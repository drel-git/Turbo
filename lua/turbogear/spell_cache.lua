-- TurboGear/spell_cache.lua
-- Shared known-ability cache for research + DoN tracked spells.
-- Builder is spell_known (unchanged). Rebuild is event-driven: spell-like
-- inventory removal, startup, or /tgear spellsync — never per-frame.

local mq = require('mq')

local M = {}

local known_by_norm = {}
local known_by_id = {}
local ready = false
local building = false
local last_sig = ''
local last_published_sig = ''

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

--- Probe via spell_known and record. Used while rebuild enumerates the slice.
function M.probe_name(name)
    name = trim(name)
    if name == '' then return false end
    local SK = ensure_spell_known()
    local known = SK and SK.live and SK.live(name) == true
    if known then known_by_norm[norm(name)] = true end
    return known == true
end

function M.probe_id(spell_id)
    spell_id = tonumber(spell_id)
    if not spell_id or spell_id <= 0 then return false end
    local SK = ensure_spell_known()
    local known = SK and SK.live_id and SK.live_id(spell_id) == true
    if known then known_by_id[spell_id] = true end
    return known == true
end

--- Cache membership (ensures built). name string or spell_id number.
function M.is_known(name_or_id)
    if building then
        if type(name_or_id) == 'number' then return M.probe_id(name_or_id) end
        local as_id = tonumber(name_or_id)
        if as_id and type(name_or_id) == 'string' and name_or_id:match('^%s*%d+%s*$') then
            return M.probe_id(as_id)
        end
        return M.probe_name(name_or_id)
    end
    if not ready then M.rebuild() end
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

function M.ensure_built()
    if not ready and not building then M.rebuild() end
    return ready
end

--- One pass over the tracked lite slice (research + DoN) via spell_known.
--- Returns true when the known-set signature changed.
function M.rebuild(className)
    if building then return false end
    building = true
    ready = false
    known_by_norm = {}
    known_by_id = {}
    local prev = last_sig
    className = trim(className)
    if className == '' then className = class_name() end

    local spells, spell_ids = {}, {}
    pcall(function()
        local spell_snap = require('spell_snapshot')
        spells, spell_ids = spell_snap.gather(className)
    end)

    for id, v in pairs(spell_ids or {}) do
        if v then known_by_id[tonumber(id) or 0] = true end
    end
    for key, row in pairs(spells or {}) do
        if type(row) == 'table' then
            local book = (row.book == true) or ((tonumber(row.book) or 0) > 0)
            if book then
                known_by_norm[norm(row.name or key)] = true
                local sid = tonumber(row.spell_id)
                if sid and sid > 0 then known_by_id[sid] = true end
            end
        end
    end

    local okSig, spell_snap = pcall(require, 'spell_snapshot')
    if okSig and spell_snap and spell_snap.signature then
        last_sig = spell_snap.signature(spells, spell_ids) or ''
    else
        local parts = {}
        for n, _ in pairs(known_by_norm) do parts[#parts + 1] = 'n' .. n end
        for id, _ in pairs(known_by_id) do
            if id > 0 then parts[#parts + 1] = 'i' .. tostring(id) end
        end
        table.sort(parts)
        last_sig = table.concat(parts, '\31')
    end

    ready = true
    building = false
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
    ready, building = false, false
    last_sig, last_published_sig = '', ''
end

return M
