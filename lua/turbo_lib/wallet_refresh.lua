-- One-shot TurboGear Wallet refresh requests for characters changed by collectors.

local mq = require('mq')
local core = require('turbo_lib.core')
local transport = require('turbo_lib.transport')

local M = {}

local WALLET_SETTLE_CMD = '/tgearbg wallet settle postcollect'
local WALLET_DIRECT_CMD = '/tgearbg wallet postcollect'
local WALLET_FOLLOWUP_CMD = '/timed 10 /tgearbg wallet postcollect'

local function clean_name(name)
    return tostring(name or ''):lower():gsub('[^%w_]', '')
end

local function display_name(name)
    return tostring(name or ''):match('^%s*([%w_]+)%s*$') or ''
end

local function add_unique(out, seen, name)
    name = display_name(name)
    if name == '' then return end
    local key = clean_name(name)
    if key == '' or seen[key] then return end
    seen[key] = true
    out[#out + 1] = name
end

function M.refresh_participants(recipient, active_senders, opts)
    opts = type(opts) == 'table' and opts or {}
    local immediate_cmd = opts.settle == true and WALLET_SETTLE_CMD or WALLET_DIRECT_CMD
    local names, seen = {}, {}
    add_unique(names, seen, recipient)
    if type(active_senders) == 'table' then
        for _, name in ipairs(active_senders) do
            add_unique(names, seen, name)
        end
    end

    local me_key = clean_name(core.me_name())
    local count = 0
    for _, name in ipairs(names) do
        if clean_name(name) == me_key then
            mq.cmd('/squelch ' .. immediate_cmd)
            mq.cmd('/squelch ' .. WALLET_FOLLOWUP_CMD)
        else
            local ok_bg = transport.send_target(name, immediate_cmd)
            local ok_followup = transport.send_target(name, WALLET_FOLLOWUP_CMD)
            if not ok_bg and not ok_followup then
                print(string.format('[TurboWallet] WARNING -- unable to form wallet refresh command for %s.', name))
            end
        end
        count = count + 1
    end
    return count, names
end

return M
