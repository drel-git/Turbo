-- Run from repo root: luajit lua/tests/turbogear_don_persist_test.lua
-- DoN replay state has to survive the Store round-trip, because that round-trip
-- IS the feature: absolute expiries are what let a camped or offline character
-- stay accurate. Two canonical missions have apostrophes in their names
-- ("Volkara's Bite", "Lavaspinner's Locals") and those names are used as table
-- KEYS, so a key-quoting bug would corrupt the cache rather than fail loudly.
--
-- This also pins where the state must live. store.lua assembles persisted rows
-- from an explicit field whitelist in four places (merge_lite_snapshot, the
-- shim record, slim_snapshot, and both payload assemblers). A new top-level
-- snapshot field is silently dropped by all four, so DoN state rides inside
-- snap.lockouts, which is already whitelisted.
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

package.preload['config'] = function()
    return { CFG = {}, Settings = {}, SharedSettings = {} }
end

local sqlmod = require('store_backend_sqlite')
local serialize, deserialize = sqlmod._serialize, sqlmod._deserialize
local don = require('don_state')

local pass, fail = 0, 0
local function check(cond, msg)
    if cond then pass = pass + 1 else fail = fail + 1; print("  FAIL: " .. tostring(msg)) end
end

local NOW = 1000000

-- Apostrophes arrive from chat and must survive to the persisted key untouched.
local APOSTROPHE_LINES = {
    "'Volkara's Bite [Raid Event] ' replay timer: 5d:11h:2m remaining.",
    "'T1: Lavaspinner's Locals [Solo] ' replay timer: 0d:3h:12m remaining.",
}

local state = don.new_state(NOW)
for _, line in ipairs(APOSTROPHE_LINES) do
    local name = don.apply_replay_line(state, line, NOW)
    check(name ~= nil, "apostrophe mission parses from chat: " .. line)
end
check(state.replays["Volkara's Bite"] == NOW + 5 * 86400 + 11 * 3600 + 2 * 60,
    "Volkara's Bite expiry recorded under its apostrophe key")
check(state.replays["Lavaspinner's Locals"] == NOW + 3 * 3600 + 12 * 60,
    "Lavaspinner's Locals expiry recorded under its apostrophe key")

-- Ride inside lockouts, alongside the existing DZ-derived categories.
local lockouts = {
    DoN = {},
    Raid = { ["Some Expedition"] = { timer = "2d 4h" } },
    DoNState = state,
}

local encoded = serialize(lockouts)
check(type(encoded) == "string" and #encoded > 0, "lockouts payload serializes")
check(encoded:find("Volkara", 1, true) ~= nil, "apostrophe key present in payload")

local decoded = deserialize(encoded)
check(type(decoded) == "table", "payload round-trips back to a table")
check(type(decoded.DoNState) == "table", "DoNState survives nested inside lockouts")
check(type(decoded.Raid) == "table" and decoded.Raid["Some Expedition"] ~= nil,
    "existing DZ categories are undisturbed")

local rt = decoded.DoNState
check(rt.capturedAt == NOW, "capturedAt survives -- without it every row reads unknown")
check(rt.replays["Volkara's Bite"] == state.replays["Volkara's Bite"],
    "apostrophe key and value both intact after round-trip")
check(rt.replays["Lavaspinner's Locals"] == state.replays["Lavaspinner's Locals"],
    "second apostrophe key intact")

-- Integer expiries must not come back as floats; a reserialized "1.00018e+06"
-- would drift the deadline and compare oddly.
check(math.floor(rt.replays["Volkara's Bite"]) == rt.replays["Volkara's Bite"],
    "expiry stays an exact integer")
check(encoded:find("e+", 1, true) == nil, "no float notation in the payload")

-- The invariant that actually matters: identical answers before and after.
for _, row in ipairs({ "Volkara's Bite", "Lavaspinner's Locals", "Best Laid Plans" }) do
    for _, at in ipairs({ NOW, NOW + 3600, NOW + 4 * 86400, NOW + 6 * 86400 }) do
        local a = don.resolve(state, row, at)
        local b = don.resolve(rt, row, at)
        check(a == b, string.format("%s resolves identically at +%ds (%s vs %s)",
            row, at - NOW, tostring(a), tostring(b)))
    end
end

-- A reloaded state whose timers have all expired must read ready, not unknown:
-- capturedAt is what carries that distinction across a restart.
check(don.resolve(rt, "Volkara's Bite", NOW + 6 * 86400) == don.STATE_READY,
    "expired-on-reload reads ready, proving capturedAt persisted meaningfully")

-- Active tasks are deliberately NOT persisted: an assigned task is live-only
-- truth, and a stale one would claim a mission is running when it is not.
don.set_task_reader(function(i)
    if i == 1 then return { id = 74, title = "T1: Best Laid Plans [Solo] ", timer_seconds = 500 } end
    return nil
end)
don.refresh_active(state, NOW)
check(don.resolve(state, "Best Laid Plans", NOW) == don.STATE_ACTIVE, "active recorded locally")
local rt2 = deserialize(serialize({ DoNState = { capturedAt = state.capturedAt, replays = state.replays } })).DoNState
check(don.resolve(rt2, "Best Laid Plans", NOW) == don.STATE_READY,
    "persisted shape omits active tasks, so a reload cannot report a phantom active mission")
don.set_task_reader(nil)

-- Empty state is a legal payload; a character with no lockouts still persists.
local empty_rt = deserialize(serialize({ DoNState = don.new_state(NOW) })).DoNState
check(type(empty_rt) == "table", "empty state round-trips")
check(don.resolve(empty_rt, "Best Laid Plans", NOW) == don.STATE_READY,
    "captured-but-empty reads ready after reload")

print(string.format('don persist: %d passed, %d failed', pass, fail))
if fail > 0 then os.exit(1) end
