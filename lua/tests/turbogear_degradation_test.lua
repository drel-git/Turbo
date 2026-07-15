-- Run from repo root:  luajit lua/tests/turbogear_degradation_test.lua
-- Confirms the graceful-degradation fallbacks stay working:
--   * missing cache file        -> load returns cleanly, Store stays empty (no crash)
--   * lsqlite3 unavailable       -> store selects the file backend
--   * actors library unavailable -> Engine.init returns false/"no_actors", stays cache-only
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

local MISSING = "/tmp/tg_deg_missing_cache_" .. tostring(os.time()) .. ".lua"
os.remove(MISSING)

package.preload['mq'] = function()
    return { TLO = { Me = { CleanName = function() return "Me" end },
        MacroQuest = { Server = function() return "Srv" end },
        EverQuest = { GameState = function() return "INGAME" end } },
        pickle = function() end, cmd = function() end, configDir = "/tmp", delay = function() end }
end
package.preload['config'] = function()
    return { CFG = { proto = 1, mailbox = "turbogear", request_cooldown_s = 10 },
        Settings = { offlineSeconds = 45, staleSeconds = 20, mainTab = "bis", storeBackend = "auto" },
        SharedSettings = { ignoredChars = {} },
        CacheFile = MISSING, LegacyCacheFile = MISSING .. ".legacy", DbFile = "/tmp/tg_deg.db",
        SaveSharedSettings = function() end, LoadSharedSettings = function() end,
        write_bg_ready = function() end, clear_bg_ready = function() end }
end
package.preload['state'] = function() return { bg = true, show = false, engine_claim_disabled = false, lean = function() return false end } end
package.preload['snapshot'] = function() return { cached = function() return nil end,
    gather = function() return nil end, depth_for_settings = function() return "lite" end,
    lite_signature = function() return "" end, invalidate = function() end, bank_window_open = function() return false end } end
-- actors library unavailable
package.preload['actors'] = function() error("no actors in this MQ build") end

local pass, fail = 0, 0
local function ck(c, m) if c then pass = pass + 1 else fail = fail + 1; print("  FAIL: " .. m) end end

-- 1. missing cache file: file backend load is graceful
local fb = require('store_backend_file').new({ newer = function() return false end, key_fn = function() return "Srv_Me" end })
local ok_load = fb:load()
ck(ok_load == false, "file backend load on missing cache returns false (no crash)")

-- 2 + 3. store selects file backend (no lsqlite3); Store.load on missing cache leaves it empty
local Store = require('store').Store
ck(Store.cache_status().backend == "file", "store falls back to file backend without lsqlite3")
Store.load()
do
    local on, st, off = Store.counts()
    ck(on == 0 and st == 0 and off == 0, "Store.load on missing cache yields an empty, usable store")
    ck(#Store.peer_keys() == 0, "no peers from a missing cache (no crash)")
end

-- 4. actors unavailable: engine stays cache-only
local Engine = require('engine').Engine
local ok_init, why = Engine.init()
ck(ok_init == false, "Engine.init returns false when actors are unavailable")
ck(why == "no_actors", "reason is no_actors")
ck(Engine.ok == false, "Engine.ok stays false (cache-only UI still runs)")

os.remove(MISSING)
print(string.format("degradation: %d passed, %d failed", pass, fail))
os.exit(fail == 0 and 0 or 1)
