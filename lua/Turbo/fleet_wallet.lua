--[[
  Turbo fleet wallet ($ chrome panel).
  Kept in its own chunk so init.lua stays under Lua's 200-local limit.

  Lean sticky pop-out: independent of Turbo Full/Mini minimize.
  You amounts = live TLOs (alt + bag stacks).
  Peer live = E3 TurboFW via one-shot /lua run turbo_wallet_ping (no Gear required).
  Sidecar is optional backup; never loop-poke peers.
]]

local M = {}

local TG, mq, ImGui, Ui
local cachedWallet, refreshWalletCache

local function defaultColumns()
    return { pp = true, dc = true, rc = true, fav = true, cc = true, aa = true }
end

local function ensureColumns()
    local cols = TG.fleetWalletColumns
    if type(cols) ~= 'table' then
        cols = defaultColumns()
        TG.fleetWalletColumns = cols
    end
    for _, key in ipairs({ 'pp', 'dc', 'rc', 'fav', 'cc', 'aa' }) do
        if cols[key] == nil then cols[key] = true end
    end
    return cols
end

local function onWalletActivity()
    local now = (mq.gettime and mq.gettime()) or (os.time() * 1000)
    if (tonumber(TG._fwTradePingAtMS) or 0) + 1500 > now then return end
    TG._fwTradePingAtMS = now
    -- Local file publish (this box). Debounced.
    pcall(function()
        local ok, ping = pcall(require, 'turbo_lib.wallet_ping')
        if ok and ping and ping.publish then ping.publish() end
    end)
    -- If Fleet wallet is open, also ask visible peers once (covers peers without Turbo).
    if M.isOpen and M.isOpen() then
        if (tonumber(TG._fwTradePeerPokeAtMS) or 0) + 5000 <= now then
            TG._fwTradePeerPokeAtMS = now
            TG._fwNeedPeerPoke = true
            TG._fwNextLiveMS = 0
        end
    end
end

local function quickWalletSig()
    -- Cheap spend detect while MerchantWnd is open (no bag walk beyond FindItemCount).
    local ok, ping = pcall(require, 'turbo_lib.wallet_ping')
    if not ok or not ping or not ping.gather then return '' end
    local snap = ping.gather()
    if type(snap) ~= 'table' then return '' end
    return table.concat({
        tostring(snap.platinum or ''),
        tostring(snap.diamond_coins or ''),
        tostring(snap.radiant_crystals or ''),
        tostring(snap.celestial_crests or ''),
    }, '|')
end

local function registerTradePing()
    if TG._fwTradePingRegistered then return end
    -- Chat events (processed when something calls doevents, e.g. Gear).
    pcall(function()
        mq.event('TurboFWTradeDone', 'You complete the trade#*#', onWalletActivity)
    end)
    pcall(function()
        mq.event('TurboFWTradeDone2', '#*#You complete the trade#*#', onWalletActivity)
    end)
    pcall(function()
        mq.event('TurboFWPurchase1', '#*#You purchase#*#', onWalletActivity)
    end)
    pcall(function()
        mq.event('TurboFWPurchase2', '#*#You buy#*#', onWalletActivity)
    end)
    TG._fwTradePingRegistered = true
end

local function windowOpen(name)
    local open = false
    pcall(function()
        open = mq.TLO.Window(name).Open() == true
    end)
    return open
end

--- Watch TradeWnd / MerchantWnd (Turbo main loop skips doevents; this is the reliable path).
function M.tick()
    if not mq then return end
    local now = (mq.gettime and mq.gettime()) or (os.time() * 1000)

    local tradeOpen = windowOpen('TradeWnd')
    if TG._fwTradeWasOpen and not tradeOpen then
        onWalletActivity()
    end
    TG._fwTradeWasOpen = tradeOpen

    local merchantOpen = windowOpen('MerchantWnd')
    if TG._fwMerchantWasOpen and not merchantOpen then
        onWalletActivity()
    elseif merchantOpen then
        -- Buys often leave the merchant open; publish when wallet totals move.
        if (tonumber(TG._fwMerchantSigAtMS) or 0) <= now then
            TG._fwMerchantSigAtMS = now + 1000
            local sig = quickWalletSig()
            if sig ~= '' and sig ~= tostring(TG._fwMerchantWalletSig or '') then
                local had = TG._fwMerchantWalletSig ~= nil and TG._fwMerchantWalletSig ~= ''
                TG._fwMerchantWalletSig = sig
                if had then onWalletActivity() end
            elseif TG._fwMerchantWalletSig == nil then
                TG._fwMerchantWalletSig = sig
            end
        end
    else
        TG._fwMerchantWalletSig = nil
    end
    TG._fwMerchantWasOpen = merchantOpen
end

function M.init(deps)
    TG = deps.TG
    mq = deps.mq
    ImGui = deps.ImGui
    Ui = deps.Ui
    cachedWallet = deps.cachedWallet
    refreshWalletCache = deps.refreshWalletCache
    TG.fleetWalletRecipient = TG.fleetWalletRecipient or ''
    TG.fleetWalletRows = TG.fleetWalletRows or {}
    TG.fleetWalletScope = TG.fleetWalletScope or 'group'
    local cur = tostring(TG.fleetWalletCurrency or 'rc'):lower()
    if cur ~= 'pp' and cur ~= 'dc' and cur ~= 'rc' and cur ~= 'cc' then cur = 'rc' end
    TG.fleetWalletCurrency = cur
    TG.fleetWalletPicks = type(TG.fleetWalletPicks) == 'table' and TG.fleetWalletPicks or {}
    TG.fleetWalletForgotten = type(TG.fleetWalletForgotten) == 'table' and TG.fleetWalletForgotten or {}
    TG.fleetWalletShowSettings = TG.fleetWalletShowSettings == true
        or TG.fleetWalletShowPicks == true
    TG.fleetWalletAmount = tostring(TG.fleetWalletAmount or ''):gsub('%D', '')
    ensureColumns()
    registerTradePing()
    return M
end

local function amountOrNil()
    local s = tostring(TG.fleetWalletAmount or ''):gsub('%D', '')
    TG.fleetWalletAmount = s
    local n = tonumber(s)
    if n and n > 0 then return math.floor(n) end
    return nil
end

local function fmt(n)
    if n == nil then return '-' end
    n = tonumber(n)
    if n == nil then return '-' end
    -- Keep exact integers through 9,999,999 so collect totals stay readable.
    if n >= 10000000 then return string.format('%.1fm', n / 1000000) end
    if n >= 100000 then return string.format('%.1fk', n / 1000) end
    return tostring(math.floor(n))
end

local function clean(name)
    return tostring(name or ''):lower():gsub('%s+', ''):gsub('[^%w]', '')
end

local function isForgotten(name)
    local forgotten = TG.fleetWalletForgotten
    if type(forgotten) ~= 'table' then return false end
    local key = clean(name)
    return forgotten[name] == true or forgotten[key] == true
end

local function forgetName(name)
    name = tostring(name or '')
    if name == '' then return end
    local key = clean(name)
    local forgotten = TG.fleetWalletForgotten
    if type(forgotten) ~= 'table' then forgotten = {}; TG.fleetWalletForgotten = forgotten end
    forgotten[name] = true
    forgotten[key] = true
    local picks = TG.fleetWalletPicks
    if type(picks) == 'table' then
        picks[name] = nil
        picks[key] = nil
    end
    if TG.saveSettings then pcall(TG.saveSettings) end
end

local function walletSidecarPath()
    return tostring(mq.configDir or '') .. '/TurboGear_wallet.lua'
end

local function cachePath()
    return tostring(mq.configDir or '') .. '/TurboGear_cache.lua'
end

local function fileSig(path)
    -- Cheap change detect: mtime + size. Never load the file here.
    path = tostring(path or '')
    if path == '' then return '' end
    local ok_lfs, lfs = pcall(require, 'lfs')
    if ok_lfs and lfs and lfs.attributes then
        local ok, attr = pcall(lfs.attributes, path)
        if ok and type(attr) == 'table' then
            return tostring(attr.modification or 0) .. ':' .. tostring(attr.size or 0)
        end
    end
    local f = io.open(path, 'rb')
    if not f then return '' end
    local size = f:seek('end') or 0
    f:close()
    return 'size:' .. tostring(size)
end

local function peersFromTable(value)
    local peers, filled = {}, 0
    if type(value) ~= 'table' then return peers, filled end
    for key, snap in pairs(value) do
        if type(snap) == 'table' then
            local name = tostring(snap.name or '')
            if name == '' then
                name = tostring(key or ''):match('_(.+)$') or ''
            end
            if name ~= '' then
                local plat = tonumber(snap.platinum)
                local dc = tonumber(snap.diamond_coins)
                local rc = tonumber(snap.radiant_crystals)
                local favor = tonumber(snap.tribute_favor)
                local crests = tonumber(snap.celestial_crests)
                local aa = tonumber(snap.aa_unspent)
                peers[clean(name)] = {
                    name = name,
                    plat = plat,
                    dc = dc,
                    rc = rc,
                    favor = favor,
                    crests = crests,
                    aa = aa,
                }
                if plat ~= nil or dc ~= nil or rc ~= nil or favor ~= nil
                    or crests ~= nil or aa ~= nil then
                    filled = filled + 1
                end
            end
        end
    end
    return peers, filled
end

local function loadSidecarPeers()
    local path = walletSidecarPath()
    local sig = fileSig(path)
    if sig == '' then return nil, 0, '' end
    local ok, value = pcall(function()
        local chunk = loadfile(path)
        if type(chunk) ~= 'function' then return nil end
        return chunk()
    end)
    if not ok or type(value) ~= 'table' then return nil, 0, sig end
    local peers, filled = peersFromTable(value)
    return peers, filled, sig
end

local function streamScanCachePeers()
    local path = cachePath()
    local peers = {}
    local filled = 0
    local f = io.open(path, 'r')
    if not f then return peers, filled end
    local current, entryDepth = nil, 0
    for line in f:lines() do
        local keyName = line:match("^%s*%['[^'%[%]]+_([%w_]+)'%]%s*=%s*%{")
        if keyName and (entryDepth <= 0 or not current) then
            current = { name = keyName }
            peers[clean(keyName)] = current
            entryDepth = 1
        elseif current then
            local opens, closes = 0, 0
            for _ in line:gmatch('%{') do opens = opens + 1 end
            for _ in line:gmatch('%}') do closes = closes + 1 end
            local n = line:match("%['name'%]%s*=%s*'([^']+)'")
            if n and n ~= '' and entryDepth == 1 then current.name = n end
            local plat = line:match("%['platinum'%]%s*=%s*([%-%d%.eE]+)")
            if plat then current.plat = tonumber(plat) end
            local dc = line:match("%['diamond_coins'%]%s*=%s*([%-%d%.eE]+)")
            if dc then current.dc = tonumber(dc) end
            local rc = line:match("%['radiant_crystals'%]%s*=%s*([%-%d%.eE]+)")
            if rc then current.rc = tonumber(rc) end
            local favor = line:match("%['tribute_favor'%]%s*=%s*([%-%d%.eE]+)")
            if favor then current.favor = tonumber(favor) end
            local crests = line:match("%['celestial_crests'%]%s*=%s*([%-%d%.eE]+)")
            if crests then current.crests = tonumber(crests) end
            local aa = line:match("%['aa_unspent'%]%s*=%s*([%-%d%.eE]+)")
            if aa then current.aa = tonumber(aa) end
            entryDepth = entryDepth + opens - closes
            if entryDepth <= 0 then
                if current.plat ~= nil or current.dc ~= nil or current.rc ~= nil
                    or current.favor ~= nil or current.crests ~= nil or current.aa ~= nil then
                    filled = filled + 1
                end
                current = nil
                entryDepth = 0
            end
        end
    end
    f:close()
    return peers, filled
end

local function ensurePeers(force)
    local sidePath = walletSidecarPath()
    local sideSig = fileSig(sidePath)
    -- Sidecar-only hot path. Full cache scan is opt-in (force + no sidecar) to
    -- avoid hitching on the multi-MB pickle.
    local sig = 'w:' .. sideSig
    if not force and TG._fwPeerSig == sig and type(TG._fwPeers) == 'table' then
        return TG._fwPeers
    end

    TG._fwLoadErr = nil
    TG._fwPeerSource = nil
    TG._fwPeerFilled = 0
    local peers, filled = {}, 0

    if sideSig ~= '' then
        local sidePeers, sideFilled = loadSidecarPeers()
        if type(sidePeers) == 'table' then
            peers, filled = sidePeers, sideFilled
            TG._fwPeerSource = 'sidecar'
        else
            TG._fwLoadErr = 'sidecar load failed'
            peers = type(TG._fwPeers) == 'table' and TG._fwPeers or {}
        end
    elseif force then
        local ok, err = pcall(function()
            peers, filled = streamScanCachePeers()
        end)
        if not ok then
            TG._fwLoadErr = tostring(err or 'cache scan failed')
            peers = type(TG._fwPeers) == 'table' and TG._fwPeers or {}
            filled = 0
        else
            TG._fwPeerSource = 'cache'
        end
    else
        TG._fwPeerSource = 'none'
    end

    TG._fwPeers = peers
    TG._fwPeerFilled = filled
    TG._fwPeerSig = sig
    return peers
end

local function armFastPoll(ms)
    local untilMS = ((mq.gettime and mq.gettime()) or (os.time() * 1000)) + (tonumber(ms) or 12000)
    TG._fwPokeUntilMS = math.max(tonumber(TG._fwPokeUntilMS) or 0, untilMS)
end

--- One-shot peer ping: tiny lua sets E3 TurboFW (no Gear required, no loop).
local function pokePeerWallet(name)
    name = tostring(name or ''):match('^[%w_]+') or ''
    if name == '' then return end
    mq.cmdf('/squelch /e3bct %s /squelch /lua run turbo_wallet_ping', name)
    armFastPoll(10000)
end

local function decodeTurboFW(text)
    text = tostring(text or '')
    if text == '' or text == 'NULL' then return nil end
    local map = {}
    for piece in string.gmatch(text, '[^:]+') do
        local k, v = piece:match('^(%a)(.*)$')
        if k then map[k] = v end
    end
    local function num(v)
        if v == nil or v == '' then return nil end
        return tonumber(v)
    end
    local p, d, r, f, c, a = num(map.p), num(map.d), num(map.r), num(map.f), num(map.c), num(map.a)
    if p == nil and d == nil and r == nil and f == nil and c == nil and a == nil then
        return nil
    end
    return {
        plat = p, dc = d, rc = r, favor = f, crests = c, aa = a,
        updated = num(map.t),
        live = true,
    }
end

local function liveFilePath(name)
    name = tostring(name or ''):match('^[%w_]+') or ''
    if name == '' then return '' end
    return tostring(mq.configDir or '') .. '/TurboFW_' .. name .. '.txt'
end

local function readLiveFile(name)
    local path = liveFilePath(name)
    if path == '' then return nil end
    local ok, text = pcall(function()
        local f = io.open(path, 'r')
        if not f then return nil end
        local body = f:read('*l') or f:read('*a') or ''
        f:close()
        return body
    end)
    if not ok or not text then return nil end
    return decodeTurboFW(text)
end

--- Live peer wallet: shared TurboFW_<Name>.txt first, E3 var backup.
local function queryPeerLive(name)
    name = tostring(name or ''):match('^[%w_]+') or ''
    if name == '' then return nil end
    local fromFile = readLiveFile(name)
    if fromFile then
        fromFile.source = 'file'
        return fromFile
    end
    local ok, val = pcall(function()
        if not (mq.TLO.MQ2Mono and mq.TLO.MQ2Mono.Query) then return nil end
        return mq.TLO.MQ2Mono.Query(string.format('e3,%s,TurboFW', name))()
    end)
    if not ok then return nil end
    local fromE3 = decodeTurboFW(val)
    if fromE3 then fromE3.source = 'e3' end
    return fromE3
end

--- Read-only overlay. Pokes are explicit (open / Refresh / Get·Send·Collect).
local function refreshLivePeers(allowedKeys)
    local now = (mq.gettime and mq.gettime()) or (os.time() * 1000)
    if (tonumber(TG._fwNextLiveMS) or 0) > now and type(TG._fwLivePeers) == 'table' then
        return TG._fwLivePeers
    end
    TG._fwNextLiveMS = now + 750

    -- Rebuild each poll so departed/stale entries do not stick forever.
    local live = {}
    local liveCount = 0
    if type(allowedKeys) == 'table' then
        for key, label in pairs(allowedKeys) do
            local name = tostring(label or key)
            local me = tostring(mq.TLO.Me.CleanName() or '')
            if name ~= '' and clean(name) ~= clean(me) then
                local rec = queryPeerLive(name)
                if rec then
                    rec.name = name
                    live[clean(name)] = rec
                    liveCount = liveCount + 1
                end
            end
        end
    end
    TG._fwLivePeers = live
    TG._fwLiveCount = liveCount
    return live
end

--- While open: sidecar reload only when file changes (no command spam).
local function pollPeersIfDue()
    local now = (mq.gettime and mq.gettime()) or (os.time() * 1000)
    local pokeUntil = tonumber(TG._fwPokeUntilMS) or 0
    local interval = (pokeUntil > now) and 1000 or 2500
    if not M.isOpen() and pokeUntil <= now then return end
    if (tonumber(TG._fwNextPollMS) or 0) > now then return end
    TG._fwNextPollMS = now + interval
    local sideSig = fileSig(walletSidecarPath())
    if sideSig ~= '' and sideSig ~= tostring(TG._fwLastSideSig or '') then
        TG._fwPeerSig = nil
        TG._fwLastSideSig = sideSig
    end
    ensurePeers(false)
end

local function e3Names()
    local out = {}
    local ok, peers = pcall(function()
        if mq.TLO.MQ2Mono and mq.TLO.MQ2Mono.Query then
            return mq.TLO.MQ2Mono.Query('e3,E3Bots.ConnectedClients')()
        end
        return nil
    end)
    if ok and type(peers) == 'string' then
        for peer in peers:gmatch('([^,]+)') do
            local name = tostring(peer):match('^%s*([%w_]+)') or ''
            if name ~= '' then out[clean(name)] = name end
        end
    end
    return out
end

local function groupNames()
    local out = {}
    local me = tostring(mq.TLO.Me.CleanName() or '')
    if me ~= '' then out[clean(me)] = me end
    local n = tonumber(mq.TLO.Group.Members() or 0) or 0
    for i = 1, n do
        local ok, gname = pcall(function() return mq.TLO.Group.Member(i).Name() end)
        gname = ok and tostring(gname or '') or ''
        if gname ~= '' then out[clean(gname)] = gname end
    end
    return out
end

local function allKnown(peers)
    local out = {}
    local me = tostring(mq.TLO.Me.CleanName() or '')
    if me ~= '' then out[clean(me)] = me end
    for k, v in pairs(groupNames()) do out[k] = v end
    for k, v in pairs(e3Names()) do out[k] = v end
    if type(peers) == 'table' then
        for k, rec in pairs(peers) do
            if type(rec) == 'table' and rec.name then
                out[k] = rec.name
            end
        end
    end
    return out
end

local function buildRows()
    refreshWalletCache()
    local me = tostring(mq.TLO.Me.CleanName() or '')
    local scope = tostring(TG.fleetWalletScope or 'group')
    local picks = type(TG.fleetWalletPicks) == 'table' and TG.fleetWalletPicks or {}
    local peers = ensurePeers(false)
    local e3 = e3Names()
    local group = groupNames()
    local known = allKnown(peers)

    local allowed = {}
    if scope == 'e3' then
        for k, v in pairs(e3) do allowed[k] = v end
        if me ~= '' then allowed[clean(me)] = me end
    elseif scope == 'live' then
        for k, v in pairs(e3) do allowed[k] = v end
        if me ~= '' then allowed[clean(me)] = me end
        for k, rec in pairs(peers) do
            if type(rec) == 'table' and (rec.plat ~= nil or rec.dc ~= nil or rec.rc ~= nil
                or rec.favor ~= nil or rec.crests ~= nil or rec.aa ~= nil) then
                allowed[k] = rec.name or k
            end
        end
    elseif scope == 'picks' then
        for name, on in pairs(picks) do
            if on and not isForgotten(name) then
                local label = known[clean(name)] or tostring(name)
                allowed[clean(name)] = label
            end
        end
        if me ~= '' then allowed[clean(me)] = me end
    else
        for k, v in pairs(group) do allowed[k] = v end
    end

    local rows, byName = {}, {}
    local function upsert(name, plat, dc, rc, favor, crests, aa, isSelf)
        name = tostring(name or ''):match('^%s*(.-)%s*$') or ''
        if name == '' then return end
        local key = clean(name)
        if not allowed[key] and not isSelf then return end
        local row = byName[key]
        if not row then
            row = {
                name = allowed[key] or name,
                plat = nil, dc = nil, rc = nil, favor = nil, crests = nil, aa = nil,
                isSelf = isSelf == true,
            }
            byName[key] = row
            rows[#rows + 1] = row
        end
        if plat ~= nil then row.plat = tonumber(plat) end
        if dc ~= nil then row.dc = tonumber(dc) end
        if rc ~= nil then row.rc = tonumber(rc) end
        if favor ~= nil then row.favor = tonumber(favor) end
        if crests ~= nil then row.crests = tonumber(crests) end
        if aa ~= nil then row.aa = tonumber(aa) end
        if isSelf then row.isSelf = true; row.name = me ~= '' and me or row.name end
    end

    upsert(me, cachedWallet.plat, cachedWallet.dc, cachedWallet.rc,
        cachedWallet.favor, cachedWallet.crests, cachedWallet.aa, true)
    -- While open: peer amounts from live ping files only (never stale sidecar).
    -- Sidecar only fills amounts when the panel is closed / no live yet and we
    -- have not just requested a poke (avoids showing wrong PP/CC after trades).
    local live = refreshLivePeers(allowed)
    local liveOnly = M.isOpen() == true
    if not liveOnly then
        for key, rec in pairs(peers) do
            if type(rec) == 'table' and allowed[key] then
                upsert(rec.name or key, rec.plat, rec.dc, rec.rc, rec.favor, rec.crests, rec.aa, false)
            end
        end
    end
    for key, rec in pairs(live) do
        if type(rec) == 'table' and allowed[key] then
            upsert(rec.name or key, rec.plat, rec.dc, rec.rc, rec.favor, rec.crests, rec.aa, false)
        end
    end
    -- Name rows for peers without live yet (amounts stay '-' while open).
    for _, name in pairs(allowed) do
        upsert(name, nil, nil, nil, nil, nil, nil, false)
    end

    table.sort(rows, function(a, b)
        if a.isSelf ~= b.isSelf then return a.isSelf end
        return tostring(a.name):lower() < tostring(b.name):lower()
    end)
    TG.fleetWalletRows = rows
    TG._fleetWalletKnown = known
    return rows
end

-- Sleek compact palette (hex -> 0-1 / IM_COL32).
local C = {
    title = { 0.29, 0.70, 0.69, 1.0 },       -- #49b3b0 (recipient / accents)
    gold = { 0.79, 0.63, 0.29, 1.0 },        -- #caa04a (Turbo chrome amber)
    body = { 0.78, 0.82, 0.85, 1.0 },        -- #c7d0da
    muted = { 0.35, 0.40, 0.46, 1.0 },       -- #5a6675
    header = { 0.58, 0.63, 0.69, 1.0 },      -- #93a0b0
    navActive = { 0.86, 0.90, 0.93, 1.0 },   -- #dbe6ee
    underline = { 0.23, 0.65, 0.64, 1.0 },   -- #3aa6a3
    onWash = { 0.37, 0.82, 0.80, 1.0 },      -- #5fd0cb
    pp = { 0.87, 0.64, 0.25, 1.0 },          -- #dda23f
    alt = { 0.29, 0.70, 0.69, 1.0 },         -- #49b3b0
    fav = { 0.56, 0.61, 0.67, 1.0 },         -- #8f9cac
    zero = { 0.23, 0.27, 0.34, 1.0 },        -- #3b4656
    textOnTeal = { 0.02, 0.17, 0.16, 1.0 },  -- #052b2a
    clearX = { 0.27, 0.32, 0.39, 1.0 },      -- #465264
}
local COL_CUR = IM_COL32 and IM_COL32(18, 50, 50, 255) or nil       -- #123232
local COL_CUR_TOT = IM_COL32 and IM_COL32(15, 42, 42, 255) or nil   -- #0f2a2a
local COL_ROW = IM_COL32 and IM_COL32(18, 56, 52, 255) or nil       -- #123834
local COL_ZEBRA = IM_COL32 and IM_COL32(17, 31, 43, 180) or nil     -- #111f2b
local COL_HAIR = IM_COL32 and IM_COL32(27, 40, 54, 255) or nil      -- #1b2836
local COL_ACCENT = IM_COL32 and IM_COL32(58, 166, 163, 255) or nil  -- #3aa6a3

local function activeCurrency()
    local cur = tostring(TG.fleetWalletCurrency or 'rc'):lower()
    if cur ~= 'pp' and cur ~= 'dc' and cur ~= 'rc' and cur ~= 'cc' then return 'rc' end
    return cur
end

local function currencyLabel(cur)
    cur = cur or activeCurrency()
    if cur == 'pp' then return 'PP' end
    if cur == 'dc' then return 'DC' end
    if cur == 'cc' then return 'CC' end
    return 'RC'
end

local function rgba(c)
    return c[1], c[2], c[3], c[4] or 1
end

-- TextColored cannot take rgba() as a single arg before `text` — Lua only
-- keeps the first return value when another argument follows.
local function textC(color, text)
    ImGui.TextColored(color[1], color[2], color[3], color[4] or 1, tostring(text or ''))
end

local function pushGhostBtn(textColor)
    local n = 0
    if ImGui.PushStyleColor and ImGuiCol then
        ImGui.PushStyleColor(ImGuiCol.Button, 0, 0, 0, 0)
        ImGui.PushStyleColor(ImGuiCol.ButtonHovered, 0.12, 0.16, 0.22, 0.45)
        ImGui.PushStyleColor(ImGuiCol.ButtonActive, 0, 0, 0, 0)
        ImGui.PushStyleColor(ImGuiCol.Text, rgba(textColor))
        n = 4
    end
    return n
end

local function popStyles(colors, vars)
    if colors and colors > 0 and ImGui.PopStyleColor then ImGui.PopStyleColor(colors) end
    if vars and vars > 0 and ImGui.PopStyleVar then ImGui.PopStyleVar(vars) end
end

local function drawLine(x1, y1, x2, y2, col, thickness)
    if not (ImGui.GetWindowDrawList and col) then return end
    pcall(function()
        local dl = ImGui.GetWindowDrawList()
        if not (dl and dl.AddLine) then return end
        if ImVec2 then
            dl:AddLine(ImVec2(x1, y1), ImVec2(x2, y2), col, thickness or 1.0)
        else
            dl:AddLine(x1, y1, x2, y2, col, thickness or 1.0)
        end
    end)
end

local function drawRectFilled(x1, y1, x2, y2, col)
    if not (ImGui.GetWindowDrawList and col) then return end
    pcall(function()
        local dl = ImGui.GetWindowDrawList()
        if not (dl and dl.AddRectFilled) then return end
        if ImVec2 then
            dl:AddRectFilled(ImVec2(x1, y1), ImVec2(x2, y2), col)
        else
            dl:AddRectFilled(x1, y1, x2, y2, col)
        end
    end)
end

local function drawUnderlineAccent()
    if not (ImGui.GetItemRectMin and ImGui.GetItemRectMax and COL_ACCENT) then
        return
    end
    pcall(function()
        local x1, y1 = ImGui.GetItemRectMin()
        local x2, y2 = ImGui.GetItemRectMax()
        drawLine(x1, y2 - 1, x2, y2 - 1, COL_ACCENT, 2.0)
    end)
end

--- Plain text nav (no pills). Active = bright text + teal underline.
local function textNav(label, id, active)
    local padVars = 0
    if ImGui.PushStyleVar and ImGuiStyleVar and ImGuiStyleVar.FramePadding then
        ImGui.PushStyleVar(ImGuiStyleVar.FramePadding, 2, 2)
        padVars = 1
    end
    local n = pushGhostBtn(active and C.navActive or C.header)
    local clicked = ImGui.Button(label .. '##' .. id)
    if active then drawUnderlineAccent() end
    popStyles(n, padVars)
    return clicked
end

local function pushFillBtn(fr, fg, fb, tr, tg, tb, hoverLift)
    hoverLift = hoverLift or 18
    local n = 0
    if ImGui.PushStyleColor and ImGuiCol then
        ImGui.PushStyleColor(ImGuiCol.Button, fr / 255, fg / 255, fb / 255, 1)
        ImGui.PushStyleColor(ImGuiCol.ButtonHovered,
            math.min(255, fr + hoverLift) / 255,
            math.min(255, fg + hoverLift) / 255,
            math.min(255, fb + hoverLift) / 255, 1)
        ImGui.PushStyleColor(ImGuiCol.ButtonActive, fr / 255, fg / 255, fb / 255, 1)
        ImGui.PushStyleColor(ImGuiCol.Text, tr / 255, tg / 255, tb / 255, 1)
        n = 4
    end
    return n
end

local function drawCurrencySegment()
    local segs = { { 'pp', 'PP' }, { 'dc', 'DC' }, { 'rc', 'RC' }, { 'cc', 'CC' } }
    local cur = activeCurrency()
    local segW, segH = 52, 28
    local totalW = (#segs * segW) + (#segs - 1) + 2
    local pushedC, pushedV = 0, 0
    if ImGui.PushStyleColor and ImGuiCol then
        ImGui.PushStyleColor(ImGuiCol.Border, 39 / 255, 52 / 255, 68 / 255, 1) -- #273444
        ImGui.PushStyleColor(ImGuiCol.ChildBg, 0, 0, 0, 0)
        pushedC = 2
    end
    if ImGui.PushStyleVar and ImGuiStyleVar then
        if ImGuiStyleVar.ChildRounding then
            ImGui.PushStyleVar(ImGuiStyleVar.ChildRounding, 5)
            pushedV = pushedV + 1
        end
        if ImGuiStyleVar.WindowPadding then
            ImGui.PushStyleVar(ImGuiStyleVar.WindowPadding, 1, 1)
            pushedV = pushedV + 1
        end
        if ImGuiStyleVar.ItemSpacing then
            ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 0, 0)
            pushedV = pushedV + 1
        end
        if ImGuiStyleVar.FrameRounding then
            ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 0)
            pushedV = pushedV + 1
        end
        if ImGuiStyleVar.FramePadding then
            ImGui.PushStyleVar(ImGuiStyleVar.FramePadding, 10, 2)
            pushedV = pushedV + 1
        end
    end
    local began = true
    if ImGui.BeginChild then
        local a, b = ImGui.BeginChild('##fw_cur_seg', totalW, segH, true)
        began = (b == nil) and a or b
    end
    if began then
        for i, s in ipairs(segs) do
            if i > 1 then
                if IM_COL32 then
                    local x, y = ImGui.GetCursorScreenPos()
                    drawLine(x, y + 3, x, y + segH - 4, IM_COL32(39, 52, 68, 255), 1.0)
                end
                ImGui.Dummy(1, 1)
                ImGui.SameLine(0, 0)
            end
            local on = cur == s[1]
            local n = 0
            if on then
                n = pushFillBtn(44, 140, 138, 5, 43, 42, 14) -- #2c8c8a / #052b2a
            else
                n = pushGhostBtn(C.header)
            end
            if ImGui.Button(s[2] .. '##fw_cur_' .. s[1], segW, segH - 2) then
                TG.fleetWalletCurrency = s[1]
                if TG.saveSettings then pcall(TG.saveSettings) end
            end
            popStyles(n, 0)
            if i < #segs then ImGui.SameLine(0, 0) end
        end
    end
    if ImGui.EndChild then ImGui.EndChild() end
    popStyles(pushedC, pushedV)
end

local function rightText(color, text)
    text = tostring(text or '')
    if ImGui.CalcTextSize and ImGui.GetContentRegionAvail and ImGui.SetCursorPosX then
        local tw = select(1, ImGui.CalcTextSize(text)) or 0
        local avail = select(1, ImGui.GetContentRegionAvail()) or 0
        if avail > tw + 2 then
            ImGui.SetCursorPosX(ImGui.GetCursorPosX() + (avail - tw))
        end
    end
    textC(color, text)
end

local function centerText(color, text)
    text = tostring(text or '')
    if ImGui.CalcTextSize and ImGui.GetContentRegionAvail and ImGui.SetCursorPosX then
        local tw = select(1, ImGui.CalcTextSize(text)) or 0
        local avail = select(1, ImGui.GetContentRegionAvail()) or 0
        if avail > tw then
            ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ((avail - tw) * 0.5))
        end
    end
    textC(color, text)
end

local function textWidth(s)
    if not ImGui.CalcTextSize then return (#tostring(s or '') * 7) end
    return select(1, ImGui.CalcTextSize(tostring(s or ''))) or 0
end

local function valueColor(kind, val, isSel)
    if val == nil or tonumber(val) == 0 then return C.zero end
    if isSel then return C.onWash end
    if kind == 'pp' then return C.pp end
    if kind == 'fav' then return C.fav end
    return C.alt
end

local function scopeIsWide()
    return tostring(TG.fleetWalletScope) == 'e3' or tostring(TG.fleetWalletScope) == 'live'
end

local function collectorScript(cur)
    cur = cur or activeCurrency()
    if cur == 'pp' then return 'turbo_collect_cash' end
    if cur == 'dc' then return 'turbo_collect_dc' end
    if cur == 'cc' then return 'turbo_collect_crests' end
    return 'turbo_collect_rc'
end

local function sendMode(cur)
    cur = cur or activeCurrency()
    if cur == 'pp' then return '_sendcash' end
    if cur == 'dc' then return '_senddc' end
    if cur == 'cc' then return '_sendcrest' end
    return '_sendrc'
end

local function invalidateLive(name)
    TG._fwNextLiveMS = 0
    local key = clean(name)
    if key ~= '' and type(TG._fwLivePeers) == 'table' then
        TG._fwLivePeers[key] = nil
    end
end

--- One-shot poke for visible peer rows (open / Refresh / collect scope).
local function pokeVisiblePeers()
    local rows = TG.fleetWalletRows
    if type(rows) ~= 'table' then return end
    for _, row in ipairs(rows) do
        if type(row) == 'table' and not row.isSelf and row.name then
            invalidateLive(row.name)
            pokePeerWallet(row.name)
        end
    end
end

local function pokePeerWalletDelayed(name, delayDs)
    name = tostring(name or ''):match('^[%w_]+') or ''
    if name == '' then return end
    delayDs = math.max(1, math.floor(tonumber(delayDs) or 40))
    mq.cmdf('/timed %d /squelch /e3bct %s /squelch /lua run turbo_wallet_ping', delayDs, name)
    armFastPoll(delayDs * 100 + 5000)
end

local function runCollectFrom(name)
    local amt = amountOrNil()
    if amt then
        mq.cmdf('/lua run %s from %s %d', collectorScript(), name, amt)
    else
        mq.cmdf('/lua run %s from %s', collectorScript(), name)
    end
    invalidateLive(name)
    pokePeerWallet(name)
    pokePeerWalletDelayed(name, 50)
end

local function runSendMineTo(name)
    local amt = amountOrNil()
    if amt then
        mq.cmdf('/mac turbogive %s %s %d', sendMode(), name, amt)
    else
        mq.cmdf('/mac turbogive %s %s', sendMode(), name)
    end
    invalidateLive(name)
    pokePeerWallet(name)
    pokePeerWalletDelayed(name, 50)
end

local function runCollectScope()
    local script = collectorScript()
    local amt = amountOrNil()
    if scopeIsWide() then
        if amt then mq.cmdf('/lua run %s all %d', script, amt)
        else mq.cmdf('/lua run %s all', script) end
    else
        if amt then mq.cmdf('/lua run %s %d', script, amt)
        else mq.cmdf('/lua run %s', script) end
    end
    pokeVisiblePeers()
end

local function runPoolScope(selected)
    local script = collectorScript()
    local amt = amountOrNil()
    if scopeIsWide() then
        if amt then mq.cmdf('/lua run %s all to %s %d', script, selected, amt)
        else mq.cmdf('/lua run %s all to %s', script, selected) end
    else
        if amt then mq.cmdf('/lua run %s to %s %d', script, selected, amt)
        else mq.cmdf('/lua run %s to %s', script, selected) end
    end
    pokeVisiblePeers()
end

function M.isOpen()
    return rawget(_G, '__TurboFleetWalletOpen') == true
end

function M.setOpen(v)
    local open = v == true
    local was = rawget(_G, '__TurboFleetWalletOpen') == true
    rawset(_G, '__TurboFleetWalletOpen', open)
    if open and not was then
        -- Restore saved layout (or seed once under $ if never placed).
        rawset(_G, '__TurboFleetWalletPlaceOnce', true)
    end
    if was and not open and TG.saveSettings then
        pcall(TG.saveSettings)
    end
end

function M.close()
    M.setOpen(false)
end

local function persistWindowPos()
    if not (ImGui.GetWindowPos and TG) then return end
    local wx, wy = ImGui.GetWindowPos()
    wx, wy = tonumber(wx), tonumber(wy)
    if not (wx and wy) then return end
    local prev = TG.fleetWalletWindowPos
    if prev and math.abs((tonumber(prev.x) or 0) - wx) < 0.5
        and math.abs((tonumber(prev.y) or 0) - wy) < 0.5 then
        return
    end
    TG.fleetWalletWindowPos = { x = wx, y = wy }
    local now = (mq and mq.gettime and mq.gettime()) or (os.time() * 1000)
    if (tonumber(TG._fwPosSaveAtMS) or 0) <= now then
        TG._fwPosSaveAtMS = now + 800
        if TG.saveSettings then pcall(TG.saveSettings) end
    end
end

local function setScope(scope)
    TG.fleetWalletScope = scope
    if scope == 'picks' then TG.fleetWalletShowPicks = true end
    if TG.saveSettings then pcall(TG.saveSettings) end
end

local function sectionGap()
    if ImGui.Dummy then ImGui.Dummy(1, 7) else ImGui.Spacing() end
end

local function opsButton(label, id, isSel)
    local padV = 0
    if ImGui.PushStyleVar and ImGuiStyleVar then
        if ImGuiStyleVar.FramePadding then
            ImGui.PushStyleVar(ImGuiStyleVar.FramePadding, 4, 1)
            padV = padV + 1
        end
        if ImGuiStyleVar.FrameRounding then
            ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 3)
            padV = padV + 1
        end
    end
    local n
    if isSel then
        n = pushFillBtn(28, 70, 65, 199, 208, 218, 12) -- #1c4641
    else
        n = pushFillBtn(27, 39, 52, 199, 208, 218, 12) -- #1b2734
    end
    local clicked = ImGui.Button(label .. '##' .. id)
    popStyles(n, padV)
    return clicked
end

local function actionButton(label, primary)
    local padV = 0
    if ImGui.PushStyleVar and ImGuiStyleVar then
        if ImGuiStyleVar.FramePadding then
            ImGui.PushStyleVar(ImGuiStyleVar.FramePadding, 5, 5)
            padV = padV + 1
        end
        if ImGuiStyleVar.FrameRounding then
            ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 5)
            padV = padV + 1
        end
    end
    local n
    if primary then
        n = pushFillBtn(44, 140, 138, 5, 43, 42, 14) -- Collect
    else
        n = pushFillBtn(27, 39, 52, 199, 208, 218, 12) -- Pool slate
    end
    local clicked = ImGui.Button(label)
    popStyles(n, padV)
    return clicked
end

local function paintHairlineAcross()
    if not (ImGui.GetCursorScreenPos and COL_HAIR) then return end
    pcall(function()
        local x, y = ImGui.GetCursorScreenPos()
        local w = select(1, ImGui.GetContentRegionAvail()) or 0
        if w < 8 then return end
        drawLine(x, y, x + w, y, COL_HAIR, 1.0)
    end)
end

function M.drawPanel()
    pollPeersIfDue()
    refreshWalletCache()
    local rows = buildRows()
    if TG._fwNeedPeerPoke then
        TG._fwNeedPeerPoke = false
        pokeVisiblePeers()
    end
    local me = tostring(mq.TLO.Me.CleanName() or '')
    local selected = tostring(TG.fleetWalletRecipient or '')
    if selected == '' then
        selected = me
        TG.fleetWalletRecipient = selected
    end
    local known = TG._fleetWalletKnown or {}
    local canControl = TG.isSharedControlOwner and TG.isSharedControlOwner()
    local cols = ensureColumns()
    local curLabel = currencyLabel()
    local amt = amountOrNil()
    local scope = tostring(TG.fleetWalletScope or 'group')

    local densV = 0
    if ImGui.PushStyleVar and ImGuiStyleVar then
        if ImGuiStyleVar.ItemSpacing then
            ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 6, 4)
            densV = densV + 1
        end
        if ImGuiStyleVar.FramePadding then
            ImGui.PushStyleVar(ImGuiStyleVar.FramePadding, 2, 2)
            densV = densV + 1
        end
    end

    -- Title row: TurboWallet | centered live status | amber minimize.
    -- Center uses last table width so AlwaysAutoResize does not expand.
    local liveN = tonumber(TG._fwLiveCount) or 0
    local statusTxt
    local statusColor = C.muted
    if TG._fwLoadErr then
        statusTxt = 'Peers: ' .. tostring(TG._fwLoadErr)
        statusColor = { 0.92, 0.45, 0.40, 1.0 }
    elseif liveN > 0 then
        statusTxt = string.format('You: live · Peers: %d live', liveN)
    else
        statusTxt = 'You: live · Peers: Refresh once for live ping'
    end

    local rowY = ImGui.GetCursorPosY()
    local leftX = ImGui.GetCursorPosX()
    local titleStr = 'TurboWallet'
    local titleTw = textWidth(titleStr)
    local statusTw = textWidth(statusTxt)
    local minW = 22
    local layoutW = tonumber(TG._fwLayoutW) or 0
    if layoutW < titleTw + statusTw + minW + 40 then
        layoutW = 0 -- not ready / too narrow; fall back below
    end

    textC(C.gold, titleStr)

    -- Centered status between title and minimize.
    do
        local centerX
        if layoutW > 0 then
            centerX = leftX + (layoutW - statusTw) * 0.5
            centerX = math.max(centerX, leftX + titleTw + 10)
            centerX = math.min(centerX, leftX + layoutW - minW - statusTw - 10)
        else
            centerX = leftX + titleTw + 12
        end
        if ImGui.SetCursorPos then ImGui.SetCursorPos(centerX, rowY) end
        textC(statusColor, statusTxt)
    end

    -- Amber minimize chip flush right of layout.
    do
        local minX
        if layoutW > 0 then
            minX = leftX + layoutW - minW
        else
            minX = leftX + titleTw + statusTw + 24
        end
        minX = math.max(minX, leftX + titleTw + 8)
        if ImGui.SetCursorPos then ImGui.SetCursorPos(minX, rowY) end
        local padV = 0
        if ImGui.PushStyleVar and ImGuiStyleVar and ImGuiStyleVar.FrameRounding then
            ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 3)
            padV = 1
        end
        local n = pushFillBtn(202, 160, 74, 14, 22, 34, 18) -- #caa04a / navy text
        if ImGui.Button('-##fw_minimize', minW, 20) then M.close() end
        popStyles(n, padV)
    end

    sectionGap()

    -- Toolbar: views left, actions on the right of last table width.
    -- Do NOT use GetContentRegionAvail gaps here — AlwaysAutoResize grows forever.
    local toolbarLeftX = ImGui.GetCursorPosX()
    if textNav('Group', 'fw_scope_group', scope == 'group') then setScope('group') end
    ImGui.SameLine(0, 8)
    if textNav('E3', 'fw_scope_e3', scope == 'e3') then setScope('e3') end
    ImGui.SameLine(0, 8)
    if textNav('Live', 'fw_scope_live', scope == 'live') then setScope('live') end
    do
        local function navW(label) return textWidth(label) + 14 end
        local actionsW = navW('Picks') + navW('Columns') + navW('Refresh') + 16
        ImGui.SameLine(0, 0)
        local afterLive = ImGui.GetCursorPosX()
        local layoutW = tonumber(TG._fwLayoutW) or 0
        local targetX = afterLive + 16
        if layoutW > 0 then
            targetX = math.max(afterLive + 16, toolbarLeftX + layoutW - actionsW)
        end
        if ImGui.SetCursorPosX then ImGui.SetCursorPosX(targetX) end
    end
    if textNav('Picks', 'fw_scope_picks', scope == 'picks') then setScope('picks') end
    ImGui.SameLine(0, 8)
    if textNav('Columns', 'fw_columns', TG.fleetWalletShowSettings == true) then
        TG.fleetWalletShowSettings = not TG.fleetWalletShowSettings
    end
    if ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        ImGui.Text('Show / hide table columns')
        ImGui.EndTooltip()
    end
    ImGui.SameLine(0, 8)
    if textNav('Refresh', 'fw_refresh', false) then
        TG._fwPeerSig = nil
        TG._fwLastSideSig = nil
        TG._fwNextLiveMS = 0
        ensurePeers(false)
        if (TG._fwPeerSource or '') == 'none' then ensurePeers(true) end
        TG._fwNeedPeerPoke = true
    end

    sectionGap()

    drawCurrencySegment()
    ImGui.SameLine(0, 14)
    textC(C.muted, 'Pool to')
    ImGui.SameLine(0, 4)
    textC(C.title, selected ~= '' and selected or '(none)')
    ImGui.SameLine(0, 4)
    local canClearRecip = selected ~= '' and selected:lower() ~= me:lower()
    if not canClearRecip then ImGui.BeginDisabled() end
    do
        local n = pushGhostBtn(C.clearX)
        if ImGui.Button('x##fw_clear_recip', 16, 0) and canClearRecip then
            TG.fleetWalletRecipient = me
            selected = me
        end
        popStyles(n, 0)
    end
    if not canClearRecip then ImGui.EndDisabled() end
    if ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        ImGui.Text(canClearRecip and 'Clear pool target (back to you)' or 'Pool target is you')
        ImGui.EndTooltip()
    end

    -- Columns panel (separate from Picks roster mode).
    if TG.fleetWalletShowSettings then
        sectionGap()
        textC(C.header, 'Columns')
        local colChanged = false
        for _, spec in ipairs({
            { 'pp', 'PP' }, { 'dc', 'DC' }, { 'rc', 'RC' },
            { 'fav', 'Fav' }, { 'cc', 'CC' }, { 'aa', 'AA' },
        }) do
            local key, label = spec[1], spec[2]
            local on = cols[key] ~= false
            local newOn = ImGui.Checkbox(label .. '##fw_col_' .. key, on)
            if newOn ~= on then
                cols[key] = newOn
                colChanged = true
            end
            ImGui.SameLine(0, 8)
        end
        ImGui.NewLine()
        if colChanged then
            TG.fleetWalletColumns = cols
            if TG.saveSettings then pcall(TG.saveSettings) end
        end
    end

    -- Picks editor only while roster scope is Picks.
    if scope == 'picks' then
        sectionGap()
        textC(C.header, 'Picks (saved roster for this view)')
        local names = {}
        for _, name in pairs(known) do
            if not isForgotten(name) then names[#names + 1] = name end
        end
        table.sort(names, function(a, b) return a:lower() < b:lower() end)
        local picks = TG.fleetWalletPicks
        if type(picks) ~= 'table' then picks = {}; TG.fleetWalletPicks = picks end
        local changed = false
        for _, name in ipairs(names) do
            local key = clean(name)
            local on = picks[name] == true or picks[key] == true
            local newOn = ImGui.Checkbox(name .. '##fw_pick_' .. key, on)
            if newOn ~= on then
                picks[name] = newOn and true or nil
                picks[key] = nil
                changed = true
            end
            ImGui.SameLine(0, 4)
            if opsButton('Forget', 'fw_forget_' .. key, false) then
                forgetName(name)
                changed = true
            end
        end
        if changed then
            TG.fleetWalletPicks = picks
            if TG.saveSettings then pcall(TG.saveSettings) end
        end
        local forgotten = TG.fleetWalletForgotten
        if type(forgotten) == 'table' and next(forgotten) ~= nil then
            if textNav('Restore forgotten', 'fw_restore_forgotten', false) then
                TG.fleetWalletForgotten = {}
                if TG.saveSettings then pcall(TG.saveSettings) end
            end
        end
    end

    sectionGap()

    local colDefs = { { key = 'name', title = 'Name', w = 0 } }
    if cols.pp ~= false then colDefs[#colDefs + 1] = { key = 'pp', title = 'PP', w = 52 } end
    if cols.dc ~= false then colDefs[#colDefs + 1] = { key = 'dc', title = 'DC', w = 36 } end
    if cols.rc ~= false then colDefs[#colDefs + 1] = { key = 'rc', title = 'RC', w = 36 } end
    if cols.fav ~= false then colDefs[#colDefs + 1] = { key = 'fav', title = 'Fav', w = 44 } end
    if cols.cc ~= false then colDefs[#colDefs + 1] = { key = 'cc', title = 'CC', w = 36 } end
    if cols.aa ~= false then colDefs[#colDefs + 1] = { key = 'aa', title = 'AA', w = 36 } end
    colDefs[#colDefs + 1] = { key = 'ops', title = 'Ops', w = 78 }

    local tot = { pp = 0, dc = 0, rc = 0, fav = 0, cc = 0, aa = 0 }
    -- Vertical hairlines only (no per-row boxes); header/totals still use paint lines.
    -- Avoid SizingFixedFit — it collapses under AlwaysAutoResize when cells
    -- briefly report empty content.
    local fwFlags = (ImGuiTableFlags and ImGuiTableFlags.NoPadOuterX or 0)
        + (ImGuiTableFlags and ImGuiTableFlags.BordersInnerV or 0)
    local colFlags = ImGuiTableColumnFlags or {}
    local CELL_BG = ImGuiTableBgTarget and (ImGuiTableBgTarget.CellBg or ImGuiTableBgTarget.RowBg0)

    local function paint_cell(isActiveCol, isSelRow, isTotals)
        if not (ImGui.TableSetBgColor and IM_COL32 and CELL_BG) then return end
        -- Recipient wash wins — paint wash on every cell; never stack column tint.
        if isSelRow then
            if COL_ROW then ImGui.TableSetBgColor(CELL_BG, COL_ROW) end
            return
        end
        if isActiveCol then
            ImGui.TableSetBgColor(CELL_BG, isTotals and COL_CUR_TOT or COL_CUR)
        end
    end

    local tblPad, tblCols = 0, 0
    if ImGui.PushStyleVar and ImGuiStyleVar and ImGuiStyleVar.CellPadding then
        ImGui.PushStyleVar(ImGuiStyleVar.CellPadding, 6, 3)
        tblPad = 1
    end
    if ImGui.PushStyleColor and ImGuiCol then
        -- Subtle column rules (#273444 / #1b2836).
        if ImGuiCol.TableBorderLight then
            ImGui.PushStyleColor(ImGuiCol.TableBorderLight, 39 / 255, 52 / 255, 68 / 255, 0.85)
            tblCols = tblCols + 1
        end
        if ImGuiCol.TableBorderStrong then
            ImGui.PushStyleColor(ImGuiCol.TableBorderStrong, 27 / 255, 40 / 255, 54 / 255, 0.95)
            tblCols = tblCols + 1
        end
    end

    if ImGui.BeginTable and ImGui.BeginTable('##fleet_wallet_tbl', #colDefs, fwFlags) then
        for _, def in ipairs(colDefs) do
            if def.key == 'name' then
                ImGui.TableSetupColumn(def.title, colFlags.WidthStretch or 0)
            else
                ImGui.TableSetupColumn(def.title, colFlags.WidthFixed or 0, def.w)
            end
        end
        local cur = activeCurrency()

        ImGui.TableNextRow()
        for _, def in ipairs(colDefs) do
            ImGui.TableNextColumn()
            local isCur = def.key == cur
            paint_cell(isCur, false, false)
            if isCur then
                centerText(C.title, def.title)
            else
                centerText(C.header, def.title)
            end
        end
        paintHairlineAcross()

        local zebra = false
        for _, row in ipairs(rows) do
            ImGui.TableNextRow()
            local isSel = selected:lower() == tostring(row.name):lower()
            if isSel and ImGui.TableSetBgColor and ImGuiTableBgTarget and COL_ROW then
                ImGui.TableSetBgColor(ImGuiTableBgTarget.RowBg0, COL_ROW)
                if ImGuiTableBgTarget.RowBg1 then
                    ImGui.TableSetBgColor(ImGuiTableBgTarget.RowBg1, COL_ROW)
                end
            elseif (not isSel) and zebra and ImGui.TableSetBgColor and ImGuiTableBgTarget and COL_ZEBRA then
                ImGui.TableSetBgColor(ImGuiTableBgTarget.RowBg0, COL_ZEBRA)
            end
            if not isSel then zebra = not zebra end

            local accentX, accentY1, accentY2
            for _, def in ipairs(colDefs) do
                ImGui.TableNextColumn()
                local isCur = def.key == cur
                paint_cell(isCur, isSel, false)
                if def.key == 'name' then
                    local label = row.name .. (row.isSelf and ' (you)' or '')
                    if isSel and ImGui.PushStyleColor and ImGuiCol then
                        ImGui.PushStyleColor(ImGuiCol.Text, rgba(C.onWash))
                    end
                    if ImGui.Selectable(label .. '##fw_' .. row.name, false) then
                        TG.fleetWalletRecipient = row.name
                        selected = row.name
                    end
                    if isSel and ImGui.PopStyleColor then ImGui.PopStyleColor(1) end
                    if isSel and ImGui.GetItemRectMin then
                        pcall(function()
                            accentX, accentY1 = ImGui.GetItemRectMin()
                            local _, y2 = ImGui.GetItemRectMax()
                            accentY2 = y2
                        end)
                    end
                elseif def.key == 'pp' then
                    rightText(valueColor('pp', row.plat, isSel), fmt(row.plat))
                    if row.plat then tot.pp = tot.pp + row.plat end
                elseif def.key == 'dc' then
                    rightText(valueColor('dc', row.dc, isSel), fmt(row.dc))
                    if row.dc then tot.dc = tot.dc + row.dc end
                elseif def.key == 'rc' then
                    rightText(valueColor('rc', row.rc, isSel), fmt(row.rc))
                    if row.rc then tot.rc = tot.rc + row.rc end
                elseif def.key == 'fav' then
                    rightText(valueColor('fav', row.favor, isSel), fmt(row.favor))
                    if row.favor then tot.fav = tot.fav + row.favor end
                elseif def.key == 'cc' then
                    rightText(valueColor('cc', row.crests, isSel), fmt(row.crests))
                    if row.crests then tot.cc = tot.cc + row.crests end
                elseif def.key == 'aa' then
                    rightText(valueColor('aa', row.aa, isSel), fmt(row.aa))
                    if row.aa then tot.aa = tot.aa + row.aa end
                elseif def.key == 'ops' then
                    if row.isSelf then
                        ImGui.Text('')
                    else
                        if not canControl then ImGui.BeginDisabled() end
                        if opsButton('Get', 'fw_get_' .. row.name, isSel) then
                            if TG.requireSharedControl('Collect ' .. curLabel .. ' from ' .. row.name) then
                                TG.fleetWalletRecipient = me
                                selected = me
                                runCollectFrom(row.name)
                            end
                        end
                        if ImGui.IsItemHovered() then
                            ImGui.BeginTooltip()
                            if amt then
                                ImGui.Text(string.format('Get %d %s from %s', amt, curLabel, row.name))
                            else
                                ImGui.Text(string.format('Get all %s from %s', curLabel, row.name))
                            end
                            ImGui.EndTooltip()
                        end
                        if ImGui.GetItemRectMax and accentY1 then
                            pcall(function()
                                local _, y2 = ImGui.GetItemRectMax()
                                if y2 and (not accentY2 or y2 > accentY2) then accentY2 = y2 end
                            end)
                        end
                        ImGui.SameLine(0, 2)
                        if opsButton('Send', 'fw_send_' .. row.name, isSel) then
                            if TG.requireSharedControl('Send ' .. curLabel .. ' to ' .. row.name) then
                                TG.fleetWalletRecipient = row.name
                                selected = row.name
                                runSendMineTo(row.name)
                            end
                        end
                        if ImGui.IsItemHovered() then
                            ImGui.BeginTooltip()
                            if amt then
                                ImGui.Text(string.format('Send %d %s to %s', amt, curLabel, row.name))
                            else
                                ImGui.Text(string.format('Send all %s to %s', curLabel, row.name))
                            end
                            ImGui.EndTooltip()
                        end
                        if ImGui.GetItemRectMax and accentY1 then
                            pcall(function()
                                local _, y2 = ImGui.GetItemRectMax()
                                if y2 and (not accentY2 or y2 > accentY2) then accentY2 = y2 end
                            end)
                        end
                        if not canControl then ImGui.EndDisabled() end
                    end
                end
            end
            if isSel and accentX and accentY1 and accentY2 and COL_ACCENT then
                drawRectFilled(accentX, accentY1, accentX + 2, accentY2, COL_ACCENT)
            end
        end

        paintHairlineAcross()
        ImGui.TableNextRow()
        for _, def in ipairs(colDefs) do
            ImGui.TableNextColumn()
            paint_cell(def.key == cur, false, true)
            if def.key == 'name' then
                textC(C.muted, 'Totals')
            elseif def.key == 'pp' then rightText(valueColor('pp', tot.pp, false), fmt(tot.pp))
            elseif def.key == 'dc' then rightText(valueColor('dc', tot.dc, false), fmt(tot.dc))
            elseif def.key == 'rc' then rightText(valueColor('rc', tot.rc, false), fmt(tot.rc))
            elseif def.key == 'fav' then rightText(valueColor('fav', tot.fav, false), fmt(tot.fav))
            elseif def.key == 'cc' then rightText(valueColor('cc', tot.cc, false), fmt(tot.cc))
            elseif def.key == 'aa' then rightText(valueColor('aa', tot.aa, false), fmt(tot.aa))
            else ImGui.Text('') end
        end
        ImGui.EndTable()
        -- Drive toolbar right-align from table width (stable under AlwaysAutoResize).
        if ImGui.GetItemRectMin and ImGui.GetItemRectMax then
            pcall(function()
                local x1 = select(1, ImGui.GetItemRectMin())
                local x2 = select(1, ImGui.GetItemRectMax())
                x1, x2 = tonumber(x1), tonumber(x2)
                if x1 and x2 and x2 > x1 + 80 then
                    TG._fwLayoutW = x2 - x1
                end
            end)
        end
    end
    if tblCols > 0 and ImGui.PopStyleColor then ImGui.PopStyleColor(tblCols) end
    if tblPad > 0 and ImGui.PopStyleVar then ImGui.PopStyleVar(tblPad) end

    sectionGap()

    local canGive = selected ~= '' and selected:lower() ~= me:lower()
    local collectLabel = amt
        and ('Collect %s x%d##fw_collect'):format(curLabel, amt)
        or ('Collect %s##fw_collect'):format(curLabel)
    local poolLabel
    if amt and canGive then
        poolLabel = ('Pool x%d to %s##fw_give'):format(amt, selected)
    elseif canGive then
        poolLabel = ('Pool %s to %s##fw_give'):format(curLabel, selected)
    else
        poolLabel = ('Pool %s##fw_give'):format(curLabel)
    end

    if not canControl then ImGui.BeginDisabled() end
    if actionButton(collectLabel, true) then
        if TG.requireSharedControl('Collect ' .. curLabel) then
            runCollectScope()
        end
    end
    if ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        if amt then
            ImGui.Text(string.format('Ask peers in scope for %d %s', amt, curLabel))
        else
            ImGui.Text(string.format('Ask peers in scope for all %s', curLabel))
        end
        ImGui.EndTooltip()
    end
    ImGui.SameLine(0, 6)
    if not canGive then ImGui.BeginDisabled() end
    if actionButton(poolLabel, false) then
        if TG.requireSharedControl('Pool ' .. curLabel) then
            runPoolScope(selected)
        end
    end
    if ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        if canGive then
            if amt then
                ImGui.Text(string.format('Ask peers to send %d %s to %s', amt, curLabel, selected))
            else
                ImGui.Text(string.format('Ask peers to send all %s to %s', curLabel, selected))
            end
        else
            ImGui.Text('Click a peer name to set Pool to')
        end
        ImGui.EndTooltip()
    end
    if not canGive then ImGui.EndDisabled() end
    if not canControl then ImGui.EndDisabled() end

    ImGui.SameLine(0, 16)
    textC(C.muted, 'Amount')
    ImGui.SameLine(0, 6)
    local allOn = amt == nil
    do
        local padV = 0
        if ImGui.PushStyleVar and ImGuiStyleVar and ImGuiStyleVar.FrameRounding then
            ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 5)
            padV = 1
        end
        local n
        if allOn then
            n = pushFillBtn(44, 140, 138, 5, 43, 42, 14)
        else
            n = pushFillBtn(27, 39, 52, 147, 160, 176, 12)
        end
        if ImGui.Button('All##fw_amt_all', 40, 0) then
            TG.fleetWalletAmount = ''
            if TG.saveSettings then pcall(TG.saveSettings) end
        end
        popStyles(n, padV)
    end
    ImGui.SameLine(0, 4)
    do
        local n = 0
        if ImGui.PushStyleColor and ImGuiCol then
            ImGui.PushStyleColor(ImGuiCol.FrameBg, 27 / 255, 39 / 255, 52 / 255, 1)
            ImGui.PushStyleColor(ImGuiCol.FrameBgHovered, 32 / 255, 46 / 255, 60 / 255, 1)
            ImGui.PushStyleColor(ImGuiCol.FrameBgActive, 32 / 255, 46 / 255, 60 / 255, 1)
            n = 3
        end
        if ImGui.SetNextItemWidth then ImGui.SetNextItemWidth(70) end
        local nextAmt = ImGui.InputText('##fw_amt', tostring(TG.fleetWalletAmount or ''))
        if nextAmt ~= nil and tostring(nextAmt) ~= tostring(TG.fleetWalletAmount or '') then
            TG.fleetWalletAmount = tostring(nextAmt):gsub('%D', '')
            if TG.saveSettings then pcall(TG.saveSettings) end
        end
        popStyles(n, 0)
    end
    if ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        ImGui.Text('Applies to Get, Send, Collect, and Pool')
        ImGui.EndTooltip()
    end

    if densV > 0 and ImGui.PopStyleVar then ImGui.PopStyleVar(densV) end
end

--- $ chrome button only. Panel is drawn via drawWindow (survives Turbo Mini).
function M.drawChrome(btnW, btnH)
    if not btnW or btnW <= 0 then return end
    if Ui.buttonVariant('$##topwalletbtn', 'walletButton', btnW, btnH) then
        local opening = not M.isOpen()
        M.setOpen(opening)
        if opening then
            TG._fwLoadErr = nil
            TG._fwNextLiveMS = 0
            pcall(function() ensurePeers(false) end)
            TG._fwNeedPeerPoke = true -- one ping round; reads are silent after that
            armFastPoll(10000)
        end
    end
    if TG.turboChromeDragAddLastItem then TG.turboChromeDragAddLastItem() end
    if ImGui.IsItemHovered and ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        ImGui.TextColored(0.88, 0.80, 0.35, 1.0, string.format('%12s pp', tostring(cachedWallet.plat)))
        ImGui.TextColored(0.45, 0.78, 0.82, 1.0, string.format('%12s dc', tostring(cachedWallet.dc)))
        ImGui.TextColored(0.55, 0.85, 0.75, 1.0, string.format('%12s rc', tostring(cachedWallet.rc or 0)))
        ImGui.TextColored(0.85, 0.70, 0.40, 1.0, string.format('%12s favor', tostring(cachedWallet.favor or 0)))
        ImGui.TextColored(0.70, 0.60, 0.90, 1.0, string.format('%12s crests', tostring(cachedWallet.crests or 0)))
        ImGui.TextColored(0.55, 0.78, 0.95, 1.0, string.format('%12s aa', tostring(cachedWallet.aa or 0)))
        ImGui.TextColored(0.55, 0.58, 0.68, 1.0, 'TurboWallet - stays open if you Mini Turbo')
        ImGui.EndTooltip()
    end

    -- Seed only for first-ever open (no saved layout yet).
    if ImGui.GetItemRectMin and ImGui.GetItemRectMax then
        pcall(function()
            local x1 = select(1, ImGui.GetItemRectMin())
            local _, y2 = ImGui.GetItemRectMax()
            TG._fwSeedX = tonumber(x1)
            TG._fwSeedY = tonumber(y2) and (tonumber(y2) + 2) or nil
        end)
    end
    ImGui.SameLine()
end

--- Independent panel window (call from Mini and Full GUI paths).
function M.drawWindow()
    if not M.isOpen() or not ImGui.Begin then return end
    if rawget(_G, '__TurboFleetWalletPlaceOnce') and ImGui.SetNextWindowPos then
        local pos = TG.fleetWalletWindowPos
        local x, y
        if pos and pos.x and pos.y then
            x, y = tonumber(pos.x), tonumber(pos.y)
        elseif TG._fwSeedX and TG._fwSeedY then
            -- First open ever: start near $, then free-float + persist.
            x, y = tonumber(TG._fwSeedX), tonumber(TG._fwSeedY)
        end
        if x and y then
            pcall(ImGui.SetNextWindowPos, x, y)
        end
        rawset(_G, '__TurboFleetWalletPlaceOnce', false)
    end
    -- Keep a usable minimum width so AlwaysAutoResize does not collapse left.
    if ImGui.SetNextWindowSizeConstraints then
        pcall(ImGui.SetNextWindowSizeConstraints, 460, 0, 1200, 1200)
    end
    local flags = 0
    if ImGuiWindowFlags then
        flags = (ImGuiWindowFlags.NoTitleBar or 0)
            + (ImGuiWindowFlags.AlwaysAutoResize or 0)
            + (ImGuiWindowFlags.NoCollapse or 0)
    end
    -- Sleek frame: 1px amber-gold #caa04a, panel #0e1622.
    local pushedVars, pushedColors = 0, 0
    if ImGui.PushStyleVar and ImGuiStyleVar and ImGuiStyleVar.WindowBorderSize then
        ImGui.PushStyleVar(ImGuiStyleVar.WindowBorderSize, 1.0)
        pushedVars = pushedVars + 1
    end
    if ImGui.PushStyleVar and ImGuiStyleVar and ImGuiStyleVar.WindowRounding then
        ImGui.PushStyleVar(ImGuiStyleVar.WindowRounding, 4)
        pushedVars = pushedVars + 1
    end
    if ImGui.PushStyleVar and ImGuiStyleVar and ImGuiStyleVar.FrameRounding then
        ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 5)
        pushedVars = pushedVars + 1
    end
    if ImGui.PushStyleColor and ImGuiCol then
        if ImGuiCol.Border then
            ImGui.PushStyleColor(ImGuiCol.Border, 202 / 255, 160 / 255, 74 / 255, 1.0) -- #caa04a
            pushedColors = pushedColors + 1
        end
        if ImGuiCol.WindowBg then
            ImGui.PushStyleColor(ImGuiCol.WindowBg, 14 / 255, 22 / 255, 34 / 255, 1.0) -- #0e1622
            pushedColors = pushedColors + 1
        end
        if ImGuiCol.ChildBg then
            ImGui.PushStyleColor(ImGuiCol.ChildBg, 14 / 255, 22 / 255, 34 / 255, 1.0)
            pushedColors = pushedColors + 1
        end
        if ImGuiCol.Text then
            ImGui.PushStyleColor(ImGuiCol.Text, 199 / 255, 208 / 255, 218 / 255, 1.0) -- #c7d0da
            pushedColors = pushedColors + 1
        end
    end
    local a, b = ImGui.Begin('TurboFleetWallet##panel', true, flags)
    local shouldDraw = (b == nil) and a or b
    if shouldDraw then
        persistWindowPos()
        local ok, err = pcall(M.drawPanel)
        if not ok then
            ImGui.TextColored(0.92, 0.45, 0.40, 1.0, 'TurboWallet error:')
            ImGui.TextWrapped(tostring(err))
        end
    else
        -- User closed via OS/X path if exposed; keep our open flag in sync.
        M.close()
    end
    ImGui.End()
    if pushedColors > 0 and ImGui.PopStyleColor then ImGui.PopStyleColor(pushedColors) end
    if pushedVars > 0 and ImGui.PopStyleVar then ImGui.PopStyleVar(pushedVars) end
end

return M
