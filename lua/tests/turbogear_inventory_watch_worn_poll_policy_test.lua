-- Run from repo root: luajit lua/tests/turbogear_inventory_watch_worn_poll_policy_test.lua
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

local policy = require('inventory_watch_worn_poll_policy')

local pass, fail = 0, 0
local function check(cond, msg)
    if cond then pass = pass + 1 else fail = fail + 1; print("  FAIL: " .. tostring(msg)) end
end

local cfg = {
    perf_equip_poll_interval_s = 1.0,
    perf_equip_poll_bg_idle_interval_s = 2.0,
    perf_equip_poll_bg_fast_interval_s = 1.0,
    perf_equip_poll_bg_fast_window_s = 15.0,
}

do
    local interval, mode = policy.interval(0, cfg, { bg = true, fast_until = 0 })
    check(interval == 2.0 and mode == "idle", "bg starts on idle interval")
end

do
    local until_t = policy.activate_until(10, cfg)
    check(until_t == 25.0, "activity opens 15s fast window")
    local interval, mode = policy.interval(20, cfg, { bg = true, fast_until = until_t })
    check(interval == 1.0 and mode == "fast", "fast interval active inside window")
    interval, mode = policy.interval(25.1, cfg, { bg = true, fast_until = until_t })
    check(interval == 2.0 and mode == "idle", "bg returns to idle after fast window")
end

do
    local first = policy.activate_until(10, cfg)
    local second = policy.activate_until(20, cfg)
    check(second > first and second == 35.0, "repeated activity extends fast window")
end

do
    local interval, mode = policy.interval(20, cfg, { bg = false, fast_until = 35 })
    check(interval == 1.0 and mode == "ui", "non-bg uses base interval even with fast window")
end

do
    local interval, mode = policy.interval(0, { perf_equip_poll_interval_s = 1.0 }, { bg = true, fast_until = 0 })
    check(interval == 0 and mode == "disabled", "bg idle default is off when unset")
end

print(string.format("inventory_watch worn poll policy: %d passed, %d failed", pass, fail))
os.exit(fail == 0 and 0 or 1)
