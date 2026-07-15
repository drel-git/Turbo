--[[
  TurboWares - data layer (merchant hustlin')
  @version lua/Turbo/wares.lua 1.7.2
]]

local mq = require('mq')

local M = {}

local writeIniKey
local readIniKey
local readIniSectionPairs
local deleteIniKey
local resolveTurbolootIniPathForProfile
local cleanProfileName
local creditGainsSale

local inventoryRows = {}
local merchantRows = {}
local buyWatchNames = {}
local buyWatchKeys = {}
local ruleLookupCache = {}
local lastInvScanMs = 0
local lastMerchantScanMs = 0
local merchantSnapshotPending = false
local lastUndo = nil

local INV_SCAN_INTERVAL_MS = 2500
local MERCHANT_SCAN_MIN_MS = 1500
local BAG_FIRST = 23
local BAG_LAST = 34
local TL_TAG = '[turboLoot]'
local TW_TAG = '[TurboWares]'

M.RULE_LABELS = { 'KEEP', 'SELL', 'BANK', 'TRIBUTE', 'DESTROY', 'IGNORE', 'ANNOUNCE' }

local function nowMs()
    return mq.gettime()
end

local function canonicalKey(name)
    return tostring(name or ''):lower():match('^%s*(.-)%s*$') or ''
end

local function normalizeNameKey(name)
    return canonicalKey(name):gsub("[''`]", '')
end

local function stripRule(raw)
    if not raw then return '' end
    local s = raw:match('^([^;]*)') or raw
    return (s:gsub('^%s+', ''):gsub('%s+$', ''))
end

local function stripIniSetting(raw)
    raw = tostring(raw or '')
    local semi = raw:find(';', 1, true)
    if semi then raw = raw:sub(1, semi - 1) end
    return raw:match('^%s*(.-)%s*$') or ''
end

local function stripColorCodes(msg)
    msg = tostring(msg or '')
    return msg:gsub('\\a%w', '')
end

local function normalizeAnnounceMethod(raw)
    raw = stripIniSetting(raw):gsub('^/', '')
    local upper = raw:upper():gsub('%s+', '')
    if upper == '' or upper == '0' or upper == 'OFF' or upper == 'FALSE' or upper == 'NO' then return 'OFF' end
    if upper:sub(1, 4) == 'E3BC' then return 'e3bc' end
    if upper:sub(1, 4) == 'ECHO' then return 'echo' end
    if upper:sub(1, 3) == 'SAY' then return 'say' end
    if upper == 'G' or upper:sub(1, 4) == 'GSAY' then return 'gsay' end
    if upper == 'RS' or upper:sub(1, 4) == 'RSAY' then return 'rsay' end
    return raw
end

local function readIniBool(iniPath, section, key, default)
    if not readIniKey or not iniPath or iniPath == '' then return default end
    local raw = stripIniSetting(readIniKey(iniPath, section, key))
    local upper = raw:upper():gsub('%s+', '')
    if upper == '' then return default end
    if upper == '0' or upper == 'OFF' or upper == 'FALSE' or upper == 'NO' then return false end
    if upper == '1' or upper == 'ON' or upper == 'TRUE' or upper == 'YES' then return true end
    local n = tonumber(raw)
    if n ~= nil then return n ~= 0 end
    return default
end

local function resolveBankSellAnnounceMethod(iniPath)
    if not readIniKey or not iniPath or iniPath == '' then return 'echo' end
    local raw = stripIniSetting(readIniKey(iniPath, 'Settings', 'announceBankSell'))
    if raw ~= '' then
        local method = normalizeAnnounceMethod(raw)
        if method ~= 'OFF' then return method end
        return 'OFF'
    end
    raw = stripIniSetting(readIniKey(iniPath, 'Settings', 'bankSellTributeAnnounceMethod'))
    if raw ~= '' then
        local method = normalizeAnnounceMethod(raw)
        if method ~= 'OFF' then return method end
    end
    raw = stripIniSetting(readIniKey(iniPath, 'Settings', 'announceDefaultTo'))
    local method = normalizeAnnounceMethod(raw)
    if method == 'OFF' or method == '' then return 'echo' end
    return method
end

local function formatAnnounceBody(msg, method)
    msg = tostring(msg or '')
    if method == 'echo' or method == 'e3bc' then return msg end
    msg = stripColorCodes(msg)
    msg = msg:gsub('%[TurboWares%] ', ''):gsub('%[TurboWares%]', '')
    msg = msg:gsub('%[turboLoot%] ', ''):gsub('%[turboLoot%]', '')
    return msg
end

local function announceBankSell(iniPath, msg)
    local method = resolveBankSellAnnounceMethod(iniPath)
    if method == 'OFF' then return end
    local body = formatAnnounceBody(msg, method)
    local lower = method:lower()
    if lower == 'echo' or lower == 'e3bc' then
        mq.cmdf('/squelch /%s %s', lower, body)
        return
    end
    if lower:sub(1, 2) == 't ' then
        local target = method:sub(3):match('^%s*(.-)%s*$') or ''
        if target ~= '' then mq.cmdf('/tell %s %s', target, body) end
        return
    end
    if lower:sub(1, 5) == 'tell ' then
        local target = method:sub(6):match('^%s*(.-)%s*$') or ''
        if target ~= '' then mq.cmdf('/tell %s %s', target, body) end
        return
    end
    mq.cmdf('/%s %s', method, body)
end

local function copperTotal()
    local me = mq.TLO.Me
    return (me.Platinum() or 0) * 1000 + (me.Gold() or 0) * 100 + (me.Silver() or 0) * 10 + (me.Copper() or 0)
end

local function formatCopper(copper)
    copper = math.max(0, math.floor(tonumber(copper) or 0))
    local p = math.floor(copper / 1000)
    local g = math.floor((copper % 1000) / 100)
    local s = math.floor((copper % 100) / 10)
    local c = copper % 10
    return string.format('%dpp %dgp %dsp %dcp', p, g, s, c)
end

function M.formatCopperLong(copper)
    return formatCopper(copper)
end

local function formatDecimal(units)
    units = tonumber(units) or 0
    if units >= 100 or math.abs(units - math.floor(units + 0.0001)) < 0.05 then
        return string.format('%.0f', units)
    end
    local rounded = math.floor(units * 10 + 0.5) / 10
    if math.abs(rounded - math.floor(rounded + 0.0001)) < 0.05 then
        return string.format('%.0f', rounded)
    end
    return string.format('%.1f', rounded)
end

local function formatUnitsWithSuffix(units, suffix)
    return formatDecimal(units) .. suffix
end

function M.formatCompactCopper(copper)
    copper = math.max(0, math.floor(tonumber(copper) or 0))
    local pp = copper / 1000
    if pp >= 1 then return formatUnitsWithSuffix(pp, 'p') end
    local gp = copper / 100
    if gp >= 1 then return formatUnitsWithSuffix(gp, 'g') end
    if copper >= 10 then return formatUnitsWithSuffix(copper / 10, 's') end
    return formatUnitsWithSuffix(copper, 'c')
end

function M.formatCompactPrice(pricePlatinum)
    pricePlatinum = tonumber(pricePlatinum) or 0
    if pricePlatinum <= 0 then return '-' end
    return formatUnitsWithSuffix(pricePlatinum, 'p')
end

function M.formatCompactPriceCopper(copper)
    copper = tonumber(copper) or 0
    if copper <= 0 then return '-' end
    return M.formatCompactCopper(copper)
end

function M.rowSellCopper(row)
    if not row then return 0 end
    local unit = math.max(0, tonumber(row.value) or 0)
    local qty = math.max(1, tonumber(row.qty) or 1)
    return unit * qty
end

local function formatSellStackEntry(row)
    local qty = math.max(1, tonumber(row.qty) or 1)
    local est = M.formatCompactCopper(M.rowSellCopper(row))
    local name = tostring(row.name or '?')
    if qty > 1 then
        return string.format('%s x%d ~%s', name, qty, est)
    end
    return string.format('%s ~%s', name, est)
end

local TW_SEP = '\\ao----------------------------------------'

local function waresEcho(msg)
    msg = tostring(msg or '')
    if msg == '' then return end
    mq.cmdf('/echo \\at[TurboWares]\\ax %s', msg)
end

local function announceWares(iniPath, msg)
    announceBankSell(iniPath, TW_TAG .. ' ' .. tostring(msg or ''))
end

local function announceWaresSellStart(iniPath, candidates, estCopper)
    local totalText = M.formatCompactCopper(estCopper)
    waresEcho(TW_SEP)
    waresEcho(string.format('\\aosell:\\aw %d stack%s (~\\ag%s\\ag est.)',
        #candidates, #candidates == 1 and '' or 's', totalText))
    for _, row in ipairs(candidates) do
        waresEcho('\\aw  ' .. formatSellStackEntry(row))
    end
    waresEcho(TW_SEP)
    announceWares(iniPath, string.format('\\aosell:\\aw %d stack%s (~\\ag%s\\ag est. total)',
        #candidates, #candidates == 1 and '' or 's', totalText))
end

local function announceWaresSellComplete(itemsSold, totalCopper, soldLines)
    waresEcho(TW_SEP)
    waresEcho(string.format('\\aosell complete:\\ag %d stack%s for %s\\ag',
        itemsSold, itemsSold == 1 and '' or 's', formatCopper(totalCopper)))
    for _, line in ipairs(soldLines or {}) do
        waresEcho('\\ag  ' .. line)
    end
    waresEcho(TW_SEP)
end

local function announceWaresBuy(name, qty, pricePlatinum, useQuantityWnd, priceCopper)
    name = tostring(name or '')
    waresEcho(TW_SEP)
    if useQuantityWnd then
        waresEcho(string.format('\\aobuy:\\aw quantity window -> \\aw%s', name))
    else
        qty = math.max(1, math.floor(tonumber(qty) or 1))
        local unitCopper = tonumber(priceCopper)
        if not unitCopper then unitCopper = math.floor(((tonumber(pricePlatinum) or 0) * 1000) + 0.5) end
        local totalText = M.formatCompactPriceCopper(unitCopper * qty)
        local unitText = M.formatCompactPriceCopper(unitCopper)
        waresEcho(string.format('\\aobuy:\\aw %d x \\aw%s\\aw (~\\ag%s\\ag at %s each)',
            qty, name, totalText, unitText))
    end
    waresEcho(TW_SEP)
end

function M.setup(env)
    writeIniKey = env.writeIniKey
    readIniKey = env.readIniKey
    readIniSectionPairs = env.readIniSectionPairs
    deleteIniKey = env.deleteIniKey
    resolveTurbolootIniPathForProfile = env.resolveTurbolootIniPathForProfile
    cleanProfileName = env.cleanProfileName
    creditGainsSale = env.creditGainsSale
end

function M.invalidateRuleCache(iniPath)
    if not iniPath or iniPath == '' then
        ruleLookupCache = {}
        return
    end
    ruleLookupCache[iniPath:lower()] = nil
end

function M.buildRuleLookup(iniPath)
    if not iniPath or iniPath == '' then return {} end
    local cacheKey = iniPath:lower()
    if ruleLookupCache[cacheKey] then
        return ruleLookupCache[cacheKey]
    end
    local lookup = {}
    if readIniSectionPairs then
        for _, pair in ipairs(readIniSectionPairs(iniPath, 'ItemLimits') or {}) do
            local key = tostring(pair.key or ''):match('^%s*(.-)%s*$') or ''
            if key ~= '' then
                lookup[key] = pair.value
                lookup[key:upper()] = pair.value
                lookup[key:lower()] = pair.value
            end
        end
    end
    ruleLookupCache[cacheKey] = lookup
    return lookup
end

function M.readRule(lookup, itemName)
    if not lookup or not itemName or itemName == '' then return '' end
    local raw = lookup[itemName] or lookup[itemName:upper()] or lookup[itemName:lower()]
    return stripRule(raw)
end

function M.ruleRgb(rule, turboKeyRGB)
    local tk = turboKeyRGB or {}
    local upper = tostring(rule or ''):upper():gsub('%s+', '')
    if upper == 'KEEP' then return tk.keep or { 70, 100, 150 } end
    if upper == 'SELL' then return tk.sell or { 60, 120, 80 } end
    if upper == 'BANK' then return tk.bank or tk.trade or { 90, 82, 130 } end
    if upper == 'TRIBUTE' then return tk.tribute or { 130, 95, 35 } end
    if upper == 'DESTROY' then return tk.destroy or { 145, 60, 55 } end
    if upper == 'IGNORE' or upper == 'SKIP' then return tk.skip or { 55, 58, 65 } end
    if upper == 'ANNOUNCE' then return tk.announce or { 55, 130, 140 } end
    if tonumber(upper) then return tk.keep or { 70, 100, 150 } end
    return { 120, 125, 135 }
end

function M.matchesFilter(name, filter)
    filter = tostring(filter or ''):lower()
    if filter == '' then return true end
    local lower = tostring(name or ''):lower()
    for term in filter:gmatch('[^|]+') do
        term = term:match('^%s*(.-)%s*$') or ''
        if term ~= '' and lower:find(term, 1, true) then return true end
    end
    return false
end

local function appendItem(rows, item, slotLabel, packNum, slotNum)
    if not item or not item() then return end
    local name = item.Name()
    if not name or name == '' or name == 'NULL' then return end
    local nameKey = canonicalKey(name)
    if nameKey == '' then return end
    local pack = packNum or 0
    local slot = slotNum or 0
    rows[#rows + 1] = {
        key = string.format('%s#%d:%d', nameKey, pack, slot),
        nameKey = nameKey,
        name = name,
        qty = item.StackCount() or 1,
        icon = item.Icon() or 500,
        itemId = item.ID() or 0,
        slotLabel = slotLabel or '',
        sellable = not item.NoDrop() and not item.NoRent(),
        packNum = packNum or 0,
        slotNum = slotNum or 0,
        value = item.Value() or 0,
    }
end

function M.scanInventory(force)
    local t = nowMs()
    if not force and (t - lastInvScanMs) < INV_SCAN_INTERVAL_MS then
        return inventoryRows
    end
    lastInvScanMs = t
    local rows = {}
    for i = BAG_FIRST, BAG_LAST do
        local packNum = i - 22
        local slot = mq.TLO.Me.Inventory(i)
        if slot.Container() and slot.Container() > 0 then
            local bagLabel = string.format('%s (%d)', slot.Name() or 'Bag', packNum)
            for j = 1, slot.Container() do
                appendItem(rows, slot.Item(j), bagLabel, packNum, j)
            end
        else
            appendItem(rows, slot, 'Bag ' .. packNum, 0, i)
        end
    end
    table.sort(rows, function(a, b)
        local an, bn = a.name:lower(), b.name:lower()
        if an ~= bn then return an < bn end
        if (a.packNum or 0) ~= (b.packNum or 0) then return (a.packNum or 0) < (b.packNum or 0) end
        return (a.slotNum or 0) < (b.slotNum or 0)
    end)
    inventoryRows = rows
    return inventoryRows
end

function M.getInventoryRows()
    return inventoryRows
end

function M.buildInventoryQtyMap()
    M.scanInventory(false)
    local map = {}
    for _, row in ipairs(inventoryRows) do
        local qty = tonumber(row.qty) or 1
        local nameKey = row.nameKey or canonicalKey(row.name)
        map[nameKey] = (map[nameKey] or 0) + qty
        local norm = normalizeNameKey(row.name)
        if norm ~= nameKey then
            map[norm] = (map[norm] or 0) + qty
        end
    end
    return map
end

function M.getInventoryQty(name, qtyMap)
    qtyMap = qtyMap or M.buildInventoryQtyMap()
    local key = canonicalKey(name)
    if qtyMap[key] then return qtyMap[key] end
    return qtyMap[normalizeNameKey(name)] or 0
end

local function collectSellCandidates(iniPath)
    local lookup = M.buildRuleLookup(iniPath)
    M.scanInventory(true)
    local candidates = {}
    local skippedMain = 0
    local skippedZero = 0
    for _, row in ipairs(inventoryRows) do
        if M.readRule(lookup, row.name):upper() == 'SELL' then
            if not row.sellable then
                -- NoDrop/NoRent; skip silently
            elseif (row.packNum or 0) <= 0 then
                skippedMain = skippedMain + 1
            elseif (tonumber(row.value) or 0) <= 0 then
                skippedZero = skippedZero + 1
            else
                candidates[#candidates + 1] = row
            end
        end
    end
    return candidates, skippedMain, skippedZero
end

local function waitMerchantSelection(itemName, timeoutMs)
    itemName = tostring(itemName or '')
    timeoutMs = timeoutMs or 800
    local elapsed = 0
    while elapsed < timeoutMs do
        local label = mq.TLO.Window('MerchantWnd').Child('MW_SelectedItemLabel').Text() or ''
        if label == itemName then return true end
        mq.delay(10)
        mq.doevents()
        elapsed = elapsed + 10
    end
    return false
end

local function waitSlotCleared(packNum, slotNum, itemName, timeoutMs)
    timeoutMs = timeoutMs or 1500
    local elapsed = 0
    while elapsed < timeoutMs do
        local slotName = mq.TLO.Me.Inventory(22 + packNum).Item(slotNum).Name() or ''
        if slotName == '' or slotName == 'NULL' or slotName ~= itemName then return true end
        mq.delay(10)
        mq.doevents()
        elapsed = elapsed + 10
    end
    return false
end

local function sellBagSlot(row, iniPath, perItemAnnounce)
    if not mq.TLO.Window('MerchantWnd').Open() then return false, 0, 'merchant closed' end
    local packNum = row.packNum
    local slotNum = row.slotNum
    local itemName = row.name
    local stackCount = tonumber(row.qty) or 1

    if mq.TLO.Cursor.ID() then
        mq.cmd('/autoinventory')
        mq.delay(100)
    end

    mq.cmdf('/nomodkey /itemnotify in pack%d %d leftmouseup', packNum, slotNum)
    if mq.TLO.Window('QuantityWnd').Open() then
        mq.cmd('/notify QuantityWnd QTYW_Accept_Button leftmouseup')
        mq.delay(50)
    end
    mq.doevents()

    if not waitMerchantSelection(itemName, 500) then
        return false, 0, 'select failed'
    end

    local sellBtn = mq.TLO.Window('MerchantWnd').Child('MW_Sell_Button')
    if not sellBtn() or not sellBtn.Enabled() then
        return false, 0, 'sell disabled'
    end

    local before = copperTotal()
    mq.cmd('/nomodkey /shift /notify MerchantWnd MW_Sell_Button leftmouseup')
    if not waitSlotCleared(packNum, slotNum, itemName, 1200) then
        return false, 0, 'sell timeout'
    end

    local gained = copperTotal() - before
    if gained > 0 and perItemAnnounce then
        local link = M.resolveItemLink(itemName, row.itemId)
        if link == '' then link = itemName end
        announceBankSell(iniPath, string.format('%s \\ag[SELL]\\aw %s \\aw(x%d) \\awfor \\ag%s\\ag',
            TL_TAG, link, stackCount, formatCopper(gained)))
    end
    return true, gained, nil
end

function M.snapshotMerchant(force)
    local t = nowMs()
    if not force and not merchantSnapshotPending and (t - lastMerchantScanMs) < MERCHANT_SCAN_MIN_MS then
        return merchantRows
    end
    if not mq.TLO.Window('MerchantWnd').Open() then
        merchantRows = {}
        return merchantRows
    end
    if mq.TLO.Merchant.ItemsReceived() ~= true and not force then
        return merchantRows
    end
    if mq.TLO.Merchant.ItemsReceived() ~= true then return merchantRows end
    lastMerchantScanMs = t
    merchantSnapshotPending = false
    local rows = {}
    local count = mq.TLO.Merchant.Items() or 0
    for i = 1, count do
        local item = mq.TLO.Merchant.Item(i)
        if item and item.Name() and item.Name() ~= '' then
            local priceCopper = math.max(0, math.floor(tonumber(item.BuyPrice()) or 0))
            local stackable = false
            pcall(function()
                if item.Stackable and item.Stackable() then stackable = true end
            end)
            pcall(function()
                if (tonumber(item.StackSize and item.StackSize()) or 0) > 1 then stackable = true end
            end)
            rows[#rows + 1] = {
                index = i,
                key = canonicalKey(item.Name()),
                name = item.Name(),
                price = priceCopper / 1000,
                priceCopper = priceCopper,
                icon = item.Icon() or 500,
                itemId = item.ID() or 0,
                qty = item.MerchQuantity() and math.floor(item.MerchQuantity()) or -1,
                stackable = stackable,
            }
        end
    end
    table.sort(rows, function(a, b)
        return a.name:lower() < b.name:lower()
    end)
    merchantRows = rows
    return merchantRows
end

function M.getMerchantRows()
    return merchantRows
end

function M.merchantLoading()
    if not mq.TLO.Window('MerchantWnd').Open() then return false end
    return mq.TLO.Merchant.ItemsReceived() ~= true
end

function M.markMerchantOpened()
    merchantSnapshotPending = true
end

function M.tick(merchantOpen)
    if not merchantOpen then return end
    if merchantSnapshotPending and mq.TLO.Merchant.ItemsReceived() == true then
        M.snapshotMerchant(true)
    end
end

function M.readBuyWatch(iniPath)
    buyWatchNames = {}
    buyWatchKeys = {}
    if not iniPath or iniPath == '' or not readIniSectionPairs then
        return buyWatchNames
    end
    for _, pair in ipairs(readIniSectionPairs(iniPath, 'BuyWatch') or {}) do
        local name = tostring(pair.key or ''):match('^%s*(.-)%s*$') or ''
        local key = canonicalKey(name)
        if name ~= '' and key ~= '' and not buyWatchKeys[key] then
            buyWatchKeys[key] = name
            buyWatchNames[#buyWatchNames + 1] = name
        end
    end
    table.sort(buyWatchNames, function(a, b) return a:lower() < b:lower() end)
    return buyWatchNames
end

function M.isWatched(name)
    local key = canonicalKey(name)
    if buyWatchKeys[key] then return true end
    local norm = normalizeNameKey(name)
    for watchKey, _ in pairs(buyWatchKeys) do
        if normalizeNameKey(watchKey) == norm then return true end
    end
    return false
end

function M.getWatchedMerchantHits(iniPath)
    M.readBuyWatch(iniPath)
    M.snapshotMerchant(false)
    local hits = {}
    local seen = {}
    for _, row in ipairs(merchantRows) do
        if M.isWatched(row.name) then
            local key = canonicalKey(row.name)
            if not seen[key] then
                seen[key] = true
                hits[#hits + 1] = row.name
            end
        end
    end
    table.sort(hits, function(a, b) return a:lower() < b:lower() end)
    return hits
end

function M.getBuyWatchNames()
    return buyWatchNames
end

function M.addBuyWatch(iniPath, itemName)
    itemName = tostring(itemName or ''):match('^%s*(.-)%s*$') or ''
    if itemName == '' or not writeIniKey or not iniPath or iniPath == '' then return false end
    local ok = writeIniKey(iniPath, 'BuyWatch', itemName, '1')
    if ok then M.readBuyWatch(iniPath) end
    return ok
end

function M.removeBuyWatch(iniPath, itemName)
    itemName = tostring(itemName or ''):match('^%s*(.-)%s*$') or ''
    if itemName == '' or not iniPath or iniPath == '' then return false end
    local ok = false
    if deleteIniKey then
        ok = deleteIniKey(iniPath, 'BuyWatch', itemName) == true
    end
    if not ok and writeIniKey then
        ok = writeIniKey(iniPath, 'BuyWatch', itemName, '')
    end
    if ok then M.readBuyWatch(iniPath) end
    return ok
end

function M.applyRule(itemName, rule, iniPath)
    if not writeIniKey or not readIniKey then return false, 'INI helpers unavailable' end
    itemName = tostring(itemName or ''):match('^%s*(.-)%s*$') or ''
    rule = tostring(rule or ''):match('^%s*(.-)%s*$') or ''
    if itemName == '' or rule == '' then return false, 'Missing item or rule' end
    if not iniPath or iniPath == '' then return false, 'No target INI' end

    local oldVal = readIniKey(iniPath, 'ItemLimits', itemName)
    local ok = writeIniKey(iniPath, 'ItemLimits', itemName, rule)
    if not ok then return false, 'Failed to write INI' end

    M.invalidateRuleCache(iniPath)
    lastUndo = {
        itemName = itemName,
        rule = rule,
        oldVal = oldVal,
        iniPath = iniPath,
    }
    return true, string.format('%s = %s', itemName, rule)
end

function M.undoLast()
    if not lastUndo or not writeIniKey then return false, 'Nothing to undo' end
    local undo = lastUndo
    local ok
    if undo.oldVal ~= nil and undo.oldVal ~= '' then
        ok = writeIniKey(undo.iniPath, 'ItemLimits', undo.itemName, undo.oldVal)
    elseif deleteIniKey then
        ok = deleteIniKey(undo.iniPath, 'ItemLimits', undo.itemName)
    else
        ok = writeIniKey(undo.iniPath, 'ItemLimits', undo.itemName, '')
    end
    if ok then
        M.invalidateRuleCache(undo.iniPath)
        lastUndo = nil
        return true, 'Undo: restored ' .. undo.itemName
    end
    return false, 'Undo failed'
end

function M.getLastUndoLabel()
    if not lastUndo then return nil end
    return string.format('Undo %s: %s', tostring(lastUndo.rule or ''), tostring(lastUndo.itemName or ''))
end

function M.resolveIniPath(profileName)
    if not resolveTurbolootIniPathForProfile then return nil end
    profileName = cleanProfileName and cleanProfileName(profileName) or profileName
    return resolveTurbolootIniPathForProfile(profileName)
end

local function looksLikeItemLink(text)
    text = tostring(text or '')
    return text:find('\x12') ~= nil
end

function M.resolveItemLink(name, itemId)
    name = tostring(name or ''):match('^%s*(.-)%s*$') or ''
    if name == '' then return '' end

    local linkDB = mq.TLO.LinkDB
    if linkDB then
        local ok, link = pcall(function() return linkDB('=' .. name)() end)
        if ok and looksLikeItemLink(link) then return link end
    end

    local fi = mq.TLO.FindItem('=' .. name)
    if fi and fi() then
        local ok, link = pcall(function() return fi.ItemLink('CLICKABLE')() end)
        if ok and looksLikeItemLink(link) then return link end
    end

    if itemId and tonumber(itemId) and tonumber(itemId) > 0 then
        local spawn = mq.TLO.Spawn('=' .. name)
        if spawn and spawn() then
            -- no link from spawn; fall through
        end
    end

    return ''
end

function M.inspectItem(name, itemId)
    name = tostring(name or ''):match('^%s*(.-)%s*$') or ''
    if name == '' then return false, 'No item name' end
    local link = M.resolveItemLink(name, itemId)
    if link ~= '' then
        mq.cmd('/executelink ' .. link)
        return true, 'Inspecting ' .. name
    end
    return false, name .. ': no item link available'
end

function M.buyMerchantItem(name, qty, opts)
    opts = opts or {}
    if not mq.TLO.Window('MerchantWnd').Open() then return false end
    name = tostring(name or '')
    if name == '' then return false end
    mq.TLO.Merchant.SelectItem('=' .. name)
    mq.delay(50)
    mq.doevents()
    if opts.useQuantityWnd then
        mq.cmd('/shift /notify MerchantWnd MW_Buy_Button leftmouseup')
        announceWaresBuy(name, nil, opts.price, true, opts.priceCopper)
        return true
    end
    qty = math.max(1, math.floor(tonumber(qty) or 1))
    mq.TLO.Merchant.Buy(qty)
    announceWaresBuy(name, qty, opts.price, false, opts.priceCopper)
    return true
end

local function creditSaleToGains(totalCopper, itemsSold)
    totalCopper = tonumber(totalCopper) or 0
    itemsSold = tonumber(itemsSold) or 0
    if totalCopper <= 0 then return false end

    if creditGainsSale then
        local ok, credited = pcall(creditGainsSale, totalCopper, itemsSold)
        if ok and credited ~= false then return true end
    end

    local engine = rawget(_G, 'TurboGainsEngineM')
    if type(engine) == 'table' and type(engine.creditSale) == 'function' then
        local ok, credited = pcall(engine.creditSale, totalCopper, itemsSold, {
            source = 'wares',
            quiet = true,
        })
        if ok and credited ~= false then return true end
    end

    -- Do not fall back to /turbogains here. TurboWares should never launch or
    -- surface TurboGains just because a merchant sale completed.
    return false
end

function M.sellTaggedSummary(iniPath)
    local candidates, skippedMain, skippedZero = collectSellCandidates(iniPath)
    local totalCopper = 0
    local lines = {}
    for _, row in ipairs(candidates) do
        totalCopper = totalCopper + M.rowSellCopper(row)
        lines[#lines + 1] = formatSellStackEntry(row)
    end
    return {
        count = #candidates,
        totalCopper = totalCopper,
        skippedMain = skippedMain,
        skippedZero = skippedZero,
        lines = lines,
    }
end

function M.countSellTagged(iniPath)
    return M.sellTaggedSummary(iniPath).count
end

function M.sellTaggedNow(iniPath, profileName)
    if not mq.TLO.Window('MerchantWnd').Open() then
        return false, 'Open a merchant first'
    end

    local candidates, skippedMain, skippedZero = collectSellCandidates(iniPath)
    if #candidates == 0 then
        if skippedMain > 0 then
            return false, string.format('No bagged SELL items ready (%d on main slots — move to a bag)', skippedMain)
        end
        if skippedZero > 0 then
            return false, 'SELL-tagged items have zero vendor value'
        end
        return false, 'No sellable SELL-tagged items in bags'
    end

    local perItem = readIniBool(iniPath, 'Settings', 'announceBankSellPerItem', false)
    local estCopper = 0
    for _, row in ipairs(candidates) do
        estCopper = estCopper + M.rowSellCopper(row)
    end
    announceWaresSellStart(iniPath, candidates, estCopper)

    local itemsSold = 0
    local totalCopper = 0
    local failed = 0
    local soldLines = {}
    local failedKeys = {}
    local maxPasses = math.max(20, #candidates * 2)
    local pass = 0

    while pass < maxPasses do
        pass = pass + 1
        if not mq.TLO.Window('MerchantWnd').Open() then break end
        local batch = collectSellCandidates(iniPath)
        local row = nil
        for _, cand in ipairs(batch) do
            if not failedKeys[cand.key] then
                row = cand
                break
            end
        end
        if not row then break end
        local ok, gained = sellBagSlot(row, iniPath, perItem)
        if ok then
            itemsSold = itemsSold + 1
            totalCopper = totalCopper + math.max(0, gained or 0)
            soldLines[#soldLines + 1] = string.format('%s x%d = %s',
                row.name, tonumber(row.qty) or 1, formatCopper(gained or 0))
            failedKeys[row.key] = nil
        else
            failed = failed + 1
            failedKeys[row.key] = true
        end
        mq.doevents()
    end

    M.scanInventory(true)

    if itemsSold > 0 then
        announceWaresSellComplete(itemsSold, totalCopper, soldLines)
        announceWares(iniPath, string.format('\\aosell complete:\\ag %d stack%s for %s\\ag',
            itemsSold, itemsSold == 1 and '' or 's', formatCopper(totalCopper)))
        if totalCopper > 0 then
            creditSaleToGains(totalCopper, itemsSold)
        end
    else
        announceWares(iniPath, '\\aosell:\\aw no items were sold.')
    end

    if skippedMain > 0 then
        announceWares(iniPath, string.format('\\aonotice:\\aw %d SELL item%s on main inventory slots - move to a bag to sell.',
            skippedMain, skippedMain == 1 and '' or 's'))
    end
    if failed > 0 then
        announceWares(iniPath, string.format('\\aowarning:\\aw %d item%s could not be sold.', failed, failed == 1 and '' or 's'))
    end

    return itemsSold > 0,
        string.format('Sold %d stack%s for %s%s', itemsSold, itemsSold == 1 and '' or 's', formatCopper(totalCopper),
            mq.TLO.Window('MerchantWnd').Open() and ' (merchant still open)' or '')
end

function M.sellStackNow(row, iniPath)
    if not mq.TLO.Window('MerchantWnd').Open() then
        return false, 'Open a merchant first'
    end
    if type(row) ~= 'table' then return false, 'No bag item selected' end
    if row.sellable == false then return false, tostring(row.name or 'Item') .. ' is NoDrop/NoRent' end
    if (tonumber(row.packNum or 0) or 0) <= 0 then
        return false, 'Move ' .. tostring(row.name or 'item') .. ' into a bag to sell it'
    end
    if (tonumber(row.slotNum or 0) or 0) <= 0 then return false, 'No bag slot for selected item' end
    if (tonumber(row.value) or 0) <= 0 then
        return false, tostring(row.name or 'Item') .. ' has zero vendor value'
    end

    local perItem = readIniBool(iniPath, 'Settings', 'announceBankSellPerItem', false)
    local ok, gained, err = sellBagSlot(row, iniPath, perItem)
    M.scanInventory(true)
    if ok then
        if (tonumber(gained) or 0) > 0 then
            creditSaleToGains(tonumber(gained) or 0, 1)
        end
        return true, string.format('Sold %s x%d for %s',
            tostring(row.name or 'item'), tonumber(row.qty) or 1, formatCopper(gained or 0))
    end
    return false, string.format('Could not sell %s: %s', tostring(row.name or 'item'), tostring(err or 'unknown'))
end

--- Run queued SELL NOW / BUY NOW actions from Turbo's main loop (yieldable; not ImGui).
function M.processPendingActions(g)
    if not g then return end
    if not g.waresPendingSellNow and not g.waresPendingSellStackNow and not g.waresPendingBuyNow then return end

    if g.waresPendingSellNow then
        local pending = g.waresPendingSellNow
        g.waresPendingSellNow = nil
        g.waresSellInProgress = true
        local okRun, runErr = pcall(function()
            local sold, msg = M.sellTaggedNow(pending.iniPath, pending.profileName)
            g.statusMessage = msg
            if sold then M.scanInventory(true) end
        end)
        g.waresSellInProgress = false
        g._waresInvalidateSellCache = true
        if pending.restoreUi then
            for key, value in pairs(pending.restoreUi) do
                if value ~= nil and key ~= 'gainsWindowOpen' then g[key] = value end
            end
        end
        if not okRun then
            g.statusMessage = 'TurboWares sell error: ' .. tostring(runErr)
        end
    end

    if g.waresPendingSellStackNow then
        local pending = g.waresPendingSellStackNow
        g.waresPendingSellStackNow = nil
        local okRun, runErr = pcall(function()
            local sold, msg = M.sellStackNow(pending.row, pending.iniPath)
            g.statusMessage = msg
            if sold then M.scanInventory(true) end
        end)
        g._waresInvalidateSellCache = true
        if not okRun then
            g.statusMessage = 'TurboWares stack sell error: ' .. tostring(runErr)
        end
    end

    if g.waresPendingBuyNow then
        local pending = g.waresPendingBuyNow
        g.waresPendingBuyNow = nil
        local okRun, runErr = pcall(function()
            local ok = M.buyMerchantItem(pending.name, pending.qty, {
                useQuantityWnd = pending.useQuantityWnd == true,
                price = pending.price,
                priceCopper = pending.priceCopper,
            })
            if ok then
                g.statusMessage = pending.useQuantityWnd
                    and ('TurboWares: quantity window opened for ' .. tostring(pending.name or ''))
                    or ('TurboWares: bought ' .. tostring(pending.name or ''))
                M.snapshotMerchant(true)
                g._waresInvalidateMerchantCache = true
            else
                g.statusMessage = 'TurboWares: could not buy ' .. tostring(pending.name or '')
            end
        end)
        if not okRun then
            g.statusMessage = 'TurboWares buy error: ' .. tostring(runErr)
        end
    end
end

return M
