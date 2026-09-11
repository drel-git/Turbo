-- TurboGear/spell_known.lua
-- Shared live probe: scribed spell/song (Book / Me.Spell) or combat ability.

local mq = require('mq')

local M = {}

local function trim(s)
    return tostring(s or ''):match('^%s*(.-)%s*$') or ''
end

local function apostrophe_variants(name)
    name = trim(name)
    if name == '' then return {} end
    local out, seen = {}, {}
    local function add(v)
        v = trim(v)
        if v ~= '' and not seen[v] then
            seen[v] = true
            out[#out + 1] = v
        end
    end
    add(name)
    add(name:gsub("'", "`"))
    add(name:gsub("`", "'"))
    add(name:gsub("\226\128\152", "'"):gsub("\226\128\153", "'"))
    add(name:gsub("\226\128\152", "`"):gsub("\226\128\153", "`"))
    return out
end

-- MQ Lua TLOs sometimes return a raw number, sometimes a callable userdata.
-- Calling () on a number throws; that was swallowed by pcall and looked "unknown".
local function tlo_number(v)
    if v == nil then return 0 end
    local tv = type(v)
    if tv == 'number' then return v end
    if tv == 'string' then return tonumber(v) or 0 end
    local ok, r = pcall(function() return v() end)
    if ok then
        if type(r) == 'number' then return r end
        if type(r) == 'string' then return tonumber(r) or 0 end
        if r then return 1 end
    end
    return tonumber(v) or 0
end

local function tlo_truthy(v)
    if v == nil or v == false then return false end
    if type(v) == 'number' then return v > 0 end
    if type(v) == 'string' then return v ~= '' end
    local ok, r = pcall(function() return v() end)
    if ok then return r and true or false end
    return true
end

local function gem_has(name)
    -- Memorized gem backup when Book name lookup is flaky on some clients.
    local maxGem = 12
    pcall(function()
        local n = tlo_number(mq.TLO.Me.NumGems)
        if n > 0 then maxGem = n end
    end)
    for i = 1, maxGem do
        local ok, gemName = pcall(function()
            local g = mq.TLO.Me.Gem(i)
            if not g then return nil end
            if g.Name then return g.Name() end
            local v = g()
            return v and tostring(v) or nil
        end)
        if ok and gemName and trim(gemName) ~= '' and trim(gemName):lower() == name:lower() then
            return true
        end
    end
    return false
end

local function probe_one(name)
    if tlo_number(mq.TLO.Me.Book(name)) > 0 then return true end
    if tlo_number(mq.TLO.Me.CombatAbility(name)) > 0 then return true end
    -- Ranked scribed form (spells/songs); nil when not known.
    if tlo_truthy(mq.TLO.Me.Spell(name)) then return true end
    if gem_has(name) then return true end
    return false
end

--- True if the local character has scribed / unlocked the ability.
function M.live(name)
    local known = false
    pcall(function()
        for _, variant in ipairs(apostrophe_variants(name)) do
            if probe_one(variant) then
                known = true
                return
            end
        end
    end)
    return known
end

--- Resolve spells_new id via Spell[id] (+ RankName) then probe Book/CombatAbility.
function M.live_id(spell_id)
    spell_id = tonumber(spell_id)
    if not spell_id or spell_id <= 0 then return false end
    local known = false
    pcall(function()
        local base = mq.TLO.Spell(spell_id)
        if not base or not base() then return end
        local names = {}
        local rank = base.RankName
        if rank and rank() then
            local rn = rank.Name and rank.Name() or nil
            if not rn or rn == '' then rn = tostring(rank()) end
            if rn and rn ~= '' then names[#names + 1] = rn end
        end
        local bn = base.Name and base.Name() or nil
        if bn and bn ~= '' then names[#names + 1] = bn end
        for _, n in ipairs(names) do
            if M.live(n) then
                known = true
                return
            end
        end
    end)
    return known
end

-- Lean probe for per-row checks (DoN rows, peer bis_search). Book + combat
-- ability only: a memorized gem or Me.Spell hit implies a Book hit, so the
-- 13-query gem scan and Me.Spell add cost, not accuracy. Apostrophe variants
-- are only tried when the name actually contains an apostrophe.
-- ~1-2 TLO queries when known, 2 (4 with apostrophes) when not.
local lookups = 0
function M.lookup_count() return lookups end
function M.reset_lookup_count() lookups = 0 end

local function lean_one(name)
    lookups = lookups + 1
    if tlo_number(mq.TLO.Me.Book(name)) > 0 then return true end
    lookups = lookups + 1
    if tlo_number(mq.TLO.Me.CombatAbility(name)) > 0 then return true end
    return false
end

function M.live_lean(name)
    name = trim(name)
    if name == '' then return false end
    local known = false
    pcall(function()
        if not name:find("['`\226]") then
            known = lean_one(name)
            return
        end
        for _, variant in ipairs(apostrophe_variants(name)) do
            if lean_one(variant) then known = true; return end
        end
    end)
    return known
end

--- Spell id -> base spell name (one query). nil when unresolved.
function M.spell_name_for_id(spell_id)
    spell_id = tonumber(spell_id)
    if not spell_id or spell_id <= 0 then return nil end
    local out = nil
    pcall(function()
        lookups = lookups + 1
        local s = mq.TLO.Spell(spell_id)
        local n = s and s.Name and s.Name() or nil
        if n and trim(n) ~= '' then out = trim(n) end
    end)
    return out
end

--- Lean known-by-id: the id's base name, then its rank name only if that
--- differs. ~2-4 queries (the full live_id ran the whole probe per name).
function M.live_lean_id(spell_id)
    spell_id = tonumber(spell_id)
    if not spell_id or spell_id <= 0 then return false end
    local base = M.spell_name_for_id(spell_id)
    if base and M.live_lean(base) then return true end
    local rank = nil
    pcall(function()
        lookups = lookups + 1
        local s = mq.TLO.Spell(spell_id)
        local r = s and s.RankName or nil
        local rn = r and r.Name and r.Name() or nil
        if rn and trim(rn) ~= '' then rank = trim(rn) end
    end)
    if rank and rank ~= base then return M.live_lean(rank) end
    return false
end

--- True if any listed spell name or spell id is known.
function M.live_any(names, ids)
    for _, id in ipairs(ids or {}) do
        if M.live_id(id) then return true end
    end
    for _, name in ipairs(names or {}) do
        if M.live(name) then return true end
    end
    return false
end

return M
