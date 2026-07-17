--[[
  turbo_lib/bot_pause.lua
  Pause/resume the active combat bot on THIS client.
  If rgmercs is RUNNING -> /rgl pause|unpause; else E3Next /e3p on|off.

  Assumes /rgl pause keeps Lua.Script[rgmercs] Status as RUNNING (loop paused,
  script still loaded) so resume can re-detect the same path.
]]

local mq = require('mq')

local M = {}

function M.rgmercs_running()
    local ok, running = pcall(function()
        return mq.TLO.Lua.Script('rgmercs').Status.Equal('RUNNING')() == true
    end)
    return ok and running == true
end

function M.pause()
    if M.rgmercs_running() then
        mq.cmd('/rgl pause')
        return 'rgl'
    end
    mq.cmd('/e3p on')
    return 'e3p'
end

function M.resume()
    if M.rgmercs_running() then
        mq.cmd('/rgl unpause')
        return 'rgl'
    end
    mq.cmd('/e3p off')
    return 'e3p'
end

return M
