-- TurboGear/runtime_guard.lua
-- Keeps each client to one local TurboGear owner: either the visible UI or the
-- background responder, never both doing actor/snapshot work.

local M = {}

M.main_names = { 'turbogear' }
-- Named lookups are a hint only. MQ2Lua's Script TLO indexes by PID; some
-- installs report the file as TurboGear_bg / lua/turbogear_bg. A miss here
-- used to `/lua run turbogear_bg` on a box that already had it -- restarting
-- the live responder and crashing that client with no Lua message.
M.bg_names = { 'turbogear_bg', 'TurboGearBg', 'TurboGear_bg', 'lua/turbogear_bg' }

function M.status_is_running(status)
    local text = tostring(status or ''):lower()
    if text == '' then return false end
    if text:find('not', 1, true)
        or text:find('stop', 1, true)
        or text:find('ended', 1, true)
        or text:find('ending', 1, true) then
        return false
    end
    return text == 'running' or text == 'run' or text:find('running', 1, true) ~= nil
end

function M.normalize_script_name(name)
    local n = tostring(name or ''):lower():gsub('\\', '/')
    n = n:gsub('%.lua$', '')
    return n:match('([^/]+)$') or n
end

function M.is_bg_script_name(name)
    local n = M.normalize_script_name(name)
    if n == '' or n:find('autostart', 1, true) then return false end
    if n == 'turbogear_bg' or n == 'turbogearbg' or n == 'turbo_gear_bg' then return true end
    return n:match('turbogear[_%-]?bg') ~= nil
end

function M.is_main_script_name(name)
    local n = M.normalize_script_name(name)
    if n == '' or M.is_bg_script_name(n) then return false end
    if n:find('autostart', 1, true) then return false end
    return n == 'turbogear' or n == 'turbogearui'
end

function M.each_lua_script(mq, fn)
    if not mq or type(fn) ~= 'function' then return end
    local pids = nil
    pcall(function()
        local lua = mq.TLO and mq.TLO.Lua
        if lua and lua.PIDs then pids = lua.PIDs() end
    end)
    if (type(pids) ~= 'string' or pids == '' or tostring(pids):upper() == 'NULL') and mq.parse then
        pcall(function() pids = mq.parse('${Lua.PIDs}') end)
    end
    if type(pids) ~= 'string' or pids == '' or tostring(pids):upper() == 'NULL' then return end
    local lua = mq.TLO and mq.TLO.Lua
    for pid in pids:gmatch('[^,%s]+') do
        local name, status, path = '', '', ''
        pcall(function()
            -- Script is PID-indexed. Try the integer first: a string miss can
            -- return the last-finished script (truthy) and hide the real one.
            local script = nil
            local n = tonumber(pid)
            if lua and lua.Script then
                if n then script = lua.Script(n) end
                if not script then script = lua.Script(pid) end
            end
            if not script then return end
            if script.Name then name = tostring(script.Name() or '') end
            if script.Status then status = tostring(script.Status() or '') end
            if script.Path then path = tostring(script.Path() or '') end
        end)
        if name == '' and mq.parse then
            pcall(function()
                name = tostring(mq.parse(string.format('${Lua.Script[%s].Name}', pid)) or '')
            end)
            pcall(function()
                status = tostring(mq.parse(string.format('${Lua.Script[%s].Status}', pid)) or '')
            end)
            pcall(function()
                path = tostring(mq.parse(string.format('${Lua.Script[%s].Path}', pid)) or '')
            end)
        end
        fn(name, status, pid, path)
    end
end

function M.script_running(mq, name)
    name = tostring(name or '')
    if name == '' or not mq then return false end
    local ok, status = pcall(function()
        local lua = mq.TLO and mq.TLO.Lua
        if not lua or not lua.Script then return '' end
        local script = lua.Script(name)
        if not script or not script.Status then return '' end
        return script.Status() or ''
    end)
    if ok and M.status_is_running(status) then return true end
    if mq.parse then
        local ok_parse, parsed = pcall(function()
            return mq.parse(string.format('${Lua.Script[%s].Status}', name))
        end)
        if ok_parse and M.status_is_running(parsed) then return true end
    end
    return false
end

function M.any_script_running(mq, names)
    for _, name in ipairs(names or {}) do
        if M.script_running(mq, name) then return true, name end
    end
    return false, nil
end

function M.detect(mq, cfg)
    cfg = cfg or {}
    local main_names = { tostring(cfg.lua_name or 'turbogear') }
    local bg_names = {
        tostring(cfg.bg_lua_name or 'turbogear_bg'),
        'TurboGearBg',
        'TurboGear_bg',
        'lua/turbogear_bg',
    }
    local main, main_name = M.any_script_running(mq, main_names)
    local bg, bg_name = M.any_script_running(mq, bg_names)
    -- Authoritative scan: Script TLO is PID-indexed. Named lookup misses are
    -- what made group autostart restart a healthy bg-only box.
    M.each_lua_script(mq, function(name, status, _pid, path)
        if not M.status_is_running(status) then return end
        if not bg and (M.is_bg_script_name(name) or M.is_bg_script_name(path)) then
            bg = true
            bg_name = (name ~= '' and name) or path
        end
        if not main and (M.is_main_script_name(name) or M.is_main_script_name(path)) then
            main = true
            main_name = (name ~= '' and name) or path
        end
    end)
    return {
        main = main == true,
        main_name = main_name or main_names[1],
        bg = bg == true,
        bg_name = bg_name or bg_names[1],
    }
end

function M.autostart_decision(scripts, mode)
    scripts = scripts or {}
    mode = tostring(mode or ''):lower()
    local bg = scripts.bg == true
    if mode == 'repair' or mode == 'force' then
        return 'repair_bg'
    end
    -- Contract: ensure bg is running on boxes that do not have a local UI.
    -- If the TurboGear UI is already running here, it owns starting the
    -- responder. Group soft-launch must not also `/lua run turbogear_bg` on
    -- that driver -- two overlapping loads crash the client.
    if bg then return 'noop' end
    if scripts.main == true then return 'noop' end
    return 'start_bg'
end

-- STATIC ROLES: bg responders own actor sync ('bg-owner'); every UI process is
-- a 'viewer' (announce coordinator + renderer). There is no promotion.
function M.role(state, engine_ok, scripts)
    state = state or {}
    if state.bg == true then return 'bg-owner' end
    return 'viewer'
end

-- Every bg responder is announce-passive. Chat events + catalog warm on a
-- bg-only box were enough to drop the client with no popup. The UI driver
-- owns [TG]; this process still answers actor REQUEST after it settles.
function M.announce_passive(is_bg, scripts)
    return is_bg == true
end

-- R5: decide when the viewer should issue its delegated startup sync. Prefer
-- waiting until the bg responder has acked readiness (its mailbox is live), so
-- the sync is not fired at a machine-tuned fixed delay that may be too early on
-- a slow box. Fall back after a deadline so a missing/late ack never blocks the
-- sync forever (degrading to the old fixed-delay behavior). Returns (go, reason).
function M.should_request_bg_sync(opts)
    opts = opts or {}
    if opts.sent then return false, "already_sent" end
    if opts.bg_ready == true then return true, "bg_ready" end
    local now, deadline = tonumber(opts.now), tonumber(opts.deadline)
    if now and deadline and now >= deadline then return true, "deadline" end
    return false, "waiting"
end

-- Decide whether to run the patch-stop routine: the patcher's lock is present
-- and we have not already begun stopping. Pure so it is unit-testable.
function M.should_patch_stop(opts)
    opts = opts or {}
    return opts.lock_present == true and opts.stopping ~= true
end

function M.script_summary(scripts)
    scripts = scripts or {}
    return string.format('main=%s bg=%s',
        scripts.main == true and 'running' or 'off',
        scripts.bg == true and 'running' or 'off')
end

return M
