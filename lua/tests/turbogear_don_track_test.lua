-- Run from repo root: luajit lua/tests/turbogear_don_track_test.lua
-- The runtime layer around don_state. The assertion that matters most is the
-- capturedAt ordering: /tasktime prints only ACTIVE replay timers, so absence
-- means "ready" -- but that inference is only valid once the output has
-- arrived. Stamping on send would report every locked mission as available for
-- the second or two before the lines land, which is both wrong and
-- intermittent enough to be miserable to reproduce.
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

local commands = {}
local events = {}

package.preload['mq'] = function()
    return {
        cmd = function(c) commands[#commands + 1] = c end,
        event = function(name, pattern, fn) events[name] = { pattern = pattern, fn = fn } end,
        TLO = { Task = function() return nil end },
        configDir = '.',
    }
end
package.preload['config'] = function()
    return { CFG = {}, Settings = {}, SharedSettings = {} }
end

local track = require('don_track')
local don = require('don_state')

local pass, fail = 0, 0
local function check(cond, msg)
    if cond then pass = pass + 1 else fail = fail + 1; print("  FAIL: " .. tostring(msg)) end
end

-- Controllable clocks: monotonic for deadlines, wall for expiries.
local mono, walltime = 0, 1000000
local function reset()
    commands, events = {}, {}
    mono, walltime = 0, 1000000
    track._reset_for_tests()
    track._set_seams({
        clock = function() return mono end,
        wall = function() return walltime end,
        issue = function(c) commands[#commands + 1] = c end,
    })
end

local function advance(seconds)
    mono = mono + seconds
    walltime = walltime + seconds
end

local TASKTIME = "'T1: Best Laid Plans [Solo] ' replay timer: 0d:3h:44m remaining."

-- ------------------------------------------------- nothing happens unbidden
reset()
for _ = 1, 50 do track.tick(); advance(1) end
check(#commands == 0, "tick alone never issues a command; the refresh is demand-driven")
check(track.captured() == false, "no capture without a completed sweep")

local idle = {}
track.embed(idle)
check(type(idle.DoNState) == "table", "state is embedded even when empty")
check(don.resolve(idle.DoNState, "Best Laid Plans", walltime) == don.STATE_UNKNOWN,
    "uncaptured state reports unknown, not a false ready")

-- ------------------------------------------------------- the ordering trap
reset()
track.note_refresh_wanted()
check(#commands == 0, "requesting from a draw callback does not itself issue the command")

track.tick()
check(#commands == 1 and commands[1] == '/tasktime', "tick issues exactly one /tasktime")
check(track.captured() == false, "NOT captured at the moment the command is sent")
check(track.pending() == true, "sweep reported as pending")

-- The window during which output is still arriving. Everything must read
-- unknown, because a locked mission has not had a chance to report itself yet.
advance(1)
track.tick()
check(track.captured() == false, "still not captured 1s in, while output is in flight")
local mid = {}
track.embed(mid)
check(don.resolve(mid.DoNState, "Best Laid Plans", walltime) == don.STATE_UNKNOWN,
    "mid-flight rows read unknown, never ready")

-- A line arriving mid-flight is captured immediately.
track.ingest(TASKTIME)
local during = {}
track.embed(during)
check(don.resolve(during.DoNState, "Best Laid Plans", walltime) == don.STATE_REPLAY,
    "a replay line lands as soon as it arrives, without waiting for the settle")

advance(2.5)
track.tick()
check(track.captured() == true, "captured once the settle deadline passes")
check(track.pending() == false, "no longer pending")

local after = {}
track.embed(after)
check(don.resolve(after.DoNState, "Best Laid Plans", walltime) == don.STATE_REPLAY,
    "captured line still locked")
check(don.resolve(after.DoNState, "Sudden Tremors", walltime) == don.STATE_READY,
    "a mission absent from the sweep reads ready only after the settle")

-- ------------------------------------------------------------- rate limits
reset()
track.note_refresh_wanted()
track.tick()
advance(4)
track.tick()
check(#commands == 1, "settle completed with a single command")

track.note_refresh_wanted()
track.tick()
check(#commands == 1, "a second request inside the cooldown is dropped")

advance(30)
track.note_refresh_wanted()
track.tick()
check(#commands == 2, "request honoured once the cooldown elapses")

-- Repeated tab toggling must not queue up commands.
reset()
for _ = 1, 25 do track.note_refresh_wanted(); track.tick(); advance(0.1) end
check(#commands == 1, "25 rapid requests collapse to one command, got " .. #commands)

-- ------------------------------------------------------ passive chat capture
reset()
track.ensure_events()
check(events['tgDonReplayTimer'] ~= nil, "replay listener registered")
check(events['tgDonReplayTimer'].pattern == '#*#replay timer#*#',
    "one loose pattern covers both message formats")

-- Drive the real callback the way MacroQuest would.
events['tgDonReplayTimer'].fn(TASKTIME)
local passive = {}
track.embed(passive)
check(don.resolve(passive.DoNState, "Best Laid Plans", walltime) == don.STATE_REPLAY,
    "passively captured grant locks the row with no command issued")
check(#commands == 0, "passive capture costs no command")
-- Still unknown for everything else: we never swept, so absence proves nothing.
check(don.resolve(passive.DoNState, "Sudden Tremors", walltime) == don.STATE_UNKNOWN,
    "passive capture alone does not license a ready verdict elsewhere")

check(track.ingest("You have gained experience!") == nil, "unrelated chat ignored")
check(track.ingest(nil) == nil, "nil line ignored")

-- --------------------------------------------------------- embedded copies
reset()
track.ingest(TASKTIME)
local snap_a = {}
track.embed(snap_a)
local captured_expiry = snap_a.DoNState.replays["Best Laid Plans"]
track.ingest("'T1: Sudden Tremors [Solo] ' replay timer: 0d:1h:0m remaining.")
check(snap_a.DoNState.replays["Sudden Tremors"] == nil,
    "an embedded copy is a snapshot, not a live reference into module state")
check(snap_a.DoNState.replays["Best Laid Plans"] == captured_expiry,
    "previously embedded values are stable")

local snap_b = {}
track.embed(snap_b)
check(snap_b.DoNState.replays["Sudden Tremors"] ~= nil, "the next embed sees the new line")

-- Embedding must not disturb the categories already in the map.
local existing = { DoN = { keep = true }, Raid = { alsokeep = true } }
track.embed(existing)
check(existing.DoN.keep == true and existing.Raid.alsokeep == true,
    "embed leaves existing lockout categories untouched")

-- ------------------------------------------------------ wall vs monotonic
-- Expiries are persisted and compared across sessions, so they must use wall
-- time. A deadline computed from os.clock() would be meaningless after reload.
reset()
track.ingest(TASKTIME)
local wallcheck = {}
track.embed(wallcheck)
check(wallcheck.DoNState.replays["Best Laid Plans"] == walltime + 3 * 3600 + 44 * 60,
    "expiry is wall-clock absolute, not monotonic")

-- ------------------------------------------- the journal read and the digest
-- Accepting or completing a mission touches neither inventory nor DynamicZone,
-- so the journal read is the only thing that notices. It cannot live behind
-- embed alone: a responder that is not publishing lockouts would never run it,
-- and a mission accepted on that box would never reach the fleet. tick()
-- drives it on the TTL so it never shares a frame with DynamicZone.
reset()
local reads = 0
don.set_task_reader(function(i)
    if i == 1 then reads = reads + 1; return { id = 74, title = "T1: Best Laid Plans [Solo] ", timer_seconds = 500 } end
    return nil
end)

check(track.refresh_active_if_due() == true, "the first call reads the journal")
check(reads == 1, "once")
for _ = 1, 20 do track.refresh_active_if_due() end
check(reads == 1, "and twenty more calls inside the TTL read nothing, got " .. reads)
check(track.refresh_active_if_due(true) == true, "force bypasses the TTL")
check(reads == 2, "so a diagnostic can see a Remove that just emptied the journal")

local sig_before = track.signature()
for _ = 1, 20 do track.signature() end
check(reads == 2, "digesting the state is a plain read, never a journal scan")
check(sig_before:find("Best Laid Plans", 1, true) ~= nil, "the assignment is named in the digest")

advance(31)
check(track.refresh_active_if_due() == true, "past the TTL it reads again")
check(reads == 3, "exactly once more, got " .. reads)
check(track.signature() == sig_before, "and the same assignment digests identically 31s later")

-- Completing the mission is a change worth publishing.
don.set_task_reader(function() return nil end)
advance(31)
track.refresh_active_if_due()
check(track.signature() ~= sig_before, "the mission ending changes the digest")
don.set_task_reader(nil)

-- Idle tick drives the journal; a heartbeat that already paid for DynamicZone
-- must not also walk Task[] on the same frame.
reset()
local tick_reads = 0
don.set_task_reader(function(i)
    if i == 1 then tick_reads = tick_reads + 1; return { id = 74, title = "T1: Best Laid Plans [Solo] " } end
    return nil
end)
package.loaded.state = { bg = true }
package.loaded.engine = { Engine = { _heavy_tlo = "dz" } }
track.tick()
check(tick_reads == 0, "tick skips the journal when the heartbeat already used a heavy TLO")
package.loaded.engine = { Engine = { _heavy_tlo = nil } }
track.tick()
check(tick_reads == 1, "tick reads the journal once the heartbeat is cheap, got " .. tostring(tick_reads))
package.loaded.engine = nil
package.loaded.state = nil
don.set_task_reader(nil)

-- ------------------------------------------- tab-entry flags, not commands
reset()
local copies = 0
don.set_task_reader(function(i)
    if i == 1 then copies = copies + 1; return { id = 74, title = "T1: Best Laid Plans [Solo] ", timer_seconds = 500 } end
    return nil
end)
track.note_tab_enter()
check(#commands == 0, "tab enter does not issue /tasktime from the UI callback")
check(track.pending() == true, "tab enter is pending until tick")
local before = track.current()
check(before.capturedAt == nil and before.active["Best Laid Plans"] == nil,
    "current() is a copy and does not scan")
check(copies == 0, "current() does not walk Task[]")

track.tick()
check(#commands == 1 and commands[1] == '/tasktime', "tick issues /tasktime once")
check(copies == 1, "tick honors the forced Active read, got " .. tostring(copies))

-- A second tab enter inside the /tasktime cooldown still forces Active.
track.note_tab_enter()
track.tick()
check(#commands == 1, "tab re-entry respects /tasktime cooldown")
check(copies == 2, "but still forces one more Active read, got " .. tostring(copies))

-- current() is a snapshot, not a live alias.
local cur = track.current()
track.ingest("'T1: Sudden Tremors [Solo] ' replay timer: 0d:1h:0m remaining.")
check(cur.replays["Sudden Tremors"] == nil, "current() copy does not see later grants")
don.set_task_reader(nil)

-- ------------------------------------------- viewer vs direct tab-entry
reset()
local delegated, direct = {}, {}
local mode = track.ui_tab_enter({
    engine_ok = false,
    delegate = function(cmd) delegated[#delegated + 1] = cmd end,
    request_all = function() direct[#direct + 1] = true end,
})
check(mode == "delegated", "A: viewer Engine.ok=false delegates")
check(#delegated == 1 and delegated[1] == track.TAB_REFRESH_CMD,
    "A: one /tgearbg donrefresh, got " .. tostring(delegated[1]))
check(#direct == 0, "A: viewer does not also call request_all")
check(track.local_collector_wanted() == false, "A: viewer does not schedule local Active or /tasktime")
check(track.pending() == false, "A: viewer pending is not set by tab enter")

reset()
delegated, direct = {}, {}
mode = track.ui_tab_enter({
    engine_ok = true,
    delegate = function(cmd) delegated[#delegated + 1] = cmd end,
    request_all = function() direct[#direct + 1] = true end,
})
check(mode == "direct", "B: Engine.ok=true uses request_all")
check(#direct == 1, "B: one direct request")
check(#delegated == 0, "B: does not also delegate to /tgearbg")
check(track.local_collector_wanted() == true, "B: owner still schedules local collector flags")

-- C: ui.lua only calls on_tab_enter on tab change. This helper itself is not
-- a poller; each call is one logical refresh (leave/re-enter = one new request).
reset()
delegated = {}
track.ui_tab_enter({ engine_ok = false, delegate = function(cmd) delegated[#delegated + 1] = cmd end })
track.ui_tab_enter({ engine_ok = false, delegate = function(cmd) delegated[#delegated + 1] = cmd end })
check(#delegated == 2, "C: leave/re-enter is two requests, not coalesced inside the helper")

-- Viewer tick must not issue /tasktime or Task[] after delegated tab enter.
reset()
local viewer_copies = 0
don.set_task_reader(function()
    viewer_copies = viewer_copies + 1
    return nil
end)
track.ui_tab_enter({ engine_ok = false, delegate = function() end })
track.tick()
check(#commands == 0, "viewer tab enter does not issue /tasktime locally")
check(viewer_copies == 0, "viewer tab enter does not fire local don.refresh_active")
check(track.local_collector_wanted() == false, "viewer flags stay clear after tick")
don.set_task_reader(nil)

-- D: owner /tasktime cooldown still applies after ui_tab_enter.
reset()
track.ui_tab_enter({ engine_ok = true, request_all = function() end, delegate = function() end })
track.tick()
check(#commands == 1 and commands[1] == '/tasktime', "D: owner tab enter issues /tasktime")
track.ui_tab_enter({ engine_ok = true, request_all = function() end, delegate = function() end })
track.tick()
check(#commands == 1, "D: re-entry inside cooldown does not issue another /tasktime")

-- ------------------------------------------- replay authority while /tasktime pending
-- REQUEST publishes immediately after a forced Active scan, with /tasktime only
-- flagged. Pending C0 must not replace persisted C1 replay authority.
reset()
local prior_c1 = {
    capturedAt = walltime - 60,
    activeAt = walltime - 60,
    replays = { ["Best Laid Plans"] = walltime + 2 * 3600 + 27 * 60 },
    active = { ["Children of Gimblax"] = { id = 1, title = "stale", expires_at = walltime + 10 } },
}
track._prior_authority_for_tests = prior_c1
don.set_task_reader(function() return nil end)
track.refresh_active_if_due(true)
track.note_refresh_wanted()
check(track.captured() == false, "runtime collector is uncaptured after restart")
check(track.pending() == true, "REQUEST flags /tasktime pending")
local live = track.current()
check(live.capturedAt == nil and live.replays["Best Laid Plans"] == nil,
    "collector is not hydrated from Store")
local pub = {}
track.embed(pub)
check(pub.DoNState.capturedAt == prior_c1.capturedAt, "publish keeps captured authority")
check(pub.DoNState.replays["Best Laid Plans"] == prior_c1.replays["Best Laid Plans"],
    "persisted Best Laid Plans replay survives pending C0")
check(pub.DoNState.active["Children of Gimblax"] == nil,
    "stale persisted Active is not copied")
check(don.resolve(pub.DoNState, "Best Laid Plans", walltime) == don.STATE_REPLAY,
    "preserved replay still resolves locked")

-- Fresh Active + preserved Replay
reset()
track._prior_authority_for_tests = {
    capturedAt = walltime - 60,
    replays = { ["Sudden Tremors"] = walltime + 3600 },
    active = {},
}
don.set_task_reader(function(i)
    if i == 1 then return { id = 74, title = "T1: Best Laid Plans [Solo] ", timer_seconds = 400 } end
    return nil
end)
track.refresh_active_if_due(true)
track.note_refresh_wanted()
local mixed = {}
track.embed(mixed)
check(don.resolve(mixed.DoNState, "Best Laid Plans", walltime) == don.STATE_ACTIVE,
    "fresh Active is published immediately")
check(don.resolve(mixed.DoNState, "Sudden Tremors", walltime) == don.STATE_REPLAY,
    "pending publish keeps previous Replay")
don.set_task_reader(nil)

-- Authoritative /tasktime with no timers may clear the preserved replay.
reset()
track._prior_authority_for_tests = {
    capturedAt = walltime - 60,
    replays = { ["Best Laid Plans"] = walltime + 3600 },
    active = {},
}
track.note_refresh_wanted()
track.tick()
local pending_pub = {}
track.embed(pending_pub)
check(pending_pub.DoNState.replays["Best Laid Plans"] ~= nil, "still preserved while settling")
advance(4)
track.tick()
check(track.captured() == true, "settle stamps local capture")
local cleared = {}
track.embed(cleared)
check(cleared.DoNState.capturedAt ~= nil, "authoritative capture is published")
check(cleared.DoNState.replays["Best Laid Plans"] == nil,
    "successful empty /tasktime is allowed to clear the old replay")
check(don.resolve(cleared.DoNState, "Best Laid Plans", walltime) == don.STATE_READY,
    "absent after a completed sweep is ready, not unknown")

-- Authoritative /tasktime that returns a replay replaces/refreshes normally.
reset()
track._prior_authority_for_tests = {
    capturedAt = walltime - 60,
    replays = { ["Best Laid Plans"] = walltime + 9000 },
    active = {},
}
track.note_refresh_wanted()
track.tick()
track.ingest(TASKTIME)
local expected_exp = walltime + 3 * 3600 + 44 * 60
advance(4)
track.tick()
local refreshed = {}
track.embed(refreshed)
check(don.resolve(refreshed.DoNState, "Best Laid Plans", walltime) == don.STATE_REPLAY,
    "tasktime replay replaces the preserved row")
check(refreshed.DoNState.replays["Best Laid Plans"] == expected_exp,
    "expiry comes from the new sweep, not the old Store row")

-- No persisted replay + runtime C0 pending: stay Unknown, do not manufacture C1.
reset()
track._prior_authority_for_tests = false
track.note_refresh_wanted()
local unknown = {}
track.embed(unknown)
check(unknown.DoNState.capturedAt == nil, "no prior capture stays uncaptured")
check(unknown.DoNState.replays["Best Laid Plans"] == nil, "no replay is invented")
check(don.resolve(unknown.DoNState, "Best Laid Plans", walltime) == don.STATE_UNKNOWN,
    "no persisted replay + pending C0 remains Unknown")

track._reset_for_tests()

print(string.format('don_track: %d passed, %d failed', pass, fail))
if fail > 0 then os.exit(1) end
