-- TurboGear/items.lua
-- Inventory slot ordering and the item/augment helpers that read from MQ TLOs.
-- make_item() defines the per-item snapshot shape used across the whole app.

local mq       = require('mq')
local Settings = require('config').Settings
local stat_defs = require('stat_defs')
local focus_extract = require('focus_extract')

local M = {}
local item_meta_cache = {}

-- ===================== INVENTORY SLOT ORDER ============================== --
M.inventory_slots = {
    { id = 2,  name = "Head" },        { id = 1,  name = "Left Ear" },
    { id = 4,  name = "Right Ear" },   { id = 3,  name = "Face" },
    { id = 5,  name = "Neck" },        { id = 6,  name = "Shoulders" },
    { id = 7,  name = "Arms" },        { id = 8,  name = "Back" },
    { id = 17, name = "Chest" },       { id = 9,  name = "Left Wrist" },
    { id = 10, name = "Right Wrist" }, { id = 12, name = "Hands" },
    { id = 15, name = "Left Finger" }, { id = 16, name = "Right Finger" },
    { id = 13, name = "Primary" },     { id = 14, name = "Secondary" },
    { id = 11, name = "Range" },       { id = 18, name = "Legs" },
    { id = 19, name = "Feet" },        { id = 20, name = "Waist" },
    { id = 21, name = "Powersource" }, { id = 0,  name = "Charm" },
    { id = 22, name = "Ammo" },
}

M.slot_groups = {
    { label = "Visibles", slots = {
        { id = 7,  label = "Arms" },       { id = 17, label = "Chest" },
        { id = 19, label = "Feet" },       { id = 12, label = "Hands" },
        { id = 2,  label = "Head" },       { id = 18, label = "Legs" },
        { id = 9,  label = "Wrist 1" },    { id = 10, label = "Wrist 2" },
    } },
    { label = "Non-Visibles", slots = {
        { id = 8,  label = "Back" },       { id = 1,  label = "Ear 1" },
        { id = 4,  label = "Ear 2" },      { id = 3,  label = "Face" },
        { id = 15, label = "Finger 1" },   { id = 16, label = "Finger 2" },
        { id = 5,  label = "Neck" },       { id = 6,  label = "Shoulders" },
        { id = 20, label = "Waist" },      { id = 0,  label = "Charm" },
    } },
    { label = "Weapons", slots = {
        { id = 13, label = "Main Hand" },  { id = 14, label = "Secondary" },
        { id = 11, label = "Ranged" },     { id = 22, label = "Ammo" },
        { id = 21, label = "Powersource" },
    } },
}

local SLOT_BY_ID = {}
for _, slot in ipairs(M.inventory_slots) do SLOT_BY_ID[slot.id] = slot end

function M.slot_display_name(slot_id)
    for _, group in ipairs(M.slot_groups) do
        for _, slot in ipairs(group.slots or {}) do
            if slot.id == slot_id then return slot.label end
        end
    end
    local slot = SLOT_BY_ID[slot_id]
    return slot and slot.name or tostring(slot_id or "?")
end

function M.grouped_slots()
    return M.slot_groups
end

local SLOT_ID_LOOKUP = {}

local function norm_slot_key(s, compact)
    s = tostring(s or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if compact then return s:gsub("%s+", "") end
    return s:gsub("%s+", " ")
end

local function register_slot_label(id, label)
    SLOT_ID_LOOKUP[norm_slot_key(label, false)] = id
    SLOT_ID_LOOKUP[norm_slot_key(label, true)] = id
end

for _, slot in ipairs(M.inventory_slots) do register_slot_label(slot.id, slot.name) end
for _, group in ipairs(M.slot_groups) do
    for _, slot in ipairs(group.slots or {}) do register_slot_label(slot.id, slot.label) end
end
register_slot_label(9, "Wrist1")
register_slot_label(10, "Wrist2")
register_slot_label(1, "Ear1")
register_slot_label(4, "Ear2")
register_slot_label(15, "Finger1")
register_slot_label(16, "Finger2")
register_slot_label(13, "MainHand")
register_slot_label(11, "Ranged")

function M.slot_id_for_label(label)
    if label == nil or label == "" then return nil end
    return SLOT_ID_LOOKUP[norm_slot_key(label, false)] or SLOT_ID_LOOKUP[norm_slot_key(label, true)]
end

-- ===================== ITEM / AUG HELPERS ================================ --
local function get_socket_type(item, idx)
    if     idx == 1 then return item.AugSlot1() or 0
    elseif idx == 2 then return item.AugSlot2() or 0
    elseif idx == 3 then return item.AugSlot3() or 0
    elseif idx == 4 then return item.AugSlot4() or 0
    elseif idx == 5 then return item.AugSlot5() or 0
    elseif idx == 6 then return item.AugSlot6() or 0
    end
    return 0
end

function M.is_skippable_socket(stype)
    return Settings.hideOrnament and (stype == 20 or stype == 30)
end

local function clone_array(src)
    local out = {}
    for i, v in ipairs(src or {}) do out[i] = v end
    return out
end

local function clone_map(src)
    local out = {}
    for k, v in pairs(src or {}) do out[k] = v end
    return out
end

local function safe_num(item, field)
    if not item or not field then return 0 end
    local ok, value = pcall(function()
        local member = item[field]
        if member ~= nil then return member() end
        return nil
    end)
    return ok and tonumber(value) or 0
end

local function first_num(item, fields)
    for _, field in ipairs(fields or {}) do
        local value = safe_num(item, field)
        if value and value ~= 0 then return value end
    end
    return 0
end

local function safe_str(item, field)
    if not item or not field then return "" end
    local ok, value = pcall(function()
        local member = item[field]
        if member ~= nil then return member() end
        return nil
    end)
    return ok and tostring(value or "") or ""
end

local function safe_bool(item, field)
    if not item or not field then return false end
    local ok, value = pcall(function()
        local member = item[field]
        if member ~= nil then return member() end
        return nil
    end)
    if not ok then return false end
    if type(value) == "boolean" then return value end
    local n = tonumber(value)
    if n ~= nil then return n ~= 0 end
    local s = tostring(value or ""):lower()
    return s == "true" or s == "yes" or s == "lore"
end

local function collect_stats(item)
    local stats = stat_defs.default_stats()
    stats.shielding     = safe_num(item, "Shielding")
    stats.avoidance     = safe_num(item, "Avoidance")
    stats.accuracy      = safe_num(item, "Accuracy")
    stats.combatEffects = safe_num(item, "CombatEffects")
    stats.spellShield   = safe_num(item, "SpellShield")
    stats.dotShielding  = safe_num(item, "DoTShielding")
    stats.dsMitigation  = safe_num(item, "DSMitigation")
    if stats.dsMitigation == 0 then stats.dsMitigation = safe_num(item, "DamageshieldMitigation") end
    if stats.dsMitigation == 0 then stats.dsMitigation = safe_num(item, "DamageShieldMitigation") end
    stats.stunResist    = safe_num(item, "StunResist")
    stats.strikethrough = safe_num(item, "StrikeThrough")

    stats.str           = first_num(item, { "STR", "Str" })
    stats.sta           = first_num(item, { "STA", "Sta" })
    stats.agi           = first_num(item, { "AGI", "Agi" })
    stats.dex           = first_num(item, { "DEX", "Dex" })
    stats.wis           = first_num(item, { "WIS", "Wis" })
    stats.int           = first_num(item, { "INT", "Int" })
    stats.cha           = first_num(item, { "CHA", "Cha" })

    stats.heroicStr     = safe_num(item, "HeroicSTR")
    stats.heroicSta     = safe_num(item, "HeroicSTA")
    stats.heroicAgi     = safe_num(item, "HeroicAGI")
    stats.heroicDex     = safe_num(item, "HeroicDEX")
    stats.heroicWis     = safe_num(item, "HeroicWIS")
    stats.heroicInt     = safe_num(item, "HeroicINT")
    stats.heroicCha     = safe_num(item, "HeroicCHA")

    stats.ac            = safe_num(item, "AC")
    stats.hp            = safe_num(item, "HP")
    stats.mana          = safe_num(item, "Mana")
    stats.endurance     = safe_num(item, "Endurance")
    stats.spellDamage   = safe_num(item, "SpellDamage")
    stats.healAmount    = safe_num(item, "HealAmount")
    stats.attack        = first_num(item, { "Attack", "ATK" })
    stats.haste         = safe_num(item, "Haste")
    stats.damage        = first_num(item, { "Damage", "Dmg" })
    stats.delay         = first_num(item, { "ItemDelay", "Delay" })
    stats.svMagic       = first_num(item, { "SVMagic", "SVMagicResist" })
    stats.svFire        = first_num(item, { "SVFire", "SVFireResist" })
    stats.svCold        = first_num(item, { "SVCold", "SVColdResist" })
    stats.svPoison      = first_num(item, { "SVPoison", "SVPoisonResist" })
    stats.svDisease     = first_num(item, { "SVDisease", "SVDiseaseResist" })
    stats.svCorruption  = first_num(item, { "SVCorruption", "SVCorruptionResist" })
    return stats
end

local BERSERKER_CLASS_NAMES = {
    ["berserker"] = true, ["ber"] = true, ["brs"] = true,
}

local function collect_classes(item)
    local classes = {}
    local count = safe_num(item, "Classes")
    local has_berserker = false
    for i = 1, count do
        local ok, class_name = pcall(function() return item.Class(i)() end)
        if ok and class_name and tostring(class_name) ~= "" then
            local name = tostring(class_name)
            classes[#classes+1] = name
            if BERSERKER_CLASS_NAMES[name:lower()] then has_berserker = true end
        end
    end
    -- "All classes" normally reports 16. Legacy/imported "ALL" items and augs
    -- predate Berserker and report 15 (every class except Berserker), which
    -- wrongly excludes Berserkers. Treat a 15-class list that lacks Berserker
    -- as all-classes too. The has_berserker guard leaves a genuine 15-class
    -- restriction that already includes Berserker untouched.
    local all_classes = count >= 16 or (count >= 15 and not has_berserker)
    return classes, all_classes
end

local function collect_slots(item)
    local slots = {}
    local count = safe_num(item, "WornSlots")
    for i = 1, count do
        local ok, sid = pcall(function() return item.WornSlot(i).ID() end)
        if ok and sid ~= nil then slots[#slots+1] = tonumber(sid) or sid end
    end
    return slots
end

local function classify_item(item, aug_type)
    if (tonumber(aug_type) or 0) > 0 then return "aug" end
    local typ = safe_str(item, "Type"):lower()
    if typ:find("augment", 1, true) then return "aug" end
    if typ:find("weapon", 1, true) or typ:find("1h ", 1, true) or typ:find("2h ", 1, true) or typ:find("bow", 1, true) then return "weapon" end
    if typ:find("armor", 1, true) or typ:find("shield", 1, true) then return "armor" end
    if typ:find("charm", 1, true) then return "charm" end
    if typ:find("ammo", 1, true) then return "ammo" end
    return "unknown"
end

local function collect_socket_types(item)
    local out = {}
    for i = 1, 6 do out[i] = get_socket_type(item, i) end
    return out
end

local function item_meta_key(id, aug_type)
    id = tonumber(id) or 0
    if id <= 0 then return nil end
    return tostring(id) .. ":" .. tostring(tonumber(aug_type) or 0)
end

local function collect_item_meta(item, id, aug_type)
    local key = item_meta_key(id, aug_type)
    if key and item_meta_cache[key] then return item_meta_cache[key] end

    local classes, all_classes = collect_classes(item)
    local meta = {
        stats = collect_stats(item),
        classes = classes,
        allClasses = all_classes,
        slots = collect_slots(item),
        itemType = classify_item(item, aug_type),
        socketTypes = collect_socket_types(item),
        requiredLevel = first_num(item, { "RequiredLevel", "ReqLevel" }),
        recommendedLevel = first_num(item, { "RecommendedLevel", "RecLevel" }),
        tribute = first_num(item, { "Tribute", "Favor", "TributeValue" }),
        lore = safe_bool(item, "Lore") or safe_bool(item, "IsLore") or safe_bool(item, "LoreItem"),
        loreGroup = first_num(item, { "LoreGroup", "LoreGroupId", "LoreID" }),
        focusEffects = focus_extract.collect_focus_effects(item),
        wornFocusEffects = focus_extract.collect_worn_focus_effects(item),
    }
    if key then item_meta_cache[key] = meta end
    return meta
end

local function meta_stats(meta)
    return meta and clone_map(meta.stats) or stat_defs.default_stats()
end

local function meta_classes(meta)
    return meta and clone_array(meta.classes) or {}
end

local function meta_slots(meta)
    return meta and clone_array(meta.slots) or {}
end

local function meta_focus(meta, field)
    local out = {}
    for _, entry in ipairs((meta and meta[field]) or {}) do
        out[#out+1] = clone_map(entry)
    end
    return out
end

local function merge_stats(base, extra)
    local out = clone_map(base)
    for k, v in pairs(extra or {}) do
        local n = tonumber(v)
        if n and n ~= 0 then out[k] = (tonumber(out[k]) or 0) + n end
    end
    return out
end

local function effective_stats(host_stats, augs)
    local total = clone_map(host_stats)
    for _, aug in ipairs(augs or {}) do
        if aug and not aug.empty and type(aug.stats) == "table" then
            total = merge_stats(total, aug.stats)
        end
    end
    return total
end

M.effective_stats = effective_stats

local function aug_item_tlo(item, idx)
    local aug_item = nil
    pcall(function()
        local slot = item.AugSlot(idx)
        if slot and slot() then
            aug_item = slot.Item
            if aug_item and not aug_item() then aug_item = nil end
        end
    end)
    return aug_item
end

local item_aug_type

local function collect_item_augs(item, host_meta)
    local out = {}
    for i = 1, 6 do
        local stype = host_meta and host_meta.socketTypes and host_meta.socketTypes[i] or get_socket_type(item, i)
        if stype and stype > 0 then
            local aug = aug_item_tlo(item, i)
            local present = (aug and aug()) and true or false
            local aid, aicon = 0, 0
            if present then
                pcall(function() aid = aug.ID() or 0 end)
                if not aid or aid == 0 then pcall(function() aid = aug.ItemID() or 0 end) end
                if not aid or aid == 0 then pcall(function() aid = aug.Item.Id() or 0 end) end
                pcall(function() aicon = aug.Icon() or 0 end)
            end
            local aug_type = present and item_aug_type(aug) or 0
            local aug_meta = present and collect_item_meta(aug, aid, aug_type) or nil
            out[#out+1] = {
                index = i,
                type = stype,
                name = present and aug.Name() or "Empty",
                id = aid,
                icon = aicon,
                empty = not present,
                stats = present and meta_stats(aug_meta) or stat_defs.default_stats(),
                classes = present and meta_classes(aug_meta) or {},
                allClasses = (present and aug_meta and aug_meta.allClasses) and true or false,
                slots = present and meta_slots(aug_meta) or {},
                itemType = present and (aug_meta and aug_meta.itemType or "aug") or "aug",
                requiredLevel = present and (tonumber(aug_meta and aug_meta.requiredLevel) or 0) or 0,
                recommendedLevel = present and (tonumber(aug_meta and aug_meta.recommendedLevel) or 0) or 0,
                tribute = present and (tonumber(aug_meta and aug_meta.tribute) or 0) or 0,
                lore = (present and aug_meta and aug_meta.lore) and true or false,
                loreGroup = present and (tonumber(aug_meta and aug_meta.loreGroup) or 0) or 0,
                focusEffects = present and meta_focus(aug_meta, "focusEffects") or {},
                wornFocusEffects = present and meta_focus(aug_meta, "wornFocusEffects") or {},
                clicky = nil,
            }
        end
    end
    return out
end

function item_aug_type(item)
    local ok, val = pcall(function() return item.AugType() end)
    if ok and val and val > 0 then return val end
    return 0
end

local function collect_item_augs_lite(item, host_meta)
    local out = {}
    for i = 1, 6 do
        local stype = host_meta and host_meta.socketTypes and host_meta.socketTypes[i] or get_socket_type(item, i)
        if stype and stype > 0 then
            if M.is_skippable_socket(stype) then goto continue end
            local aug = aug_item_tlo(item, i)
            local present = (aug and aug()) and true or false
            local aid, aicon = 0, 0
            if present then
                pcall(function() aid = aug.ID() or 0 end)
                if not aid or aid == 0 then pcall(function() aid = aug.ItemID() or 0 end) end
                pcall(function() aicon = aug.Icon() or 0 end)
            end
            out[#out+1] = {
                index = i,
                type = stype,
                name = present and aug.Name() or "Empty",
                id = aid,
                icon = aicon,
                empty = not present,
                stats = stat_defs.default_stats(),
                classes = {},
                allClasses = false,
                slots = {},
                itemType = "aug",
                requiredLevel = 0,
                recommendedLevel = 0,
                tribute = 0,
                lore = false,
                loreGroup = 0,
                focusEffects = {},
                wornFocusEffects = {},
                clicky = nil,
            }
        end
        ::continue::
    end
    return out
end

function M.make_item_lite(item, location, where, slotid, slotname)
    local aug_type = item_aug_type(item)
    local id = item.ID() or 0
    local socket_types = collect_socket_types(item)
    local nodrop = (item.NoDrop() and 1 or 0)
    local attuned = safe_bool(item, "Attuned") or safe_bool(item, "IsAttuned")
    local attunable = safe_bool(item, "Attunable") or safe_bool(item, "IsAttunable")
    local item_type = "unknown"
    if (tonumber(aug_type) or 0) > 0 then item_type = "aug"
    else
        local typ = safe_str(item, "Type"):lower()
        if typ:find("weapon", 1, true) then item_type = "weapon"
        elseif typ:find("armor", 1, true) or typ:find("shield", 1, true) then item_type = "armor"
        end
    end
    return {
        name = item.Name() or "?",
        id = id,
        icon = item.Icon() or 0,
        location = location,
        where = where,
        slotid = slotid,
        slotname = slotname,
        qty = tonumber(item.Stack()) or 1,
        nodrop = nodrop,
        attuned = attuned and true or false,
        attunable = attunable and true or false,
        lore = safe_bool(item, "Lore") or safe_bool(item, "IsLore") or safe_bool(item, "LoreItem"),
        loreGroup = first_num(item, { "LoreGroup", "LoreGroupId", "LoreID" }),
        augType = aug_type,
        augs = collect_item_augs_lite(item, { socketTypes = socket_types }),
        stats = stat_defs.default_stats(),
        baseStats = stat_defs.default_stats(),
        classes = {},
        allClasses = false,
        slots = {},
        itemType = item_type,
        requiredLevel = 0,
        recommendedLevel = 0,
        tribute = 0,
        focusEffects = {},
        wornFocusEffects = {},
        clicky = nil,
        depth = "lite",
    }
end

function M.make_item(item, location, where, slotid, slotname)
    local aug_type = item_aug_type(item)
    local id = item.ID() or 0
    local meta = collect_item_meta(item, id, aug_type)
    local host_stats = meta_stats(meta)
    local augs = collect_item_augs(item, meta)
    local nodrop = (item.NoDrop() and 1 or 0)
    local attuned = safe_bool(item, "Attuned") or safe_bool(item, "IsAttuned")
    local attunable = safe_bool(item, "Attunable") or safe_bool(item, "IsAttunable")
    return {
        name = item.Name() or "?", id = id, icon = item.Icon() or 0,
        location = location, where = where, slotid = slotid, slotname = slotname,
        qty = tonumber(item.Stack()) or 1, nodrop = nodrop,
        attuned = attuned and true or false,
        attunable = attunable and true or false,
        lore = meta.lore and true or false,
        loreGroup = tonumber(meta.loreGroup) or 0,
        augType = aug_type, augs = augs,
        stats = effective_stats(host_stats, augs),
        baseStats = host_stats,
        statsMerged = true,
        classes = meta_classes(meta),
        allClasses = meta.allClasses and true or false,
        slots = meta_slots(meta),
        itemType = meta.itemType,
        requiredLevel = tonumber(meta.requiredLevel) or 0,
        recommendedLevel = tonumber(meta.recommendedLevel) or 0,
        tribute = tonumber(meta.tribute) or 0,
        focusEffects = meta_focus(meta, "focusEffects"),
        wornFocusEffects = meta_focus(meta, "wornFocusEffects"),
        clicky = nil,
        depth = "full",
    }
end

function M.resolve_item_tlo(id, name)
    id = tonumber(id) or 0
    name = tostring(name or ""):match("^%s*(.-)%s*$") or ""

    local function valid(it)
        local ok, exists = pcall(function() return it and it() end)
        return ok and exists and true or false
    end

    if id > 0 then
        local ok, it = pcall(function() return mq.TLO.Item(id) end)
        if ok and valid(it) then return it end
        ok, it = pcall(function() return mq.TLO.FindItem(id) end)
        if ok and valid(it) then return it end
    end
    if name ~= "" then
        local ok, it = pcall(function() return mq.TLO.FindItem("=" .. name) end)
        if ok and valid(it) then return it end
        ok, it = pcall(function() return mq.TLO.FindItem(name) end)
        if ok and valid(it) then return it end
    end
    return nil
end

function M.make_virtual_item(id, name, slotid, slotname)
    id = tonumber(id) or 0
    name = tostring(name or ""):match("^%s*(.-)%s*$") or ""
    slotname = slotname or M.slot_display_name(slotid)
    local item = M.resolve_item_tlo(id, name)
    if item then
        return M.make_item(item, "Loadout", slotname, slotid, slotname)
    end
    return {
        name = name ~= "" and name or (id > 0 and ("Item " .. tostring(id)) or "?"),
        id = id > 0 and math.floor(id) or 0,
        icon = 0,
        location = "Loadout",
        where = slotname or "Equipped",
        slotid = slotid,
        slotname = slotname,
        qty = 1,
        nodrop = 0,
        augType = 0,
        augs = {},
        stats = stat_defs.default_stats(),
        baseStats = stat_defs.default_stats(),
        statsMerged = true,
        classes = {},
        allClasses = false,
        slots = slotid and { slotid } or {},
        itemType = "unknown",
        requiredLevel = 0,
        recommendedLevel = 0,
        tribute = 0,
        focusEffects = {},
        wornFocusEffects = {},
        clicky = nil,
        depth = "virtual",
        unresolved = true,
    }
end

return M
