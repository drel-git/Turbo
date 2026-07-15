-- TurboGear/references/lockouts.lua
-- Static lockout definitions (display labels + MQ DynamicZoneWnd lookup keys).

local M = {}

-- Categories match LazBiS lockout groups. `label` is shown in the UI; `lockout` is
-- the DZ_TimerList search key; `index` defaults to 2 when omitted.
M.categories = {
    Raid = {
        { name = "Crest", label = "Crest (Qeynos Hills)", lockout = "Threads_of_Chaos", zone = "Qeynos Hills" },
        { name = "Fippy", label = "Fippy (HC Qeynos Hills)", lockout = "=Broken World", zone = "HC Qeynos Hills" },
        { name = "$$PAID$$ Fippy", lockout = "Broken World [Time Keeper]", zone = "Plane of Time" },
        { name = "DSK", lockout = "=Dreadspire_HC", zone = "Castle Mistmoore" },
        { name = "$$PAID$$ DSK", lockout = "Dreadspire_HC [Time Keeper]", zone = "Plane of Time" },
        { name = "Veksar", lockout = "A Lake of Ill Omens", zone = "Lake of Ill Omen" },
        { name = "Anguish", lockout = "=Overlord Mata Muram", zone = "Wall of Slaughter", index = 3 },
        { name = "Trak", lockout = "Trakanon_Final", zone = "HC Sebilis" },
        { name = "FUKU", label = "FUKU (HC Unrest)", lockout = "The Fabled Undead Knight", zone = "HC Unrest" },
    },
    TwoGroupRaid = {
        { name = "The Crimson Curse", lockout = "The Crimson Curse", zone = "Chardok" },
        { name = "Crucible of the Brawler", lockout = "Crucible of the Brawler", zone = "Nightveil Sanctum" },
        { name = "Crucible of the Occultist", lockout = "Crucible of the Occultist", zone = "Nightveil Sanctum" },
        { name = "Crucible of the Physician", lockout = "Crucible of the Physician", zone = "Nightveil Sanctum" },
        { name = "Crucible of the Warden", lockout = "Crucible of the Warden", zone = "Nightveil Sanctum" },
        { name = "VP Hardcore", lockout = "VP Hardcore", zone = "Nightveil Sanctum" },
        { name = "Manastone Source", lockout = "Manastone Source", zone = "HC Guk Bottom" },
    },
    Group = {
        { name = "Lucian's Nightmare", lockout = "Lucian's Nightmare", zone = "Nightveil Sanctum" },
        { name = "Venril Sathir", lockout = "Revenge on Venril Sathir", zone = "Karnors Castle" },
        { name = "Fenrir", lockout = "Bloodfang", zone = "West Karana" },
        { name = "Selana", lockout = "Moonshadow", zone = "West Karana" },
        { name = "Finish Them Off", lockout = "Finish them off", zone = "Castle Mistmoore" },
        { name = "Keepsakes", lockout = "Keepsakes", zone = "Surefall Glade" },
        { name = "Ayonae", lockout = "Confront the Maestra", zone = "Surefall Glade" },
        { name = "Howling Stones", lockout = "Echoes of Charasis", zone = "The Overthere" },
        { name = "Doll Maker", lockout = "Doll Maker", zone = "Kithicor Forest" },
    },
    OldRaids = {
        { name = "Trial of Hatred", lockout = "Proving Grounds: The Mastery of Hatred", zone = "MPG" },
        { name = "Trial of Corruption", lockout = "Proving Grounds: The Mastery of Corruption", zone = "MPG" },
        { name = "Trial of Adaptation", lockout = "Proving Grounds: The Mastery of Adaptation", zone = "MPG" },
        { name = "Trial of Specialization", lockout = "Proving Grounds: The Mastery of Specialization", zone = "MPG" },
        { name = "Trial of Foresight", lockout = "Proving Grounds: The Mastery of Foresight", zone = "MPG" },
        { name = "Trial of Endurance", lockout = "Proving Grounds: The Mastery of Endurance", zone = "MPG" },
        { name = "Riftseekers", lockout = "Riftseeker", zone = "Riftseeker" },
        { name = "Tacvi", lockout = "Tunat", zone = "Txevu", index = 3 },
        { name = "Txevu", lockout = "Txevu", zone = "Txevu" },
        { name = "Plane of Time", lockout = "Quarm", zone = "Plane of Time", index = 3 },
    },
}

M.category_order = { "Raid", "TwoGroupRaid", "Group", "OldRaids" }

function M.display_label(entry)
    if not entry then return "?" end
    if entry.label and entry.label ~= "" then return entry.label end
    if entry.zone and entry.zone ~= "" then
        return string.format("%s (%s)", entry.name or "?", entry.zone)
    end
    return tostring(entry.name or "?")
end

return M
