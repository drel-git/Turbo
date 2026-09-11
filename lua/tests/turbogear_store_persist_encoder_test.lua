-- Run from repo root: luajit lua/tests/turbogear_store_persist_encoder_test.lua
-- The specialized Store item encoder must be semantically equivalent to the
-- existing SQLite backend serializer for persisted slim item structures.
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

package.preload['config'] = function()
    return { CFG = {}, Settings = {}, SharedSettings = {} }
end

local encoder = require('store_persist_encoder')
local sqlmod = require('store_backend_sqlite')
local old_serialize = sqlmod._serialize
local deserialize = sqlmod._deserialize

local pass, fail = 0, 0
local function check(cond, msg)
    if cond then pass = pass + 1 else fail = fail + 1; print("  FAIL: " .. tostring(msg)) end
end

local function deep_equal(a, b, path)
    path = path or "$"
    if type(a) ~= type(b) then return false, path .. " type " .. type(a) .. " ~= " .. type(b) end
    if type(a) ~= "table" then
        if a ~= b then return false, path .. " value " .. tostring(a) .. " ~= " .. tostring(b) end
        return true
    end
    local seen = {}
    for k, av in pairs(a) do
        seen[k] = true
        local ok, why = deep_equal(av, b[k], path .. "." .. tostring(k))
        if not ok then return false, why end
    end
    for k in pairs(b) do
        if not seen[k] then return false, path .. " extra key " .. tostring(k) end
    end
    return true
end

local function assert_equiv(label, value, encode_new)
    local old_value = deserialize(old_serialize(value))
    local new_value = deserialize(encode_new(value))
    local ok, why = deep_equal(old_value, new_value)
    check(ok, label .. " semantic round-trip equivalence" .. (why and (": " .. why) or ""))
end

local simple_equipped = {
    name = "Stone Etched War Sword",
    id = 1001,
    icon = 567,
    location = "Equipped",
    where = "Equipped",
    slotid = 13,
    slotname = "Primary",
    qty = 1,
    nodrop = true,
    attuned = false,
    attunable = true,
    lore = true,
    loreGroup = 42,
    augType = 0,
    depth = "full",
    augs = {},
    itemType = "weapon",
    requiredLevel = 60,
    recommendedLevel = 65,
    allClasses = false,
    statsMerged = true,
    classes = { "Warrior", "Paladin" },
    slots = { 13, 14 },
}

local stats_item = {
    name = "Stat Hammer",
    id = 2002,
    location = "Bag 1",
    where = "Bag",
    slotid = 3,
    slotname = "Slot 3",
    qty = 1,
    depth = "full",
    augs = {},
    stats = { ac = 35, hp = 120, mana = 0, heroic_str = 4 },
    baseStats = { ac = 20, hp = 90, endurance = 15 },
    classes = { "Cleric", "Shaman" },
    slots = { 13 },
    statsMerged = true,
}

local focus_item = {
    name = "Focus \"Ruby\"\nBand",
    id = 3003,
    location = "Bank",
    where = "Bank",
    slotid = 7,
    slotname = "Bank Slot \\ Seven",
    qty = 2,
    depth = "full",
    augs = {},
    focusEffects = {
        {
            typeId = 124,
            typeName = "Spell Haste",
            maxEffect = 20,
            effectiveLevel = 70,
            resist = "Magic",
            spellType = "Beneficial",
            spellName = "Aegis of \"Testing\"",
            spellId = 9876,
            rank = "III",
            description = "Escapes \\ quotes \" and newline\nok",
        },
    },
    wornFocusEffects = {
        { typeId = 128, typeName = "Mana Preserve", maxEffect = 8, spellId = 8765 },
    },
}

local aug_item = {
    name = "Augmented Shield",
    id = 4004,
    location = "Equipped",
    where = "Equipped",
    slotid = 14,
    slotname = "Secondary",
    qty = 1,
    depth = "full",
    augs = {
        {
            index = 1,
            type = 7,
            name = "Ruby Aug",
            id = 5001,
            icon = 321,
            empty = false,
            depth = "full",
            stats = { ac = 5, hp = 25 },
            baseStats = { ac = 4 },
            focusEffects = { { typeId = 1, typeName = "Damage", maxEffect = 5 } },
        },
        {
            index = 2,
            type = 8,
            name = "Empty Socket",
            id = 0,
            empty = true,
            depth = "lite",
            wornFocusEffects = { { typeId = 2, spellName = "Worn Test", spellId = 123 } },
        },
    },
}

local sparse_optional = {
    name = "Optional Field Test",
    id = 6006,
    location = "Bag 2",
    where = "Bag",
    augs = {},
    depth = "lite",
    classes = {},
    slots = {},
    focusEffects = {},
    wornFocusEffects = {},
}

local bag_item = {
    name = "Stacked Potion",
    id = 7007,
    location = "Bag 4",
    where = "Bag",
    slotid = 6,
    slotname = "Bag Slot 6",
    qty = 20,
    depth = "lite",
    augs = {},
}

local bank_item = {
    name = "Banked Coin",
    id = 8008,
    location = "Bank 1",
    where = "Bank",
    slotid = 1,
    slotname = "Bank Slot 1",
    qty = 1,
    depth = "full",
    augs = {},
    allClasses = true,
}

local cases = {
    simple_equipped,
    stats_item,
    focus_item,
    aug_item,
    sparse_optional,
    bag_item,
    bank_item,
}

for i, item in ipairs(cases) do
    assert_equiv("item " .. i, item, encoder.encode_item)
end

assert_equiv("item list", cases, encoder.encode_item_list)
check(encoder.encode_item(focus_item) == encoder.encode_item(focus_item), "item output deterministic")
check(encoder.encode_item_list(cases) == encoder.encode_item_list(cases), "item list output deterministic")

print(string.format("store persist encoder: %d passed, %d failed", pass, fail))
os.exit(fail == 0 and 0 or 1)
