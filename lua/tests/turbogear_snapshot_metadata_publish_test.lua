-- Run from repo root: luajit lua/tests/turbogear_snapshot_metadata_publish_test.lua
--
-- Metadata-only publication must clone current inventory authority and overlay
-- lockouts/DoN. It must not walk equipped/bags/cursor/bank, must not bump
-- inventoryUpdated, and must not change ownership's semantic key.
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

local diag_counts = {}
package.preload['diagnostics'] = function()
    return {
        time = function(_, fn) return fn() end,
        count = function(k) diag_counts[k] = (diag_counts[k] or 0) + 1 end,
        event = function() end,
        sample = function() end,
        context = function() end,
        is_enabled = function() return false end,
    }
end

local lite_calls = 0
local items = require('items')
local orig_lite = items.make_item_lite
items.make_item_lite = function(...)
    lite_calls = lite_calls + 1
    return orig_lite(...)
end

local snapshot = require('snapshot')
local ownership = require('ownership_index')
local local_needs = require('local_needs')

local gather_calls = 0
local orig_gather = snapshot.gather
snapshot.gather = function(...)
    gather_calls = gather_calls + 1
    return orig_gather(...)
end

local walk_calls = 0
if type(snapshot.begin_lite_inventory_walk) == "function" then
    local orig_walk = snapshot.begin_lite_inventory_walk
    snapshot.begin_lite_inventory_walk = function(...)
        walk_calls = walk_calls + 1
        return orig_walk(...)
    end
end

local pass, fail = 0, 0
local function check(cond, msg)
    if cond then pass = pass + 1 else fail = fail + 1; print("  FAIL: " .. tostring(msg)) end
end

local function item(id, name, loc, where, slotid)
    return {
        id = id, name = name, location = loc, where = where,
        slotid = slotid, qty = 1,
        augs = { { index = 1, id = id + 1000, empty = false } },
    }
end

local function authority(extra)
    extra = extra or {}
    local snap = {
        name = "Drel",
        server = "Srv",
        class = "Warrior",
        depth = "lite",
        equipped = { item(11, "Sword", "Equipped", "Primary", 13) },
        bags = {
            item(22, "BagItem", "Bags", "Inventory Bag 1", 23),
            item(33, "CursorGem", "Bags", "Cursor", nil),
        },
        bank = { item(44, "Banked", "Bank", "Bank 1", 2000) },
        bankValid = true,
        bankLive = extra.bankLive == true,
        bankPreserved = extra.bankPreserved ~= false,
        bankCapturedAt = extra.bankCapturedAt or 50,
        bankOpen = extra.bankOpen == true,
        inventoryUpdated = extra.inventoryUpdated or 77,
        updated = 70,
        seq = 9,
        spells_sig = "SPELLS1",
        spells = { ["some spell"] = { book = true, id = 1 } },
        lockouts = {
            Custom = { ["Old Lock"] = { found = true, expiresAt = 1 } },
            DoNState = { known = true, replay = {} },
        },
    }
    return snap
end

local function reset_counters()
    lite_calls, gather_calls, walk_calls = 0, 0, 0
    diag_counts = {}
end

local function no_inventory_work(label)
    check(gather_calls == 0, label .. ": snapshot.gather not called")
    check(lite_calls == 0, label .. ": make_item_lite not called")
    check(walk_calls == 0, label .. ": inventory walker not called")
    check((diag_counts["snapshot.inventory_live_refresh"] or 0) == 0,
        label .. ": no live inventory refresh")
    check((diag_counts["snapshot.metadata_publish"] or 0) >= 1,
        label .. ": metadata_publish counted")
    check((diag_counts["snapshot.inventory_carry_forward"] or 0) >= 1,
        label .. ": inventory_carry_forward counted")
end

-- No cached/store authority: refuse rather than gather.
do
    reset_counters()
    snapshot.invalidate()
    local out = snapshot.prepare_metadata_publish({ lockouts = {} }, { reason = "lockout_change" })
    check(out == nil, "no authority returns nil instead of gathering")
    check(gather_calls == 0, "nil-authority path does not gather")
end

-- Lockout-only: inventory rows, identity, and inventoryUpdated stay put.
do
    reset_counters()
    snapshot.invalidate()
    local src = authority()
    check(snapshot.adopt(src) == true, "adopt lockout-src")
    local new_lockouts = {
        Custom = { ["Txevu"] = { found = true, expiresAt = 1800000000 } },
        DoNState = src.lockouts.DoNState,
    }
    local before_id = snapshot.inventory_identity(src)
    local before_inv = src.inventoryUpdated
    local out = snapshot.prepare_metadata_publish({ lockouts = new_lockouts }, { reason = "lockout_change" })
    check(type(out) == "table", "lockout-only publish returns a snap")
    check(out ~= src, "lockout-only publish is a shallow clone")
    check(out.equipped == src.equipped, "equipped table is carried, not rebuilt")
    check(out.bags == src.bags, "bags table is carried, not rebuilt")
    check(out.bank == src.bank, "bank table is carried, not rebuilt")
    check(out.inventoryUpdated == before_inv, "inventoryUpdated is not manufactured")
    check(snapshot.inventory_identity(out) == before_id, "inventory identity unchanged")
    check(out.lockouts == new_lockouts, "lockouts updated")
    check(out.lockouts.Custom.Txevu and out.lockouts.Custom.Txevu.found == true,
        "new lockout is present")
    check(out.spells_sig == "SPELLS1", "spells_sig carried")
    check(out.bankValid == true and out.bankLive == false and out.bankPreserved == true
        and out.bankCapturedAt == 50, "bank provenance carried")
    check(out.seq ~= src.seq, "publication seq is stamped")
    no_inventory_work("lockout-only")
end

-- DoN-only: inventory identity unchanged, DoNState replaced.
do
    reset_counters()
    snapshot.invalidate()
    local src = authority()
    check(snapshot.adopt(src) == true, "adopt don-src")
    local new_lockouts = {
        Custom = src.lockouts.Custom,
        DoNState = { known = true, replay = { ["Blood of the Dragon"] = { expiresAt = 9 } } },
    }
    local before_id = snapshot.inventory_identity(src)
    local out = snapshot.prepare_metadata_publish({ lockouts = new_lockouts }, { reason = "don_change" })
    check(snapshot.inventory_identity(out) == before_id, "DoN-only inventory identity unchanged")
    check(out.lockouts.DoNState.replay["Blood of the Dragon"] ~= nil, "DoNState updated")
    check(out.inventoryUpdated == src.inventoryUpdated, "DoN-only does not bump inventoryUpdated")
    no_inventory_work("DoN-only")
end

-- Closed preserved bank stays present and non-live.
do
    reset_counters()
    snapshot.invalidate()
    local src = authority({ bankLive = false, bankPreserved = true, bankCapturedAt = 42 })
    check(snapshot.adopt(src) == true, "adopt closed-bank src")
    local out = snapshot.prepare_metadata_publish({
        lockouts = { Custom = {}, DoNState = { known = true } },
    }, { reason = "lockout_change" })
    check(#out.bank == 1 and out.bank[1].id == 44, "closed bank rows remain present")
    check(out.bankLive == false, "closed bank stays bankLive=false")
    check(out.bankPreserved == true, "closed bank stays bankPreserved=true")
    check(out.bankValid == true, "closed bank stays bankValid")
    check(out.bankCapturedAt == 42, "bankCapturedAt unchanged")
    no_inventory_work("closed-bank")
end

-- Ownership semantic key is lockout/DoN-blind; enqueue skips rebuild.
do
    reset_counters()
    snapshot.invalidate()
    local src = authority()
    check(snapshot.adopt(src) == true, "adopt ownership-src")
    local idx, meta = ownership.cached_snapshot_index(src)
    check(type(idx) == "table", "source ownership index built")
    check(meta and meta.cache == "miss", "first ownership build is a miss")
    local before_key = ownership.snapshot_semantic_key(src)
    local out = snapshot.prepare_metadata_publish({
        lockouts = {
            Custom = { ["Venril Sathir"] = { found = true, expiresAt = 2 } },
            DoNState = { known = true, replay = { x = 1 } },
        },
    }, { reason = "lockout_change" })
    check(ownership.snapshot_semantic_key(out) == before_key,
        "lockout/DoN change does not change ownership semantic key")
    local _, hit_meta = ownership.cached_snapshot_index(out)
    check(hit_meta and hit_meta.cache == "hit",
        "carried _bis_index remains valid on the metadata clone")
    local queued, why = ownership.enqueue_warm({ queue = {} }, { snap = out, key = "Srv_Drel" }, "lockout_change")
    check(queued == false and why == "same_semantic",
        "ownership enqueue is same_semantic_skip, got " .. tostring(why))
    no_inventory_work("ownership")
end

-- [TG] still evaluates generated need from carried ownership; no new deps.
do
    reset_counters()
    snapshot.invalidate()
    local src = authority()
    src.equipped[1].name = "Exact Blade"
    src.equipped[1].id = 111
    check(snapshot.adopt(src) == true, "adopt tg-src")
    ownership.cached_snapshot_index(src)
    local out = snapshot.prepare_metadata_publish({
        lockouts = { Custom = {}, DoNState = { known = true } },
    }, { reason = "don_change" })
    local idx = ownership.cached_snapshot_index(out)
    local state = local_needs.build_local_state({
        identity = { name = "Drel", server = "Srv", class = "Warrior", local_owner = true },
        freshness = { updated = out.updated, bankValid = out.bankValid },
        ownership = idx,
        candidates = { {
            enabled = true,
            kind = "builtin",
            eval_path = "built_in_slot",
            list_id = "preanguish",
            list_name = "Pre-Raid",
            slot = "Primary",
            link_matched = true,
            entry = { item = "Exact Blade", names = { "Exact Blade" }, ids = { 111 }, slot = "Primary" },
        } },
    })
    local r = local_needs.evaluate_link(state, { name = "Exact Blade", id = 111 })
    check(r.need == false and r.reason == "owned",
        "[TG] generated authority remains available after metadata publish, got " ..
        tostring(r and r.reason))
    no_inventory_work("tg-authority")
end

local function file_has(path, needle)
    local f = io.open(path, "r")
    if not f then return false end
    local body = f:read("*a")
    f:close()
    return body:find(needle, 1, true) ~= nil
end

check(not file_has("lua/turbogear/announcer.lua", "prepare_metadata_publish"),
    "announcer does not depend on prepare_metadata_publish")
check(not file_has("lua/turbogear/local_needs.lua", "prepare_metadata_publish"),
    "local_needs does not depend on prepare_metadata_publish")
check(not file_has("lua/turbogear/bis_catalog.lua", "prepare_metadata_publish"),
    "bis_catalog does not depend on prepare_metadata_publish")
check(not file_has("lua/turbogear/ownership_index.lua", "prepare_metadata_publish"),
    "ownership_index does not depend on prepare_metadata_publish")

print(string.format('snapshot metadata publish: %d passed, %d failed', pass, fail))
if fail > 0 then os.exit(1) end
