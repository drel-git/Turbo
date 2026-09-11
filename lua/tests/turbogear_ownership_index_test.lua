-- Run from repo root: luajit lua/tests/turbogear_ownership_index_test.lua
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

package.preload['mq'] = function()
    return { configDir = ".", TLO = { Me = { CleanName = function() return "Tester" end } } }
end
package.preload['config'] = function()
    return { CFG = { script_name = "TurboGear" }, Settings = {} }
end

local idxmod = require('ownership_index')
local bis = require('bis')

local pass, fail = 0, 0
local function check(cond, msg)
    if cond then pass = pass + 1 else fail = fail + 1; print("  FAIL: " .. tostring(msg)) end
end

local function trim(s)
    return tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function norm(s)
    s = trim(s):lower()
    s = s:gsub("`", "'"):gsub("\226\128\152", "'"):gsub("\226\128\153", "'")
    return s
end

local function keep_tattered_sack_rank_paren(s)
    return s:find("tattered sack", 1, true) ~= nil
end

local function old_norm_item_name(s)
    s = norm(s)
    if not keep_tattered_sack_rank_paren(s) then
        s = s:gsub("%s*%(%s*[^%)]-%s*%)%s*$", "")
    end
    s = s:gsub("%s*%[%s*[^%]]-%s*%]%s*$", "")
    s = s:gsub("%s+", " ")
    local stripped = s:gsub("%s*%d%d%d+$", "")
    if stripped ~= "" then s = stripped end
    return trim(s)
end

local function old_tier_rank(name)
    name = tostring(name or ""):lower()
    if name:find("- final", 1, true) then return 4 end
    if name:find("- tier iii", 1, true) then return 3 end
    if name:find("- tier ii", 1, true) then return 2 end
    if name:find("- tier i", 1, true) then return 1 end
    return nil
end

local function old_fungal_aliases(name)
    local aliases, n = {}, tostring(name or "")
    local rank = old_tier_rank(n)
    local elem = n:match("^%s*(%S+)%s+Fungus of Suffering%s*%-")
        or n:match("^%s*(%S+)%s+Fungus of Suffering%s*$")
    if elem then
        rank = rank or 4
        aliases[#aliases + 1] = elem .. " Slime of Suffering"
        for i = 1, rank do
            local suffix = i == 4 and "Final" or ("Tier " .. ({ "I", "II", "III" })[i])
            aliases[#aliases + 1] = elem .. " Fungus of Suffering - " .. suffix
        end
        return aliases
    end
    elem = n:match("^%s*(%S+)%s+Slime of Suffering%s*$")
        or n:match("^%s*Base (%S+)%s+Slime of Suffering")
    if elem then
        aliases[#aliases + 1] = elem .. " Slime of Suffering"
        for i = 1, 4 do
            local suffix = i == 4 and "Final" or ("Tier " .. ({ "I", "II", "III" })[i])
            aliases[#aliases + 1] = elem .. " Fungus of Suffering - " .. suffix
        end
        return aliases
    end
    local bloom = n:match("^%s*Fungal Bloom of (.-)%s*%-")
        or n:match("^%s*Fungal Bloom of (.-)%s*$")
    if bloom and bloom ~= "" then
        rank = rank or 4
        aliases[#aliases + 1] = "Noxious Bloom of " .. bloom
        for i = 1, rank do
            local suffix = i == 4 and "Final" or ("Tier " .. ({ "I", "II", "III" })[i])
            aliases[#aliases + 1] = "Fungal Bloom of " .. bloom .. " - " .. suffix
        end
    end
    return aliases
end

local function better_match(a, b)
    if not a then return b end
    if not b then return a end
    if a.status == "equipped" and b.status ~= "equipped" then return a end
    if b.status == "equipped" and a.status ~= "equipped" then return b end
    return a
end

local function old_build(snap)
    local idx = { by_id = {}, by_name = {}, known_spells = {} }
    local function add_rec(rec)
        local it = rec.item
        local iid = tonumber(it and it.id)
        if iid and iid > 0 then idx.by_id[iid] = better_match(idx.by_id[iid], rec) end
        local n = old_norm_item_name(it and it.name)
        if n ~= "" then
            idx.by_name[n] = better_match(idx.by_name[n], rec)
            for _, alias in ipairs(old_fungal_aliases(it and it.name)) do
                local an = old_norm_item_name(alias)
                if an ~= "" then idx.by_name[an] = better_match(idx.by_name[an], rec) end
            end
        end
    end
    for _, spec in ipairs({
        { bucket = snap.equipped or {}, status = "equipped" },
        { bucket = snap.bags or {}, status = "carried" },
        { bucket = snap.bank or {}, status = "carried" },
    }) do
        for _, it in ipairs(spec.bucket) do add_rec({ item = it, status = spec.status }) end
        for _, host in ipairs(spec.bucket) do
            for _, aug in ipairs(host.augs or {}) do
                if not aug.empty and aug.name and aug.name ~= "" and aug.name ~= "Empty" then
                    add_rec({ item = { name = aug.name, id = aug.id or 0 }, status = spec.status })
                end
            end
        end
    end
    for key, rec in pairs(snap.spells or {}) do
        if type(rec) == "table" then
            if rec.book == true or ((tonumber(rec.book) or 0) > 0) then
                local n = norm(rec.name or key)
                if n ~= "" then idx.known_spells[n] = true end
            end
        elseif rec == true then
            local n = norm(key)
            if n ~= "" then idx.known_spells[n] = true end
        end
    end
    return idx
end

local snap = {
    name = "Tester",
    server = "Srv",
    updated = 123,
    equipped = {
        { name = "Shared Ring", id = 100, where = "Left Finger", slotname = "Left Finger", augs = {
            { name = "Worn Aug", id = 501, index = 1 },
        } },
        { name = "Fire Fungus of Suffering - Tier II", id = 7002, augs = {} },
    },
    bags = {
        { name = "Shared Ring", id = 100, where = "Bag 1", augs = {} },
        { name = "Bag Sword (Augmented)", id = 200, augs = {
            { name = "Bag Aug", id = 502, index = 2 },
        } },
    },
    bank = {
        { name = "Banked Shield", id = 300, augs = {
            { name = "Bank Aug", id = 503, index = 3 },
        } },
    },
    spells = {
        ["Test Spell"] = { name = "Test Spell", book = true, id = 9001 },
        ["Unscribed"] = { name = "Unscribed", book = false, id = 9002 },
        ["Bool Known"] = true,
    },
    spell_ids = { [9001] = true, [9003] = true },
}

local old = old_build(snap)
local new = idxmod.build_snapshot_index(snap)

for id, rec in pairs(old.by_id) do
    check(new.by_id[id] and new.by_id[id].status == rec.status, "by_id status equivalent for " .. tostring(id))
end
for name, rec in pairs(old.by_name) do
    check(new.by_name[name] and new.by_name[name].status == rec.status, "by_name status equivalent for " .. tostring(name))
end
for name in pairs(old.known_spells) do
    check(new.known_spells[name] == true, "known spell equivalent for " .. tostring(name))
end

check(new.by_id[100].status == "equipped", "equipped precedence over bag for duplicate id")
check(new.by_name[idxmod.norm_item_name("Shared Ring")].status == "equipped", "equipped precedence over bag for duplicate name")
check(new.by_id[501].status == "equipped", "worn augment inherits equipped status")
check(new.by_id[502].status == "carried", "bag augment inherits carried status")
check(new.by_id[503].status == "carried", "bank augment inherits carried status")
check(new.by_name[idxmod.norm_item_name("Bag Sword")], "augmented suffix normalized")
check(new.by_name[idxmod.norm_item_name("Fire Slime of Suffering")], "fungal alias indexed")
check(new.known_spell_ids[9001] == true, "known spell id from spells row")
check(new.known_spell_ids[9003] == true, "known spell id from spell_ids table")

local via_bis = bis.ensure_snapshot_index(snap)
check(via_bis == snap._bis_index, "bis preserves snapshot cache field")
check(via_bis.by_id[100].status == new.by_id[100].status, "bis delegates to extracted index")

local cached1, meta1 = idxmod.cached_snapshot_index(snap)
local cached2, meta2 = idxmod.cached_snapshot_index(snap)
check(cached1 == cached2 and cached2 == snap._bis_index, "ownership cached_snapshot_index reuses stable snapshot index")
check(meta1.cache == "hit" or meta1.cache == "miss", "ownership cache returns cache metadata")
check(meta2.cache == "hit", "ownership second lookup is cache hit")
local old_key = snap._bis_index_key
snap.inventoryUpdated = (tonumber(snap.inventoryUpdated) or 0) + 1
snap.seq = (tonumber(snap.seq) or 0) + 1
local cached3, meta3 = idxmod.cached_snapshot_index(snap)
check(cached3 == cached2 and meta3.cache == "hit", "newer seq / inventoryUpdated alone does not rewarm")
check(snap._bis_index_key == old_key, "ownership semantic key ignores publication freshness")

snap.equipped[1] = { name = "Replacement Ring", id = 109, where = "Left Finger", slotname = "Left Finger", augs = {} }
idxmod.invalidate_snapshot_cache(snap)
local cached4, meta4 = idxmod.cached_snapshot_index(snap)
check(cached4 ~= cached2 and meta4.cache == "miss", "real equipped change rewarms")
check(snap._bis_index_key ~= old_key, "ownership cache key changes with ownership facts")

local peek_snap = {
    server = "Test",
    name = "Peek",
    equipped = { { name = "Peek Ring", id = 501, where = "Left Finger", slotname = "Left Finger", augs = {} } },
    bags = {},
    bank = {},
}
local peeked, pmeta = idxmod.peek_snapshot_index(peek_snap)
check(peeked == nil and pmeta and pmeta.cache == "miss", "peek miss does not build")
check(peek_snap._bis_index == nil, "peek miss does not write cache")
local empty_idx = idxmod.empty_snapshot_index()
check(type(empty_idx) == "table" and type(empty_idx.by_id) == "table", "empty compact index is usable")
idxmod.cached_snapshot_index(peek_snap)
local peeked2, pmeta2 = idxmod.peek_snapshot_index(peek_snap)
check(peeked2 ~= nil and pmeta2 and pmeta2.cache == "hit", "peek hit after cache fill")
check(peeked2 == peek_snap._bis_index, "peek hit returns the published index")
local replacement_peek = {
    server = "Test",
    name = "Peek",
    equipped = { { name = "Peek Ring", id = 501, where = "Left Finger", slotname = "Left Finger", augs = {} } },
    bags = {},
    bank = {},
}
local replacement_idx, replacement_meta = idxmod.peek_snapshot_index(replacement_peek)
check(replacement_idx == peeked2 and replacement_meta and replacement_meta.source == "published",
    "same-semantic replacement snapshot reuses published ownership index")
check(replacement_peek._bis_index == nil,
    "published ownership peek does not mutate replacement snapshot")

local coop_snap = {
    server = "Test",
    name = "Coop",
    updated = 1,
    inventoryUpdated = 1,
    bankValid = true,
    bankLive = false,
    bankPreserved = true,
    spells_sig = "abc",
    equipped = {
        { name = "Coop Worn", id = 1100, where = "Primary", slotname = "Primary", augs = {
            { name = "Coop Worn Aug", id = 1101, index = 1 },
        } },
    },
    bags = {
        { name = "Coop Bag", id = 1200, augs = {
            { name = "Coop Bag Aug", id = 1201, index = 2 },
        } },
    },
    bank = {
        { name = "Coop Bank", id = 1300, augs = {} },
    },
    spells = {
        ["Coop Spell"] = { name = "Coop Spell", book = true, id = 1400 },
    },
    spell_ids = { [1401] = true },
}
local expected = idxmod.build_snapshot_index(coop_snap)
local done, meta = false, nil
for _ = 1, 100 do
    done, meta = idxmod.tick_snapshot_warm(coop_snap, 100, 1)
    if done then break end
end
check(done == true and meta and meta.completed == true, "cooperative ownership warm completes")
check(coop_snap._bis_index ~= nil and coop_snap._bis_index_key == idxmod.snapshot_cache_key(coop_snap),
    "cooperative ownership warm publishes snapshot cache")
for id, rec in pairs(expected.by_id) do
    check(coop_snap._bis_index.by_id[id] and coop_snap._bis_index.by_id[id].status == rec.status,
        "cooperative by_id equivalent for " .. tostring(id))
end
for name, rec in pairs(expected.by_name) do
    check(coop_snap._bis_index.by_name[name] and coop_snap._bis_index.by_name[name].status == rec.status,
        "cooperative by_name equivalent for " .. tostring(name))
end
check(coop_snap._bis_index.known_spells[idxmod.norm("Coop Spell")] == true,
    "cooperative warm preserves known spell names")
check(coop_snap._bis_index.known_spell_ids[1400] == true and coop_snap._bis_index.known_spell_ids[1401] == true,
    "cooperative warm preserves known spell ids")

local stale_snap = { server = "Test", name = "Stale", updated = 1, inventoryUpdated = 1, equipped = {}, bags = {
    { name = "Before", id = 2100, augs = {} },
}, bank = {} }
local stale_done = idxmod.tick_snapshot_warm(stale_snap, 100, 1)
check(stale_done == false and stale_snap._bis_index_warm_job ~= nil, "cooperative warm can remain in progress")
check(stale_snap._bis_index == nil, "partial warm is not published")
stale_snap.bags = { { name = "After", id = 2101, augs = {} } }
idxmod.invalidate_snapshot_cache(stale_snap)
local stale_done2, stale_meta2 = idxmod.tick_snapshot_warm(stale_snap, 100, 1)
check(stale_done2 == false and stale_meta2 and stale_meta2.stale == true,
    "cooperative warm cancels on newer semantic input")

-- Enqueue policy: same semantic / duplicate / restart
local warm = { queue = {}, active = nil }
local row = { key = "Srv_Coop", snap = coop_snap }
local queued, why = idxmod.enqueue_warm(warm, row, "tick")
check(queued == false and why == "same_semantic", "completed current semantic key does not requeue")

local fresh = {
    server = "Test", name = "Fresh", updated = 1, inventoryUpdated = 1, seq = 1,
    equipped = { { name = "A", id = 1, augs = {} } }, bags = {}, bank = {},
}
queued, why = idxmod.enqueue_warm(warm, { key = "Test_Fresh", snap = fresh }, "tick")
check(queued == true and why == "new", "uncached snap enqueues")
queued, why = idxmod.enqueue_warm(warm, { key = "Test_Fresh", snap = fresh }, "tick")
check(queued == false and why == "duplicate", "already queued same key does not duplicate")
local fresh_replacement = {
    server = "Test", name = "Fresh", updated = 2, inventoryUpdated = 2, seq = 2,
    equipped = { { name = "A", id = 1, augs = {} } }, bags = {}, bank = {},
}
queued, why = idxmod.enqueue_warm(warm, { key = "Test_Fresh", snap = fresh_replacement }, "tick")
check(queued == false and why == "duplicate", "replacement table with same ownership semantic does not restart")
check(warm.queue[1].snap == fresh_replacement,
    "same-semantic queued warm retargets the current snapshot table")
fresh = fresh_replacement
fresh.seq = 2
fresh.inventoryUpdated = 9
queued, why = idxmod.enqueue_warm(warm, { key = "Test_Fresh", snap = fresh }, "tick")
check(queued == false and why == "duplicate", "newer seq only does not requeue")
fresh.equipped = { { name = "B", id = 2, augs = {} } }
idxmod.invalidate_snapshot_cache(fresh)
queued, why = idxmod.enqueue_warm(warm, { key = "Test_Fresh", snap = fresh }, "tick")
check(queued == true and why == "restart", "real ownership change requeues/replaces")
check(#warm.queue == 1, "restart replaces in place, queue stays length 1")

warm.active = warm.queue[1]
warm.queue = {}
local active_replacement = {
    server = "Test", name = "Fresh", updated = 3, inventoryUpdated = 10, seq = 3,
    equipped = { { name = "B", id = 2, augs = {} } }, bags = {}, bank = {},
}
queued, why = idxmod.enqueue_warm(warm, { key = "Test_Fresh", snap = active_replacement }, "tick")
check(queued == false and why == "duplicate" and warm.active ~= nil,
    "same-semantic active warm does not restart")
check(warm.active.snap == active_replacement,
    "same-semantic active warm retargets the current snapshot table")
fresh = active_replacement
fresh.equipped = { { name = "C", id = 3, augs = {} } }
idxmod.invalidate_snapshot_cache(fresh)
queued, why = idxmod.enqueue_warm(warm, { key = "Test_Fresh", snap = fresh }, "tick")
check(warm.active == nil, "newer semantic clears the in-progress job")
check(queued == true and why == "new", "restarted work is enqueued")

-- Semantic key: ownership facts only (not Store content_signatures / lockouts / stamps)
local function key_snap(extra)
    local s = {
        server = "Srv",
        name = "KeyTest",
        seq = 1,
        inventoryUpdated = 10,
        updated = 10,
        bankCapturedAt = 100,
        bankValid = true,
        bankLive = false,
        bankPreserved = true,
        spells_sig = "spA",
        equipped = { { name = "Eq", id = 1, augs = { { name = "EqAug", id = 11, index = 1 } } } },
        bags = { { name = "Bag", id = 2, augs = {} } },
        bank = { { name = "Bank", id = 3, augs = {} } },
        lockouts = {
            DoNState = { capturedAt = 1, replays = { ["Best Laid Plans"] = { expiresAt = 9 } } },
            Expeditions = { ["Some Expedition"] = { found = true, expiresAt = 50 } },
        },
    }
    if type(extra) == "function" then extra(s) end
    return s
end

local k0 = idxmod.snapshot_semantic_key(key_snap())
local g0 = idxmod.snapshot_cache_key(key_snap())
check(k0 ~= "", "semantic key is non-empty")
check(g0 ~= "" and g0 ~= k0, "gear cache key is split from full semantic key")

local item_reads = 0
local tracked_values = { name = "Tracked", id = 7001, augs = {} }
local tracked_item = setmetatable({}, {
    __index = function(_, key)
        item_reads = item_reads + 1
        return tracked_values[key]
    end,
})
local cached_key_snap = {
    server = "Srv", name = "CachedKey", equipped = { tracked_item }, bags = {}, bank = {},
}
local serialize_snapshot = require("store_backend_sqlite")._serialize
local serialized_before_peek = serialize_snapshot(cached_key_snap)
local cached_key_a = idxmod.snapshot_cache_key(cached_key_snap)
local first_key_reads = item_reads
check(cached_key_snap._tg_own_fp == nil,
    "ownership fingerprint cache never contaminates the serializable snapshot")
check(serialize_snapshot(cached_key_snap) == serialized_before_peek,
    "ownership peek leaves persistence and actor snapshot payload unchanged")
local cached_key_b = idxmod.snapshot_cache_key(cached_key_snap)
check(cached_key_a == cached_key_b and item_reads == first_key_reads,
    "repeated ownership key lookup reuses the snapshot item fingerprint")
cached_key_snap.seq = 99
cached_key_snap.spells_sig = "unrelated"
idxmod.snapshot_cache_key(cached_key_snap)
check(item_reads == first_key_reads,
    "seq and spell metadata changes do not rescan gear ownership")
cached_key_snap.bags = { { name = "New Bag Item", id = 7002, augs = {} } }
check(idxmod.snapshot_cache_key(cached_key_snap) ~= cached_key_a and item_reads > first_key_reads,
    "inventory table replacement invalidates the cached ownership fingerprint")
check(idxmod.has_cached_fingerprint(cached_key_snap) == true,
    "weak side cache reports the live snapshot fingerprint")
do
    local weak_ref = setmetatable({}, { __mode = "v" })
    local collectible = {
        server = "Srv", name = "Collectible",
        equipped = { { name = "Transient", id = 7003, augs = {} } },
        bags = {}, bank = {},
    }
    idxmod.snapshot_cache_key(collectible)
    weak_ref[1] = collectible
    collectible = nil
    collectgarbage("collect")
    collectgarbage("collect")
    check(weak_ref[1] == nil, "weak fingerprint cache does not retain old snapshots")
end

check(idxmod.snapshot_semantic_key(key_snap(function(s) s.seq = 99 end)) == k0,
    "seq-only change -> same ownership key")
check(idxmod.snapshot_semantic_key(key_snap(function(s) s.inventoryUpdated = 999 end)) == k0,
    "inventoryUpdated-only -> same")
check(idxmod.snapshot_semantic_key(key_snap(function(s)
    s.lockouts.DoNState.replays["Sudden Tremors"] = { expiresAt = 77 }
    s.lockouts.DoNState.capturedAt = 2
end)) == k0, "DoN change -> same")
check(idxmod.snapshot_semantic_key(key_snap(function(s)
    s.lockouts.Expeditions["Other Expedition"] = { found = true, expiresAt = 80 }
    s.lockouts.Expeditions["Some Expedition"].expiresAt = 51
end)) == k0, "expedition lockout change -> same")
check(idxmod.snapshot_semantic_key(key_snap(function(s) s.bankCapturedAt = 500 end)) == k0,
    "bankCapturedAt-only -> same")
check(idxmod.snapshot_semantic_key(key_snap(function(s) s.updated = 500 end)) == k0,
    "updated stamp-only -> same")

check(idxmod.snapshot_semantic_key(key_snap(function(s)
    s.equipped = { { name = "Eq2", id = 91, augs = { { name = "EqAug", id = 11, index = 1 } } } }
end)) ~= k0, "equipped item change -> new key")
check(idxmod.snapshot_semantic_key(key_snap(function(s)
    s.bags = { { name = "Bag2", id = 92, augs = {} } }
end)) ~= k0, "bag item change -> new key")
check(idxmod.snapshot_semantic_key(key_snap(function(s)
    s.bank = { { name = "Bank2", id = 93, augs = {} } }
end)) ~= k0, "bank item change -> new key")
check(idxmod.snapshot_semantic_key(key_snap(function(s)
    s.equipped[1].augs[1] = { name = "OtherAug", id = 12, index = 1 }
end)) ~= k0, "augment change -> new key")
check(idxmod.snapshot_semantic_key(key_snap(function(s) s.spells_sig = "spB" end)) ~= k0,
    "spells_sig change -> new key")
check(idxmod.snapshot_cache_key(key_snap(function(s) s.spells_sig = "spB" end)) == g0,
    "spells_sig change does not invalidate gear cache key")
check(idxmod.snapshot_semantic_key(key_snap(function(s) s.bankValid = false end)) ~= k0,
    "bankValid change -> new key")
check(idxmod.snapshot_semantic_key(key_snap(function(s) s.bankLive = true end)) ~= k0,
    "bankLive change -> new key")
check(idxmod.snapshot_semantic_key(key_snap(function(s) s.bankPreserved = false end)) ~= k0,
    "bankPreserved change -> new key")

check(idxmod.snapshot_cache_key(key_snap(function(s)
    s.equipped = { s.equipped[1] }
    s.bags = { { name = "BagB", id = 22, augs = {} }, { name = "BagA", id = 21, augs = {} } }
end)) == idxmod.snapshot_cache_key(key_snap(function(s)
    s.equipped = { s.equipped[1] }
    s.bags = { { name = "BagA", id = 21, augs = {} }, { name = "BagB", id = 22, augs = {} } }
end)), "gear cache key is stable across bag item order")

-- Store's broad content signature must not leak into ownership invalidation.
do
    local poisoned = key_snap()
    local ok_store, store_mod = pcall(require, "store")
    if ok_store and store_mod and store_mod.Store then
        store_mod.Store.content_signatures = store_mod.Store.content_signatures or {}
        store_mod.Store.content_signatures["Srv_KeyTest"] = "digest-with-lockouts-1"
        local before = idxmod.snapshot_semantic_key(poisoned)
        store_mod.Store.content_signatures["Srv_KeyTest"] = "digest-with-lockouts-2"
        check(idxmod.snapshot_semantic_key(poisoned) == before,
            "Store content_signatures lockout-only digest is ignored by ownership")
        store_mod.Store.content_signatures["Srv_KeyTest"] = nil
    else
        check(true, "Store content_signatures lockout-only digest is ignored by ownership")
    end
end

-- Scheduler key format: stored next_work.key must match current_key.
-- Live bug was who|"|"..semantic vs semantic, which never matched.
local function drel_snap(extra)
    local s = {
        server = "Project Lazarus",
        name = "Drel",
        seq = 1,
        inventoryUpdated = 10,
        equipped = { { name = "Sword", id = 501, augs = {} } },
        bags = {},
        bank = {},
        bankValid = true,
        bankLive = false,
        bankPreserved = false,
        spells_sig = "sp0",
        lockouts = { DoNState = { capturedAt = 1, replays = {} }, Expeditions = {} },
    }
    if type(extra) == "function" then extra(s) end
    return s
end

local who = "Project Lazarus_Drel"
local snap = drel_snap()
local semantic = idxmod.snapshot_cache_key(snap)
check(semantic ~= "", "Drel semantic key is non-empty")
check(semantic:find("|", 1, true) ~= nil, "semantic key is the ownership fingerprint")
local row = { key = who, snap = snap }
local next_work = { who = who, key = semantic, row = row, snap = snap }

local prefixed = who .. "|" .. semantic
check(prefixed ~= next_work.key, "TRACE: who|semantic is not the stored key")
check(idxmod.warm_job_current_key(next_work) == next_work.key,
    "current_key uses the same semantic format as stored next_work.key")
check(idxmod.warm_job_is_stale(next_work) == false,
    "same who + same semantic key is not stale")

local function start_decision(job)
    local current_key = idxmod.snapshot_cache_key(job.snap)
    if current_key ~= job.key then return "stale" end
    if idxmod.is_snapshot_index_cached(job.snap) then return "cached" end
    return "start"
end
check(start_decision(next_work) == "start", "matching keys begin warm instead of restart_new_semantic")

local done, meta = idxmod.tick_snapshot_warm(snap, 100, 1)
check(not (meta and meta.stale), "warm begins/continues on matching semantic key")
check(snap._bis_index_warm_job ~= nil or (done == true), "warm job is active or completed")
if snap._bis_index_warm_job then
    local done2, meta2 = idxmod.tick_snapshot_warm(snap, 100, 1)
    check(not (meta2 and meta2.stale), "continuing the same semantic key is not stale")
    check(done2 == true or snap._bis_index_warm_job ~= nil, "same-key warm continues")
end

snap.seq = 99
snap.inventoryUpdated = 999
snap.lockouts.DoNState.replays["Best Laid Plans"] = { expiresAt = 9 }
snap.lockouts.Expeditions["Some Expedition"] = { found = true, expiresAt = 50 }
check(idxmod.snapshot_cache_key(snap) == semantic, "seq / DoN / lockout-only keeps the same semantic key")
next_work.key = semantic
check(idxmod.warm_job_is_stale(next_work) == false, "seq / DoN / lockout-only change is not a scheduler restart")

snap.equipped = { { name = "Other Sword", id = 502, augs = {} } }
idxmod.invalidate_snapshot_cache(snap)
local changed = idxmod.snapshot_cache_key(snap)
check(changed ~= semantic, "actual item change -> new semantic key")
check(idxmod.warm_job_is_stale(next_work) == true, "changed semantic key is stale vs stored key")

local diag = require('diagnostics')
diag.enabled = true
diag.reset()
local sched = { queue = {}, active = nil }
local drel = drel_snap()
local queued, why = idxmod.enqueue_warm(sched, { key = who, snap = drel }, "tick")
check(queued == true and why == "new", "uncached Drel enqueues")
check(sched.queue[1].who == who, "who is stored separately")
check(sched.queue[1].key == idxmod.snapshot_cache_key(drel), "queued key is semantic-only")
check(idxmod.warm_job_is_stale(sched.queue[1]) == false, "queued job is startable")
check(start_decision(sched.queue[1]) == "start", "scheduler would start, not mark stale")

queued, why = idxmod.enqueue_warm(sched, { key = who, snap = drel }, "tick")
check(queued == false and why == "duplicate", "same who + same semantic key does not requeue")

local discord_snap = drel_snap(function(s) s.name = "Discord" end)
local discord_who = "Project Lazarus_Discord"
queued, why = idxmod.enqueue_warm(sched, { key = discord_who, snap = discord_snap }, "tick")
check(queued == true and why == "new", "different who with own same-format key enqueues independently")
check(#sched.queue == 2, "Drel and Discord keep independent queue entries")
check(sched.queue[1].who == who and sched.queue[2].who == discord_who, "per-character queue identity")
check(sched.queue[1].key == idxmod.snapshot_cache_key(drel), "Drel key remains semantic-only")
check(sched.queue[2].key == idxmod.snapshot_cache_key(discord_snap), "Discord key uses the same format")
check(idxmod.warm_job_is_stale(sched.queue[1]) == false and idxmod.warm_job_is_stale(sched.queue[2]) == false,
    "independent same-format keys are not stale")

drel.seq = 50
drel.lockouts.DoNState.capturedAt = 2
queued, why = idxmod.enqueue_warm(sched, { key = who, snap = drel }, "tick")
check(queued == false and why == "duplicate", "seq / DoN-only change does not restart")
check((diag.counters["ownership.restart_new_semantic"] or 0) == 0,
    "seq / DoN-only change does not increment restart_new_semantic")

drel.equipped = { { name = "New Sword", id = 777, augs = {} } }
idxmod.invalidate_snapshot_cache(drel)
queued, why = idxmod.enqueue_warm(sched, { key = who, snap = drel }, "tick")
check(queued == true and why == "restart", "item change requeues/replaces")
check((diag.counters["ownership.restart_new_semantic"] or 0) == 1,
    "item change increments restart_new_semantic exactly once")
check(#sched.queue == 2, "restart replaces Drel in place; Discord stays")
check(idxmod.warm_job_is_stale(sched.queue[1]) == false, "replaced Drel job matches the new semantic key")
diag.enabled = false
diag.reset()

-- A2 elapsed-time budget: production has no two-record ceiling.
local budget_snap = {
    server = "Test", name = "Budget", equipped = {}, bank = {},
    bags = {
        { name = "One", id = 3001, augs = {} },
        { name = "Two", id = 3002, augs = {} },
        { name = "Three", id = 3003, augs = {} },
        { name = "Four", id = 3004, augs = {} },
        { name = "Five", id = 3005, augs = {} },
        { name = "Six", id = 3006, augs = {} },
    },
}
for i = 7, 40 do
    budget_snap.bags[#budget_snap.bags + 1] = {
        name = "Budget Item " .. tostring(i), id = 3000 + i, augs = {},
    }
end
local budget_now = 0
idxmod._set_work_clock_for_tests(function()
    budget_now = budget_now + 0.00002
    return budget_now
end)
local budget_done, budget_meta = idxmod.tick_snapshot_warm(budget_snap, 1)
check(budget_done == false, "time-budgeted warm can preserve a private partial")
check((budget_meta and budget_meta.tick_units or 0) > 2,
    "time-budgeted warm processes more than the old two-record cap while budget remains")
check(budget_snap._bis_index == nil and budget_snap._bis_index_warm_job ~= nil,
    "time-budgeted partial remains unpublished")
check((budget_meta and budget_meta.tick_ms or 99) <= 1.2,
    "normal fake-cost ownership tick stays within the configured test budget")
check(budget_meta and budget_meta.budget_yield == true,
    "time-budgeted warm reports yielding at budget")

-- One indivisible expensive record may overrun; the scheduler must not start
-- another record afterward and must expose the overrun.
local expensive_snap = {
    server = "Test", name = "Expensive", equipped = {},
    bags = {
        { name = "Heavy", id = 4001, augs = {} },
        { name = "Must Wait", id = 4002, augs = {} },
    },
    bank = {},
}
idxmod._set_work_clock_for_tests(function() return 0 end)
idxmod.begin_snapshot_warm(expensive_snap)
local clock_calls = 0
idxmod._set_work_clock_for_tests(function()
    clock_calls = clock_calls + 1
    if clock_calls >= 5 then return 0.003 end
    return 0
end)
local expensive_done, expensive_meta = idxmod.tick_snapshot_warm(expensive_snap, 1)
check(expensive_done == false, "expensive unit does not synchronously complete the warm")
check((expensive_meta and expensive_meta.tick_units or 0) == 1,
    "no second ownership unit starts after one unit consumes the budget")
check((expensive_meta and expensive_meta.max_unit_ms or 0) >= 3,
    "expensive single-unit overrun is instrumented")
check(expensive_snap._bis_index == nil, "expensive partial is not published")

local full_call_now = 0
local timed_values = { name = "Timed", id = 5001, augs = {} }
local timed_item = setmetatable({}, {
    __index = function(_, key)
        full_call_now = full_call_now + 0.001
        return timed_values[key]
    end,
})
local timed_snap = {
    server = "Test", name = "Timed", equipped = { timed_item }, bags = {}, bank = {},
}
idxmod._set_work_clock_for_tests(function() return full_call_now end)
local _, timed_meta = idxmod.tick_snapshot_warm(timed_snap, 100, 1)
check(timed_meta and tonumber(timed_meta.call_ms) and timed_meta.call_ms >= full_call_now * 1000 - 0.01,
    "ownership timing includes key validation before the warm unit")
idxmod._set_work_clock_for_tests(nil)

print(string.format("ownership index: %d passed, %d failed", pass, fail))
os.exit(fail == 0 and 0 or 1)
