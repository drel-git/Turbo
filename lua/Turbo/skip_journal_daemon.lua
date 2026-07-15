--[[
  Turbo Skip Journal Daemon (optional — macro-only users)
  -------------------------------------------------------
  @version lua/Turbo/skip_journal_daemon.lua 1.1.0

  Background drain for TurboLoot_skip_queue.ini when you run TurboLoot.mac
  WITHOUT the Turbo GUI open. Start once with:

      /lua run Turbo/skip_journal_daemon

  The daemon polls skip_queue every 250 ms, which in turn appends any new
  queue rows to TurboLoot_skips_log.txt via skip_log.append_event.

  If you run /lua run Turbo (the GUI), you don't need this — the GUI drains
  the queue from its own render loop.

  Changelog:
    1.1.0 — Removed dead skip_announce wiring + dead helper functions
            (getSkipLog, resolveIniDirForChar, onLine, onAnnounce — none
            were connected to real work). Only the skipQueue.poll loop
            remains. 128 lines -> ~40 lines, same functional behavior.
    1.0.0 — Header baseline.
]]

local mq = require('mq')

local skipQueue = nil
local ok, mod = pcall(require, 'Turbo/skip_queue')
if ok and type(mod) == 'table' and mod.poll then
    skipQueue = mod
end

if not skipQueue then
    --- Turbo/skip_queue is the only way this daemon can drain. Without it
    --- there's literally nothing for us to do each tick — bail loudly so
    --- the user reinstalls or checks their lua/Turbo/ folder.
    printf('\ar[turboLoot]\ax skip_journal_daemon: \arFATAL\ax cannot require Turbo/skip_queue — check lua/Turbo/skip_queue.lua')
    return
end

printf('\ag[turboLoot]\ax skip_journal_daemon: draining \ayTurboLoot_skip_queue.ini\ax every 250ms (\aykeep this script running\ax).')

while true do
    pcall(skipQueue.poll)
    mq.delay(500)
end
