-- TurboGear/don_track.lua
-- Runtime layer for DoN mission state: chat capture, demand-driven /tasktime,
-- and the copy that rides along in snap.lockouts.
--
-- don_state.lua stays pure (no mq, no clocks of its own) so it can be tested
-- offline; everything that touches the client lives here.
--
-- Two rules shape this module:
--
--  1. Never block. The reference implementation waits out /tasktime in a
--     2500ms mq.delay loop, which stalls the Lua coroutine and, by its own
--     comments, can pause MQOverlay. /tasktime has no terminator line, so a
--     settle deadline is unavoidable -- but it can be waited out by the normal
--     tick loop instead of by blocking. Nothing here sleeps.
--
--  2. Never issue commands from a draw or actor callback. The UI only sets a
--     flag; tick() is what actually talks to the client.

local mq = require('mq')
local diag = require('diagnostics')
local don_state = require('don_state')

local M = {}

-- /tasktime output arrives asynchronously over roughly a second. donbis waits
-- 2500ms; 3s buys margin on a loaded client, and costs nothing because we are
-- not blocking on it.
local SETTLE_S = 3.0
-- Guards against a tab being toggled repeatedly. Replay timers are hours long,
-- so there is no value in asking more often than this.
local REFRESH_COOLDOWN_S = 30.0
-- Assigned tasks change only when you accept or complete one, so re-reading the
-- journal on the lockout gather cadence is enough.
local ACTIVE_TTL_S = 30.0

-- Deadlines use a monotonic clock; expiries use wall time, because they are
-- persisted and compared across sessions. Keeping the two separate is
-- deliberate -- os.clock() resets per process and would corrupt stored expiries.
local clock = os.clock
local wall = os.time
local function issue(command) mq.cmd(command) end

local state = don_state.new_state(nil)
local want_refresh = false
local want_active_refresh = false
local settle_until = nil
local last_request_at = nil
local active_read_at = nil
local events_ready = false

--- Test seam: drive time and command issuance without a client.
function M._set_seams(opts)
    opts = type(opts) == "table" and opts or {}
    clock = type(opts.clock) == "function" and opts.clock or os.clock
    wall = type(opts.wall) == "function" and opts.wall or os.time
    issue = type(opts.issue) == "function" and opts.issue or function(c) mq.cmd(c) end
end

function M._reset_for_tests()
    state = don_state.new_state(nil)
    want_refresh, want_active_refresh = false, false
    settle_until, last_request_at = nil, nil
    active_read_at, events_ready = nil, false
    M._prior_authority_for_tests = false
    M._set_seams(nil)
end

--- Fold one chat line into state. Safe to call with anything; non-replay lines
--- are ignored by the parser.
function M.ingest(line)
    local name = don_state.apply_replay_line(state, line, wall())
    if name then diag.count("don.replay_captured") end
    return name
end

-- One pattern covers both sources: "You have received a replay timer for 'X':
-- 0d:4h:0m remaining." and "'X' replay timer: 0d:3h:44m remaining." Matching
-- loosely here and discriminating in Lua costs one extra pattern check per chat
-- line instead of two, and keeps the format knowledge in one place.
function M.ensure_events()
    if events_ready then return end
    events_ready = true
    pcall(function()
        mq.event('tgDonReplayTimer', '#*#replay timer#*#', function(line)
            M.ingest(line)
        end)
    end)
end

--- Called from UI draw code. Only sets a flag -- see rule 2 above.
function M.note_refresh_wanted()
    want_refresh = true
end

--- Tab-entry / diagnostic: force one Active journal read on the next tick.
--- Does not issue /tasktime and does not bypass its cooldown. Draw must not
--- call refresh_active_if_due itself -- that is a Task[] walk.
function M.note_active_refresh_wanted()
    want_active_refresh = true
end

--- Edge-triggered DoN-tab entry: one /tasktime (cooldown permitting) plus one
--- forced Active read on the next tick. Opening the tab again does not queue
--- extra commands; the flags are booleans.
function M.note_tab_enter()
    want_refresh = true
    want_active_refresh = true
end

--- Command the local bg responder uses for viewer tab-entry peer freshness.
--- Not a new actor protocol: same /tgearbg bind as Sync Now / spellsync.
M.TAB_REFRESH_CMD = '/squelch /tgearbg donrefresh'

--- True when this process has a local /tasktime or forced-Active flag queued.
function M.local_collector_wanted()
    return want_refresh == true or want_active_refresh == true
end

--- Viewer/UI tab entry. Never both direct and delegated.
---
---   Engine.ok  -> local collector flags + Engine.request_all (this process
---                 owns the mailbox, so it IS the responder)
---   otherwise  -> /tgearbg donrefresh only. The viewer must not schedule
---                 Task[] or /tasktime: those belong on the bg VM.
--- Draw must not call this; ui.lua fires it once when the tab becomes selected.
function M.ui_tab_enter(opts)
    opts = type(opts) == "table" and opts or {}
    diag.count("don.tab_enter")

    local engine_ok = opts.engine_ok
    if engine_ok == nil then
        local ok, Engine = pcall(function() return require('engine').Engine end)
        engine_ok = ok and type(Engine) == "table" and Engine.ok == true
    end

    if engine_ok then
        M.note_tab_enter()
        diag.count("don.tab_refresh_direct")
        diag.event("don.tab_enter", "direct")
        if type(opts.request_all) == "function" then
            opts.request_all()
        else
            pcall(function()
                require('engine').Engine.request_all(false, { depth = "lite" })
            end)
        end
        return "direct"
    end

    diag.count("don.tab_refresh_delegated")
    diag.event("don.tab_enter", "delegated")
    local cmd = M.TAB_REFRESH_CMD
    if type(opts.delegate) == "function" then
        opts.delegate(cmd)
    else
        pcall(issue, cmd)
    end
    return "delegated"
end

--- Pumped from the main loop. Issues at most one /tasktime, then stamps
--- capturedAt when the settle window closes.
function M.tick()
    M.ensure_events()
    local now = clock()

    if want_active_refresh then
        want_active_refresh = false
        M.refresh_active_if_due(true)
    end

    if want_refresh and settle_until == nil
        and (last_request_at == nil or (now - last_request_at) >= REFRESH_COOLDOWN_S) then
        want_refresh = false
        last_request_at = now
        settle_until = now + SETTLE_S
        diag.count("don.tasktime_requested")
        pcall(issue, '/tasktime')
    end

    -- The trap this ordering exists to avoid: /tasktime prints only ACTIVE
    -- replay timers, so absence means ready -- but only once the output has
    -- arrived. Stamping capturedAt when the command is SENT would report every
    -- locked mission as available for the ~1-2s until the lines land.
    if settle_until ~= nil and now >= settle_until then
        settle_until = nil
        state.capturedAt = wall()
        diag.count("don.capture_settled")
        local n = 0
        for _ in pairs(state.replays or {}) do n = n + 1 end
        diag.count("don.replay_authority_replaced")
        diag.event("don.replay_authority_replaced", "replay=" .. tostring(n))
    end

    -- Idle Active refresh lives here, not on the lockout watcher (that tick
    -- already reads DynamicZone). Bg responders only -- a viewer tick must
    -- not walk Task[]. Skip when the heartbeat already paid for a native TLO
    -- family this frame. package.loaded only -- never require engine/state.
    if not want_active_refresh then
        local st = package.loaded.state
        local is_bg = type(st) == "table" and st.bg == true
        local eng = package.loaded.engine
        local heavy = type(eng) == "table" and eng.Engine and eng.Engine._heavy_tlo
        if is_bg and not heavy then
            M.refresh_active_if_due()
        end
    end
end

--- True once a /tasktime sweep has completed; until then every row is unknown.
function M.captured()
    return tonumber(state.capturedAt) ~= nil
end

function M.pending()
    return settle_until ~= nil or want_refresh or want_active_refresh
end

--- Rate-limited journal read. This is the only thing that notices a mission
--- being accepted or completed, so it cannot live solely behind embed(): a bg
--- responder that is not publishing lockouts would never run it, and accepting
--- a mission on that box would never reach the fleet. tick() drives it on the
--- TTL, never on the same frame as a DynamicZone lockout watch.
---
--- force=true bypasses the TTL. Diagnostics must do that: otherwise a Remove
--- that emptied the journal still printed the previous Active set because the
--- raw Task dump was fresh and the collector was not.
function M.refresh_active_if_due(force)
    local now = clock()
    if not force and active_read_at ~= nil and (now - active_read_at) < ACTIVE_TTL_S then return false end
    active_read_at = now
    diag.time("don.refresh_active", function()
        don_state.refresh_active(state, wall())
    end)
    don_state.prune(state, wall())
    return true
end

--- Digest of the semantic state, for change detection. A plain read: refreshing
--- is refresh_active_if_due's job, so a caller polling this cannot accidentally
--- turn it into a journal scan.
function M.signature()
    return don_state.signature(state)
end

local function copy_state()
    local out = {
        capturedAt = state.capturedAt,
        activeAt = state.activeAt,
        replays = {},
        active = {},
    }
    for k, v in pairs(state.replays or {}) do out.replays[k] = v end
    for k, v in pairs(state.active or {}) do
        out.active[k] = { id = v.id, title = v.title, expires_at = v.expires_at }
    end
    return out
end

-- Last captured replay authority for THIS character. Publication-time only:
-- the runtime collector is not hydrated from Store on startup (it starts C0),
-- so a REQUEST that publishes before /tasktime settles would otherwise ship
-- unknown over a persisted C1. Store is the source of last-known captured
-- replay; we never copy persisted Active from it.
local function prior_replay_authority()
    -- false: test isolation (do not consult Store). nil: production Store lookup.
    if M._prior_authority_for_tests == false then return nil end
    if type(M._prior_authority_for_tests) == "table" then
        local prior = M._prior_authority_for_tests
        if tonumber(prior.capturedAt) ~= nil then return prior end
        return nil
    end
    local prior
    pcall(function()
        local store_mod = require('store')
        local Store = store_mod.Store
        local key = store_mod.my_key and store_mod.my_key()
        local row = (key and Store and Store.get) and Store.get(key) or nil
        prior = row and row.lockouts and row.lockouts.DoNState
    end)
    if type(prior) == "table" and tonumber(prior.capturedAt) ~= nil then return prior end
    return nil
end

--- DoNState attached to a snapshot about to be published / Store.put.
--- Fresh Active always comes from the live collector. Replay authority is
--- local only after a completed /tasktime sweep; while captured=false the
--- last captured Store replay (if any) is preserved so pending C0 cannot
--- destroy C1. No prior capture stays Unknown -- we do not manufacture C1.
local function state_for_publish()
    local out = copy_state()
    if tonumber(out.capturedAt) ~= nil then return out end
    local prior = prior_replay_authority()
    if not prior then return out end
    local n = 0
    local merged = {}
    for k, v in pairs(prior.replays or {}) do
        merged[k] = v
        n = n + 1
    end
    -- Session chat grants overlay the preserved set; they are real even
    -- before /tasktime settles. They never wipe a prior mission.
    for k, v in pairs(out.replays or {}) do
        merged[k] = v
    end
    out.replays = merged
    out.capturedAt = prior.capturedAt
    diag.count("don.replay_authority_preserved")
    diag.event("don.replay_authority_preserved",
        string.format("oldCaptured=true oldReplay=%d reason=pending", n))
    return out
end

--- Read-only copy of the in-memory collector. Draw uses this for the local
--- column; it must never trigger a journal read or /tasktime. Uncaptured
--- C0 here is honest -- publication is what must not destroy Store C1.
function M.current()
    return copy_state()
end

--- Attach publishable state to a lockout map. Self-regulating: the journal
--- read is rate limited here rather than at every call site, so callers can
--- invoke this on any path without thinking about cost.
function M.embed(data)
    if type(data) ~= "table" then return data end
    M.refresh_active_if_due()
    data.DoNState = state_for_publish()
    return data
end

--- Per-row shadow readout, for validating the new resolver against real server
--- state before the matrix is switched over to it. Reports each source
--- separately so an acquisition failure, a canonical-mapping failure and a
--- resolver disagreement cannot be confused for one another.
function M.diagnose()
    local out = {}
    local function add(fmt, ...)
        out[#out + 1] = select('#', ...) > 0 and string.format(fmt, ...) or fmt
    end

    local don_ref = require('references.don_lockouts')
    local me = "?"
    pcall(function() me = tostring(mq.TLO.Me.CleanName()) end)
    local now = wall()

    -- Force a fresh journal read so this dump cannot disagree with state.active
    -- merely because the 30s TTL has not elapsed.
    M.refresh_active_if_due(true)

    add("[TurboGear] DoN diag: %s", me)
    add("  captured: %s%s, pending: %s",
        tostring(M.captured()),
        state.capturedAt and string.format(" (%ds ago)", now - state.capturedAt) or "",
        tostring(M.pending()))
    add("  signature: %s", M.signature())
    add("  active read: %s", state.activeAt and string.format("%ds ago", now - state.activeAt) or "never")
    add("  active rows: %d", (function()
        local n = 0
        for _ in pairs(state.active or {}) do n = n + 1 end
        return n
    end)())

    -- Raw journal, before canonical mapping: a mission assigned but absent from
    -- the rows below is a mapping gap, not an acquisition gap. Objective lines
    -- are why a still-listed task may not be Active.
    add("  Task journal (raw):")
    local seen_tasks = 0
    for i = 1, 32 do
        local rec
        pcall(function()
            local t = mq.TLO.Task(i)
            if t == nil then return end
            local title = t.Title()
            if title == nil or tostring(title) == "" then return end
            rec = { id = tonumber(t.ID()), title = tostring(title), objectives = {} }
            local misses = 0
            for oi = 1, 16 do
                local obj
                pcall(function()
                    local o = t.Objective(oi)
                    if o == nil then return end
                    local status, instruction, optional, current, required
                    pcall(function() status = o.Status() end)
                    pcall(function() instruction = o.Instruction() end)
                    pcall(function() optional = o.Optional() end)
                    pcall(function() current = tonumber(o.CurrentCount()) end)
                    pcall(function() required = tonumber(o.RequiredCount()) end)
                    local status_s = status ~= nil and tostring(status) or ""
                    local instr_s = instruction ~= nil and tostring(instruction) or ""
                    if status_s == "" and instr_s == "" and current == nil and required == nil then return end
                    obj = {
                        index = oi,
                        status = status_s,
                        instruction = instr_s,
                        optional = optional == true,
                        current = current,
                        required = required,
                    }
                end)
                if not obj then
                    misses = misses + 1
                    if misses >= 2 then break end
                else
                    misses = 0
                    rec.objectives[#rec.objectives + 1] = obj
                end
            end
            rec.objectives_readable = #rec.objectives > 0
        end)
        if rec then
            seen_tasks = seen_tasks + 1
            local row = (rec.id and don_ref.lookup(tostring(rec.id))) or don_ref.lookup(rec.title)
            local progress, counts = don_state.classify_task(rec)
            add("    [%d] id=%s title=%q -> %s", i, tostring(rec.id), rec.title,
                row and row.name or "(not a DoN row)")
            add("         objectives: readable=%s required=%d done=%d unfinished=%d -> %s",
                tostring(rec.objectives_readable == true),
                counts and counts.required or 0,
                counts and counts.done or 0,
                counts and counts.unfinished or 0,
                progress)
            for _, obj in ipairs(rec.objectives or {}) do
                add("           [%d] status=%q optional=%s current=%s required=%s %s",
                    obj.index, obj.status, tostring(obj.optional),
                    tostring(obj.current), tostring(obj.required),
                    obj.instruction ~= "" and obj.instruction or "")
            end
        end
    end
    if seen_tasks == 0 then add("    (none)") end

    -- Only rows with something to say; all 36 every time would bury it.
    add("  Rows with state:")
    local shown = 0
    for _, row in ipairs(don_ref.all_rows()) do
        local resolved, info = don_state.resolve(state, row.name, now)
        local replay_at = tonumber(state.replays and state.replays[row.name])
        local active = state.active and state.active[row.name]
        if resolved ~= don_state.STATE_READY or replay_at or active then
            shown = shown + 1
            local bits = { string.format("%-6s", resolved) }
            if type(active) == "table" then
                bits[#bits + 1] = string.format("active(id=%s, title=%q, expires=%s)",
                    tostring(active.id), tostring(active.title),
                    active.expires_at and os.date("%H:%M:%S", active.expires_at) or "none")
            end
            if replay_at then
                bits[#bits + 1] = string.format("replay(expires=%s, %s)",
                    os.date("%Y-%m-%d %H:%M:%S", replay_at),
                    replay_at > now and string.format("%dm left", math.floor((replay_at - now) / 60)) or "PASSED")
            end
            if type(info) == "table" and info.reason then
                bits[#bits + 1] = "reason=" .. tostring(info.reason)
            end
            add("    %-28s %s", row.name, table.concat(bits, " "))
        end
    end
    if shown == 0 then
        add("    (none -- every row resolves %s)",
            M.captured() and don_state.STATE_READY or don_state.STATE_UNKNOWN)
    end

    -- The visible matrix now reads don_state, not DynamicZone. This comparison
    -- stays in dondiag until live UI validation; it is not shown on the DoN tab.
    local ok_lo, lo = pcall(require, 'lockouts')
    if ok_lo and type(lo) == "table" and type(lo.gather_local) == "function" then
        -- Explicitly silent: a diagnostic must never flash the Expedition
        -- window, which the legacy boolean form would permit on a cache miss.
        local got, map = pcall(function()
            return lo.gather_local({ bypass_cache = false, allow_window_fallback = false })
        end)
        local old_locked = 0
        if got and type(map) == "table" and type(map.DoN) == "table" then
            for _, rec in pairs(map.DoN) do
                if type(rec) == "table" and rec.found == true then old_locked = old_locked + 1 end
            end
        end
        add("  old visible matrix (DynamicZone-derived DoN rows): %d locked", old_locked)
    end

    -- What THIS process currently has in Store for every peer. Local don_track
    -- above is this box's own collector; the promoted matrix reads live
    -- don_track.current() for __self__ when it has facts, and Store DoNState
    -- for peers.
    add("  Store DoN rows (what this process currently holds):")
    local ok_store, store = pcall(function() return require('store').Store end)
    if not (ok_store and type(store) == "table" and type(store.sources) == "table") then
        add("    (Store unavailable)")
        return out
    end
    local keys = {}
    for key in pairs(store.sources) do keys[#keys + 1] = tostring(key) end
    table.sort(keys)
    if #keys == 0 then add("    (none)") end
    local function remaining_label(expires_at)
        local rem = (tonumber(expires_at) or 0) - now
        if rem <= 0 then return "expired" end
        local d = math.floor(rem / 86400)
        local h = math.floor((rem % 86400) / 3600)
        local m = math.floor((rem % 3600) / 60)
        if d > 0 then return string.format("%dD:%dH", d, h) end
        if h > 0 then return string.format("%dH:%dM", h, m) end
        return string.format("%dM", m)
    end
    for _, key in ipairs(keys) do
        local row = store.sources[key]
        local ds = type(row) == "table" and type(row.lockouts) == "table" and row.lockouts.DoNState or nil
        if type(ds) ~= "table" then
            add("    %s: no DoNState", key)
        else
            local n_active, n_replay = 0, 0
            for _ in pairs(ds.active or {}) do n_active = n_active + 1 end
            for _ in pairs(ds.replays or {}) do n_replay = n_replay + 1 end
            add("    %s: captured=%s active=%d replay=%d sig=%s",
                key, tostring(tonumber(ds.capturedAt) ~= nil), n_active, n_replay,
                don_state.signature(ds))
            for _, crow in ipairs(don_ref.all_rows()) do
                local resolved, info = don_state.resolve(ds, crow.name, now)
                if resolved ~= don_state.STATE_READY then
                    local extra = ""
                    if resolved == don_state.STATE_REPLAY and info and info.expires_at then
                        extra = " " .. remaining_label(info.expires_at)
                    elseif resolved == don_state.STATE_ACTIVE then
                        extra = info and info.title and (" " .. tostring(info.title)) or ""
                    elseif resolved == don_state.STATE_UNKNOWN and info and info.reason then
                        extra = " reason=" .. tostring(info.reason)
                    end
                    add("      %-28s %s%s", crow.name, resolved, extra)
                end
            end
        end
        local change = store.last_content_change_by_key and store.last_content_change_by_key[key]
        if type(change) == "table" then
            add("      last content_changed: source=%s don=%s locked=%s v=%s",
                tostring(change.source), tostring(change.don),
                tostring(change.locked), tostring(change.version))
        end
    end
    return out
end

--- Diagnostic: current counts, for the shadow comparison.
function M.summary()
    local replays, active = 0, 0
    for _ in pairs(state.replays or {}) do replays = replays + 1 end
    for _ in pairs(state.active or {}) do active = active + 1 end
    return {
        captured = M.captured(),
        capturedAt = state.capturedAt,
        replays = replays,
        active = active,
        pending = M.pending(),
    }
end

return M
