-- TurboGear/stat_defs.lua
-- Curated stat list for cached item snapshots and Stats tab display.

local M = {}

M.stats = {
    { key = 'shielding',     label = 'Shielding',      suffix = '',  defaultSort = 'desc' },
    { key = 'avoidance',     label = 'Avoidance',      suffix = '',  defaultSort = 'desc' },
    { key = 'accuracy',      label = 'Accuracy',       suffix = '',  defaultSort = 'desc' },
    { key = 'combatEffects', label = 'Combat Effects', suffix = '',  defaultSort = 'desc' },
    { key = 'spellShield',   label = 'Spell Shield',   suffix = '',  defaultSort = 'desc' },
    { key = 'dotShielding',  label = 'DoT Shielding',  suffix = '',  defaultSort = 'desc' },
    { key = 'dsMitigation',  label = 'DS Mitigation',  suffix = '',  defaultSort = 'desc' },
    { key = 'stunResist',    label = 'Stun Resist',    suffix = '',  defaultSort = 'desc' },
    { key = 'strikethrough', label = 'Strikethrough',  suffix = '',  defaultSort = 'desc' },

    { key = 'str',           label = 'STR',            suffix = '',  defaultSort = 'desc' },
    { key = 'sta',           label = 'STA',            suffix = '',  defaultSort = 'desc' },
    { key = 'agi',           label = 'AGI',            suffix = '',  defaultSort = 'desc' },
    { key = 'dex',           label = 'DEX',            suffix = '',  defaultSort = 'desc' },
    { key = 'wis',           label = 'WIS',            suffix = '',  defaultSort = 'desc' },
    { key = 'int',           label = 'INT',            suffix = '',  defaultSort = 'desc' },
    { key = 'cha',           label = 'CHA',            suffix = '',  defaultSort = 'desc' },

    { key = 'heroicStr',     label = 'Heroic STR',     suffix = '',  defaultSort = 'desc' },
    { key = 'heroicSta',     label = 'Heroic STA',     suffix = '',  defaultSort = 'desc' },
    { key = 'heroicAgi',     label = 'Heroic AGI',     suffix = '',  defaultSort = 'desc' },
    { key = 'heroicDex',     label = 'Heroic DEX',     suffix = '',  defaultSort = 'desc' },
    { key = 'heroicWis',     label = 'Heroic WIS',     suffix = '',  defaultSort = 'desc' },
    { key = 'heroicInt',     label = 'Heroic INT',     suffix = '',  defaultSort = 'desc' },
    { key = 'heroicCha',     label = 'Heroic CHA',     suffix = '',  defaultSort = 'desc' },

    { key = 'ac',            label = 'AC',             suffix = '',  defaultSort = 'desc' },
    { key = 'hp',            label = 'HP',             suffix = '',  defaultSort = 'desc' },
    { key = 'mana',          label = 'Mana',           suffix = '',  defaultSort = 'desc' },
    { key = 'endurance',     label = 'Endurance',      suffix = '',  defaultSort = 'desc' },
    { key = 'spellDamage',   label = 'Spell Damage',   suffix = '',  defaultSort = 'desc' },
    { key = 'healAmount',    label = 'Heal Amount',    suffix = '',  defaultSort = 'desc' },
    { key = 'attack',        label = 'Attack',         suffix = '',  defaultSort = 'desc' },
    { key = 'haste',         label = 'Haste',          suffix = '%', defaultSort = 'desc' },
    { key = 'damage',        label = 'Damage',         suffix = '',  defaultSort = 'desc' },
    { key = 'delay',         label = 'Delay',          suffix = '',  defaultSort = 'asc', lowerBetter = true },
    { key = 'tribute',       label = 'Tribute',        suffix = '',  defaultSort = 'desc', analyzeSkip = true },

    { key = 'svMagic',       label = 'Magic',          suffix = '',  defaultSort = 'desc' },
    { key = 'svFire',        label = 'Fire',           suffix = '',  defaultSort = 'desc' },
    { key = 'svCold',        label = 'Cold',           suffix = '',  defaultSort = 'desc' },
    { key = 'svPoison',      label = 'Poison',         suffix = '',  defaultSort = 'desc' },
    { key = 'svDisease',     label = 'Disease',        suffix = '',  defaultSort = 'desc' },
    { key = 'svCorruption',  label = 'Corruption',     suffix = '',  defaultSort = 'desc' },
}

M.by_key = {}
for _, def in ipairs(M.stats) do
    M.by_key[def.key] = def
end

function M.default_stats()
    local out = {}
    for _, def in ipairs(M.stats) do out[def.key] = 0 end
    return out
end

function M.label(key)
    return (M.by_key[key] and M.by_key[key].label) or tostring(key or "")
end

function M.lower_better(key)
    return M.by_key[key] and M.by_key[key].lowerBetter == true
end

-- Max stats selectable on Suggest tab Compare picker (Phase 1).
M.suggest_compare_max = 5

-- Stats offered on the Suggest tab Compare dropdown (order matters).
M.suggest_compare_keys = {
    'ac', 'hp', 'mana', 'endurance', 'damage', 'delay', 'attack', 'haste',
    'tribute',
    'str', 'sta', 'agi', 'dex', 'wis', 'int', 'cha',
    'heroicStr', 'heroicSta', 'heroicAgi', 'heroicDex', 'heroicWis', 'heroicInt', 'heroicCha',
    'shielding', 'avoidance', 'accuracy', 'combatEffects', 'spellShield', 'dotShielding',
    'dsMitigation', 'stunResist', 'strikethrough', 'spellDamage', 'healAmount',
    'svMagic', 'svFire', 'svCold', 'svPoison', 'svDisease', 'svCorruption',
}

function M.format_value(key, value)
    value = tonumber(value) or 0
    local suffix = (M.by_key[key] and M.by_key[key].suffix) or ""
    if math.floor(value) == value then
        return tostring(math.floor(value)) .. suffix
    end
    return string.format("%.1f%s", value, suffix)
end

-- Compact labels for Suggest row display (full names still used in worn totals).
M.suggest_abbrev = {
    shielding = "Shield", avoidance = "Avoid", accuracy = "Acc",
    combatEffects = "CE", spellShield = "SS", dotShielding = "DoT",
    dsMitigation = "DS Mit", stunResist = "Stun", strikethrough = "Strike",
    endurance = "End", damage = "Dmg", spellDamage = "Spell Dmg",
    healAmount = "Heal", attack = "Atk", haste = "Haste", tribute = "Trib",
    ac = "AC", hp = "HP", mana = "Mana",
}

function M.compact_label(key)
    return M.suggest_abbrev[key] or M.label(key)
end

-- Analyze / compare layout (Stats loadout summary). Tribute omitted via analyzeSkip.
M.analyze_column_headers = { "Core", "Defense", "Combat", "Attributes", "Heroics" }

M.analyze_column_groups = {
    { 'hp', 'ac', 'mana', 'endurance' },
    { 'shielding', 'avoidance', 'spellShield', 'dotShielding', 'dsMitigation', 'stunResist', 'spellDamage' },
    { 'attack', 'accuracy', 'combatEffects', 'strikethrough', 'haste', 'damage', 'delay' },
    { 'str', 'sta', 'agi', 'dex', 'wis', 'int', 'cha' },
    { 'heroicStr', 'heroicSta', 'heroicAgi', 'heroicDex', 'heroicWis', 'heroicInt', 'heroicCha' },
}

M.analyze_abbrev = {
    combatEffects = "Combat Eff",
    strikethrough = "Strike",
    dsMitigation = "DS Mit",
    dotShielding = "DoT Shield",
}

M.analyze_extra_keys = {
    'healAmount', 'svMagic', 'svFire', 'svCold', 'svPoison', 'svDisease', 'svCorruption',
}

function M.analyze_skip_key(key)
    if key == 'tribute' then return true end
    local def = M.by_key[key]
    return def and def.analyzeSkip == true
end

function M.analyze_label(key)
    return M.analyze_abbrev[key] or M.label(key)
end

function M.analyze_value(key, totals)
    return M.format_value(key, totals and totals[key])
end

function M.analyze_has_value(key, totals)
    if M.analyze_skip_key(key) then return false end
    return (tonumber(totals and totals[key]) or 0) ~= 0
end

function M.analyze_compare_row(key, totals_a, totals_b)
    if M.analyze_skip_key(key) then return nil end
    local def = M.by_key[key]
    if not def then return nil end
    local a = tonumber(totals_a and totals_a[key]) or 0
    local b = tonumber(totals_b and totals_b[key]) or 0
    local d = b - a
    if a == 0 and b == 0 and d == 0 then return nil end
    return { key = key, def = def, label = def.label, a = a, b = b, d = d }
end

function M.format_signed_delta(key, value)
    value = tonumber(value) or 0
    if value == 0 then return M.format_value(key, 0) end
    local sign = value > 0 and "+" or ""
    return sign .. M.format_value(key, value)
end

function M.analyze_totals_rows(totals)
    local groups = {}
    for gi, keys in ipairs(M.analyze_column_groups) do
        groups[gi] = {}
        for _, key in ipairs(keys) do
            if M.analyze_has_value(key, totals) then
                groups[gi][#groups[gi] + 1] = {
                    key = key,
                    label = M.analyze_label(key),
                    value = M.analyze_value(key, totals),
                }
            end
        end
    end
    local extras = groups[#groups]
    for _, key in ipairs(M.analyze_extra_keys) do
        if M.analyze_has_value(key, totals) then
            extras[#extras + 1] = {
                key = key,
                label = M.analyze_label(key),
                value = M.analyze_value(key, totals),
            }
        end
    end
    return groups
end

function M.analyze_compare_rows(totals_a, totals_b)
    local rows = {}
    local function append(key)
        local row = M.analyze_compare_row(key, totals_a, totals_b)
        if row then rows[#rows + 1] = row end
    end
    for _, group in ipairs(M.analyze_column_groups) do
        for _, key in ipairs(group) do append(key) end
    end
    for _, key in ipairs(M.analyze_extra_keys) do append(key) end
    return rows
end

return M
