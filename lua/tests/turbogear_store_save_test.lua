-- Run from repo root:  luajit lua/tests/turbogear_store_save_test.lua
-- Verifies P1-interim: Store.save skips the disk read-merge when this process is
-- the sole writer (on-disk signature unchanged since our last write) and DOES
-- merge when the file changed externally (another box wrote), preserving that
-- box's entries. Uses a real (tiny) pickle serializer + real /tmp file I/O; the
-- store.save_merge / store.save_merge_skipped diag counters are the probe.
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

local CACHE = "/tmp/tg_store_save_test_cache.lua"
os.remove(CACHE)

-- minimal serializer: writes a loadable `return {...}` file (stand-in for mq.pickle)
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
        configDir = "/tmp",
    }
end
package.preload['config'] = function()
    return { CFG = {}, Settings = { offlineSeconds = 45, staleSeconds = 20, mainTab = "bis" },
        SharedSettings = { ignoredChars = {} }, CacheFile = CACHE, LegacyCacheFile = "/tmp/tg_nope.lua",
        SaveSharedSettings = function() end, LoadSharedSettings = function() end }
end
package.preload['state'] = function() return { bg = false, show = true, lean = function() return false end } end

local Store = require('store').Store
local diag = require('diagnostics')
diag.set_enabled(true)

local pass, fail = 0, 0
local function check(c, m) if c then pass = pass + 1 else fail = fail + 1; print("  FAIL: " .. tostring(m)) end end
local function cnt(k) return diag.counters[k] or 0 end
local function eqitem(id, name) return { id = id, name = name, location = "Equipped", where = "Equipped", slotid = 13, slotname = "Primary" } end
local function put(name, id, updated)
    Store.put({ name = name, server = "Srv", class = "War", level = 70, depth = "full",
        updated = updated, inventoryUpdated = updated, equipped = { eqitem(id, name .. "Blade") }, bags = {}, bank = {} }, "client")
end

put("Me", 1, 1000)
put("Alice", 101, 1000)

-- save #1: first write (cache_signature starts nil -> merge path runs)
Store.save()
do
    local ok, t = pcall(dofile, CACHE)
    check(ok and type(t) == "table", "save wrote a loadable cache file")
    check(t and t.Srv_Alice ~= nil, "cache contains the peer entry")
    check(Store.cache_signature ~= nil, "cache_signature recorded after save")
end

-- save #2: sole writer, nothing changed on disk -> read-merge SKIPPED
local merge_before, skip_before = cnt("store.save_merge"), cnt("store.save_merge_skipped")
Store.dirty = true
Store.save()
check(cnt("store.save_merge_skipped") == skip_before + 1, "sole-writer save skips the read-merge")
check(cnt("store.save_merge") == merge_before, "sole-writer save does NOT run the read-merge")

-- external writer: rewrite the file with an extra peer (Zeek) at higher recency,
-- changing its size -> signature differs -> next save MUST merge and preserve Zeek
do
    local f = assert(io.open(CACHE, "w"))
    f:write('return { Srv_Zeek = { name="Zeek", server="Srv", class="Clr", level=60,'
        .. ' updated=9000, inventoryUpdated=9000, equipped={ { id=555, name="ZeekRing",'
        .. ' location="Equipped", where="Equipped", slotid=1, slotname="Ear" } }, bags={}, bank={} } }')
    f:close()
end
local merge_before2 = cnt("store.save_merge")
Store.dirty = true
Store.save()
check(cnt("store.save_merge") == merge_before2 + 1, "external change triggers the read-merge")
do
    local ok, t = pcall(dofile, CACHE)
    check(ok and t and t.Srv_Zeek ~= nil, "external peer (Zeek) preserved by the merge")
    check(t and t.Srv_Alice ~= nil and t.Srv_Me ~= nil, "our own entries still written")
end

os.remove(CACHE)
print(string.format("store save (P1 interim): %d passed, %d failed", pass, fail))
os.exit(fail == 0 and 0 or 1)
