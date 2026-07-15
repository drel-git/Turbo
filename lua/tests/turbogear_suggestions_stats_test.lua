package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

package.loaded.item_index = { rows = {}, get = function() return {}, 0 end }
package.loaded.views = {
    clean_name = function(v) return tostring(v or ''):lower() end,
    class_abbrev = function(v) return tostring(v or '') end,
    source_snapshot = function() return nil end,
    index_equipped = function() return {} end,
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

if failed > 0 then
    io.stderr:write(string.format('turbogear_suggestions_stats_test: %d passed, %d failed\n', passed, failed))
    os.exit(1)
end

print(string.format('turbogear_suggestions_stats_test: %d passed, %d failed', passed, failed))
