-- turbogear/references/don_spell_catalog.lua
-- DoN learned abilities (spells / songs / discs / combat abilities / auras).
-- Each row is one independently tracked BiS requirement.
--
-- Status priority (see don_spells.lua):
--   known -> ready (teaching item) -> pack_owned (container) -> missing
--
-- Excluded until teaching/learned IDs are confirmed:
--   Ancient: Malicious Onslaught, Jolting Thunderkicks
-- Excluded from level-71 list: Battle Focus Discipline (BER 59)

local function ab(opts)
    return {
        display_name = opts[1] or opts.display_name,
        ability_type = opts[2] or opts.ability_type,
        learned_spell_id = opts[3] or opts.learned_spell_id,
        primary_teaching_item_id = opts[4] or opts.primary_teaching_item_id,
        source_type = opts[5] or opts.source_type, -- bundle | standalone
        source_name = opts[6] or opts.source_name,
        source_container_item_id = opts[7] or opts.source_container_item_id,
        required_level = opts[8] or opts.required_level or 71,
        alternate_teaching_item_ids = opts.alts or opts.alternate_teaching_item_ids,
        teaching_item_name = opts.teach_name or opts.teaching_item_name,
    }
end

-- Shorthand: display, type, spell_id, teach_id, source_type, source_name, container, level
local B = function(name, atype, sid, tid, pack, cid, lvl, extra)
    extra = extra or {}
    return ab({
        name, atype, sid, tid, 'bundle', pack, cid, lvl or 71,
        alts = extra.alts,
        teach_name = extra.teach_name,
    })
end

local S = function(name, atype, sid, tid, lvl, extra)
    extra = extra or {}
    return ab({
        name, atype, sid, tid, 'standalone', 'Standalone', nil, lvl or 71,
        alts = extra.alts,
        teach_name = extra.teach_name,
    })
end

return {
    ['Warrior'] = {
        S('Field Conqueror', 'Discipline', 25036, 88919, 71, { teach_name = 'Tome of Field Conqueror' }),
        S('Final Stand Discipline', 'Discipline', 10965, 79302, 71, { teach_name = 'Tome of Final Stand Discipline' }),
        S('Fourth Wind Discipline', 'Discipline', 15134, 80081, 71, { teach_name = 'Tome of Fourth Wind' }),
        S('Jeer', 'Combat Ability', 10848, 88909, 71, { teach_name = 'Tome of Jeer' }),
        S('Maelstrom Blade', 'Combat Ability', 10973, 79310, 71, { teach_name = 'Tome of Maelstrom Blade' }),
        S('Maximum Effort Discipline', 'Discipline', 15104, 80080, 71, { teach_name = 'Tome of Maximum Effort' }),
        S('Roaring Hatred', 'Combat Ability', 19537, 88910, 71, { teach_name = 'Tome of Roaring Hatred' }),
        S("Vanquisher's Aura", 'Aura', 14351, 88925, 71, { teach_name = "Tome of Vanquisher's Aura" }),
    },

    ['Cleric'] = {
        B('Aegis of Vie', 'Spell', 9742, 78079, 'Spell Pack: Aegis of Vie', 82661, 71, { teach_name = 'Spell: Aegis of Vie' }),
        B('Allegiance', 'Spell', 9730, 78067, 'Spell Pack: Allegiance', 82658, 71, { teach_name = 'Spell: Allegiance' }),
        B('Hand of Allegiance', 'Spell', 9809, 78146, 'Spell Pack: Allegiance', 82658, 71, { teach_name = 'Spell: Hand of Allegiance' }),
        B('Symbol of Elushar', 'Spell', 9709, 78046, 'Spell Pack: Allegiance', 82658, 71, { teach_name = 'Spell: Symbol of Elushar' }),
        B('Armor of the Sacred', 'Spell', 9703, 78040, 'Spell Pack: Armor of the Sacred', 82660, 71, { teach_name = 'Spell: Armor of the Sacred' }),
        S('Chromablast', 'Spell', 15140, 80284, 71, { teach_name = 'Spell: Chromablast' }),
        S('Divine Redemption', 'Spell', 25252, 124941, 71, { teach_name = 'Spell: Divine Redemption' }),
        S('Elixir of Redemption', 'Spell', 9812, 78149, 71, { teach_name = 'Spell: Elixir of Redemption' }),
        S('Sound of Zeal', 'Spell', 9749, 78086, 71, { teach_name = 'Spell: Sound of Zeal' }),
        S('Urgent Renewal', 'Spell', 15135, 80282, 71, { teach_name = 'Spell: Urgent Renewal' }),
        S('Vigilant Censure', 'Spell', 15137, 80283, 71, { teach_name = 'Spell: Vigilant Censure' }),
    },

    ['Paladin'] = {
        B('Armor of the Savior', 'Spell', 10197, 78534, 'Spell Pack: Armor of the Savior', 82810, 71, { teach_name = 'Spell: Armor of the Savior' }),
        B('Virtuous Fervor', 'Spell', 10215, 78552, 'Spell Pack: Virtuous Fervor', 82811, 71, { teach_name = 'Spell: Virtuous Fervor' }),
        B('Wave of the Stillmoon', 'Spell', 10206, 78543, 'Spell Pack: Wave of the Stillmoon', 82812, 71, { teach_name = 'Spell: Wave of the Stillmoon' }),
        S('Aegis of Righteousness', 'Discipline', 11854, 79399, 71, { teach_name = 'Tome of Aegis of Righteousness' }),
        S('Benevolent Aura', 'Aura', 15251, 81864, 71, { teach_name = 'Spell: Benevolent Aura' }),
        S("Brell's Unshakable Barricade", 'Spell', 15248, 81862, 71, { teach_name = "Spell: Brell's Unshakable Barricade" }),
        S('Force of the Sacred', 'Spell', 15240, 81861, 71, { teach_name = 'Spell: Force of the Sacred' }),
        S('Force of the Sentinel', 'Spell', 15249, 81863, 71, { teach_name = 'Spell: Force of the Sentinel' }),
        S('The Silent Decree', 'Spell', 10919, 78039, 71, { teach_name = 'Spell: The Silent Decree' }),
    },

    ['Ranger'] = {
        B('Call of Storms', 'Spell', 10134, 78471, 'Spell Pack: Call of Storms', 82815, 71, { teach_name = 'Spell: Call of Storms' }),
        B('Embers of the Delve', 'Spell', 10116, 78453, 'Spell Pack: Flame and Frost', 50150, 71, { teach_name = 'Spell: Embers of the Delve' }),
        B('Frost of the Ascent', 'Spell', 10104, 78441, 'Spell Pack: Flame and Frost', 50150, 71, { teach_name = 'Spell: Frost of the Ascent' }),
        B('Guard of Thundercrest', 'Spell', 15076, 116076, 'Spell Pack: Guard of Thundercrest', 82814, 71, { teach_name = 'Spell: Guard of Thundercrest' }),
        B('Snarl of the Predator', 'Spell', 10113, 78450, 'Spell Pack: Snarl of the Predator', 82813, 71, { teach_name = 'Spell: Snarl of the Predator' }),
        S('Eyes of the Drake', 'Spell', 15255, 81866, 71, { teach_name = 'Spell: Eyes of the Drake' }),
        S('Heartshatter', 'Spell', 15082, 116082, 71, { teach_name = 'Spell: Heartshatter' }),
        S('Swift Salve of the Stillmoon', 'Spell', 15257, 81867, 71, { teach_name = 'Spell: Swift Salve of the Stillmoon' }),
        S('Ward of the Stalker', 'Spell', 15254, 81865, 71, { teach_name = 'Spell: Ward of the Stalker' }),
    },

    ['Shadow Knight'] = {
        B('Cloak of the Corrupter', 'Spell', 10300, 78637, 'Spell Pack: Cloak of the Corrupter', 82807, 71, { teach_name = 'Spell: Cloak of the Corrupter' }),
        B('Shroud of the Accursed', 'Spell', 10251, 78588, 'Spell Pack: Shroud of the Accursed', 82808, 71, { teach_name = 'Spell: Shroud of the Accursed' }),
        B('Theft of Misery', 'Spell', 15073, 71777, 'Spell Pack: Theft of Misery', 82809, 71, { teach_name = 'Spell: Theft of Misery' }),
        S('Blood of the Harbinger', 'Spell', 15233, 80788, 71, { teach_name = 'Spell: Blood of the Harbinger' }),
        S("Grasp of Ju'rek", 'Spell', 10913, 78565, 71, { teach_name = "Spell: Grasp of Ju'rek" }),
        S('Soul Carapace', 'Discipline', 11866, 79408, 71, { teach_name = 'Tome of Soul Carapace' }),
        S("Terror of Lavaspinner's Lair", 'Spell', 10257, 78594, 71, { teach_name = "Spell: Terror of Lavaspinner's Lair" }),
        S('Touch of the Shadows', 'Spell', 15231, 80787, 71, { teach_name = 'Spell: Touch of the Shadows' }),
        S('Voice of Emoush', 'Spell', 15239, 81860, 71, { teach_name = 'Spell: Voice of Emoush' }),
    },

    ['Druid'] = {
        B('Blessing of Moss', 'Spell', 15280, 116280, 'Spell Pack: Clumped Moss', 82777, 71, { teach_name = 'Spell: Blessing of Moss' }),
        B('Mossy Vigor', 'Spell', 15235, 116235, 'Spell Pack: Clumped Moss', 82777, 71, { teach_name = 'Spell: Mossy Vigor' }),
        B('Blessing of Spiritoak', 'Spell', 9929, 78266, 'Spell Pack: Spiritoaks', 82688, 71, { teach_name = 'Spell: Blessing of Spiritoak' }),
        B('Spiritoak Skin', 'Spell', 9872, 78209, 'Spell Pack: Spiritoaks', 82688, 71, { teach_name = 'Spell: Spiritoak Skin' }),
        B("Sun's Blistering Corona", 'Spell', 9824, 78161, "Spell Pack: Sun's Blistering Corona", 82778, 71, { teach_name = "Spell: Sun's Blistering Corona" }),
        S('Ascent Frost', 'Spell', 15153, 80757, 71, { teach_name = 'Spell: Ascent Frost' }),
        S('Breath of the Ascent', 'Spell', 9863, 78200, 71, { teach_name = 'Spell: Breath of the Ascent' }),
        S('Dawnflame', 'Spell', 15156, 80758, 71, { teach_name = 'Spell: Dawnflame' }),
        S('Lunar Shadow', 'Spell', 15165, 80759, 71, { teach_name = 'Spell: Lunar Shadow' }),
        S("Nature Seeker's Behest", 'Spell', 10839, 117592, 71, { teach_name = "Spell: Nature Seeker's Behest" }),
        S("Sunburst Devotion", 'Spell', 15152, 80756, 71, { teach_name = 'Spell: Sunburst Devotion' }),
    },

    ['Monk'] = {
        S('Arcane Reprisal', 'Discipline', 10889, 79226, 71, { teach_name = 'Tome of Arcane Reprisal' }),
        S('Dragondance Discipline', 'Discipline', 15113, 88921, 71, { teach_name = 'Tome of Dragondance Discipline' }),
        S('Fists of Thundercrest', 'Combat Ability', 10854, 50117, 71, { teach_name = 'Tome of Fists of Thundercrest' }),
        S('Fourth Wind Discipline', 'Discipline', 15134, 80081, 71, { teach_name = 'Tome of Fourth Wind' }),
        S("Grandmaster's Aura", 'Aura', 15095, 80078, 71, { teach_name = "Tome of Grandmaster's Aura" }),
        S('Phantom Whispers', 'Combat Ability', 18904, 118654, 71, { teach_name = 'Tome of Phantom Whispers' }),
        S('Stormfist Discipline', 'Discipline', 11923, 79445, 71, { teach_name = 'Tome of Stormfist Discipline' }),
        S('Velocity Focus Discipline', 'Discipline', 15101, 80083, 71, { teach_name = 'Tome of Velocity Focus Discipline' }),
        S('Wheel of Fists', 'Combat Ability', 14797, 88901, 71, { teach_name = 'Tome of Wheel of Fists' }),
    },

    ['Bard'] = {
        B('Cantata of Nife', 'Song', 10948, 50158, 'Spell Pack: Cantata of Nife', 82821, 71, { teach_name = 'Song: Cantata of Nife' }),
        B('Chorus of Nife', 'Song', 10949, 50159, 'Spell Pack: Cantata of Nife', 82821, 71, { teach_name = 'Song: Chorus of Nife' }),
        B('Echoes of the Ancient', 'Song', 15081, 76562, 'Spell Pack: Echoes of the Ancient', 82823, 71, {
            alts = { 81936 },
            teach_name = 'Song: Echoes of the Ancient',
        }),
        B('Symphony of Sound', 'Song', 10936, 50155, 'Spell Pack: Symphony of Sound', 82822, 71, { teach_name = 'Song: Symphony of Sound' }),
        S('Arcane Reprisal', 'Discipline', 10889, 79226, 71, { teach_name = 'Tome of Arcane Reprisal' }),
        S('Endless Blades', 'Discipline', 10939, 50156, 71, { teach_name = 'Tome of Endless Blades' }),
        S("Niv's Symphonic", 'Song', 15264, 81935, 71, { teach_name = "Song: Niv's Symphonic" }),
        S('One Bard Band', 'Song', 35234, 78739, 71, { teach_name = 'Song: One Bard Band' }),
        S('Squall Blade Flourish', 'Combat Ability', 10940, 50157, 71, { teach_name = 'Song: Squall Blade' }),
    },

    ['Rogue'] = {
        S('Arcane Reprisal', 'Discipline', 10889, 79226, 71, { teach_name = 'Tome of Arcane Reprisal' }),
        S('Assailant Discipline', 'Discipline', 15117, 80087, 71, { teach_name = 'Tome of Assailant Discipline' }),
        S('Fourth Wind Discipline', 'Discipline', 15134, 80081, 71, { teach_name = 'Tome of Fourth Wind' }),
        S('Frenetic Stabbing Discipline', 'Discipline', 15119, 80088, 71, { teach_name = 'Tome of Frenetic Stabbing Discipline' }),
        S('Lithe Discipline', 'Discipline', 15102, 80085, 71, { teach_name = 'Tome of Lithe Discipline' }),
        S("Outlaw's Glare", 'Combat Ability', 40294, 88900, 71, { teach_name = "Tome of Outlaw's Glare" }),
        S('Pinpoint Weakness', 'Combat Ability', 15115, 88902, 71, { teach_name = 'Tome of Pinpoint Weakness' }),
        S('Twisted Fortune Discipline', 'Discipline', 10852, 50116, 71, { teach_name = 'Tome of Twisted Fortune Discipline' }),
        S('Vigorous Dagger Throw', 'Combat Ability', 10851, 79236, 71, { teach_name = 'Tome of Vigorous Dagger Throw' }),
    },

    ['Shaman'] = {
        B('Black Scorpion Companion', 'Spell', 10829, 117584, 'Spell Pack: Wild Companions', 50107, 71, { teach_name = 'Spell: Black Scorpion Companion' }),
        B('Blood Raptor Companion', 'Spell', 10832, 117587, 'Spell Pack: Wild Companions', 50107, 71, { teach_name = 'Spell: Blood Raptor Companion' }),
        B('Cunning Lioness Companion', 'Spell', 10823, 117581, 'Spell Pack: Wild Companions', 50107, 71, { teach_name = 'Spell: Cunning Lioness Companion' }),
        B('Gray Elephant Companion', 'Spell', 10824, 117583, 'Spell Pack: Wild Companions', 50107, 71, { teach_name = 'Spell: Gray Elephant Companion' }),
        B('Sea Cow Companion', 'Spell', 10833, 117591, 'Spell Pack: Wild Companions', 50107, 71, { teach_name = 'Spell: Sea Cow Companion' }),
        B('Wooly Rhino Companion', 'Spell', 10830, 117586, 'Spell Pack: Wild Companions', 50107, 71, { teach_name = 'Spell: Wooly Rhino Companion' }),
        B('Blood of Volkara', 'Spell', 10818, 55745, 'Spell Pack: Blood of Volkara', 82663, 71, { teach_name = 'Spell: Blood of Volkara' }),
        B('Stillmoon Focusing', 'Spell', 10005, 78342, 'Spell Pack: Stillmoon Focus', 82662, 71, { teach_name = 'Spell: Stillmoon Focusing' }),
        B('Talisman of the Stillmoon', 'Spell', 10056, 78393, 'Spell Pack: Stillmoon Focus', 82662, 71, { teach_name = 'Spell: Talisman of the Stillmoon' }),
        B('Talisman of Coalescence', 'Spell', 10821, 117580, 'Spell Pack: Talisman of Coalescence', 82664, 71, { teach_name = 'Spell: Talisman of Coalescence' }),
        B('Talisman of the Cougar', 'Spell', 15238, 116238, 'Spell Pack: Talisman of the Cougar', 82665, 71, { teach_name = 'Spell: Talisman of the Cougar' }),
        S('Breath of Shadows', 'Spell', 41232, 80285, 71, { teach_name = 'Spell: Breath of Shadows' }),
        S('Curse of Emoush', 'Spell', 15147, 80288, 71, { teach_name = 'Spell: Curse of Emoush' }),
        S('Shadowy Sloth', 'Spell', 15144, 80287, 71, { teach_name = 'Spell: Shadowy Sloth' }),
        S('Transcendental Torpor', 'Spell', 15141, 80286, 71, { teach_name = 'Spell: Transcendental Torpor' }),
    },

    ['Necromancer'] = {
        B('Dull Agony', 'Spell', 10910, 78814, 'Spell Pack: Dull Agony', 82806, 71, { teach_name = 'Spell: Dull Agony' }),
        B("Goner's Urgent Renewal", 'Spell', 10738, 79075, "Spell Pack: Goner's Urgent Renewal", 82800, 71, { teach_name = "Spell: Goner's Urgent Renewal" }),
        B('Sacrilege of the Wraith', 'Spell', 10476, 78808, 'Spell Pack: Sacrilege of the Wraith', 82805, 71, { teach_name = 'Spell: Sacrilege of the Wraith' }),
        S('Malignant Plague', 'Spell', 15230, 80786, 71, { teach_name = 'Spell: Malignant Plague' }),
        S('Molten Pyre', 'Spell', 15225, 80785, 71, { teach_name = 'Spell: Molten Pyre' }),
        S('Pestilent Pustules', 'Spell', 10906, 119599, 71, { teach_name = 'Spell: Pestilent Pustules' }),
        S('Ritual of Blood', 'Spell', 10482, 78819, 71, { teach_name = 'Spell: Ritual of Blood' }),
        S('Venom of the Accursed Nest', 'Spell', 10555, 78892, 71, { teach_name = 'Spell: Venom of the Accursed Nest' }),
        S('Yearning of Death', 'Spell', 15222, 80784, 71, { teach_name = 'Spell: Yearning of Death' }),
    },

    ['Wizard'] = {
        B('Bolster of the Sorcerer', 'Spell', 10773, 79110, 'Spell Pack: Bolster of the Sorcerer', 82795, 71, { teach_name = 'Spell: Bolster of the Sorcerer' }),
        B('Ethereal Weave', 'Spell', 10861, 79107, 'Spell Pack: Ethereal Weave', 82797, 71, { teach_name = 'Spell: Ethereal Weave' }),
        B('Supernal Skin', 'Spell', 10864, 79201, 'Spell Pack: Supernal Skin', 82796, 71, { teach_name = 'Spell: Supernal Skin' }),
        S('Arcane Sanctuary', 'Spell', 15180, 80763, 71, { teach_name = 'Spell: Arcane Sanctuary' }),
        S('Eruption of Telakemara', 'Spell', 15167, 80760, 71, { teach_name = 'Spell: Eruption of Telakemara' }),
        S('Ether Blaze', 'Spell', 11835, 79388, 71, { teach_name = 'Spell: Ether Blaze' }),
        S("Evoker's Pyromantic Blade", 'Spell', 15168, 80761, 71, { teach_name = "Spell: Evoker's Pyromantic Blade" }),
        S('Serenity Harvest', 'Spell', 10792, 79129, 71, { teach_name = 'Spell: Serenity Harvest' }),
        S('Wildmagic Salvo', 'Spell', 11840, 79390, 71, { teach_name = 'Spell: Wildmagic Salvo' }),
    },

    ['Magician'] = {
        B('Circle of Magmaskin', 'Spell', 10747, 79084, 'Spell Pack: Circle of Magmaskin', 82799, 71, { teach_name = 'Spell: Circle of Magmaskin' }),
        B("Goner's Urgent Renewal", 'Spell', 10738, 79075, "Spell Pack: Goner's Urgent Renewal", 82800, 71, { teach_name = "Spell: Goner's Urgent Renewal" }),
        B('Ward of the Conjurer', 'Spell', 10885, 78038, 'Spell Pack: Ward of the Conjurer', 82798, 71, { teach_name = 'Spell: Ward of the Conjurer' }),
        S('Blade Rend', 'Spell', 15191, 80766, 71, { teach_name = 'Spell: Blade Rend' }),
        S('Burning Bladestorm', 'Spell', 10890, 50144, 71, { teach_name = 'Spell: Burning Bladestorm' }),
        S('Fickle Inferno', 'Spell', 10754, 79091, 71, { teach_name = 'Spell: Fickle Inferno' }),
        S('Frantic Blaze', 'Spell', 15182, 80764, 71, { teach_name = 'Spell: Frantic Blaze' }),
        S('Grant Battle Materiel', 'Spell', 15192, 80779, 71, { teach_name = 'Spell: Grant Battle Materiel' }),
        S('Monolithic Strength', 'Spell', 15188, 80765, 71, { teach_name = 'Spell: Monolithic Strength' }),
    },

    ['Enchanter'] = {
        B('Edict of Tashan', 'Spell', 14515, 115515, 'Spell Pack: Edict of Tashan', 82804, 71, { teach_name = 'Spell: Edict of Tashan' }),
        B('Hastening of Ellowind', 'Spell', 10659, 78996, 'Spell Pack: Ellowind Hastening', 82802, 71, { teach_name = 'Spell: Hastening of Ellowind' }),
        B('Speed of Ellowind', 'Spell', 10602, 78939, 'Spell Pack: Ellowind Hastening', 82802, 71, { teach_name = 'Spell: Speed of Ellowind' }),
        B('Presidio of the Seer', 'Spell', 10583, 78920, 'Spell Pack: Presidio of the Seer', 82803, 71, { teach_name = 'Spell: Presidio of the Seer' }),
        B("Seer's Intuition", 'Spell', 10617, 78954, 'Spell Pack: Intuition', 82801, 71, { teach_name = "Spell: Seer's Intuition" }),
        B('Voice of Intuition', 'Spell', 10662, 78999, 'Spell Pack: Intuition', 82801, 71, { teach_name = 'Spell: Voice of Intuition' }),
        S('Boon of the Sentinel', 'Spell', 10902, 50149, 71, { teach_name = 'Spell: Boon of the Sentinel' }),
        S('Chromatic Chaos', 'Spell', 15212, 80781, 71, { teach_name = 'Spell: Chromatic Chaos' }),
        S('Hysteria', 'Spell', 15216, 80783, 71, { teach_name = 'Spell: Hysteria' }),
        S('Urgent Rune of Destiny', 'Spell', 15213, 80782, 71, { teach_name = 'Spell: Urgent Rune of Destiny' }),
        S('Whispers of Emoush', 'Spell', 10656, 80780, 71, { teach_name = 'Spell: Whispers of Emoush' }),
    },

    ['Beastlord'] = {
        B('Feral Exigency', 'Spell', 14099, 115099, "Spell Pack: Sha's Urgent Renewal", 82820, 71, { teach_name = 'Spell: Feral Exigency' }),
        B("Sha's Urgent Renewal", 'Spell', 14093, 115093, "Spell Pack: Sha's Urgent Renewal", 82820, 71, { teach_name = "Spell: Sha's Urgent Renewal" }),
        B('Growl of the Mountain Puma', 'Spell', 14170, 115170, 'Spell Pack: Growl of the Mountain Puma', 82819, 71, { teach_name = 'Spell: Growl of the Mountain Puma' }),
        B('Roaring Spirit of Tirranun', 'Spell', 10349, 78686, 'Spell Pack: Roaring Spirit of Tirranun', 82818, 71, { teach_name = 'Spell: Roaring Spirit of Tirranun' }),
        B('Spiritual Vibrance', 'Spell', 10339, 78676, 'Spell Pack: Spiritual Vibrance', 82817, 71, { teach_name = 'Spell: Spiritual Vibrance' }),
        S('Feral Mettle', 'Spell', 15261, 81933, 71, { teach_name = 'Spell: Feral Mettle' }),
        S('Ravenous Ice', 'Spell', 15263, 81934, 71, { teach_name = 'Spell: Ravenous Ice' }),
        S('Roaring Sleet', 'Spell', 10364, 78701, 71, { teach_name = 'Spell: Roaring Sleet' }),
        S('Spiritual Enlightenment', 'Spell', 15260, 81868, 71, { teach_name = 'Spell: Spiritual Enlightenment' }),
        S('Swift Salve of the Stillmoon', 'Spell', 15257, 81867, 71, { teach_name = 'Spell: Swift Salve of the Stillmoon' }),
    },

    ['Berserker'] = {
        S('Arcane Reprisal', 'Discipline', 10889, 79226, 71, { teach_name = 'Tome of Arcane Reprisal' }),
        S('Bloodcurdling Scream', 'Combat Ability', 10915, 79251, 71, { teach_name = 'Tome of Bloodcurdling Scream' }),
        S('Cleaving Madness Discipline', 'Discipline', 10860, 50120, 71, { teach_name = 'Tome of Cleaving Madness Discipline' }),
        S('Cry of Catastrophe', 'Combat Ability', 10857, 50118, 71, { teach_name = 'Tome of Cry of Catastrophe' }),
        S('Fourth Wind Discipline', 'Discipline', 15134, 80081, 71, { teach_name = 'Tome of Fourth Wind' }),
        S('Rancorous Flurry Discipline', 'Discipline', 15120, 80280, 71, { teach_name = 'Tome of Rancorous Flurry Discipline' }),
        S('Vigorous Axe Throw', 'Combat Ability', 10858, 50119, 71, { teach_name = 'Tome of Vigorous Axe Throw' }),
        S('Wounding Rage', 'Discipline', 15122, 80281, 71, { teach_name = 'Tome of Wounded Rage Discipline' }),
    },
}
