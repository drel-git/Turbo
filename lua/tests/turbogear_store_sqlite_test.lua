-- Run from repo root:  luajit lua/tests/turbogear_store_sqlite_test.lua
-- Exercises the SQLite store backend against a REAL SQLite database. In this
-- offline harness lsqlite3 is the FFI shim (helpers/lsqlite3_ffi_shim.lua); in
-- production it's the real rock. Covers availability, save/load round-trip with
-- nested item lists, change-detected upserts, stale deletion, cross-connection
-- change detection (data_version), and one-time pickle import.
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;lua/tests/helpers/?.lua;' .. package.path
package.preload['lsqlite3'] = function() return require('lsqlite3_ffi_shim') end

local DB   = "/tmp/tg_sqlite_backend_test.db"
local PICK = "/tmp/tg_sqlite_backend_test_pickle.lua"
local function wipe() for _, p in ipairs({DB, DB.."-wal", DB.."-shm", PICK}) do os.remove(p) end end
wipe()

package.preload['config'] = function()
    return { CFG = {}, Settings = {}, SharedSettings = {}, DbFile = DB, CacheFile = PICK }
end
local diag = require('diagnostics'); diag.set_enabled(true)
local sqlmod = require('store_backend_sqlite')

local pass, fail = 0, 0
local function ck(c, m) if c then pass = pass + 1 else fail = fail + 1; print("  FAIL: " .. m) end end
local function cnt(k) return diag.counters[k] or 0 end
local function newB() return sqlmod.new({ recency = function() return 0 end, key_fn = function() return "Srv_Me" end }) end

local function snap(name, id, lvl, augid)
    return { name = name, server = "Srv", class = "War", level = lvl, depth = "full",
        updated = 1000, inventoryUpdated = 1000,
        equipped = { { id = id, name = name .. "Blade", location = "Equipped", where = "Equipped",
            slotid = 13, slotname = "Primary",
            augs = { { index = 1, id = augid or 0, name = augid and "Aug" or nil } } } },
        bags = {}, bank = {} }
end

-- 1. availability
local B = newB()
ck(B:available(), "backend available with lsqlite3 (shim)")
ck(B.kind == "sqlite", "kind is sqlite")

-- 2. save + cross-connection load round-trip (nested payload fidelity)
local out = { Srv_Alice = snap("Alice", 101, 70, 501), Srv_Bob = snap("Bob", 202, 65) }
local ok = B:save(out); ck(ok, "save returns ok")
local B2 = newB()
local ok2, loaded = B2:load()
ck(ok2 and type(loaded) == "table", "load returns table")
ck(loaded.Srv_Alice and loaded.Srv_Alice.name == "Alice", "Alice round-tripped")
ck(loaded.Srv_Alice.equipped[1].id == 101, "nested equipped id preserved")
ck(loaded.Srv_Alice.equipped[1].augs[1].id == 501, "nested aug id preserved")
ck(loaded.Srv_Bob and loaded.Srv_Bob.level == 65, "Bob level preserved")

-- 3. change-detected upserts: unchanged save writes nothing; one change writes one row
local w0 = cnt("store.sqlite_rows_written")
B:save(out)
ck(cnt("store.sqlite_rows_written") == w0, "unchanged save writes 0 rows")
out.Srv_Bob.level = 66
B:save(out)
ck(cnt("store.sqlite_rows_written") == w0 + 1, "one changed row writes exactly 1")

-- 4. stale deletion: dropping a key deletes its row
local d0 = cnt("store.sqlite_rows_deleted")
out.Srv_Alice = nil
B:save(out)
ck(cnt("store.sqlite_rows_deleted") == d0 + 1, "removed key deletes 1 row")
local _, after = newB():load()
ck(after.Srv_Alice == nil and after.Srv_Bob ~= nil, "deleted row gone, others remain")

-- 5. cross-connection change detection via data_version (drives UI reload)
local rdr = newB()
local sig1 = rdr:signature()
local wtr = newB()
wtr:save({ Srv_Zeek = snap("Zeek", 303, 60) })
local sig2 = rdr:signature()
ck(sig1 ~= sig2, "signature changes after another connection commits")

-- 6. one-time pickle import on a fresh DB
wipe()
do
    local f = assert(io.open(PICK, "w"))
    f:write('return { Srv_Old = { name="Old", server="Srv", class="Clr", level=50, updated=900,'
        .. ' equipped={ { id=777, name="OldRod", location="Equipped", where="Equipped", slotid=13, slotname="Primary" } }, bags={}, bank={} } }')
    f:close()
end
local imp = newB()
ck((imp.imported or 0) == 1, "imported 1 row from legacy pickle on fresh DB")
local _, impLoaded = imp:load()
ck(impLoaded.Srv_Old and impLoaded.Srv_Old.equipped[1].id == 777, "imported row is queryable with payload intact")
-- a second open does NOT re-import (DB now non-empty)
local imp2 = newB()
ck((imp2.imported or 0) == 0, "no re-import when DB already has rows")

wipe()
print(string.format("store sqlite backend: %d passed, %d failed", pass, fail))
os.exit(fail == 0 and 0 or 1)
