-- TurboGear/don_state.lua
-- Four-state DoN mission model: unknown / active / replay / ready.
--
-- Phase 0 established, on Project Lazarus, that:
--   * Active tasks ARE readable from the Task TLO (id + title + expiry), and
--   * replay lockouts are NOT in DynamicZone.Timer or DZ_TimerList at all --
--     MacroQuest exposes replay timers only for dynamic zones, and DoN missions
--     are tasks. Chat is the only channel.
--
-- Both chat sources state a DURATION, so each is converted once to an absolute
-- expiry. Everything after that is arithmetic: camping, relogging, crashing and
-- offline peers all stay accurate with zero further reads, and nothing needs to
-- be polled. The two sources are:
--
--   passive grant : You have received a replay timer for 'NAME': 0d:4h:0m remaining.
--   /tasktime     : 'NAME' replay timer: 0d:3h:44m remaining.
--
-- Both carry a quoted name followed by the duration, so one pattern covers them.
-- Lazarus puts name and duration on ONE line, so unlike the donbis reference
-- this needs no header queue, FIFO pairing, or capture window.

local don_ref = require('references.don_lockouts')

local M = {}

--- Absence of a replay line means "not locked", but only if we actually looked.
--- Without this marker a first paint would report every mission as available.
--- Callers stamp it when a /tasktime sweep completes.
M.STATE_UNKNOWN = "unknown"
M.STATE_ACTIVE  = "active"
M.STATE_REPLAY  = "replay"
M.STATE_READY   = "ready"

--- An assigned task is live-only truth: unlike a replay expiry it cannot be
--- extrapolated forward. Past this age we stop claiming to know what a peer is
--- running, which is the same rule that stops a persisted row from resurrecting
--- a phantom active mission after a restart. Callers may narrow it; nobody has
--- to remember to ask for it.
M.ACTIVE_MAX_AGE_S = 900

-- Absolute expiries wobble a second between reads (each is recomputed as
-- now + remaining), so digests bucket them rather than hashing the raw value.
local SIG_BUCKET_S = 60

local function now_default()
    return os.time()
end

function M.new_state(now)
    return {
        capturedAt = tonumber(now) or nil,
        replays = {},
        active = {},
    }
end

--- Parse one chat line from either replay source.
--- Returns canonical row name, duration in seconds, and the raw quoted name;
--- nil when the line is not a replay notice or names no canonical mission.
--- Resolving through the canonical catalog is also what filters false positives
--- out of an intentionally loose pattern.
function M.parse_replay_line(line)
    -- Greedy, not lazy: "Volkara's Bite" and "Lavaspinner's Locals" contain an
    -- apostrophe, and a lazy capture closes on it and yields "Volkara". Both
    -- message formats put the duration after the final quote, so extending to
    -- the last quote is what actually delimits the name.
    local raw, d, h, m = tostring(line or ""):match("'(.*)'.-(%d+)d:(%d+)h:(%d+)m remaining")
    if not raw then return nil end
    local row = don_ref.lookup(raw)
    if not row then return nil end
    local seconds = (tonumber(d) or 0) * 86400 + (tonumber(h) or 0) * 3600 + (tonumber(m) or 0) * 60
    return row.name, seconds, raw
end

--- Fold a replay line into state. Durations are minute-resolution, so keep the
--- later expiry when the same mission is seen twice rather than letting a
--- rounded-down repeat pull the deadline backwards.
function M.apply_replay_line(state, line, now)
    if type(state) ~= "table" then return nil end
    local name, seconds = M.parse_replay_line(line)
    if not name then return nil end
    now = tonumber(now) or now_default()
    local expires_at = now + seconds
    state.replays = state.replays or {}
    local prev = tonumber(state.replays[name])
    if prev == nil or expires_at > prev then
        state.replays[name] = expires_at
    end
    return name, state.replays[name]
end

-- Task TLO access lives behind a seam so the resolver is testable without a
-- running client. Phase 0 verified the shape: Task(i) is dense from index 1 and
-- returns nil past the end, and Task() with NO argument errors, so it is never
-- used here.
--
-- The reader must distinguish three outcomes. Swallowing errors as nil made an
-- unreadable TLO look like an empty journal and would wipe a still-valid Active
-- set; that is the same "unknown is not open" rule the expedition path learned.
--
--   table  -> a task at this index
--   nil    -> no task (successful empty slot / end of list)
--   TASK_UNREADABLE -> the source could not be read; do not replace state.active
local task_reader = nil
M.TASK_UNREADABLE = {}

M.PROGRESS_UNFINISHED = "unfinished-active"
M.PROGRESS_COMPLETED  = "completed-journal-residue"
M.PROGRESS_UNREADABLE = "unreadable"

--- fn(index) -> rec table | nil | M.TASK_UNREADABLE
function M.set_task_reader(fn)
    task_reader = type(fn) == "function" and fn or nil
end

local TASK_CAP, TASK_MISS_STOP = 64, 8
local OBJ_CAP, OBJ_MISS_STOP = 16, 2

--- One required objective is complete when Status is Done, or current >= required.
--- Live Lazarus UI prints "Done"; MQ docs document "0/3"; RedGuides Lua compares
--- Status() == "Done". Accept all three rather than guessing which this client emits.
function M.objective_is_complete(obj)
    if type(obj) ~= "table" then return false end
    local status = tostring(obj.status or ""):lower()
    if status == "done" then return true end
    local a, b = status:match("^(%d+)%s*/%s*(%d+)$")
    if a and tonumber(b) and tonumber(b) > 0 then
        return tonumber(a) >= tonumber(b)
    end
    local cur, req = tonumber(obj.current), tonumber(obj.required)
    if cur and req and req > 0 then return cur >= req end
    return false
end

--- Classify a Task record as unfinished, completed journal residue, or unreadable.
---
--- rec.objectives omitted entirely means the reader did not inspect them (tests,
--- and the pre-objective seam). That is unfinished, not unreadable: presence
--- without an inspection is the old Active predicate, kept so a missing
--- Objective TLO cannot silently hide every live mission.
--- rec.objectives = {} (inspected, none found) is unreadable.
function M.classify_task(rec)
    if type(rec) ~= "table" then
        return M.PROGRESS_UNREADABLE, { required = 0, done = 0, unfinished = 0 }
    end
    if rec.objectives_readable == false then
        return M.PROGRESS_UNREADABLE, { required = 0, done = 0, unfinished = 0, objectives = rec.objectives }
    end
    if rec.objectives == nil then
        return M.PROGRESS_UNFINISHED, { required = 0, done = 0, unfinished = 0 }
    end
    if type(rec.objectives) ~= "table" then
        return M.PROGRESS_UNREADABLE, { required = 0, done = 0, unfinished = 0 }
    end

    local required, done, unfinished, saw = 0, 0, 0, 0
    for _, obj in ipairs(rec.objectives) do
        if type(obj) == "table" then
            saw = saw + 1
            if obj.optional == true then
                -- Optional leftover must not keep a finished mission Active.
            else
                required = required + 1
                if M.objective_is_complete(obj) then
                    done = done + 1
                else
                    unfinished = unfinished + 1
                end
            end
        end
    end
    local counts = { required = required, done = done, unfinished = unfinished, objectives = rec.objectives }
    if saw == 0 then
        return M.PROGRESS_UNREADABLE, counts
    end
    if required == 0 or unfinished == 0 then
        return M.PROGRESS_COMPLETED, counts
    end
    return M.PROGRESS_UNFINISHED, counts
end

local function read_objectives(t)
    local objs, misses = {}, 0
    for i = 1, OBJ_CAP do
        local ok, obj = pcall(function()
            local o = t.Objective(i)
            if o == nil then return nil end
            local status, instruction
            pcall(function() status = o.Status() end)
            pcall(function() instruction = o.Instruction() end)
            local optional
            pcall(function() optional = o.Optional() end)
            local current, required
            pcall(function() current = tonumber(o.CurrentCount()) end)
            pcall(function() required = tonumber(o.RequiredCount()) end)
            local status_s = status ~= nil and tostring(status) or ""
            local instr_s = instruction ~= nil and tostring(instruction) or ""
            if status_s == "" and instr_s == "" and current == nil and required == nil then
                return nil
            end
            return {
                index = i,
                status = status_s,
                instruction = instr_s,
                optional = optional == true,
                current = current,
                required = required,
            }
        end)
        if not ok then return nil, false end
        if obj == nil then
            misses = misses + 1
            if misses >= OBJ_MISS_STOP then break end
        else
            misses = 0
            objs[#objs + 1] = obj
        end
    end
    return objs, true
end

local function default_task_reader(index)
    local ok, mq = pcall(require, 'mq')
    if not ok or type(mq) ~= "table" or mq.TLO == nil then return M.TASK_UNREADABLE end
    if mq.TLO.Task == nil then return M.TASK_UNREADABLE end
    local got, rec = pcall(function()
        local t = mq.TLO.Task(index)
        if t == nil then return nil end
        local title = t.Title()
        if title == nil or tostring(title) == "" then return nil end
        local secs = nil
        pcall(function() secs = tonumber(t.Timer.TotalSeconds()) end)
        local objectives, readable = read_objectives(t)
        return {
            id = tonumber(t.ID()),
            title = tostring(title),
            timer_seconds = secs,
            objectives = objectives or {},
            objectives_readable = readable ~= false,
        }
    end)
    if not got then return M.TASK_UNREADABLE end
    return rec
end

--- Authoritative replacement of the Active set from one successful Task scan.
---
--- Presence in Task[] is no longer enough: Lazarus leaves completed DoN missions
--- in the journal with every required objective Done. Only an unfinished
--- required objective becomes Active. Replay state is never touched here.
---
--- Returns found, status where status is "ok" or "unreadable". On unreadable
--- the previous Active set is left intact; ACTIVE_MAX_AGE is what ages it out.
function M.refresh_active(state, now)
    if type(state) ~= "table" then return 0, "invalid" end
    now = tonumber(now) or now_default()
    local read = task_reader or default_task_reader
    local next_active, found, misses = {}, 0, 0
    for i = 1, TASK_CAP do
        local rec = read(i)
        if rec == M.TASK_UNREADABLE then
            -- Successful empty is nil slots, not this sentinel. Leave Active
            -- and activeAt alone; ACTIVE_MAX_AGE is what ages a stuck copy out.
            local n = 0
            for _ in pairs(state.active or {}) do n = n + 1 end
            return n, "unreadable"
        end
        if type(rec) ~= "table" or tostring(rec.title or "") == "" then
            misses = misses + 1
            if misses >= TASK_MISS_STOP then break end
        else
            misses = 0
            -- Numeric task id is the strongest identity; the normalized title is
            -- the fallback, and tolerates the trailing space the client emits.
            local row = (rec.id and don_ref.lookup(tostring(rec.id))) or don_ref.lookup(rec.title)
            if row then
                local progress = M.classify_task(rec)
                if progress == M.PROGRESS_UNFINISHED then
                    next_active[row.name] = {
                        id = rec.id,
                        title = rec.title,
                        expires_at = rec.timer_seconds and (now + rec.timer_seconds) or nil,
                    }
                    found = found + 1
                elseif progress == M.PROGRESS_UNREADABLE then
                    -- Cannot tell unfinished from residue. Keep a previous Active
                    -- fact for this row so a broken Objective TLO does not flip
                    -- the mission to Ready; do not invent Active if we never had one.
                    local prev = state.active and state.active[row.name]
                    if type(prev) == "table" then
                        next_active[row.name] = prev
                        found = found + 1
                    end
                end
            end
        end
    end
    state.active = next_active
    state.activeAt = now
    return found, "ok"
end

--- Resolve one canonical row to a display state.
--- Precedence is active > replay > ready > unknown. Completing a Lazarus DoN
--- mission leaves the journal entry in place with every objective Done, so
--- Active is unfinished-task truth, not mere presence; replay is independent
--- and still returned alongside when both facts exist.
--- A stale active task degrades to unknown rather than being believed, since an
--- assigned task is live-only truth; replay expiries are absolute and do not
--- rot. opts.active_max_age narrows the default (see ACTIVE_MAX_AGE_S above) --
--- the guard applies whether or not a caller remembers to ask for it, because
--- the cost of forgetting is a peer shown running a mission they finished.
function M.resolve(state, row_name, now, opts)
    if type(state) ~= "table" or tostring(row_name or "") == "" then
        return M.STATE_UNKNOWN, nil
    end
    now = tonumber(now) or now_default()
    opts = type(opts) == "table" and opts or {}

    local replay_at = tonumber(state.replays and state.replays[row_name])
    local locked = replay_at ~= nil and replay_at > now

    local active = state.active and state.active[row_name]
    if type(active) == "table" then
        local max_age = tonumber(opts.active_max_age) or M.ACTIVE_MAX_AGE_S
        local age = now - (tonumber(state.activeAt or state.capturedAt) or 0)
        local stale = max_age ~= nil and age > max_age
        if not stale then
            return M.STATE_ACTIVE, {
                id = active.id,
                title = active.title,
                expires_at = active.expires_at,
                replay_expires_at = locked and replay_at or nil,
            }
        end
        -- Too old to trust as live assignment. Fall through: a still-valid
        -- replay is the display state; otherwise Unknown, never Ready.
        if not locked then
            return M.STATE_UNKNOWN, { reason = "stale-active", age = age }
        end
    end

    if locked then
        return M.STATE_REPLAY, { expires_at = replay_at, remaining = replay_at - now }
    end

    -- Never report "ready" on data we never gathered.
    if tonumber(state.capturedAt) == nil then
        return M.STATE_UNKNOWN, { reason = "no-capture" }
    end
    return M.STATE_READY, nil
end

--- Semantic digest of one character's DoN state.
---
--- This decides both whether a change is worth publishing and whether a
--- received peer row is worth writing to disk, so it must name facts rather
--- than motion. Expiries are absolute and bucketed; ids identify the assignment.
---
--- Deliberately absent: capturedAt and activeAt as values, remaining seconds,
--- titles, and any in-flight request state -- all of those advance constantly
--- and would rewrite every peer row on every heartbeat. capturedAt contributes
--- only as a yes/no, because unknown -> ready is a real state change even when
--- the character holds nothing.
---
--- Expiry needs no entry of its own here. A replay deadline is absolute, so
--- every consumer flips that row to ready on its own clock with no traffic at
--- all; the entry lingering until prune costs one write long after it stopped
--- mattering.
function M.signature(state)
    if type(state) ~= "table" then return "" end
    local parts = { tonumber(state.capturedAt) ~= nil and "C1" or "C0" }
    for name, expires_at in pairs(state.replays or {}) do
        parts[#parts + 1] = string.format("R|%s:%d", tostring(name),
            math.floor((tonumber(expires_at) or 0) / SIG_BUCKET_S))
    end
    for name, rec in pairs(state.active or {}) do
        local id = type(rec) == "table" and rec.id or nil
        local expires_at = type(rec) == "table" and tonumber(rec.expires_at) or nil
        parts[#parts + 1] = string.format("A|%s:%s:%d", tostring(name), tostring(id or ""),
            math.floor((expires_at or 0) / SIG_BUCKET_S))
    end
    table.sort(parts)
    return table.concat(parts, "\31")
end

--- Drop replay entries that expired long enough ago to be noise. Keeps the
--- persisted payload from growing without bound across sessions.
function M.prune(state, now, grace)
    if type(state) ~= "table" or type(state.replays) ~= "table" then return 0 end
    now = tonumber(now) or now_default()
    grace = tonumber(grace) or 3600
    local removed = 0
    for name, expires_at in pairs(state.replays) do
        if (tonumber(expires_at) or 0) + grace < now then
            state.replays[name] = nil
            removed = removed + 1
        end
    end
    return removed
end

return M
