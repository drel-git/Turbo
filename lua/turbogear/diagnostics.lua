-- TurboGear/diagnostics.lua
-- Lightweight in-memory counters/timings. Debug mode records metrics only; it
-- does not print from hot paths.

local M = {
    enabled = false,
    counters = {},
    timings = {},
    slow_threshold_ms = 50,
    slow_events = {},
    events = {},
    contexts = {},
    errors = {},        -- key -> { count, last, last_at }; ALWAYS recorded (see note_error)
}
local unpack = unpack or table.unpack
local SLOW_MAX = 160
local EVENT_MAX = 220

local function now()
    return os.clock()
end

local function wall_time()
    return os.date("%H:%M:%S")
end

local function push_ring(list, max_count, entry)
    list[#list + 1] = entry
    while #list > max_count do table.remove(list, 1) end
end

function M.set_enabled(value)
    M.enabled = value and true or false
end

function M.is_enabled()
    return M.enabled == true
end

function M.set_slow_threshold(ms)
    M.slow_threshold_ms = tonumber(ms) or M.slow_threshold_ms or 50
end

function M.toggle()
    M.enabled = not M.enabled
    return M.enabled
end

function M.context(key, detail)
    if not M.enabled then return end
    key = tostring(key or "")
    if key == "" then return end
    M.contexts[key] = tostring(detail or "")
end

function M.event(key, detail)
    if not M.enabled then return end
    key = tostring(key or "")
    if key == "" then return end
    push_ring(M.events, EVENT_MAX, {
        at = wall_time(),
        key = key,
        detail = tostring(detail or ""),
    })
end

function M.count(key, amount)
    if not M.enabled then return end
    key = tostring(key or "")
    if key == "" then return end
    M.counters[key] = (M.counters[key] or 0) + (tonumber(amount) or 1)
end

function M.sample(key, ms)
    if not M.enabled then return end
    key = tostring(key or "")
    if key == "" then return end
    ms = tonumber(ms) or 0
    local t = M.timings[key]
    if not t then
        t = { count = 0, total = 0, max = 0, last = 0 }
        M.timings[key] = t
    end
    t.count = t.count + 1
    t.total = t.total + ms
    t.last = ms
    if ms > t.max then t.max = ms end
    if ms >= (tonumber(M.slow_threshold_ms) or 50) then
        push_ring(M.slow_events, SLOW_MAX, {
            at = wall_time(),
            key = key,
            ms = ms,
            context = M.contexts[key] or "",
        })
    end
end

function M.time(key, fn)
    if not M.enabled then return fn() end
    local t0 = now()
    local out = { pcall(fn) }
    M.sample(key, (now() - t0) * 1000)
    if not out[1] then error(out[2]) end
    table.remove(out, 1)
    return unpack(out)
end

-- Record a swallowed error. UNLIKE counters/events, this is always recorded
-- (even when debug is OFF): a dropped actor send or file write is rare and
-- important, and field diagnosis should not require the user to have had debug
-- enabled beforehand. Perfdiag surfaces these via M.error_lines().
function M.note_error(key, err)
    key = tostring(key or "?")
    if key == "" then key = "?" end
    local rec = M.errors[key]
    if not rec then
        rec = { count = 0, last = "", last_at = 0 }
        M.errors[key] = rec
    end
    rec.count = rec.count + 1
    rec.last = tostring(err or "")
    rec.last_at = os.time()
    if M.enabled then
        push_ring(M.events, EVENT_MAX, { at = wall_time(), key = "error." .. key, detail = rec.last })
    end
end

-- pcall a function, recording (never raising) any failure under `key`. Returns
-- fn's own return values on success, or nil on failure. Drop-in for the many
-- `pcall(function() ... end)` sites that previously discarded the error, so a
-- failure becomes visible in perfdiag instead of looking like a no-op.
function M.protect(key, fn, ...)
    if type(fn) ~= "function" then return nil end
    local res = { pcall(fn, ...) }
    if res[1] then
        return unpack(res, 2)
    end
    M.note_error(key, res[2])
    return nil
end

local function sorted_keys(t)
    local out = {}
    for k in pairs(t or {}) do out[#out + 1] = k end
    table.sort(out)
    return out
end

local function matches_filter(key, filter)
    filter = tostring(filter or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if filter == "" or filter == "all" then return true end
    return tostring(key or ""):lower():find(filter, 1, true) ~= nil
end

function M.lines(filter)
    local lines = {}
    filter = tostring(filter or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    lines[#lines + 1] = string.format("[TurboGear] diagnostics: %s%s",
        M.enabled and "ON" or "OFF",
        filter ~= "" and (" | filter=" .. filter) or "")
    for _, key in ipairs(sorted_keys(M.counters)) do
        if matches_filter(key, filter) then
            lines[#lines + 1] = string.format("  count %-28s %d", key, M.counters[key] or 0)
        end
    end
    for _, key in ipairs(sorted_keys(M.timings)) do
        if matches_filter(key, filter) then
            local t = M.timings[key]
            local avg = (t and t.count and t.count > 0) and ((t.total or 0) / t.count) or 0
            lines[#lines + 1] = string.format("  time  %-28s last %.1fms avg %.1fms max %.1fms n=%d",
                key, t.last or 0, avg, t.max or 0, t.count or 0)
        end
    end
    return lines
end

function M.error_lines(filter)
    filter = tostring(filter or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    local lines = {}
    local total = 0
    for _ in pairs(M.errors) do total = total + 1 end
    lines[#lines + 1] = string.format("[TurboGear] swallowed errors: %d distinct key(s)%s",
        total, filter ~= "" and (" | filter=" .. filter) or "")
    for _, key in ipairs(sorted_keys(M.errors)) do
        if matches_filter(key, filter) then
            local rec = M.errors[key]
            lines[#lines + 1] = string.format("  err   %-28s n=%d last=%s | %s",
                key, rec.count or 0,
                (rec.last_at and rec.last_at > 0) and os.date("%H:%M:%S", rec.last_at) or "?",
                tostring(rec.last or ""):sub(1, 120))
        end
    end
    return lines
end

function M.print(filter)
    for _, line in ipairs(M.lines(filter)) do print(line) end
end

function M.recent_slow_lines(limit)
    limit = tonumber(limit) or SLOW_MAX
    local lines = {}
    local first = math.max(1, #M.slow_events - limit + 1)
    lines[#lines + 1] = string.format("[TurboGear] recent slow events: %d shown / %d captured",
        math.max(0, #M.slow_events - first + 1), #M.slow_events)
    for i = first, #M.slow_events do
        local e = M.slow_events[i]
        lines[#lines + 1] = string.format("  %s %-28s %.1fms%s",
            tostring(e.at or "?"), tostring(e.key or "?"), tonumber(e.ms) or 0,
            tostring(e.context or "") ~= "" and (" | " .. tostring(e.context)) or "")
    end
    return lines
end

function M.recent_event_lines(limit)
    limit = tonumber(limit) or EVENT_MAX
    local lines = {}
    local first = math.max(1, #M.events - limit + 1)
    lines[#lines + 1] = string.format("[TurboGear] recent diagnostic events: %d shown / %d captured",
        math.max(0, #M.events - first + 1), #M.events)
    for i = first, #M.events do
        local e = M.events[i]
        lines[#lines + 1] = string.format("  %s %-28s %s",
            tostring(e.at or "?"), tostring(e.key or "?"), tostring(e.detail or ""))
    end
    return lines
end

function M.reset()
    M.counters = {}
    M.timings = {}
    M.slow_events = {}
    M.events = {}
    M.contexts = {}
end

return M
