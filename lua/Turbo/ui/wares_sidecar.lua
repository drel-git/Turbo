--[[
  TurboWares - docked merchant sidecar (Turbo-themed ImGui merchant window)
  @version lua/Turbo/ui/wares_sidecar.lua 1.7.3
  Draws only while MerchantWnd is open and Turbo hub is running
]]

local mq = require('mq')
local ImGui = require('ImGui')
local Wares = require('Turbo.wares')

local M = {}

local Ui, Theme, TurboKeyRGB
local writeIniKey, readIniKey, readIniSectionPairs, deleteIniKey
local resolveTurbolootIniPathForProfile, cleanProfileName, shellOpenFile, getActiveProfile
local openAllaItemPage
local saveSettings
local canSharedControlWrite, requireSharedControl
local ACTION_BTN_H = 24

local sellCountCache = { ini = '', count = 0, totalCopper = 0, skippedMain = 0, skippedZero = 0, lines = {}, at = 0 }
local waresCache = {
    tickAt = 0,
    iniSigPath = '',
    iniSig = nil,
    iniSigAt = 0,
    watchIni = '',
    watchAt = 0,
    watchHitsIni = '',
    watchHitsAt = 0,
    watchHits = {},
    merchantAt = 0,
    merchantRows = nil,
    invAt = 0,
    invRows = nil,
    qtyAt = 0,
    qtyMap = nil,
}

local TICK_TTL_MS = 500
local WATCH_TTL_MS = 1500
local MERCHANT_TTL_MS = 1000
local INV_TTL_MS = 1500
local INI_SIG_TTL_MS = 1500

local SORT_COL_ITEM = 1
local SORT_COL_RULE = 2
local SORT_COL_QTY = 3
local SORT_COL_PRICE = 4
local SORT_COL_HAVE = 7
local SORT_COL_VALUE = 8

local animItems
local setupDone = false
local merchantWasOpen = false
local lastWatchAlertKey = nil

local function contentAvail()
    local w, h = ImGui.GetContentRegionAvail()
    if type(w) == 'table' then
        return tonumber(w.x or w.X or w[1]) or 0, tonumber(w.y or w.Y or w[2]) or 0
    end
    return tonumber(w) or 0, tonumber(h) or 0
end

local function nowMs()
    local ok, v = pcall(mq.gettime)
    if ok and tonumber(v) then return tonumber(v) end
    return math.floor(os.clock() * 1000)
end

local function invalidateWaresCaches(g, what)
    what = tostring(what or 'all')
    if what == 'all' or what == 'watch' then
        waresCache.watchAt = 0
        waresCache.watchHitsAt = 0
    end
    if what == 'all' or what == 'merchant' then
        waresCache.merchantAt = 0
        waresCache.watchHitsAt = 0
        if g then g._waresMerchRows = nil end
    end
    if what == 'all' or what == 'inventory' then
        waresCache.invAt = 0
        waresCache.qtyAt = 0
        if g then
            g._waresInvRows = nil
            g._waresQtyMap = nil
        end
    end
end

local function cachedReadBuyWatch(iniPath, force)
    local t = nowMs()
    if force or waresCache.watchIni ~= tostring(iniPath or '') or (t - (waresCache.watchAt or 0)) >= WATCH_TTL_MS then
        Wares.readBuyWatch(iniPath)
        waresCache.watchIni = tostring(iniPath or '')
        waresCache.watchAt = t
        waresCache.watchHitsAt = 0
    end
    return Wares.getBuyWatchNames()
end

local function cachedMerchantRows(g, force)
    local t = nowMs()
    if force or not waresCache.merchantRows or (t - (waresCache.merchantAt or 0)) >= MERCHANT_TTL_MS then
        waresCache.merchantRows = Wares.snapshotMerchant(force == true)
        waresCache.merchantAt = t
        if g then g._waresMerchRows = waresCache.merchantRows end
    end
    return waresCache.merchantRows or {}
end

local function cachedInventoryRows(g, force)
    local t = nowMs()
    if force or not waresCache.invRows or (t - (waresCache.invAt or 0)) >= INV_TTL_MS then
        waresCache.invRows = Wares.scanInventory(force == true)
        waresCache.invAt = t
        if g then g._waresInvRows = waresCache.invRows end
    end
    return waresCache.invRows or {}
end

local function syncInventoryRowsFromWares(g)
    waresCache.invRows = Wares.getInventoryRows()
    waresCache.invAt = nowMs()
    if g then g._waresInvRows = waresCache.invRows end
    return waresCache.invRows or {}
end

local function cachedQtyMap(g, force)
    local t = nowMs()
    if force or not waresCache.qtyMap or (t - (waresCache.qtyAt or 0)) >= INV_TTL_MS then
        waresCache.qtyMap = Wares.buildInventoryQtyMap()
        waresCache.qtyAt = t
        if g then g._waresQtyMap = waresCache.qtyMap end
    end
    return waresCache.qtyMap or {}
end

local function cachedWatchedMerchantHits(g, iniPath, force)
    local t = nowMs()
    if force or waresCache.watchHitsIni ~= tostring(iniPath or '') or (t - (waresCache.watchHitsAt or 0)) >= WATCH_TTL_MS then
        cachedReadBuyWatch(iniPath, force)
        cachedMerchantRows(g, force)
        waresCache.watchHits = Wares.getWatchedMerchantHits(iniPath)
        waresCache.watchHitsIni = tostring(iniPath or '')
        waresCache.watchHitsAt = t
    end
    return waresCache.watchHits or {}
end

local function tickWaresThrottled(force)
    local t = nowMs()
    if force or (t - (waresCache.tickAt or 0)) >= TICK_TTL_MS then
        Wares.tick(true)
        waresCache.tickAt = t
        if force then waresCache.merchantAt = 0 end
    end
end

local function tip(text)
    if not text or text == '' then return end
    if Ui and Ui.tooltip then Ui.tooltip(text) end
end

local function canWriteSharedRule(actionName)
    if type(canSharedControlWrite) == 'function' and canSharedControlWrite() == false then
        if type(requireSharedControl) == 'function' then
            return requireSharedControl(actionName or 'TurboWares rule edit')
        end
        return false
    end
    return true
end

local function hasSharedRuleWrite()
    return not (type(canSharedControlWrite) == 'function' and canSharedControlWrite() == false)
end

local function pushWindowStyle()
    ImGui.PushStyleColor(ImGuiCol.WindowBg, IM_COL32(8, 10, 14, 252))
    ImGui.PushStyleColor(ImGuiCol.ChildBg, IM_COL32(10, 12, 17, 255))
    ImGui.PushStyleColor(ImGuiCol.TitleBg, IM_COL32(20, 28, 41, 255))
    ImGui.PushStyleColor(ImGuiCol.TitleBgActive, IM_COL32(26, 36, 51, 255))
    ImGui.PushStyleColor(ImGuiCol.Border, IM_COL32(184, 143, 61, 230))
    ImGui.PushStyleVar(ImGuiStyleVar.WindowRounding, 5)
    ImGui.PushStyleVar(ImGuiStyleVar.WindowBorderSize, 2)
    ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 4)
    ImGui.PushStyleVar(ImGuiStyleVar.PopupRounding, 4)
end

local function popWindowStyle()
    ImGui.PopStyleVar(4)
    ImGui.PopStyleColor(5)
end

local function pushIniComboStyle()
    ImGui.PushStyleColor(ImGuiCol.FrameBg, IM_COL32(14, 18, 26, 255))
    ImGui.PushStyleColor(ImGuiCol.FrameBgHovered, IM_COL32(22, 30, 44, 255))
    ImGui.PushStyleColor(ImGuiCol.FrameBgActive, IM_COL32(28, 40, 58, 255))
end

local function popIniComboStyle()
    ImGui.PopStyleColor(3)
end

local function pushTabBarStyle()
    ImGui.PushStyleColor(ImGuiCol.Tab, IM_COL32(16, 20, 28, 255))
    ImGui.PushStyleColor(ImGuiCol.TabHovered, IM_COL32(28, 36, 50, 255))
    ImGui.PushStyleColor(ImGuiCol.TabActive, IM_COL32(38, 72, 52, 255))
    ImGui.PushStyleColor(ImGuiCol.TabUnfocused, IM_COL32(12, 14, 20, 255))
    ImGui.PushStyleColor(ImGuiCol.TabUnfocusedActive, IM_COL32(32, 58, 44, 255))
end

local function popTabBarStyle()
    ImGui.PopStyleColor(5)
end

local function drawIcon(iconId, w, h)
    if not animItems then return end
    animItems:SetTextureCell((tonumber(iconId) or 500) - 500)
    ImGui.DrawTextureAnimation(animItems, w or 18, h or 18)
end

local function ruleDisplayText(rule)
    rule = tostring(rule or '')
    if rule == '' then return '-' end
    return rule
end

local function canonicalKey(name)
    return tostring(name or ''):lower():match('^%s*(.-)%s*$') or ''
end

local function resolveTargetProfile(g)
    if g.waresIniTargetOverride and g.waresIniTargetOverride ~= '' then
        return cleanProfileName(g.waresIniTargetOverride) or g.waresIniTargetOverride
    end
    if getActiveProfile then
        return cleanProfileName(getActiveProfile()) or 'turboloot.ini'
    end
    return 'turboloot.ini'
end

local function resolveTargetIniPath(g)
    local prof = resolveTargetProfile(g)
    local path = Wares.resolveIniPath(prof)
    g.waresIniTargetPath = path
    g.waresIniTargetProfile = prof
    return path, prof
end

local function invalidateSellCountCache()
    sellCountCache.at = 0
end

local lfsProbe = { tried = false, mod = nil }

local function fileSignature(path)
    path = tostring(path or '')
    if path == '' then return nil end
    if not lfsProbe.tried then
        lfsProbe.tried = true
        local ok, lfs = pcall(require, 'lfs')
        if ok and lfs and lfs.attributes then
            lfsProbe.mod = lfs
        end
    end
    if lfsProbe.mod then
        local ok, mod, size = pcall(function()
            local attr = lfsProbe.mod.attributes(path)
            if type(attr) ~= 'table' then return nil, nil end
            return attr.modification, attr.size
        end)
        if ok and (mod or size) then
            return tostring(mod or 0) .. ':' .. tostring(size or 0)
        end
    end
    local fh = io.open(path, 'rb')
    if not fh then return nil end
    local size = fh:seek('end') or 0
    fh:close()
    return 'size:' .. tostring(size)
end

local function rememberIniSignature(iniPath)
    waresCache.iniSigPath = tostring(iniPath or '')
    waresCache.iniSig = fileSignature(iniPath)
    waresCache.iniSigAt = nowMs()
end

local function refreshIniRules(g, iniPath, statusMessage)
    Wares.invalidateRuleCache(iniPath)
    invalidateSellCountCache()
    invalidateWaresCaches(g, 'watch')
    cachedReadBuyWatch(iniPath, true)
    rememberIniSignature(iniPath)
    if g and statusMessage and statusMessage ~= '' then
        g.statusMessage = statusMessage
    end
end

local function maybeRefreshExternalIni(g, iniPath)
    iniPath = tostring(iniPath or '')
    if iniPath == '' then return end
    local t = nowMs()
    if waresCache.iniSigPath ~= iniPath then
        refreshIniRules(g, iniPath)
        return
    end
    if (t - (waresCache.iniSigAt or 0)) < INI_SIG_TTL_MS then return end
    waresCache.iniSigAt = t
    local sig = fileSignature(iniPath)
    if sig and waresCache.iniSig and sig ~= waresCache.iniSig then
        Wares.invalidateRuleCache(iniPath)
        invalidateSellCountCache()
        invalidateWaresCaches(g, 'watch')
        cachedReadBuyWatch(iniPath, true)
        if g then
            g._waresInvalidateSellCache = nil
            g.statusMessage = 'TurboWares: target INI changed, reloaded rules.'
        end
    end
    waresCache.iniSig = sig
end

local function onIniTargetChanged(g, name, path)
    g.waresIniTargetOverride = name
    g.waresIniTargetPath = path
    g.waresSelectedKey = nil
    g.waresMerchantSelectedKey = nil
    invalidateWaresCaches(g, 'all')
    refreshIniRules(g, path, string.format('TurboWares target INI: %s', tostring(name or '')))
    if saveSettings then saveSettings() end
end

local function onIniFollowActive(g)
    g.waresIniTargetOverride = nil
    g.waresSelectedKey = nil
    g.waresMerchantSelectedKey = nil
    local activeProf = resolveTargetProfile(g)
    local activePath = Wares.resolveIniPath(activeProf)
    invalidateWaresCaches(g, 'all')
    refreshIniRules(g, activePath, 'TurboWares following active INI: ' .. tostring(activeProf))
    if saveSettings then saveSettings() end
end

local queueSellTaggedNow, queueSellStackNow, queueBuyMerchantNow
local cachedSellSummary, buildSellNowTooltip, resolveMerchantSelectedRow

local function merchantUsesQuantityWindow(row, qty)
    if type(row) ~= 'table' then return false end
    if row.stackable == true then return true end
    qty = math.max(1, math.floor(tonumber(qty) or 1))
    if qty > 1 then return true end
    local stock = tonumber(row.qty) or -1
    return stock > 1
end

local function drawIniHeader(g)
    local iniPath, prof = resolveTargetIniPath(g)
    if not iniPath or iniPath == '' then
        ImGui.TextColored(0.95, 0.45, 0.38, 1.0, 'Target INI path not found for ' .. tostring(prof or '?'))
    end

    ImGui.TextColored(0.48, 0.76, 1.0, 1.0, 'Target INI')
    ImGui.Dummy(0, 2)
    local avail = contentAvail()
    local openBtnW = 58
    local resetBtnW = 52
    pushIniComboStyle()
    ImGui.PushItemWidth(math.max(160, avail - openBtnW - resetBtnW - 12))
    local profiles = g.profileList or {}
    if #profiles == 0 then profiles = { prof or 'turboloot.ini' } end
    local preview = prof or 'turboloot.ini'
    local pendingIniChange = nil
    if ImGui.BeginCombo('##wares_target_ini', preview) then
        local okCombo, comboErr = pcall(function()
            local seen = {}
            local function addProfile(p)
                local name = cleanProfileName and cleanProfileName(p) or p
                if not name or name == '' then return end
                local key = name:lower()
                if seen[key] then return end
                seen[key] = true
                if ImGui.Selectable(name .. '##wares_ini_' .. key, preview:lower() == key) then
                    local path = Wares.resolveIniPath(name)
                    pendingIniChange = function() onIniTargetChanged(g, name, path) end
                end
            end
            addProfile(preview)
            for _, p in ipairs(profiles) do addProfile(p) end
            if g.waresIniTargetOverride and g.waresIniTargetOverride ~= '' then
                ImGui.Separator()
                if ImGui.Selectable('Follow active INI##wares_ini_active', false) then
                    pendingIniChange = function() onIniFollowActive(g) end
                end
            end
        end)
        ImGui.EndCombo()
        if not okCombo then
            g.statusMessage = 'TurboWares INI combo error: ' .. tostring(comboErr)
        end
    end
    if pendingIniChange then
        local okApply, applyErr = pcall(pendingIniChange)
        if not okApply then
            g.statusMessage = 'TurboWares INI change error: ' .. tostring(applyErr)
        end
    end
    ImGui.PopItemWidth()
    popIniComboStyle()
    ImGui.SameLine()
    if Ui.buttonVariant('Open##wares_open_ini', 'secondaryButton', openBtnW, ACTION_BTN_H) then
        if iniPath and iniPath ~= '' and shellOpenFile then
            shellOpenFile(iniPath)
        else
            g.statusMessage = 'No INI path for ' .. tostring(prof or '?')
        end
    end
    tip('Rules and BuyWatch write to this turboloot INI.')
end

local function drawRuleBar(g, selectedName, iniPath)
    if not iniPath or iniPath == '' then
        ImGui.TextColored(0.95, 0.45, 0.38, 1.0, 'Pick a valid target INI before applying rules.')
        return
    end

    local TK = TurboKeyRGB or (Theme and Theme.col and Theme.col.turboKeyRGB) or {}
    local row1 = { 'KEEP', 'SELL', 'BANK', 'TRIBUTE' }
    local row2 = { 'DESTROY', 'IGNORE', 'ANNOUNCE' }
    local colors = {
        KEEP = TK.keep or { 70, 100, 150 },
        SELL = TK.sell or { 60, 120, 80 },
        BANK = TK.bank or TK.trade or { 90, 82, 130 },
        TRIBUTE = TK.tribute or { 130, 95, 35 },
        DESTROY = TK.destroy or { 145, 60, 55 },
        IGNORE = TK.skip or { 55, 58, 65 },
        ANNOUNCE = TK.announce or { 55, 130, 140 },
    }
    local hasTarget = selectedName and selectedName ~= ''
    local canWrite = hasSharedRuleWrite()
    if hasTarget then
        local detail = 'Selected: ' .. selectedName
        if g.waresTab == 'merchant' then
            detail = detail .. ' - BUY NOW uses Qty ' .. tostring(math.max(1, math.floor(tonumber(g.waresBuyQty) or 1)))
        elseif g.waresTab == 'items' then
            detail = detail .. ' - rule buttons tag this item'
        end
        ImGui.TextColored(0.62, 0.70, 0.82, 1.0, detail)
    else
        ImGui.TextDisabled('Selected: none - click a row to tag')
    end
    ImGui.Dummy(0, 2)

    local function drawRuleRow(labels)
        local avail = contentAvail()
        local sp = math.max(ImGui.GetStyle().ItemSpacing.x, 4)
        local btnW = math.max(58, math.floor((avail - sp * (#labels - 1)) / #labels))
        for i, lab in ipairs(labels) do
            if i > 1 then ImGui.SameLine(0, sp) end
            if not hasTarget or not canWrite then ImGui.BeginDisabled() end
            if Ui.buttonRgb(lab .. '##wares_rule_' .. lab, colors[lab], btnW, ACTION_BTN_H) then
                if canWriteSharedRule('TurboWares rule edit') then
                    local ok, msg = Wares.applyRule(selectedName, lab, iniPath)
                    g.statusMessage = ok and ('TurboWares: ' .. msg) or ('TurboWares: ' .. tostring(msg))
                    if ok then
                        refreshIniRules(g, iniPath)
                    else
                        invalidateSellCountCache()
                    end
                end
            end
            if not hasTarget or not canWrite then ImGui.EndDisabled() end
            tip((not canWrite) and 'Take Turbo control to edit shared INI rules.'
                or (hasTarget and ('Apply ' .. lab .. ' to ' .. selectedName) or 'Select an item first.'))
        end
    end

    drawRuleRow(row1)
    ImGui.Dummy(0, 2)
    drawRuleRow(row2)

    local undoLabel = Wares.getLastUndoLabel()
    if undoLabel then
        ImGui.Dummy(0, 3)
        local avail = contentAvail()
        if not canWrite then ImGui.BeginDisabled() end
        if Ui.buttonVariant(Ui.fitLabel(undoLabel .. '##wares_undo', undoLabel, avail), 'secondaryButton', avail, ACTION_BTN_H) then
            if canWriteSharedRule('TurboWares undo') then
                local ok, msg = Wares.undoLast()
                g.statusMessage = ok and msg or tostring(msg)
                if ok then
                    refreshIniRules(g, iniPath)
                end
            end
        end
        if not canWrite then ImGui.EndDisabled() end
        tip(canWrite and 'Undo the last TurboWares rule edit.' or 'Take Turbo control to undo shared INI edits.')
    end
end

local function childNoScrollFlags()
    if ImGuiWindowFlags and ImGuiWindowFlags.NoScrollbar then
        return ImGuiWindowFlags.NoScrollbar
    end
    return 0
end

local function ruleFooterHeight()
    local sp = math.max(ImGui.GetStyle().ItemSpacing.y, 4)
    local frameH = math.max(ACTION_BTN_H, (ImGui.GetFrameHeight and ImGui.GetFrameHeight()) or ACTION_BTN_H)
    local textH = (ImGui.GetTextLineHeight and ImGui.GetTextLineHeight()) or 18
    local pad = ((ImGui.GetStyle().WindowPadding and ImGui.GetStyle().WindowPadding.y) or 4) * 2
    local h = textH + sp + frameH + sp + frameH + sp + pad + 16
    if Wares.getLastUndoLabel() then
        h = h + sp + frameH
    end
    return math.ceil(h)
end

local function windowRuleBarReserve()
    return ruleFooterHeight() + 12
end

local function tabUsesRuleBar(tab)
    return tab == 'items' or tab == 'merchant'
end

local function tabBodyHeight(g)
    local _, h = contentAvail()
    if tabUsesRuleBar(g.waresTab) then
        return math.max(80, h - windowRuleBarReserve())
    end
    return h
end

local function beginTabBody(id, g)
    ImGui.BeginChild(id, 0, tabBodyHeight(g), false, childNoScrollFlags())
end

local function endTabBody()
    ImGui.EndChild()
end

local function runTabBody(g, bodyId, drawFn)
    beginTabBody(bodyId, g)
    local ok, err = pcall(drawFn)
    endTabBody()
    if not ok then error(err) end
end

buildSellNowTooltip = function(iniPath, g)
    local count, totalCopper, skippedMain, skippedZero = cachedSellSummary(iniPath, g)
    if count <= 0 then
        local emptyLines = { 'No bagged SELL items are ready to sell.' }
        if skippedMain > 0 then
            emptyLines[#emptyLines + 1] = string.format('%d SELL item(s) are on top-level inventory slots. Move them into a bag to sell.',
                skippedMain)
        end
        if skippedZero > 0 then
            emptyLines[#emptyLines + 1] = string.format('%d SELL item(s) have zero vendor value.', skippedZero)
        end
        return table.concat(emptyLines, '\n')
    end
    local lines = {
        'Runs TurboLoot sell for all bag items tagged SELL in this target INI.',
        string.format('%d SELL stack(s), ~%s est. total (%s)',
            count,
            Wares.formatCompactCopper(totalCopper),
            Wares.formatCopperLong(totalCopper)),
        'Actual totals may vary slightly at the merchant.',
        '',
    }
    if skippedMain > 0 then
        lines[#lines + 1] = string.format('%d SELL item(s) are on top-level inventory slots and will be skipped until moved into a bag.',
            skippedMain)
    end
    if skippedZero > 0 then
        lines[#lines + 1] = string.format('%d SELL item(s) have zero vendor value and will be skipped.',
            skippedZero)
    end
    if #lines > 4 then lines[#lines + 1] = '' end
    for _, line in ipairs(sellCountCache.lines or {}) do
        lines[#lines + 1] = '  ' .. line
    end
    return table.concat(lines, '\n')
end

local BAG_RULE_CHIPS = {
    { id = 'all', label = 'All' },
    { id = 'sell', label = 'SELL' },
    { id = 'unruled', label = 'Unruled' },
    { id = 'keep', label = 'KEEP' },
    { id = 'bank', label = 'BANK' },
    { id = 'tribute', label = 'TRIBUTE' },
}

local MERCHANT_RULE_CHIPS = {
    { id = 'all', label = 'All' },
    { id = 'watched', label = 'Watched' },
    { id = 'sell', label = 'SELL' },
    { id = 'unruled', label = 'Unruled' },
    { id = 'keep', label = 'KEEP' },
    { id = 'bank', label = 'BANK' },
    { id = 'tribute', label = 'TRIBUTE' },
}

local function rowPassesRuleFilter(g, lookup, row, filterField)
    local filter = g[filterField or 'waresRuleFilter'] or 'all'
    if filter == 'all' then return true end
    if filter == 'watched' then return Wares.isWatched(row.name) end
    local rule = Wares.readRule(lookup, row.name):upper()
    if filter == 'sell' then return rule == 'SELL' end
    if filter == 'unruled' then return rule == '' end
    if filter == 'keep' then return rule == 'KEEP' end
    if filter == 'bank' then return rule == 'BANK' end
    if filter == 'tribute' then return rule == 'TRIBUTE' end
    return true
end

local function drawRuleFilterChips(g, filterField, chips)
    ImGui.TextColored(0.55, 0.60, 0.68, 1.0, 'Rule')
    ImGui.SameLine(0, 6)
    filterField = filterField or 'waresRuleFilter'
    g[filterField] = g[filterField] or 'all'
    chips = chips or BAG_RULE_CHIPS
    for i, chip in ipairs(chips) do
        if i > 1 then ImGui.SameLine(0, 4) end
        local active = g[filterField] == chip.id
        local variant = 'secondaryButton'
        if active then
            variant = chip.id == 'watched' and 'successButton' or 'primaryButton'
        end
        if Ui.buttonVariant(chip.label .. '##wares_rf_' .. filterField .. '_' .. chip.id, variant, 0, ACTION_BTN_H) then
            g[filterField] = chip.id
        end
    end
    ImGui.Dummy(0, 2)
end

cachedSellSummary = function(iniPath, g)
    if g and g._waresInvalidateSellCache then
        invalidateSellCountCache()
        g._waresInvalidateSellCache = nil
    end
    local t = mq.gettime()
    iniPath = tostring(iniPath or '')
    if sellCountCache.ini ~= iniPath or t - sellCountCache.at > 2000 then
        local summary = Wares.sellTaggedSummary(iniPath)
        sellCountCache.count = summary.count or 0
        sellCountCache.totalCopper = summary.totalCopper or 0
        sellCountCache.skippedMain = summary.skippedMain or 0
        sellCountCache.skippedZero = summary.skippedZero or 0
        sellCountCache.lines = summary.lines or {}
        sellCountCache.ini = iniPath
        sellCountCache.at = t
        syncInventoryRowsFromWares(g)
    end
    return sellCountCache.count, sellCountCache.totalCopper, sellCountCache.skippedMain or 0, sellCountCache.skippedZero or 0
end

local function beginScrollList(id)
    local _, availH = contentAvail()
    ImGui.BeginChild(id, 0, math.max(48, availH - 4), true, childNoScrollFlags())
end

local function endScrollList()
    ImGui.EndChild()
end

local function beginFullList(id)
    local _, availH = contentAvail()
    ImGui.BeginChild(id, 0, math.max(48, availH - 4), true, childNoScrollFlags())
end

local function endFullList()
    ImGui.EndChild()
end

local function tableFlags()
    local stretch = ImGuiTableFlags.SizingStretchProp or ImGuiTableFlags.SizingStretchSame
    return bit32.bor(
        ImGuiTableFlags.Resizable,
        ImGuiTableFlags.Borders,
        ImGuiTableFlags.RowBg,
        ImGuiTableFlags.ScrollY,
        ImGuiTableFlags.Sortable,
        stretch)
end

local function sortFilteredRows(rows, sortSpecs, lookup)
    if not sortSpecs or #rows < 2 then return end
    local specCount = tonumber(sortSpecs.SpecsCount) or 0
    if specCount <= 0 then return end
    table.sort(rows, function(a, b)
        for n = 1, specCount do
            local spec = sortSpecs:Specs(n)
            if not spec then break end
            local uid = spec.ColumnUserID
            local delta = 0
            if uid == SORT_COL_ITEM then
                local an, bn = a.name:lower(), b.name:lower()
                if an < bn then delta = -1 elseif bn < an then delta = 1 end
            elseif uid == SORT_COL_RULE then
                local ar = Wares.readRule(lookup, a.name):lower()
                local br = Wares.readRule(lookup, b.name):lower()
                if ar < br then delta = -1 elseif br < ar then delta = 1 end
            elseif uid == SORT_COL_QTY then
                delta = (tonumber(a.qty) or 0) - (tonumber(b.qty) or 0)
            elseif uid == SORT_COL_PRICE then
                delta = (tonumber(a.price) or 0) - (tonumber(b.price) or 0)
            elseif uid == SORT_COL_VALUE then
                delta = Wares.rowSellCopper(a) - Wares.rowSellCopper(b)
            end
            if delta ~= 0 then
                if ImGuiSortDirection and spec.SortDirection == ImGuiSortDirection.Ascending then
                    return delta < 0
                end
                return delta > 0
            end
        end
        return a.name:lower() < b.name:lower()
    end)
    if sortSpecs.SpecsDirty then sortSpecs.SpecsDirty = false end
end

queueSellTaggedNow = function(g, iniPath)
    g.waresPendingSellNow = {
        iniPath = iniPath,
        profileName = resolveTargetProfile(g),
        restoreUi = {
            windowOpen = g.windowOpen,
            minimizedGUI = g.minimizedGUI,
            slimGUI = g.slimGUI,
            slimWhenExpanded = g.slimWhenExpanded,
        },
    }
    g.statusMessage = 'TurboWares: selling tagged items...'
end

queueSellStackNow = function(g, row, iniPath)
    if type(row) ~= 'table' then return end
    g.waresPendingSellStackNow = {
        iniPath = iniPath,
        row = {
            key = row.key,
            name = row.name,
            qty = row.qty,
            itemId = row.itemId,
            sellable = row.sellable,
            packNum = row.packNum,
            slotNum = row.slotNum,
            value = row.value,
        },
    }
    g.statusMessage = 'TurboWares: selling ' .. tostring(row.name or 'item') .. '...'
end

queueBuyMerchantNow = function(g, row, qty, useQuantityWnd)
    if type(row) ~= 'table' then return end
    local unitCopper = tonumber(row.priceCopper) or math.floor(((tonumber(row.price) or 0) * 1000) + 0.5)
    g.waresPendingBuyNow = {
        name = row.name,
        qty = qty,
        useQuantityWnd = useQuantityWnd == true,
        price = row.price,
        priceCopper = unitCopper,
    }
    g.statusMessage = useQuantityWnd
        and ('TurboWares: opening quantity window for ' .. tostring(row.name or 'item') .. '...')
        or ('TurboWares: buying ' .. tostring(row.name or 'item') .. '...')
end

local function drawItemContextMenu(g, ctx)
    if not ImGui.BeginPopupContextItem('##wares_ctx_' .. tostring(ctx.popupId)) then return end
    ImGui.Text(tostring(ctx.name or ''))
    ImGui.Separator()
    if ctx.kind == 'bag' then
        local canSellStack = ctx.sellable ~= false
            and (tonumber(ctx.packNum or 0) or 0) > 0
            and (tonumber(ctx.slotNum or 0) or 0) > 0
            and (tonumber(ctx.value) or 0) > 0
        if Ui.menuItem('Sell this stack now##wares_ctx_sell_stack_' .. ctx.popupId, function()
            queueSellStackNow(g, ctx, ctx.iniPath)
        end, canSellStack) then end
        if Ui.menuItem('Tag SELL##wares_ctx_tag_sell_' .. ctx.popupId, function()
            if canWriteSharedRule('TurboWares rule edit') then
                local ok, msg = Wares.applyRule(ctx.name, 'SELL', ctx.iniPath)
                g.statusMessage = ok and ('TurboWares: ' .. msg) or ('TurboWares: ' .. tostring(msg))
                if ok then refreshIniRules(g, ctx.iniPath) end
            end
        end, hasSharedRuleWrite()) then end
        ImGui.Separator()
    elseif ctx.kind == 'merchant' then
        local qty = math.max(1, math.floor(tonumber(g.waresBuyQty) or 1))
        local unitCopper = tonumber(ctx.priceCopper) or math.floor(((tonumber(ctx.price) or 0) * 1000) + 0.5)
        local totalText = Wares.formatCompactPriceCopper(unitCopper * qty)
        if Ui.menuItem(string.format('Buy now x%d (~%s)##wares_ctx_buy_now_%s', qty, totalText, ctx.popupId), function()
            queueBuyMerchantNow(g, ctx, qty, merchantUsesQuantityWindow(ctx, qty))
        end, true) then end
        local stock = tonumber(ctx.qty) or -1
        if Ui.menuItem(stock > 0
            and string.format('Buy stack x%d##wares_ctx_buy_stack_%s', stock, ctx.popupId)
            or ('Buy stack##wares_ctx_buy_stack_' .. ctx.popupId), function()
            queueBuyMerchantNow(g, ctx, stock, false)
        end, stock > 0) then end
        ImGui.Separator()
    end
    local canWriteRules = hasSharedRuleWrite()
    if not canWriteRules then ImGui.BeginDisabled() end
    if ImGui.BeginMenu('Set TurboLoot Rule##wares_ctx_rule_' .. tostring(ctx.popupId)) then
        for _, lab in ipairs(Wares.RULE_LABELS or {}) do
            if ImGui.MenuItem(lab .. '##wares_ctx_rule_' .. lab .. '_' .. tostring(ctx.popupId)) then
                if canWriteSharedRule('TurboWares rule edit') then
                    local ok, msg = Wares.applyRule(ctx.name, lab, ctx.iniPath)
                    g.statusMessage = ok and ('TurboWares: ' .. msg) or ('TurboWares: ' .. tostring(msg))
                    if ok then refreshIniRules(g, ctx.iniPath) end
                end
            end
        end
        ImGui.EndMenu()
    end
    if not canWriteRules then ImGui.EndDisabled() end
    ImGui.Separator()
    if Ui.menuItem('Inspect##wares_ctx_inspect_' .. ctx.popupId, function()
        local ok, msg = Wares.inspectItem(ctx.name, ctx.itemId)
        g.statusMessage = msg
    end) then end
    local validItemId = tonumber(ctx.itemId) ~= nil and tonumber(ctx.itemId) > 0
    if Ui.menuItem('Alla##wares_ctx_alla_' .. ctx.popupId, function()
        if openAllaItemPage then openAllaItemPage(ctx.itemId)
        else g.statusMessage = 'Alla opener not available' end
    end, validItemId) then end
    if Wares.isWatched(ctx.name) then
        if Ui.menuItem('Unwatch##wares_ctx_unwatch_' .. ctx.popupId, function()
            if canWriteSharedRule('TurboWares BuyWatch edit') and Wares.removeBuyWatch(ctx.iniPath, ctx.name) then
                refreshIniRules(g, ctx.iniPath)
                g.statusMessage = 'Removed BuyWatch: ' .. ctx.name
            end
        end, hasSharedRuleWrite()) then end
    else
        if Ui.menuItem('Watch##wares_ctx_watch_' .. ctx.popupId, function()
            if canWriteSharedRule('TurboWares BuyWatch edit') and Wares.addBuyWatch(ctx.iniPath, ctx.name) then
                refreshIniRules(g, ctx.iniPath)
                g.statusMessage = 'BuyWatch: ' .. ctx.name
            end
        end, hasSharedRuleWrite()) then end
    end
    ImGui.EndPopup()
end

local function attachRowInteractions(g, ctx)
    if ImGui.IsItemHovered() then
        local msg = 'Click to select. Double-click or right-click for actions.'
        if ctx.slotLabel and ctx.slotLabel ~= '' then
            msg = string.format('%s | stack %d | est. %s\n%s',
                ctx.slotLabel,
                tonumber(ctx.qty) or 1,
                Wares.formatCompactCopper(Wares.rowSellCopper(ctx)),
                msg)
        end
        tip(msg)
    end
    if ImGui.IsItemHovered() and ImGui.IsMouseDoubleClicked and ImGui.IsMouseDoubleClicked(0) then
        Wares.inspectItem(ctx.name, ctx.itemId)
    end
    drawItemContextMenu(g, ctx)
end

local function smallTableButton(label, idSuffix)
    if ImGui.SmallButton then
        return ImGui.SmallButton(label .. idSuffix)
    end
    return ImGui.Button(label .. idSuffix, 34, 20)
end

local function drawToolbarButtons(g, specs)
    local toolAvail = contentAvail()
    local toolGap = math.max(ImGui.GetStyle().ItemSpacing.x, 4)
    local count = #specs
    local toolW = math.max(58, math.floor((toolAvail - toolGap * (count - 1)) / count))
    for i, spec in ipairs(specs) do
        if i > 1 then ImGui.SameLine(0, toolGap) end
        if spec.disabled then ImGui.BeginDisabled() end
        local label = spec.labelFn and spec.labelFn(toolW) or spec.label
        local clicked
        if spec.variant == 'sell' or spec.variant == 'buy' then
            if spec.rgb then
                clicked = Ui.buttonRgb(label, spec.rgb, toolW, ACTION_BTN_H)
            else
                clicked = Ui.buttonVariant(label, spec.variant or 'secondaryButton', toolW, ACTION_BTN_H)
            end
        else
            clicked = Ui.buttonVariant(label, spec.variant or 'secondaryButton', toolW, ACTION_BTN_H)
        end
        if spec.disabled then ImGui.EndDisabled() end
        if clicked and spec.onClick then spec.onClick() end
        if spec.tip then tip(spec.tip) end
    end
end

local function toolbarLabelFits(text, width)
    text = tostring(text or ''):match('^(.-)##') or tostring(text or '')
    width = tonumber(width) or 0
    local approxCharW = ImGui.GetFontSize() * 0.58
    return width <= 0 or ((#text * approxCharW) + 18) <= width
end

local function sellNowButtonLabel(count, totalText, width)
    count = tonumber(count) or 0
    local suffix = '##wares_sell_now'
    if count <= 0 then return 'SELL NOW' .. suffix end
    local labels = {
        string.format('SELL NOW (%d ~%s)', count, tostring(totalText or '?')),
        string.format('SELL (%d ~%s)', count, tostring(totalText or '?')),
        string.format('SELL NOW (%d)', count),
        string.format('SELL (%d)', count),
    }
    for _, label in ipairs(labels) do
        if toolbarLabelFits(label, width) then return label .. suffix end
    end
    return 'SELL' .. suffix
end

local function buyNowButtonLabel(row, qty, width)
    local suffix = '##wares_buy_now'
    qty = math.max(1, math.floor(tonumber(qty) or 1))
    if not row then return 'BUY NOW' .. suffix end
    local unitCopper = tonumber(row.priceCopper) or math.floor(((tonumber(row.price) or 0) * 1000) + 0.5)
    local totalText = Wares.formatCompactPriceCopper(unitCopper * qty)
    local labels = {
        string.format('BUY NOW (%d ~%s)', qty, tostring(totalText or '?')),
        string.format('BUY (%d ~%s)', qty, tostring(totalText or '?')),
        string.format('BUY NOW (%d)', qty),
        string.format('BUY (%d)', qty),
    }
    for _, label in ipairs(labels) do
        if toolbarLabelFits(label, width) then return label .. suffix end
    end
    return 'BUY' .. suffix
end

local function resolveSelectedItemName(g, filtered, keyField)
    local key = g[keyField]
    if not key then return nil end
    for _, row in ipairs(filtered) do
        if row.key == key then return row.name end
    end
    return nil
end

local function drawMyItemsTab(g, iniPath)
    local lookup = Wares.buildRuleLookup(iniPath)
    g.waresSearchItems = g.waresSearchItems or ''
    g.waresFilterSellable = g.waresFilterSellable == true

    ImGui.PushItemWidth(-1)
    if ImGui.InputTextWithHint then
        g.waresSearchItems = ImGui.InputTextWithHint('##wares_item_search', 'search bag inventory', g.waresSearchItems)
    else
        g.waresSearchItems = ImGui.InputText('##wares_item_search', g.waresSearchItems)
    end
    ImGui.PopItemWidth()
    drawRuleFilterChips(g, 'waresRuleFilter', BAG_RULE_CHIPS)
    local sellCount, sellTotal, skippedMain, skippedZero = cachedSellSummary(iniPath, g)
    local sellPreviewTip = buildSellNowTooltip(iniPath, g)
    local TK = TurboKeyRGB or {}
    local sellRgb = TK.sell or { 60, 120, 80 }
    local sellTotalText = Wares.formatCompactCopper(sellTotal)
    local sellBusy = g.waresSellInProgress == true
    drawToolbarButtons(g, {
        {
            label = g.waresFilterSellable and 'Sellable##wares_sell_filter' or 'All items##wares_sell_filter',
            variant = g.waresFilterSellable and 'primaryButton' or 'secondaryButton',
            tip = 'When on, hide NoDrop / NoRent items.',
            onClick = function() g.waresFilterSellable = not g.waresFilterSellable end,
        },
        {
            label = 'Refresh##wares_inv_refresh',
            variant = 'secondaryButton',
            tip = 'Rescan bag contents and reload target INI rules.',
            onClick = function()
                refreshIniRules(g, iniPath, 'TurboWares: refreshed inventory and target INI.')
                invalidateWaresCaches(g, 'inventory')
                cachedInventoryRows(g, true)
            end,
        },
        {
            labelFn = function(width) return sellNowButtonLabel(sellCount, sellTotalText, width) end,
            variant = 'sell',
            rgb = sellRgb,
            disabled = sellCount <= 0 or sellBusy,
            tip = sellBusy and 'Sell in progress...'
                or (sellPreviewTip or 'Runs TurboLoot sell for all bag items tagged SELL in this target INI. Tag sellable bag items SELL first.'),
            onClick = function()
                queueSellTaggedNow(g, iniPath)
            end,
        },
    })
    if skippedMain and skippedMain > 0 then
        ImGui.TextColored(0.95, 0.72, 0.32, 1.0,
            string.format('%d SELL item(s) are on top-level inventory slots. Move them into a bag to sell.', skippedMain))
    elseif skippedZero and skippedZero > 0 then
        ImGui.TextColored(0.95, 0.72, 0.32, 1.0,
            string.format('%d SELL item(s) have zero vendor value and will be skipped.', skippedZero))
    end

    local rows = g._waresInvRows or Wares.scanInventory(false)
    local filtered = {}
    for _, row in ipairs(rows) do
        if (tonumber(row.qty) or 0) <= 0 and g.waresHideEmptyStacks ~= false then
            -- skip empty bag slots
        elseif (not g.waresFilterSellable or row.sellable)
            and Wares.matchesFilter(row.name, g.waresSearchItems)
            and rowPassesRuleFilter(g, lookup, row, 'waresRuleFilter') then
            filtered[#filtered + 1] = row
        end
    end
    ImGui.TextColored(0.55, 0.60, 0.68, 1.0, string.format('Bag items (%d shown / %d scanned):', #filtered, #rows))

    beginScrollList('##wares_items')
    if ImGui.BeginTable('##wares_items_table', 5, tableFlags()) then
        local COL = ImGuiTableColumnFlags
        local noSort = COL.NoSort or 0
        local defaultSort = COL.DefaultSort or 0
        ImGui.TableSetupColumn('Ico', COL.WidthFixed + noSort, 26)
        ImGui.TableSetupColumn('Item', defaultSort, 1.0, SORT_COL_ITEM)
        ImGui.TableSetupColumn('Rule', COL.WidthFixed, 76, SORT_COL_RULE)
        ImGui.TableSetupColumn('Qty', COL.WidthFixed, 34, SORT_COL_QTY)
        ImGui.TableSetupColumn('Val', COL.WidthFixed, 44, SORT_COL_VALUE)
        ImGui.TableSetupScrollFreeze(0, 1)
        ImGui.TableHeadersRow()
        local sortOk, sortSpecs = pcall(ImGui.TableGetSortSpecs)
        if sortOk and sortSpecs then sortFilteredRows(filtered, sortSpecs, lookup) end
        for _, row in ipairs(filtered) do
            ImGui.PushID('##wares_inv_' .. row.key)
            ImGui.TableNextRow()
            ImGui.TableSetColumnIndex(0)
            drawIcon(row.icon, 18, 18)
            ImGui.TableSetColumnIndex(1)
            local selected = g.waresSelectedKey == row.key
            if ImGui.Selectable(row.name .. '##' .. row.key .. '##wares_inv_sel', selected) then
                g.waresSelectedKey = row.key
            end
            attachRowInteractions(g, {
                kind = 'bag',
                popupId = row.key,
                key = row.key,
                name = row.name,
                itemId = row.itemId,
                iniPath = iniPath,
                slotLabel = row.slotLabel,
                qty = row.qty,
                value = row.value,
                sellable = row.sellable,
                packNum = row.packNum,
                slotNum = row.slotNum,
            })
            ImGui.TableSetColumnIndex(2)
            local rule = Wares.readRule(lookup, row.name)
            local rgb = Wares.ruleRgb(rule, TurboKeyRGB)
            ImGui.TextColored(rgb[1] / 255, rgb[2] / 255, rgb[3] / 255, 1.0, ruleDisplayText(rule))
            ImGui.TableSetColumnIndex(3)
            ImGui.Text(tostring(row.qty or 1))
            ImGui.TableSetColumnIndex(4)
            local stackCopper = Wares.rowSellCopper(row)
            if stackCopper > 0 then
                ImGui.Text(Wares.formatCompactCopper(stackCopper))
                if ImGui.IsItemHovered() then
                    tip(string.format('Stack est. %s (%s)',
                        Wares.formatCompactCopper(stackCopper), Wares.formatCopperLong(stackCopper)))
                end
            else
                ImGui.TextDisabled('-')
            end
            ImGui.PopID()
        end
        ImGui.EndTable()
    end

    endScrollList()
end

local function resolveItemsSelectedName(g, filtered)
    if not g.waresSelectedKey then return nil end
    for _, row in ipairs(filtered or {}) do
        if row.key == g.waresSelectedKey then return row.name end
    end
    return nil
end

resolveMerchantSelectedRow = function(g, rows)
    if not g.waresMerchantSelectedKey then return nil end
    for _, row in ipairs(rows or {}) do
        if row.key == g.waresMerchantSelectedKey then return row end
    end
    return nil
end

local function resolveMerchantSelectedName(g, filtered)
    if not g.waresMerchantSelectedKey then return nil end
    for _, row in ipairs(filtered or {}) do
        if row.key == g.waresMerchantSelectedKey then return row.name end
    end
    return nil
end

local function drawMerchantTab(g, iniPath, watchedHits)
    local lookup = Wares.buildRuleLookup(iniPath)
    g.waresSearchMerchant = g.waresSearchMerchant or ''

    ImGui.PushItemWidth(-1)
    if ImGui.InputTextWithHint then
        g.waresSearchMerchant = ImGui.InputTextWithHint('##wares_merch_search', 'search merchant', g.waresSearchMerchant)
    else
        g.waresSearchMerchant = ImGui.InputText('##wares_merch_search', g.waresSearchMerchant)
    end
    ImGui.PopItemWidth()
    drawRuleFilterChips(g, 'waresMerchantRuleFilter', MERCHANT_RULE_CHIPS)

    local merchRows = g._waresMerchRows or cachedMerchantRows(g, false)
    local merchantLoading = Wares.merchantLoading and Wares.merchantLoading() or false
    local selectedRow = resolveMerchantSelectedRow(g, merchRows)
    local TK = TurboKeyRGB or {}
    local buyRgb = TK.keep or { 70, 100, 150 }
    g.waresBuyQty = math.max(1, math.floor(tonumber(g.waresBuyQty) or 1))
    local rowAvail = contentAvail()
    local rowGap = math.max(ImGui.GetStyle().ItemSpacing.x, 4)
    local slotW = math.max(58, math.floor((rowAvail - rowGap * 2) / 3))
    ImGui.TextColored(0.55, 0.60, 0.68, 1.0, 'Qty')
    ImGui.SameLine(0, 4)
    ImGui.PushItemWidth(math.max(34, slotW - 32))
    local qtyText = tostring(g.waresBuyQty)
    qtyText = ImGui.InputText('##wares_buy_qty', qtyText, 4)
    g.waresBuyQty = math.max(1, math.floor(tonumber(qtyText) or 1))
    ImGui.PopItemWidth()
    ImGui.SameLine(0, rowGap)
    if Ui.buttonVariant('Refresh##wares_merch_refresh', 'secondaryButton', slotW, ACTION_BTN_H) then
        cachedMerchantRows(g, true)
        cachedWatchedMerchantHits(g, iniPath, true)
    end
    tip('Rescan merchant stock.')
    ImGui.SameLine(0, rowGap)
    if not selectedRow then ImGui.BeginDisabled() end
    local useQtyWindow = merchantUsesQuantityWindow(selectedRow, g.waresBuyQty)
    if Ui.buttonRgb(buyNowButtonLabel(selectedRow, g.waresBuyQty, slotW), buyRgb, slotW, ACTION_BTN_H) and queueBuyMerchantNow then
        queueBuyMerchantNow(g, selectedRow, g.waresBuyQty, useQtyWindow)
    end
    if not selectedRow then ImGui.EndDisabled() end
    tip(selectedRow
        and (useQtyWindow
            and string.format('Open the game quantity slider for %s.', selectedRow.name)
            or string.format('Buy %d x %s.', g.waresBuyQty, selectedRow.name))
        or 'Select a merchant row first.')

    local rows = merchRows
    local filtered = {}
    for _, row in ipairs(rows) do
        if Wares.matchesFilter(row.name, g.waresSearchMerchant)
            and rowPassesRuleFilter(g, lookup, row, 'waresMerchantRuleFilter') then
            filtered[#filtered + 1] = row
        end
    end
    local merchantCountText = merchantLoading and 'Merchant items: loading' or string.format('Merchant items (%d):', #filtered)
    ImGui.TextColored(0.55, 0.60, 0.68, 1.0, merchantCountText)

    beginScrollList('##wares_merch')
    if ImGui.BeginTable('##wares_merch_table', 5, tableFlags()) then
        local COL = ImGuiTableColumnFlags
        local noSort = COL.NoSort or 0
        local defaultSort = COL.DefaultSort or 0
        ImGui.TableSetupColumn('Ico', COL.WidthFixed + noSort, 26)
        ImGui.TableSetupColumn('Item', defaultSort, 1.0, SORT_COL_ITEM)
        ImGui.TableSetupColumn('Rule', COL.WidthFixed, 76, SORT_COL_RULE)
        ImGui.TableSetupColumn('Stock', COL.WidthFixed, 48, SORT_COL_QTY)
        ImGui.TableSetupColumn('Price', COL.WidthFixed, 52, SORT_COL_PRICE)
        ImGui.TableSetupScrollFreeze(0, 1)
        ImGui.TableHeadersRow()
        local sortOk, sortSpecs = pcall(ImGui.TableGetSortSpecs)
        if sortOk and sortSpecs then sortFilteredRows(filtered, sortSpecs, lookup) end
        if #filtered == 0 then
            ImGui.TableNextRow()
            ImGui.TableSetColumnIndex(1)
            local msg
            if merchantLoading then
                msg = 'Loading vendor list...'
            elseif #rows == 0 and (g.waresSearchMerchant or '') == '' and (g.waresMerchantRuleFilter or 'all') == 'all' then
                msg = 'Vendor list is empty.'
            else
                msg = 'No merchant items match this filter/search.'
            end
            ImGui.TextDisabled(msg)
        end
        for _, row in ipairs(filtered) do
            ImGui.PushID('##wares_m_' .. row.key)
            ImGui.TableNextRow()
            local watched = Wares.isWatched(row.name)
            if watched then
                ImGui.TableSetBgColor(ImGuiTableBgTarget.RowBg0, IM_COL32(48, 88, 58, 90))
            end
            ImGui.TableSetColumnIndex(0)
            drawIcon(row.icon, 18, 18)
            ImGui.TableSetColumnIndex(1)
            local label = row.name
            if watched then label = label .. ' *' end
            local selected = g.waresMerchantSelectedKey == row.key
            if ImGui.Selectable(label .. '##wares_m_sel', selected) then
                g.waresMerchantSelectedKey = row.key
            end
            attachRowInteractions(g, {
                kind = 'merchant',
                popupId = row.key,
                key = row.key,
                name = row.name,
                itemId = row.itemId,
                iniPath = iniPath,
                qty = row.qty,
                price = row.price,
                priceCopper = row.priceCopper,
            })
            ImGui.TableSetColumnIndex(2)
            local rule = Wares.readRule(lookup, row.name)
            if rule ~= '' then
                local rgb = Wares.ruleRgb(rule, TurboKeyRGB)
                ImGui.TextColored(rgb[1] / 255, rgb[2] / 255, rgb[3] / 255, 1.0, rule)
            else
                ImGui.TextDisabled('-')
            end
            ImGui.TableSetColumnIndex(3)
            local stock = tonumber(row.qty) or -1
            if stock >= 0 then ImGui.Text(tostring(stock)) else ImGui.TextDisabled('-') end
            ImGui.TableSetColumnIndex(4)
            local rowCopper = tonumber(row.priceCopper) or math.floor(((tonumber(row.price) or 0) * 1000) + 0.5)
            ImGui.Text(Wares.formatCompactPriceCopper(rowCopper))
            if ImGui.IsItemHovered() and rowCopper > 0 then
                tip(string.format('Buy price: %s (%s). Select row + BUY NOW.',
                    Wares.formatCompactPriceCopper(rowCopper), Wares.formatCopperLong(rowCopper)))
            end
            ImGui.PopID()
        end
        ImGui.EndTable()
    end

    endScrollList()
end

local function drawWatchedTab(g, iniPath, watchedHits, qtyMap)
    local hits = watchedHits or {}
    local hitSet = {}
    for _, name in ipairs(hits) do hitSet[canonicalKey(name)] = true end

    g.waresWatchDraft = g.waresWatchDraft or ''
    ImGui.TextColored(0.62, 0.66, 0.74, 1.0, 'Items you always want to notice at merchants.')
    if #hits > 0 then
        ImGui.TextColored(0.95, 0.82, 0.35, 1.0, string.format('In stock now (%d): %s', #hits, table.concat(hits, ', ')))
    end
    ImGui.Dummy(0, 4)
    local avail = contentAvail()
    local btnW = 52
    local gap = math.max(ImGui.GetStyle().ItemSpacing.x, 4)
    ImGui.PushItemWidth(math.max(120, avail - btnW - gap - 8))
    if ImGui.InputTextWithHint then
        g.waresWatchDraft = ImGui.InputTextWithHint('##wares_watch_input', 'item name', g.waresWatchDraft)
    else
        g.waresWatchDraft = ImGui.InputText('##wares_watch_input', g.waresWatchDraft)
    end
    ImGui.PopItemWidth()
    ImGui.SameLine(0, gap)
    local canWatchWrite = hasSharedRuleWrite()
    if not canWatchWrite then ImGui.BeginDisabled() end
    if Ui.buttonVariant('Add##wares_watch_add', 'successButton', btnW, ACTION_BTN_H) then
        local name = tostring(g.waresWatchDraft or ''):match('^%s*(.-)%s*$') or ''
        if name ~= '' and canWriteSharedRule('TurboWares BuyWatch edit') and Wares.addBuyWatch(iniPath, name) then
            refreshIniRules(g, iniPath)
            g.waresWatchDraft = ''
            g.statusMessage = 'BuyWatch: ' .. name
        elseif name ~= '' then
            g.statusMessage = 'TurboWares: could not write BuyWatch (check target INI path).'
        end
    end
    if not canWatchWrite then ImGui.EndDisabled() end
    tip(canWatchWrite and 'Stored in [BuyWatch] on the target INI.' or 'Take Turbo control to edit BuyWatch.')

    local quickName = nil
    if g.waresSelectedKey and g._waresInvRows then
        quickName = resolveSelectedItemName(g, g._waresInvRows, 'waresSelectedKey')
    end
    if not quickName and g.waresMerchantSelectedKey and g._waresMerchRows then
        quickName = resolveSelectedItemName(g, g._waresMerchRows, 'waresMerchantSelectedKey')
    end
    if quickName and not Wares.isWatched(quickName) then
        local selBtnLabel = Ui.fitLabel('Add selected: ' .. quickName .. '##wares_watch_sel', 'Add selected', avail)
        if not canWatchWrite then ImGui.BeginDisabled() end
        if Ui.buttonVariant(selBtnLabel, 'secondaryButton', avail, ACTION_BTN_H) then
            if canWriteSharedRule('TurboWares BuyWatch edit') and Wares.addBuyWatch(iniPath, quickName) then
                refreshIniRules(g, iniPath)
                g.statusMessage = 'BuyWatch: ' .. quickName
            end
        end
        if not canWatchWrite then ImGui.EndDisabled() end
        tip(canWatchWrite and 'Adds the item selected on Bags or Merchant.' or 'Take Turbo control to edit BuyWatch.')
        ImGui.Dummy(0, 2)
    end

    local names = Wares.getBuyWatchNames()
    qtyMap = qtyMap or g._waresQtyMap or {}
    ImGui.TextColored(0.55, 0.60, 0.68, 1.0, string.format('Watched (%d):', #names))
    beginFullList('##wares_watch_scroll')
    if ImGui.BeginTable('##wares_watch_table', 4, tableFlags()) then
        local COL = ImGuiTableColumnFlags
        local noSort = COL.NoSort or 0
        local defaultSort = COL.DefaultSort or 0
        local SORT_IDX = 5
        local SORT_STOCK = 6
        ImGui.TableSetupColumn('#', COL.WidthFixed, 28, SORT_IDX)
        ImGui.TableSetupColumn('Item', defaultSort, 1.0, SORT_COL_ITEM)
        ImGui.TableSetupColumn('Have', COL.WidthFixed, 48, SORT_COL_HAVE)
        ImGui.TableSetupColumn('Stock', COL.WidthFixed, 48, SORT_STOCK)
        ImGui.TableHeadersRow()
        local displayRows = {}
        for i, name in ipairs(names) do
            local inStock = hitSet[canonicalKey(name)] == true
            displayRows[i] = {
                idx = i,
                name = name,
                inStock = inStock and 1 or 0,
                have = Wares.getInventoryQty(name, qtyMap),
            }
        end
        local sortOk, sortSpecs = pcall(ImGui.TableGetSortSpecs)
        if sortOk and sortSpecs and #displayRows > 1 and (tonumber(sortSpecs.SpecsCount) or 0) > 0 then
            table.sort(displayRows, function(a, b)
                local spec = sortSpecs:Specs(1)
                local uid = spec and spec.ColumnUserID or SORT_COL_ITEM
                local av, bv
                if uid == SORT_IDX then
                    av, bv = a.idx, b.idx
                elseif uid == SORT_STOCK then
                    av, bv = a.inStock, b.inStock
                elseif uid == SORT_COL_HAVE then
                    av, bv = a.have, b.have
                else
                    av = tostring(a.name):lower()
                    bv = tostring(b.name):lower()
                end
                if type(av) == 'number' and type(bv) == 'number' then
                    if ImGuiSortDirection and spec and spec.SortDirection == ImGuiSortDirection.Descending then
                        return av > bv
                    end
                    return av < bv
                end
                if ImGuiSortDirection and spec and spec.SortDirection == ImGuiSortDirection.Descending then
                    return av > bv
                end
                return av < bv
            end)
            if sortSpecs.SpecsDirty then sortSpecs.SpecsDirty = false end
        end
        for i, row in ipairs(displayRows) do
            local name = row.name
            ImGui.PushID('##wares_watch_row_' .. i)
            ImGui.TableNextRow()
            if row.inStock == 1 then
                ImGui.TableSetBgColor(ImGuiTableBgTarget.RowBg0, IM_COL32(48, 88, 58, 90))
            end
            ImGui.TableSetColumnIndex(0)
            ImGui.Text(tostring(i))
            ImGui.TableSetColumnIndex(1)
            if ImGui.Selectable(name .. '##wares_watch_sel_' .. i, false) then end
            attachRowInteractions(g, {
                popupId = 'watch_' .. name,
                name = name,
                itemId = nil,
                iniPath = iniPath,
            })
            ImGui.TableSetColumnIndex(2)
            if row.have > 0 then
                ImGui.Text(tostring(row.have))
            else
                ImGui.TextDisabled('-')
            end
            ImGui.TableSetColumnIndex(3)
            if row.inStock == 1 then
                ImGui.TextColored(0.55, 0.95, 0.62, 1.0, 'Yes')
            else
                ImGui.TextDisabled('-')
            end
            ImGui.PopID()
        end
        ImGui.EndTable()
    end
    endFullList()
end

local function maybeAlertWatchedInStock(g, iniPath, hits)
    hits = hits or cachedWatchedMerchantHits(g, iniPath, false)
    if #hits == 0 then return end
    local merchantName = mq.TLO.Target.CleanName() or mq.TLO.Target.Name() or 'merchant'
    local alertKey = merchantName:lower() .. '|' .. table.concat(hits, '|'):lower()
    if lastWatchAlertKey == alertKey then return end
    lastWatchAlertKey = alertKey
    g.statusMessage = string.format('TurboWares: watched in stock - %s', table.concat(hits, ', '))
    mq.cmd('/beep')
end

local function drawWaresTabNav(g, watchedHits)
    g.waresTab = g.waresTab or g.waresRequestedTab or 'items'
    local watchCount = #(Wares.getBuyWatchNames())
    local merchText = #watchedHits > 0 and string.format('Merchant (%d)', #watchedHits) or 'Merchant'
    local watchText = watchCount > 0 and string.format('Watched (%d)', watchCount) or 'Watched'
    local tabs = {
        { key = 'items', label = 'Bags' },
        { key = 'merchant', label = merchText },
        { key = 'watched', label = watchText },
    }
    local avail = contentAvail()
    local gap = math.max(ImGui.GetStyle().ItemSpacing.x, 4)
    local w = math.max(78, math.floor((avail - gap * (#tabs - 1)) / #tabs))
    for i, tab in ipairs(tabs) do
        if i > 1 then ImGui.SameLine(0, gap) end
        local active = g.waresTab == tab.key
        local variant = active and 'primaryButton' or 'secondaryButton'
        if Ui.buttonVariant(tab.label .. '##wares_nav_' .. tab.key, variant, w, ACTION_BTN_H) then
            g.waresTab = tab.key
            g.waresRequestedTab = tab.key
            if saveSettings then saveSettings() end
        end
    end
end

function M.setup(env)
    if setupDone then return end
    Ui = env.Ui
    Theme = env.Theme
    TurboKeyRGB = env.TurboKeyRGB
    writeIniKey = env.writeIniKey
    readIniKey = env.readIniKey
    readIniSectionPairs = env.readIniSectionPairs
    deleteIniKey = env.deleteIniKey
    resolveTurbolootIniPathForProfile = env.resolveTurbolootIniPathForProfile
    cleanProfileName = env.cleanProfileName
    shellOpenFile = env.shellOpenFile
    getActiveProfile = env.getActiveProfile
    openAllaItemPage = env.openAllaItemPage
    saveSettings = env.saveSettings
    canSharedControlWrite = env.canSharedControlWrite
    requireSharedControl = env.requireSharedControl
    ACTION_BTN_H = env.ACTION_BTN_H or 24
    Wares.setup(env)
    animItems = mq.FindTextureAnimation('A_DragItem')
    setupDone = true
end

function M.render(g)
    if mq.TLO.MacroQuest.GameState() ~= 'INGAME' then return end

    local merchantWnd = mq.TLO.Window('MerchantWnd')
    if not merchantWnd.Open() then
        merchantWasOpen = false
        lastWatchAlertKey = nil
        return
    end

    if not merchantWasOpen then
        merchantWasOpen = true
        if g.waresAutoShow ~= false then
            g.waresWindowOpen = true
        end
        Wares.markMerchantOpened()
        invalidateWaresCaches(g, 'all')
        cachedInventoryRows(g, true)
        cachedMerchantRows(g, true)
    end

    if g.waresAutoShow == false or not g.waresWindowOpen then return end

    tickWaresThrottled(false)
    local iniPath = resolveTargetIniPath(g)
    maybeRefreshExternalIni(g, iniPath)
    if g._waresInvalidateMerchantCache then
        g._waresInvalidateMerchantCache = false
        invalidateWaresCaches(g, 'merchant')
    end
    if g._waresInvalidateSellCache then
        g._waresInvalidateSellCache = false
        invalidateWaresCaches(g, 'inventory')
        invalidateSellCountCache()
    end
    cachedReadBuyWatch(iniPath, false)
    local alertHits = cachedWatchedMerchantHits(g, iniPath, false)
    maybeAlertWatchedInStock(g, iniPath, alertHits)

    local merchantH = merchantWnd.Height()
    local merchantX = merchantWnd.X() + merchantWnd.Width()
    local merchantY = merchantWnd.Y()
    g.waresWindowWidth = g.waresWindowWidth or 440
    local posCond = (ImGuiCond and ImGuiCond.Always) or 1
    ImGui.SetNextWindowPos(merchantX, merchantY, posCond)
    ImGui.SetNextWindowSize(g.waresWindowWidth, merchantH, posCond)
    ImGui.SetNextWindowSizeConstraints(400, merchantH, 960, merchantH)

    pushWindowStyle()
    local waresFlags = bit32.bor(
        ImGuiWindowFlags.NoCollapse,
        ImGuiWindowFlags.NoScrollbar,
        ImGuiWindowFlags.NoScrollWithMouse)
    if ImGuiWindowFlags.NoDocking then
        waresFlags = bit32.bor(waresFlags, ImGuiWindowFlags.NoDocking)
    end
    local waresOpen, waresDraw = ImGui.Begin('TurboWares###Turbo_Wares_Window', g.waresWindowOpen, waresFlags)
    g.waresWindowOpen = waresOpen
    if waresDraw == nil then waresDraw = waresOpen end
    if waresOpen and ImGui.GetWindowSize then
        local sz = ImGui.GetWindowSize()
        if type(sz) == 'table' then
            g.waresWindowWidth = tonumber(sz.x or sz.X or sz[1]) or g.waresWindowWidth
        else
            local w = select(1, ImGui.GetWindowSize())
            if w then g.waresWindowWidth = tonumber(w) or g.waresWindowWidth end
        end
    end

    local okDraw, drawErr = pcall(function()
        if not waresDraw then return end
        g.waresTab = g.waresRequestedTab or g.waresTab or 'items'
        local watchedHits = cachedWatchedMerchantHits(g, iniPath, false)
        g._waresWatchHits = watchedHits
        if g.waresTab == 'watched' then
            g._waresQtyMap = cachedQtyMap(g, false)
            g._waresInvRows = cachedInventoryRows(g, false)
            g._waresMerchRows = cachedMerchantRows(g, false)
        elseif g.waresTab == 'items' then
            g._waresQtyMap = nil
            g._waresInvRows = cachedInventoryRows(g, false)
            g._waresMerchRows = nil
        elseif g.waresTab == 'merchant' then
            g._waresQtyMap = nil
            g._waresInvRows = nil
            g._waresMerchRows = cachedMerchantRows(g, false)
        else
            g._waresQtyMap = nil
            g._waresInvRows = cachedInventoryRows(g, false)
            g._waresMerchRows = nil
        end
        drawIniHeader(g)
        ImGui.Separator()
        drawWaresTabNav(g, watchedHits)
        ImGui.Separator()
        if g.waresTab == 'merchant' then
            runTabBody(g, '##wares_tab_merchant_body', function()
                drawMerchantTab(g, iniPath, watchedHits)
            end)
        elseif g.waresTab == 'watched' then
            runTabBody(g, '##wares_tab_watched_body', function()
                drawWatchedTab(g, iniPath, watchedHits, g._waresQtyMap)
            end)
        else
            g.waresTab = 'items'
            runTabBody(g, '##wares_tab_items_body', function()
                drawMyItemsTab(g, iniPath)
            end)
        end
        if tabUsesRuleBar(g.waresTab) then
            ImGui.Separator()
            local selectedName = nil
            if g.waresTab == 'items' and g._waresInvRows then
                selectedName = resolveItemsSelectedName(g, g._waresInvRows)
            elseif g.waresTab == 'merchant' and g._waresMerchRows then
                selectedName = resolveMerchantSelectedName(g, g._waresMerchRows)
            end
            drawRuleBar(g, selectedName, iniPath)
        end
    end)

    ImGui.End()
    popWindowStyle()

    if not okDraw then
        g.statusMessage = 'TurboWares error: ' .. tostring(drawErr)
    end
end

return M
