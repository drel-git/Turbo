-- Run from repo root: luajit lua/tests/turbogear_lockouts_dz_tlo_test.lua
-- Lockout timers now come from the DynamicZone TLO instead of scraping the
-- Expedition Information window.
--
-- Why this matters: the window read only works while that window is populated,
-- which is never true on a background responder. Peers therefore showed an open
-- padlock for a lockout they demonstrably held. Verified live on Project
-- Lazarus that MaxTimers, ExpeditionName, EventName and Timer.TotalSeconds are
-- all readable with the window CLOSED -- the stub below is shaped from that
-- probe output, including the exact 84976 second reading.
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;lua/tests/?.lua;' .. package.path

-- add_custom persists to <configDir>/<script>_lockouts_custom.lua, so keep that
-- write out of the repo.
local tmpdir = require('helpers.tmpdir')

-- Controls what the fake client exposes.
local dz = { max_timers = 0, timers = {}, readable = true }
local window_calls = 0
-- Reading a closed window is harmless; opening one flashes it at the player.
-- The two get separate counters because a background box is allowed to do the
-- first and never the second.
local window_open_calls = 0

local function timer_obj(rec)
    return {
        ExpeditionName = function() return rec.expedition end,
        EventName = function() return rec.event end,
        EventID = function() return rec.event_id end,
        Timer = { TotalSeconds = function() return rec.seconds end },
    }
end

package.preload['mq'] = function()
    return {
        configDir = tmpdir.dir(),
        cmd = function() end,
        event = function() end,
        TLO = {
            Me = { CleanName = function() return "Drel" end },
            -- Any window access at all is a regression once the TLO answers.
            Window = function(name)
                window_calls = window_calls + 1
                if name == "DynamicZoneWnd" then window_open_calls = window_open_calls + 1 end
                return nil
            end,
            DynamicZone = {
                MaxTimers = function()
                    if not dz.readable then error("no such member") end
                    return dz.max_timers
                end,
                Timer = function(i)
                    local rec = dz.timers[i]
                    return rec and timer_obj(rec) or nil
                end,
            },
        },
    }
end
package.preload['config'] = function()
    return { CFG = { script_name = 'TurboGear' }, Settings = {}, SharedSettings = {} }
end

local lockouts = require('lockouts')

local pass, fail = 0, 0
local function check(cond, msg)
    if cond then pass = pass + 1 else fail = fail + 1; print("  FAIL: " .. tostring(msg)) end
end

local function reset(timers, readable)
    dz.timers = timers or {}
    dz.max_timers = #dz.timers
    dz.readable = readable ~= false
    window_calls, window_open_calls = 0, 0
    lockouts.invalidate_cache()
    lockouts.forget_known_lockouts()
end

-- Exactly what the live probe reported, window closed.
local NAGAFEN = {
    expedition = "Nagafen's Lair [Group]",
    event = "Replay Timer",
    event_id = -1,
    seconds = 84976,
}

-- ------------------------------------------------------ the live regression
reset({ NAGAFEN })
lockouts.add_custom({ name = "Nagafen's Lair [Group]", lockout = "Nagafen's Lair [Group]" })
local data = lockouts.gather_local(true)

local rec = data.Custom and data.Custom["Nagafen's Lair [Group]"]
check(type(rec) == "table", "custom entry resolved from the TLO")
check(rec and rec.found == true, "reported as locked")
check(rec and rec.remainingSeconds == 84976, "exact seconds preserved, got " .. tostring(rec and rec.remainingSeconds))
check(rec and rec.timerText == "23H:36M", "display text matches the tab, got " .. tostring(rec and rec.timerText))

-- The precision win: the window text "0D:23H:36M" truncates to the minute, so
-- an expiry derived from it could be up to 59s early.
check(rec and rec.expiresAt == rec.capturedAt + 84976, "expiry built from exact seconds")

check(window_calls == 0, "no window was touched, got " .. window_calls .. " accesses")

-- --------------------------------------------------- an empty TLO is trusted
reset({})
local empty = lockouts.gather_local(true)
check(type(empty) == "table", "empty gather still returns a map")
check(empty.Custom["Nagafen's Lair [Group]"].found == false, "no timer reads as open")
check(window_calls == 0,
    "a readable TLO reporting zero timers must not fall back to opening the window")

-- ------------------------------------------- unreadable TLO keeps the window
reset({}, false)
lockouts.gather_local(true)
check(window_calls > 0, "when the TLO cannot be read, the window path is still used")

-- ------------------------------------------------------------- matching
reset({ NAGAFEN })
lockouts.invalidate_cache()
local case_data = lockouts.gather_local(true)
check(case_data.Custom["Nagafen's Lair [Group]"].found == true,
    "apostrophes and brackets in the expedition name match cleanly")

-- Entries that match on the event-name column (index 3) rather than the
-- expedition name, e.g. Tacvi tracked by its boss 'Tunat'.
reset({ { expedition = "Txevu", event = "Tunat", event_id = 3, seconds = 3600 } })
lockouts.add_custom({ name = "Tacvi", lockout = "Tunat", index = 3 })
local by_event = lockouts.gather_local(true)
check(by_event.Custom["Tacvi"] and by_event.Custom["Tacvi"].found == true,
    "index=3 entries match on the event name column")

-- A key that matches nothing must not pick up an unrelated timer.
reset({ NAGAFEN })
lockouts.add_custom({ name = "Unrelated", lockout = "Some Other Expedition" })
local miss = lockouts.gather_local(true)
check(miss.Custom["Unrelated"] and miss.Custom["Unrelated"].found == false,
    "non-matching key stays open")

-- ---------------------------------------------------------------- hygiene
-- Zero and negative durations are expired, not active.
reset({ { expedition = "Nagafen's Lair [Group]", event = "Replay Timer", event_id = -1, seconds = 0 } })
local zero = lockouts.gather_local(true)
check(zero.Custom["Nagafen's Lair [Group]"].found == false, "a zero-second timer is not a lockout")

-- A timer with no names at all is skipped rather than indexed under "".
reset({ { expedition = "", event = "", event_id = -1, seconds = 500 } })
local nameless = lockouts.gather_local(true)
check(nameless.Custom["Nagafen's Lair [Group]"].found == false, "nameless timer ignored")

-- Multiple timers all land.
reset({
    NAGAFEN,
    { expedition = "Anguish", event = "Overlord Mata Muram", event_id = 1, seconds = 7200 },
})
lockouts.add_custom({ name = "Anguish (Wall of Slaughter)", lockout = "Anguish" })
local multi = lockouts.gather_local(true)
check(multi.Custom["Nagafen's Lair [Group]"].found == true, "first timer matched")
check(multi.Custom["Anguish (Wall of Slaughter)"].found == true, "second timer matched")
check(window_calls == 0, "still no window access with several timers")

-- The picker feeds the 'Pick from DZ' UI and must work window-closed too.
reset({ NAGAFEN })
local picked = lockouts.read_dz_timers()
check(#picked == 1, "picker returns the TLO rows, got " .. #picked)
check(picked[1] and picked[1].label == "Nagafen's Lair [Group]", "picker label is the expedition name")
check(picked[1] and picked[1].kind == "Replay Timer", "picker kind is the event name")
check(window_calls == 0, "picker no longer requires the window to be open")

-- ------------------------------------------ observed lockouts survive a sync
-- The original preservation read from the TTL cache, which invalidate_cache()
-- nils. set_synced_custom() calls invalidate_cache() on every incoming sync
-- request, so a Sync Now erased the timer instead of refreshing it.
reset({ NAGAFEN })
lockouts.add_custom({ name = "Nagafen's Lair [Group]", lockout = "Nagafen's Lair [Group]" })
local seen = lockouts.gather_local(true)
check(seen.Custom["Nagafen's Lair [Group]"].found == true, "timer observed once")

-- Now the timer becomes unreadable, exactly as when a gather races a sync.
dz.timers, dz.max_timers = {}, 0
lockouts.invalidate_cache()
local after_invalidate = lockouts.gather_local(true)
check(after_invalidate.Custom["Nagafen's Lair [Group]"].found == true,
    "invalidate_cache does not erase an already-observed lockout")
check(after_invalidate.Custom["Nagafen's Lair [Group]"].remainingSeconds == 84976,
    "preserved record keeps its original expiry")

-- A real sync goes through set_synced_custom, which invalidates internally.
lockouts.set_synced_custom({ { name = "Nagafen's Lair [Group]", lockout = "Nagafen's Lair [Group]" } })
local after_sync = lockouts.gather_local(true)
check(after_sync.Custom["Nagafen's Lair [Group]"].found == true,
    "a sync request no longer clears an observed lockout")

-- Repeatedly, because the symptom was intermittent.
for i = 1, 5 do
    lockouts.invalidate_cache()
    local again = lockouts.gather_local(true)
    check(again.Custom["Nagafen's Lair [Group]"].found == true,
        "still locked after invalidate cycle " .. i)
end

-- And an explicit forget really does clear it.
lockouts.forget_known_lockouts()
local forgotten = lockouts.gather_local(true)
check(forgotten.Custom["Nagafen's Lair [Group]"].found == false,
    "forget_known_lockouts drops observed records")

-- ------------------------------------------------------- change signature
-- The responder publishes when this digest moves. If it moved on its own it
-- would publish a snapshot every tick, so what it ignores matters as much as
-- what it captures.
local BASE = 1800000000   -- on a bucket boundary, so offsets below are exact
local function locked_at(expires, name)
    return { Custom = { [name or "Nagafen's Lair [Group]"] = { found = true, expiresAt = expires } } }
end

local sig_a = lockouts.signature(locked_at(BASE))
check(sig_a ~= "", "a held lockout produces a non-empty signature")
check(lockouts.signature(locked_at(BASE)) == sig_a, "same input, same signature")

-- expiresAt is capturedAt + remaining, recomputed per read, so it wobbles a
-- second or two. That must not look like a change.
check(lockouts.signature(locked_at(BASE + 3)) == sig_a, "a few seconds of jitter is absorbed")

-- A genuinely different expiry is a different lockout state.
check(lockouts.signature(locked_at(BASE + 3600)) ~= sig_a, "an hour's difference is a real change")

-- Losing it, gaining another, and open entries.
check(lockouts.signature({}) == "", "nothing locked is the empty signature")
check(lockouts.signature({ Custom = { ["X"] = { found = false, expiresAt = BASE } } }) == "",
    "an open entry contributes nothing")

local two = locked_at(BASE)
two.Custom["Anguish (Wall of Slaughter)"] = { found = true, expiresAt = BASE + 7200 }
local sig_two = lockouts.signature(two)
check(sig_two ~= sig_a, "gaining a second lockout changes the signature")

-- pairs() order is undefined, so the digest must sort.
check(lockouts.signature(two) == sig_two, "signature is stable across rebuilds")

-- DoNState rides in the same table and is state, not a lockout.
two.DoNState = { capturedAt = 123, replays = { ["Something"] = 456 } }
check(lockouts.signature(two) == sig_two, "DoNState does not leak into the signature")

-- --------------------------------------------- qualified expedition names
-- The client reports the full expedition name while the reference stores the
-- short display form. Observed live: entering Txevu produced a readable timer
-- for "Txevu, Lair of the Elite [Solo]" that matched the reference key "Txevu"
-- on nothing at all, so the row rendered open while the timer was running.
-- Built-in entries are only written when they match, so absence is "open".
-- That is why a published map holds a couple of entries rather than all 36.
local function row_locked(map, cat, name)
    local rec = map[cat] and map[cat][name]
    return type(rec) == "table" and rec.found == true, rec
end

reset({ { expedition = "Txevu, Lair of the Elite [Solo]", event = "Replay Timer",
    event_id = -1, seconds = 35987 } })
local hit, rec_txevu = row_locked(lockouts.gather_local(true), "OldRaids", "Txevu")
check(hit, "a qualified expedition name matches the short reference key")
check(rec_txevu and rec_txevu.remainingSeconds == 35987, "and keeps the exact seconds")

-- The [Group] variant of the same expedition lights the same row.
reset({ { expedition = "Txevu, Lair of the Elite [Group]", event = "Replay Timer",
    event_id = -1, seconds = 100 } })
check(row_locked(lockouts.gather_local(true), "OldRaids", "Txevu"),
    "the group variant matches the same row")

-- The boundary is what stops this being a substring match. A longer word that
-- merely starts with the key is a different expedition.
reset({ { expedition = "Txevumar Keep", event = "Replay Timer", event_id = -1, seconds = 100 } })
check(not row_locked(lockouts.gather_local(true), "OldRaids", "Txevu"),
    "a longer word starting with the key is not a match")

-- Exact matches must still win outright rather than falling into the scan.
reset({ NAGAFEN })
lockouts.add_custom({ name = "Nagafen's Lair [Group]", lockout = "Nagafen's Lair [Group]" })
check(lockouts.gather_local(true).Custom["Nagafen's Lair [Group]"].found == true,
    "an exact key still matches exactly")

-- Event-column entries get the same treatment: Tacvi is tracked by its boss.
reset({ { expedition = "Txevu, Lair of the Elite [Solo]", event = "Tunat, the Elder",
    event_id = 3, seconds = 600 } })
check(row_locked(lockouts.gather_local(true), "OldRaids", "Tacvi"),
    "a qualified event name matches its index=3 key")

-- ------------------------------------------- raw-row change detector
-- What the responder actually polls. It must never touch the window, must
-- hold steady while a timer counts down, and must report "unknown" rather
-- than "none" when the TLO cannot be read.
local T0 = 1800000000

reset({ NAGAFEN })
local raw_a = lockouts.timer_signature(T0)
check(type(raw_a) == "string" and raw_a ~= "", "a visible timer produces a raw signature")
check(window_calls == 0, "the change detector never touches the Expedition window")

-- The whole point: seconds tick down as wall time advances, and the pair
-- cancels out. This is the case that would have published every single check.
dz.timers[1] = { expedition = NAGAFEN.expedition, event = NAGAFEN.event,
    event_id = NAGAFEN.event_id, seconds = NAGAFEN.seconds - 37 }
check(lockouts.timer_signature(T0 + 37) == raw_a, "a counting-down timer is not a change")

dz.timers[1] = { expedition = NAGAFEN.expedition, event = NAGAFEN.event,
    event_id = NAGAFEN.event_id, seconds = NAGAFEN.seconds - 600 }
check(lockouts.timer_signature(T0 + 600) == raw_a, "still steady ten minutes later")

-- Gaining a second timer is a change. This is Sketti picking up Venril Sathir
-- while already locked to Nagafen's Lair.
reset({ NAGAFEN, { expedition = "Revenge on Venril Sathir", event = "Replay Timer",
    event_id = -1, seconds = 475215 } })
local raw_two = lockouts.timer_signature(T0)
check(raw_two ~= raw_a, "gaining a second lockout is detected")
check(lockouts.timer_signature(T0) == raw_two, "and is stable once seen")

-- Losing them all is a change, and reads as empty rather than unknown.
reset({})
check(lockouts.timer_signature(T0) == "", "no timers is the empty signature")

-- An unreadable TLO must not look like "no timers", or every box that lost the
-- ability to read would publish a spurious change.
reset({}, false)
check(lockouts.timer_signature(T0) == nil, "an unreadable TLO reports unknown, not none")

-- Expired rows are not lockouts.
reset({ { expedition = "Nagafen's Lair [Group]", event = "Replay Timer", event_id = -1, seconds = 0 } })
check(lockouts.timer_signature(T0) == "", "a zero-second row is ignored")

-- End to end through a real gather, which is how the responder calls it.
reset({ NAGAFEN })
lockouts.add_custom({ name = "Nagafen's Lair [Group]", lockout = "Nagafen's Lair [Group]" })
local live_sig = lockouts.signature(lockouts.gather_local(true))
check(live_sig ~= "", "a real gather produces a signature")
check(lockouts.signature(lockouts.gather_local(false)) == live_sig,
    "re-reading the cached gather gives the same signature")

-- ------------------------------------------ cache bypass vs window fallback
-- These were one flag. force=true meant both "re-read now" and "you may open
-- the Expedition window", so any path that wanted freshness on a background box
-- had to choose between a stale map and a window flashing in the player's face.
-- Sync Now took the stale map.
reset({ NAGAFEN })
lockouts.add_custom({ name = "Nagafen's Lair [Group]", lockout = "Nagafen's Lair [Group]" })
check(lockouts.gather_local(false).Custom["Nagafen's Lair [Group]"].found == true,
    "first gather populates the cache")

-- Venril arrives. A cached read cannot see it; that is the 300s window in which
-- the peer knows it is locked and every viewer is told otherwise.
dz.timers[2] = { expedition = "Revenge on Venril Sathir", event = "Replay Timer",
    event_id = -1, seconds = 475215 }
dz.max_timers = 2
lockouts.add_custom({ name = "Venril Sathir (Karnor's Castle)", lockout = "Revenge on Venril Sathir" })
lockouts.set_synced_custom({
    { name = "Nagafen's Lair [Group]", lockout = "Nagafen's Lair [Group]" },
    { name = "Venril Sathir (Karnor's Castle)", lockout = "Revenge on Venril Sathir" },
})

local bypassed = lockouts.gather_local({ bypass_cache = true, allow_window_fallback = false })
check(bypassed.Custom["Venril Sathir (Karnor's Castle)"]
    and bypassed.Custom["Venril Sathir (Karnor's Castle)"].found == true,
    "bypass_cache sees a timer that appeared after the cache was filled")
check(bypassed.Custom["Nagafen's Lair [Group]"].found == true, "and keeps the one already held")
check(window_calls == 0, "a readable TLO needs no window, bypass or not")

-- The safety half: bypassing the cache must not license opening the window.
reset({}, false)
lockouts.add_custom({ name = "Nagafen's Lair [Group]", lockout = "Nagafen's Lair [Group]" })
local silent = lockouts.gather_local({ bypass_cache = true, allow_window_fallback = false })
check(window_open_calls == 0, "an unreadable TLO with the fallback refused never opens the window")
check(type(silent) == "table", "and still returns a map")

-- A read that saw nothing must not become the authoritative answer for the
-- whole 300s TTL. It is held briefly so a persistently blind box does not pay
-- the per-entry fallback scan on every gather, and any bypassing caller -- the
-- watcher, a forced snapshot -- gets the truth the moment it returns.
dz.timers, dz.max_timers, dz.readable = { NAGAFEN }, 1, true
local recovered = lockouts.gather_local({ bypass_cache = true, allow_window_fallback = false })
check(recovered.Custom["Nagafen's Lair [Group]"].found == true,
    "a bypassing gather recovers the instant the source is readable again")

-- Known records still cover the gap while the source is down, so a refused
-- fallback reports what we last saw rather than a confident all-open map.
reset({ NAGAFEN })
lockouts.add_custom({ name = "Nagafen's Lair [Group]", lockout = "Nagafen's Lair [Group]" })
check(lockouts.gather_local(true).Custom["Nagafen's Lair [Group]"].found == true, "timer observed")
dz.readable = false
local blind = lockouts.gather_local({ bypass_cache = true, allow_window_fallback = false })
check(blind.Custom["Nagafen's Lair [Group]"].found == true,
    "a blind gather preserves the known lockout instead of publishing it open")

-- The legacy boolean keeps its old meaning for callers that still pass it.
reset({}, false)
lockouts.gather_local(true)
check(window_open_calls > 0, "gather_local(true) still allows the window fallback")

-- ------------------------------------------------- last built signature
-- What the watcher reconciles its startup baseline against: the raw state the
-- currently cached (and therefore last published) map was built from.
reset({ NAGAFEN })
lockouts.add_custom({ name = "Nagafen's Lair [Group]", lockout = "Nagafen's Lair [Group]" })
lockouts.gather_local(true)
check(lockouts.last_built_signature() == lockouts.timer_signature(),
    "after a gather, the built signature matches what the TLO reports")

dz.timers[2] = { expedition = "Txevu, Lair of the Elite [Solo]", event = "Replay Timer",
    event_id = -1, seconds = 35987 }
dz.max_timers = 2
check(lockouts.last_built_signature() ~= lockouts.timer_signature(),
    "a timer appearing after the gather leaves the two out of step -- the signal to correct")

-- Reporting on the map must not disturb that record, or running lockoutdiag
-- during startup would convince the watcher it had already published.
local before_diag = lockouts.last_built_signature()
lockouts.diagnose()
check(lockouts.last_built_signature() == before_diag,
    "diagnose reports without claiming to have published")

print(string.format('lockouts dz tlo: %d passed, %d failed', pass, fail))
if fail > 0 then os.exit(1) end
