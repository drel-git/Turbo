-- Run from repo root:  luajit lua/tests/turbogear_config_bgready_test.lua
-- Loads the REAL config.lua under an mq stub and exercises the R5 bg-ready
-- marker helpers (write / age / clear) against a temp file.
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;lua/tests/helpers/?.lua;' .. package.path
local tmpdir = require('tmpdir')
local lua_turbo_value = 500
local last_cmd = nil
package.preload['mq'] = function()
    return { configDir = tmpdir.dir(),
        cmd = function(s) last_cmd = s end,
        TLO = { Me = { CleanName = function() return "MarkerTest" end },
            Lua = { Turbo = function() return lua_turbo_value end },
            MacroQuest = { Server = function() return "Srv" end } } }
end

local cfg = require('config')
local pass, fail = 0, 0
local function ck(c, m) if c then pass = pass + 1 else fail = fail + 1; print("  FAIL: " .. m) end end

do
    lua_turbo_value = 500
    local st = cfg.lua_turbo_status()
    ck(st.known == true and st.warning == true and st.value == 500 and st.recommended == 1000,
        "Lua Turbo below recommendation warns")
    lua_turbo_value = 1000
    st = cfg.lua_turbo_status()
    ck(st.known == true and st.ok == true and st.warning == false and st.value == 1000,
        "Lua Turbo at recommendation is OK")
    last_cmd = nil
    local applied = cfg.set_recommended_lua_turbo()
    ck(applied == 1000 and last_cmd == "/lua conf turboNum 1000",
        "Lua Turbo setter sends /lua conf turboNum 1000")
end

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

-- patch lock detection
os.remove(cfg.PatchLockFile)
ck(cfg.patch_lock_present() == false, "no patch lock -> false")
do local f = io.open(cfg.PatchLockFile, "w"); f:write("patching"); f:close() end
ck(cfg.patch_lock_present() == true, "patch lock present -> true")
os.remove(cfg.PatchLockFile)
ck(cfg.patch_lock_present() == false, "removed patch lock -> false")

print(string.format("config bgready: %d passed, %d failed", pass, fail))
os.exit(fail == 0 and 0 or 1)
