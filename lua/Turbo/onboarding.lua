local mq = require('mq')
local ImGui = require('ImGui')
local Theme = require('Turbo.theme')
local Ui = require('Turbo.ui.components')
local IniProfiles = require('Turbo.ini_profiles')
local ShellOpen = require('Turbo.shell_open')
local Paths = require('Turbo.paths')

local app = {
    open = true,
    checked = false,
    status = 'Checking TurboLoot setup...',
    iniPath = '',
    examplePath = '',
    copied = false,
    error = '',
    e3Ok = nil,
    e3Detail = '',
    dontShowAgain = false,
    iniCreateBuf = 'turboloot.ini',
    sizeInitialized = false,
    page = 'quick',
}

local function isTurboRunning()
    local ok, status = pcall(function()
        local lua = mq.TLO.Lua
        if not lua or not lua.Script then return '' end
        local script = lua.Script('Turbo')
        if not script or not script.Status then return '' end
        return script.Status() or ''
    end)
    if ok and tostring(status or ''):lower():find('run', 1, true) then return true end
    if mq.parse then
        local okParse, parsed = pcall(function() return mq.parse('${Lua.Script[Turbo].Status}') end)
        if okParse and tostring(parsed or ''):lower():find('run', 1, true) then return true end
    end
    return false
end

local function luaScriptRunning(names)
    local list = type(names) == 'table' and names or { names }
    for _, scriptName in ipairs(list) do
        local ok, status = pcall(function()
            local lua = mq.TLO.Lua
            if not lua or not lua.Script then return '' end
            local script = lua.Script(scriptName)
            if not script or not script.Status then return '' end
            return script.Status() or ''
        end)
        if ok and tostring(status or ''):lower():find('run', 1, true) then return true end
    end
    return false
end

local function openTurboMain()
    if isTurboRunning() then
        mq.cmd('/turbofocus')
    else
        mq.cmd('/lua run Turbo full')
    end
end

local function routeTurboTab(tab)
    tab = tostring(tab or 'full'):lower()
    if isTurboRunning() then
        IniProfiles.queueNavigation(tab)
        if tab == 'setup' then
            mq.cmd('/turbosetup')
        elseif tab == 'rulepacks' or tab == 'rules' or tab == 'packs' then
            mq.cmd('/turborulepacks')
        elseif tab == 'gains' then
            mq.cmd('/turbogainsopen')
        elseif tab == 'tools' or tab == 'more' then
            mq.cmd('/turbotools')
        elseif tab == 'review' then
            mq.cmd('/turboreview')
        elseif tab == 'actions' then
            mq.cmd('/turbomain')
        else
            mq.cmd('/turbomain')
        end
    else
        mq.cmd('/lua run Turbo ' .. tab)
    end
end

local function runE3Setup()
    if isTurboRunning() then
        mq.cmd('/turboe3setup')
    else
        mq.cmd('/lua run Turbo setup')
    end
end

local function openRulePacks()
    if isTurboRunning() then
        mq.cmd('/turborulepacks')
    else
        mq.cmd('/lua run Turbo rulepacks')
    end
end

local function openGains()
    if isTurboRunning() then
        mq.cmd('/turbogainsopen')
    else
        mq.cmd('/lua run Turbo gains')
    end
end

local function openWares()
    if isTurboRunning() then
        mq.cmd('/turbowares')
    else
        mq.cmd('/lua run Turbo wares')
    end
end

local function openTurboGear()
    if luaScriptRunning({ 'turbogear', 'TurboGear' }) then
        mq.cmd('/tgear toggle')
    else
        mq.cmd('/lua run turbogear')
    end
end

local function openTurboMobs()
    if luaScriptRunning('TurboMobs') then
        mq.cmd('/tmobs togglefull')
    else
        mq.cmd('/lua run TurboMobs')
    end
end

local function fileExists(path)
    local f = io.open(path, 'r')
    if f then f:close() return true end
    return false
end

local function resolveE3IniPath()
    local mqPath = tostring(mq.TLO.MacroQuest.Path() or '')
    if mqPath == '' then return nil end
    local char = tostring(mq.TLO.Me.CleanName() or mq.TLO.Me.Name() or ''):match('^%s*(.-)%s*$') or ''
    if char == '' or char == 'NULL' then return nil end

    local serverRaw = ''
    local okSrv, srv = pcall(function()
        if mq.TLO.EverQuest and mq.TLO.EverQuest.Server then
            return mq.TLO.EverQuest.Server() or ''
        end
        if mq.parse then return mq.parse('${EverQuest.Server}') or '' end
        return ''
    end)
    if okSrv then serverRaw = tostring(srv or '') end

    local bases = {
        mqPath .. '\\Config\\e3 Bot Inis',
        mqPath .. '\\Macros\\e3 Bot Inis',
    }
    local serverStripped = serverRaw:gsub('^Project ', '')
    local serverUnder = serverRaw:gsub(' ', '_')
    local variants = {}
    if serverRaw ~= '' then variants[#variants + 1] = char .. '_' .. serverRaw end
    if serverStripped ~= serverRaw then variants[#variants + 1] = char .. '_' .. serverStripped end
    if serverUnder ~= serverRaw then variants[#variants + 1] = char .. '_' .. serverUnder end
    variants[#variants + 1] = char

    for _, base in ipairs(bases) do
        for _, v in ipairs(variants) do
            local p = base .. '\\' .. v .. '.ini'
            if fileExists(p) then return p end
        end
    end
    return nil
end

local function inspectE3Hooks()
    local ok, e3Ok, e3Detail = pcall(function()
        local char = tostring(mq.TLO.Me.CleanName() or mq.TLO.Me.Name() or '')
        if char == '' or char == 'NULL' then
            return false, 'Not in game - E3 check skipped'
        end
        local e3Path = resolveE3IniPath()
        if not e3Path then
            return false, 'E3 INI not found - run Setup to add corpse hooks'
        end
        local f = io.open(e3Path, 'r')
        if not f then
            return false, 'E3 INI not readable - run Setup'
        end
        local inEvents = false
        local foundTloot = false
        for line in f:lines() do
            local sec = line:match('^%[(.-)%]%s*$')
            if sec then inEvents = (sec == 'Events') end
            if inEvents and line:match('^%s*Tloot%s*=') then foundTloot = true break end
        end
        f:close()
        if not foundTloot then
            return false, 'Missing [Events] Tloot hook - run Setup'
        end
        return true, 'Corpse loot hooks found'
    end)
    if not ok then
        return false, 'E3 check unavailable - run Setup when in game'
    end
    return e3Ok, e3Detail
end

local function ensureStarterIni()
    return IniProfiles.createDefaultIni()
end

local function runCheck()
    local ok, err = pcall(function()
        local iniOk, iniPath, examplePath, iniErr, copied = ensureStarterIni()
        app.iniPath = iniPath or ''
        app.examplePath = examplePath or ''
        app.copied = copied == true
        app.error = iniErr or ''
        if iniOk and copied then
            app.status = 'Created turboloot.ini from the starter template.'
        elseif iniOk then
            app.status = 'Found an existing turboloot.ini.'
        else
            app.status = 'TurboLoot setup needs attention.'
        end
        app.e3Ok, app.e3Detail = inspectE3Hooks()
    end)
    app.checked = true
    if not ok then
        app.error = tostring(err or 'Quick Start check failed.')
        app.status = 'TurboLoot setup needs attention.'
        app.e3Ok = false
        app.e3Detail = 'E3 check skipped due to an error.'
    end
end

local function saveDismissPreference()
    if not app.dontShowAgain then return end
    local path = Paths.state_file('turbo_quickstart_dismiss.lua')
    if not path then return end
    local f = io.open(path, 'w')
    if not f then return end
    f:write('return true\n')
    f:close()
end

local function asciiText(text)
    return tostring(text or '')
        :gsub('\226\128\148', ' - ')  -- em dash UTF-8
        :gsub('\226\128\153', "'")     -- right single quote
        :gsub('\226\128\156', '"')
        :gsub('\226\128\157', '"')
end

local function textMuted(text)
    ImGui.PushStyleColor(ImGuiCol.Text, IM_COL32(182, 196, 220, 255))
    ImGui.TextWrapped(asciiText(text))
    ImGui.PopStyleColor()
end

local function textPath(path, prefix)
    local mqPath = tostring(mq.TLO.MacroQuest.Path() or '')
    local text = tostring(path or '')
    if mqPath ~= '' and text:sub(1, #mqPath):lower() == mqPath:lower() then
        text = '<MQ>' .. text:sub(#mqPath + 1)
    end
    if prefix and prefix ~= '' then text = prefix .. text end
    ImGui.PushStyleColor(ImGuiCol.Text, IM_COL32(148, 189, 148, 255))
    ImGui.TextWrapped(text)
    ImGui.PopStyleColor()
end

local function shortMqPath(path)
    local mqPath = tostring(mq.TLO.MacroQuest.Path() or '')
    local text = tostring(path or '')
    if mqPath ~= '' and text:sub(1, #mqPath):lower() == mqPath:lower() then
        text = '<MQ>' .. text:sub(#mqPath + 1)
    end
    return text
end

local function sectionTitle(text)
    ImGui.Spacing()
    ImGui.TextColored(0.62, 0.78, 0.95, 1.0, tostring(text or ''))
end

local function guideSection(label, defaultOpen)
    if ImGui.CollapsingHeader then
        local flags = 0
        if defaultOpen and ImGuiTreeNodeFlags and ImGuiTreeNodeFlags.DefaultOpen then
            flags = ImGuiTreeNodeFlags.DefaultOpen
        end
        local ok, open = pcall(ImGui.CollapsingHeader, tostring(label or '') .. '##qs_guide_' .. tostring(label or ''), flags)
        if ok then return open == true end
    end
    sectionTitle(label)
    return true
end

local function toolCell(name, rgb, text)
    ImGui.TextColored((rgb[1] or 180) / 255, (rgb[2] or 190) / 255, (rgb[3] or 210) / 255, 1.0, tostring(name or ''))
    ImGui.SameLine(0, 0)
    textMuted(' - ' .. tostring(text or ''))
end

local function button(label, variant, w, h)
    return Ui.buttonVariant(label, variant or 'secondaryButton', w or 118, h or 26)
end

local function hoverTip(text)
    if ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        ImGui.PushTextWrapPos(ImGui.GetFontSize() * 26)
        ImGui.Text(tostring(text or ''))
        ImGui.PopTextWrapPos()
        ImGui.EndTooltip()
    end
end

local function drawIniToolsHelp()
    sectionTitle('Loot INI profiles')
    textMuted('INI tools live on Turbo Setup: create, clone, import, export, and assign profiles.')
    if button('Open Setup INI tools##qs_open_setup_ini', 'primaryButton', 200, 28) then
        routeTurboTab('setup')
    end
    hoverTip('Opens Turbo Setup. Does not restart Turbo when it is already running.')
    textMuted('Create = new from template. Clone = copy current. Import = bring in a file. Export = copy out to share.')
    if button('Open Config folder##qs_open_config', 'secondaryButton', 140, 24) then
        local mqPath = mq.TLO.MacroQuest.Path() or ''
        if mqPath ~= '' then ShellOpen.shellOpenFolder(mqPath .. '\\Config') end
    end
    hoverTip('Open MacroQuest Config in Explorer to see turboloot*.ini files directly.')
end

local function drawStatusRow(label, ok, detail, actionLabel, actionFn, actionTip)
    local r, g, b = ok and 0.48 or 0.95, ok and 0.92 or 0.72, ok and 0.55 or 0.38
    ImGui.TextColored(r, g, b, 1.0, (ok and '[OK] ' or '[!] ') .. tostring(label))
    ImGui.PushTextWrapPos(ImGui.GetCursorPosX() + math.max(200, ImGui.GetContentRegionAvail()))
    ImGui.TextColored(0.45, 0.48, 0.55, 1.0, asciiText(detail or ''))
    ImGui.PopTextWrapPos()
    if actionLabel and actionFn then
        if button(actionLabel, ok and 'secondaryButton' or 'primaryButton', 0, 24) then actionFn() end
        hoverTip(actionTip or '')
    end
    ImGui.Dummy(0, 2)
end

local function nextStepMessage(iniOk, e3Ok, turboRunning)
    if not iniOk then
        return 'Next: make sure turboloot.ini exists, then open Setup to manage loot profiles.'
    end
    if e3Ok ~= true then
        return 'Next: repair E3 hooks so TurboLoot can respond to corpse events.'
    end
    if not turboRunning then
        return 'Next: start the Turbo UI, pick your looter on Setup, then press Loot.'
    end
    return 'You are ready to loot. Open Setup to tune INIs, or explore companion tools below.'
end

local function ruleTip(label)
    local tips = {
        KEEP = 'Loot and keep the item. Numeric rules are usually better when you only want a limited count.',
        LIMIT = 'Loot until this character has the specified count, then stop looting more copies.',
        ['# LIMIT'] = 'Loot until this character has the specified count, then stop looting more copies.',
        SELL = 'Loot the item, then sell it later with TurboLoot sell or Unload.',
        BANK = 'Loot the item, then move it to the bank with TurboLoot bank or Unload.',
        TRIBUTE = 'Loot the item, then tribute it with TurboLoot tribute or Unload.',
        IGNORE = 'Leave the item on the corpse and do not announce it. Use this for things you never want handled.',
        DESTROY = 'Loot and destroy junk items. Useful for common trash that would otherwise leave corpses behind.',
        ANNOUNCE = 'Do not loot the item. Leave it on the corpse and announce it so the right character can loot it.',
        WATCH = 'TurboWares can watch merchant items for you. Open a merchant with Turbo running, use the Watched tab, or right-click an item and choose Watch.',
    }
    return tips[label] or ''
end

local function ruleWord(label, rgb)
    local w = math.max(68, ImGui.CalcTextSize(label) + 22)
    Ui.buttonRgb(label .. '##quickstart_rule_' .. label, rgb, w, 24)
    hoverTip(ruleTip(label))
end

local function drawRuleWords()
    local tk = (Theme.col and Theme.col.turboKeyRGB) or {}
    local rules = {
        { 'KEEP', tk.keep or {70,100,150} },
        { '# LIMIT', {155, 118, 42} },
        { 'SELL', tk.sell or {60,120,80} },
        { 'BANK', tk.bank or {90,82,130} },
        { 'TRIBUTE', tk.tribute or {130,95,35} },
        { 'IGNORE', tk.skip or {90,95,105} },
        { 'DESTROY', tk.destroy or {145,60,55} },
        { 'ANNOUNCE', tk.announce or {55,130,140} },
        { 'WATCH', {55, 142, 118} },
    }
    local lineW = 0
    local maxW = ImGui.GetContentRegionAvail()
    for i, rule in ipairs(rules) do
        local label = rule[1]
        local w = math.max(68, ImGui.CalcTextSize(label) + 22)
        if i > 1 and lineW + w < maxW then
            ImGui.SameLine()
        else
            lineW = 0
        end
        ruleWord(label, rule[2])
        lineW = lineW + w
    end
end

local function announceColor()
    local tk = (Theme.col and Theme.col.turboKeyRGB) or {}
    local c = tk.announce or {55, 130, 140}
    return (c[1] or 55) / 255, (c[2] or 130) / 255, (c[3] or 140) / 255, 1.0
end

local function coloredStatus()
    if app.error ~= '' then
        ImGui.TextColored(0.95, 0.45, 0.38, 1.0, app.status)
    elseif app.copied then
        ImGui.TextColored(0.48, 0.92, 0.55, 1.0,
            'Created turboloot.ini from the starter template in ' .. shortMqPath(app.iniPath))
    else
        ImGui.TextColored(0.62, 0.86, 0.62, 1.0, app.status)
    end
end

local function drawPageTabs()
    local quickActive = app.page ~= 'learn'
    if button('Quick Start##qs_page_quick', quickActive and 'primaryButton' or 'secondaryButton', 132, 26) then
        app.page = 'quick'
    end
    hoverTip('The short first-run checklist.')
    ImGui.SameLine()
    if button('Learn More##qs_page_learn', (not quickActive) and 'primaryButton' or 'secondaryButton', 132, 26) then
        app.page = 'learn'
    end
    hoverTip('More detail about INIs, rules, and companion tools.')
end

local function drawCompanionToolButtons()
    textMuted('Optional side tools. These do not restart Turbo when it is already running.')
    if button('TurboGear##qs_turbogear', 'secondaryButton', 110, 26) then
        openTurboGear()
    end
    hoverTip('Worn gear, augments, BiS lists, and gear link announcements. Toggles if already running.')
    ImGui.SameLine()
    if button('Rule Packs##qs_rulepacks', 'secondaryButton', 110, 26) then
        openRulePacks()
    end
    hoverTip('Browse starter loot lists and merge rules into your INI.')
    ImGui.SameLine()
    if button('TurboGains##qs_gains', 'secondaryButton', 104, 26) then
        openGains()
    end
    hoverTip('AA/XP/plat tracking window. Opens without restarting Turbo.')
    ImGui.SameLine()
    if button('TurboMobs##qs_tmobs', 'secondaryButton', 100, 26) then
        openTurboMobs()
    end
    hoverTip('Spawn watches and zone alerts. Toggles if already running.')
end

local function drawRecommendedNext()
    sectionTitle('Recommended next')
    textMuted('Once the three checks are green, these two make Turbo useful fastest.')
    if button('Rule Packs##qs_next_rulepacks', 'primaryButton', 130, 28) then
        openRulePacks()
    end
    hoverTip('Add starter loot rules so Turbo knows what to keep, sell, bank, destroy, or announce.')
    ImGui.SameLine()
    textMuted('Add starter loot rules instead of building every rule by hand.')
    if button('TurboGear##qs_next_turbogear', 'primaryButton', 130, 28) then
        openTurboGear()
    end
    hoverTip('Track gear and BiS, then announce who still needs linked drops.')
    ImGui.SameLine()
    textMuted('Track gear needs and linked drop announces.')
end

local function drawQuickStartPage()
    ImGui.TextColored(0.95, 0.78, 0.34, 1.0, 'Welcome to Turbo')
    textMuted('Start here. Finish these checks first; the details can wait.')

    local iniOk = app.error == '' and app.iniPath ~= ''
    local turboRunning = isTurboRunning()
    ImGui.TextColored(0.72, 0.82, 0.95, 1.0, asciiText(nextStepMessage(iniOk, app.e3Ok, turboRunning)))

    ImGui.Separator()
    coloredStatus()
    if app.iniPath ~= '' and not app.copied then
        textPath(app.iniPath)
    end
    if app.error ~= '' then
        ImGui.TextColored(0.9, 0.35, 0.35, 1.0, asciiText(app.error))
    end

    ImGui.Dummy(0, 2)
    sectionTitle('Get looting in 3 steps')
    drawStatusRow('Step 1 - TurboLoot INI', iniOk, iniOk and shortMqPath(app.iniPath) or 'Create or import a turboloot INI in Config',
        'Manage INIs', function() routeTurboTab('setup') end,
        'Open Turbo Setup to create, clone, import, export, and assign INI profiles.')
    drawStatusRow('Step 2 - E3 corpse hooks', app.e3Ok == true, app.e3Detail or 'Checking...',
        'Repair Hooks', runE3Setup,
        'Patches this E3 INI and quietly repairs current group hooks. It does not pick a looter or open Turbo UI on peers.')
    local turboAction = turboRunning and 'Show Turbo UI' or 'Open Turbo UI'
    drawStatusRow('Step 3 - Turbo UI', turboRunning, turboRunning and 'Running - pick looter on Setup, then press Loot' or 'Not running',
        turboAction, openTurboMain,
        turboRunning and 'Bring the Turbo window to the front.' or 'Launch the main Turbo UI.')

    if not turboRunning then
        ImGui.Dummy(0, 2)
        textMuted('No Turbo UI yet? Create the default INI here, then open Turbo and use Setup for named profiles.')
        ImGui.SetNextItemWidth(180)
        if ImGui.InputTextWithHint then
            app.iniCreateBuf = ImGui.InputTextWithHint('##qs_create_buf', 'turboloot.ini', app.iniCreateBuf or 'turboloot.ini')
        end
        ImGui.SameLine()
        if button('Create default INI##qs_standalone_create', 'successButton', 130, 24) then
            app.checked = false
            runCheck()
        end
        hoverTip('Creates turboloot.ini from the starter template when missing.')
    end

    ImGui.Separator()
    drawRecommendedNext()

    ImGui.Separator()
    textMuted('Need the full map of rules, INIs, and tools? Open Learn More.')
    if button('Open Learn More##qs_learn_cta', 'secondaryButton', 160, 26) then
        app.page = 'learn'
    end
end

local function drawLearnMorePage()
    ImGui.TextColored(0.95, 0.78, 0.34, 1.0, 'Turbo Guide')
    textMuted('Open the section for the job you want to learn next.')

    ImGui.Separator()
    if guideSection('Loot Rules', true) then
        textMuted('Rules tell Turbo what to do when an item drops. Start with Rule Packs, then review or tune rules as you play.')
        drawRuleWords()
        if button('Open Rule Packs##qs_lm_rulepacks', 'primaryButton', 150, 26) then openRulePacks() end
        hoverTip('Browse starter loot lists and merge rules into your INI.')
        ImGui.SameLine()
        if button('Open Review##qs_lm_review', 'secondaryButton', 130, 26) then routeTurboTab('review') end
        hoverTip('Review skipped items, hunting alerts, reloot, and rule pack results.')
    end

    ImGui.Separator()
    if guideSection('After Looting', false) then
        textMuted('Use SELL, BANK, TRIBUTE, and DESTROY rules to clean up after farming. Unload runs the cleanup flow from the Actions tab.')
        if button('Open Actions##qs_lm_actions', 'primaryButton', 135, 26) then routeTurboTab('actions') end
        hoverTip('Open the Actions tab for Sell, Bank, Tribute, Unload, and helper commands.')
        ImGui.SameLine()
        if button('TurboWares##qs_lm_wares', 'secondaryButton', 130, 26) then openWares() end
        hoverTip('Open the merchant sidecar for selling tagged items and merchant watch lists.')
    end

    ImGui.Separator()
    if guideSection('Giving Items', false) then
        textMuted('TurboGive moves items and coin between characters. Use it after loot is sorted, not as part of first setup.')
        if button('TurboGive Help##qs_lm_give_help', 'primaryButton', 150, 26) then mq.cmd('/mac turbogive help') end
        hoverTip('Print the full TurboGive command help in chat.')
        ImGui.SameLine()
        if button('Open Actions##qs_lm_give_actions', 'secondaryButton', 135, 26) then routeTurboTab('actions') end
        hoverTip('Open the Actions tab where TurboGive helper buttons live.')
    end

    ImGui.Separator()
    if guideSection('Gear and Needs', false) then
        textMuted('TurboGear tracks worn gear, BiS lists, aug comparisons, custom lists, and who needs linked drops.')
        if button('Open TurboGear##qs_lm_gear', 'primaryButton', 150, 26) then openTurboGear() end
        hoverTip('Open or toggle TurboGear.')
    end

    ImGui.Separator()
    if guideSection('Spawn Tracking', false) then
        textMuted('TurboMobs handles named watches, zone alerts, respawn timers, and navigation to tracked mobs.')
        if button('Open TurboMobs##qs_lm_mobs', 'primaryButton', 150, 26) then openTurboMobs() end
        hoverTip('Open or toggle TurboMobs.')
    end

    ImGui.Separator()
    if guideSection('Progress Tracking', false) then
        textMuted('TurboGains tracks AA, XP, platinum, and timed challenge progress while you play.')
        if button('Open TurboGains##qs_lm_gains', 'primaryButton', 150, 26) then openGains() end
        hoverTip('Open TurboGains without restarting Turbo.')
    end

    ImGui.Separator()
    if guideSection('INI Profiles', false) then
        drawIniToolsHelp()
        sectionTitle('How TurboLoot INI fits together')
        textMuted('1) Setup - Shared or Specific INI per character (Resync pushes to E3).')
        textMuted('2) ItemLimits - per-item rules via Review / TurboKey (KEEP, SELL, BANK, ...).')
        textMuted('3) Wildcards - prefix rules (Spell:, custom Wildcard1=) for loot/sell/bank.')
        textMuted('4) Turbo INI Config - global Settings (distance, channels, sell/bank toggles).')
    end

    ImGui.Separator()
    if guideSection('Where is everything?', false) then
        drawCompanionToolButtons()
        local tableFlags = bit32.bor(ImGuiTableFlags.BordersInnerV, ImGuiTableFlags.RowBg, ImGuiTableFlags.SizingStretchProp)
        if ImGui.BeginTable('##quickstart_tool_map', 2, tableFlags) then
            ImGui.TableSetupColumn('Core Turbo')
            ImGui.TableSetupColumn('Companion tools')
            ImGui.TableNextRow()
            ImGui.TableNextColumn(); ImGui.TextColored(0.78, 0.72, 0.58, 1.0, 'Core Turbo')
            ImGui.TableNextColumn(); ImGui.TextColored(0.78, 0.72, 0.58, 1.0, 'Companion tools')
            ImGui.TableNextRow()
            ImGui.TableNextColumn(); toolCell('Setup', {115, 155, 220}, 'looters, shared/specific INIs, INI tools')
            ImGui.TableNextColumn(); toolCell('TurboMobs', {245, 200, 88}, 'spawn watches, zone alerts, respawn timers')
            ImGui.TableNextRow()
            ImGui.TableNextColumn(); toolCell('Review', {115, 155, 220}, 'skips, Hunting alerts, reloot, Rule Packs')
            ImGui.TableNextColumn(); toolCell('TurboRolls', {245, 200, 88}, 'rolls, awards, mini view, announces')
            ImGui.TableNextRow()
            ImGui.TableNextColumn(); toolCell('Actions', {115, 155, 220}, 'manual loot, TurboGive, backups, xtank healer')
            ImGui.TableNextColumn(); toolCell('TurboGains', {85, 190, 95}, 'AA/XP/plat tracking and timed challenge')
            ImGui.TableNextRow()
            ImGui.TableNextColumn(); toolCell('Behavior', {115, 155, 220}, 'distance, value thresholds, channels, wildcards')
            ImGui.TableNextColumn(); toolCell('TurboWares', {55, 142, 118}, 'merchant sidecar, sell tags, buy watch list')
            ImGui.TableNextRow()
            ImGui.TableNextColumn(); toolCell('More', {115, 155, 220}, 'diagnostics, backups, links, folders')
            ImGui.TableNextColumn(); toolCell('TurboGear', {145, 150, 165}, 'worn gear, BiS lists, aug compare, announces')
            ImGui.EndTable()
        end
    end

    ImGui.Separator()
    local ar, ag, ab, aa = announceColor()
    ImGui.TextColored(ar, ag, ab, aa, "This is just the beginning. There's a crazy amount of things that you can do with these tools. Enjoy! -Drel")
end

local function drawFooter()
    app.dontShowAgain = ImGui.Checkbox("Don't show Quick Start automatically##qs_dismiss", app.dontShowAgain)

    local gap = ImGui.GetStyle().ItemSpacing.x
    local avail = ImGui.GetContentRegionAvail()
    local btnW = math.max(112, math.floor((avail - gap) / 2))
    if button('Recheck', 'secondaryButton', btnW) then
        app.checked = false
        app.error = ''
        app.status = 'Checking TurboLoot setup...'
    end
    hoverTip('Check again for turboloot.ini and recreate it from the starter template if needed.')
    ImGui.SameLine(0, gap)
    if button('Close', 'secondaryButton', btnW) then
        saveDismissPreference()
        app.open = false
    end
    hoverTip('Close this Quick Start window.')
end

local function render()
    if not app.checked then runCheck() end
    if not app.sizeInitialized then
        ImGui.SetNextWindowSize(820, 650, ImGuiCond.FirstUseEver)
        app.sizeInitialized = true
    end
    ImGui.SetNextWindowSizeConstraints(680, 520, 1200, 1400)
    ImGui.PushStyleVar(ImGuiStyleVar.WindowRounding, 8)
    ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 6)
    ImGui.PushStyleVar(ImGuiStyleVar.FramePadding, 8, 5)
    ImGui.PushStyleColor(ImGuiCol.WindowBg, IM_COL32(16, 19, 28, 248))
    ImGui.PushStyleColor(ImGuiCol.TitleBg, IM_COL32(24, 28, 40, 255))
    ImGui.PushStyleColor(ImGuiCol.TitleBgActive, IM_COL32(38, 52, 82, 255))
    ImGui.PushStyleColor(ImGuiCol.Border, IM_COL32(82, 112, 152, 220))
    local flags = 0
    local open, draw = ImGui.Begin('Turbo Quick Start###Turbo_Onboarding_Compact', app.open, flags)
    app.open = open
    if draw then
        drawPageTabs()
        ImGui.Separator()
        if app.page == 'learn' then
            drawLearnMorePage()
        else
            drawQuickStartPage()
        end
        ImGui.Separator()
        drawFooter()
    end
    ImGui.End()
    ImGui.PopStyleColor(4)
    ImGui.PopStyleVar(3)
end

mq.imgui.init('Turbo_Quick_Start', render)

while app.open do
    mq.delay(100)
end
