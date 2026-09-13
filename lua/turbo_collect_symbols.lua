--[[
  turbo_collect_symbols.lua - Lua coordinator for Planar/Taelosian Symbol collection.

  Usage:
    /lua run turbo_collect_symbols ps list A,B to Collector
    /lua run turbo_collect_symbols ts list A,B to Collector

  Sender boxes use TurboGive.mac _sendps/_sendts. Remote recipients are reclaimed
  by the sender-side RECLAIM_DONE handshake; local recipients reclaim here.
]]

local mq = require('mq')
do
    local src = (debug.getinfo(1, 'S').source or ''):gsub('^@', '')
    local dir = src:gsub('[/\\][^/\\]*$', '')
    if dir ~= '' and dir ~= src then
        package.path = dir .. '/?.lua;' .. dir .. '/?/init.lua;' .. package.path
    end
end

local core = require('turbo_lib.core')
local orch = require('turbo_lib.orchestrate')
local reclaim = require('turbo_lib.currency_reclaim')
local wallet_refresh = require('turbo_lib.wallet_refresh')
local transport = require('turbo_lib.transport')

local TAG = '\\at[TurboSymbols]\\ax'
local MAX_PASSES = 200
local FIRST_ACTIVITY_TIMEOUT_MS = 300000
local IDLE_AFTER_TRADE_MS = 12000
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

local function currency_short(meta)
    local key = tostring(meta and meta.key or ''):upper()
    return key ~= '' and key or tostring(meta and meta.label or '')
end

local function clean_name(name)
    return orch.clean_name(name)
end

local function currency_from_args()
    for _, arg in ipairs(args) do
        local meta = reclaim.currency_from_key(arg)
        if meta then return meta end
    end
    return reclaim.CURRENCIES.ps
end

local function item_count(meta)
    return core.item_count('=' .. meta.item, false)
end

local function read_alt(meta)
    local n = core.safe_num(function()
        local t = mq.TLO.Me.AltCurrency(meta.alt)
        return t and t() or 0
    end)
    if n > 0 then return n end
    return core.safe_num(function()
        local t = mq.TLO.Me.AltCurrency(meta.alt_singular)
        return t and t() or 0
    end)
end

local function reclaim_local(meta)
    local status, qty = reclaim.reclaim_one(meta, { out = out, close = true })
    if status ~= 'ok' and status ~= 'empty' then
        out('\\ay[%s]\\ax Local reclaim returned %s.', meta.label, status)
    end
    return qty or 0
end

local function ask_sender(name, recipient, meta, chunk, remote_reclaim)
    orch.clear_done(done, name)
    local ack = remote_reclaim and ' ack' or ''
    local notify = string.format(' notify %s', core.me_name())
    local route = transport.route_hint_arg and transport.route_hint_arg() or ''
    local ok
    if chunk and chunk > 0 then
        ok = transport.send_target(name, string.format('/mac turbogive %s %s %d%s%s%s', meta.send_mode, recipient, chunk, ack, notify, route))
    else
        ok = transport.send_target(name, string.format('/mac turbogive %s %s%s%s%s', meta.send_mode, recipient, ack, notify, route))
    end
    if not ok then
        out('\\ayWARNING --\\ax unable to form remote command for %s; skipping.', name)
        return false
    end
    return true
end

local function wait_sender(name, recipient, meta, collect_locally, chunk)
    local before_alt = collect_locally and read_alt(meta) or 0
    local before_inv = collect_locally and item_count(meta) or 0
    local start = core.now_ms()
    local last_activity = start
    local saw_trade = false
    local trade_count = 0

    if not ask_sender(name, recipient, meta, chunk, not collect_locally) then
        return 0, 0, false
    end

    while true do
        if mq.doevents then mq.doevents() end

        if collect_locally and core.window_open('TradeWnd') then
            saw_trade = true
            last_activity = core.now_ms()
            if core.accept_trade() then
                trade_count = trade_count + 1
                mq.delay(350)
                reclaim_local(meta)
                last_activity = core.now_ms()
            else
                out('\\ayWARNING --\\ax trade with %s did not close cleanly; moving on.', name)
                break
            end
        end

        if collect_locally and item_count(meta) > 0 then
            reclaim_local(meta)
            last_activity = core.now_ms()
        end

        if orch.is_done(done, name) then
            if core.now_ms() - last_activity >= IDLE_AFTER_DONE_MS then break end
        elseif saw_trade then
            if core.now_ms() - last_activity >= IDLE_AFTER_TRADE_MS then break end
        elseif core.now_ms() - start >= FIRST_ACTIVITY_TIMEOUT_MS then
            out('\\ayWARNING --\\ax timed out waiting for %s.', name)
            break
        end

        mq.delay(100)
    end

    if collect_locally then
        reclaim_local(meta)
        local after_alt = read_alt(meta)
        local after_inv = item_count(meta)
        local received = math.max(0, (after_alt - before_alt) + math.max(0, after_inv - before_inv))
        return received, trade_count, orch.is_done(done, name)
    end
    return 0, trade_count, orch.is_done(done, name)
end

local function request_remote_cleanup(recipient, meta)
    if clean_name(recipient) == clean_name(core.me_name()) then return end
    local ok = transport.send_target(recipient, string.format('/squelch /lua run turbo_reclaim_currency %s', meta.key))
    if not ok then
        out('\\ayWARNING --\\ax unable to request final %s reclaim on %s.', meta.label, recipient)
    end
end

local function main()
    local meta = currency_from_args()
    local scope, max_amount, recipient, from_only, explicit_senders = orch.parse_scope_args(args)
    local me = core.me_name()
    if recipient == '' then recipient = me end
    local collect_locally = clean_name(recipient) == clean_name(me)
    local send_chunk = (tonumber(max_amount) or 0) > 0 and math.floor(max_amount) or 0

    if not orch.preflight_trade(out) then return false end
    if not collect_locally and not orch.spawn_exists(recipient) then
        out('\\arAborting:\\ax recipient %s is not in zone.', recipient)
        return false
    end

    if collect_locally and item_count(meta) > 0 then
        reclaim_local(meta)
    end

    local active, resolve_err = orch.resolve_active_senders(scope, recipient, from_only, explicit_senders)
    if resolve_err == 'from_to_same' then
        out('\\arAborting:\\ax from and to cannot be the same (%s).', from_only)
        return false
    elseif resolve_err == 'from_missing' then
        out('\\arAborting:\\ax sender %s is not in zone.', from_only)
        return false
    elseif #active == 0 then
        out('\\arNo selected in-zone senders found for %s.', meta.label)
        return false
    end

    if collect_locally and core.free_inventory() <= 0 and item_count(meta) <= 0 then
        out('\\ayWarning:\\ax no free inventory slots. Incoming %s may fail if it cannot stack.', meta.label)
    end

    out('%s -> \\ag%s\\ax from %d sender(s)', meta.label, recipient, #active)

    orch.register_done_events(done)

    local total_received, sent_count, responded = 0, 0, 0
    local passes, empty_passes = 0, 0

    for pass = 1, MAX_PASSES do
        passes = pass
        local pass_received = 0
        local pass_activity = 0
        for _, name in ipairs(active) do
            local got, trades, signaled = wait_sender(name, recipient, meta, collect_locally, send_chunk)
            sent_count = sent_count + 1
            if signaled or trades > 0 then
                responded = responded + 1
                pass_activity = pass_activity + 1
            end
            total_received = total_received + got
            pass_received = pass_received + got
            if got > 0 then
                out('%s transferred \\ag%s\\ax %s', name, fmt_num(got), currency_short(meta))
            end
            if not collect_locally then request_remote_cleanup(recipient, meta) end
            mq.delay(350)
        end

        if collect_locally then
            empty_passes = pass_received <= 0 and (empty_passes + 1) or 0
        else
            empty_passes = pass_activity <= 0 and (empty_passes + 1) or 0
        end
        if not collect_locally then break end
        if empty_passes >= 1 then break end
    end

    orch.unregister_done_events()
    if collect_locally then
        reclaim_local(meta)
    else
        request_remote_cleanup(recipient, meta)
    end
    core.clear_cursor('finishing', 4000, out)
    core.close_inventory()
    wallet_refresh.refresh_participants(recipient, active)

    if collect_locally then
        out('\\agComplete --\\ax \\ag%s\\ax %s collected to \\ag%s\\ax',
            fmt_num(total_received), currency_short(meta), recipient)
    else
        out('\\agComplete --\\ax collection sent to \\ag%s\\ax', recipient)
    end
    return true
end

local ok, err = pcall(main)
orch.unregister_done_events()
if not ok then
    out('\\arERROR:\\ax %s', tostring(err))
end
