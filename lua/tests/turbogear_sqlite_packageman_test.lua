-- Run from repo root:  luajit lua/tests/turbogear_sqlite_packageman_test.lua
-- Verifies the SQLite backend loads lsqlite3 through mq/PackageMan.Require (the
-- auto-install path, plug-and-play like LazBis) when PackageMan is available,
-- and still works via a plain require when it is not.
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;lua/tests/helpers/?.lua;' .. package.path

local DB = "/tmp/tg_pm_test.db"
for _, p in ipairs({DB, DB.."-wal", DB.."-shm"}) do os.remove(p) end

local pm_calls = {}
package.preload['mq/PackageMan'] = function()
    return { Require = function(name) pm_calls[#pm_calls + 1] = name; return require(name) end }
end
package.preload['lsqlite3'] = function() return require('lsqlite3_ffi_shim') end
package.preload['config'] = function()
    return { CFG = {}, Settings = {}, SharedSettings = {}, DbFile = DB, CacheFile = "/tmp/tg_pm_nopickle.lua" }
end
require('diagnostics')

local pass, fail = 0, 0
local function ck(c, m) if c then pass = pass + 1 else fail = fail + 1; print("  FAIL: " .. m) end end

local B = require('store_backend_sqlite').new({})
ck(B:available(), "backend available (lsqlite3 loaded)")
ck(#pm_calls == 1 and pm_calls[1] == "lsqlite3", "lsqlite3 loaded via PackageMan.Require (auto-install path)")

-- it actually works end to end through that path
ck(B:save({ Srv_A = { name = "A", server = "Srv", class = "War", level = 70, updated = 1,
    equipped = {}, bags = {}, bank = {} } }), "save works through the PackageMan-loaded module")
local _, loaded = require('store_backend_sqlite').new({}):load()
ck(loaded.Srv_A ~= nil, "round-trip works")

for _, p in ipairs({DB, DB.."-wal", DB.."-shm"}) do os.remove(p) end
print(string.format("sqlite packageman: %d passed, %d failed", pass, fail))
os.exit(fail == 0 and 0 or 1)
