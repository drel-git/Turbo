-- Research roster self-scan (spell_cache.rebuild -> spell_snapshot.gather ->
-- research_catalog.spell_inventory_info): lean book probe, scroll count only
-- when unscribed, Song:/Tome of/Tome: item names, bounded query cost.
-- Run from repo root: luajit lua/tests/turbogear_research_spells_lean_test.lua
package.path = "lua/turbogear/?.lua;lua/turbogear/?/init.lua;" .. package.path

local world = { class = "Magician", short = "MAG", book = {}, combat = {}, items = {} }
local calls = {}
local function count(k) calls.total = (calls.total or 0) + 1; calls[k] = (calls[k] or 0) + 1 end
local function reset_calls() calls = { total = 0 } end
reset_calls()
local function num(v) return setmetatable({}, { __call = function() return v end }) end
local nothing = setmetatable({}, { __call = function() return nil end, __index = function() return function() return nil end end })

package.preload["mq"] = function()
    return {
        TLO = {
            Me = {
                CleanName = function() return "Tester" end,
                Class = setmetatable({ Name = function() return world.class end, ShortName = function() return world.short end },
                    { __call = function() return world.class end }),
                Book = function(n) count("book"); return world.book[n] and 7 or nil end,
                CombatAbility = function(n) count("combat"); return world.combat[n] and 2 or nil end,
                Spell = function() count("me_spell"); return nil end,
                Gem = function() count("gem"); return nil end,
                NumGems = function() count("gem"); return 12 end,
                Level = function() return 70 end,
            },
            Spell = function() count("spell_id"); return nothing end,
            FindItemCount = function(q) count("find_count"); return num(world.items[tostring(q):gsub("^=", "")] or 0) end,
            FindItemBankCount = function(q) count("find_bank_count"); return num(0) end,
            FindItem = function() count("find"); return nothing end,
            FindItemBank = function() count("find_bank"); return nothing end,
            MacroQuest = { Server = function() return "Project Lazarus" end, Path = function() return "" end },
            EverQuest = { GameState = function() return "INGAME" end },
            Cursor = nothing,
        },
        configDir = ".",
        pickle = function() end,
    }
end
package.preload["config"] = function()
    return {
        CFG = {}, Settings = {}, SharedSettings = { bisAnnounceDisabledLists = {} },
        SaveSettings = function() end, SaveSharedSettings = function() end,
        known_class = function(c) return c end, canonical_class = function(c) return c end,
    }
end
local samples = {}
package.preload["diagnostics"] = function()
    return { time = function(_, fn) return fn() end, count = function() end, event = function() end,
        sample = function(k, v) samples[k] = v end, context = function() end }
end

local pass, fail = 0, 0
local function check(cond, msg)
    if cond then pass = pass + 1 else fail = fail + 1; print("FAIL: " .. tostring(msg)) end
end

local RC = require("research_catalog")
RC.resolve_ini_path = function() return "lua/turbogear/data/researchlearn.ini" end -- Linux test path
local SC = require("spell_cache")

-- ------------------------------------------------------- scroll name candidates
local c = RC.scroll_item_candidates("Zuriki's Song of Shenanigans", "Spell: Zuriki's Song of Shenanigans", "BRD")
check(c[1] == "Spell: Zuriki's Song of Shenanigans" and c[2] == "Song: Zuriki's Song of Shenanigans",
    "bard: ini item name first, then Song:")
c = RC.scroll_item_candidates("Vengeful Flurry Discipline", nil, "MNK")
check(c[1] == "Tome of Vengeful Flurry Discipline" and c[2] == "Tome: Vengeful Flurry Discipline",
    "melee without recipe: Tome of, then Tome:")
c = RC.scroll_item_candidates("Some Nuke", nil, "WIZ")
check(#c == 1 and c[1] == "Spell: Some Nuke", "pure caster without recipe: Spell: only")
c = RC.scroll_item_candidates("Some Heal", nil, "PAL")
check(c[1] == "Spell: Some Heal" and c[2] == "Tome of Some Heal", "hybrid: Spell:, then Tome of")
check(RC.product_norm("Song: Zuriki's Song of Shenanigans") == RC.product_norm("Zuriki's Song of Shenanigans"),
    "Song: prefix normalizes to the spell")
check(RC.product_norm("Tome: Some Disc") == RC.product_norm("Some Disc"), "Tome: prefix normalizes to the spell")

-- ------------------------------------------------------------ roster for MAG
local roster = RC.gather_spell_book("MAG", RC.LEVEL_NUMS)
local names = {}
for _, row in pairs(roster) do names[#names + 1] = row.name end
table.sort(names)
check(#names >= 40, "Magician research roster loaded (" .. #names .. " spells)")

-- All scribed: ~1 query per spell, zero scroll queries, no gem / Me.Spell.
world.book = {}
for _, n in ipairs(names) do world.book[n] = true end
reset_calls()
local rows = RC.gather_spell_book("MAG", RC.LEVEL_NUMS)
local all_known = true
for _, r in pairs(rows) do if (r.book or 0) ~= 1 then all_known = false end end
check(all_known, "every scribed spell reported book=1")
check((calls.find_count or 0) == 0 and (calls.find_bank_count or 0) == 0, "no scroll queries for scribed spells")
check((calls.gem or 0) == 0 and (calls.me_spell or 0) == 0, "no gem scan / Me.Spell")
check(calls.total <= #names * 2, string.format("scribed roster costs <= 2 queries/spell (%d for %d)", calls.total, #names))

-- Nothing scribed, nothing held: bounded per spell.
world.book = {}
reset_calls()
RC.gather_spell_book("MAG", RC.LEVEL_NUMS)
check(calls.total <= #names * 10, string.format("empty roster costs <= 10 queries/spell (%d for %d)", calls.total, #names))

-- Unscribed with a scroll held -> scroll counted.
local target = names[1]
local rec = RC.find_ini_recipe("MAG", target)
local item_name = (rec and rec.iniRaw) or ("Spell: " .. target)
world.items[item_name] = 2
local info = RC.spell_inventory_info(target, rec and rec.iniRaw, nil, nil, "MAG")
check(info.inBook == false and info.scroll == 2, "unscribed + held scroll -> scroll=2 (" .. item_name .. ")")
world.book[target] = true
info = RC.spell_inventory_info(target, rec and rec.iniRaw, nil, nil, "MAG")
check(info.inBook == true and info.scroll == 0, "scribed: spare scrolls no longer counted (by design)")
world.items = {}

-- Bard song held under Song: even though the ini says Spell:.
world.book = {}
world.items["Song: Test Ballad"] = 1
info = RC.spell_inventory_info("Test Ballad", "Spell: Test Ballad", nil, nil, "BRD")
check(info.scroll == 1, "bard: Song: item found when the ini names it Spell:")
world.items = {}

-- Melee tome by 'Tome of'.
world.items["Tome of Test Strike"] = 1
info = RC.spell_inventory_info("Test Strike", nil, nil, nil, "WAR")
check(info.scroll == 1, "melee: Tome of item found")
world.items = {}

-- Disc known via CombatAbility.
world.combat["Test Strike"] = true
info = RC.spell_inventory_info("Test Strike", nil, nil, nil, "WAR")
check(info.inBook == true, "combat ability counts as known")
world.combat = {}

-- ------------------------------------------------------- full rebuild + perf
world.book = {}
for i, n in ipairs(names) do if i % 4 ~= 0 then world.book[n] = true end end
SC.rebuild("Magician")
check(SC.ready(), "spell_cache rebuilt")
local ok_known = true
for i, n in ipairs(names) do
    local want = (i % 4 ~= 0)
    if (SC.is_known(n) == true) ~= want then ok_known = false end
end
check(ok_known, "rebuilt known-set matches the spellbook exactly")
check(type(samples["spell_cache.rebuild_ms"]) == "number", "perfdiag: spell_cache.rebuild_ms sampled")
check(type(samples["spell_cache.rebuild_lookups"]) == "number" and samples["spell_cache.rebuild_lookups"] > 0,
    "perfdiag: spell_cache.rebuild_lookups sampled (" .. tostring(samples["spell_cache.rebuild_lookups"]) .. ")")

print(string.format("research spells lean: %d passed, %d failed", pass, fail))
if fail > 0 then os.exit(1) end
