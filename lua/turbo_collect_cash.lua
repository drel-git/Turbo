--[[
  turbo_collect_cash.lua - Lua coordinator for collecting platinum from peers.
  @version lua/turbo_collect_cash.lua 1.0.0
  Usage:
    /lua run turbo_collect_cash
    /lua run turbo_collect_cash all
    /lua run turbo_collect_cash 500
    /lua run turbo_collect_cash all 500

  Hybrid model: this script orchestrates collection and accepts trades;
  sender boxes still use TurboGive.mac _sendcash for pickup/trade-fill logic.
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

local function ask_sender(name, max_pp)
    orch.clear_done(done, name)
    orch.ask_peer_macro(name, 'turbogive', '_sendcash', core.me_name(), max_pp)
end

local function collect_from_sender(name, max_pp)
    out('\ao[COLLECT CASH]\ax Asking \ag%s\ax to send cash...', name)
    local before_pp = core.platinum()
    local start = core.now_ms()
    local last_activity = start
    local saw_trade = false
    local trade_count = 0

    ask_sender(name, max_pp)

    while true do
        if mq.doevents then mq.doevents() end

        if core.window_open('TradeWnd') then
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

    local after_pp = core.platinum()
    local received = math.max(0, after_pp - before_pp)
    local signaled = orch.is_done(done, name)
    return received, trade_count, signaled
end

local function main()
    local scope, max_amount = orch.parse_scope_args(args)
    if not orch.preflight_trade(out) then return false end

    local active = orch.active_members(scope)
    if #active == 0 then
        out('\arNo %s members found in-zone to collect cash from.', scope == 'all' and 'E3' or 'group')
        return false
    end

    out('\ao[COLLECT CASH]\ax Collecting from %s: %d sender(s)%s.',
        scope == 'all' and 'all E3 peers' or 'group',
        #active,
        max_amount > 0 and (' (limit: ' .. tostring(max_amount) .. 'pp plat each)') or '')

    orch.register_done_events(done)

    local total_received = 0
    local sent_count = 0
    local responded = 0

    for _, name in ipairs(active) do
        local got, trades, signaled = collect_from_sender(name, max_amount > 0 and max_amount or nil)
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

    out('\agComplete.\ax \ag%d\ax/\ag%d\ax requests returned activity. Total received: \ag%d\ax pp. Platinum now: \ag%d\ax.',
        responded, sent_count, total_received, core.platinum())
    return true
end

local ok, err = pcall(main)
orch.unregister_done_events()
if not ok then
    out('\arERROR:\ax %s', tostring(err))
end
