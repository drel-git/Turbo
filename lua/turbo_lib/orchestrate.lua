-- turbo_lib/orchestrate.lua
-- Multi-box coordination: member lists, done events, macro dispatch.

local mq = require('mq')
local core = require('turbo_lib.core')

local M = {}

function M.clean_name(name)
    return tostring(name or ''):lower():gsub('[^%w_]', '')
end

function M.sender_name(text)
    return (tostring(text or ''):match('([%w_]+)%s*$')) or ''
end

function M.add_unique(out_list, seen, name)
    name = tostring(name or ''):match('^%s*(.-)%s*$') or ''
    name = name:match('^[%w_]+') or name
    if name == '' then return end
    if M.clean_name(name) == M.clean_name(core.me_name()) then return end
    local key = M.clean_name(name)
    if key == '' or seen[key] then return end
    seen[key] = true
    out_list[#out_list + 1] = name
end

function M.group_members()
    local out_list, seen = {}, {}
    local n = core.safe_num(function() return mq.TLO.Group.Members() end)
    for i = 1, n do
        local name = tostring(core.safe_call('', function() return mq.TLO.Group.Member(i).Name() end) or '')
        M.add_unique(out_list, seen, name)
    end
    return out_list
end

function M.e3_members()
    local out_list, seen = {}, {}
    local peers = tostring(core.safe_call('', function()
        if mq.TLO.MQ2Mono and mq.TLO.MQ2Mono.Query then
            return mq.TLO.MQ2Mono.Query('e3,E3Bots.ConnectedClients')()
        end
        return ''
    end) or '')
    for name in peers:gmatch('([^,]+)') do
        M.add_unique(out_list, seen, name)
    end
    if #out_list == 0 then
        return M.group_members()
    end
    return out_list
end

function M.spawn_exists(name)
    if name == '' then return false end
    return core.safe_num(function() return mq.TLO.Spawn('pc ' .. name).ID() end) > 0
end

function M.active_members(scope)
    local members = scope == 'all' and M.e3_members() or M.group_members()
    local active = {}
    for _, name in ipairs(members) do
        if M.spawn_exists(name) then
            active[#active + 1] = name
        end
    end
    return active
end

function M.parse_scope_args(args)
    local scope = 'group'
    local max_amount = 0
    for _, raw in ipairs(args or {}) do
        local s = tostring(raw or ''):lower()
        if s == 'all' or s == 'e3' or s == 'raid' then
            scope = 'all'
        elseif tonumber(s) and tonumber(s) > 0 then
            max_amount = math.floor(tonumber(s))
        end
    end
    return scope, max_amount
end

function M.create_done_tracker()
    return {}
end

function M.mark_done_from_text(done, text)
    text = tostring(text or '')
    local name = text:match('%[SIGNAL_DONE%].-([%w_]+)%s*$')
        or text:match('%[DONE%].-([%w_]+)%s*%-%>')
        or text:match('%[DONE%].-([%w_]+)%s*$')
    if name and name ~= '' then
        done[M.clean_name(name)] = true
    end
end

function M.register_done_events(done)
    local function on_signal(line, name)
        name = M.sender_name(name)
        if name ~= '' then
            done[M.clean_name(name)] = true
        else
            M.mark_done_from_text(done, line)
        end
    end

    local function on_done(line, name)
        name = M.sender_name(name)
        if name ~= '' then
            done[M.clean_name(name)] = true
        else
            M.mark_done_from_text(done, line)
        end
    end

    pcall(function() mq.event('TurboOrchSignal', '#*#[SIGNAL_DONE]#*##1#', on_signal) end)
    pcall(function() mq.event('TurboOrchDoneArrow', '#*#[DONE]#*##1#->#2#', on_done) end)
    pcall(function() mq.event('TurboOrchDoneAny', '#*#[DONE]#*#', on_done) end)
end

function M.unregister_done_events()
    pcall(function() mq.unevent('TurboOrchSignal') end)
    pcall(function() mq.unevent('TurboOrchDoneArrow') end)
    pcall(function() mq.unevent('TurboOrchDoneAny') end)
end

function M.clear_done(done, name)
    done[M.clean_name(name)] = nil
end

function M.is_done(done, name)
    return done[M.clean_name(name)] == true
end

function M.ask_peer_macro(peer_name, macro, mode, collector_name, amount)
    if amount and amount > 0 then
        mq.cmdf('/squelch /e3bct %s /mac %s %s %s %d', peer_name, macro, mode, collector_name, amount)
    else
        mq.cmdf('/squelch /e3bct %s /mac %s %s %s', peer_name, macro, mode, collector_name)
    end
end

function M.preflight_trade(out_fn)
    if core.cursor_id() > 0 then
        if out_fn then
            out_fn('\arAborting:\ax cursor item detected before start: %s.',
                core.cursor_name() ~= '' and core.cursor_name() or 'unknown item')
        end
        return false
    end
    if core.safe_bool(function() return mq.TLO.Me.Feigning() end) then
        if out_fn then out_fn('\arAborting:\ax cannot trade while feigned.') end
        return false
    end
    return true
end

return M
