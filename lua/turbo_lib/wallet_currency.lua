--[[
  Shared wallet currency readers (Fleet wallet / Gear snapshot / collectors).

  Radiant Crystals may live in Me.RadiantCrystals and/or the Alt Currency
  list (name or index 2 on some emu builds). Use max of alt sources so we
  never double-count when both TLOs mirror the same pool; bag stacks are
  added separately for spendable totals.
]]

local mq = require('mq')
local M = {}

local function num(fn)
    local ok, v = pcall(fn)
    if not ok or v == nil then return nil end
    return tonumber(v)
end

local function alt_currency(key)
    return num(function()
        local t = mq.TLO.Me.AltCurrency(key)
        if t == nil then return nil end
        if type(t) == 'number' then return t end
        return t()
    end)
end

--- Alt-currency Radiant Crystal count (no bag stacks).
--- Prefers Me.RadiantCrystals + named AltCurrency; falls back to index 2.
function M.radiant_alt()
    local dedicated = num(function() return mq.TLO.Me.RadiantCrystals() end)
    local named = alt_currency('Radiant Crystals')
    if named == nil then named = alt_currency('Radiant Crystal') end
    local listed = named
    if listed == nil then listed = alt_currency(2) end
    if dedicated == nil and listed == nil then return nil end
    return math.max(dedicated or 0, listed or 0)
end

--- Spendable RC = alt (either window) + inventory stacks.
function M.radiant_total()
    local alt = M.radiant_alt()
    local bag = num(function() return mq.TLO.FindItemCount('=Radiant Crystal')() end) or 0
    if alt ~= nil then return alt + bag end
    if bag > 0 then return bag end
    return nil
end

return M
