-- Run from repo root:  luajit lua/tests/turbogear_store_test.lua
-- Tests the observable behavior of store.lua: put/merge, apply_delta recency &
-- regression guards, touch presence, counts, peer_keys filtering, ignore/forget.
-- mq/config/state are stubbed so the module loads outside MacroQuest; diagnostics
-- and snapshot_delta are the real modules.
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

-- ---- stubs ----------------------------------------------------------------
local now_time = 1000000
package.preload['mq'] = function()
    return {
        TLO = {
            Me = { CleanName = function() return "Me" end },
            MacroQuest = { Server = function() return "Srv" end },
        },
        pickle = function() end,           -- never persisted in these tests
        configDir = "/tmp",
    }
end
local shared = { ignoredChars = {} }
package.preload['config'] = function()
    return {
        CFG = {
            save_every_s = 15.0, save_every_bg_s = 1.0, save_every_minimized_s = 30.0,
            save_every_heavy_ui_s = 120.0,
        },
        Settings = { offlineSeconds = 45, staleSeconds = 20, mainTab = "bis" },
        SharedSettings = shared,
        CacheFile = "/tmp/turbogear_store_test_cache.lua",  -- never written (dirty stays false path)
        LegacyCacheFile = "/tmp/turbogear_store_test_legacy.lua",
        SaveSharedSettings = function() end,
        LoadSharedSettings = function() end,
    }
end
package.preload['state'] = function()
    return { bg = false, show = true, lean = function() return false end }
end

local store_mod = require('store')
local Store = store_mod.Store

-- ---- tiny assert harness --------------------------------------------------
local pass, fail = 0, 0
local function check(cond, msg)
    if cond then pass = pass + 1 else fail = fail + 1; print("  FAIL: " .. tostring(msg)) end
end

local function eqitem(id, name, slotname, extra)
    local it = {
        id = id, name = name,
        location = "Equipped", where = "Equipped",
        slotid = 13, slotname = slotname or "Primary",
    }
    if extra then for k, v in pairs(extra) do it[k] = v end end
    return it
end

local function snap(server, name, opts)
    opts = opts or {}
    return {
        name = name, server = server, class = opts.class or "War", level = opts.level or 70,
        depth = opts.depth or "full",
        updated = opts.updated or now_time,
        seq = opts.seq,
        inventoryUpdated = opts.inventoryUpdated,
        equipped = opts.equipped or {}, bags = opts.bags or {}, bank = opts.bank or {},
    }
end

-- ---- 1. put + counts + peer_keys + self exclusion --------------------------
Store.put(snap("Srv", "Alice", { equipped = { eqitem(101, "Sword", "Primary") } }), "client")
check(Store.get("Srv_Alice") ~= nil, "put stored Alice")
do
    local on = select(1, Store.counts())
    check(on == 1, "counts online=1 after Alice put (got " .. tostring(on) .. ")")
end
Store.put(snap("Srv", "Me", { equipped = { eqitem(1, "Self", "Primary") } }), "client")   -- self
do
    local keys = Store.peer_keys()
    local has_alice, has_self = false, false
    for _, k in ipairs(keys) do
        if k == "Srv_Alice" then has_alice = true end
        if k == "Srv_Me" then has_self = true end
    end
    check(has_alice, "peer_keys includes Alice")
    check(not has_self, "peer_keys excludes self (Me)")
end

-- ---- 2. corpse keys excluded ----------------------------------------------
Store.put(snap("Srv", "Alice`s corpse", { equipped = {} }), "client")
do
    local hidden = true
    for _, k in ipairs(Store.peer_keys()) do
        if k:lower():find("corpse", 1, true) then hidden = false end
    end
    check(hidden, "corpse source excluded from peer_keys")
end

-- ---- 3. merge: lite after full preserves full item meta --------------------
Store.put(snap("Srv", "Bob", {
    depth = "full",
    equipped = { eqitem(201, "Helm", "Head", { depth = "full", stats = { ac = 50 } }) },
}), "client")
Store.put(snap("Srv", "Bob", {
    depth = "lite",
    equipped = { eqitem(201, "Helm", "Head") },   -- lite: no stats
}), "client")
do
    local b = Store.get("Srv_Bob")
    local helm = b and b.equipped and b.equipped[1]
    check(helm and helm.stats and helm.stats.ac == 50, "lite merge preserved full stats on Helm")
end

-- ---- 4. apply_delta: no baseline -> false ----------------------------------
do
    local ok = Store.apply_delta({
        name = "Ghost", server = "Srv", inventoryUpdated = now_time + 5,
        changed = { equipped = { eqitem(301, "X", "Primary") } },
    }, "client")
    check(ok == false, "apply_delta with no baseline returns false")
end

-- ---- 5. apply_delta applies changed slot; regression guard -----------------
Store.put(snap("Srv", "Cara", {
    depth = "full", inventoryUpdated = now_time,
    equipped = { eqitem(401, "OldBlade", "Primary") },
}), "client")
do
    local ok = Store.apply_delta({
        name = "Cara", server = "Srv", updated = now_time + 10, inventoryUpdated = now_time + 10,
        changed = { equipped = { eqitem(402, "NewBlade", "Primary") } },
    }, "client")
    check(ok == true, "apply_delta with baseline returns true")
    local c = Store.get("Srv_Cara")
    local blade = c and c.equipped and c.equipped[1]
    check(blade and blade.id == 402, "apply_delta swapped item in-place (id 402)")
end
do
    local ok = Store.apply_delta({
        name = "Cara", server = "Srv", updated = now_time + 1, inventoryUpdated = now_time + 1,
        changed = { equipped = { eqitem(999, "StaleBlade", "Primary") } },
    }, "client")
    check(ok == false, "apply_delta older stamp is rejected (no regress)")
    local c = Store.get("Srv_Cara")
    check(c.equipped[1].id == 402, "rejected delta did not mutate inventory")
end

-- ---- 6. apply_delta remove ------------------------------------------------
do
    local sd = require('snapshot_delta')
    local removed_key = sd.slot_key(eqitem(402, "NewBlade", "Primary"))
    local ok = Store.apply_delta({
        name = "Cara", server = "Srv", updated = now_time + 20, inventoryUpdated = now_time + 20,
        removed = { equipped = { removed_key } },
    }, "client")
    check(ok == true, "apply_delta remove returns true")
    check(#Store.get("Srv_Cara").equipped == 0, "removed slot cleared")
end

-- ---- 7. touch (meta) keeps inventory, updates presence ---------------------
Store.put(snap("Srv", "Dan", {
    depth = "full", equipped = { eqitem(501, "Ring", "Ring1") },
}), "client")
Store.touch({ name = "Dan", server = "Srv", class = "Clr", level = 71, depth = "meta", updated = now_time + 30 }, "client")
do
    local d = Store.get("Srv_Dan")
    check(d.class == "Clr" and d.level == 71, "touch updated class/level")
    check(d.equipped and #d.equipped == 1, "touch preserved inventory")
end

-- ---- 8. ignore hides a peer -----------------------------------------------
Store.set_ignored("Alice", true)
do
    local hidden = true
    for _, k in ipairs(Store.peer_keys()) do if k == "Srv_Alice" then hidden = false end end
    check(hidden, "ignored Alice hidden from peer_keys")
    check(Store.is_ignored_name("alice"), "is_ignored_name normalizes case")
end
Store.set_ignored("Alice", false)
do
    local shown = false
    for _, k in ipairs(Store.peer_keys()) do if k == "Srv_Alice" then shown = true end end
    check(shown, "un-ignored Alice visible again")
end

-- ---- 9. aging sweep: online -> stale -> offline, and 1Hz throttle (P3) -------
do
    local real_time = os.time
    Store.put(snap("Srv", "Age", { equipped = { eqitem(601, "Band", "Ring1") } }), "client")
    Store.last_save = os.clock()      -- avoid triggering a disk save during ticks
    -- force a sweep and advance wall clock past the stale threshold
    Store.last_age_sweep = os.clock() - 1000
    os.time = function() return real_time() + 25 end
    Store.tick()
    check(Store.get("Srv_Age").status == "stale", "aging: source goes stale after staleSeconds")
    -- within the same second the throttle blocks a re-sweep, so a jump to offline
    -- range is NOT yet reflected
    os.time = function() return real_time() + 100 end
    Store.tick()
    check(Store.get("Srv_Age").status == "stale", "aging: throttled sweep does not re-evaluate within 1s")
    -- forcing the sweep (as ~1s later would) now flips it offline
    Store.last_age_sweep = os.clock() - 1000
    Store.tick()
    check(Store.get("Srv_Age").status == "offline", "aging: source goes offline after offlineSeconds")
    os.time = real_time
end

-- ---- 11. cross-box ordering prefers publisher seq over wall clock (R1) ------
do
    -- baseline: HIGH wall-clock stamp but LOW seq
    Store.put(snap("Srv", "Seq", { depth = "full", inventoryUpdated = now_time + 1000, seq = 10,
        equipped = { eqitem(701, "SeqA", "Primary") } }), "client")
    -- delta with a NEWER seq but OLDER wall clock must still apply (seq beats clock)
    local ok = Store.apply_delta({ name = "Seq", server = "Srv", updated = now_time + 1,
        inventoryUpdated = now_time + 1, seq = 11,
        changed = { equipped = { eqitem(702, "SeqB", "Primary") } } }, "client")
    check(ok == true, "delta w/ higher seq but older wall-clock applies (seq beats clock)")
    check(Store.get("Srv_Seq").equipped[1].id == 702, "seq-newer delta mutated inventory")
    check(Store.get("Srv_Seq").seq == 11, "existing seq advanced to the applied delta's seq")
    -- delta with an OLDER-or-equal seq but NEWER wall clock must be rejected
    local ok2 = Store.apply_delta({ name = "Seq", server = "Srv", updated = now_time + 9999,
        inventoryUpdated = now_time + 9999, seq = 11,
        changed = { equipped = { eqitem(703, "SeqStale", "Primary") } } }, "client")
    check(ok2 == false, "delta w/ equal seq but newer wall-clock is rejected (no regress by seq)")
    check(Store.get("Srv_Seq").equipped[1].id == 702, "rejected-by-seq delta did not mutate")
    -- when neither side has seq, the wall-clock fallback still guards regressions
    Store.put(snap("Srv", "NoSeq", { depth = "full", inventoryUpdated = now_time + 500,
        equipped = { eqitem(801, "NA", "Primary") } }), "client")
    local ok3 = Store.apply_delta({ name = "NoSeq", server = "Srv", updated = now_time + 1,
        inventoryUpdated = now_time + 1,
        changed = { equipped = { eqitem(802, "NB", "Primary") } } }, "client")
    check(ok3 == false, "no-seq delta older by wall-clock still rejected (fallback path)")
end

-- ---- 10. backend selection: falls back to the file backend here ------------
do
    local st = Store.cache_status()
    check(st.backend == "file", "store falls back to file backend when lsqlite3 absent (got " .. tostring(st.backend) .. ")")
end

-- ---- results --------------------------------------------------------------
print(string.format("store: %d passed, %d failed", pass, fail))
os.exit(fail == 0 and 0 or 1)
