-- Run from repo root: luajit lua/tests/turbogear_elapsed_deadlines_test.lua
-- User-facing [TG] deadlines and item_index TTL use injectable elapsed time.
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

local state_stub = { bg = false, lean = function() return false end }
local CFG = {
    generated_authority_enabled = true,
    core_ownership_emit_wait_s = 2.0,
    core_ownership_warm_budget_ms = 2,
    core_ownership_warm_steps = 2,
    needs_index_enabled = true,
}
package.preload['config'] = function()
    return { CFG = CFG, Settings = {}, SharedSettings = { bisAnnounceEnabled = true },
        LoadSharedSettings = function() end, bis_announce_command = function() return "/g" end }
end
package.preload['state'] = function() return state_stub end
package.preload['needs_index'] = function()
    return {
        char_count = function() return 0 end, ready = function() return false end,
        needers_for = function() return {} end, text_needs = function() return {} end,
        needs_tick = function() return false end, tick = function() end,
        status = function() return {} end, oldest_queue_age_s = function() return 0 end,
    }
end
package.preload['bis_catalog'] = function()
    return {
        catalog_loaded = function() return true end,
        warm_catalog = function() return true end,
        announce_catalog_ready = function() return true end,
        clean_link_item_name = function(n) return n end,
        generated_builtin_compact_candidates_for_link = function()
            return {{
                enabled = true,
                link_matched = true,
                matched_by = "id",
                item_name = "Need Ring",
                list_id = "test",
                list_name = "test",
                entry = { item = "Need Ring", id = 9 },
                satisfy = { item = "Need Ring", id = 9 },
            }}, "ok", { raw_count = 1 }
        end,
    }
end
package.preload['snapshot'] = function()
    return { cached = function() return { name = "Emit", class = "WAR" } end,
        lite_age = function() return 0 end, gather = function() return { name = "Emit", class = "WAR" } end }
end
package.preload['item_actions'] = function() return {
    looks_like_item_link = function() return false end, remember_item_link = function() end,
    resolve_announce_link = function() return "" end, observed_link_count = function() return 0 end } end

local samples, counts = {}, {}
package.preload['diagnostics'] = function() return {
    time = function(_, fn) return fn() end,
    count = function(k, n) counts[k] = (counts[k] or 0) + (tonumber(n) or 1) end,
    event = function() end,
    sample = function(k, v) samples[k] = tonumber(v) or 0 end,
    is_enabled = function() return true end } end
package.preload['store'] = function() return { Store = {
    peer_keys = function() return {} end, get = function() return nil end,
    is_recently_visible = function() return false end } } end
package.preload['inventory_watch'] = function()
    return { inventory_settling = function() return false end }
end
package.preload['engine'] = function()
    return { Engine = { debug = false, request_loot_replay = function() end } }
end
package.preload['item_index'] = function()
    return { tick = function() end, get = function() return {}, 0 end }
end
package.preload['roster_sets'] = function()
    return {
        active_store_keys = function() return {} end,
        scope_label = function() return "online" end,
    }
end
package.preload['mq'] = function() return {
    LinkTypes = { Item = "item" },
    TLO = { Me = { CleanName = function() return "Emit" end },
        MacroQuest = { Server = function() return "Srv" end },
        EverQuest = { GameState = function() return "INGAME" end },
        Zone = { ShortName = function() return "z" end } },
    ExtractLinks = function() return {} end, ParseItemLink = function() return nil end,
    cmd = function() end, cmdf = function() end, delay = function() end } end

local policy = require('index_warm_policy')
local A = require('announcer')
A.set_passive(false)
local hooks = A._diet_a_hooks()
local idxmod = require('ownership_index')
idxmod.tick_snapshot_warm = function()
    return false, { completed = false }
end

local pass, fail = 0, 0
local function check(c, m) if c then pass = pass + 1 else fail = fail + 1; print("  FAIL: " .. tostring(m)) end end

local fake = 0
local function set_fake(t)
    fake = t
end
policy._set_elapsed_s_for_tests(function() return fake end)
hooks.set_elapsed_s(function() return fake end)

local function empty_snap(name)
    return {
        server = "Srv",
        name = name,
        class = "Warrior",
        equipped = {},
        bags = {},
        bank = {},
    }
end

local function row_for(snap)
    return { key = "Srv_" .. tostring(snap.name), snap = snap, local_owner = false }
end

local function make_job(rows, started)
    return {
        item_name = "Need Ring",
        item_id = 9,
        item_link = "",
        chat_at = 0,
        elapsed_at = started,
        source = "chat",
        rows = rows,
        index = 1,
        order = {},
        name_map = {},
        sources = {},
        details = {},
        snaps = 0,
        authority_started = started,
        pending_warm = {},
    }
end

local function has_name(order, name)
    for _, who in ipairs(order or {}) do
        if tostring(who) == name then return true end
    end
    return false
end

local function details_have(job, needle)
    local blob = table.concat(job and job.details or {}, " ")
    return blob:find(needle, 1, true) ~= nil
end

-- 1. ITEM_INDEX TTL
policy._reset_for_tests()
set_fake(0)
policy._set_elapsed_s_for_tests(function() return fake end)
policy.request_item_index("search", 3)
set_fake(2.9)
check(policy.item_index_requested() == true, "1: requested at 2.9s")
set_fake(3.1)
check(policy.item_index_requested() == false, "1: expired at 3.1s")

-- 2. TTL REFRESH
policy._reset_for_tests()
set_fake(0)
policy._set_elapsed_s_for_tests(function() return fake end)
policy.request_item_index("stats", 3)
set_fake(2)
policy.request_item_index("stats", 3)
set_fake(4)
check(policy.item_index_requested() == true, "2: refreshed demand still live at t=4")
set_fake(5.1)
check(policy.item_index_requested() == false, "2: refreshed demand expired after t=5")
policy._reset_for_tests()

-- 3. [TG] WARM OWNERSHIP
set_fake(100)
local warm = empty_snap("Warm")
idxmod.cached_snapshot_index(warm)
local need, why = hooks.need_for_row(row_for(warm), "Need Ring", 9, "test")
check(why ~= "ownership-warming", "3: cached ownership evaluates immediately")
check(type(need) == "table", "3: cached empty owner is a needer")
hooks.set_driver_job(make_job({ row_for(warm) }, fake))
hooks.step_driver_link_job(os.clock() + 1)
check(hooks.get_driver_job() == nil, "3: warm job finishes without waiting")
local finished = hooks.last_finished_job()
check(has_name(finished and finished.order, "Warm"), "3: warm needer is in the result")

-- 4. [TG] COLD OWNERSHIP resolves before deadline
set_fake(200)
counts["core_ownership.emit_deferred_miss"] = 0
local cold = empty_snap("Cold")
local built = 0
local real_build = idxmod.build_snapshot_index
idxmod.build_snapshot_index = function(snap)
    built = built + 1
    return real_build(snap)
end
hooks.set_driver_job(make_job({ row_for(cold) }, fake))
hooks.step_driver_link_job(os.clock() + 1)
local leftover = hooks.get_driver_job()
check(leftover ~= nil, "4: cold miss keeps the job open")
check(#(leftover.pending_warm or {}) > 0, "4: cold miss is deferred")
check(built == 0, "4: emit path does not call build_snapshot_index")
check((counts["core_ownership.emit_deferred_miss"] or 0) > 0, "4: cooperative warm queued")
set_fake(200.5)
idxmod.cached_snapshot_index(cold)
hooks.step_driver_link_job(os.clock() + 1)
check(hooks.get_driver_job() == nil, "4: job finishes after ownership publishes")
finished = hooks.last_finished_job()
check(has_name(finished and finished.order, "Cold"), "4: warmed peer is evaluated before deadline")

-- 5. TOTAL LINK DEADLINE from job start, not per peer
set_fake(300)
local miss_a = empty_snap("MissA")
local miss_b = empty_snap("MissB")
hooks.set_driver_job(make_job({ row_for(miss_a), row_for(miss_b) }, fake))
hooks.step_driver_link_job(os.clock() + 1)
leftover = hooks.get_driver_job()
check(leftover ~= nil, "5: missing peers keep the job open")
set_fake(301.9)
hooks.step_driver_link_job(os.clock() + 1)
leftover = hooks.get_driver_job()
check(leftover ~= nil, "5: job still retries just before the 2s total deadline")
set_fake(302.1)
counts["generated_authority.ownership_timeout"] = 0
hooks.step_driver_link_job(os.clock() + 1)
check(hooks.get_driver_job() == nil, "5: job completes after the total 2s deadline")
finished = hooks.last_finished_job()
check(not has_name(finished and finished.order, "MissA"), "5: unresolved MissA omitted")
check(not has_name(finished and finished.order, "MissB"), "5: unresolved MissB omitted")
check((counts["generated_authority.ownership_timeout"] or 0) >= 2, "5: both unresolved peers time out")
check(details_have(finished, "timeout"), "5: timeout is recorded on the job")
check(finished and finished.outcome == "ABORTED", "5: terminal unresolved is explicit ABORTED")

-- 6. STUCK PEER cannot hold the job; cached peers still announce
set_fake(400)
local ready = empty_snap("Ready")
local stuck = empty_snap("Stuck")
idxmod.cached_snapshot_index(ready)
hooks.set_driver_job(make_job({ row_for(ready), row_for(stuck) }, fake))
hooks.step_driver_link_job(os.clock() + 1)
leftover = hooks.get_driver_job()
check(leftover ~= nil, "6: stuck peer keeps the job open")
check(has_name(leftover.order, "Ready"), "6: cached peer is already a needer")
check(not has_name(leftover.order, "Stuck"), "6: stuck peer is not guessed as a needer")
set_fake(402.1)
hooks.step_driver_link_job(os.clock() + 1)
check(hooks.get_driver_job() == nil, "6: job completes after the total deadline")
finished = hooks.last_finished_job()
check(has_name(finished and finished.order, "Ready"), "6: cached needer survives the stuck peer")
check(not has_name(finished and finished.order, "Stuck"), "6: stuck peer is omitted at deadline")
check(details_have(finished, "Stuck=timeout"), "6: stuck peer records ownership timeout")
check(finished and finished.outcome == "ABORTED", "6: partial needer set is held and job aborts")
check((counts["generated_authority.aborted"] or 0) > 0, "6: abort has an explicit diagnostic counter")

-- 7. LATENCY METRIC CLOCK
set_fake(10)
samples["generated_authority.link_to_send_ms"] = nil
hooks.sample_elapsed_ms("generated_authority.link_to_send_ms", 10)
check((samples["generated_authority.link_to_send_ms"] or -1) == 0, "7: zero elapsed is 0ms")
set_fake(10.125)
hooks.sample_elapsed_ms("generated_authority.link_to_enqueue_ms", 10)
hooks.sample_elapsed_ms("generated_authority.link_to_send_ms", 10)
local send_ms = samples["generated_authority.link_to_send_ms"] or -1
local enqueue_ms = samples["generated_authority.link_to_enqueue_ms"] or -1
check(math.abs(send_ms - 125) < 0.01, "7: link_to_send reports ~125 elapsed ms")
check(math.abs(enqueue_ms - 125) < 0.01, "7: link_to_enqueue reports ~125 elapsed ms")
samples["generated_authority.decision_ms"] = nil
local decision_started = fake
set_fake(10.200)
hooks.sample_elapsed_ms("generated_authority.decision_ms", decision_started)
check(math.abs((samples["generated_authority.decision_ms"] or -1) - 75) < 0.01,
    "7: decision_ms uses the same elapsed source")

print(string.format("elapsed deadlines: %d passed, %d failed", pass, fail))
os.exit(fail == 0 and 0 or 1)
