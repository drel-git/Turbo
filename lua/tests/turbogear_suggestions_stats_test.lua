package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

package.preload['mq'] = function()
    return {
        TLO = {
            Me = {
                CleanName = function() return 'Tester' end,
                Name = function() return 'Tester' end,
            },
            MacroQuest = { Server = function() return 'Srv' end },
            EverQuest = { GameState = function() return 'INGAME' end },
            Window = function()
                return { Open = function() return false end }
            end,
        },
        configDir = '/tmp',
        luaDir = 'lua',
        gettime = function() return 0 end,
        cmd = function() end,
        delay = function() end,
    }
end

package.loaded.item_index = { rows = {}, get = function() return {}, 0 end }

local mock_snap = nil
local mock_equipped = {}

package.loaded.views = {
    clean_name = function(v) return tostring(v or ''):lower() end,
    class_abbrev = function(v) return tostring(v or '') end,
    source_snapshot = function() return mock_snap end,
    index_equipped = function() return mock_equipped end,
    source_owner_name = function() return '' end,
    scoped_source_keys = function() return {} end,
}

local suggestions = require('suggestions')

local passed, failed = 0, 0

local function check(cond, label)
    if cond then
        passed = passed + 1
    else
        failed = failed + 1
        io.stderr:write('FAIL: ', tostring(label), '\n')
    end
end

local chailak = {
    name = 'Chailak Hide Mask',
    stats = { ac = 68 },
    baseStats = { ac = 40 },
    statsMerged = true,
    augs = {
        { empty = false, stats = { ac = 28 } },
    },
}

local faceguard = {
    name = 'Faceguard of Frenzy',
    stats = { ac = 52 },
    baseStats = { ac = 52 },
    statsMerged = true,
    augs = {},
}

check(suggestions.stat_value(chailak, 'ac') == 68, 'effective AC includes installed aug')
check(suggestions.stat_value(chailak, 'ac', { mode = 'base' }) == 40, 'base AC excludes installed aug')
check(suggestions.aug_stat_bonus(chailak, 'ac') == 28, 'aug bonus is separated')
check(suggestions.upgrade_delta(chailak, faceguard, 'ac') == 16, 'default delta remains effective')
check(suggestions.upgrade_delta(chailak, faceguard, 'ac', { mode = 'base' }) == -12, 'replacement delta uses base stats')
check(suggestions.upgrade_delta(chailak, nil, 'ac') == 68, 'empty slot fill delta uses candidate stat')
check(suggestions.is_upgrade(chailak, nil, 'ac') == true, 'empty slot treats any candidate as upgrade/fill')
check(suggestions.can_class_use({ name = 'Bow', classes = {}, slots = { 11 } }, 'Berserker') == true,
    'missing class list allowed for Suggestions')
check(suggestions.can_class_use({ name = 'Plate', classes = { 'Warrior' }, slots = { 17 } }, 'Berserker') == false,
    'explicit wrong class still excluded')
check(suggestions.is_usable_in_slot({
    name = 'Bow', classes = {}, slots = { 11 }, itemType = 'weapon',
}, 11, 'Berserker') == true, 'ranged slot matches wear slots meta')
check(suggestions.is_equipment_row({
    name = 'Ruby of Determined Assault', augType = 3, slots = { 11 },
}) == false, 'augType items excluded from gear candidates')
check(suggestions.is_usable_in_slot({
    name = 'Crude Bow', classes = {}, slots = {}, itemType = 'weapon',
}, 11, 'Berserker') == true, 'bow name infers ranged when slots meta missing')
check(suggestions.is_usable_in_slot({
    name = 'Sword of Testing', classes = {}, slots = {}, itemType = 'weapon',
}, 11, 'Berserker') == false, 'generic weapon does not infer ranged')
check(suggestions.is_junk_weapon_fill({ name = "Rubrae's Infinite Orb of Buffing" }) == true,
    'buff orb is junk MH fill')
check(suggestions.is_weaponish_row({
    name = 'Ragebringer', itemType = 'weapon', stats = { damage = 20 },
}) == true, 'epic with damage is weaponish')
check(suggestions.is_weaponish_row({
    name = "Rubrae's Infinite Orb of Buffing", itemType = 'unknown', stats = { ac = 0 },
}) == false, 'buff orb without damage is not weaponish')

-- Worn totals: depth=full snap with lite worn must be unavailable (not AC: 0).
mock_snap = { depth = 'full', name = 'Tester' }
mock_equipped = {
    [1] = {
        name = 'Crescent-Emblazoned Jerkin',
        depth = 'lite',
        stats = { ac = 0 },
        baseStats = { ac = 0 },
    },
}
do
    local totals, ok = suggestions.worn_stat_totals('peer', { 'ac' })
    check(ok == false and totals == nil, 'lite worn under full snap => totals unavailable')
end

-- Legacy poison: no depth stamp, all-zero stats under depth=full snap.
mock_equipped = {
    [1] = {
        name = 'Tunat Chainmail',
        stats = { ac = 0, hp = 0 },
        baseStats = { ac = 0, hp = 0 },
    },
}
do
    local totals, ok = suggestions.worn_stat_totals('peer', { 'ac' })
    check(ok == false and totals == nil, 'zero-stat worn without depth => unavailable')
end

-- Full worn rows with real AC: available (0 AC jewelry alone must not poison).
mock_equipped = {
    [1] = {
        name = 'Armor Piece',
        depth = 'full',
        stats = { ac = 45 },
        baseStats = { ac = 45 },
        statsMerged = true,
    },
    [2] = {
        name = 'Stat Ear',
        depth = 'full',
        stats = { ac = 0, hp = 50 },
        baseStats = { ac = 0, hp = 50 },
        statsMerged = true,
    },
}
do
    local totals, ok = suggestions.worn_stat_totals('peer', { 'ac', 'hp' })
    check(ok == true and totals and totals.ac == 45 and totals.hp == 50,
        'full worn totals sum AC+HP; 0-AC jewelry ok')
end

if failed > 0 then
    io.stderr:write(string.format('turbogear_suggestions_stats_test: %d passed, %d failed\n', passed, failed))
    os.exit(1)
end

print(string.format('turbogear_suggestions_stats_test: %d passed, %d failed', passed, failed))
