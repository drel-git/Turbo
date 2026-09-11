-- TurboGear/bis_catalog.lua
-- Runtime resolver for built-in/catalog BiS data. Catalog rows are class-aware:
-- each character column resolves the selected list against that character's class.

local bis = require('bis')
local name_is_id_only = require('ownership_index').name_is_id_only

-- Names to index/display a row under. A row whose only name is ID-only (Jonas
-- Tier 6 "Skeletal Hand") keeps its display name here so it still shows in
-- search and its ids still get indexed; add_catalog_entry skips the by_name key.
local function index_names(entry)
    local names = entry and entry.names
    if type(names) == "table" and #names > 0 then return names end
    return { entry and entry.item or "" }
end
local mq = require('mq')
local cfg = require('config')
local diag = require('diagnostics')
local Settings, SaveSettings = cfg.Settings, cfg.SaveSettings
local SharedSettings, SaveSharedSettings = cfg.SharedSettings, cfg.SaveSharedSettings

local M = {}

function M._wall_now_s()
    if mq and mq.gettime then
        local ok, value = pcall(mq.gettime)
        if ok and tonumber(value) then return tonumber(value) / 1000 end
    end
    return os.clock()
end

-- Lazy catalog load (P2): the generated BiS catalog (~34k
-- lines) is only require()'d on first field access, so pure viewers and bg
-- publishers that never open BiS or evaluate announce-needs don't pay the parse
-- + resident-memory cost. Access goes through a proxy whose __index materializes
-- the real table once and then forwards field reads (catalog.groups / .lists /
-- .default / .zone_map). No code iterates the top-level table, so a proxy is safe.
local _catalog_real = nil
M._catalog_runtime_status = {
    catalog_resident = false,
    generated_resident = false,
}
local function load_catalog(origin)
    if _catalog_real == nil then
        local wall_t0, cpu_t0 = M._wall_now_s(), os.clock()
        local ok, t = pcall(require, 'catalogs.lazbis')
        _catalog_real = (ok and type(t) == "table") and t or { groups = {}, lists = {} }
        local status = M._catalog_runtime_status
        status.catalog_resident = ok and type(t) == "table"
        status.catalog_load_origin = tostring(origin or "other")
        status.catalog_loaded_at = M._wall_now_s()
        status.catalog_load_wall_ms = math.max(0, (status.catalog_loaded_at - wall_t0) * 1000)
        status.catalog_load_cpu_ms = math.max(0, (os.clock() - cpu_t0) * 1000)
        diag.sample("generated_index.catalog_load_wall_ms", status.catalog_load_wall_ms)
        diag.sample("generated_index.catalog_load_cpu_ms", status.catalog_load_cpu_ms)
    end
    return _catalog_real
end
local catalog = setmetatable({}, {
    __index = function(_, k) return load_catalog()[k] end,
})
-- Observability / warm hooks: catalog_loaded() reports whether the big table is
-- resident (used by perfdiag); warm_catalog() forces the load off the hot path.
function M.catalog_loaded() return _catalog_real ~= nil end
function M.warm_catalog(origin) load_catalog(origin or "startup"); return true end
function M.catalog_runtime_status()
    return M._catalog_runtime_status
end

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
local link_entry_memo = {}         -- class+item -> announce entry (per-link walk cache)
local compact_rule_cache = {}      -- catalog sig -> prepared compact local_needs rules
local compact_rules_generation = 1 -- bumped by explicit announce/list invalidation hooks
local compact_announce_settings_sig = nil
local compact_build_queue = {}
local compact_build_seen = {}
local compact_build = nil
local shared_index_generation = 1
local shared_index_active = nil
local shared_index_stage = nil
local shared_index_build = nil
local shared_index_queue = {}
local shared_index_seen = {}
local shared_artifact_cache = {}
local shared_artifact_next_id = 0
local shared_semantic_cache = {}
local generated_builtin = {
    index = nil,
    load_attempted = false,
    status = { ready = false, reason = "not-loaded" },
    semantic_cache = {},
    schema = 1,
    semver = "turbogear-builtin-announce-v1",
}

local function now_ms()
    if mq and mq.gettime then
        local ok, value = pcall(mq.gettime)
        if ok and tonumber(value) then return tonumber(value) end
    end
    return os.time() * 1000
end

local function diag_context(key, detail)
    if diag and type(diag.context) == "function" then
        diag.context(key, detail)
    end
end

function M.invalidate_compact_announce_rules(reason)
    compact_rules_generation = compact_rules_generation + 1
    compact_rule_cache = {}
    compact_build_queue = {}
    compact_build_seen = {}
    compact_build = nil
    shared_index_generation = shared_index_generation + 1
    shared_index_stage = nil
    shared_index_build = nil
    shared_index_queue = {}
    shared_index_seen = {}
    shared_artifact_cache = {}
    shared_artifact_next_id = 0
    shared_semantic_cache = {}
    generated_builtin.semantic_cache = {}
    diag.count("local_needs.prepared_build_invalidated")
    diag.sample("local_needs.prepared_generation", compact_rules_generation)
    diag.sample("local_needs.shared_index_generation", shared_index_generation)
    return compact_rules_generation, tostring(reason or "manual")
end

local function trim(s)
    return tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function class_key(class_name)
    if cfg.canonical_class then return cfg.canonical_class(class_name) end
    class_name = trim(class_name)
    if class_name == "" or class_name == "?" then return nil end
    if class_name == "Shadowknight" then return "Shadow Knight" end
    return class_name
end

local announce_settings_sig

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
        if name ~= "" and not seen[k] and not name_is_id_only(name) then
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

-- Adventurer's Tattered Sack progression (Bags BiS). Owning a higher rank
-- clears lower sack rows; upgrade trash clears once the corresponding rank
-- (or higher) is owned. Frame stays needed until Celestial.
local TATTERED_SACK_RANKS = {
    {
        rank = 1,
        id = 151053,
        name = "Adventurer's Tattered Sack",
        slot = "Adventurer's Tattered Sack (Base) (T1 Named)",
    },
    {
        rank = 2,
        id = 151054,
        name = "Adventurer's Tattered Sack (Reinforced)",
        slot = "Adventurer's Tattered Sack (Reinforced) (UP1)",
    },
    {
        rank = 3,
        id = 151055,
        name = "Adventurer's Tattered Sack (Bound)",
        slot = "Adventurer's Tattered Sack (Bound) (UP2)",
    },
    {
        rank = 4,
        id = 151056,
        name = "Adventurer's Tattered Sack (Arcwoven)",
        slot = "Adventurer's Tattered Sack (Arcwoven) (UP3)",
    },
    {
        rank = 5,
        id = 151057,
        name = "Adventurer's Tattered Sack (Celestial)",
        slot = "Adventurer's Tattered Sack (Celestial)",
    },
}

local TATTERED_SACK_MATERIALS = {
    ["Reinforced Stitching Frame (T2 Trash)"] = { id = 151058, min_rank = 5 },
    ["Treated Expedition Straps (T3 Trash)"] = { min_rank = 3 },
    ["Arcwoven Binding Thread (T4 Trash)"] = { min_rank = 4 },
    ["Master Tailor's Celestial Lining (T5 Trash)"] = { min_rank = 5 },
}

local TATTERED_SACK_SLOT_RANK = {}
for _, row in ipairs(TATTERED_SACK_RANKS) do
    TATTERED_SACK_SLOT_RANK[row.slot] = row.rank
end

local function expand_tattered_sack_chain(out)
    local slot = tostring(out.slot or "")
    local id_seen, name_seen = seed_id_seen(out), seed_name_seen(out)
    local rank = TATTERED_SACK_SLOT_RANK[slot]
    local mat = TATTERED_SACK_MATERIALS[slot]
    local min_rank = rank or (mat and mat.min_rank) or nil
    if not min_rank then return out end
    if mat and mat.id then add_ids(out, { mat.id }, id_seen) end
    for _, row in ipairs(TATTERED_SACK_RANKS) do
        if row.rank >= min_rank then
            add_ids(out, { row.id }, id_seen)
            add_names(out, { row.name }, name_seen)
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

-- Jonas Hand progression (Hand Aug checklist). LazBiS parity, data-driven:
-- every row's catalog ids already carry its own bone/finger id plus every
-- later hand (33167-33171), so a crafted finger or any later hand clears
-- the tier. No cross-row NAME chaining: hands 33167-33171 all share the
-- name "Jonas Dagmire's Skeletal Hand" (see ownership_index.name_is_id_only),
-- so a name hit cannot tell tiers apart. Only the "Jonas Dagmire's" prefix
-- alias is added so bare/prefixed bone names both match.
local function expand_jonas_hand_chain(list, class_bucket, out)
    local name_seen = seed_name_seen(out)
    add_jonas_aliases(out, out.names, name_seen)
    add_jonas_aliases_for_name(out, out.item, name_seen)
    return out
end

-- DoN Clickies: Boon (Clicky1) + specialty Icon (Clicky2) + combined Ancient*
-- final (Clicky3). Owning the final clears the component rows.
local function expand_don_clicky_chain(list, class_bucket, out)
    local slot = tostring(out.slot or "")
    if slot ~= "Clicky1" and slot ~= "Clicky2" then return out end
    local final = (class_bucket and class_bucket.Clicky3)
        or (list and list.template and list.template.Clicky3)
    if not final then return out end
    local e = norm_entry_cached(final)
    local id_seen, name_seen = seed_id_seen(out), seed_name_seen(out)
    add_ids(out, e.ids, id_seen)
    add_names(out, e.names, name_seen)
    add_names(out, { e.item }, name_seen)
    return out
end

-- DoN Shadow section: owning the finished class Shadow counts as having used
-- Primary/Secondary/Tertiary Materium of Legends (mark those rows green).
local function expand_don_shadow_chain(list, class_bucket, out)
    local slot = tostring(out.slot or "")
    if slot ~= "Materium1" and slot ~= "Materium2" and slot ~= "Materium3" then
        return out
    end
    local shadow = (class_bucket and class_bucket.Shadow)
        or (list and list.template and list.template.Shadow)
    if not shadow then return out end
    local e = norm_entry_cached(shadow)
    local id_seen, name_seen = seed_id_seen(out), seed_name_seen(out)
    add_ids(out, e.ids, id_seen)
    add_names(out, e.names, name_seen)
    add_names(out, { e.item }, name_seen)
    return out
end

-- DoN Misc4: Scales of the Lava Dragon OR the finished class Draconic epic.
local DON_SCALES_EPICS = {
    Bard = { id = 55906, name = "Draconic Blade of Vesagran" },
    Beastlord = { id = 55912, name = "Spiritcaller Totem of the Dragons" },
    Berserker = { id = 55905, name = "Draconic Taelosian Blood Axe" },
    Cleric = { id = 55082, name = "Aegis of Draconic Divinity" },
    Druid = { id = 55729, name = "Staff of Draconic Brambles" },
    Enchanter = { id = 55909, name = "Staff of Draconic Eloquence" },
    Magician = { id = 55908, name = "Focus of Draconic Elements" },
    Monk = { id = 55730, name = "Draconic Fistwraps of Immortality" },
    Necromancer = { id = 55910, name = "Draconic Deathwhisper" },
    Paladin = { id = 55081, name = "Nightbane, Sword of the Dragons" },
    Ranger = { id = 40863, name = "Aurora, the Draconic Bow" },
    Rogue = { id = 55904, name = "Nightshade, Blade of Draconic Entropy" },
    ["Shadow Knight"] = { id = 55080, name = "Innoruuk's Draconic Blessing" },
    Shaman = { id = 55728, name = "Draconic Spiritstaff of the Heyokah" },
    Warrior = { id = 55079, name = "Kreljnok's Sword of Draconic Power" },
    Wizard = { id = 55907, name = "Staff of Draconic Power" },
}

local function expand_don_scales_chain(out, class_name)
    if tostring(out.slot or "") ~= "Misc4" then return out end
    local epic = DON_SCALES_EPICS[class_key(class_name)]
    if not epic then return out end
    local id_seen, name_seen = seed_id_seen(out), seed_name_seen(out)
    add_ids(out, { epic.id }, id_seen)
    add_names(out, { epic.name }, name_seen)
    return out
end

-- Sebilis Forsaken armor: LazBiS treats either the finished class armor or the
-- matching Ruined Shadowy mold as satisfying the slot. Add the mold as a
-- satisfy alias so TurboBiS, linked-needs, and generated authority agree.
function M.expand_sebilis_forsaken_chain(out)
    local mold = ({
        Arms = { name = "Ruined Shadowy Armguards", id = 150774 },
        Chest = { name = "Ruined Shadowy Breastplate" },
        Feet = { name = "Ruined Shadowy Boots", id = 150775 },
        Hands = { name = "Ruined Shadowy Gauntlets", id = 150778 },
        Head = { name = "Ruined Shadowy Helm" },
        Legs = { name = "Ruined Shadowy Greaves" },
        Wrist = { name = "Ruined Shadowy Bracer" },
    })[tostring(out.slot or "")]
    if not mold then return out end
    local item = tostring(out.item or "")
    if not item:lower():find("^forsaken ", 1, false) then return out end
    local group = tostring(out.group or "")
    if group ~= "" and group ~= "Forsaken Armor" then return out end
    local id_seen, name_seen = seed_id_seen(out), seed_name_seen(out)
    if mold.id then add_ids(out, { mold.id }, id_seen) end
    add_names(out, { mold.name }, name_seen)
    return out
end

function M.sebilis_forsaken_mold_for_slot(slot)
    return ({
        Arms = { name = "Ruined Shadowy Armguards", id = 150774 },
        Chest = { name = "Ruined Shadowy Breastplate" },
        Feet = { name = "Ruined Shadowy Boots", id = 150775 },
        Hands = { name = "Ruined Shadowy Gauntlets", id = 150778 },
        Head = { name = "Ruined Shadowy Helm" },
        Legs = { name = "Ruined Shadowy Greaves" },
        Wrist = { name = "Ruined Shadowy Bracer" },
    })[tostring(slot or "")]
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
    { id = "don", label = "Dragons of Norrath", group = "Raid Best In Slot" },
    { id = "llhcitems", label = "Lower HC", group = "Other Checklists" },
    { id = "hcitems", label = "Higher HC", group = "Other Checklists" },
    { id = "focusitems", label = "Type 12 Augs", group = "Other Checklists" },
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
    compact_announce_settings_sig = announce_settings_sig()
    static_catalog.sig = nil
    direct_catalog.sig = nil
    direct_catalogs = {}
    direct_class_catalogs = {}
    static_sig_cache = {}
    direct_async = {}
    catalog_build = nil
    link_entry_memo = {}
    M.invalidate_compact_announce_rules("announce-list-toggle")
    pcall(function() require('announcer').invalidate() end)
end

function M.set_list_hidden(id, hidden)
    id = tostring(id or "")
    if id == "" then return false end
    Settings.bisHiddenLists = type(Settings.bisHiddenLists) == "table" and Settings.bisHiddenLists or {}
    if hidden then
        -- Guard: never hide the last visible catalog (force it to stay).
        local remaining = 0
        for _, spec in ipairs(UI_LIST_BUTTONS) do
            if tostring(spec.id) ~= id and not M.list_hidden(spec.id) and M.list(spec.id) then
                remaining = remaining + 1
            end
        end
        if remaining <= 0 then
            return false
        end
        Settings.bisHiddenLists[id] = true
    else
        Settings.bisHiddenLists[id] = nil
    end
    if SaveSettings then SaveSettings() end
    return true
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

local DonSpellsMod = nil
local function ensure_don_spells_mod()
    if DonSpellsMod ~= nil then return DonSpellsMod end
    local ok, mod = pcall(require, 'don_spells')
    DonSpellsMod = ok and mod or false
    return DonSpellsMod
end

--- Slots for a category. DoN Spells uses per-ability keys from don_spells
--- (always per-class; roster height is computed separately via spell_index rows).
local function category_slots(list_id, cat, class_name, _union)
    if not cat then return {} end
    if list_id == "don" and tostring(cat.name or "") == "Spells" then
        local DS = ensure_don_spells_mod()
        if DS and DS.spell_slots_for_class then
            return DS.spell_slots_for_class(class_name)
        end
        return {}
    end
    return cat.slots or {}
end

local function is_don_spells_category(list_id, cat_name)
    return list_id == "don" and tostring(cat_name or "") == "Spells"
end

local resolve_entry_cache = {}

local function resolve_entry_uncached(list_id, class_name, slot)
    -- DoN Spells: one BiS row per learned ability (not Pack1..Pack10).
    if list_id == "don" then
        local DS = ensure_don_spells_mod()
        if DS and DS.ability_for_slot then
            local ability = DS.ability_for_slot(class_name, slot)
            if ability and DS.bis_entry_for_ability then
                local out = bis.normalize_entry(DS.bis_entry_for_ability(ability))
                out.slot = slot
                out.group = "Spells"
                out.don_ability = ability
                out.learned_from = ability and (DS.learned_from and DS.learned_from(ability) or nil)
                return out
            end
            -- Ability slot for another class -> empty cell (not BiS Pack fallback).
            if DS.is_ability_slot and DS.is_ability_slot(slot) then
                return nil
            end
        end
    end

    local list = M.list(list_id)
    if not list then return nil end
    -- No known class → empty cell. "?" is a discovery stub; falling through to
    -- list.template/visible painted pouches/axes in Arms for Discord (?).
    if not class_name then return nil end
    local class_bucket = list.classes and list.classes[class_name] or nil
    local entry = class_bucket and class_bucket[slot]
    -- Template/visible only after a real class resolved (shared slots), never for stubs.
    if not entry and list.template then entry = list.template[slot] end
    if not entry and list.visible then entry = list.visible[slot] end
    if not entry then return nil end
    local out = bis.normalize_entry(entry)
    out.slot = slot
    out.group = out.group ~= "" and out.group or ""
    out.source = entry.source
    out.spell = entry.spell
    out.spells = entry.spells
    out.spell_ids = entry.spell_ids
    out.notes = entry.notes
    expand_fungal_chain(list, class_bucket or list.template or list.visible, out)
    if list_id == "jonas" then
        expand_jonas_hand_chain(list, class_bucket, out)
    elseif list_id == "don" then
        expand_don_clicky_chain(list, class_bucket, out)
        expand_don_shadow_chain(list, class_bucket, out)
        expand_don_scales_chain(out, class_name)
    elseif list_id == "bagitems" then
        expand_tattered_sack_chain(out)
    elseif list_id == "sebilis" then
        M.expand_sebilis_forsaken_chain(out)
    end
    return out
end

function M.resolve_entry(list_id, class_name, slot)
    class_name = class_key(class_name)
    local cache_key = tostring(list_id or "") .. "\31" .. tostring(class_name or "") .. "\31" .. tostring(slot or "")
    local cached = resolve_entry_cache[cache_key]
    if cached ~= nil then
        if cached == false then return nil end
        return cached
    end
    local out = resolve_entry_uncached(list_id, class_name, slot)
    resolve_entry_cache[cache_key] = out or false
    return out
end

function M.rows_for_snap(list_id, snap)
    local list = M.list(list_id)
    local rows = {}
    if not list or not snap then return rows end
    for _, cat in ipairs(list.categories or {}) do
        rows[#rows+1] = { category = cat.name, header = true }
        for _, slot in ipairs(category_slots(list_id, cat, snap.class, false)) do
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

--- Roster reference rows. opts.class_names (optional) sizes DoN Spells to the
--- max per-class ability count among visible characters instead of a shared matrix.
function M.reference_rows(list_id, opts)
    local list = M.list(list_id)
    local rows = {}
    if not list then return rows end
    opts = type(opts) == "table" and opts or {}
    local class_names = opts.class_names
    for _, cat in ipairs(list.categories or {}) do
        rows[#rows+1] = { category = cat.name, header = true }
        if is_don_spells_category(list_id, cat.name) then
            -- Per-character class columns: N index rows, no shared left-side list.
            local DS = ensure_don_spells_mod()
            local max_n = 0
            if DS and DS.max_spell_slots_for_classes and type(class_names) == "table" and #class_names > 0 then
                max_n = DS.max_spell_slots_for_classes(class_names)
            elseif DS and DS.spell_slots_for_class and type(class_names) == "table" then
                for _, cn in ipairs(class_names) do
                    local n = #DS.spell_slots_for_class(cn)
                    if n > max_n then max_n = n end
                end
            end
            for i = 1, max_n do
                rows[#rows+1] = {
                    category = cat.name,
                    spell_index = i,
                    hide_slot = true,
                }
            end
        else
            for _, slot in ipairs(category_slots(list_id, cat, nil, false)) do
                rows[#rows+1] = { category = cat.name, slot = slot }
            end
        end
    end
    return rows
end

-- Statuses a bis_search slot record may carry verbatim (DoN ability rows
-- report known / ready / pack_owned from the peer's own spellbook).
-- Module fields, not file locals: this chunk is at LuaJIT's 200-local limit.
M._BIS_SEARCH_STATUSES = {
    equipped = true, carried = true, missing = true,
    known = true, ready = true, pack_owned = true,
}

function M._snap_has_spell_data(snap)
    if type(snap) ~= "table" then return false end
    if type(snap.spell_ids) == "table" and next(snap.spell_ids) ~= nil then return true end
    return type(snap.spells) == "table" and next(snap.spells) ~= nil
end

function M.evaluate_slot(list_id, snap, slot, category)
    local entry = M.resolve_entry(list_id, snap and snap.class, slot)
    if not entry then return { category = category, slot = slot, empty = true } end
    entry.group = category or entry.group
    -- Peer columns: prefer BiS FindItem maps over empty/stale snapshots.
    local is_self = false
    if snap then
        pcall(function()
            local mine = tostring(mq.TLO.Me.CleanName() or ""):lower()
            is_self = mine ~= "" and tostring(snap.name or ""):lower() == mine
        end)
    end
    local ok_bs, bis_search = pcall(require, 'bis_search')
    if ok_bs and bis_search and bis_search.slot_rec and snap and not snap._bis_search_skip then
        if not is_self then
            local hit = bis_search.slot_rec(snap, list_id, slot)
            if type(hit) == "table" and hit.status then
                local status = tostring(hit.status)
                if not M._BIS_SEARCH_STATUSES[status] then
                    status = (tonumber(hit.count) or 0) > 0 and "carried" or "missing"
                end
                local loc = tostring(hit.location or "")
                if loc == "" then
                    loc = status == "equipped" and "Equipped" or "Bags"
                end
                -- Single label for display (row_location used to join location/where → "Bags - Bags").
                local match = {
                    name = hit.name or entry.item,
                    where = loc,
                    slotname = loc,
                    location = loc,
                }
                return {
                    entry = entry,
                    have = status ~= "missing",
                    match = match,
                    status = status,
                    category = category,
                    from_bis_search = true,
                }
            end
        end
    end
    local row = bis.evaluate_entry(entry, snap)
    row.category = category
    -- A peer DoN ability row with no search answer and no spellbook in the
    -- snapshot is UNKNOWN, not missing (absent data is not "doesn't know").
    if not is_self and row.status == "missing" and type(entry.don_ability) == "table"
        and not M._snap_has_spell_data(snap) then
        row.status = "unknown"
        row.have = false
        row.unknown = true
    end
    return row
end

--- Evaluate the Nth DoN spell for a character's class (1-based). Past the end
--- of that class list returns a blank pad cell (not a shared-matrix miss).
function M.evaluate_spell_index(list_id, snap, spell_index, category)
    spell_index = tonumber(spell_index) or 0
    if spell_index < 1 or not is_don_spells_category(list_id, category) then
        return { category = category, empty = true, pad = true }
    end
    local DS = ensure_don_spells_mod()
    if not (DS and DS.spell_slots_for_class) then
        return { category = category, empty = true, pad = true }
    end
    local slots = DS.spell_slots_for_class(snap and snap.class)
    local slot = slots[spell_index]
    if not slot then
        return { category = category, empty = true, pad = true }
    end
    return M.evaluate_slot(list_id, snap, slot, category)
end

function M.find_link_need(snap, item_name, item_id)
    return M.find_announce_need(snap, item_name, item_id)
end

-- Announce path: static catalog reverse index (BiS-style) + O(1) snapshot ownership
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

        for _, class_name in ipairs(class_names) do
            local slots = {}
            for _, cat in ipairs(list.categories or {}) do
                for _, slot in ipairs(category_slots(spec.id, cat, class_name, false)) do
                    slots[slot] = true
                end
            end
            for slot in pairs(slots) do
                local entry = M.resolve_entry(spec.id, class_name, slot)
                if entry then
                    local names = index_names(entry)
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

local function builtin_announce_list_refs(include_disabled)
    local out = {}
    for _, spec in ipairs(UI_LIST_BUTTONS) do
        if M.list(spec.id) and (include_disabled == true or M.list_announce_enabled(spec.id)) then
            out[#out + 1] = { kind = "catalog", id = spec.id }
        end
    end
    if #out > 0 then return out end
    local d = M.default_list_id()
    if d ~= "" and M.list(d) and (include_disabled == true or M.list_announce_enabled(d)) then
        return { { kind = "catalog", id = d } }
    end
    return out
end

local function norm_owner(s)
    return trim(s):lower()
end

announce_settings_sig = function()
    local disabled = SharedSettings.bisAnnounceDisabledLists or {}
    local parts = {}
    for k, v in pairs(disabled) do
        if v then parts[#parts + 1] = tostring(k) end
    end
    table.sort(parts)
    return table.concat(parts, ",")
end

function M.sync_compact_announce_settings(reason)
    local sig = announce_settings_sig()
    if compact_announce_settings_sig == nil then
        compact_announce_settings_sig = sig
        return false
    end
    if sig == compact_announce_settings_sig then return false end
    compact_announce_settings_sig = sig
    M.invalidate_compact_announce_rules(reason or "announce-settings")
    return true
end

function M.announce_list_specs()
    local specs = {}
    for _, spec in ipairs(M.ui_list_specs()) do
        if not spec.special and M.list(spec.id) then
            specs[#specs + 1] = { id = spec.id, label = spec.label }
        end
    end
    return specs
end

M.builtin_announce_list_specs = M.announce_list_specs

-- Prefer the current zone list first; fall back to raid BiS lists for line text.
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
    return table.concat({
        tostring(class_name or ""),
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
    if key ~= "" and not name_is_id_only(display_name) then
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
        for _, slot in ipairs(category_slots(list_id, cat, class_name, false)) do
            local entry = M.resolve_entry(list_id, class_name, slot)
            if entry then
                for _, name in ipairs(index_names(entry)) do
                    name = trim(name)
                    if name ~= "" then add_catalog_entry(idx, list_id, list_name, entry, name) end
                end
            end
        end
    end
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
        if not work.cat_slots then
            work.cat_slots = category_slots(work.id, cat, build.class_name, false)
        end
        local slot = work.cat_slots[work.slot_i]
        if slot then
            local entry = M.resolve_entry(work.id, build.class_name, slot)
            if entry then add_entry_names(build.idx, work.id, work.list_name, entry) end
            work.slot_i = work.slot_i + 1
            return true
        end
        work.cat_i = work.cat_i + 1
        work.slot_i = 1
        work.cat_slots = nil
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

-- Same ownership answer as the BiS grid cell for this list/slot (peers use
-- bis_search when present; local uses live FindItem; else Store snapshot).
local function paint_row_for_rec(rec, snap, opts)
    local entry = rec and rec.entry
    if not entry then return nil end
    local list_id = tostring(rec.list_id or "")
    local slot = trim(entry.slot or "")
    if list_id ~= "" and slot ~= "" and M.list(list_id) then
        local row = M.evaluate_slot(list_id, snap, slot, entry.group or entry.category)
        if row and not row.empty then return row end
    end
    return bis.evaluate_entry(entry, snap, opts)
end

local function need_from_rec(rec, snap, opts)
    opts = type(opts) == "table" and opts or {}
    local row = paint_row_for_rec(rec, snap, opts)
    if not row or row.empty or row.status ~= "missing" then return nil end
    -- Local just-looted safety when live column was skipped.
    if opts.skip_live ~= true and is_local_snap(snap) and bis.live_own_item(rec.entry, rec.item_name, nil) then
        return nil
    end
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

-- Budgeted warm helper: loads disk dcat when present, otherwise advances the
-- async direct build. Safe for announcer.tick / M.warm — not for unbounded
-- sync rebuilds on a chat frame.
function M.direct_catalog_prefetch(class_name, owner_name, budget_ms)
    budget_ms = math.max(5, tonumber(budget_ms) or 50)
    return M.tick_direct_build(class_name, owner_name, os.clock() + budget_ms / 1000)
end

-- ===== Disk cache for direct catalogs =================================== --
-- Catalogs depend only on the BiS data + announce settings + user lists,
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

-- Runtime validation is intentionally O(1): build tooling and the independent
-- drift test recompute this hash; production compares embedded strings only.
local catalog_fingerprint_cache
local function catalog_fingerprint()
    if catalog_fingerprint_cache then return catalog_fingerprint_cache end
    catalog_fingerprint_cache = tostring(load_catalog("validation").content_hash or "")
    return catalog_fingerprint_cache
end

-- User list CONTENT is not in the sig (only ids); stamp their updated fields
-- so edits invalidate the disk cache.
local function user_lists_stamp(class_name, owner_name)
    return ""
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
    st = {
        sig = sig,
        class_name = class_name,
        class_shareable = true,
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
        for _, name in ipairs(index_names(ne)) do
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
        st.cat_slots = nil
        return true
    end
    if not st.cat_slots or st.cat_slots_i ~= st.cat_i then
        st.cat_slots = category_slots(ref.id, cat, st.class_name, false)
        st.cat_slots_i = st.cat_i
    end
    local slot = st.cat_slots[st.slot_i]
    if not slot then
        st.cat_i = st.cat_i + 1
        st.slot_i = 1
        st.cat_slots = nil
        return true
    end
    local entry = M.resolve_entry(ref.id, st.class_name, slot)
    if entry then
        local list_name = M.list_label(ref.id)
        for _, name in ipairs(index_names(entry)) do
            name = trim(name)
            if name ~= "" then
                add_catalog_entry(st.idx, ref.id, list_name, entry, name)
            end
        end
    end
    st.slot_i = st.slot_i + 1
    return true
end

-- Advance the build for (class, owner). At most one atomic unit per call:
-- catalog loadfile, dcat loadfile, user-list load_all, or one list/slot step.
-- Returns the finished idx, or nil while still building.
function M.tick_direct_build(class_name, owner_name, deadline)
    class_name = class_key(class_name or "")
    owner_name = trim(owner_name or "")
    if not M.catalog_loaded() then
        diag.time("needs.unit.load_catalog", function()
            M.warm_catalog()
        end)
        diag.count("needs.list_yield_op_limit")
        return nil
    end
    local sig = catalog_static_sig(class_name, owner_name)
    local done = direct_catalogs[sig]
    if done then
        direct_async[sig] = nil
        return done
    end
    local st = direct_async[sig]
    if not st then
        local csig = catalog_class_sig(class_name)
        local shared = direct_class_catalogs[csig]
        if shared then
            direct_catalogs[sig] = shared
            return shared
        end
        -- Disk cache: loadfile is an unbounded atomic unit (100-300ms+).
        -- Cache the result, then yield so this slice does not also start a
        -- list-step or a needs evaluation.
        local cached
        diag.time("needs.unit.load_dcat", function()
            cached = load_dcat(sig, class_name, owner_name)
        end)
        if cached then
            direct_catalogs[sig] = cached
            direct_class_catalogs[csig] = cached
            diag.count("needs.list_yield_op_limit")
            return nil
        end
        st = direct_build_state(class_name, owner_name, sig)
        -- loadfile miss is still I/O; do not also parse lists this slice.
        diag.count("needs.list_yield_op_limit")
        return nil
    end
    local ref = st.refs[st.ref_i]
    if ref and ref.kind == "user" and not st.user_list and not st.user_lists_loaded then
        diag.time("needs.unit.load_user_lists", function()
            bis.load_all()
        end)
        st.user_lists_loaded = true
        diag.count("needs.list_yield_op_limit")
        return nil
    end
    deadline = tonumber(deadline) or (os.clock() + 0.005)
    local steps_limit = math.max(1, math.floor(tonumber(cfg.CFG.needs_list_steps_per_slice) or 1))
    local steps = 0
    while steps < steps_limit do
        local more
        local step_t0 = os.clock()
        more = direct_build_step(st)
        local step_ms = (os.clock() - step_t0) * 1000
        if step_ms >= 2 then
            diag.sample("needs.unit.list_step", step_ms)
        end
        steps = steps + 1
        if more == nil then
            direct_catalogs[sig] = st.idx
            if st.class_shareable then
                direct_class_catalogs[catalog_class_sig(st.class_name)] = st.idx
            end
            direct_async[sig] = nil
            save_dcat(sig, st.idx, class_name, owner_name)
            return st.idx
        end
        if step_ms >= 8 then
            diag.count("needs.list_yield_budget")
            break
        end
        if os.clock() >= deadline then
            diag.count("needs.list_yield_budget")
            break
        end
    end
    if steps >= steps_limit then
        diag.count("needs.list_yield_op_limit")
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

-- Session memo for per-link list walks (class + item). Avoids re-walking every
-- announce-enabled list for each peer snap on the same loot link.
local function link_entry_memo_key(class_name, item_name, item_id)
    -- Always include the visible name when present. Id-only keys poisoned the
    -- memo when ParseItemLink returned a bad id shared across different links.
    item_id = tonumber(item_id) or 0
    local nk = norm_item_key(item_name)
    if nk ~= "" and item_id > 0 then
        return tostring(class_name or "") .. "\31name:" .. nk .. "\31id:" .. tostring(math.floor(item_id))
    end
    if item_id > 0 then
        return tostring(class_name or "") .. "\31id:" .. tostring(math.floor(item_id))
    end
    return tostring(class_name or "") .. "\31name:" .. nk
end

-- MQ keepLinks / self-link dumps contaminate the visible name with:
--   \x12hex\x12 frames, leading item-link hex, trailing quote/angle (`">`).
-- Paint must see a plain item name or every char returns no-row while the
-- console still pretty-prints the link (looks like "Desolate Black Sapphire").
-- Hex peel: greedy %x eats leading A-F of names ("Desolate" / "Divine").
local function strip_leading_item_hex(name)
    local s, e = name:find("^%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x+")
    if not s then return name end
    local hex = name:sub(s, e)
    local after = name:sub(e + 1)
    local max_peel = math.min(16, #hex - 24)
    local best, fallback = nil, nil
    for peel = 0, max_peel do
        local peeled = (peel == 0) and "" or hex:sub(#hex - peel + 1)
        local candidate = trim(peeled .. after)
        if candidate ~= "" and #candidate >= 3 and #candidate <= 96 and candidate:find("^%u") then
            fallback = fallback or candidate
            -- Keep the longest normal capitalized recovery. A greedy hex run
            -- can consume a complete A-F-only word, so the first plausible
            -- suffix ("Hoop") is not necessarily the item boundary ("Beaded").
            if candidate:find("^%u%l") then best = candidate end
        end
    end
    if best then return best end
    if fallback then return fallback end
    after = trim(after)
    if after ~= "" and after:find("^%u") then return after end
    return name
end

local function clean_link_item_name(name)
    name = trim(name or "")
    if name == "" then return "" end
    if name:find("\x12", 1, true) then
        name = name:gsub("\x12[^\x12]*\x12", " ")
        name = name:gsub("\x12", " ")
        name = trim(name)
        if name == "" then return "" end
    end
    name = strip_leading_item_hex(name)
    for _ = 1, 4 do
        local next = name
        next = next:gsub("^['\"`“”‘’]+", "")
        next = next:gsub("%s*[\"'`“”‘’]+%s*>?%s*$", "")
        next = next:gsub("%s*>%s*$", "")
        next = trim(next)
        if next == name then break end
        name = next
    end
    name = name:gsub("[\"'`“”‘’>]+$", "")
    name = trim(name)
    if name:match("^%x+$") and #name >= 16 then return "" end
    return name
end
M.clean_link_item_name = clean_link_item_name

-- BiS-shaped: for ONE linked item, walk announce-enabled lists for this
-- class and collect matching entries. Name matches are preferred over id-only
-- (corrupt ParseItemLink ids must not steal the first hit). No reverse-index
-- build (hitch-free on chat). Requires the BiS catalog already loaded.
local function collect_announce_entries_for_link(class_name, owner_name, item_name, item_id)
    class_name = class_key(class_name or "")
    owner_name = trim(owner_name or "")
    item_name = trim(item_name or "")
    item_id = tonumber(item_id) or 0
    if not class_name or class_name == "" or (item_name == "" and item_id <= 0) then return nil end
    if not M.catalog_loaded() then return nil end
    if not bis.link_matches_entry then return nil end

    local memo_key = link_entry_memo_key(class_name, item_name, item_id)
    local memo = link_entry_memo[memo_key]
    if memo ~= nil then
        return memo or nil
    end

    local name_hits, id_hits, seen = {}, {}, {}
    local function consider(list_id, list_name, entry)
        if not entry then return end
        local dedupe = tostring(list_id or "") .. "\31" .. tostring(entry.slot or entry.item or "")
        if seen[dedupe] then return end
        local by_name = false
        local lname = norm_item_key(item_name)
        if lname ~= "" then
            for _, name in ipairs(entry.names or { entry.item }) do
                if norm_item_key(name) == lname then by_name = true; break end
            end
        end
        local by_id = false
        if item_id > 0 then
            for _, id in ipairs(entry.ids or {}) do
                if tonumber(id) == item_id then by_id = true; break end
            end
        end
        if not by_name and not by_id then
            -- DoN teaching/pack aliases etc.
            if not bis.link_matches_entry(entry, item_name, item_id) then return end
            by_name = true
        end
        seen[dedupe] = true
        local rec = {
            list_id = list_id,
            list_name = list_name,
            entry = entry,
            item_name = direct_candidate_name(entry, item_name),
        }
        if by_name then
            name_hits[#name_hits + 1] = rec
        else
            id_hits[#id_hits + 1] = rec
        end
    end

    for _, ref in ipairs(M.lists_for_announce()) do
        local list_id = tostring(ref.id or "")
        local list = M.list(list_id)
        if list then
            local list_name = M.list_label(list_id)
            for _, cat in ipairs(list.categories or {}) do
                for _, slot in ipairs(category_slots(list_id, cat, class_name, false)) do
                    consider(list_id, list_name, M.resolve_entry(list_id, class_name, slot))
                end
            end
        end
    end

    if #name_hits == 0 and #id_hits == 0 then
        -- Do not memoize negatives (warm races / bad ids must not stick).
        return nil
    end
    local out = name_hits
    for _, rec in ipairs(id_hits) do out[#out + 1] = rec end
    link_entry_memo[memo_key] = out
    return out
end

-- When peer class is still unknown, match shared template/visible rows only
-- (fungal/augs/etc). Class-specific preanguish rows stay gated on a real class.
local function collect_template_announce_entries_for_link(item_name, item_id)
    item_name = clean_link_item_name(item_name)
    item_id = tonumber(item_id) or 0
    if item_name == "" and item_id <= 0 then return nil end
    if not M.catalog_loaded() or not bis.link_matches_entry then return nil end
    local memo_key = "template\31" .. link_entry_memo_key("", item_name, item_id)
    local memo = link_entry_memo[memo_key]
    if memo ~= nil then return memo or nil end

    local out, seen = {}, {}
    for _, ref in ipairs(M.lists_for_announce()) do
        local list_id = tostring(ref.id or "")
        local list = M.list(list_id)
        if list then
            local list_name = M.list_label(list_id)
            local bucket = list.template or list.visible
            if type(bucket) == "table" then
                for slot, raw in pairs(bucket) do
                    if type(raw) == "table" then
                        local entry = bis.normalize_entry(raw)
                        entry.slot = tostring(slot)
                        expand_fungal_chain(list, bucket, entry)
                        if list_id == "don" then
                            expand_don_clicky_chain(list, bucket, entry)
                            expand_don_shadow_chain(list, bucket, entry)
                        elseif list_id == "bagitems" then
                            expand_tattered_sack_chain(entry)
                        elseif list_id == "sebilis" then
                            M.expand_sebilis_forsaken_chain(entry)
                        end
                        if bis.link_matches_entry(entry, item_name, item_id) then
                            local dedupe = list_id .. "\31" .. tostring(slot)
                            if not seen[dedupe] then
                                seen[dedupe] = true
                                out[#out + 1] = {
                                    list_id = list_id,
                                    list_name = list_name,
                                    entry = entry,
                                    item_name = direct_candidate_name(entry, item_name),
                                }
                            end
                        end
                    end
                end
            end
        end
    end
    if #out == 0 then
        return nil
    end
    link_entry_memo[memo_key] = out
    return out
end

local function compact_rule(kind, list_id, list_name, entry, item_name, eval_path, raw)
    entry = entry or {}
    return {
        kind = kind,
        eval_path = eval_path,
        list_id = tostring(list_id or ""),
        list_name = tostring(list_name or ""),
        slot = tostring(entry.slot or ""),
        group = tostring(entry.group or ""),
        item_name = direct_candidate_name(entry, item_name),
        enabled = true,
        link_matched = true,
        matched_by = "catalog",
        raw_item = raw and (raw.item or raw.name) or nil,
        entry = {
            item = entry.item,
            names = entry.names,
            ids = entry.ids,
            slot = entry.slot,
            group = entry.group,
            spell = entry.spell,
            spells = entry.spells,
            spell_ids = entry.spell_ids,
        },
    }
end

local function compact_cell_alts(raw, entry)
    local cell = trim((raw and (raw.item or raw.name)) or (entry and entry.item) or "")
    local alts = {}
    if cell == "" then return alts end
    for alt in cell:gmatch("[^/]+") do
        alt = trim(alt)
        if alt ~= "" then alts[#alts + 1] = alt end
    end
    if #alts == 0 then alts[1] = cell end
    return alts
end

local function compact_names_hit(entry, item_name, item_id, raw)
    if entry and bis.link_matches_entry(entry, item_name, item_id) then return true end
    local link_norm = norm_item_key(item_name)
    for _, alt in ipairs(compact_cell_alts(raw, entry)) do
        if link_norm ~= "" and norm_item_key(alt) == link_norm then return true end
        if entry and bis.link_matches_entry({ item = alt, names = { alt }, ids = entry.ids or {} }, item_name, item_id) then
            return true
        end
    end
    return false
end

local function compact_candidate_key(rule)
    local entry = rule and rule.entry or {}
    return table.concat({
        tostring(rule and rule.kind or ""),
        tostring(rule and rule.list_id or ""),
        tostring(entry.slot or rule and rule.slot or ""),
        tostring(entry.item or rule and rule.item_name or ""),
    }, "\31")
end

local function compact_index_candidate(prepared, rule, raw)
    if not rule then return end
    local idx = #prepared.candidates + 1
    prepared.candidates[idx] = rule
    prepared.keys[rule] = compact_candidate_key(rule)

    local function add_name(name)
        local key = norm_item_key(name)
        if key == "" then return end
        local list = prepared.by_name[key]
        if not list then
            list = {}
            prepared.by_name[key] = list
        end
        list[#list + 1] = rule
    end
    add_name(rule.item_name)
    add_name(rule.raw_item)
    local entry = rule.entry or {}
    add_name(entry.item)
    for _, name in ipairs(entry.names or {}) do add_name(name) end
    for _, alt in ipairs(compact_cell_alts(raw, entry)) do add_name(alt) end

    for _, id in ipairs(entry.ids or {}) do
        id = tonumber(id)
        if id and id > 0 then
            local list = prepared.by_id[id]
            if not list then
                list = {}
                prepared.by_id[id] = list
            end
            list[#list + 1] = rule
        end
    end
end

local function compact_prepare_key(class_name, owner_name)
    class_name = class_key(class_name or "") or ""
    owner_name = trim(owner_name or "")
    return table.concat({
        tostring(compact_rules_generation),
        tostring(class_name),
        tostring(owner_name):lower(),
    }, "\31")
end

local function compact_new_prepared(sig, class_name, owner_name)
    return {
        sig = sig,
        generation = compact_rules_generation,
        class_name = class_name or "",
        owner_name = owner_name or "",
        candidates = {},
        by_name = {},
        by_id = {},
        keys = {},
    }
end

local function compact_work_totals(work)
    if not work then return 0, 0, 0, 0 end
    local buckets_total = work.buckets and #work.buckets or 0
    local slots_total = work.slots and #work.slots or 0
    local entries_total = work.entries and #work.entries or 0
    return buckets_total, slots_total, entries_total
end

local function compact_build_detail(build)
    if not build then return "idle" end
    local work = build.work
    local ref = build.refs and build.refs[build.ref_i] or nil
    local buckets_total, slots_total, entries_total = compact_work_totals(work)
    local ref_id = (work and work.id) or (ref and ref.id) or ""
    local ref_kind = (work and work.kind) or (ref and ref.kind) or ""
    local age_ms = 0
    if build.started_wall_ms then
        age_ms = math.max(0, now_ms() - tonumber(build.started_wall_ms))
    elseif build.started_at then
        age_ms = math.max(0, (os.clock() - tonumber(build.started_at)) * 1000)
    end
    return string.format(
        "class=%s owner=%s gen=%s ref=%s:%s ref_i=%s/%s bucket_i=%s/%s slot_i=%s/%s entry_i=%s/%s candidates=%s steps=%s age=%.0fms",
        tostring(build.class_name or ""),
        tostring(build.owner_name or ""),
        tostring(build.generation or compact_rules_generation),
        tostring(ref_kind or ""),
        tostring(ref_id or ""),
        tostring(build.ref_i or 0),
        tostring(build.refs and #build.refs or 0),
        tostring(work and work.bucket_i or 0),
        tostring(buckets_total or 0),
        tostring(work and work.slot_i or 0),
        tostring(slots_total or 0),
        tostring(work and work.entry_i or 0),
        tostring(entries_total or 0),
        tostring(build.prepared and build.prepared.candidates and #build.prepared.candidates or 0),
        tostring(build.steps or 0),
        age_ms)
end

local function compact_sample_build_progress(build)
    if not build then return end
    local work = build.work
    local buckets_total, slots_total, entries_total = compact_work_totals(work)
    local candidates = build.prepared and build.prepared.candidates and #build.prepared.candidates or 0
    local age_ms = build.started_wall_ms and math.max(0, now_ms() - tonumber(build.started_wall_ms))
        or (build.started_at and math.max(0, (os.clock() - tonumber(build.started_at)) * 1000) or 0)
    diag.sample("local_needs.prepared_build_ref_i", build.ref_i or 0)
    diag.sample("local_needs.prepared_build_refs_total", build.refs and #build.refs or 0)
    diag.sample("local_needs.prepared_build_bucket_i", work and work.bucket_i or 0)
    diag.sample("local_needs.prepared_build_buckets_total", buckets_total or 0)
    diag.sample("local_needs.prepared_build_slot_i", work and work.slot_i or 0)
    diag.sample("local_needs.prepared_build_slots_total", slots_total or 0)
    diag.sample("local_needs.prepared_build_user_entry_i", work and work.entry_i or 0)
    diag.sample("local_needs.prepared_build_user_entries_total", entries_total or 0)
    diag.sample("local_needs.prepared_build_candidates", candidates)
    diag.sample("local_needs.prepared_build_steps_total", build.steps or 0)
    diag.sample("local_needs.prepared_build_age_ms", age_ms)
    diag_context("local_needs.prepared_rule_build", compact_build_detail(build))
    diag_context("local_needs.prepared_build_tick", compact_build_detail(build))
end

local function compact_apply_expansions(list_id, list, bucket, entry, class_name)
    expand_fungal_chain(list, bucket, entry)
    if list_id == "jonas" then
        expand_jonas_hand_chain(list, bucket, entry)
    elseif list_id == "don" then
        expand_don_clicky_chain(list, bucket, entry)
        expand_don_shadow_chain(list, bucket, entry)
        expand_don_scales_chain(entry, class_name)
    elseif list_id == "bagitems" then
        expand_tattered_sack_chain(entry)
    elseif list_id == "sebilis" then
        M.expand_sebilis_forsaken_chain(entry)
    end
end

local function compact_make_refs(class_name, owner_name)
    local refs, seen = {}, {}
    local function add_ref(ref)
        local key = tostring(ref and ref.kind or "catalog") .. ":" .. tostring(ref and ref.id or "")
        if seen[key] then return end
        seen[key] = true
        refs[#refs + 1] = ref
    end
    for _, ref in ipairs(M.lists_for_announce()) do add_ref(ref) end
    return refs
end

local function compact_begin_ref_work(build, ref)
    local work = {
        ref_i = build.ref_i,
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
        work.list = list
        work.list_name = M.list_label(work.id)
        local buckets = {}
        local class_bucket = build.class_name and list.classes and list.classes[build.class_name] or nil
        if type(class_bucket) == "table" then buckets[#buckets + 1] = { bucket = class_bucket, class_bucket = class_bucket } end
        if type(list.template) == "table" then buckets[#buckets + 1] = { bucket = list.template, class_bucket = class_bucket } end
        if type(list.visible) == "table" then buckets[#buckets + 1] = { bucket = list.visible, class_bucket = class_bucket } end
        work.buckets = buckets
        work.bucket_i = 1
        work.slots = nil
        work.slot_i = 1
        work.seen_slot = {}
    end
    return work
end

local function compact_finish_ref_work(build)
    diag.event("local_needs.prepared_ref_complete", compact_build_detail(build))
    build.work = nil
    build.ref_i = build.ref_i + 1
end

local function compact_finish_build(build)
    local detail = compact_build_detail(build)
    compact_rule_cache[build.sig] = build.prepared
    if compact_build == build then compact_build = nil end
    compact_build_seen[build.sig] = nil
    diag.count("local_needs.prepared_build_complete")
    diag.sample("local_needs.prepared_generation", build.generation)
    diag.sample("local_needs.prepared_rule_count", #(build.prepared.candidates or {}))
    diag.sample("local_needs.prepared_build_complete_age_ms",
        build.started_wall_ms and math.max(0, now_ms() - tonumber(build.started_wall_ms)) or 0)
    diag.event("local_needs.prepared_build_complete", detail)
end

local function compact_step_build(build)
    build.steps = (tonumber(build.steps) or 0) + 1
    local ref = build.refs[build.ref_i]
    if not ref then
        compact_finish_build(build)
        return false
    end
    if not build.work or build.work.ref_i ~= build.ref_i then
        build.work = compact_begin_ref_work(build, ref)
    end
    local work = build.work
    if not work or work.done then
        compact_finish_ref_work(build)
        return true
    end

    if work.kind == "user" then
        local raw = work.entries and work.entries[work.entry_i]
        if not raw then
            compact_finish_ref_work(build)
            return true
        end
        local entry = bis.normalize_entry(raw)
        compact_index_candidate(build.prepared,
            compact_rule("user", work.id, work.list_name, entry, entry.item, "user_entry", entry),
            entry)
        work.entry_i = work.entry_i + 1
        return true
    end

    while true do
        local bucket_rec = work.buckets and work.buckets[work.bucket_i]
        if not bucket_rec then
            compact_finish_ref_work(build)
            return true
        end
        if not work.slots then
            work.slots = {}
            for slot, raw in pairs(bucket_rec.bucket or {}) do
                work.slots[#work.slots + 1] = { slot = tostring(slot or ""), raw = raw }
            end
            table.sort(work.slots, function(a, b) return tostring(a.slot) < tostring(b.slot) end)
            work.slot_i = 1
        end
        local rec = work.slots[work.slot_i]
        if rec then
            work.slot_i = work.slot_i + 1
            if rec.slot ~= "" and not work.seen_slot[rec.slot] and type(rec.raw) == "table" then
                work.seen_slot[rec.slot] = true
                local entry = bis.normalize_entry(rec.raw)
                entry.slot = rec.slot
                compact_apply_expansions(work.id, work.list, bucket_rec.class_bucket or bucket_rec.bucket, entry, build.class_name)
                compact_index_candidate(build.prepared,
                    compact_rule("builtin", work.id, work.list_name, entry, entry.item, "built_in_slot", rec.raw),
                    rec.raw)
            end
            return true
        end
        work.bucket_i = work.bucket_i + 1
        work.slots = nil
        work.slot_i = 1
    end
end

local function compact_start_build(class_name, owner_name, sig)
    compact_build = {
        sig = sig,
        generation = compact_rules_generation,
        class_name = class_name,
        owner_name = owner_name,
        refs = compact_make_refs(class_name, owner_name),
        ref_i = 1,
        prepared = compact_new_prepared(sig, class_name, owner_name),
        started_at = os.clock(),
        started_wall_ms = now_ms(),
        steps = 0,
    }
    compact_build_seen[sig] = nil
    diag.count("local_needs.prepared_build_queued")
    diag.sample("local_needs.prepared_generation", compact_rules_generation)
    diag.sample("local_needs.prepared_build_refs_total", compact_build.refs and #compact_build.refs or 0)
    diag.event("local_needs.prepared_build_start", compact_build_detail(compact_build))
end

function M.request_compact_announce_rules(snap, reason)
    if not snap or not M.catalog_loaded() then return false, "not-ready" end
    if compact_announce_settings_sig == nil then
        compact_announce_settings_sig = announce_settings_sig()
    end
    local class_name = class_key(snap.class or "")
    local owner_name = trim(snap.name or "")
    local sig = diag.time("local_needs.prepared_cache_key", function()
        return compact_prepare_key(class_name, owner_name)
    end)
    if compact_rule_cache[sig] then return true, "ready" end
    if compact_build and compact_build.sig == sig then return false, "building" end
    if not compact_build_seen[sig] then
        compact_build_queue[#compact_build_queue + 1] = {
            sig = sig,
            class_name = class_name,
            owner_name = owner_name,
            generation = compact_rules_generation,
            reason = tostring(reason or "request"),
        }
        compact_build_seen[sig] = true
        diag.count("local_needs.prepared_generation_requested")
        diag.sample("local_needs.prepared_generation", compact_rules_generation)
    end
    return false, "queued"
end

function M.prepare_compact_announce_rules(snap)
    if not snap then return nil, "no-snap", { cache = "miss" } end
    if not M.catalog_loaded() or not bis.link_matches_entry then
        return nil, "no-catalog", { cache = "miss" }
    end
    if compact_announce_settings_sig == nil then
        compact_announce_settings_sig = announce_settings_sig()
    end

    local class_name = class_key(snap.class or "")
    local owner_name = trim(snap.name or "")
    local sig = diag.time("local_needs.prepared_cache_key", function()
        return compact_prepare_key(class_name, owner_name)
    end)
    local cached = diag.time("local_needs.prepared_cache_lookup", function()
        return compact_rule_cache[sig]
    end)
    if cached then
        diag.count("local_needs.prepared_rule_cache_hit")
        return cached, "ok", { cache = "hit", sig = sig, candidate_count = #(cached.candidates or {}) }
    end
    diag.count("local_needs.prepared_rule_cache_miss")
    M.request_compact_announce_rules(snap, "link-miss")
    return nil, "not-ready", {
        cache = "miss",
        sig = sig,
        generation = compact_rules_generation,
        candidate_count = 0,
        not_ready = true,
    }
end

function M.tick_compact_announce_rules(budget_ms, max_steps)
    if not M.catalog_loaded() then return false end
    budget_ms = tonumber(budget_ms) or 4
    max_steps = tonumber(max_steps) or 8
    local deadline = os.clock() + math.max(0.001, budget_ms / 1000)
    local steps = 0
    while os.clock() < deadline and steps < max_steps do
        if not compact_build then
            local next_req = table.remove(compact_build_queue, 1)
            if not next_req then break end
            if next_req.generation == compact_rules_generation and not compact_rule_cache[next_req.sig] then
                compact_start_build(next_req.class_name, next_req.owner_name, next_req.sig)
            else
                compact_build_seen[next_req.sig] = nil
            end
        end
        if not compact_build then break end
        steps = steps + 1
        diag.time("local_needs.prepared_rule_build", function()
            compact_step_build(compact_build)
        end)
        if compact_build then
            diag.sample("local_needs.prepared_build_progress", compact_build.ref_i or 0)
            compact_sample_build_progress(compact_build)
        end
    end
    if steps > 0 and compact_build then
        diag.event("local_needs.prepared_build_progress", compact_build_detail(compact_build))
    end
    return compact_build == nil and #compact_build_queue == 0
end

function M.compact_announce_rules_status()
    local work = compact_build and compact_build.work or nil
    local buckets_total, slots_total, entries_total = compact_work_totals(work)
    return {
        generation = compact_rules_generation,
        queue = #compact_build_queue,
        building = compact_build ~= nil,
        ref_i = compact_build and compact_build.ref_i or 0,
        refs_total = compact_build and #(compact_build.refs or {}) or 0,
        candidates = compact_build and #(compact_build.prepared and compact_build.prepared.candidates or {}) or 0,
        class_name = compact_build and compact_build.class_name or "",
        owner_name = compact_build and compact_build.owner_name or "",
        current_ref_id = (work and work.id) or "",
        current_ref_kind = (work and work.kind) or "",
        bucket_i = work and work.bucket_i or 0,
        buckets_total = buckets_total or 0,
        slot_i = work and work.slot_i or 0,
        slots_total = slots_total or 0,
        user_entry_i = work and work.entry_i or 0,
        user_entries_total = entries_total or 0,
        steps = compact_build and compact_build.steps or 0,
        age_ms = compact_build and compact_build.started_wall_ms
            and math.max(0, now_ms() - tonumber(compact_build.started_wall_ms)) or 0,
    }
end

local function compact_append_matches(out, seen, prepared, recs)
    for _, rule in ipairs(recs or {}) do
        local key = prepared.keys and prepared.keys[rule] or compact_candidate_key(rule)
        if not seen[key] then
            seen[key] = true
            out[#out + 1] = rule
        end
    end
end

-- Migration helper for local_needs shadow mode: discover compact linked-item
-- candidates from prepared rules. Preparation is stable for the character's
-- class/owner/list signature; the per-link path is name/id lookup plus a
-- conservative prepared-rule fallback for unusual equivalent rows.
function M.compact_announce_candidates_for_link(snap, item_name, item_id)
    if not snap then return {}, "no-snap", { cache = "miss", candidate_count = 0 } end
    item_name = clean_link_item_name(item_name)
    item_id = tonumber(item_id) or 0
    if item_name == "" and item_id <= 0 then return {}, "no-name", { cache = "miss", candidate_count = 0 } end
    local prepared, prep_reason, meta = M.prepare_compact_announce_rules(snap)
    meta = type(meta) == "table" and meta or {}
    if not prepared then
        meta.candidate_count = 0
        if meta.not_ready == true then
            diag.count("local_needs.prepared_not_ready")
            diag.event("local_needs.prepared_not_ready", string.format(
                "item=%s id=%s norm=%s class=%s owner=%s gen=%s",
                tostring(item_name):sub(1, 80),
                tostring(item_id),
                tostring(norm_item_key(item_name)):sub(1, 80),
                tostring(snap.class or ""),
                tostring(snap.name or ""),
                tostring(meta.generation or compact_rules_generation)))
        end
        return {}, prep_reason or "no-catalog", meta
    end
    diag.count("local_needs.prepared_ready")

    local out, seen = {}, {}
    local link_norm = norm_item_key(item_name)
    diag.time("local_needs.candidate_direct_lookup", function()
        if link_norm ~= "" then
            compact_append_matches(out, seen, prepared, prepared.by_name and prepared.by_name[link_norm])
        end
        if item_id > 0 then
            compact_append_matches(out, seen, prepared, prepared.by_id and prepared.by_id[item_id])
        end
    end)

    if #out == 0 and cfg.CFG.local_needs_shadow_fallback_scan == true then
        diag.count("local_needs.candidate_fallback_scans")
        diag.time("local_needs.candidate_fallback_scan", function()
            for _, rule in ipairs(prepared.candidates or {}) do
                if compact_names_hit(rule.entry, item_name, item_id, { item = rule.raw_item }) then
                    compact_append_matches(out, seen, prepared, { rule })
                end
            end
        end)
        if #out > 0 then meta.fallback = true end
    end

    meta.prepared_count = #(prepared.candidates or {})
    meta.candidate_count = #out
    if #out == 0 then
        diag.count("local_needs.candidate_direct_miss")
        diag.event("local_needs.candidate_direct_miss", string.format(
            "item=%s id=%s norm=%s class=%s owner=%s gen=%s prepared=%s",
            tostring(item_name):sub(1, 80),
            tostring(item_id),
            tostring(link_norm):sub(1, 80),
            tostring(snap.class or ""),
            tostring(snap.name or ""),
            tostring(prepared.generation or compact_rules_generation),
            tostring(meta.prepared_count or 0)))
        return out, "no-row", meta
    end
    return out, "ok", meta
end

-- Shared inverse compact rule index. This is the shadow path intended to
-- replace per-character compact preparation: static rules compile once per
-- semantic partition, then link handling does only by-id/by-name lookup plus
-- character applicability filtering.
local function shared_empty_partition(kind, name)
    return { kind = kind or "", name = name or "", by_id = {}, by_name = {}, rule_ids = {}, ready = false }
end

local function shared_empty_index(generation)
    return {
        generation = generation,
        common = shared_empty_partition("common", "common"),
        classes = {},
        rules = {},
        next_rule_id = 0,
        started_wall_ms = now_ms(),
    }
end

local function shared_stage()
    if shared_index_active and shared_index_active.generation == shared_index_generation then
        shared_index_stage = shared_index_active
        return shared_index_active
    end
    if shared_index_stage and shared_index_stage.generation == shared_index_generation then
        return shared_index_stage
    end
    shared_index_stage = shared_empty_index(shared_index_generation)
    return shared_index_stage
end

local function table_has_entries(t)
    if type(t) ~= "table" then return false end
    for _, _ in pairs(t) do return true end
    return false
end

local function shared_partition_key(kind, class_name)
    kind = tostring(kind or "")
    if kind == "class" then return "class:" .. tostring(class_key(class_name or "") or "") end
    return kind
end

local function shared_diag_partition_name(build)
    local partition = tostring(build and build.partition or "")
    if partition == "class" then
        local class_name = tostring(build and build.class_name or ""):lower():gsub("[^%w]+", "_")
        if class_name == "" then class_name = "unknown" end
        return "class_" .. class_name
    end
    if partition == "" then return "unknown" end
    return partition:gsub("[^%w]+", "_")
end

local function shared_build_context(build, phase, extra)
    build = type(build) == "table" and build or {}
    local cat = build.current_cat
    local cat_name = type(cat) == "table" and tostring(cat.name or "") or ""
    return string.format(
        "gen=%s partition=%s class=%s list=%s category=%s cat_i=%s slot_i=%s slot=%s entry_i=%s phase=%s rules=%s keys=%s steps=%s%s",
        tostring(build.generation or shared_index_generation),
        tostring(build.partition or ""),
        tostring(build.class_name or ""),
        tostring(build.current_list_id or ""),
        cat_name,
        tostring(build.cat_i or 0),
        tostring(build.slot_i or 0),
        tostring(build.current_slot or ""),
        tostring(build.entry_i or 0),
        tostring(phase or ""),
        tostring(build.part and build.part.rule_ids and #build.part.rule_ids or 0),
        tostring(build.match_keys or 0),
        tostring(build.steps or 0),
        extra and (" " .. tostring(extra)) or "")
end

local function shared_phase_time(build, phase, fn, extra)
    if not (cfg.CFG and cfg.CFG.local_needs_match_ref_deep_profile == true) then
        return fn()
    end
    local label = "local_needs.shared_phase." .. tostring(phase or "unknown"):gsub("[^%w_]+", "_")
    diag_context(label, shared_build_context(build, phase, extra))
    return diag.time(label, fn)
end

local shared_apply_expansions_measured

local function shared_artifact_count(build, name)
    if build then
        build[name] = (tonumber(build[name]) or 0) + 1
    end
end

local function shared_array_sig(t)
    if type(t) ~= "table" then return "" end
    local out = {}
    for i, v in ipairs(t) do out[#out + 1] = tostring(v or "") end
    return table.concat(out, "\30")
end

local function shared_raw_content_sig(raw)
    if type(raw) ~= "table" then return tostring(raw or "") end
    return table.concat({
        tostring(raw.item or raw.name or ""),
        tostring(raw.slot or ""),
        tostring(raw.group or ""),
        tostring(raw.source or ""),
        tostring(raw.spell or ""),
        shared_array_sig(raw.names),
        shared_array_sig(raw.ids),
        shared_array_sig(raw.spells),
        shared_array_sig(raw.spell_ids),
    }, "\29")
end

local function shared_copy_array(src)
    if type(src) ~= "table" then return nil end
    local out = {}
    for i, v in ipairs(src) do out[i] = v end
    return out
end

local function shared_copy_entry(src)
    src = type(src) == "table" and src or {}
    return {
        item = src.item,
        name = src.name,
        names = shared_copy_array(src.names) or {},
        ids = shared_copy_array(src.ids) or {},
        slot = src.slot,
        group = src.group,
        socket = src.socket,
        source = src.source,
        notes = src.notes,
        spell = src.spell,
        spells = shared_copy_array(src.spells) or {},
        spell_ids = shared_copy_array(src.spell_ids) or {},
        don_ability = src.don_ability,
        learned_from = src.learned_from,
    }
end

local function shared_compile_normalized_entry(raw)
    local entry
    if type(raw) == "table" then
        entry = shared_copy_entry(norm_entry_cached(raw))
    else
        entry = bis.normalize_entry(raw)
    end
    return entry
end

local function shared_builtin_artifact_key(list_id, slot, raw, bucket, class_name)
    list_id = tostring(list_id or "")
    slot = tostring(slot or "")
    class_name = class_key(class_name or "") or ""
    local class_variant = false
    if list_id == "don" then
        class_variant = true
    elseif class_name ~= "" and type(bucket) == "table" then
        class_variant = true
    end
    return table.concat({
        "builtin",
        list_id,
        slot,
        tostring(raw),
        tostring(bucket),
        class_variant and class_name or "",
        shared_raw_content_sig(raw),
    }, "\31"), class_variant
end

local function shared_user_artifact_key(list, raw, entry_i)
    return table.concat({
        "user",
        tostring(list and list.id or ""),
        tostring(entry_i or ""),
        tostring(raw),
        shared_raw_content_sig(raw),
    }, "\31"), false
end

local function shared_artifact_phase(build, phase, fn, extra)
    local label = "local_needs.shared_artifact." .. tostring(phase or "unknown"):gsub("[^%w_]+", "_")
    diag_context(label, shared_build_context(build, "artifact_" .. tostring(phase or "unknown"), extra))
    return diag.time(label, fn)
end

local function shared_artifact_compile_expansions(build, list_id, list, bucket, entry, class_name)
    return shared_artifact_phase(build, "compile_expansion", function()
        shared_apply_expansions_measured(build, list_id, list, bucket, entry, class_name)
        return entry
    end)
end

local function shared_partition(idx, kind, class_name)
    if not idx then return nil end
    if kind == "common" then return idx.common end
    if kind == "class" then
        class_name = class_key(class_name or "")
        if not class_name or class_name == "" then return nil end
        idx.classes[class_name] = idx.classes[class_name] or shared_empty_partition("class", class_name)
        return idx.classes[class_name]
    end
    return nil
end

local function shared_entry_from_keys(src)
    src = type(src) == "table" and src or {}
    return {
        item = trim(src.item or src.name or ""),
        names = src.names or {},
        ids = src.ids or {},
        slot = trim(src.slot or ""),
        group = trim(src.group or ""),
        spell = src.spell,
        spells = src.spells or {},
        spell_ids = src.spell_ids or {},
    }
end

local function shared_add_name(list, name)
    name = trim(name)
    if name == "" or name_is_id_only(name) then return end
    local key = norm_item_key(name)
    if key == "" then return end
    if not list._seen_names then list._seen_names = {} end
    if list._seen_names[key] then return end
    list._seen_names[key] = true
    list.names[#list.names + 1] = name
end

local function shared_add_id(list, id)
    id = tonumber(id)
    if not id or id <= 0 then return end
    id = math.floor(id)
    if not list._seen_ids then list._seen_ids = {} end
    if list._seen_ids[id] then return end
    list._seen_ids[id] = true
    list.ids[#list.ids + 1] = id
end

local function shared_add_spell_name(out, spell)
    spell = trim(spell)
    if spell == "" then return end
    if not out._seen_spell_names then out._seen_spell_names = {} end
    local key = norm_item_key(spell)
    if key ~= "" and not out._seen_spell_names[key] then
        out._seen_spell_names[key] = true
        out.spell_names[#out.spell_names + 1] = spell
    end
end

local function shared_keyset_from_entry(entry)
    entry = type(entry) == "table" and entry or {}
    local out = { names = {}, ids = {}, spell_names = {}, spell_ids = {} }
    shared_add_name(out, entry.item or entry.name)
    for _, name in ipairs(entry.names or {}) do shared_add_name(out, name) end
    for _, alt in ipairs(compact_cell_alts(entry, entry)) do shared_add_name(out, alt) end
    for _, id in ipairs(entry.ids or {}) do shared_add_id(out, id) end
    for _, spell in ipairs(entry.spells or {}) do shared_add_spell_name(out, spell) end
    shared_add_spell_name(out, entry.spell)
    for _, id in ipairs(entry.spell_ids or {}) do
        id = tonumber(id)
        if id and id > 0 then
            if not out._seen_spell_ids then out._seen_spell_ids = {} end
            if not out._seen_spell_ids[id] then
                out._seen_spell_ids[id] = true
                out.spell_ids[#out.spell_ids + 1] = id
            end
        end
    end
    out._seen_names, out._seen_ids, out._seen_spell_names, out._seen_spell_ids = nil, nil, nil, nil
    return out
end

local function shared_match_keys(list_id, raw_entry, satisfy_entry, class_name)
    local keys = shared_keyset_from_entry(raw_entry)
    if list_id == "fungal" then
        local expanded = shared_keyset_from_entry(satisfy_entry)
        for _, name in ipairs(expanded.names or {}) do shared_add_name(keys, name) end
        for _, id in ipairs(expanded.ids or {}) do shared_add_id(keys, id) end
    elseif list_id == "jonas" then
        local name_seen = keys._seen_names or {}
        keys._seen_names = name_seen
        add_jonas_aliases(keys, keys.names, name_seen)
        add_jonas_aliases_for_name(keys, raw_entry and raw_entry.item, name_seen)
    elseif list_id == "don" and type(satisfy_entry) == "table" and type(satisfy_entry.don_ability) == "table" then
        local ab = satisfy_entry.don_ability
        shared_add_name(keys, ab.display_name)
        shared_add_name(keys, ab.teaching_item_name)
        shared_add_name(keys, ab.source_name)
        shared_add_id(keys, ab.primary_teaching_item_id)
        shared_add_id(keys, ab.source_container_item_id)
        for _, id in ipairs(ab.alternate_teaching_item_ids or {}) do shared_add_id(keys, id) end
    end
    keys._seen_names, keys._seen_ids = nil, nil
    return keys
end

local function shared_satisfy_keys(entry)
    local keys = shared_keyset_from_entry(entry)
    for _, spell in ipairs(entry and entry.spells or {}) do shared_add_spell_name(keys, spell) end
    shared_add_spell_name(keys, entry and entry.spell)
    keys._seen_spell_names, keys._seen_spell_ids = nil, nil
    return keys
end

local function shared_compact_entry_from_keys(keys, fallback)
    keys = type(keys) == "table" and keys or {}
    fallback = type(fallback) == "table" and fallback or {}
    return {
        item = trim(fallback.item or fallback.name or (keys.names and keys.names[1]) or ""),
        names = keys.names or {},
        ids = keys.ids or {},
        slot = trim(fallback.slot or ""),
        group = trim(fallback.group or ""),
        spell = fallback.spell,
        spells = keys.spell_names or fallback.spells or {},
        spell_ids = keys.spell_ids or fallback.spell_ids or {},
    }
end

local function shared_compile_builtin_artifact(build, key, class_variant, list_id, list, list_name, slot, raw, bucket, class_name)
    diag.count("local_needs.shared_artifact.cache_miss")
    shared_artifact_count(build, "artifact_misses")
    if class_variant then
        diag.count("local_needs.shared_partition.artifact_class_variant")
        shared_artifact_count(build, "artifact_class_variants")
    end
    return shared_artifact_phase(build, "compile", function()
        local raw_entry = shared_artifact_phase(build, "compile_normalize", function()
            local entry = shared_compile_normalized_entry(raw)
            entry.slot = tostring(slot or "")
            entry.group = entry.group ~= "" and entry.group or ""
            if type(raw) == "table" then
                entry.source = raw.source
                entry.spell = raw.spell or entry.spell
                entry.spells = raw.spells or entry.spells
                entry.spell_ids = raw.spell_ids or entry.spell_ids
                entry.notes = raw.notes
                entry.don_ability = raw.don_ability
                entry.learned_from = raw.learned_from
            end
            return entry
        end)
        local satisfy_entry = shared_copy_entry(raw_entry)
        satisfy_entry = shared_artifact_compile_expansions(build, list_id, list, bucket, satisfy_entry, class_name)
        local match_keys = shared_artifact_phase(build, "compile_match_keys", function()
            return shared_match_keys(list_id, raw_entry, satisfy_entry, class_name)
        end)
        local satisfy_keys = shared_artifact_phase(build, "compile_satisfy_keys", function()
            return shared_satisfy_keys(satisfy_entry)
        end)
        shared_artifact_next_id = shared_artifact_next_id + 1
        local artifact = {
            artifact_id = tostring(shared_artifact_next_id),
            key = key,
            class_variant = class_variant == true,
            kind = "builtin",
            list_id = tostring(list_id or ""),
            list_name = tostring(list_name or ""),
            slot = tostring(slot or ""),
            group = tostring(satisfy_entry.group or raw_entry.group or ""),
            item_name = direct_candidate_name(raw_entry, raw_entry.item),
            match = shared_compact_entry_from_keys(match_keys, raw_entry),
            satisfy = shared_compact_entry_from_keys(satisfy_keys, satisfy_entry),
            entry = shared_compact_entry_from_keys(satisfy_keys, satisfy_entry),
        }
        shared_artifact_cache[key] = artifact
        return artifact
    end, class_variant and "class_variant=true" or nil)
end

local function shared_get_builtin_artifact(build, list_id, list, list_name, slot, raw, bucket, class_name)
    local key, class_variant = shared_builtin_artifact_key(list_id, slot, raw, bucket, class_name)
    local artifact = shared_artifact_cache[key]
    if artifact then
        diag.count("local_needs.shared_artifact.cache_hit")
        diag.count("local_needs.shared_partition.artifact_reused")
        shared_artifact_count(build, "artifact_hits")
        return artifact
    end
    return shared_compile_builtin_artifact(build, key, class_variant, list_id, list, list_name, slot, raw, bucket, class_name)
end

local function shared_compile_user_artifact(build, key, list, raw, entry_i)
    diag.count("local_needs.shared_artifact.cache_miss")
    shared_artifact_count(build, "artifact_misses")
    return shared_artifact_phase(build, "compile", function()
        local entry = shared_artifact_phase(build, "compile_normalize", function()
            return shared_compile_normalized_entry(raw)
        end)
        local match_keys = shared_artifact_phase(build, "compile_match_keys", function()
            return shared_keyset_from_entry(entry)
        end)
        local satisfy_keys = shared_artifact_phase(build, "compile_satisfy_keys", function()
            return shared_satisfy_keys(entry)
        end)
        shared_artifact_next_id = shared_artifact_next_id + 1
        local artifact = {
            artifact_id = tostring(shared_artifact_next_id),
            key = key,
            class_variant = false,
            kind = "user",
            list_id = tostring(list and list.id or ""),
            list_name = tostring(list and list.name or "BiS"),
            slot = tostring(entry.slot or ""),
            group = tostring(entry.group or ""),
            item_name = direct_candidate_name(entry, entry.item),
            match = shared_compact_entry_from_keys(match_keys, entry),
            satisfy = shared_compact_entry_from_keys(satisfy_keys, entry),
            entry = shared_compact_entry_from_keys(satisfy_keys, entry),
            _entry_i = entry_i,
        }
        shared_artifact_cache[key] = artifact
        return artifact
    end)
end

local function shared_get_user_artifact(build, list, raw, entry_i)
    local key = shared_user_artifact_key(list, raw, entry_i)
    local artifact = shared_artifact_cache[key]
    if artifact then
        diag.count("local_needs.shared_artifact.cache_hit")
        diag.count("local_needs.shared_partition.artifact_reused")
        shared_artifact_count(build, "artifact_hits")
        return artifact
    end
    return shared_compile_user_artifact(build, key, list, raw, entry_i)
end

local function shared_new_match_ref_id(idx)
    idx.next_ref_id = (tonumber(idx.next_ref_id) or 0) + 1
    idx.next_rule_id = idx.next_ref_id
    return tostring(idx.next_ref_id)
end

local function shared_raw_match_keys(raw, slot, list_id, build)
    raw = type(raw) == "table" and raw or {}
    local out = { names = {}, ids = {}, spell_names = {}, spell_ids = {} }
    shared_phase_time(build, "match_ref_direct_item", function()
        shared_add_name(out, raw.item or raw.name)
    end)
    shared_phase_time(build, "match_ref_raw_names", function()
        for _, name in ipairs(raw.names or {}) do shared_add_name(out, name) end
    end)
    shared_phase_time(build, "match_ref_slash_aliases", function()
        for _, alt in ipairs(compact_cell_alts(raw, { item = raw.item or raw.name, ids = raw.ids or {} })) do
            shared_add_name(out, alt)
        end
    end)
    shared_phase_time(build, "match_ref_raw_ids", function()
        for _, id in ipairs(raw.ids or {}) do shared_add_id(out, id) end
    end)

    local function has_raw_item_or_name()
        if trim(raw.item or raw.name) ~= "" then return true end
        return type(raw.names) == "table" and #raw.names > 0
    end

    list_id = tostring(list_id or "")
    if list_id == "fungal" then
        shared_phase_time(build, "match_ref_fungal_alias", function()
            local text = tostring((raw.item or raw.name or "") .. " " .. tostring(slot or ""))
            local slime = text:match("(%S+) Fungus of Suffering")
            if slime and slime ~= "" then
                shared_add_name(out, slime .. " Slime of Suffering")
                shared_add_name(out, "Base " .. slime .. " Slime of Suffering")
            end
            local bloom = text:match("Fungal Bloom of (.-)%s*%-")
                or text:match("Fungal Bloom of (.-)%s*%(")
                or text:match("Fungal Bloom of (.+)$")
            if bloom and trim(bloom) ~= "" then
                shared_add_name(out, "Noxious Bloom of " .. trim(bloom))
                shared_add_name(out, "Base Noxious Bloom of " .. trim(bloom))
            end
        end)
    elseif list_id == "jonas" then
        shared_phase_time(build, "match_ref_jonas_alias", function()
            local seen = out._seen_names or {}
            out._seen_names = seen
            add_jonas_aliases(out, out.names, seen)
            add_jonas_aliases_for_name(out, raw.item or raw.name, seen)
        end)
    elseif list_id == "don" and type(raw.don_ability) == "table" then
        shared_phase_time(build, "match_ref_don_teaching_alias", function()
            local ab = raw.don_ability
            shared_add_name(out, ab.display_name)
            shared_add_name(out, ab.teaching_item_name)
            shared_add_name(out, ab.source_name)
            shared_add_id(out, ab.primary_teaching_item_id)
            shared_add_id(out, ab.source_container_item_id)
            for _, id in ipairs(ab.alternate_teaching_item_ids or {}) do shared_add_id(out, id) end
        end)
    elseif list_id == "bagitems" then
        shared_phase_time(build, "match_ref_tattered_alias", function()
            local mat = TATTERED_SACK_MATERIALS[tostring(slot or "")]
            if mat then
                for name, row in pairs(TATTERED_SACK_MATERIALS) do
                    if row == mat then shared_add_name(out, name) end
                end
                if mat.id then shared_add_id(out, mat.id) end
            end
        end)
    elseif list_id == "sebilis" then
        shared_phase_time(build, "match_ref_sebilis_forsaken_alias", function()
            local mold = M.sebilis_forsaken_mold_for_slot(slot)
            local raw_item = tostring(raw.item or raw.name or "")
            local raw_group = tostring(raw.group or "")
            if mold and raw_item:lower():find("^forsaken ", 1, false)
                and (raw_group == "" or raw_group == "Forsaken Armor") then
                shared_add_name(out, mold.name)
                shared_add_id(out, mold.id)
            end
        end)
    end

    out._seen_names, out._seen_ids, out._seen_spell_names, out._seen_spell_ids = nil, nil, nil, nil
    if not has_raw_item_or_name() and #(out.ids or {}) == 0 then return nil end
    return out
end

local function shared_match_ref(idx, partition, ref, build)
    if not idx or not partition or not ref then return nil end
    local rid = shared_new_match_ref_id(idx)
    ref.rule_id = rid
    ref.ref_id = rid
    ref.generation = idx.generation
    shared_phase_time(build, "match_ref_table_insertion", function()
        idx.rules[rid] = ref
        partition.rule_ids[#partition.rule_ids + 1] = rid
    end)

    local function add_name(name)
        local key = norm_item_key(name)
        if key == "" then return end
        local list = partition.by_name[key]
        if not list then
            list = {}
            partition.by_name[key] = list
        end
        list[#list + 1] = rid
    end
    local function add_id(id)
        id = tonumber(id)
        if not id or id <= 0 then return end
        id = math.floor(id)
        local list = partition.by_id[id]
        if not list then
            list = {}
            partition.by_id[id] = list
        end
        list[#list + 1] = rid
    end

    shared_phase_time(build, "match_ref_by_name_indexing", function()
        for _, name in ipairs(ref.match and ref.match.names or {}) do add_name(name) end
    end)
    shared_phase_time(build, "match_ref_by_id_indexing", function()
        for _, id in ipairs(ref.match and ref.match.ids or {}) do add_id(id) end
    end)
    return rid
end

local function shared_index_rule(idx, partition, rule, build)
    if not idx or not partition or not rule then return nil end
    idx.next_rule_id = (tonumber(idx.next_rule_id) or 0) + 1
    local rid = tostring(idx.next_rule_id)
    rule.rule_id = rid
    rule.generation = idx.generation
    local function do_rule_table()
        idx.rules[rid] = rule
        partition.rule_ids[#partition.rule_ids + 1] = rid
    end
    if build then
        shared_phase_time(build, "rule_table_insertion", do_rule_table)
    else
        do_rule_table()
    end
    local function add_name(name)
        local key = norm_item_key(name)
        if key == "" then return end
        local list = partition.by_name[key]
        if not list then
            list = {}
            partition.by_name[key] = list
        end
        list[#list + 1] = rid
    end
    local function do_by_name()
        for _, name in ipairs(rule.match and rule.match.names or {}) do add_name(name) end
    end
    if build then
        shared_phase_time(build, "by_name_indexing", do_by_name)
    else
        do_by_name()
    end
    local function add_id(id)
        id = tonumber(id)
        if not id or id <= 0 then return end
        id = math.floor(id)
        local list = partition.by_id[id]
        if not list then
            list = {}
            partition.by_id[id] = list
        end
        list[#list + 1] = rid
    end
    local function do_by_id()
        for _, id in ipairs(rule.match and rule.match.ids or {}) do add_id(id) end
    end
    if build then
        shared_phase_time(build, "by_id_indexing", do_by_id)
    else
        do_by_id()
    end
    return rid
end

local function shared_builtin_raw_entry(list_id, list, class_name, slot)
    if list_id == "don" then
        local DS = ensure_don_spells_mod()
        if DS and DS.ability_for_slot and DS.bis_entry_for_ability then
            local ability = DS.ability_for_slot(class_name, slot)
            if ability then
                local raw = DS.bis_entry_for_ability(ability)
                raw.don_ability = ability
                raw.learned_from = DS.learned_from and DS.learned_from(ability) or nil
                return raw, nil
            end
            if DS.is_ability_slot and DS.is_ability_slot(slot) then return nil, "wrong-class-ability" end
        end
    end
    if not list then return nil, "no-list" end
    class_name = class_key(class_name or "")
    local class_bucket = class_name and list.classes and list.classes[class_name] or nil
    local raw = class_bucket and class_bucket[slot]
    local source_bucket = class_bucket
    if not raw and list.template then raw, source_bucket = list.template[slot], list.template end
    if not raw and list.visible then raw, source_bucket = list.visible[slot], list.visible end
    return raw, nil, class_bucket, source_bucket
end

shared_apply_expansions_measured = function(build, list_id, list, bucket, entry, class_name)
    shared_phase_time(build, "expand_fungal", function()
        expand_fungal_chain(list, bucket, entry)
    end)
    if list_id == "jonas" then
        shared_phase_time(build, "expand_jonas", function()
            expand_jonas_hand_chain(list, bucket, entry)
        end)
    elseif list_id == "don" then
        shared_phase_time(build, "expand_don_clicky", function()
            expand_don_clicky_chain(list, bucket, entry)
        end)
        shared_phase_time(build, "expand_don_shadow", function()
            expand_don_shadow_chain(list, bucket, entry)
        end)
        shared_phase_time(build, "expand_don_scales", function()
            expand_don_scales_chain(entry, class_name)
        end)
    elseif list_id == "bagitems" then
        shared_phase_time(build, "expand_tattered_sack", function()
            expand_tattered_sack_chain(entry)
        end)
    elseif list_id == "sebilis" then
        shared_phase_time(build, "expand_sebilis_forsaken", function()
            M.expand_sebilis_forsaken_chain(entry)
        end)
    end
end

local function shared_build_builtin_rule(build, list_id, list, list_name, slot)
    build.current_list_id = list_id
    build.current_slot = tostring(slot or "")
    local raw, _, class_bucket, source_bucket = shared_phase_time(build, "raw_entry_retrieval", function()
        return shared_builtin_raw_entry(list_id, list, build.class_name, slot)
    end)
    if type(raw) ~= "table" then return false end
    local match_keys = shared_phase_time(build, "match_ref_keys", function()
        return shared_raw_match_keys(raw, slot, list_id, build)
    end)
    if not match_keys then return false end
    local ref = shared_phase_time(build, "match_ref_construction", function()
        return {
        kind = "builtin",
        ref_kind = "match-ref",
        eval_path = build.partition == "common" and "shared_common" or "shared_class",
        partition = build.partition,
        list_id = tostring(list_id or ""),
        list_name = tostring(list_name or ""),
        category = type(build.current_cat) == "table" and tostring(build.current_cat.name or "") or "",
        slot = tostring(slot or ""),
        group = type(build.current_cat) == "table" and tostring(build.current_cat.name or "") or "",
        item_name = direct_candidate_name(raw, raw.item or raw.name),
        enabled = true,
        link_matched = true,
        matched_by = "shared-match-ref",
        classes = build.partition == "class" and { [build.class_name] = true } or nil,
        class_name = build.partition == "class" and build.class_name or nil,
        locator = {
            kind = "builtin",
            list_id = tostring(list_id or ""),
            class_name = build.partition == "class" and build.class_name or nil,
            slot = tostring(slot or ""),
        },
        match = shared_compact_entry_from_keys(match_keys, raw),
        }
    end)
    shared_match_ref(build.idx, build.part, ref, build)
    return true, #(match_keys.names or {}) + #(match_keys.ids or {})
end

local function shared_build_user_rule(build, list, raw, entry_i)
    if type(raw) ~= "table" then return false end
    build.current_list_id = tostring(list and list.id or build.list_id or "")
    build.current_slot = tostring(raw and raw.slot or "")
    local match_keys = shared_phase_time(build, "match_ref_keys", function()
        return shared_raw_match_keys(raw, raw.slot, "user", build)
    end)
    if not match_keys then return false end
    local owner = norm_owner(list.owner or "")
    local list_class = class_key(list.class or "")
    local ref = shared_phase_time(build, "match_ref_construction", function()
        return {
        kind = "user",
        ref_kind = "match-ref",
        eval_path = "shared_user",
        partition = "user",
        list_id = tostring(list.id or build.list_id or ""),
        list_name = tostring(list.name or "BiS"),
        category = "",
        slot = tostring(raw.slot or ""),
        group = tostring(raw.group or ""),
        item_name = direct_candidate_name(raw, raw.item or raw.name),
        enabled = true,
        link_matched = true,
        matched_by = "shared-match-ref",
        owner = owner ~= "" and owner or nil,
        user_class = list_class ~= "" and list_class or nil,
        user_shared = owner == "" and list_class == "",
        locator = {
            kind = "user",
            list_id = tostring(list.id or build.list_id or ""),
            entry_i = tonumber(entry_i) or 0,
        },
        match = shared_compact_entry_from_keys(match_keys, raw),
        }
    end)
    shared_match_ref(build.idx, build.part, ref, build)
    return true, #(match_keys.names or {}) + #(match_keys.ids or {})
end

local function shared_partition_complete(build)
    local part = build.part
    if part then part.ready = true end
    local class_pending = false
    for key, _ in pairs(shared_index_seen or {}) do
        if tostring(key):find("^class:", 1, false) then class_pending = true; break end
    end
    if build.idx and build.idx.common and build.idx.common.ready == true
        and (build.partition == "class" or not class_pending) then
        shared_index_active = build.idx
        shared_index_stage = build.idx
    end
    shared_index_build = nil
    shared_index_seen[shared_partition_key(build.partition, build.class_name)] = nil
    local elapsed = build.started_wall_ms and math.max(0, now_ms() - build.started_wall_ms) or 0
    local part_name = shared_diag_partition_name(build)
    diag.count("local_needs.shared_index_build_complete")
    diag.count("local_needs.shared_index_build_complete." .. part_name)
    diag.sample("local_needs.shared_index_generation", build.generation)
    diag.sample("local_needs.shared_index_rules_compiled", #(part and part.rule_ids or {}))
    diag.sample("local_needs.shared_index_build_steps", build.steps or 0)
    diag.sample("local_needs.shared_index_build_elapsed_ms", elapsed)
    diag.sample("local_needs.shared_index." .. part_name .. ".rules", #(part and part.rule_ids or {}))
    diag.sample("local_needs.shared_index." .. part_name .. ".keys", build.match_keys or 0)
    diag.sample("local_needs.shared_index." .. part_name .. ".steps", build.steps or 0)
    diag.sample("local_needs.shared_index." .. part_name .. ".elapsed_ms", elapsed)
    diag.sample("local_needs.shared_index." .. part_name .. ".match_refs", #(part and part.rule_ids or {}))
    diag.event("local_needs.shared_index_build_complete", string.format(
        "gen=%s partition=%s class=%s match_refs=%s keys=%s steps=%s elapsed=%.0fms",
        tostring(build.generation), tostring(build.partition), tostring(build.class_name or ""),
        tostring(#(part and part.rule_ids or {})), tostring(build.match_keys or 0),
        tostring(build.steps or 0), elapsed))
end

local function shared_start_build(req)
    local idx = shared_stage()
    local part = shared_partition(idx, req.partition, req.class_name)
    if not part then return false end
    shared_index_build = {
        generation = shared_index_generation,
        idx = idx,
        part = part,
        partition = req.partition,
        class_name = class_key(req.class_name or "") or "",
        list_i = 1,
        cat_i = 1,
        slot_i = 1,
        entry_i = 1,
        steps = 0,
        match_keys = 0,
        started_wall_ms = now_ms(),
        refs = {},
    }
    shared_index_build.refs = shared_phase_time(shared_index_build, "announce_list_refs", function()
        return M.lists_for_announce()
    end)
    local part_name = shared_diag_partition_name(shared_index_build)
    diag.count("local_needs.shared_index_build_start")
    diag.count("local_needs.shared_index_build_start." .. part_name)
    diag.sample("local_needs.shared_index_generation", shared_index_generation)
    diag.event("local_needs.shared_index_build_start", string.format(
        "gen=%s partition=%s class=%s",
        tostring(shared_index_generation), tostring(req.partition), tostring(req.class_name or "")))
    return true
end

local function shared_build_step(build)
    build.steps = (tonumber(build.steps) or 0) + 1
    if build.partition == "common" or build.partition == "class" then
        while true do
            local ref = shared_phase_time(build, "ref_lookup", function()
                return (build.refs or {})[build.list_i]
            end)
            if not ref then shared_partition_complete(build); return false end
            local list_id = tostring(ref.id or "")
            build.current_list_id = list_id
            local list, has_classes, is_common_list = shared_phase_time(build, "category_list_class_resolution", function()
                local l = M.list(list_id)
                local hc = l and table_has_entries(l.classes)
                return l, hc, l and not hc
            end)
            if not list or (build.partition == "common" and not is_common_list)
                or (build.partition == "class" and is_common_list) then
                shared_phase_time(build, "match_ref_cursor_advance", function()
                    build.list_i = build.list_i + 1
                    build.cat_i, build.slot_i = 1, 1
                end)
            else
                local cat = shared_phase_time(build, "category_lookup", function()
                    return (list.categories or {})[build.cat_i]
                end)
                build.current_cat = cat
                if not cat then
                    shared_phase_time(build, "match_ref_cursor_advance", function()
                        build.list_i = build.list_i + 1
                        build.cat_i, build.slot_i = 1, 1
                    end)
                else
                    if not build.cat_slots or build.cat_slots_i ~= build.cat_i then
                        build.cat_slots = shared_phase_time(build, "slot_enumeration", function()
                            return category_slots(list_id, cat,
                                build.partition == "class" and build.class_name or nil, false)
                        end)
                        build.cat_slots_i = build.cat_i
                    end
                    local slot = shared_phase_time(build, "slot_lookup", function()
                        return build.cat_slots and build.cat_slots[build.slot_i]
                    end)
                    build.current_slot = tostring(slot or "")
                    if not slot then
                        shared_phase_time(build, "match_ref_cursor_advance", function()
                            build.cat_i = build.cat_i + 1
                            build.slot_i = 1
                            build.cat_slots = nil
                        end)
                    else
                        local ok, key_count = shared_build_builtin_rule(build, list_id, list, M.list_label(list_id), slot)
                        if ok then build.match_keys = build.match_keys + (tonumber(key_count) or 0) end
                        shared_phase_time(build, "match_ref_cursor_advance", function()
                            build.slot_i = build.slot_i + 1
                        end)
                        return true
                    end
                end
            end
        end
    end

    if build.partition == "user" then
        while true do
            local rec = shared_phase_time(build, "user_list_lookup", function()
                return (build.user_lists or {})[build.list_i]
            end)
            if not rec then shared_partition_complete(build); return false end
            local list = rec.list
            build.current_list_id = tostring(rec.id or "")
            build.current_cat = nil
            if not list or not M.list_announce_enabled(rec.id) then
                shared_phase_time(build, "match_ref_cursor_advance", function()
                    build.list_i = build.list_i + 1
                    build.entry_i = 1
                end)
            else
                local raw = shared_phase_time(build, "user_entry_lookup", function()
                    return (list.entries or {})[build.entry_i]
                end)
                build.current_slot = tostring(raw and raw.slot or "")
                if not raw then
                    shared_phase_time(build, "match_ref_cursor_advance", function()
                        build.list_i = build.list_i + 1
                        build.entry_i = 1
                    end)
                else
                    local ok, key_count = shared_build_user_rule(build, list, raw, build.entry_i)
                    if ok then build.match_keys = build.match_keys + (tonumber(key_count) or 0) end
                    shared_phase_time(build, "match_ref_cursor_advance", function()
                        build.entry_i = build.entry_i + 1
                    end)
                    return true
                end
            end
        end
    end
    shared_partition_complete(build)
    return false
end

local function shared_should_emit_progress(build)
    local steps = tonumber(build and build.steps) or 0
    return steps == 1 or (steps % 10) == 0
end

local function shared_partition_is_ready(idx, kind, class_name)
    local part = shared_partition(idx, kind, class_name)
    return part and part.ready == true
end

function M.request_shared_compact_rule_index(class_name, owner_name, reason)
    if not M.catalog_loaded() then return false, "no-catalog" end
    local idx = shared_stage()
    local requested = {
        { partition = "common" },
    }
    class_name = class_key(class_name or "")
    if class_name and class_name ~= "" then
        requested[#requested + 1] = { partition = "class", class_name = class_name }
    end
    local all_ready = true
    for _, req in ipairs(requested) do
        local key = shared_partition_key(req.partition, req.class_name)
        if not shared_partition_is_ready(idx, req.partition, req.class_name) then
            all_ready = false
            if not shared_index_seen[key] then
                shared_index_queue[#shared_index_queue + 1] = req
                shared_index_seen[key] = true
                diag.count("local_needs.shared_index_requested")
                diag.event("local_needs.shared_index_requested", string.format(
                    "gen=%s partition=%s class=%s reason=%s",
                    tostring(shared_index_generation), tostring(req.partition),
                    tostring(req.class_name or ""), tostring(reason or "request")))
            end
        end
    end
    return all_ready, all_ready and "ready" or "queued"
end

function M.tick_shared_compact_rule_index(budget_ms, max_steps)
    if not M.catalog_loaded() then return false end
    budget_ms = tonumber(budget_ms) or 4
    max_steps = tonumber(max_steps) or 8
    local deadline = os.clock() + math.max(0.001, budget_ms / 1000)
    local steps = 0
    while os.clock() < deadline and steps < max_steps do
        if not shared_index_build then
            local req = table.remove(shared_index_queue, 1)
            if not req then break end
            shared_start_build(req)
        end
        if not shared_index_build then break end
        steps = steps + 1
        diag.time("local_needs.shared_index_build_step", function()
            diag.time("local_needs.match_ref.step_work", function()
                shared_build_step(shared_index_build)
            end)
        end)
        if shared_index_build then
            local build = shared_index_build
            if shared_should_emit_progress(build) then
                local part = build.part
                local elapsed = build.started_wall_ms and math.max(0, now_ms() - build.started_wall_ms) or 0
                local part_name = shared_diag_partition_name(build)
                diag.time("local_needs.match_ref.step_diag", function()
                    diag.sample("local_needs.shared_index_build_progress", build.steps or 0)
                    diag.sample("local_needs.shared_index_rules_compiled", #(part and part.rule_ids or {}))
                    diag.sample("local_needs.shared_index_match_keys_indexed", build.match_keys or 0)
                    diag.sample("local_needs.shared_index_build_elapsed_ms", elapsed)
                    diag.sample("local_needs.shared_index." .. part_name .. ".progress", build.steps or 0)
                    diag.sample("local_needs.shared_index." .. part_name .. ".rules_current", #(part and part.rule_ids or {}))
                    diag.sample("local_needs.shared_index." .. part_name .. ".keys_current", build.match_keys or 0)
                    diag.sample("local_needs.shared_index." .. part_name .. ".elapsed_current_ms", elapsed)
                    diag.sample("local_needs.shared_index." .. part_name .. ".match_refs_current", #(part and part.rule_ids or {}))
                    diag.event("local_needs.shared_index_build_progress", string.format(
                        "gen=%s partition=%s class=%s match_refs=%s keys=%s steps=%s elapsed=%.0fms",
                        tostring(build.generation), tostring(build.partition), tostring(build.class_name or ""),
                        tostring(#(part and part.rule_ids or {})), tostring(build.match_keys or 0),
                        tostring(build.steps or 0), elapsed))
                end)
            end
        end
    end
    return shared_index_build == nil and #shared_index_queue == 0
end

local function shared_add_rule_ids(out, seen, ids)
    for _, rid in ipairs(ids or {}) do
        rid = tostring(rid or "")
        if rid ~= "" and not seen[rid] then
            seen[rid] = true
            out[#out + 1] = rid
        end
    end
end

local function shared_lookup_partition(part, item_name, item_id, out, seen)
    if not part or part.ready ~= true then return end
    item_id = tonumber(item_id) or 0
    if item_id > 0 then
        shared_add_rule_ids(out, seen, part.by_id and part.by_id[math.floor(item_id)])
    end
    local key = norm_item_key(item_name)
    if key ~= "" then
        shared_add_rule_ids(out, seen, part.by_name and part.by_name[key])
    end
end

local function shared_rule_applies(rule, snap)
    if not rule then return false end
    local class_name = class_key(snap and snap.class or "")
    if type(rule.classes) == "table" and not rule.classes[class_name or ""] then return false end
    if rule.kind == "user" then
        local owner = norm_owner(snap and snap.name or "")
        if rule.owner and rule.owner ~= "" and owner ~= "" and rule.owner == owner then return true end
        if rule.user_class and rule.user_class ~= "" and class_name ~= "" and rule.user_class == class_name then return true end
        return rule.user_shared == true
    end
    return true
end

local function shared_materialize_builtin_ref(ref)
    local loc = type(ref and ref.locator) == "table" and ref.locator or {}
    local list = M.list(loc.list_id or ref and ref.list_id)
    local raw, _, class_bucket, source_bucket = shared_builtin_raw_entry(
        loc.list_id or ref and ref.list_id, list, loc.class_name or ref and ref.class_name, loc.slot or ref and ref.slot)
    if type(raw) ~= "table" then return nil end
    local bucket = class_bucket or source_bucket
    local entry = bis.normalize_entry(raw)
    entry.slot = tostring(ref.slot or entry.slot or "")
    entry.group = tostring(ref.group or entry.group or "")
    entry.source = raw.source
    entry.spell = raw.spell or entry.spell
    entry.spells = raw.spells or entry.spells
    entry.spell_ids = raw.spell_ids or entry.spell_ids
    entry.notes = raw.notes
    entry.don_ability = raw.don_ability
    entry.learned_from = raw.learned_from
    compact_apply_expansions(ref.list_id, list, bucket, entry, ref.class_name)
    local satisfy_keys = shared_satisfy_keys(entry)
    local satisfy = shared_compact_entry_from_keys(satisfy_keys, entry)
    return {
        kind = "builtin",
        eval_path = ref.eval_path,
        partition = ref.partition,
        list_id = ref.list_id,
        list_name = ref.list_name,
        slot = ref.slot,
        group = ref.group,
        item_name = direct_candidate_name(entry, entry.item),
        enabled = ref.enabled ~= false,
        link_matched = true,
        matched_by = "shared-match-ref",
        classes = ref.classes,
        match = ref.match,
        satisfy = satisfy,
        entry = satisfy,
        rule_id = ref.rule_id,
        ref_id = ref.ref_id,
        generation = ref.generation,
    }
end

local function shared_materialize_user_ref(ref)
    local loc = type(ref and ref.locator) == "table" and ref.locator or {}
    bis.load_all()
    local list = bis.get(loc.list_id or ref and ref.list_id)
    local raw = list and list.entries and list.entries[tonumber(loc.entry_i) or 0] or nil
    if type(raw) ~= "table" then return nil end
    local entry = bis.normalize_entry(raw)
    local satisfy_keys = shared_satisfy_keys(entry)
    local satisfy = shared_compact_entry_from_keys(satisfy_keys, entry)
    return {
        kind = "user",
        eval_path = ref.eval_path,
        partition = ref.partition,
        list_id = ref.list_id,
        list_name = ref.list_name,
        slot = tostring(entry.slot or ref.slot or ""),
        group = tostring(entry.group or ref.group or ""),
        item_name = direct_candidate_name(entry, entry.item),
        enabled = ref.enabled ~= false,
        link_matched = true,
        matched_by = "shared-match-ref",
        owner = ref.owner,
        user_class = ref.user_class,
        user_shared = ref.user_shared,
        match = ref.match,
        satisfy = satisfy,
        entry = satisfy,
        rule_id = ref.rule_id,
        ref_id = ref.ref_id,
        generation = ref.generation,
    }
end

local function shared_materialize_ref(ref)
    if not ref then return nil end
    local cache_key = table.concat({
        tostring(shared_index_generation),
        tostring(ref.generation or ""),
        tostring(ref.ref_id or ref.rule_id or ""),
    }, "\31")
    local hit = shared_semantic_cache[cache_key]
    if hit then
        diag.count("local_needs.semantic.cache_hit")
        return hit, "hit"
    end
    diag.count("local_needs.semantic.cache_miss")
    local out = diag.time("local_needs.semantic.materialize", function()
        if ref.kind == "user" then return shared_materialize_user_ref(ref) end
        return shared_materialize_builtin_ref(ref)
    end)
    if out then shared_semantic_cache[cache_key] = out end
    return out, "miss"
end

local function builtin_announce_id_set()
    local set = {}
    for _, spec in ipairs(UI_LIST_BUTTONS) do
        if M.list(spec.id) then set[tostring(spec.id)] = true end
    end
    return set
end

local function builtin_catalog_classes()
    local seen, out = {}, {}
    local function add(c)
        c = class_key(c or "")
        if c and c ~= "" and not seen[c] then
            seen[c] = true
            out[#out + 1] = c
        end
    end
    for _, list in pairs(catalog.lists or {}) do
        if type(list.classes) == "table" then
            for class_name, bucket in pairs(list.classes) do
                if type(bucket) == "table" then add(class_name) end
            end
        end
    end
    local DS = ensure_don_spells_mod()
    if DS and DS.abilities_for_class then
        for _, c in ipairs({
            "Bard", "Beastlord", "Berserker", "Cleric", "Druid", "Enchanter",
            "Magician", "Monk", "Necromancer", "Paladin", "Ranger", "Rogue",
            "Shadow Knight", "Shaman", "Warrior", "Wizard",
        }) do
            local ok, abilities = pcall(DS.abilities_for_class, c)
            if ok and type(abilities) == "table" and #abilities > 0 then add(c) end
        end
    end
    table.sort(out)
    return out
end

local function generated_locator_key(loc)
    return table.concat({
        tostring(loc and loc.list_id or ""),
        tostring(loc and loc.class or ""),
        tostring(loc and loc.source_kind or ""),
        tostring(loc and loc.category_i or 0),
        tostring(loc and loc.category or ""),
        tostring(loc and loc.slot or ""),
    }, "\31")
end

local function generated_add_locator(payload, seen_locator, loc, raw)
    if type(raw) ~= "table" then return 0 end
    local locator_key = generated_locator_key(loc)
    if seen_locator[locator_key] then
        error("duplicate generated builtin announce locator: " .. locator_key)
    end
    seen_locator[locator_key] = true
    local keys = shared_raw_match_keys(raw, loc.slot, loc.list_id, nil)
    if not keys or (#(keys.names or {}) == 0 and #(keys.ids or {}) == 0) then return 0 end
    local locator_id = #payload.locators + 1
    loc.locator_id = locator_id
    payload.locators[locator_id] = loc
    local inserted = 0
    local seen_name = {}
    for _, name in ipairs(keys.names or {}) do
        local key = norm_item_key(name)
        if key ~= "" and not seen_name[key] then
            seen_name[key] = true
            local list = payload.by_name[key]
            if not list then
                list = {}
                payload.by_name[key] = list
            end
            list[#list + 1] = locator_id
            inserted = inserted + 1
        end
    end
    local seen_id = {}
    for _, id in ipairs(keys.ids or {}) do
        id = tonumber(id)
        if id and id > 0 then
            id = math.floor(id)
            if not seen_id[id] then
                seen_id[id] = true
                local list = payload.by_id[id]
                if not list then
                    list = {}
                    payload.by_id[id] = list
                end
                list[#list + 1] = locator_id
                inserted = inserted + 1
            end
        end
    end
    return inserted
end

local function generated_source_for_slot(list_id, list, class_name, slot)
    local raw, reason, class_bucket, source_bucket = shared_builtin_raw_entry(list_id, list, class_name, slot)
    if type(raw) ~= "table" then return nil, reason end
    if list_id == "don" and type(raw.don_ability) == "table" then return raw, "don_spell", nil end
    if class_bucket and source_bucket == class_bucket then return raw, "class", class_bucket end
    if list and source_bucket == list.template then return raw, "template", list.template end
    if list and source_bucket == list.visible then return raw, "visible", list.visible end
    if class_bucket and raw == class_bucket[slot] then return raw, "class", class_bucket end
    if list and list.template and raw == list.template[slot] then return raw, "template", list.template end
    if list and list.visible and raw == list.visible[slot] then return raw, "visible", list.visible end
    return raw, "unknown", source_bucket
end

function M.generate_builtin_announce_index_payload()
    if not M.catalog_loaded() then return nil, "no-catalog" end
    local payload = {
        schema = generated_builtin.schema,
        semantic_version = generated_builtin.semver,
        catalog_fingerprint = catalog_fingerprint(),
        generated_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        by_name = {},
        by_id = {},
        locators = {},
        classes = builtin_catalog_classes(),
    }
    local seen_locator = {}
    local key_count = 0
    for _, ref in ipairs(builtin_announce_list_refs(true)) do
        local list_id = tostring(ref.id or "")
        local list = M.list(list_id)
        if list then
            local has_classes = table_has_entries(list.classes)
            local function add_class_rows(class_name)
                for cat_i, cat in ipairs(list.categories or {}) do
                    local slots = category_slots(list_id, cat, class_name, false)
                    if (not slots or #slots == 0) and not is_don_spells_category(list_id, cat and cat.name) then
                        slots = cat and cat.slots or {}
                    end
                    for _, slot in ipairs(slots or {}) do
                        slot = tostring(slot or "")
                        local raw, source_kind = generated_source_for_slot(list_id, list, class_name, slot)
                        if raw and source_kind ~= "unknown" then
                            key_count = key_count + generated_add_locator(payload, seen_locator, {
                                list_id = list_id,
                                class = class_name,
                                source_kind = source_kind,
                                category_i = cat_i,
                                category = tostring(cat and cat.name or ""),
                                slot = slot,
                            }, raw)
                        end
                    end
                end
            end
            if has_classes then
                for _, class_name in ipairs(payload.classes or {}) do add_class_rows(class_name) end
            else
                add_class_rows(nil)
            end
        end
    end
    payload.locator_count = #payload.locators
    payload.key_count = key_count
    return payload, "ok"
end

local function generated_resolve_builtin_locator(loc, snap_class)
    if type(loc) ~= "table" then return nil, "bad-locator" end
    local list_id = tostring(loc.list_id or "")
    local list = M.list(list_id)
    if not list then return nil, "no-list" end
    local slot = tostring(loc.slot or "")
    local class_name = class_key(loc.class or snap_class or "")
    local source_kind = tostring(loc.source_kind or "")
    if source_kind == "don_spell" then
        local raw = shared_builtin_raw_entry(list_id, list, class_name, slot)
        if type(raw) ~= "table" then return nil, "no-don-spell" end
        return raw, nil, nil
    end
    if source_kind == "class" then
        local bucket = class_name and list.classes and list.classes[class_name] or nil
        local raw = bucket and bucket[slot]
        return raw, raw and nil or "no-class-row", bucket
    end
    if source_kind == "template" then
        local raw = list.template and list.template[slot]
        return raw, raw and nil or "no-template-row", list.template
    end
    if source_kind == "visible" then
        local raw = list.visible and list.visible[slot]
        return raw, raw and nil or "no-visible-row", list.visible
    end
    return nil, "bad-source-kind"
end

local function validate_generated_builtin_index(payload)
    if type(payload) ~= "table" then return false, "not-table" end
    if tonumber(payload.schema) ~= generated_builtin.schema then return false, "schema" end
    if tostring(payload.semantic_version or "") ~= generated_builtin.semver then return false, "semantic-version" end
    if tostring(payload.catalog_fingerprint or "") ~= catalog_fingerprint() then return false, "catalog-fingerprint" end
    if type(payload.by_name) ~= "table" or type(payload.by_id) ~= "table" or type(payload.locators) ~= "table" then
        return false, "shape"
    end
    if #(payload.locators or {}) <= 0 then return false, "empty" end
    -- Full locator/content validation belongs to generation and regression
    -- tests. Runtime compares embedded content truth and checks top-level shape.
    return true, "ok", 0
end

local function generated_builtin_index_load(origin)
    if generated_builtin.load_attempted then return generated_builtin.index, generated_builtin.status.reason end
    generated_builtin.load_attempted = true
    origin = tostring(origin or "other")
    local load_wall_t0, load_cpu_t0 = M._wall_now_s(), os.clock()
    local payload
    local ok, err = diag.time("generated_index.load", function()
        return pcall(require, "generated.builtin_announce_index")
    end)
    local load_wall_ms = math.max(0, (M._wall_now_s() - load_wall_t0) * 1000)
    local load_cpu_ms = math.max(0, (os.clock() - load_cpu_t0) * 1000)
    if ok then payload = err else generated_builtin.status = { ready = false, reason = tostring(err or "load-error") } end
    if payload then
        local validate_wall_t0, validate_cpu_t0 = M._wall_now_s(), os.clock()
        local valid, reason, eager_resolved_locators = validate_generated_builtin_index(payload)
        local validate_wall_ms = math.max(0, (M._wall_now_s() - validate_wall_t0) * 1000)
        local validate_cpu_ms = math.max(0, (os.clock() - validate_cpu_t0) * 1000)
        if valid then
            generated_builtin.index = payload
            generated_builtin.status = {
                ready = true,
                reason = "ok",
                schema = payload.schema,
                semantic_version = payload.semantic_version,
                catalog_fingerprint = payload.catalog_fingerprint,
                locators = #(payload.locators or {}),
                key_count = tonumber(payload.key_count) or 0,
                eager_resolved_locators = tonumber(eager_resolved_locators) or 0,
                resident = true,
                load_origin = origin,
                loaded_at = M._wall_now_s(),
                load_wall_ms = load_wall_ms,
                load_cpu_ms = load_cpu_ms,
                validate_wall_ms = validate_wall_ms,
                validate_cpu_ms = validate_cpu_ms,
            }
            local runtime_status = M._catalog_runtime_status
            runtime_status.generated_resident = true
            runtime_status.generated_load_origin = origin
            runtime_status.generated_loaded_at = generated_builtin.status.loaded_at
            runtime_status.generated_load_wall_ms = load_wall_ms
            runtime_status.generated_load_cpu_ms = load_cpu_ms
            runtime_status.generated_validate_wall_ms = validate_wall_ms
            runtime_status.generated_validate_cpu_ms = validate_cpu_ms
            diag.count("generated_index.load.ok")
            diag.count("generated_index.load_origin." .. origin:gsub("[^%w_]+", "_"))
            diag.sample("generated_index.load_wall_ms", load_wall_ms)
            diag.sample("generated_index.load_cpu_ms", load_cpu_ms)
            diag.sample("generated_index.validate_wall_ms", validate_wall_ms)
            diag.sample("generated_index.validate_cpu_ms", validate_cpu_ms)
            diag.sample("generated_index.locators", generated_builtin.status.locators)
            diag.sample("generated_index.keys", generated_builtin.status.key_count)
            return generated_builtin.index, "ok"
        end
        generated_builtin.status = {
            ready = false,
            reason = reason or "invalid",
            resident = false,
            load_origin = origin,
            load_wall_ms = load_wall_ms,
            load_cpu_ms = load_cpu_ms,
            validate_wall_ms = validate_wall_ms,
            validate_cpu_ms = validate_cpu_ms,
        }
    end
    diag.count("generated_index.load.failed")
    diag.event("generated_index.load_failed", tostring(generated_builtin.status.reason or "?"):sub(1, 240))
    return nil, generated_builtin.status.reason
end

local function generated_add_locator_ids(out, seen, ids)
    for _, id in ipairs(ids or {}) do
        id = tonumber(id)
        if id and id > 0 and not seen[id] then
            seen[id] = true
            out[#out + 1] = id
        end
    end
end

local function generated_materialize_locator(payload, locator_id, snap_class)
    local loc = payload and payload.locators and payload.locators[tonumber(locator_id) or 0]
    if not loc then return nil, "no-locator" end
    local cache_key = tostring(payload.semantic_version or "") .. "\31" .. tostring(locator_id)
    local hit = generated_builtin.semantic_cache[cache_key]
    if hit then
        diag.count("generated_index.semantic.cache_hit")
        return hit, "hit"
    end
    diag.count("generated_index.semantic.cache_miss")
    local out = diag.time("generated_index.semantic.materialize", function()
        local raw, reason, bucket = generated_resolve_builtin_locator(loc, snap_class)
        if type(raw) ~= "table" then return nil, reason or "unresolved" end
        local list = M.list(loc.list_id)
        local class_name = class_key(loc.class or snap_class or "")
        local entry = bis.normalize_entry(raw)
        entry.slot = tostring(loc.slot or entry.slot or "")
        entry.group = tostring(loc.category or entry.group or "")
        entry.source = raw.source
        entry.spell = raw.spell or entry.spell
        entry.spells = raw.spells or entry.spells
        entry.spell_ids = raw.spell_ids or entry.spell_ids
        entry.notes = raw.notes
        entry.don_ability = raw.don_ability
        entry.learned_from = raw.learned_from
        compact_apply_expansions(loc.list_id, list, bucket, entry, class_name)
        local satisfy_keys = shared_satisfy_keys(entry)
        local satisfy = shared_compact_entry_from_keys(satisfy_keys, entry)
        return {
            kind = "builtin",
            eval_path = "generated_builtin",
            list_id = tostring(loc.list_id or ""),
            list_name = M.list_label(loc.list_id),
            slot = tostring(loc.slot or ""),
            group = tostring(loc.category or ""),
            item_name = direct_candidate_name(entry, entry.item),
            enabled = true,
            link_matched = true,
            matched_by = "generated-index",
            entry = satisfy,
            satisfy = satisfy,
            locator_id = tonumber(locator_id) or 0,
            semantic_version = payload.semantic_version,
        }
    end)
    if out then generated_builtin.semantic_cache[cache_key] = out end
    return out, "miss"
end

function M._generated_materialize_ids(payload, locator_ids, class_name, diag_prefix)
    local out, filtered = {}, 0
    for _, locator_id in ipairs(locator_ids or {}) do
        local loc = payload.locators and payload.locators[locator_id]
        local loc_class = class_key(loc and loc.class or "")
        if loc and M.list_announce_enabled(loc.list_id)
            and (not loc_class or loc_class == "" or loc_class == class_name) then
            filtered = filtered + 1
            local rule = diag.time("generated_index.semantic.evaluate", function()
                return generated_materialize_locator(payload, locator_id, class_name)
            end)
            if rule then out[#out + 1] = rule end
        end
    end
    diag.sample("generated_index." .. tostring(diag_prefix) .. "_filtered_candidates", filtered)
    diag.sample("generated_index." .. tostring(diag_prefix) .. "_materialized_candidates", #out)
    return out, filtered
end

function M.generated_builtin_index_status()
    return generated_builtin.status
end

function M.generated_builtin_index_ready()
    return generated_builtin.index ~= nil and generated_builtin.status.ready == true
end

function M.warm_generated_builtin_index(origin)
    return generated_builtin_index_load(origin or "startup")
end

function M._reset_generated_builtin_for_tests()
    generated_builtin.index = nil
    generated_builtin.load_attempted = false
    generated_builtin.status = { ready = false, reason = "not-loaded", resident = false }
    generated_builtin.semantic_cache = {}
    M._catalog_runtime_status.generated_resident = false
end

function M.generated_builtin_compact_candidates_for_link(snap, item_name, item_id)
    if not snap then return {}, "no-snap", { cache = "miss", candidate_count = 0 } end
    item_name = clean_link_item_name(item_name)
    item_id = tonumber(item_id) or 0
    if item_name == "" and item_id <= 0 then return {}, "no-name", { cache = "miss", candidate_count = 0 } end
    local payload, load_reason = generated_builtin.index, generated_builtin.status.reason
    if not payload then
        diag.count("generated_index.first_link_not_resident")
        return {}, "not-ready", {
            cache = "miss",
            candidate_count = 0,
            unavailable = true,
            reason = load_reason or "not-loaded",
        }
    end
    local id_ids, id_seen = {}, {}
    local name_ids, name_seen = {}, {}
    local raw_ids, raw_seen = {}, {}
    diag.time("generated_index.lookup", function()
        if item_id > 0 then
            generated_add_locator_ids(id_ids, id_seen, payload.by_id and payload.by_id[math.floor(item_id)])
        end
        local key = norm_item_key(item_name)
        if key ~= "" then
            generated_add_locator_ids(name_ids, name_seen, payload.by_name and payload.by_name[key])
        end
        -- Name identity is authoritative when available. Keep the full union
        -- only for diagnostics; an unrelated/corrupt ID must not add or hide
        -- candidates selected by a valid normalized visible name.
        generated_add_locator_ids(raw_ids, raw_seen, name_ids)
        generated_add_locator_ids(raw_ids, raw_seen, id_ids)
    end)
    diag.sample("generated_index.id_candidates", #id_ids)
    diag.sample("generated_index.name_candidates", #name_ids)
    diag.sample("generated_index.raw_candidates", #raw_ids)
    local class_name = class_key(snap.class or "")
    local name_out, name_filtered =
        M._generated_materialize_ids(payload, name_ids, class_name, "name")
    local id_out, id_filtered =
        M._generated_materialize_ids(payload, id_ids, class_name, "id")
    local out, selected_by
    if #name_out > 0 then
        out, selected_by = name_out, "name"
    elseif #id_out > 0 then
        out, selected_by = id_out, "id"
    else
        out, selected_by = {}, "none"
    end
    local filtered = name_filtered + id_filtered
    diag.sample("generated_index.filtered_candidates", filtered)
    diag.sample("generated_index.materialized_candidates", #name_out + #id_out)
    diag.count("generated_index.selected_" .. selected_by)
    return out, (#out > 0) and "ok" or "no-row", {
        cache = "hit",
        candidate_count = #out,
        raw_count = #raw_ids,
        id_count = #id_ids,
        name_count = #name_ids,
        id_filtered_count = id_filtered,
        name_filtered_count = name_filtered,
        id_materialized_count = #id_out,
        name_materialized_count = #name_out,
        selected_by = selected_by,
        generation = payload.semantic_version,
    }
end

--- Evaluate one linked item for one snapshot using only the generated
--- candidates that matched that link and a matching-key ownership scan.
--- This is the bounded cold-row authority path; it does not invoke paint_need_walk.
function M.generated_builtin_targeted_decision(snap, item_name, item_id, opts)
    opts = type(opts) == "table" and opts or {}
    local candidates, why = M.generated_builtin_compact_candidates_for_link(snap, item_name, item_id)
    if why ~= "ok" or #candidates == 0 then return nil, why end
    local ownership_index = require('ownership_index')
    local local_needs = require('local_needs')
    local ownership = ownership_index.targeted_snapshot_index(snap, candidates)
    local freshness = type(opts.freshness) == "table" and opts.freshness or {
        inventoryIncomplete = snap and snap.inventoryIncomplete == true,
        bankUnknown = snap and snap.bankValid == false and snap.bankLive ~= true,
    }
    local result = local_needs.evaluate_link({
        identity = {
            server = snap and snap.server,
            name = snap and snap.name,
            class = snap and snap.class,
            local_owner = opts.local_owner == true,
        },
        freshness = freshness,
        candidates = candidates,
        ownership = ownership,
        live_provider = opts.live_provider,
        peer_freshness_provider = opts.peer_freshness_provider,
    }, {
        name = item_name,
        id = item_id,
    })
    if type(result) ~= "table" then return nil, "unresolved" end
    if result.need == true then
        if (freshness.inventoryIncomplete == true or freshness.bankUnknown == true)
            and result.peer_fresh_used ~= true and result.live_used ~= true then
            return nil, "snapshot-unavailable"
        end
        local candidate = result.candidate or candidates[1]
        return {
            item_name = tostring(item_name or ""),
            entry = candidate and (candidate.entry or candidate.satisfy) or nil,
            list = {
                id = candidate and candidate.list_id or "",
                name = candidate and candidate.list_name or "",
            },
            targeted = true,
        }, "need"
    end
    if result.reason == "error" then return nil, tostring(result.error or "error") end
    if result.reason == "no-row" then return nil, "no-row" end
    return nil, "owned"
end

function M.shared_compact_candidates_for_link(snap, item_name, item_id)
    if not snap then return {}, "no-snap", { cache = "miss", candidate_count = 0 } end
    item_name = clean_link_item_name(item_name)
    item_id = tonumber(item_id) or 0
    if item_name == "" and item_id <= 0 then return {}, "no-name", { cache = "miss", candidate_count = 0 } end
    M.request_shared_compact_rule_index(snap.class, snap.name, "link")
    local idx = shared_index_active
    local class_name = class_key(snap.class or "")
    if not idx or not shared_partition_is_ready(idx, "common")
        or (class_name and class_name ~= "" and not shared_partition_is_ready(idx, "class", class_name)) then
        diag.count("local_needs.shared_index_not_ready")
        return {}, "not-ready", {
            cache = "miss",
            candidate_count = 0,
            not_ready = true,
            generation = shared_index_generation,
        }
    end

    local raw_ids, seen_ids = {}, {}
    diag.time("local_needs.match_ref.lookup", function()
        shared_lookup_partition(idx.common, item_name, item_id, raw_ids, seen_ids)
        if class_name and class_name ~= "" then
            shared_lookup_partition(idx.classes and idx.classes[class_name], item_name, item_id, raw_ids, seen_ids)
        end
    end)
    diag.sample("local_needs.match_ref.raw_candidates", #raw_ids)
    diag.sample("local_needs.shared_index_candidates_raw", #raw_ids)

    local out = {}
    local filtered = 0
    for _, rid in ipairs(raw_ids) do
        local ref = idx.rules and idx.rules[rid]
        if shared_rule_applies(ref, snap) then
            filtered = filtered + 1
            local rule = diag.time("local_needs.semantic.evaluate", function()
                return shared_materialize_ref(ref)
            end)
            if rule then
                out[#out + 1] = {
                    kind = rule.kind,
                    eval_path = rule.eval_path,
                    list_id = rule.list_id,
                    list_name = rule.list_name,
                    slot = rule.slot,
                    group = rule.group,
                    item_name = rule.item_name,
                    enabled = rule.enabled ~= false,
                    link_matched = true,
                    matched_by = "shared-match-ref",
                    entry = rule.satisfy or rule.entry,
                    satisfy = rule.satisfy or rule.entry,
                    match = rule.match,
                    rule_id = rule.rule_id,
                    ref_id = rule.ref_id,
                    generation = rule.generation,
                }
            end
        end
    end
    diag.sample("local_needs.match_ref.filtered_candidates", filtered)
    diag.sample("local_needs.shared_index_candidates_filtered", #out)
    return out, (#out > 0) and "ok" or "no-row", {
        cache = "hit",
        candidate_count = #out,
        raw_count = #raw_ids,
        generation = idx.generation,
    }
end

function M.shared_compact_rule_index_status()
    local idx = shared_index_active
    return {
        generation = shared_index_generation,
        active_generation = idx and idx.generation or 0,
        queue = #shared_index_queue,
        building = shared_index_build ~= nil,
        building_partition = shared_index_build and shared_index_build.partition or "",
        building_class = shared_index_build and shared_index_build.class_name or "",
        building_steps = shared_index_build and shared_index_build.steps or 0,
        common_ready = idx and idx.common and idx.common.ready == true or false,
        user_ready = true,
        rules = idx and idx.rules and (idx.next_rule_id or 0) or 0,
    }
end

-- BiS-shaped: walk class+template+visible slots; if linked name matches
-- that slot, use evaluate_slot (bis_search paint for peers / live for self).
local function paint_need_walk(snap, item_name, item_id, opts)
    opts = type(opts) == 'table' and opts or {}
    item_name = clean_link_item_name(item_name)
    item_id = tonumber(item_id) or 0
    if item_name == '' and item_id <= 0 then return nil, 'no-name' end
    if not M.catalog_loaded() or not bis.link_matches_entry then return nil, 'no-catalog' end

    local class_name = class_key(snap.class or '')
    local matched = false
    local link_norm = norm_item_key(item_name)
    local trace_jonas = link_norm == norm_item_key("Jonas Dagmire's Little Finger Metacarpal")
        or link_norm == norm_item_key("Little Finger Metacarpal")
        or link_norm == norm_item_key("Jonas Dagmire's Thumb Distal Phalanx")
        or link_norm == norm_item_key("Thumb Distal Phalanx")

    local function short_list_text(list, max_count)
        local out = {}
        max_count = tonumber(max_count) or 8
        for _, v in ipairs(type(list) == "table" and list or {}) do
            out[#out + 1] = tostring(v)
            if #out >= max_count then break end
        end
        local text = table.concat(out, "|")
        if type(list) == "table" and #list > max_count then text = text .. "|..." end
        return text
    end

    local function cell_alts(raw, entry)
        local cell = trim((raw and (raw.item or raw.name)) or (entry and entry.item) or '')
        local alts = {}
        if cell == '' then return alts end
        for alt in cell:gmatch('[^/]+') do
            alt = trim(alt)
            if alt ~= '' then alts[#alts + 1] = alt end
        end
        if #alts == 0 then alts[1] = cell end
        return alts
    end

    local function names_hit(entry, paint_name, raw)
        if entry and bis.link_matches_entry(entry, item_name, item_id) then return true end
        paint_name = trim(paint_name or '')
        if paint_name ~= '' and link_norm ~= '' and norm_item_key(paint_name) == link_norm then
            return true
        end
        for _, alt in ipairs(cell_alts(raw, entry)) do
            if link_norm ~= '' and norm_item_key(alt) == link_norm then return true end
            if entry and bis.link_matches_entry({ item = alt, names = { alt }, ids = entry.ids or {} }, item_name, item_id) then
                return true
            end
        end
        return false
    end

    local function match_reason(entry, paint_name, raw)
        entry = type(entry) == "table" and entry or {}
        if bis.link_matches_entry(entry, item_name, item_id) then return "link_matches_entry" end
        paint_name = trim(paint_name or '')
        if paint_name ~= '' and link_norm ~= '' and norm_item_key(paint_name) == link_norm then
            return "exact normalized paint/raw name"
        end
        for _, alt in ipairs(cell_alts(raw, entry)) do
            if link_norm ~= '' and norm_item_key(alt) == link_norm then return "slash alias" end
            if bis.link_matches_entry({ item = alt, names = { alt }, ids = entry.ids or {} }, item_name, item_id) then
                return "ID"
            end
        end
        return "unknown"
    end

    local function row_text(row)
        row = type(row) == "table" and row or {}
        local match = type(row.match) == "table" and row.match or {}
        return string.format("empty=%s status=%s have=%s from_bis_search=%s match=%s loc=%s",
            tostring(row.empty == true), tostring(row.status or ""), tostring(row.have == true),
            tostring(row.from_bis_search == true), tostring(match.name or ""):sub(1, 60),
            tostring(match.location or match.where or match.slotname or ""))
    end

    local function bis_search_trace_text(list_id, slot)
        local ok_bs, bis_search = pcall(require, 'bis_search')
        if not ok_bs or not bis_search then return "module=false" end
        local rec, meta = nil, nil
        if type(bis_search.slot_rec_meta) == "function" then
            rec, meta = bis_search.slot_rec_meta(snap, list_id, slot)
        elseif type(bis_search.slot_rec) == "function" then
            rec = bis_search.slot_rec(snap, list_id, slot)
        end
        rec = type(rec) == "table" and rec or {}
        meta = type(meta) == "table" and meta or {}
        return string.format("present=%s status=%s name=%s count=%s loc=%s updated=%s key=%s",
            tostring(next(rec) ~= nil), tostring(rec.status or ""), tostring(rec.name or ""):sub(1, 60),
            tostring(rec.count or ""), tostring(rec.location or ""), tostring(meta.updated or ""),
            tostring(meta.key or ""):sub(1, 80))
    end

    local function trace_jonas_row(stage, detail)
        if not trace_jonas then return end
        diag.event("announce.paint_jonas_trace", (stage .. " " .. tostring(detail or "")):sub(1, 500))
    end

    local function accept(entry, list_id, list_name, row, paint_name, raw)
        if not names_hit(entry, paint_name, raw) then return nil end
        matched = true
        if trace_jonas then
            trace_jonas_row("accept", string.format(
                "char=%s class=%s link=%s id=%s list=%s slot=%s reason=%s outcome=%s row={%s}",
                tostring(snap.name or ""), tostring(snap.class or ""), tostring(item_name or ""):sub(1, 80),
                tostring(item_id or 0), tostring(list_id or ""), tostring(entry and entry.slot or ""),
                match_reason(entry, paint_name, raw),
                (not row or row.empty) and "empty" or (row.status ~= "missing" and "non-missing/owned" or "need-check"),
                row_text(row)))
        end
        if not row or row.empty or row.status ~= 'missing' then return nil end
        if opts.skip_live ~= true and is_local_snap(snap)
            and bis.live_own_item(entry or { item = item_name, names = { item_name } }, item_name, nil) then
            trace_jonas_row("accept", "outcome=skipped local-live-owned")
            return nil
        end
        trace_jonas_row("accept", "outcome=need")
        return {
            list = { id = list_id, name = list_name },
            entry = entry or { item = item_name, names = { item_name }, slot = '' },
            item_name = direct_candidate_name(entry, item_name),
        }
    end

    for _, ref in ipairs(M.lists_for_announce()) do
        local list_id = tostring(ref.id or '')
        local list = M.list(list_id)
        if list then
            local list_name = M.list_label(list_id)
            local seen_slot = {}
            local buckets = {}
            if class_name and type(list.classes) == 'table' and type(list.classes[class_name]) == 'table' then
                buckets[#buckets + 1] = { source = "class", bucket = list.classes[class_name] }
            end
            if type(list.template) == 'table' then buckets[#buckets + 1] = { source = "template", bucket = list.template } end
            if type(list.visible) == 'table' then buckets[#buckets + 1] = { source = "visible", bucket = list.visible } end

            for _, bucket_rec in ipairs(buckets) do
                local bucket = bucket_rec.bucket
                local bucket_source = bucket_rec.source
                for slot, raw in pairs(bucket) do
                    slot = tostring(slot or '')
                    if slot ~= '' and not seen_slot[slot] and type(raw) == 'table' then
                        seen_slot[slot] = true
                        -- Cheap name/id filter BEFORE evaluate_slot (grid paint is
                        -- expensive; sapphire matched early, bloom/slimes walked
                        -- every slot and felt like "no [TG]").
                        -- Rough cell filter first (no expand): catches Fungus↔Slime
                        -- and Bloom↔Fungal Bloom without walking every slot slowly.
                        local cell = tostring((raw.item or raw.name or '') .. ' ' .. slot):lower()
                        local rough = false
                        if link_norm ~= '' then
                            rough = cell:find(link_norm, 1, true) ~= nil
                            if not rough then
                                local slime_elem = link_norm:match("^(%S+) slime of suffering$")
                                if slime_elem and cell:find(slime_elem, 1, true)
                                    and cell:find("fungus of suffering", 1, true) then
                                    rough = true
                                end
                                local bloom_rest = link_norm:match("^noxious bloom of (.+)$")
                                if bloom_rest and cell:find("fungal bloom of " .. bloom_rest, 1, true) then
                                    rough = true
                                end
                            end
                        end
                        if not rough and item_id <= 0 then
                            -- still allow exact normalize hit below for id-less edge cases
                        end
                        local entry = bis.normalize_entry(raw)
                        entry.slot = slot
                        if not rough and item_id > 0 then
                            for _, id in ipairs(entry.ids or {}) do
                                if tonumber(id) == item_id then rough = true break end
                            end
                        end
                        if rough or names_hit(entry, nil, raw) then
                            expand_fungal_chain(list, bucket, entry)
                            if list_id == 'don' then
                                expand_don_clicky_chain(list, bucket, entry)
                                expand_don_shadow_chain(list, bucket, entry)
                            elseif list_id == 'bagitems' then
                                expand_tattered_sack_chain(entry)
                            elseif list_id == 'sebilis' then
                                M.expand_sebilis_forsaken_chain(entry)
                            end
                            if names_hit(entry, nil, raw) then
                                local row = M.evaluate_slot(list_id, snap, slot, nil)
                                local paint_name = row and row.match and row.match.name or nil
                                local fallback_used = false
                                local eval_text = row_text(row)
                                -- Keep chain-expanded `entry` for name match; only borrow status.
                                if not row or row.empty then
                                    row = bis.evaluate_entry(entry, snap, opts)
                                    fallback_used = true
                                end
                                if trace_jonas and list_id == "jonas" then
                                    trace_jonas_row("row", string.format(
                                        "char=%s class=%s link=%s id=%s list=%s/%s slot=%s source=%s rawItem=%s rawNames=%s rawIds=%s normItem=%s normNames=%s normIds=%s reason=%s eval={%s} fallback=%s final={%s} bisSearch={%s}",
                                        tostring(snap.name or ""), tostring(snap.class or ""),
                                        tostring(item_name or ""):sub(1, 80), tostring(item_id or 0),
                                        tostring(list_id), tostring(list_name), tostring(slot), tostring(bucket_source or ""),
                                        tostring(raw.item or raw.name or ""):sub(1, 60),
                                        short_list_text(raw.names, 5), short_list_text(raw.ids, 8),
                                        tostring(entry.item or ""):sub(1, 60),
                                        short_list_text(entry.names, 8), short_list_text(entry.ids, 10),
                                        match_reason(entry, paint_name, raw), eval_text, tostring(fallback_used),
                                        row_text(row), bis_search_trace_text(list_id, slot)))
                                end
                                local need = accept(entry, list_id, list_name, row, paint_name, raw)
                                if need then return need, 'need' end
                            end
                        end
                    end
                end
            end
        end
    end

    return nil, matched and 'owned' or 'no-row'
end

--- Linked need = BiS paint for this char (evaluate_slot / template / live).
--- Returns need, why (why is "need" / "owned" / "no-row" / ...).
function M.check_announce_need_for_link(snap, item_name, item_id, opts)
    if not snap then return nil, "no-snap" end
    local need, why = paint_need_walk(snap, item_name, item_id, opts)
    if need then return need, "need" end
    return nil, why or "no-row"
end

--- Status helper after a nil need: "owned" vs "no-row" (and class tag).
function M.explain_announce_skip_for_link(snap, item_name, item_id, opts)
    local need, why = M.check_announce_need_for_link(snap, item_name, item_id, opts)
    if need then return "need" end
    return why or "no-row"
end

function M._explain_short_list(list, max_count)
    local out = {}
    max_count = tonumber(max_count) or 8
    for _, v in ipairs(type(list) == "table" and list or {}) do
        out[#out + 1] = tostring(v)
        if #out >= max_count then break end
    end
    local text = table.concat(out, "|")
    if type(list) == "table" and #list > max_count then text = text .. "|..." end
    return text
end

function M._explain_row_text(row)
    row = type(row) == "table" and row or {}
    local match = type(row.match) == "table" and row.match or {}
    return string.format("empty=%s status=%s have=%s from_bis_search=%s match=%s loc=%s",
        tostring(row.empty == true), tostring(row.status or ""), tostring(row.have == true),
        tostring(row.from_bis_search == true), tostring(match.name or ""):sub(1, 60),
        tostring(match.location or match.where or match.slotname or ""))
end

function M._explain_bucket_for_slot(list, class_name, slot)
    slot = tostring(slot or "")
    local buckets = {}
    if class_name and type(list and list.classes) == "table" and type(list.classes[class_name]) == "table" then
        buckets[#buckets + 1] = { source = "class", bucket = list.classes[class_name] }
    end
    if type(list and list.template) == "table" then buckets[#buckets + 1] = { source = "template", bucket = list.template } end
    if type(list and list.visible) == "table" then buckets[#buckets + 1] = { source = "visible", bucket = list.visible } end
    for _, b in ipairs(buckets) do
        local raw = b.bucket and b.bucket[slot]
        if type(raw) == "table" then return raw, b.source, b.bucket end
    end
    return nil, "", nil
end

function M._explain_match_reason(entry, raw, link_name, link_id)
    entry = type(entry) == "table" and entry or {}
    raw = type(raw) == "table" and raw or {}
    link_name = clean_link_item_name(link_name)
    link_id = tonumber(link_id) or 0
    local link_norm = norm_item_key(link_name)
    if bis.link_matches_entry and bis.link_matches_entry(entry, link_name, link_id) then
        if link_id > 0 then
            for _, id in ipairs(entry.ids or {}) do
                if tonumber(id) == link_id then return "id" end
            end
        end
        return "entry-name-or-id"
    end
    local function name_hit(n)
        return link_norm ~= "" and norm_item_key(n) == link_norm
    end
    if name_hit(entry.item) then return "exact normalized entry item" end
    for _, n in ipairs(entry.names or {}) do
        if name_hit(n) then return "exact normalized entry name" end
    end
    local cell = trim(raw.item or raw.name or "")
    for alt in cell:gmatch("[^/]+") do
        if name_hit(trim(alt)) then return "slash alias" end
    end
    return "other/no-match"
end

function M.explain_authoritative_announce_decision(snap, item_name, item_id, opts)
    opts = type(opts) == "table" and opts or {}
    if type(snap) ~= "table" then return { final_reason = "no-snap", lines = { "no-snap" } } end
    item_name = clean_link_item_name(item_name)
    item_id = tonumber(item_id) or 0
    local list_id = tostring(opts.list_id or opts.focus_list_id or "")
    local slot = tostring(opts.slot or opts.focus_slot or "")
    local class_name = class_key(snap.class or "")
    local lines = {}
    local final = "no-row"
    local function add(line)
        lines[#lines + 1] = tostring(line or ""):sub(1, 500)
    end
    local function inspect_slot(id, list, slot_name)
        local raw, source_bucket = M._explain_bucket_for_slot(list, class_name, slot_name)
        local resolved = M.resolve_entry(id, snap.class, slot_name)
        local raw_entry = type(raw) == "table" and bis.normalize_entry(raw) or nil
        if raw_entry then raw_entry.slot = slot_name end
        local entry = resolved or raw_entry
        if not entry then
            add(string.format("auth row missing char=%s class=%s item=%s id=%s list=%s slot=%s",
                tostring(snap.name or ""), tostring(snap.class or ""), tostring(item_name):sub(1, 80),
                tostring(item_id), tostring(id), tostring(slot_name)))
            return false
        end
        local row = M.evaluate_slot(id, snap, slot_name, entry.group or nil)
        local fallback_used = false
        local eval_text = M._explain_row_text(row)
        if not row or row.empty then
            row = bis.evaluate_entry(entry, snap, opts)
            fallback_used = true
        end
        local status = tostring(row and row.status or "")
        local reason = "need"
        if not row or row.empty or status ~= "missing" then
            reason = "owned"
        elseif opts.skip_live ~= true and is_local_snap(snap)
            and bis.live_own_item(entry, item_name, nil) then
            reason = "owned-live"
        end
        final = reason
        add(string.format(
            "auth char=%s class=%s link=%s id=%s list=%s slot=%s source=%s match=%s rawItem=%s rawNames=%s rawIds=%s normItem=%s normNames=%s normIds=%s spells=%s eval={%s} fallback=%s final={%s} reason=%s",
            tostring(snap.name or ""), tostring(snap.class or ""), tostring(item_name):sub(1, 80),
            tostring(item_id), tostring(id), tostring(slot_name), tostring(source_bucket or ""),
            M._explain_match_reason(entry, raw, item_name, item_id),
            tostring(raw and (raw.item or raw.name) or ""):sub(1, 60),
            M._explain_short_list(raw and raw.names, 5), M._explain_short_list(raw and raw.ids, 8),
            tostring(entry.item or ""):sub(1, 60),
            M._explain_short_list(entry.names, 8), M._explain_short_list(entry.ids, 10),
            M._explain_short_list(entry.spells or (entry.spell and { entry.spell } or nil), 5),
            eval_text, tostring(fallback_used), M._explain_row_text(row), reason))
        return true
    end
    if list_id ~= "" and slot ~= "" then
        local list = M.list(list_id)
        if list then
            inspect_slot(list_id, list, slot)
        else
            add("auth list missing list=" .. tostring(list_id))
        end
    else
        add("auth no focus list/slot supplied")
    end
    return {
        final_reason = final,
        lines = lines,
    }
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
    line = tostring(line or ""):lower()
    local text_has_name = nil
    pcall(function()
        local ni = require('needs_index')
        text_has_name = ni.core and ni.core.text_has_name
    end)
    local out, seen, seen_entry = {}, {}, {}
    for key, recs in pairs(idx.by_name or {}) do
        if not seen[key] then
            for _, rec in ipairs(recs) do
                if M.list_announce_enabled(rec.list_id) then
                    local name = tostring(rec.item_name or "")
                    local name_l = name:lower()
                    local hit = name_l ~= "" and (
                        (text_has_name and text_has_name(line, name_l))
                        or ((not text_has_name) and line:find(name_l, 1, true))
                    )
                    if hit then
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
