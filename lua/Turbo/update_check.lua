--[[
  Turbo/update_check.lua
  Throttled remote CHANGELOG compare so the hub can show "update available".
  Soft-fails offline. Fetch is async via PowerShell → config/turbo_update_check.txt.
]]

local mq = require('mq')

local M = {}

local CHANGELOG_URL =
    'https://raw.githubusercontent.com/drel-git/Turbo/main/lua/turbogear/CHANGELOG'
local PATCHER_RELEASES_URL =
    'https://github.com/drel-git/TurboPatcher/releases/latest'
local THROTTLE_S = 6 * 60 * 60
local RESULT_FILE = 'turbo_update_check.txt'
local FETCH_MARKER = 'turbo_update_check.fetching'

local state = {
    localVersion = nil,
    remoteVersion = nil,
    updateAvailable = false,
    lastFetchStarted = 0,
    busy = false,
}

local function trim(s)
    return tostring(s or ''):match('^%s*(.-)%s*$') or ''
end

local function config_path(name)
    local dir = tostring(mq.configDir or 'config'):gsub('[\\/]+$', '')
    return dir .. '\\' .. name
end

local function parse_version(text)
    text = trim(text)
    local a, b, c = text:match('^(%d+)%.(%d+)%.(%d+)')
    if not a then
        a, b = text:match('^(%d+)%.(%d+)')
        c = '0'
    end
    if not a then return nil end
    return {
        major = tonumber(a) or 0,
        minor = tonumber(b) or 0,
        patch = tonumber(c) or 0,
        raw = text,
    }
end

local function version_newer(remote, localv)
    if not remote or not localv then return false end
    if remote.major ~= localv.major then return remote.major > localv.major end
    if remote.minor ~= localv.minor then return remote.minor > localv.minor end
    return remote.patch > localv.patch
end

function M.read_local_changelog_version()
    local luaDir = tostring(mq.luaDir or 'lua'):gsub('[\\/]+$', '')
    local path = luaDir .. '\\turbogear\\CHANGELOG'
    local f = io.open(path, 'r')
    if not f then return '' end
    for line in f:lines() do
        local v = trim(line)
        if v:match('^%d+%.%d+') then
            f:close()
            return v
        end
    end
    f:close()
    return ''
end

local function read_result_file()
    local f = io.open(config_path(RESULT_FILE), 'r')
    if not f then return nil end
    local line = trim(f:read('*l') or '')
    f:close()
    if line == '' or not line:match('^%d+%.%d+') then return nil end
    return line
end

local function write_ps1(ps1Path, outPath)
    local url = CHANGELOG_URL
    -- Escape for PowerShell single-quoted strings (double single-quotes).
    local function sq(s) return tostring(s):gsub("'", "''") end
    local body = table.concat({
        "$ErrorActionPreference = 'Stop'",
        string.format("$uri = '%s'", sq(url)),
        string.format("$out = '%s'", sq(outPath)),
        "try {",
        "  $r = Invoke-WebRequest -UseBasicParsing -Uri $uri -TimeoutSec 25",
        "  $line = ($r.Content -split \"`r?`n\" | Where-Object { $_ -match '^\\d+\\.\\d+' } | Select-Object -First 1)",
        "  if ($line) { Set-Content -LiteralPath $out -Value $line.Trim() -Encoding ASCII }",
        "} catch { }",
    }, '\r\n')
    local f = io.open(ps1Path, 'w')
    if not f then return false end
    f:write(body)
    f:close()
    return true
end

local function spawn_fetch()
    local outPath = config_path(RESULT_FILE)
    local ps1Path = config_path('turbo_update_check.ps1')
    local marker = config_path(FETCH_MARKER)
    if not write_ps1(ps1Path, outPath) then return false end
    pcall(function()
        local mf = io.open(marker, 'w')
        if mf then mf:write(tostring(os.time())); mf:close() end
    end)
    -- Detached so the ImGui/game loop never blocks on the network.
    local cmd = string.format(
        'start "" /B powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%s"',
        ps1Path)
    local ok = pcall(os.execute, cmd)
    return ok == true
end

local function settings_enabled(g)
    if not g then return true end
    if g.checkForUpdates == false then return false end
    return true
end

local function should_fetch(g)
    if not settings_enabled(g) then return false end
    if state.busy then return false end
    local last = tonumber(g and g.updateCheckAt) or 0
    if last > 0 and (os.time() - last) < THROTTLE_S and state.remoteVersion then
        return false
    end
    -- Also throttle spawn attempts even before a result arrives.
    if state.lastFetchStarted > 0 and (os.time() - state.lastFetchStarted) < 60 then
        return false
    end
    return true
end

local function apply_remote(g, remoteRaw)
    local localRaw = state.localVersion
    if not localRaw or localRaw == '' then
        localRaw = M.read_local_changelog_version()
        state.localVersion = localRaw
    end
    state.remoteVersion = remoteRaw
    local rv, lv = parse_version(remoteRaw), parse_version(localRaw)
    state.updateAvailable = version_newer(rv, lv)
    if g then
        g.updateCheckAt = os.time()
        g.remoteTurboVersion = remoteRaw
        g.turboUpdateAvailable = state.updateAvailable
        if state.updateAvailable
            and tostring(g.updateBannerDismissedVersion or '') == tostring(remoteRaw) then
            g.turboUpdateAvailable = false
        end
        g._updateCheckDirty = true
    end
end

--- Call from the main loop (cheap). Spawns fetch when due; reads result when ready.
function M.tick(g)
    if not settings_enabled(g) then
        state.updateAvailable = false
        if g then g.turboUpdateAvailable = false end
        return
    end
    if not state.localVersion then
        state.localVersion = M.read_local_changelog_version()
    end

    local remote = read_result_file()
    if remote then
        local marker = config_path(FETCH_MARKER)
        pcall(function() os.remove(marker) end)
        state.busy = false
        if remote ~= state.remoteVersion or g.turboUpdateAvailable == nil then
            apply_remote(g, remote)
        else
            -- Re-apply dismiss state
            if g and state.updateAvailable
                and tostring(g.updateBannerDismissedVersion or '') == tostring(remote) then
                g.turboUpdateAvailable = false
            elseif g and state.updateAvailable then
                g.turboUpdateAvailable = true
            end
        end
    end

    if should_fetch(g) then
        state.lastFetchStarted = os.time()
        state.busy = true
        if not spawn_fetch() then
            state.busy = false
        end
    end
end

function M.dismiss(g)
    if not g then return end
    local remote = state.remoteVersion or g.remoteTurboVersion
    if remote and remote ~= '' then
        g.updateBannerDismissedVersion = remote
    end
    g.turboUpdateAvailable = false
end

function M.status(g)
    return {
        enabled = settings_enabled(g),
        localVersion = state.localVersion or M.read_local_changelog_version(),
        remoteVersion = state.remoteVersion or (g and g.remoteTurboVersion) or '',
        updateAvailable = g and g.turboUpdateAvailable == true,
        patcherReleasesUrl = PATCHER_RELEASES_URL,
    }
end

--- Draw a compact update banner. Returns true if drawn.
function M.draw_banner(g, opts)
    opts = opts or {}
    if not g or g.turboUpdateAvailable ~= true then return false end
    local localV = state.localVersion or M.read_local_changelog_version() or '?'
    local remoteV = state.remoteVersion or g.remoteTurboVersion or '?'
    local msg = string.format('Turbo update available: v%s → v%s', localV, remoteV)

    ImGui.PushStyleColor(ImGuiCol.ChildBg, 0.16, 0.12, 0.04, 0.95)
    ImGui.PushStyleColor(ImGuiCol.Border, 0.83, 0.60, 0.16, 1.0)
    if ImGui.BeginChild('##turbo_update_banner', 0, opts.height or 32, true) then
        pcall(function()
            if ImGui.AlignTextToFramePadding then ImGui.AlignTextToFramePadding() end
        end)
        ImGui.TextColored(1.0, 0.76, 0.29, 1.0, msg)
        ImGui.SameLine()
        if ImGui.SmallButton('Update##turbo_update_go') then
            if type(opts.onUpdate) == 'function' then opts.onUpdate() end
        end
        if ImGui.IsItemHovered() and ImGui.SetTooltip then
            ImGui.SetTooltip('Launch TurboPatcher to install the update.')
        end
        ImGui.SameLine()
        if ImGui.SmallButton('x##turbo_update_dismiss') then
            M.dismiss(g)
            if type(opts.onDismiss) == 'function' then opts.onDismiss() end
        end
        if ImGui.IsItemHovered() and ImGui.SetTooltip then
            ImGui.SetTooltip('Dismiss until the next Turbo version.')
        end
    end
    ImGui.EndChild()
    ImGui.PopStyleColor(2)
    ImGui.Dummy(0, 4)
    return true
end

M.PATCHER_RELEASES_URL = PATCHER_RELEASES_URL
M.CHANGELOG_URL = CHANGELOG_URL

return M
