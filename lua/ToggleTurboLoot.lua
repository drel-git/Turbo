--[[
   ToggleTurboLoot.lua — compatibility alias
   Use /lua run Turbo toggle [CharName] instead (same path as Turbo UI mini ON/OFF).
   This wrapper forwards so existing Buttonmaster binds keep working.
]]

local mq = require('mq')

local a1, a2 = ...
local arg1 = tostring(a1 or 'toggle'):match('^%s*(.-)%s*$') or 'toggle'
local arg2 = tostring(a2 or ''):match('^%s*(.-)%s*$') or ''
local low = arg1:lower()

if low == 'status' then
  if not mq.TLO.MQ2Mono or not mq.TLO.MQ2Mono.Query then
    mq.cmd('/echo [ToggleTurboLoot] MQ2Mono required for status.')
    return
  end
  local on = mq.TLO.MQ2Mono.Query('e3,Turbo')()
  local turbo = (on == 'true' or on == '1' or on == 'on') and 'ON' or 'OFF'
  local mode = mq.TLO.MQ2Mono.Query('e3,GrpLootMode')() or 'single'
  local looter = mq.TLO.MQ2Mono.Query('e3,GrpMainLooter')() or 'NOBODY'
  if looter:find('${', 1, true) then looter = '?' end
  mq.cmdf('/g [TurboLoot] Turbo=%s Mode=%s Looter=%s', turbo, mode, looter)
  return
end

local looterArg = ''
if low == 'toggle' or low == 'on' then
  looterArg = arg2
elseif low == 'off' or low == 'false' then
  mq.cmd('/lua run Turbo toggle')
  return
elseif low == 'looter' or low == 'set' then
  looterArg = arg2
  if looterArg == '' then
    mq.cmd('/echo [ToggleTurboLoot] Use /lua run Turbo toggle CharName')
    return
  end
else
  looterArg = arg1
end

if looterArg ~= '' then
  mq.cmdf('/lua run Turbo toggle %s', looterArg)
else
  mq.cmd('/lua run Turbo toggle')
end
