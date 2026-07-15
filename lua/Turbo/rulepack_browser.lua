--[[
  Turbo rule pack browser (multi-row apply + inspect)
  @version lua/Turbo/rulepack_browser.lua 1.3.2

  Browse ItemLimits from packs, filter, LinkDB inspect, apply rules to target INI.
  Select mode toggles multi-select; Range mode selects a range. Ctrl/Shift clicks are also honored when MQ passes them through.
]]

local mq    = require('mq')
local ImGui = require('ImGui')
local Ui    = require('Turbo.ui.components')
local Theme = require('Turbo.theme')

local M = {}

local RULE_CHOICES = { 'KEEP', 'SELL', 'BANK', 'TRIBUTE', 'DESTROY', 'IGNORE', 'ANNOUNCE' }

local function cleanRuleValue(rule)
    local s = tostring(rule or ''):match('^%s*(.-)%s*$') or ''
    local n = tonumber(s)
    if n and n > 0 then return tostring(math.floor(n)) end
    return s:upper():match('^%s*(%w+)') or ''
end

local function arcadeBump(g, points)
    points = math.floor(tonumber(points) or 0)
    if points <= 0 or not g then return end
    g.rulePackArcadeScore = math.floor(tonumber(g.rulePackArcadeScore) or 0) + points
    g.rulePackArcadeSessionPts = math.floor(tonumber(g.rulePackArcadeSessionPts) or 0) + points
    g.rulePackArcadeDirty = true
end

local function arcadeMaybePersist(g)
    if not g or not g.rulePackArcadeDirty then return end
    local now = (g.nowMS and g.nowMS()) or (mq.gettime and mq.gettime()) or 0
    local last = tonumber(g.rulePackArcadeLastSaveMs) or 0
    if now > 0 and (now - last) < 900 then return end
    g.rulePackArcadeLastSaveMs = now
    g.rulePackArcadeDirty = false
    if g.saveSettings then pcall(g.saveSettings) end
end

local linkCache = {}

local function resolveLinkDb(name)
    name = tostring(name or '')
    local key = name:lower()
    if linkCache[key] ~= nil then
        return linkCache[key] or ''
    end
    local ldb = mq.TLO.LinkDB
    if ldb then
        local ok, result = pcall(function()
            return ldb('=' .. name)()
        end)
        if ok and result and result ~= '' and result ~= 'NULL' then
            linkCache[key] = result
            return result
        end
    end
    linkCache[key] = false
    return ''
end

local function normAlnum(s)
    return (tostring(s or ''):lower():gsub('[^%w]+', ''))
end

local function levenshtein(a, b)
    a = tostring(a or '')
    b = tostring(b or '')
    local la, lb = #a, #b
    if math.abs(la - lb) > 14 then return 999 end
    local prev = {}
    for j = 0, lb do prev[j + 1] = j end
    for i = 1, la do
        local cur = { i }
        local ai = a:byte(i)
        for j = 1, lb do
            local cost = (ai == b:byte(j)) and 0 or 1
            cur[j + 1] = math.min(prev[j + 1] + 1, cur[j] + 1, prev[j] + cost)
        end
        prev = cur
    end
    return prev[lb + 1]
end

--- Match query against ItemLimits name; substring first, optional fuzzy "similar spelling".
local function matchPackSearchScore(query, itemName, fuzzy)
    local q = tostring(query or ''):match('^%s*(.-)%s*$'):lower()
    local nl = tostring(itemName or ''):lower()
    if q == '' or nl == '' then return nil end
    if nl:find(q, 1, true) then return 100 end
    local qn, nn = normAlnum(q), normAlnum(itemName)
    if qn ~= '' and nn:find(qn, 1, true) then return 88 end
    if fuzzy and #qn >= 3 and #nn >= 3 then
        local d = levenshtein(qn, nn)
        local maxd = math.min(5, math.max(2, math.floor(math.min(#qn, #nn) / 5)))
        if d <= maxd then return 72 - d end
    end
    return nil
end

local function syncRuleIdxFromPackRule(g, rule)
    local upper = tostring(rule or ''):upper():match('^%s*(%w+)')
    if not upper then return end
    for i, lab in ipairs(RULE_CHOICES) do
        if upper == lab then
            g.rulePackBrowserRuleIdx = i
            return
        end
    end
end

local function cleanProfileName(p)
    p = tostring(p or ''):match('^%s*(.-)%s*$') or ''
    return p ~= '' and p or nil
end

local function selSetEnsure(g)
    if type(g.rulePackBrowserSelSet) ~= 'table' then g.rulePackBrowserSelSet = {} end
    if type(g.rulePackBrowserSelList) ~= 'table' then g.rulePackBrowserSelList = {} end
end

local function selSetCount(g)
    if type(g.rulePackBrowserSelList) == 'table' and #g.rulePackBrowserSelList > 0 then
        return #g.rulePackBrowserSelList
    end
    local n = 0
    for _ in pairs(g.rulePackBrowserSelSet or {}) do n = n + 1 end
    return n
end

--- Ordered list of item names to apply rules to (multi-set if non-empty, else primary row).
local function selEffectiveNames(g)
    selSetEnsure(g)
    local names = {}
    if #g.rulePackBrowserSelList > 0 then
        for i = 1, #g.rulePackBrowserSelList do
            local name = g.rulePackBrowserSelList[i]
            if name and name ~= '' then names[#names + 1] = name end
        end
        return names
    end
    if selSetCount(g) > 0 then
        for name in pairs(g.rulePackBrowserSelSet) do
            if name and name ~= '' then names[#names + 1] = name end
        end
        table.sort(names)
        return names
    end
    if g.rulePackBrowserSelName and g.rulePackBrowserSelName ~= '' then
        return { g.rulePackBrowserSelName }
    end
    return {}
end

local function selClear(g)
    g.rulePackBrowserSelSet = {}
    g.rulePackBrowserSelList = {}
end

local function selAdd(g, name)
    name = tostring(name or '')
    if name == '' then return end
    selSetEnsure(g)
    if not g.rulePackBrowserSelSet[name] then
        g.rulePackBrowserSelList[#g.rulePackBrowserSelList + 1] = name
    end
    g.rulePackBrowserSelSet[name] = true
end

local function selRemove(g, name)
    name = tostring(name or '')
    if name == '' then return end
    selSetEnsure(g)
    g.rulePackBrowserSelSet[name] = nil
    for i = #g.rulePackBrowserSelList, 1, -1 do
        if g.rulePackBrowserSelList[i] == name then
            table.remove(g.rulePackBrowserSelList, i)
        end
    end
end

local function clearedEnsure(g)
    if type(g.rulePackBrowserClearedSet) ~= 'table' then g.rulePackBrowserClearedSet = {} end
end

local function visibleSelectionSync(g, visiblePairs, sig)
    selSetEnsure(g)
    clearedEnsure(g)
    if g.rulePackBrowserVisibleSig ~= sig then
        selClear(g)
        g.rulePackBrowserClearedSet = {}
        g.rulePackBrowserVisibleSig = sig
    end
    for _, pair in ipairs(visiblePairs or {}) do
        local name = pair.key
        if name and name ~= '' and not g.rulePackBrowserClearedSet[name] then
            selAdd(g, name)
        end
    end
end

local function visibleNames(visiblePairs)
    local names = {}
    for _, pair in ipairs(visiblePairs or {}) do
        if pair.key and pair.key ~= '' then names[#names + 1] = pair.key end
    end
    return names
end

local function inputTextHint(id, hint, value)
    if ImGui.InputTextWithHint then
        local ok, nextValue = pcall(ImGui.InputTextWithHint, id, hint, tostring(value or ''))
        if ok then return nextValue end
    end
    return ImGui.InputText(id, tostring(value or ''))
end

function M.render(ctx)
    local g = ctx.g
    local TG = ctx.TG
    if not g or not TG then return end

    local pageMode = ctx.pageMode == true
    if pageMode then
        -- Detached Rule Packs window already has the import header above this browser.
    elseif not ImGui.CollapsingHeader('Browse rule packs###setup_rulepack_browser') then
        arcadeMaybePersist(g)
        return
    end

    local tip = ctx.tip or function() end
    local mutedWrap = ctx.mutedWrap or function(t) ImGui.TextWrapped(t) end
    local ACTION_BTN_H = ctx.ACTION_BTN_H or 24
    local activeProf = ctx.activeProf or 'turboloot.ini'
    local assignTarget = ctx.assignTarget
    local showAdvancedSetup = ctx.showAdvancedSetup
    local getProfileForMember = ctx.getProfileForMember
    local resolveTurbolootIniPathForProfile = ctx.resolveTurbolootIniPathForProfile
    local profileList = type(ctx.profileList) == 'table' and ctx.profileList or {}
    local openProfile = ctx.openProfile

    local autoTargetProfile = showAdvancedSetup and getProfileForMember(assignTarget) or activeProf
    local packTargetProfile = g.rulePackBrowserTargetProfile or autoTargetProfile
    packTargetProfile = cleanProfileName(packTargetProfile) or 'turboloot.ini'
    local packTargetPath = resolveTurbolootIniPathForProfile and resolveTurbolootIniPathForProfile(packTargetProfile) or nil

    if not packTargetPath then
        ImGui.TextColored(0.95, 0.45, 0.35, 1.0, 'Could not resolve path for target INI.')
        arcadeMaybePersist(g)
        return
    end

    local nowMS = (g.nowMS and g.nowMS()) or (mq.gettime and mq.gettime()) or 0
    
    if type(g.rulePackBrowserPacks) ~= 'table'
        or (nowMS - (tonumber(g.rulePackBrowserPacksAt) or 0)) > 5000 then
    
        g.rulePackBrowserPacks = TG.refreshRulePacks(false) or {}
        g.rulePackBrowserPacksAt = nowMS
    end
    
    local packs = g.rulePackBrowserPacks or {}

    if #packs == 0 then
        mutedWrap('No rule packs in lua\\Turbo\\rulepacks.')
        arcadeMaybePersist(g)
        return
    end

    local function clearRulePackRowsCache()
    g.rulePackBrowserPackRowsCache = {}
end

local function getRulePackRows(packName)
    packName = tostring(packName or '')
    if packName == '' then return {} end

    if type(g.rulePackBrowserPackRowsCache) ~= 'table' then
        g.rulePackBrowserPackRowsCache = {}
    end

    local cached = g.rulePackBrowserPackRowsCache[packName]
    if cached then return cached end

    local rows = TG.readRulePackItemLimits(packName) or {}
    g.rulePackBrowserPackRowsCache[packName] = rows
    return rows
end

    local function bumpTargetIniRuleCache()
        g.rulePackBrowserIniRuleCacheGen = (g.rulePackBrowserIniRuleCacheGen or 0) + 1
    end

    --- Reads full [ItemLimits] from target INI once per cache generation (fast vs per-row reads).
    local function ensureTargetIniRuleCache()
        local rowsNow = g.rulePackBrowserRows or {}
        local gen = g.rulePackBrowserIniRuleCacheGen or 0
        local sig = packTargetPath .. '\1' .. tostring(g.rulePackBrowserPack or '') .. '\1'
            .. tostring(#rowsNow) .. '\1' .. tostring(gen)
        if g.rulePackBrowserIniRuleCacheSig == sig and type(g.rulePackBrowserTargetIniRules) == 'table' then
            return
        end
        local m = {}
        for _, pair in ipairs(TG.readItemLimitsIniPairs(packTargetPath)) do
            local n = pair.key
            if n and n ~= '' then
                m[n] = pair.value
            end
        end
        g.rulePackBrowserTargetIniRules = m
        g.rulePackBrowserIniRuleCacheSig = sig
    end

    local function turboRuleHead(rule)
        return tostring(rule or ''):upper():match('^%s*(%w+)') or ''
    end

    local TK = ctx.TurboKeyRGB or Theme.col.turboKeyRGB or {}
    local K  = TK.keep    or {70, 100, 150}
    local SE = TK.sell    or {60, 120, 80}
    local BA = TK.bank    or TK.trade or {90, 82, 130}
    local D  = TK.destroy or {145, 60, 55}
    local S  = TK.skip    or {55, 58, 65}
    local TR = TK.tribute or {130, 95, 35}
    local AN = TK.announce or {55, 130, 140}

    local function ruleRgb(rule)
        local head = turboRuleHead(rule)
        if head == 'KEEP' then return K end
        if head == 'SELL' then return SE end
        if head == 'BANK' then return BA end
        if head == 'TRIBUTE' then return TR end
        if head == 'DESTROY' then return D end
        if head == 'IGNORE' then return S end
        if head == 'ANNOUNCE' then return AN end
        return {145, 152, 166}
    end

    local function textRule(rule)
        local text = tostring(rule or '')
        if text == '' then
            ImGui.TextDisabled('-')
            return
        end
        local rgb = ruleRgb(text)
        ImGui.TextColored((rgb[1] or 145) / 255, (rgb[2] or 152) / 255, (rgb[3] or 166) / 255, 1.0, text)
    end

    local function inspectItem(itemName)
        itemName = tostring(itemName or '')
        if itemName == '' then return end
        local link = resolveLinkDb(itemName)
        if link ~= '' then
            mq.cmd('/executelink ' .. link)
            arcadeBump(g, 25)
        else
            g.statusMessage = itemName .. ': no LinkDB link (install MQ2LinkDB or verify item name).'
            arcadeBump(g, 3)
        end
    end

    if not g.rulePackBrowserPack or g.rulePackBrowserPack == '' then
        local prefer = 'OoW_Anguish_list.ini'
        local found = packs[1]
        for _, n in ipairs(packs) do
            if n == prefer then found = prefer break end
        end
        g.rulePackBrowserPack = found
    else
        local okName = false
        for _, n in ipairs(packs) do
            if n == g.rulePackBrowserPack then okName = true break end
        end
        if not okName then g.rulePackBrowserPack = packs[1] end
    end

    g.rulePackBrowserFilter = g.rulePackBrowserFilter or ''
    g.rulePackBrowserRuleIdx = g.rulePackBrowserRuleIdx or 1
    if type(g.rulePackBrowserRows) ~= 'table' then g.rulePackBrowserRows = {} end
    if g.rulePackGlobalSearchFuzzy == nil then g.rulePackGlobalSearchFuzzy = true end
    if g.rulePackGlobalSearchIncludeIni == nil then g.rulePackGlobalSearchIncludeIni = true end
    g.rulePackGlobalSearchQuery = g.rulePackGlobalSearchQuery or ''
    if type(g.rulePackGlobalSearchResults) ~= 'table' then g.rulePackGlobalSearchResults = {} end

    g.rulePackGlobalSearchFuzzy = true
    g.rulePackGlobalSearchIncludeIni = true

    local searchOpen = ImGui.CollapsingHeader('Search & Filter##rulepack_global_search')
    if searchOpen then
        local searchAvail = ImGui.GetContentRegionAvail()
        local gap = math.max(ImGui.GetStyle().ItemSpacing.x, 4)
        local searchW = math.max(120, searchAvail - 96 - 72 - 72 - (gap * 3))
        ImGui.PushItemWidth(searchW)
        g.rulePackGlobalSearchQuery = inputTextHint('##rulepack_gsearch_q', 'search items or rules', g.rulePackGlobalSearchQuery)
        ImGui.PopItemWidth()

        ImGui.SameLine(0, gap)
        if Ui.buttonVariant('Refresh##rulepack_refresh_packs', 'secondaryButton', 72, ACTION_BTN_H) then
            g.rulePackBrowserPacks = TG.refreshRulePacks(true) or {}
            g.rulePackBrowserPacksAt = nowMS
            clearRulePackRowsCache()
            g.rulePackBrowserRows = {}
            g.rulePackBrowserNeedsManualLoad = false
            g.rulePackBrowserIniRuleCacheSig = ''
            g.statusMessage = 'Rule packs refreshed.'
        end
        ImGui.SameLine(0, gap)

        if Ui.buttonVariant('Search##rulepack_gsearch_go', 'secondaryButton', 96, ACTION_BTN_H) then
            local q = tostring(g.rulePackGlobalSearchQuery or ''):match('^%s*(.-)%s*$') or ''
            if q == '' then
                g.rulePackGlobalSearchResults = {}
                g.statusMessage = 'Enter text to search packs / INI.'
            else
                local fuzzy = g.rulePackGlobalSearchFuzzy == true
                local inclIni = g.rulePackGlobalSearchIncludeIni == true
                local hits = {}
                for _, packName in ipairs(packs) do
                    for _, pair in ipairs(getRulePackRows(packName)) do
                        local sc = matchPackSearchScore(q, pair.key, fuzzy)
                        if sc then
                            hits[#hits + 1] = {
                                src = 'pack',
                                pack = packName,
                                name = pair.key,
                                rule = pair.value or '',
                                score = sc,
                            }
                        end
                    end
                end
                if inclIni then
                    for _, pair in ipairs(TG.readItemLimitsIniPairs(packTargetPath)) do
                        local sc = matchPackSearchScore(q, pair.key, fuzzy)
                        if sc then
                            hits[#hits + 1] = {
                                src = 'ini',
                                pack = nil,
                                name = pair.key,
                                rule = pair.value or '',
                                score = sc,
                            }
                        end
                    end
                end
                local bestByKey = {}
                for _, r in ipairs(hits) do
                    local k = r.src .. '\0' .. tostring(r.pack or '') .. '\0' .. (r.name or ''):lower()
                    local ex = bestByKey[k]
                    if not ex or r.score > ex.score then bestByKey[k] = r end
                end
                local dedup = {}
                for _, r in pairs(bestByKey) do dedup[#dedup + 1] = r end
                table.sort(dedup, function(a, b)
                    if a.score ~= b.score then return a.score > b.score end
                    return (a.name or '') < (b.name or '')
                end)
                local cap = 200
                while #dedup > cap do table.remove(dedup) end
                g.rulePackGlobalSearchResults = dedup
                g.statusMessage = string.format('Pack search » %d hit(s) for "%s"', #dedup, q)
                if dedup[1] then
                    local hit = dedup[1]
                    if hit.src == 'pack' and hit.pack then
                        g.rulePackBrowserPack = hit.pack
                        g.selectedRulePack = hit.pack
                        g.rulePackBrowserRows = getRulePackRows(hit.pack)
                    end
                    g.rulePackBrowserFilter = hit.name or q
                    g.rulePackBrowserVisibleSig = nil
                    g.statusMessage = string.format('Showing best search match: %s', hit.name or q)
                end
                arcadeBump(g, 35 + math.min(#dedup, 85))
            end
        end
        tip('Substring match preferred; fuzzy fills in typos / near names.')
        ImGui.SameLine(0, gap)
        if Ui.buttonVariant('Clear##rulepack_gsearch_clr', 'secondaryButton', 72, ACTION_BTN_H) then
            g.rulePackGlobalSearchResults = {}
            g.rulePackGlobalSearchQuery = ''
        end
    end

    if #g.rulePackBrowserRows == 0 and g.rulePackBrowserPack and g.rulePackBrowserPack ~= '' then
        g.rulePackBrowserRows = getRulePackRows(g.rulePackBrowserPack)
        g.rulePackBrowserNeedsManualLoad = false
        g.rulePackBrowserVisibleSig = nil
    elseif #packs == 0 then
        ImGui.TextDisabled('No rule packs found under lua/Turbo/rulepacks.')
        arcadeMaybePersist(g)
        return
    end

    local filterGap = math.max(ImGui.GetStyle().ItemSpacing.x, 4)
    local selectW, clearW = 72, 64
    if searchOpen then
        local filterAvailX = ImGui.GetContentRegionAvail()
        local filterAvail = tonumber(filterAvailX) or 360
        local filterW = math.max(120, filterAvail - selectW - clearW - (filterGap * 2))
        ImGui.PushItemWidth(filterW)
        local filtBuf = g.rulePackBrowserFilter
        filtBuf = inputTextHint('##rulepack_browser_filter', 'filter shown items or rules', filtBuf)
        ImGui.PopItemWidth()
        g.rulePackBrowserFilter = filtBuf
    end

    local filterLc = tostring(g.rulePackBrowserFilter or ''):lower()
    local rows = g.rulePackBrowserRows or {}
    ensureTargetIniRuleCache()

    local filteredPairs = {}
    for _, pair in ipairs(rows) do
        local nk = pair.key
        if nk and nk ~= '' then
            if filterLc == '' or nk:lower():find(filterLc, 1, true) then
                filteredPairs[#filteredPairs + 1] = pair
            end
        end
    end
    visibleSelectionSync(g, filteredPairs,
        tostring(g.rulePackBrowserPack or '') .. '\1' .. tostring(filterLc or '') .. '\1' .. tostring(#filteredPairs))

    if searchOpen then
        ImGui.SameLine(0, filterGap)
        if Ui.buttonVariant('Select##rulepack_sel_filt', 'secondaryButton', selectW, ACTION_BTN_H) then
            selClear(g)
            g.rulePackBrowserClearedSet = {}
            local cap = 250
            local nadd = 0
            for _, pair in ipairs(filteredPairs) do
                if nadd >= cap then break end
                local nk = pair.key
                if nk and nk ~= '' then
                    selAdd(g, nk)
                    nadd = nadd + 1
                end
            end
            if filteredPairs[1] then
                local fp = filteredPairs[1]
                g.rulePackBrowserSelName = fp.key
                g.rulePackBrowserSelPackRule = fp.value or ''
                syncRuleIdxFromPackRule(g, fp.value)
            end
            g.rulePackBrowserSelectMode = true
            g.statusMessage = string.format('Selected %d item(s) matching filter (max %d).', nadd, cap)
            arcadeBump(g, 18 + math.min(nadd, 140))
        end
        tip('Select all rows matching the filter string, up to 250, then use the TurboKey rule buttons.')
        ImGui.SameLine(0, filterGap)
        if Ui.buttonVariant('Clear##rulepack_clr_sel', 'secondaryButton', clearW, ACTION_BTN_H) then
            g.rulePackBrowserFilter = ''
            g.rulePackBrowserSelName = nil
            g.rulePackBrowserSelPackRule = ''
            g.rulePackBrowserSelAnchorFilteredIdx = nil
            g.rulePackBrowserVisibleSig = nil
            g.statusMessage = 'Filter cleared.'
        end
        tip('Clear the filter text.')
    end

    --- Apply rule to many names; stores undo patches (most recent write batch).
    local function applyRuleToMany(ruleLabel, names)
        ruleLabel = cleanRuleValue(ruleLabel)
        if ruleLabel == '' then return end
        if type(names) ~= 'table' or #names == 0 then
            g.statusMessage = 'Select one or more Rule Pack rows before applying a rule.'
            return
        end
    
        local MAX_RULE_APPLY_ONE_CLICK = 100
        if #names > MAX_RULE_APPLY_ONE_CLICK then
            g.statusMessage = string.format(
                'Selected %d rows. For safety, apply %d or fewer at once. Narrow the filter or select fewer rows.',
                #names,
                MAX_RULE_APPLY_ONE_CLICK
            )
            return
        end
    
        local patches = {}
        local okCount = 0
        local failed = 0
        local firstFailed = nil
        local removedAnnotations = 0
        clearedEnsure(g)
        if TG.cleanupRulePackAnnotations then
            removedAnnotations = tonumber(TG.cleanupRulePackAnnotations(packTargetPath)) or 0
        end
        for _, name in ipairs(names) do
            if name and name ~= '' then
                local oldVal = TG.readItemLimitRule(packTargetPath, name)
                if TG.writeItemLimitRule(packTargetPath, name, ruleLabel) then
                    okCount = okCount + 1
                    patches[#patches + 1] = { path = packTargetPath, item = name, oldVal = oldVal }
                    if type(g.rulePackBrowserTargetIniRules) == 'table' then
                        g.rulePackBrowserTargetIniRules[name] = ruleLabel
                    end
                    selRemove(g, name)
                    g.rulePackBrowserClearedSet[name] = true
                else
                    failed = failed + 1
                    if not firstFailed then firstFailed = name end
                end
            end
        end
        if okCount == 0 then
            g.statusMessage = string.format('Rule Pack write failed: %s to %s%s',
                ruleLabel,
                tostring(packTargetProfile or packTargetPath or 'target INI'),
                firstFailed and (' (' .. tostring(firstFailed) .. ')') or '')
            return
        end
        g.rulePackBrowserUndoPatches = patches
        for i, lab in ipairs(RULE_CHOICES) do
            if lab == ruleLabel then g.rulePackBrowserRuleIdx = i break end
        end
        local isQtyRule = tonumber(ruleLabel) ~= nil
        if failed > 0 then
            g.statusMessage = string.format('%d rules applied, %d failed writing %s%s.',
                okCount, failed, tostring(packTargetProfile or 'target INI'),
                firstFailed and ('; first failed: ' .. tostring(firstFailed)) or '')
        elseif isQtyRule then
            g.statusMessage = string.format('Applied quantity %s to %d item%s.', ruleLabel, okCount, okCount == 1 and '' or 's')
        else
            g.statusMessage = string.format('Applied %s to %d item%s.', ruleLabel, okCount, okCount == 1 and '' or 's')
        end
        if removedAnnotations > 0 then
            g.statusMessage = g.statusMessage .. string.format(' Removed %d old rule-pack note%s.',
                removedAnnotations,
                removedAnnotations == 1 and '' or 's')
        end
        bumpTargetIniRuleCache()
        arcadeBump(g, math.min(okCount * 12, 2600))
    end

    local shown = 0
    local RULEPACK_LIST_MAX = 500
    local rbRowH = (Theme.layout and Theme.layout.rowH) or 22
    local _, rbAvailH = ImGui.GetContentRegionAvail()
    local rbMinH = math.max(132, rbRowH * 7 + 8)
    local rbMaxH = math.max(170, rbRowH * 22 + 8)
    local rbReserveH = math.max(120, (ACTION_BTN_H > 0 and ACTION_BTN_H or rbRowH) * 4 + 38)
    local listH = rbMaxH
    if rbAvailH and rbAvailH > 0 then
        listH = math.max(rbMinH, math.min(rbMaxH, rbAvailH - rbReserveH))
    end
    if ImGui.BeginChild('##rulepack_browser_results', 0, listH, true) then
        local stretch = ImGuiTableFlags.SizingStretchProp or ImGuiTableFlags.SizingStretchSame
        local flags = ImGuiTableFlags.RowBg + ImGuiTableFlags.BordersInnerV + stretch
        if ImGuiTableFlags.ScrollY then flags = flags + ImGuiTableFlags.ScrollY end
        if ImGuiTableFlags.Sortable then flags = flags + ImGuiTableFlags.Sortable end
        if ImGui.BeginTable('##rulepack_browser_table', 4, flags, 0, listH) then
            local COL = ImGuiTableColumnFlags
            local noSort = COL.NoSort or 0
            local defaultSort = COL.DefaultSort or 0
            local SORT_ITEM, SORT_PACK, SORT_CURRENT = 1, 2, 3
            ImGui.TableSetupColumn('*', COL.WidthFixed + noSort, 34)
            ImGui.TableSetupColumn('Item', defaultSort, 0, SORT_ITEM)
            ImGui.TableSetupColumn('Pack', COL.WidthFixed, 76, SORT_PACK)
            ImGui.TableSetupColumn('Current', COL.WidthFixed, 82, SORT_CURRENT)
            if ImGui.TableSetupScrollFreeze then pcall(ImGui.TableSetupScrollFreeze, 0, 1) end
            ImGui.TableHeadersRow()
            local displayPairs = {}
            for i = 1, #filteredPairs do displayPairs[i] = filteredPairs[i] end
            local sortOk, sortSpecs = pcall(ImGui.TableGetSortSpecs)
            if sortOk and sortSpecs and (tonumber(sortSpecs.SpecsCount) or 0) > 0 and #displayPairs > 1 then
                table.sort(displayPairs, function(a, b)
                    local spec = sortSpecs:Specs(1)
                    local uid = spec and spec.ColumnUserID or SORT_ITEM
                    local av, bv
                    if uid == SORT_PACK then
                        av = tostring(a.value or ''):lower()
                        bv = tostring(b.value or ''):lower()
                    elseif uid == SORT_CURRENT then
                        av = tostring((g.rulePackBrowserTargetIniRules or {})[a.key] or ''):lower()
                        bv = tostring((g.rulePackBrowserTargetIniRules or {})[b.key] or ''):lower()
                    else
                        av = tostring(a.key or ''):lower()
                        bv = tostring(b.key or ''):lower()
                    end
                    if av == bv then
                        av = tostring(a.key or ''):lower()
                        bv = tostring(b.key or ''):lower()
                    end
                    if ImGuiSortDirection and spec and spec.SortDirection == ImGuiSortDirection.Descending then
                        return av > bv
                    end
                    return av < bv
                end)
                if sortSpecs.SpecsDirty then sortSpecs.SpecsDirty = false end
            end
            for i = 1, math.min(RULEPACK_LIST_MAX, #displayPairs) do
                local pair = displayPairs[i]
                local name = pair.key
                local rule = pair.value or ''
                if name and name ~= '' then
                    ImGui.TableNextRow()
                    selSetEnsure(g)
                    local inMulti = g.rulePackBrowserSelSet[name] == true
                    local isPrimary = (g.rulePackBrowserSelName == name)
                    if isPrimary then
                        ImGui.TableSetBgColor(ImGuiTableBgTarget.RowBg0, IM_COL32(36, 62, 88, 95))
                    end

                    ImGui.TableNextColumn()
                    local checked, changed = ImGui.Checkbox('##rbr_chk_' .. name, inMulti)
                    if changed == nil then changed = checked ~= inMulti end
                    if changed then
                        if checked == true then
                            clearedEnsure(g)
                            g.rulePackBrowserClearedSet[name] = nil
                            selAdd(g, name)
                        else
                            selRemove(g, name)
                            clearedEnsure(g)
                            g.rulePackBrowserClearedSet[name] = true
                        end
                        g.rulePackBrowserSelName = name
                        g.rulePackBrowserSelPackRule = rule
                        syncRuleIdxFromPackRule(g, rule)
                        g.rulePackBrowserSelAnchorFilteredIdx = i
                        g.statusMessage = string.format('Selected: %d item%s.',
                            selSetCount(g), selSetCount(g) == 1 and '' or 's')
                    end
                    tip('Check rows here, then press a TurboKey rule button.')

                    ImGui.TableNextColumn()
                    local selectableFlags = ImGuiSelectableFlags and ImGuiSelectableFlags.SpanAllColumns or 0
                    if ImGui.Selectable(name .. '##rbr_' .. name, isPrimary, selectableFlags) then
                        g.rulePackBrowserSelName = name
                        g.rulePackBrowserSelPackRule = rule
                        syncRuleIdxFromPackRule(g, rule)
                        g.rulePackBrowserSelAnchorFilteredIdx = i
                    end
                    if ImGui.IsItemHovered() and ImGui.IsMouseDoubleClicked(0) then
                        inspectItem(name)
                    end
                    if ImGui.BeginPopupContextItem('rp_ctx_' .. name) then
                        if ImGui.Selectable('Inspect##' .. name) then inspectItem(name) end
                        if ImGui.Selectable('Add to hunting list##' .. name) then
                            if TG.setHuntingTarget then TG.setHuntingTarget(name, 'Rule Pack') end
                        end
                        if ImGui.BeginMenu('Apply##' .. name) then
                            for _, lab in ipairs(RULE_CHOICES) do
                                if ImGui.MenuItem(lab) then
                                    applyRuleToMany(lab, { name })
                                end
                            end
                            ImGui.EndMenu()
                        end
                        ImGui.EndPopup()
                    end

                    ImGui.TableNextColumn()
                    textRule(rule)
                    ImGui.TableNextColumn()
                    local iniCached = g.rulePackBrowserTargetIniRules and g.rulePackBrowserTargetIniRules[name]
                    local iniStr = (iniCached ~= nil and tostring(iniCached) ~= '') and tostring(iniCached) or '-'
                    if iniCached == nil or tostring(iniCached) == '' then
                        ImGui.TextDisabled(iniStr)
                    else
                        textRule(iniStr)
                    end
                    shown = shown + 1
                end
            end
            ImGui.EndTable()
        end
        if shown == 0 then
            ImGui.TextDisabled(filterLc == '' and 'No rows in pack.' or 'No matches.')
        elseif #filteredPairs > RULEPACK_LIST_MAX then
            ImGui.TextDisabled(string.format('Showing first %d of %d filtered rows.', RULEPACK_LIST_MAX, #filteredPairs))
        end
    end
    ImGui.EndChild()

    local namesEff = selEffectiveNames(g)
    local nSel = #namesEff
    ImGui.TextColored(0.62, 0.70, 0.82, 1.0,
        (nSel > 0) and string.format('Selected: %d item%s', nSel, nSel == 1 and '' or 's') or 'Selected: none')
    ImGui.SameLine()
    ImGui.TextDisabled('Qty')
    ImGui.SameLine()
    ImGui.PushItemWidth(48)
    g.turboKeyQty = ImGui.InputText('##rulepack_qty_rule', tostring(g.turboKeyQty or '5'))
    ImGui.PopItemWidth()
    tip('Numeric ItemLimits rule. Example: 1 means keep looting until that character owns one copy.')
    ImGui.SameLine()
    if Ui.buttonVariant('Set##rulepack_qty_set', 'secondaryButton', 44, ACTION_BTN_H) then
        local num = tonumber(g.turboKeyQty)
        local selectedNow = selEffectiveNames(g)
        if #selectedNow == 0 then
            g.statusMessage = 'Select one or more Rule Pack rows before setting quantity.'
        elseif num and num > 0 then
            local qty = math.floor(num)
            g.turboKeyQty = tostring(qty)
            applyRuleToMany(tostring(qty), selectedNow)
        else
            g.statusMessage = 'Enter a valid quantity greater than 0.'
        end
    end
    tip('Apply this quantity rule to selected rows in the target INI.')
    ImGui.SameLine()
    if Ui.buttonVariant('1##rulepack_qty_1', 'secondaryButton', 28, ACTION_BTN_H) then
        g.turboKeyQty = '1'
        local selectedNow = selEffectiveNames(g)
        if #selectedNow == 0 then
            g.statusMessage = 'Quantity set to 1. Select one or more Rule Pack rows to apply it.'
        else
            applyRuleToMany('1', selectedNow)
        end
    end
    tip('Set quantity to 1 and apply it to selected rows.')

    ImGui.Dummy(0, 4)
    local tkAvail = ImGui.GetContentRegionAvail()
    local tkSp = math.max(ImGui.GetStyle().ItemSpacing.x, 4)
    local tkW = math.max(64, math.floor((tkAvail - (tkSp * 3)) / 4))
    local smallW = math.max(58, math.floor((tkW - tkSp) / 2))

    local function tkBtn(lab, rgb, hint, same)
        if same then ImGui.SameLine(0, tkSp) end
        if Ui.buttonRgb(lab .. '##rulepack_tk_' .. lab, rgb, tkW, ACTION_BTN_H) then
            applyRuleToMany(lab, selEffectiveNames(g))
        end
        tip(hint)
    end

    tkBtn('KEEP', K, 'Apply KEEP to checked rows.', false)
    tkBtn('SELL', SE, 'Apply SELL to checked rows.', true)
    tkBtn('BANK', BA, 'Apply BANK to checked rows.', true)
    tkBtn('TRIBUTE', TR, 'Apply TRIBUTE to checked rows.', true)

    tkBtn('DESTROY', D, 'Apply DESTROY to checked rows.', false)
    tkBtn('IGNORE', S, 'Apply IGNORE to checked rows.', true)
    tkBtn('ANNOUNCE', AN, 'Apply ANNOUNCE to checked rows.', true)
    ImGui.SameLine(0, tkSp)
    if Ui.buttonVariant('Select All##rulepack_select_all', 'secondaryButton', smallW, ACTION_BTN_H) then
        clearedEnsure(g)
        for _, name in ipairs(visibleNames(filteredPairs)) do
            g.rulePackBrowserClearedSet[name] = nil
            selAdd(g, name)
        end
        g.statusMessage = string.format('Selected %d visible row(s).', selSetCount(g))
    end
    tip('Check all currently visible rows.')
    ImGui.SameLine(0, tkSp)
    if Ui.buttonVariant('Clear All##rulepack_clear_all', 'secondaryButton', smallW, ACTION_BTN_H) then
        clearedEnsure(g)
        for _, name in ipairs(visibleNames(filteredPairs)) do
            selRemove(g, name)
            g.rulePackBrowserClearedSet[name] = true
        end
        g.statusMessage = 'Cleared visible rows.'
    end
    tip('Uncheck all currently visible rows.')

    ImGui.Spacing()
    local patches = g.rulePackBrowserUndoPatches
    local canUndo = type(patches) == 'table' and #patches > 0
    if not canUndo then ImGui.BeginDisabled() end
    if Ui.buttonVariant('Undo last batch##rulepack_browser_undo', 'secondaryButton', -1, ACTION_BTN_H) then
        if canUndo then
            local nPatch = #patches
            for i = nPatch, 1, -1 do
                local p = patches[i]
                if p.oldVal ~= nil then
                    TG.writeItemLimitRule(p.path, p.item, p.oldVal)
                else
                    TG.deleteItemLimitRule(p.path, p.item)
                end
            end
            g.rulePackBrowserUndoPatches = nil
            g.statusMessage = string.format('Undid %d rule write(s).', nPatch)
            bumpTargetIniRuleCache()
        end
    end
    if not canUndo then ImGui.EndDisabled() end
    tip(canUndo and string.format('Restore INI state before the last %d write(s).', #patches)
        or 'No rule-pack batch to undo yet.')

    arcadeMaybePersist(g)
end

return M
