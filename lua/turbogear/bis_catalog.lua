-- TurboGear/bis_catalog.lua
-- Runtime resolver for built-in/catalog BiS data. Catalog rows are class-aware:
-- each character column resolves the selected list against that character's class.

local bis = require('bis')
local mq = require('mq')
local cfg = require('config')
local Settings, SaveSettings = cfg.Settings, cfg.SaveSettings
local SharedSettings, SaveSharedSettings = cfg.SharedSettings, cfg.SaveSharedSettings

local M = {}

-- Lazy catalog load (P2): the generated catalog (catalogs/lazbis.lua, ~34k
-- lines) is only require()'d on first field access, so pure viewers and bg
-- publishers that never open BiS or evaluate announce-needs don't pay the parse
-- + resident-memory cost. Access goes through a proxy whose __index materializes
-- the real table once and then forwards field reads (catalog.groups / .lists /
-- .default / .zone_map). No code iterates the top-level table, so a proxy is safe.
local _catalog_real = nil
local function load_catalog()
    if _catalog_real == nil then
        local ok, t = pcall(require, 'catalogs.lazbis')
        _catalog_real = (ok and type(t) == "table") and t or { groups = {}, lists = {} }
    end
    return _catalog_real
end
local catalog = setmetatable({}, {
    __index = function(_, k) return load_catalog()[k] end,
})
-- Observability / warm hooks: catalog_loaded() reports whether the big table is
-- resident (used by perfdiag); warm_catalog() forces the load off the hot path.
function M.catalog_loaded() return _catalog_real ~= nil end
function M.warm_catalog() load_catalog(); return true end

-- Forward-declared; used by announce toggles before the announce index block below.
local static_catalog = {
    sig = nil,
    by_id = {},
    by_name = {},
    list_count = 0,
    catalog_entries = 0,
}
local direct_catalog = {
    sig = nil,
    by_id = {},
    by_name = {},
    list_count = 0,
    catalog_entries = 0,
}
local direct_catalogs = {}
local direct_class_catalogs = {}   -- class-shared direct catalogs (no user lists)
local static_sig_cache = {}        -- short-TTL memo for catalog_static_sig
local direct_async = {}            -- in-progress async direct-catalog builds
local catalog_build = nil

local function trim(s)
    return tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function class_key(class_name)
    class_name = trim(class_name)
    if class_name == "Shadowknight" then return "Shadow Knight" end
    return class_name
end

local function tier_rank(text)
    text = tostring(text or ""):lower()
    if text:find("final", 1, true) or text:find("4th ", 1, true) then return 4 end
    if text:find("tier iii", 1, true) or text:find("3rd ", 1, true) then return 3 end
    if text:find("tier ii", 1, true) or text:find("2nd ", 1, true) then return 2 end
    if text:find("tier i", 1, true) or text:find("1st ", 1, true) then return 1 end
    if text:find("base ", 1, true) then return 0 end
    return nil
end

local function fungal_family_rank(text)
    local s = tostring(text or "")
    local elem = s:match("^(%S+) Slime of Suffering")
        or s:match("^(%S+) Fungus of Suffering")
        or s:match("^%d%a%a (%S+) Fungus of Suffering")
        or s:match("^Base (%S+) Slime of Suffering")
    if elem then
        local r = tier_rank(s)
        if s:find("Slime of Suffering", 1, true) then r = 0 end
        return "slime:" .. elem:lower(), r or 4
    end
    local bloom = s:match("^Noxious Bloom of (.-)%s*%(")
        or s:match("^Noxious Bloom of (.+)$")
        or s:match("^Fungal Bloom of (.-)%s*%-")
        or s:match("^Fungal Bloom of (.+)$")
        or s:match("^%d%a%a Fungal Bloom of (.-)%s*%(")
        or s:match("^Base Noxious Bloom of (.-)%s*%(")
    if bloom and bloom ~= "" then
        bloom = trim(bloom)
        local r = tier_rank(s)
        if s:find("Noxious Bloom of", 1, true) then r = 0 end
        return "bloom:" .. bloom:lower(), r or 4
    end
    return nil, nil
end

-- Expansion memos. resolve_entry's fungal/Jonas chain expansion used to
-- re-normalize and re-classify every bucket entry PER SLOT (quadratic regex
-- work): building a class's direct catalog cost multiple SECONDS on the game
-- thread. These caches make the repeated work O(1) after first sight.
-- norm_entry_cached results are READ-ONLY - never mutate them (resolve_entry
-- keeps building its own fresh normalized copy for the returned entry).
local norm_entry_cache = setmetatable({}, { __mode = "k" })
local function norm_entry_cached(raw)
    if type(raw) ~= "table" then return bis.normalize_entry(raw) end
    local v = norm_entry_cache[raw]
    if not v then
        v = bis.normalize_entry(raw)
        norm_entry_cache[raw] = v
    end
    return v
end

local family_rank_cache = {}
-- (fungal_family_rank is defined above this cache)
local function fungal_family_rank_cached(text)
    text = tostring(text or "")
    local hit = family_rank_cache[text]
    if hit == nil then
        local fam, rank = fungal_family_rank(text)
        hit = { fam or false, rank }
        family_rank_cache[text] = hit
    end
    if hit[1] == false then return nil, nil end
    return hit[1], hit[2]
end

-- add_ids/add_names accept an optional persistent `seen` set. Without it they
-- rebuild the dedupe set from the accumulated list on EVERY call - O(n^2)
-- with a regex-trim per element. On Jonas/fungal chain expansion (80+ aliases
-- per entry) that quadratic was the real cost behind the 7-10s direct catalog
-- builds, the 3-minute static catalog warm, and the 26s chat freezes.
-- Expansions seed a seen-set once and thread it through every call.
local function seed_id_seen(dst)
    local seen = {}
    for _, id in ipairs(dst.ids or {}) do seen[tonumber(id)] = true end
    return seen
end

local function seed_name_seen(dst)
    local seen = {}
    for _, name in ipairs(dst.names or {}) do seen[trim(name):lower()] = true end
    return seen
end

local function add_ids(dst, ids, seen)
    dst.ids = dst.ids or {}
    seen = seen or seed_id_seen(dst)
    for _, id in ipairs(ids or {}) do
        id = tonumber(id)
        if id and id > 0 and not seen[id] then
            seen[id] = true
            dst.ids[#dst.ids+1] = id
        end
    end
end

local function add_names(dst, names, seen)
    dst.names = dst.names or {}
    seen = seen or seed_name_seen(dst)
    for _, name in ipairs(names or {}) do
        name = trim(name)
        local k = name:lower()
        if name ~= "" and not seen[k] then
            seen[k] = true
            dst.names[#dst.names+1] = name
        end
    end
end

local function expand_fungal_chain(list, class_bucket, out)
    local family, rank = fungal_family_rank_cached(out.item)
    if not family then family, rank = fungal_family_rank_cached(out.slot) end
    if not family or rank == nil then return out end
    local id_seen, name_seen = seed_id_seen(out), seed_name_seen(out)
    for slot, raw in pairs(class_bucket or {}) do
        local e = norm_entry_cached(raw)
        local efam, erank = fungal_family_rank_cached(e.item)
        if not efam then efam, erank = fungal_family_rank_cached(slot) end
        if efam == family and erank and erank >= rank then
            add_ids(out, e.ids, id_seen)
            add_names(out, e.names, name_seen)
            add_names(out, { e.item }, name_seen)
        end
    end
    return out
end

local JONAS_PREFIX = "Jonas Dagmire's "

local function add_jonas_aliases_for_name(out, name, name_seen)
    name = trim(name)
    if name == "" then return end
    local lower = name:lower()
    if lower:find("^jonas dagmire's ", 1, false) then
        local bare = trim(name:gsub("^Jonas Dagmire's%s+", ""))
        if bare ~= "" then add_names(out, { bare }, name_seen) end
    else
        add_names(out, { JONAS_PREFIX .. name }, name_seen)
    end
end

local function add_jonas_aliases(out, names, name_seen)
    for _, name in ipairs(names or {}) do
        add_jonas_aliases_for_name(out, name, name_seen)
    end
end

local function jonas_completion_slot(slot)
    slot = tostring(slot or "")
    return slot:match("^Tier %d+ Complete$") ~= nil
        or slot == "Middle Finger (Mayong)"
end

local JONAS_COMPLETION_IDS = {
    ["Tier 1 Complete"] = 33166,
    ["Tier 2 Complete"] = 33167,
    ["Tier 3 Complete"] = 33168,
    ["Tier 4 Complete"] = 33169,
    ["Tier 5 Complete"] = 33170,
    ["Middle Finger (Mayong)"] = 33171,
}

local function ids_include(ids, needle)
    needle = tonumber(needle)
    if not needle then return false end
    for _, id in ipairs(ids or {}) do
        if tonumber(id) == needle then return true end
    end
    return false
end

local function expand_jonas_hand_chain(list, class_bucket, out)
    local name_seen = seed_name_seen(out)
    add_jonas_aliases(out, out.names, name_seen)
    add_jonas_aliases_for_name(out, out.item, name_seen)

    if not jonas_completion_slot(out.slot) then return out end
    if #(out.ids or {}) == 0 then return out end

    local visited = {}
    local function scan_bucket(bucket)
        for slot, raw in pairs(bucket or {}) do
            if jonas_completion_slot(slot) and not visited[slot] then
                visited[slot] = true
                local e = norm_entry_cached(raw) -- read-only use
                if ids_include(out.ids, JONAS_COMPLETION_IDS[slot]) then
                    add_names(out, e.names, name_seen)
                    add_names(out, { e.item }, name_seen)
                    add_jonas_aliases(out, e.names, name_seen)
                    add_jonas_aliases_for_name(out, e.item, name_seen)
                end
            end
        end
    end
    scan_bucket(list and list.template or nil)
    scan_bucket(class_bucket)
    scan_bucket(list and list.visible or nil)
    if tostring(out.slot or ""):match("^Tier [1-5] Complete$") then
        local final = (list and list.template and list.template["Tier 6 Complete"])
            or (class_bucket and class_bucket["Tier 6 Complete"])
            or (list and list.visible and list.visible["Tier 6 Complete"])
        if final then
            local e = norm_entry_cached(final) -- read-only use
            add_names(out, e.names, name_seen)
            add_names(out, { e.item }, name_seen)
            add_jonas_aliases(out, e.names, name_seen)
            add_jonas_aliases_for_name(out, e.item, name_seen)
        end
    end
    return out
end

local function strict_first_id_for_bag_list(out)
    if type(out.ids) == "table" and #out.ids > 1 then
        out.ids = { out.ids[1] }
    end
    return out
end

function M.groups()
    return catalog.groups or {}
end

function M.default_list_id()
    local d = catalog.default or {}
    local group = d.group
    local index = d.index
    if group and index and catalog.groups then
        for _, g in ipairs(catalog.groups) do
            if g.name == group and g.lists and g.lists[index] then return g.lists[index].id end
        end
    end
    local g = catalog.groups and catalog.groups[1]
    return g and g.lists and g.lists[1] and g.lists[1].id or ""
end

function M.list(id)
    id = id or M.default_list_id()
    return catalog.lists and catalog.lists[id] or nil
end

function M.list_label(id)
    local l = M.list(id)
    return l and l.name or "No catalog"
end

-- UI tab order/labels (does not change generated catalog data).
local UI_LIST_BUTTONS = {
    { id = "preanguish", label = "Pre-Raid", group = "Group Best In Slot" },
    { id = "anguish", label = "Anguish", group = "Raid Best In Slot" },
    { id = "fuku", label = "FUKU", group = "Raid Best In Slot" },
    { id = "dsk", label = "DSK", group = "Raid Best In Slot" },
    { id = "sebilis", label = "Sebilis", group = "Raid Best In Slot" },
    { id = "veksar", label = "Veksar", group = "Raid Best In Slot" },
    { id = "llhcitems", label = "Lower HC", group = "Other Checklists" },
    { id = "hcitems", label = "Higher HC", group = "Other Checklists" },
    { id = "focusitems", label = "Focus BIS", group = "Other Checklists" },
    { id = "jonas", label = "Hand", group = "Other Checklists" },
    { id = "fungal", label = "Fungal", group = "Raid Best In Slot" },
    { id = "questitems", label = "Quest", group = "Other Checklists" },
    { id = "nightveil", label = "Nightveil", group = "Other Checklists" },
    { id = "vendoritems", label = "Vendor", group = "Other Checklists" },
    { id = "bagitems", label = "Bags", group = "Other Checklists" },
}

function M.is_special_list(_id)
    return false
end

function M.special_list_label(id)
    return tostring(id or "")
end

local function resolve_list_spec(spec)
    if not M.list(spec.id) then return nil end
    local group_obj = nil
    for _, g in ipairs(M.groups()) do
        if g.name == spec.group then
            group_obj = g
            break
        end
    end
    return {
        id = spec.id,
        label = spec.label,
        group = group_obj,
        rec = { id = spec.id, name = spec.label },
    }
end

function M.list_hidden(id)
    local hidden = Settings.bisHiddenLists
    if type(hidden) ~= "table" then return false end
    return hidden[tostring(id or "")] == true
end

function M.list_announce_enabled(id)
    id = tostring(id or "")
    if id == "" or M.is_special_list(id) then return false end
    local disabled = SharedSettings.bisAnnounceDisabledLists
    if type(disabled) ~= "table" then return true end
    return disabled[id] ~= true
end

function M.set_list_announce_enabled(id, enabled)
    id = tostring(id or "")
    if id == "" then return end
    SharedSettings.bisAnnounceDisabledLists = type(SharedSettings.bisAnnounceDisabledLists) == "table"
        and SharedSettings.bisAnnounceDisabledLists or {}
    if enabled then
        SharedSettings.bisAnnounceDisabledLists[id] = nil
    else
        SharedSettings.bisAnnounceDisabledLists[id] = true
    end
    if SaveSharedSettings then SaveSharedSettings() end
    static_catalog.sig = nil
    direct_catalog.sig = nil
    direct_catalogs = {}
    direct_class_catalogs = {}
    static_sig_cache = {}
    direct_async = {}
    catalog_build = nil
    pcall(function() require('announcer').invalidate() end)
end

function M.set_list_hidden(id, hidden)
    id = tostring(id or "")
    if id == "" then return end
    Settings.bisHiddenLists = type(Settings.bisHiddenLists) == "table" and Settings.bisHiddenLists or {}
    if hidden then
        Settings.bisHiddenLists[id] = true
    else
        Settings.bisHiddenLists[id] = nil
    end
    if SaveSettings then SaveSettings() end
end

function M.ui_list_specs()
    local out = {}
    for _, spec in ipairs(UI_LIST_BUTTONS) do
        local resolved = resolve_list_spec(spec)
        if resolved then out[#out + 1] = resolved end
    end
    return out
end

function M.ui_list_buttons()
    local out = {}
    for _, spec in ipairs(UI_LIST_BUTTONS) do
        if not M.list_hidden(spec.id) then
            local resolved = resolve_list_spec(spec)
            if resolved then out[#out + 1] = resolved end
        end
    end
    return out
end

function M.first_visible_list_button()
    for _, spec in ipairs(UI_LIST_BUTTONS) do
        if not M.list_hidden(spec.id) then
            local resolved = resolve_list_spec(spec)
            if resolved then return resolved end
        end
    end
    return nil
end

function M.resolve_entry(list_id, class_name, slot)
    local list = M.list(list_id)
    if not list then return nil end
    local class_bucket = list.classes and list.classes[class_key(class_name)] or nil
    local entry = class_bucket and class_bucket[slot]
    if not entry and list.template then entry = list.template[slot] end
    if not entry and list.visible then entry = list.visible[slot] end
    if not entry then return nil end
    local out = bis.normalize_entry(entry)
    out.slot = slot
    out.group = out.group ~= "" and out.group or ""
    out.source = entry.source
    expand_fungal_chain(list, class_bucket or list.template or list.visible, out)
    if list_id == "jonas" then
        expand_jonas_hand_chain(list, class_bucket, out)
    elseif list_id == "bagitems" then
        strict_first_id_for_bag_list(out)
    end
    return out
end

function M.rows_for_snap(list_id, snap)
    local list = M.list(list_id)
    local rows = {}
    if not list or not snap then return rows end
    for _, cat in ipairs(list.categories or {}) do
        rows[#rows+1] = { category = cat.name, header = true }
        for _, slot in ipairs(cat.slots or {}) do
            local entry = M.resolve_entry(list_id, snap.class, slot)
            if entry then
                entry.group = cat.name
                local eval = bis.evaluate_entry(entry, snap)
                eval.category = cat.name
                rows[#rows+1] = eval
            else
                rows[#rows+1] = { category = cat.name, slot = slot, empty = true }
            end
        end
    end
    return rows
end

function M.reference_rows(list_id)
    local list = M.list(list_id)
    local rows = {}
    if not list then return rows end
    for _, cat in ipairs(list.categories or {}) do
        rows[#rows+1] = { category = cat.name, header = true }
        for _, slot in ipairs(cat.slots or {}) do
            rows[#rows+1] = { category = cat.name, slot = slot }
        end
    end
    return rows
end

function M.evaluate_slot(list_id, snap, slot, category)
    local entry = M.resolve_entry(list_id, snap and snap.class, slot)
    if not entry then return { category = category, slot = slot, empty = true } end
    entry.group = category or entry.group
    local row = bis.evaluate_entry(entry, snap)
    row.category = category
    return row
end

function M.find_link_need(snap, item_name, item_id)
    return M.find_announce_need(snap, item_name, item_id)
end

-- Announce path: static catalog reverse index (LazBiS-style) + O(1) snapshot ownership
-- check per linked item. Avoids pre-evaluating hundreds of missing rows on every loot link.

local BUILD_BUDGET_MS = 8

local function norm_item_key(name)
    name = trim(name):lower()
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    return name
end

local catalog_search = { sig = nil, rows = nil }
local CATALOG_SEARCH_SIG = "all_lists_v1"

local function catalog_class_abbrev(class_name)
    class_name = trim(class_name)
    if class_name == "" then return nil end
    local views = require('views')
    return views.class_abbrev(class_name)
end

local function ensure_catalog_search_index()
    if catalog_search.sig == CATALOG_SEARCH_SIG and catalog_search.rows then
        return catalog_search.rows
    end

    local rows = {}
    local merge = {}
    for _, spec in ipairs(UI_LIST_BUTTONS) do
        local list = M.list(spec.id)
        if not list then goto continue_list end

        local class_names = {}
        if type(list.classes) == "table" then
            for cn, _ in pairs(list.classes) do
                class_names[#class_names + 1] = cn
            end
        end
        table.sort(class_names)
        if #class_names == 0 then class_names = { "" } end

        local slots = {}
        for _, cat in ipairs(list.categories or {}) do
            for _, slot in ipairs(cat.slots or {}) do
                slots[slot] = true
            end
        end

        for _, class_name in ipairs(class_names) do
            for slot in pairs(slots) do
                local entry = M.resolve_entry(spec.id, class_name, slot)
                if entry then
                    local names = entry.names or { entry.item }
                    for _, raw_name in ipairs(names) do
                        local name = trim(raw_name)
                        if name ~= "" then
                            local merge_key = spec.id .. "\31" .. slot .. "\31" .. norm_item_key(name)
                            local row = merge[merge_key]
                            if not row then
                                row = {
                                    name = name,
                                    name_lower = name:lower(),
                                    list_id = spec.id,
                                    list_label = spec.label,
                                    slot = slot,
                                    class_set = {},
                                    id = nil,
                                }
                                merge[merge_key] = row
                                rows[#rows + 1] = row
                            end
                            local abbrev = catalog_class_abbrev(class_name)
                            if abbrev then row.class_set[abbrev] = true end
                            for _, id in ipairs(entry.ids or {}) do
                                id = tonumber(id)
                                if id and id > 0 and not row.id then row.id = id end
                            end
                        end
                    end
                end
            end
        end
        ::continue_list::
    end

    for _, row in ipairs(rows) do
        local classes = {}
        for abbrev in pairs(row.class_set or {}) do
            classes[#classes + 1] = abbrev
        end
        table.sort(classes)
        row.classes = table.concat(classes, ", ")
        row.class_set = nil
    end

    table.sort(rows, function(a, b)
        if a.name_lower == b.name_lower then
            return tostring(a.list_label) < tostring(b.list_label)
        end
        return a.name_lower < b.name_lower
    end)

    catalog_search = { sig = CATALOG_SEARCH_SIG, rows = rows }
    return rows
end

function M.search_items(needle, limit)
    needle = trim(needle):lower()
    if needle == "" then return {} end
    local rows = ensure_catalog_search_index()
    limit = tonumber(limit) or 40
    local out = {}
    for _, row in ipairs(rows) do
        if #out >= limit then break end
        if row.name_lower:find(needle, 1, true) then
            out[#out + 1] = row
        end
    end
    return out
end

function M.all_catalog_list_ids()
    local out, seen = {}, {}
    for _, g in ipairs(M.groups()) do
        for _, rec in ipairs(g.lists or {}) do
            local id = trim(rec.id)
            if id ~= "" and not seen[id] and M.list(id) then
                seen[id] = true
                out[#out + 1] = id
            end
        end
    end
    return out
end

function M.lists_for_announce()
    local out = {}
    for _, spec in ipairs(UI_LIST_BUTTONS) do
        if M.list(spec.id) and M.list_announce_enabled(spec.id) then
            out[#out + 1] = { kind = "catalog", id = spec.id }
        end
    end
    if #out > 0 then return out end
    local d = M.default_list_id()
    if d ~= "" and M.list_announce_enabled(d) then
        return { { kind = "catalog", id = d } }
    end
    return out
end

local function norm_owner(s)
    return trim(s):lower()
end

local function user_list_applies(list, class_name, owner_name)
    if not list then return false end
    local lc = class_key(class_name or "")
    local lo = norm_owner(owner_name or "")
    local list_class = class_key(list.class or "")
    local list_owner = norm_owner(list.owner or "")
    if list_owner ~= "" and lo ~= "" and list_owner == lo then return true end
    if list_class ~= "" and lc ~= "" and list_class == lc then return true end
    if list_class == "" and list_owner == "" then return true end
    return false
end

local function user_lists_for_announce(class_name, owner_name)
    bis.load_all()
    local out = {}
    for _, rec in ipairs(bis.list_names()) do
        if M.list_announce_enabled(rec.id) and user_list_applies(rec.list, class_name, owner_name) then
            out[#out + 1] = { kind = "user", id = rec.id }
        end
    end
    return out
end

local function announce_settings_sig()
    local disabled = SharedSettings.bisAnnounceDisabledLists or {}
    local parts = {}
    for k, v in pairs(disabled) do
        if v then parts[#parts + 1] = tostring(k) end
    end
    table.sort(parts)
    return table.concat(parts, ",")
end

function M.announce_list_specs()
    local specs = {}
    for _, spec in ipairs(M.ui_list_specs()) do
        if not spec.special and M.list(spec.id) then
            specs[#specs + 1] = { id = spec.id, label = spec.label }
        end
    end
    bis.load_all()
    for _, rec in ipairs(bis.list_names()) do
        specs[#specs + 1] = { id = rec.id, label = rec.name, user = true }
    end
    return specs
end

-- LazBiS scans the current zone list first; fall back to raid BiS lists for line text.
function M.list_ids_for_line_scan()
    local zm = catalog.zone_map
    if zm then
        local mq = require('mq')
        local zone = mq.TLO.Zone.ShortName()
        local hit = zone and zm[zone]
        if hit and hit.group and hit.index and catalog.groups then
            for _, g in ipairs(catalog.groups) do
                if g.name == hit.group and g.lists and g.lists[hit.index] then
                    local id = trim(g.lists[hit.index].id)
                    if id ~= "" and M.list(id) then return { id } end
                end
            end
        end
    end
    local out = {}
    for _, g in ipairs(catalog.groups or {}) do
        if g.name == "Raid Best In Slot" then
            for _, rec in ipairs(g.lists or {}) do
                local id = trim(rec.id)
                if id ~= "" and M.list(id) then out[#out + 1] = id end
            end
        end
    end
    if #out > 0 then return out end
    return M.lists_for_announce()
end

-- catalog_static_sig is queried every announcer tick (readiness checks) and
-- per character during index scans; computing it walks the announce lists and
-- user-list manifest each time. Memoize per (class, owner) with a short TTL -
-- list toggles invalidate caches explicitly anyway. (static_sig_cache is
-- declared at the top of the file so settings toggles can reset it.)
local STATIC_SIG_TTL_S = 2.0

local function catalog_static_sig_uncached(class_name, owner_name)
    local list_parts = {}
    for _, ref in ipairs(M.lists_for_announce()) do
        list_parts[#list_parts + 1] = tostring(ref.id or "")
    end
    for _, ref in ipairs(user_lists_for_announce(class_name, owner_name)) do
        list_parts[#list_parts + 1] = "u:" .. tostring(ref.id or "")
    end
    return table.concat({
        tostring(class_name or ""),
        tostring(owner_name or ""),
        announce_settings_sig(),
        table.concat(list_parts, ","),
    }, "\31")
end

local function catalog_static_sig(class_name, owner_name)
    local key = tostring(class_name or "") .. "\31" .. tostring(owner_name or "")
    local now = os.clock()
    local hit = static_sig_cache[key]
    if hit and (now - hit.at) < STATIC_SIG_TTL_S then
        return hit.sig
    end
    local sig = catalog_static_sig_uncached(class_name, owner_name)
    static_sig_cache[key] = { sig = sig, at = now }
    return sig
end

local function add_catalog_entry(idx, list_id, list_name, entry, display_name)
    local rec = {
        list_id = list_id,
        list_name = list_name,
        entry = entry,
        item_name = display_name,
    }
    local key = norm_item_key(display_name)
    if key ~= "" then
        idx.by_name[key] = idx.by_name[key] or {}
        idx.by_name[key][#idx.by_name[key] + 1] = rec
    end
    for _, id in ipairs(entry.ids or {}) do
        id = tonumber(id)
        if id and id > 0 then
            idx.by_id[id] = idx.by_id[id] or {}
            idx.by_id[id][#idx.by_id[id] + 1] = rec
        end
    end
    idx.catalog_entries = (idx.catalog_entries or 0) + 1
end

local function primary_entry_id(entry)
    for _, id in ipairs((entry and entry.ids) or {}) do
        id = tonumber(id)
        if id and id > 0 then return math.floor(id) end
    end
    return 0
end

local function announce_entry_key(rec)
    local entry = rec and rec.entry or nil
    local id = primary_entry_id(entry)
    if id > 0 then
        return tostring(rec.list_id or "") .. "\31id:" .. tostring(id)
    end
    return tostring(rec and rec.list_id or "") .. "\31name:" .. norm_item_key(entry and entry.item or rec and rec.item_name or "")
end

local function add_catalog_list_entries(idx, list_id, class_name)
    local list = M.list(list_id)
    if not list then return end
    idx.list_count = (idx.list_count or 0) + 1
    local list_name = M.list_label(list_id)
    for _, cat in ipairs(list.categories or {}) do
        for _, slot in ipairs(cat.slots or {}) do
            local entry = M.resolve_entry(list_id, class_name, slot)
            if entry then
                for _, name in ipairs(entry.names or { entry.item }) do
                    name = trim(name)
                    if name ~= "" then add_catalog_entry(idx, list_id, list_name, entry, name) end
                end
            end
        end
    end
end

local function add_user_list_by_id(idx, list_id, class_name)
    bis.load_all()
    local list = bis.get(list_id)
    if not list then return end
    idx.list_count = (idx.list_count or 0) + 1
    local list_name = list.name or "BiS"
    for _, entry in ipairs(list.entries or {}) do
        local ne = bis.normalize_entry(entry)
        for _, name in ipairs(ne.names or { ne.item }) do
            name = trim(name)
            if name ~= "" then add_catalog_entry(idx, list_id, list_name, ne, name) end
        end
    end
end

local function add_user_list_entries(idx, class_name)
    if Settings.bisListMode ~= "user" then return end
    bis.load_all()
    local list = bis.get(Settings.bisSelectedList)
    if not list then return end
    add_user_list_by_id(idx, list.id or Settings.bisSelectedList, class_name)
end

local finish_catalog_build

local function add_entry_names(idx, list_id, list_name, entry)
    for _, name in ipairs(entry.names or { entry.item }) do
        name = trim(name)
        if name ~= "" then add_catalog_entry(idx, list_id, list_name, entry, name) end
    end
end

local function begin_ref_work(build, ref)
    local work = {
        ref_i = build.list_i,
        kind = tostring(ref and ref.kind or "catalog"),
        id = ref and ref.id,
    }
    if work.kind == "user" then
        bis.load_all()
        local list = bis.get(work.id)
        if not list then work.done = true; return work end
        work.list_name = list.name or "BiS"
        work.entries = list.entries or {}
        work.entry_i = 1
    else
        local list = M.list(work.id)
        if not list then work.done = true; return work end
        work.list_name = M.list_label(work.id)
        work.categories = list.categories or {}
        work.cat_i = 1
        work.slot_i = 1
    end
    build.idx.list_count = (build.idx.list_count or 0) + 1
    return work
end

local function finish_ref_work(build)
    build.work = nil
    build.list_i = build.list_i + 1
    if catalog_build == build then catalog_build.list_i = build.list_i end
end

local function step_ref_work(build)
    local ref = build.list_refs[build.list_i]
    if not ref then
        finish_catalog_build()
        return false
    end
    if not build.work or build.work.ref_i ~= build.list_i then
        build.work = begin_ref_work(build, ref)
    end
    local work = build.work
    if not work or work.done then
        finish_ref_work(build)
        return true
    end

    if work.kind == "user" then
        local raw = work.entries and work.entries[work.entry_i]
        if not raw then
            finish_ref_work(build)
            return true
        end
        add_entry_names(build.idx, work.id, work.list_name, bis.normalize_entry(raw))
        work.entry_i = work.entry_i + 1
        return true
    end

    while true do
        local cat = work.categories and work.categories[work.cat_i]
        if not cat then
            finish_ref_work(build)
            return true
        end
        local slot = cat.slots and cat.slots[work.slot_i]
        if slot then
            local entry = M.resolve_entry(work.id, build.class_name, slot)
            if entry then add_entry_names(build.idx, work.id, work.list_name, entry) end
            work.slot_i = work.slot_i + 1
            return true
        end
        work.cat_i = work.cat_i + 1
        work.slot_i = 1
    end
end

finish_catalog_build = function()
    if not catalog_build then return end
    catalog_build.idx.sig = catalog_build.sig
    static_catalog = catalog_build.idx
    catalog_build = nil
end

local function start_catalog_build(class_name, owner_name)
    class_name = class_key(class_name or "")
    owner_name = trim(owner_name or "")
    local sig = catalog_static_sig(class_name, owner_name)
    if static_catalog.sig == sig then return end
    if catalog_build and catalog_build.sig == sig then return end
    local list_refs, seen = {}, {}
    local function add_ref(ref)
        local key = tostring(ref.kind or "catalog") .. ":" .. tostring(ref.id or "")
        if seen[key] then return end
        seen[key] = true
        list_refs[#list_refs + 1] = ref
    end
    for _, ref in ipairs(M.lists_for_announce()) do add_ref(ref) end
    for _, ref in ipairs(user_lists_for_announce(class_name, owner_name)) do add_ref(ref) end
    catalog_build = {
        sig = sig,
        class_name = class_name,
        owner_name = owner_name,
        list_refs = list_refs,
        list_i = 1,
        idx = { sig = nil, by_id = {}, by_name = {}, list_count = 0, catalog_entries = 0 },
    }
end

local function build_catalog_sync(class_name, owner_name)
    start_catalog_build(class_name, owner_name)
    while catalog_build do
        M.tick_announce_catalog(500)
    end
    return static_catalog
end

function M.ensure_announce_catalog(class_name, opts)
    class_name = class_key(class_name or "")
    local owner_name = trim((opts and opts.owner) or (mq.TLO.Me.CleanName() or ""))
    local sig = catalog_static_sig(class_name, owner_name)
    if static_catalog.sig == sig then return static_catalog end
    if opts and opts.sync then
        return build_catalog_sync(class_name, owner_name)
    end
    start_catalog_build(class_name, owner_name)
    return static_catalog
end

function M.announce_catalog_ready(class_name, owner_name)
    if owner_name == nil then
        owner_name = mq.TLO.Me.CleanName() or ""
    end
    owner_name = trim(owner_name or "")
    return static_catalog.sig == catalog_static_sig(class_key(class_name or ""), owner_name)
end

function M.catalog_build_state()
    if catalog_build then
        return {
            building = true,
            entries = catalog_build.idx and catalog_build.idx.catalog_entries or 0,
            lists_done = math.max(0, (catalog_build.list_i or 1) - 1),
            lists_total = #(catalog_build.list_refs or {}),
        }
    end
    return {
        building = false,
        entries = static_catalog.catalog_entries or 0,
        lists_done = static_catalog.list_count or 0,
        lists_total = static_catalog.list_count or 0,
    }
end

-- Finish the async announce index within a time budget (all announce-enabled lists).
function M.flush_announce_catalog(class_name, owner_name, budget_ms)
    class_name = class_key(class_name or "")
    owner_name = trim(owner_name or mq.TLO.Me.CleanName() or "")
    M.ensure_announce_catalog(class_name, { owner = owner_name })
    budget_ms = tonumber(budget_ms) or 500
    local deadline = os.clock() + budget_ms / 1000
    while not M.announce_catalog_ready(class_name, owner_name) and os.clock() < deadline do
        local remaining = (deadline - os.clock()) * 1000
        if remaining <= 0 then break end
        M.tick_announce_catalog(math.max(15, remaining), tonumber(cfg.CFG.announce_catalog_steps_flush) or 64)
    end
    return M.announce_catalog_ready(class_name, owner_name), static_catalog
end

function M.tick_announce_catalog(budget_ms, max_steps)
    budget_ms = tonumber(budget_ms) or BUILD_BUDGET_MS
    if not catalog_build then
        return static_catalog.sig ~= nil
    end
    local deadline = os.clock() + budget_ms / 1000
    max_steps = tonumber(max_steps)
    local steps = 0
    while os.clock() < deadline and (not max_steps or steps < max_steps) do
        local build = catalog_build
        if not build then break end
        steps = steps + 1
        if not step_ref_work(build) then break end
    end
    return catalog_build == nil
end

local function collect_catalog_candidates(idx, item_name, item_id)
    local out, seen = {}, {}
    local function add(rec)
        local dedupe = tostring(rec.list_id or "") .. "\31" .. norm_item_key(rec.item_name)
        if seen[dedupe] then return end
        seen[dedupe] = true
        out[#out + 1] = rec
    end
    item_id = tonumber(item_id) or 0
    if item_id > 0 then
        for _, rec in ipairs(idx.by_id[item_id] or {}) do add(rec) end
    end
    local key = norm_item_key(item_name)
    if key ~= "" then
        for _, rec in ipairs(idx.by_name[key] or {}) do add(rec) end
    end
    return out
end

local function is_local_snap(snap)
    if type(snap) ~= "table" then return false end
    local my_name = trim(mq.TLO.Me.CleanName() or ""):lower()
    local my_server = trim(mq.TLO.MacroQuest.Server() or ""):lower()
    return my_name ~= ""
        and trim(snap.name or ""):lower() == my_name
        and (my_server == "" or trim(snap.server or ""):lower() == my_server)
end

local function need_from_rec(rec, snap, opts)
    opts = type(opts) == "table" and opts or {}
    local row = bis.evaluate_entry(rec.entry, snap)
    if row.status ~= "missing" then return nil end
    -- Snapshot can lag a few seconds after loot/bank; confirm with live FindItem.
    if opts.skip_live ~= true and is_local_snap(snap) and bis.live_own_item(rec.entry, rec.item_name, nil) then return nil end
    return {
        list = { id = rec.list_id, name = rec.list_name },
        entry = rec.entry,
        item_name = rec.item_name,
    }
end

local function direct_candidate_name(entry, item_name)
    item_name = trim(item_name)
    if item_name ~= "" then return item_name end
    for _, name in ipairs((entry and entry.names) or {}) do
        name = trim(name)
        if name ~= "" then return name end
    end
    return trim(entry and entry.item or "")
end

local function direct_need_from_entry(list_id, list_name, entry, snap, item_name, item_id, opts)
    if not entry or not bis.link_matches_entry or not bis.link_matches_entry(entry, item_name, item_id) then
        return nil
    end
    local rec = {
        list_id = list_id,
        list_name = list_name,
        entry = entry,
        item_name = direct_candidate_name(entry, item_name),
    }
    if rec.item_name == "" then rec.item_name = trim(item_name) end
    return need_from_rec(rec, snap, opts)
end

-- Direct catalogs are shared per CLASS whenever no user lists apply to the
-- owner (the common case): the catalog-list portion is owner-independent, so
-- six boxes of four classes cost four builds, not six - and repeat owners of
-- the same class are free. Owners with user lists still get a private build.
-- (direct_class_catalogs is declared at the top so toggles can reset it.)
local function catalog_class_sig(class_name)
    local list_parts = {}
    for _, ref in ipairs(M.lists_for_announce()) do
        list_parts[#list_parts + 1] = tostring(ref.id or "")
    end
    return table.concat({
        tostring(class_name or ""),
        announce_settings_sig(),
        table.concat(list_parts, ","),
    }, "\31")
end

local function ensure_direct_catalog(class_name, owner_name)
    class_name = class_key(class_name or "")
    owner_name = trim(owner_name or "")
    local sig = catalog_static_sig(class_name, owner_name)
    if direct_catalogs[sig] then
        direct_catalog = direct_catalogs[sig]
        return direct_catalog
    end

    local user_refs = user_lists_for_announce(class_name, owner_name)
    if #user_refs == 0 then
        local csig = catalog_class_sig(class_name)
        local idx = direct_class_catalogs[csig]
        if not idx then
            idx = { sig = csig, by_id = {}, by_name = {}, list_count = 0, catalog_entries = 0 }
            for _, ref in ipairs(M.lists_for_announce()) do
                add_catalog_list_entries(idx, ref.id, class_name)
            end
            direct_class_catalogs[csig] = idx
        end
        direct_catalog = idx
        direct_catalogs[sig] = idx
        return direct_catalog
    end

    local idx = { sig = sig, by_id = {}, by_name = {}, list_count = 0, catalog_entries = 0 }
    local seen = {}
    local function add_ref(ref)
        local key = tostring(ref.kind or "catalog") .. ":" .. tostring(ref.id or "")
        if seen[key] then return end
        seen[key] = true
        if ref.kind == "user" then
            add_user_list_by_id(idx, ref.id, class_name)
        else
            add_catalog_list_entries(idx, ref.id, class_name)
        end
    end

    for _, ref in ipairs(M.lists_for_announce()) do add_ref(ref) end
    for _, ref in ipairs(user_refs) do add_ref(ref) end
    direct_catalog = idx
    direct_catalogs[sig] = idx
    return direct_catalog
end

-- Expose the memoized direct catalog for a class/owner so consumers (e.g. the
-- needs index) can enumerate announce-enabled entries without private access.
-- BUILDS SYNCHRONOUSLY if missing - only call from budgeted tick context.
function M.direct_catalog_for(class_name, owner_name)
    return ensure_direct_catalog(class_name, owner_name)
end

-- Cached-or-nil variant for CHAT-EVENT paths: a chat handler must never pay
-- for a catalog build (that was the 26-39s "earthquake" freeze). Returns nil
-- while the catalog is not yet built; callers queue the line as pending and
-- the needs index builds catalogs from its budgeted tick.
function M.direct_catalog_if_ready(class_name, owner_name)
    class_name = class_key(class_name or "")
    owner_name = trim(owner_name or "")
    return direct_catalogs[catalog_static_sig(class_name, owner_name)]
end

-- ===== Disk cache for direct catalogs =================================== --
-- Catalogs depend only on the lazbis data + announce settings + user lists,
-- all captured below. Build once EVER per signature, persist, and load in
-- ~100-300ms on later launches - warm-up cost becomes a one-time event
-- instead of a per-session multi-second burn on slow machines.
local function sig_hash(sig)
    local h1, h2 = 5381, 52711
    for i = 1, #sig do
        local b = sig:byte(i)
        h1 = (h1 * 33 + b) % 4294967296
        h2 = (h2 * 31 + b) % 4294967296
    end
    return string.format("%x_%x", h1, h2)
end

local function dcat_path(sig)
    return string.format("%s/%s_dcat_%s.lua", mq.configDir, cfg.CFG.script_name, sig_hash(sig))
end

-- Cheap structural fingerprint of the generated catalog: invalidates disk
-- caches when the lazbis data changes shape. (Same-shape content edits slip
-- through - delete Config/TurboGear_dcat_*.lua after regenerating the
-- catalog if results look stale.)
local catalog_fingerprint_cache
local function catalog_fingerprint()
    if catalog_fingerprint_cache then return catalog_fingerprint_cache end
    local lists, slots = 0, 0
    for _, l in pairs(catalog.lists or {}) do
        lists = lists + 1
        for _, c in ipairs(l.categories or {}) do slots = slots + #(c.slots or {}) end
    end
    catalog_fingerprint_cache = tostring(lists) .. ":" .. tostring(slots)
    return catalog_fingerprint_cache
end

-- User list CONTENT is not in the sig (only ids); stamp their updated fields
-- so edits invalidate the disk cache.
local function user_lists_stamp(class_name, owner_name)
    local parts = {}
    for _, ref in ipairs(user_lists_for_announce(class_name, owner_name)) do
        local l = bis.get(ref.id)
        parts[#parts + 1] = tostring(ref.id) .. "=" .. tostring(l and l.updated or "")
    end
    return table.concat(parts, ",")
end

-- Serialize preserving shared entry tables (multiple recs reference the same
-- entry; naive pickling would duplicate them and break dedupe on load).
local function dcat_payload(sig, idx, class_name, owner_name)
    local entries, entry_ix, recs = {}, {}, {}
    for _, list in pairs(idx.by_name or {}) do
        for _, rec in ipairs(list) do
            local ei = entry_ix[rec.entry]
            if not ei then
                entries[#entries + 1] = rec.entry
                ei = #entries
                entry_ix[rec.entry] = ei
            end
            recs[#recs + 1] = { l = rec.list_id, n = rec.list_name, d = rec.item_name, e = ei }
        end
    end
    return {
        sig = sig,
        fingerprint = catalog_fingerprint(),
        user_stamp = user_lists_stamp(class_name, owner_name),
        list_count = idx.list_count or 0,
        entries = entries,
        recs = recs,
    }
end

local function idx_from_payload(payload)
    local idx = {
        sig = payload.sig, by_id = {}, by_name = {},
        list_count = tonumber(payload.list_count) or 0, catalog_entries = 0,
    }
    for _, r in ipairs(payload.recs) do
        local entry = payload.entries[tonumber(r.e) or 0]
        if entry then
            add_catalog_entry(idx, r.l, r.n, entry, r.d)
        end
    end
    return idx
end

local function save_dcat(sig, idx, class_name, owner_name)
    pcall(function()
        mq.pickle(dcat_path(sig), dcat_payload(sig, idx, class_name, owner_name))
    end)
end

local function load_dcat(sig, class_name, owner_name)
    local ok_load, payload = pcall(function()
        local chunk = loadfile(dcat_path(sig))
        if type(chunk) ~= "function" then return nil end
        return chunk()
    end)
    if not ok_load or type(payload) ~= "table" then return nil end
    if payload.sig ~= sig then return nil end
    if payload.fingerprint ~= catalog_fingerprint() then return nil end
    if payload.user_stamp ~= user_lists_stamp(class_name, owner_name) then return nil end
    if type(payload.entries) ~= "table" or type(payload.recs) ~= "table" then return nil end
    local ok_idx, idx = pcall(idx_from_payload, payload)
    if not ok_idx then return nil end
    return idx
end

-- ===== Async budgeted direct-catalog builder ============================ --
-- Offline profiling shows the build algorithm itself is ~100-600ms, but on
-- live game threads it measures 3.5-8s (interpreter/GC/load multipliers we
-- cannot control). So the build is CHUNKED: tick_direct_build advances one
-- (class, owner) build within an os.clock deadline; callers re-invoke each
-- tick until it reports ready. No synchronous build path remains.
-- (direct_async is declared at the top so settings toggles can reset it.)
local function direct_build_state(class_name, owner_name, sig)
    local st = direct_async[sig]
    if st then return st end
    local refs, seen = {}, {}
    local function add_ref(ref)
        local key = tostring(ref.kind or "catalog") .. ":" .. tostring(ref.id or "")
        if seen[key] then return end
        seen[key] = true
        refs[#refs + 1] = ref
    end
    for _, ref in ipairs(M.lists_for_announce()) do add_ref(ref) end
    local user_refs = user_lists_for_announce(class_name, owner_name)
    for _, ref in ipairs(user_refs) do add_ref(ref) end
    st = {
        sig = sig,
        class_name = class_name,
        class_shareable = #user_refs == 0,
        refs = refs,
        ref_i = 1,
        cat_i = 1,
        slot_i = 1,
        entry_i = 1,
        idx = { sig = sig, by_id = {}, by_name = {}, list_count = 0, catalog_entries = 0 },
    }
    direct_async[sig] = st
    return st
end

-- Advance one build step. Returns true when a unit of work was done, false
-- when the current ref is exhausted (advance to next).
local function direct_build_step(st)
    local ref = st.refs[st.ref_i]
    if not ref then return nil end -- complete
    if ref.kind == "user" then
        if not st.user_list then
            bis.load_all()
            st.user_list = bis.get(ref.id)
            st.entry_i = 1
            if not st.user_list then
                st.ref_i = st.ref_i + 1
                st.user_list = nil
                return true
            end
            st.idx.list_count = st.idx.list_count + 1
        end
        local raw = (st.user_list.entries or {})[st.entry_i]
        if not raw then
            st.ref_i = st.ref_i + 1
            st.user_list = nil
            return true
        end
        local ne = bis.normalize_entry(raw)
        for _, name in ipairs(ne.names or { ne.item }) do
            name = trim(name)
            if name ~= "" then
                add_catalog_entry(st.idx, ref.id, st.user_list.name or "BiS", ne, name)
            end
        end
        st.entry_i = st.entry_i + 1
        return true
    end
    local list = M.list(ref.id)
    if not list then
        st.ref_i = st.ref_i + 1
        st.cat_i, st.slot_i = 1, 1
        return true
    end
    if st.cat_i == 1 and st.slot_i == 1 then
        st.idx.list_count = st.idx.list_count + 1
    end
    local cat = (list.categories or {})[st.cat_i]
    if not cat then
        st.ref_i = st.ref_i + 1
        st.cat_i, st.slot_i = 1, 1
        return true
    end
    local slot = (cat.slots or {})[st.slot_i]
    if not slot then
        st.cat_i = st.cat_i + 1
        st.slot_i = 1
        return true
    end
    local entry = M.resolve_entry(ref.id, st.class_name, slot)
    if entry then
        local list_name = M.list_label(ref.id)
        for _, name in ipairs(entry.names or { entry.item }) do
            name = trim(name)
            if name ~= "" then
                add_catalog_entry(st.idx, ref.id, list_name, entry, name)
            end
        end
    end
    st.slot_i = st.slot_i + 1
    return true
end

-- Advance the build for (class, owner) until `deadline` (os.clock value).
-- Returns the finished idx, or nil while still building.
function M.tick_direct_build(class_name, owner_name, deadline)
    class_name = class_key(class_name or "")
    owner_name = trim(owner_name or "")
    local sig = catalog_static_sig(class_name, owner_name)
    local done = direct_catalogs[sig]
    if done then
        direct_async[sig] = nil
        return done
    end
    -- Class-shared result may already exist (built for another owner).
    local st = direct_async[sig]
    if not st then
        local probe_user = user_lists_for_announce(class_name, owner_name)
        if #probe_user == 0 then
            local csig = catalog_class_sig(class_name)
            local shared = direct_class_catalogs[csig]
            if shared then
                direct_catalogs[sig] = shared
                return shared
            end
        end
        -- Disk cache: one ~100-300ms load beats a multi-second build.
        local cached = load_dcat(sig, class_name, owner_name)
        if cached then
            direct_catalogs[sig] = cached
            if #probe_user == 0 then
                direct_class_catalogs[catalog_class_sig(class_name)] = cached
            end
            return cached
        end
        st = direct_build_state(class_name, owner_name, sig)
    end
    deadline = tonumber(deadline) or (os.clock() + 0.005)
    local steps = 0
    while os.clock() < deadline do
        local more = direct_build_step(st)
        steps = steps + 1
        if more == nil then
            -- Complete: publish to caches and persist to disk (once ever).
            direct_catalogs[sig] = st.idx
            if st.class_shareable then
                direct_class_catalogs[catalog_class_sig(st.class_name)] = st.idx
            end
            direct_async[sig] = nil
            save_dcat(sig, st.idx, class_name, owner_name)
            return st.idx
        end
    end
    return nil
end

function M.direct_build_in_progress()
    for _, _ in pairs(direct_async) do return true end
    return false
end

function M.direct_build_progress()
    for _, st in pairs(direct_async) do
        return {
            refs_total = #(st.refs or {}),
            ref_i = st.ref_i or 0,
            entries = (st.idx and st.idx.catalog_entries) or 0,
        }
    end
    return nil
end

function M.check_announce_need_direct(snap, item_name, item_id, opts)
    if not snap then return nil end
    -- Never build a catalog from a chat-triggered scan; warm-up lines queue
    -- as pending and drain once the needs index has built the catalogs.
    local idx = M.direct_catalog_if_ready(snap.class, snap.name)
    if not idx then return nil end
    for _, rec in ipairs(collect_catalog_candidates(idx, item_name, item_id)) do
        local need = direct_need_from_entry(rec.list_id, rec.list_name, rec.entry, snap, item_name, item_id, opts)
        if need then return need end
    end
    return nil
end

function M.direct_item_candidates_in_text(snap, line, limit)
    if not snap then return {} end
    line = tostring(line or "")
    if line == "" then return {} end
    local idx = M.direct_catalog_if_ready(snap.class, snap.name)
    if not idx then return {} end
    local lower = line:lower()
    -- One entry can carry alias pairs where one is a substring of the other
    -- (Jonas hand: "Triquetrum" / "Jonas Dagmire's Triquetrum"), so a single
    -- mention matches BOTH name keys. Rank matches longest-key-first, then
    -- dedupe by the entry's CANONICAL item name so each item yields one
    -- candidate displayed under the most specific alias in the line.
    local matches = {}
    for key, recs in pairs(idx.by_name or {}) do
        if key ~= "" and lower:find(key, 1, true) then
            local rec = recs and recs[1]
            if rec then matches[#matches + 1] = { key = key, rec = rec } end
        end
    end
    table.sort(matches, function(a, b) return #a.key > #b.key end)
    local hits, seen = {}, {}
    for _, m in ipairs(matches) do
        local rec = m.rec
        local item_name = trim(rec.item_name)
        local canonical = norm_item_key(trim(rec.entry and rec.entry.item or ""))
        if canonical == "" then canonical = norm_item_key(item_name) end
        if item_name ~= "" and canonical ~= "" and not seen[canonical] then
            seen[canonical] = true
            hits[#hits + 1] = {
                name = item_name,
                id = primary_entry_id(rec.entry),
            }
        end
    end
    limit = math.max(1, math.floor(tonumber(limit) or 8))
    while #hits > limit do table.remove(hits) end
    return hits
end

function M.check_announce_need(snap, item_name, item_id)
    if not snap then return nil end
    if not M.announce_catalog_ready(snap.class, snap.name) then
        M.ensure_announce_catalog(snap.class, { owner = snap.name })
        return nil
    end
    local idx = static_catalog
    for _, rec in ipairs(collect_catalog_candidates(idx, item_name, item_id)) do
        local need = need_from_rec(rec, snap)
        if need then return need end
    end
    if bis.link_matches_entry then
        for _, recs in pairs(idx.by_name or {}) do
            for _, rec in ipairs(recs) do
                if bis.link_matches_entry(rec.entry, item_name, item_id) then
                    local need = need_from_rec(rec, snap)
                    if need then return need end
                end
            end
        end
    end
    return nil
end

function M.rebuild_announce_index(snap)
    return M.ensure_announce_catalog(snap and snap.class)
end

function M.lookup_announce_need(item_name, item_id)
    local snap = require('snapshot').cached()
    if not snap then return nil end
    return M.check_announce_need(snap, item_name, item_id)
end

function M.find_announce_need(snap, item_name, item_id)
    return M.check_announce_need(snap, item_name, item_id)
end

function M.find_announce_needs_in_line(snap, line)
    if not snap then return {} end
    if not M.announce_catalog_ready(snap.class, snap.name) then
        M.ensure_announce_catalog(snap.class, { owner = snap.name })
        return {}
    end
    local idx = static_catalog
    line = tostring(line or "")
    local out, seen, seen_entry = {}, {}, {}
    for key, recs in pairs(idx.by_name or {}) do
        if not seen[key] then
            for _, rec in ipairs(recs) do
                if M.list_announce_enabled(rec.list_id) then
                    local name = rec.item_name
                    if name ~= "" and line:find(name, 1, true) then
                        seen[key] = true
                        local entry_key = announce_entry_key(rec)
                        if seen_entry[entry_key] then break end
                        seen_entry[entry_key] = true
                        local need = need_from_rec(rec, snap)
                        if need then
                            out[#out + 1] = {
                                item_name = need.item_name,
                                item_id = primary_entry_id(rec.entry),
                                need = need,
                            }
                        end
                        break
                    end
                end
            end
        end
    end
    return out
end

function M.count_missing_announce_entries(snap)
    if not snap then return 0 end
    if not M.announce_catalog_ready(snap.class, snap.name) then
        M.ensure_announce_catalog(snap.class, { owner = snap.name })
        return 0
    end
    local idx = static_catalog
    local missing = 0
    for _, recs in pairs(idx.by_name or {}) do
        for _, rec in ipairs(recs) do
            local row = bis.evaluate_entry(rec.entry, snap)
            if row.status == "missing" then
                missing = missing + 1
                break
            end
        end
    end
    return missing
end

M.catalog = catalog
return M
