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

-- Cold start must NOT sync-rebuild; get starts a job and serves empty/last-good.
local rows0, ver0 = item_index.get(false)
check(type(rows0) == "table", "cold get returns a table")
check(item_index.building() == true, "cold get starts a budgeted job")
check(#rows0 == 0 and ver0 == 0, "cold get does not sync-fill rows")

local finished_cold = false
for _ = 1, 50 do
    if item_index.tick(50) then
        finished_cold = true
        break
    end
end
check(finished_cold, "tick completes cold-start job")
check(item_index.building() ~= true, "no job after cold complete")

local rows1, ver1 = item_index.get(false)
check(type(rows1) == "table" and #rows1 >= 4, "cold tick builds self+peers")
check(ver1 >= 1, "cold tick bumps version")

local cold_total = #rows1
local cold_ver = ver1

-- Content bump: get must NOT finish a multi-peer rebuild in-call.
Store.content_version = 2
Store.sources["Srv:PeerD"] = make_peer("PeerD", "PeerD Ring", 13)
local rows2, ver2 = item_index.get(false)
check(ver2 == cold_ver, "stale get keeps last-good version")
check(#rows2 == cold_total, "stale get keeps last-good row count")
check(item_index.building() == true, "stale get starts a rebuild job")

-- Drain with ticks (chunked within peers).
local finished = false
for _ = 1, 50 do
    if item_index.tick(0.25) then
        finished = true
        break
    end
end
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

-- Within-peer chunking: a large bag list cannot finish in one tiny budget tick.
item_index._reset_for_tests()
local big_bags = {}
for i = 1, 200 do
    big_bags[i] = { name = "BagItem" .. i, id = 1000 + i, qty = 1, slotid = i, stats = {} }
end
Store.sources = {
    ["Srv:Fat"] = {
        name = "Fat",
        server = "Srv",
        class = "Wizard",
        status = "online",
        depth = "full",
        inventoryUpdated = 100,
        equipped = {},
        bags = big_bags,
        bank = {},
    },
}
Store.content_version = 1
self_cached.bags = {}
item_index.get(false)
check(item_index.building() == true, "fat peer starts job")
local progressed = item_index.tick(0.01)
check(progressed == false, "tiny budget does not finish 200-bag peer in one tick")
check(item_index.building() == true, "fat peer still building after tiny tick")
while item_index.building() do item_index.tick(50) end
local rows_fat = item_index.get(false)
check(#rows_fat >= 200, "fat peer eventually indexed")

-- Lite bag (no wear slots) then full meta on same id must rebuild Suggestions rows.
item_index._reset_for_tests()
Store.sources = {
    ["Srv:BowPeer"] = {
        name = "BowPeer",
        server = "Srv",
        class = "Berserker",
        status = "online",
        depth = "lite",
        inventoryUpdated = 100,
        equipped = {},
        bags = {
            { name = "Test Bow", id = 555, qty = 1, location = "Bags", where = "Bag1 #1",
              slots = {}, stats = {}, depth = "lite", itemType = "weapon" },
        },
        bank = {},
    },
}
Store.content_version = 1
self_cached.bags = {}
item_index.get(false)
while item_index.building() do item_index.tick(50) end
local rows_lite = item_index.get(false)
local bow_lite_slots = 0
for _, row in ipairs(rows_lite) do
    if row.name == "Test Bow" and type(row.slots) == "table" then
        for _ in pairs(row.slots) do bow_lite_slots = bow_lite_slots + 1 end
    end
end
check(bow_lite_slots == 0, "lite indexed bow has no wear slots")

Store.sources["Srv:BowPeer"].depth = "full"
Store.sources["Srv:BowPeer"].bags[1] = {
    name = "Test Bow", id = 555, qty = 1, location = "Bags", where = "Bag1 #1",
    slots = { 11 }, stats = { ac = 5, hp = 20 }, depth = "full",
    classes = { "Berserker" }, itemType = "weapon",
}
Store.content_version = 2
item_index.get(false)
while item_index.building() do item_index.tick(50) end
local rows_full = item_index.get(false)
local saw_ranged = false
for _, row in ipairs(rows_full) do
    if row.name == "Test Bow" and type(row.slots) == "table" then
        for _, sid in pairs(row.slots) do
            if tonumber(sid) == 11 then saw_ranged = true end
        end
    end
end
check(saw_ranged, "full meta rebuild indexes ranged wear slot for bag bow")

-- Store flatten serves Suggestions while the budgeted index is still building.
item_index._reset_for_tests()
Store.sources = {
    ["Srv:Quick"] = {
        name = "Quick",
        server = "Srv",
        class = "Berserker",
        status = "online",
        depth = "full",
        inventoryUpdated = 100,
        equipped = {},
        bags = {
            { name = "Quick Bow", id = 777, qty = 1, location = "Bags", where = "Bag1 #1",
              slots = { 11 }, stats = { ac = 3 }, depth = "full", itemType = "weapon" },
        },
        bank = {},
    },
}
Store.content_version = 9
self_cached.bags = {}
item_index.get(false)
check(item_index.building() == true, "cold get starts job before store flatten")
local srows, _, src = item_index.suggestion_rows()
check(src == "store", "suggestion_rows uses store while index building")
local saw_quick = false
for _, row in ipairs(srows or {}) do
    if row.name == "Quick Bow" then saw_quick = true end
end
check(saw_quick, "store flatten includes bag bow immediately")

print(string.format("item_index: %d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
