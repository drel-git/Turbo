--[[
  Turbo UI View State
  -------------------
  @version lua/Turbo/ui/state.lua 1.3.0

  Pure data transforms — takes the flat TG table from init.lua and produces
  a structured view-state object for each render path. No ImGui calls.
  Keeps tab/layout/summary normalization out of the hot render path.
]]

local M = {}

local VALID_TABS = {
    actions = true,
    setup = true,
    tools = true,
    review = true,
}

local VALID_LOOT_MANAGER_PAGES = {
    setup = true,
    review = true,
}

local function truncate(text, maxLen)
    text = tostring(text or '')
    if #text <= maxLen then return text end
    return text:sub(1, maxLen - 2) .. '..'
end

function M.normalizeActiveTab(tab)
    local t = tostring(tab or ''):lower()
    if t == 'lootmanager' then return 'setup' end
    if t == 'money' or t == 'gains' then return 'tools' end
    if VALID_TABS[t] then return t end
    return 'actions'
end

function M.normalizeRelevantTab(tab)
    local t = tostring(tab or ''):lower()
    if t == 'lootmanager' then return 'setup' end
    if t == 'money' or t == 'gains' then return 'tools' end
    if VALID_TABS[t] then return t end
    return 'setup'
end

function M.normalizeLootManagerPage(page)
    local p = tostring(page or ''):lower()
    if VALID_LOOT_MANAGER_PAGES[p] then return p end
    return 'setup'
end

function M.layoutModeFromFlags(minimizedGUI, slimGUI)
    if minimizedGUI then return 'mini' end
    if slimGUI then return 'slim' end
    return 'full'
end

function M.windowHeightForTab(isSlim, activeTab, Theme, opts)
    opts = opts or {}

    -- Slim path uses one shared height so switching Actions / Review / Setup
    -- / Tools does not resize the main window or cause layout churn.
    if isSlim then
        return Theme.layout.slimTargetH
            or Theme.layout.actionsSlimH
            or Theme.layout.lootManagerSlimH
    end

    -- Full path intentionally uses one shared shell height. Page content
    -- scrolls inside the window; tab switches must not resize the window.
    return Theme.layout.bigViewH or Theme.layout.fullTargetH or 720
end

function M.windowWidthForTab(isSlim, activeTab, Theme)
    if isSlim then
        return Theme.layout.slimTargetW
    end
    -- Full path uses one unified width so the header command lane and page
    -- body stay stable across Actions / Review / Setup / More.
    return Theme.layout.bigViewW or Theme.layout.fullTargetW or 480
end

function M.buildTopBarSummary(args)
    local currentLooter = args.currentLooter or 'NOBODY'
    local lootAllOn = args.lootAllOn == true
    local multiModeOn = args.multiModeOn == true
    local multiLooters = args.multiLooters or {}
    local members = args.members or {}
    local eventRadius = args.eventRadius or args.lootRadius or '50'

    local hubShort = lootAllOn and 'ALL'
        or (multiModeOn and string.format('MULTI:%d', #multiLooters) or currentLooter)
    hubShort = truncate(hubShort, 14)

    if #members == 0 and not lootAllOn and (currentLooter == 'NOBODY' or currentLooter == '') then
        hubShort = 'NOBODY'
    end

    return {
        hubShort = hubShort,
        eventText = string.format('%s  event %s ft', hubShort, tostring(eventRadius)),
        showNoGroupWarning = (#members == 0 and not lootAllOn),
    }
end

function M.buildLootManagerSummary(args)
    local currentLooter = args.currentLooter or 'NOBODY'
    local lootAllOn = args.lootAllOn == true
    local multiModeOn = args.multiModeOn == true
    local multiLooters = args.multiLooters or {}
    local perCharProfile = args.perCharProfile == true
    local members = args.members or {}
    local activeProfile = args.activeProfile or 'turboloot.ini'
    local getProfileForMember = args.getProfileForMember or function() return activeProfile end
    local maxLen = args.maxLen or 58

    local activeLootText = lootAllOn and string.format('ALL group members (%d)', #members)
        or (multiModeOn and string.format('MULTI selected (%d)', #multiLooters)
            or ((currentLooter ~= 'NOBODY' and currentLooter ~= '') and currentLooter or 'No looter set'))

    local activeIniText
    if perCharProfile then
        if lootAllOn or multiModeOn then
            activeIniText = 'per-character INIs'
        elseif currentLooter ~= '' and currentLooter ~= 'NOBODY' then
            activeIniText = string.format('%s -> %s', currentLooter, getProfileForMember(currentLooter))
        else
            activeIniText = 'pick a looter to see their INI'
        end
    else
        activeIniText = string.format('shared -> %s', activeProfile)
    end

    local modeText = lootAllOn and 'ALL' or (multiModeOn and string.format('MULTI (%d)', #multiLooters) or 'SINGLE')
    local modeColor = {0.72, 0.78, 0.65, 1.0}
    if lootAllOn then
        modeColor = {0.55, 0.78, 0.95, 1.0}
    elseif multiModeOn then
        modeColor = {0.68, 0.72, 0.92, 1.0}
    end

    return {
        activeLootText = activeLootText,
        activeIniText = activeIniText,
        activeIniDisplay = truncate(activeIniText, maxLen),
        modeText = modeText,
        modeColor = modeColor,
    }
end

function M.buildViewState(g, runtime)
    local activeTab = M.normalizeActiveTab(g.activeTab)
    local layoutMode = M.layoutModeFromFlags(g.minimizedGUI, g.slimGUI)
    local topBarSummary = M.buildTopBarSummary({
        currentLooter = runtime.currentLooter,
        lootAllOn = runtime.lootAllOn,
        multiModeOn = runtime.multiModeOn,
        multiLooters = runtime.multiLooters,
        members = g.members,
        eventRadius = runtime.eventLootRadius,
        lootRadius = g.lootRadius,
    })
    local lootManagerSummary = M.buildLootManagerSummary({
        currentLooter = runtime.currentLooter,
        lootAllOn = runtime.lootAllOn,
        multiModeOn = runtime.multiModeOn,
        multiLooters = runtime.multiLooters,
        perCharProfile = g.perCharProfile,
        members = g.members,
        activeProfile = runtime.activeProfile,
        getProfileForMember = runtime.getProfileForMember,
        maxLen = g.slimGUI and 34 or 58,
    })

    return {
        raw = g,
        runtime = runtime,
        layoutState = {
            mode = layoutMode,
            minimized = g.minimizedGUI,
            slim = g.slimGUI,
            slimWhenExpanded = g.slimWhenExpanded,
            lastRelevantTab = M.normalizeRelevantTab(g.lastRelevantTab),
            pendingExpandPos = g.pendingExpandPos,
            lastWindowMode = g.lastWindowMode,
            targetWidth = M.windowWidthForTab(g.slimGUI, activeTab, runtime.Theme),
            targetHeight = M.windowHeightForTab(g.slimGUI, activeTab, runtime.Theme, {
                setupExpanded = runtime.setupExpanded,
            }),
        },
        navState = {
            activeTab = activeTab,
        },
        lootManagerState = {
            selectedChar = g.selectedChar,
            perCharProfile = g.perCharProfile,
            slimIniExpanded = g.slimIniExpanded,
            page = M.normalizeLootManagerPage(g.lootManagerPage),
            summary = lootManagerSummary,
        },
        skipState = {
            reviewOpen = g.skipReviewOpen,
            selectedKey = g.skipSelectedKey,
            linkDbEnabled = g.skipReviewUseLinkDb,
            pendingCount = runtime.skipPendingCount or 0,
            hasDisplayRows = g.skipDisplayRows ~= nil,
        },
        feedbackState = {
            statusMessage = g.statusMessage or '',
            shownAtMS = g.statusMessageShownAtMS or 0,
        },
        summary = {
            topBar = topBarSummary,
            lootManager = lootManagerSummary,
        },
    }
end

return M
