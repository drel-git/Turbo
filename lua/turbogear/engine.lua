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
    inventory_publish_diag = nil,
    last_gather_diag = nil,
    pending_request = nil,
    pending_bis_search = nil,
}
local MSG = {
    REQUEST = 'request',
    SNAPSHOT = 'snapshot',
    SNAPSHOT_DELTA = 'snapshot_delta',
    WALLET = 'wallet',
    HEARTBEAT = 'heartbeat',
    LIST_SHARE = 'list_share',
    LIST_REQUEST = 'list_request',
    LOOT_LINK = 'loot_link',
    LOOT_NEED = 'loot_need',
    LOOT_REPLAY_REQUEST = 'loot_replay_request',
    LOOT_REPLAY = 'loot_replay',
    NEED_CONFIRM = 'need_confirm',
    NEED_CONFIRM_REPLY = 'need_confirm_reply',
    GO_LOOT = 'go_loot',
    GO_LOOT_RESULT = 'go_loot_result',
    -- BiS-shaped ownership: catalog FindItem scan, not full inventory.
    BIS_SEARCH = 'bis_search',
    BIS_RESULT = 'bis_result',
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
    kind = tostring(kind)
    return diag.time("engine.send_mail." .. kind, function()
        return diag.protect("engine.send." .. kind, function()
            Engine.mailbox:send({ mailbox = CFG.mailbox }, payload)
        end)
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

local function reason_kind(reason)
    reason = tostring(reason or "")
    if reason == "peer_request" then return "peer-request" end
    if reason == "manual_sync" or reason == "forced" then return "manual-sync" end
    if reason == "manual_bank_sync" or reason == "network_bank_sync" or reason == "bank_capture" then return "bank-sync" end
    if reason == "inventory_change" or reason == "inventory_watch_dirty" or reason == "inventory_watch_bg_poll" then return "inventory-dirty" end
    if reason == "worn_persist" or reason == "rich_inventory.recovery_probe" then return "worn-poll" end
    if reason == "startup_bg_full" then return "startup" end
    if reason == "scheduled_refresh" then return "scheduled" end
    if reason == "rich_inventory.promote" or reason == "richrefresh" then return "rich-inventory" end
    if reason == "lockout_change" or reason == "don_change" then return "metadata" end
    if reason:find("loot", 1, true) then return "loot/chat-event" end
    return reason ~= "" and reason or "other"
end

local function count_list(t)
    return type(t) == "table" and #t or 0
end

local function annotate_inventory_publish(snap, info)
    if type(snap) ~= "table" then return nil end
    info = type(info) == "table" and info or {}
    local now = os.time()
    local reason = tostring(info.reason or "")
    local diag_info = {
        at = now,
        reason = reason,
        reasonKind = reason_kind(reason),
        seq = tonumber(snap.seq),
        requestedDepth = tostring(info.requestedDepth or snap.depth or ""),
        depth = tostring(snap.depth or ""),
        gatherResult = tostring(info.gatherResult or (snap.inventoryIncomplete and "incomplete" or "ok")),
        complete = snap.inventoryIncomplete ~= true,
        equipped = count_list(snap.equipped),
        bags = count_list(snap.bags),
        bank = count_list(snap.bank),
    }
    Engine.last_gather_diag = {
        at = now,
        reason = reason,
        requestedDepth = diag_info.requestedDepth,
        depth = diag_info.depth,
        result = diag_info.gatherResult,
        complete = diag_info.complete,
        equipped = diag_info.equipped,
        bags = diag_info.bags,
        bank = diag_info.bank,
    }
    if info.published == false then return diag_info end
    snap._tgPublishAt = diag_info.at
    snap._tgPublishReason = diag_info.reason
    snap._tgPublishReasonKind = diag_info.reasonKind
    snap._tgPublishSeq = diag_info.seq
    snap._tgPublishRequestedDepth = diag_info.requestedDepth
    snap._tgPublishDepth = diag_info.depth
    snap._tgPublishGatherResult = diag_info.gatherResult
    snap._tgPublishComplete = diag_info.complete
    Engine.inventory_publish_diag = diag_info
    return diag_info
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
        skipLockoutBypass = opts.skipLockoutBypass == true,
    })
    if not snap or not snap.name or snap.name == "?" then return false end
    annotate_inventory_publish(snap, {
        reason = tostring(opts.reason or "cache_fallback"),
        requestedDepth = depth,
        gatherResult = snap.inventoryIncomplete == true and "incomplete" or "ok",
    })
    Store.put(snap, 'cache')
    Store.save()
    return true
end

local last_zone_short = nil
local lockout_watch = { next_at = 0, sig = nil, don = nil }

local function zone_fields()
    local zoneShort, zoneName = "", ""
    pcall(function()
        zoneShort = tostring(mq.TLO.Zone.ShortName() or "")
        zoneName = tostring(mq.TLO.Zone.Name() or "")
    end)
    local zl = zoneShort:lower()
    if zl == "unknown" or zl == "nil" or zl == "null" then
        zoneShort, zoneName = "", ""
    end
    return zoneShort, zoneName
end

local function metadata_snap()
    local cached = snapshot.cached()
    local zoneShort, zoneName = zone_fields()
    -- Ignore sticky class="?" from a failed early gather; re-read TLO each heartbeat.
    local canon = cfg.canonical_class or cfg.known_class
    local class = canon and canon(cached and cached.class) or nil
    if not class and canon then
        class = canon(mq.TLO.Me.Class.Name())
            or canon(mq.TLO.Me.Class and mq.TLO.Me.Class())
            or canon(mq.TLO.Me.Class and mq.TLO.Me.Class.ShortName and mq.TLO.Me.Class.ShortName())
            or ""
    end
    class = class or ""
    return {
        name = (cached and cached.name) or mq.TLO.Me.CleanName() or "?",
        server = (cached and cached.server) or mq.TLO.MacroQuest.Server() or "?",
        class = class,
        level = (cached and cached.level) or mq.TLO.Me.Level() or 0,
        zoneShortName = zoneShort ~= "" and zoneShort or (cached and cached.zoneShortName) or "",
        zoneName = zoneName ~= "" and zoneName or (cached and cached.zoneName) or "",
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

function Engine.ingame()
    local ok, gs = pcall(function() return mq.TLO.EverQuest.GameState() end)
    return ok and gs == "INGAME"
end

function Engine.enqueue_peer_request(c)
    c = type(c) == "table" and c or {}
    local prev = Engine.pending_request
    local depth = (c.depth == "full" or c.depth == "lite") and c.depth or nil
    if prev and prev.depth == "full" then depth = "full" end
    if depth ~= "full" and depth ~= "lite" then
        depth = ((prev and prev.force) or c.force == true) and "full" or "lite"
    end
    Engine.pending_request = {
        force = (prev and prev.force) or c.force == true,
        depth = depth,
        includeSpells = (prev and prev.includeSpells) or c.includeSpells == true,
        replyTo = c.requestId or (prev and prev.replyTo),
        requester = c.from or (prev and prev.requester),
    }
end

function Engine.apply_pending_request()
    local work = Engine.pending_request
    if not work then return false end
    if not Engine.ingame() then return false end
    if Engine.startup_settle_until and os.clock() < Engine.startup_settle_until then
        return false
    end
    Engine.pending_request = nil
    -- Inventory TLO belongs on the run loop, never in the actor mailbox
    -- callback. Do not also force a Task journal walk or DynamicZone re-read
    -- on this same drain: UI-open REQUEST is what hits bg-only alts, and
    -- stacking those native reads crashes eqgame with no Lua message.
    -- note_refresh_wanted queues /tasktime on don_track.tick after this yield.
    pcall(function()
        require('don_track').note_refresh_wanted()
    end)
    Engine.publish(work.force, work.depth, {
        includeSpells = work.includeSpells == true,
        reason = "peer_request",
        replyTo = work.replyTo,
        requester = work.requester,
        skipLockoutBypass = true,
    })
    return true
end

function Engine.enqueue_bis_search(c)
    c = type(c) == "table" and c or {}
    local list_id = tostring(c.list_id or c.list or "")
    if list_id == "" then return end
    Engine.pending_bis_search = { list_id = list_id } -- replaces a queued push: answer now
end

--- Unsolicited refresh of this box's own list answer (e.g. after scribing a
--- DoN ability). Reuses the search-reply path on a later tick; a real peer
--- request arriving meanwhile replaces it and answers immediately.
function Engine.queue_bis_push(list_id, delay_s)
    list_id = tostring(list_id or "")
    if list_id == "" then return false end
    local not_before = os.clock() + math.max(0, tonumber(delay_s) or 0)
    local cur = Engine.pending_bis_search
    if type(cur) == "table" and cur.list_id == list_id then
        -- Coalesce a scribe burst into one push after the LAST scribe.
        if cur.not_before then cur.not_before = math.max(cur.not_before, not_before) end
        return true
    end
    if type(cur) == "table" then return false end -- a real request is pending; leave it
    Engine.pending_bis_search = { list_id = list_id, not_before = not_before, push = true }
    diag.count("engine.bis_push_queued")
    return true
end

function Engine.apply_pending_bis_search()
    local work = Engine.pending_bis_search
    if not work then return false end
    if work.not_before and os.clock() < work.not_before then return false end
    if not Engine.ingame() then return false end
    if Engine.startup_settle_until and os.clock() < Engine.startup_settle_until then
        return false
    end
    Engine.pending_bis_search = nil
    local list_id = tostring(work.list_id or "")
    if list_id == "" then return false end
    diag.count("engine.bis_search_rx")
    local ok_bs, bis_search = pcall(require, 'bis_search')
    if not ok_bs or not bis_search or not bis_search.search_local then return false end
    local result = diag.time("engine.bis_search_local", function()
        return bis_search.search_local(list_id)
    end)
    if type(result) ~= "table" then return false end
    pcall(function()
        bis_search.apply_result(result)
        diag.time("engine.bis_search_rx_save", function()
            bis_search.save()
        end)
    end)
    send_mail("bis_result", {
        type = MSG.BIS_RESULT,
        proto = CFG.proto,
        kind = 'client',
        name = result.name,
        server = result.server,
        class = result.class,
        list_id = list_id,
        updated = result.updated,
        slots = result.slots,
    })
    diag.event("engine.bis_search", string.format("replied list=%s slots=%d",
        list_id, (function()
            local n = 0
            for _ in pairs(result.slots or {}) do n = n + 1 end
            return n
        end)()))
    return true
end

function Engine.apply_pending_announce()
    if not Engine.ingame() then return false end
    if Engine.startup_settle_until and os.clock() < Engine.startup_settle_until then
        return false
    end
    if Engine._heavy_tlo then return false end
    local ran = false
    if Engine.pending_loot_link then
        local c = Engine.pending_loot_link
        Engine.pending_loot_link = nil
        pcall(function() require('announcer').on_loot_link(c) end)
        ran = true
    end
    if Engine.pending_loot_need then
        local c = Engine.pending_loot_need
        Engine.pending_loot_need = nil
        pcall(function() require('announcer').on_loot_need(c) end)
        ran = true
    end
    if Engine.pending_need_confirm then
        local c = Engine.pending_need_confirm
        Engine.pending_need_confirm = nil
        pcall(function() require('announcer').on_need_confirm(c) end)
        ran = true
        Engine._heavy_tlo = "need_confirm"
    end
    return ran
end

-- Cheap zone freshness for same-zone handoff guards. Inventory does not change
-- on zone; peers only need updated zoneShortName/zoneName via Store.touch.
local function tick_zone_meta()
    if not Engine.ingame() then return end
    local zoneShort = zone_fields()
    if zoneShort == "" then return end
    if last_zone_short == nil then
        last_zone_short = zoneShort
        return
    end
    if last_zone_short == zoneShort then return end
    last_zone_short = zoneShort
    -- Zone-in is when DynamicZone actually changes. Idle sitting must not
    -- poll that TLO on a timer -- it silently disconnects some clients.
    Engine.lockout_watch_wanted = true
    lockout_watch.next_at = 0
    send_metadata_heartbeat("zone_change")
    schedule_next_keepalive()
end

local function on_message(message)
    local ok, c = pcall(function() return message() end)
    if not ok or type(c) ~= 'table' then Engine.stats.rx_bad = Engine.stats.rx_bad + 1; return end
    if c.proto and c.proto ~= CFG.proto then Engine.stats.rx_bad = Engine.stats.rx_bad + 1; return end
    if c.type == MSG.REQUEST then
        Engine.stats.rx_req = Engine.stats.rx_req + 1
        if not request_targets_this_box(c) then return end
        dprint("rx REQUEST -> queued")
        if type(c.customLockouts) == "table" then
            pcall(function() require('lockouts').set_synced_custom(c.customLockouts) end)
        end
        -- Queue only. Inventory, DynamicZone, and Task journal reads must run
        -- on the script loop. Doing them here stalls/crashes the client.
        Engine.enqueue_peer_request(c)
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
            -- Do not Store.save() here: a blocking persist inside the actor
            -- callback hitches the client. Store.put already dirtied the row;
            -- ask the run-loop persist job to flush on the next tick.
            pcall(function()
                if Store.request_flush then Store.request_flush() end
            end)
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
    elseif c.type == MSG.WALLET and c.snap then
        Engine.stats.rx_wallet = (Engine.stats.rx_wallet or 0) + 1
        dprint("rx WALLET from %s/%s", tostring(c.snap.name), tostring(c.snap.server))
        pcall(function() Store.put_wallet(c.snap, c.kind or 'client') end)
    elseif c.type == MSG.HEARTBEAT and c.snap then
        dprint("rx HEARTBEAT from %s/%s", tostring(c.snap.name), tostring(c.snap.server))
        Store.touch(c.snap, c.kind)
    elseif c.type == MSG.BIS_SEARCH then
        if not request_targets_this_box(c) then return end
        Engine.enqueue_bis_search(c)
    elseif c.type == MSG.BIS_RESULT then
        diag.count("engine.bis_result_rx")
        local ok_bs, bis_search = pcall(require, 'bis_search')
        if ok_bs and bis_search and bis_search.apply_result then
            if bis_search.apply_result(c) then
                pcall(function()
                    diag.time("engine.bis_result_save", function()
                        bis_search.save()
                    end)
                end)
                diag.event("engine.bis_result", string.format("from=%s list=%s",
                    tostring(c.name or "?"), tostring(c.list_id or c.list or "?")))
            end
        end
    elseif c.type == MSG.LIST_SHARE or c.type == MSG.LIST_REQUEST then
        pcall(function() require('userlists').handle_actor_message(c) end)
    elseif c.type == MSG.LOOT_LINK then
        local target = tostring(c.target or "")
        if target ~= "" and clean_text(target) ~= clean_text(this_name()) then return end
        Engine.stats.rx_loot = (Engine.stats.rx_loot or 0) + 1
        Engine.pending_loot_link = c
    elseif c.type == MSG.LOOT_NEED then
        local target = tostring(c.target or "")
        if target ~= "" and clean_text(target) ~= clean_text(this_name()) then return end
        Engine.stats.rx_need = (Engine.stats.rx_need or 0) + 1
        Engine.pending_loot_need = c
    elseif c.type == MSG.NEED_CONFIRM then
        local target = tostring(c.target or "")
        if target ~= "" and clean_text(target) ~= clean_text(this_name()) then return end
        Engine.pending_need_confirm = c
    elseif c.type == MSG.NEED_CONFIRM_REPLY then
        local target = tostring(c.target or "")
        if target ~= "" and clean_text(target) ~= clean_text(this_name()) then return end
        pcall(function() require('announcer').on_need_confirm_reply(c) end)
    elseif c.type == MSG.GO_LOOT then
        local target = tostring(c.target or "")
        if target == "" or clean_text(target) ~= clean_text(this_name()) then return end
        pcall(function() require('announcer').on_go_loot(c) end)
    elseif c.type == MSG.GO_LOOT_RESULT then
        local target = tostring(c.target or "")
        if target ~= "" and clean_text(target) ~= clean_text(this_name()) then return end
        pcall(function() require('announcer').on_go_loot_result(c) end)
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
        local cid = tonumber(it.corpse_id) or 0
        parts[#parts + 1] = string.format("%s:%d:%d", name, id, cid)
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
        local cid = tonumber(it.corpse_id)
        payload_items[#payload_items + 1] = {
            name = tostring(it.name or ""),
            id = tonumber(it.id) or 0,
            link = tostring(it.link or ""),
            corpse_id = (cid and cid > 0) and math.floor(cid) or nil,
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
    -- Empty/unknown holder still broadcasts: receivers do not gate on target, and
    -- after a patcher restart the UI beacon name may not be on disk yet.
    target_name = tostring(target_name or "")
    if target_name == "" then target_name = "*" end
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

-- Ask one character (over the bus) to walk to a corpse and loot an item the
-- linked-items panel says it needs. Executed by the go_loot runner on the
-- target's box; the target answers with GO_LOOT_RESULT.
function Engine.send_go_loot(target_name, payload)
    if not Engine.ok or type(payload) ~= "table" then return false end
    target_name = tostring(target_name or "")
    if target_name == "" then return false end
    send_mail("go_loot", {
        type = MSG.GO_LOOT,
        proto = CFG.proto,
        from = tostring(mq.TLO.Me.CleanName() or "?"),
        target = target_name,
        item_name = tostring(payload.item_name or ""),
        item_id = tonumber(payload.item_id) or 0,
        corpse_id = tonumber(payload.corpse_id) or 0,
    })
    return true
end

function Engine.send_go_loot_result(target_name, payload)
    if not Engine.ok or type(payload) ~= "table" then return false end
    target_name = tostring(target_name or "")
    if target_name == "" then return false end
    send_mail("go_loot_result", {
        type = MSG.GO_LOOT_RESULT,
        proto = CFG.proto,
        from = tostring(mq.TLO.Me.CleanName() or "?"),
        target = target_name,
        item_name = tostring(payload.item_name or ""),
        corpse_id = tonumber(payload.corpse_id) or 0,
        ok = payload.ok == true,
        note = tostring(payload.note or ""),
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
    -- Best-effort disk flush so the last settled gear state is not lost.
    -- May hitch once on unload; never called on zone.
    pcall(function()
        local Store = require('store').Store
        if Store and Store.flush_pending then Store.flush_pending() end
    end)
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

    -- Blocking depth=full remains only for bank-open capture and inventory_watch
    -- change publishes. Everything else (startup, Sync Now, Inspect, peer
    -- REQUEST) publishes lite immediately and enriches cooperatively.
    if depth == "full" and opts.allowBlockingFull ~= true then
        diag.event("engine.publish", string.format(
            "cooperative full reason=%s -> lite + rich_inventory", publish_reason))
        local lite_ok = Engine.publish(force, "lite", {
            skipLockouts = opts.skipLockouts,
            skipLiveStats = opts.skipLiveStats,
            includeSpells = opts.includeSpells,
            includeLiveStats = opts.skipLiveStats ~= true,
            skipLockoutBypass = opts.skipLockoutBypass,
            reason = publish_reason,
            requestedDepth = opts.requestedDepth or depth,
            replyTo = opts.replyTo,
            requester = opts.requester,
            saveNow = opts.saveNow,
        })
        pcall(function()
            require('rich_inventory').start({
                reason = publish_reason,
                replyTo = opts.replyTo,
                requester = opts.requester,
            })
        end)
        return lite_ok
    end

    diag.context("engine.publish", string.format("reason=%s force=%s depth=%s includeSpells=%s skipLockouts=%s skipLiveStats=%s bg=%s lean=%s",
        publish_reason, tostring(force), tostring(depth), tostring(opts.includeSpells == true),
        tostring(opts.skipLockouts == true), tostring(opts.skipLiveStats == true),
        tostring(state.bg == true), tostring(state.lean and state.lean() or false)))

    if depth == "full" and force then
        set_sync_hint("Syncing full inventory...", 3.0)
    end

    local snap = diag.time("engine.publish.gather", function()
        return snapshot.gather({
            force = force,
            depth = depth,
            includeSpells = opts.includeSpells == true,
            skipLockouts = opts.skipLockouts == true,
            skipLiveStats = opts.skipLiveStats == true,
            includeLiveStats = opts.includeLiveStats == true,
            skipLockoutBypass = opts.skipLockoutBypass == true,
        })
    end)
    if not snap or not snap.name or snap.name == "?" then
        dprint("publish skipped - no valid name (zoning?)")
        return false
    end
    annotate_inventory_publish(snap, {
        reason = publish_reason,
        requestedDepth = opts.requestedDepth or depth,
        gatherResult = snap.inventoryIncomplete == true and "incomplete" or "ok",
        published = false,
    })
    -- Incomplete inventory walk (pcall failed): keep local Store via put/merge
    -- preserve, but do not broadcast a partial/empty wipe to peers.
    if snap.inventoryIncomplete == true then
        dprint("publish skipped - inventory walk incomplete")
        diag.time("engine.publish.store_put", function()
            Store.put(snap, 'client')
        end)
        Engine.last_publish = os.clock()
        schedule_next_publish(Engine.last_publish)
        diag.event("engine.publish", string.format(
            "skipped incomplete reason=%s force=%s depth=%s eq=%d bag=%d err=%s",
            publish_reason, tostring(force), tostring(depth),
            #(snap.equipped or {}), #(snap.bags or {}), tostring(snap.inventoryError or "?")))
        return false
    end

    local sig = snapshot.lite_signature(snap)
    local wsig = snapshot.wallet_signature and snapshot.wallet_signature(snap) or ""
    if not force and sig == Engine.last_publish_sig then
        -- Inventory unchanged: still ship wallet-only if currency moved (PP/CC/etc).
        if wsig ~= "" and wsig ~= tostring(Engine.last_wallet_sig or "") then
            if Engine.publish_wallet then
                return Engine.publish_wallet(snap, { reason = publish_reason .. "_wallet" })
            end
        end
        Engine.last_publish = os.clock()
        schedule_next_publish(Engine.last_publish)
        Engine.stats.tx_skip = (Engine.stats.tx_skip or 0) + 1
        if Engine.last_gather_diag then Engine.last_gather_diag.result = "unchanged" end
        dprint("publish skipped - inventory unchanged")
        send_mail("heartbeat_unchanged", { type = MSG.HEARTBEAT, proto = CFG.proto, kind = 'client', snap = {
            name = snap.name,
            server = snap.server,
            class = snap.class,
            level = snap.level,
            updated = snap.updated,
        } })
        diag.time("engine.publish.store_touch", function()
            Store.touch(snap, 'client')
        end)
        diag.event("engine.publish", string.format("skipped unchanged reason=%s force=%s depth=%s eq=%d bag=%d bank=%d",
            publish_reason, tostring(force), tostring(depth), #(snap.equipped or {}), #(snap.bags or {}), #(snap.bank or {})))
        return false
    end

    Engine.last_publish_sig = sig
    Engine.last_wallet_sig = wsig
    Engine.last_publish = os.clock()
    schedule_next_publish(Engine.last_publish)
    Engine.stats.tx_snap = Engine.stats.tx_snap + 1
    annotate_inventory_publish(snap, {
        reason = publish_reason,
        requestedDepth = opts.requestedDepth or depth,
        gatherResult = "sent",
    })
    dprint("tx SNAPSHOT (%s, %d equipped / %d bag / %d bank)", depth, #snap.equipped, #snap.bags, #snap.bank)
    send_mail("snapshot", {
        type = MSG.SNAPSHOT,
        proto = CFG.proto,
        kind = 'client',
        snap = snap,
        replyTo = opts.replyTo,
        requester = opts.requester,
    })
    diag.time("engine.publish.store_put", function()
        Store.put(snap, 'client')
    end)
    -- Keep the delta baseline aligned with what peers now have, so subsequent
    -- deltas are computed against the last published state.
    pcall(function() require('inventory_watch').note_published_snapshot(snap) end)
    if opts.saveNow == true then
        diag.time("engine.publish.store_save", function()
            Store.save({ only_self = true })
        end)
    else
        pcall(function()
            diag.time("engine.publish.wallet_sidecar", function()
                Store.flush_wallet_sidecar()
            end)
        end)
    end
    diag.event("engine.publish", string.format("sent reason=%s force=%s depth=%s eq=%d bag=%d bank=%d save=%s",
        publish_reason, tostring(force), tostring(depth), #(snap.equipped or {}), #(snap.bags or {}), #(snap.bank or {}),
        tostring(opts.saveNow == true)))
    return true
    end)
end

--- Tiny wallet-only publish (no bag walk). Also sets E3 TurboFW for Fleet live reads.
function Engine.publish_wallet(snap, opts)
    opts = type(opts) == "table" and opts or {}
    if type(snap) ~= "table" or not snap.name or snap.name == "?" then
        snap = snapshot.gather_wallet and snapshot.gather_wallet() or nil
    end
    if type(snap) ~= "table" or not snap.name or snap.name == "?" then return false end
    local diag_reason = tostring(opts.reason or snap._walletDiagReason or "")
    local wallet_settle_diag = diag_reason == "wallet_settle" or tostring(snap._walletDiagReason or "") == "settle"
    local function wallet_diag_ms()
        if mq.gettime then
            local t = tonumber(mq.gettime())
            if t then return math.floor(t) end
        end
        return math.floor((os.time() or 0) * 1000)
    end
    local wsig = snapshot.wallet_signature and snapshot.wallet_signature(snap) or ""
    if opts.force ~= true and wsig ~= "" and wsig == tostring(Engine.last_wallet_sig or "") then
        return false
    end
    Engine.last_wallet_sig = wsig
    Engine.stats.tx_wallet = (Engine.stats.tx_wallet or 0) + 1
    -- Live E3 var for Fleet $ (remote Mono query; no sidecar wait).
    pcall(function()
        local enc = snapshot.encode_wallet_e3 and snapshot.encode_wallet_e3(snap) or ""
        if enc ~= "" then mq.cmdf('/squelch /e3varset TurboFW %s', enc) end
    end)
    local mail_ok = nil
    if Engine.ok then
        mail_ok = send_mail("wallet", {
            type = MSG.WALLET,
            proto = CFG.proto,
            kind = 'client',
            snap = {
                name = snap.name,
                server = snap.server,
                class = snap.class,
                level = snap.level,
                updated = snap.updated or os.time(),
                depth = 'wallet',
                platinum = snap.platinum,
                diamond_coins = snap.diamond_coins,
                radiant_crystals = snap.radiant_crystals,
                ebon_crystals = snap.ebon_crystals,
                planar_symbols = snap.planar_symbols,
                taelosian_symbols = snap.taelosian_symbols,
                tribute_favor = snap.tribute_favor,
                celestial_crests = snap.celestial_crests,
                nightveil_scrip = snap.nightveil_scrip,
                aa_unspent = snap.aa_unspent,
                _walletDiagReason = snap._walletDiagReason,
                _walletDiagPublishMs = snap._walletDiagPublishMs,
            },
        })
    end
    if wallet_settle_diag and diag.is_enabled and diag.is_enabled() then
        print(string.format("[TurboGear] wallet settle: MSG.WALLET send t=%d name=%s pp=%s sent=%s",
            wallet_diag_ms(), tostring(snap.name), tostring(snap.platinum), tostring(Engine.ok and mail_ok ~= false)))
    end
    pcall(function() Store.put_wallet(snap, 'client') end)
    diag.event("engine.publish_wallet", string.format("reason=%s name=%s",
        tostring(opts.reason or "wallet"), tostring(snap.name)))
    return true
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
        annotate_inventory_publish(snap, {
            reason = tostring(opts.reason or "prebuilt"),
            requestedDepth = snap.depth,
            gatherResult = "local-cache",
        })
        diag.time("engine.publish_snapshot.store_put", function()
            Store.put(snap, 'cache')
        end)
        diag.time("engine.publish_snapshot.store_save", function()
            Store.save({ only_self = true })
        end)
        return true
    end
    return diag.time("engine.publish_snapshot", function()
        local gs = mq.TLO.EverQuest.GameState()
        if gs and gs ~= "INGAME" then return false end
        local publish_reason = tostring(opts.reason or "prebuilt")
        annotate_inventory_publish(snap, {
            reason = publish_reason,
            requestedDepth = snap.depth,
            gatherResult = snap.inventoryIncomplete == true and "incomplete" or "ok",
            published = false,
        })
        diag.context("engine.publish_snapshot", string.format("reason=%s depth=%s skipLockouts=%s skipLiveStats=%s bg=%s lean=%s",
            publish_reason, tostring(snap.depth or ""),
            tostring(opts.skipLockouts == true), tostring(opts.skipLiveStats == true),
            tostring(state.bg == true), tostring(state.lean and state.lean() or false)))

        local sig = snapshot.lite_signature(snap)
        local wsig = snapshot.wallet_signature and snapshot.wallet_signature(snap) or ""
        if opts.force ~= true and sig == Engine.last_publish_sig then
            if wsig ~= "" and wsig ~= tostring(Engine.last_wallet_sig or "") then
                return Engine.publish_wallet(snap, { reason = publish_reason .. "_wallet" })
            end
            Engine.last_publish = os.clock()
            schedule_next_publish(Engine.last_publish)
            Engine.stats.tx_skip = (Engine.stats.tx_skip or 0) + 1
            if Engine.last_gather_diag then Engine.last_gather_diag.result = "unchanged" end
            send_mail("heartbeat_unchanged", { type = MSG.HEARTBEAT, proto = CFG.proto, kind = 'client', snap = {
                name = snap.name,
                server = snap.server,
                class = snap.class,
                level = snap.level,
                updated = snap.updated,
            } })
            diag.time("engine.publish_snapshot.store_touch", function()
                Store.touch(snap, 'client')
            end)
            diag.event("engine.publish_snapshot", string.format("skipped unchanged reason=%s depth=%s eq=%d bag=%d bank=%d",
                publish_reason, tostring(snap.depth or ""), #(snap.equipped or {}), #(snap.bags or {}), #(snap.bank or {})))
            return false
        end

        Engine.last_publish_sig = sig
        Engine.last_wallet_sig = wsig
        Engine.last_publish = os.clock()
        schedule_next_publish(Engine.last_publish)
        Engine.stats.tx_snap = Engine.stats.tx_snap + 1
        annotate_inventory_publish(snap, {
            reason = publish_reason,
            requestedDepth = snap.depth,
            gatherResult = "sent",
        })
        send_mail("snapshot", {
            type = MSG.SNAPSHOT,
            proto = CFG.proto,
            kind = 'client',
            snap = snap,
            replyTo = opts.replyTo,
            requester = opts.requester,
        })
        diag.time("engine.publish_snapshot.store_put", function()
            Store.put(snap, 'client')
        end)
        pcall(function() require('inventory_watch').note_published_snapshot(snap) end)
        if opts.saveNow == true then
            -- Hot path (worn_persist / urgent inventory): only this box's row.
            -- Full-fleet serialize was freezing Discord bg for minutes.
            diag.time("engine.publish_snapshot.store_save", function()
                Store.save({ only_self = true })
            end)
        else
            pcall(function()
                diag.time("engine.publish_snapshot.wallet_sidecar", function()
                    Store.flush_wallet_sidecar()
                end)
            end)
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

--- Broadcast a BiS-style catalog FindItem search for list_id.
function Engine.request_bis_search(list_id, opts)
    if not Engine.ok then return false end
    opts = type(opts) == "table" and opts or {}
    list_id = tostring(list_id or "")
    if list_id == "" then return false end
    diag.count("engine.bis_search_request")
    local ok_bs, bis_search = pcall(require, 'bis_search')
    if ok_bs and bis_search then
        if opts.force ~= true and bis_search.should_request and not bis_search.should_request(list_id) then
            diag.count("engine.bis_search_request_skipped")
            return false
        end
        if bis_search.mark_requested then bis_search.mark_requested(list_id) end
        -- Answer locally first so the UI host paints without waiting on the bus.
        local local_result = bis_search.search_local and diag.time("engine.bis_search_tx_local", function()
            return bis_search.search_local(list_id)
        end)
        if type(local_result) == "table" then
            bis_search.apply_result(local_result)
            pcall(function()
                diag.time("engine.bis_search_save", function()
                    bis_search.save()
                end)
            end)
        end
    end
    diag.count("engine.bis_search_tx")
    diag.event("engine.bis_search_tx", "list=" .. list_id)
    send_mail("bis_search", {
        type = MSG.BIS_SEARCH,
        proto = CFG.proto,
        list_id = list_id,
        from = this_name(),
        targetName = opts.targetName,
        targetServer = opts.strictServer == true and opts.targetServer or nil,
    })
    return true
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
    return Engine.publish(true, "full", {
        skipLockouts = true,
        skipLiveStats = true,
        reason = "inventory_change",
        allowBlockingFull = true,
    })
end

function Engine.sync_bank_now()
    if not snapshot.bank_window_open or not snapshot.bank_window_open() then
        set_sync_hint("Open the bank first, then Sync Bank.", 3.0)
        return false
    end
    snapshot.invalidate()
    local ok = Engine.publish(true, "full", { reason = "manual_bank_sync", saveNow = true, allowBlockingFull = true })
    Engine.last_bank_capture = os.clock()
    set_sync_hint(ok and "Bank contents synced." or "Bank sync requested.", 3.0)
    return ok
end

function Engine.sync_banks_network()
    local local_open = snapshot.bank_window_open and snapshot.bank_window_open() or false
    if local_open then
        snapshot.invalidate()
        Engine.publish(true, "full", { reason = "network_bank_sync", saveNow = true, allowBlockingFull = true })
        Engine.last_bank_capture = os.clock()
    end
    Engine.request_all(true, { depth = "full" })
    Engine.begin_startup_sync(8.0)
    set_sync_hint(local_open and "Bank synced; requesting peer banks..." or "Requesting peer banks. Open bank on the owner first.", 4.0)
    return true
end

local function capture_open_bank(reason, hint_seconds)
    if not snapshot.bank_window_open or not snapshot.bank_window_open() then return false end
    snapshot.invalidate()
    local ok = Engine.publish(true, "full", {
        skipLockouts = true,
        skipLiveStats = true,
        reason = reason or "bank_capture",
        saveNow = true,
        allowBlockingFull = true,
    })
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

--- Names a lockout map holds, for the diagnostic trail. A snapshot that goes
--- out with the wrong set here is the difference between "the peer never told
--- us" and "it told us and the cell is wrong".
local function locked_names(map)
    local names = {}
    for cat, entries in pairs(map or {}) do
        if type(entries) == "table" and cat ~= "DoNState" then
            for name, rec in pairs(entries) do
                if type(rec) == "table" and rec.found == true then names[#names + 1] = name end
            end
        end
    end
    table.sort(names)
    return #names > 0 and table.concat(names, ", ") or "nothing"
end

--- The second source the watcher below checks.
---
--- DoN missions are tasks, not dynamic zones, so none of their state reaches
--- timer_signature. It moves on chat capture, on a /tasktime sweep settling,
--- and on the journal read noticing a mission accepted or completed -- none of
--- which touch inventory either, so without a check here a peer's DoN state
--- would ship only when something unrelated happened to publish.
local function don_signature()
    local ok, dt = pcall(require, 'don_track')
    if not ok or type(dt) ~= "table" or type(dt.signature) ~= "function" then return nil end
    -- Digest only. A Task journal walk on the same tick as DynamicZone is the
    -- idle bg-only crash path. don_track.tick refreshes Active on its own TTL.
    local got, sig = pcall(dt.signature)
    if not got or type(sig) ~= "string" then return nil end
    return sig
end

--- Ship a lockout change that no other path would notice.
---
--- lite_signature is built from equipped/bags/bank/spells, so gaining or losing
--- a lockout leaves it byte-identical and publish drops the send as "inventory
--- unchanged". With autoPeerRefresh off the scheduled tick only heartbeats, so
--- nothing ships at all. Peers therefore learned lockouts only from a request
--- -- startup or Sync Now -- which is why a box that earned one while idle
--- never volunteered it.
---
--- Detection reads the raw DynamicZone rows rather than the matched map.
--- gather_local caches for 300s on a responder, so polling it would re-read the
--- same stale answer four checks out of five and miss a new lockout for
--- minutes; forcing it instead risks opening the Expedition window on a box
--- where the TLO cannot be read. timer_signature has neither problem, and it
--- skips the per-entry matching on the common no-change path.
---
--- Two independent sources, one publish: either can trigger it, and each is
--- baselined only if it was the one that moved.
local function tick_lockout_change()
    local now = os.clock()
    if now < lockout_watch.next_at then return false end
    lockout_watch.next_at = now + (tonumber(CFG.lockout_check_s) or 60.0)

    local ok, lo = pcall(require, 'lockouts')
    if not ok or type(lo) ~= "table" or type(lo.timer_signature) ~= "function" then return false end

    local got, sig = pcall(lo.timer_signature)
    -- nil means the TLO could not be read. Unknown is not a change.
    if not got or type(sig) ~= "string" then sig = nil end

    local don_sig = don_signature()
    local don_changed = false
    if don_sig ~= nil then
        if lockout_watch.don == nil then
            -- "C0" is a box that knows nothing and holds nothing: there is
            -- genuinely nothing to announce, so baseline quietly. Anything else
            -- is state a viewer may not have, and the startup publish skips
            -- lockouts entirely, so say it once.
            if don_sig == "C0" then
                lockout_watch.don = don_sig
            else
                don_changed = true
            end
        elseif don_sig ~= lockout_watch.don then
            don_changed = true
        end
    end

    -- nil means unreadable, which is not a change: leave the baseline alone.
    local expedition_changed = false
    if sig ~= nil then
        if lockout_watch.sig == nil then
            -- Reconcile rather than blindly trusting the first sample. The
            -- startup publish can go out before the client has populated
            -- DynamicZone, so a silent baseline would adopt the correct timers,
            -- say nothing, and leave the viewer stale until some unrelated
            -- change. Compare against the raw state the cached map was actually
            -- built from -- which is what we last published -- and only stay
            -- quiet if they agree.
            local built = type(lo.last_built_signature) == "function" and lo.last_built_signature() or nil
            if built == sig or (built == nil and sig == "") then
                lockout_watch.sig = sig
                diag.event("engine.lockout_change", "baseline matches last gather; nothing to correct")
            else
                expedition_changed = true
                diag.event("engine.lockout_change", string.format(
                    "startup correction: published state was %s, timers now %s",
                    built == nil and "never gathered" or (built == "" and "no timers" or "different"),
                    sig == "" and "none" or "present"))
            end
        elseif sig ~= lockout_watch.sig then
            expedition_changed = true
        end
    end

    if not expedition_changed and not don_changed then return true end

    -- The timer set really moved, so pay for a matched read now. Bypass the
    -- cache, but never let this open the Expedition window: we only got here
    -- because the structured TLO answered, and this runs on background boxes.
    local gotmap, map = pcall(function()
        return lo.gather_local({ bypass_cache = true, allow_window_fallback = false })
    end)
    if not gotmap or type(map) ~= "table" then return true end

    -- Inventory is not an input to this publish. Carry the latest authoritative
    -- equipped/bags/bank forward; only lockouts/DoNState change.
    local publish_reason = "lockout_change"
    if don_changed and not expedition_changed then publish_reason = "don_change" end
    local out = nil
    pcall(function()
        out = snapshot.prepare_metadata_publish({ lockouts = map }, { reason = publish_reason })
    end)
    if type(out) ~= "table" or not out.name or out.name == "?" then return true end
    diag.event("engine.lockout_change", string.format("publishing locked: %s%s",
        locked_names(map), don_changed and " (+DoN state changed)" or ""))
    -- Only accept the new state once it has actually gone out. Committing it up
    -- front meant a transient failure below -- a failed gather, a snapshot taken
    -- mid-zone -- silently adopted the change as the new baseline and never
    -- announced it. Every early return above leaves both signatures in place so
    -- the next interval tries again.
    if not Engine.publish_snapshot(out, { force = true, reason = publish_reason }) then return true end
    if expedition_changed then lockout_watch.sig = sig end
    if don_changed then lockout_watch.don = don_sig end
    return true
end

function Engine.heartbeat()
    if not Engine.ok then return end
    -- R5: keep the readiness marker fresh while we own the mailbox (throttled).
    if os.clock() >= (Engine.next_ready_write or 0) then
        Engine.next_ready_write = os.clock() + (tonumber(CFG.bg_ready_write_every_s) or 20.0)
        pcall(function() if cfg.write_bg_ready then cfg.write_bg_ready() end end)
    end
    if not Engine.ingame() then return end
    -- One native TLO family per heartbeat. Idle bg-only crashes were
    -- inventory + DynamicZone + Task + worn poll landing on the same tick.
    Engine._heavy_tlo = nil
    if Engine.apply_pending_request() then
        Engine._heavy_tlo = "inventory"
    end
    Engine.apply_pending_bis_search()
    Engine.apply_pending_announce()
    tick_bank_capture()
    prune_dedupe_maps()
    tick_zone_meta()
    if Engine._heavy_tlo == nil
        and Engine.lockout_watch_wanted
        and tick_lockout_change() then
        Engine.lockout_watch_wanted = nil
        Engine._heavy_tlo = "dz"
    end
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
M._apply_pending_request = Engine.apply_pending_request
-- Same reason: the lockout watcher is driven from heartbeat, which a test
-- cannot run without a live actor mailbox. The watch table is exposed so a test
-- can rewind the interval and clear the baseline between cases.
M._tick_lockout_change = tick_lockout_change
M._lockout_watch = lockout_watch
return M
