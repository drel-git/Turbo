-- TurboGear/inventory_watch.lua
-- Event-driven inventory change detection: invalidates snapshot cache and
-- publishes lite snapshots when gear actually changes (even in bg/lean mode).

local mq = require('mq')
local cfg = require('config')
local CFG = cfg.CFG
local snapshot = require('snapshot')
local snapshot_delta = require('snapshot_delta')
local state = require('state')
local diag = require('diagnostics')

local M = { registered = false }

local dirty_at = nil
local dirty_urgent = false
local dirty_full = false
local last_publish_at = 0
local last_known_sig = nil
local last_bg_poll_at = 0
-- Forward decl: worn refresh calls this before its definition below.
local publish_snap_if_changed
-- Baseline of the last state peers received (full snapshot or delta), used to
-- compute changed-slot deltas. { equipped/bags/bank = slot_key -> item }.
local delta_baseline = nil
local delta_baseline_bank = false
-- UI viewer: prefer adopting bg-saved Store self over a local bag TLO walk
-- (avoids hitch on Give Now). Counts down on tick; no bag-scan fallback
-- (optimistic give delta + later bg note cover the UI).
local store_adopt_retries = 0

local function enabled()
    return CFG.inventory_watch_enabled ~= false
end

local function debounce_s()
    return tonumber(CFG.inventory_watch_debounce_s) or 0.4
end

local function publish_cooldown_s()
    return tonumber(CFG.inventory_watch_publish_cooldown_s) or 2.0
end

local function bg_poll_s()
    -- Must match config.lua default (0.0 = disabled). Never fall back to a periodic scan.
    return tonumber(CFG.inventory_watch_bg_poll_s) or 0.0
end

local function mark_dirty(urgent, full)
    if not enabled() then return end
    dirty_at = urgent and (os.clock() - debounce_s()) or os.clock()
    dirty_urgent = dirty_urgent or urgent == true
    dirty_full = dirty_full or full == true
    diag.count("inventory_watch.dirty")
end

local function on_inventory_line(_line)
    mark_dirty()
end

-- Prefer bg Store adopt on the UI (no bag TLO walk / hitch). Bg still gathers.
local function try_adopt_store_self(force_reload)
    local ok_store, store_mod = pcall(require, 'store')
    if not ok_store or not store_mod or not store_mod.Store then return false end
    local Store = store_mod.Store
    if force_reload and Store.reload_cache_if_changed then
        pcall(Store.reload_cache_if_changed, true)
    elseif Store.reload_cache_if_changed then
        pcall(Store.reload_cache_if_changed, false)
    end
    local key = store_mod.my_key and store_mod.my_key() or nil
    if not key or key == "" then return false end
    local s = Store.get(key)
    if type(s) ~= "table" or type(s.bags) ~= "table" then return false end
    local cached = snapshot.cached()
    local store_ts = tonumber(s.inventoryUpdated or s.updated) or 0
    local cache_ts = tonumber(cached and (cached.inventoryUpdated or cached.updated)) or 0
    if store_ts <= cache_ts then return false end
    if not snapshot.adopt or not snapshot.adopt(s) then return false end
    last_known_sig = snapshot.lite_signature(s)
    diag.count("inventory_watch.store_adopt")
    return true
end

-- Trade/give: bags change — urgent lite flush (bag walk). Equip/remove use
-- on_worn_line (targeted equipped patch) instead; do not route them here.
local function on_gear_line(_line)
    -- UI viewer: wait for bg lite save + adopt (avoids mid-frame bag scan hitch).
    if state.engine_claim_disabled == true then
        store_adopt_retries = math.max(store_adopt_retries, 12)
        return
    end
    mark_dirty(true, false)
end

local function on_bank_line(_line)
    mark_dirty(true, true)
end

-- Phase 2: worn change detection. Local BiS uses live FindItem (no persist).
-- Persist/publish for peers is debounced — never saveNow on the UI thread.
local last_worn_sig, last_worn_poll_at = nil, 0
local worn_persist_due_at = nil
local worn_persist_snap = nil
local last_known_wallet_sig = nil

local function worn_persist_debounce_s()
    local s = tonumber(CFG.perf_worn_persist_debounce_s) or 2.5
    if s < 0.5 then s = 0.5 end
    return s
end

local function schedule_worn_persist(snap)
    if type(snap) ~= "table" then return end
    worn_persist_snap = snap
    worn_persist_due_at = os.clock() + worn_persist_debounce_s()
    diag.count("inventory_watch.worn_persist_scheduled")
end

local function persist_worn_snap(snap)
    if type(snap) ~= "table" then return false end
    -- Actor publish immediately; disk save is debounced via Store content_flush
    -- (slim persist). saveNow=true was re-serializing the full rich row (30–60s).
    local opts = {
        skipLockouts = true,
        skipLiveStats = true,
        reason = "worn_persist",
        saveNow = false,
        force = true,
    }
    -- Always try publish_snapshot (not gated on Engine.ok). When the actor is
    -- down it still Store.put so content_flush persists the slim row.
    local okE, Engine = pcall(function() return require('engine').Engine end)
    if okE and Engine and Engine.publish_snapshot then
        if Engine.publish_snapshot(snap, opts) == true then
            last_known_sig = snapshot.lite_signature(snap)
            if snapshot.wallet_signature then
                last_known_wallet_sig = snapshot.wallet_signature(snap)
            end
            last_publish_at = os.clock()
            diag.count("inventory_watch.worn_persist_flush")
            return true
        end
    end
    -- Last resort: put + let content_flush / next save tick write slim row.
    local saved = false
    pcall(function()
        local Store = require('store').Store
        Store.put(snap, 'client')
        saved = true
    end)
    if saved then
        last_known_sig = snapshot.lite_signature(snap)
        if snapshot.wallet_signature then
            last_known_wallet_sig = snapshot.wallet_signature(snap)
        end
        last_publish_at = os.clock()
        diag.count("inventory_watch.worn_persist_flush")
        diag.count("inventory_watch.worn_persist_direct_save")
        return true
    end
    diag.count("inventory_watch.worn_persist_fail")
    return false
end

local function flush_worn_persist_if_due()
    if not worn_persist_due_at then return end
    local now = os.clock()
    if now < worn_persist_due_at then return end
    local snap = worn_persist_snap
    worn_persist_due_at = nil
    worn_persist_snap = nil
    if type(snap) ~= "table" then return end
    -- Debounced peer update: one publish/save after gear settles — not per equip.
    if not persist_worn_snap(snap) then
        -- Keep the patched snap; short retry (not full debounce) so one fail
        -- does not wait another 2.5s while peers stay stale.
        worn_persist_snap = snap
        worn_persist_due_at = os.clock() + 0.5
        diag.count("inventory_watch.worn_persist_retry")
    end
end

local function note_worn_sig_changed()
    pcall(function()
        local bis = require('bis')
        if bis.invalidate_live_ownership_cache then
            bis.invalidate_live_ownership_cache()
        end
    end)
end

-- UI viewer: display is live TLO — only invalidate live cache + seed worn sig.
-- Never refresh_equipped / publish / save on the UI thread (that was the hitch).
local function apply_worn_ui_only()
    if snapshot.worn_signature then
        last_worn_sig = snapshot.worn_signature()
    end
    note_worn_sig_changed()
    diag.count("inventory_watch.worn_ui_live")
    -- Let bg adopt/publish when it notices; UI does not Store.save here.
    store_adopt_retries = math.max(store_adopt_retries, 4)
    return true
end

local function apply_worn_refresh(now, reason)
    -- UI path: zero persist cost.
    if state.engine_claim_disabled == true then
        return apply_worn_ui_only()
    end
    if not snapshot.refresh_equipped or not snapshot.cached() then return false end
    local snap = snapshot.refresh_equipped("lite")
    if not snap then return false end
    if snapshot.worn_signature then
        last_worn_sig = snapshot.worn_signature()
    end
    note_worn_sig_changed()
    diag.count("inventory_watch.worn_refresh")
    schedule_worn_persist(snap)
    return true
end

local function on_worn_line(_line)
    local now = os.clock()
    if apply_worn_refresh(now, "worn_event") then return end
    if state.engine_claim_disabled == true then
        apply_worn_ui_only()
        return
    end
    mark_dirty(true, false)
end

local function poll_equipped_if_due()
    if CFG.perf_equip_poll == false then return end
    if not snapshot.worn_signature then return end
    local interval = tonumber(CFG.perf_equip_poll_interval_s) or 1.0
    if interval <= 0 then return end
    local now = os.clock()
    if (now - last_worn_poll_at) < interval then return end
    last_worn_poll_at = now

    local sig = snapshot.worn_signature()
    if sig == last_worn_sig then return end
    if last_worn_sig == nil then
        last_worn_sig = sig -- seed; no phantom on first observation
        return
    end
    last_worn_sig = sig
    diag.count("inventory_watch.worn_change")
    apply_worn_refresh(now, "worn_poll")
end

-- Record what peers now hold so future deltas diff against the right base.
function M.note_published_snapshot(snap)
    if type(snap) ~= "table" then return end
    local include_bank = snap.bankLive == true
    delta_baseline = snapshot_delta.baseline_from_snapshot(snap, { include_bank = include_bank })
    delta_baseline_bank = include_bank
end

-- Small, urgent path: ship just the changed slots the moment gear changes.
-- Runs even when the full publish is throttled by its cooldown. Falls back to
-- nothing (full publish will cover it) when the diff is big or has no baseline.
local function publish_delta_if_small(snap)
    if CFG.delta_publish_enabled == false then return false end
    if type(snap) ~= "table" or type(delta_baseline) ~= "table" then return false end
    local include_bank = delta_baseline_bank and snap.bankLive == true
    local delta, count = snapshot_delta.diff_snapshot(delta_baseline, snap, { include_bank = include_bank })
    if not delta or count == 0 then return false end
    local max_items = tonumber(CFG.delta_max_items) or 24
    if count > max_items then return false end
    local ok, Engine = pcall(function() return require('engine').Engine end)
    if not ok or not Engine or not Engine.ok or not Engine.publish_delta then return false end
    if Engine.publish_delta(delta) then
        -- Advance the baseline: peers now have this state.
        M.note_published_snapshot(snap)
        diag.count("inventory_watch.delta_publish")
        return true
    end
    return false
end

publish_snap_if_changed = function(snap, now, depth, bypass_cooldown, publish_opts)
    if not snap then return false end
    local sig = snapshot.lite_signature(snap)
    local wsig = snapshot.wallet_signature and snapshot.wallet_signature(snap) or ""
    if sig == last_known_sig then
        -- Bags unchanged but PP/CC/etc moved: tiny wallet publish (no bag walk).
        if wsig ~= "" and wsig ~= tostring(last_known_wallet_sig or "") then
            local ok, Engine = pcall(function() return require('engine').Engine end)
            if ok and Engine and Engine.publish_wallet and Engine.publish_wallet(snap, {
                reason = "inventory_watch_wallet",
                force = true,
            }) then
                last_known_wallet_sig = wsig
                last_publish_at = now
                diag.count("inventory_watch.wallet_publish")
                return true
            end
        end
        return false
    end
    if not bypass_cooldown and (now - last_publish_at) < publish_cooldown_s() then
        dirty_at = now
        -- Full publish is throttled; get the changed slots out immediately.
        publish_delta_if_small(snap)
        return false
    end
    local ok, Engine = pcall(function() return require('engine').Engine end)
    -- Call publish_snapshot even when Engine.ok is false — it has a Store.put+save
    -- fallback. Gating on Engine.ok left worn/inventory changes unpublished and
    -- (previously) burned last_known_sig so they never retried.
    if ok and Engine then
        local sent
        if Engine.publish_snapshot then
            sent = Engine.publish_snapshot(snap, publish_opts)
        elseif Engine.ok then
            sent = Engine.publish(true, depth == "full" and "full" or "lite", publish_opts)
        end
        if sent then
            last_known_sig = sig
            last_known_wallet_sig = wsig
            last_publish_at = now
            diag.count("inventory_watch.publish")
            return true
        end
    end
    -- Engine publish unavailable or skipped: still try the delta path so peers
    -- hear about the change quickly.
    publish_delta_if_small(snap)
    return false
end

-- True when a bag/equipped slot lost a spell-like item (scribe consume) or its
-- stack qty dropped. Uses the delta baseline the watch already maintains.
local function spell_like_removed(baseline, snap)
    if type(baseline) ~= "table" or type(snap) ~= "table" then return false end
    local okSC, SC = pcall(require, 'spell_cache')
    if not okSC or not SC or not SC.is_spell_like_item then return false end
    local okD, delta_mod = pcall(require, 'snapshot_delta')
    if not okD or not delta_mod then return false end
    local delta = select(1, delta_mod.diff_snapshot(baseline, snap, { include_bank = false }))
    if type(delta) ~= "table" then return false end
    for _, bucket in ipairs({ "bags", "equipped" }) do
        local base_bucket = baseline[bucket]
        if type(base_bucket) == "table" then
            for _, key in ipairs((delta.removed and delta.removed[bucket]) or {}) do
                local old = base_bucket[key]
                if old and SC.is_spell_like_item(old.name, old.id) then
                    return true
                end
            end
            for _, item in ipairs((delta.changed and delta.changed[bucket]) or {}) do
                local key = delta_mod.slot_key(item)
                local old = key ~= "" and base_bucket[key] or nil
                if old and SC.is_spell_like_item(old.name, old.id) then
                    local old_id = tonumber(old.id) or 0
                    local new_id = tonumber(item.id) or 0
                    if old_id > 0 and old_id ~= new_id then
                        return true
                    end
                    local old_qty = tonumber(old.qty or old.count) or 1
                    local new_qty = tonumber(item.qty or item.count) or 1
                    if new_qty < old_qty then
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function maybe_spell_republish(snap, baseline)
    if not spell_like_removed(baseline, snap) then return false end
    diag.count("inventory_watch.spell_like_removed")
    local okSC, SC = pcall(require, 'spell_cache')
    if not okSC or not SC then return false end
    SC.rebuild(snap and snap.class)
    local published = select(1, SC.publish_if_changed("inventory_spell_consume"))
    if published then
        diag.count("inventory_watch.spell_publish")
    end
    return published == true
end

local function flush_if_due()
    if not enabled() or not dirty_at then return false end
    local now = os.clock()
    if (now - dirty_at) < debounce_s() then return false end
    dirty_at = nil

    snapshot.invalidate()
    local urgent = dirty_urgent == true
    dirty_urgent = false
    local full = dirty_full == true
    dirty_full = false
    local depth = full and "full" or "lite"
    local publish_opts = { skipLockouts = true, skipLiveStats = true, reason = "inventory_watch_dirty" }
    -- Urgent changes (go-loot, equip/bank) bypass the publish cooldown and flush
    -- the shared cache so the announce UI can reload without waiting ~30s.
    if urgent then publish_opts.saveNow = true end
    local baseline_before = delta_baseline
    local snap = snapshot.gather({
        force = true,
        depth = depth,
        noCoalesce = true, -- real inventory change; never reuse a coalesced force gather
        skipLockouts = publish_opts and publish_opts.skipLockouts == true,
        skipLiveStats = publish_opts and publish_opts.skipLiveStats == true,
    })
    -- Scribe path: scroll/tome removed → rebuild known-cache + spell publish.
    -- Cheap name/id pre-check; full spell gather only on a positive match.
    if maybe_spell_republish(snap, baseline_before) then
        -- Spell publish already shipped inventory+spells; refresh local sig.
        if snap then last_known_sig = snapshot.lite_signature(snap) end
        return true
    end
    return publish_snap_if_changed(snap, now, depth, urgent, publish_opts)
end

local function bg_poll_if_due()
    if not enabled() or not state.bg then return end
    local interval = bg_poll_s()
    if interval <= 0 then return end
    local now = os.clock()
    if (now - last_bg_poll_at) < interval then return end
    last_bg_poll_at = now

    if dirty_at then return end
    local snap = snapshot.gather({
        force = false,
        depth = "lite",
        skipLockouts = true,
        skipLiveStats = true,
    })
    if not snap then return end
    local sig = snapshot.lite_signature(snap)
    if sig == last_known_sig then return end

    -- Scribe/memorize often emits no watched chat line, so flush_if_due never
    -- runs. On any inventory sig change, refresh known-cache; publish_if_changed
    -- is a no-op when the known-set is unchanged.
    local baseline_before = delta_baseline
    if maybe_spell_republish(snap, baseline_before) then
        last_known_sig = sig
        return
    end
    -- No spell-like removal detected (or no baseline yet): still rebuild so a
    -- silent scribe can't leave peers/UI on a pre-scribe known-set forever.
    local published = false
    pcall(function()
        local SC = require('spell_cache')
        SC.rebuild(snap and snap.class)
        published = SC.publish_if_changed('inventory_watch_bg_poll') == true
    end)
    if published then
        last_known_sig = sig
        diag.count("inventory_watch.spell_publish")
        return
    end

    publish_snap_if_changed(snap, now, "lite", false, {
        skipLockouts = true,
        skipLiveStats = true,
        reason = "inventory_watch_bg_poll",
    })
end

function M.register()
    if M.registered or not enabled() then return end
    local opts = { keepLinks = false }
    pcall(function() mq.event('tgearInvLoot1', 'You receive #*#from #*#corpse#*#', on_inventory_line, opts) end)
    pcall(function() mq.event('tgearInvLoot2', '#*#You have looted #*#from #*#corpse#*#', on_inventory_line, opts) end)
    pcall(function() mq.event('tgearInvLoot3', 'You have looted #*#', on_inventory_line, opts) end)
    pcall(function() mq.event('tgearInvTrade', 'You complete the trade#*#', on_gear_line, opts) end)
    pcall(function() mq.event('tgearInvGive', 'You give #*#to #*#', on_gear_line, opts) end)
    pcall(function() mq.event('tgearInvBank', 'You put #*#', on_bank_line, opts) end)
    pcall(function() mq.event('tgearInvPick', 'You pick up #*#', on_bank_line, opts) end)
    -- Equip/remove: targeted worn patch (not the bag-walk gear flush).
    pcall(function() mq.event('tgearInvEquip', 'You equip #*#', on_worn_line, opts) end)
    pcall(function() mq.event('tgearInvRemove', 'You remove #*#', on_worn_line, opts) end)
    pcall(function() mq.event('tgearInvDestroy', 'You destroy #*#', on_inventory_line, opts) end)
    -- Scribe/memorize: scroll vanishes; these lines are the usual tells.
    pcall(function() mq.event('tgearInvScribe1', '#*#You have learned #*#', on_inventory_line, opts) end)
    pcall(function() mq.event('tgearInvScribe2', '#*#You have scribed #*#', on_inventory_line, opts) end)
    M.registered = true
end

function M.unregister()
    if not M.registered then return end
    pcall(function() mq.unevent('tgearInvLoot1') end)
    pcall(function() mq.unevent('tgearInvLoot2') end)
    pcall(function() mq.unevent('tgearInvLoot3') end)
    pcall(function() mq.unevent('tgearInvTrade') end)
    pcall(function() mq.unevent('tgearInvGive') end)
    pcall(function() mq.unevent('tgearInvBank') end)
    pcall(function() mq.unevent('tgearInvPick') end)
    pcall(function() mq.unevent('tgearInvEquip') end)
    pcall(function() mq.unevent('tgearInvRemove') end)
    pcall(function() mq.unevent('tgearInvDestroy') end)
    pcall(function() mq.unevent('tgearInvScribe1') end)
    pcall(function() mq.unevent('tgearInvScribe2') end)
    M.registered = false
    dirty_at = nil
    dirty_urgent = false
    dirty_full = false
end

function M.tick()
    if not enabled() then return end
    -- UI viewer: prefer Store adopt from bg; only bag-scan as last resort.
    if state.engine_claim_disabled == true then
        diag.time("inventory_watch.tick_ui", function()
            -- Live BiS only: poll seeds sig + invalidates FindItem cache. No save.
            poll_equipped_if_due()
            if store_adopt_retries > 0 then
                if try_adopt_store_self(store_adopt_retries % 3 == 0) then
                    store_adopt_retries = 0
                    dirty_at = nil
                    dirty_urgent = false
                    dirty_full = false
                    return
                end
                store_adopt_retries = store_adopt_retries - 1
                if store_adopt_retries <= 0 and not dirty_at then
                    -- No UI bag-scan fallback: optimistic give delta already
                    -- refreshed counts; bg note may still land later.
                    diag.count("inventory_watch.store_adopt_miss")
                end
            end
            if dirty_at and try_adopt_store_self(false) then
                dirty_at = nil
                dirty_urgent = false
                dirty_full = false
                return
            end
            flush_if_due()
        end)
        return
    end
    diag.time("inventory_watch.tick", function()
        poll_equipped_if_due()
        flush_worn_persist_if_due()
        flush_if_due()
        bg_poll_if_due()
    end)
end

function M.seed_signature()
    local snap = snapshot.cached() or snapshot.gather({ force = false, depth = "lite" })
    if snap then last_known_sig = snapshot.lite_signature(snap) end
    if snapshot.worn_signature then
        last_worn_sig = snapshot.worn_signature()
    end
end

-- Call from bg startup after the actor mailbox is claimed. Builds the known
-- cache once and publishes when the signature is new.
function M.startup_spell_cache()
    if state.bg ~= true then return end
    pcall(function()
        local SC = require('spell_cache')
        SC.rebuild()
        SC.publish_if_changed('startup')
    end)
end

-- Explicit dirty mark for scripted loot / trade paths that may not emit the
-- chat lines our events watch (e.g. go-loot itemnotify). urgent=true skips
-- debounce so the next tick can publish a lite snap promptly.
function M.note_change(urgent, full)
    mark_dirty(urgent == true, full == true)
end

-- UI: request Store adopt retries after Give Now /tgear note (no sync bag walk).
function M.request_store_adopt(retries)
    store_adopt_retries = math.max(store_adopt_retries, math.max(1, math.floor(tonumber(retries) or 8)))
end

function M.try_adopt_store_self(force_reload)
    return try_adopt_store_self(force_reload == true)
end

-- True while gear/bags are still in flux (or just finished a worn publish).
-- Callers (needs-index) should defer heavy rebuilds; announce stays live-accurate.
function M.inventory_settling()
    if CFG.perf_needs_gear_settle == false then return false end
    local pad = tonumber(CFG.perf_needs_gear_settle_s)
    if pad == nil then pad = 2.0 end
    if pad < 0 then pad = 0 end
    local now = os.clock()
    if worn_persist_due_at and now <= worn_persist_due_at then return true end
    if dirty_at then return true end
    if last_publish_at > 0 and (now - last_publish_at) < pad then return true end
    local ok, store_mod = pcall(require, 'store')
    if ok and store_mod and store_mod.Store and store_mod.Store.persist_busy then
        local busy = false
        pcall(function() busy = store_mod.Store.persist_busy() == true end)
        if busy then return true end
    end
    return false
end

return M
