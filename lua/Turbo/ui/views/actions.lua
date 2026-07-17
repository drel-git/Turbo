--[[
  Turbo View — Actions Tab
  ------------------------
  @version lua/Turbo/ui/views/actions.lua 1.3.0

  Full-GUI Actions tab renderer: TurboLoot/TurboGive/Currency button grids,
  cursor-hand panel, status message. All colors via Theme.col; all button
  variants via Theme.component.
]]

local ImGui = require('ImGui')

local M = {}

function M.render(state, actions)
    local g = state.raw
    local rt = state.runtime
    local Colors = actions.Colors
    local ACTION_BTN_H = actions.ACTION_BTN_H

    local meName = actions.mq.TLO.Me.Name() or 'Self'
    local runMode = g.actionRunMode or 'self'
    if type(g.actionRunTargets) ~= 'table' then g.actionRunTargets = {} end
    local botTargets = {}
    for _, name in ipairs(g.members or {}) do
        if name and name ~= '' and name ~= meName then botTargets[#botTargets + 1] = name end
    end

    local liveBots = {}
    for _, name in ipairs(botTargets) do liveBots[name] = true end
    for name in pairs(g.actionRunTargets) do
        if not liveBots[name] then g.actionRunTargets[name] = nil end
    end

    local function selectedCount()
        local n = 0
        for _, name in ipairs(botTargets) do
            if g.actionRunTargets[name] then n = n + 1 end
        end
        return n
    end

    local canSharedWrite = true
    if type(actions.canSharedControlWrite) == 'function' then
        canSharedWrite = actions.canSharedControlWrite() ~= false
    end
    local function needSharedControl(actionName)
        if canSharedWrite then return true end
        if type(actions.requireSharedControl) == 'function' then
            return actions.requireSharedControl(actionName)
        end
        g.statusMessage = tostring(actionName or 'This action') .. ' requires Turbo control.'
        return false
    end

    if (runMode == 'group' or runMode == 'all') and #botTargets == 0 then runMode = 'self'; g.actionRunMode = 'self' end
    if not canSharedWrite and runMode ~= 'self' then
        runMode = 'self'
        g.actionRunMode = 'self'
    end

    local broadcastMode = runMode ~= 'self'
    local warnRgb = {145, 105, 45}
    local warnText = {0.95, 0.76, 0.42, 1.0}
    local GRID_GAP = 4
    local MIN_ACTION_W = 78
    local MIN_TOOL_W = 82
    local MELEE_TOGGLE_COOLDOWN_MS = 5000
    local LOOT_TOGGLE_COOLDOWN_MS = 3000

    local function luaScriptRunning(scriptName)
        local names = type(scriptName) == 'table' and scriptName or { scriptName }
        local lua = actions.mq.TLO.Lua
        local function statusIsRunning(status)
            local text = tostring(status or ''):lower()
            if text == '' then return false end
            if text:find('not', 1, true) or text:find('stop', 1, true) or text:find('ended', 1, true) or text:find('ending', 1, true) then return false end
            return text == 'running' or text == 'run' or text:find('running', 1, true) ~= nil
        end
        for _, name in ipairs(names) do
            local ok, status = pcall(function()
                if not lua or not lua.Script then return '' end
                local script = lua.Script(name)
                if not script or not script.Status then return '' end
                return script.Status() or ''
            end)
            if ok and statusIsRunning(status) then return true end
            if actions.mq.parse then
                local okParse, parsed = pcall(function()
                    return actions.mq.parse(string.format('${Lua.Script[%s].Status}', tostring(name)))
                end)
                if okParse and statusIsRunning(parsed) then return true end
            end
        end
        return false
    end

    local function setRunMode(mode)
        if mode ~= 'self' and not needSharedControl('Run As ' .. tostring(mode)) then
            mode = 'self'
        end
        g.actionRunMode = mode
        runMode = mode
        broadcastMode = runMode ~= 'self'
    end

    local function targetList()
        local out = {}
        if runMode == 'group' then
            for _, name in ipairs(botTargets) do out[#out + 1] = name end
        elseif runMode == 'multi' then
            for _, name in ipairs(botTargets) do
                if g.actionRunTargets[name] then out[#out + 1] = name end
            end
        end
        return out
    end

    local function modeButton(label, mode, w, tooltip)
        local active = runMode == mode
        local variant = active and 'primaryButton' or 'secondaryButton'
        local locked = mode ~= 'self' and not canSharedWrite
        if locked then ImGui.BeginDisabled() end
        if actions.Ui.buttonVariant(label .. '##runmode_' .. mode, variant, w, 24) then
            setRunMode(mode)
        end
        if locked then ImGui.EndDisabled() end
        actions.tip(locked and ('Take Turbo control to use ' .. label .. ' scope.') or tooltip)
    end

    local function targetChip(name, width)
        local active = g.actionRunTargets[name] == true
        local variant = active and 'primaryButton' or 'secondaryButton'
        local label = actions.Ui.fitLabel(name .. '##action_target_' .. name, name:sub(1, 6), width or 82)
        if actions.Ui.buttonVariant(label, variant, width, 24) then
            g.actionRunTargets[name] = not active or nil
            if selectedCount() > 0 then setRunMode('multi') end
        end
        actions.tip(name)
    end

    local function drawRunAsPanel()
        local avail = ImGui.GetContentRegionAvail()
        local cols, modeW, gap = actions.Ui.adaptiveColumns(4, 58, GRID_GAP, math.min(avail, 360))

        ImGui.TextColored(broadcastMode and warnText[1] or 0.66, broadcastMode and warnText[2] or 0.70,
            broadcastMode and warnText[3] or 0.78, 1.0, 'Run as:')
        ImGui.SameLine()
        local scopeText = 'self: ' .. meName
        if runMode == 'multi' then
            scopeText = string.format('picks: %d', selectedCount())
        elseif runMode == 'group' then
            scopeText = string.format('group: %d bots', #botTargets)
        elseif runMode == 'all' then
            scopeText = 'all zone'
        end
        ImGui.TextColored(broadcastMode and warnText[1] or 0.45, broadcastMode and warnText[2] or 0.48,
            broadcastMode and warnText[3] or 0.52, 1.0, scopeText)
        actions.Ui.gridSameLine(1, cols, gap)
        modeButton('Self', 'self', modeW, 'This character only.')
        actions.Ui.gridSameLine(2, cols, gap)
        modeButton('Picks', 'multi', modeW, 'Picked targets only.')
        actions.Ui.gridSameLine(3, cols, gap)
        modeButton('Group', 'group', modeW, 'Current group.')
        actions.Ui.gridSameLine(4, cols, gap)
        modeButton('All', 'all', modeW, 'All E3 bots in zone.')

        local pickCols, pickW, pickGap = actions.Ui.adaptiveColumns(4, 74, GRID_GAP)
        local rows = math.max(1, math.ceil(math.max(#botTargets, 1) / math.max(1, pickCols)))
        local detailH = math.max(82, math.min(118, 22 + (rows * 28)))
        if ImGui.BeginChild('##actions_runas_detail', 0, detailH, false) then
            if runMode == 'multi' then
                ImGui.TextColored(0.55, 0.58, 0.65, 1.0, 'Targets')
                if #botTargets == 0 then
                    ImGui.SameLine()
                    ImGui.TextColored(0.55, 0.58, 0.65, 1.0, 'No bots found')
                else
                    for i, name in ipairs(botTargets) do
                        actions.Ui.gridSameLine(i, pickCols, pickGap)
                        targetChip(name, pickW)
                    end
                end
            elseif runMode == 'group' then
                ImGui.TextColored(warnText[1], warnText[2], warnText[3], 1.0,
                    string.format('Targets: group bots (%d)', #botTargets))
            elseif runMode == 'all' then
                ImGui.TextColored(warnText[1], warnText[2], warnText[3], 1.0, 'Targets: all E3 bots in zone')
            else
                ImGui.TextColored(0.55, 0.58, 0.65, 1.0, 'Targets: this character')
            end
        end
        ImGui.EndChild()
    end

    local function commandForMode(cmd, opts)
        opts = opts or {}
        if type(opts.commands) == 'table' then
            return opts.commands[runMode] or cmd
        end
        return cmd
    end

    local function syncTurboLootProfileFor(name, delayDs)
        if type(actions.turboLootProfileForCharacter) ~= 'function' then return nil end
        local profile = actions.turboLootProfileForCharacter(name)
        profile = tostring(profile or ''):match('^%s*(.-)%s*$') or ''
        if profile == '' then return nil end
        if delayDs and delayDs > 0 then
            actions.mq.cmdf('/timed %d /squelch /e3bct %s /e3varset TurboLootIni %s', delayDs, name, profile)
        elseif name and name ~= '' and name ~= meName then
            actions.mq.cmdf('/squelch /e3bct %s /e3varset TurboLootIni %s', name, profile)
        else
            actions.mq.cmdf('/squelch /e3varset TurboLootIni %s', profile)
        end
        return profile
    end

    local function sendCommand(label, cmd, opts)
        opts = opts or {}
        cmd = commandForMode(cmd, opts)
        local displayLabel = label:match('^(.-)##') or label
        local syncProfile = opts.syncTurboLootProfile == true
        if runMode == 'self' then
            local profile = syncProfile and syncTurboLootProfileFor(meName) or nil
            if profile then
                actions.mq.cmd('/timed 2 ' .. cmd)
                g.statusMessage = string.format('%s sent using %s.', displayLabel, profile)
            else
                actions.mq.cmd(cmd)
                g.statusMessage = displayLabel .. ' sent.'
            end
            return
        end
        if type(opts.localModes) == 'table' and opts.localModes[runMode] == true then
            actions.mq.cmd(cmd)
            if runMode == 'all' then
                g.statusMessage = displayLabel .. ' sent to all E3 bots.'
            elseif runMode == 'group' then
                g.statusMessage = displayLabel .. ' sent to group.'
            else
                g.statusMessage = displayLabel .. ' sent.'
            end
            return
        end
        if runMode == 'all' and opts.broadcast == true then
            if syncProfile and type(actions.syncProfileAssignments) == 'function' then
                actions.syncProfileAssignments()
                actions.mq.cmd('/timed 2 /e3bcaa ' .. cmd)
                g.statusMessage = displayLabel .. ' sent to all E3 bots with assigned INIs.'
            else
                actions.mq.cmd('/e3bcaa ' .. cmd)
                g.statusMessage = displayLabel .. ' sent to all E3 bots.'
            end
            return
        end
        local targets = targetList()
        if runMode == 'multi' and #targets == 0 then
            g.statusMessage = 'Pick one or more targets first.'
            return
        end
        if runMode == 'all' and #targets == 0 then
            g.statusMessage = 'All scope is not available for this action.'
            return
        end
        local sent = 0
        for _, name in ipairs(targets) do
            local baseDelay = sent * 5
            if syncProfile then
                syncTurboLootProfileFor(name, baseDelay)
                actions.mq.cmdf('/timed %d /squelch /e3bct %s %s', baseDelay + 2, name, cmd)
            else
                actions.mq.cmdf('/timed %d /squelch /e3bct %s %s', baseDelay, name, cmd)
            end
            sent = sent + 1
        end
        if syncProfile then
            g.statusMessage = string.format('%s sent to %d bot%s with assigned INIs.',
                displayLabel, sent, sent == 1 and '' or 's')
        else
            g.statusMessage = string.format('%s sent to %d bot%s.', displayLabel, sent, sent == 1 and '' or 's')
        end
    end

    local function scopedButton(label, cmd, color, tooltipText, btnW, btnH, opts)
        opts = opts or {}
        local enabled = (not broadcastMode) or opts.broadcast == true or opts.allLocal == true
        if runMode == 'all' and opts.allLocal ~= true and opts.broadcast ~= true then enabled = false end
        if enabled and broadcastMode and not canSharedWrite then enabled = false end
        if enabled and opts.sharedControlAlways == true and not canSharedWrite then enabled = false end
        if not enabled then ImGui.BeginDisabled() end
        local buttonColor = broadcastMode and (opts.broadcast or opts.allLocal) and warnRgb or color
        local clicked = actions.actionButton(label, nil, buttonColor, nil, nil, nil, btnW, btnH, function()
            if opts.confirmTitle and g.confirmSingleReviewRules ~= false then
                g.actionConfirm = {
                    title = opts.confirmTitle,
                    body = opts.confirmBody or 'Confirm this action?',
                    label = label,
                    cmd = cmd,
                    opts = opts,
                }
                ImGui.OpenPopup('Confirm Action')
            else
                sendCommand(label, cmd, opts)
            end
        end)
        if not enabled then ImGui.EndDisabled() end
        if enabled and tooltipText then
            actions.tip(tooltipText)
        elseif not enabled and ImGui.IsItemHovered((ImGuiHoveredFlags and ImGuiHoveredFlags.AllowWhenDisabled) or 128) then
            ImGui.BeginTooltip()
            ImGui.Text(label:match('^(.-)##') or label)
            local lockedTip = (broadcastMode and not canSharedWrite) and
                ('Take Turbo control to use ' .. tostring(runMode) .. ' scope.')
                or (opts.sharedControlAlways == true and not canSharedWrite and 'Take Turbo control to run this shared action.')
                or opts.disabledTip
                or 'Self only.'
            ImGui.TextColored(0.92, 0.45, 0.40, 1.0, lockedTip)
            ImGui.EndTooltip()
        end
        return clicked
    end

    local function drawScopedGrid(buttons, desiredCols, minW, height)
        local cols, btnW, gap = actions.Ui.adaptiveColumns(desiredCols, minW or MIN_ACTION_W, GRID_GAP)
        for i, btn in ipairs(buttons) do
            actions.Ui.gridSameLine(i, cols, gap)
            scopedButton(btn.label, btn.cmd, btn.color, btn.tooltip, btnW, height or ACTION_BTN_H, btn.opts)
            if btn.after then btn.after() end
        end
    end

    local function drawVariantGrid(buttons, desiredCols, minW, height)
        local hoveredDisabled = (ImGuiHoveredFlags and ImGuiHoveredFlags.AllowWhenDisabled) or 128
        local cols, btnW, gap = actions.Ui.adaptiveColumns(desiredCols, minW or MIN_TOOL_W, GRID_GAP)
        for i, btn in ipairs(buttons) do
            actions.Ui.gridSameLine(i, cols, gap)
            local label = actions.Ui.fitLabel(btn.label, btn.shortLabel, btnW)
            local disabled = btn.isDisabled == true or (btn.isDisabled and btn.isDisabled() or false)
            if disabled then ImGui.BeginDisabled() end
            if actions.Ui.buttonIntent(label, btn.intent or btn.variant or 'neutral', btnW, height or ACTION_BTN_H) then
                if btn.onClick and not disabled then btn.onClick() end
            end
            if disabled then ImGui.EndDisabled() end
            if disabled and btn.disabledTip then
                if ImGui.IsItemHovered(hoveredDisabled) then
                    ImGui.BeginTooltip()
                    ImGui.Text(btn.label:match('^(.-)##') or btn.label)
                    ImGui.TextColored(0.72, 0.68, 0.62, 1.0, btn.disabledTip)
                    ImGui.EndTooltip()
                end
            elseif btn.tooltip then actions.tip(btn.tooltip) end
        end
    end

    local function drawCommandGrid(buttons, desiredCols, minW, height)
        local cols, btnW, gap = actions.Ui.adaptiveColumns(desiredCols, minW or MIN_ACTION_W, GRID_GAP)
        for i, btn in ipairs(buttons) do
            actions.Ui.gridSameLine(i, cols, gap)
            actions.actionButton(btn.label, btn.cmd, btn.color, nil, nil, btn.tooltip, btnW, height or ACTION_BTN_H, btn.onClick)
        end
    end

    local function drawActionConfirmPopup()
        if g.confirmSingleReviewRules == false then
            g.actionConfirm = nil
            return
        end
        if ImGui.BeginPopupModal('Confirm Action') then
            local pending = g.actionConfirm or {}
            ImGui.Text(pending.title or 'Confirm Action')
            ImGui.Separator()
            ImGui.Text(pending.body or 'Confirm this action?')
            ImGui.Dummy(0, 6)
            if ImGui.Button('Confirm##actions_confirm', 120, ACTION_BTN_H) then
                if pending.cmd then sendCommand(pending.label or pending.title or 'Action', pending.cmd, pending.opts) end
                g.actionConfirm = nil
                ImGui.CloseCurrentPopup()
            end
            ImGui.SameLine()
            if ImGui.Button('Cancel##actions_confirm', 120, ACTION_BTN_H) then
                g.actionConfirm = nil
                ImGui.CloseCurrentPopup()
            end
            ImGui.EndPopup()
        end
    end

    local function selectedToolCharacter()
        local name = tostring(g.toolsCharacterName or g.toolsOpenE3TargetName or meName or ''):match('^%s*(.-)%s*$') or ''
        if name == '' then name = meName end
        g.toolsCharacterName = name
        return name
    end

    local function meleeToggleButton(idSuffix)
        local meleeNow = actions.mq.gettime and actions.mq.gettime() or 0
        local meleeCoolingDown = meleeNow < (tonumber(g.meleeToggleBlockUntilMS) or 0)
        local meleeRemainS = meleeCoolingDown
            and math.max(1, math.ceil(((tonumber(g.meleeToggleBlockUntilMS) or 0) - meleeNow) / 1000))
            or nil
        local meleeLabel = rt.meleeDistFar and 'Melee is Max' or 'Melee is 10'
        return {
            label = meleeLabel .. '##' .. tostring(idSuffix or 'melee_dist'),
            intent = 'utility',
            tooltip = (rt.meleeDistFar and 'Mono shows MaxMelee; label may lag refresh ~1s. '
                    or 'Mono shows fixed 10; label may lag refresh ~1s. ')
                    .. 'Click runs ToggleMeleeDist per bot: /e3varset MeleeDistFar, flips [Assist Settings] 10 <-> MaxMelee, merges [Startup Commands] TurboMelee_*; one /g line. Flip applies this session; new startup helper lines apply on the next E3 load.',
            disabledTip = meleeCoolingDown
                and string.format(
                    'Wait %ds. Already sent a melee toggle; each bot flips its own INI once.',
                    meleeRemainS or 1)
                or nil,
            isDisabled = function()
                local t = actions.mq.gettime and actions.mq.gettime() or 0
                return t < (tonumber(g.meleeToggleBlockUntilMS) or 0)
            end,
            onClick = function()
                local started = actions.mq.gettime and actions.mq.gettime() or 0
                if started < (tonumber(g.meleeToggleBlockUntilMS) or 0) then return end
                g.meleeToggleBlockUntilMS = started + MELEE_TOGGLE_COOLDOWN_MS
                actions.mq.cmd('/e3bcaa /lua run ToggleMeleeDist toggle')
                g.statusMessage = 'Melee toggle sent (INI flip per melee bot - see group).'
            end,
        }
    end

    local function drawToolCharacterSelector()
        local names = {}
        if actions.onlineCharacters then
            names = actions.onlineCharacters() or {}
        end
        local seen = {}
        local function addName(name)
            name = tostring(name or ''):match('^%s*(.-)%s*$') or ''
            if name == '' or seen[name:lower()] then return end
            seen[name:lower()] = true
            names[#names + 1] = name
        end
        local supplied = names
        names = {}
        addName(meName)
        for _, name in ipairs(supplied or {}) do addName(name) end
        for _, name in ipairs(g.members or {}) do addName(name) end

        local currentPick = selectedToolCharacter()
        if not seen[currentPick:lower()] then addName(currentPick) end

        ImGui.TextColored(0.66, 0.72, 0.82, 1.0, 'Character:')
        ImGui.SameLine()
        ImGui.PushItemWidth(math.max(160, ImGui.GetContentRegionAvail()))
        if ImGui.BeginCombo('##tools_character_select', currentPick ~= '' and currentPick or 'Choose character') then
            for _, name in ipairs(names) do
                if ImGui.Selectable(name .. '##tools_character_' .. name, currentPick == name) then
                    g.toolsCharacterName = name
                    g.toolsOpenE3TargetName = name
                end
            end
            ImGui.EndCombo()
        end
        ImGui.PopItemWidth()
        actions.tip('Select the character used by Open TL INI, Open E3 INI, Backup TL INI, Backup E3 INI, and Backup eqclient.ini. The list uses this character plus online EQBC/DanNet peers when available.')
    end

    local function drawFileOpenRow()
        local targetName = selectedToolCharacter()
        actions.thinSep('utility', 'Open files and folders')
        drawVariantGrid({
            {
                label = 'Open TL INI##tools_open_tl_ini',
                intent = 'utility',
                tooltip = 'Open the selected character\'s assigned TurboLoot INI profile in your default editor. For remote bots this uses Turbo\'s known profile assignment.',
                onClick = function()
                    if actions.openTurbolootIniForCharacter then
                        actions.openTurbolootIniForCharacter(targetName)
                    elseif actions.openActiveIni then
                        actions.openActiveIni()
                    end
                end,
            },
            {
                label = 'Open E3 INI##tools_open_e3',
                intent = 'utility',
                tooltip = 'Open the selected character\'s E3 INI in your default editor.',
                onClick = function() if actions.openCharacterE3Ini then actions.openCharacterE3Ini(targetName) end end,
            },
            {
                label = 'Config Folder##tools_open_config',
                intent = 'utility',
                tooltip = 'Open this MacroQuest install\'s Config folder.',
                onClick = function() if actions.openConfigFolder then actions.openConfigFolder() end end,
            },
            {
                label = 'Macros Folder##tools_open_macros',
                intent = 'utility',
                tooltip = 'Open this MacroQuest install\'s Macros folder.',
                onClick = function() if actions.openMacrosFolder then actions.openMacrosFolder() end end,
            },
            {
                label = 'Mobs Exports##tools_open_tmobs_exports',
                intent = 'utility',
                tooltip = 'Open TurboMobs exports directly from Turbo, without using /tmobs.',
                onClick = function() if actions.openTurboMobsExportsFolder then actions.openTurboMobsExportsFolder() end end,
            },
            meleeToggleButton('tools_melee_dist'),
        }, 2, 128, ACTION_BTN_H)
    end

    local function drawAllaSettings()
        actions.thinSep('utility', 'Alla links')
        g.allaItemUrlBase = actions.Ui.compactInput('Item base', g.allaItemUrlBase, {
            id = '##tools_alla_item_base',
            labelW = 72,
            width = math.max(180, actions.Ui.availX(280) - 72),
        })
        actions.tip('Base URL for item lookups. Turbo appends only the numeric item ID, for example 13009.')
        g.allaNpcUrlBase = actions.Ui.compactInput('NPC base', g.allaNpcUrlBase, {
            id = '##tools_alla_npc_base',
            labelW = 72,
            width = math.max(180, actions.Ui.availX(280) - 72),
        })
        actions.tip('Base URL for NPC lookups. Turbo appends only the numeric NPC ID.')
        drawVariantGrid({
            {
                label = 'Save Alla URLs##tools_alla_save',
                intent = 'positive',
                tooltip = 'Save these lookup URL bases to this character\'s Turbo settings.',
                onClick = function()
                    if actions.saveAllaUrlSettings then actions.saveAllaUrlSettings(g.allaItemUrlBase, g.allaNpcUrlBase) end
                end,
            },
            {
                label = 'Reset Lazarus defaults##tools_alla_reset',
                shortLabel = 'Lazarus defaults',
                intent = 'utility',
                tooltip = 'Set item and NPC lookup bases to Lazarus Alla.',
                onClick = function()
                    g.allaItemUrlBase = 'https://www.lazaruseq.com/alla/items/'
                    g.allaNpcUrlBase = 'https://www.lazaruseq.com/alla/npcs/'
                    if actions.saveAllaUrlSettings then actions.saveAllaUrlSettings(g.allaItemUrlBase, g.allaNpcUrlBase) end
                end,
            },
        }, 2, 128, ACTION_BTN_H)
    end

    local function drawFieldToolsRow()
        actions.thinSep('utility', 'Field Tools')
        local mobsRunning = luaScriptRunning('TurboMobs')
        local gearRunning = luaScriptRunning({ 'turbogear', 'TurboGear' })
        local rollsRunning = luaScriptRunning('TurboRolls')
        local okMV, MoneyView = pcall(require, 'Turbo.gains_view')
        local gainsRunning = okMV and MoneyView and MoneyView.isEngineRunning and MoneyView.isEngineRunning() or false
        local gainsActive = gainsRunning or g.gainsWindowOpen == true
        drawVariantGrid({
            {
                label = 'XTank Macro##field_xtank',
                intent = 'utility',
                tooltip = 'Run turbo_xtar_heal on healers. Adds out-of-group raid tanks only; same-group tanks are skipped.',
                onClick = function()
                    if actions.sendXTankMacro then
                        actions.sendXTankMacro()
                    else
                        actions.mq.cmd('/e3bcga /mac turbo_xtar_heal')
                        g.statusMessage = 'XTank macro sent to group healers.'
                    end
                end,
            },
            {
                label = 'Gear##field_gear',
                intent = gearRunning and 'announce' or 'utility',
                tooltip = 'Open TurboGear for worn gear, augments, BiS lists, focus tracking, and comparisons. Click again to hide.',
                onClick = function()
                    if luaScriptRunning({ 'turbogear', 'TurboGear' }) then
                        actions.mq.cmd('/tgear toggle')
                        g.statusMessage = 'TurboGear toggled.'
                    else
                        actions.mq.cmd('/lua run turbogear')
                        g.statusMessage = 'TurboGear launched.'
                    end
                end,
            },
            {
                label = 'Rolls##field_rolls',
                intent = rollsRunning and 'announce' or 'utility',
                tooltip = 'Open or hide TurboRolls for raid/group roll handling.',
                onClick = function()
                    if luaScriptRunning('TurboRolls') then
                        actions.mq.cmd('/troll togglefull')
                        g.statusMessage = 'TurboRolls full UI toggled.'
                    else
                        actions.mq.cmd('/lua run TurboRolls')
                        g.statusMessage = 'TurboRolls launched.'
                    end
                end,
            },
            {
                label = 'Mobs##field_mobs',
                intent = mobsRunning and 'announce' or 'utility',
                tooltip = 'Open or hide TurboMobs for mob search, spawn watches, respawn timers, and alerts.',
                onClick = function()
                    if luaScriptRunning('TurboMobs') then
                        actions.mq.cmd('/tmobs togglefull')
                        g.statusMessage = 'TurboMobs full UI toggled.'
                    else
                        actions.mq.cmd('/lua run TurboMobs')
                        g.statusMessage = 'TurboMobs launch requested.'
                    end
                end,
            },
            {
                label = 'Gains##field_gains',
                intent = gainsActive and 'announce' or 'utility',
                tooltip = 'Open or hide the Turbo Gains window for sessions, coin/XP snapshots, timed challenges, and reports.',
                onClick = function()
                    g.gainsWindowOpen = not g.gainsWindowOpen
                    if g.gainsWindowOpen then
                        g.gainsWindowOpenReason = 'field tools gains'
                        g.gainsWindowOpenAt = os.time()
                        g.slimGUI = false
                        g.minimizedGUI = false
                        g.statusMessage = 'Turbo Gains opened.'
                    else
                        g.statusMessage = 'Turbo Gains hidden.'
                    end
                    if g.saveSettings then g.saveSettings() end
                end,
            },
            {
                label = 'Maintenance##field_maintenance',
                shortLabel = 'Maint',
                intent = 'utility',
                tooltip = 'Open More for logs, journals, repairs, diagnostics, and backups.',
                onClick = function()
                    g.activeTab = 'tools'
                    g.slimGUI = false
                    g.minimizedGUI = false
                    g.statusMessage = 'More maintenance tools opened.'
                    if g.saveSettings then g.saveSettings() end
                end,
            },
        }, 2, 128, ACTION_BTN_H)
    end

    local function drawToolsResetPopup()
        if ImGui.BeginPopupModal('Confirm Repair Skip Review') then
            ImGui.Text('Repair Skip Review')
            ImGui.Separator()
            ImGui.Text('This clears Turbo skip-review state, queue state, queue file, and watched skip journals.')
            ImGui.Text('Existing INI rules are not changed.')
            ImGui.Dummy(0, 6)
            if ImGui.Button('Repair##tools_skip_review_reset_confirm', 118, ACTION_BTN_H) then
                if actions.resetSkipReviewData then actions.resetSkipReviewData() end
                ImGui.CloseCurrentPopup()
            end
            ImGui.SameLine()
            if ImGui.Button('Cancel##tools_skip_review_reset_cancel', 118, ACTION_BTN_H) then
                ImGui.CloseCurrentPopup()
            end
            ImGui.EndPopup()
        end
    end

    local function drawToolsDiagnostics()
        actions.thinSep('utility', 'Review and diagnostics')
        drawVariantGrid({
            {
                label = 'Export Diagnostics##tools_export_diagnostics',
                shortLabel = 'Diagnostics',
                intent = 'info',
                tooltip = 'Export a 360 support bundle: runtime snapshot, E3/loot/gains/mobs state, and config copies. Send the whole folder.',
                onClick = function()
                    if actions.exportDiagnostics then
                        actions.exportDiagnostics()
                    elseif actions.runDoctor then
                        actions.runDoctor()
                    end
                end,
            },
            {
                label = 'Clean Diagnostics##tools_clean_diagnostics',
                shortLabel = 'Clean Diag',
                intent = 'utility',
                tooltip = 'Remove old Turbo diagnostics bundles only. Live config, logs, and state files are not changed.',
                onClick = function()
                    if actions.cleanDiagnostics then actions.cleanDiagnostics() end
                end,
            },
            {
                label = 'Open Diagnostics##tools_open_diagnostics',
                shortLabel = 'Open Diag',
                intent = 'utility',
                tooltip = 'Open the most recently exported diagnostics folder. This may briefly pause while Windows opens Explorer.',
                onClick = function()
                    if actions.openLastDiagnostics then actions.openLastDiagnostics() end
                end,
            },
            {
                label = 'Open Skip List##tools_skip_journal',
                shortLabel = 'Open Skips',
                intent = 'utility',
                tooltip = 'Open the active profile\'s TurboLoot skip list/log file.',
                onClick = function()
                    if actions.openSkipJournal then actions.openSkipJournal() end
                end,
            },
            {
                label = 'Repair Skip Review##tools_skip_reset',
                shortLabel = 'Repair Review',
                intent = 'danger',
                tooltip = 'Clear stale Skip Review counts, queue state, queue file, and watched journals. Existing INI loot rules are not changed.',
                onClick = function()
                    ImGui.OpenPopup('Confirm Repair Skip Review')
                end,
            },
            {
                label = 'TurboDoctor##tools_doctor',
                intent = 'info',
                tooltip = 'Print Turbo diagnostics to chat: installed versions, expected macro files, active profile paths, and common setup checks.',
                onClick = function() if actions.runDoctor then actions.runDoctor() end end,
            },
        }, 2, 128, ACTION_BTN_H)
    end

    local function drawToolsBackups()
        local targetName = selectedToolCharacter()
        actions.thinSep('profile', 'Backups')
        drawVariantGrid({
            {
                label = 'Backup TL INI##tools_backup_tl',
                intent = 'utility',
                tooltip = 'Back up the selected character\'s active TurboLoot INI. Remote characters receive /lua run Turbo backup turbo through EQBC.',
                onClick = function()
                    if actions.backupActiveIni then actions.backupActiveIni(targetName) end
                end,
            },
            {
                label = 'Backup E3 INI##tools_backup_e3',
                intent = 'utility',
                tooltip = 'Back up the selected character\'s E3 INI. Remote characters receive /lua run Turbo backup e3 through EQBC.',
                onClick = function()
                    if actions.backupLocalE3Ini then actions.backupLocalE3Ini(targetName) end
                end,
            },
            {
                label = 'Backup Group E3##tools_backup_group_e3',
                intent = 'utility',
                tooltip = 'Each group character backs up its own local E3 INI.',
                onClick = function()
                    if actions.backupGroupE3Inis then actions.backupGroupE3Inis() end
                end,
            },
            {
                label = 'Backup All E3##tools_backup_all_e3',
                intent = 'value',
                tooltip = 'Broadcast E3 INI backup to all E3 bots in zone.',
                onClick = function()
                    if actions.backupAllZoneE3Inis then actions.backupAllZoneE3Inis() end
                end,
            },
            {
                label = 'Backup eqclient.ini##tools_backup_eqclient',
                intent = 'utility',
                tooltip = 'Back up eqclient.ini for the selected character\'s running client. Remote characters receive /lua run Turbo backup eqclient through EQBC.',
                onClick = function()
                    if actions.backupEqclientIni then actions.backupEqclientIni(targetName) end
                end,
            },
        }, 2, 128, ACTION_BTN_H)
    end

    local function drawToolsLinks()
        actions.thinSep('utility', 'Links')
        drawVariantGrid({
            {
                label = 'GitHub##tools_github',
                intent = 'primary',
                tooltip = 'Open Turbo on GitHub in your default browser.',
                onClick = function()
                    if actions.openGithub then actions.openGithub() end
                end,
            },
            {
                label = 'Turbo Quick Start##tools_first_run',
                intent = 'utility',
                tooltip = 'Open the Turbo Quick Start onboarding window again.',
                onClick = function()
                    actions.mq.cmd('/lua run Turbo/onboarding')
                    g.statusMessage = 'Turbo Quick Start opened.'
                end,
            },
            {
                label = 'Turbo Patcher##tools_patcher',
                intent = 'info',
                tooltip = 'Launch TurboPatcher.exe to update the Turbo suite. Looks in your MacroQuest folder (and a TurboPatcher subfolder there). Running Turbo scripts stop themselves when an update starts. If the exe is missing, opens the download page.',
                onClick = function()
                    if actions.openTurboPatcher then actions.openTurboPatcher() end
                end,
            },
        }, 1, 160, ACTION_BTN_H)
        local checkOn = g.checkForUpdates ~= false
        local newCheck = ImGui.Checkbox('Check for Turbo updates##tools_check_updates', checkOn)
        if newCheck ~= checkOn then
            g.checkForUpdates = newCheck == true
            if actions.saveSettings then actions.saveSettings() end
            if newCheck then
                g.updateCheckAt = 0
                g.turboUpdateAvailable = false
            end
        end
        if ImGui.IsItemHovered() and ImGui.SetTooltip then
            ImGui.SetTooltip('When on, Turbo occasionally checks GitHub for a newer suite version and shows a banner. Off = never check.')
        end
        ImGui.SameLine()
        if ImGui.SmallButton('Check now##tools_update_check_now') then
            local okUC, UC = pcall(require, 'Turbo.update_check')
            if okUC and UC and UC.force_check then
                if UC.force_check(g, { immediate = true }) then
                    g.statusMessage = 'Checking GitHub for a Turbo update (background)...'
                else
                    g.statusMessage = 'Could not start update check (or checks are disabled).'
                end
            end
        end
        if ImGui.IsItemHovered() and ImGui.SetTooltip then
            ImGui.SetTooltip('Fetch the latest CHANGELOG from GitHub now and show the banner if you are behind.')
        end
        if g.turboUpdateAvailable == true then
            ImGui.TextColored(1.0, 0.76, 0.29, 1.0, string.format(
                'Update available → v%s (banner above, or Turbo Patcher)',
                tostring(g.remoteTurboVersion or '?')))
        elseif g.remoteTurboVersion and g.remoteTurboVersion ~= '' then
            ImGui.TextColored(0.55, 0.60, 0.68, 1.0, string.format(
                'GitHub: v%s (you are current)', tostring(g.remoteTurboVersion)))
        end
    end

    if g.activeTab == 'tools' then
        ImGui.TextColored(0.62, 0.70, 0.86, 1.0, 'More')
        ImGui.SameLine()
        ImGui.TextColored(0.46, 0.50, 0.58, 1.0, 'maintenance, backups, links')
        ImGui.Dummy(0, 6)
        drawToolCharacterSelector()
        ImGui.Dummy(0, 4)
        drawFileOpenRow()
        ImGui.Dummy(0, 4)
        drawToolsDiagnostics()
        ImGui.Dummy(0, 4)
        drawToolsBackups()
        ImGui.Dummy(0, 4)
        drawToolsLinks()
        ImGui.Dummy(0, 4)
        drawAllaSettings()
        if g.statusMessage ~= '' then
            actions.coloredSep(55, 60, 75, 60)
            ImGui.PushTextWrapPos(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail())
            ImGui.TextColored(Colors.statusMsg[1], Colors.statusMsg[2], Colors.statusMsg[3], Colors.statusMsg[4], g.statusMessage)
            ImGui.PopTextWrapPos()
        end
        drawToolsResetPopup()
        drawActionConfirmPopup()
        return
    end

    if not g.slimGUI then
        drawRunAsPanel()
        ImGui.Dummy(0, 4)
    end

    if not g.slimGUI then
        actions.thinSep('turboloot', 'TurboLoot')
        --- 1.1.2: TurboLoot button colors aligned to the TurboKey rule palette
        --- (which itself aligns to chat \ag SELL, \ap BANK, \ay TRIBUTE,
        --- \ar DESTROY codes from TurboLoot.mac help). Goal: same color =
        --- same meaning across Actions tab, Review tab, and chat help.
        --- Report  — gray (skip slot): read-only/neutral
        --- Sell    — green (sell slot): matches \ag in chat
        --- Bank    — purple (bank slot): matches \ap in chat
        --- Tribute — gold (tribute slot): matches \ay in chat
        --- Unload  — composite gray-blue: does sell+bank+tribute+destroy in one
        ---           pass; deliberately NOT one of the four colors so it
        ---           doesn't claim a single action's identity.
        --- Destroy — red (destroy slot): matches \ar in chat
        local TKR        = actions.TurboKeyRGB
        local UNLOAD_RGB = {10, 14, 20}  -- dark utility action; distinct from BANK purple / neutral gray
        drawScopedGrid({
            {
                label = 'Report##tl_report',
                cmd = '/mac turboloot report',
                color = TKR.skip,
                tooltip = 'Show loot summary report',
                opts = { broadcast = true, syncTurboLootProfile = true },
            },
            {
                label = 'Sell##tl_sell',
                cmd = '/mac turboloot sell',
                color = TKR.sell,
                tooltip = 'Sell all SELL-tagged items to merchant',
                opts = { broadcast = true, syncTurboLootProfile = true },
            },
            {
                label = 'Bank##tl_bank',
                cmd = '/mac turboloot bank',
                color = TKR.bank,
                tooltip = 'Bank all BANK-tagged items',
                opts = { broadcast = true, syncTurboLootProfile = true },
            },
            {
                label = 'Tribute##tl_tribute',
                cmd = '/mac turboloot tribute',
                color = TKR.tribute,
                tooltip = 'Tribute all TRIBUTE-tagged items',
                opts = { broadcast = true, syncTurboLootProfile = true },
            },
            {
                label = 'Unload##tl_unload',
                cmd = '/mac turboloot unload',
                color = UNLOAD_RGB,
                tooltip = 'Unload: bank + tribute + sell + destroy in one pass',
                opts = { broadcast = true, syncTurboLootProfile = true },
            },
            {
                label = 'Destroy##tldestroy',
                cmd = '/mac turboloot destroy',
                color = TKR.destroy,
                tooltip = 'Destroy all DESTROY-tagged items (per turboloot.ini)',
                opts = {
                    syncTurboLootProfile = true,
                    confirmTitle = 'Confirm Destroy',
                    confirmBody = 'Run TurboLoot destroy on this character and destroy all DESTROY-tagged items?',
                    disabledTip = 'Self only in broadcast mode.',
                },
            },
        }, 3, MIN_ACTION_W, ACTION_BTN_H)
        --- 1.1.3: Reclaim + Lotto now shares its row with PoT + GoD symbols
        --- (two 50/50 buttons matching the gap from the grids above). Both
        --- are "earn alt-currency rewards" workflows; the Symbols button
        --- is intentionally `primaryButton` (blue) instead of green so the
        --- two reads as distinct entries rather than a blob of green.
        --- 1.2.0: bot selector can run both commands on one bot or all bots.
        --- Reclaim + Lotto stays on `successButton` (the green Theme variant) —
        --- it's not a loot rule, it's a separate workflow about acquiring
        --- alt-currency rewards. Green reads as "earn/keep" which matches.
        drawScopedGrid({
            {
                label = 'Reclaim + Lotto##tlreclaimlotto',
                cmd = '/lua run turbo_reclaim_lotto',
                color = 'successButton',
                tooltip = 'Reclaim alt-currency, open coins/tickets/sacks, reclaim again (lua/turbo_reclaim_lotto.lua).',
                opts = { broadcast = true },
            },
        --- PoT + GoD: opens TurboHandins (PoT/GoD symbols).
        --- Was previously buried under Tools popup; promoted to the action row in init.lua 3.8.55
        --- because PoK/Tower turn-ins are a routine end-of-loop workflow, not a one-off tool.
            {
                label = 'PoT + GoD##tlhandins',
                cmd = '/lua run Turbo/handins',
                color = 'primaryButton',
                tooltip = 'Open TurboHandins: PoT and GoD symbols in Plane of Knowledge. Includes per-character Exclusions list.',
                opts = { broadcast = true },
            },
        }, 2, 128, ACTION_BTN_H)
        drawFieldToolsRow()
    end

    if not g.slimGUI then
        actions.thinSep('turbogive', 'TurboGive')
        drawScopedGrid({
            {
                label = 'Give##tg_give',
                cmd = '/mac turbogive',
                color = 'successButton',
                tooltip = 'Selected Run As scope gives assigned items.',
                opts = {
                    broadcast = true,
                    allLocal = true,
                    commands = {
                        self = '/mac turbogive solo',
                        multi = '/mac turbogive solo',
                        group = '/mac turbogive',
                        all = '/mac turbogive all',
                    },
                    localModes = { group = true, all = true },
                },
            },
            {
                label = 'Collect##tg_collect',
                cmd = '/mac turbogive collect',
                color = {75,125,90},
                tooltip = 'Selected Run As scope collects assigned items.',
                opts = {
                    broadcast = true,
                    allLocal = true,
                    commands = {
                        self = '/mac turbogive collect',
                        multi = '/mac turbogive collect',
                        group = '/mac turbogive collect',
                        all = '/mac turbogive collect all',
                    },
                    localModes = { group = true, all = true },
                },
            },
            {
                label = 'Bank##tg_bank',
                cmd = '/mac turbogive bank solo',
                color = {55,110,75},
                tooltip = 'Selected Run As scope pulls assigned bank items.',
                opts = {
                    broadcast = true,
                    allLocal = true,
                    commands = {
                        self = '/mac turbogive bank solo',
                        multi = '/mac turbogive bank solo',
                        group = '/mac turbogive bank',
                        all = '/mac turbogive bank all',
                    },
                    localModes = { group = true, all = true },
                },
            },
        }, 3, MIN_ACTION_W, ACTION_BTN_H)
    end

    if not g.slimGUI then
        actions.thinSep('currency', 'Currency')
        --- 1.1.1: Give PP / Give DC are always rendered (was: only when a PC was
        --- targeted). New users couldn't discover the feature otherwise. When
        --- no PC is targeted, the buttons are disabled (BeginDisabled) and the
        --- tooltip shows a red "Target a player to enable" line so the gating
        --- is obvious. Layout stays a single row of four buttons either way.
        ---
        --- Tooltip-while-disabled: ImGui.BeginDisabled blocks IsItemHovered() by
        --- default. ImGuiHoveredFlags.AllowWhenDisabled (= 128) opts back in.
        --- Falls back gracefully on older bindings: if the flag value is missing
        --- or hover is suppressed, the user just doesn't see the warning tooltip
        --- — the button is still visibly disabled, so the gating is still clear.
        local hasPcTarget = rt.hasPcTarget
        local HOVERED_ALLOW_DISABLED = (ImGuiHoveredFlags and ImGuiHoveredFlags.AllowWhenDisabled) or 128

        local givePpCmd  = hasPcTarget and string.format('/mac turbogive %s cash', rt.targetName) or nil
        local giveDcCmd  = hasPcTarget and string.format('/mac turbogive %s dc', rt.targetName)   or nil
        local givePpTip  = hasPcTarget
            and ('Give all coin on you (platinum, gold, silver, copper) to ' .. rt.targetName .. ' - one trade')
            or nil
        local giveDcTip  = hasPcTarget
            and ('Give your Diamond Coins to ' .. rt.targetName .. ' (withdraws alt-currency DC to inventory first if needed)')
            or nil

        local currencyCols, currencyW, currencyGap = actions.Ui.adaptiveColumns(4, 72, GRID_GAP)
        if not hasPcTarget then ImGui.BeginDisabled() end
        local currencyButtons = {
            {
                label = 'Give PP##gc',
                cmd = givePpCmd or '',
                color = 'amberButton',
                tooltip = givePpTip,
                opts = { disabledTip = 'TurboGive trade commands are self only from this selector.' },
                after = function()
                    if not hasPcTarget and ImGui.IsItemHovered(HOVERED_ALLOW_DISABLED) then
                        ImGui.BeginTooltip()
                        ImGui.Text('Give PP')
                        ImGui.TextColored(0.92, 0.45, 0.40, 1.0, 'Target a player to enable.')
                        ImGui.TextColored(0.55, 0.58, 0.65, 1.0, 'Gives all coin on you to the targeted player in one trade.')
                        ImGui.EndTooltip()
                    end
                end,
            },
            {
                label = 'Give DC##gdc',
                cmd = giveDcCmd or '',
                color = 'amberButton',
                tooltip = giveDcTip,
                opts = { disabledTip = 'TurboGive trade commands are self only from this selector.' },
                after = function()
                    if not hasPcTarget and ImGui.IsItemHovered(HOVERED_ALLOW_DISABLED) then
                        ImGui.BeginTooltip()
                        ImGui.Text('Give DC')
                        ImGui.TextColored(0.92, 0.45, 0.40, 1.0, 'Target a player to enable.')
                        ImGui.TextColored(0.55, 0.58, 0.65, 1.0, 'Gives your Diamond Coins to the targeted player.')
                        ImGui.EndTooltip()
                    end
                end,
            },
        }
        for i, btn in ipairs(currencyButtons) do
            actions.Ui.gridSameLine(i, currencyCols, currencyGap)
            scopedButton(btn.label, btn.cmd, btn.color, btn.tooltip, currencyW, ACTION_BTN_H, btn.opts)
            if btn.after then btn.after() end
        end
        if not hasPcTarget then ImGui.EndDisabled() end

        local collectButtons = {
            {
                label = 'Collect PP##gc2',
                cmd = '/mac turbogive collect cash',
                color = 'amberButton',
                tooltip = 'Collect all coin from group members to you (pp+gp+sp+cp per member, one trade each)',
                opts = { disabledTip = 'TurboGive trade commands are self only from this selector.' },
            },
            {
                label = 'Collect DC##gdc2',
                cmd = '/lua run turbo_collect_dc',
                color = {145,120,55},
                tooltip = 'Collect Diamond Coins from group members to you (Lua coordinator, TurboGive sender)',
                opts = { disabledTip = 'TurboGive trade commands are self only from this selector.' },
            },
        }
        for i, btn in ipairs(collectButtons) do
            actions.Ui.gridSameLine(i + #currencyButtons, currencyCols, currencyGap)
            scopedButton(btn.label, btn.cmd, btn.color, btn.tooltip, currencyW, ACTION_BTN_H, btn.opts)
        end

        local cvtRgb = {82, 88, 100}
        if rt.inConvertZone then cvtRgb = {70, 104, 92} end

        actions.thinSep('conversions', 'Conversions')
        drawScopedGrid({
            {
                label = 'AA -> DC##cvt',
                cmd = '/mac turbogive convert all',
                color = cvtRgb,
                opts = { broadcast = true },
                after = function()
                    if ImGui.IsItemHovered() then
                        actions.turboConvertTooltip('Convert my AA -> DC, then broadcast to any group members', rt.inConvertZone)
                    end
                end,
            },
            {
                label = 'DC -> AA##cvt',
                cmd = '/mac turbogive convert dc all',
                color = cvtRgb,
                opts = { broadcast = true },
                after = function()
                    if ImGui.IsItemHovered() then
                        actions.turboConvertTooltip('Convert my DC -> AA, then broadcast to any group members', rt.inConvertZone)
                    end
                end,
            },
        }, 2, 96, ACTION_BTN_H)

    end

    if rt.hasCursor then
        actions.renderCursorHandPanel(state)
        ImGui.Dummy(0, 4)
        ImGui.PushTextWrapPos(ImGui.GetFontSize() * 26.0)
        ImGui.TextColored(Colors.turbokey.label[1], Colors.turbokey.label[2], Colors.turbokey.label[3], 1.0,
            'Cursor: ' .. rt.cursorItem)
        ImGui.PopTextWrapPos()
    end

    local footerMessage = tostring(g.statusMessage or '')
    local footerReserveH = g.slimGUI and 0 or 42
    local statusReserveH = (footerMessage ~= '' and 64 or 8)
    local _, availY = ImGui.GetContentRegionAvail()
    local spareY = (tonumber(availY) or 0) - statusReserveH - footerReserveH
    if spareY > 0 then ImGui.Dummy(0, spareY) end

    actions.coloredSep(55, 60, 75, 60)
    if footerMessage ~= '' then
        ImGui.PushTextWrapPos(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail())
        ImGui.TextColored(0.45, 0.48, 0.55, 1.0, 'Last:')
        ImGui.SameLine(0, 5)
        ImGui.TextColored(Colors.statusMsg[1], Colors.statusMsg[2], Colors.statusMsg[3], Colors.statusMsg[4], footerMessage)
        ImGui.PopTextWrapPos()
    end
    drawActionConfirmPopup()
    ImGui.Dummy(0, 3)
end

return M
