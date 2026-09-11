-- DoN learned-ability checks: lean live probe, memo, peer bis_search, unknown state.
-- Run from repo root: luajit lua/tests/turbogear_don_spells_lean_test.lua
package.path = "lua/turbogear/?.lua;lua/turbogear/?/init.lua;" .. package.path

-- World state the mq stub answers from.
local world = { book = {}, combat = {}, bags = {}, bank = {}, spell_names = {} }
local calls = { total = 0, gem = 0, me_spell = 0 }
local function count(kind)
    calls.total = calls.total + 1
    if kind then calls[kind] = (calls[kind] or 0) + 1 end
end
local function reset_calls() calls = { total = 0, gem = 0, me_spell = 0 } end
local function item(id)
    return setmetatable({}, {
        __call = function() return id end,
        __index = function(_, k)
            if k == "Count" then return function() return 1 end end
            if k == "ID" then return function() return id end end
            if k == "Name" then return function() return tostring(id) end end
            if k == "ItemSlot" then return function() return 30 end end
            return function() return nil end
        end,
    })
end
local nothing = setmetatable({}, { __call = function() return nil end, __index = function() return function() return nil end end })

package.preload["mq"] = function()
    return {
        TLO = {
            Me = {
                CleanName = function() return "Viewer" end,
                Class = { Name = function() return "Shaman" end },
                Book = function(n) count("book"); return world.book[n] and 5 or nil end,
                CombatAbility = function(n) count("combat"); return world.combat[n] and 3 or nil end,
                Spell = function() count("me_spell"); return nil end,
                Gem = function() count("gem"); return nil end,
                NumGems = function() count("gem"); return 12 end,
            },
            Spell = function(id)
                count("spell_id")
                local n = world.spell_names[id]
                return setmetatable({}, { __call = function() return n end, __index = function(_, k)
                    if k == "Name" then return function() return n end end
                    return nil
                end })
            end,
            MacroQuest = { Server = function() return "Project Lazarus" end },
            EverQuest = { GameState = function() return "INGAME" end },
            FindItem = function(q) count("find"); return (type(q) == "number" and world.bags[q]) and item(q) or nothing end,
            FindItemBank = function(q) count("find_bank"); return (type(q) == "number" and world.bank[q]) and item(q) or nothing end,
            Cursor = nothing,
        },
        configDir = ".",
        pickle = function() end,
        cmd = function() end,
    }
end
package.preload["config"] = function()
    return {
        CFG = {}, Settings = {}, SharedSettings = { bisAnnounceDisabledLists = {} },
        SaveSettings = function() end, SaveSharedSettings = function() end,
        BisSearchFile = "/nonexistent/tg_bissearch_test.lua",
        known_class = function(c) c = tostring(c or ""); if c == "" or c == "?" then return nil end; return c end,
        canonical_class = function(c) c = tostring(c or ""); if c == "" or c == "?" then return nil end; return c end,
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

local catalog = require("bis_catalog")
catalog.warm_catalog("test")
local DS = require("don_spells")
local bis_search = require("bis_search")

local fake_now = 100.0
DS._set_live_clock_for_tests(function() return fake_now end)

local function ability(class, name)
    for _, ab in ipairs(DS.abilities_for_class(class)) do
        if ab.display_name == name then return ab end
    end
end
local function entry_for(class, name) return catalog.resolve_entry("don", class, name) end
local function live(class, name, opts)
    reset_calls()
    local _, _, status = DS.try_live_match(entry_for(class, name), opts or { fresh = true })
    return status, calls.total
end
local function reset_world() world = { book = {}, combat = {}, bags = {}, bank = {}, spell_names = {} } end

-- --------------------------------------------------------------- identities
check(#DS.spell_slots_for_class("Shaman") == 15, "Shaman has 15 DoN abilities")
check(ability("Bard", "Arcane Reprisal") ~= nil, "Arcane Reprisal is a Bard ability (item 79226 classes 33216 includes BRD)")

-- ------------------------------------------------------------ lean probe cost
reset_world()
world.book["Curse of Emoush"] = true
local st, n = live("Shaman", "Curse of Emoush")
check(st == "known", "Book hit -> known")
check(n == 1, "known spell costs 1 query (got " .. n .. ")")

reset_world()
world.combat["Arcane Reprisal"] = true
st, n = live("Bard", "Arcane Reprisal")
check(st == "known", "CombatAbility hit -> known (disc)")
check(n == 2, "known disc costs 2 queries (got " .. n .. ")")

local sloth = ability("Shaman", "Shadowy Sloth")
reset_world()
world.bags[sloth.primary_teaching_item_id] = true
st = live("Shaman", "Shadowy Sloth")
check(st == "ready", "teaching item in bags -> ready")

reset_world()
world.bank[sloth.primary_teaching_item_id] = true
st = live("Shaman", "Shadowy Sloth")
check(st == "ready", "teaching item in BANK -> ready (was missing before)")

local cougar = ability("Shaman", "Talisman of the Cougar")
reset_world()
world.bank[cougar.source_container_item_id] = true
st = live("Shaman", "Talisman of the Cougar")
check(st == "pack_owned", "pack container in bank -> pack_owned")

reset_world()
local worst = 0
for _, slot in ipairs(DS.spell_slots_for_class("Shaman")) do
    local s, c = live("Shaman", slot)
    check(s == "missing", slot .. ": nothing held -> missing")
    if c > worst then worst = c end
end
check(worst <= 8, "missing row costs <= 8 queries (worst " .. worst .. ")")
check(calls.gem == 0 and calls.me_spell == 0, "no gem scan / Me.Spell in the lean path")

-- Apostrophe names: variants only when the name has one.
local bard_apos
for _, ab in ipairs(DS.abilities_for_class("Bard")) do
    if ab.display_name:find("'") then bard_apos = ab.display_name; break end
end
check(bard_apos ~= nil, "found a Bard ability with an apostrophe (" .. tostring(bard_apos) .. ")")
if bard_apos then
    reset_world()
    world.book[(bard_apos:gsub("'", "`"))] = true
    check(live("Bard", bard_apos) == "known", "apostrophe variant (backtick) still matches")
end

-- Catalog name differs from in-game name: learned spell id's name is tried.
local emoush = ability("Shaman", "Curse of Emoush")
reset_world()
world.spell_names[emoush.learned_spell_id] = "Curse of Emoush Rk. II"
world.book["Curse of Emoush Rk. II"] = true
check(live("Shaman", "Curse of Emoush") == "known", "spell-id name fallback finds a renamed/ranked spell")

-- ----------------------------------------------------------------------- memo
reset_world()
world.book["Curse of Emoush"] = true
DS.invalidate_live()
live("Shaman", "Curse of Emoush", {})                 -- prime
reset_calls()
for _ = 1, 100 do DS.try_live_match(entry_for("Shaman", "Curse of Emoush")) end
check(calls.total == 0, "draw-loop calls within TTL cost zero queries")

-- Expire everything: renewals are capped per window, not all in one frame.
DS.invalidate_live()
for _, slot in ipairs(DS.spell_slots_for_class("Shaman")) do DS.try_live_match(entry_for("Shaman", slot)) end
fake_now = fake_now + 10
reset_calls()
local probed_rows = 0
for _, slot in ipairs(DS.spell_slots_for_class("Shaman")) do
    local before = calls.total
    DS.try_live_match(entry_for("Shaman", slot))
    if calls.total > before then probed_rows = probed_rows + 1 end
end
check(probed_rows == 4, "expired memo re-probes at most 4 rows per window (got " .. probed_rows .. ")")

world.book["Shadowy Sloth"] = true
check(select(3, DS.try_live_match(entry_for("Shaman", "Shadowy Sloth"), { fresh = true })) == "known",
    "fresh probe bypasses memo (peer search / after scribe)")

-- ---------------------------------------------------------- peer bis_search
reset_world()
world.book["Curse of Emoush"] = true
world.combat["Breath of Shadows"] = true
world.bank[sloth.primary_teaching_item_id] = true
reset_calls()
local res = bis_search.search_local("don")
check(type(res) == "table" and type(res.slots) == "table", "search_local('don') returns a slot map")
local spell_rows = 0
for _, slot in ipairs(DS.spell_slots_for_class("Shaman")) do
    if res.slots[slot] then spell_rows = spell_rows + 1 end
end
check(spell_rows == 15, "all 15 Shaman DoN abilities answered by the peer (got " .. spell_rows .. ")")
check(res.slots["Curse of Emoush"].status == "known", "peer result: known")
check(res.slots["Breath of Shadows"].status == "known", "peer result: known via CombatAbility")
check(res.slots["Shadowy Sloth"].status == "ready", "peer result: tome in bank -> ready")
check(res.slots["Stillmoon Focusing"].status == "missing", "peer result: missing")
check((samples["bis_search.don_spell_lookups"] or 999) <= 15 * 8,
    "spell part of a peer search stays bounded (" .. tostring(samples["bis_search.don_spell_lookups"]) .. " lookups)")

-- Viewer side: apply the peer's reply and evaluate its column.
res.name, res.server, res.class = "PeerShm", "Project Lazarus", "Shaman"
check(bis_search.apply_result(res), "apply peer result")
local peer_snap = { name = "PeerShm", server = "Project Lazarus", class = "Shaman",
    equipped = {}, bags = {}, bank = {}, augs = {} } -- no spellbook in snapshot
local function peer_row(slot) return catalog.evaluate_slot("don", peer_snap, slot, "Spells") end
check(peer_row("Curse of Emoush").status == "known" and peer_row("Curse of Emoush").have, "peer grid: known from search")
check(peer_row("Shadowy Sloth").status == "ready", "peer grid: ready from search")
check(peer_row("Stillmoon Focusing").status == "missing", "peer grid: searched + missing stays missing")

local silent = { name = "NoReply", server = "Project Lazarus", class = "Shaman", equipped = {}, bags = {}, bank = {}, augs = {} }
local r = catalog.evaluate_slot("don", silent, "Curse of Emoush", "Spells")
check(r.status == "unknown" and r.have == false, "peer with no search reply and no spellbook -> unknown, not missing")
silent.spells = { ["some spell"] = { name = "Some Spell", book = 1 } }
r = catalog.evaluate_slot("don", silent, "Curse of Emoush", "Spells")
check(r.status == "missing", "peer with a snapshot spellbook that lacks it -> missing")
silent.spells = { ["curse of emoush"] = { name = "Curse of Emoush", book = 1 } }
r = catalog.evaluate_slot("don", silent, "Curse of Emoush", "Spells")
check(r.status == "known", "peer snapshot spellbook still counts when there is no search reply")

-- Spell-only change reuses the gear index (no gear walk), refreshes spells.
local OI = require("ownership_index")
local gear_snap = { name = "GearSame", server = "Project Lazarus", class = "Shaman",
    equipped = {}, bags = { { id = 1001, name = "Some Gear" } }, bank = {}, augs = {},
    spells_sig = "v1", spells = {} }
local idx1 = OI.cached_snapshot_index(gear_snap)
local before = OI.fingerprint_cache_stats().spell_refreshes or 0
local next_snap = { name = "GearSame", server = "Project Lazarus", class = "Shaman",
    equipped = {}, bags = { { id = 1001, name = "Some Gear" } }, bank = {}, augs = {},
    spells_sig = "v2", spells = { ["curse of emoush"] = { name = "Curse of Emoush", book = 1 } } }
local idx2 = OI.cached_snapshot_index(next_snap)
check(idx2.by_id == idx1.by_id, "spell change keeps the gear index (same by_id table, no gear rebuild)")
check(idx2.known_spells["curse of emoush"] == true, "spell change is visible immediately")
check((OI.fingerprint_cache_stats().spell_refreshes or 0) == before + 1, "exactly one spell-only refresh")
check(OI.cached_snapshot_index(next_snap) == idx2, "second lookup is a plain cache hit")

print(string.format("don spells lean: %d passed, %d failed", pass, fail))
if fail > 0 then os.exit(1) end
