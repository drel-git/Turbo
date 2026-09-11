-- TurboGear/don_matrix.lua
-- Pure presentation over don_state.resolve(). The DoN tab draws this; it does
-- not scan Task[], issue /tasktime, publish, or touch Store.
--
-- Countdown remaining is (expiresAt - now) computed at draw time. Calling
-- present() twice with different now values changes the label only -- never
-- the underlying DoNState or its semantic signature.

local don_state = require('don_state')

local M = {}

M.KIND_ACTIVE  = don_state.STATE_ACTIVE
M.KIND_REPLAY  = don_state.STATE_REPLAY
M.KIND_READY   = don_state.STATE_READY
M.KIND_UNKNOWN = don_state.STATE_UNKNOWN

function M.state_from_snap(snap)
    local lo = type(snap) == "table" and snap.lockouts or nil
    if type(lo) ~= "table" then return nil end
    return type(lo.DoNState) == "table" and lo.DoNState or nil
end

--- True when this blob has any authority at all: a completed /tasktime sweep,
--- a journal stamp, or at least one replay/active fact. Empty uncaptured state
--- is not authority -- that is what keeps a restart from painting Ready.
function M.has_facts(state)
    if type(state) ~= "table" then return false end
    if tonumber(state.capturedAt) ~= nil then return true end
    if tonumber(state.activeAt) ~= nil then return true end
    if type(state.replays) == "table" then
        for _ in pairs(state.replays) do return true end
    end
    if type(state.active) == "table" then
        for _ in pairs(state.active) do return true end
    end
    return false
end

--- Wall-clock authority of one DoNState blob. capturedAt is a completed
--- /tasktime sweep; activeAt is a journal read. Chat grants do not bump either,
--- so equal stamps still prefer live (it can be ahead of persist).
function M.authority_stamp(state)
    if type(state) ~= "table" then return 0 end
    local captured = tonumber(state.capturedAt) or 0
    local active = tonumber(state.activeAt) or 0
    if active > captured then return active end
    return captured
end

--- Self: one whole DoNState object, never a field-wise merge.
---
--- Dual-process UI+bg can disagree in both directions:
---   live newer than Store -- persist lag, tab-enter Active, chat grant
---   Store newer than live -- bg watcher published Active while the viewer
---     collector still holds an older captured Ready
--- has_facts(live) alone would pick the stale viewer blob in the second case.
--- Empty live must not hide a persisted self row on UI startup.
---
--- Used only on an engine-owner process. Viewer self never reaches here:
--- a fresh Active scan stamps activeAt on an uncaptured C0 blob and that
--- stamp would beat an older captured Store C1 as a whole state.
function M.prefer_self_state(live, stored)
    local live_ok = M.has_facts(live)
    local store_ok = M.has_facts(stored)
    if live_ok and not store_ok then return live, "live" end
    if store_ok and not live_ok then return stored, "store" end
    if not live_ok then return live, "live" end
    local live_at = M.authority_stamp(live)
    local store_at = M.authority_stamp(stored)
    if store_at > live_at then return stored, "store" end
    return live, "live"
end

local function engine_is_owner(override)
    if override ~= nil then return override == true end
    local ok, Engine = pcall(function()
        return require('engine').Engine
    end)
    return ok and type(Engine) == "table" and Engine.ok == true
end

--- Resolve the DoNState blob a matrix cell should read.
--- live_override / engine_ok_override are test seams.
---
--- Viewer (Engine.ok == false): __self__ is Store snapshot DoNState only.
--- Viewer-local don_track.current() is not matrix authority -- collection
--- was removed from that process, and a C0 blob with a newer activeAt
--- must not hide captured Store Ready/Replay.
--- Engine owner: live don_track.current() vs Store via prefer_self_state.
--- Peers: Store DoNState always. No Active/Replay merge here.
function M.state_for_key(key, snap, live_override, engine_ok_override)
    local stored = M.state_from_snap(snap)
    if tostring(key or "") ~= "__self__" then
        return stored, "store"
    end
    if not engine_is_owner(engine_ok_override) then
        return stored, "store"
    end
    local live = live_override
    if live == nil then
        pcall(function()
            local dt = require('don_track')
            if type(dt.current) == "function" then live = dt.current() end
        end)
    end
    return M.prefer_self_state(live, stored)
end

function M.format_remaining(seconds)
    local sec = math.max(0, math.floor(tonumber(seconds) or 0))
    local d = math.floor(sec / 86400); sec = sec % 86400
    local h = math.floor(sec / 3600); sec = sec % 3600
    local m = math.floor(sec / 60)
    if d > 0 then return string.format("%dD:%02dH:%02dM", d, h, m) end
    if h > 0 then return string.format("%dH:%02dM", h, m) end
    return string.format("%dM", m)
end

--- kind is the resolver state. Unknown never qualifies as locked and is never
--- converted to Ready. Ready does not qualify. Active and Replay do.
function M.qualifies_locked_only(kind)
    return kind == don_state.STATE_ACTIVE or kind == don_state.STATE_REPLAY
end

local function row_name_of(row)
    if type(row) == "table" then return tostring(row.name or "") end
    return tostring(row or "")
end

function M.row_qualifies_locked(states, row, now)
    local row_name = row_name_of(row)
    for _, state in ipairs(states or {}) do
        if type(state) == "table" then
            local kind = don_state.resolve(state, row_name, now)
            if M.qualifies_locked_only(kind) then return true end
        end
    end
    return false
end

--- Present one canonical row. Does not mutate state.
function M.present(state, row_name, now, opts)
    opts = type(opts) == "table" and opts or {}
    now = tonumber(now) or os.time()
    if type(state) ~= "table" then
        return {
            kind = don_state.STATE_UNKNOWN,
            text = "?",
            tooltip = "Not synchronized",
        }
    end
    local kind, info = don_state.resolve(state, row_name_of(row_name), now)
    if kind == don_state.STATE_ACTIVE then
        local expires_at = type(info) == "table" and tonumber(info.expires_at) or nil
        local remaining = expires_at and math.max(0, expires_at - now) or nil
        local clock = remaining and M.format_remaining(remaining) or nil
        local text
        if opts.compact == true then
            text = clock or "Active"
        else
            text = clock and ("Active " .. clock) or "Active"
        end
        return {
            kind = kind,
            text = text,
            expires_at = expires_at,
            remaining = remaining,
            tooltip = clock and ("Active mission · " .. clock) or "Active mission",
        }
    end
    if kind == don_state.STATE_REPLAY then
        local expires_at = type(info) == "table" and tonumber(info.expires_at) or nil
        local remaining = type(info) == "table" and tonumber(info.remaining) or nil
        if remaining == nil and expires_at then remaining = math.max(0, expires_at - now) end
        local text = remaining and M.format_remaining(remaining) or "Locked"
        return {
            kind = kind,
            text = text,
            expires_at = expires_at,
            remaining = remaining,
            tooltip = "Replay lockout · " .. text,
        }
    end
    if kind == don_state.STATE_READY then
        return { kind = kind, text = "Open", tooltip = "Ready" }
    end
    local reason = type(info) == "table" and info.reason or nil
    local tooltip = "Not synchronized"
    if reason == "stale-active" then tooltip = "Not synchronized (stale Active)" end
    return { kind = don_state.STATE_UNKNOWN, text = "?", tooltip = tooltip, reason = reason }
end

--- char_states: array of DoNState tables, or false for a missing snapshot.
--- A missing snapshot increments `missing` and contributes no cells. A present
--- snapshot with no/uncaptured DoNState contributes Unknown cells, never Open.
function M.count_kinds(char_states, rows, now)
    local c = { active = 0, replay = 0, ready = 0, unknown = 0, missing = 0 }
    for _, state in ipairs(char_states or {}) do
        if state == false then
            c.missing = c.missing + 1
        else
            for _, row in ipairs(rows or {}) do
                local kind = don_state.resolve(type(state) == "table" and state or nil, row_name_of(row), now)
                if kind == don_state.STATE_ACTIVE then c.active = c.active + 1
                elseif kind == don_state.STATE_REPLAY then c.replay = c.replay + 1
                elseif kind == don_state.STATE_READY then c.ready = c.ready + 1
                else c.unknown = c.unknown + 1 end
            end
        end
    end
    return c
end

return M
