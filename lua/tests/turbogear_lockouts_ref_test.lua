-- Run from repo root: luajit lua/tests/turbogear_lockouts_ref_test.lua
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

local ref = require('references.lockouts')

local pass, fail = 0, 0
local function check(cond, msg)
    if cond then pass = pass + 1 else fail = fail + 1; print('FAIL: ' .. tostring(msg)) end
end

check(table.concat(ref.ui_category_order, ',') == 'Raid,TwoGroupRaid,Group,OldRaids,Custom',
    'visible category order is Raids, 2 Group, 1 Group, Old Raids, Custom')
check(ref.category_label('Raid') == 'Raids', 'Raid visible label')
check(ref.category_label('TwoGroupRaid') == '2 Group', 'TwoGroupRaid visible label')
check(ref.category_label('Group') == '1 Group', 'Group visible label')
check(ref.category_label('OldRaids') == 'Old Raids', 'OldRaids visible label')

local anguish = ref.categories.Raid[1]
check(ref.display_label(anguish) == 'Anguish (Wall of Slaughter)', 'Anguish zone suffix')
local crest = ref.categories.Raid[2]
check(ref.display_label(crest) == 'Crest (Qeynos Hills (BB))', 'Crest zone suffix')
local fippy = ref.categories.Raid[4]
check(ref.display_label(fippy) == 'Fippy (HC Qeynos Hills (pond))', 'Fippy zone suffix')
local fuku = ref.categories.Raid[5]
check(ref.display_label(fuku) == 'FUKU (Unrest)', 'FUKU zone suffix')
local veksar = ref.categories.Raid[7]
check(ref.display_label(veksar) == 'Veksar (Lake of Ill Omen)', 'Veksar zone suffix')
local crimson = ref.categories.TwoGroupRaid[6]
check(ref.display_label(crimson) == 'The Crimson Curse (Chardok)', 'Crimson zone suffix')
local old = ref.categories.OldRaids[1]
check(ref.display_label(old) == 'Plane of Time (Plane of Time)', 'Old Raids included in UI order')

print(string.format('lockouts ref: %d passed, %d failed', pass, fail))
if fail > 0 then os.exit(1) end
