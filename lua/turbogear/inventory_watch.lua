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
-- Baseline of the last state peers received (full snapshot or delta), used to
-- compute changed-slot deltas. { equipped/bags/bank = slot_key -> item }.
local delta_baseline = nil
local delta_baseline_bank = false

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
    return tonumber(CFG.inventory_watch_bg_poll_s) or 12.0
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

local function on_gear_line(_line)
    mark_dirty(true, true)
end

local function on_bank_line(_line)
    mark_dirty(true, true)
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

local function publish_snap_if_changed(snap, now, depth, bypass_cooldown, publish_opts)
    if not snap then return false end
    local sig = snapshot.lite_signature(snap)
    if sig == last_known_sig then return false end
    if not bypass_cooldown and (now - last_publish_at) < publish_cooldown_s() then
        dirty_at = now
        -- Full publish is throttled; get the changed slots out immediately.
        publish_delta_if_small(snap)
        return false
    end
    last_known_sig = sig
    local ok, Engine = pcall(function() return require('engine').Engine end)
    if ok and Engine and Engine.ok then
        local sent
        if Engine.publish_snapshot then
            sent = Engine.publish_snapshot(snap, publish_opts)
        else
            sent = Engine.publish(true, depth == "full" and "full" or "lite", publish_opts)
        end
        if sent then
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
    local bank_open = snapshot.bank_window_open and snapshot.bank_window_open() or false
    local depth = full and "full" or "lite"
    local publish_opts = { skipLockouts = true, skipLiveStats = true, reason = "inventory_watch_dirty" }
    local snap = snapshot.gather({
        force = true,
        depth = depth,
        skipLockouts = publish_opts and publish_opts.skipLockouts == true,
        skipLiveStats = publish_opts and publish_opts.skipLiveStats == true,
    })
    return publish_snap_if_changed(snap, now, depth, urgent and bank_open, publish_opts)
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
    pcall(function() mq.event('tgearInvEquip', 'You equip #*#', on_gear_line, opts) end)
    pcall(function() mq.event('tgearInvRemove', 'You remove #*#', on_gear_line, opts) end)
    pcall(function() mq.event('tgearInvDestroy', 'You destroy #*#', on_inventory_line, opts) end)
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
    M.registered = false
    dirty_at = nil
    dirty_urgent = false
    dirty_full = false
end

function M.tick()
    if not enabled() then return end
    if state.engine_claim_disabled == true then return end
    diag.time("inventory_watch.tick", function()
        flush_if_due()
        bg_poll_if_due()
    end)
end

function M.seed_signature()
    local snap = snapshot.cached() or snapshot.gather({ force = false, depth = "lite" })
    if snap then last_known_sig = snapshot.lite_signature(snap) end
end

return M
