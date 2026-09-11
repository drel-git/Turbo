-- TurboGear peer autostart helper.
-- Safe to broadcast often: idempotent ensure-bg. Starts the bg responder when
-- absent; noops when it is already running (bg owns keepalive + inventory dirty
-- publishes — do not force a full inventory republish on every soft-launch).

local mq = require('mq')
local args = { ... }
local mode = tostring(args[1] or ''):lower()
local src = (debug.getinfo(1, "S").source or ""):gsub("^@", "")
local dir = src:gsub("[/\\][^/\\]*$", "")
if dir == "" or dir == src then dir = "lua" end
local base = dir .. "/turbogear/"
package.path = base .. "?.lua;" .. base .. "?/init.lua;" .. package.path

local guard = require('runtime_guard')
local scripts = guard.detect(mq, { lua_name = 'turbogear', bg_lua_name = 'turbogear_bg' })
local decision = guard.autostart_decision(scripts, mode)

if decision == 'repair_bg' then
    -- Repair only the background responder. Leave any visible UI alone.
    local stopped = {}
    local function stop_bg(name)
        name = tostring(name or '')
        if name == '' or stopped[name] then return end
        stopped[name] = true
        mq.cmd('/squelch /lua stop ' .. name)
    end
    for _, bg_name in ipairs(guard.bg_names or { 'turbogear_bg', 'TurboGearBg' }) do
        if guard.script_running(mq, bg_name) then stop_bg(bg_name) end
    end
    if guard.each_lua_script then
        guard.each_lua_script(mq, function(name, status, pid, path)
            if not guard.status_is_running(status) then return end
            if guard.is_bg_script_name(name) or guard.is_bg_script_name(path) then
                stop_bg(name ~= '' and name or 'turbogear_bg')
                if pid and pid ~= '' then stop_bg(tostring(pid)) end
            end
        end)
    end
    mq.cmd('/timed 5 /squelch /lua run turbogear_bg')
    return
elseif decision == 'noop' then
    return
end

mq.cmd('/squelch /lua run turbogear_bg')
