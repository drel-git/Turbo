-- turbo_remote_cmd.lua
-- One-shot targeted remote-command bridge for MacroQuest macros.

local mq = require('mq')
do
    local src = (debug.getinfo(1, 'S').source or ''):gsub('^@', '')
    local dir = src:gsub('[/\\][^/\\]*$', '')
    if dir ~= '' and dir ~= src then
        package.path = dir .. '/?.lua;' .. dir .. '/?/init.lua;' .. package.path
    end
end

local transport = require('turbo_lib.transport')

local args = { ... }

local function decode_payload(payload)
    payload = tostring(payload or '')
    return (payload:gsub('%%(%x%x)', function(hex)
        return string.char(tonumber(hex, 16))
    end))
end

local function clean_target(name)
    return tostring(name or ''):match('^%s*([%w_]+)%s*$') or ''
end

local function out(fmt, ...)
    local msg = select('#', ...) > 0 and string.format(fmt, ...) or tostring(fmt or '')
    if _G.printf then
        printf('\\at[TurboRemote]\\ax %s', msg)
    else
        print('[TurboRemote] ' .. msg)
    end
end

local function main()
    local target = clean_target(args[1])
    local mode = tostring(args[2] or ''):lower()
    if target == '' then
        out('\\arERROR:\\ax missing or invalid target.')
        return false
    end
    if mode ~= 'encoded' then
        out('\\arERROR:\\ax unsupported payload mode "%s".', tostring(args[2] or ''))
        return false
    end
    local cmd = decode_payload(args[3] or '')
    if cmd == '' then
        out('\\arERROR:\\ax empty remote command for %s.', target)
        return false
    end
    local ok, built, route = transport.send_target(target, cmd)
    if not ok then
        out('\\arERROR:\\ax unable to form remote command for %s (%s).', target, tostring(built or route or 'no_route'))
        return false
    end
    return true
end

local ok, err = pcall(main)
if not ok then
    out('\\arERROR:\\ax %s', tostring(err))
end

return {
    decode_payload = decode_payload,
}
