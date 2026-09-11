-- TurboGear/spell_cache.lua
-- Shared known-ability cache for research + DoN tracked spells.
-- Builder is spell_known (unchanged). Rebuild is event-driven: spell-like
-- inventory removal, startup, or /tgear spellsync — never per-frame.

local mq = require('mq')

local M = {}

local known_by_norm = {}
local known_by_id = {}
local pending_norm = nil
local pending_id = nil
local ready = false
local building = false
local deferred_unready = false
local last_sig = ''
local last_published_sig = ''
local last_spells = nil
local last_ids = nil

local function trim(s)
    return tostring(s or ''):match('^%s*(.-)%s*$') or ''
end

local function norm(s)
    s = trim(s):lower()
    s = s:gsub('`', "'"):gsub('\226\128\152', "'"):gsub('\226\128\153', "'")
    return s
end

local function ensure_spell_known()
    local ok, mod = pcall(require, 'spell_known')
    return ok and mod or nil
end

local function class_name()
    local c = ''
    pcall(function()
        c = (mq.TLO.Me.Class.Name and mq.TLO.Me.Class.Name()) or ''
        if trim(c) == '' then
            c = (mq.TLO.Me.Class.ShortName and mq.TLO.Me.Class.ShortName()) or ''
        end
    end)
    return trim(c)
end

--- Cheap pre-check: Spell:/Song:/Tome name, or DoN learn-item id.
function M.is_spell_like_item(name, id)
    name = tostring(name or '')
    local lower = name:lower()
    if lower:find('^spell:') or lower:find('^song:') then return true end
    if lower:find('tome', 1, true) then return true end
    id = tonumber(id)
    if id and id > 0 then
        local ok, DS = pcall(require, 'don_spells')
        if ok and DS and DS.is_learn_item_id and DS.is_learn_item_id(id) then
            return true
        end
    end
    return false
end

function M.ready()
    return ready == true
end

function M.building()
    return building == true
end

function M.signature()
    return last_sig
end

function M.last_published_signature()
    return last_published_sig
end

local function lookup_known(name_or_id)
    if type(name_or_id) == 'number' then
        return known_by_id[name_or_id] == true
    end
    local as_id = tonumber(name_or_id)
    if as_id and tostring(name_or_id):match('^%s*%d+%s*$') then
        return known_by_id[as_id] == true
    end
    local n = norm(name_or_id)
    if n == '' then return false end
    return known_by_norm[n] == true
end

local function record_known_name(name)
    local dest = (building and pending_norm) or known_by_norm
    if dest then dest[norm(name)] = true end
end

local function record_known_id(spell_id)
    local dest = (building and pending_id) or known_by_id
    if dest then dest[spell_id] = true end
end

--- Record a known spell found by another (already paid) live probe. No TLO work.
function M.note_known(name, spell_id)
    name = trim(name)
    if name ~= '' then record_known_name(name) end
    spell_id = tonumber(spell_id)
    if spell_id and spell_id > 0 then record_known_id(spell_id) end
end

--- Probe via spell_known and record. Used while rebuild enumerates the slice.
--- During rebuild, records go to the pending maps so the previous complete
--- result stays visible until the atomic swap.
function M.probe_name(name)
    name = trim(name)
    if name == '' then return false end
    local SK = ensure_spell_known()
    local known = SK and SK.live_lean and SK.live_lean(name) == true
    if known then record_known_name(name) end
    return known == true
end

function M.probe_id(spell_id)
    spell_id = tonumber(spell_id)
    if not spell_id or spell_id <= 0 then return false end
    local SK = ensure_spell_known()
    local known = SK and SK.live_lean_id and SK.live_lean_id(spell_id) == true
    if known then record_known_id(spell_id) end
    return known == true
end

--- Cache membership. Does not live-scan when startup deferred an unready cache
--- (missing persisted spells is unknown, not "knows nothing").
function M.is_known(name_or_id)
    if building then
        return lookup_known(name_or_id)
    end
    if not ready then
        if deferred_unready then return false end
        M.rebuild()
    end
    return lookup_known(name_or_id)
end

function M.ensure_built()
    if ready or building then return ready end
    if deferred_unready then return false end
    M.rebuild()
    return ready
end

--- Last complete spell maps + signature. Nil when no authority is loaded.
function M.last_maps()
    if not ready then return nil end
    if type(last_sig) ~= 'string' or last_sig == '' then return nil end
    return last_spells, last_ids, last_sig
end

function M.deferred_unready()
    return deferred_unready == true
end

--- Startup with no persisted spell authority: do not manufacture an empty book
--- and do not live-scan on the critical path.
function M.note_deferred_unready()
    if ready or building then return end
    deferred_unready = true
end

--- Hydrate from a persisted snapshot. Missing/empty sig is not authority.
function M.restore_from_snapshot(snap)
    local okP, plan = pcall(require, 'spells_startup')
    if not okP or not plan or not plan.snapshot_is_usable or not plan.snapshot_is_usable(snap) then
        return false, 'missing'
    end
    local new_norm, new_id = {}, {}
    if type(snap.spells) == 'table' then
        for key, row in pairs(snap.spells) do
            if type(row) == 'table' then
                local book = (row.book == true) or ((tonumber(row.book) or 0) > 0)
                if book then
                    new_norm[norm(row.name or key)] = true
                    local sid = tonumber(row.spell_id)
                    if sid and sid > 0 then new_id[sid] = true end
                end
            end
        end
    end
    if type(snap.spell_ids) == 'table' then
        for id, v in pairs(snap.spell_ids) do
            if v then
                id = tonumber(id) or 0
                if id > 0 then new_id[id] = true end
            end
        end
    end
    known_by_norm = new_norm
    known_by_id = new_id
    last_spells = snap.spells
    last_ids = snap.spell_ids
    last_sig = tostring(snap.spells_sig)
    last_published_sig = last_sig
    ready = true
    building = false
    deferred_unready = false
    return true, 'restored'
end

--- One pass over the tracked lite slice (research + DoN) via spell_known.
--- Previous complete maps stay visible until this replacement swaps atomically.
--- Returns true when the known-set signature changed.
function M.rebuild(className)
    if building then return false end
    building = true
    pending_norm, pending_id = {}, {}
    local prev = last_sig
    className = trim(className)
    if className == '' then className = class_name() end

    pcall(function()
        local diag = require('diagnostics')
        diag.count('snapshot.spells.live_refresh_started')
        diag.event('snapshot.spells.live_refresh_started', 'source=spell_cache.rebuild class=' .. tostring(className or ''))
    end)
    local spells, spell_ids = {}, {}
    -- perfdiag: whole-scan wall ms + TLO lookups (book probes + scroll counts).
    local okK, SK = pcall(require, 'spell_known')
    local okR, RC = pcall(require, 'research_catalog')
    if okK and SK and SK.reset_lookup_count then SK.reset_lookup_count() end
    if okR and RC and RC.reset_scroll_query_count then RC.reset_scroll_query_count() end
    local scan_t0 = os.clock()
    pcall(function()
        local spell_snap = require('spell_snapshot')
        spells, spell_ids = spell_snap.gather(className)
    end)
    pcall(function()
        local diag = require('diagnostics')
        local lookups = (okK and SK and SK.lookup_count and SK.lookup_count() or 0)
            + (okR and RC and RC.scroll_query_count and RC.scroll_query_count() or 0)
        diag.sample('spell_cache.rebuild_ms', math.max(0, (os.clock() - scan_t0) * 1000))
        diag.sample('spell_cache.rebuild_lookups', lookups)
    end)

    for id, v in pairs(spell_ids or {}) do
        if v then
            id = tonumber(id) or 0
            if id > 0 then pending_id[id] = true end
        end
    end
    for key, row in pairs(spells or {}) do
        if type(row) == 'table' then
            local book = (row.book == true) or ((tonumber(row.book) or 0) > 0)
            if book then
                pending_norm[norm(row.name or key)] = true
                local sid = tonumber(row.spell_id)
                if sid and sid > 0 then pending_id[sid] = true end
            end
        end
    end

    local new_sig = ''
    local okSig, spell_snap = pcall(require, 'spell_snapshot')
    if okSig and spell_snap and spell_snap.signature then
        new_sig = spell_snap.signature(spells, spell_ids) or ''
    else
        local parts = {}
        for n, _ in pairs(pending_norm) do parts[#parts + 1] = 'n' .. n end
        for id, _ in pairs(pending_id) do
            if id > 0 then parts[#parts + 1] = 'i' .. tostring(id) end
        end
        table.sort(parts)
        new_sig = table.concat(parts, '\31')
    end

    -- Failed/empty gather is not authority. Keep the previous complete result.
    local has_rows = type(spells) == 'table' and next(spells) ~= nil
    local has_ids = type(spell_ids) == 'table' and next(spell_ids) ~= nil
    if new_sig == '' and not has_rows and not has_ids then
        pending_norm, pending_id = nil, nil
        building = false
        return false
    end

    known_by_norm = pending_norm
    known_by_id = pending_id
    pending_norm, pending_id = nil, nil
    last_spells = spells
    last_ids = spell_ids
    last_sig = new_sig
    ready = true
    building = false
    deferred_unready = false
    pcall(function()
        local diag = require('diagnostics')
        diag.count('snapshot.spells.live_refresh_completed')
        diag.event('snapshot.spells.live_refresh_completed', 'source=spell_cache.rebuild')
    end)
    return last_sig ~= prev
end

--- Publish via the same path as Spells tab / spellsync when sig changed.
--- Engine.publish(force, lite, includeSpells) re-gathers with spells baked in.
function M.publish_if_changed(reason)
    reason = tostring(reason or 'spell_cache')
    if not ready then M.rebuild() end
    if last_sig ~= '' and last_sig == last_published_sig then
        return false, 'unchanged'
    end
    local okSnap, snapshot = pcall(require, 'snapshot')
    if okSnap and snapshot and snapshot.invalidate then snapshot.invalidate() end
    local okE, Engine = pcall(function() return require('engine').Engine end)
    if not okE or not Engine or not Engine.ok or not Engine.publish then
        return false, 'no engine'
    end
    local sent = Engine.publish(true, 'lite', {
        includeSpells = true,
        reason = reason,
        skipLockouts = true,
        skipLiveStats = true,
    })
    if sent then
        last_published_sig = last_sig
        pcall(function()
            local cached = snapshot and snapshot.cached and snapshot.cached()
            if cached and cached.spells_sig then
                last_published_sig = cached.spells_sig
            end
        end)
        return true, 'published'
    end
    return false, 'publish skipped'
end

function M.mark_published(spells_sig)
    last_published_sig = tostring(spells_sig or last_sig or '')
end

-- Test helper
function M._reset_for_tests()
    known_by_norm, known_by_id = {}, {}
    pending_norm, pending_id = nil, nil
    ready, building = false, false
    deferred_unready = false
    last_sig, last_published_sig = '', ''
    last_spells, last_ids = nil, nil
end

return M
