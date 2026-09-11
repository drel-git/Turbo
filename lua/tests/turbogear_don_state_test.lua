-- Run from repo root: luajit lua/tests/turbogear_don_state_test.lua
-- Four-state DoN resolver. Every chat string below is verbatim from a live
-- Project Lazarus client (Phase 0 trace), including the trailing space the
-- client emits inside the quoted mission name.
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

local don = require('don_state')

local pass, fail = 0, 0
local function check(cond, msg)
    if cond then pass = pass + 1 else fail = fail + 1; print('FAIL: ' .. tostring(msg)) end
end

local NOW = 1000000

-- ---------------------------------------------------------------- parsing
local TASKTIME = "'T1: Best Laid Plans [Solo] ' replay timer: 0d:3h:44m remaining."
local GRANT = "You have received a replay timer for 'T1: Best Laid Plans [Solo] ': 0d:4h:0m remaining."

local name, secs, raw = don.parse_replay_line(TASKTIME)
check(name == "Best Laid Plans", "/tasktime line resolves to canonical row, got " .. tostring(name))
check(secs == 3 * 3600 + 44 * 60, "3h44m parses to seconds, got " .. tostring(secs))
check(raw == "T1: Best Laid Plans [Solo] ", "raw quoted name preserved incl. trailing space")

local gname, gsecs = don.parse_replay_line(GRANT)
check(gname == "Best Laid Plans", "grant message resolves to the same row, got " .. tostring(gname))
check(gsecs == 4 * 3600, "0d:4h:0m parses to 4 hours, got " .. tostring(gsecs))

local sname, ssecs = don.parse_replay_line("'T1: Sudden Tremors [Solo] ' replay timer: 0d:3h:57m remaining.")
check(sname == "Sudden Tremors", "second live line resolves, got " .. tostring(sname))
check(ssecs == 3 * 3600 + 57 * 60, "3h57m parses, got " .. tostring(ssecs))

-- Apostrophes in mission names close a lazy capture early. Volkara is the trap
-- case: a lazy match yields "Volkara", which still resolves through an alias, so
-- only Lavaspinner's Locals exposes the bug.
local aname, asecs, araw = don.parse_replay_line("'T1: Lavaspinner's Locals [Solo] ' replay timer: 0d:3h:12m remaining.")
check(aname == "Lavaspinner's Locals", "apostrophe name resolves, got " .. tostring(aname))
check(asecs == 3 * 3600 + 12 * 60, "apostrophe line duration parses, got " .. tostring(asecs))
check(araw == "T1: Lavaspinner's Locals [Solo] ", "full name captured past the apostrophe")

local vname, _, vraw = don.parse_replay_line("'Volkara's Bite [Raid Event] ' replay timer: 5d:11h:2m remaining.")
check(vname == "Volkara's Bite", "Volkara's Bite resolves, got " .. tostring(vname))
check(vraw == "Volkara's Bite [Raid Event] ", "captured the whole name, not just 'Volkara'")

local ganame = don.parse_replay_line(
    "You have received a replay timer for 'T1: Lavaspinner's Locals [Solo] ': 0d:4h:0m remaining.")
check(ganame == "Lavaspinner's Locals", "apostrophe name resolves in the grant format too")

check(don.parse_replay_line("Sketti has been removed from your shared task, 'T1: Best Laid Plans [Solo] '.") == nil,
    "task-removal chatter is not a replay line")
check(don.parse_replay_line("You say, 'hello' 1d:2h:3m remaining.") == nil,
    "quoted text naming no canonical mission is rejected")
check(don.parse_replay_line("") == nil, "empty line rejected")
check(don.parse_replay_line(nil) == nil, "nil line rejected")

-- A day component must count.
local _, dsecs = don.parse_replay_line("'Rampaging Monolith [Raid Event] ' replay timer: 5d:12h:0m remaining.")
check(dsecs == 5 * 86400 + 12 * 3600, "raid 5d12h parses, got " .. tostring(dsecs))

-- Solo and Duo share one real lockout, and the catalog models them as a single
-- row. /tasktime names only the version you ran, so both spellings must land on
-- the same key or half the fleet's lockouts would read as available.
local solo_name = don.parse_replay_line("'T1: Best Laid Plans [Solo] ' replay timer: 0d:3h:44m remaining.")
local duo_name = don.parse_replay_line("'T1: Best Laid Plans [Duo] ' replay timer: 0d:3h:44m remaining.")
local bare_name = don.parse_replay_line("'Best Laid Plans' replay timer: 0d:3h:44m remaining.")
check(solo_name == duo_name, "Solo and Duo resolve to one row: " .. tostring(solo_name) .. " / " .. tostring(duo_name))
check(bare_name == solo_name, "untagged name resolves to the same row")

local duo_state = don.new_state(NOW)
don.apply_replay_line(duo_state, "'T1: Best Laid Plans [Duo] ' replay timer: 0d:3h:44m remaining.", NOW)
check(don.resolve(duo_state, "Best Laid Plans", NOW) == don.STATE_REPLAY,
    "running the Duo version locks the shared row")

-- Same for a tier-2 progression name, which carries a different bracket tag.
local p_solo = don.parse_replay_line("'T2: Children of Gimblax [2 Group Progression] ' replay timer: 0d:11h:0m remaining.")
check(p_solo ~= nil, "bracketed progression tag normalizes, got " .. tostring(p_solo))

-- ------------------------------------------------------- unknown vs ready
local fresh = don.new_state(nil)
check(don.resolve(fresh, "Best Laid Plans", NOW) == don.STATE_UNKNOWN,
    "no capture yet -> unknown, never ready")
check(don.resolve(nil, "Best Laid Plans", NOW) == don.STATE_UNKNOWN, "nil state -> unknown")
check(don.resolve(don.new_state(NOW), "", NOW) == don.STATE_UNKNOWN, "blank row -> unknown")

local captured = don.new_state(NOW)
check(don.resolve(captured, "Best Laid Plans", NOW) == don.STATE_READY,
    "captured with no timer -> ready")

-- --------------------------------------------------------------- replay
local st = don.new_state(NOW)
don.apply_replay_line(st, TASKTIME, NOW)
local state, detail = don.resolve(st, "Best Laid Plans", NOW)
check(state == don.STATE_REPLAY, "replay timer -> replay locked")
check(detail and detail.remaining == 3 * 3600 + 44 * 60, "remaining reported from absolute expiry")
check(don.resolve(st, "Sudden Tremors", NOW) == don.STATE_READY, "other rows unaffected")

-- The point of absolute expiry: time passing needs no new reads.
check(don.resolve(st, "Best Laid Plans", NOW + 3 * 3600) == don.STATE_REPLAY, "still locked at +3h")
local later = select(1, don.resolve(st, "Best Laid Plans", NOW + 3 * 3600 + 44 * 60 + 1))
check(later == don.STATE_READY, "auto-expires with no refresh -- survives camp/relog")

-- Minute-rounded repeats must not walk the deadline backwards.
don.apply_replay_line(st, "'T1: Best Laid Plans [Solo] ' replay timer: 0d:3h:43m remaining.", NOW)
check(st.replays["Best Laid Plans"] == NOW + 3 * 3600 + 44 * 60, "shorter repeat does not shorten expiry")
don.apply_replay_line(st, GRANT, NOW)
check(st.replays["Best Laid Plans"] == NOW + 4 * 3600, "longer grant does extend expiry")

-- --------------------------------------------------------------- active
local function stub_tasks(list)
    don.set_task_reader(function(i) return list[i] end)
end

local act = don.new_state(NOW)
stub_tasks({ { id = 74, title = "T1: Best Laid Plans [Solo] ", timer_seconds = 21572 } })
check(don.refresh_active(act, NOW) == 1, "one DoN task recorded")
local astate, adetail = don.resolve(act, "Best Laid Plans", NOW)
check(astate == don.STATE_ACTIVE, "assigned task -> active")
check(adetail and adetail.id == 74, "task id carried through")
check(adetail and adetail.expires_at == NOW + 21572, "task expiry is absolute")

-- Id alone must resolve, so a server-side title reword cannot blind the matrix.
-- 74 is the catalogued solo task id for Best Laid Plans.
local byid = don.new_state(NOW)
stub_tasks({ { id = 74, title = "Renamed By The Server", timer_seconds = 60 } })
check(don.refresh_active(byid, NOW) == 1, "numeric task id resolves without a usable title")
check(don.resolve(byid, "Best Laid Plans", NOW) == don.STATE_ACTIVE, "id-matched row is active")

-- Title-only fallback, for a task whose id we do not have catalogued.
local byname = don.new_state(NOW)
stub_tasks({ { id = nil, title = "T1: Sudden Tremors [Solo] ", timer_seconds = 60 } })
check(don.refresh_active(byname, NOW) == 1, "title-only task still resolves")
check(don.resolve(byname, "Sudden Tremors", NOW) == don.STATE_ACTIVE, "resolved by normalized title")

-- Non-DoN tasks must be ignored entirely.
local mixed = don.new_state(NOW)
stub_tasks({
    { id = 9999, title = "Some Unrelated Quest", timer_seconds = 100 },
    { id = 74, title = "T1: Best Laid Plans [Solo] ", timer_seconds = 500 },
})
check(don.refresh_active(mixed, NOW) == 1, "only the DoN task is recorded")
check(don.resolve(mixed, "Best Laid Plans", NOW) == don.STATE_ACTIVE, "DoN task found past a foreign one")

-- Enumeration stops on a run of empties rather than assuming a count API.
local sparse = don.new_state(NOW)
stub_tasks({ [1] = { id = 74, title = "T1: Best Laid Plans [Solo] ", timer_seconds = 1 } })
check(don.refresh_active(sparse, NOW) == 1, "dense-from-1 list terminates cleanly")

local none = don.new_state(NOW)
stub_tasks({})
check(don.refresh_active(none, NOW) == 0, "empty journal records nothing")
check(don.resolve(none, "Best Laid Plans", NOW) == don.STATE_READY, "empty journal + capture -> ready")

-- -------------------------------- A. authoritative replacement
-- refresh_active already swapped the table; this pins that a successful empty
-- scan clears immediately rather than waiting for ACTIVE_MAX_AGE.
local held = don.new_state(NOW)
stub_tasks({ { id = 74, title = "T1: Best Laid Plans [Solo] ", timer_seconds = 500 } })
check(don.refresh_active(held, NOW) == 1, "seed Active")
check(held.active["Best Laid Plans"] ~= nil, "Active present before empty scan")
stub_tasks({})
local found_empty, status_empty = don.refresh_active(held, NOW)
check(found_empty == 0 and status_empty == "ok", "successful empty scan reports ok/0")
check(held.active["Best Laid Plans"] == nil, "successful empty scan clears Active immediately")
check(held.activeAt == NOW, "and restamps activeAt")

-- -------------------------------- B. failed scan does not mean empty
local kept = don.new_state(NOW)
stub_tasks({ { id = 74, title = "T1: Best Laid Plans [Solo] ", timer_seconds = 500 } })
don.refresh_active(kept, NOW)
local before_active, before_at = kept.active, kept.activeAt
don.set_task_reader(function() return don.TASK_UNREADABLE end)
local found_fail, status_fail = don.refresh_active(kept, NOW + 5)
check(status_fail == "unreadable", "unreadable source is reported, not treated as empty")
check(found_fail == 1, "unreadable scan returns the still-held count")
check(kept.active == before_active, "failed scan does not replace the Active table")
check(kept.active["Best Laid Plans"] ~= nil, "and does not erase the known assignment")
check(kept.activeAt == before_at, "and does not pretend it just confirmed the assignment")

-- -------------------------------- C/D. unfinished vs completed journal residue
local function obj(status, optional, current, required)
    return { status = status, optional = optional == true, current = current, required = required }
end

check(don.classify_task({
    id = 74, title = "T1: Best Laid Plans [Solo] ",
    objectives = { obj("0/1"), obj("Done"), obj("1/3") },
}) == don.PROGRESS_UNFINISHED, "any unfinished required objective is Active")

local completed_rec = {
    id = 74, title = "T1: Best Laid Plans [Solo] ",
    objectives = { obj("Done"), obj("Done"), obj("6/6"), obj("1/1"), obj("Done"), obj("Done") },
}
check(don.classify_task(completed_rec) == don.PROGRESS_COMPLETED,
    "all required Done/n-of-n is completed journal residue")

local residue = don.new_state(NOW)
stub_tasks({ completed_rec })
check(don.refresh_active(residue, NOW) == 0, "completed residue is not recorded as Active")
check(residue.active["Best Laid Plans"] == nil, "state.active has no Best Laid Plans")

-- -------------------------------- E. optional leftover does not keep it Active
local optional_left = {
    id = 74, title = "T1: Best Laid Plans [Solo] ",
    objectives = { obj("Done", false), obj("0/1", true) },
}
check(don.classify_task(optional_left) == don.PROGRESS_COMPLETED,
    "unfinished optional with required Done is residue, not Active")
local opt_state = don.new_state(NOW)
stub_tasks({ optional_left })
check(don.refresh_active(opt_state, NOW) == 0, "optional leftover is not Active")

-- -------------------------------- F. Active -> Replay while the journal entry remains
local transition = don.new_state(NOW)
stub_tasks({ {
    id = 74, title = "T1: Best Laid Plans [Solo] ", timer_seconds = 500,
    objectives = { obj("0/1"), obj("0/1") },
} })
check(don.refresh_active(transition, NOW) == 1, "scan 1: unfinished -> Active")
check(don.resolve(transition, "Best Laid Plans", NOW) == don.STATE_ACTIVE, "unfinished resolves Active")
don.apply_replay_line(transition, GRANT, NOW)
check(transition.replays["Best Laid Plans"] ~= nil, "replay grant is retained independently")
stub_tasks({ {
    id = 74, title = "T1: Best Laid Plans [Solo] ", timer_seconds = 500,
    objectives = { obj("Done"), obj("Done") },
} })
check(don.refresh_active(transition, NOW + 10) == 0, "scan 2: completed residue clears Active")
check(transition.active["Best Laid Plans"] == nil, "Active gone")
check(transition.replays["Best Laid Plans"] == NOW + 4 * 3600, "replay still held")
check(don.resolve(transition, "Best Laid Plans", NOW + 10) == don.STATE_REPLAY,
    "completed + replay resolves Replay, not Active")

-- -------------------------------- G. manual remove: empty journal, replay remains
stub_tasks({})
check(don.refresh_active(transition, NOW + 20) == 0, "scan 3: journal empty")
check(don.resolve(transition, "Best Laid Plans", NOW + 20) == don.STATE_REPLAY,
    "removed completed task still resolves Replay")

-- Unreadable objectives on a task we already held keep the previous Active
-- rather than inventing Ready; unreadable on a task we never held does not
-- invent Active.
local uncertain = don.new_state(NOW)
stub_tasks({ { id = 74, title = "T1: Best Laid Plans [Solo] ", timer_seconds = 500,
    objectives = { obj("0/1") } } })
don.refresh_active(uncertain, NOW)
stub_tasks({ { id = 74, title = "T1: Best Laid Plans [Solo] ", timer_seconds = 500,
    objectives = {}, objectives_readable = false } })
check(don.refresh_active(uncertain, NOW + 1) == 1, "unreadable objectives preserve previous Active")
check(uncertain.active["Best Laid Plans"] ~= nil, "previous Active kept")

local never_held = don.new_state(NOW)
stub_tasks({ { id = 74, title = "T1: Best Laid Plans [Solo] ",
    objectives = {}, objectives_readable = false } })
check(don.refresh_active(never_held, NOW) == 0, "unreadable objectives do not invent Active")
check(never_held.active["Best Laid Plans"] == nil, "no previous fact to keep")

-- ------------------------------------------------------------ precedence
local both = don.new_state(NOW)
stub_tasks({ { id = 74, title = "T1: Best Laid Plans [Solo] ", timer_seconds = 500 } })
don.refresh_active(both, NOW)
don.apply_replay_line(both, TASKTIME, NOW)
local bstate, bdetail = don.resolve(both, "Best Laid Plans", NOW)
check(bstate == don.STATE_ACTIVE, "active outranks replay when both are present")
check(bdetail and bdetail.replay_expires_at == NOW + 3 * 3600 + 44 * 60,
    "replay expiry still reported alongside an active task")

-- A stale peer's active task degrades; an absolute replay expiry does not.
local stale = don.new_state(NOW)
stub_tasks({ { id = 74, title = "T1: Best Laid Plans [Solo] ", timer_seconds = 500 } })
don.refresh_active(stale, NOW)
check(don.resolve(stale, "Best Laid Plans", NOW + 100, { active_max_age = 60 }) == don.STATE_UNKNOWN,
    "stale active task degrades to unknown")
check(don.resolve(stale, "Best Laid Plans", NOW + 100) == don.STATE_ACTIVE,
    "a recent assignment is trusted without the caller asking")
-- The guard has a default rather than being opt-in: this state is what a
-- persisted row looks like after a restart, and a caller who forgets shows a
-- peer running a mission they finished hours ago.
check(don.resolve(stale, "Best Laid Plans", NOW + don.ACTIVE_MAX_AGE_S + 1) == don.STATE_UNKNOWN,
    "an unconfirmed assignment degrades on its own")
don.apply_replay_line(stale, TASKTIME, NOW)
check(don.resolve(stale, "Best Laid Plans", NOW + don.ACTIVE_MAX_AGE_S + 1) == don.STATE_REPLAY,
    "stale Active with a live Replay displays Replay, not Unknown")

local stale_replay = don.new_state(NOW)
don.apply_replay_line(stale_replay, TASKTIME, NOW)
check(don.resolve(stale_replay, "Best Laid Plans", NOW + 100, { active_max_age = 60 }) == don.STATE_REPLAY,
    "replay expiry is absolute and does not go stale")

-- ---------------------------------------------------------------- prune
local pr = don.new_state(NOW)
don.apply_replay_line(pr, TASKTIME, NOW)
check(don.prune(pr, NOW, 3600) == 0, "live replay is kept")
check(don.prune(pr, NOW + 4 * 3600 + 3601, 3600) == 1, "long-expired replay is dropped")
check(pr.replays["Best Laid Plans"] == nil, "pruned entry removed")

-- ------------------------------------------------------------ signature
-- What decides whether a change is worth publishing and whether a received peer
-- row is worth writing. It must name facts, not motion; see
-- turbogear_don_propagation_test for what that buys downstream.
local sig_a = don.new_state(NOW)
don.apply_replay_line(sig_a, TASKTIME, NOW)
local sig_b = don.new_state(NOW + 600)
don.apply_replay_line(sig_b, TASKTIME, NOW)
check(don.signature(sig_a) == don.signature(sig_b),
    "a later sweep of the same replay is the same state")

check(don.signature(don.new_state(nil)) == "C0", "nothing known and nothing held is the quiet baseline")
check(don.signature(don.new_state(NOW)) ~= "C0", "a completed sweep is a state change even when empty")
check(don.signature(nil) == "", "a missing state digests to nothing rather than erroring")

local sig_c = don.new_state(NOW)
don.apply_replay_line(sig_c, "'T1: Sudden Tremors [Solo] ' replay timer: 0d:3h:44m remaining.", NOW)
check(don.signature(sig_a) ~= don.signature(sig_c), "different missions digest differently")

-- Order is not information: pairs() over a hash table is arbitrary, and an
-- order-sensitive digest would rewrite peer rows at random.
local one, two = don.new_state(NOW), don.new_state(NOW)
don.apply_replay_line(one, TASKTIME, NOW)
don.apply_replay_line(one, "'T1: Sudden Tremors [Solo] ' replay timer: 0d:1h:0m remaining.", NOW)
don.apply_replay_line(two, "'T1: Sudden Tremors [Solo] ' replay timer: 0d:1h:0m remaining.", NOW)
don.apply_replay_line(two, TASKTIME, NOW)
check(don.signature(one) == don.signature(two), "digest is order-independent")

-- H. Clearing Active is one fact change. The replay continuing to count down is not.
local sig_clear = don.new_state(NOW)
stub_tasks({ {
    id = 74, title = "T1: Best Laid Plans [Solo] ", timer_seconds = 500,
    objectives = { obj("0/1") },
} })
don.refresh_active(sig_clear, NOW)
don.apply_replay_line(sig_clear, GRANT, NOW)
local s1 = don.signature(sig_clear)
stub_tasks({ {
    id = 74, title = "T1: Best Laid Plans [Solo] ", timer_seconds = 500,
    objectives = { obj("Done") },
} })
don.refresh_active(sig_clear, NOW + 30)
local s2 = don.signature(sig_clear)
check(s1 ~= s2, "clearing Active is a semantic change")
check(s2 == don.signature(sig_clear), "the same completed+replay payload is stable")
sig_clear.capturedAt = NOW + 90
check(don.signature(sig_clear) == s2, "a later capture stamp does not re-dirty it")

don.set_task_reader(nil)

print(string.format('don_state: %d passed, %d failed', pass, fail))
if fail > 0 then os.exit(1) end
