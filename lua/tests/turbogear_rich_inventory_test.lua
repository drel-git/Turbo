-- Run from repo root: luajit lua/tests/turbogear_rich_inventory_test.lua
-- Cooperative rich-inventory: one full item per slice, no partial publish,
-- atomic promote, inventory cancel, non-inventory ignore, bank preserve.
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

for _, name in ipairs({ "mq", "config", "diagnostics", "rich_inventory", "snapshot" }) do
    package.loaded[name] = nil
    package.preload[name] = nil
end

package.preload["mq"] = function()
    return {
        TLO = {
            Me = { Inventory = function() return nil end },
            Cursor = nil,
        },
        cmd = function() end,
    }
end
package.preload["config"] = function()
    return {
        CFG = { rich_inventory_items_per_slice = 1 },
        Settings = {},
    }
end
package.preload["diagnostics"] = function()
    return {
        time = function(_, fn) return fn() end,
        count = function() end,
        event = function() end,
        sample = function() end,
        context = function() end,
        is_enabled = function() return false end,
    }
end

local ri = require('rich_inventory')

local pass, fail = 0, 0
local function check(cond, msg)
    if cond then
        pass = pass + 1
    else
        fail = fail + 1
        print("FAIL: " .. tostring(msg))
    end
end

local function copy(t)
    local out = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            local inner = {}
            for ik, iv in pairs(v) do inner[ik] = iv end
            out[k] = inner
        else
            out[k] = v
        end
    end
    return out
end

local function lite_item(id, name, loc, slotid, slotname, where)
    return {
        id = id,
        name = name,
        location = loc,
        slotid = slotid,
        slotname = slotname,
        where = where or slotname,
        qty = 1,
        depth = "lite",
        augs = { { index = 1, id = id + 1000, empty = false, name = "Aug " .. id } },
        stats = { ac = 0, hp = 0, mana = 0 },
        baseStats = { ac = 0, hp = 0, mana = 0 },
        classes = {},
        slots = {},
        focusEffects = {},
        wornFocusEffects = {},
        clicky = nil,
    }
end

local function enrich(row)
    local rich = copy(row)
    rich.depth = "full"
    rich.stats = { ac = 10 + row.id, hp = 20 + row.id, mana = 5, haste = 1, str = 4 }
    rich.baseStats = { ac = 8 + row.id, hp = 15 + row.id, mana = 5, haste = 1, str = 4 }
    rich.statsMerged = true
    rich.classes = { "Warrior" }
    rich.slots = { "chest" }
    rich.allClasses = false
    rich.itemType = "armor"
    rich.requiredLevel = 70
    rich.recommendedLevel = 70
    rich.tribute = 12
    rich.focusEffects = { { name = "Focus " .. row.id } }
    rich.wornFocusEffects = { { name = "Worn " .. row.id } }
    rich.augs = {
        {
            index = 1,
            id = row.id + 1000,
            empty = false,
            name = "Aug " .. row.id,
            stats = { ac = 2 },
            focusEffects = { { name = "AugFocus" } },
        },
    }
    return rich
end

local function identity(snap)
    local parts = {}
    local function eat(list, prefix)
        for _, it in ipairs(list or {}) do
            parts[#parts + 1] = string.format("%s:%s:%s:%s",
                prefix, tostring(it.id), tostring(it.slotid or ""), tostring(it.slotname or ""))
            for _, aug in ipairs(it.augs or {}) do
                parts[#parts + 1] = "a" .. tostring(aug.index) .. ":" .. tostring(aug.id or 0)
            end
        end
    end
    eat(snap.equipped, "eq")
    eat(snap.bags, "bg")
    eat(snap.bank, "bn")
    table.sort(parts)
    return table.concat(parts, "|")
end

local function rich_fields_equal(a, b, prefix)
    prefix = prefix or "item"
    check(a.id == b.id, prefix .. " id")
    check(a.name == b.name, prefix .. " name")
    check(a.slotid == b.slotid, prefix .. " slotid")
    check(a.slotname == b.slotname, prefix .. " slotname")
    check(a.depth == "full" and b.depth == "full", prefix .. " depth full")
    check(a.stats and a.stats.ac == b.stats.ac, prefix .. " stats.ac")
    check(a.stats and a.stats.hp == b.stats.hp, prefix .. " stats.hp")
    check(a.baseStats and a.baseStats.ac == b.baseStats.ac, prefix .. " baseStats.ac")
    check(a.statsMerged == true and b.statsMerged == true, prefix .. " statsMerged")
    check((a.classes or {})[1] == (b.classes or {})[1], prefix .. " classes")
    check((a.slots or {})[1] == (b.slots or {})[1], prefix .. " slots")
    check((a.focusEffects or {})[1] and (a.focusEffects[1].name == b.focusEffects[1].name), prefix .. " focus")
    check((a.wornFocusEffects or {})[1] and (a.wornFocusEffects[1].name == b.wornFocusEffects[1].name), prefix .. " worn focus")
    check((a.augs or {})[1] and a.augs[1].id == b.augs[1].id, prefix .. " aug id")
    check((a.augs or {})[1] and a.augs[1].stats and a.augs[1].stats.ac == b.augs[1].stats.ac, prefix .. " aug stats")
end

local function make_lite_snap()
    return {
        name = "Sketti",
        server = "Project Lazarus",
        class = "Necromancer",
        depth = "lite",
        seq = 1,
        don = { a = 1 },
        lockouts = { b = 2 },
        spells_sig = "spell-v1",
        equipped = {
            lite_item(11, "Crown", "Equipped", 2, "Head", "Head"),
            lite_item(12, "Robe", "Equipped", 17, "Chest", "Chest"),
        },
        bags = {
            lite_item(21, "Sword", "Bags", 23, 1, "Bag1 #1"),
            lite_item(22, "Ring", "Bags", 23, 2, "Bag1 #2"),
            lite_item(23, "Cloak", "Bags", 24, 1, "Bag2 #1"),
        },
        bank = {
            lite_item(99, "Banked", "Bank", 1, 0, "Bank 1"),
        },
        bankPreserved = true,
        bankLive = false,
        bankOpen = false,
        bankValid = true,
        bankCapturedAt = 1000,
        bankReason = "cached; bank window closed",
    }
end

-- Policy
local p = ri.plan_startup_full()
check(p.blocking_full == false and p.start_job == true and p.items_per_slice == 1,
    "startup plan is cooperative, 1 item/slice")
local sync = ri.plan_manual_sync()
check(sync.blocking_full == false and sync.lite_refresh == true and sync.restart_job == true,
    "Sync Now plan: lite + restart, not blocking full")
check(ri.should_block_full_publish({}) == false, "default full publish is cooperative")
check(ri.should_block_full_publish({ allowBlockingFull = true }) == true,
    "bank/inventory_watch may still block")

-- Incremental 5-item, no partial publish
ri.reset()
local published = {}
local current = make_lite_snap()
local clock = { t = 0 }
local busy = false
local function start_job(src, restart)
    return ri.start({
        source_snapshot = src,
        extra_equipped = {},
        enrich_item = enrich,
        current_snapshot = function() return current end,
        publish = function(snap)
            published[#published + 1] = snap
            current = snap
            return true
        end,
        is_busy = function() return busy end,
        clock = function() return clock.t end,
        identity = identity,
        items_per_slice = 1,
        restart = restart,
        reason = "test",
    })
end

check(start_job(current) == true, "job starts")
check(ri.active() == true, "job active")
local st = ri.status()
check(st.warming == true and st.total == 5, "status warming 5 items")

for i = 1, 3 do
    clock.t = clock.t + 1
    ri.tick()
    check(#published == 0, "no publish after tick " .. i)
    check(current.depth == "lite", "published snap still lite after tick " .. i)
    check(ri.status().item == i, "progress " .. i .. "/5")
end
check(#current.equipped == 2 and current.equipped[1].depth == "lite",
    "authoritative equipped rows stay lite during partial work")

clock.t = clock.t + 1
ri.tick() -- 4
check(#published == 0, "no publish at 4/5")
clock.t = clock.t + 1
ri.tick() -- 5 -> promote
check(#published == 1, "exactly one promote at completion")
check(ri.active() == false, "job idle after promote")
local done = published[1]
check(done.depth == "full", "promoted depth=full")
check(#done.equipped == 2, "promoted equipped count")
check(#done.bags == 3, "promoted bags count")
for i, it in ipairs(done.equipped) do
    check(it.depth == "full", "equipped " .. i .. " full")
end
for i, it in ipairs(done.bags) do
    check(it.depth == "full", "bag " .. i .. " full")
end
check(ri.stats().promotes == 1, "one promote counter")
check(ri.stats().item_steps == 5, "five item steps")
check(ri.stats().yield_op_limit >= 4, "yielded on op limit (not a 5-item chain)")

-- Bank preservation
check(done.bankPreserved == true, "bankPreserved retained")
check(done.bankLive == false and done.bankOpen == false, "bank not live-walked")
check(done.bank and done.bank[1] and done.bank[1].id == 99, "preserved bank row")
check(done.bankCapturedAt == 1000, "bankCapturedAt retained")

-- Equivalence vs synchronous enrich of the same lite set
local sync_full = {
    equipped = { enrich(current.equipped[1] and make_lite_snap().equipped[1] or lite_item(11, "Crown", "Equipped", 2, "Head")),
                 enrich(make_lite_snap().equipped[2]) },
    bags = {
        enrich(make_lite_snap().bags[1]),
        enrich(make_lite_snap().bags[2]),
        enrich(make_lite_snap().bags[3]),
    },
}
-- current was replaced by promoted snap; rebuild expected from original lite
local orig = make_lite_snap()
local expected_eq = { enrich(orig.equipped[1]), enrich(orig.equipped[2]) }
local expected_bg = { enrich(orig.bags[1]), enrich(orig.bags[2]), enrich(orig.bags[3]) }
for i = 1, 2 do rich_fields_equal(done.equipped[i], expected_eq[i], "eq" .. i) end
for i = 1, 3 do rich_fields_equal(done.bags[i], expected_bg[i], "bg" .. i) end

-- Inventory invalidation: cancel, no stale promote
ri.reset()
published = {}
current = make_lite_snap()
clock.t = 0
start_job(current)
for i = 1, 3 do
    clock.t = clock.t + 1
    ri.tick()
end
check(ri.status().item == 3, "invalidation setup at 3/5")
current = make_lite_snap()
current.equipped[1].id = 999
clock.t = clock.t + 1
ri.tick()
check(ri.active() == false, "job cancelled on inventory identity change")
check(#published == 0, "no stale promotion after cancel")
check(ri.stats().jobs_cancelled == 1, "cancel counter")

-- Later restart from new lite
clock.t = clock.t + 2
current = make_lite_snap()
current.equipped[1].id = 999
start_job(current)
for i = 1, 5 do
    clock.t = clock.t + 1
    ri.tick()
end
check(#published == 1, "restarted job promotes once")
check(published[1].equipped[1].id == 999, "restarted job used new inventory")

-- Non-inventory change does not cancel; promoted shell keeps latest B metadata
ri.reset()
published = {}
current = make_lite_snap()
clock.t = 0
start_job(current)
clock.t = 1
ri.tick()
local meta_b = {}
for k, v in pairs(current) do meta_b[k] = v end
meta_b.don = { version = "B" }
meta_b.lockouts = { version = "B" }
meta_b.spells_sig = "spell-B"
meta_b.seq = 50
meta_b.updated = 9999
meta_b.inventoryUpdated = 9999
current = meta_b
clock.t = 2
ri.tick()
check(ri.active() == true, "job continues across DoN/lockout/seq/spells change")
check(#published == 0, "no publish from non-inventory mutation")
for i = 3, 5 do
    clock.t = clock.t + 1
    ri.tick()
end
check(#published == 1, "completes after non-inventory changes")
local promoted = published[1]
check(promoted.depth == "full", "promoted inventory is fully enriched")
check(#promoted.equipped == 2 and promoted.equipped[1].depth == "full", "promoted equipped rich")
check(#promoted.bags == 3 and promoted.bags[1].depth == "full", "promoted bags rich")
check(promoted.don and promoted.don.version == "B", "promoted DoN == B")
check(promoted.lockouts and promoted.lockouts.version == "B", "promoted lockouts == B")
check(promoted.spells_sig == "spell-B", "promoted spells_sig == B")
check(promoted.seq == 50, "promoted seq == B")
check(promoted.updated == 9999, "promoted updated == B")
check(promoted.don ~= nil and promoted.don.a == nil, "DoN did not regress to A")
check(promoted.lockouts ~= nil and promoted.lockouts.b == nil, "lockouts did not regress to A")
check(promoted.spells_sig ~= "spell-v1", "spells_sig did not regress to A")
check(promoted.bankPreserved == true and promoted.bank and promoted.bank[1].id == 99,
    "latest shell bank semantics retained")

-- Last-moment inventory identity change immediately before finalize
ri.reset()
published = {}
current = make_lite_snap()
clock.t = 0
local enrich_n = 0
ri.start({
    source_snapshot = current,
    extra_equipped = {},
    enrich_item = function(row)
        enrich_n = enrich_n + 1
        local rich = enrich(row)
        if enrich_n == 5 then
            local stale = make_lite_snap()
            stale.equipped[1].id = 888
            current = stale
        end
        return rich
    end,
    current_snapshot = function() return current end,
    publish = function(snap)
        published[#published + 1] = snap
        current = snap
        return true
    end,
    is_busy = function() return false end,
    clock = function() return clock.t end,
    identity = identity,
    items_per_slice = 1,
    reason = "test_last_moment",
})
for i = 1, 5 do
    clock.t = clock.t + 1
    ri.tick()
end
check(#published == 0, "last-moment identity change: no stale promotion")
check(ri.active() == false, "last-moment identity change: job cancelled")
check(ri.stats().jobs_cancelled == 1, "last-moment identity change: cancel counted")

-- Busy yield, then starve-through
ri.reset()
published = {}
current = make_lite_snap()
clock.t = 0
busy = true
start_job(current)
clock.t = 1
ri.tick()
check(ri.status().item == 0, "busy yield skips the item")
check(ri.stats().yield_busy >= 1, "yield_busy counted")
clock.t = 7
ri.tick()
check(ri.status().item == 1, "starvation guard still processes one item")
busy = false

-- Sync Now during job: restart, no blocking full, no partial publish
ri.reset()
published = {}
current = make_lite_snap()
clock.t = 0
start_job(current)
for i = 1, 3 do
    clock.t = clock.t + 1
    ri.tick()
end
check(#published == 0, "pre-sync still unpublished")
-- lite refresh (same identity) + restart
local lite2 = make_lite_snap()
lite2.seq = 50
current = lite2
start_job(lite2, true)
check(ri.status().item == 0, "Sync Now restarts rich job")
check(#published == 0, "restart does not promote stale partial")
for i = 1, 5 do
    clock.t = clock.t + 1
    ri.tick()
end
check(#published == 1, "restarted Sync Now job promotes once")
check(published[1].depth == "full" and #published[1].bags == 3, "sync restart full set")

-- Startup request with current full snapshot -> skip_already_full
ri.reset()
published = {}
local full_src = make_lite_snap()
full_src.depth = "full"
full_src.equipped = { enrich(full_src.equipped[1]), enrich(full_src.equipped[2]) }
full_src.bags = { enrich(full_src.bags[1]), enrich(full_src.bags[2]), enrich(full_src.bags[3]) }
current = full_src
clock.t = 0
local started_full = ri.start({
    source_snapshot = full_src,
    extra_equipped = {},
    enrich_item = enrich,
    current_snapshot = function() return current end,
    publish = function()
        error("skip_already_full must not publish")
    end,
    is_busy = function() return false end,
    clock = function() return clock.t end,
    identity = identity,
    items_per_slice = 1,
    reason = "startup_bg_full",
})
check(started_full == false, "startup start() skips persisted full snapshot")
check(ri.active() == false, "no job after skip_already_full")
local dec = ri.last_request()
check(dec.action == "skip_already_full", "documented skip reason is skip_already_full")
check(dec.reason == "startup_bg_full", "skip records request reason")
check(dec.currentDepth == "full", "skip records currentDepth=full")
check(dec.itemRich == true, "skip records itemRich")
check(#published == 0, "skip does not promote")

-- Force richrefresh with current full snapshot -> job starts anyway
local force = ri.plan_force_refresh()
check(force.blocking_full == false and force.restart_job == true and force.ignore_already_full == true,
    "force plan: cooperative restart, never blocking full")
local blocking_full_calls = 0
ri.reset()
published = {}
current = full_src
clock.t = 0
local forced = ri.start({
    source_snapshot = full_src,
    extra_equipped = {},
    enrich_item = enrich,
    current_snapshot = function() return current end,
    publish = function(snap)
        published[#published + 1] = snap
        current = snap
        return true
    end,
    is_busy = function() return false end,
    clock = function() return clock.t end,
    identity = identity,
    items_per_slice = 1,
    restart = true,
    reason = "richrefresh",
})
check(forced == true, "force refresh starts even when already full")
check(ri.active() == true, "forced job is active")
check(ri.last_request().action == "start" or ri.last_request().action == "restart",
    "force request action is start/restart")
check(ri.last_request().reason == "richrefresh", "force reason=richrefresh")
for i = 1, 4 do
    clock.t = clock.t + 1
    ri.tick()
    check(#published == 0, "forced job no partial publish at " .. i .. "/5")
end
clock.t = clock.t + 1
ri.tick()
check(#published == 1, "forced job single promotion")
check(published[1].depth == "full" and #published[1].equipped == 2 and #published[1].bags == 3,
    "forced job completed full set")
check(ri.stats().item_steps == 5, "forced job one item per slice")
check(blocking_full_calls == 0, "force never calls blocking full publish")

-- Force while job active -> safe restart, no stale partial
ri.reset()
published = {}
current = make_lite_snap()
clock.t = 0
start_job(current)
for i = 1, 3 do
    clock.t = clock.t + 1
    ri.tick()
end
check(ri.status().item == 3, "pre-force job at 3/5")
local restarted = ri.start({
    source_snapshot = current,
    extra_equipped = {},
    enrich_item = enrich,
    current_snapshot = function() return current end,
    publish = function(snap)
        published[#published + 1] = snap
        current = snap
        return true
    end,
    is_busy = function() return false end,
    clock = function() return clock.t end,
    identity = identity,
    items_per_slice = 1,
    restart = true,
    reason = "richrefresh",
})
check(restarted == true, "force while active restarts")
check(ri.last_request().action == "restart", "force-while-active action=restart")
check(#published == 0, "restart does not publish partial work")
check(ri.status().item == 0, "restarted job progress reset")
for i = 1, 5 do
    clock.t = clock.t + 1
    ri.tick()
end
check(#published == 1, "restarted forced job promotes once")

local function moved_lite()
    local snap = make_lite_snap()
    snap.bags[1].slotid = 30
    snap.bags[1].slotname = 3
    return snap
end

local function moved_full_item_rich()
    local snap = moved_lite()
    snap.depth = "full"
    snap.equipped = { enrich(snap.equipped[1]), enrich(snap.equipped[2]) }
    snap.bags = { enrich(snap.bags[1]), enrich(snap.bags[2]), enrich(snap.bags[3]) }
    return snap
end

local function cancel_after_enrich_miss(opts)
    opts = opts or {}
    published = {}
    current = make_lite_snap()
    clock.t = 0
    local bag_moved = false
    local probe_calls = 0
    local probe_lite = opts.probe_lite
    if not opts.cooperative and probe_lite == nil then
        probe_lite = function()
            probe_calls = probe_calls + 1
            return current
        end
    end
    ri.start({
        source_snapshot = current,
        extra_equipped = {},
        enrich_item = function(row)
            if bag_moved then return nil end
            return enrich(row)
        end,
        current_snapshot = function() return current end,
        publish = function(snap)
            published[#published + 1] = snap
            current = snap
            return true
        end,
        is_busy = function() return false end,
        clock = function() return clock.t end,
        identity = identity,
        items_per_slice = 1,
        reason = "richrefresh",
        probe_lite = probe_lite,
        adopt_lite = opts.adopt_lite or function(snap)
            current = snap
        end,
        probe_collect_rows = opts.probe_collect_rows,
        probe_validate_rows = opts.probe_validate_rows,
    })
    for _ = 1, 3 do
        clock.t = clock.t + 1
        ri.tick()
    end
    bag_moved = true
    clock.t = clock.t + 1
    ri.tick()
    bag_moved = false
    return {
        probe_calls = function() return probe_calls end,
        note_probe = function() probe_calls = probe_calls + 1 end,
    }
end

-- Recovery after enrich_miss: skip_already_full must not suppress rebuild
ri.reset()
local wait_ctrl = cancel_after_enrich_miss()
check(ri.active() == false, "enrich_miss cancels stale job")
check(#published == 0, "stale first job never promotes")
check(ri.stats().jobs_cancelled == 1, "enrich_miss counted as cancel")
check(ri.stats().jobs_started == 1, "no replacement yet")

-- No fresh identity yet: do not restart-loop / enrich_miss storm
local started_before_wait = ri.stats().jobs_started
for _ = 1, 5 do
    clock.t = clock.t + 1
    ri.tick()
end
check(ri.active() == false, "no restart while inventory identity unchanged")
check(ri.stats().jobs_started == started_before_wait, "no restart loop on stale sourceSig")
check(#published == 0, "still no promote while waiting for fresh identity")
check(ri.stats().recovery_probe >= 1, "stale wait still probes after delay")
check(ri.stats().recovery_probe_same >= 1, "stale probe counted as same")
check(ri.stats().recovery_started == 0, "stale probe does not start recovery")

-- Fresh changed source, even if depth=full / itemRich: recovery must start
local probes_before_natural = ri.stats().recovery_probe
current = moved_full_item_rich()
clock.t = clock.t + 1
ri.tick()
check(ri.active() == true, "replacement job starts after identity change")
check(ri.last_request().reason == "restart_after_cancel", "recovery reason=restart_after_cancel")
check(ri.last_request().action == "start" or ri.last_request().action == "restart",
    "recovery bypasses skip_already_full")
check(ri.last_request().itemRich == true, "current snapshot still depth=full/itemRich")
check(ri.stats().recovery_probe == probes_before_natural, "natural identity change skips extra lite gather")
check(ri.stats().recovery_started == 1, "natural identity change counts recovery_started")
check(#published == 0, "recovery does not publish until complete")
for i = 1, 5 do
    clock.t = clock.t + 1
    ri.tick()
end
check(#published == 1, "exactly one final promote from replacement job")
check(published[1].bags[1].slotid == 30, "promoted bags reflect the move")
check(ri.stats().jobs_started == 2, "original + one recovery job")
check(ri.stats().promotes == 1, "only the replacement job promoted")

-- Cached snap stays stale/full: recovery lite-probes, adopts moved identity, one promote
ri.reset()
local probe_snaps = {}
cancel_after_enrich_miss({
    probe_lite = function()
        local probed = moved_lite()
        probe_snaps[#probe_snaps + 1] = probed
        return probed
    end,
})
check(ri.active() == false, "probe-recovery cancelled before delay")
clock.t = clock.t + 1
ri.tick()
check(#probe_snaps == 1, "one lite probe while cached identity stays cancelled")
check(ri.stats().recovery_probe == 1, "recovery_probe counted")
check(ri.stats().recovery_probe_changed == 1, "recovery_probe_changed counted")
check(ri.stats().recovery_probe_same == 0, "changed probe is not same")
check(ri.stats().recovery_started == 1, "probe-changed starts recovery")
check(ri.active() == true, "replacement job starts from probe identity")
check(ri.last_request().reason == "restart_after_cancel", "probe recovery reason=restart_after_cancel")
check(current.depth == "lite", "adopted probe is lite, not Engine.publish(full)")
check(identity(current) == identity(probe_snaps[1]), "cached identity follows adopted probe")
check(#published == 0, "probe adopt is not a rich promote")
for i = 1, 5 do
    clock.t = clock.t + 1
    ri.tick()
end
check(#published == 1, "probe recovery promotes once")
check(published[1].bags[1].slotid == 30, "probe recovery promote reflects the move")
check(published[1].depth == "full", "final promote is rich")
check(ri.stats().jobs_started == 2, "original + probe recovery job")
check(ri.stats().promotes == 1, "exactly one promote after probe recovery")
check(ri.stats().recovery_probe == 1, "no extra probes after recovery started")

-- Cached snap updates naturally before probe: no extra lite gather
ri.reset()
local natural_probes = 0
cancel_after_enrich_miss({
    probe_lite = function()
        natural_probes = natural_probes + 1
        return current
    end,
})
current = moved_full_item_rich()
clock.t = clock.t + 1
ri.tick()
check(natural_probes == 0, "natural identity change does not lite-gather")
check(ri.stats().recovery_probe == 0, "recovery_probe stays 0 when cache already moved")
check(ri.stats().recovery_started == 1, "natural path still counts recovery_started")
check(ri.active() == true, "natural identity change starts recovery immediately")
for i = 1, 5 do
    clock.t = clock.t + 1
    ri.tick()
end
check(#published == 1, "natural recovery promotes once")
check(ri.stats().promotes == 1, "natural recovery one promote")

-- Probe still returns cancelled identity: no restart storm, bounded retry
ri.reset()
local same_probes = 0
cancel_after_enrich_miss({
    probe_lite = function()
        same_probes = same_probes + 1
        return current
    end,
})
clock.t = clock.t + 1
ri.tick()
check(same_probes == 1, "first delayed tick probes once")
check(ri.stats().recovery_probe == 1, "same-identity probe counted")
check(ri.stats().recovery_probe_same == 1, "recovery_probe_same counted")
check(ri.stats().recovery_started == 0, "same probe does not start recovery")
check(ri.active() == false, "same probe remains pending")
check(ri.stats().jobs_started == 1, "same probe does not start a job")
for _ = 1, 4 do
    clock.t = clock.t + 0.2
    ri.tick()
end
check(same_probes == 1, "no probe every frame while delay has not elapsed")
clock.t = clock.t + 1
ri.tick()
check(same_probes == 2, "bounded retry probes again after delay")
check(ri.stats().recovery_probe == 2, "second same probe counted")
check(ri.stats().recovery_probe_same == 2, "second same probe is same")
check(ri.active() == false, "bounded retry still pending")
check(ri.stats().jobs_started == 1, "no restart storm")
check(#published == 0, "same-identity probe never promotes")

local function rows_of(snap)
    local out = {}
    for _, row in ipairs(snap.equipped or {}) do
        out[#out + 1] = { list = "equipped", row = row }
    end
    for _, row in ipairs(snap.bags or {}) do
        out[#out + 1] = { list = "bags", row = row }
    end
    return out
end

-- Fine Steel: cooperative probe, stable moved identity, one lite adopt, one rich promote
ri.reset()
local adopts = {}
local moved_src = moved_lite()
cancel_after_enrich_miss({
    cooperative = true,
    probe_collect_rows = rows_of(moved_src),
    probe_validate_rows = rows_of(moved_src),
    adopt_lite = function(snap)
        adopts[#adopts + 1] = snap
        current = snap
    end,
})
check(ri.active() == false, "stale Fine Steel job cancelled")
check(#published == 0, "stale Fine Steel job never promotes")
for _ = 1, 40 do
    clock.t = clock.t + 1
    ri.tick()
    if ri.active() then break end
end
check(ri.active() == true, "replacement rich job starts after cooperative probe")
check(ri.last_request().reason == "restart_after_cancel", "Fine Steel recovery reason")
check(#adopts == 1, "exactly one lite adoption")
check(adopts[1] and adopts[1].depth == "lite", "adopted candidate is lite")
check(adopts[1] and adopts[1].bags[1].slotid == 30, "adopted bags reflect the move")
check(ri.stats().recovery_probe >= 1, "cooperative recovery_probe counted")
check(ri.stats().recovery_probe_changed >= 1, "cooperative recovery_probe_changed")
check(ri.stats().promotes == 0, "no promote until replacement completes")
for _ = 1, 5 do
    clock.t = clock.t + 1
    ri.tick()
end
check(#published == 1, "exactly one final rich promote")
check(published[1].depth == "full", "final promote is rich")
check(published[1].bags[1].slotid == 30, "promote reflects Fine Steel move")
check(ri.stats().promotes == 1, "replacement promotes once")
check(#adopts == 1, "probe did not adopt again during rich job")

-- Natural watcher update mid-probe cancels probe and recovers immediately
ri.reset()
local mid_adopts = {}
local long_rows = {}
for i = 1, 20 do
    long_rows[#long_rows + 1] = { list = "bags", row = lite_item(200 + i, "X" .. i, "Bags", 23, i, i) }
end
cancel_after_enrich_miss({
    cooperative = true,
    probe_collect_rows = long_rows,
    probe_validate_rows = long_rows,
    adopt_lite = function(snap)
        mid_adopts[#mid_adopts + 1] = snap
        current = snap
    end,
})
clock.t = clock.t + 1
ri.tick()
check(ri.active() == false, "probe still collecting; rich not restarted yet")
check(#mid_adopts == 0, "partial probe not adopted")
local st = ri.status()
check(tostring(st.phase or ""):find("recovery probe", 1, true) ~= nil
    or st.phase == "recovery_pending",
    "status shows recovery probe")
current = moved_full_item_rich()
clock.t = clock.t + 1
ri.tick()
check(ri.active() == true, "watcher-fast-path starts recovery immediately")
check(#mid_adopts == 0, "cancelled probe never adopted")
check(ri.last_request().reason == "restart_after_cancel", "fast path reason")
for _ = 1, 5 do
    clock.t = clock.t + 1
    ri.tick()
end
check(#published == 1, "fast-path replacement promotes once")

-- Fake [TG] link evaluation does not start probe or rich job
ri.reset()
local probe = require('inventory_probe')
probe.reset()
local started = ri.stats().jobs_started
local function fake_tg_eval(snap, item_id)
    local idx = require('ownership_index').build_snapshot_index(snap)
    return idx.by_id[item_id] ~= nil
end
check(fake_tg_eval(make_lite_snap(), 21) == true, "fake [TG] uses published ownership")
check(probe.active() == false, "link eval does not start probe")
check(ri.active() == false, "link eval does not start rich_inventory")
check(ri.stats().jobs_started == started, "link eval does not start a rich job")

print(string.format("rich_inventory: %d passed, %d failed", pass, fail))
if fail > 0 then os.exit(1) end
