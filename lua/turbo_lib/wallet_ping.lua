--[[
  Shared Fleet wallet publish: write TurboFW_<Name>.txt + E3 TurboFW.
  Used by /lua run turbo_wallet_ping and Turbo trade-complete hook.
]]

local mq = require('mq')
local M = {}

local function num(fn)
    local ok, v = pcall(fn)
    if not ok or v == nil then return nil end
    return tonumber(v)
end

local function bag(name)
    return num(function() return mq.TLO.FindItemCount('=' .. name)() end) or 0
end

local function alt_plus_bag(altFn, itemName)
    local alt = num(altFn)
    local inv = bag(itemName)
    if alt ~= nil then return alt + inv end
    if inv > 0 then return inv end
    return nil
end

local function me_name()
    local name = 'unknown'
    pcall(function()
        local n = mq.TLO.Me.CleanName() or mq.TLO.Me.Name()
        n = tostring(n or ''):match('^[%w_]+')
        if n and n ~= '' then name = n end
    end)
    return name
end

local function enc(v)
    if v == nil then return '' end
    return tostring(math.floor(tonumber(v) or 0))
end

function M.gather()
    return {
        name = me_name(),
        updated = os.time(),
        platinum = num(function() return mq.TLO.Me.Platinum() end),
        diamond_coins = alt_plus_bag(function()
            local t = mq.TLO.Me.AltCurrency('Diamond Coins')
            local n = t and t() or nil
            if n == nil then
                t = mq.TLO.Me.AltCurrency(20)
                n = t and t() or nil
            end
            return n
        end, 'Diamond Coin'),
        radiant_crystals = alt_plus_bag(function() return mq.TLO.Me.RadiantCrystals() end, 'Radiant Crystal'),
        tribute_favor = num(function() return mq.TLO.Me.CurrentFavor() end),
        celestial_crests = alt_plus_bag(function()
            local t = mq.TLO.Me.AltCurrency('Celestial Crests')
            local n = t and t() or nil
            if n == nil then
                t = mq.TLO.Me.AltCurrency('Celestial Crest')
                n = t and t() or nil
            end
            return n
        end, 'Celestial Crest'),
        aa_unspent = num(function() return mq.TLO.Me.AAPoints() end),
    }
end

function M.encode(snap)
    snap = snap or M.gather()
    return string.format('t%d:p%s:d%s:r%s:f%s:c%s:a%s',
        tonumber(snap.updated) or os.time(),
        enc(snap.platinum), enc(snap.diamond_coins), enc(snap.radiant_crystals),
        enc(snap.tribute_favor), enc(snap.celestial_crests), enc(snap.aa_unspent))
end

function M.publish()
    local snap = M.gather()
    local payload = M.encode(snap)
    local name = tostring(snap.name or ''):match('^[%w_]+') or ''
    local dir = tostring(mq.configDir or '')
    if dir ~= '' and name ~= '' and name ~= 'unknown' then
        local path = string.format('%s/TurboFW_%s.txt', dir, name)
        local tmp = path .. '.tmp'
        pcall(function()
            local f = io.open(tmp, 'w')
            if not f then return end
            f:write(payload)
            f:write('\n')
            f:close()
            pcall(function() os.remove(path) end)
            if not os.rename(tmp, path) then
                local out = io.open(path, 'w')
                if out then
                    out:write(payload)
                    out:write('\n')
                    out:close()
                end
                pcall(function() os.remove(tmp) end)
            end
        end)
    end
    pcall(function()
        mq.cmdf('/squelch /e3varset TurboFW %s', payload)
    end)
    return snap
end

return M
