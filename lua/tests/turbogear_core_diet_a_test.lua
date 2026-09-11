-- Run from repo root: luajit lua/tests/turbogear_core_diet_a_test.lua
-- Core Diet A: demand-driven item_index, generated [TG] skips needs_index,
-- peek-only emit ownership (no sync rebuild).
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

package.preload['mq'] = function()
    return { configDir = ".", TLO = { Me = { CleanName = function() return "Tester" end } } }
end
package.preload['config'] = function()
    return { CFG = { script_name = "TurboGear" }, Settings = {}, SharedSettings = {} }
end
package.preload['diagnostics'] = function()
    return { time = function(_, fn) return fn() end, count = function() end, event = function() end, sample = function() end }
end

local pass, fail = 0, 0
local function check(cond, msg)
    if cond then pass = pass + 1 else fail = fail + 1; print("  FAIL: " .. tostring(msg)) end
end

local idxmod = require('ownership_index')
local built = 0
local real_build = idxmod.build_snapshot_index
idxmod.build_snapshot_index = function(snap)
    built = built + 1
    return real_build(snap)
end

local snap = {
    server = "Srv",
    name = "Emit",
    equipped = { { name = "Need Ring", id = 9, where = "Left Finger", slotname = "Left Finger", augs = {} } },
    bags = {},
    bank = {},
}
local peeked, pmeta = idxmod.peek_snapshot_index(snap)
check(peeked == nil and pmeta.cache == "miss", "emit peek miss")
check(built == 0, "peek does not call build_snapshot_index")
check(snap._bis_index == nil, "peek does not publish cache")

idxmod.cached_snapshot_index(snap)
check(built == 1, "cached_snapshot_index still builds for rich consumers")
local peeked2, pmeta2 = idxmod.peek_snapshot_index(snap)
check(pmeta2.cache == "hit" and peeked2 ~= nil, "emit peek hit after warm")
check(built == 1, "peek hit does not rebuild")

print(string.format("core diet A: %d passed, %d failed", pass, fail))
os.exit(fail == 0 and 0 or 1)
