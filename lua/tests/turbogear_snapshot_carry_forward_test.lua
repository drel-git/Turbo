-- Run from repo root: luajit lua/tests/turbogear_snapshot_carry_forward_test.lua
--
-- A gather told to skip live stats must not publish them as absent, and a
-- gather told to skip lockouts must NOT invent a value for them.
--
-- The asymmetry is the point. Store resolves `snap.lockouts or
-- existing.lockouts`, so a nil lockout map already means "not collected" and
-- preserves what the peer last published. Carrying the cached map forward
-- instead republishes it as freshly read; when that cached map predates the
-- lockout, every peer column briefly showed an open padlock -- which claims
-- "not locked" on the strength of data nobody read. Observed in game as a
-- fleet-wide flicker to green padlocks on every Sync Now.
--
-- liveStats has no such fallback and is read straight off the snapshot, so it
-- does need carrying or Inspect > Effects blanks on the next tab visit.
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;lua/tests/?.lua;' .. package.path

local tmpdir = require('helpers.tmpdir')

package.preload['mq'] = function()
    return {
        configDir = tmpdir.dir(),
        cmd = function() end,
        delay = function() end,
        event = function() end,
        TLO = {
            Me = { CleanName = function() return "Drel" end },
            MacroQuest = { Server = function() return "Srv" end },
            EverQuest = { GameState = function() return "INGAME" end },
            Zone = { ShortName = function() return "z" end, Name = function() return "Zone" end },
        },
    }
end
package.preload['config'] = function()
    return { CFG = { script_name = 'TurboGear' }, Settings = {}, SharedSettings = {} }
end

local snapshot = require('snapshot')
local carry = snapshot._carry_forward_skipped
assert(type(carry) == "function", "snapshot exposes the carry-forward seam")

local pass, fail = 0, 0
local function check(cond, msg)
    if cond then pass = pass + 1 else fail = fail + 1; print("  FAIL: " .. tostring(msg)) end
end

local LOCKED = { Custom = { ["Nagafen's Lair [Group]"] = { found = true, expiresAt = 99999999 } } }

-- ------------------------------------------------------------ the live bug
do
    local snap = { name = "Drel" }
    carry(snap, { lockouts = LOCKED }, { skipLockouts = true })
    check(snap.lockouts == nil,
        "a skipLockouts gather leaves lockouts nil so Store keeps the last published map")
end

-- A gather that really did read lockouts keeps its own answer, including a
-- legitimate all-open result -- otherwise an expired lockout could never clear.
do
    local fresh = { Custom = { ["Nagafen's Lair [Group]"] = { found = false } } }
    local snap = { lockouts = fresh }
    carry(snap, { lockouts = LOCKED }, { skipLockouts = true })
    check(snap.lockouts == fresh, "a real lockout read is never overwritten")
end

do
    local snap = { name = "Drel" }
    carry(snap, { lockouts = LOCKED }, {})
    check(snap.lockouts == nil, "nothing to carry when the gather was not asked to skip")
end

-- ------------------------------------------------------- the live-stats case
do
    local stats = { hp = 1 }
    local snap = {}
    carry(snap, { liveStats = stats }, { skipLiveStats = true })
    check(snap.liveStats == stats, "skipLiveStats inherits cached live stats")

    local own = { hp = 2 }
    local snap2 = { liveStats = own }
    carry(snap2, { liveStats = stats }, { skipLiveStats = true })
    check(snap2.liveStats == own, "a real live-stats read wins")
end

-- Both flags at once, which is what inventory_watch actually sends.
do
    local snap = {}
    carry(snap, { lockouts = LOCKED, liveStats = { hp = 1 } },
        { skipLockouts = true, skipLiveStats = true })
    check(type(snap.liveStats) == "table", "live stats carried")
    check(snap.lockouts == nil, "lockouts still left for Store to resolve")
end

-- ---------------------------------------------------------------- robustness
do
    local snap = { name = "Drel" }
    check(carry(snap, nil, { skipLiveStats = true }) == snap, "no cache is survivable")
    check(carry(snap, {}, { skipLiveStats = true }) == snap, "empty cache is survivable")
    check(carry(nil, {}, {}) == nil, "nil snap is survivable")
    check(carry(snap, { liveStats = "not a table" }, { skipLiveStats = true }).liveStats == nil,
        "a non-table cached value is ignored rather than copied")
end

-- ------------------------------------------------- how a snapshot asks for lockouts
-- Sync Now reaches the responder as a forced request, which forces the
-- inventory walk. The lockout read was hardcoded to gather_local(false), so a
-- forced snapshot shipped fresh inventory beside a lockout map up to five
-- minutes old. That is the whole "Sketti knows before Drel does" delay.
local gather_opts = snapshot._lockout_gather_opts
assert(type(gather_opts) == "function", "snapshot exposes the lockout-options seam")

do
    local forced = gather_opts({ force = true })
    check(forced.bypass_cache == true, "a forced snapshot re-reads lockouts instead of using the cache")

    local peer_req = gather_opts({ force = true, skipLockoutBypass = true })
    check(peer_req.bypass_cache == false,
        "peer REQUEST must not re-read DynamicZone on the same tick as inventory")

    local ordinary = gather_opts({ force = false })
    check(ordinary.bypass_cache == false,
        "an ordinary snapshot still uses the cache -- the routine path stays cheap")
    check(gather_opts({}).bypass_cache == false, "absent force is not forced")

    -- Bypassing the cache must never buy permission to open the Expedition
    -- window. Snapshots are gathered on background boxes.
    check(forced.allow_window_fallback == false and ordinary.allow_window_fallback == false,
        "no snapshot gather may flash the Expedition window")
    check(peer_req.allow_window_fallback == false, "peer REQUEST also never opens the Expedition window")
end

-- adopt(lite) must supersede a stale full when inventory stamp is newer or equal.
-- Recovery probe relies on this instead of snapshot.invalidate().
do
    snapshot.invalidate()
    local full = {
        name = "Drel",
        depth = "full",
        updated = 100,
        inventoryUpdated = 100,
        equipped = { { id = 1, name = "Old" } },
        bags = {},
        bank = { { id = 9, name = "Banked" } },
        bankValid = true,
        bankLive = false,
        bankPreserved = true,
        bankCapturedAt = 50,
    }
    check(snapshot.adopt(full) == true, "adopt full")
    check(snapshot.cached() == full, "cached prefers full")
    local lite = {
        name = "Drel",
        depth = "lite",
        updated = 101,
        inventoryUpdated = 101,
        equipped = { { id = 2, name = "New" } },
        bags = {},
        bank = full.bank,
        bankValid = true,
        bankLive = false,
        bankPreserved = true,
        bankCapturedAt = 50,
    }
    check(snapshot.adopt(lite) == true, "adopt newer lite")
    check(snapshot.cached() == lite, "newer lite supersedes stale full")
    check(snapshot.cached().depth == "lite", "cached depth is lite after adopt")
    check(snapshot.cached().bankCapturedAt == 50, "adopt does not rewrite bankCapturedAt")
end

do
    snapshot.invalidate()
    local full = {
        name = "Drel",
        depth = "full",
        updated = 200,
        inventoryUpdated = 200,
        equipped = { { id = 1 } },
        bags = {},
        bank = {},
    }
    snapshot.adopt(full)
    local lite_same = {
        name = "Drel",
        depth = "lite",
        updated = 200,
        inventoryUpdated = 200,
        equipped = { { id = 2 } },
        bags = {},
        bank = {},
    }
    snapshot.adopt(lite_same)
    check(snapshot.cached() == lite_same, "equal inventory stamp still supersedes full (>=)")
end

do
    snapshot.invalidate()
    local full = {
        name = "Drel",
        depth = "full",
        updated = 300,
        inventoryUpdated = 300,
        equipped = { { id = 1 } },
        bags = {},
        bank = {},
    }
    snapshot.adopt(full)
    local older_lite = {
        name = "Drel",
        depth = "lite",
        updated = 299,
        inventoryUpdated = 299,
        equipped = { { id = 2 } },
        bags = {},
        bank = {},
    }
    snapshot.adopt(older_lite)
    check(snapshot.cached() == full, "older lite does not evict newer full")
end

print(string.format('snapshot carry-forward: %d passed, %d failed', pass, fail))
if fail > 0 then os.exit(1) end
