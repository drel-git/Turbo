--[[
  turbo_wallet_ping.lua - one-shot peer wallet publish for Fleet $.
  Usage: /e3bct Peer /lua run turbo_wallet_ping
]]

local mq = require('mq')
do
    local src = (debug.getinfo(1, 'S').source or ''):gsub('^@', '')
    local dir = src:gsub('[/\\][^/\\]*$', '')
    if dir ~= '' and dir ~= src then
        package.path = dir .. '/?.lua;' .. dir .. '/?/init.lua;' .. package.path
    end
end

require('turbo_lib.wallet_ping').publish()
