-- TurboGear/inventory_probe.lua
-- Cooperative lite inventory collector for rich-recovery fallback only.
-- Private until Pass A is complete and Pass B confirms the same canonical
-- identity. Never adopt/publish/Store.put/actor-send from this module.

local M = {}

local RETRY_S = 1.0

local job = nil
local stats = {
    started = 0,
    item_step = 0,
    validate_step = 0,
    validation_pass = 0,
    validation_retry = 0,
    completed = 0,
    cancelled = 0,
}

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

local function cfg_num(key, default, min_v)
    local ok, cfg = pcall(require, 'config')
    local n = ok and cfg and cfg.CFG and tonumber(cfg.CFG[key])
    if not n then n = default end
    if min_v and n < min_v then n = min_v end
    return n
end

local function default_clock()
    return os.clock()
end

local function default_identity(snap)
    local ok, snapshot = pcall(require, 'snapshot')
    if ok and snapshot and snapshot.inventory_identity then
        return snapshot.inventory_identity(snap)
    end
    return ""
end

local function default_current()
    local ok, snapshot = pcall(require, 'snapshot')
    if ok and snapshot and snapshot.cached then
        return snapshot.cached()
    end
    return nil
end

local function copy_shell(prior)
    local snap = {}
    if type(prior) == "table" then
        for k, v in pairs(prior) do
            if k ~= "equipped" and k ~= "bags" then
                snap[k] = v
            end
        end
    end
    snap.equipped = {}
    snap.bags = {}
    snap.depth = "lite"
    snap.inventoryIncomplete = false
    -- skipLockouts: nil means "not collected"; Store keeps last published map.
    snap.lockouts = nil
    snap._bis_index = nil
    snap._bis_index_key = nil
    return snap
end

local function append_row(candidate, list, row)
    if type(candidate) ~= "table" or type(row) ~= "table" then return end
    local key = list == "equipped" and "equipped" or "bags"
    candidate[key][#candidate[key] + 1] = row
end

local function row_list(row)
    if type(row) ~= "table" then return "bags" end
    if tostring(row.location or "") == "Equipped" then return "equipped" end
    return "bags"
end

local function begin_walk(job_ref)
    if type(job_ref.collect_rows) == "table" and job_ref.phase == "collect" then
        job_ref.cursor = 1
        return
    end
    if type(job_ref.validate_rows) == "table" and job_ref.phase == "validate" then
        job_ref.cursor = 1
        return
    end
    local ok, snapshot = pcall(require, 'snapshot')
    if ok and snapshot and snapshot.begin_lite_inventory_walk then
        job_ref.walk = snapshot.begin_lite_inventory_walk()
    else
        job_ref.walk = { phase = "done" }
    end
end

local function step_injected(job_ref)
    local rows = job_ref.phase == "validate" and job_ref.validate_rows or job_ref.collect_rows
    if type(rows) ~= "table" then return nil, true end
    local i = tonumber(job_ref.cursor) or 1
    if i > #rows then return nil, true end
    job_ref.cursor = i + 1
    local entry = rows[i]
    if type(entry) ~= "table" then return nil, false end
    if entry.row then
        return entry.row, false, entry.list or row_list(entry.row)
    end
    return entry, false, row_list(entry)
end

local function step_live(job_ref)
    local step = job_ref.step_lite
    if not step then
        local ok, snapshot = pcall(require, 'snapshot')
        if ok and snapshot then step = snapshot.step_lite_inventory_walk end
    end
    if not step then return nil, true end
    local row, done = step(job_ref.walk)
    if done then return nil, true end
    if type(row) == "table" then
        return row, false, row_list(row)
    end
    return nil, false
end

local function step_once(job_ref)
    if type(job_ref.collect_rows) == "table" or type(job_ref.validate_rows) == "table" then
        return step_injected(job_ref)
    end
    return step_live(job_ref)
end

local function target_candidate(job_ref)
    if job_ref.phase == "validate" then return job_ref.candidate_b end
    return job_ref.candidate_a
end

local function finish_collect(job_ref)
    job_ref.phase = "validate"
    job_ref.candidate_b = copy_shell(job_ref.prior)
    job_ref.occupied = 0
    job_ref.total = math.max(job_ref.total or 0, #(job_ref.candidate_a.equipped or {}) + #(job_ref.candidate_a.bags or {}))
    begin_walk(job_ref)
end

local function stamp_candidate(snap)
    local ok, snapshot = pcall(require, 'snapshot')
    if ok and snapshot and snapshot.stamp_inventory then
        snapshot.stamp_inventory(snap)
        return
    end
    local now = os.time()
    snap.updated = now
    snap.inventoryUpdated = now
end

local function finish_validate(job_ref)
    local ident = job_ref.identity or default_identity
    local sig_a = ident(job_ref.candidate_a)
    local sig_b = ident(job_ref.candidate_b)
    local d = diag()
    if sig_a ~= "" and sig_a == sig_b then
        stamp_candidate(job_ref.candidate_a)
        job_ref.candidate_a.depth = "lite"
        job_ref.candidate_a.inventoryIncomplete = false
        job_ref.phase = "complete"
        job_ref.candidate = job_ref.candidate_a
        stats.validation_pass = stats.validation_pass + 1
        stats.completed = stats.completed + 1
        d.count("inventory_probe.validation_pass")
        d.count("inventory_probe.completed")
        local elapsed_ms = math.max(0, ((job_ref.clock or default_clock)() - (tonumber(job_ref.started_at) or 0)) * 1000)
        d.sample("inventory_probe.total_elapsed", elapsed_ms)
        d.event("inventory_probe.completed", string.format(
            "eq=%d bag=%d bank=%d bankPreserved=%s elapsed=%.0fms",
            #(job_ref.candidate_a.equipped or {}),
            #(job_ref.candidate_a.bags or {}),
            #(job_ref.candidate_a.bank or {}),
            tostring(job_ref.candidate_a.bankPreserved == true),
            elapsed_ms))
        return
    end
    stats.validation_retry = stats.validation_retry + 1
    d.count("inventory_probe.validation_retry")
    local detail = "identity mismatch; discard A and B"
    pcall(function()
        local snapshot = require('snapshot')
        if not snapshot.inventory_identity_diff then return end
        local diff = snapshot.inventory_identity_diff(job_ref.candidate_a, job_ref.candidate_b)
        local function compact(s)
            s = tostring(s or "")
            if #s > 72 then return s:sub(1, 69) .. "..." end
            return s
        end
        local function n(v)
            return tonumber(v) or 0
        end
        local ca, cb = diff.counts_a or {}, diff.counts_b or {}
        local ba, bb = diff.bank_a or {}, diff.bank_b or {}
        detail = string.format(
            "identity mismatch; section=%s key=%s A=%s B=%s eq=%d/%d bags=%d/%d cursor=%d/%d bank=%d/%d bankValid=%s/%s bankLive=%s/%s bankPreserved=%s/%s bankCapturedAt=%s/%s",
            tostring(diff.section or "other"),
            compact(diff.key),
            compact(diff.a),
            compact(diff.b),
            n(ca.equipped), n(cb.equipped),
            n(ca.bags), n(cb.bags),
            n(ca.cursor), n(cb.cursor),
            n(ca.bank), n(cb.bank),
            tostring(ba.bankValid == true), tostring(bb.bankValid == true),
            tostring(ba.bankLive == true), tostring(bb.bankLive == true),
            tostring(ba.bankPreserved == true), tostring(bb.bankPreserved == true),
            tostring(ba.bankCapturedAt or "-"), tostring(bb.bankCapturedAt or "-"))
    end)
    d.event("inventory_probe.validation_retry", detail)
    local clock = job_ref.clock or default_clock
    local prior = job_ref.prior
    local opts = job_ref.opts
    job = nil
    -- Bounded retry: new Pass A/B after delay. Caller start()s again, or we
    -- leave a pending retry on a tiny stub job.
    job = {
        phase = "retry_wait",
        retry_due = clock() + (tonumber(opts.retry_s) or RETRY_S),
        opts = opts,
        prior = prior,
        identity = ident,
        clock = clock,
        started_at = clock(),
        occupied = 0,
        total = tonumber(opts.total) or 0,
        collect_rows = opts.collect_rows,
        validate_rows = opts.validate_rows,
        step_lite = opts.step_lite,
        cancelled_sig = opts.cancelled_sig,
    }
end

local function begin_collect(opts, prior)
    local clock = opts.clock or default_clock
    local total = tonumber(opts.total)
    if not total and type(prior) == "table" then
        total = #(prior.equipped or {}) + #(prior.bags or {})
    end
    job = {
        phase = "collect",
        opts = opts,
        prior = prior,
        identity = opts.identity or default_identity,
        clock = clock,
        started_at = clock(),
        occupied = 0,
        total = total or 0,
        candidate_a = copy_shell(prior),
        candidate_b = nil,
        candidate = nil,
        collect_rows = opts.collect_rows,
        validate_rows = opts.validate_rows or opts.collect_rows,
        step_lite = opts.step_lite,
        cancelled_sig = opts.cancelled_sig,
        items_per_slice = math.max(1, math.floor(tonumber(opts.items_per_slice)
            or cfg_num("inventory_probe_items_per_slice", 2, 1))),
        budget_ms = (function()
            local n = tonumber(opts.budget_ms)
            if n == nil then n = cfg_num("inventory_probe_budget_ms", 22, 1) end
            if n < 0 then n = 0 end
            return n
        end)(),
    }
    if job.items_per_slice > 2 then job.items_per_slice = 2 end
    begin_walk(job)
end

function M.reset()
    job = nil
    stats = {
        started = 0,
        item_step = 0,
        validate_step = 0,
        validation_pass = 0,
        validation_retry = 0,
        completed = 0,
        cancelled = 0,
    }
end

function M.active()
    return job ~= nil and job.phase ~= "complete" and job.phase ~= "cancelled"
        and job.phase ~= "same"
end

function M.take_candidate()
    if not job or job.phase ~= "complete" then return nil end
    local cand = job.candidate
    job = nil
    return cand
end

function M.stats()
    return stats
end

function M.status()
    if not job then
        return {
            active = false,
            phase = "idle",
            item = 0,
            total = 0,
            elapsed = 0,
            candidate = nil,
        }
    end
    local clock = job.clock or default_clock
    local now = clock()
    local item = tonumber(job.occupied) or 0
    if job.phase == "validate" and job.candidate_a then
        item = #(job.candidate_a.equipped or {}) + #(job.candidate_a.bags or {})
            + (tonumber(job.occupied) or 0)
        -- show validate progress as occupied in pass B
        item = tonumber(job.occupied) or 0
    elseif job.phase == "complete" and job.candidate_a then
        item = #(job.candidate_a.equipped or {}) + #(job.candidate_a.bags or {})
    end
    return {
        active = M.active(),
        phase = tostring(job.phase or "idle"),
        item = item,
        total = tonumber(job.total) or 0,
        elapsed = math.max(0, now - (tonumber(job.started_at) or now)),
        candidate = job.phase == "complete" and job.candidate or nil,
    }
end

function M.cancel(reason)
    if not job then return false end
    local phase = job.phase
    job.phase = "cancelled"
    job.candidate = nil
    stats.cancelled = stats.cancelled + 1
    diag().count("inventory_probe.cancelled")
    diag().event("inventory_probe.cancelled", string.format("reason=%s phase=%s",
        tostring(reason or "manual"), tostring(phase or "?")))
    job = nil
    return true
end

function M.start(opts)
    opts = type(opts) == "table" and opts or {}
    if job and job.phase ~= "complete" and job.phase ~= "cancelled"
        and job.phase ~= "same" and job.phase ~= "retry_wait" then
        return true
    end
    local prior = opts.prior
    if type(prior) ~= "table" then
        prior = (opts.current_snapshot or default_current)()
    end
    if type(prior) ~= "table" then return false end
    begin_collect(opts, prior)
    stats.started = stats.started + 1
    diag().count("inventory_probe.started")
    diag().event("inventory_probe.started", string.format(
        "eq=%d bag=%d bank=%d bankPreserved=%s",
        #(prior.equipped or {}), #(prior.bags or {}), #(prior.bank or {}),
        tostring(prior.bankPreserved == true)))
    return true
end

function M.tick()
    if not job then return false end
    local clock = job.clock or default_clock
    local now = clock()
    if job.phase == "retry_wait" then
        if now < (tonumber(job.retry_due) or 0) then return false end
        local opts = job.opts or {}
        local prior = job.prior
        begin_collect(opts, prior)
        return true
    end
    if job.phase == "complete" or job.phase == "same" or job.phase == "cancelled" then
        return false
    end

    local d = diag()
    local t0 = now
    local occupied = 0
    local max_occ = math.max(1, math.min(2, tonumber(job.items_per_slice) or 2))
    local budget_ms = tonumber(job.budget_ms) or 22
    local did = false

    d.time("inventory_probe.slice", function()
        while occupied < max_occ do
            local elapsed_ms = (clock() - t0) * 1000
            if occupied >= 1 and elapsed_ms >= budget_ms then
                break
            end
            local row, done, list
            d.time("inventory_probe.item", function()
                row, done, list = step_once(job)
            end)
            if done then
                if job.phase == "collect" then
                    finish_collect(job)
                else
                    finish_validate(job)
                end
                did = true
                break
            end
            if type(row) == "table" then
                append_row(target_candidate(job), list, row)
                occupied = occupied + 1
                job.occupied = (tonumber(job.occupied) or 0) + 1
                if job.phase == "validate" then
                    stats.validate_step = stats.validate_step + 1
                    d.count("inventory_probe.validate_step")
                else
                    stats.item_step = stats.item_step + 1
                    d.count("inventory_probe.item_step")
                end
                did = true
                elapsed_ms = (clock() - t0) * 1000
                -- One occupied row is guaranteed; yield after it if over budget.
                if elapsed_ms >= budget_ms then
                    break
                end
                if occupied >= max_occ then
                    break
                end
            else
                -- Empty-slot check. Continue until occupied or budget.
                if (clock() - t0) * 1000 >= budget_ms then
                    break
                end
            end
        end
    end)
    return did
end

return M
