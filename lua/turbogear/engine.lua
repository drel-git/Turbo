-- TurboGear/engine.lua
-- The MQ actor sync engine: registers a shared mailbox, answers REQUESTs by
-- (delta publishes added 2026-07-04)
-- publishing this box's snapshot, and ingests peer SNAPSHOTs into the Store.

local mq = require('mq')
local okActors, actorsOrErr = pcall(require, 'actors')
local actors = okActors and actorsOrErr or nil
local actorsLoadErr = okActors and nil or actorsOrErr

local cfg      = require('config')
local CFG      = cfg.CFG
local state    = require('state')
local Store    = require('store').Store
local snapshot = require('snapshot')
local diag     = require('diagnostics')

local M = {}

local Engine = {
    mailbox = nil, ok = false, debug = false,
    last_request = 0, last_publish = 0, next_publish = nil,
    next_keepalive = nil,
    last_publish_sig = nil,
    startup_sync_until = 0,
    startup_request_gap = 1.5,
    bank_open_last = false,
    bank_capture_due = 0,
    last_bank_capture = 0,
    stats = { rx_req = 0, rx_snap = 0, tx_req = 0, tx_snap = 0, rx_bad = 0, tx_skip = 0 },
    request_seq = 0,
    last_source_request = nil,
    last_source_reply = nil,
}
local MSG = {
    REQUEST = 'request',
    SNAPSHOT = 'snapshot',
    SNAPSHOT_DELTA = 'snapshot_delta',
    HEARTBEAT = 'heartbeat',
    LIST_SHARE = 'list_share',
    LIST_REQUEST = 'list_request',
    LOOT_LINK = 'loot_link',
    LOOT_NEED = 'loot_need',
    LOOT_REPLAY_REQUEST = 'loot_replay_request',
    LOOT_REPLAY = 'loot_replay',
    NEED_CONFIRM = 'need_confirm',
    NEED_CONFIRM_REPLY = 'need_confirm_reply',
}

local loot_link_dedupe = {}
local LOOT_LINK_DEDUPE_S = 3.0
local delta_backfill_requested = {}
local DELTA_BACKFILL_COOLDOWN_S = 10.0

local function dprint(...)
    if Engine.debug then diag.count("debug.events") end
end

-- Route every actor send through diag.protect so a dropped send (mailbox
-- churn, actor hiccup, transient bus error) increments a visible counter and
-- records the last error instead of silently looking like "nothing to send".
-- Surfaced in perfdiag via diagnostics.error_lines(). Behavior is otherwise
-- identical to the previous pcall(function() ... end) wrappers.
local function send_mail(kind, payload)
    return diag.protect("engine.send." .. tostring(kind), function()
        Engine.mailbox:send({ mailbox = CFG.mailbox }, payload)
    end)
end

local function set_sync_hint(msg, seconds)
    state.sync_hint = msg
    state.sync_hint_until = os.clock() + (tonumber(seconds) or 2.0)
end

local function clean_text(s)
    return tostring(s or ""):lower():match("^%s*(.-)%s*$") or ""
end

local function this_name()
    local ok, name = pcall(function() return mq.TLO.Me.CleanName() end)
    return ok and tostring(name or "") or ""
end

local function this_server()
    local ok, server = pcall(function() return mq.TLO.MacroQuest.Server() end)
    return ok and tostring(server or "") or ""
end

local function request_targets_this_box(c)
    local target_name = clean_text(c and c.targetName)
    local target_server = clean_text(c and c.targetServer)
    if target_name == "" and target_server == "" then return true end
    if target_name ~= "" and target_name ~= clean_text(this_name()) then return false end
    if target_name == "" and target_server ~= "" and target_server ~= clean_text(this_server()) then return false end
    return true
end

local function seed_jitter()
    local name = tostring((mq.TLO.Me and mq.TLO.Me.CleanName and mq.TLO.Me.CleanName()) or "")
    local acc = os.time()
    for i = 1, #name do acc = acc + (i * name:byte(i)) end
    pcall(math.randomseed, acc)
    math.random()
    math.random()
end

local function publish_jitter()
    local spread = tonumber(CFG.publish_jitter_s) or 0
    if spread <= 0 then return 0 end
    return math.random() * spread
end

local function publish_interval()
    if state.lean and state.lean() then
        return tonumber(CFG.publish_every_lean_s) or 60.0
    end
    if state.bg then
        return tonumber(CFG.publish_every_bg_s) or 30.0
    end
    if state.show == false then
        return tonumber(CFG.publish_every_minimized_s) or 30.0
    end
    return tonumber(CFG.publish_every_s) or 12.0
end

local function schedule_next_publish(now)
    Engine.next_publish = (now or os.clock()) + publish_interval() + publish_jitter()
end

-- Keepalive is presence-only. Full inventory self-heals happen through startup
-- sync, targeted peer requests, manual sync, bank-open capture, and inventory
-- dirty events. This keeps the fleet visible without forcing periodic full
-- inventory scans while players are moving.
local function keepalive_interval()
    if state.lean and state.lean() then
        return tonumber(CFG.keepalive_publish_lean_s) or 90.0
    end
    if state.bg then
        return tonumber(CFG.keepalive_publish_bg_s) or 30.0
    end
    return tonumber(CFG.keepalive_publish_s) or 45.0
end

local function schedule_next_keepalive(now)
    Engine.next_keepalive = (now or os.clock()) + keepalive_interval() + publish_jitter()
end

local function default_publish_depth(force)
    if force then return "full" end
    return snapshot.depth_for_settings()
end

local function write_local_cache_snapshot(force, depth, opts)
    opts = type(opts) == "table" and opts or {}
    local gs = mq.TLO.EverQuest.GameState()
    if gs and gs ~= "INGAME" then return false end
    depth = depth or default_publish_depth(force)
    if depth ~= "full" then depth = "lite" end
    diag.context("engine.publish", string.format("local-cache reason=%s force=%s depth=%s skipLockouts=%s skipLiveStats=%s",
        tostring(opts.reason or "cache_fallback"), tostring(force == true), tostring(depth),
        tostring(opts.skipLockouts == true), tostring(opts.skipLiveStats == true)))
    local snap = snapshot.gather({
        force = force == true,
        depth = depth,
        includeSpells = opts.includeSpells == true,
        skipLockouts = opts.skipLockouts == true,
        skipLiveStats = opts.skipLiveStats == true,
    })
    if not snap or not snap.name or snap.name == "?" then return false end
    Store.put(snap, 'cache')
    Store.save()
    return true
end

local function metadata_snap()
    local cached = snapshot.cached()
    return {
        name = (cached and cached.name) or mq.TLO.Me.CleanName() or "?",
        server = (cached and cached.server) or mq.TLO.MacroQuest.Server() or "?",
        class = (cached and cached.class) or mq.TLO.Me.Class.Name() or "?",
        level = (cached and cached.level) or mq.TLO.Me.Level() or 0,
        updated = os.time(),
        depth = "meta",
    }
end

local function send_metadata_heartbeat(reason)
    if not Engine.ok then return false end
    return diag.time("engine.heartbeat_meta", function()
        reason = tostring(reason or "heartbeat")
        diag.context("engine.heartbeat_meta", "reason=" .. reason)
        local snap = metadata_snap()
        Engine.last_publish = os.clock()
        schedule_next_publish(Engine.last_publish)
        send_mail("heartbeat", {
            type = MSG.HEARTBEAT,
            proto = CFG.proto,
            kind = 'client',
            snap = snap,
        })
        Store.touch(snap, 'client')
        diag.event("engine.heartbeat_meta", reason)
        return true
    end)
end

local function on_message(message)
    local ok, c = pcall(function() return message() end)
    if not ok or type(c) ~= 'table' then Engine.stats.rx_bad = Engine.stats.rx_bad + 1; return end
    if c.proto and c.proto ~= CFG.proto then Engine.stats.rx_bad = Engine.stats.rx_bad + 1; return end
    if c.type == MSG.REQUEST then
        Engine.stats.rx_req = Engine.stats.rx_req + 1
        if not request_targets_this_box(c) then return end
        dprint("rx REQUEST -> publishing")
        if type(c.customLockouts) == "table" then
            pcall(function() require('lockouts').set_synced_custom(c.customLockouts) end)
        end
        local force = c.force == true
        local depth = (c.depth == "full" or c.depth == "lite") and c.depth or (force and "full" or "lite")
        local publish_opts = { includeSpells = c.includeSpells == true }
        if c.fastInventory == true then
            publish_opts.skipLockouts = true
            publish_opts.skipLiveStats = true
        end
        publish_opts.reason = "peer_request"
        publish_opts.replyTo = c.requestId
        publish_opts.requester = c.from
        Engine.publish(force, depth, publish_opts)
    elseif c.type == MSG.SNAPSHOT and c.snap then
        Engine.stats.rx_snap = Engine.stats.rx_snap + 1
        dprint("rx SNAPSHOT from %s/%s", tostring(c.snap.name), tostring(c.snap.server))
        Store.put(c.snap, c.kind)
        if c.replyTo and (not c.requester or clean_text(c.requester) == clean_text(this_name())) then
            Engine.last_source_reply = {
                id = c.replyTo,
                name = c.snap.name,
                server = c.snap.server,
                depth = c.snap.depth,
                received = os.time(),
            }
            diag.event("engine.request_reply", string.format("id=%s from=%s depth=%s",
                tostring(c.replyTo), tostring(c.snap.name or "?"), tostring(c.snap.depth or "?")))
        end
    elseif c.type == MSG.SNAPSHOT_DELTA and c.delta then
        Engine.stats.rx_delta = (Engine.stats.rx_delta or 0) + 1
        dprint("rx DELTA from %s/%s", tostring(c.delta.name), tostring(c.delta.server))
        local applied = Store.apply_delta and Store.apply_delta(c.delta, c.kind) or false
        diag.event("engine.delta", string.format("rx from=%s applied=%s",
            tostring(c.delta.name or "?"), tostring(applied == true)))
        -- No baseline yet for this peer: register presence and ask for a full snapshot.
        if not applied and c.delta.name and c.delta.server then
            local bkey = tostring(c.delta.server) .. "_" .. tostring(c.delta.name)
            local last = tonumber(delta_backfill_requested[bkey]) or 0
            if (os.clock() - last) < DELTA_BACKFILL_COOLDOWN_S then return end
            delta_backfill_requested[bkey] = os.clock()
            pcall(function()
                Store.touch({
                    name = c.delta.name,
                    server = c.delta.server,
                    class = c.delta.class,
                    level = c.delta.level,
                    updated = c.delta.updated,
                    depth = "meta",
                }, c.kind)
                local key = tostring(c.delta.server) .. "_" .. tostring(c.delta.name)
                Engine.request_source(key, true, { fastInventory = true })
            end)
        end
    elseif c.type == MSG.HEARTBEAT and c.snap then
        dprint("rx HEARTBEAT from %s/%s", tostring(c.snap.name), tostring(c.snap.server))
        Store.touch(c.snap, c.kind)
    elseif c.type == MSG.LIST_SHARE or c.type == MSG.LIST_REQUEST then
        pcall(function() require('userlists').handle_actor_message(c) end)
    elseif c.type == MSG.LOOT_LINK then
        local target = tostring(c.target or "")
        if target ~= "" and clean_text(target) ~= clean_text(this_name()) then return end
        Engine.stats.rx_loot = (Engine.stats.rx_loot or 0) + 1
        pcall(function() require('announcer').on_loot_link(c) end)
    elseif c.type == MSG.LOOT_NEED then
        local target = tostring(c.target or "")
        if target ~= "" and clean_text(target) ~= clean_text(this_name()) then return end
        Engine.stats.rx_need = (Engine.stats.rx_need or 0) + 1
        pcall(function() require('announcer').on_loot_need(c) end)
    elseif c.type == MSG.NEED_CONFIRM then
        local target = tostring(c.target or "")
        if target ~= "" and clean_text(target) ~= clean_text(this_name()) then return end
        pcall(function() require('announcer').on_need_confirm(c) end)
    elseif c.type == MSG.NEED_CONFIRM_REPLY then
        local target = tostring(c.target or "")
        if target ~= "" and clean_text(target) ~= clean_text(this_name()) then return end
        pcall(function() require('announcer').on_need_confirm_reply(c) end)
    elseif c.type == MSG.LOOT_REPLAY_REQUEST then
        pcall(function() require('announcer').on_replay_request(c) end)
    elseif c.type == MSG.LOOT_REPLAY then
        local target = tostring(c.target or "")
        if target ~= "" and clean_text(target) ~= clean_text(this_name()) then return end
        pcall(function() require('announcer').on_loot_replay(c) end)
    end
end

local function loot_link_sig(items)
    local parts = {}
    for _, it in ipairs(items or {}) do
        local id = tonumber(it.id) or 0
        local name = tostring(it.name or ""):lower()
        parts[#parts + 1] = string.format("%s:%d", name, id)
    end
    table.sort(parts)
    return table.concat(parts, "|")
end

function Engine.broadcast_loot_links(items, from_name)
    if not Engine.ok or type(items) ~= "table" or #items == 0 then return false end
    cfg.LoadSharedSettings()
    if cfg.SharedSettings.announceUseActor == false then return false end
    local sig = loot_link_sig(items)
    if sig == "" then return false end
    local now = os.clock()
    if loot_link_dedupe[sig] and (now - loot_link_dedupe[sig]) <= LOOT_LINK_DEDUPE_S then
        return false
    end
    loot_link_dedupe[sig] = now
    local payload_items = {}
    for _, it in ipairs(items) do
        payload_items[#payload_items + 1] = {
            name = tostring(it.name or ""),
            id = tonumber(it.id) or 0,
            link = tostring(it.link or ""),
        }
    end
    Engine.stats.tx_loot = (Engine.stats.tx_loot or 0) + 1
    send_mail("loot_link", {
        type = MSG.LOOT_LINK,
        proto = CFG.proto,
        from = tostring(from_name or mq.TLO.Me.CleanName() or "?"),
        items = payload_items,
    })
    return true
end

function Engine.send_loot_need(target_name, need)
    if not Engine.ok or type(need) ~= "table" then return false end
    target_name = tostring(target_name or "")
    if target_name == "" then return false end
    Engine.stats.tx_need = (Engine.stats.tx_need or 0) + 1
    send_mail("loot_need", {
        type = MSG.LOOT_NEED,
        proto = CFG.proto,
        from = tostring(mq.TLO.Me.CleanName() or "?"),
        target = target_name,
        item_name = tostring(need.item_name or ""),
        loot_item_name = tostring(need.loot_item_name or ""),
        item_link = tostring(need.item_link or ""),
        item_id = tonumber(need.item_id) or 0,
        character = tostring(need.character or mq.TLO.Me.CleanName() or "?"),
        key = tostring(need.key or ""),
    })
    return true
end

-- Ask one peer to live-confirm whether it still needs an item that our cached
-- needs index says it is missing (see announcer confirm round). Fail-open by
-- design: no reply within the confirm window means the needer stays announced.
function Engine.send_need_confirm(target_name, payload)
    if not Engine.ok or type(payload) ~= "table" then return false end
    target_name = tostring(target_name or "")
    if target_name == "" then return false end
    Engine.stats.tx_confirm = (Engine.stats.tx_confirm or 0) + 1
    send_mail("need_confirm", {
        type = MSG.NEED_CONFIRM,
        proto = CFG.proto,
        from = tostring(mq.TLO.Me.CleanName() or "?"),
        target = target_name,
        item_name = tostring(payload.item_name or ""),
        item_id = tonumber(payload.item_id) or 0,
        bucket_key = tostring(payload.bucket_key or ""),
    })
    return true
end

function Engine.send_need_confirm_reply(target_name, payload)
    if not Engine.ok or type(payload) ~= "table" then return false end
    target_name = tostring(target_name or "")
    if target_name == "" then return false end
    send_mail("need_confirm_reply", {
        type = MSG.NEED_CONFIRM_REPLY,
        proto = CFG.proto,
        from = tostring(mq.TLO.Me.CleanName() or "?"),
        server = tostring(mq.TLO.MacroQuest.Server() or "?"),
        target = target_name,
        item_name = tostring(payload.item_name or ""),
        item_id = tonumber(payload.item_id) or 0,
        bucket_key = tostring(payload.bucket_key or ""),
        owned = payload.owned == true,
    })
    return true
end

function Engine.send_loot_replay(target_name, entries)
    if not Engine.ok or type(entries) ~= "table" or #entries == 0 then return false end
    target_name = tostring(target_name or "")
    if target_name == "" then return false end
    send_mail("loot_replay", {
        type = MSG.LOOT_REPLAY,
        proto = CFG.proto,
        from = tostring(mq.TLO.Me.CleanName() or "?"),
        target = target_name,
        entries = entries,
    })
    return true
end

function Engine.request_loot_replay()
    if not Engine.ok then return false end
    send_mail("loot_replay_request", {
        type = MSG.LOOT_REPLAY_REQUEST,
        proto = CFG.proto,
        from = tostring(mq.TLO.Me.CleanName() or "?"),
    })
    return true
end

-- Returns true on success. On failure returns false plus a reason:
--   "no_actors" - actors library unavailable; caller should run cache-only.
--   "busy"      - mailbox already registered (another TurboGear owns this box).
function Engine.init()
    if Engine.ok then return true end
    if not actors then
        print(string.format("[TurboGear] actors unavailable; live sync disabled, cache-only UI will still run: %s", tostring(actorsLoadErr)))
        return false, "no_actors"
    end
    local ok, mb = pcall(function() return actors.register(CFG.mailbox, on_message) end)
    if not ok or not mb then
        return false, "busy"
    end
    Engine.mailbox = mb; Engine.ok = true
    seed_jitter()
    -- R5: announce readiness so a viewer can safely delegate its startup sync.
    pcall(function() if cfg.write_bg_ready then cfg.write_bg_ready() end end)
    Engine.next_ready_write = os.clock() + (tonumber(CFG.bg_ready_write_every_s) or 20.0)
    return true
end

function Engine.shutdown()
    local released = false
    if Engine.mailbox then
        for _, method in ipairs({ "unregister", "destroy", "close" }) do
            local fn = Engine.mailbox and Engine.mailbox[method]
            if type(fn) == "function" then
                local ok = pcall(function() fn(Engine.mailbox) end)
                released = released or ok
                break
            end
        end
    end
    Engine.mailbox = nil
    Engine.ok = false
    Engine.next_publish = nil
    Engine.next_keepalive = nil
    pcall(function() if cfg.clear_bg_ready then cfg.clear_bg_ready() end end)
    return released
end

function Engine.publish(force, depth, opts)
    opts = type(opts) == "table" and opts or {}
    if not Engine.ok then
        if state.engine_claim_disabled == true then
            diag.event("engine.publish", string.format("viewer skipped local publish reason=%s depth=%s",
                tostring(opts.reason or (force and "forced" or "scheduled")), tostring(depth or "")))
            if force == true then
                pcall(function() mq.cmd('/squelch /tgearbg publish') end)
            end
            return false
        end
        return write_local_cache_snapshot(force, depth, opts)
    end
    return diag.time("engine.publish", function()
    local gs = mq.TLO.EverQuest.GameState()
    if gs and gs ~= "INGAME" then dprint("publish skipped - game state %s", tostring(gs)); return false end

    force = force == true
    depth = depth or default_publish_depth(force)
    if depth ~= "full" then depth = "lite" end
    local publish_reason = tostring(opts.reason or (force and "forced" or "scheduled"))
    diag.context("engine.publish", string.format("reason=%s force=%s depth=%s includeSpells=%s skipLockouts=%s skipLiveStats=%s bg=%s lean=%s",
        publish_reason, tostring(force), tostring(depth), tostring(opts.includeSpells == true),
        tostring(opts.skipLockouts == true), tostring(opts.skipLiveStats == true),
        tostring(state.bg == true), tostring(state.lean and state.lean() or false)))

    if depth == "full" and force then
        set_sync_hint("Syncing full inventory...", 3.0)
    end

    local snap = snapshot.gather({
        force = force,
        depth = depth,
        includeSpells = opts.includeSpells == true,
        skipLockouts = opts.skipLockouts == true,
        skipLiveStats = opts.skipLiveStats == true,
    })
    if not snap or not snap.name or snap.name == "?" then
        dprint("publish skipped - no valid name (zoning?)")
        return false
    end

    local sig = snapshot.lite_signature(snap)
    if not force and sig == Engine.last_publish_sig then
        Engine.last_publish = os.clock()
        schedule_next_publish(Engine.last_publish)
        Engine.stats.tx_skip = (Engine.stats.tx_skip or 0) + 1
        dprint("publish skipped - inventory unchanged")
        send_mail("heartbeat_unchanged", { type = MSG.HEARTBEAT, proto = CFG.proto, kind = 'client', snap = {
            name = snap.name,
            server = snap.server,
            class = snap.class,
            level = snap.level,
            updated = snap.updated,
        } })
        Store.touch(snap, 'client')
        diag.event("engine.publish", string.format("skipped unchanged reason=%s force=%s depth=%s eq=%d bag=%d bank=%d",
            publish_reason, tostring(force), tostring(depth), #(snap.equipped or {}), #(snap.bags or {}), #(snap.bank or {})))
        return false
    end

    Engine.last_publish_sig = sig
    Engine.last_publish = os.clock()
    schedule_next_publish(Engine.last_publish)
    Engine.stats.tx_snap = Engine.stats.tx_snap + 1
    dprint("tx SNAPSHOT (%s, %d equipped / %d bag / %d bank)", depth, #snap.equipped, #snap.bags, #snap.bank)
    send_mail("snapshot", {
        type = MSG.SNAPSHOT,
        proto = CFG.proto,
        kind = 'client',
        snap = snap,
        replyTo = opts.replyTo,
        requester = opts.requester,
    })
    Store.put(snap, 'client')
    -- Keep the delta baseline aligned with what peers now have, so subsequent
    -- deltas are computed against the last published state.
    pcall(function() require('inventory_watch').note_published_snapshot(snap) end)
    if opts.saveNow == true then
        Store.save()
    end
    diag.event("engine.publish", string.format("sent reason=%s force=%s depth=%s eq=%d bag=%d bank=%d save=%s",
        publish_reason, tostring(force), tostring(depth), #(snap.equipped or {}), #(snap.bags or {}), #(snap.bank or {}),
        tostring(opts.saveNow == true)))
    return true
    end)
end

-- Publish a snapshot the caller already gathered. Inventory-watch uses this to
-- avoid scanning inventory once to detect a change and then again to publish it.
function Engine.publish_snapshot(snap, opts)
    opts = type(opts) == "table" and opts or {}
    if type(snap) ~= "table" or not snap.name or snap.name == "?" then return false end
    if not Engine.ok then
        if state.engine_claim_disabled == true then
            diag.event("engine.publish_snapshot", string.format("viewer skipped local publish reason=%s depth=%s",
                tostring(opts.reason or "prebuilt"), tostring(snap.depth or "")))
            return false
        end
        Store.put(snap, 'cache')
        Store.save()
        return true
    end
    return diag.time("engine.publish_snapshot", function()
        local gs = mq.TLO.EverQuest.GameState()
        if gs and gs ~= "INGAME" then return false end
        local publish_reason = tostring(opts.reason or "prebuilt")
        diag.context("engine.publish_snapshot", string.format("reason=%s depth=%s skipLockouts=%s skipLiveStats=%s bg=%s lean=%s",
            publish_reason, tostring(snap.depth or ""),
            tostring(opts.skipLockouts == true), tostring(opts.skipLiveStats == true),
            tostring(state.bg == true), tostring(state.lean and state.lean() or false)))

        local sig = snapshot.lite_signature(snap)
        if opts.force ~= true and sig == Engine.last_publish_sig then
            Engine.last_publish = os.clock()
            schedule_next_publish(Engine.last_publish)
            Engine.stats.tx_skip = (Engine.stats.tx_skip or 0) + 1
            send_mail("heartbeat_unchanged", { type = MSG.HEARTBEAT, proto = CFG.proto, kind = 'client', snap = {
                name = snap.name,
                server = snap.server,
                class = snap.class,
                level = snap.level,
                updated = snap.updated,
            } })
            Store.touch(snap, 'client')
            diag.event("engine.publish_snapshot", string.format("skipped unchanged reason=%s depth=%s eq=%d bag=%d bank=%d",
                publish_reason, tostring(snap.depth or ""), #(snap.equipped or {}), #(snap.bags or {}), #(snap.bank or {})))
            return false
        end

        Engine.last_publish_sig = sig
        Engine.last_publish = os.clock()
        schedule_next_publish(Engine.last_publish)
        Engine.stats.tx_snap = Engine.stats.tx_snap + 1
        send_mail("snapshot", {
            type = MSG.SNAPSHOT,
            proto = CFG.proto,
            kind = 'client',
            snap = snap,
            replyTo = opts.replyTo,
            requester = opts.requester,
        })
        Store.put(snap, 'client')
        pcall(function() require('inventory_watch').note_published_snapshot(snap) end)
        if opts.saveNow == true then
            Store.save()
        end
        diag.event("engine.publish_snapshot", string.format("sent reason=%s depth=%s eq=%d bag=%d bank=%d save=%s",
            publish_reason, tostring(snap.depth or ""), #(snap.equipped or {}), #(snap.bags or {}), #(snap.bank or {}),
            tostring(opts.saveNow == true)))
        return true
    end)
end

-- Send a changed-slot delta immediately (small payload, no cooldown). Peers
-- without a baseline snapshot ignore it and request a full snapshot instead.
function Engine.publish_delta(delta)
    if not Engine.ok or type(delta) ~= "table" then return false end
    if cfg.CFG.delta_publish_enabled == false then return false end
    local gs = mq.TLO.EverQuest.GameState()
    if gs and gs ~= "INGAME" then return false end
    local count = require('snapshot_delta').count_changes(delta)
    if count == 0 then return false end
    Engine.stats.tx_delta = (Engine.stats.tx_delta or 0) + 1
    send_mail("snapshot_delta", {
        type = MSG.SNAPSHOT_DELTA,
        proto = CFG.proto,
        kind = 'client',
        delta = delta,
    })
    -- Apply locally too so our own Store/cache reflect the change right away.
    pcall(function() Store.apply_delta(delta, 'client') end)
    diag.event("engine.delta", string.format("tx items=%d", count))
    return true
end

function Engine.begin_startup_sync(seconds)
    Engine.startup_sync_until = os.clock() + (tonumber(seconds) or 12.0)
end

function Engine.request_all(force, opts)
    if not Engine.ok then return end
    opts = type(opts) == "table" and opts or {}
    if not force and (os.clock() - Engine.last_request) < CFG.request_cooldown_s then return end
    Engine.last_request = os.clock()
    Engine.stats.tx_req = Engine.stats.tx_req + 1
    dprint("tx REQUEST")
    diag.count("engine.request_all")
    diag.event("engine.request_all", string.format("force=%s depth=%s fastInventory=%s includeSpells=%s",
        tostring(force == true),
        tostring((opts.depth == "full" or opts.depth == "lite") and opts.depth or (force and "full" or "lite")),
        tostring(opts.fastInventory == true), tostring(opts.includeSpells == true)))
    send_mail("request", {
        type = MSG.REQUEST,
        proto = CFG.proto,
        force = force and true or false,
        depth = (opts.depth == "full" or opts.depth == "lite") and opts.depth or (force and "full" or "lite"),
        includeSpells = opts.includeSpells == true,
        fastInventory = opts.fastInventory == true,
        customLockouts = (function()
            local ok, lo = pcall(require, 'lockouts')
            if ok and lo and lo.export_custom_for_sync then return lo.export_custom_for_sync() end
            return nil
        end)(),
    })
end

function Engine.request_source(source_key, force, opts)
    if not Engine.ok then return false end
    opts = type(opts) == "table" and opts or {}
    local snap = Store.get(source_key or "")
    if not snap or not snap.name or snap.name == "" then return false end
    Engine.request_seq = (tonumber(Engine.request_seq) or 0) + 1
    local request_id = string.format("%s:%d:%d", tostring(this_name() or "?"), os.time(), Engine.request_seq)
    local depth = (opts.depth == "full" or opts.depth == "lite") and opts.depth or (force and "full" or "lite")
    Engine.stats.tx_req = Engine.stats.tx_req + 1
    diag.count("engine.request_source")
    Engine.last_source_request = {
        id = request_id,
        key = source_key,
        name = snap.name,
        server = snap.server,
        sent = os.time(),
        depth = depth,
        fastInventory = opts.fastInventory == true,
    }
    diag.event("engine.request_source", string.format("id=%s target=%s force=%s depth=%s fastInventory=%s includeSpells=%s",
        tostring(request_id),
        tostring(source_key or ""), tostring(force == true),
        tostring(depth),
        tostring(opts.fastInventory == true), tostring(opts.includeSpells == true)))
    send_mail("request", {
        type = MSG.REQUEST,
        proto = CFG.proto,
        force = force and true or false,
        requestId = request_id,
        from = this_name(),
        depth = depth,
        includeSpells = opts.includeSpells == true,
        fastInventory = opts.fastInventory == true,
        targetName = snap.name,
        -- Name-only targeting lets older bg responders answer even if a cached
        -- server label differs from the peer's current MacroQuest.Server text.
        targetServer = opts.strictServer == true and snap.server or nil,
    })
    return true, request_id
end

function Engine.publish_inventory_change()
    return Engine.publish(true, "full", { skipLockouts = true, skipLiveStats = true, reason = "inventory_change" })
end

function Engine.sync_bank_now()
    if not snapshot.bank_window_open or not snapshot.bank_window_open() then
        set_sync_hint("Open the bank first, then Sync Bank.", 3.0)
        return false
    end
    snapshot.invalidate()
    local ok = Engine.publish(true, "full", { reason = "manual_bank_sync" })
    Engine.last_bank_capture = os.clock()
    set_sync_hint(ok and "Bank contents synced." or "Bank sync requested.", 3.0)
    return ok
end

function Engine.sync_banks_network()
    local local_open = snapshot.bank_window_open and snapshot.bank_window_open() or false
    if local_open then
        snapshot.invalidate()
        Engine.publish(true, "full", { reason = "network_bank_sync" })
        Engine.last_bank_capture = os.clock()
    end
    pcall(function()
        if cfg.Settings.autoLaunch then cfg.launch_peers() end
        if cfg.Settings.autoAddOnlinePeers ~= false then cfg.launch_all_online_peers() end
    end)
    Engine.request_all(true, { depth = "full" })
    Engine.begin_startup_sync(8.0)
    set_sync_hint(local_open and "Bank synced; requesting peer banks..." or "Requesting peer banks. Open bank on the owner first.", 4.0)
    return true
end

local function capture_open_bank(reason, hint_seconds)
    if not snapshot.bank_window_open or not snapshot.bank_window_open() then return false end
    snapshot.invalidate()
    local ok = Engine.publish(true, "full", { skipLockouts = true, skipLiveStats = true, reason = reason or "bank_capture" })
    Engine.last_bank_capture = os.clock()
    if reason and reason ~= "" then
        set_sync_hint(reason, hint_seconds or 2.5)
    end
    return ok
end

local function tick_bank_capture()
    if cfg.Settings.autoCaptureBankOnOpen == false then return end
    if not snapshot.bank_window_open then return end
    local now = os.clock()
    local open = snapshot.bank_window_open()
    if open and not Engine.bank_open_last then
        capture_open_bank("Bank opened; captured bank contents.", 2.5)
        Engine.bank_capture_due = now + (tonumber(CFG.bank_open_capture_delay_s) or 1.0)
    elseif not open then
        Engine.bank_capture_due = 0
    end
    Engine.bank_open_last = open
    if open and Engine.bank_capture_due > 0 and now >= Engine.bank_capture_due then
        Engine.bank_capture_due = 0
        capture_open_bank("Bank contents refreshed.", 2.0)
    end
end

-- Dedupe maps only ever gained keys; prune stale entries periodically.
local next_dedupe_prune = 0
local function prune_dedupe_maps()
    local now = os.clock()
    if now < next_dedupe_prune then return end
    next_dedupe_prune = now + 60.0
    for sig, at in pairs(loot_link_dedupe) do
        if (now - (tonumber(at) or 0)) > (LOOT_LINK_DEDUPE_S * 10) then
            loot_link_dedupe[sig] = nil
        end
    end
    for key, at in pairs(delta_backfill_requested) do
        if (now - (tonumber(at) or 0)) > (DELTA_BACKFILL_COOLDOWN_S * 10) then
            delta_backfill_requested[key] = nil
        end
    end
end

function Engine.heartbeat()
    if not Engine.ok then return end
    -- R5: keep the readiness marker fresh while we own the mailbox (throttled).
    if os.clock() >= (Engine.next_ready_write or 0) then
        Engine.next_ready_write = os.clock() + (tonumber(CFG.bg_ready_write_every_s) or 20.0)
        pcall(function() if cfg.write_bg_ready then cfg.write_bg_ready() end end)
    end
    tick_bank_capture()
    prune_dedupe_maps()
    if not Engine.next_publish then schedule_next_publish(Engine.last_publish > 0 and Engine.last_publish or os.clock()) end
    if os.clock() >= Engine.next_publish then
        if (state.lean and state.lean()) or cfg.Settings.autoPeerRefresh ~= true then
            send_metadata_heartbeat("scheduled")
        else
            Engine.publish(false, nil, { reason = "scheduled_refresh" })
        end
    end
    if not Engine.next_keepalive then schedule_next_keepalive() end
    if os.clock() >= Engine.next_keepalive then
        send_metadata_heartbeat("keepalive")
        schedule_next_keepalive()
    end
    if Engine.startup_sync_until and Engine.startup_sync_until > 0 then
        if os.clock() < Engine.startup_sync_until then
            if (os.clock() - Engine.last_request) >= Engine.startup_request_gap then
                Engine.request_all(true)
            end
        else
            Engine.startup_sync_until = 0
        end
    end
end

M.Engine = Engine
M.MSG    = MSG
-- Test seam: message dispatch is otherwise a private closure. Exposed so the
-- offline dispatch test (tests/turbogear_engine_dispatch_test.lua) can drive
-- on_message with a fake actor message and assert Store side effects.
M._on_message = on_message
return M
