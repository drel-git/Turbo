-- TurboGear/references/lockouts.lua
-- Static lockout definitions (display labels + MQ DynamicZoneWnd lookup keys).

local M = {}

-- Categories match LazBiS lockout groups. `label` is shown in the UI; `lockout` is
-- the DZ_TimerList search key; `index` defaults to 2 when omitted.
M.categories = {
    Raid = {
        { name = "Anguish", lockout = "=Overlord Mata Muram", zone = "Wall of Slaughter", index = 3 },
        { name = "Crest", lockout = "Threads_of_Chaos", zone = "Qeynos Hills (BB)" },
        { name = "DSK", lockout = "=Dreadspire_HC", zone = "Castle Mistmoore" },
        { name = "Fippy", lockout = "=Broken World", zone = "HC Qeynos Hills (pond)" },
        { name = "FUKU", lockout = "The Fabled Undead Knight", zone = "Unrest" },
        { name = "Trak", lockout = "Trakanon_Final", zone = "HC Sebilis" },
        { name = "Veksar", lockout = "A Lake of Ill Omens", zone = "Lake of Ill Omen" },
        { name = "$$PAID$$ DSK", lockout = "Dreadspire_HC [Time Keeper]", zone = "Plane of Time" },
        { name = "$$PAID$$ Fippy", lockout = "Broken World [Time Keeper]", zone = "Plane of Time" },
    },
    TwoGroupRaid = {
        { name = "Crucible of the Brawler", lockout = "Crucible of the Brawler", zone = "Nightveil Sanctum" },
        { name = "Crucible of the Occultist", lockout = "Crucible of the Occultist", zone = "Nightveil Sanctum" },
        { name = "Crucible of the Physician", lockout = "Crucible of the Physician", zone = "Nightveil Sanctum" },
        { name = "Crucible of the Warden", lockout = "Crucible of the Warden", zone = "Nightveil Sanctum" },
        { name = "Manastone Source", lockout = "Manastone Source", zone = "HC Guk Bottom" },
        { name = "The Crimson Curse", lockout = "The Crimson Curse", zone = "Chardok" },
        { name = "VP Hardcore", lockout = "VP Hardcore", zone = "Nightveil Sanctum" },
    },
    Group = {
        { name = "Ayonae", label = "Ayonae Ro", lockout = "Confront the Maestra", zone = "Surefall Glade" },
        { name = "Doll Maker", lockout = "Doll Maker", zone = "Kithicor Forest" },
        { name = "Fenrir", lockout = "Bloodfang", zone = "West Karana" },
        { name = "Finish Them Off", lockout = "Finish them off", zone = "Castle Mistmoore" },
        { name = "Howling Stones", lockout = "Echoes of Charasis", zone = "The Overthere" },
        { name = "Keepsakes", lockout = "Keepsakes", zone = "Surefall Glade" },
        { name = "Lucian's Nightmare", lockout = "Lucian's Nightmare", zone = "Nightveil Sanctum" },
        { name = "Selana", lockout = "Moonshadow", zone = "West Karana" },
        { name = "Venril Sathir", lockout = "Revenge on Venril Sathir", zone = "Karnors Castle" },
    },
    OldRaids = {
        { name = "Plane of Time", lockout = "Quarm", zone = "Plane of Time", index = 3 },
        { name = "Riftseekers", lockout = "Riftseeker", zone = "Riftseeker" },
        { name = "Tacvi", lockout = "Tunat", zone = "Txevu", index = 3 },
        { name = "Txevu", lockout = "Txevu", zone = "Txevu" },
        { name = "Trial of Adaptation", lockout = "Proving Grounds: The Mastery of Adaptation", zone = "MPG" },
        { name = "Trial of Corruption", lockout = "Proving Grounds: The Mastery of Corruption", zone = "MPG" },
        { name = "Trial of Endurance", lockout = "Proving Grounds: The Mastery of Endurance", zone = "MPG" },
        { name = "Trial of Foresight", lockout = "Proving Grounds: The Mastery of Foresight", zone = "MPG" },
        { name = "Trial of Hatred", lockout = "Proving Grounds: The Mastery of Hatred", zone = "MPG" },
        { name = "Trial of Specialization", lockout = "Proving Grounds: The Mastery of Specialization", zone = "MPG" },
    },
}

M.category_order = { "Raid", "TwoGroupRaid", "Group", "OldRaids" }
M.ui_category_order = { "Raid", "TwoGroupRaid", "Group", "OldRaids", "Custom" }

M.category_labels = {
    Raid = "Raids",
    TwoGroupRaid = "2 Group",
    Group = "1 Group",
    OldRaids = "Old Raids",
    Custom = "Custom",
}

function M.display_label(entry)
    if not entry then return "?" end
    local base = entry.label and entry.label ~= "" and entry.label
        or (entry.display and entry.display ~= "" and tostring(entry.display))
        or tostring(entry.name or "?")
    if entry.zone and entry.zone ~= "" then
        return string.format("%s (%s)", base, tostring(entry.zone))
    end
    return base
end

function M.category_label(category)
    return M.category_labels[tostring(category or "")] or tostring(category or "?")
end

return M
