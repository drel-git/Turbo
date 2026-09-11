-- TurboGear/store_persist_encoder.lua
-- Specialized deterministic encoder for Store's persisted slim item structures.
-- This is intentionally narrower than store_backend_sqlite._serialize: it only
-- targets equipped/bag/bank item payloads, leaving lockouts/spells on the
-- generic backend serializer.

local diag = require('diagnostics')
local stat_defs = require('stat_defs')

local M = {}

local SKIP_KEYS = {
    _bis_index = true,
    _bis_index_key = true,
    _payload = true,
    _payload_hash = true,
}

local STAT_KEYS = {}
for _, def in ipairs(stat_defs.stats or {}) do
    if def and def.key then STAT_KEYS[tostring(def.key)] = true end
end

local function diag_enabled()
    return diag.is_enabled and diag.is_enabled()
end

local function diag_t0()
    return diag_enabled() and os.clock() or nil
end

local function diag_sample(label, t0)
    if t0 then diag.sample(label, (os.clock() - t0) * 1000) end
end

local function diag_count(label, amount)
    if diag_enabled() then diag.count(label, amount) end
end

local function encode_scalar(v)
    local t = type(v)
    if t == "number" then
        if v == math.floor(v) and math.abs(v) < 9e15 then return string.format("%d", v) end
        return string.format("%.17g", v)
    elseif t == "boolean" then
        return tostring(v)
    elseif t == "string" then
        return string.format("%q", v)
    end
    return "nil"
end

local function is_dense_array(t)
    local n = #t
    if n <= 0 then return false end
    local count = 0
    for k in pairs(t) do
        if type(k) ~= "number" or k ~= math.floor(k) or k < 1 or k > n then return false end
        count = count + 1
    end
    return count == n
end

local encode_value

local function encode_map(t)
    local map_t0 = diag_t0()
    diag_count("store.persist.encoder.generic_map_fallback_calls")
    local keys = {}
    for k in pairs(t) do
        local tk = type(k)
        if (tk == "number" or tk == "string") and not SKIP_KEYS[k] then
            keys[#keys + 1] = k
        end
    end
    table.sort(keys, function(a, b)
        local ta, tb = type(a), type(b)
        if ta ~= tb then return ta < tb end
        return a < b
    end)
    local parts = {}
    for _, k in ipairs(keys) do
        local kk = (type(k) == "number") and ("[" .. string.format("%d", k) .. "]")
            or ("[" .. string.format("%q", tostring(k)) .. "]")
        parts[#parts + 1] = kk .. "=" .. encode_value(t[k])
    end
    local assemble_t0 = diag_t0()
    local out = "{" .. table.concat(parts, ",") .. "}"
    diag_sample("store.persist.encoder.generic_map_assembly", assemble_t0)
    diag_sample("store.persist.encoder.generic_map", map_t0)
    return out
end

local function encode_key(k)
    if type(k) == "number" then return "[" .. string.format("%d", k) .. "]" end
    return "[" .. string.format("%q", tostring(k)) .. "]"
end

local function encode_stat_map(stats)
    if type(stats) ~= "table" then return encode_value(stats) end
    local parts = {}
    local known = 0
    for _, def in ipairs(stat_defs.stats or {}) do
        local key = def and def.key
        if key ~= nil and stats[key] ~= nil then
            known = known + 1
            parts[#parts + 1] = encode_key(key) .. "=" .. encode_value(stats[key])
        end
    end
    if known > 0 then diag_count("store.persist.encoder.stat_keys_known", known) end

    local unknown = {}
    for k in pairs(stats) do
        local tk = type(k)
        if (tk == "number" or tk == "string") and not SKIP_KEYS[k] and not STAT_KEYS[tostring(k)] then
            unknown[#unknown + 1] = k
        end
    end
    if #unknown > 0 then
        diag_count("store.persist.encoder.stat_keys_unknown", #unknown)
        table.sort(unknown, function(a, b)
            local ta, tb = type(a), type(b)
            if ta ~= tb then return ta < tb end
            return a < b
        end)
        for _, k in ipairs(unknown) do
            parts[#parts + 1] = encode_key(k) .. "=" .. encode_value(stats[k])
        end
    end
    return "{" .. table.concat(parts, ",") .. "}"
end

encode_value = function(v)
    local t = type(v)
    if t ~= "table" then return encode_scalar(v) end
    if is_dense_array(v) then
        local parts = {}
        for i = 1, #v do parts[i] = encode_value(v[i]) end
        return "{" .. table.concat(parts, ",") .. "}"
    end
    return encode_map(v)
end

local function add_field(parts, key, value)
    if value == nil then return end
    parts[#parts + 1] = "[" .. string.format("%q", key) .. "]=" .. encode_value(value)
end

local function add_stats_field(parts, key, stats, label)
    if stats == nil then return end
    local stats_t0 = diag_t0()
    parts[#parts + 1] = "[" .. string.format("%q", key) .. "]=" .. encode_stat_map(stats)
    diag_sample(label, stats_t0)
end

local function encode_focus_entry(entry)
    if type(entry) ~= "table" then return encode_value(entry) end
    local focus_t0 = diag_t0()
    local parts = {}
    add_field(parts, "typeId", entry.typeId)
    add_field(parts, "typeName", entry.typeName)
    add_field(parts, "maxEffect", entry.maxEffect)
    add_field(parts, "effectiveLevel", entry.effectiveLevel)
    add_field(parts, "resist", entry.resist)
    add_field(parts, "spellType", entry.spellType)
    add_field(parts, "spellName", entry.spellName)
    add_field(parts, "spellId", entry.spellId)
    add_field(parts, "rank", entry.rank)
    add_field(parts, "description", entry.description)
    local out = "{" .. table.concat(parts, ",") .. "}"
    diag_sample("store.persist.encoder.focus", focus_t0)
    return out
end

local function encode_focus_list(list)
    if type(list) ~= "table" then return encode_value(list) end
    local focus_t0 = diag_t0()
    local parts = {}
    for i = 1, #list do parts[i] = encode_focus_entry(list[i]) end
    local out = "{" .. table.concat(parts, ",") .. "}"
    diag_sample("store.persist.encoder.focus_list", focus_t0)
    return out
end

local function encode_aug(aug)
    if type(aug) ~= "table" then return encode_value(aug) end
    local aug_t0 = diag_t0()
    diag_count("store.persist.encoder.augments_encoded")
    local parts = {}
    add_field(parts, "index", aug.index)
    add_field(parts, "type", aug.type)
    add_field(parts, "name", aug.name)
    add_field(parts, "id", aug.id)
    add_field(parts, "icon", aug.icon)
    add_field(parts, "empty", aug.empty)
    add_field(parts, "depth", aug.depth)
    add_stats_field(parts, "stats", aug.stats, "store.persist.encoder.stats")
    add_stats_field(parts, "baseStats", aug.baseStats, "store.persist.encoder.baseStats")
    if aug.focusEffects ~= nil then
        parts[#parts + 1] = "[\"focusEffects\"]=" .. encode_focus_list(aug.focusEffects)
    end
    if aug.wornFocusEffects ~= nil then
        parts[#parts + 1] = "[\"wornFocusEffects\"]=" .. encode_focus_list(aug.wornFocusEffects)
    end
    local out = "{" .. table.concat(parts, ",") .. "}"
    diag_sample("store.persist.encoder.aug", aug_t0)
    return out
end

local function encode_aug_list(list)
    if type(list) ~= "table" then return encode_value(list) end
    local aug_t0 = diag_t0()
    local parts = {}
    for i = 1, #list do parts[i] = encode_aug(list[i]) end
    local out = "{" .. table.concat(parts, ",") .. "}"
    diag_sample("store.persist.encoder.aug_list", aug_t0)
    return out
end

function M.encode_item(item)
    if type(item) ~= "table" then return encode_value(item) end
    local parts = {}
    local scalars_t0 = diag_t0()
    add_field(parts, "name", item.name)
    add_field(parts, "id", item.id)
    add_field(parts, "icon", item.icon)
    add_field(parts, "location", item.location)
    add_field(parts, "where", item.where)
    add_field(parts, "slotid", item.slotid)
    add_field(parts, "slotname", item.slotname)
    add_field(parts, "qty", item.qty)
    add_field(parts, "nodrop", item.nodrop)
    add_field(parts, "attuned", item.attuned)
    add_field(parts, "attunable", item.attunable)
    add_field(parts, "lore", item.lore)
    add_field(parts, "loreGroup", item.loreGroup)
    add_field(parts, "augType", item.augType)
    add_field(parts, "depth", item.depth)
    diag_sample("store.persist.encoder.item_scalars", scalars_t0)
    if item.augs ~= nil then
        parts[#parts + 1] = "[\"augs\"]=" .. encode_aug_list(item.augs)
    end
    add_field(parts, "itemType", item.itemType)
    add_field(parts, "requiredLevel", item.requiredLevel)
    add_field(parts, "recommendedLevel", item.recommendedLevel)
    add_field(parts, "allClasses", item.allClasses)
    add_field(parts, "statsMerged", item.statsMerged)
    add_stats_field(parts, "stats", item.stats, "store.persist.encoder.stats")
    add_stats_field(parts, "baseStats", item.baseStats, "store.persist.encoder.baseStats")
    add_field(parts, "classes", item.classes)
    add_field(parts, "slots", item.slots)
    if item.focusEffects ~= nil then
        parts[#parts + 1] = "[\"focusEffects\"]=" .. encode_focus_list(item.focusEffects)
    end
    if item.wornFocusEffects ~= nil then
        parts[#parts + 1] = "[\"wornFocusEffects\"]=" .. encode_focus_list(item.wornFocusEffects)
    end
    local assemble_t0 = diag_t0()
    local out = "{" .. table.concat(parts, ",") .. "}"
    diag_sample("store.persist.encoder.final_assembly", assemble_t0)
    return out
end

function M.encode_item_list(list)
    if type(list) ~= "table" then return "{}" end
    local parts = {}
    for i = 1, #list do parts[i] = M.encode_item(list[i]) end
    return "{" .. table.concat(parts, ",") .. "}"
end

M._encode_value = encode_value

return M
