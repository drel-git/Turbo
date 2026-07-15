-- Run from repo root:  luajit lua/tests/turbogear_announcer_budget_test.lua
-- Verifies P5: announcer.tick enforces a single per-frame work budget that the
-- needs-index build draws down from, and skips the build when the budget is
-- exhausted. Deps are stubbed; needs_index.tick captures the budget it receives.
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

local CFG = {
    frame_work_budget_ms = 2,          -- deliberately < the 4ms needs-index budget
    frame_work_budget_lean_ms = 6,
    frame_work_budget_bg_ms = 40,
    needs_index_budget_ms = 4,
    needs_index_enabled = true,
    announce_pending_budget_ms = 4,
    announce_pending_items_per_tick = 1,
    announce_catalog_budget_ms = 5,
    announce_catalog_steps_ui = 1,
}
package.preload['config'] = function()
    return { CFG = CFG, Settings = {}, SharedSettings = { bisAnnounceEnabled = true },
        LoadSharedSettings = function() end, bis_announce_command = function() return "/g" end }
end
package.preload['state'] = function() return { bg = false, lean = function() return false end } end

local captured
package.preload['needs_index'] = function()
    return {
        char_count = function() return 0 end, ready = function() return false end,
        needers_for = function() return {} end, text_needs = function() return {} end,
        needs_tick = function() return true end,             -- force index_needed
        tick = function(budget) captured = budget end,       -- capture drawn-down budget
        status = function() return {} end,
    }
end
package.preload['bis_catalog'] = function()
    return {
        announce_catalog_ready = function() return true end, -- ready -> catalog warm skipped
        ensure_announce_catalog = function() end,
        tick_announce_catalog = function() end,
        direct_build_progress = function() return nil end,
        announce_list_specs = function() return {} end,
        catalog_build_state = function() return {} end,
    }
end
package.preload['snapshot'] = function()
    return { cached = function() return { name = "Tester", class = "WAR" } end,
        lite_age = function() return 0 end, gather = function() return { name = "Tester", class = "WAR" } end }
end
package.preload['item_actions'] = function() return {
    looks_like_item_link = function() return false end, remember_item_link = function() end,
    resolve_announce_link = function() return "" end, observed_link_count = function() return 0 end } end
package.preload['diagnostics'] = function() return {
    time = function(_, fn) return fn() end, count = function() end, event = function() end,
    sample = function() end, is_enabled = function() return false end } end
package.preload['store'] = function() return { Store = {
    peer_keys = function() return {} end, get = function() return nil end,
    is_recently_visible = function() return false end } } end
package.preload['mq'] = function() return {
    LinkTypes = { Item = "item" },
    TLO = { Me = { CleanName = function() return "Tester" end },
        MacroQuest = { Server = function() return "Srv" end },
        EverQuest = { GameState = function() return "INGAME" end },
        Zone = { ShortName = function() return "z" end } },
    ExtractLinks = function() return {} end, ParseItemLink = function() return nil end,
    cmd = function() end, cmdf = function() end } end

local A = require('announcer')
A.set_passive(false)

local pass, fail = 0, 0
local function check(c, m) if c then pass = pass + 1 else fail = fail + 1; print("  FAIL: " .. tostring(m)) end end

-- frame budget (2ms) is below the needs-index default (4ms): the budget passed
-- to needs_index.tick must be clamped down to the frame budget.
captured = nil
A.tick()
check(type(captured) == "number", "needs_index.tick was called")
check(captured and captured > 0 and captured <= 2.5, "budget clamped to ~frame budget (got " .. tostring(captured) .. ")")
check(captured and captured < 4, "budget drawn down below the unclamped 4ms")

-- with the frame budget exhausted, the index build is skipped this tick
CFG.frame_work_budget_ms = 0
captured = "SKIP"
A.tick()
check(captured == "SKIP", "needs_index build skipped when frame budget exhausted")

print(string.format("announcer frame budget (P5): %d passed, %d failed", pass, fail))
os.exit(fail == 0 and 0 or 1)
