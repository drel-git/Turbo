-- TurboGear/needs_index.lua
-- Inverted "who needs this item" index for the announce path. Instead of
-- scanning every cached snapshot against the catalog when an item is linked,
-- we precompute, per character, the set of announce-list entries that are
-- missing, and merge them into item-id / item-name lookup tables. A chat link
-- then resolves to needers with a couple of hash lookups.
--
-- Rebuilds are incremental and budgeted: a character is re-evaluated only when
-- its Store content signature (or the local snapshot signature) changes, at
-- most a few characters per tick. Pure index logic lives in M.core so it can
-- be unit-tested offline (tests/turbogear_needs_index_test.lua).

local M = { core = {} }
local core = M.core

-- ========================= pure core ==================================== --

local function trim(s)
    return tostring(s or ""):match("^%s*(.-)%s*$") or ""
end

-- Key builders run several regex gsubs and are invoked per alias name per
-- entry per rebuild (80+ aliases on expanded fungal/Jonas entries) - they
-- were ~20ms/entry in Rydell's 16:51 log. The name vocabulary is small and
-- stable, so both are memoized per input string.
local norm_key_cache = {}
local strip_key_cache = {}
-- Sizes are tracked on insert so cache_sizes() is O(1) (Lua has no cheap table
-- count). Safety valve (R3): the catalog alias vocabulary is small and stable,
-- so these memo tables normally stay tiny. But if a future caller ever routes
-- free-form text through norm_key/strip_key, unbounded growth would result.
-- Cap growth and clear-on-overflow so the worst case is a cheap rebuild, not a
-- leak; core.cache_sizes() surfaces the counts + clear tally for perfdiag.
local norm_key_cache_n = 0
local strip_key_cache_n = 0
local KEY_CACHE_CAP = 20000
local key_cache_clears = 0

-- Loose key: lower + collapsed whitespace (same as announcer.normalize_item_name).
function core.norm_key(name)
    if type(name) ~= "string" then
        local s = trim(name):lower():gsub("%s+", " ")
        return s
    end
    local hit = norm_key_cache[name]
    if hit == nil then
        hit = trim(name):lower():gsub("%s+", " ")
        if norm_key_cache_n >= KEY_CACHE_CAP then
            norm_key_cache = {}
            norm_key_cache_n = 0
            key_cache_clears = key_cache_clears + 1
        end
        norm_key_cache[name] = hit
        norm_key_cache_n = norm_key_cache_n + 1
    end
    return hit
end

-- Uncached normalizer for free-form TEXT (chat lines): unique strings must
-- never enter the memo tables or they grow without bound.
function core.norm_text(s)
    local out = trim(s):lower():gsub("%s+", " ")
    return out
end

local function strip_key_uncached(name)
    local s = core.norm_key(name)
    s = s:gsub("%s*%(%s*[^%)]-%s*%)%s*$", "")
    s = s:gsub("%s*%[%s*[^%]]-%s*%]%s*$", "")
    s = s:gsub("%s+", " ")
    local stripped = s:gsub("%s*%d%d%d+$", "")
    if stripped ~= "" then s = stripped end
    return trim(s)
end

-- Strict-stripped key mirroring bis.norm_item_name: drops trailing
-- parentheticals/brackets and trailing long numbers so catalog aliases like
-- "Blade of War (Azia)" still match a plain "Blade of War" link.
function core.strip_key(name)
    if type(name) ~= "string" then return strip_key_uncached(name) end
    local hit = strip_key_cache[name]
    if hit == nil then
        hit = strip_key_uncached(name)
        if strip_key_cache_n >= KEY_CACHE_CAP then
            strip_key_cache = {}
            strip_key_cache_n = 0
            key_cache_clears = key_cache_clears + 1
        end
        strip_key_cache[name] = hit
        strip_key_cache_n = strip_key_cache_n + 1
    end
    return hit
end

-- Memo-cache sizes (R3 observability). Counts are maintained on insert, so this
-- is O(1). `cap` is the clear-on-overflow threshold; `clears` counts how many
-- times a cache overflowed (should stay 0 in normal operation).
function core.cache_sizes()
    return {
        norm = norm_key_cache_n,
        strip = strip_key_cache_n,
        cap = KEY_CACHE_CAP,
        clears = key_cache_clears,
    }
end

-- Build one character's needs from catalog recs.
--   recs: array of { entry = normalized entry, item_name = display, list_id = ... }
--   evaluator(entry) -> status string ("missing" means needed)
-- Returns { by_id = { id -> need }, by_name = { key -> need }, count = n }
-- where need = { display, entry, list_id }.
--
-- Display names matter for multi-alias entries (fungal chains, Jonas hand,
-- learned aliases): an entry like "X Slime of Suffering" can carry pseudo
-- aliases like "X Fungus of Suffering - Tier II" that are not real item
-- names. Announcing (or link-resolving) those produces linkless garbage.
-- Rules: id hits display the entry's canonical item name; each name key
-- displays the alias that produced it, so a text match shows the name that
-- actually appeared in the line.
-- Evaluate ONE catalog rec into a needs accumulator. Factored out so the
-- runtime can chunk evaluation across ticks (rebuilds are resumable; no
-- single tick can blow its budget regardless of catalog size).
function core.add_entry_needs(needs, seen_entry, rec, evaluator)
    local entry = rec and rec.entry
    if not entry or seen_entry[entry] then return end
    seen_entry[entry] = true
    local status = evaluator and evaluator(entry) or "missing"
    if status ~= "missing" then return end
    local canonical = trim(entry.item)
    if canonical == "" then canonical = trim(rec.item_name) end
    needs.count = needs.count + 1
    for _, id in ipairs(entry.ids or {}) do
        id = tonumber(id)
        if id and id > 0 and not needs.by_id[id] then
            needs.by_id[id] = { display = canonical, entry = entry, list_id = rec.list_id }
        end
    end
    local names = entry.names
    if type(names) ~= "table" or #names == 0 then names = { entry.item } end
    for _, name in ipairs(names) do
        local alias = trim(name)
        if alias ~= "" then
            local need = { display = alias, entry = entry, list_id = rec.list_id }
            for _, key in ipairs({ core.norm_key(alias), core.strip_key(alias) }) do
                if key ~= "" and not needs.by_name[key] then
                    needs.by_name[key] = need
                end
            end
        end
    end
end

function core.build_char_needs(recs, evaluator)
    local needs = { by_id = {}, by_name = {}, count = 0 }
    local seen_entry = {}
    for _, rec in ipairs(recs or {}) do
        core.add_entry_needs(needs, seen_entry, rec, evaluator)
    end
    return needs
end

-- Merge per-character needs into shared lookup tables.
--   chars: { char_key -> { name = display char name, needs = build_char_needs(...) } }
-- Returns { by_id = { id -> { {character, display, entry, char_key} } }, by_name = ..., item_count }
function core.merge(chars)
    local merged = { by_id = {}, by_name = {}, item_count = 0 }
    local ordered = {}
    for key, _ in pairs(chars or {}) do ordered[#ordered + 1] = key end
    table.sort(ordered)
    for _, char_key in ipairs(ordered) do
        local rec = chars[char_key]
        local needs = rec and rec.needs
        if needs then
            merged.item_count = merged.item_count + (tonumber(needs.count) or 0)
            for id, need in pairs(needs.by_id or {}) do
                merged.by_id[id] = merged.by_id[id] or {}
                merged.by_id[id][#merged.by_id[id] + 1] = {
                    character = rec.name, display = need.display,
                    entry = need.entry, char_key = char_key,
                }
            end
            for key, need in pairs(needs.by_name or {}) do
                merged.by_name[key] = merged.by_name[key] or {}
                merged.by_name[key][#merged.by_name[key] + 1] = {
                    character = rec.name, display = need.display,
                    entry = need.entry, char_key = char_key,
                }
            end
        end
    end
    return merged
end

-- Query per-character needs maps directly (no merged structure needed).
-- chars: { char_key -> { name, needs } }. Dedupe is inherent (one hit/char).
-- Name lookups run BEFORE the id lookup: link-parsed ids are unreliable on
-- emu servers, and catalog entries can share id lists across distinct items
-- (Jonas hand bones), so an id-first hit can attribute the wrong item.
-- Display precedence per char: norm alias > strip alias > id hit (canonical).
function core.query_chars(chars, item_name, item_id)
    local out = {}
    item_id = tonumber(item_id) or 0
    local k1 = core.norm_key(item_name)
    local k2 = core.strip_key(item_name)
    if k2 == k1 or k2 == "" then k2 = nil end
    if k1 == "" then k1 = nil end
    local ordered = {}
    for key in pairs(chars or {}) do ordered[#ordered + 1] = key end
    table.sort(ordered)
    for _, char_key in ipairs(ordered) do
        local rec = chars[char_key]
        local needs = rec and rec.needs
        if needs then
            local need = (k1 and needs.by_name[k1])
                or (k2 and needs.by_name[k2])
                or (item_id > 0 and needs.by_id[item_id])
            if need then
                out[#out + 1] = {
                    character = rec.name, display = need.display,
                    entry = need.entry, char_key = char_key,
                }
            end
        end
    end
    return out
end

-- Canonical dedupe key for a text-scan hit: the ENTRY's canonical item name,
-- not the alias that matched. One catalog entry can carry alias pairs where
-- one is a substring of the other (Jonas hand: "Triquetrum" and "Jonas
-- Dagmire's Triquetrum"), so a single chat mention matches BOTH name keys;
-- deduping by alias display announced the same item twice under two names.
local function text_hit_canonical(entry, display)
    local canonical = entry and core.strip_key(entry.item) or ""
    if canonical ~= "" then return canonical end
    return core.strip_key(display)
end

-- Text-line scan over per-character needs maps. Same key volume as the old
-- merged scan; runs only on qualifying chat lines. Matches are ranked
-- longest-key-first BEFORE deduping so the most specific alias found in the
-- line ("Jonas Dagmire's Triquetrum", not "Triquetrum") is the one displayed.
function core.text_candidates_chars(chars, line, limit)
    local out = {}
    line = core.norm_text(line)
    if line == "" then return out end
    local matches = {}
    for _, rec in pairs(chars or {}) do
        local needs = rec and rec.needs
        if needs then
            for key, need in pairs(needs.by_name or {}) do
                if key ~= "" and #key >= 3 and line:find(key, 1, true) then
                    matches[#matches + 1] = { key = key, need = need }
                end
            end
        end
    end
    table.sort(matches, function(a, b) return #a.key > #b.key end)
    local seen = {}
    for _, m in ipairs(matches) do
        local need = m.need
        local dedupe = text_hit_canonical(need.entry, need.display)
        if dedupe ~= "" and not seen[dedupe] then
            seen[dedupe] = true
            local id = 0
            for _, eid in ipairs((need.entry and need.entry.ids) or {}) do
                eid = tonumber(eid)
                if eid and eid > 0 then id = math.floor(eid); break end
            end
            out[#out + 1] = { name = need.display, id = id }
        end
    end
    limit = math.max(1, math.floor(tonumber(limit) or 24))
    while #out > limit do table.remove(out) end
    for _, hit in ipairs(out) do
        hit.needers = core.query_chars(chars, hit.name, hit.id)
    end
    return out
end

-- Look up needers for a linked item. Dedupes by character.
-- (Merged-structure variant; kept for compatibility/tests. The runtime now
-- queries per-character maps via query_chars.)
function core.query(merged, item_name, item_id)
    local out, seen = {}, {}
    local function add_all(list)
        for _, need in ipairs(list or {}) do
            local ck = tostring(need.char_key or need.character or "")
            if ck ~= "" and not seen[ck] then
                seen[ck] = true
                out[#out + 1] = need
            end
        end
    end
    item_id = tonumber(item_id) or 0
    if merged then
        -- Name before id, same rationale as query_chars.
        local k1 = core.norm_key(item_name)
        if k1 ~= "" then add_all(merged.by_name[k1]) end
        local k2 = core.strip_key(item_name)
        if k2 ~= "" and k2 ~= k1 then add_all(merged.by_name[k2]) end
        if item_id > 0 then add_all(merged.by_id[item_id]) end
    end
    return out
end

-- Find needed item names appearing in a plain-text chat line. Only scans the
-- needed-name keys (a small set), not the whole catalog. Longest names first;
-- alias variants of one entry collapse to a single hit (see text_hit_canonical).
function core.text_candidates(merged, line, limit)
    local out = {}
    line = core.norm_text(line)
    if line == "" or not merged then return out end
    local matches = {}
    for key, list in pairs(merged.by_name or {}) do
        if key ~= "" and #key >= 3 and line:find(key, 1, true) then
            local first = list and list[1]
            if first then matches[#matches + 1] = { key = key, first = first } end
        end
    end
    table.sort(matches, function(a, b) return #a.key > #b.key end)
    local seen = {}
    for _, m in ipairs(matches) do
        local first = m.first
        local display = first.display or m.key
        local dedupe = text_hit_canonical(first.entry, display)
        if dedupe ~= "" and not seen[dedupe] then
            seen[dedupe] = true
            local id = 0
            if first.entry then
                for _, eid in ipairs(first.entry.ids or {}) do
                    eid = tonumber(eid)
                    if eid and eid > 0 then id = math.floor(eid); break end
                end
            end
            out[#out + 1] = { name = display, id = id }
        end
    end
    limit = math.max(1, math.floor(tonumber(limit) or 24))
    while #out > limit do table.remove(out) end
    for _, hit in ipairs(out) do
        hit.needers = core.query(merged, hit.name, hit.id)
    end
    return out
end

-- ===================== runtime wrapper ================================== --

local mq = require('mq')
local cfg = require('config')
local CFG, SharedSettings = cfg.CFG, cfg.SharedSettings
local Store = require('store').Store
local diag = require('diagnostics')
local roster_sets = require('roster_sets')

local state_idx = {
    chars = {},          -- char_key -> { name, sig, needs }
    merged = nil,
    merged_dirty = false,
    settings_sig = nil,
    last_store_content_version = -1,
    last_scan_at = 0,
    last_local_scan_at = 0,
    queue = {},          -- ordered char keys pending rebuild
    queued = {},         -- set for dedupe
    building = nil,      -- in-progress resumable char build
    built_at = 0,
    rebuilds = 0,        -- successful character evaluations
    attempts = 0,        -- all rebuild attempts (incl. failures)
    failures = 0,        -- failed attempts (tombstoned until sig changes)
    enqueue_counts = {},
    queued_at = {},
    last_enqueue = nil,
    builds_started = 0,
    builds_finished = 0,
    eval_entries = 0,
    max_single_entry_ms = 0,
    last_build = nil,
}

-- Scans are EVENT-DRIVEN (Store.content_version changes); this cadence is
-- only a safety sweep for visibility flaps that don't touch content.
local SCAN_EVERY_S = 30.0

-- Local snapshot signature memo, weak-keyed by the snapshot TABLE: the sig is
-- computed once per gathered snapshot instead of once per scan (lite_signature
-- walks every item+aug and was the steady ~80ms/scan cost in Rydell's logs).
-- New gathers create new tables, so a changed inventory naturally re-keys.
local local_sig_cache = setmetatable({}, { __mode = "k" })

local function me_name()
    return tostring(mq.TLO.Me.CleanName() or "")
end

-- Server + character never change within a session; cache the key so scans
-- do zero TLO calls (they were called per character per scan).
local cached_local_key = nil

local function local_char_key()
    if cached_local_key then return cached_local_key end
    local server = tostring(mq.TLO.MacroQuest.Server() or "?")
    local name = me_name()
    local key = server .. "_" .. name
    if server ~= "?" and name ~= "" then
        cached_local_key = key
    end
    return key
end

local function is_local_key(char_key)
    return tostring(char_key or "") == local_char_key()
end

local function settings_signature()
    local parts = {}
    local disabled = SharedSettings.bisAnnounceDisabledLists
    if type(disabled) == "table" then
        for k, v in pairs(disabled) do
            if v then parts[#parts + 1] = tostring(k) end
        end
    end
    table.sort(parts)
    local set_parts = {}
    if type(SharedSettings.characterSets) == "table" then
        for id, rec in pairs(SharedSettings.characterSets) do
            local members = {}
            if type(rec) == "table" and type(rec.members) == "table" then
                for name, label in pairs(rec.members) do
                    members[#members + 1] = tostring(name) .. "=" .. tostring(label)
                end
            end
            table.sort(members)
            local rec_name = type(rec) == "table" and rec.name or ""
            set_parts[#set_parts + 1] = tostring(id) .. ":" .. tostring(rec_name or "") .. ":" .. table.concat(members, ",")
        end
    end
    table.sort(set_parts)
    return table.concat({
        tostring(SharedSettings.bisAnnounceEnabled ~= false),
        tostring(cfg.Settings.bisListMode or ""),
        tostring(cfg.Settings.bisSelectedList or ""),
        tostring(cfg.Settings.bisRosterScope or "online"),
        tostring(cfg.Settings.bisViewKey or "__all__"),
        (function()
            local selected = cfg.Settings.bisViewSelectedChars
            if type(selected) ~= "table" then return "" end
            local selected_parts = {}
            for k, v in pairs(selected) do selected_parts[#selected_parts + 1] = tostring(k) .. "=" .. tostring(v) end
            table.sort(selected_parts)
            return table.concat(selected_parts, ",")
        end)(),
        table.concat(parts, ","),
        table.concat(set_parts, "\30"),
    }, "\31")
end

local function sig_brief(sig)
    sig = tostring(sig or "")
    if sig == "" then return "empty" end
    return string.format("len=%d head=%s", #sig, sig:sub(1, 24):gsub("[%c\31\30]", "."))
end

local function store_change_brief(char_key)
    local by_key = Store.last_content_change_by_key
    local c = type(by_key) == "table" and by_key[tostring(char_key or "")] or nil
    if type(c) ~= "table" then c = Store.last_content_change end
    if type(c) ~= "table" then return "" end
    return string.format(" source=%s changed=%s depth=%s eq=%d bag=%d bank=%d v=%s",
        tostring(c.source or "?"), tostring(c.name or c.key or "?"), tostring(c.depth or "?"),
        tonumber(c.equipped) or 0, tonumber(c.bags) or 0, tonumber(c.bank) or 0,
        tostring(c.version or "?"))
end

local function enqueue(char_key, reason, detail)
    char_key = tostring(char_key or "")
    if char_key == "" or state_idx.queued[char_key] then return end
    reason = tostring(reason or "changed")
    detail = tostring(detail or "")
    state_idx.enqueue_counts[reason] = (state_idx.enqueue_counts[reason] or 0) + 1
    state_idx.last_enqueue = {
        key = char_key,
        reason = reason,
        detail = detail,
        at = os.clock(),
    }
    diag.count("needs_index.enqueue." .. reason)
    diag.event("needs_index.enqueue", string.format("%s reason=%s %s%s",
        char_key, reason, detail, store_change_brief(char_key)))
    state_idx.queued[char_key] = true
    state_idx.queued_at[char_key] = os.clock()
    if is_local_key(char_key) then
        table.insert(state_idx.queue, 1, char_key)
    else
        state_idx.queue[#state_idx.queue + 1] = char_key
    end
end

local function local_snapshot()
    local ok, snapshot = pcall(require, 'snapshot')
    if not ok or not snapshot then return nil end
    return snapshot.cached()
end

-- Resolve the snapshot + change signature for a character key.
-- CRITICAL: signatures can be 50-100KB strings (full content serializations).
-- Return them BY REFERENCE and compare with ==, which is a pointer compare on
-- interned Lua strings. Never concatenate onto them - `"store:" .. sig` was
-- re-interning ~100KB x 6 chars every scan (the steady 66-133ms scan cost in
-- Rydell's 16:37 log).
local function char_state(char_key)
    if char_key == local_char_key() then
        -- Prefer the bg-published Store snapshot + content signature: the sig
        -- is reference-stable and free to compare, changes exactly when the
        -- inventory really changes (delta/publish driven), and matches the
        -- snapshot it describes. Recomputing lite_signature per fresh gather
        -- table was Rydell's residual 133ms scan cost. The lite path remains
        -- only as a cold-start fallback (bg not yet published).
        local store_snap = Store.get(char_key)
        local store_sig = Store.content_signatures and Store.content_signatures[char_key]
        if store_snap and store_sig and store_sig ~= "" then
            return store_snap, store_sig
        end
        local snap = local_snapshot() or store_snap
        if not snap then return nil, nil end
        local sig = local_sig_cache[snap]
        if sig == nil then
            local ok, computed = pcall(function()
                return require('snapshot').lite_signature(snap)
            end)
            sig = ok and tostring(computed or "")
                or tostring(snap.inventoryUpdated or snap.updated or "")
            local_sig_cache[snap] = sig
        end
        return snap, sig
    end
    local snap = Store.get(char_key)
    if not snap then return nil, nil end
    local sig = Store.content_signatures and Store.content_signatures[char_key]
    if sig == nil or sig == "" then
        sig = tostring(snap.inventoryUpdated or snap.updated or "")
    end
    return snap, sig
end

local function visible_char_keys()
    return roster_sets.active_store_keys(cfg.Settings.bisRosterScope or "online", { for_announce = true })
end

local function visible_char_key_set()
    local set = {}
    for _, key in ipairs(visible_char_keys()) do
        set[tostring(key or "")] = true
    end
    return set
end

local function filter_visible_needers(needers, visible)
    local out = {}
    visible = visible or visible_char_key_set()
    for _, need in ipairs(needers or {}) do
        if visible[tostring(need and need.char_key or "")] then
            out[#out + 1] = need
        end
    end
    return out
end

local function local_needs_work()
    local key = local_char_key()
    if state_idx.building and is_local_key(state_idx.building.char_key) then return true end
    if state_idx.queued[key] then return true end
    local _, csig = char_state(key)
    if not csig or csig == "" then return false end
    local known = state_idx.chars[key]
    return not known or known.failed == true or known.sig ~= csig
end

local function char_needs_current(char_key)
    local _, csig = char_state(char_key)
    if not csig or csig == "" then return false end
    local rec = state_idx.chars[tostring(char_key or "")]
    return rec ~= nil and rec.needs ~= nil and rec.sig == csig
end

local function visible_needs_work()
    for _, key in ipairs(visible_char_keys()) do
        if not char_needs_current(key) then return true end
    end
    return false
end

local function queue_has_peer_work()
    for _, key in ipairs(state_idx.queue or {}) do
        if not is_local_key(key) then return true end
    end
    return state_idx.building ~= nil and not is_local_key(state_idx.building.char_key)
end

local function pop_next_queued(allow_peers)
    for i, key in ipairs(state_idx.queue or {}) do
        if allow_peers or is_local_key(key) then
            table.remove(state_idx.queue, i)
            state_idx.queued[key] = nil
            state_idx.queued_at[key] = nil
            return key
        end
    end
    return nil
end

-- Collect catalog recs for a character (announce-enabled lists resolved for
-- that character's class/owner). Uses the memoized direct catalog.
local function recs_for_char(snap)
    local ok, catalog = pcall(require, 'bis_catalog')
    if not ok or not catalog or not catalog.direct_catalog_for then return nil end
    local idx = catalog.direct_catalog_for(snap.class, snap.name)
    if type(idx) ~= "table" then return nil end
    local recs, seen = {}, {}
    for _, list in pairs(idx.by_name or {}) do
        for _, rec in ipairs(list or {}) do
            if rec.entry and not seen[rec.entry] then
                seen[rec.entry] = true
                recs[#recs + 1] = rec
            end
        end
    end
    return recs
end

-- A failed rebuild (no snapshot, unknown class, catalog unavailable) must NOT
-- be retried every scan: that was the "constant 630ms tick" bug - a discovered
-- peer with class "?" failed forever, and every failure marked the merged
-- index dirty, forcing a full core.merge (O(all needs)) every single tick.
-- Failures now leave a tombstone carrying the signature; the character is only
-- retried when its signature actually changes (e.g. a real snapshot arrives).
local function tombstone_char(char_key, sig)
    state_idx.chars[char_key] = { failed = true, sig = tostring(sig or ""), name = char_key }
    state_idx.failures = (state_idx.failures or 0) + 1
    return false
end

-- Resumable rebuilds: starting a character captures its snapshot, signature,
-- and catalog recs; evaluation then proceeds in chunks across ticks, checking
-- the deadline every entry. The character is only committed (and only
-- becomes queryable) once fully evaluated.
local EVAL_DEADLINE_CHECK = 1

-- Returns "deferred" when the character's direct catalog is still being
-- built asynchronously (the caller keeps the char queued and retries next
-- tick); true/false otherwise.
local function start_char_build(char_key, deadline)
    local snap, sig = char_state(char_key)
    if not snap or not snap.class or snap.class == "?" then
        state_idx.attempts = (state_idx.attempts or 0) + 1
        return tombstone_char(char_key, sig)
    end
    -- Advance the async catalog build within our budget; never build sync.
    local ok_cat, catalog = pcall(require, 'bis_catalog')
    if ok_cat and catalog and catalog.tick_direct_build then
        local idx
        diag.time("needs_index.catalog", function()
            idx = catalog.tick_direct_build(snap.class, snap.name, deadline)
        end)
        if not idx then
            return "deferred"
        end
    end
    state_idx.attempts = (state_idx.attempts or 0) + 1
    local recs
    diag.time("needs_index.recs", function()
        recs = recs_for_char(snap)
    end)
    local ok_bis, bis = pcall(require, 'bis')
    if not recs or not ok_bis or not bis then
        return tombstone_char(char_key, sig)
    end
    state_idx.building = {
        char_key = char_key,
        snap = snap,
        sig = sig,
        recs = recs,
        i = 1,
        bis = bis,
        needs = { by_id = {}, by_name = {}, count = 0 },
        seen = {},
        started_at = os.clock(),
        rec_count = #recs,
    }
    state_idx.builds_started = (state_idx.builds_started or 0) + 1
    diag.count("needs_index.build_started")
    diag.event("needs_index.build_start", string.format("%s recs=%d%s",
        tostring(char_key), #recs, store_change_brief(char_key)))
    return true
end

local function continue_char_build(deadline)
    local b = state_idx.building
    if not b then return end
    local processed = 0
    diag.time("needs_index.evaluate", function()
        local recs, n = b.recs, #b.recs
        local i = b.i
        local evaluator = function(entry)
            -- skip_live: never run per-entry FindItem storms during index
            -- builds; announce paths live-confirm individual hits instead.
            local row = b.bis.evaluate_entry(entry, b.snap, { skip_live = true })
            return row and row.status or "missing"
        end
        local diag_on = diag.is_enabled and diag.is_enabled() or false
        while i <= n do
            if diag_on then
                local entry_t0 = os.clock()
                core.add_entry_needs(b.needs, b.seen, recs[i], evaluator)
                local entry_ms = (os.clock() - entry_t0) * 1000
                if entry_ms > (state_idx.max_single_entry_ms or 0) then
                    state_idx.max_single_entry_ms = entry_ms
                end
                if entry_ms >= 5 then
                    diag.sample("needs_index.entry_eval", entry_ms)
                end
            else
                core.add_entry_needs(b.needs, b.seen, recs[i], evaluator)
            end
            processed = processed + 1
            i = i + 1
            if i % EVAL_DEADLINE_CHECK == 0 and os.clock() >= deadline then break end
        end
        b.i = i
    end)
    if processed > 0 then
        state_idx.eval_entries = (state_idx.eval_entries or 0) + processed
        diag.count("needs_index.eval_entries", processed)
    end
    if b.i > #b.recs then
        state_idx.chars[b.char_key] = {
            name = tostring(b.snap.name or b.char_key),
            sig = b.sig,
            needs = b.needs,
        }
        state_idx.rebuilds = (state_idx.rebuilds or 0) + 1
        state_idx.builds_finished = (state_idx.builds_finished or 0) + 1
        local elapsed_ms = (os.clock() - (tonumber(b.started_at) or os.clock())) * 1000
        state_idx.last_build = {
            key = b.char_key,
            recs = tonumber(b.rec_count) or #b.recs,
            needs = tonumber(b.needs and b.needs.count) or 0,
            elapsed_ms = elapsed_ms,
        }
        diag.sample("needs_index.build_total", elapsed_ms)
        diag.event("needs_index.build_finish", string.format("%s recs=%d needs=%d elapsed=%.1fms",
            tostring(b.char_key), tonumber(b.rec_count) or #b.recs,
            tonumber(b.needs and b.needs.count) or 0, elapsed_ms))
        state_idx.building = nil
    end
    return processed
end

local function scan_for_changes(opts)
    opts = type(opts) == "table" and opts or {}
    local allow_peers = opts.allow_peers ~= false and opts.local_only ~= true
    local now = os.clock()
    -- Throttle applies UNCONDITIONALLY: a busy queue is no reason to rescan
    -- (scanning per tick while a slow warm-up held the queue was the constant
    -- 66-134ms stutter in the 17:40 log). Scans re-run only when content
    -- actually changed or on the slow safety sweep.
    if allow_peers then
        if (now - state_idx.last_scan_at) < SCAN_EVERY_S then
            local cv = tonumber(Store.content_version) or 0
            local settings_changed = settings_signature() ~= state_idx.settings_sig
            if cv == state_idx.last_store_content_version
                and not settings_changed
                and not visible_needs_work() then
                return
            end
        end
        state_idx.last_scan_at = now
        state_idx.last_store_content_version = tonumber(Store.content_version) or 0
    else
        if (now - state_idx.last_local_scan_at) < SCAN_EVERY_S and not local_needs_work() then return end
        state_idx.last_local_scan_at = now
    end

    local sig = settings_signature()
    if sig ~= state_idx.settings_sig then
        diag.event("needs_index.settings", "settings signature changed; clearing indexed chars")
        state_idx.settings_sig = sig
        state_idx.chars = {}
    end

    local building_key = state_idx.building and state_idx.building.char_key or nil
    local present = {}
    local keys = { local_char_key() }
    if allow_peers then keys = visible_char_keys() end
    for _, key in ipairs(keys) do
        present[key] = true
        if key ~= building_key then
            local _, csig = char_state(key)
            local known = state_idx.chars[key]
            if csig and (not known or known.sig ~= csig) then
                enqueue(key, known and "sig_change" or "new_char",
                    string.format("known=%s current=%s", sig_brief(known and known.sig), sig_brief(csig)))
            end
        end
    end
    if allow_peers then
        for key, _ in pairs(state_idx.chars) do
            if not present[key] then
                diag.event("needs_index.remove", "not visible: " .. tostring(key))
                state_idx.chars[key] = nil
            end
        end
    end
end

-- ========================= public api =================================== --

function M.tick(budget_ms, opts)
    if SharedSettings.bisAnnounceEnabled == false then return end
    opts = type(opts) == "table" and opts or {}
    local allow_peers = opts.allow_peers ~= false and opts.local_only ~= true
    return diag.time("needs_index.tick", function()
        diag.time("needs_index.scan", function() scan_for_changes(opts) end)
        budget_ms = tonumber(budget_ms) or 6
        local deadline = os.clock() + math.max(1, budget_ms) / 1000
        -- Budgeted, resumable work loop: continue an in-progress character
        -- build first; start the next queued one only if budget remains.
        -- "deferred" = that char's direct catalog is still building async;
        -- keep it at the queue head and retry next tick.
        while os.clock() < deadline do
            if state_idx.building then
                if not allow_peers and not is_local_key(state_idx.building.char_key) then break end
                continue_char_build(deadline)
                if state_idx.building then break end -- budget hit mid-build
            else
                local char_key = pop_next_queued(allow_peers)
                if not char_key then break end
                local result = start_char_build(char_key, deadline)
                if result == "deferred" then
                    state_idx.queued[char_key] = true
                    state_idx.queued_at[char_key] = state_idx.queued_at[char_key] or os.clock()
                    table.insert(state_idx.queue, is_local_key(char_key) and 1 or (#state_idx.queue + 1), char_key)
                    break
                end
            end
        end
        -- No merged structure exists anymore: queries walk the per-character
        -- need maps directly (a handful of hash lookups per chat link).
        if #state_idx.queue == 0 and not state_idx.building and state_idx.built_at == 0 then
            state_idx.built_at = os.clock()
        end
    end)
end

-- Cheap "does tick have work" probe for the announcer's early-out.
function M.needs_tick(opts)
    if SharedSettings.bisAnnounceEnabled == false then return false end
    opts = type(opts) == "table" and opts or {}
    local allow_peers = opts.allow_peers ~= false and opts.local_only ~= true
    if state_idx.building ~= nil then
        return allow_peers or is_local_key(state_idx.building.char_key)
    end
    if local_needs_work() then return true end
    if allow_peers and queue_has_peer_work() then return true end
    if allow_peers and (tonumber(Store.content_version) or 0) ~= state_idx.last_store_content_version then return true end
    if settings_signature() ~= state_idx.settings_sig then return true end
    if allow_peers and visible_needs_work() then return true end
    local age = os.clock() - (allow_peers and state_idx.last_scan_at or state_idx.last_local_scan_at)
    return age >= SCAN_EVERY_S
end

-- Ready = the local character's needs are built and no rebuilds are pending.
-- This is enough for local announce checks, but not enough for grouped
-- announcing; grouped callers need group_ready() so a local-only/minimized
-- index cannot hide a peer's need.
function M.ready()
    if #state_idx.queue > 0 or state_idx.building ~= nil then return false end
    local rec = state_idx.chars[local_char_key()]
    return rec ~= nil and rec.needs ~= nil
end

function M.local_ready()
    local rec = state_idx.chars[local_char_key()]
    return rec ~= nil and rec.needs ~= nil
end

function M.group_ready()
    if #state_idx.queue > 0 or state_idx.building ~= nil then return false end
    return not visible_needs_work()
end

function M.peer_work_pending()
    return queue_has_peer_work()
end

-- Needers for a linked item. Local character hits are confirmed against live
-- FindItem so an item looted seconds ago never gets announced as needed.
function M.needers_for(item_name, item_id)
    local out = {}
    local local_key = local_char_key()
    local visible = visible_char_key_set()
    for _, need in ipairs(filter_visible_needers(core.query_chars(state_idx.chars, item_name, item_id), visible)) do
        local keep = true
        if need.char_key == local_key then
            local ok, owned = pcall(function()
                local bis = require('bis')
                return bis.live_own_item(need.entry, need.display or item_name, item_id)
            end)
            if ok and owned then
                keep = false
                enqueue(local_key, "live_owned", tostring(need.display or item_name or "")) -- index is stale for us; refresh
            end
        end
        if keep then out[#out + 1] = need end
    end
    return out
end

-- Needed items mentioned in a plain chat line, each with its needers.
function M.text_needs(line, limit)
    local hits = core.text_candidates_chars(state_idx.chars, line, limit)
    local local_key = local_char_key()
    local visible = visible_char_key_set()
    for _, hit in ipairs(hits) do
        local filtered = {}
        for _, need in ipairs(filter_visible_needers(hit.needers or {}, visible)) do
            local keep = true
            if need.char_key == local_key then
                local ok, owned = pcall(function()
                    local bis = require('bis')
                    return bis.live_own_item(need.entry, need.display or hit.name, hit.id)
                end)
                if ok and owned then
                    keep = false
                    enqueue(local_key, "live_owned", tostring(need.display or hit.name or ""))
                end
            end
            if keep then filtered[#filtered + 1] = need end
        end
        hit.needers = filtered
    end
    return hits
end

function M.char_count()
    local n = 0
    for _, rec in pairs(state_idx.chars) do
        if rec.needs then n = n + 1 end
    end
    return n
end

function M.invalidate(reason)
    diag.event("needs_index.invalidate", tostring(reason or "manual"))
    state_idx.chars = {}
    state_idx.settings_sig = nil
    state_idx.last_store_content_version = -1
    state_idx.queue = {}
    state_idx.queued = {}
    state_idx.queued_at = {}
    state_idx.building = nil
    state_idx.built_at = 0
    state_idx.last_local_scan_at = 0
    state_idx.last_enqueue = nil
    cached_local_key = nil
end

function M.status()
    local tombstoned = 0
    for _, rec in pairs(state_idx.chars) do
        if rec.failed then tombstoned = tombstoned + 1 end
    end
    local items = 0
    for _, rec in pairs(state_idx.chars) do
        if rec.needs then items = items + (tonumber(rec.needs.count) or 0) end
    end
    local catalog_progress = nil
    pcall(function()
        local catalog = require('bis_catalog')
        if catalog.direct_build_progress then
            catalog_progress = catalog.direct_build_progress()
        end
    end)
    local oldest_queue_age_s = 0
    local now = os.clock()
    for _, queued_at in pairs(state_idx.queued_at or {}) do
        local age = now - (tonumber(queued_at) or now)
        if age > oldest_queue_age_s then oldest_queue_age_s = age end
    end
    if state_idx.building and state_idx.building.started_at then
        local age = now - (tonumber(state_idx.building.started_at) or now)
        if age > oldest_queue_age_s then oldest_queue_age_s = age end
    end
    return {
        ready = M.ready(),
        local_ready = M.local_ready(),
        group_ready = M.group_ready(),
        caches = core.cache_sizes(),
        peer_work_pending = queue_has_peer_work(),
        chars = M.char_count(),
        tombstoned = tombstoned,
        queued = #state_idx.queue + (state_idx.building and 1 or 0),
        catalog_build = catalog_progress,
        items = items,
        rebuilds = state_idx.rebuilds or 0,
        attempts = state_idx.attempts or 0,
        failures = state_idx.failures or 0,
        last_enqueue = state_idx.last_enqueue,
        enqueue_counts = state_idx.enqueue_counts,
        builds_started = state_idx.builds_started or 0,
        builds_finished = state_idx.builds_finished or 0,
        eval_entries = state_idx.eval_entries or 0,
        max_single_entry_ms = state_idx.max_single_entry_ms or 0,
        oldest_queue_age_s = oldest_queue_age_s,
        building_key = state_idx.building and state_idx.building.char_key or nil,
        building_i = state_idx.building and state_idx.building.i or nil,
        building_recs = state_idx.building and state_idx.building.rec_count or nil,
        last_build = state_idx.last_build,
        age_s = state_idx.built_at > 0 and (os.clock() - state_idx.built_at) or -1,
    }
end

return M
