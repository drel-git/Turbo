-- Run from repo root: luajit lua/tests/turbogear_don_shadow_finals_test.lua
-- Finished DoN Shadow combines must count as owning Shadow + Materium1-3.
package.path = "lua/turbogear/?.lua;lua/turbogear/?/init.lua;" .. package.path

package.preload["mq"] = function()
    return {
        TLO = {
            Me = { CleanName = function() return "Me" end },
            MacroQuest = { Server = function() return "Srv" end },
        },
        configDir = "/tmp",
    }
end
package.preload["config"] = function()
    return {
        Settings = {},
        SharedSettings = {},
        CFG = {},
        SaveSettings = function() end,
        SaveSharedSettings = function() end,
    }
end

local catalog = require("bis_catalog")

local pass, fail = 0, 0
local function check(cond, msg)
    if cond then
        pass = pass + 1
    else
        fail = fail + 1
        print("  FAIL: " .. tostring(msg))
    end
end

local function has_id(entry, id)
    id = tonumber(id) or 0
    for _, v in ipairs((entry and entry.ids) or {}) do
        if tonumber(v) == id then return true end
    end
    return false
end

local function has_name(entry, name)
    name = tostring(name or "")
    for _, v in ipairs((entry and entry.names) or {}) do
        if tostring(v) == name then return true end
    end
    return false
end

-- Shadow row carries component + finished combine.
local shd = catalog.resolve_entry("don", "Shadow Knight", "Shadow")
check(has_id(shd, 60544) and has_id(shd, 55077), "SHD Shadow has component + Merciless Bulwark ids")
check(has_name(shd, "Merciless Bulwark of the Ice Dragon"), "SHD Shadow has final name")

local ber = catalog.resolve_entry("don", "Berserker", "Shadow")
check(has_id(ber, 60667) and has_id(ber, 56497), "BER Shadow has component + Igniss ids")

local rng = catalog.resolve_entry("don", "Ranger", "Shadow")
check(has_id(rng, 56753) and has_id(rng, 66907), "RNG Shadow accepts Buckler or Bolt")

-- Materium chain expands Shadow aliases onto Materium rows.
local mat = catalog.resolve_entry("don", "Bard", "Materium1")
check(has_id(mat, 62535), "BRD Materium1 keeps Materium id")
check(has_id(mat, 56498) and has_name(mat, "Broodslayer, the Dauntless Blade"),
    "BRD Materium1 expands finished Broodslayer from Shadow chain")

local mat_shd = catalog.resolve_entry("don", "Shadow Knight", "Materium2")
check(has_id(mat_shd, 55077), "SHD Materium2 greens via finished Bulwark id")

print(string.format("don_shadow_finals: %d passed, %d failed", pass, fail))
os.exit(fail == 0 and 0 or 1)
