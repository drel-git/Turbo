--[[
   E3 Turbo setup inspection — corpse hook checks, loot readiness, Setup tab UI.
   Kept out of init.lua to stay under Lua 5.1's 200-local main-chunk limit.

   @version lua/Turbo/setup_status.lua 1.1.0
]]

local mq = require('mq')
local IniHealth = require('Turbo.ini_health')

local M = {}

function M.install(TG, opts)
    opts = opts or {}
    local findE3Ini = opts.findE3Ini
    local fileExists = opts.fileExists
    local nowMS = opts.nowMS
    local getMultiLooters = opts.getMultiLooters
    local maxMultiLooters = tonumber(opts.maxMultiLooters) or 8

    local cache = {}
    local CACHE_MS = 5000

    local function inspectE3SetupIni(iniPath)
        if not iniPath or iniPath == '' then
            return false, { 'E3 INI path unknown' }, false
        end
        if not fileExists or not fileExists(iniPath) then
            return false, { 'E3 INI not found - run Setup to create corpse hooks' }, false
        end
        local duplicates = IniHealth.duplicate_sections(iniPath)
        if duplicates and #duplicates > 0 then
            return false, {
                'Duplicate INI sections found: ' .. IniHealth.format_duplicates(duplicates),
                'E3Next will not load duplicate section names; repair the INI before reloading.',
            }, true
        end
        local f = io.open(iniPath, 'r')
        if not f then
            return false, { 'Could not read E3 INI' }, true
        end
        local inEvents = false
        local found = { Tloot = false, TlootAll = false }
        for i = 1, maxMultiLooters do
            found['TlootM' .. i] = false
        end
        local issues = {}
        local needMono = 'MQ2Mono.Query[e3,LootRadius]'
        for line in f:lines() do
            local sec = line:match('^%[(.-)%]%s*$')
            if sec then
                inEvents = (sec == 'Events')
            elseif inEvents then
                local k, v = line:match('^%s*(TlootAll)%s*=%s*(.*)$')
                if not k then k, v = line:match('^%s*(TlootM%d)%s*=%s*(.*)$') end
                if not k then k, v = line:match('^%s*(Tloot)%s*=%s*(.*)$') end
                if k and v then
                    found[k] = true
                    local hasMono = v:find(needMono, 1, true) ~= nil
                    local bareLoot = v:find('${LootRadius}', 1, true) ~= nil
                    if not hasMono then
                        if bareLoot then
                            table.insert(issues, k .. '= still uses bare ${LootRadius} - run Setup again')
                        else
                            table.insert(issues, k .. '= missing ' .. needMono)
                        end
                    end
                end
            end
        end
        f:close()
        local requiredKeys = { 'Tloot', 'TlootAll' }
        for i = 1, maxMultiLooters do table.insert(requiredKeys, 'TlootM' .. i) end
        for _, key in ipairs(requiredKeys) do
            if not found[key] then
                table.insert(issues, '[Events] ' .. key .. '= not found')
            end
        end
        return #issues == 0, issues, true
    end

    TG.invalidateE3SetupStatusCache = function()
        cache = {}
    end

    TG.getE3SetupStatus = function(characterName)
        characterName = tostring(characterName or mq.TLO.Me.CleanName() or mq.TLO.Me.Name() or '')
            :match('^%s*(.-)%s*$') or ''
        local key = characterName:lower()
        local t = (nowMS and nowMS()) or (os.time() * 1000)
        local cached = cache[key]
        if cached and (t - cached.at) < CACHE_MS then
            return cached.status
        end
        local iniPath = findE3Ini and findE3Ini(nil, characterName) or nil
        local ok, issues, iniExists = inspectE3SetupIni(iniPath)
        local status = {
            ok = ok == true,
            issues = issues or {},
            iniPath = iniPath,
            iniExists = iniExists == true,
            character = characterName,
        }
        cache[key] = { at = t, status = status }
        return status
    end

    local function firstSetupIssueForLooters(names)
        for _, name in ipairs(names or {}) do
            if name and name ~= '' and name ~= 'NOBODY' then
                local st = TG.getE3SetupStatus(name)
                if st and not st.ok then
                    local detail = (st.issues and st.issues[1]) or 'E3 corpse hooks missing'
                    return string.format(
                        '%s needs Turbo setup (/lua run Turbo setup). %s',
                        name, detail)
                end
            end
        end
        return nil
    end

    local norm_name, names_match_pending, pending_setup_message

    local baseGetLootReadiness = TG.getLootReadiness
    TG.getLootReadiness = function(lootAllOn, multiModeOn, currentLooter, liveMainLooter)
        local names
        if lootAllOn then
            names = TG.getViableLooterNames()
        elseif multiModeOn then
            names = getMultiLooters and getMultiLooters() or {}
        else
            local live = liveMainLooter or (TG.getLiveMainLooter and TG.getLiveMainLooter()) or 'NOBODY'
            local wanted = currentLooter or TG.selectedChar or TG.savedDefaultLooter or ''
            local looter = (live ~= '' and live ~= 'NOBODY') and live or wanted
            names = (looter ~= '' and looter ~= 'NOBODY') and { looter } or {}
        end
        local pendingMessage = pending_setup_message(names)
        if pendingMessage then return false, pendingMessage end
        local ready, reason = baseGetLootReadiness(lootAllOn, multiModeOn, currentLooter, liveMainLooter)
        if not ready then return ready, reason end
        local setupIssue = firstSetupIssueForLooters(names)
        if setupIssue then return false, setupIssue end
        return ready, reason
    end

    TG.verifyEventsAfterSetup = function(iniPath, tag)
        tag = tag or '\at[Turbo]\ax'
        local ok, issues = inspectE3SetupIni(iniPath)
        if ok then
            printf('%s \agCheck:\ax [Events] single/all/multi rules reference MQ2Mono.Query[e3,LootRadius] (OK).\ax', tag)
            return true
        end
        if not iniPath or not fileExists or not fileExists(iniPath) then
            printf('%s \ayCould not re-read INI for verification.\ax', tag)
            return false
        end
        printf('%s \arSetup verification:\ax', tag)
        for _, msg in ipairs(issues or {}) do
            printf('%s   \ay* %s\ax', tag, msg)
        end
        printf('%s \awFix:\ax run \ag/lua run Turbo setup\aw (queues \ag/e3reload\aw), or \ag/lua run Turbo setup noreload\aw then reload manually.\ax', tag)
        return false
    end

    TG.renderSetupStatusBanner = function(g, ctx)
        M.renderSetupBanner(g, ctx)
    end

    local setSingleLooterMode = opts.setSingleLooterMode
    local syncLootRouteVars = opts.syncLootRouteVars
    local setTurboState = opts.setTurboState
    local setCombatState = opts.setCombatState
    local setRouteVar = opts.setRouteVar
    local getCurrentLooter = opts.getCurrentLooter
    local getTurboState = opts.getTurboState
    local getCombatLootState = opts.getCombatLootState
    local saveSettings = opts.saveSettings
    local reloadDs = tonumber(opts.setupAutoreloadDs) or 80

    norm_name = function(name)
        name = tostring(name or ''):match('^%s*(.-)%s*$') or ''
        return name
    end

    local function route_mode(lootAllOn, multiModeOn)
        if lootAllOn then return 'all' end
        if multiModeOn then return 'multi' end
        return 'single'
    end

    names_match_pending = function(names)
        local pending = TG.pendingLootSetup
        if type(pending) ~= 'table' or type(pending.names) ~= 'table' then return false end
        for _, name in ipairs(names or {}) do
            local key = norm_name(name):lower()
            if key ~= '' and pending.names[key] then return true end
        end
        return false
    end

    pending_setup_message = function(names)
        local pending = TG.pendingLootSetup
        if type(pending) ~= 'table' or not names_match_pending(names) then return nil end
        local wait = math.max(0, (tonumber(pending.applyAfter) or 0) - os.time())
        local label = pending.label or table.concat(pending.displayNames or {}, ', ')
        if wait > 0 then
            return string.format('Setup patched for %s. Waiting for E3 reload, then restoring looter route (~%ds).', label, wait)
        end
        return string.format('Setup patched for %s. Restoring looter route...', label)
    end

    local function capture_route_plan(lootAllOn, multiModeOn, selectedForSingle, names)
        local mode = route_mode(lootAllOn, multiModeOn)
        local plan = {
            mode = mode,
            looter = mode == 'single' and norm_name(selectedForSingle) or nil,
            names = {},
            displayNames = {},
            turbo = (getTurboState and getTurboState() == true) or TG.savedTurboOn == true,
            combat = (getCombatLootState and getCombatLootState() == true) or TG.savedCombatLootOn == true,
            applyAfter = os.time() + math.ceil((reloadDs + 35) / 10),
        }
        for _, name in ipairs(names or {}) do
            local clean = norm_name(name)
            if clean ~= '' and clean ~= 'NOBODY' then
                plan.names[clean:lower()] = true
                plan.displayNames[#plan.displayNames + 1] = clean
            end
        end
        if #plan.displayNames == 0 and plan.looter and plan.looter ~= '' then
            plan.names[plan.looter:lower()] = true
            plan.displayNames[1] = plan.looter
        end
        plan.label = (#plan.displayNames == 1) and plan.displayNames[1]
            or tostring(#plan.displayNames) .. ' looters'
        return plan
    end

    local function apply_route_plan(plan)
        if type(plan) ~= 'table' then return end
        if plan.mode == 'single' and plan.looter and plan.looter ~= '' and plan.looter ~= 'NOBODY' and setSingleLooterMode then
            setSingleLooterMode(plan.looter)
            TG.selectedChar = plan.looter
            TG.savedDefaultLooter = plan.looter
        elseif syncLootRouteVars then
            syncLootRouteVars()
        end
        if setTurboState then setTurboState(plan.turbo == true) end
        if setCombatState then setCombatState(plan.combat == true) end
        if setRouteVar then
            local rad = tonumber(TG.savedLootRadius or TG.lootRadius) or 80
            setRouteVar('LootRadius', tostring(rad))
        end
        cache = {}
        if saveSettings then saveSettings() end
        TG.statusMessage = string.format(
            '%s ready. Loot route restored%s.',
            tostring(plan.label or plan.looter or 'Looter'),
            plan.turbo and ' with Turbo ON' or '')
    end

    TG.markLootSetupPending = function(plan)
        if type(plan) ~= 'table' then return end
        TG.pendingLootSetup = plan
        TG.statusMessage = pending_setup_message(plan.displayNames) or 'Setup patched. Waiting for E3 reload, then restoring route.'
        if saveSettings then saveSettings() end
    end

    local function resolveSetupLooter(setupOpts)
        setupOpts = setupOpts or {}
        local name = setupOpts.setupTarget
        if not name or name == '' or name == 'NOBODY' then
            name = TG.selectedChar
        end
        if not name or name == '' or name == 'NOBODY' then
            name = getCurrentLooter and getCurrentLooter() or ''
        end
        if not name or name == '' or name == 'NOBODY' then
            name = TG.savedDefaultLooter
        end
        if not name or name == '' or name == 'NOBODY' then
            name = mq.TLO.Me.CleanName() or mq.TLO.Me.Name() or ''
        end
        return name
    end

    local function resolveSetupTurbo(setupOpts)
        setupOpts = setupOpts or {}
        if setupOpts.forceTurboOn == true then return true end
        if setupOpts.forceTurboOn == false then return false end
        if setupOpts.setupTarget and setupOpts.setupTarget ~= '' then return true end
        if TG.savedTurboOn ~= nil then return TG.savedTurboOn == true end
        if getTurboState then return getTurboState() == true end
        return false
    end

    local function applySetupRestoreNow(plan)
        if not plan then return end
        local looter = plan.looter
        if looter and looter ~= '' and looter ~= 'NOBODY' and setSingleLooterMode then
            setSingleLooterMode(looter)
            TG.selectedChar = looter
            TG.savedDefaultLooter = looter
        elseif syncLootRouteVars then
            syncLootRouteVars()
        end
        if setTurboState then setTurboState(plan.turbo == true) end
        if setCombatState then setCombatState(plan.combat == true) end
        if setRouteVar then
            local rad = tonumber(TG.savedLootRadius or TG.lootRadius) or 80
            setRouteVar('LootRadius', tostring(rad))
        end
        TG.pendingSetupRestore = nil
        cache = {}
        if saveSettings then saveSettings() end
        TG.statusMessage = string.format(
            'Setup ready: %s looter, Turbo %s%s',
            tostring(looter or '?'),
            plan.turbo and 'ON' or 'OFF',
            plan.combat and ', Combat loot ON' or '')
    end

    TG.scheduleSetupRestore = function(setupOpts, scheduleReload)
        setupOpts = setupOpts or {}
        if setupOpts.restoreRoute == false then
            TG.pendingSetupRestore = nil
            if saveSettings then saveSettings() end
            printf('\at[Turbo]\ax \awHook setup patched only; route state will stay controlled by the driver UI.\ax')
            return
        end
        local plan = {
            looter = resolveSetupLooter(setupOpts),
            turbo = resolveSetupTurbo(setupOpts),
            combat = (TG.savedCombatLootOn ~= nil) and (TG.savedCombatLootOn == true)
                or (getCombatLootState and getCombatLootState() or false),
            applyAfter = os.time(),
        }
        TG.savedDefaultLooter = plan.looter
        TG.selectedChar = plan.looter
        TG.savedTurboOn = plan.turbo
        TG.savedCombatLootOn = plan.combat
        if scheduleReload then
            plan.applyAfter = os.time() + math.ceil((reloadDs + 30) / 10) + 1
            TG.pendingSetupRestore = plan
            if saveSettings then saveSettings() end
            printf('\at[Turbo]\ax \awAfter /e3reload, restoring \ag%s\aw looter + Turbo \ag%s\aw (~%ds).\ax',
                plan.looter, plan.turbo and 'ON' or 'OFF',
                math.max(1, (tonumber(plan.applyAfter) or 0) - os.time()))
        else
            applySetupRestoreNow(plan)
        end
    end

    TG.tickPendingSetupRestore = function()
        local plan = TG.pendingSetupRestore
        if type(plan) == 'table' then
            if os.time() >= (tonumber(plan.applyAfter) or 0) then
                applySetupRestoreNow(plan)
            else
                return
            end
        end
        local remote = TG.pendingLootSetup
        if type(remote) ~= 'table' then return end
        if os.time() < (tonumber(remote.applyAfter) or 0) then return end
        TG.pendingLootSetup = nil
        apply_route_plan(remote)
    end

    TG.captureLootSetupPlan = capture_route_plan
    TG.pendingLootSetupMessage = pending_setup_message
end

--- Setup tab banner + per-looter Setup buttons (keeps init.lua render path thin).
function M.renderSetupBanner(g, ctx)
    if type(g) ~= 'table' or type(ctx) ~= 'table' then return end
    local ImGui = ctx.ImGui
    local Ui = ctx.Ui
    local tip = ctx.tip
    local TG = ctx.TG
    local lootAllOn = ctx.lootAllOn
    local multiModeOn = ctx.multiModeOn
    local selectedForSingle = ctx.selectedForSingle
    local getMultiLooters = ctx.getMultiLooters
    if not ImGui or not Ui or not TG or not TG.getE3SetupStatus then return end

    local setupNames = {}
    if lootAllOn then
        setupNames = g.members or {}
    elseif multiModeOn and getMultiLooters then
        setupNames = getMultiLooters()
    elseif selectedForSingle and selectedForSingle ~= '' then
        setupNames = { selectedForSingle }
    end

    local needsSetup = {}
    for _, name in ipairs(setupNames) do
        if name and name ~= '' and name ~= 'NOBODY' then
            local st = TG.getE3SetupStatus(name)
            if st and not st.ok then
                needsSetup[#needsSetup + 1] = { name = name, st = st }
            end
        end
    end

    local function wrapText(fn, ...)
        ImGui.PushTextWrapPos(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail())
        fn(...)
        ImGui.PopTextWrapPos()
    end

    local pendingMsg = TG.pendingLootSetupMessage and TG.pendingLootSetupMessage(setupNames) or nil
    if pendingMsg then
        ImGui.Spacing()
        wrapText(ImGui.TextColored, 0.95, 0.72, 0.35, 1.0, 'Hooks repair sent')
        wrapText(ImGui.TextDisabled, pendingMsg)
        ImGui.Spacing()
        ImGui.Separator()
        return
    end

    if #needsSetup == 0 then
        if #setupNames > 0 then
            ImGui.Spacing()
            wrapText(ImGui.TextColored, 0.45, 0.85, 0.55, 1.0, 'Hooks OK for selected looter route.')
        end
        return
    end

    local routePlan = nil
    if TG.captureLootSetupPlan then
        routePlan = TG.captureLootSetupPlan(lootAllOn, multiModeOn, selectedForSingle, setupNames)
    end

    ImGui.Spacing()
    wrapText(ImGui.TextColored, 0.95, 0.55, 0.28, 1.0, 'Hooks missing')
    wrapText(ImGui.TextColored, 0.95, 0.55, 0.28, 1.0,
        'One-time Turbo hooks are missing for the selected looter route.')
    for _, row in ipairs(needsSetup) do
        local issue = (row.st.issues and row.st.issues[1]) or 'corpse hooks missing from e3 Bot INI'
        wrapText(ImGui.TextColored, 0.92, 0.72, 0.45, 1.0,
            string.format('%s: %s', row.name, issue))
    end
    wrapText(ImGui.TextDisabled,
        'Click setup here; Turbo will patch only the missing hooks, reload E3, then keep your UI looter route.')
    local meName = mq.TLO.Me.Name() or ''
    if #needsSetup > 1 then
        local batchLabel = string.format('Setup %d needed looters##setup_needed_looters', #needsSetup)
        if Ui.buttonVariant(batchLabel, 'primaryButton', 188, 22) then
            if routePlan and TG.markLootSetupPending then TG.markLootSetupPending(routePlan) end
            local sent = 0
            for _, row in ipairs(needsSetup) do
                if row.name:lower() == meName:lower() then
                    if TG.runSetup then
                        TG.runSetup(nil, nil, {
                            mode = 'local',
                            setupTarget = row.name,
                            forceTurboOn = routePlan and routePlan.turbo == true,
                        })
                    end
                elseif TG.sendRemoteSetupLocal then
                    TG.sendRemoteSetupLocal(row.name)
                    sent = sent + 1
                end
            end
            g.statusMessage = string.format('Setup queued for %d looter(s); route will restore after E3 reload.', #needsSetup)
        end
        if ImGui.IsItemHovered() and tip then
            tip('Patches only the looters missing Turbo event hooks. Runtime looter selection stays controlled by this UI.')
        end
        ImGui.SameLine()
    end
    for idx, row in ipairs(needsSetup) do
        if idx > 1 or #needsSetup > 1 then ImGui.SameLine(0, 6) end
        local label = string.format('Setup %s##setup_run_%s', row.name, row.name)
        if Ui.buttonVariant(label, 'primaryButton', 108, 22) then
            if routePlan and TG.markLootSetupPending then TG.markLootSetupPending(routePlan) end
            if row.name:lower() == meName:lower() then
                if TG.runSetup then
                    TG.runSetup(nil, nil, {
                        mode = 'local',
                        setupTarget = row.name,
                        forceTurboOn = routePlan and routePlan.turbo == true,
                    })
                else
                    mq.cmd('/lua run Turbo setup local')
                end
                g.statusMessage = string.format('Setup queued for %s (INI patch + /e3reload ~8s)', row.name)
            else
                if TG.sendRemoteSetupLocal then
                    TG.sendRemoteSetupLocal(row.name)
                else
                    mq.cmdf('/squelch /e3bct %s /lua run Turbo setup hooksonly', row.name)
                end
                g.statusMessage = string.format(
                    'Setup queued for %s; route will restore after E3 reload', row.name)
            end
        end
        if ImGui.IsItemHovered() and tip then
            tip('Patches ' .. row.name .. '\'s e3 Bot INI hooks and queues /e3reload on that box without opening Turbo UI.')
        end
    end
    ImGui.Spacing()
    ImGui.Separator()
end

return M
