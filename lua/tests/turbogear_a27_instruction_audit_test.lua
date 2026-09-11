-- Run from repo root: luajit lua/tests/turbogear_a27_instruction_audit_test.lua
-- A2.7 measurement only. Counts interpreter bytecodes; it is not a scheduler.
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

package.preload['mq'] = function()
    return { configDir = ".", TLO = { Me = { CleanName = function() return "Audit" end } } }
end
package.preload['config'] = function()
    return { CFG = { script_name = "TurboGear" }, Settings = {} }
end
package.preload['diagnostics'] = function()
    return {
        count = function() end,
        sample = function() end,
        event = function() end,
        time = function(_, fn) return fn() end,
    }
end

local ownership = require('ownership_index')
local pass, fail = 0, 0
local function check(ok, message)
    if ok then pass = pass + 1
    else fail = fail + 1; print("  FAIL: " .. tostring(message)) end
end
local function count_instructions(fn)
    local count = 0
    local function hook() count = count + 1 end
    debug.sethook(hook, "", 1)
    local ok, err = pcall(fn)
    debug.sethook()
    check(ok, "instruction-counted region completes: " .. tostring(err or ""))
    return count
end
local function make_snap(name, item_count)
    local snap = {
        server = "Audit",
        name = name,
        class = "Warrior",
        equipped = {},
        bags = {},
        bank = {},
        bankValid = false,
        bankLive = false,
        bankPreserved = false,
    }
    for i = 1, item_count do
        snap.bags[i] = {
            name = "Audit Item " .. tostring(i),
            id = 100000 + i,
            augs = {},
        }
    end
    return snap
end
local function count_one_unit()
    local snap = make_snap("OneUnit", 10)
    ownership.begin_snapshot_warm(snap, function() return 0 end)
    return count_instructions(function()
        ownership.tick_snapshot_warm(snap, 1000, 1, function() return 0 end)
    end)
end
local function count_full_warm(item_count, suffix)
    local snap = make_snap("Warm" .. tostring(suffix), item_count)
    ownership.begin_snapshot_warm(snap, function() return 0 end)
    local count = count_instructions(function()
        local done = ownership.tick_snapshot_warm(
            snap, 100000, nil, function() return 0 end)
        assert(done == true)
    end)
    check(type(snap._bis_index) == "table", "full warm atomically publishes " .. tostring(item_count))
    return count
end
local function count_sync_build(item_count, suffix)
    local snap = make_snap("Sync" .. tostring(suffix), item_count)
    return count_instructions(function()
        assert(type(ownership.build_snapshot_index(snap)) == "table")
    end)
end

local one_unit_a, one_unit_b = count_one_unit(), count_one_unit()
check(one_unit_a == one_unit_b, "one ownership item unit count is deterministic")
local warm89 = count_full_warm(89, "89")
local warm120 = count_full_warm(120, "120")
local warm225 = count_full_warm(225, "225")
local sync89 = count_sync_build(89, "89")
local sync120 = count_sync_build(120, "120")
local sync225 = count_sync_build(225, "225")

print(string.format(
    "A2.7 ownership bytecodes: one_item_unit=%d warm89=%d warm120=%d warm225=%d sync89=%d sync120=%d sync225=%d",
    one_unit_a, warm89, warm120, warm225, sync89, sync120, sync225))
print(string.format("A2.7 ownership instruction audit: %d passed, %d failed", pass, fail))
os.exit(fail == 0 and 0 or 1)
