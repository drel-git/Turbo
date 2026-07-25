-- Turbo/hitchlog.lua
-- Lightweight timed capture of Turbo UI frame work (freeze / hitch reports).
-- Usage: /turbo hitchlog [seconds]  or More → Record Hitch Log

local mq = require('mq')

local M = {}

local SLOW_MS = 50
local RING_MAX = 160
local SHOW_MAX = 80

local capture = nil -- { deadline, started_clock, started_wall, seconds, slow={}, n=0, sum=0, max=0, samples={} }

local function now_ms()
    return (os.clock() or 0) * 1000
end

local function sanitize(s)
    s = tostring(s or ''):gsub('[^%w_%-.]+', '_')
    if s == '' then s = 'unknown' end
    return s
end

local function my_key()
    local server, name = '?', '?'
    pcall(function()
        server = tostring(mq.TLO.MacroQuest.Server() or '?')
        name = tostring(mq.TLO.Me.CleanName() or mq.TLO.Me.Name() or '?')
    end)
    return server .. '_' .. name
end

local function out_path()
    local paths = require('Turbo.paths')
    local dir = paths.root()
    if dir then paths.ensure_dir(dir) end
    if not dir or dir == '' then
        dir = tostring(mq.configDir or '.')
    end
    local stamp = os.date('%Y%m%d_%H%M%S')
    return string.format('%s\\Turbo_hitchlog_%s_%s.txt', dir, sanitize(my_key()), stamp)
end

local function push_slow(label, ms)
    if not capture then return end
    local ring = capture.slow
    ring[#ring + 1] = {
        t = os.date('%H:%M:%S'),
        label = tostring(label or '?'),
        ms = ms,
    }
    if #ring > RING_MAX then
        table.remove(ring, 1)
    end
end

local function bump_sample(label, ms)
    local s = capture.samples[label]
    if not s then
        s = { n = 0, sum = 0, max = 0 }
        capture.samples[label] = s
    end
    s.n = s.n + 1
    s.sum = s.sum + ms
    if ms > s.max then s.max = ms end
    if ms >= SLOW_MS then push_slow(label, ms) end
end

function M.capturing()
    return capture ~= nil
end

function M.start(seconds, ctx)
    seconds = tonumber(seconds) or 180
    if seconds < 30 then seconds = 30 end
    if seconds > 600 then seconds = 600 end
    if capture then
        M.finish('restarted')
    end
    capture = {
        deadline = os.clock() + seconds,
        started_clock = os.clock(),
        started_wall = os.date('%Y-%m-%d %H:%M:%S'),
        seconds = seconds,
        slow = {},
        n = 0,
        sum = 0,
        max = 0,
        samples = {},
        ctx = type(ctx) == 'table' and ctx or {},
        frame_t0 = nil,
        span_t0 = nil,
        span_label = nil,
    }
    printf('\at[Turbo]\ax hitchlog recording for \ag%.0fs\ax. Reproduce the freeze; a file will be written automatically.', seconds)
    return true
end

function M.sample(label, ms)
    if not capture then return end
    ms = tonumber(ms) or 0
    if ms < 0 then ms = 0 end
    bump_sample(tostring(label or '?'), ms)
end

function M.span_begin(label)
    if not capture then return nil end
    capture.span_label = tostring(label or '?')
    capture.span_t0 = now_ms()
    return true
end

function M.span_end()
    if not capture or not capture.span_t0 then return end
    local ms = now_ms() - capture.span_t0
    local label = capture.span_label or 'span'
    capture.span_t0 = nil
    capture.span_label = nil
    capture.frame_accounted = (tonumber(capture.frame_accounted) or 0) + ms
    bump_sample(label, ms)
end

function M.on_frame_begin()
    if not capture then return end
    capture.frame_t0 = now_ms()
    capture.frame_accounted = 0
end

function M.on_frame_end(tg)
    if not capture or not capture.frame_t0 then return end
    local ms = now_ms() - capture.frame_t0
    capture.frame_t0 = nil
    capture.n = capture.n + 1
    capture.sum = capture.sum + ms
    if ms > capture.max then capture.max = ms end
    bump_sample('renderWindow', ms)
    -- Time not covered by named spans (prep gaps, GC, MQ stalls mid-callback).
    local accounted = tonumber(capture.frame_accounted) or 0
    local gap = ms - accounted
    if gap < 0 then gap = 0 end
    bump_sample('unaccounted', gap)
    capture.frame_accounted = 0
    if tg and type(tg) == 'table' then
        capture.ctx.windowOpen = tg.windowOpen
        capture.ctx.minimizedGUI = tg.minimizedGUI
        capture.ctx.slimGUI = tg.slimGUI
        capture.ctx.activeTab = tg.activeTab
        if tg.getTurboState then
            local ok, on = pcall(tg.getTurboState)
            if ok then capture.ctx.turboOn = on end
        end
        if tg.TURBO_VERSION then
            capture.ctx.version = tg.TURBO_VERSION
        end
    end
end

local function status_is_running(status)
    local text = tostring(status or ''):lower()
    if text == '' then return false end
    if text:find('not', 1, true) or text:find('stop', 1, true) or text:find('ended', 1, true) then
        return false
    end
    return text:find('running', 1, true) ~= nil or text == 'run'
end

local function script_running(names)
    local lua = mq.TLO.Lua
    for _, name in ipairs(names or {}) do
        local okS, status = pcall(function()
            local script = lua and lua.Script and lua.Script(name)
            return script and script.Status and (script.Status() or '') or ''
        end)
        if okS and status_is_running(status) then return true end
    end
    return false
end

local function build_lines(reason)
    local c = capture
    local lines = {}
    local function add(fmt, ...)
        if select('#', ...) > 0 then
            lines[#lines + 1] = string.format(fmt, ...)
        else
            lines[#lines + 1] = tostring(fmt or '')
        end
    end

    local elapsed = math.max(0, os.clock() - (tonumber(c.started_clock) or os.clock()))
    local ctx = c.ctx or {}
    add('Turbo UI Hitch Log')
    add('Written: %s', os.date('%Y-%m-%d %H:%M:%S'))
    add('Reason: %s', tostring(reason or 'complete'))
    add('Version: %s', tostring(ctx.version or '?'))
    add('Character: %s', my_key())
    add('Capture started: %s', tostring(c.started_wall or ''))
    add('Capture seconds: %.1f (requested %.0f)', elapsed, tonumber(c.seconds) or 0)
    add('')
    add('Window / UI')
    local layout = 'full'
    if ctx.windowOpen == false then
        layout = 'hidden'
    elseif ctx.minimizedGUI then
        layout = 'mini'
    elseif ctx.slimGUI then
        layout = 'slim'
    end
    add('layout=%s windowOpen=%s minimized=%s slim=%s activeTab=%s',
        layout, tostring(ctx.windowOpen), tostring(ctx.minimizedGUI), tostring(ctx.slimGUI), tostring(ctx.activeTab or ''))
    add('turboOn=%s', tostring(ctx.turboOn))
    add('')
    add('Related scripts (this session)')
    add('TurboGains=%s TurboGear=%s TurboMobs=%s',
        tostring(script_running({ 'Turbo/gains', 'gains' })),
        tostring(script_running({ 'turbogear', 'TurboGear', 'turbogear_bg' })),
        tostring(script_running({ 'TurboMobs', 'turbomobs' })))
    add('')
    add('Frame summary (renderWindow)')
    local avg = (c.n > 0) and (c.sum / c.n) or 0
    add('frames=%d avg=%.1fms max=%.1fms slow_threshold=%dms', c.n, avg, c.max, SLOW_MS)
    add('')
    add('Section samples')
    local labels = {}
    for label in pairs(c.samples or {}) do labels[#labels + 1] = label end
    table.sort(labels)
    for _, label in ipairs(labels) do
        local s = c.samples[label]
        local a = (s.n > 0) and (s.sum / s.n) or 0
        add('  %-22s n=%d avg=%.1fms max=%.1fms', label, s.n, a, s.max)
    end
    add('')
    add('Recent slow events (%d shown / %d captured)', math.min(SHOW_MAX, #(c.slow or {})), #(c.slow or {}))
    local slow = c.slow or {}
    local start = math.max(1, #slow - SHOW_MAX + 1)
    for i = start, #slow do
        local e = slow[i]
        add('  %s  %-22s  %.1fms', tostring(e.t), tostring(e.label), tonumber(e.ms) or 0)
    end
    add('')
    add('')
    add('Notes: named sections are sequential prep/draw buckets. unaccounted is')
    add('frame time not covered by those buckets (gaps, GC, or stalls mid-callback).')
    add('How to use: sit with Turbo UI open, reproduce freezes, send this file.')
    return lines
end

function M.finish(reason)
    if not capture then return nil, 'not capturing' end
    local path = out_path()
    local lines = build_lines(reason or 'complete')
    local ok, err = pcall(function()
        local fh = assert(io.open(path, 'w'))
        for _, line in ipairs(lines) do
            fh:write(line, '\n')
        end
        fh:close()
    end)
    capture = nil
    if not ok then
        printf('\at[Turbo]\ax hitchlog write failed: %s', tostring(err))
        return nil, err
    end
    printf('\at[Turbo]\ax hitchlog written: \ag%s\ax', path)
    return path
end

function M.tick()
    if not capture then return end
    if os.clock() >= (tonumber(capture.deadline) or 0) then
        M.finish('timer complete')
    end
end

--- Attach version / turbo state into the next finish() header.
function M.set_context(ctx)
    if not capture then return end
    if type(ctx) ~= 'table' then return end
    for k, v in pairs(ctx) do
        capture.ctx[k] = v
    end
end

return M
