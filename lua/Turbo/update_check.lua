--[[
  Turbo/update_check.lua
  Throttled remote CHANGELOG compare so the hub can show "update available".
  Soft-fails offline.

  Fetch uses CreateProcess(CREATE_NO_WINDOW) + curl.exe (or powershell) so the
  game thread never blocks on os.execute and no console window flashes.
]]

local mq = require('mq')

local M = {}

local CHANGELOG_URL =
    'https://raw.githubusercontent.com/drel-git/Turbo/main/lua/turbogear/CHANGELOG'
local PATCHER_RELEASES_URL =
    'https://github.com/drel-git/TurboPatcher/releases/latest'
-- When already behind, don't re-hit GitHub often. When up to date, recheck sooner
-- so a new release shows up without waiting most of a day.
local THROTTLE_BEHIND_S = 6 * 60 * 60
local THROTTLE_OK_S = 15 * 60
-- Let Turbo finish loading before the first background fetch.
local STARTUP_DELAY_S = 12
local RESULT_FILE = 'turbo_update_check.txt'
local META_FILE = 'turbo_update_check_meta.lua'
local FETCH_MARKER = 'turbo_update_check.fetching'

local state = {
    localVersion = nil,
    remoteVersion = nil,
    updateAvailable = false,
    lastFetchStarted = 0,
    busy = false,
    readyAt = os.clock() + STARTUP_DELAY_S,
    metaLoaded = false,
    spawnCdefDone = false,
    shell32 = nil,
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
    local found = nil
    for line in f:lines() do
        local v = trim(line)
        if v:match('^%d+%.%d+') then
            found = v
            break
        end
    end
    f:close()
    return found
end

-- Tiny sidecar so we do not rewrite the full turbo_settings_*.lua on every check.
local function write_meta(g)
    if not g then return end
    local path = config_path(META_FILE)
    local f = io.open(path, 'w')
    if not f then return end
    f:write('return {\n')
    f:write(string.format('  updateCheckAt = %d,\n', math.floor(tonumber(g.updateCheckAt) or 0)))
    f:write(string.format('  remoteTurboVersion = %q,\n', tostring(g.remoteTurboVersion or '')))
    f:write(string.format('  updateBannerDismissedVersion = %q,\n',
        tostring(g.updateBannerDismissedVersion or '')))
    f:write('}\n')
    f:close()
end

local function load_meta(g)
    if state.metaLoaded or not g then return end
    state.metaLoaded = true
    local path = config_path(META_FILE)
    local ok, data = pcall(dofile, path)
    if not ok or type(data) ~= 'table' then return end
    if data.updateCheckAt ~= nil then
        g.updateCheckAt = math.floor(tonumber(data.updateCheckAt) or 0)
    end
    if type(data.remoteTurboVersion) == 'string' and data.remoteTurboVersion ~= '' then
        g.remoteTurboVersion = data.remoteTurboVersion
        state.remoteVersion = data.remoteTurboVersion
    end
    if type(data.updateBannerDismissedVersion) == 'string' then
        g.updateBannerDismissedVersion = data.updateBannerDismissedVersion
    end
end

local CREATE_NO_WINDOW = 0x08000000
local DETACHED_PROCESS = 0x00000008
local SW_HIDE = 0
local function bor(a, b)
    if bit32 and bit32.bor then return bit32.bor(a, b) end
    local ok, bit = pcall(require, 'bit')
    if ok and bit and bit.bor then return bit.bor(a, b) end
    return a + b -- flags are distinct bits; safe here
end

local function powershell_exe()
    local root = os.getenv('SystemRoot') or os.getenv('WINDIR') or 'C:\\Windows'
    return root .. '\\System32\\WindowsPowerShell\\v1.0\\powershell.exe'
end

local function curl_exe()
    local root = os.getenv('SystemRoot') or os.getenv('WINDIR') or 'C:\\Windows'
    local p = root .. '\\System32\\curl.exe'
    local f = io.open(p, 'rb')
    if f then f:close(); return p end
    return nil
end

local function spawn_hidden_process(appPath, cmdline)
    local okFfi, ffi = pcall(require, 'ffi')
    if not okFfi or not ffi then return false end
    if not state.spawnCdefDone then
        local okDef = pcall(ffi.cdef, [[
            typedef struct {
                uint32_t cb;
                char* lpReserved;
                char* lpDesktop;
                char* lpTitle;
                uint32_t dwX;
                uint32_t dwY;
                uint32_t dwXSize;
                uint32_t dwYSize;
                uint32_t dwXCountChars;
                uint32_t dwYCountChars;
                uint32_t dwFillAttribute;
                uint32_t dwFlags;
                uint16_t wShowWindow;
                uint16_t cbReserved2;
                uint8_t* lpReserved2;
                void* hStdInput;
                void* hStdOutput;
                void* hStdError;
            } TURBO_UC_STARTUPINFOA;
            typedef struct {
                void* hProcess;
                void* hThread;
                uint32_t dwProcessId;
                uint32_t dwThreadId;
            } TURBO_UC_PROCESS_INFORMATION;
            int CreateProcessA(
                const char* lpApplicationName,
                char* lpCommandLine,
                void* lpProcessAttributes,
                void* lpThreadAttributes,
                int bInheritHandles,
                uint32_t dwCreationFlags,
                void* lpEnvironment,
                const char* lpCurrentDirectory,
                TURBO_UC_STARTUPINFOA* lpStartupInfo,
                TURBO_UC_PROCESS_INFORMATION* lpProcessInformation
            );
            int CloseHandle(void* hObject);
        ]])
        if not okDef then return false end
        state.spawnCdefDone = true
    end
    local si = ffi.new('TURBO_UC_STARTUPINFOA')
    local pi = ffi.new('TURBO_UC_PROCESS_INFORMATION')
    si.cb = ffi.sizeof(si)
    si.dwFlags = 1 -- STARTF_USESHOWWINDOW
    si.wShowWindow = SW_HIDE
    local buf = ffi.new('char[?]', #cmdline + 1)
    ffi.copy(buf, cmdline)
    local flags = bor(CREATE_NO_WINDOW, DETACHED_PROCESS)
    local ok = ffi.C.CreateProcessA(
        appPath, buf, nil, nil, 0, flags, nil, nil, si, pi) ~= 0
    if ok then
        pcall(function() ffi.C.CloseHandle(pi.hThread) end)
        pcall(function() ffi.C.CloseHandle(pi.hProcess) end)
    end
    return ok
end

local function write_ps1(ps1Path, outPath)
    local function sq(s) return tostring(s):gsub("'", "''") end
    local body = table.concat({
        "$ErrorActionPreference = 'Stop'",
        string.format("$uri = '%s'", sq(CHANGELOG_URL)),
        string.format("$out = '%s'", sq(outPath)),
        "try {",
        "  $r = Invoke-WebRequest -UseBasicParsing -Uri $uri -TimeoutSec 20",
        "  Set-Content -LiteralPath $out -Value $r.Content -Encoding ASCII",
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
    local marker = config_path(FETCH_MARKER)
    pcall(function()
        local mf = io.open(marker, 'w')
        if mf then mf:write(tostring(os.time())); mf:close() end
    end)
    -- Prefer curl: small, no console host, returns immediately via CreateProcess.
    local curl = curl_exe()
    if curl then
        local cmdline = string.format(
            '"%s" -fsSL --max-time 20 -o "%s" "%s"',
            curl, outPath, CHANGELOG_URL)
        if spawn_hidden_process(curl, cmdline) then return true end
    end
    -- Fallback: powershell still via CreateProcess (never os.execute).
    local ps1Path = config_path('turbo_update_check.ps1')
    if not write_ps1(ps1Path, outPath) then return false end
    local ps = powershell_exe()
    local cmdline = string.format(
        '"%s" -NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File "%s"',
        ps, ps1Path)
    return spawn_hidden_process(ps, cmdline)
end

local function settings_enabled(g)
    if not g then return true end
    if g.checkForUpdates == false then return false end
    return true
end

local function should_fetch(g)
    if not settings_enabled(g) then return false end
    if state.busy then return false end
    if os.clock() < (state.readyAt or 0) then return false end
    local last = tonumber(g and g.updateCheckAt) or 0
    local throttle = THROTTLE_OK_S
    if g and g.turboUpdateAvailable == true then
        throttle = THROTTLE_BEHIND_S
    elseif state.updateAvailable then
        throttle = THROTTLE_BEHIND_S
    end
    if last > 0 and (os.time() - last) < throttle and state.remoteVersion then
        return false
    end
    if state.lastFetchStarted > 0 and (os.time() - state.lastFetchStarted) < 45 then
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
        -- Tiny meta file only — do not rewrite full turbo_settings (that hitch was huge).
        write_meta(g)
    end
end

--- Clear throttle/cache and fetch immediately (More → Check now).
--- Still respects startup delay unless opts.immediate.
function M.force_check(g, opts)
    opts = opts or {}
    if not settings_enabled(g) then return false end
    if not opts.immediate and os.clock() < (state.readyAt or 0) then
        -- Schedule as soon as startup delay elapses.
        state.readyAt = os.clock()
    end
    state.localVersion = M.read_local_changelog_version()
    state.remoteVersion = nil
    state.updateAvailable = false
    state.lastFetchStarted = 0
    state.busy = false
    if g then
        g.updateCheckAt = 0
        g.updateBannerDismissedVersion = ''
        g.turboUpdateAvailable = false
        g.remoteTurboVersion = ''
        write_meta(g)
    end
    pcall(function() os.remove(config_path(RESULT_FILE)) end)
    pcall(function() os.remove(config_path(FETCH_MARKER)) end)
    state.lastFetchStarted = os.time()
    state.busy = true
    if not spawn_fetch() then
        state.busy = false
        return false
    end
    return true
end

--- Call from the main loop (cheap). Spawns fetch when due; reads result when ready.
function M.tick(g)
    if not settings_enabled(g) then
        state.updateAvailable = false
        if g then g.turboUpdateAvailable = false end
        return
    end
    load_meta(g)
    if not state.localVersion then
        state.localVersion = M.read_local_changelog_version()
    end

    -- Re-apply cached remote on load so the banner can show before a re-fetch.
    if state.remoteVersion and g and g.turboUpdateAvailable == nil then
        apply_remote(g, state.remoteVersion)
    end

    local remote = read_result_file()
    if remote then
        pcall(function() os.remove(config_path(FETCH_MARKER)) end)
        state.busy = false
        if remote ~= state.remoteVersion or g.turboUpdateAvailable == nil then
            apply_remote(g, remote)
        else
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
    write_meta(g)
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

local function banner_child_flags()
    local f = 0
    if not ImGuiWindowFlags then return f end
    if ImGuiWindowFlags.NoScrollbar then
        f = bit32.bor(f, ImGuiWindowFlags.NoScrollbar)
    end
    if ImGuiWindowFlags.NoScrollWithMouse then
        f = bit32.bor(f, ImGuiWindowFlags.NoScrollWithMouse)
    end
    return f
end

local function banner_button(label, variant, width, height)
    local okUi, Ui = pcall(require, 'Turbo.ui.components')
    if okUi and Ui and Ui.buttonVariant then
        return Ui.buttonVariant(label, variant, width, height)
    end
    return ImGui.Button(label, width or 0, height or 0)
end

--- Draw a compact update banner. Returns true if drawn.
--- Uses ASCII-only copy (MQ fonts often lack Unicode arrows).
function M.draw_banner(g, opts)
    opts = opts or {}
    if not g or g.turboUpdateAvailable ~= true then return false end
    local localV = state.localVersion or M.read_local_changelog_version() or '?'
    local remoteV = state.remoteVersion or g.remoteTurboVersion or '?'
    local frameH = (ImGui.GetFrameHeight and ImGui.GetFrameHeight()) or 22
    local barH = math.max(36, frameH + 14)

    ImGui.Dummy(0, 2)
    ImGui.PushStyleColor(ImGuiCol.ChildBg, 0.14, 0.11, 0.05, 0.96)
    ImGui.PushStyleColor(ImGuiCol.Border, 0.90, 0.68, 0.22, 0.95)
    ImGui.PushStyleVar(ImGuiStyleVar.WindowPadding, 10, 6)
    if ImGui.BeginChild('##turbo_update_banner', 0, barH, true, banner_child_flags()) then
        pcall(function()
            if ImGui.AlignTextToFramePadding then ImGui.AlignTextToFramePadding() end
        end)
        ImGui.TextColored(1.0, 0.84, 0.36, 1.0, 'Turbo update')
        ImGui.SameLine(0, 10)
        ImGui.TextColored(0.78, 0.72, 0.58, 1.0, string.format('v%s  ->  v%s', localV, remoteV))
        ImGui.SameLine(0, 14)
        if banner_button('Update Now##turbo_update_go', 'amberButton', 96, frameH) then
            if type(opts.onUpdate) == 'function' then opts.onUpdate() end
        end
        if ImGui.IsItemHovered() and ImGui.SetTooltip then
            ImGui.SetTooltip('Open TurboPatcher and apply this suite update.')
        end
        ImGui.SameLine(0, 6)
        if banner_button('Later##turbo_update_dismiss', 'secondaryButton', 56, frameH) then
            M.dismiss(g)
            if type(opts.onDismiss) == 'function' then opts.onDismiss() end
        end
        if ImGui.IsItemHovered() and ImGui.SetTooltip then
            ImGui.SetTooltip('Hide until the next Turbo version.')
        end
    end
    ImGui.EndChild()
    ImGui.PopStyleVar(1)
    ImGui.PopStyleColor(2)
    ImGui.Dummy(0, 4)
    return true
end

M.PATCHER_RELEASES_URL = PATCHER_RELEASES_URL
M.CHANGELOG_URL = CHANGELOG_URL

return M
