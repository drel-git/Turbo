-- Run from repo root: luajit lua/tests/turbogear_don_ui_prefs_test.lua
-- DoN tab UI preference persistence. No authority, acquisition, or matrix.
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;lua/tests/helpers/?.lua;' .. package.path
local tmpdir = require('tmpdir')
package.preload['mq'] = function()
    return {
        configDir = tmpdir.dir(),
        pickle = function() end,
        TLO = {
            Me = { CleanName = function() return "PrefTest" end },
            MacroQuest = { Server = function() return "Srv" end },
        },
    }
end
package.preload['ImGui'] = function() return {} end
package.preload['theme'] = function()
    return {
        Theme = {},
        col_text = function() end,
        toggle_button = function() return false end,
        themed_button = function() return false end,
    }
end
package.preload['views'] = function() return {} end
package.preload['characters'] = function() return {} end
package.preload['don_matrix'] = function() return {} end
package.preload['don_track'] = function() return { ui_tab_enter = function() end } end
package.preload['diagnostics'] = function()
    return {
        time = function(_, fn) return fn() end,
        count = function() end,
        event = function() end,
    }
end

local cfg = require('config')
cfg._reset_settings_dirty_for_tests()
local don_ref = require('references.don_lockouts')
local don = require('tabs.don')

local pass, fail = 0, 0
local function check(cond, msg)
    if cond then pass = pass + 1 else fail = fail + 1; print('FAIL: ' .. tostring(msg)) end
end

local pickled = 0
cfg._pickle = function() pickled = pickled + 1 end

local dirty_marks = 0
local orig_mark = cfg.MarkSettingsDirty
cfg.MarkSettingsDirty = function(...)
    dirty_marks = dirty_marks + 1
    return orig_mark(...)
end

local function reset_prefs()
    cfg._reset_settings_dirty_for_tests()
    cfg._pickle = function() pickled = pickled + 1 end
    pickled = 0
    dirty_marks = 0
    cfg.Settings.donCollapsedSections = nil
    cfg.Settings.donLockedOnly = false
    cfg.Settings.donCompact = false
end

reset_prefs()
for _, section in ipairs(don_ref.sections or {}) do
    check(don.section_collapsed(section.id) == false,
        "no collapse settings -> " .. tostring(section.id) .. " expanded")
end
check(don.all_sections_collapsed() == false, "no collapse settings -> not all collapsed")

reset_prefs()
cfg.Settings.donCollapsedSections = { t1_missions = true }
check(don.section_collapsed("t1_missions") == true, "one persisted true -> that section collapsed")
check(don.section_collapsed("raid") == false, "missing sibling stays expanded")

reset_prefs()
cfg.Settings.donCollapsedSections = { raid = false }
check(don.section_collapsed("raid") == false, "persisted false -> expanded")

reset_prefs()
cfg.Settings.donCollapsedSections = { t1_missions = true }
check(don.section_collapsed("future_t4") == false, "new unknown section -> expanded")
check(don.section_collapsed("removed_stale") == false, "stale missing key is ignored / expanded")

reset_prefs()
don.toggle_section("raid")
check(cfg.Settings.donCollapsedSections.raid == true, "single toggle collapses missing key")
check(dirty_marks == 1, "single toggle -> dirty once, got " .. tostring(dirty_marks))
check(pickled == 0, "single toggle does not SaveSettings synchronously")
check(cfg.settings_are_dirty() == true, "single toggle leaves settings dirty")
check(cfg.settings_dirty_reason() == "don_section", "single toggle dirty reason")

reset_prefs()
don.set_all_sections(true)
local all_true = true
for _, section in ipairs(don_ref.sections or {}) do
    if cfg.Settings.donCollapsedSections[section.id] ~= true then
        all_true = false
        check(false, "Collapse All left " .. tostring(section.id) .. " not true")
    end
end
check(all_true == true, "Collapse All -> all true")
check(dirty_marks == 1, "Collapse All -> one dirty mark, got " .. tostring(dirty_marks))
check(pickled == 0, "Collapse All does not SaveSettings synchronously")
check(don.all_sections_collapsed() == true, "Collapse All reports all collapsed")

reset_prefs()
don.set_all_sections(true)
dirty_marks = 0
pickled = 0
don.set_all_sections(false)
local all_false = true
for _, section in ipairs(don_ref.sections or {}) do
    if cfg.Settings.donCollapsedSections[section.id] ~= false then
        all_false = false
        check(false, "Expand All left " .. tostring(section.id) .. " not false")
    end
end
check(all_false == true, "Expand All -> all false")
check(dirty_marks == 1, "Expand All -> one dirty mark, got " .. tostring(dirty_marks))
check(pickled == 0, "Expand All does not SaveSettings synchronously")
check(don.all_sections_collapsed() == false, "Expand All reports not all collapsed")

reset_prefs()
cfg.Settings.donLockedOnly = false
don.toggle_locked_only()
check(cfg.Settings.donLockedOnly == true, "donLockedOnly toggles in memory")
check(dirty_marks == 1, "donLockedOnly toggle -> dirty once")
check(pickled == 0, "donLockedOnly toggle: no synchronous SaveSettings")
check(cfg.settings_dirty_reason() == "don_locked", "donLockedOnly dirty reason")

reset_prefs()
cfg.Settings.donCompact = false
don.toggle_compact()
check(cfg.Settings.donCompact == true, "donCompact toggles in memory")
check(dirty_marks == 1, "donCompact toggle -> dirty once")
check(pickled == 0, "donCompact toggle: no synchronous SaveSettings")
check(cfg.settings_dirty_reason() == "don_compact", "donCompact dirty reason")

cfg._reset_settings_dirty_for_tests()
print(string.format('don_ui_prefs: %d passed, %d failed', pass, fail))
if fail > 0 then os.exit(1) end
