-- TurboGear/rich_inventory.lua
-- Cooperative rich-item enrichment. Replaces the blocking startup_bg_full
-- Engine.publish(true, "full") walk with one make_item(full) per slice.
--
-- Lite inventory stays the published authority until the private job
-- finishes, then one atomic promote. No partial Store writes.

local M = {}

local BUSY_STARVE_S = 5.0
local RESTART_DELAY_S = 1.0
local SLICE_GUARD_MS = 800

local job = nil
local recovery = {
    pending = false,
    cancelled_sig = "",
    due = 0,
}
local last_start_opts = {}
local stats = {
    jobs_started = 0,
    jobs_completed = 0,
    jobs_cancelled = 0,
    item_steps = 0,
    yield_op_limit = 0,
    yield_busy = 0,
    promotes = 0,
    recovery_probe = 0,
    recovery_probe_changed = 0,
    recovery_probe_same = 0,
    recovery_started = 0,
}

local function cfg_items_per_slice()
    local ok, cfg = pcall(require, 'config')
    local n = ok and cfg and cfg.CFG and tonumber(cfg.CFG.rich_inventory_items_per_slice)
    if not n or n < 1 then n = 1 end
    return math.floor(n)
end

local function diag()
    local ok, d = pcall(require, 'diagnostics')
    if ok and d then return d end
    return {
        count = function() end,
        event = function() end,
        time = function(_, fn) return fn() end,
        sample = function() end,
    }
end

local function copy_list(list)
    local out = {}
    for i, row in ipairs(list or {}) do out[i] = row end
    return out
end

local function copy_snap_shell(src)
    local out = {}
    for k, v in pairs(src) do
        if k ~= "equipped" and k ~= "bags" then
            out[k] = v
        end
    end
    return out
end

local function default_identity(snap)
    local ok, snapshot = pcall(require, 'snapshot')
    if ok and snapshot and snapshot.inventory_identity then
        return snapshot.inventory_identity(snap)
    end
    if ok and snapshot and snapshot.lite_signature then
        return snapshot.lite_signature(snap, { skipSpells = true })
    end
    return ""
end

local function default_clock()
    return os.clock()
end

local function default_current_snapshot()
    local ok, snapshot = pcall(require, 'snapshot')
    if ok and snapshot and snapshot.cached then
        return snapshot.cached()
    end
    return nil
end

local function default_enrich(row)
    local ok, snapshot = pcall(require, 'snapshot')
    if ok and snapshot and snapshot.enrich_lite_row then
        return snapshot.enrich_lite_row(row)
    end
    return nil
end

local function default_extras()
    local ok, snapshot = pcall(require, 'snapshot')
    if ok and snapshot and snapshot.food_drink_locator_rows then
        return snapshot.food_drink_locator_rows() or {}
    end
    return {}
end

local function default_is_busy()
    local ok, ann = pcall(require, 'announcer')
    if ok and ann and ann.status then
        local st = ann.status() or {}
        if (tonumber(st.pending_chat) or 0) > 0 then return true, "chat" end
        if (tonumber(st.pending_link_scan) or 0) > 0 then return true, "link_scan" end
    end
    local okw, iw = pcall(require, 'inventory_watch')
    if okw and iw and iw.inventory_settling and iw.inventory_settling() then
        return true, "inventory_settling"
    end
    return false
end

local function default_publish(snap, job_ref)
    local ok_s, snapshot = pcall(require, 'snapshot')
    if ok_s and snapshot then
        if snapshot.stamp_for_publish then snapshot.stamp_for_publish(snap) end
        if snapshot.adopt then snapshot.adopt(snap) end
    end
    local ok_e, engine_mod = pcall(require, 'engine')
    local Engine = ok_e and engine_mod and engine_mod.Engine or nil
    if Engine and Engine.publish_snapshot then
        return Engine.publish_snapshot(snap, {
            force = true,
            reason = "rich_inventory.promote",
            replyTo = job_ref and job_ref.replyTo,
            requester = job_ref and job_ref.requester,
        }) and true or false
    end
    return true
end

-- Tests may inject probe_lite (instant complete candidate). Production uses
-- cooperative inventory_probe and never calls snapshot.gather from recovery.
local function default_adopt_lite(snap)
    if type(snap) ~= "table" then return end
    pcall(function()
        local snapshot = require('snapshot')
        if snapshot.stamp_inventory then snapshot.stamp_inventory(snap) end
        if snapshot.stamp_for_publish then snapshot.stamp_for_publish(snap) end
        if snapshot.adopt then snapshot.adopt(snap) end
    end)
    pcall(function()
        local Engine = require('engine').Engine
        if Engine and Engine.publish_snapshot then
            Engine.publish_snapshot(snap, {
                force = true,
                reason = "rich_inventory.recovery_probe",
            })
        end
    end)
end

function M.plan_startup_full()
    return {
        blocking_full = false,
        start_job = true,
        items_per_slice = 1,
        reason = "startup_bg_full",
    }
end

function M.plan_manual_sync()
    return {
        blocking_full = false,
        lite_refresh = true,
        restart_job = true,
        request_peer_depth = "lite",
        reason = "manual_sync",
    }
end

function M.plan_force_refresh()
    return {
        blocking_full = false,
        restart_job = true,
        ignore_already_full = true,
        reason = "richrefresh",
    }
end

function M.should_block_full_publish(opts)
    opts = type(opts) == "table" and opts or {}
    return opts.allowBlockingFull == true
end

local last_request = {
    action = "",
    reason = "",
    currentDepth = "",
    sourceSig = "",
    itemRich = false,
}

local function note_request(action, fields)
    fields = type(fields) == "table" and fields or {}
    last_request = {
        action = tostring(action or ""),
        reason = tostring(fields.reason or ""),
        currentDepth = tostring(fields.currentDepth or ""),
        sourceSig = tostring(fields.sourceSig or ""),
        itemRich = fields.itemRich == true,
    }
    local d = diag()
    d.count("rich_inventory.request")
    if action == "start" or action == "restart" then
        d.count("rich_inventory.request_start")
    elseif action == "skip_already_full" then
        d.count("rich_inventory.request_skip_full")
    elseif action == "skip_busy" then
        d.count("rich_inventory.request_skip_busy")
    end
    local sig = last_request.sourceSig
    if #sig > 48 then sig = sig:sub(1, 48) .. "..." end
    d.event("rich_inventory.request", string.format(
        "reason=%s currentDepth=%s itemRich=%s sourceSig=%s action=%s",
        last_request.reason, last_request.currentDepth,
        tostring(last_request.itemRich), sig, last_request.action))
end

function M.last_request()
    return last_request
end

function M.reset()
    job = nil
    recovery = { pending = false, cancelled_sig = "", due = 0 }
    last_start_opts = {}
    pcall(function() require('inventory_probe').reset() end)
    last_request = {
        action = "",
        reason = "",
        currentDepth = "",
        sourceSig = "",
        itemRich = false,
    }
    stats = {
        jobs_started = 0,
        jobs_completed = 0,
        jobs_cancelled = 0,
        item_steps = 0,
        yield_op_limit = 0,
        yield_busy = 0,
        promotes = 0,
        recovery_probe = 0,
        recovery_probe_changed = 0,
        recovery_probe_same = 0,
        recovery_started = 0,
    }
end

function M.active()
    return job ~= nil
end

function M.stats()
    return stats
end

function M.status()
    if job then
        local clock = job.clock or default_clock
        local now = clock()
        local sig = tostring(job.source_sig or "")
        if #sig > 48 then sig = sig:sub(1, 48) .. "..." end
        return {
            warming = true,
            phase = tostring(job.phase or "?"),
            item = tonumber(job.done) or 0,
            total = tonumber(job.total) or 0,
            elapsed = math.max(0, now - (tonumber(job.started_at) or now)),
            sourceSig = sig,
            reason = tostring(job.reason or ""),
        }
    end
    if recovery.pending then
        local ps = nil
        pcall(function()
            local probe = last_start_opts.inventory_probe or require('inventory_probe')
            if probe and probe.status then ps = probe.status() end
        end)
        if type(ps) == "table" and (ps.active == true or ps.phase == "complete"
            or ps.phase == "collect" or ps.phase == "validate" or ps.phase == "retry_wait") then
            return {
                warming = true,
                phase = "recovery probe " .. tostring(ps.phase or "collect"),
                item = tonumber(ps.item) or 0,
                total = tonumber(ps.total) or 0,
                elapsed = tonumber(ps.elapsed) or 0,
                sourceSig = last_request.sourceSig or "",
                reason = last_request.reason or "",
                lastAction = last_request.action or "",
                currentDepth = last_request.currentDepth or "",
                itemRich = last_request.itemRich == true,
            }
        end
        return {
            warming = true,
            phase = "recovery_pending",
            item = 0,
            total = 0,
            elapsed = 0,
            sourceSig = last_request.sourceSig or "",
            reason = last_request.reason or "",
            lastAction = last_request.action or "",
            currentDepth = last_request.currentDepth or "",
            itemRich = last_request.itemRich == true,
        }
    end
    return {
        warming = false,
        phase = "idle",
        item = 0,
        total = 0,
        elapsed = 0,
        sourceSig = last_request.sourceSig or "",
        reason = last_request.reason or "",
        lastAction = last_request.action or "",
        currentDepth = last_request.currentDepth or "",
        itemRich = last_request.itemRich == true,
    }
end

local function cancel_job(reason)
    if not job then return false end
    local d = diag()
    stats.jobs_cancelled = stats.jobs_cancelled + 1
    d.count("rich_inventory.job_cancelled")
    d.event("rich_inventory.job_cancelled", string.format("reason=%s phase=%s item=%d/%d",
        tostring(reason or "?"), tostring(job.phase or "?"),
        tonumber(job.done) or 0, tonumber(job.total) or 0))
    job = nil
    return true
end

-- Stale-job cancel: wait for a *new* inventory identity, then force-start.
-- skip_already_full must not suppress this recovery (depth=full is common).
local function arm_recovery(now)
    local sig = ""
    if job then sig = tostring(job.source_sig or "") end
    recovery.pending = true
    recovery.cancelled_sig = sig
    recovery.due = (tonumber(now) or 0) + RESTART_DELAY_S
    local d = diag()
    d.count("rich_inventory.recovery_pending")
    d.event("rich_inventory.recovery_pending", string.format("cancelledSig=%s",
        #sig > 48 and (sig:sub(1, 48) .. "...") or sig))
end

local function start_recovery(now, cancelled_sig)
    recovery.pending = false
    recovery.cancelled_sig = ""
    local ok = M.start({
        reason = "restart_after_cancel",
        restart = true,
        enrich_item = last_start_opts.enrich_item,
        current_snapshot = last_start_opts.current_snapshot,
        publish = last_start_opts.publish,
        is_busy = last_start_opts.is_busy,
        clock = last_start_opts.clock,
        identity = last_start_opts.identity,
        items_per_slice = last_start_opts.items_per_slice,
        extra_equipped = last_start_opts.extra_equipped,
        probe_lite = last_start_opts.probe_lite,
        adopt_lite = last_start_opts.adopt_lite,
        inventory_probe = last_start_opts.inventory_probe,
        probe_collect_rows = last_start_opts.probe_collect_rows,
        probe_validate_rows = last_start_opts.probe_validate_rows,
    })
    if not ok then
        recovery.pending = true
        recovery.cancelled_sig = cancelled_sig or ""
        recovery.due = now + RESTART_DELAY_S
        return false
    end
    stats.recovery_started = (stats.recovery_started or 0) + 1
    diag().count("rich_inventory.recovery_started")
    return true
end

local function probe_mod()
    if last_start_opts.inventory_probe then return last_start_opts.inventory_probe end
    local ok, p = pcall(require, 'inventory_probe')
    if ok then return p end
    return nil
end

local function cancel_probe(reason)
    local p = probe_mod()
    if p and p.cancel then p.cancel(reason or "recovery") end
end

local function note_probe_changed(cancelled_sig)
    stats.recovery_probe_changed = (stats.recovery_probe_changed or 0) + 1
    diag().count("rich_inventory.recovery_probe_changed")
    diag().event("rich_inventory.recovery_probe_changed", string.format(
        "cancelledSig=%s",
        #tostring(cancelled_sig) > 48
            and (tostring(cancelled_sig):sub(1, 48) .. "...")
            or tostring(cancelled_sig)))
end

local function try_recovery(now)
    if not recovery.pending or job then return false end
    if now < (tonumber(recovery.due) or 0) then return false end
    local current_fn = last_start_opts.current_snapshot or default_current_snapshot
    local ident_fn = last_start_opts.identity or default_identity
    local current = current_fn()
    if type(current) ~= "table" then return false end
    local live_sig = ident_fn(current)
    local cancelled_sig = recovery.cancelled_sig
    local adopt_fn = last_start_opts.adopt_lite or default_adopt_lite

    -- Watcher / other publisher already moved identity: start immediately.
    if live_sig ~= "" and live_sig ~= cancelled_sig then
        cancel_probe("watcher_fast_path")
        return start_recovery(now, cancelled_sig)
    end

    -- Instant complete-candidate seam for unit tests.
    if last_start_opts.probe_lite then
        stats.recovery_probe = (stats.recovery_probe or 0) + 1
        diag().count("rich_inventory.recovery_probe")
        local probed = last_start_opts.probe_lite()
        local probe_sig = (type(probed) == "table") and ident_fn(probed) or ""
        if probe_sig ~= "" and probe_sig ~= cancelled_sig then
            note_probe_changed(cancelled_sig)
            adopt_fn(probed)
            return start_recovery(now, cancelled_sig)
        end
        stats.recovery_probe_same = (stats.recovery_probe_same or 0) + 1
        diag().count("rich_inventory.recovery_probe_same")
        recovery.due = now + RESTART_DELAY_S
        return false
    end

    local p = probe_mod()
    if not p or not p.start or not p.tick then return false end

    if p.status and p.status().phase == "complete" then
        local cand = p.take_candidate and p.take_candidate() or nil
        local probe_sig = (type(cand) == "table") and ident_fn(cand) or ""
        if probe_sig ~= "" and probe_sig ~= cancelled_sig then
            note_probe_changed(cancelled_sig)
            adopt_fn(cand)
            return start_recovery(now, cancelled_sig)
        end
        stats.recovery_probe_same = (stats.recovery_probe_same or 0) + 1
        diag().count("rich_inventory.recovery_probe_same")
        recovery.due = now + RESTART_DELAY_S
        return false
    end

    if not p.active or not p.active() then
        local started = p.start({
            prior = current,
            current_snapshot = current_fn,
            identity = ident_fn,
            clock = last_start_opts.clock or default_clock,
            cancelled_sig = cancelled_sig,
            collect_rows = last_start_opts.probe_collect_rows,
            validate_rows = last_start_opts.probe_validate_rows,
        })
        if not started then return false end
        stats.recovery_probe = (stats.recovery_probe or 0) + 1
        diag().count("rich_inventory.recovery_probe")
    end

    local busy_fn = last_start_opts.is_busy or default_is_busy
    if busy_fn() then
        stats.yield_busy = stats.yield_busy + 1
        diag().count("rich_inventory.yield_busy")
        return false
    end

    p.tick()
    local st = p.status and p.status() or {}
    if st.phase == "complete" then
        local cand = p.take_candidate and p.take_candidate() or st.candidate
        local probe_sig = (type(cand) == "table") and ident_fn(cand) or ""
        if probe_sig ~= "" and probe_sig ~= cancelled_sig then
            note_probe_changed(cancelled_sig)
            adopt_fn(cand)
            return start_recovery(now, cancelled_sig)
        end
        stats.recovery_probe_same = (stats.recovery_probe_same or 0) + 1
        diag().count("rich_inventory.recovery_probe_same")
        if p.cancel then p.cancel("same_identity") end
        recovery.due = now + RESTART_DELAY_S
        return false
    end
    return false
end

function M.cancel(reason)
    cancel_probe("rich_cancel")
    local had = cancel_job(reason or "manual")
    recovery = { pending = false, cancelled_sig = "", due = 0 }
    return had
end

local function build_work(source, extras)
    local work = {}
    local have_slot = {}
    for i, row in ipairs(source.equipped or {}) do
        work[#work + 1] = { phase = "equipped", list = "equipped", i = i, row = row }
        have_slot[tostring(row.slotid)] = true
    end
    for i, row in ipairs(source.bags or {}) do
        work[#work + 1] = { phase = "bags", list = "bags", i = i, row = row }
    end
    for i, row in ipairs(extras or {}) do
        if not have_slot[tostring(row.slotid)] then
            work[#work + 1] = { phase = "extras", list = "extras", i = i, row = row }
        end
    end
    return work
end

local function extra_needed(source, extras)
    local have = {}
    for _, it in ipairs(source.equipped or {}) do
        have[tostring(it.slotid)] = true
    end
    for _, ex in ipairs(extras or {}) do
        if not have[tostring(ex.slotid)] then return true end
    end
    return false
end

local function already_rich(source, extras)
    if extra_needed(source, extras) then return false end
    local function list_rich(list)
        for _, it in ipairs(list or {}) do
            if tostring(it.depth or "") ~= "full" then return false end
        end
        return true
    end
    return list_rich(source.equipped) and list_rich(source.bags)
end

function M.start(opts)
    opts = type(opts) == "table" and opts or {}
    local clock = opts.clock or default_clock
    local identity = opts.identity or default_identity
    local reason = tostring(opts.reason or "rich_inventory")
    local source = opts.source_snapshot
    if type(source) ~= "table" then
        source = (opts.current_snapshot or default_current_snapshot)()
    end
    if type(source) ~= "table" then
        note_request("skip_no_source", { reason = reason, currentDepth = "" })
        return false
    end

    local extras = opts.extra_equipped
    if extras == nil then
        local ok_ex, got = pcall(default_extras)
        extras = (ok_ex and type(got) == "table") and got or {}
    end
    if type(extras) ~= "table" then extras = {} end

    local source_sig = identity(source)
    local item_rich = already_rich(source, extras)
    local fields = {
        reason = reason,
        currentDepth = tostring(source.depth or ""),
        sourceSig = source_sig,
        itemRich = item_rich,
    }

    if item_rich and opts.restart ~= true then
        note_request("skip_already_full", fields)
        return false
    end

    if job and opts.restart ~= true and job.source_sig == source_sig then
        if opts.replyTo ~= nil then job.replyTo = opts.replyTo end
        if opts.requester ~= nil then job.requester = opts.requester end
        note_request("skip_same_sig", fields)
        return true
    end

    local action = job and "restart" or "start"
    if job then
        cancel_job(opts.restart == true and "restart" or "replaced")
    end

    local work = build_work(source, extras)
    local d = diag()
    job = {
        reason = reason,
        source_sig = source_sig,
        source = source,
        partial_equipped = copy_list(source.equipped),
        partial_bags = copy_list(source.bags),
        extra_rows = {},
        work = work,
        cursor = 1,
        phase = work[1] and work[1].phase or "finalize",
        done = 0,
        total = #work,
        started_at = clock(),
        last_progress_at = clock(),
        last_phase = nil,
        replyTo = opts.replyTo,
        requester = opts.requester,
        items_per_slice = math.max(1, math.floor(tonumber(opts.items_per_slice) or cfg_items_per_slice())),
        enrich_item = opts.enrich_item or default_enrich,
        current_snapshot = opts.current_snapshot or default_current_snapshot,
        publish = opts.publish or default_publish,
        is_busy = opts.is_busy or default_is_busy,
        clock = clock,
        identity = identity,
        slice_guard_ms = tonumber(opts.slice_guard_ms) or SLICE_GUARD_MS,
        busy_starve_s = tonumber(opts.busy_starve_s) or BUSY_STARVE_S,
    }
    last_start_opts = {
        enrich_item = job.enrich_item,
        current_snapshot = job.current_snapshot,
        publish = job.publish,
        is_busy = job.is_busy,
        clock = job.clock,
        identity = job.identity,
        items_per_slice = job.items_per_slice,
        extra_equipped = opts.extra_equipped,
        probe_lite = opts.probe_lite,
        adopt_lite = opts.adopt_lite,
        inventory_probe = opts.inventory_probe,
        probe_collect_rows = opts.probe_collect_rows,
        probe_validate_rows = opts.probe_validate_rows,
    }
    recovery.pending = false
    recovery.cancelled_sig = ""
    stats.jobs_started = stats.jobs_started + 1
    note_request(action, fields)
    d.count("rich_inventory.job_started")
    d.event("rich_inventory.job_started", string.format(
        "reason=%s items=%d eq=%d bag=%d extra=%d per_slice=%d",
        job.reason, job.total, #(source.equipped or {}), #(source.bags or {}),
        #extras, job.items_per_slice))
    return true
end

function M.request(opts)
    opts = type(opts) == "table" and opts or {}
    local ok_e, engine_mod = pcall(require, 'engine')
    local Engine = ok_e and engine_mod and engine_mod.Engine or nil
    if Engine and Engine.ok then
        return M.start(opts)
    end
    pcall(function()
        local mq = require('mq')
        if mq and mq.cmd then mq.cmd('/squelch /tgearbg publish') end
    end)
    return false
end

local function apply_rich(entry, rich)
    if entry.list == "equipped" then
        job.partial_equipped[entry.i] = rich
    elseif entry.list == "bags" then
        job.partial_bags[entry.i] = rich
    else
        job.extra_rows[#job.extra_rows + 1] = rich
    end
end

local function promote()
    -- Re-check identity immediately before publish. Non-inventory fields
    -- (DoN/lockouts/spells/seq) may have moved while the job ran; inventory
    -- identity must still match or this promote is stale.
    local identity = job.identity or default_identity
    local current = job.current_snapshot and job.current_snapshot() or nil
    if type(current) ~= "table" then
        local now = (job.clock or default_clock)()
        arm_recovery(now)
        cancel_job("inventory_identity")
        return false
    end
    local live_sig = identity(current)
    if live_sig ~= "" and job.source_sig ~= "" and live_sig ~= job.source_sig then
        local now = (job.clock or default_clock)()
        arm_recovery(now)
        cancel_job("inventory_identity")
        return false
    end

    local d = diag()
    d.count("rich_inventory.phase.finalize")
    job.phase = "finalize"
    -- Latest current snap is the shell: newer DoN/lockouts/spells/seq survive.
    -- Overlay completed rich equipped/bags only.
    local out = copy_snap_shell(current)
    out.equipped = copy_list(job.partial_equipped)
    for _, extra in ipairs(job.extra_rows) do
        out.equipped[#out.equipped + 1] = extra
    end
    out.bags = copy_list(job.partial_bags)
    out.depth = "full"
    local published = job.publish(out, job)
    stats.promotes = stats.promotes + 1
    stats.jobs_completed = stats.jobs_completed + 1
    d.count("rich_inventory.promote")
    d.count("rich_inventory.job_completed")
    d.event("rich_inventory.promote", string.format(
        "reason=%s eq=%d bag=%d bank=%d preserved=%s",
        job.reason, #(out.equipped or {}), #(out.bags or {}), #(out.bank or {}),
        tostring(out.bankPreserved == true)))
    d.event("rich_inventory.job_completed", string.format("reason=%s items=%d elapsed=%.2fs",
        job.reason, job.total, math.max(0, job.clock() - job.started_at)))
    job = nil
    return published
end

function M.tick(opts)
    opts = type(opts) == "table" and opts or {}
    local clock = (job and job.clock) or last_start_opts.clock or opts.clock or default_clock
    local now = clock()

    if not job then
        try_recovery(now)
        if not job then return false end
    end

    local identity = job.identity or default_identity
    local current = job.current_snapshot()
    if type(current) == "table" then
        local live_sig = identity(current)
        if live_sig ~= "" and job.source_sig ~= "" and live_sig ~= job.source_sig then
            arm_recovery(now)
            cancel_job("inventory_identity")
            return false
        end
    end

    if job.cursor > job.total then
        return promote() and true or false
    end

    local busy, busy_why = job.is_busy()
    if busy then
        if (now - (job.last_progress_at or now)) < (job.busy_starve_s or BUSY_STARVE_S) then
            stats.yield_busy = stats.yield_busy + 1
            diag().count("rich_inventory.yield_busy")
            return false
        end
        busy_why = tostring(busy_why or "busy") .. "+starve"
    end

    local per_slice = math.max(1, math.floor(tonumber(job.items_per_slice) or 1))
    local t0 = now
    local n = 0
    local d = diag()
    while n < per_slice and job and job.cursor <= job.total do
        if n > 0 and ((clock() - t0) * 1000) >= (job.slice_guard_ms or SLICE_GUARD_MS) then
            break
        end
        local entry = job.work[job.cursor]
        job.phase = entry.phase
        if job.last_phase ~= entry.phase then
            job.last_phase = entry.phase
            d.count("rich_inventory.phase." .. tostring(entry.phase))
        end
        local rich = job.enrich_item(entry.row)
        if type(rich) ~= "table" then
            arm_recovery(clock())
            cancel_job("enrich_miss")
            return false
        end
        apply_rich(entry, rich)
        job.cursor = job.cursor + 1
        job.done = job.done + 1
        job.last_progress_at = clock()
        stats.item_steps = stats.item_steps + 1
        d.count("rich_inventory.item_step")
        n = n + 1
    end

    if n >= per_slice then
        stats.yield_op_limit = stats.yield_op_limit + 1
        d.count("rich_inventory.yield_op_limit")
    end

    if job and job.cursor > job.total then
        return promote() and true or false
    end
    return true
end

return M
