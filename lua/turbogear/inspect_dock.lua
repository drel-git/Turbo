-- TurboGear/inspect_dock.lua
-- Dock native item inspect clear of TurboGear (main loop only).
-- ImGui always paints over EQ windows — find any on-screen spot outside TG bounds.

local mq = require('mq')
local state = require('state')

local M = {}

local DOCK_WINDOW = "ItemDisplayWindow"
local DOCK_GAP = 12
local DOCK_DURATION_S = 2.5
local DEFAULT_W, DEFAULT_H = 410, 462
local LAYOUT_WAIT_S = 0.25
local ATTEMPT_INTERVAL_S = 0.08
local MAX_ATTEMPTS = 24
local EDGE = 4

local dock_until = 0
local dock_started = 0
local attempt_count = 0
local last_attempt_at = 0
local cancelled = false
local anchor_rect = nil

function M.enabled()
    local ok, cfg = pcall(require, 'config')
    if ok and cfg and cfg.Settings then
        return cfg.Settings.inspectDockEnabled ~= false
    end
    return true
end

function M.cancel()
    cancelled = true
    dock_until = 0
    attempt_count = 0
    anchor_rect = nil
end

function M.set_anchor(rect)
    if type(rect) == "table" then
        anchor_rect = rect
    end
end

function M.schedule(_item_name)
    if not M.enabled() then return end
    cancelled = false
    dock_until = os.clock() + DOCK_DURATION_S
    dock_started = os.clock()
    attempt_count = 0
    last_attempt_at = 0
end

function M.active()
    return not cancelled and M.enabled() and state.run and os.clock() <= dock_until
end

local function window_open(wnd)
    if not wnd then return false end
    local ok, open = pcall(function()
        if not wnd() then return false end
        if not wnd.Open then return false end
        return wnd.Open()
    end)
    return ok and open == true
end

local function resolve_window()
    local ok, wnd = pcall(function() return mq.TLO.DisplayItem.Window end)
    if ok and window_open(wnd) then return wnd end
    wnd = mq.TLO.Window(DOCK_WINDOW)
    if window_open(wnd) then return wnd end
    return nil
end

local function safe_num(fn, fallback)
    fallback = tonumber(fallback) or 0
    local ok, val = pcall(fn)
    if not ok then return fallback end
    return tonumber(val) or fallback
end

local function screen_size()
    local sw, sh = 1920, 1080
    pcall(function()
        if mq.TLO.Display and mq.TLO.Display.Width then
            sw = tonumber(mq.TLO.Display.Width()) or sw
        end
        if mq.TLO.Display and mq.TLO.Display.Height then
            sh = tonumber(mq.TLO.Display.Height()) or sh
        end
    end)
    return sw, sh
end

local function rect(x1, y1, x2, y2)
    return { x1 = x1, y1 = y1, x2 = x2, y2 = y2 }
end

local function overlaps(a, b, gap)
    gap = gap or 0
    return not (a.x2 + gap <= b.x1 or b.x2 + gap <= a.x1 or a.y2 + gap <= b.y1 or b.y2 + gap <= a.y1)
end

local function fits_screen(x, y, w, h, sw, sh)
    return x >= EDGE and y >= EDGE and (x + w) <= (sw - EDGE) and (y + h) <= (sh - EDGE)
end

local function clear_of_tg(x, y, w, h, tg)
    return not overlaps(rect(x, y, x + w, y + h), tg, DOCK_GAP)
end

local function find_clear_position(item_w, item_h, tg, sw, sh)
    local g = DOCK_GAP
    local candidates = {
        -- beside TG (preferred)
        { tg.x2 + g, tg.y1 },
        { tg.x1 - item_w - g, tg.y1 },
        { tg.x2 + g, tg.y1 + 48 },
        { tg.x1 - item_w - g, tg.y1 + 48 },
        -- below / above TG
        { tg.x1, tg.y2 + g },
        { tg.x2 - item_w, tg.y2 + g },
        { math.max(EDGE, tg.x1), tg.y1 - item_h - g },
        { math.max(EDGE, tg.x2 - item_w), tg.y1 - item_h - g },
        -- screen edges aligned to TG top
        { EDGE, tg.y1 },
        { sw - item_w - EDGE, tg.y1 },
        { EDGE, tg.y2 + g },
        { sw - item_w - EDGE, tg.y2 + g },
        -- corners (TG huge / centered — still find visible space)
        { EDGE, EDGE },
        { sw - item_w - EDGE, EDGE },
        { EDGE, sh - item_h - EDGE },
        { sw - item_w - EDGE, sh - item_h - EDGE },
    }

    for _, c in ipairs(candidates) do
        local x, y = math.floor(c[1]), math.floor(c[2])
        if fits_screen(x, y, item_w, item_h, sw, sh) and clear_of_tg(x, y, item_w, item_h, tg) then
            return x, y
        end
    end

    -- last resort: scan down the left edge in steps
    for y = EDGE, sh - item_h - EDGE, 40 do
        local x = EDGE
        if fits_screen(x, y, item_w, item_h, sw, sh) and clear_of_tg(x, y, item_w, item_h, tg) then
            return x, y
        end
        x = sw - item_w - EDGE
        if fits_screen(x, y, item_w, item_h, sw, sh) and clear_of_tg(x, y, item_w, item_h, tg) then
            return x, y
        end
    end

    return nil, nil
end

local function tg_rect_from_anchor(anchor)
    local tg = {
        x1 = tonumber(anchor.x1) or 0,
        y1 = tonumber(anchor.y1) or 0,
        x2 = tonumber(anchor.x2) or 0,
        y2 = tonumber(anchor.y2) or 0,
    }
    if tg.x2 <= tg.x1 then return nil end
    if tg.y2 <= tg.y1 then
        tg.y2 = tg.y1 + DEFAULT_H
    end
    return tg
end

local function try_move()
    if not M.active() then return end
    if attempt_count >= MAX_ATTEMPTS then return end
    if (os.clock() - dock_started) < LAYOUT_WAIT_S then return end
    if type(anchor_rect) ~= "table" then return end

    local now = os.clock()
    if (now - last_attempt_at) < ATTEMPT_INTERVAL_S then return end
    last_attempt_at = now

    local wnd = resolve_window()
    if not wnd then
        attempt_count = attempt_count + 1
        return
    end

    local read_w = safe_num(function() return wnd.Width() end, 0)
    local read_h = safe_num(function() return wnd.Height() end, DEFAULT_H)
    local item_w = (read_w >= 200) and read_w or DEFAULT_W
    local item_h = (read_h >= 120) and read_h or DEFAULT_H

    local tg = tg_rect_from_anchor(anchor_rect)
    if not tg then
        attempt_count = attempt_count + 1
        return
    end

    local sw, sh = screen_size()
    local x, y = find_clear_position(item_w, item_h, tg, sw, sh)
    if not x or not y then
        attempt_count = attempt_count + 1
        return
    end

    local cur_x = safe_num(function() return wnd.X() end, -9999)
    local cur_y = safe_num(function() return wnd.Y() end, -9999)
    if clear_of_tg(cur_x, cur_y, item_w, item_h, tg)
        and math.abs(cur_x - x) < 4 and math.abs(cur_y - y) < 4 then
        attempt_count = MAX_ATTEMPTS
        return
    end

    local ok_move = pcall(function()
        if wnd.Move then wnd.Move(x, y) end
    end)
    attempt_count = attempt_count + 1
    if ok_move then
        attempt_count = MAX_ATTEMPTS
    end
end

function M.tick(fallback_rect)
    if type(anchor_rect) ~= "table" and type(fallback_rect) == "table" then
        anchor_rect = fallback_rect
    end
    if not M.active() then return end
    pcall(try_move)
end

return M
