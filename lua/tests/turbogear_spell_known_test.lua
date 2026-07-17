-- Run from repo root:  luajit lua\tests\turbogear_spell_known_test.lua
-- Ensures Me.Book returning a raw number (MQ Lua) is treated as known.

package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

local book_slots = {
    ['Theft of Misery'] = 2,
}
local combat = {}
local spell_names = {
    ['Theft of Misery'] = 'Theft of Misery',
}

package.preload['mq'] = function()
    return {
        TLO = {
            Me = {
                Book = function(name)
                    return book_slots[name]
                end,
                CombatAbility = function(name)
                    return combat[name]
                end,
                Spell = function(name)
                    local n = spell_names[name]
                    if not n then return nil end
                    return function() return n end
                end,
            },
            Spell = function() return nil end,
        },
    }
end

local SK = require('spell_known')

local passed, failed = 0, 0
local function check(cond, label)
    if cond then
        passed = passed + 1
    else
        failed = failed + 1
        io.stderr:write('FAIL: ', tostring(label), '\n')
    end
end

check(SK.live('Theft of Misery') == true, 'raw Book number counts as known')
check(SK.live('Not A Real Spell') == false, 'missing spell is unknown')

-- Callable userdata-style Book (returns number via ())
book_slots['Callable Book'] = nil
local callable = setmetatable({}, {
    __call = function() return 5 end,
})
-- Simulate MQ returning callable: Book returns the callable itself
package.loaded['mq'] = {
    TLO = {
        Me = {
            Book = function(name)
                if name == 'Callable Book' then return callable end
                return book_slots[name]
            end,
            CombatAbility = function() return nil end,
            Spell = function() return nil end,
        },
        Spell = function() return nil end,
    },
}
package.loaded['spell_known'] = nil
SK = require('spell_known')
check(SK.live('Callable Book') == true, 'callable Book() number counts as known')

io.write(string.format('turbogear_spell_known_test: %d passed, %d failed\n', passed, failed))
os.exit(failed == 0 and 0 or 1)
