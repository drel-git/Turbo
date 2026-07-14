-- TurboGear/runtime_guard.lua
-- Keeps each client to one local TurboGear owner: either the visible UI or the
-- background responder, never both doing actor/snapshot work.

local M = {}

M.main_names = { 'turbogear' }
M.bg_names = { 'turbogear_bg', 'TurboGearBg' }

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
    }
    local main, main_name = M.any_script_running(mq, main_names)
    local bg, bg_name = M.any_script_running(mq, bg_names)
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
    if bg then return 'publish_bg' end
    return 'start_bg'
end

-- STATIC ROLES: bg responders own actor sync ('bg-owner'); every UI process is
-- a 'viewer' (announce coordinator + renderer). There is no promotion.
function M.role(state, engine_ok, scripts)
    state = state or {}
    if state.bg == true then return 'bg-owner' end
    return 'viewer'
end

-- Announce passivity is static and local: a bg responder mutes its announces
-- only while a main UI runs on the same box (the UI coordinates announces).
-- UIs are never announce-passive.
function M.announce_passive(is_bg, scripts)
    scripts = scripts or {}
    return is_bg == true and scripts.main == true
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

function M.script_summary(scripts)
    scripts = scripts or {}
    return string.format('main=%s bg=%s',
        scripts.main == true and 'running' or 'off',
        scripts.bg == true and 'running' or 'off')
end

return M
