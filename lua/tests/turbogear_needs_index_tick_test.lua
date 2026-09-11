-- Run from repo root: luajit lua/tests/turbogear_needs_index_tick_test.lua
-- Cooperative needs_index.tick: catalog/index waits, resumable eval, no partial publish.
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

for _, name in ipairs({
    "mq", "config", "store", "diagnostics", "roster_sets", "bis_catalog", "bis",
    "ownership_index", "needs_index",
}) do
    package.loaded[name] = nil
    package.preload[name] = nil
end

package.preload["mq"] = function()
    return {
        TLO = {
            Me = { CleanName = function() return "Tester" end },
            MacroQuest = { Server = function() return "Srv" end },
        },
    }
end
package.preload["config"] = function()
    return {
        CFG = {
            perf_needs_settle = false,
            needs_eval_ops_per_slice = 1,
            needs_list_steps_per_slice = 1,
            needs_rotate_eval_slices = 1000,
        },
        Settings = {},
        SharedSettings = {},
    }
end

local snaps = {}
local signatures = {}
local store_tbl = {
    content_version = 1,
    content_signatures = signatures,
    peer_keys = function() return {} end,
    get = function(k) return snaps[k] end,
    is_recently_visible = function() return true end,
}
package.preload["store"] = function()
    return {
        Store = store_tbl,
        my_key = function() return "Srv_Tester" end,
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
package.preload["roster_sets"] = function()
    return {
        active_store_keys = function() return { "Srv_Tester" } end,
        scope_label = function() return "" end,
    }
end

local entry_sword = { item = "Blade of War", names = { "Blade of War", "War Blade", "BoW" }, ids = { 101, 102 } }
local entry_helm  = { item = "Crown of Rile", names = { "Crown of Rile" }, ids = { 202 } }
local entry_owned = { item = "Owned Thing", names = { "Owned Thing" }, ids = { 303 } }
local recs = {
    { entry = entry_sword, item_name = "Blade of War", list_id = "anguish" },
    { entry = entry_helm, item_name = "Crown of Rile", list_id = "anguish" },
    { entry = entry_owned, item_name = "Owned Thing", list_id = "anguish" },
}
local catalog_ready = false
local catalog_calls = 0
local catalog_steps_needed = 3
local catalog_steps = 0
local catalog_building = false
package.preload["bis_catalog"] = function()
    local idx = { by_name = { anguish = recs }, by_id = {}, list_count = 1, catalog_entries = 3 }
    return {
        tick_direct_build = function()
            catalog_calls = catalog_calls + 1
            if not catalog_ready then return nil end
            if catalog_steps < catalog_steps_needed then
                catalog_building = true
                catalog_steps = catalog_steps + 1
                return nil
            end
            catalog_building = false
            return idx
        end,
        direct_catalog_for = function()
            return catalog_ready and catalog_steps >= catalog_steps_needed and idx or nil
        end,
        direct_build_in_progress = function()
            return catalog_building
        end,
    }
end
package.preload["bis"] = function()
    return {
        snap_entry_status = function(entry)
            if entry == entry_owned then return "equipped" end
            return "missing"
        end,
    }
end

package.preload["ownership_index"] = nil

local NI = require("needs_index")
local idxmod = require("ownership_index")

local pass, fail = 0, 0
local function check(cond, msg)
    if cond then pass = pass + 1 else fail = fail + 1; print("FAIL: " .. tostring(msg)) end
end

snaps["Srv_Tester"] = {
    name = "Tester",
    server = "Srv",
    class = "Warrior",
    equipped = { { name = "Owned Thing", id = 303, augs = {} } },
    bags = {},
    bank = {},
    spells_sig = "sp1",
    lockouts = { DoNState = { capturedAt = 1 }, Expeditions = {} },
    seq = 1,
}
signatures["Srv_Tester"] = "content-sig-v1"

local function drain(max_ticks)
    local st
    for i = 1, max_ticks do
        NI.tick(50, { allow_peers = true })
        st = NI.status()
        if st.ready and st.chars >= 1 and not st.building_key then return st, i end
    end
    return st, max_ticks
end

local function bump_store()
    store_tbl.content_version = (tonumber(store_tbl.content_version) or 1) + 1
end

NI.invalidate("test")
catalog_ready = false
catalog_calls = 0
catalog_steps = 0
NI.tick(50, { allow_peers = true })
local st = NI.status()
check(st.queued >= 1, "catalog wait keeps the character queued")
check(st.chars == 0, "partial/deferred build is not published as complete")
check(st.building_key == nil, "catalog wait does not start evaluation")

catalog_ready = true
local catalog_ticks = 0
for _ = 1, 10 do
    catalog_ticks = catalog_ticks + 1
    NI.tick(50, { allow_peers = true })
    if catalog_steps >= catalog_steps_needed then break end
end
check(catalog_steps == catalog_steps_needed, "large list takes multiple list steps")
check(catalog_ticks >= catalog_steps_needed, "catalog resumability does not gulp the list")

st = NI.status()
check(st.chars == 0, "ownership wait still unpublished")

local finished, ticks = drain(120)
check(finished and finished.ready == true, "incremental build eventually completes")
check(finished.chars == 1, "one character published")
check(finished.building_key == nil, "no in-progress build after complete")
check((finished.builds_started or 0) >= 1 and (finished.builds_finished or 0) >= 1,
    "start/finish recorded")
check(ticks > 3, "tiny op limit resumes across ticks, got " .. tostring(ticks))
check((finished.eval_yield_op_limit or 0) > 0 or ticks > 5,
    "evaluator yields on op limit or many slices")

local expected = NI.core.build_char_needs(recs, function(e)
    if e == entry_owned then return "equipped" end
    return "missing"
end)
local needers = NI.needers_for("Blade of War", 101)
check(#needers == 1 and needers[1].character == "Tester",
    "completed result matches old deterministic missing-sword need")
check(#NI.needers_for("Owned Thing", 303) == 0, "owned entry is not a need")
check(expected.count == 2, "core baseline still two missing entries")

-- Atomic publication: old complete result stays visible during rebuild.
local old_sword = #NI.needers_for("Blade of War", 101)
snaps["Srv_Tester"].equipped = {
    { name = "Owned Thing", id = 303, augs = {} },
    { name = "Extra", id = 404, augs = {} },
}
idxmod.invalidate_snapshot_cache(snaps["Srv_Tester"])
idxmod.invalidate_snapshot_index(snaps["Srv_Tester"])
bump_store()
NI.tick(50, { allow_peers = true })
st = NI.status()
check(#NI.needers_for("Blade of War", 101) == old_sword,
    "half-complete rebuild keeps last complete needs visible")
check(st.chars == 1, "published char map is not cleared mid-rebuild")

finished = drain(120)
check(finished and finished.ready == true, "rebuild after ownership change completes")
check(#NI.needers_for("Blade of War", 101) == 1, "rebuilt result still has the sword need")

-- Non-semantic freshness: seq/DoN/lockout must not restart a build.
NI.invalidate("nonsem")
catalog_ready = true
catalog_steps = catalog_steps_needed
idxmod.invalidate_snapshot_index(snaps["Srv_Tester"])
idxmod.invalidate_snapshot_cache(snaps["Srv_Tester"])
bump_store()
local warmed = false
for _ = 1, 40 do
    NI.tick(50, { allow_peers = true })
    st = NI.status()
    if st.building_key and (st.building_i or 0) >= 1 then
        warmed = true
        break
    end
end
check(warmed, "reached an in-progress eval")
local i_before = st.building_i
snaps["Srv_Tester"].seq = 99
snaps["Srv_Tester"].lockouts.DoNState.capturedAt = 9
snaps["Srv_Tester"].lockouts.Expeditions = { Foo = { found = true } }
bump_store()
NI.tick(50, { allow_peers = true })
st = NI.status()
check(st.building_key ~= nil, "seq/DoN/lockout change does not discard the build")
check((st.building_i or 0) >= i_before, "seq/DoN/lockout change does not restart eval from 1")

finished = drain(120)
check(finished and finished.ready == true, "build finishes after non-semantic stamps")

-- Semantic ownership change mid-build discards the partial job.
NI.invalidate("sem")
catalog_ready = true
catalog_steps = catalog_steps_needed
idxmod.invalidate_snapshot_index(snaps["Srv_Tester"])
idxmod.invalidate_snapshot_cache(snaps["Srv_Tester"])
bump_store()
warmed = false
for _ = 1, 40 do
    NI.tick(50, { allow_peers = true })
    st = NI.status()
    if st.building_key and (st.building_i or 0) >= 1 then
        warmed = true
        break
    end
end
check(warmed, "reached in-progress eval before semantic change")
snaps["Srv_Tester"].equipped = { { name = "Other", id = 505, augs = {} } }
idxmod.invalidate_snapshot_cache(snaps["Srv_Tester"])
idxmod.invalidate_snapshot_index(snaps["Srv_Tester"])
bump_store()
NI.tick(50, { allow_peers = true })
st = NI.status()
check((st.building_i or 0) <= 1 or st.building_key == nil,
    "ownership change discards/restarts the partial build")

finished = drain(120)
check(finished and finished.ready == true, "rebuild after mid-eval ownership change completes")

print(string.format("needs_index tick: %d passed, %d failed", pass, fail))
if fail > 0 then os.exit(1) end
