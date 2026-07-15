--[[
   Compatibility launcher for TurboGains.
   Prefer: /lua run Turbo/gains
   @version lua/Turbo/loot_money.lua 3.0.1
]]

local mq = require('mq')
pcall(function() mq.cmd('/lua run Turbo/gains') end)
return {}
