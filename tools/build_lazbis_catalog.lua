-- Build lua/turbogear/catalogs/lazbis.lua from sibling lazbis/bis.lua.
-- Run from the repository root with:
--   luajit tools/build_lazbis_catalog.lua

local in_path = "../lazbis/bis.lua"
local out_path = "lua/turbogear/catalogs/lazbis.lua"
package.path = "lua/turbogear/?.lua;" .. package.path

local raw = dofile(in_path)
local content_hash = require("catalog_content_hash")

local EQ_CLASSES = {
    ["Bard"] = true, ["Beastlord"] = true, ["Berserker"] = true, ["Cleric"] = true,
    ["Druid"] = true, ["Enchanter"] = true, ["Magician"] = true, ["Monk"] = true,
    ["Necromancer"] = true, ["Paladin"] = true, ["Ranger"] = true, ["Rogue"] = true,
    ["Shadow Knight"] = true, ["Shaman"] = true, ["Warrior"] = true, ["Wizard"] = true,
}

local function trim(s)
    return tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function split_item_line(line)
    local entry = { item = "", names = {}, ids = {} }
    local seen_names, seen_ids = {}, {}
    for part in tostring(line or ""):gmatch("[^/]+") do
        part = trim(part)
        local id = tonumber(part)
        if id and id > 0 then
            if not seen_ids[id] then
                seen_ids[id] = true
                entry.ids[#entry.ids+1] = id
            end
        elseif part ~= "" then
            local key = part:lower()
            if not seen_names[key] then
                seen_names[key] = true
                entry.names[#entry.names+1] = part
            end
            if entry.item == "" then entry.item = part end
        end
    end
    if entry.item == "" then return nil end
    table.sort(entry.ids)
    return entry
end

local function copy_categories(src)
    local out = {}
    local main = src and src.Main
    for _, cat in ipairs((main and main.Slots) or {}) do
        local slots = {}
        for _, slot in ipairs(cat.Slots or {}) do slots[#slots+1] = slot end
        out[#out+1] = { name = cat.Name or "Items", slots = slots }
    end
    return out
end

local function normalize_entry_value(line, slot, droppers)
    local item_line, spells, spell_ids, notes, extra_names, extra_ids = line, nil, nil, nil, nil, nil
    if type(line) == "table" then
        item_line = line.item or line.name or ""
        notes = line.notes
        if type(line.names) == "table" then extra_names = line.names end
        if type(line.ids) == "table" then extra_ids = line.ids end
        if type(line.spells) == "table" then
            spells = {}
            for _, s in ipairs(line.spells) do
                s = trim(s)
                if s ~= "" then spells[#spells+1] = s end
            end
            if #spells == 0 then spells = nil end
        elseif type(line.spell) == "string" and trim(line.spell) ~= "" then
            spells = { trim(line.spell) }
        end
        if type(line.spell_ids) == "table" then
            spell_ids = {}
            local seen = {}
            for _, raw in ipairs(line.spell_ids) do
                local id = tonumber(raw)
                if id and id > 0 and not seen[id] then
                    seen[id] = true
                    spell_ids[#spell_ids + 1] = id
                end
            end
            if #spell_ids == 0 then spell_ids = nil end
        end
    elseif type(line) ~= "string" then
        return nil
    end
    local entry = split_item_line(item_line)
    if not entry then return nil end
    -- If the table provided an explicit display name in item without /ids,
    -- prefer short display and merge extra names/ids.
    if type(line) == "table" and type(extra_names) == "table" then
        local seen = {}
        for _, n in ipairs(entry.names or {}) do seen[n:lower()] = true end
        for _, n in ipairs(extra_names) do
            n = trim(n)
            if n ~= "" and not seen[n:lower()] then
                seen[n:lower()] = true
                entry.names[#entry.names+1] = n
            end
        end
        if entry.item == "" or (extra_names[1] and entry.item ~= extra_names[1] and not tostring(item_line):find("/", 1, true)) then
            entry.item = trim(extra_names[1] or entry.item)
        end
        -- Prefer first explicit name as display when item was short-only
        if type(line.item) == "string" and not tostring(line.item):find("/", 1, true) and trim(line.item) ~= "" then
            entry.item = trim(line.item)
        end
    end
    if type(extra_ids) == "table" then
        local seen = {}
        for _, id in ipairs(entry.ids or {}) do seen[id] = true end
        for _, id in ipairs(extra_ids) do
            id = tonumber(id)
            if id and id > 0 and not seen[id] then
                seen[id] = true
                entry.ids[#entry.ids+1] = id
            end
        end
        table.sort(entry.ids)
    end
    entry.slot = slot
    if spells then
        entry.spells = spells
        entry.spell = spells[1]
    end
    if spell_ids then
        entry.spell_ids = spell_ids
    end
    if type(notes) == "string" and trim(notes) ~= "" then
        entry.notes = trim(notes)
    end
    for _, name in ipairs(entry.names or {}) do
        if droppers and droppers[name] then
            entry.source = droppers[name]
            break
        end
    end
    return entry
end

local function normalize_bucket(bucket, droppers)
    local out = {}
    for slot, line in pairs(bucket or {}) do
        if type(slot) == "string" and slot ~= "Slots" then
            local entry = normalize_entry_value(line, slot, droppers)
            if entry then out[slot] = entry end
        end
    end
    return out
end

local function infer_categories(list)
    if list.categories and #list.categories > 0 then return list.categories end
    local seen, slots = {}, {}
    local function add(slot)
        if slot and slot ~= "" and not seen[slot] then
            seen[slot] = true
            slots[#slots+1] = slot
        end
    end
    for slot in pairs(list.template or {}) do add(slot) end
    for slot in pairs(list.visible or {}) do add(slot) end
    for _, bucket in pairs(list.classes or {}) do for slot in pairs(bucket) do add(slot) end end
    table.sort(slots)
    return { { name = "Items", slots = slots } }
end

local catalog = {
    source = "LazBiS",
    generated_from = in_path,
    groups = {},
    lists = {},
    zone_map = raw.ZoneMap or {},
    default = raw.DefaultItemList or {},
}

for _, group_name in ipairs(raw.Groups or {}) do
    local group = { name = group_name, lists = {} }
    for _, meta in ipairs((raw.ItemLists and raw.ItemLists[group_name]) or {}) do
        group.lists[#group.lists+1] = { id = meta.id, name = meta.name }
        local src = raw[meta.id] or {}
        local list = {
            id = meta.id,
            name = meta.name,
            group = group_name,
            categories = copy_categories(src),
            template = normalize_bucket(src.Template, raw.LootDroppers),
            visible = normalize_bucket(src.Visible, raw.LootDroppers),
            classes = {},
            show_base = src.ShowBaseItemNames or {},
        }
        for class_name, bucket in pairs(src) do
            if EQ_CLASSES[class_name] and type(bucket) == "table" then
                list.classes[class_name] = normalize_bucket(bucket, raw.LootDroppers)
            end
        end
        list.categories = infer_categories(list)
        catalog.lists[meta.id] = list
    end
    catalog.groups[#catalog.groups+1] = group
end
catalog.content_hash = content_hash.compute(catalog)

local function is_array(t)
    if type(t) ~= "table" then return false end
    local n = 0
    for k in pairs(t) do
        if type(k) ~= "number" or k < 1 or k % 1 ~= 0 then return false end
        if k > n then n = k end
    end
    for i = 1, n do if t[i] == nil then return false end end
    return true
end

local function sorted_keys(t)
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    return keys
end

local function serialize(v, indent)
    indent = indent or ""
    local tv = type(v)
    if tv == "string" then return string.format("%q", v) end
    if tv == "number" or tv == "boolean" then return tostring(v) end
    if tv ~= "table" then return "nil" end
    local next_indent = indent .. "  "
    local parts = { "{" }
    if is_array(v) then
        for _, item in ipairs(v) do
            parts[#parts+1] = "\n" .. next_indent .. serialize(item, next_indent) .. ","
        end
    else
        for _, k in ipairs(sorted_keys(v)) do
            local key
            if type(k) == "string" and k:match("^[%a_][%w_]*$") then key = k
            else key = "[" .. serialize(k, next_indent) .. "]" end
            parts[#parts+1] = "\n" .. next_indent .. key .. " = " .. serialize(v[k], next_indent) .. ","
        end
    end
    parts[#parts+1] = "\n" .. indent .. "}"
    return table.concat(parts)
end

local f = assert(io.open(out_path, "w"))
f:write("-- Generated by tools/build_lazbis_catalog.lua; do not edit by hand.\n")
f:write("return ")
f:write(serialize(catalog, ""))
f:write("\n")
f:close()
print(string.format("Wrote %s", out_path))
