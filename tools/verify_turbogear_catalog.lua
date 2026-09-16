-- Validate the TurboGear-owned canonical BiS catalog source.
--
-- Phase 1C safety: this tool reads the canonical source directly and never
-- writes runtime artifacts.
--
-- Usage:
--   luajit tools/verify_turbogear_catalog.lua --source catalog_source/bis/catalog.lua

local args = arg or {}
local source_path

local function usage(message)
    if message and message ~= "" then io.stderr:write(message .. "\n") end
    io.stderr:write("usage: luajit tools/verify_turbogear_catalog.lua --source catalog_source/bis/catalog.lua\n")
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
    elseif a == "--help" or a == "-h" then
        usage()
    else
        usage("unknown argument: " .. a)
    end
    i = i + 1
end

if not source_path or tostring(source_path) == "" then usage("--source is required") end

local EXPECTED_SCHEMA = "turbogear_bis_canonical_v1"

local CLASSES = {
    "Bard",
    "Beastlord",
    "Berserker",
    "Cleric",
    "Druid",
    "Enchanter",
    "Magician",
    "Monk",
    "Necromancer",
    "Paladin",
    "Ranger",
    "Rogue",
    "Shadow Knight",
    "Shaman",
    "Warrior",
    "Wizard",
}

local CLASS_SET = {}
for _, class_name in ipairs(CLASSES) do CLASS_SET[class_name] = true end

local ALLOWED_TOP = {
    baseline = true,
    builder = true,
    default = true,
    groups = true,
    lists = true,
    schema = true,
    source_owner = true,
    zone_map = true,
}

local ALLOWED_LIST = {
    categories = true,
    classes = true,
    group = true,
    id = true,
    name = true,
    show_base = true,
    template = true,
    virtual = true,
    visible = true,
}

local ALLOWED_CATEGORY = {
    display_only_slots = true,
    name = true,
    slots = true,
}

local ALLOWED_ROW = {
    aliases = true,
    identities = true,
    ids = true,
    item = true,
    name = true,
    notes = true,
    priority_aliases = true,
    socket = true,
    source = true,
    spell = true,
    spell_ids = true,
    spells = true,
}

local RECOGNIZED_VIRTUAL_ROLES = {
    class_epic_2_75 = true,
    reward = true,
}

local issues = {
    ERROR = {},
    WARNING = {},
    INFO = {},
}

local counts = {
    groups = 0,
    lists = 0,
    categories = 0,
    category_slot_refs = 0,
    classes_supported = #CLASSES,
    class_scopes = 0,
    ordinary_rows = 0,
    virtual_rows = 0,
    paired_identity_blocks = 0,
    aliases = 0,
    ids = 0,
    zone_map_entries = 0,
}

local alias_index = {}
local id_index = {}
local row_index = {}

local function trim(s)
    return tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function norm_name(s)
    return trim(s):lower():gsub("`", "'"):gsub("%s+", " ")
end

local function sorted_keys(t)
    local keys = {}
    for k in pairs(type(t) == "table" and t or {}) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b)
        local ta, tb = type(a), type(b)
        if ta ~= tb then return ta < tb end
        if ta == "number" then return a < b end
        return tostring(a) < tostring(b)
    end)
    return keys
end

local function issue(severity, ctx, message)
    issues[severity][#issues[severity] + 1] = {
        ctx = ctx or "catalog",
        message = message or "",
    }
end

local function err(ctx, message) issue("ERROR", ctx, message) end
local function warn(ctx, message) issue("WARNING", ctx, message) end
local function info(ctx, message) issue("INFO", ctx, message) end

local function ctx(list_id, scope, slot, field)
    local parts = {}
    if trim(list_id) ~= "" then parts[#parts + 1] = trim(list_id) end
    if trim(scope) ~= "" then parts[#parts + 1] = trim(scope) end
    if trim(slot) ~= "" then parts[#parts + 1] = trim(slot) end
    if trim(field) ~= "" then parts[#parts + 1] = trim(field) end
    if #parts == 0 then return "catalog" end
    return table.concat(parts, "/")
end

local function load_table(path)
    local chunk, load_err = loadfile(path)
    if type(chunk) ~= "function" then
        io.stderr:write("TurboGear BiS validation: FAIL\n")
        io.stderr:write("ERROR [source] cannot load " .. tostring(path) .. ": " .. tostring(load_err) .. "\n")
        os.exit(1)
    end
    local ok, value = pcall(chunk)
    if not ok then
        io.stderr:write("TurboGear BiS validation: FAIL\n")
        io.stderr:write("ERROR [source] cannot execute " .. tostring(path) .. ": " .. tostring(value) .. "\n")
        os.exit(1)
    end
    if type(value) ~= "table" then
        io.stderr:write("TurboGear BiS validation: FAIL\n")
        io.stderr:write("ERROR [source] file must return a table\n")
        os.exit(1)
    end
    return value
end

local function is_array(t)
    if type(t) ~= "table" then return false end
    local n = 0
    for k in pairs(t) do
        if type(k) ~= "number" or k < 1 or k % 1 ~= 0 then return false end
        if k > n then n = k end
    end
    for j = 1, n do if t[j] == nil then return false end end
    return true
end

local function validate_array(ctx_text, value, field_name, required)
    if value == nil then
        if required then err(ctx_text, field_name .. " table is required") end
        return false
    end
    if type(value) ~= "table" then
        err(ctx_text, field_name .. " must be a table")
        return false
    end
    if not is_array(value) then
        err(ctx_text, field_name .. " must be a dense deterministic array")
        return false
    end
    return true
end

local function add_row_ref(list_id, scope, slot, entry)
    row_index[list_id] = row_index[list_id] or {}
    row_index[list_id][slot] = row_index[list_id][slot] or {}
    row_index[list_id][slot][#row_index[list_id][slot] + 1] = {
        scope = scope,
        entry = entry,
    }
end

local function add_alias(alias, list_id, scope, slot, entry)
    local n = norm_name(alias)
    if n == "" then return end
    alias_index[n] = alias_index[n] or {}
    alias_index[n][#alias_index[n] + 1] = {
        alias = trim(alias),
        list_id = list_id,
        scope = scope,
        slot = slot,
        item = trim(entry.item or entry.name or ""),
        ids = entry.ids,
    }
end

local function add_id(id, list_id, scope, slot, entry, role)
    local n = tonumber(id)
    if not n then return end
    local key = tostring(math.floor(n))
    id_index[key] = id_index[key] or {}
    id_index[key][#id_index[key] + 1] = {
        id = math.floor(n),
        list_id = list_id,
        scope = scope,
        slot = slot,
        item = trim(entry.item or entry.name or ""),
        role = role or "row",
    }
end

local function id_signature(ids)
    local out = {}
    for _, id in ipairs(type(ids) == "table" and ids or {}) do
        local n = tonumber(id)
        if n and n > 0 then out[#out + 1] = tostring(math.floor(n)) end
    end
    table.sort(out)
    return table.concat(out, ",")
end

local function validate_id_array(ctx_text, ids)
    if ids == nil then return 0 end
    if not validate_array(ctx_text, ids, "ids", false) then return 0 end
    local seen, count = {}, 0
    for i, id in ipairs(ids) do
        local n = tonumber(id)
        if type(id) ~= "number" or not n or n <= 0 or n % 1 ~= 0 then
            err(ctx_text, "ids[" .. i .. "] must be a positive integer")
        else
            count = count + 1
            local key = tostring(n)
            if seen[key] then
                err(ctx_text, "duplicate id within row: " .. key)
            end
            seen[key] = true
        end
    end
    return count
end

local function validate_alias_array(ctx_text, aliases)
    if aliases == nil then return 0 end
    if not validate_array(ctx_text, aliases, "aliases", false) then return 0 end
    local seen, count = {}, 0
    for i, alias in ipairs(aliases) do
        if type(alias) ~= "string" or trim(alias) == "" then
            err(ctx_text, "aliases[" .. i .. "] must be a non-empty string")
        else
            count = count + 1
            local key = norm_name(alias)
            if seen[key] then
                err(ctx_text, "duplicate alias within row: " .. trim(alias))
            end
            seen[key] = true
        end
    end
    return count
end

local function validate_string_field(ctx_text, entry, field_name, severity_if_blank)
    if entry[field_name] == nil then return end
    if type(entry[field_name]) ~= "string" then
        err(ctx_text, field_name .. " must be a string")
    elseif trim(entry[field_name]) == "" then
        if severity_if_blank == "ERROR" then
            err(ctx_text, field_name .. " must not be blank")
        else
            warn(ctx_text, field_name .. " is blank")
        end
    end
end

local function validate_spell_metadata(ctx_text, entry)
    validate_string_field(ctx_text, entry, "spell", "WARNING")
    if entry.spells ~= nil then
        if validate_array(ctx_text, entry.spells, "spells", false) then
            local seen = {}
            for i, spell in ipairs(entry.spells) do
                if type(spell) ~= "string" or trim(spell) == "" then
                    err(ctx_text, "spells[" .. i .. "] must be a non-empty string")
                else
                    local key = norm_name(spell)
                    if seen[key] then warn(ctx_text, "duplicate spell entry: " .. trim(spell)) end
                    seen[key] = true
                end
            end
            if type(entry.spell) == "string" and trim(entry.spell) ~= "" then
                local first = trim(entry.spells[1] or "")
                if first ~= "" and norm_name(first) ~= norm_name(entry.spell) then
                    warn(ctx_text, "spell does not match first spells[] entry")
                end
            end
        end
    end
    if entry.spell_ids ~= nil then
        if validate_array(ctx_text, entry.spell_ids, "spell_ids", false) then
            local seen = {}
            for i, id in ipairs(entry.spell_ids) do
                local n = tonumber(id)
                if type(id) ~= "number" or not n or n <= 0 or n % 1 ~= 0 then
                    err(ctx_text, "spell_ids[" .. i .. "] must be a positive integer")
                else
                    local key = tostring(n)
                    if seen[key] then warn(ctx_text, "duplicate spell id: " .. key) end
                    seen[key] = true
                end
            end
        end
    end
end

local function validate_identity_record(ctx_text, rec, label)
    if type(rec) ~= "table" then
        err(ctx_text, label .. " must be a table")
        return false
    end
    local ok = true
    local n = tonumber(rec.id)
    if type(rec.id) ~= "number" or not n or n <= 0 or n % 1 ~= 0 then
        err(ctx_text, label .. " id must be a positive integer")
        ok = false
    end
    if type(rec.name) ~= "string" or trim(rec.name) == "" then
        err(ctx_text, label .. " name must be a non-empty string")
        ok = false
    end
    return ok
end

local function validate_paired_identities(list_id, scope, slot, entry)
    if type(entry.identities) ~= "table" then return end
    counts.paired_identity_blocks = counts.paired_identity_blocks + 1
    local ctx_text = ctx(list_id, scope, slot, "identities")
    local ids = entry.identities
    if list_id == "don" and slot == "Shadow" then
        if not validate_identity_record(ctx_text, ids.shadow_component, "shadow_component") then return end
        if not validate_array(ctx_text, ids.rewards, "rewards", true) then return end
        if #ids.rewards < 1 then err(ctx_text, "rewards must contain at least one reward") end
        local component = ids.shadow_component
        local reward_ids, reward_names = {}, {}
        for i, reward in ipairs(ids.rewards) do
            local label = "rewards[" .. i .. "]"
            validate_identity_record(ctx_text, reward, label)
            if type(reward) == "table" then
                if reward.id == component.id then
                    err(ctx_text, label .. " id must not equal shadow_component id")
                end
                if norm_name(reward.name) ~= "" and norm_name(reward.name) == norm_name(component.name) then
                    err(ctx_text, label .. " name must not equal shadow_component name")
                end
                if reward.id then
                    local id_key = tostring(reward.id)
                    if reward_ids[id_key] then err(ctx_text, "duplicate reward id: " .. id_key) end
                    reward_ids[id_key] = true
                    add_id(reward.id, list_id, scope, slot, entry, "reward")
                end
                local name_key = norm_name(reward.name)
                if name_key ~= "" then
                    if reward_names[name_key] then err(ctx_text, "duplicate reward name: " .. trim(reward.name)) end
                    reward_names[name_key] = true
                end
            end
        end
        add_id(component.id, list_id, scope, slot, entry, "shadow_component")
    else
        warn(ctx_text, "paired identities are currently only defined for DoN Shadow rows")
    end
end

local function validate_row(list_id, scope, slot, entry)
    local ctx_text = ctx(list_id, scope, slot)
    if type(entry) ~= "table" then
        err(ctx_text, "row must be a table")
        return
    end
    counts.ordinary_rows = counts.ordinary_rows + 1
    add_row_ref(list_id, scope, slot, entry)

    for _, key in ipairs(sorted_keys(entry)) do
        if not ALLOWED_ROW[key] then warn(ctx_text, "unknown row field: " .. tostring(key)) end
    end

    validate_string_field(ctx_text, entry, "item", "WARNING")
    validate_string_field(ctx_text, entry, "name", "WARNING")
    validate_string_field(ctx_text, entry, "source", "WARNING")
    validate_string_field(ctx_text, entry, "notes", "WARNING")
    validate_spell_metadata(ctx_text, entry)

    local alias_count = validate_alias_array(ctx_text, entry.aliases or entry.names)
    local id_count = validate_id_array(ctx_text, entry.ids)
    counts.aliases = counts.aliases + alias_count
    counts.ids = counts.ids + id_count

    local item = trim(entry.item or entry.name or "")
    if item == "" and alias_count == 0 and id_count == 0 and type(entry.identities) ~= "table" then
        err(ctx_text, "row has no usable identity: item, alias, or positive id required")
    elseif item == "" then
        warn(ctx_text, "row has aliases/ids but no canonical display item")
    end

    if entry.priority_aliases ~= nil then
        if validate_array(ctx_text, entry.priority_aliases, "priority_aliases", false) then
            local declared = {}
            if item ~= "" then declared[norm_name(item)] = true end
            for _, alias in ipairs(type(entry.aliases) == "table" and entry.aliases or {}) do
                declared[norm_name(alias)] = true
            end
            for i, alias in ipairs(entry.priority_aliases) do
                if type(alias) ~= "string" or trim(alias) == "" then
                    err(ctx_text, "priority_aliases[" .. i .. "] must be a non-empty string")
                elseif not declared[norm_name(alias)] then
                    err(ctx_text, "priority_alias not declared in aliases/item: " .. trim(alias))
                end
            end
        end
    end

    for _, alias in ipairs(type(entry.aliases) == "table" and entry.aliases or {}) do
        add_alias(alias, list_id, scope, slot, entry)
    end
    for _, id in ipairs(type(entry.ids) == "table" and entry.ids or {}) do
        add_id(id, list_id, scope, slot, entry)
    end

    validate_paired_identities(list_id, scope, slot, entry)
end

local function bucket_has_slot(bucket, slot)
    return type(bucket) == "table" and type(bucket[slot]) == "table"
end

local function list_has_resolvable_slot(list, slot)
    if bucket_has_slot(list.template, slot) or bucket_has_slot(list.visible, slot) then return true end
    for _, bucket in pairs(type(list.classes) == "table" and list.classes or {}) do
        if bucket_has_slot(bucket, slot) then return true end
    end
    if type(list.virtual) == "table" and type(list.virtual[slot]) == "table" then return true end
    return false
end

local function category_display_only_reason(cat, slot)
    local slots = type(cat) == "table" and type(cat.display_only_slots) == "table" and cat.display_only_slots or nil
    if not slots then return nil end
    local reason = slots[slot]
    if type(reason) == "string" and trim(reason) ~= "" then return trim(reason) end
    if reason == true then return "explicit display-only slot" end
    return nil
end

local function validate_categories(list_id, list)
    if not validate_array(ctx(list_id), list.categories, "categories", true) then return end
    local cat_names = {}
    for cat_i, cat in ipairs(list.categories) do
        local cat_ctx = ctx(list_id, "category" .. cat_i)
        counts.categories = counts.categories + 1
        if type(cat) ~= "table" then
            err(cat_ctx, "category must be a table")
        else
            for _, key in ipairs(sorted_keys(cat)) do
                if not ALLOWED_CATEGORY[key] then warn(cat_ctx, "unknown category field: " .. tostring(key)) end
            end
            if cat.display_only_slots ~= nil and type(cat.display_only_slots) ~= "table" then
                err(cat_ctx, "display_only_slots must be a table")
            end
            if type(cat.name) ~= "string" or trim(cat.name) == "" then
                err(cat_ctx, "category name must be a non-empty string")
            else
                local key = norm_name(cat.name)
                if cat_names[key] then err(cat_ctx, "duplicate category name: " .. trim(cat.name)) end
                cat_names[key] = true
            end
            if validate_array(cat_ctx, cat.slots, "slots", true) then
                local slot_seen = {}
                for slot_i, slot in ipairs(cat.slots) do
                    counts.category_slot_refs = counts.category_slot_refs + 1
                    if type(slot) ~= "string" or trim(slot) == "" then
                        err(cat_ctx, "slots[" .. slot_i .. "] must be a non-empty string")
                    else
                        local slot_key = trim(slot)
                        if slot_seen[slot_key] then
                            err(cat_ctx, "duplicate slot in category: " .. slot_key)
                        end
                        slot_seen[slot_key] = true
                        if not list_has_resolvable_slot(list, slot_key) and not category_display_only_reason(cat, slot_key) then
                            warn(ctx(list_id, trim(cat.name), slot_key), "category slot has no resolvable row or virtual declaration")
                        end
                    end
                end
            end
            if type(cat.display_only_slots) == "table" then
                local declared = {}
                for _, slot in ipairs(type(cat.slots) == "table" and cat.slots or {}) do declared[slot] = true end
                for slot, reason in pairs(cat.display_only_slots) do
                    if type(slot) ~= "string" or trim(slot) == "" then
                        err(cat_ctx, "display_only_slots key must be a non-empty string")
                    elseif not declared[slot] then
                        err(cat_ctx, "display_only_slots references slot not present in category: " .. tostring(slot))
                    elseif list_has_resolvable_slot(list, slot) then
                        warn(ctx(list_id, trim(cat.name), slot), "display_only_slots entry has a resolvable row and may be stale")
                    end
                    if not (reason == true or (type(reason) == "string" and trim(reason) ~= "")) then
                        err(ctx(list_id, trim(cat.name), tostring(slot)), "display_only_slots reason must be true or a non-empty string")
                    end
                end
            end
        end
    end
end

local function validate_bucket(list_id, scope, bucket)
    if bucket == nil then return end
    if type(bucket) ~= "table" then
        err(ctx(list_id, scope), scope .. " must be a table")
        return
    end
    for _, slot in ipairs(sorted_keys(bucket)) do
        if type(slot) ~= "string" or trim(slot) == "" then
            err(ctx(list_id, scope), "slot key must be a non-empty string")
        else
            validate_row(list_id, scope, slot, bucket[slot])
        end
    end
end

local function validate_virtuals(list_id, list)
    if list.virtual == nil then return end
    if type(list.virtual) ~= "table" then
        err(ctx(list_id, "virtual"), "virtual must be a table")
        return
    end

    local edges = {}
    for _, slot in ipairs(sorted_keys(list.virtual)) do
        local v = list.virtual[slot]
        local ctx_text = ctx(list_id, "virtual", slot)
        counts.virtual_rows = counts.virtual_rows + 1
        if type(v) ~= "table" then
            err(ctx_text, "virtual row must be a table")
        else
            if v.identity_role ~= nil then
                if type(v.identity_role) ~= "string" or trim(v.identity_role) == "" then
                    err(ctx_text, "identity_role must be a non-empty string")
                elseif not RECOGNIZED_VIRTUAL_ROLES[v.identity_role] then
                    err(ctx_text, "unrecognized identity_role: " .. tostring(v.identity_role))
                end
            end
            if v.display ~= nil and (type(v.display) ~= "string" or trim(v.display) == "") then
                err(ctx_text, "display must be a non-empty string")
            end
            if v.note ~= nil and type(v.note) ~= "string" then
                err(ctx_text, "note must be a string")
            end
            if v.source_slot ~= nil then
                if type(v.source_slot) ~= "string" or trim(v.source_slot) == "" then
                    err(ctx_text, "source_slot must be a non-empty string")
                elseif trim(v.source_slot) == slot then
                    err(ctx_text, "virtual row must not point to itself")
                elseif not list_has_resolvable_slot(list, trim(v.source_slot)) then
                    err(ctx_text, "source_slot target missing: " .. trim(v.source_slot))
                else
                    edges[slot] = trim(v.source_slot)
                end
            end
            if slot == "Reward" and trim(v.source_slot) == "" then
                err(ctx_text, "Reward virtual requires source_slot")
            end
            if slot == "Scales" and trim(v.source_slot) == "" then
                err(ctx_text, "Scales virtual requires source_slot")
            end
            if slot == "2.75" then
                if v.identity_role ~= "class_epic_2_75" then
                    err(ctx_text, "2.75 virtual must use identity_role class_epic_2_75")
                end
                if type(v.per_class) ~= "table" then
                    err(ctx_text, "2.75 virtual requires per_class table")
                else
                    for _, class_name in ipairs(CLASSES) do
                        local rec = v.per_class[class_name]
                        if not rec then
                            err(ctx_text, "2.75 missing class identity: " .. class_name)
                        else
                            validate_identity_record(ctx_text .. "/" .. class_name, rec, "per_class")
                        end
                    end
                    for class_name in pairs(v.per_class) do
                        if not CLASS_SET[class_name] then err(ctx_text, "2.75 has unknown class: " .. tostring(class_name)) end
                    end
                end
            end
        end
    end

    for from, to in pairs(edges) do
        local seen = { [from] = true }
        local cursor = to
        while cursor and type(list.virtual[cursor]) == "table" do
            if seen[cursor] then
                err(ctx(list_id, "virtual", from), "virtual source cycle detected through " .. cursor)
                break
            end
            seen[cursor] = true
            cursor = list.virtual[cursor].source_slot
        end
    end
end

local function validate_don_expectations(catalog)
    local don = catalog.lists and catalog.lists.don
    if type(don) ~= "table" then return end
    local virtual = type(don.virtual) == "table" and don.virtual or {}
    if not virtual.Scales then
        err("don/virtual/Scales", "DoN Scales virtual row is required")
    elseif virtual.Scales.source_slot ~= "Misc4" then
        err("don/virtual/Scales/source_slot", "DoN Scales must source from Misc4")
    end
    if not virtual.Reward then
        err("don/virtual/Reward", "DoN Reward virtual row is required")
    elseif virtual.Reward.source_slot ~= "Shadow" then
        err("don/virtual/Reward/source_slot", "DoN Reward must source from Shadow")
    end
    if not virtual["2.75"] then
        err("don/virtual/2.75", "DoN 2.75 virtual row is required")
    end

    for _, class_name in ipairs(CLASSES) do
        local row = don.classes and don.classes[class_name] and don.classes[class_name].Shadow
        local row_ctx = ctx("don", class_name, "Shadow")
        if type(row) ~= "table" then
            err(row_ctx, "DoN Shadow row is required for every canonical class")
        elseif type(row.identities) ~= "table" then
            err(row_ctx, "DoN Shadow row requires explicit paired identities")
        end
    end
end

local function validate_amv_expectations(catalog)
    local anguish = catalog.lists and catalog.lists.anguish
    if type(anguish) ~= "table" or type(anguish.classes) ~= "table" then return end
    local found = 0
    for class_name, bucket in pairs(anguish.classes) do
        for slot, row in pairs(type(bucket) == "table" and bucket or {}) do
            if type(row) == "table" and norm_name(row.item) == norm_name("Warbeads of the Magus") then
                found = found + 1
                local row_ctx = ctx("anguish", class_name, slot, "source")
                if row.source ~= "AMV" then
                    warn(row_ctx, "Warbeads of the Magus expected source AMV, got " .. tostring(row.source))
                end
            end
        end
    end
    if found == 0 then warn("anguish/Warbeads/source", "no Warbeads of the Magus rows found for AMV validation") end
end

local function validate_groups_and_targets(catalog)
    local group_lists = {}
    if validate_array("catalog/groups", catalog.groups, "groups", true) then
        counts.groups = #catalog.groups
        local group_names = {}
        for gi, group in ipairs(catalog.groups) do
            local group_ctx = "groups/" .. gi
            if type(group) ~= "table" then
                err(group_ctx, "group must be a table")
            else
                local name = trim(group.name)
                if type(group.name) ~= "string" or name == "" then
                    err(group_ctx, "group name must be a non-empty string")
                elseif group_names[name] then
                    err(group_ctx, "duplicate group name: " .. name)
                end
                group_names[name] = true
                group_lists[name] = group.lists
                if validate_array(group_ctx, group.lists, "lists", true) then
                    local list_ids = {}
                    for li, rec in ipairs(group.lists) do
                        local list_ctx = group_ctx .. "/lists/" .. li
                        if type(rec) ~= "table" then
                            err(list_ctx, "group list entry must be a table")
                        else
                            if type(rec.id) ~= "string" or trim(rec.id) == "" then
                                err(list_ctx, "group list id must be a non-empty string")
                            elseif list_ids[rec.id] then
                                err(list_ctx, "duplicate list id in group: " .. rec.id)
                            end
                            list_ids[rec.id] = true
                            if type(rec.name) ~= "string" or trim(rec.name) == "" then
                                err(list_ctx, "group list name must be a non-empty string")
                            end
                        end
                    end
                end
            end
        end
    end
    return group_lists
end

local function validate_group_index_target(group_lists, record, record_ctx)
    if type(record) ~= "table" then
        err(record_ctx, "target must be a table")
        return
    end
    local group = trim(record.group)
    local index = tonumber(record.index)
    if group == "" then err(record_ctx, "target group must be non-empty") end
    if type(record.index) ~= "number" or not index or index < 1 or index % 1 ~= 0 then
        err(record_ctx, "target index must be a positive integer")
        return
    end
    local lists = group_lists[group]
    if not lists then
        err(record_ctx, "target group does not exist: " .. group)
    elseif not lists[index] then
        err(record_ctx, "target index does not exist in group " .. group .. ": " .. tostring(index))
    end
end

local function validate_defaults_and_zones(catalog, group_lists)
    validate_group_index_target(group_lists, catalog.default, "default")
    if type(catalog.zone_map) ~= "table" then
        err("zone_map", "zone_map table is required")
        return
    end
    local zones = {}
    for zone, target in pairs(catalog.zone_map) do
        counts.zone_map_entries = counts.zone_map_entries + 1
        if type(zone) ~= "string" or trim(zone) == "" then
            err("zone_map", "zone key must be a non-empty string")
        else
            local key = norm_name(zone)
            if zones[key] then warn("zone_map/" .. zone, "duplicate/conflicting normalized zone mapping") end
            zones[key] = true
            validate_group_index_target(group_lists, target, "zone_map/" .. zone)
        end
    end
end

local function validate_lists(catalog)
    if type(catalog.lists) ~= "table" then
        err("catalog/lists", "lists table is required")
        return
    end
    local list_ids = {}
    for _, list_id in ipairs(sorted_keys(catalog.lists)) do
        local list = catalog.lists[list_id]
        counts.lists = counts.lists + 1
        if type(list_id) ~= "string" or trim(list_id) == "" then
            err("lists", "list key must be a non-empty string")
        end
        if list_ids[list_id] then err(ctx(list_id), "duplicate list identity") end
        list_ids[list_id] = true
        if type(list) ~= "table" then
            err(ctx(list_id), "list must be a table")
        else
            for _, key in ipairs(sorted_keys(list)) do
                if not ALLOWED_LIST[key] then warn(ctx(list_id), "unknown list field: " .. tostring(key)) end
            end
            if type(list.id) ~= "string" or trim(list.id) == "" then
                err(ctx(list_id, "id"), "list id must be a non-empty string")
            elseif list.id ~= list_id then
                err(ctx(list_id, "id"), "list id must match list key")
            end
            if type(list.name) ~= "string" or trim(list.name) == "" then
                err(ctx(list_id, "name"), "list name must be a non-empty string")
            end
            validate_categories(list_id, list)
            validate_bucket(list_id, "template", list.template)
            validate_bucket(list_id, "visible", list.visible)
            if list.classes ~= nil then
                if type(list.classes) ~= "table" then
                    err(ctx(list_id, "classes"), "classes must be a table")
                else
                    for _, class_name in ipairs(sorted_keys(list.classes)) do
                        counts.class_scopes = counts.class_scopes + 1
                        if not CLASS_SET[class_name] then
                            err(ctx(list_id, class_name), "unknown class name")
                        end
                        validate_bucket(list_id, class_name, list.classes[class_name])
                    end
                end
            end
            validate_virtuals(list_id, list)
        end
    end
end

local function validate_top_schema(catalog)
    for _, key in ipairs(sorted_keys(catalog)) do
        if not ALLOWED_TOP[key] then warn("catalog", "unknown top-level field: " .. tostring(key)) end
    end
    if catalog.schema ~= EXPECTED_SCHEMA then
        err("catalog/schema", "expected schema " .. EXPECTED_SCHEMA .. ", got " .. tostring(catalog.schema))
    end
    if type(catalog.source_owner) ~= "string" or trim(catalog.source_owner) == "" then
        err("catalog/source_owner", "source_owner must be a non-empty string")
    end
    if type(catalog.baseline) ~= "table" then
        err("catalog/baseline", "baseline metadata table is required")
    elseif type(catalog.baseline.content_hash) ~= "string" or trim(catalog.baseline.content_hash) == "" then
        err("catalog/baseline/content_hash", "baseline content_hash must be a non-empty string")
    end
    if type(catalog.builder) ~= "table" then
        err("catalog/builder", "builder metadata table is required")
    elseif type(catalog.builder.future_builder) ~= "string" or trim(catalog.builder.future_builder) == "" then
        err("catalog/builder/future_builder", "builder.future_builder must be a non-empty string")
    end
end

local function validate_global_aliases()
    for alias_key, refs in pairs(alias_index) do
        local sigs, items, contexts, lists = {}, {}, {}, {}
        for _, ref in ipairs(refs) do
            sigs[id_signature(ref.ids)] = true
            items[norm_name(ref.item)] = true
            contexts[#contexts + 1] = ctx(ref.list_id, ref.scope, ref.slot)
            lists[ref.list_id] = true
        end
        local sig_count, item_count = 0, 0
        for _ in pairs(sigs) do sig_count = sig_count + 1 end
        for item_key in pairs(items) do if item_key ~= "" then item_count = item_count + 1 end end
        local list_count = 0
        for _ in pairs(lists) do list_count = list_count + 1 end
        if sig_count > 1 and item_count > 1 and list_count > 1 then
            table.sort(contexts)
            warn("aliases/" .. alias_key, "alias maps to different item/id contexts: " .. table.concat(contexts, ", "))
        end
    end
end

local function validate_global_ids()
    for id, refs in pairs(id_index) do
        local items, contexts, lists = {}, {}, {}
        for _, ref in ipairs(refs) do
            if trim(ref.item) ~= "" then items[norm_name(ref.item)] = true end
            contexts[#contexts + 1] = ctx(ref.list_id, ref.scope, ref.slot) .. " role=" .. tostring(ref.role)
            lists[ref.list_id] = true
        end
        local item_count = 0
        for _ in pairs(items) do item_count = item_count + 1 end
        local list_count = 0
        for _ in pairs(lists) do list_count = list_count + 1 end
        if item_count > 1 and list_count > 1 and #refs <= 4 then
            table.sort(contexts)
            warn("ids/" .. id, "id maps to conflicting canonical names: " .. table.concat(contexts, ", "))
        end
    end
end

local catalog = load_table(source_path)
validate_top_schema(catalog)
local group_lists = validate_groups_and_targets(catalog)
validate_lists(catalog)
validate_defaults_and_zones(catalog, group_lists)
validate_don_expectations(catalog)
validate_amv_expectations(catalog)
validate_global_aliases()
validate_global_ids()

info("counts", string.format(
    "groups=%d lists=%d categories=%d category_slot_refs=%d classes_supported=%d class_scopes=%d ordinary_rows=%d virtual_rows=%d paired_identity_blocks=%d aliases=%d ids=%d zone_map_entries=%d",
    counts.groups,
    counts.lists,
    counts.categories,
    counts.category_slot_refs,
    counts.classes_supported,
    counts.class_scopes,
    counts.ordinary_rows,
    counts.virtual_rows,
    counts.paired_identity_blocks,
    counts.aliases,
    counts.ids,
    counts.zone_map_entries
))

local function print_issues(severity)
    table.sort(issues[severity], function(a, b)
        local ac = tostring(a.ctx or "")
        local bc = tostring(b.ctx or "")
        if ac == bc then return tostring(a.message or "") < tostring(b.message or "") end
        return ac < bc
    end)
    for _, rec in ipairs(issues[severity]) do
        io.stdout:write(string.format("%s [%s]\n%s\n", severity, rec.ctx, rec.message))
    end
end

local error_count = #issues.ERROR
local warning_count = #issues.WARNING
local info_count = #issues.INFO

if error_count == 0 then
    io.stdout:write("TurboGear BiS validation: PASS\n")
else
    io.stdout:write("TurboGear BiS validation: FAIL\n")
end
io.stdout:write(string.format("errors=%d warnings=%d info=%d\n", error_count, warning_count, info_count))
print_issues("ERROR")
print_issues("WARNING")
print_issues("INFO")

os.exit(error_count == 0 and 0 or 1)
