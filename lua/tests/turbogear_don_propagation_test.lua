-- Run from repo root: luajit lua/tests/turbogear_don_propagation_test.lua
--
-- DoN state has to cross the same bg -> Store -> viewer boundary that normal
-- expedition lockouts do, and it inherited the same defect: the receiving
-- process updated memory while the row it must write stayed clean, so the
-- viewer -- which owns no mailbox and learns everything by polling the backing
-- store -- never found out. Howling Stones proved that for expedition timers;
-- this pins it for DoN before the matrix is switched to the new resolver.
--
-- The other half is churn. A replay timer counts down for days and a peer
-- republishes constantly, so the digest must name facts (which mission, what
-- absolute deadline) and never motion (remaining seconds, capture stamps).
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;lua/tests/?.lua;' .. package.path

local tmpdir = require('helpers.tmpdir')

local function ser(v, out)
    local t = type(v)
    if t == "number" or t == "boolean" then out[#out + 1] = tostring(v)
    elseif t == "string" then out[#out + 1] = string.format("%q", v)
    elseif t == "table" then
        out[#out + 1] = "{"
        for k, val in pairs(v) do
            if type(k) == "number" then out[#out + 1] = "[" .. k .. "]="
            else out[#out + 1] = "[" .. string.format("%q", tostring(k)) .. "]=" end
            ser(val, out)
            out[#out + 1] = ","
        end
        out[#out + 1] = "}"
    else out[#out + 1] = "nil" end
end

package.preload['mq'] = function()
    return {
        TLO = {
            Me = { CleanName = function() return "Drel" end },
            MacroQuest = { Server = function() return "Srv" end },
            EverQuest = { GameState = function() return "INGAME" end },
            Zone = { ShortName = function() return "z" end, Name = function() return "Zone" end },
        },
        cmd = function() end,
        pickle = function(path, tbl)
            local o = { "return " }
            ser(tbl, o)
            local f = assert(io.open(path, "w"))
            f:write(table.concat(o))
            f:close()
        end,
        configDir = tmpdir.dir(),
        delay = function() end,
    }
end
package.preload['config'] = function()
    return {
        CFG = { proto = 1, mailbox = "turbogear", save_content_coalesce_s = 8.0 },
        Settings = { offlineSeconds = 45, staleSeconds = 20, storeBackend = "file" },
        SharedSettings = { ignoredChars = {} },
        CacheFile = tmpdir.path("turbogear_don_prop_cache.lua"),
        LegacyCacheFile = tmpdir.path("turbogear_don_prop_legacy.lua"),
        SaveSharedSettings = function() end,
        LoadSharedSettings = function() end,
        canonical_class = function(c) return c end,
        known_class = function(c) return c end,
    }
end
package.preload['state'] = function()
    return {
        bg = true, show = false, engine_claim_disabled = false,
        local_guard_scripts = { main = true, bg = true },
        lean = function() return false end,
    }
end

local Store = require('store').Store
local don = require('don_state')

local pass, fail = 0, 0
local function check(cond, m) if cond then pass = pass + 1 else fail = fail + 1; print("  FAIL: " .. tostring(m)) end end

local KEY = "Srv_Sketti"
local NOW = 1800000000
local HOUR = 3600

-- Expiries are quantized to absorb the wobble of being recomputed as
-- now + remaining on every read. Quantizing has boundaries, so a wobble that
-- straddles one costs a single extra write; these sit mid-bucket so the tests
-- below assert the mechanism rather than the arithmetic of where NOW landed.
local REPLAY_AT = NOW + 4 * HOUR + 30
local ACTIVE_AT = NOW + 5400 + 30

local function sketti(don_state_tbl, lockouts)
    local map = lockouts or { Group = { ["Howling Stones"] = { found = true, expiresAt = NOW + 259200 } } }
    map.DoNState = don_state_tbl
    return {
        name = "Sketti", server = "Srv", class = "Rog", level = 70,
        depth = "lite", updated = os.time(),
        equipped = {}, bags = {}, bank = {},
        lockouts = map,
    }
end

--- content_version moves only in the branch that also marks the row dirty and
--- schedules the flush, so this is the observable form of "this will be written
--- and the viewer will therefore see it".
local function put_and_measure(snap)
    local before = Store.content_version or 0
    Store.put(snap, "client")
    return (Store.content_version or 0) - before
end

local function state_with(opts)
    opts = opts or {}
    return {
        capturedAt = opts.capturedAt,
        activeAt = opts.activeAt,
        replays = opts.replays or {},
        active = opts.active or {},
    }
end

-- ------------------------------------------------------------ I. DoN-only dirtying
-- Inventory byte-identical, expedition lockouts identical, only DoN moves.
do
    local base = state_with({ capturedAt = NOW, activeAt = NOW })
    put_and_measure(sketti(base))
    check(put_and_measure(sketti(state_with({ capturedAt = NOW + 5, activeAt = NOW + 5 }))) == 0,
        "the row settles: a repeated sweep of the same empty state is not a change")

    -- Sketti completes a mission and is granted a replay timer.
    local replayed = state_with({
        capturedAt = NOW + 60, activeAt = NOW + 60,
        replays = { ["Blood of the Dragon"] = REPLAY_AT },
    })
    check(put_and_measure(sketti(replayed)) == 1,
        "a replay grant dirties the peer row with no inventory change at all")

    -- And a mission being accepted.
    local active = state_with({
        capturedAt = NOW + 120, activeAt = NOW + 120,
        replays = { ["Blood of the Dragon"] = REPLAY_AT },
        active = { ["Best Laid Plans"] = { id = 74, title = "T1: Best Laid Plans [Solo] ", expires_at = ACTIVE_AT } },
    })
    check(put_and_measure(sketti(active)) == 1, "accepting a mission dirties the row")

    local locked_now = Store.last_content_change_by_key[KEY]
    check(locked_now ~= nil, "the change is recorded against this peer's key")
end

-- ------------------------------------------------------------ J. countdown no-churn
do
    -- Same facts, later sweep, both timers nearer their deadline. Peers
    -- republish constantly; if any of this registered, every peer row would be
    -- rewritten continuously for the days a replay timer runs.
    local ticked = state_with({
        capturedAt = NOW + 900, activeAt = NOW + 900,
        replays = { ["Blood of the Dragon"] = REPLAY_AT },
        active = { ["Best Laid Plans"] = { id = 74, title = "T1: Best Laid Plans [Solo] ", expires_at = ACTIVE_AT } },
    })
    check(put_and_measure(sketti(ticked)) == 0, "a quarter hour of countdown is not a change")

    -- Absolute expiries are recomputed as now + remaining on every read and
    -- wobble a second or two between them.
    local jittered = state_with({
        capturedAt = NOW + 960, activeAt = NOW + 960,
        replays = { ["Blood of the Dragon"] = REPLAY_AT + 2 },
        active = { ["Best Laid Plans"] = { id = 74, title = "T1: Best Laid Plans [Solo] ", expires_at = ACTIVE_AT - 1 } },
    })
    check(put_and_measure(sketti(jittered)) == 0, "a second of expiry jitter is absorbed")

    -- The title text is display, not identity: Solo and Duo are one row.
    local retitled = state_with({
        capturedAt = NOW + 1000, activeAt = NOW + 1000,
        replays = { ["Blood of the Dragon"] = REPLAY_AT },
        active = { ["Best Laid Plans"] = { id = 74, title = "T1: Best Laid Plans [Duo]", expires_at = ACTIVE_AT } },
    })
    check(put_and_measure(sketti(retitled)) == 0, "the raw task title is not part of the identity")
end

-- ------------------------------------------------------------ K. expiry
do
    -- A replay deadline is absolute, so every consumer flips the row to ready
    -- on its own clock. No publish, no write, no traffic.
    local held = state_with({
        capturedAt = NOW, activeAt = NOW,
        replays = { ["Blood of the Dragon"] = NOW + HOUR },
    })
    check(don.resolve(held, "Blood of the Dragon", NOW) == don.STATE_REPLAY, "locked before the deadline")
    check(don.resolve(held, "Blood of the Dragon", NOW + HOUR + 1) == don.STATE_READY,
        "and ready after it, from the same unchanged payload")
    check(don.signature(held) == don.signature(held), "which is why expiry alone moves no signature")

    -- Losing the mission outright -- completing it, or a sweep no longer
    -- listing it -- is a real change and does need to go out.
    local before = don.signature(held)
    local cleared = state_with({ capturedAt = NOW + HOUR, activeAt = NOW + HOUR })
    check(don.signature(cleared) ~= before, "a replay dropping out of the sweep is a change")
end

-- ------------------------------------------------------------ L. peer isolation
do
    local discord = {
        name = "Discord", server = "Srv", class = "Brd", level = 70,
        depth = "lite", updated = os.time(), equipped = {}, bags = {}, bank = {},
        lockouts = { DoNState = state_with({ capturedAt = NOW, activeAt = NOW }) },
    }
    Store.put(discord, "client")
    local before_other = Store.last_content_change_by_key["Srv_Discord"]

    put_and_measure(sketti(state_with({
        capturedAt = NOW + 2000, activeAt = NOW + 2000,
        replays = { ["Volkara's Bite"] = NOW + 5 * 86400 },
    })))
    check(Store.last_content_change_by_key["Srv_Discord"] == before_other,
        "one peer's DoN change leaves other peer rows alone")
    check(Store.sources["Srv_Discord"].name == "Discord", "and does not disturb their row")
end

-- ------------------------------------------------- authority: unknown -> ready
do
    -- The transition that carries no lockouts at all still has to reach the
    -- viewer, or a peer stays "?" forever after its sweep completes.
    local unknown = state_with({})
    local ready = state_with({ capturedAt = NOW, activeAt = NOW })
    check(don.resolve(unknown, "Best Laid Plans", NOW) == don.STATE_UNKNOWN, "never swept reads unknown")
    check(don.resolve(ready, "Best Laid Plans", NOW) == don.STATE_READY, "a completed sweep reads ready")
    check(don.signature(unknown) ~= don.signature(ready),
        "so unknown -> ready is a change even though nothing is locked")
    check(don.signature(unknown) == "C0", "the nothing-known digest is the quiet baseline the watcher expects")
end

-- ------------------------------------------------- G. active restart safety
do
    -- Active is live-only truth. A persisted row carries the assignment so the
    -- fleet matrix can show it, which means a reload must not believe it.
    local persisted = state_with({
        capturedAt = NOW, activeAt = NOW,
        active = { ["Best Laid Plans"] = { id = 74, title = "T1: Best Laid Plans [Solo] ", expires_at = ACTIVE_AT } },
    })
    check(don.resolve(persisted, "Best Laid Plans", NOW) == don.STATE_ACTIVE, "fresh assignment is active")

    local stale_at = NOW + don.ACTIVE_MAX_AGE_S + 1
    local resolved, info = don.resolve(persisted, "Best Laid Plans", stale_at)
    check(resolved == don.STATE_UNKNOWN, "an unconfirmed assignment degrades to unknown, not a phantom active")
    check(info and info.reason == "stale-active", "and says why")

    -- The guard has to hold without the caller asking for it: the cost of
    -- forgetting is a peer shown running a mission they finished hours ago.
    check(don.resolve(persisted, "Best Laid Plans", stale_at, {}) == don.STATE_UNKNOWN,
        "the default applies with empty opts")
    check(don.resolve(persisted, "Best Laid Plans", stale_at, { active_max_age = 60 }) == don.STATE_UNKNOWN,
        "a narrower explicit age still degrades it")

    -- H. Replay is the opposite: absolute, and survives any gap.
    local replay = state_with({ capturedAt = NOW, replays = { ["Volkara's Bite"] = NOW + 5 * 86400 } })
    check(don.resolve(replay, "Volkara's Bite", NOW + 4 * 86400) == don.STATE_REPLAY,
        "a persisted replay is still valid four days later with no refresh at all")
end

-- ------------------------------------------------- D. active and replay together
do
    local both = state_with({
        capturedAt = NOW, activeAt = NOW,
        replays = { ["Best Laid Plans"] = NOW + 3 * HOUR },
        active = { ["Best Laid Plans"] = { id = 74, title = "T1: Best Laid Plans [Solo] ", expires_at = ACTIVE_AT } },
    })
    local resolved, info = don.resolve(both, "Best Laid Plans", NOW)
    check(resolved == don.STATE_ACTIVE, "active takes display precedence")
    check(info and info.replay_expires_at == NOW + 3 * HOUR,
        "and the replay deadline is retained rather than discarded")

    -- Completed residue: Active gone, replay kept. One Store dirty.
    local completed = state_with({
        capturedAt = NOW + 60, activeAt = NOW + 60,
        replays = { ["Best Laid Plans"] = NOW + 3 * HOUR },
    })
    check(put_and_measure(sketti(completed)) == 1, "Active -> Replay dirties the peer row once")
    check(don.resolve(completed, "Best Laid Plans", NOW + 60) == don.STATE_REPLAY,
        "and the stored payload resolves Replay")
end

-- ------------------------------------------ H. stale Active + live Replay
do
    local stale_both = state_with({
        capturedAt = NOW, activeAt = NOW,
        replays = { ["Sudden Tremors"] = NOW + 4 * HOUR },
        active = { ["Sudden Tremors"] = { id = 204, title = "T1: Sudden Tremors [Solo] ", expires_at = ACTIVE_AT } },
    })
    local stale_at = NOW + don.ACTIVE_MAX_AGE_S + 1
    check(don.resolve(stale_both, "Sudden Tremors", stale_at) == don.STATE_REPLAY,
        "a stale Active assignment degrades; live Replay remains the display state")
end

-- ------------------------------------------ B. viewer reload from persisted DoN
-- Models Drel bg persisting Sketti's DoN-only change, then Drel viewer still
-- holding the previous row in memory and picking up the disk write.
do
    -- Prior runs leave this pickle on disk. File-backend save merges by seq, so
    -- a leftover seq=2 row would beat a fresh seq=1 put and hide the DoN change.
    pcall(os.remove, require('config').CacheFile)
    pcall(os.remove, require('config').LegacyCacheFile)

    local v1 = sketti(state_with({ capturedAt = NOW, activeAt = NOW }))
    v1.seq = 100
    put_and_measure(v1)

    local held = Store.sources[KEY]
    local held_ds = held.lockouts.DoNState
    local viewer_row = {
        name = held.name, server = held.server, class = held.class,
        level = held.level, depth = held.depth, seq = held.seq,
        updated = held.updated, equipped = held.equipped,
        bags = held.bags, bank = held.bank,
        lockouts = {
            Group = held.lockouts.Group,
            DoNState = {
                capturedAt = held_ds.capturedAt,
                activeAt = held_ds.activeAt,
                replays = {},
                active = {},
            },
        },
    }
    local viewer_sig = Store.content_signatures[KEY]

    local v2 = sketti(state_with({
        capturedAt = NOW, activeAt = NOW,
        replays = { ["Sudden Tremors"] = REPLAY_AT },
    }))
    v2.seq = 200
    check(put_and_measure(v2) == 1, "bg Store.put dirties Sketti for a DoN-only replay")
    check(Store.persist_busy() == true, "the peer row is scheduled for a flush")
    Store.save()

    -- Viewer has not reloaded yet.
    Store.sources[KEY] = viewer_row
    Store.content_signatures[KEY] = viewer_sig

    local changed = Store.reload_cache_if_changed(true)
    check(changed == true, "viewer reload accepts the newer seq with new DoNState")
    local ds = Store.sources[KEY] and Store.sources[KEY].lockouts and Store.sources[KEY].lockouts.DoNState
    check(ds and ds.replays and ds.replays["Sudden Tremors"] == REPLAY_AT,
        "viewer Store now holds Sketti's Sudden Tremors replay")
    local change = Store.last_content_change_by_key[KEY]
    check(change and change.source == "cache-newer",
        "the reload is recorded as cache-newer, got " .. tostring(change and change.source))
    check(change and change.don == 1, "and names the DoN fact count")
end

print(string.format('don propagation: %d passed, %d failed', pass, fail))
if fail > 0 then os.exit(1) end
