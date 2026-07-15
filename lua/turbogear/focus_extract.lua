-- TurboGear/focus_extract.lua
-- Snapshot-time focus/worn-effect extraction. Do not call this from ImGui draw.

local M = {}

local FOCUS_TYPES = {
    [124] = "Spell Damage",
    [125] = "Healing",
    [126] = "Resist",
    [127] = "Cast Time",
    [128] = "Duration",
    [129] = "Range",
    [130] = "Hate",
    [131] = "Reagent",
    [132] = "Mana Cost",
    [133] = "Stun Time",
    [167] = "Pet Power",
    [174] = "Trigger Chance",
    [175] = "Spell Haste",
}

local WORN_KEYWORDS = {
    { typeId = 1, name = "Cleave" },
    { typeId = 2, name = "Ferocity" },
    { typeId = 3, name = "Dodge" },
    { typeId = 4, name = "Parry" },
}

local RESISTS = {
    [1] = "Magic",
    [2] = "Fire",
    [3] = "Cold",
    [4] = "Poison",
    [5] = "Disease",
    [6] = "Chromatic",
    [7] = "Prismatic",
    [8] = "Physical",
    [9] = "Corruption",
}

local function safe_call(fn, default)
    local ok, value = pcall(fn)
    if not ok or value == nil then return default end
    return value
end

local function safe_num(fn)
    return tonumber(safe_call(fn, 0)) or 0
end

local function safe_str(fn)
    return tostring(safe_call(fn, "") or "")
end

local function spell_exists(spell)
    if not spell then return false end
    if safe_num(function() return spell.ID() end) > 0 then return true end
    return safe_str(function() return spell.Name() end) ~= ""
end

local function spell_name(spell)
    return safe_str(function() return spell.Name() end)
end

local function spell_id(spell)
    return safe_num(function() return spell.ID() end)
end

function M.process_focus_spell(spell)
    if not spell_exists(spell) then return nil end
    local effective_level, focus_type, max_effect, resist, spell_type = 0, 0, 0, "", ""
    local effects = safe_num(function() return spell.NumEffects() end)
    for effect = 1, effects do
        local attr = safe_num(function() return spell.Attrib(effect)() end)
        local base = safe_num(function() return spell.Base(effect)() end)
        local base2 = safe_num(function() return spell.Base2(effect)() end)
        if attr == 134 then
            effective_level = base
        elseif FOCUS_TYPES[attr] then
            focus_type = attr
            max_effect = base2 ~= 0 and base2 or base
        elseif attr == 135 then
            resist = RESISTS[base] or ""
        elseif attr == 138 then
            if base == 0 then
                spell_type = "Detrimental"
            elseif base == 1 then
                spell_type = "Beneficial"
            elseif base ~= 0 then
                spell_type = "Unknown"
            end
        end
    end
    if focus_type == 0 then return nil end
    return {
        typeId = focus_type,
        typeName = FOCUS_TYPES[focus_type] or ("SPA " .. tostring(focus_type)),
        maxEffect = max_effect,
        effectiveLevel = effective_level,
        resist = resist,
        spellType = spell_type,
        spellName = spell_name(spell),
        spellId = spell_id(spell),
    }
end

function M.collect_focus_effects(item)
    if not item then return {} end
    local spell = safe_call(function() return item.Focus.Spell end, nil)
    local entry = M.process_focus_spell(spell)
    return entry and { entry } or {}
end

function M.collect_worn_focus_effects(item)
    if not item then return {} end
    local spell = safe_call(function() return item.Worn.Spell end, nil)
    if not spell_exists(spell) then return {} end
    local name = spell_name(spell)
    local out = {}
    for _, def in ipairs(WORN_KEYWORDS) do
        if name:find(def.name, 1, true) then
            out[#out+1] = {
                typeId = def.typeId,
                typeName = def.name,
                rank = safe_num(function() return spell.Rank() end),
                description = name,
                spellName = name,
                spellId = spell_id(spell),
            }
        end
    end
    return out
end

return M
