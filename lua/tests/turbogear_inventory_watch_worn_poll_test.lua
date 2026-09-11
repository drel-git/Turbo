-- Run from repo root: luajit lua/tests/turbogear_inventory_watch_worn_poll_test.lua
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

local real_clock = os.clock
local now = 0
os.clock = function() return now end

package.loaded['inventory_watch'] = nil
package.loaded['diagnostics'] = nil
package.loaded['state'] = nil

package.preload['mq'] = function()
    return { event = function() end, unevent = function() end }
end

local state = { bg = true, engine_claim_disabled = false }
package.preload['state'] = function() return state end

package.preload['config'] = function()
    return {
        CFG = {
            inventory_watch_enabled = true,
            inventory_watch_debounce_s = 0.4,
            inventory_watch_publish_cooldown_s = 2.0,
            inventory_watch_bg_poll_s = 0.0,
            perf_equip_poll = true,
            perf_equip_poll_interval_s = 1.0,
            perf_equip_poll_bg_idle_interval_s = 2.0,
            perf_equip_poll_bg_fast_interval_s = 1.0,
            perf_equip_poll_bg_fast_window_s = 15.0,
            perf_worn_persist_debounce_s = 2.5,
            worn_lite_heal_gap_s = 999.0,
        },
        Settings = {},
    }
end

local worn_sig = "seed"
local worn_signature_calls = 0
local refresh_calls = 0
local published = 0
local snap = {
    name = "Me",
    server = "Srv",
    equipped = {},
    bags = {},
    bank = {},
}

package.preload['snapshot'] = function()
    return {
        cached = function() return snap end,
        gather = function() return snap end,
        worn_signature = function()
            worn_signature_calls = worn_signature_calls + 1
            return worn_sig
        end,
        refresh_equipped = function()
            refresh_calls = refresh_calls + 1
            return snap
        end,
        lite_signature = function() return "lite:" .. tostring(worn_sig) end,
        wallet_signature = function() return "wallet" end,
        equipped_has_lite_items = function() return false end,
        invalidate = function() end,
    }
end

package.preload['snapshot_delta'] = function()
    return {
        baseline_from_snapshot = function() return {} end,
        diff_snapshot = function() return nil, 0 end,
        slot_key = function() return "" end,
    }
end

package.preload['bis'] = function()
    return { invalidate_live_ownership_cache = function() end }
end

package.preload['engine'] = function()
    return {
        Engine = {
            publish_snapshot = function()
                published = published + 1
                return true
            end,
        },
    }
end

local diag = require('diagnostics')
diag.set_enabled(true)

local M = require('inventory_watch')

local pass, fail = 0, 0
local function check(cond, msg)
    if cond then pass = pass + 1 else fail = fail + 1; print("  FAIL: " .. tostring(msg)) end
end
local function cnt(k) return diag.counters[k] or 0 end

M.seed_signature()
local seed_calls = worn_signature_calls

now = 1.1
M.tick()
check(worn_signature_calls == seed_calls, "bg idle does not poll before 2s")

now = 2.1
M.tick()
check(worn_signature_calls == seed_calls + 1, "bg idle polls at 2s interval")
check(cnt("inventory_watch.worn_signature_idle") == 1, "idle worn signature call counted")

M.note_change(true, false)
check(cnt("inventory_watch.worn_poll_fast_reset_dirty") == 1, "inventory activity activates fast window")

now = 3.0
M.tick()
check(worn_signature_calls == seed_calls + 1, "fast mode still respects 1s interval")

now = 3.2
M.tick()
check(worn_signature_calls == seed_calls + 2, "fast mode polls after 1s")
check(cnt("inventory_watch.worn_signature_fast") == 1, "fast worn signature call counted")

worn_sig = "changed"
now = 4.3
M.tick()
check(refresh_calls == 1, "poll-detected worn change refreshes equipped snapshot")
check(cnt("inventory_watch.worn_change") == 1, "poll-detected worn change counted")
check(cnt("inventory_watch.worn_change_fast") == 1, "poll-detected worn change records active mode")
check(cnt("inventory_watch.worn_poll_fast_reset_worn_poll") == 1, "poll-detected worn change extends fast window")

now = 7.0
M.tick()
check(published == 1, "poll-detected worn change follows debounced publish path")

os.clock = real_clock
print(string.format("inventory_watch worn poll: %d passed, %d failed", pass, fail))
os.exit(fail == 0 and 0 or 1)
