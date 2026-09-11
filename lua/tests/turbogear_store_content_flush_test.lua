-- Run from repo root:  luajit lua/tests/turbogear_store_content_flush_test.lua
-- Verifies live put/delta schedule a coalesced content flush that saves before
-- the normal save_every debounce, and that cache reloads do not schedule it.
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

local CACHE = (os.getenv("TEMP") or os.getenv("TMP") or ".") .. "/tg_store_content_flush_test_cache.lua"
os.remove(CACHE)

local clock = { t = 100.0 }
local function ser(v, out)
    local t = type(v)
    if t == "number" or t == "boolean" then out[#out+1] = tostring(v)
    elseif t == "string" then out[#out+1] = string.format("%q", v)
    elseif t == "table" then
        out[#out+1] = "{"
        for k, val in pairs(v) do
            if type(k) == "number" then out[#out+1] = "[" .. k .. "]="
            else out[#out+1] = "[" .. string.format("%q", tostring(k)) .. "]=" end
            ser(val, out); out[#out+1] = ","
        end
        out[#out+1] = "}"
    else out[#out+1] = "nil" end
end
package.preload['mq'] = function()
    return {
        TLO = { Me = { CleanName = function() return "Me" end },
            MacroQuest = { Server = function() return "Srv" end } },
        pickle = function(path, tbl) local o = {"return "}; ser(tbl, o)
            local f = assert(io.open(path, "w")); f:write(table.concat(o)); f:close() end,
        configDir = (os.getenv("TEMP") or os.getenv("TMP") or "."),
    }
end
package.preload['config'] = function()
    return {
        CFG = {
            save_every_s = 60.0,
            save_every_bg_s = 60.0,
            save_content_coalesce_s = 1.5,
            age_sweep_interval_s = 999,
        },
        Settings = { offlineSeconds = 45, staleSeconds = 20, mainTab = "bis" },
        SharedSettings = { ignoredChars = {} },
        CacheFile = CACHE,
        LegacyCacheFile = (os.getenv("TEMP") or os.getenv("TMP") or ".") .. "/tg_nope.lua",
        SaveSharedSettings = function() end, LoadSharedSettings = function() end,
    }
end
package.preload['state'] = function()
    return {
        bg = true, show = false, lean = function() return false end,
        local_guard_scripts = { main = true, bg = true },
    }
end

-- Patch os.clock after packages load so store.lua's schedule uses our clock.
local real_clock = os.clock
os.clock = function() return clock.t end

local Store = require('store').Store
local diag = require('diagnostics')
diag.set_enabled(true)

local pass, fail = 0, 0
local function check(c, m) if c then pass = pass + 1 else fail = fail + 1; print("  FAIL: " .. tostring(m)) end end
local function cnt(k) return diag.counters[k] or 0 end
local function eqitem(id, name)
    return { id = id, name = name, location = "Equipped", where = "Equipped", slotid = 13, slotname = "Primary" }
end

Store.put({
    name = "Me", server = "Srv", class = "War", level = 70, depth = "lite",
    updated = 1000, inventoryUpdated = 1000,
    equipped = { eqitem(1, "Sword") }, bags = {}, bank = {},
}, "client")
Store.save()
local flush_before = cnt("store.content_flush")

-- Content change while normal debounce is 60s: tick before coalesce must NOT save.
clock.t = 100.5
Store.put({
    name = "Me", server = "Srv", class = "War", level = 70, depth = "lite",
    updated = 1001, inventoryUpdated = 1001,
    equipped = { eqitem(2, "Axe") }, bags = {}, bank = {},
}, "client")
Store.tick()
check(Store.dirty == true, "dirty after content put")
check(cnt("store.content_flush") == flush_before, "no flush before coalesce window")

-- After 1.5s coalesce, tick should content-flush.
clock.t = 102.1
Store.tick()
check(cnt("store.content_flush") == flush_before + 1, "content flush fires after coalesce")
check(Store.dirty == false, "dirty cleared by content flush save")

-- Cache reload path must not schedule a content flush.
flush_before = cnt("store.content_flush")
Store.reload_cache()
clock.t = 110.0
Store.tick()
check(cnt("store.content_flush") == flush_before, "cache reload does not schedule content flush")

os.clock = real_clock
print(string.format("store content flush: %d passed, %d failed", pass, fail))
if fail > 0 then os.exit(1) end
