-- Run from repo root:  luajit lua/tests/turbogear_store_sqlite_integration_test.lua
-- End-to-end: with lsqlite3 present (FFI shim), store.lua selects the SQLite
-- backend and persists/reloads through it. Also checks cross-connection reload.
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;lua/tests/helpers/?.lua;' .. package.path
package.preload['lsqlite3'] = function() return require('lsqlite3_ffi_shim') end

local DB = "/tmp/tg_store_sqlite_integration.db"
for _, p in ipairs({DB, DB.."-wal", DB.."-shm"}) do os.remove(p) end

package.preload['mq'] = function()
    return { TLO = { Me = { CleanName = function() return "Me" end },
        MacroQuest = { Server = function() return "Srv" end } }, configDir = "/tmp" }
end
package.preload['config'] = function()
    return { CFG = {}, Settings = { offlineSeconds = 45, staleSeconds = 20, mainTab = "bis", storeBackend = "auto" },
        SharedSettings = { ignoredChars = {} }, DbFile = DB, CacheFile = "/tmp/tg_nonexistent_pickle.lua",
        LegacyCacheFile = "/tmp/tg_nonexistent_legacy.lua", SaveSharedSettings = function() end, LoadSharedSettings = function() end }
end
package.preload['state'] = function() return { bg = false, show = true, lean = function() return false end } end

local Store = require('store').Store
local sqlmod = require('store_backend_sqlite')
local pass, fail = 0, 0
local function ck(c, m) if c then pass = pass + 1 else fail = fail + 1; print("  FAIL: " .. m) end end
local function eqitem(id, name) return { id = id, name = name, location = "Equipped", where = "Equipped", slotid = 13, slotname = "Primary" } end
local function put(name, id) Store.put({ name = name, server = "Srv", class = "War", level = 70, depth = "full",
    updated = 1000, inventoryUpdated = 1000, equipped = { eqitem(id, name .. "Blade") }, bags = {}, bank = {} }, "client") end

-- store selected the sqlite backend
ck(Store.cache_status().backend == "sqlite", "store selected sqlite backend (got " .. tostring(Store.cache_status().backend) .. ")")

-- put + save persists through the backend to the DB
put("Me", 1); put("Alice", 101)
Store.save()
do
    local _, loaded = sqlmod.new({}):load()
    ck(loaded.Srv_Alice and loaded.Srv_Alice.equipped[1].id == 101, "put+save persisted Alice to the DB")
    ck(loaded.Srv_Me ~= nil, "own entry persisted too")
end

-- another connection writes a new peer -> reload_cache_if_changed picks it up
local other = sqlmod.new({})
other:save({ Srv_Zeek = { name = "Zeek", server = "Srv", class = "Clr", level = 60, updated = 2000,
    inventoryUpdated = 2000, equipped = { eqitem(303, "ZeekRod") }, bags = {}, bank = {} } })
local changed = Store.reload_cache_if_changed(false)
ck(changed ~= false, "reload_cache_if_changed detects the external write")
ck(Store.get("Srv_Zeek") ~= nil, "externally-written peer now visible in Store")

for _, p in ipairs({DB, DB.."-wal", DB.."-shm"}) do os.remove(p) end
print(string.format("store<->sqlite integration: %d passed, %d failed", pass, fail))
os.exit(fail == 0 and 0 or 1)
