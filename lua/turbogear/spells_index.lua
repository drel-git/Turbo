-- TurboGear/spells_index.lua
-- Lightweight per-character spell roster cache for the Spells tab display path.
-- Replaces per-column build_manifest calls (the research planner) with a
-- LazBis-style precomputed answer: for each character, every roster spell with
-- owned / missing / unknown status, location label, and recipe tooltip.
--
-- Two layers of caching:
--   * class rosters: spell list + recipe lookups built ONCE per class (the old
--     path re-derived these per column per rebuild, O(spells x ini sections));
--   * character rows: re-evaluated only when that character's spell signature
--     changes (~30 hash lookups), budgeted per tick.
--
-- Filters (level chips / hide owned / hide non-research) are applied at draw
-- time by the tab, so toggling them never invalidates anything here.
-- Pure logic lives in M.core (tests/turbogear_spells_index_test.lua). The
-- planner (Catalog.build_manifest) remains the export path only.

local M = { core = {} }
local core = M.core

-- ========================= pure core ==================================== --

local SOURCE_SHORT = {
    research = "Research",
    anguish = "Anguish",
    library = "PoK Library",
    drop = "Random",
    quest = "Quest",
    other = "Other",
    noRecipe = "No recipe",
}

local function trim(s)
    return tostring(s or ""):match("^%s*(.-)%s*$") or ""
end

function core.is_non_research_kind(kind)
    return kind == "drop" or kind == "anguish" or kind == "library" or kind == "quest" or kind == "other"
end

function core.location_short(kind, source, nonResearch)
    local base = SOURCE_SHORT[kind]
    if not base then
        local src = trim(source)
        local lower = src:lower()
        if src == "" or src == "?" or src == "???" then base = "Unknown"
        elseif lower:find("research", 1, true) then base = "Research"
        elseif lower:find("anguish", 1, true) then base = "Anguish"
        elseif lower:find("library", 1, true) then base = "PoK Library"
        else base = src
        end
    end
    if nonResearch and base ~= "" then
        return base .. " (non-research)"
    end
    return base
end

-- Build the static per-class roster once.
--   laz_entries: { [level] = { "Name|Source", ... } } (spells.lua slice for one class)
--   ini_recipes: array from Catalog.ini_recipes_for_class(class)
--   classify:    function(source) -> kind, label   (Catalog.classify_source)
--   norm:        function(name) -> norm key        (Catalog.product_norm)
-- Returns array of roster rows sorted level desc, name asc:
--   { level, name, norm, sourceKind, source, location, nonResearch, inIni, recipeTip }
function core.build_class_roster(laz_entries, ini_recipes, classify, norm)
    local ini_by_norm = {}
    for _, rec in ipairs(ini_recipes or {}) do
        if rec.norm and not ini_by_norm[rec.norm] then ini_by_norm[rec.norm] = rec end
    end

    local rows, seen = {}, {}
    for level, entries in pairs(laz_entries or {}) do
        for _, entry in ipairs(entries or {}) do
            local parts = {}
            for p in tostring(entry):gmatch("[^|]+") do parts[#parts + 1] = p end
            local name = trim(parts[1] or entry)
            if name ~= "" then
                local kind, source = classify(parts[2] or "")
                local n = norm(name)
                seen[n] = true
                local rec = ini_by_norm[n]
                local non_research = core.is_non_research_kind(kind)
                rows[#rows + 1] = {
                    level = tonumber(level) or 0,
                    name = name,
                    norm = n,
                    sourceKind = kind,
                    source = source,
                    location = core.location_short(kind, source, non_research),
                    nonResearch = non_research,
                    inIni = rec ~= nil,
                    recipeTip = rec and rec.ingredients and #rec.ingredients > 0
                        and table.concat(rec.ingredients, ", ") or nil,
                }
            end
        end
    end

    -- INI-only research spells not in the LazBis roster.
    for _, rec in ipairs(ini_recipes or {}) do
        if rec.norm and not seen[rec.norm] then
            seen[rec.norm] = true
            rows[#rows + 1] = {
                level = tonumber(rec.level) or 0,
                name = rec.name,
                norm = rec.norm,
                sourceKind = "research",
                source = "INI only",
                location = "Research",
                nonResearch = false,
                inIni = true,
                recipeTip = rec.ingredients and #rec.ingredients > 0
                    and table.concat(rec.ingredients, ", ") or nil,
            }
        end
    end

    table.sort(rows, function(a, b)
        if a.level == b.level then return (a.name or "") < (b.name or "") end
        return (a.level or 0) > (b.level or 0)
    end)
    return rows
end

-- Evaluate one character against a class roster.
--   spell_book: normalized book table (Catalog.spell_book_from_snap /
--               spell_book_from_want_missing) or nil when nothing is synced.
--   inventory_info: function(display_name, spell_book) -> { inBook, scroll,
--               noData, partial } (Catalog.spell_inventory_info with
--               allowLive=false). Injected so tests can fake it.
-- Returns array of display rows (same order as roster):
--   { level, name, location, kind = "owned"|"missing"|"unknown",
--     nonResearch, recipeTip, partial }
function core.eval_char_rows(roster, spell_book, inventory_info)
    local out = {}
    for _, r in ipairs(roster or {}) do
        local kind
        local partial = false
        if spell_book == nil then
            kind = "unknown"
        else
            local inv = inventory_info(r.name, spell_book) or {}
            partial = inv.partial == true
            if inv.noData then
                kind = "unknown"
            elseif inv.inBook or (tonumber(inv.scroll) or 0) > 0 then
                kind = "owned"
            else
                kind = "missing"
            end
        end
        out[#out + 1] = {
            level = r.level,
            name = r.name,
            location = r.location,
            kind = kind,
            nonResearch = r.nonResearch,
            recipeTip = r.recipeTip,
            partial = partial,
        }
    end
    return out
end

-- Draw-time filter + per-level grouping + summary. Cheap enough to run per
-- frame over ~30 rows, so filter toggles never rebuild anything.
function core.filter_rows(rows, opts)
    opts = type(opts) == "table" and opts or {}
    local level = opts.level -- nil/"all" or number
    if level == "all" then level = nil end
    level = tonumber(level)
    local by_level = {}
    local summary = { total = 0, owned = 0, missing = 0, unknown = 0 }
    for _, row in ipairs(rows or {}) do
        local keep = true
        if level and row.level ~= level then keep = false end
        if keep and opts.hide_non_research and row.nonResearch then keep = false end
        if keep and opts.hide_owned and row.kind == "owned" then keep = false end
        if keep then
            by_level[row.level] = by_level[row.level] or {}
            local bucket = by_level[row.level]
            bucket[#bucket + 1] = row
            summary.total = summary.total + 1
            summary[row.kind] = (summary[row.kind] or 0) + 1
        end
    end
    return by_level, summary
end

-- ===================== runtime wrapper ================================== --

local diag = require('diagnostics')

local ok_catalog, Catalog = pcall(require, 'research_catalog')
if not ok_catalog then Catalog = nil end

local state_idx = {
    class_rosters = {},   -- classKey -> roster rows
    chars = {},           -- char_key -> { sig, class, rows, built_at }
    queue = {},
    queued = {},
    rebuilds = 0,
    catalog_loaded = false,
}

local function ensure_catalog_loaded()
    if state_idx.catalog_loaded or not Catalog then return Catalog ~= nil end
    -- One-time: ini parse (recipes + tooltips) and the LazBis spell roster.
    pcall(function() Catalog.load_ini(false) end)
    pcall(function() Catalog.load_spells_config(false) end)
    state_idx.catalog_loaded = true
    return true
end

local function class_roster(classKey)
    if not Catalog then return nil end
    classKey = Catalog.normalize_class(classKey or "")
    if classKey == "" then return nil end
    local hit = state_idx.class_rosters[classKey]
    if hit then return hit end
    ensure_catalog_loaded()
    local lazClass = Catalog.class_to_laz(classKey)
    local laz_entries = Catalog.load_spells_config(false)
    local class_entries = (type(laz_entries) == "table" and lazClass) and laz_entries[lazClass] or {}
    local roster = core.build_class_roster(
        class_entries,
        Catalog.ini_recipes_for_class(classKey),
        Catalog.classify_source,
        Catalog.product_norm
    )
    state_idx.class_rosters[classKey] = roster
    return roster
end

-- Signature that changes when the character's spell data changes.
local function char_sig(snap)
    if type(snap) ~= "table" then return "" end
    local sig = tostring(snap.spells_sig or "")
    if sig ~= "" then return sig end
    if type(snap.spells) == "table" and snap.spells._partial then return "partial" end
    return "none"
end

-- Resolve the display spell book the same way the old display path did:
-- synced snapshot book first, want-file export fallback for peers.
local function resolve_book(char_key, snap)
    if not Catalog or type(snap) ~= "table" then return nil, "" end
    local book = Catalog.spell_book_from_snap(snap)
    if book then return book, char_sig(snap) end
    if char_key ~= "__self__" then
        local name = trim(snap.name or "")
        if name ~= "" and Catalog.find_want_file_for_character then
            local wf = Catalog.find_want_file_for_character(name)
            if wf and wf.entries and #wf.entries > 0 then
                local partial = Catalog.spell_book_from_want_missing(wf.entries)
                if partial then
                    return partial, "want:" .. tostring(wf.meta and wf.meta.exported or wf.fname or "")
                end
            end
        end
    end
    return nil, char_sig(snap)
end

local function enqueue(char_key)
    char_key = tostring(char_key or "")
    if char_key == "" or state_idx.queued[char_key] then return end
    state_idx.queued[char_key] = true
    state_idx.queue[#state_idx.queue + 1] = { key = char_key }
end

-- Called every frame by the tab with the visible keys and a snapshot resolver
-- (key -> snap). Enqueues characters whose spell signature changed.
function M.ensure(keys, resolver)
    if not Catalog then return end
    for _, key in ipairs(keys or {}) do
        local snap = resolver and resolver(key) or nil
        local known = state_idx.chars[key]
        local sig = char_sig(snap)
        -- Want-file fallback only applies when nothing is synced; retry those
        -- lazily by including the class in the check below, not every frame.
        if not known or (known.snap_sig ~= sig)
            or (snap and known.class ~= tostring(snap.class or "")) then
            enqueue(key)
        end
    end
end

local function rebuild_char(char_key, resolver)
    local snap = resolver and resolver(char_key) or nil
    if type(snap) ~= "table" then
        state_idx.chars[char_key] = nil
        return false
    end
    local roster = class_roster(snap.class)
    if not roster then
        state_idx.chars[char_key] = nil
        return false
    end
    local book, book_sig = resolve_book(char_key, snap)
    local rows = core.eval_char_rows(roster, book, function(name, sb)
        return Catalog.spell_inventory_info(name, nil, sb, false)
    end)
    state_idx.chars[char_key] = {
        snap_sig = char_sig(snap),
        book_sig = book_sig,
        class = tostring(snap.class or ""),
        name = tostring(snap.name or char_key),
        has_book = book ~= nil,
        partial = book ~= nil and book._partial == true,
        rows = rows,
        built_at = os.clock(),
    }
    state_idx.rebuilds = state_idx.rebuilds + 1
    return true
end

function M.tick(budget_ms, resolver)
    if not Catalog or #state_idx.queue == 0 then return end
    diag.time("spells_index.tick", function()
        budget_ms = tonumber(budget_ms) or 5
        local deadline = os.clock() + math.max(1, budget_ms) / 1000
        repeat
            local item = table.remove(state_idx.queue, 1)
            if not item then break end
            state_idx.queued[item.key] = nil
            rebuild_char(item.key, resolver)
        until os.clock() >= deadline or #state_idx.queue == 0
    end)
end

function M.rows_for(char_key)
    local rec = state_idx.chars[char_key]
    return rec and rec.rows or nil
end

function M.char_state(char_key)
    return state_idx.chars[char_key]
end

function M.pending()
    return #state_idx.queue
end

function M.invalidate(char_key)
    if char_key then
        state_idx.chars[char_key] = nil
        return
    end
    state_idx.chars = {}
    state_idx.class_rosters = {}
    state_idx.queue = {}
    state_idx.queued = {}
    state_idx.catalog_loaded = false
end

function M.status()
    local chars = 0
    for _, _ in pairs(state_idx.chars) do chars = chars + 1 end
    return {
        chars = chars,
        queued = #state_idx.queue,
        rebuilds = state_idx.rebuilds,
    }
end

return M
