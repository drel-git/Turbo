-- Pure viewport column-width rules (mirrors tabs/bis.lua viewport_char_col_w).
-- Run: luajit lua\tests\turbogear_bis_roster_col_w_test.lua

local function viewport_char_col_w(num_keys, slot_w, layout_cfg, layout, avail, full_names)
    local fit_target, few_max_w = 6, 360.0
    num_keys = math.max(1, tonumber(num_keys) or 1)
    slot_w = tonumber(slot_w) or 120.0
    layout_cfg = layout_cfg or {}
    avail = tonumber(avail) or 800.0
    if layout == "ultra" then
        return tonumber(layout_cfg.col_w) or tonumber(layout_cfg.min_col_w) or 44.0
    end

    local floor_w = tonumber(layout_cfg.min_col_w) or 88.0
    local many_cap = tonumber(layout_cfg.max_col_w) or 196.0
    local compact_short = layout == "compact" and not full_names
    if compact_short then
        floor_w = tonumber(layout_cfg.fit_w) or floor_w
        many_cap = math.max(many_cap, 120.0)
    end
    local readable = floor_w
    if compact_short then
        readable = math.max(72.0, floor_w - 8.0)
    elseif layout == "normal" or full_names then
        readable = math.max(110.0, math.min(floor_w, 140.0))
    end

    local budget = math.max(120.0, avail - slot_w - 28.0)
    local target = math.min(num_keys, fit_target)
    while target > 1 and (budget / target) < readable do
        target = target - 1
    end

    local col_w
    if num_keys <= fit_target then
        col_w = budget / num_keys
        local few_cap = math.max(many_cap, math.min(few_max_w, budget / num_keys))
        col_w = math.min(col_w, few_cap)
    else
        col_w = math.min(budget / target, many_cap)
    end
    return math.max(floor_w, col_w)
end

local passed, failed = 0, 0
local function check(cond, label)
    if cond then passed = passed + 1
    else failed = failed + 1; io.stderr:write('FAIL: ', tostring(label), '\n') end
end

local compact = { min_col_w = 84, max_col_w = 92, fit_w = 88 }
local full = { min_col_w = 140, max_col_w = 220 }
local ultra = { col_w = 44, min_col_w = 44, max_col_w = 44 }

-- 2 chars on a wide window: large equal columns (fill budget)
local w2 = viewport_char_col_w(2, 110, compact, "compact", 900, false)
check(w2 > 200 and w2 < 400, 'few: 2 cols grow on wide window')

-- 3 chars larger than 9-char width
local w3 = viewport_char_col_w(3, 110, compact, "compact", 900, false)
local w9 = viewport_char_col_w(9, 110, compact, "compact", 900, false)
check(w3 > w9, 'few cols wider than many-col equal width')
check(w9 * 6 <= (900 - 110 - 28) + 2, 'many: about 6 fit in budget')

-- ultra stays narrow
check(viewport_char_col_w(2, 72, ultra, "ultra", 900, false) == 44, 'ultra: stays glyph width with few')
check(viewport_char_col_w(9, 72, ultra, "ultra", 900, false) == 44, 'ultra: stays glyph width with many')

-- narrow window reduces visible target (column still >= floor)
local wn = viewport_char_col_w(9, 110, compact, "compact", 420, false)
check(wn >= 72, 'narrow: at least readability floor')

-- full names few grow
local wf = viewport_char_col_w(2, 124, full, "compact", 900, true)
check(wf > 220, 'full-name few: can exceed many_cap to fill')

io.write(string.format('bis_roster_col_w: %d passed, %d failed\n', passed, failed))
os.exit(failed == 0 and 0 or 1)
