-- Build a runtime-shaped TurboGear BiS catalog from the Turbo-owned canonical
-- source prototype.
--
-- Phase 1B safety: this builder requires an explicit --out path and never
-- defaults to lua/turbogear/catalogs/lazbis.lua.
--
-- Usage:
--   luajit tools/build_turbogear_catalog.lua --source catalog_source/bis/catalog.lua --out tmp/phase1b/catalog-a.lua

local args = arg or {}
local source_path, out_path

local function usage(message)
    if message and message ~= "" then io.stderr:write(message .. "\n") end
    io.stderr:write("usage: luajit tools/build_turbogear_catalog.lua --source catalog_source/bis/catalog.lua --out tmp/phase1b/catalog.lua\n")
    os.exit(2)
end

local i = 1
while i <= #args do
    local a = tostring(args[i] or "")
    if a == "--source" then
        i = i + 1
        source_path = args[i]
    elseif a:match("^%-%-source=") then
        source_path = a:match("^%-%-source=(.*)$")
    elseif a == "--out" then
        i = i + 1
        out_path = args[i]
    elseif a:match("^%-%-out=") then
        out_path = a:match("^%-%-out=(.*)$")
    elseif a == "--help" or a == "-h" then
        usage()
    else
        usage("unknown argument: " .. a)
    end
    i = i + 1
end

if not source_path or tostring(source_path) == "" then usage("--source is required") end
if not out_path or tostring(out_path) == "" then usage("--out is required") end

local normalized_out = tostring(out_path):gsub("\\", "/"):lower()
if normalized_out == "lua/turbogear/catalogs/lazbis.lua" then
    usage("refusing to write runtime catalog in Phase 1B: " .. tostring(out_path))
end

package.path = "lua/turbogear/?.lua;" .. package.path
local content_hash = require("catalog_content_hash")

local function trim(s)
    return tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function copy_array(src)
    local out = {}
    for _, v in ipairs(type(src) == "table" and src or {}) do out[#out + 1] = v end
    return out
end

local function copy_scalar_map(src)
    local out = {}
    for k, v in pairs(type(src) == "table" and src or {}) do
        if type(v) == "table" then
            out[k] = copy_scalar_map(v)
        else
            out[k] = v
        end
    end
    return out
end

local function sorted_keys(t)
    local keys = {}
    for k in pairs(t or {}) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b)
        local ta, tb = type(a), type(b)
        if ta ~= tb then return ta < tb end
        if ta == "number" then return a < b end
        return tostring(a) < tostring(b)
    end)
    return keys
end

local function runtime_ids_from_identity_row(entry)
    local ids, names = {}, {}
    local identities = type(entry.identities) == "table" and entry.identities or nil
    if not identities then return nil, nil end

    local component = identities.shadow_component
    if type(component) == "table" then
        if tonumber(component.id) then ids[#ids + 1] = math.floor(tonumber(component.id)) end
        if trim(component.name) ~= "" then names[#names + 1] = trim(component.name) end
    end
    for _, reward in ipairs(type(identities.rewards) == "table" and identities.rewards or {}) do
        if type(reward) == "table" then
            if tonumber(reward.id) then ids[#ids + 1] = math.floor(tonumber(reward.id)) end
            if trim(reward.name) ~= "" then names[#names + 1] = trim(reward.name) end
        end
    end
    return ids, names
end

local function emit_entry(entry, list_id, slot)
    if type(entry) ~= "table" then return nil end
    local out = {}
    local item = trim(entry.item or entry.name or "")
    if item ~= "" then out.item = item end
    out.slot = tostring(slot or "")

    local ids, names
    if list_id == "don" and tostring(slot or "") == "Shadow" and type(entry.identities) == "table" then
        ids, names = runtime_ids_from_identity_row(entry)
    end
    if not ids then ids = copy_array(entry.ids) end
    if not names then names = copy_array(entry.aliases or entry.names) end

    out.names = names
    out.ids = ids

    if trim(entry.source) ~= "" then out.source = trim(entry.source) end
    if trim(entry.notes) ~= "" then out.notes = trim(entry.notes) end
    if trim(entry.spell) ~= "" then out.spell = trim(entry.spell) end
    if type(entry.spells) == "table" then
        out.spells = copy_array(entry.spells)
        if not out.spell and out.spells[1] then out.spell = out.spells[1] end
    end
    if type(entry.spell_ids) == "table" then out.spell_ids = copy_array(entry.spell_ids) end
    if entry.socket ~= nil then out.socket = entry.socket end
    return out
end

local function emit_bucket(bucket, list_id)
    local out = {}
    for _, slot in ipairs(sorted_keys(bucket)) do
        local entry = emit_entry(bucket[slot], list_id, slot)
        if entry then out[slot] = entry end
    end
    return out
end

local function emit_categories(categories)
    local out = {}
    for _, cat in ipairs(type(categories) == "table" and categories or {}) do
        out[#out + 1] = {
            name = cat.name or cat.Name or "Items",
            slots = copy_array(cat.slots or cat.Slots),
        }
    end
    return out
end

local function emit_groups(groups)
    local out = {}
    for _, group in ipairs(type(groups) == "table" and groups or {}) do
        local g = { name = group.name or group.Name or "", lists = {} }
        for _, rec in ipairs(group.lists or {}) do
            g.lists[#g.lists + 1] = { id = rec.id, name = rec.name }
        end
        out[#out + 1] = g
    end
    return out
end

local function emit_catalog(src)
    local catalog = {
        source = "TurboGear",
        generated_from = "catalog_source/bis/catalog.lua",
        groups = emit_groups(src.groups),
        lists = {},
        zone_map = copy_scalar_map(src.zone_map),
        default = copy_scalar_map(src.default),
    }

    for _, list_id in ipairs(sorted_keys(src.lists)) do
        local list = src.lists[list_id]
        if type(list) == "table" then
            local out = {
                id = list.id or list_id,
                name = list.name or "",
                group = list.group or "",
                categories = emit_categories(list.categories),
                template = emit_bucket(list.template, list_id),
                visible = emit_bucket(list.visible, list_id),
                classes = {},
                show_base = copy_scalar_map(list.show_base),
            }
            for _, class_name in ipairs(sorted_keys(list.classes)) do
                out.classes[class_name] = emit_bucket(list.classes[class_name], list_id)
            end
            catalog.lists[list_id] = out
        end
    end
    catalog.content_hash = content_hash.compute(catalog)
    return catalog
end

local function is_array(t)
    if type(t) ~= "table" then return false end
    local n = 0
    for k in pairs(t) do
        if type(k) ~= "number" or k < 1 or k % 1 ~= 0 then return false end
        if k > n then n = k end
    end
    if n == 0 then return false end
    for j = 1, n do if t[j] == nil then return false end end
    return true
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
            parts[#parts + 1] = "\n" .. next_indent .. serialize(item, next_indent) .. ","
        end
    else
        for _, k in ipairs(sorted_keys(v)) do
            local key
            if type(k) == "string" and k:match("^[%a_][%w_]*$") then
                key = k
            else
                key = "[" .. serialize(k, next_indent) .. "]"
            end
            parts[#parts + 1] = "\n" .. next_indent .. key .. " = " .. serialize(v[k], next_indent) .. ","
        end
    end
    parts[#parts + 1] = "\n" .. indent .. "}"
    return table.concat(parts)
end

local chunk, load_err = loadfile(source_path)
if type(chunk) ~= "function" then error("cannot load source " .. tostring(source_path) .. ": " .. tostring(load_err)) end
local ok, source = pcall(chunk)
if not ok then error("cannot execute source " .. tostring(source_path) .. ": " .. tostring(source)) end
if type(source) ~= "table" then error("canonical source must return a table") end

local catalog = emit_catalog(source)
local f, open_err = io.open(out_path, "wb")
if not f then error("cannot open output " .. tostring(out_path) .. ": " .. tostring(open_err)) end
f:write("-- Generated by tools/build_turbogear_catalog.lua; do not edit by hand.\n")
f:write("return ")
f:write(serialize(catalog, ""))
f:write("\n")
f:close()

io.stderr:write(string.format("Wrote %s content_hash=%s\n", out_path, tostring(catalog.content_hash or "")))
