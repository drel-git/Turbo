--[[
   TurboGains toggle (melee-distance style entry point)
   -----------------------------------------------------
   - /e3varset group mirror like ToggleMeleeDist / Turbo setRouteVar
   - start: TurboGainsOn + TurboGainsQuiet (no EQBC spam), then /lua run Turbo/gains
     Those two are /e3varset session vars only — not saved to INI by this script.
   - stop: vars off, /lua stop Turbo/loot_announce, /turbogains stop
   - autostart on|off|toggle: [Startup Commands] TurboGains_AutoRun in e3 Bot INI

   Driver / UI (typical):
     /e3bcaa /lua run Turbo/gains_toggle start
     /e3bcaa /lua run Turbo/gains_toggle stop

   @version lua/Turbo/gains_toggle.lua 1.0.0
]]

local mq = require('mq')

local STARTUP_SECTION = 'Startup Commands'
local KEY_AUTORUN = 'TurboGains_AutoRun'
--- Delay (MQ /timed deciseconds) so E3 finishes boot before gains_toggle start runs.
local AUTORUN_TIMED_DS = 100
local LEGACY_AUTORUN = 'Turbo_AutoGains'

local function file_exists(path)
    local fh = io.open(path, 'r')
    if fh then fh:close(); return true end
    return false
end

--- Match ToggleMeleeDist / Turbo e3 Bot Ini probing.
local function resolve_e3_bot_ini_path()
    local mqPath = mq.TLO.MacroQuest.Path() or ''
    local charName = mq.TLO.Me.CleanName() or mq.TLO.Me.Name() or ''
    local serverRaw = mq.TLO.EverQuest.Server() or ''
    local bases = {}
    if mqPath ~= '' then
        bases[#bases + 1] = mqPath .. '\\Config\\e3 Bot Inis'
        bases[#bases + 1] = mqPath .. '\\Macros\\e3 Bot Inis'
    end

    local serverStripped = serverRaw:gsub('^Project ', '')
    local serverUnder = serverRaw:gsub(' ', '_')
    local variants = {}
    if serverRaw ~= '' then variants[#variants + 1] = charName .. '_' .. serverRaw end
    if serverStripped ~= serverRaw then variants[#variants + 1] = charName .. '_' .. serverStripped end
    if serverUnder ~= serverRaw then variants[#variants + 1] = charName .. '_' .. serverUnder end
    variants[#variants + 1] = charName .. '_Lazarus'
    variants[#variants + 1] = charName

    for _, base in ipairs(bases) do
        for _, v in ipairs(variants) do
            local p = base .. '\\' .. v .. '.ini'
            if file_exists(p) then return p end
        end
    end

    if #bases > 0 and #variants > 0 then
        return bases[1] .. '\\' .. variants[1] .. '.ini'
    end
    return nil
end

local function strip_section_name(s)
    return (s or ''):gsub('%s+$', '')
end

--- Mirror current [Startup Commands] TurboGains_AutoRun (and strip legacy Turbo_AutoGains).
local function merge_autostart_startup(lines, wantAutostart)
    local autorunVal = string.format(
        '/timed %d /lua run Turbo/gains_toggle start', AUTORUN_TIMED_DS)
    local lNew = KEY_AUTORUN .. '=' .. autorunVal
    local patNew = '^' .. KEY_AUTORUN .. '='
    local patLegacy = '^' .. LEGACY_AUTORUN .. '='

    local h
    for i, line in ipairs(lines) do
        local bracket = line:match('^%[(.-)%]$')
        if bracket and strip_section_name(bracket) == STARTUP_SECTION then
            h = i
            break
        end
    end

    local function strip_gains_keys(slice)
        local out = {}
        for _, ln in ipairs(slice) do
            if not (ln:match(patNew) or ln:match(patLegacy)) then
                out[#out + 1] = ln
            end
        end
        return out
    end

    if not h then
        if not wantAutostart then return false end
        lines[#lines + 1] = ''
        lines[#lines + 1] = '[' .. STARTUP_SECTION .. ']'
        lines[#lines + 1] = lNew
        return true
    end

    local tail = {}
    local j = h + 1
    while j <= #lines and not lines[j]:match('^%[.-%]$') do
        tail[#tail + 1] = lines[j]
        j = j + 1
    end
    tail = strip_gains_keys(tail)

    if wantAutostart then
        tail[#tail + 1] = lNew
    elseif #tail == 0 then
        -- nothing
    end

    local rebuilt = {}
    for i = 1, h - 1 do
        rebuilt[#rebuilt + 1] = lines[i]
    end
    rebuilt[#rebuilt + 1] = lines[h]
    for _, ln in ipairs(tail) do
        rebuilt[#rebuilt + 1] = ln
    end
    while j <= #lines do
        rebuilt[#rebuilt + 1] = lines[j]
        j = j + 1
    end

    local dirty = (#rebuilt ~= #lines)
    if not dirty then
        for i = 1, #lines do
            if rebuilt[i] ~= lines[i] then dirty = true; break end
        end
    end
    if dirty then
        for i = 1, #rebuilt do lines[i] = rebuilt[i] end
        for i = #rebuilt + 1, #lines do lines[i] = nil end
    end
    return dirty
end

local function flush_ini(path, lines)
    local out = io.open(path, 'w')
    if not out then return false end
    for _, line in ipairs(lines) do
        out:write(line, '\n')
    end
    out:close()
    return true
end

--- true if TurboGains_AutoRun= line exists (legacy Turbo_AutoGains counts as on for migration UI).
local function read_autostart_enabled(path)
    local rf = io.open(path, 'r')
    if not rf then return false end
    local inStartup = false
    for line in rf:lines() do
        local sec = line:match('^%[(.-)%]%s*$')
        if sec then
            inStartup = (strip_section_name(sec) == STARTUP_SECTION)
        elseif inStartup then
            if line:match('^' .. KEY_AUTORUN .. '=') then rf:close(); return true end
            if line:match('^' .. LEGACY_AUTORUN .. '=') then rf:close(); return true end
        end
    end
    rf:close()
    return false
end

local function routeVar(key, value)
    mq.cmdf('/e3varset %s %s', key, value)
    mq.cmdf('/e3bcga /e3varset %s %s', key, value)
end

local function queryE3(key)
    if not (mq.TLO.MQ2Mono and mq.TLO.MQ2Mono.Query) then return nil end
    local ok, v = pcall(function() return mq.TLO.MQ2Mono.Query('e3,' .. key)() end)
    if ok then return v end
    return nil
end

local function e3Truthy(v)
    local s = tostring(v or ''):lower()
    return s == 'true' or s == '1' or s == 'on' or s == 'yes'
end

--- MQ/EQ chat lines truncate long paths; print in chunks with backslash-aware breaks.
local function printf_bot_ini_path(path)
    local tag = '\at[TurboGainsToggle]\ax '
    path = tostring(path or '')
    if path == '' then return end
    local width = 68
    if #path <= width then
        printf('%se3 Bot INI: %s', tag, path)
        return
    end
    printf('%se3 Bot INI (%d chars, split for chat):', tag, #path)
    local i = 1
    local n = #path
    while i <= n do
        local j = math.min(i + width - 1, n)
        if j < n then
            local slice = path:sub(i, j)
            local cut = nil
            for k = #slice, 1, -1 do
                if slice:sub(k, k) == '\\' then
                    cut = i + k - 1
                    break
                end
            end
            if cut and cut >= i + 12 then
                j = cut
            end
        end
        printf('%s  %s', tag, path:sub(i, j))
        i = j + 1
    end
end

local function doStart()
    routeVar('TurboGainsOn', 'true')
    routeVar('TurboGainsQuiet', 'true')
    mq.cmd('/lua run Turbo/gains')
    printf('\at[TurboGainsToggle]\ax \agstart\ax (quiet) — engine launched on %s.',
        mq.TLO.Me.CleanName() or '?')
end

local function doStop()
    routeVar('TurboGainsOn', 'false')
    routeVar('TurboGainsQuiet', 'false')
    pcall(function() mq.cmd('/lua stop Turbo/loot_announce') end)
    pcall(function() mq.cmd('/turbogains stop') end)
    printf('\at[TurboGainsToggle]\ax \arstop\ax — announcer + turbogains stop on %s.',
        mq.TLO.Me.CleanName() or '?')
end

local function doToggle()
    if e3Truthy(queryE3('TurboGainsOn')) then
        doStop()
    else
        doStart()
    end
end

local function doStatus()
    local ini = resolve_e3_bot_ini_path()
    printf('\at[TurboGainsToggle]\ax TurboGainsOn=%s TurboGainsQuiet=%s autostartINI=%s',
        tostring(queryE3('TurboGainsOn') or '?'),
        tostring(queryE3('TurboGainsQuiet') or '?'),
        ini and (read_autostart_enabled(ini) and 'on' or 'off') or 'unknown')
    if ini then printf_bot_ini_path(ini) end
end

local function doAutostart(arg2)
    local ini = resolve_e3_bot_ini_path()
    if not ini or ini == '' then
        printf('\at[TurboGainsToggle]\ax \arCould not resolve e3 Bot Inis path.\ax')
        return
    end
    local rf = io.open(ini, 'r')
    if not rf then
        printf('\at[TurboGainsToggle]\ax \arCould not open %s\ax', ini)
        return
    end
    local lines = {}
    for line in rf:lines() do lines[#lines + 1] = line end
    rf:close()

    local low = tostring(arg2 or ''):lower()
    local want
    if low == 'on' or low == '1' or low == 'true' then want = true
    elseif low == 'off' or low == '0' or low == 'false' then want = false
    elseif low == 'toggle' or low == '' then
        want = not read_autostart_enabled(ini)
    else
        printf('\at[TurboGainsToggle]\ax usage: autostart on|off|toggle')
        return
    end

    if merge_autostart_startup(lines, want) then
        if not flush_ini(ini, lines) then
            printf('\at[TurboGainsToggle]\ax \arCould not write %s\ax', ini)
            return
        end
        printf('\at[TurboGainsToggle]\ax [Startup Commands] %s = %s — future logins start TurboGains automatically; More > Gains Start also runs it on all boxes.',
            KEY_AUTORUN, want and 'ON' or 'OFF')
    else
        printf('\at[TurboGainsToggle]\ax autostart already %s; INI unchanged.', want and 'ON' or 'OFF')
    end
end

local function runCli(...)
    local cmd = tostring(select(1, ...) or ''):lower():match('^%s*(.-)%s*$') or ''
    local arg2 = select(2, ...)
    if arg2 ~= nil then arg2 = tostring(arg2) end

    if cmd == '' or cmd == 'help' or cmd == '-h' then
        printf('\at[TurboGainsToggle]\ax commands: start | stop | toggle | status | autostart on|off|toggle')
        printf('\at[TurboGainsToggle]\ax Driver: /e3bcaa /lua run Turbo/gains_toggle start')
        return
    end

    if cmd == 'start' then doStart()
    elseif cmd == 'stop' then doStop()
    elseif cmd == 'toggle' then doToggle()
    elseif cmd == 'status' then doStatus()
    elseif cmd == 'autostart' then doAutostart(arg2)
    else
        printf('\at[TurboGainsToggle]\ax unknown %q — try help', cmd)
    end
end

-- When loaded with require('Turbo.gains_toggle'), Lua passes the module name as the sole arg.
local _mod = select(1, ...)
if select('#', ...) == 1 and type(_mod) == 'string' and _mod:find('gains_toggle', 1, true) then
    return {
        resolveE3Ini = resolve_e3_bot_ini_path,
        isAutostartEnabled = function()
            local p = resolve_e3_bot_ini_path()
            if not p then return false end
            return read_autostart_enabled(p)
        end,
    }
end

runCli(...)
