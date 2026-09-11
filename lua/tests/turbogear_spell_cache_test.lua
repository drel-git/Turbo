-- Run: luajit lua/tests/turbogear_spell_cache_test.lua
-- Offline checks for spell-like item gate + cache membership (no MQ probes).

package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

package.preload['mq'] = function()
    return {
        TLO = {
            Me = {
                Class = {
                    Name = function() return 'Cleric' end,
                    ShortName = function() return 'CLR' end,
                },
                Book = function() return nil end,
                CombatAbility = function() return nil end,
                Spell = function() return nil end,
            },
            Spell = function() return nil end,
        },
    }
end

-- Minimal don_spells stub for id gate (avoid loading full catalog).
package.preload['don_spells'] = function()
    return {
        is_learn_item_id = function(id)
            return tonumber(id) == 78079
        end,
    }
end

package.loaded['spell_cache'] = nil
local SC = require('spell_cache')

local passed, failed = 0, 0
local function check(cond, label)
    if cond then
        passed = passed + 1
    else
        failed = failed + 1
        io.stderr:write('FAIL: ', tostring(label), '\n')
    end
end

check(SC.is_spell_like_item('Spell: Aegis of Vie', 0) == true, 'Spell: prefix')
check(SC.is_spell_like_item('Song: Something', 0) == true, 'Song: prefix')
check(SC.is_spell_like_item('Tome of Jeer', 0) == true, 'Tome in name')
check(SC.is_spell_like_item('Tome Pack: Ancient', 0) == true, 'Tome Pack')
check(SC.is_spell_like_item('Emerald', 0) == false, 'non-spell name')
check(SC.is_spell_like_item('Emerald', 78079) == true, 'DoN learn item id')
check(SC.is_spell_like_item('Emerald', 1) == false, 'unrelated id')

SC._reset_for_tests()
-- Inject known set without rebuild/MQ
package.loaded['spell_cache'] = nil
-- Re-require and poke internals via rebuild stub: use probe recording path
SC = require('spell_cache')
SC._reset_for_tests()

-- Simulate building probes
assert(SC.building() == false)
-- Manually exercise probe_name against stubbed spell_known
package.preload['spell_known'] = function()
    return {
        live = function(name) return name == 'Aegis of Vie' end,
        live_id = function(id) return tonumber(id) == 9742 end,
    }
end
package.loaded['spell_known'] = nil

-- Force building flag via private path: call probe while faking building
-- by using rebuild with stubbed spell_snapshot
package.preload['spell_snapshot'] = function()
    return {
        gather = function()
            local SC2 = require('spell_cache')
            SC2.probe_name('Aegis of Vie')
            SC2.probe_id(9742)
            return {
                ['aegis of vie'] = { name = 'Aegis of Vie', book = 1, scroll = 0, spell_id = 9742 },
            }, { [9742] = true }
        end,
        signature = function(map)
            local parts = {}
            for k, row in pairs(map or {}) do
                parts[#parts + 1] = string.format('%s:%d:%d', k, tonumber(row.book) or 0, tonumber(row.scroll) or 0)
            end
            table.sort(parts)
            return table.concat(parts, '\31')
        end,
    }
end
package.loaded['spell_snapshot'] = nil
package.loaded['spell_cache'] = nil
SC = require('spell_cache')
SC._reset_for_tests()
local changed = SC.rebuild('Cleric')
check(changed == true, 'first rebuild changes sig')
check(SC.ready() == true, 'cache ready after rebuild')
check(SC.is_known('Aegis of Vie') == true, 'known by name')
check(SC.is_known(9742) == true, 'known by id')
check(SC.is_known('Not A Spell') == false, 'unknown name')
local changed2 = SC.rebuild('Cleric')
check(changed2 == false, 'second rebuild same sig')

-- Restore from persisted snap does not live-gather
SC._reset_for_tests()
local restored, why = SC.restore_from_snapshot({
    spells_sig = 'aegis of vie:1:0:9742',
    spells = {
        ['aegis of vie'] = { name = 'Aegis of Vie', book = 1, scroll = 0, spell_id = 9742 },
    },
    spell_ids = { [9742] = true },
})
check(restored == true and why == 'restored', 'restore_from_snapshot hydrates cache')
check(SC.ready() == true, 'ready after restore')
check(SC.is_known('Aegis of Vie') == true, 'restored name known')
check(SC.is_known(9742) == true, 'restored id known')
check(select(1, SC.restore_from_snapshot({})) == false, 'empty snap is not restored')
SC._reset_for_tests()
SC.note_deferred_unready()
check(SC.deferred_unready() == true, 'note_deferred_unready')
check(SC.ensure_built() == false, 'deferred unready does not rebuild')

io.write(string.format('turbogear_spell_cache_test: %d passed, %d failed\n', passed, failed))
os.exit(failed == 0 and 0 or 1)
