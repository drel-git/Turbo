-- Run from repo root:  luajit lua/tests/turbogear_bis_catalog_lazy_test.lua
-- Verifies P2: the generated catalog (catalogs.lazbis) is NOT require()'d when
-- bis_catalog loads, only on first field access through the proxy, and exactly
-- once thereafter. bis/mq/config are stubbed; catalogs.lazbis is a counting stub.
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

local loads = 0
package.preload['catalogs.lazbis'] = function()
    loads = loads + 1
    return {
        groups = { { name = "G1", lists = { { id = "l1", name = "L1" } } } },
        lists = { l1 = { name = "L1" } },
        default = { group = "G1", index = 1 },
    }
end
package.preload['mq'] = function()
    return { TLO = { Me = { CleanName = function() return "Me" end },
        MacroQuest = { Server = function() return "Srv" end } }, configDir = "/tmp" }
end
package.preload['config'] = function()
    return { Settings = {}, SharedSettings = {}, CFG = {},
        SaveSettings = function() end, SaveSharedSettings = function() end }
end

local pass, fail = 0, 0
local function check(c, m) if c then pass = pass + 1 else fail = fail + 1; print("  FAIL: " .. tostring(m)) end end

local bc = require('bis_catalog')
check(loads == 0, "catalog NOT loaded at require time (lazy) - got " .. tostring(loads))
check(bc.catalog_loaded() == false, "catalog_loaded() is false before first use")

-- first field access through the exported proxy materializes the real table
local g = bc.catalog.groups
check(loads == 1, "catalog loaded exactly once on first field access")
check(bc.catalog_loaded() == true, "catalog_loaded() true after access")
check(type(g) == "table" and g[1] and g[1].name == "G1", "proxy forwards field reads")

-- subsequent access does not reload
local _ = bc.catalog.lists
check(loads == 1, "no reload on subsequent access")

-- warm_catalog is idempotent once loaded
bc.warm_catalog()
check(loads == 1, "warm_catalog after load does not reload")

print(string.format("bis_catalog lazy: %d passed, %d failed", pass, fail))
os.exit(fail == 0 and 0 or 1)
