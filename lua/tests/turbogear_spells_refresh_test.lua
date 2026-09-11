-- Run from repo root: luajit lua/tests/turbogear_spells_refresh_test.lua
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

local plan = require('spells_refresh')

local pass, fail = 0, 0
local function check(cond, msg)
    if cond then pass = pass + 1 else fail = fail + 1; print('FAIL: ' .. tostring(msg)) end
end

local NOW = 2000000

-- Case A: usable spell_cache, first open (last_at=0)
local p = plan.plan_tab_enter({
    spell_cache_ready = true,
    spell_cache_sig = "abc",
    last_spell_cache_at = 0,
    now = NOW,
    interval_minutes = 5,
})
check(p.action == "draw_cache" and p.source == "cache", "A: usable cache draws immediately")
check(p.stamp == true, "A: first usable open stamps freshness")

-- Snapshot spells_sig is also usable
p = plan.plan_tab_enter({
    spell_cache_ready = false,
    snap = { spells_sig = "sig1" },
    last_spell_cache_at = 0,
    now = NOW,
})
check(p.action == "draw_cache" and p.usable_from == "snapshot", "A: snapshot spells_sig counts as cache")

-- Case B: no cache
p = plan.plan_tab_enter({
    spell_cache_ready = false,
    snap = {},
    last_spell_cache_at = 0,
    now = NOW,
})
check(p.action == "schedule_refresh" and p.source == "refresh_scheduled", "B: missing cache schedules refresh")
check(p.stamp == false, "B: does not pretend a cache exists")

-- Expiry still refreshes
p = plan.plan_tab_enter({
    spell_cache_ready = true,
    spell_cache_sig = "abc",
    last_spell_cache_at = NOW - 6 * 60,
    now = NOW,
    interval_minutes = 5,
})
check(p.action == "schedule_refresh" and p.reason == "expired", "expiry: due after interval")

-- Fresh cache does not refresh
p = plan.plan_tab_enter({
    spell_cache_ready = true,
    spell_cache_sig = "abc",
    last_spell_cache_at = NOW - 30,
    now = NOW,
    interval_minutes = 5,
})
check(p.action == "draw_cache" and p.reason == "fresh", "fresh cache within interval")

check(plan.local_rebuild_allowed(false) == false, "viewer must not rebuild locally")
check(plan.local_rebuild_allowed(true) == true, "owner may rebuild locally")
check(plan.cache_is_usable({}) == false, "empty opts is not usable")
check(select(1, plan.cache_is_usable({ spell_cache_ready = true, spell_cache_sig = "" })) == false,
    "ready without signature is not usable")

print(string.format('spells_refresh: %d passed, %d failed', pass, fail))
if fail > 0 then os.exit(1) end
