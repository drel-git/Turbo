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

local function probe_one(name)
    if tlo_number(mq.TLO.Me.Book(name)) > 0 then return true end
    if tlo_number(mq.TLO.Me.CombatAbility(name)) > 0 then return true end
    -- Ranked scribed form (spells/songs); nil when not known.
    if tlo_truthy(mq.TLO.Me.Spell(name)) then return true end
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
