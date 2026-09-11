-- Run from repo root: luajit lua/tests/turbogear_core_diet_a_tg_defer_test.lua
-- Cold [TG] ownership miss defers; never evaluates empty ownership.
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

local state_stub = { bg = false, lean = function() return false end }
local CFG = {
    generated_authority_enabled = true,
    generated_authority_cold_fallback = true,
    generated_authority_cold_fallback_budget_ms = 6,
    generated_authority_cold_fallback_max_rows = 4,
    generated_authority_ready_fast_path = true,
    core_ownership_emit_wait_s = 0.25,
    core_ownership_warm_budget_ms = 2,
    core_ownership_warm_steps = 2,
    needs_index_enabled = true,
}
local fallback_names = {}
local sent = {}
local fake = 1000
local work_now, candidate_cost, candidate_elapsed_cost = 0, 0, 0
local candidate_calls, broad_fallback_calls, targeted_calls = 0, 0, 0
local candidate_observer = nil
local generated_resident, generated_load_calls = false, 0
package.preload['config'] = function()
    return { CFG = CFG, Settings = {}, SharedSettings = { bisAnnounceEnabled = true },
        LoadSharedSettings = function() end, bis_announce_command = function() return "/g" end }
end
package.preload['state'] = function() return state_stub end
package.preload['needs_index'] = function()
    return {
        char_count = function() error("A2 path called needs_index.char_count") end,
        ready = function() error("A2 path called needs_index.ready") end,
        needers_for = function() error("A2 path called needs_index.needers_for") end,
        text_needs = function() error("A2 path called needs_index.text_needs") end,
        needs_tick = function() error("A2 path called needs_index.needs_tick") end,
        tick = function() error("A2 path called needs_index.tick") end,
        status = function() error("A2 path called needs_index.status") end,
        oldest_queue_age_s = function() error("A2 path called needs_index.oldest_queue_age_s") end,
    }
end
package.preload['bis_catalog'] = function()
    return {
        catalog_loaded = function() return true end,
        warm_catalog = function() return true end,
        generated_builtin_index_ready = function() return generated_resident end,
        warm_generated_builtin_index = function()
            generated_load_calls = generated_load_calls + 1
            generated_resident = true
            return {}, "ok"
        end,
        announce_catalog_ready = function() return true end,
        clean_link_item_name = function(n) return n end,
        generated_builtin_compact_candidates_for_link = function(_, item_name, item_id)
            candidate_calls = candidate_calls + 1
            if type(candidate_observer) == "function" then candidate_observer() end
            work_now = work_now + candidate_cost
            fake = fake + candidate_elapsed_cost
            item_name = tostring(item_name or "Need Ring")
            item_id = tonumber(item_id) or 9
            local entry = { item = item_name, id = item_id, names = { item_name }, ids = { item_id } }
            return {{
                enabled = true,
                link_matched = true,
                matched_by = "id",
                item_name = item_name,
                list_id = "test",
                list_name = "test",
                entry = entry,
                satisfy = entry,
            }}, "ok", { raw_count = 1 }
        end,
        generated_builtin_targeted_decision = function(snap, item_name, item_id)
            targeted_calls = targeted_calls + 1
            local mode = fallback_names[tostring(snap and snap.name or "")]
            if mode == true or mode == "need" then
                return {
                    item_name = tostring(item_name or "Need Ring"),
                    entry = { item = tostring(item_name or "Need Ring"), id = tonumber(item_id) or 9 },
                    list = { id = "test", name = "test" },
                }, "need"
            end
            if mode == "unresolved" then return nil, "snapshot-unavailable" end
            return nil, "owned"
        end,
        check_announce_need_for_link = function(snap, item_name, item_id)
            broad_fallback_calls = broad_fallback_calls + 1
            local mode = fallback_names[tostring(snap and snap.name or "")]
            if mode == true or mode == "need" then
                return {
                    item_name = tostring(item_name or "Need Ring"),
                    entry = { item = tostring(item_name or "Need Ring"), id = tonumber(item_id) or 9 },
                    list = { id = "test", name = "test" },
                }, "need"
            end
            if mode == "unresolved" then return nil, "snapshot-unavailable" end
            return nil, "owned"
        end,
    }
end
local local_snap = { server = "Srv", name = "Emit", class = "WAR", equipped = {}, bags = {}, bank = {} }
package.preload['snapshot'] = function()
    return { cached = function() return local_snap end,
        lite_age = function() return 0 end, gather = function() return local_snap end }
end
package.preload['item_actions'] = function() return {
    looks_like_item_link = function() return false end, remember_item_link = function() end,
    resolve_announce_link = function() return "" end, observed_link_count = function() return 0 end } end
package.preload['diagnostics'] = function() return {
    time = function(_, fn) return fn() end, count = function() end, event = function() end,
    sample = function() end, is_enabled = function() return false end } end
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
    return {
        tick = function() error("A2 path called item_index.tick") end,
        get = function() error("A2 path called item_index.get") end,
    }
end
package.preload['roster_sets'] = function()
    return {
        active_store_keys = function() return { "Srv_Emit" } end,
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
    gettime = function() return 1000000 end,
    cmd = function(v) sent[#sent + 1] = tostring(v) end,
    cmdf = function(fmt, ...) sent[#sent + 1] = string.format(fmt, ...) end,
    delay = function() end } end

local A = require('announcer')
A.set_passive(false)
local hooks = A._diet_a_hooks()
local idxmod = require('ownership_index')

local pass, fail = 0, 0
local function check(c, m) if c then pass = pass + 1 else fail = fail + 1; print("  FAIL: " .. tostring(m)) end end
local function interpreter_instruction_count(fn)
    local count = 0
    local function hook() count = count + 1 end
    debug.sethook(hook, "", 1)
    local ok, err = pcall(fn)
    debug.sethook()
    check(ok, "instruction-counted region completes: " .. tostring(err or ""))
    return count
end
local function has_name(order, name)
    for _, who in ipairs(order or {}) do
        if tostring(who) == tostring(name) then return true end
    end
    return false
end

hooks.set_work_clock(nil)
check(math.abs(hooks.work_clock() - 1000) < 0.001,
    "production work budget clock uses mq.gettime millisecond precision")

hooks.set_elapsed_s(function() return fake end)
check(A.warm(false) == true and generated_resident == true and generated_load_calls == 1,
    "listener readiness preloads generated authority during startup warm")

local snap = {
    server = "Srv",
    name = "Emit",
    class = "Warrior",
    equipped = { { name = "Need Ring", id = 9, where = "Left Finger", slotname = "Left Finger", augs = {} } },
    bags = {},
    bank = {},
}
local row = { key = "Srv_Emit", snap = snap, local_owner = true }

local need, why = hooks.need_for_row(row, "Need Ring", 9, "test")
check(need == nil, "cold miss does not return a needer")
check(why == "ownership-warming", "cold miss defers with ownership-warming")
check(snap._bis_index == nil, "cold miss does not publish compact ownership")

idxmod.cached_snapshot_index(snap)
need, why = hooks.need_for_row(row, "Need Ring", 9, "test")
check(why ~= "ownership-warming", "cache hit is not deferred")
check(need == nil or type(need) == "table", "cache hit evaluates instead of guessing")

local warm_need = {
    server = "Srv", name = "WarmNeed", class = "Warrior",
    equipped = {}, bags = {}, bank = {},
}
idxmod.cached_snapshot_index(warm_need)
local sent_before = #sent
hooks.set_driver_job({
    entry = { manual = true },
    item_name = "Warm Ring", item_id = 8, item_link = "", chat_at = os.clock(),
    elapsed_at = fake, source = "chat",
    rows = { { key = "Srv_WarmNeed", snap = warm_need, local_owner = false } },
    index = 1, order = {}, name_map = {}, sources = {}, details = {}, scan_counts = {}, snaps = 0,
    authority_started = fake, pending_warm = {}, pending_warm_keys = {}, row_outcomes = {},
    targeted_attempted = {}, outcome = "PENDING",
})
hooks.step_driver_link_job(hooks.work_clock() + 1)
local warm_done = hooks.last_finished_job()
check(warm_done and warm_done.outcome == "COMPLETE", "warm compact row completes immediately")
check((warm_done.cold_fallback_rows or 0) == 0, "warm compact row does not use targeted fallback")
check(#sent == sent_before + 1, "warm complete result emits exactly once")
check(type(warm_done.link_to_enqueue_ms) == "number", "completed job retains link-to-enqueue latency")
check(type(warm_done.decision_ms) == "number", "completed job retains canonical decision latency")
check(type(warm_done.link_to_send_ms) == "number", "completed job retains link-to-send latency")
local warm_status = hooks.driver_job_status(warm_done)
check(warm_status and warm_status.eligible == 1 and warm_status.decided == 1,
    "status reports trustworthy eligible and decided row counts")
check(type(warm_status and warm_status.link_to_enqueue_ms) == "number"
        and type(warm_status and warm_status.decision_ms) == "number"
        and type(warm_status and warm_status.link_to_send_ms) == "number",
    "status exposes enqueue, decision, and send latency")

local warm_instr_a = interpreter_instruction_count(function()
    hooks.need_for_row({ key = "Srv_WarmNeed", snap = warm_need }, "Warm Ring", 8, "a26")
end)
local warm_instr_b = interpreter_instruction_count(function()
    hooks.need_for_row({ key = "Srv_WarmNeed", snap = warm_need }, "Warm Ring", 8, "a26")
end)
check(warm_instr_a > 0 and warm_instr_a == warm_instr_b,
    "warm cache-hit row has deterministic interpreter bytecode count")

local function counted_warm_driver_job(rows)
    return {
        entry = { manual = true },
        item_name = "Warm Ring", item_id = 8, item_link = "", chat_at = os.clock(),
        elapsed_at = fake, source = "chat", rows = rows,
        index = 1, order = {}, name_map = {}, sources = {}, details = {}, scan_counts = {}, snaps = 0,
        authority_started = fake, pending_warm = {}, pending_warm_keys = {}, row_outcomes = {},
        targeted_attempted = {}, outcome = "PENDING",
    }
end
local warm_rows = {}
for i = 1, 3 do
    local warm_snap = {
        server = "Srv", name = "Warm" .. tostring(i), class = "Warrior",
        equipped = {}, bags = {}, bank = {},
    }
    idxmod.cached_snapshot_index(warm_snap)
    warm_rows[i] = { key = "Srv_Warm" .. tostring(i), snap = warm_snap }
end
local function count_driver(rows)
    hooks.set_driver_job(counted_warm_driver_job(rows))
    return interpreter_instruction_count(function()
        hooks.step_driver_link_job(hooks.work_clock() + 1)
    end)
end
local one_row_driver_instr_a = count_driver({ warm_rows[1] })
local one_row_driver_instr_b = count_driver({ warm_rows[1] })
local three_row_driver_instr_a = count_driver(warm_rows)
local three_row_driver_instr_b = count_driver(warm_rows)
check(one_row_driver_instr_a == one_row_driver_instr_b,
    "one-row driver bookkeeping has deterministic interpreter bytecode count")
check(three_row_driver_instr_a == three_row_driver_instr_b,
    "complete three-row warm driver has deterministic interpreter bytecode count")

-- Ready-cache fast path: if every row already has compact ownership, the
-- driver should finish the whole atomic item even when the ordinary per-tick
-- deadline would have expired after the first row.
local fast_rows = {}
for i = 1, 3 do
    local fast_snap = {
        server = "Srv", name = "Fast" .. tostring(i), class = "Warrior",
        equipped = {}, bags = {}, bank = {},
    }
    idxmod.cached_snapshot_index(fast_snap)
    fast_rows[#fast_rows + 1] = { key = "Srv_Fast" .. tostring(i), snap = fast_snap }
end
work_now, candidate_cost = 0, 0.00075
hooks.set_work_clock(function() return work_now end)
sent_before = #sent
hooks.set_driver_job({
    entry = { manual = true },
    item_name = "Fast Ring", item_id = 48, item_link = "", chat_at = 0,
    elapsed_at = fake, source = "chat", rows = fast_rows,
    index = 1, order = {}, name_map = {}, sources = {}, details = {}, scan_counts = {}, snaps = 0,
    authority_started = fake, pending_warm = {}, pending_warm_keys = {}, row_outcomes = {},
    targeted_attempted = {}, outcome = "PENDING",
})
hooks.step_driver_link_job(0.0005)
local fast_done = hooks.last_finished_job()
check(hooks.get_driver_job() == nil and fast_done and fast_done.outcome == "COMPLETE",
    "ready-cache fast path completes all ready rows in one logical pass")
check((fast_done and fast_done.snaps or 0) == 3, "ready-cache fast path evaluates every ready row")
check(#sent == sent_before + 1, "ready-cache fast path emits exactly once")
candidate_cost = 0
hooks.set_work_clock(nil)

sent_before = #sent
hooks.set_driver_job({
    entry = { manual = true },
    item_name = "Need Ring", item_id = 9, item_link = "", chat_at = os.clock(),
    elapsed_at = fake, source = "chat", rows = { row },
    index = 1, order = {}, name_map = {}, sources = {}, details = {}, scan_counts = {}, snaps = 0,
    authority_started = fake, pending_warm = {}, pending_warm_keys = {}, row_outcomes = {},
    targeted_attempted = {}, outcome = "PENDING",
})
hooks.step_driver_link_job(hooks.work_clock() + 1)
local none_done = hooks.last_finished_job()
check(none_done and none_done.outcome == "NO_NEEDERS",
    "fully resolved owned row is explicit NO_NEEDERS (got " .. tostring(none_done and none_done.outcome) .. ")")
check(#sent == sent_before,
    "NO_NEEDERS intentionally emits nothing (before=" .. tostring(sent_before) .. " after=" .. tostring(#sent) .. ")")

local fallback = {
    server = "Srv",
    name = "Fallback",
    class = "Warrior",
    equipped = {},
    bags = {},
    bank = {},
}
fallback_names.Fallback = true
hooks.set_driver_job({
    item_name = "Need Ring",
    item_id = 9,
    item_link = "",
    chat_at = os.clock(),
    source = "chat",
    rows = { { key = "Srv_Fallback", snap = fallback, local_owner = false } },
    index = 1,
    order = {},
    name_map = {},
    sources = {},
    details = {},
    scan_counts = {},
    snaps = 0,
    authority_started = fake,
    pending_warm = {},
    cold_fallback_started = os.clock(),
    cold_fallback_rows = 0,
})
hooks.step_driver_link_job(hooks.work_clock() + 1)
local fallback_done = hooks.last_finished_job()
check(hooks.get_driver_job() == nil, "cold fallback finishes the link job")
check(has_name(fallback_done and fallback_done.order, "Fallback"), "cold fallback needer is included")
check((fallback_done and fallback_done.scan_counts and fallback_done.scan_counts.fallback_need or 0) == 1,
    "cold fallback is counted separately")
local function counted_targeted_job()
    return {
        item_name = "Need Ring", item_id = 9,
        targeted_attempted = {}, cold_fallback_rows = 0,
    }
end
local targeted_instr_a = interpreter_instruction_count(function()
    hooks.try_cold_row_fallback(
        counted_targeted_job(), { key = "Srv_Fallback", snap = fallback }, hooks.work_clock() + 1)
end)
local targeted_instr_b = interpreter_instruction_count(function()
    hooks.try_cold_row_fallback(
        counted_targeted_job(), { key = "Srv_Fallback", snap = fallback }, hooks.work_clock() + 1)
end)
check(targeted_instr_a > 0 and targeted_instr_a == targeted_instr_b,
    "targeted candidate decision has deterministic interpreter bytecode count")
print(string.format(
    "A2.7 interpreter bytecodes: warm_row=%d one_row_driver=%d three_row_driver=%d targeted_candidate=%d",
    warm_instr_a, one_row_driver_instr_a, three_row_driver_instr_a, targeted_instr_a))
fallback_names.Fallback = nil

local observed_status = nil
local observed_snap = {
    server = "Srv", name = "ObservedRow", class = "Warrior",
    equipped = {}, bags = {}, bank = {},
}
fallback_names.ObservedRow = "need"
hooks.set_driver_job({
    entry = { manual = true },
    item_name = "Observed Ring", item_id = 18, item_link = "", chat_at = os.clock(),
    elapsed_at = fake, source = "chat",
    rows = { { key = "Srv_ObservedRow", snap = observed_snap } },
    index = 1, order = {}, name_map = {}, sources = {}, details = {}, scan_counts = {}, snaps = 0,
    authority_started = fake, pending_warm = {}, pending_warm_keys = {}, row_outcomes = {},
    targeted_attempted = {}, outcome = "PENDING",
})
candidate_observer = function()
    observed_status = hooks.driver_job_status(hooks.get_driver_job())
end
hooks.step_driver_link_job(hooks.work_clock() + 1)
candidate_observer = nil
check(observed_status and observed_status.current_stage == "ROW_IN_PROGRESS"
        and observed_status.current_row_index == 1
        and observed_status.current_row_character == "ObservedRow",
    "driver status distinguishes an entered row from waiting for resume")
check(type(observed_status and observed_status.current_row_age_ms) == "number",
    "row-in-progress status exposes live row wall age")
fallback_names.ObservedRow = nil

-- A2: three cold rows resolve narrowly without waiting for complete compact
-- ownership indexes, then emit exactly once with the complete set.
local cold_rows = {}
for _, name in ipairs({ "ColdA", "ColdB", "ColdC" }) do
    fallback_names[name] = "need"
    cold_rows[#cold_rows + 1] = {
        key = "Srv_" .. name,
        snap = { server = "Srv", name = name, class = "Warrior", equipped = {}, bags = {}, bank = {} },
        local_owner = false,
    }
end
sent_before = #sent
local broad_before, targeted_before = broad_fallback_calls, targeted_calls
hooks.set_driver_job({
    entry = { manual = true },
    item_name = "Cold Trio Ring", item_id = 19, item_link = "", chat_at = os.clock(),
    elapsed_at = fake, source = "chat", rows = cold_rows, index = 1,
    order = {}, name_map = {}, sources = {}, details = {}, scan_counts = {}, snaps = 0,
    authority_started = fake, pending_warm = {}, pending_warm_keys = {}, row_outcomes = {},
    targeted_attempted = {}, outcome = "PENDING",
})
hooks.step_driver_link_job(hooks.work_clock() + 1)
local cold_done = hooks.last_finished_job()
check(hooks.get_driver_job() == nil and cold_done.outcome == "COMPLETE",
    "three cold targeted rows complete without full ownership warm")
check(#(cold_done.order or {}) == 3, "three cold targeted rows produce the complete needer set")
check((cold_done.targeted_resolved or 0) == 3, "all three cold rows report targeted resolution")
check(#sent == sent_before + 1, "cold three-row result emits exactly once")
check(broad_fallback_calls == broad_before,
    "cold targeted decisions never call the broad catalog paint walk")
check(targeted_calls == targeted_before + 3,
    "cold targeted decisions use the generated one-item helper")
for _, row2 in ipairs(cold_rows) do
    check(row2.snap._bis_index == nil, "targeted cold decision does not require compact cache publication")
end

-- Mixed ready + targeted + cooperative warm. The unresolved row keeps the
-- item atomic until its compact cache publishes.
local ready_snap = { server = "Srv", name = "ReadyA", class = "Warrior", equipped = {}, bags = {}, bank = {} }
local target_snap = { server = "Srv", name = "TargetB", class = "Warrior", equipped = {}, bags = {}, bank = {} }
local warm_snap = { server = "Srv", name = "WarmC", class = "Warrior", equipped = {}, bags = {}, bank = {} }
idxmod.cached_snapshot_index(ready_snap)
fallback_names.TargetB = "need"
fallback_names.WarmC = "unresolved"
sent_before = #sent
hooks.set_driver_job({
    entry = { manual = true },
    item_name = "Mixed Ring", item_id = 29, item_link = "", chat_at = os.clock(),
    elapsed_at = fake, source = "chat",
    rows = {
        { key = "Srv_ReadyA", snap = ready_snap },
        { key = "Srv_TargetB", snap = target_snap },
        { key = "Srv_WarmC", snap = warm_snap },
    },
    index = 1, order = {}, name_map = {}, sources = {}, details = {}, scan_counts = {}, snaps = 0,
    authority_started = fake, pending_warm = {}, pending_warm_keys = {}, row_outcomes = {},
    targeted_attempted = {}, outcome = "PENDING",
})
hooks.step_driver_link_job(hooks.work_clock() + 1)
check(hooks.get_driver_job() ~= nil, "mixed item remains pending while one row is unresolved")
check(#sent == sent_before, "mixed item does not emit a partial set")
fake = fake + 0.125
idxmod.cached_snapshot_index(warm_snap)
hooks.step_driver_link_job(hooks.work_clock() + 1)
local mixed_done = hooks.last_finished_job()
check(hooks.get_driver_job() == nil and mixed_done.outcome == "COMPLETE",
    "mixed item completes after final compact row publishes")
check(#(mixed_done.order or {}) == 3, "mixed item emits all three final needers")
check(#sent == sent_before + 1, "mixed complete result emits exactly once")
local mixed_stage = hooks.stage_latency_report(mixed_done)
check((mixed_stage.pending_warm.wall_ms or 0) >= 124,
    "pending-warm attribution spans the full wait across driver ticks")

-- A positive actor report can enrich only its matching open driver job; the
-- driver remains the sole emitter.
local peer_snap = { server = "Srv", name = "PeerNeed", class = "Warrior", equipped = {}, bags = {}, bank = {} }
idxmod.cached_snapshot_index(peer_snap)
sent_before = #sent
hooks.set_driver_job({
    entry = { manual = true },
    item_name = "Peer Merge Ring", item_id = 39, item_link = "", chat_at = os.clock(),
    elapsed_at = fake, source = "chat",
    rows = { { key = "Srv_PeerNeed", snap = peer_snap, local_owner = false } },
    index = 1, order = {}, name_map = {}, sources = {}, details = {}, scan_counts = {}, snaps = 0,
    authority_started = fake, pending_warm = {}, pending_warm_keys = {}, row_outcomes = {},
    targeted_attempted = {}, outcome = "PENDING",
})
A.on_loot_need({ from = "PeerNeed", item_name = "Peer Merge Ring", item_id = 39 })
hooks.step_driver_link_job(hooks.work_clock() + 1)
local peer_done = hooks.last_finished_job()
check(peer_done and peer_done.outcome == "COMPLETE", "matching peer positive enriches the open driver")
check(peer_done.sources and peer_done.sources.peerneed == "actor-reply",
    "peer enrichment remains labeled inside canonical driver state")
check(#sent == sent_before + 1, "peer enrichment still produces only one driver emission")
A.on_loot_need({ from = "PeerNeed", item_name = "Unrelated Ring", item_id = 999 })
check(#sent == sent_before + 1, "unmatched peer positive cannot create standalone output")

-- Driver CPU budget is independent from overall job lifetime. Work advances
-- only until the injected per-tick deadline, then resumes next tick.
CFG.generated_authority_ready_fast_path = false
local budget_rows = {}
for i = 1, 4 do
    local s = { server = "Srv", name = "Budget" .. i, class = "Warrior", equipped = {}, bags = {}, bank = {} }
    idxmod.cached_snapshot_index(s)
    budget_rows[#budget_rows + 1] = { key = "Srv_Budget" .. i, snap = s }
end
work_now, candidate_cost = 0, 0.00075
hooks.set_work_clock(function() return work_now end)
sent_before = #sent
hooks.set_driver_job({
    entry = { manual = true },
    item_name = "Budget Ring", item_id = 49, item_link = "", chat_at = 0,
    elapsed_at = fake, source = "chat", rows = budget_rows,
    index = 1, order = {}, name_map = {}, sources = {}, details = {}, scan_counts = {}, snaps = 0,
    authority_started = fake, pending_warm = {}, pending_warm_keys = {}, row_outcomes = {},
    targeted_attempted = {}, outcome = "PENDING",
})
hooks.step_driver_link_job(work_now + 0.001)
local budget_job = hooks.get_driver_job()
check(budget_job ~= nil and budget_job.index == 3,
    "driver yields at injected per-tick budget instead of using overall lifetime")
check(#sent == sent_before, "budget yield does not emit before every row is decided")
hooks.step_driver_link_job(work_now + 0.002)
check(hooks.get_driver_job() == nil and hooks.last_finished_job().outcome == "COMPLETE",
    "budgeted driver resumes and completes on the next tick")
check(#sent == sent_before + 1, "resumed budgeted driver emits exactly once")
candidate_cost = 0
hooks.set_work_clock(nil)
CFG.generated_authority_ready_fast_path = true

-- A candidate lookup that consumes the first driver slice must not prevent
-- the row's one targeted cold decision from ever being attempted.
local slow_target = {
    server = "Srv", name = "SlowTarget", class = "Warrior",
    equipped = {}, bags = {}, bank = {},
}
fallback_names.SlowTarget = "need"
fake, work_now = 1200, 0
candidate_cost, candidate_elapsed_cost = 0.003, 0.3
hooks.set_work_clock(function() return work_now end)
sent_before = #sent
hooks.set_driver_job({
    entry = { manual = true },
    item_name = "Slow Candidate Ring", item_id = 59, item_link = "", chat_at = 0,
    elapsed_at = fake, source = "chat",
    rows = { { key = "Srv_SlowTarget", snap = slow_target, local_owner = false } },
    index = 1, order = {}, name_map = {}, sources = {}, details = {}, scan_counts = {}, snaps = 0,
    authority_started = fake, pending_warm = {}, pending_warm_keys = {}, row_outcomes = {},
    targeted_attempted = {}, outcome = "PENDING",
})
hooks.step_driver_link_job(work_now + 0.002)
check(hooks.get_driver_job() ~= nil, "over-budget candidate row remains pending after its first slice")
hooks.step_driver_link_job(work_now + 0.002)
local slow_done = hooks.last_finished_job()
check(slow_done and slow_done.outcome == "COMPLETE",
    "expired row still receives its one previously-starved targeted decision")
check((slow_done and slow_done.cold_fallback_rows or 0) == 1,
    "previously-starved targeted decision is attempted exactly once")
check(#sent == sent_before + 1, "targeted resolution after candidate overrun emits once")
fallback_names.SlowTarget = nil
candidate_cost, candidate_elapsed_cost = 0, 0
hooks.set_work_clock(nil)
fake = 1000

-- Overall job lifetime is independent of the per-slice work clock. Once one
-- row consumes the lifetime, do not begin another canonical candidate unit.
local expiry_rows = {}
for _, name in ipairs({ "ExpiryA", "ExpiryB" }) do
    fallback_names[name] = "need"
    expiry_rows[#expiry_rows + 1] = {
        key = "Srv_" .. name,
        snap = { server = "Srv", name = name, class = "Warrior", equipped = {}, bags = {}, bank = {} },
        local_owner = false,
    }
end
fake, candidate_elapsed_cost = 1300, 0.3
local expiry_candidate_before, expiry_sent_before = candidate_calls, #sent
hooks.set_driver_job({
    entry = { manual = true },
    item_name = "Expiry Ring", item_id = 69, item_link = "", chat_at = 0,
    elapsed_at = fake, source = "chat", rows = expiry_rows,
    index = 1, order = {}, name_map = {}, sources = {}, details = {}, scan_counts = {}, snaps = 0,
    authority_started = fake, pending_warm = {}, pending_warm_keys = {}, row_outcomes = {},
    targeted_attempted = {}, outcome = "PENDING",
})
hooks.step_driver_link_job(hooks.work_clock() + 1)
local expiry_done = hooks.last_finished_job()
check(candidate_calls == expiry_candidate_before + 1,
    "expired driver does not begin another candidate decision unit")
check(expiry_done and expiry_done.outcome == "ABORTED",
    "row left unresolved at the hard lifetime produces explicit ABORTED")
check(#sent == expiry_sent_before, "hard lifetime ABORTED emits no partial needer list")
for _, name in ipairs({ "ExpiryA", "ExpiryB" }) do fallback_names[name] = nil end
candidate_elapsed_cost = 0
fake = 1000

-- Four rapid items remain distinct and each gets one serial authority result.
fallback_names.Emit = "need"
sent_before = #sent
local burst_names = { "Burst One", "Burst Two", "Burst Three", "Burst Four" }
for i, burst_name in ipairs(burst_names) do
    hooks.queue_driver_entry({
        name = burst_name, id = 100 + i, source = "announcetest", manual = true,
        chat_at = os.clock(), elapsed_at = fake,
    })
end
check(hooks.driver_queue_count() == 4, "four-item burst preserves all queued identities")
for _ = 1, 8 do
    hooks.step_driver_link_job(hooks.work_clock() + 1)
    if hooks.driver_queue_count() == 0 and hooks.get_driver_job() == nil then break end
end
check(hooks.driver_queue_count() == 0 and hooks.get_driver_job() == nil,
    "four-item burst drains without item loss")
check(#sent == sent_before + 4, "four-item burst emits exactly once per needed item")
for _, burst_name in ipairs(burst_names) do
    local found = false
    for i = sent_before + 1, #sent do
        if tostring(sent[i]):find(burst_name, 1, true) then found = true break end
    end
    check(found, "four-item burst retains identity for " .. burst_name)
end

-- A2.6 stage attribution survives both queues and reaches the command send.
fake = 1400
sent_before = #sent
local generated_loads_before_link = generated_load_calls
hooks.enqueue_chat_links({
    { name = "Stage Ring", id = 170, link = "" },
}, "You say, Stage Ring", {
    self_event = true,
    event_delivery_wall = 1399.900,
    event_delivery_cpu = os.clock(),
    event_delivery_uncertainty_ms = 25,
})
fake = 1400.020
hooks.drain_chat_link_queue(os.clock() + 1)
fake = 1400.050
hooks.step_driver_link_job(hooks.work_clock() + 1)
local stage_done = hooks.last_finished_job()
local stage_report = stage_done and hooks.stage_latency_report(stage_done) or nil
check(stage_done and stage_done.item_name == "Stage Ring" and #sent == sent_before + 1,
    "stage-attributed chat item reaches one complete mq.cmd send")
check(stage_report and (stage_report.chat_queue_wait.wall_ms or 0) >= 19
        and (stage_report.link_scan_queue_wait.wall_ms or 0) <= 5,
    "stage attribution preserves chat wait and immediate link-scan handoff")
check(stage_report and (stage_report.total.wall_ms or 0) >= 119
        and stage_report.event_delivery_uncertainty_ms == 25,
    "stage attribution preserves event-delivery uncertainty and total wall time")
check(stage_report and stage_report.render_callback == false
        and #(stage_report.rows or {}) >= 1
        and type(stage_report.rows[1].cpu_ms) == "number",
    "stage report records row wall/CPU outside the render callback")
check(generated_load_calls == generated_loads_before_link,
    "first driver row performs zero generated-index load work")
fake = 1000
fallback_names.Emit = nil

-- Blocking ownership work jumps ahead of ordinary prewarm, then background
-- readiness continues on a later cooperative slice.
hooks.reset_ownership_warm()
local bg1 = { server = "Srv", name = "Bg1", class = "Warrior", equipped = {}, bags = {}, bank = {} }
local bg2 = { server = "Srv", name = "Bg2", class = "Warrior", equipped = {}, bags = {}, bank = {} }
local blocker = { server = "Srv", name = "Blocker", class = "Warrior", equipped = {}, bags = {}, bank = {} }
hooks.queue_ownership_warm({ key = "Srv_Bg1", snap = bg1 }, "ready:roster")
hooks.queue_ownership_warm({ key = "Srv_Bg2", snap = bg2 }, "ready:roster")
hooks.queue_ownership_warm({ key = "Srv_Blocker", snap = blocker }, "emit_miss")
hooks.tick_ownership_warm(hooks.work_clock() + 1)
check(blocker._bis_index ~= nil, "active linked-item blocker advances before background prewarm")
check(bg1._bis_index == nil and bg2._bis_index == nil, "priority slice remains bounded to one warm row")
hooks.tick_ownership_warm(hooks.work_clock() + 1)
check(bg1._bis_index ~= nil or bg2._bis_index ~= nil, "background prewarm still progresses after blocker")

hooks.reset_ownership_warm()
fake = 1100
local age_blocker = { server = "Srv", name = "AgeBlocker", class = "Warrior", equipped = {}, bags = {}, bank = {} }
hooks.queue_ownership_warm({ key = "Srv_AgeBlocker", snap = age_blocker }, "emit_miss")
fake = 1101
local age_status = hooks.ownership_cache_status(8)
check((age_status.oldest_blocking_age_ms or 0) >= 999,
    "blocking warm age uses injected real elapsed time")
fake = 1000

local saved_local_snap = local_snap
local status_item_reads = 0
local status_values = { name = "Status Must Not Hash", id = 7001, augs = {} }
local status_item = setmetatable({}, {
    __index = function(_, key)
        status_item_reads = status_item_reads + 1
        return status_values[key]
    end,
})
local_snap = {
    server = "Srv", name = "Emit", class = "Warrior",
    equipped = { status_item }, bags = {}, bank = {},
}
hooks.clear_ownership_cache_status()
hooks.ownership_cache_status(8)
check(status_item_reads == 0 and local_snap._tg_own_fp == nil,
    "/tgear ownership status does not hash or prewarm a first-link snapshot")
local_snap = saved_local_snap
hooks.clear_ownership_cache_status()

CFG.generated_authority_cold_fallback = false

local stale = {
    server = "Srv",
    name = "Stuck",
    class = "Warrior",
    equipped = { { name = "Need Ring", id = 9, augs = {} } },
    bags = {},
    bank = {},
}
hooks.set_driver_job({
    item_name = "Need Ring",
    item_id = 9,
    item_link = "",
    chat_at = os.clock(),
    source = "chat",
    entry = { manual = true },
    rows = {
        { key = "Srv_WarmNeed", snap = warm_need, local_owner = false },
        { key = "Srv_Stuck", snap = stale, local_owner = false },
    },
    index = 2,
    order = { "WarmNeed" },
    name_map = { warmneed = "WarmNeed" },
    sources = { warmneed = "generated-authority" },
    details = {},
    snaps = 0,
    authority_started = fake - 10,
    pending_warm = {},
    row_outcomes = {
        Srv_WarmNeed = {
            character = "WarmNeed", class = "Warrior",
            state = "NEED", reason = "cached", final = true,
        },
    },
})
sent_before = #sent
hooks.step_driver_link_job(hooks.work_clock() + 1)
local leftover = hooks.get_driver_job()
check(leftover == nil, "expired ownership wait finishes the link job")
local aborted = hooks.last_finished_job()
check(aborted and aborted.outcome == "ABORTED", "expired ownership wait is explicit ABORTED")
check(has_name(aborted and aborted.order, "WarmNeed"), "resolved needer remains recorded on aborted job")
check(#sent == sent_before, "aborted job never emits its knowingly partial needer set")

print(string.format("core diet A tg defer: %d passed, %d failed", pass, fail))
os.exit(fail == 0 and 0 or 1)
