--[[
  Turbo View — Mini Bar
  ---------------------
  @version lua/Turbo/ui/views/mini.lua 1.0.1

  Compact floating bar: Turbo toggle, active looter picker, Loot button,
  skip chip, expand-to-full. Shows the quick-roster editor popup.
]]

local ImGui = require('ImGui')

local M = {}

local function drawLootSweepBorder(rt)
    if not (rt and rt.lootAnimationActive) then return end
    if rt.miniLootAnimation == false then return end

    local drawList = ImGui.GetWindowDrawList()
    if not drawList then return end

    local x, y = ImGui.GetWindowPos()
    local w, h = ImGui.GetWindowSize()
    w = tonumber(w) or 0
    h = tonumber(h) or 0
    if w <= 8 or h <= 8 then return end

    local pad = 1.0
    local x1, y1 = x + pad, y + pad
    local x2, y2 = x + w - pad, y + h - pad
    local ww, hh = x2 - x1, y2 - y1
    local perimeter = 2 * (ww + hh)
    if perimeter <= 0 then return end

    local t = tonumber(rt.nowMS) or 0
    local head = ((t % 1450) / 1450) * perimeter
    local sweepLen = perimeter * 0.42
    local segmentCount = 20
    local segLen = math.max(6, sweepLen / segmentCount)

    local function pointAt(d)
        d = d % perimeter
        if d <= ww then
            return x1 + d, y1
        end
        d = d - ww
        if d <= hh then
            return x2, y1 + d
        end
        d = d - hh
        if d <= ww then
            return x2 - d, y2
        end
        d = d - ww
        return x1, y2 - d
    end

    drawList:AddRect(ImVec2(x1 - 2, y1 - 2), ImVec2(x2 + 2, y2 + 2), IM_COL32(75, 125, 195, 95), 8, 0, 3.0)
    drawList:AddRect(ImVec2(x1, y1), ImVec2(x2, y2), IM_COL32(255, 188, 72, 95), 7, 0, 1.5)

    for i = 0, segmentCount - 1 do
        local a = 1.0 - (i / segmentCount)
        local startD = head - (i * segLen * 0.72)
        local endD = startD - (segLen * 0.82)
        local sx, sy = pointAt(startD)
        local ex, ey = pointAt(endD)
        local r = math.floor(255 - (105 * (1 - a)))
        local g = math.floor(212 - (92 * (1 - a)))
        local b = math.floor(86 + (132 * (1 - a)))
        local alpha = math.floor(255 * math.max(0.16, a))
        local thick = 2.4 + (2.8 * a)
        drawList:AddLine(ImVec2(sx, sy), ImVec2(ex, ey), IM_COL32(r, g, b, alpha), thick)
    end

    do
        local hx, hy = pointAt(head)
        drawList:AddCircleFilled(ImVec2(hx, hy), 3.6, IM_COL32(255, 228, 125, 245), 10)
        drawList:AddCircleFilled(ImVec2(hx, hy), 6.0, IM_COL32(90, 165, 230, 80), 12)
    end
end

function M.render(state, actions, ui)
    local g = state.raw
    local rt = state.runtime

    ImGui.PushStyleVar(ImGuiStyleVar.WindowBorderSize, 2.5)
    ImGui.PushStyleVar(ImGuiStyleVar.FramePadding, 5, 4)
    ImGui.PushStyleColor(ImGuiCol.WindowBg, IM_COL32(24, 28, 44, 248))
    ImGui.PushStyleColor(ImGuiCol.Border, IM_COL32(255, 188, 72, 240))
    local shouldDraw
    g.windowOpen, shouldDraw = ImGui.Begin('Turbo###Turbo_Mini', g.windowOpen,
        bit32.bor(ImGuiWindowFlags.AlwaysAutoResize, ImGuiWindowFlags.NoResize, ImGuiWindowFlags.NoTitleBar))
    if shouldDraw == nil then shouldDraw = g.windowOpen end
    if shouldDraw then
        pcall(function()
            local wx, wy = ImGui.GetWindowPos()
            if wx and wy then g.miniWindowPos = { x = wx, y = wy } end
        end)

        local function sp4() ImGui.SameLine(0, 4) end
        local function sp6() ImGui.SameLine(0, 6) end
        local function miniButton(label, variant, width)
            return ui.buttonVariant(label, variant, width or 0, 24)
        end

        if g.turboUpdateAvailable == true then
            if miniButton('Update##mini_turbo_update', 'amberButton', 64) then
                if actions.openTurboPatcher then
                    actions.openTurboPatcher()
                elseif type(g.openTurboPatcherExternal) == 'function' then
                    g.openTurboPatcherExternal()
                end
            end
            actions.tip(string.format(
                'Turbo update available (v%s). Opens TurboPatcher.',
                tostring(g.remoteTurboVersion or '?')))
            sp6()
        end

        local canControl = true
        if type(actions.canSharedControlWrite) == 'function' then
            canControl = actions.canSharedControlWrite() == true
        elseif type(g.isSharedControlOwner) == 'function' then
            canControl = g.isSharedControlOwner() == true
        end
        local ownerName = 'driver'
        if type(actions.sharedControlOwnerName) == 'function' then
            ownerName = actions.sharedControlOwnerName()
        elseif type(g.sharedControlOwnerName) == 'function' then
            ownerName = g.sharedControlOwnerName()
        end
        local routeWarning = rt.turboOn and rt.lootReady == false
        local turboLabel = rt.turboOn and (routeWarning and ' ON !##mturbo' or ' ON ##mturbo') or ' OFF##mturbo'
        local turboVariant = rt.turboOn and (routeWarning and 'amberButton' or 'successButton') or 'dangerButton'
        local turboTip = (rt.turboOn and rt.lootReady == false)
            and (rt.lootReadyReason or 'Turbo is enabled, but no valid looter route is ready.')
            or 'Turn Turbo auto-looting on or off. Turning it off also sends /endmacro to the active looters.'
        if not canControl then
            turboLabel = rt.turboOn and ' ON ##mturbo' or ' OFF##mturbo'
            turboVariant = 'amberButton'
            turboTip = ('Turbo is %s, but this box is browse-only. %s owns Turbo control; switch to that box to turn looting on or off.')
                :format(rt.turboOn and 'ON' or 'OFF', tostring(ownerName or 'the driver'))
        end
        if miniButton(turboLabel, turboVariant) then
            actions.toggleTurboFromMini(rt)
        end
        actions.tip(turboTip)

        sp6()
        local rawLooter = rt.currentLooter or g.selectedChar or g.savedDefaultLooter or ''
        if rawLooter:find('${', 1, true) then rawLooter = 'NOBODY' end
        if rawLooter == '' or rawLooter == 'NOBODY' then
            rawLooter = g.selectedChar or g.savedDefaultLooter or 'NOBODY'
        end
        local modeStr = rt.lootAllOn and 'ALL'
            or (rt.multiModeOn and ('MULTI:' .. #rt.multiLooters) or rawLooter)
        local noLooter = (modeStr == '' or modeStr == 'NOBODY')
        local looterLabel = noLooter and 'Set Looter##mlooter' or (modeStr .. '##mlooter')
        if miniButton(looterLabel,
            noLooter and 'amberButton' or 'secondaryButton') then
            actions.toggleMiniLooterPicker()
        end
        actions.tip(noLooter
            and 'No looter set. Click to choose a single looter quickly.'
            or 'Click to switch the active looter quickly. Choosing a character switches to Single mode.')

        sp6()
        if rt.lootReady == false then ImGui.BeginDisabled() end
        if miniButton(' Loot ##mloot', 'primaryButton') then
            actions.lootNow()
        end
        if rt.lootReady == false then ImGui.EndDisabled() end
        actions.tip((rt.lootReady == false)
            and (rt.lootReadyReason or 'No valid looter route is ready.')
            or 'Run TurboLoot for the current active looter targets.')

        if rt.skipPendingCount ~= nil then
            sp4()
            local hasSkips = rt.skipPendingCount > 0
            local skipLabel = hasSkips and (tostring(rt.skipPendingCount) .. '##skipchip') or '--##skipchip'
            if miniButton(skipLabel, hasSkips and 'miniCountButton' or 'secondaryButton', 46) then
                if actions.toggleReviewWindowFromMini then
                    actions.toggleReviewWindowFromMini(hasSkips)
                else
                    actions.expandFromMini('review', hasSkips, 'review')
                end
            end
            actions.tip(hasSkips
                and 'Toggle skipped item review.'
                or 'No skipped items waiting for review.')
        end

        sp4()
        --- Keep '+' distinct from ImGui's native top-left collapse arrow.
        if miniButton(' + ##expand', 'windowToggleButton', 52) then
            actions.expandFromMini(state.layoutState.lastRelevantTab)
        end
        actions.tip('Expand to the Full panel.')

        -- TurboGains line: pulled in inline so the mini view stays self-contained.
        -- The view module reads the combined tracker live-state file.
        do
            local okMV, MoneyView = pcall(require, 'Turbo.gains_view')
            if okMV and MoneyView and MoneyView.renderMiniLine then
                pcall(MoneyView.renderMiniLine, {
                    tooltip = 'Open TurboGains.',
                    onClick = function()
                        g.gainsWindowOpen = true
                        g.gainsWindowOpenReason = 'mini gains line'
                        g.gainsWindowOpenAt = os.time()
                        g.toolsSubTab = 'gains'
                        g.minimizedGUI = false
                        g.statusMessage = 'Turbo Gains opened.'
                        if actions.expandFromMini then actions.expandFromMini('tools') end
                        if g.saveSettings then g.saveSettings() end
                    end,
                })
            end
        end

        if g.showMiniLooterPicker then
            ImGui.Dummy(0, 6)
            ui.separator(58, 66, 90, 110)
            ImGui.TextColored(0.62, 0.70, 0.86, 1.0, 'Loot mode')
            actions.tip('Choose Single, Multi, or All, then use the roster below.')

            local modeVariant = rt.lootAllOn and 'amberButton' or (rt.multiModeOn and 'secondaryButton' or 'primaryButton')
            if ui.buttonVariant('Single##mini_mode_single', not rt.lootAllOn and not rt.multiModeOn and 'primaryButton' or 'secondaryButton', 62, 0) then
                actions.setMiniLootMode('single')
            end
            actions.tip('Use one active looter.')
            sp4()
            if ui.buttonVariant('Multi##mini_mode_multi', rt.multiModeOn and 'primaryButton' or 'secondaryButton', 58, 0) then
                actions.setMiniLootMode('multi')
            end
            actions.tip('Use more than one looter from your quick roster.')
            sp4()
            if ui.buttonVariant('All##mini_mode_all', rt.lootAllOn and 'amberButton' or 'secondaryButton', 46, 0) then
                actions.setMiniLootMode('all')
            end
            actions.tip('Every current group member loots.')

            local viable = {}
            for _, name in ipairs(g.members or {}) do
                if name ~= 'NOBODY' and name ~= '' then
                    viable[#viable + 1] = name
                end
            end
            local roster = {}
            local hasRoster = false
            for _, name in ipairs(viable) do
                if g.quickLootRoster and g.quickLootRoster[name] then
                    hasRoster = true
                    break
                end
            end
            for _, name in ipairs(viable) do
                if not hasRoster or (g.quickLootRoster and g.quickLootRoster[name]) then
                    roster[#roster + 1] = name
                end
            end
            local selectedName = rawLooter ~= '' and rawLooter or g.selectedChar or g.savedDefaultLooter or 'NOBODY'
            local perRow = 3
            local shown = 0
            local groupCount = #roster > 0 and #roster or #(g.members or {})
            local multiLookup = {}
            for _, name in ipairs(rt.multiLooters or {}) do
                multiLookup[name] = true
            end

            ImGui.Dummy(0, 4)
            local popupSummary = rt.lootAllOn and string.format('All: %d group member%s',
                groupCount, groupCount == 1 and '' or 's')
                or (rt.multiModeOn and string.format('Multi: %d selected', #(rt.multiLooters or {}))
                    or ('Single: ' .. ((selectedName ~= '' and selectedName ~= 'NOBODY') and selectedName or 'No looter set')))
            ImGui.TextColored(0.82, 0.82, 0.75, 1.0, popupSummary)

            if rt.lootAllOn then
                ImGui.Dummy(0, 4)
                ImGui.TextColored(0.45, 0.48, 0.55, 1.0, 'All current group members will loot.')
            elseif #roster > 0 then
                ImGui.Dummy(0, 4)
                ImGui.TextColored(0.60, 0.68, 0.84, 1.0, 'Active looters')
                ImGui.Dummy(0, 2)
                for i, name in ipairs(roster) do
                    if shown > 0 then
                        sp4()
                    end
                    local variant = 'secondaryButton'
                    if rt.multiModeOn and rt.multiLooters then
                        variant = multiLookup[name] and 'successButton' or 'secondaryButton'
                    elseif name == selectedName then
                        variant = 'primaryButton'
                    end
                    if ui.buttonVariant(name .. '##mini_pick_' .. name, variant) then
                        actions.setMiniLooter(name, rt)
                    end
                    actions.tip(
                        (rt.multiModeOn and ('Toggle ' .. name .. ' in the Multi looter set.'))
                        or ('Switch the active single looter to ' .. name .. '.'))
                    shown = shown + 1
                    if (shown % perRow) == 0 and i < #roster then
                        shown = 0
                        ImGui.Dummy(0, 4)
                    end
                end
            end

            if #roster == 0 then
                ImGui.TextColored(0.72, 0.64, 0.42, 1.0, 'No quick roster yet. Add names below or use Setup to choose which characters appear here.')
            elseif not rt.lootAllOn then
                ImGui.Dummy(0, 4)
                ImGui.TextColored(0.45, 0.48, 0.55, 1.0,
                    rt.multiModeOn and 'Multi: toggle any roster names on or off.'
                        or 'Single: pick one roster name.')
            end

            if not rt.lootAllOn then
                ImGui.Dummy(0, 6)
                ui.separator(58, 66, 90, 110)
                ImGui.TextColored(0.60, 0.68, 0.84, 1.0, 'Quick roster')
                ImGui.SameLine(0, 8)
                if ui.buttonVariant((g.showMiniRosterEditor and 'Done##mini_roster_edit' or 'Edit roster##mini_roster_edit'), 'secondaryButton') then
                    actions.toggleMiniRosterEditor()
                end
                actions.tip('Add or remove names from the Mini quick looter roster.')
                if not g.showMiniRosterEditor then
                    ImGui.Dummy(0, 2)
                    ImGui.TextColored(0.45, 0.48, 0.55, 1.0, 'Choose which names appear in Mini quick selection.')
                end
            end

            if g.showMiniRosterEditor and not rt.lootAllOn then
                ImGui.Dummy(0, 6)
                ImGui.Dummy(0, 2)
                ImGui.TextColored(0.45, 0.48, 0.55, 1.0,
                    hasRoster
                        and 'Click a name to add or remove it from Mini quick selection.'
                        or 'No roster is configured yet, so Mini shows every viable looter. Click a name to hide it.')
                ImGui.Dummy(0, 4)
                local shownEdit = 0
                local editPerRow = 3
                for i, name in ipairs(viable) do
                    if shownEdit > 0 then
                        sp4()
                    end
                    local inRoster = hasRoster and g.quickLootRoster and g.quickLootRoster[name] or true
                    if ui.buttonVariant(name .. '##mini_roster_toggle_' .. name, inRoster and 'primaryButton' or 'secondaryButton') then
                        actions.toggleMiniQuickRosterMember(name)
                    end
                    actions.tip((inRoster and 'Remove ' or 'Add ') .. name .. ' from the Mini quick looter roster.')
                    shownEdit = shownEdit + 1
                    if (shownEdit % editPerRow) == 0 and i < #viable then
                        shownEdit = 0
                        ImGui.Dummy(0, 4)
                    end
                end
            end
        end

        drawLootSweepBorder(rt)
    end
    ImGui.End()
    ImGui.PopStyleColor(2)
    ImGui.PopStyleVar(2)
end

return M
