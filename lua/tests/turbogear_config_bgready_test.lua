-- Run from repo root:  luajit lua/tests/turbogear_config_bgready_test.lua
-- Loads the REAL config.lua under an mq stub and exercises the R5 bg-ready
-- marker helpers (write / age / clear) against a temp file.
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path
package.preload['mq'] = function()
    return { configDir = "/tmp",
        TLO = { Me = { CleanName = function() return "MarkerTest" end },
            MacroQuest = { Server = function() return "Srv" end } } }
end

local cfg = require('config')
local pass, fail = 0, 0
local function ck(c, m) if c then pass = pass + 1 else fail = fail + 1; print("  FAIL: " .. m) end end

os.remove(cfg.BgReadyFile)
ck(cfg.bg_ready_age() == nil, "no marker -> age nil")
cfg.write_bg_ready()
local age = cfg.bg_ready_age()
ck(type(age) == "number" and age >= 0 and age < 5, "fresh marker -> small age (got " .. tostring(age) .. ")")
cfg.clear_bg_ready()
ck(cfg.bg_ready_age() == nil, "cleared marker -> age nil")
-- a garbage marker body reads as nil (not a crash)
do local f = io.open(cfg.BgReadyFile, "w"); f:write("not-a-number"); f:close() end
ck(cfg.bg_ready_age() == nil, "non-numeric marker body -> age nil")
os.remove(cfg.BgReadyFile)

print(string.format("config bgready: %d passed, %d failed", pass, fail))
os.exit(fail == 0 and 0 or 1)
