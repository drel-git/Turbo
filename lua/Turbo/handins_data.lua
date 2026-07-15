--[[
  Turbo/handins_data — item tables and NPC map for Turbo/handins.lua
  @version lua/Turbo/handins_data.lua 1.1.0

  Pure data file — no logic, no script-time effects. Edit the lists below
  to add/remove items per server expansion. Per-character exclusions live
  separately in <MQConfig>/Turbo_handins_exclusions_<CharName>.lua and
  do NOT belong here.
]]

return {
  symbolZoneShort    = 'poknowledge',

  zones = { 'TIME', 'TEXVU', 'TACVI' },

  --- PoK symbol exchanger per loot line (edit TACVI if your server uses a different NPC name).
  symbolNpcByZone = {
    TIME  = 'Klorg',
    TEXVU = 'Zenma',
    TACVI = 'Zenma',
  },

  symbolTurnInItems = {
    ['TIME'] = {
      "Songblade of the Eternal", "Ton Po's Mystical Pouch", "Symbol of the Planemasters",
      "Earring of Xaoth Kor", "Ethereal Destroyer", "Faceguard of Frenzy", "Fiery Crystal Guard", "Mask of Strategic Insight", "Pauldrons of Purity", "Timeless Coral Greatsword",
      "Cap of Flowing Time", "Edge of Eternity", "Girdle of Intense Durability", "Gloves of the Unseen", "Ring of Evasion", "Runewarded Belt", "Shroud of Provocation", "Symbol of the Planemasters", "Time's Antithesis", "Veil of Lost Hopes",
      "Amulet of Crystal Dreams", "Band of Prismatic Focus", "Bracer of Precision", "Circlet of Flowing Time", "Cloak of the Falling Skies", "Hopebringer", "Mantle of Deadly Precision", "Serpent of Vindication",
      "Tactician's Shield", "Winged Storm Boots", "Armguards of the Brute", "Cape of Endless Torment", "Coif of Flowing Time", "Cudgel of Venomous Hatred", "Earring of Corporeal Essence", "Hammer of Hours", "Orb of Clinging Death",
      "Talisman of Tainted Energy", "Vanazir, Dreamer's Despair", "Bow of the Tempest", "Cord of Potential", "Earring of Temporal Solstice", "Globe of Mystical Protection", "Hammer of Holy Vengeance", "Helm of Flowing Time",
      "Shinai of the Ancients", "Shoes of Fleeting Fury", "Temporal Chainmail Sleeves", "Wand of Temporal Power", "Belt of Temporal Bindings", "Boots of Despair", "Celestial Cloak", "Collar of Catastrophe", "Eye of Dreams",
      "Greatblade of Chaos", "Leggings of Furious Might", "Pulsing Onyx Ring", "Symbol of Ancient Summoning", "Timespinner, Blade of the Hunter", "Veil of the Inferno",
      "Belt of Tidal Energy", "Cloak of Retribution", "Earring of Unseen Horrors", "Greaves of Furious Might", "Mask of Simplicity", "Padded Tigerskin Gloves", "Staff of Transcendence", "Timestone Adorned Ring",
      "Wand of Impenetrable Force", "Wristband of Echoed Thoughts", "Zealot's Spiked Bracer", "Barrier of Freezing Winds", "Bracer of Timeless Rage", "Earring of Celestial Energy", "Girdle of Stability", "Gloves of Airy Mists",
      "Jagged Timeforged Blade", "Mantle of Pure Spirit", "Necklace of Eternal Visions", "Serrated Dart of Energy", "Shroud of Survival", "Band of Primordial Energy", "Darkblade of the Warlord", "Greatstaff of Power",
      "Pants of Furious Might", "Pauldrons of Devastation", "Platinum Cloak of War", "Ring of Thunderous Forces", "Sandals of Empowerment", "Shield of Strife", "Visor of the Berserker",
      "Bracer of the Inferno", "Cord of Temporal Weavings", "Earring of Influxed Gravity", "Earthen Bracer of Fortitude", "Ethereal Silk Leggings", "Hammer of the Timeweaver", "Prismatic Ring of Resistance", "Shawl of Eternal Forces",
      "Shroud of Eternity", "Silver Hoop of Speed", "Spool of Woven Time", "Stone of Flowing Time", "Talisman of the Elements", "Whorl of Unnatural Forces", "Wristband of Icy Vengeance", "Timeless Breastplate Mold",
      "Timeless Chain Tunic Pattern", "Timeless Leather Tunic Pattern", "Timeless Silk Robe Pattern",
    },
    ['TACVI'] = {
      'Bracer of Grievous Harm', 'Glinting Onyx of Might', 'Glyphed Sandstone of Idealism', 'Ragestone of Hateful Thoughts', 'Shimmering Granite', 'Wristguard of Chaotic Essence', 'Xxeric\'s Battleworn Bracer', 'Xxeric\'s Warbraid',
      'Bulwark of Lost Souls', 'Death\'s Head Mace', 'Vambraces of Eternal Twilight', 'Sleeves of Malefic Rapture', 'Ring of Organic Darkness', 'Golden Idol of Destruction', 'Earring of Pain Deliverance',
      'Aegis of Midnight', 'Armband of Writhing Shadow', 'Tome of Discordant Magic', 'Ruby of Determined Assault', 'Ring of the Serpent', 'Mask of the Void', 'Armguards of Insidious Corruption',
      'Weighted Hammer of Conviction', 'Scepter of Incantations', 'Pauldron of Dark Auspices', 'Luxurious Satin Slippers', 'Girdle of the Zun\'Muram', 'Gauntlets of Malicious Intent', 'Brutish Blade of Balance', 'Bloodstone Blade of the Zun\'Muram',
      'Zun\'Muram\'s Spear of Doom', 'Shroud of the Legion', 'Runed Gauntlets of the Void', 'Nightmarish Boots of Conflict', 'Jagged Axe of Uncontrolled Rage', 'Dagger of Evil Summons', 'Cloak of Nightmarish Visions', 'Blade of Natural Turmoil',
      'Zun\'Muram\'s Scepter of Chaos', 'Supple Slippers of the Stargazer', 'Mindreaper Club', 'Mantle of Corruption', 'Loop of Entropic Hues', 'Kelp-Covered Hammer', 'Hammer of Delusions', 'Gloves of Wicked Ambition',
      'Xxeric\'s Matted-Fur Mask', 'Pendant of Discord', 'Gloves of Coalesced Flame', 'Discordant Dagger of Night', 'Deathblade of the Zun\'Muram', 'Dagger of Death', 'Boots of Captive Screams',
      'Worked Granite of Sundering', 'Tunat\'Muram\'s Chestplate of Agony', 'Tunat\'Muram\'s Chainmail of Pain', 'Tunat\'Muram\'s Bloodied Greaves', 'Solid Stone of the Iron Fist', 'Merciless Enslaver\'s Britches', 'Lightning Prism of Swordplay',
      'Jagged Glowing Prism', 'Greaves of the Tunat\'Muram', 'Greaves of the Dark Ritualist', 'Drape of the Merciless Slaver', 'Dark Tunic of the Enslavers', 'Blade Warstone',
    },
    ['TEXVU'] = {
      'Rapier of Somber Notes',
      'Globe of Dancing Light', 'Azure Trinket of Despair', 'Shroud of Pandemonium', 'Flayed-Skin Spiked Boots', 'Hardened Scale Vambraces', 'Silken Gloves of the Chaos', 'Headband of the Endless Night', 'Lizard Skin Wardrums',
      'Verge of the Mindless Servant', 'Lute of False Worship', 'Caduceus of Retribution', 'Bulwark of Living Stone', 'Barrier of Serenity', 'Bow of the Whispering Wind', 'Jade Effigy of Trushar', 'Staff of Revealed Secrets', 'Ring of Celestial Harmony',
      'Mask of Eternity', 'Staff of Shattered Dreams', 'Scepter of Forbidden Knowledge', 'Earring of the Starless Night', 'Silken Slippers of Discordant Magic', 'Armguards of Envy', 'Suede Gloves of Creation', 'Crown of the Forsaken', 'Bloodfire Cabochon',
      'Chain Wraps of the Dark Master', 'Earring of Incessant Conflict', 'Forlorn Mantle of Shadows', 'Halberd of Endless Pain', 'Shadowy Coif of Condemnation', 'Sleeves of Cognitive Resonance', 'Stained Fur Mask', 'Steel Boots of the Slayer',
      'Carved Bone Gauntlets', 'Cloak of the Penumbra', 'Golden Half Mask of Convalescence', 'Hardened Bone Spike', 'Skullcap of Contemplation', 'Ukun-Hide Armplates of Mortification', 'Woven Chain Boots of Strife', 'Aegis of Discord',
      'Band of Solid Shadow', 'Blackstone Figurine', 'Cape of Woven Steel', 'Edge of Chaos', 'Gem-Studded Band of Struggle', 'Gemstone of Dark Flame', 'Kaftan of Embroidered Light', 'Longsword of Execration',
      'Muramite\'s Heavy Shackles', 'Shroud of Ceaseless Might', 'Spiked Steel Baton', 'Wristband of Chaotic Warfare',
    },
  },

  --- exclusion items
  exclusionCandidates = {
    PLANAR = {
      "Songblade of the Eternal",
      "Ton Po's Mystical Pouch",
      "Symbol of the Planemasters",
    },
    TAELOSIAN = {
      "Rapier of Somber Notes",
      "Worked Granite of Sundering",
    },
  },
}
