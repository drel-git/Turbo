--[[
   Turbo diagnostics bundle export — 360° support snapshot in one folder.

   @version lua/Turbo/diagnostics_export.lua 1.1.0
]]

local mq = require('mq')
local Paths = require('Turbo.paths')

local M = {}

local MAX_COPY_BYTES = 128 * 1024
local MAX_E3_INI_BYTES = 512 * 1024

local function safeCall(fn, fallback)
    local ok, result = pcall(fn)
    if ok then return result end
    return fallback
end

local function fileSize(pathValue)
    local fsz = io.open(pathValue, 'rb')
    if not fsz then return nil end
    local size = fsz:seek('end')
    fsz:close()
    return size
end

local function readTableFile(path)
    path = tostring(path or '')
    if path == '' then return nil, 'no path' end
    local f = io.open(path, 'r')
    if not f then return nil, 'missing' end
    f:close()
    local ok, data = pcall(dofile, path)
    if ok and type(data) == 'table' then return data end
    return nil, 'unreadable'
end

local function gainsPaths(configDir, serverTag, meClean)
    local base = string.format('%s/Turbo/Gains/%s', configDir, serverTag)
    local legacy = string.format('%s/Turbo/Money/%s', configDir, serverTag)
    return {
        dir = base,
        live = string.format('%s/%s_live.lua', base, meClean),
        settings = string.format('%s/%s_gains_settings.lua', base, meClean),
        state = string.format('%s/%s_gains.lua', base, meClean),
        legacyLive = string.format('%s/%s_live.lua', legacy, meClean),
    }
end

local function inspectGainsLive(path)
    local data, err = readTableFile(path)
    if not data then return nil, err end
    local updatedAt = tonumber(data.updatedAt) or 0
    local ageSec = updatedAt > 0 and math.max(0, os.time() - updatedAt) or -1
    local xs = (type(data.xp) == 'table' and type(data.xp.session) == 'table') and data.xp.session or {}
    local sess = type(data.session) == 'table' and data.session or {}
    return {
        schema = tostring(data.schema or '?'),
        running = data.running == true,
        updatedAt = updatedAt,
        ageSec = ageSec,
        fresh = ageSec >= 0 and ageSec <= 10,
        sessionCp = tonumber(sess.totalCp) or 0,
        sessionEvents = tonumber(sess.events) or 0,
        xpGained = tonumber(xs.xpGained) or 0,
        aaGained = tonumber(xs.aaGained) or 0,
        sampleMs = tonumber(data.xp and data.xp.sampleMs) or nil,
        pausedAt = tonumber(sess.pausedAt) or 0,
    }
end

local TURBOGEAR_SCRIPT_NAMES = {
    'turbogear', 'Turbo/turbogear', 'turbogear/init', 'TurboGear', 'TurboGearUI',
}

local function turboGearRunning(TG)
    return TG and TG.luaScriptRunningAny and TG.luaScriptRunningAny(TURBOGEAR_SCRIPT_NAMES) or false
end

local function copiedHas(copied, label)
    for _, item in ipairs(copied or {}) do
        if tostring(item.label or '') == tostring(label or '') then return true end
    end
    return false
end

local function buildFpsChecklist(ctx)
    ctx = type(ctx) == 'table' and ctx or {}
    local lines = {}
    local function add(fmt, ...)
        if select('#', ...) > 0 then
            lines[#lines + 1] = string.format(fmt, ...)
        else
            lines[#lines + 1] = tostring(fmt or '')
        end
    end

    local function mark(ok, gapMsg, okMsg)
        add('  %s %s', ok and '[OK]' or '[GAP]', ok and okMsg or gapMsg)
    end

    add('Top optimization targets when active (typical heaviest first):')
    add('  1. TurboMobs — spawn scans, large respawns DB, liveSearch, alert/watch UI')
    add('  2. TurboGains — engine live-file writes (~2s), UI dofile refresh (~500ms)')
    add('  3. TurboGear — ImGui UI loop, inventory snapshots, actor sync (~6s heartbeat)')
    add('  4. Turbo hub — Skip Review journal tail (2s poll), mini loot animation, full panels')
    add('')
    add('This export — perf data coverage:')

    mark(ctx.lootPerfCopied,
        'TurboLoot perf missing — turboloot.ini lootPerfLog=ON, loot once, re-export',
        'TurboLoot perf file included')

    if ctx.gainsLiveCopied then
        mark(ctx.gainsFresh ~= false,
            'TurboGains live file stale (>10s) — engine may have stopped; Start and re-export while hitching',
            string.format('TurboGains live file included%s',
                ctx.gainsEngineRunning and ' (engine in RAM)' or ''))
    else
        mark(false,
            'TurboGains live missing — More > Gains > Start TurboGains, reproduce hitch, re-export',
            '')
    end

    mark(ctx.tmobsPerfCopied,
        'TurboMobs perf missing — /lua run TurboMobs on this box, then export (/tmobs perf auto-runs)',
        'TurboMobs perf file included')

    mark(ctx.turbogearRunning,
        'TurboGear not running — if hitches happen with gear UI open, run /lua run turbogear before re-export',
        'TurboGear script running on this session')

    if ctx.tmobsEnabled then
        local flags = {}
        if ctx.liveSearch then flags[#flags + 1] = 'liveSearch' end
        if ctx.learnAllSpawns then flags[#flags + 1] = 'learnAllSpawns' end
        if ctx.seedAutoMaintain then flags[#flags + 1] = 'seedAutoMaintain' end
        local flagText = (#flags > 0) and (' [' .. table.concat(flags, ', ') .. ']') or ''
        local sizeText = (tonumber(ctx.respawnsSize) or 0) > 0
            and string.format(', respawns %.1f MB', (tonumber(ctx.respawnsSize) or 0) / (1024 * 1024))
            or ''
        add('  [NOTE] TurboMobs enabled%s%s — close windows or stop script to test FPS impact',
            flagText, sizeText)
    end

    if (tonumber(ctx.skipPending) or 0) > 25 then
        add('  [NOTE] Skip Review pending=%d with logSkipListForIni — journal/queue I/O during loot',
            tonumber(ctx.skipPending) or 0)
    end
    if ctx.miniLootAnim then
        add('  [NOTE] Mini loot animation ON — small ImGui cost while TurboLoot active')
    end

    add('')
    add('Quick FPS isolation (try one at a time):')
    add('  • Stop TurboGains — More > Gains > Stop')
    add('  • Stop TurboGear — /lua stop turbogear')
    add('  • Stop TurboMobs — close UI or /lua stop TurboMobs')
    add('  • Turbo hub — disable mini loot animation; minimize Full window')
    add('')
    add('Re-export when reporting FPS (while hitch is happening):')
    add('  [ ] TurboGains Started and live file fresh')
    add('  [ ] TurboMobs loaded (perf file appears in bundle)')
    add('  [ ] TurboGear running if gear UI was open during hitch')
    add('  [ ] lootPerfLog=ON and at least one loot since enabling')
    add('  [ ] Export Diagnostics again — send whole Turbo_diag_* folder')

    return lines
end

local function collectRuntimeSnapshot(deps)
    local TG = deps.TG
    local lines = {}
    local function add(fmt, ...)
        if select('#', ...) > 0 then
            lines[#lines + 1] = string.format(fmt, ...)
        else
            lines[#lines + 1] = tostring(fmt or '')
        end
    end

    local getCurrentLooter = deps.getCurrentLooter
    local getTurboState = deps.getTurboState
    local getCombatLootState = deps.getCombatLootState
    local getLootAllState = deps.getLootAllState
    local isMultiLootMode = deps.isMultiLootMode
    local readIniKey = deps.readIniKey

    local currentLooter = getCurrentLooter and getCurrentLooter() or 'NOBODY'
    local liveMain = (TG.getLiveMainLooter and TG.getLiveMainLooter()) or currentLooter
    local lootAll = getLootAllState and getLootAllState() or false
    local multiMode = isMultiLootMode and isMultiLootMode() or false
    local lootReady, lootReason = true, 'n/a'
    if TG.getLootReadiness then
        lootReady, lootReason = TG.getLootReadiness(lootAll, multiMode, currentLooter, liveMain)
    end

    add('Turbo hub')
    add('  Layout: %s | Tab: %s | Tools sub-tab: %s',
        tostring(TG.layoutMode or '-'), tostring(TG.activeTab or '-'), tostring(TG.toolsSubTab or '-'))
    add('  Windows: mini=%s full=%s gains=%s onboarding=%s',
        tostring(TG.minimizedGUI ~= true), tostring(TG.minimizedGUI ~= true and TG.slimGUI ~= true),
        tostring(TG.gainsWindowOpen == true),
        tostring(TG.luaScriptRunningAny and TG.luaScriptRunningAny({ 'Turbo/onboarding', 'onboarding' }) or false))
    add('  Gains window reason: %s at=%s',
        tostring(TG.gainsWindowOpenReason or ''),
        tostring(TG.gainsWindowOpenAt or 0))
    add('  Loot: mode=%s looter=%s E3 main=%s turbo=%s combatLoot=%s all=%s multi=%s',
        tostring(TG.lootMode or '-'), tostring(currentLooter), tostring(liveMain),
        tostring(getTurboState and getTurboState() or '?'),
        tostring(getCombatLootState and getCombatLootState() or '?'),
        tostring(lootAll), tostring(multiMode))
    add('  Loot route ready: %s (%s)', lootReady and 'yes' or 'NO', tostring(lootReason or '-'))
    add('  Loot radius: saved=%s live=%s', tostring(TG.savedLootRadius or '-'), tostring(TG.lootRadius or '-'))
    add('  Skip review pending: %s | mini loot anim: %s',
        tostring((TG.skipTracker and TG.skipTracker.pending_count and TG.skipTracker.pending_count()) or 0),
        tostring(TG.miniLootAnimation ~= false))
    add('  Status: %s', tostring(TG.lastActionMessage or TG.statusMessage or '-'))

    add('')
    add('E3 route vars (MQ2Mono.Query)')
    local e3Keys = {
        'Turbo', 'CombatLoot', 'GrpLootMode', 'GrpMainLooter', 'GrpLootAll',
        'LootRadius', 'TurboLootIni', 'TurboLootActive', 'TurboGainsOn', 'TurboGainsQuiet',
    }
    for _, key in ipairs(e3Keys) do
        local val = safeCall(function() return mq.TLO.MQ2Mono.Query('e3,' .. key)() end, nil)
        add('  %s = %s', key, tostring(val ~= nil and val ~= '' and val or 'NULL'))
    end

    add('')
    add('E3 corpse hooks')
    local meClean = tostring(safeCall(function() return mq.TLO.Me.CleanName() end, '') or '')
    if TG.getE3SetupStatus and meClean ~= '' then
        local st = TG.getE3SetupStatus(meClean)
        if type(st) == 'table' then
            add('  %s: hooks=%s ini=%s (%s)',
                meClean, st.ok and 'OK' or 'MISSING',
                st.iniExists and 'found' or 'missing',
                (st.issues and st.issues[1]) or '-')
        end
    else
        add('  (setup status unavailable)')
    end

    local activeIni = deps.getTurbolootIniPath and deps.getTurbolootIniPath() or ''
    if activeIni ~= '' and readIniKey then
        add('')
        add('Active TurboLoot INI flags')
        local keys = {
            'logSkipListForIni', 'announceRunSummary', 'lootPerfLog', 'lootPerfDetail',
            'announceMethod', 'lootDistance', 'corpseHideMode',
        }
        for _, key in ipairs(keys) do
            local val = readIniKey(activeIni, 'Settings', key)
            if val and val ~= '' then add('  %s = %s', key, val) end
        end
    end

    local configDir = deps.getConfigDir and deps.getConfigDir() or mq.configDir
    local serverTag = tostring(safeCall(function() return mq.TLO.EverQuest.Server() end, 'unknown') or 'unknown'):gsub(' ', '_')
    meClean = meClean:gsub('[^%w_%-]', '_')
    if meClean == '' then meClean = 'unknown' end
    local gp = gainsPaths(configDir, serverTag, meClean)

    add('')
    add('TurboGains')
    local engine = _G.TurboGainsEngineM
    add('  Engine script in RAM: %s', (engine and engine.running == true) and 'running' or 'not running')
    add('  Live file: %s', gp.live)
    local liveInfo, liveErr = inspectGainsLive(gp.live)
    if liveInfo then
        add('  Live snap: schema=%s running=%s updated=%ds ago fresh=%s',
            liveInfo.schema, tostring(liveInfo.running), liveInfo.ageSec, tostring(liveInfo.fresh))
        add('  Session: coin=%d events=%d xp=%.4f aa=%.4f sampleMs=%s pausedAt=%d',
            liveInfo.sessionCp, liveInfo.sessionEvents, liveInfo.xpGained, liveInfo.aaGained,
            tostring(liveInfo.sampleMs or '-'), liveInfo.pausedAt)
    else
        add('  Live snap: %s', tostring(liveErr or 'missing'))
        local legacyInfo = inspectGainsLive(gp.legacyLive)
        if legacyInfo then
            add('  Legacy Money live: fresh=%s age=%ds', tostring(legacyInfo.fresh), legacyInfo.ageSec)
        end
    end

    local turboMobsDir = configDir and (configDir .. '\\TurboMobs') or nil
    if turboMobsDir then
        add('')
        add('TurboMobs')
        local mobSettings = readTableFile(turboMobsDir .. '\\settings.lua')
        if mobSettings then
            add('  enabled=%s liveSearch=%s learnAllSpawns=%s seedAutoMaintain=%s',
                tostring(mobSettings.enabled == true), tostring(mobSettings.liveSearch == true),
                tostring(mobSettings.learnAllSpawns == true), tostring(mobSettings.seedAutoMaintain == true))
            add('  showAlertPopup=%s respawnSound=%s watchCurrentZoneOnly=%s',
                tostring(mobSettings.showAlertPopup == true), tostring(mobSettings.respawnSound == true),
                tostring(mobSettings.watchCurrentZoneOnly == true))
        else
            add('  settings.lua not readable')
        end
        local watchesSize = fileSize(turboMobsDir .. '\\watches.lua')
        local respawnsSize = fileSize(turboMobsDir .. '\\respawns.lua')
        if watchesSize then add('  watches.lua size: %d bytes', watchesSize) end
        if respawnsSize then add('  respawns.lua size: %d bytes', respawnsSize) end
    end

    add('')
    add('TurboGear')
    local gearRunning = turboGearRunning(TG)
    add('  Script running: %s', gearRunning and 'yes' or 'no')
    add('  Typical load: ImGui draw loop, inventory snapshot ~3s, actor publish ~6s, cache save ~5s')
    if configDir and meClean ~= '' then
        local cachePath = string.format('%s/TurboGear_cache.lua', configDir)
        local cacheSize = fileSize(cachePath)
        if cacheSize then add('  TurboGear_cache.lua: %d bytes', cacheSize) end
        local settingsPath = string.format('%s/TurboGear_%s.lua', configDir, meClean)
        if fileSize(settingsPath) then add('  Settings file: present') end
    end

    add('')
    add('Environment')
    add('  MQ build: %s', tostring(safeCall(function() return mq.TLO.MacroQuest.BuildName() end, '?') or '?'))
    add('  In game: %s', tostring(TG.clientInGame and TG.clientInGame() or safeCall(function() return mq.TLO.Me.ID() end, 0) ~= 0))

    return lines
end

function M.run(deps)
    deps = type(deps) == 'table' and deps or {}
    local TG = deps.TG or {}
    local TURBO_VERSION = deps.TURBO_VERSION or TG.TURBO_VERSION or 'unknown'
    local nowMS = deps.nowMS or function() return (mq.gettime and mq.gettime()) or (os.time() * 1000) end
    local fileExists = deps.fileExists or function(path)
        local f = io.open(path, 'r')
        if f then f:close() return true end
        return false
    end

    local diagDir = TG.turboSupportDir and TG.turboSupportDir('diagnostics')
    if not diagDir then return nil, 'Could not create Config\\Turbo\\diagnostics.' end

    local timings = {}
    local exportStarted = nowMS()
    local function markTiming(label, startedAt)
        timings[#timings + 1] = string.format('%s: %dms', tostring(label or 'step'), math.max(0, nowMS() - (startedAt or exportStarted)))
    end

    local perfRequests = {}
    local function requestPerfSnapshot(label, command, waitMs)
        label = tostring(label or command or 'perf')
        command = tostring(command or '')
        if command == '' then return end
        local ok, err = pcall(function() mq.cmd(command) end)
        if ok then
            perfRequests[#perfRequests + 1] = label .. ': requested'
            local delayMs = tonumber(waitMs) or 0
            if delayMs > 0 then pcall(function() mq.delay(delayMs) end) end
        else
            perfRequests[#perfRequests + 1] = label .. ': request failed - ' .. tostring(err)
        end
    end

    local charName = tostring(safeCall(function() return mq.TLO.Me.CleanName() end, '') or '')
    if charName == '' then charName = tostring(safeCall(function() return mq.TLO.Me.Name() end, 'unknown') or 'unknown') end
    charName = charName:gsub('[^%w_%-]', '_')
    local meClean = charName
    local stamp = os.date('%Y%m%d_%H%M%S')
    local bundleDir = string.format('%s\\Turbo_diag_%s_%s', diagDir, charName ~= '' and charName or 'unknown', stamp)
    if not TG.ensureFolder or not TG.ensureFolder(bundleDir) then return nil, 'Could not create diagnostics bundle folder.' end

    local copied, missing, skipped = {}, {}, {}
    local copiedSources = {}

    local function safeLabel(text)
        text = tostring(text or ''):gsub('[^%w_%-%.]', '_')
        if text == '' then text = 'file' end
        return text
    end

    local function copyFile(srcPath, label, maxBytes)
        srcPath = tostring(srcPath or '')
        if srcPath == '' then return false end
        if not fileExists(srcPath) then
            missing[#missing + 1] = string.format('%s: %s', tostring(label or 'file'), srcPath)
            return false
        end
        local sourceKey = srcPath:gsub('/', '\\'):lower()
        if copiedSources[sourceKey] then
            skipped[#skipped + 1] = string.format('%s: duplicate source already copied as %s: %s',
                tostring(label or 'file'), tostring(copiedSources[sourceKey]), srcPath)
            return false
        end
        local size = fileSize(srcPath)
        if maxBytes and size and size > maxBytes then
            skipped[#skipped + 1] = string.format('%s: skipped %d-byte file over %d-byte limit: %s',
                tostring(label or 'file'), tonumber(size) or 0, tonumber(maxBytes) or 0, srcPath)
            return false
        end
        local copyStart = nowMS()
        local src = io.open(srcPath, 'rb')
        if not src then
            missing[#missing + 1] = string.format('%s: could not read %s', tostring(label or 'file'), srcPath)
            return false
        end
        local destName = safeLabel(label or (TG.fileBaseName and TG.fileBaseName(srcPath) or 'file')) .. '__' .. safeLabel(TG.fileBaseName and TG.fileBaseName(srcPath) or 'file')
        local destPath = bundleDir .. '\\' .. destName
        local n = 1
        while fileExists(destPath) do
            destPath = bundleDir .. '\\' .. safeLabel(label or 'file') .. '_' .. tostring(n) .. '__' .. safeLabel(TG.fileBaseName and TG.fileBaseName(srcPath) or 'file')
            n = n + 1
        end
        local dest = io.open(destPath, 'wb')
        if not dest then
            missing[#missing + 1] = string.format('%s: could not write copy for %s', tostring(label or 'file'), srcPath)
            src:close()
            return false
        end
        local copiedBytes = 0
        while true do
            local chunk = src:read(65536)
            if not chunk then break end
            dest:write(chunk)
            copiedBytes = copiedBytes + #chunk
        end
        src:close()
        dest:close()
        copied[#copied + 1] = { label = tostring(label or 'file'), src = srcPath, dest = destPath, size = copiedBytes }
        copiedSources[sourceKey] = tostring(label or 'file')
        markTiming('copy ' .. tostring(label or 'file'), copyStart)
        return true
    end

    local function copyFirst(paths, label, maxBytes)
        for _, srcPath in ipairs(paths or {}) do
            if srcPath and fileExists(srcPath) then
                return copyFile(srcPath, label, maxBytes)
            end
        end
        missing[#missing + 1] = string.format('%s: no matching file found', tostring(label or 'file'))
        return false
    end

    requestPerfSnapshot('TurboMobs perf log', '/tmobs perf', 300)
    perfRequests[#perfRequests + 1] = 'TurboLoot perf: copied if lootPerfLog=ON was used during a recent loot run'

    local configDir = deps.getConfigDir and deps.getConfigDir() or mq.configDir
    local mqPath = tostring(safeCall(function() return mq.TLO.MacroQuest.Path() end, '') or '')
    local activeIni = deps.getTurbolootIniPath and deps.getTurbolootIniPath() or ''
    local reviewStart = nowMS()
    local reviewSpecs = TG.getReviewJournalWatchSpecs and TG.getReviewJournalWatchSpecs() or {}
    markTiming('review watch specs', reviewStart)

    local serverTag = tostring(safeCall(function() return mq.TLO.EverQuest.Server() end, 'unknown') or 'unknown'):gsub(' ', '_')
    local gp = gainsPaths(configDir, serverTag, meClean)
    local turboMobsDir = configDir and (configDir .. '\\TurboMobs') or nil
    local e3Ini = deps.findE3Ini and deps.findE3Ini() or nil

    copyFile(activeIni, 'Active_TurboLoot_INI')
    if e3Ini then copyFile(e3Ini, 'E3_Bot_INI', MAX_E3_INI_BYTES) end
    if configDir then
        copyFirst({
            Paths.log_file('TurboLoot_perf_' .. meClean .. '.txt'),
            configDir .. '\\TurboLoot_perf_' .. meClean .. '.txt',
        }, 'TurboLoot_perf')
        copyFile(configDir .. '\\TurboLoot_skip_queue.ini', 'SkipReview_queue', MAX_COPY_BYTES)
        copyFile(configDir .. '\\turbo_skip_queue_state.lua', 'SkipReview_queue_state')
        copyFile(configDir .. '\\turbo_skips_state.lua', 'SkipReview_state')
        copyFile(configDir .. '\\turbo_settings.lua', 'Turbo_shared_settings')
        copyFile(configDir .. '\\turbo_settings_' .. meClean .. '.lua', 'Turbo_char_settings')
        copyFile(configDir .. '\\turbo_profiles.lua', 'Turbo_profiles')
        copyFile(configDir .. '\\TurboGear_' .. meClean .. '.lua', 'TurboGear_settings')
        copyFile(configDir .. '\\TurboGear_shared.lua', 'TurboGear_shared')
        copyFile(configDir .. '\\TurboGear_cache.lua', 'TurboGear_cache', MAX_COPY_BYTES)
    end
    copyFile(gp.live, 'TurboGains_live')
    copyFile(gp.settings, 'TurboGains_settings')
    copyFile(gp.state, 'TurboGains_state')
    copyFile(gp.legacyLive, 'TurboGains_legacy_live')
    for _, spec in ipairs(reviewSpecs or {}) do
        if spec.iniPath and spec.iniPath ~= '' then
            copyFile(spec.iniPath, 'Review_INI_' .. safeLabel(spec.profile or 'profile'))
        end
        if spec.path and spec.path ~= '' then
            copyFile(spec.path, 'Review_journal_' .. safeLabel(spec.profile or 'profile'), MAX_COPY_BYTES)
        end
    end
    if turboMobsDir then
        copyFile(turboMobsDir .. '\\settings.lua', 'TurboMobs_settings')
        copyFile(turboMobsDir .. '\\watches.lua', 'TurboMobs_watches', MAX_COPY_BYTES)
        copyFile(turboMobsDir .. '\\respawns.lua', 'TurboMobs_respawns', MAX_COPY_BYTES)
        copyFirst({
            Paths.log_file('TurboMobs_perf_' .. meClean .. '.txt'),
            turboMobsDir .. '\\TurboMobs_perf_' .. meClean .. '.txt',
        }, 'TurboMobs_perf')
    end

    local liveInfo = inspectGainsLive(gp.live)
    local tmobsSettings = turboMobsDir and readTableFile(turboMobsDir .. '\\settings.lua') or nil
    local respawnsSize = turboMobsDir and fileSize(turboMobsDir .. '\\respawns.lua') or nil
    local checklistCtx = {
        lootPerfCopied = copiedHas(copied, 'TurboLoot_perf'),
        gainsLiveCopied = copiedHas(copied, 'TurboGains_live'),
        gainsFresh = liveInfo and liveInfo.fresh,
        gainsEngineRunning = _G.TurboGainsEngineM and _G.TurboGainsEngineM.running == true,
        tmobsPerfCopied = copiedHas(copied, 'TurboMobs_perf'),
        tmobsEnabled = tmobsSettings and tmobsSettings.enabled == true,
        liveSearch = tmobsSettings and tmobsSettings.liveSearch == true,
        learnAllSpawns = tmobsSettings and tmobsSettings.learnAllSpawns == true,
        seedAutoMaintain = tmobsSettings and tmobsSettings.seedAutoMaintain == true,
        respawnsSize = respawnsSize,
        turbogearRunning = turboGearRunning(TG),
        skipPending = (TG.skipTracker and TG.skipTracker.pending_count and TG.skipTracker.pending_count()) or 0,
        miniLootAnim = TG.miniLootAnimation ~= false,
    }
    local fpsChecklistLines = buildFpsChecklist(checklistCtx)
    local runtimeLines = collectRuntimeSnapshot(deps)
    local reportPath = bundleDir .. '\\Turbo_diagnostics.txt'
    local readmePath = bundleDir .. '\\README.txt'

    local rf = io.open(readmePath, 'w')
    if rf then
        rf:write('Turbo Diagnostics Bundle (360 view)\r\n')
        rf:write('Send this ENTIRE folder when reporting a Turbo issue.\r\n\r\n')
        rf:write('Start here: Turbo_diagnostics.txt\r\n')
        rf:write('  - FPS / performance checklist (top of report)\r\n')
        rf:write('  - Runtime snapshot (loot route, E3 vars, TurboGains, TurboMobs, TurboGear)\r\n')
        rf:write('  - Copied settings/state files (snapshots only — live files unchanged)\r\n\r\n')
        rf:write('For FPS issues: start TurboGains + TurboMobs + TurboGear (if used), reproduce hitch, export.\r\n')
        rf:close()
    end

    local f, err = io.open(reportPath, 'w')
    if not f then return nil, err or 'Could not write diagnostics report.' end

    local function line(fmt, ...)
        if select('#', ...) > 0 then
            f:write(string.format(fmt, ...), '\n')
        else
            f:write(tostring(fmt or ''), '\n')
        end
    end

    line('Turbo Diagnostics (360 view)')
    line('Generated: %s', os.date('%Y-%m-%d %H:%M:%S'))
    line('Turbo version: %s', tostring(TURBO_VERSION))
    line('Bundle folder: %s', bundleDir)
    line('Character: %s', tostring(safeCall(function() return mq.TLO.Me.CleanName() end, 'unknown') or 'unknown'))
    line('Server: %s', tostring(safeCall(function() return mq.TLO.EverQuest.Server() end, 'unknown') or 'unknown'))
    line('Zone: %s', tostring(safeCall(function() return mq.TLO.Zone.ShortName() end, 'unknown') or 'unknown'))
    line('')
    line('=== FPS / performance checklist ===')
    for _, txt in ipairs(fpsChecklistLines) do line(txt) end
    line('')
    line('=== Runtime snapshot ===')
    for _, txt in ipairs(runtimeLines) do line(txt) end
    line('')
    line('=== Perf snapshot requests ===')
    for _, item in ipairs(perfRequests) do line(item) end
    line('')
    line('=== Paths ===')
    line('Config: %s', tostring(configDir or '-'))
    line('MacroQuest: %s', tostring(mqPath ~= '' and mqPath or '-'))
    line('Turbo support: %s', tostring(TG.turboSupportDir and TG.turboSupportDir('') or '-'))
    line('Diagnostics: %s', diagDir)
    line('Active TurboLoot INI: %s', tostring(activeIni ~= '' and activeIni or '-'))
    line('E3 Bot INI: %s', tostring(e3Ini or '-'))
    line('Char settings: %s', tostring(deps.getCharSettingsPath and deps.getCharSettingsPath() or '-'))
    line('Shared settings: %s', tostring(deps.getSettingsPath and deps.getSettingsPath() or '-'))
    line('TurboGains dir: %s', gp.dir)
    line('TurboMobs folder: %s', tostring(turboMobsDir or '-'))
    line('TurboGear settings: %s', configDir and (configDir .. '\\TurboGear_' .. meClean .. '.lua') or '-')
    line('')
    line('=== Export timings ===')
    markTiming('total export', exportStarted)
    for _, item in ipairs(timings) do line(item) end
    line('')
    line('=== Copied files (%d) ===', #copied)
    if #copied == 0 then
        line('(none)')
    else
        for _, item in ipairs(copied) do
            line('%s | %d bytes | %s', tostring(item.label), tonumber(item.size) or 0, tostring(item.src))
        end
    end
    line('')
    line('=== Missing or unavailable ===')
    if #missing == 0 then line('(none)') else for _, item in ipairs(missing) do line(item) end end
    line('')
    line('=== Skipped (size limit) ===')
    if #skipped == 0 then line('(none)') else for _, item in ipairs(skipped) do line(item) end end
    line('')
    line('=== Notes ===')
    line('Snapshots only — your live Config files were not modified or moved.')
    line('Large TurboMobs data files may be omitted; sizes are listed in the runtime snapshot.')
    line('For loot perf detail: set lootPerfLog=ON in turboloot.ini, loot once, export again.')
    f:close()

    return bundleDir, nil
end

return M
