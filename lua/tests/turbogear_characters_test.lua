-- Run from repo root:  luajit lua/tests/turbogear_characters_test.lua
-- Pure helpers + BiS adapter apply_scope / view_key_for_new_scope (ImGui stubbed).
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

package.preload['mq'] = function()
    return {
        TLO = {
            Me = { CleanName = function() return "Tester" end },
            MacroQuest = { Server = function() return "Srv" end },
            Group = nil,
        },
    }
end

local Settings = {
    bisRosterScope = "online",
    bisViewKey = "__all__",
    bisViewSelectedChars = {},
    spellsRosterScope = "online",
    spellsViewKey = "__all__",
    spellsViewSelectedChars = {},
    lockoutsRosterScope = "online",
    lockoutsViewKey = "__all__",
    lockoutsViewSelectedChars = {},
    liveStatsRosterScope = "online",
    liveStatsViewKey = "__self__",
    suggestSourceScope = "all",
    suggestTargetKey = "__self__",
    inventoryRosterScope = "online",
    inventoryViewKey = "__self__",
    inventoryScope = "single",
    augsRosterScope = "online",
    augsViewKey = "__self__",
    augsViewMode = "single",
    storedRosterScope = "online",
    storedViewKey = "__self__",
    storedViewMode = "single",
    statsSourceKey = "__self__",
    statsSearchScope = "all",
    statsSearchViewKey = "__all__",
    statsSearchSelectedChars = {},
    focusSourceKey = "__self__",
    focusSourceScope = "all",
    emptyViewKey = "__self__",
    emptyViewMode = "single",
    compareKey1 = "__self__",
    showCharactersPill = true,
    syncRosterScopeAcrossTabs = false,
}
local SharedSettings = { characterSets = {} }
local saved = 0

package.preload['config'] = function()
    return {
        Settings = Settings,
        SharedSettings = SharedSettings,
        SaveSettings = function() saved = saved + 1 end,
        SaveSharedSettings = function() end,
        apply_linked_roster_scope = function() return false end,
    }
end

package.preload['store'] = function()
    return {
        Store = {
            peer_keys = function() return { "Srv_Alpha", "Srv_Beta" } end,
            get = function(key)
                if key == "Srv_Alpha" then
                    return { name = "Alpha", status = "online" }
                end
                if key == "Srv_Beta" then
                    return { name = "Beta", status = "stale" }
                end
                return nil
            end,
            is_recently_visible = function() return true end,
        },
        my_key = function() return "Srv_Tester" end,
    }
end

package.preload['ImGui'] = function()
    return {}
end

package.preload['theme'] = function()
    return {
        Theme = { blue = {}, steel = {}, purple = {}, dim = {}, header = {}, item = {} },
        col_text = function() end,
        themed_button = function() return false end,
    }
end

package.preload['views'] = function()
    return {
        validate_source_key = function(key) return key end,
        source_owner_name = function(key)
            if key == "__self__" then return "Tester" end
            if key == "Srv_Alpha" then return "Alpha" end
            if key == "Srv_Beta" then return "Beta" end
            return tostring(key)
        end,
        source_snapshot = function(key)
            if key == "__self__" then
                return { name = "Tester", class = "Shadow Knight", status = "live" }
            end
            if key == "Srv_Alpha" then
                return { name = "Alpha", class = "Wizard", status = "online" }
            end
            return nil
        end,
        source_label = function(key) return tostring(key) end,
        class_abbrev = function(class_name)
            if tostring(class_name) == "Shadow Knight" then return "SHD" end
            if tostring(class_name) == "Wizard" then return "WIZ" end
            return ""
        end,
    }
end

local C = require('characters')
local roster_sets = require('roster_sets')

local passed, failed = 0, 0
local function check(cond, label)
    if cond then
        passed = passed + 1
    else
        failed = failed + 1
        io.stderr:write('FAIL: ', tostring(label), '\n')
    end
end

-- format_pill_label
check(C.format_pill_label("Live Peers", 3, 3) == "Characters: Live Peers - 3 of 3",
    'pill label: shown of total')
check(C.format_pill_label("Live Peers", 1, 3) == "Characters: Live Peers - 1 of 3",
    'pill label: subset')
check(C.format_pill_label("Group", 0, 0) == "Characters: Group",
    'pill label: empty pool omits counts')
check(C.format_pill_label("", 2, 2) == "Characters: Characters - 2 of 2",
    'pill label: empty scope falls back')

-- view_key_for_new_scope / normalize_scope
check(C.view_key_for_new_scope("self") == "__self__", 'view key: self -> __self__')
check(C.view_key_for_new_scope("online") == "__all__", 'view key: online -> __all__')
check(C.view_key_for_new_scope("group") == "__all__", 'view key: group -> __all__')
check(C.normalize_scope("e3") == "online", 'normalize: e3 migrates to online')
check(C.normalize_scope("all") == "all", 'normalize: all unchanged')

-- apply_scope dual-drives Settings
Settings.bisRosterScope = "online"
Settings.bisViewKey = "__all__"
saved = 0
C.apply_scope("bis", "self")
check(Settings.bisRosterScope == "self", 'apply_scope: sets bisRosterScope')
check(Settings.bisViewKey == "__self__", 'apply_scope: self resets view to __self__')
check(saved >= 1, 'apply_scope: SaveSettings called')

C.apply_scope("bis", "group")
check(Settings.bisRosterScope == "group", 'apply_scope: group scope')
check(Settings.bisViewKey == "__all__", 'apply_scope: non-self resets view to __all__')

C.apply_scope("bis", "e3")
check(Settings.bisRosterScope == "online", 'apply_scope: e3 normalized to online')

-- spells / lockouts adapters
Settings.spellsRosterScope = "online"
Settings.spellsViewKey = "__all__"
Settings.spellsViewSelectedChars = {}
C.apply_scope("spells", "group")
check(Settings.spellsRosterScope == "group", 'apply_scope spells: group')
check(Settings.spellsViewKey == "__all__", 'apply_scope spells: view reset')

Settings.lockoutsRosterScope = "online"
Settings.lockoutsViewKey = "__all__"
Settings.lockoutsViewSelectedChars = {}
C.apply_scope("lockouts", "all")
check(Settings.lockoutsRosterScope == "all", 'apply_scope lockouts: all')

-- active_keys respects selected chars via roster_sets
Settings.bisRosterScope = "all"
Settings.bisViewKey = roster_sets.VIEW_SELECTED
Settings.bisViewSelectedChars = { alpha = "Alpha" }
local keys = C.active_keys("bis")
local has_alpha, has_beta, has_self = false, false, false
for _, k in ipairs(keys) do
    if k == "Srv_Alpha" then has_alpha = true end
    if k == "Srv_Beta" then has_beta = true end
    if k == "__self__" then has_self = true end
end
check(has_alpha == true, 'active_keys: selected includes Alpha')
check(has_beta == false, 'active_keys: selected excludes Beta')
check(has_self == false, 'active_keys: selected excludes self when not listed')

Settings.spellsRosterScope = "all"
Settings.spellsViewKey = roster_sets.VIEW_SELECTED
Settings.spellsViewSelectedChars = { beta = "Beta" }
local spell_keys = C.active_keys("spells")
local spell_has_beta, spell_has_alpha = false, false
for _, k in ipairs(spell_keys) do
    if k == "Srv_Beta" then spell_has_beta = true end
    if k == "Srv_Alpha" then spell_has_alpha = true end
end
check(spell_has_beta == true, 'active_keys spells: selected Beta')
check(spell_has_alpha == false, 'active_keys spells: excludes Alpha')

Settings.bisViewKey = "__all__"
Settings.bisViewSelectedChars = {}
local all_keys = C.active_keys("bis")
check(#all_keys >= 2, 'active_keys: __all__ returns pool')

-- pill_label uses scope display + counts
Settings.bisRosterScope = "online"
Settings.bisViewKey = "__all__"
local label = C.pill_label("bis")
check(type(label) == "string" and label:find("Characters:", 1, true) ~= nil, 'pill_label: prefix')
check(label:find("Live Peers", 1, true) ~= nil, 'pill_label: scope name')

-- primary mode: Suggestions only
check(C.is_primary("suggestions") == true, 'is_primary: suggestions')
check(C.is_primary("bis") == false, 'is_primary: bis is roster')
check(C.is_picker("effects") == true, 'is_picker: effects')
check(C.is_primary("inventory") == true, 'is_primary: inventory')
check(C.is_picker("inventory") == false, 'is_picker: inventory false')

Settings.liveStatsViewKey = "__self__"
saved = 0
C.apply_scope("effects", "group")
check(Settings.liveStatsViewKey == "__self__", 'apply_scope effects picker: ignored')
check(saved == 0, 'apply_scope effects picker: no save')

C.set_primary("effects", "Srv_Alpha")
check(Settings.liveStatsViewKey == "Srv_Alpha", 'set_primary effects: Alpha')
check(C.get_primary("effects") == "Srv_Alpha", 'get_primary effects')

local effects_active = C.active_keys("effects")
check(#effects_active == 1 and effects_active[1] == "Srv_Alpha", 'active_keys effects: single')

local effects_label = C.pill_label("effects")
check(effects_label:find("Character:", 1, true) ~= nil, 'pill_label effects: picker prefix')
check(effects_label:find("Alpha", 1, true) ~= nil, 'pill_label effects: character name')
check(C.format_picker_pill_label("Drel (SHD) [live]") == "Character: Drel (SHD) [live]",
    'format_picker_pill_label')
check(C.format_list_pill_label("Drel") == "List: Drel", 'format_list_pill_label')

Settings.suggestSourceScope = "all"
Settings.suggestTargetKey = "__self__"
C.apply_scope("suggestions", "online")
check(Settings.suggestSourceScope == "online", 'apply_scope suggestions: online')
C.set_primary("suggestions", "Srv_Alpha")
check(Settings.suggestTargetKey == "Srv_Alpha", 'set_primary suggestions')
check(C.format_primary_pill_label("Live Peers", "Drel (SHD) [live]")
    == "Characters: Live Peers - Drel (SHD) [live]", 'format_primary_pill_label')

-- inventory is primary: Source drives Slot Across; Character drives inventory
Settings.inventoryScope = "group"
Settings.inventoryRosterScope = "all"
Settings.augsViewMode = "group"
Settings.storedViewMode = "e3"
C.set_primary("inventory", "Srv_Alpha")
check(Settings.inventoryViewKey == "Srv_Alpha", 'set_primary inventory')
check(Settings.inventoryScope == "single", 'set_primary inventory: forces single')
C.apply_scope("inventory", "online")
check(Settings.inventoryRosterScope == "online", 'apply_scope inventory: online')
local inv_label = C.pill_label("inventory")
check(inv_label:find("Characters:", 1, true) ~= nil, 'pill_label inventory: primary prefix')
C.set_primary("worn", "Srv_Alpha")
check(Settings.augsViewKey == "Srv_Alpha", 'set_primary worn')
check(Settings.augsViewMode == "single", 'set_primary worn: forces single')
C.set_primary("stored", "__self__")
check(Settings.storedViewKey == "__self__", 'set_primary stored')
check(Settings.storedViewMode == "single", 'set_primary stored: forces single')

check(C.is_picker("stats_character") == true, 'is_picker: stats_character')
check(C.is_list("stats_plan") == true, 'is_list: stats_plan')
check(C.is_roster("stats_search") == true, 'is_roster: stats_search')
check(C.is_picker("focus") == true, 'is_picker: focus')
check(C.is_picker("empty") == true, 'is_picker: empty')
check(C.is_picker("compare") == true, 'is_picker: compare')
Settings.statsLoadoutList = "list_a"
check(C.get_list("stats_plan") == "list_a", 'get_list stats_plan')
C.set_list("stats_plan", "list_b")
check(Settings.statsLoadoutList == "list_b", 'set_list stats_plan')
check(C.pill_label("stats_plan"):find("List:", 1, true) ~= nil, 'pill_label stats_plan')
C.set_primary("focus", "Srv_Alpha")
check(Settings.focusSourceKey == "Srv_Alpha", 'set_primary focus')
check(Settings.focusSourceScope == "character", 'set_primary focus: forces character scope')

print(string.format("characters: %d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
