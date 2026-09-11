-- Jonas Dagmire Hand (Hand Aug checklist) progression.
-- Run from repo root: luajit lua/tests/turbogear_jonas_hand_progression_test.lua
--
-- Item facts (Lazarus DB):
--   33166 Backhand (Tier 1 finger)          33172 Thumb       (Tier 2 finger)
--   33173 Forefinger (Tier 3 finger)        33174 Ring Finger (Tier 4 finger)
--   33175 Little Finger (Tier 5 finger)     33176 Middle Finger (Tier 6 finger)
--   82836 Sunken Middle Finger (converts to 33176)
--   33167-33171 "Jonas Dagmire's Skeletal Hand" = hand after Tier 2..6 (33171 final)
-- Recipes are sequential: 33166+33172->33167, +33173->33168, +33174->33169,
-- +33175->33170, +33176->33171.
-- Rule: a row is green when its own bone, its tier's finger, or any later hand
-- is held. The shared "Skeletal Hand" NAME never satisfies anything.
package.path = "lua/turbogear/?.lua;lua/turbogear/?/init.lua;" .. package.path

-- FindItem stub driven by `held` (list of {id=, name=}).
local held = {}
local finditem_log = {}
local function fake_item(it)
    return setmetatable({}, {
        __call = function() return it.name end,
        __index = function(_, k)
            if k == "Name" then return function() return it.name end end
            if k == "ID" then return function() return it.id end end
            if k == "ItemSlot" then return function() return 30 end end
            if k == "ItemSlotName" then return function() return "Bags" end end
            return function() return nil end
        end,
    })
end
local empty = setmetatable({}, { __call = function() return nil end, __index = function() return function() return nil end end })
local function find(query, bank)
    finditem_log[#finditem_log + 1] = { q = query, bank = bank }
    if bank then return empty end
    for _, it in ipairs(held) do
        if type(query) == "number" then
            if it.id == query then return fake_item(it) end
        else
            local q = tostring(query):gsub("^=", ""):lower()
            if it.name:lower() == q then return fake_item(it) end
        end
    end
    return empty
end

package.preload["mq"] = function()
    return {
        TLO = {
            Me = {
                CleanName = function() return "HandTester" end,
                Class = { Name = function() return "Warrior" end },
            },
            MacroQuest = { Server = function() return "Project Lazarus" end },
            EverQuest = { GameState = function() return "INGAME" end },
            FindItem = function(q) return find(q, false) end,
            FindItemBank = function(q) return find(q, true) end,
            Cursor = empty,
        },
        configDir = ".",
        pickle = function() end,
    }
end
package.preload["config"] = function()
    return {
        CFG = {}, Settings = {}, SharedSettings = { bisAnnounceDisabledLists = {} },
        SaveSettings = function() end, SaveSharedSettings = function() end,
        known_class = function(c) c = tostring(c or ""); if c == "" or c == "?" then return nil end; return c end,
        canonical_class = function(c) c = tostring(c or ""); if c == "" or c == "?" then return nil end; return c end,
    }
end
package.preload["diagnostics"] = function()
    return { time = function(_, fn) return fn() end, count = function() end, event = function() end,
        sample = function() end, context = function() end }
end

local pass, fail = 0, 0
local function check(cond, msg)
    if cond then pass = pass + 1 else fail = fail + 1; print("FAIL: " .. tostring(msg)) end
end

local catalog = require("bis_catalog")
local bis = require("bis")
local ownership_index = require("ownership_index")
local bis_search = require("bis_search")
catalog.warm_catalog("test")

local HAND = "Jonas Dagmire's Skeletal Hand"
local FINGERS = {
    [1] = { id = 33166, name = "Jonas Dagmire's Skeletal Backhand" },
    [2] = { id = 33172, name = "Jonas Dagmire's Skeletal Thumb" },
    [3] = { id = 33173, name = "Jonas Dagmire's Skeletal Forefinger" },
    [4] = { id = 33174, name = "Jonas Dagmire's Skeletal Ring Finger" },
    [5] = { id = 33175, name = "Jonas Dagmire's Skeletal Little Finger" },
}
local HAND_AFTER_TIER = { [2] = 33167, [3] = 33168, [4] = 33169, [5] = 33170, [6] = 33171 }

-- Slot -> tier (6 = Tier 6 (Final)), from the catalog's own categories.
local list = catalog.list("jonas")
check(list ~= nil, "jonas list loads")
local slot_tier, all_slots = {}, {}
for _, cat in ipairs(list.categories or {}) do
    local t = tonumber(tostring(cat.name or ""):match("^Tier (%d)"))
    for _, slot in ipairs(cat.slots or {}) do
        slot_tier[slot] = t
        all_slots[#all_slots + 1] = slot
    end
end
check(#all_slots == 30, "jonas list has 30 rows (got " .. #all_slots .. ")")

local function has_id(entry, id)
    for _, v in ipairs(entry.ids or {}) do if tonumber(v) == id then return true end end
    return false
end
local function has_name(entry, name)
    local k = ownership_index.norm_item_name(name)
    for _, v in ipairs(entry.names or {}) do if ownership_index.norm_item_name(v) == k then return true end end
    return false
end

-- ---------------------------------------------------------------- catalog rows
for _, slot in ipairs(all_slots) do
    local e = catalog.resolve_entry("jonas", "Warrior", slot)
    check(e ~= nil, "resolve " .. slot)
    if e then
        check(not has_name(e, HAND) and not has_name(e, "Skeletal Hand"),
            slot .. ": shared 'Skeletal Hand' name never a match name")
        check(has_id(e, 33171), slot .. ": final hand 33171 satisfies every row")
    end
end
local t6 = catalog.resolve_entry("jonas", "Warrior", "Tier 6 Complete")
check(#t6.ids == 1 and t6.ids[1] == 33171 and #t6.names == 0, "Tier 6 Complete is ID-only {33171}")
check(t6.item == HAND, "Tier 6 Complete keeps its display name")
local mid = catalog.resolve_entry("jonas", "Warrior", "Middle Finger (Mayong)")
check(has_id(mid, 82836) and has_id(mid, 33176) and has_id(mid, 33171) and #mid.ids == 3,
    "Middle Finger row = {82836, 33176, 33171}")
for _, slot in ipairs({ "Elite Gnolls (Blackburrow)", "Lord Pickclaw (Runnyeye)", "Redwind (Everfrost)", "Tier 2 Complete" }) do
    check(has_id(catalog.resolve_entry("jonas", "Warrior", slot), 33172), slot .. ": Thumb 33172 clears Tier 2")
end
local scruffy = catalog.resolve_entry("jonas", "Warrior", "Scruffy (HC QH)")
check(has_name(scruffy, "Trapezoid") and has_name(scruffy, "Jonas Dagmire's Trapezoid"),
    "bone rows keep bare + prefixed own name")
check(not has_name(catalog.resolve_entry("jonas", "Warrior", "Tier 1 Complete"), "Trapezoid"),
    "no cross-row name chaining (Tier 1 Complete does not match a loose bone)")

-- ------------------------------------------------------------ evaluation paths
local function snap_with(items)
    local bags = {}
    for _, it in ipairs(items) do bags[#bags + 1] = { id = it.id or 0, name = it.name } end
    return { name = "Peer", server = "Project Lazarus", class = "Warrior",
        equipped = {}, bags = bags, bank = {}, augs = {}, spells = {} }
end

-- expected(slot) -> bool; checks bis.evaluate_entry and ownership_index.entry_status agree.
local function expect_matrix(label, items, expected)
    local snap = snap_with(items)
    local oidx = ownership_index.build_snapshot_index(snap)
    for _, slot in ipairs(all_slots) do
        local e = catalog.resolve_entry("jonas", "Warrior", slot)
        local want = expected(slot) and true or false
        local r = bis.evaluate_entry(e, snap, { skip_live = true })
        check((r.have and true or false) == want,
            string.format("%s | evaluate_entry %s: want %s got %s", label, slot, tostring(want), tostring(r.have)))
        local _, st = ownership_index.entry_status(e, oidx)
        check((st ~= "missing") == want,
            string.format("%s | entry_status %s: want %s got %s", label, slot, tostring(want), tostring(st)))
    end
end

expect_matrix("nothing held", {}, function() return false end)

expect_matrix("loose Trapezoid (T1 bone)", { { id = 0, name = "Jonas Dagmire's Trapezoid" } },
    function(slot) return slot == "Scruffy (HC QH)" end)

expect_matrix("mixed loose bones T1+T3+T5", {
    { id = 0, name = "Trapezoid" },
    { id = 0, name = "Jonas Dagmire's Forefinger Distal Phalanx" },
    { id = 0, name = "Little Finger Middle Phalanx" },
}, function(slot)
    return slot == "Scruffy (HC QH)" or slot == "Rosch Var'L'Vlor (SK)" or slot == "Slizik The Mighty (Hole)"
end)

for tier, f in pairs(FINGERS) do
    expect_matrix("finger T" .. tier .. " unmerged", { f },
        function(slot) return slot_tier[slot] == tier and slot ~= "Middle Finger (Mayong)" end)
end

for tier, id in pairs(HAND_AFTER_TIER) do
    expect_matrix("hand " .. id .. " (after T" .. tier .. ")", { { id = id, name = HAND } },
        function(slot)
            if slot == "Middle Finger (Mayong)" then return id == 33171 end
            return (slot_tier[slot] or 99) <= tier
        end)
end

expect_matrix("Sunken Middle Finger 82836", { { id = 82836, name = "Sunken Jonas Dagmire's Skeletal Middle FInger" } },
    function(slot) return slot == "Middle Finger (Mayong)" end)
expect_matrix("Middle Finger 33176", { { id = 33176, name = "Jonas Dagmire's Skeletal Middle FInger" } },
    function(slot) return slot == "Middle Finger (Mayong)" end)

-- Name-only hand record (id missing in snapshot) must NOT green anything.
expect_matrix("hand by name only (id 0)", { { id = 0, name = HAND } }, function() return false end)

-- --------------------------------------------------------------- live self path
held = { { id = 33167, name = HAND } }
check(bis.live_item_status(t6, HAND, 0) == nil, "live self: Tier 2 hand does not satisfy Tier 6 via name")
check(bis.live_item_status(catalog.resolve_entry("jonas", "Warrior", "Tier 2 Complete"), HAND, 0) ~= nil,
    "live self: Tier 2 hand satisfies Tier 2 Complete via id")
held = {}

-- ------------------------------------------------------------ bis_search (peer)
local function search(slot)
    finditem_log = {}
    return bis_search._search_entry(bis.normalize_entry(catalog.resolve_entry("jonas", "Warrior", slot)))
end
held = { { id = 12345, name = "Trapezoid" } }
local r = search("Scruffy (HC QH)")
check(r.status == "carried", "bis_search: Tier 1 bone in bags found")
check(finditem_log[1] and finditem_log[1].q == "=Trapezoid", "bis_search: own bone name is the first lookup")

held = { { id = 33171, name = HAND } }
r = search("Tier 6 Complete")
check(r.status == "carried" and #finditem_log == 1 and finditem_log[1].q == 33171,
    "bis_search: final hand holder found on first lookup (Tier 6)")
r = search("Scruffy (HC QH)")
check(r.status == "carried", "bis_search: final hand clears a Tier 1 bone row")

held = { { id = 33166, name = FINGERS[1].name } }
r = search("Ice Giants (Perma)")
check(r.status == "carried", "bis_search: Backhand (lowest id, last in budget) still found on a 6-id row")

held = { { id = 33167, name = HAND } }
check(search("Tier 3 Complete").status == "missing", "bis_search: Tier 2 hand does not clear Tier 3")
check(search("Tier 6 Complete").status == "missing", "bis_search: Tier 2 hand does not clear Tier 6")
for _, q in ipairs(finditem_log) do
    check(type(q.q) ~= "string" or not q.q:lower():find("skeletal hand", 1, true),
        "bis_search: never queries the shared hand name")
end
held = {}

-- ----------------------------------------------------- generated announce index
local payload = catalog.warm_generated_builtin_index("test")
check(payload ~= nil, "generated index loads (fingerprint matches catalog)")
local snap = snap_with({})
local function cand_slots(name, id)
    local out = {}
    local cands = catalog.generated_builtin_compact_candidates_for_link(snap, name, id)
    for _, c in ipairs(cands or {}) do
        if c.list_id == "jonas" then out[c.slot] = true end
    end
    return out
end
local by_name_only = cand_slots(HAND, 0)
check(next(by_name_only) == nil, "announce: hand link without id matches no Jonas row")
local t2hand = cand_slots(HAND, 33167)
check(t2hand["Tier 2 Complete"] and t2hand["Tier 1 Complete"], "announce: 33167 link maps to Tier 1-2 rows")
check(not t2hand["Tier 3 Complete"] and not t2hand["Tier 6 Complete"], "announce: 33167 link not a Tier 3/6 candidate")
local thumb = cand_slots(FINGERS[2].name, 33172)
-- Name identity is authoritative in the generated index: the Thumb's own row.
check(thumb["Tier 2 Complete"] and not thumb["Tier 3 Complete"], "announce: Thumb link maps to Tier 2 Complete")
local sunken = cand_slots("Sunken Jonas Dagmire's Skeletal Middle FInger", 82836)
check(sunken["Middle Finger (Mayong)"] and not sunken["Tier 6 Complete"], "announce: Sunken finger maps to Middle Finger only")
check(cand_slots("Trapezoid", 0)["Scruffy (HC QH)"], "announce: bone name link still matches its row")

print(string.format("jonas hand progression: %d passed, %d failed", pass, fail))
if fail > 0 then os.exit(1) end
