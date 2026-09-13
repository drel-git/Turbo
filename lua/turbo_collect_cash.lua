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
local wallet_refresh = require('turbo_lib.wallet_refresh')

local TAG = '\at[TurboCash]\ax'
local CURRENCY_NAME = 'Platinum'
local CURRENCY_SHORT = 'PP'
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

local function fmt_num(n)
    local s = tostring(math.floor(tonumber(n) or 0))
    local k
    repeat
        s, k = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
    until k == 0
    return s
end

local function ask_sender(name, recipient, max_pp)
    orch.clear_done(done, name)
    local ok = orch.ask_peer_macro(name, 'turbogive', '_sendcash', recipient, max_pp, core.me_name())
    if not ok then
        out('\ayWARNING --\ax unable to form remote command for %s; skipping.', name)
        return false
    end
    return true
end

local function wait_sender(name, collect_locally, max_pp, recipient)
    local before_pp = collect_locally and core.platinum() or 0
    local start = core.now_ms()
    local last_activity = start
    local saw_trade = false
    local trade_count = 0

    if not ask_sender(name, recipient, max_pp) then
        return 0, 0, false
    end

    while true do
        if mq.doevents then mq.doevents() end

        if collect_locally and core.window_open('TradeWnd') then
            saw_trade = true
            last_activity = core.now_ms()
            if core.accept_trade() then
                trade_count = trade_count + 1
                last_activity = core.now_ms()
            else
                out('\ayWARNING --\ax trade with %s did not close cleanly; moving on.', name)
                break
            end
        end

        if orch.is_done(done, name) then
            if core.now_ms() - last_activity >= IDLE_AFTER_DONE_MS then break end
        elseif saw_trade then
            if core.now_ms() - last_activity >= IDLE_AFTER_TRADE_MS then break end
        elseif core.now_ms() - start >= CASH_TIMEOUT_MS then
            out('\ayWARNING --\ax timed out waiting for %s (60s); moving on.', name)
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
    local scope, max_amount, recipient, from_only, explicit_senders = orch.parse_scope_args(args)
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

    local active, resolve_err = orch.resolve_active_senders(scope, recipient, from_only, explicit_senders)
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
            from_only ~= '' and 'named' or (explicit_senders and 'selected' or (scope == 'all' and 'E3' or 'group')), recipient)
        return false
    end

    out('%s -> \ag%s\ax from %d sender(s)', CURRENCY_NAME, recipient, #active)

    orch.register_done_events(done)

    local total_received, sent_count, responded = 0, 0, 0
    for _, name in ipairs(active) do
        local got, trades, signaled = wait_sender(name, collect_locally, max_amount > 0 and max_amount or nil, recipient)
        sent_count = sent_count + 1
        if signaled or trades > 0 then responded = responded + 1 end
        total_received = total_received + got
        if got > 0 then
            out('%s transferred \ag%s\ax %s', name, fmt_num(got), CURRENCY_SHORT)
        end
        mq.delay(350)
    end

    orch.unregister_done_events()
    core.clear_cursor('finishing', 4000, out)
    wallet_refresh.refresh_participants(recipient, active, { settle = true })

    if collect_locally then
        out('\agComplete --\ax \ag%s\ax %s collected to \ag%s\ax',
            fmt_num(total_received), CURRENCY_SHORT, recipient)
    else
        out('\agComplete --\ax collection sent to \ag%s\ax', recipient)
    end
    return true
end

local ok, err = pcall(main)
orch.unregister_done_events()
if not ok then
    out('\arERROR:\ax %s', tostring(err))
end
