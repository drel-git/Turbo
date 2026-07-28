-- Run from repo root: luajit lua/tests/turbogear_worn_refresh_test.lua
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

local snapshot = require('snapshot')

local passed, failed = 0, 0
local function check(cond, label)
    if cond then
        passed = passed + 1
    else
        failed = failed + 1
        io.stderr:write('FAIL: ', tostring(label), '\n')
    end
end

-- item_has_populated_stats: AC==0 alone is not enough; depth signal is separate.
check(snapshot.item_has_populated_stats({
    depth = "full",
    stats = { ac = 0, hp = 0 },
    baseStats = { ac = 0, hp = 0 },
}) == false, 'zero stats not populated')

check(snapshot.item_has_populated_stats({
    depth = "full",
    stats = { ac = 0, hp = 100 },
    baseStats = { ac = 0, hp = 100 },
}) == true, 'HP>0 counts as populated even with AC 0')

check(snapshot.item_has_populated_stats({
    depth = "full",
    stats = { ac = 0 },
    baseStats = { ac = 0 },
    classes = { "WAR" },
}) == true, 'class meta counts as populated')

-- worn_entry_needs_rebuild: reuse full same-id; rebuild lite or swapped.
local prev_full = { id = 10, depth = "full", stats = { ac = 45 } }
local prev_lite = { id = 10, depth = "lite", stats = { ac = 0 } }

check(snapshot.worn_entry_needs_rebuild(prev_full, 10, "full") == false,
    'reuse unchanged full row with stats')
check(snapshot.worn_entry_needs_rebuild(prev_lite, 10, "full") == true,
    'rebuild lite row when wanting full')
check(snapshot.worn_entry_needs_rebuild(prev_full, 11, "full") == true,
    'rebuild on item id swap')
check(snapshot.worn_entry_needs_rebuild(prev_lite, 10, "lite") == false,
    'lite want reuses same-id lite row')
check(snapshot.worn_entry_needs_rebuild({
    id = 10, depth = "full", stats = { ac = 0 }, baseStats = { ac = 0 },
}, 10, "full") == true, 'rebuild false-full zero-stat row')

check(snapshot.equipped_has_lite_items({
    equipped = {
        { id = 1, name = "A", depth = "full", stats = { ac = 10 }, baseStats = { ac = 10 } },
        { id = 2, name = "B", depth = "lite" },
    },
}) == true, 'detects lite worn in snap')

check(snapshot.equipped_has_lite_items({
    equipped = {
        { id = 1, name = "A", depth = "full", stats = { ac = 10 }, baseStats = { ac = 10 } },
        { id = 2, name = "B", depth = "full", stats = { hp = 5 }, baseStats = { hp = 5 } },
    },
}) == false, 'healthy full snap has no lite/poison worn')

check(snapshot.equipped_has_lite_items({
    equipped = {
        { id = 1, name = "Poison", stats = { ac = 0 }, baseStats = { ac = 0 } },
    },
}) == true, 'detects legacy zero-stat poison worn')

if failed > 0 then
    io.stderr:write(string.format('turbogear_worn_refresh_test: %d passed, %d failed\n', passed, failed))
    os.exit(1)
end

print(string.format('turbogear_worn_refresh_test: %d passed, %d failed', passed, failed))
