-- Run from repo root: luajit lua/tests/turbogear_settings_debounce_test.lua
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;lua/tests/helpers/?.lua;' .. package.path
local tmpdir = require('tmpdir')
package.preload['mq'] = function()
    return {
        configDir = tmpdir.dir(),
        pickle = function() end,
        TLO = {
            Me = { CleanName = function() return "SetTest" end },
            MacroQuest = { Server = function() return "Srv" end },
        },
    }
end

local cfg = require('config')
cfg._reset_settings_dirty_for_tests()

local pass, fail = 0, 0
local function check(cond, msg)
    if cond then pass = pass + 1 else fail = fail + 1; print('FAIL: ' .. tostring(msg)) end
end

local pickled = 0
cfg._pickle = function() pickled = pickled + 1 end
cfg.CFG.ui_settings_save_debounce_s = 0.2

-- Click path: memory updates immediately, pickle does not.
cfg.Settings.mainTab = "gear"
cfg.Settings.mainTab = "don"
cfg.MarkSettingsDirty("main_tab")
check(cfg.Settings.mainTab == "don", "click changes mainTab immediately")
check(cfg.settings_are_dirty() == true, "dirty flag set")
check(cfg.settings_dirty_reason() == "main_tab", "reason recorded")
check(pickled == 0, "SaveSettings not called synchronously from click")

check(cfg.tick_settings_save(os.clock()) == false, "debounce has not elapsed")
check(pickled == 0, "still no pickle during debounce")

-- Rapid switches coalesce to one write of the final value.
cfg.Settings.mainTab = "spells"
cfg.MarkSettingsDirty("main_tab")
cfg.Settings.mainTab = "don"
cfg.MarkSettingsDirty("main_tab")
check(cfg.tick_settings_save(os.clock() + 1.0) == true, "one later save after debounce")
check(pickled == 1, "multiple quick switches -> one persist, got " .. tostring(pickled))
check(cfg.Settings.mainTab == "don", "final tab value is what was saved")
check(cfg.settings_are_dirty() == false, "dirty cleared after save")

cfg.MarkSettingsDirty("main_tab")
check(cfg.flush_settings_save() == true, "shutdown flush writes immediately")
check(pickled == 2, "flush pickles once more")

cfg._reset_settings_dirty_for_tests()
print(string.format('settings_debounce: %d passed, %d failed', pass, fail))
if fail > 0 then os.exit(1) end
