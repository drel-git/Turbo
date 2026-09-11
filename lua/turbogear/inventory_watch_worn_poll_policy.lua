-- TurboGear/inventory_watch_worn_poll_policy.lua
-- Pure interval policy for the worn-slot correctness backstop poll.

local M = {}

local function num(v, default)
    v = tonumber(v)
    if v == nil then return default end
    return v
end

function M.base_interval(cfg)
    local interval = num(cfg and cfg.perf_equip_poll_interval_s, 1.0)
    return interval
end

function M.bg_idle_interval(cfg)
    -- 0 = disabled. Sitting bg-only boxes must not walk worn slots on a timer.
    return num(cfg and cfg.perf_equip_poll_bg_idle_interval_s, 0)
end

function M.bg_fast_interval(cfg)
    local interval = num(cfg and cfg.perf_equip_poll_bg_fast_interval_s, M.base_interval(cfg))
    if interval <= 0 then interval = M.base_interval(cfg) end
    return interval
end

function M.fast_window_s(cfg)
    local seconds = num(cfg and cfg.perf_equip_poll_bg_fast_window_s, 15.0)
    if seconds < 0 then seconds = 0 end
    return seconds
end

function M.activate_until(now, cfg)
    return (tonumber(now) or 0) + M.fast_window_s(cfg)
end

function M.fast_active(now, fast_until)
    return (tonumber(fast_until) or 0) > (tonumber(now) or 0)
end

function M.interval(now, cfg, opts)
    opts = opts or {}
    local base = M.base_interval(cfg)
    if base <= 0 then return base, "disabled" end
    if opts.bg ~= true then return base, "ui" end
    if M.fast_active(now, opts.fast_until) then return M.bg_fast_interval(cfg), "fast" end
    local idle = M.bg_idle_interval(cfg)
    if idle <= 0 then return 0, "disabled" end
    return idle, "idle"
end

return M
