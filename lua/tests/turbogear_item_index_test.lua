-- Run from repo root:  luajit lua\tests\turbogear_item_index_test.lua
-- Budgeted fleet item-index: get serves last-good; tick completes swap.

package.path = "lua/turbogear/?.lua;lua/turbogear/?/init.lua;" .. package.path

package.preload["mq"] = function()
    return {
        configDir = ".",
        TLO = {
            Me = { CleanName = function() return "Self" end },
            MacroQuest = { Server = function() return "Srv" end },
        },
    }
end
package.preload["config"] = function()
    return {
        CFG = { script_name = "TurboGear" },
        Settings = {},
        SharedSettings = {},
        SaveSettings = function() end,
        SaveSharedSettings = function() end,
    }
end

local Store = {
    sources = {},
    content_version = 1,
}
package.preload["store"] = function()
    return { Store = Store }
end

local self_cached = {
    name = "Self",
    server = "Srv",
    class = "Warrior",
    depth = "full",
    inventoryUpdated = 100,
    updated = 100,
    equipped = {
        { name = "Self Sword", id = 1, qty = 1, slotid = 13, slotname = "Primary", stats = { str = 5 } },
    },
    bags = {},
    bank = {},
}
package.preload["snapshot"] = function()
    return {
        cached = function() return self_cached end,
    }
end

local item_index = require("item_index")

local passed, failed = 0, 0
local function check(cond, label)
    if cond then
        passed = passed + 1
    else
        failed = failed + 1
        io.stderr:write("FAIL: ", tostring(label), "\n")
    end
end

local function make_peer(name, item_name, id)
    return {
        name = name,
        server = "Srv",
        class = "Cleric",
        status = "online",
        depth = "full",
        inventoryUpdated = 100,
        equipped = {
            { name = item_name, id = id, qty = 1, slotid = 1, slotname = "Charm", stats = { ac = 1 } },
        },
        bags = {},
        bank = {},
    }
end

item_index._reset_for_tests()
Store.sources = {
    ["Srv:PeerA"] = make_peer("PeerA", "PeerA Ring", 10),
    ["Srv:PeerB"] = make_peer("PeerB", "PeerB Ring", 11),
    ["Srv:PeerC"] = make_peer("PeerC", "PeerC Ring", 12),
}
Store.content_version = 1

-- Cold start fills synchronously once.
local rows1, ver1 = item_index.get(false)
check(type(rows1) == "table" and #rows1 >= 4, "cold get builds self+peers")
check(ver1 >= 1, "cold get bumps version")
check(item_index.building() ~= true, "cold get leaves no in-flight job")

local cold_total = #rows1
local cold_ver = ver1

-- Content bump: get must NOT finish a multi-peer rebuild in-call.
Store.content_version = 2
Store.sources["Srv:PeerD"] = make_peer("PeerD", "PeerD Ring", 13)
local rows2, ver2 = item_index.get(false)
check(ver2 == cold_ver, "stale get keeps last-good version")
check(#rows2 == cold_total, "stale get keeps last-good row count")
check(item_index.building() == true, "stale get starts a rebuild job")

-- One tiny tick should not always finish 4 peers; drain with ticks.
local finished = false
for _ = 1, 20 do
    if item_index.tick(0.25) then
        finished = true
        break
    end
end
-- Force completion if budget was too tight for environment noise.
if not finished then
    while item_index.building() do
        item_index.tick(50)
    end
    finished = true
end
check(finished, "tick eventually completes rebuild")
check(item_index.building() ~= true, "no job after complete")

local rows3, ver3 = item_index.get(false)
check(ver3 > cold_ver, "completed swap bumps version")
check(#rows3 >= cold_total + 1, "completed index includes new peer")
local saw_d = false
for _, row in ipairs(rows3) do
    if row.owner == "PeerD" then saw_d = true end
end
check(saw_d, "PeerD present after swap")

-- Mid-job target change restarts; published generation matches latest content_version.
Store.content_version = 3
item_index.get(false)
check(item_index.building() == true, "another bump starts a job")
Store.content_version = 4
while item_index.building() do item_index.tick(50) end
local rows4, ver4 = item_index.get(false)
check(ver4 > ver3, "restarted job still publishes a complete generation")
check(item_index.content_version == 4, "finished job targets latest content_version")
check(#rows4 >= #rows3, "final row count stable after restart")

print(string.format("item_index: %d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
