-- Offline: check_announce_need_for_link finds needs without reverse-index / dcat.
-- Run from repo root: luajit lua/tests/turbogear_announce_link_need_test.lua
package.path = "lua/turbogear/?.lua;lua/turbogear/?/init.lua;" .. package.path

package.preload["mq"] = function()
    local function empty_item()
        return setmetatable({}, {
            __call = function() return nil end,
            __index = function() return nil end,
        })
    end
    return {
        TLO = {
            Me = {
                CleanName = function() return "Drel" end,
                Class = { Name = function() return "Wizard" end },
            },
            MacroQuest = { Server = function() return "Project Lazarus" end },
            EverQuest = { GameState = function() return "INGAME" end },
            FindItem = function() return empty_item() end,
            FindItemBank = function() return empty_item() end,
            Cursor = empty_item(),
        },
        configDir = ".",
    }
end

package.preload["config"] = function()
    return {
        CFG = { perf_live_self_bis = true },
        Settings = {},
        SharedSettings = { bisAnnounceDisabledLists = {} },
        SaveSettings = function() end,
        SaveSharedSettings = function() end,
        known_class = function(c)
            c = tostring(c or "")
            if c == "" or c == "?" then return nil end
            return c
        end,
        canonical_class = function(c)
            c = tostring(c or "")
            if c == "" or c == "?" then return nil end
            if c == "Shadowknight" then return "Shadow Knight" end
            return c
        end,
    }
end

package.preload["diagnostics"] = function()
    return {
        time = function(_, fn) return fn() end,
        count = function() end,
        event = function() end,
        sample = function() end,
    }
end

local pass, fail = 0, 0
local function check(cond, msg)
    if cond then
        pass = pass + 1
    else
        fail = fail + 1
        print("FAIL: " .. tostring(msg))
    end
end

local catalog = require("bis_catalog")
catalog.warm_catalog()
check(catalog.catalog_loaded() == true, "catalog_loaded after warm")

local function empty_snap(class, name)
    return {
        name = name or "Drel",
        server = "Project Lazarus",
        class = class,
        equipped = {},
        bags = {},
        bank = {},
        augs = {},
        spells = {},
    }
end

local wizard = empty_snap("Wizard", "Drel")
for _, name in ipairs({ "Frigid Slime of Suffering", "Hideous Hex of Noxious Demise" }) do
    local need = catalog.check_announce_need_for_link(wizard, name, 0, { skip_live = true })
    check(need ~= nil, "Wizard empty snap needs " .. name)
end

-- Melee-only preanguish clickies: Wizard should not need; Warrior should.
check(catalog.check_announce_need_for_link(wizard, "Ring of Organic Darkness", 0, { skip_live = true }) == nil,
    "Wizard does not need Ring of Organic Darkness")
local warrior = empty_snap("Warrior", "Discord")
check(catalog.check_announce_need_for_link(warrior, "Ring of Organic Darkness", 0, { skip_live = true }) ~= nil,
    "Warrior empty snap needs Ring of Organic Darkness")

-- Unknown class: class-specific preanguish rows stay gated.
check(catalog.check_announce_need_for_link(empty_snap("?", "Discord"), "Ring of Organic Darkness", 0, { skip_live = true }) == nil,
    "class ? yields no ring need")
-- Unknown class: shared template rows (fungal/augs) still need-check.
check(catalog.check_announce_need_for_link(empty_snap("", "Discord"), "Frigid Slime of Suffering", 0, { skip_live = true }) ~= nil,
    "blank class still needs template fungal item")
check(catalog.check_announce_need_for_link(empty_snap("?", "Discord"), "Hideous Hex of Noxious Demise", 0, { skip_live = true }) ~= nil,
    "class ? still needs template Hideous Hex")

-- Wrong link id that matches an OWNED early row must not hide a real name need.
local chest = catalog.resolve_entry("preanguish", "Wizard", "Chest")
check(chest and chest.ids and chest.ids[1], "Wizard preanguish Chest resolves")
local owned_early = empty_snap("Wizard", "Drel")
owned_early.bags = { { name = chest.item, id = chest.ids[1] } }
local need = catalog.check_announce_need_for_link(
    owned_early, "Frigid Slime of Suffering", chest.ids[1], { skip_live = true })
check(need ~= nil and need.item_name == "Frigid Slime of Suffering",
    "name match preferred over owned wrong-id row")

-- Status explain: owned vs class-gated no-row.
check(catalog.explain_announce_skip_for_link(wizard, "Desolate Black Sapphire", 0, { skip_live = true }) == "no-row",
    "Wizard sapphire explain is no-row")
check(catalog.explain_announce_skip_for_link(warrior, "Desolate Black Sapphire", 0, { skip_live = true }) == "owned"
    or catalog.check_announce_need_for_link(warrior, "Desolate Black Sapphire", 0, { skip_live = true }) ~= nil,
    "Warrior empty sapphire is need (or owned only if somehow present)")
local bloom = "Noxious Bloom of Ebbing Exertion"
check(catalog.check_announce_need_for_link(empty_snap("Enchanter", "Discord"), bloom, 0, { skip_live = true }) ~= nil,
    "empty Enchanter needs Noxious Bloom")
local tiered = empty_snap("Enchanter", "Discord")
tiered.bags = { { name = "Fungal Bloom of Ebbing Exertion - Tier I", id = 1 } }
check(catalog.check_announce_need_for_link(tiered, bloom, 0, { skip_live = true }) == nil,
    "Tier I fungal owns base Noxious Bloom link")
check(catalog.explain_announce_skip_for_link(tiered, bloom, 0, { skip_live = true }) == "owned",
    "Tier I fungal explain is owned")

-- Self-link chat junk on the visible name must not yield no-row.
local junk = bloom .. ' ">'
check(catalog.check_announce_need_for_link(empty_snap("Wizard", "Drel"), junk, 0, { skip_live = true }) ~= nil,
    "trailing quote-angle on bloom name still needs")
check(catalog.clean_link_item_name(bloom .. '">') == bloom, "clean strips trailing quote-angle")
check(catalog.clean_link_item_name("\x12ABC\x12" .. bloom .. '">') == bloom,
    "clean strips link frames and trailing junk")
local hex_bloom = "008CCD00000000000000000000000000000000000000000000000AC7F59C9" .. bloom .. '">'
check(catalog.clean_link_item_name(hex_bloom) == bloom, "clean strips leading item-link hex")
check(catalog.check_announce_need_for_link(empty_snap("Wizard", "Drel"), hex_bloom, 0, { skip_live = true }) ~= nil,
    "hex-prefixed bloom name still needs")
local sapphire = "Desolate Black Sapphire"
local hex_sap = "008CCD00000000000000000000000000000000000000000000000AC7F59C9" .. sapphire .. '">'
check(catalog.clean_link_item_name(hex_sap) == sapphire, "clean strips hex from sapphire")
check(catalog.check_announce_need_for_link(empty_snap("Shadow Knight", "Drel"), hex_sap, 0, { skip_live = true }) ~= nil,
    "hex-prefixed sapphire still needs for SK")
check(catalog.check_announce_need_for_link(empty_snap("Berserker", "Discord"), hex_sap, 0, { skip_live = true }) ~= nil,
    "hex-prefixed sapphire still needs for Ber")

-- BiS paint (bis_search) wins over Store for peer columns — same as the grid.
do
    local slot_hits = {}
    package.loaded["bis_search"] = {
        slot_rec = function(snap, list_id, slot)
            local k = tostring(snap and snap.name) .. "\31" .. tostring(list_id) .. "\31" .. tostring(slot)
            return slot_hits[k]
        end,
    }
    local function paint(list_id, slot, status)
        slot_hits["Discord\31" .. list_id .. "\31" .. slot] = {
            status = status, count = status == "missing" and 0 or 1, name = bloom, location = "Bags",
        }
    end
    local peer = empty_snap("Enchanter", "Discord")
    peer.bags = { { name = bloom, id = 42 } } -- Store says owned
    paint("fungal", "Base Noxious Bloom of Ebbing Exertion (Double Attack)", "missing")
    check(catalog.check_announce_need_for_link(peer, bloom, 0, { skip_live = true }) ~= nil,
        "bis_search missing overrides Store owned (BiS paint truth)")
    -- All matching announce lists must paint owned (bloom hits fungal + sebilis).
    paint("fungal", "Base Noxious Bloom of Ebbing Exertion (Double Attack)", "carried")
    paint("sebilis", "FlowerAug3 (Double Attack)", "carried")
    local empty_peer = empty_snap("Enchanter", "Discord")
    check(catalog.check_announce_need_for_link(empty_peer, bloom, 0, { skip_live = true }) == nil,
        "bis_search carried overrides empty Store (BiS paint truth)")
    package.loaded["bis_search"] = nil
end

print(string.format("announce_link_need: %d passed, %d failed", pass, fail))
os.exit(fail == 0 and 0 or 1)
