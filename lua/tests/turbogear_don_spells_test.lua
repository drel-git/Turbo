-- Run from repo root:  luajit lua\tests\turbogear_don_spells_test.lua
-- DoN per-ability ownership: Known / Ready / Pack Owned / Missing.

package.path = "lua/turbogear/?.lua;lua/turbogear/?/init.lua;" .. package.path

package.preload["mq"] = function()
    return {
        configDir = ".",
        TLO = {
            Me = {
                CleanName = function() return "Tester" end,
                Book = function(name)
                    if name == "Shroud of the Accursed" then return 4 end
                    return nil
                end,
                CombatAbility = function() return nil end,
                Spell = function() return nil end,
                Gem = function() return nil end,
                NumGems = function() return 8 end,
            },
            Spell = function(id)
                if tonumber(id) == 10251 then
                    return {
                        Name = function() return "Shroud of the Accursed" end,
                        RankName = function() return nil end,
                    }
                end
                return nil
            end,
            MacroQuest = { Server = function() return "Srv" end },
            FindItem = function() return nil end,
        },
    }
end
package.preload["config"] = function()
    return {
        CFG = { script_name = "TurboGear" },
        Settings = {},
        SharedSettings = {},
        SaveSettings = function() end,
        SaveSharedSettings = function() end,
    }
end

local bis = require("bis")
local DS = require("don_spells")
DS._reset_index_for_tests()

local passed, failed = 0, 0
local function check(cond, label)
    if cond then
        passed = passed + 1
    else
        failed = failed + 1
        io.stderr:write("FAIL: ", tostring(label), "\n")
    end
end

local function snap_with(bags, spells, spell_ids, class_name)
    return {
        name = "Tester",
        server = "Srv",
        class = class_name or "Cleric",
        bags = bags or {},
        equipped = {},
        bank = {},
        spells = spells or {},
        spell_ids = spell_ids or {},
        inventoryUpdated = tostring(os.clock()),
    }
end

local function ability_entry(class_name, display_name)
    local ab = DS.ability_for_slot(class_name, display_name)
    check(ab ~= nil, "catalog has " .. tostring(display_name) .. " for " .. tostring(class_name))
    return DS.bis_entry_for_ability(ab)
end

-- Allegiance ability: independent of Hand of Allegiance.
local allegiance = ability_entry("Cleric", "Allegiance")
local hand = ability_entry("Cleric", "Hand of Allegiance")

local empty = snap_with({})
local r0 = bis.evaluate_entry(allegiance, empty, { skip_live = true })
check(r0.have ~= true and r0.status == "missing", "Allegiance: missing when empty")

local teach = snap_with({ { id = 78067, name = "Spell: Allegiance" } })
local r1 = bis.evaluate_entry(allegiance, teach, { skip_live = true })
check(r1.have == true and r1.status == "ready", "Allegiance: teaching scroll => Ready")

local r1b = bis.evaluate_entry(hand, teach, { skip_live = true })
check(r1b.have ~= true or r1b.status == "missing" or r1b.status == "pack_owned",
    "Hand of Allegiance: Allegiance scroll alone does not mark Ready")

local pack = snap_with({ { id = 82658, name = "Spell Pack: Allegiance" } })
local r2 = bis.evaluate_entry(allegiance, pack, { skip_live = true })
check(r2.have == true and r2.status == "pack_owned", "Allegiance: pack held => Pack Owned (not Known)")

local r2b = bis.evaluate_entry(hand, pack, { skip_live = true })
check(r2b.have == true and r2b.status == "pack_owned", "Hand of Allegiance: same pack => Pack Owned")

local known = snap_with({}, {
    ["allegiance"] = { name = "Allegiance", book = 1 },
}, { [9730] = true })
local r3 = bis.evaluate_entry(allegiance, known, { skip_live = true })
check(r3.have == true and r3.status == "known", "Allegiance: learned_spell_id => Known")

local r3b = bis.evaluate_entry(hand, known, { skip_live = true })
check(r3b.status == "missing", "Hand of Allegiance: Allegiance known does not clear Hand")

-- Echoes alternate teaching item
local echoes = ability_entry("Bard", "Echoes of the Ancient")
local alt = snap_with({ { id = 81936, name = "Song: Echoes of the Ancient" } }, nil, nil, "Bard")
local r4 = bis.evaluate_entry(echoes, alt, { skip_live = true })
check(r4.have == true and r4.status == "ready", "Echoes: alternate teaching item => Ready")

-- Excluded packs must not resolve as known via container alone
local malicious = {
    item = "Tome Pack: Ancient: Malicious Onslaught",
    ids = { 82654 },
    names = { "Tome Pack: Ancient: Malicious Onslaught" },
}
local handled_m = select(1, DS.try_match(malicious, snap_with({ { id = 82654 } }, nil, nil, "Warrior")))
check(handled_m == false, "Malicious Onslaught pack excluded from catalog match")

local jolting = {
    item = "Tome Pack: Jolting Thunderkicks",
    ids = { 82816 },
    names = { "Tome Pack: Jolting Thunderkicks" },
}
local handled_j = select(1, DS.try_match(jolting, snap_with({ { id = 82816 } }, nil, nil, "Monk")))
check(handled_j == false, "Jolting Thunderkicks pack excluded from catalog match")

-- Single vendor tome
local field = ability_entry("Warrior", "Field Conqueror")
local r7 = bis.evaluate_entry(field, snap_with({}, nil, nil, "Warrior"), { skip_live = true })
check(r7.have ~= true, "Field Conqueror: missing when empty")
local r8 = bis.evaluate_entry(field, snap_with({}, {}, { [25036] = true }, "Warrior"), { skip_live = true })
check(r8.have == true and r8.status == "known", "Field Conqueror: spell_id => Known")

-- Sha's abilities are independent
local shas = ability_entry("Beastlord", "Sha's Urgent Renewal")
local feral = ability_entry("Beastlord", "Feral Exigency")
local half = snap_with({ { id = 115093, name = "Spell: Sha's Urgent Renewal" } }, nil, nil, "Beastlord")
local r9 = bis.evaluate_entry(shas, half, { skip_live = true })
check(r9.status == "ready", "Sha's: teaching scroll => Ready")
local r9b = bis.evaluate_entry(feral, half, { skip_live = true })
check(r9b.status == "missing", "Feral Exigency: Sha's scroll alone does not Ready")

-- Non-catalog gear falls through
local gear = { item = "Some Random Sword", ids = { 999999 }, names = { "Some Random Sword" } }
local handled = select(1, DS.try_match(gear, snap_with({})))
check(handled == false, "non-catalog entry is not claimed by don_spells")

-- Live Book path for local toon
local shroud = ability_entry("Shadow Knight", "Shroud of the Accursed")
local empty_local = snap_with({}, nil, nil, "Shadow Knight")
local r11 = bis.evaluate_entry(shroud, empty_local, { skip_live = true })
check(r11.have ~= true, "Shroud: snap-only missing without scroll/book in snap")
local _, _, liveStatus = DS.try_live_match(shroud)
check(liveStatus == "known", "Shroud: try_live_match uses Me.Book")
local list = { entries = { shroud } }
local rows = bis.evaluate(list, empty_local)
check(rows[1] and rows[1].have == true and rows[1].status == "known",
    "Shroud: bis.evaluate marks Known via Me.Book")

-- Slot listing: Cleric has Allegiance; Warrior does not
local clr_slots = DS.spell_slots_for_class("Cleric")
local has_all = false
for _, s in ipairs(clr_slots) do if s == "Allegiance" then has_all = true end end
check(has_all, "Cleric spell slots include Allegiance")
check(DS.ability_for_slot("Warrior", "Allegiance") == nil, "Warrior has no Allegiance slot")

-- Per-class lists are alphabetical and independent (no shared cross-class matrix).
local sk_slots = DS.spell_slots_for_class("Shadow Knight")
check(#sk_slots == 9, "Shadow Knight has 9 DoN abilities")
check(sk_slots[1] == "Blood of the Harbinger", "SK slots sorted A-Z (first)")
check(sk_slots[#sk_slots] == "Voice of Emoush", "SK slots sorted A-Z (last)")
local war_has_cloak = false
for _, s in ipairs(DS.spell_slots_for_class("Warrior")) do
    if s == "Cloak of the Corrupter" then war_has_cloak = true end
end
check(not war_has_cloak, "Warrior list excludes Shadow Knight abilities")
check(DS.max_spell_slots_for_classes({ "Shadow Knight", "Cleric" }) == #clr_slots,
    "roster height is max of visible class lists")

print(string.format("don_spells: %d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
