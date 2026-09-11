-- Run from repo root: luajit lua/tests/turbogear_don_matrix_test.lua
-- Presentation-layer derivation for the promoted DoN matrix. No ImGui: cells
-- are kind + label + remaining, and Locked Only / summary counts are the same
-- helpers the tab uses.
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

local don = require('don_state')
local matrix = require('don_matrix')

local pass, fail = 0, 0
local function check(cond, msg)
    if cond then pass = pass + 1 else fail = fail + 1; print('FAIL: ' .. tostring(msg)) end
end

local NOW = 1000000
local ROW = "Best Laid Plans"
local OTHER = "Sudden Tremors"
local ROWS = { ROW, OTHER }

local function captured(now)
    return don.new_state(now or NOW)
end

local function with_active(now, expires_at)
    local st = captured(now)
    st.activeAt = now
    st.active[ROW] = { id = 74, title = "T1: Best Laid Plans [Solo] ", expires_at = expires_at }
    return st
end

local function with_replay(now, expires_at)
    local st = captured(now)
    st.replays[ROW] = expires_at
    return st
end

-- ---------------------------------------------------------------- A. Active
local active = with_active(NOW, NOW + 5 * 3600 + 42 * 60)
local cell = matrix.present(active, ROW, NOW)
check(cell.kind == matrix.KIND_ACTIVE, "A: fresh Active presents as Active")
check(cell.text == "Active 5H:42M", "A: Active label includes remaining, got " .. tostring(cell.text))
check(matrix.present(active, OTHER, NOW).kind == matrix.KIND_READY,
    "A: other captured rows stay Ready")

-- ---------------------------------------------------------------- B. Replay
local replay = with_replay(NOW, NOW + 3 * 3600 + 58 * 60)
cell = matrix.present(replay, ROW, NOW)
check(cell.kind == matrix.KIND_REPLAY, "B: valid Replay presents as Replay Locked")
check(cell.text == "3H:58M", "B: Replay label is remaining only, got " .. tostring(cell.text))

-- ---------------------------------------------------------------- C. Ready
local ready = captured(NOW)
cell = matrix.present(ready, ROW, NOW)
check(cell.kind == matrix.KIND_READY, "C: captured with neither timer is Open")
check(cell.text == "Open", "C: Ready text is Open")

-- ---------------------------------------------------------------- D. Unknown
cell = matrix.present(nil, ROW, NOW)
check(cell.kind == matrix.KIND_UNKNOWN and cell.text == "?", "D: no DoNState -> ?")
check(cell.tooltip == "Not synchronized", "D: tooltip names the gap")
cell = matrix.present(don.new_state(nil), ROW, NOW)
check(cell.kind == matrix.KIND_UNKNOWN and cell.text == "?", "D: captured=false -> ? not Open")

-- -------------------------------------------------------- E. completed residue
-- Completed journal residue is already absent from Active; Replay remains.
local residue = with_replay(NOW, NOW + 4 * 3600)
-- no active[] entry -- the classifier already dropped it
cell = matrix.present(residue, ROW, NOW)
check(cell.kind == matrix.KIND_REPLAY, "E: completed residue presents Replay, not Active")

-- ------------------------------------------------- F/G. stale Active +/- Replay
local stale = with_active(NOW, NOW + 1000)
stale.activeAt = NOW
check(matrix.present(stale, ROW, NOW + don.ACTIVE_MAX_AGE_S + 1).kind == matrix.KIND_UNKNOWN,
    "G: stale Active without Replay -> Unknown")
stale.replays[ROW] = NOW + don.ACTIVE_MAX_AGE_S + 3600
check(matrix.present(stale, ROW, NOW + don.ACTIVE_MAX_AGE_S + 1).kind == matrix.KIND_REPLAY,
    "F: stale Active + valid Replay -> Replay")

-- ----------------------------------------------------------- H. Locked Only
check(matrix.qualifies_locked_only(matrix.KIND_ACTIVE) == true, "H: Active qualifies")
check(matrix.qualifies_locked_only(matrix.KIND_REPLAY) == true, "H: Replay qualifies")
check(matrix.qualifies_locked_only(matrix.KIND_READY) == false, "H: Ready does not qualify")
check(matrix.qualifies_locked_only(matrix.KIND_UNKNOWN) == false, "H: Unknown does not qualify as locked")

check(matrix.row_qualifies_locked({ ready, active }, ROW, NOW) == true,
    "H: row kept when any displayed character is Active")
check(matrix.row_qualifies_locked({ ready, replay }, ROW, NOW) == true,
    "H: row kept when any displayed character is Replay")
check(matrix.row_qualifies_locked({ ready, captured(NOW) }, ROW, NOW) == false,
    "H: Ready-only row is hidden")
check(matrix.row_qualifies_locked({ don.new_state(nil), nil }, ROW, NOW) == false,
    "H: Unknown does not falsely become locked")
check(matrix.row_qualifies_locked({ ready }, { name = ROW }, NOW) == false,
    "H: row objects are accepted the same as names")

-- ---------------------------------------------------------- I. summary counts
-- Mixed fleet, two canonical rows:
--   Sketti: Active on ROW, Ready on OTHER
--   Drel:   Replay on ROW, Ready on OTHER
--   offline: missing snapshot
--   unsynced: present snap, uncaptured
local sketti = with_active(NOW, NOW + 100)
local drel = with_replay(NOW, NOW + 200)
local unsynced = don.new_state(nil)
local counts = matrix.count_kinds({ sketti, drel, false, unsynced }, ROWS, NOW)
check(counts.active == 1, "I: one Active cell, got " .. tostring(counts.active))
check(counts.replay == 1, "I: one Replay cell, got " .. tostring(counts.replay))
check(counts.ready == 2, "I: two Ready cells (Sketti OTHER + Drel OTHER), got " .. tostring(counts.ready))
check(counts.unknown == 2, "I: unsynced contributes two Unknown, not Open, got " .. tostring(counts.unknown))
check(counts.missing == 1, "I: missing snapshot counted once, got " .. tostring(counts.missing))
check(counts.ready + counts.unknown + counts.active + counts.replay == 6,
    "I: missing snapshot contributes no cells")

-- ------------------------------------------------------ J. countdown stability
local moving = with_active(NOW, NOW + 5 * 3600 + 42 * 60)
local sig = don.signature(moving)
local a1 = matrix.present(moving, ROW, NOW)
local a2 = matrix.present(moving, ROW, NOW + 60)
check(a1.text ~= a2.text, "J: displayed countdown changes, " .. a1.text .. " -> " .. a2.text)
check(don.signature(moving) == sig, "J: underlying signature does not change")
check(moving.active[ROW].expires_at == NOW + 5 * 3600 + 42 * 60, "J: absolute expiry is not mutated")

local r1 = matrix.present(replay, ROW, NOW)
local r2 = matrix.present(replay, ROW, NOW + 120)
check(r1.text ~= r2.text, "J: Replay remaining also moves locally")
check(replay.replays[ROW] == NOW + 3 * 3600 + 58 * 60, "J: Replay expiry is not mutated")

-- ---------------------------------------------------------- source selection
local live = with_replay(NOW, NOW + 100)
local stored = captured(NOW)
stored.replays[OTHER] = NOW + 50
local chosen, src = matrix.prefer_self_state(live, stored)
check(src == "live" and chosen == live, "self prefers live collector when it has facts")

local empty_live = don.new_state(nil)
chosen, src = matrix.prefer_self_state(empty_live, stored)
check(src == "store" and chosen == stored, "self falls back to Store when live has no facts")

-- Live older captured Ready vs Store newer Active: dual-process viewer vs bg.
local stale_live = captured(NOW)
local newer_store = with_active(NOW + 60, NOW + 60 + 1000)
newer_store.activeAt = NOW + 60
chosen, src = matrix.prefer_self_state(stale_live, newer_store)
check(src == "store" and chosen == newer_store,
    "self uses newer Store when live stamp is older")

local fresh_live = with_active(NOW + 80, NOW + 80 + 500)
fresh_live.activeAt = NOW + 80
local older_store = captured(NOW)
chosen, src = matrix.prefer_self_state(fresh_live, older_store)
check(src == "live" and chosen == fresh_live,
    "self uses live when it has a fresher Active stamp")

local live_replay = with_replay(NOW + 40, NOW + 40 + 100)
live_replay.capturedAt = NOW + 40
local old_replay_store = captured(NOW)
chosen, src = matrix.prefer_self_state(live_replay, old_replay_store)
check(src == "live" and chosen == live_replay,
    "self uses live when it has a fresher Replay stamp")

-- Equal stamps: chat grant can land in live without bumping capturedAt, so
-- live stays the tie-break rather than merging fields.
local tied_live = with_replay(NOW, NOW + 400)
local tied_store = captured(NOW)
chosen, src = matrix.prefer_self_state(tied_live, tied_store)
check(src == "live" and chosen == tied_live, "equal stamps prefer live")

-- Uncaptured live grant (stamp 0) vs captured Store: Store is the last completed
-- sweep. Picking live would drop Ready for every other row. The grant reaches
-- Store through the existing bg chat -> publish path.
local grant_only = don.new_state(nil)
grant_only.replays[ROW] = NOW + 100
local captured_store = captured(NOW)
chosen, src = matrix.prefer_self_state(grant_only, captured_store)
check(src == "store" and chosen == captured_store,
    "uncaptured live grant does not override a captured Store sweep")

local snap = { lockouts = { DoNState = stored } }
local peer, peer_src = matrix.state_for_key("Sketti_Server", snap, live)
check(peer_src == "store" and peer == stored, "peers always use snapshot DoNState")
local self_state, self_src = matrix.state_for_key("__self__", snap, live, true)
check(self_src == "live" and self_state == live, "engine owner __self__ uses live when it has facts")

-- ------------------------------------------------ viewer self is Store-only
-- Whole-state stamp comparison: uncaptured C0 with a newer activeAt beats
-- older captured Store C1. That is why Drel reverted to ? after Open.
local viewer_c0 = don.new_state(nil)
viewer_c0.activeAt = NOW + 100
local store_c1_ready = captured(NOW)
check(don.signature(viewer_c0) == "C0", "viewer live signature is C0")
check(tonumber(store_c1_ready.capturedAt) ~= nil, "Store self is captured C1")
check(matrix.has_facts(viewer_c0) == true, "TRACE: live activeAt counts as facts")
check(matrix.authority_stamp(viewer_c0) > matrix.authority_stamp(store_c1_ready),
    "TRACE: live activeAt is newer than Store capturedAt")
local stamp_pick, stamp_src = matrix.prefer_self_state(viewer_c0, store_c1_ready)
check(stamp_src == "live" and stamp_pick == viewer_c0,
    "TRACE: freshness comparison chooses live C0 over Store C1")
check(matrix.present(stamp_pick, ROW, NOW).kind == matrix.KIND_UNKNOWN,
    "TRACE: that C0 blob presents as ? not Open")

local viewer_snap = { lockouts = { DoNState = store_c1_ready } }
local v_state, v_src = matrix.state_for_key("__self__", viewer_snap, viewer_c0, false)
check(v_src == "store" and v_state == store_c1_ready,
    "viewer Engine.ok=false: self source is Store")
check(matrix.present(v_state, ROW, NOW).kind == matrix.KIND_READY,
    "viewer Engine.ok=false: Store C1 replay=0 presents Ready")

local store_c1_replay = with_replay(NOW, NOW + 1000)
local replay_snap = { lockouts = { DoNState = store_c1_replay } }
v_state, v_src = matrix.state_for_key("__self__", replay_snap, viewer_c0, false)
check(v_src == "store" and v_state == store_c1_replay,
    "viewer C0 newer Active stamp does not hide Store Replay")
check(matrix.present(v_state, ROW, NOW).kind == matrix.KIND_REPLAY,
    "viewer self state is Replay from Store")

local viewer_c1 = captured(NOW + 200)
v_state, v_src = matrix.state_for_key("__self__", replay_snap, viewer_c1, false)
check(v_src == "store" and v_state == store_c1_replay,
    "viewer local C1 differs from Store: Store remains authority")

local owner_state, owner_src = matrix.state_for_key("__self__", viewer_snap, viewer_c0, true)
check(owner_src == "live" and owner_state == viewer_c0,
    "Engine.ok=true: live self authority is still supported")

local viewer_peer, viewer_peer_src = matrix.state_for_key("Sketti_Server", replay_snap, viewer_c0, false)
check(viewer_peer_src == "store" and viewer_peer == store_c1_replay,
    "viewer peers remain Store-only")
local owner_peer, owner_peer_src = matrix.state_for_key("Sketti_Server", snap, live, true)
check(owner_peer_src == "store" and owner_peer == stored,
    "engine-owner peers remain Store-only")

check(matrix.state_from_snap({ lockouts = {} }) == nil, "snap without DoNState is nil")
check(matrix.state_from_snap(nil) == nil, "nil snap is nil")
check(matrix.has_facts(empty_live) == false, "uncaptured empty has no facts")
check(matrix.has_facts(live) == true, "replay fact counts as authority")

-- Compact Active drops the prefix so the 74px column still fits.
check(matrix.present(active, ROW, NOW, { compact = true }).text == "5H:42M",
    "compact Active is remaining only")

print(string.format('don_matrix: %d passed, %d failed', pass, fail))
if fail > 0 then os.exit(1) end
