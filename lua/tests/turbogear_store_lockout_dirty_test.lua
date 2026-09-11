-- Run from repo root: luajit lua/tests/turbogear_store_lockout_dirty_test.lua
--
-- A peer lockout change must mark the row for persistence.
--
-- The TurboGear UI process owns no actor mailbox: peer snapshots arrive at the
-- local bg responder, and the only way they reach the viewer is the bg writing
-- the row to the backing store and the viewer polling it. Store.put decides
-- whether a row is worth writing by comparing a content signature, and lockouts
-- were not in it. Observed live: Sketti gained a Howling Stones lockout, Drel's
-- bg process held the correct four-lockout row in memory, and Drel's viewer went
-- on rendering three -- because that row was never once written to disk.
--
-- Both persistence gates read this signature (the dirty-key filter, and the
-- per-key "disk already has this content" skip), so a change that it cannot see
-- is a change that never lands.
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;lua/tests/?.lua;' .. package.path

local tmpdir = require('helpers.tmpdir')

package.preload['mq'] = function()
    return {
        TLO = {
            Me = { CleanName = function() return "Drel" end },
            MacroQuest = { Server = function() return "Srv" end },
            EverQuest = { GameState = function() return "INGAME" end },
            Zone = { ShortName = function() return "z" end, Name = function() return "Zone" end },
        },
        cmd = function() end,
        pickle = function() end,
        configDir = tmpdir.dir(),
        delay = function() end,
    }
end
package.preload['config'] = function()
    return {
        CFG = { proto = 1, mailbox = "turbogear", save_content_coalesce_s = 8.0 },
        -- storeBackend=file keeps this off SQLite; nothing here writes anyway.
        Settings = { offlineSeconds = 45, staleSeconds = 20, storeBackend = "file" },
        SharedSettings = { ignoredChars = {} },
        CacheFile = tmpdir.path("turbogear_store_lockout_dirty_cache.lua"),
        LegacyCacheFile = tmpdir.path("turbogear_store_lockout_dirty_legacy.lua"),
        SaveSharedSettings = function() end,
        LoadSharedSettings = function() end,
        -- Store canonicalizes class on merge. Without these the first merge
        -- would rewrite class to "" and shift the signature for a reason that
        -- has nothing to do with what is under test.
        canonical_class = function(c) return c end,
        known_class = function(c) return c end,
    }
end
-- bg + a UI on the same box is the arrangement where peer rows are persist
-- eligible, which is exactly the Drel case.
package.preload['state'] = function()
    return {
        bg = true, show = false, engine_claim_disabled = false,
        local_guard_scripts = { main = true, bg = true },
        lean = function() return false end,
    }
end

local Store = require('store').Store

local pass, fail = 0, 0
local function check(cond, m) if cond then pass = pass + 1 else fail = fail + 1; print("  FAIL: " .. tostring(m)) end end

local KEY = "Srv_Sketti"
local BASE = 1800000000

--- The four Sketti actually held, minus whichever are dropped.
local function sketti(lockouts, extra)
    local snap = {
        name = "Sketti", server = "Srv", class = "Rog", level = 70,
        depth = "lite", updated = os.time(), seq = nil,
        equipped = {}, bags = {}, bank = {},
        lockouts = lockouts,
    }
    for k, v in pairs(extra or {}) do snap[k] = v end
    return snap
end

local function held(...)
    local map = { Custom = {}, Group = {}, OldRaids = {} }
    local at = {
        ["Nagafen's Lair [Group]"] = { cat = "Custom", exp = BASE + 84976 },
        ["Venril Sathir"] = { cat = "Group", exp = BASE + 475215 },
        ["Txevu"] = { cat = "OldRaids", exp = BASE + 35987 },
        ["Howling Stones"] = { cat = "Group", exp = BASE + 259200 },
    }
    for _, name in ipairs({ ... }) do
        local spec = at[name]
        map[spec.cat][name] = { found = true, expiresAt = spec.exp, timerText = "x" }
    end
    return map
end

local THREE = { "Nagafen's Lair [Group]", "Venril Sathir", "Txevu" }
local FOUR = { "Nagafen's Lair [Group]", "Venril Sathir", "Txevu", "Howling Stones" }

--- Store.put bumps content_version only in the branch that also marks the row
--- persist-dirty and schedules the flush, so this is the observable form of
--- "this row will be written".
local function put_and_measure(snap)
    local before = Store.content_version or 0
    Store.put(snap, "client")
    return (Store.content_version or 0) - before
end

-- ---------------------------------------------------------- the live failure
do
    put_and_measure(sketti(held(unpack(THREE))))
    -- Let the row settle first. Without this the next put would differ for
    -- reasons unrelated to lockouts and the assertion below would pass either
    -- way, which would make this test worthless.
    check(put_and_measure(sketti(held(unpack(THREE)))) == 0, "the three-lockout baseline settles")

    -- Sketti requests Howling Stones. Nothing else about her changed: same
    -- gear, same bags, same bank. Under the old signature this was invisible.
    local bumped = put_and_measure(sketti(held(unpack(FOUR))))
    check(bumped == 1, "gaining a lockout is a content change even with identical inventory")

    local change = Store.last_content_change_by_key[KEY]
    check(change and change.locked == 4, "the change record names how many lockouts the row now holds, got " ..
        tostring(change and change.locked))

    -- The other half of "will be written": a flush is now pending for it.
    check(Store.persist_busy() == true, "the row is scheduled for a flush rather than left clean")
end

-- ------------------------------------------------------------- no churn
-- The signature has to be quiet as well as correct. Peers republish on every
-- heartbeat, and a digest that moved each time would rewrite the whole fleet
-- continuously -- which is the cost we have spent months removing.
do
    check(put_and_measure(sketti(held(unpack(FOUR)))) == 0,
        "republishing the same lockouts is not a change")

    -- expiresAt is recomputed as capturedAt + remaining on every read and
    -- wobbles a second or two between publishes.
    local jittered = held(unpack(FOUR))
    jittered.Group["Howling Stones"].expiresAt = BASE + 259200 + 2
    jittered.Custom["Nagafen's Lair [Group]"].expiresAt = BASE + 84976 - 1
    check(put_and_measure(sketti(jittered)) == 0, "a second or two of jitter is absorbed")

    -- Counting down does not change absolute expiry.
    local later = held(unpack(FOUR))
    later.Group["Howling Stones"].timerText = "2D:23H"
    later.Group["Howling Stones"].remainingSeconds = 259100
    check(put_and_measure(sketti(later)) == 0, "a timer counting down is not a change")

    -- DoN state rides in the same table. It participates in the digest -- see
    -- turbogear_don_propagation_test for the detail -- but only semantically,
    -- so a repeat and an advancing capture stamp are both quiet.
    local with_don = held(unpack(FOUR))
    with_don.DoNState = { capturedAt = 123, replays = { ["Blood of the Dragon"] = BASE + 3600 } }
    check(put_and_measure(sketti(with_don)) == 1, "DoN state arriving is a change")

    local again = held(unpack(FOUR))
    again.DoNState = { capturedAt = 456, replays = { ["Blood of the Dragon"] = BASE + 3600 } }
    check(put_and_measure(sketti(again)) == 0, "the same DoN state with a newer capture stamp is not")
end

-- ------------------------------------------------------------------ expiry
do
    check(put_and_measure(sketti(held(unpack(THREE)))) == 1,
        "losing a lockout is a change, or an expired one could never clear on the viewer")
    local change = Store.last_content_change_by_key[KEY]
    check(change and change.locked == 3, "and the record reflects the smaller set")

    -- An entry present but open contributes nothing, so a sparse map and an
    -- explicit found=false map are the same state.
    local explicit_open = held(unpack(THREE))
    explicit_open.Group["Howling Stones"] = { found = false, expiresAt = 0 }
    check(put_and_measure(sketti(explicit_open)) == 0,
        "an explicitly open entry is the same state as an absent one")
end

-- -------------------------------------------------- existing contracts hold
do
    -- A snapshot that did not collect lockouts sends nil, and Store keeps what
    -- the peer last published. That must not read as "lost every lockout".
    local before_map = Store.sources[KEY].lockouts
    check(put_and_measure(sketti(nil)) == 0, "a snapshot with no lockout map is not a change")
    check(Store.sources[KEY].lockouts == before_map, "and the last published map is preserved")

    -- Inventory changes still register on their own.
    check(put_and_measure(sketti(held(unpack(THREE)), {
        equipped = { { id = 7, name = "Rod", slotid = 13, slotname = "Primary" } },
    })) == 1, "an inventory change is still a content change")

    -- Peers stay independent: one peer's lockout must not disturb another's row.
    local other = {
        name = "Discord", server = "Srv", class = "Brd", level = 70,
        depth = "lite", updated = os.time(), equipped = {}, bags = {}, bank = {},
        lockouts = held(unpack(THREE)),
    }
    Store.put(other, "client")
    local before_other = Store.last_content_change_by_key["Srv_Discord"]
    put_and_measure(sketti(held(unpack(FOUR)), {
        equipped = { { id = 7, name = "Rod", slotid = 13, slotname = "Primary" } },
    }))
    check(Store.last_content_change_by_key["Srv_Discord"] == before_other,
        "changing one peer's lockouts leaves other peer rows alone")
    check(Store.sources["Srv_Discord"].name == "Discord", "and does not disturb their row")
    check(Store.sources[KEY].name == "Sketti", "both peers survive")
end

print(string.format('store lockout dirty: %d passed, %d failed', pass, fail))
if fail > 0 then os.exit(1) end
