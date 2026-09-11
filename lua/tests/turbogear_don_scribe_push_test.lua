-- After a scribe publishes a changed spell set, the bg box pushes a fresh
-- "don" bis_search answer (debounced, coalesced, never over a real request).
-- Run from repo root: luajit lua/tests/turbogear_don_scribe_push_test.lua
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

package.preload['actors'] = function() error("no actors in test") end
package.preload['mq'] = function()
    return {
        TLO = {
            Me = { CleanName = function() return "Me" end },
            MacroQuest = { Server = function() return "Srv" end },
            EverQuest = { GameState = function() return "INGAME" end },
            Zone = { ShortName = function() return "z" end, Name = function() return "Zone" end },
        },
        cmd = function() end, pickle = function() end, configDir = "/tmp", delay = function() end,
        event = function() end, unevent = function() end,
    }
end
package.preload['config'] = function()
    return {
        CFG = { proto = 1, mailbox = "turbogear", request_cooldown_s = 10, publish_every_s = 12,
            publish_every_bg_s = 30, publish_every_lean_s = 60, publish_every_minimized_s = 30,
            keepalive_publish_s = 45, publish_jitter_s = 0, delta_publish_enabled = true },
        Settings = { offlineSeconds = 45, staleSeconds = 20, mainTab = "bis", autoPeerRefresh = false },
        SharedSettings = { ignoredChars = {}, announceUseActor = true },
        CacheFile = "/tmp/turbogear_push_test_cache.lua",
        LegacyCacheFile = "/tmp/turbogear_push_test_legacy.lua",
        SaveSharedSettings = function() end, LoadSharedSettings = function() end,
    }
end
local STATE = { bg = false, show = true, engine_claim_disabled = true, lean = function() return false end }
package.preload['state'] = function() return STATE end
package.preload['snapshot'] = function()
    return { gather = function() return { name = "Me", server = "Srv", class = "Shaman", equipped = {}, bags = {}, bank = {} } end,
        depth_for_settings = function() return "lite" end, lite_signature = function() return "SIG" end,
        cached = function() return nil end, invalidate = function() end, bank_window_open = function() return false end }
end
-- bis_search stub records searches.
local searches = {}
package.preload['bis_search'] = function()
    return {
        search_local = function(list_id)
            searches[#searches + 1] = list_id
            return { name = "Me", server = "Srv", class = "Shaman", list_id = list_id, updated = 1, slots = {} }
        end,
        apply_result = function() return true end,
        save = function() return true end,
    }
end
local invalidations = 0
package.preload['don_spells'] = function()
    return { invalidate_live = function() invalidations = invalidations + 1 end }
end

local pass, fail = 0, 0
local function check(cond, m) if cond then pass = pass + 1 else fail = fail + 1; print("FAIL: " .. tostring(m)) end end

local Engine = require('engine').Engine
check(type(Engine.queue_bis_push) == "function", "engine exposes queue_bis_push")

-- Fake clock for the debounce.
local now = 1000.0
local real_clock = os.clock
os.clock = function() return now end -- luacheck: ignore

-- 1. queued push waits for its not_before
Engine.pending_bis_search = nil
check(Engine.queue_bis_push("don", 2.0) == true, "push queued")
check(Engine.apply_pending_bis_search() == false and #searches == 0, "push does not run before the debounce")
now = now + 1.0
check(Engine.queue_bis_push("don", 2.0) == true, "second scribe coalesces into the same push")
now = now + 1.5 -- 2.5s after the first, 1.5s after the second
check(Engine.apply_pending_bis_search() == false and #searches == 0, "debounce restarts on each scribe (coalesced)")
now = now + 1.0
check(Engine.apply_pending_bis_search() == true and #searches == 1 and searches[1] == "don", "one push after the last scribe")
check(Engine.pending_bis_search == nil, "push consumed")

-- 2. a real peer request is never delayed or replaced by a push
Engine.enqueue_bis_search({ list_id = "anguish" })
check(Engine.queue_bis_push("don", 2.0) == false, "push does not replace a pending real request")
check(Engine.pending_bis_search.list_id == "anguish" and Engine.pending_bis_search.not_before == nil, "real request still immediate")
check(Engine.apply_pending_bis_search() == true and searches[#searches] == "anguish", "real request answered")

-- 3. a real request arriving over a queued push answers immediately
Engine.queue_bis_push("don", 2.0)
Engine.enqueue_bis_search({ list_id = "don" })
check(Engine.apply_pending_bis_search() == true and searches[#searches] == "don", "request replaces queued push and answers now")

-- 4. inventory_watch hook: memo always dropped; push only from the bg process
local iw = require('inventory_watch')
check(type(iw._after_spell_publish) == "function", "inventory_watch exposes the hook")
Engine.pending_bis_search = nil
STATE.bg = false
check(iw._after_spell_publish("test") == false and Engine.pending_bis_search == nil, "UI process does not push")
check(invalidations == 1, "UI process still drops its live DoN memo")
STATE.bg = true
check(iw._after_spell_publish("test") == true and Engine.pending_bis_search
    and Engine.pending_bis_search.list_id == "don" and Engine.pending_bis_search.push == true, "bg process queues a don push")
check(invalidations == 2, "bg process drops its live DoN memo too")

os.clock = real_clock -- luacheck: ignore
print(string.format("don scribe push: %d passed, %d failed", pass, fail))
if fail > 0 then os.exit(1) end
