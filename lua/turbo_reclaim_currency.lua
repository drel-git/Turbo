--[[
  turbo_reclaim_currency.lua - one-shot targeted alt-currency reclaim helper.

  Usage:
    /lua run turbo_reclaim_currency dc [notify Sender] [seq N]
    /lua run turbo_reclaim_currency ps [notify Sender] [seq N]
    /lua run turbo_reclaim_currency ts [notify Sender] [seq N]

  Emits [RECLAIM_DONE] recipient key seq status qty when notify is provided.
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
local reclaim = require('turbo_lib.currency_reclaim')
local transport = require('turbo_lib.transport')

local TAG = '\\at[TurboReclaim]\\ax'
local args = { ... }

local function out(fmt, ...)
    local msg = select('#', ...) > 0 and string.format(fmt, ...) or tostring(fmt or '')
    if _G.printf then
        printf('%s %s', TAG, msg)
    else
        print(TAG .. ' ' .. msg)
    end
end

local function safe_name(name)
    return tostring(name or ''):match('^[%w_]+') or ''
end

local function parse_args()
    local key = tostring(args[1] or ''):lower()
    local notify, seq = '', '0'
    local i = 2
    while i <= #args do
        local low = tostring(args[i] or ''):lower()
        if low == 'notify' and args[i + 1] then
            notify = safe_name(args[i + 1])
            i = i + 1
        elseif low == 'seq' and args[i + 1] then
            seq = tostring(args[i + 1] or '0'):match('^[%w_%-]+') or '0'
            i = i + 1
        end
        i = i + 1
    end
    return key, notify, seq
end

local function send_ack(notify, meta, seq, status, qty)
    notify = safe_name(notify)
    if notify == '' then return end
    local me = core.me_name()
    local ok = transport.send_target(notify, string.format('/echo [RECLAIM_DONE] %s %s %s %s %d',
        me, meta.key, tostring(seq or '0'), tostring(status or 'fail_reclaim'), tonumber(qty) or 0))
    if not ok then
        out('\\ayWARNING --\\ax unable to acknowledge reclaim completion to %s.', notify)
    end
end

local function main()
    local key, notify, seq = parse_args()
    local meta = reclaim.currency_from_key(key)
    if not meta then
        out('\\arAborting:\\ax unknown currency "%s".', key)
        if notify ~= '' then
            local fallback = { key = key ~= '' and key or 'unknown' }
            send_ack(notify, fallback, seq, 'fail_list', 0)
        end
        return false
    end

    local status, qty = reclaim.reclaim_one(meta, { out = out, close = true })
    if status ~= 'ok' and status ~= 'empty' then
        out('\\ayWARNING --\\ax %s reclaim: %s (%d).', meta.label, status, tonumber(qty) or 0)
    end
    send_ack(notify, meta, seq, status, qty)
    return status == 'ok' or status == 'empty'
end

local ok, err = pcall(main)
if not ok then
    out('\\arERROR:\\ax %s', tostring(err))
end
