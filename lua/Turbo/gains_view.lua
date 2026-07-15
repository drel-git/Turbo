--[[
   TurboGains - UI view module

   Read-only mirror of the TurboGains engine state, rendered inline in
   Turbo's main window and mini bar.

   @version lua/Turbo/gains_view.lua 1.0.13
]]

local mq    = require('mq')
local ImGui = require('ImGui')
local Ui    = require('Turbo.ui.components')
local TimedChallenge = require('Turbo.timed_challenge')
local okGainsHistory, GainsHistory = pcall(require, 'Turbo.gains_history')
if not okGainsHistory then GainsHistory = nil end

local M = {}

local MyName   = mq.TLO.Me.CleanName() or 'unknown'
local MyServer = (mq.TLO.EverQuest.Server() or 'unknown'):gsub(' ', '_')
local liveFile = string.format('%s/Turbo/Gains/%s/%s_live.lua',
    mq.configDir, MyServer, MyName)
local oldLiveFile = string.format('%s/Turbo/Money/%s/%s_live.lua',
    mq.configDir, MyServer, MyName)

-- Cached snapshot of the engine's live state.
local snap = nil
local lastReadMs = 0
local LIVE_READ_MIN_MS = 500
local LIVE_STALE_SECONDS = 10
local activityRowsCache = {}
local activityLastReadMs = 0
local ACTIVITY_READ_MIN_MS = 1000
local seededDisplayOpen = false
local seededToolsOpen = false
local seededDetailsOpen = false
local seededTimerOpen = false
local activitySummary
local activityDetails
-- (seededStoppedTimerOpen removed: Timed Challenge defaults closed when stopped)
--- After Stop is clicked, show Stopping… only while the engine still reports
--- running (no fixed 3s grace — that felt like lag).
local stopPressedAt = 0
--- After Start (header or Login autostart Enable), show Running / Stop while the live snap catches up.
local widthNudgeDone = false  -- nudge window to 380px once per Lua session
local startPressedAt = 0
local timedChallengeProvider

local function startTurboGainsAll()
    stopPressedAt = 0
    mq.cmd('/e3bcaa /lua run Turbo/gains_toggle start')
    startPressedAt = os.time()
end

--- UI-only timed challenge against current TurboGains session baselines.
local sessionCompare = {
    active = false,
    endAt = 0,
    baselineXp = 0,
    baselineAa = 0,
    baselineCp = 0,
    durationMin = 30,
    lastMsg = '',
    lastCompareXp = 0,
    lastCompareAa = 0,
    lastCompareCp = 0,
    lastCompareMin = 0,
    lastCompareAt = 0,
    lastLiveRefreshMs = 0,
}

local CP_PER_SP = 10
local CP_PER_GP = 100
local CP_PER_PP = 1000

-- Shared formatter (kept identical to the engine's so totals match).
local function formatCopper(total)
    total = tonumber(total) or 0
    if total == 0 then return '0cp' end
    local pp = math.floor(total / CP_PER_PP); total = total - pp * CP_PER_PP
    local gp = math.floor(total / CP_PER_GP); total = total - gp * CP_PER_GP
    local sp = math.floor(total / CP_PER_SP); total = total - sp * CP_PER_SP
    local cp = total
    local parts = {}
    if pp > 0 then table.insert(parts, string.format('%dpp', pp)) end
    if gp > 0 then table.insert(parts, string.format('%dgp', gp)) end
    if sp > 0 then table.insert(parts, string.format('%dsp', sp)) end
    if cp > 0 then table.insert(parts, string.format('%dcp', cp)) end
    return table.concat(parts, ' ')
end

local function formatCopperCompact(total)
    total = tonumber(total) or 0
    if total == 0 then return '0cp' end
    local pp = math.floor(total / CP_PER_PP); total = total - pp * CP_PER_PP
    local gp = math.floor(total / CP_PER_GP); total = total - gp * CP_PER_GP
    local sp = math.floor(total / CP_PER_SP); total = total - sp * CP_PER_SP
    local cp = total
    if pp > 0 then
        return gp > 0 and string.format('%dpp %dgp', pp, gp) or string.format('%dpp', pp)
    elseif gp > 0 then
        return sp > 0 and string.format('%dgp %dsp', gp, sp) or string.format('%dgp', gp)
    elseif sp > 0 then
        return cp > 0 and string.format('%dsp %dcp', sp, cp) or string.format('%dsp', sp)
    end
    return string.format('%dcp', cp)
end

local function formatCopperPerHour(copperPerHour)
    local n = tonumber(copperPerHour) or 0
    if n <= 0 then return '-' end
    return formatCopperCompact(math.floor(n + 0.5)) .. '/hr'
end

local function formatBreakdown(pp, gp, sp, cp)
    local parts = {}
    if pp and pp > 0 then table.insert(parts, string.format('%dpp', pp)) end
    if gp and gp > 0 then table.insert(parts, string.format('%dgp', gp)) end
    if sp and sp > 0 then table.insert(parts, string.format('%dsp', sp)) end
    if cp and cp > 0 then table.insert(parts, string.format('%dcp', cp)) end
    if #parts == 0 then return '0pp' end
    return table.concat(parts, ' ')
end

--- Format a duration in seconds as HH:MM:SS (or just MM:SS for short
--- sessions under an hour, since the leading 00: looks wasteful). Used
--- for the live session timer in the Money tab + mini-bar line.
local function formatElapsed(seconds)
    seconds = tonumber(seconds) or 0
    if seconds < 0 then seconds = 0 end
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    if h > 0 then
        return string.format('%d:%02d:%02d', h, m, s)
    else
        return string.format('%d:%02d', m, s)
    end
end

local function formatPct(value)
    local n = tonumber(value) or 0
    local s = string.format('%.2f', n)
    s = s:gsub('(%..-)0+$', '%1'):gsub('%.$', '')
    return s .. '%'
end

local function formatLevelGain(value)
    local n = tonumber(value) or 0
    local sign = n >= 0 and '+' or '-'
    n = math.abs(n)

    local levels = math.floor(n / 100)
    local pct = n - (levels * 100)

    if levels > 0 then
        return string.format('%s%d Lv %.1f%%', sign, levels, pct)
    end

    return string.format('%s%.1f%%', sign, pct)
end

local function formatRate(value)
    local n = tonumber(value) or 0
    local s = string.format('%.2f', n)
    s = s:gsub('(%..-)0+$', '%1'):gsub('%.$', '')
    return s .. '%/hr'
end

--- XP rates are stored as %/hr where 100 = 1 full level. Show as "X Lv Y%/hr"
--- so "811.53%/hr" reads as "8 Lv 11.5%/hr" -- human-legible level pace.
local SAFE_ZONES = {
    poknowledge = true, nexus = true, potranquility = true,
    bazaar = true, guildhall = true, guildlobby = true,
    freportw = true, freporte = true,
}

local function formatLevelRate(xpPerHour)
    local n = tonumber(xpPerHour) or 0
    if n <= 0 then return '-' end
    local levels = math.floor(n / 100)
    local pct = n - levels * 100
    if levels >= 1 then
        return string.format('%d Lv %.1f%%/hr', levels, pct)
    end
    return string.format('%.2f%%/hr', n)
end

local function formatAAUnits(value, signed)
    local n = (tonumber(value) or 0) / 100
    if math.abs(n) < 0.05 then n = 0 end
    local prefix = signed and n >= 0 and '+' or ''
    local s = string.format('%s%.1f', prefix, n)
    s = s:gsub('%.0$', '')
    return s .. ' AA'
end

local function formatAARate(value)
    local n = (tonumber(value) or 0) / 100
    if math.abs(n) < 0.05 then n = 0 end
    local s = string.format('%.1f', n)
    s = s:gsub('%.0$', '')
    return s .. ' AA/hr'
end

--- Lazy require of Turbo/gains_toggle API (autostart probe). On failure, buttons still mq.cmd.
local gainsToggleMod, gainsToggleModTried = nil, false
local function getGainsToggleApi()
    if gainsToggleModTried then return gainsToggleMod end
    gainsToggleModTried = true
    local ok, m = pcall(require, 'Turbo.gains_toggle')
    if ok and type(m) == 'table' then gainsToggleMod = m end
    return gainsToggleMod
end

local function renderGainsAutostartPanel()
    if not ImGui.CollapsingHeader('Login autostart##tg_autostart_hdr') then return end
    ImGui.PushTextWrapPos(0)
    ImGui.TextWrapped(
        'Adds TurboGains_AutoRun to [Startup Commands] in your e3 Bot INI so TurboGains starts on future logins. '
            .. 'Enable also runs Start TurboGains on all boxes now.')
    ImGui.PopTextWrapPos()
    local gt = getGainsToggleApi()
    local on = (gt and gt.isAutostartEnabled and gt.isAutostartEnabled()) or false
    ImGui.TextColored(on and 0.55 or 0.75, on and 0.92 or 0.72, on and 0.62 or 0.78, 1.0,
        on and 'Autostart: ON' or 'Autostart: OFF')
    if Ui.buttonVariant('Enable##tg_autostart_on', 'successButton', 96, 24) then
        mq.cmd('/lua run Turbo/gains_toggle autostart on')
        startTurboGainsAll()
    end
    if ImGui.IsItemHovered() then
        Ui.tooltip(
            'Writes TurboGains_AutoRun into your bot INI for future logins, then runs gains_toggle start on all sessions (same as Start TurboGains).',
            34)
    end
    ImGui.SameLine(0, 8)
    if Ui.buttonVariant('Disable##tg_autostart_off', 'secondaryButton', 96, 24) then
        mq.cmd('/lua run Turbo/gains_toggle autostart off')
    end
    if ImGui.IsItemHovered() then
        Ui.tooltip(
            'Removes TurboGains_AutoRun (and legacy Turbo_AutoGains) from [Startup Commands].\n\nDoes not stop a running session -- use Stop TurboGains if needed.',
            34)
    end
    ImGui.Spacing()
    ImGui.PushTextWrapPos(0)
    ImGui.TextDisabled('Disable only edits INI. Use Stop TurboGains to end this session.')
    ImGui.PopTextWrapPos()
end

local function arcadeRankTitle(points)
    points = math.floor(tonumber(points) or 0)
    if points >= 2500 then return 'Legendary rulemaster' end
    if points >= 1000 then return 'Ancient pack master' end
    if points >= 500 then return 'Master rulesmith' end
    if points >= 150 then return 'Pack hunter' end
    if points >= 50 then return 'INI scout' end
    return 'Novice pack scout'
end

local LOADING_LINES = {
    'Bristlebane Was Here',
    'Checking Anti-Camp Radius',
    'DING!',
    'Dusting Off Spellbooks',
    'Ensuring Everything Works Perfektly',
    'Looking For Graphics',
    'Oiling Clockworks',
    'Polishing Erudite Foreheads',
    'Preparing to Spin You Around Rapidly',
    'Refreshing Death Touch Ammunition',
    'Sanding Wood Elves... now 34% smoother.',
    'Starching High Elf Robes',
    'Stringing Bows',
    'Teaching Snakes to Kick',
    "Told You It Wasn't Made of Cheese",
    'You Have Gotten Better At Fizzling! (47)',
}

local function loadingLine()
    local t = (mq.gettime and mq.gettime()) or (os.time() * 1000)
    return LOADING_LINES[(math.floor(t / 9000) % #LOADING_LINES) + 1]
end

local function renderArcadeScore(g)
    if type(g) ~= 'table' then return end
    local score = math.floor(tonumber(g.rulePackArcadeScore) or 0)
    local sess = math.floor(tonumber(g.rulePackArcadeSessionPts) or 0)
    -- Only show the score banner once you've actually earned points.
    if score > 0 then
        -- Keep it on two lines so the banner doesn't force the window wide.
        ImGui.TextColored(1.0, 0.92, 0.35, 1.0, 'HIGH SCORE')
        ImGui.SameLine(0, 10)
        ImGui.TextColored(1.0, 0.42, 0.92, 1.0, tostring(score))
        if sess > 0 then
            ImGui.SameLine(0, 10)
            ImGui.TextColored(0.48, 0.94, 0.70, 1.0, string.format('+%d this session', sess))
        end
        ImGui.TextDisabled(arcadeRankTitle(score))
    end
    ImGui.TextDisabled(loadingLine())
    ImGui.Separator()
end

local function shortText(text, maxLen)
    text = tostring(text or '')
    maxLen = maxLen or 18
    if #text <= maxLen then return text end
    return text:sub(1, math.max(1, maxLen - 3)) .. '...'
end

local function getXPSection()
    if not snap or type(snap.xp) ~= 'table' then return nil end
    return snap.xp
end

local function challengeStatsFromSnap(currentSnap, xps)
    currentSnap = type(currentSnap) == 'table' and currentSnap or {}
    xps = type(xps) == 'table' and xps or {}
    return {
        -- Convert AA progress units to AA values so the timer shows decimal AAs.
        aa = (tonumber(xps.aaGained) or 0) / 100,
        aaIsPercent = false,
        xp = tonumber(xps.xpGained) or 0,
        plat = tonumber(currentSnap.session and currentSnap.session.totalCp) or 0,
        platIsCopper = true,
        zone = tostring(xps.currentZone or ''),
    }
end

--- Snapshot rows also persist in standalone *.lua files (engine writes these).
--- The embedded live file can lag or be absent when TurboGains is stopped; merge
--- disk + embedded so Best saved camps stays accurate.
local function loadDiskSnapshotTable(primaryPath, fallbackPath)
    local path = primaryPath
    local f = io.open(path, 'r')
    if not f and fallbackPath and fallbackPath ~= '' then
        path = fallbackPath
        f = io.open(path, 'r')
    end
    if not f then return {} end
    f:close()
    local ok, data = pcall(dofile, path)
    if ok and type(data) == 'table' then return data end
    return {}
end

local function diskXpSnapshotPaths()
    local gainsPath = string.format('%s/Turbo/Gains/%s/%s_xp_snapshots.lua', mq.configDir, MyServer, MyName)
    local legacyPath = string.format('%s/Turbo/Money/%s/%s_xp_snapshots.lua', mq.configDir, MyServer, MyName)
    return gainsPath, legacyPath
end

local function diskCoinSnapshotPath()
    return string.format('%s/Turbo/Gains/%s/%s_coin_snapshots.lua', mq.configDir, MyServer, MyName)
end

--- Append embed rows after disk (order irrelevant for best-* helpers).
local function combinedXpSnapshotRows(xpSection)
    local embed = (xpSection and type(xpSection.snapshots) == 'table') and xpSection.snapshots or {}
    local pGain, pLegacy = diskXpSnapshotPaths()
    local disk = loadDiskSnapshotTable(pGain, pLegacy)
    local out = {}
    for _, r in ipairs(disk) do out[#out + 1] = r end
    for _, r in ipairs(embed) do out[#out + 1] = r end
    return out
end

local function combinedMoneySnapshotRows(currentSnap)
    local embed = (currentSnap.money and type(currentSnap.money.snapshots) == 'table')
        and currentSnap.money.snapshots or {}
    local disk = loadDiskSnapshotTable(diskCoinSnapshotPath(), nil)
    local out = {}
    for _, r in ipairs(disk) do out[#out + 1] = r end
    for _, r in ipairs(embed) do out[#out + 1] = r end
    return out
end

local function activityRows(limit)
    if not GainsHistory or type(GainsHistory.events) ~= 'function' then return {} end
    local nowMs = (mq.gettime and mq.gettime()) or (os.time() * 1000)
    if (nowMs - activityLastReadMs) >= ACTIVITY_READ_MIN_MS then
        activityLastReadMs = nowMs
        local ok, rows = pcall(GainsHistory.events, 50)
        activityRowsCache = (ok and type(rows) == 'table') and rows or {}
    end
    if not limit or limit <= 0 or limit >= #activityRowsCache then return activityRowsCache end
    local out = {}
    for i = 1, math.min(limit, #activityRowsCache) do out[#out + 1] = activityRowsCache[i] end
    return out
end

-- Pull a fresh snapshot from disk if our cache is stale. The file is small
-- (a few KB at most) and writes from the engine are atomic-via-rename, so a
-- read here is safe even mid-loot.
local function refresh()
    local nowMs = (mq.gettime and mq.gettime()) or (os.time() * 1000)
    if snap and (nowMs - lastReadMs) < LIVE_READ_MIN_MS then return end
    lastReadMs = nowMs

    local path = liveFile
    local f = io.open(path, 'r')
    if not f then
        path = oldLiveFile
        f = io.open(path, 'r')
    end
    if not f then
        snap = nil
        return
    end
    f:close()
    local ok, data = pcall(dofile, path)
    if ok and type(data) == 'table' then
        snap = data
    end
end

--- Bypass the UI read throttle (used when starting the timed challenge).
local function refreshForce()
    lastReadMs = 0
    refresh()
end

local function isFreshGainsSnap(data)
    if type(data) ~= 'table' then return false end
    if data.schema ~= 'TurboGainsLive' and data.schema ~= 'TurboStatsLive' then return false end
    if data.running == false then return false end
    if type(data.xp) ~= 'table' then return false end
    local updatedAt = tonumber(data.updatedAt) or 0
    if updatedAt <= 0 then return false end
    return (os.time() - updatedAt) <= LIVE_STALE_SECONDS
end

--- Public: returns the current group-session total in copper, or 0 if the
--- engine isn't running yet. Used by the mini-bar render path.
function M.getSessionTotalCp()
    refresh()
    if not isFreshGainsSnap(snap) then return 0 end
    if not snap or not snap.session then return 0 end
    return tonumber(snap.session.totalCp) or 0
end

--- Public: returns true only when the combined Stats engine is actively
--- heartbeating. Old Money live files are treated as offline so buttons do not
--- send /turbomoney commands before the engine has bound them.
function M.isEngineRunning()
    refresh()
    return isFreshGainsSnap(snap)
end

--- Public: return the path the view is reading. Useful for /turbomoney
--- diagnostics so users can sanity-check that engine and view agree.
function M.getLiveFilePath()
    return liveFile
end

-- =============================================================================
-- Mini-bar group total line
-- =============================================================================

--- Public: render a single line under the mini bar showing the group total.
--- Designed to slot in at the bottom of mini.lua's render flow without
--- changing the bar's existing buttons. Wraps the text in a faint amber
--- background pill matching the rest of the mini bar's color language.
function M.renderMiniLine(opts)
    opts = type(opts) == 'table' and opts or {}
    refresh()
    if not isFreshGainsSnap(snap) then return end
    local currentSnap = snap or {}
    local display = currentSnap.display or {}
    local cp = (currentSnap.session and currentSnap.session.totalCp) or 0
    local startedAt   = (currentSnap.session and tonumber(currentSnap.session.startedAt))   or 0
    local pausedAt    = (currentSnap.session and tonumber(currentSnap.session.pausedAt))    or 0
    local pausedAccum = (currentSnap.session and tonumber(currentSnap.session.pausedAccum)) or 0
    local isPaused    = pausedAt > 0
    local xp = getXPSection() or {}
    local xps = xp.session or {}
    local drew = false
    local segments = {}

    if display.miniXP == true then
        table.insert(segments, { text = formatLevelGain(xps.xpGained or 0), color = { 0.62, 1.0, 0.62, 1.0 } })
    end
    if display.miniAA == true then
        table.insert(segments, { text = formatAAUnits(xps.aaGained or 0), color = { 0.76, 0.60, 0.95, 1.0 } })
    end
    if display.miniCoin == true then
        table.insert(segments, { text = formatCopperCompact(cp), color = { 1.0, 0.95, 0.55, 1.0 } })
    end
    if display.miniTime == true and startedAt > 0 then
        local refTime = isPaused and pausedAt or os.time()
        local elapsed = refTime - startedAt - pausedAccum
        if elapsed < 0 then elapsed = 0 end
        table.insert(segments, {
            text = formatElapsed(elapsed),
            color = { isPaused and 0.95 or 0.62, isPaused and 0.65 or 0.70, isPaused and 0.30 or 0.86, 1.0 }
        })
    end
    if #segments == 0 then return end

    local function sep()
        if drew then
            ImGui.SameLine(0, 8)
            ImGui.TextColored(0.45, 0.50, 0.62, 1.0, '|')
            ImGui.SameLine(0, 8)
        end
        drew = true
    end

    ImGui.Dummy(0, 2)
    local availX = ImGui.GetContentRegionAvail()
    availX = tonumber(availX) or 0
    local fontSize = tonumber(ImGui.GetFontSize()) or 13
    local approxTextW = 0
    for _, seg in ipairs(segments) do approxTextW = approxTextW + (#seg.text * fontSize * 0.52) end
    approxTextW = approxTextW + math.max(0, #segments - 1) * fontSize * 2.0
    if availX > approxTextW then
        local cursorX = ImGui.GetCursorPosX()
        ImGui.SetCursorPosX(cursorX + math.floor((availX - approxTextW) * 0.5))
    end
    for _, seg in ipairs(segments) do
        sep()
        ImGui.TextColored(seg.color[1], seg.color[2], seg.color[3], seg.color[4], seg.text)
        if opts.onClick and ImGui.IsItemClicked and ImGui.IsItemClicked() then opts.onClick() end
        if opts.tooltip and ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then ImGui.SetTooltip(opts.tooltip) end
    end
end

function M.renderTimedChallengeMini(showFull)
    refresh()
    TimedChallenge.renderMini(timedChallengeProvider(showFull or function()
        mq.cmd('/lua run Turbo')
    end))
end

-- =============================================================================
-- Money tab body (renders inside Turbo's main window when activeTab=='money')
-- =============================================================================

--- 1.1.3: compute a table's height based on row count, capped at a max.
--- When `rowCount` fits inside `maxRows`, returns the exact height needed
--- (no scrollbar engages); otherwise returns the max height (scrollbar
--- shows). The +6 fudge accounts for header bottom border + row padding
--- so the last row never gets clipped at the cap boundary.
---
--- Use with ImGuiTableFlags.ScrollY: pass the returned value as the table
--- height. When rows < maxRows the table shrinks to fit and no scrollbar
--- is needed; when rows >= maxRows the scrollbar appears and rows scroll
--- WITHIN the capped region.
local function tableHeightForRows(rowCount, maxRows)
    local rowH = math.ceil(ImGui.GetFontSize() + ImGui.GetStyle().ItemSpacing.y)
    local headerH = math.ceil(ImGui.GetFontSize() + ImGui.GetStyle().FramePadding.y * 2 + 4)
    local visibleRows = math.min(math.max(rowCount, 1), maxRows)
    return headerH + (rowH * visibleRows) + 6
end

local function renderPerChar()
    if not snap or not snap.session or not snap.session.byChar then
        ImGui.TextDisabled('No loots this session yet.')
        return
    end
    local rows = {}
    for name, info_ in pairs(snap.session.byChar) do
        table.insert(rows, {
            name   = name,
            cp     = tonumber(info_.cp)     or 0,
            events = tonumber(info_.events) or 0,
        })
    end
    table.sort(rows, function(a, b) return a.cp > b.cp end)
    if #rows == 0 then
        ImGui.TextDisabled('No loots this session yet.')
        return
    end
    if ImGui.BeginTable('TurboGainsPerChar', 3,
        ImGuiTableFlags.Borders + ImGuiTableFlags.RowBg
        + ImGuiTableFlags.SizingStretchProp) then
        ImGui.TableSetupColumn('Character')
        ImGui.TableSetupColumn('Looted')
        ImGui.TableSetupColumn('Events')
        ImGui.TableHeadersRow()
        for _, r in ipairs(rows) do
            ImGui.TableNextRow()
            ImGui.TableNextColumn(); ImGui.Text(r.name)
            ImGui.TableNextColumn()
            ImGui.TextColored(0.85, 0.78, 0.38, 1.0, formatCopper(r.cp))
            ImGui.TableNextColumn(); ImGui.Text(tostring(r.events))
        end
        ImGui.EndTable()
    end
end

local function renderRecent()
    if not snap or not snap.recent or #snap.recent == 0 then
        ImGui.TextDisabled('No loot events yet.')
        return
    end
    --- 1.1.3: was hardcoded at 92px (~3.5 rows) which always clipped the
    --- last row's bottom edge. Cap at 8 rows so the scrollbar only shows
    --- when needed; when content is shorter the table shrinks to fit.
    local tableH = tableHeightForRows(#snap.recent, 8)
    if ImGui.BeginTable('TurboGainsRecent', 5,
        ImGuiTableFlags.Borders + ImGuiTableFlags.RowBg
        + ImGuiTableFlags.SizingStretchProp + ImGuiTableFlags.ScrollY,
        0, tableH) then
        ImGui.TableSetupColumn('Time')
        ImGui.TableSetupColumn('Looter')
        ImGui.TableSetupColumn('Amount')
        ImGui.TableSetupColumn('Zone')
        ImGui.TableSetupColumn('Corpse')
        ImGui.TableHeadersRow()
        for _, r in ipairs(snap.recent) do
            ImGui.TableNextRow()
            ImGui.TableNextColumn(); ImGui.Text(tostring(r.at or ''))
            ImGui.TableNextColumn()
            ImGui.TextColored(0.85, 0.78, 0.38, 1.0, tostring(r.who or ''))
            ImGui.TableNextColumn()
            ImGui.Text(formatBreakdown(r.pp, r.gp, r.sp, r.ccp))
            ImGui.TableNextColumn(); ImGui.Text(shortText(r.zone or '', 18))
            ImGui.TableNextColumn(); ImGui.Text(tostring(r.corpse or ''))
        end
        ImGui.EndTable()
    end
end

local function renderXPSnapshots(xp, display)
    local rows = xp and xp.snapshots or nil
    if not rows or #rows == 0 then
        ImGui.TextDisabled('No XP snapshots yet.')
        return
    end
    display = display or {}

    local showZone = display.metaZone ~= false
    local showXP = display.pageXP ~= false and display.xpGained ~= false
    local showXPRate = display.pageXP ~= false and display.xpRate ~= false
    local showAA = display.pageAA ~= false and display.aaGained ~= false
    local showAARate = display.pageAA ~= false and display.aaRate ~= false

    local colCount = 2
    if showZone then colCount = colCount + 1 end
    if showXP then colCount = colCount + 1 end
    if showXPRate then colCount = colCount + 1 end
    if showAA then colCount = colCount + 1 end
    if showAARate then colCount = colCount + 1 end

    if ImGui.BeginTable('TurboGainsXPSnapshots', colCount,
        ImGuiTableFlags.Borders + ImGuiTableFlags.RowBg
        + ImGuiTableFlags.SizingStretchProp + ImGuiTableFlags.ScrollY,
        0, tableHeightForRows(#rows, 5)) then
        ImGui.TableSetupColumn('Time')
        ImGui.TableSetupColumn('Run')
        if showZone then ImGui.TableSetupColumn('Zone') end
        if showXP then ImGui.TableSetupColumn('XP') end
        if showXPRate then ImGui.TableSetupColumn('XP/hr') end
        if showAA then ImGui.TableSetupColumn('AA') end
        if showAARate then ImGui.TableSetupColumn('AA/hr') end
        ImGui.TableHeadersRow()

        for _, row in ipairs(rows) do
            ImGui.TableNextRow()
            ImGui.TableNextColumn(); ImGui.Text(tostring(row.time or ''))
            ImGui.TableNextColumn(); ImGui.Text(formatElapsed(tonumber(row.runtime) or 0))
            if showZone then
                ImGui.TableNextColumn(); ImGui.Text(shortText(row.zone or 'Unknown', 22))
            end
            if showXP then
                ImGui.TableNextColumn()
                ImGui.TextColored(0.62, 1.0, 0.62, 1.0, formatLevelGain(row.xpGained or 0))
            end
            if showXPRate then
                ImGui.TableNextColumn()
                ImGui.TextColored(0.85, 0.78, 0.38, 1.0, formatLevelRate(row.xpPerHour or 0))
            end
            if showAA then
                ImGui.TableNextColumn()
                ImGui.TextColored(0.76, 0.60, 0.95, 1.0, formatAAUnits(row.aaGained or 0))
            end
            if showAARate then
                ImGui.TableNextColumn()
                ImGui.TextColored(0.85, 0.78, 0.38, 1.0, formatAARate(row.aaPerHour or 0))
            end
        end

        ImGui.EndTable()
    end
end


local function renderMoneySnapshots()
    local rows = snap and snap.money and snap.money.snapshots or nil
    if not rows or #rows == 0 then
        ImGui.TextDisabled('No coin snapshots yet.')
        return
    end
    if ImGui.BeginTable('TurboGainsCoinSnapshots', 6, ImGuiTableFlags.Borders + ImGuiTableFlags.RowBg + ImGuiTableFlags.SizingStretchProp + ImGuiTableFlags.ScrollY, 0, tableHeightForRows(#rows, 5)) then
        ImGui.TableSetupColumn('Time')
        ImGui.TableSetupColumn('Run')
        ImGui.TableSetupColumn('Zone')
        ImGui.TableSetupColumn('Total')
        ImGui.TableSetupColumn('Events')
        ImGui.TableSetupColumn('Biggest')
        ImGui.TableHeadersRow()
        for _, row in ipairs(rows) do
            ImGui.TableNextRow()
            ImGui.TableNextColumn(); ImGui.Text(tostring(row.time or ''))
            ImGui.TableNextColumn(); ImGui.Text(formatElapsed(row.runtime or 0))
            ImGui.TableNextColumn(); ImGui.Text(shortText(row.zone or '', 18))
            ImGui.TableNextColumn(); ImGui.TextColored(1.0, 0.95, 0.55, 1.0, formatCopper(row.totalCp or 0))
            ImGui.TableNextColumn(); ImGui.Text(tostring(row.events or 0))
            ImGui.TableNextColumn(); ImGui.Text(formatCopper(row.biggestCp or 0))
        end
        ImGui.EndTable()
    end
end

local function displayEnabled(display, key)
    return not display or display[key] ~= false
end

local function countRows(rows)
    if type(rows) ~= 'table' then return 0 end
    return #rows
end

local function hasPerCharRows(currentSnap)
    local byChar = currentSnap and currentSnap.session and currentSnap.session.byChar or nil
    if type(byChar) ~= 'table' then return false end
    for _, info_ in pairs(byChar) do
        if (tonumber(info_.cp) or 0) > 0 or (tonumber(info_.events) or 0) > 0 then
            return true
        end
    end
    return false
end

local function hasRecentRows(currentSnap)
    return countRows(currentSnap and currentSnap.recent) > 0
end

local function hasMeaningfulXPSnapshots(xp)
    local rows = xp and xp.snapshots or nil
    if type(rows) ~= 'table' then return false end
    for _, row in ipairs(rows) do
        if (tonumber(row.xpGained) or 0) ~= 0 or (tonumber(row.aaGained) or 0) ~= 0 then
            return true
        end
    end
    return false
end

local function hasMeaningfulMoneySnapshots(currentSnap)
    local rows = currentSnap and currentSnap.money and currentSnap.money.snapshots or nil
    if type(rows) ~= 'table' then return false end
    for _, row in ipairs(rows) do
        if (tonumber(row.totalCp) or 0) > 0 or (tonumber(row.events) or 0) > 0 then
            return true
        end
    end
    return false
end

--- 1.1.0: sectionTitle now draws a colored separator + dot anchor before
--- the label. Same visual language as Ui.sectionHeader in components.lua
--- so the Gains tools page stops looking like an outlier. Color passed in by the
--- caller drives both the separator tint and the dot fill, so each
--- section keeps its semantic palette (XP=green, AA=purple, Coin=gold).
local function sectionTitle(label, r, g, b)
    r = r or 0.70
    g = g or 0.85
    b = b or 1.0
    ImGui.Spacing()

    -- Tinted separator. Uses the section's accent color at low alpha so it
    -- reads as an anchor without competing with content.
    local sepR = math.floor(r * 255 * 0.55)
    local sepG = math.floor(g * 255 * 0.55)
    local sepB = math.floor(b * 255 * 0.55)
    ImGui.PushStyleColor(ImGuiCol.Separator, IM_COL32(sepR, sepG, sepB, 110))
    ImGui.Separator()
    ImGui.PopStyleColor(1)

    -- Colored dot before the label, vertically centered on the label's
    -- font line. Identical pattern to Ui.sectionHeader (components.lua
    -- line ~125) and the watcher dot in renderSkipReview.
    local fontSize = ImGui.GetFontSize()
    local radius = math.max(3, math.floor(fontSize * 0.30))
    local cx, cy = ImGui.GetCursorScreenPos()
    local centerY = cy + math.floor(fontSize * 0.5) + 1
    local centerX = cx + radius + 2
    local dotR = math.floor(math.min(r * 255 * 1.10, 255))
    local dotG = math.floor(math.min(g * 255 * 1.10, 255))
    local dotB = math.floor(math.min(b * 255 * 1.10, 255))
    ImGui.GetWindowDrawList():AddCircleFilled(
        ImVec2(centerX, centerY), radius,
        IM_COL32(dotR, dotG, dotB, 255), 0)
    ImGui.Dummy(radius * 2 + 6, 1)
    ImGui.SameLine(0, 0)

    ImGui.TextColored(r, g, b, 1.0, label)
end

local function labelValue(label, value, r, g, b)
    ImGui.TextColored(0.62, 0.70, 0.86, 1.0, label .. ':')
    ImGui.SameLine()
    ImGui.TextColored(r or 0.90, g or 0.92, b or 0.96, 1.0, tostring(value or '-'))
end

local function renderMetricRow(items)
    local drew = false
    for _, item in ipairs(items or {}) do
        if item.show then
            if drew then ImGui.SameLine(0, item.gap or 18) end
            labelValue(item.label, item.value, item.r, item.g, item.b)
            drew = true
        end
    end
    return drew
end

local function toggleButton(label, id, active, cmd, width)
    local variant = active and 'successButton' or 'secondaryButton'
    if Ui.buttonVariant(label .. '##' .. id, variant, width, 22) then
        mq.cmd(cmd)
    end
end

local function ensureWindowHeight(targetH)
    targetH = tonumber(targetH) or 0
    if targetH <= 0 then return end
    local okSize, sx, sy = pcall(ImGui.GetWindowSize)
    if okSize and sx and sy and sy < targetH then
        pcall(function() ImGui.SetWindowSize(sx, targetH) end)
    end
end

local function renderToggleGroup(title, specs, display, commandScope)
    ImGui.TextColored(0.62, 0.70, 0.86, 1.0, title .. ':')
    local avail = ImGui.GetContentRegionAvail()
    local sp = ImGui.GetStyle().ItemSpacing.x
    local cols = math.min(4, #specs)
    while cols > 1 and ((avail - sp * (cols - 1)) / cols) < 64 do
        cols = cols - 1
    end
    local w = math.max(1, math.floor((avail - sp * (cols - 1)) / cols))
    for i, spec in ipairs(specs) do
        if cols > 1 and ((i - 1) % cols) > 0 then ImGui.SameLine(0, sp) end
        local active = displayEnabled(display, spec.displayKey)
        local scope = spec.scope or commandScope
        local label = Ui.fitLabel(spec.label, spec.shortLabel, w)
        toggleButton(label, scope .. '_' .. spec.cmdKey, active,
            string.format('/turbogains %s %s toggle', scope, spec.cmdKey), w)
    end
end

local function bestRow(rows, key)
    if type(rows) ~= 'table' then return nil end
    local best, bestValue = nil, 0
    for _, row in ipairs(rows) do
        local value = tonumber(row and row[key]) or 0
        if value > bestValue then
            best, bestValue = row, value
        end
    end
    return best, bestValue
end

--- Highest copper/hour among coin snapshots with enough runtime (same basis as timed compare).
local function bestMoneySnapshotHourlyCp(rows)
    local function pick(minRt)
        local bestR, bestV = nil, 0
        if type(rows) ~= 'table' then return nil, 0 end
        for _, row in ipairs(rows) do
            local rt = tonumber(row and row.runtime) or 0
            if rt >= minRt then
                local tcp = tonumber(row and row.totalCp) or 0
                local v = (tcp / rt) * 3600
                if v > bestV then
                    bestV = v
                    bestR = row
                end
            end
        end
        return bestR, bestV
    end
    local br, bv = pick(30)
    if bv <= 0 then br, bv = pick(10) end
    if bv <= 0 then br, bv = pick(1) end
    return br, bv
end

local function captureSessionBaselines()
    local xp = getXPSection() or {}
    local xps = xp.session or {}
    local s = (snap and snap.session) or {}
    return tonumber(xps.xpGained) or 0, tonumber(xps.aaGained) or 0, tonumber(s.totalCp) or 0
end

local function tickSessionCompareTimer()
    if not sessionCompare.active then return end
    if not M.isEngineRunning() then
        sessionCompare.active = false
        sessionCompare.lastMsg = 'Timer cancelled (TurboGains stopped).'
        return
    end
    if os.time() < sessionCompare.endAt then return end
    refreshForce()
    local cx, ca, cc = captureSessionBaselines()
    local dx = cx - sessionCompare.baselineXp
    local da = ca - sessionCompare.baselineAa
    local dc = cc - sessionCompare.baselineCp
    sessionCompare.lastMsg = string.format(
        'Timed Challenge finished (%dm): XP %+s  AA %s  Coin %s. Snapshot saved.',
        sessionCompare.durationMin,
        formatLevelGain(dx), formatAAUnits(da, true), formatCopperCompact(dc))
    sessionCompare.lastCompareXp = dx
    sessionCompare.lastCompareAa = da
    sessionCompare.lastCompareCp = dc
    sessionCompare.lastCompareMin = tonumber(sessionCompare.durationMin) or 0
    sessionCompare.lastCompareAt = os.time()
    sessionCompare.active = false
    mq.cmd('/turbogains xp snapshot')
    mq.cmd('/turbogains coin snapshot')
end

timedChallengeProvider = function(showFull)
    return {
        getStats = function()
            refreshForce()
            local currentSnap = snap or {}
            local xp = getXPSection() or {}
            local xps = xp.session or {}
            return challengeStatsFromSnap(currentSnap, xps)
        end,
        snapshot = function()
            mq.cmd('/turbogains xp snapshot')
            mq.cmd('/turbogains coin snapshot')
        end,
        showFull = showFull or function() end,
    }
end

local function renderSessionCompareTimer()
    local provider = timedChallengeProvider()
    TimedChallenge.renderSetup(provider)
    if TimedChallenge.isActive and TimedChallenge.isActive() then
        ImGui.TextColored(0.55, 0.60, 0.68, 1.0, 'Mini timer is open.')
    end
end

local function renderEngineHeader(displayRunning)
    local now = os.time()
    local engineRunning = M.isEngineRunning()
    local stopping = engineRunning and stopPressedAt > 0 and (now - stopPressedAt) <= 15
    local starting = displayRunning and (not engineRunning) and startPressedAt > 0
        and (now - startPressedAt) <= 15
    local statusText = 'Stopped'
    if stopping then
        statusText = 'Stopping...'
    elseif starting then
        statusText = 'Starting...'
    elseif displayRunning then
        statusText = 'Running'
    end
    --- 1.1.0: Status dot before the "TurboGains" label. Same pattern as
    --- Ui.sectionHeader uses elsewhere in the suite — a colored filled
    --- circle that acts as a scannable status anchor. Green when running,
    --- red when stopped. The text status to the right is kept for explicit
    --- reading but the dot lets you confirm engine state at a glance from
    --- across the room.
    local dotColor = displayRunning
        and IM_COL32(95, 200, 110, 255)   -- green: engine running
        or  IM_COL32(220, 75, 70, 255)    -- red: engine stopped
    local fontSize = ImGui.GetFontSize()
    local radius = math.max(4, math.floor(fontSize * 0.36))
    local cx, cy = ImGui.GetCursorScreenPos()
    local centerY = cy + math.floor(fontSize * 0.5) + 1
    local centerX = cx + radius + 2
    ImGui.GetWindowDrawList():AddCircleFilled(
        ImVec2(centerX, centerY), radius, dotColor, 0)
    --- Reserve horizontal space for the dot so the label doesn't overlap it.
    ImGui.Dummy(radius * 2 + 6, 1)
    ImGui.SameLine(0, 0)

    ImGui.TextColored(0.70, 0.85, 1.0, 1.0, 'TurboGains')
    ImGui.SameLine(0, 14)
    ImGui.TextColored(displayRunning and 0.50 or 0.95, displayRunning and 0.95 or 0.45,
        displayRunning and 0.60 or 0.35, 1.0, statusText)
    ImGui.SameLine(0, 18)
    if displayRunning then
        if Ui.buttonVariant((stopping and 'Stopping...' or 'Stop TurboGains') .. '##tg_engine_stop', 'secondaryButton', 132, 24) then
            stopPressedAt = now
            startPressedAt = 0
            mq.cmd('/e3bcaa /lua run Turbo/gains_toggle stop')
        end
        if ImGui.IsItemHovered() then
            Ui.tooltip(
                'Every E3 session: gains_toggle stop -- TurboGainsQuiet/On off, /turbogains stop, /lua stop loot announcer.',
                34)
        end
    else
        stopPressedAt = 0
        local startAvail = ImGui.GetContentRegionAvail()
        local startW = math.min(140, math.max(74, math.floor(startAvail)))
        local startLabel = startW < 118 and 'Start##tg_engine_start' or 'Start TurboGains##tg_engine_start'
        if Ui.buttonVariant(startLabel, 'successButton', startW, 24) then
            startTurboGainsAll()
        end
        if ImGui.IsItemHovered() then
            Ui.tooltip(
                'Same idea as Field Tools melee toggle: /e3bcaa runs gains_toggle start on each box.\n\n'
                    .. 'Sets TurboGainsOn + TurboGainsQuiet via /e3varset (session vars -- not written to any INI).\n\n'
                    .. 'To persist for future logins, use Login autostart > Enable (adds TurboGains_AutoRun under [Startup Commands] in your e3 Bot INI).',
                34)
        end
    end
end

local function sessionElapsed(s)
    s = s or {}
    local startedAt   = tonumber(s.startedAt)   or 0
    local pausedAt    = tonumber(s.pausedAt)    or 0
    local pausedAccum = tonumber(s.pausedAccum) or 0
    local isPaused    = pausedAt > 0
    if startedAt <= 0 then return 0, isPaused end
    local refTime = isPaused and pausedAt or os.time()
    local elapsed = refTime - startedAt - pausedAccum
    if elapsed < 0 then elapsed = 0 end
    return elapsed, isPaused
end

local function defaultClosedHeader(label, seededName)
    if ImGui.SetNextItemOpen then
        if seededName == 'display' and not seededDisplayOpen then
            ImGui.SetNextItemOpen(false)
            seededDisplayOpen = true
        elseif seededName == 'tools' and not seededToolsOpen then
            ImGui.SetNextItemOpen(false)
            seededToolsOpen = true
        elseif seededName == 'details' and not seededDetailsOpen then
            ImGui.SetNextItemOpen(false)
            seededDetailsOpen = true
        elseif seededName == 'timer' and not seededTimerOpen then
            ImGui.SetNextItemOpen(true)
            seededTimerOpen = true
        end
    end
    return ImGui.CollapsingHeader(label)
end

local function latestXPSnapshot(xp)
    local rows = xp and xp.snapshots or nil
    if type(rows) ~= 'table' or #rows == 0 then return nil end
    return rows[1]
end

local function latestMoneySnapshot(currentSnap)
    local rows = currentSnap and currentSnap.money and currentSnap.money.snapshots or nil
    if type(rows) ~= 'table' or #rows == 0 then return nil end
    return rows[1]
end

local card

--- Build a per-zone aggregate from all XP + coin snapshots.
local function buildZoneScoreboard(xpRows, moneyRows)
    local byZone = {}
    local order = {}
    local function getZone(z)
        z = tostring(z or '')
        if z == '' then z = 'Unknown' end
        if not byZone[z] then
            byZone[z] = { zone = z, runs = 0, bestXPhr = 0, bestAAhr = 0, bestCpHr = 0,
                          bestXPRuntime = 0, bestCpRuntime = 0 }
            order[#order + 1] = z
        end
        return byZone[z]
    end
    for _, r in ipairs(xpRows or {}) do
        local rt = tonumber(r.runtime) or 0
        if rt < 90 then goto continue_xp end  -- skip sub-90s runs (transit noise)
        local e = getZone(r.zone)
        e.runs = e.runs + 1
        local xphr = tonumber(r.xpPerHour) or 0
        local aahr = tonumber(r.aaPerHour) or 0
        if xphr > e.bestXPhr then e.bestXPhr = xphr; e.bestXPRuntime = rt end
        if aahr > e.bestAAhr then e.bestAAhr = aahr end
        ::continue_xp::
    end
    for _, r in ipairs(moneyRows or {}) do
        local e = getZone(r.zone)
        local rt = tonumber(r.runtime) or 0
        local cp = tonumber(r.totalCp) or 0
        if rt >= 60 and cp > 0 then
            local cphr = (cp / rt) * 3600
            if cphr > e.bestCpHr then e.bestCpHr = cphr; e.bestCpRuntime = rt end
        end
    end
    local result = {}
    for _, z in ipairs(order) do result[#result + 1] = byZone[z] end
    table.sort(result, function(a, b)
        if a.bestXPhr ~= b.bestXPhr then return a.bestXPhr > b.bestXPhr end
        return a.bestCpHr > b.bestCpHr
    end)
    return result
end

local function renderZoneScoreboard(xpRows, moneyRows)
    local rows = buildZoneScoreboard(xpRows, moneyRows)
    if #rows == 0 then
        ImGui.TextDisabled('No snapshots yet. Snapshot after a camp to build your scoreboard.')
        return
    end
    local flags = ImGuiTableFlags.Borders + ImGuiTableFlags.RowBg + ImGuiTableFlags.SizingStretchProp
    if ImGui.BeginTable('TGZoneBoard', 5, flags) then
        ImGui.TableSetupColumn('Zone')
        ImGui.TableSetupColumn('Best XP/hr')
        ImGui.TableSetupColumn('Best AA/hr')
        ImGui.TableSetupColumn('Best Coin/hr')
        ImGui.TableSetupColumn('Runs')
        ImGui.TableHeadersRow()
        for i, e in ipairs(rows) do
            ImGui.TableNextRow()
            ImGui.TableNextColumn(); ImGui.Text(e.zone:sub(1, 22))
            if ImGui.IsItemHovered() and #e.zone > 22 then
                ImGui.BeginTooltip(); ImGui.Text(e.zone); ImGui.EndTooltip()
            end
            ImGui.TableNextColumn()
            if e.bestXPhr > 0 then ImGui.TextColored(0.62, 1.0, 0.62, 1.0, formatLevelRate(e.bestXPhr))
            else ImGui.TextDisabled('-') end
            ImGui.TableNextColumn()
            if e.bestAAhr > 0 then ImGui.TextColored(0.76, 0.60, 0.95, 1.0, formatAARate(e.bestAAhr))
            else ImGui.TextDisabled('-') end
            ImGui.TableNextColumn()
            if e.bestCpHr > 0 then ImGui.TextColored(1.0, 0.86, 0.42, 1.0, formatCopperPerHour(e.bestCpHr))
            else ImGui.TextDisabled('-') end
            ImGui.TableNextColumn()
            ImGui.TextDisabled(tostring(e.runs))
            if ImGui.IsItemHovered() then
                ImGui.BeginTooltip()
                if e.bestXPhr > 0 then ImGui.Text('Best XP run: ' .. formatElapsed(e.bestXPRuntime)) end
                if e.bestCpHr > 0 then ImGui.Text('Best coin run: ' .. formatElapsed(e.bestCpRuntime)) end
                ImGui.EndTooltip()
            end
        end
        ImGui.EndTable()
    end
end

local function renderStoppedDashboard()
    local currentSnap = snap or {}
    local xp = getXPSection() or {}
    local xpRows = combinedXpSnapshotRows(xp)
    local moneyRows = combinedMoneySnapshotRows(currentSnap)
    local lastXP = latestXPSnapshot(xp)
    if not lastXP and type(xpRows) == 'table' and #xpRows > 0 then
        lastXP = xpRows[1]
    end
    local lastCoin = latestMoneySnapshot(currentSnap)
    if not lastCoin and type(moneyRows) == 'table' and #moneyRows > 0 then
        lastCoin = moneyRows[1]
    end
    local lastActivity = activityRows(1)[1]

    ImGui.TextColored(0.88, 0.78, 0.34, 1.0, 'Best Spots')
    renderZoneScoreboard(xpRows, moneyRows)

    ImGui.Spacing()
    if sessionCompare.lastMsg ~= '' then
        ImGui.TextColored(0.62, 0.72, 0.82, 1.0, 'Last Timed Challenge')
        ImGui.TextColored(0.55, 0.92, 0.62, 1.0, sessionCompare.lastMsg)
        ImGui.Spacing()
    end

    if lastXP or lastCoin or lastActivity then
        ImGui.TextColored(0.62, 0.70, 0.86, 1.0, 'Most recent saves')
        if lastXP then
            ImGui.TextColored(0.70, 0.90, 1.0, 1.0,
                string.format('XP %s  AA %s  %s',
                    formatLevelGain(lastXP.xpGained or 0), formatAAUnits(lastXP.aaGained or 0),
                    formatElapsed(lastXP.runtime or 0)))
            if ImGui.IsItemHovered() then
                ImGui.BeginTooltip()
                ImGui.Text(tostring(lastXP.zone or ''))
                ImGui.EndTooltip()
            end
        end
        if lastCoin then
            ImGui.TextColored(1.0, 0.95, 0.55, 1.0,
                string.format('Coin %s  %d events',
                    formatCopperCompact(lastCoin.totalCp or 0), tonumber(lastCoin.events) or 0))
            if ImGui.IsItemHovered() then
                ImGui.BeginTooltip()
                ImGui.Text(tostring(lastCoin.zone or ''))
                ImGui.EndTooltip()
            end
        end
        if lastActivity then
            ImGui.TextColored(1.0, 0.85, 0.35, 1.0,
                string.format('%s  %s',
                    tostring(lastActivity.label or lastActivity.kind or 'Activity'),
                    activitySummary(lastActivity)))
            if ImGui.IsItemHovered() then
                ImGui.BeginTooltip()
                ImGui.Text(tostring(lastActivity.zone or ''))
                local details = activityDetails(lastActivity)
                if details ~= '' then ImGui.Text(details) end
                ImGui.EndTooltip()
            end
        end
        ImGui.Spacing()
    end

    ImGui.TextDisabled('Tracks XP, AA, coin, and session time.')
    ImGui.TextDisabled('Press Start when ready.')

    ImGui.Spacing()
    renderGainsAutostartPanel()

    -- Timed Challenge: show compact inline status when stopped.
    ImGui.Spacing()
    ImGui.Separator()
    if true then  -- always show (was CollapsingHeader)
        if not M.isEngineRunning() then
            ImGui.TextColored(0.75, 0.72, 0.45, 1.0, 'Start TurboGains to activate.')
        end
        renderSessionCompareTimer()
    end
end

card = function(label, value, sub, r, g, b)
    ImGui.TextColored(0.62, 0.70, 0.86, 1.0, label)
    ImGui.TextColored(r, g, b, 1.0, tostring(value or '-'))
    if sub and sub ~= '' then ImGui.TextDisabled(tostring(sub)) end
end

--- 1.1.3: bordered card with a tinted top stripe.
---
--- Approach: submit a real item boundary first with Dummy(), then paint
--- the background rectangle and text inside that reserved item. MQ ImGui
--- can assert if SetCursorPos is used to grow parent/table bounds without
--- a submitted item; the Dummy is the authoritative footprint.
---
--- Why not nested BeginChild (v1.1.0): GetContentRegionAvail inside a
--- fresh TableNextColumn doesn't reliably return the column width on
--- the first frame, so the child overflowed and overlapped neighbors.
---
--- Why not ChannelsSplit/Merge (v1.1.1): that drawlist binding isn't
--- used anywhere else in this codebase; can't be sure MQ Next exposes
--- it without crashing. Sticking to AddRectFilled / AddRect / Text
--- which are proven elsewhere in the suite.
local function cardWithStripe(idSuffix, label, value, sub, r, g, b, hidden, sr, sg, sb)
    local PADDING_X = 7
    local PADDING_Y = 4
    local STRIPE_H = 2

    local fontSize = ImGui.GetFontSize()
    local lineH = fontSize + math.ceil(ImGui.GetStyle().ItemSpacing.y)
    local hasSub = (not hidden) and sub and sub ~= ''
    -- Always allocate 3 text lines so all cards in a row are the same height.
    local lines = 3
    _ = hasSub  -- used below for whether to actually render the sub text
    local cardH = PADDING_Y * 2 + STRIPE_H + (lineH * lines) + 2

    -- Card spans the full available width of this table cell. Use
    -- GetContentRegionAvail.x for the width — inside a table cell it
    -- returns the cell's content width correctly AFTER TableNextColumn
    -- has run at least one frame. On the very first frame the column
    -- widths may not be finalized; ImGui pads conservatively in that
    -- case, and the cell shrinks to fit on frame 2.
    local availW = ImGui.GetContentRegionAvail()
    local startX = ImGui.GetCursorPosX()
    local startY = ImGui.GetCursorPosY()
    local x1, y1 = ImGui.GetCursorScreenPos()
    local x2 = x1 + availW
    local y2 = y1 + cardH

    ImGui.Dummy(availW, cardH + 2)

    local drawList = ImGui.GetWindowDrawList()

    -- Background rect (drawn first; text will render on top via normal flow).
    drawList:AddRectFilled(
        ImVec2(x1, y1), ImVec2(x2, y2),
        IM_COL32(30, 34, 44, 200), 0)
    -- Top stripe — use dedicated stripe color (sr/sg/sb) when provided,
    -- otherwise fall back to the card value color brightened slightly.
    if not hidden then
        local stripeR = math.floor(math.min((sr or r) * 255 * 1.05, 255))
        local stripeG = math.floor(math.min((sg or g) * 255 * 1.05, 255))
        local stripeB = math.floor(math.min((sb or b) * 255 * 1.05, 255))
        drawList:AddRectFilled(
            ImVec2(x1, y1), ImVec2(x2, y1 + STRIPE_H),
            IM_COL32(stripeR, stripeG, stripeB, 230), 0)
    end
    -- Border (drawn last so it sits on top of the bg and stripe edges).
    drawList:AddRect(
        ImVec2(x1, y1), ImVec2(x2, y2),
        IM_COL32(60, 68, 84, 180), 0, 0, 1.0)

    -- Text is drawn over the reserved item. Cursor movement here is only
    -- for placement inside the already-submitted Dummy footprint.
    -- Clip all text to card bounds — prevents text from inflating DC.CursorMaxPos
    -- and pushing the window wider than the card column.
    ImGui.PushClipRect(x1, y1, x2, y2 + 2, true)

    ImGui.SetCursorPosX(startX + PADDING_X)
    ImGui.SetCursorPosY(startY + PADDING_Y + STRIPE_H)

    ImGui.TextColored(0.66, 0.74, 0.88, 1.0, label)
    if hidden then
        ImGui.SetCursorPosX(startX + PADDING_X)
        ImGui.TextColored(0.45, 0.50, 0.62, 1.0, 'Hidden')
    else
        ImGui.SetCursorPosX(startX + PADDING_X)
        ImGui.TextColored(r, g, b, 1.0, tostring(value or '-'))
        if hasSub then
            ImGui.SetCursorPosX(startX + PADDING_X)
            -- Clip subtitle to card width so it never overflows into neighbors.
            local maxSubChars = math.max(6, math.floor((availW - PADDING_X * 2) / math.max(1, fontSize * 0.54)))
            local clippedSub = #sub > maxSubChars and sub:sub(1, maxSubChars - 2) .. '..' or sub
            ImGui.TextDisabled(clippedSub)
            if #sub > maxSubChars and ImGui.IsItemHovered() then
                ImGui.BeginTooltip()
                ImGui.TextDisabled(sub)
                ImGui.EndTooltip()
            end
        end
    end

    ImGui.PopClipRect()

    -- Restore the cursor to the end of the real item. This preserves the
    -- table cell bounds established by Dummy() and avoids parent-boundary
    -- extension warnings.
    local endY = startY + cardH + 2
    ImGui.SetCursorPosX(startX)
    ImGui.SetCursorPosY(endY)
end

--- Returns (bestXPhr, bestCpHr) for the current zone from snapshot history.
local function zoneBestRates(xp, currentSnap)
    local xps = (type(xp) == 'table' and xp.session) or {}
    local zone = tostring(xps.currentZone or '')
    if zone == '' then return 0, 0 end
    local xpRows = combinedXpSnapshotRows(xp)
    local moneyRows = combinedMoneySnapshotRows(currentSnap)
    local bestXP, bestCp = 0, 0
    for _, r in ipairs(xpRows) do
        if tostring(r.zone or '') == zone then
            bestXP = math.max(bestXP, tonumber(r.xpPerHour) or 0)
        end
    end
    for _, r in ipairs(moneyRows) do
        if tostring(r.zone or '') == zone then
            local rt = tonumber(r.runtime) or 0
            local cp = tonumber(r.totalCp) or 0
            if rt >= 60 then bestCp = math.max(bestCp, (cp / rt) * 3600) end
        end
    end
    return bestXP, bestCp
end

local function renderSummaryCards(s, l, xp, xps, display, wallet, currentSnap)
    local elapsed, isPaused = sessionElapsed(s)
    local zoneStr = tostring(xps.currentZone or '')
    local timeSub = zoneStr ~= '' and zoneStr or 'TurboGains'
    if isPaused then
        timeSub = 'Paused - ' .. timeSub
    end
    -- Hot streak: is this session beating the zone record?
    local zoneRecordXP, zoneRecordCp = zoneBestRates(xp, currentSnap or {})
    local liveXPhr = tonumber(xps.xpPerHour) or 0
    local isXPRecord = liveXPhr > 0 and zoneRecordXP > 0 and liveXPhr > zoneRecordXP
    local liveCpHr = (elapsed > 30) and math.floor(((tonumber(s.totalCp) or 0) / elapsed) * 3600 + 0.5) or 0
    local isCpRecord = liveCpHr > 0 and zoneRecordCp > 0 and liveCpHr > zoneRecordCp

    local cards = {}
    cards[#cards + 1] = function()
        local xpOn = displayEnabled(display, 'pageXP')
        local aaOn = displayEnabled(display, 'pageAA')
        if xpOn and aaOn then
            local xpEta = tostring(xps.etaLevel or '-')
            local _xpRate = tonumber(xps.xpPerHour) or 0
            local _aaRate = tonumber(xps.aaPerHour) or 0
            local xpAaSub
            if xpEta ~= '-' then
                xpAaSub = string.format('%s XP  ETA %s', formatLevelRate(_xpRate), xpEta)
            elseif _xpRate > 0 or _aaRate > 0 then
                xpAaSub = string.format('%s XP  %s', formatLevelRate(_xpRate), formatAARate(_aaRate))
            else
                xpAaSub = ''
            end
            local xpLabel = isXPRecord and 'XP / AA  * HOT *' or 'XP / AA'
            local xpR = isXPRecord and 1.0 or 0.68
            local xpG = isXPRecord and 0.88 or 0.86
            local xpB = isXPRecord and 0.25 or 0.95
            -- Stripe: gold when HOT, otherwise electric cyan.
            local xpSR = isXPRecord and 1.0 or 0.20
            local xpSG = isXPRecord and 0.88 or 0.82
            local xpSB = isXPRecord and 0.10 or 0.95
            cardWithStripe('tg_xpaa', xpLabel,
                (tonumber(xps.aaGained) or 0) ~= 0
                    and (formatLevelGain(xps.xpGained or 0) .. ' / ' .. formatAAUnits(xps.aaGained or 0, true))
                    or  formatLevelGain(xps.xpGained or 0),
                xpAaSub,
                xpR, xpG, xpB, false, xpSR, xpSG, xpSB)
        elseif xpOn then
            cardWithStripe('tg_xp', 'XP', formatLevelGain(xps.xpGained or 0),
                string.format('%s now  %s', formatPct(xps.currentPctExp or 0), formatLevelRate(xps.xpPerHour or 0)),
                0.62, 1.0, 0.62, false, 0.20, 0.82, 0.95)
        elseif aaOn then
            cardWithStripe('tg_aa', 'AA', formatAAUnits(xps.aaGained or 0, true),
                string.format('%s now  %s', formatPct(xps.currentPctAA or 0), formatAARate(xps.aaPerHour or 0)),
                0.76, 0.60, 0.95, false, 0.58, 0.30, 0.95)
        else
            cardWithStripe('tg_xpaa', 'XP/AA', 'Hidden', '', 0.45, 0.50, 0.62, true)
        end
    end
    cards[#cards + 1] = function()
        if displayEnabled(display, 'pageCoin') then
            local coinCpHr = elapsed > 30
                and math.floor(((tonumber(s.totalCp) or 0) / elapsed) * 3600 + 0.5)
                or 0
            local coinSub = coinCpHr > 0
                and string.format('%s/hr  ·  %d events', formatCopperCompact(coinCpHr), tonumber(s.events) or 0)
                or string.format('%d events  life %s', tonumber(s.events) or 0, formatCopperCompact(tonumber(l.totalCp) or 0))
            local coinLabel = isCpRecord and 'Coin  * HOT *' or 'Coin'
            local cG = isCpRecord and 0.95 or 0.86
            local cB = isCpRecord and 0.25 or 0.42
            -- Stripe: bright gold (hot) or warm amber (normal)
            local coinSR = isCpRecord and 1.0 or 0.95
            local coinSG = isCpRecord and 0.95 or 0.72
            local coinSB = isCpRecord and 0.10 or 0.12
            cardWithStripe('tg_coin', coinLabel, formatCopperCompact(tonumber(s.totalCp) or 0),
                coinSub, 1.0, cG, cB, false, coinSR, coinSG, coinSB)
        else
            cardWithStripe('tg_coin', 'Coin', 'Hidden', '', 0.45, 0.50, 0.62, true)
        end
    end
    cards[#cards + 1] = function()
        local safeZonePaused = isPaused and (currentSnap and currentSnap.session and currentSnap.session.safeZonePaused == true)
        local sessSubText = safeZonePaused and (zoneStr .. ' (auto-paused)') or timeSub
        -- Stripe: warm amber when paused, violet when running
        local sessSR = isPaused and 0.95 or 0.60
        local sessSG = isPaused and 0.65 or 0.35
        local sessSB = isPaused and 0.15 or 0.95
        cardWithStripe('tg_sess', 'Session', formatElapsed(elapsed), sessSubText,
            isPaused and 0.95 or 0.74, isPaused and 0.65 or 0.82, isPaused and 0.30 or 0.92, false,
            sessSR, sessSG, sessSB)
    end
    cards[#cards + 1] = function()
        local w = type(wallet) == 'table' and wallet or {}
        cardWithStripe('tg_wallet', 'Wallet', tostring(w.plat or 0) .. 'pp',
            string.format('%s AA  %s DC  %s tribute', tostring(w.aa or 0), tostring(w.dc or 0), tostring(w.favor or 0)),
            0.88, 0.78, 0.34, false, 0.18, 0.82, 0.68)
    end

    local avail = ImGui.GetContentRegionAvail()
    local sp = ImGui.GetStyle().ItemSpacing.x
    -- Use 2x2 grid by default; 4-col only on very wide windows (>580px content).
    -- 4 cards at 145px each = 580px threshold. Below that, 2x2 is less cramped
    -- and stops card text from driving the window wider than needed.
    local w4 = (avail - (sp * 3)) / 4
    local w2 = (avail - sp) / 2
    local cols
    if w4 >= 145 then
        cols = 4
    elseif w2 >= 100 then
        cols = 2
    else
        cols = 1
    end

    if ImGui.BeginTable('TurboGainsSummaryCards', cols, ImGuiTableFlags.SizingStretchProp) then
        for i = 1, cols do
            ImGui.TableSetupColumn('C' .. tostring(i))
        end
        --- Each logical row must start with TableNextRow(); TableNextColumn() alone wraps
        --- unpredictably across rows and can trigger ImGui "Missing End()" when cols < #cards.
        for idx, drawCard in ipairs(cards) do
            if ((idx - 1) % cols) == 0 then
                ImGui.TableNextRow()
            end
            ImGui.TableNextColumn()
            drawCard()
        end
        ImGui.EndTable()
    end
end

--- Show the player's best recorded rates for the current zone so they can
--- see in real time whether they are beating their personal record.
local function renderCurrentZoneBest(xp, currentSnap)
    local xps = (type(xp) == 'table' and xp.session) or {}
    local zone = tostring(xps.currentZone or '')
    if zone == '' then return end

    local xpRows = combinedXpSnapshotRows(xp)
    local moneyRows = combinedMoneySnapshotRows(currentSnap)

    local bestXPhr, bestAAhr, bestCpHr = 0, 0, 0
    for _, r in ipairs(xpRows) do
        if tostring(r.zone or '') == zone then
            bestXPhr = math.max(bestXPhr, tonumber(r.xpPerHour) or 0)
            bestAAhr = math.max(bestAAhr, tonumber(r.aaPerHour) or 0)
        end
    end
    for _, r in ipairs(moneyRows) do
        if tostring(r.zone or '') == zone then
            local rt = tonumber(r.runtime) or 0
            local cp = tonumber(r.totalCp) or 0
            if rt >= 60 and cp > 0 then
                bestCpHr = math.max(bestCpHr, (cp / rt) * 3600)
            end
        end
    end

    if bestXPhr <= 0 and bestAAhr <= 0 and bestCpHr <= 0 then return end

    -- "Best:" on its own line; full zone name available on hover.
    ImGui.TextDisabled('Best:')
    if ImGui.IsItemHovered() then
        ImGui.BeginTooltip(); ImGui.Text('Best in ' .. zone); ImGui.EndTooltip()
    end
    ImGui.SameLine(0, 6)
    local parts = {}
    if bestXPhr > 0 then parts[#parts + 1] = { text = formatLevelRate(bestXPhr), r = 0.62, g = 1.0, b = 0.62 } end
    if bestAAhr > 0 then parts[#parts + 1] = { text = formatAARate(bestAAhr), r = 0.76, g = 0.60, b = 0.95 } end
    if bestCpHr > 0 then parts[#parts + 1] = { text = formatCopperPerHour(bestCpHr), r = 1.0, g = 0.86, b = 0.42 } end
    for i, p in ipairs(parts) do
        if i > 1 then ImGui.SameLine(0, 10) end
        ImGui.TextColored(p.r, p.g, p.b, 1.0, p.text)
    end
end

local function renderSnapshotStrip(xp, currentSnap)
    local xpSnap = latestXPSnapshot(xp)
    local coinSnap = latestMoneySnapshot(currentSnap)
    local xpMeaningful = xpSnap and (
        (tonumber(xpSnap.xpGained) or 0) ~= 0
        or (tonumber(xpSnap.aaGained) or 0) ~= 0
        or (tonumber(xpSnap.xpPerHour) or 0) ~= 0
        or (tonumber(xpSnap.aaPerHour) or 0) ~= 0)
    local coinMeaningful = coinSnap and (
        (tonumber(coinSnap.totalCp) or 0) > 0
        or (tonumber(coinSnap.events) or 0) > 0
        or (tonumber(coinSnap.biggestCp) or 0) > 0)
    if not xpMeaningful and not coinMeaningful then
        return
    end

    -- "Save:" prefix is shorter than "Latest save:" but still clear.
    ImGui.TextDisabled('Save:')
    ImGui.SameLine(0, 6)
    if xpMeaningful then
        local snapXP   = tonumber(xpSnap.xpGained) or 0
        local snapAA   = tonumber(xpSnap.aaGained) or 0
        local snapRate = tonumber(xpSnap.xpPerHour) or 0
        local snapAAhr = tonumber(xpSnap.aaPerHour) or 0
        -- Only include AA if it's non-zero to keep the line short.
        local gainStr = snapAA ~= 0
            and (formatLevelGain(snapXP) .. '  ' .. formatAAUnits(snapAA))
            or  formatLevelGain(snapXP)
        local rateStr = snapRate > 0 and (' @ ' .. formatLevelRate(snapRate))
            or (snapAAhr > 0 and (' @ ' .. formatAARate(snapAAhr)) or '')
        ImGui.TextColored(0.62, 1.0, 0.62, 1.0, gainStr .. rateStr)
    end
    if coinMeaningful then
        if xpMeaningful then ImGui.SameLine(0, 8) end
        ImGui.TextColored(1.0, 0.95, 0.55, 1.0, formatCopperCompact(coinSnap.totalCp or 0))
        local evCount = tonumber(coinSnap.events) or 0
        if evCount > 0 then
            ImGui.SameLine(0, 4); ImGui.TextDisabled(tostring(evCount) .. 'ev')
        end
    end
end

local function renderGainsSubTabs(g)
    if type(g) ~= 'table' then return 'scoreboard' end
    local page = tostring(g.gainsPage or 'scoreboard'):lower()
    if page ~= 'scoreboard' and page ~= 'snapshots' and page ~= 'settings' and page ~= 'tools' then
        page = 'scoreboard'
    end
    local avail = ImGui.GetContentRegionAvail()
    local sp = ImGui.GetStyle().ItemSpacing.x
    local cols = 4
    while cols > 1 and ((avail - sp * (cols - 1)) / cols) < 60 do
        cols = cols - 1
    end
    local w = math.max(1, math.floor((avail - sp * (cols - 1)) / cols))
    local tabIndex = 0
    local function tab(label, id, tooltip)
        tabIndex = tabIndex + 1
        if cols > 1 and ((tabIndex - 1) % cols) > 0 then
            ImGui.SameLine(0, sp)
        end
        if Ui.subTabButton(label .. '##gains_page_' .. id, page == id, w, 22) then
            g.gainsPage = id
            page = id
        end
        if tooltip then Ui.tooltip(tooltip) end
    end
    tab('Score', 'scoreboard', 'Scoreboard summary: XP/AA, coin, session time, challenge, and details.')
    tab('History', 'snapshots', 'Saved snapshot history.')
    tab('Show', 'settings', 'Choose which Gains fields are visible.')
    tab('More', 'tools', 'Snapshot, reset, report, and announce tools.')
    return page
end

local function renderDisplaySettings(display, compact)
    ImGui.TextColored(0.62, 0.70, 0.86, 1.0, 'View:')
    toggleButton('Compact', 'view_compact', compact, '/turbogains view compact toggle', 84)
    ImGui.SameLine()
    toggleButton('Full', 'view_full', not compact, '/turbogains view full toggle', 74)

    renderToggleGroup('Mini', {
        { label = 'XP', cmdKey = 'xp', displayKey = 'miniXP' },
        { label = 'AA', cmdKey = 'aa', displayKey = 'miniAA' },
        { label = 'Coin', cmdKey = 'coin', displayKey = 'miniCoin' },
        { label = 'Time', cmdKey = 'time', displayKey = 'miniTime' },
    }, display, 'mini')

    renderToggleGroup('Page', {
        { label = 'XP', cmdKey = 'xp', displayKey = 'pageXP' },
        { label = 'AA', cmdKey = 'aa', displayKey = 'pageAA' },
        { label = 'Coin', cmdKey = 'coin', displayKey = 'pageCoin' },
        { label = 'Feed', cmdKey = 'feed', displayKey = 'pageFeed' },
        { label = 'Snaps', cmdKey = 'snapshots', displayKey = 'pageSnapshots' },
    }, display, 'page')

    renderToggleGroup('XP Fields', {
        { label = 'Current', shortLabel = 'Cur', cmdKey = 'currentxp', displayKey = 'xpCurrent', width = 84 },
        { label = 'Gained', shortLabel = 'Gain', cmdKey = 'xpgained', displayKey = 'xpGained', width = 80 },
        { label = 'XP/hr', cmdKey = 'xprate', displayKey = 'xpRate', width = 72 },
        { label = 'ETA', cmdKey = 'xpeta', displayKey = 'xpEta', width = 64 },
    }, display, 'field')

    renderToggleGroup('AA Fields', {
        { label = 'Current', shortLabel = 'Cur', cmdKey = 'currentaa', displayKey = 'aaCurrent', width = 84 },
        { label = 'Gained', shortLabel = 'Gain', cmdKey = 'aagained', displayKey = 'aaGained', width = 80 },
        { label = 'AA/hr', cmdKey = 'aarate', displayKey = 'aaRate', width = 72 },
        { label = 'ETA', cmdKey = 'aaeta', displayKey = 'aaEta', width = 64 },
    }, display, 'field')

    renderToggleGroup('Meta', {
        { label = 'Level', cmdKey = 'level', displayKey = 'metaLevel', width = 70 },
        { label = 'AA Total', shortLabel = 'AA', cmdKey = 'aatotal', displayKey = 'metaAA', width = 86 },
        { label = 'Runtime', shortLabel = 'Run', cmdKey = 'runtime', displayKey = 'metaRuntime', width = 84 },
        { label = 'Zone', cmdKey = 'zone', displayKey = 'metaZone', width = 70 },
    }, display, 'field')

    renderToggleGroup('Coin Fields', {
        { label = 'Total', cmdKey = 'cointotal', displayKey = 'coinTotal', width = 68 },
        { label = 'Time', cmdKey = 'cointime', displayKey = 'coinTime', width = 66 },
        { label = 'Events', cmdKey = 'coinevents', displayKey = 'coinEvents', width = 74 },
        { label = 'Biggest', shortLabel = 'Big', cmdKey = 'coinbiggest', displayKey = 'coinBiggest', width = 78 },
        { label = 'Per Char', shortLabel = 'Char', cmdKey = 'coinperchar', displayKey = 'coinPerChar', width = 86 },
        { label = 'Feed', cmdKey = 'coinfeed', displayKey = 'coinFeed', width = 66 },
        { label = 'Snaps', cmdKey = 'coinsnapshots', displayKey = 'coinSnapshots', width = 70 },
    }, display, 'field')
end

local function renderPrimaryActions(xp, isPaused, currentSnap)
    local xpPaused = type(xp) == 'table' and xp.tracking == false
    local frozen = isPaused or xpPaused

    local avail = ImGui.GetContentRegionAvail()
    local gap = ImGui.GetStyle().ItemSpacing.x
    local btnW = math.min(108, math.floor((avail - gap) / 2))
    local totalW = (btnW * 2) + gap
    if avail > totalW then
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + math.floor((avail - totalW) * 0.5))
    end
    if Ui.buttonVariant((frozen and 'Resume##' or 'Pause##') .. 'tg_sess_pause',
        frozen and 'successButton' or 'secondaryButton', btnW, 24) then
        if frozen then
            mq.cmd('/turbogains resume')
            mq.cmd('/turbogains xp resume')
        else
            mq.cmd('/turbogains pause')
            mq.cmd('/turbogains xp pause')
        end
    end
    Ui.tooltip(frozen and 'Resume session timer, loot counting, and XP sampling.' or 'Pause session timer, loot counting, and XP sampling.')
    ImGui.SameLine(0, gap)
    if Ui.buttonVariant('Snapshot##tg_unified_snap', 'utilityButton', btnW, 24) then
        mq.cmd('/turbogains xp snapshot')
        mq.cmd('/turbogains coin snapshot')
    end
    Ui.tooltip('Writes XP/AA + coin snapshot rows. Saved snapshots are viewable in the History tab.')
end

local function renderToolsPage(currentSnap)
    local avail = ImGui.GetContentRegionAvail()
    local sp = ImGui.GetStyle().ItemSpacing.x
    local w2 = math.max(120, math.floor((avail - sp) / 2))

    if Ui.buttonVariant('Save Snapshot##tg_tools_save_snapshot', 'primaryButton', w2, 24) then
        mq.cmd('/turbogains snapshot all')
    end
    ImGui.SameLine()
    if Ui.buttonVariant('Clear Snapshots##tg_tools_clear_snapshot', 'secondaryButton', w2, 24) then
        mq.cmd('/turbogains clear snapshots')
    end

    if Ui.buttonVariant('Reset XP##tg_xp_reset_tools', 'secondaryButton', w2, 24) then
        mq.cmd('/turbogains xp reset')
    end
    ImGui.SameLine()
    if Ui.buttonVariant('XP Report##tg_xp_report_tools', 'secondaryButton', w2, 24) then
        mq.cmd('/turbogains xp status')
    end

    if Ui.buttonVariant('Reset Session##tg_coin_reset_session_tools', 'secondaryButton', w2, 24) then
        mq.cmd('/turbogains coin reset')
    end
    ImGui.SameLine()
    if Ui.buttonVariant('Reset Group##tg_coin_reset_group_tools', 'secondaryButton', w2, 24) then
        mq.cmd('/turbogains reset all')
    end

    if Ui.buttonVariant('Report to Chat##tg_coin_report_tools', 'secondaryButton', w2, 24) then
        mq.cmd('/turbogains coin report')
    end
    ImGui.SameLine()
    local announceOn = currentSnap and currentSnap.announce == true
    local toggleLabel = announceOn and 'Announce: ON##tg_coin_announce_tools' or 'Announce: OFF##tg_coin_announce_tools'
    if Ui.buttonVariant(toggleLabel, announceOn and 'successButton' or 'secondaryButton', w2, 24) then
        mq.cmd('/turbogains coin announce ' .. (announceOn and 'off' or 'on'))
    end

    ImGui.Spacing()
    ImGui.Separator()
    renderGainsAutostartPanel()
end

local function snapshotKey(row)
    return table.concat({
        tostring(row and row.time or ''),
        tostring(row and row.runtime or ''),
        tostring(row and row.zone or ''),
    }, '\31')
end

local function combinedSnapshotRows(xp, currentSnap)
    local rowsByKey = {}
    local ordered = {}

    local function ensureRow(key, source)
        local row = rowsByKey[key]
        if not row then
            row = {
                time = tostring(source and source.time or ''),
                runtime = tonumber(source and source.runtime) or 0,
                zone = tostring(source and source.zone or ''),
                coinCp = nil,
                xpGained = nil,
                aaGained = nil,
                events = nil,
            }
            rowsByKey[key] = row
            ordered[#ordered + 1] = row
        end
        return row
    end

    for _, xr in ipairs(combinedXpSnapshotRows(xp) or {}) do
        local row = ensureRow(snapshotKey(xr), xr)
        row.xpGained = tonumber(xr.xpGained) or 0
        row.aaGained = tonumber(xr.aaGained) or 0
    end
    for _, mr in ipairs(combinedMoneySnapshotRows(currentSnap) or {}) do
        local row = ensureRow(snapshotKey(mr), mr)
        row.coinCp = tonumber(mr.totalCp) or 0
        row.events = tonumber(mr.events) or 0
    end

    return ordered
end

activitySummary = function(row)
    row = type(row) == 'table' and row or {}
    if row.kind == 'reclaim_lotto' then
        return string.format('%d opened, %d reclaim',
            tonumber(row.opened) or 0,
            tonumber(row.reclaim) or 0)
    end
    return tostring(row.label or row.kind or 'activity')
end

activityDetails = function(row)
    row = type(row) == 'table' and row or {}
    if row.kind == 'reclaim_lotto' then
        return string.format('%d coin, %d ticket, %d sack, %d gem, %d pass',
            tonumber(row.coins) or 0,
            tonumber(row.tickets) or 0,
            tonumber(row.sacks) or 0,
            tonumber(row.gems) or 0,
            tonumber(row.passes) or 0)
    end
    return tostring(row.details or '')
end

local function activityLabel(row)
    row = type(row) == 'table' and row or {}
    if row.kind == 'reclaim_lotto' then return 'Reclaim/Lotto' end
    return tostring(row.label or row.kind or 'Activity')
end

local function activityTotals(rows)
    local totals = { reclaimLottoRuns = 0, opened = 0, reclaim = 0, coins = 0, tickets = 0, sacks = 0, gems = 0 }
    for _, row in ipairs(type(rows) == 'table' and rows or {}) do
        if row.kind == 'reclaim_lotto' then
            totals.reclaimLottoRuns = totals.reclaimLottoRuns + 1
            totals.opened = totals.opened + (tonumber(row.opened) or 0)
            totals.reclaim = totals.reclaim + (tonumber(row.reclaim) or 0)
            totals.coins = totals.coins + (tonumber(row.coins) or 0)
            totals.tickets = totals.tickets + (tonumber(row.tickets) or 0)
            totals.sacks = totals.sacks + (tonumber(row.sacks) or 0)
            totals.gems = totals.gems + (tonumber(row.gems) or 0)
        end
    end
    return totals
end

local function renderActivityHistory(maxRows, fixedHeight)
    local allRows = activityRows(0)
    if #allRows == 0 then return false end
    local rows = activityRows(maxRows or 8)
    local totals = activityTotals(allRows)

    ImGui.TextColored(0.62, 0.70, 0.86, 1.0, 'Activity Journal')
    if totals.reclaimLottoRuns > 0 then
        ImGui.TextColored(1.0, 0.85, 0.35, 1.0,
            string.format('Reclaim/Lotto lifetime: %d runs, %d opened, %d reclaim clicks',
                totals.reclaimLottoRuns, totals.opened, totals.reclaim))
        if ImGui.IsItemHovered() then
            ImGui.BeginTooltip()
            ImGui.Text(string.format('coins %d, tickets %d, sacks %d, gems %d',
                totals.coins, totals.tickets, totals.sacks, totals.gems))
            ImGui.EndTooltip()
        end
    end
    local flags = ImGuiTableFlags.Borders + ImGuiTableFlags.RowBg + ImGuiTableFlags.SizingStretchProp
    if fixedHeight and ImGuiTableFlags.ScrollY then flags = flags + ImGuiTableFlags.ScrollY end
    if ImGui.BeginTable('TurboGainsActivityJournal', 4, flags, 0, fixedHeight or 0) then
        ImGui.TableSetupColumn('Time', ImGuiTableColumnFlags.WidthFixed, 42.0)
        ImGui.TableSetupColumn('Zone', ImGuiTableColumnFlags.WidthFixed, 68.0)
        ImGui.TableSetupColumn('Activity', ImGuiTableColumnFlags.WidthFixed, 92.0)
        ImGui.TableSetupColumn('Details', ImGuiTableColumnFlags.WidthStretch, 1.0)
        ImGui.TableHeadersRow()
        for _, row in ipairs(rows) do
            ImGui.TableNextRow()
            ImGui.TableNextColumn()
            local at = tonumber(row.at)
            ImGui.Text(tostring(row.time or (at and os.date('%H:%M:%S', at)) or '-'))
            ImGui.TableNextColumn()
            ImGui.Text(shortText(row.zone or '-', 18))
            if tostring(row.zone or '') ~= '' and #tostring(row.zone or '') > 18 and ImGui.IsItemHovered() then
                ImGui.BeginTooltip(); ImGui.Text(tostring(row.zone)); ImGui.EndTooltip()
            end
            ImGui.TableNextColumn()
            ImGui.TextColored(1.0, 0.85, 0.35, 1.0, activityLabel(row))
            ImGui.TableNextColumn()
            local summary = activitySummary(row)
            local details = activityDetails(row)
            ImGui.Text(shortText(summary .. (details ~= '' and (' | ' .. details) or ''), 44))
            if ImGui.IsItemHovered() then
                ImGui.BeginTooltip()
                ImGui.Text(activityLabel(row))
                ImGui.Text(summary)
                if details ~= '' then ImGui.Text(details) end
                ImGui.EndTooltip()
            end
        end
        ImGui.EndTable()
    end
    return true
end


local function renderSnapshotsPage(xp, currentSnap)
    local xpRows2 = combinedXpSnapshotRows(xp)
    local moneyRows2 = combinedMoneySnapshotRows(currentSnap)
    local showedActivity = renderActivityHistory(8, 142)
    if showedActivity then
        ImGui.Dummy(0, 2)
        ImGui.Separator()
    end
    ImGui.TextColored(0.88, 0.78, 0.34, 1.0, 'Best Spots')
    renderZoneScoreboard(xpRows2, moneyRows2)
    ImGui.Dummy(0, 2)
    ImGui.Separator()
    ImGui.TextColored(0.62, 0.70, 0.86, 1.0, 'Run Log')
    local rows = combinedSnapshotRows(xp, currentSnap)
    if #rows == 0 then
        ImGui.TextDisabled('No runs yet. Hit Snapshot to record a camp.')
        return
    end
    table.sort(rows, function(a, b)
        -- Sort: best XP first, then best coin
        local ax = type(a.xpGained) == 'number' and a.xpGained or 0
        local bx = type(b.xpGained) == 'number' and b.xpGained or 0
        if ax ~= bx then return ax > bx end
        local ac = type(a.coinCp) == 'number' and a.coinCp or 0
        local bc = type(b.coinCp) == 'number' and b.coinCp or 0
        return ac > bc
    end)
    local flags = ImGuiTableFlags.Borders + ImGuiTableFlags.RowBg + ImGuiTableFlags.SizingStretchProp
    if ImGuiTableFlags.ScrollY then flags = flags + ImGuiTableFlags.ScrollY end
    local _, availH = ImGui.GetContentRegionAvail()
    local tableH = math.max(100, (tonumber(availH) or 200) - 8)
    local function snapshotTooltip(row)
        if not ImGui.IsItemHovered() then return end
        ImGui.BeginTooltip()
        ImGui.Text('Snapshot')
        ImGui.TextColored(0.55, 0.60, 0.70, 1.0, 'Events: ' .. tostring(row.events or 0))
        ImGui.EndTooltip()
    end

    if ImGui.BeginTable('TurboGainsUnifiedSnapshots', 5, flags, 0, tableH) then
        ImGui.TableSetupColumn('Run')
        ImGui.TableSetupColumn('Zone')
        ImGui.TableSetupColumn('Coin')
        ImGui.TableSetupColumn('XP')
        ImGui.TableSetupColumn('AA')
        ImGui.TableHeadersRow()
        for _, row in ipairs(rows) do
            ImGui.TableNextRow()
            -- Run column: show duration; hover reveals timestamp.
            ImGui.TableNextColumn()
            ImGui.Text(formatElapsed(row.runtime or 0))
            if ImGui.IsItemHovered() then
                ImGui.BeginTooltip()
                ImGui.Text(row.time ~= '' and row.time or '-')
                ImGui.Text('Events: ' .. tostring(row.events or 0))
                ImGui.EndTooltip()
            end
            ImGui.TableNextColumn()
            local zoneStr2 = row.zone ~= '' and row.zone or '-'
            ImGui.Text(shortText(zoneStr2, 18))
            if zoneStr2 ~= '-' and #zoneStr2 > 18 and ImGui.IsItemHovered() then
                ImGui.BeginTooltip(); ImGui.Text(zoneStr2); ImGui.EndTooltip()
            else
                snapshotTooltip(row)
            end
            ImGui.TableNextColumn(); ImGui.TextColored(1.0, 0.95, 0.55, 1.0, row.coinCp and formatCopperCompact(row.coinCp) or '-')
            ImGui.TableNextColumn(); ImGui.TextColored(0.62, 1.0, 0.62, 1.0, row.xpGained and formatLevelGain(row.xpGained) or '-')
            ImGui.TableNextColumn(); ImGui.TextColored(0.76, 0.60, 0.95, 1.0, row.aaGained and formatAAUnits(row.aaGained) or '-')
        end
        ImGui.EndTable()
    end
end

--- Public: render the body of the Tools > Gains page. Engine controls live-state;
--- Start/Stop use Turbo/gains_toggle + /e3bcaa.
function M.renderTab(state)
    local g = type(state) == 'table' and state.raw or nil
    -- One-shot width nudge: if window is wider than a comfortable size on the
    -- first frame, snap it to 380px. After that the user can resize freely.
    if not widthNudgeDone then
        local _cw, _ch = ImGui.GetWindowSize()
        if _cw > 400 then
            pcall(function() ImGui.SetWindowSize(380, _ch) end)
        end
        widthNudgeDone = true
    end
    refresh()
    tickSessionCompareTimer()
    local engineRunning = M.isEngineRunning()
    if engineRunning then startPressedAt = 0 end
    local now = os.time()
    local inStartGrace = startPressedAt > 0 and (now - startPressedAt) <= 15
    local displayRunning = engineRunning or inStartGrace

    renderEngineHeader(displayRunning)
    ImGui.Separator()
    renderArcadeScore(g)

    if not displayRunning then
        renderStoppedDashboard()
        return
    end

    local currentSnap = snap or {}
    local s = currentSnap.session or {}
    local l = currentSnap.lifetime or {}
    local xp = getXPSection() or {}
    local xps = xp.session or {}
    local display = currentSnap.display or {}
    local compact = display.compact ~= false
    local gainsPage = renderGainsSubTabs(g)
    ImGui.Separator()

    if gainsPage == 'snapshots' then
        renderSnapshotsPage(xp, currentSnap)
        return
    elseif gainsPage == 'settings' then
        ensureWindowHeight(680)
        renderDisplaySettings(display, compact)
        return
    elseif gainsPage == 'tools' then
        renderToolsPage(currentSnap)
        return
    end

    local elapsed, isPaused = sessionElapsed(s)
    renderPrimaryActions(xp, isPaused, currentSnap)
    ImGui.Dummy(0, 3)
    renderSummaryCards(s, l, xp, xps, display, state and state.wallet, currentSnap)
    ImGui.Dummy(0, 2)
    renderSnapshotStrip(xp, currentSnap)
    renderCurrentZoneBest(xp, currentSnap)

    ImGui.Dummy(0, 2)
    ImGui.Separator()
    renderSessionCompareTimer()

    if compact then
        if defaultClosedHeader('Details##gains_compact_details', 'details') then
            ensureWindowHeight(760)
            if displayEnabled(display, 'pageSnapshots') and hasMeaningfulXPSnapshots(xp) then
                if ImGui.CollapsingHeader('XP Snapshots##details_xp_snaps') then
                    ensureWindowHeight(820)
                    renderXPSnapshots(xp, display)
                end
            end
            if displayEnabled(display, 'pageFeed') and displayEnabled(display, 'coinPerChar') and hasPerCharRows(currentSnap) then
                if ImGui.CollapsingHeader('Per-character##details_per_char') then
                    ensureWindowHeight(820)
                    renderPerChar()
                end
            end
            if displayEnabled(display, 'pageFeed') and displayEnabled(display, 'coinFeed') and hasRecentRows(currentSnap) then
                if ImGui.CollapsingHeader('Recent Coin Feed##details_coin_feed') then
                    ensureWindowHeight(820)
                    renderRecent()
                end
            end
            if displayEnabled(display, 'pageSnapshots') and displayEnabled(display, 'coinSnapshots') and hasMeaningfulMoneySnapshots(currentSnap) then
                if ImGui.CollapsingHeader('Coin Snapshots##details_coin_snaps') then
                    ensureWindowHeight(820)
                    renderMoneySnapshots()
                end
            end
        end
        ImGui.Spacing()
        ImGui.Dummy(0, 10)
        return
    end

    if defaultClosedHeader('Details##gains_full_details', 'details') then
        ensureWindowHeight(820)
        if xps and (displayEnabled(display, 'pageXP') or displayEnabled(display, 'pageAA')) then
            sectionTitle('XP / AA', 0.70, 0.88, 1.0)
            if displayEnabled(display, 'metaZone') and xps.currentZone and xps.currentZone ~= '' then
                labelValue('Zone', xps.currentZone, 0.74, 0.82, 0.92)
            end

            local xpHasGain = ((tonumber(xps.levelUps) or 0) ~= 0) or ((tonumber(xps.xpGained) or 0) ~= 0)
            local xpHasRate = (tonumber(xps.xpPerHour) or 0) ~= 0
            local xpHasEta = tostring(xps.etaLevel or '-') ~= '-'
            local aaHasGain = ((tonumber(xps.aaPointsGained) or 0) ~= 0) or ((tonumber(xps.aaGained) or 0) ~= 0)
            local aaHasRate = (tonumber(xps.aaPerHour) or 0) ~= 0
            local aaHasEta = tostring(xps.etaAA or '-') ~= '-'

            if displayEnabled(display, 'pageXP') then
                renderMetricRow({
                    { show = displayEnabled(display, 'xpCurrent'), label = 'XP', value = formatPct(xps.currentPctExp or 0), r = 0.62, g = 1.0, b = 0.62 },
                    { show = displayEnabled(display, 'xpGained') and xpHasGain, label = 'XP Gained', value = formatLevelGain(xps.xpGained or 0), r = 0.62, g = 1.0, b = 0.62 },
                    { show = displayEnabled(display, 'xpRate') and xpHasRate, label = 'XP/hr', value = formatLevelRate(xps.xpPerHour or 0), r = 0.62, g = 1.0, b = 0.62 },
                    { show = displayEnabled(display, 'xpEta') and xpHasEta, label = 'ETA', value = tostring(xps.etaLevel or '-'), r = 0.74, g = 0.82, b = 0.92 },
                })
            end

            if displayEnabled(display, 'pageAA') then
                renderMetricRow({
                    { show = displayEnabled(display, 'aaCurrent'), label = 'AA', value = formatPct(xps.currentPctAA or 0), r = 0.76, g = 0.60, b = 0.95 },
                    { show = displayEnabled(display, 'aaGained') and aaHasGain, label = 'AA Gained', value = formatAAUnits(xps.aaGained or 0), r = 0.76, g = 0.60, b = 0.95 },
                    { show = displayEnabled(display, 'aaRate') and aaHasRate, label = 'AA/hr', value = formatAARate(xps.aaPerHour or 0), r = 0.76, g = 0.60, b = 0.95 },
                    { show = displayEnabled(display, 'aaEta') and aaHasEta, label = 'ETA', value = tostring(xps.etaAA or '-'), r = 0.74, g = 0.82, b = 0.92 },
                })
            end

            if displayEnabled(display, 'metaLevel') or displayEnabled(display, 'metaAA') or displayEnabled(display, 'metaRuntime') then
                renderMetricRow({
                    { show = displayEnabled(display, 'metaLevel'), label = 'Level', value = tonumber(xps.currentLevel) or 0, r = 0.74, g = 0.82, b = 0.92 },
                    { show = displayEnabled(display, 'metaAA'), label = 'AA Total', value = tonumber(xps.currentAA) or 0, r = 0.74, g = 0.82, b = 0.92 },
                    { show = displayEnabled(display, 'metaRuntime'), label = 'Runtime', value = formatElapsed(tonumber(xp.runtime) or 0), r = 0.74, g = 0.82, b = 0.92 },
                })
            end

            if displayEnabled(display, 'pageSnapshots') and hasMeaningfulXPSnapshots(xp) then
                if ImGui.CollapsingHeader('XP Snapshots') then
                    renderXPSnapshots(xp, display)
                end
            end
        end

        if displayEnabled(display, 'pageCoin') then
            sectionTitle('Coin', 1.0, 0.86, 0.42)

            local salesCp = tonumber(s.salesCp) or 0
            if displayEnabled(display, 'coinTotal') then
                labelValue('Group Session', formatCopperCompact(tonumber(s.totalCp) or 0), 1.0, 0.95, 0.55)
                if salesCp > 0 then
                    local lootedCp = math.max(0, (tonumber(s.totalCp) or 0) - salesCp)
                    ImGui.SameLine(0, 18)
                    labelValue('Looted', formatCopperCompact(lootedCp), 0.85, 0.95, 0.70)
                    ImGui.SameLine(0, 18)
                    labelValue('Sold', formatCopperCompact(salesCp), 0.85, 0.95, 0.70)
                end
            end

            local startedAt   = tonumber(s.startedAt)   or 0
            local pausedAt    = tonumber(s.pausedAt)    or 0
            local pausedAccum = tonumber(s.pausedAccum) or 0
            local isPaused    = pausedAt > 0
            local xpAaBlockOn = displayEnabled(display, 'pageXP') or displayEnabled(display, 'pageAA')
            local runtimeShownAbove = xpAaBlockOn and displayEnabled(display, 'metaRuntime')
            if displayEnabled(display, 'coinTime') and startedAt > 0 and not runtimeShownAbove then
                local refTime = isPaused and pausedAt or os.time()
                local elapsed = refTime - startedAt - pausedAccum
                if elapsed < 0 then elapsed = 0 end
                labelValue('Session Time', formatElapsed(elapsed) .. (isPaused and ' (PAUSED)' or ''), isPaused and 0.95 or 0.74, isPaused and 0.65 or 0.82, isPaused and 0.30 or 0.92)
            end
            if displayEnabled(display, 'coinEvents') then
                ImGui.SameLine(0, 18)
                labelValue('Events / Lifetime', string.format('%d / %s', tonumber(s.events) or 0, formatCopperCompact(tonumber(l.totalCp) or 0)), 0.90, 0.92, 0.96)
            end
            if displayEnabled(display, 'coinBiggest') and s.biggestCp and tonumber(s.biggestCp) > 0 then
                labelValue('Biggest Loot', string.format('%s by %s', formatCopperCompact(tonumber(s.biggestCp)), tostring(s.biggestWho or '')), 1.0, 0.95, 0.55)
            end
        end

        if displayEnabled(display, 'pageFeed') and displayEnabled(display, 'coinPerChar') and hasPerCharRows(currentSnap) then
            if ImGui.CollapsingHeader('Per-character##gains_full_per_char') then
                renderPerChar()
            end
        end

        if displayEnabled(display, 'pageFeed') and displayEnabled(display, 'coinFeed') and hasRecentRows(currentSnap) then
            if ImGui.CollapsingHeader('Recent Coin Feed##gains_full_recent') then
                renderRecent()
            end
        end

        if displayEnabled(display, 'pageSnapshots') and displayEnabled(display, 'coinSnapshots') and hasMeaningfulMoneySnapshots(currentSnap) then
            if ImGui.CollapsingHeader('Coin Snapshots##gains_full_coin_snaps') then
                renderMoneySnapshots()
            end
        end
    end

    ImGui.Dummy(0, 4)
end

return M
