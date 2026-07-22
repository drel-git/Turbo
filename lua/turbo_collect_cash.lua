--[[
  turbo_collect_cash.lua - Lua coordinator for collecting / pooling platinum.
  @version lua/turbo_collect_cash.lua 1.1.0
  Usage:
    /lua run turbo_collect_cash
    /lua run turbo_collect_cash all
    /lua run turbo_collect_cash 500
    /lua run turbo_collect_cash all 500
    /lua run turbo_collect_cash from Name
    /lua run turbo_collect_cash to Name
    /lua run turbo_collect_cash from A to B
    /lua run turbo_collect_cash all to Name

  Hybrid model: this script orchestrates collection and accepts trades when
  recipient is self; sender boxes use TurboGive.mac _sendcash.
]]

local mq = require('mq')
local core = require('turbo_lib.core')
local orch = require('turbo_lib.orchestrate')

local TAG = '\at[TurboCash]\ax'
local CASH_TIMEOUT_MS = 60000
local IDLE_AFTER_TRADE_MS = 8000
local IDLE_AFTER_DONE_MS = 3000

local args = { ... }
local done = orch.create_done_tracker()

local function out(fmt, ...)
    local msg = select('#', ...) > 0 and string.format(fmt, ...) or tostring(fmt or '')
    if _G.printf then
        printf('%s %s', TAG, msg)
    else
        print(TAG .. ' ' .. msg)
    end
end

local function ask_sender(name, recipient, max_pp)
    orch.clear_done(done, name)
    orch.ask_peer_macro(name, 'turbogive', '_sendcash', recipient, max_pp)
end

local function wait_sender(name, collect_locally, max_pp, recipient)
    out('\ao[COLLECT CASH]\ax Asking \ag%s\ax...', name)
    local before_pp = collect_locally and core.platinum() or 0
    local start = core.now_ms()
    local last_activity = start
    local saw_trade = false
    local trade_count = 0

    ask_sender(name, recipient, max_pp)

    while true do
        if mq.doevents then mq.doevents() end

        if collect_locally and core.window_open('TradeWnd') then
            saw_trade = true
            last_activity = core.now_ms()
            if core.accept_trade() then
                trade_count = trade_count + 1
                last_activity = core.now_ms()
            else
                out('\ay[COLLECT CASH]\ax Trade with %s did not close cleanly; moving on.', name)
                break
            end
        end

        if orch.is_done(done, name) then
            if core.now_ms() - last_activity >= IDLE_AFTER_DONE_MS then break end
        elseif saw_trade then
            if core.now_ms() - last_activity >= IDLE_AFTER_TRADE_MS then break end
        elseif core.now_ms() - start >= CASH_TIMEOUT_MS then
            out('\ay[COLLECT CASH]\ax Timed out waiting for %s (60s). Moving on.', name)
            break
        end

        mq.delay(100)
    end

    if collect_locally then
        local after_pp = core.platinum()
        local received = math.max(0, after_pp - before_pp)
        return received, trade_count, orch.is_done(done, name)
    end
    return 0, trade_count, orch.is_done(done, name)
end

local function main()
    local scope, max_amount, recipient, from_only = orch.parse_scope_args(args)
    local me = core.me_name()
    if recipient == '' then recipient = me end
    local collect_locally = orch.clean_name(recipient) == orch.clean_name(me)

    if not orch.preflight_trade(out) then return false end
    if recipient == '' then
        out('\arAborting:\ax no recipient.')
        return false
    end
    if not collect_locally and not orch.spawn_exists(recipient) then
        out('\arAborting:\ax recipient %s is not in zone.', recipient)
        return false
    end

    local active, resolve_err = orch.resolve_active_senders(scope, recipient, from_only)
    if resolve_err == 'from_to_same' then
        out('\arAborting:\ax from and to cannot be the same (%s).', from_only)
        return false
    end
    if resolve_err == 'from_missing' then
        out('\arAborting:\ax sender %s is not in zone.', from_only)
        return false
    end
    if #active == 0 then
        out('\arNo %s members found in-zone to move cash from (recipient %s excluded).',
            from_only ~= '' and 'named' or (scope == 'all' and 'E3' or 'group'), recipient)
        return false
    end

    out('\ao[COLLECT CASH]\ax %s -> \ag%s\ax from %d sender(s) (%s)%s.',
        collect_locally and 'Collect' or 'Pool',
        recipient,
        #active,
        from_only ~= '' and ('from ' .. from_only) or (scope == 'all' and 'E3 peers' or 'group'),
        max_amount > 0 and (' limit ' .. tostring(max_amount) .. 'pp each') or '')

    orch.register_done_events(done)

    local total_received, sent_count, responded = 0, 0, 0
    for _, name in ipairs(active) do
        local got, trades, signaled = wait_sender(name, collect_locally, max_amount > 0 and max_amount or nil, recipient)
        sent_count = sent_count + 1
        if signaled or trades > 0 then responded = responded + 1 end
        total_received = total_received + got
        if got > 0 then
            out('\ao[COLLECT CASH]\ax %s delivered \ag%d\ax pp. Platinum now: \ag%d\ax.', name, got, core.platinum())
        end
        mq.delay(350)
    end

    orch.unregister_done_events()
    core.clear_cursor('finishing', 4000, out)

    if collect_locally then
        out('\agComplete.\ax \ag%d\ax/\ag%d\ax requests returned activity. Total received: \ag%d\ax pp. Platinum now: \ag%d\ax.',
            responded, sent_count, total_received, core.platinum())
    else
        out('\agComplete.\ax \ag%d\ax/\ag%d\ax senders signaled. Recipient: \ag%s\ax.',
            responded, sent_count, recipient)
    end
    return true
end

local ok, err = pcall(main)
orch.unregister_done_events()
if not ok then
    out('\arERROR:\ax %s', tostring(err))
end
