-- Run from repo root:  luajit lua/tests/turbogear_announcer_budget_test.lua
-- 1.2.131+: announce tick is BiS-thin. needs_index runs only when announce
-- queues are idle, at its own small budget (never Search/Stats enrichment).
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

local CFG = {
    needs_index_budget_ms = 4,
    needs_index_budget_lean_ms = 2,
    needs_index_enabled = true,
    announce_pending_budget_ms = 4,
    announce_pending_items_per_tick = 1,
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
        needs_tick = function() return true end,
        tick = function(budget) captured = budget end,
        status = function() return {} end,
        oldest_queue_age_s = function() return 0 end,
    }
end
package.preload['bis_catalog'] = function()
    return {
        catalog_loaded = function() return true end,
        warm_catalog = function() return true end,
        announce_catalog_ready = function() return true end,
        ensure_announce_catalog = function() end,
        tick_announce_catalog = function() end,
        direct_catalog_if_ready = function() return { by_name = {} } end,
        direct_catalog_prefetch = function() return { by_name = {} } end,
        direct_build_progress = function() return nil end,
        announce_list_specs = function() return {} end,
        catalog_build_state = function() return {} end,
        clean_link_item_name = function(n) return n end,
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
package.preload['inventory_watch'] = function()
    return { inventory_settling = function() return false end }
end
package.preload['engine'] = function()
    return { Engine = { debug = false, request_loot_replay = function() end } }
end
package.preload['item_index'] = function()
    return { tick = function() end, get = function() return {}, 0 end }
end
package.preload['roster_sets'] = function()
    return {
        active_store_keys = function() return {} end,
        scope_label = function() return "online" end,
    }
end
package.preload['mq'] = function() return {
    LinkTypes = { Item = "item" },
    TLO = { Me = { CleanName = function() return "Tester" end },
        MacroQuest = { Server = function() return "Srv" end },
        EverQuest = { GameState = function() return "INGAME" end },
        Zone = { ShortName = function() return "z" end } },
    ExtractLinks = function() return {} end, ParseItemLink = function() return nil end,
    cmd = function() end, cmdf = function() end, delay = function() end } end

local A = require('announcer')
A.set_passive(false)

local pass, fail = 0, 0
local function check(c, m) if c then pass = pass + 1 else fail = fail + 1; print("  FAIL: " .. tostring(m)) end end

-- Idle announce queues: needs_index enrichment gets its configured budget.
captured = nil
A.tick()
check(type(captured) == "number", "needs_index.tick was called when idle")
check(captured == 4, "idle needs_index budget is needs_index_budget_ms (got " .. tostring(captured) .. ")")

-- Disable enrichment: announce tick must still run without calling needs_index.
CFG.needs_index_enabled = false
captured = "SKIP"
A.tick()
check(captured == "SKIP", "needs_index skipped when disabled")

print(string.format("announcer thin tick (1.2.137): %d passed, %d failed", pass, fail))
os.exit(fail == 0 and 0 or 1)
