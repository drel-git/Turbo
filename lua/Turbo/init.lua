--[[
   *  *  *  *  *  *  *  *  *  *  [  T u r b o  ]  *  *  *  *  *  *  *  *  *  *
                       _____ _   _____________  _____ 
                       |_   _| | | | ___ \ ___ \|  _  |
                         | | | | | | |_/ / |_/ /| | | |
                         | | | | | |    /| ___ \| | | |
                         | | | |_| | |\ \| |_/ /\ \_/ / 
                         \_/  \___/\_| \_\____/  \___/
---------------------------------------------------------------------------------->
                  https://www.github.com/drel-git/TurboLoot
             Turbo v3.9.88 debug  -  suite hub / setup / toggle / pick group looter
             @version lua/Turbo/init.lua 3.9.88
---------------------------------------------------------------------------------->
    GUI mode:  /lua run Turbo  [optional: full | mini — layout + save]
    CLI modes:
        /lua run Turbo cycle       -- advance to next group member
        /lua run Turbo on          -- Turbo=true, pick if needed
        /lua run Turbo off         -- Turbo=false, looter=NOBODY
        /lua run Turbo all         -- toggle ALL-loot mode (everyone loots)
        /lua run Turbo CharName    -- set specific looter
        /lua run Turbo toggle [CharName]  -- UI-style ON/OFF toggle (keeps looter); Buttonmaster-friendly
        /lua run Turbo combatloot  -- toggle combat looting
        /lua run Turbo loot        -- send loot command for nearby corpses
        /lua run Turbo setup [File.ini] [local|driver|noreload]  -- INI hooks + queued /e3reload (~8s); default syncs group via quiet /e3bct hook repair. Use \atsetup driver\ax for this character only; \atnoreload\ax skips autoreload
        /lua run Turbo backup turbo|e3|all -- timestamped .bak copy beside INI
        /lua run Turbo patcher    -- launch TurboPatcher.exe (same as the More tab button)
        /turbopatcher             -- same, while the Turbo UI is already running
        /lua run Turbo diag clean -- remove old Turbo diagnostics bundles only
        /lua run Turbo view full|mini -- layout + save (alias: layout)
        /lua run Turbo doctor     -- print install/profile doctor when UI is closed
        /turbodoctor              -- same report while the Turbo UI is already running
        /turbosnapshot            -- active turboloot.ini settings, grouped + with descriptions
        /turbomain                -- show/hide main Turbo while the Turbo UI is already running
        /turbofocus               -- show main Turbo (open only; does not hide)
        /turbosetup               -- open Setup tab while the Turbo UI is already running
        /turboe3setup             -- patch E3 corpse hooks without restarting Turbo
        /turbogainswin            -- show/hide Turbo Gains window while the Turbo UI is already running
        /turbogainsopen           -- show Turbo Gains window (open only; does not hide)
        /turborulepacks           -- show/hide Rule Packs while the Turbo UI is already running
        /turbosettings            -- show/hide Turbo INI Config while the Turbo UI is already running
        /turbotools               -- show More while the Turbo UI is already running
        /turboreview              -- show/hide Review while the Turbo UI is already running
        /turbowares               -- show/hide TurboWares sidecar at merchants
]]

local mq = require('mq')
local ImGui = require('ImGui')
local Theme  = require('Turbo.theme')   -- centralized design tokens
local Ui = require('Turbo.ui.components')
local UiState = require('Turbo.ui.state')
local MiniView = require('Turbo.ui.views.mini')
local ActionsView = require('Turbo.ui.views.actions')
local FooterView = require('Turbo.ui.views.footer')

-- Single state + ImGui deps table so renderWindow stays under LuaJIT's 60-upvalue limit.
local TG = {
    mq = mq,
    ImGui = ImGui,
    paths = require('Turbo.paths'),
    sharedControl = require('Turbo.control'),
    iniHealth = require('Turbo.ini_health'),
    windowOpen = true,
    minimizedGUI = false,
    slimGUI = false,
    slimWhenExpanded = false,
    lastSlimGUIForResize = nil,
    lastSetupExpandedForResize = nil,
    members = {},
    statusMessage = '',
    lastActionMessage = '',
    sharedControlStatus = nil,
    lastRefreshMS = 0,
    lootRadius = '50',
    lootRadiusBuf = '50',
    startupInitDone = false,
    lastToggleMS = 0,
    profileList = {},
    profileSeen = {},
    profileSources = {},
    profileCacheLoaded = false,
    profileCacheSeeded = false,
    profileSettingsCache = {},
    logFileOn = false,
    cachedProfile = nil,
    profileInitialized = false,
    perCharProfile = false,
    charProfiles = {},
    multiLootMode = false,
    multiLooters = {},
    quickLootRoster = {},
    selectedChar = nil,
    turboKeyQty = '5',
    handQty = '1',
    lastCursorItem = nil,
    lastCursorRuleUndo = nil,
    actionRunMode = 'self',
    actionRunTargets = {},
    actionConfirm = nil,
    lootPulseUntilMS = 0,
    cachedLootActive = false,
    cachedLootActiveExpiry = 0,
    miniLootAnimation = true,
    selectedRulePack = nil,
    rulePackCache = nil,
    rulePackInfoCache = {},
    backupE3TargetName = '',
    stopAllActions = function()
        mq.cmd('/e3bcaa /endmacro')
        mq.cmd('/e3bcaa /nav stop')
        mq.cmd('/g HALT! all actions stopped')
    end,
    doctorBindActive = false,
    setupTabBindActive = false,
    e3SetupBindActive = false,
    gainsWinBindActive = false,
    focusBindActive = false,
    gainsOpenBindActive = false,
    --- Slim layout: INI/profile combo collapsed by default; expanded state is saved.
    slimIniExpanded = false,
    --- Slim footer: auto-clear status text so stacked status+cursor stays short.
    lastStatusMessageText = '',
    statusMessageShownAtMS = 0,
    --- Skip Review state
    skipReviewOpen = false,
    reviewWindowOpen = false,
    reviewFilterText = '',
    reviewFilterReason = 'All',
    reviewFilterSource = 'All',
    reviewMultiClickMode = false,
    tlSettingsWindowOpen = false,
    tlSettingsShowAdvanced = false,
    tlSettingsPage = 'settings',
    tlSettingsProfile = nil,
    tlSettingsDraft = nil,
    tlSettingsDraftProfile = nil,
    wildcardDraft = nil,
    wildcardDraftProfile = nil,
    giveDraft = nil,
    giveDraftProfile = nil,
    skipSelectedKey = nil,
    --- INI target for Skip Review rule writes: resolved from source field, overrideable via dropdown.
    skipIniTarget = '',               -- resolved filename (e.g. 'turbolootExample.ini')
    skipIniTargetOverride = nil,      -- nil = use auto-resolved; string = user-picked filename
    skipIniTargetOverridePath = nil,  -- 3.8.33: parallel full-path for apply_rule (set with override)
    lastSkipApplyMS = 0,              -- cooldown guard: ignore double-clicks < 500ms apart
    meleeToggleBlockUntilMS = 0,      -- Field Tools melee: block re-fire until /timed melee chain can apply
    lootToggleBlockUntilMS = 0,       -- Field Tools loot: block re-fire until ToggleTurboLoot can apply
    --- 3.8.59: staged snapshot for the Review tab's IGNORE ALL confirmation popup.
    ignoreAllStagedAt = 0,
    ignoreAllStagedSnapshot = nil,
    reviewConfirm = nil,
    reviewConfirmOpenRequested = false,
    --- __TL_SKIP__ listener: pre-built display rows, updated by the mq.event handler (not render loop).
    skipDisplayRows = nil,        -- nil = needs rebuild; table = ready to render
    --- Skip Review: resolve right-click inspect via MQ2LinkDB only on demand.
    skipReviewUseLinkDb = false,
    confirmSingleReviewRules = true,
    showReviewModeButtons = true,
    showQuickStartButton = true,
    quickStartDismissed = false,
    --- Suite update check (remote CHANGELOG); default on. Throttled in Turbo.update_check.
    checkForUpdates = true,
    updateCheckAt = 0,
    remoteTurboVersion = '',
    updateBannerDismissedVersion = '',
    turboUpdateAvailable = false,
    quickStartAutoShown = false,
    quickStartAutoReason = '',
    quickStartAutoLastCheck = 0,
    quickStartSeen = false,
    iniToolMode = nil,
    iniToolBuf = '',
    iniCloneSource = nil,
    gainsWindowOpen = false,
    gainsWindowOpenReason = '',
    gainsWindowOpenAt = 0,
    waresWindowOpen = true,
    waresAutoShow = true,
    waresTab = 'items',
    waresIniTargetOverride = nil,
    waresSelectedKey = nil,
    waresMerchantSelectedKey = nil,
    waresSearchItems = '',
    waresSearchMerchant = '',
    waresBuyQty = 1,
    waresRuleFilter = 'all',
    waresMerchantRuleFilter = 'all',
    waresHideEmptyStacks = true,
    waresSellInProgress = false,
    waresPendingSellNow = nil,
    waresPendingBuyNow = nil,
    waresWatchDraft = '',
    waresSidecarReady = false,
    huntingTargetName = '',
    huntingTargets = {},
    huntingDraftName = '',
    huntingEnabled = false,
    huntingBeep = true,
    huntingAnnounceTo = '',
    huntingAlertActive = false,
    huntingLastFoundName = '',
    huntingLastFoundAt = '',
    --- Top bar: red STOP halts macros/nav/HALT. Off by default for users who mis-click.
    showStopAllButton = false,
    startupToolsEnabled = false,
    startupToolSelections = { turbo = true },
    startupToolTargets = {},
    --- Skip Review: checked rows for batch actions.
    skipSelectionSet = nil,
    activeTab = 'actions',              -- tab nav: 'actions'|'setup'|'review'
    lastRelevantTab = 'setup',          -- Mini >> target; tracks last meaningful Full tab
    lootManagerPage = 'setup',          -- internal Loot Manager page: 'setup'|'review'
    --- Full Setup tab: 'loot' (INI / looters) or 'rulepacks' (merge + browser).
    setupSubTab = 'loot',
    lastActiveTab = nil,               -- tracks tab changes for window resize
    showMiniLooterPicker = false,
    showMiniRosterEditor = false,
    miniWindowPos = nil,
    fullWindowPos = nil,
    fullWindowSize = nil,
    gainsWindowPos = nil,
    reviewWindowPos = nil,
    layoutState = {},
    navState = {},
    lootManagerState = {},
    skipState = {},
    feedbackState = {},
    xtanksBroadcastCommand = '/squelch /e3bcga /mac turbo_xtar_heal',
    allaItemUrlBase = 'https://www.lazaruseq.com/alla/items/',
    allaNpcUrlBase = 'https://www.lazaruseq.com/alla/npcs/',
}

local args = { ... }
local cliMode = args[1] or nil
local cliArg2 = args[2] or nil
--- /lua run Turbo slim|full|mini opens the GUI in that layout (not a character name).
local guiStartupLayout = nil
if cliMode then
    local lc = cliMode:lower()
    if lc == 'full' or lc == 'slim' or lc == 'mini' then
        guiStartupLayout = lc
        cliMode = nil
    elseif lc == 'rulepacks' or lc == 'rules' or lc == 'packs' then
        guiStartupLayout = 'full'
        TG.activeTab = 'review'
        TG.reviewWindowOpen = true
        TG.skipReviewOpen = true
        TG.reviewSubPage = 'rulepacks'
        TG.rulePacksWindowOpen = false
        TG.rulePackBrowserNeedsManualLoad = false
        cliMode = nil
    elseif lc == 'settings' or lc == 'turbo-settings' then
        guiStartupLayout = 'full'
        TG.tlSettingsWindowOpen = true
        cliMode = nil
    elseif lc == 'tools' or lc == 'turbo-tools' then
        guiStartupLayout = 'full'
        TG.activeTab = 'tools'
        cliMode = nil
    elseif lc == 'gains' or lc == 'turbo-gains' then
        guiStartupLayout = 'full'
        TG.gainsWindowOpen = true
        TG.gainsWindowOpenReason = 'cli gains'
        TG.gainsWindowOpenAt = os.time()
        cliMode = nil
    elseif lc == 'review' or lc == 'turbo-review' then
        guiStartupLayout = 'full'
        TG.activeTab = 'review'
        TG.reviewWindowOpen = true
        TG.skipReviewOpen = true
        TG.reviewSubPage = 'review'
        cliMode = nil
    elseif lc == 'setup' or lc == 'turbo-setup' then
        guiStartupLayout = 'full'
        TG.activeTab = 'setup'
        TG.lastRelevantTab = 'setup'
        TG.lootManagerPage = 'setup'
        cliMode = nil
    elseif lc == 'first-run' or lc == 'firstrun' or lc == 'onboarding' then
        mq.cmd('/lua run Turbo/onboarding')
        cliMode = nil
    end
end

local scriptName = 'Turbo'
-- Suite version, parsed from lua/turbogear/CHANGELOG (the same file TurboGear and
-- TurboPatcher read), so every surface shows one number. The literal is only a
-- fallback for broken installs; per-file @version tags remain maintenance metadata.
local TURBO_VERSION = '1.2.1'
do
    local f = io.open((mq.luaDir or 'lua') .. '/turbogear/CHANGELOG', 'r')
    if f then
        for line in f:lines() do
            local v = line:match('^%s*(%d+%.%d+%.%d+)%s*$')
            if v then TURBO_VERSION = v break end
        end
        f:close()
    end
end
local TURBO_HUB_NAME = 'Turbo'
local TURBO_DOCTOR_BIND = '/turbodoctor'
local TURBO_URL = 'github.com/drel-git/TurboLoot'
--- Browser readme / releases (More page).
local TURBO_REPO_WEB = 'https://www.github.com/drel-git/TurboLoot'
local AUTO_REFRESH_MS = 1000

TG.luaScriptRunningAny = function(names)
    local lua = mq.TLO.Lua
    local function statusIsRunning(status)
        local text = tostring(status or ''):lower()
        if text == '' then return false end
        if text:find('not', 1, true) or text:find('stop', 1, true) or text:find('ended', 1, true) or text:find('ending', 1, true) then
            return false
        end
        return text == 'running' or text == 'run' or text:find('running', 1, true) ~= nil
    end
    for _, name in ipairs(names or {}) do
        local ok, status = pcall(function()
            local script = lua and lua.Script and lua.Script(name)
            if not script or not script.Status then return '' end
            return script.Status() or ''
        end)
        if ok and statusIsRunning(status) then return true end
        if mq.parse then
            local okParse, parsed = pcall(function()
                return mq.parse(string.format('${Lua.Script[%s].Status}', tostring(name)))
            end)
            if okParse and statusIsRunning(parsed) then return true end
        end
    end
    return false
end

TG.toggleQuickStartWindow = function()
    if TG.luaScriptRunningAny({ 'Turbo/onboarding', 'onboarding', 'Turbo_Quick_Start' }) then
        mq.cmd('/lua stop Turbo/onboarding')
        TG.statusMessage = 'Turbo Quick Start closed.'
        return false
    end
    mq.cmd('/lua run Turbo/onboarding')
    TG.statusMessage = 'Turbo Quick Start opened.'
    return true
end

local cachedLooter = nil
local cachedLooterExpiry = 0
local CACHE_TTL_MS = 1000
local MULTI_LOOT_STAGGER_DS = 10
local MAX_MULTI_LOOTERS = 6
TG.startupToolPrefix = 'TurboSuite_Start_'
TG.startupToolMaxLines = 12
TG.startupToolChoices = {
    { id = 'turbo',      label = 'Turbo',      cmd = '/lua run Turbo mini',               tip = 'Starts the compact Turbo control bar.' },
    { id = 'turbogear',  label = 'TurboGear',  cmd = '/lua run turbogear mini',           tip = 'Starts TurboGear minimized.' },
    { id = 'turborolls', label = 'TurboRolls', cmd = '/lua run TurboRolls',               tip = 'Starts TurboRolls.' },
    { id = 'turbogains', label = 'TurboGains', cmd = '/lua run Turbo/gains_toggle start', tip = 'Starts TurboGains tracking quietly.' },
    { id = 'turbomobs',  label = 'TurboMobs',  cmd = '/lua run TurboMobs',                tip = 'Starts TurboMobs.' },
}

local cachedTurbo = nil
local cachedTurboExpiry = 0
local cachedCombat = nil
local cachedCombatExpiry = 0
local cachedLootAll = nil
local cachedLootAllExpiry = 0

--- Forward declaration: body assigned below.
--- getEventLootRadius (defined next) captures this at parse time; must be local here.
local syncEventLootRadiusFromActiveProfiles

local cachedEventRadius    = nil
local cachedEventRadiusKey = ''  -- composite: looter|mode|profile

--- Must be defined before toggleLootAll / setLooter / setActiveProfile.
local function invalidateEventRadiusCache()
    cachedEventRadius    = nil
    cachedEventRadiusKey = ''
end

--- Cached wrapper. syncEventLootRadiusFromActiveProfiles is forward-declared above;
--- its body is assigned later once all helper functions it needs are defined.
local function getEventLootRadius(lootAllOn, multiModeOn, currentLooter)
    local key = tostring(lootAllOn) .. "|" .. tostring(multiModeOn)
        .. "|" .. tostring(currentLooter)
        .. "|" .. (TG.perCharProfile and "pc" or (TG.cachedProfile or "turboloot.ini"))
    if cachedEventRadiusKey == key and cachedEventRadius then
        return cachedEventRadius
    end
    local r = syncEventLootRadiusFromActiveProfiles(lootAllOn, multiModeOn, currentLooter)
    cachedEventRadius    = r
    cachedEventRadiusKey = key
    return r
end

--- Forward: body assigned below (toggleLootAll / setLooter / toggleCombatLoot call this earlier in file).
local saveSettings

local function nowMS() return mq.gettime() end
TG.startupT0 = nowMS()
TG.startupLastMS = TG.startupT0
TG.startupTrace = {}
TG.markStartup = function(label)
    local t = nowMS()
    TG.startupTrace[#TG.startupTrace + 1] = string.format('%s=%dms', label, t - TG.startupLastMS)
    TG.startupLastMS = t
end

TG.safeCall = function(fn, fallback)
    local ok, value = pcall(fn)
    if ok and value ~= nil then return value end
    return fallback
end

TG.clientInGame = function()
    local stateCandidates = {
        TG.safeCall(function() return mq.TLO.EverQuest.GameState() end, ''),
        TG.safeCall(function() return mq.TLO.GameState() end, ''),
    }
    for _, state in ipairs(stateCandidates) do
        local text = tostring(state or ''):lower()
        if text ~= '' and text ~= 'nil' and text ~= 'null' then
            if text:find('char', 1, true)
                or text:find('select', 1, true)
                or text:find('load', 1, true)
                or text:find('connect', 1, true)
                or text:find('disconnect', 1, true) then
                return false
            end
            if text:find('ingame', 1, true) or text:find('in game', 1, true) then
                return true
            end
        end
    end

    local me = tostring(TG.safeCall(function() return mq.TLO.Me.Name() end, '') or '')
    local zone = tostring(TG.safeCall(function() return mq.TLO.Zone.ShortName() end, '') or '')
    local meLower, zoneLower = me:lower(), zone:lower()
    return me ~= '' and meLower ~= 'nil' and meLower ~= 'null'
        and zone ~= '' and zoneLower ~= 'unknown' and zoneLower ~= 'nil' and zoneLower ~= 'null'
end

local function cleanProfileName(val)
    if not val then return nil end
    local s = tostring(val):match('^%s*(.-)%s*$') or ''
    if s:sub(1, 1) == '"' and s:sub(-1) == '"' then
        s = s:sub(2, -2)
    end
    if s == '' or s == 'NULL' or s == 'null' or s:match('^%$%b{}$') then
        return nil
    end
    return s
end

local function getCurrentLooter()
    local t = nowMS()
    if cachedLooter and t < cachedLooterExpiry then return cachedLooter end
    local val = mq.TLO.MQ2Mono.Query('e3,GrpMainLooter')()
    --- 3.8.63: sanitize unexpanded TLO placeholders. If MQ2Mono / E3 hasn't
    --- finished booting, or the var was published with a literal placeholder,
    --- the query returns the string '${GrpMainLooter}' instead of a real
    --- character name. Treat any '${...}' value as 'NOBODY' so every downstream
    --- label ("Single: X", "Set INI for X", "Set SINGLE: X", etc.) stays clean.
    --- mini.lua already has the same guard at its display site; centralizing
    --- it here fixes the Full view's Setup tab and any future call site.
    if val and val:find('${', 1, true) then val = nil end
    if val and val ~= '' and val ~= 'NULL' and val ~= 'NOBODY' then
        cachedLooter = val
        cachedLooterExpiry = t + CACHE_TTL_MS
        return val
    end
    local fallback = 'NOBODY'
    if TG.selectedChar and TG.selectedChar ~= '' and TG.selectedChar ~= 'NOBODY' then
        fallback = TG.selectedChar
    elseif TG.savedDefaultLooter and TG.savedDefaultLooter ~= '' and TG.savedDefaultLooter ~= 'NOBODY' then
        fallback = TG.savedDefaultLooter
    end
    cachedLooter = fallback
    cachedLooterExpiry = t + CACHE_TTL_MS
    return fallback
end

TG.getLiveMainLooter = function()
    local t = nowMS()
    if TG.cachedLiveMainLooter ~= nil and t < (tonumber(TG.cachedLiveMainLooterExpiry) or 0) then
        return TG.cachedLiveMainLooter
    end
    local val = mq.TLO.MQ2Mono.Query('e3,GrpMainLooter')()
    if val and val:find('${', 1, true) then val = nil end
    local live = 'NOBODY'
    if val and val ~= '' and val ~= 'NULL' and val ~= 'NOBODY' then live = val end
    TG.cachedLiveMainLooter = live
    TG.cachedLiveMainLooterExpiry = t + CACHE_TTL_MS
    return live
end

local function getProfileForMember(name)
    if TG.perCharProfile and name and name ~= '' and name ~= 'NOBODY' then
        local prof = cleanProfileName(TG.charProfiles[name])
        return prof or 'turboloot.ini'
    end
    return cleanProfileName(TG.cachedProfile) or 'turboloot.ini'
end

TG.getLiveProfileForMember = function(name)
    name = tostring(name or ''):match('^%s*(.-)%s*$') or ''
    local val = nil
    if name ~= '' and name ~= 'NOBODY' and mq.TLO.MQ2Mono and mq.TLO.MQ2Mono.Query then
        local me = mq.TLO.Me.Name() or ''
        if name:lower() == me:lower() then
            val = mq.TLO.MQ2Mono.Query('e3,TurboLootIni')()
        else
            val = mq.TLO.MQ2Mono.Query(string.format('e3,%s,TurboLootIni', name))()
        end
    end
    return cleanProfileName(val)
end

TG.e3Bool = function(val)
    local s = tostring(val or ''):lower()
    return s == 'true' or s == 'on' or s == '1'
end

local function getTurboState()
    local t = nowMS()
    local controlOwner = (TG.isSharedControlOwner and TG.isSharedControlOwner()) or false
    if controlOwner and TG.turboUiAuthoritative and TG.savedTurboOn ~= nil then
        return TG.savedTurboOn == true
    end
    if cachedTurbo ~= nil and t < cachedTurboExpiry then return cachedTurbo end
    local val = mq.TLO.MQ2Mono.Query('e3,Turbo')()
    cachedTurbo = TG.e3Bool(val)
    cachedTurboExpiry = t + CACHE_TTL_MS
    if not controlOwner and TG.savedTurboOn ~= cachedTurbo then
        TG.savedTurboOn = cachedTurbo
        TG.turboUiAuthoritative = false
    end
    return cachedTurbo
end

local function setTurboCache(val)
    cachedTurbo = val
    cachedTurboExpiry = nowMS() + CACHE_TTL_MS
end

local function getCombatLootState()
    local t = nowMS()
    if cachedCombat ~= nil and t < cachedCombatExpiry then return cachedCombat end
    local val = mq.TLO.MQ2Mono.Query('e3,CombatLoot')()
    cachedCombat = TG.e3Bool(val)
    cachedCombatExpiry = t + CACHE_TTL_MS
    return cachedCombat
end

local function setCombatCache(val)
    cachedCombat = val
    cachedCombatExpiry = nowMS() + CACHE_TTL_MS
end

local function getLootAllState()
    local t = nowMS()
    if cachedLootAll ~= nil and t < cachedLootAllExpiry then return cachedLootAll end
    local val = mq.TLO.MQ2Mono.Query('e3,GrpLootAll')()
    cachedLootAll = TG.e3Bool(val)
    cachedLootAllExpiry = t + CACHE_TTL_MS
    return cachedLootAll
end

local function setLootAllCache(val)
    cachedLootAll = val
    cachedLootAllExpiry = nowMS() + CACHE_TTL_MS
end

local function getMultiLooters()
    local selected = {}
    for _, name in ipairs(TG.members) do
        if TG.multiLooters[name] then
            table.insert(selected, name)
        end
    end
    return selected
end

local function isMultiLootMode()
    return TG.multiLootMode and #getMultiLooters() > 0
end

TG.getViableLooterNames = function()
    local names = {}
    for _, name in ipairs(TG.members) do
        if name and name ~= '' and name ~= 'NOBODY' then
            table.insert(names, name)
        end
    end
    return names
end

TG.hasConfiguredQuickRoster = function()
    for _, name in ipairs(TG.members) do
        if TG.quickLootRoster[name] then
            return true
        end
    end
    return false
end

TG.getQuickRosterNames = function()
    local names = {}
    local hasRoster = TG.hasConfiguredQuickRoster()
    for _, name in ipairs(TG.getViableLooterNames()) do
        if not hasRoster or TG.quickLootRoster[name] then
            table.insert(names, name)
        end
    end
    return names
end

local function setRouteVar(key, value)
    if not TG.clientInGame() then
        TG.statusMessage = 'Paused at character select; E3 var sync is disabled.'
        return
    end
    mq.cmdf('/e3varset %s %s', key, value)
    mq.cmdf('/e3bcga /e3varset %s %s', key, value)
    local t = nowMS()
    if key == 'GrpMainLooter' then
        local looter = tostring(value or '')
        if looter == '' or looter == 'NULL' then looter = 'NOBODY' end
        cachedLooter = looter
        cachedLooterExpiry = t + CACHE_TTL_MS
        TG.cachedLiveMainLooter = (looter ~= 'NOBODY') and looter or 'NOBODY'
        TG.cachedLiveMainLooterExpiry = t + CACHE_TTL_MS
    elseif key == 'Turbo' then
        cachedTurbo = TG.e3Bool(value)
        cachedTurboExpiry = t + CACHE_TTL_MS
    elseif key == 'CombatLoot' then
        cachedCombat = TG.e3Bool(value)
        cachedCombatExpiry = t + CACHE_TTL_MS
    elseif key == 'GrpLootAll' then
        cachedLootAll = TG.e3Bool(value)
        cachedLootAllExpiry = t + CACHE_TTL_MS
    end
end

TG.quoteCmdArg = function(value)
    return '"' .. tostring(value or ''):gsub('\\', '\\\\'):gsub('"', '\\"') .. '"'
end

TG.xtankRequestedTankName = function()
    local targetName = tostring((mq.TLO.Target.CleanName and mq.TLO.Target.CleanName()) or '')
    local targetType = tostring((mq.TLO.Target.Type and mq.TLO.Target.Type()) or ''):lower()
    if targetName ~= '' and targetType == 'pc' then return targetName end
    return ''
end

TG.xtankBroadcastCommand = function()
    local tank = TG.xtankRequestedTankName()
    if tank == '' then return TG.xtanksBroadcastCommand or '/squelch /e3bcga /mac turbo_xtar_heal' end
    return '/squelch /e3bcga /mac turbo_xtar_heal ' .. TG.quoteCmdArg(tank)
end

TG.setTurboLootIniVar = function(profile)
    if not TG.clientInGame() then
        TG.statusMessage = 'Paused at character select; TurboLootIni sync is disabled.'
        return
    end
    local quoted = TG.quoteCmdArg(profile)
    mq.cmdf('/e3varset TurboLootIni %s', quoted)
    mq.cmdf('/e3bcga /e3varset TurboLootIni %s', quoted)
end

TG.setTurboLootIniVarLocal = function(profile)
    if not TG.clientInGame() then
        TG.statusMessage = 'Paused at character select; TurboLootIni sync is disabled.'
        return
    end
    mq.cmdf('/e3varset TurboLootIni %s', TG.quoteCmdArg(profile))
end

TG.setTurboLootIniVarForTarget = function(target, profile)
    local quoted = TG.quoteCmdArg(profile)
    if target and target ~= '' and target ~= '*' then
        mq.cmdf('/e3bct %s /e3varset TurboLootIni %s', target, quoted)
    else
        TG.setTurboLootIniVarLocal(profile)
    end
end

--- Local-only E3 var (no /e3bcga). Used by `Turbo setup local`/`hooksonly` so a follow-up INI patch
--- on one boxer does not reset Turbo / looter routing for the whole group.
local function e3varsetLocal(key, value)
    if not TG.clientInGame() then
        TG.statusMessage = 'Paused at character select; E3 var sync is disabled.'
        return
    end
    mq.cmdf('/e3varset %s %s', key, value)
end

--- After setup writes INI entries, reset runtime loot vars. When `scopeSilent`, only this
--- session is touched (per-client /e3varset). Full `Turbo setup` still broadcasts via setRouteVar.
local function applySetupRuntimeDefaults(scopeSilent)
    local function setKV(k, v)
        if scopeSilent then
            e3varsetLocal(k, v)
        else
            setRouteVar(k, v)
        end
    end
    setKV('GrpLootMode', 'single')
    setKV('GrpMainLooter', 'NOBODY')
    setKV('Turbo', 'false')
    setKV('CombatLoot', 'false')
    setKV('GrpLootAll', 'false')
    for i = 1, MAX_MULTI_LOOTERS do
        setKV('GrpLoot' .. i, 'NOBODY')
    end
    setKV('LootRadius', tostring(DEFAULT_LOOT_RADIUS))
end

local function setTurboState(value)
    TG.savedTurboOn = value and true or false
    TG.turboUiAuthoritative = true
    TG.nextTurboReconcileMS = nowMS() + 1200
    setRouteVar('Turbo', value and 'true' or 'false')
    setTurboCache(value and true or false)
end

TG.reconcileTurboRouteVar = function()
    if not TG.turboUiAuthoritative or TG.savedTurboOn == nil then return end
    local due = tonumber(TG.nextTurboReconcileMS) or 0
    local t = nowMS()
    if t < due then return end

    if TG.isSharedControlOwner and not TG.isSharedControlOwner() then
        local live = TG.e3Bool(mq.TLO.MQ2Mono.Query('e3,Turbo')())
        TG.savedTurboOn = live
        TG.turboUiAuthoritative = false
        setTurboCache(live)
        TG.nextTurboReconcileMS = t + 10000
        return
    end

    local desired = TG.savedTurboOn == true
    local live = TG.e3Bool(mq.TLO.MQ2Mono.Query('e3,Turbo')())
    if live ~= desired then
        setRouteVar('Turbo', desired and 'true' or 'false')
        TG.nextTurboReconcileMS = t + 3000
        TG.statusMessage = desired
            and 'Turbo ON requested; retrying E3 Turbo route var...'
            or 'Turbo OFF requested; retrying E3 Turbo route var...'
    else
        TG.nextTurboReconcileMS = t + 10000
    end
end

local function setCombatState(value)
    TG.savedCombatLootOn = value and true or false
    setRouteVar('CombatLoot', value and 'true' or 'false')
    setCombatCache(value and true or false)
end

local function syncLootRouteVars()
    local allOn = getLootAllState()
    local selected = getMultiLooters()

    if allOn then
        setRouteVar('GrpLootMode', 'all')
        setRouteVar('GrpLootAll', 'true')
        setRouteVar('GrpMainLooter', 'NOBODY')
    elseif #selected > 0 then
        setRouteVar('GrpLootMode', 'multi')
        setRouteVar('GrpLootAll', 'false')
        setRouteVar('GrpMainLooter', 'NOBODY')
    else
        local looter = getCurrentLooter()
        if not looter or looter == '' or looter == 'NULL' then looter = 'NOBODY' end
        setRouteVar('GrpLootMode', 'single')
        setRouteVar('GrpLootAll', 'false')
        setRouteVar('GrpMainLooter', looter)
    end

    for i = 1, MAX_MULTI_LOOTERS do
        setRouteVar('GrpLoot' .. i, selected[i] or 'NOBODY')
    end
end

local clearMultiLooters, setSingleLooterMode

clearMultiLooters = function()
    TG.multiLootMode = false
    TG.multiLooters = {}
end

setSingleLooterMode = function(name)
    clearMultiLooters()
    if name and name ~= '' and name ~= 'NOBODY' then
        TG.selectedChar = name
        TG.savedDefaultLooter = name
        setRouteVar('GrpLootMode', 'single')
        setRouteVar('GrpMainLooter', name)
        setRouteVar('GrpLootAll', 'false')
        setLootAllCache(false)
        for i = 1, MAX_MULTI_LOOTERS do
            setRouteVar('GrpLoot' .. i, 'NOBODY')
        end
    end
end

local function toggleMultiLooter(name)
    if not name or name == '' or name == 'NOBODY' then return end
    if getLootAllState() then
        setRouteVar('GrpLootAll', 'false')
        setLootAllCache(false)
    end
    local wasSelected = TG.multiLooters[name] == true
    if not wasSelected and #getMultiLooters() == 0 then
        local single = getCurrentLooter()
        if single and single ~= '' and single ~= 'NOBODY' and single ~= name then
            TG.multiLooters[single] = true
        end
    end
    TG.selectedChar = name
    TG.multiLooters[name] = not wasSelected or nil
    TG.multiLootMode = #getMultiLooters() > 0
    if TG.multiLootMode then
        syncLootRouteVars()
        cachedLooter = 'NOBODY'
        cachedLooterExpiry = nowMS() + CACHE_TTL_MS
        TG.statusMessage = string.format('Multi loot: %d selected', #getMultiLooters())
    else
        syncLootRouteVars()
        TG.statusMessage = 'Multi loot: none selected'
    end
    saveSettings()
end

local function sendMultiLootCommands()
    local sent = 0
    for _, name in ipairs(getMultiLooters()) do
        local profile = getProfileForMember(name)
        local profileArg = TG.quoteCmdArg(profile)
        if sent == 0 then
            mq.cmdf('/squelch /e3bct %s /e3varset TurboLootIni %s', name, profileArg)
            mq.cmdf('/timed 2 /squelch /e3bct %s /mac TurboLoot', name)
        else
            mq.cmdf('/timed %d /squelch /e3bct %s /e3varset TurboLootIni %s', sent * MULTI_LOOT_STAGGER_DS, name, profileArg)
            mq.cmdf('/timed %d /squelch /e3bct %s /mac TurboLoot', sent * MULTI_LOOT_STAGGER_DS + 2, name)
        end
        sent = sent + 1
    end
    if sent > 0 then
        TG.lootPulseUntilMS = math.max(tonumber(TG.lootPulseUntilMS) or 0, nowMS() + (sent * MULTI_LOOT_STAGGER_DS * 100) + 12000)
    end
    return sent
end

TG.sendLootCommandTo = function(name, delayDs)
    if not name or name == '' or name == 'NOBODY' then return false end
    delayDs = tonumber(delayDs) or 0
    local profile = getProfileForMember(name)
    local profileArg = TG.quoteCmdArg(profile)
    if delayDs <= 0 then
        mq.cmdf('/squelch /e3bct %s /e3varset TurboLootIni %s', name, profileArg)
        mq.cmdf('/timed 2 /squelch /e3bct %s /mac TurboLoot', name)
    else
        mq.cmdf('/timed %d /squelch /e3bct %s /e3varset TurboLootIni %s', delayDs, name, profileArg)
        mq.cmdf('/timed %d /squelch /e3bct %s /mac TurboLoot', delayDs + 2, name)
    end
    TG.lootPulseUntilMS = math.max(tonumber(TG.lootPulseUntilMS) or 0, nowMS() + (delayDs * 100) + 12000)
    return true
end

TG.sendHideAndLootCommandTo = function(name, delayDs)
    if not name or name == '' or name == 'NOBODY' then return false end
    delayDs = tonumber(delayDs) or 0
    local profile = getProfileForMember(name)
    local profileArg = TG.quoteCmdArg(profile)
    mq.cmdf('/timed %d /e3bct %s /gsay [Turbo] Reloot requested: showing hidden corpses before TurboLoot.', delayDs, name)
    mq.cmdf('/timed %d /squelch /e3bct %s /hidecorpse none', delayDs + 1, name)
    mq.cmdf('/timed %d /squelch /e3bct %s /e3varset TurboLootIni %s', delayDs + 4, name, profileArg)
    mq.cmdf('/timed %d /squelch /e3bct %s /mac TurboLoot', delayDs + 6, name)
    TG.lootPulseUntilMS = math.max(tonumber(TG.lootPulseUntilMS) or 0, nowMS() + ((delayDs + 6) * 100) + 12000)
    return true
end

TG.sendSharedAllLootCommand = function(delayDs)
    delayDs = tonumber(delayDs) or 0
    if not TG.perCharProfile then
        local liveProfile = mq.TLO.MQ2Mono.Query('e3,TurboLootIni')()
        local profile = cleanProfileName(TG.cachedProfile) or cleanProfileName(liveProfile) or 'turboloot.ini'
        local profileArg = TG.quoteCmdArg(profile)
        if delayDs <= 0 then
            mq.cmdf('/squelch /e3bcaa /e3varset TurboLootIni %s', profileArg)
            mq.cmd('/timed 2 /squelch /e3bcaa /mac TurboLoot')
        else
            mq.cmdf('/timed %d /squelch /e3bcaa /e3varset TurboLootIni %s', delayDs, profileArg)
            mq.cmdf('/timed %d /squelch /e3bcaa /mac TurboLoot', delayDs + 2)
        end
    else
        mq.cmdf('/timed %d /squelch /e3bcaa /mac TurboLoot', delayDs)
    end
    TG.lootPulseUntilMS = math.max(tonumber(TG.lootPulseUntilMS) or 0, nowMS() + (delayDs * 100) + 12000)
end

local function toggleLootAll()
    invalidateEventRadiusCache()
    local isOn = getLootAllState()
    if isOn then
        setRouteVar('GrpLootAll', 'false')
        setLootAllCache(false)
        syncLootRouteVars()
        mq.cmd('/e3bc /echo [Turbo] Loot ALL OFF.')
        TG.statusMessage = 'Loot ALL: OFF (single looter)'
    else
        clearMultiLooters()
        setRouteVar('GrpLootAll', 'true')
        setLootAllCache(true)
        syncLootRouteVars()
        mq.cmd('/e3bc /echo [Turbo] Loot ALL ON.')
        TG.statusMessage = 'Loot ALL: ON (everyone loots)'
    end
    saveSettings()
end

TG.setQuickRosterMember = function(name, enabled)
    if not name or name == '' or name == 'NOBODY' then return end
    if enabled then
        TG.quickLootRoster[name] = true
    else
        TG.quickLootRoster[name] = nil
        if TG.multiLooters[name] then
            TG.multiLooters[name] = nil
            TG.multiLootMode = #getMultiLooters() > 0
            syncLootRouteVars()
            cachedLooter = TG.multiLootMode and 'NOBODY' or cachedLooter
            cachedLooterExpiry = nowMS() + CACHE_TTL_MS
            TG.statusMessage = TG.multiLootMode
                and string.format('Multi loot: %d selected', #getMultiLooters())
                or 'Multi loot: none selected'
        end
        if not getLootAllState() and not TG.multiLootMode then
            local current = getCurrentLooter()
            if current == name then
                local fallback = nil
                for _, candidate in ipairs(TG.getQuickRosterNames()) do
                    if candidate ~= name then
                        fallback = candidate
                        break
                    end
                end
                if fallback and fallback ~= '' and fallback ~= 'NOBODY' then
                    setSingleLooterMode(fallback)
                    cachedLooter = fallback
                    cachedLooterExpiry = nowMS() + CACHE_TTL_MS
                    TG.selectedChar = fallback
                    TG.statusMessage = string.format('Looter set to: %s', fallback)
                end
            end
        end
    end
    saveSettings()
end

TG.toggleQuickRosterMember = function(name)
    if not name or name == '' or name == 'NOBODY' then return end
    if not TG.hasConfiguredQuickRoster() then
        for _, seedName in ipairs(TG.getViableLooterNames()) do
            TG.quickLootRoster[seedName] = true
        end
    end
    TG.setQuickRosterMember(name, not TG.quickLootRoster[name])
end

TG.getClampedWindowPos = function(pos, targetW, targetH)
    if not pos or pos.x == nil or pos.y == nil then return nil end
    local x, y = tonumber(pos.x) or 0, tonumber(pos.y) or 0
    local ok, io = pcall(ImGui.GetIO)
    if ok and io and io.DisplaySize then
        local ds = io.DisplaySize
        local maxX = math.max(0, (tonumber(ds.x) or 0) - (tonumber(targetW) or 0))
        local maxY = math.max(0, (tonumber(ds.y) or 0) - (tonumber(targetH) or 0))
        x = math.min(math.max(0, x), maxX)
        y = math.min(math.max(0, y), maxY)
    end
    return { x = x, y = y }
end

TG.ensureMultiSeed = function(preferredName)
    if #getMultiLooters() > 0 then return end
    local seed = preferredName
    if not seed or seed == '' or seed == 'NOBODY' then
        seed = getCurrentLooter()
    end
    if not seed or seed == '' or seed == 'NOBODY' then
        local roster = TG.getQuickRosterNames()
        seed = roster[1] or TG.members[1]
    end
    if seed and seed ~= '' and seed ~= 'NOBODY' then
        TG.multiLooters[seed] = true
    end
end

TG.setLootMode = function(mode, preferredName)
    mode = tostring(mode or ''):lower()
    invalidateEventRadiusCache()
    if mode == 'all' then
        if not getLootAllState() then
            toggleLootAll()
        end
        return
    end
    if getLootAllState() then
        setRouteVar('GrpLootAll', 'false')
        setLootAllCache(false)
    end
    if mode == 'multi' then
        TG.multiLootMode = true
        TG.ensureMultiSeed(preferredName)
        syncLootRouteVars()
        cachedLooter = 'NOBODY'
        cachedLooterExpiry = nowMS() + CACHE_TTL_MS
        TG.statusMessage = string.format('Multi loot: %d selected', #getMultiLooters())
        saveSettings()
        return
    end

    local single = preferredName
    if not single or single == '' or single == 'NOBODY' then
        single = getCurrentLooter()
    end
    if not single or single == '' or single == 'NOBODY' then
        local roster = TG.getQuickRosterNames()
        single = roster[1] or TG.members[1] or (mq.TLO.Me.Name() or '')
    end
    if single and single ~= '' and single ~= 'NOBODY' then
        TG.setLooter(single)
    end
end

local DEFAULT_LOOT_RADIUS = 50
local TOGGLE_DEBOUNCE_MS = 300

local function getLootRadius()
    return TG.lootRadius
end

local function getNearbyCorpseCount()
    local r = tonumber(getLootRadius()) or 50
    local count = mq.TLO.SpawnCount(string.format('npccorpse radius %d', r))()
    return count or 0
end

local function collectGroupMembers()
    local updated = {}
    local groupSize = mq.TLO.Group.Members() or 0
    local myName = mq.TLO.Me.Name()

    for i = 1, groupSize do
        local member = mq.TLO.Group.Member(i)
        if member() then
            local name = member.Name()
            local offline = member.Offline()
            if name and name ~= '' and not offline then
                table.insert(updated, name)
            end
        end
    end

    if myName and myName ~= '' then
        local found = false
        for _, n in ipairs(updated) do
            if n == myName then found = true; break end
        end
        if not found then
            table.insert(updated, myName)
        end
    end

    table.sort(updated, function(a, b)
        return a:lower() < b:lower()
    end)

    TG.members = updated
end

TG.addUniqueName = function(list, seen, name)
    name = tostring(name or ''):match('^%s*(.-)%s*$') or ''
    if name == '' or name == 'NOBODY' then return end
    if not seen[name:lower()] then
        seen[name:lower()] = true
        list[#list + 1] = name
    end
end

TG.addNamesFromDelimitedText = function(list, seen, text)
    text = tostring(text or '')
    for token in text:gmatch('[^,%s|;]+') do
        token = token:gsub('^<', ''):gsub('>$', '')
        TG.addUniqueName(list, seen, token)
    end
end

TG.collectOnlineCharacters = function()
    local updated, seen = {}, {}
    TG.addUniqueName(updated, seen, mq.TLO.Me.Name() or mq.TLO.Me.CleanName() or '')

    collectGroupMembers()
    for _, name in ipairs(TG.members or {}) do
        TG.addUniqueName(updated, seen, name)
    end

    local okEqbc, eqbcNames = pcall(function()
        if mq.TLO.EQBC and mq.TLO.EQBC.Names then return mq.TLO.EQBC.Names() end
        return nil
    end)
    if okEqbc then TG.addNamesFromDelimitedText(updated, seen, eqbcNames) end

    local okDannet, peers = pcall(function()
        if mq.TLO.DanNet and mq.TLO.DanNet.Peers then return mq.TLO.DanNet.Peers() end
        return nil
    end)
    if okDannet then TG.addNamesFromDelimitedText(updated, seen, peers) end

    table.sort(updated, function(a, b) return a:lower() < b:lower() end)
    TG.onlineCharacters = updated
    return updated
end

--- Count of other group members in this zone (same rules as TurboGive HandOutToGroup).
local function countHandRecipientsInZone()
    local grouped = mq.TLO.Me.Grouped and mq.TLO.Me.Grouped()
    if not grouped or grouped == 0 then return 0 end
    local nMembers = mq.TLO.Group.Members() or 0
    if nMembers < 1 then return 0 end
    local myName = mq.TLO.Me.Name() or ''
    local count = 0
    for i = 1, nMembers do
        local mem = mq.TLO.Group.Member(i)
        if mem and mem() then
            local name = mem.Name()
            if name and name ~= '' and name ~= myName then
                local id = 0
                local sp = mq.TLO.Spawn(string.format('pc %s', name))
                if sp and sp() and sp.ID then
                    id = tonumber(sp.ID()) or 0
                end
                if id <= 0 then
                    sp = mq.TLO.Spawn(name)
                    if sp and sp() and sp.ID then
                        id = tonumber(sp.ID()) or 0
                    end
                end
                if id > 0 then
                    count = count + 1
                end
            end
        end
    end
    return count
end

local lastLooterApplyName = nil
local lastLooterApplyMs = 0
local LOOTER_APPLY_DEBOUNCE_MS = 450

local function setLooter(name)
    if not name or name == '' then return end
    local t = nowMS()
    if lastLooterApplyName == name and (t - lastLooterApplyMs) < LOOTER_APPLY_DEBOUNCE_MS then
        return
    end
    lastLooterApplyName = name
    lastLooterApplyMs = t
    invalidateEventRadiusCache()
    setSingleLooterMode(name)
    mq.cmdf('/e3varset GrpMainLooter %s', name)
    mq.cmdf('/e3bc /echo [Turbo] Looter set to %s', name)
    cachedLooter = name
    cachedLooterExpiry = nowMS() + CACHE_TTL_MS
    TG.selectedChar = name
    TG.savedDefaultLooter = name
    TG.statusMessage = string.format('Looter set to: %s', name)
    saveSettings()
end

local function cycleToNext()
    local currentLooter = getCurrentLooter()
    collectGroupMembers()

    local foundCurrent = false
    local nextLooter = nil
    local firstName = nil

    for _, name in ipairs(TG.members) do
        if name == 'NOBODY' then goto continue end
        if not firstName then firstName = name end
        if foundCurrent and not nextLooter then
            nextLooter = name
        end
        if name == currentLooter then
            foundCurrent = true
        end
        ::continue::
    end

    if not nextLooter and firstName then
        nextLooter = firstName
    end

    if nextLooter then
        setLooter(nextLooter)
        TG.statusMessage = string.format('Looter: %s (was: %s)', nextLooter, currentLooter)
    else
        TG.statusMessage = 'No group members found to cycle.'
    end
end

local function lootNow()
    local corpses = getNearbyCorpseCount()
    if corpses == 0 then
        TG.statusMessage = 'No corpses nearby.'
        return
    end
    if getLootAllState() then
        TG.sendSharedAllLootCommand(0)
        TG.statusMessage = string.format('Loot ALL sent (%d corpses)', corpses)
        return
    end
    if isMultiLootMode() then
        local sent = sendMultiLootCommands()
        if sent < 1 then
            TG.statusMessage = 'No active looter configured. Open Setup to assign one.'
            return
        end
        TG.statusMessage = string.format('Loot MULTI sent to %d character(s), staggered %.1fs (%d corpses)',
            sent, MULTI_LOOT_STAGGER_DS / 10, corpses)
        return
    end
    local looter = getCurrentLooter()
    if looter == 'NOBODY' then
        TG.statusMessage = 'No active looter configured. Open Setup to assign one.'
        return
    end
    TG.sendLootCommandTo(looter, 0)
    TG.statusMessage = string.format('Loot sent to %s (%d corpses)', looter, corpses)
end

local function relootNow(scopeMode)
    scopeMode = tostring(scopeMode or ''):lower()
    if scopeMode == '' then
        if getLootAllState() then
            scopeMode = 'all'
        elseif isMultiLootMode() then
            scopeMode = 'multi'
        else
            scopeMode = 'single'
        end
    end
    if scopeMode == 'all' then
        mq.cmd('/e3bcaa /gsay [Turbo] Reloot ALL requested: showing hidden corpses before TurboLoot.')
        mq.cmd('/squelch /e3bcaa /hidecorpse none')
        TG.sendSharedAllLootCommand(6)
        TG.statusMessage = 'Reloot sent to ALL zone bots: show corpses, then TurboLoot'
        return
    end
    if scopeMode == 'group' then
        local sent = 0
        for _, name in ipairs(TG.members or {}) do
            if name and name ~= '' and name ~= 'NOBODY' then
                TG.sendHideAndLootCommandTo(name, sent * MULTI_LOOT_STAGGER_DS)
                sent = sent + 1
            end
        end
        if sent < 1 then
            TG.statusMessage = 'No group characters found for Reloot.'
            return
        end
        TG.statusMessage = string.format('Reloot GROUP sent to %d character(s)', sent)
        return
    end
    if scopeMode == 'multi' or scopeMode == 'picks' then
        local sent = 0
        local targets = {}
        if type(TG.actionRunTargets) == 'table' then
            local seen = {}
            for _, name in ipairs(TG.members or {}) do
                if TG.actionRunTargets[name] then
                    targets[#targets + 1] = name
                    seen[name:lower()] = true
                end
            end
            for name, enabled in pairs(TG.actionRunTargets) do
                if enabled and type(name) == 'string' and name ~= '' and not seen[name:lower()] then
                    targets[#targets + 1] = name
                end
            end
        end
        if #targets == 0 then targets = getMultiLooters() end
        for _, name in ipairs(targets) do
            TG.sendHideAndLootCommandTo(name, sent * MULTI_LOOT_STAGGER_DS)
            sent = sent + 1
        end
        if sent < 1 then
            TG.statusMessage = 'No Reloot picks selected.'
            return
        end
        TG.statusMessage = string.format('Reloot PICKS sent to %d character(s)', sent)
        return
    end
    local looter = getCurrentLooter()
    if looter == 'NOBODY' then
        TG.statusMessage = 'No active looter configured. Open Setup to assign one.'
        return
    end
    TG.sendHideAndLootCommandTo(looter, 0)
    TG.statusMessage = string.format('Reloot sent to %s', looter)
end

local function toggleCombatLoot()
    local isOn = getCombatLootState()
    if isOn then
        setCombatState(false)
        TG.statusMessage = 'Combat Loot: OFF'
    else
        setCombatState(true)
        TG.statusMessage = 'Combat Loot: ON'
    end
    saveSettings()
end

-- =========================================================
-- INI Profile switching
-- =========================================================

local function getConfigDir()
    local mqPath = mq.TLO.MacroQuest.Path() or ''
    if mqPath == '' then return nil end
    return mqPath .. '\\Config'
end

local function getCharProfilesPath()
    local dir = getConfigDir()
    if not dir then return nil end
    return dir .. '\\turbo_profiles.lua'
end

local function loadCharProfiles()
    local path = getCharProfilesPath()
    if not path then return end
    local f = io.open(path, 'r')
    if not f then return end
    local content = f:read('*a')
    f:close()
    if not content or content == '' then return end
    local fn = load('return ' .. content)
    if fn then
        local ok, tbl = pcall(fn)
        if ok and type(tbl) == 'table' then TG.charProfiles = tbl end
    end
end

local function saveCharProfiles()
    local path = getCharProfilesPath()
    if not path then return end
    local f = io.open(path, 'w')
    if not f then return end
    f:write('{\n')
    for k, v in pairs(TG.charProfiles) do
        f:write(string.format('  [%q] = %q,\n', k, v))
    end
    f:write('}\n')
    f:close()
end

-- =========================================================
-- Persistent GUI settings (shared across all characters)
-- =========================================================
--- Forward: real implementation is assigned below with profile picker (saveSettings runs first in file order).
local getActiveProfile

local function getSettingsPath()
    local dir = getConfigDir()
    if not dir then return nil end
    return dir .. '\\turbo_settings.lua'
end

--- Per-character settings: Config/turbo_settings_CharName.lua
--- Holds character-specific state (activeTab, looter, lootRadius, multiLooters).
--- Falls back gracefully if the char name is unavailable.
local function getCharSettingsPath()
    local dir = getConfigDir()
    if not dir then return nil end
    local charName = mq.TLO.Me.CleanName() or mq.TLO.Me.Name() or ''
    if charName == '' or charName == 'NULL' then
        return dir .. '\\turbo_settings.lua'  -- fallback to shared
    end
    return dir .. '\\turbo_settings_' .. charName .. '.lua'
end

saveSettings = function()
    -- Per-character settings: each character writes their own file.
    -- Shared turbo_settings.lua is left for legacy reads / first-run defaults.
    local path = getCharSettingsPath()
    if not path then return end
    local f = io.open(path, 'w')
    if not f then return end
    local layoutMode = 'full'
    if TG.minimizedGUI then layoutMode = 'mini'
    elseif TG.slimGUI then layoutMode = 'slim' end
    local looterNow = getCurrentLooter()
    if not looterNow or looterNow == '' or tostring(looterNow) == 'NULL' then looterNow = 'NOBODY' end
    f:write('{\n')
    -- Layout / UI state (per-char: each toon remembers their own view)
    f:write(string.format('  layoutMode = %q,\n', layoutMode))
    f:write(string.format('  minimizedGUI = %s,\n', tostring(TG.minimizedGUI)))
    f:write(string.format('  slimGUI = %s,\n', tostring(TG.slimGUI)))
    f:write(string.format('  slimWhenExpanded = %s,\n', tostring(TG.slimWhenExpanded)))
    f:write(string.format('  slimIniExpanded = %s,\n', tostring(TG.slimIniExpanded)))
    f:write(string.format('  activeTab = %q,\n', UiState.normalizeActiveTab(TG.activeTab)))
    f:write(string.format('  lastRelevantTab = %q,\n', UiState.normalizeRelevantTab(TG.lastRelevantTab)))
    f:write(string.format('  lootManagerPage = %q,\n', UiState.normalizeLootManagerPage(TG.lootManagerPage)))
    if TG.miniWindowPos and TG.miniWindowPos.x and TG.miniWindowPos.y then
        f:write(string.format('  miniWindowPos = { x = %.1f, y = %.1f },\n', TG.miniWindowPos.x, TG.miniWindowPos.y))
    end
    if TG.fullWindowPos and TG.fullWindowPos.x and TG.fullWindowPos.y then
        f:write(string.format('  fullWindowPos = { x = %.1f, y = %.1f },\n', TG.fullWindowPos.x, TG.fullWindowPos.y))
    end
    if TG.fullWindowSize and TG.fullWindowSize.w and TG.fullWindowSize.h then
        f:write(string.format('  fullWindowSize = { w = %.1f, h = %.1f },\n', TG.fullWindowSize.w, TG.fullWindowSize.h))
    end
    if TG.gainsWindowPos and TG.gainsWindowPos.x and TG.gainsWindowPos.y then
        f:write(string.format('  gainsWindowPos = { x = %.1f, y = %.1f },\n', TG.gainsWindowPos.x, TG.gainsWindowPos.y))
    end
    if TG.reviewWindowPos and TG.reviewWindowPos.x and TG.reviewWindowPos.y then
        f:write(string.format('  reviewWindowPos = { x = %.1f, y = %.1f },\n', TG.reviewWindowPos.x, TG.reviewWindowPos.y))
    end
    -- Loot config (per-char)
    -- `lootRadius` is the current live value; `savedLootRadius` is the explicit
    -- user-chosen radius that should WIN over turboloot.ini on next startup.
    f:write(string.format('  lootRadius = %q,\n', TG.lootRadius))
    f:write(string.format('  savedLootRadius = %q,\n', TG.lootRadius))
    f:write(string.format('  perCharProfile = %s,\n', tostring(TG.perCharProfile)))
    f:write(string.format('  multiLootMode = %s,\n', tostring(TG.multiLootMode)))
    f:write('  multiLooters = {\n')
    for k, v in pairs(TG.multiLooters) do
        if v then f:write(string.format('    [%q] = true,\n', k)) end
    end
    f:write('  },\n')
    f:write('  quickLootRoster = {\n')
    for k, v in pairs(TG.quickLootRoster) do
        if v then f:write(string.format('    [%q] = true,\n', k)) end
    end
    f:write('  },\n')
    -- Toggles
    f:write(string.format('  logFileOn = %s,\n', tostring(TG.logFileOn)))
    f:write(string.format('  skipReviewUseLinkDb = %s,\n', tostring(TG.skipReviewUseLinkDb)))
    f:write(string.format('  confirmSingleReviewRules = %s,\n', tostring(TG.confirmSingleReviewRules ~= false)))
    f:write(string.format('  showReviewModeButtons = %s,\n', tostring(TG.showReviewModeButtons ~= false)))
    f:write(string.format('  showQuickStartButton = %s,\n', tostring(TG.showQuickStartButton ~= false)))
    f:write(string.format('  quickStartDismissed = %s,\n', tostring(TG.quickStartDismissed == true)))
    f:write(string.format('  quickStartSeen = %s,\n', tostring(TG.quickStartSeen == true)))
    f:write(string.format('  checkForUpdates = %s,\n', tostring(TG.checkForUpdates ~= false)))
    f:write(string.format('  updateCheckAt = %d,\n', math.floor(tonumber(TG.updateCheckAt) or 0)))
    f:write(string.format('  remoteTurboVersion = %q,\n', tostring(TG.remoteTurboVersion or '')))
    f:write(string.format('  updateBannerDismissedVersion = %q,\n', tostring(TG.updateBannerDismissedVersion or '')))
    f:write(string.format('  showStopAllButton = %s,\n', tostring(TG.showStopAllButton ~= false)))
    f:write(string.format('  startupToolsEnabled = %s,\n', tostring(TG.startupToolsEnabled == true)))
    f:write('  startupToolSelections = {\n')
    for k, v in pairs(TG.startupToolSelections or {}) do
        if v then f:write(string.format('    [%q] = true,\n', tostring(k))) end
    end
    f:write('  },\n')
    f:write('  startupToolTargets = {\n')
    for k, v in pairs(TG.startupToolTargets or {}) do
        if v then f:write(string.format('    [%q] = true,\n', tostring(k))) end
    end
    f:write('  },\n')
    f:write(string.format('  miniLootAnimation = %s,\n', tostring(TG.miniLootAnimation ~= false)))
    f:write(string.format('  waresAutoShow = %s,\n', tostring(TG.waresAutoShow ~= false)))
    if TG.waresIniTargetOverride and TG.waresIniTargetOverride ~= '' then
        f:write(string.format('  waresIniTargetOverride = %q,\n', tostring(TG.waresIniTargetOverride)))
    else
        f:write('  waresIniTargetOverride = nil,\n')
    end
    f:write(string.format('  huntingTargetName = %q,\n', tostring(TG.huntingTargetName or '')))
    f:write('  huntingTargets = {\n')
    for _, name in ipairs(TG.huntingTargets or {}) do
        if name and tostring(name) ~= '' then f:write(string.format('    %q,\n', tostring(name))) end
    end
    f:write('  },\n')
    f:write(string.format('  huntingEnabled = %s,\n', tostring(TG.huntingEnabled == true)))
    f:write(string.format('  huntingBeep = %s,\n', tostring(TG.huntingBeep ~= false)))
    f:write(string.format('  huntingAnnounceTo = %q,\n', tostring(TG.huntingAnnounceTo or '')))
    -- E3 state snapshot
    f:write(string.format('  defaultGrpMainLooter = %q,\n', tostring(looterNow)))
    local turboForSave = (TG.savedTurboOn ~= nil) and TG.savedTurboOn or getTurboState()
    local combatForSave = (TG.savedCombatLootOn ~= nil) and TG.savedCombatLootOn or getCombatLootState()
    f:write(string.format('  defaultTurboOn = %s,\n', tostring(turboForSave == true)))
    f:write(string.format('  defaultCombatLootOn = %s,\n', tostring(combatForSave == true)))
    f:write(string.format('  defaultLootAllOn = %s,\n', tostring(getLootAllState())))
    if not TG.perCharProfile then
        f:write(string.format('  savedTurboLootIni = %q,\n', getActiveProfile()))
    else
        f:write('  savedTurboLootIni = nil,\n')
    end
    f:write(string.format('  rulePackArcadeScore = %d,\n', math.floor(tonumber(TG.rulePackArcadeScore) or 0)))
    f:write(string.format('  allaItemUrlBase = %q,\n', tostring(TG.allaItemUrlBase or '')))
    f:write(string.format('  allaNpcUrlBase = %q,\n', tostring(TG.allaNpcUrlBase or '')))
    local pending = TG.pendingSetupRestore
    if type(pending) == 'table' and (tonumber(pending.applyAfter) or 0) > os.time() then
        f:write(string.format(
            '  pendingSetupRestore = { looter = %q, turbo = %s, combat = %s, applyAfter = %d },\n',
            tostring(pending.looter or ''),
            tostring(pending.turbo == true),
            tostring(pending.combat == true),
            tonumber(pending.applyAfter) or 0))
    else
        f:write('  pendingSetupRestore = nil,\n')
    end
    f:write('}\n')
    f:close()
end

local function loadSettingsFromPath(path)
    if not path then return nil end
    local f = io.open(path, 'r')
    if not f then return nil end
    local raw = f:read('*a')
    f:close()
    if not raw or raw == '' then return nil end
    local fn = load('return ' .. raw)
    if not fn then return nil end
    local ok, tbl = pcall(fn)
    if not ok or type(tbl) ~= 'table' then return nil end
    return tbl
end

local function applySettingsTable(tbl)
    if not tbl then return end
    if tbl.lootRadius then
        TG.lootRadius = tostring(tonumber(tbl.lootRadius) or DEFAULT_LOOT_RADIUS)
        TG.lootRadiusBuf = TG.lootRadius
    end
    -- 3.8.29: user-chosen radius persists across sessions — ensureE3Vars honors this over turboloot.ini's lootDistance.
    if tbl.savedLootRadius then
        TG.savedLootRadius = tostring(tonumber(tbl.savedLootRadius) or DEFAULT_LOOT_RADIUS)
    end
    if tbl.perCharProfile ~= nil then TG.perCharProfile = tbl.perCharProfile end
    if tbl.multiLootMode ~= nil then TG.multiLootMode = tbl.multiLootMode end
    if type(tbl.multiLooters) == 'table' then TG.multiLooters = tbl.multiLooters end
    if type(tbl.quickLootRoster) == 'table' then TG.quickLootRoster = tbl.quickLootRoster end
    if tbl.logFileOn ~= nil then TG.logFileOn = tbl.logFileOn end
    if tbl.confirmSingleReviewRules ~= nil then TG.confirmSingleReviewRules = tbl.confirmSingleReviewRules ~= false end
    if tbl.showReviewModeButtons ~= nil then TG.showReviewModeButtons = tbl.showReviewModeButtons ~= false end
    if tbl.showQuickStartButton ~= nil then TG.showQuickStartButton = tbl.showQuickStartButton ~= false end
    if tbl.quickStartDismissed ~= nil then TG.quickStartDismissed = tbl.quickStartDismissed == true end
    if tbl.quickStartSeen ~= nil then TG.quickStartSeen = tbl.quickStartSeen == true end
    if tbl.checkForUpdates ~= nil then TG.checkForUpdates = tbl.checkForUpdates ~= false end
    if tbl.updateCheckAt ~= nil then TG.updateCheckAt = math.floor(tonumber(tbl.updateCheckAt) or 0) end
    if type(tbl.remoteTurboVersion) == 'string' then TG.remoteTurboVersion = tbl.remoteTurboVersion end
    if type(tbl.updateBannerDismissedVersion) == 'string' then
        TG.updateBannerDismissedVersion = tbl.updateBannerDismissedVersion
    end
    if tbl.showStopAllButton ~= nil then TG.showStopAllButton = tbl.showStopAllButton ~= false end
    if tbl.startupToolsEnabled ~= nil then TG.startupToolsEnabled = tbl.startupToolsEnabled == true end
    if type(tbl.startupToolSelections) == 'table' then TG.startupToolSelections = tbl.startupToolSelections end
    if type(tbl.startupToolTargets) == 'table' then TG.startupToolTargets = tbl.startupToolTargets end
    if tbl.miniLootAnimation ~= nil then TG.miniLootAnimation = tbl.miniLootAnimation ~= false end
    if tbl.waresAutoShow ~= nil then TG.waresAutoShow = tbl.waresAutoShow ~= false end
    if type(tbl.waresIniTargetOverride) == 'string' and tbl.waresIniTargetOverride ~= '' then
        TG.waresIniTargetOverride = tbl.waresIniTargetOverride
    end
    if type(tbl.huntingTargetName) == 'string' then
        TG.huntingTargetName = tbl.huntingTargetName
        TG.huntingDraftName = tbl.huntingTargetName
    end
    if type(tbl.huntingTargets) == 'table' then
        TG.huntingTargets = {}
        local seenHunt = {}
        for _, name in ipairs(tbl.huntingTargets) do
            local clean = tostring(name or ''):match('^%s*(.-)%s*$') or ''
            local key = clean:lower()
            if clean ~= '' and not seenHunt[key] then
                seenHunt[key] = true
                TG.huntingTargets[#TG.huntingTargets + 1] = clean
            end
        end
    elseif type(tbl.huntingTargetName) == 'string' and tbl.huntingTargetName ~= '' then
        TG.huntingTargets = { tbl.huntingTargetName }
    end
    if tbl.huntingEnabled ~= nil then TG.huntingEnabled = tbl.huntingEnabled == true end
    if tbl.huntingBeep ~= nil then TG.huntingBeep = tbl.huntingBeep ~= false end
    if type(tbl.huntingAnnounceTo) == 'string' then TG.huntingAnnounceTo = tbl.huntingAnnounceTo end
    if tbl.slimWhenExpanded ~= nil then TG.slimWhenExpanded = tbl.slimWhenExpanded end
    if tbl.slimIniExpanded ~= nil then TG.slimIniExpanded = tbl.slimIniExpanded end
    TG.skipReviewUseLinkDb = tbl.skipReviewUseLinkDb == true
    if tbl.layoutMode and type(tbl.layoutMode) == 'string' then
        local lm = tbl.layoutMode:lower()
        if lm == 'mini' then
            TG.minimizedGUI = true
            TG.slimGUI = false
        elseif lm == 'slim' then
            TG.minimizedGUI = false
            TG.slimGUI = true
            TG.slimWhenExpanded = true
        else
            TG.minimizedGUI = false
            TG.slimGUI = false
            TG.slimWhenExpanded = false
        end
    else
        if tbl.minimizedGUI ~= nil then TG.minimizedGUI = tbl.minimizedGUI end
        if tbl.slimGUI ~= nil then TG.slimGUI = tbl.slimGUI end
    end
    TG.savedDefaultLooter = tbl.defaultGrpMainLooter
    TG.savedTurboOn = tbl.defaultTurboOn
    TG.savedCombatLootOn = tbl.defaultCombatLootOn
    TG.savedLootAllOn = tbl.defaultLootAllOn
    TG.savedTurboLootIni = tbl.savedTurboLootIni
    -- activeTab persistence
    if type(tbl.activeTab) == 'string' then
        local savedTab = tostring(tbl.activeTab):lower()
        TG.activeTab = UiState.normalizeActiveTab(savedTab)
        if savedTab == 'money' or savedTab == 'gains' then TG.toolsSubTab = 'gains' end
    end
    if type(tbl.lastRelevantTab) == 'string' then TG.lastRelevantTab = UiState.normalizeRelevantTab(tbl.lastRelevantTab) end
    if type(tbl.lootManagerPage) == 'string' then TG.lootManagerPage = UiState.normalizeLootManagerPage(tbl.lootManagerPage) end
    if type(tbl.miniWindowPos) == 'table' and tbl.miniWindowPos.x and tbl.miniWindowPos.y then
        TG.miniWindowPos = { x = tonumber(tbl.miniWindowPos.x) or 0, y = tonumber(tbl.miniWindowPos.y) or 0 }
    end
    if type(tbl.fullWindowPos) == 'table' and tbl.fullWindowPos.x and tbl.fullWindowPos.y then
        TG.fullWindowPos = { x = tonumber(tbl.fullWindowPos.x) or 0, y = tonumber(tbl.fullWindowPos.y) or 0 }
    end
    if type(tbl.fullWindowSize) == 'table' and tbl.fullWindowSize.w and tbl.fullWindowSize.h then
        local w = tonumber(tbl.fullWindowSize.w) or 0
        local h = tonumber(tbl.fullWindowSize.h) or 0
        if w > 0 and h > 0 then TG.fullWindowSize = { w = w, h = h } end
    end
    if type(tbl.gainsWindowPos) == 'table' and tbl.gainsWindowPos.x and tbl.gainsWindowPos.y then
        TG.gainsWindowPos = { x = tonumber(tbl.gainsWindowPos.x) or 0, y = tonumber(tbl.gainsWindowPos.y) or 0 }
    end
    if type(tbl.reviewWindowPos) == 'table' and tbl.reviewWindowPos.x and tbl.reviewWindowPos.y then
        TG.reviewWindowPos = { x = tonumber(tbl.reviewWindowPos.x) or 0, y = tonumber(tbl.reviewWindowPos.y) or 0 }
    end
    if tbl.rulePackArcadeScore ~= nil then
        TG.rulePackArcadeScore = math.floor(tonumber(tbl.rulePackArcadeScore) or 0)
    end
    if type(tbl.allaItemUrlBase) == 'string' then TG.allaItemUrlBase = tbl.allaItemUrlBase end
    if type(tbl.allaNpcUrlBase) == 'string' then TG.allaNpcUrlBase = tbl.allaNpcUrlBase end
    if type(tbl.pendingSetupRestore) == 'table' then
        TG.pendingSetupRestore = tbl.pendingSetupRestore
    end
    if TG.activeTab == 'setup' or TG.activeTab == 'review' then
        TG.lootManagerPage = TG.activeTab == 'review' and 'review' or 'setup'
    end
    if tbl.layoutMode and type(tbl.layoutMode) == 'string' and tbl.layoutMode:lower() == 'slim' then
        TG.slimGUI = false
        TG.slimWhenExpanded = false
    end
    if not TG.minimizedGUI then
        TG.slimGUI = false
        TG.slimWhenExpanded = false
    end
end

local function loadSettings()
    -- Load shared defaults first, then per-char overrides on top.
    -- This means each character gets their own UI state while sharing
    -- any manually edited shared turbo_settings.lua as a baseline.
    local shared = loadSettingsFromPath(getSettingsPath())
    applySettingsTable(shared)
    local perChar = loadSettingsFromPath(getCharSettingsPath())
    applySettingsTable(perChar)  -- per-char wins on any key present in both
end

TG.getHuntingRuntimePath = function()
    local dir = getConfigDir()
    if not dir then return nil end
    return dir .. '\\Turbo_hunting.ini'
end

TG.writeHuntingRuntimeState = function()
    local path = TG.getHuntingRuntimePath and TG.getHuntingRuntimePath() or nil
    if not path then return false end
    local f = io.open(path, 'w')
    if not f then return false end
    f:write('[Settings]\n')
    f:write(string.format('enabled=%s\n', TG.huntingEnabled == true and 'TRUE' or 'FALSE'))
    f:write(string.format('targetName=%s\n', tostring(TG.huntingTargetName or '')))
    f:write(string.format('beep=%s\n', TG.huntingBeep ~= false and 'TRUE' or 'FALSE'))
    f:write(string.format('announceTo=%s\n', tostring(TG.huntingAnnounceTo or '')))
    f:write('\n[Items]\n')
    local targets = TG.huntingTargets or {}
    f:write(string.format('count=%d\n', #targets))
    for i, name in ipairs(targets) do
        f:write(string.format('%d=%s\n', i, tostring(name or '')))
    end
    f:write('\n[Alert]\n')
    f:write(string.format('active=%s\n', TG.huntingAlertActive == true and 'TRUE' or 'FALSE'))
    f:write(string.format('itemName=%s\n', tostring(TG.huntingLastFoundName or '')))
    f:write(string.format('foundAt=%s\n', tostring(TG.huntingLastFoundAt or '')))
    f:write(string.format('corpseId=%s\n', tostring(TG.huntingLastFoundCorpseId or '')))
    f:write(string.format('source=%s\n', tostring(TG.huntingLastFoundSource or '')))
    f:close()
    return true
end

TG.pollHuntingRuntimeAlert = function()
    local path = TG.getHuntingRuntimePath and TG.getHuntingRuntimePath() or nil
    if not path then return end
    local f = io.open(path, 'r')
    if not f then return end
    local section = ''
    local alert = {}
    local settings = {}
    local itemCount = 0
    local items = {}
    for line in f:lines() do
        local s = tostring(line or ''):match('^%s*(.-)%s*$') or ''
        local sec = s:match('^%[([^%]]+)%]$')
        if sec then
            section = sec
        else
            local k, v = s:match('^([^=]+)=(.*)$')
            if k then
                k = (k:match('^%s*(.-)%s*$') or ''):lower()
                v = v:match('^%s*(.-)%s*$') or ''
                if section == 'Alert' then
                    alert[k] = v
                elseif section == 'Settings' then
                    settings[k] = v
                elseif section == 'Items' then
                    if k == 'count' then
                        itemCount = tonumber(v) or 0
                    else
                        local idx = tonumber(k)
                        if idx and v ~= '' then items[idx] = v end
                    end
                end
            end
        end
    end
    f:close()
    if settings.enabled ~= nil then TG.huntingEnabled = tostring(settings.enabled):upper() == 'TRUE' end
    if settings.beep ~= nil then TG.huntingBeep = tostring(settings.beep):upper() ~= 'FALSE' end
    if settings.announceto ~= nil then TG.huntingAnnounceTo = settings.announceto end
    if itemCount > 0 or next(items) ~= nil then
        local loaded = {}
        local maxIdx = math.max(itemCount, 0)
        for idx in pairs(items) do if idx > maxIdx then maxIdx = idx end end
        for i = 1, maxIdx do
            local name = tostring(items[i] or ''):match('^%s*(.-)%s*$') or ''
            if name ~= '' then loaded[#loaded + 1] = name end
        end
        TG.huntingTargets = loaded
        if TG.normalizeHuntingTargets then TG.normalizeHuntingTargets() end
    end
    TG.huntingAlertActive = tostring(alert.active or ''):upper() == 'TRUE'
    TG.huntingLastFoundName = alert.itemname or TG.huntingLastFoundName or ''
    TG.huntingLastFoundAt = alert.foundat or TG.huntingLastFoundAt or ''
    TG.huntingLastFoundCorpseId = alert.corpseid or TG.huntingLastFoundCorpseId or ''
    TG.huntingLastFoundSource = alert.source or TG.huntingLastFoundSource or ''
end

TG.normalizeHuntingTargets = function()
    local out, seen = {}, {}
    for _, name in ipairs(TG.huntingTargets or {}) do
        local clean = tostring(name or ''):match('^%s*(.-)%s*$') or ''
        local key = clean:lower()
        if clean ~= '' and not seen[key] then
            seen[key] = true
            out[#out + 1] = clean
        end
    end
    TG.huntingTargets = out
    TG.huntingTargetName = out[1] or ''
    return out
end

TG.setHuntingTarget = function(itemName, sourceLabel)
    local target = tostring(itemName or ''):match('^%s*(.-)%s*$') or ''
    if target == '' then
        TG.statusMessage = 'Enter an item name for Hunting.'
        return false
    end
    local targets = TG.huntingTargets or {}
    local key = target:lower()
    for _, name in ipairs(targets) do
        if tostring(name or ''):lower() == key then
            TG.huntingDraftName = target
            TG.huntingEnabled = true
            TG.normalizeHuntingTargets()
            if saveSettings then saveSettings() end
            TG.writeHuntingRuntimeState()
            TG.statusMessage = string.format('Already hunting: %s', target)
            return true
        end
    end
    targets[#targets + 1] = target
    TG.huntingTargets = targets
    TG.normalizeHuntingTargets()
    TG.huntingDraftName = target
    TG.huntingEnabled = true
    TG.huntingAlertActive = false
    TG.huntingLastFoundName = ''
    TG.huntingLastFoundAt = ''
    TG.huntingLastFoundCorpseId = ''
    TG.huntingLastFoundSource = ''
    if saveSettings then saveSettings() end
    TG.writeHuntingRuntimeState()
    TG.statusMessage = string.format('Added Hunting target%s: %s',
        sourceLabel and sourceLabel ~= '' and (' from ' .. sourceLabel) or '', target)
    return true
end

--- Review right-click go loot: same best-effort pipeline as TurboGear linked-needs Go.
--- Gates: corpse id required; for local Me, abort on zone mismatch. Does not prove
--- the item is still on the corpse (TurboLoot GO reports not_found / empty).
--- characterOverride: optional group member name (any toon, not just designated looter).
TG.goLootReviewCorpse = function(row, statusSink, characterOverride)
    local setStatus = function(msg)
        msg = tostring(msg or '')
        if type(statusSink) == 'function' then
            statusSink(msg)
        else
            TG.statusMessage = msg
        end
    end
    local corpseId = tonumber(row and row.corpseId) or 0
    if corpseId <= 0 then
        setStatus('Go loot: no corpse ID on this skip row')
        return false
    end
    local itemName = tostring(row and row.name or ''):match('^%s*(.-)%s*$') or ''
    if itemName == '' then
        setStatus('Go loot: no item name on this skip row')
        return false
    end
    local itemId = tonumber(row and row.itemId) or 0
    local me = tostring(mq.TLO.Me.Name() or '')
    local src = tostring(row and row.source or '')
    local character = me
    local override = tostring(characterOverride or ''):match('^%s*(.-)%s*$') or ''
    if override ~= '' then
        character = override
    elseif src ~= '' and src ~= 'cli' and src:lower() ~= me:lower() then
        character = src
    end

    if character:lower() == me:lower() then
        local zone = tostring(row and row.zone or '')
        local myZone = ''
        pcall(function() myZone = tostring(mq.TLO.Zone.ShortName() or '') end)
        if zone ~= '' and myZone ~= '' and zone:lower() ~= myZone:lower() then
            setStatus(string.format('Go loot: corpse was in %s; you are in %s', zone, myZone))
            return false
        end
    end

    -- Match TurboGear linked-needs routing: /tgearbg is only bound on the bg
    -- responder; the UI binds /tgear and runs the same goloot dispatcher.
    local bgRunning = TG.luaScriptRunningAny
        and TG.luaScriptRunningAny({ 'turbogear_bg', 'TurboGear_bg' })
    local uiRunning = TG.luaScriptRunningAny
        and TG.luaScriptRunningAny({ 'turbogear', 'TurboGear' })
    if bgRunning then
        mq.cmdf('/squelch /tgearbg goloot %s %d %d %s', character, corpseId, itemId, itemName)
        setStatus(string.format('Go loot: %s -> %s (corpse %d)', character, itemName, corpseId))
        return true
    end
    if uiRunning then
        mq.cmdf('/squelch /tgear goloot %s %d %d %s', character, corpseId, itemId, itemName)
        setStatus(string.format('Go loot: %s -> %s (corpse %d)', character, itemName, corpseId))
        return true
    end

    if character:lower() == me:lower() then
        mq.cmdf('/mac TurboLoot go %d %s', corpseId, itemName)
        setStatus(string.format('Go loot (TurboLoot): %s (corpse %d)', itemName, corpseId))
        return true
    end

    setStatus('Go loot needs TurboGear running to send another character')
    return false
end

--- Candidates for Review Go loot picker: skip Src first, then Me, then group.
--- Not limited to designated looters. Returns { { name, label }, ... }.
TG.reviewGoLootCandidates = function(row)
    local me = tostring(mq.TLO.Me.Name() or '')
    local src = tostring(row and row.source or '')
    local default = me
    if src ~= '' and src ~= 'cli' then default = src end
    local out, seen = {}, {}
    local add = function(name, tag)
        name = tostring(name or ''):match('^%s*(.-)%s*$') or ''
        if name == '' or name == 'NOBODY' then return end
        local key = name:lower()
        if seen[key] then return end
        seen[key] = true
        local label = name
        if tag and tag ~= '' then label = name .. ' ' .. tag end
        out[#out + 1] = { name = name, label = label }
    end
    if default:lower() == me:lower() then
        add(me, '(you)')
    else
        add(default, '(src)')
        add(me, '(you)')
    end
    for _, name in ipairs(TG.members or {}) do
        add(name)
    end
    return out
end

--- Draw Go loot submenu (group picker). Used by Full + quick Review context menus.
TG.renderReviewGoLootMenu = function(row, menuId, statusSink)
    if not row then return end
    local valid = tostring(row.corpseId or '') ~= '' and tostring(row.corpseId or '') ~= '0'
    if not valid then
        Ui.menuItem('Go loot##' .. menuId, nil, false, {95, 210, 145, 255})
        return
    end
    if ImGui.BeginMenu('Go loot##' .. menuId) then
        for _, cand in ipairs(TG.reviewGoLootCandidates(row)) do
            Ui.menuItem(cand.label .. '##' .. menuId .. '_' .. cand.name, function()
                TG.goLootReviewCorpse(row, statusSink, cand.name)
            end, true, {95, 210, 145, 255})
        end
        ImGui.EndMenu()
    end
end

TG.clearHuntingTarget = function()
    TG.huntingTargetName = ''
    TG.huntingTargets = {}
    TG.huntingDraftName = ''
    TG.huntingEnabled = false
    TG.huntingAlertActive = false
    TG.huntingLastFoundName = ''
    TG.huntingLastFoundAt = ''
    TG.huntingLastFoundCorpseId = ''
    TG.huntingLastFoundSource = ''
    if saveSettings then saveSettings() end
    TG.writeHuntingRuntimeState()
    TG.statusMessage = 'Hunting list cleared.'
end

TG.removeHuntingTarget = function(itemName)
    local target = tostring(itemName or ''):match('^%s*(.-)%s*$') or ''
    if target == '' then return end
    local key = target:lower()
    local out = {}
    for _, name in ipairs(TG.huntingTargets or {}) do
        if tostring(name or ''):lower() ~= key then out[#out + 1] = name end
    end
    TG.huntingTargets = out
    TG.normalizeHuntingTargets()
    if #out == 0 then TG.huntingEnabled = false end
    if saveSettings then saveSettings() end
    TG.writeHuntingRuntimeState()
    TG.statusMessage = 'Removed Hunting target: ' .. target
end

TG.drawHuntingPanel = function(g, tip, actionBtnH)
    local state = TG
    if TG.pollHuntingRuntimeAlert then TG.pollHuntingRuntimeAlert() end
    if TG.normalizeHuntingTargets then TG.normalizeHuntingTargets() end
    tip = tip or function() end
    actionBtnH = actionBtnH or 24
    state.huntingDraftName = tostring(state.huntingDraftName or '')
    local targets = state.huntingTargets or {}
    local targetN = #targets
    local enabled = state.huntingEnabled == true and targetN > 0
    ImGui.TextColored(0.78, 0.68, 0.38, 1.0, 'Hunting')
    ImGui.SameLine()
    if targetN > 0 then
        ImGui.TextColored(enabled and 0.90 or 0.55, enabled and 0.78 or 0.58, enabled and 0.42 or 0.62, 1.0,
            string.format('%s: %d item%s', enabled and 'ON' or 'OFF', targetN, targetN == 1 and '' or 's'))
    else
        ImGui.TextDisabled('No hunted items')
    end
    if state.huntingAlertActive then
        ImGui.SameLine()
        ImGui.TextColored(1.0, 0.55, 0.25, 1.0, 'FOUND')
    end

    ImGui.Dummy(0, 3)
    ImGui.TextColored(0.62, 0.66, 0.74, 1.0, 'Alerts / Announcements')
    ImGui.SameLine(0, 8)
    ImGui.TextDisabled('Announce via')
    ImGui.SameLine(0, 6)
    local announceOptions = {
        { label = 'Auto', value = '' },
        { label = 'echo', value = 'echo' },
        { label = 'gsay', value = 'gsay' },
        { label = 'rsay', value = 'rsay' },
        { label = 'e3bc', value = 'e3bc' },
        { label = 'say', value = 'say' },
    }
    local announceCurrent = tostring(state.huntingAnnounceTo or '')
    local announceLabel = announceCurrent ~= '' and announceCurrent or 'Auto'
    ImGui.PushItemWidth(92)
    if ImGui.BeginCombo('##hunting_announce_to', announceLabel) then
        for _, opt in ipairs(announceOptions) do
            if ImGui.Selectable(opt.label .. '##hunting_announce_' .. opt.label, announceCurrent == opt.value) then
                state.huntingAnnounceTo = opt.value
                if state.saveSettings then state.saveSettings() end
                TG.writeHuntingRuntimeState()
                state.statusMessage = 'Hunting announce channel: ' .. opt.label
            end
        end
        ImGui.EndCombo()
    end
    ImGui.PopItemWidth()
    tip('Channel for [HUNTING] alerts. Auto uses TurboLoot skip/default announce settings.')

    ImGui.Dummy(0, 3)
    local topAvail = Ui.availX(240)
    local topGap = math.max(ImGui.GetStyle().ItemSpacing.x, 6)
    local topBtnW = math.max(70, math.floor((topAvail - (topGap * 2)) / 3))
    if Ui.buttonVariant((state.huntingBeep ~= false and 'Beep ON' or 'Beep OFF') .. '##hunting_beep_top',
        state.huntingBeep ~= false and 'primaryButton' or 'secondaryButton', topBtnW, actionBtnH) then
        state.huntingBeep = not (state.huntingBeep ~= false)
        if state.saveSettings then state.saveSettings() end
        TG.writeHuntingRuntimeState()
    end
    tip('Play a beep when TurboLoot finds a hunted item.')
    ImGui.SameLine(0, topGap)
    if Ui.buttonVariant('Test Beep##hunting_test_beep', 'secondaryButton', topBtnW, actionBtnH) then
        mq.cmd('/beep')
    end
    tip('Play the current MQ beep once.')
    ImGui.SameLine(0, topGap)
    if Ui.buttonVariant(Ui.fitLabel('Open INI##hunting_open_ini_top', 'Open', topBtnW), 'secondaryButton', topBtnW, actionBtnH) then
        if TG.openHuntingRuntimeFile then TG.openHuntingRuntimeFile()
        else state.statusMessage = 'Hunting INI opener is not ready yet.' end
    end
    tip('Open Config\\Turbo_hunting.ini for direct editing.')
    ImGui.Dummy(0, 4)

    local huntAvail = ImGui.GetContentRegionAvail()
    local btnW = 42
    local gap = math.max(ImGui.GetStyle().ItemSpacing.x, 4)
    local visibleButtons = targetN > 0 and 4 or 3
    ImGui.PushItemWidth(math.max(120, huntAvail - (btnW * visibleButtons) - (gap * visibleButtons) - 12))
    if ImGui.InputTextWithHint then
        state.huntingDraftName = ImGui.InputTextWithHint(
            '##hunting_add_item_input',
            'item name to watch for',
            tostring(state.huntingDraftName or ''))
    else
        state.huntingDraftName = ImGui.InputText(
            '##hunting_add_item_input',
            tostring(state.huntingDraftName or ''))
    end
    ImGui.PopItemWidth()
    tip('Type any item name here, then Add. Hunting alerts do not change loot rules.')
    local enterAdds = false
    if ImGui.IsItemFocused and ImGui.IsKeyPressed and ImGuiKey and ImGuiKey.Enter then
        local okEnter, pressed = pcall(ImGui.IsKeyPressed, ImGuiKey.Enter)
        enterAdds = okEnter and pressed == true
    end
    ImGui.SameLine(0, gap)
    if Ui.buttonVariant('Add##hunting_set', 'secondaryButton', btnW, actionBtnH) or enterAdds then
        if TG.setHuntingTarget(state.huntingDraftName, 'manual entry') then
            state.huntingDraftName = ''
        end
    end
    tip('Add this typed item name to the Hunting alert list.')
    ImGui.SameLine(0, gap)
    if targetN == 0 then ImGui.BeginDisabled() end
    if Ui.buttonVariant((enabled and 'ON' or 'OFF') .. '##hunting_toggle',
        enabled and 'successButton' or 'secondaryButton', btnW, actionBtnH) then
        state.huntingEnabled = not enabled
        if state.huntingEnabled and targetN == 0 then state.huntingEnabled = false end
        if state.saveSettings then state.saveSettings() end
        TG.writeHuntingRuntimeState()
        state.statusMessage = string.format('Hunting alerts %s.', state.huntingEnabled and 'enabled' or 'disabled')
    end
    if targetN == 0 then ImGui.EndDisabled() end
    tip('Enable or disable Hunting alerts for the list.')
    ImGui.SameLine(0, gap)
    if not state.huntingAlertActive then ImGui.BeginDisabled() end
    if Ui.buttonVariant('Ack##hunting_ack', 'secondaryButton', btnW, actionBtnH) then
        state.huntingAlertActive = false
        state.huntingLastFoundName = ''
        state.huntingLastFoundAt = ''
        state.huntingLastFoundCorpseId = ''
        state.huntingLastFoundSource = ''
        TG.writeHuntingRuntimeState()
        state.statusMessage = 'Hunting alert acknowledged.'
    end
    if not state.huntingAlertActive then ImGui.EndDisabled() end
    tip('Acknowledge a found Hunting item alert.')
    if targetN > 0 then
        ImGui.SameLine(0, gap)
        if Ui.buttonVariant('Clear##hunting_clear', 'secondaryButton', btnW + 12, actionBtnH) then
            TG.clearHuntingTarget()
        end
        tip('Clear the Hunting list.')
    end

    if targetN > 0 then
        ImGui.Dummy(0, 6)
        local flags = ImGuiTableFlags.RowBg + ImGuiTableFlags.BordersInnerV + (ImGuiTableFlags.SizingStretchProp or ImGuiTableFlags.SizingStretchSame)
        local tableStyle = Ui.pushTableStyle()
        if ImGui.BeginTable('##hunting_targets_table', 3, flags, 0, math.min(260, 28 + (targetN * 24))) then
            ImGui.TableSetupColumn('#', ImGuiTableColumnFlags.WidthFixed, 36)
            ImGui.TableSetupColumn('Item')
            ImGui.TableSetupColumn('', ImGuiTableColumnFlags.WidthFixed, 58)
            ImGui.TableHeadersRow()
        for i, name in ipairs(targets) do
                ImGui.TableNextRow()
                ImGui.TableNextColumn()
                ImGui.TextColored(0.78, 0.62, 0.28, 1.0, tostring(i))
                ImGui.TableNextColumn()
                ImGui.TextColored(0.74, 0.82, 0.96, 1.0, tostring(name))
                ImGui.TableNextColumn()
                if Ui.buttonVariant('Remove##hunting_remove_' .. i, 'secondaryButton', 54, 0) then
                    TG.removeHuntingTarget(name)
                end
                tip('Remove ' .. tostring(name) .. ' from Hunting.')
            end
            ImGui.EndTable()
        end
        Ui.popTableStyle(tableStyle)
    end
end

getActiveProfile = function()
    if not TG.profileInitialized then
        TG.profileInitialized = true
        local val = mq.TLO.MQ2Mono.Query('e3,TurboLootIni')()
        if val and val ~= '' and val ~= 'NULL' then
            TG.cachedProfile = cleanProfileName(val)
        end
        loadCharProfiles()
    end
    if TG.perCharProfile then
        if TG.selectedChar and TG.charProfiles[TG.selectedChar] then
            return TG.charProfiles[TG.selectedChar]
        end
        return 'turboloot.ini'
    end
    return TG.cachedProfile or 'turboloot.ini'
end

local lastProfileApplyKey = nil
local lastProfileApplyMs = 0
local PROFILE_APPLY_DEBOUNCE_MS = 450

local function setActiveProfile(filename)
    if not filename or filename == '' then return end
    filename = cleanProfileName(filename)
    if not filename or filename == '' then return end
    local target = TG.perCharProfile and (TG.selectedChar or (mq.TLO.Me.Name() or '')) or '*'
    local debounceKey = target .. '\1' .. filename
    local t = nowMS()
    if lastProfileApplyKey == debounceKey and (t - lastProfileApplyMs) < PROFILE_APPLY_DEBOUNCE_MS then
        return
    end
    lastProfileApplyKey = debounceKey
    lastProfileApplyMs = t
    invalidateEventRadiusCache()
    if TG.addProfileCandidate then
        TG.addProfileCandidate(filename, true, true)
        if TG.saveProfileCache then TG.saveProfileCache() end
    end

    if TG.perCharProfile then
        local myName = mq.TLO.Me.Name() or ''
        if target == myName then
            TG.setTurboLootIniVarForTarget(nil, filename)
        else
            TG.setTurboLootIniVarForTarget(target, filename)
        end
        TG.charProfiles[target] = filename
        saveCharProfiles()
        TG.cachedProfile = filename
        TG.statusMessage = string.format('Profile: %s -> %s', target, filename)
    else
        TG.setTurboLootIniVar(filename)
        TG.cachedProfile = filename
        for _, name in ipairs(TG.members) do
            TG.charProfiles[name] = filename
        end
        saveCharProfiles()
        TG.statusMessage = string.format('Profile: %s (all chars)', filename)
    end
    saveSettings()
end

local function syncProfileAssignments()
    collectGroupMembers()
    local myName = mq.TLO.Me.Name() or ''

    if TG.perCharProfile then
        local sent = 0
        for _, name in ipairs(TG.members) do
            local profile = getProfileForMember(name)
            if name == myName then
                TG.setTurboLootIniVarForTarget(nil, profile)
            else
                TG.setTurboLootIniVarForTarget(name, profile)
            end
            sent = sent + 1
        end
        TG.statusMessage = string.format('Synced per-char INIs to %d character(s)', sent)
    else
        local profile = getActiveProfile()
        TG.setTurboLootIniVar(profile)
        TG.statusMessage = string.format('Synced shared INI: %s', profile)
    end
end

TG.refreshActiveIniState = function(forceRescan)
    if forceRescan and TG.rescanProfiles then
        TG.rescanProfiles()
    end

    local val = mq.TLO.MQ2Mono.Query('e3,TurboLootIni')()
    if val and val ~= '' and val ~= 'NULL' then
        TG.cachedProfile = cleanProfileName(val)
    end

    invalidateEventRadiusCache()
    syncEventLootRadiusFromActiveProfiles(getLootAllState(), isMultiLootMode(), getCurrentLooter())
end

local profilesScanned = false

--- Exclude runtime / sidecar files from the profile picker. Anything matching
--- the `turboloot*.ini` dir glob that is NOT a real user profile goes here.
--- Convention going forward: TurboLoot_<purpose>.ini (case-insensitive) is
--- reserved for runtime state (skip_queue, future history/cache/etc.) and
--- must never appear as a picker option.
--- Routed through TG (not a top-level local) to stay under LuaJIT's 200-local
--- main-chunk limit — adding one more local here pushes the compiler over.
TG.isRuntimeProfileName = function(name)
    if not name or name == '' then return false end
    return name:lower():find('^turboloot_', 1) ~= nil
end

TG.getProfileCachePath = function()
    local dir = getConfigDir()
    if not dir then return nil end
    return dir .. '\\Turbo_profile_cache.lua'
end

TG.profileFileLocation = function(name, allowLegacy)
    name = cleanProfileName(name)
    if not name or name == '' or TG.isRuntimeProfileName(name) then return nil, false, nil end
    local mqPath = mq.TLO.MacroQuest.Path() or ''
    if mqPath == '' then return nil, false, nil end

    local configPath = mqPath .. '\\Config\\' .. name
    local f = io.open(configPath, 'r')
    if f then f:close() return configPath, true, 'Config' end

    if allowLegacy ~= false then
        local macroPath = mqPath .. '\\Macros\\' .. name
        f = io.open(macroPath, 'r')
        if f then f:close() return macroPath, true, 'Macros' end
    end

    return configPath, false, 'Config'
end

TG.rebuildProfileList = function()
    local results = {}
    for _, name in pairs(TG.profileSeen or {}) do
        if name and name ~= '' then results[#results + 1] = name end
    end
    table.sort(results, function(a, b) return a:lower() < b:lower() end)
    TG.profileList = results
end

TG.addProfileCandidate = function(name, allowLegacy, includeMissing, deferRebuild)
    name = cleanProfileName(name)
    if not name or name == '' or TG.isRuntimeProfileName(name) then return false end
    local path, exists, source = TG.profileFileLocation(name, allowLegacy)
    if not exists and includeMissing ~= true then return false end

    TG.profileSeen = TG.profileSeen or {}
    TG.profileSources = TG.profileSources or {}
    local key = name:lower()
    TG.profileSeen[key] = name
    TG.profileSources[key] = exists and (source or 'Config') or 'missing'
    if not deferRebuild then TG.rebuildProfileList() end
    return true, path, exists, source
end

TG.loadProfileCache = function()
    if TG.profileCacheLoaded then return end
    TG.profileCacheLoaded = true
    local path = TG.getProfileCachePath()
    if not path then return end
    local f = io.open(path, 'r')
    if not f then return end
    local content = f:read('*a')
    f:close()
    if not content or content == '' then return end
    local fn = load('return ' .. content)
    if not fn then return end
    local ok, tbl = pcall(fn)
    if not ok or type(tbl) ~= 'table' then return end
    for k, v in pairs(tbl) do
        local name = type(v) == 'string' and v or (type(k) == 'string' and k or nil)
        if name then TG.addProfileCandidate(name, false, false, true) end
    end
    TG.rebuildProfileList()
end

TG.saveProfileCache = function()
    local path = TG.getProfileCachePath()
    if not path then return false end
    TG.rebuildProfileList()
    local f = io.open(path, 'w')
    if not f then return false end
    f:write('{\n')
    for _, name in ipairs(TG.profileList or {}) do
        f:write(string.format('  %q,\n', name))
    end
    f:write('}\n')
    f:close()
    return true
end

TG.seedKnownProfiles = function()
    TG.addProfileCandidate('turboloot.ini', true, true, true)
    local active = getActiveProfile()
    TG.addProfileCandidate(active, true, true, true)
    TG.addProfileCandidate(TG.cachedProfile, true, false, true)
    TG.addProfileCandidate(TG.savedTurboLootIni, true, false, true)
    for _, profile in pairs(TG.charProfiles or {}) do
        TG.addProfileCandidate(profile, true, false, true)
    end
    TG.rebuildProfileList()
end

TG.ensureProfileCacheSeeded = function()
    if TG.profileCacheSeeded then return end
    TG.profileCacheSeeded = true
    TG.loadProfileCache()
    TG.seedKnownProfiles()
    TG.saveProfileCache()
end

TG.refreshProfileCache = function()
    local start = nowMS()
    TG.profileSeen = {}
    TG.profileSources = {}
    TG.profileList = {}
    TG.profileCacheLoaded = false
    TG.profileCacheSeeded = false
    TG.ensureProfileCacheSeeded()
    return #TG.profileList, nowMS() - start
end

local function scanTurbolootProfiles()
    if profilesScanned then return end
    profilesScanned = true

    local mqPath = mq.TLO.MacroQuest.Path() or ''
    if mqPath == '' then return end

    TG.profileSeen = {}
    TG.profileSources = {}
    TG.profileList = {}

    local cmd = string.format('dir /b /a-d "%s\\Config\\turboloot*.ini" 2>nul', mqPath)
    local handle = io.popen(cmd)
    if handle then
        for line in handle:lines() do
            local name = line:gsub('[\r\n]', ''):match('^%s*(.-)%s*$')
            if name and name ~= '' and not TG.isRuntimeProfileName(name) then
                TG.addProfileCandidate(name, false, false, true)
            end
        end
        handle:close()
    end

    local macroCmd = string.format('dir /b /a-d "%s\\Macros\\turboloot*.ini" 2>nul', mqPath)
    local macroHandle = io.popen(macroCmd)
    if macroHandle then
        for line in macroHandle:lines() do
            local name = line:gsub('[\r\n]', ''):match('^%s*(.-)%s*$')
            if name and name ~= '' and not TG.isRuntimeProfileName(name) then
                TG.addProfileCandidate(name, true, false, true)
            end
        end
        macroHandle:close()
    end

    TG.seedKnownProfiles()
    TG.profileCacheSeeded = true
    TG.saveProfileCache()
end

local function rescanProfiles()
    profilesScanned = false
    local start = nowMS()
    scanTurbolootProfiles()
    return #TG.profileList, nowMS() - start
end

loadSettings()
if not cliMode and not guiStartupLayout then
    TG.activeTab = 'actions'
    TG.lastRelevantTab = 'actions'
end
TG.writeHuntingRuntimeState()
TG.markStartup('settings')
-- Profile discovery is cache-first; full directory scans stay behind explicit
-- refresh actions so opening Setup does not block on shell/file enumeration.
TG.markStartup('profiles')

if guiStartupLayout then
    if guiStartupLayout == 'mini' then
        TG.slimWhenExpanded = false
        TG.slimGUI = false
        TG.minimizedGUI = true
    elseif guiStartupLayout == 'slim' then
        TG.minimizedGUI = false
        TG.slimGUI = false
        TG.slimWhenExpanded = false
    else
        TG.minimizedGUI = false
        TG.slimGUI = false
        TG.slimWhenExpanded = false
    end
    saveSettings()
end

-- =========================================================
-- TurboKey: set item rules using Lua file I/O
-- (bypasses MQ2 /ini which fails with spaces in paths)
-- =========================================================
local DESTROY_RULES = { DESTROY = true, IGNORE = true, SKIP = true }

local function getTurbolootIniPath()
    local mqPath = mq.TLO.MacroQuest.Path() or ''
    if mqPath == '' then return nil end
    local profile = getActiveProfile()
    local candidates = {
        mqPath .. '\\Config\\' .. profile,
        mqPath .. '\\Macros\\' .. profile,
    }
    for _, p in ipairs(candidates) do
        local f = io.open(p, 'r')
        if f then f:close() return p end
    end
    if profile ~= 'turboloot.ini' then
        local fallbacks = {
            mqPath .. '\\Config\\turboloot.ini',
            mqPath .. '\\Macros\\turboloot.ini',
        }
        for _, p in ipairs(fallbacks) do
            local f = io.open(p, 'r')
            if f then f:close() return p end
        end
    end
    return candidates[1]
end

local function resolveTurbolootIniPathForProfile(profile)
    local function exists(path)
        local f = io.open(path, 'r')
        if f then f:close() return true end
        return false
    end
    local mqPath = mq.TLO.MacroQuest.Path() or ''
    if mqPath == '' then return nil, false end
    profile = cleanProfileName(profile)
    profile = (profile and profile ~= '' and profile ~= 'NULL') and profile or 'turboloot.ini'

    local candidates = {
        mqPath .. '\\Config\\' .. profile,
        mqPath .. '\\Macros\\' .. profile,
    }
    for _, p in ipairs(candidates) do
        if exists(p) then return p, true end
    end

    if profile ~= 'turboloot.ini' then
        local fallbacks = {
            mqPath .. '\\Config\\turboloot.ini',
            mqPath .. '\\Macros\\turboloot.ini',
        }
        for _, p in ipairs(fallbacks) do
            if exists(p) then return p, true end
        end
    end

    return candidates[1], false
end

local function listTurbolootInisInFolder(dir)
    local out = {}
    if not dir or dir == '' then return out end
    local cmd = string.format('dir /b /a-d "%s\\turboloot*.ini" 2>nul', dir)
    local handle = io.popen(cmd)
    if handle then
        for line in handle:lines() do
            local name = line:gsub('[\r\n]', ''):match('^%s*(.-)%s*$')
            --- Skip runtime files (TurboLoot_skip_queue.ini etc.) — see TG.isRuntimeProfileName.
            if name and name ~= '' and not TG.isRuntimeProfileName(name) then
                table.insert(out, name)
            end
        end
        handle:close()
    end
    table.sort(out, function(a, b) return a:lower() < b:lower() end)
    return out
end

local function writeIniKey(filePath, section, key, value)
    local lines = {}
    local f = io.open(filePath, 'r')
    if f then
        for line in f:lines() do table.insert(lines, line) end
        f:close()
    end

    local inSection = false
    local keyWritten = false
    local sectionFound = false
    local result = {}

    for _, line in ipairs(lines) do
        local sec = line:match('^%[(.-)%]%s*$')
        if sec then
            if inSection and not keyWritten then
                table.insert(result, key .. '=' .. value)
                keyWritten = true
            end
            if sec == section and sectionFound then
                inSection = true
                goto nextline
            end
            inSection = (sec == section)
            if inSection then sectionFound = true end
        elseif inSection then
            local k = line:match('^([^=]+)=')
            if k and k:match('^%s*(.-)%s*$') == key then
                table.insert(result, key .. '=' .. value)
                keyWritten = true
                goto nextline
            end
        end
        table.insert(result, line)
        ::nextline::
    end

    if not sectionFound then
        table.insert(result, '')
        table.insert(result, '[' .. section .. ']')
        table.insert(result, key .. '=' .. value)
    elseif not keyWritten then
        table.insert(result, key .. '=' .. value)
    end

    f = io.open(filePath, 'w')
    if not f then return false end
    for _, line in ipairs(result) do f:write(line .. '\n') end
    f:close()
    return true
end

--- Delete a key from an INI section entirely (1.1.0).
--- Rewrites the file omitting the matching line. Returns true if a deletion
--- occurred, false if the key wasn't found or I/O failed. Passed to
--- skipTracker.init so apply_rule can clean up orphan rule keys (e.g.
--- 'CrystallizedMarrow' left over from pre-Fix-B corrupted skip rows).
local function deleteIniKey(filePath, section, key)
    local f = io.open(filePath, 'r')
    if not f then return false end

    local lines = {}
    local inSection = false
    local deleted = false
    for line in f:lines() do
        local sec = line:match('^%[(.-)%]%s*$')
        if sec then
            inSection = (sec == section)
            lines[#lines + 1] = line
        elseif inSection then
            local k = line:match('^([^=]+)=')
            if k and k:match('^%s*(.-)%s*$') == key then
                deleted = true
                -- drop this line
            else
                lines[#lines + 1] = line
            end
        else
            lines[#lines + 1] = line
        end
    end
    f:close()

    if not deleted then return false end

    local wf = io.open(filePath, 'w')
    if not wf then return false end
    for _, line in ipairs(lines) do wf:write(line .. '\n') end
    wf:close()
    return true
end

--- Replace an entire INI section (removes duplicate headers) with new body lines.
--- bodyLines: strings without the [Section] header (keys, values, comments).
local function replaceIniSection(filePath, section, bodyLines)
    if not filePath or filePath == '' or not section or section == '' then return false end
    local lines = {}
    local f = io.open(filePath, 'r')
    if f then
        for line in f:lines() do table.insert(lines, line) end
        f:close()
    end

    local result = {}
    local insertAt = nil
    local i = 1
    while i <= #lines do
        local sec = lines[i]:match('^%[(.-)%]%s*$')
        if sec == section then
            if not insertAt then insertAt = #result + 1 end
            i = i + 1
            while i <= #lines and not lines[i]:match('^%[(.-)%]%s*$') do
                i = i + 1
            end
        else
            result[#result + 1] = lines[i]
            i = i + 1
        end
    end

    local block = { '[' .. section .. ']' }
    for _, line in ipairs(bodyLines or {}) do
        block[#block + 1] = line
    end

    if insertAt then
        local merged = {}
        for j = 1, insertAt - 1 do merged[#merged + 1] = result[j] end
        for _, line in ipairs(block) do merged[#merged + 1] = line end
        for j = insertAt, #result do merged[#merged + 1] = result[j] end
        result = merged
    else
        if #result > 0 and result[#result] ~= '' then result[#result + 1] = '' end
        for _, line in ipairs(block) do result[#result + 1] = line end
    end

    f = io.open(filePath, 'w')
    if not f then return false end
    for _, line in ipairs(result) do f:write(line .. '\n') end
    f:close()
    return true
end

local function readIniKey(filePath, section, key)
    local f = io.open(filePath, 'r')
    if not f then return nil end
    local inSection = false
    for line in f:lines() do
        local sec = line:match('^%[(.-)%]%s*$')
        if sec then
            inSection = (sec == section)
        elseif inSection then
            local k, v = line:match('^([^=]+)=(.*)')
            if k and k:match('^%s*(.-)%s*$') == key then
                f:close()
                return v
            end
        end
    end
    f:close()
    return nil
end

local function stripIniValueForDisplay(raw)
    if not raw then return '—' end
    local s = raw:match('^([^;]*)') or raw
    return (s:gsub('^%s+', ''):gsub('%s+$', ''))
end

local function readIniSectionPairs(filePath, section)
    local out = {}
    local f = io.open(filePath, 'r')
    if not f then return out end

    local inSection = false
    for line in f:lines() do
        local sec = line:match('^%s*%[(.-)%]%s*$')
        if sec then
            if inSection then break end
            inSection = (sec == section)
        elseif inSection then
            local k, v = line:match('^%s*([^;#][^=]-)%s*=%s*(.*)$')
            if k then
                table.insert(out, {
                    key = k:match('^%s*(.-)%s*$'),
                    value = stripIniValueForDisplay(v),
                })
            end
        end
    end

    f:close()
    return out
end

TG.rulePackSections = { 'ItemLimits', 'Wildcards' }

TG.getRulePackDir = function()
    local mqPath = mq.TLO.MacroQuest.Path() or ''
    if mqPath == '' then return nil end
    return mqPath .. '\\lua\\Turbo\\rulepacks'
end

TG.listRulePacks = function()
    local dir = TG.getRulePackDir()
    local out = {}
    if not dir or dir == '' then return out end
    local okLfs, lfs = pcall(require, 'lfs')
    if okLfs and lfs and lfs.dir then
        local okDir = pcall(function()
            for name in lfs.dir(dir) do
                if tostring(name or ''):lower():match('%.ini$') then
                    local attr = lfs.attributes(dir .. '\\' .. name)
                    if not attr or attr.mode == 'file' then
                        out[#out + 1] = name
                    end
                end
            end
        end)
        if okDir then
            table.sort(out, function(a, b) return a:lower() < b:lower() end)
            return out
        end
        out = {}
    end
    local cmd = string.format('dir /b /a-d "%s\\*.ini" 2>nul', dir)
    local handle = io.popen(cmd)
    if handle then
        for line in handle:lines() do
            local name = line:gsub('[\r\n]', ''):match('^%s*(.-)%s*$')
            if name and name ~= '' then
                out[#out + 1] = name
            end
        end
        handle:close()
    end
    table.sort(out, function(a, b) return a:lower() < b:lower() end)
    return out
end

TG.refreshRulePacks = function(force)
    if TG.rulePackCache and not force then return TG.rulePackCache end
    TG.rulePackCache = TG.listRulePacks()
    if force then
        TG.rulePackInfoCache = {}
    else
        TG.rulePackInfoCache = TG.rulePackInfoCache or {}
    end
    return TG.rulePackCache
end

TG.resolveRulePackPath = function(packName)
    packName = tostring(packName or ''):match('^%s*(.-)%s*$') or ''
    if packName == '' or packName:find('[\\/:]') then return nil end
    local dir = TG.getRulePackDir()
    if not dir then return nil end
    return dir .. '\\' .. packName
end

TG.readRulePackInfo = function(packName)
    local path = TG.resolveRulePackPath(packName)
    if not path then return nil end
    local title = packName:gsub('%.ini$', '')
    local desc = ''
    local total = 0
    local countSections = {}
    for _, section in ipairs(TG.rulePackSections) do countSections[section] = true end

    local f = io.open(path, 'r')
    if not f then return { name = packName, path = path, title = title, description = desc, total = total } end
    local section = ''
    for line in f:lines() do
        local sec = line:match('^%s*%[(.-)%]%s*$')
        if sec then
            section = sec
        elseif section == 'Pack' then
            local k, v = line:match('^%s*([^;#][^=]-)%s*=%s*(.*)$')
            if k then
                k = k:match('^%s*(.-)%s*$')
                v = stripIniValueForDisplay(v)
                if k == 'name' and v ~= '' and v ~= '—' then title = v end
                if k == 'description' and v ~= '' and v ~= '—' then desc = v end
            end
        elseif countSections[section] then
            local k = line:match('^%s*([^;#][^=]-)%s*=')
            if k and (k:match('^%s*(.-)%s*$') or '') ~= '' then
                total = total + 1
            end
        end
    end
    f:close()
    return { name = packName, path = path, title = title, description = desc, total = total }
end

--- ItemLimits rows from a rule pack .ini (for the pack browser UI).
TG.readRulePackItemLimits = function(packName)
    local path = TG.resolveRulePackPath(packName)
    if not path then return {} end
    return readIniSectionPairs(path, 'ItemLimits')
end

--- ItemLimits rows from any turboloot INI path (target profile search in rule pack browser).
TG.readItemLimitsIniPairs = function(iniPath)
    iniPath = tostring(iniPath or '')
    if iniPath == '' then return {} end
    return readIniSectionPairs(iniPath, 'ItemLimits')
end

--- Write one [ItemLimits] rule to an absolute turboloot INI path (browser / tools).
TG.writeItemLimitRule = function(iniPath, itemName, rule)
    iniPath = tostring(iniPath or '')
    itemName = tostring(itemName or ''):match('^%s*(.-)%s*$') or ''
    rule = tostring(rule or ''):match('^%s*(.-)%s*$') or ''
    if iniPath == '' or itemName == '' or rule == '' then return false end
    return writeIniKey(iniPath, 'ItemLimits', itemName, rule)
end

TG.cleanupRulePackAnnotations = function(iniPath)
    iniPath = tostring(iniPath or '')
    if iniPath == '' then return 0 end

    local f = io.open(iniPath, 'r')
    if not f then return 0 end
    local lines = {}
    for line in f:lines() do lines[#lines + 1] = line end
    f:close()

    local result = {}
    local removed = 0
    local function isRulePackAnnotationLine(line)
        line = tostring(line or '')
        return line:match('^%s*;%s*Turbo Rule Pack:') ~= nil
            or line:match('^%s*;%s*START TURBO RULEPACK:') ~= nil
            or line:match('^%s*;%s*END TURBO RULEPACK:') ~= nil
            or line:match('^%s*;%s*Active lines below were added by this rulepack%.%s*$') ~= nil
            or line:match('^%s*;%s*Existing user rules were not changed%. Rulepack suggestions are commented out below%.%s*$') ~= nil
            or line:match(';%s*rulepack suggestion;%s*existing user rule kept') ~= nil
    end
    for _, line in ipairs(lines) do
        if isRulePackAnnotationLine(line) then
            removed = removed + 1
        else
            result[#result + 1] = line
        end
    end
    if removed == 0 then return 0 end

    f = io.open(iniPath, 'w')
    if not f then return 0 end
    for _, line in ipairs(result) do f:write(line .. '\n') end
    f:close()
    return removed
end

TG.annotateItemLimitRule = function()
    return false
end

--- Read / remove one [ItemLimits] row (rule pack browser undo, tools).
TG.readItemLimitRule = function(iniPath, itemName)
    iniPath = tostring(iniPath or '')
    itemName = tostring(itemName or ''):match('^%s*(.-)%s*$') or ''
    if iniPath == '' or itemName == '' then return nil end
    return readIniKey(iniPath, 'ItemLimits', itemName)
end

TG.deleteItemLimitRule = function(iniPath, itemName)
    iniPath = tostring(iniPath or '')
    itemName = tostring(itemName or ''):match('^%s*(.-)%s*$') or ''
    if iniPath == '' or itemName == '' then return false end
    return deleteIniKey(iniPath, 'ItemLimits', itemName)
end

TG.getRulePackInfo = function(packName)
    if not packName or packName == '' then return nil end
    if not TG.rulePackInfoCache then TG.rulePackInfoCache = {} end
    if TG.rulePackInfoCache[packName] then return TG.rulePackInfoCache[packName] end
    TG.rulePackInfoCache[packName] = TG.readRulePackInfo(packName)
    return TG.rulePackInfoCache[packName]
end

TG.mergeRulePackIntoIni = function(packName, targetIniPath, overwrite)
    local packPath = TG.resolveRulePackPath(packName)
    if not packPath or not targetIniPath or targetIniPath == '' then
        return nil, 'Missing rule pack or target INI.'
    end
    local removedAnnotations = 0
    if TG.cleanupRulePackAnnotations then
        removedAnnotations = tonumber(TG.cleanupRulePackAnnotations(targetIniPath)) or 0
    end

    if overwrite then
        local added, skipped, overwritten, failed, invalid = 0, 0, 0, 0, 0
        local function isPlaceholderRuleForOverwrite(key)
            local compact = tostring(key or ''):upper():gsub('[%s%p_]+', '')
            return compact == '' or compact == 'NA' or compact == 'NIL' or compact == 'NULL' or compact == 'UNKNOWN'
        end
        for _, section in ipairs(TG.rulePackSections) do
            for _, pair in ipairs(readIniSectionPairs(packPath, section)) do
                local key = pair.key
                local value = pair.value
                if key and key ~= '' and value and value ~= '' then
                    if isPlaceholderRuleForOverwrite(key) then
                        invalid = invalid + 1
                    else
                        local existing = readIniKey(targetIniPath, section, key)
                        if existing == nil or existing == '' then
                            if writeIniKey(targetIniPath, section, key, value) then added = added + 1 else failed = failed + 1 end
                        elseif writeIniKey(targetIniPath, section, key, value) then
                            overwritten = overwritten + 1
                        else
                            failed = failed + 1
                        end
                    end
                end
            end
        end
        return {
            added = added,
            skipped = skipped,
            overwritten = overwritten,
            failed = failed,
            invalid = invalid,
            removedAnnotations = removedAnnotations,
        }
    end

    local targetLines = {}
    local f = io.open(targetIniPath, 'r')
    if f then
        for line in f:lines() do targetLines[#targetLines + 1] = line end
        f:close()
    end

    local existingBySection = {}
    for _, section in ipairs(TG.rulePackSections) do existingBySection[section] = {} end
    local currentSection = nil
    for _, line in ipairs(targetLines) do
        local sec = line:match('^%s*%[(.-)%]%s*$')
        if sec then
            currentSection = sec
        elseif existingBySection[currentSection] then
            local k = line:match('^%s*([^;#][^=]-)%s*=')
            if k then
                existingBySection[currentSection][(k:match('^%s*(.-)%s*$') or k):lower()] = true
            end
        end
    end

    local function isPlaceholderRule(key)
        local compact = tostring(key or ''):upper():gsub('[%s%p_]+', '')
        return compact == '' or compact == 'NA' or compact == 'NIL' or compact == 'NULL' or compact == 'UNKNOWN'
    end

    local function appendRulePackBlock(lines, section, block)
        if #block == 0 then return lines end
        local sectionStart, insertAt
        for i, line in ipairs(lines) do
            local sec = line:match('^%s*%[(.-)%]%s*$')
            if sec == section then
                sectionStart = i
                insertAt = #lines + 1
            elseif sectionStart and sec then
                insertAt = i
                break
            end
        end

        local result = {}
        if not sectionStart then
            for _, line in ipairs(lines) do result[#result + 1] = line end
            if #result > 0 and result[#result] ~= '' then result[#result + 1] = '' end
            result[#result + 1] = '[' .. section .. ']'
            for _, line in ipairs(block) do result[#result + 1] = line end
            return result
        end

        for i = 1, #lines do
            if i == insertAt then
                if result[#result] ~= '' then result[#result + 1] = '' end
                for _, line in ipairs(block) do result[#result + 1] = line end
                if lines[i] and lines[i] ~= '' then result[#result + 1] = '' end
            end
            result[#result + 1] = lines[i]
        end
        if insertAt == #lines + 1 then
            if result[#result] ~= '' then result[#result + 1] = '' end
            for _, line in ipairs(block) do result[#result + 1] = line end
        end
        return result
    end

    local added, skipped, overwritten, failed, invalid = 0, 0, 0, 0, 0
    local blocks = {}
    for _, section in ipairs(TG.rulePackSections) do
        local activeLines = {}
        for _, pair in ipairs(readIniSectionPairs(packPath, section)) do
            local key = pair.key
            local value = pair.value
            if key and key ~= '' and value and value ~= '' then
                local keyLower = key:lower()
                local exists = existingBySection[section] and existingBySection[section][keyLower]
                if isPlaceholderRule(key) then
                    invalid = invalid + 1
                elseif not exists then
                    activeLines[#activeLines + 1] = key .. '=' .. value
                    if existingBySection[section] then existingBySection[section][keyLower] = true end
                    added = added + 1
                elseif overwrite then
                    if writeIniKey(targetIniPath, section, key, value) then
                        overwritten = overwritten + 1
                    else
                        failed = failed + 1
                    end
                else
                    skipped = skipped + 1
                end
            end
        end

        if #activeLines > 0 then
            blocks[section] = activeLines
        end
    end

    if not overwrite then
        for _, section in ipairs(TG.rulePackSections) do
            if blocks[section] then
                targetLines = appendRulePackBlock(targetLines, section, blocks[section])
            end
        end

        if added > 0 or skipped > 0 then
            f = io.open(targetIniPath, 'w')
            if not f then return nil, 'Could not write target INI.' end
            for _, line in ipairs(targetLines) do f:write(line .. '\n') end
            f:close()
        end
    end

    return {
        added = added,
        skipped = skipped,
        overwritten = overwritten,
        failed = failed,
        invalid = invalid,
        removedAnnotations = removedAnnotations,
    }
end

TG.renderRulePacksPanel = function(g, activeProf, assignTarget, showAdvancedSetup, getProfileForMember, mutedWrap, tipFn, actionBtnH, rescanFn, openProfileFn)
    if ImGui.SetNextItemOpen and not g.rulePackLootSettingsSeen then
        ImGui.SetNextItemOpen(true)
        g.rulePackLootSettingsSeen = true
    end
    if not ImGui.CollapsingHeader('Rule pack loot settings###setup_rule_packs') then return end

    ImGui.PushTextWrapPos(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail())
    ImGui.TextColored(0.62, 0.72, 0.88, 1.0,
        'Rule packs are starter loot lists (KEEP, SELL, BANK, etc.). Pick a pack, check items below, then merge only what you want into your INI.')
    ImGui.PopTextWrapPos()
    ImGui.Dummy(0, 4)

    local autoTargetProfile = showAdvancedSetup and getProfileForMember(assignTarget) or activeProf
    if not g.rulePackBrowserTargetProfile then
        local autoLc = tostring(autoTargetProfile or ''):lower()
        if autoLc:find('example', 1, true) then
            for _, profile in ipairs(g.profileList or {}) do
                local p = cleanProfileName(profile)
                if p and p:lower() == 'turboloot.ini' then
                    g.rulePackBrowserTargetProfile = p
                    break
                end
            end
        end
    end
    local packTargetProfile = g.rulePackBrowserTargetProfile or autoTargetProfile
    packTargetProfile = cleanProfileName(packTargetProfile) or 'turboloot.ini'
    local packTargetPath = resolveTurbolootIniPathForProfile(packTargetProfile)

    local function pushRulePackInputStyle()
        ImGui.PushStyleColor(ImGuiCol.FrameBg, IM_COL32(25, 49, 82, 245))
        ImGui.PushStyleColor(ImGuiCol.FrameBgHovered, IM_COL32(38, 72, 116, 255))
        ImGui.PushStyleColor(ImGuiCol.FrameBgActive, IM_COL32(46, 88, 140, 255))
        ImGui.PushStyleColor(ImGuiCol.Button, IM_COL32(58, 96, 145, 255))
        ImGui.PushStyleColor(ImGuiCol.ButtonHovered, IM_COL32(76, 122, 180, 255))
        ImGui.PushStyleColor(ImGuiCol.ButtonActive, IM_COL32(46, 88, 140, 255))
    end

    ImGui.TextColored(0.48, 0.76, 1.0, 1.0, '1 Target INI')
    ImGui.SameLine()
    do
        local targetAvail = ImGui.GetContentRegionAvail()
        local openBtnW = 62
        pushRulePackInputStyle()
        ImGui.PushItemWidth(math.max(150, targetAvail - openBtnW - ImGui.GetStyle().ItemSpacing.x))
        if ImGui.BeginCombo('##rulepack_top_target_ini_combo', packTargetProfile) then
            if ImGui.Selectable('Auto: ' .. tostring(autoTargetProfile) .. '##rulepack_top_target_auto',
                g.rulePackBrowserTargetProfile == nil) then
                g.rulePackBrowserTargetProfile = nil
                packTargetProfile = cleanProfileName(autoTargetProfile) or 'turboloot.ini'
                packTargetPath = resolveTurbolootIniPathForProfile(packTargetProfile)
                g.rulePackBrowserIniRuleCacheSig = nil
            end
            local seenProfiles = {}
            for _, profile in ipairs(g.profileList or {}) do
                local p = cleanProfileName(profile)
                if p and p ~= '' and not seenProfiles[p:lower()] then
                    seenProfiles[p:lower()] = true
                    if ImGui.Selectable(p .. '##rulepack_top_target_' .. p, packTargetProfile:lower() == p:lower()) then
                        g.rulePackBrowserTargetProfile = p
                        packTargetProfile = p
                        packTargetPath = resolveTurbolootIniPathForProfile(packTargetProfile)
                        g.rulePackBrowserIniRuleCacheSig = nil
                    end
                end
            end
            ImGui.EndCombo()
        end
        ImGui.PopItemWidth()
        ImGui.PopStyleColor(6)
        tipFn('Choose which TurboLoot INI receives imported packs, search target checks, and per-item TurboKey rule writes.')
        ImGui.SameLine()
        if Ui.buttonVariant('Open##rulepack_top_target_open', 'secondaryButton', openBtnW, actionBtnH) then
            if openProfileFn then openProfileFn(packTargetProfile) end
        end
        tipFn('Open this target INI in your default text editor.')
    end
    local packs = TG.refreshRulePacks(false) or {}
    if #packs == 0 then
        ImGui.TextColored(0.95, 0.78, 0.34, 1.0, '2 Rule pack')
        ImGui.SameLine()
        mutedWrap('No rule packs found in lua\\Turbo\\rulepacks.')
        return
    end

    ImGui.TextColored(0.95, 0.78, 0.34, 1.0, '2 Rule pack')
    ImGui.SameLine()

    local selectedPack = g.rulePackBrowserPack or g.selectedRulePack
    if not selectedPack or selectedPack == '' then
        selectedPack = packs[1]
        g.rulePackBrowserPack = selectedPack
        g.selectedRulePack = selectedPack
    else
        local foundSelected = false
        for _, packName in ipairs(packs) do
            if packName == selectedPack then foundSelected = true; break end
        end
        if not foundSelected then
            selectedPack = packs[1]
            g.rulePackBrowserPack = selectedPack
            g.selectedRulePack = selectedPack
        end
    end

    local selectedInfo = TG.getRulePackInfo(selectedPack)
    local previewLabel = (selectedInfo and selectedInfo.title) or selectedPack
    if ImGui.BeginCombo then
        local refreshW = 112
        local packAvail = ImGui.GetContentRegionAvail()
        pushRulePackInputStyle()
        ImGui.PushItemWidth(math.max(150, packAvail - refreshW - ImGui.GetStyle().ItemSpacing.x))
        if ImGui.BeginCombo('##rulepack_combo', previewLabel) then
            for _, packName in ipairs(packs) do
                local info = TG.getRulePackInfo(packName)
                local label = ((info and info.title) or packName) .. '##rulepack_' .. packName
                local selected = g.rulePackBrowserPack == packName
                if ImGui.Selectable(label, selected) then
                    g.rulePackBrowserPack = packName
                    g.selectedRulePack = packName
                    selectedPack = packName
                    selectedInfo = info
                    g.rulePackBrowserRows = TG.readRulePackItemLimits(packName)
                    g.rulePackBrowserSelName = nil
                    g.rulePackBrowserSelSet = {}
                    g.rulePackBrowserSelList = {}
                    g.rulePackBrowserSelPackRule = ''
                    g.rulePackBrowserIniRuleCacheSig = nil
                end
                if selected then ImGui.SetItemDefaultFocus() end
            end
            ImGui.EndCombo()
        end
        ImGui.PopItemWidth()
        ImGui.PopStyleColor(6)
        ImGui.SameLine()
        if Ui.buttonVariant('Refresh packs##rulepack_refresh', 'secondaryButton', refreshW, actionBtnH) then
            packs = TG.refreshRulePacks(true) or {}
            g.statusMessage = string.format('Rule packs refreshed: %d found', #packs)
        end
        tipFn('Rescan lua\\Turbo\\rulepacks for .ini rule packs.')
    else
        mutedWrap(previewLabel)
    end
    tipFn('Choose a cached rule pack. Use Refresh packs after adding files.')
    if selectedInfo and selectedInfo.description and selectedInfo.description ~= '' then
        mutedWrap(selectedInfo.description)
    end

    ImGui.PushTextWrapPos(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail())
    ImGui.TextColored(0.74, 0.82, 0.95, 1.0,
        'Add pack merges the whole list into your Target INI. Or use Search & Filter below to pick individual items.')
    ImGui.PopTextWrapPos()

    local canApplyPack = packTargetPath and selectedPack and selectedPack ~= ''
    if not canApplyPack then ImGui.BeginDisabled() end
    local rpAvail = ImGui.GetContentRegionAvail()
    local rpBtnW = math.max(180, math.floor(rpAvail * 0.50))
    local rpLeft = math.max(0, math.floor((rpAvail - rpBtnW) / 2))
    if rpLeft > 0 then ImGui.SetCursorPosX(ImGui.GetCursorPosX() + rpLeft) end
    if Ui.buttonVariant(Ui.fitLabel('3 Add entire rule pack to INI##rulepack_apply', 'Add pack', rpBtnW), 'successButton', rpBtnW, actionBtnH) then
        local backupPath, backupErr = TG.backupFileBesideOriginal(packTargetPath, packTargetProfile)
        if not backupPath then
            g.statusMessage = string.format('Rule pack not applied; backup failed: %s', tostring(backupErr or 'unknown'))
        else
            local result, err = TG.mergeRulePackIntoIni(selectedPack, packTargetPath, false)
            if result then
                if rescanFn then rescanFn() end
                g.statusMessage = string.format('Rule pack added to %s: %d added, %d existing skipped, %d invalid skipped, %d failed; backup: %s',
                    packTargetProfile, result.added, result.skipped, result.invalid or 0, result.failed, TG.fileBaseName(backupPath))
                if (result.removedAnnotations or 0) > 0 then
                    g.statusMessage = g.statusMessage .. string.format(' Removed %d old rule-pack note%s.',
                        result.removedAnnotations,
                        result.removedAnnotations == 1 and '' or 's')
                end
            else
                g.statusMessage = err or 'Rule pack merge failed.'
            end
        end
    end
    if not canApplyPack then ImGui.EndDisabled() end
    tipFn('Adds missing rules from the selected pack to the selected Target INI. Existing item rules are not overwritten.')
end

--- Color-code an ON/OFF/TRUE/FALSE/YES/NO value string for chat output.
--- Numeric and free-text values stay neutral. v3.8.52: hoisted from later
--- in the file because the snapshot builder now uses it directly.
local function chatBool(raw)
    local v = stripIniValueForDisplay(raw)
    local upper = tostring(v):upper()
    if upper == 'ON' or upper == 'TRUE' or upper == 'YES' then
        return '\ag' .. v .. '\ax'
    end
    if upper == 'OFF' or upper == 'FALSE' or upper == 'NO' then
        return '\ar' .. v .. '\ax'
    end
    if v == '—' then
        return '\at—\ax'
    end
    return '\aw' .. v .. '\ax'
end

-- v3.8.52: snapshot helpers wrapped in a do-end block so their locals
-- (SnapshotMeta, the per-path builder) don't consume slots in init.lua's
-- 200-local main-function budget. Public surface is reached via TG.
do
    local SnapshotMeta = {
        descriptions = {
            lootdistance              = 'event radius in feet',
            loothighvalueminpp        = 'auto-keep items worth >= N pp',
            lootstackableminpp        = 'auto-keep stackables worth >= N pp',
            lootnodropprompt          = 'prompt before looting NO DROP',
            lootnodroppromptreset     = 'when to reset NO-DROP prompt cache',
            corpsehidemode            = 'hide corpses after looting',
            sellunlistedstackable     = 'sell unlisted stackables automatically',
            sellunlisteditems         = 'sell ANY unlisted item',
            sellwildcards             = 'apply wildcard sell rules',
            bankwildcards             = 'apply wildcard bank rules',
            convertcoinonbank         = 'convert coin during bank/unload',
            announcedefaultto         = 'default channel: echo|e3bc|say|gsay|rsay|"t Name"',
            announceskipto            = 'skip-loot channel: say|gsay|rsay',
            announcebanksellto        = 'bank/sell announce channel',
            announcedonelootingto     = 'done-looting announce channel',
            inventorywarnslots        = 'warn when free bag slots <= N',
            returntoleader            = 'walk back to group leader after task',
            stoplootwhenattacked      = 'abort loot if aggro detected',
            droplevbeforenav          = 'drop levitate before navigating',
            finalsweep                = 'extra corpse sweep after main pass',
            reclaimdiamondcoinsafterloot = 'reclaim inventory Diamond Coins after normal loot',
            usenavforcorpses          = 'use MQ2Nav to reach corpses',
            debug                     = 'verbose tracing',
            showdebug                 = 'legacy alias for debug',
            logtofile                 = 'write task output to MQ Logs',
            loglevel                  = 'log verbosity',
            logskiplistforini         = 'journal skips for Review pane',
        },
        groups = {
            { label = 'Loot',           keys = { 'lootdistance', 'loothighvalueminpp', 'lootstackableminpp', 'lootnodropprompt', 'corpsehidemode', 'reclaimdiamondcoinsafterloot' } },
            { label = 'Sell/Bank',      keys = { 'sellunlistedstackable', 'sellunlisteditems', 'sellwildcards', 'bankwildcards', 'convertcoinonbank' } },
            { label = 'Announcements',  keys = { 'announcedefaultto', 'announceskipto', 'announcedonelootingto', 'announcebanksellto' } },
            { label = 'Movement/Safety',keys = { 'inventorywarnslots', 'returntoleader', 'stoplootwhenattacked', 'droplevbeforenav', 'finalsweep', 'usenavforcorpses' } },
            { label = 'Debug/Logs',     keys = { 'debug', 'logtofile', 'loglevel', 'logskiplistforini' } },
        },
    }

    --- Lines from active turboloot.ini [Settings] for chat output / Cfg button.
    --- v3.8.52: grouped sections + descriptions + ON/OFF coloring. Renders
    --- cleanly for /turbosnapshot, the More -> INI Snapshot menu, and is the
    --- single source of truth users hit when asking "what does this setting do?"
    local function buildLinesForPath(path)
        if not path then
            return { 'turboloot.ini path not found' }
        end

        -- Format one line: '    key = value     description'. Pad based on PLAIN
        -- length so descriptions line up — color codes are zero-width in chat.
        local function formatLine(key, rawValue)
            local desc = SnapshotMeta.descriptions[key:lower()]
            local valColored = chatBool(rawValue)
            local valPlain = stripIniValueForDisplay(rawValue)
            local padLen = math.max(1, 14 - #valPlain)
            local pad = string.rep(' ', padLen)
            if desc then
                return string.format('    \aw%s\ax = %s%s\at%s\ax', key, valColored, pad, desc)
            end
            return string.format('    \aw%s\ax = %s', key, valColored)
        end

        local fileTail = path:match('[^\\/]+$') or path
        local lines = { string.format('\at[Settings]\ax  \ay%s\ax  \aw— what each setting does\ax', fileTail) }

        local pairsList = readIniSectionPairs(path, 'Settings')
        if #pairsList == 0 then
            table.insert(lines, '  (no readable key=value lines in [Settings])')
            return lines
        end

        local byKey = {}
        for _, p in ipairs(pairsList) do
            byKey[p.key:lower()] = p
        end

        local shown = {}
        for _, group in ipairs(SnapshotMeta.groups) do
            local hasAny = false
            for _, k in ipairs(group.keys) do
                if byKey[k] then hasAny = true; break end
            end
            if hasAny then
                table.insert(lines, string.format('  \at%s\ax', group.label))
                for _, k in ipairs(group.keys) do
                    local p = byKey[k]
                    if p then
                        shown[k] = true
                        table.insert(lines, formatLine(p.key, p.value))
                    end
                end
            end
        end

        local otherShown = false
        for _, p in ipairs(pairsList) do
            if not shown[p.key:lower()] then
                if not otherShown then
                    table.insert(lines, '  \atOther\ax')
                    otherShown = true
                end
                table.insert(lines, formatLine(p.key, p.value))
            end
        end

        table.insert(lines, '  \aw(E3 LootRadius may match lootDistance after sync)\ax')
        return lines
    end

    -- Public surface: TG-attached so callers (popup, bind, doctor pointer)
    -- and the closure scope (line ~4060) can reach without a top-level local.
    TG.getTurboLootSettingsSummaryLinesForPath = buildLinesForPath
    TG.getTurboLootSettingsSummaryLines = function()
        return buildLinesForPath(getTurbolootIniPath())
    end
    TG.printTurboSnapshot = function()
        printf('\at[Turbo]\ax \ayturboloot.ini [Settings] snapshot:\ax')
        for _, ln in ipairs(TG.getTurboLootSettingsSummaryLines()) do
            printf('  %s', ln)
        end
    end
end

local function lootFeetFromIniValue(raw)
    if not raw then return nil end
    local s = raw:match('^([^;]*)') or raw
    s = (s:gsub(',', '')):gsub('^%s+', ''):gsub('%s+$', '')
    local n = tonumber(s)
    if not n then return nil end
    n = math.floor(n)
    if n < 1 or n > 2000 then return nil end
    return n
end

local function readLootDistanceFeetFromTurbolootIni()
    local iniPath = getTurbolootIniPath()
    if not iniPath then return nil end
    local d = readIniKey(iniPath, 'Settings', 'lootDistance')
    local feet = lootFeetFromIniValue(d)
    if feet then return feet end
    local legacy = readIniKey(iniPath, 'Settings', 'lootRadiusFeet')
    return lootFeetFromIniValue(legacy)
end

local function readLootDistanceFeetForProfile(profile)
    local path, exists = resolveTurbolootIniPathForProfile(profile)
    if not path or not exists then return nil end
    local d = readIniKey(path, 'Settings', 'lootDistance')
    local feet = lootFeetFromIniValue(d)
    if feet then return feet end
    return lootFeetFromIniValue(readIniKey(path, 'Settings', 'lootRadiusFeet'))
end

local function writeLootDistanceFeetForProfile(profile, feet)
    local path, exists = resolveTurbolootIniPathForProfile(profile)
    if not path or not exists then return false end
    writeIniKey(path, 'Settings', 'lootDistance', tostring(feet))
    return true
end

TG.invalidateProfileSettingsCache = function(profile)
    if type(TG.profileSettingsCache) ~= 'table' then
        TG.profileSettingsCache = {}
        return
    end
    if profile then
        local clean = cleanProfileName(profile)
        if clean and clean ~= '' then
            TG.profileSettingsCache[clean:lower()] = nil
            return
        end
    end
    TG.profileSettingsCache = {}
end

TG.readTurboLootDebugEnabledForProfile = function(profile)
    local cleanProfile = cleanProfileName(profile) or 'turboloot.ini'
    local key = cleanProfile:lower()
    TG.profileSettingsCache = TG.profileSettingsCache or {}
    local cached = TG.profileSettingsCache[key]
    if cached and cached.debug ~= nil then return cached.debug == true end

    local enabled = false
    local path, exists = resolveTurbolootIniPathForProfile(cleanProfile)
    if path and exists then
        local raw = readIniKey(path, 'Settings', 'debug')
        if raw == nil or raw == '' then
            raw = readIniKey(path, 'Settings', 'ShowDebug')
        end
        if raw ~= nil then
            local v = stripIniValueForDisplay(raw):upper():gsub('%s+', '')
            enabled = v == '1' or v == 'ON' or v == 'TRUE' or v == 'YES'
        end
    end

    TG.profileSettingsCache[key] = cached or {}
    TG.profileSettingsCache[key].debug = enabled
    TG.profileSettingsCache[key].path = path or TG.profileSettingsCache[key].path or ''
    TG.profileSettingsCache[key].at = nowMS()
    return enabled
end

TG.readTurboLootReclaimDcAfterLootForProfile = function(profile)
    local cleanProfile = cleanProfileName(profile) or 'turboloot.ini'
    local key = cleanProfile:lower()
    TG.profileSettingsCache = TG.profileSettingsCache or {}
    local cached = TG.profileSettingsCache[key]
    if cached and cached.reclaimDcAfterLoot ~= nil then return cached.reclaimDcAfterLoot == true end

    local enabled = false
    local path, exists = resolveTurbolootIniPathForProfile(cleanProfile)
    if path and exists then
        local raw = readIniKey(path, 'Settings', 'reclaimDiamondCoinsAfterLoot')
        if raw ~= nil then
            local v = stripIniValueForDisplay(raw):upper():gsub('%s+', '')
            enabled = v == '1' or v == 'ON' or v == 'TRUE' or v == 'YES'
        end
    end

    TG.profileSettingsCache[key] = cached or {}
    TG.profileSettingsCache[key].reclaimDcAfterLoot = enabled
    TG.profileSettingsCache[key].path = path or (cached and cached.path) or ''
    TG.profileSettingsCache[key].at = nowMS()
    return enabled
end

local function activeLootTargetNames(lootAllOn, multiModeOn, currentLooter)
    local names = {}
    if lootAllOn then
        for _, name in ipairs(TG.members) do
            if name and name ~= '' and name ~= 'NOBODY' then table.insert(names, name) end
        end
    elseif multiModeOn then
        for _, name in ipairs(getMultiLooters()) do
            if name and name ~= '' and name ~= 'NOBODY' then table.insert(names, name) end
        end
    elseif currentLooter and currentLooter ~= '' and currentLooter ~= 'NOBODY' then
        table.insert(names, currentLooter)
    end
    return names
end

TG.refreshLootAnimationActive = require('Turbo.loot_active').refresh

TG.getLootReadiness = function(lootAllOn, multiModeOn, currentLooter, liveMainLooter)
    if lootAllOn then
        return #TG.getViableLooterNames() > 0, (#TG.getViableLooterNames() > 0)
            and 'All group members eligible to loot.'
            or 'No group members found.'
    end
    if multiModeOn then
        local selected = getMultiLooters()
        return #selected > 0, (#selected > 0)
            and string.format('%d Multi looter%s selected.', #selected, #selected == 1 and '' or 's')
            or 'Multi mode has no selected looters.'
    end
    local live = liveMainLooter or (TG.getLiveMainLooter and TG.getLiveMainLooter()) or 'NOBODY'
    if live ~= '' and live ~= 'NOBODY' then
        return true, 'Single looter is ' .. live .. '.'
    end
    local wanted = currentLooter or TG.selectedChar or TG.savedDefaultLooter or ''
    if wanted ~= '' and wanted ~= 'NOBODY' then
        return false, 'E3 GrpMainLooter is NOBODY. Pick/resync ' .. wanted .. ' before expecting auto-loot.'
    end
    return false, 'No single looter is set.'
end

TG.getReviewJournalWatchSpecs = function()
    collectGroupMembers()
    local lootAllOn = getLootAllState()
    local multiModeOn = (not lootAllOn) and isMultiLootMode()
    local currentLooter = getCurrentLooter()
    local targets = activeLootTargetNames(lootAllOn, multiModeOn, currentLooter)
    local specs, seen = {}, {}

    local function addSpec(profile, looter)
        local cleanProfile = cleanProfileName(profile) or 'turboloot.ini'
        local iniPath = resolveTurbolootIniPathForProfile(cleanProfile)
        local journalPath = nil
        if iniPath and iniPath ~= '' then
            local dir = iniPath:match('^(.*)[/\\][^/\\]+$')
            if dir and dir ~= '' then
                journalPath = dir .. '\\TurboLoot_skips_log.txt'
            end
        end
        if not journalPath or journalPath == '' then return end
        local key = journalPath:lower()
        local spec = seen[key]
        if not spec then
            spec = {
                path = journalPath,
                profile = cleanProfile,
                iniPath = iniPath or '',
                looters = {},
            }
            seen[key] = spec
            specs[#specs + 1] = spec
        end
        if looter and looter ~= '' and looter ~= 'NOBODY' then
            local exists = false
            for _, name in ipairs(spec.looters) do
                if name == looter then
                    exists = true
                    break
                end
            end
            if not exists then
                spec.looters[#spec.looters + 1] = looter
            end
        end
    end

    if #targets > 0 then
        for _, name in ipairs(targets) do
            addSpec(getProfileForMember(name), name)
        end
    else
        addSpec(getActiveProfile(), mq.TLO.Me.Name() or '')
    end

    return specs
end

TG.setTurboLootDebugEnabledForProfile = function(profile, enabled, lootAllOn, multiModeOn, currentLooter)
    local path, exists = resolveTurbolootIniPathForProfile(profile)
    if not path or not exists then
        TG.statusMessage = string.format('Cannot find %s to update debug', tostring(profile or 'turboloot.ini'))
        return false
    end

    local val = enabled and 'ON' or 'OFF'
    if not writeIniKey(path, 'Settings', 'debug', val) then
        TG.statusMessage = string.format('Failed to write debug=%s in %s', val, profile)
        return false
    end
    writeIniKey(path, 'Settings', 'ShowDebug', val)
    TG.profileSettingsCache = TG.profileSettingsCache or {}
    TG.profileSettingsCache[(cleanProfileName(profile) or 'turboloot.ini'):lower()] = {
        debug = enabled == true,
        path = path,
        at = nowMS(),
    }

    local myName = mq.TLO.Me.Name() or ''
    local touched = 0
    local seen = {}
    for _, name in ipairs(activeLootTargetNames(lootAllOn, multiModeOn, currentLooter)) do
        local key = tostring(name):lower()
        local memberProfile = cleanProfileName(getProfileForMember(name)) or 'turboloot.ini'
        if not seen[key] and memberProfile:lower() == cleanProfileName(profile):lower() then
            seen[key] = true
            if myName ~= '' and name == myName then
                mq.cmdf('/if (${Macro.Name.Equal[turboLoot]}) /varset showDebug %d', enabled and 1 or 0)
            else
                mq.cmdf('/squelch /e3bct %s /if (${Macro.Name.Equal[turboLoot]}) /varset showDebug %d', name, enabled and 1 or 0)
            end
            touched = touched + 1
        end
    end

    TG.statusMessage = string.format('TurboLoot debug %s for %s%s',
        enabled and 'ON' or 'OFF',
        cleanProfileName(profile) or 'turboloot.ini',
        touched > 0 and string.format(' (%d active looter%s updated now)', touched, touched == 1 and '' or 's') or ' (applies next run)')
    return true
end

TG.setTurboLootReclaimDcAfterLootForProfile = function(profile, enabled)
    local cleanProfile = cleanProfileName(profile) or 'turboloot.ini'
    local path, exists = resolveTurbolootIniPathForProfile(cleanProfile)
    if not path or not exists then
        TG.statusMessage = string.format('Cannot find %s to update Diamond Coin reclaim', tostring(cleanProfile))
        return false
    end

    local val = enabled and 'ON' or 'OFF'
    if not writeIniKey(path, 'Settings', 'reclaimDiamondCoinsAfterLoot', val) then
        TG.statusMessage = string.format('Failed to write reclaimDiamondCoinsAfterLoot=%s in %s', val, cleanProfile)
        return false
    end

    TG.profileSettingsCache = TG.profileSettingsCache or {}
    local key = cleanProfile:lower()
    TG.profileSettingsCache[key] = TG.profileSettingsCache[key] or {}
    TG.profileSettingsCache[key].reclaimDcAfterLoot = enabled == true
    TG.profileSettingsCache[key].path = path
    TG.profileSettingsCache[key].at = nowMS()
    TG.statusMessage = string.format('Auto reclaim Diamond Coins after loot: %s for %s',
        enabled and 'ON' or 'OFF', cleanProfile)
    return true
end

TG.stopActiveLootMacros = function(lootAllOn, multiModeOn, currentLooter)
    collectGroupMembers()
    local myName = mq.TLO.Me.Name() or ''
    local seen = {}
    local stopped = 0
    for _, name in ipairs(activeLootTargetNames(lootAllOn, multiModeOn, currentLooter)) do
        local key = tostring(name):lower()
        if name ~= '' and name ~= 'NOBODY' and not seen[key] then
            seen[key] = true
            if myName ~= '' and name == myName then
                mq.cmd('/squelch /e3varset TurboLootActive OFF')
                mq.cmd('/squelch /e3varset TurboLootActiveAt 0')
                mq.cmd('/endmacro')
            else
                mq.cmdf('/squelch /e3bct %s /e3varset TurboLootActive OFF', name)
                mq.cmdf('/squelch /e3bct %s /e3varset TurboLootActiveAt 0', name)
                mq.cmdf('/squelch /e3bct %s /endmacro', name)
            end
            stopped = stopped + 1
        end
    end
    return stopped
end

TG.setTurboEnabled = function(value, currentLooter, lootAllOn, multiModeOn)
    if value then
        if not lootAllOn and not multiModeOn then
            local live = (TG.getLiveMainLooter and TG.getLiveMainLooter()) or 'NOBODY'
            if live == '' or live == 'NOBODY' then
                local desired = currentLooter
                if not desired or desired == '' or desired == 'NOBODY' then
                    desired = TG.selectedChar or TG.savedDefaultLooter or TG.members[1] or mq.TLO.Me.Name() or ''
                end
                if desired and desired ~= '' and desired ~= 'NOBODY' then
                    setSingleLooterMode(desired)
                    currentLooter = desired
                else
                    cycleToNext()
                    currentLooter = getCurrentLooter()
                end
            end
        end
        setTurboState(true)
        TG.statusMessage = (currentLooter and currentLooter ~= '' and currentLooter ~= 'NOBODY' and not lootAllOn and not multiModeOn)
            and string.format('Turbo: ON (%s)', currentLooter)
            or 'Turbo: ON'
    else
        local stopped = TG.stopActiveLootMacros(lootAllOn, multiModeOn, currentLooter)
        setTurboCache(false)
        setTurboState(false)
        TG.statusMessage = (stopped > 0)
            and string.format('Turbo: OFF. Sent /endmacro to %d active looter(s).', stopped)
            or 'Turbo: OFF'
    end
    saveSettings()
end

local function countDistinctProfilesForNames(names, getProfileForMember)
    local seen = {}
    local count = 0
    local firstProfile = nil
    for _, name in ipairs(names or {}) do
        local profile = cleanProfileName((getProfileForMember and getProfileForMember(name)) or 'turboloot.ini')
        if not profile or profile == '' then profile = 'turboloot.ini' end
        local key = profile:lower()
        if not seen[key] then
            seen[key] = true
            count = count + 1
            if not firstProfile then firstProfile = profile end
        end
    end
    return count, firstProfile or 'turboloot.ini'
end

syncEventLootRadiusFromActiveProfiles = function(lootAllOn, multiModeOn, currentLooter)
    if not TG.clientInGame() then
        return tonumber(TG.lootRadius) or DEFAULT_LOOT_RADIUS, false
    end
    local maxFeet = nil
    if TG.perCharProfile then
        for _, name in ipairs(activeLootTargetNames(lootAllOn, multiModeOn, currentLooter)) do
            local feet = readLootDistanceFeetForProfile(getProfileForMember(name))
            if feet and (not maxFeet or feet > maxFeet) then maxFeet = feet end
        end

    else
        maxFeet = readLootDistanceFeetForProfile(getActiveProfile())
    end
    if not maxFeet then return tonumber(TG.lootRadius) or DEFAULT_LOOT_RADIUS, false end
    maxFeet = math.max(10, math.min(500, math.floor(maxFeet)))
    local cur = tonumber(mq.TLO.MQ2Mono.Query('e3,LootRadius')()) or 0
    if cur ~= maxFeet then
        setRouteVar('LootRadius', tostring(maxFeet))
    end
    TG.lootRadius = tostring(maxFeet)
    TG.lootRadiusBuf = TG.lootRadius
    return maxFeet, true
end

local function setProfileLootDistance(profile, value)
    profile = cleanProfileName(profile)
    local num = tonumber(value)
    if not profile or profile == '' or not num then return false end
    num = math.max(10, math.min(500, math.floor(num)))
    if not writeLootDistanceFeetForProfile(profile, num) then
        TG.statusMessage = string.format('Could not write lootDistance to %s', profile)
        return false
    end
    invalidateEventRadiusCache()
    local eventFeet = syncEventLootRadiusFromActiveProfiles(getLootAllState(), isMultiLootMode(), getCurrentLooter())
    -- 3.8.29: user clicked ± — persist the resulting event radius so startup honors it.
    TG.savedLootRadius = tostring(eventFeet or num)
    TG.statusMessage = string.format('%s lootDistance=%d ft. Event radius=%d ft.',
        profile, num, eventFeet or num)
    saveSettings()
    return true
end

local function turbolootIniFileExists(filename)
    if not filename or filename == '' then return false end
    local mqPath = mq.TLO.MacroQuest.Path() or ''
    if mqPath == '' then return false end
    for _, p in ipairs({
        mqPath .. '\\Config\\' .. filename,
        mqPath .. '\\Macros\\' .. filename,
    }) do
        local f = io.open(p, 'r')
        if f then f:close() return true end
    end
    return false
end

--- Apply passive startup preferences from turbo_settings.lua (after E3 missing-var fill).
--- Do not restore/broadcast live route toggles here. Multiple Turbo Lua instances can have
--- different per-character saved defaults; making each startup authoritative lets them fight
--- over shared E3 vars. Explicit user actions still broadcast through setTurboState,
--- setCombatState, toggleLootAll, setSingleLooterMode, and setup.
local function restoreSavedLootPrefs()
    local any = (type(TG.savedTurboLootIni) == 'string' and TG.savedTurboLootIni ~= '' and not TG.perCharProfile)
    if not any then return end

    if type(TG.savedTurboLootIni) == 'string' and TG.savedTurboLootIni ~= '' and not TG.perCharProfile then
        if turbolootIniFileExists(TG.savedTurboLootIni) then
            TG.setTurboLootIniVar(TG.savedTurboLootIni)
            TG.cachedProfile = TG.savedTurboLootIni
        end
    end
end

TG.restoreSavedLiveToggles = function()
    -- Only the shared-control owner restores saved live toggles. Browse boxes mirror live E3 vars.
    local controlOwner = (TG.isSharedControlOwner and TG.isSharedControlOwner()) or false
    if TG.savedTurboOn ~= nil then
        local desiredTurbo = TG.savedTurboOn == true
        local liveTurbo = TG.e3Bool(mq.TLO.MQ2Mono.Query('e3,Turbo')())
        if not controlOwner then
            TG.savedTurboOn = liveTurbo
            TG.turboUiAuthoritative = false
            setTurboCache(liveTurbo)
        elseif liveTurbo ~= desiredTurbo then
            setRouteVar('Turbo', desiredTurbo and 'true' or 'false')
        end
        if controlOwner and desiredTurbo and not TG.savedLootAllOn and not TG.multiLootMode then
            local liveLooter = (TG.getLiveMainLooter and TG.getLiveMainLooter()) or 'NOBODY'
            local savedLooter = tostring(TG.savedDefaultLooter or ''):match('^%s*(.-)%s*$') or ''
            if (liveLooter == '' or liveLooter == 'NOBODY')
                and savedLooter ~= '' and savedLooter ~= 'NOBODY' and savedLooter ~= 'NULL' then
                TG.selectedChar = savedLooter
                setRouteVar('GrpLootMode', 'single')
                setRouteVar('GrpLootAll', 'false')
                setRouteVar('GrpMainLooter', savedLooter)
            end
        end
        if controlOwner then
            TG.turboUiAuthoritative = true
            TG.nextTurboReconcileMS = nowMS() + 5000
            setTurboCache(desiredTurbo)
        end
    end
    if TG.savedCombatLootOn ~= nil then
        local desiredCombat = TG.savedCombatLootOn == true
        local liveCombat = TG.e3Bool(mq.TLO.MQ2Mono.Query('e3,CombatLoot')())
        if not controlOwner then
            TG.savedCombatLootOn = liveCombat
            setCombatCache(liveCombat)
        elseif liveCombat ~= desiredCombat then
            setRouteVar('CombatLoot', desiredCombat and 'true' or 'false')
            setCombatCache(desiredCombat)
        else
            setCombatCache(desiredCombat)
        end
    end
end

local function ensureE3Vars()
    if not TG.clientInGame() then
        TG.statusMessage = 'Paused at character select; E3 setup is disabled.'
        return
    end
    if TG.startupInitDone then return end
    TG.startupInitDone = true

    local checks = {
        { key = 'LootRadius',     default = TG.lootRadius },
        { key = 'Turbo',          default = 'false' },
        { key = 'CombatLoot',     default = 'false' },
        { key = 'GrpLootMode',    default = 'single' },
        { key = 'GrpLootAll',     default = 'false' },
        { key = 'GrpMainLooter',  default = 'NOBODY' },
    }
    for i = 1, MAX_MULTI_LOOTERS do
        table.insert(checks, { key = 'GrpLoot' .. i, default = 'NOBODY' })
    end
    for _, c in ipairs(checks) do
        local val = mq.TLO.MQ2Mono.Query('e3,' .. c.key)()
        if not val or val == '' or val == 'NULL' then
            mq.cmdf('/e3varset %s %s', c.key, c.default)
        end
    end

    -- Restore passive startup preferences before reading turboloot.ini lootDistance.
    restoreSavedLootPrefs()
    TG.restoreSavedLiveToggles()

    -- Prefer turboloot.ini over stale E3 when both exist (one place to edit the file).
    -- 3.8.29: user-saved per-char radius WINS over turboloot.ini.lootDistance. Previously
    -- this block stomped the saved value on every startup, reverting to 50 each reload.
    local iniFeet = readLootDistanceFeetFromTurbolootIni()
    if TG.savedLootRadius then
        local savedNum = tonumber(TG.savedLootRadius)
        if savedNum and savedNum >= 10 and savedNum <= 500 then
            TG.lootRadius = tostring(savedNum)
            TG.lootRadiusBuf = TG.lootRadius
            setRouteVar('LootRadius', tostring(savedNum))
        elseif iniFeet then
            TG.lootRadius = tostring(iniFeet)
            TG.lootRadiusBuf = TG.lootRadius
            setRouteVar('LootRadius', tostring(iniFeet))
        end
    elseif iniFeet then
        TG.lootRadius = tostring(iniFeet)
        TG.lootRadiusBuf = TG.lootRadius
        setRouteVar('LootRadius', tostring(iniFeet))
    end

    local radVal = mq.TLO.MQ2Mono.Query('e3,LootRadius')()
    if radVal and radVal ~= '' and radVal ~= 'NULL' then
        -- 3.8.29: only let E3 override if the user did NOT save a per-char choice.
        if not TG.savedLootRadius then
            TG.lootRadius = tostring(tonumber(radVal) or DEFAULT_LOOT_RADIUS)
            TG.lootRadiusBuf = TG.lootRadius
        end
    end

    if TG.maybeAutoShowQuickStart then TG.maybeAutoShowQuickStart() end
end

local function setLootRadius(value, scope)
    local num = tonumber(value)
    if not num or num < 10 or num > 500 then return false end
    num = math.floor(num)
    TG.lootRadius = tostring(num)
    TG.lootRadiusBuf = TG.lootRadius
    -- 3.8.29: persist user choice so startup honors it (bug: radius reverting to 50 each reload).
    TG.savedLootRadius = TG.lootRadius
    local written = 0
    if TG.perCharProfile then
        local targets = {}
        if scope == 'active' then
            targets = activeLootTargetNames(getLootAllState(), isMultiLootMode(), getCurrentLooter())
        else
            local target = TG.selectedChar
                or ((getCurrentLooter() ~= 'NOBODY') and getCurrentLooter())
                or (mq.TLO.Me.Name() or '')
            if target and target ~= '' and target ~= 'NOBODY' then table.insert(targets, target) end
        end
        local seenProfiles = {}
        for _, name in ipairs(targets) do
            local profile = getProfileForMember(name)
            if profile and not seenProfiles[profile:lower()] then
                if writeLootDistanceFeetForProfile(profile, num) then
                    written = written + 1
                    seenProfiles[profile:lower()] = true
                end
            end
        end
    else
        if writeLootDistanceFeetForProfile(getActiveProfile(), num) then
            written = 1
        end
    end
    invalidateEventRadiusCache()
    local eventFeet = syncEventLootRadiusFromActiveProfiles(getLootAllState(), isMultiLootMode(), getCurrentLooter())
    if not eventFeet then
        setRouteVar('LootRadius', tostring(num))
        eventFeet = num
    end
    TG.statusMessage = string.format('Loot distance: %d ft (%d INI%s); event radius: %d ft',
        num, written, written == 1 and '' or 's', eventFeet)
    saveSettings()
    return true
end

local function applyTurboKeyRule(rule, opts)
    if TG.requireSharedControl and not TG.requireSharedControl('TurboKey rule edit') then return end
    opts = opts or {}
    local itemName = opts.itemName
    if not itemName or itemName == '' or itemName == 'NULL' then
        itemName = mq.TLO.Cursor.Name()
    end
    if not itemName or itemName == '' or itemName == 'NULL' then
        TG.statusMessage = 'Nothing on cursor.'
        return
    end

    local iniPath = getTurbolootIniPath()
    if not iniPath then
        TG.statusMessage = 'Cannot find turboloot.ini'
        return
    end

    local oldVal = readIniKey(iniPath, 'ItemLimits', itemName)
    local ok = writeIniKey(iniPath, 'ItemLimits', itemName, rule)

    if not ok then
        TG.statusMessage = 'Failed to write to turboloot.ini'
        return
    end

    TG.lastCursorRuleUndo = {
        itemName = itemName,
        rule = rule,
        oldVal = oldVal,
        iniPath = iniPath,
    }

    if oldVal then
        TG.statusMessage = string.format('%s = %s (was %s)', itemName, rule, oldVal)
        mq.cmdf('/echo \\atUpdated \\ag%s\\at in \\ag[ItemLimits]\\at: \\ay%s\\at -> \\ag%s\\at.', itemName, oldVal, rule)
    else
        TG.statusMessage = string.format('%s = %s', itemName, rule)
        mq.cmdf('/echo \\atAdded \\ag%s\\at to \\ag[ItemLimits]\\at as \\ag%s\\at.', itemName, rule)
    end

    local destroyCursor = opts.destroyCursor
    if destroyCursor == nil then
        destroyCursor = DESTROY_RULES[rule:upper()] == true
    end

    if destroyCursor then
        mq.cmd('/destroy')
        TG.statusMessage = TG.statusMessage .. ' [destroyed]'
    else
        mq.cmd('/autoinv')
    end
end

local function undoCursorRule()
    if TG.requireSharedControl and not TG.requireSharedControl('TurboKey undo') then return false end
    local undo = TG.lastCursorRuleUndo
    if type(undo) ~= 'table' then
        TG.statusMessage = 'Nothing to undo'
        return false
    end

    local itemName = undo.itemName
    local iniPath = undo.iniPath
    if not itemName or itemName == '' or not iniPath or iniPath == '' then
        TG.statusMessage = 'Cursor undo data is incomplete'
        TG.lastCursorRuleUndo = nil
        return false
    end

    local ok
    if undo.oldVal ~= nil then
        ok = writeIniKey(iniPath, 'ItemLimits', itemName, undo.oldVal)
    else
        ok = deleteIniKey(iniPath, 'ItemLimits', itemName)
    end

    if ok then
        TG.lastCursorRuleUndo = nil
        if undo.oldVal ~= nil then
            TG.statusMessage = string.format('Undo cursor: restored %s = %s', itemName, undo.oldVal)
        else
            TG.statusMessage = string.format('Undo cursor: removed %s = %s', itemName, undo.rule or 'rule')
        end
        return true
    end

    TG.statusMessage = string.format('Failed to undo cursor rule for %s', itemName)
    return false
end

-- =========================================================
-- Setup: write auto-loot config to E3 INI using Lua file I/O
-- (bypasses MQ2 /ini command which fails with spaces in paths)
-- =========================================================

-- E3 event lines must read LootRadius via MQ2Mono — bare ${LootRadius} often does NOT expand
-- when E3 fires the event (only some vars like ${Turbo} are substituted). Hardcoded 50 works
-- for the same reason. See Turbo.mac (uses ${MQ2Mono.Query[e3,...]} for E3 state).
local LOOT_RADIUS_QUERY = '${MQ2Mono.Query[e3,LootRadius]}'
local LOOT_MODE_QUERY = 'MQ2Mono.Query[e3,GrpLootMode]'
local SETUP_ENTRIES = {
    { section = 'EventRegMatches', key = 'Tloot', value = 'slain' },
    { section = 'EventRegMatches', key = 'TlootAll', value = 'slain' },
    { section = 'Events', key = 'Tloot',
      value = '/timed 10 /if (${' .. LOOT_MODE_QUERY .. '.Equal[single]} && ${MQ2Mono.Query[e3,GrpMainLooter].NotEqual[NOBODY]} && (${Bool[${MQ2Mono.Query[e3,CombatLoot]}]} || !${Spawn[npc radius ' .. LOOT_RADIUS_QUERY .. '].Aggressive}) && ${Bool[${MQ2Mono.Query[e3,Turbo]}]} && ${SpawnCount[npccorpse radius ' .. LOOT_RADIUS_QUERY .. ']}) /squelch /e3bct ${MQ2Mono.Query[e3,GrpMainLooter]} /mac TurboLoot' },
    { section = 'Events', key = 'TlootAll',
      value = '/timed 11 /if (${' .. LOOT_MODE_QUERY .. '.Equal[all]} && (${Bool[${MQ2Mono.Query[e3,CombatLoot]}]} || !${Spawn[npc radius ' .. LOOT_RADIUS_QUERY .. '].Aggressive}) && ${Bool[${MQ2Mono.Query[e3,Turbo]}]} && ${SpawnCount[npccorpse radius ' .. LOOT_RADIUS_QUERY .. ']}) /squelch /e3bcaa /mac TurboLoot' },
    { section = 'E3BotsPublishData (key/value)', key = 'GrpMainLooterName', value = '${GrpMainLooter}' },
    { section = 'Startup Commands', key = 'Turbo_InitLootMode', value = '/e3varset GrpLootMode single' },
    { section = 'Startup Commands', key = 'Turbo_InitLooter', value = '/e3varset GrpMainLooter NOBODY' },
    { section = 'Startup Commands', key = 'Turbo_InitTurbo', value = '/e3varset Turbo false' },
    { section = 'Startup Commands', key = 'Turbo_InitCombat', value = '/e3varset CombatLoot false' },
    { section = 'Startup Commands', key = 'Turbo_InitLootAll', value = '/e3varset GrpLootAll false' },
    { section = 'Startup Commands', key = 'Turbo_InitLootRadius', value = '/e3varset LootRadius 50' },
}

for i = 1, MAX_MULTI_LOOTERS do
    table.insert(SETUP_ENTRIES, { section = 'EventRegMatches', key = 'TlootM' .. i, value = 'slain' })
    table.insert(SETUP_ENTRIES, {
        section = 'Events',
        key = 'TlootM' .. i,
        value = string.format('/timed %d /if (${%s.Equal[multi]} && ${MQ2Mono.Query[e3,GrpLoot%d].NotEqual[NOBODY]} && (${Bool[${MQ2Mono.Query[e3,CombatLoot]}]} || !${Spawn[npc radius %s].Aggressive}) && ${Bool[${MQ2Mono.Query[e3,Turbo]}]} && ${SpawnCount[npccorpse radius %s]}) /squelch /e3bct ${MQ2Mono.Query[e3,GrpLoot%d]} /mac TurboLoot',
            10 + ((i - 1) * MULTI_LOOT_STAGGER_DS), LOOT_MODE_QUERY, i, LOOT_RADIUS_QUERY, LOOT_RADIUS_QUERY, i)
    })
    table.insert(SETUP_ENTRIES, {
        section = 'Startup Commands',
        key = 'Turbo_InitLoot' .. i,
        value = '/e3varset GrpLoot' .. i .. ' NOBODY'
    })
end

--- Deferred /e3reload after CLI `setup reload` (~8s — MQ /timed uses deciseconds).
local SETUP_AUTORELOAD_DS = 80
--- After driver `Turbo setup`, delay (deciseconds) before /e3bct sends quiet `Turbo setup hooksonly` to each other group member.
local SETUP_GROUP_PROPAGATE_DS = 30

TG.noteQuickStartAuto = function(reason)
    TG.quickStartAutoReason = tostring(reason or '')
    TG.quickStartAutoLastCheck = os.time()
end

TG.sendRemoteSetupLocal = function(name, delayDs)
    name = tostring(name or ''):match('^%s*(.-)%s*$') or ''
    if name == '' then return false end
    delayDs = tonumber(delayDs) or 0
    if delayDs > 0 then
        mq.cmdf('/squelch /e3bct %s /timed %d /lua run Turbo setup hooksonly', name, math.floor(delayDs))
    else
        mq.cmdf('/squelch /e3bct %s /lua run Turbo setup hooksonly', name)
    end
    return true
end

TG.describeLogSkipListSetting = function(iniPath)
    if not iniPath or iniPath == '' then
        return false, 'unknown'
    end
    local raw = readIniKey(iniPath, 'Settings', 'logSkipListForIni')
    if raw == nil then
        return true, 'ON (default)'
    end
    local shown = stripIniValueForDisplay(raw)
    local upper = shown:upper():gsub('%s+', '')
    if upper == '' then
        return true, 'ON (default)'
    end
    if upper == '0' or upper == 'OFF' or upper == 'FALSE' or upper == 'NO' then
        return false, shown
    end
    return true, shown
end

local function fileExists(path)
    local f = io.open(path, 'r')
    if f then f:close() return true end
    return false
end

TG.maybeAutoShowQuickStart = function()
    if TG.quickStartDismissed then TG.noteQuickStartAuto('blocked: dismissed in settings') return end
    local configDir = mq.configDir or getConfigDir()
    local dismissPaths = {
        TG.paths.state_file('turbo_quickstart_dismiss.lua'),
        configDir and (configDir:gsub('/', '\\') .. '\\turbo_quickstart_dismiss.lua') or nil,
    }
    for _, dismissPath in pairs(dismissPaths) do
        if dismissPath and fileExists(dismissPath) then TG.noteQuickStartAuto('blocked: dismiss file exists') return end
    end
    if TG.quickStartAutoShown then TG.noteQuickStartAuto('blocked: already checked this session') return end
    if TG.luaScriptRunningAny({ 'Turbo/onboarding', 'onboarding', 'Turbo_Quick_Start' }) then
        TG.noteQuickStartAuto('blocked: Quick Start already running')
        return
    end

    local need = TG.quickStartSeen ~= true
    local reasons = {}
    if need then reasons[#reasons + 1] = 'first run' end
    local mqPath = mq.TLO.MacroQuest.Path() or ''
    if mqPath ~= '' then
        local hasIni = false
        for _, sub in ipairs({ 'Config', 'Macros' }) do
            local p = mqPath .. '\\' .. sub .. '\\turboloot.ini'
            if fileExists(p) then hasIni = true break end
        end
        if not hasIni then
            need = true
            reasons[#reasons + 1] = 'missing turboloot.ini'
        end
    end
    if TG.getE3SetupStatus then
        local st = TG.getE3SetupStatus()
        if st and not st.ok then
            need = true
            local issue = st.issues and st.issues[1] or nil
            reasons[#reasons + 1] = issue and ('E3 setup: ' .. tostring(issue)) or 'E3 setup incomplete'
        end
    end

    TG.quickStartAutoShown = true
    if need then
        TG.noteQuickStartAuto('opening: ' .. table.concat(reasons, '; '))
        TG.quickStartSeen = true
        TG.quickStartDismissed = false
        saveSettings()
        mq.cmd('/timed 50 /lua run Turbo/onboarding')
    else
        TG.noteQuickStartAuto('not needed: config/setup ok')
    end
end

TG.dismissQuickStartAutoShow = function()
    TG.quickStartDismissed = true
    TG.quickStartSeen = true
    saveSettings()
    local path = TG.paths.state_file('turbo_quickstart_dismiss.lua')
    local f = path and io.open(path, 'w') or nil
    if f then f:write('return true\n') f:close() end
end

local function readTurboVersionFromFile(path)
    local f = io.open(path, 'r')
    if not f then return nil end

    local fallback = nil
    local lineCount = 0
    for line in f:lines() do
        lineCount = lineCount + 1
        local marker = line:match('@version.-([%d][%w%.%-_]*)%s*$')
        if marker then
            f:close()
            return marker
        end

        fallback = fallback
            or line:match('TurboLoot%s+([%w%.%-_]+)%s+%-')
            or line:match('Turbo%s+Auto%-Loot%s+v([%w%.%-_]+)')
            or line:match('Turbo%s+v([%w%.%-_]+)')
            or line:match('TurboGive%.mac%s+v([%w%.%-_]+)')
            or line:match('TurboKey%s+v([%w%.%-_]+)')
            or line:match('^%s*turboSuiteVersion%s*=%s*([%w%.%-_]+)')

        if lineCount >= 80 then break end
    end

    f:close()
    return fallback
end

local function versionText(path)
    local version = readTurboVersionFromFile(path)
    return version and ('v' .. version) or 'v?'
end

local function relativeMqPath(path, mqPath)
    if not path or path == '' then return '' end
    if not mqPath or mqPath == '' then return path end
    local prefix = mqPath .. '\\'
    if path:sub(1, #prefix):lower() == prefix:lower() then
        return path:sub(#prefix + 1)
    end
    return path
end

local ShellOpen = require('Turbo.shell_open')

TG.ShellOpen = ShellOpen
TG.shellExecuteOpen = ShellOpen.shellOpenExternal
TG.isSafeHttpBaseUrl = ShellOpen.isSafeHttpBaseUrl
TG.isSafeHttpUrl = ShellOpen.isSafeHttpUrl

local function shellOpenFile(path)
    return ShellOpen.shellOpenFile(path)
end

local function shellOpenFolder(dir)
    return ShellOpen.shellOpenFolder(dir)
end

local function shellOpenUrl(url)
    return ShellOpen.shellOpenUrl(url)
end

TG.openHuntingRuntimeFile = function()
    if TG.writeHuntingRuntimeState then TG.writeHuntingRuntimeState() end
    local p = TG.getHuntingRuntimePath and TG.getHuntingRuntimePath() or nil
    if not p or p == '' then
        TG.statusMessage = 'Cannot resolve Hunting INI path.'
        return
    end
    shellOpenFile(p)
    TG.statusMessage = 'Opened Hunting INI: ' .. p
end

TG.openAllaUrl = function(kind, id)
    id = tonumber(id)
    if not id or id <= 0 then
        TG.statusMessage = 'No valid ' .. tostring(kind or 'Alla') .. ' ID available.'
        return false
    end
    local base = (kind == 'npc') and TG.allaNpcUrlBase or TG.allaItemUrlBase
    base = tostring(base or '')
    if not ShellOpen.isSafeHttpUrl(base) then
        TG.statusMessage = 'Set a valid http(s) Alla URL base in More > Links.'
        return false
    end
    if ShellOpen.openAllaPage(base, id) then
        TG.statusMessage = string.format('Opened Alla %s page: %d', kind == 'npc' and 'NPC' or 'item', math.floor(id))
        return true
    end
    TG.statusMessage = 'Could not open Alla page.'
    return false
end

TG.openAllaItemPage = function(itemId)
    return TG.openAllaUrl('item', itemId)
end

TG.openAllaNpcPage = function(npcId)
    return TG.openAllaUrl('npc', npcId)
end

local function openTurbolootIniFileExternal()
    local p = getTurbolootIniPath()
    if not p then
        TG.statusMessage = 'Cannot find active turboloot*.ini path.'
        return
    end
    if not fileExists(p) then
        TG.statusMessage = 'INI not on disk yet: ' .. p .. ' — pick/create profile first.'
        return
    end
    shellOpenFile(p)
    TG.statusMessage = 'Opened INI in default app: ' .. p
end

TG.getActiveSkipJournalPath = function()
    local iniPath = getTurbolootIniPath()
    if not iniPath or iniPath == '' then return nil end
    local dir = iniPath:match('^(.*)[/\\][^/\\]+$')
    if not dir or dir == '' then return nil end
    return dir .. '\\TurboLoot_skips_log.txt'
end

TG.openSkipJournalExternal = function()
    local p = TG.getActiveSkipJournalPath()
    if not p then
        TG.statusMessage = 'Cannot resolve skip journal path from the active turboloot INI.'
        return
    end
    if not fileExists(p) then
        TG.statusMessage = 'Skip journal not on disk yet. It appears after the first skipped item is logged.'
        return
    end
    shellOpenFile(p)
    TG.statusMessage = 'Opened skip journal: ' .. p
end

local function openProfileExternal(profile)
    local p, exists = resolveTurbolootIniPathForProfile(profile)
    if not p or p == '' or not exists then
        TG.statusMessage = 'INI not found: ' .. tostring(profile or '')
        return
    end
    shellOpenFile(p)
    TG.statusMessage = 'Opened INI in default app: ' .. p
end

local function openProfileFolderExternal(profile)
    local p, exists = resolveTurbolootIniPathForProfile(profile)
    if not p or p == '' or not exists then
        TG.statusMessage = 'INI not found: ' .. tostring(profile or '')
        return
    end
    local dir = p:match('^(.*)[/\\][^/\\]+$')
    if dir and dir ~= '' then
        shellOpenFolder(dir)
        TG.statusMessage = 'Opened INI folder: ' .. dir
    end
end

local function profileContextMenu(profile, id)
    profile = cleanProfileName(profile)
    if not profile or profile == '' then return end
    if ImGui.BeginPopupContextItem(id) then
        ImGui.TextColored(0.65, 0.58, 0.78, 1.0, profile)
        ImGui.Separator()
        if ImGui.Selectable('Open INI in editor##openini') then
            openProfileExternal(profile)
            ImGui.CloseCurrentPopup()
        end
        if ImGui.Selectable('Open INI folder##openinifolder') then
            openProfileFolderExternal(profile)
            ImGui.CloseCurrentPopup()
        end
        if ImGui.Selectable('Clone to new profile##cloneini') then
            TG.iniCloneSource = profile
            TG.iniToolMode = 'clone'
            TG.iniToolBuf = profile:gsub('%.ini$', '') .. '_copy.ini'
            ImGui.CloseCurrentPopup()
        end
        if ImGui.Selectable('Export profile##exportini') then
            local path, err = TG.exportProfile(profile)
            if path then
                TG.statusMessage = 'Exported: ' .. path
                if TG.openTurboExportsFolderExternal then TG.openTurboExportsFolderExternal() end
            else
                TG.statusMessage = 'Export failed: ' .. tostring(err or '')
            end
            ImGui.CloseCurrentPopup()
        end
        ImGui.EndPopup()
    end
end

local function openMacroQuestSubfolderExternal(subfolder)
    local mqPath = mq.TLO.MacroQuest.Path() or ''
    if mqPath == '' then
        TG.statusMessage = 'MacroQuest path unknown.'
        return
    end
    local dir = mqPath .. '\\' .. subfolder
    shellOpenFolder(dir)
    TG.statusMessage = 'Opened ' .. subfolder .. ' folder: ' .. dir
end

local function openTurbolootConfigFolderExternal()
    openMacroQuestSubfolderExternal('Config')
end

local function openTurbolootMacrosFolderExternal()
    openMacroQuestSubfolderExternal('Macros')
end

TG.openTurboMobsExportsFolderExternal = function()
    local configDir = mq.configDir or ''
    if configDir == '' then
        TG.statusMessage = 'MacroQuest config path unknown.'
        return
    end
    local dir = configDir:gsub('/', '\\') .. '\\TurboMobs\\exports'
    shellOpenFolder(dir)
    TG.statusMessage = 'Opened TurboMobs exports folder: ' .. dir
end

TG.openTurboExportsFolderExternal = function()
    local exportDir = TG.turboSupportDir('exports')
    if not exportDir then
        TG.statusMessage = 'Could not open Turbo exports folder.'
        return
    end
    shellOpenFolder(exportDir)
    TG.statusMessage = 'Opened Turbo exports folder: ' .. exportDir
end

local function openTurboRepoWeb()
    if ShellOpen.shellOpenUrl(TURBO_REPO_WEB) then
        TG.statusMessage = 'Opening TurboLoot on GitHub (readme & releases).'
    else
        TG.statusMessage = 'Could not open GitHub link.'
    end
end

--- Launch the patcher exe like a double-click in Explorer (ShellExecuteA
--- 'open'): no console window, and the patcher outlives this script if it
--- stops us. Checked spots: <MQ>\, <MQ>\TurboPatcher\, <MQ>\Patcher\.
--- On TG (not a local): the main chunk is near LuaJIT's 200-local limit.
TG.openTurboPatcherExternal = function()
    local exe
    local mqPath = (mq.TLO.MacroQuest.Path() or ''):gsub('[\\/]+$', '')
    if mqPath ~= '' then
        for _, dir in ipairs({ mqPath, mqPath .. '\\TurboPatcher', mqPath .. '\\Patcher' }) do
            for _, name in ipairs({ 'TurboPatcher.exe', 'LazarusPatcher.exe' }) do
                local path = dir .. '\\' .. name
                if fileExists(path) then exe = path break end
            end
            if exe then break end
        end
    end
    if not exe then
        local url = 'https://github.com/drel-git/TurboPatcher/releases/latest'
        pcall(function()
            local okUC, UC = pcall(require, 'Turbo.update_check')
            if okUC and UC and UC.PATCHER_RELEASES_URL then url = UC.PATCHER_RELEASES_URL end
        end)
        if shellOpenUrl(url) then
            TG.statusMessage = 'TurboPatcher.exe not found — opened download page. '
                .. 'Save the exe into your MacroQuest folder (or a TurboPatcher subfolder).'
        else
            TG.statusMessage = 'TurboPatcher.exe not found. Put it in your MacroQuest folder '
                .. '(or a TurboPatcher subfolder), or open: ' .. url
        end
        return
    end
    if shellOpenFile(exe) then
        TG.statusMessage = 'Turbo Patcher launched: ' .. exe
    else
        TG.statusMessage = 'Could not launch Turbo Patcher: ' .. exe
    end
end

local function findE3Ini(manualFile, characterName)
    local mqPath = mq.TLO.MacroQuest.Path() or ''
    local charName = tostring(characterName or mq.TLO.Me.CleanName() or ''):match('^%s*(.-)%s*$') or ''
    local serverRaw = mq.TLO.EverQuest.Server() or ''

    local bases = {}
    if mqPath ~= '' then
        table.insert(bases, mqPath .. '\\Config\\e3 Bot Inis')
        table.insert(bases, mqPath .. '\\Macros\\e3 Bot Inis')
    end

    if manualFile and manualFile ~= '' then
        for _, base in ipairs(bases) do
            local p = base .. '\\' .. manualFile
            if fileExists(p) then return p end
        end
        if #bases > 0 then return bases[1] .. '\\' .. manualFile end
    end

    local serverStripped = serverRaw:gsub('^Project ', '')
    local serverUnder = serverRaw:gsub(' ', '_')
    local variants = {}
    if serverRaw ~= '' then table.insert(variants, charName .. '_' .. serverRaw) end
    if serverStripped ~= serverRaw then table.insert(variants, charName .. '_' .. serverStripped) end
    if serverUnder ~= serverRaw then table.insert(variants, charName .. '_' .. serverUnder) end
    table.insert(variants, charName)

    for _, base in ipairs(bases) do
        for _, v in ipairs(variants) do
            local p = base .. '\\' .. v .. '.ini'
            if fileExists(p) then return p end
        end
    end

    if #bases > 0 and #variants > 0 then
        return bases[1] .. '\\' .. variants[1] .. '.ini'
    end
    return nil
end

TG.normalizeStartupToolState = function()
    if type(TG.startupToolSelections) ~= 'table' then TG.startupToolSelections = {} end
    local anyTool = false
    for _, tool in ipairs(TG.startupToolChoices or {}) do
        if TG.startupToolSelections[tool.id] then anyTool = true break end
    end
    if not anyTool then TG.startupToolSelections.turbo = true end
    if type(TG.startupToolTargets) ~= 'table' then TG.startupToolTargets = {} end
end

TG.selectedStartupToolList = function()
    TG.normalizeStartupToolState()
    local out = {}
    for _, tool in ipairs(TG.startupToolChoices or {}) do
        if TG.startupToolSelections[tool.id] then out[#out + 1] = tool end
    end
    return out
end

TG.selectedStartupTargetList = function()
    TG.normalizeStartupToolState()
    local names = {}
    for name, on in pairs(TG.startupToolTargets or {}) do
        local clean = tostring(name or ''):match('^%s*(.-)%s*$') or ''
        if on and clean ~= '' then names[#names + 1] = clean end
    end
    table.sort(names, function(a, b) return a:lower() < b:lower() end)
    if #names == 0 then
        local me = mq.TLO.Me.CleanName() or mq.TLO.Me.Name() or ''
        if me ~= '' and me ~= 'NULL' then names[1] = me end
    end
    return names
end

TG.clearStartupToolEntries = function(iniPath)
    if not iniPath or iniPath == '' then return 0 end
    local ok, removed = TG.mergeStartupToolEntries(iniPath, {})
    if not ok then return 0 end
    return removed or 0
end

TG.isStartupToolCommandValue = function(value)
    local v = tostring(value or ''):match('^%s*(.-)%s*$') or ''
    if v:match('^/lua%s+run%s+Turbo/startup_tool%s+%d+%s+[%w_%-%s]+$') then return true end
    if v:match('^/timed%s+%d+%s+/lua%s+run%s+Turbo%s+mini%s*$') then return true end
    if v:match('^/timed%s+%d+%s+/lua%s+run%s+turbogear%s+mini%s*$') then return true end
    if v:match('^/timed%s+%d+%s+/lua%s+run%s+TurboRolls%s*$') then return true end
    if v:match('^/timed%s+%d+%s+/lua%s+run%s+Turbo/gains_toggle%s+start%s*$') then return true end
    if v:match('^/timed%s+%d+%s+/lua%s+run%s+TurboMobs%s*$') then return true end
    return false
end

TG.mergeStartupToolEntries = function(iniPath, newLines)
    if not iniPath or iniPath == '' then return false, 0 end
    local dupes, derr = TG.iniHealth.duplicate_sections(iniPath, 'Startup Commands')
    if derr then return false, 0, derr end
    if dupes and #dupes > 0 then
        return false, 0, 'duplicate [Startup Commands]'
    end

    local ok, info = TG.iniHealth.merge_section(iniPath, 'Startup Commands', {
        allowCreate = true,
        newLines = newLines or {},
        removeLine = function(key, value)
            local isTurboSuite = key:sub(1, #TG.startupToolPrefix) == TG.startupToolPrefix
            local isGeneratedCommand = key:lower() == 'command' and TG.isStartupToolCommandValue(value)
            return isTurboSuite or isGeneratedCommand
        end,
    })
    if not ok then return false, 0, info end
    return true, (info and info.removed) or 0
end

TG.repairStartupToolEntries = function(iniPath)
    if not iniPath or iniPath == '' then return false, 0, 0 end
    local ok, info = TG.iniHealth.merge_section(iniPath, 'Startup Commands', {
        allowCreate = true,
        newLines = {},
        removeLine = function(key, value)
            local isTurboSuite = key:sub(1, #TG.startupToolPrefix) == TG.startupToolPrefix
            local isGeneratedCommand = key:lower() == 'command' and TG.isStartupToolCommandValue(value)
            return isTurboSuite or isGeneratedCommand
        end,
    })
    if not ok then return false, 0, 0, info end
    return true, (info and info.removed) or 0, (info and info.duplicateHeaders) or 0
end

TG.writeStartupToolEntries = function(iniPath)
    if not iniPath or iniPath == '' then return false, 0 end
    if TG.startupToolsEnabled ~= true then
        local ok, _, err = TG.mergeStartupToolEntries(iniPath, {})
        return ok, 0, err
    end

    local tools = TG.selectedStartupToolList()
    local delayStart = 100
    local delayStep = 50
    local count = 0
    local ids = {}
    for _, tool in ipairs(tools) do
        count = count + 1
        if count > TG.startupToolMaxLines then break end
        ids[#ids + 1] = tool.id
    end
    local lines = {}
    if #ids > 0 then
        lines[1] = string.format('Command=/lua run Turbo/startup_tool %d %d %s',
            delayStart, delayStep, table.concat(ids, ' '))
    end
    local ok, _, err = TG.mergeStartupToolEntries(iniPath, lines)
    if not ok then return false, 0, err end
    return true, count
end

TG.applyStartupToolsToTargets = function(enabled)
    TG.startupToolsEnabled = enabled == true
    TG.normalizeStartupToolState()

    local targets = TG.selectedStartupTargetList()
    local updated, skipped, failed, duplicate = 0, 0, 0, 0
    TG.lastStartupToolDuplicateTargets = {}
    for _, name in ipairs(targets) do
        local iniPath = findE3Ini(nil, name)
        if iniPath and fileExists(iniPath) then
            local ok, _, err = TG.writeStartupToolEntries(iniPath)
            if ok then
                updated = updated + 1
            else
                failed = failed + 1
                if tostring(err or ''):find('duplicate', 1, true) then
                    duplicate = duplicate + 1
                    TG.lastStartupToolDuplicateTargets[#TG.lastStartupToolDuplicateTargets + 1] = name
                end
            end
        else
            skipped = skipped + 1
        end
    end
    saveSettings()

    local action = TG.startupToolsEnabled and 'applied as one E3 Command= line' or 'removed'
    TG.statusMessage = string.format('Startup tools %s for %d character(s)%s%s.',
        action,
        updated,
        skipped > 0 and string.format(', %d missing INI', skipped) or '',
        failed > 0 and string.format(', %d failed', failed) or '')
    if duplicate > 0 then
        TG.statusMessage = TG.statusMessage .. string.format(' %d duplicate [Startup Commands]; use Repair duplicates.', duplicate)
    end
    return updated, skipped, failed
end

TG.repairStartupToolsForTargets = function()
    TG.normalizeStartupToolState()
    local targets = TG.selectedStartupTargetList()
    local repaired, skipped, failed, removed, dupHeaders = 0, 0, 0, 0, 0
    for _, name in ipairs(targets) do
        local iniPath = findE3Ini(nil, name)
        if iniPath and fileExists(iniPath) then
            local ok, r, d = TG.repairStartupToolEntries(iniPath)
            if ok then
                repaired = repaired + 1
                removed = removed + (tonumber(r) or 0)
                dupHeaders = dupHeaders + (tonumber(d) or 0)
            else
                failed = failed + 1
            end
        else
            skipped = skipped + 1
        end
    end
    TG.lastStartupToolDuplicateTargets = {}
    TG.statusMessage = string.format('Startup INI repair: %d file(s), %d duplicate header(s), %d Turbo line(s) removed%s%s.',
        repaired, dupHeaders, removed,
        skipped > 0 and string.format(', %d missing INI', skipped) or '',
        failed > 0 and string.format(', %d failed', failed) or '')
    return repaired, skipped, failed
end

TG.startupToolPreviewText = function()
    local tools = TG.selectedStartupToolList()
    if #tools == 0 then return 'No tools selected.' end
    local delayStart = 100
    local delayStep = 50
    local labels, ids = {}, {}
    for _, tool in ipairs(tools) do
        labels[#labels + 1] = tool.label
        ids[#ids + 1] = tool.id
    end
    return string.format('Selected tools: %s\nWrites under E3 [Startup Commands]:\nCommand=/lua run Turbo/startup_tool %d %d %s',
        table.concat(labels, ', '), delayStart, delayStep, table.concat(ids, ' '))
end

TG.renderStartupToolsSetupPanel = function(tip)
    TG.normalizeStartupToolState()
    if not ImGui.CollapsingHeader('Startup tools###setup_startup_tools') then return end
    tip('Choose which Turbo companion tools are written to selected characters\' E3 [Startup Commands].')

    local function wrappedMuted(text)
        ImGui.PushTextWrapPos(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail())
        ImGui.TextDisabled(tostring(text or ''))
        ImGui.PopTextWrapPos()
    end

    local enabled = TG.startupToolsEnabled == true
    if Ui.buttonVariant((enabled and 'Startup ON' or 'Startup OFF') .. '##startup_tools_toggle',
        enabled and 'successButton' or 'secondaryButton', 118, 0) then
        TG.startupToolsEnabled = not enabled
        saveSettings()
    end
    tip('Master switch for Turbo companion startup commands. Apply writes/removes only Turbo-generated Command= startup lines.')
    wrappedMuted('Apply writes one E3 Command= line to each selected character.')
    wrappedMuted('On login, Turbo/startup_tool starts the selected tools one at a time: first after 10s, then 5s apart.')

    ImGui.TextColored(0.65, 0.72, 0.9, 1.0, 'Tools')
    local toolCols, toolW, toolGap = Ui.adaptiveColumns(3, 102, 4)
    for i, tool in ipairs(TG.startupToolChoices or {}) do
        Ui.gridSameLine(i, toolCols, toolGap)
        local on = TG.startupToolSelections[tool.id] == true
        if Ui.buttonVariant(tool.label .. '##startup_tool_' .. tool.id, on and 'primaryButton' or 'secondaryButton', toolW, 0) then
            TG.startupToolSelections[tool.id] = not on
            TG.normalizeStartupToolState()
            saveSettings()
        end
        tip(tool.tip .. '\n' .. tool.cmd)
    end

    ImGui.TextColored(0.65, 0.72, 0.9, 1.0, 'Characters')
    local roster = TG.collectOnlineCharacters and TG.collectOnlineCharacters() or {}
    local me = mq.TLO.Me.CleanName() or mq.TLO.Me.Name() or ''
    local haveMe = false
    for _, name in ipairs(roster) do
        if tostring(name):lower() == tostring(me):lower() then haveMe = true break end
    end
    if me ~= '' and me ~= 'NULL' and not haveMe then table.insert(roster, 1, me) end

    if Ui.buttonVariant('This box##startup_targets_self', 'secondaryButton', 88, 0) then
        TG.startupToolTargets = {}
        if me ~= '' and me ~= 'NULL' then TG.startupToolTargets[me] = true end
        saveSettings()
    end
    tip('Select only this character.')
    ImGui.SameLine()
    if Ui.buttonVariant('All online##startup_targets_all', 'secondaryButton', 92, 0) then
        for _, name in ipairs(roster) do
            if name and name ~= '' and name ~= 'NOBODY' then TG.startupToolTargets[name] = true end
        end
        saveSettings()
    end
    tip('Select all currently known online characters.')
    ImGui.SameLine()
    if Ui.buttonVariant('Clear##startup_targets_clear', 'secondaryButton', 70, 0) then
        TG.startupToolTargets = {}
        saveSettings()
    end
    tip('Clear the list. Applying with no selected character uses this box.')

    local targetCols, targetW, targetGap = Ui.adaptiveColumns(4, 78, 4)
    local targetIdx = 0
    for _, name in ipairs(roster) do
        if name and name ~= '' and name ~= 'NOBODY' then
            targetIdx = targetIdx + 1
            Ui.gridSameLine(targetIdx, targetCols, targetGap)
            local on = TG.startupToolTargets[name] == true
            if Ui.buttonVariant(name .. '##startup_target_' .. name, on and 'primaryButton' or 'secondaryButton', targetW, 0) then
                TG.startupToolTargets[name] = not on
                saveSettings()
            end
            tip((on and 'Remove ' or 'Add ') .. name .. ' from the startup edit target list.')
        end
    end

    ImGui.TextColored(0.55, 0.62, 0.72, 1.0, 'Preview')
    wrappedMuted(TG.startupToolPreviewText())
    local applyLabel = (TG.startupToolsEnabled == true) and 'Apply startup tools##startup_tools_apply' or 'Remove startup tools##startup_tools_apply'
    if Ui.buttonVariant(applyLabel, TG.startupToolsEnabled == true and 'successButton' or 'secondaryButton', 154, 0) then
        TG.applyStartupToolsToTargets(TG.startupToolsEnabled == true)
    end
    tip('Writes the previewed E3 Command= startup line, or removes Turbo companion startup lines if Startup is OFF.')
    ImGui.SameLine()
    if Ui.buttonVariant('Repair duplicates##startup_tools_repair_dupes', 'secondaryButton', 136, 0) then
        TG.repairStartupToolsForTargets()
    end
    tip('Collapses duplicate E3 [Startup Commands] sections for the selected character INIs, preserving non-Turbo commands.')
end

require('Turbo.setup_status').install(TG, {
    findE3Ini = findE3Ini,
    fileExists = fileExists,
    nowMS = nowMS,
    getMultiLooters = getMultiLooters,
    maxMultiLooters = MAX_MULTI_LOOTERS,
    setSingleLooterMode = setSingleLooterMode,
    syncLootRouteVars = syncLootRouteVars,
    setTurboState = setTurboState,
    setCombatState = setCombatState,
    setRouteVar = setRouteVar,
    getCurrentLooter = getCurrentLooter,
    getTurboState = getTurboState,
    getCombatLootState = getCombatLootState,
    saveSettings = saveSettings,
    setupAutoreloadDs = SETUP_AUTORELOAD_DS,
})

function TG.refreshSharedControl(force)
    local ok, st = pcall(function() return TG.sharedControl.status(force == true) end)
    if ok and st then
        TG.sharedControlStatus = st
        return st
    end
    TG.sharedControlStatus = {
        owner = '',
        selfName = tostring(mq.TLO.Me.Name() or ''),
        isOwner = true,
        expired = true,
    }
    return TG.sharedControlStatus
end

function TG.isSharedControlOwner()
    local st = TG.sharedControlStatus or TG.refreshSharedControl(false)
    return st.isOwner == true
end

function TG.sharedControlOwnerName()
    local st = TG.sharedControlStatus or TG.refreshSharedControl(false)
    if st and st.owner and st.owner ~= '' and not st.expired then return st.owner end
    return 'another box'
end

function TG.requireSharedControl(action)
    if TG.isSharedControlOwner() then return true end
    TG.statusMessage = string.format('%s requires Turbo control. Current controller: %s.',
        tostring(action or 'This action'), TG.sharedControlOwnerName())
    return false
end

function TG.takeSharedControl()
    local ok = TG.sharedControl.takeControl()
    TG.refreshSharedControl(true)
    TG.statusMessage = ok and 'Turbo control moved to this box.' or 'Could not take Turbo control.'
    return ok
end

function TG.renderSharedControlBadge(tip, compact)
    local st = TG.sharedControlStatus or TG.refreshSharedControl(false)
    local isOwner = st and st.isOwner == true
    local label = isOwner and (compact and 'Ctl' or 'Control') or (compact and 'Take' or ('Browse: ' .. TG.sharedControlOwnerName()))
    local variant = isOwner and 'successButton' or 'amberButton'
    local w = compact and (isOwner and 42 or 48) or (isOwner and 64 or 116)
    if Ui.buttonVariant(label .. '##shared_control_badge', variant, w, TG.LAYOUT_MODE_BTN_H or 24) then
        if not isOwner then TG.takeSharedControl() end
    end
    if TG.turboChromeDragAddLastItem then TG.turboChromeDragAddLastItem() end
    if tip then
        tip(isOwner
            and 'This box can edit shared loot setup and send team-wide commands.'
            or ('Browse mode. Click to take control from ' .. TG.sharedControlOwnerName() .. '.'))
    end
end

function TG.renderSharedControlSetupNotice(tip)
    if TG.isSharedControlOwner() then return end
    ImGui.TextColored(0.95, 0.72, 0.35, 1.0,
        'Browse mode: shared setup is controlled by ' .. TG.sharedControlOwnerName() .. '.')
    ImGui.SameLine()
    if Ui.buttonVariant('Take Control##setup_take_shared_control', 'amberButton', 112, TG.ACTION_BTN_H or 24) then
        TG.takeSharedControl()
    end
    if tip then tip('Take control to edit looters, profile assignments, INI rules, or team commands from this box.') end
    ImGui.Separator()
end

local function resolveEqclientIniPath()
    local candidates = {}
    local function addCandidate(dir)
        dir = tostring(dir or ''):match('^%s*(.-)%s*$') or ''
        if dir ~= '' then
            candidates[#candidates + 1] = dir .. '\\eqclient.ini'
        end
    end

    addCandidate(mq.TLO.MacroQuest.Path() or '')
    local ok, eqPath = pcall(function()
        if mq.TLO.EverQuest and mq.TLO.EverQuest.Path then
            return mq.TLO.EverQuest.Path()
        end
        return nil
    end)
    if ok then addCandidate(eqPath) end

    for _, p in ipairs(candidates) do
        if fileExists(p) then return p end
    end
    return candidates[1]
end

local function openE3IniExternal(characterName)
    local path = findE3Ini(nil, characterName)
    if not path or path == '' then
        TG.statusMessage = 'E3 INI path not found.'
        return
    end
    shellOpenFile(path)
    TG.statusMessage = 'Opened E3 INI: ' .. TG.fileBaseName(path)
end

TG.openTurbolootIniForCharacterExternal = function(characterName)
    characterName = tostring(characterName or ''):match('^%s*(.-)%s*$') or ''
    local profile = characterName ~= '' and getProfileForMember(characterName) or getActiveProfile()
    openProfileExternal(profile)
end

TG.fileBaseName = function(path)
    return tostring(path or ''):match('[^\\/]+$') or tostring(path or '')
end

TG.backupFileBesideOriginal = function(srcPath, label)
    if not srcPath or srcPath == '' then
        return nil, 'No file path found.'
    end
    if not fileExists(srcPath) then
        return nil, string.format('%s not found: %s', label or 'File', srcPath)
    end

    local stamp = os.date('%Y%m%d-%H%M%S')
    local backupPath = string.format('%s.%s.bak', srcPath, stamp)
    local n = 1
    while fileExists(backupPath) do
        backupPath = string.format('%s.%s-%02d.bak', srcPath, stamp, n)
        n = n + 1
    end

    local src = io.open(srcPath, 'rb')
    if not src then return nil, 'Could not open source file.' end
    local data = src:read('*a')
    src:close()

    local dest = io.open(backupPath, 'wb')
    if not dest then return nil, 'Could not create backup file.' end
    dest:write(data or '')
    dest:close()
    return backupPath
end

TG.copyFileBinary = function(srcPath, destPath)
    if not srcPath or srcPath == '' then return nil, 'No source path.' end
    if not fileExists(srcPath) then return nil, 'Source file not found: ' .. tostring(srcPath) end
    local src = io.open(srcPath, 'rb')
    if not src then return nil, 'Could not open source file.' end
    local data = src:read('*a')
    src:close()
    local dest = io.open(destPath, 'wb')
    if not dest then return nil, 'Could not write destination file.' end
    dest:write(data or '')
    dest:close()
    return destPath
end

TG.findTurbolootExampleIni = function()
    local IniProfiles = require('Turbo.ini_profiles')
    return IniProfiles.findExampleIni()
end

TG.normalizeNewProfileName = function(raw)
    local name = cleanProfileName(raw)
    if not name or name == '' then return nil, 'Enter a profile name.' end
    if not name:lower():find('%.ini$', 1) then
        if name:lower():find('^turboloot', 1) then
            name = name .. '.ini'
        else
            name = 'turboloot_' .. name .. '.ini'
        end
    end
    name = cleanProfileName(name)
    if not name or name == '' then return nil, 'Invalid profile name.' end
    if not name:lower():find('^turboloot', 1) then
        return nil, 'Profile names must start with turboloot (e.g. turboloot_mage.ini).'
    end
    if TG.isRuntimeProfileName(name) then
        return nil, 'That name is reserved for Turbo runtime files.'
    end
    if name:lower() == 'turbolootexample.ini' then
        return nil, 'Cannot use the example template filename as a profile.'
    end
    return name
end

TG.validateTurbolootIniContent = function(path)
    if not path or not fileExists(path) then return false, 'INI file not found.' end
    local f = io.open(path, 'r')
    if not f then return false, 'Could not read INI file.' end
    local hasSettings = false
    for line in f:lines() do
        if line:match('^%[Settings%]%s*$') or line:match('^%[ItemLimits%]%s*$') then
            hasSettings = true
            break
        end
    end
    f:close()
    if not hasSettings then
        return false, 'File does not look like a TurboLoot INI (missing [Settings] or [ItemLimits]).'
    end
    return true
end

TG.createProfileFromTemplate = function(rawName, opts)
    opts = type(opts) == 'table' and opts or {}
    local name, normErr = TG.normalizeNewProfileName(rawName or 'turboloot.ini')
    if not name then return nil, normErr end
    local mqPath = mq.TLO.MacroQuest.Path() or ''
    if mqPath == '' then return nil, 'MacroQuest path unknown.' end
    local destPath = mqPath .. '\\Config\\' .. name
    local _, exists = TG.profileFileLocation(name, false)
    if exists and opts.overwrite ~= true then
        return nil, 'Profile already exists: ' .. name
    end
    local source = opts.sourcePath or TG.findTurbolootExampleIni()
    if not source then return nil, 'Missing turbolootexample.ini in Macros or Config.' end
    local copied, copyErr = TG.copyFileBinary(source, destPath)
    if not copied then return nil, copyErr or 'Could not create profile.' end
    TG.addProfileCandidate(name, false, false)
    TG.saveProfileCache()
    if TG.rescanProfiles then TG.rescanProfiles() end
    if opts.setActive ~= false then setActiveProfile(name) end
    return destPath, name
end

TG.cloneProfile = function(srcName, destRaw, opts)
    opts = type(opts) == 'table' and opts or {}
    local src = cleanProfileName(srcName) or getActiveProfile()
    local dest, normErr = TG.normalizeNewProfileName(destRaw)
    if not dest then return nil, normErr end
    if src:lower() == dest:lower() then return nil, 'Source and destination must differ.' end
    local srcPath, srcExists = resolveTurbolootIniPathForProfile(src)
    if not srcPath or not srcExists then return nil, 'Source INI not found: ' .. tostring(src) end
    local _, destExists = TG.profileFileLocation(dest, false)
    if destExists and opts.overwrite ~= true then
        return nil, 'Destination already exists: ' .. dest
    end
    local mqPath = mq.TLO.MacroQuest.Path() or ''
    if mqPath == '' then return nil, 'MacroQuest path unknown.' end
    local destPath = mqPath .. '\\Config\\' .. dest
    local copied, copyErr = TG.copyFileBinary(srcPath, destPath)
    if not copied then return nil, copyErr or 'Clone failed.' end
    TG.addProfileCandidate(dest, false, false)
    TG.saveProfileCache()
    if TG.rescanProfiles then TG.rescanProfiles() end
    if opts.setActive then setActiveProfile(dest) end
    return destPath, dest
end

TG.resolveImportSourcePath = function(pathOrName)
    local raw = tostring(pathOrName or ''):match('^%s*(.-)%s*$') or ''
    if raw == '' then return nil, 'Enter a file name or full path.' end
    if raw:find('[\\/]') or raw:find('%.ini$', 1, true) then
        if fileExists(raw) then return raw end
    end
    local name, normErr = TG.normalizeNewProfileName(raw)
    if name then
        local path, exists = TG.profileFileLocation(name, true)
        if exists then return path end
    end
    local mqPath = mq.TLO.MacroQuest.Path() or ''
    if mqPath ~= '' then
        local candidates = {
            mqPath .. '\\Config\\' .. raw,
            mqPath .. '\\Macros\\' .. raw,
        }
        if not raw:lower():find('%.ini$', 1) then
            candidates[#candidates + 1] = mqPath .. '\\Config\\' .. raw .. '.ini'
            candidates[#candidates + 1] = mqPath .. '\\Macros\\' .. raw .. '.ini'
        end
        for _, path in ipairs(candidates) do
            if fileExists(path) then return path end
        end
    end
    return nil, 'Import source not found: ' .. raw
end

TG.importProfile = function(pathOrName, opts)
    opts = type(opts) == 'table' and opts or {}
    local srcPath, srcErr = TG.resolveImportSourcePath(pathOrName)
    if not srcPath then return nil, srcErr end
    local okContent, contentErr = TG.validateTurbolootIniContent(srcPath)
    if not okContent then return nil, contentErr end
    local base = TG.fileBaseName(srcPath)
    local destName, normErr
    if opts.destName and opts.destName ~= '' then
        destName, normErr = TG.normalizeNewProfileName(opts.destName)
        if not destName then return nil, normErr end
    else
        destName, normErr = TG.normalizeNewProfileName(base)
        if not destName then
            destName = cleanProfileName(base)
        end
    end
    if TG.isRuntimeProfileName(destName) then
        return nil, 'Imported filename is reserved for Turbo runtime files.'
    end
    local mqPath = mq.TLO.MacroQuest.Path() or ''
    if mqPath == '' then return nil, 'MacroQuest path unknown.' end
    local destPath = mqPath .. '\\Config\\' .. destName
    local _, destExists = TG.profileFileLocation(destName, false)
    if destExists and opts.overwrite ~= true then
        return nil, 'Profile already exists in Config: ' .. destName
    end
    local copied, copyErr = TG.copyFileBinary(srcPath, destPath)
    if not copied then return nil, copyErr or 'Import failed.' end
    TG.addProfileCandidate(destName, false, false)
    TG.saveProfileCache()
    if TG.rescanProfiles then TG.rescanProfiles() end
    if opts.setActive then setActiveProfile(destName) end
    return destPath, destName
end

TG.exportProfile = function(profileName, destPath)
    local name = cleanProfileName(profileName) or getActiveProfile()
    local srcPath, exists = resolveTurbolootIniPathForProfile(name)
    if not srcPath or not exists then return nil, 'INI not found: ' .. tostring(name) end
    if not destPath or destPath == '' then
        local exportDir = TG.turboSupportDir('exports')
        if not exportDir then return nil, 'Could not create Turbo exports folder.' end
        destPath = exportDir .. '\\' .. name
    end
    local copied, copyErr = TG.copyFileBinary(srcPath, destPath)
    if not copied then return nil, copyErr or 'Export failed.' end
    return destPath, name
end

TG.getPendingNavigationPath = function()
    local configDir = mq.configDir or getConfigDir()
    local newPath = TG.paths.state_file('turbo_pending_nav.lua')
    local legacyPath = configDir and (configDir:gsub('/', '\\') .. '\\turbo_pending_nav.lua') or nil
    if newPath and fileExists(newPath) then return newPath end
    if legacyPath and fileExists(legacyPath) then return legacyPath end
    return newPath or legacyPath
end

TG.queueNavigation = function(tabName)
    local IniProfiles = require('Turbo.ini_profiles')
    return IniProfiles.queueNavigation(tabName)
end

TG.consumePendingNavigation = function()
    local path = TG.getPendingNavigationPath()
    if not path or not fileExists(path) then return nil end
    local fn = loadfile(path)
    os.remove(path)
    if not fn then return nil end
    local ok, tab = pcall(fn)
    if not ok or type(tab) ~= 'string' or tab == '' then return nil end
    TG.windowOpen = true
    TG.minimizedGUI = false
    TG.slimGUI = false
    TG.slimWhenExpanded = false
    TG.activeTab = UiState.normalizeActiveTab(tab)
    TG.lastRelevantTab = TG.activeTab
    if tab == 'review' then
        TG.reviewWindowOpen = true
        TG.skipReviewOpen = true
    elseif tab == 'tools' then
        TG.activeTab = 'tools'
    end
    return TG.activeTab
end

TG.backupActiveTurbolootIni = function()
    return TG.backupFileBesideOriginal(getTurbolootIniPath(), 'Active TurboLoot INI')
end

TG.backupLocalE3Ini = function(manualFile, characterName)
    return TG.backupFileBesideOriginal(findE3Ini(manualFile, characterName), 'E3 INI')
end

TG.backupEqclientIni = function()
    return TG.backupFileBesideOriginal(resolveEqclientIniPath(), 'eqclient.ini')
end

TG.backupStatusMessage = function(label, backupPath, err)
    if backupPath then
        return string.format('%s backed up: %s', label, TG.fileBaseName(backupPath))
    end
    return string.format('%s backup failed: %s', label, err or 'unknown error')
end

function TG.openTurboGainsWindow(reason)
    TG.gainsWindowOpen = true
    TG.gainsWindowOpenReason = tostring(reason or 'unknown')
    TG.gainsWindowOpenAt = os.time()
end

TG.ensureFolder = function(path)
    return TG.paths.ensure_dir(path)
end

TG.turboSupportDir = function(kind)
    return TG.paths.dir(kind)
end

TG.cleanupDiagnosticsBundles = function(opts)
    opts = type(opts) == 'table' and opts or {}
    local diagDir = TG.turboSupportDir('diagnostics')
    if not diagDir then return { removed = 0, kept = 0, errors = 1, notes = { 'Could not open diagnostics folder.' } } end
    local keep = tonumber(opts.keep) or 5
    local maxAgeDays = tonumber(opts.maxAgeDays) or 7
    local now = os.time()
    local entries, notes = {}, {}
    local cmd = string.format('dir /b /ad "%s\\Turbo_diag_*" 2>nul', diagDir:gsub('/', '\\'))
    local pipe = io.popen(cmd)
    if pipe then
        for name in pipe:lines() do
            name = tostring(name or ''):match('^%s*(.-)%s*$') or ''
            local y, mo, d, h, mi, s = name:match('^Turbo_diag_.-_(%d%d%d%d)(%d%d)(%d%d)_(%d%d)(%d%d)(%d%d)$')
            if y then
                local ts = os.time({
                    year = tonumber(y),
                    month = tonumber(mo),
                    day = tonumber(d),
                    hour = tonumber(h),
                    min = tonumber(mi),
                    sec = tonumber(s),
                }) or 0
                entries[#entries + 1] = { name = name, path = diagDir .. '\\' .. name, ts = ts }
            end
        end
        pipe:close()
    else
        notes[#notes + 1] = 'Could not list diagnostics bundles.'
    end

    table.sort(entries, function(a, b) return (a.ts or 0) > (b.ts or 0) end)
    local removed, errors = 0, 0
    for i, entry in ipairs(entries) do
        local oldEnough = maxAgeDays >= 0 and entry.ts > 0 and now and ((now - entry.ts) > (maxAgeDays * 86400))
        local overKeep = keep >= 0 and i > keep
        if oldEnough or overKeep then
            local safeName = tostring(entry.name or '')
            if safeName:match('^Turbo_diag_[%w_%-]+_%d%d%d%d%d%d%d%d_%d%d%d%d%d%d$') then
                local ok = os.execute(string.format('cmd /c rmdir /s /q "%s"', tostring(entry.path):gsub('/', '\\')))
                if ok == true or ok == 0 then
                    removed = removed + 1
                else
                    errors = errors + 1
                    notes[#notes + 1] = 'Failed to remove ' .. safeName
                end
            end
        end
    end

    return {
        removed = removed,
        kept = math.max(0, #entries - removed),
        errors = errors,
        scanned = #entries,
        keep = keep,
        maxAgeDays = maxAgeDays,
        notes = notes,
    }
end

TG.exportDiagnosticsReport = function()
    return require('Turbo.diagnostics_export').run({
        TG = TG,
        TURBO_VERSION = TURBO_VERSION,
        nowMS = nowMS,
        fileExists = fileExists,
        findE3Ini = findE3Ini,
        getConfigDir = getConfigDir,
        getTurbolootIniPath = getTurbolootIniPath,
        getCharSettingsPath = getCharSettingsPath,
        getSettingsPath = getSettingsPath,
        getCurrentLooter = getCurrentLooter,
        getTurboState = getTurboState,
        getCombatLootState = getCombatLootState,
        getLootAllState = getLootAllState,
        isMultiLootMode = isMultiLootMode,
        readIniKey = readIniKey,
    })
end

TG.printBackupResult = function(label, backupPath, err)
    if backupPath then
        printf('\at[Turbo]\ax %s backed up: \ag%s\ax', label, backupPath)
    else
        printf('\at[Turbo]\ax \ar%s backup failed:\ax %s', label, tostring(err or 'unknown error'))
    end
end

TG.sendE3BackupTo = function(name)
    name = tostring(name or ''):match('^%s*(.-)%s*$') or ''
    if name == '' or name == 'NOBODY' then return false end
    mq.cmdf('/squelch /e3bct %s /lua run Turbo backup e3', name)
    return true
end

TG.sendGroupE3Backups = function()
    local sent = 0
    collectGroupMembers()
    for _, name in ipairs(TG.members or {}) do
        if TG.sendE3BackupTo(name) then sent = sent + 1 end
    end
    return sent
end

--- extraEntries (optional): list of { section, key, value } merged after SETUP_ENTRIES.
local function insertIniEntries(filePath, extraEntries)
    local lines = {}
    local f = io.open(filePath, 'r')
    if f then
        for line in f:lines() do
            table.insert(lines, line)
        end
        f:close()
    end

    local duplicates, dupErr = TG.iniHealth.duplicate_sections(filePath)
    if dupErr == nil and duplicates and #duplicates > 0 then
        return false, 'duplicate INI sections: ' .. TG.iniHealth.format_duplicates(duplicates)
    end

    local sectionMap = {}
    local currentSec = nil
    for i, line in ipairs(lines) do
        local sec = line:match('^%[(.-)%]%s*$')
        if sec then
            currentSec = sec
            if not sectionMap[sec] then
                sectionMap[sec] = { headerLine = i, keys = {} }
            end
        elseif currentSec then
            local k = line:match('^([^=]+)=')
            if k then
                sectionMap[currentSec].keys[k:match('^%s*(.-)%s*$')] = i
            end
        end
    end

    local insertions = {}

    local mergedEntries = SETUP_ENTRIES
    if extraEntries and #extraEntries > 0 then
        mergedEntries = {}
        for _, e in ipairs(SETUP_ENTRIES) do
            mergedEntries[#mergedEntries + 1] = e
        end
        for _, e in ipairs(extraEntries) do
            mergedEntries[#mergedEntries + 1] = e
        end
    end

    for _, entry in ipairs(mergedEntries) do
        local sec = sectionMap[entry.section]
        if sec then
            if sec.keys[entry.key] then
                lines[sec.keys[entry.key]] = entry.key .. '=' .. entry.value
            else
                if not insertions[sec.headerLine] then
                    insertions[sec.headerLine] = {}
                end
                table.insert(insertions[sec.headerLine], entry.key .. '=' .. entry.value)
            end
        else
            table.insert(lines, '')
            table.insert(lines, '[' .. entry.section .. ']')
            local newIdx = #lines
            sectionMap[entry.section] = { headerLine = newIdx, keys = {} }
            table.insert(lines, entry.key .. '=' .. entry.value)
            sectionMap[entry.section].keys[entry.key] = #lines
        end
    end

    if next(insertions) then
        local newLines = {}
        for i, line in ipairs(lines) do
            table.insert(newLines, line)
            if insertions[i] then
                for _, ins in ipairs(insertions[i]) do
                    table.insert(newLines, ins)
                end
            end
        end
        lines = newLines
    end

    f = io.open(filePath, 'w')
    if not f then return false, 'write failed' end
    for _, line in ipairs(lines) do
        f:write(line .. '\n')
    end
    f:close()
    return true
end

local function warnPreflightSetup(tag)
    local mqMonoOk = false
    if mq.TLO.MQ2Mono and mq.TLO.MQ2Mono.Query then
        mqMonoOk = pcall(function() mq.TLO.MQ2Mono.Query('e3,Turbo')() end)
    end
    if not mqMonoOk then
        printf('%s \ayWarning:\ax MQ2Mono / E3 query not available — load E3Next and MQ2Mono before relying on auto-loot.\ax', tag)
    end
    local mqPath = mq.TLO.MacroQuest.Path() or ''
    if mqPath ~= '' then
        local hasLoot = fileExists(mqPath .. '\\Macros\\TurboLoot.mac')
            or fileExists(mqPath .. '\\Config\\TurboLoot.mac')
        if not hasLoot then
            printf('%s \ayWarning:\ax TurboLoot.mac not in Macros or Config — corpse events call /mac TurboLoot.\ax', tag)
        end
        local hasTurboMac = fileExists(mqPath .. '\\Macros\\Turbo.mac')
            or fileExists(mqPath .. '\\Config\\Turbo.mac')
        if not hasTurboMac then
            printf('%s \ayWarning:\ax Turbo.mac not in Macros or Config — you can still use this Lua GUI.\ax', tag)
        end
        local hasMoney = fileExists(mqPath .. '\\lua\\Turbo\\gains.lua')
        local hasToggle = fileExists(mqPath .. '\\lua\\Turbo\\gains_toggle.lua')
        if hasMoney and hasToggle then
            printf('%s \agTurboGains:\ax gains.lua + gains_toggle.lua — More > Gains: /e3bcaa start/stop; optional INI autostart.\ax', tag)
        else
            if not hasMoney then
                printf('%s \ayWarning:\ax lua\\Turbo\\gains.lua missing — TurboGains unavailable.\ax', tag)
            end
            if not hasToggle then
                printf('%s \ayWarning:\ax lua\\Turbo\\gains_toggle.lua missing — group start/stop + autostart UI need it.\ax', tag)
            end
        end
        local hasMoneyAnnounce = fileExists(mqPath .. '\\lua\\Turbo\\loot_announce.lua')
        if hasMoney and not hasMoneyAnnounce then
            printf('%s \ayNote:\ax loot_announce.lua optional (EQBC fallback if Actors unavailable).\ax', tag)
        end
    end
end

--- High-visibility block so new users do not miss /e3reload and Turbo on/GUI.
--- queuedReloadDs (number): positive if step 1 was scheduled via /timed (deciseconds).
local function printSetupNextStepsBanner(tag, queuedReloadDs)
    queuedReloadDs = tonumber(queuedReloadDs) or 0
    local bar = '\ao================================================================\ax'
    printf('%s %s', tag, bar)
    printf('%s \ay>>>\ax  \agNEXT — run these commands (in order)\ax  \ay<<<\ax', tag)
    printf('%s %s', tag, bar)
    if queuedReloadDs > 0 then
        printf('%s  \ag1.\ax \aye3reload\ax \aw— \agqueued\ax (\at/timed %d\aw ~%.1fs). Reloads \ay[Events]\aw + \ay[Startup Commands]\aw.\ax',
            tag, queuedReloadDs, queuedReloadDs / 10)
    else
        printf('%s  \ag1.\ax \at/e3reload\ax', tag)
        printf('%s      \awReloads E3 so \ay[Events]\aw + \ay[Startup Commands]\aw from your INI take effect.\ax', tag)
    end
    printf('%s  \ag2.\ax  Then \aweither:\ax', tag)
    printf('%s      \at/lua run Turbo\ax      \aw— pick single, multi, or all looters in the GUI\ax', tag)
    printf('%s      \at/lua run Turbo on\ax   \aw— turn auto-loot \agon\aw from the command line\ax', tag)
    printf('%s  \ag3.\ax TurboGains: use \agMore > Gains\ax Start/Stop (\at/e3bcaa gains_toggle\ax) or optional \agLogin autostart\ax INI line.\ax', tag)
    printf('%s %s', tag, bar)
    printf('%s \aw(Run \at/e3reload\aw manually if you skipped autoreload, or reload is still pending from an earlier timed command.)\ax', tag)
    printf('%s %s', tag, bar)
end

local function printSetupChecklist(tag, charDidSetup)
    printf('%s \au— First-time order (do once per tank / event owner) —\ax', tag)
    printf('%s  \ag1.\ax Install \ayTurboLoot.mac\ax, \ayTurbo.mac\ax, \ayTurboKey.mac\ax (optional), repo \aylua\\Turbo\\\ax → MQ \aylua\\Turbo\\\ax', tag)
    printf('%s  \ag2.\ax First Run opens and creates \ayturboloot.ini\ax from the starter template if needed.', tag)
    printf('%s \ag3.\ax Recommended group setup: \ag/lua run Turbo setup\ax — patches \ayyour\ax E3 INI + quietly repairs current group hooks via E3', tag)
    printf('%s     \awDriver-only setup: \ag/lua run Turbo setup driver\aw (alias: \agsetup local\aw) = this character only, no group sync.\ax', tag)
    printf('%s  \ag4.\ax \ag/lua run Turbo setup\ax queues \ag/e3reload\ax (~8s) so [Events] apply — use \agsetup noreload\ax to skip autoreload.\ax', tag)
    printf('%s  \ag5.\ax \ag/lua run Turbo on\ax or open GUI (\ag/lua run Turbo\ax), set looter, confirm Turbo ON', tag)
    printf('%s  \ag6.\ax TurboGains: \agTurbo setup\ax syncs INI hooks; press \agStart\ax in More > Gains (or gains_toggle) to run trackers.\ax', tag)
    if charDidSetup then
        printf('%s \awCharacter:\ax \ag%s\ax', tag, mq.TLO.Me.CleanName() or '?')
    end
end

--- manualFile (string/nil): optional INI basename for findE3Ini.
--- scheduleReload (boolean/nil): nil = queue /e3reload (~8s); true = same; false = skip (use setup noreload).
--- setupOpts (table/nil):
---   mode: 'full' (default) = banners + optional group /e3bcaa sync; 'local' = quiet per-character INI patch (no broadcast).
local function doLuaSetup(manualFile, scheduleReload, setupOpts)
    setupOpts = setupOpts or {}
    local mode = setupOpts.mode or 'full'
    local silent = (mode == 'local')
    local tag = '\at[Turbo]\ax'
    local queuedReloadDs = 0

    if scheduleReload == nil then
        scheduleReload = true
    end

    local iniPath = findE3Ini(manualFile)
    if not iniPath then
        printf('%s \arCould not determine E3 INI path.\ax', tag)
        if not silent then
            printf('%s Try: \at/lua run Turbo setup YourChar_Server.ini\ax or \at/lua run Turbo setup noreload\ax', tag)
        end
        return
    end

    if silent then
        printf('%s Setup \ay(driver/local)\ax \ag%s\ax', tag, iniPath)
        printf('%s \awThis updates only this character; no group sync will be sent.\ax', tag)
    else
        printf('%s \ay--- Setup ---\ax', tag)
        printf('%s Target: \ag%s\ax', tag, iniPath)
        printf('%s \awRecommended group setup: this character updates now, then current group members receive quiet \agTurbo setup hooksonly\aw.\ax', tag)
    end
    warnPreflightSetup(tag)

    local existed = fileExists(iniPath)
    if not existed then
        printf('%s \ayINI not found -- creating new file.\ax', tag)
    end

    local mqPath = mq.TLO.MacroQuest.Path() or ''
    local ok, writeErr = insertIniEntries(iniPath)
    if ok then
        if not silent then
            printf('%s \agSetup complete!\ax Entries written to INI.', tag)
        else
            printf('%s \agINI updated\ax (%s).', tag, mq.TLO.Me.CleanName() or '?')
        end
        local verifyOk = TG.verifyEventsAfterSetup(iniPath, tag)
        TG.invalidateE3SetupStatusCache()
        if TG.scheduleSetupRestore then
            TG.scheduleSetupRestore(setupOpts, scheduleReload == true)
        else
            saveSettings()
        end
        if scheduleReload then
            queuedReloadDs = SETUP_AUTORELOAD_DS
            mq.cmd('/timed ' .. queuedReloadDs .. ' /e3reload')
            if silent then
                printf('%s \agAutoreload:\ax queued \at/e3reload\ax in \ay%.1f\ax s.',
                    tag, queuedReloadDs / 10)
            else
                printf('%s \agAutoreload:\ax queued \at/e3reload\ax in \ay%.1f\ax s (\at/timed %d\ax).',
                    tag, queuedReloadDs / 10, queuedReloadDs)
            end
        end
        if not silent and (not existed or not verifyOk) then
            printSetupChecklist(tag, true)
        end
        if not silent then
            printSetupNextStepsBanner(tag, queuedReloadDs)
        end
        if not existed then
            printf('%s \ayNote: new file created. Verify E3 loads from this path.\ax', tag)
        end

        if not silent then
            collectGroupMembers()
            local meName = (mq.TLO.Me.Name() or ''):lower()
            local meClean = (mq.TLO.Me.CleanName() or ''):lower()
            local sent = 0
            for _, name in ipairs(TG.members or {}) do
                local nl = (name or ''):lower()
                if nl ~= '' and nl ~= meName and nl ~= meClean then
                    TG.sendRemoteSetupLocal(name, SETUP_GROUP_PROPAGATE_DS)
                    sent = sent + 1
                end
            end
            if sent > 0 then
                printf('%s Group sync: quiet \agTurbo setup hooksonly\ax -> \ag%d\ax other group member(s) (~%.1fs).\ax',
                    tag, sent, SETUP_GROUP_PROPAGATE_DS / 10)
                printf('%s \awEach patches its own E3 INI and queues /e3reload without opening Turbo UI.\ax', tag)
            else
                printf('%s \awNo other group members detected — only this session was configured.\ax', tag)
                printf('%s \awMultibox outside /group: run \ag/lua run Turbo setup driver\ax on each session once, or only on your event driver.\ax', tag)
            end
        end
    else
        printf('%s \arFailed to write to: %s\ax', tag, iniPath)
        if writeErr and tostring(writeErr):find('duplicate INI sections', 1, true) then
            printf('%s \ay%s\ax', tag, writeErr)
            printf('%s \awFix duplicate sections in the E3 INI first, then run setup again. Startup tools can repair duplicate [Startup Commands].\ax', tag)
        else
            printf('%s Check file permissions and path.%s', tag, writeErr and (' ' .. tostring(writeErr)) or '')
        end
    end
end

TG.runSetup = doLuaSetup

-- =========================================================
-- Colors shim: delegates to Theme.col (see lua/Turbo/theme.lua)
-- =========================================================
local Colors = {
    turboloot   = Theme.col.turboloot,
    turbogive   = Theme.col.turbogive,
    turbokey    = Theme.col.turbokey,
    currency    = Theme.col.currency,
    --- 3.8.66: route new palette keys (theme.lua 1.5.0) into the Colors
    --- alias table. Without this thinSep('conversions', ...) and
    --- thinSep('corpses', ...) fall through to the `or Colors.turboloot`
    --- safety branch and silently render in blue.
    conversions = Theme.col.conversions,
    corpses     = Theme.col.corpses,
    profile     = Theme.col.profile,
    skipreview  = Theme.col.skipreview,
    status      = { on = Theme.col.statusOn, off = Theme.col.statusOff },
    statusMsg   = Theme.col.statusMsg,
    plat        = Theme.col.plat,
    aa          = Theme.col.aa,
    error       = Theme.col.errorCol,
    neutral     = Theme.col.neutral,
    neutralLit  = Theme.col.neutralLit,
    warn        = Theme.col.warn,
    warnLit     = Theme.col.warnLit,
    memberHi    = Theme.col.memberHi,
    memberAll   = Theme.col.memberAll,
    memberSel   = Theme.col.memberSel,
    lootCell    = Theme.col.lootCell,
}

--- TurboKey rule buttons: shared RGB for Slim + Full (KEEP=keep, SELL/BANK=trade, TRIBUTE, DESTROY=warn, IGNORE/SKIP=muted).
local TurboKeyRGB = Theme.col.turboKeyRGB

-- =========================================================
-- GUI helpers (hoisted to module scope to avoid per-frame allocation)
-- =========================================================

local function tip(text)
    Ui.tooltip(text, 30.0)
end

local function coloredSep(r, g, b, a)
    Ui.separator(r, g, b, a)
end

local function thinSep(colorKey, label)
    local c = Colors[colorKey] or Colors.turboloot
    Ui.sectionHeader(c, label)
end

--- Footer (Full + Slim): Tools menu + Wallet panel.
local TURBO_FOOTER_TOOLS_POPUP = 'TurboFooterTools##popup'
local TURBO_FOOTER_WALLET_POPUP = 'TurboFooterWallet##popup'
TG.TURBO_FOOTER_HELP_POPUP = 'TurboFooterHelp##popup'

--- Cached wallet values — refreshed on AUTO_REFRESH_MS timer alongside collectGroupMembers.
--- Avoids per-frame TLO calls when wallet strip is always visible.
local cachedWallet = { plat=0, aa=0, dc=0, favor=0, lastUpdateMS=0 }

local function refreshWalletCache()
    cachedWallet.plat  = tonumber(mq.TLO.Me.Platinum() or 0) or 0
    cachedWallet.aa    = tonumber(mq.TLO.Me.AAPoints() or 0) or 0
    cachedWallet.dc    = 0
    local ok, dc = pcall(function()
        local t = mq.TLO.Me.AltCurrency('Diamond Coins')
        return t and tonumber(t()) or 0
    end)
    if ok then cachedWallet.dc = dc end
    local ok2, fav = pcall(function()
        return tonumber(mq.TLO.Me.CurrentFavor() or 0) or 0
    end)
    cachedWallet.favor = ok2 and fav or 0
    cachedWallet.lastUpdateMS = mq.gettime()
end

local function readAltCurrencyAmount(name)
    local ok, v = pcall(function()
        local t = mq.TLO.Me.AltCurrency(name)
        if not t then return nil end
        local n = t()
        if n == nil then return nil end
        return tonumber(n) or 0
    end)
    if ok and type(v) == 'number' then return v end
    return 0
end

local function readTributeFavor()
    local ok, v = pcall(function()
        local n = mq.TLO.Me.CurrentFavor()
        if n == nil then return 0 end
        return tonumber(n) or 0
    end)
    if ok and type(v) == 'number' then return v end
    return 0
end

local function imguiWalletValueLines()
    local plat = mq.TLO.Me.Platinum() or 0
    local aa = mq.TLO.Me.AAPoints() or 0
    local dc = readAltCurrencyAmount('Diamond Coins')
    local favor = readTributeFavor()
    ImGui.TextColored(Colors.plat[1], Colors.plat[2], Colors.plat[3], 1.0, string.format('Plat: %s', tostring(plat)))
    ImGui.TextColored(Colors.aa[1], Colors.aa[2], Colors.aa[3], 1.0, string.format('AA: %s', tostring(aa)))
    ImGui.TextColored(0.72, 0.80, 0.95, 1.0, string.format('Diamond Coins: %s', tostring(dc)))
    ImGui.TextColored(0.82, 0.70, 0.95, 1.0, string.format('Tribute favor: %s', tostring(favor)))
end

--- Hover hint on Wallet button (values live in the Wallet popup).
local function tooltipWalletSummaryOnHover()
    if not ImGui.IsItemHovered() then return end
    ImGui.BeginTooltip()
    ImGui.PushTextWrapPos(ImGui.GetFontSize() * 30.0)
    ImGui.Text('Plat, AA, Diamond Coins, tribute favor — click for live panel.')
    ImGui.PopTextWrapPos()
    ImGui.EndTooltip()
end

local function drawWalletPopupPanel()
    ImGui.PushTextWrapPos(ImGui.GetFontSize() * 36.0)
    ImGui.TextColored(0.55, 0.58, 0.68, 1.0, 'Character wallet & tribute')
    ImGui.TextColored(0.45, 0.48, 0.52, 1, 'Plat, AA, Diamond Coins (alt currency), CurrentFavor.')
    ImGui.Spacing()
    imguiWalletValueLines()
    ImGui.Spacing()
    ImGui.Separator()
    ImGui.TextColored(0.42, 0.45, 0.52, 1, 'Values refresh while this menu is open.')
    ImGui.PopTextWrapPos()
end

local function toggleSwitch(id, isOn, width, height)
    return Ui.toggleChip(id, isOn, {
        width = width,
        height = height,
        nowMS = nowMS,
        debounceMs = TOGGLE_DEBOUNCE_MS,
        lastToggleMS = function() return TG.lastToggleMS end,
        setLastToggleMS = function(v) TG.lastToggleMS = v end,
    })
end

--- Default width for main TurboLoot / TurboGive grids (uniform rows; narrower = less wide Full window).
--- Full TurboLoot block overrides with a 3-column grid width from `GetContentRegionAvail()` each frame.
local ACTION_BTN_W = 96
local ACTION_BTN_H = 0
local LAYOUT_MODE_BTN_W, LAYOUT_MODE_BTN_H = 58, 28
local SLIM_LAYOUT_BTN_W, SLIM_LAYOUT_BTN_H = 50, 24
local SLIM_HELP_H = 22
local SLIM_COMBAT_PACK_W = 94
--- Slim-only: hide stale status line (TurboKey feedback etc.) so footer does not stay tall.
local SLIM_STATUS_MSG_TTL_MS = Theme.layout.statusMsgTtlMs

--- Full layout: 2 / 3 / 4 equal columns from current line width (same right edge per row).
local function fullColumnWidths()
    local avail = ImGui.GetContentRegionAvail()
    local sp = ImGui.GetStyle().ItemSpacing.x
    local minW = 80
    local w2 = math.max(minW, math.floor((avail - sp) / 2))
    local w3 = math.max(minW, math.floor((avail - sp * 2) / 3))
    local w4 = math.max(minW, math.floor((avail - sp * 3) / 4))
    return w2, w3, w4, avail, sp
end

local function actionButton(label, cmd, r, g, b, tooltipText, btnW, btnH, onClick)
    local clicked
    if type(r) == 'string' then
        clicked = Ui.buttonVariant(label, r, btnW and btnW > 0 and btnW or nil, btnH or 0)
    elseif type(r) == 'table' then
        clicked = Ui.buttonRgb(label, r, btnW and btnW > 0 and btnW or nil, btnH or 0)
    elseif btnW and btnW > 0 then
        clicked = Ui.buttonRgb(label, { r, g, b }, btnW, btnH or 0)
    else
        clicked = Ui.buttonRgb(label, { r, g, b })
    end
    if clicked then
        if onClick then
            onClick()
        elseif cmd and cmd ~= '' then
            mq.cmd(cmd)
            local displayLabel = label:match('^(.-)##') or label
            TG.statusMessage = displayLabel .. ' sent.'
        end
    end
    if tooltipText then tip(tooltipText) end
    return clicked
end

--- Small help chip: runs `cmd` and shows title + command on hover.
local HELP_CHIP_W, HELP_CHIP_H = 40, 28

local function helpMacroChip(label, cmd, title, extraLine, chipW, chipH)
    chipW = chipW or HELP_CHIP_W
    chipH = chipH or HELP_CHIP_H
    if Ui.buttonVariant(label, 'secondaryButton', chipW, chipH) then mq.cmd(cmd) end
    if ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        ImGui.Text(title)
        ImGui.TextColored(0.5, 0.5, 0.55, 1, cmd)
        if extraLine and extraLine ~= '' then
            ImGui.PushTextWrapPos(ImGui.GetFontSize() * 28.0)
            ImGui.TextColored(0.45, 0.48, 0.52, 1, extraLine)
            ImGui.PopTextWrapPos()
        end
        ImGui.EndTooltip()
    end
end

local RULE_BTN_W = 92
--- Taller hit targets for Slim TurboKey (cursor tagging).
local SLIM_RULE_BTN_H = 36

--- Optional `btnW`: use -1 for full available width (Slim TurboKey column).
--- Optional `btnH`: override button height (Slim uses SLIM_RULE_BTN_H).
local function ruleButton(label, r, g, b, tooltipText, btnW, btnH)
    if type(r) == 'table' and type(g) == 'string' and type(b) == 'number' then
        btnH = tooltipText
        btnW = b
        tooltipText = g
    end
    btnW = btnW or RULE_BTN_W
    btnH = btnH or ACTION_BTN_H
    local rgb = type(r) == 'table' and r or { r, g, b }
    if Ui.buttonRgb(label, rgb, btnW, btnH) then applyTurboKeyRule(label) end
    if tooltipText then tip(tooltipText) end
end

local function turboConvertTooltip(dir, inConvertZone)
    ImGui.BeginTooltip()
    ImGui.PushTextWrapPos(ImGui.GetFontSize() * 30.0)
    ImGui.Text(dir)
    if inConvertZone then
        ImGui.TextColored(0.3, 1.0, 0.5, 1.0, 'In conversion zone')
    else
        ImGui.TextColored(1.0, 0.5, 0.3, 1.0, 'Requires PoK or Temple of Marr')
    end
    ImGui.PopTextWrapPos()
    ImGui.EndTooltip()
end

-- =========================================================
-- Help / print
-- =========================================================
local function printHelp()
    printf('\au<<< \ar---------- \atTurbo Commands \ar---------- \au>>>\ax')
    printf('\awVersion: \ag%s\aw  Command: \ag/lua run Turbo\aw  Purpose: TurboSuite hub\ax', TURBO_VERSION)
    printf('\aw \ax')
    printf('\at==== \aySUITE MAP \at====\ax')
    printf('\aw  \agTurboLoot.mac\ax — loot/sell/bank/tribute/destroy by INI rules\ax')
    printf('\aw  \ag/lua run Turbo\ax or \ag/mac Turbo\ax — auto-loot controller and looter picker\ax')
    printf('\aw  \agTurboKey.mac\ax — tag cursor item into turboloot.ini\ax')
    printf('\aw  \agTurboGive.mac\ax — share/collect/hand items and coin between characters\ax')
    printf('\aw \ax')
    printf('\at==== \ayLOOTER SELECTION \at====\ax')
    printf('\aw    \ag/lua run Turbo\ax \at[slim|full|mini]\ax — open GUI (optional layout; saved like \ayview\ax)\ax')
    printf('\aw    \ag/lua run Turbo cycle\ax — advance to next group member\ax')
    printf('\aw    \ag/lua run Turbo \atCharName\ax — set specific character as looter\ax')
    printf('\aw    \ac/lua run Turbo all\ax — toggle ALL-loot mode (everyone loots)\ax')
    printf('\aw \ax')
    printf('\at==== \ayTOGGLES \at====\ax')
    printf('\aw    \ag/lua run Turbo on\ax — enable auto-loot (sweeps existing corpses)\ax')
    printf('\aw    \ar/lua run Turbo off\ax — disable auto-loot (clears looter to NOBODY)\ax')
    printf('\aw    \ag/lua run Turbo toggle\ax \at[CharName]\ax — UI-style ON/OFF (keeps looter; optional name sets single looter)\ax')
    printf('\aw    \ay/lua run Turbo combatloot\ax — toggle looting during combat\ax')
    printf('\aw \ax')
    printf('\at==== \ayACTIONS \at====\ax')
    printf('\aw    \ao/lua run Turbo loot\ax — sweep nearby corpses now\ax')
    printf('\aw    \ay/lua run Turbo setup\ax \aw[\atFile.ini\aw] [\atlocal|driver|noreload\aw]\ax')
    printf('\aw      Patches E3 corpse hooks, queues \ag/e3reload\aw (~8s), syncs group via quiet \agTurbo setup hooksonly\aw.\ax')
    printf('\aw      Use \ay/lua run Turbo setup driver\ax \aw(alias: local) for this character only, no group sync.\ax')
    printf('\aw    \ay/lua run Turbo view\ax \atfull\ax|\atslim\ax|\atmini\ax')
    printf('\aw      GUI layout (saved to turbo_settings.lua); also saves looter, Turbo on, combat loot, ALL mode, radius, shared profile\ax')
    printf('\aw    \ay/lua run Turbo patcher\ax — launch TurboPatcher.exe (aliases: patch, update)\ax')
    printf('\aw    \ay/turbopatcher\ax — same, while Turbo is already running\ax')
    printf('\aw      \aoMissing exe opens the download page. Hub banner when a newer suite is on GitHub.\ax')
    printf('\aw    \ay/lua run Turbo doctor\ax — install scan + profile report (versions, files, INIs)\ax')
    printf('\aw    \ay%s\ax — same install report when the Turbo UI is already open\ax', TURBO_DOCTOR_BIND)
    printf('\aw    \ay/turbosnapshot\ax — active turboloot.ini settings, grouped + with descriptions\ax')
    printf('\aw \ax')
    printf('\at==== \ayOTHER TOOLS \at====\ax')
    printf('\aw    \ag/mac turboloot help\ax     \ag/mac turbogive help\ax     \ag/mac turbokey help\ax')
    printf('\aw \ax')
    printf('\aw  \aohttps://github.com/drel-git/TurboLoot\ax')
end

local function printTurboDoctor()
    local tag = '\at[TurboDoctor]\ax'
    local mqPath = mq.TLO.MacroQuest.Path() or ''
    local me = mq.TLO.Me.CleanName() or mq.TLO.Me.Name() or '?'
    collectGroupMembers()
    local profile = getActiveProfile()

    if TG.perCharProfile and me ~= '?' and TG.charProfiles[me] then
        profile = TG.charProfiles[me]
    end
    profile = cleanProfileName(profile) or 'turboloot.ini'

    local activePath, activeExists = resolveTurbolootIniPathForProfile(profile)
    local activeLower = activePath and activePath:lower() or ''

    printf('%s \au===== Turbo Doctor: install scan =====\ax', tag)
    printf('%s \awChar: \ag%s\aw | Lua: \ag%s %s\ax', tag, me, TURBO_HUB_NAME, TURBO_VERSION)
    printf('%s \awSelected profile: \ay%s\aw (%s)\ax', tag, profile,
        TG.perCharProfile and 'per-character' or 'shared')
    if activePath and activeExists then
        printf('%s \awActive INI: \ag%s\ax', tag, relativeMqPath(activePath, mqPath))
    elseif activePath then
        printf('%s \awActive INI: \arMISSING\aw \ay%s\ax', tag, relativeMqPath(activePath, mqPath))
    end
    local reviewSpecs = TG.getReviewJournalWatchSpecs and TG.getReviewJournalWatchSpecs() or {}
    if #reviewSpecs > 0 then
        printf('%s \awReview journals:\ax', tag)
        for _, spec in ipairs(reviewSpecs) do
            local who = (#(spec.looters or {}) > 0) and table.concat(spec.looters, ', ') or 'local UI'
            printf('%s   \aw%s\ax -> \ag%s\ax', tag, who, relativeMqPath(spec.path, mqPath))
        end
        printf('%s \at[\ayReview Health\at]\ax', tag)
        for _, spec in ipairs(reviewSpecs) do
            local who = (#(spec.looters or {}) > 0) and table.concat(spec.looters, ', ') or 'local UI'
            local enabled, settingLabel = TG.describeLogSkipListSetting(spec.iniPath)
            local skipState = enabled and ('\ag' .. settingLabel .. '\ax') or ('\ar' .. settingLabel .. '\ax')
            local journalState = fileExists(spec.path) and '\agpresent\ax' or '\aynot yet created\ax'
            printf('%s   \aw%s:\ax logSkipListForIni=%s \awjournal=\ax%s', tag, who, skipState, journalState)
        end
    end
    if mqPath ~= '' then
        local queuePath = (TG.skipQueue and TG.skipQueue.get_queue_path and TG.skipQueue.get_queue_path())
            or (mqPath .. '\\Config\\TurboLoot_skip_queue.ini')
        local queueStatePath = (TG.skipQueue and TG.skipQueue.get_state_path and TG.skipQueue.get_state_path())
            or (mqPath .. '\\Config\\turbo_skip_queue_state.lua')
        printf('%s \at[\ayReview Queue\at]\ax', tag)
        printf('%s   \awQueue:\ax %s \at%s\ax', tag,
            fileExists(queuePath) and '\agpresent\ax' or '\aynot yet created\ax',
            relativeMqPath(queuePath, mqPath))
        printf('%s   \awQueue state:\ax %s \at%s\ax', tag,
            fileExists(queueStatePath) and '\agpresent\ax' or '\aynot yet created\ax',
            relativeMqPath(queueStatePath, mqPath))
        printf('%s   \awRepair:\ax More -> Repair Skip Review clears journals, queue, and queue state; INI rules stay unchanged.\ax', tag)
    end

    local lootAll = getLootAllState()
    local currentLooter = getCurrentLooter()
    local multiMode = (not lootAll) and isMultiLootMode()
    local liveTurboRaw = mq.TLO.MQ2Mono.Query('e3,Turbo')() or ''
    local liveTurbo = TG.e3Bool(liveTurboRaw)
    local desiredTurbo = getTurboState()
    local savedTurbo = (TG.savedTurboOn == nil) and 'unset' or (TG.savedTurboOn and 'ON' or 'OFF')
    local liveLootAllRaw = mq.TLO.MQ2Mono.Query('e3,GrpLootAll')() or ''
    local liveLootAll = TG.e3Bool(liveLootAllRaw)
    local liveMainLooter = (TG.getLiveMainLooter and TG.getLiveMainLooter()) or 'NOBODY'
    local routeMode = mq.TLO.MQ2Mono.Query('e3,GrpLootMode')() or 'single'
    if routeMode == '' or routeMode == 'NULL' or routeMode:find('${', 1, true) then routeMode = 'single' end
    local routeSlots = {}
    for i = 1, MAX_MULTI_LOOTERS do
        local v = mq.TLO.MQ2Mono.Query('e3,GrpLoot' .. i)() or ''
        if v ~= '' and v ~= 'NULL' and v ~= 'NOBODY' then
            table.insert(routeSlots, v)
        end
    end
    local lootReady, lootReadyReason = TG.getLootReadiness(lootAll, multiMode, currentLooter, liveMainLooter)
    printf('%s \at[\ayRoute State\at]\ax', tag)
    printf('%s   \awTurbo:\ax desired=\ag%s\ax live=\ag%s\ax raw=\at%s\ax saved=\at%s\ax authoritative=\at%s\ax',
        tag, desiredTurbo and 'ON' or 'OFF', liveTurbo and 'ON' or 'OFF',
        tostring(liveTurboRaw ~= '' and liveTurboRaw or 'empty'), savedTurbo,
        TG.turboUiAuthoritative and 'yes' or 'no')
    printf('%s   \awLoot route:\ax ready=%s \awreason=\at%s\ax',
        tag, lootReady and '\agyes\ax' or '\arno\ax', lootReadyReason or '')
    printf('%s   \awMode vars:\ax uiAll=\ag%s\ax liveAll=\ag%s\ax routeMode=\ag%s\ax uiMulti=\ag%s\ax',
        tag, lootAll and 'ON' or 'OFF', liveLootAll and 'ON' or 'OFF',
        routeMode, multiMode and 'ON' or 'OFF')
    printf('%s   \awMain looter:\ax ui=\ag%s\ax live=\ag%s\ax selected=\at%s\ax default=\at%s\ax',
        tag, currentLooter or 'NOBODY', liveMainLooter or 'NOBODY',
        TG.selectedChar or '', TG.savedDefaultLooter or '')
    printf('%s \at[\ayActive Looters / INIs\at]\ax', tag)
    if lootAll then
        printf('%s   \awLoot mode:\ax \agALL\aw (%d group member%s)\ax', tag, #TG.members, #TG.members == 1 and '' or 's')
    elseif multiMode then
        printf('%s   \awLoot mode:\ax \agMULTI\aw (%d selected)\ax', tag, #getMultiLooters())
    elseif currentLooter and currentLooter ~= '' and currentLooter ~= 'NOBODY' then
        printf('%s   \awLoot mode:\ax \agSingle\aw -> \ag%s\ax', tag, currentLooter)
    else
        printf('%s   \awLoot mode:\ax \arNo active looter set.\ax', tag)
    end
    printf('%s   \awRoute vars:\ax mode=\ag%s\ax single=\ag%s\ax liveSingle=\ag%s\ax multi=\ag%s\ax', tag,
        routeMode, currentLooter, liveMainLooter, (#routeSlots > 0 and table.concat(routeSlots, ', ') or 'none'))
    printf('%s   \awINI mode:\ax %s\ax', tag, TG.perCharProfile and '\agper-character' or '\ayshared')
    if #TG.members > 0 then
        for _, name in ipairs(TG.members) do
            local willLoot = lootAll
                or (multiMode and TG.multiLooters[name])
                or ((not multiMode) and currentLooter and currentLooter ~= 'NOBODY' and name == currentLooter)
            local mark = willLoot and '\agLOOT' or '\atidle'
            local memberProfile = TG.perCharProfile and getProfileForMember(name) or profile
            printf('%s     %s\aw %-12s -> \ay%s\ax', tag, mark, name, memberProfile)
        end
    elseif currentLooter and currentLooter ~= '' and currentLooter ~= 'NOBODY' then
        printf('%s     \agLOOT\aw %-12s -> \ay%s\ax', tag, currentLooter,
            TG.perCharProfile and getProfileForMember(currentLooter) or profile)
    end

    if mqPath == '' then
        printf('%s \arMacroQuest path unavailable; cannot scan files.\ax', tag)
        return
    end

    local macroFiles = {
        { name = 'TurboLoot.mac', label = 'TurboLoot' },
        { name = 'Turbo.mac', label = 'Turbo Auto-Loot macro' },
        { name = 'TurboGive.mac', label = 'TurboGive' },
        { name = 'TurboKey.mac', label = 'TurboKey' },
        { name = 'turbo_xtar_heal.mac', label = 'XTanks helper' },
    }
    printf('%s \at[\ayFiles\at]\ax', tag)
    local missingCount = 0
    for _, item in ipairs(macroFiles) do
        local path = mqPath .. '\\Macros\\' .. item.name
        if fileExists(path) then
            printf('%s   \aw%s:\ax \ay%s\ax \agOK\ax \at%s\ax', tag, item.label, item.name, versionText(path))
        else
            missingCount = missingCount + 1
            printf('%s   \aw%s:\ax \ay%s\ax \arMISSING\ax', tag, item.label, item.name)
        end
    end

    local luaPath = mqPath .. '\\lua\\Turbo\\init.lua'
    if fileExists(luaPath) then
        printf('%s   \awLua UI:\ax \aylua\\Turbo\\init.lua\ax \agOK\ax \at%s\ax', tag, versionText(luaPath))
    else
        missingCount = missingCount + 1
        printf('%s   \awLua UI:\ax \aylua\\Turbo\\init.lua\ax \arMISSING\ax', tag)
    end
    local reclaimLottoLuaPath = mqPath .. '\\lua\\turbo_reclaim_lotto.lua'
    if fileExists(reclaimLottoLuaPath) then
        printf('%s   \awReclaim/Lotto helper:\ax \aylua\\turbo_reclaim_lotto.lua\ax \agOK\ax \at%s\ax', tag, versionText(reclaimLottoLuaPath))
    else
        missingCount = missingCount + 1
        printf('%s   \awReclaim/Lotto helper:\ax \aylua\\turbo_reclaim_lotto.lua\ax \arMISSING\ax', tag)
    end
    local collectDcLuaPath = mqPath .. '\\lua\\turbo_collect_dc.lua'
    if fileExists(collectDcLuaPath) then
        printf('%s   \awCollect DC helper:\ax \aylua\\turbo_collect_dc.lua\ax \agOK\ax \at%s\ax', tag, versionText(collectDcLuaPath))
    else
        missingCount = missingCount + 1
        printf('%s   \awCollect DC helper:\ax \aylua\\turbo_collect_dc.lua\ax \arMISSING\ax', tag)
    end
    local skipLogPath = mqPath .. '\\lua\\Turbo\\skip_log.lua'
    if fileExists(skipLogPath) then
        printf('%s   \awSkip journal:\ax \aylua\\Turbo\\skip_log.lua\ax \agOK\ax', tag)
    else
        missingCount = missingCount + 1
        printf('%s   \awSkip journal:\ax \aylua\\Turbo\\skip_log.lua\ax \arMISSING\ax \aw(Skip Review / skips log need this file)\ax', tag)
    end
    local skipAppendPath = mqPath .. '\\lua\\Turbo\\skip_append.lua'
    if fileExists(skipAppendPath) then
        printf('%s   \awSkip batch flush:\ax \aylua\\Turbo\\skip_append.lua\ax \agOK\ax', tag)
    else
        missingCount = missingCount + 1
        printf('%s   \awSkip batch flush:\ax \aylua\\Turbo\\skip_append.lua\ax \arMISSING\ax \aw(queued skip rows will not reach Review)\ax', tag)
    end
    local skipQueuePath = mqPath .. '\\lua\\Turbo\\skip_queue.lua'
    if fileExists(skipQueuePath) then
        printf('%s   \awSkip queue drain:\ax \aylua\\Turbo\\skip_queue.lua\ax \agOK\ax', tag)
    else
        missingCount = missingCount + 1
        printf('%s   \awSkip queue drain:\ax \aylua\\Turbo\\skip_queue.lua\ax \arMISSING\ax \aw(queue-backed skip transport unavailable)\ax', tag)
    end
    local skipDaemon = mqPath .. '\\lua\\Turbo\\skip_journal_daemon.lua'
    if fileExists(skipDaemon) then
        printf('%s   \awSkip listener (optional):\ax \aylua\\Turbo\\skip_journal_daemon.lua\ax \agOK\ax \at— use if you loot without Turbo GUI open\ax', tag)
    end
    if missingCount == 0 then
        printf('%s \at[\ayInstall\at]\ax \agall expected files found.\ax', tag)
    else
        printf('%s \at[\ayInstall\at]\ax \ar%d expected file(s) missing.\ax', tag, missingCount)
    end

    local folders = {
        { label = 'Config', dir = mqPath .. '\\Config' },
        { label = 'Macros', dir = mqPath .. '\\Macros' },
    }
    printf('%s \at[\ayProfiles\at]\ax', tag)
    for _, folder in ipairs(folders) do
        local inis = listTurbolootInisInFolder(folder.dir)
        if #inis == 0 then
            printf('%s   \aw%s:\ax \atnone\ax', tag, folder.label)
        else
            printf('%s   \aw%s:\ax', tag, folder.label)
            for _, name in ipairs(inis) do
                local full = folder.dir .. '\\' .. name
                local mark = (full:lower() == activeLower)
                    and string.format('\agACTIVE for %s', me)
                    or '\atavailable'
                printf('%s     \ay%s\ax \at%s\ax %s\ax', tag, name, versionText(full), mark)
            end
        end
    end

    if activePath and activeExists then
        -- v3.8.52: Active INI settings moved to /turbosnapshot, which now
        -- shows grouped values WITH descriptions (what each setting does).
        -- Doctor stays focused on install health + routing; snapshot owns
        -- "what does my INI say". One concept per command.
        printf('%s \at[\ayActive INI Settings\at]\ax  \aw->\ax \ay/turbosnapshot\ax  \aw(or More -> INI Snapshot)\ax', tag)
    end
    printf('%s \au===== Doctor complete: read-only, no changes made. =====\ax', tag)
end

-- Forward declarations so bindTurboRuntimeCommands can reference these
-- before their full definitions (which depend on SKIP_EVENT_NAME and onSkipBroadcast).
-- rebuildSkipDisplayRows must be forward-declared too: otherwise Lua resolves it as a
-- global inside bindTurboRuntimeCommands (defined above the local function).
local registerSkipListener, unregisterSkipListener, rebuildSkipDisplayRows

local function bindTurboRuntimeCommands()
    local ok, err = pcall(function()
        mq.bind(TURBO_DOCTOR_BIND, function()
            printTurboDoctor()
        end)
    end)
    TG.doctorBindActive = ok
    if not ok then
        printf('\at[Turbo]\ax \ayCould not bind %s: %s\ax', TURBO_DOCTOR_BIND, tostring(err))
    end
    -- v3.8.52: /turbosnapshot — grouped active-INI dump with descriptions.
    -- Doctor lost its [Active INI Settings] block in 3.8.52; this is the
    -- canonical "what does my INI say + what does each setting mean" output.
    local okSnap, errSnap = pcall(function()
        mq.bind('/turbosnapshot', function()
            TG.printTurboSnapshot()
        end)
    end)
    TG.snapshotBindActive = okSnap
    if not okSnap then
        printf('\at[Turbo]\ax \ayCould not bind /turbosnapshot: %s\ax', tostring(errSnap))
    end
    -- /turbopatcher: launch TurboPatcher.exe while Turbo is running. The CLI form
    -- (/lua run Turbo patcher) only works when Turbo is NOT running, because MQ
    -- refuses to start a script that is already loaded.
    local okPatcher, errPatcher = pcall(function()
        mq.bind('/turbopatcher', function()
            TG.openTurboPatcherExternal()
            printf('\at[Turbo]\ax %s', tostring(TG.statusMessage or ''))
        end)
    end)
    TG.patcherBindActive = okPatcher
    if not okPatcher then
        printf('\at[Turbo]\ax \ayCould not bind /turbopatcher: %s\ax', tostring(errPatcher))
    end
    local okMain, errMain = pcall(function()
        mq.bind('/turbomain', function()
            TG.windowOpen = not TG.windowOpen
            if TG.windowOpen then
                TG.minimizedGUI = false
                TG.slimGUI = false
                TG.slimWhenExpanded = false
                TG.statusMessage = 'Turbo opened.'
            end
        end)
    end)
    TG.mainBindActive = okMain
    if not okMain then
        printf('\at[Turbo]\ax \ayCould not bind /turbomain: %s\ax', tostring(errMain))
    end
    local okFocus, errFocus = pcall(function()
        mq.bind('/turbofocus', function()
            TG.windowOpen = true
            TG.minimizedGUI = false
            TG.slimGUI = false
            TG.slimWhenExpanded = false
            TG.statusMessage = 'Turbo opened.'
        end)
    end)
    TG.focusBindActive = okFocus
    if not okFocus then
        printf('\at[Turbo]\ax \ayCould not bind /turbofocus: %s\ax', tostring(errFocus))
    end
    local okSetupTab, errSetupTab = pcall(function()
        mq.bind('/turbosetup', function()
            TG.windowOpen = true
            TG.minimizedGUI = false
            TG.slimGUI = false
            TG.slimWhenExpanded = false
            TG.activeTab = 'setup'
            TG.lastRelevantTab = 'setup'
            TG.lootManagerPage = 'setup'
            TG.statusMessage = 'Setup opened.'
        end)
    end)
    TG.setupTabBindActive = okSetupTab
    if not okSetupTab then
        printf('\at[Turbo]\ax \ayCould not bind /turbosetup: %s\ax', tostring(errSetupTab))
    end
    local okE3Setup, errE3Setup = pcall(function()
        mq.bind('/turboe3setup', function()
            doLuaSetup(nil, nil, { mode = 'full' })
            TG.statusMessage = 'E3 setup complete. Recheck Quick Start when ready.'
        end)
    end)
    TG.e3SetupBindActive = okE3Setup
    if not okE3Setup then
        printf('\at[Turbo]\ax \ayCould not bind /turboe3setup: %s\ax', tostring(errE3Setup))
    end
    local okGainsWin, errGainsWin = pcall(function()
        mq.bind('/turbogainswin', function()
            TG.gainsWindowOpen = not TG.gainsWindowOpen
            if TG.gainsWindowOpen then
                TG.gainsWindowOpenReason = '/turbogainswin'
                TG.gainsWindowOpenAt = os.time()
            end
            TG.windowOpen = true
            TG.minimizedGUI = false
            TG.slimGUI = false
            TG.slimWhenExpanded = false
            TG.statusMessage = TG.gainsWindowOpen and 'Turbo Gains opened.' or 'Turbo Gains hidden.'
            saveSettings()
        end)
    end)
    TG.gainsWinBindActive = okGainsWin
    if not okGainsWin then
        printf('\at[Turbo]\ax \ayCould not bind /turbogainswin: %s\ax', tostring(errGainsWin))
    end
    local okGainsOpen, errGainsOpen = pcall(function()
        mq.bind('/turbogainsopen', function()
            TG.openTurboGainsWindow('/turbogainsopen')
            TG.windowOpen = true
            TG.minimizedGUI = false
            TG.slimGUI = false
            TG.slimWhenExpanded = false
            TG.statusMessage = 'Turbo Gains opened.'
            saveSettings()
        end)
    end)
    TG.gainsOpenBindActive = okGainsOpen
    if not okGainsOpen then
        printf('\at[Turbo]\ax \ayCould not bind /turbogainsopen: %s\ax', tostring(errGainsOpen))
    end
    local okRulePacks, errRulePacks = pcall(function()
        mq.bind('/turborulepacks', function()
            local isOpen = TG.reviewWindowOpen and TG.reviewSubPage == 'rulepacks'
            if isOpen then
                TG.reviewWindowOpen = false
                TG.skipReviewOpen = false
                TG.statusMessage = 'Rule Packs closed.'
                return
            end
            TG.windowOpen = true
            TG.minimizedGUI = false
            TG.slimGUI = false
            TG.slimWhenExpanded = false
            TG.activeTab = 'review'
            TG.reviewWindowOpen = true
            TG.skipReviewOpen = true
            TG.reviewSubPage = 'rulepacks'
            TG.rulePacksWindowOpen = false
            TG.rulePackBrowserNeedsManualLoad = false
            TG.statusMessage = 'Rule Packs opened.'
        end)
    end)
    TG.rulePacksBindActive = okRulePacks
    if not okRulePacks then
        printf('\at[Turbo]\ax \ayCould not bind /turborulepacks: %s\ax', tostring(errRulePacks))
    end
    local okSettings, errSettings = pcall(function()
        mq.bind('/turbosettings', function()
            if TG.tlSettingsWindowOpen then
                TG.tlSettingsWindowOpen = false
                TG.statusMessage = 'Turbo INI Config closed.'
                return
            end
            TG.windowOpen = true
            TG.minimizedGUI = false
            TG.slimGUI = false
            TG.slimWhenExpanded = false
            TG.tlSettingsWindowOpen = true
            TG.statusMessage = 'Turbo INI Config opened.'
        end)
    end)
    TG.settingsBindActive = okSettings
    if not okSettings then
        printf('\at[Turbo]\ax \ayCould not bind /turbosettings: %s\ax', tostring(errSettings))
    end
    local okTools, errTools = pcall(function()
        mq.bind('/turbotools', function()
            local isOpen = TG.windowOpen and not TG.minimizedGUI and not TG.slimGUI and TG.activeTab == 'tools'
            if isOpen then
                TG.windowOpen = false
                TG.statusMessage = 'More closed.'
                return
            end
            TG.windowOpen = true
            TG.minimizedGUI = false
            TG.slimGUI = false
            TG.slimWhenExpanded = false
            TG.activeTab = 'tools'
            TG.statusMessage = 'More opened.'
        end)
    end)
    TG.toolsBindActive = okTools
    if not okTools then
        printf('\at[Turbo]\ax \ayCould not bind /turbotools: %s\ax', tostring(errTools))
    end
    local okReview, errReview = pcall(function()
        mq.bind('/turboreview', function()
            local isOpen = TG.reviewWindowOpen and TG.reviewSubPage == 'review'
            if isOpen then
                TG.reviewWindowOpen = false
                TG.skipReviewOpen = false
                TG.statusMessage = 'Review closed.'
                return
            end
            TG.windowOpen = true
            TG.minimizedGUI = false
            TG.slimGUI = false
            TG.slimWhenExpanded = false
            TG.activeTab = 'review'
            TG.reviewWindowOpen = true
            TG.skipReviewOpen = true
            TG.reviewSubPage = 'review'
            TG.statusMessage = 'Review opened.'
        end)
    end)
    TG.reviewBindActive = okReview
    if not okReview then
        printf('\at[Turbo]\ax \ayCould not bind /turboreview: %s\ax', tostring(errReview))
    end
    local okWares, errWares = pcall(function()
        mq.bind('/turbowares', function()
            TG.waresAutoShow = not (TG.waresAutoShow ~= false)
            if TG.waresAutoShow then
                TG.waresWindowOpen = true
            end
            TG.statusMessage = TG.waresAutoShow
                and 'TurboWares enabled at merchants.'
                or 'TurboWares disabled at merchants.'
            saveSettings()
        end)
    end)
    TG.waresBindActive = okWares
    if not okWares then
        printf('\at[Turbo]\ax \ayCould not bind /turbowares: %s\ax', tostring(errWares))
    end
    -- Review auto-clear after successful Go loot (local echo + TurboGear relay).
    local okReviewGo, errReviewGo = pcall(function()
        mq.bind('/turboreviewgoloot', function(...)
            local args = { ... }
            local note = tostring(args[1] or ''):lower()
            if note ~= 'looted' and note ~= 'ok' and note ~= 'success' then return end
            -- /turboreviewgoloot looted <corpseId> <item name...>
            local start = 2
            if tonumber(args[2]) then start = 3 end
            local itemName = table.concat(args, ' ', start):match('^%s*(.-)%s*$') or ''
            TG.dismissReviewAfterGoLoot(itemName)
        end)
    end)
    TG.reviewGoLootBindActive = okReviewGo
    if not okReviewGo then
        printf('\at[Turbo]\ax \ayCould not bind /turboreviewgoloot: %s\ax', tostring(errReviewGo))
    end
    registerSkipListener()
end

local function unbindTurboRuntimeCommands()
    if TG.doctorBindActive then
        pcall(function() mq.unbind(TURBO_DOCTOR_BIND) end)
        TG.doctorBindActive = false
    end
    if TG.snapshotBindActive then
        pcall(function() mq.unbind('/turbosnapshot') end)
        TG.snapshotBindActive = false
    end
    if TG.patcherBindActive then
        pcall(function() mq.unbind('/turbopatcher') end)
        TG.patcherBindActive = false
    end
    if TG.mainBindActive then
        pcall(function() mq.unbind('/turbomain') end)
        TG.mainBindActive = false
    end
    if TG.focusBindActive then
        pcall(function() mq.unbind('/turbofocus') end)
        TG.focusBindActive = false
    end
    if TG.setupTabBindActive then
        pcall(function() mq.unbind('/turbosetup') end)
        TG.setupTabBindActive = false
    end
    if TG.e3SetupBindActive then
        pcall(function() mq.unbind('/turboe3setup') end)
        TG.e3SetupBindActive = false
    end
    if TG.gainsWinBindActive then
        pcall(function() mq.unbind('/turbogainswin') end)
        TG.gainsWinBindActive = false
    end
    if TG.gainsOpenBindActive then
        pcall(function() mq.unbind('/turbogainsopen') end)
        TG.gainsOpenBindActive = false
    end
    if TG.rulePacksBindActive then
        pcall(function() mq.unbind('/turborulepacks') end)
        TG.rulePacksBindActive = false
    end
    if TG.settingsBindActive then
        pcall(function() mq.unbind('/turbosettings') end)
        TG.settingsBindActive = false
    end
    if TG.toolsBindActive then
        pcall(function() mq.unbind('/turbotools') end)
        TG.toolsBindActive = false
    end
    if TG.reviewBindActive then
        pcall(function() mq.unbind('/turboreview') end)
        TG.reviewBindActive = false
    end
    if TG.waresBindActive then
        pcall(function() mq.unbind('/turbowares') end)
        TG.waresBindActive = false
    end
    if TG.reviewGoLootBindActive then
        pcall(function() mq.unbind('/turboreviewgoloot') end)
        TG.reviewGoLootBindActive = false
    end
    if TG.goLootReviewEventActive then
        pcall(function() mq.unevent('TurboReviewGoLootEcho') end)
        TG.goLootReviewEventActive = false
    end
    unregisterSkipListener()
end

--- TurboGive /mac help is very long; split for chat readability (full: /mac turbogive help).
local function printTurboGiveHelp1()
    printf('\au<<< \ar---------- \atTurboGive Commands \ag(1/2) \at— Give / Distribute / Hand \ar---------- \au>>>\ax')
    printf('\awFull macro version + output: \ag/mac turbogive help\ax')
    printf('\aw \ax')
    printf('\at==== \ayGETTING STARTED \at====\ax')
    printf('\aw  \ag1)\ax Target a PC, item on cursor: \ag/mac turbogive add\ax or \ag/mac turbogive add target\ax')
    printf('\aw  \ag2)\ax Distribute: \ag/mac turbogive\ax — you + each bot gives assigned items to the group\ax')
    printf('\aw \ax')
    printf('\at==== \ayDISTRIBUTE \at====\ax')
    printf('\aw    \ag/mac turbogive\ax — default: everyone gives per give-list\ax')
    printf('\aw    \ag/mac turbogive solo\ax — only you give (no broadcast)\ax')
    printf('\aw    \ag/mac turbogive solo all\ax — only you, everyone in zone\ax')
    printf('\aw    \ag/mac turbogive all\ax — you + bots, everyone in zone\ax')
    printf('\aw    \ag/mac turbogive \atCHARNAME\ax — give your items to one character\ax')
    printf('\aw    \ag/mac turbogive tell \atCHARNAME\ax — tell one bot to give theirs\ax')
    printf('\aw \ax')
    printf('\at==== \ayHAND OUT \at====\ax')
    printf('\aw    \ag/mac turbogive hand \atCOUNT\ax — cursor item: COUNT to each person\ax')
    printf('\aw    \ag/mac turbogive hand \atCOUNT ItemName\ax — named item from inventory\ax')
    printf('\aw    \ag/mac turbogive hand \atCOUNT ItemName\ag all\ax — all bots in zone\ax')
    printf('\aw    \ag/mac turbogive hand tell \atCHARNAME COUNT ItemName\ax \aw[\agall\aw]\ax')
    printf('\aw      tell a bot to hand from their bags\ax')
    printf('\aw \ax')
    printf('\at==== \ayQUANTITY LIMITS \at====\ax')
    printf('\aw    \ag/mac turbogive \atCHARNAME 5\ax — give up to 5 items to that character\ax')
    printf('\aw    \ag/mac turbogive collect 5\ax — collect up to 5 items total\ax')
    printf('\aw \ax')
    printf('\aw  \aohttps://github.com/drel-git/TurboLoot\ax')
end

local function printTurboGiveHelp2()
    printf('\au<<< \ar---------- \atTurboGive Commands \ao(2/2) \at— Collect / Bank / Cash / Setup \ar---------- \au>>>\ax')
    printf('\awFull macro version + output: \ag/mac turbogive help\ax')
    printf('\aw \ax')
    printf('\at==== \ayCOLLECT \at====\ax')
    printf('\aw    \ag/mac turbogive collect\ax — group sends you your assigned items\ax')
    printf('\aw    \ag/mac turbogive collect all\ax / \agcollect raid\ax — all bots in zone\ax')
    printf('\aw    \ag/mac turbogive collect tell \atCHARNAME\ax \aw[\agall\aw]\ax — tell one toon to collect\ax')
    printf('\aw \ax')
    printf('\at==== \ayBANK \at====\ax')
    printf('\aw    \ag/mac turbogive bank\ax / \agbank all\ax — others pull from bank (caller does not)\ax')
    printf('\aw    \ag/mac turbogive bank solo\ax — you pull your own assigned items\ax')
    printf('\aw    \ag/mac turbogive bank pull\ax — you pull others items from your bank\ax')
    printf('\aw    \ag/mac turbogive bank \atCHARNAME\ax — pull that toon\'s items into your bags\ax')
    printf('\aw    \ag/mac turbogive bank tell \atCHARNAME\ax — tell them to pull theirs\ax')
    printf('\aw \ax')
    printf('\at==== \ayCASH / DC / CONVERT \at====\ax')
    printf('\aw    \ag/mac turbogive collect cash\ax \aw[\atamount\aw]\ax \aw[\agall\aw]\ax — coin from group\ax')
    printf('\aw    \ag/mac turbogive collect dc\ax \aw[\atamount\aw]\ax \aw[\agall\aw]\ax — Diamond Coins\ax')
    printf('\aw    \ag/mac turbogive \atCHARNAME\ag cash\ax / \ag\atCHARNAME\ag dc\ax — give coin/DC to target\ax')
    printf('\aw    \ag/mac turbogive convert aa\ax / \agconvert dc\ax — PoK / Temple of Marr NPC\ax')
    printf('\aw    \ag/mac turbogive convert exchange\ax / \agconvert all\ax — alt-currency / group broadcast\ax')
    printf('\aw \ax')
    printf('\at==== \ayNPC HAND-IN \at====\ax')
    printf('\aw    \ag/mac turbogive handin \at"Item"\ax \aw[\at#\aw]\ax \aw[\agdestroy\aw]\ax — to targeted NPC\ax')
    printf('\aw    \ag/mac turbogive handin pp\ax|\agsp\ax|\aggp\ax|\agcp\ax \at#\ax — coin to NPC\ax')
    printf('\aw    \ag/mac turbogive handin tell \atCHARNAME\ag "Item"\ax \aw[\at#\aw]\ax — tell bot to hand in\ax')
    printf('\aw \ax')
    printf('\at==== \aySETUP \at====\ax')
    printf('\aw    \ag/mac turbogive add\ax / \aglist\ax / \agstatus\ax / \aghelp\ax')
    printf('\aw \ax')
    printf('\at==== \ayINI (summary) \at====\ax')
    printf('\aw    \at[GiveList]\ax — item -> character, optional quantity cap; \at_prefix1\ax, \at_wildcards\ax, etc.\ax')
    printf('\aw    \at[GiveExclude]\ax — \at_list=Name,Name\ax excludes toons from wildcard rules\ax')
    printf('\aw \ax')
    printf('\aw  \aohttps://github.com/drel-git/TurboLoot\ax')
end

--- Help chip that runs a Lua callback instead of /mac (same look as helpMacroChip).
local function helpCallbackChip(label, onClick, title, extraLine, chipW, chipH)
    chipW = chipW or HELP_CHIP_W
    chipH = chipH or HELP_CHIP_H
    if Ui.buttonVariant(label, 'secondaryButton', chipW, chipH) then onClick() end
    if ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        ImGui.Text(title)
        if extraLine and extraLine ~= '' then
            ImGui.PushTextWrapPos(ImGui.GetFontSize() * 28.0)
            ImGui.TextColored(0.45, 0.48, 0.52, 1, extraLine)
            ImGui.PopTextWrapPos()
        end
        ImGui.EndTooltip()
    end
end

-- Bind ImGui callback deps once; renderWindow only closes over TG (LuaJIT upvalue limit).
TG.ensureE3Vars = ensureE3Vars
TG.nowMS = nowMS
TG.collectGroupMembers = collectGroupMembers
TG.getCurrentLooter = getCurrentLooter
TG.getProfileForMember = getProfileForMember
TG.getTurboState = getTurboState
TG.getCombatLootState = getCombatLootState
TG.getLootAllState = getLootAllState
TG.getMultiLooters = getMultiLooters
TG.isMultiLootMode = isMultiLootMode
TG.toggleMultiLooter = toggleMultiLooter
TG.sendMultiLootCommands = sendMultiLootCommands
TG.getNearbyCorpseCount = getNearbyCorpseCount
TG.setTurboCache = setTurboCache
TG.cycleToNext = cycleToNext
TG.setLooter = setLooter
TG.toggleLootAll = toggleLootAll
TG.toggleCombatLoot = toggleCombatLoot
TG.lootNow = lootNow
TG.setLootRadius = setLootRadius
TG.saveSettings = saveSettings
TG.saveCharProfiles = saveCharProfiles
TG.getActiveProfile = getActiveProfile
TG.setActiveProfile = setActiveProfile
TG.syncProfileAssignments = syncProfileAssignments
TG.scanTurbolootProfiles = scanTurbolootProfiles
TG.rescanProfiles = rescanProfiles
TG.ensureProfileCacheSeeded = TG.ensureProfileCacheSeeded
TG.applyTurboKeyRule = applyTurboKeyRule
-- TG.getTurboLootSettingsSummaryLines / .printTurboSnapshot are set in the
-- snapshot do-end block above (around line ~1435); no re-export needed here.
TG.tip = tip
TG.coloredSep = coloredSep
TG.thinSep = thinSep
TG.toggleSwitch = toggleSwitch
TG.actionButton = actionButton
TG.helpMacroChip = helpMacroChip
TG.helpCallbackChip = helpCallbackChip
TG.printTurboGiveHelp1 = printTurboGiveHelp1
TG.printTurboGiveHelp2 = printTurboGiveHelp2
TG.ruleButton = ruleButton
TG.turboConvertTooltip = turboConvertTooltip
TG.printHelp = printHelp
TG.Colors = Colors
TG.AUTO_REFRESH_MS = AUTO_REFRESH_MS
TG.DEFAULT_LOOT_RADIUS = DEFAULT_LOOT_RADIUS
TG.TURBO_VERSION = TURBO_VERSION
TG.TURBO_HUB_NAME = TURBO_HUB_NAME
TG.TURBO_URL = TURBO_URL
TG.ACTION_BTN_W = ACTION_BTN_W
TG.ACTION_BTN_H = ACTION_BTN_H
TG.RULE_BTN_W = RULE_BTN_W
TG.SLIM_RULE_BTN_H = SLIM_RULE_BTN_H
TG.LAYOUT_MODE_BTN_W = LAYOUT_MODE_BTN_W
TG.LAYOUT_MODE_BTN_H = LAYOUT_MODE_BTN_H
TG.HELP_CHIP_W = HELP_CHIP_W
TG.HELP_CHIP_H = HELP_CHIP_H
TG.ui = Ui

-- =========================================================
-- Shared Tools popup body (3.8.29)
-- Rendered inside whichever ImGui window scope opened the popup — Mini or Full.
-- Before 3.8.29, the body lived only in Full's render scope, so /lua run Turbo
-- in Mini mode fired OpenPopup but had no BeginPopup to display it.
-- =========================================================
TG.renderHelpPopupBody = function(g)
    local function sectionHeader(text, r, gb, b)
        ImGui.PushTextWrapPos(ImGui.GetFontSize() * 34.0)
        ImGui.TextColored(r, gb, b, 1.0, text)
        ImGui.PopTextWrapPos()
    end

    sectionHeader('Commands', 0.58, 0.68, 0.86)
    if ImGui.Selectable('TurboLoot Commands##st1') then
        mq.cmd('/mac turboloot help')
        ImGui.CloseCurrentPopup()
    end
    if ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        ImGui.PushTextWrapPos(ImGui.GetFontSize() * 30.0)
        ImGui.Text('For: running TurboLoot on corpses, merchants, banking, and item rules.')
        ImGui.TextColored(0.45, 0.48, 0.52, 1, 'Runs /mac turboloot help (full command list in chat).')
        ImGui.PopTextWrapPos()
        ImGui.EndTooltip()
    end
    if ImGui.Selectable('TurboGive Commands 1/2##st2') then
        printTurboGiveHelp1()
        ImGui.CloseCurrentPopup()
    end
    if ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        ImGui.PushTextWrapPos(ImGui.GetFontSize() * 30.0)
        ImGui.Text('For: give-lists, /mac turbogive to pass items around, and hand counts per member.')
        ImGui.TextColored(0.45, 0.48, 0.52, 1, 'Part 1 of 2. Full macro: /mac turbogive help')
        ImGui.PopTextWrapPos()
        ImGui.EndTooltip()
    end
    if ImGui.Selectable('TurboGive Commands 2/2##st3') then
        printTurboGiveHelp2()
        ImGui.CloseCurrentPopup()
    end
    if ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        ImGui.PushTextWrapPos(ImGui.GetFontSize() * 30.0)
        ImGui.Text('For: pulling your items from others, bank routines, plat/Diamond Coins, converts, NPC turn-ins, give-list INI.')
        ImGui.TextColored(0.45, 0.48, 0.52, 1, 'Part 2 of 2. Same full /mac turbogive help in game.')
        ImGui.PopTextWrapPos()
        ImGui.EndTooltip()
    end
    if ImGui.Selectable('TurboKey Commands##st4') then
        mq.cmd('/mac turbokey help')
        ImGui.CloseCurrentPopup()
    end
    if ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        ImGui.PushTextWrapPos(ImGui.GetFontSize() * 30.0)
        ImGui.Text('For: keyboard/macro shortcuts to set loot rules from inventory or cursor.')
        ImGui.TextColored(0.45, 0.48, 0.52, 1, 'Runs /mac turbokey help.')
        ImGui.PopTextWrapPos()
        ImGui.EndTooltip()
    end
    if ImGui.Selectable('Turbo Window Commands##st5') then
        printHelp()
        ImGui.CloseCurrentPopup()
    end
    if ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        ImGui.PushTextWrapPos(ImGui.GetFontSize() * 30.0)
        ImGui.Text('For: group looter, active INI profiles, auto-loot on/off, combat loot, /loot sweep, E3 setup, Full/Slim/Mini.')
        ImGui.TextColored(0.45, 0.48, 0.52, 1, 'Lua printHelp() to chat (no /mac).')
        ImGui.PopTextWrapPos()
        ImGui.EndTooltip()
    end
end

-- =========================================================
local function renderToolsPopupBody(g)
    local function sectionHeader(text, r, gb, b)
        ImGui.PushTextWrapPos(ImGui.GetFontSize() * 34.0)
        ImGui.TextColored(r, gb, b, 1.0, text)
        ImGui.PopTextWrapPos()
    end

    local function coloredSelectable(label, color)
        if color then
            ImGui.PushStyleColor(ImGuiCol.Text, IM_COL32(color[1], color[2], color[3], 255))
        end
        local clicked = ImGui.Selectable(label)
        if color then ImGui.PopStyleColor(1) end
        return clicked
    end

    sectionHeader('Actions', 0.82, 0.70, 0.38)
    local logOnLbl = 'File Log: ON##stlog'
    local logOffLbl = 'File Log: OFF##stlog'
    if coloredSelectable(g.logFileOn and logOnLbl or logOffLbl, g.logFileOn and {95, 185, 110} or {175, 118, 90}) then
        g.logFileOn = not g.logFileOn
        mq.cmdf('/squelch /varset logToFile %s', g.logFileOn and 'TRUE' or 'FALSE')
        g.statusMessage = g.logFileOn and 'File logging ON (when TurboLoot runs)' or 'File logging OFF'
        saveSettings()
        ImGui.CloseCurrentPopup()
    end
    if ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        ImGui.Text('Sets MQ logToFile for TurboLoot runs (MacroQuest Logs). Not the same as logSkipListForIni (session .txt in Config).')
        ImGui.EndTooltip()
    end
    if ImGui.Selectable('INI Snapshot##stcfg') then
        TG.printTurboSnapshot()
        ImGui.CloseCurrentPopup()
    end
    if ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        ImGui.PushTextWrapPos(ImGui.GetFontSize() * 28.0)
        ImGui.Text('Active turboloot.ini [Settings] grouped by category, with descriptions of what each setting does. Same output as /turbosnapshot.')
        ImGui.PopTextWrapPos()
        ImGui.EndTooltip()
    end
    if coloredSelectable('Open Skip Journal##stskiplog', {110, 170, 125}) then
        TG.openSkipJournalExternal()
        ImGui.CloseCurrentPopup()
    end
    if ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        ImGui.PushTextWrapPos(ImGui.GetFontSize() * 30.0)
        ImGui.Text('Open TurboLoot_skips_log.txt for the active profile.')
        ImGui.TextColored(0.45, 0.48, 0.52, 1, 'Created after the first skipped item is logged. Same folder as the active turboloot INI.')
        ImGui.PopTextWrapPos()
        ImGui.EndTooltip()
    end
    if coloredSelectable('Repair Skip Review##stskipreset', {185, 120, 75}) then
        ImGui.OpenPopup('Confirm Repair Skip Review')
    end
    if ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        ImGui.PushTextWrapPos(ImGui.GetFontSize() * 30.0)
        ImGui.Text('Clear stale Skip Review counts/state, queue state, queue file, and watched journals.')
        ImGui.TextColored(0.75, 0.55, 0.35, 1, 'Item rules in turboloot.ini are not changed. New skips will rebuild fresh.')
        ImGui.PopTextWrapPos()
        ImGui.EndTooltip()
    end
    if ImGui.BeginPopupModal('Confirm Repair Skip Review') then
        ImGui.Text('Repair Skip Review')
        ImGui.Separator()
        ImGui.Text('This clears Turbo skip-review state, queue state, queue file, and watched skip journals.')
        ImGui.Text('Existing INI rules are not changed.')
        ImGui.Dummy(0, 6)
        if ImGui.Button('Repair##skip_review_reset_confirm', 118, 0) then
            if TG.repairSkipReviewData then TG.repairSkipReviewData(g) end
            ImGui.CloseCurrentPopup()
        end
        ImGui.SameLine()
        if ImGui.Button('Cancel##skip_review_reset_cancel', 118, 0) then
            ImGui.CloseCurrentPopup()
        end
        ImGui.EndPopup()
    end
    --- 3.8.55: Symbol turn-ins selectable removed from this popup.
    --- It is now a primary action button next to Reclaim + Lotto in the Actions
    --- tab (see actions.lua 1.1.3). PoK/Tower turn-ins are a routine end-of-loop
    --- workflow, not a one-off tool, so they belong with the other action buttons.
    ImGui.Separator()
    sectionHeader('Backups', 0.70, 0.74, 0.92)
    if ImGui.Selectable('Backup Active TurboLoot INI##backup_turbo_ini') then
        local backupPath, err = TG.backupActiveTurbolootIni()
        g.statusMessage = TG.backupStatusMessage('TurboLoot INI', backupPath, err)
        ImGui.CloseCurrentPopup()
    end
    if ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        ImGui.PushTextWrapPos(ImGui.GetFontSize() * 30.0)
        ImGui.Text('Creates a timestamped .bak next to the active turboloot*.ini.')
        ImGui.TextColored(0.45, 0.48, 0.52, 1, 'Example: turboloot.ini.20260512-1153.bak')
        ImGui.PopTextWrapPos()
        ImGui.EndTooltip()
    end
    if ImGui.Selectable('Backup My E3 INI##backup_my_e3_ini') then
        local backupPath, err = TG.backupLocalE3Ini()
        g.statusMessage = TG.backupStatusMessage('E3 INI', backupPath, err)
        ImGui.CloseCurrentPopup()
    end
    if ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        ImGui.PushTextWrapPos(ImGui.GetFontSize() * 30.0)
        ImGui.Text('Creates a timestamped .bak next to this character\'s E3 INI.')
        ImGui.TextColored(0.45, 0.48, 0.52, 1, 'Looks in Config\\e3 Bot Inis, then Macros\\e3 Bot Inis.')
        ImGui.PopTextWrapPos()
        ImGui.EndTooltip()
    end
    if ImGui.Selectable('Backup Group E3 INIs##backup_group_e3_ini') then
        local sent = TG.sendGroupE3Backups()
        g.statusMessage = sent > 0
            and string.format('E3 INI backup sent to %d group character(s).', sent)
            or 'No group characters found for E3 INI backup.'
        ImGui.CloseCurrentPopup()
    end
    if ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        ImGui.PushTextWrapPos(ImGui.GetFontSize() * 30.0)
        ImGui.Text('Each group character backs up its own local E3 INI.')
        ImGui.TextColored(0.45, 0.48, 0.52, 1, 'Sends /lua run Turbo backup e3 via /e3bct.')
        ImGui.PopTextWrapPos()
        ImGui.EndTooltip()
    end
    if ImGui.Selectable('Backup ALL Zone E3 INIs##backup_all_e3_ini') then
        mq.cmd('/squelch /e3bcaa /lua run Turbo backup e3')
        g.statusMessage = 'E3 INI backup sent to ALL zone bots.'
        ImGui.CloseCurrentPopup()
    end
    if ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        ImGui.PushTextWrapPos(ImGui.GetFontSize() * 30.0)
        ImGui.Text('Broadcasts an E3 INI backup command to all E3 bots in zone.')
        ImGui.TextColored(0.45, 0.48, 0.52, 1, 'Use carefully in crowded zones.')
        ImGui.PopTextWrapPos()
        ImGui.EndTooltip()
    end
    ImGui.TextColored(0.55, 0.58, 0.65, 1.0, 'Named E3 backup')
    ImGui.SameLine()
    ImGui.PushItemWidth(118)
    g.backupE3TargetName = ImGui.InputText('##backup_e3_named_target', tostring(g.backupE3TargetName or ''))
    ImGui.PopItemWidth()
    ImGui.SameLine()
    if ImGui.SmallButton('Send##backup_e3_named') then
        if TG.sendE3BackupTo(g.backupE3TargetName) then
            g.statusMessage = 'E3 INI backup sent to ' .. tostring(g.backupE3TargetName)
            g.backupE3TargetName = ''
            ImGui.CloseCurrentPopup()
        else
            g.statusMessage = 'Enter a character name for E3 INI backup.'
        end
    end
    if ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        ImGui.Text('Tell one named character to back up its local E3 INI.')
        ImGui.EndTooltip()
    end
    ImGui.Separator()
    if coloredSelectable('GitHub##stgh', {95, 145, 210}) then
        openTurboRepoWeb()
        ImGui.CloseCurrentPopup()
    end
    if ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        ImGui.PushTextWrapPos(ImGui.GetFontSize() * 28.0)
        ImGui.Text(TURBO_REPO_WEB)
        ImGui.TextColored(0.45, 0.48, 0.52, 1, 'Opens in your default browser (Windows).')
        ImGui.PopTextWrapPos()
        ImGui.EndTooltip()
    end
    if coloredSelectable('XTank Macro##stxt', {150, 124, 192}) then
        local cmd = TG.xtankBroadcastCommand()
        mq.cmd(cmd)
        g.statusMessage = 'Turbo xtarget heal sent: ' .. cmd
        ImGui.CloseCurrentPopup()
    end
    if ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        ImGui.PushTextWrapPos(ImGui.GetFontSize() * 30.0)
        ImGui.Text('Sends to your E3 group. CLR / DRU / SHM only, in raid.')
        ImGui.TextColored(0.45, 0.48, 0.55, 1, 'Macro: turbo_xtar_heal.mac (install in Macros).')
        ImGui.TextColored(0.45, 0.48, 0.55, 1, g.xtanksBroadcastCommand)
        ImGui.TextColored(0.45, 0.48, 0.55, 1, 'Adds WAR / PAL / SHD raid tanks outside each healer\'s group.')
        ImGui.PopTextWrapPos()
        ImGui.EndTooltip()
    end
end
TG.renderToolsPopupBody = renderToolsPopupBody

-- =========================================================
-- Skip Tracker: load + init (graceful fallback if not installed)
-- =========================================================
local skipTracker = nil
do
    local ok, mod = pcall(function()
        for _, name in ipairs({ 'Turbo/skip_tracker', 'turbo/skip_tracker' }) do
            local s, m = pcall(require, name)
            if s and m and m.init then return m end
        end
        return nil
    end)
    if ok and mod then
        skipTracker = mod
        skipTracker.init(writeIniKey, readIniKey, getTurbolootIniPath,
                         deleteIniKey, readIniSectionPairs, TG.getReviewJournalWatchSpecs)
        if skipTracker.set_linkdb_enabled then
            skipTracker.set_linkdb_enabled(TG.skipReviewUseLinkDb == true)
        end
    end
end
TG.markStartup('skip tracker')

TG.skipQueue = (function()
    local ok, mod = pcall(function()
        for _, name in ipairs({ 'Turbo/skip_queue', 'turbo/skip_queue' }) do
            local s, m = pcall(require, name)
            if s and m and m.poll then return m end
        end
        return nil
    end)
    if ok and mod then
        return mod
    end
    return nil
end)()
TG.markStartup('skip queue')

TG.skipTracker = skipTracker
-- Define on TG (not chunk locals): this file is at LuaJIT's 200-local main limit.
TG.applySkipRule = function(itemName, rule)
    if TG.requireSharedControl and not TG.requireSharedControl('Review rule edit') then return end
    if not skipTracker then return end
    local ok = skipTracker.apply_rule(itemName, rule)
    if ok then
        TG.statusMessage = string.format('%s = %s (skip review)', itemName, rule)
    else
        TG.statusMessage = string.format('Failed to apply %s to %s', rule, itemName)
    end
end

TG.undoSkipRule = function()
    if TG.requireSharedControl and not TG.requireSharedControl('Review undo') then return end
    if not skipTracker then return end
    local ok, err = skipTracker.undo_last()
    if ok then
        TG.statusMessage = 'Undo: restored last skip rule'
    else
        TG.statusMessage = err or 'Nothing to undo'
    end
end

TG.undoCursorRule = undoCursorRule
TG.relootNow = relootNow
TG.TurboKeyRGB = TurboKeyRGB
TG.Theme = Theme

--- Drop a Review skip row after a successful Go loot (TurboLoot [GOLOOT] looted
--- or TurboGear /turboreviewgoloot). Failed go-loot leaves the row so the user
--- can retry or Nav. Safe no-op when the item is not on the pending list.
TG.dismissReviewAfterGoLoot = function(itemName, statusSink)
    itemName = tostring(itemName or ''):match('^%s*(.-)%s*$') or ''
    if itemName == '' then return false end
    local tracker = TG.skipTracker or skipTracker
    if not (tracker and tracker.dismiss) then return false end
    local ok = tracker.dismiss(itemName)
    if ok then
        TG.skipDisplayRows = nil
        TG.skipSelectedKey = nil
        TG.skipSelectionSet = nil
        TG.quickReviewSelectedKey = nil
        local msg = itemName .. ' cleared from Review (go loot)'
        if type(statusSink) == 'function' then
            statusSink(msg)
        else
            TG.statusMessage = msg
        end
    end
    return ok == true
end

-- Stored on TG (not chunk locals): this file is at LuaJIT's 200-local main limit.
TG.parseGolootLootedItem = function(line)
    line = tostring(line or '')
    local lower = line:lower()
    local tag_at = lower:find('%[goloot%]', 1, false)
    if not tag_at then return nil end
    local after = line:sub(tag_at + 8):match('^%s*(.-)%s*$') or ''
    local status, rest = after:match('^(%S+)%s*(.*)$')
    if not status or status:lower() ~= 'looted' then return nil end
    rest = tostring(rest or ''):gsub('%(%s*ID%s*:%s*%d+%s*%)', ''):match('^%s*(.-)%s*$') or ''
    if rest == '' then return nil end
    return rest
end

TG.onGoLootReviewEcho = function(line)
    local item = TG.parseGolootLootedItem(line)
    if item then TG.dismissReviewAfterGoLoot(item) end
end

if not TG.goLootReviewEventActive then
    pcall(function()
        mq.event('TurboReviewGoLootEcho', '#*#[GOLOOT] looted #*#', TG.onGoLootReviewEcho)
    end)
    TG.goLootReviewEventActive = true
end

TG.repairSkipReviewData = function(g)
    g = g or TG
    local removedJournals = 0
    local removedRuntime = 0

    if g.skipTracker and g.skipTracker.reset_all then
        removedJournals = g.skipTracker.reset_all(true) or 0
    end

    if g.skipQueue and g.skipQueue.reset_state then
        removedRuntime = removedRuntime + (g.skipQueue.reset_state(true) or 0)
    else
        local mqPath = mq.TLO.MacroQuest.Path() or ''
        if mqPath ~= '' then
            for _, path in ipairs({
                mqPath .. '\\Config\\TurboLoot_skip_queue.ini',
                mqPath .. '\\Config\\turbo_skip_queue_state.lua',
            }) do
                if os.remove(path) then
                    removedRuntime = removedRuntime + 1
                end
            end
        end
    end

    g.skipDisplayRows = nil
    g.skipSelectedKey = nil
    g.skipSelectionSet = nil
    g.skipIniTargetOverride = nil
    g.skipIniTargetOverridePath = nil
    g.statusMessage = string.format(
        'Skip Review repaired. Deleted %d journal file%s and %d queue/state file%s. INI rules unchanged.',
        removedJournals, removedJournals == 1 and '' or 's',
        removedRuntime, removedRuntime == 1 and '' or 's')
end

-- =========================================================
-- __TL_SKIP__ event listener + display cache
-- =========================================================

--- Resolve the turboloot INI filename assigned to a character name.
--- Reads the E3 var TurboLootIni for that character via MQ2Mono.
--- Falls back to the active local INI if the character is unknown.
TG.resolveIniForChar = function(charName)
    if not charName or charName == '' then
        return getTurbolootIniPath and
            (getTurbolootIniPath() or ''):match('[^\\/]+$') or 'turboloot.ini'
    end
    -- Journal "source" for CLI tests and some paths is literal "cli", not a character name.
    if charName:lower() == 'cli' then
        return getTurbolootIniPath and
            (getTurbolootIniPath() or ''):match('[^\\/]+$') or 'turboloot.ini'
    end
    -- Check per-char profile table first (already in memory).
    -- charProfiles is a dict: { ["Drel"] = "turboloot.ini", ... } — use pairs, not ipairs.
    local profiles = TG.charProfiles
    if profiles then
        local direct = profiles[charName]
        if direct and direct ~= '' then return direct end
        -- Case-insensitive fallback (character names should match, but guard anyway).
        local lc = charName:lower()
        for k, v in pairs(profiles) do
            if type(k) == 'string' and k:lower() == lc and v and v ~= '' then
                return v
            end
        end
    end
    -- Fall back to E3 var for this character.
    local v = mq.TLO.MQ2Mono and mq.TLO.MQ2Mono.Query and
              mq.TLO.MQ2Mono.Query(string.format('e3,%s,TurboLootIni', charName))()
    if v and v ~= '' and v ~= 'NULL' and not v:find('${', 1, true) then
        return v
    end
    return getTurbolootIniPath and
        (getTurbolootIniPath() or ''):match('[^\\/]+$') or 'turboloot.ini'
end

--- Rebuild the pre-formatted display rows from the tracker's pending list.
--- Called by the mq.event handler and once on tracker init — never inside renderWindow.
TG.readReviewItemRule = function(iniPath, itemName)
    if not iniPath or iniPath == '' or not itemName or itemName == '' then return nil end
    local rule = readIniKey(iniPath, 'ItemLimits', itemName)
    if (not rule or rule == '') then
        rule = readIniKey(iniPath, 'ItemLimits', itemName:upper())
    end
    if (not rule or rule == '') then
        rule = readIniKey(iniPath, 'ItemLimits', itemName:lower())
    end
    if not rule or rule == '' then return nil end
    return tostring(rule):match('^%s*(.-)%s*$')
end

TG.buildReviewItemRuleLookup = function(iniPath)
    local lookup = {}
    if not iniPath or iniPath == '' then return lookup end
    for _, pair in ipairs(readIniSectionPairs(iniPath, 'ItemLimits')) do
        local key = tostring(pair.key or ''):match('^%s*(.-)%s*$') or ''
        if key ~= '' then
            lookup[key] = pair.value
            lookup[key:upper()] = pair.value
            lookup[key:lower()] = pair.value
        end
    end
    return lookup
end

TG.isExpectedReviewSkip = function(reasonCode, itemRule)
    local rule = tostring(itemRule or ''):match('^%s*(.-)%s*$') or ''
    if rule == '' then return false end
    local r = tostring(reasonCode or ''):lower()
    local ruleUpper = rule:upper():gsub('%s+', '')
    if r == 'numeric_limit_reached' then
        return tonumber(rule) ~= nil and tonumber(rule) > 0
    end
    if r:find('lore_', 1, true) or r:find('lore', 1, true) then
        return true
    end
    if r == 'unlisted' then
        return ruleUpper == 'IGNORE' or ruleUpper == 'SKIP' or ruleUpper == 'ANNOUNCE'
    end
    if r == 'below_threshold' or r == 'stackable_below_pp_threshold' then
        return ruleUpper == 'IGNORE' or ruleUpper == 'SKIP' or ruleUpper == 'ANNOUNCE'
    end
    return false
end

rebuildSkipDisplayRows = function()
    if not skipTracker or not skipTracker.is_ready() then
        TG.skipDisplayRows = {}
        TG.skipDisplayTotal = 0
        TG.skipExpectedSkipTotal = 0
        return
    end
    local pending = skipTracker.get_pending()
    local rows = {}
    local expectedN = 0
    local ruleCache = {}
    for i = 1, #pending do
        local rec = pending[i]
        local reasonCode, reasonDisplay = skipTracker.primary_reason(rec)
        local src = skipTracker.get_source(rec)
        local iniFile = TG.skipIniTargetOverride or TG.resolveIniForChar(src)
        -- 3.8.33: resolve full path alongside the filename. apply_rule needs
        -- a full path to write the INI; UI display still uses the filename.
        -- TG.resolveIniForChar returns bare filename (e.g. "turboloot.ini") — we
        -- complete it via resolveTurbolootIniPathForProfile which probes
        -- Config\ and Macros\ under MacroQuest's base dir.
        local iniPath = nil
        if resolveTurbolootIniPathForProfile then
            iniPath = (resolveTurbolootIniPathForProfile(iniFile))
        end
        local itemRule = nil
        if iniPath and iniPath ~= '' then
            local cacheKey = iniPath:lower()
            if not ruleCache[cacheKey] then
                ruleCache[cacheKey] = TG.buildReviewItemRuleLookup(iniPath)
            end
            local lookup = ruleCache[cacheKey]
            itemRule = lookup[rec.name] or lookup[rec.name:upper()] or lookup[rec.name:lower()]
        end
        local expectedSkip = TG.isExpectedReviewSkip(reasonCode, itemRule)
        if expectedSkip then
            expectedN = expectedN + 1
        else
            local nameDisplay = rec.name
            if #nameDisplay > 32 then nameDisplay = nameDisplay:sub(1, 29) .. '...' end
            if #rows < 500 then
                rows[#rows + 1] = {
                    key         = rec.key,
                    name        = rec.name,
                    nameDisplay = nameDisplay,
                    count       = rec.count,
                    reason      = reasonDisplay,
                    zone        = rec.last_zone,
                    source      = src,
                    itemId      = tostring(rec.item_id or ''),
                    corpseId    = tostring(rec.corpse_id or ''),
                    iniFile     = iniFile,   -- bare filename for UI display
                    iniPath     = iniPath,   -- full path for apply_rule (3.8.33)
                }
            end
        end
    end
    TG.skipDisplayRows = rows
    TG.skipDisplayTotal = math.max(0, #pending - expectedN)
    TG.skipExpectedSkipTotal = expectedN
end

-- Dismiss every actionable pending skip in one pass. Same filter as the Review
-- list (leave "expected" skips alone) and same mark_ts revive semantics as a
-- per-row dismiss — but load each INI's [ItemLimits] once instead of N key reads.
-- Stored on TG (not a chunk local) to stay under LuaJIT's 200-local main limit.
TG.clearActionablePendingSkips = function()
    local cleared = 0
    if not skipTracker or not skipTracker.get_pending then return 0 end
    local pendingItems = skipTracker.get_pending() or {}
    local ruleCache = {}
    if skipTracker.persist_batch_begin then skipTracker.persist_batch_begin() end
    for _, rec in ipairs(pendingItems) do
        if rec.name and rec.name ~= '' then
            local reasonCode = skipTracker.primary_reason(rec)
            local recSrc = skipTracker.get_source(rec)
            local iniFile = TG.resolveIniForChar(recSrc)
            local iniPath = resolveTurbolootIniPathForProfile and resolveTurbolootIniPathForProfile(iniFile) or nil
            local itemRule = nil
            if iniPath and iniPath ~= '' then
                local cacheKey = iniPath:lower()
                if not ruleCache[cacheKey] then
                    ruleCache[cacheKey] = TG.buildReviewItemRuleLookup(iniPath)
                end
                local lookup = ruleCache[cacheKey]
                itemRule = lookup[rec.name] or lookup[rec.name:upper()] or lookup[rec.name:lower()]
            end
            if not TG.isExpectedReviewSkip(reasonCode, itemRule) then
                if skipTracker.dismiss(rec.name) then cleared = cleared + 1 end
            end
        end
    end
    if skipTracker.persist_batch_end then skipTracker.persist_batch_end() end
    return cleared
end

--- EQBC / echo event names (must be defined before registerSkipListener).
TG.SKIP_EVENT_NAME = 'TurboSkipBroadcast'
--- Multiple patterns: MQ Next chat lines vary (color codes, channel); e3bc often does not surface to Lua mq.event without a local /echo.
TG.SKIP_EVENT_PATTERNS = {
    '#*#__TL_SKIP__|#*#',
    '#*#__TL_SKIP__|*',
    '*__TL_SKIP__|*',
}
TG.skipAnnounceEventName = 'TurboSkipAnnounce'
TG.skipAnnouncePatterns = {
    "#*#SKIP#*#",
    "#*#GIVING UP#*#",
    "#*#LIMIT REACHED#*#",
    "*SKIP*",
    "*GIVING UP*",
    "*LIMIT REACHED*",
}

--- Current E3 GrpLootMode (single / multi / all), lowercased; default single.
TG.queryGrpLootMode = function()
    local q = mq.TLO.MQ2Mono and mq.TLO.MQ2Mono.Query and mq.TLO.MQ2Mono.Query('e3,GrpLootMode')
    if not q then return 'single' end
    local v = q()
    if not v or v == '' or v == 'NULL' then return 'single' end
    return v:lower()
end

--- MQ Next often does not pass argv to `lua run Turbo/skip_log append ...`; load module like TurboLoot.mac /lua parse (require + loadfile paths).
TG.onSkipBroadcast = function(line)
    if not line:find('__TL_SKIP__|', 1, true) then return end
    TG.skipDisplayRows = nil
end

function TG.onSkipAnnounce(line)
    TG.skipDisplayRows = nil
end

--- Register the EQBC __TL_SKIP__ event listener (called from bindTurboRuntimeCommands).
registerSkipListener = function()
    if TG.skipEventActive then return end
    for i, pat in ipairs(TG.SKIP_EVENT_PATTERNS) do
        pcall(function()
            mq.event(TG.SKIP_EVENT_NAME .. tostring(i), pat, TG.onSkipBroadcast)
        end)
    end
    for i, pat in ipairs(TG.skipAnnouncePatterns) do
        pcall(function()
            mq.event(TG.skipAnnounceEventName .. tostring(i), pat, TG.onSkipAnnounce)
        end)
    end
    TG.skipEventActive = true
end

unregisterSkipListener = function()
    if not TG.skipEventActive then return end
    for i = 1, #TG.SKIP_EVENT_PATTERNS do
        pcall(function()
            mq.unevent(TG.SKIP_EVENT_NAME .. tostring(i))
        end)
    end
    for i = 1, #TG.skipAnnouncePatterns do
        pcall(function()
            mq.unevent(TG.skipAnnounceEventName .. tostring(i))
        end)
    end
    TG.skipEventActive = false
end


-- =========================================================

TG.turboChromeNewDragState = function()
    return {
        excludes = {},
        band = nil,
        grabbing = false,
        lastX = nil,
        lastY = nil,
    }
end

TG.turboChromeDragStates = TG.turboChromeDragStates or {
    main = TG.turboChromeNewDragState(),
    review = TG.turboChromeNewDragState(),
    gains = TG.turboChromeNewDragState(),
}
TG.turboChromeDragState = TG.turboChromeDragStates.main
TG.turboChromeDragCurrentState = TG.turboChromeDragState
TG.turboTitleDragEnabled = false

TG.turboChromeGetDragState = function(state)
    if type(state) == 'string' then
        TG.turboChromeDragStates[state] = TG.turboChromeDragStates[state] or TG.turboChromeNewDragState()
        return TG.turboChromeDragStates[state]
    end
    if type(state) == 'table' then return state end
    return TG.turboChromeDragCurrentState or TG.turboChromeDragState
end

TG.turboVec2XY = function(v, y)
    if type(v) == 'table' then
        return tonumber(v.x or v.X or v[1]) or 0, tonumber(v.y or v.Y or v[2]) or 0
    end
    return tonumber(v) or 0, tonumber(y) or 0
end

TG.turboMousePos = function()
    if not ImGui.GetMousePos then return nil, nil end
    local x, y = ImGui.GetMousePos()
    return TG.turboVec2XY(x, y)
end

TG.turboWindowRect = function()
    if not (ImGui.GetWindowPos and ImGui.GetWindowSize) then return nil end
    local x, y = TG.turboVec2XY(ImGui.GetWindowPos())
    local w, h = TG.turboVec2XY(ImGui.GetWindowSize())
    return { x1 = x, y1 = y, x2 = x + w, y2 = y + h }
end

TG.turboCursorScreenY = function()
    if not ImGui.GetCursorScreenPos then return nil end
    local _, y = TG.turboVec2XY(ImGui.GetCursorScreenPos())
    return y
end

TG.turboItemRect = function()
    if not (ImGui.GetItemRectMin and ImGui.GetItemRectMax) then return nil end
    local minX, minY = ImGui.GetItemRectMin()
    local maxX, maxY = ImGui.GetItemRectMax()
    local x1, y1 = TG.turboVec2XY(minX, minY)
    local x2, y2 = TG.turboVec2XY(maxX, maxY)
    return { x1 = x1, y1 = y1, x2 = x2, y2 = y2 }
end

TG.turboPointInRect = function(x, y, r)
    return r and x >= r.x1 and x <= r.x2 and y >= r.y1 and y <= r.y2
end

TG.turboChromeDragReset = function(state)
    local st = TG.turboChromeGetDragState(state)
    TG.turboChromeDragCurrentState = st
    st.excludes = {}
    st.band = nil
    if ImGui.IsMouseDown and not ImGui.IsMouseDown(0) then
        st.grabbing = false
        st.lastX, st.lastY = nil, nil
    end
end

TG.turboChromeDragAddLastItem = function(state)
    local st = TG.turboChromeGetDragState(state)
    local r = TG.turboItemRect()
    if r then st.excludes[#st.excludes + 1] = r end
end

TG.turboChromeDragSetBandToCursor = function(minHeight, state)
    local win = TG.turboWindowRect()
    local cy = TG.turboCursorScreenY()
    if not win or not cy then return end
    minHeight = tonumber(minHeight) or 24
    local st = TG.turboChromeGetDragState(state)
    st.band = {
        x1 = win.x1,
        y1 = win.y1,
        x2 = win.x2,
        y2 = math.max(win.y1 + minHeight, cy),
    }
end

TG.turboChromeBlocked = function(x, y, state)
    local st = TG.turboChromeGetDragState(state)
    for _, r in ipairs(st.excludes or {}) do
        if TG.turboPointInRect(x, y, r) then return true end
    end
    return false
end

TG.turboChromeDragMove = function(x, y, state)
    if not (ImGui.SetWindowPos and x and y) then return end
    local st = TG.turboChromeGetDragState(state)
    if st.lastX and st.lastY then
        local dx = x - st.lastX
        local dy = y - st.lastY
        if dx ~= 0 or dy ~= 0 then
            local wx, wy = TG.turboVec2XY(ImGui.GetWindowPos())
            ImGui.SetWindowPos(wx + dx, wy + dy)
        end
    end
    st.lastX, st.lastY = x, y
end

TG.turboChromeDragApplyActive = function(state)
    local st = TG.turboChromeGetDragState(state)
    if not st.grabbing then return end
    if not (ImGui.IsMouseDown and ImGui.IsMouseDown(0)) then
        st.grabbing = false
        st.lastX, st.lastY = nil, nil
        return
    end
    local mx, my = TG.turboMousePos()
    if not mx or not my then return end
    if ImGui.ClearActiveID then ImGui.ClearActiveID() end
    TG.turboChromeDragMove(mx, my, st)
end

TG.turboChromeDragActiveItem = function(state)
    if not (ImGui.IsItemActive and ImGui.IsItemActive()) then return false end
    if not (ImGui.IsMouseDown and ImGui.IsMouseDown(0)) then return false end
    local mx, my = TG.turboMousePos()
    if not mx or not my then return false end
    local st = TG.turboChromeGetDragState(state)
    if not st.grabbing then
        st.grabbing = true
        st.lastX, st.lastY = mx, my
        if ImGui.ResetMouseDragDelta then ImGui.ResetMouseDragDelta(0) end
    end
    if ImGui.ClearActiveID then ImGui.ClearActiveID() end
    TG.turboChromeDragMove(mx, my, st)
    return true
end

TG.turboChromeDragHandle = function(tooltip, allowBlankWindow, state)
    local st = TG.turboChromeGetDragState(state)
    local mx, my = TG.turboMousePos()
    if not mx or not my or not st.band then return end
    local hovered = not ImGui.IsWindowHovered or ImGui.IsWindowHovered()
    local inBand = TG.turboPointInRect(mx, my, st.band)
    local blocked = TG.turboChromeBlocked(mx, my, st)
    local down = ImGui.IsMouseDown and ImGui.IsMouseDown(0)
    local blankWindow = false
    if allowBlankWindow and ImGui.IsWindowHovered then
        local anyItemHovered = ImGui.IsAnyItemHovered and ImGui.IsAnyItemHovered() or false
        local anyItemActive = ImGui.IsAnyItemActive and ImGui.IsAnyItemActive() or false
        blankWindow = ImGui.IsWindowHovered() and not anyItemHovered and not anyItemActive and not blocked
    end

    if ImGui.IsMouseClicked and ImGui.IsMouseClicked(0) then
        if hovered and ((inBand and not blocked) or blankWindow) then
            st.grabbing = true
            st.lastX, st.lastY = mx, my
            if ImGui.ResetMouseDragDelta then ImGui.ResetMouseDragDelta(0) end
        elseif not st.grabbing then
            st.lastX, st.lastY = nil, nil
        end
    end

    if not down then
        st.grabbing = false
        st.lastX, st.lastY = nil, nil
        return
    end

    if st.grabbing then
        if ImGui.ClearActiveID then ImGui.ClearActiveID() end
    elseif hovered and (inBand and not blocked or blankWindow) and ImGui.SetTooltip then
        ImGui.SetTooltip(tooltip or 'Drag empty header space to move Turbo.')
    end
end

-- =========================================================
-- Tab rendering stubs (Session 3 will wire these in)
-- Forward-declared here so renderWindow can reference them.
-- =========================================================

--- Persistent top bar: toggles plus top-right wallet/Loot/collapse controls.
--- Rendered above the tab bar in Full + Slim modes.
--- Not yet called from renderWindow — wired in Session 3.
local function renderTopBar(g, viewState)
    local function topAvailX()
        local avail = ImGui.GetContentRegionAvail()
        if type(avail) == 'table' then return tonumber(avail.x or avail.X or avail[1]) or 0 end
        return tonumber(avail) or 0
    end
    local turboOn     = viewState.runtime.turboOn
    local combatOn    = viewState.runtime.combatOn
    local lootAllOn   = viewState.runtime.lootAllOn
    local currentLooter = viewState.runtime.currentLooter
    local routeWarning = turboOn and viewState.runtime.lootReady == false
    local saveSettings  = g.saveSettings
    local toggleSwitch  = g.toggleSwitch
    local tip           = g.tip
    local summary       = viewState.summary.topBar
    local canControl    = TG.isSharedControlOwner()

    local compactHeader = topAvailX() < ((TG.showQuickStartButton ~= false or TG.showStopAllButton ~= false) and 360 or 330)
    local smallGap = compactHeader and 2 or Theme.space.sm

    -- ── Turbo + Combat toggles (left side) ──────────────────────
    ImGui.BeginGroup()
    if not canControl then ImGui.BeginDisabled() end
    if toggleSwitch('##turbo', turboOn) then
        if TG.requireSharedControl('Turbo toggle') then
            if turboOn then
                TG.setTurboEnabled(false, currentLooter, lootAllOn, viewState.runtime.multiModeOn)
            else
                TG.setTurboEnabled(true, currentLooter, lootAllOn, viewState.runtime.multiModeOn)
            end
        end
    end
    if not canControl then ImGui.EndDisabled() end
    if TG.turboChromeDragAddLastItem then TG.turboChromeDragAddLastItem() end
    tip((turboOn and viewState.runtime.lootReady == false)
        and (viewState.runtime.lootReadyReason or 'Turbo is enabled, but no valid looter route is ready.')
        or (canControl and 'Toggle auto-looting on or off. Turning it off also sends /endmacro to the active looters.'
            or ('Browse mode: controlled by ' .. TG.sharedControlOwnerName() .. '.')))
    ImGui.SameLine()
    ImGui.TextColored(turboOn and (routeWarning and 0.9 or 0.4) or 0.5,
        turboOn and (routeWarning and 0.68 or 0.85) or 0.5,
        turboOn and (routeWarning and 0.25 or 0.5) or 0.5, 1.0,
        compactHeader and (routeWarning and 'T!' or 'T') or (routeWarning and 'Turbo !' or 'Turbo'))
    ImGui.SameLine()
    ImGui.Dummy(smallGap, 1)
    ImGui.SameLine()
    if not canControl then ImGui.BeginDisabled() end
    if toggleSwitch('##combat', combatOn) then
        if TG.requireSharedControl('Combat loot toggle') then g.toggleCombatLoot() end
    end
    if not canControl then ImGui.EndDisabled() end
    if TG.turboChromeDragAddLastItem then TG.turboChromeDragAddLastItem() end
    tip(canControl and 'When ON, loot even with aggressive mobs nearby'
        or ('Browse mode: controlled by ' .. TG.sharedControlOwnerName() .. '.'))
    ImGui.SameLine()
    ImGui.TextColored(combatOn and 0.8 or 0.5, combatOn and 0.6 or 0.5, combatOn and 0.3 or 0.5, 1.0,
        compactHeader and 'C' or 'Combat')
    ImGui.EndGroup()

    -- ── Wallet + Loot + Collapse (right side) ──────────────────
    local stopBtnW = (TG.showStopAllButton ~= false) and 32 or 0
    local helpBtnW = (TG.showQuickStartButton ~= false) and 26 or 0
    local walletBtnW = 0
    local lootTopW = 92
    local spTop = ImGui.GetStyle().ItemSpacing.x
    local compactTop = topAvailX() < 420
    local collapseActualW = compactTop and 34 or 40
    if compactTop then
        lootTopW = 64
        if TG.showQuickStartButton ~= false then helpBtnW = 24 end
        walletBtnW = 0
        if TG.showStopAllButton ~= false then stopBtnW = 26 end
    end
    local availTop = topAvailX()
    local function rightWidth()
        local visible = 1 -- collapse is always visible
        if helpBtnW > 0 then visible = visible + 1 end
        if stopBtnW > 0 then visible = visible + 1 end
        if lootTopW > 0 then visible = visible + 1 end
        if walletBtnW > 0 then visible = visible + 1 end
        return walletBtnW + helpBtnW + lootTopW + collapseActualW + stopBtnW + (spTop * math.max(0, visible - 1))
    end
    local rightTopW = rightWidth()
    if rightTopW > availTop and helpBtnW > 0 then helpBtnW = 0 ; rightTopW = rightWidth() end
    if rightTopW > availTop and stopBtnW > 0 then stopBtnW = 0 ; rightTopW = rightWidth() end
    if rightTopW > availTop and lootTopW > 0 then
        lootTopW = math.max(50, math.min(lootTopW, availTop - collapseActualW - spTop))
        rightTopW = rightWidth()
    end
    if rightTopW > availTop and lootTopW > 0 then lootTopW = 0 ; rightTopW = rightWidth() end

    ImGui.SameLine()
    ImGui.SetCursorPosX(ImGui.GetCursorPosX() + math.max(0, topAvailX() - rightTopW))

    ImGui.BeginGroup()
    --- Order reads: help, stop (optional), Loot, $, collapse. Collapse stays on the far right
    --- to match Mini's edge-positioned expand button.
    if helpBtnW > 0 then
        if Ui.buttonVariant('?##top_quick_start', 'utilityButton', helpBtnW, LAYOUT_MODE_BTN_H) then
            TG.toggleQuickStartWindow()
        end
        if TG.turboChromeDragAddLastItem then TG.turboChromeDragAddLastItem() end
        tip('Open or close Turbo Quick Start.')
        ImGui.SameLine()
    end

    if stopBtnW > 0 then
        if not canControl then ImGui.BeginDisabled() end
        if Ui.stopSignButton('##top_stop_all', stopBtnW, LAYOUT_MODE_BTN_H) then
            if TG.requireSharedControl('STOP') then g.stopAllActions() end
        end
        if not canControl then ImGui.EndDisabled() end
        if TG.turboChromeDragAddLastItem then TG.turboChromeDragAddLastItem() end
        tip(canControl
            and 'STOP: end all macros, stop navigation, and announce HALT. Turn off in Loot Manager Setup if you mis-click it.'
            or ('Browse mode: controlled by ' .. TG.sharedControlOwnerName() .. '.'))
        ImGui.SameLine()
    end

    if lootTopW > 0 then
        if viewState.runtime.lootReady == false or not canControl then ImGui.BeginDisabled() end
        if Ui.buttonVariant('Loot##toprun', 'primaryButton', lootTopW, LAYOUT_MODE_BTN_H) then
            if TG.requireSharedControl('Loot Now') then
                if TG.collectGroupMembers then TG.collectGroupMembers() elseif g.collectGroupMembers then g.collectGroupMembers() end
                if TG.lootNow then TG.lootNow() elseif g.lootNow then g.lootNow() end
            end
        end
        if TG.turboChromeDragAddLastItem then TG.turboChromeDragAddLastItem() end
        if viewState.runtime.lootReady == false or not canControl then ImGui.EndDisabled() end
        tip((not canControl)
            and ('Browse mode: controlled by ' .. TG.sharedControlOwnerName() .. '.')
            or (viewState.runtime.lootReady == false)
            and (viewState.runtime.lootReadyReason or 'No valid looter route is ready.')
            or 'Loot Now - sends to single looter, selected MULTI looters, or ALL')
        ImGui.SameLine()
    end

    if walletBtnW > 0 then
        if Ui.buttonVariant('$##topwalletbtn', 'amberButton', walletBtnW, LAYOUT_MODE_BTN_H) then
            ImGui.OpenPopup(viewState.popupIds.wallet)
        end
        if TG.turboChromeDragAddLastItem then TG.turboChromeDragAddLastItem() end
        if ImGui.IsItemHovered() then
            ImGui.BeginTooltip()
            ImGui.TextColored(0.88, 0.80, 0.35, 1.0, string.format('%12s pp', tostring(cachedWallet.plat)))
            ImGui.TextColored(0.55, 0.72, 0.90, 1.0, string.format('%12s aa', tostring(cachedWallet.aa)))
            ImGui.TextColored(0.45, 0.78, 0.82, 1.0, string.format('%12s dc', tostring(cachedWallet.dc)))
            ImGui.TextColored(0.72, 0.55, 0.88, 1.0, string.format('%12s tribute', tostring(cachedWallet.favor)))
            ImGui.EndTooltip()
        end
        ImGui.SameLine()
    end

    if Ui.buttonVariant('-##collapsemini', 'windowToggleButton', collapseActualW, LAYOUT_MODE_BTN_H) then
        g.slimWhenExpanded = false
        g.slimGUI = false
        g.minimizedGUI = true
        saveSettings()
    end
    if TG.turboChromeDragAddLastItem then TG.turboChromeDragAddLastItem() end
    tip('Collapse back to the Mini bar.')
    ImGui.EndGroup()
    if ImGui.BeginPopup(viewState.popupIds.wallet) then
        drawWalletPopupPanel()
        ImGui.EndPopup()
    end

    if summary.showNoGroupWarning then
        ImGui.Dummy(0, 4)
        ImGui.TextColored(0.8, 0.65, 0.35, 1.0,
            'No group PCs in zone — solo / merc (use ALL or set looter when grouped).')
    end
end

TG.drawTurboFullTitle = function()
    local function textWidth(text)
        text = tostring(text or '')
        if ImGui.CalcTextSize then
            local w = ImGui.CalcTextSize(text)
            if type(w) == 'table' then return tonumber(w.x or w.X or w[1]) or 0 end
            return tonumber(w) or 0
        end
        return #text * 7
    end
    local barW = 0
    if ImGui.GetWindowContentRegionMin and ImGui.GetWindowContentRegionMax then
        local cmin = ImGui.GetWindowContentRegionMin()
        local cmax = ImGui.GetWindowContentRegionMax()
        local minX = type(cmin) == 'table' and tonumber(cmin.x or cmin.X or cmin[1]) or tonumber(cmin) or 0
        local maxX = type(cmax) == 'table' and tonumber(cmax.x or cmax.X or cmax[1]) or tonumber(cmax) or minX
        if maxX > minX then barW = maxX - minX end
    end
    if barW <= 0 then
        local avail = ImGui.GetContentRegionAvail and ImGui.GetContentRegionAvail() or 0
        barW = type(avail) == 'table' and tonumber(avail.x or avail.X or avail[1]) or tonumber(avail) or 0
    end
    local titleA = 'Turbo'
    local titleB = string.format(' v%s', TURBO_VERSION)
    local titleW = textWidth(titleA) + textWidth(titleB)
    local x0, y0 = 0, 0
    if ImGui.GetCursorPos then
        local x, y = ImGui.GetCursorPos()
        x0, y0 = tonumber(x) or 0, tonumber(y) or 0
    end
    local screenX, screenY = nil, nil
    if ImGui.GetCursorScreenPos then
        local sx, sy = ImGui.GetCursorScreenPos()
        if type(sx) == 'table' then
            screenX = tonumber(sx.x or sx.X or sx[1])
            screenY = tonumber(sx.y or sx.Y or sx[2])
        else
            screenX = tonumber(sx)
            screenY = tonumber(sy)
        end
    end

    local badgeCompact = barW < 390
    local sharedStatus = TG.sharedControlStatus or TG.refreshSharedControl(false)
    local sharedOwner = sharedStatus and sharedStatus.isOwner == true
    local badgeW = badgeCompact and (sharedOwner and 42 or 48) or (sharedOwner and 64 or 116)
    if titleW + badgeW + 18 > barW then
        titleB = ''
        titleW = textWidth(titleA)
    end
    if ImGui.SetCursorPos then ImGui.SetCursorPos(x0, y0 + 7) end
    TG.renderSharedControlBadge(tip, badgeCompact)
    local dragX = badgeW + 6
    if ImGui.SetCursorPos then
        ImGui.SetCursorPos(x0 + dragX, y0)
    else
        ImGui.SameLine(0, 6)
    end

    local dragMinX, dragMinY, dragMaxX = nil, nil, nil
    if ImGui.InvisibleButton then
        ImGui.InvisibleButton('##turbo_full_title_drag', math.max(20, barW - dragX), 38)
        if ImGui.GetItemRectMin and ImGui.GetItemRectMax then
            local rmin, rminY = ImGui.GetItemRectMin()
            local rmax = ImGui.GetItemRectMax()
            dragMinX = type(rmin) == 'table' and tonumber(rmin.x or rmin.X or rmin[1]) or tonumber(rmin) or nil
            dragMinY = type(rmin) == 'table' and tonumber(rmin.y or rmin.Y or rmin[2]) or tonumber(rminY) or nil
            dragMaxX = type(rmax) == 'table' and tonumber(rmax.x or rmax.X or rmax[1]) or tonumber(rmax) or nil
        end
        if TG.turboChromeDragActiveItem then TG.turboChromeDragActiveItem('main') end
        if TG.turboTitleDragEnabled ~= false
            and ImGui.IsItemActive and ImGui.IsItemActive()
            and ImGui.IsMouseDragging and ImGui.GetMouseDragDelta and ImGui.SetWindowPos
            and ImGui.IsMouseDragging(0, 0.0) then
            local delta = ImGui.GetMouseDragDelta(0)
            local dx = type(delta) == 'table' and tonumber(delta.x or delta.X or delta[1]) or tonumber(delta) or 0
            local dy = type(delta) == 'table' and tonumber(delta.y or delta.Y or delta[2]) or 0
            if dx ~= 0 or dy ~= 0 then
                local px, py = ImGui.GetWindowPos()
                ImGui.SetWindowPos((tonumber(px) or 0) + dx, (tonumber(py) or 0) + dy)
                if ImGui.ResetMouseDragDelta then ImGui.ResetMouseDragDelta(0) end
            end
        end
        if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then ImGui.SetTooltip('Drag to move Turbo.') end
    end

    if ImGui.GetWindowDrawList and ImGui.GetColorU32 and screenX and screenY then
        local drawX = screenX + math.max(0, (barW - titleW) * 0.5)
        if drawX < screenX + dragX then drawX = screenX + dragX end
        local drawY = screenY + 4
        ImGui.GetWindowDrawList():AddText(ImVec2(drawX, drawY), IM_COL32(255, 199, 82, 255), titleA)
        ImGui.GetWindowDrawList():AddText(ImVec2(drawX + textWidth(titleA), drawY), IM_COL32(235, 240, 250, 255), titleB)
    elseif ImGui.GetWindowDrawList and ImGui.GetColorU32 and dragMinX and dragMinY and dragMaxX then
        local drawX = dragMinX + math.max(0, ((dragMaxX - dragMinX) - titleW) * 0.5)
        local drawY = dragMinY + 4
        ImGui.GetWindowDrawList():AddText(ImVec2(drawX, drawY), IM_COL32(255, 199, 82, 255), titleA)
        ImGui.GetWindowDrawList():AddText(ImVec2(drawX + textWidth(titleA), drawY), IM_COL32(235, 240, 250, 255), titleB)
    elseif ImGui.SetCursorPos then
        ImGui.SetCursorPos(x0 + math.max(dragX, (barW - titleW) * 0.5), y0 + 3)
        ImGui.TextColored(1.00, 0.78, 0.32, 1.00, titleA)
        ImGui.SameLine(0, 0)
        ImGui.TextColored(0.92, 0.94, 0.98, 1.00, titleB)
    end

    if ImGui.SetCursorPos then ImGui.SetCursorPos(x0, y0 + 40) end
    ImGui.Separator()
end

TG.drawTurboReviewTitle = function(g)
    local function textWidth(text)
        text = tostring(text or '')
        if ImGui.CalcTextSize then
            local w = ImGui.CalcTextSize(text)
            if type(w) == 'table' then return tonumber(w.x or w.X or w[1]) or 0 end
            return tonumber(w) or 0
        end
        return #text * 7
    end
    local barW = 0
    if ImGui.GetWindowContentRegionMin and ImGui.GetWindowContentRegionMax then
        local cmin = ImGui.GetWindowContentRegionMin()
        local cmax = ImGui.GetWindowContentRegionMax()
        local minX = type(cmin) == 'table' and tonumber(cmin.x or cmin.X or cmin[1]) or tonumber(cmin) or 0
        local maxX = type(cmax) == 'table' and tonumber(cmax.x or cmax.X or cmax[1]) or tonumber(cmax) or minX
        if maxX > minX then barW = maxX - minX end
    end
    if barW <= 0 then
        local avail = ImGui.GetContentRegionAvail and ImGui.GetContentRegionAvail() or 0
        barW = type(avail) == 'table' and tonumber(avail.x or avail.X or avail[1]) or tonumber(avail) or 0
    end

    local titleA = 'Turbo'
    local titleB = ' Review'
    local titleW = textWidth(titleA) + textWidth(titleB)
    local btnW, btnH = 30, 26
    local x0, y0 = 0, 0
    if ImGui.GetCursorPos then
        local x, y = ImGui.GetCursorPos()
        x0, y0 = tonumber(x) or 0, tonumber(y) or 0
    end

    local dragMinX, dragMinY, dragMaxX = nil, nil, nil
    if ImGui.InvisibleButton then
        ImGui.InvisibleButton('##turbo_review_title_drag', math.max(20, barW - btnW - 6), 38)
        if ImGui.GetItemRectMin and ImGui.GetItemRectMax then
            local rmin, rminY = ImGui.GetItemRectMin()
            local rmax = ImGui.GetItemRectMax()
            dragMinX = type(rmin) == 'table' and tonumber(rmin.x or rmin.X or rmin[1]) or tonumber(rmin) or nil
            dragMinY = type(rmin) == 'table' and tonumber(rmin.y or rmin.Y or rmin[2]) or tonumber(rminY) or nil
            dragMaxX = type(rmax) == 'table' and tonumber(rmax.x or rmax.X or rmax[1]) or tonumber(rmax) or nil
        end
        if TG.turboChromeDragActiveItem then TG.turboChromeDragActiveItem('review') end
        if TG.turboTitleDragEnabled ~= false
            and ImGui.IsItemActive and ImGui.IsItemActive()
            and ImGui.IsMouseDragging and ImGui.GetMouseDragDelta and ImGui.SetWindowPos
            and ImGui.IsMouseDragging(0, 0.0) then
            local delta = ImGui.GetMouseDragDelta(0)
            local dx = type(delta) == 'table' and tonumber(delta.x or delta.X or delta[1]) or tonumber(delta) or 0
            local dy = type(delta) == 'table' and tonumber(delta.y or delta.Y or delta[2]) or 0
            if dx ~= 0 or dy ~= 0 then
                local px, py = ImGui.GetWindowPos()
                ImGui.SetWindowPos((tonumber(px) or 0) + dx, (tonumber(py) or 0) + dy)
                if ImGui.ResetMouseDragDelta then ImGui.ResetMouseDragDelta(0) end
            end
        end
        if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then ImGui.SetTooltip('Drag to move Turbo Review.') end
    end

    if ImGui.GetWindowDrawList and dragMinX and dragMinY and dragMaxX then
        local drawX = dragMinX + math.max(0, ((dragMaxX - dragMinX) - titleW) * 0.5)
        local drawY = dragMinY + 4
        ImGui.GetWindowDrawList():AddText(ImVec2(drawX, drawY), IM_COL32(255, 199, 82, 255), titleA)
        ImGui.GetWindowDrawList():AddText(ImVec2(drawX + textWidth(titleA), drawY), IM_COL32(235, 240, 250, 255), titleB)
    end

    if ImGui.SetCursorPos then
        ImGui.SetCursorPos(x0 + math.max(0, barW - btnW), y0)
    else
        ImGui.SameLine()
    end
    if Ui.buttonVariant('-##turbo_review_close', 'windowToggleButton', btnW, btnH) then
        g.reviewWindowOpen = false
        g.skipReviewOpen = false
        if g.saveSettings then g.saveSettings() end
    end
    if TG.turboChromeDragAddLastItem then TG.turboChromeDragAddLastItem() end
    if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then ImGui.SetTooltip('Close Turbo Review.') end

    if ImGui.SetCursorPos then ImGui.SetCursorPos(x0, y0 + 42) end
    ImGui.Separator()
end

TG.drawTurboGainsTitle = function(g)
    local function textWidth(text)
        text = tostring(text or '')
        if ImGui.CalcTextSize then
            local w = ImGui.CalcTextSize(text)
            if type(w) == 'table' then return tonumber(w.x or w.X or w[1]) or 0 end
            return tonumber(w) or 0
        end
        return #text * 7
    end
    local barW = 0
    if ImGui.GetWindowContentRegionMin and ImGui.GetWindowContentRegionMax then
        local cmin = ImGui.GetWindowContentRegionMin()
        local cmax = ImGui.GetWindowContentRegionMax()
        local minX = type(cmin) == 'table' and tonumber(cmin.x or cmin.X or cmin[1]) or tonumber(cmin) or 0
        local maxX = type(cmax) == 'table' and tonumber(cmax.x or cmax.X or cmax[1]) or tonumber(cmax) or minX
        if maxX > minX then barW = maxX - minX end
    end
    if barW <= 0 then
        local avail = ImGui.GetContentRegionAvail and ImGui.GetContentRegionAvail() or 0
        barW = type(avail) == 'table' and tonumber(avail.x or avail.X or avail[1]) or tonumber(avail) or 0
    end

    local titleA = 'Turbo'
    local titleB = string.format('Gains v%s', TURBO_VERSION)
    local titleW = textWidth(titleA) + textWidth(titleB)
    local btnW, btnH = 30, 26
    local x0, y0 = 0, 0
    if ImGui.GetCursorPos then
        local x, y = ImGui.GetCursorPos()
        x0, y0 = tonumber(x) or 0, tonumber(y) or 0
    end

    if Ui.buttonVariant('...##turbo_gains_menu_btn', 'menuButton', btnW, btnH) then
        if ImGui.OpenPopup then ImGui.OpenPopup('turbo_gains_title_menu') end
    end
    if TG.turboChromeDragAddLastItem then TG.turboChromeDragAddLastItem() end
    if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then ImGui.SetTooltip('TurboGains menu.') end
    if ImGui.BeginPopup and ImGui.BeginPopup('turbo_gains_title_menu') then
        if ImGui.Selectable('Hide##turbo_gains_hide') then
            g.gainsWindowOpen = false
            g.gainsWindowOpenReason = ''
            g.statusMessage = 'Turbo Gains hidden.'
            if g.saveSettings then g.saveSettings() end
            if ImGui.CloseCurrentPopup then ImGui.CloseCurrentPopup() end
        end
        ImGui.EndPopup()
    end

    local dragMinX, dragMinY, dragMaxX = nil, nil, nil
    if ImGui.InvisibleButton then
        if ImGui.SetCursorPos then ImGui.SetCursorPos(x0 + btnW + 6, y0) else ImGui.SameLine(0, 6) end
        ImGui.InvisibleButton('##turbo_gains_title_drag', math.max(20, barW - (btnW * 2) - 12), 38)
        if ImGui.GetItemRectMin and ImGui.GetItemRectMax then
            local rmin, rminY = ImGui.GetItemRectMin()
            local rmax = ImGui.GetItemRectMax()
            dragMinX = type(rmin) == 'table' and tonumber(rmin.x or rmin.X or rmin[1]) or tonumber(rmin) or nil
            dragMinY = type(rmin) == 'table' and tonumber(rmin.y or rmin.Y or rmin[2]) or tonumber(rminY) or nil
            dragMaxX = type(rmax) == 'table' and tonumber(rmax.x or rmax.X or rmax[1]) or tonumber(rmax) or nil
        end
        if TG.turboChromeDragActiveItem then TG.turboChromeDragActiveItem('gains') end
        if TG.turboTitleDragEnabled ~= false
            and ImGui.IsItemActive and ImGui.IsItemActive()
            and ImGui.IsMouseDragging and ImGui.GetMouseDragDelta and ImGui.SetWindowPos
            and ImGui.IsMouseDragging(0, 0.0) then
            local delta = ImGui.GetMouseDragDelta(0)
            local dx = type(delta) == 'table' and tonumber(delta.x or delta.X or delta[1]) or tonumber(delta) or 0
            local dy = type(delta) == 'table' and tonumber(delta.y or delta.Y or delta[2]) or 0
            if dx ~= 0 or dy ~= 0 then
                local px, py = ImGui.GetWindowPos()
                ImGui.SetWindowPos((tonumber(px) or 0) + dx, (tonumber(py) or 0) + dy)
                if ImGui.ResetMouseDragDelta then ImGui.ResetMouseDragDelta(0) end
            end
        end
        if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then ImGui.SetTooltip('Drag to move Turbo Gains.') end
    end

    if ImGui.GetWindowDrawList and dragMinX and dragMinY and dragMaxX then
        local drawX = dragMinX + math.max(0, ((dragMaxX - dragMinX) - titleW) * 0.5)
        local drawY = dragMinY + 4
        ImGui.GetWindowDrawList():AddText(ImVec2(drawX, drawY), IM_COL32(255, 199, 82, 255), titleA)
        ImGui.GetWindowDrawList():AddText(ImVec2(drawX + textWidth(titleA), drawY), IM_COL32(235, 240, 250, 255), titleB)
    elseif ImGui.SetCursorPos then
        ImGui.SetCursorPos(x0 + math.max(btnW + 8, (barW - titleW) * 0.5), y0 + 4)
        ImGui.TextColored(1.00, 0.78, 0.32, 1.00, titleA)
        ImGui.SameLine(0, 0)
        ImGui.TextColored(0.92, 0.94, 0.98, 1.00, titleB)
    end

    if ImGui.SetCursorPos then
        ImGui.SetCursorPos(x0 + math.max(0, barW - btnW), y0)
    else
        ImGui.SameLine()
    end
    if Ui.buttonVariant('-##turbo_gains_close', 'windowToggleButton', btnW, btnH) then
        g.gainsWindowOpen = false
        g.gainsWindowOpenReason = ''
        if g.saveSettings then g.saveSettings() end
    end
    if TG.turboChromeDragAddLastItem then TG.turboChromeDragAddLastItem() end
    if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then ImGui.SetTooltip('Close Turbo Gains.') end

    if ImGui.SetCursorPos then ImGui.SetCursorPos(x0, y0 + 42) end
    ImGui.Separator()
end

--- Tab bar: primary full-window navigation.
local function renderTabBar(g, viewState)
    local tip = g.tip
    local sn = viewState.skipState.pendingCount or 0

    local tabs = {
        { id = 'actions',     label = 'Actions' },
        { id = 'review',      label = sn > 0 and ('Review ' .. tostring(sn)) or 'Review' },
        { id = 'setup',       label = 'Setup' },
        { id = 'tools',       label = 'More' },
    }

    local btnH = Theme.layout.tabBarH
    local sp = ImGui.GetStyle().ItemSpacing.x
    local avail = ImGui.GetContentRegionAvail()
    local tabWidths = {}
    local btnW = math.max(54, math.floor((avail - sp * (#tabs - 1)) / #tabs))
    for _, tab in ipairs(tabs) do tabWidths[tab.id] = btnW end

    for i, tab in ipairs(tabs) do
        local isActive = (g.activeTab == tab.id)
        local hasSkips = (tab.id == 'review' and sn > 0)
        local btnW = tabWidths[tab.id] or 54
        if i > 1 then ImGui.SameLine() end
        local tabLabel = tab.label
        if tab.id == 'review' and sn > 0 then tabLabel = Ui.fitLabel(tab.label, 'Review', btnW) end
        if Ui.tabButton(tabLabel .. '##tab_' .. tab.id, isActive, hasSkips, btnW, btnH) then
            g.activeTab = tab.id
            g.lastActiveTab = tab.id
            g.lastRelevantTab = UiState.normalizeRelevantTab(tab.id)
            if tab.id == 'setup' or tab.id == 'review' then
                g.lootManagerPage = (tab.id == 'review') and 'review' or 'setup'
                g.skipReviewOpen = (tab.id == 'review')
                if tab.id == 'review' then
                    g.reviewMode = 'quick'
                    g.reviewWindowOpen = false
                    g.rulePacksWindowOpen = false
                end
            end
            if g.saveSettings then g.saveSettings() end
        end
        if hasSkips then
            tip(string.format('%d skipped items waiting for rules', sn))
        elseif tab.id == 'review' then
            --- 3.8.53: previously this branch had no tooltip, so hovering the
            --- Review tab while empty showed nothing. Now we describe what
            --- the tab is for so new users know it exists for a reason.
            tip('Review skipped items, set rules (KEEP/SELL/BANK/etc), or dismiss them. Empty when no skips have been recorded.')
        elseif tab.id == 'setup' then
            tip('Choose looters and INIs.')
        elseif tab.id == 'actions' then
            tip('Run TurboLoot, TurboGive, and Currency actions.')
        elseif tab.id == 'tools' then
            tip('TurboGains, maintenance, backups, links, and support tools.')
        end
    end

    -- thin separator under tab bar
    ImGui.PushStyleColor(ImGuiCol.Separator, IM_COL32(38, 52, 82, 180))
    ImGui.Separator()
    ImGui.PopStyleColor(1)
end

-- Skip Review render function (extracted to stay under LuaJIT 200-local limit)
-- =========================================================
local function renderSkipReview(g, skipTracker, tip, thinSep, undoSkipRule, TurboKeyRGB, Colors, ACTION_BTN_H, forceOpen, applyTurboKeyRule, getActiveProfile)
    if not (skipTracker and skipTracker.is_ready()) then return end
    local function wrappedText(r, gb, b, a, text)
        ImGui.PushTextWrapPos(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail())
        ImGui.TextColored(r, gb, b, a, text)
        ImGui.PopTextWrapPos()
    end

    local pendingBefore = skipTracker.pending_count()
    local dirty = skipTracker.poll()
    local pendingN = skipTracker.pending_count()
    -- pending can drop without mergeEvent (e.g. journal cleared) — rebuild rows when count changes.
    if dirty or g.skipDisplayRows == nil or pendingBefore ~= pendingN then
        rebuildSkipDisplayRows()
    end
    pendingN = g.skipDisplayTotal or pendingN
    -- Always draw Skip Review when the tracker is ready (do not hide the whole block when count is 0:
    -- skipReviewOpen is not persisted, so that made the panel disappear forever after clears / empty journal.)

    local pageMode = forceOpen == true

    if not pageMode and not g.slimGUI then
        thinSep('skipreview', 'Skip Review')
    elseif not pageMode then
        ImGui.Dummy(0, 2)
    end

    if pageMode then
        g.skipReviewOpen = true
        local watchInfo = skipTracker.get_watch_info and skipTracker.get_watch_info() or {}
        local watchText = nil
        if #watchInfo > 0 then
            local watchers = {}
            for _, spec in ipairs(watchInfo) do
                if #(spec.looters or {}) > 0 then
                    watchers[#watchers + 1] = table.concat(spec.looters, ', ')
                end
            end
            if #watchers > 0 then
                watchText = (#watchInfo == 1)
                    and ('Watching looter: ' .. watchers[1])
                    or ('Watching looters: ' .. table.concat(watchers, ' | '))
            end
        end
        -- v3.8.50: Top section pruned. The action panel below the list now
        -- carries the instructional text ("Click a row OR put an item on
        -- your cursor..."), so duplicating it up here just added noise.
        -- Order is now: tabs -> Watching looter -> list -> action panel.
        --- 3.8.65 (D): promote the "Watching looter" line — it's the most
        --- important context on this tab (which looter's skips you're
        --- reviewing) so it gets a colored dot marker and a slightly brighter
        --- text color. Was previously a small gray line that blended into the
        --- background. The dot uses the same skipreview palette as the
        --- section headers in Actions tab so the visual language stays
        --- consistent across the suite.
        if watchText then
            local dot = (Theme.col and Theme.col.skipreview and Theme.col.skipreview.dot)
                or {185, 140, 70, 255}
            local fontSize = ImGui.GetFontSize()
            local r = math.max(3, math.floor(fontSize * 0.30))
            local cx, cy = ImGui.GetCursorScreenPos()
            local centerY = cy + math.floor(fontSize * 0.5) + 1
            local centerX = cx + r + 2
            ImGui.GetWindowDrawList():AddCircleFilled(
                ImVec2(centerX, centerY), r,
                IM_COL32(dot[1], dot[2], dot[3], dot[4] or 255), 0)
            ImGui.Dummy(r * 2 + 6, 1)
            ImGui.SameLine(0, 0)
            ImGui.TextColored(0.78, 0.72, 0.58, 1.0, watchText)
        end
        if pendingN == 0 then
            wrappedText(0.62, 0.66, 0.74, 1.0,
                'No skipped items are waiting for review right now.')
            if (g.skipExpectedSkipTotal or 0) > 0 then
                wrappedText(0.45, 0.48, 0.55, 1.0,
                    string.format('%d expected skip%s hidden because matching INI rules already exist.',
                        g.skipExpectedSkipTotal, g.skipExpectedSkipTotal == 1 and '' or 's'))
            end
        end
        --- 3.8.73: Review stays focused on skipped items. INI/config/macro
        --- openers live under Setup and Tools.
        --- 3.8.65 (F): thin colored separator between the toolbar/header
        --- zone and the skip table. Before, the buttons and the table
        --- header butted directly against each other so the eye couldn't
        --- find the seam. The skipreview palette stays consistent with the
        --- promoted watcher dot above for one cohesive visual band.
        ImGui.Dummy(0, 3)
        do
            local sep = (Theme.col and Theme.col.skipreview and Theme.col.skipreview.sep)
                or {130, 95, 45, 90}
            ImGui.PushStyleColor(ImGuiCol.Separator,
                IM_COL32(sep[1], sep[2], sep[3], sep[4] or 90))
            ImGui.Separator()
            ImGui.PopStyleColor(1)
        end
        ImGui.Dummy(0, 2)
    else
        local headerLabel = string.format('Skip Review (%d)###skip_review_hdr', pendingN)

        if pendingN > 0 then
            ImGui.PushStyleColor(ImGuiCol.Header, IM_COL32(80, 60, 30, 200))
            ImGui.PushStyleColor(ImGuiCol.HeaderHovered, IM_COL32(100, 75, 40, 220))
        end
        local headerOpen = ImGui.CollapsingHeader(headerLabel)
        g.skipReviewOpen = headerOpen
        if pendingN > 0 then ImGui.PopStyleColor(2) end

        if not headerOpen then return end
    end

    ImGui.Dummy(0, 4)

    local totalN = g.skipDisplayTotal or pendingN
    local rawRows = g.skipDisplayRows or {}
    local function trimLower(v)
        return tostring(v or ''):lower():match('^%s*(.-)%s*$') or ''
    end
    local function reviewReasonBucket(reason)
        local r = trimLower(reason)
        if r:find('unlisted', 1, true) then return 'Unlisted' end
        if r:find('below', 1, true) then return 'Below $' end
        if r:find('lore', 1, true) then return 'Lore' end
        return 'Other'
    end
    local rows = rawRows
    if pageMode then
        local reasonOptions = { 'All', 'Unlisted', 'Below $', 'Lore', 'Other' }
        local filterText = trimLower(g.reviewFilterText)
        local reasonFilter = tostring(g.reviewFilterReason or 'All')
        g.reviewFilterShownText = ''
        g.reviewFilterSource = 'All'
        rows = {}
        for _, row in ipairs(rawRows) do
            local src = tostring(row.source or '')
            if src == '' then src = 'Unknown' end
            local reasonBucket = reviewReasonBucket(row.reason)
            local textOk = filterText == ''
                or trimLower(row.name):find(filterText, 1, true)
                or trimLower(row.itemId):find(filterText, 1, true)
                or trimLower(row.reason):find(filterText, 1, true)
                or trimLower(row.zone):find(filterText, 1, true)
                or trimLower(src):find(filterText, 1, true)
                or trimLower(row.iniFile):find(filterText, 1, true)
            local reasonOk = reasonFilter == 'All' or reasonBucket == reasonFilter
            if textOk and reasonOk then rows[#rows + 1] = row end
        end

        local countLabel = string.format('%d matching / %d actionable', #rows, totalN)
        ImGui.TextColored(0.62, 0.66, 0.74, 1.0, countLabel)
        ImGui.SameLine(0, 10)
        if Ui.buttonVariant('Reset filters##review_filter_reset', 'secondaryButton', 96, 0) then
            g.reviewFilterText = ''
            g.reviewFilterShownText = ''
            g.reviewFilterReason = 'All'
            g.reviewFilterSource = 'All'
            rows = rawRows
        end
        tip('Clear Review search and reason filters.')
        ImGui.Dummy(0, 4)
        local profileNow = cleanProfileName(g.reviewTargetProfile or ((getActiveProfile and getActiveProfile()) or 'turboloot.ini')) or 'turboloot.ini'
        ImGui.TextColored(0.58, 0.63, 0.72, 1.0, 'Target INI')
        ImGui.SameLine(0, 8)
        ImGui.PushItemWidth(math.max(160, Ui.availX(260) - 80))
        if ImGui.BeginCombo('##review_target_ini_combo', tostring(profileNow)) then
            local seenProfile = {}
            local function profileOpt(p)
                p = cleanProfileName(p)
                if not p or p == '' or seenProfile[p:lower()] then return end
                seenProfile[p:lower()] = true
                if ImGui.Selectable(p .. '##review_target_ini_' .. p, p == profileNow) then
                    g.skipIniTarget = p
                    g.reviewTargetProfile = p
                    if g.perCharProfile and g.selectedChar and g.selectedChar ~= '' then
                        g.charProfiles[g.selectedChar] = p
                    else
                        g.cachedProfile = p
                    end
                end
            end
            profileOpt(profileNow)
            for _, p in ipairs(g.profileList or {}) do profileOpt(p) end
            ImGui.EndCombo()
        end
        ImGui.PopItemWidth()
        ImGui.Dummy(0, 2)
        local function filterChipRow(label, current, options, idPrefix)
            ImGui.TextColored(0.58, 0.63, 0.72, 1.0, label)
            local nextValue = current
            local gap = 4
            for i, opt in ipairs(options or {}) do
                if i == 1 then ImGui.SameLine(0, 8) else ImGui.SameLine(0, gap) end
                local text = tostring(opt)
                local w = math.max(42, math.min(92, (#text * 7) + 18))
                if Ui.buttonVariant(text .. '##' .. idPrefix .. '_' .. text,
                    text == tostring(current) and 'primaryButton' or 'secondaryButton', w, 0) then
                    nextValue = text
                end
            end
            return nextValue
        end
        g.reviewFilterReason = filterChipRow('Reason', reasonFilter, reasonOptions, 'review_reason_filter')
        tip('Filter by why TurboLoot skipped the item.')
        ImGui.Dummy(0, 2)
        local gap = math.max(ImGui.GetStyle().ItemSpacing.x, 4)
        local availSearch = ImGui.GetContentRegionAvail()
        local clearW = 72
        local searchW = math.max(120, availSearch - clearW - gap)
        ImGui.PushItemWidth(searchW)
        if ImGui.InputTextWithHint then
            g.reviewFilterText = ImGui.InputTextWithHint('##review_filter_text', 'search items or reasons', tostring(g.reviewFilterText or ''))
        else
            g.reviewFilterText = ImGui.InputText('##review_filter_text', tostring(g.reviewFilterText or ''))
        end
        ImGui.PopItemWidth()
        tip('Search item name, item ID, reason, zone, source, or target INI.')
        ImGui.SameLine(0, gap)
        if Ui.buttonVariant('Clear##review_search_clear', 'secondaryButton', clearW, 0) then
            g.reviewFilterText = ''
        end
        tip('Clear search text.')
        ImGui.Dummy(0, 3)
    end
    --- Drop stale multi-select keys when rows refresh; keep one-key checkbox
    --- sets intact so Review checkboxes behave like Rule Packs multi-select.
    do
        local rk = {}
        for _, row in ipairs(rows) do rk[row.key] = true end
        if g.skipSelectionSet then
            for k in pairs(g.skipSelectionSet) do
                if not rk[k] then g.skipSelectionSet[k] = nil end
            end
            local n = 0
            for _ in pairs(g.skipSelectionSet) do
                n = n + 1
            end
            if n == 0 then
                g.skipSelectionSet = nil
            end
        end
        if g.skipSelectedKey and g.skipSelectedKey ~= '' and not rk[g.skipSelectedKey] then
            g.skipSelectedKey = nil
            g.skipIniTargetOverride = nil
            g.skipIniTargetOverridePath = nil
            g.skipSelectionSet = nil
        end
    end
    local avail, availH = ImGui.GetContentRegionAvail()
    local cursorItem = mq.TLO.Cursor.Name()
    local hasCursor = cursorItem and cursorItem ~= '' and cursorItem ~= 'NULL'
    local cursorIni = (getActiveProfile and getActiveProfile()) or 'turboloot.ini'
    local undoInfo = skipTracker.get_last_undo()
    local cursorUndo = g.lastCursorRuleUndo
    local hasSelectedSkip = false
    if g.skipSelectionSet then
        for _ in pairs(g.skipSelectionSet) do hasSelectedSkip = true break end
    end
    if not hasSelectedSkip then
        hasSelectedSkip = g.skipSelectedKey ~= nil and g.skipSelectedKey ~= ''
    end
    local hasPanelTarget = hasCursor or hasSelectedSkip
    if pageMode and hasPanelTarget and g.ensureWindowHeight then
        g.ensureWindowHeight(780)
    end
    local actionPanelH = 0
    local actionPanelContentH = 0  -- 1.3.0: what the panel needs vs. what it's given
    if pageMode then
        local style = ImGui.GetStyle()
        local rowH = Theme.layout.rowH or 22
        local textH = math.ceil(ImGui.GetFontSize())
        local spacingY = math.ceil(style.ItemSpacing.y)
        local paddingY = math.ceil(style.WindowPadding.y) * 2

        if g.slimGUI then
            actionPanelContentH = 360
        else
            --- 1.3.0 — verified row inventory (renderSkipReview body 5228-5636).
            --- Each rowH below maps to exactly one ImGui.Button row that
            --- actually renders in the action panel:
            ---   1) Summary row ("Cursor" / "Selected skip" / "Pick a target")
            ---   2) KEEP/SELL/BANK/TRIBUTE row
            ---   3) DESTROY/IGNORE/ANNOUNCE row
            ---   4) Reloot scope row (Single/Picks/Group/All)
            ---   5) Reload corpses button
            --- The textH lines: target-mode header, "Apply rule" (only if
            --- hasTarget — see 1.3.2 below), "Reloot:" label.
            --- Gap budget: sum of Dummy(0, N) baseline calls.
            ---
            --- Previous (v1.2.x) budget under-counted: it had rowH * 4 but
            --- the panel renders 5 rowHs baseline AND an additional rowH each
            --- for Quantity (if hasTarget), Ignore all (if pending >= 2),
            --- and Clear all (if pending >= 2). On a typical screen with
            --- ~96 pending skips, this was ~3 rows (~66px) short — exactly
            --- enough to push the bottom buttons off-screen.
            ---
            --- 1.3.2: empty state ("Pick a target" + instruction) compressed
            --- from 2 stacked lines + 1px Dummy to 1 inline SameLine row.
            --- "Apply rule" label now conditional on hasTarget. Trailing
            --- Dummy(0, 24) reduced to Dummy(0, 8). Net: ~50px reclaimed in
            --- the no-target state (the most common state on the Review
            --- tab), letting the list show ~2 more rows at the same window
            --- height.
            ---
            --- Baseline = 2 text lines (target header + Reloot:) + 5 rowHs
            --- + 28px gap budget (Dummies: 3+4+8+3+8 = 26, plus 2px buffer).
            actionPanelContentH = paddingY
                + (textH * 2)
                + (rowH * 5)
                + (spacingY * 8)
                + 28
            -- "Apply rule" label only renders when there's a target (1.3.2).
            if hasPanelTarget then
                actionPanelContentH = actionPanelContentH + textH + 7  -- label + Dummy(0,3) + Dummy(0,4)
            end
            -- Quantity row appears only when there's a target (line 5341).
            if hasPanelTarget then
                actionPanelContentH = actionPanelContentH + rowH + spacingY + 4
            end
            -- Undo bars (independent of each other; both can appear at once).
            if undoInfo then
                actionPanelContentH = actionPanelContentH + rowH + spacingY + 4
            end
            if cursorUndo then
                actionPanelContentH = actionPanelContentH + rowH + spacingY + 3
            end
            -- Multi-mode picks: reserve 2 rowHs (may wrap on many picks; the
            -- scrollbar fallback in the BeginChild flags covers overflow).
            if (g.actionRunMode or 'self') == 'multi' then
                actionPanelContentH = actionPanelContentH + (rowH * 2) + (spacingY * 3)
            end
            -- Ignore all + Clear all share the pendingN >= skipClearMinCount gate.
            -- BOTH render in pageMode when the gate opens (5566 + 5608).
            if pendingN >= (Theme.layout.skipClearMinCount or 2) then
                actionPanelContentH = actionPanelContentH + (rowH * 2) + (spacingY * 2) + 4
            end
            --- 1.3.1: 12px safety margin. Spacing math is rounded per-element
            --- via math.ceil, which over-counts by 0-1px per item. With ~10
            --- spacingY contributions, drift is small but non-zero. Adding
            --- 12px ensures the panel never trips its own scrollbar from
            --- accumulated rounding when content was supposed to fit.
            actionPanelContentH = actionPanelContentH + 12
        end
    end
    -- Responsive Review split (1.3.1):
    --   1. Action panel claims its FULL content height. No ceiling — the
    --      panel renders exactly what it needs, no scrollbar reserved.
    --   2. List takes whatever's left, with a floor of listMinH so it stays
    --      usable. The list ALREADY scrolls (it's a BeginChild with a table
    --      inside) so shrinking the list is graceful — the user sees fewer
    --      rows but can scroll for more.
    --   3. On windows so small that listMinH + actionPanelContentH would
    --      overflow availH, the action panel falls back to scrolling (its
    --      BeginChild has AlwaysVerticalScrollbar). This only triggers on
    --      truly tiny windows (~ <360px tall).
    -- v1.3.0 had a 60% ceiling that always-clipped the panel by ~1 button
    -- when content+scrollbar reservation exceeded the cap. v1.3.1 removes
    -- the ceiling entirely and lets the list shrink instead.
    local rowH = Theme.layout.rowH or 22
    local spacingY = math.ceil(ImGui.GetStyle().ItemSpacing.y)
    local clearAllH = (not pageMode) and pendingN >= (Theme.layout.skipClearMinCount or 2) and (rowH + spacingY + 8) or 0
    --- 1.3.2: bumped pageMode listMinH from 4 rows (~96px) to 5 rows
    --- (~120px). Combined with the ~50px reclaimed by compressing the
    --- empty-state header, the list now stays usable at smaller window
    --- heights without forcing the action panel to scroll. The panel
    --- scrollbar only engages on truly tiny windows (~ <380px tall) now.
    local listMinH = pageMode and math.max(120, (rowH * 5) + 10) or (#rows == 0 and 56 or 4)
    local listContentH = #rows > 0 and ((#rows + 1) * rowH + 10) or listMinH
    local listMaxH
    if pageMode then
        local availH_safe = math.max(220, math.floor(availH or 0))
        local footerReserveH = 56
        --- Page mode keeps the action area compact and table-first. The
        --- action body is no longer a large child panel, so reserve a stable
        --- compact footer/action budget instead of the old full-content estimate.
        actionPanelH = math.max(340, (rowH * 11) + (spacingY * 12) + 56)
        if (g.actionRunMode or 'self') == 'multi' then
            actionPanelH = actionPanelH + (rowH * 2) + (spacingY * 3)
        end
        if undoInfo then
            actionPanelH = actionPanelH + rowH + spacingY
        end
        if cursorUndo then
            actionPanelH = actionPanelH + rowH + spacingY
        end
        -- List gets the rest. If actionPanelH + listMinH exceeds availH,
        -- the action panel's own scrollbar kicks in (set in BeginChild flags
        -- below). This only happens on truly tiny windows.
        listMaxH = math.max(listMinH, availH_safe - actionPanelH - clearAllH - footerReserveH - 10)
        --- Hard cap on the action panel: never let it consume the entire
        --- window. If the window is so short that the panel would push the
        --- list below its floor, clamp the panel to (availH - listMinH) and
        --- let the panel scroll. Prevents the failure mode where panel
        --- claims everything and the list disappears.
        local panelMaxByWindow = availH_safe - listMinH - clearAllH - footerReserveH - 10
        if panelMaxByWindow > 0 and actionPanelH > panelMaxByWindow then
            actionPanelH = panelMaxByWindow
        end
    else
        listMaxH = g.slimGUI and 220 or 180
    end
    --- 1.3.3: in pageMode, list always fills the remaining height instead
    --- of capping at listContentH. Previously, when there were only a few
    --- skip rows the list stopped growing and left empty space below the
    --- action panel (between "Clear all skips" and the footer). That space
    --- now lives INSIDE the list's bordered region, which is more
    --- semantically honest ("this is the list area; few rows happen to
    --- exist") and gives the user a stable visual anchor as rows arrive.
    ---
    --- Non-pageMode (slim collapsing-header path) keeps content-sized
    --- behavior since it's not a full-page layout — it's a stack of items
    --- where extra empty space would look broken.
    local listH
    if pageMode then
        listH = math.max(listMinH, listMaxH)
        listH = math.min(listH, math.max(170, (rowH * 18) + 10))
    else
        listH = math.max(listMinH, math.min(math.max(listContentH, listMinH), listMaxH))
    end

    local drawRuleConfirmPopup
    do
        if #rows == 0 then
            ImGui.TextColored(0.45, 0.48, 0.55, 1.0, 'No pending skips.')
            ImGui.TextColored(0.38, 0.41, 0.48, 1.0,
                'Skips appear after TurboLoot journals them (logSkipListForIni).')
        else
            local function navToReviewCorpse(row)
                local corpseId = tostring((row and row.corpseId) or '')
                if corpseId == '' or corpseId == '0' then
                    g.statusMessage = 'No corpse ID stored for this skip row'
                    return
                end
                local src = tostring(row.source or '')
                local me = tostring(mq.TLO.Me.Name() or '')
                if src ~= '' and src ~= 'cli' and src:lower() ~= me:lower() then
                    mq.cmdf('/squelch /e3bct %s /target id %s', src, corpseId)
                    mq.cmdf('/timed 5 /squelch /e3bct %s /nav target', src)
                    g.statusMessage = 'Navigating ' .. src .. ' to corpse ' .. corpseId
                else
                    mq.cmdf('/squelch /target id %s', corpseId)
                    mq.cmd('/timed 5 /squelch /nav target')
                    g.statusMessage = 'Navigating to corpse ' .. corpseId
                end
            end

            local stretchFlag = ImGuiTableFlags.SizingStretchProp or ImGuiTableFlags.SizingStretchSame
            local tableFlags = ImGuiTableFlags.RowBg + ImGuiTableFlags.BordersInnerV + stretchFlag
            if ImGuiTableFlags.Sortable then
                tableFlags = tableFlags + ImGuiTableFlags.Sortable
            end
            if ImGuiTableFlags.ScrollY then
                tableFlags = tableFlags + ImGuiTableFlags.ScrollY
            end
            --- Sortable headers (same pattern as lua/find.lua): UserID identifies
            --- columns in TableGetSortSpecs; displayRows is a shallow copy sorted per frame.
            local SKIP_SORT_COL_ITEM = 0
            local SKIP_SORT_COL_ID = 1
            local SKIP_SORT_COL_REASON = 2
            local SKIP_SORT_COL_NAV = 3
            local displayRows = {}
            for i = 1, #rows do displayRows[i] = rows[i] end
            local skipSortSpecsRef = nil
            local function compareSkipDisplayRows(a, b)
                local sort_specs = skipSortSpecsRef
                if not sort_specs or sort_specs.SpecsCount < 1 then
                    return tostring(a.name or ''):lower() < tostring(b.name or ''):lower()
                end
                for n = 1, sort_specs.SpecsCount do
                    local sort_spec = sort_specs:Specs(n)
                    local delta = 0
                    local uid = sort_spec.ColumnUserID
                    if uid == SKIP_SORT_COL_ITEM then
                        local an = tostring(a.name or ''):lower()
                        local bn = tostring(b.name or ''):lower()
                        if an < bn then delta = -1 elseif bn < an then delta = 1 end
                    elseif uid == SKIP_SORT_COL_ID then
                        local aid = (a.itemId ~= '' and a.itemId ~= '0') and (tonumber(a.itemId) or 0) or 0
                        local bid = (b.itemId ~= '' and b.itemId ~= '0') and (tonumber(b.itemId) or 0) or 0
                        delta = aid - bid
                    elseif uid == SKIP_SORT_COL_REASON then
                        local ar = tostring(a.reason or ''):lower()
                        local br = tostring(b.reason or ''):lower()
                        if ar < br then delta = -1 elseif br < ar then delta = 1 end
                    elseif uid == SKIP_SORT_COL_NAV then
                        local ac = (a.corpseId ~= '' and a.corpseId ~= '0') and 1 or 0
                        local bc = (b.corpseId ~= '' and b.corpseId ~= '0') and 1 or 0
                        delta = ac - bc
                        if delta == 0 then
                            local an = tostring(a.name or ''):lower()
                            local bn = tostring(b.name or ''):lower()
                            if an < bn then delta = -1 elseif bn < an then delta = 1 end
                        end
                    end
                    if delta ~= 0 then
                        if ImGuiSortDirection and sort_spec.SortDirection == ImGuiSortDirection.Ascending then
                            return delta < 0
                        end
                        return delta > 0
                    end
                end
                return tostring(a.name or ''):lower() < tostring(b.name or ''):lower()
            end

            local tableStyle = Ui.pushTableStyle()
            if ImGui.BeginTable('##skip_table', 5, tableFlags, 0, listH) then
                ImGui.TableSetupScrollFreeze(0, 1)
                --- 3.8.65 (B): rebalanced column widths. Previously Item was
                --- 42%, INI was 20%, Reason was 28% — Item still truncated
                --- ("Mendin(") AND INI also truncated ("TurboLoot.ir" missing
                --- the 'i'), while Reason had visible slack. The longest
                --- reason string is "Lore (no destroy)" at 17 chars which
                --- fits comfortably in 24%. Fixed columns also trimmed:
                --- Seen 42 -> 36 (only ever shows "Nx" up to ~4 chars), ID
                --- 56 -> 48 (item IDs cap at 6 digits in EQ), Nav 42 -> 40.
                --- Net: ~16px reclaimed and redistributed to stretch columns.
                local COL = ImGuiTableColumnFlags
                local itemColFlags = COL.WidthStretch
                if COL.DefaultSort then itemColFlags = itemColFlags + COL.DefaultSort end
                ImGui.TableSetupColumn('*',      COL.WidthFixed,                     34)
                ImGui.TableSetupColumn('Item',   itemColFlags,                       0.58, SKIP_SORT_COL_ITEM)
                ImGui.TableSetupColumn('ID',     COL.WidthFixed,                     48,   SKIP_SORT_COL_ID)
                ImGui.TableSetupColumn('Reason', COL.WidthStretch,                   0.34, SKIP_SORT_COL_REASON)
                ImGui.TableSetupColumn('Nav',    COL.WidthFixed,                     40,   SKIP_SORT_COL_NAV)
                ImGui.TableHeadersRow()

                local sort_specs_ok, sort_specs = pcall(ImGui.TableGetSortSpecs)
                if sort_specs_ok and sort_specs and #displayRows > 1 then
                    skipSortSpecsRef = sort_specs
                    table.sort(displayRows, compareSkipDisplayRows)
                    skipSortSpecsRef = nil
                    if sort_specs.SpecsDirty then sort_specs.SpecsDirty = false end
                end

                local function inspectReviewRow(row)
                    local pending = skipTracker.get_pending()
                    for _, rec in ipairs(pending) do
                        if rec.key == row.key then
                            local link = skipTracker.get_link(rec)
                            if link ~= '' then mq.cmd('/executelink ' .. link)
                            else g.statusMessage = row.name .. ': no item link available' end
                            break
                        end
                    end
                end
                local function copyReviewIds(row)
                    local itemId = tostring((row and row.itemId) or '')
                    local corpseId = tostring((row and row.corpseId) or '')
                    local hasItem = itemId ~= '' and itemId ~= '0'
                    local hasCorpse = corpseId ~= '' and corpseId ~= '0'
                    if not hasItem and not hasCorpse then
                        g.statusMessage = 'No item or corpse/NPC ID available for ' .. tostring((row and row.name) or 'row')
                        return
                    end
                    local text
                    if hasItem and hasCorpse then
                        text = string.format('%s - Item ID: %s - (NPC ID: %s)', tostring(row.name or 'Item'), itemId, corpseId)
                    elseif hasItem then
                        text = string.format('%s - Item ID: %s', tostring(row.name or 'Item'), itemId)
                    else
                        text = string.format('%s - (NPC ID: %s)', tostring(row.name or 'Item'), corpseId)
                    end
                    local ok = pcall(ImGui.SetClipboardText, text)
                    g.statusMessage = ok and ('Copied ' .. text) or text
                end

                local ioCtrl = false
                do
                    local ok, io = pcall(ImGui.GetIO)
                    ioCtrl = ok and io and io.KeyCtrl == true
                    if not ioCtrl and ImGuiKey and ImGui.IsKeyDown then
                        local function keyDown(k)
                            if not k then return false end
                            local okKey, down = pcall(ImGui.IsKeyDown, k)
                            return okKey and down == true
                        end
                        ioCtrl = keyDown(ImGuiKey.ModCtrl) or keyDown(ImGuiKey.LeftCtrl) or keyDown(ImGuiKey.RightCtrl)
                    end
                end

                for _, row in ipairs(displayRows) do
                    local inMulti = g.skipSelectionSet and g.skipSelectionSet[row.key] == true
                    local primary = (g.skipSelectedKey == row.key)
                    local isSelected = inMulti or primary
                    local reasonLower = tostring(row.reason or ''):lower()
                    local reasonColor = {0.72, 0.72, 0.72, 1.0}
                    if reasonLower:find('below', 1, true) then
                        reasonColor = {0.62, 0.72, 0.82, 1.0}
                    elseif reasonLower:find('unlisted', 1, true) then
                        reasonColor = {0.78, 0.72, 0.52, 1.0}
                    elseif reasonLower:find('lore', 1, true) then
                        reasonColor = {0.72, 0.62, 0.88, 1.0}
                    end

                    ImGui.TableNextRow()
                    if primary then
                        if g.skipSelectionSet then
                            ImGui.TableSetBgColor(ImGuiTableBgTarget.RowBg0, IM_COL32(52, 76, 112, 92))
                        else
                            ImGui.TableSetBgColor(ImGuiTableBgTarget.RowBg0, IM_COL32(42, 62, 92, 78))
                        end
                    end

                    ImGui.TableSetColumnIndex(0)
                    local checked, changed = ImGui.Checkbox('##skip_chk_' .. row.key, inMulti)
                    if changed == nil then changed = checked ~= inMulti end
                    if changed then
                        if checked == true then
                            if not g.skipSelectionSet then g.skipSelectionSet = {} end
                            g.skipSelectionSet[row.key] = true
                            g.skipSelectedKey = row.key
                            if not g.skipIniTargetOverride then g.skipIniTarget = row.iniFile end
                        else
                            if g.skipSelectionSet then g.skipSelectionSet[row.key] = nil end
                            if g.skipSelectedKey == row.key then g.skipSelectedKey = nil end
                        end
                    end
                    tip('Check rows here, then press a TurboKey rule button.')

                    ImGui.TableSetColumnIndex(1)
                    local selectableFlags = ImGuiSelectableFlags and ImGuiSelectableFlags.SpanAllColumns or 0
                    if ImGui.Selectable(row.nameDisplay .. '##skip_' .. row.key, primary, selectableFlags) then
                        g.skipSelectedKey = row.key
                        if not g.skipIniTargetOverride then
                            g.skipIniTarget = row.iniFile
                        end
                    end
                    if ImGui.IsItemHovered() then
                        ImGui.BeginTooltip()
                        ImGui.Text(row.name)
                        if row.zone ~= '' then
                            ImGui.TextColored(0.5, 0.55, 0.65, 1.0, 'Zone: ' .. row.zone)
                        end
                        if row.source ~= '' then
                            ImGui.TextColored(0.55, 0.6, 0.5, 1.0, 'Skipped by: ' .. row.source)
                        end
                        ImGui.TextColored(0.52, 0.58, 0.70, 1.0, 'Seen: ' .. tostring(row.count) .. 'x')
                        if row.itemId ~= '' and row.itemId ~= '0' then
                            ImGui.TextColored(0.52, 0.58, 0.70, 1.0, 'Item ID: ' .. row.itemId)
                        end
                        if row.iniFile and row.iniFile ~= '' then
                            ImGui.TextColored(0.55, 0.78, 0.60, 1.0, 'INI: ' .. row.iniFile)
                        end
                        if row.corpseId ~= '' and row.corpseId ~= '0' then
                            ImGui.TextColored(0.52, 0.58, 0.70, 1.0, 'Corpse ID: ' .. row.corpseId)
                        end
                        ImGui.TextColored(0.45, 0.48, 0.52, 1.0,
                            'Click row: primary item  |  Checkboxes: multi-select  |  Double-click: inspect  |  Right-click: Nav / Go loot / rules')
                        ImGui.EndTooltip()
                    end
                    if ImGui.IsItemHovered() and ImGui.IsMouseDoubleClicked and ImGui.IsMouseDoubleClicked(0) then
                        inspectReviewRow(row)
                    end
                    if ImGui.BeginPopupContextItem('##review_row_ctx_' .. row.key) then
                        ImGui.Text(row.name)
                        ImGui.Separator()
                        Ui.menuItem('Inspect item##review_inspect_' .. row.key, function()
                            inspectReviewRow(row)
                        end, true, {120, 170, 235, 255})
                        local validItemId = tonumber(row.itemId) ~= nil and tonumber(row.itemId) > 0
                        Ui.menuItem('Open Alla item page##review_alla_' .. row.key, function()
                            TG.openAllaItemPage(row.itemId)
                        end, validItemId, {120, 170, 235, 255})
                        local validCorpseId = tostring(row.corpseId or '') ~= '' and tostring(row.corpseId or '') ~= '0'
                        Ui.menuItem('Copy ID##review_copy_ids_' .. row.key, function()
                            copyReviewIds(row)
                        end, validItemId or validCorpseId, {235, 190, 90, 255})
                        Ui.menuItem('Nav to corpse##review_nav_corpse_' .. row.key, function()
                            navToReviewCorpse(row)
                        end, validCorpseId, {95, 210, 145, 255})
                        TG.renderReviewGoLootMenu(row, 'review_goloots_' .. row.key, function(msg)
                            g.statusMessage = msg
                        end)
                        Ui.menuItem('Add to hunting list##review_hunt_' .. row.key, function()
                            TG.setHuntingTarget(row.name, 'Review')
                        end, true, {95, 210, 145, 255})
                        Ui.menuItem('Dismiss from review##review_dismiss_' .. row.key, function()
                            if skipTracker.dismiss(row.name) then
                                g.skipSelectedKey = nil
                                g.skipSelectionSet = nil
                                g.skipDisplayRows = nil
                                g.statusMessage = tostring(row.name or 'Item') .. ' dismissed'
                            end
                        end, true, {230, 120, 110, 255})
                        if ImGui.BeginMenu('Apply rule##review_apply_' .. row.key) then
                            for _, lab in ipairs({ 'KEEP', 'SELL', 'BANK', 'TRIBUTE', 'DESTROY', 'IGNORE', 'ANNOUNCE' }) do
                                if ImGui.MenuItem(lab) then TG.applySkipRule(row.name, lab) end
                            end
                            ImGui.EndMenu()
                        end
                        ImGui.Separator()
                        Ui.menuItem('Open target INI##review_open_ini_' .. row.key, function()
                            if row.iniPath and row.iniPath ~= '' then shellOpenFile(row.iniPath)
                            else g.statusMessage = 'No target INI path available for ' .. row.name end
                        end, row.iniPath and row.iniPath ~= '', {160, 185, 230, 255})
                        ImGui.EndPopup()
                    end

                    ImGui.TableSetColumnIndex(2)
                    ImGui.TextColored(0.62, 0.68, 0.78, 1.0, (row.itemId ~= '' and row.itemId ~= '0') and row.itemId or '-')

                    ImGui.TableSetColumnIndex(3)
                    ImGui.TextColored(reasonColor[1], reasonColor[2], reasonColor[3], reasonColor[4], row.reason)

                    ImGui.TableSetColumnIndex(4)
                    local canNav = row.corpseId ~= '' and row.corpseId ~= '0'
                    if not canNav then ImGui.BeginDisabled() end
                    if ImGui.SmallButton('Nav##skipnav_' .. row.key) then
                        navToReviewCorpse(row)
                    end
                    if not canNav then ImGui.EndDisabled() end
                    if ImGui.IsItemHovered() then
                        ImGui.BeginTooltip()
                        if canNav then
                            ImGui.Text('Target corpse and /nav target.')
                        else
                            ImGui.Text('No corpse ID saved for this row.')
                        end
                        ImGui.EndTooltip()
                    end
                end

                ImGui.EndTable()
            end
            Ui.popTableStyle(tableStyle)
        end
        if totalN > #rawRows then
            ImGui.TextColored(0.45, 0.48, 0.52, 1.0,
                string.format('... and %d more (showing top 500)', totalN - #rawRows))
        end
        if (g.skipExpectedSkipTotal or 0) > 0 then
            ImGui.TextColored(0.45, 0.48, 0.52, 1.0,
                string.format('%d expected skip%s hidden (existing INI rule + expected reason).',
                    g.skipExpectedSkipTotal, g.skipExpectedSkipTotal == 1 and '' or 's'))
        end
    end

    local function skipEffectiveKeySet()
        if g.skipSelectionSet then
            local n = 0
            for _ in pairs(g.skipSelectionSet) do n = n + 1 end
            if n > 0 then return g.skipSelectionSet end
        end
        if g.skipSelectedKey and g.skipSelectedKey ~= '' then
            return { [g.skipSelectedKey] = true }
        end
        return nil
    end

    local function collectSkipBatchRows()
        local ek = skipEffectiveKeySet()
        if not ek then return {} end
        local out = {}
        for _, row in ipairs(rows) do
            if ek[row.key] then out[#out + 1] = row end
        end
        table.sort(out, function(a, b)
            return tostring(a.name or ''):lower() < tostring(b.name or ''):lower()
        end)
        return out
    end

    local batchRows = collectSkipBatchRows()
    local selRow = nil
    for _, row in ipairs(batchRows) do
        if row.key == g.skipSelectedKey then
            selRow = row
            break
        end
    end
    selRow = selRow or batchRows[1]

    if hasSelectedSkip and #batchRows == 0 then
        g.skipSelectedKey = nil
        g.skipSelectionSet = nil
        g.skipIniTargetOverride = nil
        g.skipIniTargetOverridePath = nil
    end

    -- v3.8.49: Always render the action panel with TurboKey rule buttons,
    -- regardless of whether a skip is selected or an item is on the cursor.
    -- Buttons are disabled when no target exists, so new users see what
    -- Review does on first visit instead of having to click a row to
    -- discover the rule UI. Header text covers both list-click and
    -- cursor paths so the dual workflow is visible up front.
    local targetMode
    if hasCursor then
        targetMode = 'cursor'
    elseif selRow then
        targetMode = 'skip'
    else
        targetMode = 'none'
    end
    g.reviewRuleTarget = targetMode
    local hasTarget = (targetMode ~= 'none')

    local function clearActionableSkips()
        local cleared = TG.clearActionablePendingSkips()
        g.skipSelectedKey = nil
        g.skipSelectionSet = nil
        g.skipIniTargetOverride = nil
        g.skipIniTargetOverridePath = nil
        g.skipDisplayRows = nil
        rebuildSkipDisplayRows()
        g.skipReviewOpen = true
        g.ignoreAllStagedAt = 0
        g.ignoreAllStagedSnapshot = nil
        g.statusMessage = string.format('%d actionable skip%s cleared', cleared, cleared == 1 and '' or 's')
    end

    do
        --- Avoid a BeginChild wrapper here; MQ Next has been faulting in EndChild.
        local skipActionPanelBody = false

        if not skipActionPanelBody then

        local RULE_BTN_W = TG.RULE_BTN_W
        local SLIM_RULE_BTN_H = TG.SLIM_RULE_BTN_H
        local cooldownOk = (mq.gettime() - g.lastSkipApplyMS) >= 500
        local targetIni = selRow and (g.skipIniTargetOverride or selRow.iniFile) or cursorIni
        local targetIniPath = selRow and (g.skipIniTargetOverridePath or selRow.iniPath) or nil
        local rw = g.slimGUI and -1 or RULE_BTN_W
        local rh = g.slimGUI and SLIM_RULE_BTN_H or ACTION_BTN_H

        local function applySkipRuleTo(itemName, label, iniPath, iniLabel, deferCleanup)
            deferCleanup = deferCleanup == true
            if not itemName or itemName == '' then return end
            if TG.requireSharedControl and not TG.requireSharedControl('Review rule edit') then return end
            local ok, info = skipTracker.apply_rule(itemName, label, iniPath)
            g.lastSkipApplyMS = mq.gettime()
            if not deferCleanup then
                g.skipSelectedKey = nil
                g.skipSelectionSet = nil
                g.skipIniTargetOverride = nil
                g.skipIniTargetOverridePath = nil
                g.skipDisplayRows = nil
            end
            if ok then
                if not deferCleanup then
                    local iniForMsg = iniLabel or targetIni
                    if info and info.ini_path then
                        iniForMsg = info.ini_path:match('[^\\/]+$') or info.ini_path
                    end
                    local orphans = (info and info.deleted_orphans) or {}
                    if #orphans > 0 then
                        g.statusMessage = string.format('%s = %s in %s (cleaned %d orphan%s)',
                            itemName, label, iniForMsg,
                            #orphans, #orphans == 1 and '' or 's')
                    else
                        g.statusMessage = string.format('%s = %s in %s', itemName, label, iniForMsg)
                    end
                end
            else
                g.statusMessage = string.format('Failed to apply %s to %s', label, itemName)
            end
        end

        local function applySkipRule(label)
            local nBatch = #batchRows
            if nBatch == 0 then return end
            skipTracker.persist_batch_begin()
            for i, brow in ipairs(batchRows) do
                local path = brow.iniPath
                local file = brow.iniFile
                if nBatch == 1 then
                    path = g.skipIniTargetOverridePath or brow.iniPath
                    file = g.skipIniTargetOverride or brow.iniFile
                end
                applySkipRuleTo(brow.name, label, path, file, i < nBatch)
            end
            skipTracker.persist_batch_end()
            if nBatch > 1 then
                g.statusMessage = string.format('Applied %s to %d skip rows', label, nBatch)
            end
        end

        local function applyCursorRule(label, destroyCursor, itemNameOverride)
            if destroyCursor == nil and g.confirmSingleReviewRules == false then
                destroyCursor = false
            end
            applyTurboKeyRule(label, { destroyCursor = destroyCursor, itemName = itemNameOverride or cursorItem })
            g.lastSkipApplyMS = mq.gettime()
        end

        local function runRule(label)
            if targetMode == 'cursor' then
                applyCursorRule(label, nil, cursorItem)
            elseif targetMode == 'skip' then
                applySkipRule(label)
            end
            -- targetMode == 'none' is unreachable when buttons are disabled,
            -- but safe-default to no-op if it ever leaks through.
        end

        local function runQuantityRule()
            local num = tonumber(g.turboKeyQty)
            if not num or num <= 0 then
                g.statusMessage = 'Enter a valid quantity.'
                return
            end
            runRule(tostring(math.floor(num)))
        end

        local function stageReviewRuleConfirm(label)
            local snap = {}
            if targetMode == 'skip' then
                local nBatch = #batchRows
                for _, r in ipairs(batchRows) do
                    local path = r.iniPath
                    local file = r.iniFile
                    if nBatch == 1 then
                        path = g.skipIniTargetOverridePath or r.iniPath
                        file = g.skipIniTargetOverride or r.iniFile
                    end
                    snap[#snap + 1] = { name = r.name, iniPath = path, iniFile = file }
                end
            end
            g.reviewConfirm = {
                label = label,
                targetMode = targetMode,
                cursorItem = cursorItem,
                cursorIni = cursorIni,
                skipName = (#batchRows == 1 and selRow) and selRow.name or nil,
                skipIniPath = (#batchRows == 1 and selRow) and targetIniPath or nil,
                skipIni = (#batchRows == 1 and selRow) and targetIni or nil,
                skipBatch = (#snap > 0) and snap or nil,
            }
            g.reviewConfirmOpenRequested = true
        end

        local rulesEnabled = hasTarget and cooldownOk
        --- 3.8.53: hover detection while ImGui.BeginDisabled is active.
        --- AllowWhenDisabled lets us show a "what to do" tooltip on the
        --- KEEP/SELL/BANK/TRIBUTE/DESTROY/IGNORE buttons when no target is
        --- selected — previously they had no tooltip in that state, so the
        --- Review tab felt undocumented to new users.
        local SR_HOVERED_ALLOW_DISABLED = (ImGuiHoveredFlags and ImGuiHoveredFlags.AllowWhenDisabled) or 128

        local function srTipNoTarget(label)
            if hasTarget then return end
            if not ImGui.IsItemHovered(SR_HOVERED_ALLOW_DISABLED) then return end
            ImGui.BeginTooltip()
            ImGui.Text(label)
            ImGui.TextColored(0.92, 0.45, 0.40, 1.0, 'Select a skip row or put an item on your cursor first.')
            ImGui.EndTooltip()
        end

        local function srBtn(label, r, gb, b, tt)
            if not rulesEnabled then ImGui.BeginDisabled() end
            ImGui.PushStyleColor(ImGuiCol.Button, IM_COL32(r, gb, b, 255))
            ImGui.PushStyleColor(ImGuiCol.ButtonHovered,
                IM_COL32(math.min(r+25,255), math.min(gb+25,255), math.min(b+25,255), 255))
            if ImGui.Button(label .. '##sr_' .. label, rw, rh) then runRule(label) end
            ImGui.PopStyleColor(2)
            if not rulesEnabled then ImGui.EndDisabled() end
            if tt and hasTarget then tip(tt) else srTipNoTarget(label) end
        end

        local function srBtnF(label, r, gb, b, tt, w)
            if not rulesEnabled then ImGui.BeginDisabled() end
            ImGui.PushStyleColor(ImGuiCol.Button, IM_COL32(r, gb, b, 255))
            ImGui.PushStyleColor(ImGuiCol.ButtonHovered,
                IM_COL32(math.min(r+25,255), math.min(gb+25,255), math.min(b+25,255), 255))
            if ImGui.Button(label .. '##sr_' .. label, w, ACTION_BTN_H) then runRule(label) end
            ImGui.PopStyleColor(2)
            if not rulesEnabled then ImGui.EndDisabled() end
            if tt and hasTarget then tip(tt) else srTipNoTarget(label) end
        end

        local function srRuleButtonRaw(label, r, gb, b, tt, w, h)
            if not rulesEnabled then ImGui.BeginDisabled() end
            ImGui.PushStyleColor(ImGuiCol.Button, IM_COL32(r, gb, b, 255))
            ImGui.PushStyleColor(ImGuiCol.ButtonHovered,
                IM_COL32(math.min(r+25,255), math.min(gb+25,255), math.min(b+25,255), 255))
            local clicked = ImGui.Button(label .. '##sr_' .. label, w, h)
            ImGui.PopStyleColor(2)
            if not rulesEnabled then ImGui.EndDisabled() end
            if tt and hasTarget then tip(tt) else srTipNoTarget(label) end
            return clicked
        end

        local function srRuleButton(label, r, gb, b, tt)
            if srRuleButtonRaw(label, r, gb, b, tt, rw, rh) then
                local upper = label:upper()
                if g.confirmSingleReviewRules == false and (
                    (targetMode == 'skip' and (upper == 'DESTROY' or upper == 'IGNORE'))
                    or (targetMode == 'cursor' and DESTROY_RULES[upper])
                ) then
                    runRule(label)
                elseif upper == 'DESTROY' or upper == 'IGNORE' or (targetMode == 'cursor' and DESTROY_RULES[upper]) then
                    stageReviewRuleConfirm(label)
                else
                    runRule(label)
                end
            end
        end

        local function srRuleButtonF(label, r, gb, b, tt, w)
            if srRuleButtonRaw(label, r, gb, b, tt, w, ACTION_BTN_H) then
                local upper = label:upper()
                if g.confirmSingleReviewRules == false and (
                    (targetMode == 'skip' and (upper == 'DESTROY' or upper == 'IGNORE'))
                    or (targetMode == 'cursor' and DESTROY_RULES[upper])
                ) then
                    runRule(label)
                elseif upper == 'DESTROY' or upper == 'IGNORE' or (targetMode == 'cursor' and DESTROY_RULES[upper]) then
                    stageReviewRuleConfirm(label)
                else
                    runRule(label)
                end
            end
        end
        local function reviewSelectVisibleRows()
            g.skipSelectionSet = {}
            for _, row in ipairs(rows or {}) do
                if row.key then g.skipSelectionSet[row.key] = true end
            end
            g.skipSelectedKey = rows[1] and rows[1].key or nil
            g.statusMessage = string.format('Selected %d visible Review row(s).', #(rows or {}))
        end
        local function reviewClearVisibleRows()
            if g.skipSelectionSet then
                for _, row in ipairs(rows or {}) do
                    if row.key then g.skipSelectionSet[row.key] = nil end
                end
            end
            g.skipSelectedKey = nil
            g.statusMessage = 'Cleared visible Review rows.'
        end

        local function commitReviewConfirm(destroyCursor)
            local pending = g.reviewConfirm
            if type(pending) ~= 'table' then return end
            if pending.targetMode == 'cursor' then
                applyCursorRule(pending.label, destroyCursor, pending.cursorItem)
            elseif pending.targetMode == 'skip' then
                local batch = pending.skipBatch
                if type(batch) == 'table' and #batch > 0 then
                    skipTracker.persist_batch_begin()
                    local last = #batch
                    for i, brow in ipairs(batch) do
                        applySkipRuleTo(brow.name, pending.label, brow.iniPath, brow.iniFile, i < last)
                    end
                    skipTracker.persist_batch_end()
                    if last > 1 then
                        g.statusMessage = string.format('Applied %s to %d skip rows', pending.label, last)
                    end
                elseif pending.skipName and pending.skipName ~= '' then
                    applySkipRuleTo(pending.skipName, pending.label, pending.skipIniPath, pending.skipIni)
                end
            end
            g.reviewConfirm = nil
        end

        drawRuleConfirmPopup = function()
            if g.confirmSingleReviewRules == false then
                g.reviewConfirmOpenRequested = false
                g.reviewConfirm = nil
                return
            end
            if g.reviewConfirmOpenRequested then
                g.reviewConfirmOpenRequested = false
                ImGui.OpenPopup('Confirm Review Rule')
            end
            ImGui.SetNextWindowSize(420, 0, ImGuiCond.Appearing)
            if ImGui.BeginPopupModal('Confirm Review Rule') then
                local pending = g.reviewConfirm or {}
                local label = pending.label or 'rule'
                ImGui.Text('Confirm ' .. label)
                ImGui.Separator()
                if pending.targetMode == 'cursor' then
                    ImGui.Text('This will write the rule for the item on your cursor.')
                    ImGui.Text('Choose whether to keep or destroy the cursor item.')
                elseif pending.targetMode == 'skip' then
                    local nb = type(pending.skipBatch) == 'table' and #pending.skipBatch or 0
                    local lu = tostring(pending.label or 'rule'):upper()
                    if nb > 1 then
                        ImGui.Text(string.format('This will write %s rules for %d selected skip rows (each row\'s INI).',
                            lu, nb))
                    elseif lu == 'DESTROY' then
                        ImGui.Text('This will write a DESTROY rule for the selected skip item.')
                    elseif lu == 'IGNORE' then
                        ImGui.Text('This will write an IGNORE rule for the selected skip item.')
                    else
                        ImGui.Text('Confirm this Review action.')
                    end
                else
                    ImGui.Text('Confirm this Review action.')
                end
                ImGui.Dummy(0, 6)
                if pending.targetMode == 'cursor' then
                    local btnSp = ImGui.GetStyle().ItemSpacing.x
                    local btnW = math.floor((ImGui.GetContentRegionAvail() - (btnSp * 2)) / 3)
                    if ImGui.Button('Cancel##review_rule_modal', btnW, ACTION_BTN_H) then
                        g.reviewConfirm = nil
                        g.reviewConfirmOpenRequested = false
                        ImGui.CloseCurrentPopup()
                    end
                    ImGui.SameLine()
                    if ImGui.Button('Set rule##review_rule_modal', btnW, ACTION_BTN_H) then
                        commitReviewConfirm(false)
                        ImGui.CloseCurrentPopup()
                    end
                    ImGui.SameLine()
                    if ImGui.Button('Set + destroy##review_rule_modal', btnW, ACTION_BTN_H) then
                        commitReviewConfirm(true)
                        ImGui.CloseCurrentPopup()
                    end
                else
                    if ImGui.Button('Set rule##review_rule_modal', 120, ACTION_BTN_H) then
                        commitReviewConfirm()
                        ImGui.CloseCurrentPopup()
                    end
                    ImGui.SameLine()
                    if ImGui.Button('Cancel##review_rule_modal', 120, ACTION_BTN_H) then
                        g.reviewConfirm = nil
                        g.reviewConfirmOpenRequested = false
                        ImGui.CloseCurrentPopup()
                    end
                end
                ImGui.EndPopup()
            end
        end

        --- 3.8.54: turboKeyRGB palette split — SELL and BANK now have
        --- distinct slots (was: both routed through `trade`). KEEP became
        --- blue, SELL took the old KEEP green, BANK took the old TRIBUTE
        --- purple, TRIBUTE moved to gold. Aligns the buttons with chat color
        --- codes (\ag SELL, \ap BANK, \ay TRIBUTE, \ar DESTROY).
        --- Palette: tolerate missing keys (stale theme.lua before sell/bank split) so Review never nil-indexes.
        local TK = TurboKeyRGB
        if type(TK) ~= 'table' then TK = Theme.col.turboKeyRGB end
        if type(TK) ~= 'table' then TK = {} end
        local K  = TK.keep    or {70, 100, 150}
        local SE = TK.sell    or {60, 120, 80}
        local BA = TK.bank    or TK.trade or {90, 82, 130}
        local D  = TK.destroy or {145, 60, 55}
        local S  = TK.skip    or {55, 58, 65}
        local TR = TK.tribute or {130, 95, 35}
        --- 3.8.57: ANNOUNCE rule — TEAL/CYAN. Skip-class rule (item stays on
        --- corpse, never enters review queue) with a forced chat broadcast so
        --- another character can come grab it. Falls back gracefully if a
        --- stale theme.lua (pre-1.4.1) lacks the key.
        local AN = TK.announce or {55, 130, 140}
        local function compactLabel(text, maxLen)
            text = tostring(text or '')
            maxLen = maxLen or 44
            if #text <= maxLen then return text end
            return text:sub(1, maxLen - 2) .. '..'
        end
        local function drawReviewSummaryRow(itemText, iniText, sourceText)
            ImGui.TextColored(Colors.turbokey.label[1], Colors.turbokey.label[2], Colors.turbokey.label[3], 1.0,
                compactLabel(itemText, 26))
            ImGui.SameLine(0, 6)
            ImGui.TextColored(0.45, 0.65, 0.45, 1.0, '-> ' .. compactLabel(iniText, 18))
            if sourceText and sourceText ~= '' then
                ImGui.SameLine(0, 6)
                ImGui.TextColored(0.45, 0.48, 0.52, 1.0, '(' .. compactLabel(sourceText, 12) .. ')')
            end
        end
        local targetDesc
        if targetMode == 'cursor' then
            targetDesc = cursorItem .. ' in active INI ' .. cursorIni
        elseif targetMode == 'skip' then
            local nb = #batchRows
            if nb > 1 then
                targetDesc = string.format('%d selected skips (each row\'s INI)', nb)
            elseif selRow then
                targetDesc = selRow.name .. ' to ' .. targetIni
            else
                targetDesc = 'selected skip'
            end
        else
            targetDesc = 'selected item'  -- fallback only; tooltips suppressed when no target
        end

        if pageMode then
            local selN = #batchRows
            local pageTargetText = selN > 0 and string.format('Selected: %d item%s', selN, selN == 1 and '' or 's') or 'Selected: none'
            if targetMode == 'cursor' then
                pageTargetText = 'Cursor: ' .. compactLabel(cursorItem, 22)
            end
            ImGui.TextColored(0.62, 0.70, 0.82, 1.0, pageTargetText)
            ImGui.SameLine()
            ImGui.TextDisabled('Qty')
            ImGui.SameLine()
            ImGui.PushItemWidth(48)
            g.turboKeyQty = ImGui.InputText('##sr_qty_rule_top', g.turboKeyQty)
            ImGui.PopItemWidth()
            ImGui.SameLine()
            if not rulesEnabled then ImGui.BeginDisabled() end
            if Ui.buttonVariant('Set##sr_qty_set_top', 'secondaryButton', 44, ACTION_BTN_H) then
                runQuantityRule()
            end
            if not rulesEnabled then ImGui.EndDisabled() end
            tip('Apply this quantity rule to checked Review rows.')
            ImGui.SameLine()
            if not rulesEnabled then ImGui.BeginDisabled() end
            if Ui.buttonVariant('1##sr_qty_1_top', 'secondaryButton', 28, ACTION_BTN_H) then
                g.turboKeyQty = '1'
                if rulesEnabled then
                    runQuantityRule()
                else
                    g.statusMessage = 'Quantity set to 1. Select one or more Review rows to apply it.'
                end
            end
            if not rulesEnabled then ImGui.EndDisabled() end
            if rulesEnabled then tip('Set quantity to 1 and apply it to checked Review rows.') else srTipNoTarget('Quantity 1') end
            ImGui.SameLine()
            ImGui.TextDisabled('Click rows to toggle selection')
            ImGui.SameLine()
            if targetMode == 'skip' and #batchRows > 0 then
                if Ui.buttonVariant('Dismiss##sr_page_dismiss', 'secondaryButton', 74, ACTION_BTN_H) then
                    skipTracker.persist_batch_begin()
                    for _, br in ipairs(batchRows) do skipTracker.dismiss(br.name) end
                    skipTracker.persist_batch_end()
                    g.skipSelectedKey = nil
                    g.skipSelectionSet = nil
                    g.skipDisplayRows = nil
                    g.statusMessage = (#batchRows > 1) and string.format('Dismissed %d skips', #batchRows) or ((selRow and selRow.name or 'Item') .. ' dismissed')
                end
                tip('Hide selected Review row(s) without making rules.')
            end
        end

        if not pageMode then
        ImGui.Dummy(0, 1)
        if targetMode == 'cursor' then
            ImGui.TextColored(0.65, 0.68, 0.75, 1.0, 'Cursor')
            ImGui.Dummy(0, 1)
            drawReviewSummaryRow(cursorItem, cursorIni, nil)
        elseif targetMode == 'skip' then
            local skipBatchN = #batchRows
            local hdrBtnSp = ImGui.GetStyle().ItemSpacing.x
            local pickBtnW, dismissBtnW = 64, 66
            local hdrBtnRowW = pickBtnW + hdrBtnSp + dismissBtnW
            ImGui.TextColored(0.65, 0.68, 0.75, 1.0,
                skipBatchN > 1 and string.format('Selected skips (%d)', skipBatchN) or 'Selected skip')
            ImGui.Dummy(0, 1)
            if skipBatchN > 1 then
                ImGui.TextColored(0.55, 0.58, 0.65, 1.0,
                    string.format('%d items — rules apply to each row\'s INI. Accent: %s',
                        skipBatchN, compactLabel(selRow and selRow.name or '', 22)))
            else
                drawReviewSummaryRow(selRow.name, targetIni, selRow.source)
            end
            ImGui.SameLine()
            local rightEdge = ImGui.GetCursorPosX() + math.max(0, ImGui.GetContentRegionAvail() - hdrBtnRowW)
            if rightEdge > ImGui.GetCursorPosX() then ImGui.SetCursorPosX(rightEdge) end
            if skipBatchN > 1 then ImGui.BeginDisabled() end
            if ImGui.SmallButton('Pick INI##ini_pick') then ImGui.OpenPopup('skip_ini_picker') end
            if skipBatchN > 1 then ImGui.EndDisabled() end
            tip(skipBatchN > 1
                and 'INI override applies to a single selection. Multi-select uses each row\'s INI.'
                or 'Choose a different INI for this selected skip rule.')
            ImGui.SameLine()
            ImGui.PushStyleColor(ImGuiCol.Button, IM_COL32(55, 55, 60, 255))
            ImGui.PushStyleColor(ImGuiCol.ButtonHovered, IM_COL32(75, 75, 80, 255))
            if ImGui.SmallButton('Dismiss##sr') then
                local dismissed = 0
                skipTracker.persist_batch_begin()
                for _, br in ipairs(batchRows) do
                    if skipTracker.dismiss(br.name) then dismissed = dismissed + 1 end
                end
                skipTracker.persist_batch_end()
                g.skipSelectedKey = nil
                g.skipSelectionSet = nil
                g.skipIniTargetOverride = nil
                g.skipIniTargetOverridePath = nil
                g.skipDisplayRows = nil
                g.statusMessage = skipBatchN > 1
                    and string.format('Dismissed %d skips', dismissed)
                    or (selRow.name .. ' dismissed')
            end
            ImGui.PopStyleColor(2)
            tip(skipBatchN > 1 and 'Hide all selected skips without making rules.'
                or 'Hide this item without making a rule.')

            if ImGui.BeginPopup('skip_ini_picker') then
                ImGui.Text('Write rule to:')
                ImGui.Separator()
                if ImGui.Selectable('auto: ' .. selRow.iniFile .. '##auto', not g.skipIniTargetOverride) then
                    g.skipIniTargetOverride = nil
                    g.skipIniTargetOverridePath = nil
                    g.skipIniTarget = selRow.iniFile
                end
                local inisSeen = {}
                for _, iniVal in pairs(g.charProfiles or {}) do
                    if type(iniVal) == 'string' and iniVal ~= '' and not inisSeen[iniVal] then
                        inisSeen[iniVal] = true
                        if ImGui.Selectable(iniVal .. '##iniopt', g.skipIniTargetOverride == iniVal) then
                            g.skipIniTargetOverride = iniVal
                            g.skipIniTargetOverridePath = resolveTurbolootIniPathForProfile
                                and (resolveTurbolootIniPathForProfile(iniVal)) or nil
                            g.skipIniTarget = iniVal
                            TG.skipDisplayRows = nil
                        end
                    end
                end
                ImGui.EndPopup()
            end
        else
            --- targetMode == 'none' — no skip selected, no cursor item.
            --- 1.3.2: compressed from 3 lines (label + gap + wrapped text)
            --- to 1 line (label + inline instruction on SameLine). Saves
            --- ~30px of vertical space in the most common state (no
            --- selection). The instruction is short enough to fit on most
            --- widths; on very narrow widths it wraps naturally without
            --- needing wrappedText since SameLine respects content region.
            ImGui.TextColored(0.65, 0.68, 0.75, 1.0, 'Select row/item')
            ImGui.SameLine(0, 8)
            ImGui.TextColored(0.55, 0.58, 0.65, 1.0,
                'Use checkboxes for multi-select; cursor works.')
        end
        end

        --- 1.3.2: "Apply rule" label is only useful when there IS a target
        --- (then it disambiguates "this row of buttons applies a rule to
        --- the target above"). In the empty state, the compressed inline
        --- header "Pick a target — click a row above..." already provides
        --- context, and the disabled rule buttons obviously don't need a
        --- separate "Apply rule" label. Skipping the label here saves
        --- ~20px (label height + Dummy) in the empty state, which is when
        --- the user most needs the list real estate to find a row to click.
        if hasTarget and not pageMode then
            ImGui.Dummy(0, 3)
            ImGui.TextColored(0.65, 0.68, 0.75, 1.0, 'Apply rule')
            ImGui.Dummy(0, 4)
        elseif not pageMode then
            ImGui.Dummy(0, 4)
        end
        if pageMode and hasTarget then
            ImGui.Dummy(0, 4)
            ImGui.Separator()
            ImGui.TextColored(0.65, 0.68, 0.75, 1.0, 'Loot tags')
            ImGui.Dummy(0, 4)
        end
        --- 3.8.57: ANNOUNCE rule — skip-class (item stays on corpse) with a
        --- forced chat announce so another character can grab it. Slim adds it
        --- at the end of the stacked button list; Full repacks the bottom row
        --- from 2-column (DESTROY/IGNORE) to 3-column (DESTROY/IGNORE/ANNOUNCE).
        --- Tooltip text is intentionally identical between layouts so the rule
        --- semantic stays one canonical sentence wherever the user encounters it.
        local ANNOUNCE_TIP = "Don't loot. Announce in chat so another character can grab it. Never appears in skip review."
        if g.slimGUI then
            srRuleButton('KEEP',     K[1],K[2],K[3],   'Always loot ' .. targetDesc)
            srRuleButton('SELL',     SE[1],SE[2],SE[3],'Loot and sell ' .. targetDesc)
            srRuleButton('BANK',     BA[1],BA[2],BA[3],'Loot and bank ' .. targetDesc)
            srRuleButton('TRIBUTE',  TR[1],TR[2],TR[3],'Loot and tribute ' .. targetDesc)
            srRuleButton('DESTROY',  D[1],D[2],D[3],   'Always destroy ' .. targetDesc)
            srRuleButton('IGNORE',   S[1],S[2],S[3],   'Ignore ' .. targetDesc)
            srRuleButton('ANNOUNCE', AN[1],AN[2],AN[3],ANNOUNCE_TIP)
        else
            ImGui.Dummy(0, 1)
            local tkAvail = ImGui.GetContentRegionAvail()
            local tkSp = math.max(ImGui.GetStyle().ItemSpacing.x, 6)
            local tkW4 = math.max(72, math.floor((tkAvail - tkSp * 3) / 4))
            local tkW3 = math.max(72, math.floor((tkAvail - tkSp * 2) / 3))
            srRuleButtonF('KEEP',     K[1],K[2],K[3],   'Always loot ' .. targetDesc,     tkW4) ImGui.SameLine(0, tkSp)
            srRuleButtonF('SELL',     SE[1],SE[2],SE[3],'Loot and sell ' .. targetDesc,   tkW4) ImGui.SameLine(0, tkSp)
            srRuleButtonF('BANK',     BA[1],BA[2],BA[3],'Loot and bank ' .. targetDesc,   tkW4) ImGui.SameLine(0, tkSp)
            srRuleButtonF('TRIBUTE',  TR[1],TR[2],TR[3],'Loot and tribute ' .. targetDesc,tkW4)
            --- 3.8.67: bumped inter-row gap from 4 -> 8 so the KEEP/SELL/BANK/TRIBUTE
            --- and DESTROY/IGNORE/ANNOUNCE rows don't visually fuse into a
            --- single grid. The two rows are semantically different ("loot
            --- with rule" vs "don't loot") — the gap reinforces that split.
            ImGui.Dummy(0, 8)
            srRuleButtonF('DESTROY',  D[1],D[2],D[3],   'Always destroy ' .. targetDesc,  tkW3) ImGui.SameLine(0, tkSp)
            srRuleButtonF('IGNORE',   S[1],S[2],S[3],   'Ignore ' .. targetDesc,          tkW3) ImGui.SameLine(0, tkSp)
            srRuleButtonF('ANNOUNCE', AN[1],AN[2],AN[3],ANNOUNCE_TIP,                     tkW3)
            ImGui.Dummy(0, 6)
            local utilityW = math.max(72, math.floor((tkAvail - tkSp) / 2))
            local selAllLabel = Ui.fitLabel('Select All##review_select_all_bottom', 'All##review_select_all_bottom', utilityW)
            if Ui.buttonVariant(selAllLabel, 'secondaryButton', utilityW, ACTION_BTN_H) then
                reviewSelectVisibleRows()
            end
            tip('Check all currently visible Review rows.')
            ImGui.SameLine(0, tkSp)
            local clrAllLabel = Ui.fitLabel('Clear All##review_clear_all_bottom', 'Clear##review_clear_all_bottom', utilityW)
            if Ui.buttonVariant(clrAllLabel, 'secondaryButton', utilityW, ACTION_BTN_H) then
                reviewClearVisibleRows()
            end
            tip('Uncheck currently visible Review rows.')
        end

        if hasTarget and not pageMode then
            ImGui.Dummy(0, 3)
            ImGui.TextColored(0.65, 0.68, 0.75, 1.0, 'Loot tags')
            ImGui.Dummy(0, 4)
        end
        if hasTarget and not pageMode then
            ImGui.Dummy(0, 4)
            ImGui.TextColored(0.65, 0.68, 0.75, 1.0, 'Quantity')
            ImGui.SameLine()
            ImGui.PushItemWidth(58)
            g.turboKeyQty = ImGui.InputText('##sr_qty_rule', g.turboKeyQty)
            ImGui.PopItemWidth()
            ImGui.SameLine()
            if not rulesEnabled then ImGui.BeginDisabled() end
            if Ui.buttonVariant('Set##sr_qty_set', 'secondaryButton', 48, ACTION_BTN_H) then
                runQuantityRule()
            end
            if not rulesEnabled then ImGui.EndDisabled() end
            tip('Write a numeric ItemLimits rule for the cursor item or selected skip row(s). Use checkboxes or Select shown for bulk rows.')
            ImGui.SameLine()
            if Ui.buttonVariant('1##sr_qty_1', 'secondaryButton', 30, ACTION_BTN_H) then
                g.turboKeyQty = '1'
                if rulesEnabled then
                    runQuantityRule()
                else
                    g.statusMessage = 'Quantity set to 1. Select a Review row or cursor item to apply it.'
                end
            end
            tip('Set quantity to 1 and apply it to the selected Review row or cursor item.')
            if targetMode == 'cursor' then
                local cursorStack = tonumber(mq.TLO.Cursor.Stack()) or 1
                if cursorStack > 1 then
                    ImGui.SameLine()
                    if Ui.buttonVariant('All##sr_qty_all', 'secondaryButton', 40, ACTION_BTN_H) then
                        g.turboKeyQty = tostring(cursorStack)
                    end
                    tip('Set quantity to the cursor stack size')
                end
            end
        end

        if undoInfo or cursorUndo then
            ImGui.Dummy(0, 4)
        end
        if undoInfo then
            ImGui.PushStyleColor(ImGuiCol.Button, IM_COL32(65, 58, 45, 255))
            ImGui.PushStyleColor(ImGuiCol.ButtonHovered, IM_COL32(85, 78, 65, 255))
            local undoName = (#undoInfo.name > 18) and (undoInfo.name:sub(1, 15) .. '...') or undoInfo.name
            local uLabel = string.format('Undo %s: %s##sr', undoInfo.rule, undoName)
            if ImGui.Button(uLabel, -1, ACTION_BTN_H) then
                undoSkipRule()
                g.skipDisplayRows = nil
            end
            ImGui.PopStyleColor(2)
            tip('Undo the most recent skip-review rule.')
        end
        if cursorUndo then
            if undoInfo then ImGui.Dummy(0, 3) end
            ImGui.PushStyleColor(ImGuiCol.Button, IM_COL32(55, 60, 70, 255))
            ImGui.PushStyleColor(ImGuiCol.ButtonHovered, IM_COL32(75, 80, 90, 255))
            local cursorUndoName = tostring(cursorUndo.itemName or 'cursor item')
            cursorUndoName = (#cursorUndoName > 18) and (cursorUndoName:sub(1, 15) .. '...') or cursorUndoName
            local cursorUndoLabel = string.format('Undo cursor %s: %s##sr_cursor_undo', tostring(cursorUndo.rule or 'rule'), cursorUndoName)
            if ImGui.Button(cursorUndoLabel, -1, ACTION_BTN_H) then
                if g.undoCursorRule then g.undoCursorRule() end
            end
            ImGui.PopStyleColor(2)
            tip('Undo the most recent cursor-item INI rule. This does not restore destroyed items.')
        end

        ImGui.Dummy(0, 3)
        if pageMode then
            ImGui.Separator()
            ImGui.TextColored(0.65, 0.68, 0.75, 1.0, 'Reloot')
        end
        local relootMode = g.actionRunMode or 'self'
        local relootAvail = ImGui.GetContentRegionAvail()
        local relootSp = ImGui.GetStyle().ItemSpacing.x
        local relootW = math.max(54, math.floor((math.min(relootAvail, 300) - relootSp * 3) / 4))
        ImGui.TextColored(0.62, 0.66, 0.74, 1.0, 'Reloot:')
        ImGui.SameLine()
        local function relootScopeButton(label, mode, tooltipText)
            local active = relootMode == mode
            if Ui.buttonVariant(label .. '##review_reloot_scope_' .. mode,
                active and 'primaryButton' or 'secondaryButton', relootW, 0) then
                g.actionRunMode = mode
            end
            tip(tooltipText)
        end
        relootScopeButton('Single', 'self', 'Reloot with the current single looter.')
        ImGui.SameLine()
        relootScopeButton('Picks', 'multi', 'Reloot with characters selected in Actions -> Run As -> Picks.')
        ImGui.SameLine()
        relootScopeButton('Group', 'group', 'Reloot with current group characters.')
        ImGui.SameLine()
        relootScopeButton('All', 'all', 'Reloot with all E3 bots in zone.')
        if (g.actionRunMode or 'self') == 'multi' then
            if type(g.actionRunTargets) ~= 'table' then g.actionRunTargets = {} end
            local shown = 0
            local shownNames = {}
            for _, name in ipairs(g.members or {}) do
                if name and name ~= '' and name ~= 'NOBODY' then
                    if shown == 0 then
                        ImGui.TextColored(0.55, 0.58, 0.65, 1.0, 'Picks')
                        ImGui.SameLine()
                    else
                        ImGui.SameLine()
                    end
                    shownNames[name:lower()] = true
                    local active = type(g.actionRunTargets) == 'table' and g.actionRunTargets[name] == true
                    if Ui.buttonVariant(name .. '##review_reloot_pick_' .. name,
                        active and 'primaryButton' or 'secondaryButton', 76, 0) then
                        g.actionRunTargets[name] = not active or nil
                    end
                    tip('Toggle ' .. name .. ' for Reloot Picks.')
                    shown = shown + 1
                end
            end
            for name, active in pairs(g.actionRunTargets) do
                if active and type(name) == 'string' and name ~= '' and not shownNames[name:lower()] then
                    if shown == 0 then
                        ImGui.TextColored(0.55, 0.58, 0.65, 1.0, 'Picks')
                        ImGui.SameLine()
                    else
                        ImGui.SameLine()
                    end
                    if Ui.buttonVariant(name .. ' x##review_reloot_pick_extra_' .. name, 'primaryButton', 88, 0) then
                        g.actionRunTargets[name] = nil
                    end
                    tip('Remove ' .. name .. ' from Reloot Picks.')
                    shown = shown + 1
                end
            end
            if shown == 0 then
                ImGui.TextColored(0.55, 0.58, 0.65, 1.0, 'No picks selected.')
            end
            ImGui.PushItemWidth(math.max(120, ImGui.GetContentRegionAvail() - 80))
            g.relootPickName = ImGui.InputText('##review_reloot_pick_name', tostring(g.relootPickName or ''))
            ImGui.PopItemWidth()
            ImGui.SameLine()
            if Ui.buttonVariant('Add pick##review_reloot_add_pick', 'secondaryButton', 72, 0) then
                local pick = tostring(g.relootPickName or ''):match('^%s*(.-)%s*$') or ''
                if pick ~= '' and pick ~= 'NOBODY' then
                    g.actionRunTargets[pick] = true
                    g.relootPickName = ''
                end
            end
            tip('Add an out-of-group toon by exact character name.')
        end
        if Ui.buttonVariant('Reloot corpses##sr_reloot', 'primaryButton', -1, ACTION_BTN_H) then
            if g.relootNow then g.relootNow(g.actionRunMode or 'self') end
        end
        tip('Show hidden corpses for the selected Reloot scope, then run TurboLoot again.')
        if pageMode then
            ImGui.Dummy(0, 4)
            ImGui.Separator()
            ImGui.TextColored(0.65, 0.68, 0.75, 1.0, 'Corpses')
            ImGui.Dummy(0, 2)
            if Ui.buttonVariant('Hide all corpses##sr_hide_all_corpses', 'secondaryButton', 0, ACTION_BTN_H) then
                mq.cmd('/e3bcaa /hidecorpse all')
                g.statusMessage = 'Hide all corpses sent to group.'
            end
            tip('Hide all corpses for the group.')
            ImGui.SameLine()
            if Ui.buttonVariant('Hide looted##sr_hide_looted_corpses', 'secondaryButton', 0, ACTION_BTN_H) then
                mq.cmd('/e3bcaa /hidecorpse looted')
                g.statusMessage = 'Hide looted corpses sent to group.'
            end
            tip('Hide looted corpses for the group.')
            ImGui.SameLine()
            if Ui.buttonVariant('Show corpses##sr_show_corpses', 'secondaryButton', 0, ACTION_BTN_H) then
                mq.cmd('/e3bcaa /gsay [Turbo] Review Show corpses requested.')
                mq.cmd('/e3bcaa /hidecorpse none')
                g.statusMessage = 'Show corpses sent to group.'
            end
            tip('Show all corpses for the group.')
            ImGui.Dummy(0, 3)
        end

    if pendingN >= (Theme.layout.skipClearMinCount or 2) then
        --- 3.8.59: IGNORE ALL — bulk-apply IGNORE rule to every pending skip row.
        --- Confirmation popup prevents misclicks. First click stages a frozen
        --- snapshot, then the modal confirms that exact set.
        --- Per-row INI routing (each rule writes to that row's `iniPath`, matching
        --- per-row IGNORE behavior). Stages a frozen snapshot from
        --- `skipTracker.get_pending()` — not `skipDisplayRows` — so items beyond
        --- the display cap (50) are included, while new arrivals during the
        --- modal is open are left alone. Single-step undo only restores the last
        --- write; status message advertises this so users aren't surprised.

        local function snapshotPendingSkips()
            local snapshot = {}
            local pendingItems = skipTracker.get_pending() or {}
            for _, rec in ipairs(pendingItems) do
                local recName = rec.name
                if recName and recName ~= '' then
                    local reasonCode = skipTracker.primary_reason(rec)
                    local recSrc = skipTracker.get_source(rec)
                    local iniFile = TG.resolveIniForChar(recSrc)
                    local iniPath = nil
                    if resolveTurbolootIniPathForProfile then
                        iniPath = resolveTurbolootIniPathForProfile(iniFile)
                    end
                    local itemRule = TG.readReviewItemRule(iniPath, recName)
                    if not TG.isExpectedReviewSkip(reasonCode, itemRule) then
                        snapshot[#snapshot + 1] = {
                            name = recName,
                            source = recSrc,
                            iniPath = iniPath,
                        }
                    end
                end
            end
            return snapshot
        end

        local function pendingNameSet()
            local names = {}
            local pendingItems = skipTracker.get_pending() or {}
            for _, rec in ipairs(pendingItems) do
                if rec.name and rec.name ~= '' then
                    local reasonCode = skipTracker.primary_reason(rec)
                    local recSrc = skipTracker.get_source(rec)
                    local iniFile = TG.resolveIniForChar(recSrc)
                    local iniPath = resolveTurbolootIniPathForProfile and resolveTurbolootIniPathForProfile(iniFile) or nil
                    local itemRule = TG.readReviewItemRule(iniPath, rec.name)
                    if not TG.isExpectedReviewSkip(reasonCode, itemRule) then
                        names[rec.name] = true
                    end
                end
            end
            return names
        end

        local function applyIgnoreSnapshot(stagedSnapshot)
            if TG.requireSharedControl and not TG.requireSharedControl('Review Ignore all') then return end
            local stillPending = pendingNameSet()
            local applied, failed, skipped = 0, 0, 0
            skipTracker.persist_batch_begin()
            for _, rec in ipairs(stagedSnapshot or {}) do
                if not stillPending[rec.name] then
                    skipped = skipped + 1
                else
                    local ok = skipTracker.apply_rule(rec.name, 'IGNORE', rec.iniPath)
                    if ok then applied = applied + 1 else failed = failed + 1 end
                end
            end
            skipTracker.persist_batch_end()
            g.lastSkipApplyMS = mq.gettime()
            g.skipSelectedKey = nil
            g.skipSelectionSet = nil
            g.skipIniTargetOverride = nil
            g.skipIniTargetOverridePath = nil
            g.skipDisplayRows = nil
            g.ignoreAllStagedAt = 0
            g.ignoreAllStagedSnapshot = nil
            if failed == 0 then
                if skipped > 0 then
                    g.statusMessage = string.format('Ignored %d items; %d no longer pending (Undo restores the last one only)', applied, skipped)
                else
                    g.statusMessage = string.format('Ignored %d items (Undo restores the last one only)', applied)
                end
            else
                g.statusMessage = string.format('Ignored %d items, %d failed, %d no longer pending', applied, failed, skipped)
            end
        end

        ImGui.Dummy(0, 2)
        ImGui.PushStyleColor(ImGuiCol.Button, IM_COL32(55, 58, 65, 255))
        ImGui.PushStyleColor(ImGuiCol.ButtonHovered, IM_COL32(75, 78, 85, 255))
        if ImGui.Button(string.format('Ignore all (%d)##sr_ignore_all', pendingN), -1, ACTION_BTN_H) then
            local snapshot = snapshotPendingSkips()
            if g.confirmSingleReviewRules == false then
                applyIgnoreSnapshot(snapshot)
            else
                g.ignoreAllStagedAt = mq.gettime()
                g.ignoreAllStagedSnapshot = snapshot
                ImGui.OpenPopup('Confirm Ignore All Skips')
            end
        end
        ImGui.PopStyleColor(2)
        tip(g.confirmSingleReviewRules == false
            and 'Apply IGNORE rule to every pending skip row.'
            or 'Apply IGNORE rule to every pending skip row. You will be asked to confirm.')

        if ImGui.BeginPopupModal('Confirm Ignore All Skips') then
            local stagedSnapshot = g.ignoreAllStagedSnapshot or {}
            ImGui.Text('Confirm Ignore All')
            ImGui.Separator()
            ImGui.Text(string.format('Apply IGNORE to %d staged skip row%s?', #stagedSnapshot, #stagedSnapshot == 1 and '' or 's'))
            ImGui.Text('New rows added after you clicked Ignore all will be left alone.')
            ImGui.Dummy(0, 6)
            if ImGui.Button('Confirm##ignore_all_modal', 120, ACTION_BTN_H) then
                -- Commit: iterate the staged snapshot only. If a staged row was
                -- dismissed or resolved during the confirm window, skip it.
                applyIgnoreSnapshot(stagedSnapshot)
                ImGui.CloseCurrentPopup()
            end
            ImGui.SameLine()
            if ImGui.Button('Cancel##ignore_all_modal', 120, ACTION_BTN_H) then
                g.ignoreAllStagedAt = 0
                g.ignoreAllStagedSnapshot = nil
                ImGui.CloseCurrentPopup()
            end
            ImGui.EndPopup()
        end
    end

        --- Full Review (pageMode) always offers Clear all skips when at least one
        --- actionable row is up. The slim review keeps the higher threshold so its
        --- compact layout isn't cluttered for a single item. (Tester request.)
        if pageMode and pendingN >= 1 then
            ImGui.Dummy(0, 2)
            ImGui.PushStyleColor(ImGuiCol.Button, IM_COL32(55, 45, 45, 255))
            ImGui.PushStyleColor(ImGuiCol.ButtonHovered, IM_COL32(75, 55, 55, 255))
            if ImGui.Button('Clear all skips##sr_clear_all_panel', -1, ACTION_BTN_H) then
                if g.confirmSingleReviewRules == false then
                    clearActionableSkips()
                else
                    ImGui.OpenPopup('Confirm Clear All Skips')
                end
            end
            ImGui.PopStyleColor(2)
            tip(g.confirmSingleReviewRules == false
                and 'Dismiss all pending items without making rules.'
                or 'Dismiss all pending items (no rules created). You will be asked to confirm.')

            if ImGui.BeginPopupModal('Confirm Clear All Skips') then
                ImGui.Text('Confirm Clear All Skips')
                ImGui.Separator()
                ImGui.Text(string.format('Dismiss all %d actionable skip row%s without writing rules?', pendingN, pendingN == 1 and '' or 's'))
                ImGui.Dummy(0, 6)
                if ImGui.Button('Confirm##clear_all_modal_panel', 120, ACTION_BTN_H) then
                    clearActionableSkips()
                    ImGui.CloseCurrentPopup()
                end
                ImGui.SameLine()
                if ImGui.Button('Cancel##clear_all_modal_panel', 120, ACTION_BTN_H) then
                    ImGui.CloseCurrentPopup()
                end
                ImGui.EndPopup()
            end
        end
        --- 1.3.2: trimmed from 24px to 8px. The BeginChild already gets
        --- WindowPadding.y of bottom padding from ImGui itself, so the 24px
        --- Dummy was effectively doubling the bottom margin. 8px keeps a
        --- small visual breather below "Clear all skips" without wasting
        --- the real estate that the list could use.
        if pageMode then
            local footerMessage = tostring(g.statusMessage or '')
            if footerMessage ~= '' then
                ImGui.Dummy(0, 3)
                ImGui.PushTextWrapPos(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail())
                ImGui.TextColored(0.45, 0.48, 0.55, 1.0, 'Last:')
                ImGui.SameLine(0, 5)
                ImGui.TextColored(Colors.statusMsg[1], Colors.statusMsg[2], Colors.statusMsg[3], Colors.statusMsg[4], footerMessage)
                ImGui.PopTextWrapPos()
            end
        end
        ImGui.Dummy(0, 8)

        end --- skipActionPanelBody

        if drawRuleConfirmPopup then drawRuleConfirmPopup() end
    end

    if (not pageMode) and pendingN >= (Theme.layout.skipClearMinCount or 2) then
        local function clearActionableSkips()
            local cleared = TG.clearActionablePendingSkips()
            g.skipSelectedKey = nil
            g.skipSelectionSet = nil
            g.skipIniTargetOverride = nil
            g.skipIniTargetOverridePath = nil
            g.skipDisplayRows = nil
            rebuildSkipDisplayRows()
            g.skipReviewOpen = true
            g.ignoreAllStagedAt = 0
            g.ignoreAllStagedSnapshot = nil
            g.statusMessage = string.format('%d actionable skip%s cleared', cleared, cleared == 1 and '' or 's')
        end
        ImGui.Dummy(0, 2)
        ImGui.PushStyleColor(ImGuiCol.Button, IM_COL32(55, 45, 45, 255))
        ImGui.PushStyleColor(ImGuiCol.ButtonHovered, IM_COL32(75, 55, 55, 255))
        if ImGui.Button('Clear all skips##sr_clear_all', -1, ACTION_BTN_H) then
            if g.confirmSingleReviewRules == false then
                clearActionableSkips()
            else
                ImGui.OpenPopup('Confirm Clear All Skips')
            end
        end
        ImGui.PopStyleColor(2)
        tip(g.confirmSingleReviewRules == false
            and 'Dismiss all pending items without making rules.'
            or 'Dismiss all pending items (no rules created). You will be asked to confirm.')

        if ImGui.BeginPopupModal('Confirm Clear All Skips') then
            ImGui.Text('Confirm Clear All Skips')
            ImGui.Separator()
            ImGui.Text(string.format('Dismiss all %d actionable skip row%s without writing rules?', pendingN, pendingN == 1 and '' or 's'))
            ImGui.Dummy(0, 6)
            if ImGui.Button('Confirm##clear_all_modal', 120, ACTION_BTN_H) then
                clearActionableSkips()
                ImGui.CloseCurrentPopup()
            end
            ImGui.SameLine()
            if ImGui.Button('Cancel##clear_all_modal', 120, ACTION_BTN_H) then
                ImGui.CloseCurrentPopup()
            end
            ImGui.EndPopup()
        end
    end
end

TG.renderTurboLootSettingsWindow = (function()
TG.turboLootSettingsSchema = require('Turbo.ui.settings_meta').buildSchema()

local WILDCARD_BUILTIN_KEYS = { 'Spell:', 'Skill:', 'Song:', 'Tome ', 'Tome of ' }

local function formatLooterBehaviorSaveStatus(profile, iniPath, label, count)
    profile = cleanProfileName(profile) or 'turboloot.ini'
    local tail = (iniPath and iniPath ~= '' and (iniPath:match('[^\\/]+$') or iniPath)) or profile
    local me = mq.TLO.Me.Name() or ''
    local live = (TG.getLiveProfileForMember and TG.getLiveProfileForMember(me)) or nil
    local msg = string.format('Saved %s (%d) → %s', label, count or 0, tail)
    if live and live ~= '' and live:lower() ~= profile:lower() then
        msg = msg .. string.format(' — E3 on %s uses %s; Setup → Resync or re-run loot/bank/sell', me, live)
    else
        msg = msg .. ' — re-run TurboLoot if a macro is already running'
    end
    return msg
end

local function reloadTurboLootSettingsDraft(g, iniPath, iniExists)
    g.tlSettingsDraft = {}
    g.tlSettingsDraftOriginal = {}
    if not iniPath or iniPath == '' or iniExists ~= true then return end
    for _, spec in ipairs(TG.turboLootSettingsSchema) do
        local raw = readIniKey(iniPath, 'Settings', spec.key)
        if raw == nil and spec.key == 'SellUnlistedStackable' then
            raw = readIniKey(iniPath, 'Settings', 'sellUnlistedStackable')
        end
        if raw == nil and spec.default ~= nil then
            raw = spec.default
        end
        local value = tostring(raw or '')
        g.tlSettingsDraft[spec.key] = value
        g.tlSettingsDraftOriginal[spec.key] = value
    end
end

local function renderTurboLootSettingsWildcardsPage(g, profile, iniPath, iniExists, ACTION_BTN_H)
    ImGui.TextColored(0.55, 0.60, 0.68, 1.0,
        'Wildcards are prefix rules. Spell:=ON matches item names starting with Spell:.')
    ImGui.TextColored(0.55, 0.60, 0.68, 1.0,
        'Custom Wildcard1=Rune of matches item names starting with Rune of.')
    if type(g.wildcardDraft) ~= 'table' or g.wildcardDraftProfile ~= profile then
        g.wildcardDraftProfile = profile
        g.wildcardDraft = {}
        if iniPath and iniExists == true then
            for _, key in ipairs(WILDCARD_BUILTIN_KEYS) do
                g.wildcardDraft[key] = tostring(readIniKey(iniPath, 'Wildcards', key) or '')
            end
            for i = 1, 8 do
                local key = 'Wildcard' .. tostring(i)
                g.wildcardDraft[key] = tostring(readIniKey(iniPath, 'Wildcards', key) or '')
            end
        end
    end
    Ui.section('utility', 'Built-ins', { topGap = 6, bottomGap = 3 })
    for _, key in ipairs(WILDCARD_BUILTIN_KEYS) do
        local cur = tostring(g.wildcardDraft[key] or '')
        local upper = cur:upper()
        g.wildcardDraft[key] = ImGui.Checkbox(key .. '##wc_builtin_' .. key,
            upper == 'ON' or upper == 'TRUE' or cur == '1') and 'ON' or 'OFF'
    end
    Ui.section('utility', 'Custom prefixes', { topGap = 6, bottomGap = 3 })
    for i = 1, 8 do
        local key = 'Wildcard' .. tostring(i)
        g.wildcardDraft[key] = Ui.compactInput(key, g.wildcardDraft[key], {
            id = '##wc_custom_' .. key,
            labelW = 82,
            width = math.max(180, math.min(360, Ui.availX(280) - 82)),
        })
    end
    ImGui.Separator()
    if not iniPath or iniExists ~= true then ImGui.BeginDisabled() end
    if Ui.buttonVariant('Save Wildcards##wc_save', 'primaryButton', 132, ACTION_BTN_H) then
        local body = {
            '; Looting = prefix (starts-with) only. ON/OFF for built-ins; Wildcard1= for customs.',
            '; Keep exactly one [Wildcards] header in this file (duplicates break MQ Ini reads).',
            '; GiveList _prefix can use Text*  *Text  *Text* — see TurboGive docs.',
        }
        local saved = 0
        for _, key in ipairs(WILDCARD_BUILTIN_KEYS) do
            local value = tostring(g.wildcardDraft[key] or 'OFF'):upper()
            if value ~= 'ON' and value ~= 'TRUE' and value ~= '1' then value = 'OFF' end
            body[#body + 1] = key .. '=' .. value
            saved = saved + 1
        end
        for i = 1, 8 do
            local key = 'Wildcard' .. tostring(i)
            local value = tostring(g.wildcardDraft[key] or ''):gsub('[\r\n]+', ' '):match('^%s*(.-)%s*$') or ''
            if value ~= '' then
                body[#body + 1] = key .. '=' .. value
                saved = saved + 1
            end
        end
        if replaceIniSection(iniPath, 'Wildcards', body) then
            g.statusMessage = formatLooterBehaviorSaveStatus(profile, iniPath, '[Wildcards]', saved)
            if TG.invalidateProfileSettingsCache then TG.invalidateProfileSettingsCache(profile) end
        else
            g.statusMessage = 'Could not save [Wildcards] — check file path and permissions.'
        end
    end
    if not iniPath or iniExists ~= true then ImGui.EndDisabled() end
end

local function renderTurboLootSettingsGivePage(g, profile, iniPath, iniExists, tip, ACTION_BTN_H)
    ImGui.TextColored(0.55, 0.60, 0.68, 1.0,
        'TurboGive exact rows write [GiveList] as Item Name=Receiver or Receiver MaxCount.')
    ImGui.TextColored(0.55, 0.60, 0.68, 1.0,
        'Pattern rows like _prefix1=Tank:Spell:* can still be edited in the INI for now.')
    if type(g.giveDraft) ~= 'table' or g.giveDraftProfile ~= profile then
        g.giveDraftProfile = profile
        g.giveDraft = { item = '', receiver = '', max = '', exclude = '' }
        if iniPath and iniExists == true then
            g.giveDraft.exclude = tostring(readIniKey(iniPath, 'GiveExclude', '_list') or '')
        end
    end
    Ui.section('utility', 'Add or update exact item', { topGap = 6, bottomGap = 3 })
    g.giveDraft.item = Ui.compactInput('Item', g.giveDraft.item, {
        id = '##give_item',
        labelW = 70,
        width = math.max(180, math.min(360, Ui.availX(280) - 70)),
    })
    g.giveDraft.receiver = Ui.compactInput('Receiver', g.giveDraft.receiver, {
        id = '##give_receiver',
        labelW = 70,
        width = 140,
    })
    g.giveDraft.max = Ui.compactInput('Max', g.giveDraft.max, {
        id = '##give_max',
        labelW = 70,
        width = 70,
    })
    if not iniPath or iniExists ~= true then ImGui.BeginDisabled() end
    if Ui.buttonVariant('Save Give Row##give_save_row', 'primaryButton', 132, ACTION_BTN_H) then
        local item = tostring(g.giveDraft.item or ''):gsub('[\r\n=]+', ' '):match('^%s*(.-)%s*$') or ''
        local receiver = tostring(g.giveDraft.receiver or ''):gsub('[\r\n=]+', ' '):match('^%s*(.-)%s*$') or ''
        local max = tostring(g.giveDraft.max or ''):match('^%s*(.-)%s*$') or ''
        local n = tonumber(max)
        local value = receiver
        if n and n > 0 then value = receiver .. ' ' .. tostring(math.floor(n)) end
        if item ~= '' and receiver ~= '' and writeIniKey(iniPath, 'GiveList', item, value) then
            g.statusMessage = formatLooterBehaviorSaveStatus(profile, iniPath, 'GiveList row', 1)
            g.giveDraft.item, g.giveDraft.receiver, g.giveDraft.max = '', '', ''
            g.giveDraftProfile = nil
        else
            g.statusMessage = 'Enter an item and receiver before saving TurboGive row.'
        end
    end
    if not iniPath or iniExists ~= true then ImGui.EndDisabled() end
    Ui.section('utility', 'Exclusions', { topGap = 8, bottomGap = 3 })
    g.giveDraft.exclude = Ui.compactInput('Never match', g.giveDraft.exclude, {
        id = '##give_exclude',
        labelW = 92,
        width = math.max(180, math.min(420, Ui.availX(320) - 92)),
    })
    tip('Comma-separated exact item names that wildcard GiveList patterns should never match.')
    if not iniPath or iniExists ~= true then ImGui.BeginDisabled() end
    if Ui.buttonVariant('Save Exclusions##give_save_exclude', 'secondaryButton', 132, ACTION_BTN_H) then
        local value = tostring(g.giveDraft.exclude or ''):gsub('[\r\n]+', ' '):match('^%s*(.-)%s*$') or ''
        if value ~= '' then writeIniKey(iniPath, 'GiveExclude', '_list', value)
        else deleteIniKey(iniPath, 'GiveExclude', '_list') end
        g.statusMessage = 'Saved TurboGive exclusions.'
    end
    if not iniPath or iniExists ~= true then ImGui.EndDisabled() end
    Ui.section('utility', 'Existing exact GiveList rows', { topGap = 8, bottomGap = 3 })
    if iniPath and iniExists == true then
        local shown = 0
        for _, pair in ipairs(readIniSectionPairs(iniPath, 'GiveList')) do
            if not tostring(pair.key or ''):match('^_') then
                ImGui.TextColored(0.72, 0.76, 0.84, 1.0,
                    tostring(pair.key or '') .. ' = ' .. tostring(pair.value or ''))
                shown = shown + 1
                if shown >= 20 then break end
            end
        end
        if shown == 0 then ImGui.TextColored(0.45, 0.48, 0.55, 1.0, 'No exact GiveList rows yet.') end
    end
end

local function turboLootSettingsDraftDirty(g)
    if type(g.tlSettingsDraft) ~= 'table' or type(g.tlSettingsDraftOriginal) ~= 'table' then return false end
    for _, spec in ipairs(TG.turboLootSettingsSchema) do
        if tostring(g.tlSettingsDraft[spec.key] or '') ~= tostring(g.tlSettingsDraftOriginal[spec.key] or '') then
            return true
        end
    end
    return false
end

local function saveTurboLootSettingsDraft(g, profile, iniPath)
    local dupes, dupErr = TG.iniHealth.duplicate_sections(iniPath, 'Settings')
    if dupErr then
        g.statusMessage = 'Could not inspect [Settings]: ' .. tostring(dupErr)
        return
    end
    if dupes and #dupes > 0 then
        g.statusMessage = 'Cannot save: duplicate [Settings] sections in ' .. tostring(iniPath)
        return
    end

    local saved, failed = 0, 0
    local firstFailure = nil
    for _, spec in ipairs(TG.turboLootSettingsSchema) do
        local value = tostring(g.tlSettingsDraft[spec.key] or ''):gsub('[\r\n]+', ' '):match('^%s*(.-)%s*$') or ''
        if spec.type == 'int' then
            local n = tonumber(value)
            if n then
                n = math.floor(n)
                if spec.min then n = math.max(spec.min, n) end
                if spec.max then n = math.min(spec.max, n) end
                value = tostring(n)
            elseif spec.default ~= nil then
                value = tostring(spec.default)
            else
                value = ''
            end
        elseif value == '' and spec.type == 'bool' then
            value = 'OFF'
        elseif value == '' and spec.default ~= nil then
            value = tostring(spec.default)
        end
        local ok, err = false, nil
        if value ~= '' then
            ok, err = TG.iniHealth.write_key_verified(iniPath, 'Settings', spec.key, value, writeIniKey, readIniKey)
        end
        if ok then
            saved = saved + 1
            g.tlSettingsDraft[spec.key] = value
            g.tlSettingsDraftOriginal[spec.key] = value
        else
            failed = failed + 1
            firstFailure = firstFailure or string.format('%s (%s)', spec.key, tostring(err or 'not written'))
        end
    end
    g.statusMessage = formatLooterBehaviorSaveStatus(profile, iniPath, '[Settings] verified', saved)
    if failed > 0 then
        g.statusMessage = g.statusMessage .. string.format(' (%d failed: %s)', failed, tostring(firstFailure or 'unknown'))
    end
    if saved > 0 and TG.invalidateProfileSettingsCache then
        TG.invalidateProfileSettingsCache(profile)
    end
end

local function renderTurboLootSettingsFooter(g, profile, iniPath, iniExists, tip, ACTION_BTN_H)
    ImGui.Separator()
    if turboLootSettingsDraftDirty(g) then
        ImGui.TextColored(1.0, 0.78, 0.25, 1.0, 'Unsaved changes')
    else
        ImGui.TextColored(0.45, 0.65, 0.45, 1.0, 'No unsaved changes')
    end

    local avail = Ui.availX(360)
    local gap = 8
    local openW = 92
    local reloadW = 90
    local saveW = math.max(138, math.min(210, avail - reloadW - openW - gap * 2))
    local canWrite = iniPath and iniPath ~= '' and iniExists == true
    if not canWrite then ImGui.BeginDisabled() end
    local saveLabel = Ui.fitLabel(string.format('Save to %s##tl_settings_save', tostring(profile or 'INI')),
        'Save##tl_settings_save', saveW)
    if Ui.buttonVariant(saveLabel, 'primaryButton', saveW, ACTION_BTN_H) then
        saveTurboLootSettingsDraft(g, profile, iniPath)
    end
    tip('Write and verify the shown values in the [Settings] section of the selected TurboLoot INI.')
    if not canWrite then ImGui.EndDisabled() end
    ImGui.SameLine(0, gap)
    if Ui.buttonVariant('Reload##tl_settings_reload', 'secondaryButton', reloadW, ACTION_BTN_H) then
        reloadTurboLootSettingsDraft(g, iniPath, iniExists)
        g.statusMessage = 'Reloaded TurboLoot settings from disk.'
    end
    ImGui.SameLine(0, gap)
    if Ui.buttonVariant('Open INI##tl_settings_open_ini', 'secondaryButton', openW, ACTION_BTN_H) then
        openProfileExternal(profile)
    end
end

local function renderTurboLootSettingsSchemaPage(g, profile, iniPath, iniExists, tip, ACTION_BTN_H)
    local lastGroup = nil
    local function settingTip(spec)
        local text = tostring(spec.tooltip or spec.description or '')
        if spec.default ~= nil then
            text = text .. '\nDefault: ' .. tostring(spec.default)
        end
        if spec.options and spec.options ~= '' then
            text = text .. '\nOptions: ' .. tostring(spec.options)
        end
        if text ~= '' then tip(text) end
    end
    for _, spec in ipairs(TG.turboLootSettingsSchema) do
        if spec.advanced ~= true or g.tlSettingsShowAdvanced == true then
        if spec.group ~= lastGroup then
            lastGroup = spec.group
            Ui.section('utility', lastGroup, { topGap = 6, bottomGap = 3 })
        end
        local cur = tostring((g.tlSettingsDraft and g.tlSettingsDraft[spec.key]) or '')
        if spec.type == 'bool' then
            local upper = cur:upper()
            g.tlSettingsDraft[spec.key] = ImGui.Checkbox(spec.label .. '##tlset_' .. spec.key,
                upper == 'ON' or upper == 'TRUE' or cur == '1') and 'ON' or 'OFF'
            settingTip(spec)
        elseif spec.type == 'enum' then
            local nextVal = cur ~= '' and cur or tostring((spec.values and spec.values[1]) or '')
            nextVal = Ui.compactCombo(spec.label, nextVal, spec.values, {
                id = '##tlset_' .. spec.key,
                width = 150,
            })
            g.tlSettingsDraft[spec.key] = nextVal
            settingTip(spec)
        else
            g.tlSettingsDraft[spec.key] = Ui.compactInput(spec.label, cur, {
                id = '##tlset_' .. spec.key,
                labelW = 132,
                width = spec.type == 'int' and 86 or 170,
            })
            settingTip(spec)
        end
        end
    end

    local rcMode = tostring((g.tlSettingsDraft and g.tlSettingsDraft.RightClickLoot) or ''):upper()
    local allowLegacy = tostring((g.tlSettingsDraft and g.tlSettingsDraft.AllowLeftClickLoot) or ''):upper()
    local legacyAllowed = allowLegacy == 'ON' or allowLegacy == 'TRUE' or allowLegacy == 'YES' or allowLegacy == '1'
    if (rcMode == 'OFF' or rcMode == 'FALSE' or rcMode == 'NO' or rcMode == '0') and not legacyAllowed then
        ImGui.TextColored(1.0, 0.78, 0.25, 1.0,
            'RightClickLoot=OFF will be ignored unless Allow legacy left-click is ON.')
    end
end

local function renderTurboLootMain(g, tip, ACTION_BTN_H, getActiveProfile)
    local profile = cleanProfileName(g.tlSettingsProfile or '')
    if not profile then profile = cleanProfileName((getActiveProfile and getActiveProfile()) or '') end
    profile = profile or 'turboloot.ini'
    g.tlSettingsProfile = profile
    local iniPath = resolveTurbolootIniPathForProfile and resolveTurbolootIniPathForProfile(profile) or nil
    local iniExists = false
    if resolveTurbolootIniPathForProfile then
        iniPath, iniExists = resolveTurbolootIniPathForProfile(profile)
    end

    if type(g.tlSettingsDraft) ~= 'table' or g.tlSettingsDraftProfile ~= profile then
        g.tlSettingsDraftProfile = profile
        reloadTurboLootSettingsDraft(g, iniPath, iniExists)
    end
    local function wrappedText(r, gb, b, a, text)
        ImGui.PushTextWrapPos(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail())
        ImGui.TextColored(r, gb, b, a, tostring(text or ''))
        ImGui.PopTextWrapPos()
    end

    ImGui.TextColored(0.65, 0.72, 0.9, 1.0, 'Target INI')
    ImGui.SameLine()
    if ImGui.BeginCombo('##tl_settings_profile', profile) then
        local seenProfiles = {}
        local profileOptions = {}
        for _, prof in ipairs(g.profileList or {}) do
            local clean = cleanProfileName(prof)
            if clean and not seenProfiles[clean:lower()] then
                seenProfiles[clean:lower()] = true
                profileOptions[#profileOptions + 1] = clean
            end
        end
        if not seenProfiles[profile:lower()] then profileOptions[#profileOptions + 1] = profile end
        table.sort(profileOptions, function(a, b) return a:lower() < b:lower() end)
        for _, prof in ipairs(profileOptions) do
            if ImGui.Selectable(tostring(prof) .. '##tl_settings_profile_' .. tostring(prof), tostring(prof) == profile) then
                profile = cleanProfileName(prof) or profile
                g.tlSettingsProfile = profile
                if resolveTurbolootIniPathForProfile then
                    iniPath, iniExists = resolveTurbolootIniPathForProfile(profile)
                end
                g.tlSettingsDraftProfile = profile
                reloadTurboLootSettingsDraft(g, iniPath, iniExists)
            end
        end
        ImGui.EndCombo()
    end
    tip('Choose which TurboLoot INI [Settings] section to edit.')
    if iniPath and iniPath ~= '' and iniExists == true then
        wrappedText(0.45, 0.65, 0.45, 1.0, iniPath)
    elseif iniPath and iniPath ~= '' then
        wrappedText(0.9, 0.55, 0.25, 1.0, 'Missing on disk: ' .. iniPath)
    else
        ImGui.TextColored(0.9, 0.35, 0.35, 1.0, 'Could not resolve this INI path.')
    end
    wrappedText(0.50, 0.54, 0.62, 1.0,
        'Setup assigns which INI each character uses; Resync pushes to E3. Item rules live in Review/TurboKey.')
    g.tlSettingsShowAdvanced = ImGui.Checkbox('Show advanced settings##tl_settings_advanced',
        g.tlSettingsShowAdvanced == true)
    tip('Show less-common behavior and debug/log options. Basic users can leave this off.')
    ImGui.Separator()

    g.tlSettingsPage = g.tlSettingsPage or 'settings'
    local tabW = math.max(96, math.floor((Ui.availX(360) - 12) / 3))
    if Ui.buttonVariant('Settings##tl_settings_page_settings',
        g.tlSettingsPage == 'settings' and 'primaryButton' or 'secondaryButton', tabW, ACTION_BTN_H) then
        g.tlSettingsPage = 'settings'
    end
    ImGui.SameLine()
    if Ui.buttonVariant('Wildcards##tl_settings_page_wildcards',
        g.tlSettingsPage == 'wildcards' and 'primaryButton' or 'secondaryButton', tabW, ACTION_BTN_H) then
        g.tlSettingsPage = 'wildcards'
    end
    ImGui.SameLine()
    if Ui.buttonVariant('TurboGive##tl_settings_page_give',
        g.tlSettingsPage == 'give' and 'primaryButton' or 'secondaryButton', tabW, ACTION_BTN_H) then
        g.tlSettingsPage = 'give'
    end
    ImGui.Separator()

    if g.tlSettingsPage == 'wildcards' then
        renderTurboLootSettingsWildcardsPage(g, profile, iniPath, iniExists, ACTION_BTN_H)
        return
    elseif g.tlSettingsPage == 'give' then
        renderTurboLootSettingsGivePage(g, profile, iniPath, iniExists, tip, ACTION_BTN_H)
        return
    end

    local _, availY = ImGui.GetContentRegionAvail()
    local footerH = ACTION_BTN_H + 38
    local bodyH = math.max(40, (availY or 220) - footerH)
    if ImGui.BeginChild('##tl_settings_schema_body', 0, bodyH, true) then
        renderTurboLootSettingsSchemaPage(g, profile, iniPath, iniExists, tip, ACTION_BTN_H)
        ImGui.EndChild()
    end
    renderTurboLootSettingsFooter(g, profile, iniPath, iniExists, tip, ACTION_BTN_H)
end

return renderTurboLootMain
end)()

-- =========================================================
-- Main render window
-- =========================================================
function TG.renderWindow()
    (function()
    local g = TG
    local mq, ImGui = g.mq, g.ImGui
    local ensureE3Vars, nowMS = g.ensureE3Vars, g.nowMS
    local collectGroupMembers, getCurrentLooter = g.collectGroupMembers, g.getCurrentLooter
    local getTurboState, getCombatLootState = g.getTurboState, g.getCombatLootState
    local getLootAllState, getNearbyCorpseCount = g.getLootAllState, g.getNearbyCorpseCount
    local getMultiLooters, isMultiLootMode = g.getMultiLooters, g.isMultiLootMode
    local toggleMultiLooter = g.toggleMultiLooter
    local setTurboCache, cycleToNext = g.setTurboCache, g.cycleToNext
    local setLooter, toggleLootAll = g.setLooter, g.toggleLootAll
    local toggleCombatLoot = g.toggleCombatLoot
    local setLootRadius, saveSettings = g.setLootRadius, g.saveSettings
    local saveCharProfiles = g.saveCharProfiles
    local getActiveProfile, setActiveProfile = g.getActiveProfile, g.setActiveProfile
    local syncProfileAssignments = g.syncProfileAssignments
    local getProfileForMember = g.getProfileForMember
    local scanTurbolootProfiles, rescanProfiles = g.scanTurbolootProfiles, g.rescanProfiles
    local applyTurboKeyRule = g.applyTurboKeyRule
    local getTurboLootSettingsSummaryLines = g.getTurboLootSettingsSummaryLines
    local tip, coloredSep, thinSep = g.tip, g.coloredSep, g.thinSep
    local toggleSwitch, actionButton = g.toggleSwitch, g.actionButton
    local ruleButton = g.ruleButton
    local skipTracker = g.skipTracker
    local undoSkipRule = g.undoSkipRule
    local TurboKeyRGB = g.TurboKeyRGB
    local printTurboGiveHelp1, printTurboGiveHelp2 = g.printTurboGiveHelp1, g.printTurboGiveHelp2
    local turboConvertTooltip, printHelp = g.turboConvertTooltip, g.printHelp
    local Colors = g.Colors
    local AUTO_REFRESH_MS, DEFAULT_LOOT_RADIUS = g.AUTO_REFRESH_MS, g.DEFAULT_LOOT_RADIUS
    local TURBO_VERSION, TURBO_URL = g.TURBO_VERSION, g.TURBO_URL
    local ACTION_BTN_W, ACTION_BTN_H = g.ACTION_BTN_W, g.ACTION_BTN_H
    local LAYOUT_MODE_BTN_W, LAYOUT_MODE_BTN_H = g.LAYOUT_MODE_BTN_W, g.LAYOUT_MODE_BTN_H
    local HELP_CHIP_W, HELP_CHIP_H = g.HELP_CHIP_W, g.HELP_CHIP_H

    if not g.windowOpen then return end

    if TG.consumePendingNavigation then TG.consumePendingNavigation() end

    if not TG.clientInGame() then
        ImGui.SetNextWindowSize(360, 112, ImGuiCond.FirstUseEver)
        local open = g.windowOpen
        open = ImGui.Begin(string.format('Turbo v%s', TURBO_VERSION), open)
        g.windowOpen = open
        if open then
            ImGui.TextColored(0.90, 0.70, 0.38, 1.00, 'Paused: client is not in-game.')
            ImGui.TextWrapped('Turbo is not syncing E3 vars or broadcasting commands from character select.')
            if ImGui.Button('Close Turbo##charselect_close') then
                g.windowOpen = false
            end
        end
        ImGui.End()
        return
    end

    ensureE3Vars()
    TG.refreshSharedControl(false)

    if g.statusMessage == '' then
        g.lastStatusMessageText = ''
        g.statusMessageShownAtMS = 0
    elseif g.statusMessage ~= g.lastStatusMessageText then
        g.lastStatusMessageText = g.statusMessage
        g.lastActionMessage = g.statusMessage
        g.statusMessageShownAtMS = nowMS()
    end
    if g.statusMessage ~= '' and g.statusMessageShownAtMS > 0
        and (nowMS() - g.statusMessageShownAtMS) >= SLIM_STATUS_MSG_TTL_MS then
        g.statusMessage = ''
        g.lastActionMessage = ''
        g.lastStatusMessageText = ''
        g.statusMessageShownAtMS = 0
    end
    if g.reconcileTurboRouteVar then
        g.reconcileTurboRouteVar()
    end
    if g.tickPendingSetupRestore then
        g.tickPendingSetupRestore()
    end

    local t = nowMS()
    if (t - g.lastRefreshMS) >= AUTO_REFRESH_MS then
        collectGroupMembers()
        refreshWalletCache()
        if g.refreshActiveIniState then
            g.refreshActiveIniState(false)
        end
        g.lastRefreshMS = t
    end

    if g.skipQueue and g.skipQueue.poll and g.skipQueue.poll() then
        if skipTracker and skipTracker.refresh then
            skipTracker.refresh()
        end
        g.skipDisplayRows = nil
    end

    -- 3.8.32: global skip poll. Prior: poll() was only called inside
    -- renderSkipReview, so new journal writes never appeared until the user
    -- navigated to the old Loot Manager / Review flow and waited
    -- 2 s. Badge count stayed stale across tabs. Now: poll() fires once per
    -- render, the tracker's internal 2 s throttle keeps it cheap (single
    -- io.open + seek on no-change tails — sub-ms). If it returns dirty,
    -- invalidate the display cache so the next Skip Review render rebuilds.
    -- Routes through TG (no new locals — respects 200-local limit).
    if skipTracker and skipTracker.poll then
        if skipTracker.poll() then
            g.skipDisplayRows = nil
            g.skipDisplayTotal = nil
        end
    end

    local currentLooter = getCurrentLooter()
    local liveMainLooter = g.getLiveMainLooter and g.getLiveMainLooter() or currentLooter
    if not g.selectedChar or g.selectedChar == '' then
        g.selectedChar = (currentLooter ~= 'NOBODY') and currentLooter or (mq.TLO.Me.Name() or '')
    end
    local activeProfile = getActiveProfile()
    local turboOn = getTurboState()
    local combatOn = getCombatLootState()
    local lootAllOn = getLootAllState()
    local meleeDistFar = g.cachedMeleeDistFar == true
    if t >= (tonumber(g.cachedMeleeDistFarExpiry) or 0) then
        pcall(function()
            meleeDistFar = TG.e3Bool(mq.TLO.MQ2Mono.Query('e3,MeleeDistFar')())
        end)
        g.cachedMeleeDistFar = meleeDistFar
        g.cachedMeleeDistFarExpiry = t + CACHE_TTL_MS
    end
    local multiModeOn = (not lootAllOn) and isMultiLootMode()
    local multiLooters = getMultiLooters()
    local lootReady, lootReadyReason = true, ''
    if g.getLootReadiness then
        lootReady, lootReadyReason = g.getLootReadiness(lootAllOn, multiModeOn, currentLooter, liveMainLooter)
    end
    local eventLootRadius = getEventLootRadius(lootAllOn, multiModeOn, currentLooter)
    if skipTracker and skipTracker.is_ready() and g.skipDisplayRows == nil then
        rebuildSkipDisplayRows()
    end
    local skipPendingCount = 0
    if skipTracker and skipTracker.is_ready() then
        if g.skipDisplayTotal ~= nil then
            skipPendingCount = g.skipDisplayTotal
        else
            skipPendingCount = skipTracker.pending_count()
        end
    end
    local activeTargets = activeLootTargetNames(lootAllOn, multiModeOn, currentLooter)
    local lootAnimationActive = TG.refreshLootAnimationActive(mq, TG, activeTargets, nowMS())
    local activeProfileN = countDistinctProfilesForNames(activeTargets, getProfileForMember)
    local setupExpanded = g.perCharProfile
    if not g.minimizedGUI and g.slimGUI then
        g.slimGUI = false
        g.slimWhenExpanded = false
    end
    g.activeTab = UiState.normalizeActiveTab(g.activeTab)
    g.lastRelevantTab = UiState.normalizeRelevantTab(g.lastRelevantTab)
    g.lootManagerPage = UiState.normalizeLootManagerPage(g.lootManagerPage)
    local viewState = UiState.buildViewState(g, {
        Theme = Theme,
        currentLooter = currentLooter,
        liveMainLooter = liveMainLooter,
        activeProfile = activeProfile,
        turboOn = turboOn,
        combatOn = combatOn,
        lootAllOn = lootAllOn,
        multiModeOn = multiModeOn,
        multiLooters = multiLooters,
        lootReady = lootReady,
        lootReadyReason = lootReadyReason,
        eventLootRadius = eventLootRadius,
        lootAnimationActive = lootAnimationActive,
        miniLootAnimation = g.miniLootAnimation ~= false,
        nowMS = nowMS(),
        meleeDistFar = meleeDistFar,
        setupExpanded = setupExpanded,
        getProfileForMember = getProfileForMember,
        skipPendingCount = skipPendingCount,
    })
    viewState.popupIds = {
        tools = TURBO_FOOTER_TOOLS_POPUP,
        help = TG.TURBO_FOOTER_HELP_POPUP,
        wallet = TURBO_FOOTER_WALLET_POPUP,
    }
    g.layoutState = viewState.layoutState
    g.navState = viewState.navState
    g.lootManagerState = viewState.lootManagerState
    g.skipState = viewState.skipState
    g.feedbackState = viewState.feedbackState
    viewState.wallet = cachedWallet;

    --- LuaJIT caps nested closures at ~60 upvalues; pack outer locals into one table so
    --- the inner chunk only closes over `renderFrameOuter`.
    local renderFrameOuter = {
        g = g, mq = mq, ImGui = ImGui, Theme = Theme, Ui = Ui, UiState = UiState,
        MiniView = MiniView, FooterView = FooterView, viewState = viewState,
        TG = TG, TURBO_VERSION = TURBO_VERSION, TURBO_FOOTER_TOOLS_POPUP = TURBO_FOOTER_TOOLS_POPUP,
        ensureE3Vars = ensureE3Vars, nowMS = nowMS, tip = tip,
        renderToolsPopupBody = renderToolsPopupBody, lootNow = lootNow,
        collectGroupMembers = collectGroupMembers, fullColumnWidths = fullColumnWidths,
        renderTopBar = renderTopBar, renderTabBar = renderTabBar,
        skipTracker = skipTracker, thinSep = thinSep, undoSkipRule = undoSkipRule,
        TurboKeyRGB = TurboKeyRGB, Colors = Colors, ACTION_BTN_H = ACTION_BTN_H,
        applyTurboKeyRule = applyTurboKeyRule, getActiveProfile = getActiveProfile,
        renderSkipReview = renderSkipReview, currentLooter = currentLooter,
        lootAllOn = lootAllOn, multiModeOn = multiModeOn, toggleMultiLooter = toggleMultiLooter,
        getMultiLooters = getMultiLooters, eventLootRadius = eventLootRadius,
        setupExpanded = setupExpanded, getProfileForMember = getProfileForMember,
        activeLootTargetNames = activeLootTargetNames,
        countDistinctProfilesForNames = countDistinctProfilesForNames,
        rescanProfiles = rescanProfiles, openProfileExternal = openProfileExternal,
        resolveTurbolootIniPathForProfile = resolveTurbolootIniPathForProfile,
        readLootDistanceFeetForProfile = readLootDistanceFeetForProfile,
        DEFAULT_LOOT_RADIUS = DEFAULT_LOOT_RADIUS, ImGuiCol = ImGuiCol, ImGuiCond = ImGuiCond,
        ImGuiStyleVar = ImGuiStyleVar, ImGuiTableFlags = ImGuiTableFlags,
        ImGuiTableBgTarget = ImGuiTableBgTarget, ImGuiTableColumnFlags = ImGuiTableColumnFlags,
        ImGuiSortDirection = ImGuiSortDirection, IM_COL32 = IM_COL32,
        cachedWallet = cachedWallet, saveSettings = saveSettings, setActiveProfile = setActiveProfile,
        cleanProfileName = cleanProfileName, coloredSep = coloredSep, actionButton = actionButton,
        ruleButton = ruleButton, turboConvertTooltip = turboConvertTooltip,
        RULE_BTN_W = RULE_BTN_W, SLIM_RULE_BTN_H = SLIM_RULE_BTN_H, ActionsView = ActionsView,
        openTurbolootIniFileExternal = openTurbolootIniFileExternal, printTurboDoctor = printTurboDoctor,
        openE3IniExternal = openE3IniExternal, openTurboRepoWeb = openTurboRepoWeb,
        openTurboPatcherExternal = TG.openTurboPatcherExternal,
        openTurbolootConfigFolderExternal = openTurbolootConfigFolderExternal,
        openTurbolootMacrosFolderExternal = openTurbolootMacrosFolderExternal,
        openTurboMobsExportsFolderExternal = TG.openTurboMobsExportsFolderExternal,
        countHandRecipientsInZone = countHandRecipientsInZone,
        profileContextMenu = profileContextMenu, setProfileLootDistance = setProfileLootDistance,
    }
    renderFrameOuter.activeProfile = activeProfile;
    (function()
    local o = renderFrameOuter
    local g, mq, ImGui, Theme, Ui, UiState = o.g, o.mq, o.ImGui, o.Theme, o.Ui, o.UiState
    local MiniView, FooterView, viewState, TG = o.MiniView, o.FooterView, o.viewState, o.TG
    local TURBO_VERSION, TURBO_FOOTER_TOOLS_POPUP = o.TURBO_VERSION, o.TURBO_FOOTER_TOOLS_POPUP
    local ensureE3Vars, nowMS, tip = o.ensureE3Vars, o.nowMS, o.tip
    local renderToolsPopupBody, lootNow = o.renderToolsPopupBody, o.lootNow
    local collectGroupMembers, fullColumnWidths = o.collectGroupMembers, o.fullColumnWidths
    local renderTopBar, renderTabBar = o.renderTopBar, o.renderTabBar
    local skipTracker, thinSep, undoSkipRule = o.skipTracker, o.thinSep, o.undoSkipRule
    local TurboKeyRGB, Colors, ACTION_BTN_H = o.TurboKeyRGB, o.Colors, o.ACTION_BTN_H
    local applyTurboKeyRule, getActiveProfile = o.applyTurboKeyRule, o.getActiveProfile
    local renderSkipReview, currentLooter = o.renderSkipReview, o.currentLooter
    local lootAllOn, multiModeOn, toggleMultiLooter = o.lootAllOn, o.multiModeOn, o.toggleMultiLooter
    local getMultiLooters, eventLootRadius = o.getMultiLooters, o.eventLootRadius
    local setupExpanded, getProfileForMember = o.setupExpanded, o.getProfileForMember
    local activeLootTargetNames, countDistinctProfilesForNames = o.activeLootTargetNames, o.countDistinctProfilesForNames
    local rescanProfiles, openProfileExternal = o.rescanProfiles, o.openProfileExternal
    local resolveTurbolootIniPathForProfile = o.resolveTurbolootIniPathForProfile
    local readLootDistanceFeetForProfile, DEFAULT_LOOT_RADIUS = o.readLootDistanceFeetForProfile, o.DEFAULT_LOOT_RADIUS
    local ImGuiCol, ImGuiCond = o.ImGuiCol, o.ImGuiCond
    local ImGuiStyleVar, ImGuiTableFlags = o.ImGuiStyleVar, o.ImGuiTableFlags
    local ImGuiTableBgTarget, ImGuiTableColumnFlags = o.ImGuiTableBgTarget, o.ImGuiTableColumnFlags
    local ImGuiSortDirection, IM_COL32 = o.ImGuiSortDirection, o.IM_COL32

    local function renderDetachedRulePacksWindow()
        if not g.rulePacksWindowOpen then return end
        local function rpMutedWrap(text)
            ImGui.PushTextWrapPos(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail())
            ImGui.TextColored(0.45, 0.48, 0.55, 1.0, tostring(text or ''))
            ImGui.PopTextWrapPos()
        end
        pcall(function()
            ImGui.SetNextWindowSizeConstraints(520, 420, 960, 980)
            ImGui.SetNextWindowSize(760, 720, ImGuiCond.FirstUseEver)
        end)
        ImGui.PushStyleColor(ImGuiCol.WindowBg, IM_COL32(16, 19, 28, 248))
        ImGui.PushStyleColor(ImGuiCol.TitleBg, IM_COL32(24, 28, 40, 255))
        ImGui.PushStyleColor(ImGuiCol.TitleBgActive, IM_COL32(38, 52, 82, 255))
        ImGui.PushStyleColor(ImGuiCol.Border, IM_COL32(82, 112, 152, 230))
        ImGui.PushStyleVar(ImGuiStyleVar.WindowRounding, 8)
        ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 5)
        ImGui.PushStyleVar(ImGuiStyleVar.PopupRounding, 5)
        local rpOpen, rpDraw = ImGui.Begin('Turbo Rule Packs###Turbo_RulePacks_Window', g.rulePacksWindowOpen)
        g.rulePacksWindowOpen = rpOpen
        if rpDraw == nil then rpDraw = rpOpen end
        if rpDraw then
            local okRulePacks, errRulePacks = pcall(function()
                local assignTargetRp = g.selectedChar or ((currentLooter and currentLooter ~= 'NOBODY') and currentLooter) or 'selected character'
                local activeProfRp = getActiveProfile()
                local activeTargetsRp = activeLootTargetNames(lootAllOn, multiModeOn, currentLooter)
                local activeProfileNRp = countDistinctProfilesForNames(activeTargetsRp, getProfileForMember)
                local showAdvancedSetupRp = g.perCharProfile
                TG.renderRulePacksPanel(g, activeProfRp, assignTargetRp, showAdvancedSetupRp,
                    getProfileForMember, rpMutedWrap, tip, ACTION_BTN_H, rescanProfiles, openProfileExternal)

                local okRB, RB = pcall(require, 'Turbo.rulepack_browser')
                if okRB and RB and RB.render then
                    RB.render({
                        g = g,
                        TG = TG,
                        tip = tip,
                        mutedWrap = rpMutedWrap,
                        ACTION_BTN_H = ACTION_BTN_H,
                        activeProf = activeProfRp,
                        assignTarget = assignTargetRp,
                        showAdvancedSetup = showAdvancedSetupRp,
                        getProfileForMember = getProfileForMember,
                        resolveTurbolootIniPathForProfile = resolveTurbolootIniPathForProfile,
                        profileList = g.profileList,
                        TurboKeyRGB = TurboKeyRGB,
                        openProfile = openProfileExternal,
                        pageMode = true,
                    })
                else
                    rpMutedWrap('Rule pack browser module failed to load.')
                end
            end)
            if not okRulePacks then
                ImGui.TextColored(0.9, 0.35, 0.35, 1.0, 'Rule Packs failed to render.')
                rpMutedWrap(tostring(errRulePacks))
            end
        end
        ImGui.End()
        ImGui.PopStyleVar(3)
        ImGui.PopStyleColor(4)
    end

    ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 4)
    ImGui.PushStyleVar(ImGuiStyleVar.WindowRounding, 8)
    ImGui.PushStyleVar(ImGuiStyleVar.WindowBorderSize, 2)
    ImGui.PushStyleVar(ImGuiStyleVar.ChildRounding, 4)
    ImGui.PushStyleVar(ImGuiStyleVar.PopupRounding, 4)
    ImGui.PushStyleVar(ImGuiStyleVar.GrabRounding, 4)

    ImGui.PushStyleColor(ImGuiCol.WindowBg, IM_COL32(12, 15, 22, 246))
    ImGui.PushStyleColor(ImGuiCol.TitleBg, IM_COL32(14, 17, 24, 255))
    ImGui.PushStyleColor(ImGuiCol.TitleBgActive, IM_COL32(20, 24, 34, 255))
    ImGui.PushStyleColor(ImGuiCol.Border, IM_COL32(185, 140, 70, 225))
    ImGui.PushStyleColor(ImGuiCol.FrameBg, IM_COL32(25, 29, 39, 255))
    ImGui.PushStyleColor(ImGuiCol.FrameBgHovered, IM_COL32(38, 44, 58, 255))
    ImGui.PushStyleColor(ImGuiCol.Header, IM_COL32(32, 54, 82, 255))
    ImGui.PushStyleColor(ImGuiCol.HeaderHovered, IM_COL32(46, 70, 104, 255))
    ImGui.PushStyleColor(ImGuiCol.TableRowBg, IM_COL32(16, 18, 25, 255))
    ImGui.PushStyleColor(ImGuiCol.TableRowBgAlt, IM_COL32(21, 23, 31, 255))
    ImGui.PushStyleColor(ImGuiCol.TableBorderStrong, IM_COL32(58, 58, 48, 255))
    ImGui.PushStyleColor(ImGuiCol.TableBorderLight, IM_COL32(42, 44, 40, 255))

    local function renderTimedChallengeOverlay()
        local okMV, MoneyView = pcall(require, 'Turbo.gains_view')
        if okMV and MoneyView and MoneyView.renderTimedChallengeMini then
            pcall(MoneyView.renderTimedChallengeMini, function()
                g.minimizedGUI = false
                g.slimGUI = false
                g.slimWhenExpanded = false
                if TG.openTurboGainsWindow then TG.openTurboGainsWindow('timed challenge mini')
                else g.gainsWindowOpen = true end
                if g.saveSettings then g.saveSettings() end
            end)
        end
    end

    local function renderGainsWindow()
        if not g.gainsWindowOpen then return end
        if tostring(g.gainsWindowOpenReason or '') == '' then
            g.gainsWindowOpenReason = 'unknown'
            g.gainsWindowOpenAt = os.time()
        end
        pcall(function()
            ImGui.SetNextWindowSizeConstraints(390, 480, 760, 1040)
            local sizeCond = g.gainsWindowSlimSized and ImGuiCond.FirstUseEver or ImGuiCond.Always
            ImGui.SetNextWindowSize(430, 760, sizeCond)
            g.gainsWindowSlimSized = true
            if g.gainsWindowPos and g.gainsWindowPos.x and g.gainsWindowPos.y then
                ImGui.SetNextWindowPos(g.gainsWindowPos.x, g.gainsWindowPos.y, ImGuiCond.FirstUseEver)
            end
        end)
        ImGui.PushStyleColor(ImGuiCol.WindowBg, IM_COL32(12, 15, 22, 250))
        ImGui.PushStyleColor(ImGuiCol.TitleBg, IM_COL32(14, 17, 24, 255))
        ImGui.PushStyleColor(ImGuiCol.TitleBgActive, IM_COL32(20, 24, 34, 255))
        ImGui.PushStyleColor(ImGuiCol.Border, IM_COL32(95, 150, 105, 230))
        ImGui.PushStyleVar(ImGuiStyleVar.WindowRounding, 8)
        ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 5)
        ImGui.PushStyleVar(ImGuiStyleVar.PopupRounding, 5)
        local gainsOpen, gainsDraw = ImGui.Begin('Turbo Gains###Turbo_Gains_Window', g.gainsWindowOpen, ImGuiWindowFlags.NoTitleBar or 0)
        g.gainsWindowOpen = gainsOpen
        if gainsDraw == nil then gainsDraw = gainsOpen end
        if gainsDraw then
            if TG.turboChromeDragApplyActive then TG.turboChromeDragApplyActive('gains') end
            local wx, wy = ImGui.GetWindowPos()
            if wx and wy then g.gainsWindowPos = { x = wx, y = wy } end
            if TG.turboChromeDragReset then TG.turboChromeDragReset('gains') end
            TG.drawTurboGainsTitle(g)
            if TG.turboChromeDragSetBandToCursor then TG.turboChromeDragSetBandToCursor(52, 'gains') end
            if TG.turboChromeDragHandle then TG.turboChromeDragHandle('Drag Turbo Gains header to move the window.', false, 'gains') end
            local okGains, errGains = pcall(function()
                local okMV, MoneyView = pcall(require, 'Turbo.gains_view')
                if okMV and MoneyView and MoneyView.renderTab then
                    MoneyView.renderTab(viewState)
                else
                    ImGui.TextColored(0.95, 0.45, 0.38, 1.0,
                        'TurboGains view module failed to load.')
                    ImGui.TextWrapped(tostring(MoneyView))
                end
            end)
            if not okGains then
                ImGui.TextColored(0.9, 0.35, 0.35, 1.0, 'Turbo Gains failed to render.')
                ImGui.TextWrapped(tostring(errGains))
            end
        end
        ImGui.End()
        ImGui.PopStyleVar(3)
        ImGui.PopStyleColor(4)
    end

    local function renderWaresWindow()
        if not g.waresSidecarModule then
            local okMod, WaresSidecar = pcall(require, 'Turbo.ui.wares_sidecar')
            if not okMod or not WaresSidecar then return end
            g.waresSidecarModule = WaresSidecar
            WaresSidecar.setup({
                Ui = Ui,
                Theme = Theme,
                TurboKeyRGB = TurboKeyRGB,
                ACTION_BTN_H = ACTION_BTN_H,
                writeIniKey = writeIniKey,
                readIniKey = readIniKey,
                readIniSectionPairs = readIniSectionPairs,
                deleteIniKey = deleteIniKey,
                resolveTurbolootIniPathForProfile = resolveTurbolootIniPathForProfile,
                cleanProfileName = cleanProfileName,
                shellOpenFile = shellOpenFile,
                getActiveProfile = getActiveProfile,
                openAllaItemPage = TG.openAllaItemPage,
                canSharedControlWrite = TG.isSharedControlOwner,
                requireSharedControl = TG.requireSharedControl,
                creditGainsSale = function(totalCopper, itemsSold)
                    local engine = rawget(_G, 'TurboGainsEngineM')
                    if type(engine) == 'table' and type(engine.creditSale) == 'function' then
                        return engine.creditSale(totalCopper, itemsSold, {
                            source = 'wares',
                            quiet = true,
                        })
                    end
                    return false
                end,
                saveSettings = saveSettings,
            })
            g.waresSidecarReady = true
        end
        g.waresSidecarModule.render(g)
    end

    local function hasHuntingEntries()
        for _ in pairs(g.huntingTargets or {}) do return true end
        return false
    end

    local function reviewChoiceVariant(active, kind)
        if active then return 'primaryButton' end
        if kind == 'packs' then return 'amberButton' end
        if kind == 'hunting' and (g.huntingEnabled == true or hasHuntingEntries()) then return 'successButton' end
        return 'utilityButton'
    end

    -- ============ MINI MODE ============
    local shouldDraw
    if g.minimizedGUI then
        MiniView.render(viewState, {
            cachedWallet = o.cachedWallet,
            tip = tip,
            renderToolsPopupBody = renderToolsPopupBody,
            lootNow = function()
                if TG.requireSharedControl('Loot Now') then
                    collectGroupMembers()
                    lootNow()
                end
            end,
            stopAllActions = function()
                if TG.requireSharedControl('STOP') then g.stopAllActions() end
            end,
            canSharedControlWrite = TG.isSharedControlOwner,
            sharedControlOwnerName = TG.sharedControlOwnerName,
            toggleTurboFromMini = function(rt)
                if TG.requireSharedControl('Turbo toggle') then
                    if rt.turboOn then
                        TG.setTurboEnabled(false, rt.currentLooter, rt.lootAllOn, rt.multiModeOn)
                    else
                        TG.setTurboEnabled(true, rt.currentLooter, rt.lootAllOn, rt.multiModeOn)
                    end
                end
            end,
            toggleMiniLooterPicker = function()
                collectGroupMembers()
                g.showMiniLooterPicker = not g.showMiniLooterPicker
                if not g.showMiniLooterPicker then
                    g.showMiniRosterEditor = false
                end
            end,
            toggleMiniRosterEditor = function()
                collectGroupMembers()
                g.showMiniRosterEditor = not g.showMiniRosterEditor
            end,
            toggleReviewWindowFromMini = function(hasSkips)
                if hasSkips then
                    g.reviewWindowOpen = not g.reviewWindowOpen
                    g.skipReviewOpen = g.reviewWindowOpen
                end
            end,
            openTurboPatcher = TG.openTurboPatcherExternal,
            setMiniLootMode = function(mode)
                if TG.requireSharedControl('Loot mode') then
                    collectGroupMembers()
                    TG.setLootMode(mode, g.selectedChar or currentLooter)
                end
            end,
            setMiniLooter = function(name, rt)
                if not name or name == '' or name == 'NOBODY' then return end
                if not TG.requireSharedControl('Looter selection') then return end
                collectGroupMembers()
                g.selectedChar = name
                if rt and rt.multiModeOn then
                    toggleMultiLooter(name)
                else
                    g.showMiniLooterPicker = false
                    g.showMiniRosterEditor = false
                    TG.setLootMode('single', name)
                end
            end,
            toggleMiniQuickRosterMember = function(name)
                collectGroupMembers()
                TG.toggleQuickRosterMember(name)
            end,
            expandFromMini = function(targetTab, openSkips, targetPage)
                g.showMiniLooterPicker = false
                g.showMiniRosterEditor = false
                g.minimizedGUI = false
                g.slimGUI = false
                g.slimWhenExpanded = false
                local target = targetTab and UiState.normalizeRelevantTab(targetTab)
                    or UiState.normalizeRelevantTab(g.lastRelevantTab)
                g.activeTab = target
                g.lastRelevantTab = target
                if target == 'setup' or target == 'review' then
                    if targetPage then
                        g.lootManagerPage = UiState.normalizeLootManagerPage(targetPage)
                    elseif openSkips then
                        g.lootManagerPage = 'review'
                    else
                        g.lootManagerPage = UiState.normalizeLootManagerPage(g.lootManagerPage)
                    end
                end
                if openSkips then
                    g.skipReviewOpen = true
                    g.reviewWindowOpen = true
                end
                local expandW = UiState.windowWidthForTab(false, g.activeTab, Theme)
                local expandH = UiState.windowHeightForTab(false, g.activeTab, Theme, {
                    setupExpanded = setupExpanded,
                })
                local basePos = g.fullWindowPos or g.miniWindowPos
                g.pendingExpandPos = TG.getClampedWindowPos(basePos, expandW, expandH)
                o.saveSettings()
            end,
        }, Ui)
        if g.reviewWindowOpen then
            pcall(function()
                ImGui.SetNextWindowSizeConstraints(560, 760, 1120, 1040)
                ImGui.SetNextWindowSize(820, 820, ImGuiCond.FirstUseEver)
                if g.reviewWindowPos and g.reviewWindowPos.x and g.reviewWindowPos.y then
                    ImGui.SetNextWindowPos(g.reviewWindowPos.x, g.reviewWindowPos.y, ImGuiCond.FirstUseEver)
                end
            end)
            ImGui.PushStyleColor(ImGuiCol.WindowBg, IM_COL32(12, 15, 22, 252))
            ImGui.PushStyleColor(ImGuiCol.TitleBg, IM_COL32(14, 17, 24, 255))
            ImGui.PushStyleColor(ImGuiCol.TitleBgActive, IM_COL32(20, 24, 34, 255))
            ImGui.PushStyleColor(ImGuiCol.Border, IM_COL32(185, 140, 70, 225))
            ImGui.PushStyleVar(ImGuiStyleVar.WindowRounding, 8)
            ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 5)
            ImGui.PushStyleVar(ImGuiStyleVar.PopupRounding, 5)
            local reviewOpen, reviewDraw = ImGui.Begin('Turbo Review###Turbo_Review_Window', g.reviewWindowOpen, ImGuiWindowFlags.NoTitleBar or 0)
            g.reviewWindowOpen = reviewOpen
        if reviewDraw == nil then reviewDraw = reviewOpen end
        if reviewDraw then
            if TG.turboChromeDragApplyActive then TG.turboChromeDragApplyActive('review') end
            local wx, wy = ImGui.GetWindowPos()
            if wx and wy then g.reviewWindowPos = { x = wx, y = wy } end
            if TG.turboChromeDragReset then TG.turboChromeDragReset('review') end
            TG.drawTurboReviewTitle(g)
            if TG.turboChromeDragSetBandToCursor then TG.turboChromeDragSetBandToCursor(52, 'review') end
            if TG.turboChromeDragHandle then TG.turboChromeDragHandle('Drag Turbo Review header to move the window.', false, 'review') end
            if g.reviewWindowOpen then
            local okReview, errReview = pcall(function()
                    local function reviewMutedWrap(text)
                        ImGui.PushTextWrapPos(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail())
                        ImGui.TextColored(0.45, 0.48, 0.55, 1.0, tostring(text or ''))
                        ImGui.PopTextWrapPos()
                    end
                    g.reviewSubPage = g.reviewSubPage or 'review'
                    if Ui.buttonVariant('Full##review_sub_review', reviewChoiceVariant(g.reviewSubPage == 'review', 'full'), 82, ACTION_BTN_H) then
                        g.reviewSubPage = 'review'
                    end
                    ImGui.SameLine()
                    if Ui.buttonVariant('Packs##review_sub_rulepacks', reviewChoiceVariant(g.reviewSubPage == 'rulepacks', 'packs'), 82, ACTION_BTN_H) then
                        g.reviewSubPage = 'rulepacks'
                    end
                    ImGui.SameLine()
                    if Ui.buttonVariant('Hunting##review_sub_hunting', reviewChoiceVariant(g.reviewSubPage == 'hunting', 'hunting'), 92, ACTION_BTN_H) then
                        g.reviewSubPage = 'hunting'
                    end
                    ImGui.Separator()
                    if g.reviewSubPage == 'rulepacks' then
                        local assignTargetRp = g.selectedChar or ((currentLooter and currentLooter ~= 'NOBODY') and currentLooter) or 'selected character'
                        local activeProfRp = getActiveProfile()
                        local activeTargetsRp = activeLootTargetNames(lootAllOn, multiModeOn, currentLooter)
                        local activeProfileNRp = countDistinctProfilesForNames(activeTargetsRp, getProfileForMember)
                        local showAdvancedSetupRp = g.perCharProfile
                        TG.renderRulePacksPanel(g, activeProfRp, assignTargetRp, showAdvancedSetupRp,
                            getProfileForMember, reviewMutedWrap, tip, ACTION_BTN_H, rescanProfiles, openProfileExternal)
                        local okRB, RB = pcall(require, 'Turbo.rulepack_browser')
                        if okRB and RB and RB.render then
                            RB.render({
                                g = g,
                                TG = TG,
                                tip = tip,
                                mutedWrap = reviewMutedWrap,
                                ACTION_BTN_H = ACTION_BTN_H,
                                activeProf = activeProfRp,
                                assignTarget = assignTargetRp,
                                showAdvancedSetup = showAdvancedSetupRp,
                                getProfileForMember = getProfileForMember,
                                resolveTurbolootIniPathForProfile = resolveTurbolootIniPathForProfile,
                                profileList = g.profileList,
                                TurboKeyRGB = TurboKeyRGB,
                                openProfile = openProfileExternal,
                                pageMode = true,
                            })
                        else
                            reviewMutedWrap('Rule pack browser module failed to load.')
                        end
                    elseif g.reviewSubPage == 'hunting' then
                        reviewMutedWrap('Manage item alerts for drops you are actively hunting. TurboLoot reads this list once per loot run and checks it in memory.')
                        ImGui.Dummy(0, 4)
                        TG.drawHuntingPanel(g, tip, ACTION_BTN_H)
                    else
                        renderSkipReview(g, skipTracker, tip, thinSep, undoSkipRule, TurboKeyRGB, Colors,
                            ACTION_BTN_H, true, applyTurboKeyRule, getActiveProfile)
                    end
                end)
                if not okReview then
                    ImGui.TextColored(0.9, 0.35, 0.35, 1.0, 'Review failed to render.')
                    ImGui.TextWrapped(tostring(errReview))
                end
            end
            end
            ImGui.End()
            ImGui.PopStyleVar(3)
            ImGui.PopStyleColor(4)
        end
        renderDetachedRulePacksWindow()
        renderTimedChallengeOverlay()
        renderGainsWindow()
        renderWaresWindow()
        ImGui.PopStyleColor(12)
        ImGui.PopStyleVar(6)
        return
    end

    -- ============ FULL MODE ============
    local fullDefaultW = UiState.windowWidthForTab(false, g.activeTab, Theme)
    local fullDefaultH = UiState.windowHeightForTab(false, g.activeTab, Theme, {
        setupExpanded = setupExpanded,
    })
    pcall(function()
        if g.slimGUI then
            -- Tall narrow panel: tagging-focused (TurboKey column, hub on top).
            ImGui.SetNextWindowSizeConstraints(248, 400, 430, 980)
        else
            local minW = Theme.layout.windowMinW or fullDefaultW or 480
            local maxW = Theme.layout.windowMaxW or 760
            local minH = 620
            ImGui.SetNextWindowSizeConstraints(minW, minH, maxW, 1040)
            local saved = g.fullWindowSize
            local targetW = (saved and saved.w) or fullDefaultW
            local targetH = (saved and saved.h) or fullDefaultH
            ImGui.SetNextWindowSize(targetW, targetH, ImGuiCond.FirstUseEver)
        end
    end)

    -- 3.8.29: if Mini just expanded, place Full at Mini's last on-screen pos.
    -- One-shot: cleared after consumption so the user can drag the Full window freely afterward.
    if g.pendingExpandPos then
        pcall(function()
            ImGui.SetNextWindowPos(g.pendingExpandPos.x, g.pendingExpandPos.y, ImGuiCond.Always)
        end)
        g.pendingExpandPos = nil
    end

    local windowTitle = string.format('Turbo v%s debug###Turbo_Full', TURBO_VERSION)
    local windowFlags = ImGuiWindowFlags.NoTitleBar or 0
    g.windowOpen, shouldDraw = ImGui.Begin(windowTitle, g.windowOpen, windowFlags)
    if shouldDraw == nil then shouldDraw = g.windowOpen end
    if shouldDraw then
        if TG.turboChromeDragApplyActive then TG.turboChromeDragApplyActive('main') end
        pcall(function()
            local wx, wy = ImGui.GetWindowPos()
            if wx and wy then g.fullWindowPos = { x = wx, y = wy } end
        end)
        if g.lastSlimGUIForResize == nil then
            g.lastSlimGUIForResize = g.slimGUI
            if g.slimGUI then
                pcall(function()
                    ImGui.SetWindowSize(
                        g.slimIniExpanded and 390 or 280,
                        UiState.windowHeightForTab(true, g.activeTab, Theme)
                    )
                end)
            elseif not g.userSizedFullWindow then
                local saved = g.fullWindowSize
                pcall(function()
                    ImGui.SetWindowSize(
                        (saved and saved.w) or fullDefaultW,
                        (saved and saved.h) or fullDefaultH
                    )
                end)
            end
        elseif g.slimGUI ~= g.lastSlimGUIForResize then
            g.lastSlimGUIForResize = g.slimGUI
            local targetW = g.slimGUI and (g.slimIniExpanded and 390 or 280)
                or ((g.fullWindowSize and g.fullWindowSize.w) or fullDefaultW)
            local targetH = g.slimGUI and UiState.windowHeightForTab(true, g.activeTab, Theme)
                or ((g.fullWindowSize and g.fullWindowSize.h) or fullDefaultH)
            pcall(function() ImGui.SetWindowSize(targetW, targetH) end)
        end
        if not g.slimGUI then
            local okSize, sx, sy = pcall(ImGui.GetWindowSize)
            if okSize and sx and sy then
                g.fullWindowSize = { w = sx, h = sy }
                g.userSizedFullWindow = true
            end
        end

        ImGui.PushStyleVar(ImGuiStyleVar.FramePadding, 4, 3)
        local colW2, colW3, colW4, colAvail, colSp = fullColumnWidths()  -- cached once per frame

        -- Hoisted cursor/target locals: used across multiple tab sections.
        local cursorItem   = mq.TLO.Cursor.Name()
        local hasCursor    = cursorItem and cursorItem ~= '' and cursorItem ~= 'NULL'
        local cursorStack  = hasCursor and (tonumber(mq.TLO.Cursor.Stack()) or 1) or 1
        local targetName   = mq.TLO.Target.Name()
        local targetType   = mq.TLO.Target.Type()
        local hasPcTarget  = targetName and targetType and targetType == 'PC'
        local zoneShort    = mq.TLO.Zone.ShortName() or ''
        local inConvertZone = zoneShort == 'poknowledge' or zoneShort == 'freeporttemple'
        viewState.runtime.colW2 = colW2
        viewState.runtime.colW3 = colW3
        viewState.runtime.colW4 = colW4
        viewState.runtime.colAvail = colAvail
        viewState.runtime.colSp = colSp
        viewState.runtime.cursorItem = cursorItem
        viewState.runtime.hasCursor = hasCursor
        viewState.runtime.cursorStack = cursorStack
        viewState.runtime.targetName = targetName
        viewState.runtime.hasPcTarget = hasPcTarget
        viewState.runtime.zoneShort = zoneShort
        viewState.runtime.inConvertZone = inConvertZone
        -- Track cursor item for TurboKey hint; update handQty on new item
        if hasCursor and cursorItem ~= g.lastCursorItem then
            g.lastCursorItem = cursorItem
            g.handQty = tostring(cursorStack)
        end

        -- ============ TOP BAR + TAB BAR ============
        g.cachedEventRadiusDisplay = eventLootRadius or g.lootRadius
        local function rememberFullWindowSize()
            local okSize, sx, sy = pcall(ImGui.GetWindowSize)
            if okSize and sx and sy and not g.slimGUI then
                g.fullWindowSize = { w = sx, h = sy }
                g.userSizedFullWindow = true
            end
        end

        local function ensureWindowHeight(targetH)
            -- Full mode keeps one stable shell size. Tall pages scroll instead
            -- of growing the outer window and causing tab-to-tab jitter.
            return targetH
        end

        g.rememberTabWindowSize = rememberFullWindowSize
        g.restoreTabWindowSize = nil
        g.ensureWindowHeight = ensureWindowHeight

        -- Tab switches change content only; the full window keeps one shared
        -- size so header controls and page chrome do not jump around.
        if g.activeTab ~= g.lastActiveTab then
            g.lastActiveTab = g.activeTab
        end
        g.lastSetupExpandedForResize = setupExpanded
        if TG.turboChromeDragReset then TG.turboChromeDragReset('main') end
        TG.drawTurboFullTitle()
        renderTopBar(g, viewState)
        if TG.turboChromeDragSetBandToCursor then TG.turboChromeDragSetBandToCursor(nil, 'main') end
        if TG.turboChromeDragHandle then TG.turboChromeDragHandle('Drag empty Turbo header space to move the window.', false, 'main') end
        pcall(function()
            local okUC, UC = pcall(require, 'Turbo.update_check')
            if okUC and UC and UC.draw_banner then
                UC.draw_banner(g, {
                    onUpdate = function()
                        if TG.openTurboPatcherExternal then TG.openTurboPatcherExternal() end
                    end,
                    onDismiss = function() end,
                })
            end
        end)
        ImGui.Dummy(0, 2)
        renderTabBar(g, viewState)
        ImGui.Dummy(0, 4)
        --- MQ Next has repeatedly faulted inside EndChild for the outer
        --- ##turbo_content wrapper. Render tab content directly in the main
        --- window; inner lists/tables still provide their own scrolling.
        do

        -- ============ SETUP TAB ============
        if g.activeTab == 'setup' then
        if TG.ensureProfileCacheSeeded then TG.ensureProfileCacheSeeded() end
        o.activeProfile = getActiveProfile()
        local function renderIniToolsPanel()
            ImGui.TextColored(0.65, 0.72, 0.9, 1.0, 'INI profiles')
            ImGui.SameLine()
            if ImGui.SmallButton('Scan Config##setup_ini_scan') then
                local count, elapsed = rescanProfiles()
                g.statusMessage = string.format('Scanned Config/Macros: %d profile%s (%dms)',
                    count or #g.profileList, (count or #g.profileList) == 1 and '' or 's', elapsed or 0)
            end
            tip('Scan Config and Macros for turboloot*.ini files and refresh the profile list.')
            local toolCols, toolW, toolGap = Ui.adaptiveColumns(4, 88, 4)
            if Ui.buttonVariant('Create##setup_ini_create', 'successButton', toolW, 0) then
                g.iniToolMode = 'create'
                g.iniToolBuf = 'turboloot.ini'
            end
            tip('Create a new profile in Config from the starter template. Names must start with turboloot (e.g. turboloot_mage.ini).')
            Ui.gridSameLine(2, toolCols, toolGap)
            if Ui.buttonVariant('Clone##setup_ini_clone', 'secondaryButton', toolW, 0) then
                g.iniToolMode = 'clone'
                g.iniCloneSource = getActiveProfile()
                g.iniToolBuf = (getActiveProfile() or 'turboloot.ini'):gsub('%.ini$', '') .. '_copy.ini'
            end
            tip('Copy the active INI to a new profile name in Config.')
            Ui.gridSameLine(3, toolCols, toolGap)
            if Ui.buttonVariant('Import##setup_ini_import', 'secondaryButton', toolW, 0) then
                g.iniToolMode = 'import'
                g.iniToolBuf = ''
            end
            tip('Copy an INI from Config, Macros, or a full path into Config. Use Browse Config to open the folder.')
            Ui.gridSameLine(4, toolCols, toolGap)
            if Ui.buttonVariant('Export##setup_ini_export', 'secondaryButton', toolW, 0) then
                local path, err = TG.exportProfile(getActiveProfile())
                if path then
                    g.statusMessage = 'Exported: ' .. path
                    if TG.openTurboExportsFolderExternal then TG.openTurboExportsFolderExternal() end
                else
                    g.statusMessage = 'Export failed: ' .. tostring(err or '')
                end
            end
            tip('Copy the active INI to Config\\Turbo\\exports and open that folder.')
            if g.iniToolMode then
                ImGui.SetNextItemWidth(math.max(180, Ui.availX(260)))
                if ImGui.InputTextWithHint then
                    g.iniToolBuf = ImGui.InputTextWithHint('##setup_ini_tool_buf',
                        g.iniToolMode == 'import' and 'file name or full path' or 'new profile name (turboloot...)',
                        tostring(g.iniToolBuf or ''))
                else
                    g.iniToolBuf = ImGui.InputText('##setup_ini_tool_buf', tostring(g.iniToolBuf or ''))
                end
                if g.iniToolMode == 'import' then
                    if Ui.buttonVariant('Browse Config##setup_ini_browse', 'secondaryButton', 110, 0) then
                        o.openTurbolootConfigFolderExternal()
                    end
                    tip('Open Config in Explorer to find an INI to import.')
                    ImGui.SameLine()
                end
                if Ui.buttonVariant('Apply##setup_ini_tool_apply', 'primaryButton', 72, 0) then
                    local path, nameOrErr
                    if g.iniToolMode == 'create' then
                        path, nameOrErr = TG.createProfileFromTemplate(g.iniToolBuf, { setActive = true })
                    elseif g.iniToolMode == 'clone' then
                        path, nameOrErr = TG.cloneProfile(g.iniCloneSource or getActiveProfile(), g.iniToolBuf, { setActive = true })
                    elseif g.iniToolMode == 'import' then
                        path, nameOrErr = TG.importProfile(g.iniToolBuf, { setActive = true })
                    end
                    if path then
                        g.statusMessage = string.format('INI %s ready: %s', g.iniToolMode, tostring(nameOrErr or path))
                        g.iniToolMode = nil
                        g.iniToolBuf = ''
                    else
                        g.statusMessage = tostring(nameOrErr or 'INI action failed.')
                    end
                end
                ImGui.SameLine()
                if Ui.buttonVariant('Cancel##setup_ini_tool_cancel', 'secondaryButton', 72, 0) then
                    g.iniToolMode = nil
                    g.iniToolBuf = ''
                end
            end
            ImGui.Separator()
        end
        local function renderLootManagerSetupBody()
        local setupWriteLocked = not TG.isSharedControlOwner()
        if setupWriteLocked then
            TG.renderSharedControlSetupNotice(tip)
            ImGui.BeginDisabled()
        end
        if #g.profileList == 0 then
            ImGui.TextColored(0.82, 0.82, 0.75, 1.0, 'No turboloot profiles found yet.')
            ImGui.TextColored(0.45, 0.48, 0.55, 1.0,
                'Press Create to add turboloot.ini from the starter template, or Scan Config if you already have INIs on disk.')
            if Ui.buttonVariant('Create turboloot.ini##setup_empty_create', 'successButton', 180, 0) then
                local path, nameOrErr = TG.createProfileFromTemplate('turboloot.ini', { setActive = true })
                g.statusMessage = path and ('Created ' .. tostring(nameOrErr or 'turboloot.ini'))
                    or tostring(nameOrErr or 'Create failed.')
            end
            ImGui.SameLine()
            if Ui.buttonVariant('Scan Config##setup_empty_scan', 'secondaryButton', 120, 0) then
                local count, elapsed = rescanProfiles()
                g.statusMessage = string.format('Scanned: %d profile%s (%dms)',
                    count or #g.profileList, (count or #g.profileList) == 1 and '' or 's', elapsed or 0)
            end
            if setupWriteLocked then ImGui.EndDisabled() end
            return
        end
        if #g.profileList > 0 then
            local showProfCombo = true
            if g.slimGUI then
                local prevIniOpen = g.slimIniExpanded
                if ImGui.SetNextItemOpen then ImGui.SetNextItemOpen(g.slimIniExpanded) end
                g.slimIniExpanded = ImGui.CollapsingHeader('Loot setup##slimprof')
                if g.slimIniExpanded ~= prevIniOpen then
                    o.saveSettings()
                    if g.slimIniExpanded then
                        pcall(function() ImGui.SetWindowSize(390, 720) end)
                    end
                end
                showProfCombo = g.slimIniExpanded
                if ImGui.IsItemHovered() then
                    tip('Mode, active looters, and INIs in one place.')
                end
            end
            if showProfCombo then
                local activeProf = getActiveProfile()
                local showAdvancedSetup = g.perCharProfile

                local function setIniMode(usePerChar)
                    if usePerChar == g.perCharProfile then return end
                    if usePerChar then
                        g.perCharProfile = true
                        if currentLooter and currentLooter ~= '' and currentLooter ~= 'NOBODY' then
                            g.selectedChar = currentLooter
                        end
                        g.statusMessage = 'Specific INIs ON: pick a character and assign an INI below'
                        o.saveSettings()
                    else
                        local sharedProfile = getActiveProfile()
                        g.perCharProfile = false
                        g.cachedProfile = sharedProfile
                        o.saveSettings()
                        o.setActiveProfile(sharedProfile)
                        g.statusMessage = string.format('Shared INI ON: %s for all characters', sharedProfile)
                    end
                end

                ImGui.Separator()

                local setupPage = 'loot'

                if setupPage == 'loot' then

                ImGui.TextColored(0.65, 0.72, 0.9, 1.0, '1) Single or multi looter?')
                if Ui.buttonVariant('Single##setup_mode_single', (not lootAllOn and not multiModeOn) and 'successButton' or 'secondaryButton', 66, 0) then
                    TG.setLootMode('single', g.selectedChar or currentLooter)
                end
                tip('Use one active looter.')
                ImGui.SameLine()
                if Ui.buttonVariant('Multi##setup_mode_multi', multiModeOn and 'successButton' or 'secondaryButton', 60, 0) then
                    TG.setLootMode('multi', g.selectedChar or currentLooter)
                end
                tip('Use two or more active looters.')
                ImGui.SameLine()
                if Ui.buttonVariant('All##setup_mode_all', lootAllOn and 'successButton' or 'secondaryButton', 44, 0) then
                    TG.setLootMode('all', g.selectedChar or currentLooter)
                end
                tip('Every current group member loots.')
                ImGui.Separator()
                local selectedForSingle = g.selectedChar or ((currentLooter ~= 'NOBODY') and currentLooter)
                    or (g.members[1] or mq.TLO.Me.Name() or '')
                if TG.renderSetupStatusBanner then
                    TG.renderSetupStatusBanner(g, {
                        ImGui = ImGui,
                        Ui = Ui,
                        tip = tip,
                        TG = TG,
                        lootAllOn = lootAllOn,
                        multiModeOn = multiModeOn,
                        selectedForSingle = selectedForSingle,
                        getMultiLooters = getMultiLooters,
                    })
                end
                if not lootAllOn then
                ImGui.TextColored(0.65, 0.72, 0.9, 1.0, '2) Who loots?')
                local rosterNames = TG.getQuickRosterNames()
                if #rosterNames > 0 then
                    local rosterCols, rosterW, rosterGap = Ui.adaptiveColumns(3, 82, 4)
                    for i, name in ipairs(rosterNames) do
                        Ui.gridSameLine(i, rosterCols, rosterGap)
                        local variant = 'secondaryButton'
                        if multiModeOn then
                            variant = g.multiLooters[name] and 'successButton' or 'secondaryButton'
                        elseif name == selectedForSingle then
                            variant = 'successButton'
                        end
                        if Ui.buttonVariant(name .. '##setup_lootpick_' .. name, variant, rosterW, 0) then
                            if not g.selectedChar or g.selectedChar == '' then
                                g.selectedChar = name
                            end
                            if multiModeOn then
                                toggleMultiLooter(name)
                            else
                                TG.setLootMode('single', name)
                                selectedForSingle = name
                                local st = TG.getE3SetupStatus(name)
                                if st and not st.ok then
                                    g.statusMessage = string.format(
                                        '%s needs Turbo setup before auto-loot works - use Setup %s above or /lua run Turbo setup.',
                                        name, name)
                                end
                            end
                        end
                        tip(
                            (multiModeOn and ('Toggle ' .. name .. ' in the Multi looter set.'))
                            or (name == selectedForSingle and ('Keep ' .. name .. ' as the active single looter.')
                                or ('Set ' .. name .. ' as the active single looter.')))
                    end
                end
                end

                ImGui.Separator()
                ImGui.TextColored(0.65, 0.72, 0.9, 1.0, '3) What INI?')
                local iniCols, iniBtnW, iniGap = Ui.adaptiveColumns(2, 96, 4)
                Ui.gridSameLine(1, iniCols, iniGap)
                if Ui.buttonVariant('Shared##setup_shared_mode', showAdvancedSetup and 'secondaryButton' or 'primaryButton', iniBtnW, 0) then
                    setIniMode(false)
                    showAdvancedSetup = false
                    activeProf = getActiveProfile()
                end
                tip('One INI applies to every active looter.')
                Ui.gridSameLine(2, iniCols, iniGap)
                if Ui.buttonVariant('Specific##setup_perchar_mode', showAdvancedSetup and 'primaryButton' or 'secondaryButton', iniBtnW, 0) then
                    setIniMode(true)
                    showAdvancedSetup = true
                end
                tip('Different characters can use different turboloot*.ini files.')

                if showAdvancedSetup and #g.members > 0 then
                    ImGui.Dummy(0, 2)
                    ImGui.TextColored(0.65, 0.72, 0.9, 1.0, 'INI target')
                    ImGui.SameLine()
                    local targetForIni = g.selectedChar or ((currentLooter and currentLooter ~= 'NOBODY') and currentLooter) or g.members[1]
                    for i, name in ipairs(g.members) do
                        if name and name ~= '' and name ~= 'NOBODY' then
                            if i > 1 then ImGui.SameLine(0, 4) end
                            local targetActive = (name == targetForIni)
                            if Ui.buttonVariant(name .. '##setup_ini_target_' .. name,
                                targetActive and 'primaryButton' or 'secondaryButton', 82, 0) then
                                g.selectedChar = name
                                if g.charProfiles[name] then g.cachedProfile = g.charProfiles[name] end
                                g.statusMessage = string.format('INI target: %s', name)
                            end
                            tip('Choose whose INI changes when you click an INI row below.')
                        end
                    end
                end

                ImGui.Separator()
                renderIniToolsPanel()
                ImGui.Dummy(0, 2)
                local assignTarget = g.selectedChar or ((currentLooter and currentLooter ~= 'NOBODY') and currentLooter) or 'selected character'
                ImGui.TextColored(0.6, 0.65, 0.72, 1.0,
                    showAdvancedSetup and string.format('Assign INI to %s', assignTarget) or 'Shared INI')
                ImGui.SameLine()
                if ImGui.SmallButton('Resync##syncprof') then
                    syncProfileAssignments()
                    if g.refreshActiveIniState then g.refreshActiveIniState(false) end
                end
                tip('Resend current INI assignments and refresh active INI settings.')

                activeProf = getActiveProfile()
                local activeProfLc = activeProf:lower()
                local iniFlags = ImGuiTableFlags.RowBg + ImGuiTableFlags.Borders
                if ImGuiTableFlags.Sortable then iniFlags = iniFlags + ImGuiTableFlags.Sortable end
                local iniTableCols = showAdvancedSetup and 2 or 1
                if ImGui.BeginTable('##setup_ini_profiles_combined', iniTableCols, iniFlags) then
                    local iniColFlags = ImGuiTableColumnFlags
                    ImGui.TableSetupColumn('INI', iniColFlags.WidthStretch or 0, showAdvancedSetup and 0.42 or 1.0, 0)
                    if showAdvancedSetup then
                        ImGui.TableSetupColumn('Using', iniColFlags.WidthStretch or 0, 0.58, 2)
                    end
                    ImGui.TableHeadersRow()
                    local profileRows = {}
                    for i = 1, #g.profileList do profileRows[i] = g.profileList[i] end
                    local sort_specs_ok, sort_specs = pcall(ImGui.TableGetSortSpecs)
                    if sort_specs_ok and sort_specs and sort_specs.SpecsCount and sort_specs.SpecsCount > 0 then
                        local spec = sort_specs:Specs(1)
                        local uid = spec and spec.ColumnUserID or 0
                        table.sort(profileRows, function(a, b)
                            local av, bv
                            if showAdvancedSetup and uid == 2 then
                                local function usersForProfile(profile)
                                    local pLower = tostring(profile or ''):lower()
                                    local names = {}
                                    for _, name in ipairs(g.members) do
                                        if getProfileForMember(name):lower() == pLower then
                                            names[#names + 1] = name
                                        end
                                    end
                                    table.sort(names)
                                    return table.concat(names, ', '), #names
                                end
                                local at, ac = usersForProfile(a)
                                local bt, bc = usersForProfile(b)
                                av = string.format('%03d %s', ac, at)
                                bv = string.format('%03d %s', bc, bt)
                            else
                                av = tostring(a or ''):lower()
                                bv = tostring(b or ''):lower()
                            end
                            if av == bv then return tostring(a or ''):lower() < tostring(b or ''):lower() end
                            if ImGuiSortDirection and spec.SortDirection == ImGuiSortDirection.Ascending then
                                return av < bv
                            end
                            return av > bv
                        end)
                        if sort_specs.SpecsDirty then sort_specs.SpecsDirty = false end
                    end
                    for _, pName in ipairs(profileRows) do
                        local pLower = pName:lower()
                        local isSelected = (pLower == activeProfLc)
                        local users = {}
                        local anyActive = false
                        for _, name in ipairs(g.members) do
                            if getProfileForMember(name):lower() == pLower then
                                local memberActive = lootAllOn
                                    or (multiModeOn and g.multiLooters[name])
                                    or ((not multiModeOn) and currentLooter and currentLooter ~= 'NOBODY' and name == currentLooter)
                                if memberActive then anyActive = true end
                                table.insert(users, name)
                            end
                        end

                        ImGui.TableNextRow()
                        if anyActive then
                            ImGui.TableSetBgColor(ImGuiTableBgTarget.RowBg0, IM_COL32(35, 76, 48, 95))
                        elseif isSelected then
                            ImGui.TableSetBgColor(ImGuiTableBgTarget.RowBg0, IM_COL32(42, 120, 72, 95))
                        end

                        ImGui.TableSetColumnIndex(0)
                        if isSelected then
                            ImGui.PushStyleColor(ImGuiCol.Header, IM_COL32(42, 120, 72, 125))
                            ImGui.PushStyleColor(ImGuiCol.HeaderHovered, IM_COL32(52, 145, 86, 155))
                            ImGui.PushStyleColor(ImGuiCol.Text, IM_COL32(188, 245, 198, 255))
                        end
                        ImGui.Selectable(pName .. '##setup_ini_pick_' .. pName, isSelected)
                        if isSelected then ImGui.PopStyleColor(3) end
                        --- Use mouse click detection, not Selectable's return value: some ImgGui builds
                        --- report "picked" across multiple frames while the focused row stays selected,
                        --- which spammed /e3varset TurboLootIni. IsItemClicked() is one-shot per click
                        --- and still fires when clicking the already-selected row (explicit re-push).
                        if ImGui.IsItemClicked() then
                            o.setActiveProfile(pName)
                            activeProf = pName
                            activeProfLc = pLower
                        end
                        if ImGui.IsItemHovered() then
                            tip(showAdvancedSetup
                                and 'Click to assign this INI to the selected character. Right-click for options.'
                                or 'Click to set this as the shared INI for every active looter. Right-click for options.')
                        end
                        o.profileContextMenu(pName, '##ctxprofile_' .. pName)
                        if isSelected then ImGui.SetItemDefaultFocus() end

                        if showAdvancedSetup then
                            ImGui.TableSetColumnIndex(1)
                            local userText
                            userText = (#users > 0) and table.concat(users, ', ') or '-'
                            local maxChars = g.slimGUI and 18 or 42
                            if #userText > maxChars then userText = userText:sub(1, maxChars - 2) .. '..' end
                            ImGui.TextColored(anyActive and 0.5 or 0.55, anyActive and 0.9 or 0.55,
                                anyActive and 0.58 or 0.62, 1.0, userText)
                            if ImGui.IsItemHovered() then
                                tip(#users > 0 and table.concat(users, ', ') or 'No current group members use this INI')
                            end
                        end
                    end
                    ImGui.EndTable()
                end

                if #g.members > 0 then
                    ImGui.Separator()
                    local quickOpen = ImGui.CollapsingHeader('Edit quick roster for mini view###setup_quick_roster')
                    tip('Choose which character buttons appear in the mini view. This does not change INI assignments.')
                    local rosterConfigured = false
                    local rosterSelected = 0
                    local viableRoster = 0
                    for _, name in ipairs(g.members) do
                        if name and name ~= '' and name ~= 'NOBODY' then
                            viableRoster = viableRoster + 1
                            if g.quickLootRoster[name] then rosterSelected = rosterSelected + 1 end
                        end
                    end
                    rosterConfigured = rosterSelected > 0 and rosterSelected < viableRoster
                    if quickOpen then
                        local quickCols, quickW, quickGap = Ui.adaptiveColumns(3, 82, 4)
                        local quickIdx = 0
                        for i, name in ipairs(g.members) do
                            if name ~= 'NOBODY' and name ~= '' then
                                quickIdx = quickIdx + 1
                                Ui.gridSameLine(quickIdx, quickCols, quickGap)
                                local inRoster = rosterConfigured and g.quickLootRoster[name] or true
                                if Ui.buttonVariant(name .. '##setup_quickroster_' .. name, inRoster and 'primaryButton' or 'secondaryButton', quickW, 0) then
                                    TG.toggleQuickRosterMember(name)
                                end
                                tip((inRoster and 'Remove ' or 'Add ') .. name .. ' from the mini-view looter buttons.')
                            end
                        end
                    end
                end

                ImGui.Separator()
                TG.renderStartupToolsSetupPanel(tip)

                ImGui.Separator()
                local confirmReviewOn = g.confirmSingleReviewRules ~= false
                local quickStartOn = g.showQuickStartButton ~= false
                local stopBtnOn = g.showStopAllButton ~= false
                local debugProfile = showAdvancedSetup and getProfileForMember(assignTarget) or activeProf
                debugProfile = o.cleanProfileName(debugProfile) or activeProf
                local debugOn = TG.readTurboLootDebugEnabledForProfile(debugProfile)
                local reclaimDcAfterLootOn = TG.readTurboLootReclaimDcAfterLootForProfile(debugProfile)
                local nextReclaimDcAfterLoot = ImGui.Checkbox(
                    'Auto reclaim Diamond Coins after loot##setup_reclaim_dc_after_loot',
                    reclaimDcAfterLootOn)
                if nextReclaimDcAfterLoot ~= reclaimDcAfterLootOn then
                    if TG.setTurboLootReclaimDcAfterLootForProfile(debugProfile, nextReclaimDcAfterLoot) then
                        g.tlSettingsDraftProfile = nil
                    end
                end
                tip((reclaimDcAfterLootOn and 'ON: ' or 'OFF: ')
                    .. 'At the end of normal /mac turboloot only, reclaim inventory Diamond Coin stacks to alt-currency. No sell/bank/tribute/unload effect.')
                ImGui.Dummy(0, 2)
                local settingsCols, settingsW, settingsGap = Ui.adaptiveColumns(2, 118, 4)
                if Ui.buttonVariant('Turbo INI Config##setup_edit_tl_settings', 'successButton', settingsW, 0) then
                    g.tlSettingsProfile = debugProfile
                    g.tlSettingsDraftProfile = nil
                    g.tlSettingsWindowOpen = true
                end
                tip('Edit common TurboLoot [Settings] keys for this INI, including loot distance, value thresholds, channels, wildcards, and TurboGive.')
                Ui.gridSameLine(2, settingsCols, settingsGap)
                if Ui.buttonVariant('Print Settings##setup_ini_snapshot', 'infoButton', settingsW, 0) then
                    TG.printTurboSnapshot()
                end
                tip('Print this character\'s currently active TurboLoot INI settings to chat, grouped by category.')
                ImGui.Dummy(0, 4)

                local safetyCols, safetyW, safetyGap = Ui.adaptiveColumns(6, 62, 4)
                if Ui.buttonVariant('Confirm##setup_confirm_review',
                    confirmReviewOn and 'primaryButton' or 'secondaryButton', safetyW, 0) then
                    g.confirmSingleReviewRules = not confirmReviewOn
                    o.saveSettings()
                    g.statusMessage = string.format('Risky action confirmations: %s', g.confirmSingleReviewRules and 'ON' or 'OFF')
                end
                tip((confirmReviewOn and 'ON: ' or 'OFF: ') .. 'Asks before DESTROY, IGNORE, Ignore all, Clear all skips, and Actions Destroy.')
                Ui.gridSameLine(2, safetyCols, safetyGap)
                local waresAutoOn = g.waresAutoShow ~= false
                if Ui.buttonVariant('Wares##setup_wares_autoshow',
                    waresAutoOn and 'primaryButton' or 'secondaryButton', safetyW, 0) then
                    g.waresAutoShow = not waresAutoOn
                    o.saveSettings()
                    g.statusMessage = string.format('TurboWares auto-open: %s', g.waresAutoShow and 'ON' or 'OFF')
                end
                tip((waresAutoOn and 'ON: ' or 'OFF: ') .. 'Opens TurboWares when you open a merchant window. Toggle with /turbowares.')
                Ui.gridSameLine(3, safetyCols, safetyGap)
                if Ui.buttonVariant('?##setup_quick_start_top',
                    quickStartOn and 'primaryButton' or 'secondaryButton', safetyW, 0) then
                    g.showQuickStartButton = not quickStartOn
                    o.saveSettings()
                    g.statusMessage = string.format('Header Quick Start button: %s', g.showQuickStartButton and 'ON' or 'OFF')
                end
                local qsTip = (quickStartOn and 'ON: ' or 'OFF: ') ..
                    'Shows the ? Quick Start button between Combat and Loot in the Turbo header.'
                if g.quickStartAutoReason and g.quickStartAutoReason ~= '' then
                    qsTip = qsTip .. ' Last auto-check: ' .. tostring(g.quickStartAutoReason)
                end
                tip(qsTip)
                Ui.gridSameLine(4, safetyCols, safetyGap)
                if Ui.buttonVariant('STOP##setup_stop_top',
                    stopBtnOn and 'dangerButton' or 'secondaryButton', safetyW, 0) then
                    g.showStopAllButton = not stopBtnOn
                    o.saveSettings()
                    g.statusMessage = string.format('Header STOP button: %s', g.showStopAllButton and 'ON' or 'OFF')
                end
                tip((stopBtnOn and 'ON: ' or 'OFF: ') .. 'Shows the red STOP control in the Turbo header (halt macros / nav).')
                Ui.gridSameLine(5, safetyCols, safetyGap)
                if Ui.buttonVariant('Debug##setup_dbg',
                    debugOn and 'primaryButton' or 'secondaryButton', safetyW, 0) then
                    TG.setTurboLootDebugEnabledForProfile(debugProfile, not debugOn, lootAllOn, multiModeOn, currentLooter)
                end
                tip((debugOn and 'ON: ' or 'OFF: ') .. 'Controls [TL DBG] and SkipReview chat traces for this INI.')
                Ui.gridSameLine(6, safetyCols, safetyGap)
                if Ui.buttonVariant('Mini FX##setup_mini_fx',
                    (g.miniLootAnimation ~= false) and 'primaryButton' or 'secondaryButton', safetyW, 0) then
                    g.miniLootAnimation = not (g.miniLootAnimation ~= false)
                    o.saveSettings()
                    g.statusMessage = string.format('Mini loot animation: %s', g.miniLootAnimation and 'ON' or 'OFF')
                end
                tip(((g.miniLootAnimation ~= false) and 'ON: ' or 'OFF: ') .. 'Shows the moving border sweep on the Mini window while TurboLoot is active.')
                end
            end
            end
        if setupWriteLocked then ImGui.EndDisabled() end
        end
        renderLootManagerSetupBody()
        end -- setup tab

        -- ============ REVIEW TAB ============
        if g.activeTab == 'review' then
            g.reviewMode = g.reviewMode or 'quick'
            if g.showReviewModeButtons ~= false then
                local reviewCols, reviewW, reviewGap = Ui.adaptiveColumns(3, 74, 4)
                local fullLabel = string.format('Full (%d)##review_mode_detailed', viewState.skipState.pendingCount or 0)
                if Ui.buttonVariant(fullLabel, reviewChoiceVariant(g.reviewWindowOpen and g.reviewSubPage == 'review', 'full'), reviewW, ACTION_BTN_H) then
                    local isOpen = g.reviewWindowOpen and g.reviewSubPage == 'review'
                    g.reviewWindowOpen = not isOpen
                    g.skipReviewOpen = g.reviewWindowOpen
                    if g.reviewWindowOpen then
                        g.reviewMode = 'detailed'
                        g.reviewSubPage = 'review'
                    else
                        g.reviewMode = 'quick'
                    end
                end
                tip('Open Full Review for quantity rules, Undo, Ignore all, Clear all skips, filters, nav, and Reloot controls.')
                Ui.gridSameLine(2, reviewCols, reviewGap)
                if Ui.buttonVariant('Packs##review_open_rulepacks_window', reviewChoiceVariant(g.reviewWindowOpen and g.reviewSubPage == 'rulepacks', 'packs'), reviewW, ACTION_BTN_H) then
                    local isOpen = g.reviewWindowOpen and g.reviewSubPage == 'rulepacks'
                    g.reviewWindowOpen = not isOpen
                    g.skipReviewOpen = g.reviewWindowOpen
                    if g.reviewWindowOpen then
                        g.reviewSubPage = 'rulepacks'
                        g.reviewMode = 'detailed'
                    else
                        g.reviewMode = 'quick'
                    end
                    g.rulePacksWindowOpen = false
                    TG.setupSubTab = 'loot'
                end
                tip('Show or hide Rule Packs inside the shared pop-out Review window.')
                Ui.gridSameLine(3, reviewCols, reviewGap)
                if Ui.buttonVariant('Hunting##review_open_hunting_window', reviewChoiceVariant(g.reviewWindowOpen and g.reviewSubPage == 'hunting', 'hunting'), reviewW, ACTION_BTN_H) then
                    local isOpen = g.reviewWindowOpen and g.reviewSubPage == 'hunting'
                    g.reviewWindowOpen = not isOpen
                    g.skipReviewOpen = g.reviewWindowOpen
                    if g.reviewWindowOpen then
                        g.reviewSubPage = 'hunting'
                        g.reviewMode = 'detailed'
                    else
                        g.reviewMode = 'quick'
                    end
                    g.rulePacksWindowOpen = false
                end
                tip('Show or hide Turbo Hunting inside the shared pop-out Review window.')
                ImGui.Dummy(0, 4)
            end
            if skipTracker and skipTracker.is_ready and skipTracker.is_ready() then
                local rawRows = g.skipDisplayRows or {}
                local q = tostring(g.quickReviewSearch or ''):lower():match('^%s*(.-)%s*$') or ''
                ImGui.PushItemWidth(math.max(120, Ui.availX(160)))
                if ImGui.InputTextWithHint then
                    g.quickReviewSearch = ImGui.InputTextWithHint('##quick_review_search', 'Search skipped items', tostring(g.quickReviewSearch or ''))
                else
                    g.quickReviewSearch = ImGui.InputText('##quick_review_search', tostring(g.quickReviewSearch or ''))
                end
                ImGui.PopItemWidth()
                tip('Filter the quick list by item, reason, source, or INI.')

                local quickRows = {}
                for _, row in ipairs(rawRows) do
                    local hay = (tostring(row.name or '') .. ' ' .. tostring(row.reason or '') .. ' '
                        .. tostring(row.source or '') .. ' ' .. tostring(row.iniFile or '')):lower()
                    if q == '' or hay:find(q, 1, true) then quickRows[#quickRows + 1] = row end
                end
                if g.quickReviewSelectedKey then
                    local foundSel = false
                    for _, row in ipairs(quickRows) do
                        if row.key == g.quickReviewSelectedKey then foundSel = true break end
                    end
                    if not foundSel then g.quickReviewSelectedKey = nil end
                end

                local function quickInspectReviewRow(row)
                    local pending = skipTracker.get_pending and skipTracker.get_pending() or {}
                    for _, rec in ipairs(pending) do
                        if rec.key == row.key then
                            local link = skipTracker.get_link and skipTracker.get_link(rec) or ''
                            if link ~= '' then mq.cmd('/executelink ' .. link)
                            else g.statusMessage = tostring(row.name or 'Item') .. ': no item link available' end
                            break
                        end
                    end
                end

                local function quickCopyReviewIds(row)
                    local itemId = tostring((row and row.itemId) or '')
                    local corpseId = tostring((row and row.corpseId) or '')
                    local hasItem = itemId ~= '' and itemId ~= '0'
                    local hasCorpse = corpseId ~= '' and corpseId ~= '0'
                    if not hasItem and not hasCorpse then
                        g.statusMessage = 'No item or corpse/NPC ID available for ' .. tostring((row and row.name) or 'row')
                        return
                    end
                    local text
                    if hasItem and hasCorpse then
                        text = string.format('%s - Item ID: %s - (NPC ID: %s)', tostring(row.name or 'Item'), itemId, corpseId)
                    elseif hasItem then
                        text = string.format('%s - Item ID: %s', tostring(row.name or 'Item'), itemId)
                    else
                        text = string.format('%s - (NPC ID: %s)', tostring(row.name or 'Item'), corpseId)
                    end
                    local ok = pcall(ImGui.SetClipboardText, text)
                    g.statusMessage = ok and ('Copied ' .. text) or text
                end

                local function quickNavReviewCorpse(row)
                    local corpseId = tostring((row and row.corpseId) or '')
                    if corpseId == '' or corpseId == '0' then
                        g.statusMessage = 'No corpse ID stored for ' .. tostring((row and row.name) or 'row')
                        return
                    end
                    local src = tostring((row and row.source) or '')
                    local me = tostring(mq.TLO.Me.Name() or '')
                    if src ~= '' and src ~= 'cli' and src:lower() ~= me:lower() then
                        mq.cmdf('/squelch /e3bct %s /target id %s', src, corpseId)
                        mq.cmdf('/timed 5 /squelch /e3bct %s /nav target', src)
                        g.statusMessage = 'Navigating ' .. src .. ' to corpse ' .. corpseId
                    else
                        mq.cmdf('/squelch /target id %s', corpseId)
                        mq.cmd('/timed 5 /squelch /nav target')
                        g.statusMessage = 'Navigating to corpse ' .. corpseId
                    end
                end

                local function quickApplyReviewRule(row, label)
                    if not row then
                        g.statusMessage = 'No quick review row selected.'
                        return
                    end
                    if TG.requireSharedControl and not TG.requireSharedControl('Review rule edit') then return end
                    local ok = skipTracker.apply_rule(row.name, label, row.iniPath)
                    g.lastSkipApplyMS = mq.gettime()
                    if ok then
                        g.statusMessage = string.format('%s = %s in %s', row.name, label, row.iniFile or 'INI')
                        g.quickReviewSelectedKey = nil
                        g.skipDisplayRows = nil
                    else
                        g.statusMessage = string.format('Failed to apply %s to %s', label, row.name)
                    end
                end

                local function quickDismissReviewRow(row)
                    if not row then
                        g.statusMessage = 'No quick review row selected.'
                        return false
                    end
                    if skipTracker.dismiss(row.name) then
                        g.quickReviewSelectedKey = nil
                        g.skipDisplayRows = nil
                        g.statusMessage = tostring(row.name or 'Item') .. ' dismissed'
                        return true
                    end
                    g.statusMessage = 'Failed to dismiss ' .. tostring(row.name or 'item')
                    return false
                end

                local function quickClearActionableSkips()
                    local cleared = TG.clearActionablePendingSkips()
                    g.quickReviewSelectedKey = nil
                    g.skipSelectedKey = nil
                    g.skipSelectionSet = nil
                    g.skipIniTargetOverride = nil
                    g.skipIniTargetOverridePath = nil
                    g.skipDisplayRows = nil
                    rebuildSkipDisplayRows()
                    g.statusMessage = string.format('%d actionable skip%s cleared', cleared, cleared == 1 and '' or 's')
                end

                local quickRowH = (Theme.layout and Theme.layout.rowH) or 22
                local quickAvailY = ImGui.GetContentRegionAvail()
                local quickMinH = quickRowH * 8 + 8
                local quickDesiredH = quickRowH * 11 + 8
                local quickReserveH = g.slimGUI and 224 or 208
                local quickSpaceH = math.max(quickMinH, quickAvailY - quickReserveH)
                local quickH = math.max(quickMinH, math.min(quickDesiredH, quickSpaceH))
                if ImGui.BeginChild('##quick_review_results', 0, quickH, true) then
                    local stretch = ImGuiTableFlags.SizingStretchProp or ImGuiTableFlags.SizingStretchSame
                    local flags = ImGuiTableFlags.RowBg + ImGuiTableFlags.BordersInnerV + stretch
                    local styleN = Ui.pushTableStyle()
                    if ImGui.BeginTable('##quick_review_table', 4, flags) then
                        ImGui.TableSetupColumn('Item')
                        ImGui.TableSetupColumn('Reason', ImGuiTableColumnFlags.WidthFixed, 84)
                        ImGui.TableSetupColumn('Src', ImGuiTableColumnFlags.WidthFixed, 52)
                        ImGui.TableSetupColumn('Nav', ImGuiTableColumnFlags.WidthFixed, 40)
                        ImGui.TableHeadersRow()
                        local shown = math.min(#quickRows, 80)
                        for i = 1, shown do
                            local row = quickRows[i]
                            local selected = g.quickReviewSelectedKey == row.key
                            ImGui.TableNextRow()
                            if selected then
                                ImGui.TableSetBgColor(ImGuiTableBgTarget.RowBg0, IM_COL32(42, 68, 104, 90))
                            end
                            ImGui.TableNextColumn()
                            if ImGui.Selectable(tostring(row.nameDisplay or row.name or '') .. '##quick_review_row_' .. row.key, selected,
                                ImGuiSelectableFlags and ImGuiSelectableFlags.SpanAllColumns or 0) then
                                g.quickReviewSelectedKey = row.key
                            end
                            if ImGui.IsItemHovered() then
                                ImGui.BeginTooltip()
                                ImGui.Text(tostring(row.name or ''))
                                ImGui.TextColored(0.62, 0.66, 0.74, 1.0, 'INI: ' .. tostring(row.iniFile or '-'))
                                if row.zone and row.zone ~= '' then ImGui.TextColored(0.55, 0.58, 0.65, 1.0, 'Zone: ' .. row.zone) end
                                ImGui.EndTooltip()
                            end
                            if ImGui.IsItemHovered() and ImGui.IsMouseDoubleClicked and ImGui.IsMouseDoubleClicked(0) then
                                quickInspectReviewRow(row)
                            end
                            if ImGui.BeginPopupContextItem('##quick_review_row_ctx_' .. row.key) then
                                g.quickReviewSelectedKey = row.key
                                ImGui.Text(tostring(row.name or 'Item'))
                                ImGui.Separator()
                                Ui.menuItem('Inspect item##quick_review_inspect_' .. row.key, function()
                                    quickInspectReviewRow(row)
                                end, true, {120, 170, 235, 255})
                                local validItemId = tonumber(row.itemId) ~= nil and tonumber(row.itemId) > 0
                                Ui.menuItem('Open Alla item page##quick_review_alla_' .. row.key, function()
                                    TG.openAllaItemPage(row.itemId)
                                end, validItemId, {120, 170, 235, 255})
                                local validCorpseId = tostring(row.corpseId or '') ~= '' and tostring(row.corpseId or '') ~= '0'
                                Ui.menuItem('Copy ID##quick_review_copy_ids_' .. row.key, function()
                                    quickCopyReviewIds(row)
                                end, validItemId or validCorpseId, {235, 190, 90, 255})
                                Ui.menuItem('Nav to corpse##quick_review_nav_corpse_' .. row.key, function()
                                    quickNavReviewCorpse(row)
                                end, validCorpseId, {95, 210, 145, 255})
                                TG.renderReviewGoLootMenu(row, 'quick_review_goloots_' .. row.key, function(msg)
                                    g.statusMessage = msg
                                end)
                                Ui.menuItem('Add to hunting list##quick_review_hunt_' .. row.key, function()
                                    TG.setHuntingTarget(row.name, 'Review')
                                end, true, {95, 210, 145, 255})
                                Ui.menuItem('Dismiss from review##quick_review_dismiss_' .. row.key, function()
                                    quickDismissReviewRow(row)
                                end, true, {230, 120, 110, 255})
                                if ImGui.BeginMenu('Apply rule##quick_review_apply_' .. row.key) then
                                    for _, lab in ipairs({ 'KEEP', 'SELL', 'BANK', 'TRIBUTE', 'DESTROY', 'IGNORE', 'ANNOUNCE' }) do
                                        if ImGui.MenuItem(lab) then quickApplyReviewRule(row, lab) end
                                    end
                                    ImGui.EndMenu()
                                end
                                ImGui.Separator()
                                Ui.menuItem('Open target INI##quick_review_open_ini_' .. row.key, function()
                                    if row.iniPath and row.iniPath ~= '' then shellOpenFile(row.iniPath)
                                    else g.statusMessage = 'No target INI path available for ' .. tostring(row.name or 'item') end
                                end, row.iniPath and row.iniPath ~= '', {160, 185, 230, 255})
                                ImGui.EndPopup()
                            end
                            ImGui.TableNextColumn()
                            local rl = tostring(row.reason or ''):lower()
                            if rl:find('below', 1, true) then
                                ImGui.TextColored(0.45, 0.65, 0.95, 1.0, tostring(row.reason or ''))
                            elseif rl:find('unlisted', 1, true) then
                                ImGui.TextColored(0.86, 0.72, 0.32, 1.0, tostring(row.reason or ''))
                            elseif rl:find('lore', 1, true) then
                                ImGui.TextColored(0.72, 0.62, 0.88, 1.0, tostring(row.reason or ''))
                            else
                                ImGui.TextColored(0.62, 0.66, 0.74, 1.0, tostring(row.reason or ''))
                            end
                            ImGui.TableNextColumn()
                            ImGui.TextDisabled(tostring(row.source or '-'))
                            ImGui.TableNextColumn()
                            local canNav = tostring(row.corpseId or '') ~= '' and tostring(row.corpseId or '') ~= '0'
                            if not canNav then ImGui.BeginDisabled() end
                            if ImGui.SmallButton('Nav##quick_review_nav_' .. row.key) then
                                quickNavReviewCorpse(row)
                            end
                            if not canNav then ImGui.EndDisabled() end
                            if ImGui.IsItemHovered() then
                                ImGui.BeginTooltip()
                                ImGui.Text(canNav and 'Target corpse and /nav target.' or 'No corpse ID saved for this row.')
                                ImGui.EndTooltip()
                            end
                        end
                        ImGui.EndTable()
                    end
                    Ui.popTableStyle(styleN)
                end
                ImGui.EndChild()

                local selectedRow = nil
                for _, row in ipairs(rawRows) do
                    if row.key == g.quickReviewSelectedKey then selectedRow = row break end
                end
                local quickTargetMode = hasCursor and 'cursor' or (selectedRow and 'row' or 'none')
                local quickHasTarget = quickTargetMode ~= 'none'
                local QR_HOVERED_ALLOW_DISABLED = (ImGuiHoveredFlags and ImGuiHoveredFlags.AllowWhenDisabled) or 128
                local function quickNoTargetTip(label)
                    if quickHasTarget then return end
                    if not ImGui.IsItemHovered(QR_HOVERED_ALLOW_DISABLED) then return end
                    ImGui.BeginTooltip()
                    ImGui.Text(label)
                    ImGui.TextColored(0.92, 0.45, 0.40, 1.0, 'Select a Review row or put an item on your cursor first.')
                    ImGui.EndTooltip()
                end
                local quickTargetText = selectedRow and 'Selected: 1 item' or 'Selected: none'
                if quickTargetMode == 'cursor' then
                    quickTargetText = 'Cursor: ' .. tostring(cursorItem or '')
                end
                ImGui.TextColored(0.62, 0.70, 0.82, 1.0, quickTargetText)
                if quickTargetMode == 'row' and selectedRow then
                    ImGui.SameLine(0, 8)
                    if Ui.buttonVariant('Dismiss##quick_review_dismiss_selected', 'secondaryButton', 82, ACTION_BTN_H) then
                        quickDismissReviewRow(selectedRow)
                    end
                    tip('Hide this row without making a rule.')
                end
                ImGui.TextDisabled('Full Review has Qty / Undo / bulk tools')
                ImGui.Dummy(0, 3)
                local function quickApply(label)
                    if quickTargetMode == 'cursor' then
                        applyTurboKeyRule(label, { itemName = cursorItem })
                    else
                        quickApplyReviewRule(selectedRow, label)
                    end
                end
                local TK = TurboKeyRGB or Theme.col.turboKeyRGB or {}
                local qAvail = ImGui.GetContentRegionAvail()
                local qSp = math.max(ImGui.GetStyle().ItemSpacing.x, 4)
                local qW4 = math.max(64, math.floor((qAvail - qSp * 3) / 4))
                local qW3 = math.max(72, math.floor((qAvail - qSp * 2) / 3))
                local function qBtn(label, rgb, same)
                    if same then ImGui.SameLine(0, qSp) end
                    if not quickHasTarget then ImGui.BeginDisabled() end
                    if Ui.buttonRgb(label .. '##quick_review_' .. label, rgb, qW4, ACTION_BTN_H) then quickApply(label) end
                    if not quickHasTarget then ImGui.EndDisabled() end
                    if quickHasTarget then
                        tip(quickTargetMode == 'cursor' and ('Apply ' .. label .. ' to the cursor item.') or ('Apply ' .. label .. ' to the selected quick-review row.'))
                    else
                        quickNoTargetTip(label)
                    end
                end
                qBtn('KEEP', TK.keep or {70, 100, 150}, false)
                qBtn('SELL', TK.sell or {60, 120, 80}, true)
                qBtn('BANK', TK.bank or TK.trade or {90, 82, 130}, true)
                qBtn('TRIBUTE', TK.tribute or {130, 95, 35}, true)
                local function qBtn3(label, rgb, same)
                    if same then ImGui.SameLine(0, qSp) end
                    if not quickHasTarget then ImGui.BeginDisabled() end
                    if Ui.buttonRgb(label .. '##quick_review_' .. label, rgb, qW3, ACTION_BTN_H) then quickApply(label) end
                    if not quickHasTarget then ImGui.EndDisabled() end
                    if quickHasTarget then
                        tip(quickTargetMode == 'cursor' and ('Apply ' .. label .. ' to the cursor item.') or ('Apply ' .. label .. ' to the selected quick-review row.'))
                    else
                        quickNoTargetTip(label)
                    end
                end
                qBtn3('DESTROY', TK.destroy or {145, 60, 55}, false)
                qBtn3('IGNORE', TK.skip or {55, 58, 65}, true)
                qBtn3('ANNOUNCE', TK.announce or {55, 130, 140}, true)
                ImGui.Dummy(0, 3)
                local rMode = g.actionRunMode or 'self'
                local relootAvail = ImGui.GetContentRegionAvail()
                local relootSp = math.max(ImGui.GetStyle().ItemSpacing.x, 4)
                local relootW = math.max(54, math.floor((math.min(relootAvail, 300) - relootSp * 3) / 4))
                ImGui.TextColored(0.62, 0.66, 0.74, 1.0, 'Reloot:')
                ImGui.SameLine()
                local function quickRelootScope(label, mode, hint)
                    if Ui.buttonVariant(label .. '##quick_review_reloot_scope_' .. mode,
                        rMode == mode and 'primaryButton' or 'secondaryButton', relootW, ACTION_BTN_H) then
                        g.actionRunMode = mode
                    end
                    tip(hint)
                end
                quickRelootScope('Single', 'self', 'Reloot with the current single looter.')
                ImGui.SameLine()
                quickRelootScope('Picks', 'multi', 'Reloot with characters selected in Actions -> Run As -> Picks.')
                ImGui.SameLine()
                quickRelootScope('Group', 'group', 'Reloot with current group characters.')
                ImGui.SameLine()
                quickRelootScope('All', 'all', 'Reloot with all E3 bots in zone.')
                if Ui.buttonVariant('Reloot corpses##quick_review_reloot', 'primaryButton', -1, ACTION_BTN_H) then
                    if g.relootNow then g.relootNow(g.actionRunMode or 'self') end
                end
                tip('Show hidden corpses for the selected Reloot scope, then run TurboLoot again.')
                ImGui.Dummy(0, 3)
                local corpseAvail = ImGui.GetContentRegionAvail()
                local corpseGap = math.max(ImGui.GetStyle().ItemSpacing.x, 4)
                local corpseW = math.max(72, math.floor((corpseAvail - corpseGap * 2) / 3))
                if Ui.buttonVariant('Hide all##quick_review_hide_all', 'secondaryButton', corpseW, ACTION_BTN_H) then
                    mq.cmd('/e3bcaa /hidecorpse all')
                    g.statusMessage = 'Hide all corpses sent to group.'
                end
                tip('Hide all corpses for the group.')
                ImGui.SameLine(0, corpseGap)
                if Ui.buttonVariant('Hide looted##quick_review_hide_looted', 'secondaryButton', corpseW, ACTION_BTN_H) then
                    mq.cmd('/e3bcaa /hidecorpse looted')
                    g.statusMessage = 'Hide looted corpses sent to group.'
                end
                tip('Hide looted corpses for the group.')
                ImGui.SameLine(0, corpseGap)
                if Ui.buttonVariant('Show corpses##quick_review_show_corpses', 'secondaryButton', corpseW, ACTION_BTN_H) then
                    mq.cmd('/e3bcaa /gsay [Turbo] Review Show corpses requested.')
                    mq.cmd('/e3bcaa /hidecorpse none')
                    g.statusMessage = 'Show corpses sent to group.'
                end
                tip('Show all corpses for the group.')
                local quickPendingN = tonumber(g.skipDisplayTotal or viewState.skipState.pendingCount or #rawRows) or 0
                if quickPendingN > 0 then
                    ImGui.Dummy(0, 3)
                    ImGui.PushStyleColor(ImGuiCol.Button, IM_COL32(55, 45, 45, 255))
                    ImGui.PushStyleColor(ImGuiCol.ButtonHovered, IM_COL32(75, 55, 55, 255))
                    if ImGui.Button('Clear All Skips##quick_review_clear_all', -1, ACTION_BTN_H) then
                        if g.confirmSingleReviewRules == false then
                            quickClearActionableSkips()
                        else
                            ImGui.OpenPopup('Confirm Clear All Skips##quick_review')
                        end
                    end
                    ImGui.PopStyleColor(2)
                    tip('Dismiss all actionable Review rows without writing rules.')
                    if ImGui.BeginPopupModal('Confirm Clear All Skips##quick_review') then
                        ImGui.Text('Confirm Clear All Skips')
                        ImGui.Separator()
                        ImGui.Text(string.format('Dismiss %d actionable skip row%s without writing rules?', quickPendingN, quickPendingN == 1 and '' or 's'))
                        ImGui.TextColored(0.72, 0.78, 0.88, 1.0, 'This includes rows hidden by search or filters.')
                        ImGui.Dummy(0, 6)
                        if ImGui.Button('Confirm##quick_review_clear_all_modal', 120, ACTION_BTN_H) then
                            quickClearActionableSkips()
                            ImGui.CloseCurrentPopup()
                        end
                        ImGui.SameLine()
                        if ImGui.Button('Cancel##quick_review_clear_all_modal', 120, ACTION_BTN_H) then
                            ImGui.CloseCurrentPopup()
                        end
                        ImGui.EndPopup()
                    end
                end
                local quickFooterMessage = tostring(g.statusMessage or '')
                if quickFooterMessage ~= '' then
                    local maxLen = 54
                    quickFooterMessage = tostring(quickFooterMessage)
                    if #quickFooterMessage > maxLen then
                        quickFooterMessage = quickFooterMessage:sub(1, maxLen - 2) .. '..'
                    end
                    ImGui.Dummy(0, 2)
                    ImGui.TextColored(Colors.statusMsg[1], Colors.statusMsg[2], Colors.statusMsg[3], Colors.statusMsg[4],
                        'Last: ' .. quickFooterMessage)
                end
            else
                ImGui.TextColored(0.50, 0.54, 0.62, 1.0, 'Skip Review is not ready yet.')
            end
        end -- review tab

        -- ============ ACTIONS TAB ============
        if g.activeTab == 'actions' or g.activeTab == 'tools' then
            local function applyQtyRule()
                local num = tonumber(g.turboKeyQty)
                if num and num > 0 then
                    applyTurboKeyRule(tostring(math.floor(num)))
                else
                    g.statusMessage = 'Enter a valid number for quantity.'
                end
            end

            local function renderCursorHandPanel()
                if not hasCursor then return end
                thinSep('turbogive', 'TurboGive Help')
                local cstk = tonumber(mq.TLO.Cursor.Stack()) or 1
                local recipHand = o.countHandRecipientsInZone()
                local addBtnW, handBtnW = 42, 50
                local smBtn, allBtnW = 34, 40
                local inSp = ImGui.GetStyle().ItemInnerSpacing.x

                if hasPcTarget then
                    o.actionButton('Add##addgive', '/mac turbogive add', {65,115,85}, nil, nil,
                        string.format("Add cursor item to %s's give-list", targetName), addBtnW, ACTION_BTN_H)
                    ImGui.SameLine()
                end
                if Ui.buttonVariant('Hand##handmain', 'successButton', handBtnW, ACTION_BTN_H) then
                    local num = tonumber(g.handQty)
                    if num and num > 0 then
                        mq.cmdf('/mac turbogive hand %d', math.floor(num))
                        g.statusMessage = string.format('Handing %d to group...', math.floor(num))
                    else
                        g.statusMessage = 'Enter a valid hand quantity.'
                    end
                end
                tip(string.format('Give %s of cursor item to each groupmate in zone (you are skipped)', g.handQty))
                ImGui.SameLine()
                ImGui.PushItemWidth(math.max(48, ImGui.GetContentRegionAvail() - inSp))
                g.handQty = ImGui.InputText('##handqty', g.handQty)
                ImGui.PopItemWidth()
                tip('Quantity per recipient — in-zone group only (matches TurboGive hand)')

                ImGui.Dummy(0, 4)
                if Ui.buttonVariant('1##h1', 'secondaryButton', smBtn, ACTION_BTN_H) then g.handQty = '1' end
                tip('Set quantity to 1')
                if recipHand > 0 and cstk > 1 then
                    ImGui.SameLine()
                    if Ui.buttonVariant('Spl##hsplit', 'secondaryButton', smBtn, ACTION_BTN_H) then
                        local q = math.floor(cstk / recipHand)
                        if q < 1 then
                            g.statusMessage = string.format('Stack %d too small to split among %d groupmates in zone.', cstk, recipHand)
                        else
                            g.handQty = tostring(q)
                            g.statusMessage = string.format('Qty %d = floor(%d / %d recipients)', q, cstk, recipHand)
                        end
                    end
                    tip(string.format('Even split: floor(%d / %d) - per person for in-zone groupmates', cstk, recipHand))
                end
                if cstk > 1 then
                    ImGui.SameLine()
                    if Ui.buttonVariant('All##hall', 'secondaryButton', allBtnW, ACTION_BTN_H) then g.handQty = tostring(cstk) end
                    tip(string.format('Set to full stack on cursor (%d)', cstk))
                end
            end

            o.ActionsView.render(viewState, {
                mq = mq,
                Ui = Ui,
                Colors = Colors,
                TurboKeyRGB = TurboKeyRGB,
                ACTION_BTN_H = ACTION_BTN_H,
                RULE_BTN_W = o.RULE_BTN_W,
                SLIM_RULE_BTN_H = o.SLIM_RULE_BTN_H,
                thinSep = thinSep,
                coloredSep = o.coloredSep,
                tip = tip,
                actionButton = o.actionButton,
                ruleButton = o.ruleButton,
                canSharedControlWrite = TG.isSharedControlOwner,
                requireSharedControl = TG.requireSharedControl,
                sharedControlOwnerName = TG.sharedControlOwnerName,
                turboConvertTooltip = o.turboConvertTooltip,
                applyQtyRule = applyQtyRule,
                renderCursorHandPanel = renderCursorHandPanel,
                openActiveIni = o.openTurbolootIniFileExternal,
                runDoctor = function()
                    o.printTurboDoctor()
                    g.statusMessage = 'Turbo doctor printed to chat.'
                end,
                exportDiagnostics = function()
                    local path, err = TG.exportDiagnosticsReport()
                    if path then
                        g.lastDiagnosticsPath = path
                        g.statusMessage = 'Diagnostics exported: ' .. TG.fileBaseName(path)
                        printf('\at[Turbo]\ax Diagnostics exported: \ag%s\ax', path)
                    else
                        g.statusMessage = 'Diagnostics export failed: ' .. tostring(err or 'unknown error')
                    end
                end,
                openLastDiagnostics = function()
                    if g.lastDiagnosticsPath and g.lastDiagnosticsPath ~= '' then
                        shellOpenFolder(g.lastDiagnosticsPath)
                        g.statusMessage = 'Opened diagnostics folder: ' .. TG.fileBaseName(g.lastDiagnosticsPath)
                        printf('\at[Turbo]\ax Diagnostics folder: \ag%s\ax', g.lastDiagnosticsPath)
                    else
                        g.statusMessage = 'No diagnostics folder exported this session.'
                    end
                end,
                cleanDiagnostics = function()
                    local result = TG.cleanupDiagnosticsBundles({ keep = 5, maxAgeDays = 7 })
                    g.statusMessage = string.format('Diagnostics cleanup: removed %d, kept %d%s',
                        tonumber(result.removed) or 0,
                        tonumber(result.kept) or 0,
                        (tonumber(result.errors) or 0) > 0 and string.format(', %d error(s)', tonumber(result.errors) or 0) or '')
                    printf('\at[Turbo]\ax %s', g.statusMessage)
                end,
                toggleFileLog = function()
                    g.logFileOn = not g.logFileOn
                    mq.cmdf('/squelch /varset logToFile %s', g.logFileOn and 'TRUE' or 'FALSE')
                    g.statusMessage = g.logFileOn and 'File logging ON (when TurboLoot runs)' or 'File logging OFF'
                    o.saveSettings()
                end,
                printTurboSnapshot = function()
                    TG.printTurboSnapshot()
                end,
                resetSkipReviewData = function()
                    if TG.repairSkipReviewData then TG.repairSkipReviewData(g) end
                end,
                openSkipJournal = TG.openSkipJournalExternal,
                onlineCharacters = function()
                    return TG.collectOnlineCharacters()
                end,
                openTurbolootIniForCharacter = function(name)
                    TG.openTurbolootIniForCharacterExternal(name)
                end,
                openTurboLootSettingsWindow = function(name)
                    local prof = getProfileForMember(name or '') or getActiveProfile()
                    g.tlSettingsProfile = o.cleanProfileName(prof) or 'turboloot.ini'
                    g.tlSettingsDraftProfile = nil
                    g.tlSettingsWindowOpen = true
                end,
                turboLootProfileForCharacter = function(name)
                    local prof = getProfileForMember(name or '') or getActiveProfile()
                    return o.cleanProfileName(prof) or 'turboloot.ini'
                end,
                syncProfileAssignments = function()
                    syncProfileAssignments()
                end,
                openCharacterE3Ini = function(name)
                    o.openE3IniExternal(name)
                end,
                saveAllaUrlSettings = function(itemBase, npcBase)
                    itemBase = tostring(itemBase or '')
                    npcBase = tostring(npcBase or '')
                    if not TG.isSafeHttpBaseUrl(itemBase) or not TG.isSafeHttpBaseUrl(npcBase) then
                        g.statusMessage = 'Alla URL bases must start with http(s) and cannot contain spaces or shell characters.'
                        return false
                    end
                    TG.allaItemUrlBase = itemBase
                    TG.allaNpcUrlBase = npcBase
                    o.saveSettings()
                    g.statusMessage = 'Alla URL bases saved.'
                    return true
                end,
                backupActiveIni = function(name)
                    name = tostring(name or ''):match('^%s*(.-)%s*$') or ''
                    local me = mq.TLO.Me.Name() or mq.TLO.Me.CleanName() or ''
                    if name ~= '' and name ~= me then
                        mq.cmdf('/squelch /e3bct %s /lua run Turbo backup turbo', name)
                        g.statusMessage = 'TurboLoot INI backup sent to ' .. name .. '.'
                        return
                    end
                    local backupPath, err = TG.backupActiveTurbolootIni()
                    g.statusMessage = TG.backupStatusMessage('TurboLoot INI', backupPath, err)
                end,
                backupLocalE3Ini = function(name)
                    name = tostring(name or ''):match('^%s*(.-)%s*$') or ''
                    local me = mq.TLO.Me.Name() or mq.TLO.Me.CleanName() or ''
                    if name ~= '' and name ~= me then
                        mq.cmdf('/squelch /e3bct %s /lua run Turbo backup e3', name)
                        g.statusMessage = 'E3 INI backup sent to ' .. name .. '.'
                        return
                    end
                    local backupPath, err = TG.backupLocalE3Ini(nil, name)
                    g.statusMessage = TG.backupStatusMessage('E3 INI', backupPath, err)
                end,
                backupGroupE3Inis = function()
                    local sent = TG.sendGroupE3Backups()
                    g.statusMessage = sent > 0
                        and string.format('E3 INI backup sent to %d group character(s).', sent)
                        or 'No group characters found for E3 INI backup.'
                end,
                backupAllZoneE3Inis = function()
                    mq.cmd('/squelch /e3bcaa /lua run Turbo backup e3')
                    g.statusMessage = 'E3 INI backup sent to ALL zone bots.'
                end,
                backupEqclientIni = function(name)
                    name = tostring(name or ''):match('^%s*(.-)%s*$') or ''
                    local me = mq.TLO.Me.Name() or mq.TLO.Me.CleanName() or ''
                    if name ~= '' and name ~= me then
                        mq.cmdf('/squelch /e3bct %s /lua run Turbo backup eqclient', name)
                        g.statusMessage = 'eqclient.ini backup sent to ' .. name .. '.'
                        return
                    end
                    local backupPath, err = TG.backupEqclientIni()
                    g.statusMessage = TG.backupStatusMessage('eqclient.ini', backupPath, err)
                end,
                sendE3BackupTo = function(name)
                    if TG.sendE3BackupTo(name) then
                        g.statusMessage = 'E3 INI backup sent to ' .. tostring(name)
                        return true
                    end
                    g.statusMessage = 'Enter a character name for E3 INI backup.'
                    return false
                end,
                openGithub = function()
                    o.openTurboRepoWeb()
                end,
                openTurboPatcher = o.openTurboPatcherExternal,
                sendXTankMacro = function()
                    if TG.requireSharedControl('XTank macro broadcast') then
                        local cmd = TG.xtankBroadcastCommand()
                        mq.cmd(cmd)
                        g.statusMessage = 'Turbo xtarget heal sent: ' .. cmd
                    end
                end,
                openConfigFolder = o.openTurbolootConfigFolderExternal,
                openMacrosFolder = o.openTurbolootMacrosFolderExternal,
                openTurboMobsExportsFolder = o.openTurboMobsExportsFolderExternal,
                saveSettings = o.saveSettings,
            })
        end -- actions/tools tab

        end -- main tab content

        ImGui.PopStyleVar(1)
    end
    ImGui.End()
    ImGui.PopStyleColor(12)
    ImGui.PopStyleVar(6)
    renderTimedChallengeOverlay()
    renderGainsWindow()
    renderWaresWindow()

    if g.reviewWindowOpen then
        pcall(function()
            ImGui.SetNextWindowSizeConstraints(560, 760, 1120, 1040)
            ImGui.SetNextWindowSize(820, 820, ImGuiCond.FirstUseEver)
            if g.reviewWindowPos and g.reviewWindowPos.x and g.reviewWindowPos.y then
                ImGui.SetNextWindowPos(g.reviewWindowPos.x, g.reviewWindowPos.y, ImGuiCond.FirstUseEver)
            end
        end)
        ImGui.PushStyleColor(ImGuiCol.WindowBg, IM_COL32(12, 15, 22, 252))
        ImGui.PushStyleColor(ImGuiCol.TitleBg, IM_COL32(14, 17, 24, 255))
        ImGui.PushStyleColor(ImGuiCol.TitleBgActive, IM_COL32(20, 24, 34, 255))
        ImGui.PushStyleColor(ImGuiCol.Border, IM_COL32(185, 140, 70, 225))
        ImGui.PushStyleVar(ImGuiStyleVar.WindowRounding, 8)
        ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 5)
        ImGui.PushStyleVar(ImGuiStyleVar.PopupRounding, 5)
        local reviewOpen, reviewDraw = ImGui.Begin('Turbo Review###Turbo_Review_Window', g.reviewWindowOpen, ImGuiWindowFlags.NoTitleBar or 0)
        g.reviewWindowOpen = reviewOpen
        if reviewDraw == nil then reviewDraw = reviewOpen end
        if reviewDraw then
            if TG.turboChromeDragApplyActive then TG.turboChromeDragApplyActive('review') end
            local wx, wy = ImGui.GetWindowPos()
            if wx and wy then g.reviewWindowPos = { x = wx, y = wy } end
            if TG.turboChromeDragReset then TG.turboChromeDragReset('review') end
            TG.drawTurboReviewTitle(g)
            if TG.turboChromeDragSetBandToCursor then TG.turboChromeDragSetBandToCursor(52, 'review') end
            if TG.turboChromeDragHandle then TG.turboChromeDragHandle('Drag Turbo Review header to move the window.', false, 'review') end
            if g.reviewWindowOpen then
            local okReview, errReview = pcall(function()
                local function reviewMutedWrap(text)
                    ImGui.PushTextWrapPos(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail())
                    ImGui.TextColored(0.45, 0.48, 0.55, 1.0, tostring(text or ''))
                    ImGui.PopTextWrapPos()
                end
                g.reviewSubPage = g.reviewSubPage or 'review'
                if Ui.buttonVariant('Full##review_sub_review2', reviewChoiceVariant(g.reviewSubPage == 'review', 'full'), 82, ACTION_BTN_H) then
                    g.reviewSubPage = 'review'
                end
                ImGui.SameLine()
                if Ui.buttonVariant('Packs##review_sub_rulepacks2', reviewChoiceVariant(g.reviewSubPage == 'rulepacks', 'packs'), 82, ACTION_BTN_H) then
                    g.reviewSubPage = 'rulepacks'
                end
                ImGui.SameLine()
                if Ui.buttonVariant('Hunting##review_sub_hunting2', reviewChoiceVariant(g.reviewSubPage == 'hunting', 'hunting'), 92, ACTION_BTN_H) then
                    g.reviewSubPage = 'hunting'
                end
                ImGui.Separator()
                if g.reviewSubPage == 'rulepacks' then
                    local assignTargetRp = g.selectedChar or ((currentLooter and currentLooter ~= 'NOBODY') and currentLooter) or 'selected character'
                    local activeProfRp = getActiveProfile()
                    local activeTargetsRp = activeLootTargetNames(lootAllOn, multiModeOn, currentLooter)
                    local activeProfileNRp = countDistinctProfilesForNames(activeTargetsRp, getProfileForMember)
                    local showAdvancedSetupRp = g.perCharProfile
                    TG.renderRulePacksPanel(g, activeProfRp, assignTargetRp, showAdvancedSetupRp,
                        getProfileForMember, reviewMutedWrap, tip, ACTION_BTN_H, rescanProfiles, openProfileExternal)
                    local okRB, RB = pcall(require, 'Turbo.rulepack_browser')
                    if okRB and RB and RB.render then
                        RB.render({
                            g = g,
                            TG = TG,
                            tip = tip,
                            mutedWrap = reviewMutedWrap,
                            ACTION_BTN_H = ACTION_BTN_H,
                            activeProf = activeProfRp,
                            assignTarget = assignTargetRp,
                            showAdvancedSetup = showAdvancedSetupRp,
                            getProfileForMember = getProfileForMember,
                            resolveTurbolootIniPathForProfile = resolveTurbolootIniPathForProfile,
                            profileList = g.profileList,
                            TurboKeyRGB = TurboKeyRGB,
                            openProfile = openProfileExternal,
                            pageMode = true,
                        })
                    else
                        reviewMutedWrap('Rule pack browser module failed to load.')
                    end
                elseif g.reviewSubPage == 'hunting' then
                    reviewMutedWrap('Manage item alerts for drops you are actively hunting. TurboLoot reads this list once per loot run and checks it in memory.')
                    ImGui.Dummy(0, 4)
                    TG.drawHuntingPanel(g, tip, ACTION_BTN_H)
                else
                    renderSkipReview(g, skipTracker, tip, thinSep, undoSkipRule, TurboKeyRGB, Colors,
                        ACTION_BTN_H, true, applyTurboKeyRule, getActiveProfile)
                end
            end)
            if not okReview then
                ImGui.TextColored(0.9, 0.35, 0.35, 1.0, 'Review failed to render.')
                ImGui.TextWrapped(tostring(errReview))
            end
            end
        end
        ImGui.End()
        ImGui.PopStyleVar(3)
        ImGui.PopStyleColor(4)
    end

    if g.tlSettingsWindowOpen then
        pcall(function()
            ImGui.SetNextWindowSizeConstraints(420, 480, 760, 980)
            ImGui.SetNextWindowSize(560, 760, ImGuiCond.FirstUseEver)
        end)
        ImGui.PushStyleColor(ImGuiCol.WindowBg, IM_COL32(16, 19, 28, 248))
        ImGui.PushStyleColor(ImGuiCol.TitleBg, IM_COL32(24, 28, 40, 255))
        ImGui.PushStyleColor(ImGuiCol.TitleBgActive, IM_COL32(38, 52, 82, 255))
        ImGui.PushStyleColor(ImGuiCol.Border, IM_COL32(82, 112, 152, 220))
        ImGui.PushStyleVar(ImGuiStyleVar.WindowRounding, 8)
        ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 5)
        ImGui.PushStyleVar(ImGuiStyleVar.PopupRounding, 5)
        local settingsOpen, settingsDraw = ImGui.Begin('Turbo INI Config###Turbo_Settings_Window', g.tlSettingsWindowOpen)
        g.tlSettingsWindowOpen = settingsOpen
        if settingsDraw == nil then settingsDraw = settingsOpen end
        if settingsDraw then
            local okSettings, errSettings = pcall(function()
                TG.renderTurboLootSettingsWindow(g, tip, ACTION_BTN_H, getActiveProfile)
            end)
            if not okSettings then
                ImGui.TextColored(0.9, 0.35, 0.35, 1.0, 'Turbo INI Config failed to render.')
                ImGui.TextWrapped(tostring(errSettings))
            end
        end
        ImGui.End()
        ImGui.PopStyleVar(3)
        ImGui.PopStyleColor(4)
    end

    renderDetachedRulePacksWindow()
    end)()
    end)()
end

-- =========================================================
-- CLI mode
-- =========================================================
-- Lua 5.1 / LuaJIT: chunks cap active locals (~200). This CLI dispatcher's many
-- `local`s pushed the chunk over the limit — isolate inside an anonymous function.
if cliMode then
    (function()
        local cmd = cliMode:lower()
        local sharedCli = {
            cycle = true,
            on = true,
            off = true,
            none = true,
            nobody = true,
            toggle = true,
            combatloot = true,
            combat = true,
            loot = true,
            lootnow = true,
            all = true,
        }
        if sharedCli[cmd] and TG.requireSharedControl and not TG.requireSharedControl('/lua run Turbo ' .. cmd) then
            printf('\at[Turbo]\ax \ayBrowse mode:\ax %s owns Turbo control. Open Turbo and click Take Control to change shared loot state.',
                TG.sharedControlOwnerName and TG.sharedControlOwnerName() or 'another box')
            return
        end

    if cmd == 'cycle' then
        cycleToNext()
    elseif cmd == 'all' then
        toggleLootAll()
        if getLootAllState() then
            printf('\at[Turbo]\ax Loot ALL \acON\ax. All characters will loot.')
        else
            printf('\at[Turbo]\ax Loot ALL \arOFF\ax. Single-looter mode.')
        end
    elseif cmd == 'on' then
        collectGroupMembers()
        setTurboState(true)
        local allOn = getLootAllState()
        local multiOn = (not allOn) and isMultiLootMode()
        if not allOn and not multiOn then
            local cl = getCurrentLooter()
            if cl == 'NOBODY' then
                cycleToNext()
            end
        end
        local corpses = getNearbyCorpseCount()
        if corpses > 0 then
            if allOn then
                mq.cmd('/squelch /e3bcaa /mac TurboLoot')
                printf('\at[Turbo]\ax Auto-loot \agON\ax (ALL). Sweeping %d corpses.', corpses)
            elseif multiOn then
                local sent = sendMultiLootCommands()
                printf('\at[Turbo]\ax Auto-loot \agON\ax (MULTI %d, staggered %.1fs). Sweeping %d corpses.',
                    sent, MULTI_LOOT_STAGGER_DS / 10, corpses)
            elseif getCurrentLooter() ~= 'NOBODY' then
                mq.cmdf('/squelch /e3bct %s /mac TurboLoot', getCurrentLooter())
                printf('\at[Turbo]\ax Auto-loot \agON\ax. Sweeping %d corpses.', corpses)
            else
                printf('\at[Turbo]\ax Auto-loot \agON\ax.')
            end
        else
            printf('\at[Turbo]\ax Auto-loot \agON\ax.%s', allOn and ' (ALL mode)' or (multiOn and ' (MULTI mode)' or ''))
        end
        saveSettings()
    elseif cmd == 'off' or cmd == 'none' or cmd == 'nobody' then
        setTurboState(false)
        setRouteVar('GrpMainLooter', 'NOBODY')
        mq.cmdf('/e3bc /echo [Turbo] Auto-loot OFF.')
        printf('\at[Turbo]\ax Auto-loot \arOFF\ax.')
        saveSettings()
    elseif cmd == 'toggle' then
        collectGroupMembers()
        local namedLooter = cliArg2 and tostring(cliArg2):match('^%s*(.-)%s*$') or ''
        local allOn = getLootAllState()
        local multiOn = (not allOn) and isMultiLootMode()
        if namedLooter ~= '' and not allOn and not multiOn then
            local resolved = nil
            for _, name in ipairs(TG.members) do
                if name:lower() == namedLooter:lower() then
                    resolved = name
                    break
                end
            end
            if not resolved then
                local sc = mq.TLO.SpawnCount(string.format('pc %s', namedLooter))()
                if sc and sc > 0 then resolved = namedLooter end
            end
            if resolved then
                setLooter(resolved)
            else
                printf('\at[Turbo]\ax \ayWarning:\ax %s not in group/zone; using current looter.', namedLooter)
            end
        elseif namedLooter ~= '' and (allOn or multiOn) then
            printf('\at[Turbo]\ax Toggle in %s mode (named looter ignored).', allOn and 'ALL' or 'MULTI')
        end
        local currentLooter = getCurrentLooter()
        local turboOn = getTurboState()
        if turboOn then
            TG.setTurboEnabled(false, currentLooter, allOn, multiOn)
            mq.cmdf('/e3bc /echo [Turbo] Auto-loot OFF.')
            if not allOn and not multiOn and currentLooter ~= 'NOBODY' then
                printf('\at[Turbo]\ax Auto-loot \arOFF\ax. Looter stays \ag%s\ax.', currentLooter)
            else
                printf('\at[Turbo]\ax Auto-loot \arOFF\ax.')
            end
        else
            TG.setTurboEnabled(true, currentLooter, allOn, multiOn)
            mq.cmdf('/e3bc /echo [Turbo] Auto-loot ON.')
            currentLooter = getCurrentLooter()
            if allOn then
                printf('\at[Turbo]\ax Auto-loot \agON\ax (ALL mode).')
            elseif multiOn then
                printf('\at[Turbo]\ax Auto-loot \agON\ax (MULTI mode).')
            elseif currentLooter ~= 'NOBODY' then
                printf('\at[Turbo]\ax Auto-loot \agON\ax. Looter: \ag%s\ax.', currentLooter)
            else
                printf('\at[Turbo]\ax Auto-loot \agON\ax.')
            end
        end
    elseif cmd == 'combatloot' or cmd == 'combat' then
        local isOn = getCombatLootState()
        if isOn then
            setCombatState(false)
            printf('\at[Turbo]\ax Combat loot \arOFF\ax.')
        else
            setCombatState(true)
            printf('\at[Turbo]\ax Combat loot \agON\ax.')
        end
        saveSettings()
    elseif cmd == 'loot' or cmd == 'lootnow' then
        collectGroupMembers()
        local corpses = getNearbyCorpseCount()
        if corpses == 0 then
            printf('\at[Turbo]\ax No corpses nearby.')
        elseif getLootAllState() then
            mq.cmd('/squelch /e3bcaa /mac TurboLoot')
            printf('\at[Turbo]\ax Loot ALL sent (%d corpses).', corpses)
        elseif isMultiLootMode() then
            local sent = sendMultiLootCommands()
            printf('\at[Turbo]\ax Loot MULTI sent to \ag%d\ax character(s), staggered %.1fs (%d corpses).',
                sent, MULTI_LOOT_STAGGER_DS / 10, corpses)
        else
            local looter = getCurrentLooter()
            if looter == 'NOBODY' then
                printf('\at[Turbo]\ax \arNo looter set.\ax Pick one first, or use \ac/lua run Turbo all\ax.')
            else
                mq.cmdf('/squelch /e3bct %s /mac TurboLoot', looter)
                printf('\at[Turbo]\ax Loot sent to \ag%s\ax (%d corpses).', looter, corpses)
            end
        end
    elseif cmd == 'setup' then
        local manual = nil
        local reloadOpt = nil
        local setupMode = 'full'
        local restoreRoute = true
        local i = 2
        while args[i] do
            local tok = tostring(args[i])
            local low = tok:lower()
            if low == 'reload' or low == 'e3reload' then
                reloadOpt = true
            elseif low == 'noreload' or low == 'no-reload' then
                reloadOpt = false
            elseif low == 'local' or low == 'driver' or low == 'self' or low == 'nosync' then
                setupMode = 'local'
            elseif low == 'hooksonly' or low == 'hooks' or low == 'prepare' then
                setupMode = 'local'
                restoreRoute = false
            else
                manual = tok
            end
            i = i + 1
        end
        doLuaSetup(manual, reloadOpt, { mode = setupMode, restoreRoute = restoreRoute })
        if setupMode ~= 'local' then
            printf('\at[Turbo]\ax Setup finished. Quick Start will stay closed; open it with \ag/lua run Turbo onboarding\ax or the \ag?\ax button if needed.')
        end
    elseif cmd == 'backup' or cmd == 'bak' then
        TG.backupCliTarget = tostring(cliArg2 or 'turbo'):lower()
        if TG.backupCliTarget == 'turbo' or TG.backupCliTarget == 'turboloot' or TG.backupCliTarget == 'ini' or TG.backupCliTarget == 'active' then
            TG.lastBackupPath, TG.lastBackupErr = TG.backupActiveTurbolootIni()
            TG.printBackupResult('TurboLoot INI', TG.lastBackupPath, TG.lastBackupErr)
        elseif TG.backupCliTarget == 'e3' or TG.backupCliTarget == 'e3ini' then
            TG.lastBackupPath, TG.lastBackupErr = TG.backupLocalE3Ini(args[3])
            TG.printBackupResult('E3 INI', TG.lastBackupPath, TG.lastBackupErr)
        elseif TG.backupCliTarget == 'eqclient' or TG.backupCliTarget == 'eqclient.ini' or TG.backupCliTarget == 'eq' then
            TG.lastBackupPath, TG.lastBackupErr = TG.backupEqclientIni()
            TG.printBackupResult('eqclient.ini', TG.lastBackupPath, TG.lastBackupErr)
        elseif TG.backupCliTarget == 'all' or TG.backupCliTarget == 'both' or TG.backupCliTarget == 'local' then
            TG.lastBackupPath, TG.lastBackupErr = TG.backupActiveTurbolootIni()
            TG.printBackupResult('TurboLoot INI', TG.lastBackupPath, TG.lastBackupErr)
            TG.lastBackupPath, TG.lastBackupErr = TG.backupLocalE3Ini(args[3])
            TG.printBackupResult('E3 INI', TG.lastBackupPath, TG.lastBackupErr)
        else
            printf('\at[Turbo]\ax Backup commands: \ag/lua run Turbo backup turbo\ax, \agbackup e3\ax, \agbackup eqclient\ax, \agbackup all\ax')
        end
    elseif cmd == 'doctor' or cmd == 'diag' or cmd == 'check' then
        local sub = tostring(cliArg2 or ''):lower()
        if (cmd == 'diag' or cmd == 'doctor') and (sub == 'clean' or sub == 'cleanup') then
            local result = TG.cleanupDiagnosticsBundles({ keep = 5, maxAgeDays = 7 })
            printf('\at[Turbo]\ax Diagnostics cleanup: removed \ag%d\ax, kept \ag%d\ax%s',
                tonumber(result.removed) or 0,
                tonumber(result.kept) or 0,
                (tonumber(result.errors) or 0) > 0 and string.format(', \ar%d error(s)\ax', tonumber(result.errors) or 0) or '')
        else
            printTurboDoctor()
        end
    elseif cmd == 'view' or cmd == 'layout' then
        local v = (cliArg2 or 'full'):lower()
        if v == 'mini' then
            TG.slimWhenExpanded = false
            TG.slimGUI = false
            TG.minimizedGUI = true
        elseif v == 'slim' then
            TG.minimizedGUI = false
            TG.slimGUI = false
            TG.slimWhenExpanded = false
            v = 'full'
        else
            TG.minimizedGUI = false
            TG.slimGUI = false
            TG.slimWhenExpanded = false
        end
        saveSettings()
        printf('\at[Turbo]\ax Layout saved: \ag%s\ax (\ay/lua run Turbo\ax to open)', v)
    elseif cmd == 'patcher' or cmd == 'patch' or cmd == 'update' then
        -- Same path as the More tab's Turbo Patcher button.
        TG.openTurboPatcherExternal()
        printf('\at[Turbo]\ax %s', tostring(TG.statusMessage or ''))
    elseif cmd == 'help' then
        printHelp()
    else
        local spawnCount = mq.TLO.SpawnCount(string.format('pc %s', cliMode))()
        if spawnCount and spawnCount > 0 then
            if TG.requireSharedControl and TG.requireSharedControl('/lua run Turbo ' .. tostring(cliMode)) then
                setLooter(cliMode)
                printf('\at[Turbo]\ax Looter set to \ag%s\ax.', cliMode)
            else
                printf('\at[Turbo]\ax \ayBrowse mode:\ax %s owns Turbo control. Open Turbo and click Take Control to change looter.',
                    TG.sharedControlOwnerName and TG.sharedControlOwnerName() or 'another box')
            end
        else
            printf('\at[Turbo]\ax \arCannot find %s in zone.\ax', cliMode)
        end
    end
    end)()

    return
end

-- =========================================================
-- GUI mode
-- =========================================================
collectGroupMembers()
TG.markStartup('group')
bindTurboRuntimeCommands()
TG.markStartup('binds')
mq.imgui.init(scriptName, TG.renderWindow)
TG.markStartup('imgui')
if nowMS() - TG.startupT0 >= 1000 then
    printf('\at[Turbo]\ax startup %dms: %s', nowMS() - TG.startupT0, table.concat(TG.startupTrace, ', '))
end

while TG.windowOpen do
    -- Do not mq.doevents() here: it can interrupt TurboLoot GO while a mac is
    -- running. Review dismiss uses /turboreviewgoloot (bind) instead.
    require('Turbo.wares').processPendingActions(TG)
    -- Patcher shutdown hook: TurboPatcher drops turbo_patch.lock in the shared
    -- config dir before replacing files. TurboGear stops the rest of the suite;
    -- the hub only needs to end any running macro and close itself.
    if os.clock() >= (TG.patchLockNextCheck or 0) then
        TG.patchLockNextCheck = os.clock() + 1.0
        -- Field, not a local: this chunk is at LuaJIT's 200-local limit here.
        TG.patchLockHandle = io.open((mq.configDir or 'config') .. '/turbo_patch.lock', 'rb')
        if TG.patchLockHandle then
            TG.patchLockHandle:close()
            TG.patchLockHandle = nil
            print('[Turbo] patch lock detected - closing so the updater can replace files.')
            pcall(function() mq.cmd('/squelch /endmacro') end)
            TG.windowOpen = false
        end
        pcall(function()
            local okUC, UC = pcall(require, 'Turbo.update_check')
            if okUC and UC and UC.tick then UC.tick(TG) end
        end)
    end
    mq.delay(100)
end

saveSettings()
saveCharProfiles()
unbindTurboRuntimeCommands()
mq.imgui.destroy(scriptName)
