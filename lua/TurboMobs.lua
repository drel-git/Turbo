--[[                                                             
    ▄▄▄▄▄▄▄▄▄             ▄▄          ▄▄▄      ▄▄▄       ▄▄          
    ▀▀▀███▀▀▀             ██          ████▄  ▄████       ██          
       ███    ██ ██ ████▄ ████▄ ▄███▄ ███▀████▀███ ▄███▄ ████▄ ▄█▀▀▀ 
       ███    ██ ██ ██ ▀▀ ██ ██ ██ ██ ███  ▀▀  ███ ██ ██ ██ ██ ▀███▄ 
       ███    ▀██▀█ ██    ████▀ ▀███▀ ███      ███ ▀███▀ ████▀ ▄▄▄█▀                                  
               ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
               ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣶⣿⣿⣶⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
               ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
               ⠀⠀⠀⠀⠀⠀⠀⠀⢀⡼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢧⡀⠀⠀⠀⠀⠀⠀⠀⠀
               ⠀⠢⣤⣀⡀⠀⠀⠀⢿⣧⣄⡉⠻⢿⣿⣿⡿⠟⢉⣠⣼⡿⠀⠀⠀⠀⣀⣤⠔⠀
               ⠀⠀⠈⢻⣿⣶⠀⣷⠀⠉⠛⠿⠶⡴⢿⡿⢦⠶⠿⠛⠉⠀⣾⠀⣶⣿⡟⠁⠀⠀
               ⠀⠀⠀⠀⠻⣿⡆⠘⡇⠘⠷⠠⠦⠀⣾⣷⠀⠴⠄⠾⠃⢸⠃⢰⣿⠟⠀⠀⠀⠀
               ⠀⠀⠀⠀⠀⠋⢠⣾⣥⣴⣶⣶⣆⠘⣿⣿⠃⣰⣶⣶⣦⣬⣷⡄⠙⠀⠀⠀⠀⠀
               ⠀⠀⠀⠀⠀⠀⢋⠛⠻⠿⣿⠟⢹⣆⠸⠇⣰⡏⠻⣿⠿⠟⠛⡙⠀⠀⠀⠀⠀⠀
               ⠀⠀⠀⠀⠀⠀⠈⢧⡀⠠⠄⠀⠈⠛⠀⠀⠛⠁⠀⠠⠄⢀⡼⠁⠀⠀⠀⠀⠀⠀
               ⠀⠀⠀⠀⠀⠀⠀⠈⢻⣦⡀⠃⠀⣿⡆⢰⣿⠀⠘⢀⣴⡟⠁⠀⠀⠀⠀⠀⠀⠀
               ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠹⣿⣦⡀⠘⠇⠸⠃⢀⣴⣿⠏⠀⠀⠀⠀⠀⠀⠀⠀⠀
               ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⢿⣿⣷⣄⣠⣾⣿⡿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
               ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⠻⣿⣿⠟⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀

                    lightweight NPC spawn tracker
                            by Drel

    Drop into your MQ lua folder, then run:
        /lua run TurboMobs

    Commands:
        /tmobs                  Restore the primary TurboMobs window
        /tmobs show             Show full window
        /tmobs togglefull       Show/hide full window without stopping Watch/scanning
        /tmobs mini             Show/hide Turbo Watch
        /tmobs hide             Hide full search window
        /tmobs on               Enable polling while visible
        /tmobs off              Pause polling
        /tmobs refresh          Manual refresh
        /tmobs search <text>    Set name search filter
        /tmobs clearsearch      Clear name search filter
        /tmobs clearfilters     Clear search + structured filters
        /tmobs named            Toggle named-only filter
        /tmobs npc              Toggle NPC-only filter
        /tmobs targetable       Toggle targetable-only filter
        /tmobs alerts           Show/hide Turbo Watch
        /tmobs navstop          Stop active MQ navigation
        /tmobs importspawnmaster [all] Import current-zone or all-zone MQ2SpawnMaster.ini entries
        /tmobs compat [on|off|target|spawnmaster] Toggle MQ/E3 compatibility vars
        /tmobs statusvars       Echo MQ/E3 compatibility vars
        /tmobs config           Open the TurboMobs config folder
        /tmobs exports          Open/print the TurboMobs exports folder
        /tmobs perf             Write recent timing diagnostics to TurboMobs_perf_<name>.txt
        /tmobs diag             Write tester diagnostic snapshot to TurboMobs_diag_<name>.txt
        /tmobs help             Show the in-game help panel
        /tmobs watch [name]     Watch your current target, or a passed name
        /tmobs edit <name>      Open the watch editor for a saved watch
        /tmobs export [zone]    Export learned respawns (current zone or 'all')
        /tmobs import <file>    Import a respawns file from the exports folder
        /tmobs importalla [file] Import prepared Alla seed data from the exports folder
        /tmobs importalla all   Re-import the combined multi-zone bundle (alla_seeds_all.lua)
                                Bundled nameds auto-load on first in-game session
        /tmobs importalla preview [file] Validate an Alla seed without importing it
        /tmobs repairalla [zone|all] Repair older Alla seed point classification
        /tmobs quit             End script

    Alias:
        /turbomobs              Same as /tmobs

    Files (auto-created on first run):
        <mq.configDir>/TurboMobs/settings.lua    UI + filter preferences
        <mq.configDir>/TurboMobs/respawns.lua    Learned respawn data per zone
        <mq.configDir>/TurboMobs/watches.lua     Saved watches
        <mq.configDir>/TurboMobs/exports/        Shareable export files
]]

local mq = require('mq')
local ImGui = require('ImGui')
local Paths = require('Turbo.paths')
-- Pure, unit-tested primitives delegated to below (lua/tests/turbomobs_logic_test.lua).
local TM = require('turbomobs_logic')

local SCRIPT_NAME = 'TurboMobs'
local VERSION = '1.7.171'
local DATA_FORMAT_VERSION = 2

-- ============================================================
-- Paths and folder setup
-- ============================================================

local configRoot = mq.configDir or '.'
local turboFolder = configRoot .. '/TurboMobs'
local exportsFolder = turboFolder .. '/exports'
local settingsPath = turboFolder .. '/settings.lua'
local respawnsPath = turboFolder .. '/respawns.lua'
local watchesPath = turboFolder .. '/watches.lua'
local legacySettingsPath = configRoot .. '/TurboMobs_settings.lua'

local function turboLogPath(prefix, who)
    who = tostring(who or 'Unknown'):gsub('[^%w_%-]', '_')
    return Paths.log_file(string.format('%s_%s.txt', tostring(prefix or 'TurboMobs_log'), who))
        or string.format('%s/%s_%s.txt', turboFolder, tostring(prefix or 'TurboMobs_log'), who)
end

local function pathExists(path)
    local f = io.open(path, 'r')
    if f then f:close(); return true end
    return false
end

local function folderExists(path)
    local ok, _, code = os.rename(path, path)
    return ok == true or code == 13
end

local function ensureFolder(path)
    if folderExists(path) then return true end
    local okFfi, ffi = pcall(require, 'ffi')
    if okFfi then
        if not _G.TurboMobsCreateDirectoryCdef then
            pcall(ffi.cdef, [[
                int CreateDirectoryA(const char* lpPathName, void* lpSecurityAttributes);
            ]])
            _G.TurboMobsCreateDirectoryCdef = true
        end
        local winPath = tostring(path or ''):gsub('/', '\\'):gsub('\\+$', '')
        local current = ''
        local rest = winPath
        local drive = winPath:match('^%a:')
        if drive then
            current = drive
            rest = winPath:sub(4)
        end
        for part in rest:gmatch('[^\\]+') do
            if current == '' then current = part else current = current .. '\\' .. part end
            if not folderExists(current) then pcall(function() ffi.C.CreateDirectoryA(current, nil) end) end
        end
    end
    return folderExists(path)
end

local function atomicWrite(path, contents)
    local tmpPath = path .. '.tmp'
    local f, err = io.open(tmpPath, 'w')
    if not f then return false, err end
    f:write(contents)
    f:close()
    os.remove(path)
    local ok, renameErr = os.rename(tmpPath, path)
    if not ok then return false, renameErr end
    return true
end

-- ============================================================
-- UI state
-- ============================================================

local running = true
local showWindow = true
local compactMode = true
local enabled = true
local debugMode = false
local compatVarsEnabled = true
local spawnMasterCompat = true

local searchText = ''
local lastSearchEditMs = 0

local npcOnly = false
local namedOnly = false
local includeCorpses = false
local includePlayers = false
local includePets = false
local includeGroundItems = false
local maxDistance = 0
local minLevel = 0
local maxLevel = 999
local maxResults = 100
local scanMaxResults = 300

local sortMode = 'Distance'
local sortAscending = true

local welcomed = false
local allaHintShown = false

local refreshCompactMs = 5000
local refreshFullMs = 1500
local lastRefreshMs = 0
local lastWatchRefreshMs = 0
local lastSearchRefreshMs = 0
local statusText = 'Ready.'
local debugText = 'No scan yet.'
local debugTypeCounts = {}
local debugBodyCounts = {}
local debugRawRows = {}

local spawns = {}
local allSpawns = {}
local allSpawnsById = {}
local selectedId = nil
local selectedName = 'None'
local lastSelectedName = 'None'
local selectRow
local refreshSpawns
local saveSettings

-- Watch / alert state
local watchList = {}
local alertLog = {}
local showAlertsPanel = false
local respawnSound = true
local respawnSoundName = ''
local respawnSoundPath = 'AudioTriggers/default/'
local alertEcho = true
local announceMethod = '/echo'

local customRespawnInputs = {}

local exportInputZone = ''
local importInputFile = ''
local importStatusMsg = ''

local ux = {
    showMore = false,
    settingsAdvanced = false,
    showSettings = false,
    showHelpPanel = false,
    showIdColumn = true,
    showTypeColumn = true,
    showBodyColumn = true,
    showTrueNameColumn = false,
    showClassColumn = false,
    showDirectionColumn = false,
    showDirectionArrows = true,
    showAlertPopup = true,
    alertPopupClosedAt = 0,
    alertPopupRemindSeconds = 60,
    spawnPopup = true,
    spawnPopupCommand = '/popup',
    mapHighlight = false,
    mapHighlightColor = {160, 64, 255},
    bodyFilter = '',
    raceFilter = '',
    classFilter = '',
    typeFilter = '',
    activeFilterNeedles = { search = '', body = '', race = '', class = '', type = '' },
    disabledZones = {},
    doubleClickNav = true,
    navDistance = 20,
    useBulkSpawnScan = true,
    bulkScanMigratedV1 = false,
    liveSearchMigratedV2 = false,
    watchZoneViewMigratedV2 = false,
    targetCompatVarsEnabled = false,
    watchShowAll = true,
    watchShowUnknown = false,
    watchHideKnownTimersUntilSoon = false,
    watchTimerSoonSeconds = 240,
    watchPopupMaxCampsPerLabel = 2,
    watchCurrentZoneOnly = true,
    watchNamedOnly = false,
    watchIncludeGround = false,
    watchDetailFilter = 'all',
    watchDetailZone = 'current',
    learnAllSpawns = true,
    learnAllSeen = {},
    learnAllCandidates = {},
    zoneIntelFilter = 'linked',
    zoneIntelView = 'camps',
    zoneIntelCampsDefaultMigratedV1 = false,
    zoneIntelShowIgnored = false,
    watchPopupSort = { mode = 'default', asc = true },
    watchDetailSort = { mode = 'default', asc = true },
    watchMode = 'ultra',
    lastWatchAutoW = 0,
    watchRowsCache = { at = 0, key = '', rows = {} },
    watchDetailRowsCache = { at = 0, key = '', rows = {} },
    zoneIntelSort = { mode = 'default', asc = true },
    zoneIntelCache = { at = 0, key = '', rows = {} },
    watchFullBaselinePending = false,
    watchFullBaselineZoneIdentity = '',
    watchZoneEpoch = 0,
    watchZoneEnteredAt = 0,
    watchRowsCacheMs = 1500,
    watchPopupMaxDrawRows = 16,
    watchPopupCompanionMaxDrawRows = 8,
    watchPopupRowH = 20,
    liveSearchAutoLockAfterMs = 1200,
    useTargetedWatchRefresh = true,
    targetedWatchNameLimit = 5,
    targetedWatchMaxSpawns = 32,
    watchScanChunkSize = 6,
    watchScanMaxPhNamesPerWatch = 3,
    watchScanCursor = 1,
    watchUpdateCursor = 1,
    watchUpdateBudgetMs = 75,
    watchUpdateMinPerPass = 1,
    watchUpdateMaxPerPass = 8,
    watchUpdatePending = false,
    zoneEntryPrimeDelayMs = 500,
    zoneEntryPrimeRetryMs = 2500,
    zoneEntryPrimeStaleMs = 12000,
    targetedWatchRefreshReady = false,
    timeAgoCache = { bucket = 0, values = {} },
    spawnIndex = { byId = {}, byName = {}, byPoint = {}, presenceByName = {}, presenceByPoint = {} },
    watchIndex = { byId = {}, byName = {}, downByPoint = {}, current = {}, currentKeys = {} },
    windowGeom = {},
    perfLog = {},
    perfLogLimit = 60,
    perfThrottle = {},
    lastDrawTimingText = '',
    lastRefreshDecisionText = '',
    lastWatchRowsTimingText = '',
    lastWatchPopupTimingText = '',
    lastWatchDetailTimingText = '',
    lastMapHighlightRefreshMs = 0,
    lastMapHighlightKey = '',
    lastMapHighlightCount = 0,
    watchDetailStatus = '',
    watchZonePickerOpen = false,
    inspectWatchKey = '',
    inspectWatchOpen = false,
    editWatchKey = '',
    editWatchOpen = false,
    editWatchDraft = nil,
    selectedWatchKey = '',
    pendingWatchRow = nil,
    phNamedDraft = '',
    phNamedFilter = '',
    watchNameDraft = '',
    zoneIntelCacheMs = 7000,
    searchRefreshMs = 15000,
    searchStableWatchRefreshMs = 5000,
    liveSearch = false,
    liveSearchAutoOffAfterTabLeaveMs = 60000,
    searchTabLeftAt = 0,
    lastTrackedFullTab = '',
    inputsLocked = true,
    searchPage = 1,
    zoneIntelPage = 1,
    zoneIntelPageSize = 100,
    zoneIntelRefreshMs = 5000,
    settingsRefreshMs = 12000,
    watchesRefreshMs = 10000,
    watchPopupRefreshMs = 12000,
    watchUiRefreshMs = 12000,
    searchWatchedCacheKey = '',
    namedOrPHOnly = true,
    searchDefaultModeVersion = 1,
    targetableOnly = false,
    autoPauseSafeZones = true,
    seedAutoMaintain = true,
    bundledSeedAutoImported = false,
    useBundledSeedTimers = nil,
    bundledSeedTimersMigratedV1 = false,
    bundledSeedTimerRepairDone = false,
    seedAutoMaintainMigratedV1 = false,
    bundledSeedGeneratedAt = '',
    safeZoneScanOverride = false,
    lastZoneForSafePause = '',
    watchBaselineZone = '',
    watchBaselineZoneIdentity = '',
    watchBaselineReady = false,
    lastRespawnSoundMs = 0,
    respawnSoundCooldownMs = 1500,
    lastRefreshTimingText = '',
    lastLearnAllUpdateMS = 0,
    lastLearnAllZone = '',
    learnAllUpdateMS = 2500,
    learnAllCandidateHits = 3,
    learnTrashPruneDays = 4,
    autoPruneTrashOnZoneEntry = true,
    lastTrashPruneZone = '',
    lastZoneIntelLearnAllRefreshMS = 0,
    lastRespawnsSaveDeferredAt = 0,
    pendingRespawnSave = false,
    lastRespawnSaveMs = 0,
    lastWatchSaveAt = 0,
    lastWatchSaveDeferredAt = 0,
    lastWatchRuntimeSaveDeferredAt = 0,
    pendingWatchSave = false,
    pendingWatchSaveReason = '',
    pendingWatchRuntimeSave = false,
    pendingWatchRuntimeSaveReason = '',
    watchSaveForceAfterSec = 1800,
    watchRuntimeSaveForceAfterSec = 45,
    lastWatchSaveMs = 0,
    lastWatchRuntimeSaveMs = 0,
    lastWatchRuntimeSaveAt = 0,
    spawnDataRevision = 0,
    uiWantsTextInput = false,
    respawnSaveForceAfterSec = 1800,
    deferWatchRespawnSaves = true,
    deferWatchUiRefresh = true,
    lastStaleOccupantText = '',
    latestExportFile = '',
    activeNavTargetId = 0,
    activeNavStopDistance = 0,
    activeNavLastCheckMS = 0,
    activeNavStartedMS = 0,
    activeNavSawTarget = false,
    pendingNavClearTargetId = 0,
    pendingNavClearUntilMS = 0,
    pendingNavClearLastMS = 0,
    pendingTargetRowId = 0,
    pendingTargetRow = nil,
    pendingTargetAtMS = 0,
    currentTargetCache = { at = 0, id = 0, row = nil },
    pendingAllaImport = nil,
    allaSeedImportInProgress = false,
    watchSeedAwaitingZone = '',
    watchSeedAwaitingSince = 0,
    zoneEntryRefreshPending = false,
    zoneEntryRefreshMs = 2500,
    lastWatchUiZone = '',
    respawnsLoaded = false,
    respawnsLoadStarted = false,
    respawnsLoadAfterMS = 0,
    respawnsPostLoadQueue = nil,
    forceSearchScanOnZoneIn = false,
    safeZoneShortNames = {
        poknowledge = true,
        knowledge = true,
        guildlobby = true,
        bazaar = true,
        nexus = true,
    },
    pumpCommandEvents = function() end,
}

ux.winQuotedArg = function(p)
    if not p then return '""' end
    return '"' .. tostring(p):gsub('"', '') .. '"'
end


-- ============================================================
-- Learned respawns
-- ============================================================

local respawnsData = {
    _meta = {
        version = DATA_FORMAT_VERSION,
        server = '',
        last_updated = '',
        contributors = {},
    },
}

local MAX_SAMPLES_PER_MOB = 20
local MIN_SAMPLES_FOR_DISPLAY = 3
-- Samples needed before a strong observed/Alla disagreement (>2x) is trusted
-- early, so a camp Alla mislabeled (e.g. a rare-named interval vs the PH cycle)
-- self-corrects fast instead of waiting for a full sample set.
local EARLY_TIMER_DIVERGENCE_SAMPLES = 5
ux.watchDueCountUpLimitSec = 15 * 60
ux.watchStaleDueMinSec = 60 * 60
ux.watchStaleDueRespawnMult = 6
ux.minRespawnSampleSeconds = 45
ux.defaultPointOccupantRadius = 6
-- Legacy seed anchor hint; discovery no longer gates on a fixed radius (roamers).
ux.seedWatchAnchorRadius = 8
local respawnsDirty = false
local lastRespawnsSaveAt = 0
local RESPAWNS_SAVE_INTERVAL_SEC = 30
local saveRespawns
local saveWatches

-- ============================================================
-- Colors / styling
-- ============================================================

-- ============================================================
-- Color language (semantic roles for buttonColors keys)
-- Aligns with the TurboLoot suite palette so the tools feel unified.
--   start       green        : active / ON state, tracking running, active toggle
--   stop        orange-brown : paused / stopped state
--   primary     blue         : primary action / navigation (Refresh, Nav)
--   tools       slate-blue   : secondary tool action
--   accent      teal         : informational / editable-mode accent
--   neutral     gray         : inactive toggle / secondary / default state
--   warn        amber        : caution state (e.g. Inputs Locked)
--   danger      bright red   : destructive action (remove / x) -- reserved, used sparingly
--   unloadDark  dark red     : Unload (quiet destructive; distinct from bright danger)
--   windowToggle amber-brown : window chrome minimize (-) / expand (+)
--   expand/gold              : legacy, retained for compatibility (no current callers)
-- ============================================================
local buttonColors = {
    start = {0.22, 0.42, 0.27, 1.00, 0.28, 0.52, 0.34, 1.00, 0.17, 0.32, 0.21, 1.00},
    stop = {0.50, 0.32, 0.14, 1.00, 0.60, 0.40, 0.18, 1.00, 0.38, 0.24, 0.10, 1.00},
    primary = {0.26, 0.39, 0.58, 1.00, 0.32, 0.47, 0.68, 1.00, 0.20, 0.31, 0.48, 1.00},
    tools = {0.27, 0.35, 0.50, 1.00, 0.34, 0.44, 0.62, 1.00, 0.20, 0.27, 0.40, 1.00},
    expand = {0.38, 0.30, 0.31, 1.00, 0.48, 0.38, 0.39, 1.00, 0.28, 0.22, 0.23, 1.00},
    danger = {0.42, 0.18, 0.18, 1.00, 0.54, 0.22, 0.22, 1.00, 0.32, 0.13, 0.13, 1.00},
    neutral = {0.29, 0.31, 0.35, 1.00, 0.37, 0.39, 0.44, 1.00, 0.22, 0.24, 0.28, 1.00},
    warn = {0.55, 0.45, 0.18, 1.00, 0.65, 0.55, 0.22, 1.00, 0.42, 0.34, 0.13, 1.00},
    accent = {0.16, 0.40, 0.42, 1.00, 0.21, 0.50, 0.52, 1.00, 0.11, 0.30, 0.32, 1.00},
    gold = {0.34, 0.27, 0.19, 0.82, 0.46, 0.36, 0.23, 0.92, 0.26, 0.20, 0.13, 0.88},
    -- Amber window-chrome toggles (minimize / expand). Warm amber-brown, echoes the TurboLoot mini bar.
    windowToggle = {0.48, 0.36, 0.17, 1.00, 0.60, 0.46, 0.22, 1.00, 0.38, 0.28, 0.13, 1.00},
    ultra = {0.36, 0.28, 0.55, 1.00, 0.46, 0.36, 0.68, 1.00, 0.28, 0.22, 0.44, 1.00},
    menu = {0.23, 0.34, 0.49, 1.00, 0.29, 0.41, 0.58, 1.00, 0.19, 0.29, 0.43, 1.00},
    -- Subtle dark red for Unload (destructive-but-quiet; brighter 'danger' stays for remove/x actions).
    unloadDark = {0.30, 0.13, 0.13, 1.00, 0.40, 0.18, 0.18, 1.00, 0.22, 0.10, 0.10, 1.00},
}

local textColors = {
    active = {0.33, 0.78, 0.76, 1.00},
    stopped = {0.90, 0.70, 0.38, 1.00},
    idle = {0.65, 0.69, 0.76, 1.00},
    selected = {0.55, 0.78, 1.00, 1.00},
    distance = {0.95, 0.72, 0.28, 1.00},
    last = {0.72, 0.52, 0.86, 1.00},
    muted = {0.70, 0.74, 0.80, 1.00},
    alertUp = {0.40, 1.00, 0.52, 1.00},
    alertDown = {1.00, 0.55, 0.40, 1.00},
    learned = {0.55, 0.85, 1.00, 1.00},
    etaSoon = {1.00, 0.78, 0.32, 1.00},
}

-- ============================================================
-- Utility
-- ============================================================

local function nowMs()
    local ok, value = pcall(function() return mq.gettime() end)
    value = tonumber(value)
    if ok and value then
        if value > 0 and value < 100000 and value ~= math.floor(value) then
            return math.floor(value * 1000)
        end
        return math.floor(value)
    end
    return os.time() * 1000
end
local function trim(s) return (s or ''):gsub('^%s+', ''):gsub('%s+$', '') end

local function splitArgs(line)
    local args = {}
    local text = tostring(line or '')
    local i, n = 1, #text
    while i <= n do
        while i <= n and text:sub(i, i):match('%s') do i = i + 1 end
        if i > n then break end
        local quote = text:sub(i, i)
        local value = {}
        if quote == '"' or quote == "'" then
            i = i + 1
            while i <= n do
                local ch = text:sub(i, i)
                if ch == quote then i = i + 1; break end
                table.insert(value, ch)
                i = i + 1
            end
        else
            while i <= n and not text:sub(i, i):match('%s') do
                table.insert(value, text:sub(i, i))
                i = i + 1
            end
        end
        table.insert(args, table.concat(value))
    end
    return args
end

local function chat(msg) mq.cmdf('/echo \\at[%s]\\ax %s', SCRIPT_NAME, msg) end

local function notify(msg)
    chat(msg)
    pcall(function() mq.cmdf('/popup %s', tostring(msg or ''):gsub('[\r\n]', ' ')) end)
end

local function safeCall(fn, fallback)
    local ok, value = pcall(fn)
    if ok and value ~= nil then return value end
    return fallback
end

local function clientInGame()
    -- Called several times per main-loop tick (loop, refreshIfDue, kill poll,
    -- zone sync). Each uncached call does multiple TLO reads, so memoize for a
    -- sub-tick window (40ms < the 50ms in-game tick) to collapse the duplicates.
    local nowTick = nowMs()
    local cache = ux.inGameCache
    if cache and (nowTick - (cache.at or 0)) < 40 then
        return cache.value
    end

    local function compute()
        local stateCandidates = {
            safeCall(function() return mq.TLO.EverQuest.GameState() end, ''),
            safeCall(function() return mq.TLO.GameState() end, ''),
        }
        for _, state in ipairs(stateCandidates) do
            local text = trim(tostring(state or '')):lower()
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

        local me = trim(tostring(safeCall(function() return mq.TLO.Me.Name() end, '') or ''))
        local zone = trim(tostring(safeCall(function() return mq.TLO.Zone.ShortName() end, '') or ''))
        local meLower, zoneLower = me:lower(), zone:lower()
        return me ~= '' and meLower ~= 'nil' and meLower ~= 'null'
            and zone ~= '' and zoneLower ~= 'unknown' and zoneLower ~= 'nil' and zoneLower ~= 'null'
    end

    local result = compute()
    ux.inGameCache = { at = nowTick, value = result }
    return result
end

local function shortText(text, maxLen)
    text = tostring(text or '')
    maxLen = maxLen or 18
    if #text <= maxLen then return text end
    return text:sub(1, math.max(1, maxLen - 3)) .. '...'
end

local function currentZoneLongName()
    local candidates = {
        safeCall(function() return mq.TLO.Zone.Name() end, ''),
        safeCall(function() return mq.TLO.Zone.LongName() end, ''),
        safeCall(function() return mq.TLO.Zone() end, ''),
    }
    for _, value in ipairs(candidates) do
        local text = trim(tostring(value or ''))
        if text ~= '' and text:lower() ~= 'unknown' then return text end
    end
    return ''
end

local function currentZoneShortRaw()
    return tostring(safeCall(function() return mq.TLO.Zone.ShortName() end, 'unknown') or 'unknown'):lower()
end

local function currentZoneShort()
    local short = currentZoneShortRaw()
    local longName = currentZoneLongName():lower()
    if longName:find('hardcore', 1, true) and not short:find('_hc', 1, true) then
        local version = longName:match('version%s*(%d+)') or longName:match('%(v(%d+)%)')
        if version and version ~= '1' then return short .. '_hc_v' .. version end
        return short .. '_hc'
    end
    -- Instance/DZ zone-in: long name can lag behind; prefer _hc when seeded watches exist.
    if not short:find('_hc', 1, true) then
        local dzId = tonumber(safeCall(function() return mq.TLO.DynamicZone.ID() end, 0)) or 0
        local inst = tonumber(safeCall(function() return mq.TLO.Me.Instance() end, 0)) or 0
        if dzId > 0 or inst > 0 then
            local hcShort = short .. '_hc'
            for _, w in pairs(watchList or {}) do
                if type(w) == 'table' and tostring(w.zone or ''):lower() == hcShort then
                    return hcShort
                end
            end
        end
    end
    return short
end

ux.cleanZoneIdentityPart = function(value)
    local text = trim(tostring(value or ''))
    local lower = text:lower()
    if text == '' or lower == 'unknown' or lower == 'nil' or lower == 'null' or lower == '0' then return '' end
    return text:gsub('[|]', '/')
end

ux.currentZoneRuntimeIdentity = function()
    local short = currentZoneShort()
    local parts = { short }
    local longName = ux.cleanZoneIdentityPart(currentZoneLongName())
    if longName ~= '' then table.insert(parts, 'long=' .. longName:lower()) end

    local dzCandidates = {
        safeCall(function() return mq.TLO.DynamicZone.ID() end, ''),
        safeCall(function() return mq.TLO.DynamicZone.Name() end, ''),
        safeCall(function() return mq.TLO.DynamicZone.Leader() end, ''),
        safeCall(function() return mq.TLO.Me.Instance() end, ''),
        safeCall(function() return mq.TLO.Zone.Instance() end, ''),
    }
    for _, value in ipairs(dzCandidates) do
        local text = ux.cleanZoneIdentityPart(value)
        if text ~= '' then table.insert(parts, 'dz=' .. text:lower()); break end
    end

    return table.concat(parts, '|')
end

ux.isSparseWatchRefresh = function()
    local source = tostring(ux.currentRefreshSource or ux.lastRefreshSource or '')
    return source:find('targeted%-watch', 1, true) ~= nil
end

ux.spawnSnapshotMatchesCurrentZone = function()
    if not clientInGame() then return false end
    local current = tostring(ux.currentZoneRuntimeIdentity and ux.currentZoneRuntimeIdentity() or currentZoneShort())
    local live = tostring(ux.spawnIndexZoneIdentity or '')
    if live ~= '' and live == current then return true end
    local full = tostring(ux.fullSpawnZoneIdentity or '')
    if full ~= '' and full == current then return true end
    return false
end

ux.zoneWatchesNeedFirstScan = function()
    if not clientInGame() then return false end
    if ux.safeZoneScanPaused and ux.safeZoneScanPaused() then return false end
    if ux.zoneEntryRefreshPending == true then return true end
    if ux.watchFullBaselinePending == true then return true end
    if not ux.spawnSnapshotMatchesCurrentZone() then return true end
    local byId = ux.spawnIndex and ux.spawnIndex.byId
    if type(byId) ~= 'table' or next(byId) == nil then return true end
    return false
end

ux.buildStickySpawnRowFromWatch = function(watch, id)
    if not watch then return nil end
    id = tonumber(id) or tonumber(watch.occupantSpawnId or 0) or 0
    if id <= 0 then return nil end
    local name = trim(tostring(watch.currentName or watch.occupantName or watch.lastOccupantName or ''))
    if name == '' then return nil end
    local row = {
        id = id,
        name = name,
        x = tonumber(watch.lastX) or 0,
        y = tonumber(watch.lastY) or 0,
        z = tonumber(watch.lastZ) or 0,
        level = 0,
        distance = 9999,
        type = 'NPC',
        body = '',
        sticky = true,
    }
    if ux.finalizeSpawnRow then ux.finalizeSpawnRow(row) end
    return row
end

ux.resolveStickyWatchOccupant = function(watch, id)
    if not watch then return nil end
    id = tonumber(id) or tonumber(watch.occupantSpawnId or 0) or 0
    if id <= 0 then return nil end
    local byId = ux.spawnIndex and ux.spawnIndex.byId and ux.spawnIndex.byId[id]
    if byId and passWatchPresenceFilters(byId) then return byId end
    return ux.buildStickySpawnRowFromWatch(watch, id)
end

function ux.isSafeHubZone()
    return ux.safeZoneShortNames[currentZoneShort()] == true
end

function ux.safeZoneScanPaused()
    return ux.autoPauseSafeZones == true and ux.isSafeHubZone() and ux.safeZoneScanOverride ~= true
end

local function currentServer()
    return tostring(safeCall(function() return mq.TLO.EverQuest.Server() end, '') or '')
end

ux.isLazarusServer = function()
    local server = currentServer():lower()
    if server == '' then return false end
    return server:find('lazarus', 1, true) ~= nil
end

local function currentCharacter()
    return tostring(safeCall(function() return mq.TLO.Me.Name() end, '') or '')
end

local function dateStamp() return os.date('%Y-%m-%d') end

local function formatSeconds(sec)
    sec = tonumber(sec) or 0
    if sec < 0 then sec = 0 end
    local m = math.floor(sec / 60)
    local s = math.floor(sec % 60)
    return string.format('%d:%02d', m, s)
end

local function localTimeText()
    return os.date('%I:%M %p')
end

ux.classAbbrevs = {
    Warrior = 'WAR',
    Cleric = 'CLR',
    Paladin = 'PAL',
    Ranger = 'RNG',
    Shadowknight = 'SHD',
    ShadowKnight = 'SHD',
    Druid = 'DRU',
    Monk = 'MNK',
    Bard = 'BRD',
    Rogue = 'ROG',
    Shaman = 'SHM',
    Necromancer = 'NEC',
    Wizard = 'WIZ',
    Magician = 'MAG',
    Enchanter = 'ENC',
    Beastlord = 'BST',
    Berserker = 'BER',
    Mercenary = 'MERC',
}

ux.classText = function(className)
    className = tostring(className or '')
    return ux.classAbbrevs[className] or (className ~= '' and className or '-')
end

ux.classSearchText = function(className)
    local raw = tostring(className or '')
    local lower = raw:lower()
    if lower == '' or lower == 'unknown' then return lower end

    local parts = { lower }
    local abbr = ux.classAbbrevs[raw]
    if abbr and abbr ~= '' then parts[#parts + 1] = abbr:lower() end

    for longName, shortName in pairs(ux.classAbbrevs or {}) do
        local longLower = tostring(longName or ''):lower()
        local shortLower = tostring(shortName or ''):lower()
        if lower == longLower or lower == shortLower then
            parts[#parts + 1] = longLower
            parts[#parts + 1] = shortLower
        end
    end
    return table.concat(parts, ' ')
end

local function addDebugCount(t, key)
    key = tostring(key or 'Unknown')
    t[key] = (t[key] or 0) + 1
end

local function tableCount(t)
    local n = 0
    if type(t) ~= 'table' then return n end
    for _ in pairs(t) do n = n + 1 end
    return n
end

local function topDebugCounts(t, maxItems)
    local rows = {}
    for k, v in pairs(t or {}) do table.insert(rows, {key = k, value = v}) end
    table.sort(rows, function(a, b)
        if a.value == b.value then return a.key < b.key end
        return a.value > b.value
    end)
    local parts = {}
    for i = 1, math.min(maxItems or 6, #rows) do
        table.insert(parts, string.format('%s=%d', rows[i].key, rows[i].value))
    end
    return table.concat(parts, ' | ')
end

-- ============================================================
-- Lua serializer for our data files
-- ============================================================

local function serializeLua(value, indent)
    indent = indent or ''
    local nextIndent = indent .. '  '
    local t = type(value)

    if t == 'nil' then return 'nil' end
    if t == 'boolean' then return tostring(value) end
    if t == 'number' then
        if value ~= value then return '0' end
        if value == math.huge or value == -math.huge then return '0' end
        return tostring(value)
    end
    if t == 'string' then return string.format('%q', value) end

    if t == 'table' then
        local n = #value
        local isArray = (n > 0)
        if isArray then
            local count = 0
            for _ in pairs(value) do count = count + 1 end
            if count ~= n then isArray = false end
        end

        if isArray then
            local parts = {}
            for i = 1, n do table.insert(parts, serializeLua(value[i], nextIndent)) end
            return '{ ' .. table.concat(parts, ', ') .. ' }'
        end

        local keys = {}
        for k in pairs(value) do table.insert(keys, k) end
        table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)

        if #keys == 0 then return '{}' end

        local lines = {'{'}
        for _, k in ipairs(keys) do
            local v = value[k]
            local keyStr
            if type(k) == 'string' and k:match('^[%a_][%w_]*$') then
                keyStr = k
            else
                keyStr = '[' .. serializeLua(k, '') .. ']'
            end
            table.insert(lines, string.format('%s%s = %s,', nextIndent, keyStr, serializeLua(v, nextIndent)))
        end
        table.insert(lines, indent .. '}')
        return table.concat(lines, '\n')
    end

    return 'nil'
end

local function serializeAsModule(tbl)
    return 'return ' .. serializeLua(tbl, '') .. '\n'
end

-- ============================================================
-- Settings persistence
-- ============================================================

local function buildSettingsTable()
    return {
        compactMode = compactMode,
        enabled = enabled,
        showMore = ux.showMore,
        settingsAdvanced = ux.settingsAdvanced == true,
        showSettings = ux.showSettings,
        compatVarsEnabled = compatVarsEnabled,
        spawnMasterCompat = spawnMasterCompat,
        targetCompatVarsEnabled = ux.targetCompatVarsEnabled,
        npcOnly = npcOnly,
        targetableOnly = ux.targetableOnly,
        namedOnly = namedOnly,
        includeCorpses = includeCorpses,
        includePlayers = includePlayers,
        includePets = includePets,
        includeGroundItems = includeGroundItems,
        bodyFilter = ux.bodyFilter,
        raceFilter = ux.raceFilter,
        classFilter = ux.classFilter,
        typeFilter = ux.typeFilter,
        maxDistance = tonumber(maxDistance) or 0,
        maxResults = tonumber(maxResults) or 100,
        scanMaxResults = tonumber(scanMaxResults) or 500,
        minLevel = tonumber(minLevel) or 0,
        maxLevel = tonumber(maxLevel) or 999,
        sortMode = sortMode or 'Distance',
        sortAscending = sortAscending,
        showIdColumn = ux.showIdColumn,
        showTypeColumn = ux.showTypeColumn,
        showBodyColumn = ux.showBodyColumn,
        showTrueNameColumn = ux.showTrueNameColumn,
        showClassColumn = ux.showClassColumn,
        showDirectionColumn = ux.showDirectionColumn,
        showDirectionArrows = ux.showDirectionArrows,
        respawnSound = respawnSound,
        respawnSoundName = respawnSoundName,
        respawnSoundPath = respawnSoundPath,
        alertEcho = alertEcho,
        announceMethod = announceMethod,
        spawnPopup = ux.spawnPopup,
        spawnPopupCommand = ux.spawnPopupCommand,
        mapHighlight = ux.mapHighlight,
        mapHighlightColor = ux.mapHighlightColor,
        respawnSoundCooldownMs = ux.respawnSoundCooldownMs,
        showAlertPopup = ux.showAlertPopup,
        alertPopupRemindSeconds = ux.alertPopupRemindSeconds,
        disabledZones = ux.disabledZones,
        doubleClickNav = ux.doubleClickNav,
        watchMode = 'ultra',
        watchShowAll = ux.watchShowAll,
        watchShowUnknown = ux.watchShowUnknown == true,
        watchHideKnownTimersUntilSoon = ux.watchHideKnownTimersUntilSoon == true,
        watchCurrentZoneOnly = ux.watchCurrentZoneOnly,
        watchNamedOnly = ux.watchNamedOnly,
        namedOrPHOnly = ux.namedOrPHOnly,
        searchDefaultModeVersion = tonumber(ux.searchDefaultModeVersion) or 1,
        watchIncludeGround = ux.watchIncludeGround,
        watchDetailZone = ux.watchDetailZone,
        liveSearch = ux.liveSearch,
        inputsLocked = ux.inputsLocked,
        zoneIntelFilter = ux.zoneIntelFilter,
        zoneIntelView = ux.zoneIntelView,
        zoneIntelShowIgnored = ux.zoneIntelShowIgnored,
        zoneIntelPageSize = ux.zoneIntelPageSize,
        windowGeom = ux.windowGeom,
        learnAllSpawns = ux.learnAllSpawns,
        autoPauseSafeZones = ux.autoPauseSafeZones,
        navDistance = tonumber(ux.navDistance) or 20,
        useBulkSpawnScan = ux.useBulkSpawnScan == true,
        bulkScanMigratedV1 = ux.bulkScanMigratedV1 == true,
        liveSearchMigratedV2 = ux.liveSearchMigratedV2 == true,
        watchZoneViewMigratedV2 = ux.watchZoneViewMigratedV2 == true,
        zoneIntelFilterMigratedV3 = ux.zoneIntelFilterMigratedV3 == true,
        zoneIntelCampsDefaultMigratedV1 = ux.zoneIntelCampsDefaultMigratedV1 == true,
        watchModeUltraMigratedV1 = ux.watchModeUltraMigratedV1 == true,
        welcomed = welcomed,
        allaHintShown = allaHintShown,
        seedAutoMaintain = ux.seedAutoMaintain == true,
        bundledSeedAutoImported = ux.bundledSeedAutoImported == true,
        useBundledSeedTimers = ux.useBundledSeedTimers,
        bundledSeedTimersMigratedV1 = ux.bundledSeedTimersMigratedV1 == true,
        bundledSeedTimerRepairDone = ux.bundledSeedTimerRepairDone == true,
        seedAutoMaintainMigratedV1 = ux.seedAutoMaintainMigratedV1 == true,
        bundledSeedGeneratedAt = ux.bundledSeedGeneratedAt or '',
    }
end

local function applySettingsTable(data)
    if type(data) ~= 'table' then return end
    compactMode = data.compactMode ~= nil and data.compactMode or compactMode
    enabled = data.enabled ~= nil and data.enabled or enabled
    ux.showMore = data.showMore ~= nil and data.showMore or ux.showMore
    ux.settingsAdvanced = data.settingsAdvanced == true
    ux.showSettings = data.showSettings ~= nil and data.showSettings or ux.showSettings
    compatVarsEnabled = data.compatVarsEnabled ~= nil and data.compatVarsEnabled or compatVarsEnabled
    spawnMasterCompat = data.spawnMasterCompat ~= nil and data.spawnMasterCompat or spawnMasterCompat
    ux.targetCompatVarsEnabled = data.targetCompatVarsEnabled == true
    npcOnly = data.npcOnly ~= nil and data.npcOnly or npcOnly
    ux.targetableOnly = data.targetableOnly ~= nil and data.targetableOnly or ux.targetableOnly
    namedOnly = data.namedOnly ~= nil and data.namedOnly or namedOnly
    includeCorpses = data.includeCorpses ~= nil and data.includeCorpses or includeCorpses
    includePlayers = data.includePlayers ~= nil and data.includePlayers or includePlayers
    includePets = data.includePets ~= nil and data.includePets or includePets
    includeGroundItems = data.includeGroundItems ~= nil and data.includeGroundItems or includeGroundItems
    ux.bodyFilter = tostring(data.bodyFilter or ux.bodyFilter or '')
    ux.raceFilter = tostring(data.raceFilter or ux.raceFilter or '')
    ux.classFilter = tostring(data.classFilter or ux.classFilter or '')
    ux.typeFilter = tostring(data.typeFilter or ux.typeFilter or '')
    maxDistance = tonumber(data.maxDistance) or maxDistance
    maxResults = tonumber(data.maxResults) or maxResults
    if maxResults == 80 then maxResults = 100 end
    maxResults = math.max(20, math.min(500, maxResults))
    scanMaxResults = tonumber(data.scanMaxResults) or scanMaxResults
    minLevel = tonumber(data.minLevel) or minLevel
    maxLevel = tonumber(data.maxLevel) or maxLevel
    ux.normalizeLevelFilters()
    sortMode = data.sortMode or sortMode
    if sortMode == 'Direction' then sortMode = 'Distance' end
    sortAscending = data.sortAscending ~= nil and data.sortAscending or sortAscending
    ux.showIdColumn = data.showIdColumn ~= nil and data.showIdColumn or ux.showIdColumn
    ux.showTypeColumn = data.showTypeColumn ~= nil and data.showTypeColumn or ux.showTypeColumn
    ux.showBodyColumn = data.showBodyColumn ~= nil and data.showBodyColumn or ux.showBodyColumn
    ux.showTrueNameColumn = data.showTrueNameColumn ~= nil and data.showTrueNameColumn or ux.showTrueNameColumn
    ux.showClassColumn = data.showClassColumn ~= nil and data.showClassColumn or ux.showClassColumn
    ux.showDirectionColumn = false
    ux.showDirectionArrows = data.showDirectionArrows ~= nil and data.showDirectionArrows or ux.showDirectionArrows
    respawnSound = data.respawnSound ~= nil and data.respawnSound or (data.alertBeep ~= nil and data.alertBeep or respawnSound)
    respawnSoundName = data.respawnSoundName or respawnSoundName
    respawnSoundPath = data.respawnSoundPath or respawnSoundPath
    alertEcho = data.alertEcho ~= nil and data.alertEcho or alertEcho
    announceMethod = data.announceMethod or announceMethod
    ux.spawnPopup = data.spawnPopup ~= nil and data.spawnPopup or ux.spawnPopup
    ux.spawnPopupCommand = type(data.spawnPopupCommand) == 'string' and data.spawnPopupCommand or ux.spawnPopupCommand
    -- Disabled until the MQ highlight command path is confirmed working. Keeping
    -- this false also avoids wasted background watch resolution in tester builds.
    ux.mapHighlight = false
    ux.mapHighlightColor = type(data.mapHighlightColor) == 'table' and data.mapHighlightColor or ux.mapHighlightColor
    ux.respawnSoundCooldownMs = tonumber(data.respawnSoundCooldownMs) or ux.respawnSoundCooldownMs
    ux.navDistance = math.max(1, tonumber(data.navDistance) or tonumber(ux.navDistance) or 20)
    -- Bulk spawn scan defaults ON (single O(n) getAllSpawns vs the O(n^2)
    -- NearestSpawn loop). Installs created before this became the default have it
    -- serialized as false; flip those exactly once via bulkScanMigratedV1, then
    -- honor the user's explicit choice from then on.
    if data.bulkScanMigratedV1 == true then
        ux.useBulkSpawnScan = data.useBulkSpawnScan ~= false
        ux.bulkScanMigratedV1 = true
    else
        ux.useBulkSpawnScan = true
        ux.bulkScanMigratedV1 = true
        ux.bulkScanJustMigrated = true
    end
    ux.showAlertPopup = data.showAlertPopup ~= nil and data.showAlertPopup or ux.showAlertPopup
    ux.alertPopupRemindSeconds = tonumber(data.alertPopupRemindSeconds) or ux.alertPopupRemindSeconds
    ux.disabledZones = type(data.disabledZones) == 'table' and data.disabledZones or ux.disabledZones
    ux.doubleClickNav = data.doubleClickNav ~= nil and data.doubleClickNav or ux.doubleClickNav
    if tostring(data.watchMode or ''):lower() ~= 'ultra' and data.watchModeUltraMigratedV1 ~= true then
        ux.watchModeLeanMigrated = true
    end
    ux.watchMode = 'ultra'
    ux.watchModeUltraMigratedV1 = true
    ux.watchShowAll = data.watchShowAll ~= nil and data.watchShowAll or ux.watchShowAll
    ux.watchShowUnknown = data.watchShowUnknown == true
    ux.watchHideKnownTimersUntilSoon = data.watchHideKnownTimersUntilSoon == true
    ux.watchCurrentZoneOnly = data.watchCurrentZoneOnly ~= nil and data.watchCurrentZoneOnly or ux.watchCurrentZoneOnly
    ux.watchNamedOnly = data.watchNamedOnly ~= nil and data.watchNamedOnly or ux.watchNamedOnly
    ux.namedOrPHOnly = data.namedOrPHOnly ~= nil and data.namedOrPHOnly or ux.namedOrPHOnly
    if (tonumber(data.searchDefaultModeVersion) or 0) < 1 then
        if data.namedOnly ~= true then
            namedOnly = false
            ux.namedOrPHOnly = true
        end
    end
    ux.searchDefaultModeVersion = 1
    ux.watchIncludeGround = data.watchIncludeGround ~= nil and data.watchIncludeGround or ux.watchIncludeGround
    ux.watchDetailZone = type(data.watchDetailZone) == 'string' and data.watchDetailZone or ux.watchDetailZone
    if data.liveSearchMigratedV2 == true then
        ux.liveSearch = data.liveSearch ~= nil and data.liveSearch or ux.liveSearch
        ux.liveSearchMigratedV2 = true
    else
        if data.liveSearch == true then
            ux.liveSearch = false
            ux.liveSearchJustMigrated = true
        else
            ux.liveSearch = data.liveSearch ~= nil and data.liveSearch or ux.liveSearch
        end
        ux.liveSearchMigratedV2 = true
    end
    if data.watchZoneViewMigratedV2 == true then
        ux.watchCurrentZoneOnly = data.watchCurrentZoneOnly ~= nil and data.watchCurrentZoneOnly or ux.watchCurrentZoneOnly
        ux.watchZoneViewMigratedV2 = true
    else
        if data.watchCurrentZoneOnly == false then
            ux.watchCurrentZoneOnly = true
            ux.watchZoneViewJustMigrated = true
        else
            ux.watchCurrentZoneOnly = data.watchCurrentZoneOnly ~= nil and data.watchCurrentZoneOnly or ux.watchCurrentZoneOnly
        end
        ux.watchZoneViewMigratedV2 = true
    end
    if data.inputsLocked ~= nil then ux.inputsLocked = data.inputsLocked == true end
    ux.zoneIntelFilter = type(data.zoneIntelFilter) == 'string' and data.zoneIntelFilter or ux.zoneIntelFilter
    if ux.zoneIntelFilter ~= 'linked' and ux.zoneIntelFilter ~= 'all' then ux.zoneIntelFilter = 'linked' end
    ux.zoneIntelView = type(data.zoneIntelView) == 'string' and data.zoneIntelView or ux.zoneIntelView
    if ux.zoneIntelView ~= 'points' and ux.zoneIntelView ~= 'camps' then ux.zoneIntelView = 'camps' end
    if data.zoneIntelCampsDefaultMigratedV1 == true then
        ux.zoneIntelCampsDefaultMigratedV1 = true
    elseif not ux.zoneIntelCampsDefaultMigratedV1 then
        ux.zoneIntelFilter = 'linked'
        ux.zoneIntelView = 'camps'
        ux.zoneIntelCampsDefaultMigratedV1 = true
        ux.zoneIntelCampsDefaultJustMigrated = true
    end
    if data.zoneIntelFilterMigratedV3 == true then
        ux.zoneIntelFilterMigratedV3 = true
    elseif not ux.zoneIntelFilterMigratedV3 then
        ux.zoneIntelFilter = 'linked'
        ux.zoneIntelFilterMigratedV3 = true
        ux.zoneIntelFilterJustMigrated = true
    end
    ux.zoneIntelShowIgnored = data.zoneIntelShowIgnored ~= nil and data.zoneIntelShowIgnored or ux.zoneIntelShowIgnored
    ux.zoneIntelPageSize = tonumber(data.zoneIntelPageSize) or tonumber(data.zoneIntelMaxRows) or ux.zoneIntelPageSize
    ux.zoneIntelPageSize = math.max(50, math.min(250, ux.zoneIntelPageSize))
    ux.windowGeom = type(data.windowGeom) == 'table' and data.windowGeom or ux.windowGeom
    ux.learnAllSpawns = data.learnAllSpawns ~= nil and data.learnAllSpawns or ux.learnAllSpawns
    ux.autoPauseSafeZones = data.autoPauseSafeZones ~= nil and data.autoPauseSafeZones or ux.autoPauseSafeZones
    welcomed = data.welcomed ~= nil and data.welcomed or welcomed
    allaHintShown = data.allaHintShown ~= nil and data.allaHintShown or allaHintShown
    ux.bundledSeedAutoImported = data.bundledSeedAutoImported == true
    if type(data.useBundledSeedTimers) == 'boolean' then
        ux.useBundledSeedTimers = data.useBundledSeedTimers
    else
        ux.useBundledSeedTimers = nil
    end
    ux.bundledSeedTimerRepairDone = data.bundledSeedTimerRepairDone == true
    ux.bundledSeedTimersMigratedV1 = data.bundledSeedTimersMigratedV1 == true or ux.bundledSeedTimersMigratedV1 == true
    ux.bundledSeedGeneratedAt = tostring(data.bundledSeedGeneratedAt or '')
    if data.seedAutoMaintainMigratedV1 == true then
        ux.seedAutoMaintain = data.seedAutoMaintain == true
    else
        ux.seedAutoMaintain = data.seedAutoMaintain == true
        ux.seedAutoMaintainMigratedV1 = true
    end
end

saveSettings = function()
    atomicWrite(settingsPath, serializeAsModule(buildSettingsTable()))
end

ux.applyPerformanceMode = function()
    refreshFullMs = 1500
    refreshCompactMs = 5000

    scanMaxResults = 300
    maxResults = 100

    ux.liveSearch = false
    ux.inputsLocked = true
    ux.watchCurrentZoneOnly = true
    ux.namedOrPHOnly = true
    ux.useBulkSpawnScan = true

    ux.watchRowsCacheMs = 1500
    ux.zoneIntelCacheMs = 7000
    ux.searchRefreshMs = 15000
    ux.searchStableWatchRefreshMs = 5000
    ux.settingsRefreshMs = 12000
    ux.watchesRefreshMs = 10000
    ux.watchPopupRefreshMs = 12000
    ux.watchUiRefreshMs = 12000
    ux.watchPopupMaxDrawRows = 16
    ux.watchPopupCompanionMaxDrawRows = 8

    ux.deferWatchRespawnSaves = true
    ux.deferWatchUiRefresh = true
    ux.autoPauseSafeZones = true

    saveSettings()
    chat('\\agTurboMobs:\\ax Optimized Settings restored. Search/UI refresh reduced; watch timers and PH/named learning remain active.')
end
ux.applyWindowGeometry = function(key, defaultW, defaultH, cond)
    ux.windowGeom = ux.windowGeom or {}
    local g = ux.windowGeom[key]
    if type(g) == 'table' and tonumber(g.x) and tonumber(g.y) then
        pcall(function() ImGui.SetNextWindowPos(tonumber(g.x), tonumber(g.y), ImGuiCond.FirstUseEver) end)
    end
    if type(g) == 'table' and tonumber(g.w) and tonumber(g.h) then
        pcall(function() ImGui.SetNextWindowSize(tonumber(g.w), tonumber(g.h), ImGuiCond.FirstUseEver) end)
    elseif defaultW and defaultH then
        ImGui.SetNextWindowSize(defaultW, defaultH, cond or ImGuiCond.FirstUseEver)
    end
end

ux.captureWindowGeometry = function(key)
    if not ImGui.GetWindowPos or not ImGui.GetWindowSize then return end
    if ImGui.IsWindowCollapsed and ImGui.IsWindowCollapsed() then return end
    local pos, posY = ImGui.GetWindowPos()
    local size, sizeY = ImGui.GetWindowSize()
    local x = type(pos) == 'table' and tonumber(pos.x or pos.X or pos[1]) or tonumber(pos)
    local y = type(pos) == 'table' and tonumber(pos.y or pos.Y or pos[2]) or tonumber(posY)
    local w = type(size) == 'table' and tonumber(size.x or size.X or size[1]) or tonumber(size)
    local h = type(size) == 'table' and tonumber(size.y or size.Y or size[2]) or tonumber(sizeY)
    if not x or not y or not w or not h then return end
    ux.windowGeom = ux.windowGeom or {}
    local prev = ux.windowGeom[key] or {}
    x, y, w, h = math.floor(x + 0.5), math.floor(y + 0.5), math.floor(w + 0.5), math.floor(h + 0.5)
    if prev.x == x and prev.y == y and prev.w == w and prev.h == h then return end
    ux.windowGeom[key] = { x = x, y = y, w = w, h = h }
    ux.geomSaveAt = ux.geomSaveAt or {}
    local nowValue = nowMs()
    if (nowValue - (ux.geomSaveAt[key] or 0)) < 1000 then return end
    ux.geomSaveAt[key] = nowValue
    saveSettings()
end

ux.requestShutdown = function()
    running = false
    showWindow = false
    ux.showAlertPopup = false
    -- Do NOT call mq.imgui.destroy here — this may be called from inside a draw
    -- callback. The while-running loop exits on the next tick and the cleanup
    -- block at the bottom of the script tears down ImGui cleanly from outside.
end

ux.stopNow = function()
    chat('\\agTurboMobs:\\ax unloading. Run \\ay/lua run TurboMobs\\ax again after this closes.')
    if not ux.stopCommandQueued then
        ux.stopCommandQueued = true
        pcall(function() mq.cmd('/timed 2 /lua stop TurboMobs') end)
    end
    ux.requestShutdown()
end

ux.hideFullWindow = function()
    showWindow = false
    compactMode = false
    saveSettings()
end

ux.hideWatchWindow = function()
    ux.showAlertPopup = false
    ux.alertPopupClosedAt = os.time()
    saveSettings()
end

ux.showWatchWindow = function()
    running = true
    enabled = true
    ux.showAlertPopup = true
    ux.alertPopupClosedAt = 0
    compactMode = false
    saveSettings()
end

ux.toggleWatchWindow = function()
    if ux.showAlertPopup then
        ux.hideWatchWindow()
    else
        ux.showWatchWindow()
    end
end

ux.toggleFullMainWindow = function()
    if showWindow and not compactMode then
        showWindow = false
    else
        running = true
        enabled = true
        showWindow = true
        compactMode = false
        ux.showMore = false
        lastRefreshMs = nowMs()
    end
    saveSettings()
end

--- Hide the full TurboMobs window and show the slim Turbo Watch pop-out.
ux.minimizeToWatchWindow = function()
    running = true
    enabled = true
    showWindow = false
    compactMode = false
    ux.showWatchWindow()
    ux.refreshWatchesNow({ suppressAlerts = true })
end

ux.showFullWindow = function()
    running = true
    enabled = true
    showWindow = true
    compactMode = false
    ux.showMore = false
    lastRefreshMs = nowMs()
    ux.refreshWatchesNow({ suppressAlerts = true })
    saveSettings()
end

ux.openFullWatchTab = function()
    ux.showFullWindow()
    ux.activeFullTab = 'watches'
end

ux.showBothWindows = function()
    running = true
    enabled = true
    ux.showWatchWindow()
    ux.showFullWindow()
end

ux.restorePrimaryWindow = function()
    ux.showBothWindows()
end

ux.toggleCompactMainWindow = function()
    ux.toggleWatchWindow()
end

local function loadSettings()
    local loaded = false
    if pathExists(settingsPath) then
        local ok, data = pcall(dofile, settingsPath)
        if ok and type(data) == 'table' then
            applySettingsTable(data)
            loaded = true
        end
    end
    if not loaded and pathExists(legacySettingsPath) then
        local ok, data = pcall(dofile, legacySettingsPath)
        if ok and type(data) == 'table' then
            applySettingsTable(data)
            chat('Migrated settings from legacy location.')
            loaded = true
        end
    end
    if not loaded then
        -- Fresh install: the new bulk-on default is already in effect; mark it
        -- migrated so the one-time notice never fires for new users.
        ux.bulkScanMigratedV1 = true
    elseif ux.bulkScanJustMigrated then
        ux.bulkScanJustMigrated = nil
        chat('\\agTurboMobs:\\ax enabled fast bulk spawn scan (one-time speed-up for this install).')
        saveSettings()
    elseif ux.liveSearchJustMigrated then
        ux.liveSearchJustMigrated = nil
        chat('\\agTurboMobs:\\ax switched Search to Lock mode (Live Search OFF) for better performance. Watches still update in the background. Turn Live Search on under Search if you need auto-refreshing spawn rows.')
        saveSettings()
    elseif ux.watchZoneViewJustMigrated then
        ux.watchZoneViewJustMigrated = nil
        chat('\\agTurboMobs:\\ax Turbo Watch now shows current-zone watches only (All Zones removed for performance). Browse other zones under Watches or Zone Intel.')
        saveSettings()
    elseif ux.zoneIntelFilterJustMigrated then
        ux.zoneIntelFilterJustMigrated = nil
        chat('\\agTurboMobs:\\ax Zone Intel now defaults to Named+PH (not All). Use All only when you need every learned spawn point; Clean Raw removes generic trash timers.')
        saveSettings()
    elseif ux.zoneIntelCampsDefaultJustMigrated then
        ux.zoneIntelCampsDefaultJustMigrated = nil
        chat('\\agTurboMobs:\\ax Zone Intel now defaults to Camps. Use PH Points or All Points only when inspecting spawn-point detail.')
        saveSettings()
    elseif ux.watchModeLeanMigrated then
        ux.watchModeLeanMigrated = nil
        chat('\\agTurboMobs:\\ax Turbo Watch is now Ultra Slim only. Use ... > Watch Target to add your current target, ... > Full Watches for the table, or + for the main window.')
        saveSettings()
    end
end

-- ============================================================
-- Respawn data
-- ============================================================

local function loadRespawns()
    if not pathExists(respawnsPath) then return true end
    local ok, data = pcall(dofile, respawnsPath)
    if not ok or type(data) ~= 'table' then
        chat('WARNING: respawns.lua failed to load. Starting fresh (existing file untouched).')
        if ux.recordRuntimeError then
            ux.recordRuntimeError('loadRespawns', ok and ('invalid data type ' .. type(data)) or data)
        end
        return false
    end
    respawnsData = data
    if type(respawnsData._meta) ~= 'table' then
        respawnsData._meta = { version = DATA_FORMAT_VERSION, server = '', last_updated = '', contributors = {} }
    end
    if ux.rebuildImportedRespawnLookup then ux.rebuildImportedRespawnLookup(currentZoneShort()) end
    return true
end

ux.queueRespawnsPostLoad = function()
    if type(ux.respawnsPostLoadQueue) == 'table' and #ux.respawnsPostLoadQueue > 0 then return end
    ux.respawnsPostLoadQueue = { 'reconcile', 'anchor', 'import', 'autoseed', 'zone_refresh' }
end

ux.processRespawnsPostLoad = function()
    local queue = ux.respawnsPostLoadQueue
    if type(queue) ~= 'table' or #queue == 0 then return end
    local step = table.remove(queue, 1)
    if step == 'reconcile' then
        local restored = 0
        local postOk, postErr = pcall(function()
            restored = ux.reconcileWatchTimersFromRespawns and ux.reconcileWatchTimersFromRespawns() or 0
        end)
        if not postOk and ux.recordRuntimeError then ux.recordRuntimeError('respawn reconcile', postErr) end
        if restored > 0 then chat(string.format('TurboMobs: restored %d live respawn timer(s) from saved data.', restored)) end
    elseif step == 'anchor' then
        local anchorFixes = 0
        local anchorOk, anchorErr = pcall(function()
            anchorFixes = ux.repairSeedWatchAnchorDrift and ux.repairSeedWatchAnchorDrift(currentZoneShort()) or 0
        end)
        if not anchorOk and ux.recordRuntimeError then ux.recordRuntimeError('seed anchor repair', anchorErr) end
        if anchorFixes > 0 then chat(string.format('TurboMobs: repaired %d seed watch anchor(s).', anchorFixes)) end
    elseif step == 'import' then
        if ux.maybeAutoImportBundledSeed then
            local autoOk, autoErr = pcall(ux.maybeAutoImportBundledSeed)
            if not autoOk and ux.recordRuntimeError then ux.recordRuntimeError('bundled seed auto-import', autoErr) end
        end
    elseif step == 'autoseed' then
        if ux.autoSeedCurrentZone then
            local seedOk, seedErr = pcall(ux.autoSeedCurrentZone)
            if not seedOk and ux.recordRuntimeError then ux.recordRuntimeError('auto seed', seedErr) end
        end
    elseif step == 'zone_refresh' then
        ux.zoneEntryRefreshPending = true
    end
    if #queue == 0 then ux.respawnsPostLoadQueue = nil end
end

local function finishRespawnsFileLoad(started, ok)
    ux.respawnsLoaded = true
    ux.respawnsLoadStarted = false
    ux.zoneIntelCache = { at = 0, key = '', rows = {} }
    ux.watchRowsCache = { at = 0, key = '', rows = {} }
    ux.watchDetailRowsCache = { at = 0, key = '', rows = {} }
    chat(string.format('Respawn data %s in %dms.', ok and 'loaded' or 'load skipped', nowMs() - started))
    ux.queueRespawnsPostLoad()
end

ux.processInitialRespawnLoad = function()
    if ux.respawnsLoaded or ux.respawnsLoadStarted then return end
    if nowMs() < (tonumber(ux.respawnsLoadAfterMS) or 0) then return end
    if not clientInGame() then return end
    -- Prefer a calm moment to avoid a load hitch, but never defer forever: a
    -- tester who is constantly moving/naving would otherwise never load respawn
    -- data (intel/timers stay empty and periodic saves can't flush). Cap the
    -- wait so the load always happens within a few seconds of being in-game.
    if ux.respawnsLoadHardDeadline == nil then ux.respawnsLoadHardDeadline = nowMs() + 6000 end
    if nowMs() < ux.respawnsLoadHardDeadline
        and ux.gameplayBusyForRespawnSave and ux.gameplayBusyForRespawnSave() then
        ux.respawnsLoadAfterMS = nowMs() + 1500
        return
    end

    ux.respawnsLoadStarted = true
    chat('Loading respawn data...')
    local started = nowMs()
    local ok = loadRespawns()
    finishRespawnsFileLoad(started, ok)
end

ux.ensureRespawnsLoaded = function(reason)
    if ux.respawnsLoaded then return true end
    if ux.respawnsLoadStarted then return false end
    ux.respawnsLoadStarted = true
    chat('Loading respawn data' .. (reason and reason ~= '' and (' for ' .. tostring(reason)) or '') .. '...')
    local started = nowMs()
    local ok = loadRespawns()
    finishRespawnsFileLoad(started, ok)
    return ok
end

saveRespawns = function(force)
    if not ux.respawnsLoaded and pathExists(respawnsPath) then
        -- Routine (periodic) saves are queued off the UI refresh path; if the
        -- initial load is still pending, only warn on an explicit forced save.
        if force then
            local nowSec = os.time()
            if (nowSec - (tonumber(ux.lastRespawnSkipWarnAt) or 0)) >= 15 then
                ux.lastRespawnSkipWarnAt = nowSec
                chat('Respawn save skipped: data has not loaded yet.')
            end
        end
        return false, 0, 0
    end
    if not respawnsDirty and not force then return false, 0, 0 end
    respawnsData._meta = respawnsData._meta or {}
    respawnsData._meta.version = DATA_FORMAT_VERSION
    respawnsData._meta.last_updated = dateStamp()
    if (respawnsData._meta.server == nil or respawnsData._meta.server == '') and currentServer() ~= '' then
        respawnsData._meta.server = currentServer()
    end
    respawnsData._meta.contributors = respawnsData._meta.contributors or {}
    local me = currentCharacter()
    if me ~= '' then
        local found = false
        for _, c in ipairs(respawnsData._meta.contributors) do
            if c == me then found = true; break end
        end
        if not found then table.insert(respawnsData._meta.contributors, me) end
    end

    local tWrite = nowMs()
    local payload = serializeAsModule(respawnsData)
    local byteSize = #payload
    local ok = atomicWrite(respawnsPath, payload)
    local elapsed = nowMs() - tWrite
    if ok then
        respawnsDirty = false
        lastRespawnsSaveAt = os.time()
        ux.lastRespawnsSaveDeferredAt = 0
        ux.pendingRespawnSave = false
    end
    return ok and true or false, elapsed, byteSize
end

ux.gameplayBusyForRespawnSave = function()
    if ux.safeZoneScanPaused() then return false end
    if not enabled then return false end

    local combatState = tostring(safeCall(function() return mq.TLO.Me.CombatState() end, '') or ''):lower()
    if combatState ~= '' and combatState ~= 'out of combat' and combatState ~= 'combat' then return true end
    if safeCall(function() return mq.TLO.Me.Combat() end, false) then return true end
    if safeCall(function() return mq.TLO.Me.Moving() end, false) then return true end
    if safeCall(function() return mq.TLO.Me.Casting.ID() end, 0) ~= 0 then return true end
    if safeCall(function() return mq.TLO.Navigation.Active() end, false) then return true end
    return false
end

ux.gameplayBusyForImport = function()
    if not clientInGame() then return true end
    if safeCall(function() return mq.TLO.Me.Moving() end, false) then return true end
    if safeCall(function() return mq.TLO.Me.Casting.ID() end, 0) ~= 0 then return true end
    return false
end

ux.deferRespawnSaveForWatch = function(overdue)
    if overdue then return false end
    if not ux.deferWatchRespawnSaves then return false end
    if ux.showAlertPopup or showWindow then return true end

    -- Turbo Watch / full UI are commonly left open while moving. Avoid
    -- respawn-data serialization hitches during active play; shutdown and
    -- overdue saves still flush (processed off the ImGui draw path).
    return true
end

ux.respawnSaveIsOverdue = function(now)
    now = tonumber(now) or os.time()
    local forceAfter = tonumber(ux.respawnSaveForceAfterSec) or 1800
    local deferredAt = tonumber(ux.lastRespawnsSaveDeferredAt) or 0
    return (deferredAt > 0 and (now - deferredAt) >= forceAfter)
        or (lastRespawnsSaveAt > 0 and (now - lastRespawnsSaveAt) >= forceAfter)
end

ux.recordRespawnSavePerf = function(elapsedMs, byteSize, reason)
    elapsedMs = tonumber(elapsedMs) or 0
    byteSize = tonumber(byteSize) or 0
    if elapsedMs <= 0 then return end
    ux.lastRespawnSaveMs = elapsedMs
    local kb = math.floor(byteSize / 1024)
    local line = string.format(
        'RespawnSave total=%dms bytes=%d kb=%d reason=%s fullOpen=%s watchOpen=%s',
        elapsedMs, byteSize, kb, tostring(reason or 'periodic'),
        tostring(showWindow == true), tostring(ux.showAlertPopup == true))
    ux.recordPerfLine(line)
    ux.recordSlowPerf('respawnSave', line, elapsedMs, 50, 1000)
end

-- Queue a disk flush after refresh; actual write runs in the main loop.
ux.queueRespawnSaveWhenSafe = function()
    if not ux.respawnsLoaded then return end
    if not respawnsDirty then return end
    local now = os.time()
    if (now - lastRespawnsSaveAt) < RESPAWNS_SAVE_INTERVAL_SEC then return end
    ux.pendingRespawnSave = true
end

ux.processPendingRespawnSave = function()
    if not ux.pendingRespawnSave then return end
    if not clientInGame() then return end
    if not ux.respawnsLoaded then return end
    if not respawnsDirty then
        ux.pendingRespawnSave = false
        return
    end
    local now = os.time()
    if (now - lastRespawnsSaveAt) < RESPAWNS_SAVE_INTERVAL_SEC then return end

    local overdue = ux.respawnSaveIsOverdue(now)
    local dueWatchActive = ux.anyCurrentZoneWatchDue and ux.anyCurrentZoneWatchDue() or false
    local watchRefreshDue = enabled and lastWatchRefreshMs > 0
        and (nowMs() - lastWatchRefreshMs) >= math.max(1500, tonumber(ux.dueWatchRefreshMs) or 1500)
    if dueWatchActive or watchRefreshDue then
        if (tonumber(ux.lastRespawnsSaveDeferredAt) or 0) <= 0 then ux.lastRespawnsSaveDeferredAt = now end
        return
    end
    if ux.deferRespawnSaveForWatch(overdue) then
        if (tonumber(ux.lastRespawnsSaveDeferredAt) or 0) <= 0 then ux.lastRespawnsSaveDeferredAt = now end
        return
    end
    if ux.gameplayBusyForRespawnSave() and not overdue then
        if (tonumber(ux.lastRespawnsSaveDeferredAt) or 0) <= 0 then ux.lastRespawnsSaveDeferredAt = now end
        return
    end

    local ok, elapsed, bytes = saveRespawns(false)
    if ok then
        ux.recordRespawnSavePerf(elapsed, bytes, overdue and 'overdue' or 'periodic')
    elseif not respawnsDirty then
        ux.pendingRespawnSave = false
    end
end

ux.saveRespawnsWhenSafe = function(force)
    if force then
        local ok, elapsed, bytes = saveRespawns(true)
        if ok and elapsed > 0 then ux.recordRespawnSavePerf(elapsed, bytes, 'forced') end
        return
    end
    ux.queueRespawnSaveWhenSafe()
end

-- ============================================================
-- Watches persistence (config in watches.lua, live timers in watch_runtime.lua)
-- ============================================================

ux.WATCH_RUNTIME_FIELDS = {
    'despawnedAt', 'expectedRespawnAt', 'expectedRespawnSource', 'killedAtText',
    'lastOccupiedAt', 'lastOccupantName', 'lastOccupantId', 'lastConfirmedKillAt',
    'occupantSpawnId', 'occupantName', 'currentName', 'pointOccupied', 'occupantConfirmedAtAnchor',
    'offAnchorOccupantId', 'offAnchorOccupantName',
    'roamingPhSpawnId', 'roamingPhName', 'roamingPhConfirmedAt',
    'trackingMode', 'lastTimerBlockedReason', 'lastStaleOccupantText',
    'lastAlertAttemptText', 'lastAlertDeliveredText', 'lastAlertSuppressedReason', 'lastAlertAt',
    'lastDeliveredAlertSpawnId', 'lastDeliveredAlertKey',
}

ux.extractWatchRuntimeEntry = function(w)
    if type(w) ~= 'table' then return nil end
    local snap = {}
    local any = false
    for _, field in ipairs(ux.WATCH_RUNTIME_FIELDS) do
        local val = w[field]
        if field == 'pointOccupied' or field == 'occupantConfirmedAtAnchor' then
            if val == true then snap[field] = true; any = true end
        elseif field == 'trackingMode' or field == 'expectedRespawnSource' or field == 'killedAtText'
            or field == 'currentName' or field == 'occupantName' or field == 'lastOccupantName'
            or field == 'offAnchorOccupantName' or field == 'roamingPhName'
            or field == 'lastTimerBlockedReason' or field == 'lastStaleOccupantText'
            or field == 'lastAlertAttemptText' or field == 'lastAlertDeliveredText'
            or field == 'lastAlertSuppressedReason' or field == 'lastDeliveredAlertKey' then
            local text = trim(tostring(val or ''))
            if text ~= '' and (field ~= 'trackingMode' or text ~= 'point') then
                snap[field] = text
                any = true
            end
        else
            local n = tonumber(val) or 0
            if n > 0 then snap[field] = n; any = true end
        end
    end
    if not any then return nil end
    return snap
end

ux.applyWatchRuntimeEntry = function(w, snap)
    if type(w) ~= 'table' or type(snap) ~= 'table' then return end
    for _, field in ipairs(ux.WATCH_RUNTIME_FIELDS) do
        if snap[field] ~= nil then w[field] = snap[field] end
    end
end

ux.loadWatchRuntime = function()
    if not pathExists(turboFolder .. '/watch_runtime.lua') then return end
    local ok, data = pcall(dofile, turboFolder .. '/watch_runtime.lua')
    if not ok or type(data) ~= 'table' then return end
    for key, snap in pairs(data) do
        if key ~= '_meta' and type(snap) == 'table' and watchList[key] then
            ux.applyWatchRuntimeEntry(watchList[key], snap)
        end
    end
end

saveWatchRuntime = function(reason)
    local toSave = {
        _meta = {
            version = 1,
            savedAt = os.time(),
            zone = currentZoneShort(),
            character = currentCharacter(),
        },
    }
    local count = 0
    for key, w in pairs(watchList or {}) do
        local snap = ux.extractWatchRuntimeEntry(w)
        if snap then
            toSave[key] = snap
            count = count + 1
        end
    end
    local tWrite = nowMs()
    local payload = serializeAsModule(toSave)
    local byteSize = #payload
    local ok = atomicWrite(turboFolder .. '/watch_runtime.lua', payload)
    local elapsed = nowMs() - tWrite
    if ok then
        ux.pendingWatchRuntimeSave = false
        ux.pendingWatchRuntimeSaveReason = ''
        ux.lastWatchRuntimeSaveAt = os.time()
        ux.lastWatchRuntimeSaveDeferredAt = 0
    end
    if ux.recordPerfLine and elapsed >= 0 then
        ux.lastWatchRuntimeSaveMs = elapsed
        ux.recordPerfLine(string.format(
            'WatchRuntimeSave total=%dms bytes=%d entries=%d reason=%s fullOpen=%s watchOpen=%s',
            elapsed, byteSize, count, tostring(reason or 'direct'),
            tostring(showWindow == true), tostring(ux.showAlertPopup == true)))
    end
    return ok and true or false, elapsed, byteSize
end

ux.saveWatchRuntime = saveWatchRuntime

saveWatches = function(reason)
    local toSave = {}
    for key, w in pairs(watchList) do
        if w.mode ~= 'id' then
            toSave[key] = {
                label = w.label,
                desiredName = w.desiredName,
                mode = w.mode,
                zone = w.zone,
                source = w.source,
                category = w.category,
                trackingMode = w.trackingMode,
                alwaysPing = w.alwaysPing == true,
                phNames = w.phNames,
                seedPhNames = w.seedPhNames,
                areaRadius = w.areaRadius or 0,
                respawnSeconds = w.respawnSeconds or 0,
                lastSpawnPointKey = w.lastSpawnPointKey,
                pointConfidence = w.pointConfidence,
                pointSamples = w.pointSamples or 0,
                lastX = w.lastX,
                lastY = w.lastY,
                lastZ = w.lastZ,
            }
        end
    end
    local tWrite = nowMs()
    local payload = serializeAsModule(toSave)
    local byteSize = #payload
    local ok = atomicWrite(watchesPath, payload)
    local elapsed = nowMs() - tWrite
    if ok then
        ux.pendingWatchSave = false
        ux.pendingWatchSaveReason = ''
        ux.lastWatchSaveAt = os.time()
        ux.lastWatchSaveDeferredAt = 0
    end
    if ux.recordPerfLine and elapsed > 0 then
        local kb = math.floor(byteSize / 1024)
        ux.lastWatchSaveMs = elapsed
        ux.recordPerfLine(string.format(
            'WatchSave total=%dms bytes=%d kb=%d reason=%s fullOpen=%s watchOpen=%s',
            elapsed, byteSize, kb, tostring(reason or 'direct'),
            tostring(showWindow == true), tostring(ux.showAlertPopup == true)))
    end
    ux.watchRowsCache = { at = 0, key = '', rows = {} }
    ux.watchDetailRowsCache = { at = 0, key = '', rows = {} }
    return ok and true or false, elapsed, byteSize
end

ux.saveWatches = saveWatches

ux.queueWatchSaveWhenSafe = function(reason)
    ux.pendingWatchRuntimeSave = true
    if tostring(reason or '') ~= '' then ux.pendingWatchRuntimeSaveReason = tostring(reason) end
    if (tonumber(ux.lastWatchRuntimeSaveDeferredAt) or 0) <= 0 then
        ux.lastWatchRuntimeSaveDeferredAt = os.time()
    end
end

ux.queueWatchConfigSave = function(reason)
    ux.pendingWatchSave = true
    if tostring(reason or '') ~= '' then ux.pendingWatchSaveReason = tostring(reason) end
    if (tonumber(ux.lastWatchSaveDeferredAt) or 0) <= 0 then
        ux.lastWatchSaveDeferredAt = os.time()
    end
end

ux.watchRuntimeSaveIsOverdue = function(now)
    now = tonumber(now) or os.time()
    local deferredAt = tonumber(ux.lastWatchRuntimeSaveDeferredAt) or 0
    return deferredAt > 0 and (now - deferredAt) >= (tonumber(ux.watchRuntimeSaveForceAfterSec) or 45)
end

ux.watchSaveIsOverdue = function(now)
    now = tonumber(now) or os.time()
    local deferredAt = tonumber(ux.lastWatchSaveDeferredAt) or 0
    return deferredAt > 0 and (now - deferredAt) >= (tonumber(ux.watchSaveForceAfterSec) or 1800)
end

ux.processPendingWatchRuntimeSave = function()
    if not ux.pendingWatchRuntimeSave then return end
    if not clientInGame() then return end
    local now = os.time()
    local overdue = ux.watchRuntimeSaveIsOverdue and ux.watchRuntimeSaveIsOverdue(now) or false
    if (tonumber(ux.spawnRefreshInProgress) or 0) > 0 then return end
    if ux.recentWatchTargetActive and ux.recentWatchTargetActive(7000) and not overdue then return end
    if ux.gameplayBusyForRespawnSave and ux.gameplayBusyForRespawnSave() and not overdue then return end
    saveWatchRuntime(overdue and 'deferred-overdue' or (ux.pendingWatchRuntimeSaveReason ~= '' and ux.pendingWatchRuntimeSaveReason or 'deferred'))
end

ux.processPendingWatchSave = function()
    if not ux.pendingWatchSave then return end
    if not clientInGame() then return end
    local now = os.time()
    local overdue = ux.watchSaveIsOverdue and ux.watchSaveIsOverdue(now) or false
    if (tonumber(ux.spawnRefreshInProgress) or 0) > 0 then return end
    if ux.showAlertPopup or showWindow then return end
    if ux.gameplayBusyForRespawnSave and ux.gameplayBusyForRespawnSave() and not overdue then return end
    saveWatches(overdue and 'deferred-overdue' or (ux.pendingWatchSaveReason ~= '' and ux.pendingWatchSaveReason or 'deferred'))
end

local function loadWatches()
    if not pathExists(watchesPath) then return end
    local ok, data = pcall(dofile, watchesPath)
    if not ok or type(data) ~= 'table' then return end
    for key, w in pairs(data) do
        local loadedMode = w.mode or 'exact'
        if loadedMode == 'exact' and w.lastSpawnPointKey then loadedMode = 'smart' end
        watchList[key] = {
            label = w.label or key,
            desiredName = w.desiredName or tostring(w.label or key):lower(),
            mode = loadedMode,
            zone = w.zone,
            source = w.source,
            category = w.category,
            trackingMode = w.trackingMode,
            alwaysPing = w.alwaysPing == true,
            phNames = type(w.phNames) == 'table' and w.phNames or {},
            seedPhNames = type(w.seedPhNames) == 'table' and w.seedPhNames or nil,
            areaRadius = tonumber(w.areaRadius) or 0,
            spawnId = 0,
            respawnSeconds = tonumber(w.respawnSeconds) or 0,
            isUp = false,
            lastSeenAt = 0,
            initialResolved = false,
            lastSpawnPointKey = w.lastSpawnPointKey,
            pointConfidence = w.pointConfidence or ((w.source == 'Zone Intel' or w.source == 'SpawnMaster') and 'trusted' or 'learning'),
            pointSamples = tonumber(w.pointSamples) or 0,
            lastX = tonumber(w.lastX) or 0,
            lastY = tonumber(w.lastY) or 0,
            lastZ = tonumber(w.lastZ) or 0,
            lastSpawnId = 0,
        }
        -- Legacy watches.lua may still carry timer fields from older builds.
        ux.applyWatchRuntimeEntry(watchList[key], w)
    end
    ux.loadWatchRuntime()
end

-- ============================================================
-- Learned respawn helpers
-- ============================================================

local function getZoneRespawns(zone, createIfMissing)
    zone = tostring(zone or currentZoneShort()):lower()
    if not respawnsData[zone] and createIfMissing then
        respawnsData[zone] = {}
    end
    return respawnsData[zone]
end

ux.getZoneRespawns = getZoneRespawns

-- Delegated to turbomobs_logic (pure, tested).
local roundedCoord = TM.roundedCoord
local spawnPointKey = TM.spawnPointKey

ux.spawnPointKey = spawnPointKey

ux.pointKeyFromCoords = TM.pointKeyFromCoords

ux.rowDistanceFromLoc = TM.rowDistanceFromLoc

ux.rowWithinLoc = function(row, x, y, radius)
    local dist = ux.rowDistanceFromLoc(row, x, y)
    return dist ~= nil and dist <= (tonumber(radius) or ux.defaultPointOccupantRadius)
end

ux.watchAnchorRadius = function(watch)
    local mode = ux.watchTrackingMode and ux.watchTrackingMode(watch) or tostring(watch and watch.trackingMode or ''):lower()
    if mode == 'area' then
        local r = tonumber(watch and watch.areaRadius) or 0
        return r > 0 and r or ux.defaultPointOccupantRadius
    end
    -- anchorRadius=0 means "use default"; treat nil/0 as unset.
    local r = tonumber(watch and watch.anchorRadius) or 0
    return r > 0 and r or ux.defaultPointOccupantRadius
end

ux.rowWithinWatchAnchor = function(watch, row)
    if not watch or not row then return false end
    return ux.rowWithinLoc(row, watch.lastX, watch.lastY, ux.watchAnchorRadius(watch))
end

local function getPointTable(zoneTable, createIfMissing)
    if type(zoneTable) ~= 'table' then return nil end
    if type(zoneTable._points) ~= 'table' and createIfMissing then
        zoneTable._points = {}
    end
    return zoneTable._points
end

local function touchNameList(entry, name)
    name = trim(tostring(name or ''))
    if name == '' then return end
    entry.names = entry.names or {}
    for _, existing in ipairs(entry.names) do
        if tostring(existing):lower() == name:lower() then return end
    end
    table.insert(entry.names, name)
    while #entry.names > 12 do table.remove(entry.names, 1) end
end

local function appendUniqueText(list, value, maxItems)
    if type(list) ~= 'table' then list = {} end
    local clean = trim(tostring(value or ''))
    if clean == '' then return list, false end
    local key = clean:lower()
    for _, existing in ipairs(list) do
        if tostring(existing or ''):lower() == key then return list, false end
    end
    table.insert(list, clean)
    while maxItems and maxItems > 0 and #list > maxItems do table.remove(list, 1) end
    return list, true
end

local function ensurePointEntry(zoneTable, row, name)
    local key = spawnPointKey(row)
    if not key then return nil, nil end
    local points = getPointTable(zoneTable, true)
    if not points or not row then return nil, nil end
    local rowName = name or row.name or key
    points[key] = points[key] or {
        display_name = rowName,
        last_seen_name = rowName,
        samples = {},
        names = {},
        last_death = 0,
        last_seen = 0,
        first_seen = os.time(),
        x = roundedCoord(row.x),
        y = roundedCoord(row.y),
        z = roundedCoord(row.z),
        last_spawn_id = tonumber(row.id) or 0,
    }
    local entry = points[key]
    entry.display_name = entry.display_name or rowName
    entry.last_seen_name = rowName
    entry.x, entry.y, entry.z = roundedCoord(row.x), roundedCoord(row.y), roundedCoord(row.z)
    entry.last_spawn_id = tonumber(row.id) or entry.last_spawn_id or 0
    entry.last_seen = os.time()
    entry.level = tonumber(row.level) or entry.level or 0
    entry.type = row.type or entry.type
    entry.body = row.body or entry.body
    entry.race = row.race or entry.race
    entry.class = row.class or entry.class
    touchNameList(entry, rowName)
    return entry, key
end

ux.ensurePointEntry = ensurePointEntry

local function appendSample(entry, seconds)
    if not entry or not seconds or seconds <= 0 then return false end
    table.insert(entry.samples, math.floor(seconds))
    while #entry.samples > MAX_SAMPLES_PER_MOB do
        table.remove(entry.samples, 1)
    end
    return true
end

local function recordObservation(name, seconds, row)
    if not name or not seconds or seconds <= 0 then return end
    if seconds < ux.minRespawnSampleSeconds then return end
    if seconds > 4 * 3600 then return end

    local zone = currentZoneShort()
    local zoneTable = getZoneRespawns(zone, true)
    local key = tostring(name):lower()
    zoneTable[key] = zoneTable[key] or {
        display_name = name,
        samples = {},
        last_death = 0,
        first_seen = os.time(),
    }
    local entry = zoneTable[key]
    entry.display_name = entry.display_name or name
    appendSample(entry, seconds)
    if row then
        local pointEntry = ensurePointEntry(zoneTable, row, name)
        appendSample(pointEntry, seconds)
    end
    respawnsDirty = true; ux.statsRevision = (ux.statsRevision or 0) + 1
end

ux.recordObservation = recordObservation

local function recordDeath(name, row)
    if not name then return end
    local zone = currentZoneShort()
    local zoneTable = getZoneRespawns(zone, true)
    local key = tostring(name):lower()
    zoneTable[key] = zoneTable[key] or {
        display_name = name,
        samples = {},
        last_death = 0,
        first_seen = os.time(),
    }
    zoneTable[key].last_death = os.time()
    if row then
        local pointEntry = ensurePointEntry(zoneTable, row, name)
        if pointEntry then pointEntry.last_death = os.time() end
    end
    respawnsDirty = true; ux.statsRevision = (ux.statsRevision or 0) + 1
end

local function statsFromEntry(entry)
    if not entry or not entry.samples or #entry.samples == 0 then return nil end
    local samples = entry.samples
    local sum, lo, hi = 0, math.huge, -math.huge
    for _, v in ipairs(samples) do
        sum = sum + v
        if v < lo then lo = v end
        if v > hi then hi = v end
    end
    local avg = sum / #samples
    local variance = 0
    if #samples > 1 then
        for _, v in ipairs(samples) do variance = variance + (v - avg) ^ 2 end
        variance = variance / (#samples - 1)
    end
    return {
        avg = avg,
        stddev = math.sqrt(variance),
        n = #samples,
        lo = lo,
        hi = hi,
        last_death = entry.last_death or 0,
        display_name = entry.display_name or entry.last_seen_name,
    }
end

local function statsForMob(name, zone, pointKey)
    zone = zone or currentZoneShort()
    -- Memo: statsForMob is called 2-3x per watch row every draw frame plus per
    -- watch in the refresh passes. Results only change when learned data changes
    -- (ux.statsRevision), so cache per revision. Stored on ux (not as locals) to
    -- stay under LuaJIT's 200 main-chunk local limit. Clearing on revision change
    -- keeps it bounded and guarantees identical values to the uncached path.
    local rev = ux.statsRevision or 0
    if ux.statsMemoRev ~= rev then
        ux.statsMemo = {}
        ux.statsMemoRev = rev
    end
    local memo = ux.statsMemo
    local memoKey = zone .. '\0' .. tostring(name or '') .. '\0' .. tostring(pointKey or '')
    local memoed = memo[memoKey]
    if memoed ~= nil then
        if memoed == false then return nil end
        return memoed
    end

    local result = nil
    local zoneTable = respawnsData[zone]
    if zoneTable then
        if pointKey and type(zoneTable._points) == 'table' then
            result = statsFromEntry(zoneTable._points[pointKey])
        end
        if result == nil then
            result = statsFromEntry(zoneTable[tostring(name):lower()])
        end
    end

    memo[memoKey] = (result == nil) and false or result
    return result
end

local function learnedEtaText(name, pointKey)
    local s = statsForMob(name, nil, pointKey)
    if not s or s.n == 0 then return nil end
    if s.n < MIN_SAMPLES_FOR_DISPLAY then
        return string.format('learning... (n=%d)', s.n)
    end
    return string.format('observed: %s (+/-%ds, n=%d)', formatSeconds(s.avg), math.floor(s.stddev), s.n)
end

local function learnedEtaSeconds(name, pointKey)
    local s = statsForMob(name, nil, pointKey)
    if not s or s.n <= 0 then return nil end
    if s.n < MIN_SAMPLES_FOR_DISPLAY then
        return s.avg, string.format('observed %d/%d', tonumber(s.n) or 0, MIN_SAMPLES_FOR_DISPLAY)
    end
    return s.avg, 'learned'
end

-- ============================================================
-- Styling helpers
-- ============================================================

local function styledButton(label, colorKey, padX, padY, tooltip, buttonW, buttonH)
    local pushedColors = 0
    local c = buttonColors[colorKey or 'neutral']

    ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 5)
    ImGui.PushStyleVar(ImGuiStyleVar.FramePadding, padX or 8, padY or 4)

    if c then
        ImGui.PushStyleColor(ImGuiCol.Button, c[1], c[2], c[3], c[4])
        ImGui.PushStyleColor(ImGuiCol.ButtonHovered, c[5], c[6], c[7], c[8])
        ImGui.PushStyleColor(ImGuiCol.ButtonActive, c[9], c[10], c[11], c[12])
        pushedColors = 3
    end

    local clicked
    if buttonW and buttonH then
        clicked = ImGui.Button(label, buttonW, buttonH)
    else
        clicked = ImGui.Button(label)
    end

    if tooltip and tooltip ~= '' and ImGui.IsItemHovered() then
        ImGui.SetTooltip(tooltip)
    end

    if pushedColors > 0 then ImGui.PopStyleColor(pushedColors) end
    ImGui.PopStyleVar(2)
    return clicked
end

local function pushActiveTabStyle()
    local pushed = 0
    if ImGuiCol.Tab then
        ImGui.PushStyleColor(ImGuiCol.Tab, 0.16, 0.27, 0.43, 1.00)
        pushed = pushed + 1
    end
    if ImGuiCol.TabHovered then
        ImGui.PushStyleColor(ImGuiCol.TabHovered, 0.24, 0.40, 0.62, 1.00)
        pushed = pushed + 1
    end
    if ImGuiCol.TabActive then
        ImGui.PushStyleColor(ImGuiCol.TabActive, 0.22, 0.42, 0.27, 1.00)
        pushed = pushed + 1
    end
    if ImGuiCol.TabSelected then
        ImGui.PushStyleColor(ImGuiCol.TabSelected, 0.22, 0.42, 0.27, 1.00)
        pushed = pushed + 1
    end
    return pushed
end

local function coloredText(text, colorKey)
    local c = textColors[colorKey or 'muted']
    if c then
        ImGui.PushStyleColor(ImGuiCol.Text, c[1], c[2], c[3], c[4])
        ImGui.Text(text)
        ImGui.PopStyleColor()
    else
        ImGui.Text(text)
    end
end

-- Wraps within the current content region width (avoids stretching the window).
local function coloredTextWrapped(text, colorKey)
    local c = textColors[colorKey or 'muted']
    if c then
        ImGui.PushStyleColor(ImGuiCol.Text, c[1], c[2], c[3], c[4])
        ImGui.TextWrapped(text)
        ImGui.PopStyleColor()
    else
        ImGui.TextWrapped(text)
    end
end

local function pushCursorToFarRight(buttonWidth)
    buttonWidth = tonumber(buttonWidth) or 42
    local avail = ImGui.GetContentRegionAvail and ImGui.GetContentRegionAvail() or 0
    local availX = type(avail) == 'table' and tonumber(avail.x or avail[1]) or tonumber(avail) or 0
    if availX > buttonWidth and ImGui.SetCursorPosX and ImGui.GetCursorPosX then
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + availX - buttonWidth)
    end
end

ux.imguiTextWidth = function(text)
    text = tostring(text or '')
    if ImGui.CalcTextSize then
        local w, _ = ImGui.CalcTextSize(text)
        if type(w) == 'table' then return tonumber(w.x or w.X or w[1]) or 0 end
        return tonumber(w) or 0
    end
    return #text * 7
end

ux.contentRegionWidth = function()
    if ImGui.GetWindowContentRegionMin and ImGui.GetWindowContentRegionMax then
        local cmin = ImGui.GetWindowContentRegionMin()
        local cmax = ImGui.GetWindowContentRegionMax()
        local minX = type(cmin) == 'table' and tonumber(cmin.x or cmin.X or cmin[1]) or tonumber(cmin) or 0
        local maxX = type(cmax) == 'table' and tonumber(cmax.x or cmax.X or cmax[1]) or tonumber(cmax) or minX
        if maxX > minX then return maxX - minX end
    end
    local avail = ImGui.GetContentRegionAvail and ImGui.GetContentRegionAvail() or 0
    return type(avail) == 'table' and tonumber(avail.x or avail.X or avail[1]) or tonumber(avail) or 0
end

ux.navigationActive = function()
    return safeCall(function() return mq.TLO.Navigation.Active() end, false) == true
end

ux.dragCurrentWindow = function()
    if not ImGui.IsMouseDragging or not ImGui.GetMouseDragDelta or not ImGui.SetWindowPos then return end
    if not ImGui.IsMouseDragging(0, 0.0) then return end
    local delta = ImGui.GetMouseDragDelta(0)
    local dx = type(delta) == 'table' and tonumber(delta.x or delta.X or delta[1]) or tonumber(delta) or 0
    local dy = type(delta) == 'table' and tonumber(delta.y or delta.Y or delta[2]) or 0
    if dx == 0 and dy == 0 then return end
    local px, py = ImGui.GetWindowPos()
    px, py = tonumber(px) or 0, tonumber(py) or 0
    ImGui.SetWindowPos(px + dx, py + dy)
    if ImGui.ResetMouseDragDelta then ImGui.ResetMouseDragDelta(0) end
end

ux.chromeDragState = {
    excludes = {},
    band = nil,
    grabbing = false,
    lastX = nil,
    lastY = nil,
}
-- Separate state for the mini watch popup so it doesn't share state with the main window.
ux.chromeDragStateWatch = {
    excludes = {},
    band = nil,
    grabbing = false,
    lastX = nil,
    lastY = nil,
}

ux.vec2XY = function(v, y)
    if type(v) == 'table' then
        return tonumber(v.x or v.X or v[1]) or 0, tonumber(v.y or v.Y or v[2]) or 0
    end
    return tonumber(v) or 0, tonumber(y) or 0
end

ux.chromeDragCanHandle = function()
    return ImGui.GetMousePos and ImGui.GetWindowPos and ImGui.GetWindowSize
        and ImGui.GetCursorScreenPos and ImGui.GetItemRectMin and ImGui.GetItemRectMax
        and ImGui.SetWindowPos and ImGui.IsMouseClicked and ImGui.IsMouseDown
end

ux.chromeMousePos = function()
    if not ImGui.GetMousePos then return nil, nil end
    local x, y = ImGui.GetMousePos()
    return ux.vec2XY(x, y)
end

ux.chromeWindowRect = function()
    if not (ImGui.GetWindowPos and ImGui.GetWindowSize) then return nil end
    local x, y = ux.vec2XY(ImGui.GetWindowPos())
    local w, h = ux.vec2XY(ImGui.GetWindowSize())
    return { x1 = x, y1 = y, x2 = x + w, y2 = y + h }
end

ux.chromeCursorScreenY = function()
    if not ImGui.GetCursorScreenPos then return nil end
    local _, y = ux.vec2XY(ImGui.GetCursorScreenPos())
    return y
end

ux.chromeItemRect = function()
    if not (ImGui.GetItemRectMin and ImGui.GetItemRectMax) then return nil end
    local minX, minY = ImGui.GetItemRectMin()
    local maxX, maxY = ImGui.GetItemRectMax()
    local x1, y1 = ux.vec2XY(minX, minY)
    local x2, y2 = ux.vec2XY(maxX, maxY)
    return { x1 = x1, y1 = y1, x2 = x2, y2 = y2 }
end

ux.pointInRect = function(x, y, r)
    return r and x >= r.x1 and x <= r.x2 and y >= r.y1 and y <= r.y2
end

ux.chromeDragReset = function(st)
    st = st or ux.chromeDragState
    st.excludes = {}
    st.band = nil
end

ux.chromeDragAddLastItem = function(st)
    st = st or ux.chromeDragState
    local r = ux.chromeItemRect()
    if r then st.excludes[#st.excludes + 1] = r end
end

ux.chromeDragSetBandToCursor = function(st)
    st = st or ux.chromeDragState
    local win = ux.chromeWindowRect()
    local cy = ux.chromeCursorScreenY()
    if not win or not cy then return end
    st.band = {
        x1 = win.x1,
        y1 = win.y1,
        x2 = win.x2,
        y2 = math.max(win.y1 + 48, cy),
    }
end

ux.chromeDragBlocked = function(x, y, st)
    st = st or ux.chromeDragState
    for _, r in ipairs(st.excludes or {}) do
        if ux.pointInRect(x, y, r) then return true end
    end
    return false
end

ux.chromeDragMove = function(x, y, st)
    if not (ImGui.SetWindowPos and x and y) then return end
    st = st or ux.chromeDragState
    if st.lastX and st.lastY then
        local dx = x - st.lastX
        local dy = y - st.lastY
        if dx ~= 0 or dy ~= 0 then
            local wx, wy = ux.vec2XY(ImGui.GetWindowPos())
            ImGui.SetWindowPos(wx + dx, wy + dy)
        end
    end
    st.lastX, st.lastY = x, y
end

ux.chromeDragApplyActive = function(st)
    st = st or ux.chromeDragState
    if not st.grabbing then return end
    if not (ImGui.IsMouseDown and ImGui.IsMouseDown(0)) then
        st.grabbing = false
        st.lastX, st.lastY = nil, nil
        return
    end
    local mx, my = ux.chromeMousePos()
    if not mx or not my then return end
    if ImGui.ClearActiveID then ImGui.ClearActiveID() end
    ux.chromeDragMove(mx, my, st)
end

ux.chromeDragActiveItem = function(st)
    if not (ImGui.IsItemActive and ImGui.IsItemActive()) then return false end
    if not (ImGui.IsMouseDown and ImGui.IsMouseDown(0)) then return false end
    st = st or ux.chromeDragState
    local mx, my = ux.chromeMousePos()
    if not mx or not my then return false end
    if not st.grabbing then
        st.grabbing = true
        st.lastX, st.lastY = mx, my
        if ImGui.ResetMouseDragDelta then ImGui.ResetMouseDragDelta(0) end
    end
    if ImGui.ClearActiveID then ImGui.ClearActiveID() end
    ux.chromeDragMove(mx, my, st)
    return true
end

ux.chromeDragHandle = function(tooltip, st)
    if not ux.chromeDragCanHandle() then return end
    st = st or ux.chromeDragState
    local mx, my = ux.chromeMousePos()
    if not mx or not my or not st.band then return end
    local hovered = not ImGui.IsWindowHovered or ImGui.IsWindowHovered()
    local inBand = ux.pointInRect(mx, my, st.band)
    local blocked = ux.chromeDragBlocked(mx, my, st)
    local down = ImGui.IsMouseDown(0)

    if ImGui.IsMouseClicked(0) then
        if hovered and inBand and not blocked then
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
    elseif hovered and inBand and not blocked and ImGui.SetTooltip then
        ImGui.SetTooltip(tooltip or 'Drag empty header space to move this window.')
    end
end

ux.calcTurboWatchSize = function(rows, opts)
    rows = rows or {}
    opts = opts or {}
    local maxRows = tonumber(opts.maxDrawRows)
        or (opts.companion and tonumber(ux.watchPopupCompanionMaxDrawRows))
        or tonumber(ux.watchPopupMaxDrawRows)
        or 16
    local minRows = opts.companion and 4 or 8
    local drawRows = math.min(#rows, math.max(minRows, maxRows))
    local overflowRows = #rows > drawRows and 1 or 0
    -- Cache result keyed on everything that affects output text. The per-row
    -- ImGui.CalcTextSize calls were the #1 per-frame cost (~75 calls/frame,
    -- ~5-8ms); skip entirely when inputs haven't changed since last call.
    local sizeKey = string.format('%d:%d:%s:%s:%s:%d',
        #rows, tonumber(ux.spawnDataRevision) or 0,
        tostring(maxRows or ''), tostring(ux.watchPopupRowH or ''), opts.companion and 'c' or 'n',
        ux.pendingWatchRow and 1 or 0)
    if ux._watchSizeCache and ux._watchSizeCache.key == sizeKey then
        return ux._watchSizeCache.w, ux._watchSizeCache.h
    end
    local function cacheReturn(w, h)
        ux._watchSizeCache = { key = sizeKey, w = w, h = h }
        return w, h
    end
    local maxNameW = ux.imguiTextWidth('Turbo Mobs')
    local maxStatusW = ux.imguiTextWidth('TBD')
    for i = 1, drawRows do
        local entry = rows[i]
        local label = ux.watchNameText and ux.watchNameText(entry, 34) or tostring(entry.name or entry.label or '')
        maxNameW = math.max(maxNameW, ux.imguiTextWidth(label))
        local status = ux.watchUltraStatus and ux.watchUltraStatus(entry) or ''
        maxStatusW = math.max(maxStatusW, ux.imguiTextWidth(status))
    end
    if overflowRows > 0 then
        maxNameW = math.max(maxNameW, ux.imguiTextWidth(string.format('+%d more', #rows - drawRows)))
    end
    local desiredW = math.max(240, math.min(380, math.floor(maxNameW + maxStatusW + 74)))
    local desiredH = math.max(96, math.min(360, 46 + ((drawRows + overflowRows) * 22)))
    return cacheReturn(desiredW, desiredH)
end

ux.applyTurboWatchAutoSize = function(rows, opts)
    if ux._watchHeaderDragging then
        return tonumber(ux._lastAppliedWatchW) or 300, tonumber(ux._lastAppliedWatchH) or 200
    end
    local desiredW, desiredH = ux.calcTurboWatchSize(rows, opts)
    ImGui.SetNextWindowSizeConstraints(240, 96, 380, 360)
    if desiredW ~= ux._lastAppliedWatchW or desiredH ~= ux._lastAppliedWatchH then
        ux._lastAppliedWatchW = desiredW
        ux._lastAppliedWatchH = desiredH
        ImGui.SetNextWindowSize(desiredW, desiredH, ImGuiCond.Always)
    else
        ImGui.SetNextWindowSize(desiredW, desiredH, ImGuiCond.Appearing)
    end
    return desiredW, desiredH
end

ux.drawTurboWatchChrome = function()
    -- Use separate drag state from the main window so they don't interfere.
    local dSt = ux.chromeDragStateWatch
    ux.chromeDragReset(dSt)
    local barW = ux.contentRegionWidth()
    local titleA = 'Turbo'
    local titleB = ' Mobs'
    local titleW = ux.imguiTextWidth(titleA) + ux.imguiTextWidth(titleB)
    local btnW, btnH = 30, 22
    local x0 = 0
    local y0 = 0
    if ImGui.GetCursorPos then
        local x, y = ImGui.GetCursorPos()
        x0, y0 = tonumber(x) or 0, tonumber(y) or 0
    end

    if styledButton('...##watch_menu_btn', 'menu', 7, 3, 'Watch menu.', btnW, btnH) then
        if ImGui.OpenPopup then ImGui.OpenPopup('##watch_menu_popup') end
    end
    ux.chromeDragAddLastItem(dSt)
    if ImGui.BeginPopup and ImGui.BeginPopup('##watch_menu_popup') then
        if styledButton('Watch Target##watch_menu_watch', 'primary', 7, 3, 'Add your current in-game target to the watch list and keep it on Turbo Watch.') then
            if ux.addWatchFromCurrentTarget then ux.addWatchFromCurrentTarget() end
            if ImGui.CloseCurrentPopup then ImGui.CloseCurrentPopup() end
        end
        if styledButton('Full Watches##watch_menu_full', 'neutral', 7, 3, 'Open the full TurboMobs Watches tab for filters, zone picker, and every saved watch.') then
            ux.openFullWatchTab()
            if ImGui.CloseCurrentPopup then ImGui.CloseCurrentPopup() end
        end
        if styledButton('Stop Nav##watch_menu_nav_stop', 'neutral', 7, 3, 'Stop active MQ navigation without unloading TurboMobs.') then
            ux.stopNav()
        end
        if styledButton('Clear Highlights##watch_menu_hl_reset', 'neutral', 7, 3, 'Remove all /highlight overlays on the map.') then
            mq.cmd('/highlight reset')
        end
        if styledButton('Import Zone##watch_menu_import_zone', 'tools', 7, 3, 'Import bundled Lazarus seed data for the current zone.') then
            ux.requestAllaImport('')
        end
        ImGui.Separator()
        if styledButton('Close Slim##watch_menu_close', 'neutral', 7, 3, 'Close the Turbo Watch slim window. Tracking stays active.') then
            ux.hideWatchWindow()
        end
        ImGui.Separator()
        if styledButton('Unload TurboMobs##watch_menu_unload', 'unloadDark', 7, 3, 'Unload TurboMobs. Same as /lua stop TurboMobs.') then
            ux.stopNow()
        end
        ImGui.EndPopup()
    end

    local dragX = x0 + btnW + 4
    local dragW = math.max(20, barW - (btnW * 2) - 8)
    if ImGui.SetCursorPos and ImGui.InvisibleButton then
        ImGui.SetCursorPos(dragX, y0)
        ImGui.InvisibleButton('##watch_header_drag', dragW, 38)
        ux._watchHeaderDragging = ImGui.IsItemActive and ImGui.IsItemActive() or false
        if ux.chromeDragActiveItem then ux.chromeDragActiveItem(dSt) end
        if (not ux.chromeDragCanHandle()) and ux._watchHeaderDragging then ux.dragCurrentWindow() end
        if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then ImGui.SetTooltip('Drag to move Turbo Watch.') end
    else
        ux._watchHeaderDragging = false
    end

    if ImGui.SetCursorPos then
        ImGui.SetCursorPos(dragX + math.max(0, (dragW - titleW) * 0.5), y0 + 4)
        coloredText(titleA, 'etaSoon')
        ImGui.SameLine(0, 0)
        coloredText(titleB, 'idle')
    else
        ImGui.SameLine()
        coloredText(titleA .. titleB, 'etaSoon')
    end

    if ImGui.SetCursorPos then
        ImGui.SetCursorPos(x0 + math.max(0, barW - btnW), y0)
    else
        ImGui.SameLine()
        pushCursorToFarRight(btnW)
    end
    if styledButton('+##watch_expand', 'windowToggle', 7, 3, showWindow and 'Close the full TurboMobs window.' or 'Open the full TurboMobs window.', btnW, btnH) then
        ux.toggleFullMainWindow()
    end
    ux.chromeDragAddLastItem(dSt)

    if ImGui.SetCursorPos then
        ImGui.SetCursorPos(x0, y0 + 42)
    else
        ImGui.NewLine()
    end
    ux.chromeDragSetBandToCursor(dSt)
    ux.chromeDragHandle('Drag Turbo Watch header to move the window.', dSt)
    if ux.chromeDragCanHandle() then
        ux._watchHeaderDragging = dSt.grabbing == true
    end
    ImGui.Separator()
end

ux.drawFullWindowChrome = function()
    ux.chromeDragReset()
    local barW = ux.contentRegionWidth()
    local titleA = 'Turbo'
    local titleB = string.format('Mobs v%s', VERSION)
    local titleW = ux.imguiTextWidth(titleA) + ux.imguiTextWidth(titleB)
    local btnW, btnH = 30, 22
    local x0 = 0
    local y0 = 0
    if ImGui.GetCursorPos then
        local x, y = ImGui.GetCursorPos()
        x0, y0 = tonumber(x) or 0, tonumber(y) or 0
    end

    if styledButton('...##full_menu_btn', 'menu', 7, 3, 'TurboMobs menu.', btnW, btnH) then
        if ImGui.OpenPopup then ImGui.OpenPopup('##full_menu_popup') end
    end
    ux.chromeDragAddLastItem()
    if ImGui.BeginPopup and ImGui.BeginPopup('##full_menu_popup') then
        if styledButton('Show Turbo Watch##full_menu_watch', 'primary', 7, 3, 'Show the Turbo Watch mini window.') then
            ux.showWatchWindow()
        end
        if styledButton('Close Full Window##full_menu_close', 'neutral', 7, 3, 'Close the full TurboMobs window. Tracking stays active.') then
            ux.hideFullWindow()
        end
        if ux.navigationActive() then
            if styledButton('Nav Stop##full_menu_nav_stop', 'neutral', 7, 3, 'Stop active MQ navigation without unloading TurboMobs.') then
                ux.stopNav()
            end
        end
        ImGui.Separator()
        if styledButton('Unload TurboMobs##full_menu_unload', 'unloadDark', 7, 3, 'Unload TurboMobs. Same as /lua stop TurboMobs.') then
            ux.stopNow()
        end
        ImGui.EndPopup()
    end

    local dragX = x0 + btnW + 4
    local dragW = math.max(20, barW - (btnW * 2) - 8)
    if ImGui.SetCursorPos and ImGui.InvisibleButton then
        ImGui.SetCursorPos(dragX, y0)
        ImGui.InvisibleButton('##full_header_drag', dragW, 38)
        if ux.chromeDragActiveItem then ux.chromeDragActiveItem() end
        if (not ux.chromeDragCanHandle()) and ImGui.IsItemActive and ImGui.IsItemActive() then ux.dragCurrentWindow() end
        if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then ImGui.SetTooltip('Drag to move TurboMobs.') end
    end

    if ImGui.SetCursorPos then
        ImGui.SetCursorPos(dragX + math.max(0, (dragW - titleW) * 0.5), y0 + 4)
        coloredText(titleA, 'etaSoon')
        ImGui.SameLine(0, 0)
        coloredText(titleB, 'idle')
    else
        ImGui.SameLine()
        coloredText(titleA .. titleB, 'etaSoon')
    end

    if ImGui.SetCursorPos then
        ImGui.SetCursorPos(x0 + math.max(0, barW - btnW), y0)
    else
        ImGui.SameLine()
        pushCursorToFarRight(btnW)
    end
    if styledButton('-##full_minimize', 'windowToggle', 7, 3, 'Close the full TurboMobs window and keep Turbo Watch available.', btnW, btnH) then
        ux.hideFullWindow()
        ux.showWatchWindow()
    end
    ux.chromeDragAddLastItem()

    if ImGui.SetCursorPos then
        ImGui.SetCursorPos(x0, y0 + 42)
    else
        ImGui.NewLine()
    end
    ux.chromeDragSetBandToCursor()
    ux.chromeDragHandle('Drag TurboMobs header to move the window.')
    ImGui.Separator()
end

local function drawWindowChrome(minimizeTooltip)
    if styledButton('Unload##tmobs_chrome_unload', 'unloadDark', 7, 3, 'Unload TurboMobs. Same as /lua stop TurboMobs.') then
        ux.stopNow()
    end
    ImGui.SameLine()
    if styledButton('Nav Stop##tmobs_chrome_nav_stop', 'neutral', 7, 3, 'Stop active MQ navigation without unloading TurboMobs.') then
        ux.stopNav()
    end
    ImGui.SameLine()
    pushCursorToFarRight(50)
    if styledButton(' - ##tmobs_chrome_minimize', 'windowToggle', 17, 6, minimizeTooltip or 'Minimize to Turbo Watch.') then
        ux.minimizeToWatchWindow()
    end
    ImGui.Separator()
end

ux.directionLabel = function(row)
    if not row then return '-' end
    if ux.dynamicDirectionRow and tonumber(row.directionDegrees) == nil then
        row = ux.dynamicDirectionRow(row) or row
    end
    local direct = trim(tostring(row.direction or ''))
    if direct ~= '' then return direct end
    local deg = tonumber(row.directionDegrees)
    if not deg then return '-' end
    deg = ((deg % 360) + 360) % 360
    if deg < 22.5 or deg >= 337.5 then return 'front' end
    if deg < 67.5 then return 'front-right' end
    if deg < 112.5 then return 'right' end
    if deg < 157.5 then return 'back-right' end
    if deg < 202.5 then return 'behind' end
    if deg < 247.5 then return 'back-left' end
    if deg < 292.5 then return 'left' end
    return 'front-left'
end

ux.directionDegreesFromLabel = function(value)
    local text = trim(tostring(value or '')):lower()
    if text == '' then return nil end
    if text:find('straight ahead', 1, true) or text:find('front', 1, true) then
        if text:find('left', 1, true) then return 45 end
        if text:find('right', 1, true) then return 315 end
        return 0
    end
    if text:find('behind', 1, true) or text:find('back', 1, true) then
        if text:find('left', 1, true) then return 135 end
        if text:find('right', 1, true) then return 225 end
        return 180
    end
    if text:find('left', 1, true) and not text:find('right', 1, true) then return 90 end
    if text:find('right', 1, true) and not text:find('left', 1, true) then return 270 end
    text = text:gsub('^to your%s+', ''):gsub('^the%s+', '')
    text = text:gsub('_', '-'):gsub('%s+', '-')
    if text == 'front' or text == 'ahead' or text == 'forward' then return 0 end
    if text == 'front-right' or text == 'right-front' or text == 'ahead-right' then return 315 end
    if text == 'right' then return 270 end
    if text == 'back-right' or text == 'right-back' or text == 'behind-right' then return 225 end
    if text == 'behind' or text == 'back' then return 180 end
    if text == 'back-left' or text == 'left-back' or text == 'behind-left' then return 135 end
    if text == 'left' then return 90 end
    if text == 'front-left' or text == 'left-front' or text == 'ahead-left' then return 45 end
    return nil
end

ux.directionDebugText = function(row)
    if not row then return '' end
    local r = (ux.dynamicDirectionRow and ux.dynamicDirectionRow(row)) or row
    local bearing = tonumber(r.bearingDegrees)
    local heading = tonumber(r.playerHeading)
    local headingCCW = tonumber(r.playerHeadingCCW)
    local rel = tonumber(r.directionDegrees)
    if not bearing or not rel then return '' end
    if headingCCW then
        return string.format('Heading CW %.1f CCW %.1f | bearing %.1f | relative %.1f (%s) | MQ dir: %s',
            heading or 0, headingCCW, bearing, rel, ux.directionLabel(r), tostring(row.direction or '-'))
    end
    if not heading then return '' end
    return string.format('Heading %.1f | bearing %.1f | relative %.1f (%s) | MQ dir: %s',
        heading, bearing, rel, ux.directionLabel(r), tostring(row.direction or '-'))
end

ux.directionTooltipText = function(row)
    if not row then return '-' end
    local r = (ux.dynamicDirectionRow and ux.dynamicDirectionRow(row)) or row
    local debugText = ux.directionDebugText(r)
    local myX = tonumber(safeCall(function() return mq.TLO.Me.X() end, 0)) or 0
    local myY = tonumber(safeCall(function() return mq.TLO.Me.Y() end, 0)) or 0
    return string.format('%s\nPlayer loc %.1f, %.1f | Mob loc %.1f, %.1f\nMob: %s | distance %.1f',
        debugText ~= '' and debugText or ux.directionLabel(r),
        myX, myY,
        tonumber(row.x) or 0,
        tonumber(row.y) or 0,
        tostring(row.name or '-'),
        tonumber(r.distance or row.distance) or 0)
end

local function conColorForLevel(level)
    level = tonumber(level) or 0
    if level <= 0 then return 1.00, 1.00, 1.00, 1.00 end
    local myLevel = tonumber(ux.currentDrawLevel) or tonumber(safeCall(function() return mq.TLO.Me.Level() end, 0)) or 0
    if myLevel <= 0 then return 1.00, 1.00, 1.00, 1.00 end
    local diff = level - myLevel
    if diff >= 4 then return 1.00, 0.30, 0.30, 1.00
    elseif diff >= 1 then return 1.00, 1.00, 0.20, 1.00
    elseif diff == 0 then return 1.00, 1.00, 1.00, 1.00
    elseif diff >= -5 then return 0.40, 0.55, 1.00, 1.00
    elseif diff >= -13 then return 0.40, 0.85, 1.00, 1.00
    elseif diff >= -20 then return 0.30, 1.00, 0.30, 1.00
    else return 0.55, 0.55, 0.55, 1.00 end
end

local function conColoredText(text, level)
    local r, g, b, a = conColorForLevel(level)
    ImGui.PushStyleColor(ImGuiCol.Text, r, g, b, a)
    ImGui.Text(text)
    ImGui.PopStyleColor()
end

local function conColoredSelectable(label, row)
    local r, g, b, a = conColorForLevel(row.level)
    ImGui.PushStyleColor(ImGuiCol.Text, r, g, b, a)
    local targetId = tonumber(safeCall(function() return mq.TLO.Target.ID() end, 0)) or 0
    ImGui.Selectable(label, selectedId == row.id or targetId == row.id)
    local clicked = ImGui.IsItemClicked and ImGui.IsItemClicked(0)
    ImGui.PopStyleColor()
    return clicked
end

local function distanceColor(distance)
    distance = tonumber(distance) or 0
    if distance <= 50 then return 0.40, 1.00, 0.52, 1.00
    elseif distance <= 150 then return 0.40, 0.85, 1.00, 1.00
    elseif distance <= 300 then return 0.95, 0.72, 0.28, 1.00
    else return 1.00, 0.34, 0.30, 1.00 end
end

local function distanceColorVec(distance)
    local r, g, b, a = distanceColor(distance)
    return ImVec4(r, g, b, a)
end

local function distanceText(distance)
    local r, g, b, a = distanceColor(distance)
    ImGui.PushStyleColor(ImGuiCol.Text, r, g, b, a)
    ImGui.Text(string.format('%.0f', tonumber(distance) or 0))
    ImGui.PopStyleColor()
end

ux.dynamicDirectionRow = function(row)
    if not row or row.x == nil or row.y == nil then return row end
    local info = ux.relativeDirectionInfo and ux.relativeDirectionInfo(row.x, row.y)
    if not info then return row end

    local relDeg = nil
    local mqLabel = trim(tostring(row.direction or ''))
    if mqLabel ~= '' then
        relDeg = ux.directionDegreesFromLabel(mqLabel)
    end
    -- Direction arrow: prefer the cheap MQ direction label captured at scan time;
    -- otherwise derive the egocentric angle from the spawn's last-known coords and
    -- the per-frame cached player heading (this equals relativeDirectionInfo.relative).
    -- We deliberately do NOT call Spawn(id).HeadingTo per row here: that TLO read is
    -- uncached per spawn and spikes under multi-box load, and it was the dominant
    -- per-frame cost in the watch panel and Turbo Watch mini. The coord-based bearing
    -- matches HeadingTo for stationary camp spawns (the watch case); a fast-moving mob
    -- may lag by up to one scan, which is acceptable for a direction arrow.
    if relDeg == nil then
        relDeg = (info.bearing - info.headingCCW + 360) % 360
    end

    return {
        distance = info.distance,
        directionDegrees = relDeg,
        bearingDegrees = info.bearing,
        playerHeading = info.heading,
        playerHeadingCCW = info.headingCCW,
        direction = row.direction or '',
        name = row.name,
        x = row.x,
        y = row.y,
        z = row.z,
        id = row.id,
        level = row.level,
    }
end

ux.relativeDirectionInfo = function(x, y)
    local ctx = ux.directionContext or {}
    local myX = tonumber(ctx.x)
    if not myX then myX = tonumber(safeCall(function() return mq.TLO.Me.X() end, 0)) or 0 end
    local myY = tonumber(ctx.y)
    if not myY then myY = tonumber(safeCall(function() return mq.TLO.Me.Y() end, 0)) or 0 end
    local headingCW = tonumber(ctx.heading)
    if not headingCW then headingCW = tonumber(safeCall(function() return mq.TLO.Me.Heading.Degrees() end, 0)) or 0 end
    local headingCCW = tonumber(ctx.headingCCW)
    if not headingCCW then
        headingCCW = tonumber(safeCall(function() return mq.TLO.Me.Heading.DegreesCCW() end, nil))
    end
    if not headingCCW then headingCCW = (360 - headingCW) % 360 end
    local dx = (tonumber(x) or 0) - myX
    local dy = (tonumber(y) or 0) - myY
    local dist = math.sqrt(dx * dx + dy * dy)
    local function atan2(y, x)
        if x > 0 then return math.atan(y / x) end
        if x < 0 and y >= 0 then return math.atan(y / x) + math.pi end
        if x < 0 then return math.atan(y / x) - math.pi end
        if y > 0 then return math.pi / 2 end
        if y < 0 then return -math.pi / 2 end
        return 0
    end
    -- EQ world: +X = West, +Y = North. atan2(dx, dy) => CCW bearing (N=0, W=90, S=180, E=270).
    -- Arrow: CCW egocentric (ahead=0, left=90, behind=180, right=270).
    local bearing = (math.deg(atan2(dx, dy)) + 360) % 360
    local relative = (bearing - headingCCW + 360) % 360
    return {
        distance = dist,
        bearing = bearing,
        heading = headingCW,
        headingCCW = headingCCW,
        relative = relative,
    }
end

local function rotatePoint(p, cx, cy, angle)
    local radians = math.rad(angle)
    local cosA = math.cos(radians)
    local sinA = math.sin(radians)
    return ImVec2(
        cosA * (p.x - cx) - sinA * (p.y - cy) + cx,
        sinA * (p.x - cx) + cosA * (p.y - cy) + cy
    )
end

local function drawDirectionArrow(row, forceArrow)
    if row and ux.dynamicDirectionRow then row = ux.dynamicDirectionRow(row) or row end
    if not forceArrow and not ux.showDirectionArrows then
        ImGui.Text(row.direction ~= '' and row.direction or '-')
        return
    end
    local cursor = ImGui.GetCursorScreenPosVec()
    local top = ImVec2(cursor.x + 10, cursor.y + 1)
    local p1 = top
    local p2 = ImVec2(top.x + 5, top.y + 14)
    local p3 = ImVec2(top.x - 5, top.y + 14)
    local cx = (p1.x + p2.x + p3.x) / 3
    local cy = (p1.y + p2.y + p3.y) / 3
    -- directionDegrees is already CCW egocentric (0=ahead/up); rotate triangle directly.
    local angle = tonumber(row.directionDegrees) or ux.directionDegreesFromLabel(row.direction) or 0
    p1 = rotatePoint(p1, cx, cy, angle)
    p2 = rotatePoint(p2, cx, cy, angle)
    p3 = rotatePoint(p3, cx, cy, angle)
    ImGui.GetWindowDrawList():AddTriangleFilled(p1, p2, p3, ImGui.GetColorU32(distanceColorVec(row.distance)))
    ImGui.Dummy(20, 16)
    if ImGui.IsItemHovered() then ImGui.SetTooltip(ux.directionTooltipText(row)) end
end

local function sameLineColoredText(text, colorKey)
    ImGui.SameLine()
    coloredText(text, colorKey)
end

-- ============================================================
-- Spawn scanning
-- ============================================================

local function looksNamed(spawn)
    if not spawn then return false end
    local named = safeCall(function() return spawn.Named() end, nil)
    if named ~= nil then return named and true or false end
    local name = tostring(safeCall(function() return spawn.CleanName() end, nil) or '')
    if name == '' then name = tostring(safeCall(function() return spawn.Name() end, '') or '') end
    if name:match('^[A-Z]') and not name:lower():match('^a ') and not name:lower():match('^an ') then
        return true
    end
    return false
end

ux.rowLooksPH = function(row)
    if not row or not row.id then return false end
    if row._tmIsPH ~= nil
        and row._tmDerivedWatchGen == ux.watchGeneration
        and row._tmDerivedSpawnRev == ux.spawnDataRevision then
        return row._tmIsPH == true
    end
    local pointKey = spawnPointKey(row)
    if not pointKey or pointKey == '' then return false end
    local lookup = ux.activeSearchPHLookup or (ux.currentZonePHLookup and ux.currentZonePHLookup()) or nil
    if lookup and lookup.byPoint and lookup.byPoint[pointKey] then return true end
    local name = row.name_l or tostring(row.name or ''):lower()
    local candidates = lookup and lookup.byName and lookup.byName[name] or nil
    if candidates then
        for _, watch in ipairs(candidates) do
            if watch and ux.rowIsPhForWatch(watch, row) then
                return true
            end
        end
        return false
    end
    -- Fallback for calls before the lookup cache exists.
    local _, currentWatches = ux.currentZoneWatchPairs()
    for _, watch in ipairs(currentWatches or {}) do
        if watch and ux.rowIsPhForWatch(watch, row) then
            return true
        end
    end
    return false
end

ux.rowIsNamedOrPH = function(row)
    if not row then return false end
    if row._tmNamedOrPH ~= nil
        and row._tmDerivedWatchGen == ux.watchGeneration
        and row._tmDerivedSpawnRev == ux.spawnDataRevision then
        return row._tmNamedOrPH == true
    end
    return row.named == true or ux.labelLooksNamed(row.name) or ux.rowLooksPH(row)
end

-- Delegated to turbomobs_logic (pure, tested). Identical to the original.
ux.finalizeSpawnRow = TM.finalizeSpawnRow

-- Delegated to turbomobs_logic (pure, tested). Identical to the original.
ux.rowIsUntargetable = TM.rowIsUntargetable

ux.passLiveSettingFilters = function(row)
    if not row then return false end
    local rowType = row.type_l or tostring(row.type or ''):lower()
    local rowBody = row.body_l or tostring(row.body or ''):lower()
    local rowName = row.name_l or tostring(row.name or ''):lower()

    if npcOnly then
        if row.is_player or rowType == 'pc' then return false end
        if row.is_corpse or rowType:find('corpse', 1, true) then return false end
        if rowBody == 'player' then return false end
    end

    if ux.targetableOnly and ux.rowIsUntargetable(row) then return false end
    if not includeCorpses and (row.is_corpse or rowType:find('corpse', 1, true)
        or rowName:find("'s corpse", 1, true) or rowName:find('`s corpse', 1, true)) then return false end
    if not includePlayers and (row.is_player or rowType == 'pc' or rowBody == 'player') then return false end
    if not includeGroundItems and (row.is_ground or rowType == 'item' or rowBody == 'item' or rowType == 'ground item') then return false end

    if not includePets then
        if row.is_pet_type or rowType:find('pet', 1, true) then return false end
        if row.is_pet_body or rowBody == 'familiar' or rowBody == 'summoned creature' or rowBody == 'undeadpet' then return false end
        if row.is_pet_name or rowName:find("'s pet", 1, true) or rowName:find('`s pet', 1, true) then return false end
    end

    return true
end

local function passLocalFilters(row)
    if not row then return false end
    if row.id == 0 then return false end
    -- Always exclude the player's own spawn (self appears at dist 0 and confuses search results).
    -- ux._selfId is set once per scan in refreshSpawns; falls back to a live TLO read for
    -- refilterSearchRows calls that happen outside the scan loop.
    local _selfId = ux._selfId or 0
    if _selfId == 0 then
        _selfId = tonumber(safeCall(function() return mq.TLO.Me.ID() end, 0)) or 0
        ux._selfId = _selfId
    end
    if _selfId > 0 and row.id == _selfId then return false end

    local rowType = row.type_l or tostring(row.type or ''):lower()
    local rowBody = row.body_l or tostring(row.body or ''):lower()
    local rowName = row.name_l or tostring(row.name or ''):lower()
    local rowTrueName = row.trueName_l or tostring(row.trueName or ''):lower()
    local rowRace = row.race_l or tostring(row.race or ''):lower()
    local rowClass = ux.classSearchText and ux.classSearchText(row.class) or (row.class_l or tostring(row.class or ''):lower())

    if not debugMode then
        if rowName == 'zone controller' then return false end
        if rowName:find('depop', 1, true) then return false end
        if rowName:find('controller', 1, true) then return false end
        if rowBody == 'trap' or rowBody == 'timer' or rowBody == 'eventtrigger' then return false end
        if rowType:find('trigger', 1, true) then return false end
    end

    if not ux.passLiveSettingFilters(row) then return false end

    if row.level < minLevel or row.level > maxLevel then return false end
    if maxDistance and maxDistance > 0 and row.distance > maxDistance then return false end
    if namedOnly and not row.named then return false end
    if ux.namedOrPHOnly and not ux.rowIsNamedOrPH(row) then return false end

    local needles = ux.activeFilterNeedles
    local s = needles.search
    if s ~= '' and not (rowName:find(s, 1, true) or rowTrueName:find(s, 1, true)) then return false end

    local bodyNeedle = needles.body
    if bodyNeedle ~= '' and not rowBody:find(bodyNeedle, 1, true) then return false end

    local raceNeedle = needles.race
    if raceNeedle ~= '' and not rowRace:find(raceNeedle, 1, true) then return false end

    local classNeedle = needles.class
    if classNeedle ~= '' and not rowClass:find(classNeedle, 1, true) then return false end

    local typeNeedle = needles.type
    if typeNeedle ~= '' and not rowType:find(typeNeedle, 1, true) then return false end

    return true
end

-- passQSFilters: Quick Search variant of passLocalFilters.
-- Applies all the same spawn-level guards (self-exclude, hidden types, include
-- flags, level range, text needles) but deliberately omits the namedOnly /
-- namedOrPHOnly checks — those are module-level flags for the OLD search
-- system and are handled separately by qsNamedOnly/qsNamedPHOnly in the QS
-- browse loop.  Passing namedOnly into the QS loop was reducing 270 mobs to
-- ~25 when the user had ever toggled Named-only in the legacy search panel.
ux.passQSFilters = function(row, tN, bN, rN, cN)
    if not row or row.id == 0 then return false end
    local selfId = ux._selfId or 0
    if selfId > 0 and row.id == selfId then return false end

    local rType = row.type_l or tostring(row.type or ''):lower()
    local rBody = row.body_l or tostring(row.body or ''):lower()
    local rName = row.name_l or tostring(row.name or ''):lower()

    if not debugMode then
        if rName == 'zone controller' then return false end
        if rName:find('depop', 1, true) then return false end
        if rName:find('controller', 1, true) then return false end
        if rBody == 'trap' or rBody == 'timer' or rBody == 'eventtrigger' then return false end
        if rType:find('trigger', 1, true) then return false end
    end

    if ux.targetableOnly and ux.rowIsUntargetable(row) then return false end
    if not includeCorpses  and (row.is_corpse or rType:find('corpse', 1, true)
        or rName:find("'s corpse", 1, true) or rName:find('`s corpse', 1, true)) then return false end
    if not includePlayers  and (row.is_player or rType == 'pc' or rBody == 'player') then return false end
    if not includeGroundItems and (row.is_ground or rType == 'item' or rBody == 'item' or rType == 'ground item') then return false end
    if not includePets then
        if row.is_pet_type or rType:find('pet', 1, true) then return false end
        if row.is_pet_body or rBody == 'familiar' or rBody == 'summoned creature' or rBody == 'undeadpet' then return false end
        if row.is_pet_name or rName:find("'s pet", 1, true) or rName:find('`s pet', 1, true) then return false end
    end

    local rl = row.level or 0
    if rl < minLevel or rl > maxLevel then return false end

    if tN ~= '' and not rType:find(tN, 1, true) then return false end
    if bN ~= '' and not rBody:find(bN, 1, true) then return false end
    if rN ~= '' then
        local rr = row.race_l or tostring(row.race or ''):lower()
        if not rr:find(rN, 1, true) then return false end
    end
    if cN ~= '' then
        local rc = ux.classSearchText and ux.classSearchText(row.class) or (row.class_l or tostring(row.class or ''):lower())
        if not rc:find(cN, 1, true) then return false end
    end
    return true
end

local function passWatchFilters(row)
    if not row or row.id == 0 then return false end
    local rowType = row.type_l or tostring(row.type or ''):lower()
    local rowBody = row.body_l or tostring(row.body or ''):lower()
    local rowName = row.name_l or tostring(row.name or ''):lower()

    if row.dead then return false end
    if rowName == 'zone controller' then return false end
    if rowName:find('depop', 1, true) then return false end
    if rowName:find('controller', 1, true) then return false end
    if rowName:find("'s corpse", 1, true) or rowName:find('`s corpse', 1, true) then return false end
    if rowType:find('corpse', 1, true) or rowBody:find('corpse', 1, true) then return false end
    if rowType == 'corpse' or rowBody == 'corpse' then return false end
    if rowType == 'pc' or rowBody == 'player' then return false end
    if rowBody == 'trap' or rowBody == 'timer' or rowBody == 'eventtrigger' then return false end
    if rowType:find('trigger', 1, true) then return false end
    if rowType:find('pet', 1, true) then return false end
    if rowBody == 'familiar' or rowBody == 'summoned creature' or rowBody == 'undeadpet' then return false end
    if rowName:find("'s pet", 1, true) or rowName:find('`s pet', 1, true) then return false end
    return true
end

local function passWatchPresenceFilters(row)
    if not row or row.id == 0 then return false end
    local rowType = tostring(row.type or ''):lower()
    local rowBody = tostring(row.body or ''):lower()
    local rowName = tostring(row.name or ''):lower()

    if row.dead then return false end
    if rowName == 'zone controller' then return false end
    if rowName:find('depop', 1, true) then return false end
    if rowName:find('controller', 1, true) then return false end
    if rowName:find("'s corpse", 1, true) or rowName:find('`s corpse', 1, true) then return false end
    if rowType:find('corpse', 1, true) or rowBody:find('corpse', 1, true) then return false end
    if rowType == 'corpse' or rowBody == 'corpse' then return false end
    if rowType == 'pc' or rowBody == 'player' then return false end
    if rowBody == 'trap' or rowBody == 'timer' or rowBody == 'eventtrigger' then return false end
    if rowType:find('trigger', 1, true) then return false end
    if rowType:find('pet', 1, true) then return false end
    if rowBody == 'familiar' or rowBody == 'summoned creature' or rowBody == 'undeadpet' then return false end
    if rowName:find("'s pet", 1, true) or rowName:find('`s pet', 1, true) then return false end
    return true
end

local function isPetRow(row)
    if not row then return false end
    local rowType = tostring(row.type or ''):lower()
    local rowBody = tostring(row.body or ''):lower()
    local rowName = tostring(row.name or ''):lower()
    if rowType:find('pet', 1, true) then return true end
    if rowBody == 'familiar' or rowBody == 'summoned creature' or rowBody == 'undeadpet' then return true end
    if rowName:find("'s pet", 1, true) or rowName:find('`s pet', 1, true) then return true end
    return false
end

local function collectNearestByQuery(query, label, out, seen)
    local count = safeCall(function() return mq.TLO.SpawnCount(query)() end, 0) or 0
    local limit = math.min(count, scanMaxResults)
    for i = 1, limit do
        if i % 25 == 0 then ux.pumpCommandEvents() end
        local spawn = safeCall(function() return mq.TLO.NearestSpawn(i, query) end, nil)
        if not spawn then
            spawn = safeCall(function() return mq.TLO.NearestSpawn(string.format('%d, %s', i, query)) end, nil)
        end
        if spawn then
            local id = tonumber(safeCall(function() return spawn.ID() end, 0)) or 0
            if id ~= 0 and not seen[id] then
                seen[id] = true
                table.insert(out, spawn)
            end
        end
    end
    return count, limit, label
end

ux.addUniqueSpawnObject = function(out, seen, spawn)
    if not spawn then return false end
    local id = tonumber(safeCall(function() return spawn.ID() end, 0)) or 0
    if id == 0 or seen[id] then return false end
    seen[id] = true
    table.insert(out, spawn)
    return true
end

ux.quoteSpawnSearchName = function(name)
    local s = trim(tostring(name or ''))
    if s == '' then return '' end
    return '"' .. s:gsub('"', '') .. '"'
end

ux.collectWatchSpawnQuery = function(query, label, out, seen, limit, maxUnique)
    query = trim(tostring(query or ''))
    if query == '' then return 0, 0, label end
    local found = 0
    local scanned = 0
    local count = tonumber(safeCall(function() return mq.TLO.SpawnCount(query)() end, 0)) or 0
    local maxCount = math.min(count, tonumber(limit) or scanMaxResults)
    for i = 1, maxCount do
        if maxUnique and #out >= maxUnique then break end
        if i % 10 == 0 then ux.pumpCommandEvents() end
        local spawn = safeCall(function() return mq.TLO.NearestSpawn(i, query) end, nil)
        if not spawn then
            spawn = safeCall(function() return mq.TLO.NearestSpawn(string.format('%d, %s', i, query)) end, nil)
        end
        scanned = scanned + 1
        if ux.addUniqueSpawnObject(out, seen, spawn) then found = found + 1 end
    end

    if count == 0 and (not maxUnique or #out < maxUnique) then
        local spawn = safeCall(function() return mq.TLO.Spawn(query) end, nil)
        if ux.addUniqueSpawnObject(out, seen, spawn) then
            found = found + 1
            scanned = math.max(scanned, 1)
            count = math.max(count, 1)
        end
    end
    return count, scanned, label
end

ux.collectDueWatchProbeSpawns = function(out, seen, counts)
    local added = 0
    local queryCount = 0
    local _, currentWatches = ux.currentZoneWatchPairs()

    local function nameKey(name)
        name = trim(tostring(name or ''))
        if name == '' then return '' end
        if ux.seedNameKey then return ux.seedNameKey(name) end
        return name:lower()
    end

    local function addName(names, seenNames, name)
        name = trim(tostring(name or ''))
        local key = nameKey(name)
        if name ~= '' and not seenNames[key] then
            seenNames[key] = true
            table.insert(names, name)
        end
    end

    local function buildAllowedNames(watch)
        local allowed = {}
        local names, seenNames = {}, {}
        addName(names, seenNames, watch and watch.label)
        addName(names, seenNames, watch and watch.desiredName)
        addName(names, seenNames, ux.smartDesiredName and ux.smartDesiredName(watch) or '')
        for name in pairs((ux.watchPhNameSet and ux.watchPhNameSet(watch)) or {}) do
            addName(names, seenNames, name)
        end
        for _, name in ipairs(names) do
            local key = nameKey(name)
            if key ~= '' then allowed[key] = true end
        end
        return names, allowed
    end

    local function probeName(watch, name, allowed)
        local queries = {}
        local seenQueries = {}
        local quoted = ux.quoteSpawnSearchName and ux.quoteSpawnSearchName(name) or ''
        if quoted ~= '' then addName(queries, seenQueries, 'npc ' .. quoted) end
        -- Fallback: substring match catches mobs with server-appended suffixes (e.g. Lazarus HC "(hunter)")
        if quoted ~= '' then addName(queries, seenQueries, 'npc name ' .. quoted) end

        for _, query in ipairs(queries) do
            queryCount = queryCount + 1
            local count = tonumber(safeCall(function() return mq.TLO.SpawnCount(query)() end, 0)) or 0
            local maxCount = math.max(1, math.min(count > 0 and count or 1, tonumber(ux.dueWatchProbeMaxCandidates) or 8))
            local rejectedAnchor = 0
            for i = 1, maxCount do
                local spawn
                if count > 0 then
                    spawn = safeCall(function() return mq.TLO.NearestSpawn(i, query) end, nil)
                    if not spawn then
                        spawn = safeCall(function() return mq.TLO.NearestSpawn(string.format('%d, %s', i, query)) end, nil)
                    end
                else
                    spawn = safeCall(function() return mq.TLO.Spawn(query) end, nil)
                end
                local id = spawn and (tonumber(safeCall(function() return spawn.ID() end, 0)) or 0) or 0
                local clean = spawn and tostring(safeCall(function() return spawn.CleanName() end, name) or name) or ''
                local typ = spawn and tostring(safeCall(function() return spawn.Type() end, '') or ''):lower() or ''
                local body = spawn and tostring(safeCall(function() return spawn.Body() end, '') or ''):lower() or ''
                local dead = spawn and safeCall(function() return spawn.Dead() end, false) == true
                local corpse = clean:lower():find('corpse', 1, true) ~= nil
                    or typ:find('corpse', 1, true) ~= nil
                    or body:find('corpse', 1, true) ~= nil
                local cleanKey = nameKey(clean)
                -- Also accept names that match after stripping a trailing parenthetical suffix
                -- (e.g. "Hierophant Prime Grekal (hunter)" -> base "hierophant prime grekal")
                local cleanBaseKey = nameKey(clean:gsub('%s*%([^)]+%)%s*$', ''))
                local exact = cleanKey ~= '' and allowed
                    and (allowed[cleanKey] == true
                        or (cleanBaseKey ~= '' and cleanBaseKey ~= cleanKey and allowed[cleanBaseKey] == true))
                local x = spawn and tonumber(safeCall(function() return spawn.X() end, 0)) or 0
                local y = spawn and tonumber(safeCall(function() return spawn.Y() end, 0)) or 0
                local candidateRow = { id = id, name = clean, x = x, y = y }
                local anchored = false
                if exact then
                    if ux.rowIsDesiredForWatch and ux.rowIsDesiredForWatch(watch, candidateRow) then
                        anchored = true
                    elseif ux.rowIsPlaceholderAtWatchCamp then
                        anchored = ux.rowIsPlaceholderAtWatchCamp(watch, candidateRow)
                    elseif ux.targetMatchesWatch then
                        anchored = ux.targetMatchesWatch(watch, clean:lower(), id, x, y)
                    else
                        anchored = true
                    end
                end
                if id > 0 and exact and anchored and not dead and not corpse then
                    local wasAdded = ux.addUniqueSpawnObject(out, seen, spawn)
                    if wasAdded then added = added + 1 end
                    table.insert(counts, string.format('due:%s=1/1', tostring(name)))
                    if ux.recordPerfLine then
                        ux.recordPerfLine(string.format(
                            'DueWatchProbe hit label=%s query=%s id=%s clean=%s',
                            tostring(watch and (watch.label or watch.desiredName) or '-'),
                            tostring(query),
                            tostring(id),
                            tostring(clean)
                        ))
                    end
                    return true
                elseif id > 0 and exact and not anchored then
                    rejectedAnchor = rejectedAnchor + 1
                elseif id > 0 and not exact and ux.recordPerfLine then
                    ux.recordPerfLine(string.format(
                        'DueWatchProbe rejected label=%s query=%s id=%s clean=%s',
                        tostring(watch and (watch.label or watch.desiredName) or '-'),
                        tostring(query),
                        tostring(id),
                        tostring(clean)
                    ))
                end
            end
            if rejectedAnchor > 0 and ux.recordPerfLine then
                ux.recordPerfLine(string.format(
                    'DueWatchProbe off-anchor label=%s query=%s rejected=%d',
                    tostring(watch and (watch.label or watch.desiredName) or '-'),
                    tostring(query),
                    rejectedAnchor
                ))
            end
        end
        return false
    end

    for _, watch in ipairs(currentWatches or {}) do
        if ux.watchIsEffectivelyDue and ux.watchIsEffectivelyDue(watch) then
            local names, allowed = buildAllowedNames(watch)
            for _, name in ipairs(names) do
                if probeName(watch, name, allowed) then break end
            end
        end
    end

    if queryCount > 0 and added == 0 then
        table.insert(counts, string.format('dueProbe=0/%d', queryCount))
    end
    return added, queryCount
end

local function normalizeSpawnTable(result)
    local normalized = {}
    if type(result) ~= 'table' then return normalized end
    for _, spawn in pairs(result) do
        if spawn then table.insert(normalized, spawn) end
    end
    return normalized
end

local function getAllSpawnObjects()
    if ux.useBulkSpawnScan == true then
        local okAll, resultAll = pcall(function() return mq.getAllSpawns() end)
        local allSpawns = normalizeSpawnTable(resultAll)
        if okAll and #allSpawns > 0 then
            debugText = string.format('getAllSpawns=%d', #allSpawns)
            return allSpawns, #allSpawns, 'allspawns'
        end
        -- getFilteredSpawns(predicate) is intentionally skipped: when called inside
        -- an ImGui frame it caps results at ~31 spawns, which is worse than the TLO
        -- loop below. If getAllSpawns() is unavailable or empty, fall straight through
        -- to collectNearestByQuery which is fully uncapped (up to scanMaxResults).
    end

    local fallback = {}
    local seen = {}
    local counts = {}
    local queryList = { 'npc' }
    if includePets then table.insert(queryList, 'pet') end
    if includePlayers then table.insert(queryList, 'pc') end
    if includeCorpses then table.insert(queryList, 'corpse') end
    if includeGroundItems then table.insert(queryList, 'item') end
    for _, query in ipairs(queryList) do
        local count, scanned = collectNearestByQuery(query, query, fallback, seen)
        table.insert(counts, string.format('%s=%d/%d', query, count or 0, scanned or 0))
        if #fallback >= scanMaxResults then break end
    end
    debugText = table.concat(counts, ' | ')
    return fallback, #fallback, 'broad-nearest'
end

ux.getTargetedWatchSpawnObjects = function(opts)
    opts = opts or {}
    local hints = ux.buildWatchScanHints and ux.buildWatchScanHints(opts) or nil
    if type(hints) ~= 'table' or (tonumber(hints.count) or 0) <= 0 then return nil end
    ux.lastWatchScanHints = hints

    local out = {}
    local seen = {}
    local counts = {}
    local total = 0
    local queryCount = 0
    local maxUnique = math.max(8, tonumber(opts.targetedWatchMaxSpawns) or tonumber(ux.targetedWatchMaxSpawns) or 32)

    -- Due probes run first so overdue camps are never squeezed out by name/id queries.
    local dueAdded, dueQueries = 0, 0
    if ux.collectDueWatchProbeSpawns then
        dueAdded, dueQueries = ux.collectDueWatchProbeSpawns(out, seen, counts)
        total = total + (tonumber(dueAdded) or 0)
        queryCount = queryCount + (tonumber(dueQueries) or 0)
    end

    for id in pairs(hints.ids or {}) do
        if #out >= maxUnique then break end
        id = tonumber(id) or 0
        if id > 0 then
            queryCount = queryCount + 1
            local count, scanned = ux.collectWatchSpawnQuery(string.format('id %d', id), string.format('id=%d', id), out, seen, 1, maxUnique)
            total = total + (tonumber(count) or 0)
            table.insert(counts, string.format('id:%d=%d/%d', id, count or 0, scanned or 0))
        end
    end

    local nameLimit = math.max(1, tonumber(ux.targetedWatchNameLimit) or 20)
    for name in pairs(hints.names or {}) do
        if #out >= maxUnique then break end
        local quoted = ux.quoteSpawnSearchName(name)
        if quoted ~= '' then
            queryCount = queryCount + 1
            local query = 'npc ' .. quoted
            local count, scanned = ux.collectWatchSpawnQuery(query, tostring(name), out, seen, nameLimit, maxUnique)
            total = total + (tonumber(count) or 0)
            table.insert(counts, string.format('name:%s=%d/%d', tostring(name), count or 0, scanned or 0))
            -- Fallback: substring scan catches mobs with server-appended suffixes (e.g. Lazarus HC "(hunter)")
            if (tonumber(count) or 0) == 0 and #out < maxUnique then
                queryCount = queryCount + 1
                local partialQuery = 'npc name ' .. quoted
                local pc, ps = ux.collectWatchSpawnQuery(partialQuery, tostring(name) .. '~', out, seen, nameLimit, maxUnique)
                total = total + (tonumber(pc) or 0)
                if (tonumber(pc) or 0) > 0 then
                    table.insert(counts, string.format('name~:%s=%d/%d', tostring(name), pc or 0, ps or 0))
                end
            end
        end
    end

    if queryCount == 0 then return nil end
    if #out >= maxUnique then
        table.insert(counts, string.format('targetCap=%d', maxUnique))
    end
    table.insert(counts, string.format('watchHints=%d/%d names=%d ids=%d points=%d extra=%d',
        tonumber(hints.count) or 0,
        tonumber(hints.totalWatches) or 0,
        tonumber(hints.nameCount) or 0,
        tonumber(hints.idCount) or 0,
        tonumber(hints.pointCount) or 0,
        tonumber(hints.extraNames) or 0))
    debugText = table.concat(counts, ' | ')
    return out, total, 'targeted-watch'
end

local function sortSpawns()
    table.sort(spawns, function(a, b)
        local av, bv
        if sortMode == 'Name' then av, bv = a.name_l or a.name, b.name_l or b.name
        elseif sortMode == 'Level' then av, bv = a.level, b.level
        elseif sortMode == 'ID' then av, bv = a.id, b.id
        elseif sortMode == 'TrueName' then av, bv = a.trueName_l or a.trueName, b.trueName_l or b.trueName
        elseif sortMode == 'Type' then av, bv = a.type_l or a.type, b.type_l or b.type
        elseif sortMode == 'Body' then av, bv = a.body_l or a.body, b.body_l or b.body
        elseif sortMode == 'Class' then av, bv = a.class_l or a.class, b.class_l or b.class
        elseif sortMode == 'Direction' then
            local da = ux.dynamicDirectionRow and ux.dynamicDirectionRow(a) or a
            local db = ux.dynamicDirectionRow and ux.dynamicDirectionRow(b) or b
            av, bv = tonumber(da and da.directionDegrees) or 0, tonumber(db and db.directionDegrees) or 0
        else av, bv = a.distance, b.distance end
        if av == bv then
            local an = a.name_l or tostring(a.name or ''):lower()
            local bn = b.name_l or tostring(b.name or ''):lower()
            return an < bn
        end
        if sortAscending then return av < bv end
        return av > bv
    end)
end

ux.refilterSearchRows = function()
    if not allSpawns or #allSpawns == 0 then
        spawns = {}
        statusText = 'No Search rows loaded. Press Refresh when you want to scan the full zone.'
        return false
    end
    ux.activeFilterNeedles.search = trim(searchText):lower()
    ux.activeFilterNeedles.body = trim(ux.bodyFilter):lower()
    ux.activeFilterNeedles.race = trim(ux.raceFilter):lower()
    ux.activeFilterNeedles.class = trim(ux.classFilter):lower()
    ux.activeFilterNeedles.type = trim(ux.typeFilter):lower()
    local fresh = {}
    for _, row in ipairs(allSpawns) do
        if passLocalFilters(row) then table.insert(fresh, row) end
    end
    spawns = fresh
    sortSpawns()
    if showWindow and tostring(ux.activeFullTab or ''):lower() == 'search' then
        ux.cacheSearchWatchedRows()
    end
    return true
end

-- ============================================================
-- Watch / alert system
-- ============================================================

local function watchKeyExact(name) return 'exact:' .. tostring(name or ''):lower() end
local function watchKeyId(id) return 'id:' .. tostring(id or 0) end
ux.watchKeyExactForZone = function(name, zone)
    local z = tostring(zone or ''):lower()
    local base = watchKeyExact(name)
    if z == '' then return base end
    return 'exact:' .. z .. ':' .. tostring(name or ''):lower()
end

ux.watchKeyForZonePoint = function(name, zone, pointKey)
    local z = tostring(zone or ''):lower()
    local p = tostring(pointKey or ''):lower()
    if p == '' then return ux.watchKeyExactForZone(name, z) end
    return 'exact:' .. z .. ':' .. tostring(name or ''):lower() .. ':' .. p
end

-- Find the best saved watch key for a named in a zone (seed camp preferred).
ux.findWatchKeyForNamedInZone = function(name, zone)
    zone = tostring(zone or currentZoneShort() or ''):lower()
    local labelKey = ux.seedNameKey and ux.seedNameKey(name) or trim(tostring(name or '')):lower()
    if zone == '' or labelKey == '' then return nil, nil end
    local bestKey, bestWatch, bestScore = nil, nil, -1
    for key, watch in pairs(watchList or {}) do
        if type(watch) == 'table' and tostring(watch.zone or ''):lower() == zone then
            local watchKey = ux.seedNameKey and ux.seedNameKey(watch.label or watch.desiredName or '')
                or trim(tostring(watch.desiredName or watch.label or '')):lower()
            if watchKey == labelKey then
                local score = 0
                if ux.watchIsSeedSourced(watch) then score = score + 100 end
                if ux.watchHasPoint(watch) then score = score + 50 end
                if tostring(key):find(':loc:', 1, true) then score = score + 25 end
                if watch.isUp == true then score = score + 10 end
                if score > bestScore then
                    bestScore = score
                    bestKey = key
                    bestWatch = watch
                end
            end
        end
    end
    return bestKey, bestWatch
end

ux.watchIsSeedSourced = function(watch)
    if type(watch) ~= 'table' then return false end
    local source = tostring(watch.source or ''):lower()
    return source:find('alla', 1, true) ~= nil or source:find('lazarus', 1, true) ~= nil
end

-- SpawnMaster import keys watches as `exact:zone:name`, while Alla seed import
-- keys them as `exact:zone:name:<point>`, so the same named in the same zone can
-- end up with two watches that never dedupe against each other (and double up in
-- the Watch list and Zone Intel "linked names"). When a seed (Alla) watch exists
-- for a zone+named, drop the bare same-zone/name watch that only carries a name
-- (e.g. SpawnMaster) -- the seed watch owns the PH names, respawn timer and spawn
-- anchor; the live point re-learns on its own. Zones with no Alla seed keep their
-- SpawnMaster watch untouched. Returns the count removed; idempotent.
ux.collapseDuplicateSourceWatches = function()
    local groups = {}
    for key, watch in pairs(watchList or {}) do
        if type(watch) == 'table' then
            local name = tostring(watch.desiredName or watch.label or ''):lower()
            if name ~= '' then
                local groupKey = tostring(watch.zone or ''):lower() .. '|' .. name
                groups[groupKey] = groups[groupKey] or {}
                table.insert(groups[groupKey], key)
            end
        end
    end
    local removed = 0
    for _, keys in pairs(groups) do
        if #keys > 1 then
            local keepKey, keepScore = nil, -1
            for _, key in ipairs(keys) do
                local watch = watchList[key]
                if type(watch) == 'table' then
                    local score = 0
                    if ux.watchIsSeedSourced(watch) then score = score + 100 end
                    if ux.watchHasPoint(watch) then score = score + 50 end
                    if tostring(key):find(':loc:', 1, true) then score = score + 25 end
                    if watch.isUp == true then score = score + 10 end
                    if score > keepScore then
                        keepScore = score
                        keepKey = key
                    end
                end
            end
            if keepKey then
                local keep = watchList[keepKey]
                for _, key in ipairs(keys) do
                    if key ~= keepKey then
                        local drop = watchList[key]
                        if keep and drop and drop.isUp == true and keep.isUp ~= true then
                            keep.isUp = true
                            keep.pointOccupied = drop.pointOccupied == true
                            keep.currentName = drop.currentName or keep.currentName
                            keep.currentIsDesired = true
                            keep.occupantSpawnId = tonumber(drop.occupantSpawnId or 0) or keep.occupantSpawnId or 0
                            keep.occupantName = drop.occupantName or keep.occupantName
                            keep.lastSeenAt = tonumber(drop.lastSeenAt or 0) or keep.lastSeenAt or 0
                            if tonumber(drop.lastSpawnId or 0) > 0 then keep.lastSpawnId = drop.lastSpawnId end
                            if drop.lastSpawnPointKey and drop.lastSpawnPointKey ~= '' then
                                keep.lastSpawnPointKey = drop.lastSpawnPointKey
                                keep.lastX = drop.lastX
                                keep.lastY = drop.lastY
                                keep.lastZ = drop.lastZ
                            end
                        end
                        watchList[key] = nil
                        removed = removed + 1
                    end
                end
            end
        end
    end
    return removed
end

-- Alla lists some placeholders as their own "named" row at the same coords as a
-- real named (e.g. A Gnoll Brewer + Master Brewer). Keep one watch per point.
ux.watchLabelListedAsPh = function(primaryWatch, candidateLabel)
    if not primaryWatch then return false end
    local key = ux.seedNameKey and ux.seedNameKey(candidateLabel) or trim(tostring(candidateLabel or '')):lower()
    if key == '' then return false end
    local lists = { primaryWatch.seedPhNames, primaryWatch.phNames }
    for _, list in ipairs(lists) do
        if type(list) == 'table' then
            for _, ph in ipairs(list) do
                if (ux.seedNameKey and ux.seedNameKey(ph) or trim(tostring(ph or '')):lower()) == key then
                    return true
                end
            end
        end
    end
    return false
end

-- Alla sometimes lists two real nameds at the same spawn as each other's PHs
-- (Froglok Repairer / Froglok Watcher, Pyzjn / Varsoon). Keep both watches.
ux.seedMutualNamedPair = function(watchA, watchBOrName)
    if not watchA then return false end
    local nameA = ux.seedNameKey and ux.seedNameKey(watchA.label or watchA.desiredName or '') or trim(tostring(watchA.label or watchA.desiredName or '')):lower()
    local nameB = type(watchBOrName) == 'table'
        and (ux.seedNameKey and ux.seedNameKey(watchBOrName.label or watchBOrName.desiredName or '') or trim(tostring(watchBOrName.label or watchBOrName.desiredName or '')):lower())
        or (ux.seedNameKey and ux.seedNameKey(watchBOrName) or trim(tostring(watchBOrName or '')):lower())
    if nameA == '' or nameB == '' or nameA == nameB then return false end
    local aListsB = ux.watchLabelListedAsPh(watchA, nameB) or ux.phNameSeedSanctioned(watchA, nameB)
    if not aListsB then return false end
    if type(watchBOrName) == 'table' then
        return ux.watchLabelListedAsPh(watchBOrName, watchA.label) or ux.phNameSeedSanctioned(watchBOrName, watchA.label)
    end
    for _, other in pairs(watchList or {}) do
        if type(other) == 'table' and other ~= watchA then
            local otherName = ux.seedNameKey and ux.seedNameKey(other.label or other.desiredName or '') or trim(tostring(other.label or other.desiredName or '')):lower()
            if otherName == nameB then
                return ux.watchLabelListedAsPh(other, watchA.label) or ux.phNameSeedSanctioned(other, watchA.label)
            end
        end
    end
    return false
end

ux.incomingSeedMutualNamedPair = function(existingWatch, incomingPhNames, incomingNamed)
    if not existingWatch or not ux.watchLabelListedAsPh(existingWatch, incomingNamed) then return false end
    local existingName = ux.seedNameKey and ux.seedNameKey(existingWatch.label or existingWatch.desiredName or '')
        or trim(tostring(existingWatch.label or existingWatch.desiredName or '')):lower()
    if existingName == '' then return false end
    for _, ph in ipairs(incomingPhNames or {}) do
        local phKey = ux.seedNameKey and ux.seedNameKey(ph) or trim(tostring(ph or '')):lower()
        if phKey ~= '' and phKey == existingName then return true end
    end
    return false
end

ux.rowIsMutualSeedNamedForSibling = function(watch, row)
    if not watch or not row or not ux.watchHasPoint(watch) then return false end
    local pointKey = tostring(watch.lastSpawnPointKey or '')
    if pointKey == '' then return false end
    local zone = tostring(watch.zone or currentZoneShort()):lower()
    for _, other in pairs(watchList or {}) do
        if type(other) == 'table' and other ~= watch
            and tostring(other.zone or ''):lower() == zone
            and tostring(other.lastSpawnPointKey or '') == pointKey
            and ux.seedMutualNamedPair(watch, other)
            and ux.rowIsDesiredForWatch(other, row) then
            return true
        end
    end
    return false
end

ux.watchPreviousOccupantCanStartTimer = function(watch, previousName, wasNamedUp)
    if not watch then return false end
    if wasNamedUp == true then return true end
    previousName = trim(tostring(previousName or ''))
    if previousName == '' then return false end
    local desired = trim(tostring(watch.desiredName or watch.label or '')):lower()
    if desired ~= '' and previousName:lower() == desired then return true end
    return ux.watchLabelListedAsPh and ux.watchLabelListedAsPh(watch, previousName) or false
end

ux.pruneRedundantSeedPointWatches = function(zoneKey)
    local function watchPrimaryScore(watch)
        local label = tostring(watch and watch.label or '')
        local score = (ux.labelLooksNamed and ux.labelLooksNamed(label)) and 100 or 0
        if label:match('^[Aa]n?%s+') then score = score - 40 end
        if watch and ux.watchIsSeedSourced and ux.watchIsSeedSourced(watch) then score = score + 10 end
        return score
    end
    zoneKey = tostring(zoneKey or currentZoneShort()):lower()
    if zoneKey == '' then return 0 end
    local byPoint = {}
    for key, watch in pairs(watchList or {}) do
        if type(watch) == 'table'
            and tostring(watch.zone or ''):lower() == zoneKey
            and tostring(watch.lastSpawnPointKey or '') ~= '' then
            local pk = watch.lastSpawnPointKey
            byPoint[pk] = byPoint[pk] or {}
            table.insert(byPoint[pk], { key = key, watch = watch })
        end
    end
    local removed = 0
    for _, list in pairs(byPoint) do
        if #list > 1 then
            table.sort(list, function(a, b) return watchPrimaryScore(a.watch) > watchPrimaryScore(b.watch) end)
            local primary = list[1]
            for i = 2, #list do
                local item = list[i]
                local drop = ux.watchLabelListedAsPh(primary.watch, item.watch.label)
                    or ux.watchLabelListedAsPh(item.watch, primary.watch.label)
                if drop and ux.seedMutualNamedPair(primary.watch, item.watch) then
                    drop = false
                end
                if drop then
                    local norm = ux.normalizeWatchNameList or function(list) return list or {} end
                    for _, ph in ipairs(norm(item.watch.phNames or {})) do
                        local merged, _ = appendUniqueText(primary.watch.phNames, ph, 32)
                        primary.watch.phNames = merged
                    end
                    if type(item.watch.seedPhNames) == 'table' then
                        primary.watch.seedPhNames = primary.watch.seedPhNames or {}
                        for _, ph in ipairs(item.watch.seedPhNames) do
                            local merged, _ = appendUniqueText(primary.watch.seedPhNames, ph, 32)
                            primary.watch.seedPhNames = merged
                        end
                    end
                    watchList[item.key] = nil
                    removed = removed + 1
                end
            end
        end
    end
    return removed
end

-- Re-importing a seed whose coordinates changed between scrapes (e.g. The Prophet
-- moved from one loc to another) leaves the OLD point-keyed seed watch behind:
-- createAllaSeedWatch is idempotent per point key, and collapseDuplicateSourceWatches
-- only removes non-seed twins, so two Alla-sourced watches for the same named persist
-- (the user sees a "double named"). This prunes Alla seed point-watches whose point
-- key is no longer present in the freshly-imported set for that named, while keeping
-- every current point (so legitimate multi-spawn-group nameds are untouched).
-- `importedKeysByName` is name-key -> { pointKey -> true } for the zone just imported.
ux.pruneStaleSeedWatches = function(zoneKey, importedKeysByName)
    zoneKey = tostring(zoneKey or ''):lower()
    if zoneKey == '' or type(importedKeysByName) ~= 'table' then return 0 end
    local removed = 0
    for key, watch in pairs(watchList or {}) do
        if type(watch) == 'table'
            and tostring(watch.zone or ''):lower() == zoneKey
            and ux.watchIsSeedSourced(watch) then
            local named = ux.seedNameKey(watch.label or watch.desiredName or '')
            local keepSet = named ~= '' and importedKeysByName[named] or nil
            if keepSet then
                local pointKey = tostring(watch.seedPointLabel or watch.lastSpawnPointKey or '')
                if pointKey ~= '' and not keepSet[pointKey] then
                    watchList[key] = nil
                    removed = removed + 1
                end
            end
        end
    end
    return removed
end

local function zoneAlertsDisabled()
    return ux.disabledZones[currentZoneShort()] == true
end

local function wakeAlertPopup()
    if zoneAlertsDisabled() then return end
    ux.showAlertPopup = true
    ux.alertPopupClosedAt = 0
end

local function addAlert(msg, suppressEcho)
    local stamp = os.date('%H:%M:%S')
    table.insert(alertLog, 1, { text = msg, time = stamp })
    while #alertLog > 12 do table.remove(alertLog) end
    if alertEcho and suppressEcho ~= true then
        local plain = tostring(msg or ''):gsub('\\a[%a]', '')
        if plain:find('Spawn alert:', 1, true) then return end
        local echo = msg
        if plain:find('Killed:', 1, true) or plain:find('PH killed:', 1, true)
            or plain:find('Point emptied:', 1, true) then
            echo = string.format('[%s] %s', stamp, tostring(msg or ''))
        end
        chat(echo)
    end
end

local function normalizedAnnounceCommand()
    local cmd = trim(tostring(announceMethod or '/echo'))
    if cmd == '' then cmd = '/echo' end
    if cmd:sub(1, 1) ~= '/' then cmd = '/' .. cmd end
    local lowered = cmd:lower()
    if lowered == '/s' then return '/say' end
    return cmd
end

local function announceText(text)
    if zoneAlertsDisabled() then return end
    mq.cmdf('%s [TurboMobs] %s', normalizedAnnounceCommand(), tostring(text or ''))
end

ux.normalizedPopupCommand = function()
    local cmd = trim(tostring(ux.spawnPopupCommand or '/popup'))
    if cmd == '' then cmd = '/popup' end
    if cmd:sub(1, 1) ~= '/' then cmd = '/' .. cmd end
    return cmd
end

ux.showSpawnPopup = function(name)
    if zoneAlertsDisabled() then return end
    if ux.spawnPopup ~= true then return end
    local mobName = trim(tostring(name or ''))
    if mobName == '' then return end
    mq.cmdf('%s SPAWN: %s!', ux.normalizedPopupCommand(), mobName)
end

ux.highlightMapSpawn = function(spawnRef)
    if zoneAlertsDisabled() then return end
    if ux.mapHighlight ~= true then return end
    local filter = ''
    if type(spawnRef) == 'table' and tonumber(spawnRef.id or 0) and tonumber(spawnRef.id or 0) ~= 0 then
        filter = string.format('id %d', tonumber(spawnRef.id) or 0)
    else
        local mobName = trim(tostring(spawnRef or ''))
        if mobName == '' then return end
        filter = '"' .. mobName:gsub('"', '') .. '"'
    end
    local c = type(ux.mapHighlightColor) == 'table' and ux.mapHighlightColor or {160, 64, 255}
    local r = math.max(0, math.min(255, tonumber(c[1]) or 160))
    local g = math.max(0, math.min(255, tonumber(c[2]) or 64))
    local b = math.max(0, math.min(255, tonumber(c[3]) or 255))
    mq.cmd('/squelch /highlight reset')
    mq.cmdf('/squelch /highlight %s color %d %d %d pulse', filter, r, g, b)
end

ux.refreshWatchedMapHighlights = function(force)
    if zoneAlertsDisabled() then ux.lastMapHighlightCount = 0; return end
    if ux.mapHighlight ~= true then ux.lastMapHighlightCount = 0; return end
    local now = nowMs()
    if not force and (now - (tonumber(ux.lastMapHighlightRefreshMs) or 0)) < 5000 then return end

    local filters = {}
    local seen = {}
    local currentKeys, currentWatches = ux.currentZoneWatchPairs()
    for i, watch in ipairs(currentWatches or {}) do
        local watchKey = currentKeys and currentKeys[i] or tostring(watch)
        local row = (ux.cachedWatchPresenceRow and ux.cachedWatchPresenceRow(watch, watchKey) or ux.findWatchPresenceRow(watch))
            or (ux.cachedWatchOccupantRow and ux.cachedWatchOccupantRow(watch, watchKey) or ux.watchOccupantRow(watch, watchKey))
        if row and tonumber(row.id or 0) and tonumber(row.id or 0) ~= 0 then
            local key = 'id:' .. tostring(row.id)
            if not seen[key] then
                seen[key] = true
                table.insert(filters, string.format('id %d', tonumber(row.id) or 0))
            end
        else
            local name = trim(tostring(row and row.name or ''))
            if name ~= '' then
                local key = 'name:' .. name:lower()
                if not seen[key] then
                    seen[key] = true
                    table.insert(filters, '"' .. name:gsub('"', '') .. '"')
                end
            end
        end
        if #filters >= 8 then break end
    end

    local highlightKey = table.concat(filters, '|')
    ux.lastMapHighlightCount = #filters
    if highlightKey == '' then return end
    if not force and highlightKey == tostring(ux.lastMapHighlightKey or '') then
        ux.lastMapHighlightRefreshMs = now
        return
    end

    local c = type(ux.mapHighlightColor) == 'table' and ux.mapHighlightColor or {160, 64, 255}
    local r = math.max(0, math.min(255, tonumber(c[1]) or 160))
    local g = math.max(0, math.min(255, tonumber(c[2]) or 64))
    local b = math.max(0, math.min(255, tonumber(c[3]) or 255))
    mq.cmd('/squelch /highlight reset')
    for _, filter in ipairs(filters) do
        mq.cmdf('/squelch /highlight %s color %d %d %d pulse', filter, r, g, b)
    end
    ux.lastMapHighlightKey = highlightKey
    ux.lastMapHighlightRefreshMs = now
end

local function announceTargetWatch()
    if zoneAlertsDisabled() then return end
    mq.cmdf('%s [TurboMobs] %%T added to watchlist at %s', normalizedAnnounceCommand(), localTimeText())
end

local function buildBeepArg()
    local name = trim(tostring(respawnSoundName or ''))
    if name == '' then return nil end
    -- Auto-append .wav if no extension is present.
    if not name:lower():match('%.%w+$') then
        name = name .. '.wav'
    end
    local prefix = trim(tostring(respawnSoundPath or ''))
    -- If prefix is set, ensure it ends with a single slash. Normalize backslashes.
    if prefix ~= '' then
        prefix = prefix:gsub('\\', '/')
        if not prefix:match('/$') then prefix = prefix .. '/' end
    end
    return prefix .. name
end

local function playRespawnSound()
    if zoneAlertsDisabled() then return end
    if not respawnSound then return end
    local now = nowMs()
    if (now - (ux.lastRespawnSoundMs or 0)) < (ux.respawnSoundCooldownMs or 1500) then return end
    ux.lastRespawnSoundMs = now
    local arg = buildBeepArg()
    if not arg then
        mq.cmd('/timed 1 /beep')
    else
        mq.cmdf('/timed 1 /beep %s', arg)
    end
end

local function rememberWatchLocation(watch, row)
    if not watch or not row then return end
    watch.lastSpawnPointKey = spawnPointKey(row)
    watch.lastX = row.x
    watch.lastY = row.y
    watch.lastZ = row.z
    watch.lastSpawnId = row.id
end

ux.rememberWatchLiveMatch = function(watch, row)
    if not watch or not row then return end
    local rowPointKey = spawnPointKey(row)
    if not watch.lastSpawnPointKey or watch.lastSpawnPointKey == '' or watch.lastSpawnPointKey == rowPointKey then
        rememberWatchLocation(watch, row)
        return
    end
    watch.lastSpawnId = row.id
end

ux.smartDesiredName = function(watch)
    return tostring((watch and (watch.desiredName or watch.label)) or ''):lower()
end

ux.watchTrackingMode = function(watch)
    local mode = tostring(watch and watch.trackingMode or ''):lower()
    if mode == 'name' or mode == 'point' or mode == 'area' or mode == 'roamer' then return mode end
    if watch and (tonumber(watch.areaRadius) or 0) > 0 then return 'area' end
    if ux.watchHasPoint and ux.watchHasPoint(watch) then return 'point' end
    return 'name'
end

local function normalizeWatchNameList(list)
    local out, seen = {}, {}
    if type(list) == 'table' then
        for _, value in ipairs(list) do
            local name = trim(tostring(value or ''))
            local key = name:lower()
            if name ~= '' and not seen[key] then
                seen[key] = true
                table.insert(out, name)
            end
        end
    else
        local text = tostring(list or ''):gsub('\r', '\n')
        text = text:gsub(';', '\n'):gsub(',', '\n')
        for raw in text:gmatch('[^\n]+') do
            local name = trim(raw)
            local key = name:lower()
            if name ~= '' and not seen[key] then
                seen[key] = true
                table.insert(out, name)
            end
        end
    end
    return out
end
ux.normalizeWatchNameList = normalizeWatchNameList

ux.watchNameListText = function(list)
    return table.concat(normalizeWatchNameList(list), '\n')
end

ux.nameMatchesOtherNamedWatch = function(watch, name)
    local needle = ux.seedNameKey and ux.seedNameKey(name) or trim(tostring(name or '')):lower()
    if needle == '' then return false end
    local index = ux.watchIndex
    if not index or type(index.namedNames) ~= 'table' then
        ux.rebuildWatchIndex()
        index = ux.watchIndex or {}
    end
    local matches = index.namedNames and index.namedNames[needle]
    if not matches then return false end
    for other in pairs(matches) do
        if other ~= watch then return true end
    end
    return false
end

-- A handful of rare camps have nameds that are each other's placeholders (e.g.
-- Pyzjn / Varsoon / Yollis Jenkins share one spawn in Qeynos Hills, listed as
-- each other's PHs in the Alla seed). The blanket "a named is never a PH" guard
-- is correct for accidental pollution (a wandering named captured via Assign PH)
-- but wrong for these seed-sanctioned cases. `watch.seedPhNames` records the PH
-- list as it came from the seed, so we can tell a legitimate named-PH from noise.
ux.phNameSeedSanctioned = function(watch, name)
    if type(watch) ~= 'table' or type(watch.seedPhNames) ~= 'table' then return false end
    local key = ux.seedNameKey and ux.seedNameKey(name) or trim(tostring(name or '')):lower()
    if key == '' then return false end
    for _, n in ipairs(watch.seedPhNames) do
        local nk = ux.seedNameKey and ux.seedNameKey(n) or trim(tostring(n or '')):lower()
        if nk == key then return true end
    end
    return false
end

-- Strip invalid placeholder names from stored watches. A named is never a PH for
-- another named, nor for itself, so remove any phNames entry that matches the
-- watch's own desired name or another tracked named. Genuine trash PHs
-- ("a giant rat") are kept. Returns the number of entries removed.
ux.sanitizeWatchPhNames = function()
    local removed = 0
    for _, watch in pairs(watchList or {}) do
        if type(watch) == 'table' and type(watch.phNames) == 'table' and #watch.phNames > 0 then
            local desired = tostring(watch.desiredName or watch.label or ''):lower()
            local kept = {}
            for _, name in ipairs(watch.phNames) do
                local clean = trim(tostring(name or ''))
                local key = clean:lower()
                if clean == '' then
                    -- drop empties silently
                elseif key == desired then
                    removed = removed + 1
                elseif ux.nameMatchesOtherNamedWatch(watch, clean)
                    and not ux.phNameSeedSanctioned(watch, clean) then
                    -- another tracked named that the seed does NOT list as a PH here
                    -- (pollution) -> drop. Seed-sanctioned named-PHs are kept.
                    removed = removed + 1
                else
                    table.insert(kept, clean)
                end
            end
            watch.phNames = kept
        end
    end
    return removed
end

-- Weak-keyed memo for watchPhNameSet. Building a watch's PH name set is
-- relatively expensive (list normalization, point-entry lookups, named-watch
-- checks) and it is called in tight per-row/per-watch loops. The cache is keyed
-- by ux.watchGeneration so it transparently invalidates whenever the watch set
-- or current zone changes (see rebuildWatchIndex).
ux._phNameSetCache = ux._phNameSetCache or setmetatable({}, { __mode = 'k' })

ux.watchPhNameSet = function(watch)
    if not watch then return {} end
    local gen = ux.watchGeneration or 0
    local cached = ux._phNameSetCache[watch]
    if cached and cached.gen == gen and type(cached.set) == 'table' then
        return cached.set
    end
    local set = {}
    for _, name in ipairs(normalizeWatchNameList(watch and watch.phNames or {})) do
        set[name:lower()] = true
    end
    for _, name in ipairs(normalizeWatchNameList(watch and watch.seedPhNames or {})) do
        set[name:lower()] = true
    end
    local pointEntry = ux.pointEntryForWatch and ux.pointEntryForWatch(watch) or nil
    local desired = ux.seedNameKey and ux.seedNameKey(watch and (watch.label or watch.desiredName) or '') or tostring(watch and watch.label or ''):lower()
    local function addImportedPh(name)
        local rawName = trim(tostring(name or ''))
        local isFabled = rawName:lower():match('^the%s+fabled%s+') ~= nil
        local key = ux.seedNameKey and ux.seedNameKey(name) or tostring(name or ''):lower()
        if key == '' or (key == desired and not isFabled) then return end
        local sanctioned = ux.phNameSeedSanctioned and ux.phNameSeedSanctioned(watch, name)
        if not sanctioned then
            if ux.nameMatchesOtherNamedWatch and ux.nameMatchesOtherNamedWatch(watch, name) then return end
            if ux.labelLooksNamed and ux.labelLooksNamed(name) and not isFabled then return end
        end
        set[tostring(name or ''):lower()] = true
    end
    if type(pointEntry) == 'table' then
        for _, name in ipairs(normalizeWatchNameList(pointEntry.ph_names or {})) do
            addImportedPh(name)
        end
        -- Do not promote every "seen here" name on a seed point into a PH candidate;
        -- that pulls zone-wide trash (e.g. a necro acolyte from another camp) onto
        -- unrelated named watches. Learning watches still widen from names[].
        if ux.watchPointConfidence(watch) ~= 'trusted' then
            for _, name in ipairs(normalizeWatchNameList(pointEntry.names or {})) do
                addImportedPh(name)
            end
        end
    end
    ux._phNameSetCache[watch] = { gen = gen, set = set }
    return set
end

ux.currentZonePHLookup = function()
    local zone = currentZoneShort()
    local gen = tonumber(ux.watchGeneration) or 0
    local cached = ux._currentZonePHLookup
    if cached and cached.zone == zone and cached.gen == gen then return cached end

    local lookup = {
        zone = zone,
        gen = gen,
        byPoint = {},
        byName = {},
    }
    local _, currentWatches = ux.currentZoneWatchPairs()
    for _, watch in ipairs(currentWatches or {}) do
        if type(watch) == 'table' and watch.isUp ~= true then
            local pointKey = tostring(watch.lastSpawnPointKey or '')
            if pointKey ~= '' then lookup.byPoint[pointKey] = true end
            local set = ux.watchPhNameSet(watch)
            for name in pairs(set or {}) do
                name = tostring(name or ''):lower()
                if name ~= '' then
                    local bucket = lookup.byName[name]
                    if not bucket then
                        bucket = {}
                        lookup.byName[name] = bucket
                    end
                    table.insert(bucket, watch)
                end
            end
        end
    end
    ux._currentZonePHLookup = lookup
    return lookup
end

ux.rowWithinWatchArea = function(watch, row)
    if not watch or not row then return false end
    local radius = tonumber(watch.areaRadius) or 0
    if radius <= 0 then radius = tonumber(ux.defaultPointOccupantRadius) or 30 end
    if watch.lastX == nil or watch.lastY == nil or row.x == nil or row.y == nil then return false end
    local dx = (tonumber(row.x) or 0) - (tonumber(watch.lastX) or 0)
    local dy = (tonumber(row.y) or 0) - (tonumber(watch.lastY) or 0)
    return math.sqrt(dx * dx + dy * dy) <= radius
end

ux.rowIsPhForWatch = function(watch, row)
    if not watch or not row then return false end
    if ux.rowIsMutualSeedNamedForSibling and ux.rowIsMutualSeedNamedForSibling(watch, row) then return false end
    local set = ux.watchPhNameSet(watch)
    local name = tostring(row.name or ''):lower()
    if name == '' or not set[name] then return false end
    local mode = ux.watchTrackingMode(watch)
    if mode == 'area' then return ux.rowWithinWatchArea(watch, row) end
    if ux.watchHasPoint(watch) and watch.lastSpawnPointKey == spawnPointKey(row) then return true end
    -- Whenever the watch has any anchor location, require the candidate to be near
    -- it. This keeps the Named/PH filter from flagging every same-named trash mob in
    -- the zone (e.g. all "orc centurion") when only the one occupying the watched
    -- spawn point is the real placeholder.
    if tonumber(watch.lastX) ~= nil and tonumber(watch.lastY) ~= nil then
        local dist = ux.rowDistanceFromLoc(row, watch.lastX, watch.lastY)
        return dist ~= nil and dist <= ux.watchAnchorRadius(watch)
    end
    return true
end

-- True when a live spawn is a real placeholder for this watch's camp (not a distant
-- stale id or random mob that merely shares a zone-wide PH name).
ux.rowIsPlaceholderAtWatchCamp = function(watch, row)
    if not watch or not row or not ux.rowIsPhForWatch(watch, row) then return false end
    if not ux.watchHasPoint(watch) then return true end
    local rowKey = spawnPointKey(row)
    if rowKey and watch.lastSpawnPointKey == rowKey then return true end
    return ux.rowWithinWatchAnchor(watch, row)
end

-- Zone-wide PH allocation: assign shared trash PH names (e.g. "a restless skeleton"
-- at five Qey camps) by anchor proximity after in-camp matches are claimed.
ux.watchAllocationKey = function(watch, watchKey)
    if watchKey and tostring(watchKey) ~= '' then return tostring(watchKey) end
    if not watch then return '' end
    local zone = tostring(watch.zone or currentZoneShort() or ''):lower()
    local point = tostring(watch.lastSpawnPointKey or '')
    local name = tostring(watch.desiredName or watch.label or ''):lower()
    if zone ~= '' and point ~= '' and name ~= '' then
        return zone .. '|' .. point .. '|' .. name
    end
    return tostring(watch)
end

ux.rowEligiblePhForWatch = function(watch, row)
    if not watch or not row then return false end
    if ux.rowIsDesiredForWatch(watch, row) then return false end
    if ux.rowIsMutualSeedNamedForSibling and ux.rowIsMutualSeedNamedForSibling(watch, row) then return false end
    local set = ux.watchPhNameSet(watch)
    local name = tostring(row.name or ''):lower()
    return name ~= '' and set[name] == true
end

ux.ensureZonePhAllocation = function()
    local rev = tonumber(ux.spawnDataRevision) or 0
    if ux.phAllocationCache and ux.phAllocationCache.rev == rev then return end
    local function pickPoolPhRow(pointEntries, candidates, claimedIds, byKey)
        if not pointEntries or #pointEntries == 0 then return nil end
        local px, py = nil, nil
        for _, entry in ipairs(pointEntries) do
            local w = entry.watch
            if tonumber(w.lastX) ~= nil and tonumber(w.lastY) ~= nil then
                px, py = w.lastX, w.lastY
                break
            end
        end
        local poolKeys = {}
        for _, entry in ipairs(pointEntries) do poolKeys[entry.key] = true end
        local function rowEligibleForPool(row)
            for _, entry in ipairs(pointEntries) do
                if ux.rowEligiblePhForWatch(entry.watch, row) then return true end
            end
            return false
        end
        local function rowScore(row)
            if not rowEligibleForPool(row) then return nil end
            local atAnchor = false
            for _, entry in ipairs(pointEntries) do
                if ux.rowIsPlaceholderAtWatchCamp(entry.watch, row) then
                    atAnchor = true
                    break
                end
            end
            if not atAnchor then return nil end
            local dist = px and (ux.rowDistanceFromLoc(row, px, py) or math.huge) or math.huge
            return dist
        end
        local bestRow, bestScore = nil, nil
        local seenId = {}
        for _, entry in ipairs(pointEntries) do
            local row = byKey[entry.key]
            if row then
                local id = tonumber(row.id) or 0
                if id > 0 and not seenId[id] then
                    seenId[id] = true
                    local score = rowScore(row)
                    if score and (not bestScore or score < bestScore) then
                        bestRow, bestScore = row, score
                    end
                end
            end
        end
        for _, row in ipairs(candidates) do
            local id = tonumber(row.id) or 0
            if id > 0 and not seenId[id] then
                seenId[id] = true
                local claim = claimedIds[id]
                if claim and not poolKeys[claim] then goto continue_pool_candidate end
                local score = rowScore(row)
                if score and (not bestScore or score < bestScore) then
                    bestRow, bestScore = row, score
                end
                ::continue_pool_candidate::
            end
        end
        return bestRow
    end
    local byKey = {}
    local claimedIds = {}
    local currentKeys, currentWatches = ux.currentZoneWatchPairs()
    local entries = {}
    for i, watch in ipairs(currentWatches or {}) do
        if type(watch) == 'table' and ux.watchHasPoint(watch) then
            local phSet = ux.watchPhNameSet(watch)
            local hasPh = false
            for _ in pairs(phSet) do hasPh = true; break end
            if hasPh then
                table.insert(entries, {
                    watch = watch,
                    key = ux.watchAllocationKey(watch, currentKeys and currentKeys[i]),
                })
            end
        end
    end
    local candidates = {}
    local seenId = {}
    for _, row in ipairs(allSpawns or {}) do
        if passWatchPresenceFilters(row) then
            local id = tonumber(row.id) or 0
            if id > 0 and not seenId[id] then
                seenId[id] = true
                table.insert(candidates, row)
            end
        end
    end
    local anchorMatches = {}
    for _, entry in ipairs(entries) do
        local watch = entry.watch
        for _, row in ipairs(candidates) do
            if ux.rowEligiblePhForWatch(watch, row) and ux.rowIsPlaceholderAtWatchCamp(watch, row) then
                table.insert(anchorMatches, {
                    entry = entry,
                    row = row,
                    id = tonumber(row.id) or 0,
                    dist = ux.rowDistanceFromLoc(row, watch.lastX, watch.lastY) or math.huge,
                })
            end
        end
    end
    table.sort(anchorMatches, function(a, b)
        if a.dist ~= b.dist then return a.dist < b.dist end
        return tostring(a.entry.key) < tostring(b.entry.key)
    end)
    for _, match in ipairs(anchorMatches) do
        if not byKey[match.entry.key] and match.id > 0 and not claimedIds[match.id] then
            byKey[match.entry.key] = match.row
            claimedIds[match.id] = match.entry.key
        end
    end
    local byPoint = {}
    for _, entry in ipairs(entries) do
        local pointKey = tostring(entry.watch.lastSpawnPointKey or '')
        if pointKey ~= '' then
            byPoint[pointKey] = byPoint[pointKey] or {}
            table.insert(byPoint[pointKey], entry)
        end
    end
    local roamMatches = {}
    for _, entry in ipairs(entries) do
        local pointKey = tostring(entry.watch.lastSpawnPointKey or '')
        local poolSize = pointKey ~= '' and #(byPoint[pointKey] or {}) or 1
        if poolSize <= 1 and not byKey[entry.key] then
            local watch = entry.watch
            for _, row in ipairs(candidates) do
                if ux.rowEligiblePhForWatch(watch, row) then
                    if ux.watchUsesFixedPointAnchor(watch)
                        and not ux.rowIsPlaceholderAtWatchCamp(watch, row)
                        and not ux.rowAtWatchAnchor(watch, row) then
                        goto continue_roam_row
                    end
                    local id = tonumber(row.id) or 0
                    if id > 0 and not claimedIds[id] then
                        table.insert(roamMatches, {
                            entry = entry,
                            row = row,
                            id = id,
                            dist = ux.rowDistanceFromLoc(row, watch.lastX, watch.lastY) or math.huge,
                        })
                    end
                end
                ::continue_roam_row::
            end
        end
    end
    table.sort(roamMatches, function(a, b)
        if a.dist ~= b.dist then return a.dist < b.dist end
        return tostring(a.entry.key) < tostring(b.entry.key)
    end)
    for _, match in ipairs(roamMatches) do
        if not byKey[match.entry.key] and not claimedIds[match.id] then
            byKey[match.entry.key] = match.row
            claimedIds[match.id] = match.entry.key
        end
    end
    for pointKey, pointEntries in pairs(byPoint) do
        if #pointEntries > 1 then
            for _, entry in ipairs(pointEntries) do
                local oldRow = byKey[entry.key]
                if oldRow then
                    local oid = tonumber(oldRow.id) or 0
                    if oid > 0 and claimedIds[oid] == entry.key then
                        claimedIds[oid] = nil
                    end
                    byKey[entry.key] = nil
                end
            end
            local poolRow = pickPoolPhRow(pointEntries, candidates, claimedIds, byKey)
            if poolRow then
                local poolId = tonumber(poolRow.id) or 0
                for _, entry in ipairs(pointEntries) do
                    if ux.rowEligiblePhForWatch(entry.watch, poolRow) then
                        byKey[entry.key] = poolRow
                    end
                end
                if poolId > 0 then claimedIds[poolId] = 'pool:' .. pointKey end
            end
        end
    end
    ux.phAllocationCache = { rev = rev, byKey = byKey }
end

ux.getAllocatedPhRow = function(watch, watchKey, opts)
    if not watch then return nil end
    ux.ensureZonePhAllocation()
    local cache = ux.phAllocationCache
    if not cache or type(cache.byKey) ~= 'table' then return nil end
    local row = cache.byKey[ux.watchAllocationKey(watch, watchKey)]
    if not row then return nil end
    if opts and opts.raw == true then return row end
    if ux.rowCountsAsWatchCampPh(watch, row, opts or { allowStickyPull = true }) then return row end
    return nil
end

ux.annotateDerivedSpawnRows = function(rows)
    rows = rows or allSpawns or {}
    local watchGen = tonumber(ux.watchGeneration) or 0
    local spawnRev = tonumber(ux.spawnDataRevision) or 0
    local lookup = ux.currentZonePHLookup and ux.currentZonePHLookup() or nil
    if ux.ensureZonePhAllocation then ux.ensureZonePhAllocation() end
    local allocatedById = {}
    local allocation = ux.phAllocationCache and ux.phAllocationCache.byKey or nil
    if type(allocation) == 'table' then
        for _, row in pairs(allocation) do
            local id = tonumber(row and row.id or 0) or 0
            if id > 0 then allocatedById[id] = true end
        end
    end

    for _, row in ipairs(rows) do
        if row then
            row._tmDerivedWatchGen = watchGen
            row._tmDerivedSpawnRev = spawnRev
            row._tmIsPH = false
            if passWatchPresenceFilters(row) then
                local id = tonumber(row.id) or 0
                if id > 0 and allocatedById[id] then
                    row._tmIsPH = true
                else
                    local pointKey = spawnPointKey(row)
                    if pointKey and pointKey ~= '' and lookup and lookup.byPoint and lookup.byPoint[pointKey] then
                        row._tmIsPH = true
                    else
                        local name = row.name_l or tostring(row.name or ''):lower()
                        local candidates = lookup and lookup.byName and lookup.byName[name] or nil
                        if candidates then
                            for _, watch in ipairs(candidates) do
                                if watch and ux.rowIsPhForWatch(watch, row) then
                                    row._tmIsPH = true
                                    break
                                end
                            end
                        end
                    end
                end
            end
            row._tmNamedOrPH = row.named == true or ux.labelLooksNamed(row.name) or row._tmIsPH == true
        end
    end
end

ux.findWatchPhPresenceRow = function(watch, watchKey)
    if not watch then return nil end
    local roaming = ux.liveRoamingPhRow and ux.liveRoamingPhRow(watch) or nil
    if roaming then return roaming end
    local allocated = ux.getAllocatedPhRow(watch, watchKey, { allowStickyPull = true })
    if allocated then return allocated end
    local set = ux.watchPhNameSet(watch)
    local hasNames = false
    for _ in pairs(set) do hasNames = true; break end
    if not hasNames then return nil end
    local best, bestDist = nil, math.huge
    -- Track candidates that pass the name check but fail the anchor-radius check.
    -- If exactly ONE such candidate exists in the scan results it is unambiguous
    -- (only one mob with this PH name is in the zone), so accept it regardless of
    -- how far it has wandered.  If multiple exist we keep the strict radius to
    -- avoid picking the wrong camp's PH.
    local roamCandidate, roamCount = nil, 0
    local mode = ux.watchTrackingMode(watch)
    for _, row in ipairs(allSpawns or {}) do
        if passWatchPresenceFilters(row) and set[tostring(row.name or ''):lower()] then
            if ux.rowIsDesiredForWatch(watch, row) then goto continue_ph_scan end
            if ux.rowIsMutualSeedNamedForSibling and ux.rowIsMutualSeedNamedForSibling(watch, row) then goto continue_ph_scan end
            if ux.rowIsPlaceholderAtWatchCamp(watch, row) then
                if mode == 'area' then
                    return row
                elseif mode == 'point' and ux.watchHasPoint(watch) then
                    local dist = ux.rowDistanceFromLoc(row, watch.lastX, watch.lastY) or math.huge
                    if dist < bestDist then
                        best, bestDist = row, dist
                    end
                else
                    return row
                end
            elseif mode == 'point' and ux.watchHasPoint(watch) then
                roamCount = roamCount + 1
                roamCandidate = row
            end
        end
        ::continue_ph_scan::
    end
    -- Prefer the in-radius winner.  Only fall back to the single roaming candidate if
    -- no OTHER watch in the current zone also lists that PH name — otherwise the mob
    -- is ambiguous (e.g. "a restless skeleton" shared by five named watches) and
    -- accepting it here would incorrectly mark all five camps as occupied.
    if best then return best end
    if roamCount == 1 and roamCandidate then
        local candidateName = tostring(roamCandidate.name or ''):lower()
        local unambiguous = ux.phNameIsUniqueToCurrentWatch and ux.phNameIsUniqueToCurrentWatch(watch, candidateName)
        if mode == 'roamer' or unambiguous then return roamCandidate end
    end
    return nil
end

-- Delegated to turbomobs_logic (pure, tested). Identical to the original.
ux.watchHasPoint = TM.watchHasPoint

ux.watchPointConfidence = function(watch)
    if not watch or not ux.watchHasPoint(watch) then return 'none' end
    if watch.pointTrusted == true then return 'trusted' end
    local confidence = tostring(watch.pointConfidence or '')
    if confidence == 'trusted' or confidence == 'learning' or confidence == 'live' then return confidence end
    if watch.source == 'Zone Intel' or watch.source == 'SpawnMaster' then return 'trusted' end
    return 'learning'
end

ux.watchPointTrusted = function(watch)
    return ux.watchPointConfidence(watch) == 'trusted'
end

ux.watchUsesFixedPointAnchor = function(watch)
    if not (watch and ux.watchHasPoint and ux.watchHasPoint(watch)) then return false end
    local mode = ux.watchTrackingMode and ux.watchTrackingMode(watch) or tostring(watch.trackingMode or ''):lower()
    if mode ~= 'point' then return false end
    if tonumber(watch.areaRadius or 0) > 0 then return false end
    return ux.watchPointTrusted and ux.watchPointTrusted(watch)
end

ux.rowAtWatchAnchor = function(watch, row)
    if not watch or not row then return false end
    if not (ux.watchHasPoint and ux.watchHasPoint(watch)) then return true end
    local rowKey = spawnPointKey(row)
    if rowKey and rowKey == tostring(watch.lastSpawnPointKey or '') then return true end
    return ux.rowWithinWatchAnchor and ux.rowWithinWatchAnchor(watch, row) or false
end

ux.noteWatchStaleOccupant = function(watch, text)
    text = tostring(text or '')
    ux.lastStaleOccupantText = text
    if watch then watch.lastStaleOccupantText = text end
end

ux.clearRoamingPh = function(watch)
    if not watch then return end
    watch.roamingPhSpawnId = 0
    watch.roamingPhName = ''
    watch.roamingPhConfirmedAt = 0
    watch._lastRoamingPhLogKey = ''
end

ux.setRoamingPh = function(watch, row, reason)
    if not watch or not row then return false end
    local id = tonumber(row.id or 0) or 0
    if id <= 0 then return false end
    if ux.findZoneNamedPresenceRow and ux.findZoneNamedPresenceRow(watch) then
        return false
    end
    local name = tostring(row.name or '')
    local changed = tonumber(watch.roamingPhSpawnId or 0) ~= id
        or tostring(watch.roamingPhName or '') ~= name
    watch.roamingPhSpawnId = id
    watch.roamingPhName = name
    watch.roamingPhConfirmedAt = os.time()
    watch.currentName = name
    watch.currentIsDesired = false
    watch.isUp = false
    watch.alertArmed = watch.initialResolved == true
    watch.emptySeenCount = 0
    watch.expectedRespawnAt = 0
    watch.expectedRespawnSource = ''
    watch.despawnedAt = 0
    watch.killedAtText = ''
    watch.lastTimerBlockedReason = 'roaming PH live'
    local pointKey = tostring(watch.lastSpawnPointKey or '-')
    local rowPointKey = tostring(spawnPointKey(row) or '-')
    local logKey = table.concat({ tostring(id), name, tostring(reason or '-'), pointKey, rowPointKey }, '|')
    if ux.recordPerfLine and tostring(watch._lastRoamingPhLogKey or '') ~= logKey then
        watch._lastRoamingPhLogKey = logKey
        ux.recordPerfLine(string.format(
            'Watch roaming PH live label=%s id=%s name=%s reason=%s point=%s current=%s',
            tostring(watch.label or watch.desiredName or '-'),
            tostring(id),
            tostring(name ~= '' and name or '-'),
            tostring(reason or '-'),
            pointKey,
            rowPointKey))
    end
    return changed
end

ux.liveRoamingPhRow = function(watch)
    if not watch then return nil end
    local id = tonumber(watch.roamingPhSpawnId or 0) or 0
    if id <= 0 then return nil end
    local row = ux.spawnIndex and ux.spawnIndex.byId and ux.spawnIndex.byId[id] or nil
    if not row or not passWatchPresenceFilters(row) then return nil end
    local name = tostring(row.name or ''):lower()
    local phSet = ux.watchPhNameSet and ux.watchPhNameSet(watch) or {}
    if name == '' or not phSet[name] then return nil end
    if ux.rowIsDesiredForWatch and ux.rowIsDesiredForWatch(watch, row) then return nil end
    return row
end

ux.phNameIsUniqueToCurrentWatch = function(watch, name)
    name = tostring(name or ''):lower()
    if name == '' then return false end
    local _, currentWatches = ux.currentZoneWatchPairs()
    for _, other in ipairs(currentWatches or {}) do
        if other ~= watch then
            local otherSet = ux.watchPhNameSet and ux.watchPhNameSet(other) or {}
            if otherSet[name] then return false end
        end
    end
    return true
end

-- True when a live row should count as this watch's camp PH (state + display).
-- Zone-wide same-name mobs are rejected unless they occupy the saved spawn point,
-- except a spawn ID already confirmed at this anchor and since pulled away.
ux.rowCountsAsWatchCampPh = function(watch, row, opts)
    opts = opts or {}
    if not watch or not row then return false end
    if ux.rowIsDesiredForWatch(watch, row) then return false end
    if ux.rowIsMutualSeedNamedForSibling and ux.rowIsMutualSeedNamedForSibling(watch, row) then return false end
    local phSet = ux.watchPhNameSet(watch)
    local name = tostring(row.name or ''):lower()
    if name == '' or not phSet[name] then return false end
    local rowId = tonumber(row.id or 0) or 0
    local occupantId = tonumber(watch.occupantSpawnId or 0) or 0
    if opts.allowStickyPull == true and occupantId > 0 and rowId == occupantId
        and watch.occupantConfirmedAtAnchor == true then
        return true
    end
    if opts.allowRoamingPh == true then
        local roamingId = tonumber(watch.roamingPhSpawnId or 0) or 0
        if roamingId > 0 and rowId == roamingId then return true end
        if ux.phNameIsUniqueToCurrentWatch(watch, name) then return true end
    end
    if ux.rowIsPlaceholderAtWatchCamp(watch, row) then return true end
    if ux.rowAtWatchAnchor(watch, row) then return true end
    if ux.watchTrackingMode(watch) == 'area' then
        return ux.rowWithinWatchArea(watch, row)
    end
    if ux.watchUsesFixedPointAnchor and ux.watchUsesFixedPointAnchor(watch) then
        return false
    end
    return ux.rowIsPhForWatch(watch, row)
end

ux.coordsFromPointKey = TM.coordsFromPointKey

ux.repairSeedWatchAnchorDrift = function(zone)
    if not ux.respawnsLoaded then return 0 end
    zone = tostring(zone or currentZoneShort() or ''):lower()
    if zone == '' or zone == 'unknown' then return 0 end
    local zoneTable = respawnsData and respawnsData[zone] or nil
    local points = type(zoneTable) == 'table' and zoneTable._points or nil
    local changed = 0
    for _, watch in pairs(watchList or {}) do
        if type(watch) == 'table' and tostring(watch.zone or ''):lower() == zone
            and ux.watchIsSeedSourced and ux.watchIsSeedSourced(watch)
            and tostring(watch.seedPointLabel or '') ~= ''
            and tostring(watch.lastSpawnPointKey or '') ~= tostring(watch.seedPointLabel or '') then
            local seedPoint = tostring(watch.seedPointLabel or '')
            local pointEntry = type(points) == 'table' and points[seedPoint] or nil
            local x = type(pointEntry) == 'table' and tonumber(pointEntry.x) or nil
            local y = type(pointEntry) == 'table' and tonumber(pointEntry.y) or nil
            local z = type(pointEntry) == 'table' and tonumber(pointEntry.z) or nil
            if x == nil or y == nil then x, y = ux.coordsFromPointKey(seedPoint) end
            if x ~= nil and y ~= nil then
                watch.lastSpawnPointKey = seedPoint
                watch.lastX = x
                watch.lastY = y
                if z ~= nil then watch.lastZ = z end
                watch.pointConfidence = 'trusted'
                watch.pointSamples = math.max(tonumber(watch.pointSamples) or 0, MIN_SAMPLES_FOR_DISPLAY)
                watch.occupantConfirmedAtAnchor = false
                if watch.pointOccupied == true and tostring(watch.currentName or '') ~= '' and watch.currentIsDesired ~= true then
                    watch.pointOccupied = false
                    watch.currentName = ''
                    watch.occupantSpawnId = 0
                    watch.occupantName = ''
                end
                changed = changed + 1
                if ux.recordPerfLine then
                    ux.recordPerfLine(string.format('Seed watch anchor restored label=%s point=%s',
                        tostring(watch.label or watch.desiredName or '-'), seedPoint))
                end
            end
        end
    end
    if changed > 0 then
        ux.markWatchStateDirty()
        if ux.rebuildWatchIndex then ux.rebuildWatchIndex(false) end
        saveWatches()
    end
    return changed
end

ux.updateSmartWatchLearning = function(watch, row)
    if not watch or not row or watch.mode ~= 'smart' then return end
    if not ux.rowIsDesiredForWatch(watch, row) then return end
    local rowPointKey = spawnPointKey(row)
    if not rowPointKey or rowPointKey == '' then return end

    local previousId = tonumber(watch.lastSpawnId or 0) or 0
    local rowId = tonumber(row.id or 0) or 0
    local wasDown = watch.isUp == false
    local newLiveSpawn = previousId > 0 and rowId > 0 and previousId ~= rowId
    local missingPoint = not ux.watchHasPoint(watch)
    local fixedSeedOffAnchor = ux.watchUsesFixedPointAnchor and ux.watchUsesFixedPointAnchor(watch)
        and not (ux.rowAtWatchAnchor and ux.rowAtWatchAnchor(watch, row))

    if fixedSeedOffAnchor then
        if rowId > 0 then watch.lastSpawnId = rowId end
        watch.offAnchorOccupantId = rowId
        watch.offAnchorOccupantName = row.name or ''
        return
    end

    if missingPoint or wasDown or newLiveSpawn then
        watch.lastSpawnPointKey = rowPointKey
        watch.lastX = row.x
        watch.lastY = row.y
        watch.lastZ = row.z
        if missingPoint or wasDown or newLiveSpawn then
            watch.pointSamples = math.min(99, (tonumber(watch.pointSamples) or 0) + 1)
        end
        if (tonumber(watch.pointSamples) or 0) >= 2 then
            watch.pointConfidence = 'trusted'
        elseif watch.pointConfidence ~= 'trusted' then
            watch.pointConfidence = 'learning'
        end
    elseif ux.watchPointConfidence(watch) == 'none' then
        watch.pointConfidence = 'live'
    end

    if rowId > 0 then watch.lastSpawnId = rowId end
end

ux.cachedOccupantRow = function(watch)
    if not ux.watchHasPoint(watch) then return nil end
    local occupantId = tonumber(watch.occupantSpawnId or 0) or 0
    if occupantId == 0 then return nil end
    local byId = ux.spawnIndex and ux.spawnIndex.byId and ux.spawnIndex.byId[occupantId]
    local sparse = ux.isSparseWatchRefresh and ux.isSparseWatchRefresh() or false
    if not byId or not passWatchPresenceFilters(byId) then
        if sparse and watch.occupantConfirmedAtAnchor == true then
            local sticky = ux.resolveStickyWatchOccupant and ux.resolveStickyWatchOccupant(watch, occupantId) or nil
            if sticky then return sticky end
        end
        if sparse then return nil end
        watch.lastOccupantName = tostring(watch.occupantName or watch.currentName or '')
        watch.lastOccupantId = occupantId
        watch.lastOccupiedAt = os.time()
        ux.noteWatchStaleOccupant(watch, string.format(
            '%s cached occupant id=%d ignored: spawn missing or filtered for saved point=%s',
            tostring(watch.label or watch.desiredName or '?'),
            occupantId,
            tostring(watch.lastSpawnPointKey or '-')))
        watch.occupantSpawnId = 0
        watch.occupantName = ''
        return nil
    end
    local cachedPoint = spawnPointKey(byId)
    if cachedPoint ~= watch.lastSpawnPointKey then
        -- The cached occupant has moved off the stored anchor point.
        -- If it IS the desired named (the actual target), treat it as a roaming named:
        -- clear the occupant slot so the camp doesn't show as "occupied", and hand
        -- the ID to offAnchorOccupantId so nav / roamer-promotion logic can use it.
        -- If it is NOT the desired named (i.e. it's a PH that wandered from its spawn
        -- origin), the camp is still occupied — return it as-is.
        if ux.rowIsDesiredForWatch and ux.rowIsDesiredForWatch(watch, byId) then
            watch.lastOccupantName = tostring(watch.occupantName or byId.name or '')
            watch.lastOccupantId = occupantId
            watch.lastOccupiedAt = os.time()
            ux.noteWatchStaleOccupant(watch, string.format(
                '%s cached named id=%d still live off anchor: current point=%s saved point=%s',
                tostring(watch.label or watch.desiredName or '?'),
                occupantId,
                tostring(cachedPoint or '-'),
                tostring(watch.lastSpawnPointKey or '-')))
            watch.offAnchorOccupantId = occupantId
            watch.offAnchorOccupantName = watch.occupantName or ''
            watch.occupantSpawnId = 0
            watch.occupantName = ''
            return nil
        end
        -- PH wandered from spawn origin. For fixed trusted point watches, do not
        -- keep a wandered PH attached to the camp; it prevents the camp from
        -- becoming empty and can make unrelated trash look like this point's PH.
        -- Explicit area/roamer behavior can still keep off-anchor occupants.
        if ux.watchUsesFixedPointAnchor and ux.watchUsesFixedPointAnchor(watch) then
            local legacyConfirmedOccupant = watch.pointOccupied == true
                and occupantId > 0
                and tonumber(watch.occupantSpawnId or 0) == occupantId
                and tostring(watch.occupantName or watch.currentName or '') ~= ''
            if watch.occupantConfirmedAtAnchor == true or legacyConfirmedOccupant then
                ux.noteWatchStaleOccupant(watch, string.format(
                    '%s cached PH id=%d still live off anchor after anchor confirmation: current=%s origin=%s',
                    tostring(watch.label or watch.desiredName or '?'),
                    occupantId,
                    tostring(cachedPoint or '-'),
                    tostring(watch.lastSpawnPointKey or '-')))
                watch.occupantConfirmedAtAnchor = true
                ux.setRoamingPh(watch, byId, 'confirmed-id-off-anchor')
                return byId
            end
            watch.lastOccupantName = tostring(watch.occupantName or byId.name or '')
            watch.lastOccupantId = occupantId
            watch.lastOccupiedAt = os.time()
            ux.noteWatchStaleOccupant(watch, string.format(
                '%s cached PH id=%d cleared: off anchor for fixed-point watch current=%s origin=%s',
                tostring(watch.label or watch.desiredName or '?'),
                occupantId,
                tostring(cachedPoint or '-'),
                tostring(watch.lastSpawnPointKey or '-')))
            watch.occupantSpawnId = 0
            watch.occupantName = ''
            watch.occupantConfirmedAtAnchor = false
            return nil
        end
        -- PH wandered from spawn origin. Only keep it as the camp occupant if it
        -- was previously confirmed at the watched anchor; otherwise a same-name
        -- trash mob elsewhere in the zone can get cached as this camp's PH.
        if ux.watchPointTrusted and ux.watchPointTrusted(watch) and watch.occupantConfirmedAtAnchor ~= true then
            watch.lastOccupantName = tostring(watch.occupantName or byId.name or '')
            watch.lastOccupantId = occupantId
            watch.lastOccupiedAt = os.time()
            ux.noteWatchStaleOccupant(watch, string.format(
                '%s cached PH id=%d cleared: off anchor and not confirmed at origin current=%s origin=%s',
                tostring(watch.label or watch.desiredName or '?'),
                occupantId,
                tostring(cachedPoint or '-'),
                tostring(watch.lastSpawnPointKey or '-')))
            watch.occupantSpawnId = 0
            watch.occupantName = ''
            watch.occupantConfirmedAtAnchor = false
            return nil
        end
        ux.noteWatchStaleOccupant(watch, string.format(
            '%s cached PH id=%d off spawn origin but still live: current=%s origin=%s',
            tostring(watch.label or watch.desiredName or '?'),
            occupantId,
            tostring(cachedPoint or '-'),
            tostring(watch.lastSpawnPointKey or '-')))
    end
    return byId
end

ux.watchOccupantRow = function(watch, watchKey)
    local cached = ux.cachedOccupantRow(watch)
    if cached then
        -- For a cached occupant (identity confirmed by spawn ID on a prior scan),
        -- skip the location check in rowIsPhForWatch — the mob may have wandered from
        -- its spawn origin but it is unambiguously the right mob for this camp.
        -- Only verify it's still the named or a known PH name; that prevents a
        -- completely wrong mob from being returned if the spawn ID was recycled.
        if ux.rowIsDesiredForWatch(watch, cached) then return cached end
        local cachedName = tostring(cached.name or ''):lower()
        local phSet = ux.watchPhNameSet and ux.watchPhNameSet(watch) or {}
        if cachedName ~= '' and phSet[cachedName] then return cached end
        return nil
    end
    return ux.watchPointOccupiedRow(watch, watchKey)
end

ux.cachedWatchOccupantRow = function(watch, watchKey)
    if not watch then return nil end
    local rev = tonumber(ux.spawnDataRevision) or 0
    local cache = ux.watchOccupantRowCache
    if not cache or cache.rev ~= rev then
        cache = { rev = rev, byKey = {} }
        ux.watchOccupantRowCache = cache
    end
    local key = tostring(watchKey or watch)
    local stateKey = table.concat({
        tostring(watch.lastSpawnPointKey or ''),
        tostring(watch.occupantSpawnId or 0),
        tostring(watch.roamingPhSpawnId or 0),
        tostring(watch.currentName or ''),
    }, '|')
    local hit = cache.byKey[key]
    if not hit or hit.stateKey ~= stateKey then
        hit = { stateKey = stateKey, row = ux.watchOccupantRow(watch, key) or false }
        cache.byKey[key] = hit
    end
    if hit.row == false then return nil end
    return hit.row
end

ux.liveNamedCanResolveWatch = function(watch, row)
    if not watch or not row then return false end
    local desired = ux.smartDesiredName(watch)
    local rowNameL = tostring(row.name or ''):lower()
    -- Also match rows whose name has a server-appended suffix (e.g. Lazarus HC "(hunter)")
    local rowBaseL = rowNameL:gsub('%s*%([^)]+%)%s*$', '')
    if desired == '' or (desired ~= rowNameL and desired ~= rowBaseL) then
        return false, 'name-mismatch'
    end
    local mode = ux.watchTrackingMode(watch)
    if mode == 'name' or mode == 'roamer' then return true, mode end
    if mode == 'area' then
        if ux.rowWithinWatchArea(watch, row) then return true, 'area' end
        return false, 'outside-area'
    end
    if mode ~= 'point' or not (ux.watchHasPoint and ux.watchHasPoint(watch)) then return true, 'no-anchor' end

    local rowId = tonumber(row.id or 0) or 0
    if rowId > 0 then
        if rowId == (tonumber(watch.occupantSpawnId or 0) or 0)
            or rowId == (tonumber(watch.lastSpawnId or 0) or 0)
            or rowId == (tonumber(watch.lastOccupantId or 0) or 0)
            or rowId == (tonumber(watch.offAnchorOccupantId or 0) or 0) then
            return true, 'tracked-id'
        end
    end
    if ux.rowAtWatchAnchor and ux.rowAtWatchAnchor(watch, row) then return true, 'anchor' end
    return false, 'same-name-off-anchor'
end

ux.recordIgnoredOffAnchorNamed = function(watch, row, reason)
    if not (ux.recordPerfLine and watch and row) then return end
    reason = tostring(reason or 'same-name-off-anchor')
    local key = table.concat({
        reason,
        tostring(watch.label or watch.desiredName or '-'),
        tostring(row.id or 0),
        tostring(row.name or '-'),
        tostring(watch.lastSpawnPointKey or '-'),
    }, '|')
    if tostring(watch._lastIgnoredNamedKey or '') == key then return end
    watch._lastIgnoredNamedKey = key
    ux.recordPerfLine(string.format(
        'Watch same-name off-anchor ignored label=%s id=%s name=%s point=%s reason=%s',
        tostring(watch.label or watch.desiredName or '-'),
        tostring(row.id or '-'),
        tostring(row.name or '-'),
        tostring(watch.lastSpawnPointKey or '-'),
        reason))
end

ux.rowIsDesiredForWatch = function(watch, row)
    local ok = ux.liveNamedCanResolveWatch and ux.liveNamedCanResolveWatch(watch, row) or false
    return ok == true
end

-- Other watches for the same named in this zone (multi spawn-group camps).
ux.watchCampSiblings = function(watch)
    local out = {}
    if not watch then return out end
    local labelKey = ux.seedNameKey and ux.seedNameKey(watch.label or watch.desiredName or '')
        or tostring(watch.label or watch.desiredName or ''):lower()
    if labelKey == '' then return out end
    local zone = tostring(watch.zone or currentZoneShort() or ''):lower()
    local gen = tonumber(ux.watchGeneration) or 0
    local cache = ux._watchCampSiblingsCache
    if not cache or cache.gen ~= gen or cache.zone ~= zone then
        cache = { gen = gen, zone = zone, byName = {} }
        local _, currentWatches = ux.currentZoneWatchPairs()
        for _, other in ipairs(currentWatches or {}) do
            if type(other) == 'table' and ux.watchHasPoint(other) then
                local otherKey = ux.seedNameKey and ux.seedNameKey(other.label or other.desiredName or '')
                    or tostring(other.label or other.desiredName or ''):lower()
                if otherKey ~= '' then
                    local bucket = cache.byName[otherKey]
                    if not bucket then
                        bucket = {}
                        cache.byName[otherKey] = bucket
                    end
                    table.insert(bucket, other)
                end
            end
        end
        ux._watchCampSiblingsCache = cache
    end
    local bucket = cache.byName[labelKey] or {}
    for _, other in ipairs(bucket) do
        if other ~= watch then table.insert(out, other) end
    end
    return out
end

-- Which camp "owns" a live spawn for a point-tracked named. Single-camp nameds
-- (Gnashmaw) match anywhere in the zone (roamers). Multi-camp nameds
-- (Grizzleknot x2, Kroldir x4) assign to whichever seed anchor is closest to
-- the live spawn — not a fixed radius, so SK wanderers still register.
ux.rowClaimsWatchCamp = function(watch, row)
    if not watch or not row then return false end
    if tonumber(watch.lastX) == nil or tonumber(watch.lastY) == nil then return true end
    local dist = ux.rowDistanceFromLoc(row, watch.lastX, watch.lastY)
    if dist == nil then return true end
    local rowKey = spawnPointKey(row)
    if rowKey and watch.lastSpawnPointKey == rowKey then return true end
    local mode = ux.watchTrackingMode and ux.watchTrackingMode(watch) or ''
    local isPoint = mode == 'point' and ux.watchHasPoint and ux.watchHasPoint(watch)
    -- For single-camp nameds: the mob is unique in the zone, so accept it anywhere
    -- (pulled across the zone, roaming, etc.).  For multi-camp nameds (siblings),
    -- use nearest-camp assignment — no fixed radius needed; whichever anchor is
    -- closest owns the spawn.
    local siblings = ux.watchCampSiblings(watch)
    if #siblings == 0 then return true end
    for _, other in ipairs(siblings) do
        local od = ux.rowDistanceFromLoc(row, other.lastX, other.lastY)
        if od and od < dist then return false end
    end
    return true
end

local function findStickyWatchRow(watch, passFn)
    if not watch or watch.isUp ~= true then return nil end
    local id = tonumber(watch.lastSpawnId or 0) or 0
    if id <= 0 then return nil end
    local index = ux.spawnIndex or {}
    local row = index.byId and index.byId[id] or nil
    if not row or not passFn(row) then return nil end
    local desired = ux.smartDesiredName(watch)
    if desired == '' or desired ~= tostring(row.name or ''):lower() then return nil end
    return row
end

-- Distance from the player to a watch's learned/seed anchor (for camp labels).
ux.distanceToWatchAnchor = function(watch, myX, myY)
    if not watch or watch.lastX == nil or watch.lastY == nil then return nil end
    if myX == nil then myX = tonumber(safeCall(function() return mq.TLO.Me.X() end, 0)) or 0 end
    if myY == nil then myY = tonumber(safeCall(function() return mq.TLO.Me.Y() end, 0)) or 0 end
    local dx = (tonumber(watch.lastX) or 0) - myX
    local dy = (tonumber(watch.lastY) or 0) - myY
    return math.sqrt(dx * dx + dy * dy)
end

-- When several watches share a label (multi spawn-group nameds), append a camp
-- suffix so Turbo Watch reads "Grizzleknot · 5121" not two identical rows.
ux.buildWatchCampLabelMap = function()
    local gen = ux.watchGeneration or 0
    local cache = ux.watchCampLabelMap
    if cache and cache.gen == gen and type(cache.map) == 'table' then return cache.map end
    local byLabel = {}
    for key, watch in pairs(watchList or {}) do
        if ux.watchAppliesToCurrentZone and ux.watchAppliesToCurrentZone(watch) then
            local labelKey = ux.seedNameKey and ux.seedNameKey(watch.label or watch.desiredName or '')
                or tostring(watch.label or watch.desiredName or ''):lower()
            if labelKey ~= '' then
                byLabel[labelKey] = byLabel[labelKey] or {}
                table.insert(byLabel[labelKey], { key = key, watch = watch })
            end
        end
    end
    local myX = tonumber(safeCall(function() return mq.TLO.Me.X() end, 0)) or 0
    local myY = tonumber(safeCall(function() return mq.TLO.Me.Y() end, 0)) or 0
    local map = {}
    for _, list in pairs(byLabel) do
        if #list > 1 then
            table.sort(list, function(a, b)
                local da = ux.distanceToWatchAnchor(a.watch, myX, myY) or 999999
                local db = ux.distanceToWatchAnchor(b.watch, myX, myY) or 999999
                if da ~= db then return da < db end
                return tostring(a.key) < tostring(b.key)
            end)
            for idx, item in ipairs(list) do
                local dist = ux.distanceToWatchAnchor(item.watch, myX, myY)
                if dist then
                    map[item.key] = string.format(' · %d', math.floor(dist + 0.5))
                else
                    map[item.key] = string.format(' · %d/%d', idx, #list)
                end
            end
        end
    end
    ux.watchCampLabelMap = { gen = gen, map = map }
    return map
end

-- Alla lists some nameds at a seed point but they path around the zone (Crypt Caretaker).
ux.seedWatchTrackingMode = function(record, point, named)
    if type(record) == 'table' and record.roaming == true then return 'roamer' end
    if type(point) == 'table' and point.roaming == true then return 'roamer' end
    local key = ux.seedNameKey and ux.seedNameKey(named) or trim(tostring(named or '')):lower()
    if key == 'crypt caretaker' or key == 'cryptcaretaker' then return 'roamer' end
    return 'point'
end

ux.repairKnownSeedRoamersForZone = function(zone)
    zone = tostring(zone or currentZoneShort()):lower()
    if zone == '' then return 0 end
    local changed = 0
    for _, watch in pairs(watchList or {}) do
        if type(watch) == 'table' and tostring(watch.zone or ''):lower() == zone then
            if ux.seedWatchTrackingMode(nil, nil, watch.label or watch.desiredName) == 'roamer'
                and watch.trackingMode ~= 'roamer' then
                watch.trackingMode = 'roamer'
                changed = changed + 1
            end
        end
    end
    if changed > 0 and saveWatches then saveWatches() end
    return changed
end

-- Multi-camp nameds (Knight of Sathir x11 in Karnor) are correct per seed but noisy
-- in the slim popup. Keep the nearest camp row(s) per label.
ux.collapseWatchEntriesToNearestCamps = function(rows, maxPerLabel)
    maxPerLabel = tonumber(maxPerLabel) or 0
    rows = rows or {}
    if maxPerLabel <= 0 or #rows == 0 then return rows end
    local byLabel, order = {}, {}
    for _, entry in ipairs(rows) do
        local watch = entry.watch or {}
        local labelKey = ux.seedNameKey and ux.seedNameKey(watch.label or watch.desiredName or '')
            or tostring(watch.label or watch.desiredName or ''):lower()
        if labelKey ~= '' then
            if not byLabel[labelKey] then
                byLabel[labelKey] = {}
                table.insert(order, labelKey)
            end
            table.insert(byLabel[labelKey], entry)
        else
            table.insert(order, '__' .. tostring(entry.key or #order))
            byLabel['__' .. tostring(entry.key or #order)] = { entry }
        end
    end
    local myX = tonumber(safeCall(function() return mq.TLO.Me.X() end, 0)) or 0
    local myY = tonumber(safeCall(function() return mq.TLO.Me.Y() end, 0)) or 0
    local out = {}
    for _, labelKey in ipairs(order) do
        local list = byLabel[labelKey] or {}
        if #list <= maxPerLabel then
            for _, entry in ipairs(list) do table.insert(out, entry) end
        else
            table.sort(list, function(a, b)
                local da = ux.distanceToWatchAnchor(a.watch, myX, myY) or 999999
                local db = ux.distanceToWatchAnchor(b.watch, myX, myY) or 999999
                if da ~= db then return da < db end
                return tostring(a.key) < tostring(b.key)
            end)
            for i = 1, maxPerLabel do table.insert(out, list[i]) end
        end
    end
    return out
end

ux.pointEntryForWatch = function(watch)
    if not ux.watchHasPoint(watch) then return nil end
    local zoneTable = respawnsData[currentZoneShort()]
    return zoneTable and zoneTable._points and zoneTable._points[watch.lastSpawnPointKey] or nil
end

-- Wall-clock anchor for ETA math: watch despawn time, else learned last_death on the camp point.
ux.watchDeathAnchorTime = function(watch)
    if type(watch) ~= 'table' then return 0 end
    local despawnedAt = tonumber(watch.despawnedAt or 0) or 0
    if despawnedAt > 0 then return despawnedAt end
    local pointEntry = ux.pointEntryForWatch(watch)
    if type(pointEntry) == 'table' then
        local lastDeath = tonumber(pointEntry.last_death) or 0
        if lastDeath > 0 then return lastDeath end
    end
    local zone = tostring(watch.zone or currentZoneShort()):lower()
    local zoneTable = respawnsData and respawnsData[zone]
    local nameKey = tostring(watch.label or watch.desiredName or ''):lower()
    if nameKey ~= '' and type(zoneTable) == 'table' and type(zoneTable[nameKey]) == 'table' then
        local lastDeath = tonumber(zoneTable[nameKey].last_death) or 0
        if lastDeath > 0 then return lastDeath end
    end
    return 0
end

ux.syncWatchExpectedRespawnFromSeed = function(watch, now)
    if type(watch) ~= 'table' or watch.isUp then return false end
    if (tonumber(watch.expectedRespawnAt or 0) or 0) > 0 then return false end
    local lastDeath = tonumber(watch.despawnedAt or 0) or 0
    if lastDeath <= 0 then
        local confirmedAt = tonumber(watch.lastConfirmedKillAt or 0) or 0
        if confirmedAt > 0 then lastDeath = confirmedAt end
    end
    if lastDeath <= 0 then return false end
    local respawn, source = ux.effectiveRespawnSeconds(watch)
    if (tonumber(respawn) or 0) <= 0 then return false end
    now = tonumber(now) or os.time()
    if lastDeath + respawn <= now then return false end
    watch.despawnedAt = lastDeath
    if not watch.killedAtText or watch.killedAtText == '' then
        watch.killedAtText = os.date('%I:%M %p', lastDeath)
    end
    watch.expectedRespawnAt = lastDeath + respawn
    watch.expectedRespawnSource = source
    if tonumber(watch.lastConfirmedKillAt or 0) == lastDeath then
        watch.lastTimerBlockedReason = ''
    end
    return true
end

ux.rowNameIsDesiredForWatch = function(watch, row)
    if not watch or not row then return false end
    local desired = ux.smartDesiredName(watch)
    if desired == '' then return false end
    local rowNameL = tostring(row.name_l or row.name or ''):lower()
    local rowBaseL = rowNameL:gsub('%s*%([^)]+%)%s*$', '')
    return desired == rowNameL or desired == rowBaseL
end

ux.pointNamesText = function(watch, limit)
    local entry = ux.pointEntryForWatch(watch)
    if type(entry) ~= 'table' or type(entry.names) ~= 'table' then return '' end
    local names = {}
    for _, name in ipairs(entry.names) do
        local value = trim(tostring(name or ''))
        if value ~= '' then table.insert(names, value) end
        if limit and #names >= limit then break end
    end
    return table.concat(names, ', ')
end

ux.pointImportedPHText = function(watch, limit)
    local entry = ux.pointEntryForWatch(watch)
    if type(entry) ~= 'table' or type(entry.ph_names) ~= 'table' then return '', 0 end
    local desired = tostring((watch and (watch.desiredName or watch.label)) or ''):lower()
    local names, seen = {}, {}
    for _, name in ipairs(entry.ph_names) do
        local clean = trim(tostring(name or ''))
        local key = clean:lower()
        -- Hide the watch's own name and any tracked named that merely wandered
        -- through this point. Seed-sanctioned named-PHs (Pyzjn/Varsoon/Yollis) are
        -- shown -- they are genuine placeholders per the Alla seed.
        local wanderingNamed = ux.nameMatchesOtherNamedWatch and ux.nameMatchesOtherNamedWatch(watch, clean)
            and not (ux.phNameSeedSanctioned and ux.phNameSeedSanctioned(watch, clean))
        if clean ~= '' and not seen[key] and key ~= desired and not wanderingNamed then
            seen[key] = true
            table.insert(names, clean)
        end
    end
    local total = #names
    if limit and limit > 0 and #names > limit then
        local shown = {}
        for i = 1, limit do table.insert(shown, names[i]) end
        return table.concat(shown, ', ') .. string.format(' (+%d)', total - limit), total
    end
    return table.concat(names, ', '), total
end

ux.formatSeedChance = function(value)
    local chance = tonumber(value) or 0
    if chance <= 0 then return '' end
    local text = string.format('%.1f', chance)
    text = (text:gsub('%.0$', ''))
    return text .. '%'
end

ux.tooltipText = function(text)
    return (tostring(text or ''):gsub('%%', '%%%%'))
end

ux.watchNameText = function(entry, maxLen)
    local watch = entry.watch or {}
    local base = tostring(watch.label or entry.key or '')
    if watch.alwaysPing == true then base = '* ' .. base end
    local suffix = ''
    if entry.key and ux.buildWatchCampLabelMap then
        local map = ux.buildWatchCampLabelMap()
        suffix = map[entry.key] or ''
    end
    return shortText(base .. suffix, maxLen or 30)
end

local function addWatchExact(row, announceTarget, quiet)
    if not row then return end
    local zone = currentZoneShort()
    local existingKey = ux.findWatchKeyForNamedInZone and select(1, ux.findWatchKeyForNamedInZone(row.name, zone)) or nil
    local key = existingKey or watchKeyExact(row.name)
    local isNew = watchList[key] == nil
    watchList[key] = watchList[key] or {
        label = row.name,
        desiredName = tostring(row.name or ''):lower(),
        mode = 'smart',
        zone = currentZoneShort(),
        source = 'Manual',
        category = row.named and 'named' or 'normal',
        trackingMode = 'point',
        phNames = {},
        areaRadius = 0,
        spawnId = 0,
        respawnSeconds = 0,
        isUp = true,
        lastSeenAt = os.time(),
        despawnedAt = 0,
        killedAtText = '',
        expectedRespawnAt = 0,
        initialResolved = true,
        lastSpawnPointKey = spawnPointKey(row),
        pointConfidence = 'live',
        pointSamples = 0,
        lastX = row.x,
        lastY = row.y,
        lastZ = row.z,
        lastSpawnId = row.id,
    }
    watchList[key].zone = watchList[key].zone or currentZoneShort()
    watchList[key].source = watchList[key].source or 'Manual'
    watchList[key].mode = 'smart'
    watchList[key].desiredName = watchList[key].desiredName or tostring(row.name or ''):lower()
    watchList[key].category = watchList[key].category or (row.named and 'named' or 'normal')
    watchList[key].trackingMode = watchList[key].trackingMode or 'point'
    watchList[key].phNames = normalizeWatchNameList(watchList[key].phNames or {})
    watchList[key].pointConfidence = 'live'
    watchList[key].pointSamples = 0
    watchList[key].isUp = true
    watchList[key].pointOccupied = true
    watchList[key].currentName = row.name
    watchList[key].currentIsDesired = true
    watchList[key].lastSeenAt = os.time()
    rememberWatchLocation(watchList[key], row)
    if tonumber(row.id or 0) > 0 then
        ux.recentWatchTarget = {
            at = nowMs(),
            firstSeenAt = nowMs(),
            id = tonumber(row.id) or 0,
            name = tostring(row.name or ''):lower(),
            x = tonumber(row.x) or 0,
            y = tonumber(row.y) or 0,
            z = tonumber(row.z) or 0,
            watchKey = key,
            zoneIdentity = ux.currentZoneRuntimeIdentity and ux.currentZoneRuntimeIdentity() or currentZoneShort(),
        }
    end
    local bareKey = watchKeyExact(row.name)
    if existingKey and bareKey ~= existingKey and watchList[bareKey] then
        watchList[bareKey] = nil
    end
    if ux.collapseDuplicateSourceWatches then
        local removed = ux.collapseDuplicateSourceWatches()
        if removed > 0 and ux.rebuildWatchIndex then ux.rebuildWatchIndex() end
    end
    if not quiet then
        addAlert((isNew and not existingKey) and ('Watching: ' .. row.name) or ('Updated watch: ' .. row.name))
        if announceTarget then announceTargetWatch()
        else announceText(row.name .. ' added to watchlist at ' .. localTimeText()) end
    end
    saveWatches()
    if ux.rebuildWatchIndex then ux.rebuildWatchIndex() end
    if ux.cacheSearchWatchedRows then ux.cacheSearchWatchedRows() end
end

ux.addWatchPhForNamed = function(row, namedLabel)
    if not row then return false end
    namedLabel = trim(tostring(namedLabel or ''))
    if namedLabel == '' then return false end
    local key = watchKeyExact(namedLabel)
    local now = os.time()
    watchList[key] = watchList[key] or {
        label = namedLabel,
        desiredName = namedLabel:lower(),
        mode = 'smart',
        zone = currentZoneShort(),
        source = 'Manual PH',
        category = 'named',
        trackingMode = 'point',
        phNames = {},
        areaRadius = 0,
        spawnId = 0,
        respawnSeconds = 0,
        isUp = false,
        lastSeenAt = 0,
        despawnedAt = 0,
        killedAtText = '',
        expectedRespawnAt = 0,
        initialResolved = true,
    }
    local watch = watchList[key]
    watch.label = namedLabel
    watch.desiredName = namedLabel:lower()
    watch.mode = 'smart'
    watch.zone = currentZoneShort()
    watch.source = 'Manual PH'
    watch.category = 'named'
    watch.trackingMode = watch.trackingMode or 'point'
    watch.phNames = normalizeWatchNameList(watch.phNames or {})
    -- A named is never a placeholder for another named (or for itself). Guard the
    -- capture so "Assign PH" can't poison the list with a tracked named that
    -- happened to be sitting on the point (e.g. Tovax Vmar showing as Scruffy's PH).
    local occupantName = trim(tostring(row.name or ''))
    if occupantName ~= '' and occupantName:lower() == tostring(watch.desiredName or namedLabel:lower()) then
        chat(string.format('TurboMobs: "%s" can\'t be its own placeholder.', namedLabel))
    elseif occupantName ~= '' and ux.nameMatchesOtherNamedWatch(watch, occupantName) then
        chat(string.format('TurboMobs: "%s" is a tracked named, not a placeholder - not added to %s.', occupantName, namedLabel))
    else
        local phSeen = false
        for _, name in ipairs(watch.phNames) do
            if tostring(name or ''):lower() == occupantName:lower() then phSeen = true; break end
        end
        if not phSeen and occupantName ~= '' then table.insert(watch.phNames, occupantName) end
    end
    watch.isUp = false
    watch.pointOccupied = true
    watch.currentName = row.name
    watch.currentIsDesired = false
    watch.lastSeenAt = now
    watch.despawnedAt = 0
    watch.killedAtText = ''
    watch.expectedRespawnAt = 0
    watch.initialResolved = true
    watch.alertArmed = false
    watch.lastSpawnPointKey = spawnPointKey(row)
    watch.pointConfidence = 'trusted'
    watch.pointSamples = MIN_SAMPLES_FOR_DISPLAY
    watch.lastX = row.x
    watch.lastY = row.y
    watch.lastZ = row.z
    watch.occupantSpawnId = tonumber(row.id) or 0
    watch.occupantName = row.name

    local zoneTable = getZoneRespawns(currentZoneShort(), true)
    ensurePointEntry(zoneTable, row, row.name)
    respawnsDirty = true; ux.statsRevision = (ux.statsRevision or 0) + 1
    ux.zoneIntelCache = { at = 0, key = '', rows = {} }
    ux.watchRowsCache = { at = 0, key = '', rows = {} }
    ux.watchDetailRowsCache = { at = 0, key = '', rows = {} }
    saveWatches()
    if ux.rebuildWatchIndex then ux.rebuildWatchIndex() end
    if ux.cacheSearchWatchedRows then ux.cacheSearchWatchedRows() end
    addAlert(string.format('Watching %s point; current PH: %s', namedLabel, tostring(row.name or 'unknown')))
    return true
end

ux.promoteLearnedPhForPoint = function(pointKey, row, pointEntry)
    if not pointKey or pointKey == '' or not row then return false end

    local occupantName = trim(tostring(row.name or ''))
    if occupantName == '' then return false end

    local occupantKey = occupantName:lower()
    local zone = currentZoneShort()
    local changed = false
    local promotedTo = {}

    -- Find named watches tied to this same spawn point.
    for _, watch in pairs(watchList or {}) do
        if type(watch) == 'table'
            and tostring(watch.zone or ''):lower() == tostring(zone or ''):lower()
            and tostring(watch.lastSpawnPointKey or '') == tostring(pointKey)
            and ux.watchIsNamedLink
            and ux.watchIsNamedLink(watch) then

            local desired = ux.smartDesiredName(watch)

            -- Do not add the named itself as its own PH.
            if occupantKey ~= '' and desired ~= '' and occupantKey ~= desired then

                -- Do not add a mob that is already tracked as another named.
                if not (ux.nameMatchesOtherNamedWatch and ux.nameMatchesOtherNamedWatch(watch, occupantName)) then
                    watch.phNames = normalizeWatchNameList(watch.phNames or {})

                    local exists = false
                    for _, ph in ipairs(watch.phNames) do
                        if tostring(ph or ''):lower() == occupantKey then
                            exists = true
                            break
                        end
                    end

                    if not exists then
                        table.insert(watch.phNames, occupantName)
                        watch.phNames = normalizeWatchNameList(watch.phNames)
                        watch.pointConfidence = watch.pointConfidence or 'learning'
                        watch.pointSamples = math.max(tonumber(watch.pointSamples) or 0, tonumber(ux.learnAllCandidateHits) or 3)
                        watch.currentName = occupantName
                        watch.currentIsDesired = false
                        watch.pointOccupied = true
                        watch.occupantName = occupantName
                        watch.occupantSpawnId = tonumber(row.id) or tonumber(watch.occupantSpawnId) or 0
                        watch.lastSeenAt = os.time()
                        changed = true
                        table.insert(promotedTo, tostring(watch.label or watch.desiredName or '?'))
                    end
                end
            end
        end
    end

    if changed then
        -- Also store the PH name on the respawn point itself, so Zone Intel
        -- and future seed/repair passes can see it even before watches reload.
        if type(pointEntry) == 'table' then
            pointEntry.ph_names = normalizeWatchNameList(pointEntry.ph_names or {})
            local seen = false
            for _, ph in ipairs(pointEntry.ph_names) do
                if tostring(ph or ''):lower() == occupantKey then
                    seen = true
                    break
                end
            end
            if not seen then
                table.insert(pointEntry.ph_names, occupantName)
                pointEntry.ph_names = normalizeWatchNameList(pointEntry.ph_names)
            end
        end

        respawnsDirty = true
        ux.statsRevision = (ux.statsRevision or 0) + 1
        ux.spawnDataRevision = (ux.spawnDataRevision or 0) + 1

        ux.zoneIntelCache = { at = 0, key = '', rows = {} }
        ux.watchRowsCache = { at = 0, key = '', rows = {} }
        ux.watchDetailRowsCache = { at = 0, key = '', rows = {} }

        saveWatches()
        if ux.rebuildWatchIndex then ux.rebuildWatchIndex() end
        if ux.cacheSearchWatchedRows then ux.cacheSearchWatchedRows() end
        if ux.saveRespawnsWhenSafe then ux.saveRespawnsWhenSafe(false) end

        addAlert(string.format(
            'Learned PH: %s -> %s',
            occupantName,
            table.concat(promotedTo, ', ')
        ))
    end

    return changed
end

local function findTrackableRowByName(name)
    local needle = tostring(name or ''):lower()
    if needle == '' then return nil end
    for _, row in ipairs(allSpawns or {}) do
        if passWatchFilters(row) and tostring(row.name or ''):lower() == needle then
            return row
        end
    end
    return nil
end

local function addWatchByName(name, announceTarget, quiet)
    name = trim(tostring(name or ''))
    if name == '' then return false end
    local row = findTrackableRowByName(name)
    if row then
        addWatchExact(row, announceTarget, quiet)
    else
        local key = watchKeyExact(name)
        watchList[key] = watchList[key] or {
            label = name,
            desiredName = tostring(name or ''):lower(),
            mode = 'smart',
            zone = currentZoneShort(),
            source = 'Manual',
            category = 'normal',
            trackingMode = 'name',
            phNames = {},
            areaRadius = 0,
            spawnId = 0,
            respawnSeconds = 0,
            isUp = false,
            lastSeenAt = 0,
            despawnedAt = 0,
            killedAtText = '',
            expectedRespawnAt = 0,
            initialResolved = true,
            alertArmed = true,
        }
        watchList[key].desiredName = watchList[key].desiredName or tostring(name or ''):lower()
        watchList[key].trackingMode = watchList[key].trackingMode or 'name'
        watchList[key].phNames = normalizeWatchNameList(watchList[key].phNames or {})
        saveWatches()
        if ux.rebuildWatchIndex then ux.rebuildWatchIndex() end
        if ux.cacheSearchWatchedRows then ux.cacheSearchWatchedRows() end
        if not quiet then
            addAlert('Watching: ' .. name)
            if announceTarget then announceTargetWatch()
            else announceText(name .. ' added to watchlist at ' .. localTimeText()) end
        end
    end
    return true
end

local function setManualRespawnTimer(row, seconds)
    if not row then return end
    local key = watchKeyExact(row.name)
    watchList[key] = watchList[key] or {
        label = row.name,
        mode = 'exact',
        zone = currentZoneShort(),
        source = 'Manual',
        category = row.named and 'named' or 'normal',
        trackingMode = 'point',
        phNames = {},
        areaRadius = 0,
        spawnId = 0,
        isUp = true,
        lastSeenAt = os.time(),
        despawnedAt = 0,
        killedAtText = '',
        expectedRespawnAt = 0,
        initialResolved = true,
        lastSpawnPointKey = spawnPointKey(row),
        lastX = row.x,
        lastY = row.y,
        lastZ = row.z,
        lastSpawnId = row.id,
    }
    watchList[key].respawnSeconds = tonumber(seconds) or 0
    rememberWatchLocation(watchList[key], row)
    addAlert(string.format('Manual respawn set: %s = %s', row.name, formatSeconds(seconds)))
    saveWatches()
end

local function clearWatch(row)
    if not row then return end
    watchList[watchKeyExact(row.name)] = nil
    watchList[watchKeyId(row.id)] = nil
    addAlert('Cleared watch: ' .. row.name)
    saveWatches()
    if ux.rebuildWatchIndex then ux.rebuildWatchIndex() end
    if ux.cacheSearchWatchedRows then ux.cacheSearchWatchedRows() end
end

local function clearWatchByKey(key)
    local watch = watchList[key]
    if not watch then return end
    watchList[key] = nil
    addAlert('Cleared watch: ' .. (watch.label or key))
    saveWatches()
    if ux.rebuildWatchIndex then ux.rebuildWatchIndex() end
    if ux.cacheSearchWatchedRows then ux.cacheSearchWatchedRows() end
end

local function watchMatchesRow(watch, row)
    if not watch or not row then return false end
    if watch.zone and watch.zone ~= '' and watch.zone ~= currentZoneShort() then return false end
    if watch.mode == 'id' then return tonumber(watch.spawnId) == tonumber(row.id) end
    if watch.mode == 'name' then return tostring(watch.label or ''):lower() == tostring(row.name or ''):lower() end
    if watch.mode == 'smart' then
        return ux.rowIsDesiredForWatch(watch, row)
    end
    return tostring(watch.label or ''):lower() == tostring(row.name or ''):lower()
end

ux.rebuildWatchNamedIndex = function()
    local namedNames = {}
    for _, watch in pairs(watchList or {}) do
        if type(watch) == 'table' then
            local category = tostring(watch.category or ''):lower()
            local source = tostring(watch.source or ''):lower()
            local looksNamed = ux.labelLooksNamed and ux.labelLooksNamed(watch.label or watch.desiredName)
            if category == 'named' or source == 'spawnmaster' or looksNamed then
                local labelKey = ux.seedNameKey and ux.seedNameKey(watch.label or watch.desiredName or '')
                    or tostring(watch.label or watch.desiredName or ''):lower()
                local desiredKey = ux.seedNameKey and ux.seedNameKey(watch.desiredName or watch.label or '')
                    or tostring(watch.desiredName or watch.label or ''):lower()
                if labelKey ~= '' then
                    namedNames[labelKey] = namedNames[labelKey] or {}
                    namedNames[labelKey][watch] = true
                end
                if desiredKey ~= '' then
                    namedNames[desiredKey] = namedNames[desiredKey] or {}
                    namedNames[desiredKey][watch] = true
                end
            end
        end
    end
    ux.watchNamedNames = namedNames
end

ux.rebuildWatchZoneIndex = function()
    local zone = currentZoneShort()
    local byId, byName, downByPoint, current, currentKeys = {}, {}, {}, {}, {}
    for key, watch in pairs(watchList or {}) do
        if type(watch) == 'table' and (not watch.zone or watch.zone == '' or watch.zone == zone) then
            table.insert(current, watch)
            table.insert(currentKeys, key)
            if watch.mode == 'id' then
                local id = tonumber(watch.spawnId) or 0
                if id ~= 0 then byId[id] = watch end
            else
                local name = tostring(watch.label or ''):lower()
                if name ~= '' then byName[name] = watch end
            end
            if watch.isUp == false and watch.lastSpawnPointKey then
                downByPoint[watch.lastSpawnPointKey] = true
            end
        end
    end
    ux.watchIndex = {
        byId = byId,
        byName = byName,
        downByPoint = downByPoint,
        current = current,
        currentKeys = currentKeys,
        namedNames = ux.watchNamedNames or {},
        _zone = zone,
    }
end

ux.rebuildWatchIndex = function(bumpGeneration)
    -- Bump generation only on watch mutations / zone changes (default). Routine
    -- spawn refreshes rebuild the zone slice without invalidating draw caches.
    if bumpGeneration ~= false then
        ux.watchGeneration = (ux.watchGeneration or 0) + 1
        ux.rebuildWatchNamedIndex()
    elseif type(ux.watchNamedNames) ~= 'table' then
        ux.rebuildWatchNamedIndex()
    end
    ux.rebuildWatchZoneIndex()
    ux._currentZonePHLookup = nil
    ux.phAllocationCache = nil
    ux._watchCampSiblingsCache = nil
end

ux.currentZoneWatchPairs = function()
    local index = ux.watchIndex or {}
    local watches = index.current
    local keys = index.currentKeys
    if type(watches) == 'table' and type(keys) == 'table'
        and tostring(index._zone or '') == currentZoneShort() then
        return keys, watches
    end
    ux.rebuildWatchIndex()
    index = ux.watchIndex or {}
    return index.currentKeys or {}, index.current or {}
end

local function watchPointOccupiedRow(watch, watchKey)
    if not watch then return nil end
    local cached = ux.cachedOccupantRow(watch)
    if cached then return cached end
    local phRow = ux.findWatchPhPresenceRow(watch, watchKey)
    if phRow then return phRow end
    if not watch.lastSpawnPointKey then return nil end
    local indexed = ux.spawnIndex and ux.spawnIndex.presenceByPoint and ux.spawnIndex.presenceByPoint[watch.lastSpawnPointKey]
    if indexed and passWatchPresenceFilters(indexed) then
        if ux.rowIsDesiredForWatch(watch, indexed) then return indexed end
        if ux.rowIsPhForWatch(watch, indexed) then return indexed end
        return nil
    end
    for _, row in ipairs(allSpawns or {}) do
        if passWatchPresenceFilters(row) and watch.lastSpawnPointKey == spawnPointKey(row) then
            if ux.rowIsDesiredForWatch(watch, row) then return row end
            if ux.rowIsPhForWatch(watch, row) then return row end
        end
    end
    return nil
end

ux.watchPointOccupiedRow = watchPointOccupiedRow

local function isWatchedRow(row)
    if not row then return false end
    local index = ux.watchIndex or {}
    if row.id and index.byId and index.byId[tonumber(row.id) or 0] then
        return true, index.byId[tonumber(row.id) or 0]
    end
    local name = tostring(row.name or ''):lower()
    if name ~= '' and index.byName and index.byName[name] then
        local watch = index.byName[name]
        if watchMatchesRow(watch, row) then return true, watch end
    end
    local _, currentWatches = ux.currentZoneWatchPairs()
    local pointKey = spawnPointKey(row)
    if pointKey and pointKey ~= '' and index.downByPoint and index.downByPoint[pointKey] then
        for _, watch in ipairs(currentWatches or {}) do
            if watch and watch.lastSpawnPointKey == pointKey then
                return true, watch
            end
        end
    end
    for _, watch in ipairs(currentWatches or {}) do
        if ux.rowIsPhForWatch(watch, row) then return true, watch end
        if watchMatchesRow(watch, row) then return true, watch end
    end
    return false, nil
end

ux.cacheSearchWatchedRows = function()
    local index = ux.watchIndex or {}
    local spawnIndex = ux.spawnIndex or {}
    for _, row in ipairs(spawns or {}) do
        row.watched = false
        row.watchedEntry = nil
        if not row then goto continue end
        local id = tonumber(row.id) or 0
        if id > 0 and index.byId and index.byId[id] then
            row.watched = true
            row.watchedEntry = index.byId[id]
            goto continue
        end
        local name = tostring(row.name or ''):lower()
        if name ~= '' and index.byName and index.byName[name] then
            local watch = index.byName[name]
            if watchMatchesRow(watch, row) then
                row.watched = true
                row.watchedEntry = watch
                goto continue
            end
        end
        local pointKey = spawnPointKey(row)
        if pointKey and pointKey ~= '' then
            if spawnIndex.presenceByPoint and spawnIndex.presenceByPoint[pointKey] then
                local _, currentWatches = ux.currentZoneWatchPairs()
                for _, watch in ipairs(currentWatches or {}) do
                    if watch and watch.lastSpawnPointKey == pointKey and watchMatchesRow(watch, row) then
                        row.watched = true
                        row.watchedEntry = watch
                        break
                    end
                end
            end
        end
        ::continue::
    end
    ux.searchWatchedCacheKey = tostring(ux.spawnDataRevision or 0) .. ':' .. tostring(#spawns)
end

-- ============================================================
-- MQ / E3 compatibility variables
-- ============================================================
-- These are normal MQ global variables, not custom TLOs.
-- Lua cannot create the exact plugin syntax ${SpawnMaster.HasTarget},
-- but it can create ${SpawnMaster_HasTarget} as a lightweight compatibility alias.
--
-- Count vars are scoped to watches that apply to the current zone (same as the UI).
-- TurboMobs_DueCount: watches currently down with a known ETA (expectedRespawnAt > 0),
--   i.e. timer pending or overdue until the spawn is seen again.

local mqCompatVars = {
    TurboMobs_HasTarget = nil,
    TurboMobs_TargetWatched = nil,
    TurboMobs_TargetName = nil,
    TurboMobs_TargetID = nil,
    TurboMobs_WatchCount = nil,
    TurboMobs_UpCount = nil,
    TurboMobs_DueCount = nil,
    SpawnMaster_HasTarget = nil,
    SpawnMaster_TargetName = nil,
}

local function mqVarExists(name)
    return safeCall(function() return mq.TLO.Defined(name)() end, false) and true or false
end

local function setCompatVar(name, value)
    if not compatVarsEnabled then return end
    if not clientInGame() then return end

    value = tostring(value or '')

    -- Avoid command spam. Only touch MQ vars when the value actually changed.
    if mqCompatVars[name] == value then return end
    mqCompatVars[name] = value

    if not mqVarExists(name) then
        mq.cmdf('/squelch /declare %s string global', name)
    end

    mq.cmdf('/squelch /varset %s %s', name, value)
end

local function zoneWatchCompatCounts()
    local watchCount, upCount, dueCount = 0, 0, 0
    local _, currentWatches = ux.currentZoneWatchPairs()
    for _, w in ipairs(currentWatches or {}) do
        watchCount = watchCount + 1
        if w.isUp then
            upCount = upCount + 1
        else
            local eta = tonumber(w.expectedRespawnAt) or 0
            if eta > 0 then dueCount = dueCount + 1 end
        end
    end
    return watchCount, upCount, dueCount
end

local function updateTargetCompatVars()
    if not compatVarsEnabled then return end

    local watchCount, upCount, dueCount = zoneWatchCompatCounts()
    setCompatVar('TurboMobs_WatchCount', watchCount)
    setCompatVar('TurboMobs_UpCount', upCount)
    setCompatVar('TurboMobs_DueCount', dueCount)

    if ux.targetCompatVarsEnabled ~= true then
        setCompatVar('TurboMobs_HasTarget', 'FALSE')
        setCompatVar('TurboMobs_TargetWatched', 'FALSE')
        setCompatVar('TurboMobs_TargetName', '')
        setCompatVar('TurboMobs_TargetID', '0')
        setCompatVar('SpawnMaster_HasTarget', 'FALSE')
        setCompatVar('SpawnMaster_TargetName', '')
        return
    end

    local targetId = tonumber(safeCall(function() return mq.TLO.Target.ID() end, 0)) or 0
    local targetName = tostring(safeCall(function() return mq.TLO.Target.CleanName() end, '') or '')

    if targetId <= 0 or targetName == '' then
        setCompatVar('TurboMobs_HasTarget', 'FALSE')
        setCompatVar('TurboMobs_TargetWatched', 'FALSE')
        setCompatVar('TurboMobs_TargetName', '')
        setCompatVar('TurboMobs_TargetID', '0')

        if spawnMasterCompat then
            setCompatVar('SpawnMaster_HasTarget', 'FALSE')
            setCompatVar('SpawnMaster_TargetName', '')
        end
        return
    end

    local row = allSpawnsById[targetId]
    local watched = false

    if row then
        watched = isWatchedRow(row) and true or false
        targetName = row.name or targetName
    else
        -- Fallback for the small window before refreshSpawns has populated allSpawnsById.
        local tempRow = {
            id = targetId,
            name = targetName,
            x = tonumber(safeCall(function() return mq.TLO.Target.X() end, 0)) or 0,
            y = tonumber(safeCall(function() return mq.TLO.Target.Y() end, 0)) or 0,
            z = tonumber(safeCall(function() return mq.TLO.Target.Z() end, 0)) or 0,
        }
        watched = isWatchedRow(tempRow) and true or false
    end

    setCompatVar('TurboMobs_HasTarget', 'TRUE')
    setCompatVar('TurboMobs_TargetWatched', watched and 'TRUE' or 'FALSE')
    setCompatVar('TurboMobs_TargetName', targetName)
    setCompatVar('TurboMobs_TargetID', tostring(targetId))

    -- SpawnMaster compatibility aliases.
    -- SpawnMaster_HasTarget intentionally means "current target is watched",
    -- not merely "I have any target".
    if spawnMasterCompat then
        setCompatVar('SpawnMaster_HasTarget', watched and 'TRUE' or 'FALSE')
        setCompatVar('SpawnMaster_TargetName', targetName)
    end
end

local function echoCompatVars()
    updateTargetCompatVars()
    chat('MQ/E3 compatibility vars:')
    chat('  TurboMobs_HasTarget = ' .. tostring(mqCompatVars.TurboMobs_HasTarget or ''))
    chat('  TurboMobs_TargetWatched = ' .. tostring(mqCompatVars.TurboMobs_TargetWatched or ''))
    chat('  TurboMobs_TargetName = ' .. tostring(mqCompatVars.TurboMobs_TargetName or ''))
    chat('  TurboMobs_TargetID = ' .. tostring(mqCompatVars.TurboMobs_TargetID or ''))
    chat('  TurboMobs_WatchCount = ' .. tostring(mqCompatVars.TurboMobs_WatchCount or ''))
    chat('  TurboMobs_UpCount = ' .. tostring(mqCompatVars.TurboMobs_UpCount or ''))
    chat('  TurboMobs_DueCount = ' .. tostring(mqCompatVars.TurboMobs_DueCount or '') .. '  (down w/ ETA)')
    chat('  SpawnMaster_HasTarget = ' .. tostring(mqCompatVars.SpawnMaster_HasTarget or ''))
    chat('  SpawnMaster_TargetName = ' .. tostring(mqCompatVars.SpawnMaster_TargetName or ''))
    chat('E3 replacement: SpawnMaster=${SpawnMaster_HasTarget.Equal[TRUE]}')
end

local function findWatchRow(watch)
    if not watch then return nil end
    local sticky = findStickyWatchRow(watch, passWatchFilters)
    if sticky then return sticky end
    local index = ux.spawnIndex or {}
    local row = nil
    if watch.mode == 'id' then
        row = index.byId and index.byId[tonumber(watch.spawnId) or 0] or nil
    else
        local desired = watch.mode == 'smart' and ux.smartDesiredName(watch) or tostring(watch.label or ''):lower()
        row = index.presenceByName and index.presenceByName[desired] or nil
        if (not row) and ux.watchHasPoint(watch) and ux.watchTrackingMode(watch) == 'point' then
            row = index.presenceByPoint and index.presenceByPoint[watch.lastSpawnPointKey] or nil
        end
    end
    if row and passWatchFilters(row) and watchMatchesRow(watch, row) then return row end
    return nil
end

ux.cachedFindWatchRow = function(watch, watchKey)
    if not watch then return nil end
    watchKey = tostring(watchKey or '')
    local rev = tonumber(ux.spawnDataRevision) or 0
    local cache = ux.findWatchRowCache
    if not cache or cache.rev ~= rev then
        cache = { rev = rev, byKey = {} }
        ux.findWatchRowCache = cache
    end
    if cache.byKey[watchKey] == nil then
        cache.byKey[watchKey] = findWatchRow(watch) or false
    end
    local hit = cache.byKey[watchKey]
    if hit == false then return nil end
    return hit
end

ux.findWatchPresenceRow = function(watch)
    if not watch then return nil end
    local sticky = findStickyWatchRow(watch, passWatchPresenceFilters)
    if sticky then return sticky end
    local index = ux.spawnIndex or {}
    local row = nil
    if watch.mode == 'id' then
        row = index.byId and index.byId[tonumber(watch.spawnId) or 0] or nil
    else
        local desired = watch.mode == 'smart' and ux.smartDesiredName(watch) or tostring(watch.label or ''):lower()
        row = index.presenceByName and index.presenceByName[desired] or nil
        if (not row) and ux.watchHasPoint(watch) and ux.watchTrackingMode(watch) == 'point' then
            row = index.presenceByPoint and index.presenceByPoint[watch.lastSpawnPointKey] or nil
        end
    end
    if row and passWatchPresenceFilters(row) and watchMatchesRow(watch, row) then return row end
    return nil
end

ux.cachedWatchPresenceRow = function(watch, watchKey)
    if not watch then return nil end
    local rev = tonumber(ux.spawnDataRevision) or 0
    local cache = ux.watchPresenceRowCache
    if not cache or cache.rev ~= rev then
        cache = { rev = rev, byKey = {} }
        ux.watchPresenceRowCache = cache
    end
    local key = tostring(watchKey or watch)
    local stateKey = table.concat({
        tostring(watch.isUp == true),
        tostring(watch.lastSpawnId or 0),
        tostring(watch.lastSpawnPointKey or ''),
        tostring(watch.occupantSpawnId or 0),
        tostring(watch.mode or ''),
    }, '|')
    local hit = cache.byKey[key]
    if not hit or hit.stateKey ~= stateKey then
        hit = { stateKey = stateKey, row = ux.findWatchPresenceRow(watch) or false }
        cache.byKey[key] = hit
    end
    if hit.row == false then return nil end
    return hit.row
end

ux.buildWatchScanHints = function(opts)
    opts = opts or {}
    local hints = {
        ids = {}, names = {}, points = {}, keys = {},
        count = 0, totalWatches = 0, dueWatches = 0,
        selectedWatches = 0, extraNames = 0, nameCount = 0, idCount = 0, pointCount = 0,
    }
    local currentKeys, currentWatches = ux.currentZoneWatchPairs()
    local total = #(currentWatches or {})
    hints.totalWatches = total
    if total <= 0 then return hints end

    local maxWatches = math.max(1, tonumber(opts.maxWatches) or tonumber(ux.watchScanChunkSize) or 6)
    local fullBaseline = opts.fullBaseline == true or opts.full == true
    local selected = {}
    local selectedByKey = {}

    local function selectWatch(i, reason)
        local watch = currentWatches and currentWatches[i] or nil
        if type(watch) ~= 'table' then return false end
        local key = tostring(currentKeys and currentKeys[i] or watch)
        if key == '' or selectedByKey[key] then return false end
        selectedByKey[key] = true
        table.insert(selected, { key = key, watch = watch, reason = reason or 'chunk' })
        return true
    end

    for i, watch in ipairs(currentWatches or {}) do
        if ux.watchIsEffectivelyDue and ux.watchIsEffectivelyDue(watch) then
            if selectWatch(i, 'due') then hints.dueWatches = hints.dueWatches + 1 end
        end
    end

    for i, watch in ipairs(currentWatches or {}) do
        if watch and (watch.isUp == true or (tonumber(watch.occupantSpawnId or 0) or 0) > 0) then
            selectWatch(i, 'active')
        end
    end

    local targetNormal = fullBaseline and total or maxWatches
    local cursor = math.max(1, tonumber(ux.watchScanCursor) or 1)
    if cursor > total then cursor = 1 end
    local scanned = 0
    local addedNormal = 0
    while scanned < total and (fullBaseline or addedNormal < targetNormal) do
        local i = ((cursor + scanned - 1) % total) + 1
        if selectWatch(i, 'chunk') then addedNormal = addedNormal + 1 end
        scanned = scanned + 1
    end
    if total > 0 then
        ux.watchScanCursor = ((cursor + math.max(1, scanned) - 1) % total) + 1
    end

    local function addName(name)
        name = tostring(name or ''):lower()
        if name ~= '' then hints.names[name] = true end
    end

    for _, item in ipairs(selected) do
        local watch = item.watch
        if type(watch) == 'table' then
            hints.count = hints.count + 1
            hints.keys[item.key] = true
            local spawnId = tonumber(watch.spawnId or 0) or 0
            local lastId = tonumber(watch.lastSpawnId or 0) or 0
            local occupantId = tonumber(watch.occupantSpawnId or 0) or 0
            if spawnId > 0 then hints.ids[spawnId] = true end
            if lastId > 0 then hints.ids[lastId] = true end
            if occupantId > 0 then hints.ids[occupantId] = true end

            addName(watch.label)
            addName(ux.smartDesiredName and ux.smartDesiredName(watch) or watch.desiredName)

            local phLimit = math.max(0, tonumber(ux.watchScanMaxPhNamesPerWatch) or 3)
            local phAdded = 0
            if item.reason == 'due' or fullBaseline or not watch.isUp then
                for name in pairs((ux.watchPhNameSet and ux.watchPhNameSet(watch)) or {}) do
                    if phAdded >= phLimit then break end
                    if name and name ~= '' then
                        addName(name)
                        phAdded = phAdded + 1
                    end
                end
            end

            local pointKey = tostring(watch.lastSpawnPointKey or '')
            if pointKey ~= '' then hints.points[pointKey] = true end
        end
    end

    -- Before the baseline is ready, add a bounded set of extra name probes so
    -- first-zone resolution converges quickly. After baseline, steady-state
    -- targeted refreshes stay on due/active/current chunk watches to avoid
    -- second-scale MQ query fanout in crowded zones.
    if fullBaseline or ux.watchBaselineReady ~= true then
        local maxExtraNames = math.max(12, (tonumber(ux.targetedWatchNameLimit) or 5) * 4)
        local extraNames = 0
        for i, watch in ipairs(currentWatches or {}) do
            if extraNames >= maxExtraNames then break end
            local key = tostring(currentKeys and currentKeys[i] or '')
            if key ~= '' and not selectedByKey[key] and type(watch) == 'table' then
                local before = 0
                for _ in pairs(hints.names or {}) do before = before + 1 end
                addName(watch.label)
                addName(ux.smartDesiredName and ux.smartDesiredName(watch) or watch.desiredName)
                local after = 0
                for _ in pairs(hints.names or {}) do after = after + 1 end
                if after > before then extraNames = extraNames + (after - before) end
            end
        end
        hints.extraNames = extraNames
    end
    hints.selectedWatches = #selected
    for _ in pairs(hints.names or {}) do hints.nameCount = hints.nameCount + 1 end
    for _ in pairs(hints.ids or {}) do hints.idCount = hints.idCount + 1 end
    for _ in pairs(hints.points or {}) do hints.pointCount = hints.pointCount + 1 end
    return hints
end

ux.rowMatchesWatchScanHints = function(row, hints)
    if not row or type(hints) ~= 'table' then return false end
    local id = tonumber(row.id) or 0
    if id > 0 and hints.ids and hints.ids[id] then return true end
    local name = tostring(row.name or ''):lower()
    if name ~= '' and hints.names and hints.names[name] then return true end
    local pointKey = spawnPointKey(row)
    if pointKey and pointKey ~= '' and hints.points and hints.points[pointKey] then return true end
    return false
end

ux.hydrateWatchCandidateRow = function(row, spawn)
    if not row or not spawn or row._watchHydrated then return row end
    local ok, d = pcall(function()
        return {
            trueName = spawn.Name(),
            level = spawn.Level(),
            distance = spawn.Distance(),
            type = spawn.Type(),
            body = spawn.Body(),
            dead = spawn.Dead(),
        }
    end)
    if ok and type(d) == 'table' then
        row.trueName = tostring(d.trueName or row.name or '')
        row.level = tonumber(d.level) or 0
        row.distance = tonumber(d.distance) or 0
        row.type = tostring(d.type or 'Unknown')
        row.body = tostring(d.body or 'Unknown')
        if d.dead ~= nil then row.dead = d.dead end
    else
        row.trueName = tostring(safeCall(function() return spawn.Name() end, row.name) or row.name)
        row.level = tonumber(safeCall(function() return spawn.Level() end, 0)) or 0
        row.distance = tonumber(safeCall(function() return spawn.Distance() end, 0)) or 0
        row.type = tostring(safeCall(function() return spawn.Type() end, 'Unknown') or 'Unknown')
        row.body = tostring(safeCall(function() return spawn.Body() end, 'Unknown') or 'Unknown')
        row.dead = safeCall(function() return spawn.Dead() end, row.dead or false)
    end
    row._watchHydrated = true
    return row
end

local function targetRow(row)
    if not row then return false end
    local id = tonumber(row.id) or 0
    ux.pendingTargetRowId = 0
    ux.pendingTargetRow = nil
    ux.pendingTargetAtMS = 0
    -- Do not stop /nav when the player targets another mob for /con; active nav
    -- tracks the spawn id from the Nav button, not the current target.
    if row.id and row.id ~= 0 then
        mq.cmdf('/squelch /target id %d', row.id)
        return true
    end
    local name = trim(tostring(row.name or ''))
    if name ~= '' then
        mq.cmdf('/squelch /target "%s"', name:gsub('"', ''))
        return true
    end
    return false
end

ux.clearPendingTargetRow = function()
    ux.pendingTargetRowId = 0
    ux.pendingTargetRow = nil
    ux.pendingTargetAtMS = 0
end

ux.queueTargetRow = function(row)
    local id = tonumber(row and row.id) or 0
    if id <= 0 then return targetRow(row) end
    ux.pendingTargetRowId = id
    ux.pendingTargetRow = {
        id = id,
        name = row.name,
        x = row.x,
        y = row.y,
        z = row.z,
    }
    ux.pendingTargetAtMS = nowMs() + 240
    return true
end

ux.updatePendingTargetRow = function()
    local id = tonumber(ux.pendingTargetRowId) or 0
    if id <= 0 then return end
    if nowMs() < (tonumber(ux.pendingTargetAtMS) or 0) then return end
    local fallback = ux.pendingTargetRow
    ux.clearPendingTargetRow()
    local row = (allSpawnsById and allSpawnsById[id]) or fallback
    if row then targetRow(row) end
end

local function faceRow(row)
    if not row then chat('Watched mob is not currently up.'); return end
    targetRow(row)
    mq.cmd('/face')
end

ux.resetActiveNavState = function()
    ux.activeNavTargetId = 0
    ux.activeNavStopDistance = 0
    ux.activeNavLastCheckMS = 0
    ux.activeNavStartedMS = 0
    ux.activeNavSawTarget = false
end

ux.requestNavTargetRelease = function(id, durationMs)
    id = tonumber(id) or 0
    mq.cmd('/squelch /nav stop')
    if id > 0 then
        ux.pendingNavClearTargetId = id
        ux.pendingNavClearUntilMS = nowMs() + (tonumber(durationMs) or 1750)
        ux.pendingNavClearLastMS = 0
    else
        ux.pendingNavClearTargetId = 0
        ux.pendingNavClearUntilMS = 0
        ux.pendingNavClearLastMS = 0
    end
end

ux.stopNav = function()
    mq.cmd('/squelch /nav stop')
    ux.resetActiveNavState()
    ux.clearPendingTargetRow()
end

local function navRow(row)
    if not row then chat('Watched mob is not currently up.'); return end
    ux.clearPendingTargetRow()
    local id = tonumber(row.id) or 0
    if id > 0 then
        if (tonumber(ux.activeNavTargetId) or 0) > 0 and id ~= tonumber(ux.activeNavTargetId) then
            ux.requestNavTargetRelease(ux.activeNavTargetId, 500)
            ux.resetActiveNavState()
        end
        local stopDistance = math.max(1, tonumber(ux.navDistance) or 20)
        ux.activeNavTargetId = id
        ux.activeNavStopDistance = stopDistance
        ux.activeNavLastCheckMS = 0
        ux.activeNavStartedMS = nowMs()
        ux.activeNavSawTarget = false
        ux.pendingNavClearTargetId = 0
        ux.pendingNavClearUntilMS = 0
        ux.pendingNavClearLastMS = 0
        targetRow(row)
        mq.cmdf('/squelch /nav id %d distance=%d', id, stopDistance)
        return
    end
    if row.x ~= nil and row.y ~= nil then
        ux.resetActiveNavState()
        local y = tonumber(row.y) or 0
        local x = tonumber(row.x) or 0
        local z = tonumber(row.z) or 0
        local navQuery = string.format('loc %.1f %.1f %.1f', y, x, z)
        local pathOk = safeCall(function() return mq.TLO.Navigation.PathExists(navQuery)() end, true)
        if pathOk == false then
            chat(string.format('Nav path failed for %s at %.1f %.1f %.1f. Watch kept; try Nav on a nearby live mob or move closer.',
                tostring(row.name or row.label or 'saved point'), y, x, z))
            if ux.recordPerfLine then ux.recordPerfLine('Nav loc path failed: ' .. navQuery .. ' for ' .. tostring(row.name or row.label or '-')) end
            return
        end
        mq.cmdf('/squelch /nav loc %.1f %.1f %.1f', y, x, z)
        return
    end
    chat('Nav unavailable: no location for ' .. tostring(row.name or 'this row') .. '.')
end

ux.updatePendingNavTargetClear = function()
    local id = tonumber(ux.pendingNavClearTargetId) or 0
    if id <= 0 then return end
    local now = nowMs()
    if now > (tonumber(ux.pendingNavClearUntilMS) or 0) then
        ux.pendingNavClearTargetId = 0
        ux.pendingNavClearUntilMS = 0
        ux.pendingNavClearLastMS = 0
        return
    end
    if now - (tonumber(ux.pendingNavClearLastMS) or 0) < 150 then return end
    ux.pendingNavClearLastMS = now
    local targetId = tonumber(safeCall(function() return mq.TLO.Target.ID() end, 0)) or 0
    mq.cmd('/squelch /nav stop')
    if targetId == id then
        mq.cmd('/squelch /target clear')
        mq.cmd('/squelch /keypress esc')
    elseif targetId > 0 then
        ux.pendingNavClearTargetId = 0
        ux.pendingNavClearUntilMS = 0
        ux.pendingNavClearLastMS = 0
    end
end

ux.updateActiveNavTarget = function()
    local id = tonumber(ux.activeNavTargetId) or 0
    if id <= 0 then return end
    local now = nowMs()
    if now - (tonumber(ux.activeNavLastCheckMS) or 0) < 250 then return end
    ux.activeNavLastCheckMS = now
    local navActive = safeCall(function() return mq.TLO.Navigation.Active() end, false)
    local startedAgo = now - (tonumber(ux.activeNavStartedMS) or 0)
    if startedAgo > 1250 and not navActive then
        ux.resetActiveNavState()
        ux.recordPerfLine(string.format('Nav id %d monitor released after nav stopped', id))
        return
    end
    local dist = tonumber(safeCall(function() return mq.TLO.Spawn('id ' .. tostring(id)).Distance() end, 999999)) or 999999
    local stopDistance = math.max(1, tonumber(ux.activeNavStopDistance) or tonumber(ux.navDistance) or 20)
    if dist <= (stopDistance + 2) then
        mq.cmd('/squelch /nav stop')
        ux.resetActiveNavState()
        ux.recordPerfLine(string.format('Nav id %d released at %.1fm', id, dist))
    end
end

ux.importedRespawnSeconds = function(watch)
    local entry = ux.pointEntryForWatch and ux.pointEntryForWatch(watch) or nil
    if type(entry) == 'table' then
        local seconds = tonumber(entry.respawn_seconds) or tonumber(entry.imported_respawn_seconds) or 0
        if seconds > 0 then return seconds, tostring(entry.timer_source or entry.source or 'imported') end
    end
    local zone = currentZoneShort()
    local desiredNames = {}
    local function addDesired(value)
        local clean = trim(tostring(value or ''))
        local key = ux.seedNameKey and ux.seedNameKey(clean) or clean:lower()
        if key ~= '' then desiredNames[key] = clean end
    end
    addDesired(watch and watch.label)
    addDesired(watch and watch.desiredName)
    addDesired(ux.smartDesiredName and ux.smartDesiredName(watch) or '')
    local lookup = ux.importedRespawnByZone and ux.importedRespawnByZone[zone]
    if type(lookup) ~= 'table' and ux.rebuildImportedRespawnLookup then
        ux.rebuildImportedRespawnLookup(zone)
        lookup = ux.importedRespawnByZone and ux.importedRespawnByZone[zone]
    end
    if type(lookup) == 'table' then
        for desiredKey in pairs(desiredNames) do
            local hit = lookup[desiredKey]
            if hit and (tonumber(hit.seconds) or 0) > 0 then
                return tonumber(hit.seconds), tostring(hit.source or 'imported')
            end
        end
    end
    local zoneTable = respawnsData[zone]
    for desiredKey, desiredLabel in pairs(desiredNames) do
        local mob = zoneTable and zoneTable[tostring(desiredLabel or ''):lower()] or nil
        if type(mob) ~= 'table' and zoneTable then mob = zoneTable[desiredKey] end
        if type(mob) == 'table' then
            local seconds = tonumber(mob.imported_respawn_seconds) or tonumber(mob.respawn_seconds) or 0
            if seconds > 0 then return seconds, tostring(mob.timer_source or mob.source or 'imported') end
        end
    end
    return 0, 'none'
end

ux.rebuildImportedRespawnLookup = function(zone)
    zone = tostring(zone or currentZoneShort()):lower()
    local zoneTable = respawnsData and respawnsData[zone]
    local byName = {}
    local function store(name, seconds, source)
        local key = ux.seedNameKey and ux.seedNameKey(name) or tostring(name or ''):lower()
        seconds = tonumber(seconds) or 0
        if key == '' or seconds <= 0 then return end
        if not byName[key] then
            byName[key] = { seconds = seconds, source = tostring(source or 'imported') }
        end
    end
    local function indexPointNames(point)
        if type(point) ~= 'table' then return end
        local sec = tonumber(point.respawn_seconds) or tonumber(point.imported_respawn_seconds) or 0
        if sec <= 0 then return end
        local src = point.timer_source or point.source or 'imported'
        store(point.named_name or point.display_name or point.last_seen_name, sec, src)
        for _, list in ipairs({ point.seed_names, point.ph_names, point.names }) do
            if type(list) == 'table' then
                for _, nm in ipairs(list) do store(nm, sec, src) end
            end
        end
    end
    if type(zoneTable) == 'table' then
        for k, mob in pairs(zoneTable) do
            if k ~= '_points' and type(mob) == 'table' then
                local sec = tonumber(mob.imported_respawn_seconds) or tonumber(mob.respawn_seconds) or 0
                if sec > 0 then store(mob.display_name or k, sec, mob.timer_source or mob.source) end
            end
        end
        local points = zoneTable._points
        if type(points) == 'table' then
            for _, point in pairs(points) do indexPointNames(point) end
        end
    end
    ux.importedRespawnByZone = ux.importedRespawnByZone or {}
    ux.importedRespawnByZone[zone] = byName
end

local function effectiveRespawnSeconds(watch)
    if (tonumber(watch.respawnSeconds) or 0) > 0 then
        return tonumber(watch.respawnSeconds), 'manual'
    end
    local imported, importedSource = ux.importedRespawnSeconds(watch)
    local stats = statsForMob(watch.label, nil, watch.lastSpawnPointKey)
    if imported and imported > 0 and tostring(importedSource or ''):lower():find('lazarus', 1, true) then return imported, importedSource end
    if stats and (tonumber(stats.n) or 0) >= MIN_SAMPLES_FOR_DISPLAY then return stats.avg, 'learned' end
    if stats and (tonumber(stats.n) or 0) > 0 then return stats.avg, string.format('observed %d/%d', tonumber(stats.n) or 0, MIN_SAMPLES_FOR_DISPLAY) end
    if imported and imported > 0 then return imported, importedSource end
    return 0, 'none'
end

ux.effectiveRespawnSeconds = effectiveRespawnSeconds

ux.watchEffectiveEtaAt = function(watch)
    if type(watch) ~= 'table' then return 0 end
    local eta = tonumber(watch.expectedRespawnAt or 0) or 0
    if eta > 0 then return eta end
    if not (ux.watchHasPoint and ux.watchHasPoint(watch)) then return 0 end
    local despawnedAt = tonumber(watch.despawnedAt or 0) or 0
    if despawnedAt <= 0 then return 0 end
    local respawn = tonumber((select(1, ux.effectiveRespawnSeconds(watch)))) or 0
    if respawn > 0 then return despawnedAt + respawn end
    return 0
end

ux.watchIsEffectivelyDue = function(watch)
    if type(watch) ~= 'table' or watch.isUp == true then return false end
    local eta = ux.watchEffectiveEtaAt and ux.watchEffectiveEtaAt(watch) or 0
    return eta > 0 and eta <= os.time()
end

-- Does the player's current target belong to this watch (incl. generic corpses)?
ux.targetMatchesWatch = function(watch, targetName, targetId, targetX, targetY)
    if not watch then return false end
    targetName = tostring(targetName or ''):lower()
    targetId = tonumber(targetId) or 0
    local spawnId = tonumber(watch.lastSpawnId or 0) or 0
    if watch.mode == 'id' then
        spawnId = tonumber(watch.spawnId or 0) or spawnId
    end
    if targetId > 0 and spawnId > 0 and spawnId == targetId then return true end
    local desired = watch.mode == 'smart' and ux.smartDesiredName(watch) or tostring(watch.label or ''):lower()
    local targetBaseName = targetName:gsub('%s*%([^)]+%)%s*$', '')
    if desired ~= '' and (desired == targetName or (targetBaseName ~= '' and desired == targetBaseName)) then
        if ux.watchTrackingMode and ux.watchTrackingMode(watch) == 'point'
            and ux.watchHasPoint and ux.watchHasPoint(watch)
            and targetX ~= nil and targetY ~= nil
            and ux.rowClaimsWatchCamp then
            return ux.rowClaimsWatchCamp(watch, { name = targetName, id = targetId, x = targetX, y = targetY })
        end
        return true
    end
    local label = tostring(watch.label or ''):lower()
    if label == '' or targetName == '' then return false end
    local function sharesToken(a, b)
        for word in a:gmatch('[a-z][a-z0-9\']+') do
            if #word >= 5 and b:find(word, 1, true) then return true end
        end
        return false
    end
    if sharesToken(label, targetName) or sharesToken(targetName, label) then
        if targetName:find('corpse', 1, true) and ux.watchHasPoint(watch) and targetX ~= nil and targetY ~= nil then
            local dx = (tonumber(targetX) or 0) - (tonumber(watch.lastX) or 0)
            local dy = (tonumber(targetY) or 0) - (tonumber(watch.lastY) or 0)
            local radius = math.max(tonumber(watch.anchorRadius) or 0, ux.seedWatchAnchorRadius or 30) * 2
            return (dx * dx + dy * dy) <= (radius * radius)
        end
        if not targetName:find('corpse', 1, true) then return true end
    end
    local phSet = ux.watchPhNameSet and ux.watchPhNameSet(watch) or {}
    if phSet[targetName] or (ux.watchLabelListedAsPh and ux.watchLabelListedAsPh(watch, targetName)) then
        if not ux.watchHasPoint(watch) or targetX == nil or targetY == nil then return true end
        if ux.rowIsPlaceholderAtWatchCamp then
            return ux.rowIsPlaceholderAtWatchCamp(watch, { name = targetName, id = targetId, x = targetX, y = targetY })
        end
        return ux.rowWithinWatchAnchor and ux.rowWithinWatchAnchor(watch, { name = targetName, id = targetId, x = targetX, y = targetY }) or false
    end
    return false
end

ux.clearWatchPoolBlock = function(watch)
    if not watch then return end
    watch.poolBlockName = ''
    watch.poolBlockSpawnId = 0
end

ux.resolvePoolBlockRow = function(watch)
    if not watch then return nil end
    local blockName = trim(tostring(watch.poolBlockName or ''))
    if blockName == '' then return nil end
    local blockId = tonumber(watch.poolBlockSpawnId or 0) or 0
    if blockId > 0 and ux.spawnIndex and ux.spawnIndex.byId then
        local live = ux.spawnIndex.byId[blockId]
        if live and passWatchPresenceFilters(live) then return live end
    end
    return {
        name = blockName,
        id = blockId,
        x = watch.lastX,
        y = watch.lastY,
        z = watch.lastZ,
    }
end

ux.syncPoolWatchTimers = function(sourceWatch)
    if type(sourceWatch) ~= 'table' then return 0 end
    local pointKey = tostring(sourceWatch.lastSpawnPointKey or '')
    if pointKey == '' then return 0 end
    local zone = tostring(sourceWatch.zone or currentZoneShort() or ''):lower()
    if zone == '' or zone == 'unknown' then return 0 end
    local synced = 0
    for _, other in pairs(watchList or {}) do
        if type(other) == 'table' and other ~= sourceWatch
            and tostring(other.zone or ''):lower() == zone
            and tostring(other.lastSpawnPointKey or '') == pointKey then
            other.despawnedAt = sourceWatch.despawnedAt
            other.expectedRespawnAt = sourceWatch.expectedRespawnAt
            other.expectedRespawnSource = sourceWatch.expectedRespawnSource
            other.killedAtText = sourceWatch.killedAtText
            other.lastConfirmedKillAt = sourceWatch.lastConfirmedKillAt
            other.isUp = false
            other.pointOccupied = false
            other.currentIsDesired = false
            other.occupantSpawnId = 0
            other.occupantName = ''
            ux.clearWatchPoolBlock(other)
            other.currentName = ''
            synced = synced + 1
        end
    end
    return synced
end

-- Arm despawn/respawn timer when a watched named goes down. Returns true if transitioned.
local function armWatchRespawnTimer(watch, now, suppressAlerts, opts)
    opts = opts or {}
    local function block(reason)
        if watch then watch.lastTimerBlockedReason = tostring(reason or 'unknown') end
        return false
    end
    local function formatWatchDeathAlert(prefix, label, source, respawnSeconds)
        prefix = tostring(prefix or 'Despawned')
        label = tostring(label or '')
        if prefix == 'Killed' then
            if respawnSeconds and tonumber(respawnSeconds) and tonumber(respawnSeconds) > 0 then
                return string.format('\\ar%s:\\ax \\aw%s\\ax (\\ay%s ETA: %s\\ax)',
                    prefix, label, tostring(source or ''), formatSeconds(respawnSeconds))
            end
            return string.format('\\ar%s:\\ax \\aw%s\\ax', prefix, label)
        end
        if respawnSeconds and tonumber(respawnSeconds) and tonumber(respawnSeconds) > 0 then
            return string.format('%s: %s (%s ETA: %s)', prefix, label, tostring(source or ''), formatSeconds(respawnSeconds))
        end
        return prefix .. ': ' .. label
    end
    if not watch or not watch.initialResolved then return block('watch not initially resolved') end
    if watch.isUp ~= true and opts.allowColdDown ~= true then return block('watch already down and cold arm not allowed') end
    if watch.isUp ~= true and opts.allowColdDown == true and not ux.watchHasPoint(watch) then return block('cold arm requested without saved point') end
    if opts.confirmedKill == true then
        local lastAt = tonumber(watch.lastConfirmedKillAt or 0) or 0
        if lastAt > 0 and (now - lastAt) < 600 then return block('recent confirmed kill already recorded') end
    elseif (tonumber(watch.expectedRespawnAt) or 0) > 0 then
        return block('timer already armed')
    end

    local reason = tostring(opts.reason or 'despawned')
    if reason == 'despawned' and opts.skipFalsePositiveCheck ~= true then
        if ux.watchTrackingMode(watch) == 'point' and ux.watchHasPoint(watch) then
            local desired = ux.smartDesiredName(watch)
            local zoneRow = ux.spawnIndex and ux.spawnIndex.presenceByName and ux.spawnIndex.presenceByName[desired] or nil
            if zoneRow and ux.rowClaimsWatchCamp and not ux.rowClaimsWatchCamp(watch, zoneRow) then
                watch.isUp = false
                watch.alertArmed = false
                watch.despawnedAt = 0
                watch.killedAtText = ''
                watch.expectedRespawnAt = 0
                watch.expectedRespawnSource = ''
                watch.currentIsDesired = false
                return true
            end
        end
    end

    local previousName = tostring(opts.previousName or watch.currentName or watch.occupantName or watch.label or '')
    local previousIsUp = watch.isUp == true
    local previousPointOccupied = watch.pointOccupied == true
    local previousOccupantId = tonumber(watch.occupantSpawnId or 0) or 0
    if previousOccupantId <= 0 and opts.lastRow then previousOccupantId = tonumber(opts.lastRow.id or 0) or 0 end
    if previousOccupantId <= 0 then previousOccupantId = tonumber(watch.roamingPhSpawnId or 0) or 0 end
    local previousEmptySeen = tonumber(watch.emptySeenCount or 0) or 0
    local refreshSource = tostring(ux.currentRefreshSource or '')
    local respawn, source = ux.effectiveRespawnSeconds(watch)
    watch.lastTimerBlockedReason = ''
    watch.lastOccupiedAt = tonumber(watch.lastOccupiedAt) or now
    watch.lastOccupantName = previousName ~= '' and previousName or tostring(watch.lastOccupantName or '')
    watch.lastOccupantId = previousOccupantId

    watch.isUp = false
    watch.alertArmed = true
    watch.despawnedAt = now
    watch.killedAtText = localTimeText()
    watch.pointOccupied = false
    watch.currentIsDesired = false
    watch.occupantSpawnId = 0
    watch.occupantName = ''
    watch.lastDeliveredAlertSpawnId = 0
    watch.lastDeliveredAlertKey = ''
    watch.offAnchorOccupantId = 0
    watch.offAnchorOccupantName = ''
    ux.clearRoamingPh(watch)
    if ux.recordPerfLine then
        ux.recordPerfLine(string.format('Watch timer armed reason=%s source=%s label=%s point=%s death=%s prev=%s prevUp=%s prevOccupied=%s prevOccupant=%s emptySeen=%d respawn=%d timerSource=%s alertPrefix=%s',
            tostring(reason),
            refreshSource ~= '' and refreshSource or '-',
            tostring(watch.label or watch.desiredName or '-'),
            tostring(watch.lastSpawnPointKey or '-'),
            tostring(opts.deathName or watch.label or '-'),
            previousName ~= '' and previousName or '-',
            tostring(previousIsUp),
            tostring(previousPointOccupied),
            tostring(previousOccupantId),
            previousEmptySeen,
            tonumber(respawn) or 0,
            tostring(source or 'none'),
            tostring(opts.alertPrefix or 'Despawned')))
    end

    local lastRow = opts.lastRow
    if not lastRow and watch.lastSpawnPointKey then
        lastRow = { id = watch.lastSpawnId or 0, name = watch.label, x = watch.lastX, y = watch.lastY, z = watch.lastZ }
    end
    local deathName = tostring(opts.deathName or watch.label or '')
    local watchDeathName = tostring(watch.label or watch.desiredName or '')
    local anchorRow = {
        id = lastRow and lastRow.id or watch.lastSpawnId or 0,
        name = watchDeathName ~= '' and watchDeathName or deathName,
        x = watch.lastX,
        y = watch.lastY,
        z = watch.lastZ,
    }
    if watchDeathName ~= '' then
        recordDeath(watchDeathName, anchorRow)
    end
    if deathName ~= '' and deathName:lower() ~= watchDeathName:lower() then
        recordDeath(deathName, lastRow)
    end

    if respawn > 0 then
        watch.expectedRespawnAt = now + respawn
        watch.expectedRespawnSource = source
        ux.clearWatchPoolBlock(watch)
        if ux.syncPoolWatchTimers then ux.syncPoolWatchTimers(watch) end
        if not suppressAlerts then
            local prefix = tostring(opts.alertPrefix or 'Despawned')
            addAlert(formatWatchDeathAlert(prefix, watch.label, source, respawn))
        end
    elseif not suppressAlerts then
        addAlert(formatWatchDeathAlert(tostring(opts.alertPrefix or 'Despawned'), watch.label, nil, 0))
    end
    if opts.confirmedKill == true then
        watch.lastConfirmedKillAt = now
    end
    if ux.markWatchStateDirty then
        ux.markWatchStateDirty()
    end
    return true
end

ux.armWatchRespawnTimer = armWatchRespawnTimer

ux.normalizeWatchTargetName = TM.normalizeWatchTargetName

ux.findBestWatchForTarget = function(targetName, targetId, targetX, targetY)
    targetName = tostring(targetName or ''):lower()
    targetId = tonumber(targetId) or 0
    targetX = tonumber(targetX) or 0
    targetY = tonumber(targetY) or 0
    if targetId <= 0 or targetName == '' then return nil, nil end
    local currentKeys, currentWatches = ux.currentZoneWatchPairs()
    local bestWatch = nil
    local bestKey = nil
    local bestDistSq = math.huge
    for i, watch in ipairs(currentWatches or {}) do
        if watch and ux.targetMatchesWatch(watch, targetName, targetId, targetX, targetY) then
            local dx = targetX - (tonumber(watch.lastX) or 0)
            local dy = targetY - (tonumber(watch.lastY) or 0)
            local distSq = dx * dx + dy * dy
            if distSq < bestDistSq then
                bestDistSq = distSq
                bestWatch = watch
                bestKey = tostring(currentKeys and currentKeys[i] or '')
            end
        end
    end
    return bestWatch, bestKey
end

-- Looser camp match for live-evidence updates: desired nameds may bind off-anchor.
ux.findWatchForTargetEvidence = function(targetName, targetId, targetX, targetY)
    targetName = tostring(targetName or ''):lower()
    targetId = tonumber(targetId) or 0
    targetX = tonumber(targetX) or 0
    targetY = tonumber(targetY) or 0
    if targetId <= 0 or targetName == '' then return nil, nil end
    local baseName = ux.normalizeWatchTargetName and ux.normalizeWatchTargetName(targetName) or targetName:gsub('%s*%([^)]+%)%s*$', '')
    local currentKeys, currentWatches = ux.currentZoneWatchPairs()
    local bestWatch, bestKey, bestDistSq = nil, nil, math.huge
    for i, watch in ipairs(currentWatches or {}) do
        if watch then
            local desired = watch.mode == 'smart' and ux.smartDesiredName(watch) or tostring(watch.label or ''):lower()
            local phSet = ux.watchPhNameSet and ux.watchPhNameSet(watch) or {}
            local desiredHit = desired ~= '' and (desired == targetName or desired == baseName)
            local phHit = phSet[targetName] or phSet[baseName]
                or (ux.watchLabelListedAsPh and (ux.watchLabelListedAsPh(watch, targetName) or ux.watchLabelListedAsPh(watch, baseName)))
            if desiredHit or phHit then
                if phHit and not desiredHit and ux.watchHasPoint(watch) then
                    if ux.rowIsPlaceholderAtWatchCamp and not ux.rowIsPlaceholderAtWatchCamp(watch, {
                        name = targetName, id = targetId, x = targetX, y = targetY,
                    }) then
                        goto continue_target_evidence
                    end
                end
                local dx = targetX - (tonumber(watch.lastX) or 0)
                local dy = targetY - (tonumber(watch.lastY) or 0)
                local distSq = dx * dx + dy * dy
                if distSq < bestDistSq then
                    bestDistSq = distSq
                    bestWatch = watch
                    bestKey = tostring(currentKeys and currentKeys[i] or '')
                end
            end
        end
        ::continue_target_evidence::
    end
    return bestWatch, bestKey
end

ux.recentWatchTargetActive = function(maxAgeMs)
    local recent = ux.recentWatchTarget
    if type(recent) ~= 'table' then return false end
    local id = tonumber(recent.id or 0) or 0
    if id <= 0 then return false end
    local age = nowMs() - (tonumber(recent.at) or 0)
    if age > (tonumber(maxAgeMs) or tonumber(ux.recentWatchTargetMs) or 7000) then return false end
    local zoneIdentity = ux.currentZoneRuntimeIdentity and ux.currentZoneRuntimeIdentity() or currentZoneShort()
    return tostring(recent.zoneIdentity or '') == tostring(zoneIdentity or '')
end

ux.recentWatchTargetBaselineDeferActive = function()
    if not (ux.recentWatchTargetActive and ux.recentWatchTargetActive()) then return false, 0, 0 end
    local recent = ux.recentWatchTarget
    local cap = tonumber(ux.recentWatchTargetBaselineDeferMs) or 5000
    local firstSeenAt = tonumber(recent and recent.firstSeenAt or 0) or 0
    if firstSeenAt <= 0 then firstSeenAt = tonumber(recent and recent.at or 0) or 0 end
    local age = nowMs() - firstSeenAt
    return age <= cap, age, cap
end

ux.armWatchTargetDeath = function(watch, target, suppressAlerts, reason)
    if not watch or type(target) ~= 'table' then return false end
    local targetId = tonumber(target.id or 0) or 0
    if targetId > 0 then
        watch.lastSpawnId = targetId
        if watch.isUp == true or watch.pointOccupied == true then
            watch.occupantSpawnId = targetId
        end
    end
    local targetName = tostring(target.name or watch.currentName or watch.occupantName or watch.label or '')
    local targetNameLower = targetName:lower()
    local desired = watch.mode == 'smart' and ux.smartDesiredName(watch) or tostring(watch.label or ''):lower()
    local row = {
        id = targetId,
        name = targetName ~= '' and targetName or tostring(watch.label or ''),
        x = tonumber(target.x) or tonumber(watch.lastX),
        y = tonumber(target.y) or tonumber(watch.lastY),
        z = tonumber(target.z) or tonumber(watch.lastZ),
    }
    local phKill = desired ~= '' and desired ~= targetNameLower
        and ((ux.watchPhNameSet and ux.watchPhNameSet(watch)[targetNameLower])
            or (ux.watchLabelListedAsPh and ux.watchLabelListedAsPh(watch, targetNameLower)))
    if armWatchRespawnTimer(watch, os.time(), suppressAlerts, {
        reason = reason or (phKill and 'ph_killed' or 'despawned'),
        skipFalsePositiveCheck = true,
        allowColdDown = true,
        confirmedKill = true,
        lastRow = row,
        deathName = row.name,
        previousName = phKill and row.name or nil,
        alertPrefix = phKill and 'PH killed' or 'Killed',
    }) then
        if ux.markWatchStateDirty then ux.markWatchStateDirty() end
        if ux.queueWatchSaveWhenSafe then ux.queueWatchSaveWhenSafe('target-death') end
        return true
    end
    return false
end

ux.applyWatchedTargetLive = function(watch, target, suppressAlerts)
    if not watch or type(target) ~= 'table' then return false end
    local id = tonumber(target.id or 0) or 0
    local name = trim(tostring(target.name or ''))
    if id <= 0 or name == '' then return false end
    local row = {
        id = id,
        name = name,
        x = tonumber(target.x) or tonumber(watch.lastX),
        y = tonumber(target.y) or tonumber(watch.lastY),
        z = tonumber(target.z) or tonumber(watch.lastZ),
        level = tonumber(target.level) or 0,
        distance = tonumber(target.distance) or 0,
        type = tostring(target.type or 'NPC'),
        body = tostring(target.body or ''),
        dead = false,
        targetable = true,
    }
    if ux.finalizeSpawnRow then ux.finalizeSpawnRow(row) end
    local nameLower = tostring(row.name_l or name:lower())
    local desired = watch.mode == 'smart' and ux.smartDesiredName(watch) or tostring(watch.label or ''):lower()
    local baseLower = nameLower:gsub('%s*%([^)]+%)%s*$', '')
    local desiredHit = desired ~= '' and (desired == nameLower or desired == baseLower)
    local phHit = not desiredHit and not (ux.rowIsMutualSeedNamedForSibling and ux.rowIsMutualSeedNamedForSibling(watch, row))
        and ((ux.watchPhNameSet and ux.watchPhNameSet(watch)[nameLower])
        or (ux.watchLabelListedAsPh and ux.watchLabelListedAsPh(watch, nameLower)))
    if desiredHit then
        local canResolve, rejectReason = true, ''
        if ux.liveNamedCanResolveWatch then
            canResolve, rejectReason = ux.liveNamedCanResolveWatch(watch, row)
        end
        if canResolve ~= true then
            if rejectReason == 'same-name-off-anchor' or rejectReason == 'outside-area' then
                ux.recordIgnoredOffAnchorNamed(watch, row, rejectReason)
            end
            return false
        end
        local beforeUp = watch.isUp == true
            and tonumber(watch.occupantSpawnId or 0) == id
            and tostring(watch.currentName or '') == row.name
            and (tonumber(watch.expectedRespawnAt or 0) or 0) <= 0
        local changed = ux.applyFoundWatchState(watch, row, os.time(), currentZoneShort(), suppressAlerts) or false
        if changed or not beforeUp then
            ux.markWatchStateDirty()
            if ux.recordPerfLine then
                ux.recordPerfLine(string.format('Watch target live label=%s id=%s name=%s kind=named',
                    tostring(watch.label or watch.desiredName or '-'), tostring(id), tostring(row.name or '-')))
            end
            return true
        end
        return false
    elseif phHit then
        if ux.watchHasPoint and ux.watchHasPoint(watch) then
            local atCamp = ux.rowIsPlaceholderAtWatchCamp and ux.rowIsPlaceholderAtWatchCamp(watch, row)
            if not atCamp then return false end
        end
        local changed = watch.pointOccupied ~= true
            or tonumber(watch.occupantSpawnId or 0) ~= id
            or tostring(watch.currentName or '') ~= row.name
            or (tonumber(watch.expectedRespawnAt or 0) or 0) > 0
            or (tonumber(watch.despawnedAt or 0) or 0) > 0
            or watch.isUp == true
        if not changed then return false end
        watch.isUp = false
        watch.initialResolved = true
        watch.pointOccupied = true
        watch.currentName = row.name
        watch.currentIsDesired = false
        watch.occupantSpawnId = id
        watch.occupantName = row.name
        watch.occupantConfirmedAtAnchor = true
        watch.alertArmed = true
        watch.expectedRespawnAt = 0
        watch.expectedRespawnSource = ''
        watch.despawnedAt = 0
        watch.killedAtText = ''
        watch.lastOccupiedAt = os.time()
        watch.lastOccupantName = row.name
        watch.lastOccupantId = id
        local zoneTable = ux.getZoneRespawns(currentZoneShort(), true)
        ux.ensurePointEntry(zoneTable, row, row.name)
        if ux.maybeFireAlwaysPing then ux.maybeFireAlwaysPing(watch, row, suppressAlerts) end
        ux.markWatchStateDirty()
        if ux.recordPerfLine then
            ux.recordPerfLine(string.format('Watch target live label=%s id=%s name=%s kind=ph',
                tostring(watch.label or watch.desiredName or '-'), tostring(id), tostring(row.name or '-')))
        end
        return true
    elseif ux.rowIsMutualSeedNamedForSibling and ux.rowIsMutualSeedNamedForSibling(watch, row) then
        if ux.watchHasPoint and ux.watchHasPoint(watch) then
            local atCamp = ux.rowAtWatchAnchor and ux.rowAtWatchAnchor(watch, row)
            if not atCamp and not (ux.rowIsPlaceholderAtWatchCamp and ux.rowIsPlaceholderAtWatchCamp(watch, row)) then
                return false
            end
        end
        local blockName = tostring(row.name or '')
        local blockId = tonumber(row.id) or 0
        local changed = tostring(watch.poolBlockName or '') ~= blockName
            or (tonumber(watch.poolBlockSpawnId) or 0) ~= blockId
            or watch.isUp == true
            or watch.pointOccupied == true
            or (tonumber(watch.expectedRespawnAt) or 0) > 0
        if not changed then return false end
        watch.poolBlockName = blockName
        watch.poolBlockSpawnId = blockId
        watch.currentName = blockName
        watch.isUp = false
        watch.pointOccupied = false
        watch.currentIsDesired = false
        watch.occupantSpawnId = 0
        watch.occupantName = ''
        watch.occupantConfirmedAtAnchor = false
        watch.expectedRespawnAt = 0
        watch.expectedRespawnSource = ''
        watch.despawnedAt = 0
        watch.killedAtText = ''
        watch.initialResolved = true
        if watch.alertArmed ~= true then watch.alertArmed = true end
        ux.markWatchStateDirty()
        if ux.recordPerfLine then
            ux.recordPerfLine(string.format('Watch target live label=%s id=%s name=%s kind=pool_block',
                tostring(watch.label or watch.desiredName or '-'), tostring(id), tostring(row.name or '-')))
        end
        return true
    end
    return false
end

-- Target.Dead is often set before the spawn scan drops the mob; cheap 2x TLO poll.
ux.processWatchedTargetKill = function(suppressAlerts)
    if not enabled or not clientInGame() then return false end
    local targetId = tonumber(safeCall(function() return mq.TLO.Target.ID() end, 0)) or 0
    if targetId <= 0 then return false end
    local targetCleanName = tostring(safeCall(function() return mq.TLO.Target.CleanName() end, '') or '')
    local targetName = targetCleanName:lower()
    local lookupName = ux.normalizeWatchTargetName and ux.normalizeWatchTargetName(targetName) or targetName
    local targetX = tonumber(safeCall(function() return mq.TLO.Target.X() end, 0)) or 0
    local targetY = tonumber(safeCall(function() return mq.TLO.Target.Y() end, 0)) or 0
    local targetZ = tonumber(safeCall(function() return mq.TLO.Target.Z() end, 0)) or 0
    local bestWatch, bestKey = ux.findWatchForTargetEvidence(lookupName, targetId, targetX, targetY)
    if not bestWatch and lookupName ~= targetName then
        bestWatch, bestKey = ux.findWatchForTargetEvidence(targetName, targetId, targetX, targetY)
    end
    if not bestWatch then
        bestWatch, bestKey = ux.findBestWatchForTarget(lookupName, targetId, targetX, targetY)
    end
    if not bestWatch then
        local recent = ux.recentWatchTarget
        if type(recent) == 'table' then
            local recentKey = tostring(recent.watchKey or '')
            local recentName = ux.normalizeWatchTargetName and ux.normalizeWatchTargetName(recent.name) or tostring(recent.name or '')
            if recentKey ~= '' and watchList[recentKey]
                and (tonumber(recent.id or 0) == targetId or recentName == lookupName) then
                bestWatch = watchList[recentKey]
                bestKey = recentKey
            end
        end
    end
    local targetCorpse = targetName:find('corpse', 1, true) ~= nil
        or lookupName ~= targetName
    local targetDead = safeCall(function() return mq.TLO.Target.Dead() end, false) == true or targetCorpse
    if bestWatch then
        local nowMsValue = nowMs()
        local zoneIdentity = ux.currentZoneRuntimeIdentity and ux.currentZoneRuntimeIdentity() or currentZoneShort()
        local previous = ux.recentWatchTarget
        local sameRecent = type(previous) == 'table'
            and tonumber(previous.id or 0) == targetId
            and tostring(previous.watchKey or '') == tostring(bestKey or '')
            and tostring(previous.zoneIdentity or '') == tostring(zoneIdentity or '')
        ux.recentWatchTarget = {
            at = nowMsValue,
            firstSeenAt = sameRecent and (tonumber(previous.firstSeenAt or previous.at or nowMsValue) or nowMsValue) or nowMsValue,
            id = targetId,
            name = targetName,
            x = targetX,
            y = targetY,
            z = targetZ,
            watchKey = bestKey,
            zoneIdentity = zoneIdentity,
        }
        if not targetDead then
            ux.applyWatchedTargetLive(bestWatch, {
                id = targetId,
                name = targetCleanName ~= '' and targetCleanName or targetName,
                x = targetX,
                y = targetY,
                z = targetZ,
                level = safeCall(function() return mq.TLO.Target.Level() end, 0),
                distance = safeCall(function() return mq.TLO.Target.Distance() end, 0),
                type = safeCall(function() return mq.TLO.Target.Type() end, 'NPC'),
                body = safeCall(function() return mq.TLO.Target.Body() end, ''),
            }, suppressAlerts)
        end
    end

    if not targetDead then return false end
    local nowMsValue = nowMs()
    local cache = ux.watchedTargetKillCache or { id = 0, at = 0 }
    if cache.id == targetId and (nowMsValue - (tonumber(cache.at) or 0)) < 500 then return false end
    ux.watchedTargetKillCache = { id = targetId, at = nowMsValue }

    if bestWatch then
        return ux.armWatchTargetDeath(bestWatch, {
            id = targetId,
            name = safeCall(function() return mq.TLO.Target.CleanName() end, bestWatch.label) or bestWatch.label,
            x = targetX,
            y = targetY,
            z = targetZ,
        }, suppressAlerts, 'target_dead')
    end
    return false
end

ux.processWatchedXTargetEvidence = function(suppressAlerts)
    if not enabled or not clientInGame() then return false end
    local nowMsValue = nowMs()
    if nowMsValue - (tonumber(ux.lastWatchedXTargetEvidenceMS) or 0) < 750 then return false end
    ux.lastWatchedXTargetEvidenceMS = nowMsValue
    local xtCount = tonumber(safeCall(function() return mq.TLO.XTarget()() end, 0)) or 0
    if xtCount <= 0 then return false end
    local changed = false
    for i = 1, math.min(xtCount, 20) do
        local spawn = safeCall(function() return mq.TLO.XTarget(i)() end, nil)
        if spawn then
            local id = tonumber(safeCall(function() return spawn.ID() end, 0)) or 0
            local name = tostring(safeCall(function() return spawn.CleanName() end, '') or '')
            if name == '' then name = tostring(safeCall(function() return spawn.Name() end, '') or '') end
            if id > 0 and name ~= '' and safeCall(function() return spawn.Dead() end, false) ~= true then
                local x = tonumber(safeCall(function() return spawn.X() end, 0)) or 0
                local y = tonumber(safeCall(function() return spawn.Y() end, 0)) or 0
                local watch = ux.findWatchForTargetEvidence(name:lower(), id, x, y)
                if watch and ux.applyWatchedTargetLive(watch, {
                    id = id,
                    name = name,
                    x = x,
                    y = y,
                    z = tonumber(safeCall(function() return spawn.Z() end, 0)) or 0,
                    level = tonumber(safeCall(function() return spawn.Level() end, 0)) or 0,
                    distance = tonumber(safeCall(function() return spawn.Distance() end, 0)) or 0,
                    type = tostring(safeCall(function() return spawn.Type() end, 'NPC') or 'NPC'),
                    body = tostring(safeCall(function() return spawn.Body() end, '') or ''),
                }, suppressAlerts) then
                    changed = true
                end
            end
        end
    end
    if changed and ux.queueWatchSaveWhenSafe then ux.queueWatchSaveWhenSafe('xtarget-evidence') end
    return changed
end

ux.processRecentWatchTargetDeaths = function(suppressAlerts)
    local recent = ux.recentWatchTarget
    if type(recent) ~= 'table' then return false end
    local age = nowMs() - (tonumber(recent.at) or 0)
    if age > (tonumber(ux.recentWatchTargetMs) or 7000) then
        ux.recentWatchTarget = nil
        return false
    end
    if tostring(recent.zoneIdentity or '') ~= tostring(ux.currentZoneRuntimeIdentity and ux.currentZoneRuntimeIdentity() or currentZoneShort()) then
        ux.recentWatchTarget = nil
        return false
    end
    local id = tonumber(recent.id or 0) or 0
    if id <= 0 then return false end
    local spawn = safeCall(function() return mq.TLO.Spawn('id ' .. tostring(id)) end, nil)
    local seenId = spawn and (tonumber(safeCall(function() return spawn.ID() end, 0)) or 0) or 0
    local name = spawn and tostring(safeCall(function() return spawn.CleanName() end, '') or '') or ''
    if name == '' then name = tostring(recent.name or '') end
    local typ = spawn and tostring(safeCall(function() return spawn.Type() end, '') or ''):lower() or ''
    local body = spawn and tostring(safeCall(function() return spawn.Body() end, '') or ''):lower() or ''
    local dead = seenId > 0 and safeCall(function() return spawn.Dead() end, false) == true
    local corpse = name:lower():find('corpse', 1, true) ~= nil
        or typ:find('corpse', 1, true) ~= nil
        or body:find('corpse', 1, true) ~= nil
    local missing = seenId <= 0
    if not (dead or corpse or missing) then return false end
    local firstSeenAt = tonumber(recent.firstSeenAt or recent.at or 0) or 0
    local missingThreshold = 2
    if firstSeenAt > 0 and (nowMs() - firstSeenAt) <= 4000 then missingThreshold = 1 end
    recent.missingCount = (dead or corpse) and 2 or ((tonumber(recent.missingCount) or 0) + 1)
    if recent.missingCount < missingThreshold then return false end
    local watch = watchList and watchList[tostring(recent.watchKey or '')] or nil
    if not watch then
        watch = ux.findBestWatchForTarget(tostring(recent.name or ''), id, tonumber(recent.x) or 0, tonumber(recent.y) or 0)
    end
    if watch and ux.armWatchTargetDeath(watch, {
        id = id,
        name = name ~= '' and name or tostring(recent.name or watch.label or ''),
        x = spawn and (tonumber(safeCall(function() return spawn.X() end, recent.x)) or tonumber(recent.x)) or tonumber(recent.x),
        y = spawn and (tonumber(safeCall(function() return spawn.Y() end, recent.y)) or tonumber(recent.y)) or tonumber(recent.y),
        z = spawn and (tonumber(safeCall(function() return spawn.Z() end, recent.z)) or tonumber(recent.z)) or tonumber(recent.z),
    }, suppressAlerts, (dead or corpse) and 'target_cache_dead' or 'target_cache_missing') then
        ux.recentWatchTarget = nil
        return true
    end
    return false
end

-- Catch watched deaths even after the player changes target. Tracks the named
-- when isUp, and seed/learned PH occupants when the camp point is occupied.
ux.processWatchedSpawnIdDeaths = function(suppressAlerts)
    if not enabled or not clientInGame() then return false end
    local nowMsValue = nowMs()
    if nowMsValue - (tonumber(ux.lastWatchedSpawnIdDeathPollMS) or 0) < 450 then return false end
    ux.lastWatchedSpawnIdDeathPollMS = nowMsValue

    local pollState = ux.watchedSpawnIdDeathPollState or {}
    ux.watchedSpawnIdDeathPollState = pollState

    local now = os.time()
    local changed = false
    local _, currentWatches = ux.currentZoneWatchPairs()
    for _, watch in ipairs(currentWatches or {}) do
        if watch and watch.initialResolved then
            local id = 0
            if watch.isUp == true then
                id = tonumber(watch.occupantSpawnId or 0) or 0
                if id <= 0 then id = tonumber(watch.lastSpawnId or 0) or 0 end
                -- Also track named that wandered off-anchor; still need to catch its death.
                if id <= 0 then id = tonumber(watch.offAnchorOccupantId or 0) or 0 end
            elseif watch.pointOccupied == true then
                local occupantName = trim(tostring(watch.currentName or watch.occupantName or ''))
                if occupantName ~= '' and ux.watchPreviousOccupantCanStartTimer
                    and ux.watchPreviousOccupantCanStartTimer(watch, occupantName, false) then
                    id = tonumber(watch.occupantSpawnId or 0) or 0
                end
            else
                local roamingPhId = tonumber(watch.roamingPhSpawnId or 0) or 0
                if roamingPhId > 0 then id = roamingPhId end
            end
            if id > 0 then
                local spawn = safeCall(function() return mq.TLO.Spawn('id ' .. tostring(id)) end, nil)
                local seenId = spawn and (tonumber(safeCall(function() return spawn.ID() end, 0)) or 0) or 0
                local name = spawn and tostring(safeCall(function() return spawn.CleanName() end, '') or '') or ''
                if name == '' and spawn then name = tostring(safeCall(function() return spawn.Name() end, '') or '') end
                local typ = spawn and tostring(safeCall(function() return spawn.Type() end, '') or ''):lower() or ''
                local body = spawn and tostring(safeCall(function() return spawn.Body() end, '') or ''):lower() or ''
                local dead = seenId > 0 and safeCall(function() return spawn.Dead() end, false) == true
                local corpse = name:lower():find('corpse', 1, true) ~= nil
                    or typ:find('corpse', 1, true) ~= nil
                    or body:find('corpse', 1, true) ~= nil
                local missing = seenId <= 0

                if dead or corpse or missing then
                    local state = pollState[id] or { count = 0 }
                    state.count = (dead or corpse) and 2 or ((tonumber(state.count) or 0) + 1)
                    pollState[id] = state
                    if state.count >= 2 then
                        local lastRow = {
                            id = id,
                            name = name ~= '' and name or tostring(watch.currentName or watch.occupantName or watch.label or ''),
                            x = spawn and (tonumber(safeCall(function() return spawn.X() end, watch.lastX)) or tonumber(watch.lastX)) or tonumber(watch.lastX),
                            y = spawn and (tonumber(safeCall(function() return spawn.Y() end, watch.lastY)) or tonumber(watch.lastY)) or tonumber(watch.lastY),
                            z = spawn and (tonumber(safeCall(function() return spawn.Z() end, watch.lastZ)) or tonumber(watch.lastZ)) or tonumber(watch.lastZ),
                        }
                        local phKill = watch.isUp ~= true
                            and (watch.pointOccupied == true or (tonumber(watch.roamingPhSpawnId or 0) or 0) == id)
                        if phKill and missing and not (dead or corpse) then
                            if ux.recordPerfLine then
                                ux.recordPerfLine(string.format(
                                    'Watched PH id missing ignored label=%s id=%s name=%s point=%s',
                                    tostring(watch.label or watch.desiredName or '-'),
                                    tostring(id),
                                    tostring(lastRow.name or '-'),
                                    tostring(watch.lastSpawnPointKey or '-')))
                            end
                            pollState[id] = nil
                            goto continue_watched_spawn_id_death
                        end
                        if armWatchRespawnTimer(watch, now, suppressAlerts, {
                            reason = (dead or corpse) and 'spawn_id_dead' or 'spawn_id_missing',
                            skipFalsePositiveCheck = true,
                            allowColdDown = phKill or nil,
                            confirmedKill = dead or corpse,
                            lastRow = lastRow,
                            deathName = lastRow.name,
                            previousName = phKill and lastRow.name or nil,
                            alertPrefix = (dead or corpse) and (phKill and 'PH killed' or 'Killed') or 'Despawned',
                        }) then
                            pollState[id] = nil
                            changed = true
                            ux.watchGeneration = (tonumber(ux.watchGeneration) or 0) + 1
                            ux.watchRowsCache = { at = 0, key = '', rows = {} }
                            ux.watchDetailRowsCache = { at = 0, key = '', rows = {} }
                            ux.zoneIntelCache = { at = 0, key = '', rows = {} }
                        end
                    end
                    ::continue_watched_spawn_id_death::
                else
                    pollState[id] = nil
                end
            end
        end
    end

    if changed and ux.queueWatchSaveWhenSafe then ux.queueWatchSaveWhenSafe('spawn-id-death') end
    return changed
end

ux.noteWatchAlert = function(watch, kind, reason)
    if not watch then return end
    local text = string.format('%s at %s%s',
        tostring(kind or 'alert'),
        localTimeText(),
        reason and tostring(reason) ~= '' and (' (' .. tostring(reason) .. ')') or '')
    if kind == 'delivered' then
        watch.lastAlertDeliveredText = text
        watch.lastAlertSuppressedReason = ''
        watch.lastAlertAt = os.time()
    elseif kind == 'suppressed' then
        watch.lastAlertSuppressedReason = text
    else
        watch.lastAlertAttemptText = text
    end
end

ux.watchLiveAlertKey = function(row, watch)
    if not row then return '' end
    local rowId = tonumber(row.id or 0) or 0
    local name = trim(tostring(row.name or '')):lower()
    local point = tostring(watch and watch.lastSpawnPointKey or '')
    local label = trim(tostring(watch and (watch.label or watch.desiredName) or '')):lower()
    return table.concat({
        tostring(currentZoneShort and currentZoneShort() or ''),
        point,
        label,
        tostring(rowId),
        name,
    }, '|')
end

ux.watchGlobalLiveAlertKey = function(row)
    if not row then return '' end
    local rowId = tonumber(row.id or 0) or 0
    local name = trim(tostring(row.name or '')):lower()
    if rowId <= 0 and name == '' then return '' end
    return table.concat({
        tostring(currentZoneShort and currentZoneShort() or ''),
        tostring(rowId),
        name,
    }, '|')
end

ux.globalWatchSpawnAlertSeen = function(key, now)
    key = tostring(key or '')
    if key == '' then return false end
    now = tonumber(now) or os.time()
    ux.lastGlobalWatchSpawnAlerts = ux.lastGlobalWatchSpawnAlerts or {}
    local last = tonumber(ux.lastGlobalWatchSpawnAlerts[key] or 0) or 0
    if last > 0 and (now - last) >= 0 and (now - last) < 60 then
        return true
    end
    for k, t in pairs(ux.lastGlobalWatchSpawnAlerts) do
        local age = now - (tonumber(t) or 0)
        if age < 0 or age > 300 then ux.lastGlobalWatchSpawnAlerts[k] = nil end
    end
    return false
end

ux.markGlobalWatchSpawnAlert = function(key, now)
    key = tostring(key or '')
    if key == '' then return end
    ux.lastGlobalWatchSpawnAlerts = ux.lastGlobalWatchSpawnAlerts or {}
    ux.lastGlobalWatchSpawnAlerts[key] = tonumber(now) or os.time()
end

ux.fireWatchSpawnAlert = function(row, watch)
    if not row then return end
    local rowId = tonumber(row.id or 0) or 0
    local alertKey = ux.watchLiveAlertKey(row, watch)
    local globalKey = ux.watchGlobalLiveAlertKey(row)
    local alertNow = os.time()
    if ux.globalWatchSpawnAlertSeen(globalKey, alertNow) then
        ux.noteWatchAlert(watch, 'suppressed', 'same live spawn already announced globally')
        if watch and rowId > 0 then watch.lastDeliveredAlertSpawnId = rowId end
        if watch and alertKey ~= '' then watch.lastDeliveredAlertKey = alertKey end
        return
    end
    if watch and alertKey ~= '' and tostring(watch.lastDeliveredAlertKey or '') == alertKey then
        ux.noteWatchAlert(watch, 'suppressed', 'same live spawn key already alerted')
        return
    end
    if watch and rowId > 0 and tonumber(watch.lastDeliveredAlertSpawnId or 0) == rowId then
        ux.noteWatchAlert(watch, 'suppressed', 'same live spawn already alerted')
        return
    end
    local spawnAlertText = 'Spawn alert: ' .. tostring(row.name or 'mob') .. ' is up - ' .. string.format('%.0fm', tonumber(row.distance) or 0)
    addAlert(spawnAlertText, true)
    wakeAlertPopup()
    playRespawnSound()
    ux.showSpawnPopup(row.name)
    ux.highlightMapSpawn(row)
    announceText(spawnAlertText)
    ux.noteWatchAlert(watch, 'delivered', tostring(row.name or 'mob'))
    ux.markGlobalWatchSpawnAlert(globalKey, alertNow)
    if watch and rowId > 0 then watch.lastDeliveredAlertSpawnId = rowId end
    if watch and alertKey ~= '' then watch.lastDeliveredAlertKey = alertKey end
end

ux.maybeFireAlwaysPing = function(watch, row, suppressAlerts)
    if suppressAlerts or not watch or watch.alwaysPing ~= true or not row then return end
    local rowId = tonumber(row.id or 0) or 0
    local alertKey = ux.watchLiveAlertKey(row, watch)
    if alertKey ~= '' and tostring(watch.lastDeliveredAlertKey or '') == alertKey then return end
    if rowId > 0 and tonumber(watch.lastDeliveredAlertSpawnId or 0) == rowId then return end
    ux.noteWatchAlert(watch, 'attempted', tostring(row.name or 'mob'))
    ux.fireWatchSpawnAlert(row, watch)
end

ux.markWatchStateDirty = function()
    ux.watchGeneration = (tonumber(ux.watchGeneration) or 0) + 1
    ux.watchRowsCache = { at = 0, key = '', rows = {} }
    ux.watchDetailRowsCache = { at = 0, key = '', rows = {} }
    ux.zoneIntelCache = { at = 0, key = '', rows = {} }
    if ux.queueWatchSaveWhenSafe then ux.queueWatchSaveWhenSafe('watch-state') end
end

ux.rowMatchesRecentConfirmedKill = function(watch, row, windowSec)
    if not watch or not row then return false end
    local killAt = tonumber(watch.lastConfirmedKillAt or 0) or 0
    if killAt <= 0 or (os.time() - killAt) > (tonumber(windowSec) or 20) then return false end
    local rowId = tonumber(row.id or 0) or 0
    local killedId = tonumber(watch.lastSpawnId or 0) or 0
    if killedId <= 0 then killedId = tonumber(watch.lastOccupantId or 0) or 0 end
    if rowId > 0 and killedId > 0 and rowId == killedId then return true end
    if rowId > 0 and killedId > 0 and rowId ~= killedId then return false end
    local mode = ux.watchTrackingMode and ux.watchTrackingMode(watch) or tostring(watch.trackingMode or ''):lower()
    if mode == 'point' and ux.watchHasPoint and ux.watchHasPoint(watch) then return false end
    local rowName = tostring(row.name or ''):lower():gsub("%s*'?s corpse%s*$", '')
    local killedName = tostring(watch.lastOccupantName or watch.currentName or watch.occupantName or ''):lower()
    killedName = killedName:gsub("%s*'?s corpse%s*$", '')
    return rowName ~= '' and killedName ~= '' and rowName == killedName
end

ux.applyFoundWatchState = function(watch, found, now, zoneName, suppressAlerts)
    local changed = false
    local foundId = tonumber(found and found.id or 0) or 0
    local canResolve, rejectReason = true, ''
    if ux.liveNamedCanResolveWatch then
        canResolve, rejectReason = ux.liveNamedCanResolveWatch(watch, found)
    end
    if canResolve ~= true then
        if rejectReason == 'same-name-off-anchor' or rejectReason == 'outside-area' then
            ux.recordIgnoredOffAnchorNamed(watch, found, rejectReason)
        end
        return false
    end
    local foundAtAnchor = ux.rowAtWatchAnchor and ux.rowAtWatchAnchor(watch, found) or true
    if (tonumber(watch.expectedRespawnAt or 0) or 0) > now
        and ux.rowMatchesRecentConfirmedKill
        and ux.rowMatchesRecentConfirmedKill(watch, found, 20) then
        if ux.recordPerfLine then
            ux.recordPerfLine(string.format(
                'Watch stale killed row ignored label=%s id=%s name=%s',
                tostring(watch.label or watch.desiredName or '-'),
                tostring(foundId),
                tostring(found and found.name or '-')))
        end
        return false
    end
    if watch.isUp == true
        and watch.initialResolved == true
        and watch.alertArmed ~= true
        and foundId > 0
        and (tonumber(watch.occupantSpawnId or 0) or 0) == foundId
        and tostring(watch.currentName or '') == tostring(found.name or '')
        and watch.pointOccupied == foundAtAnchor
        and (tonumber(watch.expectedRespawnAt or 0) or 0) <= 0
        and (tonumber(watch.despawnedAt or 0) or 0) <= 0 then
        watch.lastSeenAt = now
        return false
    end
    if not watch.zone or watch.zone == '' then watch.zone = zoneName; changed = true end
    if not watch.category or watch.category == '' or (found.named and tostring(watch.category or ''):lower() ~= 'named') then
        watch.category = found.named and 'named' or 'normal'
        changed = true
    end
    if watch.isUp == false and watch.initialResolved then
        if watch.alertArmed == true then
            ux.noteWatchAlert(watch, 'attempted', tostring(found.name or 'mob'))
            if not suppressAlerts then
                ux.fireWatchSpawnAlert(found, watch)
            else
                ux.noteWatchAlert(watch, 'suppressed', 'refresh suppressed alerts')
            end
        else
            ux.noteWatchAlert(watch, 'suppressed', 'alert not armed')
        end
    end
    if watch.isUp == false and watch.initialResolved and watch.alertArmed == true then
        if (tonumber(watch.despawnedAt) or 0) > 0 then
            local observed = now - (tonumber(watch.despawnedAt) or now)
            local foundPointKey = ux.spawnPointKey and ux.spawnPointKey(found) or nil
            if not watch.lastSpawnPointKey or watch.lastSpawnPointKey == foundPointKey or not ux.watchPointTrusted(watch) then
                ux.recordObservation(watch.label, observed, found)
            end
        end
    end
    if watch.alertArmed ~= false
        or watch.isUp ~= true
        or watch.pointOccupied ~= foundAtAnchor
        or tostring(watch.currentName or '') ~= tostring(found.name or '')
        or watch.currentIsDesired ~= true
        or (tonumber(watch.expectedRespawnAt or 0) or 0) > 0
        or (tonumber(watch.despawnedAt or 0) or 0) > 0
        or (tonumber(watch.roamingPhSpawnId or 0) or 0) > 0
        or (tonumber(watch.poolBlockSpawnId or 0) or 0) > 0 then
        changed = true
    end
    local zoneTable = ux.getZoneRespawns(zoneName, true)
    ux.ensurePointEntry(zoneTable, found, found.name)
    watch.alertArmed = false
    ux.updateSmartWatchLearning(watch, found)
    watch.isUp = true
    watch.pointOccupied = foundAtAnchor
    watch.currentName = found.name
    watch.currentIsDesired = true
    ux.clearRoamingPh(watch)
    ux.clearWatchPoolBlock(watch)
    watch.occupantSpawnId = tonumber(found.id) or 0
    watch.occupantName = found.name
    watch.occupantConfirmedAtAnchor = foundAtAnchor
    if foundAtAnchor then
        watch.offAnchorOccupantId = 0
        watch.offAnchorOccupantName = ''
        watch._roamerHitCount = 0  -- reset: named found at anchor, no pending roamer promotion
    else
        watch.offAnchorOccupantId = tonumber(found.id) or 0
        watch.offAnchorOccupantName = found.name or ''
    end
    watch.emptySeenCount = 0
    watch.lastSeenAt = now
    watch.despawnedAt = 0
    watch.killedAtText = ''
    watch.expectedRespawnAt = 0
    watch.initialResolved = true
    ux.rememberWatchLiveMatch(watch, found)
    return changed
end

ux.applyMissingWatchState = function(watch, watchKey, now, zoneName, suppressAlerts)
    local changed = false
    local pointWasOccupied = watch.pointOccupied == true
    local pointWasConfirmedAtAnchor = watch.occupantConfirmedAtAnchor == true
    local previousOccupantId = tonumber(watch.occupantSpawnId or 0) or 0
    local previousExpectedRespawnAt = tonumber(watch.expectedRespawnAt or 0) or 0
    local previousDespawnedAt = tonumber(watch.despawnedAt or 0) or 0
    local previousPointName = tostring(watch.currentName or '')
    if previousPointName == '' then previousPointName = tostring(watch.occupantName or '') end
    if previousPointName == '' then previousPointName = tostring(watch.lastOccupantName or '') end
    local refreshSparse = ux.isSparseWatchRefresh and ux.isSparseWatchRefresh() or false
    local namedPresence = ux.findZoneNamedPresenceRow and ux.findZoneNamedPresenceRow(watch) or nil
    if namedPresence then
        return ux.applyFoundWatchState(watch, namedPresence, now, zoneName, suppressAlerts)
    end
    local occupant = ux.cachedWatchOccupantRow and ux.cachedWatchOccupantRow(watch, watchKey) or ux.watchPointOccupiedRow(watch, watchKey)
    if occupant and ux.rowIsDesiredForWatch(watch, occupant) then
        return ux.applyFoundWatchState(watch, occupant, now, zoneName, suppressAlerts)
    end
    if not occupant and pointWasOccupied and pointWasConfirmedAtAnchor and refreshSparse and previousOccupantId > 0 then
        occupant = ux.resolveStickyWatchOccupant and ux.resolveStickyWatchOccupant(watch, previousOccupantId) or nil
    end
    local siblingBlock = nil
    if occupant and ux.rowIsMutualSeedNamedForSibling and ux.rowIsMutualSeedNamedForSibling(watch, occupant) then
        siblingBlock = occupant
        occupant = nil
    end
    if occupant and not ux.rowCountsAsWatchCampPh(watch, occupant, { allowStickyPull = true, allowRoamingPh = true }) then
        if ux.recordPerfLine then
            ux.recordPerfLine(string.format(
                'Watch rejected zone-wide PH label=%s point=%s by=%s id=%s dist=%s',
                tostring(watch.label or watch.desiredName or '-'),
                tostring(watch.lastSpawnPointKey or '-'),
                tostring(occupant.name or '-'),
                tostring(occupant.id or '-'),
                tostring(occupant.distance or '-')))
        end
        occupant = nil
    end
    if occupant and previousExpectedRespawnAt > os.time()
        and not ux.rowAtWatchAnchor(watch, occupant)
        and not ux.rowIsPlaceholderAtWatchCamp(watch, occupant) then
        occupant = nil
    end
    if occupant and previousExpectedRespawnAt > os.time()
        and ux.rowMatchesRecentConfirmedKill
        and ux.rowMatchesRecentConfirmedKill(watch, occupant, 20) then
        if ux.recordPerfLine then
            ux.recordPerfLine(string.format(
                'Watch stale killed PH ignored label=%s point=%s id=%s name=%s',
                tostring(watch.label or watch.desiredName or '-'),
                tostring(watch.lastSpawnPointKey or '-'),
                tostring(occupant.id or '-'),
                tostring(occupant.name or '-')))
        end
        occupant = nil
    end
    if occupant and pointWasOccupied ~= true and ux.recordPerfLine then
        ux.recordPerfLine(string.format('Watch point occupied label=%s point=%s by=%s id=%s',
            tostring(watch.label or watch.desiredName or '-'), tostring(watch.lastSpawnPointKey or '-'),
            tostring(occupant.name or '-'), tostring(occupant.id or '-')))
    end
    if not occupant and not siblingBlock and pointWasOccupied and pointWasConfirmedAtAnchor and refreshSparse then
        return changed
    end
    if siblingBlock then
        local blockName = tostring(siblingBlock.name or '')
        local blockId = tonumber(siblingBlock.id) or 0
        if tostring(watch.poolBlockName or '') ~= blockName
            or (tonumber(watch.poolBlockSpawnId) or 0) ~= blockId then
            changed = true
        end
        watch.poolBlockName = blockName
        watch.poolBlockSpawnId = blockId
        watch.currentName = blockName
        watch.pointOccupied = false
        watch.currentIsDesired = false
        watch.occupantSpawnId = 0
        watch.occupantName = ''
        watch.occupantConfirmedAtAnchor = false
        watch.isUp = false
        watch.emptySeenCount = 0
        if (tonumber(watch.expectedRespawnAt) or 0) > 0
            or (tonumber(watch.despawnedAt) or 0) > 0 then
            watch.expectedRespawnAt = 0
            watch.expectedRespawnSource = ''
            watch.despawnedAt = 0
            watch.killedAtText = ''
            changed = true
        end
        if watch.initialResolved then watch.alertArmed = true end
    else
        ux.clearWatchPoolBlock(watch)
        local occupantAtAnchor = occupant and (ux.rowAtWatchAnchor and ux.rowAtWatchAnchor(watch, occupant) or true) or false
        local occupantIsRoamingPh = occupant ~= nil
            and occupantAtAnchor ~= true
            and not (ux.rowIsDesiredForWatch and ux.rowIsDesiredForWatch(watch, occupant))
        if occupantIsRoamingPh then
            if ux.setRoamingPh(watch, occupant, 'presence-off-anchor') then changed = true end
        elseif occupant then
            ux.clearRoamingPh(watch)
        end
        watch.pointOccupied = occupant ~= nil and occupantIsRoamingPh ~= true
        watch.currentName = occupant and occupant.name or ''
        watch.currentIsDesired = false
        watch.occupantSpawnId = occupant and (tonumber(occupant.id) or 0) or 0
        watch.occupantName = occupant and occupant.name or ''
        watch.occupantConfirmedAtAnchor = occupant and occupantIsRoamingPh ~= true
            and ((watch.occupantConfirmedAtAnchor == true) or spawnPointKey(occupant) == tostring(watch.lastSpawnPointKey or '') or ux.rowWithinWatchAnchor(watch, occupant)) or false
        if occupant then
            local occupantName = tostring(occupant.name or '')
            local occupantId = tonumber(occupant.id or 0) or 0
            if pointWasOccupied ~= (occupantIsRoamingPh ~= true)
                or previousPointName ~= occupantName
                or previousOccupantId ~= occupantId
                or previousExpectedRespawnAt > 0
                or previousDespawnedAt > 0 then
                changed = true
            end
            watch.emptySeenCount = 0
            watch.expectedRespawnAt = 0
            watch.expectedRespawnSource = ''
            watch.despawnedAt = 0
            watch.killedAtText = ''
            local zoneTable = ux.getZoneRespawns(zoneName, true)
            ux.ensurePointEntry(zoneTable, occupant, occupant.name)
            if watch.isUp == true and watch.initialResolved then
                watch.isUp = false
                watch.alertArmed = true
                watch.despawnedAt = 0
                watch.killedAtText = ''
                changed = true
                if ux.recordPerfLine then
                    ux.recordPerfLine(string.format('Watch desired absent but point occupied label=%s point=%s occupant=%s id=%s',
                        tostring(watch.label or watch.desiredName or '-'), tostring(watch.lastSpawnPointKey or '-'),
                        tostring(occupant.name or '-'), tostring(occupant.id or '-')))
                end
            end
            if watch.initialResolved and not watch.isUp then watch.alertArmed = true end
            if ux.maybeFireAlwaysPing then ux.maybeFireAlwaysPing(watch, occupant, suppressAlerts) end
        elseif not watch.isUp then
            local roamingPh = ux.liveRoamingPhRow and ux.liveRoamingPhRow(watch) or nil
            if roamingPh then
                if ux.setRoamingPh(watch, roamingPh, 'still-live') then changed = true end
                if ux.maybeFireAlwaysPing then ux.maybeFireAlwaysPing(watch, roamingPh, suppressAlerts) end
                return changed
            end
            ux.clearRoamingPh(watch)
            if (tonumber(watch.despawnedAt) or 0) > 0 and (tonumber(watch.expectedRespawnAt) or 0) <= 0 then
                local respawn, source = ux.effectiveRespawnSeconds(watch)
                if respawn > 0 then
                    watch.expectedRespawnAt = (tonumber(watch.despawnedAt) or now) + respawn
                    watch.expectedRespawnSource = source
                    changed = true
                end
            elseif ux.syncWatchExpectedRespawnFromSeed(watch, now) then
                changed = true
            end
        end
    end
    if watch.isUp == true and watch.initialResolved and not occupant and not siblingBlock then
        if ux.zoneEntryRefreshPending ~= true then
            -- Don't start the timer if the named is still live but roaming off its anchor.
            -- offAnchorOccupantId is set by cachedOccupantRow when the mob moved off anchor.
            local offId = tonumber(watch.offAnchorOccupantId or 0) or 0
            local namedStillLive = offId > 0
                and ux.spawnIndex and ux.spawnIndex.byId
                and ux.spawnIndex.byId[offId] ~= nil
            if not namedStillLive then
                -- Presence fallback: catches roamers that were never seen at their anchor
                -- this session (logged in with them already roaming), so occupantSpawnId
                -- was never set and cachedOccupantRow never populated offAnchorOccupantId.
                -- Only applies to point-mode watches — name/roamer mode already resolves
                -- via presenceByName and would never reach this branch.
                local mode = ux.watchTrackingMode(watch)
                if mode == 'point' and ux.watchHasPoint(watch) then
                    local desired = ux.smartDesiredName(watch)
                    local presRow = desired ~= ''
                        and ux.spawnIndex and ux.spawnIndex.presenceByName
                        and ux.spawnIndex.presenceByName[desired] or nil
                    if presRow and tonumber(presRow.id or 0) > 0 and not presRow.dead then
                        -- Named IS in zone but off-anchor — hold the timer, track his ID.
                        watch.offAnchorOccupantId = tonumber(presRow.id)
                        watch.offAnchorOccupantName = presRow.name or ''
                        namedStillLive = true
                        -- Accumulate consecutive off-anchor presence hits. After 2+
                        -- hits we know this mob genuinely roams; auto-promote to
                        -- 'roamer' trackingMode so findWatchRow resolves from
                        -- presenceByName directly going forward (no more anchor miss).
                        local hits = (tonumber(watch._roamerHitCount) or 0) + 1
                        watch._roamerHitCount = hits
                        if hits >= 2 and watch.trackingMode ~= 'roamer' then
                            watch.trackingMode = 'roamer'
                            changed = true
                            if ux.queueWatchSaveWhenSafe then ux.queueWatchSaveWhenSafe('roamer-promote') end
                            if ux.recordPerfLine then
                                ux.recordPerfLine(string.format(
                                    'Watch auto-promoted to roamer trackingMode: label=%s after %d off-anchor hits',
                                    tostring(watch.label or watch.desiredName or '-'), hits))
                            end
                        end
                    end
                end
            end
            if not namedStillLive then
                if ux.armWatchRespawnTimer(watch, now, suppressAlerts, { reason = 'despawned' }) then changed = true end
            end
        end
    elseif watch.initialResolved and pointWasOccupied and not occupant
        and (tostring(ux.currentRefreshSource or '') ~= 'targeted-watch' or pointWasConfirmedAtAnchor)
        and ux.watchHasPoint(watch)
        and ux.watchTrackingMode(watch) ~= 'roamer'
        and (ux.watchPreviousOccupantCanStartTimer and ux.watchPreviousOccupantCanStartTimer(watch, previousPointName, watch.isUp == true))
        and not (ux.nameMatchesOtherNamedWatch and ux.nameMatchesOtherNamedWatch(watch, previousPointName)
            and not ux.phNameSeedSanctioned(watch, previousPointName)) then
        watch.emptySeenCount = math.min(10, (tonumber(watch.emptySeenCount) or 0) + 1)
        local emptyThreshold = 2
        if ux.watchIsSeedSourced(watch) then
            local imported = select(1, ux.importedRespawnSeconds(watch))
            if (tonumber(imported) or 0) > 0 then emptyThreshold = 1 end
        end
        local respawnSeconds, respawnSource = ux.effectiveRespawnSeconds(watch)
        if (tonumber(respawnSeconds) or 0) > 0 and tostring(respawnSource or '') == 'manual' then
            emptyThreshold = 1
        end
        if watch.emptySeenCount >= emptyThreshold then
            local lastRow = { id = watch.lastOccupantId or watch.lastSpawnId or 0, name = previousPointName ~= '' and previousPointName or watch.label, x = watch.lastX, y = watch.lastY, z = watch.lastZ }
            ux.armWatchRespawnTimer(watch, now, suppressAlerts, {
                reason = 'point_emptied',
                skipFalsePositiveCheck = true,
                allowColdDown = true,
                deathName = lastRow.name,
                previousName = previousPointName,
                lastRow = lastRow,
                alertPrefix = 'Point emptied',
            })
            changed = true
        elseif ux.recordPerfLine then
            ux.recordPerfLine(string.format('Point emptied debounce label=%s point=%s previous=%s',
                tostring(watch.label or watch.desiredName or '-'), tostring(watch.lastSpawnPointKey or '-'),
                tostring(previousPointName ~= '' and previousPointName or '-')))
        end
    elseif not watch.initialResolved then
        watch.isUp = false
        watch.initialResolved = true
        watch.alertArmed = false
        watch.emptySeenCount = 0
        watch.expectedRespawnAt = 0
        watch.expectedRespawnSource = ''
        watch.despawnedAt = 0
        watch.killedAtText = ''
    end
    return changed
end

ux.updateOneWatchState = function(watch, watchKey, now, zoneName, suppressAlerts)
    local changed = false
    local namedPresence = ux.findZoneNamedPresenceRow and ux.findZoneNamedPresenceRow(watch) or nil
    if namedPresence then
        return ux.applyFoundWatchState(watch, namedPresence, now, zoneName, suppressAlerts) or false
    end
    if watch.isUp == true and watch.initialResolved then
        local stickyId = tonumber(watch.occupantSpawnId or 0) or 0
        if stickyId <= 0 then stickyId = tonumber(watch.lastSpawnId or 0) or 0 end
        local row = stickyId > 0 and ux.spawnIndex and ux.spawnIndex.byId and ux.spawnIndex.byId[stickyId] or nil
        local rowName = tostring(row and row.name or ''):lower()
        local rowType = tostring(row and row.type or ''):lower()
        local rowBody = tostring(row and row.body or ''):lower()
        local stickyIsCorpse = rowName:find('corpse', 1, true) or rowType:find('corpse', 1, true) or rowBody:find('corpse', 1, true)
        if row and (row.dead or stickyIsCorpse) then
            if ux.armWatchRespawnTimer(watch, now, suppressAlerts, {
                reason = 'despawned',
                skipFalsePositiveCheck = true,
                confirmedKill = true,
                lastRow = row,
                deathName = row.name or watch.label,
            }) then
                ux.markWatchStateDirty()
                return true
            end
        elseif row and passWatchPresenceFilters(row) then
            local desired = ux.smartDesiredName(watch)
            local rowBase = rowName:gsub('%s*%([^)]+%)%s*$', '')
            if desired ~= '' and (desired == rowName or desired == rowBase) then
                watch.lastSeenAt = now
                return false
            end
        end
    end
    local found = ux.cachedWatchPresenceRow and ux.cachedWatchPresenceRow(watch, watchKey) or ux.findWatchPresenceRow(watch)
    if found then
        changed = ux.applyFoundWatchState(watch, found, now, zoneName, suppressAlerts) or changed
    else
        changed = ux.applyMissingWatchState(watch, watchKey, now, zoneName, suppressAlerts) or changed
    end
    return changed
end

ux.findZoneNamedPresenceRow = function(watch)
    if not watch then return nil end
    local desired = ux.smartDesiredName(watch)
    if desired == '' then return nil end
    local function namedOwnedByWatch(row)
        if not ux.rowNameIsDesiredForWatch(watch, row) then return false end
        local ok, reason = true, ''
        if ux.liveNamedCanResolveWatch then
            ok, reason = ux.liveNamedCanResolveWatch(watch, row)
        end
        if ok ~= true and (reason == 'same-name-off-anchor' or reason == 'outside-area') then
            ux.recordIgnoredOffAnchorNamed(watch, row, reason)
        end
        return ok == true
    end

    local stickyId = tonumber(watch.lastSpawnId or 0) or 0
    if stickyId > 0 and ux.spawnIndex and ux.spawnIndex.byId then
        local row = ux.spawnIndex.byId[stickyId]
        if row and passWatchPresenceFilters(row) and namedOwnedByWatch(row) then return row end
    end

    local indexed = ux.spawnIndex and ux.spawnIndex.presenceByName and ux.spawnIndex.presenceByName[desired] or nil
    if indexed and passWatchPresenceFilters(indexed) and namedOwnedByWatch(indexed) then return indexed end

    for _, row in ipairs(allSpawns or {}) do
        local rowName = row and (row.name_l or tostring(row.name or ''):lower()) or ''
        local rowBase = rowName:gsub('%s*%([^)]+%)%s*$', '')
        if rowName == desired or rowBase == desired then
            if passWatchPresenceFilters(row) and namedOwnedByWatch(row) then return row end
        end
    end
    return nil
end

ux.liveOffAnchorNamedRow = function(watch)
    if not watch then return nil end
    local desired = ux.smartDesiredName and ux.smartDesiredName(watch) or ''
    if desired == '' then return nil end
    local ids = {
        tonumber(watch.offAnchorOccupantId or 0) or 0,
        tonumber(watch.occupantSpawnId or 0) or 0,
        tonumber(watch.lastSpawnId or 0) or 0,
    }
    for _, id in ipairs(ids) do
        local row = id > 0 and ux.spawnIndex and ux.spawnIndex.byId and ux.spawnIndex.byId[id] or nil
        if row and passWatchPresenceFilters(row) and ux.rowNameIsDesiredForWatch(watch, row)
            and not (ux.rowClaimsWatchCamp and ux.rowClaimsWatchCamp(watch, row)) then
            return row
        end
    end
    local siblings = ux.watchCampSiblings and ux.watchCampSiblings(watch) or {}
    if #siblings == 0 then
        local row = ux.spawnIndex and ux.spawnIndex.presenceByName and ux.spawnIndex.presenceByName[desired] or nil
        if row and passWatchPresenceFilters(row) and ux.rowNameIsDesiredForWatch(watch, row)
            and not (ux.rowClaimsWatchCamp and ux.rowClaimsWatchCamp(watch, row)) then
            return row
        end
    end
    return nil
end

ux.applyZoneNamedPresence = function(now, zoneName, suppressAlerts)
    local changed = false
    local _, currentWatches = ux.currentZoneWatchPairs()
    for _, watch in ipairs(currentWatches or {}) do
        local row = ux.findZoneNamedPresenceRow and ux.findZoneNamedPresenceRow(watch) or nil
        if row then
            if ux.applyFoundWatchState(watch, row, now, zoneName, suppressAlerts) then changed = true end
        end
    end
    return changed
end

local function updateWatches(rawRows, suppressAlerts, watchScanHints)
    local now = os.time()
    local zoneName = tostring(ux.watchBaselineZone or '')
    local updateKeys = watchScanHints and watchScanHints.keys or nil
    local resolveAllUnresolved = ux.zoneEntryRefreshPending == true
        and ux.currentZoneWatchesResolved and not ux.currentZoneWatchesResolved()
    local baselinePass = resolveAllUnresolved or ux.zoneEntryRefreshPending == true
    local changed = false
    if ux.ensureZonePhAllocation then ux.ensureZonePhAllocation() end
    local currentKeys, currentWatches = ux.currentZoneWatchPairs()
    if ux.applyZoneNamedPresence and ux.applyZoneNamedPresence(now, zoneName, suppressAlerts) then
        changed = true
    end
    if ux.processRecentWatchTargetDeaths and ux.processRecentWatchTargetDeaths(suppressAlerts) then
        changed = true
    end
    local total = #(currentWatches or {})
    local startIndex = math.max(1, math.min(total > 0 and total or 1, tonumber(ux.watchUpdateCursor) or 1))
    local budgetMs = baselinePass
        and math.max(75, tonumber(ux.watchBaselineUpdateBudgetMs) or 300)
        or math.max(15, tonumber(ux.watchUpdateBudgetMs) or 75)
    local minPerPass = math.max(1, tonumber(ux.watchUpdateMinPerPass) or 1)
    local maxPerPass = updateKeys and total
        or (baselinePass and math.max(minPerPass, tonumber(ux.watchBaselineUpdateMaxPerPass) or 20))
        or math.max(minPerPass, tonumber(ux.watchUpdateMaxPerPass) or 8)
    if total > 0 then maxPerPass = math.min(maxPerPass, total) end
    local tPassStart = nowMs()
    local processed = 0
    local scanned = 0
    ux.watchUpdatePending = false
    while total > 0 and scanned < total do
        local i = ((startIndex + scanned - 1) % total) + 1
        scanned = scanned + 1
        local watch = currentWatches[i]
        local watchKey = tostring(currentKeys and currentKeys[i] or watch)
        local inHints = not updateKeys or updateKeys[watchKey]
        local needsBaseline = resolveAllUnresolved and watch.initialResolved ~= true
        local isDue = ux.watchIsEffectivelyDue and ux.watchIsEffectivelyDue(watch)
        if inHints or needsBaseline or isDue then
            local tWatchOne = nowMs()
            if ux.updateOneWatchState(watch, watchKey, now, zoneName, suppressAlerts) then changed = true end
            local elapsed = nowMs() - tWatchOne
            if elapsed >= (tonumber(ux.watchUpdateSlowThresholdMs) or 250) and ux.recordPerfLine then
                ux.recordPerfLine(string.format(
                    'WatchUpdateSlow label=%s elapsed=%dms key=%s source=%s',
                    tostring(watch and (watch.label or watch.desiredName) or '-'),
                    elapsed,
                    tostring(watchKey or '-'),
                    tostring(ux.currentRefreshSource or '-')))
            end
            if ux.processRecentWatchTargetDeaths and ux.processRecentWatchTargetDeaths(suppressAlerts) then
                changed = true
            end
            processed = processed + 1
            if processed >= maxPerPass then
                ux.watchUpdatePending = scanned < total
                break
            end
            if processed >= minPerPass and (nowMs() - tPassStart) >= budgetMs then
                ux.watchUpdatePending = scanned < total
                break
            end
        end
    end
    if total > 0 then
        ux.watchUpdateCursor = ((startIndex + scanned - 1) % total) + 1
    else
        ux.watchUpdateCursor = 1
    end
    if ux.watchUpdatePending and ux.recordPerfLine then
        ux.recordPerfLine(string.format(
            'WatchUpdate deferred processed=%d scanned=%d total=%d budget=%dms source=%s',
            processed, scanned, total, budgetMs, tostring(ux.currentRefreshSource or '-')))
    end
    if changed and ux.queueWatchSaveWhenSafe then ux.queueWatchSaveWhenSafe('watch-refresh') end
end

ux.watchStaleDueThreshold = function(watch)
    local respawn = 0
    if watch and ux.effectiveRespawnSeconds then
        respawn = tonumber((select(1, ux.effectiveRespawnSeconds(watch)))) or 0
    end
    local byRespawn = respawn > 0 and (respawn * (ux.watchStaleDueRespawnMult or 6)) or 0
    return math.max(tonumber(ux.watchStaleDueMinSec) or 3600, byRespawn)
end

ux.watchDueOverdueSeconds = function(watch)
    local eta = tonumber(watch and watch.expectedRespawnAt or 0) or 0
    if eta <= 0 then return 0 end
    local overdue = os.time() - eta
    return overdue > 0 and overdue or 0
end

ux.watchDueIsStale = function(watch)
    local overdue = ux.watchDueOverdueSeconds and ux.watchDueOverdueSeconds(watch) or 0
    local threshold = ux.watchStaleDueThreshold and ux.watchStaleDueThreshold(watch) or 3600
    return overdue > threshold
end

local function formatEta(ts, watch)
    ts = tonumber(ts) or 0
    if ts <= 0 then return '-' end
    local remain = ts - os.time()
    if remain <= 0 then
        return 'Due'
    end
    return formatSeconds(remain)
end

function etaColorKey(ts)
    local remain = (tonumber(ts) or 0) - os.time()
    if remain <= 0 then return 'alertUp' end
    if remain <= 300 then return 'etaSoon' end
    return 'learned'
end

local function formatDownFor(watch)
    if not watch or watch.isUp or not watch.despawnedAt or watch.despawnedAt <= 0 then return '-' end
    return formatSeconds(os.time() - watch.despawnedAt)
end

local function watchSummary()
    local total, up = 0, 0
    local nextEta, nextLabel, nextWatch = math.huge, nil, nil
    local now = os.time()
    local _, currentWatches = ux.currentZoneWatchPairs()
    for _, w in ipairs(currentWatches or {}) do
        total = total + 1
        if w.isUp then up = up + 1 end
        if not w.isUp and w.expectedRespawnAt and w.expectedRespawnAt > now then
            if w.expectedRespawnAt < nextEta then
                nextEta = w.expectedRespawnAt
                nextLabel = w.label
                nextWatch = w
            end
        end
    end
    if nextEta == math.huge then nextEta = 0 end
    return total, up, nextEta, nextLabel, nextWatch
end

local function watchLocRow(watch)
    if not watch or not watch.lastX or not watch.lastY then return nil end
    return ux.dynamicDirectionRow({ direction = '', name = watch.label or '', x = watch.lastX, y = watch.lastY, z = watch.lastZ })
end

ux.resolveWatchLocRow = function(entry)
    if not entry then return nil end
    local watch = entry.watch
    return entry.row or entry.placeholderRow or entry.poolBlockRow
        or (ux.resolvePoolBlockRow and ux.resolvePoolBlockRow(watch))
        or watchLocRow(watch)
end

-- Nav distance/arrow must use the live spawn when a watch is up, not a stale camp anchor.
ux.resolveNavDisplayRow = function(row, watch, placeholderRow)
    local function freshById(id)
        id = tonumber(id) or 0
        if id > 0 and allSpawnsById then return allSpawnsById[id] end
        return nil
    end
    if row then
        local fresh = freshById(row.id)
        if fresh and passWatchPresenceFilters(fresh) then return fresh end
    end
    if watch then
        local fresh = freshById(watch.occupantSpawnId)
        if fresh and passWatchPresenceFilters(fresh) then return fresh end
        if watch.isUp and ux.findWatchPresenceRow then
            local presence = ux.cachedWatchPresenceRow and ux.cachedWatchPresenceRow(watch) or ux.findWatchPresenceRow(watch)
            if presence then return presence end
        end
    end
    if row and (tonumber(row.id) or 0) > 0 then return row end
    if placeholderRow then return placeholderRow end
    if watch then return watchLocRow(watch) end
    return nil
end

ux.timeAgo = function(ts)
    ts = tonumber(ts) or 0
    if ts <= 0 then return '-' end
    local now = os.time()
    local bucket = math.floor(now / 60)
    ux.timeAgoCache = ux.timeAgoCache or { bucket = 0, values = {} }
    if ux.timeAgoCache.bucket ~= bucket then
        ux.timeAgoCache.bucket = bucket
        ux.timeAgoCache.values = {}
    end
    local cacheKey = tostring(math.floor(ts))
    local cached = ux.timeAgoCache.values[cacheKey]
    if cached then return cached end

    local elapsed = now - ts
    local text = '-'
    if elapsed < 0 then return 'now' end
    -- Zone Intel needs the timestamp for timer math, but the table only needs
    -- a stable age bucket. This avoids noisy per-second text churn.
    if elapsed < 60 then
        text = '<1m ago'
    elseif elapsed < 3600 then
        text = string.format('%dm ago', math.floor(elapsed / 60))
    elseif elapsed < 86400 then
        text = string.format('%dh ago', math.floor(elapsed / 3600))
    elseif elapsed < 2592000 then
        text = string.format('%dd ago', math.floor(elapsed / 86400))
    else
        text = 'old'
    end
    ux.timeAgoCache.values[cacheKey] = text
    return text
end

ux.recordPerfLine = function(text)
    ux.perfLog = ux.perfLog or {}
    table.insert(ux.perfLog, 1, string.format('%s %s', os.date('%H:%M:%S'), tostring(text or '')))
    while #ux.perfLog > (ux.perfLogLimit or 20) do table.remove(ux.perfLog) end
end

ux.recentAlertsForWatch = function(label)
    local needle = tostring(label or ''):lower()
    if needle == '' then return {} end
    local out = {}
    for _, alert in ipairs(alertLog or {}) do
        if tostring(alert.text or ''):lower():find(needle, 1, true) then
            table.insert(out, string.format('%s  %s', tostring(alert.time or ''), tostring(alert.text or '')))
            if #out >= 2 then break end
        end
    end
    return out
end

ux.recordRuntimeError = function(context, err)
    local nowValue = nowMs()
    local message = tostring(err or 'unknown error'):gsub('[\r\n]+', ' | ')
    local line = string.format('RuntimeError context=%s error=%s', tostring(context or '-'), message)
    ux.lastRuntimeErrorText = line
    if (nowValue - (tonumber(ux.lastRuntimeErrorAtMS) or 0)) >= 1000 then
        ux.lastRuntimeErrorAtMS = nowValue
        chat('\\ar' .. line .. '\\ax')
        if ux.recordPerfLine then ux.recordPerfLine(line) end
    end
end

ux.recordSlowPerf = function(key, text, elapsedMs, thresholdMs, throttleMs)
    elapsedMs = tonumber(elapsedMs) or 0
    thresholdMs = tonumber(thresholdMs) or 0
    if elapsedMs < thresholdMs then return end
    local nowValue = nowMs()
    throttleMs = tonumber(throttleMs) or 1000
    ux.perfThrottle = ux.perfThrottle or {}
    local last = tonumber(ux.perfThrottle[key]) or 0
    if last > 0 and (nowValue - last) < throttleMs then return end
    ux.perfThrottle[key] = nowValue
    ux.recordPerfLine(text)
end

ux.exportPerfLog = function()
    local who = currentCharacter()
    if who == '' then who = 'Unknown' end
    local path = turboLogPath('TurboMobs_perf', who)
    local f, err = io.open(path, 'w')
    if not f then chat('Could not write perf log: ' .. tostring(err)); return end
    local _, currentWatchesForPerf = ux.currentZoneWatchPairs()
    local currentWatchCount = #(currentWatchesForPerf or {})
    f:write(string.format('TurboMobs v%s perf log\n', VERSION))
    f:write(string.format('Character: %s\nZone: %s\nZone identity: %s\nTime: %s\n',
        who, currentZoneShort(), ux.currentZoneRuntimeIdentity(), os.date('%Y-%m-%d %H:%M:%S')))
    f:write(string.format('Active tab: %s\nFull open: %s\nWatch open: %s\nEnabled: %s\nDebug: %s\n',
        tostring(ux.activeFullTab or '-'), tostring(showWindow == true), tostring(ux.showAlertPopup == true),
        tostring(enabled == true), tostring(debugMode == true)))
    f:write(string.format('Raw spawns: %d\nVisible rows: %d\nAll watches: %d\nCurrent-zone watches: %d\nLearned points: %d\nSpawn revision: %s\nWatch generation: %s\n\n',
        #allSpawns, #spawns, tableCount(watchList), currentWatchCount,
        ux.zoneIntelLastTotalRows or 0, tostring(ux.spawnDataRevision or 0), tostring(ux.watchGeneration or 0)))
    if ux.lastRefreshTimingText and ux.lastRefreshTimingText ~= '' then f:write(ux.lastRefreshTimingText, '\n') end
    if ux.lastRefreshDecisionText and ux.lastRefreshDecisionText ~= '' then f:write(ux.lastRefreshDecisionText, '\n') end
    if ux.lastRuntimeErrorText and ux.lastRuntimeErrorText ~= '' then f:write(ux.lastRuntimeErrorText, '\n') end
    if ux.lastDrawTimingText and ux.lastDrawTimingText ~= '' then f:write(ux.lastDrawTimingText, '\n') end
    if ux.lastWatchRowsTimingText and ux.lastWatchRowsTimingText ~= '' then f:write(ux.lastWatchRowsTimingText, '\n') end
    if ux.lastWatchPopupTimingText and ux.lastWatchPopupTimingText ~= '' then f:write(ux.lastWatchPopupTimingText, '\n') end
    if ux.lastWatchDetailTimingText and ux.lastWatchDetailTimingText ~= '' then f:write(ux.lastWatchDetailTimingText, '\n') end
    f:write('\n')
    for i = #ux.perfLog, 1, -1 do
        f:write(tostring(ux.perfLog[i]), '\n')
    end
    f:close()
    chat('Wrote perf log: ' .. path)
end

ux.exportDiagnostic = function()
    if ux.syncWatchZoneEntryState then pcall(ux.syncWatchZoneEntryState) end
    local who = currentCharacter()
    if who == '' then who = 'Unknown' end
    local path = turboLogPath('TurboMobs_diag', who)
    local f, err = io.open(path, 'w')
    if not f then chat('Could not write TurboMobs diag: ' .. tostring(err)); return end
    local zoneKeys, zoneWatches = ux.currentZoneWatchPairs()
    zoneKeys = zoneKeys or {}
    zoneWatches = zoneWatches or {}
    local statusCounts = {}
    for i, watch in ipairs(zoneWatches) do
        local entry = { key = zoneKeys[i], watch = watch }
        if ux.resolveWatchDisplayRows then
            local row, placeholderRow, offAnchorRow = ux.resolveWatchDisplayRows(watch, zoneKeys[i])
            entry.row = row
            entry.placeholderRow = placeholderRow
            entry.offAnchorRow = offAnchorRow
            entry.poolBlockRow = ux.resolvePoolBlockRow and ux.resolvePoolBlockRow(watch) or nil
        end
        local status = 'unknown'
        if ux.watchDisplayStatus then
            status = tostring((select(1, ux.watchDisplayStatus(entry))) or 'unknown')
        elseif watch and watch.isUp then
            status = 'UP'
        elseif watch and tonumber(watch.expectedRespawnAt or 0) > 0 then
            status = 'DOWN'
        end
        statusCounts[status] = (statusCounts[status] or 0) + 1
    end

    f:write(string.format('TurboMobs v%s diagnostic\n', VERSION))
    f:write(string.format('Character: %s\nServer: %s\nZone: %s\nZone identity: %s\nTime: %s\n',
        who, currentServer(), currentZoneShort(), ux.currentZoneRuntimeIdentity(), os.date('%Y-%m-%d %H:%M:%S')))
    f:write(string.format('Visible full window: %s\nVisible watch window: %s\nEnabled: %s\nSafe-zone paused: %s\nSafe override: %s\n',
        tostring(showWindow == true), tostring(ux.showAlertPopup == true), tostring(enabled == true),
        tostring(ux.safeZoneScanPaused and ux.safeZoneScanPaused() or false), tostring(ux.safeZoneScanOverride == true)))
    f:write(string.format('Search: text=%q live=%s activeTab=%s page=%s status=%s\n',
        tostring(searchText or ''), tostring(ux.liveSearch == true), tostring(ux.activeFullTab or '-'),
        tostring(ux.searchPage or 1), tostring(statusText or '')))
    local pendingSeed = ux.pendingAllaImport
    local pendingAge = pendingSeed and ((nowMs() - (tonumber(pendingSeed.requestedAt) or nowMs()))) or -1
    local importingAge = ux.allaSeedImportInProgress == true
        and ((nowMs() - (tonumber(ux.allaSeedImportStartedMS) or nowMs()))) or -1
    f:write(string.format('Respawns: loaded=%s loading=%s pendingSave=%s dirty=%s seedAuto=%s seedPending=%s seedImporting=%s seedPendingZone=%s seedPendingAgeMs=%s seedImportAgeMs=%s seedAwaitingZone=%s seedAwaitingAgeMs=%s importStatus=%s\n',
        tostring(ux.respawnsLoaded == true), tostring(ux.respawnsLoadStarted == true),
        tostring(ux.pendingRespawnSave == true), tostring(respawnsDirty == true),
        tostring(ux.seedAutoMaintain == true), tostring(pendingSeed ~= nil),
        tostring(ux.allaSeedImportInProgress == true),
        tostring(pendingSeed and pendingSeed.zone or ''),
        tostring(pendingAge), tostring(importingAge),
        tostring(ux.watchSeedAwaitingZone or ''),
        tostring((tonumber(ux.watchSeedAwaitingSince) or 0) > 0 and (nowMs() - (tonumber(ux.watchSeedAwaitingSince) or nowMs())) or -1),
        tostring(importStatusMsg or '')))
    local watchSaveDeferredAt = tonumber(ux.lastWatchSaveDeferredAt) or 0
    local watchRuntimeDeferredAt = tonumber(ux.lastWatchRuntimeSaveDeferredAt) or 0
    f:write(string.format('Watch save: pending=%s reason=%s deferredAgeSec=%s lastSaveAt=%s lastMs=%s\n',
        tostring(ux.pendingWatchSave == true),
        tostring(ux.pendingWatchSaveReason or ''),
        tostring(watchSaveDeferredAt > 0 and (os.time() - watchSaveDeferredAt) or -1),
        tostring(ux.lastWatchSaveAt or 0),
        tostring(ux.lastWatchSaveMs or 0)))
    f:write(string.format('Watch runtime save: pending=%s reason=%s deferredAgeSec=%s lastSaveAt=%s lastMs=%s\n',
        tostring(ux.pendingWatchRuntimeSave == true),
        tostring(ux.pendingWatchRuntimeSaveReason or ''),
        tostring(watchRuntimeDeferredAt > 0 and (os.time() - watchRuntimeDeferredAt) or -1),
        tostring(ux.lastWatchRuntimeSaveAt or 0),
        tostring(ux.lastWatchRuntimeSaveMs or 0)))
    local sourceText = tostring(ux.currentRefreshSource or '')
    if sourceText == '' then sourceText = tostring(ux.lastRefreshSource or '-') end
    f:write(string.format('Spawns: raw=%d visible=%d allById=%d revision=%s fullRevision=%s source=%s inProgress=%s lastStarted=%s\n',
        #allSpawns, #spawns, tableCount(allSpawnsById or {}), tostring(ux.spawnDataRevision or 0),
        tostring(ux.fullSpawnRevision or 0), sourceText,
        tostring((tonumber(ux.spawnRefreshInProgress) or 0) > 0), tostring(ux.spawnRefreshStartedMS or 0)))
    local nowDiag = nowMs()
    local currentIdentity = ux.currentZoneRuntimeIdentity()
    local latest = ux.lastRefreshDiag or {}
    local latestZone = tostring(latest.zoneIdentity or '')
    local latestAt = tonumber(latest.at) or 0
    local latestAge = latestAt > 0 and (nowDiag - latestAt) or -1
    local inProgressStarted = tonumber(ux.spawnRefreshStartedMS) or 0
    local inProgressAge = inProgressStarted > 0 and (nowDiag - inProgressStarted) or -1
    local inProgressSource = tostring(ux.currentRefreshSource or '')
    if inProgressSource == '' then inProgressSource = tostring(ux.refreshInProgressSource or '') end
    f:write(string.format('Snapshot zones: live=%s full=%s latest=%s current=%s\n',
        tostring(ux.spawnIndexZoneIdentity or '-'), tostring(ux.fullSpawnZoneIdentity or '-'),
        latestZone ~= '' and latestZone or '-', tostring(currentIdentity or '-')))
    f:write(string.format('Refresh state: inProgress=%s count=%s ageMs=%s kind=%s zone=%s source=%s latestKind=%s latestAgeMs=%s latestCurrentZone=%s\n',
        tostring((tonumber(ux.spawnRefreshInProgress) or 0) > 0),
        tostring(ux.spawnRefreshInProgress or 0), tostring(inProgressAge),
        tostring(ux.refreshInProgressKind or ''), tostring(ux.refreshInProgressZoneIdentity or ''),
        inProgressSource,
        tostring(latest.kind or ''), tostring(latestAge),
        tostring(latestZone ~= '' and latestZone == currentIdentity)))
    local scanProgressText = ux.watchScanProgressText and ux.watchScanProgressText() or ''
    local scanProgress = ux.watchScanProgress or {}
    f:write(string.format('Scan progress: %s active=%s phase=%s scanned=%s total=%s watches=%s resolved=%s source=%s\n',
        scanProgressText ~= '' and scanProgressText or '-',
        tostring(scanProgress.active == true), tostring(scanProgress.phase or ''),
        tostring(scanProgress.scanned or 0), tostring(scanProgress.total or 0),
        tostring(scanProgress.watches or 0), tostring(scanProgress.resolved or 0),
        tostring(scanProgress.source or '')))
    if latestZone ~= '' and latestZone ~= currentIdentity then
        f:write('Refresh warning: latest completed refresh is for a different zone; current-zone matching may still be waiting on the first scan.\n')
    end
    f:write(string.format('Watches: total=%d currentZone=%d generation=%s baselineReady=%s zonePending=%s targetedReady=%s\n',
        tableCount(watchList), #zoneWatches, tostring(ux.watchGeneration or 0),
        tostring(ux.watchBaselineReady == true), tostring(ux.zoneEntryRefreshPending == true),
        tostring(ux.targetedWatchRefreshReady == true)))
    f:write('Watch status counts:\n')
    for status, count in pairs(statusCounts) do f:write(string.format('  %s=%d\n', tostring(status), count)) end
    f:write('\nLatest timing:\n')
    f:write(tostring(ux.lastRefreshTimingText or 'none'), '\n')
    if ux.lastRefreshDecisionText and ux.lastRefreshDecisionText ~= '' then f:write(tostring(ux.lastRefreshDecisionText), '\n') end
    if ux.lastRuntimeErrorText and ux.lastRuntimeErrorText ~= '' then f:write(tostring(ux.lastRuntimeErrorText), '\n') end
    f:write('\nCurrent-zone watches (first 40):\n')
    for i, watch in ipairs(zoneWatches) do
        if i > 40 then break end
        local key = zoneKeys[i]
        local entry = { key = key, watch = watch }
        local row, placeholderRow, offAnchorRow = nil, nil, nil
        if ux.resolveWatchDisplayRows then
            row, placeholderRow, offAnchorRow = ux.resolveWatchDisplayRows(watch, key)
            entry.row = row
            entry.placeholderRow = placeholderRow
            entry.offAnchorRow = offAnchorRow
            entry.poolBlockRow = ux.resolvePoolBlockRow and ux.resolvePoolBlockRow(watch) or nil
        end
        local status = ux.watchDisplayStatus and tostring((select(1, ux.watchDisplayStatus(entry))) or '-') or '-'
        local phCount = type(watch.phNames) == 'table' and #watch.phNames or 0
        local seedPhCount = type(watch.seedPhNames) == 'table' and #watch.seedPhNames or 0
        f:write(string.format(
            '%02d status=%s label=%s desired=%s category=%s up=%s current=%s poolBlock=%s occupant=%s spawnId=%s offAnchorId=%s roamingPhId=%s respawnAt=%s timerSource=%s source=%s point=%s seedPoint=%s ph=%d seedPh=%d row=%s placeholder=%s offAnchor=%s\n',
            i, status, tostring(watch.label or ''), tostring(watch.desiredName or ''),
            tostring(watch.category or ''), tostring(watch.isUp == true), tostring(watch.currentName or ''),
            tostring(watch.poolBlockName or ''), tostring(watch.occupantName or ''), tostring(watch.occupantSpawnId or 0),
            tostring(watch.offAnchorOccupantId or 0), tostring(watch.roamingPhSpawnId or 0),
            tostring(watch.expectedRespawnAt or 0), tostring(watch.expectedRespawnSource or ''),
            tostring(watch.source or ''), tostring(watch.lastSpawnPointKey or ''),
            tostring(watch.seedPointLabel or ''), phCount, seedPhCount,
            tostring(row and row.name or ''), tostring(placeholderRow and placeholderRow.name or ''),
            tostring(offAnchorRow and offAnchorRow.name or '')))
    end
    f:write('\nRecent perf:\n')
    for i = #ux.perfLog, math.max(1, #ux.perfLog - 40), -1 do
        f:write(tostring(ux.perfLog[i]), '\n')
    end
    f:close()
    chat('Wrote TurboMobs diag: ' .. path)
end

ux.learnableRow = function(row)
    if not row or row.id == 0 or row.dead then return false end
    if isPetRow(row) then return false end
    return tostring(row.type or ''):lower() == 'npc'
end

ux.pointIsAllaSeed = function(entry)
    if type(entry) ~= 'table' then return false end
    local source = tostring(entry.source or ''):lower()
    local timerSource = tostring(entry.timer_source or ''):lower()
    local sourceUrl = tostring(entry.source_url or ''):lower()
    if tostring(entry.seed_confidence or ''):lower() == 'imported' then return true end
    if tostring(entry.category or ''):lower() == 'seed' then return true end
    if source:find('alla', 1, true) or source:find('lazarus', 1, true) then return true end
    if timerSource:find('alla', 1, true) or timerSource:find('lazarus', 1, true) then return true end
    if sourceUrl:find('lazaruseq.com', 1, true) then return true end
    return false
end

-- Generic learn-all trash (a rat, a skeleton) — not a named/PH camp we want to retain.
ux.pointIsGenericTrashLearn = function(entry)
    if type(entry) ~= 'table' or ux.pointIsAllaSeed(entry) then return false end
    if entry.named_name and trim(tostring(entry.named_name or '')) ~= '' then return false end
    if type(entry.ph_names) == 'table' and #entry.ph_names > 0 then return false end
    local label = trim(tostring(entry.display_name or entry.last_seen_name or ''))
    if label == '' then return true end
    if ux.labelLooksNamed(label) then return false end
    return true
end

ux.shouldLearnSpawnPoint = function(row, key, pointEntry, linkedPoints)
    if not key or not row then return false end
    if linkedPoints and linkedPoints[key] then return true end
    if pointEntry and ux.pointIsAllaSeed(pointEntry) then return true end
    if ux.rowIsNamedOrPH(row) then return true end
    local _, currentWatches = ux.currentZoneWatchPairs()
    local rowName = tostring(row.name or ''):lower()
    for _, watch in ipairs(currentWatches or {}) do
        if watch and tostring(watch.lastSpawnPointKey or '') == key then return true end
        local desired = ux.smartDesiredName(watch)
        if desired ~= '' and desired == rowName then return true end
    end
    if pointEntry and not ux.pointIsGenericTrashLearn(pointEntry) then return true end
    if pointEntry and ux.pointIsGenericTrashLearn(pointEntry) then
        local lastSeen = tonumber(pointEntry.last_seen) or 0
        if lastSeen > 0 and (os.time() - lastSeen) <= (7 * 86400) then return true end
        return false
    end
    return false
end

ux.findLivePointRow = function(pointKey, entry)
    if not pointKey then return nil end
    local indexed = ux.spawnIndex and ux.spawnIndex.byPoint and ux.spawnIndex.byPoint[pointKey]
    if indexed then return indexed end
    if ux.pointIsGenericTrashLearn(entry) then return nil end
    local best, bestDist = nil, math.huge
    local names = {}
    if type(entry) == 'table' then
        if type(entry.ph_names) == 'table' then
            for _, name in ipairs(entry.ph_names) do names[tostring(name or ''):lower()] = true end
        end
        if entry.named_name then names[tostring(entry.named_name or ''):lower()] = true end
        if entry.display_name then names[tostring(entry.display_name or ''):lower()] = true end
    end
    for _, row in ipairs(allSpawns or {}) do
        if spawnPointKey(row) == pointKey then return row end
        if type(entry) == 'table' and passWatchPresenceFilters(row) and names[tostring(row.name or ''):lower()] then
            local dist = ux.rowDistanceFromLoc(row, entry.x, entry.y)
            local radius = tonumber(entry.anchor_radius) or ux.defaultPointOccupantRadius
            if dist and dist <= radius and dist < bestDist then
                best, bestDist = row, dist
            end
        end
    end
    return best
end

ux.updateLearnAllSpawns = function(rawRows)
    if not ux.learnAllSpawns then return end
    local nowMSValue = nowMs()
    if ux.lastLearnAllUpdateMS > 0 and (nowMSValue - ux.lastLearnAllUpdateMS) < (ux.learnAllUpdateMS or 2500) then
        return
    end
    ux.lastLearnAllUpdateMS = nowMSValue
    local zone = currentZoneShort()
    local zoneTable = getZoneRespawns(zone, true)
    local seenForZone = ux.learnAllSeen[zone] or {}
    ux.learnAllSeen[zone] = seenForZone
    local candidates = ux.learnAllCandidates[zone] or {}
    ux.learnAllCandidates[zone] = candidates
    local points = getPointTable(zoneTable, true) or {}
    local linkedPoints = {}
    if ux.watchIndex and ux.watchIndex.current then
        for _, watch in ipairs(ux.watchIndex.current) do
            if type(watch) == 'table' then
                local key = tostring(watch.lastSpawnPointKey or '')
                if key ~= '' then linkedPoints[key] = true end
            end
        end
    else
        for _, watch in pairs(watchList or {}) do
            if ux.watchAppliesToCurrentZone(watch) then
                local key = tostring(watch.lastSpawnPointKey or '')
                if key ~= '' then linkedPoints[key] = true end
            end
        end
    end
    local function pointIsProtected(key, entry)
        if linkedPoints[key] then return true end
        if type(entry) ~= 'table' then return false end
        if ux.pointIsAllaSeed(entry) then return true end
        if (tonumber(entry.respawn_seconds) or tonumber(entry.imported_respawn_seconds) or 0) > 0 then return true end
        if type(entry.samples) == 'table' and #entry.samples >= MIN_SAMPLES_FOR_DISPLAY then
            if not ux.pointIsGenericTrashLearn(entry) then return true end
        end
        return false
    end

    local currentKeys = {}
    local now = os.time()
    for i, row in ipairs(rawRows or {}) do
        if i % 50 == 0 then ux.pumpCommandEvents() end
        if ux.learnableRow(row) then
            local key = spawnPointKey(row)
            local pointEntry = key and points[key] or nil
            if not ux.shouldLearnSpawnPoint(row, key, pointEntry, linkedPoints) then
                goto continue_learn_row
            end
            local trackTransient = false
            if key and not pointEntry and not pointIsProtected(key, pointEntry) then
                if ux.rowIsNamedOrPH(row) then
                    local candidateKey = key .. '|' .. tostring(row.name or ''):lower()
                    local candidate = candidates[candidateKey] or { hits = 0, firstMS = nowMSValue, lastMS = 0 }
                    if nowMSValue - (tonumber(candidate.lastMS) or 0) >= ((ux.learnAllUpdateMS or 2500) - 100) then
                        candidate.hits = (tonumber(candidate.hits) or 0) + 1
                    end
                    candidate.name = row.name
                    candidate.lastRow = { id = row.id, name = row.name, x = row.x, y = row.y, z = row.z }
                    candidate.lastMS = nowMSValue
                    candidates[candidateKey] = candidate
                    if (tonumber(candidate.hits) or 0) >= (tonumber(ux.learnAllCandidateHits) or 3) then
                        trackTransient = true
                    
                        -- If this repeated occupant is standing on a known named camp point,
                        -- promote it into that named watch's PH list.
                        local promotePointEntry = pointEntry
                        if not promotePointEntry and zoneTable and zoneTable._points then
                            promotePointEntry = zoneTable._points[key]
                        end
                    
                        if ux.promoteLearnedPhForPoint then
                            ux.promoteLearnedPhForPoint(key, row, promotePointEntry)
                        end
                    end
                end
            elseif key then
                pointEntry = ensurePointEntry(zoneTable, row, row.name)
            
                -- Existing imported/learned point: track repeated non-named occupants
                -- so Alla-seeded named camps can learn their PHs over time.
                local candidateKey = tostring(key or '') .. '|' .. tostring(row.name or ''):lower()
                local candidate = candidates[candidateKey] or { hits = 0, firstMS = nowMSValue, lastMS = 0 }
            
                if nowMSValue - (tonumber(candidate.lastMS) or 0) >= ((ux.learnAllUpdateMS or 2500) - 100) then
                    candidate.hits = (tonumber(candidate.hits) or 0) + 1
                end
            
                candidate.name = row.name
                candidate.lastRow = { id = row.id, name = row.name, x = row.x, y = row.y, z = row.z }
                candidate.lastMS = nowMSValue
                candidates[candidateKey] = candidate
            
                if (tonumber(candidate.hits) or 0) >= (tonumber(ux.learnAllCandidateHits) or 3) then
                    if ux.promoteLearnedPhForPoint then
                        ux.promoteLearnedPhForPoint(key, row, pointEntry)
                    end
                end
            end
            if (pointEntry or trackTransient) and key then
                currentKeys[key] = row
            end
            if (pointEntry or trackTransient) and key and not (pointEntry and pointEntry.ignored) then
                local cached = seenForZone[key]
                if cached and cached.isUp == false and cached.deathAt and cached.deathAt > 0 then
                    recordObservation(row.name, now - cached.deathAt, row)
                    pointEntry = points[key]
                    candidates[key .. '|' .. tostring(row.name or ''):lower()] = nil
                end
                seenForZone[key] = {
                    isUp = true,
                    name = row.name,
                    lastRow = { id = row.id, name = row.name, x = row.x, y = row.y, z = row.z },
                    deathAt = 0,
                }
            end
            ::continue_learn_row::
        end
    end

    for key, cached in pairs(seenForZone) do
        local pointEntry = zoneTable and zoneTable._points and zoneTable._points[key] or nil
        if cached.isUp and not currentKeys[key] and not (pointEntry and pointEntry.ignored) then
            if pointEntry and ux.shouldLearnSpawnPoint({ name = cached.name, id = 1, dead = false, type = 'NPC' }, key, pointEntry, linkedPoints) then
                recordDeath(cached.name, cached.lastRow)
            end
            cached.isUp = false
            cached.deathAt = now
        end
    end
    for key, candidate in pairs(candidates) do
        if nowMSValue - (tonumber(candidate.lastMS) or 0) > 60000 then
            candidates[key] = nil
        end
    end
end

-- ============================================================
-- Refresh
-- ============================================================

ux.clearRefreshInProgress = function(reason)
    local hadRefresh = (tonumber(ux.spawnRefreshInProgress) or 0) > 0
    ux.spawnRefreshInProgress = 0
    -- Also clear the re-entrancy guard; runs on completion AND error recovery
    -- (main-loop xpcall), so an erroring scan can't wedge refreshSpawns off.
    ux.refreshSpawnsActive = false
    ux.refreshInProgressKind = ''
    ux.refreshInProgressZoneIdentity = ''
    ux.refreshInProgressSource = ''
    ux.currentRefreshSource = ''
    if hadRefresh and reason and reason ~= '' and ux.recordPerfLine then
        ux.recordPerfLine('Refresh state reset: ' .. tostring(reason))
    end
end

local function finishSpawnRefresh()
    ux.spawnRefreshInProgress = math.max(0, (tonumber(ux.spawnRefreshInProgress) or 1) - 1)
    if (tonumber(ux.spawnRefreshInProgress) or 0) <= 0 then
        ux.clearRefreshInProgress()
    end
end

-- True when this zone already has saved watches or learned/seed spawn points.
ux.zoneHasWatchOrSeedData = function(zone)
    zone = tostring(zone or currentZoneShort()):lower()
    if zone == '' or zone == 'unknown' then return false, false end
    for _, watch in pairs(watchList or {}) do
        if type(watch) == 'table' and tostring(watch.zone or ''):lower() == zone then
            return true, false
        end
    end
    local zoneTable = respawnsData and respawnsData[zone]
    local points = zoneTable and zoneTable._points
    if type(points) == 'table' and next(points) ~= nil then
        return false, true
    end
    return false, false
end

-- Detect zone-in before the first refreshSpawns tick (draw can run first).
ux.syncWatchZoneEntryState = function()
    if not clientInGame() then return end
    local zone = currentZoneShort()
    if zone == '' or zone == 'unknown' then return end
    local identity = ux.currentZoneRuntimeIdentity()
    local prevZone = tostring(ux.lastWatchUiZone or ''):lower()
    if prevZone ~= zone then
        if prevZone ~= '' and ux.clearRefreshInProgress then
            ux.clearRefreshInProgress(string.format('zone changed %s -> %s', tostring(prevZone), tostring(zone)))
        end
        if prevZone ~= '' then
            ux.fullSpawnById = nil
            ux.fullSpawnRevision = 0
            ux.fullSpawnZoneIdentity = ''
            spawns = {}
            allSpawns = {}
            allSpawnsById = {}
            ux.spawnIndex = { byId = {}, byName = {}, byPoint = {}, presenceByName = {}, presenceByPoint = {} }
            ux.spawnIndexZoneIdentity = identity
            ux.spawnDataRevision = (tonumber(ux.spawnDataRevision) or 0) + 1
            ux.watchPresenceRowCache = { rev = ux.spawnDataRevision, byKey = {} }
            ux.watchOccupantRowCache = { rev = ux.spawnDataRevision, byKey = {} }
            ux.quickSearchRows = nil
            ux.quickSearchRev = nil
            ux._qsLastTriggerMs = 0
            ux.lastZoneEntryPrimeMS = 0
            ux.forceSearchScanOnZoneIn = true
            if not ux.respawnsLoaded then
                ux.respawnsLoadHardDeadline = nowMs() + 2000
                ux.respawnsLoadAfterMS = 0
            end
        end
        ux._zoneBaselineStartMs = nowMs()
        ux.watchZoneEpoch = (tonumber(ux.watchZoneEpoch) or 0) + 1
        ux.watchZoneEnteredAt = nowMs()
        ux.lastWatchUiZone = zone
        ux.lastWatchUiZoneIdentity = identity
        if prevZone ~= '' then
            ux.watchBaselineReady = false
            ux.zoneEntryRefreshPending = true
            lastWatchRefreshMs = 0
            lastSearchRefreshMs = 0
            lastRefreshMs = 0
        end
        if ux.clearWatchSeedAwaiting then ux.clearWatchSeedAwaiting() end
        -- Cancel any pending quiet (auto-seed) import from the previous zone so
        -- the new zone can always queue its own. Explicit user-triggered imports
        -- (quiet == false) are left intact.
        if ux.pendingAllaImport and ux.pendingAllaImport.quiet and ux.clearSeedImportState then
            ux.clearSeedImportState('Seed import canceled after zoning.')
        elseif ux.allaSeedImportInProgress == true and ux.clearSeedImportState then
            ux.clearSeedImportState('Seed import canceled after zoning.')
        end
        if ux.autoSeedCurrentZone then ux.autoSeedCurrentZone() end
        if ux.repairKnownSeedRoamersForZone then ux.repairKnownSeedRoamersForZone(zone) end
        ux.mutualSeedRepairZones = ux.mutualSeedRepairZones or {}
        ux.mutualSeedRepairZones[zone] = nil
        if ux.spawnSnapshotMatchesCurrentZone and not ux.spawnSnapshotMatchesCurrentZone() then
            ux.watchBaselineReady = false
            ux.watchFullBaselinePending = true
            ux.zoneEntryRefreshPending = true
            lastWatchRefreshMs = 0
        end
        if ux.repairMutualSeedNamedWatchesForZone then
            ux.repairMutualSeedNamedWatchesForZone(zone)
        end
    else
        ux.lastWatchUiZoneIdentity = identity
    end
    -- Zoned before respawn data finished loading: auto-seed was skipped earlier.
    if ux.respawnsLoaded and ux.autoSeedCurrentZone then
        ux.autoSeedCurrentZone()
    end
    if ux.respawnsLoaded and ux.repairMutualSeedNamedWatchesForZone then
        ux.mutualSeedRepairZones = ux.mutualSeedRepairZones or {}
        if not ux.mutualSeedRepairZones[zone] then
            ux.repairMutualSeedNamedWatchesForZone(zone)
        end
    end
    if ux.forceBaselineResolveZoneWatchesIfStale then ux.forceBaselineResolveZoneWatchesIfStale() end
    if (tonumber(ux.spawnRefreshInProgress) or 0) > 0 then
        local started = tonumber(ux.spawnRefreshStartedMS) or 0
        local age = started > 0 and (nowMs() - started) or 0
        if age > (tonumber(ux.zoneEntryPrimeStaleMs) or 12000) and ux.clearRefreshInProgress then
            ux.clearRefreshInProgress(string.format('stale during zone sync ageMs=%d zone=%s', age, zone))
        end
    end
end

-- Mark current-zone watches resolved without a spawn scan (safe hubs, paused
-- tracking, or zone-in timeout). Background tracking continues on next scan.
ux.baselineResolveZoneWatches = function(zone)
    zone = tostring(zone or currentZoneShort() or ''):lower()
    if zone == '' or zone == 'unknown' then return 0 end
    local resolved = 0
    for _, watch in pairs(watchList or {}) do
        if type(watch) == 'table' and tostring(watch.zone or ''):lower() == zone
            and watch.initialResolved ~= true then
            watch.initialResolved = true
            if watch.isUp ~= true then
                watch.alertArmed = false
            end
            resolved = resolved + 1
        end
    end
    if resolved > 0 then
        ux.watchGeneration = (tonumber(ux.watchGeneration) or 0) + 1
        ux.watchRowsCache = { at = 0, key = '', rows = {} }
        ux.watchDetailRowsCache = { at = 0, key = '', rows = {} }
    end
    return resolved
end

ux.forceBaselineResolveZoneWatchesIfStale = function()
    if not clientInGame() then return end
    local settling = ux.zoneEntryRefreshPending == true
        or (ux.currentZoneWatchesResolved and not ux.currentZoneWatchesResolved())
    if not settling then
        ux._zoneBaselineStartMs = 0
        return
    end
    local started = tonumber(ux._zoneBaselineStartMs) or 0
    if started <= 0 then
        ux._zoneBaselineStartMs = nowMs()
        return
    end
    local maxWait = math.max(10000, tonumber(ux.zoneEntryBaselineMaxMs) or 30000)
    if (nowMs() - started) < maxWait then return end
    local snapshotOk = ux.spawnSnapshotMatchesCurrentZone and ux.spawnSnapshotMatchesCurrentZone() or false
    if snapshotOk then
        ux.watchFullBaselinePending = false
        if ux.currentZoneWatchesResolved and ux.currentZoneWatchesResolved()
            and ux.watchUpdatePending ~= true then
            ux.watchBaselineReady = true
            ux.zoneEntryRefreshPending = false
            ux._zoneBaselineStartMs = 0
            ux._settlingStartMs = nil
        else
            ux._zoneBaselineStartMs = nowMs()
            if ux.recordPerfLine then
                ux.recordPerfLine('Zone baseline still reconciling current snapshot')
            end
        end
        return
    end
    -- Safe hubs only: resolve without a spawn scan. Gameplay zones keep scanning.
    if ux.safeZoneScanPaused and ux.safeZoneScanPaused() then
        ux.baselineResolveZoneWatches(currentZoneShort())
        ux.watchBaselineReady = true
        ux.zoneEntryRefreshPending = false
        ux._zoneBaselineStartMs = 0
        ux._settlingStartMs = nil
        return
    end
    ux._zoneBaselineStartMs = nowMs()
    ux.watchBaselineReady = false
    ux.watchFullBaselinePending = true
    if ux.recordPerfLine then
        ux.recordPerfLine('Zone baseline still pending; waiting for first current-zone spawn snapshot')
    end
end

ux.zoneWatchesStillSettling = function()
    if ux.watchBaselineReady == true and ux.zoneEntryRefreshPending ~= true then return false end
    local _, zoneWatches = ux.currentZoneWatchPairs()
    for _, watch in ipairs(zoneWatches or {}) do
        if type(watch) == 'table' and not watch.initialResolved then return true end
    end
    return false
end

ux.currentZoneWatchesResolved = function()
    local _, zoneWatches = ux.currentZoneWatchPairs()
    for _, watch in ipairs(zoneWatches or {}) do
        if type(watch) == 'table' and not watch.initialResolved then return false end
    end
    return true
end

ux.drawWatchLoadingPanel = function(title, detail, zone, footer)
    local dots = string.rep('.', (math.floor((tonumber(nowMs()) or 0) / 450) % 3) + 1)
    coloredTextWrapped(tostring(title or 'Loading seed watches') .. dots, 'etaSoon')
    if zone and zone ~= '' then
        coloredTextWrapped('Zone: ' .. tostring(zone), 'muted')
    end
    if detail and detail ~= '' then
        coloredTextWrapped(detail, 'muted')
    end
    if footer and footer ~= '' then
        coloredTextWrapped(footer, 'idle')
    end
end

ux.clearWatchSeedAwaiting = function()
    ux.watchSeedAwaitingZone = ''
    ux.watchSeedAwaitingSince = 0
end

ux.clearSeedImportState = function(reason)
    local hadState = ux.pendingAllaImport ~= nil or ux.allaSeedImportInProgress == true
        or tostring(ux.watchSeedAwaitingZone or '') ~= ''
    ux.pendingAllaImport = nil
    ux.allaSeedImportInProgress = false
    if ux.clearWatchSeedAwaiting then ux.clearWatchSeedAwaiting() end
    if reason and reason ~= '' then importStatusMsg = tostring(reason) end
    if hadState and reason and reason ~= '' and ux.recordPerfLine then
        ux.recordPerfLine('Seed import state reset: ' .. tostring(reason))
    end
end

ux.setWatchSeedAwaiting = function(zone)
    zone = tostring(zone or currentZoneShort()):lower()
    if zone == '' or zone == 'unknown' then return end
    ux.watchSeedAwaitingZone = zone
    ux.watchSeedAwaitingSince = nowMs()
end

-- Turbo Watch / UI: show a short busy line instead of an empty list while loading.
ux.watchBusyState = function()
    if not clientInGame() then return false, '', '' end
    ux.syncWatchZoneEntryState()
    local zone = currentZoneShort()
    local pendingZone = ux.pendingAllaImport and tostring(ux.pendingAllaImport.zone or ''):lower() or ''
    if ux.pendingAllaImport and pendingZone ~= '' and pendingZone ~= zone and ux.pendingAllaImport.quiet == true then
        ux.clearSeedImportState('Seed import canceled after zoning.')
    elseif ux.pendingAllaImport or ux.allaSeedImportInProgress == true then
        local started = ux.pendingAllaImport and tonumber(ux.pendingAllaImport.requestedAt) or tonumber(ux.allaSeedImportStartedMS)
        if started and started > 0 and (nowMs() - started) > 90000 then
            ux.clearSeedImportState('Seed import timed out; use Import This Zone to retry.')
        end
    end
    if ux.pendingAllaImport or ux.allaSeedImportInProgress == true then
        local detail = trim(tostring(importStatusMsg or ''))
        if detail == '' then
            detail = ux.pendingAllaImport and 'Seed import runs when you are idle; watches appear when it finishes.'
                or 'Applying Lazarus seed watches for this zone...'
        end
        return true, 'Loading seed watches...', detail
    end
    local _, zoneWatches = ux.currentZoneWatchPairs()
    if tostring(ux.watchSeedAwaitingZone or ''):lower() == zone
        and #(zoneWatches or {}) == 0
        and (nowMs() - (tonumber(ux.watchSeedAwaitingSince) or 0)) < 300000 then
        local detail = trim(tostring(importStatusMsg or ''))
        if detail == '' then detail = 'Creating named watches from bundled seed data.' end
        return true, 'Loading seed watches...', detail
    end
    if ux.respawnsLoadStarted then
        return true, 'Loading respawn data...', 'Watches may look empty for a few seconds.'
    end
    if not ux.respawnsLoaded and pathExists(respawnsPath) then
        local _, zoneWatchesBusy = ux.currentZoneWatchPairs()
        if #(zoneWatchesBusy or {}) == 0 then
            return true, 'Loading respawn data...', 'Watches may look empty for a few seconds.'
        end
    end
    -- Safe zone check comes first: no seed prep or settling state should gate this.
    if ux.safeZoneScanPaused and ux.safeZoneScanPaused() then
        return true, 'Paused in safe zone', 'Use Scan Here to update this zone. Existing watches stay loaded.'
    end
    if ux.seedAutoMaintain == true and zone ~= '' and zone ~= 'unknown' and not ux.autoSeededZones[zone] then
        local hasWatches, hasPoints = ux.zoneHasWatchOrSeedData(zone)
        if not hasWatches and not hasPoints then
            return false, '', ''
        end
    end
    if not enabled and ux.zoneWatchesStillSettling and ux.zoneWatchesStillSettling() then
        return true, 'Tracking paused', 'Turn tracking ON (Search tab) to finish zone watch baseline after zoning.'
    end
    if ux.zoneWatchesStillSettling and ux.zoneWatchesStillSettling() then
        return true, 'Updating zone watches...', 'Scanning spawns and matching UP/Down state.'
    end
    local _, zoneWatches = ux.currentZoneWatchPairs()
    if ux.seedAutoMaintain == true and #(zoneWatches or {}) == 0 and zone ~= '' and zone ~= 'unknown' then
        return false, '', ''
    end
    return false, '', ''
end

ux.watchScanProgressText = function()
    local p = ux.watchScanProgress
    if type(p) ~= 'table' then return '' end
    local total = tonumber(p.total) or 0
    local scannedText = total > 0 and string.format('%d/%d', tonumber(p.scanned) or 0, total)
        or tostring(tonumber(p.scanned) or 0)
    local watches = tonumber(p.watches) or 0
    local resolved = tonumber(p.resolved) or 0
    if p.active == true then
        return string.format('Scanning %s - Watches %d/%d', scannedText, resolved, watches)
    end
    if ux.watchBaselineReady ~= true or ux.zoneEntryRefreshPending == true then
        return string.format('Scanned %s - Watches %d/%d', scannedText, resolved, watches)
    end
    return ''
end

refreshSpawns = function(force, opts)
    opts = opts or {}
    -- Re-entrancy guard: the scan loop pumps MQ command events mid-scan, so a
    -- queued /tmobs or watch command can re-enter refreshSpawns. Nested scans
    -- leak ux.spawnRefreshInProgress, which strands the Search tab on "running
    -- scan". Skipping is safe -- the in-flight scan rebuilds the whole snapshot.
    if ux.refreshSpawnsActive == true then
        local refreshNow = nowMs()
        local activeRefreshes = tonumber(ux.spawnRefreshInProgress) or 0
        local started = tonumber(ux.spawnRefreshStartedMS) or 0
        local age = started > 0 and (refreshNow - started) or 0
        local currentIdentity = clientInGame() and ux.currentZoneRuntimeIdentity() or ''
        local busyIdentity = tostring(ux.refreshInProgressZoneIdentity or '')
        local wrongZone = currentIdentity ~= '' and busyIdentity ~= '' and currentIdentity ~= busyIdentity
        if activeRefreshes > 0 and (wrongZone or age > (tonumber(ux.zoneEntryPrimeStaleMs) or 12000)) then
            ux.clearRefreshInProgress(string.format('stale active refresh before re-entry skip ageMs=%d busyZone=%s currentZone=%s',
                age, busyIdentity ~= '' and busyIdentity or '-', currentIdentity ~= '' and currentIdentity or '-'))
        else
            if ux.recordPerfLine then ux.recordPerfLine('refreshSpawns re-entrant call skipped') end
            return
        end
    end
    ux.refreshSpawnsActive = true
    local refreshNow = nowMs()
    local activeRefreshes = tonumber(ux.spawnRefreshInProgress) or 0
    if activeRefreshes > 0 then
        local started = tonumber(ux.spawnRefreshStartedMS) or 0
        local age = started > 0 and (refreshNow - started) or 0
        local currentIdentity = clientInGame() and ux.currentZoneRuntimeIdentity() or ''
        local busyIdentity = tostring(ux.refreshInProgressZoneIdentity or '')
        local wrongZone = currentIdentity ~= '' and busyIdentity ~= '' and currentIdentity ~= busyIdentity
        if wrongZone or age > (tonumber(ux.zoneEntryPrimeStaleMs) or 12000) then
            ux.clearRefreshInProgress(string.format('stale before refresh ageMs=%d busyZone=%s currentZone=%s',
                age, busyIdentity ~= '' and busyIdentity or '-', currentIdentity ~= '' and currentIdentity or '-'))
            activeRefreshes = 0
        end
    end
    -- Re-assert the guard: a stale-clear above may have reset it while this
    -- top-level scan is still about to run.
    ux.refreshSpawnsActive = true
    ux.spawnRefreshInProgress = activeRefreshes + 1
    ux.spawnRefreshStartedMS = refreshNow
    local function done()
        finishSpawnRefresh()
    end
    if not clientInGame() then
        spawns = {}
        allSpawns = {}
        allSpawnsById = {}
        ux.spawnIndex = { byId = {}, byName = {}, byPoint = {}, presenceByName = {}, presenceByPoint = {} }
        ux.watchIndex = { byId = {}, byName = {}, downByPoint = {}, current = {}, currentKeys = {} }
        statusText = 'Paused: client is not in-game.'
        lastRefreshMs = nowMs()
        done()
        return
    end
    if not force and not enabled then
        done()
        return
    end
    local watchOnly = opts.watchOnly == true
    local searchOnly = opts.searchOnly == true
    local legacyFull = not watchOnly and not searchOnly
    local buildSearchRows = searchOnly or legacyFull
    local runWatchUpdate = watchOnly or legacyFull
    local refreshKind = searchOnly and 'search' or (watchOnly and 'watch' or 'full')
    local zone = currentZoneShort()
    local zoneIdentity = ux.currentZoneRuntimeIdentity()
    local refreshEpoch = tonumber(ux.watchZoneEpoch) or 0
    local refreshZoneIdentity = zoneIdentity
    local function refreshStillCurrent()
        if not clientInGame() then return false end
        if (tonumber(ux.watchZoneEpoch) or 0) ~= refreshEpoch then return false end
        return tostring(ux.currentZoneRuntimeIdentity() or '') == tostring(refreshZoneIdentity or '')
    end
    ux.refreshInProgressKind = refreshKind
    ux.refreshInProgressZoneIdentity = zoneIdentity
    ux.refreshInProgressSource = 'starting'
    if ux.lastZoneForSafePause ~= zoneIdentity then
        ux.lastZoneForSafePause = zoneIdentity
        ux.safeZoneScanOverride = false
    end
    local previousZone = tostring(ux.watchBaselineZone or ''):lower()
    local zoneChanged = previousZone ~= '' and previousZone ~= zone
    if previousZone ~= zone then
        if zoneChanged then
            for _, watch in pairs(watchList or {}) do
                if type(watch) == 'table' and tostring(watch.zone or ''):lower() == zone then
                    watch.isUp = false
                    watch.initialResolved = false
                    watch.alertArmed = false
                    watch.pointOccupied = false
                    watch.currentName = ''
                    watch.occupantSpawnId = 0
                    watch.occupantName = ''
                    watch.emptySeenCount = 0
                    watch.expectedRespawnAt = 0
                    watch.expectedRespawnSource = ''
                    watch.despawnedAt = 0
                    watch.killedAtText = ''
                end
            end
            ux.watchGeneration = (tonumber(ux.watchGeneration) or 0) + 1
            ux.watchRowsCache = { at = 0, key = '', rows = {} }
            ux.watchDetailRowsCache = { at = 0, key = '', rows = {} }
        end
        if zoneChanged and ux.lastTrashPruneZone ~= zone then
            ux.lastTrashPruneZone = zone
            if ux.pruneStaleTrashPoints then ux.pruneStaleTrashPoints(zone, { quiet = true }) end
        end
        ux.watchBaselineZone = zone
        ux.watchBaselineZoneIdentity = zoneIdentity
        ux.watchBaselineReady = false
        ux.watchFullBaselinePending = true
        ux.targetedWatchRefreshReady = false
        ux.zoneEntryRefreshPending = true
        ux._settlingStartMs = nil
        lastWatchRefreshMs = 0
        lastSearchRefreshMs = 0
        lastRefreshMs = 0
        -- Clear stale search data so the Search tab rescans immediately on next open
        -- rather than displaying mobs from the previous zone.
        ux.fullSpawnById = nil
        ux.fullSpawnRevision = 0
        ux.fullSpawnZoneIdentity = ''
        spawns = {}
        allSpawns = {}
        allSpawnsById = {}
        ux.spawnIndex = { byId = {}, byName = {}, byPoint = {}, presenceByName = {}, presenceByPoint = {} }
        ux.spawnIndexZoneIdentity = zoneIdentity
        ux.spawnDataRevision = (tonumber(ux.spawnDataRevision) or 0) + 1
        ux.watchPresenceRowCache = { rev = ux.spawnDataRevision, byKey = {} }
        ux.watchOccupantRowCache = { rev = ux.spawnDataRevision, byKey = {} }
        ux.quickSearchRows = nil
        ux.quickSearchRev = nil
        ux._qsLastTriggerMs = 0
        if ux.autoSeedCurrentZone then ux.autoSeedCurrentZone() end
        if ux.rebuildImportedRespawnLookup then ux.rebuildImportedRespawnLookup(zone) end
    else
        ux.watchBaselineZoneIdentity = zoneIdentity
    end
    if ux.lastLearnAllZone ~= zone then
        ux.lastLearnAllZone = zone
        ux.learnAllSeen[zone] = {}
        ux.learnAllCandidates[zone] = {}
        ux.lastLearnAllUpdateMS = 0
        ux.lastZoneIntelLearnAllRefreshMS = 0
    end
    if ux.safeZoneScanPaused() then
        spawns = {}
        allSpawns = {}
        allSpawnsById = {}
        ux.spawnIndex = { byId = {}, byName = {}, byPoint = {}, presenceByName = {}, presenceByPoint = {} }
        ux.rebuildWatchIndex()
        if ux.baselineResolveZoneWatches then ux.baselineResolveZoneWatches(zone) end
        ux.watchBaselineReady = true
        ux.zoneEntryRefreshPending = false
        ux._zoneBaselineStartMs = 0
        statusText = 'Safe-zone auto-pause: heavy spawn scanning is paused here. Use Scan Here to override.'
        lastRefreshMs = nowMs()
        updateTargetCompatVars()
        done()
        return
    end

    local timing = debugMode
    local tStart = nowMs()
    local watchLightHydration = watchOnly and not searchOnly and not legacyFull
    local searchLightHydration = searchOnly and not watchOnly and not legacyFull and not debugMode
    local richHydration = (buildSearchRows and not searchLightHydration) or debugMode or opts.learnAll == true
    local raceNeedle = trim(ux.raceFilter):lower()
    local classNeedle = trim(ux.classFilter):lower()
    local searchNeedRace = searchLightHydration and (raceNeedle ~= '' or ux.qsColShowRace == true)
    local searchNeedClass = searchLightHydration and (classNeedle ~= '' or ux.showClassColumn == true or ux.qsColShowClass == true)
    local spawnObjects, totalCount, source
    local fullWatchBaseline = false
    local function currentFullSpawnSnapshotReady()
        local currentIdentity = tostring(zoneIdentity or '')
        local fullIdentity = tostring(ux.fullSpawnZoneIdentity or '')
        return currentIdentity ~= ''
            and fullIdentity == currentIdentity
            and type(ux.fullSpawnById) == 'table'
            and next(ux.fullSpawnById) ~= nil
    end
    if watchOnly and not searchOnly and not legacyFull then
        if ux.watchFullBaselinePending == true
            or (ux.watchBaselineReady ~= true and not currentFullSpawnSnapshotReady()) then
            -- Resolve every watch from one bulk getAllSpawns() snapshot for the
            -- first zone baseline or explicit/manual watch refresh. Routine
            -- watch ticks below stay targeted so the popup does not rebuild and
            -- sort the whole zone every few seconds.
            fullWatchBaseline = true
            spawnObjects, totalCount, source = getAllSpawnObjects()
            source = 'watch-baseline:' .. tostring(source or 'scan')
            ux.targetedWatchRefreshReady = true
        else
            spawnObjects, totalCount, source = ux.getTargetedWatchSpawnObjects({
                fullBaseline = false,
            })
            if type(spawnObjects) ~= 'table' then
                spawnObjects = {}
                totalCount = 0
                source = 'targeted-watch'
            elseif source == 'targeted-watch' then
                -- Targeted helpers run several name/id queries; their returned
                -- count is summed query hits, not unique spawn objects. Use the
                -- unique row count for progress text so it does not look like an
                -- endless scan whose denominator changes every refresh.
                totalCount = #spawnObjects
            end
        end
    elseif searchOnly and not watchOnly then
        spawnObjects, totalCount, source = getAllSpawnObjects()
    else
        spawnObjects, totalCount, source = getAllSpawnObjects()
    end
    ux.refreshInProgressSource = tostring(source or '')
    local tLoaded = nowMs()
    -- Watch index is rebuilt after the spawn index is populated (below); the
    -- scan loop does not read it, so an extra rebuild here would be wasted work.
    local fresh = {}
    local rawRows = {}
    local rawById = {}
    local rawByName = {}
    local rawByPoint = {}
    local presenceByName = {}
    local presenceByPoint = {}
    local scanned = 0
    ux.watchScanProgress = {
        active = true,
        phase = 'scan',
        scanned = 0,
        total = tonumber(totalCount) or 0,
        resolved = 0,
        watches = #(select(2, ux.currentZoneWatchPairs()) or {}),
        source = tostring(source or 'scan'),
        startedAt = nowMs(),
    }
    local watchScanHints = ux.lastWatchScanHints
    if not watchScanHints and not richHydration and not watchLightHydration and not searchLightHydration and ux.buildWatchScanHints then
        watchScanHints = ux.buildWatchScanHints()
    end
    ux.lastWatchScanHints = nil
    local targetedWatchRows = source == 'targeted-watch'
    local hydratedWatchRows = 0
    debugTypeCounts = {}
    debugBodyCounts = {}
    debugRawRows = {}

    ux.activeFilterNeedles.search = trim(searchText):lower()
    ux.activeFilterNeedles.body = trim(ux.bodyFilter):lower()
    ux.activeFilterNeedles.race = raceNeedle
    ux.activeFilterNeedles.class = classNeedle
    ux.activeFilterNeedles.type = trim(ux.typeFilter):lower()
    ux.activeSearchPHLookup = (buildSearchRows and ux.namedOrPHOnly and ux.currentZonePHLookup) and ux.currentZonePHLookup() or nil

    -- Cache the player's own spawn ID; updated each scan so zone changes pick it up.
    -- getAllSpawns() includes self regardless of type, so we exclude by ID unconditionally.
    ux._selfId = tonumber(safeCall(function() return mq.TLO.Me.ID() end, 0)) or 0

    for _, spawn in pairs(spawnObjects) do
        scanned = scanned + 1
        if ux.watchScanProgress then ux.watchScanProgress.scanned = scanned end
        if scanned % 25 == 0 then
            ux.pumpCommandEvents()
            if ux.recentWatchTargetActive and ux.recentWatchTargetActive(4000) then
                ux.processRecentWatchTargetDeaths(true)
                ux.processWatchedTargetKill(true)
            end
        end
        -- Batched field read: ONE closure + ONE pcall per spawn instead of the
        -- previous ~18 safeCall closures (the GC win). Field-by-field fallbacks
        -- in the mapping below mirror the old per-field safeCall defaults.
        local ok, d = pcall(function()
            local r = {
                id = spawn.ID(),
                cleanName = spawn.CleanName(),
                realName = spawn.Name(),
                dead = spawn.Dead(),
                x = spawn.X(), y = spawn.Y(), z = spawn.Z(),
            }
            if richHydration or watchLightHydration or searchLightHydration then
                r.level = spawn.Level()
                r.distance = spawn.Distance()
                r.type = spawn.Type()
                r.body = spawn.Body()
                if richHydration then
                    r.ownerId = spawn.OwnerID()
                    r.race = spawn.Race()
                    r.class = spawn.Class()
                    r.targetable = spawn.Targetable()
                    r.direction = spawn.Direction()
                elseif searchLightHydration then
                    r.targetable = spawn.Targetable()
                    if searchNeedRace then r.race = spawn.Race() end
                    if searchNeedClass then r.class = spawn.Class() end
                elseif watchLightHydration then
                    r.targetable = spawn.Targetable()
                end
                -- Named() is NOT a member on all MQ/server builds (the original
                -- looksNamed wrapped it separately for exactly this reason). If it
                -- errors inside this batch it aborts ALL rich reads and forces
                -- every spawn down the slow per-field fallback. Isolate it: one
                -- cheap protected read, and on failure leave it unknown so the
                -- capitalized-name heuristic decides (parity with looksNamed).
                local okNamed, nm = pcall(function() return spawn.Named() end)
                if okNamed then
                    r.named = nm
                    r.namedKnown = (nm ~= nil)
                end
            end
            return r
        end)
        if not ok or type(d) ~= 'table' then
            -- Batch threw (a single TLO field errored on this spawn). Fall back
            -- to per-field protected reads so ONE bad field can't blank the whole
            -- row (which would zero level/distance/type and get it filtered out).
            -- Only paid on the rare failure path; the happy path stays one pcall.
            d = {
                id = safeCall(function() return spawn.ID() end, nil),
                cleanName = safeCall(function() return spawn.CleanName() end, nil),
                realName = safeCall(function() return spawn.Name() end, nil),
                dead = safeCall(function() return spawn.Dead() end, nil),
                x = safeCall(function() return spawn.X() end, nil),
                y = safeCall(function() return spawn.Y() end, nil),
                z = safeCall(function() return spawn.Z() end, nil),
            }
            if richHydration or watchLightHydration or searchLightHydration then
                d.level = safeCall(function() return spawn.Level() end, nil)
                d.distance = safeCall(function() return spawn.Distance() end, nil)
                d.type = safeCall(function() return spawn.Type() end, nil)
                d.body = safeCall(function() return spawn.Body() end, nil)
                if richHydration then
                    d.ownerId = safeCall(function() return spawn.OwnerID() end, nil)
                    d.race = safeCall(function() return spawn.Race() end, nil)
                    d.class = safeCall(function() return spawn.Class() end, nil)
                    d.targetable = safeCall(function() return spawn.Targetable() end, nil)
                    d.direction = safeCall(function() return spawn.Direction() end, nil)
                elseif searchLightHydration then
                    d.targetable = safeCall(function() return spawn.Targetable() end, nil)
                    if searchNeedRace then d.race = safeCall(function() return spawn.Race() end, nil) end
                    if searchNeedClass then d.class = safeCall(function() return spawn.Class() end, nil) end
                elseif watchLightHydration then
                    d.targetable = safeCall(function() return spawn.Targetable() end, nil)
                end
                local nm = safeCall(function() return spawn.Named() end, nil)
                d.named = nm
                d.namedKnown = (nm ~= nil)
            end
        end

        local id = tonumber(d.id) or 0
        -- name: CleanName, else Name, else 'Unknown' (matches old fallback chain,
        -- including leaving '' when Name() itself returns an empty string).
        local name = tostring(d.cleanName or '')
        if name == '' then name = tostring(d.realName or 'Unknown') end
        -- resolvedName mirrors what looksNamed() saw (the real CleanName/Name,
        -- never the 'Unknown' placeholder) so the heuristic stays identical.
        local resolvedName = ''
        if d.cleanName ~= nil and tostring(d.cleanName) ~= '' then
            resolvedName = tostring(d.cleanName)
        elseif d.realName ~= nil and tostring(d.realName) ~= '' then
            resolvedName = tostring(d.realName)
        end
        local trueName = name
        local level = 0
        local distance = 0
        local typeName = ''
        local bodyName = ''
        local ownerId = 0
        local dead = false
        if d.dead ~= nil then dead = d.dead end
        local raceName = 'Unknown'
        local className = 'Unknown'
        local targetable = true
        local named = false
        if richHydration or watchLightHydration or searchLightHydration then
            trueName = tostring(d.realName or name)
            level = tonumber(d.level) or 0
            distance = tonumber(d.distance) or 0
            typeName = tostring(d.type or 'Unknown')
            bodyName = tostring(d.body or 'Unknown')
            if richHydration then
                ownerId = tonumber(d.ownerId) or 0
                raceName = tostring(d.race or 'Unknown')
                className = tostring(d.class or 'Unknown')
            elseif searchLightHydration then
                if searchNeedRace and d.race ~= nil then raceName = tostring(d.race or 'Unknown') end
                if searchNeedClass and d.class ~= nil then className = tostring(d.class or 'Unknown') end
            end
            if d.targetable ~= nil then targetable = d.targetable end
            -- looksNamed() parity: trust the Named() flag when present, else fall
            -- back to the capitalized-name heuristic on the resolved real name.
            if d.namedKnown then
                named = d.named and true or false
            elseif resolvedName ~= ''
                and resolvedName:match('^[A-Z]')
                and not resolvedName:lower():match('^a ')
                and not resolvedName:lower():match('^an ') then
                named = true
            end
        end
        local x = tonumber(d.x) or 0
        local y = tonumber(d.y) or 0
        local z = tonumber(d.z) or 0
        local directionText = richHydration and tostring(d.direction or '') or ''
        local row = {
            id = id, name = name, trueName = trueName, level = level, distance = distance,
            type = typeName, body = bodyName, race = raceName, class = className,
            ownerId = ownerId, targetable = targetable, dead = dead, named = named,
            x = x, y = y, z = z, direction = directionText, directionDegrees = ux.directionDegreesFromLabel(directionText),
        }
        local watchCandidate = targetedWatchRows or (watchLightHydration and ux.rowMatchesWatchScanHints and ux.rowMatchesWatchScanHints(row, watchScanHints))
        if watchCandidate then
            hydratedWatchRows = hydratedWatchRows + 1
            if not watchLightHydration and not searchLightHydration then
                ux.hydrateWatchCandidateRow(row, spawn)
            end
            row._watchHydrated = true
            trueName, level, distance = row.trueName, row.level, row.distance
            typeName, bodyName = row.type, row.body
        end
        ux.finalizeSpawnRow(row)

        if buildSearchRows or debugMode then
            addDebugCount(debugTypeCounts, typeName)
            addDebugCount(debugBodyCounts, bodyName)
            if #debugRawRows < 15 then table.insert(debugRawRows, row) end
        end
        table.insert(rawRows, row)
        if id ~= 0 then rawById[id] = row end
        local lowerName = row.name_l or name:lower()
        if lowerName ~= '' then rawByName[lowerName] = rawByName[lowerName] or row end
        local pointKey = spawnPointKey(row)
        if pointKey and pointKey ~= '' then rawByPoint[pointKey] = rawByPoint[pointKey] or row end
        local indexPresenceRow = richHydration or watchLightHydration or searchLightHydration
            or watchCandidate or fullWatchBaseline
        if indexPresenceRow and passWatchPresenceFilters(row) then
            if lowerName ~= '' then
                presenceByName[lowerName] = presenceByName[lowerName] or row
                -- Also index by base name (suffix stripped) so watches find mobs with
                -- server-appended name variants (e.g. Lazarus HC "(hunter)" suffix)
                local baseLowerName = lowerName:gsub('%s*%([^)]+%)%s*$', '')
                if baseLowerName ~= '' and baseLowerName ~= lowerName then
                    presenceByName[baseLowerName] = presenceByName[baseLowerName] or row
                end
            end
            if pointKey and pointKey ~= '' then presenceByPoint[pointKey] = presenceByPoint[pointKey] or row end
        end

        if buildSearchRows and passLocalFilters(row) then table.insert(fresh, row) end
    end
    ux.activeSearchPHLookup = nil
    local tRowsBuilt = nowMs()

    local searchOnlyIsolated = searchOnly and not watchOnly and not legacyFull
    local preserveSearchDisplay = watchOnly and not searchOnly and not legacyFull
        and showWindow
        and tostring(ux.activeFullTab or ''):lower() == 'search'
    local savedSpawns
    if preserveSearchDisplay then
        savedSpawns = spawns
    end

    if not refreshStillCurrent() then
        if ux.recordPerfLine then
            ux.recordPerfLine(string.format('Refresh discarded (zone changed during scan) epoch=%d zone=%s source=%s',
                refreshEpoch, tostring(refreshZoneIdentity or '-'), tostring(source or '-')))
        end
        done()
        return
    end

    if searchOnlyIsolated then
        -- Also update fullSpawnById so Quick Search browse mode has a full zone
        -- snapshot from this scan (the else branch was the only place it was set,
        -- so searchOnly scans never populated it — fixed here).
        allSpawns = rawRows
        allSpawnsById = rawById
        ux.spawnIndex = {
            byId = rawById,
            byName = rawByName,
            byPoint = rawByPoint,
            presenceByName = presenceByName,
            presenceByPoint = presenceByPoint,
        }
        ux.spawnDataRevision = (tonumber(ux.spawnDataRevision) or 0) + 1
        ux.spawnIndexZoneIdentity = zoneIdentity
        ux.watchPresenceRowCache = { rev = ux.spawnDataRevision, byKey = {} }
        ux.watchOccupantRowCache = { rev = ux.spawnDataRevision, byKey = {} }
        ux.fullSpawnById = rawById
        ux.fullSpawnRevision = (tonumber(ux.fullSpawnRevision) or 0) + 1
        ux.fullSpawnZoneIdentity = zoneIdentity
        spawns = fresh
        sortSpawns()
    else
        allSpawns = rawRows
        allSpawnsById = rawById
        ux.spawnIndex = {
            byId = rawById,
            byName = rawByName,
            byPoint = rawByPoint,
            presenceByName = presenceByName,
            presenceByPoint = presenceByPoint,
        }
        ux.spawnDataRevision = (tonumber(ux.spawnDataRevision) or 0) + 1
        ux.spawnIndexZoneIdentity = zoneIdentity
        ux.watchPresenceRowCache = { rev = ux.spawnDataRevision, byKey = {} }
        ux.watchOccupantRowCache = { rev = ux.spawnDataRevision, byKey = {} }
        -- fullSpawnById only updates from full/searchOnly scans, plus the one
        -- watch-baseline all-spawn scan. Routine watchOnly scans are sparse
        -- and would corrupt Search with an incomplete zone population.
        if buildSearchRows or fullWatchBaseline then
            ux.fullSpawnById = rawById
            ux.fullSpawnRevision = (tonumber(ux.fullSpawnRevision) or 0) + 1
            ux.fullSpawnZoneIdentity = zoneIdentity
        end
        if buildSearchRows then
            spawns = fresh
            sortSpawns()
        end
        if preserveSearchDisplay and type(savedSpawns) == 'table' then
            spawns = savedSpawns
        end
    end
    if ux.annotateDerivedSpawnRows then ux.annotateDerivedSpawnRows(allSpawns) end
    local tSorted = nowMs()
    local matchedCount = buildSearchRows and #spawns or 0
    if (not searchOnly) and opts.learnAll == true and not ux.isSafeHubZone() then ux.updateLearnAllSpawns(allSpawns) end
    local tLearned = nowMs()
    local suppressWatchAlerts = opts.suppressAlerts or searchOnly or not ux.watchBaselineReady
    ux.currentRefreshSource = tostring(source or '')
    if not searchOnly or searchOnlyIsolated then updateWatches(allSpawns, suppressWatchAlerts, watchScanHints) end
    if fullWatchBaseline and refreshStillCurrent() then
        if #allSpawns > 0 or scanned > 0 then
            ux.watchFullBaselinePending = false
            ux.watchFullBaselineZoneIdentity = zoneIdentity
        elseif ux.recordPerfLine then
            ux.recordPerfLine(string.format('Watch baseline empty raw=%d scanned=%d zone=%s; retry pending',
                #allSpawns, scanned, tostring(zone or '-')))
        end
    end
    ux.currentRefreshSource = ''
    local tWatchUpdate = nowMs()
    do
        local _, progressWatches = ux.currentZoneWatchPairs()
        local resolvedWatches = 0
        for _, w in ipairs(progressWatches or {}) do
            if type(w) == 'table' and w.initialResolved == true then resolvedWatches = resolvedWatches + 1 end
        end
        ux.watchScanProgress = {
            active = false,
            phase = 'done',
            scanned = scanned,
            total = tonumber(totalCount) or scanned,
            resolved = resolvedWatches,
            watches = #(progressWatches or {}),
            source = tostring(source or 'scan'),
            finishedAt = nowMs(),
        }
    end
    if not searchOnly or searchOnlyIsolated then ux.refreshWatchedMapHighlights(false) end
    local tMap = nowMs()
    if refreshStillCurrent() and ((not searchOnly) or (searchOnlyIsolated and ux.zoneEntryRefreshPending == true)) then
        local resolved = ux.currentZoneWatchesResolved and ux.currentZoneWatchesResolved() or true
        local snapshotOk = ux.spawnSnapshotMatchesCurrentZone and ux.spawnSnapshotMatchesCurrentZone() or false
        local safePaused = ux.safeZoneScanPaused and ux.safeZoneScanPaused() or false
        local fullBaselineDone = ux.watchFullBaselinePending ~= true
            or fullWatchBaseline
            or safePaused
        local scanEvidence = snapshotOk and fullBaselineDone and (
            #allSpawns > 0 or fullWatchBaseline or searchOnlyIsolated or safePaused
            or (targetedWatchRows and currentFullSpawnSnapshotReady()))
        local settleAge = 0
        if ux.zoneEntryRefreshPending == true then
            ux._settlingStartMs = ux._settlingStartMs or tonumber(ux.watchZoneEnteredAt) or nowMs()
            settleAge = nowMs() - (tonumber(ux._settlingStartMs) or nowMs())
        else
            ux._settlingStartMs = nil
        end
        -- Safe hubs: resolve without scan after 30s. Gameplay zones: accept live spawn evidence after 15s.
        if not resolved and ux.zoneEntryRefreshPending then
            if settleAge > 30000 and safePaused then
                resolved = true
            elseif settleAge > 15000 and #allSpawns > 0 and snapshotOk then
                resolved = true
            end
        end
        if not scanEvidence and #allSpawns > 0 and snapshotOk and settleAge > 15000 then
            scanEvidence = true
            if fullWatchBaseline or #allSpawns >= 8 then
                ux.watchFullBaselinePending = false
            end
        end
        if resolved and not scanEvidence and not safePaused then
            resolved = false
        end
        if ux.watchUpdatePending == true and not resolved then
            resolved = false
        end
        ux.watchBaselineReady = resolved and scanEvidence
        ux.zoneEntryRefreshPending = not (resolved and scanEvidence)
        if searchOnlyIsolated and snapshotOk and #allSpawns > 0 then
            ux.watchFullBaselinePending = false
            ux.targetedWatchRefreshReady = true
        end
        if searchOnlyIsolated and resolved and scanEvidence then
            ux.watchFullBaselinePending = false
            ux.targetedWatchRefreshReady = true
        end
    end
    ux.rebuildWatchIndex(false)
    if buildSearchRows and showWindow and tostring(ux.activeFullTab or ''):lower() == 'search' then
        ux.cacheSearchWatchedRows()
    end
    local tSearchWatchCache = nowMs()
    if not ux.showAlertPopup and ux.alertPopupClosedAt > 0 and ux.alertPopupRemindSeconds > 0 then
        local hasActiveWatch = false
        local _, currentWatches = ux.currentZoneWatchPairs()
        for _, watch in ipairs(currentWatches or {}) do
            if watch.isUp or tonumber(watch.expectedRespawnAt or 0) > 0 then
                hasActiveWatch = true
                break
            end
        end
        if hasActiveWatch and (os.time() - ux.alertPopupClosedAt) >= ux.alertPopupRemindSeconds then
            wakeAlertPopup()
        end
    end
    local finishedAt = nowMs()
    if runWatchUpdate and refreshStillCurrent() then
        lastWatchRefreshMs = finishedAt
        lastRefreshMs = finishedAt
    end
    if buildSearchRows then
        lastSearchRefreshMs = finishedAt
    end
    if buildSearchRows then
        statusText = string.format('Showing %d / matched %d / raw %d / scanned %d / total %d via %s', #spawns, matchedCount, #allSpawns, scanned, totalCount or scanned, source or 'scan')
    else
        statusText = string.format('Watch refresh: raw %d / scanned %d / total %d via %s', #allSpawns, scanned, totalCount or scanned, source or 'scan')
    end
    ux.lastRefreshSource = tostring(source or 'scan')

    if selectedId and buildSearchRows then
        local stillExists = false
        local row = allSpawnsById[selectedId]
        if row then stillExists = true; selectedName = row.name end
        if not stillExists then
            selectedId = nil
            selectedName = 'None'
        end
    end

    updateTargetCompatVars()
    local tCompat = nowMs()

    if not force then ux.queueRespawnSaveWhenSafe() end
    local tDone = nowMs()
    local _, timingWatches = ux.currentZoneWatchPairs()
    local zoneWatchCount = #timingWatches
    ux.lastRefreshTimingText = string.format(
        'Timing ms: tab=%s load=%d rows=%d sort=%d learn=%d watch=%d map=%d mark=%d compat=%d save=%d total=%d raw=%d matched=%d watches=%d learned=%d hydrated=%d source=%s zoneid=%s',
        tostring(refreshKind),
        tLoaded - tStart, tRowsBuilt - tLoaded, tSorted - tRowsBuilt, tLearned - tSorted,
        tWatchUpdate - tLearned, tMap - tWatchUpdate, tSearchWatchCache - tMap,
        tCompat - tSearchWatchCache, tDone - tCompat, tDone - tStart, #allSpawns, matchedCount,
        zoneWatchCount,
        ux.zoneIntelLastTotalRows or 0,
        hydratedWatchRows,
        tostring(source or 'scan'),
        tostring(zoneIdentity or '-'))
    ux.lastRefreshDiag = {
        kind = refreshKind,
        totalMs = tDone - tStart,
        raw = #allSpawns,
        matched = matchedCount,
        watches = zoneWatchCount,
        source = tostring(source or 'scan'),
        zoneIdentity = tostring(zoneIdentity or '-'),
        at = tDone,
    }
    if timing then
        ux.recordPerfLine(ux.lastRefreshTimingText)
    elseif (tDone - tStart) >= 80 then
        ux.recordPerfLine(string.format(
            'Refresh tab=%s total=%dms load=%d rows=%d sort=%d learn=%d watch=%d map=%d mark=%d compat=%d save=%d raw=%d matched=%d watches=%d learned=%d hydrated=%d source=%s zoneid=%s',
            tostring(refreshKind),
            tDone - tStart, tLoaded - tStart, tRowsBuilt - tLoaded, tSorted - tRowsBuilt,
            tLearned - tSorted, tWatchUpdate - tLearned, tMap - tWatchUpdate,
            tSearchWatchCache - tMap, tCompat - tSearchWatchCache, tDone - tCompat,
            #allSpawns, matchedCount, zoneWatchCount, ux.zoneIntelLastTotalRows or 0,
            hydratedWatchRows,
            tostring(source or 'scan'),
            tostring(zoneIdentity or '-')))
    end
    done()
end

ux.refreshWatchesNow = function(opts)
    opts = opts or {}
    opts.watchOnly = true
    refreshSpawns(true, opts)
end

ux.refreshSearchNow = function(opts)
    opts = opts or {}
    opts.searchOnly = true
    refreshSpawns(true, opts)
end

ux.refreshAllNow = function(opts)
    opts = opts or {}
    opts.watchOnly = nil
    opts.searchOnly = nil
    refreshSpawns(true, opts)
end

ux.rebuildQuickSearchRowsFromSnapshot = function()
    local byId = ux.fullSpawnById
    if type(byId) ~= 'table' or next(byId) == nil then return false end
    local needle = trim(searchText or ''):lower()
    local typeN  = trim(ux.typeFilter  or ''):lower()
    local bodyN  = trim(ux.bodyFilter  or ''):lower()
    local raceN  = trim(ux.raceFilter  or ''):lower()
    local classN = trim(ux.classFilter or ''):lower()
    ux.activeFilterNeedles.type  = typeN
    ux.activeFilterNeedles.body  = bodyN
    ux.activeFilterNeedles.race  = raceN
    ux.activeFilterNeedles.class = classN
    ux.activeFilterNeedles.search = needle

    local namedF = ux.qsNamedOnly == true
    local phF = ux.qsNamedPHOnly == true
    local results = {}
    for id, row in pairs(byId) do
        if not row then goto continue_qs_snapshot end
        local rowName = row.name_l or tostring(row.name or ''):lower()
        local rowTrue = row.trueName_l or tostring(row.trueName or ''):lower()
        if needle ~= '' and not (rowName:find(needle, 1, true) or rowTrue:find(needle, 1, true)) then
            goto continue_qs_snapshot
        end
        if namedF and not row.named then goto continue_qs_snapshot end
        if phF and not ux.rowIsNamedOrPH(row) then goto continue_qs_snapshot end
        if not ux.passQSFilters(row, typeN, bodyN, raceN, classN) then goto continue_qs_snapshot end
        results[#results + 1] = {
            id = id,
            name = row.name,
            trueName = row.trueName or '',
            level = row.level or 0,
            dist = tonumber(row.distance) or 9999,
            x = row.x or 0,
            y = row.y or 0,
            row = row,
        }
        ::continue_qs_snapshot::
    end
    if ux.qsSortRows then
        ux.qsSortRows(results)
    else
        table.sort(results, function(a, b) return a.dist < b.dist end)
    end
    ux.quickSearchRows = results
    ux.quickSearchNeedle = needle
    ux.quickSearchRev = tostring(tonumber(ux.fullSpawnRevision) or 0)
        .. ':snap:' .. needle
        .. (namedF and ':N' or '') .. (phF and ':PH' or '')
        .. ':t' .. typeN .. ':b' .. bodyN .. ':r' .. raceN .. ':c' .. classN
        .. ':l' .. tostring(minLevel) .. '-' .. tostring(maxLevel)
        .. (ux.targetableOnly and ':UT' or '')
        .. (includeCorpses and ':C' or '') .. (includePlayers and ':P' or '')
        .. (includePets and ':Pt' or '') .. (includeGroundItems and ':G' or '')
    ux.quickSearchLastMs = 0
    return true
end

ux.anyCurrentZoneWatchDue = function()
    local _, currentWatches = ux.currentZoneWatchPairs()
    for _, watch in ipairs(currentWatches or {}) do
        if ux.watchIsEffectivelyDue and ux.watchIsEffectivelyDue(watch) then
            return true
        end
    end
    return false
end

ux.deferWatchRefreshForUi = function(overdue, dueWatchActive)
    if overdue or dueWatchActive then return false end
    -- Zone-in baseline must not wait on movement/UI defer — otherwise "Updating
    -- zone watches..." can stick for minutes while running around.
    if ux.zoneEntryRefreshPending == true or ux.watchBaselineReady ~= true then
        return false
    end
    if ux.deferWatchUiRefresh ~= true then return false end
    if not (ux.showAlertPopup or (showWindow and tostring(ux.activeFullTab or ''):lower() == 'watches')) then
        return false
    end
    return ux.gameplayBusyForRespawnSave and ux.gameplayBusyForRespawnSave() or false
end

-- Live Search is opt-in; turn it off after leaving the Search tab so background
-- search-only spawn rebuilds do not keep running while camping with Turbo Watch.
ux.maybeAutoOffLiveSearch = function()
    if ux.liveSearch ~= true then
        ux.searchTabLeftAt = 0
        return
    end
    local activeTab = tostring(ux.activeFullTab or ''):lower()
    local prevTab = tostring(ux.lastTrackedFullTab or ''):lower()
    if activeTab == 'search' then
        ux.searchTabLeftAt = 0
    elseif activeTab ~= '' then
        if (tonumber(ux.searchTabLeftAt) or 0) <= 0
            and (prevTab == 'search' or prevTab == '') then
            ux.searchTabLeftAt = nowMs()
        end
    end
    ux.lastTrackedFullTab = activeTab
    if activeTab ~= 'search' and activeTab ~= '' then
        local leaveAt = tonumber(ux.searchTabLeftAt) or 0
        local autoOffMs = math.max(1000, tonumber(ux.liveSearchAutoOffAfterTabLeaveMs) or 60000)
        if leaveAt > 0 and (nowMs() - leaveAt) >= autoOffMs then
            ux.liveSearch = false
            ux.searchTabLeftAt = 0
            saveSettings()
        end
    end
end

local function refreshIfDue()
    if not enabled then return end
    ux.maybeAutoOffLiveSearch()
    ux.drainCommandQueue(false)

    -- Don't rebuild while typing in an ImGui text field (flag set during draw).
    if ux.uiWantsTextInput then return end

    local activeTab = tostring(ux.activeFullTab or ''):lower()
    local onSearchLive = showWindow and activeTab == 'search' and ux.liveSearch == true
    local learnAll = false
    if showWindow and activeTab == 'zoneintel' and ux.learnAllSpawns == true then
        local learnInterval = math.max(60000, tonumber(ux.zoneIntelLearnAllRefreshMs) or 300000)
        local lastLearnScan = tonumber(ux.lastZoneIntelLearnAllRefreshMS) or 0
        if lastLearnScan <= 0 then
            ux.lastZoneIntelLearnAllRefreshMS = nowMs()
        elseif (nowMs() - lastLearnScan) >= learnInterval then
            learnAll = true
        end
    end

    local zoneSettling = ux.zoneEntryRefreshPending == true or ux.watchBaselineReady ~= true
        or ux.pendingAllaImport ~= nil

    local function fullSnapshotReadyForCurrentZone()
        local currentIdentity = tostring(ux.currentZoneRuntimeIdentity and ux.currentZoneRuntimeIdentity() or currentZoneShort())
        local fullIdentity = tostring(ux.fullSpawnZoneIdentity or '')
        return currentIdentity ~= ''
            and fullIdentity == currentIdentity
            and type(ux.fullSpawnById) == 'table'
            and next(ux.fullSpawnById) ~= nil
    end

    -- Zone-in: automatically run the same full snapshot scan that the Search
    -- Refresh button runs. This primes Search and Watch from one source of truth.
    if enabled and not (ux.safeZoneScanPaused and ux.safeZoneScanPaused())
        and (ux.forceSearchScanOnZoneIn == true
            or ux.zoneEntryRefreshPending == true
            or ux.watchBaselineReady ~= true)
        and not fullSnapshotReadyForCurrentZone() then
        local enteredAt = tonumber(ux.watchZoneEnteredAt or 0) or 0
        local age = enteredAt > 0 and (nowMs() - enteredAt) or math.huge
        local delayMs = math.max(0, tonumber(ux.zoneEntryPrimeDelayMs) or 500)
        if age >= delayMs then
            local busy = (tonumber(ux.spawnRefreshInProgress) or 0) > 0
            local started = tonumber(ux.spawnRefreshStartedMS) or 0
            local busyAge = started > 0 and (nowMs() - started) or 0
            if busy and busyAge > (tonumber(ux.zoneEntryPrimeStaleMs) or 12000) and ux.clearRefreshInProgress then
                ux.clearRefreshInProgress(string.format('stale before zone prime ageMs=%d', busyAge))
                busy = false
            end
            if not busy then
                local lastPrime = tonumber(ux.lastZoneEntryPrimeMS or 0) or 0
                local retryMs = math.max(500, tonumber(ux.zoneEntryPrimeRetryMs) or 2500)
                if lastPrime <= 0 or (nowMs() - lastPrime) >= retryMs then
                    ux.lastZoneEntryPrimeMS = nowMs()
                    local primeSearch = showWindow == true and activeTab == 'search'
                    if primeSearch then
                        ux.refreshSearchNow({ suppressAlerts = true })
                    else
                        ux.refreshWatchesNow({ suppressAlerts = true })
                    end
                    if fullSnapshotReadyForCurrentZone() then
                        ux.forceSearchScanOnZoneIn = false
                    end
                    ux.lastRefreshDecisionText = string.format(
                        'RefreshDecision kind=zone-prime call=%dms mode=%s zoneSettling=%s tab=%s fullOpen=%s watchOpen=%s',
                        nowMs() - ux.lastZoneEntryPrimeMS, primeSearch and 'search' or 'watch', tostring(zoneSettling == true),
                        tostring(activeTab ~= '' and activeTab or '-'), tostring(showWindow == true),
                        tostring(ux.showAlertPopup == true))
                    return
                end
            end
        end
    end

    -- Zone-in: prime Search before heavy watch refresh (does not wait on respawn load).
    if ux.forceSearchScanOnZoneIn == true and showWindow and activeTab == 'search' then
        local searchBusy = (tonumber(ux.spawnRefreshInProgress) or 0) > 0
        local qsLast = tonumber(ux._qsLastTriggerMs) or 0
        if not searchBusy and (qsLast <= 0 or (nowMs() - qsLast) >= 500) then
            ux._qsLastTriggerMs = nowMs()
            ux.refreshSearchNow({ suppressAlerts = true })
            if ux.fullSpawnById and next(ux.fullSpawnById) then
                ux.forceSearchScanOnZoneIn = false
            end
        end
    end

    -- Watch refresh: tracking, timers, alerts — independent of Search Live mode.
    local watchRefreshMs = refreshCompactMs or 5000
    if showWindow and activeTab == 'settings' then
        watchRefreshMs = math.max(watchRefreshMs, ux.settingsRefreshMs or 10000)
    elseif showWindow and activeTab == 'watches' then
        watchRefreshMs = math.max(watchRefreshMs, ux.watchesRefreshMs or 8000)
    elseif showWindow and activeTab == 'zoneintel' then
        watchRefreshMs = math.max(watchRefreshMs, ux.zoneIntelRefreshMs or 5000)
    elseif showWindow and activeTab == 'search' and not onSearchLive then
        watchRefreshMs = math.max(watchRefreshMs, ux.searchStableWatchRefreshMs or 4000)
    end
    if ux.showAlertPopup then
        watchRefreshMs = math.max(watchRefreshMs, tonumber(ux.watchPopupRefreshMs) or 10000)
    elseif showWindow and activeTab == 'watches' then
        watchRefreshMs = math.max(watchRefreshMs, tonumber(ux.watchUiRefreshMs) or 10000)
    end
    if zoneSettling and enabled then
        watchRefreshMs = math.min(watchRefreshMs, tonumber(ux.zoneEntryRefreshMs) or 2500)
    end
    local dueWatchActive = ux.anyCurrentZoneWatchDue and ux.anyCurrentZoneWatchDue() or false
    if dueWatchActive then
        watchRefreshMs = math.min(watchRefreshMs, tonumber(ux.dueWatchRefreshMs) or 1500)
    end

    local forceWatch = ux.zoneEntryRefreshPending == true or ux.watchFullBaselinePending == true
    local watchOverdue = (nowMs() - lastWatchRefreshMs) >= (watchRefreshMs * 2)
    local deferWatch = not forceWatch and ux.deferWatchRefreshForUi and ux.deferWatchRefreshForUi(watchOverdue, dueWatchActive)
    if not deferWatch and (forceWatch or (nowMs() - lastWatchRefreshMs >= watchRefreshMs)) then
        local elapsedSinceWatch = lastWatchRefreshMs > 0 and (nowMs() - lastWatchRefreshMs) or 0
        local tWatchStart = nowMs()
        local runLearnAll = learnAll and not zoneSettling and activeTab == 'zoneintel'
        refreshSpawns(forceWatch, {
            watchOnly = true,
            learnAll = runLearnAll,
            suppressAlerts = zoneSettling,
        })
        if runLearnAll then ux.lastZoneIntelLearnAllRefreshMS = nowMs() end
        local watchElapsed = nowMs() - tWatchStart
        ux.lastRefreshDecisionText = string.format(
            'RefreshDecision kind=watch elapsed=%dms dueAfter=%dms call=%dms force=%s learnAll=%s zoneSettling=%s dueWatch=%s tab=%s fullOpen=%s watchOpen=%s',
            elapsedSinceWatch, watchRefreshMs, watchElapsed, tostring(forceWatch == true),
            tostring(runLearnAll), tostring(zoneSettling == true), tostring(dueWatchActive == true), tostring(activeTab ~= '' and activeTab or '-'),
            tostring(showWindow == true), tostring(ux.showAlertPopup == true))
        ux.recordSlowPerf('refreshIfDue', ux.lastRefreshDecisionText, watchElapsed, 25, 1000)
    end

    -- Quick Search: primary spawn list for the Search tab.
    -- Two modes, both gated to Search tab open only — zero cost otherwise.
    --
    -- BROWSE (empty needle): reads scan-time distances straight from spawnIndex,
    -- rebuilds only when spawnDataRevision changes (i.e. a new scan ran). No TLO
    -- calls needed — cheap enough to treat as the default view.
    --
    -- FILTERED (name typed): 1s TLO poll per matching ID for live distance and
    -- kill detection. Dead mobs drop off within 1s. Full zone coverage, no cap.
    if showWindow and activeTab == 'search' then
        local needle = trim(searchText or ''):lower()
        -- Use fullSpawnById — only populated by full/searchOnly scans, never sparse
        -- watchOnly scans. If missing, trigger a search scan immediately.
        local byId = ux.fullSpawnById
        if not byId or next(byId) == nil then
            -- Trigger a scan to populate fullSpawnById. Use a timestamp so:
            --   • First open: fires immediately (lastTrigger = 0).
            --   • If scan returns empty (very early zone entry): retries every 2.5s
            --     instead of blocking forever like _qsTriggerPending did.
            --   • On success: byId is re-read right after the sync scan so the
            --     browse loop can build quickSearchRows THIS frame, not next frame.
            local lastTrigger = tonumber(ux._qsLastTriggerMs) or 0
            local retryMs = ux.forceSearchScanOnZoneIn == true and 500 or 2500
            if nowMs() - lastTrigger >= retryMs then
                ux._qsLastTriggerMs = nowMs()
                ux.refreshSearchNow({ suppressAlerts = true })
                byId = ux.fullSpawnById   -- pick up result immediately
                if byId and next(byId) then ux.forceSearchScanOnZoneIn = false end
            end
        else
            ux._qsLastTriggerMs = 0
        end
        -- Sync activeFilterNeedles from current UI state before any filtering.
        -- passLocalFilters reads these needles; keeping them current here ensures
        -- both browse and filtered modes reflect Filters-section changes immediately.
        local _typeN  = trim(ux.typeFilter  or ''):lower()
        local _bodyN  = trim(ux.bodyFilter  or ''):lower()
        local _raceN  = trim(ux.raceFilter  or ''):lower()
        local _classN = trim(ux.classFilter or ''):lower()
        ux.activeFilterNeedles.type  = _typeN
        ux.activeFilterNeedles.body  = _bodyN
        ux.activeFilterNeedles.race  = _raceN
        ux.activeFilterNeedles.class = _classN
        ux.activeFilterNeedles.search = needle
        if byId and type(ux.quickSearchRows) ~= 'table'
            and ux.rebuildQuickSearchRowsFromSnapshot then
            ux.rebuildQuickSearchRowsFromSnapshot()
        end
        if needle ~= '' then
            -- Filtered mode: TLO poll every 1s for live distance + kill detection
            local qsLast = tonumber(ux.quickSearchLastMs) or 0
            if qsLast <= 0 or (nowMs() - qsLast) >= 1000 then
                ux.quickSearchLastMs = nowMs()
                if byId then
                    local results = {}
                    local namedF = ux.qsNamedOnly == true
                    local phF = ux.qsNamedPHOnly == true
                    for id, row in pairs(byId) do
                        local rowName = row.name_l or tostring(row.name or ''):lower()
                        if rowName:find(needle, 1, true) then
                            if namedF and not row.named then goto continue end
                            if phF and not ux.rowIsNamedOrPH(row) then goto continue end
                            if not ux.passQSFilters(row, _typeN, _bodyN, _raceN, _classN) then goto continue end
                            local sp = safeCall(function() return mq.TLO.Spawn('id ' .. tostring(id)) end, nil)
                            local seenId = sp and (tonumber(safeCall(function() return sp.ID() end, 0)) or 0) or 0
                            if seenId > 0 then
                                local dist = tonumber(safeCall(function() return sp.Distance() end, 9999)) or 9999
                                results[#results + 1] = {
                                    id = id, name = row.name, trueName = row.trueName or '',
                                    level = row.level or 0, dist = dist,
                                    x = row.x or 0, y = row.y or 0, row = row,
                                }
                            end
                        end
                        ::continue::
                    end
                    table.sort(results, function(a, b) return a.dist < b.dist end)
                    ux.quickSearchRows = results
                    ux.quickSearchNeedle = needle
                    ux.quickSearchRev = ux.fullSpawnRevision
                end
            end
        else
            -- Browse mode: rebuild when scan revision OR any active filter changes.
            local currentRev = tonumber(ux.fullSpawnRevision) or 0
            local namedF = ux.qsNamedOnly == true
            local phF = ux.qsNamedPHOnly == true
            local filterKey = tostring(currentRev)
                .. (namedF and 'N' or '') .. (phF and 'P' or '')
                .. ':t' .. _typeN .. ':b' .. _bodyN .. ':r' .. _raceN .. ':c' .. _classN
                .. ':l' .. tostring(minLevel) .. '-' .. tostring(maxLevel)
                .. (ux.targetableOnly and ':UT' or '')
                .. (includeCorpses and ':C' or '') .. (includePlayers and ':P' or '')
                .. (includePets and ':Pt' or '') .. (includeGroundItems and ':G' or '')
            if (ux.quickSearchRev or '') ~= filterKey and byId then
                local results = {}
                for id, row in pairs(byId) do
                    if namedF and not row.named then goto continue end
                    if phF and not ux.rowIsNamedOrPH(row) then goto continue end
                    if not ux.passQSFilters(row, _typeN, _bodyN, _raceN, _classN) then goto continue end
                    results[#results + 1] = {
                        id = id, name = row.name, trueName = row.trueName or '',
                        level = row.level or 0, dist = tonumber(row.distance) or 9999,
                        x = row.x or 0, y = row.y or 0, row = row,
                    }
                    ::continue::
                end
                table.sort(results, function(a, b) return a.dist < b.dist end)
                ux.quickSearchRows = results
                ux.quickSearchNeedle = ''
                ux.quickSearchRev = filterKey
                ux.quickSearchLastMs = 0
            end
        end
    else
        -- Not on search tab: clear to free memory
        if ux.quickSearchRows ~= nil then
            ux.quickSearchRows = nil
            ux.quickSearchNeedle = ''
            ux.quickSearchLastMs = 0
            ux.quickSearchRev = nil
            ux._qsTriggerPending = false
        end
    end

    -- Search refresh: display rows only — never runs watch updates or learn-all.
    if onSearchLive and not zoneSettling then
        local searchRefreshMs = ux.searchRefreshMs or 12000
        local sinceWatchMs = nowMs() - lastWatchRefreshMs
        if sinceWatchMs >= 400 and (lastSearchRefreshMs <= 0 or (nowMs() - lastSearchRefreshMs) >= searchRefreshMs) then
            local elapsedSinceSearch = lastSearchRefreshMs > 0 and (nowMs() - lastSearchRefreshMs) or 0
            local tSearchStart = nowMs()
            refreshSpawns(false, { searchOnly = true, suppressAlerts = true })
            local searchElapsed = nowMs() - tSearchStart
            local autoLockMs = tonumber(ux.liveSearchAutoLockAfterMs) or 0
            if autoLockMs > 0 and searchElapsed >= autoLockMs and ux.liveSearch == true then
                ux.liveSearch = false
                statusText = string.format('Live Search locked after slow auto-refresh (%dms). Press Refresh when you need Search rows rebuilt.', searchElapsed)
                saveSettings()
                chat(string.format('\\ayTurboMobs:\\ax Live Search locked after slow auto-refresh (%dms). Watches still update in the background.', searchElapsed))
            end
            ux.lastRefreshDecisionText = string.format(
                'RefreshDecision kind=search elapsed=%dms dueAfter=%dms call=%dms tab=%s fullOpen=%s watchOpen=%s liveSearch=%s',
                elapsedSinceSearch, searchRefreshMs, searchElapsed, tostring(activeTab),
                tostring(showWindow == true), tostring(ux.showAlertPopup == true), tostring(ux.liveSearch == true))
            ux.recordSlowPerf('refreshIfDue', ux.lastRefreshDecisionText, searchElapsed, 25, 1000)
        end
    end
end

selectRow = function(row, targetNow)
    if not row then return end
    if targetNow then
        targetRow(row)
        selectedId = nil
        selectedName = 'None'
    else
        selectedId = row.id
        selectedName = row.name
        lastSelectedName = row.name
    end
end

local function faceSelected()
    if not selectedId then chat('No mob selected.'); return end
    faceRow(allSpawnsById[selectedId])
end

local function navSelected()
    if not selectedId then chat('No mob selected.'); return end
    navRow(allSpawnsById[selectedId])
end

local function nearestRow() return spawns[1] end

ux.clearSearchFilters = function()
    searchText = ''
    ux.bodyFilter = ''
    ux.raceFilter = ''
    ux.classFilter = ''
    ux.typeFilter = ''
    minLevel = 0
    maxLevel = 999
    maxDistance = 0
    namedOnly = false
    ux.namedOrPHOnly = false
    ux.searchPage = 1
    ux.refilterSearchRows()
    saveSettings()
end

ux.clearAllFilters = ux.clearSearchFilters

ux.activeSearchFilterText = function()
    local filters = {}
    local function add(label, value)
        value = trim(tostring(value or ''))
        if value ~= '' then table.insert(filters, label .. ' "' .. value .. '"') end
    end
    add('Name', searchText)
    add('Type', ux.typeFilter)
    add('Body', ux.bodyFilter)
    add('Race', ux.raceFilter)
    add('Class', ux.classFilter)
    if namedOnly then table.insert(filters, 'Named') end
    if ux.namedOrPHOnly then table.insert(filters, 'Named+PH') end
    if tonumber(minLevel) and tonumber(minLevel) > 0 then table.insert(filters, 'Min ' .. tostring(minLevel)) end
    if tonumber(maxLevel) and tonumber(maxLevel) < 999 then table.insert(filters, 'Max ' .. tostring(maxLevel)) end
    if tonumber(maxDistance) and tonumber(maxDistance) > 0 then table.insert(filters, 'Dist ' .. tostring(maxDistance)) end
    if ux.targetableOnly then table.insert(filters, 'Targetable only') end
    if npcOnly then table.insert(filters, 'NPC only') end
    return table.concat(filters, ', ')
end

ux.normalizeLevelFilters = function()
    minLevel = math.max(0, math.min(999, tonumber(minLevel) or 0))
    maxLevel = math.max(1, math.min(999, tonumber(maxLevel) or 999))
    if minLevel > maxLevel then minLevel = maxLevel end
end

local function currentTargetName()
    local t = safeCall(function() return mq.TLO.Target.CleanName() end, nil)
    if t == nil or t == '' then return nil end
    return tostring(t)
end

local function currentTargetRow()
    local nowValue = nowMs()
    local cache = ux.currentTargetCache or { at = 0, id = 0, row = nil }
    if (nowValue - (tonumber(cache.at) or 0)) < 200 then
        return cache.row
    end
    local id = tonumber(safeCall(function() return mq.TLO.Target.ID() end, 0)) or 0
    if id == 0 then
        ux.currentTargetCache = { at = nowValue, id = 0, row = nil }
        return nil
    end
    local row = allSpawnsById[id]
    if row then
        ux.currentTargetCache = { at = nowValue, id = id, row = row }
        return row
    end
    local name = currentTargetName()
    if not name then
        ux.currentTargetCache = { at = nowValue, id = id, row = nil }
        return nil
    end
    row = {
        id = id,
        name = name,
        trueName = tostring(safeCall(function() return mq.TLO.Target.Name() end, name) or name),
        level = tonumber(safeCall(function() return mq.TLO.Target.Level() end, 0)) or 0,
        distance = tonumber(safeCall(function() return mq.TLO.Target.Distance() end, 0)) or 0,
        type = tostring(safeCall(function() return mq.TLO.Target.Type() end, 'NPC') or 'NPC'),
        body = tostring(safeCall(function() return mq.TLO.Target.Body() end, 'Unknown') or 'Unknown'),
        race = tostring(safeCall(function() return mq.TLO.Target.Race() end, 'Unknown') or 'Unknown'),
        class = tostring(safeCall(function() return mq.TLO.Target.Class() end, 'Unknown') or 'Unknown'),
        ownerId = tonumber(safeCall(function() return mq.TLO.Target.OwnerID() end, 0)) or 0,
        targetable = true,
        dead = safeCall(function() return mq.TLO.Target.Dead() end, false),
        named = safeCall(function() return mq.TLO.Target.Named() end, false),
        x = tonumber(safeCall(function() return mq.TLO.Target.X() end, 0)) or 0,
        y = tonumber(safeCall(function() return mq.TLO.Target.Y() end, 0)) or 0,
        z = tonumber(safeCall(function() return mq.TLO.Target.Z() end, 0)) or 0,
    }
    ux.currentTargetCache = { at = nowValue, id = id, row = row }
    return row
end

local function addWatchFromCurrentTarget()
    local row = currentTargetRow()
    if not row then
        chat('No target selected. Target a mob in-game first.')
        return
    end
    addWatchExact(row, true)
    ux.refreshWatchesNow({ suppressAlerts = true })
end
ux.addWatchFromCurrentTarget = addWatchFromCurrentTarget

ux.assignPHFromCurrentTarget = function()
    local row = currentTargetRow()
    if not row then
        chat('No target selected. Target a placeholder mob first.')
        return
    end
    local selected = ux.selectedNamedWatch()
    if selected and selected.watch and selected.watch.label then
        if ux.addWatchPhForNamed(row, selected.watch.label) then
            ux.pendingWatchRow = nil
        end
        return
    end
    ux.pendingWatchRow = row
    ux.phNamedDraft = ux.phNamedDraft or ''
end

ux.targetActionLabel = function()
    local row = currentTargetRow()
    if not row then return 'Target a mob' end
    return 'Watch'
end

ux.drawTargetActionButton = function(sizeKey)
    local label = ux.targetActionLabel()
    local color = 'accent'
    local padX = sizeKey == 'small' and 6 or nil
    local padY = sizeKey == 'small' and 2 or nil
    if styledButton(label .. '##target_action_' .. tostring(sizeKey or 'normal'), color, padX, padY, 'Watch the current target. TurboMobs will classify it under the hood.') then
        addWatchFromCurrentTarget()
    end
end

ux.assignPHActionLabel = function()
    local selected = ux.selectedNamedWatch()
    if selected and selected.watch and selected.watch.label then
        return 'Assign PH to ' .. shortText(selected.watch.label, 18)
    end
    return 'Assign PH'
end

ux.drawAssignPHButton = function(sizeKey)
    local padX = sizeKey == 'small' and 6 or nil
    local padY = sizeKey == 'small' and 2 or nil
    if styledButton(ux.assignPHActionLabel() .. '##assign_ph_' .. tostring(sizeKey or 'normal'), 'accent', padX, padY, 'Link the current target as a placeholder for a named watch.') then
        ux.assignPHFromCurrentTarget()
    end
end

ux.assignPendingPhToNamed = function(label)
    local row = ux.pendingWatchRow
    label = trim(tostring(label or ''))
    if not row or label == '' then return false end
    if ux.addWatchPhForNamed(row, label) then
        ux.pendingWatchRow = nil
        ux.phNamedDraft = label
        ux.phNamedFilter = ''
        return true
    end
    return false
end

ux.namedAssignmentOptions = function()
    local seen = {}
    local out = {}
    local function add(label)
        label = trim(tostring(label or ''))
        if label == '' then return end
        local key = label:lower()
        if seen[key] then return end
        seen[key] = true
        table.insert(out, label)
    end

    local zone = currentZoneShort()
    for _, watch in pairs(watchList or {}) do
        local watchZone = tostring(watch.zone or ''):lower()
        if watchZone == '' or watchZone == zone then
            local category = tostring(watch.category or ''):lower()
            local source = tostring(watch.source or ''):lower()
            local label = tostring(watch.label or '')
            local lower = label:lower()
            if category == 'named' or source == 'spawnmaster' or source == 'zone intel'
                or (label:match('^[A-Z]') and not lower:match('^a ') and not lower:match('^an ')) then
                add(label)
            end
        end
    end

    local zoneTable = respawnsData[zone]
    local points = zoneTable and zoneTable._points or nil
    if type(points) == 'table' then
        for _, entry in pairs(points) do
            if type(entry) == 'table' and tostring(entry.category or ''):lower() == 'named' then
                add(entry.display_name or entry.last_seen_name)
            end
        end
    end

    table.sort(out, function(a, b) return a:lower() < b:lower() end)
    return out
end

ux.drawWatchByNamePanel = function()
    local avail = ux.contentAvailX(420)
    local inputW = math.max(160, math.min(320, avail - 96))
    ImGui.SetNextItemWidth(inputW)
    local nextName, changed
    if ImGui.InputTextWithHint then
        nextName, changed = ImGui.InputTextWithHint('##watch_by_name', 'Watch by name', tostring(ux.watchNameDraft or ''))
    else
        nextName, changed = ImGui.InputText('##watch_by_name', tostring(ux.watchNameDraft or ''))
    end
    if changed then ux.watchNameDraft = nextName or '' end
    ImGui.SameLine()
    if styledButton('Watch##watch_by_name_btn', 'primary', 8, 3, 'Create a name watch. If the mob is live, TurboMobs links its current point.') then
        local name = trim(tostring(ux.watchNameDraft or ''))
        if addWatchByName(name, true) then
            ux.watchNameDraft = ''
            ux.refreshWatchesNow({ suppressAlerts = true })
        else
            chat('Type a mob name to watch first.')
        end
    end
end

ux.drawWatchAssignmentPanel = function()
    local row = ux.pendingWatchRow
    if not row then return end

    ImGui.Separator()
    coloredText('Assign PH: ' .. tostring(row.name or 'unknown'), 'selected')
    coloredTextWrapped('Pick the named this placeholder belongs to. Typing is only needed for a new named.', 'muted')
    local selected = ux.selectedNamedWatch()
    if selected and selected.watch and selected.watch.label then
        if styledButton('Assign to selected: ' .. shortText(selected.watch.label, 22) .. '##ph_assign_selected', 'primary', nil, nil, 'Assign this target as the PH for the selected named watch.') then
            ux.assignPendingPhToNamed(selected.watch.label)
        end
    end

    local options = ux.namedAssignmentOptions()
    if #options > 0 then
        coloredText('Assign to existing named:', 'muted')
        ImGui.SetNextItemWidth(220)
        local filterValue, filterChanged
        if ImGui.InputTextWithHint then
            filterValue, filterChanged = ImGui.InputTextWithHint('##ph_named_filter', 'Filter named watches', tostring(ux.phNamedFilter or ''))
        else
            filterValue, filterChanged = ImGui.InputText('##ph_named_filter', tostring(ux.phNamedFilter or ''))
        end
        if filterChanged then ux.phNamedFilter = filterValue or '' end
        local filter = tostring(ux.phNamedFilter or ''):lower()
        local shown = 0
        if ImGui.BeginChild then ImGui.BeginChild('##ph_named_assign_list', 0, 104, true) end
        for i, label in ipairs(options) do
            if filter == '' or tostring(label or ''):lower():find(filter, 1, true) then
                shown = shown + 1
                if styledButton(shortText(label, 34) .. '##ph_pick_' .. tostring(i), 'tools', 7, 3, 'Assign this target as a PH for ' .. label .. '.') then
                    ux.assignPendingPhToNamed(label)
                end
                if shown % 3 ~= 0 then ImGui.SameLine() end
            end
            if shown >= 36 then break end
        end
        if shown == 0 then
            coloredText('No matching named watches. Type a new named below.', 'muted')
        end
        if ImGui.EndChild then ImGui.EndChild() end
    end

    if styledButton('Track as Normal Mob##watch_ph_direct', 'neutral', nil, nil, 'Track this non-named target by its own name and point.') then
        addWatchExact(row, true)
        ux.pendingWatchRow = nil
        ux.refreshWatchesNow({ suppressAlerts = true })
    end
    ImGui.SameLine()
    if styledButton('Cancel##watch_ph_clear', 'neutral', nil, nil, 'Clear this pending PH assignment.') then
        ux.pendingWatchRow = nil
    end

    ImGui.SetNextItemWidth(180)
    local nextName, changed = ImGui.InputText('New named##watch_ph_named', tostring(ux.phNamedDraft or ''))
    if changed then ux.phNamedDraft = nextName end
    ImGui.SameLine()
    if styledButton('Use as PH##watch_ph_assign', 'tools', nil, nil, 'Create or update a named point watch using this target as the current PH.') then
        if not ux.assignPendingPhToNamed(ux.phNamedDraft) then
            chat('Type the named mob label first, for example: Hadden')
        end
    end
end

-- ============================================================
-- Export / Import
-- ============================================================

ux.exportRespawns = function(zoneOrAll)
    ensureFolder(exportsFolder)
    local zone = trim(tostring(zoneOrAll or ''))
    local toExport = {
        _meta = {
            version = DATA_FORMAT_VERSION,
            server = currentServer(),
            exported_by = currentCharacter(),
            exported_at = dateStamp(),
            source_contributors = respawnsData._meta and respawnsData._meta.contributors or {},
        },
    }
    local label
    if zone == '' or zone:lower() == 'current' then
        zone = currentZoneShort()
    end
    if zone:lower() == 'all' then
        for k, v in pairs(respawnsData) do
            if k ~= '_meta' then toExport[k] = v end
        end
        label = 'all'
    else
        if respawnsData[zone] then
            toExport[zone] = respawnsData[zone]
            label = zone
        else
            chat('No respawn data for zone: ' .. zone)
            return nil
        end
    end

    local filename = string.format('respawns_%s_%s.lua', label, dateStamp())
    local outPath = exportsFolder .. '/' .. filename
    local ok = atomicWrite(outPath, serializeAsModule(toExport))
    if not ok then
        chat('Export failed (could not write file).')
        return nil
    end
    chat('Exported to: ' .. outPath)
    return outPath
end

local function mergeRespawnsEntry(zoneTable, key, incoming)
    if key == '_points' then return end
    zoneTable[key] = zoneTable[key] or {
        display_name = incoming.display_name or key,
        samples = {},
        last_death = 0,
        first_seen = os.time(),
    }
    local existing = zoneTable[key]
    if incoming.source or tostring(existing.display_name or ''):lower():find('raw data', 1, true) then
        existing.display_name = incoming.display_name or existing.display_name or key
    else
        existing.display_name = existing.display_name or incoming.display_name or key
    end
    existing.source = existing.source or incoming.source
    existing.source_url = existing.source_url or incoming.source_url
    existing.npc_id = tonumber(existing.npc_id) or tonumber(incoming.npc_id) or tonumber(incoming.id) or existing.npc_id
    local incomingTimer = tonumber(incoming.imported_respawn_seconds) or tonumber(incoming.respawn_seconds) or 0
    local existingTimer = tonumber(existing.imported_respawn_seconds) or 0
    local incomingSource = tostring(incoming.timer_source or incoming.source or '')
    local existingSource = tostring(existing.timer_source or existing.source or '')
    local function rank(source)
        source = tostring(source or ''):lower()
        if source:find('lazarus', 1, true) then return 30 end
        if source:find('pqdi', 1, true) then return 20 end
        if source ~= '' then return 10 end
        return 0
    end
    if incomingTimer > 0 and (existingTimer <= 0 or rank(incomingSource) >= rank(existingSource)) then
        existing.imported_respawn_seconds = incomingTimer
        existing.timer_source = incoming.timer_source or incoming.source or existing.timer_source
    else
        existing.imported_respawn_seconds = existingTimer > 0 and existingTimer or existing.imported_respawn_seconds
    end
    existing.timer_window_seconds = tonumber(existing.timer_window_seconds) or tonumber(incoming.timer_window_seconds) or existing.timer_window_seconds
    if type(incoming.samples) == 'table' then
        for _, s in ipairs(incoming.samples) do
            if type(s) == 'number' and s > 0 and s < 4 * 3600 then
                table.insert(existing.samples, math.floor(s))
            end
        end
        while #existing.samples > MAX_SAMPLES_PER_MOB do
            table.remove(existing.samples, 1)
        end
    end
end

local function mergePointEntry(pointsTable, key, incoming)
    if type(incoming) ~= 'table' then return end
    pointsTable[key] = pointsTable[key] or {
        display_name = incoming.display_name or incoming.last_seen_name or key,
        last_seen_name = incoming.last_seen_name or incoming.display_name or key,
        samples = {},
        names = {},
        last_death = 0,
        first_seen = os.time(),
        x = tonumber(incoming.x) or 0,
        y = tonumber(incoming.y) or 0,
        z = tonumber(incoming.z) or 0,
        last_spawn_id = tonumber(incoming.last_spawn_id) or 0,
    }
    local existing = pointsTable[key]
    local incomingIsSeed = tostring(incoming.seed_confidence or ''):lower() == 'imported'
        or tostring(incoming.source or ''):lower():find('alla', 1, true) ~= nil
    local existingRawLabel = tostring(existing.display_name or ''):lower():find('raw data', 1, true) ~= nil
    if incoming.source and (not incomingIsSeed or existingRawLabel or trim(tostring(existing.display_name or '')) == '') then
        existing.display_name = incoming.display_name or incoming.last_seen_name or existing.display_name or key
        existing.last_seen_name = incoming.last_seen_name or incoming.display_name or existing.last_seen_name
    else
        existing.display_name = existing.display_name or incoming.display_name or incoming.last_seen_name or key
        existing.last_seen_name = incoming.last_seen_name or existing.last_seen_name
    end
    existing.last_death = math.max(tonumber(existing.last_death) or 0, tonumber(incoming.last_death) or 0)
    existing.first_seen = math.min(tonumber(existing.first_seen) or os.time(), tonumber(incoming.first_seen) or os.time())
    existing.x = tonumber(incoming.x) or existing.x
    existing.y = tonumber(incoming.y) or existing.y
    existing.z = tonumber(incoming.z) or existing.z
    existing.last_spawn_id = tonumber(incoming.last_spawn_id) or existing.last_spawn_id
    existing.source = incoming.source or existing.source
    existing.source_url = incoming.source_url or existing.source_url
    existing.category = incoming.category or existing.category
    if incoming.clear_named_name then existing.named_name = nil
    else existing.named_name = incoming.named_name or existing.named_name end
    existing.npc_id = tonumber(existing.npc_id) or tonumber(incoming.npc_id) or tonumber(incoming.id) or existing.npc_id
    if incoming.seed_name then
        existing.seed_names = appendUniqueText(existing.seed_names, incoming.seed_name, 96)
    end
    if type(incoming.seed_names) == 'table' then
        for _, name in ipairs(incoming.seed_names) do
            existing.seed_names = appendUniqueText(existing.seed_names, name, 96)
        end
    end
    local incomingTimer = tonumber(incoming.respawn_seconds) or tonumber(incoming.imported_respawn_seconds) or 0
    local existingTimer = tonumber(existing.respawn_seconds) or tonumber(existing.imported_respawn_seconds) or 0
    local incomingSource = tostring(incoming.timer_source or incoming.source or '')
    local existingSource = tostring(existing.timer_source or existing.source or '')
    local function rank(source)
        source = tostring(source or ''):lower()
        if source:find('lazarus', 1, true) then return 30 end
        if source:find('pqdi', 1, true) then return 20 end
        if source ~= '' then return 10 end
        return 0
    end
    if incomingTimer > 0 and (existingTimer <= 0 or rank(incomingSource) >= rank(existingSource)) then
        existing.respawn_seconds = incomingTimer
        existing.timer_source = incoming.timer_source or incoming.source or existing.timer_source
    else
        existing.respawn_seconds = existingTimer > 0 and existingTimer or existing.respawn_seconds
    end
    existing.timer_window_seconds = tonumber(incoming.timer_window_seconds) or tonumber(existing.timer_window_seconds) or existing.timer_window_seconds
    existing.chance = tonumber(incoming.chance) or tonumber(existing.chance) or existing.chance
    existing.anchor_radius = tonumber(incoming.anchor_radius) or tonumber(existing.anchor_radius) or existing.anchor_radius
    existing.seed_confidence = incoming.seed_confidence or existing.seed_confidence
    if type(incoming.names) == 'table' then
        for _, name in ipairs(incoming.names) do touchNameList(existing, name) end
    end
    if type(incoming.ph_names) == 'table' then
        existing.ph_names = existing.ph_names or {}
        local seen = {}
        for _, name in ipairs(existing.ph_names) do seen[tostring(name or ''):lower()] = true end
        for _, name in ipairs(incoming.ph_names) do
            local clean = trim(tostring(name or ''))
            local keyName = clean:lower()
            if clean ~= '' and not seen[keyName] then
                table.insert(existing.ph_names, clean)
                seen[keyName] = true
            end
            touchNameList(existing, clean)
        end
        while #existing.ph_names > 16 do table.remove(existing.ph_names, 1) end
    end
    if type(incoming.samples) == 'table' then
        for _, s in ipairs(incoming.samples) do
            if type(s) == 'number' and s > 0 and s < 4 * 3600 then
                table.insert(existing.samples, math.floor(s))
            end
        end
        while #existing.samples > MAX_SAMPLES_PER_MOB do
            table.remove(existing.samples, 1)
        end
    end
end

ux.importRespawns = function(filenameOrPath)
    ensureFolder(exportsFolder)
    local raw = trim(tostring(filenameOrPath or ''))
    if raw == '' then
        chat('Usage: /tmobs import <filename>  (file should be in exports/ folder)')
        return false
    end

    local candidates = { raw, exportsFolder .. '/' .. raw }
    local path = nil
    for _, p in ipairs(candidates) do
        if pathExists(p) then path = p; break end
    end
    if not path then
        chat('Import failed: file not found. Looked at:')
        for _, p in ipairs(candidates) do chat('  ' .. p) end
        return false
    end

    local ok, data = pcall(dofile, path)
    if not ok or type(data) ~= 'table' then
        chat('Import failed: file is not a valid Lua table.')
        return false
    end

    if type(data._meta) == 'table' and tostring(data._meta.format or '') == 'TurboMobsAllaSeed' then
        notify('Detected Alla seed file; using Import Alla Seed.')
        ux.requestAllaImport(filenameOrPath)
        return true
    end

    if type(data._meta) == 'table' and data._meta.server and data._meta.server ~= '' then
        local mine = currentServer()
        if mine ~= '' and data._meta.server ~= mine then
            chat(string.format('NOTE: file is from server "%s", you are on "%s". Importing anyway.', data._meta.server, mine))
        end
    end

    local zonesImported, mobsNew, mobsMerged = 0, 0, 0
    for zoneKey, zoneTable in pairs(data) do
        if zoneKey ~= '_meta' and type(zoneTable) == 'table' then
            zonesImported = zonesImported + 1
            if not respawnsData[zoneKey] then respawnsData[zoneKey] = {} end
            local targetZone = respawnsData[zoneKey]
            for mobKey, mobEntry in pairs(zoneTable) do
                if mobKey == '_points' and type(mobEntry) == 'table' then
                    targetZone._points = targetZone._points or {}
                    for pointKey, pointEntry in pairs(mobEntry) do
                        if not targetZone._points[pointKey] then mobsNew = mobsNew + 1
                        else mobsMerged = mobsMerged + 1 end
                        mergePointEntry(targetZone._points, pointKey, pointEntry)
                    end
                elseif type(mobEntry) == 'table' then
                    if targetZone[mobKey] then mobsMerged = mobsMerged + 1
                    else mobsNew = mobsNew + 1 end
                    mergeRespawnsEntry(targetZone, mobKey, mobEntry)
                end
            end
        end
    end

    if type(data._meta) == 'table' and type(data._meta.source_contributors) == 'table' then
        respawnsData._meta.contributors = respawnsData._meta.contributors or {}
        local seen = {}
        for _, c in ipairs(respawnsData._meta.contributors) do seen[c] = true end
        for _, c in ipairs(data._meta.source_contributors) do
            if not seen[c] then
                table.insert(respawnsData._meta.contributors, c)
                seen[c] = true
            end
        end
    end

    respawnsDirty = true; ux.statsRevision = (ux.statsRevision or 0) + 1
    saveRespawns(true)

    local msg = string.format('Imported: %d zones, %d new mobs, %d merged.', zonesImported, mobsNew, mobsMerged)
    chat(msg)
    importStatusMsg = msg
    return true
end

ux.parseDurationSeconds = function(value)
    if type(value) == 'number' then return math.floor(value) end
    local text = tostring(value or ''):lower()
    if text == '' or text == '-' then return 0 end
    local total = 0
    local matched = false
    for n, unit in text:gmatch('(%d+)%s*([hms])') do
        matched = true
        local v = tonumber(n) or 0
        if unit == 'h' then total = total + (v * 3600)
        elseif unit == 'm' then total = total + (v * 60)
        elseif unit == 's' then total = total + v end
    end
    if matched then return total end
    -- M:SS or H:MM:SS formats e.g. "28:40" or "1:28:40"
    local h, m, s = text:match('^(%d+):(%d+):(%d+)$')
    if h and m and s then return (tonumber(h) or 0) * 3600 + (tonumber(m) or 0) * 60 + (tonumber(s) or 0) end
    local m2, s2 = text:match('^(%d+):(%d+)$')
    if m2 and s2 then return (tonumber(m2) or 0) * 60 + (tonumber(s2) or 0) end
    return tonumber(text:match('(%d+)')) or 0
end

ux.normalizeSeedNameList = function(value)
    local out = {}
    for _, name in ipairs(normalizeWatchNameList(value or {})) do
        if name ~= '' then table.insert(out, name) end
    end
    return out
end

ux.seedNameKey = TM.seedNameKey

ux.seedRecordPoints = function(record)
    if type(record.points) == 'table' then return record.points end
    if type(record.spawns) == 'table' then return record.spawns end
    return { record }
end

ux.resolveAllaSeedPath = function(filenameOrPath, quiet)
    ensureFolder(exportsFolder)
    local raw = trim(tostring(filenameOrPath or ''))
    if raw == '' then raw = trim(tostring(importInputFile or '')) end
    local zoneSeed = string.format('%s.lua', currentZoneShort())
    local legacyZoneSeed = string.format('alla_seed_%s.lua', currentZoneShort())
    local bundledFolder = turboFolder .. '/alla_seeds'
    local source = debug.getinfo(1, 'S').source or ''
    local folder = source:sub(1, 1) == '@' and source:sub(2):gsub('\\', '/'):match('^(.+)/[^/]+$') or ''
    if raw == '' then
        raw = zoneSeed
        if not quiet then notify('Alla seed import: no file supplied; trying current-zone seed ' .. raw) end
    end
    local candidates = {
        raw,
        'alla_seeds/' .. raw,
        'alla_seeds/' .. zoneSeed,
        'alla_seeds/' .. legacyZoneSeed,
        '../alla_seeds/' .. raw,
        '../alla_seeds/' .. zoneSeed,
        '../alla_seeds/' .. legacyZoneSeed,
    }
    if folder ~= '' then
        table.insert(candidates, folder .. '/alla_seeds/' .. raw)
        table.insert(candidates, folder .. '/alla_seeds/' .. zoneSeed)
        table.insert(candidates, folder .. '/alla_seeds/' .. legacyZoneSeed)
        table.insert(candidates, folder .. '/../alla_seeds/' .. raw)
        table.insert(candidates, folder .. '/../alla_seeds/' .. zoneSeed)
        table.insert(candidates, folder .. '/../alla_seeds/' .. legacyZoneSeed)
    end
    table.insert(candidates, exportsFolder .. '/' .. raw)
    table.insert(candidates, exportsFolder .. '/' .. zoneSeed)
    table.insert(candidates, exportsFolder .. '/' .. legacyZoneSeed)
    table.insert(candidates, bundledFolder .. '/' .. raw)
    table.insert(candidates, bundledFolder .. '/' .. zoneSeed)
    table.insert(candidates, bundledFolder .. '/' .. legacyZoneSeed)
    local seen = {}
    for _, p in ipairs(candidates) do
        if not seen[p] then
            seen[p] = true
            if pathExists(p) then
                if not quiet then chat('Alla seed file: ' .. tostring(p)) end
                return p, raw
            end
        end
    end
    if not quiet then
        notify('Alla seed file not found.')
        for _, p in ipairs(candidates) do if not seen['printed:' .. p] then seen['printed:' .. p] = true; chat('  ' .. p) end end
    end
    return nil, raw
end

ux.loadAllaSeedFile = function(filenameOrPath, quiet)
    local path, raw = ux.resolveAllaSeedPath(filenameOrPath, quiet)
    if not path then return nil, nil, raw end
    local ok, data = pcall(dofile, path)
    if not ok or type(data) ~= 'table' then
        if not quiet then notify('Alla seed failed to load: ' .. tostring(data or 'file is not a valid Lua table')) end
        return nil, path, raw
    end
    return data, path, raw
end

ux.allaSeedZoneRecords = function(data)
    local out = {}
    if type(data) ~= 'table' then return out end
    local zones = type(data.zones) == 'table' and data.zones or data
    for zoneKey, zoneData in pairs(zones) do
        if zoneKey ~= '_meta' and zoneKey ~= 'zones' and type(zoneData) == 'table' then
            local zoneName = tostring(zoneData.zone or zoneData.short_name or zoneKey):lower()
            local records = zoneData.named or zoneData.npcs or zoneData
            table.insert(out, { zone = zoneName, records = records })
        end
    end
    table.sort(out, function(a, b) return tostring(a.zone) < tostring(b.zone) end)
    return out
end

ux.allaSeedSummary = function(data, path)
    local summary = {
        path = path or '',
        source = type(data) == 'table' and type(data._meta) == 'table' and tostring(data._meta.source or '') or '',
        schemaVersion = type(data) == 'table' and type(data._meta) == 'table' and tostring(data._meta.schema_version or '') or '',
        zones = 0,
        records = 0,
        points = 0,
        recordsWithoutPoints = 0,
        duplicatePoints = 0,
        pointsMissingTimers = 0,
        details = {},
    }
    local zoneRecords = ux.allaSeedZoneRecords(data)
    summary.zones = #zoneRecords
    for _, zoneBlock in ipairs(zoneRecords) do
        local seenPoints = {}
        for _, record in pairs(zoneBlock.records or {}) do
            if type(record) == 'table' then
                summary.records = summary.records + 1
                local name = trim(tostring(record.name or record.display_name or record.named_name or record.npc_id or record.id or 'Unknown'))
                local validPoints = 0
                for _, point in ipairs(ux.seedRecordPoints(record)) do
                    if type(point) == 'table' then
                        local coords = type(point.coords) == 'table' and point.coords or {}
                        local x = tonumber(point.x) or tonumber(coords.x) or tonumber(coords[1])
                        local y = tonumber(point.y) or tonumber(coords.y) or tonumber(coords[2])
                        if x ~= nil and y ~= nil then
                            validPoints = validPoints + 1
                            summary.points = summary.points + 1
                            local pointKey = ux.pointKeyFromCoords(x, y) or string.format('%.1f,%.1f', x, y)
                            local scopedKey = tostring(zoneBlock.zone) .. ':' .. pointKey
                            if seenPoints[scopedKey] then
                                summary.duplicatePoints = summary.duplicatePoints + 1
                                if #summary.details < 16 then
                                    table.insert(summary.details, string.format('Duplicate point %s: %s also overlaps %s', pointKey, name, seenPoints[scopedKey]))
                                end
                            else
                                seenPoints[scopedKey] = name
                            end
                            local respawnSeconds = ux.parseDurationSeconds(point.respawn_seconds or point.respawn or point.timer or record.respawn_seconds or record.respawn or record.timer or record.respawn_text)
                            if respawnSeconds <= 0 then
                                summary.pointsMissingTimers = summary.pointsMissingTimers + 1
                                if #summary.details < 16 then
                                    table.insert(summary.details, string.format('Missing timer: %s @ %s', name, pointKey))
                                end
                            end
                        end
                    end
                end
                if validPoints == 0 then
                    summary.recordsWithoutPoints = summary.recordsWithoutPoints + 1
                    if #summary.details < 16 then
                        table.insert(summary.details, 'No spawn points: ' .. name)
                    end
                end
            end
        end
    end
    return summary
end

ux.allaSeedSummaryText = function(summary)
    if type(summary) ~= 'table' then return 'Alla seed preview unavailable.' end
    local warnCount = (tonumber(summary.recordsWithoutPoints) or 0) + (tonumber(summary.duplicatePoints) or 0) + (tonumber(summary.pointsMissingTimers) or 0)
    local prefix = warnCount > 0 and 'Alla seed preview WARN' or 'Alla seed preview OK'
    local schema = tostring(summary.schemaVersion or '')
    local source = tostring(summary.source or '')
    local meta = {}
    if schema ~= '' then table.insert(meta, 'schema ' .. schema) end
    if source ~= '' then table.insert(meta, source) end
    local suffix = #meta > 0 and (' [' .. table.concat(meta, ', ') .. ']') or ''
    return string.format('%s: %d zone(s), %d named, %d point(s), %d no-point, %d duplicate, %d missing timer%s.',
        prefix, tonumber(summary.zones) or 0, tonumber(summary.records) or 0, tonumber(summary.points) or 0,
        tonumber(summary.recordsWithoutPoints) or 0, tonumber(summary.duplicatePoints) or 0,
        tonumber(summary.pointsMissingTimers) or 0, suffix)
end

ux.chatAllaSeedSummary = function(summary)
    local text = ux.allaSeedSummaryText(summary)
    notify(text)
    for _, detail in ipairs(summary and summary.details or {}) do
        chat('  ' .. tostring(detail))
    end
end

ux.previewAllaSeed = function(filenameOrPath)
    chat('Alla seed preview requested for ' .. (trim(tostring(filenameOrPath or '')) ~= '' and trim(tostring(filenameOrPath or '')) or currentZoneShort()))
    local data, path = ux.loadAllaSeedFile(filenameOrPath, false)
    if not data then return false end
    local summary = ux.allaSeedSummary(data, path)
    ux.lastAllaSeedSummary = summary
    importStatusMsg = ux.allaSeedSummaryText(summary)
    ux.chatAllaSeedSummary(summary)
    return true
end

ux.seedProfileFromMeta = function(meta)
    if type(meta) ~= 'table' then return 'lazarus' end
    return tostring(meta.seed_profile or meta.server_profile or 'lazarus'):lower()
end

ux.shouldImportSeedTimers = function(seedMeta)
    if ux.useBundledSeedTimers == false then return false end
    if ux.useBundledSeedTimers == true then return true end
    local profile = ux.seedProfileFromMeta(seedMeta)
    if profile == '' or profile == 'lazarus' or profile == 'any' then
        return ux.isLazarusServer()
    end
    return false
end

ux.resolveBundledSeedTimersPreference = function()
    if ux.useBundledSeedTimers ~= nil then return end
    local server = currentServer()
    if server == '' or ux.isLazarusServer() then
        ux.useBundledSeedTimers = true
    else
        ux.useBundledSeedTimers = false
    end
    if saveSettings then saveSettings() end
end

ux.seedPointsMissingTimers = function()
    local seeded, timed = 0, 0
    for zoneKey, zoneTable in pairs(respawnsData or {}) do
        if zoneKey ~= '_meta' and type(zoneTable) == 'table' then
            local points = zoneTable._points
            if type(points) == 'table' then
                for _, pt in pairs(points) do
                    if type(pt) == 'table' and pt.category == 'seed' then
                        local src = tostring(pt.source or ''):lower()
                        if src:find('alla', 1, true) or src:find('lazarus', 1, true) then
                            seeded = seeded + 1
                            if (tonumber(pt.respawn_seconds) or 0) > 0 then timed = timed + 1 end
                        end
                    end
                end
            end
        end
    end
    return seeded > 0 and timed == 0
end

ux.countAllaSeedZones = function()
    local count = 0
    for zoneKey, zoneTable in pairs(respawnsData or {}) do
        if zoneKey ~= '_meta' and type(zoneTable) == 'table' then
            local points = zoneTable._points
            if type(points) == 'table' then
                for _, pt in pairs(points) do
                    if type(pt) == 'table' and pt.category == 'seed' then
                        local src = tostring(pt.source or ''):lower()
                        local timerSrc = tostring(pt.timer_source or ''):lower()
                        if src:find('alla', 1, true) or src:find('lazarus', 1, true)
                            or timerSrc:find('lazarus', 1, true) or timerSrc:find('alla', 1, true) then
                            count = count + 1
                            break
                        end
                    end
                end
            end
        end
    end
    return count
end

ux.hasExistingBundledSeedData = function()
    local zonesWithSeed = ux.countAllaSeedZones()
    if zonesWithSeed >= 3 then return true end
    if zonesWithSeed >= 1 and ux.seedAutoMaintain == true then return true end
    return false
end

ux.markBundledSeedImportComplete = function(generatedAt)
    ux.bundledSeedAutoImported = true
    allaHintShown = true
    if generatedAt and generatedAt ~= '' then
        ux.bundledSeedGeneratedAt = tostring(generatedAt)
    end
    if saveSettings then saveSettings() end
end

ux.maybeAutoImportBundledSeed = function()
    if not ux.respawnsLoaded then return end
    if not clientInGame() then return end
    if ux.pendingAllaImport or ux.allaSeedImportInProgress == true then return end
    local bundlePath = ux.resolveAllaSeedPath and select(1, ux.resolveAllaSeedPath('alla_seeds_all.lua', true)) or nil
    if not bundlePath then
        if ux.bundledSeedAutoImported ~= true then ux.markBundledSeedImportComplete() end
        return
    end
    ux.resolveBundledSeedTimersPreference()
    local bundleData = ux.loadAllaSeedFile('alla_seeds_all.lua', true)
    local wantTimers = bundleData and ux.shouldImportSeedTimers(bundleData._meta) or false
    local bundleGeneratedAt = tostring((bundleData and bundleData._meta and bundleData._meta.generated_at) or '')
    if ux.bundledSeedTimerRepairDone ~= true and ux.hasExistingBundledSeedData() and wantTimers and ux.seedPointsMissingTimers() then
        ux.bundledSeedTimerRepairDone = true
        if saveSettings then saveSettings() end
        chat('\\ayTurboMobs:\\ax Re-importing bundled seed with Lazarus respawn timers...')
        ux.requestAllaImport('alla_seeds_all.lua', true, { autoBundled = true, timerRepair = true })
        return
    end
    -- If the bundle has been updated since the last import, re-import to pick up new entries.
    local savedGeneratedAt = tostring(ux.bundledSeedGeneratedAt or '')
    if ux.bundledSeedAutoImported == true
        and bundleGeneratedAt ~= ''
        and savedGeneratedAt ~= ''
        and bundleGeneratedAt > savedGeneratedAt
        and ux.hasExistingBundledSeedData() then
        chat(string.format('\\ayTurboMobs:\\ax Bundled seed updated (%s → %s); re-importing to pick up new entries...', savedGeneratedAt, bundleGeneratedAt))
        ux.bundledSeedAutoImported = false
        ux.requestAllaImport('alla_seeds_all.lua', true, { autoBundled = true })
        return
    end
    if ux.bundledSeedAutoImported == true then return end
    if ux.hasExistingBundledSeedData() then
        if ux.seedAutoMaintain ~= true then
            ux.seedAutoMaintain = true
            if saveSettings then saveSettings() end
        end
        ux.markBundledSeedImportComplete(bundleGeneratedAt)
        return
    end
    ux.resolveBundledSeedTimersPreference()
    ux.requestAllaImport('alla_seeds_all.lua', true, { autoBundled = true })
end

ux.mergeAllaSeedRecord = function(zoneKey, record, sourceText, importOpts)
    if type(record) ~= 'table' then return 0, 0 end
    importOpts = type(importOpts) == 'table' and importOpts or {}
    local skipTimers = importOpts.skipTimers == true
    zoneKey = tostring(zoneKey or ''):lower()
    if zoneKey == '' then return 0, 0 end
    local named = trim(tostring(record.name or record.display_name or record.named_name or ''))
    if named == '' then return 0, 0 end

    respawnsData[zoneKey] = respawnsData[zoneKey] or {}
    local zoneTable = respawnsData[zoneKey]
    local mobKey = named:lower()
    mergeRespawnsEntry(zoneTable, mobKey, {
        display_name = named,
        npc_id = tonumber(record.npc_id) or tonumber(record.id) or 0,
        imported_respawn_seconds = skipTimers and 0 or ux.parseDurationSeconds(record.respawn_seconds or record.respawn or record.timer or record.respawn_text),
        timer_window_seconds = skipTimers and 0 or ux.parseDurationSeconds(record.timer_window_seconds or record.timer_window),
        timer_source = skipTimers and 'names_only' or (record.timer_source or record.source_type or sourceText),
        source = sourceText,
        source_url = record.source_url or record.url,
    })

    zoneTable._points = zoneTable._points or {}
    local pointCount = 0
    for _, point in ipairs(ux.seedRecordPoints(record)) do
        if type(point) == 'table' then
            local coords = type(point.coords) == 'table' and point.coords or {}
            local x = tonumber(point.x) or tonumber(coords.x) or tonumber(coords[1])
            local y = tonumber(point.y) or tonumber(coords.y) or tonumber(coords[2])
            local z = tonumber(point.z) or tonumber(coords.z) or tonumber(coords[3]) or 0
            if x ~= nil and y ~= nil then
                local key = ux.pointKeyFromCoords(x, y)
                local phNames = ux.normalizeSeedNameList(point.ph_names or point.placeholders or record.ph_names or record.placeholders)
                local names = { named }
                for _, ph in ipairs(phNames) do table.insert(names, ph) end
                local respawnSeconds = skipTimers and 0 or ux.parseDurationSeconds(point.respawn_seconds or point.respawn or point.timer or record.respawn_seconds or record.respawn or record.timer or record.respawn_text)
                mergePointEntry(zoneTable._points, key, {
                    display_name = named,
                    last_seen_name = named,
                    names = names,
                    ph_names = phNames,
                    seed_name = named,
                    x = x,
                    y = y,
                    z = z,
                    npc_id = tonumber(record.npc_id) or tonumber(record.id) or 0,
                    named_name = nil,
                    clear_named_name = true,
                    category = 'seed',
                    source = sourceText,
                    source_url = point.source_url or record.source_url or record.url,
                    respawn_seconds = respawnSeconds,
                    timer_source = skipTimers and 'names_only' or (point.timer_source or point.source_type or record.timer_source or record.source_type or sourceText),
                    timer_window_seconds = skipTimers and 0 or ux.parseDurationSeconds(point.timer_window_seconds or point.timer_window or record.timer_window_seconds or record.timer_window),
                    chance = tonumber(point.chance) or tonumber(record.chance) or 0,
                    anchor_radius = tonumber(point.anchor_radius) or ux.defaultPointOccupantRadius,
                    seed_confidence = 'imported',
                })
                pointCount = pointCount + 1
            end
        end
    end
    return 1, pointCount
end

ux.createAllaSeedWatch = function(zoneKey, record, point, sourceText)
    if type(record) ~= 'table' or type(point) ~= 'table' then return false end
    zoneKey = tostring(zoneKey or ''):lower()
    if zoneKey == '' then return false end
    local named = trim(tostring(record.name or record.display_name or record.named_name or ''))
    if named == '' then return false end
    local coords = type(point.coords) == 'table' and point.coords or {}
    local x = tonumber(point.x) or tonumber(coords.x) or tonumber(coords[1])
    local y = tonumber(point.y) or tonumber(coords.y) or tonumber(coords[2])
    if x == nil or y == nil then return false end
    local z = tonumber(point.z) or tonumber(coords.z) or tonumber(coords[3]) or 0
    local pointKey = ux.pointKeyFromCoords(x, y)
    if not pointKey or pointKey == '' then return false end
    local phNames = ux.normalizeSeedNameList(point.ph_names or point.placeholders or record.ph_names or record.placeholders)
    for _, existing in pairs(watchList or {}) do
        if type(existing) == 'table'
            and tostring(existing.zone or ''):lower() == zoneKey
            and existing.lastSpawnPointKey == pointKey
            and ux.watchLabelListedAsPh(existing, named)
            and not ux.incomingSeedMutualNamedPair(existing, phNames, named) then
            return false
        end
    end
    local key = ux.watchKeyForZonePoint(named, zoneKey, pointKey)
    if watchList[key] then
        local existingSource = tostring(watchList[key].source or ''):lower()
        if not (existingSource:find('alla', 1, true) or existingSource:find('lazarus', 1, true)) then
            return false
        end
        return false
    end
    watchList[key] = {}
    local watch = watchList[key]
    watch.label = named
    watch.seedPointLabel = pointKey
    watch.desiredName = tostring(named or ''):lower()
    watch.mode = 'smart'
    watch.zone = zoneKey
    watch.source = sourceText or 'Project Lazarus Alla'
    watch.category = 'named'
    watch.trackingMode = ux.seedWatchTrackingMode(record, point, named)
    watch.phNames = phNames
    watch.areaRadius = 0
    -- Authoritative seed PH list (kept separate from phNames, which sanitize and
    -- learning may trim). Lets phNameSeedSanctioned recognize legitimate
    -- named-as-PH camps (Pyzjn/Varsoon/Yollis) that the generic guard would drop.
    watch.seedPhNames = {}
    for _, n in ipairs(phNames) do table.insert(watch.seedPhNames, n) end
    watch.spawnId = 0
    watch.respawnSeconds = 0
    watch.isUp = false
    watch.pointOccupied = false
    watch.currentName = ''
    watch.currentIsDesired = false
    watch.lastSeenAt = 0
    watch.despawnedAt = 0
    watch.killedAtText = ''
    watch.expectedRespawnAt = 0
    watch.initialResolved = true
    watch.lastSpawnPointKey = pointKey
    watch.pointConfidence = 'trusted'
    watch.pointSamples = MIN_SAMPLES_FOR_DISPLAY
    watch.lastX = x
    watch.lastY = y
    watch.lastZ = z
    watch.lastSpawnId = 0
    watch.anchorRadius = math.max(tonumber(point.anchor_radius) or 0, ux.seedWatchAnchorRadius or 30)
    return true
end

ux.createAllaSeedWatchesForZone = function(zoneName, records, sourceText)
    zoneName = tostring(zoneName or ''):lower()
    if zoneName == '' then return 0 end
    local created = 0
    for _, record in pairs(records or {}) do
        if type(record) == 'table' then
            for _, point in ipairs(ux.seedRecordPoints(record)) do
                if ux.createAllaSeedWatch(zoneName, record, point, sourceText) then
                    created = created + 1
                end
            end
        end
    end
    return created
end

ux.createAllaSeedWatchesForCurrentZone = function(zoneName, records, sourceText)
    zoneName = tostring(zoneName or ''):lower()
    if zoneName == '' or zoneName ~= currentZoneShort() then return 0 end
    return ux.createAllaSeedWatchesForZone(zoneName, records, sourceText)
end

ux.repairMutualSeedNamedWatchesForZone = function(zoneKey)
    zoneKey = tostring(zoneKey or currentZoneShort()):lower()
    if zoneKey == '' or zoneKey == 'unknown' then return 0 end
    if not ux.respawnsLoaded then return 0 end
    ux.mutualSeedRepairZones = ux.mutualSeedRepairZones or {}
    if ux.mutualSeedRepairZones[zoneKey] then return 0 end
    local data = select(1, ux.loadAllaSeedFile and ux.loadAllaSeedFile(zoneKey .. '.lua', true))
    if not data then return 0 end
    local zones = type(data.zones) == 'table' and data.zones or data
    local zoneData = zones[zoneKey]
    if type(zoneData) ~= 'table' then
        ux.mutualSeedRepairZones[zoneKey] = true
        return 0
    end
    local records = zoneData.named or zoneData.npcs or zoneData
    local sourceText = 'Project Lazarus Alla'
    if type(data._meta) == 'table' and data._meta.source then sourceText = tostring(data._meta.source) end
    local added = ux.createAllaSeedWatchesForZone(zoneKey, records, sourceText)
    ux.mutualSeedRepairZones[zoneKey] = true
    if added > 0 then
        if ux.rebuildWatchIndex then ux.rebuildWatchIndex() end
        if ux.markWatchStateDirty then ux.markWatchStateDirty() end
        if ux.queueWatchSaveWhenSafe then ux.queueWatchSaveWhenSafe('mutual-seed-repair') end
        if ux.recordPerfLine then
            ux.recordPerfLine(string.format('Mutual seed named repair zone=%s added=%d', zoneKey, added))
        end
    end
    return added
end

ux.cleanupAllaSeedForImport = function(zoneKey, importedKeysByName, sourceText)
    local zoneTable = respawnsData[tostring(zoneKey or ''):lower()]
    if type(zoneTable) ~= 'table' then return 0 end
    local removed = 0
    for key, entry in pairs(zoneTable) do
        if key ~= '_points' and type(entry) == 'table' then
            local display = tostring(entry.display_name or '')
            local source = tostring(entry.source or '')
            if display:lower():find('raw data', 1, true) and (source == '' or source == sourceText) then
                zoneTable[key] = nil
                removed = removed + 1
            end
        end
    end
    local points = zoneTable._points
    if type(points) ~= 'table' then return removed end
    for key, entry in pairs(points) do
        if type(entry) == 'table' then
            local source = tostring(entry.source or '')
            local isImported = source == sourceText or tostring(entry.seed_confidence or '') == 'imported'
            local rawLabel = tostring(entry.display_name or ''):lower():find('raw data', 1, true) ~= nil
            if rawLabel and isImported then
                points[key] = nil
                removed = removed + 1
            elseif isImported then
                local hasKnownSeedName = false
                local keepAny = false
                local function checkName(name)
                    local named = ux.seedNameKey(name or '')
                    local keepSet = importedKeysByName[named]
                    if keepSet then
                        hasKnownSeedName = true
                        if keepSet[key] then keepAny = true end
                    end
                end
                checkName(entry.named_name)
                if type(entry.seed_names) == 'table' then
                    for _, seedName in ipairs(entry.seed_names) do checkName(seedName) end
                end
                checkName(entry.display_name)
                if hasKnownSeedName and not keepAny then
                    points[key] = nil
                    removed = removed + 1
                end
            end
        end
    end
    return removed
end

ux.importAllaSeed = function(filenameOrPath, quiet, importContext)
    if not ux.ensureRespawnsLoaded('Alla import') then return false end
    importContext = type(importContext) == 'table' and importContext or {}
    ux.allaSeedImportInProgress = true
    if not quiet then chat('Alla seed import requested for ' .. (trim(tostring(filenameOrPath or '')) ~= '' and trim(tostring(filenameOrPath or '')) or currentZoneShort())) end
    local data, path = ux.loadAllaSeedFile(filenameOrPath, quiet)
    if not data then
        ux.allaSeedImportInProgress = false
        ux.allaSeedImportStartedMS = 0
        if ux.clearWatchSeedAwaiting then ux.clearWatchSeedAwaiting() end
        return false
    end
    local summary = ux.allaSeedSummary(data, path)
    ux.lastAllaSeedSummary = summary
    importStatusMsg = ux.allaSeedSummaryText(summary)
    if not quiet then
        ux.chatAllaSeedSummary(summary)
        chat('Applying seed data now (all zones — may take 10-30 seconds)...')
    end
    importStatusMsg = 'Applying seed data...'
    local importTimers = importContext.timerRepair == true or ux.shouldImportSeedTimers(data._meta)
    local mergeOpts = { skipTimers = not importTimers }
    if not quiet and not importTimers then
        chat('Alla seed import: names, camps, and PH lists only (respawn timers skipped for this server/profile).')
    end
    -- Remember that the player opted into seed data; from now on we keep every
    -- zone's seed watches current automatically on zone-in (one-click import).
    if ux.seedAutoMaintain ~= true then
        ux.seedAutoMaintain = true
        if saveSettings then saveSettings() end
    end

    local sourceText = 'Alla seed'
    if type(data._meta) == 'table' and data._meta.source then sourceText = tostring(data._meta.source) end
    local zonesImported, namedImported, pointsImported, staleRemoved, seedWatches = 0, 0, 0, 0, 0
    local staleWatches, prunedPoint = 0, 0
    local zones = type(data.zones) == 'table' and data.zones or data
    local zoneList = {}
    for zoneKey, zoneData in pairs(zones) do
        if zoneKey ~= '_meta' and type(zoneData) == 'table' then
            table.insert(zoneList, { key = zoneKey, data = zoneData })
        end
    end
    table.sort(zoneList, function(a, b) return tostring(a.key) < tostring(b.key) end)
    local totalZones = #zoneList
    local zonesDone = 0
    for _, zoneItem in ipairs(zoneList) do
        local zoneKey = zoneItem.key
        local zoneData = zoneItem.data
        zonesDone = zonesDone + 1
        if not quiet and (zonesDone == 1 or zonesDone == totalZones or zonesDone % 20 == 0) then
            local progress = string.format('Applying seed data: zone %d/%d...', zonesDone, totalZones)
            importStatusMsg = progress
            chat(progress)
        end
            local zoneName = tostring(zoneData.zone or zoneData.short_name or zoneKey):lower()
            local records = zoneData.named or zoneData.npcs or zoneData
            local zoneHadData = false
            local importedKeysByName = {}
            for _, record in pairs(records) do
                if type(record) == 'table' then
                    local named = ux.seedNameKey(record.name or record.display_name or record.named_name or '')
                    if named ~= '' then
                        importedKeysByName[named] = importedKeysByName[named] or {}
                        for _, point in ipairs(ux.seedRecordPoints(record)) do
                            if type(point) == 'table' then
                                local coords = type(point.coords) == 'table' and point.coords or {}
                                local x = tonumber(point.x) or tonumber(coords.x) or tonumber(coords[1])
                                local y = tonumber(point.y) or tonumber(coords.y) or tonumber(coords[2])
                                local pointKey = ux.pointKeyFromCoords(x, y)
                                if pointKey then importedKeysByName[named][pointKey] = true end
                            end
                        end
                    end
                    local namedCount, pointCount = ux.mergeAllaSeedRecord(zoneName, record, sourceText, mergeOpts)
                    if namedCount > 0 then
                        namedImported = namedImported + namedCount
                        pointsImported = pointsImported + pointCount
                        zoneHadData = true
                    end
                end
            end
            if zoneHadData then
                zonesImported = zonesImported + 1
                staleRemoved = staleRemoved + ux.cleanupAllaSeedForImport(zoneName, importedKeysByName, sourceText)
                seedWatches = seedWatches + ux.createAllaSeedWatchesForCurrentZone(zoneName, records, sourceText)
                staleWatches = staleWatches + ux.pruneStaleSeedWatches(zoneName, importedKeysByName)
                prunedPoint = prunedPoint + (ux.pruneRedundantSeedPointWatches(zoneName) or 0)
            end
    end

    if not quiet then
        importStatusMsg = 'Creating watches and merging PH links...'
        chat('Creating watches and merging PH links...')
    end
    respawnsDirty = true; ux.statsRevision = (ux.statsRevision or 0) + 1
    ux.zoneIntelCache = { at = 0, key = '', rows = {} }
    local repairedTimers = 0
    local repairedWatchMeta = 0
    for _, watch in pairs(watchList or {}) do
        if ux.watchAppliesToCurrentZone(watch)
            and not watch.isUp
            and (tonumber(watch.despawnedAt or 0) or 0) > 0 then
            local seconds, source = ux.effectiveRespawnSeconds(watch)
            if seconds and seconds > 0 then
                local expected = (tonumber(watch.despawnedAt) or os.time()) + seconds
                if (tonumber(watch.expectedRespawnAt or 0) or 0) <= 0
                    or math.abs((tonumber(watch.expectedRespawnAt or 0) or 0) - expected) > 2
                    or tostring(watch.expectedRespawnSource or '') ~= tostring(source or '') then
                    watch.expectedRespawnAt = expected
                    watch.expectedRespawnSource = source
                    repairedTimers = repairedTimers + 1
                end
            end
        end
        if ux.watchAppliesToCurrentZone(watch) then
            local zoneTable = respawnsData[currentZoneShort()]
            local points = zoneTable and zoneTable._points or nil
            local desired = ux.seedNameKey(watch.label or watch.desiredName or '')
            local pointEntry = nil
            if type(points) == 'table' and watch.lastSpawnPointKey and points[watch.lastSpawnPointKey] then
                pointEntry = points[watch.lastSpawnPointKey]
            end
            if type(points) == 'table' and type(pointEntry) ~= 'table' and desired ~= '' then
                for key, entry in pairs(points) do
                    if type(entry) == 'table' then
                        local named = ux.seedNameKey(entry.named_name or entry.display_name or '')
                        if named == desired then
                            pointEntry = entry
                            if not ux.watchHasPoint(watch) then
                                watch.lastSpawnPointKey = key
                                watch.lastX = entry.x
                                watch.lastY = entry.y
                                watch.lastZ = entry.z
                                watch.pointConfidence = 'trusted'
                                watch.pointSamples = math.max(tonumber(watch.pointSamples) or 0, MIN_SAMPLES_FOR_DISPLAY)
                            end
                            break
                        end
                    end
                end
            end
            -- Sync anchorRadius from seed data. Uses the point's explicit radius
            -- when present; otherwise the global seedWatchAnchorRadius default.
            -- This corrects watches imported with the old 30-unit default.
            if ux.watchIsSeedSourced(watch) then
                local seedR = ux.seedWatchAnchorRadius or 8
                local pointR = type(pointEntry) == 'table' and tonumber(pointEntry.anchor_radius) or 0
                watch.anchorRadius = pointR > 0 and pointR or seedR
            end
            if type(pointEntry) == 'table' then
                local seen = {}
                local merged = {}
                for _, name in ipairs(normalizeWatchNameList(watch.phNames or {})) do
                    seen[name:lower()] = true
                    table.insert(merged, name)
                end
                for _, name in ipairs(normalizeWatchNameList(pointEntry.ph_names or {})) do
                    local key = name:lower()
                    if key ~= '' and not seen[key] then
                        seen[key] = true
                        table.insert(merged, name)
                        repairedWatchMeta = repairedWatchMeta + 1
                    end
                end
                watch.phNames = merged
            end
        end
    end
    local mergedDupes = ux.collapseDuplicateSourceWatches()
    if prunedPoint > 0 and not quiet then
        chat(string.format('TurboMobs: merged %d duplicate camp watch(es) (placeholder kept on named only).', prunedPoint))
    end
    if ux.rebuildWatchIndex then ux.rebuildWatchIndex() end
    local cleanedPh = ux.sanitizeWatchPhNames and ux.sanitizeWatchPhNames() or 0
    if seedWatches > 0 or repairedTimers > 0 or repairedWatchMeta > 0 or mergedDupes > 0 or cleanedPh > 0 or staleWatches > 0 or prunedPoint > 0 then
        saveWatches()
        if ux.rebuildWatchIndex then ux.rebuildWatchIndex() end
        if ux.cacheSearchWatchedRows then ux.cacheSearchWatchedRows() end
    end
    -- Make freshly created/pruned watches show up immediately (no second click).
    ux.watchRowsCache = { at = 0, key = '', rows = {} }
    ux.watchDetailRowsCache = { at = 0, key = '', rows = {} }
    ux.zoneIntelCache = { at = 0, key = '', rows = {} }
    ux.watchBaselineReady = false
    ux.watchFullBaselinePending = true
    ux.zoneEntryRefreshPending = true
    lastWatchRefreshMs = 0
    lastSearchRefreshMs = 0
    lastRefreshMs = 0
    local msg = string.format('Alla seed import: %d zone(s), %d named, %d spawn point(s), %d seed watch(es), %d stale seed row(s) removed, %d stale seed watch(es) pruned, %d active timer(s) repaired, %d PH link(s) merged, %d duplicate watch(es) merged.', zonesImported, namedImported, pointsImported, seedWatches, staleRemoved, staleWatches, repairedTimers, repairedWatchMeta, mergedDupes)
    importStatusMsg = msg
    local importGeneratedAt = tostring((type(data._meta) == 'table' and data._meta.generated_at) or '')
    if importContext.autoBundled == true then
        ux.markBundledSeedImportComplete(importGeneratedAt)
        local timerNote = importTimers and ' Lazarus respawn timers included.' or ' Names and camps only; timers refine as you play.'
        chat(string.format('\\agTurboMobs:\\ax Loaded %d named camps from bundled seed data (%d zones).%s Watches auto-load as you zone.', namedImported, zonesImported, timerNote))
    elseif quiet then
        if seedWatches > 0 or staleWatches > 0 then
            chat(string.format('TurboMobs: auto-loaded seed watches for %s (%d added%s).', currentZoneShort(), seedWatches, staleWatches > 0 and (', ' .. staleWatches .. ' stale pruned') or ''))
        end
    else
        notify(msg)
        notify(string.format('Done. %d named now watched in %s. Zone in/out auto-loads other zones.', seedWatches, currentZoneShort()))
        if pointsImported > 0 then ux.markBundledSeedImportComplete(importGeneratedAt) end
    end
    local zoneNow = currentZoneShort()
    if tostring(ux.watchSeedAwaitingZone or ''):lower() == zoneNow then
        if ux.clearWatchSeedAwaiting then ux.clearWatchSeedAwaiting() end
    end
    ux.allaSeedImportInProgress = false
    ux.allaSeedImportStartedMS = 0
    return pointsImported > 0
end

ux.requestAllaImport = function(filenameOrPath, quiet, opts)
    local requestZone = currentZoneShort()
    local requestIdentity = ux.currentZoneRuntimeIdentity and ux.currentZoneRuntimeIdentity() or ''
    if ux.setWatchSeedAwaiting then ux.setWatchSeedAwaiting(requestZone) end
    opts = type(opts) == 'table' and opts or {}
    ux.pendingAllaImport = {
        filename = tostring(filenameOrPath or ''),
        requestedAt = nowMs(),
        zone = requestZone,
        zoneIdentity = requestIdentity,
        lastWaitChatAt = 0,
        quiet = quiet == true,
        autoBundled = opts.autoBundled == true,
        timerRepair = opts.timerRepair == true,
    }
    importStatusMsg = quiet and 'Loading zone seed watches...' or 'Alla seed import queued...'
    if not quiet then
        chat('Alla seed import queued. It runs when you stop moving/casting -- watches appear automatically when it finishes (no second click needed).')
    end
end

-- Once the player has imported seed data at least once, keep every zone's seed
-- watches current automatically: on the first visit to a zone this session,
-- quietly create its watches from the bundled per-zone seed. This makes a single
-- "Import All Zones" definitive -- zoning into any zone (including HC variants)
-- populates its watches without a manual "Import This Zone". Runs once per zone
-- per session; zones with no bundled seed are a quiet no-op.
ux.autoSeededZones = ux.autoSeededZones or {}
ux.autoSeedCurrentZone = function()
    if ux.seedAutoMaintain ~= true then return end
    if not ux.respawnsLoaded then return end
    local zone = currentZoneShort()
    if zone == '' or zone == 'unknown' then return end
    if ux.autoSeededZones[zone] then return end
    -- Safe hub zones don't need seed import; mark done so the UI never shows
    -- "Preparing zone watches..." in towns, nexus, PoK, etc.
    if ux.safeZoneScanPaused and ux.safeZoneScanPaused() then
        ux.autoSeededZones[zone] = true
        return
    end
    if ux.pendingAllaImport then return end
    -- Skip only if at least one seed-sourced watch already exists for this zone.
    -- Manual-only watches are not treated as a completed seed import, so players
    -- who add a few watches by hand before discovering "Import Zone" will still
    -- get the full seed on first zone-in this session.
    for _, watch in pairs(watchList or {}) do
        if type(watch) == 'table' and tostring(watch.zone or ''):lower() == zone then
            local src = tostring(watch.source or ''):lower()
            if src:find('alla', 1, true) or src:find('lazarus', 1, true) then
                ux.autoSeededZones[zone] = true
                return
            end
        end
    end
    local seedPath = ux.resolveAllaSeedPath and select(1, ux.resolveAllaSeedPath('', true)) or nil
    if not seedPath then
        ux.autoSeededZones[zone] = true
        if ux.clearWatchSeedAwaiting then ux.clearWatchSeedAwaiting() end
        importStatusMsg = 'No bundled seed for this zone.'
        return
    end
    ux.autoSeededZones[zone] = true
    if ux.setWatchSeedAwaiting then ux.setWatchSeedAwaiting(zone) end
    ux.requestAllaImport('', true)
end

ux.processPendingAllaImport = function()
    local pending = ux.pendingAllaImport
    if not pending then return end
    local pendingZone = tostring(pending.zone or ''):lower()
    local currentZone = currentZoneShort()
    if pending.quiet == true and pending.autoBundled ~= true
        and pendingZone ~= '' and pendingZone ~= currentZone then
        ux.clearSeedImportState('Seed import canceled after zoning.')
        return
    end
    -- Quiet auto-seed imports: force-run quickly regardless of gameplay state.
    -- Per-zone seeds are tiny; waiting on idle movement caused multi-minute
    -- "Loading seed watches..." in active dungeons.
    local elapsed = nowMs() - (tonumber(pending.requestedAt) or nowMs())
    local forceAfterMs = pending.autoBundled and 20000 or (pending.quiet and 5000 or 10000)
    local forceRun = pending.quiet and elapsed > forceAfterMs
    if not forceRun and ux.gameplayBusyForImport() then
        local now = os.time()
        if (tonumber(pending.lastWaitChatAt) or 0) <= 0 then
            pending.lastWaitChatAt = now
            importStatusMsg = 'Alla seed import queued; waiting for idle gameplay...'
            if pending.quiet ~= true then
                chat('Alla seed import waiting for idle gameplay.')
            end
        end
        return
    end
    importStatusMsg = 'Alla seed import processing...'
    ux.allaSeedImportStartedMS = nowMs()
    if pending.quiet ~= true then
        chat('Alla seed import processing...')
    end
    local filename = pending.filename or ''
    local quiet = pending.quiet == true
    local ok, err = pcall(function()
        ux.importAllaSeed(filename, quiet, { autoBundled = pending.autoBundled == true, timerRepair = pending.timerRepair == true })
    end)
    ux.pendingAllaImport = nil
    if not ok then
        ux.allaSeedImportInProgress = false
        ux.allaSeedImportStartedMS = 0
        local msg = 'Alla seed import failed: ' .. tostring(err)
        importStatusMsg = msg
        chat(msg)
        if ux.clearWatchSeedAwaiting then ux.clearWatchSeedAwaiting() end
    elseif ux.rebuildImportedRespawnLookup then
        ux.allaSeedImportStartedMS = 0
        ux.rebuildImportedRespawnLookup(currentZoneShort())
    end
end

ux.repairAllaSeedData = function(zoneOrAll)
    if not ux.ensureRespawnsLoaded('Alla repair') then return false end
    local target = trim(tostring(zoneOrAll or ''))
    if target == '' or target:lower() == 'current' then target = currentZoneShort() end
    local repairAll = target:lower() == 'all'
    local zonesMatched, zonesTouched, pointsTouched, namesPreserved, pointsScanned, seedPointsSeen = 0, 0, 0, 0, 0, 0
    for zoneKey, zoneTable in pairs(respawnsData or {}) do
        if zoneKey ~= '_meta' and type(zoneTable) == 'table' and (repairAll or tostring(zoneKey):lower() == target:lower()) then
            zonesMatched = zonesMatched + 1
            local zoneChanged = false
            local points = zoneTable._points
            if type(points) == 'table' then
                for _, entry in pairs(points) do
                    if type(entry) == 'table' then
                        pointsScanned = pointsScanned + 1
                        local source = tostring(entry.source or ''):lower()
                        local timerSource = tostring(entry.timer_source or ''):lower()
                        local sourceUrl = tostring(entry.source_url or ''):lower()
                        local isAllaSeed = tostring(entry.seed_confidence or ''):lower() == 'imported'
                            or source:find('alla', 1, true) ~= nil
                            or source:find('lazarus', 1, true) ~= nil
                            or timerSource:find('alla', 1, true) ~= nil
                            or timerSource:find('lazarus', 1, true) ~= nil
                            or sourceUrl:find('lazaruseq.com', 1, true) ~= nil
                        if isAllaSeed then
                            seedPointsSeen = seedPointsSeen + 1
                            local beforeCount = type(entry.seed_names) == 'table' and #entry.seed_names or 0
                            entry.seed_names = appendUniqueText(entry.seed_names, entry.named_name, 96)
                            if tostring(entry.category or ''):lower() == 'named' then
                                entry.seed_names = appendUniqueText(entry.seed_names, entry.display_name or entry.last_seen_name, 96)
                            end
                            local afterCount = type(entry.seed_names) == 'table' and #entry.seed_names or 0
                            namesPreserved = namesPreserved + math.max(0, afterCount - beforeCount)
                            if tostring(entry.category or ''):lower() ~= 'seed' then
                                entry.category = 'seed'
                                pointsTouched = pointsTouched + 1
                                zoneChanged = true
                            end
                            if entry.named_name ~= nil then
                                entry.named_name = nil
                                zoneChanged = true
                            end
                        end
                    end
                end
            end
            if zoneChanged then zonesTouched = zonesTouched + 1 end
        end
    end
    if zonesTouched > 0 then
        respawnsDirty = true; ux.statsRevision = (ux.statsRevision or 0) + 1
        saveRespawns(true)
        ux.zoneIntelCache = { at = 0, key = '', rows = {} }
    end
    local msg = string.format('Alla seed repair: %d matched zone(s), %d changed zone(s), %d scanned, %d seed point(s), %d point classification(s), %d seed name(s) preserved.', zonesMatched, zonesTouched, pointsScanned, seedPointsSeen, pointsTouched, namesPreserved)
    notify(msg)
    importStatusMsg = msg
    return zonesMatched > 0
end

ux.cleanupZoneIntelRawPoints = function(zoneKey)
    if not ux.ensureRespawnsLoaded('Zone Intel cleanup') then return 0 end
    zoneKey = tostring(zoneKey or currentZoneShort()):lower()
    local zoneTable = respawnsData and respawnsData[zoneKey] or nil
    local points = zoneTable and zoneTable._points or nil
    if type(points) ~= 'table' then
        notify('Zone Intel cleanup: no point data for ' .. zoneKey)
        return 0
    end
    local linkedPoints = {}
    for _, watch in pairs(watchList or {}) do
        if ux.watchAppliesToCurrentZone(watch) then
            local key = tostring(watch.lastSpawnPointKey or '')
            if key ~= '' then linkedPoints[key] = true end
        end
    end
    local removed, kept = 0, 0
    for key, entry in pairs(points) do
        if type(entry) == 'table' then
            if linkedPoints[key] or ux.pointIsAllaSeed(entry) then
                kept = kept + 1
            elseif ux.pointIsGenericTrashLearn(entry) then
                points[key] = nil
                removed = removed + 1
            else
                local sampleCount = type(entry.samples) == 'table' and #entry.samples or 0
                local hasTimer = (tonumber(entry.respawn_seconds) or tonumber(entry.imported_respawn_seconds) or 0) > 0
                if sampleCount >= MIN_SAMPLES_FOR_DISPLAY or hasTimer then
                    kept = kept + 1
                else
                    points[key] = nil
                    removed = removed + 1
                end
            end
        end
    end
    if removed > 0 then
        respawnsDirty = true; ux.statsRevision = (ux.statsRevision or 0) + 1
        saveRespawns(true)
        ux.zoneIntelCache = { at = 0, key = '', rows = {} }
        if ux.rebuildImportedRespawnLookup then ux.rebuildImportedRespawnLookup(zoneKey) end
    end
    local msg = string.format('Zone Intel cleanup: removed %d generic/stale point(s), kept %d seed/watch/named point(s).', removed, kept)
    notify(msg)
    importStatusMsg = msg
    return removed
end

ux.pruneStaleTrashPoints = function(zoneKey, opts)
    opts = type(opts) == 'table' and opts or {}
    if not ux.autoPruneTrashOnZoneEntry and opts.force ~= true then return 0 end
    if not ux.ensureRespawnsLoaded('Trash prune') then return 0 end
    zoneKey = tostring(zoneKey or currentZoneShort()):lower()
    if zoneKey == '' then return 0 end
    local zoneTable = respawnsData and respawnsData[zoneKey] or nil
    local points = zoneTable and zoneTable._points or nil
    if type(points) ~= 'table' then return 0 end
    local linkedPoints = {}
    for _, watch in pairs(watchList or {}) do
        if ux.watchAppliesToCurrentZone(watch) then
            local key = tostring(watch.lastSpawnPointKey or '')
            if key ~= '' then linkedPoints[key] = true end
        end
    end
    local pruneSec = math.max(1, tonumber(ux.learnTrashPruneDays) or 4) * 86400
    local now = os.time()
    local removed = 0
    for key, entry in pairs(points) do
        if type(entry) == 'table'
            and not linkedPoints[key]
            and ux.pointIsGenericTrashLearn(entry) then
            local lastSeen = tonumber(entry.last_seen) or tonumber(entry.first_seen) or 0
            if lastSeen <= 0 or (now - lastSeen) >= pruneSec then
                points[key] = nil
                removed = removed + 1
            end
        end
    end
    if removed > 0 then
        respawnsDirty = true
        ux.statsRevision = (ux.statsRevision or 0) + 1
        saveRespawns(true)
        ux.zoneIntelCache = { at = 0, key = '', rows = {} }
        if ux.rebuildImportedRespawnLookup then ux.rebuildImportedRespawnLookup(zoneKey) end
        if not opts.quiet then
            chat(string.format('TurboMobs: pruned %d stale trash spawn point(s) in %s.', removed, zoneKey))
        end
    end
    return removed
end

ux.listExportFiles = function(pattern)
    ensureFolder(exportsFolder)
    local out = {}
    local okFfi, ffi = pcall(require, 'ffi')
    if not okFfi then return out end
    if not _G.TurboMobsFindFileCdef then
        pcall(ffi.cdef, [[
            typedef void* HANDLE;
            typedef unsigned long DWORD;
            typedef int BOOL;
            typedef struct _FILETIME { DWORD dwLowDateTime; DWORD dwHighDateTime; } FILETIME;
            typedef struct _WIN32_FIND_DATAA {
                DWORD dwFileAttributes;
                FILETIME ftCreationTime;
                FILETIME ftLastAccessTime;
                FILETIME ftLastWriteTime;
                DWORD nFileSizeHigh;
                DWORD nFileSizeLow;
                DWORD dwReserved0;
                DWORD dwReserved1;
                char cFileName[260];
                char cAlternateFileName[14];
                DWORD dwFileType;
                DWORD dwCreatorType;
                unsigned short wFinderFlags;
            } WIN32_FIND_DATAA;
            HANDLE FindFirstFileA(const char* lpFileName, WIN32_FIND_DATAA* lpFindFileData);
            BOOL FindNextFileA(HANDLE hFindFile, WIN32_FIND_DATAA* lpFindFileData);
            BOOL FindClose(HANDLE hFindFile);
        ]])
        _G.TurboMobsFindFileCdef = true
    end

    local search = exportsFolder:gsub('/', '\\') .. '\\' .. tostring(pattern or '*.lua')
    local data = ffi.new('WIN32_FIND_DATAA[1]')
    local invalid = ffi.cast('HANDLE', -1)
    local handle = ffi.C.FindFirstFileA(search, data)
    if handle == invalid then return out end

    local bitlib = bit
    repeat
        local attrs = tonumber(data[0].dwFileAttributes) or 0
        local isDir = bitlib and bitlib.band(attrs, 0x10) ~= 0 or false
        local name = trim(ffi.string(data[0].cFileName))
        if name ~= '' and name ~= '.' and name ~= '..' and not isDir then
            table.insert(out, {
                name = name,
                hi = tonumber(data[0].ftLastWriteTime.dwHighDateTime) or 0,
                lo = tonumber(data[0].ftLastWriteTime.dwLowDateTime) or 0,
            })
        end
    until ffi.C.FindNextFileA(handle, data) == 0
    ffi.C.FindClose(handle)

    table.sort(out, function(a, b)
        if a.hi == b.hi then return a.lo > b.lo end
        return a.hi > b.hi
    end)
    for i, item in ipairs(out) do out[i] = item.name end
    return out
end

ux.latestExportFilename = function()
    local files = ux.listExportFiles('*.lua')
    return trim(files[1] or '')
end

ux.latestAllaSeedFilename = function()
    local files = ux.listExportFiles('alla_seed_*.lua')
    return trim(files[1] or '')
end

-- Read just the _meta of a share file (server / author / format) so the share
-- panel can show provenance and warn on a server mismatch. Results are cached
-- per filename; ux.shareMetaCache is cleared whenever the file list is rescanned.
ux.shareMetaCache = ux.shareMetaCache or {}
ux.peekShareMeta = function(filename)
    local key = trim(tostring(filename or ''))
    if key == '' then return nil end
    local cached = ux.shareMetaCache[key]
    if cached ~= nil then return cached end
    local meta = { server = '', exported_by = '', format = '', kind = 'respawns' }
    local path = exportsFolder .. '/' .. key
    if pathExists(path) then
        local ok, data = pcall(dofile, path)
        if ok and type(data) == 'table' and type(data._meta) == 'table' then
            meta.server = trim(tostring(data._meta.server or ''))
            meta.exported_by = trim(tostring(data._meta.exported_by or ''))
            meta.format = trim(tostring(data._meta.format or ''))
            if meta.format == 'TurboMobsAllaSeed' then meta.kind = 'alla' end
        end
    end
    ux.shareMetaCache[key] = meta
    return meta
end

-- In-window browser for exports/: one-click import with a visible server-mismatch
-- warning, so users don't have to type filenames or guess provenance.
ux.drawSharePanel = function()
    if ux.exportFileList == nil then ux.exportFileList = ux.listExportFiles() end
    local mine = currentServer()
    coloredText('Shared files in exports/', 'warn')
    ImGui.SameLine()
    if styledButton('Refresh##share_refresh', 'neutral', 6, 2, 'Re-scan the exports/ folder for share files.') then
        ux.exportFileList = ux.listExportFiles()
        ux.shareMetaCache = {}
    end
    local files = ux.exportFileList or {}
    if #files == 0 then
        coloredTextWrapped("No share files found. Export data below, or drop a friend's file into the exports/ folder and click Refresh.", 'muted')
        return
    end
    local flags = bit32.bor(ImGuiTableFlags.Borders, ImGuiTableFlags.RowBg, ImGuiTableFlags.ScrollY, ImGuiTableFlags.SizingStretchProp)
    local tableH = math.min(190, 30 + #files * 24)
    if ImGui.BeginTable('##tmobs_share_files', 4, flags, 0, tableH) then
        ImGui.TableSetupColumn('File', ImGuiTableColumnFlags.WidthStretch, 1.4)
        ImGui.TableSetupColumn('Server', ImGuiTableColumnFlags.WidthFixed, 104)
        ImGui.TableSetupColumn('By', ImGuiTableColumnFlags.WidthFixed, 84)
        ImGui.TableSetupColumn('##share_act', ImGuiTableColumnFlags.WidthFixed, 70)
        if ImGui.TableSetupScrollFreeze then ImGui.TableSetupScrollFreeze(0, 1) end
        ImGui.TableNextRow()
        ImGui.TableSetColumnIndex(0); ImGui.Text('File')
        ImGui.TableSetColumnIndex(1); ImGui.Text('Server')
        ImGui.TableSetColumnIndex(2); ImGui.Text('By')
        ImGui.TableSetColumnIndex(3); ImGui.Text('')
        for i, name in ipairs(files) do
            local meta = ux.peekShareMeta(name) or {}
            local mismatch = meta.server ~= '' and mine ~= '' and meta.server ~= mine
            ImGui.TableNextRow()
            ImGui.TableSetColumnIndex(0)
            local selected = (importInputFile == name)
            if ImGui.Selectable(shortText(name, 38) .. '##share_sel_' .. i, selected) then
                importInputFile = name
            end
            if ImGui.IsItemHovered() then
                ImGui.SetTooltip(name .. (meta.kind == 'alla' and '\n(Alla seed file)' or ''))
            end
            ImGui.TableSetColumnIndex(1)
            if meta.server == '' then
                coloredText('-', 'muted')
            elseif mismatch then
                coloredText(meta.server, 'stopped')
                if ImGui.IsItemHovered() then ImGui.SetTooltip('Different server than yours (' .. (mine ~= '' and mine or 'unknown') .. ').\nTimers may not apply.') end
            else
                coloredText(meta.server, 'learned')
            end
            ImGui.TableSetColumnIndex(2)
            ImGui.Text(meta.exported_by ~= '' and shortText(meta.exported_by, 12) or '-')
            ImGui.TableSetColumnIndex(3)
            local impColor = mismatch and 'warn' or 'primary'
            local impTip = mismatch
                and string.format('Import anyway. File is from server "%s"; you are on "%s". Data merges, but respawn timers may not match this server.', meta.server, mine ~= '' and mine or 'unknown')
                or 'Import and merge this file into your data.'
            if styledButton('Import##share_imp_' .. i, impColor, 4, 2, impTip) then
                if meta.kind == 'alla' then
                    ux.requestAllaImport(name)
                else
                    ux.importRespawns(name)
                end
                ux.exportFileList = nil
            end
        end
        ImGui.EndTable()
    end
    coloredText('Your server: ' .. (mine ~= '' and mine or 'unknown') .. ' (mismatched servers shown in red)', 'muted')
end

ux.spawnMasterPluginLoaded = function()
    local checks = {
        '${Plugin[MQ2SpawnMaster].Name}',
        '${Plugin[SpawnMaster].Name}',
    }
    for _, expr in ipairs(checks) do
        local ok, value = pcall(function() return mq.parse(expr) end)
        local text = tostring(ok and value or ''):lower()
        if text ~= '' and text ~= 'null' and text ~= 'false' then return true end
    end
    return false
end

ux.cleanSpawnMasterName = function(value)
    local text = trim(tostring(value or ''))
    if text == '' then return nil end
    text = text:gsub('^"', ''):gsub('"$', '')
    text = text:gsub('^%d+[%s,=]+', '')
    text = text:gsub('^Name%s*=%s*', '')
    text = trim(text)
    if text == '' or text:sub(1, 1) == '[' then return nil end
    return text
end

ux.spawnMasterSectionToZone = function(sectionName)
    sectionName = tostring(sectionName or ''):lower()
    sectionName = sectionName:gsub('^the%s+', '')
    sectionName = sectionName:gsub('%s+', ' ')
    sectionName = trim(sectionName)
    if sectionName == '' then return '' end
    return sectionName
end

ux.addSpawnMasterWatch = function(name, zoneName)
    name = trim(tostring(name or ''))
    zoneName = ux.spawnMasterSectionToZone(zoneName)
    if name == '' or zoneName == '' then return false, false end
    local key = ux.watchKeyExactForZone(name, zoneName)
    local existed = watchList[key] ~= nil
    watchList[key] = watchList[key] or {
        label = name,
        mode = 'exact',
        zone = zoneName,
        source = 'SpawnMaster',
        category = 'named',
        trackingMode = 'name',
        phNames = {},
        areaRadius = 0,
        spawnId = 0,
        respawnSeconds = 0,
        isUp = false,
        lastSeenAt = 0,
        despawnedAt = 0,
        killedAtText = '',
        expectedRespawnAt = 0,
        initialResolved = false,
    }
    local watch = watchList[key]
    watch.zone = zoneName
    watch.source = 'SpawnMaster'
    watch.category = watch.category or 'named'
    watch.trackingMode = watch.trackingMode or 'name'
    watch.phNames = normalizeWatchNameList(watch.phNames or {})
    return true, existed
end

ux.importSpawnMaster = function(allZones)
    local path = configRoot .. '/MQ2SpawnMaster.ini'
    if not pathExists(path) then
        chat('SpawnMaster import failed: ' .. path .. ' not found.')
        return false
    end

    local function normalizeZoneName(z)
        return ux.spawnMasterSectionToZone(z)
    end

    local zoneShort = currentZoneShort()
    local zoneLong = normalizeZoneName(safeCall(function() return mq.TLO.Zone.Name() end, zoneShort) or zoneShort)

    local function sectionMatchesCurrentZone(sectionName)
        sectionName = normalizeZoneName(sectionName)
        return sectionName == zoneShort or sectionName == zoneLong
    end

    local section = ''
    local imported, skipped, existing, zonesSeen = 0, 0, 0, 0
    local seen = {}

    for line in io.lines(path) do
        local header = line:match('^%s*%[([^%]]+)%]')
        if header then
            section = normalizeZoneName(header)
            if allZones and section ~= '' then zonesSeen = zonesSeen + 1 end
        elseif (allZones and section ~= '') or sectionMatchesCurrentZone(section) then
            local value = line:match('=%s*(.+)$') or line
            local name = ux.cleanSpawnMasterName(value)
            local importZone = allZones and section or zoneShort
            local seenKey = importZone .. ':' .. tostring(name or ''):lower()
            if name and not seen[seenKey] then
                seen[seenKey] = true
                local ok, existed = ux.addSpawnMasterWatch(name, importZone)
                if ok then
                    if existed then existing = existing + 1 else imported = imported + 1 end
                else
                    skipped = skipped + 1
                end
            end
        end
    end

    local mergedDupes = ux.collapseDuplicateSourceWatches()
    if ux.rebuildWatchIndex then ux.rebuildWatchIndex() end
    local cleanedPh = ux.sanitizeWatchPhNames and ux.sanitizeWatchPhNames() or 0
    saveWatches()
    ux.refreshWatchesNow({ suppressAlerts = true })

    local msg
    if allZones then
        msg = string.format('SpawnMaster import all zones: %d section(s), %d added, %d already existed, %d skipped.', zonesSeen, imported, existing, skipped)
    else
        msg = string.format('SpawnMaster import for %s: %d added, %d already existed, %d skipped.', zoneShort, imported, existing, skipped)
    end
    if mergedDupes > 0 then
        msg = msg .. string.format(' Merged %d into existing Alla seed watch(es).', mergedDupes)
    end
    chat(msg)
    importStatusMsg = msg
    return (imported + existing) > 0
end

-- ============================================================
-- Commands
-- ============================================================

-- Opens a local file-system path or folder with Windows Explorer.
ux.shellOpenExternal = function(target)
    target = tostring(target or '')
    if target == '' then return false end
    local okOpen, ShellOpen = pcall(require, 'Turbo.shell_open')
    if okOpen and ShellOpen and ShellOpen.shellOpenExternal then
        return ShellOpen.shellOpenExternal(target)
    end
    return false
end

ux.openConfigFolder = function()
    local winPath = turboFolder:gsub('/', '\\')
    notify('TurboMobs config folder: ' .. winPath)
    ensureFolder(turboFolder)
    ux.shellOpenExternal(winPath)
end

ux.openExportsFolder = function()
    local winPath = exportsFolder:gsub('/', '\\')
    notify('TurboMobs exports folder: ' .. winPath)
    ensureFolder(exportsFolder)
    ux.shellOpenExternal(winPath)
end

ux.commandQueue = ux.commandQueue or {}
ux.processingCommandQueue = false

ux.commandName = function(line)
    if type(line) == 'table' then line = line.line end
    local args = splitArgs(line)
    return string.lower(args[1] or '')
end

ux.commandLineFromArgs = function(...)
    local count = select('#', ...)
    local line = select(1, ...)
    if count > 1 then
        local parts = {}
        for i = 1, count do table.insert(parts, tostring(select(i, ...) or '')) end
        line = table.concat(parts, ' ')
    end
    line = trim(tostring(line or ''))
    line = line:gsub('^/?turbomobs%s*', '')
    line = line:gsub('^/?tmobs%s*', '')
    return trim(line)
end

ux.queueCommand = function(...)
    local line = ux.commandLineFromArgs(...)
    if ux.processCommandLine and not ux.processingCommandQueue then
        local ok, err = pcall(ux.processCommandLine, line)
        if not ok then chat('Command failed: ' .. tostring(err)) end
        return
    end
    table.insert(ux.commandQueue, { line = tostring(line or ''), queuedAt = nowMs() })
end

ux.quickCommand = function(cmd)
    return cmd == 'config' or cmd == 'exports' or cmd == 'exportfolder'
        or cmd == 'perf' or cmd == 'perflog' or cmd == 'exportperf'
        or cmd == 'diag' or cmd == 'diagnostic' or cmd == 'exportdiag'
end

ux.drainCommandQueue = function(quickOnly)
    if ux.processingCommandQueue then return end
    if #ux.commandQueue == 0 then return end
    ux.processingCommandQueue = true
    local remaining = {}
    for _, queued in ipairs(ux.commandQueue) do
        local cmd = ux.commandName(queued)
        if (not quickOnly) or ux.quickCommand(cmd) then
            if ux.processCommandLine then
                local delay = nowMs() - (tonumber(queued.queuedAt) or nowMs())
                if delay >= 100 then ux.recordPerfLine(string.format('Command /tmobs %s queued %dms', cmd ~= '' and cmd or '(restore)', delay)) end
                local ok, err = pcall(ux.processCommandLine, queued.line)
                if not ok then chat('Command failed: ' .. tostring(err)) end
            end
        else
            table.insert(remaining, queued)
        end
    end
    ux.commandQueue = remaining
    ux.processingCommandQueue = false
end

ux.pumpCommandEvents = function()
    mq.doevents()
    ux.drainCommandQueue(true)
end

ux.processCommandLine = function(line)
    local args = splitArgs(line)
    local cmd = string.lower(args[1] or '')

    if cmd == '' then
        ux.restorePrimaryWindow()
        return
    end

    if cmd ~= 'quit' and cmd ~= 'exit' then
        running = true
    end

    if cmd == 'show' then
        ux.showBothWindows()
    elseif cmd == 'full' then
        showWindow = true; compactMode = false; saveSettings()
    elseif cmd == 'togglefull' then
        ux.toggleFullMainWindow()
    elseif cmd == 'mini' or cmd == 'compact' or cmd == 'watchui' then
        ux.toggleWatchWindow()
    elseif cmd == 'hide' then
        ux.hideFullWindow()
    elseif cmd == 'on' then
        enabled = true; showWindow = true; ux.refreshWatchesNow(); saveSettings()
    elseif cmd == 'off' then
        enabled = false; saveSettings()
    elseif cmd == 'refresh' then
        ux.safeZoneScanOverride = true
        ux.refreshWatchesNow()
        if ux.liveSearch then ux.refreshSearchNow() end
    elseif cmd == 'navstop' or cmd == 'stopnav' then
        ux.stopNav()
        chat('Nav stopped.')
    elseif cmd == 'search' then
        local raw = tostring(line or ''):gsub('^%s*search%s*', '')
        searchText = trim(raw); ux.searchPage = 1; ux.refilterSearchRows()
    elseif cmd == 'clearsearch' or cmd == 'clear' then
        searchText = ''; ux.searchPage = 1; ux.refilterSearchRows()
    elseif cmd == 'clearfilters' then
        ux.clearSearchFilters()
    elseif cmd == 'named' then
        namedOnly = not namedOnly; ux.searchPage = 1; ux.refilterSearchRows(); saveSettings()
    elseif cmd == 'npc' then
        npcOnly = not npcOnly; ux.searchPage = 1; ux.refreshSearchNow({ suppressAlerts = true }); saveSettings()
    elseif cmd == 'targetable' then
        ux.targetableOnly = not ux.targetableOnly; ux.searchPage = 1; ux.refilterSearchRows(); saveSettings()
    elseif cmd == 'alerts' then
        ux.toggleWatchWindow()
    elseif cmd == 'watches' or cmd == 'details' then
        showAlertsPanel = not showAlertsPanel; ux.showMore = true; showWindow = true; compactMode = false; saveSettings()
    elseif cmd == 'config' then
        ux.openConfigFolder()
    elseif cmd == 'exports' or cmd == 'exportfolder' then
        ux.openExportsFolder()
    elseif cmd == 'perf' or cmd == 'perflog' or cmd == 'exportperf' then
        ux.exportPerfLog()
    elseif cmd == 'diag' or cmd == 'diagnostic' or cmd == 'exportdiag' then
        ux.exportDiagnostic()
    elseif cmd == 'help' then
        ux.showHelpPanel = true; showWindow = true; compactMode = false
    elseif cmd == 'statusvars' or cmd == 'vars' then
        echoCompatVars()
    elseif cmd == 'compat' then
        local mode = tostring(args[2] or ''):lower()
        if mode == 'on' then
            compatVarsEnabled = true
            saveSettings()
            updateTargetCompatVars()
            chat('Compatibility count vars enabled. Target vars remain ' .. (ux.targetCompatVarsEnabled and 'ON' or 'OFF') .. '.')
        elseif mode == 'off' then
            compatVarsEnabled = false
            ux.targetCompatVarsEnabled = false
            saveSettings()
            compatVarsEnabled = true
            updateTargetCompatVars()
            compatVarsEnabled = false
            chat('Compatibility vars disabled.')
        elseif mode == 'target' then
            ux.targetCompatVarsEnabled = not ux.targetCompatVarsEnabled
            saveSettings()
            updateTargetCompatVars()
            chat('Target compatibility vars are now ' .. (ux.targetCompatVarsEnabled and 'ON' or 'OFF') .. '.')
        elseif mode == 'spawnmaster' then
            spawnMasterCompat = not spawnMasterCompat
            if spawnMasterCompat then ux.targetCompatVarsEnabled = true end
            saveSettings()
            updateTargetCompatVars()
            chat('SpawnMaster compatibility alias is now ' .. (spawnMasterCompat and 'ON' or 'OFF') .. '.')
        else
            chat('Compatibility vars are ' .. (compatVarsEnabled and 'ON' or 'OFF') .. '. Target vars are ' .. (ux.targetCompatVarsEnabled and 'ON' or 'OFF') .. '. SpawnMaster alias is ' .. (spawnMasterCompat and 'ON' or 'OFF') .. '.')
            chat('Use: /tmobs compat on | off | target | spawnmaster')
            chat('E3 replacement: SpawnMaster=${SpawnMaster_HasTarget.Equal[TRUE]}')
        end
    elseif cmd == 'watch' then
        if args[2] then
            local name = table.concat(args, ' ', 2)
            addWatchByName(name)
        else
            addWatchFromCurrentTarget()
        end
    elseif cmd == 'edit' then
        local name = trim(table.concat(args, ' ', 2))
        local needle = name:lower()
        local foundKey = ''
        for key, watch in pairs(watchList or {}) do
            if needle == '' or tostring(watch.label or ''):lower() == needle or tostring(watch.desiredName or ''):lower() == needle then
                foundKey = key
                break
            end
        end
        if foundKey ~= '' then
            showWindow = true
            compactMode = false
            ux.openWatchEditor({ key = foundKey, watch = watchList[foundKey] })
        else
            chat('Watch not found. Usage: /tmobs edit <name>')
        end
    elseif cmd == 'export' then
        ux.exportRespawns(args[2])
    elseif cmd == 'import' then
        if not args[2] then chat('Usage: /tmobs import <filename>')
        else ux.importRespawns(table.concat(args, ' ', 2)) end
    elseif cmd == 'importalla' or cmd == 'alla' then
        local mode = tostring(args[2] or ''):lower()
        local function resolveAllaTarget(rawArg)
            local target = tostring(rawArg or '')
            local lowered = target:lower()
            if lowered == 'all' or lowered == 'manifest' or lowered == 'bundle' then
                return 'alla_seeds_all.lua'
            end
            return target
        end
        if mode == 'preview' or mode == 'check' or mode == 'validate' then
            ux.previewAllaSeed(resolveAllaTarget(args[3] and table.concat(args, ' ', 3) or ''))
        elseif mode == 'all' or mode == 'manifest' or mode == 'bundle' then
            ux.requestAllaImport('alla_seeds_all.lua')
        else
            ux.requestAllaImport(args[2] and table.concat(args, ' ', 2) or '')
        end
    elseif cmd == 'repairalla' or cmd == 'allarepair' then
        ux.repairAllaSeedData(args[2] and table.concat(args, ' ', 2) or '')
    elseif cmd == 'importspawnmaster' or cmd == 'spawnmaster' then
        local mode = tostring(args[2] or ''):lower()
        ux.importSpawnMaster(mode == 'all')
    elseif cmd == 'quit' or cmd == 'exit' then
        ux.stopNow()
    else
        chat('Unknown command. Try /tmobs help')
    end
end

ux.bindSlashCommand = function(name, handler)
    pcall(function() mq.unbind(name) end)
    local ok, err = pcall(function() mq.bind(name, handler) end)
    if not ok then chat('Bind failed ' .. tostring(name) .. ': ' .. tostring(err)) end
    return ok
end

ux.bindSlashCommand('/tmobs', function(...) ux.queueCommand(...) end)
ux.bindSlashCommand('/turbomobs', function(...) ux.queueCommand(...) end)
ux.bindSlashCommand('/tmobs2', function(...) ux.queueCommand(...) end)
ux.bindSlashCommand('/tmalla', function(...) ux.requestAllaImport(...) end)

-- ============================================================
-- UI: header, watch, full, panels
-- ============================================================

ux.drawMiniWatchSummary = function()
    local total, up, nextEta, nextLabel, nextWatch = watchSummary()
    if nextEta > 0 and nextLabel then
        local row = watchLocRow(nextWatch)
        coloredText(shortText(nextLabel, 18), 'learned')
        ImGui.SameLine()
        coloredText(formatEta(nextEta), etaColorKey(nextEta))
        if row then
            ImGui.SameLine()
            drawDirectionArrow(row, true)
            ImGui.SameLine()
            distanceText(row.distance)
        end
    else
        coloredText(string.format('Watches: %d/%d up', up, total), total > 0 and 'muted' or 'idle')
    end
end

ux.watchCategoryText = function(watch)
    local cat = tostring(watch and watch.category or 'normal')
    if cat == 'named' then return 'Named' end
    if cat == 'ground' then return 'Ground' end
    return 'Normal'
end

ux.watchAppliesToCurrentZone = function(watch)
    return not watch or not watch.zone or watch.zone == '' or watch.zone == currentZoneShort()
end

-- Rebuild live down-timers after a reload/update from the death times persisted
-- in respawns.lua (last_death). respawns.lua saves periodically and on shutdown,
-- so it survives "paste over the folder" updates even when watches.lua wasn't
-- re-saved between the kill and the reload. Only restores timers that are still
-- counting down (ETA in the future); already-respawned mobs are left for the
-- next scan to detect as up. Idempotent: skips watches that already have a timer.
ux.reconcileWatchTimersFromRespawns = function()
    if not ux.respawnsLoaded then return 0 end
    local zone = currentZoneShort()
    local zoneTable = respawnsData and respawnsData[zone]
    if type(zoneTable) ~= 'table' then return 0 end
    local points = zoneTable._points
    local now = os.time()
    local restored = 0
    for _, watch in pairs(watchList or {}) do
        if type(watch) == 'table'
            and ux.watchAppliesToCurrentZone(watch)
            and not watch.isUp
            and (tonumber(watch.despawnedAt or 0) or 0) <= 0 then
            local lastDeath = 0
            if type(points) == 'table' and watch.lastSpawnPointKey and points[watch.lastSpawnPointKey] then
                lastDeath = tonumber(points[watch.lastSpawnPointKey].last_death) or 0
            end
            if lastDeath <= 0 then
                local nameKey = tostring(watch.label or watch.desiredName or ''):lower()
                if nameKey ~= '' and type(zoneTable[nameKey]) == 'table' then
                    lastDeath = tonumber(zoneTable[nameKey].last_death) or 0
                end
            end
            if lastDeath > 0 then
                local seconds, source = ux.effectiveRespawnSeconds(watch)
                if seconds and seconds > 0 and (lastDeath + seconds) > now then
                    watch.despawnedAt = lastDeath
                    if not watch.killedAtText or watch.killedAtText == '' then
                        watch.killedAtText = os.date('%I:%M %p', lastDeath)
                    end
                    watch.expectedRespawnAt = lastDeath + seconds
                    watch.expectedRespawnSource = source
                    restored = restored + 1
                end
            end
        end
    end
    return restored
end

ux.watchVisibleInZoneView = function(watch)
    if not watch then return false end
    if ux.watchCurrentZoneOnly == false then return true end
    local zone = tostring(watch.zone or ''):lower()
    return zone == currentZoneShort()
end

ux.watchMatchesDetailZone = function(watch, row)
    if not watch then return false end
    local selected = tostring(ux.watchDetailZone or 'current'):lower()
    local zone = tostring(watch.zone or ''):lower()
    if selected == '' or selected == 'current' then
        return zone == currentZoneShort() or (zone == '' and row ~= nil)
    end
    if selected == 'all' then return true end
    return zone == selected
end

ux.watchZoneOptions = function()
    local seen = {}
    local out = {}
    for _, watch in pairs(watchList or {}) do
        local zone = tostring(watch.zone or ''):lower()
        if zone ~= '' and not seen[zone] then
            seen[zone] = true
            table.insert(out, zone)
        end
    end
    table.sort(out)
    return out
end

ux.setWatchDetailZone = function(zone)
    local selected = tostring(zone or 'current'):lower()
    if selected == '' then selected = 'current' end
    ux.watchDetailZone = selected
    ux.watchZonePickerOpen = false
    ux.watchDetailStatus = (selected == 'all') and 'Viewing: all zones'
        or (selected == 'current' and ('Viewing: current zone (' .. currentZoneShort() .. ')'))
        or ('Viewing: ' .. selected)
    saveSettings()
    if ImGui.CloseCurrentPopup then ImGui.CloseCurrentPopup() end
end

ux.cycleWatchDetailZone = function(delta)
    delta = tonumber(delta) or 1
    local options = {'current', 'all'}
    for _, zone in ipairs(ux.watchZoneOptions()) do
        if zone ~= 'current' and zone ~= 'all' then table.insert(options, zone) end
    end
    local selected = tostring(ux.watchDetailZone or 'current'):lower()
    local index = 1
    for i, zone in ipairs(options) do
        if zone == selected then index = i; break end
    end
    index = ((index - 1 + delta) % #options) + 1
    ux.setWatchDetailZone(options[index])
end

ux.watchDetailZoneLabel = function()
    local selected = tostring(ux.watchDetailZone or 'current'):lower()
    if selected == 'all' then return 'All Zones' end
    if selected == '' or selected == 'current' then return currentZoneShort() end
    return selected
end

ux.drawWatchZonePicker = function()
    local selected = tostring(ux.watchDetailZone or 'current'):lower()
    local zoneLabel = ux.watchDetailZoneLabel()
    if styledButton((ux.watchZonePickerOpen and 'Hide Zones: ' or 'Zone: ') .. zoneLabel .. '##watch_zone_picker', 'primary', 7, 3, 'Show saved watch zones.') then
        ux.watchZonePickerOpen = not ux.watchZonePickerOpen
    end
    ImGui.SameLine()
    if styledButton('Current##watch_zone_current_btn', (selected == '' or selected == 'current') and 'primary' or 'neutral', 7, 3, 'Show this zone only.') then ux.setWatchDetailZone('current') end
    ImGui.SameLine()
    if styledButton('All Zones##watch_zone_all_btn', selected == 'all' and 'primary' or 'neutral', 7, 3, 'Show watches from every saved zone.') then ux.setWatchDetailZone('all') end

    if not ux.watchZonePickerOpen then return end
    coloredText('Saved zones', 'muted')
    local count = 0
    for _, zone in ipairs(ux.watchZoneOptions()) do
        count = count + 1
        if count > 1 then ImGui.SameLine() end
        if styledButton(zone .. '##watch_zone_pick_' .. zone, selected == zone and 'primary' or 'neutral', 7, 3, 'Show watches saved for this zone.') then
            ux.setWatchDetailZone(zone)
        end
        if count % 4 == 0 then count = 0 end
    end
end

ux.labelLooksNamed = function(label)
    label = trim(tostring(label or ''))
    if label == '' then return false end
    local lower = label:lower()
    return label:match('^[A-Z]') ~= nil and not lower:match('^a ') and not lower:match('^an ')
end

ux.watchLooksNamed = function(entry)
    local watch = entry and entry.watch or nil
    local row = entry and entry.row or nil
    if not watch then return false end
    if watch.category == 'named' then return true end
    if watch.category == 'ground' then return false end
    if row and row.named then return true end
    if tostring(watch.source or '') == 'SpawnMaster' then return true end
    return ux.labelLooksNamed(watch.label)
end

ux.watchIsGround = function(entry)
    local watch = entry and entry.watch or nil
    local row = entry and entry.row or nil
    if watch and watch.category == 'ground' then return true end
    if not row then return false end
    local typ = tostring(row.type or ''):lower()
    local body = tostring(row.body or ''):lower()
    return typ == 'item' or body == 'item' or typ == 'ground item'
end

-- Delegated to turbomobs_logic (pure, tested). Identical to the original.
ux.watchHasKnownPhNames = TM.watchHasKnownPhNames

-- Turbo Watch popup: timers, N/PH UP, Camp, and user-added Manual watches (shown as Watch).
-- Other grey Down seed rows stay in the full Watches tab only.
ux.currentZoneWatchCount = function()
    local _, zoneWatches = ux.currentZoneWatchPairs()
    return #(zoneWatches or {})
end

ux.watchIsUserTracked = function(entry)
    local watch = entry and entry.watch
    if not watch then return false end
    local source = tostring(watch.source or '')
    return source == 'Manual' or source == 'Manual PH'
end

ux.watchEntryActiveForPopup = function(entry)
    if not entry or not entry.watch then return false end
    if ux.watchIsUserTracked(entry) then return true end
    if ux.watchHasLiveEvidence(entry) then return true end
    if ux.watchHasSessionTimer(entry.watch) then
        if ux.watchSessionTimerExpired(entry.watch) then
            return ux.watchIsCampCheckable(entry)
        end
        return TM.watchTimerVisible(entry.watch.expectedRespawnAt, os.time(), ux.watchHideKnownTimersUntilSoon, ux.watchTimerSoonSeconds)
            and not (ux.watchDueIsStale and ux.watchDueIsStale(entry.watch))
    end
    if ux.watchShowUnknown == true then return true end
    return false
end

-- Split live spawn match (named row) vs true placeholder (PH at camp).
ux.resolveWatchDisplayRows = function(watch, key)
    local row = ux.cachedFindWatchRow(watch, key)
    local offAnchorRow = nil
    if not row then
        offAnchorRow = ux.liveOffAnchorNamedRow and ux.liveOffAnchorNamedRow(watch) or nil
        if offAnchorRow then row = offAnchorRow end
    end
    local occupant = nil
    if not row then
        occupant = ux.cachedWatchOccupantRow and ux.cachedWatchOccupantRow(watch, key) or ux.watchPointOccupiedRow(watch, key)
        if occupant and ux.rowIsDesiredForWatch(watch, occupant) then
            row = occupant
            occupant = nil
        end
    end
    local placeholderRow = nil
    if not row and occupant then
        -- A freshly discovered occupant (occupantSpawnId == 0) must pass camp PH
        -- checks so zone-wide same-name trash does not claim every seeded camp.
        local occupantId = tonumber(watch.occupantSpawnId or 0) or 0
        local isIdConfirmed = occupantId > 0
            and ux.spawnIndex and ux.spawnIndex.byId
            and ux.spawnIndex.byId[occupantId] == occupant
        if isIdConfirmed or ux.rowCountsAsWatchCampPh(watch, occupant, { allowStickyPull = true, allowRoamingPh = true }) then
            placeholderRow = occupant
        end
    end
    if not row and not placeholderRow then
        local roamingPh = ux.liveRoamingPhRow and ux.liveRoamingPhRow(watch) or nil
        if roamingPh then placeholderRow = roamingPh end
    end
    if not row and not placeholderRow and watch.pointOccupied == true
        and watch.occupantConfirmedAtAnchor == true
        and (tonumber(watch.occupantSpawnId or 0) or 0) > 0 then
        local sticky = ux.resolveStickyWatchOccupant and ux.resolveStickyWatchOccupant(watch) or nil
        if sticky then
            if ux.rowIsDesiredForWatch(watch, sticky) then
                row = sticky
            else
                placeholderRow = sticky
            end
        end
    end
    return row, placeholderRow, offAnchorRow
end

ux.buildWatchRows = function(optsOrIncludeAll)
    local opts
    if type(optsOrIncludeAll) == 'table' then
        opts = optsOrIncludeAll
    else
        opts = { includeAll = optsOrIncludeAll == true }
    end
    local includeAll = opts.includeAll == true
    if tostring(opts.cacheScope or 'popup') == 'popup' then
        includeAll = false
    end
    local sortState = opts.sortState or ux.watchPopupSort or {}
    local cacheScope = tostring(opts.cacheScope or 'popup')
    local statusFilter = tostring(opts.statusFilter or '')
    local zoneScope = tostring(opts.zoneScope or ''):lower()
    if zoneScope == '' then
        zoneScope = ux.watchCurrentZoneOnly ~= false and 'current' or 'all'
    end
    local requireDetailZone = opts.requireDetailZone == true

    local tStart = nowMs()
    local watchCount = tableCount(watchList)
    local currentKeys, currentWatches = ux.currentZoneWatchPairs()
    local tPairs = nowMs()
    local cacheKey = table.concat({
        cacheScope,
        currentZoneShort(),
        includeAll and '1' or '0',
        ux.watchNamedOnly and '1' or '0',
        ux.watchCurrentZoneOnly and '1' or '0',
        ux.watchIncludeGround and '1' or '0',
        zoneScope,
        statusFilter,
        tostring(sortState.mode or 'default'),
        sortState.asc and '1' or '0',
        tostring(#allSpawns),
        tostring(watchCount),
        tostring(ux.spawnDataRevision or 0),
        tostring(ux.watchGeneration or 0),
        ux.watchBaselineReady and '1' or '0',
        tostring(math.floor(os.time() / 60)),
    }, '|')
    local cache = ux.watchRowsCache
    if type(cache) ~= 'table' or cache.key ~= nil or cache.rows ~= nil then
        cache = {}
    end
    ux.watchRowsCache = cache
    local nowValue = nowMs()
    local cachedRows = cache[cacheKey]
    if cachedRows and cachedRows.rows then
        ux.lastWatchRowsTimingText = string.format(
            'WatchRows cache=hit rows=%d pairs=%d allSpawns=%d watches=%d rev=%s gen=%s scope=%s',
            #(cachedRows.rows or {}), #(currentWatches or {}), #allSpawns, watchCount,
            tostring(ux.spawnDataRevision or 0), tostring(ux.watchGeneration or 0), cacheScope)
        return cachedRows.rows
    end
    local rows = {}
    local sourceKeys, sourceWatches = {}, {}
    if zoneScope == 'current' or zoneScope == '' then
        sourceKeys, sourceWatches = currentKeys or {}, currentWatches or {}
    elseif zoneScope == 'all' then
        for key, watch in pairs(watchList or {}) do
            table.insert(sourceKeys, key)
            table.insert(sourceWatches, watch)
        end
    else
        for key, watch in pairs(watchList or {}) do
            local z = tostring(watch.zone or ''):lower()
            if zoneScope == z or (z == '' and zoneScope == currentZoneShort()) then
                table.insert(sourceKeys, key)
                table.insert(sourceWatches, watch)
            end
        end
    end
    for i, watch in ipairs(sourceWatches) do
        local key = sourceKeys[i]
        local row, placeholderRow, offAnchorRow = ux.resolveWatchDisplayRows(watch, key)
        local poolBlockRow = ux.resolvePoolBlockRow and ux.resolvePoolBlockRow(watch) or nil
        if requireDetailZone and not ux.watchMatchesDetailZone(watch, row) then goto continue_row end
        local zone = tostring(watch.zone or ''):lower()
        local zoneVisible
        if zoneScope ~= 'current' and zoneScope ~= '' then
            zoneVisible = true
        else
            zoneVisible = ux.watchCurrentZoneOnly == false
                or zone == currentZoneShort()
                or (zone == '' and row ~= nil)
        end
        if zoneVisible then
            local dueSoon = (not watch.isUp) and tonumber(watch.expectedRespawnAt or 0) > 0
            local entry = { key = key, watch = watch, row = row, placeholderRow = placeholderRow, offAnchorRow = offAnchorRow, poolBlockRow = poolBlockRow }
            local showByStatus
            if cacheScope == 'popup' then
                showByStatus = ux.watchEntryActiveForPopup(entry)
            else
                showByStatus = includeAll or watch.isUp or dueSoon or (ux.watchShowUnknown == true and cacheScope ~= 'popup')
            end
            if statusFilter == 'up' then
                showByStatus = watch.isUp == true
            elseif statusFilter == 'down' then
                showByStatus = watch.isUp ~= true
            elseif statusFilter == 'named' then
                showByStatus = ux.watchLooksNamed(entry)
            elseif statusFilter == 'ground' then
                showByStatus = ux.watchIsGround(entry)
            end
            local showByNamed = (not ux.watchNamedOnly) or ux.watchLooksNamed(entry)
            local showByGround = ux.watchIncludeGround or not ux.watchIsGround(entry)
            if showByStatus and showByNamed and showByGround then
                table.insert(rows, entry)
            end
        end
        ::continue_row::
    end
    local tRows = nowMs()
    if ux.sortWatchEntries then ux.sortWatchEntries(rows, sortState) end
    if cacheScope == 'popup' then
        rows = ux.collapseWatchEntriesToNearestCamps(rows, 1)
    elseif tonumber(ux.watchPopupMaxCampsPerLabel) and tonumber(ux.watchPopupMaxCampsPerLabel) > 0 then
        rows = ux.collapseWatchEntriesToNearestCamps(rows, tonumber(ux.watchPopupMaxCampsPerLabel))
    end
    local tSort = nowMs()
    local cacheCount = 0
    for _ in pairs(cache) do
        cacheCount = cacheCount + 1
        if cacheCount > 32 then
            for k in pairs(cache) do cache[k] = nil end
            break
        end
    end
    cache[cacheKey] = { at = nowValue, rows = rows }
    local elapsed = nowMs() - tStart
    ux.lastWatchRowsTimingText = string.format(
        'WatchRows cache=miss total=%d pairs=%d rows=%d sort=%d source=%d out=%d allSpawns=%d watches=%d scope=%s filter=%s rev=%s gen=%s',
        elapsed, tPairs - tStart, tRows - tPairs, tSort - tRows, #sourceWatches, #rows, #allSpawns, watchCount,
        cacheScope, statusFilter ~= '' and statusFilter or 'popup',
        tostring(ux.spawnDataRevision or 0), tostring(ux.watchGeneration or 0))
    ux.recordSlowPerf('watchRows', string.format(
        'WatchRows total=%dms pairs=%d rows=%d sort=%d out=%d allSpawns=%d watches=%d scope=%s',
        elapsed, tPairs - tStart, tRows - tPairs, tSort - tRows, #rows, #allSpawns, watchCount, cacheScope),
        elapsed, 8, 1000)
    return rows
end

ux.placeWatchWindowTopRight = function(width, height)
    local ok, io = pcall(ImGui.GetIO)
    if not ok or not io or not io.DisplaySize then return end
    local ds = io.DisplaySize
    local sw = tonumber(ds.x) or 0
    if sw <= 0 then return end
    local x = math.max(0, sw - (tonumber(width) or 420) - 12)
    local y = 28
    pcall(function() ImGui.SetNextWindowPos(x, y, ImGuiCond.Appearing or ImGuiCond.FirstUseEver) end)
end

-- Sort watch rows (Turbo Watch + Watches tab). sortState.mode 'default' matches former ordering.
ux.sortWatchEntries = function(entries, sortState)
    if not entries or #entries == 0 then return end
    local mode = sortState.mode or 'default'
    local asc = sortState.asc ~= false

    local function distK(entry)
        local r = entry.row
        if r and tonumber(r.distance) ~= nil then return tonumber(r.distance) end
        local lr = watchLocRow(entry.watch)
        return (lr and tonumber(lr.distance)) or 999999
    end

    local function degK(entry)
        local r = entry.row
        if r and tonumber(r.directionDegrees) ~= nil then return tonumber(r.directionDegrees) end
        local lr = watchLocRow(entry.watch)
        return (lr and tonumber(lr.directionDegrees)) or 0
    end

    local function samplesK(entry)
        local st = statsForMob(entry.watch.label, nil, entry.watch.lastSpawnPointKey)
        return st and tonumber(st.n) or 0
    end

    local function etaTs(watch)
        if watch.isUp then return -1e18 end
        local e = tonumber(watch.expectedRespawnAt or 0) or 0
        if e > 0 then return e end
        return 1e18
    end

    local function statusPri(watch)
        if watch.isUp then return 0 end
        if (tonumber(watch.expectedRespawnAt or 0) or 0) > 0 then return 1 end
        return 2
    end

    local function cmpNum(av, bv)
        if av ~= bv then
            if asc then return av < bv end
            return av > bv
        end
        return nil
    end

    local function nameLess(a, b)
        local na, nb = tostring(a.watch.label or ''):lower(), tostring(b.watch.label or ''):lower()
        if na ~= nb then
            if asc then return na < nb end
            return na > nb
        end
        return nil
    end

    -- Default-view tier order (ascending = top of list):
    --   0  N UP - named is alive right now
    --   1  PH UP - placeholder occupying the spawn point
    --   2  Camp - known camp is due to be checked
    --   3  Unknown - only when unknown watches are enabled
    --   4  Countdown timer running, soonest ETA first
    local function defaultTier(entry)
        local w = entry.watch
        local hasTimer = (not w.isUp) and (tonumber(w.expectedRespawnAt or 0) or 0) > 0
        local state = ux.watchState and ux.watchState(entry) or {}
        return TM.watchDefaultSortTier(state.state, state.kind, hasTimer, ux.watchShowUnknown == true)
    end

    table.sort(entries, function(a, b)
        local wa, wb = a.watch, b.watch
        if mode == 'default' then
            local ta, tb = defaultTier(a), defaultTier(b)
            if ta ~= tb then return ta < tb end
            local ae, be = tonumber(wa.expectedRespawnAt or 0) or 0, tonumber(wb.expectedRespawnAt or 0) or 0
            if ae > 0 and be > 0 and ae ~= be then return ae < be end
            if ae > 0 and be == 0 then return true end
            if be > 0 and ae == 0 then return false end
            return tostring(wa.label or ''):lower() < tostring(wb.label or ''):lower()
        end

        local av, bv
        local r
        if mode == 'name' then
            r = nameLess(a, b); if r ~= nil then return r end
            return false
        elseif mode == 'status' then
            av, bv = statusPri(wa), statusPri(wb)
            r = cmpNum(av, bv); if r ~= nil then return r end
            r = nameLess(a, b); if r ~= nil then return r end
            return false
        elseif mode == 'eta' then
            av, bv = etaTs(wa), etaTs(wb)
            r = cmpNum(av, bv); if r ~= nil then return r end
            r = nameLess(a, b); if r ~= nil then return r end
            return false
        elseif mode == 'dist' then
            av, bv = distK(a), distK(b)
            r = cmpNum(av, bv); if r ~= nil then return r end
            r = nameLess(a, b); if r ~= nil then return r end
            return false
        elseif mode == 'dir' then
            av, bv = degK(a), degK(b)
            r = cmpNum(av, bv); if r ~= nil then return r end
            r = nameLess(a, b); if r ~= nil then return r end
            return false
        elseif mode == 'samples' then
            av, bv = samplesK(a), samplesK(b)
            r = cmpNum(av, bv); if r ~= nil then return r end
            r = nameLess(a, b); if r ~= nil then return r end
            return false
        end
        return false
    end)
end

ux.watchSortHeader = function(columnIndex, label, modeKey, sortState, idSuffix)
    ImGui.TableSetColumnIndex(columnIndex)
    local text = label
    if sortState.mode == modeKey then text = text .. (sortState.asc and ' ^' or ' v') end
    if ImGui.Selectable(text .. '##wsh_' .. (idSuffix or 'w') .. '_' .. modeKey, false) then
        if sortState.mode == modeKey then sortState.asc = not sortState.asc
        else sortState.mode = modeKey; sortState.asc = true end
    end
end

ux.zoneIntelSortHeader = function(columnIndex, label, modeKey, sortState)
    ImGui.TableSetColumnIndex(columnIndex)
    local text = label
    if sortState.mode == modeKey then text = text .. (sortState.asc and ' ^' or ' v') end
    if ImGui.Selectable(text .. '##zish_' .. modeKey, false) then
        if sortState.mode == modeKey then sortState.asc = not sortState.asc
        else sortState.mode = modeKey; sortState.asc = true end
        ux.zoneIntelPage = 1
    end
end

ux.sortZoneIntelRows = function(rows, sortState)
    if not rows or #rows == 0 then return end
    local mode = sortState.mode or 'default'
    local asc = sortState.asc ~= false

    local function locRowOf(intel)
        return intel.liveRow or watchLocRow({
            lastX = intel.entry.x,
            lastY = intel.entry.y,
            lastZ = intel.entry.z,
            label = intel.entry.display_name or intel.entry.last_seen_name,
        })
    end

    local function nameKey(intel)
        return tostring(intel.entry.display_name or intel.entry.last_seen_name or intel.key or ''):lower()
    end

    local function avgKey(intel)
        local st = intel.stats
        if st and st.n >= MIN_SAMPLES_FOR_DISPLAY then return st.avg end
        return math.huge
    end

    local function confKey(intel)
        local n = intel.stats and intel.stats.n or 0
        if n >= MIN_SAMPLES_FOR_DISPLAY then return 0 end
        if n > 0 then return 1 end
        return 2
    end

    local function cmpNum(av, bv)
        if av ~= bv then
            if asc then return av < bv end
            return av > bv
        end
        return nil
    end

    table.sort(rows, function(a, b)
        if mode == 'default' then
            local la, lb = a.liveRow ~= nil, b.liveRow ~= nil
            if la ~= lb then return la end
            local an, bn = a.stats and a.stats.n or 0, b.stats and b.stats.n or 0
            if an ~= bn then return an > bn end
            return nameKey(a) < nameKey(b)
        end

        local av, bv
        local r
        if mode == 'name' then
            local na, nb = nameKey(a), nameKey(b)
            if na ~= nb then
                if asc then return na < nb end
                return na > nb
            end
            return false
        elseif mode == 'status' then
            local order = { ['N UP'] = 0, ['NAMED UP'] = 0, ['PH UP'] = 1, UP = 2, Down = 3, Empty = 4 }
            local sa = ux.zoneIntelState and (select(1, ux.zoneIntelState(a))) or (a.liveRow and 'UP' or 'Down')
            local sb = ux.zoneIntelState and (select(1, ux.zoneIntelState(b))) or (b.liveRow and 'UP' or 'Down')
            av = order[sa] or 9
            bv = order[sb] or 9
            r = cmpNum(av, bv); if r ~= nil then return r end
            return nameKey(a) < nameKey(b)
        elseif mode == 'avg' then
            av, bv = avgKey(a), avgKey(b)
            r = cmpNum(av, bv); if r ~= nil then return r end
            return nameKey(a) < nameKey(b)
        elseif mode == 'samples' then
            av, bv = (a.stats and a.stats.n or 0), (b.stats and b.stats.n or 0)
            r = cmpNum(av, bv); if r ~= nil then return r end
            return nameKey(a) < nameKey(b)
        elseif mode == 'last_seen' then
            av, bv = tonumber(a.entry.last_seen) or 0, tonumber(b.entry.last_seen) or 0
            r = cmpNum(av, bv); if r ~= nil then return r end
            return nameKey(a) < nameKey(b)
        elseif mode == 'confidence' then
            av, bv = confKey(a), confKey(b)
            r = cmpNum(av, bv); if r ~= nil then return r end
            return nameKey(a) < nameKey(b)
        elseif mode == 'dist' then
            local lrA, lrB = locRowOf(a), locRowOf(b)
            av = lrA and tonumber(lrA.distance) or 999999
            bv = lrB and tonumber(lrB.distance) or 999999
            r = cmpNum(av, bv); if r ~= nil then return r end
            return nameKey(a) < nameKey(b)
        elseif mode == 'dir' then
            local lrA, lrB = locRowOf(a), locRowOf(b)
            av = lrA and tonumber(lrA.directionDegrees) or 0
            bv = lrB and tonumber(lrB.directionDegrees) or 0
            r = cmpNum(av, bv); if r ~= nil then return r end
            return nameKey(a) < nameKey(b)
        end
        return false
    end)
end

ux.watchTooltipText = function(entry)
    local watch = entry.watch or {}
    local row = entry.row
    local placeholder = entry.placeholderRow or (ux.cachedWatchOccupantRow and ux.cachedWatchOccupantRow(watch, entry.key) or ux.watchOccupantRow(watch, entry.key))
    local stats = statsForMob(watch.label, nil, watch.lastSpawnPointKey)
    local trackText = (select(1, ux.watchTrackText(entry))) or 'Name'
    local statusText = (select(1, ux.watchDisplayStatus(entry))) or '-'
    local lines = {}
    table.insert(lines, tostring(watch.label or entry.key))
    table.insert(lines, tostring(trackText) .. ' watch')
    table.insert(lines, 'Status: ' .. statusText)
    table.insert(lines, 'Current: ' .. ux.watchCurrentText(entry, 28))
    if row then
        table.insert(lines, string.format('Nearby: %.0fm %s', tonumber(row.distance) or 0, ux.directionLabel(row)))
    elseif placeholder then
        table.insert(lines, string.format('Current PH: %s at %.0fm', tostring(placeholder.name or '-'), tonumber(placeholder.distance) or 0))
    elseif ux.watchHasPoint(watch) then
        table.insert(lines, 'Point empty or out of scan range.')
    else
        table.insert(lines, 'Name alert until the named is seen or a PH is assigned.')
    end
    local knownNames = ux.pointNamesText(watch, 6)
    if knownNames ~= '' then table.insert(lines, 'Seen here: ' .. knownNames) end
    if not ux.watchHasPoint(watch) and watch.lastX and watch.lastY then
        table.insert(lines, string.format('Last loc: %.1f, %.1f, %.1f', tonumber(watch.lastX) or 0, tonumber(watch.lastY) or 0, tonumber(watch.lastZ) or 0))
    end
    local phText = ux.watchNameListText(watch.phNames or {}):gsub('\n', ', ')
    if phText ~= '' then table.insert(lines, 'PH names: ' .. phText) end
    if ux.watchTrackingMode(watch) == 'area' then
        table.insert(lines, 'Area radius: ' .. tostring(watch.areaRadius or 0))
    end
    if (tonumber(watch.respawnSeconds) or 0) > 0 then
        table.insert(lines, 'Manual respawn: ' .. formatSeconds(watch.respawnSeconds))
    elseif stats and stats.n >= MIN_SAMPLES_FOR_DISPLAY then
        table.insert(lines, string.format('Avg respawn: %s (%d samples)', formatSeconds(stats.avg), tonumber(stats.n) or 0))
    elseif stats and stats.n > 0 then
        table.insert(lines, string.format('Observed respawn: %s (%d/%d samples)', formatSeconds(stats.avg), tonumber(stats.n) or 0, MIN_SAMPLES_FOR_DISPLAY))
    else
        local imported, importedSource = ux.importedRespawnSeconds(watch)
        if imported and imported > 0 then
            table.insert(lines, 'Catalogued respawn: ' .. formatSeconds(imported) .. ' (' .. tostring(importedSource or 'imported') .. ', named timer)')
        elseif stats then
            table.insert(lines, string.format('Learning timer: %d/%d samples', tonumber(stats.n) or 0, MIN_SAMPLES_FOR_DISPLAY))
        else
            table.insert(lines, string.format('Learning timer: 0/%d samples', MIN_SAMPLES_FOR_DISPLAY))
        end
    end
    if entry.placeholderRow and not row then
        table.insert(lines, 'PH up on point')
    elseif ux.watchHasPoint(watch) and not row and not placeholder then
        table.insert(lines, 'Point tracked, desired not up')
    elseif not ux.watchHasPoint(watch) then
        table.insert(lines, 'Name watch (no point yet)')
    end
    for _, alertLine in ipairs(ux.recentAlertsForWatch(watch.label)) do
        table.insert(lines, 'Recent: ' .. shortText(alertLine, 72))
    end
    table.insert(lines, 'Left-click targets. Right-click actions. Click Nav to navigate.')
    return table.concat(lines, '\n')
end

ux.drawWatchTooltip = function(entry)
    if not entry then return end
    if not ImGui.BeginTooltip then
        ImGui.SetTooltip(ux.tooltipText(ux.watchTooltipText(entry)))
        return
    end
    ImGui.BeginTooltip()
    local lineNo = 0
    for line in tostring(ux.watchTooltipText(entry) or ''):gmatch('[^\n]+') do
        lineNo = lineNo + 1
        if lineNo == 1 then
            local row = entry.row or entry.placeholderRow
            if row then conColoredText(line, row.level)
            else coloredText(line, 'selected') end
        else
            local color = 'idle'
            if line:find('^Status:') then
                if line:find('N UP') or line:find('NAMED UP') then color = 'alertUp'
                elseif line:find('PH UP') or line:find('due') then color = 'etaSoon'
                elseif line:find('Down') then color = 'alertDown'
                else color = 'muted' end
            elseif line:find('^Point confidence:') or line:find('respawn:') or line:find('Learning timer:') then
                color = 'learned'
            elseif line:find('^Current PH:') or line:find('^Seen here:') then
                color = 'etaSoon'
            elseif line:find('Name alert') or line:find('Left%-click targets') then
                color = 'selected'
            elseif line:find('empty') or line:find('Learning') then
                color = 'muted'
            end
            coloredText(line, color)
        end
    end
    ImGui.EndTooltip()
end

-- Watch display predicates (status, ETA, Camp): thin ux wrappers that gather
-- live evidence and delegate to turbomobs_logic. effectiveRespawnSeconds is a
-- thunk (only paid on the branch that needs it). No new main-chunk locals are
-- added here -- this file runs near LuaJIT's 200-local limit.
ux.watchHasLiveEvidence = function(entry)
    if not entry then return false end
    return TM.watchHasLiveEvidence(entry.watch or {}, {
        hasRow = entry.row ~= nil,
        hasOffAnchorNamed = entry.offAnchorRow ~= nil,
        hasPlaceholderRow = entry.placeholderRow ~= nil,
        hasRoamingPh = entry.roamingPhRow ~= nil,
    })
end

ux.watchHasSessionTimer = TM.watchHasSessionTimer

ux.watchSessionTimerExpired = function(watch)
    return TM.watchSessionTimerExpired(watch, {
        now = os.time(),
        respawnSeconds = function() return (select(1, ux.effectiveRespawnSeconds(watch or {}))) end,
    })
end

ux.watchIsCampCheckable = function(entry)
    if not entry or not entry.watch then return false end
    local watch = entry.watch
    return TM.watchIsCampCheckable(watch, {
        hasRow = entry.row ~= nil,
        hasOffAnchorNamed = entry.offAnchorRow ~= nil,
        hasPlaceholderRow = entry.placeholderRow ~= nil,
        hasRoamingPh = entry.roamingPhRow ~= nil,
        now = os.time(),
        respawnSeconds = function() return (select(1, ux.effectiveRespawnSeconds(watch))) end,
    })
end

ux.watchPopupEtaText = function(entry)
    local watch = entry and entry.watch or {}
    local watchZone = tostring(watch.zone or ''):lower()
    if watchZone ~= '' and watchZone ~= currentZoneShort() then
        return watchZone
    end
    if ux.watchHasLiveEvidence(entry) then return '-' end
    if not ux.watchHasSessionTimer(watch) then
        if not ux.watchHasPoint(watch) then return '-' end
        return 'TBD'
    end
    local eta = tonumber(watch.expectedRespawnAt or 0) or 0
    if eta > 0 then
        local text = formatEta(eta, watch)
        if text == 'Due' then return 'Due' end
        return text
    end
    local deathAt = tonumber(watch.despawnedAt or 0) or 0
    if deathAt <= 0 then return 'TBD' end
    local stats = statsForMob(watch.label, nil, watch.lastSpawnPointKey)
    local imported, importedSource = 0, 'none'
    if ux.importedRespawnSeconds then imported, importedSource = ux.importedRespawnSeconds(watch) end
    if stats and stats.n >= MIN_SAMPLES_FOR_DISPLAY then
        return formatEta(deathAt + (tonumber(stats.avg) or 0), watch)
    elseif imported and imported > 0 and tostring(importedSource or ''):lower():find('lazarus', 1, true) then
        return formatEta(deathAt + imported, watch)
    elseif stats and stats.n > 0 and stats.n < MIN_SAMPLES_FOR_DISPLAY then
        return tostring(stats.n) .. '/' .. tostring(MIN_SAMPLES_FOR_DISPLAY)
    elseif imported and imported > 0 then
        return formatEta(deathAt + imported, watch)
    end
    return 'TBD'
end

-- Merged status for the slim popup: collapses State + ETA into one cell.
-- Shows: N UP (green) / PH UP (yellow) / Camp / timer e.g. "2:55" (alertDown) /
--        Down (grey) / Watch (grey). Never shows "-" / "TBD" / overdue count-up.
ux.watchPopupStatusText = function(entry)
    local watch = entry.watch or {}
    if ux.watchIsCampCheckable(entry) then
        return 'Camp', 'etaSoon'
    end
    local baseStatus, baseColor = ux.watchDisplayStatus(entry)
    if watch.isUp or baseStatus == 'N UP' or baseStatus == 'PH UP'
        or baseStatus == '...' or baseStatus == 'Off-zone' then
        return baseStatus, baseColor
    end
    local etaStr = ux.watchPopupEtaText(entry)
    if etaStr ~= nil and etaStr ~= '-' and etaStr ~= 'TBD' and etaStr ~= '' and etaStr ~= 'Due' then
        return etaStr, 'alertDown'
    end
    if baseStatus == 'WATCH' then return 'Watch', 'muted' end
    return 'Down', 'muted'
end

-- The live inputs computeWatchState needs (same ones the original
-- watchDisplayStatus read inline).
ux.buildWatchEvidence = function(entry)
    entry = entry or {}
    local watch = entry.watch or {}
    local watchZone = tostring(watch.zone or ''):lower()
    return {
        inCurrentZone = (watchZone == '' or watchZone == currentZoneShort()),
        baselineReady = ux.watchBaselineReady,
        zoneEntryPending = ux.zoneEntryRefreshPending,
        hasRow = entry.row ~= nil,
        hasOffAnchorNamed = entry.offAnchorRow ~= nil,
        hasPlaceholderRow = entry.placeholderRow ~= nil,
        hasRoamingPh = entry.roamingPhRow ~= nil,
        now = os.time(),
        respawnSeconds = function() return (select(1, ux.effectiveRespawnSeconds(watch))) end,
    }
end

-- Explicit watch state { state, kind, display, color }; state is UP/DOWN/DUE/UNKNOWN.
ux.watchState = function(entry)
    return TM.computeWatchState((entry and entry.watch) or {}, ux.buildWatchEvidence(entry))
end

-- Legacy display string/color, now derived from the single computed state so
-- mini/popup/ultra/full can never disagree about a watch's status.
ux.watchDisplayStatus = function(entry)
    local r = TM.computeWatchState((entry and entry.watch) or {}, ux.buildWatchEvidence(entry))
    return r.display, r.color
end

ux.watchCurrentText = function(entry, maxLen)
    local watch = entry and entry.watch or {}
    local row = entry and entry.row or nil
    local placeholder = entry and entry.placeholderRow or nil
    if row then return shortText(row.name or watch.label or '-', maxLen or 22) end
    if placeholder then return shortText(placeholder.name or watch.currentName or 'PH', maxLen or 22) end
    local current = trim(tostring(watch.currentName or ''))
    if current ~= '' then return shortText(current, maxLen or 22) end
    return '-'
end

ux.watchEtaText = function(entry)
    return ux.watchPopupEtaText(entry)
end

ux.watchTrackText = function(entry)
    local watch = entry and entry.watch or {}
    if watch.mode == 'id' then return 'ID', 'warn' end
    if watch.mode == 'name' then return 'Name', 'muted' end
    if watch.mode == 'smart' then
        if tostring(watch.source or ''):lower() == 'manual ph' then return 'PH', 'etaSoon' end
        local trackingMode = ux.watchTrackingMode(watch)
        if trackingMode == 'roamer' then return 'Roam', 'tools' end
        if trackingMode == 'area' then return 'Area', 'tools' end
        if trackingMode == 'name' then return 'Name', 'muted' end
        local row = entry and entry.row or nil
        if row and tonumber(watch.lastSpawnId or 0) > 0 and tonumber(watch.lastSpawnId) == tonumber(row.id) and not ux.watchPointTrusted(watch) then
            return 'Live', 'selected'
        end
        if ux.watchPointTrusted(watch) then
            if ux.watchLooksNamed(entry) then return 'Named', 'learned' end
            return 'Point', 'learned'
        end
        if ux.watchHasPoint(watch) then return 'Learn', 'etaSoon' end
        return 'Name', 'muted'
    end
    if ux.watchHasPoint(watch) then return 'Point', 'learned' end
    return 'Name', 'muted'
end

ux.drawWatchNavCell = function(row, contextId, options)
    options = type(options) == 'table' and options or {}
    row = ux.resolveNavDisplayRow(row, options.watch, options.placeholderRow) or row
    if not row then ImGui.Text('-'); return end
    local displayRow = (ux.dynamicDirectionRow and ux.dynamicDirectionRow(row)) or row
    local showArrow = options.arrow ~= false
    local context = tostring(contextId or displayRow.navContext or displayRow.name or displayRow.label or '')
    context = context:gsub('[^%w_%-]', '_')
    local suffix = tostring(tonumber(displayRow.id) or 0) .. '_' .. tostring(math.floor(tonumber(displayRow.x) or 0)) .. '_' .. tostring(math.floor(tonumber(displayRow.y) or 0)) .. '_' .. context
    local navTip = (tonumber(displayRow.id) or 0) > 0 and 'Navigate with /nav id to this live spawn.' or 'Navigate with /nav loc to this saved point.'
    local navText = string.format('%.0f##tmobs_nav_cell_%s', tonumber(displayRow.distance) or 0, suffix)
    if styledButton(navText, 'tools', 7, 2, navTip) then navRow(displayRow) end
    if showArrow then
        ImGui.SameLine(0, 2)
        drawDirectionArrow(displayRow, true)
        if ImGui.IsItemClicked and ImGui.IsItemClicked(0) then navRow(displayRow) end
        if ImGui.IsItemHovered() then ImGui.SetTooltip(ux.directionTooltipText(displayRow)) end
    end
end

ux.watchRowDebugText = function(label, row)
    if not row then return label .. ': none' end
    return string.format('%s: %s | id=%d lvl=%d dist=%.0f dir=%s loc=%.1f,%.1f,%.1f type=%s body=%s targetable=%s dead=%s point=%s',
        label,
        tostring(row.name or '-'),
        tonumber(row.id) or 0,
        tonumber(row.level) or 0,
        tonumber(row.distance) or 0,
        ux.directionLabel(row),
        tonumber(row.x) or 0,
        tonumber(row.y) or 0,
        tonumber(row.z) or 0,
        tostring(row.type or '-'),
        tostring(row.body or '-'),
        tostring(row.targetable),
        tostring(row.dead),
        tostring(spawnPointKey(row) or '-'))
end

ux.watchInspectEntry = function(key)
    local watch = watchList and watchList[key] or nil
    if not watch then return nil end
    local row, placeholderRow = ux.resolveWatchDisplayRows(watch, key)
    local poolBlockRow = ux.resolvePoolBlockRow and ux.resolvePoolBlockRow(watch) or nil
    return {
        key = key,
        watch = watch,
        row = row,
        placeholderRow = placeholderRow,
        poolBlockRow = poolBlockRow,
    }
end

ux.watchInspectText = function(entry)
    if not entry or not entry.watch then return 'No watch selected.' end
    local watch = entry.watch
    local row = entry.row
    local cachedId = tonumber(watch.occupantSpawnId or 0) or 0
    local cachedRow = cachedId ~= 0 and ux.spawnIndex and ux.spawnIndex.byId and ux.spawnIndex.byId[cachedId] or nil
    local cachedPoint = cachedRow and spawnPointKey(cachedRow) or ''
    local cachedAtOrigin = cachedRow ~= nil and cachedPoint == tostring(watch.lastSpawnPointKey or '')
    local cachedValid = cachedAtOrigin and 'true (at origin)'
        or (cachedRow ~= nil and 'true (roaming)' or 'false (gone)')
    local occupant = ux.cachedWatchOccupantRow and ux.cachedWatchOccupantRow(watch, entry.key) or ux.watchOccupantRow(watch, entry.key)
    local stats = statsForMob(watch.label, nil, watch.lastSpawnPointKey)
    local importedSeconds, importedSource = ux.importedRespawnSeconds(watch)
    local effectiveSeconds, effectiveSource = ux.effectiveRespawnSeconds(watch)
    local trackText = (select(1, ux.watchTrackText(entry))) or '-'
    local statusText = (select(1, ux.watchDisplayStatus(entry))) or '-'
    local knownNames = ux.pointNamesText(watch, 24)
    local lines = {}

    table.insert(lines, 'TurboMobs Watch Inspect')
    table.insert(lines, 'Version: ' .. tostring(VERSION))
    table.insert(lines, 'Current zone: ' .. currentZoneShort())
    table.insert(lines, 'Watch key: ' .. tostring(entry.key or '-'))
    table.insert(lines, 'Label: ' .. tostring(watch.label or '-'))
    table.insert(lines, 'Desired name: ' .. tostring(watch.desiredName or watch.label or '-'))
    table.insert(lines, 'Track: ' .. tostring(trackText))
    table.insert(lines, 'Mode: ' .. tostring(watch.mode or '-'))
    table.insert(lines, 'Tracking mode: ' .. tostring(ux.watchTrackingMode(watch)))
    table.insert(lines, 'Category: ' .. ux.watchCategoryText(watch))
    table.insert(lines, 'Source: ' .. tostring(watch.source or 'Manual'))
    table.insert(lines, 'Saved zone: ' .. tostring(watch.zone or '-'))
    table.insert(lines, 'Applies here: ' .. tostring(ux.watchAppliesToCurrentZone(watch)))
    table.insert(lines, 'Status: ' .. tostring(statusText))
    local poolBlockName = trim(tostring(watch.poolBlockName or ''))
    if poolBlockName ~= '' then
        table.insert(lines, 'Pool block: ' .. poolBlockName .. ' id=' .. tostring(watch.poolBlockSpawnId or 0))
    end
    table.insert(lines, 'Point known: ' .. tostring(ux.watchHasPoint(watch)))
    table.insert(lines, 'Point confidence: ' .. ux.watchPointConfidence(watch))
    table.insert(lines, 'Point samples: ' .. tostring(watch.pointSamples or 0))
    table.insert(lines, 'Point key: ' .. tostring(watch.lastSpawnPointKey or '-'))
    table.insert(lines, string.format('Saved loc: %.1f, %.1f, %.1f', tonumber(watch.lastX) or 0, tonumber(watch.lastY) or 0, tonumber(watch.lastZ) or 0))
    table.insert(lines, 'Last spawn ID: ' .. tostring(watch.lastSpawnId or '-'))
    table.insert(lines, 'Cached occupant ID: ' .. tostring(cachedId > 0 and cachedId or '-'))
    if cachedId > 0 then
        table.insert(lines, 'Cached occupant point: ' .. tostring(cachedPoint ~= '' and cachedPoint or '-'))
        table.insert(lines, 'Cached occupant valid: ' .. tostring(cachedValid))
    end
    local staleText = trim(tostring(watch.lastStaleOccupantText or ''))
    if staleText ~= '' then
        table.insert(lines, 'Last stale occupant ignored: ' .. staleText)
    end
    local offAnchorId = tonumber(watch.offAnchorOccupantId or 0) or 0
    if offAnchorId > 0 then
        local offAnchorRow = ux.spawnIndex and ux.spawnIndex.byId and ux.spawnIndex.byId[offAnchorId]
        table.insert(lines, string.format('Off-anchor occupant: %s id=%d %s',
            tostring(watch.offAnchorOccupantName or '?'), offAnchorId,
            offAnchorRow and ('live at ' .. tostring(spawnPointKey(offAnchorRow) or '-')) or 'gone'))
    end
    local roamingPhId = tonumber(watch.roamingPhSpawnId or 0) or 0
    if roamingPhId > 0 then
        local roamingPhRow = ux.liveRoamingPhRow and ux.liveRoamingPhRow(watch) or nil
        table.insert(lines, string.format('Roaming PH: %s id=%d %s',
            tostring(watch.roamingPhName or '?'), roamingPhId,
            roamingPhRow and ('live at ' .. tostring(spawnPointKey(roamingPhRow) or '-')) or 'gone'))
    end
    table.insert(lines, 'Point names learned: ' .. (knownNames ~= '' and knownNames or '-'))
    table.insert(lines, 'PH names: ' .. (ux.watchNameListText(watch.phNames or {}) ~= '' and ux.watchNameListText(watch.phNames or {}):gsub('\n', ', ') or '-'))
    local phSet = {}
    for name in pairs(ux.watchPhNameSet(watch) or {}) do table.insert(phSet, name) end
    table.sort(phSet)
    table.insert(lines, 'Possible PHs: ' .. (#phSet > 0 and table.concat(phSet, ', ') or '-'))
    table.insert(lines, 'Area radius: ' .. tostring(watch.areaRadius or 0))
    table.insert(lines, 'Timer arm blocked reason: ' .. tostring(watch.lastTimerBlockedReason or '-'))
    table.insert(lines, 'Last occupied at: ' .. tostring(watch.lastOccupiedAt or 0))
    table.insert(lines, 'Last occupant name: ' .. tostring(watch.lastOccupantName or '-'))
    local confirmedKillAt = tonumber(watch.lastConfirmedKillAt or 0) or 0
    table.insert(lines, 'Last confirmed kill at: ' .. (confirmedKillAt > 0 and (tostring(confirmedKillAt) .. ' (' .. os.date('%I:%M %p', confirmedKillAt) .. ')') or '0'))
    table.insert(lines, ux.watchRowDebugText('Matched desired row', row))
    if entry.poolBlockRow then
        table.insert(lines, ux.watchRowDebugText('Pool block occupant', entry.poolBlockRow))
    end
    table.insert(lines, ux.watchRowDebugText('Current point occupant', occupant))
    if row then table.insert(lines, 'Direction debug: ' .. (ux.directionDebugText(row) ~= '' and ux.directionDebugText(row) or '-')) end
    if (not row) and occupant then table.insert(lines, 'Direction debug: ' .. (ux.directionDebugText(occupant) ~= '' and ux.directionDebugText(occupant) or '-')) end
    if occupant and row and tostring(occupant.name or '') ~= tostring(row.name or '') then
        table.insert(lines, 'Decision: desired name is up, but another point occupant was also found; inspect point data.')
    elseif row then
        table.insert(lines, 'Decision: watch matched the desired live row.')
    elseif roamingPhId > 0 and (ux.liveRoamingPhRow and ux.liveRoamingPhRow(watch) or nil) then
        table.insert(lines, 'Decision: PH is live off-anchor; saved point remains separate and timer is blocked.')
    elseif occupant then
        table.insert(lines, 'Decision: saved point is occupied by a PH/current occupant, desired name is not up.')
    elseif ux.watchHasPoint(watch) then
        table.insert(lines, 'Decision: saved point is empty/down or filtered out by scan settings.')
    else
        table.insert(lines, 'Decision: no saved point yet; this is name/learning mode until a point is observed.')
    end
    table.insert(lines, 'isUp: ' .. tostring(watch.isUp))
    table.insert(lines, 'pointOccupied: ' .. tostring(watch.pointOccupied))
    table.insert(lines, 'currentName: ' .. tostring(watch.currentName or '-'))
    table.insert(lines, 'currentIsDesired: ' .. tostring(watch.currentIsDesired))
    table.insert(lines, 'alertArmed: ' .. tostring(watch.alertArmed))
    table.insert(lines, 'initialResolved: ' .. tostring(watch.initialResolved))
    table.insert(lines, 'Last alert attempted: ' .. tostring(watch.lastAlertAttemptText or '-'))
    table.insert(lines, 'Last alert delivered: ' .. tostring(watch.lastAlertDeliveredText or '-'))
    table.insert(lines, 'Last alert suppressed: ' .. tostring(watch.lastAlertSuppressedReason or '-'))
    table.insert(lines, 'Last delivered alert spawn ID: ' .. tostring(watch.lastDeliveredAlertSpawnId or 0))
    table.insert(lines, 'Last delivered alert key: ' .. tostring(watch.lastDeliveredAlertKey or '-'))
    table.insert(lines, string.format('Alert settings: sound=%s echo=%s popup=%s disabledHere=%s',
        tostring(respawnSound == true),
        tostring(alertEcho == true),
        tostring(ux.spawnPopup == true),
        tostring(zoneAlertsDisabled())))
    table.insert(lines, 'killedAtText: ' .. tostring(watch.killedAtText or '-'))
    table.insert(lines, 'despawnedAt: ' .. tostring(watch.despawnedAt or 0))
    table.insert(lines, 'expectedRespawnAt: ' .. tostring(watch.expectedRespawnAt or 0))
    table.insert(lines, 'ETA: ' .. ux.watchEtaText(entry))
    table.insert(lines, 'Manual respawn seconds: ' .. tostring(watch.respawnSeconds or 0))
    table.insert(lines, 'Seed respawn seconds: ' .. tostring(importedSeconds or 0))
    table.insert(lines, 'Seed timer source: ' .. tostring(importedSource or 'none'))
    table.insert(lines, 'Effective timer: ' .. ((effectiveSeconds and effectiveSeconds > 0) and (formatSeconds(effectiveSeconds) .. ' from ' .. tostring(effectiveSource or 'unknown')) or 'none'))
    if stats then
        table.insert(lines, string.format('Samples: %d/%d', tonumber(stats.n) or 0, MIN_SAMPLES_FOR_DISPLAY))
        table.insert(lines, 'Learned avg: ' .. ((stats.n or 0) >= MIN_SAMPLES_FOR_DISPLAY and formatSeconds(stats.avg) or '-'))
        table.insert(lines, string.format('Learned range: %s-%s', formatSeconds(stats.lo or 0), formatSeconds(stats.hi or 0)))
    else
        table.insert(lines, string.format('Samples: 0/%d', MIN_SAMPLES_FOR_DISPLAY))
    end

    return table.concat(lines, '\n')
end

ux.openWatchInspect = function(entry)
    if not entry then return end
    ux.inspectWatchKey = tostring(entry.key or '')
    ux.inspectWatchOpen = ux.inspectWatchKey ~= ''
end

ux.selectWatch = function(entry)
    if not entry then return end
    ux.selectedWatchKey = tostring(entry.key or '')
end

ux.watchNameClickable = function(label, selected)
    if selected then coloredText(label, 'selected')
    else ImGui.Text(label) end
    return ImGui.IsItemClicked and ImGui.IsItemClicked(0)
end

ux.selectedWatchEntry = function()
    local key = tostring(ux.selectedWatchKey or '')
    if key == '' or not watchList[key] then return nil end
    return ux.watchInspectEntry(key)
end

ux.selectedNamedWatch = function()
    local entry = ux.selectedWatchEntry()
    if entry and ux.watchLooksNamed(entry) then return entry end
    return nil
end

ux.handleWatchRowClick = function(entry, locRow)
    if not entry then return end
    if ux.pendingWatchRow and ux.watchLooksNamed(entry) then
        ux.assignPendingPhToNamed(entry.watch and entry.watch.label)
        return
    end
    ux.selectWatch(entry)
    if locRow and tonumber(locRow.id or 0) > 0 then targetRow(locRow) end
end

ux.drawWatchInspectWindow = function()
    if not ux.inspectWatchOpen then return end
    local entry = ux.watchInspectEntry(ux.inspectWatchKey)
    local open = true
    ImGui.SetNextWindowSizeConstraints(430, 340, 900, 1200)
    open = ImGui.Begin('Inspect Watch##tmobs_inspect_watch', open)
    if not open then
        ux.inspectWatchOpen = false
        ImGui.End()
        return
    end

    if not entry then
        coloredTextWrapped('That watch no longer exists.', 'warn')
        if styledButton('Close##inspect_missing', 'neutral', 7, 3, 'Close this inspect window.') then ux.inspectWatchOpen = false end
        ImGui.End()
        return
    end

    local text = ux.watchInspectText(entry)
    if styledButton('Copy Inspect##watch_inspect_copy', 'primary', 7, 3, 'Copy this diagnostic block for Discord or a bug report.') then
        local ok = pcall(ImGui.SetClipboardText, text)
        chat(ok and 'Watch inspect copied to clipboard.' or 'Unable to copy watch inspect.')
    end
    ImGui.SameLine()
    if styledButton('Refresh##watch_inspect_refresh', 'neutral', 7, 3, 'Refresh live spawn data before reading this inspect view.') then
        ux.refreshWatchesNow({ suppressAlerts = true })
    end
    ImGui.SameLine()
    if styledButton('Close##watch_inspect_close', 'neutral', 7, 3, 'Close this inspect window.') then ux.inspectWatchOpen = false end
    ImGui.Separator()
    coloredTextWrapped(text, 'idle')
    ImGui.End()
end

ux.openWatchEditor = function(entry)
    if not entry or not entry.watch then return end
    local watch = entry.watch
    ux.editWatchKey = tostring(entry.key or '')
    ux.editWatchDraft = {
        label = tostring(watch.label or ''),
        desiredName = tostring(watch.desiredName or watch.label or ''),
        zone = tostring(watch.zone or currentZoneShort()),
        category = tostring(watch.category or 'normal'),
        trackingMode = ux.watchTrackingMode(watch),
        phNamesText = ux.watchNameListText(watch.phNames or {}),
        respawnSeconds = (function() local sec = tonumber(watch.respawnSeconds) or 0; return sec > 0 and formatSeconds(sec) or '0' end)(),
        areaRadius = tostring(tonumber(watch.areaRadius) or 0),
        anchorRadius = tostring(tonumber(watch.anchorRadius) or 0),
        lastX = tostring(watch.lastX ~= nil and watch.lastX or ''),
        lastY = tostring(watch.lastY ~= nil and watch.lastY or ''),
        lastZ = tostring(watch.lastZ ~= nil and watch.lastZ or ''),
        pointConfidence = tostring(watch.pointConfidence or ''),
        alwaysPing = watch.alwaysPing == true,
    }
    ux.editWatchOpen = ux.editWatchKey ~= ''
end

ux.applyWatchEditor = function()
    local key = tostring(ux.editWatchKey or '')
    local draft = ux.editWatchDraft or {}
    local watch = key ~= '' and watchList[key] or nil
    if not watch then return false end

    local label = trim(tostring(draft.label or ''))
    if label == '' then label = tostring(watch.label or key) end
    local desired = trim(tostring(draft.desiredName or ''))
    if desired == '' then desired = label end
    local zone = tostring(draft.zone or ''):lower()
    if zone == '' then zone = currentZoneShort() end
    local trackingMode = tostring(draft.trackingMode or 'point'):lower()
    if trackingMode ~= 'name' and trackingMode ~= 'point' and trackingMode ~= 'area' and trackingMode ~= 'roamer' then
        trackingMode = ux.watchHasPoint(watch) and 'point' or 'name'
    end

    watch.label = label
    watch.desiredName = desired:lower()
    watch.zone = zone
    watch.mode = 'smart'
    watch.category = tostring(draft.category or watch.category or 'normal'):lower()
    if watch.category ~= 'named' and watch.category ~= 'ground' then watch.category = 'normal' end
    watch.trackingMode = trackingMode
    watch.alwaysPing = draft.alwaysPing == true
    watch.phNames = normalizeWatchNameList(draft.phNamesText or {})
    watch.respawnSeconds = math.max(0, ux.parseDurationSeconds(draft.respawnSeconds))
    watch.areaRadius = math.max(0, tonumber(draft.areaRadius) or 0)
    watch.anchorRadius = math.max(0, tonumber(draft.anchorRadius) or 0)
    watch.lastX = tonumber(draft.lastX) or watch.lastX
    watch.lastY = tonumber(draft.lastY) or watch.lastY
    watch.lastZ = tonumber(draft.lastZ) or watch.lastZ
    if watch.lastX ~= nil and watch.lastY ~= nil then
        watch.lastSpawnPointKey = spawnPointKey({ x = watch.lastX, y = watch.lastY, z = watch.lastZ }) or watch.lastSpawnPointKey
    end
    if draft.pointConfidence and draft.pointConfidence ~= '' then watch.pointConfidence = tostring(draft.pointConfidence) end
    if trackingMode == 'roamer' then
        watch.pointConfidence = watch.pointConfidence or 'trusted'
    elseif trackingMode == 'area' and watch.areaRadius <= 0 then
        watch.areaRadius = 250
    end

    saveWatches()
    if ux.rebuildWatchIndex then ux.rebuildWatchIndex() end
    if ux.cacheSearchWatchedRows then ux.cacheSearchWatchedRows() end
    ux.refreshWatchesNow({ suppressAlerts = true })
    addAlert('Updated watch: ' .. label)
    return true
end

ux.drawWatchEditWindow = function()
    if not ux.editWatchOpen then return end
    local key = tostring(ux.editWatchKey or '')
    local watch = watchList and watchList[key] or nil
    local draft = ux.editWatchDraft
    local open = true
    ImGui.SetNextWindowSizeConstraints(430, 420, 820, 1100)
    open = ImGui.Begin('Edit Watch##tmobs_edit_watch', open)
    if not open then
        ux.editWatchOpen = false
        ImGui.End()
        return
    end
    if not watch or not draft then
        coloredTextWrapped('That watch no longer exists.', 'warn')
        if styledButton('Close##edit_missing', 'neutral', 7, 3, 'Close this editor.') then ux.editWatchOpen = false end
        ImGui.End()
        return
    end

    coloredText(shortText(tostring(watch.label or key), 46), 'selected')
    ImGui.SetNextItemWidth(260)
    local labelValue, labelChanged = ImGui.InputText('Named label##edit_label', tostring(draft.label or ''))
    if labelChanged then draft.label = labelValue end
    ImGui.SetNextItemWidth(260)
    local desiredValue, desiredChanged = ImGui.InputText('Live named##edit_desired', tostring(draft.desiredName or ''))
    if desiredChanged then draft.desiredName = desiredValue end
    ImGui.SetNextItemWidth(180)
    local zoneValue, zoneChanged = ImGui.InputText('Zone##edit_zone', tostring(draft.zone or ''))
    if zoneChanged then draft.zone = zoneValue end

    coloredText('Mode', 'muted')
    local modes = {
        { key = 'name', label = 'Name' },
        { key = 'point', label = 'Point' },
        { key = 'area', label = 'Area' },
        { key = 'roamer', label = 'Roamer' },
    }
    for i, mode in ipairs(modes) do
        if i > 1 then ImGui.SameLine() end
        if styledButton(mode.label .. '##edit_mode_' .. mode.key, draft.trackingMode == mode.key and 'primary' or 'neutral', 7, 3, 'Choose how this watch decides whether the named/PH group is up.') then
            draft.trackingMode = mode.key
        end
    end

    coloredText('Category', 'muted')
    local cats = {
        { key = 'named', label = 'Named' },
        { key = 'normal', label = 'Normal' },
        { key = 'ground', label = 'Ground' },
    }
    for i, cat in ipairs(cats) do
        if i > 1 then ImGui.SameLine() end
        if styledButton(cat.label .. '##edit_cat_' .. cat.key, draft.category == cat.key and 'primary' or 'neutral', 7, 3, 'Classify this watch for filters and Zone Intel linking.') then
            draft.category = cat.key
        end
    end

    ImGui.SetNextItemWidth(360)
    local phValue, phChanged = ImGui.InputText('PH names##edit_ph_names', tostring(draft.phNamesText or ''):gsub('\n', ', '))
    if phChanged then draft.phNamesText = phValue end
    if ImGui.IsItemHovered() then ImGui.SetTooltip('Comma-separated PH names. Roamer mode uses these anywhere in the zone; Area mode uses them inside the radius.') end

    ImGui.SetNextItemWidth(110)
    local respawnValue, respawnChanged = ImGui.InputText('Respawn timer##edit_respawn', tostring(draft.respawnSeconds or '0'))
    if respawnChanged then draft.respawnSeconds = respawnValue end
    if ImGui.IsItemHovered() then ImGui.SetTooltip('Accepts: 28:40   28m40s   1720 (sec)   1h   0 to clear') end
    -- Show the auto/seeded timer when no manual override is typed so the user
    -- knows what TurboMobs will use without needing to open the Inspect panel.
    if ux.parseDurationSeconds(draft.respawnSeconds) == 0 and watch and ux.effectiveRespawnSeconds then
        local autoSec, autoSource = ux.effectiveRespawnSeconds(watch)
        if autoSec and autoSec > 0 then
            coloredText('Auto: ' .. formatSeconds(autoSec) .. ' (' .. tostring(autoSource or 'imported') .. ')', 'muted')
        end
    end
    local pingValue, pingChanged = ImGui.Checkbox('Always Ping##edit_always_ping', draft.alwaysPing == true)
    if pingChanged then draft.alwaysPing = pingValue == true end
    if ImGui.IsItemHovered() then ImGui.SetTooltip('Alert on any live named or PH evidence for this watch, not only the desired named spawn.') end
    ImGui.SetNextItemWidth(110)
    if draft.trackingMode == 'area' then
        local radiusValue, radiusChanged = ImGui.InputText('Area radius##edit_radius', tostring(draft.areaRadius or '0'))
        if radiusChanged then draft.areaRadius = radiusValue end
        if ImGui.IsItemHovered() then ImGui.SetTooltip('Radius (units) around the saved point for detecting the named and its PHs.') end
    elseif draft.trackingMode == 'point' then
        local anchorValue, anchorChanged = ImGui.InputText('Anchor radius##edit_anchor', tostring(draft.anchorRadius or '0'))
        if anchorChanged then draft.anchorRadius = anchorValue end
        if ImGui.IsItemHovered() then ImGui.SetTooltip('Max distance (units) from saved point to match a PH. 0 = default (15). Set tighter (e.g. 5) when nearby spawn points share the same PH name.') end
    end

    coloredText('Saved location', 'muted')
    ImGui.SetNextItemWidth(105)
    local xValue, xChanged = ImGui.InputText('X##edit_x', tostring(draft.lastX or ''))
    if xChanged then draft.lastX = xValue end
    ImGui.SameLine()
    ImGui.SetNextItemWidth(105)
    local yValue, yChanged = ImGui.InputText('Y##edit_y', tostring(draft.lastY or ''))
    if yChanged then draft.lastY = yValue end
    ImGui.SameLine()
    ImGui.SetNextItemWidth(105)
    local zValue, zChanged = ImGui.InputText('Z##edit_z', tostring(draft.lastZ or ''))
    if zChanged then draft.lastZ = zValue end

    local target = currentTargetRow()
    if target and styledButton('Use Target Loc##edit_use_target_loc', 'tools', 7, 3, 'Copy current target location and add its name to PH names.') then
        draft.lastX, draft.lastY, draft.lastZ = tostring(target.x or ''), tostring(target.y or ''), tostring(target.z or '')
        local ph = normalizeWatchNameList(draft.phNamesText or '')
        local targetName = trim(tostring(target.name or ''))
        local seen = false
        for _, name in ipairs(ph) do if name:lower() == targetName:lower() then seen = true; break end end
        if targetName ~= '' and not seen then table.insert(ph, targetName) end
        draft.phNamesText = ux.watchNameListText(ph)
    end

    ImGui.Separator()
    if styledButton('Save##edit_watch_save', 'primary', 9, 4, 'Save this watch.') then
        if ux.applyWatchEditor() then ux.editWatchOpen = false end
    end
    ImGui.SameLine()
    if styledButton('Cancel##edit_watch_cancel', 'neutral', 9, 4, 'Close without saving.') then ux.editWatchOpen = false end
    ImGui.SameLine()
    if styledButton('Inspect##edit_watch_inspect', 'neutral', 9, 4, 'Open diagnostic inspect for this watch.') then
        ux.openWatchInspect({ key = key, watch = watch })
    end
    ImGui.End()
end

-- Quick Search panel: moblist-style live name search on the Search tab.
-- Shows mq.getFilteredSpawns results filtered by searchText, sorted by distance.
-- Polled every ~1s from refreshIfDue. Gives near-instant kill detection feedback.
-- Quick Search sort state (col: 'dist'|'name'|'level'|'truename'|'loc', dir: 1/-1)
ux.qsSortCol = ux.qsSortCol or 'dist'
ux.qsSortDir = ux.qsSortDir or 1

ux.qsSortRows = function(rows)
    local col = ux.qsSortCol or 'dist'
    local dir = ux.qsSortDir or 1
    table.sort(rows, function(a, b)
        local av, bv
        if col == 'dist'     then av, bv = a.dist or 9999, b.dist or 9999
        elseif col == 'level'    then av, bv = a.level or 0, b.level or 0
        elseif col == 'name'     then av, bv = (a.name or ''):lower(), (b.name or ''):lower()
        elseif col == 'truename' then av, bv = (a.trueName or ''):lower(), (b.trueName or ''):lower()
        elseif col == 'loc'      then av, bv = a.x or 0, b.x or 0
        elseif col == 'type'     then av, bv = ((a.row and tostring(a.row.type or '')) or ''):lower(), ((b.row and tostring(b.row.type or '')) or ''):lower()
        elseif col == 'body'     then av, bv = ((a.row and tostring(a.row.body or '')) or ''):lower(), ((b.row and tostring(b.row.body or '')) or ''):lower()
        elseif col == 'race'     then av, bv = ((a.row and tostring(a.row.race or '')) or ''):lower(), ((b.row and tostring(b.row.race or '')) or ''):lower()
        elseif col == 'class'    then av, bv = ((a.row and tostring(a.row.class or '')) or ''):lower(), ((b.row and tostring(b.row.class or '')) or ''):lower()
        else av, bv = a.dist or 9999, b.dist or 9999 end
        if dir == 1 then return av < bv else return av > bv end
    end)
end

ux.qsHeaderBtn = function(label, col)
    local active = (ux.qsSortCol or 'dist') == col
    local arrow = active and (((ux.qsSortDir or 1) == 1) and ' v' or ' ^') or ''
    -- Use TextUnformatted + IsItemClicked instead of Selectable(label, active):
    -- Selectable returns the *selected state* as its first value in MQ2's ImGui
    -- binding, so passing active=true causes it to fire every frame, re-sorting
    -- the list continuously.
    if active then ImGui.PushStyleColor(ImGuiCol.Text, 1, 1, 0.4, 1) end
    ImGui.TextUnformatted(label .. arrow)
    if active then ImGui.PopStyleColor() end
    if ImGui.IsItemClicked() then
        if ux.qsSortCol == col then
            ux.qsSortDir = (ux.qsSortDir == 1) and -1 or 1
        else
            ux.qsSortCol = col
            ux.qsSortDir = 1
        end
        if type(ux.quickSearchRows) == 'table' then
            ux.qsSortRows(ux.quickSearchRows)
        end
    end
end

ux.drawQuickSearch = function()
    local rows = ux.quickSearchRows

    if type(rows) ~= 'table' then
        if (tonumber(ux.spawnRefreshInProgress) or 0) > 0 then
            coloredText('Loading zone mobs... (running scan)', 'muted')
        else
            coloredText('Loading zone mobs... (waiting for zone index)', 'muted')
        end
        return
    end

    local needle = ux.quickSearchNeedle or ''
    if #rows == 0 then
        if needle ~= '' then
            coloredText('No live mobs matching "' .. needle .. '".', 'muted')
        else
            coloredText('No mobs in zone index yet. Try Refresh.', 'muted')
        end
        return
    end

    -- Build active column list based on user toggle flags
    local cols = {
        { id = 'level', label = 'Lvl',  fixed = 30 },
        { id = 'name',  label = 'Name', stretch = true },
    }
    if ux.qsShowTrueName  then cols[#cols+1] = { id = 'truename', label = 'True Name', stretch = true } end
    if ux.qsColShowType   then cols[#cols+1] = { id = 'type',     label = 'Type',      fixed = 64 } end
    if ux.qsColShowBody   then cols[#cols+1] = { id = 'body',     label = 'Body',      fixed = 64 } end
    if ux.qsColShowRace   then cols[#cols+1] = { id = 'race',     label = 'Race',      fixed = 64 } end
    if ux.qsColShowClass  then cols[#cols+1] = { id = 'class',    label = 'Class',     fixed = 64 } end
    cols[#cols+1] = { id = 'dist', label = 'Dist', fixed = 48 }
    cols[#cols+1] = { id = 'loc',  label = 'Loc',  fixed = 90 }
    cols[#cols+1] = { id = 'nav',  label = 'Nav',  fixed = 46 }

    local _, availY = ImGui.GetContentRegionAvail()
    local tableFlags = bit32.bor(ImGuiTableFlags.BordersInnerV, ImGuiTableFlags.BordersOuter,
        ImGuiTableFlags.RowBg, ImGuiTableFlags.ScrollY, ImGuiTableFlags.SizingFixedFit)
    local tableH = math.max((tonumber(availY) or 200) - 4, 80)

    if ImGui.BeginTable('##qs_table', #cols, tableFlags, 0, tableH) then
        if ImGui.TableSetupScrollFreeze then ImGui.TableSetupScrollFreeze(0, 1) end
        for _, col in ipairs(cols) do
            if col.stretch then
                ImGui.TableSetupColumn(col.label, ImGuiTableColumnFlags.WidthStretch)
            else
                ImGui.TableSetupColumn(col.label, ImGuiTableColumnFlags.WidthFixed, col.fixed or 60)
            end
        end

        -- Sortable header row
        ImGui.TableNextRow()
        for ci, col in ipairs(cols) do
            ImGui.TableSetColumnIndex(ci - 1)
            if col.id == 'nav' then
                ImGui.TextUnformatted('Nav')
            else
                ux.qsHeaderBtn(col.label, col.id)
            end
        end

        -- Data rows
        for i, entry in ipairs(rows) do
            local spId = tostring(entry.id or 0)
            local row  = entry.row
            ImGui.TableNextRow()
            for ci, col in ipairs(cols) do
                ImGui.TableSetColumnIndex(ci - 1)
                local id = col.id
                if id == 'level' then
                    ImGui.TextUnformatted(tostring(entry.level or ''))
                elseif id == 'name' then
                    local cr, cg, cb, ca = conColorForLevel(entry.level)
                    ImGui.PushStyleColor(ImGuiCol.Text, cr, cg, cb, ca)
                    ImGui.TextUnformatted(tostring(entry.name or ''))
                    ImGui.PopStyleColor()
                    -- Left-click → target
                    if ImGui.IsItemClicked() then
                        mq.cmdf('/target id %s', spId)
                    end
                    if ImGui.IsItemHovered() then
                        ImGui.SetTooltip('Left-click to target | Right-click for options')
                    end
                    -- Right-click context menu (no Target entry — left-click handles it)
                    if ImGui.BeginPopupContextItem('##qs_ctx' .. i) then
                        coloredText(tostring(entry.name or ''), 'selected')
                        ImGui.Separator()
                        if ImGui.Selectable('Navigate##qs_nav' .. i) then
                            mq.cmdf('/nav id %s', spId)
                        end
                        ImGui.Separator()
                        if ImGui.Selectable('Watch##qs_watch' .. i) then
                            if row then addWatchExact(row, false, true) end
                        end
                        if ImGui.Selectable('Assign as PH##qs_ph' .. i) then
                            if row then
                                ux.pendingWatchRow = row
                                ux.phNamedDraft = ux.phNamedDraft or ''
                            end
                        end
                        ImGui.Separator()
                        if ImGui.Selectable('Highlight on map##qs_hl' .. i) then
                            -- Use /highlight directly (same as moblist) to bypass ux.mapHighlight gate
                            mq.cmdf('/highlight "%s"', tostring(entry.name or ''))
                        end
                        ImGui.EndPopup()
                    end
                elseif id == 'truename' then
                    ImGui.TextUnformatted(tostring(entry.trueName or ''))
                elseif id == 'type' then
                    ImGui.TextUnformatted(tostring((row and row.type) or ''))
                elseif id == 'body' then
                    ImGui.TextUnformatted(tostring((row and row.body) or ''))
                elseif id == 'race' then
                    ImGui.TextUnformatted(tostring((row and row.race) or ''))
                elseif id == 'class' then
                    ImGui.TextUnformatted(tostring((row and row.class) or ''))
                elseif id == 'dist' then
                    ImGui.TextUnformatted((entry.dist or 9999) < 9999 and string.format('%.0f', entry.dist) or '?')
                elseif id == 'loc' then
                    ImGui.TextUnformatted(string.format('%.0f, %.0f', entry.x or 0, entry.y or 0))
                elseif id == 'nav' then
                    if ImGui.Button('Nav##qs' .. i) then
                        mq.cmdf('/nav id %s', spId)
                    end
                end
            end
        end
        ImGui.EndTable()
    end
end

ux.drawWatchContextMenu = function(entry)
    local watch = entry.watch
    local row = entry.row
    local locRow = ux.resolveWatchLocRow and ux.resolveWatchLocRow(entry) or (row or entry.placeholderRow or watchLocRow(watch))
    coloredText(shortText(watch.label or entry.key, 34), watch.isUp and 'alertUp' or 'alertDown')
    ImGui.Separator()
    if row then
        if ImGui.Selectable('Navigate to live spawn') then navRow(row) end
    else
        -- Named (or PH) may be live but off its anchor point.
        local offId = tonumber(watch.offAnchorOccupantId or 0) or 0
        local offRow = offId > 0 and ux.spawnIndex and ux.spawnIndex.byId and ux.spawnIndex.byId[offId] or nil
        if offRow then
            if ImGui.Selectable('Navigate to live spawn (off anchor)') then navRow(offRow) end
        end
        if locRow then
            local navLabel
            if entry.placeholderRow and not row then
                navLabel = 'Navigate to PH'
            elseif entry.poolBlockRow and not row and not entry.placeholderRow then
                navLabel = 'Navigate to pool occupant'
            else
                navLabel = 'Navigate to saved point'
            end
            if ImGui.Selectable(navLabel) then navRow(locRow) end
        elseif not offRow then
            coloredText('No saved point available.', 'muted')
        end
    end
    if ImGui.Selectable('Select for PH assignment') then ux.selectWatch(entry) end
    if ImGui.Selectable((watch.alwaysPing == true and 'Disable Always Ping' or 'Enable Always Ping') .. '##wctx_always_ping') then
        watch.alwaysPing = watch.alwaysPing ~= true
        saveWatches()
        if ux.markWatchStateDirty then ux.markWatchStateDirty() end
    end
    if ImGui.Selectable('Edit Watch') then ux.openWatchEditor(entry) end
    if ImGui.Selectable('Copy Inspect') then
        local ok = pcall(ImGui.SetClipboardText, ux.watchInspectText(entry))
        chat(ok and 'Watch inspect copied to clipboard.' or 'Unable to copy watch inspect.')
    end
    -- Highlight: prefer live named spawn, then PH at anchor, then roaming off-anchor
    local hlName = (row and row.name) or ''
    if hlName == '' then
        local phRow = entry.placeholderRow
        local offId = tonumber(watch.offAnchorOccupantId or 0) or 0
        local offRow = offId > 0 and ux.spawnIndex and ux.spawnIndex.byId and ux.spawnIndex.byId[offId] or nil
        hlName = (phRow and phRow.name) or (offRow and offRow.name) or watch.label or watch.desiredName or ''
    end
    if hlName ~= '' then
        ImGui.Separator()
        if ImGui.Selectable('Highlight on map##wctx_hl') then
            mq.cmdf('/highlight "%s"', hlName)
        end
    end
    ImGui.Separator()
    if (tonumber(watch.respawnSeconds) or 0) > 0 and ImGui.Selectable('Clear manual timer') then watch.respawnSeconds = 0; saveWatches() end
    if ImGui.Selectable('Remove watch') then clearWatchByKey(entry.key) end
end

ux.drawWatchMiniRow = function(entry, suffix)
    local watch = entry.watch
    local row = entry.row
    local placeholderRow = entry.placeholderRow
    local label = ux.watchNameText(entry, 28)
    local status, color = ux.watchPopupStatusText(entry)
    if status == 'N UP' or status == 'NAMED UP' then status = 'UP' end
    if status == 'WATCH' then status = 'Watch' end

    if row then
        local r, g, b, a = conColorForLevel(row.level)
        ImGui.PushStyleColor(ImGuiCol.Text, r, g, b, a)
    end
    if ux.watchNameClickable(label, false) then
        ux.handleWatchRowClick(entry, row or placeholderRow)
    end
    if row then ImGui.PopStyleColor() end
    if ImGui.IsItemHovered() then
        ux.drawWatchTooltip(entry)
    end
    if ImGui.BeginPopupContextItem('##watchmini_ctx_' .. suffix .. '_' .. entry.key) then
        ux.drawWatchContextMenu(entry)
        ImGui.EndPopup()
    end
    ImGui.SameLine()
    coloredText(status, color)
    local dirRow = row or placeholderRow
    if dirRow then
        ImGui.SameLine()
        distanceText(dirRow.distance)
        ImGui.SameLine()
        drawDirectionArrow(dirRow, true)
    end
end

ux.watchUltraStatus = function(entry)
    local watch = entry and entry.watch or {}
    local status, displayColor = ux.watchPopupStatusText(entry)
    status = status or ''
    displayColor = displayColor or 'muted'
    if status == 'N UP' or status == 'NAMED UP' or status == 'UP' then return 'UP', 'alertUp' end
    if status == 'PH UP' or status == 'PH' then return 'PH', 'etaSoon' end
    if status == 'Camp' then return 'Camp', 'etaSoon' end
    if status == 'Watch' or status == 'WATCH' then return 'Watch', 'muted' end
    if status == 'Down' then return 'Down', displayColor end
    if status ~= '' and status ~= '-' and status ~= 'TBD' and status ~= 'Due' and status:find(':') then
        return status, displayColor == 'muted' and 'alertDown' or displayColor
    end
    return status ~= '' and status or 'Down', 'muted'
end

ux.drawWatchUltraRows = function(rows, opts)
    rows = rows or {}
    opts = opts or {}
    if #rows == 0 then
        local tracked = ux.currentZoneWatchCount and ux.currentZoneWatchCount() or 0
        if tracked > 0 and ux.zoneWatchesNeedFirstScan and ux.zoneWatchesNeedFirstScan() then
            coloredTextWrapped('Scanning zone camps...', 'etaSoon')
        elseif tracked > 0 then
            coloredTextWrapped(string.format('%d camp(s) tracked - all down.', tracked), 'muted')
        else
            coloredTextWrapped('No active watches right now.', 'muted')
        end
        return 0
    end
    local maxRows = tonumber(opts.maxDrawRows)
        or (opts.companion and tonumber(ux.watchPopupCompanionMaxDrawRows))
        or tonumber(ux.watchPopupMaxDrawRows)
        or 16
    local minRows = opts.companion and 4 or 8
    local maxDraw = math.min(#rows, math.max(minRows, maxRows))
    local hidden = #rows - maxDraw
    local drawn = 0
    local availX = ux.contentAvailX and ux.contentAvailX(220) or 220
    for i = 1, maxDraw do
        local entry = rows[i]
        drawn = drawn + 1
        local watch = entry.watch or {}
        local row = entry.row
        local placeholderRow = entry.placeholderRow
        local locRow = ux.resolveWatchLocRow and ux.resolveWatchLocRow(entry) or (row or placeholderRow or watchLocRow(watch))
        local status, statusColor = ux.watchUltraStatus(entry)
        local isNamedUp = watch.isUp or row ~= nil
        local r, g, b, a = 0.62, 0.66, 0.72, 1.00
        if isNamedUp then
            r, g, b = 0.40, 1.00, 0.52
        elseif placeholderRow then
            r, g, b = 1.00, 0.78, 0.32
        end
        ImGui.PushStyleColor(ImGuiCol.Text, r, g, b, a)
        if ux.watchNameClickable(ux.watchNameText(entry, 34), ux.selectedWatchKey == entry.key) then
            ux.handleWatchRowClick(entry, locRow)
        end
        ImGui.PopStyleColor()
        if not opts.companion then
            if ImGui.IsItemHovered() then ux.drawWatchTooltip(entry) end
            if ImGui.BeginPopupContextItem('##ultra_watch_ctx_' .. entry.key) then
                ux.drawWatchContextMenu(entry)
                ImGui.EndPopup()
            end
        end
        ImGui.SameLine()
        local statusText = tostring(status or '')
        local statusW = 42
        if ImGui.CalcTextSize then
            local w = ImGui.CalcTextSize(statusText)
            if type(w) == 'table' then
                statusW = math.max(statusW, tonumber(w.x or w.X or w[1]) or statusW)
            else
                statusW = math.max(statusW, tonumber(w) or statusW)
            end
        end
        if ImGui.SetCursorPosX and ImGui.GetCursorPosX then
            local x = ImGui.GetCursorPosX()
            ImGui.SetCursorPosX(math.max(x, availX - statusW - 2))
        end
        coloredText(statusText, statusColor)
    end
    if hidden > 0 then
        coloredText(string.format('+%d more - open full view', hidden), 'muted')
    end
    return drawn
end

ux.drawAlertPopupWindow = function()
    if not ux.showAlertPopup then return end
    local tStart = nowMs()
    local companionMode = showWindow == true and tostring(ux.activeFullTab or '') == 'watches'
    local drawOpts = companionMode and {
        companion = true,
        maxDrawRows = tonumber(ux.watchPopupCompanionMaxDrawRows) or 8,
    } or nil
    local rows = ux.buildWatchRows({ includeAll = false, zoneScope = 'current', cacheScope = 'popup' })
    local tRows = nowMs()
    local tControlsAt = tRows
    local tBodyAt = tRows
    local tTableAt = tRows
    local drawnRows = 0
    local function finish(stage)
        local tEnd = nowMs()
        local elapsed = tEnd - tStart
        ux.lastWatchPopupTimingText = string.format(
            'WatchPopup total=%d rowsBuild=%d controls=%d body=%d table=%d final=%d rows=%d drawn=%d stage=%s raw=%d watches=%d',
            elapsed, tRows - tStart, tControlsAt - tRows, tBodyAt - tControlsAt, tTableAt - tBodyAt,
            tEnd - tTableAt, #rows, drawnRows, tostring(stage or 'done'), #allSpawns, tableCount(watchList))
        ux.recordSlowPerf('watchPopup', ux.lastWatchPopupTimingText, elapsed, 8, 1000)
    end

    local desiredW, desiredH = ux.calcTurboWatchSize(rows, drawOpts)
    if not (ux.windowGeom and ux.windowGeom.watch) then
        ux.placeWatchWindowTopRight(desiredW, desiredH)
    end
    ux.applyTurboWatchAutoSize(rows, drawOpts)
    ImGui.PushStyleVar(ImGuiStyleVar.WindowRounding, 5)
    ImGui.PushStyleVar(ImGuiStyleVar.WindowBorderSize, 2)
    ImGui.PushStyleColor(ImGuiCol.Border, 0.72, 0.56, 0.24, 0.95)
    ImGui.PushStyleColor(ImGuiCol.TitleBg, 0.08, 0.11, 0.16, 1.00)
    ImGui.PushStyleColor(ImGuiCol.TitleBgActive, 0.10, 0.14, 0.20, 1.00)
    ImGui.PushStyleColor(ImGuiCol.TitleBgCollapsed, 0.08, 0.11, 0.16, 1.00)
    local open = true
    open = ImGui.Begin('Turbo Watch', open, ImGuiWindowFlags.NoTitleBar or 0)
    if not open then
        ux.hideWatchWindow()
        ux.captureWindowGeometry('watch')
        ImGui.End()
        ImGui.PopStyleColor(4); ImGui.PopStyleVar(2)
        finish('closed')
        return
    end

    ux.chromeDragApplyActive(ux.chromeDragStateWatch)
    ux.drawTurboWatchChrome()
    tControlsAt = nowMs()
    if not ux.showAlertPopup then
        ux.captureWindowGeometry('watch')
        ImGui.End()
        ImGui.PopStyleColor(4); ImGui.PopStyleVar(2)
        finish('hidden')
        return
    end

    local safePaused = ux.safeZoneScanPaused()
    local watchBusy, watchBusyTitle, watchBusyDetail = ux.watchBusyState()
    if safePaused and #rows == 0 then
        coloredTextWrapped('Paused in safe zone.', 'stopped')
    elseif watchBusy and #rows == 0 then
        ux.drawWatchLoadingPanel(watchBusyTitle, watchBusyDetail, currentZoneShort(), 'Seed watches are still loading for this zone.')
    end
    local progressText = ux.watchScanProgressText and ux.watchScanProgressText() or ''
    if progressText ~= '' and #rows == 0 then coloredTextWrapped(progressText, 'muted') end
    tBodyAt = nowMs()
    drawnRows = ux.drawWatchUltraRows(rows, drawOpts)
    tTableAt = nowMs()
    ux.captureWindowGeometry('watch')
    ImGui.End()
    ImGui.PopStyleColor(4); ImGui.PopStyleVar(2)
    finish('ultra')
end


ux.drawCompactWindow = function()
    ImGui.SetNextWindowSizeConstraints(260, 100, 520, 720)
    ImGui.SetNextWindowSize(330, 150, ImGuiCond.FirstUseEver)

    ImGui.PushStyleVar(ImGuiStyleVar.WindowRounding, 5)
    ImGui.PushStyleVar(ImGuiStyleVar.WindowBorderSize, 2)
    ImGui.PushStyleColor(ImGuiCol.Border, 0.72, 0.56, 0.24, 0.95)
    ImGui.PushStyleColor(ImGuiCol.TitleBg, 0.08, 0.11, 0.16, 1.00)
    ImGui.PushStyleColor(ImGuiCol.TitleBgActive, 0.10, 0.14, 0.20, 1.00)
    ImGui.PushStyleColor(ImGuiCol.TitleBgCollapsed, 0.08, 0.11, 0.16, 1.00)

    local open = showWindow
    open = ImGui.Begin(SCRIPT_NAME, open, bit32.bor(ImGuiWindowFlags.NoTitleBar, ImGuiWindowFlags.AlwaysAutoResize))
    showWindow = open

    if not open then
        ux.hideFullWindow()
        ImGui.End()
        ImGui.PopStyleColor(4); ImGui.PopStyleVar(2)
        return
    end

    local selected = ux.selectedNamedWatch()
    if selected and selected.watch and selected.watch.label then
        coloredText('Selected: ' .. tostring(selected.watch.label), 'selected')
    end

    local rows = ux.buildWatchRows(true)
    if #rows == 0 then
        ux.drawMiniWatchSummary()
    else
        for i, entry in ipairs(rows) do
            if i > 5 then
                coloredText(string.format('+%d more watched', #rows - 5), 'muted')
                break
            end
            ux.drawWatchMiniRow(entry, 'compact')
        end
    end

    if styledButton(enabled and 'ON' or 'PAUSED', enabled and 'start' or 'stop', 9, 4, enabled and 'Tracking is running. Click to pause.' or 'Tracking is paused. Click to resume.') then
        enabled = not enabled
        if enabled then ux.refreshWatchesNow() end
    end
    ImGui.SameLine()
    ux.drawTargetActionButton('compact')
    ImGui.SameLine()
    ux.drawAssignPHButton('compact')
    ImGui.SameLine()
    if styledButton(ux.showAlertPopup and 'Hide Watch' or 'Pop Watch', ux.showAlertPopup and 'tools' or 'primary', 9, 4, 'Show or hide the separate Turbo Watch pop-out. Closing it does not remove watches.') then
        if ux.showAlertPopup then
            ux.hideWatchWindow()
        else
            ux.showAlertPopup = true
            ux.alertPopupClosedAt = 0
            saveSettings()
        end
    end
    ImGui.SameLine()
    if styledButton('Full', 'expand', 9, 4, 'Expand to the full spawn table and filters.') then
        ux.toggleFullMainWindow()
    end
    ImGui.SameLine()
    if styledButton('Nav Stop', 'neutral', 9, 4, 'Stop active MQ navigation without unloading TurboMobs.') then
        ux.stopNav()
    end
    ImGui.SameLine()
    if styledButton('Unload', 'unloadDark', 9, 4, 'Unload TurboMobs. This is the same intent as /lua stop TurboMobs.') then
        ux.stopNow()
    end

    ux.drawWatchAssignmentPanel()
    ImGui.End()
    ImGui.PopStyleColor(4); ImGui.PopStyleVar(2)
end

ux.sortHeader = function(label, mode)
    local text = label
    if sortMode == mode then text = text .. (sortAscending and ' ^' or ' v') end
    if ImGui.Selectable(text .. '##sort_' .. mode, false) then
        if sortMode == mode then sortAscending = not sortAscending
        else sortMode = mode; sortAscending = (mode ~= 'Level') end
        ux.searchPage = 1
        sortSpawns(); saveSettings()
    end
end

ux.resetSearchPage = function()
    ux.searchPage = 1
end

ux.searchPageBounds = function(total)
    total = tonumber(total) or 0
    local pageSize = math.max(20, math.min(500, tonumber(maxResults) or 100))
    local pageCount = math.max(1, math.ceil(total / pageSize))
    ux.searchPage = math.max(1, math.min(pageCount, tonumber(ux.searchPage) or 1))
    local first = total > 0 and ((ux.searchPage - 1) * pageSize + 1) or 0
    local last = total > 0 and math.min(total, first + pageSize - 1) or 0
    return pageSize, pageCount, first, last
end

ux.drawSearchPagingControls = function(total)
    local pageSize, pageCount, first, last = ux.searchPageBounds(total)
    coloredText(string.format('Matches: %d | Showing %d-%d | Page %d/%d', tonumber(total) or 0, first, last, ux.searchPage, pageCount), 'muted')
    ImGui.SameLine()
    coloredText('Rows:', 'muted')
    for _, size in ipairs({50, 100, 250}) do
        ImGui.SameLine()
        if styledButton(tostring(size) .. '##search_page_size_' .. tostring(size), pageSize == size and 'primary' or 'neutral', 6, 2, 'Show ' .. tostring(size) .. ' search rows per page') then
            maxResults = size
            ux.searchPage = 1
            saveSettings()
        end
    end
    if total <= pageSize then return end

    if styledButton('<', ux.searchPage > 1 and 'neutral' or 'disabled', 7, 2, 'Previous page') then
        if ux.searchPage > 1 then ux.searchPage = ux.searchPage - 1 end
    end
    ImGui.SameLine()
    local firstPage = math.max(1, ux.searchPage - 2)
    local lastPage = math.min(pageCount, firstPage + 4)
    firstPage = math.max(1, lastPage - 4)
    if firstPage > 1 then
        if styledButton('1##search_page_first', 'neutral', 7, 2, 'Go to first page') then ux.searchPage = 1 end
        ImGui.SameLine()
        ImGui.Text('...')
        ImGui.SameLine()
    end
    for p = firstPage, lastPage do
        if styledButton(tostring(p) .. '##search_page_' .. tostring(p), p == ux.searchPage and 'primary' or 'neutral', 7, 2, 'Go to page ' .. tostring(p)) then
            ux.searchPage = p
        end
        if p < lastPage then ImGui.SameLine() end
    end
    if lastPage < pageCount then
        ImGui.SameLine()
        ImGui.Text('...')
        ImGui.SameLine()
        if styledButton(tostring(pageCount) .. '##search_page_last', 'neutral', 7, 2, 'Go to last page') then ux.searchPage = pageCount end
    end
    ImGui.SameLine()
    if styledButton('>', ux.searchPage < pageCount and 'neutral' or 'disabled', 7, 2, 'Next page') then
        if ux.searchPage < pageCount then ux.searchPage = ux.searchPage + 1 end
    end
end

ux.zoneIntelPageBounds = function(total)
    total = tonumber(total) or 0
    local pageSize = math.max(50, math.min(250, tonumber(ux.zoneIntelPageSize) or 100))
    local pageCount = math.max(1, math.ceil(total / pageSize))
    ux.zoneIntelPage = math.max(1, math.min(pageCount, tonumber(ux.zoneIntelPage) or 1))
    local first = total > 0 and ((ux.zoneIntelPage - 1) * pageSize + 1) or 0
    local last = total > 0 and math.min(total, first + pageSize - 1) or 0
    return pageSize, pageCount, first, last
end

ux.drawZoneIntelPagingControls = function(total, storedTotal)
    local pageSize, pageCount, first, last = ux.zoneIntelPageBounds(total)
    local stored = tonumber(storedTotal) or 0
    if stored > 0 and stored > (tonumber(total) or 0) then
        coloredText(string.format(
            'Saved points: %d | Showing %d-%d of %d | Page %d/%d',
            stored, first, last, tonumber(total) or 0, ux.zoneIntelPage, pageCount
        ), 'muted')
    else
        coloredText(string.format('Learned points: %d | Showing %d-%d | Page %d/%d', tonumber(total) or 0, first, last, ux.zoneIntelPage, pageCount), 'muted')
    end
    ImGui.SameLine()
    coloredText('Rows:', 'muted')
    for _, size in ipairs({50, 100, 250}) do
        ImGui.SameLine()
        if styledButton(tostring(size) .. '##zone_intel_page_size_' .. tostring(size), pageSize == size and 'primary' or 'neutral', 6, 2, 'Show ' .. tostring(size) .. ' learned points per page') then
            ux.zoneIntelPageSize = size
            ux.zoneIntelPage = 1
            saveSettings()
        end
    end
    if total <= pageSize then return end

    if styledButton('<##zone_intel_prev', ux.zoneIntelPage > 1 and 'neutral' or 'disabled', 7, 2, 'Previous page') then
        if ux.zoneIntelPage > 1 then ux.zoneIntelPage = ux.zoneIntelPage - 1 end
    end
    ImGui.SameLine()
    local firstPage = math.max(1, ux.zoneIntelPage - 2)
    local lastPage = math.min(pageCount, firstPage + 4)
    firstPage = math.max(1, lastPage - 4)
    if firstPage > 1 then
        if styledButton('1##zone_intel_page_first', 'neutral', 7, 2, 'Go to first page') then ux.zoneIntelPage = 1 end
        ImGui.SameLine()
        ImGui.Text('...')
        ImGui.SameLine()
    end
    for p = firstPage, lastPage do
        if styledButton(tostring(p) .. '##zone_intel_page_' .. tostring(p), p == ux.zoneIntelPage and 'primary' or 'neutral', 7, 2, 'Go to page ' .. tostring(p)) then
            ux.zoneIntelPage = p
        end
        if p < lastPage then ImGui.SameLine() end
    end
    if lastPage < pageCount then
        ImGui.SameLine()
        ImGui.Text('...')
        ImGui.SameLine()
        if styledButton(tostring(pageCount) .. '##zone_intel_page_last', 'neutral', 7, 2, 'Go to last page') then ux.zoneIntelPage = pageCount end
    end
    ImGui.SameLine()
    if styledButton('>##zone_intel_next', ux.zoneIntelPage < pageCount and 'neutral' or 'disabled', 7, 2, 'Next page') then
        if ux.zoneIntelPage < pageCount then ux.zoneIntelPage = ux.zoneIntelPage + 1 end
    end
end

ux.drawSearchDirectionCell = function(row)
    ImGui.Text(ux.directionLabel(row))
end

ux.drawRowContextMenu = function(row)
    if ImGui.BeginPopupContextItem('##mob_context_' .. tostring(row.id)) then
        conColoredText(shortText(row.name, 28), row.level)

        local etaText = learnedEtaText(row.name, spawnPointKey(row))
        if etaText then coloredText(etaText, 'learned') end

        ImGui.Separator()

        if ImGui.Selectable('Target') then selectRow(row, true) end
        if ImGui.Selectable('Nav to') then selectRow(row, false); navSelected() end
        if ImGui.Selectable('/face') then selectRow(row, false); faceSelected() end

        ImGui.Separator()

        if ImGui.Selectable('Watch') then addWatchExact(row) end
        if ImGui.IsItemHovered() then
            ImGui.SetTooltip('TurboMobs will classify this as a name, point, or named-point watch under the hood.')
        end

        local selectedNamed = ux.selectedNamedWatch()
        local assignLabel = selectedNamed and selectedNamed.watch and ('Assign PH to ' .. tostring(selectedNamed.watch.label or 'selected')) or 'Assign PH...'
        if ImGui.Selectable(assignLabel) then
            if selectedNamed and selectedNamed.watch then
                ux.addWatchPhForNamed(row, selectedNamed.watch.label)
            else
                ux.pendingWatchRow = row
                ux.phNamedDraft = ux.phNamedDraft or ''
            end
        end
        if ImGui.IsItemHovered() then
            ImGui.SetTooltip('Link this row as a placeholder for a named watch.')
        end

        ImGui.Separator()
        if ImGui.Selectable('Clear watch / timer') then clearWatch(row) end

        ImGui.EndPopup()
    end
end

ux.drawSpawnTable = function()
    if #spawns == 0 then
        if ux.safeZoneScanPaused() then
            coloredTextWrapped('Search is paused in this safe zone. Use Scan Here to load live mobs here.', 'stopped')
        elseif #allSpawns == 0 then
            coloredTextWrapped('No live spawn rows are loaded. Refresh, or check that scanning is ON.', 'muted')
        else
            local activeFilters = ux.activeSearchFilterText()
            if activeFilters ~= '' then
                coloredTextWrapped(string.format('No matches from %d scanned rows. Active filters: %s', #allSpawns, activeFilters), 'muted')
            else
                coloredTextWrapped(string.format('No matches from %d scanned rows.', #allSpawns), 'muted')
            end
        end
        if styledButton('Clear Search##empty_search_clear', 'neutral', nil, nil, 'Clear name, type, body, race, class, level, distance, and named filters. Keeps targetable/NPC/include preferences.') then
            ux.clearSearchFilters()
        end
        ImGui.SameLine()
        if styledButton('Refresh##empty_search_refresh', 'primary', nil, nil, 'Refresh live spawn data now.') then
            ux.safeZoneScanOverride = true
            ux.refreshSearchNow({ suppressAlerts = true, searchOnly = true })
        end
    end

    local totalRows = #spawns
    ux.drawSearchPagingControls(totalRows)
    local _, _, firstRow, lastRow = ux.searchPageBounds(totalRows)

    local columnCount = 3
    if ux.showIdColumn then columnCount = columnCount + 1 end
    if ux.showTrueNameColumn then columnCount = columnCount + 1 end
    if ux.showTypeColumn then columnCount = columnCount + 1 end
    if ux.showBodyColumn then columnCount = columnCount + 1 end
    if ux.showClassColumn then columnCount = columnCount + 1 end
    if ux.showDirectionColumn then columnCount = columnCount + 1 end

    local _, availY = ImGui.GetContentRegionAvail()
    local tableHeight = math.max(160, (tonumber(availY) or 220) - 8)
    local tableFlags = bit32.bor(ImGuiTableFlags.Borders, ImGuiTableFlags.RowBg, ImGuiTableFlags.ScrollY,
        ImGuiTableFlags.Resizable, ImGuiTableFlags.Reorderable, ImGuiTableFlags.Hideable,
        ImGuiTableFlags.SizingStretchProp)
    if ImGui.BeginTable('##turbomobs_table', columnCount, tableFlags, 0, tableHeight) then
        ImGui.TableSetupColumn('Name', ImGuiTableColumnFlags.WidthStretch, 1.35)
        if ux.showIdColumn then ImGui.TableSetupColumn('ID', ImGuiTableColumnFlags.WidthFixed, 48) end
        ImGui.TableSetupColumn('Lvl', ImGuiTableColumnFlags.WidthFixed, 34)
        if ux.showTypeColumn then ImGui.TableSetupColumn('Type', ImGuiTableColumnFlags.WidthFixed, 58) end
        if ux.showBodyColumn then ImGui.TableSetupColumn('Body', ImGuiTableColumnFlags.WidthFixed, 72) end
        if ux.showClassColumn then ImGui.TableSetupColumn('Class', ImGuiTableColumnFlags.WidthFixed, 70) end
        if ux.showTrueNameColumn then ImGui.TableSetupColumn('True Name', ImGuiTableColumnFlags.WidthStretch, 1.0) end
        ImGui.TableSetupColumn('Nav', ImGuiTableColumnFlags.WidthFixed, 96)
        if ux.showDirectionColumn then ImGui.TableSetupColumn('Dir', ImGuiTableColumnFlags.WidthFixed, 42) end
        if ImGui.TableSetupScrollFreeze then
            ImGui.TableSetupScrollFreeze(0, 1)
        end

        ImGui.TableNextRow()
        ImGui.TableSetColumnIndex(0); ux.sortHeader('Name', 'Name')
        local col = 1
        if ux.showIdColumn then ImGui.TableSetColumnIndex(col); ux.sortHeader('ID', 'ID'); col = col + 1 end
        ImGui.TableSetColumnIndex(col); ux.sortHeader('Lvl', 'Level'); col = col + 1
        if ux.showTypeColumn then ImGui.TableSetColumnIndex(col); ux.sortHeader('Type', 'Type'); col = col + 1 end
        if ux.showBodyColumn then ImGui.TableSetColumnIndex(col); ux.sortHeader('Body', 'Body'); col = col + 1 end
        if ux.showClassColumn then ImGui.TableSetColumnIndex(col); ux.sortHeader('Class', 'Class'); col = col + 1 end
        if ux.showTrueNameColumn then ImGui.TableSetColumnIndex(col); ux.sortHeader('True Name', 'TrueName'); col = col + 1 end
        ImGui.TableSetColumnIndex(col); ux.sortHeader('Nav', 'Distance'); col = col + 1
        if ux.showDirectionColumn then ImGui.TableSetColumnIndex(col); ux.sortHeader('Dir', 'Direction') end

        local previousDirectionContext = ux.directionContext
        if ux.showDirectionColumn then
            local headingCW = tonumber(safeCall(function() return mq.TLO.Me.Heading.Degrees() end, 0)) or 0
            local headingCCW = tonumber(safeCall(function() return mq.TLO.Me.Heading.DegreesCCW() end, nil))
            if not headingCCW then headingCCW = (360 - headingCW) % 360 end
            ux.directionContext = {
                x = tonumber(safeCall(function() return mq.TLO.Me.X() end, 0)) or 0,
                y = tonumber(safeCall(function() return mq.TLO.Me.Y() end, 0)) or 0,
                heading = headingCW,
                headingCCW = headingCCW,
            }
        end
        for i = firstRow, lastRow do
            local row = spawns[i]
            if not row then break end
            local watched, watchedEntry = row.watched == true, row.watchedEntry
            ImGui.TableNextRow()
            ImGui.TableSetColumnIndex(0)
            local label = (watched and '* ' or '') .. shortText(row.name, 24) .. '##mob_' .. tostring(row.id)
            if conColoredSelectable(label, row) then
                selectRow(row, false)
                targetRow(row)
            end
            ux.drawRowContextMenu(row)
            if ImGui.IsItemHovered() then
                local tooltip = string.format('%s%s\nID: %d\nLevel: %d\nDistance: %.1fm\nLoc: %.1f, %.1f, %.1f\nType: %s\nBody: %s\nRace: %s\nClass: %s',
                    watched and '[Watched] ' or '', row.name, row.id, row.level, row.distance, row.y or 0, row.x or 0, row.z or 0, row.type, row.body, row.race, row.class)
                if watchedEntry then
                    local trackText = (ux.watchTrackText({ watch = watchedEntry }))
                    tooltip = tooltip .. '\nWatched as: ' .. tostring(trackText)
                    if watchedEntry.lastSpawnPointKey then tooltip = tooltip .. '\nPoint: ' .. tostring(watchedEntry.lastSpawnPointKey) end
                end
                tooltip = tooltip .. '\nLeft-click targets. Use Nav button/column to navigate. Right-click opens actions.'
                if isPetRow(row) then tooltip = tooltip .. string.format('\nOwnerID: %d', row.ownerId or 0) end
                ImGui.SetTooltip(tooltip)
            end
            local dataCol = 1
            if ux.showIdColumn then ImGui.TableSetColumnIndex(dataCol); ImGui.Text(tostring(row.id)); dataCol = dataCol + 1 end
            ImGui.TableSetColumnIndex(dataCol); conColoredText(tostring(row.level), row.level); dataCol = dataCol + 1
            if ux.showTypeColumn then ImGui.TableSetColumnIndex(dataCol); ImGui.Text(row.type or 'Unknown'); dataCol = dataCol + 1 end
            if ux.showBodyColumn then ImGui.TableSetColumnIndex(dataCol); ImGui.Text(row.body and row.body ~= 'Unknown' and row.body or '-'); dataCol = dataCol + 1 end
            if ux.showClassColumn then ImGui.TableSetColumnIndex(dataCol); ImGui.Text(row.class and row.class ~= 'Unknown' and ux.classText(row.class) or '-'); dataCol = dataCol + 1 end
            if ux.showTrueNameColumn then ImGui.TableSetColumnIndex(dataCol); ImGui.Text(row.trueName or '-'); dataCol = dataCol + 1 end
            ImGui.TableSetColumnIndex(dataCol); ux.drawWatchNavCell(row, row.id or row.name, { arrow = false }); dataCol = dataCol + 1
            if ux.showDirectionColumn then ImGui.TableSetColumnIndex(dataCol); ux.drawSearchDirectionCell(row) end
        end
        ux.directionContext = previousDirectionContext
        ImGui.EndTable()
    end
end

ux.drawDebugPanel = function()
    if not debugMode then return end
    ImGui.Separator()
    coloredText('Debug Scan', 'muted')
    if ux.lastRefreshTimingText and ux.lastRefreshTimingText ~= '' then
        coloredText(ux.lastRefreshTimingText, 'muted')
    end
    if ux.lastDrawTimingText and ux.lastDrawTimingText ~= '' then
        coloredText(ux.lastDrawTimingText, 'muted')
    end
    if ux.lastRefreshDecisionText and ux.lastRefreshDecisionText ~= '' then
        coloredText(ux.lastRefreshDecisionText, 'muted')
    end
    if ux.lastWatchRowsTimingText and ux.lastWatchRowsTimingText ~= '' then
        coloredText(ux.lastWatchRowsTimingText, 'muted')
    end
    if ux.lastWatchPopupTimingText and ux.lastWatchPopupTimingText ~= '' then
        coloredText(ux.lastWatchPopupTimingText, 'muted')
    end
    if ux.lastWatchDetailTimingText and ux.lastWatchDetailTimingText ~= '' then
        coloredText(ux.lastWatchDetailTimingText, 'muted')
    end
    if ux.perfLog and #ux.perfLog > 0 then
        coloredText('Recent perf:', 'muted')
        for i = 1, math.min(5, #ux.perfLog) do
            coloredText(shortText(ux.perfLog[i], 110), 'muted')
        end
    end
    coloredText('Types: ' .. topDebugCounts(debugTypeCounts, 8), 'muted')
    coloredText('Bodies: ' .. topDebugCounts(debugBodyCounts, 8), 'muted')
    coloredText(string.format('Map highlights: %d names', tonumber(ux.lastMapHighlightCount) or 0), 'muted')
    if ux.lastStaleOccupantText ~= '' then
        coloredText('Stale occupant: ' .. shortText(ux.lastStaleOccupantText, 110), 'muted')
    end

    if ImGui.BeginTable('##turbomobs_debug_table', 6, bit32.bor(ImGuiTableFlags.Borders, ImGuiTableFlags.RowBg, ImGuiTableFlags.ScrollY, ImGuiTableFlags.Resizable), 0, 120) then
        ImGui.TableSetupColumn('Name', ImGuiTableColumnFlags.WidthStretch)
        ImGui.TableSetupColumn('Lv', ImGuiTableColumnFlags.WidthFixed, 30)
        ImGui.TableSetupColumn('Dist', ImGuiTableColumnFlags.WidthFixed, 45)
        ImGui.TableSetupColumn('Type', ImGuiTableColumnFlags.WidthFixed, 60)
        ImGui.TableSetupColumn('Body', ImGuiTableColumnFlags.WidthFixed, 70)
        ImGui.TableSetupColumn('Target', ImGuiTableColumnFlags.WidthFixed, 48)
        ImGui.TableHeadersRow()
        for _, row in ipairs(debugRawRows) do
            ImGui.TableNextRow()
            ImGui.TableSetColumnIndex(0); ImGui.Text(shortText(row.name, 24))
            ImGui.TableSetColumnIndex(1); ImGui.Text(tostring(row.level))
            ImGui.TableSetColumnIndex(2); ImGui.Text(string.format('%.0f', row.distance))
            ImGui.TableSetColumnIndex(3); ImGui.Text(row.type or 'Unknown')
            ImGui.TableSetColumnIndex(4); ImGui.Text(row.body or 'Unknown')
            ImGui.TableSetColumnIndex(5); ImGui.Text(tostring(row.targetable))
        end
        ImGui.EndTable()
    end
end

ux.drawAlertsPanel = function(force)
    if not force and not showAlertsPanel then return end
    local tStart = nowMs()

    ImGui.Separator()
    coloredText('Watches', 'muted')
    if force then
        ux.drawWatchZonePicker()
        if styledButton('All##watch_detail_filter', ux.watchDetailFilter == 'all' and 'primary' or 'neutral', 7, 3, 'Show every current-zone watch.') then ux.watchDetailFilter = 'all' end
        ImGui.SameLine()
        if styledButton('Up##watch_detail_filter', ux.watchDetailFilter == 'up' and 'start' or 'neutral', 7, 3, 'Show watches that are currently up.') then ux.watchDetailFilter = 'up' end
        ImGui.SameLine()
        if styledButton('Down##watch_detail_filter', ux.watchDetailFilter == 'down' and 'danger' or 'neutral', 7, 3, 'Show watches that are down or waiting for an ETA.') then ux.watchDetailFilter = 'down' end
        ImGui.SameLine()
        if styledButton('Named##watch_detail_filter', ux.watchDetailFilter == 'named' and 'start' or 'neutral', 7, 3, 'Show named-category watches.') then ux.watchDetailFilter = 'named' end
        ImGui.SameLine()
        if styledButton('Ground##watch_detail_filter', ux.watchDetailFilter == 'ground' and 'tools' or 'neutral', 7, 3, 'Show ground-item watches.') then ux.watchDetailFilter = 'ground' end
        coloredText('  Viewing: ' .. ux.watchDetailZoneLabel(), 'muted')
    end
    local tControlsAt = nowMs()

    local entries = ux.buildWatchRows({
        includeAll = true,
        sortState = ux.watchDetailSort,
        zoneScope = ux.watchDetailZone or 'current',
        statusFilter = force and (ux.watchDetailFilter or 'all') or 'all',
        requireDetailZone = true,
        cacheScope = 'detail',
    })
    local tCacheAt = nowMs()
    local cacheHit = ux.lastWatchRowsTimingText and ux.lastWatchRowsTimingText:find('cache=hit', 1, true) ~= nil
    if force and #entries > 0 then
        local pointCount, nameCount, phCount = 0, 0, 0
        for _, entry in ipairs(entries) do
            if ux.watchHasPoint(entry.watch) then pointCount = pointCount + 1 else nameCount = nameCount + 1 end
            if entry.placeholderRow and not entry.row then phCount = phCount + 1 end
        end
        coloredText(string.format('  Point tracked: %d  |  Name watch: %d  |  PH up: %d', pointCount, nameCount, phCount), 'muted')
    end
    local tSummaryAt = nowMs()

    local drawnRows = 0
    local tTableAt = tSummaryAt
    if #entries == 0 then
        coloredText('  (no watches - right-click a mob, use Watch, or /tmobs watch <name>)', 'muted')
    else
        local tableHeight = 150
        if force then
            local _, availY = ImGui.GetContentRegionAvail()
            local recentReserve = (#alertLog > 0) and 72 or 0
            tableHeight = math.max(130, (tonumber(availY) or 260) - recentReserve - 8)
        end
        if ImGui.BeginTable('##turbomobs_watch_table', 7, bit32.bor(ImGuiTableFlags.Borders, ImGuiTableFlags.RowBg, ImGuiTableFlags.Resizable, ImGuiTableFlags.ScrollY, ImGuiTableFlags.SizingStretchProp), 0, tableHeight) then
            ImGui.TableSetupColumn('Name', ImGuiTableColumnFlags.WidthStretch, 1.25)
            ImGui.TableSetupColumn('State', ImGuiTableColumnFlags.WidthFixed, 46)
            ImGui.TableSetupColumn('Current', ImGuiTableColumnFlags.WidthStretch, 0.95)
            ImGui.TableSetupColumn('ETA', ImGuiTableColumnFlags.WidthFixed, 48)
            ImGui.TableSetupColumn('Nav', ImGuiTableColumnFlags.WidthFixed, 92)
            ImGui.TableSetupColumn('Samples', ImGuiTableColumnFlags.WidthFixed, 48)
            ImGui.TableSetupColumn('', ImGuiTableColumnFlags.WidthFixed, 28)
            ImGui.TableNextRow()
            ux.watchSortHeader(0, 'Name', 'name', ux.watchDetailSort, 'detail')
            ux.watchSortHeader(1, 'State', 'status', ux.watchDetailSort, 'detail')
            ImGui.TableSetColumnIndex(2); ImGui.Text('Current')
            ux.watchSortHeader(3, 'ETA', 'eta', ux.watchDetailSort, 'detail')
            ImGui.TableSetColumnIndex(4); ImGui.Text('Nav')
            ux.watchSortHeader(5, 'Samples', 'samples', ux.watchDetailSort, 'detail')
            ImGui.TableSetColumnIndex(6)
            ImGui.Text('')
            for _, entry in ipairs(entries) do
                drawnRows = drawnRows + 1
                local watch = entry.watch
                local watchRow = entry.row
                local locRow = ux.resolveWatchLocRow and ux.resolveWatchLocRow(entry) or (watchRow or entry.placeholderRow or watchLocRow(watch))
                local eta = tonumber(watch.expectedRespawnAt or 0) or 0
                local learnedStats = statsForMob(watch.label, nil, watch.lastSpawnPointKey)
                ImGui.TableNextRow()
                ImGui.TableSetColumnIndex(0)
                if watchRow then
                    local r, g, b, a = conColorForLevel(watchRow.level)
                    ImGui.PushStyleColor(ImGuiCol.Text, r, g, b, a)
                end
                local selectLabel = (ux.selectedWatchKey == entry.key and '> ' or '') .. ux.watchNameText(entry, 38)
                if ux.watchNameClickable(selectLabel, ux.selectedWatchKey == entry.key) then
                    ux.handleWatchRowClick(entry, locRow)
                end
                if watchRow then ImGui.PopStyleColor() end
                if ImGui.IsItemHovered() then
                    ux.drawWatchTooltip(entry)
                end
                if ImGui.BeginPopupContextItem('##watch_context_' .. entry.key) then
                    ux.drawWatchContextMenu(entry)
                    ImGui.EndPopup()
                end
                ImGui.TableSetColumnIndex(1)
                local status, statusColor = ux.watchDisplayStatus(entry)
                coloredText(status, statusColor)
                ImGui.TableSetColumnIndex(2)
                local currentColor = entry.placeholderRow and 'etaSoon' or (watchRow and 'active' or 'muted')
                coloredText(ux.watchCurrentText(entry, 20), currentColor)
                ImGui.TableSetColumnIndex(3)
                coloredText(ux.watchEtaText(entry), watch.isUp and 'muted' or statusColor)
                ImGui.TableSetColumnIndex(4)
                ux.drawWatchNavCell(locRow, entry.key, { watch = watch, placeholderRow = entry.placeholderRow })
                ImGui.TableSetColumnIndex(5)
                if learnedStats then coloredText(tostring(learnedStats.n) .. '/' .. tostring(MIN_SAMPLES_FOR_DISPLAY), learnedStats.n >= MIN_SAMPLES_FOR_DISPLAY and 'learned' or 'muted')
                else ImGui.Text('-') end
                ImGui.TableSetColumnIndex(6)
                if styledButton('x##rm_' .. entry.key, 'danger', 6, 2, 'Remove this watch.') then clearWatchByKey(entry.key) end
            end
            ImGui.EndTable()
        end
    end
    tTableAt = nowMs()

    if #alertLog > 0 then
        coloredText('Recent', 'muted')
        local shown = 0
        for _, alert in ipairs(alertLog or {}) do
            shown = shown + 1
            if shown > 4 then break end
            ImGui.Text(string.format('%s  %s', alert.time or '', alert.text or ''))
        end
    end
    local elapsed = nowMs() - tStart
    ux.lastWatchDetailTimingText = string.format(
        'WatchDetail total=%d controls=%d cache=%d summary=%d table=%d recent=%d rows=%d drawn=%d cacheHit=%s force=%s raw=%d watches=%d filter=%s sort=%s/%s zone=%s',
        elapsed, tControlsAt - tStart, tCacheAt - tControlsAt, tSummaryAt - tCacheAt, tTableAt - tSummaryAt,
        nowMs() - tTableAt, #entries, drawnRows, tostring(cacheHit == true), tostring(force == true),
        #allSpawns, tableCount(watchList), tostring(ux.watchDetailFilter or 'all'), tostring((ux.watchDetailSort or {}).mode or 'default'),
        (ux.watchDetailSort or {}).asc ~= false and 'asc' or 'desc', tostring(ux.watchDetailZone or 'current'))
    ux.recordSlowPerf('drawAlertsPanel', string.format(
        'DrawAlertsPanel total=%dms controls=%d cache=%d table=%d rows=%d drawn=%d cacheHit=%s force=%s watches=%d raw=%d',
        elapsed, tControlsAt - tStart, tCacheAt - tControlsAt, tTableAt - tSummaryAt, #entries, drawnRows,
        tostring(cacheHit == true), tostring(force == true), tableCount(watchList), #allSpawns), elapsed, 8, 1000)
end

ux.zoneIntelBuildWatchLinkMaps = function()
    local maps = { byPoint = {}, byLabel = {} }
    for key, watch in pairs(watchList or {}) do
        if ux.watchIsNamedLink and ux.watchIsNamedLink(watch) and ux.watchAppliesToCurrentZone(watch) then
            local item = { key = key, watch = watch }
            local pointKey = tostring(watch.lastSpawnPointKey or '')
            if pointKey ~= '' then
                maps.byPoint[pointKey] = maps.byPoint[pointKey] or {}
                table.insert(maps.byPoint[pointKey], item)
            end
            local desired = ux.smartDesiredName(watch)
            if desired ~= '' then
                maps.byLabel[desired] = maps.byLabel[desired] or {}
                table.insert(maps.byLabel[desired], item)
            end
        end
    end
    return maps
end

-- Generation-cached accessor for the watch link maps. Rebuilding scans the full
-- watch list, so cache it by ux.watchGeneration + zone and reuse it for every
-- ZoneIntel point lookup within a refresh instead of re-scanning per point.
ux.zoneIntelGetWatchLinkMaps = function()
    local gen = ux.watchGeneration or 0
    local zone = currentZoneShort()
    local cache = ux.zoneIntelLinkMapCache
    if cache and cache.gen == gen and cache.zone == zone and type(cache.maps) == 'table' then
        return cache.maps
    end
    local maps = ux.zoneIntelBuildWatchLinkMaps()
    ux.zoneIntelLinkMapCache = { gen = gen, zone = zone, maps = maps }
    return maps
end

ux.zoneIntelLinksForPoint = function(pointKey, label, maps, entry)
    maps = maps or { byPoint = {}, byLabel = {} }
    local linked = {}
    local seen = {}
    local function addList(list)
        for _, item in ipairs(list or {}) do
            if item and item.key and not seen[item.key] then
                seen[item.key] = true
                table.insert(linked, item)
            end
        end
    end
    addList(maps.byPoint and maps.byPoint[tostring(pointKey or '')])
    -- Full-zone Alla imports can contain many coordinates for the same NPC name.
    -- Named+PH should mean a watch is tied to this exact point, not every point
    -- whose seed label matches the watched name.
    table.sort(linked, function(a, b)
        return tostring(a.watch.label or ''):lower() < tostring(b.watch.label or ''):lower()
    end)
    return linked
end

ux.zoneIntelNamesFromLinks = function(linked, limit)
    local names = {}
    for _, item in ipairs(linked or {}) do
        local label = trim(tostring(item.watch and (item.watch.label or item.watch.desiredName) or ''))
        if label ~= '' then table.insert(names, label) end
        if limit and #names >= limit then break end
    end
    return table.concat(names, ', ')
end

-- Base row title (named linked to the camp), without camp disambiguation suffix.
ux.zoneIntelBaseLabel = function(intel)
    local entry = intel and intel.entry or {}
    if type(intel) == 'table' and type(intel.linkedWatches) == 'table' then
        for _, item in ipairs(intel.linkedWatches) do
            local w = item and item.watch
            if w and ux.labelLooksNamed(w.label or w.desiredName) then
                local nm = trim(tostring(w.label or w.desiredName or ''))
                if nm ~= '' then return nm end
            end
        end
    end
    return tostring(entry.named_name or entry.display_name or entry.last_seen_name or (intel and intel.key) or '')
end

ux.zoneIntelRowRank = function(row)
    local entry = row and row.entry or {}
    local score = 0
    if tostring(entry.seed_confidence or '') == 'imported' then score = score + 1000 end
    if row.liveMatchesLabel then score = score + 500 end
    if row.liveRow then score = score + 100 end
    if row.synthetic then score = score - 200 end
    score = score + (row.stats and tonumber(row.stats.n) or 0)
    return score
end

-- Collapse learned duplicate points for the same named camp (within anchor radius).
ux.dedupeZoneIntelCampRows = function(rows)
    if not rows or #rows == 0 then return rows end
    local kept = {}
    for _, row in ipairs(rows) do
        local base = ux.zoneIntelBaseLabel(row):lower()
        local x = tonumber(row.entry and row.entry.x)
        local y = tonumber(row.entry and row.entry.y)
        local merged = false
        if base ~= '' and x and y then
            for j, other in ipairs(kept) do
                if ux.zoneIntelBaseLabel(other):lower() == base then
                    local ox = tonumber(other.entry and other.entry.x)
                    local oy = tonumber(other.entry and other.entry.y)
                    if ox and oy and ux.rowWithinLoc({ x = x, y = y }, ox, oy, ux.defaultPointOccupantRadius) then
                        if ux.zoneIntelRowRank(row) > ux.zoneIntelRowRank(other) then
                            kept[j] = row
                        end
                        merged = true
                        break
                    end
                end
            end
        end
        if not merged then table.insert(kept, row) end
    end
    return kept
end

-- Append " · 5121" style suffix when several intel rows share a named label.
ux.assignZoneIntelCampSuffixes = function(rows)
    if not rows or #rows == 0 then return end
    local byLabel = {}
    for _, row in ipairs(rows) do
        local base = ux.zoneIntelBaseLabel(row)
        local key = base:lower()
        if key ~= '' then
            byLabel[key] = byLabel[key] or {}
            table.insert(byLabel[key], row)
        end
    end
    local myX = tonumber(safeCall(function() return mq.TLO.Me.X() end, 0)) or 0
    local myY = tonumber(safeCall(function() return mq.TLO.Me.Y() end, 0)) or 0
    for _, list in pairs(byLabel) do
        if #list > 1 then
            for _, row in ipairs(list) do
                local x = tonumber(row.entry and row.entry.x)
                local y = tonumber(row.entry and row.entry.y)
                if x and y then
                    local dx = x - myX
                    local dy = y - myY
                    row.campSuffix = string.format(' · %d', math.floor(math.sqrt(dx * dx + dy * dy) + 0.5))
                end
            end
        end
    end
end

ux.compactZoneIntelCampRows = function(rows)
    if not rows or #rows == 0 then return rows end
    local groups, order, singles = {}, {}, {}
    for _, row in ipairs(rows) do
        local base = trim(tostring(ux.zoneIntelBaseLabel(row) or ''))
        local key = base:lower()
        if key == '' then
            table.insert(singles, row)
        else
            local group = groups[key]
            if not group then
                group = { rows = {} }
                groups[key] = group
                table.insert(order, key)
            end
            table.insert(group.rows, row)
        end
    end

    local compact = {}
    for _, row in ipairs(singles) do table.insert(compact, row) end
    for _, key in ipairs(order) do
        local list = groups[key] and groups[key].rows or {}
        table.sort(list, function(a, b)
            return ux.zoneIntelRowRank(a) > ux.zoneIntelRowRank(b)
        end)
        local best = list[1]
        if best then
            best.campPointCount = #list
            best.campPointRows = list
            table.insert(compact, best)
        end
    end
    return compact
end

ux.zoneIntelRows = function(force)
    local tStart = nowMs()
    local zoneTable = respawnsData[currentZoneShort()]
    local points = zoneTable and zoneTable._points or nil
    if type(points) ~= 'table' then return {} end
    local sortState = ux.zoneIntelSort or {}
    local cacheKey = table.concat({
        currentZoneShort(),
        tostring(ux.zoneIntelFilter or 'all'),
        tostring(ux.zoneIntelView or 'camps'),
        ux.zoneIntelShowIgnored and '1' or '0',
        tostring(sortState.mode or 'default'),
        sortState.asc and '1' or '0',
        tostring(ux.spawnDataRevision or 0),
    }, '|')
    local cache = ux.zoneIntelCache or { at = 0, key = '', rows = {} }
    ux.zoneIntelCache = cache
    local nowValue = nowMs()
    local filter = tostring(ux.zoneIntelFilter or 'all'):lower()
    local cacheMs = filter == 'linked' and 1200 or (ux.zoneIntelCacheMs or 5000)
    if not force and cache.key == cacheKey and cache.rows and (nowValue - (cache.at or 0)) < cacheMs then
        return cache.rows
    end

    local rows = {}
    local linkMaps = ux.zoneIntelGetWatchLinkMaps()
    local function buildRowForPoint(key, entry)
        if type(entry) ~= 'table' or not (ux.zoneIntelShowIgnored or not entry.ignored) then return end
        local label = tostring(entry.display_name or entry.last_seen_name or key)
        local linked = ux.zoneIntelLinksForPoint(key, label, linkMaps, entry)
        local stats = statsFromEntry(entry)
        local liveRow = nil
        local liveMatches = false
        for _, item in ipairs(linked) do
            local watchRow = ux.cachedWatchPresenceRow and ux.cachedWatchPresenceRow(item.watch, item.key) or ux.findWatchPresenceRow(item.watch)
            if watchRow then
                liveRow = watchRow
                liveMatches = true
                break
            end
        end
        if not liveRow then
            for _, item in ipairs(linked) do
                local occupant = ux.cachedWatchOccupantRow and ux.cachedWatchOccupantRow(item.watch, item.key) or ux.watchPointOccupiedRow(item.watch, item.key)
                if occupant then
                    liveRow = occupant
        
                    local liveName = trim(tostring(occupant.name or '')):lower()
                    local desired = trim(tostring(ux.smartDesiredName(item.watch) or '')):lower()
                    if liveName ~= '' and desired ~= '' and liveName == desired then
                        liveMatches = true
                    end
        
                    break
                end
            end
        end
        if not liveRow then liveRow = ux.findLivePointRow(key, entry) end
        if liveRow then
            local liveName = tostring(liveRow.name or ''):lower()
            if #linked > 0 and not liveMatches then
                for _, item in ipairs(linked) do
                    local desired = trim(tostring(ux.smartDesiredName(item.watch) or '')):lower()
                    if liveName ~= '' and desired ~= '' and liveName == desired then
                        liveMatches = true
                        break
                    end
                end
            elseif #linked == 0 then
                liveMatches = liveName ~= '' and liveName == label:lower()
            end
        end
        if filter ~= 'linked' or #linked > 0 then
            table.insert(rows, {
                key = key,
                entry = entry,
                stats = stats,
                liveRow = liveRow,
                linkedWatches = linked,
                hasNamedLinks = #linked > 0,
                desiredText = ux.zoneIntelNamesFromLinks(linked, 6),
                liveMatchesLabel = liveMatches,
            })
        end
    end

    if filter == 'linked' then
        -- A point can only yield a 'linked' row when a named watch is tied to
        -- it (linkMaps.byPoint[key] is non-empty), so drive iteration from the
        -- small link map instead of walking every learned point. Alla-seeded
        -- zones can hold thousands of points (e.g. ~3,800) for only a handful
        -- of linked rows, which is the source of Zone Intel tab lag.
        local seenKeys = {}
        for pointKey in pairs(linkMaps.byPoint or {}) do
            if not seenKeys[pointKey] then
                seenKeys[pointKey] = true
                buildRowForPoint(pointKey, points[pointKey])
            end
        end
        -- Watch-complete Named+PH view: a watched named whose spawn point hasn't
        -- yet settled into a learned _points entry (wanderers, freshly imported or
        -- just-deduped anchors) would otherwise be invisible here even while it's
        -- up. Add a synthetic row for every current-zone named/PH watch not already
        -- represented by a linked point row above, so watched nameds never silently
        -- drop out of intel. These carry no samples, so they render as Seen/Learning
        -- (or the imported Alla timer) until the learner confirms a point.
        local representedWatchKeys = {}
        for _, row in ipairs(rows) do
            for _, item in ipairs(row.linkedWatches or {}) do
                if item.key then representedWatchKeys[item.key] = true end
            end
        end
        local watchKeys, currentWatches = ux.currentZoneWatchPairs()
        for i, watch in ipairs(currentWatches or {}) do
            local wkey = watchKeys[i]
            if watch and wkey and not representedWatchKeys[wkey] and ux.watchIsNamedLink(watch) then
                local anchorKey = tostring(watch.lastSpawnPointKey or '')
                if anchorKey ~= '' then
                    for _, existing in ipairs(rows) do
                        if tostring(existing.key) == anchorKey then
                            representedWatchKeys[wkey] = true
                            break
                        end
                    end
                end
            end
        end
        for i, watch in ipairs(currentWatches or {}) do
            local wkey = watchKeys[i]
            if watch and wkey and not representedWatchKeys[wkey] and ux.watchIsNamedLink(watch) then
                local label = trim(tostring(watch.label or watch.desiredName or ''))
                if label ~= '' then
                    local liveRow = (ux.cachedWatchPresenceRow and ux.cachedWatchPresenceRow(watch, wkey) or ux.findWatchPresenceRow(watch))
                        or (ux.cachedWatchOccupantRow and ux.cachedWatchOccupantRow(watch, wkey) or ux.watchPointOccupiedRow(watch, wkey))
                    local liveMatches = false
                    if liveRow then
                        local liveName = tostring(liveRow.name or ''):lower()
                        local desired = trim(tostring(ux.smartDesiredName(watch) or '')):lower()
                        liveMatches = liveName ~= '' and desired ~= '' and liveName == desired
                    end
                    table.insert(rows, {
                        key = 'watch:' .. tostring(wkey),
                        entry = {
                            display_name = label,
                            last_seen_name = label,
                            named_name = label,
                            category = 'named',
                            ph_names = type(watch.phNames) == 'table' and watch.phNames or {},
                            x = tonumber(watch.lastX) or 0,
                            y = tonumber(watch.lastY) or 0,
                            z = tonumber(watch.lastZ) or 0,
                            respawn_seconds = tonumber(watch.respawnSeconds) or 0,
                            source = watch.source,
                            last_seen = tonumber(watch.lastSeenAt) or 0,
                        },
                        stats = nil,
                        liveRow = liveRow,
                        linkedWatches = { { key = wkey, watch = watch } },
                        hasNamedLinks = true,
                        desiredText = label,
                        liveMatchesLabel = liveMatches,
                        synthetic = true,
                    })
                end
            end
        end
    else
        for key, entry in pairs(points) do
            buildRowForPoint(key, entry)
        end
    end
    if filter == 'linked' then
        rows = ux.dedupeZoneIntelCampRows(rows)
        if tostring(ux.zoneIntelView or 'camps'):lower() ~= 'points' then
            rows = ux.compactZoneIntelCampRows(rows)
        end
    end
    ux.assignZoneIntelCampSuffixes(rows)
    ux.zoneIntelLastTotalRows = #rows
    ux.sortZoneIntelRows(rows, ux.zoneIntelSort)
    cache.key = cacheKey
    cache.at = nowValue
    cache.rows = rows
    local elapsed = nowMs() - tStart
    ux.recordSlowPerf('zoneIntelRows', string.format(
        'ZoneIntelRows total=%dms rows=%d points=%d filter=%s watches=%d raw=%d',
        elapsed, #rows, tableCount(points), tostring(filter), tableCount(watchList), #allSpawns),
        elapsed, 20, 1200)
    return rows
end

ux.zoneIntelConfidence = function(stats)
    local n = stats and stats.n or 0
    if n >= MIN_SAMPLES_FOR_DISPLAY then return 'Good' end
    if n > 0 then return 'Learning' end
    return 'Seen'
end

ux.zoneIntelLabel = function(intel)
    local base = ux.zoneIntelBaseLabel(intel)
    local suffix = type(intel) == 'table' and tostring(intel.campSuffix or '') or ''
    return base .. suffix
end

ux.watchIsNamedLink = function(watch)
    if not watch then return false end
    if tostring(watch.category or ''):lower() == 'ground' then return false end
    local source = tostring(watch.source or ''):lower()
    if source == 'spawnmaster' or source == 'manual ph' then return true end
    if tostring(watch.category or ''):lower() == 'named' and ux.labelLooksNamed(watch.label or watch.desiredName) then return true end
    return false
end

ux.zoneIntelLinkedWatches = function(intel)
    if not intel then return {} end
    if type(intel.linkedWatches) == 'table' then return intel.linkedWatches end
    local pointKey = tostring(intel.key or '')
    local maps = ux.zoneIntelGetWatchLinkMaps()
    return ux.zoneIntelLinksForPoint(pointKey, ux.zoneIntelLabel(intel):lower(), maps, intel.entry)
end

ux.zoneIntelDesiredText = function(intel, limit)
    if intel and type(intel.desiredText) == 'string' and intel.desiredText ~= '' and (not limit or limit >= 6) then return intel.desiredText end
    local names = {}
    for _, item in ipairs(ux.zoneIntelLinkedWatches(intel)) do
        local label = trim(tostring(item.watch.label or item.watch.desiredName or ''))
        if label ~= '' then table.insert(names, label) end
        if limit and #names >= limit then break end
    end
    local entry = intel and intel.entry or nil
    return table.concat(names, ', ')
end

ux.zoneIntelSeedNamesText = function(entry, limit)
    local names = {}
    local seen = {}
    local function add(name)
        local clean = trim(tostring(name or ''))
        local key = clean:lower()
        if clean ~= '' and not seen[key] then
            seen[key] = true
            table.insert(names, clean)
        end
    end
    if type(entry) == 'table' then
        if type(entry.seed_names) == 'table' then
            for _, name in ipairs(entry.seed_names) do add(name) end
        end
        add(entry.named_name)
        if tostring(entry.category or ''):lower() == 'seed' then add(entry.display_name or entry.last_seen_name) end
    end
    local total = #names
    if limit and limit > 0 and #names > limit then
        local shown = {}
        for i = 1, limit do table.insert(shown, names[i]) end
        return table.concat(shown, ', ') .. string.format(' (+%d)', total - limit), total
    end
    return table.concat(names, ', '), total
end

ux.zoneIntelImportedRespawn = function(intel)
    local entry = intel and intel.entry or nil
    local seconds = tonumber(entry and (entry.respawn_seconds or entry.imported_respawn_seconds) or 0) or 0
    if seconds > 0 then return seconds, tostring(entry.timer_source or entry.source or 'imported') end
    for _, item in ipairs(ux.zoneIntelLinkedWatches(intel)) do
        local watchSeconds, source = ux.importedRespawnSeconds(item.watch)
        watchSeconds = tonumber(watchSeconds) or 0
        if watchSeconds > 0 then return watchSeconds, source end
    end
    return 0, 'none'
end

ux.zoneIntelHasNamedLinks = function(intel)
    if intel and intel.hasNamedLinks ~= nil then return intel.hasNamedLinks == true end
    return #ux.zoneIntelLinkedWatches(intel) > 0
end

ux.zoneIntelLiveMatchesLabel = function(intel)
    if intel and intel.liveMatchesLabel ~= nil then return intel.liveMatchesLabel == true end

    local liveRow = intel and intel.liveRow or nil
    if not liveRow then return false end

    local liveName = trim(tostring(liveRow.name or '')):lower()
    if liveName == '' then return false end

    local linked = ux.zoneIntelLinkedWatches(intel)

    -- Strongest signal: linked watch desired named.
    for _, item in ipairs(linked or {}) do
        local desired = trim(tostring(ux.smartDesiredName(item.watch) or '')):lower()
        if desired ~= '' and liveName == desired then return true end
    end

    -- Imported/seed point signals. These protect named mobs like "an odd mole"
    -- where a simple a/an/the heuristic would be wrong.
    local entry = intel and intel.entry or nil
    if type(entry) == 'table' then
        local candidates = {
            entry.named_name,
            entry.display_name,
            entry.last_seen_name,
            entry.seed_name,
        }

        for _, value in ipairs(candidates) do
            local candidate = trim(tostring(value or '')):lower()
            if candidate ~= '' and liveName == candidate then return true end
        end

        if type(entry.seed_names) == 'table' then
            for _, value in ipairs(entry.seed_names) do
                local candidate = trim(tostring(value or '')):lower()
                if candidate ~= '' and liveName == candidate then return true end
            end
        end

        if type(entry.names) == 'table' then
            for _, value in ipairs(entry.names) do
                local candidate = trim(tostring(value or '')):lower()
                if candidate ~= '' and liveName == candidate then return true end
            end
        end
    end

    -- If this is linked to a named watch and none of the named candidates match,
    -- then the point is occupied by a PH/other occupant.
    if #linked > 0 then return false end

    local base = trim(tostring(ux.zoneIntelBaseLabel(intel) or '')):lower()
    return base ~= '' and liveName == base
end

ux.zoneIntelState = function(intel)
    local hasNamedLinks = ux.zoneIntelHasNamedLinks(intel)
    if hasNamedLinks then
        if not (intel and intel.liveRow) then return 'Down', 'alertDown' end
        if ux.zoneIntelLiveMatchesLabel(intel) then return 'N UP', 'alertUp' end
        return 'PH UP', 'etaSoon'
    end
    if intel and intel.liveRow then return 'UP', 'alertUp' end
    return 'Empty', 'muted'
end

ux.zoneIntelCurrentText = function(intel, maxLen)
    local liveRow = intel and intel.liveRow or nil
    if liveRow then return shortText(tostring(liveRow.name or '-'), maxLen or 24) end
    return '-'
end

ux.watchIntelPoint = function(intel)
    local entry = intel.entry or {}
    local liveRow = intel.liveRow
    local label = tostring(entry.named_name or entry.display_name or entry.last_seen_name or intel.key)
    local key = watchKeyExact(label)
    local liveMatches = liveRow and tostring(liveRow.name or ''):lower() == label:lower()
    watchList[key] = watchList[key] or {
        label = label,
        desiredName = tostring(label or ''):lower(),
        mode = 'smart',
        zone = currentZoneShort(),
        source = entry.source or 'Zone Intel',
        category = ux.labelLooksNamed(label) and 'named' or 'normal',
        trackingMode = 'point',
        phNames = type(entry.ph_names) == 'table' and entry.ph_names or {},
        areaRadius = 0,
        spawnId = 0,
        respawnSeconds = 0,
        isUp = false,
        lastSeenAt = tonumber(entry.last_seen) or 0,
        despawnedAt = tonumber(entry.last_death) or 0,
        killedAtText = '',
        expectedRespawnAt = 0,
        initialResolved = true,
        lastSpawnPointKey = intel.key,
        pointConfidence = 'trusted',
        pointSamples = MIN_SAMPLES_FOR_DISPLAY,
        lastX = tonumber(entry.x) or 0,
        lastY = tonumber(entry.y) or 0,
        lastZ = tonumber(entry.z) or 0,
        lastSpawnId = tonumber(entry.last_spawn_id) or 0,
    }
    local watch = watchList[key]
    watch.label = label
    watch.desiredName = tostring(label or ''):lower()
    watch.mode = 'smart'
    watch.zone = currentZoneShort()
    watch.source = entry.source or 'Zone Intel'
    watch.category = tostring(entry.category or '') ~= '' and tostring(entry.category) or (ux.labelLooksNamed(label) and 'named' or 'normal')
    watch.trackingMode = watch.trackingMode or 'point'
    watch.phNames = normalizeWatchNameList(watch.phNames or entry.ph_names or {})
    if type(entry.ph_names) == 'table' then
        local seen = {}
        for _, name in ipairs(watch.phNames) do seen[tostring(name or ''):lower()] = true end
        for _, name in ipairs(entry.ph_names) do
            local clean = trim(tostring(name or ''))
            if clean ~= '' and not seen[clean:lower()] then table.insert(watch.phNames, clean) end
        end
    end
    watch.lastSpawnPointKey = intel.key
    watch.pointConfidence = 'trusted'
    watch.pointSamples = MIN_SAMPLES_FOR_DISPLAY
    watch.lastX = tonumber(entry.x) or 0
    watch.lastY = tonumber(entry.y) or 0
    watch.lastZ = tonumber(entry.z) or 0
    watch.initialResolved = true
    if liveRow then
        watch.pointOccupied = true
        watch.currentName = liveRow.name
        watch.currentIsDesired = liveMatches and true or false
        watch.occupantSpawnId = tonumber(liveRow.id) or 0
        watch.occupantName = liveRow.name
        if liveMatches then
            watch.isUp = true
            watch.lastSeenAt = os.time()
            watch.despawnedAt = 0
            watch.killedAtText = ''
            watch.expectedRespawnAt = 0
            watch.lastSpawnId = tonumber(liveRow.id) or tonumber(entry.last_spawn_id) or 0
        else
            watch.isUp = false
            watch.lastSpawnId = tonumber(entry.last_spawn_id) or watch.lastSpawnId or 0
        end
    else
        watch.pointOccupied = false
        watch.currentName = ''
        watch.currentIsDesired = false
        watch.occupantSpawnId = 0
        watch.occupantName = ''
        watch.isUp = false
    end
    saveWatches()
    ux.zoneIntelCache = { at = 0, key = '', rows = {} }
    addAlert('Watching learned spawn point: ' .. label)
end

ux.drawZoneIntelContextMenu = function(intel)
    local entry = intel.entry or {}
    local stateText, stateColor = ux.zoneIntelState(intel)
    local desiredText = ux.zoneIntelDesiredText(intel, 4)
    local seedText = ux.zoneIntelSeedNamesText(entry, 6)
    coloredText(shortText(entry.display_name or entry.last_seen_name or intel.key, 34), stateColor)
    coloredText(stateText, stateColor)
    if desiredText ~= '' then coloredText('Linked: ' .. desiredText, 'selected') end
    if seedText ~= '' then coloredText('Seed: ' .. seedText, 'muted') end
    if ImGui.Selectable('Watch smart point') then ux.watchIntelPoint(intel) end
    if intel.liveRow and ImGui.Selectable('Watch current mob') then addWatchExact(intel.liveRow) end
    local linked = ux.zoneIntelLinkedWatches(intel)
    if #linked > 0 and ImGui.Selectable('Edit Watch') then
        ux.openWatchEditor(linked[1])
    end
    if ImGui.Selectable('Ignore') then entry.ignored = true; respawnsDirty = true; ux.statsRevision = (ux.statsRevision or 0) + 1 end
    -- Highlight: prefer the live occupant's name; fall back to intel record name
    local ziHlName = (intel.liveRow and intel.liveRow.name) or entry.display_name or entry.last_seen_name or ''
    if ziHlName ~= '' then
        if ImGui.Selectable('Highlight on map##zi_hl') then
            mq.cmdf('/highlight "%s"', ziHlName)
        end
    end
    ImGui.Separator()
    if ImGui.Selectable('Clear Samples') then
        entry.samples = {}
        entry.last_death = 0
        respawnsDirty = true; ux.statsRevision = (ux.statsRevision or 0) + 1
    end
end

ux.drawZoneIntelTab = function()
    coloredTextWrapped('Silent current-zone spawn learning for named camps and placeholders. Generic trash (a rat, a skeleton) is no longer learned by default.', 'muted')
    if not ux.respawnsLoaded then
        coloredTextWrapped('Respawn data is not loaded. Load it only when you need Zone Intel or Alla import/repair.', 'stopped')
        if styledButton('Load Data##zone_intel_load_respawns', 'primary', 9, 4, 'Load TurboMobs respawn data now. Large files can pause the client briefly.') then
            ux.ensureRespawnsLoaded('Zone Intel')
        end
        ImGui.SameLine()
        if styledButton('Import All Zones##zone_intel_import_all_no_data', 'primary', 7, 3, 'Queue import of the bundled Lazarus seed for every zone (alla_seeds_all.lua). This will load respawn data first.') then
            ux.requestAllaImport('alla_seeds_all.lua')
        end
        ImGui.SameLine()
        if styledButton('Import This Zone##zone_intel_import_no_data', 'tools', 7, 3, 'Queue import of just the current-zone Lazarus seed. This will load respawn data first.') then
            ux.requestAllaImport('')
        end
        return
    end
    if styledButton(ux.learnAllSpawns and 'Learning ON' or 'Learning OFF', ux.learnAllSpawns and 'start' or 'neutral', nil, nil, 'Silently learn stable current-zone NPC spawn points. New raw points must be seen repeatedly; seed and watched points update immediately.') then
        ux.learnAllSpawns = not ux.learnAllSpawns
        saveSettings()
    end
    ImGui.SameLine()
    if styledButton('Learn Scan##zone_intel_learn_scan', 'tools', 7, 3, 'Run one broad current-zone learning scan now. This can pause briefly in crowded zones.') then
        ux.lastZoneIntelLearnAllRefreshMS = nowMs()
        refreshSpawns(true, { watchOnly = true, learnAll = true, suppressAlerts = true })
        ux.zoneIntelPage = 1
        ux.zoneIntelCache = { at = 0, key = '', rows = {} }
    end
    ImGui.SameLine()
    if styledButton(ux.zoneIntelShowIgnored and 'Hide Ignored' or 'Show Ignored', ux.zoneIntelShowIgnored and 'tools' or 'neutral', nil, nil, 'Show or hide ignored learned points.') then
        ux.zoneIntelShowIgnored = not ux.zoneIntelShowIgnored
        ux.zoneIntelPage = 1
        saveSettings()
    end
    ImGui.SameLine()
    local ziFilter = tostring(ux.zoneIntelFilter or 'linked'):lower()
    local ziView = tostring(ux.zoneIntelView or 'camps'):lower()
    ImGui.SameLine()
    if styledButton('Camps##zone_intel_filter_camps', ziFilter == 'linked' and ziView ~= 'points' and 'start' or 'neutral', 7, 3, 'Group repeated spawn points by named camp. Best default view for testers.') then
        ux.zoneIntelFilter = 'linked'
        ux.zoneIntelView = 'camps'
        ux.zoneIntelPage = 1
        ux.zoneIntelCache = { at = 0, key = '', rows = {} }
        saveSettings()
    end
    ImGui.SameLine()
    if styledButton('PH Points##zone_intel_filter_linked_points', ziFilter == 'linked' and ziView == 'points' and 'primary' or 'neutral', 7, 3, 'Show every linked named/PH spawn point. Useful for PH cleanup and navigation debugging.') then
        ux.zoneIntelFilter = 'linked'
        ux.zoneIntelView = 'points'
        ux.zoneIntelPage = 1
        ux.zoneIntelCache = { at = 0, key = '', rows = {} }
        saveSettings()
    end
    ImGui.SameLine()
    if styledButton('All Points##zone_intel_filter_all_points', ziFilter ~= 'linked' and 'warn' or 'neutral', 7, 3, 'Show every saved spawn point, including noisy raw learned points. Can be thousands and slow; use only for cleanup.') then
        ux.zoneIntelFilter = 'all'
        ux.zoneIntelView = 'points'
        ux.zoneIntelPage = 1
        ux.zoneIntelCache = { at = 0, key = '', rows = {} }
        saveSettings()
    end
    if styledButton('Repair Alla##zone_intel_repair_alla', 'tools', 7, 3, 'Convert older imported Alla point rows from named rows into seed metadata for this zone.') then
        ux.repairAllaSeedData(currentZoneShort())
        ux.zoneIntelPage = 1
        ux.zoneIntelCache = { at = 0, key = '', rows = {} }
    end
    ImGui.SameLine()
    if styledButton('Import All Zones##zone_intel_import_all', 'primary', 7, 3, 'Import the bundled Lazarus seed for every zone (alla_seeds_all.lua). Respawn/PH data for all zones; named watches are created for the zone you are in now. Other zones (e.g. runnyeye_hc) get watches on first zone-in or Import This Zone.') then
        ux.requestAllaImport('alla_seeds_all.lua')
        ux.zoneIntelPage = 1
        ux.zoneIntelCache = { at = 0, key = '', rows = {} }
    end
    ImGui.SameLine()
    if styledButton('Import This Zone##zone_intel_import_alla', 'tools', 7, 3, 'Import just the current-zone Lazarus Alla seed. No filename is needed.') then
        ux.requestAllaImport('')
        ux.zoneIntelPage = 1
        ux.zoneIntelCache = { at = 0, key = '', rows = {} }
    end
    ImGui.SameLine()
    if styledButton('Clean Raw##zone_intel_clean_raw', 'neutral', 7, 3, 'Remove generic trash spawn timers (a rat, a skeleton, etc.). Keeps Alla seed camps, watched points, and named/PH data.') then
        ux.cleanupZoneIntelRawPoints(currentZoneShort())
        ux.zoneIntelPage = 1
        ux.zoneIntelCache = { at = 0, key = '', rows = {} }
    end

    local rows = ux.zoneIntelRows(false)
    local storedPoints = 0
    do
        local zoneTable = respawnsData and respawnsData[currentZoneShort()]
        local pts = zoneTable and zoneTable._points
        if type(pts) == 'table' then storedPoints = tableCount(pts) end
    end
    if tostring(ux.zoneIntelFilter or 'linked'):lower() ~= 'linked' and storedPoints >= 200 then
        coloredTextWrapped(
            string.format(
                'All Points view: %d saved spawn points in this zone (mostly old learn-all trash). Camps is much faster. Click Clean Raw to drop generic trash timers.',
                storedPoints
            ),
            'etaSoon'
        )
        ImGui.Spacing()
    end
    if #rows == 0 then
        if ux.zoneIntelFilter == 'linked' then
            coloredText('No named-linked spawn points match this view. Use All or link a point to a named watch.', 'muted')
        else
            coloredText('No learned spawn points yet. Leave Learning ON while in-zone to build samples.', 'muted')
        end
        return
    end
    local totalRows = #rows
    ux.drawZoneIntelPagingControls(totalRows, storedPoints)
    local _, _, firstRow, lastRow = ux.zoneIntelPageBounds(totalRows)

    local _, availY = ImGui.GetContentRegionAvail()
    local tableHeight = math.max(180, (tonumber(availY) or 260) - 4)
    if ImGui.BeginTable('##turbomobs_zone_intel_table', 7, bit32.bor(ImGuiTableFlags.Borders, ImGuiTableFlags.RowBg, ImGuiTableFlags.Resizable, ImGuiTableFlags.ScrollY, ImGuiTableFlags.SizingStretchProp), 0, tableHeight) then
        ImGui.TableSetupColumn('Name', ImGuiTableColumnFlags.WidthStretch, 1.4)
        ImGui.TableSetupColumn('State', ImGuiTableColumnFlags.WidthFixed, 46)
        ImGui.TableSetupColumn('Current', ImGuiTableColumnFlags.WidthStretch, 1.0)
        ImGui.TableSetupColumn('Timer', ImGuiTableColumnFlags.WidthFixed, 54)
        ImGui.TableSetupColumn('Samples', ImGuiTableColumnFlags.WidthFixed, 48)
        ImGui.TableSetupColumn('Seen', ImGuiTableColumnFlags.WidthFixed, 60)
        ImGui.TableSetupColumn('Nav', ImGuiTableColumnFlags.WidthFixed, 92)
        if ImGui.TableSetupScrollFreeze then
            ImGui.TableSetupScrollFreeze(0, 1)
        end
        ImGui.TableNextRow()
        ux.zoneIntelSortHeader(0, 'Name', 'name', ux.zoneIntelSort)
        ux.zoneIntelSortHeader(1, 'State', 'status', ux.zoneIntelSort)
        ImGui.TableSetColumnIndex(2); ImGui.Text('Current')
        ux.zoneIntelSortHeader(3, 'Timer', 'avg', ux.zoneIntelSort)
        ux.zoneIntelSortHeader(4, 'Samples', 'samples', ux.zoneIntelSort)
        ux.zoneIntelSortHeader(5, 'Seen', 'last_seen', ux.zoneIntelSort)
        ImGui.TableSetColumnIndex(6); ImGui.Text('Nav')
        for i = firstRow, lastRow do
            local intel = rows[i]
            if not intel then break end
            local entry = intel.entry or {}
            local stats = intel.stats
            local liveRow = intel.liveRow
            local locRow = liveRow or watchLocRow({ lastX = entry.x, lastY = entry.y, lastZ = entry.z, label = entry.display_name })
            local stateText, stateColor = ux.zoneIntelState(intel)
            local desiredText = ux.zoneIntelDesiredText(intel, 6)
            local seedText, seedCount = ux.zoneIntelSeedNamesText(entry, 10)
            local importedSeconds, importedSource = ux.zoneIntelImportedRespawn(intel)
            local displayLabel = ux.zoneIntelLabel(intel)
            local pointCount = tonumber(intel.campPointCount or 0) or 0
            if pointCount > 1 then
                displayLabel = string.format('%s (%d pts)', displayLabel, pointCount)
            end
            ImGui.TableNextRow()
            ImGui.TableSetColumnIndex(0)
            if liveRow then
                local r, g, b, a = conColorForLevel(liveRow.level)
                ImGui.PushStyleColor(ImGuiCol.Text, r, g, b, a)
            end
            if ImGui.Selectable(shortText(displayLabel, 30) .. '##zone_intel_row_' .. intel.key, false) then
                if liveRow then targetRow(liveRow) end
            end
            if liveRow then ImGui.PopStyleColor() end
            if ImGui.IsItemHovered() then
                local baseTip = string.format('%s\nPoint: %s\nState: %s\nLoc: %.1f, %.1f, %.1f\nType: %s\nBody: %s\nRace: %s\nClass: %s',
                    tostring(displayLabel), intel.key,
                    stateText,
                    tonumber(entry.x) or 0, tonumber(entry.y) or 0, tonumber(entry.z) or 0,
                    tostring(entry.type or '-'), tostring(entry.body or '-'), tostring(entry.race or '-'), tostring(entry.class or '-'))
                if pointCount > 1 then
                    baseTip = baseTip .. string.format('\nCamp summary: %d linked spawn points hidden. Switch to Points to inspect each one.', pointCount)
                end
                if desiredText ~= '' then
                    baseTip = baseTip .. '\nLinked named watch: ' .. desiredText
                else
                    baseTip = baseTip .. '\nGeneric learned point: state is only point occupancy.'
                end
                if seedText ~= '' then
                    baseTip = baseTip .. string.format('\nAlla seed names (%d): %s', tonumber(seedCount) or 0, seedText)
                end
                if stats and stats.n >= MIN_SAMPLES_FOR_DISPLAY then
                    baseTip = baseTip .. string.format('\nAvg respawn: %s (+/-%ds)', formatSeconds(stats.avg), math.floor(stats.stddev or 0))
                    baseTip = baseTip .. string.format('\nObserved range: %s - %s', formatSeconds(stats.lo or 0), formatSeconds(stats.hi or 0))
                elseif stats and stats.n > 0 then
                    baseTip = baseTip .. string.format('\nSamples: %d (need %d for timer)', stats.n, MIN_SAMPLES_FOR_DISPLAY)
                end
                if tonumber(importedSeconds or 0) > 0 then
                    baseTip = baseTip .. '\nCatalogued respawn: ' .. formatSeconds(importedSeconds) .. ' (' .. tostring(importedSource or 'imported') .. ', named timer)'
                end
                if tonumber(entry.chance or 0) > 0 then
                    baseTip = baseTip .. '\nSeed chance: ' .. ux.formatSeedChance(entry.chance)
                end
                if type(entry.ph_names) == 'table' and #entry.ph_names > 0 then
                    -- A named is never a PH; hide tracked nameds (and this point's
                    -- own name) so a wanderer doesn't read as a placeholder.
                    local phList, ownName = {}, tostring(entry.display_name or entry.last_seen_name or ''):lower()
                    for _, name in ipairs(entry.ph_names) do
                        local clean = trim(tostring(name or ''))
                        if clean ~= '' and clean:lower() ~= ownName
                            and not (ux.nameMatchesOtherNamedWatch and ux.nameMatchesOtherNamedWatch(nil, clean)) then
                            table.insert(phList, clean)
                        end
                    end
                    if #phList > 0 then
                        baseTip = baseTip .. '\nImported PHs: ' .. shortText(table.concat(phList, ', '), 90)
                        if #phList > 1 then
                            baseTip = baseTip .. '\nPH candidates share this seed point; tag PHs manually if live behavior differs.'
                        end
                    end
                end
                if liveRow then
                    baseTip = baseTip .. string.format('\nCurrent: L%d %s', tonumber(liveRow.level) or 0, tostring(liveRow.name or ''))
                end
                if tonumber(entry.last_spawn_id or 0) > 0 then
                    baseTip = baseTip .. string.format('\nLast spawn ID: %d', tonumber(entry.last_spawn_id))
                end
                ImGui.SetTooltip(ux.tooltipText(baseTip))
            end
            if ImGui.BeginPopupContextItem('##zone_intel_ctx_' .. intel.key) then
                ux.drawZoneIntelContextMenu(intel)
                ImGui.EndPopup()
            end
            ImGui.TableSetColumnIndex(1); coloredText(stateText, stateColor)
            ImGui.TableSetColumnIndex(2)
            if liveRow then conColoredText(ux.zoneIntelCurrentText(intel, 22), liveRow.level)
            else coloredText('-', 'muted') end
            local hasSeedTimer = tonumber(importedSeconds or 0) > 0
            local sampleN = stats and (tonumber(stats.n) or 0) or 0
            local obsAvg = stats and (tonumber(stats.avg) or 0) or 0
            -- Decide when the observed camp cycle wins over the Alla seed timer.
            -- Alla is trusted by default (usually correct); observed takes over when
            -- it is well-sampled, OR when a few samples strongly disagree (>2x off) --
            -- the latter catches camps Alla mislabeled (e.g. Pyzjn/Varsoon, where the
            -- seed holds the long rare-named interval, not the short PH cycle).
            -- With no seed timer at all (uncatalogued mobs / other servers) the
            -- observed value shows as soon as we have a few samples.
            local trustObserved
            if not hasSeedTimer then
                trustObserved = sampleN >= MIN_SAMPLES_FOR_DISPLAY
            elseif sampleN >= MAX_SAMPLES_PER_MOB then
                trustObserved = true
            elseif sampleN >= EARLY_TIMER_DIVERGENCE_SAMPLES and obsAvg > 0 then
                local ratio = obsAvg / importedSeconds
                trustObserved = ratio <= 0.5 or ratio >= 2.0
            else
                trustObserved = false
            end
            local hasObservedTimer = trustObserved and obsAvg > 0
            local avgText = (hasObservedTimer and ('Obs ' .. formatSeconds(obsAvg)))
                or (hasSeedTimer and formatSeconds(importedSeconds))
                or '-'
            local sampleTarget = hasSeedTimer and MAX_SAMPLES_PER_MOB or MIN_SAMPLES_FOR_DISPLAY
            local sampleText = (stats and stats.n > 0) and (tostring(stats.n) .. '/' .. tostring(sampleTarget))
                or (hasSeedTimer and 'Alla' or ('0/' .. tostring(MIN_SAMPLES_FOR_DISPLAY)))
            ImGui.TableSetColumnIndex(3); ImGui.Text(avgText)
            ImGui.TableSetColumnIndex(4); coloredText(sampleText, hasObservedTimer and 'learned' or (hasSeedTimer and 'etaSoon' or 'muted'))
            ImGui.TableSetColumnIndex(5); ImGui.Text(ux.timeAgo(entry.last_seen))
            local linkedWatch = intel.linkedWatches and intel.linkedWatches[1] and intel.linkedWatches[1].watch
            ImGui.TableSetColumnIndex(6); ux.drawWatchNavCell(locRow, intel.key, { watch = linkedWatch })
        end
        ImGui.EndTable()
    end
end

ux.drawHelpPanel = function()
    if not ux.showHelpPanel then return end

    if not ux._helpPanelLists then
        ux._helpPanelLists = {
            sharing = {
                { '/tmobs export', 'export current zone to exports/' },
                { '/tmobs export all', 'export every zone you have data on' },
                { '/tmobs export <zone>', 'export a specific zone short-name (e.g. gfaydark)' },
                { '/tmobs import <file>', 'import an exported file (filename from exports/)' },
                { '/tmobs importalla [file]', 'import prepared Alla seed data (filename from exports/)' },
                { '/tmobs importalla all', 'import the combined multi-zone bundle (alla_seeds_all.lua)' },
                { '/tmobs importalla preview [file]', 'validate an Alla seed without importing it' },
                { '/tmobs repairalla [zone|all]', 'convert older Alla seed points from named to seed metadata' },
            },
            commands = {
                { '/tmobs', 'restore Turbo Watch and the full search window' },
                { '/tmobs show', 'show full search window' },
                { '/tmobs togglefull', 'show/hide full search window without unloading' },
                { '/tmobs mini | alerts', 'show/hide Turbo Watch' },
                { '/tmobs on | off', 'polling on/off' },
                { '/tmobs navstop', 'stop active MQ navigation' },
                { '/tmobs search <text>', 'filter by name' },
                { '/tmobs clearfilters', 'clear search and structured filters' },
                { '/tmobs named | npc | targetable', 'toggle named/npc/targetable filters' },
                { '/tmobs watches', 'show/hide full watch details panel' },
                { '/tmobs importspawnmaster', 'import current-zone SpawnMaster entries' },
                { '/tmobs importspawnmaster all', 'import every SpawnMaster zone section' },
                { '/tmobs importalla [file]', 'import Alla seed data into Zone Intel' },
                { '/tmobs importalla all', 'import the combined multi-zone bundle (alla_seeds_all.lua)' },
                { '/tmobs importalla preview [file]', 'preview Alla seed counts and warnings' },
                { '/tmobs repairalla [zone|all]', 'repair prior Alla seed classification' },
                { '/tmobs compat [mode]', 'toggle macro bridge vars; target vars are opt-in' },
                { '/tmobs statusvars', 'print current macro bridge values (debug)' },
                { '/tmobs perf', 'write recent timing diagnostics to TurboMobs_perf_<name>.txt' },
                { '/tmobs diag', 'write tester diagnostic snapshot to TurboMobs_diag_<name>.txt' },
                { '/tmobs help', 'show this help' },
                { '/tmobs config', 'open config folder' },
                { '/tmobs exports', 'open/print exports folder' },
            },
        }
    end

    local function helpSlashPair(cmd, desc)
        local c = textColors.learned
        ImGui.PushStyleColor(ImGuiCol.Text, c[1], c[2], c[3], c[4])
        ImGui.Text(cmd)
        ImGui.PopStyleColor()
        if desc and desc ~= '' then
            coloredTextWrapped(desc, 'muted')
        end
    end

    local function helpBulletLabel(label, gloss)
        ImGui.Bullet()
        ImGui.SameLine()
        ImGui.BeginGroup()
        coloredText(label, 'idle')
        if gloss and gloss ~= '' then coloredTextWrapped(gloss, 'muted') end
        ImGui.EndGroup()
    end

    local function helpBulletSlash(cmd, desc)
        ImGui.Bullet()
        ImGui.SameLine()
        ImGui.BeginGroup()
        helpSlashPair(cmd, desc)
        ImGui.EndGroup()
    end

    ImGui.Separator()
    coloredText('TurboMobs Help', 'selected')
    ImGui.Spacing()

    coloredText('Config folder:', 'learned')
    coloredTextWrapped(turboFolder, 'idle')
    if styledButton('Open Folder##help', 'primary', 6, 3, 'Open the TurboMobs config folder in Explorer.') then
        ux.openConfigFolder()
    end
    ImGui.SameLine()
    if styledButton('Copy Path##help', 'neutral', 6, 3, 'Copy the path to your clipboard.') then
        ImGui.SetClipboardText(turboFolder)
        chat('Path copied to clipboard.')
    end

    ImGui.Spacing()
    coloredText('Files in this folder:', 'learned')
    helpBulletLabel('settings.lua', 'UI and filter preferences')
    helpBulletLabel('respawns.lua', 'learned respawn data per zone (one file, all zones)')
    helpBulletLabel('watches.lua', 'saved smart/name watches; ID watches do not persist')
    helpBulletLabel('exports/', 'files exported for sharing')

    ImGui.Spacing()
    coloredText('How learning works:', 'learned')
    coloredTextWrapped('Each time you watch a mob die and respawn, TurboMobs records the gap.', 'idle')
    coloredTextWrapped('Learned timers are keyed to the spawn point when location data is available.', 'idle')
    coloredTextWrapped('After 3 observations, you will see: observed: M:SS (+/-Xs, n=N)', 'idle')
    coloredTextWrapped('Manual timers override learned. Clear the manual to use learned data.', 'idle')
    coloredTextWrapped('The Alerts panel shows timer source, ETA, and sample count.', 'idle')

    ImGui.Spacing()
    coloredText('Sharing respawn data:', 'learned')
    for _, row in ipairs(ux._helpPanelLists.sharing) do
        helpBulletSlash(row[1], row[2])
    end
    coloredTextWrapped('Tip: Bundled named camps auto-load on first in-game session. Use Zone Intel > Import All Zones or /tmobs importalla all to re-import.', 'idle')
    coloredTextWrapped('Import merges with your data. Samples combine; you keep both contributors.', 'idle')
    coloredTextWrapped('If the file is from a different server, you will see a warning but import proceeds.', 'idle')

    ImGui.Spacing()
    coloredText('Watches:', 'learned')
    helpBulletLabel('Watch', 'smart default: remembers the target name and spawn point, then shows UP, PH, Down, or Learning')
    helpBulletLabel('Watch current ID', 'one currently alive NPC only; does not persist')
    helpBulletLabel('Watch all mobs with this name', 'tracks any live mob with the same clean name in this zone')
    helpBulletSlash('/tmobs watch [name]', 'smart-watch by name, or your current target if no name is given')
    helpBulletSlash('/tmobs edit <name>', 'open the watch editor for mode, PH names, location, radius, and timer')

    ImGui.Spacing()
    coloredText('Macros & automation (optional)', 'learned')
    coloredTextWrapped(
        'If you use MQ macros, hotkeys, or setups like E3, TurboMobs can keep a small set of MQ global variables updated — '
            .. 'think of them as named slots other scripts can read (for example whether your target is on your watch list).',
        'idle'
    )
    coloredTextWrapped(
        'They are not spell-window "TLO" objects; they update only when needed so chat is not spammed. Defaults are on.',
        'idle'
    )
    coloredTextWrapped('Examples: TurboMobs_HasTarget, TurboMobs_TargetWatched, TurboMobs_TargetName (see /tmobs statusvars).', 'muted')
    helpBulletSlash('/tmobs compat [on|off|target|spawnmaster]', 'enable/disable bridge vars; target vars are opt-in')
    helpBulletSlash('/tmobs statusvars', 'print every TurboMobs_* value for troubleshooting')

    ImGui.Spacing()
    coloredText('Commands:', 'learned')
    ImGui.Indent(8)
    for _, row in ipairs(ux._helpPanelLists.commands) do
        helpSlashPair(row[1], row[2])
    end
    ImGui.Unindent(8)

    ImGui.Spacing()
    if styledButton('Close Help', 'neutral', nil, nil, 'Hide this help panel.') then
        ux.showHelpPanel = false
    end
end

ux.drawExportImportPanel = function()
    coloredText('Export / Import learned respawns', 'muted')
    coloredTextWrapped('Share TurboMobs timer files from the exports folder. Import merges with your current timers.', 'muted')

    coloredText('Create a share file', 'learned')
    if styledButton('Export Current', 'primary', 6, 3, 'Export learned respawn data for this zone.') then
        ux.exportRespawns(currentZoneShort())
    end
    ImGui.SameLine()
    if styledButton('Export All', 'primary', 6, 3, 'Export learned respawn data for every zone.') then
        ux.exportRespawns('all')
        ux.exportFileList = nil
    end
    ImGui.SameLine()
    if styledButton('Open Exports', 'neutral', 6, 3, 'Open the TurboMobs exports folder.') then
        ux.openExportsFolder()
    end

    ImGui.SetNextItemWidth(160)
    local newZone, _ = ImGui.InputText('Custom export zone/all##exportZone', exportInputZone)
    exportInputZone = newZone or ''
    ImGui.SameLine()
    if styledButton('Export Custom', 'primary', 6, 3, 'Export learned respawn data. Empty = current zone. "all" = every zone.') then
        local z = trim(exportInputZone)
        if z == '' then z = currentZoneShort() end
        ux.exportRespawns(z)
        ux.exportFileList = nil
    end

    ImGui.Spacing()
    coloredText('Import a TurboMobs share file', 'warn')
    ux.drawSharePanel()
    ImGui.Spacing()
    coloredText('Or type a filename:', 'muted')
    if importInputFile == '' and ux.latestExportFile == '' then
        ux.latestExportFile = ux.latestExportFilename()
    end
    if styledButton('Use Latest', 'neutral', 6, 3, 'Fill the filename box with the newest .lua file in the exports folder.') then
        ux.latestExportFile = ux.latestExportFilename()
        importInputFile = ux.latestExportFile
        importStatusMsg = ux.latestExportFile ~= '' and ('Selected latest export: ' .. ux.latestExportFile) or 'No .lua exports found.'
    end
    ImGui.SameLine()
    if styledButton('Latest Alla', 'tools', 6, 3, 'Fill the filename box with the newest alla_seed_*.lua file in exports/.') then
        ux.latestExportFile = ux.latestAllaSeedFilename()
        importInputFile = ux.latestExportFile
        importStatusMsg = ux.latestExportFile ~= '' and ('Selected latest Alla seed: ' .. ux.latestExportFile) or 'No alla_seed_*.lua files found.'
    end
    ImGui.SameLine()
    if styledButton('Open Exports##import_open_exports', 'neutral', 6, 3, 'Open the folder where TurboMobs imports and exports share files.') then
        ux.openExportsFolder()
    end
    ImGui.SetNextItemWidth(220)
    local newFile, _ = ImGui.InputText('Share filename##importFile', importInputFile)
    importInputFile = newFile or ''
    ImGui.SameLine()
    if styledButton('Import File', 'warn', 6, 3, 'Import a file from the exports/ folder. Merges with your data.') then
        if importInputFile ~= '' then ux.importRespawns(importInputFile) end
    end
    ImGui.SameLine()
    if styledButton('Preview Alla', 'tools', 6, 3, 'Validate the selected Alla seed. Blank filename previews the bundled/current-zone seed.') then
        ux.previewAllaSeed(importInputFile)
    end
    ImGui.SameLine()
    if styledButton('Import Alla Seed', 'tools', 6, 3, 'Import prepared Alla seed data. Blank filename imports the bundled/current-zone seed.') then
        ux.requestAllaImport(importInputFile)
    end

    local spawnMasterPath = configRoot .. '/MQ2SpawnMaster.ini'
    ImGui.Spacing()
    coloredText('Import SpawnMaster watches', 'tools')
    coloredText('Source: ' .. spawnMasterPath, pathExists(spawnMasterPath) and 'learned' or 'muted')
    local smLoaded = ux.spawnMasterPluginLoaded()
    coloredText('SpawnMaster plugin: ' .. (smLoaded and 'loaded' or 'not loaded'), smLoaded and 'warn' or 'muted')
    if ImGui.IsItemHovered() then
        ImGui.SetTooltip('TurboMobs imports from MQ2SpawnMaster.ini. The plugin does not need to be loaded for import.')
    end
    coloredTextWrapped('After importing, disable SpawnMaster alerts or unload MQ2SpawnMaster to avoid duplicate alerts.', 'muted')
    if styledButton('Import Current Zone', 'tools', 6, 3, 'Import current-zone entries from MQ2SpawnMaster.ini as TurboMobs watches.') then
        ux.importSpawnMaster()
    end
    ImGui.SameLine()
    if styledButton('Import All Zones', 'tools', 6, 3, 'Import every zone section from MQ2SpawnMaster.ini as zone-scoped TurboMobs watches.') then
        ux.importSpawnMaster(true)
    end
    ImGui.NewLine()
    if styledButton('Open Config', 'neutral', 6, 3, 'Open the MacroQuest Config folder where MQ2SpawnMaster.ini normally lives.') then
        ux.shellOpenExternal(configRoot:gsub('/', '\\'))
    end

    if importStatusMsg ~= '' then coloredText(importStatusMsg, 'muted') end
end

ux.drawSearchPerformanceBanner = function()
    local raw = #(allSpawns or {})
    local visible = #(spawns or {})
    if raw < 1 then return end
    if not ux.liveSearch and raw < 80 and visible < 50 then return end
    coloredTextWrapped(
        "Damn, that's a lotta mobs! Keeping Search open is heavy. Once you find what you're looking for, swap to one of the other tabs or to using Turbo Watch.",
        'etaSoon'
    )
    ImGui.Spacing()
end

ux.drawAnnounceSettings = function()
    coloredText('Alerts / Announcements', 'muted')
    local zone = currentZoneShort()
    local disabledHere = ux.disabledZones[zone] == true
    local newDisabledHere, disabledChanged = ImGui.Checkbox('Disable alerts in this zone', disabledHere)
    if disabledChanged then
        ux.disabledZones[zone] = newDisabledHere or nil
        saveSettings()
    end
    if ImGui.IsItemHovered() then
        ImGui.SetTooltip('Suppresses popup wakeups, sounds, and announce commands in this zone. The window still works.')
    end

    local soundValue, soundChanged = ImGui.Checkbox('Sound on respawn', respawnSound)
    if soundChanged then respawnSound = soundValue; saveSettings() end
    if ImGui.IsItemHovered() then
        ImGui.SetTooltip('Only plays after TurboMobs sees a watched mob go down and then come back up. Zone-in mobs that are already up stay quiet.')
    end

    local echoValue, echoChanged = ImGui.Checkbox('Echo to chat log', alertEcho)
    if echoChanged then alertEcho = echoValue; saveSettings() end

    local popupValue, popupChanged = ImGui.Checkbox('Center-screen popup', ux.spawnPopup)
    if popupChanged then ux.spawnPopup = popupValue; saveSettings() end
    if ImGui.IsItemHovered() then
        ImGui.SetTooltip('Shows a SpawnMaster-style on-screen popup only when a watched mob respawns.')
    end

    if not ux.settingsAdvanced then return end
    if not ImGui.CollapsingHeader('Alert details##tmobs_alert_details_v2') then return end
    coloredTextWrapped('Sound file, announce command, and popup command details. Defaults are fine for most testers.', 'muted')

    ImGui.SetNextItemWidth(90)
    local cooldownSec, cooldownChanged = ImGui.InputInt('Sound cooldown (sec)', math.max(1, math.floor((tonumber(ux.respawnSoundCooldownMs) or 1500) / 1000)))
    if cooldownChanged then
        cooldownSec = math.max(1, math.min(30, tonumber(cooldownSec) or 2))
        ux.respawnSoundCooldownMs = math.floor(cooldownSec * 1000)
        saveSettings()
    end
    if ImGui.IsItemHovered() then
        ImGui.SetTooltip('Minimum time between respawn sounds. Prevents stacked alerts from playing a dozen sounds at once.')
    end

    ImGui.SetNextItemWidth(220)
    local newSoundPath, soundPathChanged = ImGui.InputText('Sound path', respawnSoundPath)
    if soundPathChanged then
        respawnSoundPath = newSoundPath or ''
    end
    if ImGui.IsItemDeactivatedAfterEdit() then
        saveSettings()
    end
    if ImGui.IsItemHovered() then
        ImGui.SetTooltip(
            'Folder prefix relative to your EQ install directory.\n' ..
            'Project Lazarus default: AudioTriggers/default/\n' ..
            'Stock EQ alternative: sounds/\n' ..
            'Leave blank to put the sound file directly in your EQ root. Press ENTER to save choice.'
            
        )
    end

    ImGui.SetNextItemWidth(140)
    local newSoundName, soundNameChanged = ImGui.InputText('Sound name', respawnSoundName)
    if soundNameChanged then
        respawnSoundName = newSoundName or ''
    end
    if ImGui.IsItemDeactivatedAfterEdit() then
        saveSettings()
    end
    if ImGui.IsItemHovered() then
        ImGui.SetTooltip(
            'Sound file name (.wav auto-appended if omitted).\n' ..
            'Examples on Project Lazarus: Alert1, Alert2, Alert3, Alert4, Alert5\n' ..
            'Leave blank to use the plain system /beep.'
        )
    end
    ImGui.SameLine()
    if styledButton('Test Sound', 'neutral', 5, 2, 'Play the configured sound now.') then playRespawnSound() end
    local beepArg = buildBeepArg()
    coloredText('Plays: ' .. (beepArg and ('/beep ' .. beepArg) or '/beep (system beep)'), 'muted')

    ImGui.SetNextItemWidth(90)
    local newAnnounceMethod, announceChanged = ImGui.InputText('Announce via', announceMethod)
    if announceChanged then
        announceMethod = newAnnounceMethod or '/echo'
    end
    if ImGui.IsItemDeactivatedAfterEdit() then
        saveSettings()
    end
    if ImGui.IsItemHovered() then
        ImGui.SetTooltip('Command used for watch/spawn announcements. Default /echo keeps it in the MQ window; examples: /g, /rs, /bc')
    end

    ImGui.SetNextItemWidth(90)
    local newPopupCommand, popupCommandChanged = ImGui.InputText('Popup cmd', ux.spawnPopupCommand or '/popup')
    if popupCommandChanged then
        ux.spawnPopupCommand = newPopupCommand or '/popup'
    end
    if ImGui.IsItemDeactivatedAfterEdit() then
        saveSettings()
    end
    if ImGui.IsItemHovered() then
        ImGui.SetTooltip('Default /popup. Advanced users can change this if their MQ build uses a different on-screen text command.')
    end
end

ux.optionList = function(fieldName, preferred)
    local seen = {}
    local options = {'Any'}
    if preferred then
        for _, v in ipairs(preferred) do
            local value = trim(tostring(v or ''))
            if value ~= '' and not seen[value:lower()] then
                seen[value:lower()] = true
                table.insert(options, value)
            end
        end
    end
    for _, row in ipairs(allSpawns or {}) do
        local value = trim(tostring(row[fieldName] or ''))
        if value ~= '' and value ~= 'Unknown' and not seen[value:lower()] then
            seen[value:lower()] = true
            table.insert(options, value)
        end
    end
    table.sort(options, function(a, b)
        if a == 'Any' then return true end
        if b == 'Any' then return false end
        return a:lower() < b:lower()
    end)
    return options
end

ux.filterCombo = function(label, current, options, width)
    ImGui.SetNextItemWidth(width or 100)
    local display = current ~= '' and current or 'Any'
    local changed, nextValue = false, current
    if ImGui.BeginCombo(label, display) then
        for _, option in ipairs(options or {'Any'}) do
            local value = option == 'Any' and '' or option
            if ImGui.Selectable(option, value == current) then
                changed = true
                nextValue = value
            end
        end
        ImGui.EndCombo()
    end
    return nextValue, changed
end

ux.filterText = function(label, value, width)
    ImGui.SetNextItemWidth(width or 100)
    local newValue, changed = ImGui.InputText(label, value or '')
    if changed then
        value = newValue or ''
    end
    return value, changed
end

ux.contentAvailX = function(default)
    local v = (ImGui.GetContentRegionAvail())
    if type(v) == 'number' then return v end
    if type(v) == 'table' then return tonumber(v.x or v.X or v[1]) or default end
    return default or 520
end

ux.filterInput = function(id, hint, value)
    local nextValue, changed
    if ImGui.InputTextWithHint then
        nextValue, changed = ImGui.InputTextWithHint(id, hint, tostring(value or ''))
    else
        nextValue, changed = ImGui.InputText(id, tostring(value or ''))
    end
    local active = (ImGui.IsItemActive and ImGui.IsItemActive()) or false
    if changed then value = nextValue or '' end
    return value, changed, active
end

ux.drawFilterBand = function()
    ux.normalizeLevelFilters()
    local textActive = false
    local textChanged = false
    local lockInputs = (ux.inputsLocked == true) and (ImGui.BeginDisabled ~= nil) and (ImGui.EndDisabled ~= nil)
    local function beginLock() if lockInputs then ImGui.BeginDisabled() end end
    local function endLock() if lockInputs then ImGui.EndDisabled() end end
    local avail = ux.contentAvailX(560)
    local gap = ImGui.GetStyle().ItemSpacing.x

    local nameW = math.max(180, avail - 4)
    beginLock()
    ImGui.SetNextItemWidth(nameW)
    local newSearch, changedSearch
    if ImGui.InputTextWithHint then
        newSearch, changedSearch = ImGui.InputTextWithHint('##mob_search_fb', 'Name search', searchText)
    else
        newSearch, changedSearch = ImGui.InputText('##mob_search_fb', searchText)
    end
    textActive = textActive or ((ImGui.IsItemActive and ImGui.IsItemActive()) or false)
    if changedSearch then searchText = newSearch or ''; textChanged = true end
    endLock()
    if styledButton(namedOnly and 'Nameds' or 'All', namedOnly and 'start' or 'neutral', 8, 3, 'Nameds: only show mobs that look named. All: show every matching mob.') then
        namedOnly = not namedOnly
        if namedOnly then ux.namedOrPHOnly = false end
        ux.searchPage = 1
        ux.refilterSearchRows()
        saveSettings()
    end
    ImGui.SameLine()
    if styledButton(ux.namedOrPHOnly and 'Named/PH' or 'Named+PH', ux.namedOrPHOnly and 'start' or 'neutral', 8, 3, 'Show only named NPCs or current placeholder mobs occupying watched spawn points.') then
        ux.namedOrPHOnly = not ux.namedOrPHOnly
        if ux.namedOrPHOnly then namedOnly = false end
        ux.searchPage = 1
        ux.refilterSearchRows()
        saveSettings()
    end
    ImGui.SameLine()
    if styledButton('Clear', 'neutral', 8, 3, 'Clear search text and temporary filters. Keeps targetable/NPC/include preferences.') then
        ux.clearSearchFilters()
    end
    ImGui.SameLine()
    if styledButton(ux.liveSearch and 'Live' or 'Lock', ux.liveSearch and 'start' or 'neutral', 8, 3,
        ux.liveSearch and 'Live Search ON: Search rows refresh automatically (turns off ~1 min after leaving this tab).' or 'Stable Search: watches refresh in the background; press Refresh to rebuild Search rows.') then
        ux.liveSearch = not ux.liveSearch
        if ux.liveSearch then ux.refreshSearchNow({ suppressAlerts = true }) end
        saveSettings()
    end
    ImGui.SameLine()
    if styledButton(ux.inputsLocked and 'Inputs Locked' or 'Inputs Open', ux.inputsLocked and 'warn' or 'accent', 8, 3,
        ux.inputsLocked and 'Filter text/number boxes are locked so they cannot grab your keyboard (no accidental movement capture). Click to enable editing.' or 'Filter boxes are editable. Click to lock them so they cannot accidentally capture keyboard input.') then
        ux.inputsLocked = not ux.inputsLocked
        saveSettings()
    end

    local active
    local filterW = math.max(92, math.floor((avail - gap * 3) / 4))
    local numberW = math.max(58, math.floor((avail - gap * 2) / 3))

    beginLock()
    ImGui.SetNextItemWidth(filterW)
    ux.typeFilter, changedSearch, active = ux.filterInput('##tmobs_type_filter', 'Type', ux.typeFilter)
    textChanged = textChanged or changedSearch; textActive = textActive or active
    ImGui.SameLine(0, gap)
    ImGui.SetNextItemWidth(filterW)
    ux.bodyFilter, changedSearch, active = ux.filterInput('##tmobs_body_filter', 'Body', ux.bodyFilter)
    textChanged = textChanged or changedSearch; textActive = textActive or active
    ImGui.SameLine(0, gap)
    ImGui.SetNextItemWidth(filterW)
    ux.raceFilter, changedSearch, active = ux.filterInput('##tmobs_race_filter', 'Race', ux.raceFilter)
    textChanged = textChanged or changedSearch; textActive = textActive or active
    ImGui.SameLine(0, gap)
    ImGui.SetNextItemWidth(filterW)
    ux.classFilter, changedSearch, active = ux.filterInput('##tmobs_class_filter', 'Class', ux.classFilter)
    textChanged = textChanged or changedSearch; textActive = textActive or active
    endLock()

    if textChanged then lastSearchEditMs = nowMs() end
    if not textActive and lastSearchEditMs and lastSearchEditMs > 0 and nowMs() - lastSearchEditMs > 250 then
        ux.searchPage = 1
        ux.refilterSearchRows()
        saveSettings()
        lastSearchEditMs = 0
    end

    beginLock()
    ImGui.SetNextItemWidth(numberW)
    local newMinLevel, changedMinLevel = ImGui.InputInt('Min Lv##min_level', minLevel, 0)
    if changedMinLevel then minLevel = math.max(0, math.min(999, tonumber(newMinLevel) or minLevel)); ux.normalizeLevelFilters(); ux.searchPage = 1; ux.refilterSearchRows(); saveSettings() end
    ImGui.SameLine(0, gap)
    ImGui.SetNextItemWidth(numberW)
    local newMaxLevel, changedMaxLevel = ImGui.InputInt('Max Lv##max_level', maxLevel, 0)
    if changedMaxLevel then maxLevel = math.max(1, math.min(999, tonumber(newMaxLevel) or maxLevel)); ux.normalizeLevelFilters(); ux.searchPage = 1; ux.refilterSearchRows(); saveSettings() end
    ImGui.SameLine(0, gap)
    ImGui.SetNextItemWidth(numberW)
    local newMaxDist, changedMaxDist = ImGui.InputInt('Max Dist##max_distance', maxDistance, 0)
    if changedMaxDist then maxDistance = math.max(0, tonumber(newMaxDist) or maxDistance); ux.searchPage = 1; ux.refilterSearchRows(); saveSettings() end
    endLock()
end

ux.drawSafeZoneSearchPause = function()
    coloredTextWrapped('Safe-zone scan pause is active. Live spawn scanning and Watch updates are paused here.', 'stopped')
    coloredTextWrapped('Use Scan Here only when you need current-zone spawn data in this hub zone.', 'muted')
    if styledButton('Scan Here', 'primary', 9, 4, 'Temporarily allow scanning in this safe zone until you zone or reload.') then
        ux.safeZoneScanOverride = true
        ux.refreshSearchNow({ suppressAlerts = true })
        saveSettings()
    end
    ImGui.SameLine()
    if styledButton('Show Turbo Watch', ux.showAlertPopup and 'tools' or 'primary', 9, 4, 'Open the Turbo Watch pop-out.') then
        ux.showWatchWindow()
    end
    ImGui.SameLine()
    ux.drawTargetActionButton('safe')
    ImGui.SameLine()
    ux.drawAssignPHButton('safe')
end


ux.drawFullWindow = function()
    ImGui.SetNextWindowSizeConstraints(520, 380, 980, 2800)
    ux.applyWindowGeometry('full', 650, 520, ImGuiCond.FirstUseEver)

    ImGui.PushStyleVar(ImGuiStyleVar.WindowRounding, 5)
    ImGui.PushStyleVar(ImGuiStyleVar.WindowBorderSize, 2)
    ImGui.PushStyleColor(ImGuiCol.Border, 0.72, 0.56, 0.24, 0.95)
    ImGui.PushStyleColor(ImGuiCol.TitleBg, 0.08, 0.11, 0.16, 1.00)
    ImGui.PushStyleColor(ImGuiCol.TitleBgActive, 0.10, 0.14, 0.20, 1.00)
    ImGui.PushStyleColor(ImGuiCol.TitleBgCollapsed, 0.08, 0.11, 0.16, 1.00)

    local open = showWindow
    open = ImGui.Begin(string.format('%s v%s', SCRIPT_NAME, VERSION), open, ImGuiWindowFlags.NoTitleBar or 0)
    showWindow = open

    if not open then
        ux.hideFullWindow()
        ux.captureWindowGeometry('full')
        ImGui.End()
        ImGui.PopStyleColor(4); ImGui.PopStyleVar(2)
        return
    end

    ux.chromeDragApplyActive(ux.chromeDragState)
    ux.drawFullWindowChrome()

    local tabStylePushed = pushActiveTabStyle()
    if ImGui.BeginTabBar('##turbomobs_full_tabs') then
        if ImGui.BeginTabItem('Search') then
            ux.activeFullTab = 'search'
            -- Init column-visibility flags (runtime state, not persisted)
            if ux.qsShowTrueName  == nil then ux.qsShowTrueName  = false end
            if ux.qsColShowType   == nil then ux.qsColShowType   = false end
            if ux.qsColShowBody   == nil then ux.qsColShowBody   = false end
            if ux.qsColShowRace   == nil then ux.qsColShowRace   = false end
            if ux.qsColShowClass  == nil then ux.qsColShowClass  = false end

            local safePaused = ux.safeZoneScanPaused()
            if safePaused then
                ux.drawSafeZoneSearchPause()
            else
                local avail = ux.contentAvailX(500)
                local gap = ImGui.GetStyle().ItemSpacing.x

                -- ── Search bar ──────────────────────────────────────────────
                local clearW = 46
                ImGui.SetNextItemWidth(avail - clearW - gap)
                local newSearch, changedSearch
                if ImGui.InputTextWithHint then
                    newSearch, changedSearch = ImGui.InputTextWithHint('##mob_search', 'Name search...', searchText)
                else
                    newSearch, changedSearch = ImGui.InputText('##mob_search', searchText)
                end
                if changedSearch then
                    searchText = newSearch or ''
                    ux.qsSortCol = 'dist'; ux.qsSortDir = 1
                    ux.quickSearchRev = nil
                    if not (ux.rebuildQuickSearchRowsFromSnapshot and ux.rebuildQuickSearchRowsFromSnapshot()) then
                        ux.quickSearchRows = nil
                    end
                end
                ImGui.SameLine(0, gap)
                if styledButton('Clear', 'neutral', 7, 3, 'Clear name filter and N+PH toggle') then
                    searchText = ''; ux.qsNamedOnly = false; ux.qsNamedPHOnly = false
                    ux.qsSortCol = 'dist'; ux.qsSortDir = 1
                    ux.quickSearchRev = nil
                    if not (ux.rebuildQuickSearchRowsFromSnapshot and ux.rebuildQuickSearchRowsFromSnapshot()) then
                        ux.quickSearchRows = nil
                    end
                end

                -- ── ▾ Filters ───────────────────────────────────────────────
                if ImGui.CollapsingHeader('Filters##qs_adv') then
                    ux.normalizeLevelFilters()
                    local lockInputs = (ux.inputsLocked == true) and (ImGui.BeginDisabled ~= nil) and (ImGui.EndDisabled ~= nil)
                    local function bl() if lockInputs then ImGui.BeginDisabled() end end
                    local function el() if lockInputs then ImGui.EndDisabled() end end
                    local favail = ux.contentAvailX(500)
                    local fgap = ImGui.GetStyle().ItemSpacing.x
                    local halfW = math.max(80, math.floor((favail - fgap) / 2))
                    local fChanged, fActive, classChanged, ch, ac = false, false, false, false, false
                    bl()
                    -- Row 1: Type | Body
                    ImGui.SetNextItemWidth(halfW)
                    ux.typeFilter, ch, ac = ux.filterInput('##qs_type_filter', 'Type', ux.typeFilter)
                    fChanged = fChanged or ch; fActive = fActive or ac
                    ImGui.SameLine(0, fgap)
                    ImGui.SetNextItemWidth(halfW)
                    ux.bodyFilter, ch, ac = ux.filterInput('##qs_body_filter', 'Body', ux.bodyFilter)
                    fChanged = fChanged or ch; fActive = fActive or ac
                    -- Row 2: Race | Class
                    ImGui.SetNextItemWidth(halfW)
                    ux.raceFilter, ch, ac = ux.filterInput('##qs_race_filter', 'Race', ux.raceFilter)
                    fChanged = fChanged or ch; fActive = fActive or ac
                    ImGui.SameLine(0, fgap)
                    ImGui.SetNextItemWidth(halfW)
                    ux.classFilter, ch, ac = ux.filterInput('##qs_class_filter', 'Class', ux.classFilter)
                    fChanged = fChanged or ch; fActive = fActive or ac; classChanged = classChanged or ch
                    el()
                    if fChanged then
                        lastSearchEditMs = nowMs()
                        ux.searchPage = 1
                        ux.quickSearchRev = nil
                        if ux.rebuildQuickSearchRowsFromSnapshot then ux.rebuildQuickSearchRowsFromSnapshot() end
                        if classChanged and trim(ux.classFilter or '') ~= '' then
                            ux.quickSearchClassRefreshPending = true
                        elseif classChanged then
                            ux.quickSearchClassRefreshPending = false
                        end
                    end
                    if not fActive and lastSearchEditMs and lastSearchEditMs > 0 and nowMs() - lastSearchEditMs > 250 then
                        -- Invalidate quickSearch cache so the browse/filtered loops pick up new needles.
                        -- (activeFilterNeedles is synced each frame in the polling function.)
                        ux.searchPage = 1
                        ux.quickSearchRev = nil
                        if ux.quickSearchClassRefreshPending == true and trim(ux.classFilter or '') ~= '' then
                            ux.quickSearchClassRefreshPending = false
                            ux.refreshSearchNow({ suppressAlerts = true })
                        elseif ux.rebuildQuickSearchRowsFromSnapshot then
                            ux.rebuildQuickSearchRowsFromSnapshot()
                        end
                        saveSettings(); lastSearchEditMs = 0
                    end
                    bl()
                    -- Row 3: Level [min] to [max]
                    local lvW = math.max(60, math.floor((favail - fgap * 2 - 18) / 3))
                    ImGui.SetNextItemWidth(lvW)
                    local nMin, cMin = ImGui.InputInt('##qs_min_lv', minLevel, 0)
                    if cMin then
                        minLevel = math.max(0, math.min(999, tonumber(nMin) or minLevel))
                        ux.normalizeLevelFilters(); ux.searchPage = 1; ux.quickSearchRev = nil
                        if ux.rebuildQuickSearchRowsFromSnapshot then ux.rebuildQuickSearchRowsFromSnapshot() end
                        saveSettings()
                    end
                    ImGui.SameLine(0, fgap)
                    ImGui.PushStyleColor(ImGuiCol.Text, 0.55, 0.55, 0.55, 1.0)
                    ImGui.TextUnformatted('to')
                    ImGui.PopStyleColor()
                    ImGui.SameLine(0, fgap)
                    ImGui.SetNextItemWidth(lvW)
                    local nMax, cMax = ImGui.InputInt('##qs_max_lv', maxLevel, 0)
                    if cMax then
                        maxLevel = math.max(1, math.min(999, tonumber(nMax) or maxLevel))
                        ux.normalizeLevelFilters(); ux.searchPage = 1; ux.quickSearchRev = nil
                        if ux.rebuildQuickSearchRowsFromSnapshot then ux.rebuildQuickSearchRowsFromSnapshot() end
                        saveSettings()
                    end
                    ImGui.SameLine(0, fgap)
                    ImGui.PushStyleColor(ImGuiCol.Text, 0.55, 0.55, 0.55, 1.0)
                    ImGui.TextUnformatted('Level')
                    ImGui.PopStyleColor()
                    el()
                end

                -- ── ▾ Include ───────────────────────────────────────────────
                if ImGui.CollapsingHeader('Include##qs_include') then
                    local incChanged = false
                    -- NPC is always the base — render as plain dimmed text, not a clickable widget
                    ImGui.PushStyleColor(ImGuiCol.Text, 0.45, 0.45, 0.45, 1.0)
                    ImGui.TextUnformatted('[x] NPC')
                    ImGui.PopStyleColor()
                    ImGui.SameLine()
                    local newPC, cPC = ImGui.Checkbox('PC##qs_pc', includePlayers)
                    if cPC then includePlayers = newPC; incChanged = true end
                    ImGui.SameLine()
                    local newPets, cPets = ImGui.Checkbox('Pets##qs_pets', includePets)
                    if cPets then includePets = newPets; incChanged = true end
                    ImGui.SameLine()
                    local newCorpse, cCorpse = ImGui.Checkbox('Corpses##qs_corpse', includeCorpses)
                    if cCorpse then includeCorpses = newCorpse; incChanged = true end
                    ImGui.SameLine()
                    -- Untargetable: row.targetable is always fetched in search scans; toggling
                    -- this invalidates the QS cache for an instant refilter (no rescan needed).
                    local showUntargetable = not (ux.targetableOnly == true)
                    local newUT, cUT = ImGui.Checkbox('Untargetable##qs_ut', showUntargetable)
                    if cUT then
                        ux.targetableOnly = not newUT
                        ux.searchPage = 1; ux.quickSearchRev = nil
                        if ux.rebuildQuickSearchRowsFromSnapshot then ux.rebuildQuickSearchRowsFromSnapshot() end
                        saveSettings()
                    end
                    if incChanged then
                        ux.searchPage = 1
                        ux.quickSearchRev = nil   -- force immediate QS rebuild from cached byId
                        if ux.rebuildQuickSearchRowsFromSnapshot then ux.rebuildQuickSearchRowsFromSnapshot() end
                        saveSettings()
                    end
                end

                -- ── ▾ Columns ───────────────────────────────────────────────
                if ImGui.CollapsingHeader('Columns##qs_cols') then
                    local tn, cTn = ImGui.Checkbox('True Name##qs_col_tn', ux.qsShowTrueName == true)
                    if cTn then ux.qsShowTrueName = tn end
                    ImGui.SameLine()
                    local tp, cTp = ImGui.Checkbox('Type##qs_col_type', ux.qsColShowType == true)
                    if cTp then ux.qsColShowType = tp end
                    ImGui.SameLine()
                    local bd, cBd = ImGui.Checkbox('Body##qs_col_body', ux.qsColShowBody == true)
                    if cBd then ux.qsColShowBody = bd end
                    ImGui.SameLine()
                    local rc, cRc = ImGui.Checkbox('Race##qs_col_race', ux.qsColShowRace == true)
                    if cRc then ux.qsColShowRace = rc end
                    ImGui.SameLine()
                    local cl, cCl = ImGui.Checkbox('Class##qs_col_class', ux.qsColShowClass == true)
                    if cCl then ux.qsColShowClass = cl end
                end

                -- ── Status bar ──────────────────────────────────────────────
                local rowCount = type(ux.quickSearchRows) == 'table' and #ux.quickSearchRows or 0
                local displayMode = ux.qsShowTrueName and 'Name + True' or 'Name'
                ImGui.PushStyleColor(ImGuiCol.Text, 0.55, 0.55, 0.55, 1.0)
                ImGui.TextUnformatted('Scanner: ')
                ImGui.PopStyleColor()
                ImGui.SameLine(0, 0)
                if enabled then
                    ImGui.PushStyleColor(ImGuiCol.Text, 0.4, 0.9, 0.45, 1.0)
                    ImGui.TextUnformatted('ON')
                else
                    ImGui.PushStyleColor(ImGuiCol.Text, 1.0, 0.55, 0.3, 1.0)
                    ImGui.TextUnformatted('PAUSED')
                end
                ImGui.PopStyleColor()
                -- Click ON/PAUSED text to toggle scanner
                if ImGui.IsItemClicked() then
                    enabled = not enabled
                    if enabled then ux.refreshWatchesNow() end
                    saveSettings()
                end
                if ImGui.IsItemHovered() then
                    ImGui.SetTooltip(enabled and 'Click to pause tracking' or 'Click to resume tracking')
                end
                ImGui.SameLine(0, 0)
                ImGui.PushStyleColor(ImGuiCol.Text, 0.55, 0.55, 0.55, 1.0)
                ImGui.TextUnformatted(string.format('  |  %d mobs found  |  Display: %s', rowCount, displayMode))
                ImGui.PopStyleColor()

                -- ── Action row ──────────────────────────────────────────────
                ux.drawTargetActionButton('full')
                ImGui.SameLine()
                ux.drawAssignPHButton('full')
                ImGui.SameLine()
                if styledButton('Name/True Name', ux.qsShowTrueName and 'tools' or 'neutral', 7, 4, 'Toggle True Name column visibility') then
                    ux.qsShowTrueName = not ux.qsShowTrueName
                end
                ImGui.SameLine()
                if styledButton('N+PH: ' .. (ux.qsNamedPHOnly and 'On' or 'Off'), ux.qsNamedPHOnly and 'start' or 'neutral', 7, 4, 'Show named and placeholder mobs only') then
                    ux.qsNamedPHOnly = not ux.qsNamedPHOnly
                    if ux.qsNamedPHOnly then ux.qsNamedOnly = false end
                    ux.quickSearchRev = nil
                    if not (ux.rebuildQuickSearchRowsFromSnapshot and ux.rebuildQuickSearchRowsFromSnapshot()) then
                        ux.quickSearchRows = nil
                    end
                end
                ImGui.SameLine()
                if styledButton('Refresh', 'primary', 9, 4, 'Rebuild spawn list now.') then
                    ux.safeZoneScanOverride = true
                    ux.refreshSearchNow({ suppressAlerts = true })
                end
                ImGui.SameLine()
                if styledButton('Clear HL', 'neutral', 7, 4, 'Remove all /highlight overlays on the map.') then
                    mq.cmd('/highlight reset')
                end

                ux.drawWatchAssignmentPanel()
                ImGui.Separator()
                ux.drawQuickSearch()
            end
            ImGui.EndTabItem()
        end

        if ImGui.BeginTabItem('Watches') then
            ux.activeFullTab = 'watches'
            coloredTextWrapped(
                ux.showAlertPopup
                    and 'Turbo Watch is also open. This full Watches table remains available for filters, zone picker, and saved-watch management.'
                    or 'Turbo Watch is the pop-out watch window. Keep it open for alerts while using the full Watches table here.',
                'muted'
            )
            if styledButton(ux.showAlertPopup and 'Hide Turbo Watch' or 'Show Turbo Watch', 'primary', nil, nil, 'Show or hide the separate Turbo Watch window.') then
                ux.toggleWatchWindow()
            end
            ImGui.SameLine()
            ux.drawTargetActionButton('watches')
            ImGui.SameLine()
            ux.drawAssignPHButton('watches')
            ux.drawWatchByNamePanel()
            ux.drawWatchAssignmentPanel()
            if ux.safeZoneScanPaused() then
                coloredTextWrapped('Paused in safe zone. Use Scan Here to update this zone. Existing watches stay loaded.', 'stopped')
            end
            ux.drawAlertsPanel(true)
            ImGui.EndTabItem()
        end

        if ImGui.BeginTabItem('Zone Intel') then
            ux.activeFullTab = 'zoneintel'
            ux.drawZoneIntelTab()
            ImGui.EndTabItem()
        end

        if ImGui.BeginTabItem('Settings') then
            ux.activeFullTab = 'settings'
            coloredTextWrapped('Normal setup lives here. Advanced tools are for imports, data repair, and tester troubleshooting.', 'muted')
            if styledButton(ux.settingsAdvanced and 'Hide advanced tools' or 'Show advanced tools', ux.settingsAdvanced and 'warn' or 'neutral', nil, nil, 'Show imports, scan tuning, table columns, and debug controls.') then
                ux.settingsAdvanced = not ux.settingsAdvanced
                saveSettings()
            end
            ImGui.Spacing()

            if ImGui.CollapsingHeader('General', (ImGuiTreeNodeFlags and ImGuiTreeNodeFlags.DefaultOpen) or 0) then
                if styledButton('Open Folder', 'primary', nil, nil, 'Open the TurboMobs config folder in Explorer.') then ux.openConfigFolder() end
                ImGui.SameLine()
            
                if styledButton('Optimize Settings', 'accent', nil, nil, 'Restores the recommended low-lag defaults while keeping PH/named learning, watch timers, and respawn saving active.') then
                    ux.applyPerformanceMode()
                end
                ImGui.SameLine()
            
                if styledButton(ux.showHelpPanel and 'Hide Help' or 'Help', 'neutral', nil, nil, 'Show in-game help and sharing instructions.') then ux.showHelpPanel = not ux.showHelpPanel; saveSettings() end
                if ux.showHelpPanel then ux.drawHelpPanel() end
            end

            if ImGui.CollapsingHeader('Alerts', (ImGuiTreeNodeFlags and ImGuiTreeNodeFlags.DefaultOpen) or 0) then
                ux.drawAnnounceSettings()
            end

            if ImGui.CollapsingHeader('Tester diagnostics##tmobs_diag_v2') then
                coloredTextWrapped('Use this when a tester sees bad Search, Watch, Mini, seed, or timer behavior.', 'muted')
                if styledButton('Export Diagnostic', 'primary', nil, nil, 'Write a current TurboMobs snapshot for tester reports.') then
                    ux.exportDiagnostic()
                end
                ImGui.SameLine()
                if styledButton('Export Perf Log', 'neutral', nil, nil, 'Write recent TurboMobs timing lines to a text file testers can send.') then
                    ux.exportPerfLog()
                end
                ImGui.SameLine()
                if styledButton('Open Config Folder', 'neutral', nil, nil, 'Open the TurboMobs config folder in Explorer (diagnostics, perf logs, settings, watches).') then
                    ux.openConfigFolder()
                end
                coloredTextWrapped('Command: /tmobs diag creates TurboMobs_diag_<character>.txt.', 'muted')
            end

            if ux.settingsAdvanced and ImGui.CollapsingHeader('Share / import timers##tmobs_import_v2') then
                coloredTextWrapped('Optional tools for sharing learned timers or migrating old SpawnMaster watches.', 'muted')
                ImGui.BeginChild('##tmobs_export_import_panel', 0, 420, true)
                ux.drawExportImportPanel()
                ImGui.EndChild()
            end

            if ux.settingsAdvanced and ImGui.CollapsingHeader('Seed watch repair##tmobs_seed_v2') then
                coloredTextWrapped('Seed data creates/repairs named watches from bundled zone data. Leave these alone unless you are repairing seed watches or refreshing bundled timers.', 'muted')
                local seedMaintainValue, seedMaintainChanged = ImGui.Checkbox('Auto-maintain seed watches on zone-in', ux.seedAutoMaintain == true)
                if seedMaintainChanged then ux.seedAutoMaintain = seedMaintainValue == true; saveSettings() end
                if ImGui.IsItemHovered() then
                    ImGui.SetTooltip('After bundled seed data is loaded, quietly create or refresh named watches when you enter each zone.')
                end
                local bundledTimersEnabled = ux.useBundledSeedTimers == true or (ux.useBundledSeedTimers == nil and ux.isLazarusServer())
                local bundledTimersValue, bundledTimersChanged = ImGui.Checkbox('Import bundled Lazarus respawn timers', bundledTimersEnabled)
                if bundledTimersChanged then
                    ux.useBundledSeedTimers = bundledTimersValue == true
                    saveSettings()
                end
                if ImGui.IsItemHovered() then
                    ImGui.SetTooltip('When off, imports still load named camps and PH lists; ETAs come from your kills. Defaults on for Lazarus servers.')
                end
                if styledButton('Re-import bundled seed (all zones)', 'primary', nil, nil, 'Queue a fresh import of alla_seeds_all.lua with Lazarus timers.') then
                    ux.bundledSeedAutoImported = false
                    ux.useBundledSeedTimers = true
                    saveSettings()
                    ux.requestAllaImport('alla_seeds_all.lua', false, { timerRepair = true })
                end
            end

            if ux.settingsAdvanced and ImGui.CollapsingHeader('Search performance##tmobs_scan_v2') then
                coloredTextWrapped('These affect how much data Search scans and which rows appear. Recommended defaults are best for most players.', 'muted')
                local safePauseValue, safePauseChanged = ImGui.Checkbox('Auto-pause scans in safe zones', ux.autoPauseSafeZones)
                if safePauseChanged then
                    ux.autoPauseSafeZones = safePauseValue
                    ux.safeZoneScanOverride = false
                    saveSettings()
                end
                if ImGui.IsItemHovered() then
                    ImGui.SetTooltip('Prevents heavy scan and Zone Intel work in hub zones such as Plane of Knowledge unless Scan Here is used.')
                end
                if styledButton('Clear Search Filters', 'neutral', nil, nil, 'Clear name/body/race/class/type, level, distance, and named filters. Keeps these preference checkboxes.') then
                    ux.clearSearchFilters()
                end

                local npcValue, npcChanged = ImGui.Checkbox('NPC only', npcOnly)
                if npcChanged then npcOnly = npcValue; ux.searchPage = 1; ux.refreshSearchNow({ suppressAlerts = true }); saveSettings() end
                if ImGui.IsItemHovered() then
                    ImGui.SetTooltip('Hides PCs, corpses, and player bodies. This does not control untargetable NPCs.')
                end
                ImGui.SameLine()
                if styledButton(ux.watchCurrentZoneOnly and 'Current Zone' or 'All Zones', ux.watchCurrentZoneOnly and 'primary' or 'neutral', nil, nil, ux.watchCurrentZoneOnly and 'Watches tab: current zone only. Turbo Watch always shows this zone.' or 'Watches tab: include every saved zone (can be slow). Turbo Watch stays current-zone only.') then
                    ux.watchCurrentZoneOnly = not ux.watchCurrentZoneOnly
                    saveSettings()
                end
                ImGui.SameLine()
                local unknownValue, unknownChanged = ImGui.Checkbox('Show Unknown Watches', ux.watchShowUnknown == true)
                if unknownChanged then
                    ux.watchShowUnknown = unknownValue == true
                    ux.watchRowsCache = { at = 0, key = '', rows = {} }
                    saveSettings()
                end
                if ImGui.IsItemHovered() then ImGui.SetTooltip('Show watched camps even when they have no live evidence or timer yet.') end
                local hideTimersValue, hideTimersChanged = ImGui.Checkbox('Hide known timers until <= 4:00', ux.watchHideKnownTimersUntilSoon == true)
                if hideTimersChanged then
                    ux.watchHideKnownTimersUntilSoon = hideTimersValue == true
                    ux.watchRowsCache = { at = 0, key = '', rows = {} }
                    saveSettings()
                end
                if ImGui.IsItemHovered() then ImGui.SetTooltip('Keeps fully known down camps out of Turbo Watch until the respawn is within four minutes.') end
                ImGui.SameLine()
                local targetableValue, targetableChanged = ImGui.Checkbox('Targetable only', ux.targetableOnly)
                if targetableChanged then
                    ux.targetableOnly = targetableValue
                    ux.searchPage = 1
                    ux.refilterSearchRows()
                    saveSettings()
                end
                if ImGui.IsItemHovered() then
                    ImGui.SetTooltip('When enabled, hide untargetable spawns. Turn off to include untargetable NPCs.')
                end
                local corpseValue, corpseChanged = ImGui.Checkbox('Include corpses', includeCorpses)
                if corpseChanged then includeCorpses = corpseValue; ux.searchPage = 1; ux.refreshSearchNow({ suppressAlerts = true }); saveSettings() end
                ImGui.SameLine()
                local playerValue, playerChanged = ImGui.Checkbox('Include players', includePlayers)
                if playerChanged then includePlayers = playerValue; ux.searchPage = 1; ux.refreshSearchNow({ suppressAlerts = true }); saveSettings() end
                ImGui.SameLine()
                local petValue, petChanged = ImGui.Checkbox('Include pets', includePets)
                if petChanged then includePets = petValue; ux.searchPage = 1; ux.refreshSearchNow({ suppressAlerts = true }); saveSettings() end
                local groundValue, groundChanged = ImGui.Checkbox('Ground items', includeGroundItems)
                if groundChanged then includeGroundItems = groundValue; ux.searchPage = 1; ux.refreshSearchNow({ suppressAlerts = true }); saveSettings() end

                ImGui.SetNextItemWidth(92)
                local newMaxResults, maxResultsChanged = ImGui.InputInt('Page size##tmobs_max_results', tonumber(maxResults) or 100)
                if maxResultsChanged then
                    maxResults = math.max(20, math.min(500, tonumber(newMaxResults) or 100))
                    ux.searchPage = 1
                    saveSettings()
                end
                if ImGui.IsItemHovered() then
                    ImGui.SetTooltip('Filtered Search rows shown per page. All matches stay available through page buttons.')
                end
                ImGui.SameLine()
                ImGui.SetNextItemWidth(92)
                local newScanCap, scanCapChanged = ImGui.InputInt('Scan cap##tmobs_scan_cap', tonumber(scanMaxResults) or 500)
                if scanCapChanged then
                    scanMaxResults = math.max(100, math.min(5000, tonumber(newScanCap) or 500))
                    ux.refreshSearchNow({ suppressAlerts = true })
                    saveSettings()
                end
                if ImGui.IsItemHovered() then
                    ImGui.SetTooltip('Maximum raw spawns scanned by fallback NearestSpawn paths.')
                end
                ImGui.SameLine()
                ImGui.SetNextItemWidth(80)
                local newNavDistance, navDistanceChanged = ImGui.InputInt('Nav stop##tmobs_nav_distance', tonumber(ux.navDistance) or 20)
                if navDistanceChanged then
                    ux.navDistance = math.max(1, math.min(200, tonumber(newNavDistance) or 20))
                    saveSettings()
                end
                if ImGui.IsItemHovered() then
                    ImGui.SetTooltip('Live mob navigation uses /nav id and stops when this close.')
                end
            end

            if ux.settingsAdvanced and ImGui.CollapsingHeader('Search table columns##tmobs_cols_v2') then
                local idValue, idChanged = ImGui.Checkbox('ID', ux.showIdColumn)
                if idChanged then ux.showIdColumn = idValue; saveSettings() end
                ImGui.SameLine()
                local trueNameValue, trueNameChanged = ImGui.Checkbox('True name', ux.showTrueNameColumn)
                if trueNameChanged then ux.showTrueNameColumn = trueNameValue; saveSettings() end
                ImGui.SameLine()
                local typeValue, typeChanged = ImGui.Checkbox('Show Type column', ux.showTypeColumn)
                if typeChanged then ux.showTypeColumn = typeValue; saveSettings() end
                ImGui.SameLine()
                local bodyValue, bodyChanged = ImGui.Checkbox('Show Body column', ux.showBodyColumn)
                if bodyChanged then ux.showBodyColumn = bodyValue; saveSettings() end
                local classValue, classChanged = ImGui.Checkbox('Class', ux.showClassColumn)
                if classChanged then ux.showClassColumn = classValue; saveSettings() end
                ImGui.SameLine()
                coloredText('Search direction column disabled pending tester confirmation.', 'muted')
                ux.showDirectionColumn = false
                coloredText('Mob rows left-click target. Use Nav buttons/columns to navigate.', 'muted')
            end

            if ux.settingsAdvanced and ImGui.CollapsingHeader('Debug scan view##tmobs_debug_v2') then
                local debugValue, debugChanged = ImGui.Checkbox('Show debug scan', debugMode)
                if debugChanged then debugMode = debugValue; saveSettings() end
                ux.drawDebugPanel()
            end
            ImGui.EndTabItem()
        end

        ImGui.EndTabBar()
    end
    if tabStylePushed > 0 then ImGui.PopStyleColor(tabStylePushed) end

    ux.captureWindowGeometry('full')
    ImGui.End()
    ImGui.PopStyleColor(4); ImGui.PopStyleVar(2)
end

ux.drawOutOfGamePauseWindow = function()
    if not showWindow and not ux.showAlertPopup then return end
    ImGui.SetNextWindowSize(360, 112, ImGuiCond.FirstUseEver)
    local open = true
    open = ImGui.Begin(string.format('%s v%s', SCRIPT_NAME, VERSION), open)
    if open then
        coloredTextWrapped('Paused: client is not in-game.', 'stopped')
        coloredTextWrapped('TurboMobs is not scanning, importing, navigating, or writing MQ vars from character select.', 'muted')
        if styledButton('Unload##paused_unload', 'unloadDark', 9, 4, 'Unload TurboMobs now.') then ux.stopNow() end
    end
    ImGui.End()
    if not open then
        showWindow = false
        ux.showAlertPopup = false
        saveSettings()
    end
end

ux.drawWindow = function()
    if not running then return end
    if not clientInGame() then
        ux.drawOutOfGamePauseWindow()
        return
    end
    ux.uiWantsTextInput = safeCall(function() return ImGui.GetIO().WantTextInput end, false) and true or false
    local tStart = nowMs()
    local previousDirectionContext = ux.directionContext
    local previousDrawLevel = ux.currentDrawLevel
    local headingCW = tonumber(safeCall(function() return mq.TLO.Me.Heading.Degrees() end, 0)) or 0
    local headingCCW = tonumber(safeCall(function() return mq.TLO.Me.Heading.DegreesCCW() end, nil))
    if not headingCCW then headingCCW = (360 - headingCW) % 360 end
    ux.directionContext = {
        x = tonumber(safeCall(function() return mq.TLO.Me.X() end, 0)) or 0,
        y = tonumber(safeCall(function() return mq.TLO.Me.Y() end, 0)) or 0,
        heading = headingCW,
        headingCCW = headingCCW,
    }
    ux.currentDrawLevel = tonumber(safeCall(function() return mq.TLO.Me.Level() end, 0)) or 0
    local tRefresh = nowMs()
    if showWindow and compactMode then
        showWindow = false
        compactMode = false
        ux.showAlertPopup = true
        ux.alertPopupClosedAt = 0
        saveSettings()
    end
    local tMode = nowMs()
    if showWindow then
        ux.drawFullWindow()
    end
    local tFull = nowMs()
    ux.drawAlertPopupWindow()
    local tWatch = nowMs()
    ux.drawWatchInspectWindow()
    local tInspect = nowMs()
    ux.drawWatchEditWindow()
    local tDone = nowMs()
    ux.directionContext = previousDirectionContext
    ux.currentDrawLevel = previousDrawLevel
    local total = tDone - tStart
    if debugMode or total >= 18 then
        ux.lastDrawTimingText = string.format(
            'Draw ms: total=%d refresh=%d mode=%d full=%d watch=%d inspect=%d edit=%d tab=%s fullOpen=%s watchOpen=%s',
            total, tRefresh - tStart, tMode - tRefresh, tFull - tMode, tWatch - tFull,
            tInspect - tWatch, tDone - tInspect, tostring(ux.activeFullTab or '-'),
            tostring(showWindow == true), tostring(ux.showAlertPopup == true))
    end
    ux.recordSlowPerf('drawWindow', ux.lastDrawTimingText, total, 18, 1000)
end

-- ============================================================
-- Startup
-- ============================================================

ux.firstRunSetup = function()
    ensureFolder(turboFolder)
    ensureFolder(exportsFolder)

    if not pathExists(settingsPath) then
        atomicWrite(settingsPath, serializeAsModule(buildSettingsTable()))
    end
    if not pathExists(respawnsPath) then
        atomicWrite(respawnsPath, serializeAsModule(respawnsData))
    end
    if not pathExists(watchesPath) then
        atomicWrite(watchesPath, serializeAsModule({}))
    end
end

-- Post-load watch cleanup + Alla hint (on ux.* — main chunk must stay under Lua's 200-local limit).
ux.postLoadWatchMaintenance = function()
    local mergedDupes = ux.collapseDuplicateSourceWatches and ux.collapseDuplicateSourceWatches() or 0
    local prunedPoint = ux.pruneRedundantSeedPointWatches and ux.pruneRedundantSeedPointWatches(currentZoneShort()) or 0
    if ux.rebuildWatchIndex then ux.rebuildWatchIndex() end
    local cleanedPh = ux.sanitizeWatchPhNames and ux.sanitizeWatchPhNames() or 0
    if mergedDupes > 0 or cleanedPh > 0 or prunedPoint > 0 then
        if mergedDupes > 0 then
            chat(string.format('TurboMobs: merged %d duplicate SpawnMaster/Alla watch(es) (kept the seed watch).', mergedDupes))
        end
        if cleanedPh > 0 then
            chat(string.format('TurboMobs: removed %d invalid PH name(s) (a named can\'t be a placeholder).', cleanedPh))
        end
        saveWatches()
        if ux.rebuildWatchIndex then ux.rebuildWatchIndex() end
    end
    if not allaHintShown and ux.bundledSeedAutoImported ~= true then
        local bundlePath = ux.resolveAllaSeedPath and select(1, ux.resolveAllaSeedPath('alla_seeds_all.lua', true)) or nil
        if bundlePath then
            allaHintShown = true
            saveSettings()
        end
    end
end

ux.firstRunSetup()
loadSettings()
-- Respect saved showAlertPopup; do not force Turbo Watch open on every script load.

mq.imgui.init(SCRIPT_NAME, ux.drawWindow)
chat(string.format('\\agLoaded v%s.\\ax \\ay/tmobs help\\ax for the manual.', VERSION))

ux.respawnsLoaded = false
ux.respawnsLoadStarted = false
ux.respawnsLoadAfterMS = 0
loadWatches()
ux.postLoadWatchMaintenance()
updateTargetCompatVars()

if not welcomed then
    chat(string.format('First run! Config created at: %s', turboFolder))
    chat('Type /tmobs help for commands, sharing, and how learned respawns work.')
    chat('Type /tmobs config to open the folder.')
    welcomed = true
    saveSettings()
end

ux.lastCompatTargetId = tonumber(safeCall(function() return mq.TLO.Target.ID() end, 0)) or 0

ux.mainLoopTick = function()
    mq.doevents()
    if clientInGame() then
        ux.drainCommandQueue(false)
        ux.processInitialRespawnLoad()
        ux.processRespawnsPostLoad()
        ux.processPendingRespawnSave()
        ux.processWatchedTargetKill(false)
        ux.processWatchedXTargetEvidence(false)
        ux.processRecentWatchTargetDeaths(false)
        ux.processWatchedSpawnIdDeaths(false)
        ux.processPendingWatchRuntimeSave()
        ux.processPendingWatchSave()
        ux.syncWatchZoneEntryState()
        ux.processPendingAllaImport()
        refreshIfDue()
        if ux.recentWatchTargetActive and ux.recentWatchTargetActive(4000) then
            ux.processWatchedTargetKill(false)
            ux.processRecentWatchTargetDeaths(false)
        end
        ux.updatePendingTargetRow()
        ux.updateActiveNavTarget()
        ux.updatePendingNavTargetClear()

        ux.compatTargetPollId = tonumber(safeCall(function() return mq.TLO.Target.ID() end, 0)) or 0
        if ux.compatTargetPollId ~= ux.lastCompatTargetId then
            ux.lastCompatTargetId = ux.compatTargetPollId
            ux.currentTargetCache = { at = 0, id = 0, row = nil }
            updateTargetCompatVars()
        end
        local loopDelay = 150
        if showWindow or ux.showAlertPopup then
            loopDelay = (ux.recentWatchTargetActive and ux.recentWatchTargetActive(4000)) and 25 or 50
        end
        mq.delay(loopDelay)
    else
        mq.delay(250)
    end
end

while running do
    if not xpcall(ux.mainLoopTick, function(err)
        local trace = debug and debug.traceback and debug.traceback(err, 2) or err
        if ux.recordRuntimeError then ux.recordRuntimeError('main loop', trace) end
        if ux.clearRefreshInProgress then ux.clearRefreshInProgress('main loop error') end
        return trace
    end) then
        mq.delay(500)
    end
end

saveSettings()
saveWatches('unload')
saveWatchRuntime('unload')
saveRespawns(true)
pcall(function() mq.imgui.destroy(SCRIPT_NAME) end)
pcall(function() mq.unbind('/tmobs') end)
pcall(function() mq.unbind('/turbomobs') end)
pcall(function() mq.unbind('/tmobs2') end)
pcall(function() mq.unbind('/tmalla') end)
chat('Unloaded.')
