--[[
  Turbo Timed Challenge
  ---------------------
  Lean ImGui widget for MacroQuest Lua / E3Next overlays.

  Drop-in use:
    local Challenge = require('Turbo.timed_challenge')
    Challenge.renderSetup({
      getStats = function()
        return {
          aa = 12,              -- AA points, or AA percent if that is all you have
          xp = 34.5,            -- XP percent gained/session value
          plat = 120000,        -- copper is preferred; see platIsCopper below
          platIsCopper = true,
          zone = 'Befallen',
        }
      end,
      snapshot = function() mq.cmd('/turbogains snapshot') end,
      showFull = function() ... end,
    })
    Challenge.renderMini(provider)

  If your exact MQ TLO calls differ, change only provider.getStats().
]]

local mq = require('mq')
local ImGui = require('ImGui')
local Ui = require('Turbo.ui.components')
local Paths = require('Turbo.paths')

local M = {}

local CP_PER_PP = 1000
local legacySettingsPath = string.format('%s/Turbo/timed_challenge_settings.lua', mq.configDir or '.')

local function settingsPath()
    return Paths.state_file('timed_challenge_settings.lua') or legacySettingsPath
end

local S = {
    durationMin = 30,
    track = { aa = true, xp = false, plat = true },
    running = false,
    paused = false,
    done = false,
    startAt = 0,
    durationSec = 1800,
    pauseAt = 0,
    pausedAccum = 0,
    base = { aa = 0, xp = 0, plat = 0 },
    final = nil,
    status = '',
}

local function bool(v) return v == true end

local function safeNow()
    return os.time()
end

local function ensureDir()
    -- Avoid os.execute here: on some Windows/MQ setups it flashes a console
    -- when the user changes challenge toggles. The Turbo config folder should
    -- already exist; if it does not, saveSettings simply becomes a no-op.
end

local function saveSettings()
    ensureDir()
    local f = io.open(settingsPath(), 'w')
    if not f then return end
    f:write('return {\n')
    f:write(string.format('  durationMin = %d,\n', tonumber(S.durationMin) or 30))
    f:write(string.format('  trackAA = %s,\n', tostring(S.track.aa == true)))
    f:write(string.format('  trackXP = %s,\n', tostring(S.track.xp == true)))
    f:write(string.format('  trackPlat = %s,\n', tostring(S.track.plat == true)))
    f:write('}\n')
    f:close()
end

local function loadSettings()
    local path = settingsPath()
    local ok, data = pcall(dofile, path)
    if (not ok or type(data) ~= 'table') and path ~= legacySettingsPath then
        ok, data = pcall(dofile, legacySettingsPath)
    end
    if not ok or type(data) ~= 'table' then return end
    S.durationMin = tonumber(data.durationMin) or S.durationMin
    S.track.aa = data.trackAA == true
    S.track.xp = data.trackXP == true
    S.track.plat = data.trackPlat == true
    if not (S.track.aa or S.track.xp or S.track.plat) then S.track.aa = true end
end

loadSettings()

function M.formatTime(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    if h > 0 then return string.format('%d:%02d:%02d', h, m, s) end
    return string.format('%d:%02d', m, s)
end

local function fmtPct(v)
    local n = tonumber(v) or 0
    local s = string.format('%.1f', n):gsub('%.0$', '')
    return s .. '%'
end

local function fmtCoinCompact(cp)
    cp = math.floor(math.abs(tonumber(cp) or 0) + 0.5)
    if cp == 0 then return '0cp' end
    local pp = math.floor(cp / CP_PER_PP); cp = cp - pp * CP_PER_PP
    local gp = math.floor(cp / 100); cp = cp - gp * 100
    local sp = math.floor(cp / 10); cp = cp - sp * 10
    local parts = {}
    if pp > 0 then parts[#parts + 1] = string.format('%dpp', pp) end
    if gp > 0 then parts[#parts + 1] = string.format('%dgp', gp) end
    if sp > 0 then parts[#parts + 1] = string.format('%dsp', sp) end
    if cp > 0 then parts[#parts + 1] = string.format('%dcp', cp) end
    return table.concat(parts, ' ')
end

local function fmtCoinDelta(cp)
    cp = tonumber(cp) or 0
    if cp < 0 then return '-' .. fmtCoinCompact(cp) end
    return '+' .. fmtCoinCompact(cp)
end

function M.elapsed(now)
    now = now or safeNow()
    local endNow = S.paused and S.pauseAt or now
    return math.max(0, endNow - (S.startAt or endNow) - (S.pausedAccum or 0))
end

function M.progress(now)
    if S.done then return 1 end
    local dur = math.max(1, tonumber(S.durationSec) or 1)
    return math.max(0, math.min(1, M.elapsed(now) / dur))
end

local function selectedCount()
    local n = 0
    if S.track.aa then n = n + 1 end
    if S.track.xp then n = n + 1 end
    if S.track.plat then n = n + 1 end
    return n
end

local function normalizeStats(raw)
    raw = type(raw) == 'table' and raw or {}
    local plat = tonumber(raw.plat) or 0
    -- TurboGains passes coin as copper. Keep copper as the default so callers
    -- that omit platIsCopper cannot accidentally inflate 2681cp into 2681pp.
    if raw.platIsCopper == false or raw.platIsPlat == true then plat = plat * CP_PER_PP end
    return {
        aa = tonumber(raw.aa) or 0,
        aaIsPercent = raw.aaIsPercent == true,
        xp = tonumber(raw.xp) or 0,
        plat = plat,
        zone = tostring(raw.zone or ''),
    }
end

function M.gains(current)
    current = normalizeStats(current)
    local base = S.base or {}
    local g = {
        aa = current.aa - (tonumber(base.aa) or 0),
        aaIsPercent = current.aaIsPercent == true or base.aaIsPercent == true,
        xp = current.xp - (tonumber(base.xp) or 0),
        plat = current.plat - (tonumber(base.plat) or 0),
        zone = current.zone,
    }
    return g
end

function M.rates(gains, elapsed)
    elapsed = math.max(1, tonumber(elapsed) or 1)
    return {
        aa = ((tonumber(gains.aa) or 0) / elapsed) * 3600,
        xp = ((tonumber(gains.xp) or 0) / elapsed) * 3600,
        plat = ((tonumber(gains.plat) or 0) / elapsed) * 3600,
    }
end

local function statText(key, value)
    if key == 'aa' then
        local n = tonumber(value) or 0
        if math.abs(n) < 0.05 then n = 0 end
        local s = string.format('%+.1f', n):gsub('%.0$', '')
        return 'AA ' .. s
    end
    if key == 'xp' then return 'XP +' .. fmtPct(value) end
    return fmtCoinDelta(value)
end

function M.formatSelectedStatDisplay(gains)
    local parts = {}
    if S.track.aa then
        parts[#parts + 1] = gains.aaIsPercent and ('AA +' .. fmtPct(gains.aa)) or statText('aa', gains.aa)
    end
    if S.track.xp then parts[#parts + 1] = statText('xp', gains.xp) end
    if S.track.plat then parts[#parts + 1] = statText('plat', gains.plat) end
    return parts
end

local function toggleButton(label, on, w)
    if Ui.buttonVariant(label, on and 'successButton' or 'secondaryButton', w or 52, 24) then
        return not on
    end
    return on
end

function M.start(provider)
    provider = provider or {}
    if selectedCount() <= 0 then
        S.status = 'Pick a stat.'
        return false
    end
    local stats = normalizeStats(provider.getStats and provider.getStats() or {})
    S.base = { aa = stats.aa, aaIsPercent = stats.aaIsPercent, xp = stats.xp, plat = stats.plat }
    S.durationSec = math.max(60, (tonumber(S.durationMin) or 30) * 60)
    S.startAt = safeNow()
    S.pausedAccum = 0
    S.pauseAt = 0
    S.running = true
    S.paused = false
    S.done = false
    S.final = nil
    S.status = ''
    saveSettings()
    return true
end

local function complete(provider)
    local stats = normalizeStats(provider and provider.getStats and provider.getStats() or {})
    S.final = M.gains(stats)
    S.running = false
    S.paused = false
    S.done = true
    if provider and provider.snapshot then provider.snapshot() end
end

local function pause()
    if S.running and not S.paused then
        S.paused = true
        S.pauseAt = safeNow()
    end
end

local function resume()
    if S.running and S.paused then
        S.pausedAccum = (S.pausedAccum or 0) + (safeNow() - (S.pauseAt or safeNow()))
        S.pauseAt = 0
        S.paused = false
    end
end

local function stop()
    S.running = false
    S.paused = false
    S.done = false
end

function M.isActive()
    return S.running == true or S.done == true
end

function M.drawSetupSelector(provider)
    ImGui.TextColored(0.58, 0.63, 0.72, 1.0, 'Track')
    local allOn = S.track.aa and S.track.xp and S.track.plat
    if Ui.buttonVariant('All##tc_all', allOn and 'successButton' or 'secondaryButton', 42, 24) then
        local next = not allOn
        S.track.aa, S.track.xp, S.track.plat = next, next, next
        saveSettings()
    end
    ImGui.SameLine(0, 4); S.track.aa = toggleButton('AA##tc_aa', S.track.aa, 42)
    ImGui.SameLine(0, 4); S.track.xp = toggleButton('XP##tc_xp', S.track.xp, 42)
    ImGui.SameLine(0, 4); S.track.plat = toggleButton('Plat##tc_plat', S.track.plat, 54)
    if not (S.track.aa or S.track.xp or S.track.plat) then
        ImGui.SameLine(0, 8)
        ImGui.TextColored(0.95, 0.55, 0.38, 1.0, 'Pick one')
    end
    ImGui.Dummy(0, 4)
    ImGui.TextColored(0.62, 0.70, 0.86, 1.0, 'Time')
    for i, m in ipairs({ 15, 30, 60, 90 }) do
        if i > 1 then ImGui.SameLine(0, 4) end
        if Ui.buttonVariant(tostring(m) .. 'm##tc_dur_' .. tostring(m),
            S.durationMin == m and 'primaryButton' or 'secondaryButton', 48, 24) then
            S.durationMin = m
            saveSettings()
        end
    end
    ImGui.Dummy(0, 5)
    local avail = ImGui.GetContentRegionAvail()
    local startW = 92
    if avail > startW then
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + math.floor((avail - startW) * 0.5))
    end
    if Ui.buttonVariant('Start##tc_start', 'infoButton', startW, 24) then M.start(provider) end
    if S.status ~= '' then
        ImGui.SameLine(0, 8)
        ImGui.TextColored(0.95, 0.62, 0.40, 1.0, S.status)
    end
end

local function drawProgress(frac, width)
    local w = math.max(120, math.min(300, tonumber(width) or 160))
    ImGui.ProgressBar(math.max(0, math.min(1, frac or 0)), w, 10, '')
end

local function statColor(key)
    if key == 'aa' then return { 0.76, 0.60, 0.95, 1.00 } end
    if key == 'xp' then return { 0.62, 1.00, 0.62, 1.00 } end
    if key == 'plat' then return { 1.00, 0.95, 0.55, 1.00 } end
    return { 0.86, 0.92, 1.00, 1.00 }
end

local function selectedStatParts(gains)
    local parts = {}
    if S.track.aa then
        local aaText = gains.aaIsPercent
            and ('AA +' .. fmtPct(gains.aa))
            or statText('aa', gains.aa)
        parts[#parts + 1] = { text = aaText, color = statColor('aa') }
    end
    if S.track.xp then parts[#parts + 1] = { text = statText('xp', gains.xp), color = statColor('xp') } end
    if S.track.plat then parts[#parts + 1] = { text = statText('plat', gains.plat), color = statColor('plat') } end
    return parts
end

local function textWidth(text)
    text = tostring(text or '')
    if ImGui.CalcTextSize then
        local ok, x = pcall(ImGui.CalcTextSize, text)
        if ok and tonumber(x) then return tonumber(x) end
    end
    local fontSize = tonumber(ImGui.GetFontSize()) or 13
    return #text * fontSize * 0.54
end

local function approxSegmentsWidth(parts)
    local w = 0
    for _, part in ipairs(parts or {}) do w = w + textWidth(part.text) end
    return w + math.max(0, #(parts or {}) - 1) * 10
end

local function drawColoredSegments(parts)
    for i, part in ipairs(parts or {}) do
        if i > 1 then ImGui.SameLine(0, 10) end
        local c = part.color or statColor()
        ImGui.TextColored(c[1], c[2], c[3], c[4], tostring(part.text or ''))
    end
end

local function drawWrappedSegments(parts, width)
    local availX = math.max(80, tonumber(width) or tonumber(ImGui.GetContentRegionAvail()) or 120)
    local lineW = 0
    for i, part in ipairs(parts or {}) do
        local text = tostring(part.text or '')
        local segW = textWidth(text)
        local gap = 10
        if i > 1 and lineW > 0 and (lineW + gap + segW) <= availX then
            ImGui.SameLine(0, gap)
            lineW = lineW + gap
        elseif i > 1 then
            lineW = 0
        end
        local c = part.color or statColor()
        ImGui.TextColored(c[1], c[2], c[3], c[4], text)
        lineW = lineW + segW
    end
end

local function drawCenteredSegments(parts, width)
    local availX = tonumber(width) or tonumber(ImGui.GetContentRegionAvail()) or 0
    local textW = approxSegmentsWidth(parts)
    local startX = ImGui.GetCursorPosX()
    if availX > textW then ImGui.SetCursorPosX(startX + math.floor((availX - textW) * 0.5)) end
    drawColoredSegments(parts)
end

local function drawCenteredText(text, color, width)
    local availX = tonumber(width) or tonumber(ImGui.GetContentRegionAvail()) or 0
    local textW = textWidth(text)
    local startX = ImGui.GetCursorPosX()
    if availX > textW then ImGui.SetCursorPosX(startX + math.floor((availX - textW) * 0.5)) end
    color = color or statColor()
    ImGui.TextColored(color[1], color[2], color[3], color[4], tostring(text or ''))
end

local function drawMiniText(parts, left, width)
    if S.done then
        drawCenteredText('Done', { 1.00, 0.84, 0.36, 1.00 }, width)
        drawWrappedSegments(parts, width)
        return
    end
    drawCenteredSegments(parts, width)
    drawCenteredText(M.formatTime(left), { 1.00, 0.84, 0.36, 1.00 }, width)
end

function M.drawHoverTooltip(gains, rates, provider)
    if not ImGui.IsItemHovered() then return end
    ImGui.BeginTooltip()
    ImGui.Text('Run: ' .. M.formatTime(M.elapsed()))
    if S.track.aa then
        ImGui.Text(gains.aaIsPercent
            and string.format('AA Rate: %.1f%%/hr', rates.aa or 0)
            or string.format('AA Rate: %.1f AA/hr', rates.aa or 0))
    end
    if S.track.xp then ImGui.Text(string.format('XP Rate: %.1f%%/hr', rates.xp or 0)) end
    if S.track.plat then ImGui.Text('Coin Rate: ' .. fmtCoinCompact(rates.plat or 0) .. '/hr') end
    local zone = tostring(gains.zone or '')
    if zone == '' and provider and provider.getZone then zone = tostring(provider.getZone() or '') end
    if zone ~= '' then ImGui.Text('Zone: ' .. zone) end
    ImGui.Text('Challenge: ' .. tostring(S.durationMin) .. 'm')
    ImGui.EndTooltip()
end

function M.drawContextMenu(provider)
    if ImGui.BeginPopupContextWindow('##tc_context') then
        if S.done then
            if ImGui.Selectable('Again') then M.start(provider) end
            if ImGui.Selectable('Snapshot') and provider and provider.snapshot then provider.snapshot() end
            if ImGui.Selectable('Close') then S.done = false end
            if ImGui.Selectable('Show Full Gains') and provider and provider.showFull then provider.showFull() end
        else
            if ImGui.Selectable(S.paused and 'Resume' or 'Pause') then if S.paused then resume() else pause() end end
            if ImGui.Selectable('Snapshot') and provider and provider.snapshot then provider.snapshot() end
            if ImGui.Selectable('Stop/Close') then stop() end
            if ImGui.Selectable('Show Full Gains') and provider and provider.showFull then provider.showFull() end
        end
        ImGui.EndPopup()
    end
end

function M.drawMiniTimer(provider)
    provider = provider or {}
    if not (S.running or S.done) then return end
    if S.running and not S.paused and M.elapsed() >= (S.durationSec or 1) then complete(provider) end

    local stats = normalizeStats(provider.getStats and provider.getStats() or {})
    local gains = S.done and (S.final or M.gains(stats)) or M.gains(stats)
    local rates = M.rates(gains, M.elapsed())
    local parts = selectedStatParts(gains)
    local left = math.max(0, (S.durationSec or 0) - M.elapsed())
    local title = 'Turbo Challenge###Turbo_Timed_Challenge_Mini'
    local contentW = math.max(140, math.min(320, math.floor(approxSegmentsWidth(parts) + 10)))

    ImGui.SetNextWindowPos(120, 120, ImGuiCond.FirstUseEver)
    ImGui.SetNextWindowSize(contentW + 16, 0, ImGuiCond.Always)
    local flags = bit32.bor(
        ImGuiWindowFlags.AlwaysAutoResize,
        ImGuiWindowFlags.NoScrollbar,
        ImGuiWindowFlags.NoTitleBar,
        ImGuiWindowFlags.NoCollapse,
        ImGuiWindowFlags.NoFocusOnAppearing
    )
    ImGui.PushStyleVar(ImGuiStyleVar.WindowPadding, 8, 6)
    ImGui.PushStyleVar(ImGuiStyleVar.WindowRounding, 7)
    ImGui.PushStyleVar(ImGuiStyleVar.WindowBorderSize, 2)
    ImGui.PushStyleVar(ImGuiStyleVar.FramePadding, 2, 1)
    ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 3)
    ImGui.PushStyleColor(ImGuiCol.WindowBg, 0.035, 0.045, 0.070, 0.92)
    ImGui.PushStyleColor(ImGuiCol.Border, 1.00, 0.68, 0.18, 0.95)
    ImGui.PushStyleColor(ImGuiCol.FrameBg, 0.11, 0.13, 0.18, 0.92)
    ImGui.PushStyleColor(ImGuiCol.PlotHistogram, 1.00, 0.73, 0.16, 1.00)
    local open, draw = ImGui.Begin(title, true, flags)
    if draw == nil then draw = open end
    if draw then
        drawMiniText(parts, left, contentW)
        drawProgress(S.done and 1 or M.progress(), contentW)
        M.drawHoverTooltip(gains, rates, provider)
        M.drawContextMenu(provider)
    end
    ImGui.End()
    ImGui.PopStyleColor(4)
    ImGui.PopStyleVar(5)
end

function M.renderSetup(provider)
    if not S.running and not S.done then M.drawSetupSelector(provider) end
end

function M.renderMini(provider)
    M.drawMiniTimer(provider)
end

return M
