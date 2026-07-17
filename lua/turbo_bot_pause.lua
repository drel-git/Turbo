--[[
  turbo_bot_pause.lua - one-shot local pause/resume for E3 or RGMercs.
  Run on the box that should pause (including via /e3bct Name ...).

  Usage:
    /lua run turbo_bot_pause pause
    /lua run turbo_bot_pause resume
    /lua run turbo_bot_pause unpause   (alias of resume)

  @version lua/turbo_bot_pause.lua 1.0.0
]]

local args = { ... }
local mode = tostring(args[1] or ''):lower()

local src = (debug.getinfo(1, 'S').source or ''):gsub('^@', '')
local dir = src:gsub('[/\\][^/\\]*$', '')
if dir == '' or dir == src then dir = 'lua' end
package.path = dir .. '/?.lua;' .. dir .. '/?/init.lua;' .. package.path

local bot_pause = require('turbo_lib.bot_pause')

if mode == 'pause' or mode == 'on' then
    bot_pause.pause()
elseif mode == 'resume' or mode == 'unpause' or mode == 'off' then
    bot_pause.resume()
else
    print('[turbo_bot_pause] usage: /lua run turbo_bot_pause pause|resume')
end
