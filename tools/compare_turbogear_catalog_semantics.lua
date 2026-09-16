-- Compare TurboGear BiS catalog semantics.
--
-- Usage:
--   luajit tools/compare_turbogear_catalog_semantics.lua old.lua new.lua
--
-- The comparator accepts either the current generated runtime catalog shape
-- (names/ids) or the Phase 1A canonical-source prototype shape
-- (aliases/ids/identities). It reports provenance-only differences without
-- failing, but fails on runtime, announce/index, or UI/display differences.

local old_path, new_path = arg and arg[1], arg and arg[2]

local FAIL_SEVERITY = {
    ["runtime behavior"] = true,
    ["announce/index"] = true,
    ["UI/display"] = true,
}

local function usage()
    io.stderr:write("usage: luajit tools/compare_turbogear_catalog_semantics.lua old.lua new.lua\n")
    os.exit(2)
end

if not old_path or not new_path then usage() end

local function trim(s)
    return tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function norm_name(s)
    return trim(s):lower():gsub("`", "'"):gsub("%s+", " ")
end

local function load_table(path)
    local chunk, err = loadfile(path)
    if type(chunk) ~= "function" then
        error("cannot load " .. tostring(path) .. ": " .. tostring(err))
    end
    local ok, value = pcall(chunk)
    if not ok then error("cannot execute " .. tostring(path) .. ": " .. tostring(value)) end
    if type(value) ~= "table" then error("file did not return a table: " .. tostring(path)) end
    return value
end

local function sorted_keys(t)
    local keys = {}
    for k in pairs(t or {}) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    return keys
end

local function copy_array(t)
    local out = {}
    for _, v in ipairs(type(t) == "table" and t or {}) do out[#out + 1] = v end
    return out
end

local function array_sig(t)
    local out = {}
    for _, v in ipairs(type(t) == "table" and t or {}) do out[#out + 1] = tostring(v) end
    return table.concat(out, "\31")
end

local function scalar_sig(v)
    if v == nil then return "" end
    return tostring(v)
end

local function set_sig(t, norm_fn)
    local out, seen = {}, {}
    for _, v in ipairs(type(t) == "table" and t or {}) do
        local key = norm_fn and norm_fn(v) or tostring(v)
        if key ~= "" and not seen[key] then
            seen[key] = true
            out[#out + 1] = key
        end
    end
    table.sort(out)
    return table.concat(out, "\31")
end

local function id_set_sig(t)
    return set_sig(t, function(v)
        local n = tonumber(v)
        if not n or n <= 0 then return "" end
        return tostring(math.floor(n))
    end)
end

local function alias_set_sig(t)
    return set_sig(t, norm_name)
end

local function map_sig(t)
    if type(t) ~= "table" then return "" end
    local parts = {}
    for _, k in ipairs(sorted_keys(t)) do
        local v = t[k]
        if type(v) == "table" then
            parts[#parts + 1] = tostring(k) .. "={" .. map_sig(v) .. "}"
        else
            parts[#parts + 1] = tostring(k) .. "=" .. tostring(v)
        end
    end
    return table.concat(parts, "\30")
end

local function category_sig(categories)
    local parts = {}
    for _, cat in ipairs(type(categories) == "table" and categories or {}) do
        parts[#parts + 1] = tostring(cat.name or "") .. ":" .. array_sig(cat.slots)
    end
    return table.concat(parts, "\30")
end

local function groups_sig(groups)
    local parts = {}
    for _, group in ipairs(type(groups) == "table" and groups or {}) do
        local lists = {}
        for _, rec in ipairs(group.lists or {}) do
            lists[#lists + 1] = tostring(rec.id or "") .. ":" .. tostring(rec.name or "")
        end
        parts[#parts + 1] = tostring(group.name or "") .. "={" .. table.concat(lists, "\31") .. "}"
    end
    return table.concat(parts, "\30")
end

local function canonical_aliases(entry)
    if type(entry) ~= "table" then return {} end
    if type(entry.aliases) == "table" then return copy_array(entry.aliases) end
    if type(entry.names) == "table" then return copy_array(entry.names) end
    local item = trim(entry.item or entry.name or "")
    if item ~= "" then return { item } end
    return {}
end

local function canonical_ids(entry)
    if type(entry) ~= "table" then return {} end
    return copy_array(entry.ids)
end

local function infer_don_shadow_identities(entry)
    if type(entry) ~= "table" then return nil end
    local names = canonical_aliases(entry)
    local ids = canonical_ids(entry)
    local item_low = tostring(entry.item or entry.name or ""):lower()
    local out = { rewards = {} }
    for i, name in ipairs(names) do
        local n = tostring(name or "")
        local low = n:lower()
        local rec = { name = n }
        local id = tonumber(ids[i])
        if id and id > 0 then rec.id = math.floor(id) end
        if low ~= "" and (low == item_low or low:find("^shadow of a legendary ", 1, false)) then
            out.shadow_component = rec
        elseif n ~= "" then
            out.rewards[#out.rewards + 1] = rec
        end
    end
    if not out.shadow_component and #out.rewards == 0 then return nil end
    if #out.rewards == 0 then out.rewards = nil end
    return out
end

local function identity_pair_sig(identities)
    if type(identities) ~= "table" then return "" end
    local parts = {}
    local sc = identities.shadow_component
    if type(sc) == "table" then
        parts[#parts + 1] = "shadow:" .. tostring(sc.id or "") .. ":" .. norm_name(sc.name)
    end
    for _, rec in ipairs(type(identities.rewards) == "table" and identities.rewards or {}) do
        if type(rec) == "table" then
            parts[#parts + 1] = "reward:" .. tostring(rec.id or "") .. ":" .. norm_name(rec.name)
        end
    end
    table.sort(parts)
    return table.concat(parts, "\31")
end

local function normalize_entry(entry, list_id, slot)
    if type(entry) ~= "table" then return nil end
    local identities = entry.identities
    if not identities and list_id == "don" and tostring(slot or "") == "Shadow" then
        identities = infer_don_shadow_identities(entry)
    end
    return {
        item = trim(entry.item or entry.name or ""),
        aliases = alias_set_sig(canonical_aliases(entry)),
        ids = id_set_sig(canonical_ids(entry)),
        spells = array_sig(entry.spells or (entry.spell and { entry.spell } or {})),
        spell_ids = id_set_sig(entry.spell_ids),
        source = scalar_sig(entry.source),
        notes = scalar_sig(entry.notes),
        identities = identity_pair_sig(identities),
        priority_aliases = array_sig(entry.priority_aliases),
    }
end

local function normalize_bucket(bucket, list_id)
    local out = {}
    for slot, entry in pairs(type(bucket) == "table" and bucket or {}) do
        local ne = normalize_entry(entry, list_id, slot)
        if ne then out[tostring(slot)] = ne end
    end
    return out
end

local function normalize_list(list, list_id)
    list = type(list) == "table" and list or {}
    local out = {
        id = tostring(list.id or list_id or ""),
        name = tostring(list.name or ""),
        group = tostring(list.group or ""),
        categories = category_sig(list.categories),
        template = normalize_bucket(list.template, list_id),
        visible = normalize_bucket(list.visible, list_id),
        classes = {},
        show_base = map_sig(list.show_base),
    }
    for class_name, bucket in pairs(type(list.classes) == "table" and list.classes or {}) do
        out.classes[tostring(class_name)] = normalize_bucket(bucket, list_id)
    end
    return out
end

local function normalize_catalog(catalog)
    return {
        groups = groups_sig(catalog.groups),
        default = map_sig(catalog.default),
        zone_map = map_sig(catalog.zone_map),
        lists = (function()
            local out = {}
            for list_id, list in pairs(type(catalog.lists) == "table" and catalog.lists or {}) do
                out[tostring(list_id)] = normalize_list(list, tostring(list_id))
            end
            return out
        end)(),
        provenance = {
            source = scalar_sig(catalog.source),
            generated_from = scalar_sig(catalog.generated_from),
            source_owner = scalar_sig(catalog.source_owner),
            schema = scalar_sig(catalog.schema),
            content_hash = scalar_sig(catalog.content_hash),
            baseline_hash = type(catalog.baseline) == "table" and scalar_sig(catalog.baseline.content_hash) or "",
        },
    }
end

local diffs = {}

local function add_diff(severity, path, old_value, new_value)
    diffs[#diffs + 1] = {
        severity = severity,
        path = path,
        old_value = old_value,
        new_value = new_value,
    }
end

local function compare_value(path, a, b, severity)
    if tostring(a or "") ~= tostring(b or "") then
        add_diff(severity, path, a, b)
    end
end

local function compare_entry(path, a, b)
    a, b = a or {}, b or {}
    compare_value(path .. ".item", a.item, b.item, "runtime behavior")
    compare_value(path .. ".aliases", a.aliases, b.aliases, "announce/index")
    compare_value(path .. ".ids", a.ids, b.ids, "runtime behavior")
    compare_value(path .. ".spells", a.spells, b.spells, "runtime behavior")
    compare_value(path .. ".spell_ids", a.spell_ids, b.spell_ids, "runtime behavior")
    compare_value(path .. ".source", a.source, b.source, "UI/display")
    compare_value(path .. ".notes", a.notes, b.notes, "UI/display")
    compare_value(path .. ".identities", a.identities, b.identities, "runtime behavior")
    compare_value(path .. ".priority_aliases", a.priority_aliases, b.priority_aliases, "announce/index")
end

local function compare_bucket(path, a, b)
    local seen = {}
    for _, key in ipairs(sorted_keys(a)) do
        seen[key] = true
        if not b[key] then
            add_diff("runtime behavior", path .. "." .. key, "present", "missing")
        else
            compare_entry(path .. "." .. key, a[key], b[key])
        end
    end
    for _, key in ipairs(sorted_keys(b)) do
        if not seen[key] then add_diff("runtime behavior", path .. "." .. key, "missing", "present") end
    end
end

local function compare_list(path, a, b)
    compare_value(path .. ".id", a.id, b.id, "runtime behavior")
    compare_value(path .. ".name", a.name, b.name, "UI/display")
    compare_value(path .. ".group", a.group, b.group, "UI/display")
    compare_value(path .. ".categories", a.categories, b.categories, "announce/index")
    compare_value(path .. ".show_base", a.show_base, b.show_base, "UI/display")
    compare_bucket(path .. ".template", a.template, b.template)
    compare_bucket(path .. ".visible", a.visible, b.visible)

    local seen = {}
    for _, class_name in ipairs(sorted_keys(a.classes)) do
        seen[class_name] = true
        if not b.classes[class_name] then
            add_diff("runtime behavior", path .. ".classes." .. class_name, "present", "missing")
        else
            compare_bucket(path .. ".classes." .. class_name, a.classes[class_name], b.classes[class_name])
        end
    end
    for _, class_name in ipairs(sorted_keys(b.classes)) do
        if not seen[class_name] then
            add_diff("runtime behavior", path .. ".classes." .. class_name, "missing", "present")
        end
    end
end

local old_catalog = normalize_catalog(load_table(old_path))
local new_catalog = normalize_catalog(load_table(new_path))

compare_value("groups", old_catalog.groups, new_catalog.groups, "runtime behavior")
compare_value("default", old_catalog.default, new_catalog.default, "runtime behavior")
compare_value("zone_map", old_catalog.zone_map, new_catalog.zone_map, "runtime behavior")

local seen_lists = {}
for _, list_id in ipairs(sorted_keys(old_catalog.lists)) do
    seen_lists[list_id] = true
    if not new_catalog.lists[list_id] then
        add_diff("runtime behavior", "lists." .. list_id, "present", "missing")
    else
        compare_list("lists." .. list_id, old_catalog.lists[list_id], new_catalog.lists[list_id])
    end
end
for _, list_id in ipairs(sorted_keys(new_catalog.lists)) do
    if not seen_lists[list_id] then add_diff("runtime behavior", "lists." .. list_id, "missing", "present") end
end

for _, key in ipairs(sorted_keys(old_catalog.provenance)) do
    compare_value("provenance." .. key, old_catalog.provenance[key], new_catalog.provenance[key], "provenance only")
end
for _, key in ipairs(sorted_keys(new_catalog.provenance)) do
    if old_catalog.provenance[key] == nil then
        compare_value("provenance." .. key, "", new_catalog.provenance[key], "provenance only")
    end
end

local failing = false
for _, diff in ipairs(diffs) do
    if FAIL_SEVERITY[diff.severity] then failing = true end
end

if failing then
    print("SEMANTIC EQUIVALENCE: FAIL")
else
    print("SEMANTIC EQUIVALENCE: PASS")
end

for _, diff in ipairs(diffs) do
    print(string.format("%s\t%s\told=%s\tnew=%s",
        diff.severity,
        diff.path,
        tostring(diff.old_value),
        tostring(diff.new_value)))
end

os.exit(failing and 1 or 0)
