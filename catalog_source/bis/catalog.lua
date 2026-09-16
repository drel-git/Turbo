-- TurboGear canonical BiS source prototype.
-- Generated for Phase 1A from lua/turbogear/catalogs/lazbis.lua.
-- Edit this developer source in future phases; runtime still loads lua/turbogear/catalogs/lazbis.lua.
return {
  baseline = {
    content_hash = "16:631:2d04d75b_83e36959:114026",
    note = "Phase 1A prototype reconstructed from the shipped TurboGear runtime catalog; do not use ../lazbis/bis.lua as authority.",
    runtime_catalog = "lua/turbogear/catalogs/lazbis.lua",
  },
  builder = {
    aliases_emit_as = "names",
    future_builder = "tools/build_turbogear_catalog.lua",
    ids_are_unordered_by_default = true,
    target_runtime_catalog = "lua/turbogear/catalogs/lazbis.lua",
  },
  default = {
    group = "Raid Best In Slot",
    index = 4,
  },
  groups = {
    {
      lists = {
        {
          id = "preanguish",
          name = "Pre-Anguish",
        },
      },
      name = "Group Best In Slot",
    },
    {
      lists = {
        {
          id = "anguish",
          name = "Anguish",
        },
        {
          id = "fuku",
          name = "FUKU",
        },
        {
          id = "dsk",
          name = "DSK",
        },
        {
          id = "sebilis",
          name = "Sebilis",
        },
        {
          id = "fungal",
          name = "Fungal Aug",
        },
        {
          id = "veksar",
          name = "Veksar",
        },
        {
          id = "don",
          name = "Dragons of Norrath",
        },
      },
      name = "Raid Best In Slot",
    },
    {
      lists = {
        {
          id = "llhcitems",
          name = "Lower Level HC Items",
        },
        {
          id = "hcitems",
          name = "Higher Level HC Items",
        },
        {
          id = "nightveil",
          name = "Nightveil",
        },
        {
          id = "jonas",
          name = "Hand Aug",
        },
        {
          id = "questitems",
          name = "Quest Items",
        },
        {
          id = "vendoritems",
          name = "Vendor Items",
        },
        {
          id = "focusitems",
          name = "Focus Items",
        },
        {
          id = "bagitems",
          name = "Bag Items",
        },
      },
      name = "Other Checklists",
    },
  },
  lists = {
    anguish = {
      categories = {
        {
          name = "Mini Augs",
          slots = {
            "MiniAug1",
            "MiniAug2",
            "MiniAug3",
            "MiniAug4",
            "MiniAug5",
            "MiniAug6",
            "MiniAug7",
            "MiniAug8",
            "MiniAug9",
            "MiniAug10",
            "MiniAug11",
          },
        },
        {
          name = "Visibles",
          slots = {
            "Arms",
            "Chest",
            "Feet",
            "Hands",
            "Head",
            "Legs",
            "Wrists",
          },
        },
        {
          name = "Non-Visibles",
          slots = {
            "Back",
            "Ear1",
            "Ear2",
            "Face",
            "Finger1",
            "Finger2",
            "Neck",
            "Shoulder",
            "Waist",
          },
        },
        {
          name = "Weapons",
          slots = {
            "OffHand(War)",
            "MainHand",
            "Secondary",
            "Ranged",
            "Charm",
            "Aug1",
            "Aug2",
            "Aug3(Pally)",
            "Aug4(SK)",
            "Mask",
          },
        },
        {
          name = "DSK Focus",
          slots = {
            "DSK1",
            "DSK2",
            "DSK3",
            "DSK4",
            "DSK5",
          },
        },
      },
      classes = {
        Bard = {
          Arms = {
            aliases = {
              "Farseeker's Plate Armbands of Harmony",
            },
            ids = {
              70903,
            },
            item = "Farseeker's Plate Armbands of Harmony",
            source = "First Four Names",
          },
          Aug2 = {
            aliases = {
              "Blood-Polished Gemstone",
            },
            ids = {
            },
            item = "Blood-Polished Gemstone",
            source = "Jelvan",
          },
          Back = {
            aliases = {
              "Cloak of Wailing Woes",
            },
            ids = {
              28369,
            },
            item = "Cloak of Wailing Woes",
            source = "Jelvan",
          },
          Chest = {
            aliases = {
              "Farseeker's Plate Chestguard of Harmony",
            },
            ids = {
              70907,
            },
            item = "Farseeker's Plate Chestguard of Harmony",
            source = "AMV or OOM",
          },
          DSK1 = {
            aliases = {
              "Choker of Imprisoned Visions",
            },
            ids = {
              28118,
            },
            item = "Choker of Imprisoned Visions",
            source = "Keldovan",
          },
          DSK2 = {
            aliases = {
              "Plagueborn Cape",
              "Warbeads of the Magus",
            },
            ids = {
              27618,
            },
            item = "Plagueborn Cape",
            source = "OMM",
          },
          DSK3 = {
            aliases = {
              "Earring of Dark Conflict",
            },
            ids = {
              28115,
            },
            item = "Earring of Dark Conflict",
            source = "Jelvan",
          },
          Ear1 = {
            aliases = {
              "Beaded Hoop of Demise",
            },
            ids = {
              27625,
            },
            item = "Beaded Hoop of Demise",
            source = "AMV",
          },
          Ear2 = {
            aliases = {
              "Stud of Chilling Precision",
            },
            ids = {
              27623,
            },
            item = "Stud of Chilling Precision",
            source = "Keldovan",
          },
          Face = {
            aliases = {
              "Mask of Lament",
            },
            ids = {
            },
            item = "Mask of Lament",
            source = "Jelvan",
          },
          Feet = {
            aliases = {
              "Farseeker's Plate Boots of Harmony",
            },
            ids = {
              70906,
            },
            item = "Farseeker's Plate Boots of Harmony",
            source = "First Four Names",
          },
          Finger1 = {
            aliases = {
              "Ring of the Beast",
            },
            ids = {
              28113,
            },
            item = "Ring of the Beast",
            source = "Hanvar",
          },
          Finger2 = {
            aliases = {
              "Rigid Ring of Prowess",
            },
            ids = {
              28120,
            },
            item = "Rigid Ring of Prowess",
            source = "Keldovan",
          },
          Hands = {
            aliases = {
              "Farseeker's Plate Gloves of Harmony",
            },
            ids = {
              70905,
            },
            item = "Farseeker's Plate Gloves of Harmony",
            source = "First Four Names",
          },
          Head = {
            aliases = {
              "Farseeker's Plate Helm of Harmony",
            },
            ids = {
              70902,
            },
            item = "Farseeker's Plate Helm of Harmony",
            source = "First Four Names",
          },
          Legs = {
            aliases = {
              "Farseeker's Plate Legguards of Harmony",
            },
            ids = {
              70908,
            },
            item = "Farseeker's Plate Legguards of Harmony",
            source = "AMV or OOM",
          },
          MainHand = {
            aliases = {
              "Blade of Vesagran",
              "Globe of Discordant Energy",
            },
            ids = {
              40864,
            },
            item = "Blade of Vesagran",
          },
          Mask = {
            aliases = {
              "Mirrored Mask",
            },
            ids = {
            },
            item = "Mirrored Mask",
          },
          Neck = {
            aliases = {
              "Necklace of the Steadfast Spirit",
            },
            ids = {
              47273,
            },
            item = "Necklace of the Steadfast Spirit",
            source = "OMM",
          },
          Ranged = {
            aliases = {
              "Symbol of the Overlord",
            },
            ids = {
              40814,
            },
            item = "Symbol of the Overlord",
            source = "OMM",
          },
          Secondary = {
            aliases = {
              "Mace of Tortured Nightmares",
            },
            ids = {
            },
            item = "Mace of Tortured Nightmares",
            source = "Keldovan",
          },
          Shoulder = {
            aliases = {
              "Shroud of Eternal Agony",
            },
            ids = {
              28119,
            },
            item = "Shroud of Eternal Agony",
            source = "OMM",
          },
          Waist = {
            aliases = {
              "Girdle of the Fleet",
            },
            ids = {
              33030,
            },
            item = "Girdle of the Fleet",
            source = "Jelvan",
          },
          Wrists = {
            aliases = {
              "Farseeker's Plate Wristguard of Harmony",
            },
            ids = {
              70904,
            },
            item = "Farseeker's Plate Wristguard of Harmony",
            source = "First Four Names",
          },
        },
        Beastlord = {
          Arms = {
            aliases = {
              "Savagesoul Sleeves of the Wilds",
            },
            ids = {
              70952,
            },
            item = "Savagesoul Sleeves of the Wilds",
            source = "First Four Names",
          },
          Aug2 = {
            aliases = {
              "Blood-Polished Gemstone",
            },
            ids = {
            },
            item = "Blood-Polished Gemstone",
            source = "Jelvan",
          },
          Back = {
            aliases = {
              "Cloak of Wailing Woes",
            },
            ids = {
              28369,
            },
            item = "Cloak of Wailing Woes",
            source = "Jelvan",
          },
          Chest = {
            aliases = {
              "Savagesoul Jerkin of the Wilds",
            },
            ids = {
              70956,
            },
            item = "Savagesoul Jerkin of the Wilds",
            source = "AMV or OOM",
          },
          DSK1 = {
            aliases = {
              "Belt of Contempt",
            },
            ids = {
              28109,
            },
            item = "Belt of Contempt",
            source = "Ture",
          },
          DSK2 = {
            aliases = {
              "Plagueborn Cape",
              "Warbeads of the Magus",
            },
            ids = {
              27618,
            },
            item = "Plagueborn Cape",
            source = "OMM",
          },
          DSK3 = {
            aliases = {
              "Earring of Dark Conflict",
            },
            ids = {
              28115,
            },
            item = "Earring of Dark Conflict",
            source = "Jelvan",
          },
          Ear1 = {
            aliases = {
              "Beaded Hoop of Demise",
            },
            ids = {
              27625,
            },
            item = "Beaded Hoop of Demise",
            source = "AMV",
          },
          Ear2 = {
            aliases = {
              "Hanvar's Hoop",
            },
            ids = {
            },
            item = "Hanvar's Hoop",
            source = "Ture",
          },
          Face = {
            aliases = {
              "Golem Stone Face Guard",
            },
            ids = {
              28117,
            },
            item = "Golem Stone Face Guard",
            source = "Ture",
          },
          Feet = {
            aliases = {
              "Savagesoul Sandals of the Wilds",
            },
            ids = {
              70955,
            },
            item = "Savagesoul Sandals of the Wilds",
            source = "First Four Names",
          },
          Finger1 = {
            aliases = {
              "Ring of the Beast",
            },
            ids = {
              28113,
            },
            item = "Ring of the Beast",
            source = "Hanvar",
          },
          Finger2 = {
            aliases = {
              "Rigid Ring of Prowess",
            },
            ids = {
              28120,
            },
            item = "Rigid Ring of Prowess",
            source = "Keldovan",
          },
          Hands = {
            aliases = {
              "Savagesoul Gloves of the Wilds",
            },
            ids = {
              70954,
            },
            item = "Savagesoul Gloves of the Wilds",
            source = "First Four Names",
          },
          Head = {
            aliases = {
              "Savagesoul Cap of the Wilds",
            },
            ids = {
              70951,
            },
            item = "Savagesoul Cap of the Wilds",
            source = "First Four Names",
          },
          Legs = {
            aliases = {
              "Savagesoul Legguards of the Wilds",
            },
            ids = {
              70957,
            },
            item = "Savagesoul Legguards of the Wilds",
            source = "AMV or OOM",
          },
          MainHand = {
            aliases = {
              "Spiritcaller Totem of the Feral",
              "Globe of Discordant Energy",
            },
            ids = {
              40866,
            },
            item = "Spiritcaller Totem of the Feral",
          },
          Mask = {
            aliases = {
              "Mirrored Mask",
            },
            ids = {
            },
            item = "Mirrored Mask",
          },
          Neck = {
            aliases = {
              "Necklace of the Steadfast Spirit",
            },
            ids = {
              47273,
            },
            item = "Necklace of the Steadfast Spirit",
            source = "OMM",
          },
          Ranged = {
            aliases = {
              "Symbol of the Overlord",
            },
            ids = {
              40814,
            },
            item = "Symbol of the Overlord",
            source = "OMM",
          },
          Secondary = {
            aliases = {
              "Mace of Grim Tidings",
            },
            ids = {
            },
            item = "Mace of Grim Tidings",
            source = "Hanvar",
          },
          Shoulder = {
            aliases = {
              "Shoulderpads of Warfare",
            },
            ids = {
              28116,
            },
            item = "Shoulderpads of Warfare",
            source = "Hanvar",
          },
          Waist = {
            aliases = {
              "Chains of Anguish",
            },
            ids = {
              27622,
              33030,
            },
            item = "Chains of Anguish",
            source = "OMM",
          },
          Wrists = {
            aliases = {
              "Savagesoul Wristband of the Wilds",
            },
            ids = {
              70953,
            },
            item = "Savagesoul Wristband of the Wilds",
            source = "First Four Names",
          },
        },
        Berserker = {
          Arms = {
            aliases = {
              "Wrathbringer's Chain Sleeves of the Vindicator",
            },
            ids = {
              70959,
            },
            item = "Wrathbringer's Chain Sleeves of the Vindicator",
            source = "First Four Names",
          },
          Aug1 = {
            aliases = {
              "Bone Shard of Wickedness",
            },
            ids = {
            },
            item = "Bone Shard of Wickedness",
            source = "Ture",
          },
          Back = {
            aliases = {
              "Cloak of Wailing Woes",
            },
            ids = {
              28369,
            },
            item = "Cloak of Wailing Woes",
            source = "Jelvan",
          },
          Chest = {
            aliases = {
              "Wrathbringer's Chain Chestguard of the Vindicator",
            },
            ids = {
              70963,
            },
            item = "Wrathbringer's Chain Chestguard of the Vindicator",
            source = "AMV or OOM",
          },
          DSK1 = {
            aliases = {
              "Shroud of Eternal Agony",
            },
            ids = {
              28119,
            },
            item = "Shroud of Eternal Agony",
            source = "OMM",
          },
          DSK2 = {
            aliases = {
              "Choker of Imprisoned Visions",
            },
            ids = {
              28118,
            },
            item = "Choker of Imprisoned Visions",
            source = "Keldovan",
          },
          Ear1 = {
            aliases = {
              "Beaded Hoop of Demise",
            },
            ids = {
              27625,
            },
            item = "Beaded Hoop of Demise",
            source = "AMV",
          },
          Ear2 = {
            aliases = {
              "Hanvar's Hoop",
            },
            ids = {
            },
            item = "Hanvar's Hoop",
            source = "Ture",
          },
          Face = {
            aliases = {
              "Golem Stone Face Guard",
            },
            ids = {
              28117,
            },
            item = "Golem Stone Face Guard",
            source = "Ture",
          },
          Feet = {
            aliases = {
              "Wrathbringer's Chain Boots of the Vindicator",
            },
            ids = {
              70962,
            },
            item = "Wrathbringer's Chain Boots of the Vindicator",
            source = "First Four Names",
          },
          Finger1 = {
            aliases = {
              "Ring of the Beast",
            },
            ids = {
              28113,
            },
            item = "Ring of the Beast",
            source = "Hanvar",
          },
          Finger2 = {
            aliases = {
              "Rigid Ring of Prowess",
            },
            ids = {
              28120,
            },
            item = "Rigid Ring of Prowess",
            source = "Keldovan",
          },
          Hands = {
            aliases = {
              "Wrathbringer's Chain Gloves of the Vindicator",
            },
            ids = {
              70961,
            },
            item = "Wrathbringer's Chain Gloves of the Vindicator",
            source = "First Four Names",
          },
          Head = {
            aliases = {
              "Wrathbringer's Chain Helm of the Vindicator",
            },
            ids = {
              70958,
            },
            item = "Wrathbringer's Chain Helm of the Vindicator",
            source = "First Four Names",
          },
          Legs = {
            aliases = {
              "Wrathbringer's Chain Leggings of the Vindicator",
            },
            ids = {
              70964,
            },
            item = "Wrathbringer's Chain Leggings of the Vindicator",
            source = "AMV or OOM",
          },
          MainHand = {
            aliases = {
              "Vengeful Taelosian Blood Axe",
              "Globe of Discordant Energy",
            },
            ids = {
              40476,
            },
            item = "Vengeful Taelosian Blood Axe",
          },
          Mask = {
            aliases = {
              "Mirrored Mask",
            },
            ids = {
            },
            item = "Mirrored Mask",
          },
          Neck = {
            aliases = {
              "Necklace of the Steadfast Spirit",
            },
            ids = {
              47273,
            },
            item = "Necklace of the Steadfast Spirit",
            source = "OMM",
          },
          Ranged = {
            aliases = {
              "Symbol of the Overlord",
            },
            ids = {
              40814,
            },
            item = "Symbol of the Overlord",
            source = "OMM",
          },
          Shoulder = {
            aliases = {
              "Shoulderpads of Warfare",
            },
            ids = {
              28116,
            },
            item = "Shoulderpads of Warfare",
            source = "Hanvar",
          },
          Waist = {
            aliases = {
              "Girdle of the Fleet",
            },
            ids = {
              33030,
            },
            item = "Girdle of the Fleet",
            source = "Jelvan",
          },
          Wrists = {
            aliases = {
              "Wrathbringer's Chain Wristguard of the Vindicator",
            },
            ids = {
              70960,
            },
            item = "Wrathbringer's Chain Wristguard of the Vindicator",
            source = "First Four Names",
          },
        },
        Cleric = {
          Arms = {
            aliases = {
              "Faithbringer's Armguards of Conviction",
            },
            ids = {
              70861,
            },
            item = "Faithbringer's Armguards of Conviction",
            source = "First Four Names",
          },
          Back = {
            aliases = {
              "Cloak of Regretful Transgressions",
            },
            ids = {
              27624,
              33019,
            },
            item = "Cloak of Regretful Transgressions",
            source = "Hanvar",
          },
          Chest = {
            aliases = {
              "Faithbringer's Breastplate of Conviction",
            },
            ids = {
              70865,
            },
            item = "Faithbringer's Breastplate of Conviction",
            source = "AMV or OOM",
          },
          DSK1 = {
            aliases = {
              "Shroud of the Subjugated Kuuan",
            },
            ids = {
            },
            item = "Shroud of the Subjugated Kuuan",
            source = "Keldovan",
          },
          DSK2 = {
            aliases = {
              "Aegis of the Dragorn Elders",
            },
            ids = {
              28114,
            },
            item = "Aegis of the Dragorn Elders",
            source = "Ture",
          },
          Ear1 = {
            aliases = {
              "Earring of Dragonkin",
            },
            ids = {
              27622,
            },
            item = "Earring of Dragonkin",
            source = "OMM",
          },
          Ear2 = {
            aliases = {
              "Earring of Dark Conflict",
            },
            ids = {
              28115,
            },
            item = "Earring of Dark Conflict",
            source = "Jelvan",
          },
          Face = {
            aliases = {
              "Mask of the Crackling Energy",
            },
            ids = {
            },
            item = "Mask of the Crackling Energy",
            source = "Keldovan",
          },
          Feet = {
            aliases = {
              "Faithbringer's Boots of Conviction",
            },
            ids = {
              70864,
            },
            item = "Faithbringer's Boots of Conviction",
            source = "First Four Names",
          },
          Finger1 = {
            aliases = {
              "Ring of Persecution",
            },
            ids = {
              27621,
            },
            item = "Ring of Persecution",
            source = "OMM",
          },
          Finger2 = {
            aliases = {
              "Ring of Deterrence",
            },
            ids = {
              27622,
            },
            item = "Ring of Deterrence",
            source = "AMV",
          },
          Hands = {
            aliases = {
              "Faithbringer's Gloves of Conviction",
            },
            ids = {
              70863,
            },
            item = "Faithbringer's Gloves of Conviction",
            source = "First Four Names",
          },
          Head = {
            aliases = {
              "Faithbringer's Cap of Conviction",
            },
            ids = {
              70860,
            },
            item = "Faithbringer's Cap of Conviction",
            source = "First Four Names",
          },
          Legs = {
            aliases = {
              "Faithbringer's Leggings of Conviction",
            },
            ids = {
              70866,
            },
            item = "Faithbringer's Leggings of Conviction",
            source = "AMV or OOM",
          },
          MainHand = {
            aliases = {
              "Bazu Claw Hammer",
            },
            ids = {
            },
            item = "Bazu Claw Hammer",
            source = "Jelvan",
          },
          Mask = {
            aliases = {
              "Mirrored Mask",
            },
            ids = {
            },
            item = "Mirrored Mask",
          },
          Neck = {
            aliases = {
              "Warbeads of the Magus",
            },
            ids = {
              47276,
            },
            item = "Warbeads of the Magus",
            source = "AMV",
          },
          Ranged = {
            aliases = {
              "Globe of Voltage",
            },
            ids = {
              28111,
            },
            item = "Globe of Voltage",
            source = "Jelvan",
          },
          Secondary = {
            aliases = {
              "Aegis of Superior Divinity",
              "Globe of Discordant Energy",
            },
            ids = {
              40501,
            },
            item = "Aegis of Superior Divinity",
          },
          Shoulder = {
            aliases = {
              "Amice of Ill-Will",
            },
            ids = {
              28113,
            },
            item = "Amice of Ill-Will",
            source = "AMV",
          },
          Waist = {
            aliases = {
              "Belt of the Stagnant",
            },
            ids = {
              28112,
              33003,
            },
            item = "Belt of the Stagnant",
            source = "Hanvar",
          },
          Wrists = {
            aliases = {
              "Faithbringer's Wristband of Conviction",
            },
            ids = {
              70862,
            },
            item = "Faithbringer's Wristband of Conviction",
            source = "First Four Names",
          },
        },
        Druid = {
          Arms = {
            aliases = {
              "Everspring Sleeves of the Tangled Briars",
            },
            ids = {
              70889,
            },
            item = "Everspring Sleeves of the Tangled Briars",
            source = "First Four Names",
          },
          Back = {
            aliases = {
              "Plagueborn Cape",
            },
            ids = {
              27618,
              33019,
            },
            item = "Plagueborn Cape",
            source = "OMM",
          },
          Chest = {
            aliases = {
              "Everspring Jerkin of the Tangled Briars",
            },
            ids = {
              70893,
            },
            item = "Everspring Jerkin of the Tangled Briars",
            source = "AMV or OOM",
          },
          DSK1 = {
            aliases = {
              "Shroud of Eternal Agony",
            },
            ids = {
              28119,
            },
            item = "Shroud of Eternal Agony",
            source = "OMM",
          },
          DSK2 = {
            aliases = {
              "Earring of Dark Conflict",
            },
            ids = {
              28115,
            },
            item = "Earring of Dark Conflict",
            source = "Jelvan",
          },
          DSK3 = {
            aliases = {
              "Shroud of the Subjugated Kuuan",
            },
            ids = {
            },
            item = "Shroud of the Subjugated Kuuan",
            source = "Keldovan",
          },
          Ear1 = {
            aliases = {
              "Earring of Dragonkin",
            },
            ids = {
              27622,
            },
            item = "Earring of Dragonkin",
            source = "OMM",
          },
          Ear2 = {
            aliases = {
              "Stud of Chilling Precision",
            },
            ids = {
              27623,
            },
            item = "Stud of Chilling Precision",
            source = "Keldovan",
          },
          Face = {
            aliases = {
              "Mask of Forbidden Rites",
            },
            ids = {
            },
            item = "Mask of Forbidden Rites",
            source = "AMV",
          },
          Feet = {
            aliases = {
              "Everspring Slippers of the Tangled Briars",
            },
            ids = {
              70892,
            },
            item = "Everspring Slippers of the Tangled Briars",
            source = "First Four Names",
          },
          Finger1 = {
            aliases = {
              "Ring of Persecution",
            },
            ids = {
              27621,
            },
            item = "Ring of Persecution",
            source = "OMM",
          },
          Finger2 = {
            aliases = {
              "Ring of Deterrence",
            },
            ids = {
              27622,
            },
            item = "Ring of Deterrence",
            source = "AMV",
          },
          Hands = {
            aliases = {
              "Everspring Mitts of the Tangled Briars",
            },
            ids = {
              70891,
            },
            item = "Everspring Mitts of the Tangled Briars",
            source = "First Four Names",
          },
          Head = {
            aliases = {
              "Everspring Cap of the Tangled Briars",
            },
            ids = {
              70888,
            },
            item = "Everspring Cap of the Tangled Briars",
            source = "First Four Names",
          },
          Legs = {
            aliases = {
              "Everspring Pants of the Tangled Briars",
            },
            ids = {
              70894,
            },
            item = "Everspring Pants of the Tangled Briars",
            source = "AMV or OOM",
          },
          MainHand = {
            aliases = {
              "Staff of Everliving Brambles",
              "Globe of Discordant Energy",
            },
            ids = {
              40503,
            },
            item = "Staff of Everliving Brambles",
          },
          Mask = {
            aliases = {
              "Mirrored Mask",
            },
            ids = {
            },
            item = "Mirrored Mask",
          },
          Neck = {
            aliases = {
              "Warbeads of the Magus",
            },
            ids = {
              47276,
            },
            item = "Warbeads of the Magus",
            source = "AMV",
          },
          Ranged = {
            aliases = {
              "Sorrowmourn Gemstone",
            },
            ids = {
            },
            item = "Sorrowmourn Gemstone",
            source = "Jelvan",
          },
          Secondary = {
            aliases = {
              "Aegis of the Dragorn Elders",
            },
            ids = {
            },
            item = "Aegis of the Dragorn Elders",
            source = "Ture",
          },
          Shoulder = {
            aliases = {
              "Amice of Ill-Will",
            },
            ids = {
              28113,
            },
            item = "Amice of Ill-Will",
            source = "AMV",
          },
          Waist = {
            aliases = {
              "Belt of the Stagnant",
            },
            ids = {
              28112,
              33003,
            },
            item = "Belt of the Stagnant",
            source = "Hanvar",
          },
          Wrists = {
            aliases = {
              "Everspring Wristband of the Tangled Briars",
            },
            ids = {
              70890,
            },
            item = "Everspring Wristband of the Tangled Briars",
            source = "First Four Names",
          },
        },
        Enchanter = {
          Arms = {
            aliases = {
              "Mindreaver's Armguards of Coercion",
            },
            ids = {
              70945,
            },
            item = "Mindreaver's Armguards of Coercion",
            source = "First Four Names",
          },
          Back = {
            aliases = {
              "Plagueborn Cape",
            },
            ids = {
              24149,
              27618,
            },
            item = "Plagueborn Cape",
            source = "OMM",
          },
          Chest = {
            aliases = {
              "Mindreaver's Vest of Coercion",
            },
            ids = {
              70949,
            },
            item = "Mindreaver's Vest of Coercion",
            source = "AMV or OOM",
          },
          DSK1 = {
            aliases = {
              "Shroud of Eternal Agony",
            },
            ids = {
              28119,
            },
            item = "Shroud of Eternal Agony",
            source = "OMM",
          },
          DSK2 = {
            aliases = {
              "Shroud of the Subjugated Kuuan",
            },
            ids = {
            },
            item = "Shroud of the Subjugated Kuuan",
            source = "Keldovan",
          },
          Ear1 = {
            aliases = {
              "Earring of Dragonkin",
            },
            ids = {
              27622,
            },
            item = "Earring of Dragonkin",
            source = "OMM",
          },
          Ear2 = {
            aliases = {
              "Earring of Dark Conflict",
            },
            ids = {
              28115,
            },
            item = "Earring of Dark Conflict",
            source = "Jelvan",
          },
          Face = {
            aliases = {
              "Mask of Forbidden Rites",
            },
            ids = {
            },
            item = "Mask of Forbidden Rites",
            source = "AMV",
          },
          Feet = {
            aliases = {
              "Mindreaver's Shoes of Coercion",
            },
            ids = {
              70948,
            },
            item = "Mindreaver's Shoes of Coercion",
            source = "First Four Names",
          },
          Finger1 = {
            aliases = {
              "Ring of Persecution",
            },
            ids = {
              27621,
            },
            item = "Ring of Persecution",
            source = "OMM",
          },
          Finger2 = {
            aliases = {
              "Ring of Deterrence",
            },
            ids = {
              27622,
            },
            item = "Ring of Deterrence",
            source = "AMV",
          },
          Hands = {
            aliases = {
              "Mindreaver's Handguards of Coercion",
            },
            ids = {
              70947,
            },
            item = "Mindreaver's Handguards of Coercion",
            source = "First Four Names",
          },
          Head = {
            aliases = {
              "Mindreaver's Skullcap of Coercion",
            },
            ids = {
              70944,
            },
            item = "Mindreaver's Skullcap of Coercion",
            source = "First Four Names",
          },
          Legs = {
            aliases = {
              "Mindreaver's Leggings of Coercion",
            },
            ids = {
              70950,
            },
            item = "Mindreaver's Leggings of Coercion",
            source = "AMV or OOM",
          },
          MainHand = {
            aliases = {
              "Staff of Eternal Eloquence",
              "Globe of Discordant Energy",
            },
            ids = {
              40861,
            },
            item = "Staff of Eternal Eloquence",
          },
          Mask = {
            aliases = {
              "Mirrored Mask",
            },
            ids = {
            },
            item = "Mirrored Mask",
          },
          Neck = {
            aliases = {
              "Warbeads of the Magus",
            },
            ids = {
              47276,
            },
            item = "Warbeads of the Magus",
            source = "AMV",
          },
          Ranged = {
            aliases = {
              "Sorrowmourn Gemstone",
            },
            ids = {
              28189,
            },
            item = "Sorrowmourn Gemstone",
            source = "Jelvan",
          },
          Secondary = {
            aliases = {
              "Aegis of the Dragorn Elders",
            },
            ids = {
            },
            item = "Aegis of the Dragorn Elders",
            source = "Ture",
          },
          Shoulder = {
            aliases = {
              "Amice of Ill-Will",
            },
            ids = {
              28113,
            },
            item = "Amice of Ill-Will",
            source = "AMV",
          },
          Waist = {
            aliases = {
              "Belt of the Stagnant",
            },
            ids = {
              28112,
              28370,
            },
            item = "Belt of the Stagnant",
            source = "Hanvar",
          },
          Wrists = {
            aliases = {
              "Mindreaver's Bracer of Coercion",
            },
            ids = {
              70946,
            },
            item = "Mindreaver's Bracer of Coercion",
            source = "First Four Names",
          },
        },
        Magician = {
          Arms = {
            aliases = {
              "Glyphwielder's Sleeves of the Summoner",
            },
            ids = {
              70938,
            },
            item = "Glyphwielder's Sleeves of the Summoner",
            source = "First Four Names",
          },
          Back = {
            aliases = {
              "Plagueborn Cape",
            },
            ids = {
              24149,
              27618,
            },
            item = "Plagueborn Cape",
            source = "OMM",
          },
          Chest = {
            aliases = {
              "Glyphwielder's Tunic of the Summoner",
            },
            ids = {
              70942,
            },
            item = "Glyphwielder's Tunic of the Summoner",
            source = "AMV or OOM",
          },
          DSK1 = {
            aliases = {
              "Shroud of Eternal Agony",
            },
            ids = {
              28119,
            },
            item = "Shroud of Eternal Agony",
            source = "OMM",
          },
          DSK2 = {
            aliases = {
              "Shroud of the Subjugated Kuuan",
            },
            ids = {
            },
            item = "Shroud of the Subjugated Kuuan",
            source = "Keldovan",
          },
          Ear1 = {
            aliases = {
              "Earring of Dragonkin",
            },
            ids = {
              27622,
            },
            item = "Earring of Dragonkin",
            source = "OMM",
          },
          Ear2 = {
            aliases = {
              "Stud of Chilling Precision",
            },
            ids = {
              27623,
            },
            item = "Stud of Chilling Precision",
            source = "Keldovan",
          },
          Face = {
            aliases = {
              "Mask of Forbidden Rites",
            },
            ids = {
            },
            item = "Mask of Forbidden Rites",
            source = "AMV",
          },
          Feet = {
            aliases = {
              "Glyphwielder's Slippers of the Summoner",
            },
            ids = {
              70941,
            },
            item = "Glyphwielder's Slippers of the Summoner",
            source = "First Four Names",
          },
          Finger1 = {
            aliases = {
              "Ring of Persecution",
            },
            ids = {
              27621,
            },
            item = "Ring of Persecution",
            source = "OMM",
          },
          Finger2 = {
            aliases = {
              "Ring of Deterrence",
            },
            ids = {
              27622,
            },
            item = "Ring of Deterrence",
            source = "AMV",
          },
          Hands = {
            aliases = {
              "Glyphwielder's Gloves of the Summoner",
            },
            ids = {
              70940,
            },
            item = "Glyphwielder's Gloves of the Summoner",
            source = "First Four Names",
          },
          Head = {
            aliases = {
              "Glyphwielder's Hat of the Summoner",
            },
            ids = {
              70937,
            },
            item = "Glyphwielder's Hat of the Summoner",
            source = "First Four Names",
          },
          Legs = {
            aliases = {
              "Glyphwielder's Leggings of the Summoner",
            },
            ids = {
              70943,
            },
            item = "Glyphwielder's Leggings of the Summoner",
            source = "AMV or OOM",
          },
          MainHand = {
            aliases = {
              "Focus of Primal Elements",
              "Globe of Discordant Energy",
            },
            ids = {
              40865,
            },
            item = "Focus of Primal Elements",
          },
          Mask = {
            aliases = {
              "Mirrored Mask",
            },
            ids = {
            },
            item = "Mirrored Mask",
          },
          Neck = {
            aliases = {
              "Warbeads of the Magus",
            },
            ids = {
              47276,
            },
            item = "Warbeads of the Magus",
            source = "AMV",
          },
          Ranged = {
            aliases = {
              "Sorrowmourn Gemstone",
            },
            ids = {
              28189,
            },
            item = "Sorrowmourn Gemstone",
            source = "Jelvan",
          },
          Secondary = {
            aliases = {
              "Aegis of the Dragorn Elders",
            },
            ids = {
            },
            item = "Aegis of the Dragorn Elders",
            source = "Ture",
          },
          Shoulder = {
            aliases = {
              "Amice of Ill-Will",
            },
            ids = {
              28113,
            },
            item = "Amice of Ill-Will",
            source = "AMV",
          },
          Waist = {
            aliases = {
              "Belt of the Stagnant",
            },
            ids = {
              28112,
              28370,
            },
            item = "Belt of the Stagnant",
            source = "Hanvar",
          },
          Wrists = {
            aliases = {
              "Glyphwielder's Wristband of the Summoner",
            },
            ids = {
              70939,
            },
            item = "Glyphwielder's Wristband of the Summoner",
            source = "First Four Names",
          },
        },
        Monk = {
          Arms = {
            aliases = {
              "Fiercehand Sleeves of the Focused",
            },
            ids = {
              70896,
            },
            item = "Fiercehand Sleeves of the Focused",
            source = "First Four Names",
          },
          Aug1 = {
            aliases = {
              "Bone Shard of Wickedness",
            },
            ids = {
            },
            item = "Bone Shard of Wickedness",
            source = "Ture",
          },
          Aug2 = {
            aliases = {
              "Blood-Polished Gemstone",
            },
            ids = {
            },
            item = "Blood-Polished Gemstone",
            source = "Jelvan",
          },
          Back = {
            aliases = {
              "Cloak of Wailing Woes",
            },
            ids = {
              28369,
            },
            item = "Cloak of Wailing Woes",
            source = "Jelvan",
          },
          Chest = {
            aliases = {
              "Fiercehand Shroud of the Focused",
            },
            ids = {
              70900,
            },
            item = "Fiercehand Shroud of the Focused",
            source = "AMV or OOM",
          },
          Ear1 = {
            aliases = {
              "Beaded Hoop of Demise",
            },
            ids = {
              27625,
            },
            item = "Beaded Hoop of Demise",
            source = "AMV",
          },
          Ear2 = {
            aliases = {
              "Hanvar's Hoop",
            },
            ids = {
            },
            item = "Hanvar's Hoop",
            source = "Ture",
          },
          Face = {
            aliases = {
              "Golem Stone Face Guard",
            },
            ids = {
              28117,
            },
            item = "Golem Stone Face Guard",
            source = "Ture",
          },
          Feet = {
            aliases = {
              "Fiercehand Tabis of the Focused",
            },
            ids = {
              70899,
            },
            item = "Fiercehand Tabis of the Focused",
            source = "First Four Names",
          },
          Finger1 = {
            aliases = {
              "Ring of the Beast",
            },
            ids = {
              28113,
            },
            item = "Ring of the Beast",
            source = "Hanvar",
          },
          Finger2 = {
            aliases = {
              "Rigid Ring of Prowess",
            },
            ids = {
              28120,
            },
            item = "Rigid Ring of Prowess",
            source = "Keldovan",
          },
          Hands = {
            aliases = {
              "Fiercehand Gloves of the Focused",
            },
            ids = {
              70898,
            },
            item = "Fiercehand Gloves of the Focused",
            source = "First Four Names",
          },
          Head = {
            aliases = {
              "Fiercehand Cap of the Focused",
            },
            ids = {
              70895,
            },
            item = "Fiercehand Cap of the Focused",
            source = "First Four Names",
          },
          Legs = {
            aliases = {
              "Fiercehand Leggings of the Focused",
            },
            ids = {
              70901,
            },
            item = "Fiercehand Leggings of the Focused",
            source = "AMV or OOM",
          },
          MainHand = {
            aliases = {
              "Transcended Fistwraps of Immortality",
              "Globe of Discordant Energy",
            },
            ids = {
              40474,
            },
            item = "Transcended Fistwraps of Immortality",
          },
          Mask = {
            aliases = {
              "Mirrored Mask",
            },
            ids = {
            },
            item = "Mirrored Mask",
          },
          Neck = {
            aliases = {
              "Necklace of the Steadfast Spirit",
            },
            ids = {
              47273,
            },
            item = "Necklace of the Steadfast Spirit",
            source = "OMM",
          },
          Ranged = {
            aliases = {
              "Symbol of the Overlord",
            },
            ids = {
              40814,
            },
            item = "Symbol of the Overlord",
            source = "OMM",
          },
          Secondary = {
            aliases = {
              "Flayed Flesh Handwraps",
            },
            ids = {
            },
            item = "Flayed Flesh Handwraps",
            source = "AMV",
          },
          Shoulder = {
            aliases = {
              "Shoulderpads of Warfare",
            },
            ids = {
              28116,
            },
            item = "Shoulderpads of Warfare",
            source = "Hanvar",
          },
          Waist = {
            aliases = {
              "Girdle of the Fleet",
            },
            ids = {
              33030,
            },
            item = "Girdle of the Fleet",
            source = "Jelvan",
          },
          Wrists = {
            aliases = {
              "Fiercehand Wristband of the Focused",
            },
            ids = {
              70897,
            },
            item = "Fiercehand Wristband of the Focused",
            source = "First Four Names",
          },
        },
        Necromancer = {
          Arms = {
            aliases = {
              "Blightbringer's Armband of the Grave",
            },
            ids = {
              70924,
            },
            item = "Blightbringer's Armband of the Grave",
            source = "First Four Names",
          },
          Back = {
            aliases = {
              "Plagueborn Cape",
            },
            ids = {
              24149,
              27618,
            },
            item = "Plagueborn Cape",
            source = "OMM",
          },
          Chest = {
            aliases = {
              "Blightbringer's Tunic of the Grave",
            },
            ids = {
              70928,
            },
            item = "Blightbringer's Tunic of the Grave",
            source = "AMV or OOM",
          },
          DSK1 = {
            aliases = {
              "Shroud of Eternal Agony",
            },
            ids = {
              28119,
            },
            item = "Shroud of Eternal Agony",
            source = "OMM",
          },
          DSK2 = {
            aliases = {
              "Shroud of the Subjugated Kuuan",
            },
            ids = {
            },
            item = "Shroud of the Subjugated Kuuan",
            source = "Keldovan",
          },
          DSK3 = {
            aliases = {
              "Belt of the Stagnant",
            },
            ids = {
              28112,
            },
            item = "Belt of the Stagnant",
            source = "Hanvar",
          },
          DSK4 = {
            aliases = {
              "Stud of Chilling Precision",
            },
            ids = {
              27623,
            },
            item = "Stud of Chilling Precision",
            source = "Keldovan",
          },
          Ear1 = {
            aliases = {
              "Earring of Dragonkin",
            },
            ids = {
              27622,
            },
            item = "Earring of Dragonkin",
            source = "OMM",
          },
          Ear2 = {
            aliases = {
              "Earring of Dark Conflict",
            },
            ids = {
              28115,
            },
            item = "Earring of Dark Conflict",
            source = "Jelvan",
          },
          Face = {
            aliases = {
              "Mask of Forbidden Rites",
            },
            ids = {
            },
            item = "Mask of Forbidden Rites",
            source = "AMV",
          },
          Feet = {
            aliases = {
              "Blightbringer's Sandals of the Grave",
            },
            ids = {
              70927,
            },
            item = "Blightbringer's Sandals of the Grave",
            source = "First Four Names",
          },
          Finger1 = {
            aliases = {
              "Ring of Persecution",
            },
            ids = {
              27621,
            },
            item = "Ring of Persecution",
            source = "OMM",
          },
          Finger2 = {
            aliases = {
              "Ring of Deterrence",
            },
            ids = {
              27622,
            },
            item = "Ring of Deterrence",
            source = "AMV",
          },
          Hands = {
            aliases = {
              "Blightbringer's Handguards of the Grave",
            },
            ids = {
              70926,
            },
            item = "Blightbringer's Handguards of the Grave",
            source = "First Four Names",
          },
          Head = {
            aliases = {
              "Blightbringer's Cap of the Grave",
            },
            ids = {
              70923,
            },
            item = "Blightbringer's Cap of the Grave",
            source = "First Four Names",
          },
          Legs = {
            aliases = {
              "Blightbringer's Pants of the Grave",
            },
            ids = {
              70929,
            },
            item = "Blightbringer's Pants of the Grave",
            source = "AMV or OOM",
          },
          MainHand = {
            aliases = {
              "Deathwhisper",
              "Globe of Discordant Energy",
            },
            ids = {
              40062,
            },
            item = "Deathwhisper",
          },
          Mask = {
            aliases = {
              "Mirrored Mask",
            },
            ids = {
            },
            item = "Mirrored Mask",
          },
          Neck = {
            aliases = {
              "Warbeads of the Magus",
            },
            ids = {
              47276,
            },
            item = "Warbeads of the Magus",
            source = "AMV",
          },
          Ranged = {
            aliases = {
              "Globe of Voltage",
            },
            ids = {
              28111,
            },
            item = "Globe of Voltage",
            source = "Jelvan",
          },
          Secondary = {
            aliases = {
              "Aegis of the Dragorn Elders",
            },
            ids = {
            },
            item = "Aegis of the Dragorn Elders",
            source = "Ture",
          },
          Shoulder = {
            aliases = {
              "Amice of Ill-Will",
            },
            ids = {
              28113,
            },
            item = "Amice of Ill-Will",
            source = "AMV",
          },
          Waist = {
            aliases = {
              "Belt of Contempt",
            },
            ids = {
              28109,
              28370,
            },
            item = "Belt of Contempt",
            source = "Ture",
          },
          Wrists = {
            aliases = {
              "Blightbringer's Bracer of the Grave",
            },
            ids = {
              70925,
            },
            item = "Blightbringer's Bracer of the Grave",
          },
        },
        Paladin = {
          Arms = {
            aliases = {
              "Dawnseeker's Sleeves of the Defender",
            },
            ids = {
              70868,
            },
            item = "Dawnseeker's Sleeves of the Defender",
            source = "First Four Names",
          },
          Aug1 = {
            aliases = {
              "Bone Shard of Wickedness",
            },
            ids = {
            },
            item = "Bone Shard of Wickedness",
            source = "Ture",
          },
          ["Aug3(Pally)"] = {
            aliases = {
              "Blade of Forgotten Faith",
            },
            ids = {
              150283,
            },
            item = "Blade of Forgotten Faith",
            source = "Ture",
          },
          Back = {
            aliases = {
              "Cape of Catastrophe",
            },
            ids = {
              33013,
            },
            item = "Cape of Catastrophe",
            source = "AMV",
          },
          Chest = {
            aliases = {
              "Dawnseeker's Chestpiece of the Defender",
            },
            ids = {
              70872,
            },
            item = "Dawnseeker's Chestpiece of the Defender",
            source = "AMV or OOM",
          },
          DSK1 = {
            aliases = {
              "Shoulderpads of Warfare",
            },
            ids = {
              28116,
            },
            item = "Shoulderpads of Warfare",
            source = "Hanvar",
          },
          DSK2 = {
            aliases = {
              "Golem Stone Face Guard",
            },
            ids = {
              28117,
            },
            item = "Golem Stone Face Guard",
            source = "Ture",
          },
          DSK3 = {
            aliases = {
              "Symbol of the Overlord",
            },
            ids = {
              40814,
            },
            item = "Symbol of the Overlord",
            source = "OMM",
          },
          Ear1 = {
            aliases = {
              "Beaded Hoop of Demise",
            },
            ids = {
              27625,
            },
            item = "Beaded Hoop of Demise",
            source = "AMV",
          },
          Ear2 = {
            aliases = {
              "Hanvar's Hoop",
            },
            ids = {
            },
            item = "Hanvar's Hoop",
            source = "Ture",
          },
          Face = {
            aliases = {
              "Mask of Lament",
            },
            ids = {
            },
            item = "Mask of Lament",
            source = "Jelvan",
          },
          Feet = {
            aliases = {
              "Dawnseeker's Boots of the Defender",
            },
            ids = {
              70871,
            },
            item = "Dawnseeker's Boots of the Defender",
            source = "First Four Names",
          },
          Finger1 = {
            aliases = {
              "Ring of the Beast",
            },
            ids = {
              28113,
            },
            item = "Ring of the Beast",
            source = "Hanvar",
          },
          Finger2 = {
            aliases = {
              "Ring of Deterrence",
            },
            ids = {
            },
            item = "Ring of Deterrence",
            source = "AMV",
          },
          Hands = {
            aliases = {
              "Dawnseeker's Mitts of the Defender",
            },
            ids = {
              70870,
            },
            item = "Dawnseeker's Mitts of the Defender",
            source = "First Four Names",
          },
          Head = {
            aliases = {
              "Dawnseeker's Coif of the Defender",
            },
            ids = {
              70867,
            },
            item = "Dawnseeker's Coif of the Defender",
            source = "First Four Names",
          },
          Legs = {
            aliases = {
              "Dawnseeker's Leggings of the Defender",
            },
            ids = {
              70873,
            },
            item = "Dawnseeker's Leggings of the Defender",
            source = "AMV or OOM",
          },
          MainHand = {
            aliases = {
              "Nightbane, Sword of the Valiant",
              "Globe of Discordant Energy",
            },
            ids = {
              40500,
            },
            item = "Nightbane, Sword of the Valiant",
          },
          Mask = {
            aliases = {
              "Mirrored Mask",
            },
            ids = {
            },
            item = "Mirrored Mask",
          },
          Neck = {
            aliases = {
              "Choker of Imprisoned Visions",
            },
            ids = {
              28118,
            },
            item = "Choker of Imprisoned Visions",
            source = "Keldovan",
          },
          Ranged = {
            aliases = {
              "Totem of the Chimera",
            },
            ids = {
            },
            item = "Totem of the Chimera",
            source = "Hanvar",
          },
          Secondary = {
            aliases = {
              "Shield of the Lightning Lord",
            },
            ids = {
            },
            item = "Shield of the Lightning Lord",
            source = "AMV",
          },
          Shoulder = {
            aliases = {
              "Shroud of Eternal Agony",
            },
            ids = {
              28119,
            },
            item = "Shroud of Eternal Agony",
            source = "OMM",
          },
          Waist = {
            aliases = {
              "Chains of Anguish",
            },
            ids = {
              27622,
              41402,
            },
            item = "Chains of Anguish",
            source = "OMM",
          },
          Wrists = {
            aliases = {
              "Dawnseeker's Wristguard of the Defender",
            },
            ids = {
              70869,
            },
            item = "Dawnseeker's Wristguard of the Defender",
            source = "First Four Names",
          },
        },
        Ranger = {
          Arms = {
            aliases = {
              "Bladewhisper Chain Sleeves of Journeys",
            },
            ids = {
              70875,
            },
            item = "Bladewhisper Chain Sleeves of Journeys",
            source = "First Four Names",
          },
          Aug1 = {
            aliases = {
              "Bone Shard of Wickedness",
            },
            ids = {
            },
            item = "Bone Shard of Wickedness",
            source = "Ture",
          },
          Aug2 = {
            aliases = {
              "Blood-Polished Gemstone",
            },
            ids = {
            },
            item = "Blood-Polished Gemstone",
            source = "Jelvan",
          },
          Back = {
            aliases = {
              "Cape of Catastrophe",
            },
            ids = {
              28369,
            },
            item = "Cape of Catastrophe",
            source = "AMV",
          },
          Chest = {
            aliases = {
              "Bladewhisper Chain Vest of Journeys",
            },
            ids = {
              70879,
            },
            item = "Bladewhisper Chain Vest of Journeys",
            source = "AMV or OOM",
          },
          DSK1 = {
            aliases = {
              "Shroud of Eternal Agony",
            },
            ids = {
              28119,
            },
            item = "Shroud of Eternal Agony",
            source = "OMM",
          },
          DSK2 = {
            aliases = {
              "Earring of Dark Conflict",
            },
            ids = {
              28115,
            },
            item = "Earring of Dark Conflict",
            source = "Jelvan",
          },
          DSK3 = {
            aliases = {
              "Ring of Persecution",
            },
            ids = {
              27621,
            },
            item = "Ring of Persecution",
            source = "OMM",
          },
          DSK4 = {
            aliases = {
              "Plagueborn Cape",
              "Warbeads of the Magus",
            },
            ids = {
              27618,
            },
            item = "Plagueborn Cape",
            source = "OMM",
          },
          DSK5 = {
            aliases = {
              "Stud of Chilling Precision",
            },
            ids = {
              27623,
            },
            item = "Stud of Chilling Precision",
            source = "Keldovan",
          },
          DSK6 = {
            aliases = {
              "Symbol of the Overlord",
            },
            ids = {
              40814,
            },
            item = "Symbol of the Overlord",
            source = "OMM",
          },
          Ear1 = {
            aliases = {
              "Beaded Hoop of Demise",
            },
            ids = {
              27625,
            },
            item = "Beaded Hoop of Demise",
            source = "AMV",
          },
          Ear2 = {
            aliases = {
              "Hanvar's Hoop",
            },
            ids = {
            },
            item = "Hanvar's Hoop",
            source = "Ture",
          },
          Face = {
            aliases = {
              "Golem Stone Face Guard",
            },
            ids = {
              28117,
            },
            item = "Golem Stone Face Guard",
            source = "Ture",
          },
          Feet = {
            aliases = {
              "Bladewhisper Chain Boots of Journeys",
            },
            ids = {
              70878,
            },
            item = "Bladewhisper Chain Boots of Journeys",
            source = "First Four Names",
          },
          Finger1 = {
            aliases = {
              "Ring of the Beast",
            },
            ids = {
              28113,
            },
            item = "Ring of the Beast",
            source = "Hanvar",
          },
          Finger2 = {
            aliases = {
              "Rigid Ring of Prowess",
            },
            ids = {
              28120,
            },
            item = "Rigid Ring of Prowess",
            source = "Keldovan",
          },
          Hands = {
            aliases = {
              "Bladewhisper Chain Gloves of Journeys",
            },
            ids = {
              70877,
            },
            item = "Bladewhisper Chain Gloves of Journeys",
            source = "First Four Names",
          },
          Head = {
            aliases = {
              "Bladewhisper Chain Cap of Journeys",
            },
            ids = {
              70874,
            },
            item = "Bladewhisper Chain Cap of Journeys",
            source = "First Four Names",
          },
          Legs = {
            aliases = {
              "Bladewhisper Chain Legguards of Journeys",
            },
            ids = {
              70880,
            },
            item = "Bladewhisper Chain Legguards of Journeys",
            source = "AMV or OOM",
          },
          MainHand = {
            aliases = {
              "Hammer of Rancorous Thoughts",
            },
            ids = {
              47314,
            },
            item = "Hammer of Rancorous Thoughts",
          },
          Mask = {
            aliases = {
              "Mirrored Mask",
            },
            ids = {
            },
            item = "Mirrored Mask",
          },
          Neck = {
            aliases = {
              "Necklace of the Steadfast Spirit",
            },
            ids = {
              47273,
            },
            item = "Necklace of the Steadfast Spirit",
            source = "OMM",
          },
          Ranged = {
            aliases = {
              "Aurora, the Heartwood Bow",
              "Globe of Discordant Energy",
            },
            ids = {
              40863,
            },
            item = "Aurora, the Heartwood Bow",
          },
          Secondary = {
            aliases = {
              "Shield of the Planar Assassin",
            },
            ids = {
            },
            item = "Shield of the Planar Assassin",
            source = "Hanvar",
          },
          Shoulder = {
            aliases = {
              "Shoulderpads of Warfare",
            },
            ids = {
              28116,
            },
            item = "Shoulderpads of Warfare",
            source = "Hanvar",
          },
          Waist = {
            aliases = {
              "Chains of Anguish",
            },
            ids = {
              27622,
              33030,
            },
            item = "Chains of Anguish",
            source = "OMM",
          },
          Wrists = {
            aliases = {
              "Bladewhisper Chain Wristband of Journeys",
            },
            ids = {
              70876,
            },
            item = "Bladewhisper Chain Wristband of Journeys",
            source = "First Four Names",
          },
        },
        Rogue = {
          Arms = {
            aliases = {
              "Whispering Armguard of Shadows",
            },
            ids = {
              70910,
            },
            item = "Whispering Armguard of Shadows",
            source = "First Four Names",
          },
          Aug2 = {
            aliases = {
              "Blood-Polished Gemstone",
            },
            ids = {
            },
            item = "Blood-Polished Gemstone",
            source = "Jelvan",
          },
          Back = {
            aliases = {
              "Cloak of Wailing Woes",
            },
            ids = {
              28369,
            },
            item = "Cloak of Wailing Woes",
            source = "Jelvan",
          },
          Chest = {
            aliases = {
              "Whispering Tunic of Shadows",
            },
            ids = {
              70914,
            },
            item = "Whispering Tunic of Shadows",
            source = "AMV or OOM",
          },
          DSK1 = {
            aliases = {
              "Choker of Imprisoned Visions",
            },
            ids = {
              28118,
            },
            item = "Choker of Imprisoned Visions",
            source = "Keldovan",
          },
          Ear1 = {
            aliases = {
              "Beaded Hoop of Demise",
            },
            ids = {
              27625,
            },
            item = "Beaded Hoop of Demise",
            source = "AMV",
          },
          Ear2 = {
            aliases = {
              "Hanvar's Hoop",
            },
            ids = {
            },
            item = "Hanvar's Hoop",
            source = "Ture",
          },
          Face = {
            aliases = {
              "Golem Stone Face Guard",
            },
            ids = {
              28117,
            },
            item = "Golem Stone Face Guard",
            source = "Ture",
          },
          Feet = {
            aliases = {
              "Whispering Boots of Shadows",
            },
            ids = {
              70913,
            },
            item = "Whispering Boots of Shadows",
            source = "First Four Names",
          },
          Finger1 = {
            aliases = {
              "Ring of the Beast",
            },
            ids = {
              28113,
            },
            item = "Ring of the Beast",
            source = "Hanvar",
          },
          Finger2 = {
            aliases = {
              "Rigid Ring of Prowess",
            },
            ids = {
              28120,
            },
            item = "Rigid Ring of Prowess",
            source = "Keldovan",
          },
          Hands = {
            aliases = {
              "Whispering Gloves of Shadows",
            },
            ids = {
              70912,
            },
            item = "Whispering Gloves of Shadows",
            source = "First Four Names",
          },
          Head = {
            aliases = {
              "Whispering Hat of Shadows",
            },
            ids = {
              70909,
            },
            item = "Whispering Hat of Shadows",
            source = "First Four Names",
          },
          Legs = {
            aliases = {
              "Whispering Pants of Shadows",
            },
            ids = {
              70915,
            },
            item = "Whispering Pants of Shadows",
            source = "AMV or OOM",
          },
          MainHand = {
            aliases = {
              "Nightshade, Blade of Entropy",
              "Globe of Discordant Energy",
            },
            ids = {
              40475,
            },
            item = "Nightshade, Blade of Entropy",
          },
          Mask = {
            aliases = {
              "Mirrored Mask",
            },
            ids = {
            },
            item = "Mirrored Mask",
          },
          Neck = {
            aliases = {
              "Necklace of the Steadfast Spirit",
            },
            ids = {
              47273,
            },
            item = "Necklace of the Steadfast Spirit",
            source = "OMM",
          },
          Ranged = {
            aliases = {
              "Symbol of the Overlord",
            },
            ids = {
              40814,
            },
            item = "Symbol of the Overlord",
            source = "OMM",
          },
          Secondary = {
            aliases = {
              "Aneuk Dagger of Eye Gouging",
            },
            ids = {
            },
            item = "Aneuk Dagger of Eye Gouging",
            source = "Jelvan",
          },
          Shoulder = {
            aliases = {
              "Shoulderpads of Warfare",
            },
            ids = {
              28116,
            },
            item = "Shoulderpads of Warfare",
            source = "Hanvar",
          },
          Waist = {
            aliases = {
              "Girdle of the Fleet",
            },
            ids = {
              33030,
            },
            item = "Girdle of the Fleet",
            source = "Jelvan",
          },
          Wrists = {
            aliases = {
              "Whispering Bracer of Shadows",
            },
            ids = {
              70911,
            },
            item = "Whispering Bracer of Shadows",
            source = "First Four Names",
          },
        },
        ["Shadow Knight"] = {
          Arms = {
            aliases = {
              "Duskbringer's Plate Armguards of the Hateful",
            },
            ids = {
              70882,
            },
            item = "Duskbringer's Plate Armguards of the Hateful",
            source = "First Four Names",
          },
          Aug1 = {
            aliases = {
              "Bone Shard of Wickedness",
            },
            ids = {
            },
            item = "Bone Shard of Wickedness",
            source = "Ture",
          },
          ["Aug4(SK)"] = {
            aliases = {
              "Morguecaller",
            },
            ids = {
              150282,
            },
            item = "Morguecaller",
            source = "Hanvar",
          },
          Back = {
            aliases = {
              "Cape of Catastrophe",
            },
            ids = {
              33013,
            },
            item = "Cape of Catastrophe",
            source = "AMV",
          },
          Chest = {
            aliases = {
              "Duskbringer's Plate Chestguard of the Hateful",
            },
            ids = {
              70886,
            },
            item = "Duskbringer's Plate Chestguard of the Hateful",
            source = "AMV or OOM",
          },
          DSK1 = {
            aliases = {
              "Shoulderpads of Warfare",
            },
            ids = {
              28116,
            },
            item = "Shoulderpads of Warfare",
            source = "Hanvar",
          },
          DSK2 = {
            aliases = {
              "Golem Stone Face Guard",
            },
            ids = {
              28117,
            },
            item = "Golem Stone Face Guard",
            source = "Ture",
          },
          DSK3 = {
            aliases = {
              "Symbol of the Overlord",
            },
            ids = {
              40814,
            },
            item = "Symbol of the Overlord",
            source = "OMM",
          },
          Ear1 = {
            aliases = {
              "Beaded Hoop of Demise",
            },
            ids = {
              27625,
            },
            item = "Beaded Hoop of Demise",
            source = "AMV",
          },
          Ear2 = {
            aliases = {
              "Hanvar's Hoop",
            },
            ids = {
            },
            item = "Hanvar's Hoop",
            source = "Ture",
          },
          Face = {
            aliases = {
              "Mask of Lament",
            },
            ids = {
            },
            item = "Mask of Lament",
            source = "Jelvan",
          },
          Feet = {
            aliases = {
              "Duskbringer's Plate Boots of the Hateful",
            },
            ids = {
              70885,
            },
            item = "Duskbringer's Plate Boots of the Hateful",
            source = "First Four Names",
          },
          Finger1 = {
            aliases = {
              "Ring of the Beast",
            },
            ids = {
              28113,
            },
            item = "Ring of the Beast",
            source = "Hanvar",
          },
          Finger2 = {
            aliases = {
              "Ring of Persecution",
            },
            ids = {
              27621,
            },
            item = "Ring of Persecution",
            source = "OMM",
          },
          Hands = {
            aliases = {
              "Duskbringer's Plate Gloves of the Hateful",
            },
            ids = {
              70884,
            },
            item = "Duskbringer's Plate Gloves of the Hateful",
            source = "First Four Names",
          },
          Head = {
            aliases = {
              "Duskbringer's Plate Helm of the Hateful",
            },
            ids = {
              70881,
            },
            item = "Duskbringer's Plate Helm of the Hateful",
            source = "First Four Names",
          },
          Legs = {
            aliases = {
              "Duskbringer's Plate Legguards of the Hateful",
            },
            ids = {
              70887,
            },
            item = "Duskbringer's Plate Legguards of the Hateful",
            source = "AMV or OOM",
          },
          MainHand = {
            aliases = {
              "Innoruuk's Dark Blessing",
              "Globe of Discordant Energy",
            },
            ids = {
              40477,
            },
            item = "Innoruuk's Dark Blessing",
          },
          Mask = {
            aliases = {
              "Mirrored Mask",
            },
            ids = {
            },
            item = "Mirrored Mask",
          },
          Neck = {
            aliases = {
              "Choker of Imprisoned Visions",
            },
            ids = {
              28118,
            },
            item = "Choker of Imprisoned Visions",
            source = "Keldovan",
          },
          Ranged = {
            aliases = {
              "Totem of the Chimera",
            },
            ids = {
            },
            item = "Totem of the Chimera",
            source = "Hanvar",
          },
          Secondary = {
            aliases = {
              "Shield of the Lightning Lord",
            },
            ids = {
            },
            item = "Shield of the Lightning Lord",
            source = "AMV",
          },
          Shoulder = {
            aliases = {
              "Shroud of Eternal Agony",
            },
            ids = {
              28119,
            },
            item = "Shroud of Eternal Agony",
            source = "OMM",
          },
          Waist = {
            aliases = {
              "Chains of Anguish",
            },
            ids = {
              27622,
              41402,
            },
            item = "Chains of Anguish",
            source = "OMM",
          },
          Wrists = {
            aliases = {
              "Duskbringer's Plate Wristguard of the Hateful",
            },
            ids = {
              70883,
            },
            item = "Duskbringer's Plate Wristguard of the Hateful",
            source = "First Four Names",
          },
        },
        Shaman = {
          Arms = {
            aliases = {
              "Ritualchanter's Armguards of the Ancestors",
            },
            ids = {
              70917,
            },
            item = "Ritualchanter's Armguards of the Ancestors",
            source = "First Four Names",
          },
          Back = {
            aliases = {
              "Plagueborn Cape",
            },
            ids = {
              27618,
              33019,
            },
            item = "Plagueborn Cape",
            source = "OMM",
          },
          Chest = {
            aliases = {
              "Ritualchanter's Tunic of the Ancestors",
            },
            ids = {
              70921,
            },
            item = "Ritualchanter's Tunic of the Ancestors",
            source = "AMV or OOM",
          },
          DSK1 = {
            aliases = {
              "Shroud of Eternal Agony",
            },
            ids = {
              28119,
            },
            item = "Shroud of Eternal Agony",
            source = "OMM",
          },
          DSK2 = {
            aliases = {
              "Shroud of the Subjugated Kuuan",
            },
            ids = {
            },
            item = "Shroud of the Subjugated Kuuan",
            source = "Keldovan",
          },
          DSK3 = {
            aliases = {
              "Belt of the Stagnant",
            },
            ids = {
              28112,
            },
            item = "Belt of the Stagnant",
            source = "Hanvar",
          },
          Ear1 = {
            aliases = {
              "Earring of Dragonkin",
            },
            ids = {
              27622,
            },
            item = "Earring of Dragonkin",
            source = "OMM",
          },
          Ear2 = {
            aliases = {
              "Earring of Dark Conflict",
            },
            ids = {
              28115,
            },
            item = "Earring of Dark Conflict",
            source = "Jelvan",
          },
          Face = {
            aliases = {
              "Mask of Forbidden Rites",
            },
            ids = {
            },
            item = "Mask of Forbidden Rites",
            source = "AMV",
          },
          Feet = {
            aliases = {
              "Ritualchanter's Boots of the Ancestors",
            },
            ids = {
              70920,
            },
            item = "Ritualchanter's Boots of the Ancestors",
            source = "First Four Names",
          },
          Finger1 = {
            aliases = {
              "Ring of Persecution",
            },
            ids = {
              27621,
            },
            item = "Ring of Persecution",
            source = "OMM",
          },
          Finger2 = {
            aliases = {
              "Ring of Deterrence",
            },
            ids = {
              27622,
            },
            item = "Ring of Deterrence",
            source = "AMV",
          },
          Hands = {
            aliases = {
              "Ritualchanter's Mitts of the Ancestors",
            },
            ids = {
              70919,
            },
            item = "Ritualchanter's Mitts of the Ancestors",
            source = "First Four Names",
          },
          Head = {
            aliases = {
              "Ritualchanter's Cap of the Ancestors",
            },
            ids = {
              70916,
            },
            item = "Ritualchanter's Cap of the Ancestors",
            source = "First Four Names",
          },
          Legs = {
            aliases = {
              "Ritualchanter's Leggings of the Ancestors",
            },
            ids = {
              70922,
            },
            item = "Ritualchanter's Leggings of the Ancestors",
            source = "AMV or OOM",
          },
          MainHand = {
            aliases = {
              "Blessed Spiritstaff of the Heyokah",
              "Globe of Discordant Energy",
            },
            ids = {
              40502,
            },
            item = "Blessed Spiritstaff of the Heyokah",
          },
          Mask = {
            aliases = {
              "Mirrored Mask",
            },
            ids = {
            },
            item = "Mirrored Mask",
          },
          Neck = {
            aliases = {
              "Warbeads of the Magus",
            },
            ids = {
              47276,
            },
            item = "Warbeads of the Magus",
            source = "AMV",
          },
          Ranged = {
            aliases = {
              "Globe of Voltage",
            },
            ids = {
              28111,
            },
            item = "Globe of Voltage",
            source = "Jelvan",
          },
          Secondary = {
            aliases = {
              "Aegis of the Dragorn Elders",
            },
            ids = {
            },
            item = "Aegis of the Dragorn Elders",
            source = "Ture",
          },
          Shoulder = {
            aliases = {
              "Amice of Ill-Will",
            },
            ids = {
              28113,
            },
            item = "Amice of Ill-Will",
            source = "AMV",
          },
          Waist = {
            aliases = {
              "Belt of Contempt",
            },
            ids = {
              28109,
              33003,
            },
            item = "Belt of Contempt",
            source = "Ture",
          },
          Wrists = {
            aliases = {
              "Ritualchanter's Wristband of the Ancestors",
            },
            ids = {
              70918,
            },
            item = "Ritualchanter's Wristband of the Ancestors",
            source = "First Four Names",
          },
        },
        Warrior = {
          Arms = {
            aliases = {
              "Gladiator's Plate Sleeves of War",
            },
            ids = {
              70854,
            },
            item = "Gladiator's Plate Sleeves of War",
            source = "First Four Names",
          },
          Aug1 = {
            aliases = {
              "Bone Shard of Wickedness",
            },
            ids = {
            },
            item = "Bone Shard of Wickedness",
            source = "Ture",
          },
          Aug2 = {
            aliases = {
              "Blood-Polished Gemstone",
            },
            ids = {
            },
            item = "Blood-Polished Gemstone",
            source = "Jelvan",
          },
          Back = {
            aliases = {
              "Cape of Catastrophe",
            },
            ids = {
              33013,
            },
            item = "Cape of Catastrophe",
            source = "AMV",
          },
          Chest = {
            aliases = {
              "Gladiator's Plate Chestguard of War",
            },
            ids = {
              70858,
            },
            item = "Gladiator's Plate Chestguard of War",
            source = "AMV or OOM",
          },
          DSK1 = {
            aliases = {
              "Shoulderpads of Warfare",
            },
            ids = {
              28116,
            },
            item = "Shoulderpads of Warfare",
            source = "Hanvar",
          },
          DSK2 = {
            aliases = {
              "Stud of Chilling Precision",
            },
            ids = {
              27623,
            },
            item = "Stud of Chilling Precision",
            source = "Keldovan",
          },
          DSK3 = {
            aliases = {
              "Symbol of the Overlord",
            },
            ids = {
              40814,
            },
            item = "Symbol of the Overlord",
            source = "OMM",
          },
          Ear1 = {
            aliases = {
              "Beaded Hoop of Demise",
            },
            ids = {
              27625,
            },
            item = "Beaded Hoop of Demise",
            source = "AMV",
          },
          Ear2 = {
            aliases = {
              "Hanvar's Hoop",
            },
            ids = {
            },
            item = "Hanvar's Hoop",
            source = "Ture",
          },
          Face = {
            aliases = {
              "Mask of Lament",
            },
            ids = {
            },
            item = "Mask of Lament",
            source = "Jelvan",
          },
          Feet = {
            aliases = {
              "Gladiator's Plate Boots of War",
            },
            ids = {
              70857,
            },
            item = "Gladiator's Plate Boots of War",
            source = "First Four Names",
          },
          Finger1 = {
            aliases = {
              "Ring of the Beast",
            },
            ids = {
              28113,
            },
            item = "Ring of the Beast",
            source = "Hanvar",
          },
          Finger2 = {
            aliases = {
              "Rigid Ring of Prowess",
            },
            ids = {
              28120,
            },
            item = "Rigid Ring of Prowess",
            source = "Keldovan",
          },
          Hands = {
            aliases = {
              "Gladiator's Plate Gloves of War",
            },
            ids = {
              70856,
            },
            item = "Gladiator's Plate Gloves of War",
            source = "First Four Names",
          },
          Head = {
            aliases = {
              "Gladiator's Plate Helm of War",
            },
            ids = {
              70853,
            },
            item = "Gladiator's Plate Helm of War",
            source = "First Four Names",
          },
          Legs = {
            aliases = {
              "Gladiator's Plate Legguards of War",
            },
            ids = {
              70859,
            },
            item = "Gladiator's Plate Legguards of War",
            source = "AMV or OOM",
          },
          MainHand = {
            aliases = {
              "Kreljnok's Sword of Eternal Power",
              "Globe of Discordant Energy",
            },
            ids = {
              40473,
            },
            item = "Kreljnok's Sword of Eternal Power",
          },
          Mask = {
            aliases = {
              "Mirrored Mask",
            },
            ids = {
            },
            item = "Mirrored Mask",
          },
          Neck = {
            aliases = {
              "Choker of Imprisoned Visions",
            },
            ids = {
              28118,
            },
            item = "Choker of Imprisoned Visions",
            source = "Keldovan",
          },
          ["OffHand(War)"] = {
            aliases = {
              "Ruinous Razor-edged ShanTok",
            },
            ids = {
            },
            item = "Ruinous Razor-edged ShanTok",
          },
          Ranged = {
            aliases = {
              "Totem of the Chimera",
            },
            ids = {
              28361,
            },
            item = "Totem of the Chimera",
            source = "Hanvar",
          },
          Secondary = {
            aliases = {
              "Shield of the Lightning Lord",
            },
            ids = {
              28366,
            },
            item = "Shield of the Lightning Lord",
            source = "AMV",
          },
          Shoulder = {
            aliases = {
              "Shroud of Eternal Agony",
            },
            ids = {
              28119,
            },
            item = "Shroud of Eternal Agony",
            source = "OMM",
          },
          Waist = {
            aliases = {
              "Chains of Anguish",
            },
            ids = {
              27622,
              41402,
            },
            item = "Chains of Anguish",
            source = "OMM",
          },
          Wrists = {
            aliases = {
              "Gladiator's Plate Bracer of War",
            },
            ids = {
              70855,
            },
            item = "Gladiator's Plate Bracer of War",
            source = "First Four Names",
          },
        },
        Wizard = {
          Arms = {
            aliases = {
              "Academic's Sleeves of the Arcanists",
            },
            ids = {
              70931,
            },
            item = "Academic's Sleeves of the Arcanists",
            source = "First Four Names",
          },
          Back = {
            aliases = {
              "Plagueborn Cape",
            },
            ids = {
              24149,
              27618,
            },
            item = "Plagueborn Cape",
            source = "OMM",
          },
          Chest = {
            aliases = {
              "Academic's Robe of the Arcanists",
            },
            ids = {
              70935,
            },
            item = "Academic's Robe of the Arcanists",
            source = "AMV or OOM",
          },
          DSK1 = {
            aliases = {
              "Shroud of Eternal Agony",
            },
            ids = {
              28119,
            },
            item = "Shroud of Eternal Agony",
            source = "OMM",
          },
          DSK2 = {
            aliases = {
              "Shroud of the Subjugated Kuuan",
            },
            ids = {
            },
            item = "Shroud of the Subjugated Kuuan",
            source = "Keldovan",
          },
          Ear1 = {
            aliases = {
              "Earring of Dragonkin",
            },
            ids = {
              27622,
            },
            item = "Earring of Dragonkin",
            source = "OMM",
          },
          Ear2 = {
            aliases = {
              "Stud of Chilling Precision",
            },
            ids = {
              27623,
            },
            item = "Stud of Chilling Precision",
            source = "Keldovan",
          },
          Face = {
            aliases = {
              "Mask of Forbidden Rites",
            },
            ids = {
            },
            item = "Mask of Forbidden Rites",
            source = "AMV",
          },
          Feet = {
            aliases = {
              "Academic's Slippers of the Arcanists",
            },
            ids = {
              70934,
            },
            item = "Academic's Slippers of the Arcanists",
            source = "First Four Names",
          },
          Finger1 = {
            aliases = {
              "Ring of Persecution",
            },
            ids = {
              27621,
            },
            item = "Ring of Persecution",
            source = "OMM",
          },
          Finger2 = {
            aliases = {
              "Ring of Deterrence",
            },
            ids = {
              27622,
            },
            item = "Ring of Deterrence",
            source = "AMV",
          },
          Hands = {
            aliases = {
              "Academic's Gloves of the Arcanists",
            },
            ids = {
              70933,
            },
            item = "Academic's Gloves of the Arcanists",
            source = "First Four Names",
          },
          Head = {
            aliases = {
              "Academic's Cap of the Arcanists",
            },
            ids = {
              70930,
            },
            item = "Academic's Cap of the Arcanists",
            source = "First Four Names",
          },
          Legs = {
            aliases = {
              "Academic's Pants of the Arcanists",
            },
            ids = {
              70936,
            },
            item = "Academic's Pants of the Arcanists",
            source = "AMV or OOM",
          },
          MainHand = {
            aliases = {
              "Staff of Phenomenal Power",
              "Globe of Discordant Energy",
            },
            ids = {
              40860,
            },
            item = "Staff of Phenomenal Power",
          },
          Mask = {
            aliases = {
              "Mirrored Mask",
            },
            ids = {
            },
            item = "Mirrored Mask",
          },
          Neck = {
            aliases = {
              "Warbeads of the Magus",
            },
            ids = {
              47276,
            },
            item = "Warbeads of the Magus",
            source = "AMV",
          },
          Ranged = {
            aliases = {
              "Sorrowmourn Gemstone",
            },
            ids = {
              28189,
            },
            item = "Sorrowmourn Gemstone",
            source = "Jelvan",
          },
          Secondary = {
            aliases = {
              "Aegis of the Dragorn Elders",
            },
            ids = {
            },
            item = "Aegis of the Dragorn Elders",
            source = "Ture",
          },
          Shoulder = {
            aliases = {
              "Amice of Ill-Will",
            },
            ids = {
              28113,
            },
            item = "Amice of Ill-Will",
            source = "AMV",
          },
          Waist = {
            aliases = {
              "Belt of the Stagnant",
            },
            ids = {
              28112,
              28370,
            },
            item = "Belt of the Stagnant",
            source = "Hanvar",
          },
          Wrists = {
            aliases = {
              "Academic's Wristband of the Arcanists",
            },
            ids = {
              70932,
            },
            item = "Academic's Wristband of the Arcanists",
            source = "First Four Names",
          },
        },
      },
      group = "Raid Best In Slot",
      id = "anguish",
      name = "Anguish",
      show_base = {
        DSK1 = 1,
        DSK2 = 1,
        DSK3 = 1,
        DSK4 = 1,
        DSK5 = 1,
      },
      template = {
        Charm = {
          aliases = {
            "Overlord's Prized Trinket",
          },
          ids = {
            41400,
          },
          item = "Overlord's Prized Trinket",
          source = "OMM",
        },
        MiniAug1 = {
          aliases = {
            "Abhorrent Brimstone of Charring",
          },
          ids = {
            150343,
            150355,
          },
          item = "Abhorrent Brimstone of Charring",
        },
        MiniAug10 = {
          aliases = {
            "Stone of Horrid Transformation",
          },
          ids = {
            150353,
            150364,
          },
          item = "Stone of Horrid Transformation",
        },
        MiniAug11 = {
          aliases = {
            "Stone of Planar Protection",
          },
          ids = {
            150354,
            150365,
          },
          item = "Stone of Planar Protection",
        },
        MiniAug2 = {
          aliases = {
            "Gem of Unnatural Resilience",
          },
          ids = {
            150344,
            150356,
          },
          item = "Gem of Unnatural Resilience",
        },
        MiniAug3 = {
          aliases = {
            "Kyv Eye of Marksmanship",
          },
          ids = {
            150346,
            150357,
          },
          item = "Kyv Eye of Marksmanship",
        },
        MiniAug4 = {
          aliases = {
            "Orb of Forbidden Laughter",
          },
          ids = {
            150347,
            150358,
          },
          item = "Orb of Forbidden Laughter",
        },
        MiniAug5 = {
          aliases = {
            "Petrified Girplan Heart",
          },
          ids = {
            150348,
            150359,
          },
          item = "Petrified Girplan Heart",
        },
        MiniAug6 = {
          aliases = {
            "Rune of Astral Celerity",
          },
          ids = {
            150349,
            150360,
          },
          item = "Rune of Astral Celerity",
        },
        MiniAug7 = {
          aliases = {
            "Rune of Futile Resolutions",
          },
          ids = {
            150350,
            150361,
          },
          item = "Rune of Futile Resolutions",
        },
        MiniAug8 = {
          aliases = {
            "Rune of Grim Portents",
          },
          ids = {
            150351,
            150362,
          },
          item = "Rune of Grim Portents",
        },
        MiniAug9 = {
          aliases = {
            "Rune of Living Lightning",
          },
          ids = {
            150352,
            150363,
          },
          item = "Rune of Living Lightning",
        },
      },
      visible = {
        Any = {
          aliases = {
            "Fragmented Deific Insignia",
          },
          ids = {
          },
          item = "Fragmented Deific Insignia",
        },
        Arms = {
          aliases = {
            "Lenarsk's Embossed Leather Pouch",
          },
          ids = {
          },
          item = "Lenarsk's Embossed Leather Pouch",
        },
        Chest = {
          aliases = {
            "Jayruk's Vest",
          },
          ids = {
          },
          item = "Jayruk's Vest",
        },
        Feet = {
          aliases = {
            "Muramite Cruelty Medal",
          },
          ids = {
          },
          item = "Muramite Cruelty Medal",
        },
        Hands = {
          aliases = {
            "Makyah's Axe",
          },
          ids = {
          },
          item = "Makyah's Axe",
        },
        Head = {
          aliases = {
            "Patorav's Walking Stick",
          },
          ids = {
          },
          item = "Patorav's Walking Stick",
        },
        Legs = {
          aliases = {
            "Patorav's Amulet",
          },
          ids = {
          },
          item = "Patorav's Amulet",
        },
        Wrist1 = {
          aliases = {
            "Riftseeker Heart",
          },
          ids = {
          },
          item = "Riftseeker Heart",
        },
        Wrist2 = {
          aliases = {
            "Riftseeker Heart",
          },
          ids = {
          },
          item = "Riftseeker Heart",
        },
      },
    },
    bagitems = {
      categories = {
        {
          name = "HC Bag",
          slots = {
            "Adventurer's Tattered Sack (Base) (T1 Named)",
            "Reinforced Stitching Frame (T2 Trash)",
            "Adventurer's Tattered Sack (Reinforced) (UP1)",
            "Treated Expedition Straps (T3 Trash)",
            "Adventurer's Tattered Sack (Bound) (UP2)",
            "Arcwoven Binding Thread (T4 Trash)",
            "Adventurer's Tattered Sack (Arcwoven) (UP3)",
            "Master Tailor's Celestial Lining (T5 Trash)",
            "Adventurer's Tattered Sack (Celestial)",
          },
        },
        {
          name = "CC Bag (Djinn Lamp world drops)",
          slots = {
            "Celestial Strongbox (CC) (Base)",
            "Celestial Blessing of the Djinn (UPG ITM)",
            "Blessed Celestial Strongbox (UP1)",
            "Blessed Celestial Strongbox (UP2)",
            "Blessed Celestial Strongbox (UP3)",
            "Blessed Celestial Strongbox (UP4)",
            "Blessed Celestial Strongbox (UP5)",
            "Blessed Celestial Strongbox (UP6)",
            "Blessed Celestial Strongbox (UP7)",
            "Blessed Celestial Strongbox (UP8)",
            "Blessed Celestial Strongbox (UP9)",
            "Hallowed Celestial Strongbox (UP^)",
          },
        },
        {
          name = "VP Bag (Draconic Binding from Shady)",
          slots = {
            "Chromatic Dragonhide Satchel (Base)",
            "Draconic Binding Thread (UPG ITM)",
            "Reinforced Dragonhide Satchel (UP1)",
            "Scaled Dragonhide Satchel (UP2)",
            "Elder Dragonhide Satchel (UP3)",
            "Ascendant Dragonhide Satchel (UP^)",
          },
        },
        {
          name = "GC Bag",
          slots = {
            "The Golden Reliquary",
          },
        },
        {
          name = "Upgradable Bags (Jolum x1)",
          slots = {
            "Blue Brawler's Bindle (Base)",
            "Enhanced Blue Brawler's Bindle (UP^)",
            "Candy Bowl (Base)",
            "Enhanced Candy Bowl (UP^)",
            "Champion's Pack (Base)",
            "Enhanced Champion's Pack (UP^)",
            "Clover Tote (Base)",
            "Enhanced Clover Tote (UP^)",
            "Enchanted Slimesack (Token DZ) (Base)",
            "Enhanced Enchanted Slimesack (UP^)",
            "Glorious Prize Purse (Base)",
            "Enhanced Glorious Prize Purse (UP^)",
            "Heart Shaped Box (Base)",
            "Enhanced Heart Shaped Box (UP^)",
            "Jack-O-Lantern Bag (Base)",
            "Enhanced Jack-O-Lantern Bag (UP^)",
            "Tailored Legendary Pink Pack (Base)",
            "Enhanced Legendary Pink Pack (UP^)",
            "Magic Murder Satchel (Base)",
            "Enhanced Magic Murder Satchel (UP^)",
            "Red Rival's Rucksack (Base)",
            "Enhanced Red Rival's Rucksack (UP^)",
            "Risky Basket (Base)",
            "Enhanced Risky Basket (UP^)",
            "Runner's Rucksack (Base)",
            "Enhanced Runner's Rucksack (UP^)",
            "Sack of the Doomed (Base)",
            "Enhanced Sack of the Doomed (UP^)",
            "Santug Claugg's Sack (Base)",
            "Enhanced Santug Claugg's Sack (UP^)",
            "Santug's Stocking (Base)",
            "Enhanced Santug's Stocking (UP^)",
            "Speedster's Satchel (Base)",
            "Enhanced Speedster's Satchel (UP^)",
            "Treasure Hunter's Carryall (Base)",
            "Enhanced Treasure Hunter's Carryall (UP^)",
          },
        },
        {
          name = "Upgradable Bags (Recipe)",
          slots = {
            "Bank Storage Crate (Shady) (Base)",
            "Alloy Reinforced Bank Vault (UP^)",
          },
        },
        {
          name = "Lotto Tickets",
          slots = {
            "Euclid's Prime Carryall",
            "Artisan's Adept Attache",
          },
        },
      },
      classes = {
      },
      group = "Other Checklists",
      id = "bagitems",
      name = "Bag Items",
      show_base = {
        ALL = 1,
      },
      template = {
        ["Adventurer's Tattered Sack (Arcwoven) (UP3)"] = {
          aliases = {
            "Adventurer's Tattered Sack (Arcwoven)",
          },
          ids = {
            151056,
            151057,
          },
          item = "Adventurer's Tattered Sack (Arcwoven)",
        },
        ["Adventurer's Tattered Sack (Base) (T1 Named)"] = {
          aliases = {
            "Adventurer's Tattered Sack",
          },
          ids = {
            151053,
            151054,
            151055,
            151056,
            151057,
          },
          item = "Adventurer's Tattered Sack",
        },
        ["Adventurer's Tattered Sack (Bound) (UP2)"] = {
          aliases = {
            "Adventurer's Tattered Sack (Bound)",
          },
          ids = {
            151055,
            151056,
            151057,
          },
          item = "Adventurer's Tattered Sack (Bound)",
        },
        ["Adventurer's Tattered Sack (Celestial)"] = {
          aliases = {
            "Adventurer's Tattered Sack (Celestial)",
          },
          ids = {
            151057,
          },
          item = "Adventurer's Tattered Sack (Celestial)",
        },
        ["Adventurer's Tattered Sack (Reinforced) (UP1)"] = {
          aliases = {
            "Adventurer's Tattered Sack (Reinforced)",
          },
          ids = {
            151054,
            151055,
            151056,
            151057,
          },
          item = "Adventurer's Tattered Sack (Reinforced)",
        },
        ["Alloy Reinforced Bank Vault (UP^)"] = {
          aliases = {
            "Alloy Reinforced Bank Vault",
          },
          ids = {
          },
          item = "Alloy Reinforced Bank Vault",
        },
        ["Arcwoven Binding Thread (T4 Trash)"] = {
          aliases = {
            "Arcwoven Binding Thread",
          },
          ids = {
            151056,
            151057,
          },
          item = "Arcwoven Binding Thread",
        },
        ["Artisan's Adept Attache"] = {
          aliases = {
            "Artisan's Adept Attache",
          },
          ids = {
            50619,
          },
          item = "Artisan's Adept Attache",
        },
        ["Ascendant Dragonhide Satchel (UP^)"] = {
          aliases = {
            "Ascendant Dragonhide Satchel",
          },
          ids = {
            81946,
          },
          item = "Ascendant Dragonhide Satchel",
        },
        ["Bank Storage Crate (Shady) (Base)"] = {
          aliases = {
            "Bank Storage Crate",
          },
          ids = {
            50625,
          },
          item = "Bank Storage Crate",
        },
        ["Blessed Celestial Strongbox (UP1)"] = {
          aliases = {
            "Blessed Celestial Strongbox",
          },
          ids = {
            50135,
            50136,
            50137,
            50138,
            50139,
            50140,
            50141,
            50142,
            50143,
          },
          item = "Blessed Celestial Strongbox",
        },
        ["Blessed Celestial Strongbox (UP2)"] = {
          aliases = {
            "Blessed Celestial Strongbox",
          },
          ids = {
            50136,
            50137,
            50138,
            50139,
            50140,
            50141,
            50142,
            50143,
          },
          item = "Blessed Celestial Strongbox",
        },
        ["Blessed Celestial Strongbox (UP3)"] = {
          aliases = {
            "Blessed Celestial Strongbox",
          },
          ids = {
            50137,
            50138,
            50139,
            50140,
            50141,
            50142,
            50143,
          },
          item = "Blessed Celestial Strongbox",
        },
        ["Blessed Celestial Strongbox (UP4)"] = {
          aliases = {
            "Blessed Celestial Strongbox",
          },
          ids = {
            50138,
            50139,
            50140,
            50141,
            50142,
            50143,
          },
          item = "Blessed Celestial Strongbox",
        },
        ["Blessed Celestial Strongbox (UP5)"] = {
          aliases = {
            "Blessed Celestial Strongbox",
          },
          ids = {
            50139,
            50140,
            50141,
            50142,
            50143,
          },
          item = "Blessed Celestial Strongbox",
        },
        ["Blessed Celestial Strongbox (UP6)"] = {
          aliases = {
            "Blessed Celestial Strongbox",
          },
          ids = {
            50140,
            50141,
            50142,
            50143,
          },
          item = "Blessed Celestial Strongbox",
        },
        ["Blessed Celestial Strongbox (UP7)"] = {
          aliases = {
            "Blessed Celestial Strongbox",
          },
          ids = {
            50141,
            50142,
            50143,
          },
          item = "Blessed Celestial Strongbox",
        },
        ["Blessed Celestial Strongbox (UP8)"] = {
          aliases = {
            "Blessed Celestial Strongbox",
          },
          ids = {
            50142,
            50143,
          },
          item = "Blessed Celestial Strongbox",
        },
        ["Blessed Celestial Strongbox (UP9)"] = {
          aliases = {
            "Blessed Celestial Strongbox",
          },
          ids = {
            50143,
          },
          item = "Blessed Celestial Strongbox",
        },
        ["Blue Brawler's Bindle (Base)"] = {
          aliases = {
            "Blue Brawler's Bindle",
          },
          ids = {
            50200,
          },
          item = "Blue Brawler's Bindle",
        },
        ["Candy Bowl (Base)"] = {
          aliases = {
            "Candy Bowl",
          },
          ids = {
            50130,
          },
          item = "Candy Bowl",
        },
        ["Celestial Strongbox (CC) (Base)"] = {
          aliases = {
            "Celestial Strongbox",
          },
          ids = {
            50134,
            50135,
            50136,
            50137,
            50138,
            50139,
            50140,
            50141,
            50142,
            50143,
          },
          item = "Celestial Strongbox",
        },
        ["Celestial Blessing of the Djinn (UPG ITM)"] = {
          aliases = {
            "Celestial Blessing of the Djinn",
          },
          ids = {
            50133,
          },
          item = "Celestial Blessing of the Djinn",
        },
        ["Champion's Pack (Base)"] = {
          aliases = {
            "Champion's Pack",
          },
          ids = {
            50123,
          },
          item = "Champion's Pack",
        },
        ["Chromatic Dragonhide Satchel (Base)"] = {
          aliases = {
            "Chromatic Dragonhide Satchel",
          },
          ids = {
            81942,
            81943,
            81944,
            81945,
            81946,
          },
          item = "Chromatic Dragonhide Satchel",
        },
        ["Draconic Binding Thread (UPG ITM)"] = {
          aliases = {
            "Draconic Binding Thread",
          },
          ids = {
            81947,
          },
          item = "Draconic Binding Thread",
        },
        ["Clover Tote (Base)"] = {
          aliases = {
            "Clover Tote",
          },
          ids = {
            50131,
          },
          item = "Clover Tote",
        },
        ["Elder Dragonhide Satchel (UP3)"] = {
          aliases = {
            "Elder Dragonhide Satchel",
          },
          ids = {
            81945,
            81946,
          },
          item = "Elder Dragonhide Satchel",
        },
        ["Enchanted Slimesack (Token DZ) (Base)"] = {
          aliases = {
            "Enchanted Slimesack",
          },
          ids = {
            50126,
          },
          item = "Enchanted Slimesack",
        },
        ["Enhanced Blue Brawler's Bindle (UP^)"] = {
          aliases = {
            "Enhanced Blue Brawler's Bindle",
          },
          ids = {
          },
          item = "Enhanced Blue Brawler's Bindle",
        },
        ["Enhanced Candy Bowl (UP^)"] = {
          aliases = {
            "Enhanced Candy Bowl",
          },
          ids = {
          },
          item = "Enhanced Candy Bowl",
        },
        ["Enhanced Champion's Pack (UP^)"] = {
          aliases = {
            "Enhanced Champion's Pack",
          },
          ids = {
          },
          item = "Enhanced Champion's Pack",
        },
        ["Enhanced Clover Tote (UP^)"] = {
          aliases = {
            "Enhanced Clover Tote",
          },
          ids = {
          },
          item = "Enhanced Clover Tote",
        },
        ["Enhanced Enchanted Slimesack (UP^)"] = {
          aliases = {
            "Enhanced Enchanted Slimesack",
          },
          ids = {
          },
          item = "Enhanced Enchanted Slimesack",
        },
        ["Enhanced Glorious Prize Purse (UP^)"] = {
          aliases = {
            "Enhanced Glorious Prize Purse",
          },
          ids = {
          },
          item = "Enhanced Glorious Prize Purse",
        },
        ["Enhanced Heart Shaped Box (UP^)"] = {
          aliases = {
            "Enhanced Heart Shaped Box",
          },
          ids = {
          },
          item = "Enhanced Heart Shaped Box",
        },
        ["Enhanced Jack-O-Lantern Bag (UP^)"] = {
          aliases = {
            "Enhanced Jack-O-Lantern Bag",
          },
          ids = {
          },
          item = "Enhanced Jack-O-Lantern Bag",
        },
        ["Enhanced Legendary Pink Pack (UP^)"] = {
          aliases = {
            "Enhanced Legendary Pink Pack",
          },
          ids = {
          },
          item = "Enhanced Legendary Pink Pack",
        },
        ["Enhanced Magic Murder Satchel (UP^)"] = {
          aliases = {
            "Enhanced Magic Murder Satchel",
          },
          ids = {
          },
          item = "Enhanced Magic Murder Satchel",
        },
        ["Enhanced Red Rival's Rucksack (UP^)"] = {
          aliases = {
            "Enhanced Red Rival's Rucksack",
          },
          ids = {
          },
          item = "Enhanced Red Rival's Rucksack",
        },
        ["Enhanced Risky Basket (UP^)"] = {
          aliases = {
            "Enhanced Risky Basket",
          },
          ids = {
          },
          item = "Enhanced Risky Basket",
        },
        ["Enhanced Runner's Rucksack (UP^)"] = {
          aliases = {
            "Enhanced Runner's Rucksack",
          },
          ids = {
          },
          item = "Enhanced Runner's Rucksack",
        },
        ["Enhanced Sack of the Doomed (UP^)"] = {
          aliases = {
            "Enhanced Sack of the Doomed",
          },
          ids = {
          },
          item = "Enhanced Sack of the Doomed",
        },
        ["Enhanced Santug Claugg's Sack (UP^)"] = {
          aliases = {
            "Enhanced Santug Claugg's Sack",
          },
          ids = {
          },
          item = "Enhanced Santug Claugg's Sack",
        },
        ["Enhanced Santug's Stocking (UP^)"] = {
          aliases = {
            "Enhanced Santug's Stocking",
          },
          ids = {
          },
          item = "Enhanced Santug's Stocking",
        },
        ["Enhanced Speedster's Satchel (UP^)"] = {
          aliases = {
            "Enhanced Speedster's Satchel",
          },
          ids = {
          },
          item = "Enhanced Speedster's Satchel",
        },
        ["Enhanced Treasure Hunter's Carryall (UP^)"] = {
          aliases = {
            "Enhanced Treasure Hunter's Carryall",
          },
          ids = {
          },
          item = "Enhanced Treasure Hunter's Carryall",
        },
        ["Euclid's Prime Carryall"] = {
          aliases = {
            "Euclid's Prime Carryall",
          },
          ids = {
            50620,
          },
          item = "Euclid's Prime Carryall",
        },
        ["Glorious Prize Purse (Base)"] = {
          aliases = {
            "Glorious Prize Purse",
          },
          ids = {
            50125,
          },
          item = "Glorious Prize Purse",
        },
        ["Hallowed Celestial Strongbox (UP^)"] = {
          aliases = {
            "Hallowed Celestial Strongbox",
          },
          ids = {
          },
          item = "Hallowed Celestial Strongbox",
        },
        ["Heart Shaped Box (Base)"] = {
          aliases = {
            "Heart Shaped Box",
          },
          ids = {
            50423,
          },
          item = "Heart Shaped Box",
        },
        ["Jack-O-Lantern Bag (Base)"] = {
          aliases = {
            "Jack-O-Lantern Bag",
          },
          ids = {
            50127,
          },
          item = "Jack-O-Lantern Bag",
        },
        ["Magic Murder Satchel (Base)"] = {
          aliases = {
            "Magic Murder Satchel",
          },
          ids = {
            50198,
          },
          item = "Magic Murder Satchel",
        },
        ["Master Tailor's Celestial Lining (T5 Trash)"] = {
          aliases = {
            "Master Tailor's Celestial Lining",
          },
          ids = {
            151057,
          },
          item = "Master Tailor's Celestial Lining",
        },
        ["Red Rival's Rucksack (Base)"] = {
          aliases = {
            "Red Rival's Rucksack",
          },
          ids = {
            50202,
          },
          item = "Red Rival's Rucksack",
        },
        ["Reinforced Dragonhide Satchel (UP1)"] = {
          aliases = {
            "Reinforced Dragonhide Satchel",
          },
          ids = {
            81943,
            81944,
            81945,
            81946,
          },
          item = "Reinforced Dragonhide Satchel",
        },
        ["Reinforced Stitching Frame (T2 Trash)"] = {
          aliases = {
            "Reinforced Stitching Frame",
          },
          ids = {
            151057,
            151058,
          },
          item = "Reinforced Stitching Frame",
        },
        ["Risky Basket (Base)"] = {
          aliases = {
            "Risky Basket",
          },
          ids = {
            50129,
          },
          item = "Risky Basket",
        },
        ["Runner's Rucksack (Base)"] = {
          aliases = {
            "Runner's Rucksack",
          },
          ids = {
            50165,
          },
          item = "Runner's Rucksack",
        },
        ["Sack of the Doomed (Base)"] = {
          aliases = {
            "Sack of the Doomed",
          },
          ids = {
            50124,
          },
          item = "Sack of the Doomed",
        },
        ["Santug Claugg's Sack (Base)"] = {
          aliases = {
            "Santug Claugg's Sack",
          },
          ids = {
            50128,
          },
          item = "Santug Claugg's Sack",
        },
        ["Santug's Stocking (Base)"] = {
          aliases = {
            "Santug's Stocking",
          },
          ids = {
            50623,
          },
          item = "Santug's Stocking",
        },
        ["Scaled Dragonhide Satchel (UP2)"] = {
          aliases = {
            "Scaled Dragonhide Satchel",
          },
          ids = {
            81944,
            81945,
            81946,
          },
          item = "Scaled Dragonhide Satchel",
        },
        ["Speedster's Satchel (Base)"] = {
          aliases = {
            "Speedster's Satchel",
          },
          ids = {
            50163,
          },
          item = "Speedster's Satchel",
        },
        ["Tailored Legendary Pink Pack (Base)"] = {
          aliases = {
            "Tailored Legendary Pink Pack",
          },
          ids = {
            50628,
          },
          item = "Tailored Legendary Pink Pack",
        },
        ["The Golden Reliquary"] = {
          aliases = {
            "The Golden Reliquary",
          },
          ids = {
            50121,
          },
          item = "The Golden Reliquary",
        },
        ["Treasure Hunter's Carryall (Base)"] = {
          aliases = {
            "Treasure Hunter's Carryall",
          },
          ids = {
            50396,
          },
          item = "Treasure Hunter's Carryall",
        },
        ["Treated Expedition Straps (T3 Trash)"] = {
          aliases = {
            "Treated Expedition Straps",
          },
          ids = {
            151055,
            151056,
            151057,
          },
          item = "Treated Expedition Straps",
        },
      },
      visible = {
      },
    },
    don = {
      categories = {
        {
          name = "Visibles",
          slots = {
            "Head",
            "Chest",
            "Arms",
            "Wrist1",
            "Hands",
            "Legs",
            "Feet",
            "Wrist2",
          },
        },
        {
          name = "Non-Visibles",
          slots = {
            "Ear1",
            "Ear2",
            "Face",
            "Neck",
            "Back",
            "Shoulder",
            "Waist",
            "Finger1",
            "Finger2",
          },
        },
        {
          name = "Ranged + Charm",
          slots = {
            "Ranged",
            "RangedAug",
            "Duality",
            "CharmExtreme",
            "CharmSafe",
          },
        },
        {
          name = "Spells",
          slots = {
            "Pack1",
            "Pack2",
            "Pack3",
            "Pack4",
            "Pack5",
            "Pack6",
            "Pack7",
            "Pack8",
            "Pack9",
            "Pack10",
          },
        },
        {
          name = "Clickies",
          slots = {
            "Clicky1",
            "Clicky2",
            "Clicky3",
          },
        },
        {
          name = "Glyphs",
          slots = {
            "Glyph1",
            "Glyph2",
            "Glyph3",
            "Glyph4",
            "Glyph5",
            "Glyph6",
          },
        },
        {
          name = "Shadow",
          slots = {
            "Materium1",
            "Materium2",
            "Materium3",
            "Shadow",
            "Reward",
          },
        },
        {
          name = "Epic",
          slots = {
            "Scales",
            "2.75",
          },
        },
        {
          name = "Misc",
          slots = {
            "Misc1",
            "Misc2",
            "Misc3",
            "Misc5",
          },
        },
        {
          name = "Cryptic Clutch Foci",
          slots = {
            "Aug1",
            "Aug2",
            "Aug3",
            "Aug4",
            "Aug5",
            "Aug6",
            "Aug7",
            "Aug8",
            "Aug9",
            "Aug10",
            "Aug11",
            "Aug12",
            "Aug13",
            "Aug14",
            "Aug15",
            "Aug16",
            "Aug17",
            "Aug18",
            "Aug19",
          },
        },
      },
      classes = {
        Bard = {
          Arms = {
            aliases = {
              "Keeper's Ascendant Armbands of Harmony",
            },
            ids = {
              60459,
            },
            item = "Keeper's Ascendant Armbands of Harmony",
          },
          Aug19 = {
            aliases = {
              "Physical Prowess",
              "Cryptic Clutch of Physical Prowess",
              "Vacant Vessel of Physical Prowess",
            },
            ids = {
              62558,
              66533,
            },
            item = "Physical Prowess",
            notes = "No focus effect | +5 hSTR, +5 hSTA, +5 hAGI, +5 hDEX",
          },
          Back = {
            aliases = {
              "Cloak of Deepshadow",
            },
            ids = {
              71665,
            },
            item = "Cloak of Deepshadow",
          },
          Chest = {
            aliases = {
              "Keeper's Ascendant Chestguard of Harmony",
            },
            ids = {
              60458,
            },
            item = "Keeper's Ascendant Chestguard of Harmony",
          },
          Clicky1 = {
            aliases = {
              "Icon of Ancient Boon",
            },
            ids = {
              56758,
            },
            item = "Icon of Ancient Boon",
          },
          Clicky2 = {
            aliases = {
              "Icon of Potent Prowess",
            },
            ids = {
              56757,
            },
            item = "Icon of Potent Prowess",
          },
          Clicky3 = {
            aliases = {
              "Icon of Ancient Prowess",
            },
            ids = {
              57142,
            },
            item = "Icon of Ancient Prowess",
          },
          Ear1 = {
            aliases = {
              "Cloudkiller's Bauble",
            },
            ids = {
              71584,
            },
            item = "Cloudkiller's Bauble",
          },
          Ear2 = {
            aliases = {
              "Accursed Earhoop of Pain",
            },
            ids = {
              71668,
            },
            item = "Accursed Earhoop of Pain",
          },
          Face = {
            aliases = {
              "Mask of the Dawn Scorcher",
            },
            ids = {
              71626,
            },
            item = "Mask of the Dawn Scorcher",
          },
          Feet = {
            aliases = {
              "Keeper's Ascendant Boots of Harmony",
            },
            ids = {
              60463,
            },
            item = "Keeper's Ascendant Boots of Harmony",
          },
          Finger1 = {
            aliases = {
              "Glimmering Fire Opal Band",
            },
            ids = {
              71634,
            },
            item = "Glimmering Fire Opal Band",
          },
          Finger2 = {
            aliases = {
              "Bloodstained Ring of Evisceration",
            },
            ids = {
              71588,
            },
            item = "Bloodstained Ring of Evisceration",
          },
          Glyph1 = {
            aliases = {
              "Mnemonic Glyph: Cantata of Nife",
            },
            ids = {
              80071,
            },
            item = "Mnemonic Glyph: Cantata of Nife",
          },
          Glyph2 = {
            aliases = {
              "Mnemonic Glyph: Symphony of Sound",
            },
            ids = {
              80084,
            },
            item = "Mnemonic Glyph: Symphony of Sound",
          },
          Glyph3 = {
            aliases = {
              "Imbued Glyph: Echoes of the Ancient",
            },
            ids = {
              80072,
            },
            item = "Imbued Glyph: Echoes of the Ancient",
          },
          Hands = {
            aliases = {
              "Keeper's Ascendant Gloves of Harmony",
            },
            ids = {
              60461,
            },
            item = "Keeper's Ascendant Gloves of Harmony",
          },
          Head = {
            aliases = {
              "Keeper's Ascendant Helm of Harmony",
            },
            ids = {
              60457,
            },
            item = "Keeper's Ascendant Helm of Harmony",
          },
          Legs = {
            aliases = {
              "Keeper's Ascendant Legguards of Harmony",
            },
            ids = {
              60462,
            },
            item = "Keeper's Ascendant Legguards of Harmony",
          },
          Neck = {
            aliases = {
              "Necklace of Sandstorms",
            },
            ids = {
              71612,
            },
            item = "Necklace of Sandstorms",
          },
          Pack1 = {
            aliases = {
              "Spell Pack: Cantata of Nife",
            },
            ids = {
              82821,
            },
            item = "Spell Pack: Cantata of Nife",
            spell = "Cantata of Nife",
            spells = {
              "Cantata of Nife",
            },
          },
          Pack2 = {
            aliases = {
              "Spell Pack: Symphony of Sound",
            },
            ids = {
              82822,
            },
            item = "Spell Pack: Symphony of Sound",
            spell = "Symphony of Sound",
            spells = {
              "Symphony of Sound",
            },
          },
          Pack3 = {
            aliases = {
              "Spell Pack: Echoes of the Ancient",
            },
            ids = {
              82823,
            },
            item = "Spell Pack: Echoes of the Ancient",
            spell = "Echoes of the Ancient",
            spells = {
              "Echoes of the Ancient",
            },
          },
          Pack4 = {
            aliases = {
              "Song: Niv's Symphonic",
            },
            ids = {
              81935,
            },
            item = "Song: Niv's Symphonic",
            spell = "Niv's Symphonic",
            spell_ids = {
              15264,
            },
            spells = {
              "Niv's Symphonic",
            },
          },
          Pack5 = {
            aliases = {
              "Song: One Bard Band",
            },
            ids = {
              78739,
            },
            item = "Song: One Bard Band",
            spell = "One Bard Band",
            spell_ids = {
              35234,
            },
            spells = {
              "One Bard Band",
            },
          },
          Pack6 = {
            aliases = {
              "Song: Squall Blade",
            },
            ids = {
              50157,
            },
            item = "Song: Squall Blade",
            spell = "Squall Blade Flourish",
            spell_ids = {
              10940,
            },
            spells = {
              "Squall Blade Flourish",
            },
          },
          Pack7 = {
            aliases = {
              "Tome of Arcane Reprisal",
            },
            ids = {
              79226,
            },
            item = "Tome of Arcane Reprisal",
            spell = "Arcane Reprisal",
            spell_ids = {
              10889,
            },
            spells = {
              "Arcane Reprisal",
            },
          },
          Pack8 = {
            aliases = {
              "Tome of Endless Blades",
            },
            ids = {
              50156,
            },
            item = "Tome of Endless Blades",
            spell = "Endless Blades",
            spell_ids = {
              10939,
            },
            spells = {
              "Endless Blades",
            },
          },
          Ranged = {
            aliases = {
              "Head of the Putrid Drake",
            },
            ids = {
              55052,
            },
            item = "Head of the Putrid Drake",
          },
          RangedAug = {
            aliases = {
              "Preserved Eye of the Putrid Drake",
            },
            ids = {
              71620,
            },
            item = "Preserved Eye of the Putrid Drake",
          },
          Shadow = {
            aliases = {
              "Shadow of a Legendary Bard Weapon",
              "Broodslayer, the Dauntless Blade",
            },
            identities = {
              rewards = {
                {
                  id = 56498,
                  name = "Broodslayer, the Dauntless Blade",
                },
              },
              shadow_component = {
                id = 60668,
                name = "Shadow of a Legendary Bard Weapon",
              },
            },
            ids = {
              60668,
              56498,
            },
            item = "Shadow of a Legendary Bard Weapon",
          },
          Shoulder = {
            aliases = {
              "Lightning Singed Mantle",
            },
            ids = {
              71654,
            },
            item = "Lightning Singed Mantle",
          },
          Waist = {
            aliases = {
              "Thundercrash Girdle",
            },
            ids = {
              71657,
            },
            item = "Thundercrash Girdle",
          },
          Wrist1 = {
            aliases = {
              "Keeper's Ascendant Wristguard of Harmony",
            },
            ids = {
              60460,
            },
            item = "Keeper's Ascendant Wristguard of Harmony",
          },
          Wrist2 = {
            aliases = {
              "Keeper's Eternal Bracer of Harmony",
            },
            ids = {
              60464,
            },
            item = "Keeper's Eternal Bracer of Harmony",
          },
        },
        Beastlord = {
          Arms = {
            aliases = {
              "Keeper's Ascendant Sleeves of the Wilds",
            },
            ids = {
              60529,
            },
            item = "Keeper's Ascendant Sleeves of the Wilds",
          },
          Aug19 = {
            aliases = {
              "Physical Prowess",
              "Cryptic Clutch of Physical Prowess",
              "Vacant Vessel of Physical Prowess",
            },
            ids = {
              62558,
              66533,
            },
            item = "Physical Prowess",
            notes = "No focus effect | +5 hSTR, +5 hSTA, +5 hAGI, +5 hDEX",
          },
          Back = {
            aliases = {
              "Cloak of Deepshadow",
            },
            ids = {
              71665,
            },
            item = "Cloak of Deepshadow",
          },
          Chest = {
            aliases = {
              "Keeper's Ascendant Jerkin of the Wilds",
            },
            ids = {
              60528,
            },
            item = "Keeper's Ascendant Jerkin of the Wilds",
          },
          Clicky1 = {
            aliases = {
              "Icon of Ancient Boon",
            },
            ids = {
              56758,
            },
            item = "Icon of Ancient Boon",
          },
          Clicky2 = {
            aliases = {
              "Icon of Potent Prowess",
            },
            ids = {
              56757,
            },
            item = "Icon of Potent Prowess",
          },
          Clicky3 = {
            aliases = {
              "Icon of Ancient Prowess",
            },
            ids = {
              57142,
            },
            item = "Icon of Ancient Prowess",
          },
          Ear1 = {
            aliases = {
              "Hoop of the Drakeborn",
            },
            ids = {
              71574,
            },
            item = "Hoop of the Drakeborn",
          },
          Ear2 = {
            aliases = {
              "Accursed Earhoop of Pain",
            },
            ids = {
              71668,
            },
            item = "Accursed Earhoop of Pain",
          },
          Face = {
            aliases = {
              "Entrancing Silk Veil",
            },
            ids = {
              71643,
            },
            item = "Entrancing Silk Veil",
          },
          Feet = {
            aliases = {
              "Keeper's Ascendant Sandals of the Wilds",
            },
            ids = {
              60533,
            },
            item = "Keeper's Ascendant Sandals of the Wilds",
          },
          Finger1 = {
            aliases = {
              "Thought Sieve Ring",
            },
            ids = {
              71625,
            },
            item = "Thought Sieve Ring",
          },
          Finger2 = {
            aliases = {
              "Bloodstained Ring of Evisceration",
            },
            ids = {
              71588,
            },
            item = "Bloodstained Ring of Evisceration",
          },
          Glyph1 = {
            aliases = {
              "Mnemonic Glyph: Spiritual Vibrance",
            },
            ids = {
              80067,
            },
            item = "Mnemonic Glyph: Spiritual Vibrance",
          },
          Glyph2 = {
            aliases = {
              "Mnemonic Glyph: Roaring Spirit of Tirranun",
            },
            ids = {
              80068,
            },
            item = "Mnemonic Glyph: Roaring Spirit of Tirranun",
          },
          Glyph3 = {
            aliases = {
              "Mnemonic Glyph: Growl of the Mountain Puma",
            },
            ids = {
              80069,
            },
            item = "Mnemonic Glyph: Growl of the Mountain Puma",
          },
          Glyph4 = {
            aliases = {
              "Imbued Glyph: Sha's Urgent Renewal",
            },
            ids = {
              80070,
            },
            item = "Imbued Glyph: Sha's Urgent Renewal",
          },
          Hands = {
            aliases = {
              "Keeper's Ascendant Gloves of the Wilds",
            },
            ids = {
              60531,
            },
            item = "Keeper's Ascendant Gloves of the Wilds",
          },
          Head = {
            aliases = {
              "Keeper's Ascendant Cap of the Wilds",
            },
            ids = {
              60527,
            },
            item = "Keeper's Ascendant Cap of the Wilds",
          },
          Legs = {
            aliases = {
              "Keeper's Ascendant Legguards of the Wilds",
            },
            ids = {
              60532,
            },
            item = "Keeper's Ascendant Legguards of the Wilds",
          },
          Neck = {
            aliases = {
              "Necklace of Sandstorms",
            },
            ids = {
              71612,
            },
            item = "Necklace of Sandstorms",
          },
          Pack1 = {
            aliases = {
              "Spell Pack: Spiritual Vibrance",
            },
            ids = {
              82817,
            },
            item = "Spell Pack: Spiritual Vibrance",
            spell = "Spiritual Vibrance",
            spells = {
              "Spiritual Vibrance",
            },
          },
          Pack2 = {
            aliases = {
              "Spell Pack: Roaring Spirit of Tirranun",
            },
            ids = {
              82818,
            },
            item = "Spell Pack: Roaring Spirit of Tirranun",
            spell = "Roaring Spirit of Tirranun",
            spells = {
              "Roaring Spirit of Tirranun",
            },
          },
          Pack3 = {
            aliases = {
              "Spell Pack: Growl of the Mountain Puma",
            },
            ids = {
              82819,
            },
            item = "Spell Pack: Growl of the Mountain Puma",
            spell = "Growl of the Mountain Puma",
            spells = {
              "Growl of the Mountain Puma",
            },
          },
          Pack4 = {
            aliases = {
              "Spell Pack: Sha's Urgent Renewal",
            },
            ids = {
              82820,
            },
            item = "Spell Pack: Sha's Urgent Renewal",
            spell = "Sha's Urgent Renewal",
            spells = {
              "Sha's Urgent Renewal",
            },
          },
          Pack5 = {
            aliases = {
              "Spell: Feral Mettle",
            },
            ids = {
              81933,
            },
            item = "Spell: Feral Mettle",
            spell = "Feral Mettle",
            spell_ids = {
              15261,
            },
            spells = {
              "Feral Mettle",
            },
          },
          Pack6 = {
            aliases = {
              "Spell: Ravenous Ice",
            },
            ids = {
              81934,
            },
            item = "Spell: Ravenous Ice",
            spell = "Ravenous Ice",
            spell_ids = {
              15263,
            },
            spells = {
              "Ravenous Ice",
            },
          },
          Pack7 = {
            aliases = {
              "Spell: Roaring Sleet",
            },
            ids = {
              78701,
            },
            item = "Spell: Roaring Sleet",
            spell = "Roaring Sleet",
            spell_ids = {
              10364,
            },
            spells = {
              "Roaring Sleet",
            },
          },
          Pack8 = {
            aliases = {
              "Spell: Spiritual Enlightenment",
            },
            ids = {
              81868,
            },
            item = "Spell: Spiritual Enlightenment",
            spell = "Spiritual Enlightenment",
            spell_ids = {
              15260,
            },
            spells = {
              "Spiritual Enlightenment",
            },
          },
          Pack9 = {
            aliases = {
              "Spell: Swift Salve of the Stillmoon",
            },
            ids = {
              81867,
            },
            item = "Spell: Swift Salve of the Stillmoon",
            spell = "Swift Salve of the Stillmoon",
            spell_ids = {
              15257,
            },
            spells = {
              "Swift Salve of the Stillmoon",
            },
          },
          Ranged = {
            aliases = {
              "Branch of the Twisting Tree",
            },
            ids = {
              71627,
            },
            item = "Branch of the Twisting Tree",
          },
          RangedAug = {
            aliases = {
              "Fallen Leaf of the Twisting Tree",
            },
            ids = {
              55053,
            },
            item = "Fallen Leaf of the Twisting Tree",
          },
          Shadow = {
            aliases = {
              "Shadow of a Legendary Beastlord Weapon",
              "Holy Relic of the Temple",
            },
            identities = {
              rewards = {
                {
                  id = 56754,
                  name = "Holy Relic of the Temple",
                },
              },
              shadow_component = {
                id = 62534,
                name = "Shadow of a Legendary Beastlord Weapon",
              },
            },
            ids = {
              62534,
              56754,
            },
            item = "Shadow of a Legendary Beastlord Weapon",
          },
          Shoulder = {
            aliases = {
              "Brimstone Spaulders",
            },
            ids = {
              71635,
            },
            item = "Brimstone Spaulders",
          },
          Waist = {
            aliases = {
              "Windwatcher Sash",
            },
            ids = {
              71621,
            },
            item = "Windwatcher Sash",
          },
          Wrist1 = {
            aliases = {
              "Keeper's Ascendant Wristband of the Wilds",
            },
            ids = {
              60530,
            },
            item = "Keeper's Ascendant Wristband of the Wilds",
          },
          Wrist2 = {
            aliases = {
              "Keeper's Eternal Bracer of the Wilds",
            },
            ids = {
              60534,
            },
            item = "Keeper's Eternal Bracer of the Wilds",
          },
        },
        Berserker = {
          Arms = {
            aliases = {
              "Keeper's Ascendant Sleeves of the Vindicator",
            },
            ids = {
              60451,
            },
            item = "Keeper's Ascendant Sleeves of the Vindicator",
          },
          Aug19 = {
            aliases = {
              "Physical Prowess",
              "Cryptic Clutch of Physical Prowess",
              "Vacant Vessel of Physical Prowess",
            },
            ids = {
              62558,
              66533,
            },
            item = "Physical Prowess",
            notes = "No focus effect | +5 hSTR, +5 hSTA, +5 hAGI, +5 hDEX",
          },
          Back = {
            aliases = {
              "Cloak of Deepshadow",
            },
            ids = {
              71665,
            },
            item = "Cloak of Deepshadow",
          },
          Chest = {
            aliases = {
              "Keeper's Ascendant Chestguard of the Vindicator",
            },
            ids = {
              60450,
            },
            item = "Keeper's Ascendant Chestguard of the Vindicator",
          },
          Clicky1 = {
            aliases = {
              "Icon of Ancient Boon",
            },
            ids = {
              56758,
            },
            item = "Icon of Ancient Boon",
          },
          Clicky2 = {
            aliases = {
              "Icon of Potent Prowess",
            },
            ids = {
              56757,
            },
            item = "Icon of Potent Prowess",
          },
          Clicky3 = {
            aliases = {
              "Icon of Ancient Prowess",
            },
            ids = {
              57142,
            },
            item = "Icon of Ancient Prowess",
          },
          Ear1 = {
            aliases = {
              "Cloudkiller's Bauble",
            },
            ids = {
              71584,
            },
            item = "Cloudkiller's Bauble",
          },
          Ear2 = {
            aliases = {
              "Accursed Earhoop of Pain",
            },
            ids = {
              71668,
            },
            item = "Accursed Earhoop of Pain",
          },
          Face = {
            aliases = {
              "Mask of the Dawn Scorcher",
            },
            ids = {
              71626,
            },
            item = "Mask of the Dawn Scorcher",
          },
          Feet = {
            aliases = {
              "Keeper's Ascendant Boots of the Vindicator",
            },
            ids = {
              60455,
            },
            item = "Keeper's Ascendant Boots of the Vindicator",
          },
          Finger1 = {
            aliases = {
              "Glimmering Fire Opal Band",
            },
            ids = {
              71634,
            },
            item = "Glimmering Fire Opal Band",
          },
          Finger2 = {
            aliases = {
              "Bloodstained Ring of Evisceration",
            },
            ids = {
              71588,
            },
            item = "Bloodstained Ring of Evisceration",
          },
          Glyph1 = {
            aliases = {
              "Imbued Glyph: Ancient: Annihilator's Volley",
            },
            ids = {
              80076,
            },
            item = "Imbued Glyph: Ancient: Annihilator's Volley",
          },
          Hands = {
            aliases = {
              "Keeper's Ascendant Gloves of the Vindicator",
            },
            ids = {
              60453,
            },
            item = "Keeper's Ascendant Gloves of the Vindicator",
          },
          Head = {
            aliases = {
              "Keeper's Ascendant Helm of the Vindicator",
            },
            ids = {
              60449,
            },
            item = "Keeper's Ascendant Helm of the Vindicator",
          },
          Legs = {
            aliases = {
              "Keeper's Ascendant Leggings of the Vindicator",
            },
            ids = {
              60454,
            },
            item = "Keeper's Ascendant Leggings of the Vindicator",
          },
          Neck = {
            aliases = {
              "Necklace of Sandstorms",
            },
            ids = {
              71612,
            },
            item = "Necklace of Sandstorms",
          },
          Pack1 = {
            aliases = {
              "Tome Pack: Ancient: Annihilator's Volley",
            },
            ids = {
              82657,
            },
            item = "Tome Pack: Ancient: Annihilator's Volley",
            spell = "Ancient: Annihilator's Volley",
            spells = {
              "Ancient: Annihilator's Volley",
            },
          },
          Pack10 = {
            aliases = {
              "Tome of Wounded Rage Discipline",
            },
            ids = {
              80281,
            },
            item = "Tome of Wounded Rage Discipline",
            spell = "Wounding Rage",
            spell_ids = {
              15122,
            },
            spells = {
              "Wounding Rage",
            },
          },
          Pack2 = {
            aliases = {
              "Tome of Arcane Reprisal",
            },
            ids = {
              79226,
            },
            item = "Tome of Arcane Reprisal",
            spell = "Arcane Reprisal",
            spell_ids = {
              10889,
            },
            spells = {
              "Arcane Reprisal",
            },
          },
          Pack3 = {
            aliases = {
              "Tome of Battle Focus Discipline",
            },
            ids = {
              59925,
            },
            item = "Tome of Battle Focus Discipline",
            spell = "Battle Focus Discipline",
            spell_ids = {
              5038,
            },
            spells = {
              "Battle Focus Discipline",
            },
          },
          Pack4 = {
            aliases = {
              "Tome of Bloodcurdling Scream",
            },
            ids = {
              79251,
            },
            item = "Tome of Bloodcurdling Scream",
            spell = "Bloodcurdling Scream",
            spell_ids = {
              10915,
            },
            spells = {
              "Bloodcurdling Scream",
            },
          },
          Pack5 = {
            aliases = {
              "Tome of Cleaving Madness Discipline",
            },
            ids = {
              50120,
            },
            item = "Tome of Cleaving Madness Discipline",
            spell = "Cleaving Madness Discipline",
            spell_ids = {
              10860,
            },
            spells = {
              "Cleaving Madness Discipline",
            },
          },
          Pack6 = {
            aliases = {
              "Tome of Cry of Catastrophe",
            },
            ids = {
              50118,
            },
            item = "Tome of Cry of Catastrophe",
            spell = "Cry of Catastrophe",
            spell_ids = {
              10857,
            },
            spells = {
              "Cry of Catastrophe",
            },
          },
          Pack7 = {
            aliases = {
              "Tome of Fourth Wind",
            },
            ids = {
              80081,
            },
            item = "Tome of Fourth Wind",
            spell = "Fourth Wind Discipline",
            spell_ids = {
              15134,
            },
            spells = {
              "Fourth Wind Discipline",
            },
          },
          Pack8 = {
            aliases = {
              "Tome of Rancorous Flurry Discipline",
            },
            ids = {
              80280,
            },
            item = "Tome of Rancorous Flurry Discipline",
            spell = "Rancorous Flurry Discipline",
            spell_ids = {
              15120,
            },
            spells = {
              "Rancorous Flurry Discipline",
            },
          },
          Pack9 = {
            aliases = {
              "Tome of Vigorous Axe Throw",
            },
            ids = {
              50119,
            },
            item = "Tome of Vigorous Axe Throw",
            spell = "Vigorous Axe Throw",
            spell_ids = {
              10858,
            },
            spells = {
              "Vigorous Axe Throw",
            },
          },
          Ranged = {
            aliases = {
              "Head of the Putrid Drake",
            },
            ids = {
              55052,
            },
            item = "Head of the Putrid Drake",
          },
          RangedAug = {
            aliases = {
              "Preserved Eye of the Putrid Drake",
            },
            ids = {
              71620,
            },
            item = "Preserved Eye of the Putrid Drake",
          },
          Shadow = {
            aliases = {
              "Shadow of a Legendary Berserker Augment",
              "Igniss, the Fallen Flame",
            },
            identities = {
              rewards = {
                {
                  id = 56497,
                  name = "Igniss, the Fallen Flame",
                },
              },
              shadow_component = {
                id = 60667,
                name = "Shadow of a Legendary Berserker Augment",
              },
            },
            ids = {
              60667,
              56497,
            },
            item = "Shadow of a Legendary Berserker Augment",
          },
          Shoulder = {
            aliases = {
              "Lightning Singed Mantle",
            },
            ids = {
              71654,
            },
            item = "Lightning Singed Mantle",
          },
          Waist = {
            aliases = {
              "Thundercrash Girdle",
            },
            ids = {
              71657,
            },
            item = "Thundercrash Girdle",
          },
          Wrist1 = {
            aliases = {
              "Keeper's Ascendant Wristguard of the Vindicator",
            },
            ids = {
              60452,
            },
            item = "Keeper's Ascendant Wristguard of the Vindicator",
          },
          Wrist2 = {
            aliases = {
              "Keeper's Eternal Bracer of the Vindicator",
            },
            ids = {
              60456,
            },
            item = "Keeper's Eternal Bracer of the Vindicator",
          },
        },
        Cleric = {
          Arms = {
            aliases = {
              "Keeper's Ascendant Armguards of Conviction",
            },
            ids = {
              57146,
            },
            item = "Keeper's Ascendant Armguards of Conviction",
          },
          Aug19 = {
            aliases = {
              "Mental Prowess",
              "Cryptic Clutch of Mental Prowess",
              "Vacant Vessel of Mental Prowess",
            },
            ids = {
              62559,
              66720,
            },
            item = "Mental Prowess",
            notes = "No focus effect | +10 hINT, +10 hWIS, +10 heroic resists",
          },
          Back = {
            aliases = {
              "Cape of Serenity",
            },
            ids = {
              71613,
            },
            item = "Cape of Serenity",
          },
          Chest = {
            aliases = {
              "Keeper's Ascendant Breastplate of Conviction",
            },
            ids = {
              57145,
            },
            item = "Keeper's Ascendant Breastplate of Conviction",
          },
          Clicky1 = {
            aliases = {
              "Icon of Ancient Boon",
            },
            ids = {
              56758,
            },
            item = "Icon of Ancient Boon",
          },
          Clicky2 = {
            aliases = {
              "Icon of Scribe's Endurance",
            },
            ids = {
              56756,
            },
            item = "Icon of Scribe's Endurance",
          },
          Clicky3 = {
            aliases = {
              "Icon of the Ancient Scribe",
            },
            ids = {
              57143,
            },
            item = "Icon of the Ancient Scribe",
          },
          Ear1 = {
            aliases = {
              "Earring of Contemplation",
            },
            ids = {
              71589,
            },
            item = "Earring of Contemplation",
          },
          Ear2 = {
            aliases = {
              "Tear of Kessdona",
            },
            ids = {
              71642,
            },
            item = "Tear of Kessdona",
          },
          Face = {
            aliases = {
              "Young Dragon Mask",
            },
            ids = {
              71594,
            },
            item = "Young Dragon Mask",
          },
          Feet = {
            aliases = {
              "Keeper's Ascendant Boots of Conviction",
            },
            ids = {
              57150,
            },
            item = "Keeper's Ascendant Boots of Conviction",
          },
          Finger1 = {
            aliases = {
              "Dragon Nursery Ring",
            },
            ids = {
              71592,
            },
            item = "Dragon Nursery Ring",
          },
          Finger2 = {
            aliases = {
              "Eye of Tirranun",
            },
            ids = {
              71652,
            },
            item = "Eye of Tirranun",
          },
          Glyph1 = {
            aliases = {
              "Mnemonic Glyph: Allegiance",
            },
            ids = {
              76563,
            },
            item = "Mnemonic Glyph: Allegiance",
          },
          Glyph2 = {
            aliases = {
              "Mnemonic Glyph: Hand of Allegiance",
            },
            ids = {
              76564,
            },
            item = "Mnemonic Glyph: Hand of Allegiance",
          },
          Glyph3 = {
            aliases = {
              "Mnemonic Glyph: Symbol of Elushar",
            },
            ids = {
              76565,
            },
            item = "Mnemonic Glyph: Symbol of Elushar",
          },
          Glyph4 = {
            aliases = {
              "Mnemonic Glyph: Armor of the Sacred",
            },
            ids = {
              76566,
            },
            item = "Mnemonic Glyph: Armor of the Sacred",
          },
          Glyph5 = {
            aliases = {
              "Imbued Glyph: Aegis of Vie",
            },
            ids = {
              76567,
            },
            item = "Imbued Glyph: Aegis of Vie",
          },
          Hands = {
            aliases = {
              "Keeper's Ascendant Gloves of Conviction",
            },
            ids = {
              57148,
            },
            item = "Keeper's Ascendant Gloves of Conviction",
          },
          Head = {
            aliases = {
              "Keeper's Ascendant Cap of Conviction",
            },
            ids = {
              57144,
            },
            item = "Keeper's Ascendant Cap of Conviction",
          },
          Legs = {
            aliases = {
              "Keeper's Ascendant Leggings of Conviction",
            },
            ids = {
              57149,
            },
            item = "Keeper's Ascendant Leggings of Conviction",
          },
          Neck = {
            aliases = {
              "Locket of Raining Tears",
            },
            ids = {
              71655,
            },
            item = "Locket of Raining Tears",
          },
          Pack1 = {
            aliases = {
              "Spell Pack: Allegiance",
            },
            ids = {
              82658,
            },
            item = "Spell Pack: Allegiance",
            spell = "Allegiance",
            spells = {
              "Allegiance",
              "Hand of Allegiance",
              "Symbol of Elushar",
            },
          },
          Pack2 = {
            aliases = {
              "Spell Pack: Armor of the Sacred",
            },
            ids = {
              82660,
            },
            item = "Spell Pack: Armor of the Sacred",
            spell = "Armor of the Sacred",
            spells = {
              "Armor of the Sacred",
            },
          },
          Pack3 = {
            aliases = {
              "Spell Pack: Aegis of Vie",
            },
            ids = {
              82661,
            },
            item = "Spell Pack: Aegis of Vie",
            spell = "Aegis of Vie",
            spells = {
              "Aegis of Vie",
            },
          },
          Pack4 = {
            aliases = {
              "Spell: Chromablast",
            },
            ids = {
              80284,
            },
            item = "Spell: Chromablast",
            spell = "Chromablast",
            spell_ids = {
              15140,
            },
            spells = {
              "Chromablast",
            },
          },
          Pack5 = {
            aliases = {
              "Spell: Divine Redemption",
            },
            ids = {
              124941,
            },
            item = "Spell: Divine Redemption",
            spell = "Divine Redemption",
            spell_ids = {
              25252,
            },
            spells = {
              "Divine Redemption",
            },
          },
          Pack6 = {
            aliases = {
              "Spell: Elixir of Redemption",
            },
            ids = {
              78149,
            },
            item = "Spell: Elixir of Redemption",
            spell = "Elixir of Redemption",
            spell_ids = {
              9812,
            },
            spells = {
              "Elixir of Redemption",
            },
          },
          Pack7 = {
            aliases = {
              "Spell: Sound of Zeal",
            },
            ids = {
              78086,
            },
            item = "Spell: Sound of Zeal",
            spell = "Sound of Zeal",
            spell_ids = {
              9749,
            },
            spells = {
              "Sound of Zeal",
            },
          },
          Pack8 = {
            aliases = {
              "Spell: Urgent Renewal",
            },
            ids = {
              80282,
            },
            item = "Spell: Urgent Renewal",
            spell = "Urgent Renewal",
            spell_ids = {
              15135,
            },
            spells = {
              "Urgent Renewal",
            },
          },
          Pack9 = {
            aliases = {
              "Spell: Vigilant Censure",
            },
            ids = {
              80283,
            },
            item = "Spell: Vigilant Censure",
            spell = "Vigilant Censure",
            spell_ids = {
              15137,
            },
            spells = {
              "Vigilant Censure",
            },
          },
          Ranged = {
            aliases = {
              "Phial of the First Brood",
            },
            ids = {
              71578,
            },
            item = "Phial of the First Brood",
          },
          RangedAug = {
            aliases = {
              "Crux of the First Brood",
            },
            ids = {
              60535,
            },
            item = "Crux of the First Brood",
          },
          Shadow = {
            aliases = {
              "Shadow of a Legendary Cleric Staff",
              "Beacon of the Blessed",
            },
            identities = {
              rewards = {
                {
                  id = 56492,
                  name = "Beacon of the Blessed",
                },
              },
              shadow_component = {
                id = 60546,
                name = "Shadow of a Legendary Cleric Staff",
              },
            },
            ids = {
              60546,
              56492,
            },
            item = "Shadow of a Legendary Cleric Staff",
          },
          Shoulder = {
            aliases = {
              "Obsidian Pauldrons",
            },
            ids = {
              71666,
            },
            item = "Obsidian Pauldrons",
          },
          Waist = {
            aliases = {
              "Windwatcher Sash",
            },
            ids = {
              71621,
            },
            item = "Windwatcher Sash",
          },
          Wrist1 = {
            aliases = {
              "Keeper's Ascendant Wristband of Conviction",
            },
            ids = {
              57147,
            },
            item = "Keeper's Ascendant Wristband of Conviction",
          },
          Wrist2 = {
            aliases = {
              "Keeper's Eternal Bracer of Conviction",
            },
            ids = {
              57151,
            },
            item = "Keeper's Eternal Bracer of Conviction",
          },
        },
        Druid = {
          Arms = {
            aliases = {
              "Keeper's Ascendant Sleeves of the Tangled Briars",
            },
            ids = {
              57162,
            },
            item = "Keeper's Ascendant Sleeves of the Tangled Briars",
          },
          Aug19 = {
            aliases = {
              "Mental Prowess",
              "Cryptic Clutch of Mental Prowess",
              "Vacant Vessel of Mental Prowess",
            },
            ids = {
              62559,
              66720,
            },
            item = "Mental Prowess",
            notes = "No focus effect | +10 hINT, +10 hWIS, +10 heroic resists",
          },
          Back = {
            aliases = {
              "Cape of Serenity",
            },
            ids = {
              71613,
            },
            item = "Cape of Serenity",
          },
          Chest = {
            aliases = {
              "Keeper's Ascendant Jerkin of the Tangled Briars",
            },
            ids = {
              57161,
            },
            item = "Keeper's Ascendant Jerkin of the Tangled Briars",
          },
          Clicky1 = {
            aliases = {
              "Icon of Ancient Boon",
            },
            ids = {
              56758,
            },
            item = "Icon of Ancient Boon",
          },
          Clicky2 = {
            aliases = {
              "Icon of Scribe's Endurance",
            },
            ids = {
              56756,
            },
            item = "Icon of Scribe's Endurance",
          },
          Clicky3 = {
            aliases = {
              "Icon of the Ancient Scribe",
            },
            ids = {
              57143,
            },
            item = "Icon of the Ancient Scribe",
          },
          Ear1 = {
            aliases = {
              "Earring of Contemplation",
            },
            ids = {
              71589,
            },
            item = "Earring of Contemplation",
          },
          Ear2 = {
            aliases = {
              "Tear of Kessdona",
            },
            ids = {
              71642,
            },
            item = "Tear of Kessdona",
          },
          Face = {
            aliases = {
              "Young Dragon Mask",
            },
            ids = {
              71594,
            },
            item = "Young Dragon Mask",
          },
          Feet = {
            aliases = {
              "Keeper's Ascendant Slippers of the Tangled Briars",
            },
            ids = {
              57178,
            },
            item = "Keeper's Ascendant Slippers of the Tangled Briars",
          },
          Finger1 = {
            aliases = {
              "Dragon Nursery Ring",
            },
            ids = {
              71592,
            },
            item = "Dragon Nursery Ring",
          },
          Finger2 = {
            aliases = {
              "Eye of Tirranun",
            },
            ids = {
              71652,
            },
            item = "Eye of Tirranun",
          },
          Glyph1 = {
            aliases = {
              "Mnemonic Glyph: Spiritoak Skin",
            },
            ids = {
              76573,
            },
            item = "Mnemonic Glyph: Spiritoak Skin",
          },
          Glyph2 = {
            aliases = {
              "Mnemonic Glyph: Blessing of Spiritoak",
            },
            ids = {
              78227,
            },
            item = "Mnemonic Glyph: Blessing of Spiritoak",
          },
          Glyph3 = {
            aliases = {
              "Mnemonic Glyph: Mossy Vigor",
            },
            ids = {
              79518,
            },
            item = "Mnemonic Glyph: Mossy Vigor",
          },
          Glyph4 = {
            aliases = {
              "Mnemonic Glyph: Blessing of Moss",
            },
            ids = {
              79519,
            },
            item = "Mnemonic Glyph: Blessing of Moss",
          },
          Glyph5 = {
            aliases = {
              "Imbued Glyph: Sun's Blistering Corona",
            },
            ids = {
              79520,
            },
            item = "Imbued Glyph: Sun's Blistering Corona",
          },
          Hands = {
            aliases = {
              "Keeper's Ascendant Mitts of the Tangled Briars",
            },
            ids = {
              57164,
            },
            item = "Keeper's Ascendant Mitts of the Tangled Briars",
          },
          Head = {
            aliases = {
              "Keeper's Ascendant Cap of the Tangled Briars",
            },
            ids = {
              57160,
            },
            item = "Keeper's Ascendant Cap of the Tangled Briars",
          },
          Legs = {
            aliases = {
              "Keeper's Ascendant Pants of the Tangled Briars",
            },
            ids = {
              57165,
            },
            item = "Keeper's Ascendant Pants of the Tangled Briars",
          },
          Neck = {
            aliases = {
              "Locket of Raining Tears",
            },
            ids = {
              71655,
            },
            item = "Locket of Raining Tears",
          },
          Pack1 = {
            aliases = {
              "Spell Pack: Spiritoaks",
            },
            ids = {
              82688,
            },
            item = "Spell Pack: Spiritoaks",
            spell = "Spiritoak Skin",
            spells = {
              "Spiritoak Skin",
              "Blessing of Spiritoak",
            },
          },
          Pack2 = {
            aliases = {
              "Spell Pack: Clumped Moss",
            },
            ids = {
              82777,
            },
            item = "Spell Pack: Clumped Moss",
            spell = "Mossy Vigor",
            spells = {
              "Mossy Vigor",
              "Blessing of Moss",
            },
          },
          Pack3 = {
            aliases = {
              "Spell Pack: Sun's Blistering Corona",
            },
            ids = {
              82778,
            },
            item = "Spell Pack: Sun's Blistering Corona",
            spell = "Sun's Blistering Corona",
            spells = {
              "Sun's Blistering Corona",
            },
          },
          Pack4 = {
            aliases = {
              "Spell: Ascent Frost",
            },
            ids = {
              80757,
            },
            item = "Spell: Ascent Frost",
            spell = "Ascent Frost",
            spell_ids = {
              15153,
            },
            spells = {
              "Ascent Frost",
            },
          },
          Pack5 = {
            aliases = {
              "Spell: Breath of the Ascent",
            },
            ids = {
              78200,
            },
            item = "Spell: Breath of the Ascent",
            spell = "Breath of The Ascent",
            spell_ids = {
              9863,
            },
            spells = {
              "Breath of The Ascent",
            },
          },
          Pack6 = {
            aliases = {
              "Spell: Dawnflame",
            },
            ids = {
              80758,
            },
            item = "Spell: Dawnflame",
            spell = "Dawnflame",
            spell_ids = {
              15156,
            },
            spells = {
              "Dawnflame",
            },
          },
          Pack7 = {
            aliases = {
              "Spell: Lunar Shadow",
            },
            ids = {
              80759,
            },
            item = "Spell: Lunar Shadow",
            spell = "Lunar Shadow",
            spell_ids = {
              15165,
            },
            spells = {
              "Lunar Shadow",
            },
          },
          Pack8 = {
            aliases = {
              "Spell: Nature Seeker's Behest",
            },
            ids = {
              117592,
            },
            item = "Spell: Nature Seeker's Behest",
            spell = "Nature Seeker's Behest",
            spell_ids = {
              10839,
            },
            spells = {
              "Nature Seeker's Behest",
            },
          },
          Pack9 = {
            aliases = {
              "Spell: Sunburst Devotion",
            },
            ids = {
              80756,
            },
            item = "Spell: Sunburst Devotion",
            spell = "Sunburst Devotion",
            spell_ids = {
              15152,
            },
            spells = {
              "Sunburst Devotion",
            },
          },
          Ranged = {
            aliases = {
              "Phial of the First Brood",
            },
            ids = {
              71578,
            },
            item = "Phial of the First Brood",
          },
          RangedAug = {
            aliases = {
              "Crux of the First Brood",
            },
            ids = {
              60535,
            },
            item = "Crux of the First Brood",
          },
          Shadow = {
            aliases = {
              "Shadow of a Legendary Druid Staff",
              "Staff of Nature's Soul",
            },
            identities = {
              rewards = {
                {
                  id = 56493,
                  name = "Staff of Nature's Soul",
                },
              },
              shadow_component = {
                id = 60548,
                name = "Shadow of a Legendary Druid Staff",
              },
            },
            ids = {
              60548,
              56493,
            },
            item = "Shadow of a Legendary Druid Staff",
          },
          Shoulder = {
            aliases = {
              "Obsidian Pauldrons",
            },
            ids = {
              71666,
            },
            item = "Obsidian Pauldrons",
          },
          Waist = {
            aliases = {
              "Windwatcher Sash",
            },
            ids = {
              71621,
            },
            item = "Windwatcher Sash",
          },
          Wrist1 = {
            aliases = {
              "Keeper's Ascendant Wristband of the Tangled Briars",
            },
            ids = {
              57163,
            },
            item = "Keeper's Ascendant Wristband of the Tangled Briars",
          },
          Wrist2 = {
            aliases = {
              "Keeper's Eternal Bracer of the Tangled Briars",
            },
            ids = {
              57179,
            },
            item = "Keeper's Eternal Bracer of the Tangled Briars",
          },
        },
        Enchanter = {
          Arms = {
            aliases = {
              "Keeper's Ascendant Armguards of Coercion",
            },
            ids = {
              60505,
            },
            item = "Keeper's Ascendant Armguards of Coercion",
          },
          Aug19 = {
            aliases = {
              "Mental Prowess",
              "Cryptic Clutch of Mental Prowess",
              "Vacant Vessel of Mental Prowess",
            },
            ids = {
              62559,
              66720,
            },
            item = "Mental Prowess",
            notes = "No focus effect | +10 hINT, +10 hWIS, +10 heroic resists",
          },
          Back = {
            aliases = {
              "Shroud of the Surging Storm",
            },
            ids = {
              71656,
            },
            item = "Shroud of the Surging Storm",
          },
          Chest = {
            aliases = {
              "Keeper's Ascendant Vest of Coercion",
            },
            ids = {
              60504,
            },
            item = "Keeper's Ascendant Vest of Coercion",
          },
          Clicky1 = {
            aliases = {
              "Icon of Ancient Boon",
            },
            ids = {
              56758,
            },
            item = "Icon of Ancient Boon",
          },
          Clicky2 = {
            aliases = {
              "Icon of Scribe's Endurance",
            },
            ids = {
              56756,
            },
            item = "Icon of Scribe's Endurance",
          },
          Clicky3 = {
            aliases = {
              "Icon of the Ancient Scribe",
            },
            ids = {
              57143,
            },
            item = "Icon of the Ancient Scribe",
          },
          Ear1 = {
            aliases = {
              "Hoop of the Drakeborn",
            },
            ids = {
              71574,
            },
            item = "Hoop of the Drakeborn",
          },
          Ear2 = {
            aliases = {
              "Grelian Earring of Uncertainty",
            },
            ids = {
              71603,
            },
            item = "Grelian Earring of Uncertainty",
          },
          Face = {
            aliases = {
              "Entrancing Silk Veil",
            },
            ids = {
              71643,
            },
            item = "Entrancing Silk Veil",
          },
          Feet = {
            aliases = {
              "Keeper's Ascendant Shoes of Coercion",
            },
            ids = {
              60509,
            },
            item = "Keeper's Ascendant Shoes of Coercion",
          },
          Finger1 = {
            aliases = {
              "Thought Sieve Ring",
            },
            ids = {
              71625,
            },
            item = "Thought Sieve Ring",
          },
          Finger2 = {
            aliases = {
              "Stormeye Band",
            },
            ids = {
              71658,
            },
            item = "Stormeye Band",
          },
          Glyph1 = {
            aliases = {
              "Mnemonic Glyph: Seer's Intuition",
            },
            ids = {
              79529,
            },
            item = "Mnemonic Glyph: Seer's Intuition",
          },
          Glyph2 = {
            aliases = {
              "Mnemonic Glyph: Voice of Intuition",
            },
            ids = {
              79530,
            },
            item = "Mnemonic Glyph: Voice of Intuition",
          },
          Glyph3 = {
            aliases = {
              "Mnemonic Glyph: Speed of Ellowind",
            },
            ids = {
              79531,
            },
            item = "Mnemonic Glyph: Speed of Ellowind",
          },
          Glyph4 = {
            aliases = {
              "Mnemonic Glyph: Hastening of Ellowind",
            },
            ids = {
              79532,
            },
            item = "Mnemonic Glyph: Hastening of Ellowind",
          },
          Glyph5 = {
            aliases = {
              "Mnemonic Glyph: Presidio of the Seer",
            },
            ids = {
              79533,
            },
            item = "Mnemonic Glyph: Presidio of the Seer",
          },
          Glyph6 = {
            aliases = {
              "Imbued Glyph: Edict of Tashan",
            },
            ids = {
              79534,
            },
            item = "Imbued Glyph: Edict of Tashan",
          },
          Hands = {
            aliases = {
              "Keeper's Ascendant Handguards of Coercion",
            },
            ids = {
              60507,
            },
            item = "Keeper's Ascendant Handguards of Coercion",
          },
          Head = {
            aliases = {
              "Keeper's Ascendant Skullcap of Coercion",
            },
            ids = {
              60503,
            },
            item = "Keeper's Ascendant Skullcap of Coercion",
          },
          Legs = {
            aliases = {
              "Keeper's Ascendant Leggings of Coercion",
            },
            ids = {
              60508,
            },
            item = "Keeper's Ascendant Leggings of Coercion",
          },
          Neck = {
            aliases = {
              "Choker of One Hundred Diamonds",
            },
            ids = {
              71651,
            },
            item = "Choker of One Hundred Diamonds",
          },
          Pack1 = {
            aliases = {
              "Spell Pack: Intuition",
            },
            ids = {
              82801,
            },
            item = "Spell Pack: Intuition",
            spell = "Seer's Intuition",
            spells = {
              "Seer's Intuition",
              "Voice of Intuition",
            },
          },
          Pack2 = {
            aliases = {
              "Spell Pack: Ellowind Hastening",
            },
            ids = {
              82802,
            },
            item = "Spell Pack: Ellowind Hastening",
            spell = "Speed of Ellowind",
            spells = {
              "Speed of Ellowind",
              "Hastening of Ellowind",
            },
          },
          Pack3 = {
            aliases = {
              "Spell Pack: Presidio of the Seer",
            },
            ids = {
              82803,
            },
            item = "Spell Pack: Presidio of the Seer",
            spell = "Presidio of the Seer",
            spells = {
              "Presidio of the Seer",
            },
          },
          Pack4 = {
            aliases = {
              "Spell Pack: Edict of Tashan",
            },
            ids = {
              82804,
            },
            item = "Spell Pack: Edict of Tashan",
            spell = "Edict of Tashan",
            spells = {
              "Edict of Tashan",
            },
          },
          Pack5 = {
            aliases = {
              "Spell: Boon of the Sentinel",
            },
            ids = {
              50149,
            },
            item = "Spell: Boon of the Sentinel",
            spell = "Boon of the Sentinel",
            spell_ids = {
              10902,
            },
            spells = {
              "Boon of the Sentinel",
            },
          },
          Pack6 = {
            aliases = {
              "Spell: Chromatic Chaos",
            },
            ids = {
              80781,
            },
            item = "Spell: Chromatic Chaos",
            spell = "Chromatic Chaos",
            spell_ids = {
              15212,
            },
            spells = {
              "Chromatic Chaos",
            },
          },
          Pack7 = {
            aliases = {
              "Spell: Hysteria",
            },
            ids = {
              80783,
            },
            item = "Spell: Hysteria",
            spell = "Hysteria",
            spell_ids = {
              15216,
            },
            spells = {
              "Hysteria",
            },
          },
          Pack8 = {
            aliases = {
              "Spell: Urgent Rune of Destiny",
            },
            ids = {
              80782,
            },
            item = "Spell: Urgent Rune of Destiny",
            spell = "Urgent Rune of Destiny",
            spell_ids = {
              15213,
            },
            spells = {
              "Urgent Rune of Destiny",
            },
          },
          Pack9 = {
            aliases = {
              "Spell: Whispers of Emoush",
            },
            ids = {
              80780,
            },
            item = "Spell: Whispers of Emoush",
            spell = "Whispers of Emoush",
            spell_ids = {
              10656,
            },
            spells = {
              "Whispers of Emoush",
            },
          },
          Ranged = {
            aliases = {
              "Spark of the Skies",
            },
            ids = {
              60536,
            },
            item = "Spark of the Skies",
          },
          RangedAug = {
            aliases = {
              "Core of the Skies",
            },
            ids = {
              71659,
            },
            item = "Core of the Skies",
          },
          Shadow = {
            aliases = {
              "Shadow of a Legendary Enchanter Shield",
              "Shield of the Savvy Psyche",
            },
            identities = {
              rewards = {
                {
                  id = 56501,
                  name = "Shield of the Savvy Psyche",
                },
              },
              shadow_component = {
                id = 62531,
                name = "Shadow of a Legendary Enchanter Shield",
              },
            },
            ids = {
              62531,
              56501,
            },
            item = "Shadow of a Legendary Enchanter Shield",
          },
          Shoulder = {
            aliases = {
              "Brimstone Spaulders",
            },
            ids = {
              71635,
            },
            item = "Brimstone Spaulders",
          },
          Waist = {
            aliases = {
              "Sash of Frigidity",
            },
            ids = {
              71650,
            },
            item = "Sash of Frigidity",
          },
          Wrist1 = {
            aliases = {
              "Keeper's Ascendant Bracer of Coercion",
            },
            ids = {
              60506,
            },
            item = "Keeper's Ascendant Bracer of Coercion",
          },
          Wrist2 = {
            aliases = {
              "Keeper's Eternal Bracer of Coercion",
            },
            ids = {
              60510,
            },
            item = "Keeper's Eternal Bracer of Coercion",
          },
        },
        Magician = {
          Arms = {
            aliases = {
              "Keeper's Ascendant Sleeves of the Summoner",
            },
            ids = {
              60475,
            },
            item = "Keeper's Ascendant Sleeves of the Summoner",
          },
          Aug19 = {
            aliases = {
              "Mental Prowess",
              "Cryptic Clutch of Mental Prowess",
              "Vacant Vessel of Mental Prowess",
            },
            ids = {
              62559,
              66720,
            },
            item = "Mental Prowess",
            notes = "No focus effect | +10 hINT, +10 hWIS, +10 heroic resists",
          },
          Back = {
            aliases = {
              "Shroud of the Surging Storm",
            },
            ids = {
              71656,
            },
            item = "Shroud of the Surging Storm",
          },
          Chest = {
            aliases = {
              "Keeper's Ascendant Tunic of the Summoner",
            },
            ids = {
              60474,
            },
            item = "Keeper's Ascendant Tunic of the Summoner",
          },
          Clicky1 = {
            aliases = {
              "Icon of Ancient Boon",
            },
            ids = {
              56758,
            },
            item = "Icon of Ancient Boon",
          },
          Clicky2 = {
            aliases = {
              "Icon of Scribe's Endurance",
            },
            ids = {
              56756,
            },
            item = "Icon of Scribe's Endurance",
          },
          Clicky3 = {
            aliases = {
              "Icon of the Ancient Scribe",
            },
            ids = {
              57143,
            },
            item = "Icon of the Ancient Scribe",
          },
          Ear1 = {
            aliases = {
              "Hoop of the Drakeborn",
            },
            ids = {
              71574,
            },
            item = "Hoop of the Drakeborn",
          },
          Ear2 = {
            aliases = {
              "Grelian Earring of Uncertainty",
            },
            ids = {
              71603,
            },
            item = "Grelian Earring of Uncertainty",
          },
          Face = {
            aliases = {
              "Entrancing Silk Veil",
            },
            ids = {
              71643,
            },
            item = "Entrancing Silk Veil",
          },
          Feet = {
            aliases = {
              "Keeper's Ascendant Slippers of the Summoner",
            },
            ids = {
              60501,
            },
            item = "Keeper's Ascendant Slippers of the Summoner",
          },
          Finger1 = {
            aliases = {
              "Thought Sieve Ring",
            },
            ids = {
              71625,
            },
            item = "Thought Sieve Ring",
          },
          Finger2 = {
            aliases = {
              "Stormeye Band",
            },
            ids = {
              71658,
            },
            item = "Stormeye Band",
          },
          Glyph1 = {
            aliases = {
              "Mnemonic Glyph: Ward of the Conjurer",
            },
            ids = {
              79524,
            },
            item = "Mnemonic Glyph: Ward of the Conjurer",
          },
          Glyph2 = {
            aliases = {
              "Mnemonic Glyph: Circle of Magmaskin",
            },
            ids = {
              79525,
            },
            item = "Mnemonic Glyph: Circle of Magmaskin",
          },
          Glyph3 = {
            aliases = {
              "Imbued Glyph: Goner's Urgent Renewal",
            },
            ids = {
              79526,
            },
            item = "Imbued Glyph: Goner's Urgent Renewal",
          },
          Hands = {
            aliases = {
              "Keeper's Ascendant Gloves of the Summoner",
            },
            ids = {
              60477,
            },
            item = "Keeper's Ascendant Gloves of the Summoner",
          },
          Head = {
            aliases = {
              "Keeper's Ascendant Hat of the Summoner",
            },
            ids = {
              60473,
            },
            item = "Keeper's Ascendant Hat of the Summoner",
          },
          Legs = {
            aliases = {
              "Keeper's Ascendant Leggings of the Summoner",
            },
            ids = {
              60500,
            },
            item = "Keeper's Ascendant Leggings of the Summoner",
          },
          Neck = {
            aliases = {
              "Choker of One Hundred Diamonds",
            },
            ids = {
              71651,
            },
            item = "Choker of One Hundred Diamonds",
          },
          Pack1 = {
            aliases = {
              "Spell Pack: Ward of the Conjurer",
            },
            ids = {
              82798,
            },
            item = "Spell Pack: Ward of the Conjurer",
            spell = "Ward of the Conjurer",
            spells = {
              "Ward of the Conjurer",
            },
          },
          Pack2 = {
            aliases = {
              "Spell Pack: Circle of Magmaskin",
            },
            ids = {
              82799,
            },
            item = "Spell Pack: Circle of Magmaskin",
            spell = "Circle of Magmaskin",
            spells = {
              "Circle of Magmaskin",
            },
          },
          Pack3 = {
            aliases = {
              "Spell Pack: Goner's Urgent Renewal",
            },
            ids = {
              82800,
            },
            item = "Spell Pack: Goner's Urgent Renewal",
            spell = "Goner's Urgent Renewal",
            spells = {
              "Goner's Urgent Renewal",
            },
          },
          Pack4 = {
            aliases = {
              "Spell: Blade Rend",
            },
            ids = {
              80766,
            },
            item = "Spell: Blade Rend",
            spell = "Blade Rend",
            spell_ids = {
              15191,
            },
            spells = {
              "Blade Rend",
            },
          },
          Pack5 = {
            aliases = {
              "Spell: Burning Bladestorm",
            },
            ids = {
              50144,
            },
            item = "Spell: Burning Bladestorm",
            spell = "Burning Bladestorm",
            spell_ids = {
              10890,
            },
            spells = {
              "Burning Bladestorm",
            },
          },
          Pack6 = {
            aliases = {
              "Spell: Fickle Inferno",
            },
            ids = {
              79091,
            },
            item = "Spell: Fickle Inferno",
            spell = "Fickle Inferno",
            spell_ids = {
              10754,
            },
            spells = {
              "Fickle Inferno",
            },
          },
          Pack7 = {
            aliases = {
              "Spell: Frantic Blaze",
            },
            ids = {
              80764,
            },
            item = "Spell: Frantic Blaze",
            spell = "Frantic Blaze",
            spell_ids = {
              15182,
            },
            spells = {
              "Frantic Blaze",
            },
          },
          Pack8 = {
            aliases = {
              "Spell: Grant Battle Materiel",
            },
            ids = {
              80779,
            },
            item = "Spell: Grant Battle Materiel",
            spell = "Grant Battle Materiel",
            spell_ids = {
              15192,
            },
            spells = {
              "Grant Battle Materiel",
            },
          },
          Pack9 = {
            aliases = {
              "Spell: Monolithic Strength",
            },
            ids = {
              80765,
            },
            item = "Spell: Monolithic Strength",
            spell = "Monolithic Strength",
            spell_ids = {
              15188,
            },
            spells = {
              "Monolithic Strength",
            },
          },
          Ranged = {
            aliases = {
              "Spark of the Skies",
            },
            ids = {
              60536,
            },
            item = "Spark of the Skies",
          },
          RangedAug = {
            aliases = {
              "Core of the Skies",
            },
            ids = {
              71659,
            },
            item = "Core of the Skies",
          },
          Shadow = {
            aliases = {
              "Shadow of a Legendary Magician Staff",
              "Stave of Searing Slag",
            },
            identities = {
              rewards = {
                {
                  id = 56500,
                  name = "Stave of Searing Slag",
                },
              },
              shadow_component = {
                id = 62530,
                name = "Shadow of a Legendary Magician Staff",
              },
            },
            ids = {
              62530,
              56500,
            },
            item = "Shadow of a Legendary Magician Staff",
          },
          Shoulder = {
            aliases = {
              "Brimstone Spaulders",
            },
            ids = {
              71635,
            },
            item = "Brimstone Spaulders",
          },
          Waist = {
            aliases = {
              "Sash of Frigidity",
            },
            ids = {
              71650,
            },
            item = "Sash of Frigidity",
          },
          Wrist1 = {
            aliases = {
              "Keeper's Ascendant Wristband of the Summoner",
            },
            ids = {
              60476,
            },
            item = "Keeper's Ascendant Wristband of the Summoner",
          },
          Wrist2 = {
            aliases = {
              "Keeper's Eternal Bracer of the Summoner",
            },
            ids = {
              60502,
            },
            item = "Keeper's Eternal Bracer of the Summoner",
          },
        },
        Monk = {
          Arms = {
            aliases = {
              "Keeper's Ascendant Sleeves of the Focused",
            },
            ids = {
              57711,
            },
            item = "Keeper's Ascendant Sleeves of the Focused",
          },
          Aug19 = {
            aliases = {
              "Physical Prowess",
              "Cryptic Clutch of Physical Prowess",
              "Vacant Vessel of Physical Prowess",
            },
            ids = {
              62558,
              66533,
            },
            item = "Physical Prowess",
            notes = "No focus effect | +5 hSTR, +5 hSTA, +5 hAGI, +5 hDEX",
          },
          Back = {
            aliases = {
              "Cloak of Deepshadow",
            },
            ids = {
              71665,
            },
            item = "Cloak of Deepshadow",
          },
          Chest = {
            aliases = {
              "Keeper's Ascendant Shroud of the Focused",
            },
            ids = {
              57234,
            },
            item = "Keeper's Ascendant Shroud of the Focused",
          },
          Clicky1 = {
            aliases = {
              "Icon of Ancient Boon",
            },
            ids = {
              56758,
            },
            item = "Icon of Ancient Boon",
          },
          Clicky2 = {
            aliases = {
              "Icon of Potent Prowess",
            },
            ids = {
              56757,
            },
            item = "Icon of Potent Prowess",
          },
          Clicky3 = {
            aliases = {
              "Icon of Ancient Prowess",
            },
            ids = {
              57142,
            },
            item = "Icon of Ancient Prowess",
          },
          Ear1 = {
            aliases = {
              "Cloudkiller's Bauble",
            },
            ids = {
              71584,
            },
            item = "Cloudkiller's Bauble",
          },
          Ear2 = {
            aliases = {
              "Accursed Earhoop of Pain",
            },
            ids = {
              71668,
            },
            item = "Accursed Earhoop of Pain",
          },
          Face = {
            aliases = {
              "Mask of the Dawn Scorcher",
            },
            ids = {
              71626,
            },
            item = "Mask of the Dawn Scorcher",
          },
          Feet = {
            aliases = {
              "Keeper's Ascendant Tabis of the Focused",
            },
            ids = {
              59357,
            },
            item = "Keeper's Ascendant Tabis of the Focused",
          },
          Finger1 = {
            aliases = {
              "Glimmering Fire Opal Band",
            },
            ids = {
              71634,
            },
            item = "Glimmering Fire Opal Band",
          },
          Finger2 = {
            aliases = {
              "Bloodstained Ring of Evisceration",
            },
            ids = {
              71588,
            },
            item = "Bloodstained Ring of Evisceration",
          },
          Glyph1 = {
            aliases = {
              "Imbued Glyph: Ancient: Arachnid Fang",
            },
            ids = {
              80074,
            },
            item = "Imbued Glyph: Ancient: Arachnid Fang",
          },
          Hands = {
            aliases = {
              "Keeper's Ascendant Gloves of the Focused",
            },
            ids = {
              59169,
            },
            item = "Keeper's Ascendant Gloves of the Focused",
          },
          Head = {
            aliases = {
              "Keeper's Ascendant Cap of the Focused",
            },
            ids = {
              57233,
            },
            item = "Keeper's Ascendant Cap of the Focused",
          },
          Legs = {
            aliases = {
              "Keeper's Ascendant Leggings of the Focused",
            },
            ids = {
              59170,
            },
            item = "Keeper's Ascendant Leggings of the Focused",
          },
          Neck = {
            aliases = {
              "Necklace of Sandstorms",
            },
            ids = {
              71612,
            },
            item = "Necklace of Sandstorms",
          },
          Pack1 = {
            aliases = {
              "Tome Pack: Ancient: Arachnid Fang",
            },
            ids = {
              82655,
            },
            item = "Tome Pack: Ancient: Arachnid Fang",
            spell = "Ancient: Arachnid Fang",
            spells = {
              "Ancient: Arachnid Fang",
            },
          },
          Pack10 = {
            aliases = {
              "Tome of Wheel of Fists",
            },
            ids = {
              88901,
            },
            item = "Tome of Wheel of Fists",
            spell = "Wheel of Fists",
            spell_ids = {
              14797,
            },
            spells = {
              "Wheel of Fists",
            },
          },
          Pack2 = {
            aliases = {
              "Tome of Arcane Reprisal",
            },
            ids = {
              79226,
            },
            item = "Tome of Arcane Reprisal",
            spell = "Arcane Reprisal",
            spell_ids = {
              10889,
            },
            spells = {
              "Arcane Reprisal",
            },
          },
          Pack3 = {
            aliases = {
              "Tome of Dragondance Discipline",
            },
            ids = {
              88921,
            },
            item = "Tome of Dragondance Discipline",
            spell = "Dragondance Discipline",
            spell_ids = {
              15113,
            },
            spells = {
              "Dragondance Discipline",
            },
          },
          Pack4 = {
            aliases = {
              "Tome of Fists of Thundercrest",
            },
            ids = {
              50117,
            },
            item = "Tome of Fists of Thundercrest",
            spell = "Fists of Thundercrest",
            spell_ids = {
              10854,
            },
            spells = {
              "Fists of Thundercrest",
            },
          },
          Pack5 = {
            aliases = {
              "Tome of Fourth Wind",
            },
            ids = {
              80081,
            },
            item = "Tome of Fourth Wind",
            spell = "Fourth Wind Discipline",
            spell_ids = {
              15134,
            },
            spells = {
              "Fourth Wind Discipline",
            },
          },
          Pack6 = {
            aliases = {
              "Tome of Grandmaster's Aura",
            },
            ids = {
              80078,
            },
            item = "Tome of Grandmaster's Aura",
            spell = "Grandmaster's Aura",
            spell_ids = {
              15095,
            },
            spells = {
              "Grandmaster's Aura",
            },
          },
          Pack7 = {
            aliases = {
              "Tome of Phantom Whispers",
            },
            ids = {
              118654,
            },
            item = "Tome of Phantom Whispers",
            spell = "Phantom Whispers",
            spell_ids = {
              18904,
            },
            spells = {
              "Phantom Whispers",
            },
          },
          Pack8 = {
            aliases = {
              "Tome of Stormfist Discipline",
            },
            ids = {
              79445,
            },
            item = "Tome of Stormfist Discipline",
            spell = "Stormfist Discipline",
            spell_ids = {
              11923,
            },
            spells = {
              "Stormfist Discipline",
            },
          },
          Pack9 = {
            aliases = {
              "Tome of Velocity Focus",
            },
            ids = {
              80083,
            },
            item = "Tome of Velocity Focus",
            spell = "Velocity Focus Discipline",
            spell_ids = {
              15101,
            },
            spells = {
              "Velocity Focus Discipline",
            },
          },
          Ranged = {
            aliases = {
              "Head of the Putrid Drake",
            },
            ids = {
              55052,
            },
            item = "Head of the Putrid Drake",
          },
          RangedAug = {
            aliases = {
              "Preserved Eye of the Putrid Drake",
            },
            ids = {
              71620,
            },
            item = "Preserved Eye of the Putrid Drake",
          },
          Shadow = {
            aliases = {
              "Shadow of a Legendary Monk Weapon",
              "Phantom, the Storm Child",
            },
            identities = {
              rewards = {
                {
                  id = 56495,
                  name = "Phantom, the Storm Child",
                },
              },
              shadow_component = {
                id = 60549,
                name = "Shadow of a Legendary Monk Weapon",
              },
            },
            ids = {
              60549,
              56495,
            },
            item = "Shadow of a Legendary Monk Weapon",
          },
          Shoulder = {
            aliases = {
              "Lightning Singed Mantle",
            },
            ids = {
              71654,
            },
            item = "Lightning Singed Mantle",
          },
          Waist = {
            aliases = {
              "Thundercrash Girdle",
            },
            ids = {
              71657,
            },
            item = "Thundercrash Girdle",
          },
          Wrist1 = {
            aliases = {
              "Keeper's Ascendant Wristband of the Focused",
            },
            ids = {
              59168,
            },
            item = "Keeper's Ascendant Wristband of the Focused",
          },
          Wrist2 = {
            aliases = {
              "Keeper's Eternal Bracer of the Focused",
            },
            ids = {
              59358,
            },
            item = "Keeper's Eternal Bracer of the Focused",
          },
        },
        Necromancer = {
          Arms = {
            aliases = {
              "Keeper's Ascendant Armband of the Grave",
            },
            ids = {
              60513,
            },
            item = "Keeper's Ascendant Armband of the Grave",
          },
          Aug19 = {
            aliases = {
              "Mental Prowess",
              "Cryptic Clutch of Mental Prowess",
              "Vacant Vessel of Mental Prowess",
            },
            ids = {
              62559,
              66720,
            },
            item = "Mental Prowess",
            notes = "No focus effect | +10 hINT, +10 hWIS, +10 heroic resists",
          },
          Back = {
            aliases = {
              "Shroud of the Surging Storm",
            },
            ids = {
              71656,
            },
            item = "Shroud of the Surging Storm",
          },
          Chest = {
            aliases = {
              "Keeper's Ascendant Tunic of the Grave",
            },
            ids = {
              60512,
            },
            item = "Keeper's Ascendant Tunic of the Grave",
          },
          Clicky1 = {
            aliases = {
              "Icon of Ancient Boon",
            },
            ids = {
              56758,
            },
            item = "Icon of Ancient Boon",
          },
          Clicky2 = {
            aliases = {
              "Icon of Scribe's Endurance",
            },
            ids = {
              56756,
            },
            item = "Icon of Scribe's Endurance",
          },
          Clicky3 = {
            aliases = {
              "Icon of the Ancient Scribe",
            },
            ids = {
              57143,
            },
            item = "Icon of the Ancient Scribe",
          },
          Ear1 = {
            aliases = {
              "Hoop of the Drakeborn",
            },
            ids = {
              71574,
            },
            item = "Hoop of the Drakeborn",
          },
          Ear2 = {
            aliases = {
              "Grelian Earring of Uncertainty",
            },
            ids = {
              71603,
            },
            item = "Grelian Earring of Uncertainty",
          },
          Face = {
            aliases = {
              "Entrancing Silk Veil",
            },
            ids = {
              71643,
            },
            item = "Entrancing Silk Veil",
          },
          Feet = {
            aliases = {
              "Keeper's Ascendant Sandals of the Grave",
            },
            ids = {
              60517,
            },
            item = "Keeper's Ascendant Sandals of the Grave",
          },
          Finger1 = {
            aliases = {
              "Thought Sieve Ring",
            },
            ids = {
              71625,
            },
            item = "Thought Sieve Ring",
          },
          Finger2 = {
            aliases = {
              "Stormeye Band",
            },
            ids = {
              71658,
            },
            item = "Stormeye Band",
          },
          Glyph1 = {
            aliases = {
              "Mnemonic Glyph: Sacrilege of the Wraith",
            },
            ids = {
              79527,
            },
            item = "Mnemonic Glyph: Sacrilege of the Wraith",
          },
          Glyph2 = {
            aliases = {
              "Mnemonic Glyph: Dull Agony",
            },
            ids = {
              79528,
            },
            item = "Mnemonic Glyph: Dull Agony",
          },
          Glyph3 = {
            aliases = {
              "Imbued Glyph: Goner's Urgent Renewal",
            },
            ids = {
              79526,
            },
            item = "Imbued Glyph: Goner's Urgent Renewal",
          },
          Hands = {
            aliases = {
              "Keeper's Ascendant Handguards of the Grave",
            },
            ids = {
              60515,
            },
            item = "Keeper's Ascendant Handguards of the Grave",
          },
          Head = {
            aliases = {
              "Keeper's Ascendant Cap of the Grave",
            },
            ids = {
              60511,
            },
            item = "Keeper's Ascendant Cap of the Grave",
          },
          Legs = {
            aliases = {
              "Keeper's Ascendant Pants of the Grave",
            },
            ids = {
              60516,
            },
            item = "Keeper's Ascendant Pants of the Grave",
          },
          Neck = {
            aliases = {
              "Choker of One Hundred Diamonds",
            },
            ids = {
              71651,
            },
            item = "Choker of One Hundred Diamonds",
          },
          Pack1 = {
            aliases = {
              "Spell Pack: Sacrilege of the Wraith",
            },
            ids = {
              82805,
            },
            item = "Spell Pack: Sacrilege of the Wraith",
            spell = "Sacrilege of the Wraith",
            spells = {
              "Sacrilege of the Wraith",
            },
          },
          Pack2 = {
            aliases = {
              "Spell Pack: Dull Agony",
            },
            ids = {
              82806,
            },
            item = "Spell Pack: Dull Agony",
            spell = "Dull Agony",
            spells = {
              "Dull Agony",
            },
          },
          Pack3 = {
            aliases = {
              "Spell Pack: Goner's Urgent Renewal",
            },
            ids = {
              82800,
            },
            item = "Spell Pack: Goner's Urgent Renewal",
            spell = "Goner's Urgent Renewal",
            spells = {
              "Goner's Urgent Renewal",
            },
          },
          Pack4 = {
            aliases = {
              "Spell: Malignant Plague",
            },
            ids = {
              80786,
            },
            item = "Spell: Malignant Plague",
            spell = "Malignant Plague",
            spell_ids = {
              15230,
            },
            spells = {
              "Malignant Plague",
            },
          },
          Pack5 = {
            aliases = {
              "Spell: Molten Pyre",
            },
            ids = {
              80785,
            },
            item = "Spell: Molten Pyre",
            spell = "Molten Pyre",
            spell_ids = {
              15225,
            },
            spells = {
              "Molten Pyre",
            },
          },
          Pack6 = {
            aliases = {
              "Spell: Pestilent Pustules",
            },
            ids = {
              119599,
            },
            item = "Spell: Pestilent Pustules",
            spell = "Pestilent Pustules",
            spell_ids = {
              10906,
            },
            spells = {
              "Pestilent Pustules",
            },
          },
          Pack7 = {
            aliases = {
              "Spell: Ritual of Blood",
            },
            ids = {
              78819,
            },
            item = "Spell: Ritual of Blood",
            spell = "Ritual of Blood",
            spell_ids = {
              10482,
            },
            spells = {
              "Ritual of Blood",
            },
          },
          Pack8 = {
            aliases = {
              "Spell: Venom of the Accursed Nest",
            },
            ids = {
              78892,
            },
            item = "Spell: Venom of the Accursed Nest",
            spell = "Venom of the Accursed Nest",
            spell_ids = {
              10555,
            },
            spells = {
              "Venom of the Accursed Nest",
            },
          },
          Pack9 = {
            aliases = {
              "Spell: Yearning of Death",
            },
            ids = {
              80784,
            },
            item = "Spell: Yearning of Death",
            spell = "Yearning of Death",
            spell_ids = {
              15222,
            },
            spells = {
              "Yearning of Death",
            },
          },
          Ranged = {
            aliases = {
              "Spark of the Skies",
            },
            ids = {
              60536,
            },
            item = "Spark of the Skies",
          },
          RangedAug = {
            aliases = {
              "Core of the Skies",
            },
            ids = {
              71659,
            },
            item = "Core of the Skies",
          },
          Shadow = {
            aliases = {
              "Shadow of a Legendary Necromancer Shield",
              "Shadowed Shield of Corruption",
            },
            identities = {
              rewards = {
                {
                  id = 56752,
                  name = "Shadowed Shield of Corruption",
                },
              },
              shadow_component = {
                id = 62532,
                name = "Shadow of a Legendary Necromancer Shield",
              },
            },
            ids = {
              62532,
              56752,
            },
            item = "Shadow of a Legendary Necromancer Shield",
          },
          Shoulder = {
            aliases = {
              "Brimstone Spaulders",
            },
            ids = {
              71635,
            },
            item = "Brimstone Spaulders",
          },
          Waist = {
            aliases = {
              "Sash of Frigidity",
            },
            ids = {
              71650,
            },
            item = "Sash of Frigidity",
          },
          Wrist1 = {
            aliases = {
              "Keeper's Ascendant Bracer of the Grave",
            },
            ids = {
              60514,
            },
            item = "Keeper's Ascendant Bracer of the Grave",
          },
          Wrist2 = {
            aliases = {
              "Keeper's Eternal Bracer of the Grave",
            },
            ids = {
              60518,
            },
            item = "Keeper's Eternal Bracer of the Grave",
          },
        },
        Paladin = {
          Arms = {
            aliases = {
              "Keeper's Ascendant Sleeves of the Defender",
            },
            ids = {
              54962,
            },
            item = "Keeper's Ascendant Sleeves of the Defender",
          },
          Aug19 = {
            aliases = {
              "Physical Prowess",
              "Cryptic Clutch of Physical Prowess",
              "Vacant Vessel of Physical Prowess",
            },
            ids = {
              62558,
              66533,
            },
            item = "Physical Prowess",
            notes = "No focus effect | +5 hSTR, +5 hSTA, +5 hAGI, +5 hDEX",
          },
          Back = {
            aliases = {
              "Cape of Dragon Scales",
            },
            ids = {
              71596,
            },
            item = "Cape of Dragon Scales",
          },
          Chest = {
            aliases = {
              "Keeper's Ascendant Chestpiece of the Defender",
            },
            ids = {
              54961,
            },
            item = "Keeper's Ascendant Chestpiece of the Defender",
          },
          Clicky1 = {
            aliases = {
              "Icon of Ancient Boon",
            },
            ids = {
              56758,
            },
            item = "Icon of Ancient Boon",
          },
          Clicky2 = {
            aliases = {
              "Icon of Unwavering Defense",
            },
            ids = {
              56755,
            },
            item = "Icon of Unwavering Defense",
          },
          Clicky3 = {
            aliases = {
              "Icon of Ancient Defense",
            },
            ids = {
              57141,
            },
            item = "Icon of Ancient Defense",
          },
          Ear1 = {
            aliases = {
              "Weighted Loop of Eternal Battle",
            },
            ids = {
              71624,
            },
            item = "Weighted Loop of Eternal Battle",
          },
          Ear2 = {
            aliases = {
              "Hoop of the Nest Defender",
            },
            ids = {
              71593,
            },
            item = "Hoop of the Nest Defender",
          },
          Face = {
            aliases = {
              "Face of Unfeeling",
            },
            ids = {
              71667,
            },
            item = "Face of Unfeeling",
          },
          Feet = {
            aliases = {
              "Keeper's Ascendant Boots of the Defender",
            },
            ids = {
              55037,
            },
            item = "Keeper's Ascendant Boots of the Defender",
          },
          Finger1 = {
            aliases = {
              "Ring of Unsung Legends",
            },
            ids = {
              71608,
            },
            item = "Ring of Unsung Legends",
          },
          Finger2 = {
            aliases = {
              "Ring of Living Malachite",
            },
            ids = {
              71562,
            },
            item = "Ring of Living Malachite",
          },
          Glyph1 = {
            aliases = {
              "Mnemonic Glyph: Armor of the Savior",
            },
            ids = {
              79538,
            },
            item = "Mnemonic Glyph: Armor of the Savior",
          },
          Glyph2 = {
            aliases = {
              "Mnemonic Glyph: Virtuous Fervor",
            },
            ids = {
              79539,
            },
            item = "Mnemonic Glyph: Virtuous Fervor",
          },
          Glyph3 = {
            aliases = {
              "Imbued Glyph: Wave of the Stillmoon",
            },
            ids = {
              79540,
            },
            item = "Imbued Glyph: Wave of the Stillmoon",
          },
          Hands = {
            aliases = {
              "Keeper's Ascendant Mitts of the Defender",
            },
            ids = {
              54964,
            },
            item = "Keeper's Ascendant Mitts of the Defender",
          },
          Head = {
            aliases = {
              "Keeper's Ascendant Coif of the Defender",
            },
            ids = {
              54960,
            },
            item = "Keeper's Ascendant Coif of the Defender",
          },
          Legs = {
            aliases = {
              "Keeper's Ascendant Leggings of the Defender",
            },
            ids = {
              54965,
            },
            item = "Keeper's Ascendant Leggings of the Defender",
          },
          Neck = {
            aliases = {
              "Necklace of Grimspirit Beads",
            },
            ids = {
              71597,
            },
            item = "Necklace of Grimspirit Beads",
          },
          Pack1 = {
            aliases = {
              "Spell Pack: Armor of the Savior",
            },
            ids = {
              82810,
            },
            item = "Spell Pack: Armor of the Savior",
            spell = "Armor of the Savior",
            spells = {
              "Armor of the Savior",
            },
          },
          Pack2 = {
            aliases = {
              "Spell Pack: Virtuous Fervor",
            },
            ids = {
              82811,
            },
            item = "Spell Pack: Virtuous Fervor",
            spell = "Virtuous Fervor",
            spells = {
              "Virtuous Fervor",
            },
          },
          Pack3 = {
            aliases = {
              "Spell Pack: Wave of the Stillmoon",
            },
            ids = {
              82812,
            },
            item = "Spell Pack: Wave of the Stillmoon",
            spell = "Wave of the Stillmoon",
            spells = {
              "Wave of the Stillmoon",
            },
          },
          Pack4 = {
            aliases = {
              "Spell: Benevolent Aura",
            },
            ids = {
              81864,
            },
            item = "Spell: Benevolent Aura",
            spell = "Benevolent Aura",
            spell_ids = {
              15251,
            },
            spells = {
              "Benevolent Aura",
            },
          },
          Pack5 = {
            aliases = {
              "Spell: Brell's Unshakable Barricade",
            },
            ids = {
              81862,
            },
            item = "Spell: Brell's Unshakable Barricade",
            spell = "Brell's Unshakable Barricade",
            spell_ids = {
              15248,
            },
            spells = {
              "Brell's Unshakable Barricade",
            },
          },
          Pack6 = {
            aliases = {
              "Spell: Force of the Sacred",
            },
            ids = {
              81861,
            },
            item = "Spell: Force of the Sacred",
            spell = "Force of the Sacred",
            spell_ids = {
              15240,
            },
            spells = {
              "Force of the Sacred",
            },
          },
          Pack7 = {
            aliases = {
              "Spell: Force of the Sentinel",
            },
            ids = {
              81863,
            },
            item = "Spell: Force of the Sentinel",
            spell = "Force of the Sentinel",
            spell_ids = {
              15249,
            },
            spells = {
              "Force of the Sentinel",
            },
          },
          Pack8 = {
            aliases = {
              "Spell: The Silent Decree",
            },
            ids = {
              78039,
            },
            item = "Spell: The Silent Decree",
            spell = "The Silent Decree",
            spell_ids = {
              10919,
            },
            spells = {
              "The Silent Decree",
            },
          },
          Pack9 = {
            aliases = {
              "Tome of Aegis of Righteousness",
            },
            ids = {
              79399,
            },
            item = "Tome of Aegis of Righteousness",
            spell = "Aegis of Righteousness",
            spell_ids = {
              11854,
            },
            spells = {
              "Aegis of Righteousness",
            },
          },
          Ranged = {
            aliases = {
              "Branch of the Twisting Tree",
            },
            ids = {
              71627,
            },
            item = "Branch of the Twisting Tree",
          },
          RangedAug = {
            aliases = {
              "Fallen Leaf of the Twisting Tree",
            },
            ids = {
              55053,
            },
            item = "Fallen Leaf of the Twisting Tree",
          },
          Shadow = {
            aliases = {
              "Shadow of a Legendary Paladin Shield",
              "Valiant Bulwark of the Storm Dragon",
            },
            identities = {
              rewards = {
                {
                  id = 55078,
                  name = "Valiant Bulwark of the Storm Dragon",
                },
              },
              shadow_component = {
                id = 60545,
                name = "Shadow of a Legendary Paladin Shield",
              },
            },
            ids = {
              60545,
              55078,
            },
            item = "Shadow of a Legendary Paladin Shield",
          },
          Shoulder = {
            aliases = {
              "Dark-Touched Mantle",
            },
            ids = {
              71590,
            },
            item = "Dark-Touched Mantle",
          },
          Waist = {
            aliases = {
              "Belt of the Black Dragon",
            },
            ids = {
              71664,
            },
            item = "Belt of the Black Dragon",
          },
          Wrist1 = {
            aliases = {
              "Keeper's Ascendant Wristguard of the Defender",
            },
            ids = {
              54963,
            },
            item = "Keeper's Ascendant Wristguard of the Defender",
          },
          Wrist2 = {
            aliases = {
              "Keeper's Eternal Bracer of the Defender",
            },
            ids = {
              55050,
            },
            item = "Keeper's Eternal Bracer of the Defender",
          },
        },
        Ranger = {
          Arms = {
            aliases = {
              "Keeper's Ascendant Sleeves of Journeys",
            },
            ids = {
              60521,
            },
            item = "Keeper's Ascendant Sleeves of Journeys",
          },
          Aug19 = {
            aliases = {
              "Physical Prowess",
              "Cryptic Clutch of Physical Prowess",
              "Vacant Vessel of Physical Prowess",
            },
            ids = {
              62558,
              66533,
            },
            item = "Physical Prowess",
            notes = "No focus effect | +5 hSTR, +5 hSTA, +5 hAGI, +5 hDEX",
          },
          Back = {
            aliases = {
              "Shroud of the Surging Storm",
            },
            ids = {
              71656,
            },
            item = "Shroud of the Surging Storm",
          },
          Chest = {
            aliases = {
              "Keeper's Ascendant Vest of Journeys",
            },
            ids = {
              60520,
            },
            item = "Keeper's Ascendant Vest of Journeys",
          },
          Clicky1 = {
            aliases = {
              "Icon of Ancient Boon",
            },
            ids = {
              56758,
            },
            item = "Icon of Ancient Boon",
          },
          Clicky2 = {
            aliases = {
              "Icon of Potent Prowess",
            },
            ids = {
              56757,
            },
            item = "Icon of Potent Prowess",
          },
          Clicky3 = {
            aliases = {
              "Icon of Ancient Prowess",
            },
            ids = {
              57142,
            },
            item = "Icon of Ancient Prowess",
          },
          Ear1 = {
            aliases = {
              "Cloudkiller's Bauble",
            },
            ids = {
              71584,
            },
            item = "Cloudkiller's Bauble",
          },
          Ear2 = {
            aliases = {
              "Grelian Earring of Uncertainty",
            },
            ids = {
              71603,
            },
            item = "Grelian Earring of Uncertainty",
          },
          Face = {
            aliases = {
              "Mask of the Dawn Scorcher",
            },
            ids = {
              71626,
            },
            item = "Mask of the Dawn Scorcher",
          },
          Feet = {
            aliases = {
              "Keeper's Ascendant Boots of Journeys",
            },
            ids = {
              60525,
            },
            item = "Keeper's Ascendant Boots of Journeys",
          },
          Finger1 = {
            aliases = {
              "Glimmering Fire Opal Band",
            },
            ids = {
              71634,
            },
            item = "Glimmering Fire Opal Band",
          },
          Finger2 = {
            aliases = {
              "Stormeye Band",
            },
            ids = {
              71658,
            },
            item = "Stormeye Band",
          },
          Glyph1 = {
            aliases = {
              "Mnemonic Glyph: Snarl of the Predator",
            },
            ids = {
              80063,
            },
            item = "Mnemonic Glyph: Snarl of the Predator",
          },
          Glyph2 = {
            aliases = {
              "Mnemonic Glyph: Guard of Thundercrest",
            },
            ids = {
              80064,
            },
            item = "Mnemonic Glyph: Guard of Thundercrest",
          },
          Glyph3 = {
            aliases = {
              "Mnemonic Glyph: Call of Storms",
            },
            ids = {
              80065,
            },
            item = "Mnemonic Glyph: Call of Storms",
          },
          Glyph4 = {
            aliases = {
              "Imbued Glyph: Jolting Thunderkicks",
            },
            ids = {
              80066,
            },
            item = "Imbued Glyph: Jolting Thunderkicks",
          },
          Hands = {
            aliases = {
              "Keeper's Ascendant Gloves of Journeys",
            },
            ids = {
              60523,
            },
            item = "Keeper's Ascendant Gloves of Journeys",
          },
          Head = {
            aliases = {
              "Keeper's Ascendant Cap of Journeys",
            },
            ids = {
              60519,
            },
            item = "Keeper's Ascendant Cap of Journeys",
          },
          Legs = {
            aliases = {
              "Keeper's Ascendant Legguards of Journeys",
            },
            ids = {
              60524,
            },
            item = "Keeper's Ascendant Legguards of Journeys",
          },
          Neck = {
            aliases = {
              "Choker of One Hundred Diamonds",
            },
            ids = {
              71651,
            },
            item = "Choker of One Hundred Diamonds",
          },
          Pack1 = {
            aliases = {
              "Spell Pack: Snarl of the Predator",
            },
            ids = {
              82813,
            },
            item = "Spell Pack: Snarl of the Predator",
            spell = "Snarl of the Predator",
            spells = {
              "Snarl of the Predator",
            },
          },
          Pack2 = {
            aliases = {
              "Spell Pack: Guard of Thundercrest",
            },
            ids = {
              82814,
            },
            item = "Spell Pack: Guard of Thundercrest",
            spell = "Guard of Thundercrest",
            spells = {
              "Guard of Thundercrest",
            },
          },
          Pack3 = {
            aliases = {
              "Spell Pack: Call of Storms",
            },
            ids = {
              82815,
            },
            item = "Spell Pack: Call of Storms",
            spell = "Call of Storms",
            spells = {
              "Call of Storms",
            },
          },
          Pack4 = {
            aliases = {
              "Tome Pack: Jolting Thunderkicks",
            },
            ids = {
              82816,
            },
            item = "Tome Pack: Jolting Thunderkicks",
            spell = "Jolting Thunderkicks",
            spells = {
              "Jolting Thunderkicks",
            },
          },
          Pack5 = {
            aliases = {
              "Spell Pack: Flame and Frost",
            },
            ids = {
              50150,
            },
            item = "Spell Pack: Flame and Frost",
            spell = "Flame and Frost",
            spells = {
              "Flame and Frost",
            },
          },
          Pack6 = {
            aliases = {
              "Spell: Eyes of the Drake",
            },
            ids = {
              81866,
            },
            item = "Spell: Eyes of the Drake",
            spell = "Eyes of the Drake",
            spell_ids = {
              15255,
            },
            spells = {
              "Eyes of the Drake",
            },
          },
          Pack7 = {
            aliases = {
              "Spell: Heartshatter",
            },
            ids = {
              116082,
            },
            item = "Spell: Heartshatter",
            spell = "Heartshatter",
            spell_ids = {
              15082,
            },
            spells = {
              "Heartshatter",
            },
          },
          Pack8 = {
            aliases = {
              "Spell: Swift Salve of the Stillmoon",
            },
            ids = {
              81867,
            },
            item = "Spell: Swift Salve of the Stillmoon",
            spell = "Swift Salve of the Stillmoon",
            spell_ids = {
              15257,
            },
            spells = {
              "Swift Salve of the Stillmoon",
            },
          },
          Pack9 = {
            aliases = {
              "Spell: Ward of the Stalker",
            },
            ids = {
              81865,
            },
            item = "Spell: Ward of the Stalker",
            spell = "Ward of the Stalker",
            spell_ids = {
              15254,
            },
            spells = {
              "Ward of the Stalker",
            },
          },
          Ranged = {
            aliases = {
              "Branch of the Twisting Tree",
            },
            ids = {
              71627,
            },
            item = "Branch of the Twisting Tree",
          },
          RangedAug = {
            aliases = {
              "Fallen Leaf of the Twisting Tree",
            },
            ids = {
              55053,
            },
            item = "Fallen Leaf of the Twisting Tree",
          },
          Shadow = {
            aliases = {
              "Shadow of a Legendary Ranger Shield",
              "Buckler of the Broodlands Stalker",
              "Bolt of the Storming Sky",
            },
            identities = {
              rewards = {
                {
                  id = 56753,
                  name = "Buckler of the Broodlands Stalker",
                },
                {
                  id = 66907,
                  name = "Bolt of the Storming Sky",
                },
              },
              shadow_component = {
                id = 62533,
                name = "Shadow of a Legendary Ranger Shield",
              },
            },
            ids = {
              62533,
              56753,
              66907,
            },
            item = "Shadow of a Legendary Ranger Shield",
          },
          Shoulder = {
            aliases = {
              "Lightning Singed Mantle",
            },
            ids = {
              71654,
            },
            item = "Lightning Singed Mantle",
          },
          Waist = {
            aliases = {
              "Belt of the Black Dragon",
            },
            ids = {
              71664,
            },
            item = "Belt of the Black Dragon",
          },
          Wrist1 = {
            aliases = {
              "Keeper's Ascendant Wristband of Journeys",
            },
            ids = {
              60522,
            },
            item = "Keeper's Ascendant Wristband of Journeys",
          },
          Wrist2 = {
            aliases = {
              "Keeper's Eternal Bracer of of Journeys",
            },
            ids = {
              60526,
            },
            item = "Keeper's Eternal Bracer of of Journeys",
          },
        },
        Rogue = {
          Arms = {
            aliases = {
              "Keeper's Ascendant Armguard of Shadows",
            },
            ids = {
              60443,
            },
            item = "Keeper's Ascendant Armguard of Shadows",
          },
          Aug19 = {
            aliases = {
              "Physical Prowess",
              "Cryptic Clutch of Physical Prowess",
              "Vacant Vessel of Physical Prowess",
            },
            ids = {
              62558,
              66533,
            },
            item = "Physical Prowess",
            notes = "No focus effect | +5 hSTR, +5 hSTA, +5 hAGI, +5 hDEX",
          },
          Back = {
            aliases = {
              "Cloak of Deepshadow",
            },
            ids = {
              71665,
            },
            item = "Cloak of Deepshadow",
          },
          Chest = {
            aliases = {
              "Keeper's Ascendant Tunic of Shadows",
            },
            ids = {
              60442,
            },
            item = "Keeper's Ascendant Tunic of Shadows",
          },
          Clicky1 = {
            aliases = {
              "Icon of Ancient Boon",
            },
            ids = {
              56758,
            },
            item = "Icon of Ancient Boon",
          },
          Clicky2 = {
            aliases = {
              "Icon of Potent Prowess",
            },
            ids = {
              56757,
            },
            item = "Icon of Potent Prowess",
          },
          Clicky3 = {
            aliases = {
              "Icon of Ancient Prowess",
            },
            ids = {
              57142,
            },
            item = "Icon of Ancient Prowess",
          },
          Ear1 = {
            aliases = {
              "Cloudkiller's Bauble",
            },
            ids = {
              71584,
            },
            item = "Cloudkiller's Bauble",
          },
          Ear2 = {
            aliases = {
              "Accursed Earhoop of Pain",
            },
            ids = {
              71668,
            },
            item = "Accursed Earhoop of Pain",
          },
          Face = {
            aliases = {
              "Mask of the Dawn Scorcher",
            },
            ids = {
              71626,
            },
            item = "Mask of the Dawn Scorcher",
          },
          Feet = {
            aliases = {
              "Keeper's Ascendant Boots of Shadows",
            },
            ids = {
              60447,
            },
            item = "Keeper's Ascendant Boots of Shadows",
          },
          Finger1 = {
            aliases = {
              "Glimmering Fire Opal Band",
            },
            ids = {
              71634,
            },
            item = "Glimmering Fire Opal Band",
          },
          Finger2 = {
            aliases = {
              "Bloodstained Ring of Evisceration",
            },
            ids = {
              71588,
            },
            item = "Bloodstained Ring of Evisceration",
          },
          Glyph1 = {
            aliases = {
              "Imbued Glyph: Ancient: Incursion",
            },
            ids = {
              80075,
            },
            item = "Imbued Glyph: Ancient: Incursion",
          },
          Hands = {
            aliases = {
              "Keeper's Ascendant Gloves of Shadows",
            },
            ids = {
              60445,
            },
            item = "Keeper's Ascendant Gloves of Shadows",
          },
          Head = {
            aliases = {
              "Keeper's Ascendant Hat of Shadows",
            },
            ids = {
              59359,
            },
            item = "Keeper's Ascendant Hat of Shadows",
          },
          Legs = {
            aliases = {
              "Keeper's Ascendant Pants of Shadows",
            },
            ids = {
              60446,
            },
            item = "Keeper's Ascendant Pants of Shadows",
          },
          Neck = {
            aliases = {
              "Necklace of Sandstorms",
            },
            ids = {
              71612,
            },
            item = "Necklace of Sandstorms",
          },
          Pack1 = {
            aliases = {
              "Tome Pack: Ancient: Incursion",
            },
            ids = {
              82656,
            },
            item = "Tome Pack: Ancient: Incursion",
            spell = "Ancient: Incursion",
            spells = {
              "Ancient: Incursion",
            },
          },
          Pack10 = {
            aliases = {
              "Tome of Vigorous Dagger Throw",
            },
            ids = {
              79236,
            },
            item = "Tome of Vigorous Dagger Throw",
            spell = "Vigorous Dagger Throw",
            spell_ids = {
              10851,
            },
            spells = {
              "Vigorous Dagger Throw",
            },
          },
          Pack2 = {
            aliases = {
              "Tome of Arcane Reprisal",
            },
            ids = {
              79226,
            },
            item = "Tome of Arcane Reprisal",
            spell = "Arcane Reprisal",
            spell_ids = {
              10889,
            },
            spells = {
              "Arcane Reprisal",
            },
          },
          Pack3 = {
            aliases = {
              "Tome of Assailant Discipline",
            },
            ids = {
              80087,
            },
            item = "Tome of Assailant Discipline",
            spell = "Assailant Discipline",
            spell_ids = {
              15117,
            },
            spells = {
              "Assailant Discipline",
            },
          },
          Pack4 = {
            aliases = {
              "Tome of Fourth Wind",
            },
            ids = {
              80081,
            },
            item = "Tome of Fourth Wind",
            spell = "Fourth Wind Discipline",
            spell_ids = {
              15134,
            },
            spells = {
              "Fourth Wind Discipline",
            },
          },
          Pack5 = {
            aliases = {
              "Tome of Frenetic Stabbing Discipline",
            },
            ids = {
              80088,
            },
            item = "Tome of Frenetic Stabbing Discipline",
            spell = "Frenetic Stabbing Discipline",
            spell_ids = {
              15119,
            },
            spells = {
              "Frenetic Stabbing Discipline",
            },
          },
          Pack6 = {
            aliases = {
              "Tome of Lithe Discipline",
            },
            ids = {
              80085,
            },
            item = "Tome of Lithe Discipline",
            spell = "Lithe Discipline",
            spell_ids = {
              15102,
            },
            spells = {
              "Lithe Discipline",
            },
          },
          Pack7 = {
            aliases = {
              "Tome of Outlaw's Glare",
            },
            ids = {
              88900,
            },
            item = "Tome of Outlaw's Glare",
            spell = "Outlaw's Glare",
            spell_ids = {
              40294,
            },
            spells = {
              "Outlaw's Glare",
            },
          },
          Pack8 = {
            aliases = {
              "Tome of Pinpoint Weakness",
            },
            ids = {
              88902,
            },
            item = "Tome of Pinpoint Weakness",
            spell = "Pinpoint Weakness",
            spell_ids = {
              15115,
            },
            spells = {
              "Pinpoint Weakness",
            },
          },
          Pack9 = {
            aliases = {
              "Tome of Twisted Fortune Discipline",
            },
            ids = {
              50116,
            },
            item = "Tome of Twisted Fortune Discipline",
            spell = "Twisted Fortune Discipline",
            spell_ids = {
              10852,
            },
            spells = {
              "Twisted Fortune Discipline",
            },
          },
          Ranged = {
            aliases = {
              "Head of the Putrid Drake",
            },
            ids = {
              55052,
            },
            item = "Head of the Putrid Drake",
          },
          RangedAug = {
            aliases = {
              "Preserved Eye of the Putrid Drake",
            },
            ids = {
              71620,
            },
            item = "Preserved Eye of the Putrid Drake",
          },
          Shadow = {
            aliases = {
              "Shadow of a Legendary Rogue Weapon",
              "Fang, the Lair's Deceit",
            },
            identities = {
              rewards = {
                {
                  id = 56496,
                  name = "Fang, the Lair's Deceit",
                },
              },
              shadow_component = {
                id = 60550,
                name = "Shadow of a Legendary Rogue Weapon",
              },
            },
            ids = {
              60550,
              56496,
            },
            item = "Shadow of a Legendary Rogue Weapon",
          },
          Shoulder = {
            aliases = {
              "Lightning Singed Mantle",
            },
            ids = {
              71654,
            },
            item = "Lightning Singed Mantle",
          },
          Waist = {
            aliases = {
              "Thundercrash Girdle",
            },
            ids = {
              71657,
            },
            item = "Thundercrash Girdle",
          },
          Wrist1 = {
            aliases = {
              "Keeper's Ascendant Bracer of Shadows",
            },
            ids = {
              60444,
            },
            item = "Keeper's Ascendant Bracer of Shadows",
          },
          Wrist2 = {
            aliases = {
              "Keeper's Eternal Bracer of Shadows",
            },
            ids = {
              60448,
            },
            item = "Keeper's Eternal Bracer of Shadows",
          },
        },
        ["Shadow Knight"] = {
          Arms = {
            aliases = {
              "Keeper's Ascendant Armguards of the Hateful",
            },
            ids = {
              54955,
            },
            item = "Keeper's Ascendant Armguards of the Hateful",
          },
          Aug19 = {
            aliases = {
              "Physical Prowess",
              "Cryptic Clutch of Physical Prowess",
              "Vacant Vessel of Physical Prowess",
            },
            ids = {
              62558,
              66533,
            },
            item = "Physical Prowess",
            notes = "No focus effect | +5 hSTR, +5 hSTA, +5 hAGI, +5 hDEX",
          },
          Back = {
            aliases = {
              "Cape of Dragon Scales",
            },
            ids = {
              71596,
            },
            item = "Cape of Dragon Scales",
          },
          Chest = {
            aliases = {
              "Keeper's Ascendant Chestguard of the Hateful",
            },
            ids = {
              54954,
            },
            item = "Keeper's Ascendant Chestguard of the Hateful",
          },
          Clicky1 = {
            aliases = {
              "Icon of Ancient Boon",
            },
            ids = {
              56758,
            },
            item = "Icon of Ancient Boon",
          },
          Clicky2 = {
            aliases = {
              "Icon of Unwavering Defense",
            },
            ids = {
              56755,
            },
            item = "Icon of Unwavering Defense",
          },
          Clicky3 = {
            aliases = {
              "Icon of Ancient Defense",
            },
            ids = {
              57141,
            },
            item = "Icon of Ancient Defense",
          },
          Ear1 = {
            aliases = {
              "Weighted Loop of Eternal Battle",
            },
            ids = {
              71624,
            },
            item = "Weighted Loop of Eternal Battle",
          },
          Ear2 = {
            aliases = {
              "Hoop of the Nest Defender",
            },
            ids = {
              71593,
            },
            item = "Hoop of the Nest Defender",
          },
          Face = {
            aliases = {
              "Face of Unfeeling",
            },
            ids = {
              71667,
            },
            item = "Face of Unfeeling",
          },
          Feet = {
            aliases = {
              "Keeper's Ascendant Boots of the Hateful",
            },
            ids = {
              54959,
            },
            item = "Keeper's Ascendant Boots of the Hateful",
          },
          Finger1 = {
            aliases = {
              "Ring of Unsung Legends",
            },
            ids = {
              71608,
            },
            item = "Ring of Unsung Legends",
          },
          Finger2 = {
            aliases = {
              "Ring of Living Malachite",
            },
            ids = {
              71562,
            },
            item = "Ring of Living Malachite",
          },
          Glyph1 = {
            aliases = {
              "Mnemonic Glyph: Cloak of the Corrupter",
            },
            ids = {
              79535,
            },
            item = "Mnemonic Glyph: Cloak of the Corrupter",
          },
          Glyph2 = {
            aliases = {
              "Mnemonic Glyph: Shroud of the Accursed",
            },
            ids = {
              79536,
            },
            item = "Mnemonic Glyph: Shroud of the Accursed",
          },
          Glyph3 = {
            aliases = {
              "Imbued Glyph: Theft of Misery",
            },
            ids = {
              79537,
            },
            item = "Imbued Glyph: Theft of Misery",
          },
          Hands = {
            aliases = {
              "Keeper's Ascendant Gloves of the Hateful",
            },
            ids = {
              54957,
            },
            item = "Keeper's Ascendant Gloves of the Hateful",
          },
          Head = {
            aliases = {
              "Keeper's Ascendant Helm of the Hateful",
            },
            ids = {
              54953,
            },
            item = "Keeper's Ascendant Helm of the Hateful",
          },
          Legs = {
            aliases = {
              "Keeper's Ascendant Legguards of the Hateful",
            },
            ids = {
              54958,
            },
            item = "Keeper's Ascendant Legguards of the Hateful",
          },
          Neck = {
            aliases = {
              "Necklace of Grimspirit Beads",
            },
            ids = {
              71597,
            },
            item = "Necklace of Grimspirit Beads",
          },
          Pack1 = {
            aliases = {
              "Spell Pack: Cloak of the Corrupter",
            },
            ids = {
              82807,
            },
            item = "Spell Pack: Cloak of the Corrupter",
            spell = "Cloak of the Corrupter",
            spells = {
              "Cloak of the Corrupter",
            },
          },
          Pack2 = {
            aliases = {
              "Spell Pack: Shroud of the Accursed",
            },
            ids = {
              82808,
            },
            item = "Spell Pack: Shroud of the Accursed",
            spell = "Shroud of the Accursed",
            spell_ids = {
              10251,
            },
            spells = {
              "Shroud of the Accursed",
            },
          },
          Pack3 = {
            aliases = {
              "Spell Pack: Theft of Misery",
              "Spell: Theft of Misery",
            },
            ids = {
              71777,
              82809,
            },
            item = "Spell Pack: Theft of Misery",
            spell = "Theft of Misery",
            spell_ids = {
              15073,
            },
            spells = {
              "Theft of Misery",
            },
          },
          Pack4 = {
            aliases = {
              "Spell: Blood of the Harbinger",
            },
            ids = {
              80788,
            },
            item = "Spell: Blood of the Harbinger",
            spell = "Blood of the Harbinger",
            spell_ids = {
              15233,
            },
            spells = {
              "Blood of the Harbinger",
            },
          },
          Pack5 = {
            aliases = {
              "Spell: Grasp of Ju'rek",
            },
            ids = {
              78565,
            },
            item = "Spell: Grasp of Ju'rek",
            spell = "Grasp of Ju'rek",
            spell_ids = {
              10913,
            },
            spells = {
              "Grasp of Ju'rek",
            },
          },
          Pack6 = {
            aliases = {
              "Spell: Terror of Lavaspinner's Lair",
            },
            ids = {
              78594,
            },
            item = "Spell: Terror of Lavaspinner's Lair",
            spell = "Terror of Lavaspinner's Lair",
            spell_ids = {
              10257,
            },
            spells = {
              "Terror of Lavaspinner's Lair",
            },
          },
          Pack7 = {
            aliases = {
              "Spell: Touch of the Shadows",
            },
            ids = {
              80787,
            },
            item = "Spell: Touch of the Shadows",
            spell = "Touch of the Shadows",
            spell_ids = {
              15231,
            },
            spells = {
              "Touch of the Shadows",
            },
          },
          Pack8 = {
            aliases = {
              "Spell: Voice of Emoush",
            },
            ids = {
              81860,
            },
            item = "Spell: Voice of Emoush",
            spell = "Voice of Emoush",
            spell_ids = {
              15239,
            },
            spells = {
              "Voice of Emoush",
            },
          },
          Pack9 = {
            aliases = {
              "Tome of Soul Carapace",
            },
            ids = {
              79408,
            },
            item = "Tome of Soul Carapace",
            spell = "Soul Carapace",
            spell_ids = {
              11866,
            },
            spells = {
              "Soul Carapace",
            },
          },
          Ranged = {
            aliases = {
              "Branch of the Twisting Tree",
            },
            ids = {
              71627,
            },
            item = "Branch of the Twisting Tree",
          },
          RangedAug = {
            aliases = {
              "Fallen Leaf of the Twisting Tree",
            },
            ids = {
              55053,
            },
            item = "Fallen Leaf of the Twisting Tree",
          },
          Shadow = {
            aliases = {
              "Shadow of a Legendary Shadowknight Shield",
              "Merciless Bulwark of the Ice Dragon",
            },
            identities = {
              rewards = {
                {
                  id = 55077,
                  name = "Merciless Bulwark of the Ice Dragon",
                },
              },
              shadow_component = {
                id = 60544,
                name = "Shadow of a Legendary Shadowknight Shield",
              },
            },
            ids = {
              60544,
              55077,
            },
            item = "Shadow of a Legendary Shadowknight Shield",
          },
          Shoulder = {
            aliases = {
              "Dark-Touched Mantle",
            },
            ids = {
              71590,
            },
            item = "Dark-Touched Mantle",
          },
          Waist = {
            aliases = {
              "Belt of the Black Dragon",
            },
            ids = {
              71664,
            },
            item = "Belt of the Black Dragon",
          },
          Wrist1 = {
            aliases = {
              "Keeper's Ascendant Wristguard of the Hateful",
            },
            ids = {
              54956,
            },
            item = "Keeper's Ascendant Wristguard of the Hateful",
          },
          Wrist2 = {
            aliases = {
              "Keeper's Eternal Bracer of the Hateful",
            },
            ids = {
              55051,
            },
            item = "Keeper's Eternal Bracer of the Hateful",
          },
        },
        Shaman = {
          Arms = {
            aliases = {
              "Keeper's Ascendant Armguards of the Ancestors",
            },
            ids = {
              57154,
            },
            item = "Keeper's Ascendant Armguards of the Ancestors",
          },
          Aug19 = {
            aliases = {
              "Mental Prowess",
              "Cryptic Clutch of Mental Prowess",
              "Vacant Vessel of Mental Prowess",
            },
            ids = {
              62559,
              66720,
            },
            item = "Mental Prowess",
            notes = "No focus effect | +10 hINT, +10 hWIS, +10 heroic resists",
          },
          Back = {
            aliases = {
              "Cape of Serenity",
            },
            ids = {
              71613,
            },
            item = "Cape of Serenity",
          },
          Chest = {
            aliases = {
              "Keeper's Ascendant Tunic of the Ancestors",
            },
            ids = {
              57153,
            },
            item = "Keeper's Ascendant Tunic of the Ancestors",
          },
          Clicky1 = {
            aliases = {
              "Icon of Ancient Boon",
            },
            ids = {
              56758,
            },
            item = "Icon of Ancient Boon",
          },
          Clicky2 = {
            aliases = {
              "Icon of Scribe's Endurance",
            },
            ids = {
              56756,
            },
            item = "Icon of Scribe's Endurance",
          },
          Clicky3 = {
            aliases = {
              "Icon of the Ancient Scribe",
            },
            ids = {
              57143,
            },
            item = "Icon of the Ancient Scribe",
          },
          Ear1 = {
            aliases = {
              "Earring of Contemplation",
            },
            ids = {
              71589,
            },
            item = "Earring of Contemplation",
          },
          Ear2 = {
            aliases = {
              "Tear of Kessdona",
            },
            ids = {
              71642,
            },
            item = "Tear of Kessdona",
          },
          Face = {
            aliases = {
              "Young Dragon Mask",
            },
            ids = {
              71594,
            },
            item = "Young Dragon Mask",
          },
          Feet = {
            aliases = {
              "Keeper's Ascendant Boots of the Ancestors",
            },
            ids = {
              57158,
            },
            item = "Keeper's Ascendant Boots of the Ancestors",
          },
          Finger1 = {
            aliases = {
              "Dragon Nursery Ring",
            },
            ids = {
              71592,
            },
            item = "Dragon Nursery Ring",
          },
          Finger2 = {
            aliases = {
              "Eye of Tirranun",
            },
            ids = {
              71652,
            },
            item = "Eye of Tirranun",
          },
          Glyph1 = {
            aliases = {
              "Mnemonic Glyph: Stillmoon Focusing",
            },
            ids = {
              76568,
            },
            item = "Mnemonic Glyph: Stillmoon Focusing",
          },
          Glyph2 = {
            aliases = {
              "Mnemonic Glyph: Talisman of the Stillmoon",
            },
            ids = {
              76569,
            },
            item = "Mnemonic Glyph: Talisman of the Stillmoon",
          },
          Glyph3 = {
            aliases = {
              "Mnemonic Glyph: Blood of Volkara",
            },
            ids = {
              76570,
            },
            item = "Mnemonic Glyph: Blood of Volkara",
          },
          Glyph4 = {
            aliases = {
              "Mnemonic Glyph: Talisman of Coalescence",
            },
            ids = {
              76571,
            },
            item = "Mnemonic Glyph: Talisman of Coalescence",
          },
          Glyph5 = {
            aliases = {
              "Imbued Glyph: Talisman of the Cougar",
            },
            ids = {
              76572,
            },
            item = "Imbued Glyph: Talisman of the Cougar",
          },
          Hands = {
            aliases = {
              "Keeper's Ascendant Mitts of the Ancestors",
            },
            ids = {
              57156,
            },
            item = "Keeper's Ascendant Mitts of the Ancestors",
          },
          Head = {
            aliases = {
              "Keeper's Ascendant Cap of the Ancestors",
            },
            ids = {
              57152,
            },
            item = "Keeper's Ascendant Cap of the Ancestors",
          },
          Legs = {
            aliases = {
              "Keeper's Ascendant Leggings of the Ancestors",
            },
            ids = {
              57157,
            },
            item = "Keeper's Ascendant Leggings of the Ancestors",
          },
          Neck = {
            aliases = {
              "Locket of Raining Tears",
            },
            ids = {
              71655,
            },
            item = "Locket of Raining Tears",
          },
          Pack1 = {
            aliases = {
              "Spell Pack: Stillmoon Focus",
            },
            ids = {
              82662,
            },
            item = "Spell Pack: Stillmoon Focus",
            spell = "Stillmoon Focusing",
            spells = {
              "Stillmoon Focusing",
              "Talisman of the Stillmoon",
            },
          },
          Pack2 = {
            aliases = {
              "Spell Pack: Blood of Volkara",
            },
            ids = {
              82663,
            },
            item = "Spell Pack: Blood of Volkara",
            spell = "Blood of Volkara",
            spells = {
              "Blood of Volkara",
            },
          },
          Pack3 = {
            aliases = {
              "Spell Pack: Talisman of Coalescence",
            },
            ids = {
              82664,
            },
            item = "Spell Pack: Talisman of Coalescence",
            spell = "Talisman of Coalescence",
            spells = {
              "Talisman of Coalescence",
            },
          },
          Pack4 = {
            aliases = {
              "Spell Pack: Talisman of the Cougar",
            },
            ids = {
              82665,
            },
            item = "Spell Pack: Talisman of the Cougar",
            spell = "Talisman of the Cougar",
            spells = {
              "Talisman of the Cougar",
            },
          },
          Pack5 = {
            aliases = {
              "Spell Pack: Wild Companions",
            },
            ids = {
              50107,
            },
            item = "Spell Pack: Wild Companions",
            spell = "Wild Companions",
            spells = {
              "Wild Companions",
            },
          },
          Pack6 = {
            aliases = {
              "Spell: Breath of Ju'rek",
            },
            ids = {
              80285,
            },
            item = "Spell: Breath of Ju'rek",
            spell = "Breath of Shadows",
            spell_ids = {
              41232,
            },
            spells = {
              "Breath of Shadows",
            },
          },
          Pack7 = {
            aliases = {
              "Spell: Curse of Emoush",
            },
            ids = {
              80288,
            },
            item = "Spell: Curse of Emoush",
            spell = "Curse of Emoush",
            spell_ids = {
              15147,
            },
            spells = {
              "Curse of Emoush",
            },
          },
          Pack8 = {
            aliases = {
              "Spell: Shadowy Sloth",
            },
            ids = {
              80287,
            },
            item = "Spell: Shadowy Sloth",
            spell = "Shadowy Sloth",
            spell_ids = {
              15144,
            },
            spells = {
              "Shadowy Sloth",
            },
          },
          Pack9 = {
            aliases = {
              "Spell: Transcendental Torpor",
            },
            ids = {
              80286,
            },
            item = "Spell: Transcendental Torpor",
            spell = "Transcendental Torpor",
            spell_ids = {
              15141,
            },
            spells = {
              "Transcendental Torpor",
            },
          },
          Ranged = {
            aliases = {
              "Phial of the First Brood",
            },
            ids = {
              71578,
            },
            item = "Phial of the First Brood",
          },
          RangedAug = {
            aliases = {
              "Crux of the First Brood",
            },
            ids = {
              60535,
            },
            item = "Crux of the First Brood",
          },
          Shadow = {
            aliases = {
              "Shadow of a Legendary Shaman Shield",
              "Bulwark of Bygone Purity",
            },
            identities = {
              rewards = {
                {
                  id = 56494,
                  name = "Bulwark of Bygone Purity",
                },
              },
              shadow_component = {
                id = 60547,
                name = "Shadow of a Legendary Shaman Shield",
              },
            },
            ids = {
              60547,
              56494,
            },
            item = "Shadow of a Legendary Shaman Shield",
          },
          Shoulder = {
            aliases = {
              "Obsidian Pauldrons",
            },
            ids = {
              71666,
            },
            item = "Obsidian Pauldrons",
          },
          Waist = {
            aliases = {
              "Windwatcher Sash",
            },
            ids = {
              71621,
            },
            item = "Windwatcher Sash",
          },
          Wrist1 = {
            aliases = {
              "Keeper's Ascendant Wristband of the Ancestors",
            },
            ids = {
              57155,
            },
            item = "Keeper's Ascendant Wristband of the Ancestors",
          },
          Wrist2 = {
            aliases = {
              "Keeper's Eternal Bracer of the Ancestors",
            },
            ids = {
              57159,
            },
            item = "Keeper's Eternal Bracer of the Ancestors",
          },
        },
        Warrior = {
          Arms = {
            aliases = {
              "Keeper's Ascendant Sleeves of War",
            },
            ids = {
              54947,
            },
            item = "Keeper's Ascendant Sleeves of War",
          },
          Aug19 = {
            aliases = {
              "Physical Prowess",
              "Cryptic Clutch of Physical Prowess",
              "Vacant Vessel of Physical Prowess",
            },
            ids = {
              62558,
              66533,
            },
            item = "Physical Prowess",
            notes = "No focus effect | +5 hSTR, +5 hSTA, +5 hAGI, +5 hDEX",
          },
          Back = {
            aliases = {
              "Cape of Dragon Scales",
            },
            ids = {
              71596,
            },
            item = "Cape of Dragon Scales",
          },
          Chest = {
            aliases = {
              "Keeper's Ascendant Chestguard of War",
            },
            ids = {
              54946,
            },
            item = "Keeper's Ascendant Chestguard of War",
          },
          Clicky1 = {
            aliases = {
              "Icon of Ancient Boon",
            },
            ids = {
              56758,
            },
            item = "Icon of Ancient Boon",
          },
          Clicky2 = {
            aliases = {
              "Icon of Unwavering Defense",
            },
            ids = {
              56755,
            },
            item = "Icon of Unwavering Defense",
          },
          Clicky3 = {
            aliases = {
              "Icon of Ancient Defense",
            },
            ids = {
              57141,
            },
            item = "Icon of Ancient Defense",
          },
          Ear1 = {
            aliases = {
              "Weighted Loop of Eternal Battle",
            },
            ids = {
              71624,
            },
            item = "Weighted Loop of Eternal Battle",
          },
          Ear2 = {
            aliases = {
              "Hoop of the Nest Defender",
            },
            ids = {
              71593,
            },
            item = "Hoop of the Nest Defender",
          },
          Face = {
            aliases = {
              "Face of Unfeeling",
            },
            ids = {
              71667,
            },
            item = "Face of Unfeeling",
          },
          Feet = {
            aliases = {
              "Keeper's Ascendant Boots of War",
            },
            ids = {
              54951,
            },
            item = "Keeper's Ascendant Boots of War",
          },
          Finger1 = {
            aliases = {
              "Ring of Unsung Legends",
            },
            ids = {
              71608,
            },
            item = "Ring of Unsung Legends",
          },
          Finger2 = {
            aliases = {
              "Ring of Living Malachite",
            },
            ids = {
              71562,
            },
            item = "Ring of Living Malachite",
          },
          Glyph1 = {
            aliases = {
              "Imbued Glyph: Malicious Onslaught Discipline",
            },
            ids = {
              80073,
            },
            item = "Imbued Glyph: Malicious Onslaught Discipline",
          },
          Hands = {
            aliases = {
              "Keeper's Ascendant Gloves of War",
            },
            ids = {
              54949,
            },
            item = "Keeper's Ascendant Gloves of War",
          },
          Head = {
            aliases = {
              "Keeper's Ascendant Helm of War",
            },
            ids = {
              54945,
            },
            item = "Keeper's Ascendant Helm of War",
          },
          Legs = {
            aliases = {
              "Keeper's Ascendant Legguards of War",
            },
            ids = {
              54950,
            },
            item = "Keeper's Ascendant Legguards of War",
          },
          Neck = {
            aliases = {
              "Necklace of Grimspirit Beads",
            },
            ids = {
              71597,
            },
            item = "Necklace of Grimspirit Beads",
          },
          Pack1 = {
            aliases = {
              "Tome Pack: Ancient: Malicious Onslaught",
            },
            ids = {
              82654,
            },
            item = "Tome Pack: Ancient: Malicious Onslaught",
            spell = "Malicious Onslaught Discipline",
            spells = {
              "Malicious Onslaught Discipline",
            },
          },
          Pack2 = {
            aliases = {
              "Tome of Field Conqueror",
            },
            ids = {
              88919,
            },
            item = "Tome of Field Conqueror",
            spell = "Field Conqueror",
            spell_ids = {
              25036,
            },
            spells = {
              "Field Conqueror",
            },
          },
          Pack3 = {
            aliases = {
              "Tome of Final Stand Discipline",
            },
            ids = {
              79302,
            },
            item = "Tome of Final Stand Discipline",
            spell = "Final Stand Discipline",
            spell_ids = {
              10965,
            },
            spells = {
              "Final Stand Discipline",
            },
          },
          Pack4 = {
            aliases = {
              "Tome of Fourth Wind",
            },
            ids = {
              80081,
            },
            item = "Tome of Fourth Wind",
            spell = "Fourth Wind Discipline",
            spell_ids = {
              15134,
            },
            spells = {
              "Fourth Wind Discipline",
            },
          },
          Pack5 = {
            aliases = {
              "Tome of Jeer",
            },
            ids = {
              88909,
            },
            item = "Tome of Jeer",
            spell = "Jeer",
            spell_ids = {
              10848,
            },
            spells = {
              "Jeer",
            },
          },
          Pack6 = {
            aliases = {
              "Tome of Maelstrom Blade",
            },
            ids = {
              79310,
            },
            item = "Tome of Maelstrom Blade",
            spell = "Maelstrom Blade",
            spell_ids = {
              10973,
            },
            spells = {
              "Maelstrom Blade",
            },
          },
          Pack7 = {
            aliases = {
              "Tome of Maximum Effort",
            },
            ids = {
              80080,
            },
            item = "Tome of Maximum Effort",
            spell = "Maximum Effort Discipline",
            spell_ids = {
              15104,
            },
            spells = {
              "Maximum Effort Discipline",
            },
          },
          Pack8 = {
            aliases = {
              "Tome of Roaring Hatred",
            },
            ids = {
              88910,
            },
            item = "Tome of Roaring Hatred",
            spell = "Roaring Hatred",
            spell_ids = {
              19537,
            },
            spells = {
              "Roaring Hatred",
            },
          },
          Pack9 = {
            aliases = {
              "Tome of Vanquisher's Aura",
            },
            ids = {
              88925,
            },
            item = "Tome of Vanquisher's Aura",
            spell = "Vanquisher's Aura",
            spell_ids = {
              14351,
            },
            spells = {
              "Vanquisher's Aura",
            },
          },
          Ranged = {
            aliases = {
              "Head of the Putrid Drake",
            },
            ids = {
              55052,
            },
            item = "Head of the Putrid Drake",
          },
          RangedAug = {
            aliases = {
              "Preserved Eye of the Putrid Drake",
            },
            ids = {
              71620,
            },
            item = "Preserved Eye of the Putrid Drake",
          },
          Shadow = {
            aliases = {
              "Shadow of a Legendary Warrior Shield",
              "Tenacious Bulwark of the Lava Dragon",
            },
            identities = {
              rewards = {
                {
                  id = 55056,
                  name = "Tenacious Bulwark of the Lava Dragon",
                },
              },
              shadow_component = {
                id = 60538,
                name = "Shadow of a Legendary Warrior Shield",
              },
            },
            ids = {
              60538,
              55056,
            },
            item = "Shadow of a Legendary Warrior Shield",
          },
          Shoulder = {
            aliases = {
              "Dark-Touched Mantle",
            },
            ids = {
              71590,
            },
            item = "Dark-Touched Mantle",
          },
          Waist = {
            aliases = {
              "Belt of the Black Dragon",
            },
            ids = {
              71664,
            },
            item = "Belt of the Black Dragon",
          },
          Wrist1 = {
            aliases = {
              "Keeper's Ascendant Bracer of War",
            },
            ids = {
              54948,
            },
            item = "Keeper's Ascendant Bracer of War",
          },
          Wrist2 = {
            aliases = {
              "Keeper's Eternal Bracer of War",
            },
            ids = {
              54952,
            },
            item = "Keeper's Eternal Bracer of War",
          },
        },
        Wizard = {
          Arms = {
            aliases = {
              "Keeper's Ascendant Sleeves of the Arcanists",
            },
            ids = {
              60467,
            },
            item = "Keeper's Ascendant Sleeves of the Arcanists",
          },
          Aug19 = {
            aliases = {
              "Mental Prowess",
              "Cryptic Clutch of Mental Prowess",
              "Vacant Vessel of Mental Prowess",
            },
            ids = {
              62559,
              66720,
            },
            item = "Mental Prowess",
            notes = "No focus effect | +10 hINT, +10 hWIS, +10 heroic resists",
          },
          Back = {
            aliases = {
              "Shroud of the Surging Storm",
            },
            ids = {
              71656,
            },
            item = "Shroud of the Surging Storm",
          },
          Chest = {
            aliases = {
              "Keeper's Ascendant Robe of the Arcanists",
            },
            ids = {
              60466,
            },
            item = "Keeper's Ascendant Robe of the Arcanists",
          },
          Clicky1 = {
            aliases = {
              "Icon of Ancient Boon",
            },
            ids = {
              56758,
            },
            item = "Icon of Ancient Boon",
          },
          Clicky2 = {
            aliases = {
              "Icon of Scribe's Endurance",
            },
            ids = {
              56756,
            },
            item = "Icon of Scribe's Endurance",
          },
          Clicky3 = {
            aliases = {
              "Icon of the Ancient Scribe",
            },
            ids = {
              57143,
            },
            item = "Icon of the Ancient Scribe",
          },
          Ear1 = {
            aliases = {
              "Hoop of the Drakeborn",
            },
            ids = {
              71574,
            },
            item = "Hoop of the Drakeborn",
          },
          Ear2 = {
            aliases = {
              "Grelian Earring of Uncertainty",
            },
            ids = {
              71603,
            },
            item = "Grelian Earring of Uncertainty",
          },
          Face = {
            aliases = {
              "Entrancing Silk Veil",
            },
            ids = {
              71643,
            },
            item = "Entrancing Silk Veil",
          },
          Feet = {
            aliases = {
              "Keeper's Ascendant Slippers of the Arcanists",
            },
            ids = {
              60471,
            },
            item = "Keeper's Ascendant Slippers of the Arcanists",
          },
          Finger1 = {
            aliases = {
              "Thought Sieve Ring",
            },
            ids = {
              71625,
            },
            item = "Thought Sieve Ring",
          },
          Finger2 = {
            aliases = {
              "Stormeye Band",
            },
            ids = {
              71658,
            },
            item = "Stormeye Band",
          },
          Glyph1 = {
            aliases = {
              "Mnemonic Glyph: Bolster of the Sorceror",
            },
            ids = {
              79521,
            },
            item = "Mnemonic Glyph: Bolster of the Sorceror",
          },
          Glyph2 = {
            aliases = {
              "Mnemonic Glyph: Supernal Skin",
            },
            ids = {
              79522,
            },
            item = "Mnemonic Glyph: Supernal Skin",
          },
          Glyph3 = {
            aliases = {
              "Imbued Glyph: Ethereal Weave",
            },
            ids = {
              79523,
            },
            item = "Imbued Glyph: Ethereal Weave",
          },
          Hands = {
            aliases = {
              "Keeper's Ascendant Gloves of the Arcanists",
            },
            ids = {
              60469,
            },
            item = "Keeper's Ascendant Gloves of the Arcanists",
          },
          Head = {
            aliases = {
              "Keeper's Ascendant Cap of the Arcanists",
            },
            ids = {
              60465,
            },
            item = "Keeper's Ascendant Cap of the Arcanists",
          },
          Legs = {
            aliases = {
              "Keeper's Ascendant Pants of the Arcanists",
            },
            ids = {
              60470,
            },
            item = "Keeper's Ascendant Pants of the Arcanists",
          },
          Neck = {
            aliases = {
              "Choker of One Hundred Diamonds",
            },
            ids = {
              71651,
            },
            item = "Choker of One Hundred Diamonds",
          },
          Pack1 = {
            aliases = {
              "Spell Pack: Bolster of the Sorcerer",
            },
            ids = {
              82795,
            },
            item = "Spell Pack: Bolster of the Sorcerer",
            spell = "Bolster of the Sorcerer",
            spells = {
              "Bolster of the Sorcerer",
            },
          },
          Pack2 = {
            aliases = {
              "Spell Pack: Supernal Skin",
            },
            ids = {
              82796,
            },
            item = "Spell Pack: Supernal Skin",
            spell = "Supernal Skin",
            spells = {
              "Supernal Skin",
            },
          },
          Pack3 = {
            aliases = {
              "Spell Pack: Ethereal Weave",
            },
            ids = {
              82797,
            },
            item = "Spell Pack: Ethereal Weave",
            spell = "Ethereal Weave",
            spells = {
              "Ethereal Weave",
            },
          },
          Pack4 = {
            aliases = {
              "Spell: Arcane Sanctuary",
            },
            ids = {
              80763,
            },
            item = "Spell: Arcane Sanctuary",
            spell = "Arcane Sanctuary",
            spell_ids = {
              15180,
            },
            spells = {
              "Arcane Sanctuary",
            },
          },
          Pack5 = {
            aliases = {
              "Spell: Eruption of Telakemara",
            },
            ids = {
              80760,
            },
            item = "Spell: Eruption of Telakemara",
            spell = "Eruption of Telakemara",
            spell_ids = {
              15167,
            },
            spells = {
              "Eruption of Telakemara",
            },
          },
          Pack6 = {
            aliases = {
              "Spell: Ether Blaze",
            },
            ids = {
              79388,
            },
            item = "Spell: Ether Blaze",
            spell = "Ether Blaze",
            spell_ids = {
              11835,
            },
            spells = {
              "Ether Blaze",
            },
          },
          Pack7 = {
            aliases = {
              "Spell: Evoker's Pyromantic Blade",
            },
            ids = {
              80761,
            },
            item = "Spell: Evoker's Pyromantic Blade",
            spell = "Evoker's Pyromantic Blade",
            spell_ids = {
              15168,
            },
            spells = {
              "Evoker's Pyromantic Blade",
            },
          },
          Pack8 = {
            aliases = {
              "Spell: Serenity Harvest",
            },
            ids = {
              79129,
            },
            item = "Spell: Serenity Harvest",
            spell = "Serenity Harvest",
            spell_ids = {
              10792,
            },
            spells = {
              "Serenity Harvest",
            },
          },
          Pack9 = {
            aliases = {
              "Spell: Wildmagic Salvo",
            },
            ids = {
              79390,
            },
            item = "Spell: Wildmagic Salvo",
            spell = "Wildmagic Salvo",
            spell_ids = {
              11840,
            },
            spells = {
              "Wildmagic Salvo",
            },
          },
          Ranged = {
            aliases = {
              "Spark of the Skies",
            },
            ids = {
              60536,
            },
            item = "Spark of the Skies",
          },
          RangedAug = {
            aliases = {
              "Core of the Skies",
            },
            ids = {
              71659,
            },
            item = "Core of the Skies",
          },
          Shadow = {
            aliases = {
              "Shadow of a Legendary Wizard Staff",
              "Capsule of Catastrophic Fate",
            },
            identities = {
              rewards = {
                {
                  id = 56499,
                  name = "Capsule of Catastrophic Fate",
                },
              },
              shadow_component = {
                id = 60669,
                name = "Shadow of a Legendary Wizard Staff",
              },
            },
            ids = {
              60669,
              56499,
            },
            item = "Shadow of a Legendary Wizard Staff",
          },
          Shoulder = {
            aliases = {
              "Brimstone Spaulders",
            },
            ids = {
              71635,
            },
            item = "Brimstone Spaulders",
          },
          Waist = {
            aliases = {
              "Sash of Frigidity",
            },
            ids = {
              71650,
            },
            item = "Sash of Frigidity",
          },
          Wrist1 = {
            aliases = {
              "Keeper's Ascendant Wristband of the Arcanists",
            },
            ids = {
              60468,
            },
            item = "Keeper's Ascendant Wristband of the Arcanists",
          },
          Wrist2 = {
            aliases = {
              "Keeper's Eternal Bracer of the Arcanists",
            },
            ids = {
              60472,
            },
            item = "Keeper's Eternal Bracer of the Arcanists",
          },
        },
      },
      group = "Raid Best In Slot",
      id = "don",
      name = "Dragons of Norrath",
      show_base = {
      },
      template = {
        Aug1 = {
          aliases = {
            "Benevolent Efficiency",
            "Cryptic Clutch of Benevolent Efficiency",
            "Vacant Vessel of Benevolent Efficiency",
          },
          ids = {
            62541,
            62561,
          },
          item = "Benevolent Efficiency",
          notes = "-11–33% beneficial spell mana cost | +10 hWIS",
        },
        Aug10 = {
          aliases = {
            "Noxious Demise",
            "Cryptic Clutch of Noxious Demise",
            "Vacant Vessel of Noxious Demise",
          },
          ids = {
            62547,
            62567,
          },
          item = "Noxious Demise",
          notes = "+10–60% poison spell damage | +5 hINT, +25 hPR",
        },
        Aug11 = {
          aliases = {
            "Festering Demise",
            "Cryptic Clutch of Festering Demise",
            "Vacant Vessel of Festering Demise",
          },
          ids = {
            62548,
            62568,
          },
          item = "Festering Demise",
          notes = "+10–60% disease spell damage | +5 hINT, +25 hDR",
        },
        Aug12 = {
          aliases = {
            "Merciful Mending",
            "Cryptic Clutch of Merciful Mending",
            "Vacant Vessel of Merciful Mending",
          },
          ids = {
            62549,
            62569,
          },
          item = "Merciful Mending",
          notes = "+10–60% healing | +10 hWIS",
        },
        Aug13 = {
          aliases = {
            "Expanded Reach",
            "Cryptic Clutch of Expanded Reach",
            "Vacant Vessel of Expanded Reach",
          },
          ids = {
            62552,
            63018,
          },
          item = "Expanded Reach",
          notes = "+50% spell range | +10 hWIS, +10 hINT",
        },
        Aug14 = {
          aliases = {
            "Nimble Elusion",
            "Cryptic Clutch of Nimble Elusion",
            "Vacant Vessel of Nimble Elusion",
          },
          ids = {
            62556,
            64050,
          },
          item = "Nimble Elusion",
          notes = "+70% dodge | +10 hAGI",
        },
        Aug15 = {
          aliases = {
            "Adept Guard",
            "Cryptic Clutch of Adept Guard",
            "Vacant Vessel of Adept Guard",
          },
          ids = {
            62555,
            64049,
          },
          item = "Adept Guard",
          notes = "+70% parry, +70% block | +10 hSTA",
        },
        Aug16 = {
          aliases = {
            "Visceral Malice",
            "Cryptic Clutch of Visceral Malice",
            "Vacant Vessel of Visceral Malice",
          },
          ids = {
            62554,
            63020,
          },
          item = "Visceral Malice",
          notes = "+300% melee critical damage | +10 hSTR",
        },
        Aug17 = {
          aliases = {
            "Wanton Assault",
            "Cryptic Clutch of Wanton Assault",
            "Vacant Vessel of Wanton Assault",
          },
          ids = {
            62553,
            63019,
          },
          item = "Wanton Assault",
          notes = "+21% double attack, +7% triple attack, +5% chance to hit | +10 hSTR",
        },
        Aug18 = {
          aliases = {
            "Lethal Barrage",
            "Cryptic Clutch of Lethal Barrage",
            "Vacant Vessel of Lethal Barrage",
          },
          ids = {
            62557,
            64326,
          },
          item = "Lethal Barrage",
          notes = "+28% archery and throwing chance to hit | +20 hDEX",
        },
        Aug2 = {
          aliases = {
            "Benevolent Extension",
            "Cryptic Clutch of Benevolent Extension",
            "Vacant Vessel of Benevolent Extension",
          },
          ids = {
            62551,
            63017,
          },
          item = "Benevolent Extension",
          notes = "+40% beneficial spell duration | +10 hWIS",
        },
        Aug3 = {
          aliases = {
            "Benevolent Alacrity",
            "Cryptic Clutch of Benevolent Alacrity",
            "Vacant Vessel of Benevolent Alacrity",
          },
          ids = {
            62543,
            62563,
          },
          item = "Benevolent Alacrity",
          notes = "-40% beneficial spell cast time | +10 hWIS",
        },
        Aug4 = {
          aliases = {
            "Malevolent Efficiency",
            "Cryptic Clutch of Malevolent Efficiency",
            "Vacant Vessel of Malevolent Efficiency",
          },
          ids = {
            62540,
            62560,
          },
          item = "Malevolent Efficiency",
          notes = "-11–33% detrimental spell mana cost | +10 hINT",
        },
        Aug5 = {
          aliases = {
            "Malevolent Extension",
            "Cryptic Clutch of Malevolent Extension",
            "Vacant Vessel of Malevolent Extension",
          },
          ids = {
            62550,
            63016,
          },
          item = "Malevolent Extension",
          notes = "+40% detrimental spell duration | +10 hINT",
        },
        Aug6 = {
          aliases = {
            "Malevolent Alacrity",
            "Cryptic Clutch of Malevolent Alacrity",
            "Vacant Vessel of Malevolent Alacrity",
          },
          ids = {
            62542,
            62562,
          },
          item = "Malevolent Alacrity",
          notes = "-40% detrimental spell cast time | +10 hINT",
        },
        Aug7 = {
          aliases = {
            "Arcane Demise",
            "Cryptic Clutch of Arcane Demise",
            "Vacant Vessel of Arcane Demise",
          },
          ids = {
            62544,
            62564,
          },
          item = "Arcane Demise",
          notes = "+10–60% magic spell damage | +5 hINT, +25 hMR",
        },
        Aug8 = {
          aliases = {
            "Fiery Demise",
            "Cryptic Clutch of Fiery Demise",
            "Vacant Vessel of Fiery Demise",
          },
          ids = {
            62545,
            62565,
          },
          item = "Fiery Demise",
          notes = "+10–60% fire spell damage | +5 hINT, +25 hFR",
        },
        Aug9 = {
          aliases = {
            "Chilling Demise",
            "Cryptic Clutch of Chilling Demise",
            "Vacant Vessel of Chilling Demise",
          },
          ids = {
            62546,
            62566,
          },
          item = "Chilling Demise",
          notes = "+10–60% cold spell damage | +5 hINT, +25 hCR",
        },
        CharmExtreme = {
          aliases = {
            "Lustrous Gem of Eternal Avarice",
          },
          ids = {
            55054,
          },
          item = "Lustrous Gem of Eternal Avarice",
        },
        CharmSafe = {
          aliases = {
            "Solemn Gem of Restrained Avarice",
          },
          ids = {
            55055,
          },
          item = "Solemn Gem of Restrained Avarice",
        },
        Duality = {
          aliases = {
            "Duality of Desire",
          },
          ids = {
            66903,
          },
          item = "Duality of Desire",
        },
        Materium1 = {
          aliases = {
            "Primary Materium of Legends",
          },
          ids = {
            62535,
          },
          item = "Primary Materium of Legends",
        },
        Materium2 = {
          aliases = {
            "Secondary Materium of Legends",
          },
          ids = {
            62536,
          },
          item = "Secondary Materium of Legends",
        },
        Materium3 = {
          aliases = {
            "Tertiary Materium of Legends",
          },
          ids = {
            62537,
          },
          item = "Tertiary Materium of Legends",
        },
        Misc1 = {
          aliases = {
            "Dark Reign Elite Satchel",
          },
          ids = {
            66731,
          },
          item = "Dark Reign Elite Satchel",
        },
        Misc2 = {
          aliases = {
            "Dark Reign Initiate Satchel",
          },
          ids = {
            66732,
          },
          item = "Dark Reign Initiate Satchel",
        },
        Misc3 = {
          aliases = {
            "Ancient Draconic Lockbox I",
          },
          ids = {
            66733,
          },
          item = "Ancient Draconic Lockbox I",
        },
        Misc4 = {
          aliases = {
            "Scales of the Lava Dragon",
          },
          ids = {
            66904,
          },
          item = "Scales of the Lava Dragon",
        },
        Misc5 = {
          aliases = {
            "Draconium Surveyor's Waystone",
          },
          ids = {
            43224,
          },
          item = "Draconium Surveyor's Waystone",
        },
      },
      virtual = {
        ["2.75"] = {
          identity_role = "class_epic_2_75",
          note = "Display row for finished class Draconic epic; runtime satisfaction remains in bis_catalog.lua.",
          per_class = {
            Bard = {
              id = 55906,
              name = "Draconic Blade of Vesagran",
            },
            Beastlord = {
              id = 55912,
              name = "Spiritcaller Totem of the Dragons",
            },
            Berserker = {
              id = 55905,
              name = "Draconic Taelosian Blood Axe",
            },
            Cleric = {
              id = 55082,
              name = "Aegis of Draconic Divinity",
            },
            Druid = {
              id = 55729,
              name = "Staff of Draconic Brambles",
            },
            Enchanter = {
              id = 55909,
              name = "Staff of Draconic Eloquence",
            },
            Magician = {
              id = 55908,
              name = "Focus of Draconic Elements",
            },
            Monk = {
              id = 55730,
              name = "Draconic Fistwraps of Immortality",
            },
            Necromancer = {
              id = 55910,
              name = "Draconic Deathwhisper",
            },
            Paladin = {
              id = 55081,
              name = "Nightbane, Sword of the Dragons",
            },
            Ranger = {
              id = 55911,
              name = "Aurora, the Draconic Bow",
            },
            Rogue = {
              id = 55904,
              name = "Nightshade, Blade of Draconic Entropy",
            },
            ["Shadow Knight"] = {
              id = 55080,
              name = "Innoruuk's Draconic Blessing",
            },
            Shaman = {
              id = 55728,
              name = "Draconic Spiritstaff of the Heyokah",
            },
            Warrior = {
              id = 55079,
              name = "Kreljnok's Sword of Draconic Power",
            },
            Wizard = {
              id = 55907,
              name = "Staff of Draconic Power",
            },
          },
        },
        Reward = {
          identity_role = "reward",
          note = "Display row derived from explicit Shadow reward identities per class.",
          source_slot = "Shadow",
        },
        Scales = {
          display = "Scales",
          note = "Display row backed by template Misc4 Scales of the Lava Dragon.",
          source_slot = "Misc4",
        },
      },
      visible = {
      },
    },
    dsk = {
      categories = {
        {
          name = "Visibles",
          slots = {
            "Arms",
            "Chest",
            "Feet",
            "Hands",
            "Head",
            "Legs",
            "Wrist1",
            "Wrist2",
          },
        },
        {
          name = "Non-Visibles",
          slots = {
            "Back",
            "Ear1",
            "Ear2",
            "Face",
            "Finger1",
            "Finger2",
            "Neck",
            "Shoulder",
            "Waist",
          },
        },
        {
          name = "Weapons",
          slots = {
            "MainHand",
            "Secondary",
            "Ranged",
            "RangedAug",
            "Charm",
            "Clicky",
          },
        },
        {
          name = "Books",
          slots = {
            "Book1",
            "Book2",
            "Book3",
            "Wand",
          },
        },
        {
          name = "Augs",
          slots = {
            "Middle Finger (Mayong)",
            "Aug1",
            "Aug2",
            "Aug3",
            "Aug4",
            "Aug5",
            "Aug6",
            "Aug7",
            "Aug8",
            "Aug9",
            "Aug10",
            "Aug11",
            "Aug12",
            "Aug13",
            "Aug14",
            "Aug15",
            "Aug16",
            "Aug17",
            "Aug18",
            "Aug19",
            "Aug20",
          },
        },
      },
      classes = {
        Bard = {
          Arms = {
            aliases = {
              "Farseeker's Ascendant Armbands of Harmony",
            },
            ids = {
              32489,
            },
            item = "Farseeker's Ascendant Armbands of Harmony",
            source = "Brothers",
          },
          Aug20 = {
            aliases = {
              "Physical Prowess",
              "Hideous Hex of Physical Prowess",
            },
            ids = {
              33008,
            },
            item = "Physical Prowess",
            notes = "No focus effect | +15 STR/STA/AGI/DEX, +5 WIS/INT/CHA, +150 hp, +200 mana/endur, +15 ac",
          },
          Back = {
            aliases = {
              "Shroud of Calamitous Chic",
            },
            ids = {
            },
            item = "Shroud of Calamitous Chic",
            source = "Fippy",
          },
          Book1 = {
            aliases = {
              "Codex of Ancient Boon",
            },
            ids = {
              39670,
              39671,
              39672,
            },
            item = "Codex of Ancient Boon",
          },
          Book2 = {
            aliases = {
              "Codex of Potent Prowess",
            },
            ids = {
              39671,
            },
            item = "Codex of Potent Prowess",
          },
          Chest = {
            aliases = {
              "Farseeker's Ascendant Chestguard of Harmony",
            },
            ids = {
              32532,
            },
            item = "Farseeker's Ascendant Chestguard of Harmony",
            source = "Mayong",
          },
          Clicky = {
            aliases = {
              "Glint of the Grave",
            },
            ids = {
            },
            item = "Glint of the Grave",
            source = "Restless",
          },
          Ear1 = {
            aliases = {
              "Earhoop of Eternal Night",
            },
            ids = {
            },
            item = "Earhoop of Eternal Night",
            source = "Mayong",
          },
          Ear2 = {
            aliases = {
              "Poached Molar Pendant",
            },
            ids = {
            },
            item = "Poached Molar Pendant",
            source = "Cata",
          },
          Face = {
            aliases = {
              "Bandana of Brazen Banditry",
            },
            ids = {
            },
            item = "Bandana of Brazen Banditry",
            source = "Brothers",
          },
          Feet = {
            aliases = {
              "Farseeker's Ascendant Boots of Harmony",
            },
            ids = {
              32490,
            },
            item = "Farseeker's Ascendant Boots of Harmony",
            source = "First Four Names",
          },
          Finger1 = {
            aliases = {
              "Band of the Dragon's Bane",
            },
            ids = {
            },
            item = "Band of the Dragon's Bane",
            source = "Brothers",
          },
          Finger2 = {
            aliases = {
              "Luminary's Lavish Loop",
            },
            ids = {
            },
            item = "Luminary's Lavish Loop",
            source = "Mayong",
          },
          Hands = {
            aliases = {
              "Farseeker's Ascendant Gloves of Harmony",
            },
            ids = {
              32533,
            },
            item = "Farseeker's Ascendant Gloves of Harmony",
            source = "First Four Names",
          },
          Head = {
            aliases = {
              "Farseeker's Ascendant Helm of Harmony",
            },
            ids = {
              33000,
            },
            item = "Farseeker's Ascendant Helm of Harmony",
            source = "First Four Names",
          },
          Legs = {
            aliases = {
              "Farseeker's Ascendant Legguards of Harmony",
            },
            ids = {
              33001,
            },
            item = "Farseeker's Ascendant Legguards of Harmony",
            source = "Brothers",
          },
          Neck = {
            aliases = {
              "Covert Inquisitor's Collar",
            },
            ids = {
            },
            item = "Covert Inquisitor's Collar",
            source = "Cata",
          },
          Ranged = {
            aliases = {
              "Lightstone of the Ruined Lands",
            },
            ids = {
            },
            item = "Lightstone of the Ruined Lands",
            source = "Fippy",
          },
          RangedAug = {
            aliases = {
              "Rat Ears",
            },
            ids = {
            },
            item = "Rat Ears",
            source = "Fippy",
          },
          Secondary = {
            aliases = {
              "Shimmer of Strife",
            },
            ids = {
            },
            item = "Shimmer of Strife",
            source = "Restless",
          },
          Shoulder = {
            aliases = {
              "Ornate Pauldrons of Proficience",
            },
            ids = {
            },
            item = "Ornate Pauldrons of Proficience",
            source = "Drinker",
          },
          Waist = {
            aliases = {
              "Shabby Crimson Sash",
            },
            ids = {
            },
            item = "Shabby Crimson Sash",
            source = "Sebastian",
          },
          Wrist1 = {
            aliases = {
              "Farseeker's Ascendant Wristguard of Harmony",
            },
            ids = {
              33002,
            },
            item = "Farseeker's Ascendant Wristguard of Harmony",
            source = "First Four Names",
          },
          Wrist2 = {
            aliases = {
              "Farseeker's Eternal Bracer",
            },
            ids = {
              31648,
            },
            item = "Farseeker's Eternal Bracer",
            source = "Fippy",
          },
        },
        Beastlord = {
          Arms = {
            aliases = {
              "Savagesoul's Ascendant Sleeves of the Wilds",
            },
            ids = {
              32487,
            },
            item = "Savagesoul's Ascendant Sleeves of the Wilds",
          },
          Aug20 = {
            aliases = {
              "Physical Prowess",
              "Hideous Hex of Physical Prowess",
            },
            ids = {
              33008,
            },
            item = "Physical Prowess",
            notes = "No focus effect | +15 STR/STA/AGI/DEX, +5 WIS/INT/CHA, +150 hp, +200 mana/endur, +15 ac",
          },
          Back = {
            aliases = {
              "Shroud of Calamitous Chic",
            },
            ids = {
            },
            item = "Shroud of Calamitous Chic",
            source = "Fippy",
          },
          Book1 = {
            aliases = {
              "Codex of Ancient Boon",
            },
            ids = {
              39670,
              39671,
              39672,
            },
            item = "Codex of Ancient Boon",
          },
          Book2 = {
            aliases = {
              "Codex of Potent Prowess",
            },
            ids = {
              39671,
            },
            item = "Codex of Potent Prowess",
          },
          Book3 = {
            aliases = {
              "Codex of Minion's Materiel",
            },
            ids = {
            },
            item = "Codex of Minion's Materiel",
          },
          Chest = {
            aliases = {
              "Savagesoul's Ascendant Jerkin of the Wilds",
            },
            ids = {
              32484,
            },
            item = "Savagesoul's Ascendant Jerkin of the Wilds",
          },
          Ear1 = {
            aliases = {
              "Adornment of the Antagonist",
            },
            ids = {
            },
            item = "Adornment of the Antagonist",
            source = "Mayong",
          },
          Ear2 = {
            aliases = {
              "Poached Molar Pendant",
            },
            ids = {
            },
            item = "Poached Molar Pendant",
            source = "Cata",
          },
          Face = {
            aliases = {
              "Bandana of Brazen Banditry",
            },
            ids = {
            },
            item = "Bandana of Brazen Banditry",
            source = "Brothers",
          },
          Feet = {
            aliases = {
              "Savagesoul's Ascendant Sandals of the Wilds",
            },
            ids = {
              32486,
            },
            item = "Savagesoul's Ascendant Sandals of the Wilds",
          },
          Finger1 = {
            aliases = {
              "Band of the Dragon's Bane",
            },
            ids = {
            },
            item = "Band of the Dragon's Bane",
            source = "Brothers",
          },
          Finger2 = {
            aliases = {
              "Ringlet of Restless Spirits",
            },
            ids = {
            },
            item = "Ringlet of Restless Spirits",
            source = "Mayong",
          },
          Hands = {
            aliases = {
              "Savagesoul's Ascendant Gloves of the Wilds",
            },
            ids = {
              32483,
            },
            item = "Savagesoul's Ascendant Gloves of the Wilds",
          },
          Head = {
            aliases = {
              "Savagesoul's Ascendant Cap of the Wilds",
            },
            ids = {
              32482,
            },
            item = "Savagesoul's Ascendant Cap of the Wilds",
          },
          Legs = {
            aliases = {
              "Savagesoul's Ascendant Legguards of the Wilds",
            },
            ids = {
              32485,
            },
            item = "Savagesoul's Ascendant Legguards of the Wilds",
          },
          MainHand = {
            aliases = {
              "Germinating Fungal Eviscerator",
            },
            ids = {
            },
            item = "Germinating Fungal Eviscerator",
            source = "Restless",
          },
          Neck = {
            aliases = {
              "Covert Inquisitor's Collar",
            },
            ids = {
            },
            item = "Covert Inquisitor's Collar",
            source = "Cata",
          },
          Ranged = {
            aliases = {
              "Brazier of the Ruined Lands",
            },
            ids = {
            },
            item = "Brazier of the Ruined Lands",
            source = "Fippy",
          },
          RangedAug = {
            aliases = {
              "Fish Scales",
            },
            ids = {
            },
            item = "Fish Scales",
            source = "Fippy",
          },
          Shoulder = {
            aliases = {
              "Ornate Pauldrons of Proficience",
            },
            ids = {
            },
            item = "Ornate Pauldrons of Proficience",
            source = "Drinker",
          },
          Waist = {
            aliases = {
              "Shabby Crimson Sash",
            },
            ids = {
            },
            item = "Shabby Crimson Sash",
            source = "Sebastian",
          },
          Wrist1 = {
            aliases = {
              "Savagesoul's Ascendant Wristband of the Wilds",
            },
            ids = {
              32488,
            },
            item = "Savagesoul's Ascendant Wristband of the Wilds",
          },
          Wrist2 = {
            aliases = {
              "Savagesoul's Eternal Bracer",
            },
            ids = {
              31647,
            },
            item = "Savagesoul's Eternal Bracer",
          },
        },
        Berserker = {
          Arms = {
            aliases = {
              "Wrathbringer's Ascendant Sleeves of the Vindicator",
            },
            ids = {
              31710,
            },
            item = "Wrathbringer's Ascendant Sleeves of the Vindicator",
            source = "Brothers",
          },
          Aug20 = {
            aliases = {
              "Physical Prowess",
              "Hideous Hex of Physical Prowess",
            },
            ids = {
              33008,
            },
            item = "Physical Prowess",
            notes = "No focus effect | +15 STR/STA/AGI/DEX, +5 WIS/INT/CHA, +150 hp, +200 mana/endur, +15 ac",
          },
          Back = {
            aliases = {
              "Shroud of Calamitous Chic",
            },
            ids = {
            },
            item = "Shroud of Calamitous Chic",
            source = "Fippy",
          },
          Book1 = {
            aliases = {
              "Codex of Ancient Boon",
            },
            ids = {
              39670,
              39671,
              39672,
            },
            item = "Codex of Ancient Boon",
          },
          Book2 = {
            aliases = {
              "Codex of Potent Prowess",
            },
            ids = {
              39671,
            },
            item = "Codex of Potent Prowess",
          },
          Chest = {
            aliases = {
              "Wrathbringer's Ascendant Chestguard of the Vindicator",
            },
            ids = {
              31706,
            },
            item = "Wrathbringer's Ascendant Chestguard of the Vindicator",
            source = "Mayong",
          },
          Ear1 = {
            aliases = {
              "Adornment of the Antagonist",
            },
            ids = {
            },
            item = "Adornment of the Antagonist",
            source = "Mayong",
          },
          Ear2 = {
            aliases = {
              "Poached Molar Pendant",
            },
            ids = {
            },
            item = "Poached Molar Pendant",
            source = "Cata",
          },
          Face = {
            aliases = {
              "Bandana of Brazen Banditry",
            },
            ids = {
            },
            item = "Bandana of Brazen Banditry",
            source = "Brothers",
          },
          Feet = {
            aliases = {
              "Wrathbringer's Ascendant Boots of the Vindicator",
            },
            ids = {
              31688,
            },
            item = "Wrathbringer's Ascendant Boots of the Vindicator",
            source = "First Four Names",
          },
          Finger1 = {
            aliases = {
              "Band of the Dragon's Bane",
            },
            ids = {
            },
            item = "Band of the Dragon's Bane",
            source = "Brothers",
          },
          Finger2 = {
            aliases = {
              "Ringlet of Restless Spirits",
            },
            ids = {
            },
            item = "Ringlet of Restless Spirits",
            source = "Mayong",
          },
          Hands = {
            aliases = {
              "Wrathbringer's Ascendant Gloves of the Vindicator",
            },
            ids = {
              31707,
            },
            item = "Wrathbringer's Ascendant Gloves of the Vindicator",
            source = "First Four Names",
          },
          Head = {
            aliases = {
              "Wrathbringer's Ascendant Helm of the Vindicator",
            },
            ids = {
              31708,
            },
            item = "Wrathbringer's Ascendant Helm of the Vindicator",
            source = "First Four Names",
          },
          Legs = {
            aliases = {
              "Wrathbringer's Ascendant Leggings of the Vindicator",
            },
            ids = {
              31709,
            },
            item = "Wrathbringer's Ascendant Leggings of the Vindicator",
            source = "Brothers",
          },
          Neck = {
            aliases = {
              "Covert Inquisitor's Collar",
            },
            ids = {
            },
            item = "Covert Inquisitor's Collar",
            source = "Cata",
          },
          Ranged = {
            aliases = {
              "Lightstone of the Ruined Lands",
            },
            ids = {
            },
            item = "Lightstone of the Ruined Lands",
            source = "Fippy",
          },
          RangedAug = {
            aliases = {
              "Rat Ears",
            },
            ids = {
            },
            item = "Rat Ears",
            source = "Fippy",
          },
          Secondary = {
            aliases = {
              "Rage-Infused Shadows",
            },
            ids = {
            },
            item = "Rage-Infused Shadows",
            source = "Restless",
          },
          Shoulder = {
            aliases = {
              "Ornate Pauldrons of Proficience",
            },
            ids = {
            },
            item = "Ornate Pauldrons of Proficience",
            source = "Drinker",
          },
          Waist = {
            aliases = {
              "Shabby Crimson Sash",
            },
            ids = {
            },
            item = "Shabby Crimson Sash",
            source = "Sebastian",
          },
          Wrist1 = {
            aliases = {
              "Wrathbringer's Ascendant Wristguard of the Vindicator",
            },
            ids = {
              31711,
            },
            item = "Wrathbringer's Ascendant Wristguard of the Vindicator",
            source = "First Four Names",
          },
          Wrist2 = {
            aliases = {
              "Wrathbringer's Eternal Bracer",
            },
            ids = {
              30583,
            },
            item = "Wrathbringer's Eternal Bracer",
            source = "Fippy",
          },
        },
        Cleric = {
          Arms = {
            aliases = {
              "Faithbringer's Ascendant Armguards of Conviction",
            },
            ids = {
              31712,
            },
            item = "Faithbringer's Ascendant Armguards of Conviction",
            source = "Brothers",
          },
          Aug20 = {
            aliases = {
              "Mental Prowess",
              "Hideous Hex of Mental Prowess",
            },
            ids = {
              33011,
            },
            item = "Mental Prowess",
            notes = "No focus effect | +15 WIS/INT/CHA, +5 STR/STA/AGI/DEX, +130 hp, +360 mana, +13 ac, +10 resists",
          },
          Back = {
            aliases = {
              "Gilded Cloak of Grandeur",
            },
            ids = {
            },
            item = "Gilded Cloak of Grandeur",
            source = "Drinker",
          },
          Book1 = {
            aliases = {
              "Codex of Ancient Boon",
            },
            ids = {
              39670,
              39671,
              39672,
            },
            item = "Codex of Ancient Boon",
          },
          Book2 = {
            aliases = {
              "Codex of Scribe's Endurance",
            },
            ids = {
              39672,
            },
            item = "Codex of Scribe's Endurance",
          },
          Chest = {
            aliases = {
              "Faithbringer's Ascendant Breastplate of Conviction",
            },
            ids = {
              32251,
            },
            item = "Faithbringer's Ascendant Breastplate of Conviction",
            source = "Mayong",
          },
          Clicky = {
            aliases = {
              "Glint of the Grave",
            },
            ids = {
            },
            item = "Glint of the Grave",
            source = "Restless",
          },
          Ear1 = {
            aliases = {
              "Earhoop of Eternal Night",
            },
            ids = {
            },
            item = "Earhoop of Eternal Night",
            source = "Mayong",
          },
          Ear2 = {
            aliases = {
              "Aristocrat's Opulent Adornment",
            },
            ids = {
            },
            item = "Aristocrat's Opulent Adornment",
            source = "Sebastian",
          },
          Face = {
            aliases = {
              "Eerie Veil of the Enigma",
            },
            ids = {
            },
            item = "Eerie Veil of the Enigma",
            source = "Sebastian",
          },
          Feet = {
            aliases = {
              "Faithbringer's Ascendant Boots of Conviction",
            },
            ids = {
              32250,
            },
            item = "Faithbringer's Ascendant Boots of Conviction",
            source = "First Four Names",
          },
          Finger1 = {
            aliases = {
              "Circlet of Convalescence",
            },
            ids = {
            },
            item = "Circlet of Convalescence",
            source = "Drinker",
          },
          Finger2 = {
            aliases = {
              "Luminary's Lavish Loop",
            },
            ids = {
            },
            item = "Luminary's Lavish Loop",
            source = "Mayong",
          },
          Hands = {
            aliases = {
              "Faithbringer's Ascendant Gloves of Conviction",
            },
            ids = {
              32253,
            },
            item = "Faithbringer's Ascendant Gloves of Conviction",
            source = "First Four Names",
          },
          Head = {
            aliases = {
              "Faithbringer's Ascendant Cap of Conviction",
            },
            ids = {
              32252,
            },
            item = "Faithbringer's Ascendant Cap of Conviction",
            source = "First Four Names",
          },
          Legs = {
            aliases = {
              "Faithbringer's Ascendant Leggings of Conviction",
            },
            ids = {
              32254,
            },
            item = "Faithbringer's Ascendant Leggings of Conviction",
            source = "Brothers",
          },
          Neck = {
            aliases = {
              "Advocate's Amethyst Lavalliere",
            },
            ids = {
            },
            item = "Advocate's Amethyst Lavalliere",
            source = "Brothers",
          },
          Ranged = {
            aliases = {
              "Lantern of the Ruined Lands",
            },
            ids = {
            },
            item = "Lantern of the Ruined Lands",
            source = "Fippy",
          },
          RangedAug = {
            aliases = {
              "Bone Chips",
            },
            ids = {
            },
            item = "Bone Chips",
            source = "Fippy",
          },
          Shoulder = {
            aliases = {
              "Epaulettes of Sacramental Faith",
            },
            ids = {
            },
            item = "Epaulettes of Sacramental Faith",
            source = "Cata",
          },
          Waist = {
            aliases = {
              "Consecrated Cummerbund of Compassion",
            },
            ids = {
            },
            item = "Consecrated Cummerbund of Compassion",
            source = "Fippy",
          },
          Wrist1 = {
            aliases = {
              "Faithbringer's Ascendant Wristband of Conviction",
            },
            ids = {
              32255,
            },
            item = "Faithbringer's Ascendant Wristband of Conviction",
            source = "First Four Names",
          },
          Wrist2 = {
            aliases = {
              "Faithbringer's Eternal Bracer",
            },
            ids = {
              30771,
            },
            item = "Faithbringer's Eternal Bracer",
            source = "Fippy",
          },
        },
        Druid = {
          Arms = {
            aliases = {
              "Everspring's Ascendant Sleeves of the Tangled Briars",
            },
            ids = {
              32341,
            },
            item = "Everspring's Ascendant Sleeves of the Tangled Briars",
            source = "Brothers",
          },
          Aug20 = {
            aliases = {
              "Mental Prowess",
              "Hideous Hex of Mental Prowess",
            },
            ids = {
              33011,
            },
            item = "Mental Prowess",
            notes = "No focus effect | +15 WIS/INT/CHA, +5 STR/STA/AGI/DEX, +130 hp, +360 mana, +13 ac, +10 resists",
          },
          Back = {
            aliases = {
              "Gilded Cloak of Grandeur",
            },
            ids = {
            },
            item = "Gilded Cloak of Grandeur",
            source = "Drinker",
          },
          Book1 = {
            aliases = {
              "Codex of Ancient Boon",
            },
            ids = {
              39670,
              39671,
              39672,
            },
            item = "Codex of Ancient Boon",
          },
          Book2 = {
            aliases = {
              "Codex of Scribe's Endurance",
            },
            ids = {
              39672,
            },
            item = "Codex of Scribe's Endurance",
          },
          Book3 = {
            aliases = {
              "Codex of Minion's Materiel",
            },
            ids = {
            },
            item = "Codex of Minion's Materiel",
          },
          Chest = {
            aliases = {
              "Everspring's Ascendant Jerkin of the Tangled Briars",
            },
            ids = {
              32264,
            },
            item = "Everspring's Ascendant Jerkin of the Tangled Briars",
            source = "Mayong",
          },
          Ear1 = {
            aliases = {
              "Earhoop of Eternal Night",
            },
            ids = {
            },
            item = "Earhoop of Eternal Night",
            source = "Mayong",
          },
          Ear2 = {
            aliases = {
              "Aristocrat's Opulent Adornment",
            },
            ids = {
            },
            item = "Aristocrat's Opulent Adornment",
            source = "Sebastian",
          },
          Face = {
            aliases = {
              "Eerie Veil of the Enigma",
            },
            ids = {
            },
            item = "Eerie Veil of the Enigma",
            source = "Sebastian",
          },
          Feet = {
            aliases = {
              "Everspring's Ascendant Slippers of the Tangled Briars",
            },
            ids = {
              32342,
            },
            item = "Everspring's Ascendant Slippers of the Tangled Briars",
            source = "First Four Names",
          },
          Finger1 = {
            aliases = {
              "Circlet of Convalescence",
            },
            ids = {
            },
            item = "Circlet of Convalescence",
            source = "Drinker",
          },
          Finger2 = {
            aliases = {
              "Luminary's Lavish Loop",
            },
            ids = {
            },
            item = "Luminary's Lavish Loop",
            source = "Mayong",
          },
          Hands = {
            aliases = {
              "Everspring's Ascendant Mitts of the Tangled Briars",
            },
            ids = {
              32265,
            },
            item = "Everspring's Ascendant Mitts of the Tangled Briars",
            source = "First Four Names",
          },
          Head = {
            aliases = {
              "Everspring's Ascendant  Cap of the Tangled Briars",
            },
            ids = {
              32263,
            },
            item = "Everspring's Ascendant  Cap of the Tangled Briars",
            source = "First Four Names",
          },
          Legs = {
            aliases = {
              "Everspring's Ascendant Pants of the Tangled Briars",
            },
            ids = {
              32266,
            },
            item = "Everspring's Ascendant Pants of the Tangled Briars",
            source = "Brothers",
          },
          Neck = {
            aliases = {
              "Advocate's Amethyst Lavalliere",
            },
            ids = {
            },
            item = "Advocate's Amethyst Lavalliere",
            source = "Brothers",
          },
          Ranged = {
            aliases = {
              "Lantern of the Ruined Lands",
            },
            ids = {
            },
            item = "Lantern of the Ruined Lands",
            source = "Fippy",
          },
          RangedAug = {
            aliases = {
              "Bone Chips",
            },
            ids = {
            },
            item = "Bone Chips",
            source = "Fippy",
          },
          Secondary = {
            aliases = {
              "Furtive Aegis of the Sanguine",
            },
            ids = {
              24142,
            },
            item = "Furtive Aegis of the Sanguine",
            source = "Restless",
          },
          Shoulder = {
            aliases = {
              "Epaulettes of Sacramental Faith",
            },
            ids = {
            },
            item = "Epaulettes of Sacramental Faith",
            source = "Cata",
          },
          Waist = {
            aliases = {
              "Consecrated Cummerbund of Compassion",
            },
            ids = {
            },
            item = "Consecrated Cummerbund of Compassion",
            source = "Fippy",
          },
          Wrist1 = {
            aliases = {
              "Everspring's Ascendant Wristband of the Tangled Briars",
            },
            ids = {
              32343,
            },
            item = "Everspring's Ascendant Wristband of the Tangled Briars",
            source = "First Four Names",
          },
          Wrist2 = {
            aliases = {
              "Everspring's Eternal Bracer",
            },
            ids = {
              31639,
            },
            item = "Everspring's Eternal Bracer",
            source = "Fippy",
          },
        },
        Enchanter = {
          Arms = {
            aliases = {
              "Mindreaver's Ascendant Armguards of Coercion",
            },
            ids = {
              32358,
            },
            item = "Mindreaver's Ascendant Armguards of Coercion",
            source = "Brothers",
          },
          Aug20 = {
            aliases = {
              "Mental Prowess",
              "Hideous Hex of Mental Prowess",
            },
            ids = {
              33011,
            },
            item = "Mental Prowess",
            notes = "No focus effect | +15 WIS/INT/CHA, +5 STR/STA/AGI/DEX, +130 hp, +360 mana, +13 ac, +10 resists",
          },
          Back = {
            aliases = {
              "Silken Shawl of Sanguine Salacity",
            },
            ids = {
            },
            item = "Silken Shawl of Sanguine Salacity",
            source = "Cata",
          },
          Book1 = {
            aliases = {
              "Codex of Ancient Boon",
            },
            ids = {
              39670,
              39671,
              39672,
            },
            item = "Codex of Ancient Boon",
          },
          Book2 = {
            aliases = {
              "Codex of Scribe's Endurance",
            },
            ids = {
              39672,
            },
            item = "Codex of Scribe's Endurance",
          },
          Book3 = {
            aliases = {
              "Codex of Minion's Materiel",
            },
            ids = {
            },
            item = "Codex of Minion's Materiel",
          },
          Chest = {
            aliases = {
              "Mindreaver's Ascendant Vest of Coercion",
            },
            ids = {
              32376,
            },
            item = "Mindreaver's Ascendant Vest of Coercion",
            source = "Mayong",
          },
          Ear1 = {
            aliases = {
              "Earhoop of Eternal Night",
            },
            ids = {
            },
            item = "Earhoop of Eternal Night",
            source = "Mayong",
          },
          Ear2 = {
            aliases = {
              "Astral Emblem of Augury",
            },
            ids = {
            },
            item = "Astral Emblem of Augury",
            source = "Brothers",
          },
          Face = {
            aliases = {
              "Insidious Imposter's Masquerade",
            },
            ids = {
            },
            item = "Insidious Imposter's Masquerade",
            source = "Drinker",
          },
          Feet = {
            aliases = {
              "Mindreaver's Ascendant Shoes of Coercion",
            },
            ids = {
              32374,
            },
            item = "Mindreaver's Ascendant Shoes of Coercion",
            source = "First Four Names",
          },
          Finger1 = {
            aliases = {
              "Coterie's Covetous Circlet",
            },
            ids = {
            },
            item = "Coterie's Covetous Circlet",
            source = "Cata",
          },
          Finger2 = {
            aliases = {
              "Luminary's Lavish Loop",
            },
            ids = {
            },
            item = "Luminary's Lavish Loop",
            source = "Mayong",
          },
          Hands = {
            aliases = {
              "Mindreaver's Ascendant Handguards of Coercion",
            },
            ids = {
              32360,
            },
            item = "Mindreaver's Ascendant Handguards of Coercion",
            source = "First Four Names",
          },
          Head = {
            aliases = {
              "Mindreaver's Ascendant Skullcap of Coercion",
            },
            ids = {
              32375,
            },
            item = "Mindreaver's Ascendant Skullcap of Coercion",
            source = "First Four Names",
          },
          Legs = {
            aliases = {
              "Mindreaver's Ascendant Leggings of Coercion",
            },
            ids = {
              32361,
            },
            item = "Mindreaver's Ascendant Leggings of Coercion",
            source = "Brothers",
          },
          Neck = {
            aliases = {
              "Razor Edge of Rancor",
            },
            ids = {
            },
            item = "Razor Edge of Rancor",
            source = "Sebastian",
          },
          Ranged = {
            aliases = {
              "Torch of the Ruined Lands",
            },
            ids = {
            },
            item = "Torch of the Ruined Lands",
            source = "Fippy",
          },
          RangedAug = {
            aliases = {
              "Bat Wing",
            },
            ids = {
            },
            item = "Bat Wing",
            source = "Fippy",
          },
          Secondary = {
            aliases = {
              "Furtive Aegis of the Sanguine",
            },
            ids = {
            },
            item = "Furtive Aegis of the Sanguine",
            source = "Restless",
          },
          Shoulder = {
            aliases = {
              "Woven Mantle of Mastery",
            },
            ids = {
            },
            item = "Woven Mantle of Mastery",
            source = "Brothers",
          },
          Waist = {
            aliases = {
              "Spurred Sash of Suffering",
            },
            ids = {
            },
            item = "Spurred Sash of Suffering",
            source = "Fippy",
          },
          Wrist1 = {
            aliases = {
              "Mindreaver's Ascendant Bracer of Coercion",
            },
            ids = {
              32359,
            },
            item = "Mindreaver's Ascendant Bracer of Coercion",
            source = "First Four Names",
          },
          Wrist2 = {
            aliases = {
              "Mindreaver's Eternal Bracer",
            },
            ids = {
              31642,
            },
            item = "Mindreaver's Eternal Bracer",
            source = "Fippy",
          },
        },
        Magician = {
          Arms = {
            aliases = {
              "Glyphwielder's Ascendant Sleeves of the Summoner",
            },
            ids = {
              32354,
            },
            item = "Glyphwielder's Ascendant Sleeves of the Summoner",
            source = "Brothers",
          },
          Aug20 = {
            aliases = {
              "Mental Prowess",
              "Hideous Hex of Mental Prowess",
            },
            ids = {
              33011,
            },
            item = "Mental Prowess",
            notes = "No focus effect | +15 WIS/INT/CHA, +5 STR/STA/AGI/DEX, +130 hp, +360 mana, +13 ac, +10 resists",
          },
          Back = {
            aliases = {
              "Silken Shawl of Sanguine Salacity",
            },
            ids = {
            },
            item = "Silken Shawl of Sanguine Salacity",
            source = "Cata",
          },
          Book1 = {
            aliases = {
              "Codex of Ancient Boon",
            },
            ids = {
              39670,
              39671,
              39672,
            },
            item = "Codex of Ancient Boon",
          },
          Book2 = {
            aliases = {
              "Codex of Scribe's Endurance",
            },
            ids = {
              39672,
            },
            item = "Codex of Scribe's Endurance",
          },
          Book3 = {
            aliases = {
              "Codex of Minion's Materiel",
            },
            ids = {
            },
            item = "Codex of Minion's Materiel",
          },
          Chest = {
            aliases = {
              "Glyphwielder's Ascendant Tunic of the Summoner",
            },
            ids = {
              32356,
            },
            item = "Glyphwielder's Ascendant Tunic of the Summoner",
            source = "Mayong",
          },
          Ear1 = {
            aliases = {
              "Earhoop of Eternal Night",
            },
            ids = {
            },
            item = "Earhoop of Eternal Night",
            source = "Mayong",
          },
          Ear2 = {
            aliases = {
              "Astral Emblem of Augury",
            },
            ids = {
            },
            item = "Astral Emblem of Augury",
            source = "Brothers",
          },
          Face = {
            aliases = {
              "Insidious Imposter's Masquerade",
            },
            ids = {
            },
            item = "Insidious Imposter's Masquerade",
            source = "Drinker",
          },
          Feet = {
            aliases = {
              "Glyphwielder's Ascendant Slippers of the Summoner",
            },
            ids = {
              32355,
            },
            item = "Glyphwielder's Ascendant Slippers of the Summoner",
            source = "First Four Names",
          },
          Finger1 = {
            aliases = {
              "Coterie's Covetous Circlet",
            },
            ids = {
            },
            item = "Coterie's Covetous Circlet",
            source = "Cata",
          },
          Finger2 = {
            aliases = {
              "Luminary's Lavish Loop",
            },
            ids = {
            },
            item = "Luminary's Lavish Loop",
            source = "Mayong",
          },
          Hands = {
            aliases = {
              "Glyphwielder's Ascendant Gloves of the Summoner",
            },
            ids = {
              32351,
            },
            item = "Glyphwielder's Ascendant Gloves of the Summoner",
            source = "First Four Names",
          },
          Head = {
            aliases = {
              "Glyphwielder's Ascendant Hat of the Summoner",
            },
            ids = {
              32352,
            },
            item = "Glyphwielder's Ascendant Hat of the Summoner",
            source = "First Four Names",
          },
          Legs = {
            aliases = {
              "Glyphwielder's Ascendant Leggings of the Summoner",
            },
            ids = {
              32353,
            },
            item = "Glyphwielder's Ascendant Leggings of the Summoner",
            source = "Brothers",
          },
          Neck = {
            aliases = {
              "Razor Edge of Rancor",
            },
            ids = {
            },
            item = "Razor Edge of Rancor",
            source = "Sebastian",
          },
          Ranged = {
            aliases = {
              "Torch of the Ruined Lands",
            },
            ids = {
            },
            item = "Torch of the Ruined Lands",
            source = "Fippy",
          },
          RangedAug = {
            aliases = {
              "Bat Wing",
            },
            ids = {
            },
            item = "Bat Wing",
            source = "Fippy",
          },
          Secondary = {
            aliases = {
              "Stave of Scorching Frost",
            },
            ids = {
            },
            item = "Stave of Scorching Frost",
            source = "Restless",
          },
          Shoulder = {
            aliases = {
              "Woven Mantle of Mastery",
            },
            ids = {
            },
            item = "Woven Mantle of Mastery",
            source = "Brothers",
          },
          Waist = {
            aliases = {
              "Spurred Sash of Suffering",
            },
            ids = {
            },
            item = "Spurred Sash of Suffering",
            source = "Fippy",
          },
          Wrist1 = {
            aliases = {
              "Glyphwielder's Ascendant Wristband of the Summoner",
            },
            ids = {
              32357,
            },
            item = "Glyphwielder's Ascendant Wristband of the Summoner",
            source = "First Four Names",
          },
          Wrist2 = {
            aliases = {
              "Glyphwielder's Eternal Bracer",
            },
            ids = {
              31641,
            },
            item = "Glyphwielder's Eternal Bracer",
            source = "Fippy",
          },
        },
        Monk = {
          Arms = {
            aliases = {
              "Fiercehand's Ascendant Sleeves of the Focused",
            },
            ids = {
              31678,
              82651,
            },
            item = "Fiercehand's Ascendant Sleeves of the Focused",
            source = "Brothers",
          },
          Aug20 = {
            aliases = {
              "Physical Prowess",
              "Hideous Hex of Physical Prowess",
            },
            ids = {
              33008,
            },
            item = "Physical Prowess",
            notes = "No focus effect | +15 STR/STA/AGI/DEX, +5 WIS/INT/CHA, +150 hp, +200 mana/endur, +15 ac",
          },
          Back = {
            aliases = {
              "Shroud of Calamitous Chic",
            },
            ids = {
            },
            item = "Shroud of Calamitous Chic",
            source = "Fippy",
          },
          Book1 = {
            aliases = {
              "Codex of Ancient Boon",
            },
            ids = {
              39670,
              39671,
              39672,
            },
            item = "Codex of Ancient Boon",
          },
          Book2 = {
            aliases = {
              "Codex of Potent Prowess",
            },
            ids = {
              39671,
            },
            item = "Codex of Potent Prowess",
          },
          Chest = {
            aliases = {
              "Fiercehand's Ascendant Shroud of the Focused",
            },
            ids = {
              31677,
              82650,
            },
            item = "Fiercehand's Ascendant Shroud of the Focused",
            source = "Mayong",
          },
          Ear1 = {
            aliases = {
              "Adornment of the Antagonist",
            },
            ids = {
            },
            item = "Adornment of the Antagonist",
            source = "Mayong",
          },
          Ear2 = {
            aliases = {
              "Poached Molar Pendant",
            },
            ids = {
            },
            item = "Poached Molar Pendant",
            source = "Cata",
          },
          Face = {
            aliases = {
              "Bandana of Brazen Banditry",
            },
            ids = {
            },
            item = "Bandana of Brazen Banditry",
            source = "Brothers",
          },
          Feet = {
            aliases = {
              "Fiercehand's Ascendant Tabis of the Focused",
            },
            ids = {
              31679,
              82652,
            },
            item = "Fiercehand's Ascendant Tabis of the Focused",
            source = "First Four Names",
          },
          Finger1 = {
            aliases = {
              "Band of the Dragon's Bane",
            },
            ids = {
            },
            item = "Band of the Dragon's Bane",
            source = "Brothers",
          },
          Finger2 = {
            aliases = {
              "Ringlet of Restless Spirits",
            },
            ids = {
            },
            item = "Ringlet of Restless Spirits",
            source = "Mayong",
          },
          Hands = {
            aliases = {
              "Fiercehand's Ascendant Gloves of the Focused",
            },
            ids = {
              31675,
              82648,
            },
            item = "Fiercehand's Ascendant Gloves of the Focused",
            source = "First Four Names",
          },
          Head = {
            aliases = {
              "Fiercehand's Ascendant Cap of the Focused",
            },
            ids = {
              31674,
              82647,
            },
            item = "Fiercehand's Ascendant Cap of the Focused",
            source = "First Four Names",
          },
          Legs = {
            aliases = {
              "Fiercehand's Ascendant Leggings of the Focused",
            },
            ids = {
              31676,
              82649,
            },
            item = "Fiercehand's Ascendant Leggings of the Focused",
            source = "Brothers",
          },
          MainHand = {
            aliases = {
              "Infectious Fungal Eviscerator",
            },
            ids = {
            },
            item = "Infectious Fungal Eviscerator",
            source = "Restless",
          },
          Neck = {
            aliases = {
              "Covert Inquisitor's Collar",
            },
            ids = {
            },
            item = "Covert Inquisitor's Collar",
            source = "Cata",
          },
          Ranged = {
            aliases = {
              "Lightstone of the Ruined Lands",
            },
            ids = {
            },
            item = "Lightstone of the Ruined Lands",
            source = "Fippy",
          },
          RangedAug = {
            aliases = {
              "Rat Ears",
            },
            ids = {
            },
            item = "Rat Ears",
            source = "Fippy",
          },
          Shoulder = {
            aliases = {
              "Ornate Pauldrons of Proficience",
            },
            ids = {
            },
            item = "Ornate Pauldrons of Proficience",
            source = "Drinker",
          },
          Waist = {
            aliases = {
              "Shabby Crimson Sash",
            },
            ids = {
            },
            item = "Shabby Crimson Sash",
            source = "Sebastian",
          },
          Wrist1 = {
            aliases = {
              "Fiercehand's Ascendant Wristband of the Focused",
            },
            ids = {
              31680,
              82653,
            },
            item = "Fiercehand's Ascendant Wristband of the Focused",
            source = "First Four Names",
          },
          Wrist2 = {
            aliases = {
              "Fiercehand's Eternal Bracer",
            },
            ids = {
              29705,
            },
            item = "Fiercehand's Eternal Bracer",
            source = "Fippy",
          },
        },
        Necromancer = {
          Arms = {
            aliases = {
              "Blightbringer's Ascendant Armband of the Grave",
            },
            ids = {
              32377,
            },
            item = "Blightbringer's Ascendant Armband of the Grave",
            source = "Brothers",
          },
          Aug20 = {
            aliases = {
              "Mental Prowess",
              "Hideous Hex of Mental Prowess",
            },
            ids = {
              33011,
            },
            item = "Mental Prowess",
            notes = "No focus effect | +15 WIS/INT/CHA, +5 STR/STA/AGI/DEX, +130 hp, +360 mana, +13 ac, +10 resists",
          },
          Back = {
            aliases = {
              "Silken Shawl of Sanguine Salacity",
            },
            ids = {
            },
            item = "Silken Shawl of Sanguine Salacity",
            source = "Cata",
          },
          Book1 = {
            aliases = {
              "Codex of Ancient Boon",
            },
            ids = {
              39670,
              39671,
              39672,
            },
            item = "Codex of Ancient Boon",
          },
          Book2 = {
            aliases = {
              "Codex of Scribe's Endurance",
            },
            ids = {
              39672,
            },
            item = "Codex of Scribe's Endurance",
          },
          Book3 = {
            aliases = {
              "Codex of Minion's Materiel",
            },
            ids = {
            },
            item = "Codex of Minion's Materiel",
          },
          Chest = {
            aliases = {
              "Blightbringer's Ascendant Tunic of the Grave",
            },
            ids = {
              32453,
            },
            item = "Blightbringer's Ascendant Tunic of the Grave",
            source = "Mayong",
          },
          Ear1 = {
            aliases = {
              "Earhoop of Eternal Night",
            },
            ids = {
            },
            item = "Earhoop of Eternal Night",
            source = "Mayong",
          },
          Ear2 = {
            aliases = {
              "Astral Emblem of Augury",
            },
            ids = {
            },
            item = "Astral Emblem of Augury",
            source = "Brothers",
          },
          Face = {
            aliases = {
              "Insidious Imposter's Masquerade",
            },
            ids = {
            },
            item = "Insidious Imposter's Masquerade",
            source = "Drinker",
          },
          Feet = {
            aliases = {
              "Blightbringer's Ascendant Sandals of the Grave",
            },
            ids = {
              32452,
            },
            item = "Blightbringer's Ascendant Sandals of the Grave",
            source = "First Four Names",
          },
          Finger1 = {
            aliases = {
              "Coterie's Covetous Circlet",
            },
            ids = {
            },
            item = "Coterie's Covetous Circlet",
            source = "Cata",
          },
          Finger2 = {
            aliases = {
              "Luminary's Lavish Loop",
            },
            ids = {
            },
            item = "Luminary's Lavish Loop",
            source = "Mayong",
          },
          Hands = {
            aliases = {
              "Blightbringer's Ascendant Handguards of the Grave",
            },
            ids = {
              32380,
            },
            item = "Blightbringer's Ascendant Handguards of the Grave",
            source = "First Four Names",
          },
          Head = {
            aliases = {
              "Blightbringer's Ascendant Cap of the Grave",
            },
            ids = {
              32379,
            },
            item = "Blightbringer's Ascendant Cap of the Grave",
            source = "First Four Names",
          },
          Legs = {
            aliases = {
              "Blightbringer's Ascendant Pants of the Grave",
            },
            ids = {
              32381,
            },
            item = "Blightbringer's Ascendant Pants of the Grave",
            source = "Brothers",
          },
          Neck = {
            aliases = {
              "Razor Edge of Rancor",
            },
            ids = {
            },
            item = "Razor Edge of Rancor",
            source = "Sebastian",
          },
          Ranged = {
            aliases = {
              "Torch of the Ruined Lands",
            },
            ids = {
            },
            item = "Torch of the Ruined Lands",
            source = "Fippy",
          },
          RangedAug = {
            aliases = {
              "Bat Wing",
            },
            ids = {
            },
            item = "Bat Wing",
            source = "Fippy",
          },
          Secondary = {
            aliases = {
              "Stave of Scorching Frost",
            },
            ids = {
            },
            item = "Stave of Scorching Frost",
            source = "Restless",
          },
          Shoulder = {
            aliases = {
              "Woven Mantle of Mastery",
            },
            ids = {
            },
            item = "Woven Mantle of Mastery",
            source = "Brothers",
          },
          Waist = {
            aliases = {
              "Spurred Sash of Suffering",
            },
            ids = {
            },
            item = "Spurred Sash of Suffering",
            source = "Fippy",
          },
          Wrist1 = {
            aliases = {
              "Blightbringer's Ascendant Bracer of the Grave",
            },
            ids = {
              32378,
            },
            item = "Blightbringer's Ascendant Bracer of the Grave",
          },
          Wrist2 = {
            aliases = {
              "Blightbringer's Eternal Bracer",
            },
            ids = {
              31643,
            },
            item = "Blightbringer's Eternal Bracer",
            source = "Fippy",
          },
        },
        Paladin = {
          Arms = {
            aliases = {
              "Dawnseeker's Ascendant Sleeves of the Defender",
            },
            ids = {
              32458,
            },
            item = "Dawnseeker's Ascendant Sleeves of the Defender",
            source = "Brothers",
          },
          Aug20 = {
            aliases = {
              "Physical Prowess",
              "Hideous Hex of Physical Prowess",
            },
            ids = {
              33008,
            },
            item = "Physical Prowess",
            notes = "No focus effect | +15 STR/STA/AGI/DEX, +5 WIS/INT/CHA, +150 hp, +200 mana/endur, +15 ac",
          },
          Back = {
            aliases = {
              "Glimmering Ebony Shroud",
            },
            ids = {
            },
            item = "Glimmering Ebony Shroud",
            source = "Sebastian",
          },
          Book1 = {
            aliases = {
              "Codex of Ancient Boon",
            },
            ids = {
              39670,
              39671,
              39672,
            },
            item = "Codex of Ancient Boon",
          },
          Book2 = {
            aliases = {
              "Codex of Unwavering Defense",
            },
            ids = {
              39670,
            },
            item = "Codex of Unwavering Defense",
          },
          Chest = {
            aliases = {
              "Dawnseeker's Ascendant Chestpiece of the Defender",
            },
            ids = {
              32455,
            },
            item = "Dawnseeker's Ascendant Chestpiece of the Defender",
            source = "Mayong",
          },
          Clicky = {
            aliases = {
              "Glint of the Grave",
            },
            ids = {
            },
            item = "Glint of the Grave",
            source = "Restless",
          },
          Ear1 = {
            aliases = {
              "Adornment of the Antagonist",
            },
            ids = {
            },
            item = "Adornment of the Antagonist",
            source = "Mayong",
          },
          Ear2 = {
            aliases = {
              "Barbed Enforcer's Bangle",
            },
            ids = {
            },
            item = "Barbed Enforcer's Bangle",
            source = "Brothers",
          },
          Face = {
            aliases = {
              "Facade of Doom",
            },
            ids = {
            },
            item = "Facade of Doom",
            source = "Cata",
          },
          Feet = {
            aliases = {
              "Dawnseeker's Ascendant Boots of the Defender",
            },
            ids = {
              32454,
            },
            item = "Dawnseeker's Ascendant Boots of the Defender",
            source = "First Four Names",
          },
          Finger1 = {
            aliases = {
              "Ring of Sinister Strategy",
            },
            ids = {
            },
            item = "Ring of Sinister Strategy",
            source = "Sebastian",
          },
          Finger2 = {
            aliases = {
              "Ringlet of Restless Spirits",
            },
            ids = {
            },
            item = "Ringlet of Restless Spirits",
            source = "Mayong",
          },
          Hands = {
            aliases = {
              "Dawnseeker's Ascendant Mitts of the Defender",
            },
            ids = {
              32457,
            },
            item = "Dawnseeker's Ascendant Mitts of the Defender",
            source = "First Four Names",
          },
          Head = {
            aliases = {
              "Dawnseeker's Ascendant Coif of the Defender",
            },
            ids = {
              32460,
            },
            item = "Dawnseeker's Ascendant Coif of the Defender",
            source = "First Four Names",
          },
          Legs = {
            aliases = {
              "Dawnseeker's Ascendant Leggings of the Defender",
            },
            ids = {
              32456,
            },
            item = "Dawnseeker's Ascendant Leggings of the Defender",
            source = "Brothers",
          },
          MainHand = {
            aliases = {
              "Shadowfiend's Spire",
            },
            ids = {
            },
            item = "Shadowfiend's Spire",
            source = "Restless",
          },
          Neck = {
            aliases = {
              "Gorget of Unrelenting Grit",
            },
            ids = {
            },
            item = "Gorget of Unrelenting Grit",
            source = "Drinker",
          },
          Ranged = {
            aliases = {
              "Brazier of the Ruined Lands",
            },
            ids = {
            },
            item = "Brazier of the Ruined Lands",
            source = "Fippy",
          },
          RangedAug = {
            aliases = {
              "Fish Scales",
            },
            ids = {
            },
            item = "Fish Scales",
            source = "Fippy",
          },
          Secondary = {
            aliases = {
              "Clandestine Bulwark of the Sanguine",
            },
            ids = {
            },
            item = "Clandestine Bulwark of the Sanguine",
            source = "Restless",
          },
          Shoulder = {
            aliases = {
              "Mantle of the Eradicator",
            },
            ids = {
            },
            item = "Mantle of the Eradicator",
            source = "Fippy",
          },
          Waist = {
            aliases = {
              "Tenacious Guardian's Girdle",
            },
            ids = {
            },
            item = "Tenacious Guardian's Girdle",
            source = "Drinker",
          },
          Wrist1 = {
            aliases = {
              "Dawnseeker's Ascendant Wristguard of the Defender",
            },
            ids = {
              32459,
            },
            item = "Dawnseeker's Ascendant Wristguard of the Defender",
            source = "First Four Names",
          },
          Wrist2 = {
            aliases = {
              "Dawnseeker's Eternal Bracer",
            },
            ids = {
              31644,
            },
            item = "Dawnseeker's Eternal Bracer",
            source = "Fippy",
          },
        },
        Ranger = {
          Arms = {
            aliases = {
              "Deadeye's Ascendant Sleeves of Journeys",
            },
            ids = {
              32479,
            },
            item = "Deadeye's Ascendant Sleeves of Journeys",
            source = "Brothers",
          },
          Aug20 = {
            aliases = {
              "Physical Prowess",
              "Hideous Hex of Physical Prowess",
            },
            ids = {
              33008,
            },
            item = "Physical Prowess",
            notes = "No focus effect | +15 STR/STA/AGI/DEX, +5 WIS/INT/CHA, +150 hp, +200 mana/endur, +15 ac",
          },
          Back = {
            aliases = {
              "Shroud of Calamitous Chic",
            },
            ids = {
            },
            item = "Shroud of Calamitous Chic",
            source = "Fippy",
          },
          Book1 = {
            aliases = {
              "Codex of Ancient Boon",
            },
            ids = {
              39670,
              39671,
              39672,
            },
            item = "Codex of Ancient Boon",
          },
          Book2 = {
            aliases = {
              "Codex of Potent Prowess",
            },
            ids = {
              39671,
            },
            item = "Codex of Potent Prowess",
          },
          Chest = {
            aliases = {
              "Deadeye's Ascendant Vest of Journeys",
            },
            ids = {
              32480,
            },
            item = "Deadeye's Ascendant Vest of Journeys",
            source = "Mayong",
          },
          Ear1 = {
            aliases = {
              "Adornment of the Antagonist",
            },
            ids = {
            },
            item = "Adornment of the Antagonist",
            source = "Mayong",
          },
          Ear2 = {
            aliases = {
              "Poached Molar Pendant",
            },
            ids = {
            },
            item = "Poached Molar Pendant",
            source = "Cata",
          },
          Face = {
            aliases = {
              "Bandana of Brazen Banditry",
            },
            ids = {
            },
            item = "Bandana of Brazen Banditry",
            source = "Brothers",
          },
          Feet = {
            aliases = {
              "Deadeye's Ascendant Boots of Journeys",
            },
            ids = {
              32475,
            },
            item = "Deadeye's Ascendant Boots of Journeys",
            source = "First Four Names",
          },
          Finger1 = {
            aliases = {
              "Band of the Dragon's Bane",
            },
            ids = {
            },
            item = "Band of the Dragon's Bane",
            source = "Brothers",
          },
          Finger2 = {
            aliases = {
              "Ringlet of Restless Spirits",
            },
            ids = {
            },
            item = "Ringlet of Restless Spirits",
            source = "Mayong",
          },
          Hands = {
            aliases = {
              "Deadeye's Ascendant Gloves of Journeys",
            },
            ids = {
              32477,
            },
            item = "Deadeye's Ascendant Gloves of Journeys",
            source = "First Four Names",
          },
          Head = {
            aliases = {
              "Deadeye's Ascendant Cap of Journeys",
            },
            ids = {
              32476,
            },
            item = "Deadeye's Ascendant Cap of Journeys",
            source = "First Four Names",
          },
          Legs = {
            aliases = {
              "Deadeye's Ascendant Legguards of Journeys",
            },
            ids = {
              32478,
            },
            item = "Deadeye's Ascendant Legguards of Journeys",
            source = "Brothers",
          },
          MainHand = {
            aliases = {
              "Brazier of the Ruined Lands",
            },
            ids = {
            },
            item = "Brazier of the Ruined Lands",
            source = "Fippy",
          },
          Neck = {
            aliases = {
              "Covert Inquisitor's Collar",
            },
            ids = {
            },
            item = "Covert Inquisitor's Collar",
            source = "Cata",
          },
          Ranged = {
            aliases = {
              "Brazier of the Ruined Lands",
            },
            ids = {
            },
            item = "Brazier of the Ruined Lands",
            source = "Fippy",
          },
          RangedAug = {
            aliases = {
              "Fish Scales",
            },
            ids = {
            },
            item = "Fish Scales",
            source = "Fippy",
          },
          Secondary = {
            aliases = {
              "Stave of Scorching Frost",
            },
            ids = {
              28367,
            },
            item = "Stave of Scorching Frost",
            source = "Restless",
          },
          Shoulder = {
            aliases = {
              "Ornate Pauldrons of Proficience",
            },
            ids = {
            },
            item = "Ornate Pauldrons of Proficience",
            source = "Drinker",
          },
          Waist = {
            aliases = {
              "Shabby Crimson Sash",
            },
            ids = {
            },
            item = "Shabby Crimson Sash",
            source = "Sebastian",
          },
          Wrist1 = {
            aliases = {
              "Deadeye's Ascendant Wristband of Journeys",
            },
            ids = {
              32481,
            },
            item = "Deadeye's Ascendant Wristband of Journeys",
            source = "First Four Names",
          },
          Wrist2 = {
            aliases = {
              "Deadeye's Eternal Bracer",
            },
            ids = {
              31646,
            },
            item = "Deadeye's Eternal Bracer",
            source = "Fippy",
          },
        },
        Rogue = {
          Arms = {
            aliases = {
              "Whisperer's Ascendant Armguard of Shadows",
            },
            ids = {
              31683,
            },
            item = "Whisperer's Ascendant Armguard of Shadows",
            source = "Brothers",
          },
          Aug20 = {
            aliases = {
              "Physical Prowess",
              "Hideous Hex of Physical Prowess",
            },
            ids = {
              33008,
            },
            item = "Physical Prowess",
            notes = "No focus effect | +15 STR/STA/AGI/DEX, +5 WIS/INT/CHA, +150 hp, +200 mana/endur, +15 ac",
          },
          Back = {
            aliases = {
              "Shroud of Calamitous Chic",
            },
            ids = {
            },
            item = "Shroud of Calamitous Chic",
            source = "Fippy",
          },
          Book1 = {
            aliases = {
              "Codex of Ancient Boon",
            },
            ids = {
              39670,
              39671,
              39672,
            },
            item = "Codex of Ancient Boon",
          },
          Book2 = {
            aliases = {
              "Codex of Potent Prowess",
            },
            ids = {
              39671,
            },
            item = "Codex of Potent Prowess",
          },
          Chest = {
            aliases = {
              "Whisperer's Ascendant Tunic of Shadows",
            },
            ids = {
              31682,
            },
            item = "Whisperer's Ascendant Tunic of Shadows",
            source = "Mayong",
          },
          Ear1 = {
            aliases = {
              "Adornment of the Antagonist",
            },
            ids = {
            },
            item = "Adornment of the Antagonist",
            source = "Mayong",
          },
          Ear2 = {
            aliases = {
              "Poached Molar Pendant",
            },
            ids = {
            },
            item = "Poached Molar Pendant",
            source = "Cata",
          },
          Face = {
            aliases = {
              "Bandana of Brazen Banditry",
            },
            ids = {
            },
            item = "Bandana of Brazen Banditry",
            source = "Brothers",
          },
          Feet = {
            aliases = {
              "Whisperer's Ascendant Boots of Shadows",
            },
            ids = {
              31687,
            },
            item = "Whisperer's Ascendant Boots of Shadows",
            source = "First Four Names",
          },
          Finger1 = {
            aliases = {
              "Band of the Dragon's Bane",
            },
            ids = {
            },
            item = "Band of the Dragon's Bane",
            source = "Brothers",
          },
          Finger2 = {
            aliases = {
              "Ringlet of Restless Spirits",
            },
            ids = {
            },
            item = "Ringlet of Restless Spirits",
            source = "Mayong",
          },
          Hands = {
            aliases = {
              "Whisperer's Ascendant Gloves of Shadows",
            },
            ids = {
              31685,
            },
            item = "Whisperer's Ascendant Gloves of Shadows",
            source = "First Four Names",
          },
          Head = {
            aliases = {
              "Whisperer's Ascendant Hat of Shadows",
            },
            ids = {
              31681,
            },
            item = "Whisperer's Ascendant Hat of Shadows",
            source = "First Four Names",
          },
          Legs = {
            aliases = {
              "Whisperer's Ascendant Pants of Shadows",
            },
            ids = {
              31686,
            },
            item = "Whisperer's Ascendant Pants of Shadows",
            source = "Brothers",
          },
          MainHand = {
            aliases = {
              "Grim Silhouette",
            },
            ids = {
            },
            item = "Grim Silhouette",
            source = "Restless",
          },
          Neck = {
            aliases = {
              "Covert Inquisitor's Collar",
            },
            ids = {
            },
            item = "Covert Inquisitor's Collar",
            source = "Cata",
          },
          Ranged = {
            aliases = {
              "Lightstone of the Ruined Lands",
            },
            ids = {
            },
            item = "Lightstone of the Ruined Lands",
            source = "Fippy",
          },
          RangedAug = {
            aliases = {
              "Rat Ears",
            },
            ids = {
            },
            item = "Rat Ears",
            source = "Fippy",
          },
          Shoulder = {
            aliases = {
              "Ornate Pauldrons of Proficience",
            },
            ids = {
            },
            item = "Ornate Pauldrons of Proficience",
            source = "Drinker",
          },
          Waist = {
            aliases = {
              "Shabby Crimson Sash",
            },
            ids = {
            },
            item = "Shabby Crimson Sash",
            source = "Sebastian",
          },
          Wrist1 = {
            aliases = {
              "Whisperer's Ascendant Bracer of Shadows",
            },
            ids = {
              31684,
            },
            item = "Whisperer's Ascendant Bracer of Shadows",
            source = "First Four Names",
          },
          Wrist2 = {
            aliases = {
              "Whisperer's Eternal Bracer",
            },
            ids = {
              30582,
            },
            item = "Whisperer's Eternal Bracer",
            source = "Fippy",
          },
        },
        ["Shadow Knight"] = {
          Arms = {
            aliases = {
              "Duskbringer's Ascendant Armguards of the Hateful",
            },
            ids = {
              32461,
            },
            item = "Duskbringer's Ascendant Armguards of the Hateful",
            source = "Brothers",
          },
          Aug20 = {
            aliases = {
              "Physical Prowess",
              "Hideous Hex of Physical Prowess",
            },
            ids = {
              33008,
            },
            item = "Physical Prowess",
            notes = "No focus effect | +15 STR/STA/AGI/DEX, +5 WIS/INT/CHA, +150 hp, +200 mana/endur, +15 ac",
          },
          Back = {
            aliases = {
              "Glimmering Ebony Shroud",
            },
            ids = {
            },
            item = "Glimmering Ebony Shroud",
            source = "Sebastian",
          },
          Book1 = {
            aliases = {
              "Codex of Ancient Boon",
            },
            ids = {
              39670,
              39671,
              39672,
            },
            item = "Codex of Ancient Boon",
          },
          Book2 = {
            aliases = {
              "Codex of Minion's Materiel",
            },
            ids = {
            },
            item = "Codex of Minion's Materiel",
          },
          Book3 = {
            aliases = {
              "Codex of Unwavering Defense",
            },
            ids = {
              39670,
            },
            item = "Codex of Unwavering Defense",
          },
          Chest = {
            aliases = {
              "Duskbringer's Ascendant Chestguard of the Hateful",
            },
            ids = {
              32463,
            },
            item = "Duskbringer's Ascendant Chestguard of the Hateful",
            source = "Mayong",
          },
          Clicky = {
            aliases = {
              "Glint of the Grave",
            },
            ids = {
            },
            item = "Glint of the Grave",
            source = "Restless",
          },
          Ear1 = {
            aliases = {
              "Adornment of the Antagonist",
            },
            ids = {
            },
            item = "Adornment of the Antagonist",
            source = "Mayong",
          },
          Ear2 = {
            aliases = {
              "Barbed Enforcer's Bangle",
            },
            ids = {
            },
            item = "Barbed Enforcer's Bangle",
            source = "Brothers",
          },
          Face = {
            aliases = {
              "Facade of Doom",
            },
            ids = {
            },
            item = "Facade of Doom",
            source = "Cata",
          },
          Feet = {
            aliases = {
              "Duskbringer's Ascendant Boots of the Hateful",
            },
            ids = {
              32462,
            },
            item = "Duskbringer's Ascendant Boots of the Hateful",
            source = "First Four Names",
          },
          Finger1 = {
            aliases = {
              "Ring of Sinister Strategy",
            },
            ids = {
            },
            item = "Ring of Sinister Strategy",
            source = "Sebastian",
          },
          Finger2 = {
            aliases = {
              "Ringlet of Restless Spirits",
            },
            ids = {
            },
            item = "Ringlet of Restless Spirits",
            source = "Mayong",
          },
          Hands = {
            aliases = {
              "Duskbringer's Ascendant Gloves of the Hateful",
            },
            ids = {
              32464,
            },
            item = "Duskbringer's Ascendant Gloves of the Hateful",
            source = "First Four Names",
          },
          Head = {
            aliases = {
              "Duskbringer's Ascendant Helm of the Hateful",
            },
            ids = {
              32465,
            },
            item = "Duskbringer's Ascendant Helm of the Hateful",
            source = "First Four Names",
          },
          Legs = {
            aliases = {
              "Duskbringer's Ascendant Legguards of the Hateful",
            },
            ids = {
              32466,
            },
            item = "Duskbringer's Ascendant Legguards of the Hateful",
            source = "Brothers",
          },
          MainHand = {
            aliases = {
              "Shadowfiend's Spire",
            },
            ids = {
            },
            item = "Shadowfiend's Spire",
            source = "Restless",
          },
          Neck = {
            aliases = {
              "Gorget of Unrelenting Grit",
            },
            ids = {
            },
            item = "Gorget of Unrelenting Grit",
            source = "Drinker",
          },
          Ranged = {
            aliases = {
              "Brazier of the Ruined Lands",
            },
            ids = {
            },
            item = "Brazier of the Ruined Lands",
            source = "Fippy",
          },
          RangedAug = {
            aliases = {
              "Fish Scales",
            },
            ids = {
            },
            item = "Fish Scales",
            source = "Fippy",
          },
          Secondary = {
            aliases = {
              "Clandestine Bulwark of the Sanguine",
            },
            ids = {
            },
            item = "Clandestine Bulwark of the Sanguine",
            source = "Restless",
          },
          Shoulder = {
            aliases = {
              "Mantle of the Eradicator",
            },
            ids = {
            },
            item = "Mantle of the Eradicator",
            source = "Fippy",
          },
          Waist = {
            aliases = {
              "Tenacious Guardian's Girdle",
            },
            ids = {
            },
            item = "Tenacious Guardian's Girdle",
            source = "Drinker",
          },
          Wrist1 = {
            aliases = {
              "Duskbringer's Ascendant Wristguard of the Hateful",
            },
            ids = {
              32467,
            },
            item = "Duskbringer's Ascendant Wristguard of the Hateful",
            source = "First Four Names",
          },
          Wrist2 = {
            aliases = {
              "Duskbringer's Eternal Bracer",
            },
            ids = {
              31645,
            },
            item = "Duskbringer's Eternal Bracer",
            source = "Fippy",
          },
        },
        Shaman = {
          Arms = {
            aliases = {
              "Ritualchanter's Ascendant Armguards of the Ancestors",
            },
            ids = {
              32256,
            },
            item = "Ritualchanter's Ascendant Armguards of the Ancestors",
            source = "Brothers",
          },
          Aug20 = {
            aliases = {
              "Mental Prowess",
              "Hideous Hex of Mental Prowess",
            },
            ids = {
              33011,
            },
            item = "Mental Prowess",
            notes = "No focus effect | +15 WIS/INT/CHA, +5 STR/STA/AGI/DEX, +130 hp, +360 mana, +13 ac, +10 resists",
          },
          Back = {
            aliases = {
              "Gilded Cloak of Grandeur",
            },
            ids = {
            },
            item = "Gilded Cloak of Grandeur",
            source = "Drinker",
          },
          Book1 = {
            aliases = {
              "Codex of Ancient Boon",
            },
            ids = {
              39670,
              39671,
              39672,
            },
            item = "Codex of Ancient Boon",
          },
          Book2 = {
            aliases = {
              "Codex of Scribe's Endurance",
            },
            ids = {
              39672,
            },
            item = "Codex of Scribe's Endurance",
          },
          Book3 = {
            aliases = {
              "Codex of Minion's Materiel",
            },
            ids = {
            },
            item = "Codex of Minion's Materiel",
          },
          Chest = {
            aliases = {
              "Ritualchanter's Ascendant Tunic of the Ancestors",
            },
            ids = {
              32261,
            },
            item = "Ritualchanter's Ascendant Tunic of the Ancestors",
            source = "Mayong",
          },
          Ear1 = {
            aliases = {
              "Earhoop of Eternal Night",
            },
            ids = {
            },
            item = "Earhoop of Eternal Night",
            source = "Mayong",
          },
          Ear2 = {
            aliases = {
              "Aristocrat's Opulent Adornment",
            },
            ids = {
            },
            item = "Aristocrat's Opulent Adornment",
            source = "Sebastian",
          },
          Face = {
            aliases = {
              "Eerie Veil of the Enigma",
            },
            ids = {
            },
            item = "Eerie Veil of the Enigma",
            source = "Sebastian",
          },
          Feet = {
            aliases = {
              "Ritualchanter's Ascendant Boots of the Ancestors",
            },
            ids = {
              32257,
            },
            item = "Ritualchanter's Ascendant Boots of the Ancestors",
            source = "First Four Names",
          },
          Finger1 = {
            aliases = {
              "Circlet of Convalescence",
            },
            ids = {
            },
            item = "Circlet of Convalescence",
            source = "Drinker",
          },
          Finger2 = {
            aliases = {
              "Luminary's Lavish Loop",
            },
            ids = {
            },
            item = "Luminary's Lavish Loop",
            source = "Mayong",
          },
          Hands = {
            aliases = {
              "Ritualchanter's Ascendant Mitts of the Ancestors",
            },
            ids = {
              32260,
            },
            item = "Ritualchanter's Ascendant Mitts of the Ancestors",
            source = "First Four Names",
          },
          Head = {
            aliases = {
              "Ritualchanter's Ascendant Cap of the Ancestors",
            },
            ids = {
              32258,
            },
            item = "Ritualchanter's Ascendant Cap of the Ancestors",
            source = "First Four Names",
          },
          Legs = {
            aliases = {
              "Ritualchanter's Ascendant Leggings of the Ancestors",
            },
            ids = {
              32259,
            },
            item = "Ritualchanter's Ascendant Leggings of the Ancestors",
            source = "Brothers",
          },
          Neck = {
            aliases = {
              "Advocate's Amethyst Lavalliere",
            },
            ids = {
            },
            item = "Advocate's Amethyst Lavalliere",
            source = "Brothers",
          },
          Ranged = {
            aliases = {
              "Lantern of the Ruined Lands",
            },
            ids = {
            },
            item = "Lantern of the Ruined Lands",
            source = "Fippy",
          },
          RangedAug = {
            aliases = {
              "Bone Chips",
            },
            ids = {
            },
            item = "Bone Chips",
            source = "Fippy",
          },
          Secondary = {
            aliases = {
              "Furtive Aegis of the Sanguine",
            },
            ids = {
              24142,
            },
            item = "Furtive Aegis of the Sanguine",
            source = "Restless",
          },
          Shoulder = {
            aliases = {
              "Epaulettes of Sacramental Faith",
            },
            ids = {
            },
            item = "Epaulettes of Sacramental Faith",
            source = "Cata",
          },
          Waist = {
            aliases = {
              "Consecrated Cummerbund of Compassion",
            },
            ids = {
            },
            item = "Consecrated Cummerbund of Compassion",
            source = "Fippy",
          },
          Wrist1 = {
            aliases = {
              "Ritualchanter's Ascendant Wristband of the Ancestors",
            },
            ids = {
              32262,
            },
            item = "Ritualchanter's Ascendant Wristband of the Ancestors",
            source = "First Four Names",
          },
          Wrist2 = {
            aliases = {
              "Ritualchanter's Eternal Bracer",
            },
            ids = {
              31638,
            },
            item = "Ritualchanter's Eternal Bracer",
            source = "Fippy",
          },
        },
        Warrior = {
          Arms = {
            aliases = {
              "Gladiator's Ascendant Sleeves of War",
            },
            ids = {
              31673,
            },
            item = "Gladiator's Ascendant Sleeves of War",
            source = "Brothers",
          },
          Aug20 = {
            aliases = {
              "Physical Prowess",
              "Hideous Hex of Physical Prowess",
            },
            ids = {
              33008,
            },
            item = "Physical Prowess",
            notes = "No focus effect | +15 STR/STA/AGI/DEX, +5 WIS/INT/CHA, +150 hp, +200 mana/endur, +15 ac",
          },
          Back = {
            aliases = {
              "Glimmering Ebony Shroud",
            },
            ids = {
            },
            item = "Glimmering Ebony Shroud",
            source = "Sebastian",
          },
          Book1 = {
            aliases = {
              "Codex of Ancient Boon",
            },
            ids = {
              39670,
              39671,
              39672,
            },
            item = "Codex of Ancient Boon",
          },
          Book2 = {
            aliases = {
              "Codex of Unwavering Defense",
            },
            ids = {
              39670,
            },
            item = "Codex of Unwavering Defense",
          },
          Chest = {
            aliases = {
              "Gladiator's Ascendant Chestguard of War",
            },
            ids = {
              31669,
            },
            item = "Gladiator's Ascendant Chestguard of War",
            source = "Mayong",
          },
          Clicky = {
            aliases = {
              "Glint of the Grave",
            },
            ids = {
            },
            item = "Glint of the Grave",
            source = "Restless",
          },
          Ear1 = {
            aliases = {
              "Adornment of the Antagonist",
            },
            ids = {
            },
            item = "Adornment of the Antagonist",
            source = "Mayong",
          },
          Ear2 = {
            aliases = {
              "Barbed Enforcer's Bangle",
            },
            ids = {
            },
            item = "Barbed Enforcer's Bangle",
            source = "Brothers",
          },
          Face = {
            aliases = {
              "Facade of Doom",
            },
            ids = {
            },
            item = "Facade of Doom",
            source = "Cata",
          },
          Feet = {
            aliases = {
              "Gladiator's Ascendant Boots of War",
            },
            ids = {
              31655,
            },
            item = "Gladiator's Ascendant Boots of War",
            source = "First Four Names",
          },
          Finger1 = {
            aliases = {
              "Ring of Sinister Strategy",
            },
            ids = {
            },
            item = "Ring of Sinister Strategy",
            source = "Sebastian",
          },
          Finger2 = {
            aliases = {
              "Ringlet of Restless Spirits",
            },
            ids = {
            },
            item = "Ringlet of Restless Spirits",
            source = "Mayong",
          },
          Hands = {
            aliases = {
              "Gladiator's Ascendant Gloves of War",
            },
            ids = {
              31670,
            },
            item = "Gladiator's Ascendant Gloves of War",
            source = "First Four Names",
          },
          Head = {
            aliases = {
              "Gladiator's Ascendant Helm of War",
            },
            ids = {
              31671,
            },
            item = "Gladiator's Ascendant Helm of War",
            source = "First Four Names",
          },
          Legs = {
            aliases = {
              "Gladiator's Ascendant Legguards of War",
            },
            ids = {
              31672,
            },
            item = "Gladiator's Ascendant Legguards of War",
            source = "Brothers",
          },
          Neck = {
            aliases = {
              "Gorget of Unrelenting Grit",
            },
            ids = {
            },
            item = "Gorget of Unrelenting Grit",
            source = "Drinker",
          },
          Ranged = {
            aliases = {
              "Lightstone of the Ruined Lands",
            },
            ids = {
            },
            item = "Lightstone of the Ruined Lands",
            source = "Fippy",
          },
          RangedAug = {
            aliases = {
              "Rat Ears",
            },
            ids = {
            },
            item = "Rat Ears",
            source = "Fippy",
          },
          Secondary = {
            aliases = {
              "Clandestine Bulwark of the Sanguine",
            },
            ids = {
            },
            item = "Clandestine Bulwark of the Sanguine",
            source = "Restless",
          },
          Shoulder = {
            aliases = {
              "Mantle of the Eradicator",
            },
            ids = {
            },
            item = "Mantle of the Eradicator",
            source = "Fippy",
          },
          Waist = {
            aliases = {
              "Tenacious Guardian's Girdle",
            },
            ids = {
            },
            item = "Tenacious Guardian's Girdle",
            source = "Drinker",
          },
          Wrist1 = {
            aliases = {
              "Gladiator's Ascendant Bracer of War",
            },
            ids = {
              31668,
            },
            item = "Gladiator's Ascendant Bracer of War",
            source = "First Four Names",
          },
          Wrist2 = {
            aliases = {
              "Gladiator's Eternal Bracer",
            },
            ids = {
              29704,
            },
            item = "Gladiator's Eternal Bracer",
            source = "Fippy",
          },
        },
        Wizard = {
          Arms = {
            aliases = {
              "Academic's Ascendant Sleeves of the Arcanists",
            },
            ids = {
              32348,
            },
            item = "Academic's Ascendant Sleeves of the Arcanists",
            source = "Brothers",
          },
          Aug20 = {
            aliases = {
              "Mental Prowess",
              "Hideous Hex of Mental Prowess",
            },
            ids = {
              33011,
            },
            item = "Mental Prowess",
            notes = "No focus effect | +15 WIS/INT/CHA, +5 STR/STA/AGI/DEX, +130 hp, +360 mana, +13 ac, +10 resists",
          },
          Back = {
            aliases = {
              "Silken Shawl of Sanguine Salacity",
            },
            ids = {
            },
            item = "Silken Shawl of Sanguine Salacity",
            source = "Cata",
          },
          Book1 = {
            aliases = {
              "Codex of Ancient Boon",
            },
            ids = {
              39670,
              39671,
              39672,
            },
            item = "Codex of Ancient Boon",
          },
          Book2 = {
            aliases = {
              "Codex of Scribe's Endurance",
            },
            ids = {
              39672,
            },
            item = "Codex of Scribe's Endurance",
          },
          Chest = {
            aliases = {
              "Academic's Ascendant Robe of the Arcanists",
            },
            ids = {
              32347,
            },
            item = "Academic's Ascendant Robe of the Arcanists",
            source = "Mayong",
          },
          Ear1 = {
            aliases = {
              "Earhoop of Eternal Night",
            },
            ids = {
            },
            item = "Earhoop of Eternal Night",
            source = "Mayong",
          },
          Ear2 = {
            aliases = {
              "Astral Emblem of Augury",
            },
            ids = {
            },
            item = "Astral Emblem of Augury",
            source = "Brothers",
          },
          Face = {
            aliases = {
              "Insidious Imposter's Masquerade",
            },
            ids = {
            },
            item = "Insidious Imposter's Masquerade",
            source = "Drinker",
          },
          Feet = {
            aliases = {
              "Academic's Ascendant Slippers of the Arcanists",
            },
            ids = {
              32349,
            },
            item = "Academic's Ascendant Slippers of the Arcanists",
            source = "First Four Names",
          },
          Finger1 = {
            aliases = {
              "Coterie's Covetous Circlet",
            },
            ids = {
            },
            item = "Coterie's Covetous Circlet",
            source = "Cata",
          },
          Finger2 = {
            aliases = {
              "Luminary's Lavish Loop",
            },
            ids = {
            },
            item = "Luminary's Lavish Loop",
            source = "Mayong",
          },
          Hands = {
            aliases = {
              "Academic's Ascendant Gloves of the Arcanists",
            },
            ids = {
              32345,
            },
            item = "Academic's Ascendant Gloves of the Arcanists",
            source = "First Four Names",
          },
          Head = {
            aliases = {
              "Academic's Ascendant Cap of the Arcanists",
            },
            ids = {
              32344,
            },
            item = "Academic's Ascendant Cap of the Arcanists",
            source = "First Four Names",
          },
          Legs = {
            aliases = {
              "Academic's Ascendant Pants of the Arcanists",
            },
            ids = {
              32346,
            },
            item = "Academic's Ascendant Pants of the Arcanists",
            source = "Brothers",
          },
          Neck = {
            aliases = {
              "Razor Edge of Rancor",
            },
            ids = {
            },
            item = "Razor Edge of Rancor",
            source = "Sebastian",
          },
          Ranged = {
            aliases = {
              "Torch of the Ruined Lands",
            },
            ids = {
            },
            item = "Torch of the Ruined Lands",
            source = "Fippy",
          },
          RangedAug = {
            aliases = {
              "Bat Wing",
            },
            ids = {
            },
            item = "Bat Wing",
            source = "Fippy",
          },
          Secondary = {
            aliases = {
              "Stave of Scorching Frost",
            },
            ids = {
            },
            item = "Stave of Scorching Frost",
            source = "Restless",
          },
          Shoulder = {
            aliases = {
              "Woven Mantle of Mastery",
            },
            ids = {
            },
            item = "Woven Mantle of Mastery",
            source = "Brothers",
          },
          Waist = {
            aliases = {
              "Spurred Sash of Suffering",
            },
            ids = {
            },
            item = "Spurred Sash of Suffering",
            source = "Fippy",
          },
          Wrist1 = {
            aliases = {
              "Academic's Ascendant Wristband of the Arcanists",
            },
            ids = {
              32350,
            },
            item = "Academic's Ascendant Wristband of the Arcanists",
            source = "First Four Names",
          },
          Wrist2 = {
            aliases = {
              "Academic's Eternal Bracer",
            },
            ids = {
              31640,
            },
            item = "Academic's Eternal Bracer",
            source = "Fippy",
          },
        },
      },
      group = "Raid Best In Slot",
      id = "dsk",
      name = "DSK",
      show_base = {
      },
      template = {
        Aug1 = {
          aliases = {
            "Benevolent Efficiency",
            "Hideous Hex of Benevolent Efficiency",
          },
          ids = {
            27620,
          },
          item = "Benevolent Efficiency",
          notes = "-5% beneficial spell mana cost | +50 hp/mana/endur",
        },
        Aug10 = {
          aliases = {
            "Noxious Demise",
            "Hideous Hex of Noxious Demise",
          },
          ids = {
            27625,
          },
          item = "Noxious Demise",
          notes = "+5% poison spell damage | +50 hp/mana/endur",
        },
        Aug11 = {
          aliases = {
            "Festering Demise",
            "Hideous Hex of Festering Demise",
          },
          ids = {
            28109,
          },
          item = "Festering Demise",
          notes = "+5% disease spell damage | +50 hp/mana/endur",
        },
        Aug12 = {
          aliases = {
            "Merciful Mending",
            "Hideous Hex of Merciful Mending",
          },
          ids = {
            28110,
          },
          item = "Merciful Mending",
          notes = "+5% healing | +50 hp/mana/endur",
        },
        Aug13 = {
          aliases = {
            "Expanded Reach",
            "Hideous Hex of Expanded Reach",
          },
          ids = {
            28115,
          },
          item = "Expanded Reach",
          notes = "+40% spell range | +50 hp/mana/endur",
        },
        Aug14 = {
          aliases = {
            "Nimble Elusion",
            "Hideous Hex of Nimble Elusion",
          },
          ids = {
            28119,
          },
          item = "Nimble Elusion",
          notes = "+60% dodge | +50 hp/mana/endur",
        },
        Aug15 = {
          aliases = {
            "Adept Guard",
            "Hideous Hex of Adept Guard",
          },
          ids = {
            28118,
          },
          item = "Adept Guard",
          notes = "+60% parry, +60% block | +50 hp/mana/endur",
        },
        Aug16 = {
          aliases = {
            "Visceral Malice",
            "Hideous Hex of Visceral Malice",
          },
          ids = {
            28117,
          },
          item = "Visceral Malice",
          notes = "+250% melee critical damage | +50 hp/mana/endur",
        },
        Aug17 = {
          aliases = {
            "Wanton Assault",
            "Hideous Hex of Wanton Assault",
          },
          ids = {
            28116,
          },
          item = "Wanton Assault",
          notes = "+18% double attack, +6% triple attack, +3% chance to hit | +50 hp/mana/endur",
        },
        Aug18 = {
          aliases = {
            "Lethal Barrage",
            "Hideous Hex of Lethal Barrage",
          },
          ids = {
            28120,
          },
          item = "Lethal Barrage",
          notes = "+20% archery and throwing chance to hit | +50 hp/mana/endur",
        },
        Aug19 = {
          aliases = {
            "Companion's Mercy",
            "Hideous Hex of Companion's Mercy",
          },
          ids = {
            28111,
          },
          item = "Companion's Mercy",
          notes = "+30% companion healing | +50 hp/mana/endur",
        },
        Aug2 = {
          aliases = {
            "Benevolent Extension",
            "Hideous Hex of Benevolent Extension",
          },
          ids = {
            28113,
          },
          item = "Benevolent Extension",
          notes = "+35% beneficial spell duration | +50 hp/mana/endur",
        },
        Aug3 = {
          aliases = {
            "Benevolent Alacrity",
            "Hideous Hex of Benevolent Alacrity",
          },
          ids = {
            27622,
          },
          item = "Benevolent Alacrity",
          notes = "-35% beneficial spell cast time | +50 hp/mana/endur",
        },
        Aug4 = {
          aliases = {
            "Malevolent Efficiency",
            "Hideous Hex of Malevolent Efficiency",
          },
          ids = {
            27618,
          },
          item = "Malevolent Efficiency",
          notes = "-5% detrimental spell mana cost | +50 hp/mana/endur",
        },
        Aug5 = {
          aliases = {
            "Malevolent Extension",
            "Hideous Hex of Malevolent Extension",
          },
          ids = {
            28112,
          },
          item = "Malevolent Extension",
          notes = "+35% detrimental spell duration | +50 hp/mana/endur",
        },
        Aug6 = {
          aliases = {
            "Malevolent Alacrity",
            "Hideous Hex of Malevolent Alacrity",
          },
          ids = {
            27621,
          },
          item = "Malevolent Alacrity",
          notes = "-35% detrimental spell cast time | +50 hp/mana/endur",
        },
        Aug7 = {
          aliases = {
            "Arcane Demise",
            "Hideous Hex of Arcane Demise",
          },
          ids = {
            28114,
          },
          item = "Arcane Demise",
          notes = "+5% magic spell damage | +50 hp/mana/endur",
        },
        Aug8 = {
          aliases = {
            "Fiery Demise",
            "Hideous Hex of Fiery Demise",
          },
          ids = {
            27623,
          },
          item = "Fiery Demise",
          notes = "+5% fire spell damage | +50 hp/mana/endur",
        },
        Aug9 = {
          aliases = {
            "Chilling Demise",
            "Hideous Hex of Chilling Demise",
          },
          ids = {
            27624,
          },
          item = "Chilling Demise",
          notes = "+5% cold spell damage | +50 hp/mana/endur",
        },
        Charm = {
          aliases = {
            "Geode of Unyielding Avarice",
          },
          ids = {
          },
          item = "Geode of Unyielding Avarice",
          source = "Fippy",
        },
        ["Middle Finger (Mayong)"] = {
          aliases = {
            "Jonas Dagmire's Skeletal Middle Finger",
          },
          ids = {
            33171,
            33176,
            82836,
          },
          item = "Jonas Dagmire's Skeletal Middle Finger",
        },
        Wand = {
          aliases = {
            "Wand of Ruptured Reality",
          },
          ids = {
          },
          item = "Wand of Ruptured Reality",
          source = "Fippy",
        },
      },
      visible = {
        Arms = {
          aliases = {
            "Vessel of the Ascendant Sleeves",
          },
          ids = {
          },
          item = "Vessel of the Ascendant Sleeves",
        },
        Chest = {
          aliases = {
            "Vessel of the Ascendant Breastplate",
          },
          ids = {
          },
          item = "Vessel of the Ascendant Breastplate",
        },
        Feet = {
          aliases = {
            "Vessel of the Ascendant Boots",
          },
          ids = {
          },
          item = "Vessel of the Ascendant Boots",
        },
        Hands = {
          aliases = {
            "Vessel of the Ascendant Gauntlets",
          },
          ids = {
          },
          item = "Vessel of the Ascendant Gauntlets",
        },
        Head = {
          aliases = {
            "Vessel of the Ascendant Helm",
          },
          ids = {
          },
          item = "Vessel of the Ascendant Helm",
        },
        Legs = {
          aliases = {
            "Vessel of the Ascendant Leggings",
          },
          ids = {
          },
          item = "Vessel of the Ascendant Leggings",
        },
        Wrist1 = {
          aliases = {
            "Vessel of the Ascendant Bracer",
          },
          ids = {
          },
          item = "Vessel of the Ascendant Bracer",
        },
        Wrist2 = {
          aliases = {
            "Binding of Reality",
          },
          ids = {
          },
          item = "Binding of Reality",
        },
      },
    },
    focusitems = {
      categories = {
        {
          name = "Focus Items",
          slots = {
            "Increased Healing",
            "Pet Healing",
            "Extended Reach",
            "Beneficial Extension",
            "Beneficial Reduction of Mana",
            "Beneficial Cast Time Reduction",
            "Detrimental Extension",
            "Detrimental Reduction of Mana",
            "Detrimental Cast Time Reduction",
            "Detrimental Damage",
            "Detrimental Duration Damage",
            "Magic Damage",
            "Fire Damage",
            "Ice Damage",
            "Poison Damage",
            "Disease Damage",
            "Improved Dodge",
            "Block and Parry",
            "Cleave",
            "Double Attack",
          },
        },
      },
      classes = {
        Bard = {
          ["Beneficial Cast Time Reduction"] = {
            aliases = {
              "Beneficial Cast Time Reduction",
            },
            ids = {
              27622,
            },
            item = "Beneficial Cast Time Reduction",
          },
          ["Beneficial Extension"] = {
            aliases = {
              "Beneficial Extension",
            },
            ids = {
              28113,
            },
            item = "Beneficial Extension",
          },
          ["Beneficial Reduction of Mana"] = {
            aliases = {
              "Beneficial Reduction of Mana",
            },
            ids = {
              27620,
            },
            item = "Beneficial Reduction of Mana",
          },
          ["Block and Parry"] = {
            aliases = {
              "Block and Parry",
            },
            ids = {
              28118,
            },
            item = "Block and Parry",
          },
          Cleave = {
            aliases = {
              "Cleave",
            },
            ids = {
              28117,
            },
            item = "Cleave",
          },
          ["Detrimental Cast Time Reduction"] = {
            aliases = {
              "Detrimental Cast Time Reduction",
            },
            ids = {
              27621,
            },
            item = "Detrimental Cast Time Reduction",
          },
          ["Detrimental Damage"] = {
            aliases = {
              "Detrimental Damage",
            },
            ids = {
              150047,
            },
            item = "Detrimental Damage",
          },
          ["Detrimental Duration Damage"] = {
            aliases = {
              "Detrimental Duration Damage",
            },
            ids = {
            },
            item = "Detrimental Duration Damage",
          },
          ["Detrimental Extension"] = {
            aliases = {
              "Detrimental Extension",
            },
            ids = {
              28112,
            },
            item = "Detrimental Extension",
          },
          ["Detrimental Reduction of Mana"] = {
            aliases = {
              "Detrimental Reduction of Mana",
            },
            ids = {
              27618,
            },
            item = "Detrimental Reduction of Mana",
          },
          ["Disease Damage"] = {
            aliases = {
              "Disease Damage",
            },
            ids = {
              28109,
            },
            item = "Disease Damage",
          },
          ["Double Attack"] = {
            aliases = {
              "Double Attack",
            },
            ids = {
              28116,
            },
            item = "Double Attack",
          },
          ["Extended Reach"] = {
            aliases = {
              "Extended Reach",
            },
            ids = {
              28115,
            },
            item = "Extended Reach",
          },
          ["Fire Damage"] = {
            aliases = {
              "Fire Damage",
            },
            ids = {
              27623,
            },
            item = "Fire Damage",
          },
          ["Ice Damage"] = {
            aliases = {
              "Ice Damage",
            },
            ids = {
              27624,
            },
            item = "Ice Damage",
          },
          ["Improved Dodge"] = {
            aliases = {
              "Improved Dodge",
            },
            ids = {
              28119,
            },
            item = "Improved Dodge",
          },
          ["Increased Healing"] = {
            aliases = {
              "Increased Healing",
            },
            ids = {
              28110,
            },
            item = "Increased Healing",
          },
          ["Magic Damage"] = {
            aliases = {
              "Magic Damage",
            },
            ids = {
              28114,
            },
            item = "Magic Damage",
          },
          ["Poison Damage"] = {
            aliases = {
              "Poison Damage",
            },
            ids = {
              27625,
            },
            item = "Poison Damage",
          },
        },
        Beastlord = {
          ["Beneficial Cast Time Reduction"] = {
            aliases = {
              "Beneficial Cast Time Reduction",
            },
            ids = {
              27622,
              150044,
            },
            item = "Beneficial Cast Time Reduction",
          },
          ["Beneficial Extension"] = {
            aliases = {
              "Beneficial Extension",
            },
            ids = {
              28113,
              150045,
            },
            item = "Beneficial Extension",
          },
          ["Beneficial Reduction of Mana"] = {
            aliases = {
              "Beneficial Reduction of Mana",
            },
            ids = {
              27620,
              150043,
            },
            item = "Beneficial Reduction of Mana",
          },
          ["Block and Parry"] = {
            aliases = {
              "Block and Parry",
            },
            ids = {
              28118,
            },
            item = "Block and Parry",
          },
          Cleave = {
            aliases = {
              "Cleave",
            },
            ids = {
              28117,
            },
            item = "Cleave",
          },
          ["Detrimental Cast Time Reduction"] = {
            aliases = {
              "Detrimental Cast Time Reduction",
            },
            ids = {
              27621,
            },
            item = "Detrimental Cast Time Reduction",
          },
          ["Detrimental Damage"] = {
            aliases = {
              "Detrimental Damage",
            },
            ids = {
              150047,
            },
            item = "Detrimental Damage",
          },
          ["Detrimental Duration Damage"] = {
            aliases = {
              "Detrimental Duration Damage",
            },
            ids = {
              150048,
            },
            item = "Detrimental Duration Damage",
          },
          ["Detrimental Extension"] = {
            aliases = {
              "Detrimental Extension",
            },
            ids = {
              28112,
            },
            item = "Detrimental Extension",
          },
          ["Detrimental Reduction of Mana"] = {
            aliases = {
              "Detrimental Reduction of Mana",
            },
            ids = {
              27618,
            },
            item = "Detrimental Reduction of Mana",
          },
          ["Disease Damage"] = {
            aliases = {
              "Disease Damage",
            },
            ids = {
              28109,
            },
            item = "Disease Damage",
          },
          ["Double Attack"] = {
            aliases = {
              "Double Attack",
            },
            ids = {
              28116,
            },
            item = "Double Attack",
          },
          ["Extended Reach"] = {
            aliases = {
              "Extended Reach",
            },
            ids = {
              28115,
              150049,
            },
            item = "Extended Reach",
          },
          ["Fire Damage"] = {
            aliases = {
              "Fire Damage",
            },
            ids = {
              27623,
            },
            item = "Fire Damage",
          },
          ["Ice Damage"] = {
            aliases = {
              "Ice Damage",
            },
            ids = {
              27624,
            },
            item = "Ice Damage",
          },
          ["Improved Dodge"] = {
            aliases = {
              "Improved Dodge",
            },
            ids = {
              28119,
            },
            item = "Improved Dodge",
          },
          ["Increased Healing"] = {
            aliases = {
              "Increased Healing",
            },
            ids = {
              28110,
              150046,
            },
            item = "Increased Healing",
          },
          ["Magic Damage"] = {
            aliases = {
              "Magic Damage",
            },
            ids = {
              28114,
            },
            item = "Magic Damage",
          },
          ["Pet Healing"] = {
            aliases = {
              "Pet Healing",
            },
            ids = {
              28111,
            },
            item = "Pet Healing",
          },
          ["Poison Damage"] = {
            aliases = {
              "Poison Damage",
            },
            ids = {
              27625,
            },
            item = "Poison Damage",
          },
        },
        Berserker = {
          ["Beneficial Cast Time Reduction"] = {
            aliases = {
              "Beneficial Cast Time Reduction",
            },
            ids = {
              27622,
            },
            item = "Beneficial Cast Time Reduction",
          },
          ["Beneficial Extension"] = {
            aliases = {
              "Beneficial Extension",
            },
            ids = {
              28113,
            },
            item = "Beneficial Extension",
          },
          ["Block and Parry"] = {
            aliases = {
              "Block and Parry",
            },
            ids = {
              28118,
            },
            item = "Block and Parry",
          },
          Cleave = {
            aliases = {
              "Cleave",
            },
            ids = {
              28117,
            },
            item = "Cleave",
          },
          ["Detrimental Cast Time Reduction"] = {
            aliases = {
              "Detrimental Cast Time Reduction",
            },
            ids = {
              27621,
            },
            item = "Detrimental Cast Time Reduction",
          },
          ["Detrimental Damage"] = {
            aliases = {
              "Detrimental Damage",
            },
            ids = {
              150047,
            },
            item = "Detrimental Damage",
          },
          ["Detrimental Duration Damage"] = {
            aliases = {
              "Detrimental Duration Damage",
            },
            ids = {
            },
            item = "Detrimental Duration Damage",
          },
          ["Detrimental Extension"] = {
            aliases = {
              "Detrimental Extension",
            },
            ids = {
              28112,
            },
            item = "Detrimental Extension",
          },
          ["Detrimental Reduction of Mana"] = {
            aliases = {
              "Detrimental Reduction of Mana",
            },
            ids = {
              27618,
            },
            item = "Detrimental Reduction of Mana",
          },
          ["Disease Damage"] = {
            aliases = {
              "Disease Damage",
            },
            ids = {
              28109,
            },
            item = "Disease Damage",
          },
          ["Double Attack"] = {
            aliases = {
              "Double Attack",
            },
            ids = {
              28116,
            },
            item = "Double Attack",
          },
          ["Extended Reach"] = {
            aliases = {
              "Extended Reach",
            },
            ids = {
              28115,
            },
            item = "Extended Reach",
          },
          ["Fire Damage"] = {
            aliases = {
              "Fire Damage",
            },
            ids = {
              27623,
            },
            item = "Fire Damage",
          },
          ["Ice Damage"] = {
            aliases = {
              "Ice Damage",
            },
            ids = {
              27624,
            },
            item = "Ice Damage",
          },
          ["Improved Dodge"] = {
            aliases = {
              "Improved Dodge",
            },
            ids = {
              28119,
            },
            item = "Improved Dodge",
          },
          ["Magic Damage"] = {
            aliases = {
              "Magic Damage",
            },
            ids = {
              28114,
            },
            item = "Magic Damage",
          },
          ["Poison Damage"] = {
            aliases = {
              "Poison Damage",
            },
            ids = {
              27625,
            },
            item = "Poison Damage",
          },
        },
        Cleric = {
          ["Beneficial Cast Time Reduction"] = {
            aliases = {
              "Beneficial Cast Time Reduction",
            },
            ids = {
              27622,
              150044,
            },
            item = "Beneficial Cast Time Reduction",
          },
          ["Beneficial Extension"] = {
            aliases = {
              "Beneficial Extension",
            },
            ids = {
              28113,
              150045,
            },
            item = "Beneficial Extension",
          },
          ["Beneficial Reduction of Mana"] = {
            aliases = {
              "Beneficial Reduction of Mana",
            },
            ids = {
              27620,
              150043,
            },
            item = "Beneficial Reduction of Mana",
          },
          Cleave = {
            aliases = {
              "Cleave",
            },
            ids = {
              28117,
            },
            item = "Cleave",
          },
          ["Detrimental Cast Time Reduction"] = {
            aliases = {
              "Detrimental Cast Time Reduction",
            },
            ids = {
              27621,
            },
            item = "Detrimental Cast Time Reduction",
          },
          ["Detrimental Damage"] = {
            aliases = {
              "Detrimental Damage",
            },
            ids = {
              150047,
            },
            item = "Detrimental Damage",
          },
          ["Detrimental Duration Damage"] = {
            aliases = {
              "Detrimental Duration Damage",
            },
            ids = {
              150048,
            },
            item = "Detrimental Duration Damage",
          },
          ["Detrimental Extension"] = {
            aliases = {
              "Detrimental Extension",
            },
            ids = {
              28112,
            },
            item = "Detrimental Extension",
          },
          ["Detrimental Reduction of Mana"] = {
            aliases = {
              "Detrimental Reduction of Mana",
            },
            ids = {
              27618,
            },
            item = "Detrimental Reduction of Mana",
          },
          ["Disease Damage"] = {
            aliases = {
              "Disease Damage",
            },
            ids = {
              28109,
            },
            item = "Disease Damage",
          },
          ["Double Attack"] = {
            aliases = {
              "Double Attack",
            },
            ids = {
              28116,
            },
            item = "Double Attack",
          },
          ["Extended Reach"] = {
            aliases = {
              "Extended Reach",
            },
            ids = {
              28115,
              150049,
            },
            item = "Extended Reach",
          },
          ["Fire Damage"] = {
            aliases = {
              "Fire Damage",
            },
            ids = {
              27623,
            },
            item = "Fire Damage",
          },
          ["Ice Damage"] = {
            aliases = {
              "Ice Damage",
            },
            ids = {
              27624,
            },
            item = "Ice Damage",
          },
          ["Improved Dodge"] = {
            aliases = {
              "Improved Dodge",
            },
            ids = {
              28119,
            },
            item = "Improved Dodge",
          },
          ["Increased Healing"] = {
            aliases = {
              "Increased Healing",
            },
            ids = {
              28110,
              150046,
            },
            item = "Increased Healing",
          },
          ["Magic Damage"] = {
            aliases = {
              "Magic Damage",
            },
            ids = {
              28114,
            },
            item = "Magic Damage",
          },
          ["Poison Damage"] = {
            aliases = {
              "Poison Damage",
            },
            ids = {
              27625,
            },
            item = "Poison Damage",
          },
        },
        Druid = {
          ["Beneficial Cast Time Reduction"] = {
            aliases = {
              "Beneficial Cast Time Reduction",
            },
            ids = {
              27622,
              150044,
            },
            item = "Beneficial Cast Time Reduction",
          },
          ["Beneficial Extension"] = {
            aliases = {
              "Beneficial Extension",
            },
            ids = {
              28113,
              150045,
            },
            item = "Beneficial Extension",
          },
          ["Beneficial Reduction of Mana"] = {
            aliases = {
              "Beneficial Reduction of Mana",
            },
            ids = {
              27620,
              150043,
            },
            item = "Beneficial Reduction of Mana",
          },
          ["Detrimental Cast Time Reduction"] = {
            aliases = {
              "Detrimental Cast Time Reduction",
            },
            ids = {
              27621,
            },
            item = "Detrimental Cast Time Reduction",
          },
          ["Detrimental Damage"] = {
            aliases = {
              "Detrimental Damage",
            },
            ids = {
              150047,
            },
            item = "Detrimental Damage",
          },
          ["Detrimental Duration Damage"] = {
            aliases = {
              "Detrimental Duration Damage",
            },
            ids = {
              150048,
            },
            item = "Detrimental Duration Damage",
          },
          ["Detrimental Extension"] = {
            aliases = {
              "Detrimental Extension",
            },
            ids = {
              28112,
            },
            item = "Detrimental Extension",
          },
          ["Detrimental Reduction of Mana"] = {
            aliases = {
              "Detrimental Reduction of Mana",
            },
            ids = {
              27618,
            },
            item = "Detrimental Reduction of Mana",
          },
          ["Disease Damage"] = {
            aliases = {
              "Disease Damage",
            },
            ids = {
              28109,
            },
            item = "Disease Damage",
          },
          ["Extended Reach"] = {
            aliases = {
              "Extended Reach",
            },
            ids = {
              28115,
              150049,
            },
            item = "Extended Reach",
          },
          ["Fire Damage"] = {
            aliases = {
              "Fire Damage",
            },
            ids = {
              27623,
            },
            item = "Fire Damage",
          },
          ["Ice Damage"] = {
            aliases = {
              "Ice Damage",
            },
            ids = {
              27624,
            },
            item = "Ice Damage",
          },
          ["Improved Dodge"] = {
            aliases = {
              "Improved Dodge",
            },
            ids = {
              28119,
            },
            item = "Improved Dodge",
          },
          ["Increased Healing"] = {
            aliases = {
              "Increased Healing",
            },
            ids = {
              28110,
              150046,
            },
            item = "Increased Healing",
          },
          ["Magic Damage"] = {
            aliases = {
              "Magic Damage",
            },
            ids = {
              28114,
            },
            item = "Magic Damage",
          },
          ["Poison Damage"] = {
            aliases = {
              "Poison Damage",
            },
            ids = {
              27625,
            },
            item = "Poison Damage",
          },
        },
        Enchanter = {
          ["Beneficial Cast Time Reduction"] = {
            aliases = {
              "Beneficial Cast Time Reduction",
            },
            ids = {
              27622,
              150044,
            },
            item = "Beneficial Cast Time Reduction",
          },
          ["Beneficial Extension"] = {
            aliases = {
              "Beneficial Extension",
            },
            ids = {
              28113,
              150045,
            },
            item = "Beneficial Extension",
          },
          ["Beneficial Reduction of Mana"] = {
            aliases = {
              "Beneficial Reduction of Mana",
            },
            ids = {
              27620,
              150043,
            },
            item = "Beneficial Reduction of Mana",
          },
          ["Detrimental Cast Time Reduction"] = {
            aliases = {
              "Detrimental Cast Time Reduction",
            },
            ids = {
              27621,
            },
            item = "Detrimental Cast Time Reduction",
          },
          ["Detrimental Damage"] = {
            aliases = {
              "Detrimental Damage",
            },
            ids = {
              150047,
            },
            item = "Detrimental Damage",
          },
          ["Detrimental Duration Damage"] = {
            aliases = {
              "Detrimental Duration Damage",
            },
            ids = {
              150048,
            },
            item = "Detrimental Duration Damage",
          },
          ["Detrimental Extension"] = {
            aliases = {
              "Detrimental Extension",
            },
            ids = {
              28112,
            },
            item = "Detrimental Extension",
          },
          ["Detrimental Reduction of Mana"] = {
            aliases = {
              "Detrimental Reduction of Mana",
            },
            ids = {
              27618,
            },
            item = "Detrimental Reduction of Mana",
          },
          ["Disease Damage"] = {
            aliases = {
              "Disease Damage",
            },
            ids = {
              28109,
            },
            item = "Disease Damage",
          },
          ["Extended Reach"] = {
            aliases = {
              "Extended Reach",
            },
            ids = {
              28115,
              150049,
            },
            item = "Extended Reach",
          },
          ["Fire Damage"] = {
            aliases = {
              "Fire Damage",
            },
            ids = {
              27623,
            },
            item = "Fire Damage",
          },
          ["Ice Damage"] = {
            aliases = {
              "Ice Damage",
            },
            ids = {
              27624,
            },
            item = "Ice Damage",
          },
          ["Improved Dodge"] = {
            aliases = {
              "Improved Dodge",
            },
            ids = {
              28119,
            },
            item = "Improved Dodge",
          },
          ["Magic Damage"] = {
            aliases = {
              "Magic Damage",
            },
            ids = {
              28114,
            },
            item = "Magic Damage",
          },
          ["Poison Damage"] = {
            aliases = {
              "Poison Damage",
            },
            ids = {
              27625,
            },
            item = "Poison Damage",
          },
        },
        Magician = {
          ["Beneficial Cast Time Reduction"] = {
            aliases = {
              "Beneficial Cast Time Reduction",
            },
            ids = {
              27622,
              150044,
            },
            item = "Beneficial Cast Time Reduction",
          },
          ["Beneficial Extension"] = {
            aliases = {
              "Beneficial Extension",
            },
            ids = {
              28113,
              150045,
            },
            item = "Beneficial Extension",
          },
          ["Beneficial Reduction of Mana"] = {
            aliases = {
              "Beneficial Reduction of Mana",
            },
            ids = {
              27620,
              150043,
            },
            item = "Beneficial Reduction of Mana",
          },
          ["Detrimental Cast Time Reduction"] = {
            aliases = {
              "Detrimental Cast Time Reduction",
            },
            ids = {
              27621,
            },
            item = "Detrimental Cast Time Reduction",
          },
          ["Detrimental Damage"] = {
            aliases = {
              "Detrimental Damage",
            },
            ids = {
              150047,
            },
            item = "Detrimental Damage",
          },
          ["Detrimental Duration Damage"] = {
            aliases = {
              "Detrimental Duration Damage",
            },
            ids = {
              150048,
            },
            item = "Detrimental Duration Damage",
          },
          ["Detrimental Extension"] = {
            aliases = {
              "Detrimental Extension",
            },
            ids = {
              28112,
            },
            item = "Detrimental Extension",
          },
          ["Detrimental Reduction of Mana"] = {
            aliases = {
              "Detrimental Reduction of Mana",
            },
            ids = {
              27618,
            },
            item = "Detrimental Reduction of Mana",
          },
          ["Disease Damage"] = {
            aliases = {
              "Disease Damage",
            },
            ids = {
              28109,
            },
            item = "Disease Damage",
          },
          ["Extended Reach"] = {
            aliases = {
              "Extended Reach",
            },
            ids = {
              28115,
              150049,
            },
            item = "Extended Reach",
          },
          ["Fire Damage"] = {
            aliases = {
              "Fire Damage",
            },
            ids = {
              27623,
            },
            item = "Fire Damage",
          },
          ["Ice Damage"] = {
            aliases = {
              "Ice Damage",
            },
            ids = {
              27624,
            },
            item = "Ice Damage",
          },
          ["Improved Dodge"] = {
            aliases = {
              "Improved Dodge",
            },
            ids = {
              28119,
            },
            item = "Improved Dodge",
          },
          ["Increased Healing"] = {
            aliases = {
              "Increased Healing",
            },
            ids = {
              28110,
              150046,
            },
            item = "Increased Healing",
          },
          ["Magic Damage"] = {
            aliases = {
              "Magic Damage",
            },
            ids = {
              28114,
            },
            item = "Magic Damage",
          },
          ["Pet Healing"] = {
            aliases = {
              "Pet Healing",
            },
            ids = {
              28111,
            },
            item = "Pet Healing",
          },
          ["Poison Damage"] = {
            aliases = {
              "Poison Damage",
            },
            ids = {
              27625,
            },
            item = "Poison Damage",
          },
        },
        Monk = {
          ["Beneficial Cast Time Reduction"] = {
            aliases = {
              "Beneficial Cast Time Reduction",
            },
            ids = {
              27622,
            },
            item = "Beneficial Cast Time Reduction",
          },
          ["Beneficial Extension"] = {
            aliases = {
              "Beneficial Extension",
            },
            ids = {
              28113,
            },
            item = "Beneficial Extension",
          },
          ["Block and Parry"] = {
            aliases = {
              "Block and Parry",
            },
            ids = {
              28118,
            },
            item = "Block and Parry",
          },
          Cleave = {
            aliases = {
              "Cleave",
            },
            ids = {
              28117,
            },
            item = "Cleave",
          },
          ["Detrimental Cast Time Reduction"] = {
            aliases = {
              "Detrimental Cast Time Reduction",
            },
            ids = {
              27621,
            },
            item = "Detrimental Cast Time Reduction",
          },
          ["Detrimental Damage"] = {
            aliases = {
              "Detrimental Damage",
            },
            ids = {
            },
            item = "Detrimental Damage",
          },
          ["Detrimental Duration Damage"] = {
            aliases = {
              "Detrimental Duration Damage",
            },
            ids = {
            },
            item = "Detrimental Duration Damage",
          },
          ["Detrimental Extension"] = {
            aliases = {
              "Detrimental Extension",
            },
            ids = {
              28112,
            },
            item = "Detrimental Extension",
          },
          ["Detrimental Reduction of Mana"] = {
            aliases = {
              "Detrimental Reduction of Mana",
            },
            ids = {
              27618,
            },
            item = "Detrimental Reduction of Mana",
          },
          ["Disease Damage"] = {
            aliases = {
              "Disease Damage",
            },
            ids = {
              28109,
            },
            item = "Disease Damage",
          },
          ["Double Attack"] = {
            aliases = {
              "Double Attack",
            },
            ids = {
              28116,
            },
            item = "Double Attack",
          },
          ["Extended Reach"] = {
            aliases = {
              "Extended Reach",
            },
            ids = {
              28115,
            },
            item = "Extended Reach",
          },
          ["Fire Damage"] = {
            aliases = {
              "Fire Damage",
            },
            ids = {
              27623,
            },
            item = "Fire Damage",
          },
          ["Ice Damage"] = {
            aliases = {
              "Ice Damage",
            },
            ids = {
              27624,
            },
            item = "Ice Damage",
          },
          ["Improved Dodge"] = {
            aliases = {
              "Improved Dodge",
            },
            ids = {
              28119,
            },
            item = "Improved Dodge",
          },
          ["Magic Damage"] = {
            aliases = {
              "Magic Damage",
            },
            ids = {
              28114,
            },
            item = "Magic Damage",
          },
          ["Poison Damage"] = {
            aliases = {
              "Poison Damage",
            },
            ids = {
              27625,
            },
            item = "Poison Damage",
          },
        },
        Necromancer = {
          ["Beneficial Cast Time Reduction"] = {
            aliases = {
              "Beneficial Cast Time Reduction",
            },
            ids = {
              27622,
              150044,
            },
            item = "Beneficial Cast Time Reduction",
          },
          ["Beneficial Extension"] = {
            aliases = {
              "Beneficial Extension",
            },
            ids = {
              28113,
              150045,
            },
            item = "Beneficial Extension",
          },
          ["Beneficial Reduction of Mana"] = {
            aliases = {
              "Beneficial Reduction of Mana",
            },
            ids = {
              27620,
              150043,
            },
            item = "Beneficial Reduction of Mana",
          },
          ["Detrimental Cast Time Reduction"] = {
            aliases = {
              "Detrimental Cast Time Reduction",
            },
            ids = {
              27621,
            },
            item = "Detrimental Cast Time Reduction",
          },
          ["Detrimental Damage"] = {
            aliases = {
              "Detrimental Damage",
            },
            ids = {
              150047,
            },
            item = "Detrimental Damage",
          },
          ["Detrimental Duration Damage"] = {
            aliases = {
              "Detrimental Duration Damage",
            },
            ids = {
              150048,
            },
            item = "Detrimental Duration Damage",
          },
          ["Detrimental Extension"] = {
            aliases = {
              "Detrimental Extension",
            },
            ids = {
              28112,
            },
            item = "Detrimental Extension",
          },
          ["Detrimental Reduction of Mana"] = {
            aliases = {
              "Detrimental Reduction of Mana",
            },
            ids = {
              27618,
            },
            item = "Detrimental Reduction of Mana",
          },
          ["Disease Damage"] = {
            aliases = {
              "Disease Damage",
            },
            ids = {
              28109,
            },
            item = "Disease Damage",
          },
          ["Extended Reach"] = {
            aliases = {
              "Extended Reach",
            },
            ids = {
              28115,
              150049,
            },
            item = "Extended Reach",
          },
          ["Fire Damage"] = {
            aliases = {
              "Fire Damage",
            },
            ids = {
              27623,
            },
            item = "Fire Damage",
          },
          ["Ice Damage"] = {
            aliases = {
              "Ice Damage",
            },
            ids = {
              27624,
            },
            item = "Ice Damage",
          },
          ["Improved Dodge"] = {
            aliases = {
              "Improved Dodge",
            },
            ids = {
              28119,
            },
            item = "Improved Dodge",
          },
          ["Increased Healing"] = {
            aliases = {
              "Increased Healing",
            },
            ids = {
              28110,
              150046,
            },
            item = "Increased Healing",
          },
          ["Magic Damage"] = {
            aliases = {
              "Magic Damage",
            },
            ids = {
              28114,
            },
            item = "Magic Damage",
          },
          ["Pet Healing"] = {
            aliases = {
              "Pet Healing",
            },
            ids = {
              28111,
            },
            item = "Pet Healing",
          },
          ["Poison Damage"] = {
            aliases = {
              "Poison Damage",
            },
            ids = {
              27625,
            },
            item = "Poison Damage",
          },
        },
        Paladin = {
          ["Beneficial Cast Time Reduction"] = {
            aliases = {
              "Beneficial Cast Time Reduction",
            },
            ids = {
              27622,
              150044,
            },
            item = "Beneficial Cast Time Reduction",
          },
          ["Beneficial Extension"] = {
            aliases = {
              "Beneficial Extension",
            },
            ids = {
              28113,
              150045,
            },
            item = "Beneficial Extension",
          },
          ["Beneficial Reduction of Mana"] = {
            aliases = {
              "Beneficial Reduction of Mana",
            },
            ids = {
              27620,
              150043,
            },
            item = "Beneficial Reduction of Mana",
          },
          ["Block and Parry"] = {
            aliases = {
              "Block and Parry",
            },
            ids = {
              28118,
            },
            item = "Block and Parry",
          },
          Cleave = {
            aliases = {
              "Cleave",
            },
            ids = {
              28117,
            },
            item = "Cleave",
          },
          ["Detrimental Cast Time Reduction"] = {
            aliases = {
              "Detrimental Cast Time Reduction",
            },
            ids = {
              27621,
            },
            item = "Detrimental Cast Time Reduction",
          },
          ["Detrimental Damage"] = {
            aliases = {
              "Detrimental Damage",
            },
            ids = {
              150047,
            },
            item = "Detrimental Damage",
          },
          ["Detrimental Duration Damage"] = {
            aliases = {
              "Detrimental Duration Damage",
            },
            ids = {
              150048,
            },
            item = "Detrimental Duration Damage",
          },
          ["Detrimental Extension"] = {
            aliases = {
              "Detrimental Extension",
            },
            ids = {
              28112,
            },
            item = "Detrimental Extension",
          },
          ["Detrimental Reduction of Mana"] = {
            aliases = {
              "Detrimental Reduction of Mana",
            },
            ids = {
              27618,
            },
            item = "Detrimental Reduction of Mana",
          },
          ["Disease Damage"] = {
            aliases = {
              "Disease Damage",
            },
            ids = {
              28109,
            },
            item = "Disease Damage",
          },
          ["Double Attack"] = {
            aliases = {
              "Double Attack",
            },
            ids = {
              28116,
            },
            item = "Double Attack",
          },
          ["Extended Reach"] = {
            aliases = {
              "Extended Reach",
            },
            ids = {
              28115,
              150049,
            },
            item = "Extended Reach",
          },
          ["Fire Damage"] = {
            aliases = {
              "Fire Damage",
            },
            ids = {
              27623,
            },
            item = "Fire Damage",
          },
          ["Ice Damage"] = {
            aliases = {
              "Ice Damage",
            },
            ids = {
              27624,
            },
            item = "Ice Damage",
          },
          ["Improved Dodge"] = {
            aliases = {
              "Improved Dodge",
            },
            ids = {
              28119,
            },
            item = "Improved Dodge",
          },
          ["Increased Healing"] = {
            aliases = {
              "Increased Healing",
            },
            ids = {
              28110,
              150046,
            },
            item = "Increased Healing",
          },
          ["Magic Damage"] = {
            aliases = {
              "Magic Damage",
            },
            ids = {
              28114,
            },
            item = "Magic Damage",
          },
          ["Poison Damage"] = {
            aliases = {
              "Poison Damage",
            },
            ids = {
              27625,
            },
            item = "Poison Damage",
          },
        },
        Ranger = {
          ["Beneficial Cast Time Reduction"] = {
            aliases = {
              "Beneficial Cast Time Reduction",
            },
            ids = {
              27622,
              150044,
            },
            item = "Beneficial Cast Time Reduction",
          },
          ["Beneficial Extension"] = {
            aliases = {
              "Beneficial Extension",
            },
            ids = {
              28113,
              150045,
            },
            item = "Beneficial Extension",
          },
          ["Beneficial Reduction of Mana"] = {
            aliases = {
              "Beneficial Reduction of Mana",
            },
            ids = {
              27620,
              150043,
            },
            item = "Beneficial Reduction of Mana",
          },
          ["Block and Parry"] = {
            aliases = {
              "Block and Parry",
            },
            ids = {
              28118,
            },
            item = "Block and Parry",
          },
          Cleave = {
            aliases = {
              "Cleave",
            },
            ids = {
              28117,
            },
            item = "Cleave",
          },
          ["Detrimental Cast Time Reduction"] = {
            aliases = {
              "Detrimental Cast Time Reduction",
            },
            ids = {
              27621,
            },
            item = "Detrimental Cast Time Reduction",
          },
          ["Detrimental Damage"] = {
            aliases = {
              "Detrimental Damage",
            },
            ids = {
              150047,
            },
            item = "Detrimental Damage",
          },
          ["Detrimental Duration Damage"] = {
            aliases = {
              "Detrimental Duration Damage",
            },
            ids = {
              150048,
            },
            item = "Detrimental Duration Damage",
          },
          ["Detrimental Extension"] = {
            aliases = {
              "Detrimental Extension",
            },
            ids = {
              28112,
            },
            item = "Detrimental Extension",
          },
          ["Detrimental Reduction of Mana"] = {
            aliases = {
              "Detrimental Reduction of Mana",
            },
            ids = {
              27618,
            },
            item = "Detrimental Reduction of Mana",
          },
          ["Disease Damage"] = {
            aliases = {
              "Disease Damage",
            },
            ids = {
              28109,
            },
            item = "Disease Damage",
          },
          ["Double Attack"] = {
            aliases = {
              "Double Attack",
            },
            ids = {
              28116,
            },
            item = "Double Attack",
          },
          ["Extended Reach"] = {
            aliases = {
              "Extended Reach",
            },
            ids = {
              28115,
              150049,
            },
            item = "Extended Reach",
          },
          ["Fire Damage"] = {
            aliases = {
              "Fire Damage",
            },
            ids = {
              27623,
            },
            item = "Fire Damage",
          },
          ["Ice Damage"] = {
            aliases = {
              "Ice Damage",
            },
            ids = {
              27624,
            },
            item = "Ice Damage",
          },
          ["Improved Dodge"] = {
            aliases = {
              "Improved Dodge",
            },
            ids = {
              28119,
            },
            item = "Improved Dodge",
          },
          ["Increased Healing"] = {
            aliases = {
              "Increased Healing",
            },
            ids = {
              28110,
              150046,
            },
            item = "Increased Healing",
          },
          ["Magic Damage"] = {
            aliases = {
              "Magic Damage",
            },
            ids = {
              28114,
            },
            item = "Magic Damage",
          },
          ["Poison Damage"] = {
            aliases = {
              "Poison Damage",
            },
            ids = {
              27625,
            },
            item = "Poison Damage",
          },
        },
        Rogue = {
          ["Beneficial Cast Time Reduction"] = {
            aliases = {
              "Beneficial Cast Time Reduction",
            },
            ids = {
              27622,
            },
            item = "Beneficial Cast Time Reduction",
          },
          ["Beneficial Extension"] = {
            aliases = {
              "Beneficial Extension",
            },
            ids = {
              28113,
            },
            item = "Beneficial Extension",
          },
          ["Block and Parry"] = {
            aliases = {
              "Block and Parry",
            },
            ids = {
              28118,
            },
            item = "Block and Parry",
          },
          Cleave = {
            aliases = {
              "Cleave",
            },
            ids = {
              28117,
            },
            item = "Cleave",
          },
          ["Detrimental Cast Time Reduction"] = {
            aliases = {
              "Detrimental Cast Time Reduction",
            },
            ids = {
              27621,
            },
            item = "Detrimental Cast Time Reduction",
          },
          ["Detrimental Damage"] = {
            aliases = {
              "Detrimental Damage",
            },
            ids = {
            },
            item = "Detrimental Damage",
          },
          ["Detrimental Duration Damage"] = {
            aliases = {
              "Detrimental Duration Damage",
            },
            ids = {
            },
            item = "Detrimental Duration Damage",
          },
          ["Detrimental Extension"] = {
            aliases = {
              "Detrimental Extension",
            },
            ids = {
              28112,
            },
            item = "Detrimental Extension",
          },
          ["Detrimental Reduction of Mana"] = {
            aliases = {
              "Detrimental Reduction of Mana",
            },
            ids = {
              27618,
            },
            item = "Detrimental Reduction of Mana",
          },
          ["Disease Damage"] = {
            aliases = {
              "Disease Damage",
            },
            ids = {
              28109,
            },
            item = "Disease Damage",
          },
          ["Double Attack"] = {
            aliases = {
              "Double Attack",
            },
            ids = {
              28116,
            },
            item = "Double Attack",
          },
          ["Extended Reach"] = {
            aliases = {
              "Extended Reach",
            },
            ids = {
              28115,
            },
            item = "Extended Reach",
          },
          ["Fire Damage"] = {
            aliases = {
              "Fire Damage",
            },
            ids = {
              27623,
            },
            item = "Fire Damage",
          },
          ["Ice Damage"] = {
            aliases = {
              "Ice Damage",
            },
            ids = {
              27624,
            },
            item = "Ice Damage",
          },
          ["Improved Dodge"] = {
            aliases = {
              "Improved Dodge",
            },
            ids = {
              28119,
            },
            item = "Improved Dodge",
          },
          ["Magic Damage"] = {
            aliases = {
              "Magic Damage",
            },
            ids = {
              28114,
            },
            item = "Magic Damage",
          },
          ["Poison Damage"] = {
            aliases = {
              "Poison Damage",
            },
            ids = {
              27625,
            },
            item = "Poison Damage",
          },
        },
        ["Shadow Knight"] = {
          ["Beneficial Cast Time Reduction"] = {
            aliases = {
              "Beneficial Cast Time Reduction",
            },
            ids = {
              27622,
              150044,
            },
            item = "Beneficial Cast Time Reduction",
          },
          ["Beneficial Extension"] = {
            aliases = {
              "Beneficial Extension",
            },
            ids = {
              28113,
              150045,
            },
            item = "Beneficial Extension",
          },
          ["Beneficial Reduction of Mana"] = {
            aliases = {
              "Beneficial Reduction of Mana",
            },
            ids = {
              27620,
              150043,
            },
            item = "Beneficial Reduction of Mana",
          },
          ["Block and Parry"] = {
            aliases = {
              "Block and Parry",
            },
            ids = {
              28118,
            },
            item = "Block and Parry",
          },
          Cleave = {
            aliases = {
              "Cleave",
            },
            ids = {
              28117,
            },
            item = "Cleave",
          },
          ["Detrimental Cast Time Reduction"] = {
            aliases = {
              "Detrimental Cast Time Reduction",
            },
            ids = {
              27621,
            },
            item = "Detrimental Cast Time Reduction",
          },
          ["Detrimental Damage"] = {
            aliases = {
              "Detrimental Damage",
            },
            ids = {
              150047,
            },
            item = "Detrimental Damage",
          },
          ["Detrimental Duration Damage"] = {
            aliases = {
              "Detrimental Duration Damage",
            },
            ids = {
              150048,
            },
            item = "Detrimental Duration Damage",
          },
          ["Detrimental Extension"] = {
            aliases = {
              "Detrimental Extension",
            },
            ids = {
              28112,
            },
            item = "Detrimental Extension",
          },
          ["Detrimental Reduction of Mana"] = {
            aliases = {
              "Detrimental Reduction of Mana",
            },
            ids = {
              27618,
            },
            item = "Detrimental Reduction of Mana",
          },
          ["Disease Damage"] = {
            aliases = {
              "Disease Damage",
            },
            ids = {
              28109,
            },
            item = "Disease Damage",
          },
          ["Double Attack"] = {
            aliases = {
              "Double Attack",
            },
            ids = {
              28116,
            },
            item = "Double Attack",
          },
          ["Extended Reach"] = {
            aliases = {
              "Extended Reach",
            },
            ids = {
              28115,
              150049,
            },
            item = "Extended Reach",
          },
          ["Fire Damage"] = {
            aliases = {
              "Fire Damage",
            },
            ids = {
              27623,
            },
            item = "Fire Damage",
          },
          ["Ice Damage"] = {
            aliases = {
              "Ice Damage",
            },
            ids = {
              27624,
            },
            item = "Ice Damage",
          },
          ["Improved Dodge"] = {
            aliases = {
              "Improved Dodge",
            },
            ids = {
              28119,
            },
            item = "Improved Dodge",
          },
          ["Increased Healing"] = {
            aliases = {
              "Increased Healing",
            },
            ids = {
              28110,
              150046,
            },
            item = "Increased Healing",
          },
          ["Magic Damage"] = {
            aliases = {
              "Magic Damage",
            },
            ids = {
              28114,
            },
            item = "Magic Damage",
          },
          ["Poison Damage"] = {
            aliases = {
              "Poison Damage",
            },
            ids = {
              27625,
            },
            item = "Poison Damage",
          },
        },
        Shaman = {
          ["Beneficial Cast Time Reduction"] = {
            aliases = {
              "Beneficial Cast Time Reduction",
            },
            ids = {
              27622,
              150044,
            },
            item = "Beneficial Cast Time Reduction",
          },
          ["Beneficial Extension"] = {
            aliases = {
              "Beneficial Extension",
            },
            ids = {
              28113,
              150045,
            },
            item = "Beneficial Extension",
          },
          ["Beneficial Reduction of Mana"] = {
            aliases = {
              "Beneficial Reduction of Mana",
            },
            ids = {
              27620,
              150043,
            },
            item = "Beneficial Reduction of Mana",
          },
          ["Detrimental Cast Time Reduction"] = {
            aliases = {
              "Detrimental Cast Time Reduction",
            },
            ids = {
              27621,
            },
            item = "Detrimental Cast Time Reduction",
          },
          ["Detrimental Damage"] = {
            aliases = {
              "Detrimental Damage",
            },
            ids = {
              150047,
            },
            item = "Detrimental Damage",
          },
          ["Detrimental Duration Damage"] = {
            aliases = {
              "Detrimental Duration Damage",
            },
            ids = {
              150048,
            },
            item = "Detrimental Duration Damage",
          },
          ["Detrimental Extension"] = {
            aliases = {
              "Detrimental Extension",
            },
            ids = {
              28112,
            },
            item = "Detrimental Extension",
          },
          ["Detrimental Reduction of Mana"] = {
            aliases = {
              "Detrimental Reduction of Mana",
            },
            ids = {
              27618,
            },
            item = "Detrimental Reduction of Mana",
          },
          ["Disease Damage"] = {
            aliases = {
              "Disease Damage",
            },
            ids = {
              28109,
            },
            item = "Disease Damage",
          },
          ["Extended Reach"] = {
            aliases = {
              "Extended Reach",
            },
            ids = {
              28115,
              150049,
            },
            item = "Extended Reach",
          },
          ["Fire Damage"] = {
            aliases = {
              "Fire Damage",
            },
            ids = {
              27623,
            },
            item = "Fire Damage",
          },
          ["Ice Damage"] = {
            aliases = {
              "Ice Damage",
            },
            ids = {
              27624,
            },
            item = "Ice Damage",
          },
          ["Improved Dodge"] = {
            aliases = {
              "Improved Dodge",
            },
            ids = {
              28119,
            },
            item = "Improved Dodge",
          },
          ["Increased Healing"] = {
            aliases = {
              "Increased Healing",
            },
            ids = {
              28110,
              150046,
            },
            item = "Increased Healing",
          },
          ["Magic Damage"] = {
            aliases = {
              "Magic Damage",
            },
            ids = {
              28114,
            },
            item = "Magic Damage",
          },
          ["Poison Damage"] = {
            aliases = {
              "Poison Damage",
            },
            ids = {
              27625,
            },
            item = "Poison Damage",
          },
        },
        Warrior = {
          ["Beneficial Cast Time Reduction"] = {
            aliases = {
              "Beneficial Cast Time Reduction",
            },
            ids = {
              27622,
            },
            item = "Beneficial Cast Time Reduction",
          },
          ["Beneficial Extension"] = {
            aliases = {
              "Beneficial Extension",
            },
            ids = {
              28113,
            },
            item = "Beneficial Extension",
          },
          ["Block and Parry"] = {
            aliases = {
              "Block and Parry",
            },
            ids = {
              28118,
            },
            item = "Block and Parry",
          },
          Cleave = {
            aliases = {
              "Cleave",
            },
            ids = {
              28117,
            },
            item = "Cleave",
          },
          ["Detrimental Cast Time Reduction"] = {
            aliases = {
              "Detrimental Cast Time Reduction",
            },
            ids = {
              27621,
            },
            item = "Detrimental Cast Time Reduction",
          },
          ["Detrimental Damage"] = {
            aliases = {
              "Detrimental Damage",
            },
            ids = {
            },
            item = "Detrimental Damage",
          },
          ["Detrimental Duration Damage"] = {
            aliases = {
              "Detrimental Duration Damage",
            },
            ids = {
            },
            item = "Detrimental Duration Damage",
          },
          ["Detrimental Extension"] = {
            aliases = {
              "Detrimental Extension",
            },
            ids = {
              28112,
            },
            item = "Detrimental Extension",
          },
          ["Detrimental Reduction of Mana"] = {
            aliases = {
              "Detrimental Reduction of Mana",
            },
            ids = {
              27618,
            },
            item = "Detrimental Reduction of Mana",
          },
          ["Disease Damage"] = {
            aliases = {
              "Disease Damage",
            },
            ids = {
              28109,
            },
            item = "Disease Damage",
          },
          ["Double Attack"] = {
            aliases = {
              "Double Attack",
            },
            ids = {
              28116,
            },
            item = "Double Attack",
          },
          ["Extended Reach"] = {
            aliases = {
              "Extended Reach",
            },
            ids = {
              28115,
            },
            item = "Extended Reach",
          },
          ["Fire Damage"] = {
            aliases = {
              "Fire Damage",
            },
            ids = {
              27623,
            },
            item = "Fire Damage",
          },
          ["Ice Damage"] = {
            aliases = {
              "Ice Damage",
            },
            ids = {
              27624,
            },
            item = "Ice Damage",
          },
          ["Improved Dodge"] = {
            aliases = {
              "Improved Dodge",
            },
            ids = {
              28119,
            },
            item = "Improved Dodge",
          },
          ["Magic Damage"] = {
            aliases = {
              "Magic Damage",
            },
            ids = {
              28114,
            },
            item = "Magic Damage",
          },
          ["Poison Damage"] = {
            aliases = {
              "Poison Damage",
            },
            ids = {
              27625,
            },
            item = "Poison Damage",
          },
        },
        Wizard = {
          ["Beneficial Cast Time Reduction"] = {
            aliases = {
              "Beneficial Cast Time Reduction",
            },
            ids = {
              27622,
              150044,
            },
            item = "Beneficial Cast Time Reduction",
          },
          ["Beneficial Extension"] = {
            aliases = {
              "Beneficial Extension",
            },
            ids = {
              28113,
              150045,
            },
            item = "Beneficial Extension",
          },
          ["Beneficial Reduction of Mana"] = {
            aliases = {
              "Beneficial Reduction of Mana",
            },
            ids = {
              27620,
              150043,
            },
            item = "Beneficial Reduction of Mana",
          },
          ["Detrimental Cast Time Reduction"] = {
            aliases = {
              "Detrimental Cast Time Reduction",
            },
            ids = {
              27621,
            },
            item = "Detrimental Cast Time Reduction",
          },
          ["Detrimental Damage"] = {
            aliases = {
              "Detrimental Damage",
            },
            ids = {
            },
            item = "Detrimental Damage",
          },
          ["Detrimental Duration Damage"] = {
            aliases = {
              "Detrimental Duration Damage",
            },
            ids = {
              150048,
            },
            item = "Detrimental Duration Damage",
          },
          ["Detrimental Extension"] = {
            aliases = {
              "Detrimental Extension",
            },
            ids = {
              28112,
            },
            item = "Detrimental Extension",
          },
          ["Detrimental Reduction of Mana"] = {
            aliases = {
              "Detrimental Reduction of Mana",
            },
            ids = {
              27618,
            },
            item = "Detrimental Reduction of Mana",
          },
          ["Disease Damage"] = {
            aliases = {
              "Disease Damage",
            },
            ids = {
              28109,
            },
            item = "Disease Damage",
          },
          ["Extended Reach"] = {
            aliases = {
              "Extended Reach",
            },
            ids = {
              28115,
              150049,
            },
            item = "Extended Reach",
          },
          ["Fire Damage"] = {
            aliases = {
              "Fire Damage",
            },
            ids = {
              27623,
            },
            item = "Fire Damage",
          },
          ["Ice Damage"] = {
            aliases = {
              "Ice Damage",
            },
            ids = {
              27624,
            },
            item = "Ice Damage",
          },
          ["Improved Dodge"] = {
            aliases = {
              "Improved Dodge",
            },
            ids = {
              28119,
            },
            item = "Improved Dodge",
          },
          ["Magic Damage"] = {
            aliases = {
              "Magic Damage",
            },
            ids = {
              28114,
            },
            item = "Magic Damage",
          },
          ["Poison Damage"] = {
            aliases = {
              "Poison Damage",
            },
            ids = {
              27625,
            },
            item = "Poison Damage",
          },
        },
      },
      group = "Other Checklists",
      id = "focusitems",
      name = "Focus Items",
      show_base = {
      },
      template = {
        ["EnchantedJewel(Shielding)"] = {
          aliases = {
            "Enchanted Jewel of Shielding",
          },
          ids = {
          },
          item = "Enchanted Jewel of Shielding",
        },
      },
      visible = {
      },
    },
    fuku = {
      categories = {
        {
          name = "Augs",
          slots = {
            "Globe",
            "Heart",
            "Rune",
            "Ornament",
          },
        },
        {
          name = "Clickies",
          slots = {
            "Boots (Potent Prowess)",
            "Bracelet (Boon of the Ancients)",
            "Cap (Scribes Endurance)",
            "Hammer (DA)",
            "Mantle (Unwavering Defense)",
            "Ring (Pestilence Bolt)",
            "FabledBrew (Hops)",
            "Shield for Radix",
          },
        },
        {
          name = "Pew Pew",
          slots = {
            "Arrow",
          },
        },
      },
      classes = {
        Bard = {
          ["Boots (Potent Prowess)"] = {
            aliases = {
              "Fabled Dwarven Work Boots",
            },
            ids = {
            },
            item = "Fabled Dwarven Work Boots",
          },
          ["Cap (Scribes Endurance)"] = {
            aliases = {
              "Fabled Savant's Cap",
            },
            ids = {
            },
            item = "Fabled Savant's Cap",
          },
          ["FabledBrew (Hops)"] = {
            aliases = {
              "Fabled Blackout Brew",
            },
            ids = {
            },
            item = "Fabled Blackout Brew",
          },
          Heart = {
            aliases = {
              "Fabled Ghoul's Heart",
            },
            ids = {
            },
            item = "Fabled Ghoul's Heart",
          },
          ["Ring (Pestilence Bolt)"] = {
            aliases = {
              "Fabled Jagged Band",
            },
            ids = {
            },
            item = "Fabled Jagged Band",
          },
          Rune = {
            aliases = {
              "Invocation Rune: Vulka's Chant of Lightning",
              "Invocation Glyph: Vulka's Chant of Lightning",
            },
            ids = {
            },
            item = "Invocation Rune: Vulka's Chant of Lightning",
          },
          ["Shield for Radix"] = {
            aliases = {
              "Ancient Shield of Corrupted Tranquility",
            },
            ids = {
              150402,
            },
            item = "Ancient Shield of Corrupted Tranquility",
          },
        },
        Beastlord = {
          ["Boots (Potent Prowess)"] = {
            aliases = {
              "Fabled Dwarven Work Boots",
            },
            ids = {
            },
            item = "Fabled Dwarven Work Boots",
          },
          ["FabledBrew (Hops)"] = {
            aliases = {
              "Fabled Blackout Brew",
            },
            ids = {
            },
            item = "Fabled Blackout Brew",
          },
          Globe = {
            aliases = {
              "Fabled Globe of Mist",
            },
            ids = {
            },
            item = "Fabled Globe of Mist",
          },
          ["Ring (Pestilence Bolt)"] = {
            aliases = {
              "Fabled Jagged Band",
            },
            ids = {
            },
            item = "Fabled Jagged Band",
          },
          Rune = {
            aliases = {
              "Destructive Focus Rune: Reptilian Venom",
              "Destructive Focus Glyph: Reptilian Venom",
            },
            ids = {
            },
            item = "Destructive Focus Rune: Reptilian Venom",
          },
          ["Shield for Radix"] = {
            aliases = {
              "Ancient Shield of Corrupted Tranquility",
            },
            ids = {
              150402,
            },
            item = "Ancient Shield of Corrupted Tranquility",
          },
        },
        Berserker = {
          ["Boots (Potent Prowess)"] = {
            aliases = {
              "Fabled Dwarven Work Boots",
            },
            ids = {
            },
            item = "Fabled Dwarven Work Boots",
          },
          ["FabledBrew (Hops)"] = {
            aliases = {
              "Fabled Blackout Brew",
            },
            ids = {
            },
            item = "Fabled Blackout Brew",
          },
          Heart = {
            aliases = {
              "Fabled Ghoul's Heart",
            },
            ids = {
            },
            item = "Fabled Ghoul's Heart",
          },
          ["Ring (Pestilence Bolt)"] = {
            aliases = {
              "Fabled Jagged Band",
            },
            ids = {
            },
            item = "Fabled Jagged Band",
          },
          Rune = {
            aliases = {
              "Rapid Focus Rune: Destroyer's Volley",
              "Rapid Focus Glyph: Destroyer's Volley",
            },
            ids = {
            },
            item = "Rapid Focus Rune: Destroyer's Volley",
          },
          ["Shield for Radix"] = {
            aliases = {
              "Ancient Shield of Corrupted Tranquility",
            },
            ids = {
              150402,
            },
            item = "Ancient Shield of Corrupted Tranquility",
          },
        },
        Cleric = {
          ["Cap (Scribes Endurance)"] = {
            aliases = {
              "Fabled Savant's Cap",
            },
            ids = {
            },
            item = "Fabled Savant's Cap",
          },
          ["FabledBrew (Hops)"] = {
            aliases = {
              "Fabled Blackout Brew",
            },
            ids = {
            },
            item = "Fabled Blackout Brew",
          },
          Globe = {
            aliases = {
              "Fabled Globe of Mist",
            },
            ids = {
            },
            item = "Fabled Globe of Mist",
          },
          ["Hammer (DA)"] = {
            aliases = {
              "Fabled Torklar's Battle Hammer",
            },
            ids = {
            },
            item = "Fabled Torklar's Battle Hammer",
          },
          Rune = {
            aliases = {
              "Enduring Focus Rune: Pious Elixir of Divinity",
              "Enduring Focus Glyph: Pious Elixir of Divinity",
            },
            ids = {
            },
            item = "Enduring Focus Rune: Pious Elixir of Divinity",
          },
          ["Shield for Radix"] = {
            aliases = {
              "Ancient Shield of Corrupted Tranquility",
            },
            ids = {
              150402,
            },
            item = "Ancient Shield of Corrupted Tranquility",
          },
        },
        Druid = {
          ["Cap (Scribes Endurance)"] = {
            aliases = {
              "Fabled Savant's Cap",
            },
            ids = {
            },
            item = "Fabled Savant's Cap",
          },
          ["FabledBrew (Hops)"] = {
            aliases = {
              "Fabled Blackout Brew",
            },
            ids = {
            },
            item = "Fabled Blackout Brew",
          },
          Globe = {
            aliases = {
              "Fabled Globe of Mist",
            },
            ids = {
            },
            item = "Fabled Globe of Mist",
          },
          Rune = {
            aliases = {
              "Destructive Focus Rune: Wasp Swarm",
              "Destructive Focus Glyph: Wasp Swarm",
            },
            ids = {
            },
            item = "Destructive Focus Rune: Wasp Swarm",
          },
          ["Shield for Radix"] = {
            aliases = {
              "Ancient Shield of Corrupted Tranquility",
            },
            ids = {
              150402,
            },
            item = "Ancient Shield of Corrupted Tranquility",
          },
        },
        Enchanter = {
          ["Cap (Scribes Endurance)"] = {
            aliases = {
              "Fabled Savant's Cap",
            },
            ids = {
            },
            item = "Fabled Savant's Cap",
          },
          ["FabledBrew (Hops)"] = {
            aliases = {
              "Fabled Blackout Brew",
            },
            ids = {
            },
            item = "Fabled Blackout Brew",
          },
          Globe = {
            aliases = {
              "Fabled Globe of Mist",
            },
            ids = {
            },
            item = "Fabled Globe of Mist",
          },
          Rune = {
            aliases = {
              "Destructive Focus Rune: Mind Shatter",
              "Destructive Focus Glyph: Mind Shatter",
            },
            ids = {
            },
            item = "Destructive Focus Rune: Mind Shatter",
          },
          ["Shield for Radix"] = {
            aliases = {
              "Ancient Shield of Corrupted Tranquility",
            },
            ids = {
              150402,
            },
            item = "Ancient Shield of Corrupted Tranquility",
          },
        },
        Magician = {
          ["Cap (Scribes Endurance)"] = {
            aliases = {
              "Fabled Savant's Cap",
            },
            ids = {
            },
            item = "Fabled Savant's Cap",
          },
          ["FabledBrew (Hops)"] = {
            aliases = {
              "Fabled Blackout Brew",
            },
            ids = {
            },
            item = "Fabled Blackout Brew",
          },
          Globe = {
            aliases = {
              "Fabled Globe of Mist",
            },
            ids = {
            },
            item = "Fabled Globe of Mist",
          },
          Rune = {
            aliases = {
              "Destructive Focus Rune: Spear of Ro",
              "Destructive Focus Glyph: Spear of Ro",
            },
            ids = {
            },
            item = "Destructive Focus Rune: Spear of Ro",
          },
          ["Shield for Radix"] = {
            aliases = {
              "Ancient Shield of Corrupted Tranquility",
            },
            ids = {
              150402,
            },
            item = "Ancient Shield of Corrupted Tranquility",
          },
        },
        Monk = {
          ["Boots (Potent Prowess)"] = {
            aliases = {
              "Fabled Dwarven Work Boots",
            },
            ids = {
            },
            item = "Fabled Dwarven Work Boots",
          },
          ["FabledBrew (Hops)"] = {
            aliases = {
              "Fabled Blackout Brew",
            },
            ids = {
            },
            item = "Fabled Blackout Brew",
          },
          Heart = {
            aliases = {
              "Fabled Ghoul's Heart",
            },
            ids = {
            },
            item = "Fabled Ghoul's Heart",
          },
          ["Ring (Pestilence Bolt)"] = {
            aliases = {
              "Fabled Jagged Band",
            },
            ids = {
            },
            item = "Fabled Jagged Band",
          },
          Rune = {
            aliases = {
              "Rapid Focus Rune: Dragon Fang",
              "Rapid Focus Glyph: Dragon Fang",
            },
            ids = {
            },
            item = "Rapid Focus Rune: Dragon Fang",
          },
          ["Shield for Radix"] = {
            aliases = {
              "Ancient Shield of Corrupted Tranquility",
            },
            ids = {
              150402,
            },
            item = "Ancient Shield of Corrupted Tranquility",
          },
        },
        Necromancer = {
          ["Cap (Scribes Endurance)"] = {
            aliases = {
              "Fabled Savant's Cap",
            },
            ids = {
            },
            item = "Fabled Savant's Cap",
          },
          ["FabledBrew (Hops)"] = {
            aliases = {
              "Fabled Blackout Brew",
            },
            ids = {
            },
            item = "Fabled Blackout Brew",
          },
          Globe = {
            aliases = {
              "Fabled Globe of Mist",
            },
            ids = {
            },
            item = "Fabled Globe of Mist",
          },
          Rune = {
            aliases = {
              "Destructive Focus Rune: Chaos Plague",
              "Destructive Focus Glyph: Chaos Plague",
            },
            ids = {
            },
            item = "Destructive Focus Rune: Chaos Plague",
          },
          ["Shield for Radix"] = {
            aliases = {
              "Ancient Shield of Corrupted Tranquility",
            },
            ids = {
              150402,
            },
            item = "Ancient Shield of Corrupted Tranquility",
          },
        },
        Paladin = {
          ["FabledBrew (Hops)"] = {
            aliases = {
              "Fabled Blackout Brew",
            },
            ids = {
            },
            item = "Fabled Blackout Brew",
          },
          Globe = {
            aliases = {
              "Fabled Globe of Mist",
            },
            ids = {
            },
            item = "Fabled Globe of Mist",
          },
          ["Hammer (DA)"] = {
            aliases = {
              "Fabled Torklar's Battle Hammer",
            },
            ids = {
            },
            item = "Fabled Torklar's Battle Hammer",
          },
          ["Mantle (Unwavering Defense)"] = {
            aliases = {
              "Fabled Bloodstained Mantle",
            },
            ids = {
            },
            item = "Fabled Bloodstained Mantle",
          },
          Ornament = {
            aliases = {
              "Fabled Knight's Devotion Ornament",
            },
            ids = {
            },
            item = "Fabled Knight's Devotion Ornament",
          },
          ["Ring (Pestilence Bolt)"] = {
            aliases = {
              "Fabled Jagged Band",
            },
            ids = {
            },
            item = "Fabled Jagged Band",
          },
          Rune = {
            aliases = {
              "Mending Focus Rune: Light of Piety",
              "Mending Focus Glyph: Light of Piety",
            },
            ids = {
            },
            item = "Mending Focus Rune: Light of Piety",
          },
          ["Shield for Radix"] = {
            aliases = {
              "Ancient Shield of Corrupted Tranquility",
            },
            ids = {
              150402,
            },
            item = "Ancient Shield of Corrupted Tranquility",
          },
        },
        Ranger = {
          Arrow = {
            aliases = {
              "Fabled Arrow",
            },
            ids = {
              81683,
            },
            item = "Fabled Arrow",
          },
          ["Boots (Potent Prowess)"] = {
            aliases = {
              "Fabled Dwarven Work Boots",
            },
            ids = {
            },
            item = "Fabled Dwarven Work Boots",
          },
          ["FabledBrew (Hops)"] = {
            aliases = {
              "Fabled Blackout Brew",
            },
            ids = {
            },
            item = "Fabled Blackout Brew",
          },
          Globe = {
            aliases = {
              "Fabled Globe of Mist",
            },
            ids = {
            },
            item = "Fabled Globe of Mist",
          },
          ["Ring (Pestilence Bolt)"] = {
            aliases = {
              "Fabled Jagged Band",
            },
            ids = {
            },
            item = "Fabled Jagged Band",
          },
          Rune = {
            aliases = {
              "Destructive Focus Rune: Scorched Earth",
              "Destructive Focus Glyph: Scorched Earth",
            },
            ids = {
            },
            item = "Destructive Focus Rune: Scorched Earth",
          },
          ["Shield for Radix"] = {
            aliases = {
              "Ancient Shield of Corrupted Tranquility",
            },
            ids = {
              150402,
            },
            item = "Ancient Shield of Corrupted Tranquility",
          },
        },
        Rogue = {
          ["Boots (Potent Prowess)"] = {
            aliases = {
              "Fabled Dwarven Work Boots",
            },
            ids = {
            },
            item = "Fabled Dwarven Work Boots",
          },
          ["FabledBrew (Hops)"] = {
            aliases = {
              "Fabled Blackout Brew",
            },
            ids = {
            },
            item = "Fabled Blackout Brew",
          },
          Heart = {
            aliases = {
              "Fabled Ghoul's Heart",
            },
            ids = {
            },
            item = "Fabled Ghoul's Heart",
          },
          ["Ring (Pestilence Bolt)"] = {
            aliases = {
              "Fabled Jagged Band",
            },
            ids = {
            },
            item = "Fabled Jagged Band",
          },
          Rune = {
            aliases = {
              "Rapid Focus Rune: Assault",
              "Rapid Focus Glyph: Assault",
            },
            ids = {
            },
            item = "Rapid Focus Rune: Assault",
          },
          ["Shield for Radix"] = {
            aliases = {
              "Ancient Shield of Corrupted Tranquility",
            },
            ids = {
              150402,
            },
            item = "Ancient Shield of Corrupted Tranquility",
          },
        },
        ["Shadow Knight"] = {
          ["FabledBrew (Hops)"] = {
            aliases = {
              "Fabled Blackout Brew",
            },
            ids = {
            },
            item = "Fabled Blackout Brew",
          },
          Globe = {
            aliases = {
              "Fabled Globe of Mist",
            },
            ids = {
            },
            item = "Fabled Globe of Mist",
          },
          ["Hammer (DA)"] = {
            aliases = {
              "Fabled Torklar's Battle Hammer",
            },
            ids = {
            },
            item = "Fabled Torklar's Battle Hammer",
          },
          ["Mantle (Unwavering Defense)"] = {
            aliases = {
              "Fabled Bloodstained Mantle",
            },
            ids = {
            },
            item = "Fabled Bloodstained Mantle",
          },
          Ornament = {
            aliases = {
              "Fabled Knight's Devotion Ornament",
            },
            ids = {
            },
            item = "Fabled Knight's Devotion Ornament",
          },
          ["Ring (Pestilence Bolt)"] = {
            aliases = {
              "Fabled Jagged Band",
            },
            ids = {
            },
            item = "Fabled Jagged Band",
          },
          Rune = {
            aliases = {
              "Destructive Focus Rune: Touch of the Devourer",
              "Destructive Focus Glyph: Touch of the Devourer",
            },
            ids = {
            },
            item = "Destructive Focus Rune: Touch of the Devourer",
          },
          ["Shield for Radix"] = {
            aliases = {
              "Ancient Shield of Corrupted Tranquility",
            },
            ids = {
              150402,
            },
            item = "Ancient Shield of Corrupted Tranquility",
          },
        },
        Shaman = {
          ["Cap (Scribes Endurance)"] = {
            aliases = {
              "Fabled Savant's Cap",
            },
            ids = {
            },
            item = "Fabled Savant's Cap",
          },
          ["FabledBrew (Hops)"] = {
            aliases = {
              "Fabled Blackout Brew",
            },
            ids = {
            },
            item = "Fabled Blackout Brew",
          },
          Globe = {
            aliases = {
              "Fabled Globe of Mist",
            },
            ids = {
            },
            item = "Fabled Globe of Mist",
          },
          Rune = {
            aliases = {
              "Destructive Focus Rune: Blood of Yoppa",
              "Destructive Focus Glyph: Blood of Yoppa",
            },
            ids = {
            },
            item = "Destructive Focus Rune: Blood of Yoppa",
          },
          ["Shield for Radix"] = {
            aliases = {
              "Ancient Shield of Corrupted Tranquility",
            },
            ids = {
              150402,
            },
            item = "Ancient Shield of Corrupted Tranquility",
          },
        },
        Warrior = {
          ["FabledBrew (Hops)"] = {
            aliases = {
              "Fabled Blackout Brew",
            },
            ids = {
            },
            item = "Fabled Blackout Brew",
          },
          Heart = {
            aliases = {
              "Fabled Ghoul's Heart",
            },
            ids = {
            },
            item = "Fabled Ghoul's Heart",
          },
          ["Mantle (Unwavering Defense)"] = {
            aliases = {
              "Fabled Bloodstained Mantle",
            },
            ids = {
            },
            item = "Fabled Bloodstained Mantle",
          },
          ["Ring (Pestilence Bolt)"] = {
            aliases = {
              "Fabled Jagged Band",
            },
            ids = {
            },
            item = "Fabled Jagged Band",
          },
          Rune = {
            aliases = {
              "Rapid Focus Rune: Mock and Flaunt",
              "Rapid Focus Glyph: Mock and Flaunt",
            },
            ids = {
            },
            item = "Rapid Focus Rune: Mock and Flaunt",
          },
          ["Shield for Radix"] = {
            aliases = {
              "Ancient Shield of Corrupted Tranquility",
            },
            ids = {
              150402,
            },
            item = "Ancient Shield of Corrupted Tranquility",
          },
        },
        Wizard = {
          ["Cap (Scribes Endurance)"] = {
            aliases = {
              "Fabled Savant's Cap",
            },
            ids = {
            },
            item = "Fabled Savant's Cap",
          },
          ["FabledBrew (Hops)"] = {
            aliases = {
              "Fabled Blackout Brew",
            },
            ids = {
            },
            item = "Fabled Blackout Brew",
          },
          Globe = {
            aliases = {
              "Fabled Globe of Mist",
            },
            ids = {
            },
            item = "Fabled Globe of Mist",
          },
          Rune = {
            aliases = {
              "Destructive Focus Rune: Ether Flame",
              "Destructive Focus Glyph: Ether Flame",
            },
            ids = {
            },
            item = "Destructive Focus Rune: Ether Flame",
          },
          ["Shield for Radix"] = {
            aliases = {
              "Ancient Shield of Corrupted Tranquility",
            },
            ids = {
              150402,
            },
            item = "Ancient Shield of Corrupted Tranquility",
          },
        },
      },
      group = "Raid Best In Slot",
      id = "fuku",
      name = "FUKU",
      show_base = {
      },
      template = {
        ["Bracelet (Boon of the Ancients)"] = {
          aliases = {
            "Fabled Ivory Bracelet",
          },
          ids = {
          },
          item = "Fabled Ivory Bracelet",
        },
      },
      visible = {
      },
    },
    fungal = {
      categories = {
        {
          name = "Original Aug",
          slots = {
            "Base Corrosive Slime of Suffering (Poison)",
            "Base Frigid Slime of Suffering (Cold)",
            "Base Necrotic Slime of Suffering (Disease)",
            "Base Ruinous Slime of Suffering (Magic)",
            "Base Searing Slime of Suffering (Fire)",
            "Base Noxious Bloom of Brittle Bones (Parry/Block)",
            "Base Noxious Bloom of Corporeal Calamity (Increase Duration)",
            "Base Noxious Bloom of Ebbing Exertion (Double Attack)",
            "Base Noxious Bloom of Feeble Finesse (Crit)",
            "Base Noxious Bloom of Languid Limbs (Dodge)",
            "Base Noxious Bloom of Meager Mettle (Healing)",
            "Base Noxious Bloom of Wavering Willpower (Reduce Mana Cost)",
          },
        },
        {
          name = "Fungal (Mimicry)",
          slots = {
            "1st Corrosive Fungus of Suffering (Poison)",
            "1st Frigid Fungus of Suffering (Cold)",
            "1st Necrotic Fungus of Suffering (Disease)",
            "1st Ruinous Fungus of Suffering (Magic)",
            "1st Searing Fungus of Suffering (Fire)",
            "1st Fungal Bloom of Brittle Bones (Parry/Block)",
            "1st Fungal Bloom of Corporeal Calamity (Increase Duration)",
            "1st Fungal Bloom of Ebbing Exertion (Double Attack)",
            "1st Fungal Bloom of Feeble Finesse (Crit)",
            "1st Fungal Bloom of Languid Limbs (Dodge)",
            "1st Fungal Bloom of Meager Mettle (Healing)",
            "1st Fungal Bloom of Wavering Willpower (Reduce Mana Cost)",
          },
        },
        {
          name = "Fungal (Crud 1)",
          slots = {
            "2nd Corrosive Fungus of Suffering (Poison)",
            "2nd Frigid Fungus of Suffering (Cold)",
            "2nd Necrotic Fungus of Suffering (Disease)",
            "2nd Ruinous Fungus of Suffering (Magic)",
            "2nd Searing Fungus of Suffering (Fire)",
            "2nd Fungal Bloom of Brittle Bones (Parry/Block)",
            "2nd Fungal Bloom of Corporeal Calamity (Increase Duration)",
            "2nd Fungal Bloom of Ebbing Exertion (Double Attack)",
            "2nd Fungal Bloom of Feeble Finesse (Crit)",
            "2nd Fungal Bloom of Languid Limbs (Dodge)",
            "2nd Fungal Bloom of Meager Mettle (Healing)",
            "2nd Fungal Bloom of Wavering Willpower (Reduce Mana Cost)",
          },
        },
        {
          name = "Fungal (Crud 2)",
          slots = {
            "3rd Corrosive Fungus of Suffering (Poison)",
            "3rd Frigid Fungus of Suffering (Cold)",
            "3rd Necrotic Fungus of Suffering (Disease)",
            "3rd Ruinous Fungus of Suffering (Magic)",
            "2nd Searing Fungus of Suffering (Fire)",
            "3rd Fungal Bloom of Brittle Bones (Parry/Block)",
            "3rd Fungal Bloom of Corporeal Calamity (Increase Duration)",
            "3rd Fungal Bloom of Ebbing Exertion (Double Attack)",
            "3rd Fungal Bloom of Feeble Finesse (Crit)",
            "3rd Fungal Bloom of Languid Limbs (Dodge)",
            "3rd Fungal Bloom of Meager Mettle (Healing)",
            "3rd Fungal Bloom of Wavering Willpower (Reduce Mana Cost)",
          },
        },
        {
          name = "Fungal (Crud 3)",
          slots = {
            "4th Corrosive Fungus of Suffering (Poison)",
            "4th Frigid Fungus of Suffering (Cold)",
            "4th Necrotic Fungus of Suffering (Disease)",
            "4th Ruinous Fungus of Suffering (Magic)",
            "4th Searing Fungus of Suffering (Fire)",
            "4th Fungal Bloom of Brittle Bones (Parry/Block)",
            "4th Fungal Bloom of Corporeal Calamity (Increase Duration)",
            "4th Fungal Bloom of Ebbing Exertion (Double Attack)",
            "4th Fungal Bloom of Feeble Finesse (Crit)",
            "4th Fungal Bloom of Languid Limbs (Dodge)",
            "4th Fungal Bloom of Meager Mettle (Healing)",
            "4th Fungal Bloom of Wavering Willpower (Reduce Mana Cost)",
          },
        },
      },
      classes = {
      },
      group = "Raid Best In Slot",
      id = "fungal",
      name = "Fungal Aug",
      show_base = {
        ALL = 1,
      },
      template = {
        ["1st Corrosive Fungus of Suffering (Poison)"] = {
          aliases = {
            "Corrosive Fungus of Suffering - Tier I",
          },
          ids = {
            50091,
            50092,
            50093,
            50094,
          },
          item = "Corrosive Fungus of Suffering - Tier I",
        },
        ["1st Frigid Fungus of Suffering (Cold)"] = {
          aliases = {
            "Frigid Fungus of Suffering - Tier I",
          },
          ids = {
            50087,
            50088,
            50089,
            50090,
          },
          item = "Frigid Fungus of Suffering - Tier I",
        },
        ["1st Fungal Bloom of Brittle Bones (Parry/Block)"] = {
          aliases = {
            "Fungal Bloom of Brittle Bones - Tier I",
          },
          ids = {
            50055,
            50056,
            50057,
            50058,
          },
          item = "Fungal Bloom of Brittle Bones - Tier I",
        },
        ["1st Fungal Bloom of Corporeal Calamity (Increase Duration)"] = {
          aliases = {
            "Fungal Bloom of Corporeal Calamity - Tier I",
          },
          ids = {
            50079,
            50080,
            50081,
            50082,
          },
          item = "Fungal Bloom of Corporeal Calamity - Tier I",
        },
        ["1st Fungal Bloom of Ebbing Exertion (Double Attack)"] = {
          aliases = {
            "Fungal Bloom of Ebbing Exertion - Tier I",
          },
          ids = {
            50063,
            50064,
            50065,
            50066,
          },
          item = "Fungal Bloom of Ebbing Exertion - Tier I",
        },
        ["1st Fungal Bloom of Feeble Finesse (Crit)"] = {
          aliases = {
            "Fungal Bloom of Feeble Finesse - Tier I",
          },
          ids = {
            50067,
            50068,
            50069,
            50070,
          },
          item = "Fungal Bloom of Feeble Finesse - Tier I",
        },
        ["1st Fungal Bloom of Languid Limbs (Dodge)"] = {
          aliases = {
            "Fungal Bloom of Languid Limbs - Tier I",
          },
          ids = {
            50059,
            50060,
            50061,
            50062,
          },
          item = "Fungal Bloom of Languid Limbs - Tier I",
        },
        ["1st Fungal Bloom of Meager Mettle (Healing)"] = {
          aliases = {
            "Fungal Bloom of Meager Mettle - Tier I",
          },
          ids = {
            50071,
            50072,
            50073,
            50074,
          },
          item = "Fungal Bloom of Meager Mettle - Tier I",
        },
        ["1st Fungal Bloom of Wavering Willpower (Reduce Mana Cost)"] = {
          aliases = {
            "Fungal Bloom of Wavering Willpower - Tier I",
          },
          ids = {
            50075,
            50076,
            50077,
            50078,
          },
          item = "Fungal Bloom of Wavering Willpower - Tier I",
        },
        ["1st Necrotic Fungus of Suffering (Disease)"] = {
          aliases = {
            "Necrotic Fungus of Suffering - Tier I",
          },
          ids = {
            50095,
            50096,
            50097,
            50098,
          },
          item = "Necrotic Fungus of Suffering - Tier I",
        },
        ["1st Ruinous Fungus of Suffering (Magic)"] = {
          aliases = {
            "Ruinous Fungus of Suffering - Tier I",
          },
          ids = {
            50099,
            50100,
            50101,
            50102,
          },
          item = "Ruinous Fungus of Suffering - Tier I",
        },
        ["1st Searing Fungus of Suffering (Fire)"] = {
          aliases = {
            "Searing Fungus of Suffering - Tier I",
          },
          ids = {
            50083,
            50084,
            50085,
            50086,
          },
          item = "Searing Fungus of Suffering - Tier I",
        },
        ["2nd Corrosive Fungus of Suffering (Poison)"] = {
          aliases = {
            "Corrosive Fungus of Suffering - Tier II",
          },
          ids = {
            50092,
            50093,
            50094,
          },
          item = "Corrosive Fungus of Suffering - Tier II",
        },
        ["2nd Frigid Fungus of Suffering (Cold)"] = {
          aliases = {
            "Frigid Fungus of Suffering - Tier II",
          },
          ids = {
            50088,
            50089,
            50090,
          },
          item = "Frigid Fungus of Suffering - Tier II",
        },
        ["2nd Fungal Bloom of Brittle Bones (Parry/Block)"] = {
          aliases = {
            "Fungal Bloom of Brittle Bones - Tier II",
          },
          ids = {
            50056,
            50057,
            50058,
          },
          item = "Fungal Bloom of Brittle Bones - Tier II",
        },
        ["2nd Fungal Bloom of Corporeal Calamity (Increase Duration)"] = {
          aliases = {
            "Fungal Bloom of Corporeal Calamity - Tier II",
          },
          ids = {
            50080,
            50081,
            50082,
          },
          item = "Fungal Bloom of Corporeal Calamity - Tier II",
        },
        ["2nd Fungal Bloom of Ebbing Exertion (Double Attack)"] = {
          aliases = {
            "Fungal Bloom of Ebbing Exertion - Tier II",
          },
          ids = {
            50064,
            50065,
            50066,
          },
          item = "Fungal Bloom of Ebbing Exertion - Tier II",
        },
        ["2nd Fungal Bloom of Feeble Finesse (Crit)"] = {
          aliases = {
            "Fungal Bloom of Feeble Finesse - Tier II",
          },
          ids = {
            50068,
            50069,
            50070,
          },
          item = "Fungal Bloom of Feeble Finesse - Tier II",
        },
        ["2nd Fungal Bloom of Languid Limbs (Dodge)"] = {
          aliases = {
            "Fungal Bloom of Languid Limbs - Tier II",
          },
          ids = {
            50060,
            50061,
            50062,
          },
          item = "Fungal Bloom of Languid Limbs - Tier II",
        },
        ["2nd Fungal Bloom of Meager Mettle (Healing)"] = {
          aliases = {
            "Fungal Bloom of Meager Mettle - Tier II",
          },
          ids = {
            50072,
            50073,
            50074,
          },
          item = "Fungal Bloom of Meager Mettle - Tier II",
        },
        ["2nd Fungal Bloom of Wavering Willpower (Reduce Mana Cost)"] = {
          aliases = {
            "Fungal Bloom of Wavering Willpower - Tier II",
          },
          ids = {
            50076,
            50077,
            50078,
          },
          item = "Fungal Bloom of Wavering Willpower - Tier II",
        },
        ["2nd Necrotic Fungus of Suffering (Disease)"] = {
          aliases = {
            "Necrotic Fungus of Suffering - Tier II",
          },
          ids = {
            50096,
            50097,
            50098,
          },
          item = "Necrotic Fungus of Suffering - Tier II",
        },
        ["2nd Ruinous Fungus of Suffering (Magic)"] = {
          aliases = {
            "Ruinous Fungus of Suffering - Tier II",
          },
          ids = {
            50100,
            50101,
            50102,
          },
          item = "Ruinous Fungus of Suffering - Tier II",
        },
        ["2nd Searing Fungus of Suffering (Fire)"] = {
          aliases = {
            "Searing Fungus of Suffering - Tier II",
          },
          ids = {
            50084,
            50085,
            50086,
          },
          item = "Searing Fungus of Suffering - Tier II",
        },
        ["3rd Corrosive Fungus of Suffering (Poison)"] = {
          aliases = {
            "Corrosive Fungus of Suffering - Tier III",
          },
          ids = {
            50093,
            50094,
          },
          item = "Corrosive Fungus of Suffering - Tier III",
        },
        ["3rd Frigid Fungus of Suffering (Cold)"] = {
          aliases = {
            "Frigid Fungus of Suffering - Tier III",
          },
          ids = {
            50089,
            50090,
          },
          item = "Frigid Fungus of Suffering - Tier III",
        },
        ["3rd Fungal Bloom of Brittle Bones (Parry/Block)"] = {
          aliases = {
            "Fungal Bloom of Brittle Bones - Tier III",
          },
          ids = {
            50057,
            50058,
          },
          item = "Fungal Bloom of Brittle Bones - Tier III",
        },
        ["3rd Fungal Bloom of Corporeal Calamity (Increase Duration)"] = {
          aliases = {
            "Fungal Bloom of Corporeal Calamity - Tier III",
          },
          ids = {
            50081,
            50082,
          },
          item = "Fungal Bloom of Corporeal Calamity - Tier III",
        },
        ["3rd Fungal Bloom of Ebbing Exertion (Double Attack)"] = {
          aliases = {
            "Fungal Bloom of Ebbing Exertion - Tier III",
          },
          ids = {
            50065,
            50066,
          },
          item = "Fungal Bloom of Ebbing Exertion - Tier III",
        },
        ["3rd Fungal Bloom of Feeble Finesse (Crit)"] = {
          aliases = {
            "Fungal Bloom of Feeble Finesse - Tier III",
          },
          ids = {
            50069,
            50070,
          },
          item = "Fungal Bloom of Feeble Finesse - Tier III",
        },
        ["3rd Fungal Bloom of Languid Limbs (Dodge)"] = {
          aliases = {
            "Fungal Bloom of Languid Limbs - Tier III",
          },
          ids = {
            50061,
            50062,
          },
          item = "Fungal Bloom of Languid Limbs - Tier III",
        },
        ["3rd Fungal Bloom of Meager Mettle (Healing)"] = {
          aliases = {
            "Fungal Bloom of Meager Mettle - Tier III",
          },
          ids = {
            50073,
            50074,
          },
          item = "Fungal Bloom of Meager Mettle - Tier III",
        },
        ["3rd Fungal Bloom of Wavering Willpower (Reduce Mana Cost)"] = {
          aliases = {
            "Fungal Bloom of Wavering Willpower - Tier III",
          },
          ids = {
            50077,
            50078,
          },
          item = "Fungal Bloom of Wavering Willpower - Tier III",
        },
        ["3rd Necrotic Fungus of Suffering (Disease)"] = {
          aliases = {
            "Necrotic Fungus of Suffering - Tier III",
          },
          ids = {
            50097,
            50098,
          },
          item = "Necrotic Fungus of Suffering - Tier III",
        },
        ["3rd Ruinous Fungus of Suffering (Magic)"] = {
          aliases = {
            "Ruinous Fungus of Suffering - Tier III",
          },
          ids = {
            50101,
            50102,
          },
          item = "Ruinous Fungus of Suffering - Tier III",
        },
        ["3rd Searing Fungus of Suffering (Fire)"] = {
          aliases = {
            "Searing Fungus of Suffering - Tier III",
          },
          ids = {
            50085,
            50086,
          },
          item = "Searing Fungus of Suffering - Tier III",
        },
        ["4th Corrosive Fungus of Suffering (Poison)"] = {
          aliases = {
            "Corrosive Fungus of Suffering - Final",
          },
          ids = {
            50094,
          },
          item = "Corrosive Fungus of Suffering - Final",
        },
        ["4th Frigid Fungus of Suffering (Cold)"] = {
          aliases = {
            "Frigid Fungus of Suffering - Final",
          },
          ids = {
            50090,
          },
          item = "Frigid Fungus of Suffering - Final",
        },
        ["4th Fungal Bloom of Brittle Bones (Parry/Block)"] = {
          aliases = {
            "Fungal Bloom of Brittle Bones - Final",
          },
          ids = {
            50058,
          },
          item = "Fungal Bloom of Brittle Bones - Final",
        },
        ["4th Fungal Bloom of Corporeal Calamity (Increase Duration)"] = {
          aliases = {
            "Fungal Bloom of Corporeal Calamity - Final",
          },
          ids = {
            50082,
          },
          item = "Fungal Bloom of Corporeal Calamity - Final",
        },
        ["4th Fungal Bloom of Ebbing Exertion (Double Attack)"] = {
          aliases = {
            "Fungal Bloom of Ebbing Exertion - Final",
          },
          ids = {
            50066,
          },
          item = "Fungal Bloom of Ebbing Exertion - Final",
        },
        ["4th Fungal Bloom of Feeble Finesse (Crit)"] = {
          aliases = {
            "Fungal Bloom of Feeble Finesse - Final",
          },
          ids = {
            50070,
          },
          item = "Fungal Bloom of Feeble Finesse - Final",
        },
        ["4th Fungal Bloom of Languid Limbs (Dodge)"] = {
          aliases = {
            "Fungal Bloom of Languid Limbs - Final",
          },
          ids = {
            50062,
          },
          item = "Fungal Bloom of Languid Limbs - Final",
        },
        ["4th Fungal Bloom of Meager Mettle (Healing)"] = {
          aliases = {
            "Fungal Bloom of Meager Mettle - Final",
          },
          ids = {
            50074,
          },
          item = "Fungal Bloom of Meager Mettle - Final",
        },
        ["4th Fungal Bloom of Wavering Willpower (Reduce Mana Cost)"] = {
          aliases = {
            "Fungal Bloom of Wavering Willpower - Final",
          },
          ids = {
            50078,
          },
          item = "Fungal Bloom of Wavering Willpower - Final",
        },
        ["4th Necrotic Fungus of Suffering (Disease)"] = {
          aliases = {
            "Necrotic Fungus of Suffering - Final",
          },
          ids = {
            50098,
          },
          item = "Necrotic Fungus of Suffering - Final",
        },
        ["4th Ruinous Fungus of Suffering (Magic)"] = {
          aliases = {
            "Ruinous Fungus of Suffering - Final",
          },
          ids = {
            50102,
          },
          item = "Ruinous Fungus of Suffering - Final",
        },
        ["4th Searing Fungus of Suffering (Fire)"] = {
          aliases = {
            "Searing Fungus of Suffering - Final",
          },
          ids = {
            50086,
          },
          item = "Searing Fungus of Suffering - Final",
        },
        ["Base Corrosive Slime of Suffering (Poison)"] = {
          aliases = {
            "Corrosive Slime of Suffering",
          },
          ids = {
            39077,
          },
          item = "Corrosive Slime of Suffering",
        },
        ["Base Frigid Slime of Suffering (Cold)"] = {
          aliases = {
            "Frigid Slime of Suffering",
          },
          ids = {
            39076,
          },
          item = "Frigid Slime of Suffering",
        },
        ["Base Necrotic Slime of Suffering (Disease)"] = {
          aliases = {
            "Necrotic Slime of Suffering",
          },
          ids = {
            39078,
          },
          item = "Necrotic Slime of Suffering",
        },
        ["Base Noxious Bloom of Brittle Bones (Parry/Block)"] = {
          aliases = {
            "Noxious Bloom of Brittle Bones",
          },
          ids = {
            39061,
          },
          item = "Noxious Bloom of Brittle Bones",
        },
        ["Base Noxious Bloom of Corporeal Calamity (Increase Duration)"] = {
          aliases = {
            "Noxious Bloom of Corporeal Calamity",
          },
          ids = {
            39068,
          },
          item = "Noxious Bloom of Corporeal Calamity",
        },
        ["Base Noxious Bloom of Ebbing Exertion (Double Attack)"] = {
          aliases = {
            "Noxious Bloom of Ebbing Exertion",
          },
          ids = {
            39063,
          },
          item = "Noxious Bloom of Ebbing Exertion",
        },
        ["Base Noxious Bloom of Feeble Finesse (Crit)"] = {
          aliases = {
            "Noxious Bloom of Feeble Finesse",
          },
          ids = {
            39064,
          },
          item = "Noxious Bloom of Feeble Finesse",
        },
        ["Base Noxious Bloom of Languid Limbs (Dodge)"] = {
          aliases = {
            "Noxious Bloom of Languid Limbs",
          },
          ids = {
            39062,
          },
          item = "Noxious Bloom of Languid Limbs",
        },
        ["Base Noxious Bloom of Meager Mettle (Healing)"] = {
          aliases = {
            "Noxious Bloom of Meager Mettle",
          },
          ids = {
            39065,
          },
          item = "Noxious Bloom of Meager Mettle",
        },
        ["Base Noxious Bloom of Wavering Willpower (Reduce Mana Cost)"] = {
          aliases = {
            "Noxious Bloom of Wavering Willpower",
          },
          ids = {
            39066,
          },
          item = "Noxious Bloom of Wavering Willpower",
        },
        ["Base Ruinous Slime of Suffering (Magic)"] = {
          aliases = {
            "Ruinous Slime of Suffering",
          },
          ids = {
            39079,
          },
          item = "Ruinous Slime of Suffering",
        },
        ["Base Searing Slime of Suffering (Fire)"] = {
          aliases = {
            "Searing Slime of Suffering",
          },
          ids = {
            39075,
          },
          item = "Searing Slime of Suffering",
        },
      },
      visible = {
      },
    },
    hcitems = {
      categories = {
        {
          name = "Arcane",
          slots = {
            "ArcaneDestruction",
            "ArcaneMending",
            "ArcanePersistence",
            "ArcaneSuffering",
          },
        },
        {
          name = "Incarnate",
          slots = {
            "IncarnateCleaving",
            "IncarnateDeflection",
            "IncarnateEvasion",
            "IncarnateFerocity",
          },
        },
        {
          name = "Other",
          slots = {
            "TranquilSoul",
            "Tongue",
            "FrozenOre",
            "Shattered Gnoll Slayer",
            "Tarnished Skeleton Key",
            "Graverobber's Icon",
            "Battered Smuggler's Barrel",
          },
        },
        {
          name = "Clickies",
          slots = {
            "EyeMight",
            "EyeComprehension",
            "Crystalized",
            "Minion's",
          },
        },
      },
      classes = {
        Bard = {
          BellikosClaws = {
            aliases = {
              "Splintered Bellikos Claws",
            },
            ids = {
            },
            item = "Splintered Bellikos Claws",
          },
          EyeComprehension = {
            aliases = {
              "Eye of Comprehension",
            },
            ids = {
            },
            item = "Eye of Comprehension",
          },
          EyeMight = {
            aliases = {
              "Eye of Might",
            },
            ids = {
            },
            item = "Eye of Might",
          },
          FrozenOre = {
            aliases = {
              "Frozen Ore",
            },
            ids = {
              150215,
            },
            item = "Frozen Ore",
          },
          ["Tarnished Skeleton Key"] = {
            aliases = {
              "Tarnished Skeleton Key",
            },
            ids = {
            },
            item = "Tarnished Skeleton Key",
          },
        },
        Beastlord = {
          BellikosClaws = {
            aliases = {
              "Splintered Bellikos Claws",
            },
            ids = {
            },
            item = "Splintered Bellikos Claws",
          },
          EyeComprehension = {
            aliases = {
              "Eye of Comprehension",
            },
            ids = {
            },
            item = "Eye of Comprehension",
          },
          EyeMight = {
            aliases = {
              "Eye of Might",
            },
            ids = {
            },
            item = "Eye of Might",
          },
          FrozenOre = {
            aliases = {
              "Frozen Ore",
            },
            ids = {
              150215,
            },
            item = "Frozen Ore",
          },
          ["Minion's"] = {
            aliases = {
              "Minion's Memento",
            },
            ids = {
            },
            item = "Minion's Memento",
          },
        },
        Berserker = {
          ["Battered Smuggler's Barrel"] = {
            aliases = {
              "Battered Smuggler's Barrel",
            },
            ids = {
            },
            item = "Battered Smuggler's Barrel",
          },
          BellikosFang = {
            aliases = {
              "Fragmented Bellikos Fang",
            },
            ids = {
            },
            item = "Fragmented Bellikos Fang",
          },
          EyeMight = {
            aliases = {
              "Eye of Might",
            },
            ids = {
            },
            item = "Eye of Might",
          },
        },
        Cleric = {
          BellikosEye = {
            aliases = {
              "Obsidian Bellikos Eye",
            },
            ids = {
            },
            item = "Obsidian Bellikos Eye",
          },
          BellikosFang = {
            aliases = {
              "Fragmented Bellikos Fang",
            },
            ids = {
            },
            item = "Fragmented Bellikos Fang",
          },
          EyeComprehension = {
            aliases = {
              "Eye of Comprehension",
            },
            ids = {
            },
            item = "Eye of Comprehension",
          },
          ["Graverobber's Icon"] = {
            aliases = {
              "Graverobber's Icon",
            },
            ids = {
            },
            item = "Graverobber's Icon",
          },
        },
        Druid = {
          BellikosEye = {
            aliases = {
              "Obsidian Bellikos Eye",
            },
            ids = {
            },
            item = "Obsidian Bellikos Eye",
          },
          Crystalized = {
            aliases = {
              "Crystalized Soul Gem",
            },
            ids = {
            },
            item = "Crystalized Soul Gem",
          },
          EyeComprehension = {
            aliases = {
              "Eye of Comprehension",
            },
            ids = {
            },
            item = "Eye of Comprehension",
          },
          ["Minion's"] = {
            aliases = {
              "Minion's Memento",
            },
            ids = {
            },
            item = "Minion's Memento",
          },
          ["Shattered Gnoll Slayer"] = {
            aliases = {
              "Shattered Gnoll Slayer",
            },
            ids = {
            },
            item = "Shattered Gnoll Slayer",
          },
        },
        Enchanter = {
          BellikosEye = {
            aliases = {
              "Obsidian Bellikos Eye",
            },
            ids = {
            },
            item = "Obsidian Bellikos Eye",
          },
          Crystalized = {
            aliases = {
              "Crystalized Soul Gem",
            },
            ids = {
            },
            item = "Crystalized Soul Gem",
          },
          EyeComprehension = {
            aliases = {
              "Eye of Comprehension",
            },
            ids = {
            },
            item = "Eye of Comprehension",
          },
          ["Minion's"] = {
            aliases = {
              "Minion's Memento",
            },
            ids = {
            },
            item = "Minion's Memento",
          },
          ["Tarnished Skeleton Key"] = {
            aliases = {
              "Tarnished Skeleton Key",
            },
            ids = {
            },
            item = "Tarnished Skeleton Key",
          },
        },
        Magician = {
          BellikosEye = {
            aliases = {
              "Obsidian Bellikos Eye",
            },
            ids = {
            },
            item = "Obsidian Bellikos Eye",
          },
          EyeComprehension = {
            aliases = {
              "Eye of Comprehension",
            },
            ids = {
            },
            item = "Eye of Comprehension",
          },
          ["Minion's"] = {
            aliases = {
              "Minion's Memento",
            },
            ids = {
            },
            item = "Minion's Memento",
          },
        },
        Monk = {
          BellikosClaws = {
            aliases = {
              "Splintered Bellikos Claws",
            },
            ids = {
            },
            item = "Splintered Bellikos Claws",
          },
          BellikosFang = {
            aliases = {
              "Fragmented Bellikos Fang",
            },
            ids = {
            },
            item = "Fragmented Bellikos Fang",
          },
          EyeMight = {
            aliases = {
              "Eye of Might",
            },
            ids = {
            },
            item = "Eye of Might",
          },
          FrozenOre = {
            aliases = {
              "Frozen Ore",
            },
            ids = {
              150215,
            },
            item = "Frozen Ore",
          },
        },
        Necromancer = {
          BellikosEye = {
            aliases = {
              "Obsidian Bellikos Eye",
            },
            ids = {
            },
            item = "Obsidian Bellikos Eye",
          },
          EyeComprehension = {
            aliases = {
              "Eye of Comprehension",
            },
            ids = {
            },
            item = "Eye of Comprehension",
          },
          ["Graverobber's Icon"] = {
            aliases = {
              "Graverobber's Icon",
            },
            ids = {
            },
            item = "Graverobber's Icon",
          },
          ["Minion's"] = {
            aliases = {
              "Minion's Memento",
            },
            ids = {
            },
            item = "Minion's Memento",
          },
        },
        Paladin = {
          BellikosClaws = {
            aliases = {
              "Splintered Bellikos Claws",
            },
            ids = {
            },
            item = "Splintered Bellikos Claws",
          },
          BellikosFang = {
            aliases = {
              "Fragmented Bellikos Fang",
            },
            ids = {
            },
            item = "Fragmented Bellikos Fang",
          },
          BellikosTear = {
            aliases = {
              "Hardened Tear of the Bellikos",
            },
            ids = {
            },
            item = "Hardened Tear of the Bellikos",
          },
          EyeComprehension = {
            aliases = {
              "Eye of Comprehension",
            },
            ids = {
            },
            item = "Eye of Comprehension",
          },
          EyeMight = {
            aliases = {
              "Eye of Might",
            },
            ids = {
            },
            item = "Eye of Might",
          },
          FrozenOre = {
            aliases = {
              "Frozen Ore",
            },
            ids = {
              150215,
            },
            item = "Frozen Ore",
          },
        },
        Ranger = {
          BellikosClaws = {
            aliases = {
              "Splintered Bellikos Claws",
            },
            ids = {
            },
            item = "Splintered Bellikos Claws",
          },
          BellikosEye = {
            aliases = {
              "Obsidian Bellikos Eye",
            },
            ids = {
            },
            item = "Obsidian Bellikos Eye",
          },
          BellikosFang = {
            aliases = {
              "Fragmented Bellikos Fang",
            },
            ids = {
            },
            item = "Fragmented Bellikos Fang",
          },
          EyeComprehension = {
            aliases = {
              "Eye of Comprehension",
            },
            ids = {
            },
            item = "Eye of Comprehension",
          },
          EyeMight = {
            aliases = {
              "Eye of Might",
            },
            ids = {
            },
            item = "Eye of Might",
          },
          FrozenOre = {
            aliases = {
              "Frozen Ore",
            },
            ids = {
              150215,
            },
            item = "Frozen Ore",
          },
        },
        Rogue = {
          BellikosClaws = {
            aliases = {
              "Splintered Bellikos Claws",
            },
            ids = {
            },
            item = "Splintered Bellikos Claws",
          },
          EyeMight = {
            aliases = {
              "Eye of Might",
            },
            ids = {
            },
            item = "Eye of Might",
          },
          FrozenOre = {
            aliases = {
              "Frozen Ore",
            },
            ids = {
              150215,
            },
            item = "Frozen Ore",
          },
        },
        ["Shadow Knight"] = {
          BellikosClaws = {
            aliases = {
              "Splintered Bellikos Claws",
            },
            ids = {
            },
            item = "Splintered Bellikos Claws",
          },
          BellikosFang = {
            aliases = {
              "Fragmented Bellikos Fang",
            },
            ids = {
            },
            item = "Fragmented Bellikos Fang",
          },
          BellikosTear = {
            aliases = {
              "Hardened Tear of the Bellikos",
            },
            ids = {
            },
            item = "Hardened Tear of the Bellikos",
          },
          Crystalized = {
            aliases = {
              "Crystalized Soul Gem",
            },
            ids = {
            },
            item = "Crystalized Soul Gem",
          },
          EyeComprehension = {
            aliases = {
              "Eye of Comprehension",
            },
            ids = {
            },
            item = "Eye of Comprehension",
          },
          EyeMight = {
            aliases = {
              "Eye of Might",
            },
            ids = {
            },
            item = "Eye of Might",
          },
          FrozenOre = {
            aliases = {
              "Frozen Ore",
            },
            ids = {
              150215,
            },
            item = "Frozen Ore",
          },
          ["Minion's"] = {
            aliases = {
              "Minion's Memento",
            },
            ids = {
            },
            item = "Minion's Memento",
          },
        },
        Shaman = {
          BellikosEye = {
            aliases = {
              "Obsidian Bellikos Eye",
            },
            ids = {
            },
            item = "Obsidian Bellikos Eye",
          },
          Crystalized = {
            aliases = {
              "Crystalized Soul Gem",
            },
            ids = {
            },
            item = "Crystalized Soul Gem",
          },
          EyeComprehension = {
            aliases = {
              "Eye of Comprehension",
            },
            ids = {
            },
            item = "Eye of Comprehension",
          },
          ["Minion's"] = {
            aliases = {
              "Minion's Memento",
            },
            ids = {
            },
            item = "Minion's Memento",
          },
          ["Shattered Gnoll Slayer"] = {
            aliases = {
              "Shattered Gnoll Slayer",
            },
            ids = {
            },
            item = "Shattered Gnoll Slayer",
          },
        },
        Warrior = {
          ["Battered Smuggler's Barrel"] = {
            aliases = {
              "Battered Smuggler's Barrel",
            },
            ids = {
            },
            item = "Battered Smuggler's Barrel",
          },
          BellikosClaws = {
            aliases = {
              "Splintered Bellikos Claws",
            },
            ids = {
            },
            item = "Splintered Bellikos Claws",
          },
          BellikosFang = {
            aliases = {
              "Fragmented Bellikos Fang",
            },
            ids = {
            },
            item = "Fragmented Bellikos Fang",
          },
          BellikosTear = {
            aliases = {
              "Hardened Tear of the Bellikos",
            },
            ids = {
            },
            item = "Hardened Tear of the Bellikos",
          },
          EyeMight = {
            aliases = {
              "Eye of Might",
            },
            ids = {
            },
            item = "Eye of Might",
          },
          FrozenOre = {
            aliases = {
              "Frozen Ore",
            },
            ids = {
              150215,
            },
            item = "Frozen Ore",
          },
        },
        Wizard = {
          BellikosEye = {
            aliases = {
              "Obsidian Bellikos Eye",
            },
            ids = {
            },
            item = "Obsidian Bellikos Eye",
          },
          EyeComprehension = {
            aliases = {
              "Eye of Comprehension",
            },
            ids = {
            },
            item = "Eye of Comprehension",
          },
        },
      },
      group = "Other Checklists",
      id = "hcitems",
      name = "Higher Level HC Items",
      show_base = {
      },
      template = {
        ArcaneDestruction = {
          aliases = {
            "Arcane Umbra of Destruction",
          },
          ids = {
            151026,
          },
          item = "Arcane Umbra of Destruction",
        },
        ArcaneMending = {
          aliases = {
            "Arcane Umbra of Mending",
          },
          ids = {
            151027,
          },
          item = "Arcane Umbra of Mending",
        },
        ArcanePersistence = {
          aliases = {
            "Arcane Umbra of Persistence",
          },
          ids = {
            151028,
          },
          item = "Arcane Umbra of Persistence",
        },
        ArcaneSuffering = {
          aliases = {
            "Arcane Umbra of Suffering",
          },
          ids = {
            151029,
          },
          item = "Arcane Umbra of Suffering",
        },
        IncarnateCleaving = {
          aliases = {
            "Incarnate Umbra of Cleaving",
          },
          ids = {
            151030,
          },
          item = "Incarnate Umbra of Cleaving",
        },
        IncarnateDeflection = {
          aliases = {
            "Incarnate Umbra of Deflection",
          },
          ids = {
            151031,
          },
          item = "Incarnate Umbra of Deflection",
        },
        IncarnateEvasion = {
          aliases = {
            "Incarnate Umbra of Evasion",
          },
          ids = {
            151032,
          },
          item = "Incarnate Umbra of Evasion",
        },
        IncarnateFerocity = {
          aliases = {
            "Incarnate Umbra of Ferocity",
          },
          ids = {
            151033,
          },
          item = "Incarnate Umbra of Ferocity",
        },
        Tongue = {
          aliases = {
            "Tongue of Unspoken Sins",
          },
          ids = {
            150979,
          },
          item = "Tongue of Unspoken Sins",
        },
        TranquilSoul = {
          aliases = {
            "The Tranquil Soul",
          },
          ids = {
            17712,
          },
          item = "The Tranquil Soul",
        },
      },
      visible = {
      },
    },
    jonas = {
      categories = {
        {
          name = "Tier 1",
          slots = {
            "Tier 1 Complete",
            "Scruffy (HC QH)",
            "Ground Spawn (QH)",
            "Dixl Drool (OOT)",
            "Ground Spawn (OOT)",
            "Efreeti Lord (SolB)",
            "Ground Spawn (SolB)",
            "Ice Giants (Perma)",
            "Goblin Alchemist (Perma)",
          },
        },
        {
          name = "Tier 2",
          slots = {
            "Tier 2 Complete",
            "Elite Gnolls (Blackburrow)",
            "Lord Pickclaw (Runnyeye)",
            "Redwind (Everfrost)",
          },
        },
        {
          name = "Tier 3",
          slots = {
            "Tier 3 Complete",
            "Rosch Var'L'Vlor (SK)",
            "Lord Gimblox (SolA)",
            "Skeleton Lrodd (Befallen)",
            "Spectres (Oasis)",
          },
        },
        {
          name = "Tier 4",
          slots = {
            "Tier 4 Complete",
            "Gorillas (CT)",
            "Ambassador Dvinn (CB)",
            "Froglok Shin Lord (GukTop)",
            "Death Beetles (Unrest)",
          },
        },
        {
          name = "Tier 5",
          slots = {
            "Tier 5 Complete",
            "Ground Spawn (Mistmoore)",
            "Slizik The Mighty (Hole)",
            "Ground Spawn (SplitPaw)",
            "Frenzied Ghoul (GukBottom)",
          },
        },
        {
          name = "Tier 6 (Final)",
          slots = {
            "Tier 6 Complete",
            "Middle Finger (Mayong)",
          },
        },
      },
      classes = {
      },
      group = "Other Checklists",
      id = "jonas",
      name = "Hand Aug",
      show_base = {
        ALL = 1,
      },
      template = {
        ["Ambassador Dvinn (CB)"] = {
          aliases = {
            "Ring Finger Middle Phalanx",
          },
          ids = {
            33169,
            33170,
            33171,
            33174,
          },
          item = "Ring Finger Middle Phalanx",
        },
        ["Death Beetles (Unrest)"] = {
          aliases = {
            "Ring Finger Metacarpal",
          },
          ids = {
            33169,
            33170,
            33171,
            33174,
          },
          item = "Ring Finger Metacarpal",
        },
        ["Dixl Drool (OOT)"] = {
          aliases = {
            "Hamate",
          },
          ids = {
            33166,
            33167,
            33168,
            33169,
            33170,
            33171,
          },
          item = "Hamate",
        },
        ["Efreeti Lord (SolB)"] = {
          aliases = {
            "Scaphoid",
          },
          ids = {
            33166,
            33167,
            33168,
            33169,
            33170,
            33171,
          },
          item = "Scaphoid",
        },
        ["Elite Gnolls (Blackburrow)"] = {
          aliases = {
            "Thumb Distal Phalanx",
          },
          ids = {
            33167,
            33168,
            33169,
            33170,
            33171,
            33172,
          },
          item = "Thumb Distal Phalanx",
        },
        ["Frenzied Ghoul (GukBottom)"] = {
          aliases = {
            "Little Finger Metacarpal",
          },
          ids = {
            33170,
            33171,
            33175,
          },
          item = "Little Finger Metacarpal",
        },
        ["Froglok Shin Lord (GukTop)"] = {
          aliases = {
            "Ring Finger Proximal Phalanx",
          },
          ids = {
            33169,
            33170,
            33171,
            33174,
          },
          item = "Ring Finger Proximal Phalanx",
        },
        ["Goblin Alchemist (Perma)"] = {
          aliases = {
            "Lunate",
          },
          ids = {
            33166,
            33167,
            33168,
            33169,
            33170,
            33171,
          },
          item = "Lunate",
        },
        ["Gorillas (CT)"] = {
          aliases = {
            "Ring Finger Distal Phalanx",
          },
          ids = {
            33169,
            33170,
            33171,
            33174,
          },
          item = "Ring Finger Distal Phalanx",
        },
        ["Ground Spawn (Mistmoore)"] = {
          aliases = {
            "Little Finger Distal Phalanx",
          },
          ids = {
            33170,
            33171,
            33175,
          },
          item = "Little Finger Distal Phalanx",
        },
        ["Ground Spawn (OOT)"] = {
          aliases = {
            "Triquetrum",
          },
          ids = {
            33166,
            33167,
            33168,
            33169,
            33170,
            33171,
          },
          item = "Triquetrum",
        },
        ["Ground Spawn (QH)"] = {
          aliases = {
            "Trapezium",
          },
          ids = {
            33166,
            33167,
            33168,
            33169,
            33170,
            33171,
          },
          item = "Trapezium",
        },
        ["Ground Spawn (SolB)"] = {
          aliases = {
            "Capitate",
          },
          ids = {
            33166,
            33167,
            33168,
            33169,
            33170,
            33171,
          },
          item = "Capitate",
        },
        ["Ground Spawn (SplitPaw)"] = {
          aliases = {
            "Little Finger Proximal Phalanx",
          },
          ids = {
            33170,
            33171,
            33175,
          },
          item = "Little Finger Proximal Phalanx",
        },
        ["Ice Giants (Perma)"] = {
          aliases = {
            "Pisiform",
          },
          ids = {
            33166,
            33167,
            33168,
            33169,
            33170,
            33171,
          },
          item = "Pisiform",
        },
        ["Lord Gimblox (SolA)"] = {
          aliases = {
            "Forefinger Middle Phalanx",
          },
          ids = {
            33168,
            33169,
            33170,
            33171,
            33173,
          },
          item = "Forefinger Middle Phalanx",
        },
        ["Lord Pickclaw (Runnyeye)"] = {
          aliases = {
            "Thumb Metacarpal",
          },
          ids = {
            33167,
            33168,
            33169,
            33170,
            33171,
            33172,
          },
          item = "Thumb Metacarpal",
        },
        ["Middle Finger (Mayong)"] = {
          aliases = {
            "Jonas Dagmire's Skeletal Middle Finger",
          },
          ids = {
            33171,
            33176,
            82836,
          },
          item = "Jonas Dagmire's Skeletal Middle Finger",
        },
        ["Redwind (Everfrost)"] = {
          aliases = {
            "Thumb Proximal Phalanx",
          },
          ids = {
            33167,
            33168,
            33169,
            33170,
            33171,
            33172,
          },
          item = "Thumb Proximal Phalanx",
        },
        ["Rosch Var'L'Vlor (SK)"] = {
          aliases = {
            "Forefinger Distal Phalanx",
          },
          ids = {
            33168,
            33169,
            33170,
            33171,
            33173,
          },
          item = "Forefinger Distal Phalanx",
        },
        ["Scruffy (HC QH)"] = {
          aliases = {
            "Trapezoid",
          },
          ids = {
            33166,
            33167,
            33168,
            33169,
            33170,
            33171,
          },
          item = "Trapezoid",
        },
        ["Skeleton Lrodd (Befallen)"] = {
          aliases = {
            "Forefinger Proximal Phalanx",
          },
          ids = {
            33168,
            33169,
            33170,
            33171,
            33173,
          },
          item = "Forefinger Proximal Phalanx",
        },
        ["Slizik The Mighty (Hole)"] = {
          aliases = {
            "Little Finger Middle Phalanx",
          },
          ids = {
            33170,
            33171,
            33175,
          },
          item = "Little Finger Middle Phalanx",
        },
        ["Spectres (Oasis)"] = {
          aliases = {
            "Forefinger Metacarpal",
          },
          ids = {
            33168,
            33169,
            33170,
            33171,
            33173,
          },
          item = "Forefinger Metacarpal",
        },
        ["Tier 1 Complete"] = {
          aliases = {
            "Jonas Dagmire's Skeletal Backhand",
          },
          ids = {
            33166,
            33167,
            33168,
            33169,
            33170,
            33171,
          },
          item = "Jonas Dagmire's Skeletal Backhand",
        },
        ["Tier 2 Complete"] = {
          aliases = {
            "Jonas Dagmire's Skeletal Thumb",
          },
          ids = {
            33167,
            33168,
            33169,
            33170,
            33171,
            33172,
          },
          item = "Jonas Dagmire's Skeletal Thumb",
        },
        ["Tier 3 Complete"] = {
          aliases = {
            "Jonas Dagmire's Skeletal Forefinger",
          },
          ids = {
            33168,
            33169,
            33170,
            33171,
            33173,
          },
          item = "Jonas Dagmire's Skeletal Forefinger",
        },
        ["Tier 4 Complete"] = {
          aliases = {
            "Jonas Dagmire's Skeletal Ring Finger",
          },
          ids = {
            33169,
            33170,
            33171,
            33174,
          },
          item = "Jonas Dagmire's Skeletal Ring Finger",
        },
        ["Tier 5 Complete"] = {
          aliases = {
            "Jonas Dagmire's Skeletal Little Finger",
          },
          ids = {
            33170,
            33171,
            33175,
          },
          item = "Jonas Dagmire's Skeletal Little Finger",
        },
        ["Tier 6 Complete"] = {
          aliases = {
            "Jonas Dagmire's Skeletal Hand",
          },
          ids = {
            33171,
          },
          item = "Jonas Dagmire's Skeletal Hand",
        },
      },
      visible = {
      },
    },
    llhcitems = {
      categories = {
        {
          name = "Augs/Items",
          slots = {
            "Ancient Gnawbone",
            "Asp's Fang",
            "Authentic Treasure Map",
            "Bludgeon of the Brute",
            "Brilliant Geode",
            "Corrupted Netherstone",
            "Corundum Infused Granite",
            "Creepy Bone Chips",
            "Deep Emerald Stone",
            "Experimental Device",
            "Hardened Bone Shard",
            "Honed Geode Cluster",
            "Imbued Feather",
            "Lance of the Legionnaire",
            "Lucent Crystal",
            "Luminescent Geode Cluster",
            "Malevolent Effigy",
            "Mallet of the Marauder",
            "Radiant Geode",
            "Rallosian Power Gem",
            "Resilient Sphere",
            "Shard of Phosphorescent Power",
            "Shard of True Power",
            "Shrunken Gnoll Head",
            "Staff of the Subjugator",
            "Stone of Greatness",
            "Vapor of Vitality",
            "Void Rune of Sacrifice",
          },
        },
      },
      classes = {
        Bard = {
          ["Ancient Gnawbone"] = {
            aliases = {
              "Ancient Gnawbone",
            },
            ids = {
            },
            item = "Ancient Gnawbone",
          },
          ["Asp's Fang"] = {
            aliases = {
              "Asp's Fang",
            },
            ids = {
            },
            item = "Asp's Fang",
          },
          ["Authentic Treasure Map"] = {
            aliases = {
              "Authentic Treasure Map",
            },
            ids = {
            },
            item = "Authentic Treasure Map",
          },
          ["Brilliant Geode"] = {
            aliases = {
              "Brilliant Geode",
            },
            ids = {
            },
            item = "Brilliant Geode",
          },
          ["Corrupted Netherstone"] = {
            aliases = {
              "Corrupted Netherstone",
            },
            ids = {
            },
            item = "Corrupted Netherstone",
          },
          ["Creepy Bone Chips"] = {
            aliases = {
              "Creepy Bone Chips",
            },
            ids = {
            },
            item = "Creepy Bone Chips",
          },
          ["Deep Emerald Stone"] = {
            aliases = {
              "Deep Emerald Stone",
            },
            ids = {
            },
            item = "Deep Emerald Stone",
          },
          ["Hardened Bone Shard"] = {
            aliases = {
              "Hardened Bone Shard",
            },
            ids = {
            },
            item = "Hardened Bone Shard",
          },
          ["Honed Geode Cluster"] = {
            aliases = {
              "Honed Geode Cluster",
            },
            ids = {
            },
            item = "Honed Geode Cluster",
          },
          ["Imbued Feather"] = {
            aliases = {
              "Imbued Feather",
            },
            ids = {
            },
            item = "Imbued Feather",
          },
          ["Lucent Crystal"] = {
            aliases = {
              "Lucent Crystal",
            },
            ids = {
            },
            item = "Lucent Crystal",
          },
          ["Luminescent Geode Cluster"] = {
            aliases = {
              "Luminescent Geode Cluster",
            },
            ids = {
            },
            item = "Luminescent Geode Cluster",
          },
          ["Mallet of the Marauder"] = {
            aliases = {
              "Mallet of the Marauder",
            },
            ids = {
            },
            item = "Mallet of the Marauder",
          },
          ["Radiant Geode"] = {
            aliases = {
              "Radiant Geode",
            },
            ids = {
            },
            item = "Radiant Geode",
          },
          ["Rallosian Power Gem"] = {
            aliases = {
              "Rallosian Power Gem",
            },
            ids = {
            },
            item = "Rallosian Power Gem",
          },
          ["Resilient Sphere"] = {
            aliases = {
              "Resilient Sphere",
            },
            ids = {
            },
            item = "Resilient Sphere",
          },
          ["Shard of Phosphorescent Power"] = {
            aliases = {
              "Shard of Phosphorescent Power",
            },
            ids = {
            },
            item = "Shard of Phosphorescent Power",
          },
          ["Shard of True Power"] = {
            aliases = {
              "Shard of True Power",
            },
            ids = {
            },
            item = "Shard of True Power",
          },
          ["Shrunken Gnoll Head"] = {
            aliases = {
              "Shrunken Gnoll Head",
            },
            ids = {
            },
            item = "Shrunken Gnoll Head",
          },
          ["Stone of Greatness"] = {
            aliases = {
              "Stone of Greatness",
            },
            ids = {
            },
            item = "Stone of Greatness",
          },
        },
        Beastlord = {
          ["Ancient Gnawbone"] = {
            aliases = {
              "Ancient Gnawbone",
            },
            ids = {
            },
            item = "Ancient Gnawbone",
          },
          ["Asp's Fang"] = {
            aliases = {
              "Asp's Fang",
            },
            ids = {
            },
            item = "Asp's Fang",
          },
          ["Authentic Treasure Map"] = {
            aliases = {
              "Authentic Treasure Map",
            },
            ids = {
            },
            item = "Authentic Treasure Map",
          },
          ["Bludgeon of the Brute"] = {
            aliases = {
              "Bludgeon of the Brute",
            },
            ids = {
            },
            item = "Bludgeon of the Brute",
          },
          ["Brilliant Geode"] = {
            aliases = {
              "Brilliant Geode",
            },
            ids = {
            },
            item = "Brilliant Geode",
          },
          ["Corrupted Netherstone"] = {
            aliases = {
              "Corrupted Netherstone",
            },
            ids = {
            },
            item = "Corrupted Netherstone",
          },
          ["Creepy Bone Chips"] = {
            aliases = {
              "Creepy Bone Chips",
            },
            ids = {
            },
            item = "Creepy Bone Chips",
          },
          ["Deep Emerald Stone"] = {
            aliases = {
              "Deep Emerald Stone",
            },
            ids = {
            },
            item = "Deep Emerald Stone",
          },
          ["Hardened Bone Shard"] = {
            aliases = {
              "Hardened Bone Shard",
            },
            ids = {
            },
            item = "Hardened Bone Shard",
          },
          ["Honed Geode Cluster"] = {
            aliases = {
              "Honed Geode Cluster",
            },
            ids = {
            },
            item = "Honed Geode Cluster",
          },
          ["Imbued Feather"] = {
            aliases = {
              "Imbued Feather",
            },
            ids = {
            },
            item = "Imbued Feather",
          },
          ["Lucent Crystal"] = {
            aliases = {
              "Lucent Crystal",
            },
            ids = {
            },
            item = "Lucent Crystal",
          },
          ["Luminescent Geode Cluster"] = {
            aliases = {
              "Luminescent Geode Cluster",
            },
            ids = {
            },
            item = "Luminescent Geode Cluster",
          },
          ["Malevolent Effigy"] = {
            aliases = {
              "Malevolent Effigy",
            },
            ids = {
            },
            item = "Malevolent Effigy",
          },
          ["Mallet of the Marauder"] = {
            aliases = {
              "Mallet of the Marauder",
            },
            ids = {
            },
            item = "Mallet of the Marauder",
          },
          ["Radiant Geode"] = {
            aliases = {
              "Radiant Geode",
            },
            ids = {
            },
            item = "Radiant Geode",
          },
          ["Rallosian Power Gem"] = {
            aliases = {
              "Rallosian Power Gem",
            },
            ids = {
            },
            item = "Rallosian Power Gem",
          },
          ["Resilient Sphere"] = {
            aliases = {
              "Resilient Sphere",
            },
            ids = {
            },
            item = "Resilient Sphere",
          },
          ["Shard of Phosphorescent Power"] = {
            aliases = {
              "Shard of Phosphorescent Power",
            },
            ids = {
            },
            item = "Shard of Phosphorescent Power",
          },
          ["Shard of True Power"] = {
            aliases = {
              "Shard of True Power",
            },
            ids = {
            },
            item = "Shard of True Power",
          },
          ["Shrunken Gnoll Head"] = {
            aliases = {
              "Shrunken Gnoll Head",
            },
            ids = {
            },
            item = "Shrunken Gnoll Head",
          },
          ["Stone of Greatness"] = {
            aliases = {
              "Stone of Greatness",
            },
            ids = {
            },
            item = "Stone of Greatness",
          },
          ["Vapor of Vitality"] = {
            aliases = {
              "Vapor of Vitality",
            },
            ids = {
            },
            item = "Vapor of Vitality",
          },
        },
        Berserker = {
          ["Ancient Gnawbone"] = {
            aliases = {
              "Ancient Gnawbone",
            },
            ids = {
            },
            item = "Ancient Gnawbone",
          },
          ["Asp's Fang"] = {
            aliases = {
              "Asp's Fang",
            },
            ids = {
            },
            item = "Asp's Fang",
          },
          ["Authentic Treasure Map"] = {
            aliases = {
              "Authentic Treasure Map",
            },
            ids = {
            },
            item = "Authentic Treasure Map",
          },
          ["Bludgeon of the Brute"] = {
            aliases = {
              "Bludgeon of the Brute",
            },
            ids = {
            },
            item = "Bludgeon of the Brute",
          },
          ["Brilliant Geode"] = {
            aliases = {
              "Brilliant Geode",
            },
            ids = {
            },
            item = "Brilliant Geode",
          },
          ["Corrupted Netherstone"] = {
            aliases = {
              "Corrupted Netherstone",
            },
            ids = {
            },
            item = "Corrupted Netherstone",
          },
          ["Creepy Bone Chips"] = {
            aliases = {
              "Creepy Bone Chips",
            },
            ids = {
            },
            item = "Creepy Bone Chips",
          },
          ["Deep Emerald Stone"] = {
            aliases = {
              "Deep Emerald Stone",
            },
            ids = {
            },
            item = "Deep Emerald Stone",
          },
          ["Hardened Bone Shard"] = {
            aliases = {
              "Hardened Bone Shard",
            },
            ids = {
            },
            item = "Hardened Bone Shard",
          },
          ["Honed Geode Cluster"] = {
            aliases = {
              "Honed Geode Cluster",
            },
            ids = {
            },
            item = "Honed Geode Cluster",
          },
          ["Imbued Feather"] = {
            aliases = {
              "Imbued Feather",
            },
            ids = {
            },
            item = "Imbued Feather",
          },
          ["Lucent Crystal"] = {
            aliases = {
              "Lucent Crystal",
            },
            ids = {
            },
            item = "Lucent Crystal",
          },
          ["Luminescent Geode Cluster"] = {
            aliases = {
              "Luminescent Geode Cluster",
            },
            ids = {
            },
            item = "Luminescent Geode Cluster",
          },
          ["Radiant Geode"] = {
            aliases = {
              "Radiant Geode",
            },
            ids = {
            },
            item = "Radiant Geode",
          },
          ["Rallosian Power Gem"] = {
            aliases = {
              "Rallosian Power Gem",
            },
            ids = {
            },
            item = "Rallosian Power Gem",
          },
          ["Resilient Sphere"] = {
            aliases = {
              "Resilient Sphere",
            },
            ids = {
            },
            item = "Resilient Sphere",
          },
          ["Shard of Phosphorescent Power"] = {
            aliases = {
              "Shard of Phosphorescent Power",
            },
            ids = {
            },
            item = "Shard of Phosphorescent Power",
          },
          ["Shard of True Power"] = {
            aliases = {
              "Shard of True Power",
            },
            ids = {
            },
            item = "Shard of True Power",
          },
          ["Shrunken Gnoll Head"] = {
            aliases = {
              "Shrunken Gnoll Head",
            },
            ids = {
            },
            item = "Shrunken Gnoll Head",
          },
          ["Stone of Greatness"] = {
            aliases = {
              "Stone of Greatness",
            },
            ids = {
            },
            item = "Stone of Greatness",
          },
        },
        Cleric = {
          ["Ancient Gnawbone"] = {
            aliases = {
              "Ancient Gnawbone",
            },
            ids = {
            },
            item = "Ancient Gnawbone",
          },
          ["Authentic Treasure Map"] = {
            aliases = {
              "Authentic Treasure Map",
            },
            ids = {
            },
            item = "Authentic Treasure Map",
          },
          ["Brilliant Geode"] = {
            aliases = {
              "Brilliant Geode",
            },
            ids = {
            },
            item = "Brilliant Geode",
          },
          ["Corrupted Netherstone"] = {
            aliases = {
              "Corrupted Netherstone",
            },
            ids = {
            },
            item = "Corrupted Netherstone",
          },
          ["Creepy Bone Chips"] = {
            aliases = {
              "Creepy Bone Chips",
            },
            ids = {
            },
            item = "Creepy Bone Chips",
          },
          ["Hardened Bone Shard"] = {
            aliases = {
              "Hardened Bone Shard",
            },
            ids = {
            },
            item = "Hardened Bone Shard",
          },
          ["Honed Geode Cluster"] = {
            aliases = {
              "Honed Geode Cluster",
            },
            ids = {
            },
            item = "Honed Geode Cluster",
          },
          ["Imbued Feather"] = {
            aliases = {
              "Imbued Feather",
            },
            ids = {
            },
            item = "Imbued Feather",
          },
          ["Lucent Crystal"] = {
            aliases = {
              "Lucent Crystal",
            },
            ids = {
            },
            item = "Lucent Crystal",
          },
          ["Luminescent Geode Cluster"] = {
            aliases = {
              "Luminescent Geode Cluster",
            },
            ids = {
            },
            item = "Luminescent Geode Cluster",
          },
          ["Malevolent Effigy"] = {
            aliases = {
              "Malevolent Effigy",
            },
            ids = {
            },
            item = "Malevolent Effigy",
          },
          ["Rallosian Power Gem"] = {
            aliases = {
              "Rallosian Power Gem",
            },
            ids = {
            },
            item = "Rallosian Power Gem",
          },
          ["Resilient Sphere"] = {
            aliases = {
              "Resilient Sphere",
            },
            ids = {
            },
            item = "Resilient Sphere",
          },
          ["Shard of Phosphorescent Power"] = {
            aliases = {
              "Shard of Phosphorescent Power",
            },
            ids = {
            },
            item = "Shard of Phosphorescent Power",
          },
          ["Shard of True Power"] = {
            aliases = {
              "Shard of True Power",
            },
            ids = {
            },
            item = "Shard of True Power",
          },
          ["Shrunken Gnoll Head"] = {
            aliases = {
              "Shrunken Gnoll Head",
            },
            ids = {
            },
            item = "Shrunken Gnoll Head",
          },
          ["Staff of the Subjugator"] = {
            aliases = {
              "Staff of the Subjugator",
            },
            ids = {
            },
            item = "Staff of the Subjugator",
          },
          ["Vapor of Vitality"] = {
            aliases = {
              "Vapor of Vitality",
            },
            ids = {
            },
            item = "Vapor of Vitality",
          },
        },
        Druid = {
          ["Ancient Gnawbone"] = {
            aliases = {
              "Ancient Gnawbone",
            },
            ids = {
            },
            item = "Ancient Gnawbone",
          },
          ["Authentic Treasure Map"] = {
            aliases = {
              "Authentic Treasure Map",
            },
            ids = {
            },
            item = "Authentic Treasure Map",
          },
          ["Brilliant Geode"] = {
            aliases = {
              "Brilliant Geode",
            },
            ids = {
            },
            item = "Brilliant Geode",
          },
          ["Corrupted Netherstone"] = {
            aliases = {
              "Corrupted Netherstone",
            },
            ids = {
            },
            item = "Corrupted Netherstone",
          },
          ["Creepy Bone Chips"] = {
            aliases = {
              "Creepy Bone Chips",
            },
            ids = {
            },
            item = "Creepy Bone Chips",
          },
          ["Hardened Bone Shard"] = {
            aliases = {
              "Hardened Bone Shard",
            },
            ids = {
            },
            item = "Hardened Bone Shard",
          },
          ["Honed Geode Cluster"] = {
            aliases = {
              "Honed Geode Cluster",
            },
            ids = {
            },
            item = "Honed Geode Cluster",
          },
          ["Imbued Feather"] = {
            aliases = {
              "Imbued Feather",
            },
            ids = {
            },
            item = "Imbued Feather",
          },
          ["Lucent Crystal"] = {
            aliases = {
              "Lucent Crystal",
            },
            ids = {
            },
            item = "Lucent Crystal",
          },
          ["Luminescent Geode Cluster"] = {
            aliases = {
              "Luminescent Geode Cluster",
            },
            ids = {
            },
            item = "Luminescent Geode Cluster",
          },
          ["Malevolent Effigy"] = {
            aliases = {
              "Malevolent Effigy",
            },
            ids = {
            },
            item = "Malevolent Effigy",
          },
          ["Rallosian Power Gem"] = {
            aliases = {
              "Rallosian Power Gem",
            },
            ids = {
            },
            item = "Rallosian Power Gem",
          },
          ["Resilient Sphere"] = {
            aliases = {
              "Resilient Sphere",
            },
            ids = {
            },
            item = "Resilient Sphere",
          },
          ["Shard of Phosphorescent Power"] = {
            aliases = {
              "Shard of Phosphorescent Power",
            },
            ids = {
            },
            item = "Shard of Phosphorescent Power",
          },
          ["Shard of True Power"] = {
            aliases = {
              "Shard of True Power",
            },
            ids = {
            },
            item = "Shard of True Power",
          },
          ["Shrunken Gnoll Head"] = {
            aliases = {
              "Shrunken Gnoll Head",
            },
            ids = {
            },
            item = "Shrunken Gnoll Head",
          },
          ["Staff of the Subjugator"] = {
            aliases = {
              "Staff of the Subjugator",
            },
            ids = {
            },
            item = "Staff of the Subjugator",
          },
          ["Vapor of Vitality"] = {
            aliases = {
              "Vapor of Vitality",
            },
            ids = {
            },
            item = "Vapor of Vitality",
          },
        },
        Enchanter = {
          ["Ancient Gnawbone"] = {
            aliases = {
              "Ancient Gnawbone",
            },
            ids = {
            },
            item = "Ancient Gnawbone",
          },
          ["Authentic Treasure Map"] = {
            aliases = {
              "Authentic Treasure Map",
            },
            ids = {
            },
            item = "Authentic Treasure Map",
          },
          ["Brilliant Geode"] = {
            aliases = {
              "Brilliant Geode",
            },
            ids = {
            },
            item = "Brilliant Geode",
          },
          ["Corrupted Netherstone"] = {
            aliases = {
              "Corrupted Netherstone",
            },
            ids = {
            },
            item = "Corrupted Netherstone",
          },
          ["Creepy Bone Chips"] = {
            aliases = {
              "Creepy Bone Chips",
            },
            ids = {
            },
            item = "Creepy Bone Chips",
          },
          ["Hardened Bone Shard"] = {
            aliases = {
              "Hardened Bone Shard",
            },
            ids = {
            },
            item = "Hardened Bone Shard",
          },
          ["Honed Geode Cluster"] = {
            aliases = {
              "Honed Geode Cluster",
            },
            ids = {
            },
            item = "Honed Geode Cluster",
          },
          ["Imbued Feather"] = {
            aliases = {
              "Imbued Feather",
            },
            ids = {
            },
            item = "Imbued Feather",
          },
          ["Lucent Crystal"] = {
            aliases = {
              "Lucent Crystal",
            },
            ids = {
            },
            item = "Lucent Crystal",
          },
          ["Luminescent Geode Cluster"] = {
            aliases = {
              "Luminescent Geode Cluster",
            },
            ids = {
            },
            item = "Luminescent Geode Cluster",
          },
          ["Malevolent Effigy"] = {
            aliases = {
              "Malevolent Effigy",
            },
            ids = {
            },
            item = "Malevolent Effigy",
          },
          ["Rallosian Power Gem"] = {
            aliases = {
              "Rallosian Power Gem",
            },
            ids = {
            },
            item = "Rallosian Power Gem",
          },
          ["Resilient Sphere"] = {
            aliases = {
              "Resilient Sphere",
            },
            ids = {
            },
            item = "Resilient Sphere",
          },
          ["Shard of Phosphorescent Power"] = {
            aliases = {
              "Shard of Phosphorescent Power",
            },
            ids = {
            },
            item = "Shard of Phosphorescent Power",
          },
          ["Shard of True Power"] = {
            aliases = {
              "Shard of True Power",
            },
            ids = {
            },
            item = "Shard of True Power",
          },
          ["Shrunken Gnoll Head"] = {
            aliases = {
              "Shrunken Gnoll Head",
            },
            ids = {
            },
            item = "Shrunken Gnoll Head",
          },
          ["Staff of the Subjugator"] = {
            aliases = {
              "Staff of the Subjugator",
            },
            ids = {
            },
            item = "Staff of the Subjugator",
          },
          ["Vapor of Vitality"] = {
            aliases = {
              "Vapor of Vitality",
            },
            ids = {
            },
            item = "Vapor of Vitality",
          },
        },
        Magician = {
          ["Ancient Gnawbone"] = {
            aliases = {
              "Ancient Gnawbone",
            },
            ids = {
            },
            item = "Ancient Gnawbone",
          },
          ["Authentic Treasure Map"] = {
            aliases = {
              "Authentic Treasure Map",
            },
            ids = {
            },
            item = "Authentic Treasure Map",
          },
          ["Brilliant Geode"] = {
            aliases = {
              "Brilliant Geode",
            },
            ids = {
            },
            item = "Brilliant Geode",
          },
          ["Corrupted Netherstone"] = {
            aliases = {
              "Corrupted Netherstone",
            },
            ids = {
            },
            item = "Corrupted Netherstone",
          },
          ["Creepy Bone Chips"] = {
            aliases = {
              "Creepy Bone Chips",
            },
            ids = {
            },
            item = "Creepy Bone Chips",
          },
          ["Hardened Bone Shard"] = {
            aliases = {
              "Hardened Bone Shard",
            },
            ids = {
            },
            item = "Hardened Bone Shard",
          },
          ["Honed Geode Cluster"] = {
            aliases = {
              "Honed Geode Cluster",
            },
            ids = {
            },
            item = "Honed Geode Cluster",
          },
          ["Imbued Feather"] = {
            aliases = {
              "Imbued Feather",
            },
            ids = {
            },
            item = "Imbued Feather",
          },
          ["Lucent Crystal"] = {
            aliases = {
              "Lucent Crystal",
            },
            ids = {
            },
            item = "Lucent Crystal",
          },
          ["Luminescent Geode Cluster"] = {
            aliases = {
              "Luminescent Geode Cluster",
            },
            ids = {
            },
            item = "Luminescent Geode Cluster",
          },
          ["Malevolent Effigy"] = {
            aliases = {
              "Malevolent Effigy",
            },
            ids = {
            },
            item = "Malevolent Effigy",
          },
          ["Rallosian Power Gem"] = {
            aliases = {
              "Rallosian Power Gem",
            },
            ids = {
            },
            item = "Rallosian Power Gem",
          },
          ["Resilient Sphere"] = {
            aliases = {
              "Resilient Sphere",
            },
            ids = {
            },
            item = "Resilient Sphere",
          },
          ["Shard of Phosphorescent Power"] = {
            aliases = {
              "Shard of Phosphorescent Power",
            },
            ids = {
            },
            item = "Shard of Phosphorescent Power",
          },
          ["Shard of True Power"] = {
            aliases = {
              "Shard of True Power",
            },
            ids = {
            },
            item = "Shard of True Power",
          },
          ["Shrunken Gnoll Head"] = {
            aliases = {
              "Shrunken Gnoll Head",
            },
            ids = {
            },
            item = "Shrunken Gnoll Head",
          },
          ["Staff of the Subjugator"] = {
            aliases = {
              "Staff of the Subjugator",
            },
            ids = {
            },
            item = "Staff of the Subjugator",
          },
          ["Vapor of Vitality"] = {
            aliases = {
              "Vapor of Vitality",
            },
            ids = {
            },
            item = "Vapor of Vitality",
          },
        },
        Monk = {
          ["Ancient Gnawbone"] = {
            aliases = {
              "Ancient Gnawbone",
            },
            ids = {
            },
            item = "Ancient Gnawbone",
          },
          ["Asp's Fang"] = {
            aliases = {
              "Asp's Fang",
            },
            ids = {
            },
            item = "Asp's Fang",
          },
          ["Authentic Treasure Map"] = {
            aliases = {
              "Authentic Treasure Map",
            },
            ids = {
            },
            item = "Authentic Treasure Map",
          },
          ["Bludgeon of the Brute"] = {
            aliases = {
              "Bludgeon of the Brute",
            },
            ids = {
            },
            item = "Bludgeon of the Brute",
          },
          ["Brilliant Geode"] = {
            aliases = {
              "Brilliant Geode",
            },
            ids = {
            },
            item = "Brilliant Geode",
          },
          ["Corrupted Netherstone"] = {
            aliases = {
              "Corrupted Netherstone",
            },
            ids = {
            },
            item = "Corrupted Netherstone",
          },
          ["Creepy Bone Chips"] = {
            aliases = {
              "Creepy Bone Chips",
            },
            ids = {
            },
            item = "Creepy Bone Chips",
          },
          ["Deep Emerald Stone"] = {
            aliases = {
              "Deep Emerald Stone",
            },
            ids = {
            },
            item = "Deep Emerald Stone",
          },
          ["Hardened Bone Shard"] = {
            aliases = {
              "Hardened Bone Shard",
            },
            ids = {
            },
            item = "Hardened Bone Shard",
          },
          ["Honed Geode Cluster"] = {
            aliases = {
              "Honed Geode Cluster",
            },
            ids = {
            },
            item = "Honed Geode Cluster",
          },
          ["Imbued Feather"] = {
            aliases = {
              "Imbued Feather",
            },
            ids = {
            },
            item = "Imbued Feather",
          },
          ["Lucent Crystal"] = {
            aliases = {
              "Lucent Crystal",
            },
            ids = {
            },
            item = "Lucent Crystal",
          },
          ["Luminescent Geode Cluster"] = {
            aliases = {
              "Luminescent Geode Cluster",
            },
            ids = {
            },
            item = "Luminescent Geode Cluster",
          },
          ["Mallet of the Marauder"] = {
            aliases = {
              "Mallet of the Marauder",
            },
            ids = {
            },
            item = "Mallet of the Marauder",
          },
          ["Radiant Geode"] = {
            aliases = {
              "Radiant Geode",
            },
            ids = {
            },
            item = "Radiant Geode",
          },
          ["Rallosian Power Gem"] = {
            aliases = {
              "Rallosian Power Gem",
            },
            ids = {
            },
            item = "Rallosian Power Gem",
          },
          ["Resilient Sphere"] = {
            aliases = {
              "Resilient Sphere",
            },
            ids = {
            },
            item = "Resilient Sphere",
          },
          ["Shard of Phosphorescent Power"] = {
            aliases = {
              "Shard of Phosphorescent Power",
            },
            ids = {
            },
            item = "Shard of Phosphorescent Power",
          },
          ["Shard of True Power"] = {
            aliases = {
              "Shard of True Power",
            },
            ids = {
            },
            item = "Shard of True Power",
          },
          ["Shrunken Gnoll Head"] = {
            aliases = {
              "Shrunken Gnoll Head",
            },
            ids = {
            },
            item = "Shrunken Gnoll Head",
          },
          ["Stone of Greatness"] = {
            aliases = {
              "Stone of Greatness",
            },
            ids = {
            },
            item = "Stone of Greatness",
          },
        },
        Necromancer = {
          ["Ancient Gnawbone"] = {
            aliases = {
              "Ancient Gnawbone",
            },
            ids = {
            },
            item = "Ancient Gnawbone",
          },
          ["Authentic Treasure Map"] = {
            aliases = {
              "Authentic Treasure Map",
            },
            ids = {
            },
            item = "Authentic Treasure Map",
          },
          ["Brilliant Geode"] = {
            aliases = {
              "Brilliant Geode",
            },
            ids = {
            },
            item = "Brilliant Geode",
          },
          ["Corrupted Netherstone"] = {
            aliases = {
              "Corrupted Netherstone",
            },
            ids = {
            },
            item = "Corrupted Netherstone",
          },
          ["Creepy Bone Chips"] = {
            aliases = {
              "Creepy Bone Chips",
            },
            ids = {
            },
            item = "Creepy Bone Chips",
          },
          ["Hardened Bone Shard"] = {
            aliases = {
              "Hardened Bone Shard",
            },
            ids = {
            },
            item = "Hardened Bone Shard",
          },
          ["Honed Geode Cluster"] = {
            aliases = {
              "Honed Geode Cluster",
            },
            ids = {
            },
            item = "Honed Geode Cluster",
          },
          ["Imbued Feather"] = {
            aliases = {
              "Imbued Feather",
            },
            ids = {
            },
            item = "Imbued Feather",
          },
          ["Lucent Crystal"] = {
            aliases = {
              "Lucent Crystal",
            },
            ids = {
            },
            item = "Lucent Crystal",
          },
          ["Luminescent Geode Cluster"] = {
            aliases = {
              "Luminescent Geode Cluster",
            },
            ids = {
            },
            item = "Luminescent Geode Cluster",
          },
          ["Malevolent Effigy"] = {
            aliases = {
              "Malevolent Effigy",
            },
            ids = {
            },
            item = "Malevolent Effigy",
          },
          ["Rallosian Power Gem"] = {
            aliases = {
              "Rallosian Power Gem",
            },
            ids = {
            },
            item = "Rallosian Power Gem",
          },
          ["Resilient Sphere"] = {
            aliases = {
              "Resilient Sphere",
            },
            ids = {
            },
            item = "Resilient Sphere",
          },
          ["Shard of Phosphorescent Power"] = {
            aliases = {
              "Shard of Phosphorescent Power",
            },
            ids = {
            },
            item = "Shard of Phosphorescent Power",
          },
          ["Shard of True Power"] = {
            aliases = {
              "Shard of True Power",
            },
            ids = {
            },
            item = "Shard of True Power",
          },
          ["Shrunken Gnoll Head"] = {
            aliases = {
              "Shrunken Gnoll Head",
            },
            ids = {
            },
            item = "Shrunken Gnoll Head",
          },
          ["Staff of the Subjugator"] = {
            aliases = {
              "Staff of the Subjugator",
            },
            ids = {
            },
            item = "Staff of the Subjugator",
          },
          ["Vapor of Vitality"] = {
            aliases = {
              "Vapor of Vitality",
            },
            ids = {
            },
            item = "Vapor of Vitality",
          },
        },
        Paladin = {
          ["Ancient Gnawbone"] = {
            aliases = {
              "Ancient Gnawbone",
            },
            ids = {
            },
            item = "Ancient Gnawbone",
          },
          ["Asp's Fang"] = {
            aliases = {
              "Asp's Fang",
            },
            ids = {
            },
            item = "Asp's Fang",
          },
          ["Authentic Treasure Map"] = {
            aliases = {
              "Authentic Treasure Map",
            },
            ids = {
            },
            item = "Authentic Treasure Map",
          },
          ["Brilliant Geode"] = {
            aliases = {
              "Brilliant Geode",
            },
            ids = {
            },
            item = "Brilliant Geode",
          },
          ["Corrupted Netherstone"] = {
            aliases = {
              "Corrupted Netherstone",
            },
            ids = {
            },
            item = "Corrupted Netherstone",
          },
          ["Corundum Infused Granite"] = {
            aliases = {
              "Corundum Infused Granite",
            },
            ids = {
            },
            item = "Corundum Infused Granite",
          },
          ["Creepy Bone Chips"] = {
            aliases = {
              "Creepy Bone Chips",
            },
            ids = {
            },
            item = "Creepy Bone Chips",
          },
          ["Deep Emerald Stone"] = {
            aliases = {
              "Deep Emerald Stone",
            },
            ids = {
            },
            item = "Deep Emerald Stone",
          },
          ["Experimental Device"] = {
            aliases = {
              "Experimental Device",
            },
            ids = {
            },
            item = "Experimental Device",
          },
          ["Hardened Bone Shard"] = {
            aliases = {
              "Hardened Bone Shard",
            },
            ids = {
            },
            item = "Hardened Bone Shard",
          },
          ["Honed Geode Cluster"] = {
            aliases = {
              "Honed Geode Cluster",
            },
            ids = {
            },
            item = "Honed Geode Cluster",
          },
          ["Imbued Feather"] = {
            aliases = {
              "Imbued Feather",
            },
            ids = {
            },
            item = "Imbued Feather",
          },
          ["Lance of the Legionnaire"] = {
            aliases = {
              "Lance of the Legionnaire",
            },
            ids = {
            },
            item = "Lance of the Legionnaire",
          },
          ["Lucent Crystal"] = {
            aliases = {
              "Lucent Crystal",
            },
            ids = {
            },
            item = "Lucent Crystal",
          },
          ["Luminescent Geode Cluster"] = {
            aliases = {
              "Luminescent Geode Cluster",
            },
            ids = {
            },
            item = "Luminescent Geode Cluster",
          },
          ["Malevolent Effigy"] = {
            aliases = {
              "Malevolent Effigy",
            },
            ids = {
            },
            item = "Malevolent Effigy",
          },
          ["Radiant Geode"] = {
            aliases = {
              "Radiant Geode",
            },
            ids = {
            },
            item = "Radiant Geode",
          },
          ["Rallosian Power Gem"] = {
            aliases = {
              "Rallosian Power Gem",
            },
            ids = {
            },
            item = "Rallosian Power Gem",
          },
          ["Resilient Sphere"] = {
            aliases = {
              "Resilient Sphere",
            },
            ids = {
            },
            item = "Resilient Sphere",
          },
          ["Shard of Phosphorescent Power"] = {
            aliases = {
              "Shard of Phosphorescent Power",
            },
            ids = {
            },
            item = "Shard of Phosphorescent Power",
          },
          ["Shard of True Power"] = {
            aliases = {
              "Shard of True Power",
            },
            ids = {
            },
            item = "Shard of True Power",
          },
          ["Shrunken Gnoll Head"] = {
            aliases = {
              "Shrunken Gnoll Head",
            },
            ids = {
            },
            item = "Shrunken Gnoll Head",
          },
          ["Stone of Greatness"] = {
            aliases = {
              "Stone of Greatness",
            },
            ids = {
            },
            item = "Stone of Greatness",
          },
          ["Vapor of Vitality"] = {
            aliases = {
              "Vapor of Vitality",
            },
            ids = {
            },
            item = "Vapor of Vitality",
          },
          ["Void Rune of Sacrifice"] = {
            aliases = {
              "Void Rune of Sacrifice",
            },
            ids = {
            },
            item = "Void Rune of Sacrifice",
          },
        },
        Ranger = {
          ["Ancient Gnawbone"] = {
            aliases = {
              "Ancient Gnawbone",
            },
            ids = {
            },
            item = "Ancient Gnawbone",
          },
          ["Asp's Fang"] = {
            aliases = {
              "Asp's Fang",
            },
            ids = {
            },
            item = "Asp's Fang",
          },
          ["Authentic Treasure Map"] = {
            aliases = {
              "Authentic Treasure Map",
            },
            ids = {
            },
            item = "Authentic Treasure Map",
          },
          ["Bludgeon of the Brute"] = {
            aliases = {
              "Bludgeon of the Brute",
            },
            ids = {
            },
            item = "Bludgeon of the Brute",
          },
          ["Brilliant Geode"] = {
            aliases = {
              "Brilliant Geode",
            },
            ids = {
            },
            item = "Brilliant Geode",
          },
          ["Corrupted Netherstone"] = {
            aliases = {
              "Corrupted Netherstone",
            },
            ids = {
            },
            item = "Corrupted Netherstone",
          },
          ["Creepy Bone Chips"] = {
            aliases = {
              "Creepy Bone Chips",
            },
            ids = {
            },
            item = "Creepy Bone Chips",
          },
          ["Deep Emerald Stone"] = {
            aliases = {
              "Deep Emerald Stone",
            },
            ids = {
            },
            item = "Deep Emerald Stone",
          },
          ["Hardened Bone Shard"] = {
            aliases = {
              "Hardened Bone Shard",
            },
            ids = {
            },
            item = "Hardened Bone Shard",
          },
          ["Honed Geode Cluster"] = {
            aliases = {
              "Honed Geode Cluster",
            },
            ids = {
            },
            item = "Honed Geode Cluster",
          },
          ["Imbued Feather"] = {
            aliases = {
              "Imbued Feather",
            },
            ids = {
            },
            item = "Imbued Feather",
          },
          ["Lucent Crystal"] = {
            aliases = {
              "Lucent Crystal",
            },
            ids = {
            },
            item = "Lucent Crystal",
          },
          ["Luminescent Geode Cluster"] = {
            aliases = {
              "Luminescent Geode Cluster",
            },
            ids = {
            },
            item = "Luminescent Geode Cluster",
          },
          ["Malevolent Effigy"] = {
            aliases = {
              "Malevolent Effigy",
            },
            ids = {
            },
            item = "Malevolent Effigy",
          },
          ["Mallet of the Marauder"] = {
            aliases = {
              "Mallet of the Marauder",
            },
            ids = {
            },
            item = "Mallet of the Marauder",
          },
          ["Radiant Geode"] = {
            aliases = {
              "Radiant Geode",
            },
            ids = {
            },
            item = "Radiant Geode",
          },
          ["Rallosian Power Gem"] = {
            aliases = {
              "Rallosian Power Gem",
            },
            ids = {
            },
            item = "Rallosian Power Gem",
          },
          ["Resilient Sphere"] = {
            aliases = {
              "Resilient Sphere",
            },
            ids = {
            },
            item = "Resilient Sphere",
          },
          ["Shard of Phosphorescent Power"] = {
            aliases = {
              "Shard of Phosphorescent Power",
            },
            ids = {
            },
            item = "Shard of Phosphorescent Power",
          },
          ["Shard of True Power"] = {
            aliases = {
              "Shard of True Power",
            },
            ids = {
            },
            item = "Shard of True Power",
          },
          ["Shrunken Gnoll Head"] = {
            aliases = {
              "Shrunken Gnoll Head",
            },
            ids = {
            },
            item = "Shrunken Gnoll Head",
          },
          ["Stone of Greatness"] = {
            aliases = {
              "Stone of Greatness",
            },
            ids = {
            },
            item = "Stone of Greatness",
          },
          ["Vapor of Vitality"] = {
            aliases = {
              "Vapor of Vitality",
            },
            ids = {
            },
            item = "Vapor of Vitality",
          },
        },
        Rogue = {
          ["Ancient Gnawbone"] = {
            aliases = {
              "Ancient Gnawbone",
            },
            ids = {
            },
            item = "Ancient Gnawbone",
          },
          ["Asp's Fang"] = {
            aliases = {
              "Asp's Fang",
            },
            ids = {
            },
            item = "Asp's Fang",
          },
          ["Authentic Treasure Map"] = {
            aliases = {
              "Authentic Treasure Map",
            },
            ids = {
            },
            item = "Authentic Treasure Map",
          },
          ["Brilliant Geode"] = {
            aliases = {
              "Brilliant Geode",
            },
            ids = {
            },
            item = "Brilliant Geode",
          },
          ["Corrupted Netherstone"] = {
            aliases = {
              "Corrupted Netherstone",
            },
            ids = {
            },
            item = "Corrupted Netherstone",
          },
          ["Creepy Bone Chips"] = {
            aliases = {
              "Creepy Bone Chips",
            },
            ids = {
            },
            item = "Creepy Bone Chips",
          },
          ["Deep Emerald Stone"] = {
            aliases = {
              "Deep Emerald Stone",
            },
            ids = {
            },
            item = "Deep Emerald Stone",
          },
          ["Hardened Bone Shard"] = {
            aliases = {
              "Hardened Bone Shard",
            },
            ids = {
            },
            item = "Hardened Bone Shard",
          },
          ["Honed Geode Cluster"] = {
            aliases = {
              "Honed Geode Cluster",
            },
            ids = {
            },
            item = "Honed Geode Cluster",
          },
          ["Imbued Feather"] = {
            aliases = {
              "Imbued Feather",
            },
            ids = {
            },
            item = "Imbued Feather",
          },
          ["Lucent Crystal"] = {
            aliases = {
              "Lucent Crystal",
            },
            ids = {
            },
            item = "Lucent Crystal",
          },
          ["Luminescent Geode Cluster"] = {
            aliases = {
              "Luminescent Geode Cluster",
            },
            ids = {
            },
            item = "Luminescent Geode Cluster",
          },
          ["Mallet of the Marauder"] = {
            aliases = {
              "Mallet of the Marauder",
            },
            ids = {
            },
            item = "Mallet of the Marauder",
          },
          ["Radiant Geode"] = {
            aliases = {
              "Radiant Geode",
            },
            ids = {
            },
            item = "Radiant Geode",
          },
          ["Rallosian Power Gem"] = {
            aliases = {
              "Rallosian Power Gem",
            },
            ids = {
            },
            item = "Rallosian Power Gem",
          },
          ["Resilient Sphere"] = {
            aliases = {
              "Resilient Sphere",
            },
            ids = {
            },
            item = "Resilient Sphere",
          },
          ["Shard of Phosphorescent Power"] = {
            aliases = {
              "Shard of Phosphorescent Power",
            },
            ids = {
            },
            item = "Shard of Phosphorescent Power",
          },
          ["Shard of True Power"] = {
            aliases = {
              "Shard of True Power",
            },
            ids = {
            },
            item = "Shard of True Power",
          },
          ["Shrunken Gnoll Head"] = {
            aliases = {
              "Shrunken Gnoll Head",
            },
            ids = {
            },
            item = "Shrunken Gnoll Head",
          },
          ["Stone of Greatness"] = {
            aliases = {
              "Stone of Greatness",
            },
            ids = {
            },
            item = "Stone of Greatness",
          },
        },
        ["Shadow Knight"] = {
          ["Ancient Gnawbone"] = {
            aliases = {
              "Ancient Gnawbone",
            },
            ids = {
            },
            item = "Ancient Gnawbone",
          },
          ["Asp's Fang"] = {
            aliases = {
              "Asp's Fang",
            },
            ids = {
            },
            item = "Asp's Fang",
          },
          ["Authentic Treasure Map"] = {
            aliases = {
              "Authentic Treasure Map",
            },
            ids = {
            },
            item = "Authentic Treasure Map",
          },
          ["Brilliant Geode"] = {
            aliases = {
              "Brilliant Geode",
            },
            ids = {
            },
            item = "Brilliant Geode",
          },
          ["Corrupted Netherstone"] = {
            aliases = {
              "Corrupted Netherstone",
            },
            ids = {
            },
            item = "Corrupted Netherstone",
          },
          ["Corundum Infused Granite"] = {
            aliases = {
              "Corundum Infused Granite",
            },
            ids = {
            },
            item = "Corundum Infused Granite",
          },
          ["Creepy Bone Chips"] = {
            aliases = {
              "Creepy Bone Chips",
            },
            ids = {
            },
            item = "Creepy Bone Chips",
          },
          ["Deep Emerald Stone"] = {
            aliases = {
              "Deep Emerald Stone",
            },
            ids = {
            },
            item = "Deep Emerald Stone",
          },
          ["Experimental Device"] = {
            aliases = {
              "Experimental Device",
            },
            ids = {
            },
            item = "Experimental Device",
          },
          ["Hardened Bone Shard"] = {
            aliases = {
              "Hardened Bone Shard",
            },
            ids = {
            },
            item = "Hardened Bone Shard",
          },
          ["Honed Geode Cluster"] = {
            aliases = {
              "Honed Geode Cluster",
            },
            ids = {
            },
            item = "Honed Geode Cluster",
          },
          ["Imbued Feather"] = {
            aliases = {
              "Imbued Feather",
            },
            ids = {
            },
            item = "Imbued Feather",
          },
          ["Lance of the Legionnaire"] = {
            aliases = {
              "Lance of the Legionnaire",
            },
            ids = {
            },
            item = "Lance of the Legionnaire",
          },
          ["Lucent Crystal"] = {
            aliases = {
              "Lucent Crystal",
            },
            ids = {
            },
            item = "Lucent Crystal",
          },
          ["Luminescent Geode Cluster"] = {
            aliases = {
              "Luminescent Geode Cluster",
            },
            ids = {
            },
            item = "Luminescent Geode Cluster",
          },
          ["Malevolent Effigy"] = {
            aliases = {
              "Malevolent Effigy",
            },
            ids = {
            },
            item = "Malevolent Effigy",
          },
          ["Radiant Geode"] = {
            aliases = {
              "Radiant Geode",
            },
            ids = {
            },
            item = "Radiant Geode",
          },
          ["Rallosian Power Gem"] = {
            aliases = {
              "Rallosian Power Gem",
            },
            ids = {
            },
            item = "Rallosian Power Gem",
          },
          ["Resilient Sphere"] = {
            aliases = {
              "Resilient Sphere",
            },
            ids = {
            },
            item = "Resilient Sphere",
          },
          ["Shard of Phosphorescent Power"] = {
            aliases = {
              "Shard of Phosphorescent Power",
            },
            ids = {
            },
            item = "Shard of Phosphorescent Power",
          },
          ["Shard of True Power"] = {
            aliases = {
              "Shard of True Power",
            },
            ids = {
            },
            item = "Shard of True Power",
          },
          ["Shrunken Gnoll Head"] = {
            aliases = {
              "Shrunken Gnoll Head",
            },
            ids = {
            },
            item = "Shrunken Gnoll Head",
          },
          ["Stone of Greatness"] = {
            aliases = {
              "Stone of Greatness",
            },
            ids = {
            },
            item = "Stone of Greatness",
          },
          ["Vapor of Vitality"] = {
            aliases = {
              "Vapor of Vitality",
            },
            ids = {
            },
            item = "Vapor of Vitality",
          },
          ["Void Rune of Sacrifice"] = {
            aliases = {
              "Void Rune of Sacrifice",
            },
            ids = {
            },
            item = "Void Rune of Sacrifice",
          },
        },
        Shaman = {
          ["Ancient Gnawbone"] = {
            aliases = {
              "Ancient Gnawbone",
            },
            ids = {
            },
            item = "Ancient Gnawbone",
          },
          ["Authentic Treasure Map"] = {
            aliases = {
              "Authentic Treasure Map",
            },
            ids = {
            },
            item = "Authentic Treasure Map",
          },
          ["Brilliant Geode"] = {
            aliases = {
              "Brilliant Geode",
            },
            ids = {
            },
            item = "Brilliant Geode",
          },
          ["Corrupted Netherstone"] = {
            aliases = {
              "Corrupted Netherstone",
            },
            ids = {
            },
            item = "Corrupted Netherstone",
          },
          ["Creepy Bone Chips"] = {
            aliases = {
              "Creepy Bone Chips",
            },
            ids = {
            },
            item = "Creepy Bone Chips",
          },
          ["Hardened Bone Shard"] = {
            aliases = {
              "Hardened Bone Shard",
            },
            ids = {
            },
            item = "Hardened Bone Shard",
          },
          ["Honed Geode Cluster"] = {
            aliases = {
              "Honed Geode Cluster",
            },
            ids = {
            },
            item = "Honed Geode Cluster",
          },
          ["Imbued Feather"] = {
            aliases = {
              "Imbued Feather",
            },
            ids = {
            },
            item = "Imbued Feather",
          },
          ["Lucent Crystal"] = {
            aliases = {
              "Lucent Crystal",
            },
            ids = {
            },
            item = "Lucent Crystal",
          },
          ["Luminescent Geode Cluster"] = {
            aliases = {
              "Luminescent Geode Cluster",
            },
            ids = {
            },
            item = "Luminescent Geode Cluster",
          },
          ["Malevolent Effigy"] = {
            aliases = {
              "Malevolent Effigy",
            },
            ids = {
            },
            item = "Malevolent Effigy",
          },
          ["Rallosian Power Gem"] = {
            aliases = {
              "Rallosian Power Gem",
            },
            ids = {
            },
            item = "Rallosian Power Gem",
          },
          ["Resilient Sphere"] = {
            aliases = {
              "Resilient Sphere",
            },
            ids = {
            },
            item = "Resilient Sphere",
          },
          ["Shard of Phosphorescent Power"] = {
            aliases = {
              "Shard of Phosphorescent Power",
            },
            ids = {
            },
            item = "Shard of Phosphorescent Power",
          },
          ["Shard of True Power"] = {
            aliases = {
              "Shard of True Power",
            },
            ids = {
            },
            item = "Shard of True Power",
          },
          ["Shrunken Gnoll Head"] = {
            aliases = {
              "Shrunken Gnoll Head",
            },
            ids = {
            },
            item = "Shrunken Gnoll Head",
          },
          ["Staff of the Subjugator"] = {
            aliases = {
              "Staff of the Subjugator",
            },
            ids = {
            },
            item = "Staff of the Subjugator",
          },
          ["Vapor of Vitality"] = {
            aliases = {
              "Vapor of Vitality",
            },
            ids = {
            },
            item = "Vapor of Vitality",
          },
        },
        Warrior = {
          ["Ancient Gnawbone"] = {
            aliases = {
              "Ancient Gnawbone",
            },
            ids = {
            },
            item = "Ancient Gnawbone",
          },
          ["Asp's Fang"] = {
            aliases = {
              "Asp's Fang",
            },
            ids = {
            },
            item = "Asp's Fang",
          },
          ["Authentic Treasure Map"] = {
            aliases = {
              "Authentic Treasure Map",
            },
            ids = {
            },
            item = "Authentic Treasure Map",
          },
          ["Bludgeon of the Brute"] = {
            aliases = {
              "Bludgeon of the Brute",
            },
            ids = {
            },
            item = "Bludgeon of the Brute",
          },
          ["Brilliant Geode"] = {
            aliases = {
              "Brilliant Geode",
            },
            ids = {
            },
            item = "Brilliant Geode",
          },
          ["Corrupted Netherstone"] = {
            aliases = {
              "Corrupted Netherstone",
            },
            ids = {
            },
            item = "Corrupted Netherstone",
          },
          ["Corundum Infused Granite"] = {
            aliases = {
              "Corundum Infused Granite",
            },
            ids = {
            },
            item = "Corundum Infused Granite",
          },
          ["Creepy Bone Chips"] = {
            aliases = {
              "Creepy Bone Chips",
            },
            ids = {
            },
            item = "Creepy Bone Chips",
          },
          ["Deep Emerald Stone"] = {
            aliases = {
              "Deep Emerald Stone",
            },
            ids = {
            },
            item = "Deep Emerald Stone",
          },
          ["Experimental Device"] = {
            aliases = {
              "Experimental Device",
            },
            ids = {
            },
            item = "Experimental Device",
          },
          ["Hardened Bone Shard"] = {
            aliases = {
              "Hardened Bone Shard",
            },
            ids = {
            },
            item = "Hardened Bone Shard",
          },
          ["Honed Geode Cluster"] = {
            aliases = {
              "Honed Geode Cluster",
            },
            ids = {
            },
            item = "Honed Geode Cluster",
          },
          ["Imbued Feather"] = {
            aliases = {
              "Imbued Feather",
            },
            ids = {
            },
            item = "Imbued Feather",
          },
          ["Lucent Crystal"] = {
            aliases = {
              "Lucent Crystal",
            },
            ids = {
            },
            item = "Lucent Crystal",
          },
          ["Luminescent Geode Cluster"] = {
            aliases = {
              "Luminescent Geode Cluster",
            },
            ids = {
            },
            item = "Luminescent Geode Cluster",
          },
          ["Mallet of the Marauder"] = {
            aliases = {
              "Mallet of the Marauder",
            },
            ids = {
            },
            item = "Mallet of the Marauder",
          },
          ["Radiant Geode"] = {
            aliases = {
              "Radiant Geode",
            },
            ids = {
            },
            item = "Radiant Geode",
          },
          ["Rallosian Power Gem"] = {
            aliases = {
              "Rallosian Power Gem",
            },
            ids = {
            },
            item = "Rallosian Power Gem",
          },
          ["Resilient Sphere"] = {
            aliases = {
              "Resilient Sphere",
            },
            ids = {
            },
            item = "Resilient Sphere",
          },
          ["Shard of Phosphorescent Power"] = {
            aliases = {
              "Shard of Phosphorescent Power",
            },
            ids = {
            },
            item = "Shard of Phosphorescent Power",
          },
          ["Shard of True Power"] = {
            aliases = {
              "Shard of True Power",
            },
            ids = {
            },
            item = "Shard of True Power",
          },
          ["Shrunken Gnoll Head"] = {
            aliases = {
              "Shrunken Gnoll Head",
            },
            ids = {
            },
            item = "Shrunken Gnoll Head",
          },
          ["Stone of Greatness"] = {
            aliases = {
              "Stone of Greatness",
            },
            ids = {
            },
            item = "Stone of Greatness",
          },
          ["Void Rune of Sacrifice"] = {
            aliases = {
              "Void Rune of Sacrifice",
            },
            ids = {
            },
            item = "Void Rune of Sacrifice",
          },
        },
        Wizard = {
          ["Ancient Gnawbone"] = {
            aliases = {
              "Ancient Gnawbone",
            },
            ids = {
            },
            item = "Ancient Gnawbone",
          },
          ["Authentic Treasure Map"] = {
            aliases = {
              "Authentic Treasure Map",
            },
            ids = {
            },
            item = "Authentic Treasure Map",
          },
          ["Brilliant Geode"] = {
            aliases = {
              "Brilliant Geode",
            },
            ids = {
            },
            item = "Brilliant Geode",
          },
          ["Corrupted Netherstone"] = {
            aliases = {
              "Corrupted Netherstone",
            },
            ids = {
            },
            item = "Corrupted Netherstone",
          },
          ["Creepy Bone Chips"] = {
            aliases = {
              "Creepy Bone Chips",
            },
            ids = {
            },
            item = "Creepy Bone Chips",
          },
          ["Hardened Bone Shard"] = {
            aliases = {
              "Hardened Bone Shard",
            },
            ids = {
            },
            item = "Hardened Bone Shard",
          },
          ["Honed Geode Cluster"] = {
            aliases = {
              "Honed Geode Cluster",
            },
            ids = {
            },
            item = "Honed Geode Cluster",
          },
          ["Imbued Feather"] = {
            aliases = {
              "Imbued Feather",
            },
            ids = {
            },
            item = "Imbued Feather",
          },
          ["Lucent Crystal"] = {
            aliases = {
              "Lucent Crystal",
            },
            ids = {
            },
            item = "Lucent Crystal",
          },
          ["Luminescent Geode Cluster"] = {
            aliases = {
              "Luminescent Geode Cluster",
            },
            ids = {
            },
            item = "Luminescent Geode Cluster",
          },
          ["Malevolent Effigy"] = {
            aliases = {
              "Malevolent Effigy",
            },
            ids = {
            },
            item = "Malevolent Effigy",
          },
          ["Rallosian Power Gem"] = {
            aliases = {
              "Rallosian Power Gem",
            },
            ids = {
            },
            item = "Rallosian Power Gem",
          },
          ["Resilient Sphere"] = {
            aliases = {
              "Resilient Sphere",
            },
            ids = {
            },
            item = "Resilient Sphere",
          },
          ["Shard of Phosphorescent Power"] = {
            aliases = {
              "Shard of Phosphorescent Power",
            },
            ids = {
            },
            item = "Shard of Phosphorescent Power",
          },
          ["Shard of True Power"] = {
            aliases = {
              "Shard of True Power",
            },
            ids = {
            },
            item = "Shard of True Power",
          },
          ["Shrunken Gnoll Head"] = {
            aliases = {
              "Shrunken Gnoll Head",
            },
            ids = {
            },
            item = "Shrunken Gnoll Head",
          },
          ["Staff of the Subjugator"] = {
            aliases = {
              "Staff of the Subjugator",
            },
            ids = {
            },
            item = "Staff of the Subjugator",
          },
          ["Vapor of Vitality"] = {
            aliases = {
              "Vapor of Vitality",
            },
            ids = {
            },
            item = "Vapor of Vitality",
          },
        },
      },
      group = "Other Checklists",
      id = "llhcitems",
      name = "Lower Level HC Items",
      show_base = {
      },
      template = {
        ["Ancient Gnawbone"] = {
          aliases = {
            "Ancient Gnawbone",
          },
          ids = {
          },
          item = "Ancient Gnawbone",
        },
        ["Authentic Treasure Map"] = {
          aliases = {
            "Authentic Treasure Map",
          },
          ids = {
          },
          item = "Authentic Treasure Map",
        },
        ["Brilliant Geode"] = {
          aliases = {
            "Brilliant Geode",
          },
          ids = {
          },
          item = "Brilliant Geode",
        },
        ["Creepy Bone Chips"] = {
          aliases = {
            "Creepy Bone Chips",
          },
          ids = {
          },
          item = "Creepy Bone Chips",
        },
        ["Hardened Bone Shard"] = {
          aliases = {
            "Hardened Bone Shard",
          },
          ids = {
          },
          item = "Hardened Bone Shard",
        },
        ["Honed Geode Cluster"] = {
          aliases = {
            "Honed Geode Cluster",
          },
          ids = {
          },
          item = "Honed Geode Cluster",
        },
        ["Imbued Feather"] = {
          aliases = {
            "Imbued Feather",
          },
          ids = {
          },
          item = "Imbued Feather",
        },
        ["Lucent Crystal"] = {
          aliases = {
            "Lucent Crystal",
          },
          ids = {
          },
          item = "Lucent Crystal",
        },
        ["Luminescent Geode Cluster"] = {
          aliases = {
            "Luminescent Geode Cluster",
          },
          ids = {
          },
          item = "Luminescent Geode Cluster",
        },
        ["Rallosian Power Gem"] = {
          aliases = {
            "Rallosian Power Gem",
          },
          ids = {
          },
          item = "Rallosian Power Gem",
        },
        ["Resilient Sphere"] = {
          aliases = {
            "Resilient Sphere",
          },
          ids = {
          },
          item = "Resilient Sphere",
        },
        ["Shard of Phosphorescent Power"] = {
          aliases = {
            "Shard of Phosphorescent Power",
          },
          ids = {
          },
          item = "Shard of Phosphorescent Power",
        },
        ["Shard of True Power"] = {
          aliases = {
            "Shard of True Power",
          },
          ids = {
          },
          item = "Shard of True Power",
        },
      },
      visible = {
      },
    },
    nightveil = {
      categories = {
        {
          name = "Nightveil Augs",
          slots = {
            "Codex",
            "PrimaryAug",
            "SecondaryAug",
            "RangeAug",
          },
        },
      },
      classes = {
        Bard = {
          PrimaryAug = {
            aliases = {
              "Oval Aspect of Venom",
            },
            ids = {
            },
            item = "Oval Aspect of Venom",
          },
          RangeAug = {
            aliases = {
              "Oval Aspect of Exchange",
            },
            ids = {
            },
            item = "Oval Aspect of Exchange",
          },
          SecondaryAug = {
            aliases = {
              "Oval Aspect of Flame",
            },
            ids = {
            },
            item = "Oval Aspect of Flame",
          },
        },
        Beastlord = {
          PrimaryAug = {
            aliases = {
              "Oval Aspect of Vampirism",
            },
            ids = {
            },
            item = "Oval Aspect of Vampirism",
          },
          RangeAug = {
            aliases = {
              "Marquise Aspect of Venom",
            },
            ids = {
            },
            item = "Marquise Aspect of Venom",
          },
          SecondaryAug = {
            aliases = {
              "Marquise Aspect of Frost",
            },
            ids = {
            },
            item = "Marquise Aspect of Frost",
          },
        },
        Berserker = {
          PrimaryAug = {
            aliases = {
              "Pear Aspect of Chaos",
            },
            ids = {
            },
            item = "Pear Aspect of Chaos",
          },
          RangeAug = {
            aliases = {
              "Oval Aspect of Exchange",
            },
            ids = {
            },
            item = "Oval Aspect of Exchange",
          },
        },
        Cleric = {
          PrimaryAug = {
            aliases = {
              "Trilliant Aspect of Survival",
            },
            ids = {
            },
            item = "Trilliant Aspect of Survival",
          },
          RangeAug = {
            aliases = {
              "Trilliant Aspect of Exchange",
            },
            ids = {
            },
            item = "Trilliant Aspect of Exchange",
          },
        },
        Druid = {
          PrimaryAug = {
            aliases = {
              "Trilliant Aspect of Survival",
            },
            ids = {
            },
            item = "Trilliant Aspect of Survival",
          },
          RangeAug = {
            aliases = {
              "Trilliant Aspect of Exchange",
            },
            ids = {
            },
            item = "Trilliant Aspect of Exchange",
          },
        },
        Enchanter = {
          PrimaryAug = {
            aliases = {
              "Marquise Aspect of Lightning",
            },
            ids = {
            },
            item = "Marquise Aspect of Lightning",
          },
          RangeAug = {
            aliases = {
              "Marquise Aspect of Exchange",
            },
            ids = {
            },
            item = "Marquise Aspect of Exchange",
          },
          SecondaryAug = {
            aliases = {
              "Marquise Aspect of Enduring",
            },
            ids = {
            },
            item = "Marquise Aspect of Enduring",
          },
        },
        Magician = {
          PrimaryAug = {
            aliases = {
              "Marquise Aspect of Flame",
            },
            ids = {
            },
            item = "Marquise Aspect of Flame",
          },
          RangeAug = {
            aliases = {
              "Marquise Aspect of Exchange",
            },
            ids = {
            },
            item = "Marquise Aspect of Exchange",
          },
          SecondaryAug = {
            aliases = {
              "Marquise Aspect of Lightning",
            },
            ids = {
            },
            item = "Marquise Aspect of Lightning",
          },
        },
        Monk = {
          PrimaryAug = {
            aliases = {
              "Oval Aspect of Chaos",
            },
            ids = {
            },
            item = "Oval Aspect of Chaos",
          },
          RangeAug = {
            aliases = {
              "Oval Aspect of Exchange",
            },
            ids = {
            },
            item = "Oval Aspect of Exchange",
          },
          SecondaryAug = {
            aliases = {
              "Oval Aspect of Venom",
            },
            ids = {
            },
            item = "Oval Aspect of Venom",
          },
        },
        Necromancer = {
          PrimaryAug = {
            aliases = {
              "Marquise Aspect of Vampirism",
            },
            ids = {
            },
            item = "Marquise Aspect of Vampirism",
          },
          RangeAug = {
            aliases = {
              "Marquise Aspect of Exchange",
            },
            ids = {
            },
            item = "Marquise Aspect of Exchange",
          },
          SecondaryAug = {
            aliases = {
              "Marquise Aspect of Lightning",
            },
            ids = {
            },
            item = "Marquise Aspect of Lightning",
          },
        },
        Paladin = {
          PrimaryAug = {
            aliases = {
              "Square Aspect of Survival",
            },
            ids = {
            },
            item = "Square Aspect of Survival",
          },
          RangeAug = {
            aliases = {
              "Square Aspect of Exchange",
            },
            ids = {
            },
            item = "Square Aspect of Exchange",
          },
        },
        Ranger = {
          PrimaryAug = {
            aliases = {
              "Marquise Aspect of Frost",
            },
            ids = {
            },
            item = "Marquise Aspect of Frost",
          },
          RangeAug = {
            aliases = {
              "Oval Aspect of Chaos",
            },
            ids = {
            },
            item = "Oval Aspect of Chaos",
          },
          SecondaryAug = {
            aliases = {
              "Marquise Aspect of Flame",
            },
            ids = {
            },
            item = "Marquise Aspect of Flame",
          },
        },
        Rogue = {
          PrimaryAug = {
            aliases = {
              "Oval Aspect of Chaos",
            },
            ids = {
            },
            item = "Oval Aspect of Chaos",
          },
          RangeAug = {
            aliases = {
              "Oval Aspect of Exchange",
            },
            ids = {
            },
            item = "Oval Aspect of Exchange",
          },
          SecondaryAug = {
            aliases = {
              "Oval Aspect of Venom",
            },
            ids = {
            },
            item = "Oval Aspect of Venom",
          },
        },
        ["Shadow Knight"] = {
          PrimaryAug = {
            aliases = {
              "Square Aspect of Survival",
            },
            ids = {
            },
            item = "Square Aspect of Survival",
          },
          RangeAug = {
            aliases = {
              "Square Aspect of Exchange",
            },
            ids = {
            },
            item = "Square Aspect of Exchange",
          },
        },
        Shaman = {
          PrimaryAug = {
            aliases = {
              "Trilliant Aspect of Survival",
            },
            ids = {
            },
            item = "Trilliant Aspect of Survival",
          },
          RangeAug = {
            aliases = {
              "Trilliant Aspect of Exchange",
            },
            ids = {
            },
            item = "Trilliant Aspect of Exchange",
          },
        },
        Warrior = {
          PrimaryAug = {
            aliases = {
              "Square Aspect of Survival",
            },
            ids = {
            },
            item = "Square Aspect of Survival",
          },
          RangeAug = {
            aliases = {
              "Square Aspect of Exchange",
            },
            ids = {
            },
            item = "Square Aspect of Exchange",
          },
        },
        Wizard = {
          PrimaryAug = {
            aliases = {
              "Marquise Aspect of Flame",
            },
            ids = {
            },
            item = "Marquise Aspect of Flame",
          },
          RangeAug = {
            aliases = {
              "Marquise Aspect of Exchange",
            },
            ids = {
            },
            item = "Marquise Aspect of Exchange",
          },
          SecondaryAug = {
            aliases = {
              "Marquise Aspect of Lightning",
            },
            ids = {
            },
            item = "Marquise Aspect of Lightning",
          },
        },
      },
      group = "Other Checklists",
      id = "nightveil",
      name = "Nightveil",
      show_base = {
      },
      template = {
        Codex = {
          aliases = {
            "Codex of Numbers",
          },
          ids = {
          },
          item = "Codex of Numbers",
        },
      },
      visible = {
      },
    },
    preanguish = {
      categories = {
        {
          name = "Visibles",
          slots = {
            "Arms",
            "Chest",
            "Feet",
            "Hands",
            "Head",
            "Legs",
            "Wrist1",
            "Wrist2",
          },
        },
        {
          name = "Non-Visibles",
          slots = {
            "Back",
            "Ear1",
            "Ear2",
            "Face",
            "Finger1",
            "Finger2",
            "Neck",
            "Shoulder",
            "Waist",
          },
        },
        {
          name = "Weapons",
          slots = {
            "MainHand",
            "Secondary",
            "Range",
            "Charm",
          },
        },
        {
          name = "Clickies",
          slots = {
            "Clicky1",
            "Clicky2",
            "Clicky3",
            "Clicky4",
            "Clicky5",
            "Clicky6",
            "Clicky7",
          },
        },
        {
          name = "Augments",
          slots = {
            "Aug1",
            "Aug2",
            "Aug3",
            "Aug4",
            "Aug5",
            "Aug6",
            "Aug7",
            "Aug8",
          },
        },
        {
          name = "PoP_Slot(3)",
          slots = {
            "PoPAug1",
            "PoPAug2",
          },
        },
        {
          name = "GoD_Slot(3)",
          slots = {
            "GoDAug1",
            "GoDAug2",
            "GoDAug3",
            "GoDAug4",
          },
        },
      },
      classes = {
        Bard = {
          Arms = {
            aliases = {
              "Armplates of Endless Fortitude",
            },
            ids = {
              47204,
            },
            item = "Armplates of Endless Fortitude",
          },
          Back = {
            aliases = {
              "Two-Toned Fur Cape",
            },
            ids = {
              47248,
            },
            item = "Two-Toned Fur Cape",
          },
          Charm = {
            aliases = {
              "Grim Idol of the Brute",
            },
            ids = {
              150111,
            },
            item = "Grim Idol of the Brute",
          },
          Chest = {
            aliases = {
              "Luvwen's Chestplate of Melody",
            },
            ids = {
              68968,
            },
            item = "Luvwen's Chestplate of Melody",
          },
          Clicky1 = {
            aliases = {
              "Veil of the Inferno",
            },
            ids = {
              9435,
            },
            item = "Veil of the Inferno",
          },
          Clicky2 = {
            aliases = {
              "Cloak of Retribution",
            },
            ids = {
              15842,
            },
            item = "Cloak of Retribution",
          },
          Clicky3 = {
            aliases = {
              "Ring of Organic Darkness",
            },
            ids = {
              69131,
            },
            item = "Ring of Organic Darkness",
          },
          Clicky4 = {
            aliases = {
              "Prismatic Ring of Resistance",
            },
            ids = {
              26989,
            },
            item = "Prismatic Ring of Resistance",
          },
          Ear1 = {
            aliases = {
              "Earring of Mental Incursion",
            },
            ids = {
              47233,
            },
            item = "Earring of Mental Incursion",
          },
          Ear2 = {
            aliases = {
              "Stud of Focused Aptitude",
            },
            ids = {
              47236,
            },
            item = "Stud of Focused Aptitude",
          },
          Face = {
            aliases = {
              "Cynin's Mask",
            },
            ids = {
              70718,
            },
            item = "Cynin's Mask",
          },
          Feet = {
            aliases = {
              "Boots of Shifting Time",
            },
            ids = {
              47216,
            },
            item = "Boots of Shifting Time",
          },
          Finger1 = {
            aliases = {
              "Ring of the Serpent",
            },
            ids = {
              69160,
            },
            item = "Ring of the Serpent",
          },
          Finger2 = {
            aliases = {
              "Bloodband of Malice",
            },
            ids = {
              47237,
            },
            item = "Bloodband of Malice",
          },
          Hands = {
            aliases = {
              "Gauntlets of Singular Mastery",
            },
            ids = {
              47212,
            },
            item = "Gauntlets of Singular Mastery",
          },
          Head = {
            aliases = {
              "Hammered Helm of Foresight",
            },
            ids = {
              47208,
            },
            item = "Hammered Helm of Foresight",
          },
          Legs = {
            aliases = {
              "Greaves of Seething Rage",
            },
            ids = {
              47200,
            },
            item = "Greaves of Seething Rage",
          },
          MainHand = {
            aliases = {
              "Prismatic Dragon Blade",
            },
            ids = {
              77631,
            },
            item = "Prismatic Dragon Blade",
          },
          Neck = {
            aliases = {
              "Assistant Researcher's Symbol",
            },
            ids = {
              67625,
            },
            item = "Assistant Researcher's Symbol",
          },
          PoPAug1 = {
            aliases = {
              "Planar Alloy of Escalating Onslaught",
            },
            ids = {
              10412,
            },
            item = "Planar Alloy of Escalating Onslaught",
          },
          Range = {
            aliases = {
              "Screaming Skull of Discontent",
            },
            ids = {
              47242,
            },
            item = "Screaming Skull of Discontent",
          },
          Secondary = {
            aliases = {
              "Rapier of Somber Notes",
            },
            ids = {
              69114,
            },
            item = "Rapier of Somber Notes",
          },
          Shoulder = {
            aliases = {
              "Pauldron of Dark Auspices",
            },
            ids = {
              69130,
            },
            item = "Pauldron of Dark Auspices",
          },
          Waist = {
            aliases = {
              "Belt of Inevitable Conversion",
            },
            ids = {
              47232,
            },
            item = "Belt of Inevitable Conversion",
          },
          Wrist1 = {
            aliases = {
              "Xxeric's Battleworn Bracer",
            },
            ids = {
              69126,
            },
            item = "Xxeric's Battleworn Bracer",
          },
          Wrist2 = {
            aliases = {
              "Bracer of the Debauched",
            },
            ids = {
              47220,
            },
            item = "Bracer of the Debauched",
          },
        },
        Beastlord = {
          Arms = {
            aliases = {
              "Sleeves of the Steadfast",
            },
            ids = {
              47206,
            },
            item = "Sleeves of the Steadfast",
          },
          Aug1 = {
            aliases = {
              "Velrek's Enchanted Prism",
            },
            ids = {
              68020,
            },
            item = "Velrek's Enchanted Prism",
          },
          Back = {
            aliases = {
              "Cloak of the Faithless",
            },
            ids = {
              47249,
            },
            item = "Cloak of the Faithless",
          },
          Charm = {
            aliases = {
              "Grim Idol of the Brute",
            },
            ids = {
              150111,
            },
            item = "Grim Idol of the Brute",
          },
          Chest = {
            aliases = {
              "Yelnia's Tunic",
            },
            ids = {
              70702,
            },
            item = "Yelnia's Tunic",
          },
          Clicky1 = {
            aliases = {
              "Veil of the Inferno",
            },
            ids = {
              9435,
            },
            item = "Veil of the Inferno",
          },
          Clicky2 = {
            aliases = {
              "Cloak of Retribution",
            },
            ids = {
              15842,
            },
            item = "Cloak of Retribution",
          },
          Clicky3 = {
            aliases = {
              "Ring of Organic Darkness",
            },
            ids = {
              69131,
            },
            item = "Ring of Organic Darkness",
          },
          Clicky4 = {
            aliases = {
              "Prismatic Ring of Resistance",
            },
            ids = {
              26989,
            },
            item = "Prismatic Ring of Resistance",
          },
          Clicky5 = {
            aliases = {
              "Wand of the Vortex",
            },
            ids = {
              26899,
            },
            item = "Wand of the Vortex",
          },
          Ear1 = {
            aliases = {
              "Earring of Mental Incursion",
            },
            ids = {
              47233,
            },
            item = "Earring of Mental Incursion",
          },
          Ear2 = {
            aliases = {
              "Stud of Focused Aptitude",
            },
            ids = {
              47236,
            },
            item = "Stud of Focused Aptitude",
          },
          Face = {
            aliases = {
              "Mask of Uncanny Sight",
            },
            ids = {
              47245,
            },
            item = "Mask of Uncanny Sight",
          },
          Feet = {
            aliases = {
              "Kira's Slippers",
            },
            ids = {
            },
            item = "Kira's Slippers",
          },
          Finger1 = {
            aliases = {
              "Ring of the Serpent",
            },
            ids = {
              69160,
            },
            item = "Ring of the Serpent",
          },
          Finger2 = {
            aliases = {
              "Bloodband of Malice",
            },
            ids = {
              47237,
            },
            item = "Bloodband of Malice",
          },
          Hands = {
            aliases = {
              "Gloves of Coalesced Flame",
            },
            ids = {
              69254,
            },
            item = "Gloves of Coalesced Flame",
          },
          Head = {
            aliases = {
              "Headband of Heightened Cognizance",
            },
            ids = {
              47210,
            },
            item = "Headband of Heightened Cognizance",
          },
          Legs = {
            aliases = {
              "Leggings of Fearsome Deeds",
            },
            ids = {
              47202,
            },
            item = "Leggings of Fearsome Deeds",
          },
          MainHand = {
            aliases = {
              "Savage Lord's Totem",
            },
            ids = {
              52911,
            },
            item = "Savage Lord's Totem",
          },
          Neck = {
            aliases = {
              "Sapphire Choker of Adaptation",
            },
            ids = {
              47226,
            },
            item = "Sapphire Choker of Adaptation",
          },
          PoPAug1 = {
            aliases = {
              "Planar Alloy of Escalating Onslaught",
            },
            ids = {
              10412,
            },
            item = "Planar Alloy of Escalating Onslaught",
          },
          Range = {
            aliases = {
              "Ruby of Determined Assault",
            },
            ids = {
              69158,
            },
            item = "Ruby of Determined Assault",
          },
          Secondary = {
            aliases = {
              "Fangs of the Serpent",
            },
            ids = {
              47259,
            },
            item = "Fangs of the Serpent",
          },
          Shoulder = {
            aliases = {
              "Whispering Amice",
            },
            ids = {
              68955,
            },
            item = "Whispering Amice",
          },
          Waist = {
            aliases = {
              "Belt of Inevitable Conversion",
            },
            ids = {
              47232,
            },
            item = "Belt of Inevitable Conversion",
          },
          Wrist1 = {
            aliases = {
              "Bracer of Grievous Harm",
            },
            ids = {
              69128,
            },
            item = "Bracer of Grievous Harm",
          },
          Wrist2 = {
            aliases = {
              "Wristband of Chaotic Warfare",
            },
            ids = {
              69099,
            },
            item = "Wristband of Chaotic Warfare",
          },
        },
        Berserker = {
          Arms = {
            aliases = {
              "Crystal Mail Sleeves",
            },
            ids = {
              70711,
            },
            item = "Crystal Mail Sleeves",
          },
          Back = {
            aliases = {
              "Cloak of the Faithless",
            },
            ids = {
              47249,
            },
            item = "Cloak of the Faithless",
          },
          Charm = {
            aliases = {
              "Grim Idol of the Brute",
            },
            ids = {
              150111,
            },
            item = "Grim Idol of the Brute",
          },
          Chest = {
            aliases = {
              "Bloodlink Chestmail",
            },
            ids = {
              68780,
            },
            item = "Bloodlink Chestmail",
          },
          Clicky1 = {
            aliases = {
              "Veil of the Inferno",
            },
            ids = {
              9435,
            },
            item = "Veil of the Inferno",
          },
          Clicky2 = {
            aliases = {
              "Cloak of Retribution",
            },
            ids = {
              15842,
            },
            item = "Cloak of Retribution",
          },
          Clicky3 = {
            aliases = {
              "Ring of Organic Darkness",
            },
            ids = {
              69131,
            },
            item = "Ring of Organic Darkness",
          },
          Clicky4 = {
            aliases = {
              "Prismatic Ring of Resistance",
            },
            ids = {
              26989,
            },
            item = "Prismatic Ring of Resistance",
          },
          Ear1 = {
            aliases = {
              "Earring of Mental Incursion",
            },
            ids = {
              47233,
            },
            item = "Earring of Mental Incursion",
          },
          Ear2 = {
            aliases = {
              "Stud of Focused Aptitude",
            },
            ids = {
              47236,
            },
            item = "Stud of Focused Aptitude",
          },
          Face = {
            aliases = {
              "Mask of Uncanny Sight",
            },
            ids = {
              47245,
            },
            item = "Mask of Uncanny Sight",
          },
          Feet = {
            aliases = {
              "Harlad's Boots of Fury",
            },
            ids = {
              68893,
            },
            item = "Harlad's Boots of Fury",
          },
          Finger1 = {
            aliases = {
              "Ring of Fluid Perception",
            },
            ids = {
              47239,
            },
            item = "Ring of Fluid Perception",
          },
          Finger2 = {
            aliases = {
              "Bloodband of Malice47239",
            },
            ids = {
            },
            item = "Bloodband of Malice47239",
          },
          Hands = {
            aliases = {
              "Runed Gauntlets of the Void",
            },
            ids = {
              69253,
            },
            item = "Runed Gauntlets of the Void",
          },
          Head = {
            aliases = {
              "Headband of the Endless Night",
            },
            ids = {
              69088,
            },
            item = "Headband of the Endless Night",
          },
          Legs = {
            aliases = {
              "Tunat'Muram's Bloodied Greaves",
            },
            ids = {
              69147,
            },
            item = "Tunat'Muram's Bloodied Greaves",
          },
          MainHand = {
            aliases = {
              "Raging Taelosian Alloy Axe",
            },
            ids = {
              18398,
            },
            item = "Raging Taelosian Alloy Axe",
          },
          Neck = {
            aliases = {
              "Sapphire Choker of Adaptation",
            },
            ids = {
              47226,
            },
            item = "Sapphire Choker of Adaptation",
          },
          PoPAug1 = {
            aliases = {
              "Planar Alloy of Escalating Onslaught",
            },
            ids = {
              10412,
            },
            item = "Planar Alloy of Escalating Onslaught",
          },
          PoPAug2 = {
            aliases = {
              "Focus Rune of Furious Assault",
            },
            ids = {
              150030,
            },
            item = "Focus Rune of Furious Assault",
          },
          Range = {
            aliases = {
              "Ruby of Determined Assault",
            },
            ids = {
              69158,
            },
            item = "Ruby of Determined Assault",
          },
          Secondary = {
            aliases = {
              "-NA-",
            },
            ids = {
            },
            item = "-NA-",
          },
          Shoulder = {
            aliases = {
              "Ilsin's Mantle",
            },
            ids = {
              70717,
            },
            item = "Ilsin's Mantle",
          },
          Waist = {
            aliases = {
              "Belt of Inevitable Conversion",
            },
            ids = {
              47232,
            },
            item = "Belt of Inevitable Conversion",
          },
          Wrist1 = {
            aliases = {
              "Wristguard of Chaotic Essence",
            },
            ids = {
              69127,
            },
            item = "Wristguard of Chaotic Essence",
          },
          Wrist2 = {
            aliases = {
              "Red Crystal Bracer",
            },
            ids = {
              70619,
            },
            item = "Red Crystal Bracer",
          },
        },
        Cleric = {
          Arms = {
            aliases = {
              "Armplates of Endless Fortitude",
            },
            ids = {
              47204,
            },
            item = "Armplates of Endless Fortitude",
          },
          Back = {
            aliases = {
              "Cloak of Nightmarish Visions",
            },
            ids = {
              69164,
            },
            item = "Cloak of Nightmarish Visions",
          },
          Charm = {
            aliases = {
              "Fetish of Irreverent Knowledge",
            },
            ids = {
              150112,
            },
            item = "Fetish of Irreverent Knowledge",
          },
          Chest = {
            aliases = {
              "Crystal Breastplate",
            },
            ids = {
              70701,
            },
            item = "Crystal Breastplate",
          },
          Clicky1 = {
            aliases = {
              "Earring of Pain Deliverance",
            },
            ids = {
              69133,
            },
            item = "Earring of Pain Deliverance",
          },
          Clicky2 = {
            aliases = {
              "Loop of Endless Insanity",
            },
            ids = {
              68957,
            },
            item = "Loop of Endless Insanity",
          },
          Clicky3 = {
            aliases = {
              "Mantle of Corruption",
            },
            ids = {
              69163,
            },
            item = "Mantle of Corruption",
          },
          Clicky4 = {
            aliases = {
              "Prismatic Ring of Resistance",
            },
            ids = {
              26989,
            },
            item = "Prismatic Ring of Resistance",
          },
          Clicky5 = {
            aliases = {
              "Wand of the Vortex",
            },
            ids = {
              26899,
            },
            item = "Wand of the Vortex",
          },
          Clicky6 = {
            aliases = {
              "Aged Shissar Apothic Staff",
            },
            ids = {
              69437,
            },
            item = "Aged Shissar Apothic Staff",
            source = "Hoshkar",
          },
          Clicky7 = {
            aliases = {
              "Weighted Hammer of Conviction",
            },
            ids = {
              69111,
            },
            item = "Weighted Hammer of Conviction",
            source = "Zun'Muram Kvxe Pirik",
          },
          Ear1 = {
            aliases = {
              "Loop of Entropic Hues",
            },
            ids = {
              69166,
            },
            item = "Loop of Entropic Hues",
          },
          Ear2 = {
            aliases = {
              "Clawed Earring of Determination",
            },
            ids = {
              47234,
            },
            item = "Clawed Earring of Determination",
          },
          Face = {
            aliases = {
              "Xxeric's Matted-Fur Mask",
            },
            ids = {
              69132,
            },
            item = "Xxeric's Matted-Fur Mask",
          },
          Feet = {
            aliases = {
              "Dakkamor's Boots of the Divine",
            },
            ids = {
              68858,
            },
            item = "Dakkamor's Boots of the Divine",
          },
          Finger1 = {
            aliases = {
              "Ring of the Serpent",
            },
            ids = {
              69160,
            },
            item = "Ring of the Serpent",
          },
          Finger2 = {
            aliases = {
              "Ring of Ire Intent",
            },
            ids = {
              47240,
            },
            item = "Ring of Ire Intent",
          },
          GoDAug1 = {
            aliases = {
              "Discordian Alloy of Tenacity",
            },
            ids = {
              150041,
            },
            item = "Discordian Alloy of Tenacity",
          },
          Hands = {
            aliases = {
              "Crystal Gauntlets",
            },
            ids = {
              70723,
            },
            item = "Crystal Gauntlets",
          },
          Head = {
            aliases = {
              "Hammered Helm of Foresight",
            },
            ids = {
              47208,
            },
            item = "Hammered Helm of Foresight",
          },
          Legs = {
            aliases = {
              "Dakkamor's Legplates of the Divine",
            },
            ids = {
              68963,
            },
            item = "Dakkamor's Legplates of the Divine",
          },
          MainHand = {
            aliases = {
              "Wand of Twisted Fate",
            },
            ids = {
              47251,
            },
            item = "Wand of Twisted Fate",
          },
          Neck = {
            aliases = {
              "Zulaqua's Necklace",
            },
            ids = {
              70705,
            },
            item = "Zulaqua's Necklace",
          },
          Range = {
            aliases = {
              "Tome of New Beginnings",
            },
            ids = {
              67606,
            },
            item = "Tome of New Beginnings",
          },
          Secondary = {
            aliases = {
              "Harmony of the Soul",
            },
            ids = {
              9955,
            },
            item = "Harmony of the Soul",
          },
          Shoulder = {
            aliases = {
              "Mantle of Corruption",
            },
            ids = {
              69163,
            },
            item = "Mantle of Corruption",
          },
          Waist = {
            aliases = {
              "Scyllus' Belt",
            },
            ids = {
              70716,
            },
            item = "Scyllus' Belt",
          },
          Wrist1 = {
            aliases = {
              "Xxeric's Battleworn Bracer",
            },
            ids = {
              69126,
            },
            item = "Xxeric's Battleworn Bracer",
          },
          Wrist2 = {
            aliases = {
              "Bracer of the Debauched",
            },
            ids = {
              47220,
            },
            item = "Bracer of the Debauched",
          },
        },
        Druid = {
          Arms = {
            aliases = {
              "Sleeves of the Steadfast",
            },
            ids = {
              47206,
            },
            item = "Sleeves of the Steadfast",
          },
          Aug1 = {
            aliases = {
              "Velrek's Enchanted Prism",
            },
            ids = {
              68020,
            },
            item = "Velrek's Enchanted Prism",
          },
          Back = {
            aliases = {
              "Cloak of Nightmarish Visions",
            },
            ids = {
              69164,
            },
            item = "Cloak of Nightmarish Visions",
          },
          Charm = {
            aliases = {
              "Fetish of Irreverent Knowledge",
            },
            ids = {
              150112,
            },
            item = "Fetish of Irreverent Knowledge",
          },
          Chest = {
            aliases = {
              "Yelnia's Tunic",
            },
            ids = {
              70702,
            },
            item = "Yelnia's Tunic",
          },
          Clicky1 = {
            aliases = {
              "Earring of Pain Deliverance",
            },
            ids = {
              69133,
            },
            item = "Earring of Pain Deliverance",
          },
          Clicky2 = {
            aliases = {
              "Loop of Endless Insanity",
            },
            ids = {
              68957,
            },
            item = "Loop of Endless Insanity",
          },
          Clicky3 = {
            aliases = {
              "Mantle of Corruption",
            },
            ids = {
              69163,
            },
            item = "Mantle of Corruption",
          },
          Clicky4 = {
            aliases = {
              "Prismatic Ring of Resistance",
            },
            ids = {
              26989,
            },
            item = "Prismatic Ring of Resistance",
          },
          Clicky5 = {
            aliases = {
              "Wand of the Vortex",
            },
            ids = {
              26899,
            },
            item = "Wand of the Vortex",
          },
          Clicky6 = {
            aliases = {
              "Aged Dragon Spine Staff",
            },
            ids = {
              69413,
            },
            item = "Aged Dragon Spine Staff",
            source = "Silverwing",
          },
          Clicky7 = {
            aliases = {
              "Kelp-Covered Hammer",
            },
            ids = {
              69119,
            },
            item = "Kelp-Covered Hammer",
            source = "Zun'Muram Shaldn Boc",
          },
          Ear1 = {
            aliases = {
              "Loop of Entropic Hues",
            },
            ids = {
              69166,
            },
            item = "Loop of Entropic Hues",
          },
          Ear2 = {
            aliases = {
              "Clawed Earring of Determination",
            },
            ids = {
              47234,
            },
            item = "Clawed Earring of Determination",
          },
          Face = {
            aliases = {
              "Xxeric's Matted-Fur Mask",
            },
            ids = {
              69132,
            },
            item = "Xxeric's Matted-Fur Mask",
          },
          Feet = {
            aliases = {
              "Sandals of Constant Change",
            },
            ids = {
              47218,
            },
            item = "Sandals of Constant Change",
          },
          Finger1 = {
            aliases = {
              "Ring of the Serpent",
            },
            ids = {
              69160,
            },
            item = "Ring of the Serpent",
          },
          Finger2 = {
            aliases = {
              "Ring of Ire Intent",
            },
            ids = {
              47240,
            },
            item = "Ring of Ire Intent",
          },
          GoDAug1 = {
            aliases = {
              "Discordian Alloy of Tenacity",
            },
            ids = {
              150041,
            },
            item = "Discordian Alloy of Tenacity",
          },
          GoDAug2 = {
            aliases = {
              "Focus Shard of Aggregate Annihilation",
            },
            ids = {
              41142,
            },
            item = "Focus Shard of Aggregate Annihilation",
          },
          GoDAug3 = {
            aliases = {
              "Focus Shard of Destruction",
            },
            ids = {
              150047,
            },
            item = "Focus Shard of Destruction",
          },
          GoDAug4 = {
            aliases = {
              "Volatile Discordian Rune",
            },
            ids = {
              150040,
            },
            item = "Volatile Discordian Rune",
          },
          Hands = {
            aliases = {
              "Gloves of the Adept",
            },
            ids = {
              47214,
            },
            item = "Gloves of the Adept",
          },
          Head = {
            aliases = {
              "Headband of Heightened Cognizance",
            },
            ids = {
              47210,
            },
            item = "Headband of Heightened Cognizance",
          },
          Legs = {
            aliases = {
              "Leggings of Fearsome Deeds",
            },
            ids = {
              47202,
            },
            item = "Leggings of Fearsome Deeds",
          },
          MainHand = {
            aliases = {
              "Staff of Everliving Brambles",
            },
            ids = {
              62880,
            },
            item = "Staff of Everliving Brambles",
          },
          Neck = {
            aliases = {
              "Zulaqua's Necklace",
            },
            ids = {
              70705,
            },
            item = "Zulaqua's Necklace",
          },
          PoPAug1 = {
            aliases = {
              "Volatile Planar Rune",
            },
            ids = {
              150033,
            },
            item = "Volatile Planar Rune",
          },
          Range = {
            aliases = {
              "Tome of New Beginnings",
            },
            ids = {
              67606,
            },
            item = "Tome of New Beginnings",
          },
          Secondary = {
            aliases = {
              "Lana's Crystal Shield",
            },
            ids = {
              70708,
            },
            item = "Lana's Crystal Shield",
          },
          Shoulder = {
            aliases = {
              "Mantle of Corruption",
            },
            ids = {
              69163,
            },
            item = "Mantle of Corruption",
          },
          Waist = {
            aliases = {
              "Cord of the Malcontent",
            },
            ids = {
              47231,
            },
            item = "Cord of the Malcontent",
          },
          Wrist1 = {
            aliases = {
              "Bracer of Grievous Harm",
            },
            ids = {
              69128,
            },
            item = "Bracer of Grievous Harm",
          },
          Wrist2 = {
            aliases = {
              "Muramite's Heavy Shackles",
            },
            ids = {
              69100,
            },
            item = "Muramite's Heavy Shackles",
          },
        },
        Enchanter = {
          Arms = {
            aliases = {
              "Sleeves of Malefic Rapture",
            },
            ids = {
              69176,
            },
            item = "Sleeves of Malefic Rapture",
          },
          Aug1 = {
            aliases = {
              "Velrek's Enchanted Prism",
            },
            ids = {
              68020,
            },
            item = "Velrek's Enchanted Prism",
          },
          Back = {
            aliases = {
              "Cloak of Nightmarish Visions",
            },
            ids = {
              69164,
            },
            item = "Cloak of Nightmarish Visions",
          },
          Charm = {
            aliases = {
              "Fetish of Irreverent Knowledge",
            },
            ids = {
              150112,
            },
            item = "Fetish of Irreverent Knowledge",
          },
          Chest = {
            aliases = {
              "Crystal Silk Robe",
            },
            ids = {
              70714,
            },
            item = "Crystal Silk Robe",
          },
          Clicky1 = {
            aliases = {
              "Earring of Pain Deliverance",
            },
            ids = {
              69133,
            },
            item = "Earring of Pain Deliverance",
          },
          Clicky2 = {
            aliases = {
              "Loop of Endless Insanity",
            },
            ids = {
              68957,
            },
            item = "Loop of Endless Insanity",
          },
          Clicky3 = {
            aliases = {
              "Mantle of Corruption",
            },
            ids = {
              69163,
            },
            item = "Mantle of Corruption",
          },
          Clicky4 = {
            aliases = {
              "Wand of the Vortex",
            },
            ids = {
              26899,
            },
            item = "Wand of the Vortex",
          },
          Clicky5 = {
            aliases = {
              "Aged Shissar Focus Staff",
            },
            ids = {
              69431,
            },
            item = "Aged Shissar Focus Staff",
            source = "Druushk",
          },
          Clicky6 = {
            aliases = {
              "Hammer of Delusions",
            },
            ids = {
              69125,
            },
            item = "Hammer of Delusions",
            source = "Zun'Muram Shaldn Boc",
          },
          Ear1 = {
            aliases = {
              "Loop of Entropic Hues",
            },
            ids = {
              69166,
            },
            item = "Loop of Entropic Hues",
          },
          Ear2 = {
            aliases = {
              "Clawed Earring of Determination",
            },
            ids = {
              47234,
            },
            item = "Clawed Earring of Determination",
          },
          Face = {
            aliases = {
              "Xxeric's Matted-Fur Mask",
            },
            ids = {
              69132,
            },
            item = "Xxeric's Matted-Fur Mask",
          },
          Feet = {
            aliases = {
              "Supple Slippers of Transformation",
            },
            ids = {
              47219,
            },
            item = "Supple Slippers of Transformation",
          },
          Finger1 = {
            aliases = {
              "Band of Eternal Gaze",
            },
            ids = {
              47238,
            },
            item = "Band of Eternal Gaze",
          },
          Finger2 = {
            aliases = {
              "Ring of Ire Intent",
            },
            ids = {
              47240,
            },
            item = "Ring of Ire Intent",
          },
          GoDAug1 = {
            aliases = {
              "Focus Shard of Aggregate Annihilation",
            },
            ids = {
              41142,
            },
            item = "Focus Shard of Aggregate Annihilation",
          },
          GoDAug2 = {
            aliases = {
              "Focus Shard of Destruction",
            },
            ids = {
              150047,
            },
            item = "Focus Shard of Destruction",
          },
          GoDAug3 = {
            aliases = {
              "Volatile Discordian Rune",
            },
            ids = {
              150040,
            },
            item = "Volatile Discordian Rune",
          },
          Hands = {
            aliases = {
              "Laced Gloves of Superiority",
            },
            ids = {
              47215,
            },
            item = "Laced Gloves of Superiority",
          },
          Head = {
            aliases = {
              "Twisted Crown of Consciousness",
            },
            ids = {
              47211,
            },
            item = "Twisted Crown of Consciousness",
          },
          Legs = {
            aliases = {
              "Envenomed Leggings of Enmity",
            },
            ids = {
              47203,
            },
            item = "Envenomed Leggings of Enmity",
          },
          MainHand = {
            aliases = {
              "Oculus of Persuasion",
            },
            ids = {
              52952,
            },
            item = "Oculus of Persuasion",
          },
          Neck = {
            aliases = {
              "Zulaqua's Necklace",
            },
            ids = {
              70705,
            },
            item = "Zulaqua's Necklace",
          },
          PoPAug1 = {
            aliases = {
              "Volatile Planar Rune",
            },
            ids = {
              150033,
            },
            item = "Volatile Planar Rune",
          },
          Range = {
            aliases = {
              "Tome of New Beginnings",
            },
            ids = {
              67606,
            },
            item = "Tome of New Beginnings",
          },
          Secondary = {
            aliases = {
              "Lana's Crystal Shield",
            },
            ids = {
              70708,
            },
            item = "Lana's Crystal Shield",
          },
          Shoulder = {
            aliases = {
              "Mantle of Corruption",
            },
            ids = {
              69163,
            },
            item = "Mantle of Corruption",
          },
          Waist = {
            aliases = {
              "Cord of the Malcontent",
            },
            ids = {
              47231,
            },
            item = "Cord of the Malcontent",
          },
          Wrist1 = {
            aliases = {
              "Bracelet of the Corrupter",
            },
            ids = {
              47223,
            },
            item = "Bracelet of the Corrupter",
          },
          Wrist2 = {
            aliases = {
              "Muramite's Heavy Shackles",
            },
            ids = {
              69100,
            },
            item = "Muramite's Heavy Shackles",
          },
        },
        Magician = {
          Arms = {
            aliases = {
              "Sleeves of Malefic Rapture",
            },
            ids = {
              69176,
            },
            item = "Sleeves of Malefic Rapture",
          },
          Aug1 = {
            aliases = {
              "Velrek's Enchanted Prism",
            },
            ids = {
              68020,
            },
            item = "Velrek's Enchanted Prism",
          },
          Back = {
            aliases = {
              "Cloak of Nightmarish Visions",
            },
            ids = {
              69164,
            },
            item = "Cloak of Nightmarish Visions",
          },
          Charm = {
            aliases = {
              "Fetish of Irreverent Knowledge",
            },
            ids = {
              150112,
            },
            item = "Fetish of Irreverent Knowledge",
          },
          Chest = {
            aliases = {
              "Crystal Silk Robe",
            },
            ids = {
              70714,
            },
            item = "Crystal Silk Robe",
          },
          Clicky1 = {
            aliases = {
              "Earring of Pain Deliverance",
            },
            ids = {
              69133,
            },
            item = "Earring of Pain Deliverance",
          },
          Clicky2 = {
            aliases = {
              "Loop of Endless Insanity",
            },
            ids = {
              68957,
            },
            item = "Loop of Endless Insanity",
          },
          Clicky3 = {
            aliases = {
              "Mantle of Corruption",
            },
            ids = {
              69163,
            },
            item = "Mantle of Corruption",
          },
          Clicky4 = {
            aliases = {
              "Wand of the Vortex",
            },
            ids = {
              26899,
            },
            item = "Wand of the Vortex",
          },
          Clicky5 = {
            aliases = {
              "Aged Sarnak Channeler Staff",
            },
            ids = {
              69417,
            },
            item = "Aged Sarnak Channeler Staff",
            source = "Druushk",
          },
          Clicky6 = {
            aliases = {
              "Dagger of Evil Summons",
            },
            ids = {
              69124,
            },
            item = "Dagger of Evil Summons",
            source = "Zun'Muram Mordl Delt",
          },
          Ear1 = {
            aliases = {
              "Loop of Entropic Hues",
            },
            ids = {
              69166,
            },
            item = "Loop of Entropic Hues",
          },
          Ear2 = {
            aliases = {
              "Clawed Earring of Determination",
            },
            ids = {
              47234,
            },
            item = "Clawed Earring of Determination",
          },
          Face = {
            aliases = {
              "Xxeric's Matted-Fur Mask",
            },
            ids = {
              69132,
            },
            item = "Xxeric's Matted-Fur Mask",
          },
          Feet = {
            aliases = {
              "Supple Slippers of Transformation",
            },
            ids = {
              47219,
            },
            item = "Supple Slippers of Transformation",
          },
          Finger1 = {
            aliases = {
              "Band of Eternal Gaze",
            },
            ids = {
              47238,
            },
            item = "Band of Eternal Gaze",
          },
          Finger2 = {
            aliases = {
              "Ring of Ire Intent",
            },
            ids = {
              47240,
            },
            item = "Ring of Ire Intent",
          },
          GoDAug1 = {
            aliases = {
              "Focus Shard of Aggregate Annihilation",
            },
            ids = {
              41142,
            },
            item = "Focus Shard of Aggregate Annihilation",
          },
          GoDAug2 = {
            aliases = {
              "Focus Shard of Destruction",
            },
            ids = {
              150047,
            },
            item = "Focus Shard of Destruction",
          },
          GoDAug3 = {
            aliases = {
              "Volatile Discordian Rune",
            },
            ids = {
              150040,
            },
            item = "Volatile Discordian Rune",
          },
          Hands = {
            aliases = {
              "Gloves of Wicked Ambition",
            },
            ids = {
              69255,
            },
            item = "Gloves of Wicked Ambition",
          },
          Head = {
            aliases = {
              "Twisted Crown of Consciousness",
            },
            ids = {
              47211,
            },
            item = "Twisted Crown of Consciousness",
          },
          Legs = {
            aliases = {
              "Envenomed Leggings of Enmity",
            },
            ids = {
              47203,
            },
            item = "Envenomed Leggings of Enmity",
          },
          MainHand = {
            aliases = {
              "Focus of Primal Elements",
            },
            ids = {
              19839,
            },
            item = "Focus of Primal Elements",
          },
          Neck = {
            aliases = {
              "Zulaqua's Necklace",
            },
            ids = {
              70705,
            },
            item = "Zulaqua's Necklace",
          },
          PoPAug1 = {
            aliases = {
              "Volatile Planar Rune",
            },
            ids = {
              150033,
            },
            item = "Volatile Planar Rune",
          },
          Range = {
            aliases = {
              "Tome of New Beginnings",
            },
            ids = {
              67606,
            },
            item = "Tome of New Beginnings",
          },
          Secondary = {
            aliases = {
              "Lana's Crystal Shield",
            },
            ids = {
              70708,
            },
            item = "Lana's Crystal Shield",
          },
          Shoulder = {
            aliases = {
              "Mantle of Corruption",
            },
            ids = {
              69163,
            },
            item = "Mantle of Corruption",
          },
          Waist = {
            aliases = {
              "Cord of the Malcontent",
            },
            ids = {
              47231,
            },
            item = "Cord of the Malcontent",
          },
          Wrist1 = {
            aliases = {
              "Bracelet of the Corrupter",
            },
            ids = {
              47223,
            },
            item = "Bracelet of the Corrupter",
          },
          Wrist2 = {
            aliases = {
              "Muramite's Heavy Shackles",
            },
            ids = {
              69100,
            },
            item = "Muramite's Heavy Shackles",
          },
        },
        Monk = {
          Arms = {
            aliases = {
              "Sleeves of the Steadfast",
            },
            ids = {
              47206,
            },
            item = "Sleeves of the Steadfast",
          },
          Aug1 = {
            aliases = {
              "Velrek's Enchanted Prism",
            },
            ids = {
              68020,
            },
            item = "Velrek's Enchanted Prism",
          },
          Back = {
            aliases = {
              "Cloak of the Faithless",
            },
            ids = {
            },
            item = "Cloak of the Faithless",
          },
          Charm = {
            aliases = {
              "Grim Idol of the Brute",
            },
            ids = {
              150111,
            },
            item = "Grim Idol of the Brute",
          },
          Chest = {
            aliases = {
              "Yelnia's Tunic",
            },
            ids = {
            },
            item = "Yelnia's Tunic",
          },
          Clicky1 = {
            aliases = {
              "Veil of the Inferno",
            },
            ids = {
              9435,
            },
            item = "Veil of the Inferno",
          },
          Clicky2 = {
            aliases = {
              "Cloak of Retribution",
            },
            ids = {
              15842,
            },
            item = "Cloak of Retribution",
          },
          Clicky3 = {
            aliases = {
              "Ring of Organic Darkness",
            },
            ids = {
              69131,
            },
            item = "Ring of Organic Darkness",
          },
          Clicky4 = {
            aliases = {
              "Prismatic Ring of Resistance",
            },
            ids = {
              26989,
            },
            item = "Prismatic Ring of Resistance",
          },
          Ear1 = {
            aliases = {
              "Earring of Mental Incursion",
            },
            ids = {
            },
            item = "Earring of Mental Incursion",
          },
          Ear2 = {
            aliases = {
              "Stud of Focused Aptitude",
            },
            ids = {
            },
            item = "Stud of Focused Aptitude",
          },
          Face = {
            aliases = {
              "Mask of Uncanny Sight",
            },
            ids = {
            },
            item = "Mask of Uncanny Sight",
          },
          Feet = {
            aliases = {
              "Kira's Slippers",
            },
            ids = {
            },
            item = "Kira's Slippers",
          },
          Finger1 = {
            aliases = {
              "Ring of Fluid Perception",
            },
            ids = {
            },
            item = "Ring of Fluid Perception",
          },
          Finger2 = {
            aliases = {
              "Bloodband of Malice",
            },
            ids = {
            },
            item = "Bloodband of Malice",
          },
          Hands = {
            aliases = {
              "Gloves of Coalesced Flame",
            },
            ids = {
              69254,
            },
            item = "Gloves of Coalesced Flame",
          },
          Head = {
            aliases = {
              "Headband of Heightened Cognizance",
            },
            ids = {
              47210,
            },
            item = "Headband of Heightened Cognizance",
          },
          Legs = {
            aliases = {
              "Leggings of Fearsome Deeds",
            },
            ids = {
            },
            item = "Leggings of Fearsome Deeds",
          },
          MainHand = {
            aliases = {
              "Fistwraps of Celestial Discipline",
            },
            ids = {
              61025,
            },
            item = "Fistwraps of Celestial Discipline",
          },
          Neck = {
            aliases = {
              "Sapphire Choker of Adaptation",
            },
            ids = {
            },
            item = "Sapphire Choker of Adaptation",
          },
          PoPAug1 = {
            aliases = {
              "Planar Alloy of Escalating Onslaught",
            },
            ids = {
              10412,
            },
            item = "Planar Alloy of Escalating Onslaught",
          },
          PoPAug2 = {
            aliases = {
              "Focus Rune of Dexterous Striking",
            },
            ids = {
              150031,
            },
            item = "Focus Rune of Dexterous Striking",
          },
          Range = {
            aliases = {
              "Ruby of Determined Assault",
            },
            ids = {
              69158,
            },
            item = "Ruby of Determined Assault",
          },
          Secondary = {
            aliases = {
              "Fangs of the Serpent",
            },
            ids = {
            },
            item = "Fangs of the Serpent",
          },
          Shoulder = {
            aliases = {
              "Ilsin's Mantle",
            },
            ids = {
            },
            item = "Ilsin's Mantle",
          },
          Waist = {
            aliases = {
              "Belt of Inevitable Conversion",
            },
            ids = {
            },
            item = "Belt of Inevitable Conversion",
          },
          Wrist1 = {
            aliases = {
              "Bracer of Grievous Harm",
            },
            ids = {
            },
            item = "Bracer of Grievous Harm",
          },
          Wrist2 = {
            aliases = {
              "Wristband of Chaotic Warfare",
            },
            ids = {
            },
            item = "Wristband of Chaotic Warfare",
          },
        },
        Necromancer = {
          Arms = {
            aliases = {
              "Sleeves of Malefic Rapture",
            },
            ids = {
              69176,
            },
            item = "Sleeves of Malefic Rapture",
          },
          Aug1 = {
            aliases = {
              "Velrek's Enchanted Prism",
            },
            ids = {
              68020,
            },
            item = "Velrek's Enchanted Prism",
          },
          Back = {
            aliases = {
              "Cloak of Nightmarish Visions",
            },
            ids = {
              69164,
            },
            item = "Cloak of Nightmarish Visions",
          },
          Charm = {
            aliases = {
              "Fetish of Irreverent Knowledge",
            },
            ids = {
              150112,
            },
            item = "Fetish of Irreverent Knowledge",
          },
          Chest = {
            aliases = {
              "Crystal Silk Robe",
            },
            ids = {
              70714,
            },
            item = "Crystal Silk Robe",
          },
          Clicky1 = {
            aliases = {
              "Earring of Pain Deliverance",
            },
            ids = {
              69133,
            },
            item = "Earring of Pain Deliverance",
          },
          Clicky2 = {
            aliases = {
              "Loop of Endless Insanity",
            },
            ids = {
              68957,
            },
            item = "Loop of Endless Insanity",
          },
          Clicky3 = {
            aliases = {
              "Mantle of Corruption",
            },
            ids = {
              69163,
            },
            item = "Mantle of Corruption",
          },
          Clicky4 = {
            aliases = {
              "Wand of the Vortex",
            },
            ids = {
              26899,
            },
            item = "Wand of the Vortex",
          },
          Clicky5 = {
            aliases = {
              "Aged Shissar Deathspeaker Staff",
            },
            ids = {
              69432,
            },
            item = "Aged Shissar Deathspeaker Staff",
            source = "Druushk",
          },
          Clicky6 = {
            aliases = {
              "Dagger of Death",
            },
            ids = {
              69123,
            },
            item = "Dagger of Death",
            source = "Zun'Muram Yihst Vor",
          },
          Ear1 = {
            aliases = {
              "Loop of Entropic Hues",
            },
            ids = {
              69166,
            },
            item = "Loop of Entropic Hues",
          },
          Ear2 = {
            aliases = {
              "Clawed Earring of Determination",
            },
            ids = {
              47234,
            },
            item = "Clawed Earring of Determination",
          },
          Face = {
            aliases = {
              "Xxeric's Matted-Fur Mask",
            },
            ids = {
              69132,
            },
            item = "Xxeric's Matted-Fur Mask",
          },
          Feet = {
            aliases = {
              "Supple Slippers of Transformation",
            },
            ids = {
              47219,
            },
            item = "Supple Slippers of Transformation",
          },
          Finger1 = {
            aliases = {
              "Band of Eternal Gaze",
            },
            ids = {
              47238,
            },
            item = "Band of Eternal Gaze",
          },
          Finger2 = {
            aliases = {
              "Ring of Ire Intent",
            },
            ids = {
              47240,
            },
            item = "Ring of Ire Intent",
          },
          GoDAug1 = {
            aliases = {
              "Focus Shard of Aggregate Annihilation",
            },
            ids = {
              41142,
            },
            item = "Focus Shard of Aggregate Annihilation",
          },
          GoDAug2 = {
            aliases = {
              "Focus Shard of Destruction",
            },
            ids = {
              150047,
            },
            item = "Focus Shard of Destruction",
          },
          GoDAug3 = {
            aliases = {
              "Volatile Discordian Rune",
            },
            ids = {
              150040,
            },
            item = "Volatile Discordian Rune",
          },
          Hands = {
            aliases = {
              "Laced Gloves of Superiority",
            },
            ids = {
              47215,
            },
            item = "Laced Gloves of Superiority",
          },
          Head = {
            aliases = {
              "Twisted Crown of Consciousness",
            },
            ids = {
              47211,
            },
            item = "Twisted Crown of Consciousness",
          },
          Legs = {
            aliases = {
              "Envenomed Leggings of Enmity",
            },
            ids = {
              47203,
            },
            item = "Envenomed Leggings of Enmity",
          },
          MainHand = {
            aliases = {
              "Soulwhisper",
            },
            ids = {
              62581,
            },
            item = "Soulwhisper",
          },
          Neck = {
            aliases = {
              "Zulaqua's Necklace",
            },
            ids = {
              70705,
            },
            item = "Zulaqua's Necklace",
          },
          Range = {
            aliases = {
              "Tome of New Beginnings",
            },
            ids = {
              67606,
            },
            item = "Tome of New Beginnings",
          },
          Secondary = {
            aliases = {
              "Lana's Crystal Shield",
            },
            ids = {
              70708,
            },
            item = "Lana's Crystal Shield",
          },
          Shoulder = {
            aliases = {
              "Mantle of Corruption",
            },
            ids = {
              69163,
            },
            item = "Mantle of Corruption",
          },
          Waist = {
            aliases = {
              "Cord of the Malcontent",
            },
            ids = {
              47231,
            },
            item = "Cord of the Malcontent",
          },
          Wrist1 = {
            aliases = {
              "Bracelet of the Corrupter",
            },
            ids = {
              47223,
            },
            item = "Bracelet of the Corrupter",
          },
          Wrist2 = {
            aliases = {
              "Muramite's Heavy Shackles",
            },
            ids = {
              69100,
            },
            item = "Muramite's Heavy Shackles",
          },
        },
        Paladin = {
          Arms = {
            aliases = {
              "Armguards of Insidious Corruption",
            },
            ids = {
              69168,
            },
            item = "Armguards of Insidious Corruption",
          },
          Aug1 = {
            aliases = {
              "Hulcror Pearl",
            },
            ids = {
              70694,
            },
            item = "Hulcror Pearl",
          },
          Aug2 = {
            aliases = {
              "Enchanted Orb of Defense",
            },
            ids = {
              68019,
            },
            item = "Enchanted Orb of Defense",
          },
          Aug3 = {
            aliases = {
              "Glyphed Sandstone",
            },
            ids = {
              68800,
            },
            item = "Glyphed Sandstone",
          },
          Aug4 = {
            aliases = {
              "Blessed Shard",
            },
            ids = {
              68667,
            },
            item = "Blessed Shard",
          },
          Aug5 = {
            aliases = {
              "Experimental Gem of Enhanced Protection",
            },
            ids = {
              68048,
            },
            item = "Experimental Gem of Enhanced Protection",
          },
          Aug6 = {
            aliases = {
              "Frosty Gem of Enhanced Protection",
            },
            ids = {
              68107,
            },
            item = "Frosty Gem of Enhanced Protection",
          },
          Aug7 = {
            aliases = {
              "Guardian's Stone of Enhanced Protection",
            },
            ids = {
              68049,
            },
            item = "Guardian's Stone of Enhanced Protection",
          },
          Aug8 = {
            aliases = {
              "Yenner's Rock of Enhanced Protection",
            },
            ids = {
              68047,
            },
            item = "Yenner's Rock of Enhanced Protection",
          },
          Back = {
            aliases = {
              "Two-Toned Fur Cape",
            },
            ids = {
              47248,
            },
            item = "Two-Toned Fur Cape",
          },
          Charm = {
            aliases = {
              "Grim Idol of the Brute",
            },
            ids = {
              150111,
            },
            item = "Grim Idol of the Brute",
          },
          Chest = {
            aliases = {
              "Trimdet's Chestplate of Chivalry",
            },
            ids = {
              68964,
            },
            item = "Trimdet's Chestplate of Chivalry",
          },
          Clicky1 = {
            aliases = {
              "Band of Primordial Energy",
            },
            ids = {
              26990,
            },
            item = "Band of Primordial Energy",
          },
          Clicky2 = {
            aliases = {
              "Cloak of Retribution",
            },
            ids = {
              15842,
            },
            item = "Cloak of Retribution",
          },
          Clicky3 = {
            aliases = {
              "Ring of Organic Darkness",
            },
            ids = {
              69131,
            },
            item = "Ring of Organic Darkness",
          },
          Ear1 = {
            aliases = {
              "Earring of Mental Incursion",
            },
            ids = {
              47233,
            },
            item = "Earring of Mental Incursion",
          },
          Ear2 = {
            aliases = {
              "Stud of Focused Aptitude",
            },
            ids = {
              47236,
            },
            item = "Stud of Focused Aptitude",
          },
          Face = {
            aliases = {
              "Cynin's Mask",
            },
            ids = {
            },
            item = "Cynin's Mask",
          },
          Feet = {
            aliases = {
              "Boots of Shifting Time",
            },
            ids = {
              47216,
            },
            item = "Boots of Shifting Time",
          },
          Finger1 = {
            aliases = {
              "Divine Crystal Ring",
            },
            ids = {
            },
            item = "Divine Crystal Ring",
          },
          Finger2 = {
            aliases = {
              "Ring of the Brutish Beasts",
            },
            ids = {
            },
            item = "Ring of the Brutish Beasts",
          },
          GoDAug1 = {
            aliases = {
              "Discordian Alloy of Tenacity",
            },
            ids = {
              150041,
            },
            item = "Discordian Alloy of Tenacity",
          },
          Hands = {
            aliases = {
              "Crystal Gauntlets",
            },
            ids = {
              70723,
            },
            item = "Crystal Gauntlets",
          },
          Head = {
            aliases = {
              "Trimdet's Helm of Chivalry",
            },
            ids = {
              68860,
            },
            item = "Trimdet's Helm of Chivalry",
          },
          Legs = {
            aliases = {
              "Greaves of Seething Rage",
            },
            ids = {
              47200,
            },
            item = "Greaves of Seething Rage",
          },
          MainHand = {
            aliases = {
              "Redemption",
            },
            ids = {
              64031,
            },
            item = "Redemption",
          },
          Neck = {
            aliases = {
              "Assistant Researcher's Symbol",
            },
            ids = {
              67625,
            },
            item = "Assistant Researcher's Symbol",
          },
          Range = {
            aliases = {
              "Screaming Skull of Discontent",
            },
            ids = {
              47242,
            },
            item = "Screaming Skull of Discontent",
          },
          Secondary = {
            aliases = {
              "Battleworn Dented Aegis",
            },
            ids = {
              47252,
            },
            item = "Battleworn Dented Aegis",
          },
          Shoulder = {
            aliases = {
              "Forlorn Mantle of Shadows",
            },
            ids = {
            },
            item = "Forlorn Mantle of Shadows",
          },
          Waist = {
            aliases = {
              "Belt of Intangible Clairvoyance",
            },
            ids = {
              47230,
            },
            item = "Belt of Intangible Clairvoyance",
          },
          Wrist1 = {
            aliases = {
              "Xxeric's Battleworn Bracer",
            },
            ids = {
              69126,
            },
            item = "Xxeric's Battleworn Bracer",
          },
          Wrist2 = {
            aliases = {
              "Bracer of the Debauched",
            },
            ids = {
              47220,
            },
            item = "Bracer of the Debauched",
          },
        },
        Ranger = {
          Arms = {
            aliases = {
              "Crystal Mail Sleeves",
            },
            ids = {
              70711,
            },
            item = "Crystal Mail Sleeves",
          },
          Back = {
            aliases = {
              "Cloak of the Faithless",
            },
            ids = {
            },
            item = "Cloak of the Faithless",
          },
          Charm = {
            aliases = {
              "Grim Idol of the Brute",
            },
            ids = {
              150111,
            },
            item = "Grim Idol of the Brute",
          },
          Chest = {
            aliases = {
              "Bloodlink Chestmail",
            },
            ids = {
            },
            item = "Bloodlink Chestmail",
          },
          Clicky1 = {
            aliases = {
              "Veil of the Inferno",
            },
            ids = {
              9435,
            },
            item = "Veil of the Inferno",
          },
          Clicky2 = {
            aliases = {
              "Cloak of Retribution",
            },
            ids = {
              15842,
            },
            item = "Cloak of Retribution",
          },
          Clicky3 = {
            aliases = {
              "Ring of Organic Darkness",
            },
            ids = {
              69131,
            },
            item = "Ring of Organic Darkness",
          },
          Clicky4 = {
            aliases = {
              "Prismatic Ring of Resistance",
            },
            ids = {
              26989,
            },
            item = "Prismatic Ring of Resistance",
          },
          Clicky5 = {
            aliases = {
              "Wand of the Vortex",
            },
            ids = {
              26899,
            },
            item = "Wand of the Vortex",
          },
          Ear1 = {
            aliases = {
              "Earring of Mental Incursion",
            },
            ids = {
            },
            item = "Earring of Mental Incursion",
          },
          Ear2 = {
            aliases = {
              "Stud of Focused Aptitude",
            },
            ids = {
            },
            item = "Stud of Focused Aptitude",
          },
          Face = {
            aliases = {
              "Mask of Uncanny Sight",
            },
            ids = {
            },
            item = "Mask of Uncanny Sight",
          },
          Feet = {
            aliases = {
              "Nadien's Boots of the Archer",
            },
            ids = {
            },
            item = "Nadien's Boots of the Archer",
          },
          Finger1 = {
            aliases = {
              "Ring of Fluid Perception",
            },
            ids = {
            },
            item = "Ring of Fluid Perception",
          },
          Finger2 = {
            aliases = {
              "Bloodband of Malice",
            },
            ids = {
            },
            item = "Bloodband of Malice",
          },
          GoDAug1 = {
            aliases = {
              "Focus Shard of Aggregate Annihilation",
            },
            ids = {
              41142,
            },
            item = "Focus Shard of Aggregate Annihilation",
          },
          GoDAug2 = {
            aliases = {
              "Focus Shard of Destruction",
            },
            ids = {
              150047,
            },
            item = "Focus Shard of Destruction",
          },
          GoDAug3 = {
            aliases = {
              "Volatile Discordian Rune",
            },
            ids = {
              150040,
            },
            item = "Volatile Discordian Rune",
          },
          Hands = {
            aliases = {
              "Runed Gauntlets of the Void",
            },
            ids = {
              69253,
            },
            item = "Runed Gauntlets of the Void",
          },
          Head = {
            aliases = {
              "Headband of the Endless Night",
            },
            ids = {
            },
            item = "Headband of the Endless Night",
          },
          Legs = {
            aliases = {
              "Tunat'Muram's Bloodied Greaves",
            },
            ids = {
            },
            item = "Tunat'Muram's Bloodied Greaves",
          },
          MainHand = {
            aliases = {
              "Heartwood Blade",
            },
            ids = {
              62627,
            },
            item = "Heartwood Blade",
          },
          Neck = {
            aliases = {
              "Sapphire Choker of Adaptation",
            },
            ids = {
            },
            item = "Sapphire Choker of Adaptation",
          },
          PoPAug1 = {
            aliases = {
              "Planar Alloy of Escalating Onslaught",
            },
            ids = {
              10412,
            },
            item = "Planar Alloy of Escalating Onslaught",
          },
          Range = {
            aliases = {
              "Ruby of Determined Assault",
            },
            ids = {
              69158,
            },
            item = "Ruby of Determined Assault",
          },
          Secondary = {
            aliases = {
              "Blade of Natural Turmoil",
            },
            ids = {
            },
            item = "Blade of Natural Turmoil",
          },
          Shoulder = {
            aliases = {
              "Ilsin's Mantle",
            },
            ids = {
            },
            item = "Ilsin's Mantle",
          },
          Waist = {
            aliases = {
              "Belt of Inevitable Conversion",
            },
            ids = {
            },
            item = "Belt of Inevitable Conversion",
          },
          Wrist1 = {
            aliases = {
              "Wristguard of Chaotic Essence",
            },
            ids = {
            },
            item = "Wristguard of Chaotic Essence",
          },
          Wrist2 = {
            aliases = {
              "Red Crystal Bracer",
            },
            ids = {
              70619,
            },
            item = "Red Crystal Bracer",
          },
        },
        Rogue = {
          Arms = {
            aliases = {
              "Crystal Mail Sleeves",
            },
            ids = {
              70711,
            },
            item = "Crystal Mail Sleeves",
          },
          Back = {
            aliases = {
              "Cloak of the Faithless",
            },
            ids = {
            },
            item = "Cloak of the Faithless",
          },
          Charm = {
            aliases = {
              "Grim Idol of the Brute",
            },
            ids = {
              150111,
            },
            item = "Grim Idol of the Brute",
          },
          Chest = {
            aliases = {
              "Bloodlink Chestmail",
            },
            ids = {
            },
            item = "Bloodlink Chestmail",
          },
          Clicky1 = {
            aliases = {
              "Veil of the Inferno",
            },
            ids = {
              9435,
            },
            item = "Veil of the Inferno",
          },
          Clicky2 = {
            aliases = {
              "Cloak of Retribution",
            },
            ids = {
              15842,
            },
            item = "Cloak of Retribution",
          },
          Clicky3 = {
            aliases = {
              "Ring of Organic Darkness",
            },
            ids = {
              69131,
            },
            item = "Ring of Organic Darkness",
          },
          Clicky4 = {
            aliases = {
              "Prismatic Ring of Resistance",
            },
            ids = {
              26989,
            },
            item = "Prismatic Ring of Resistance",
          },
          Ear1 = {
            aliases = {
              "Earring of Mental Incursion",
            },
            ids = {
            },
            item = "Earring of Mental Incursion",
          },
          Ear2 = {
            aliases = {
              "Stud of Focused Aptitude",
            },
            ids = {
            },
            item = "Stud of Focused Aptitude",
          },
          Face = {
            aliases = {
              "Mask of Uncanny Sight",
            },
            ids = {
            },
            item = "Mask of Uncanny Sight",
          },
          Feet = {
            aliases = {
              "Nodnol's Boots of the Scoundrel",
            },
            ids = {
            },
            item = "Nodnol's Boots of the Scoundrel",
          },
          Finger1 = {
            aliases = {
              "Ring of Fluid Perception",
            },
            ids = {
            },
            item = "Ring of Fluid Perception",
          },
          Finger2 = {
            aliases = {
              "Bloodband of Malice",
            },
            ids = {
            },
            item = "Bloodband of Malice",
          },
          Hands = {
            aliases = {
              "Runed Gauntlets of the Void",
            },
            ids = {
              69253,
            },
            item = "Runed Gauntlets of the Void",
          },
          Head = {
            aliases = {
              "Headband of the Endless Night",
            },
            ids = {
            },
            item = "Headband of the Endless Night",
          },
          Legs = {
            aliases = {
              "Tunat'Muram's Bloodied Greaves",
            },
            ids = {
            },
            item = "Tunat'Muram's Bloodied Greaves",
          },
          MainHand = {
            aliases = {
              "Fatestealer",
            },
            ids = {
              52347,
            },
            item = "Fatestealer",
          },
          Neck = {
            aliases = {
              "Sapphire Choker of Adaptation",
            },
            ids = {
            },
            item = "Sapphire Choker of Adaptation",
          },
          PoPAug1 = {
            aliases = {
              "Planar Alloy of Escalating Onslaught",
            },
            ids = {
              10412,
            },
            item = "Planar Alloy of Escalating Onslaught",
          },
          PoPAug2 = {
            aliases = {
              "Focus Rune of Foul Play",
            },
            ids = {
              150029,
            },
            item = "Focus Rune of Foul Play",
          },
          Range = {
            aliases = {
              "Ruby of Determined Assault",
            },
            ids = {
              69158,
            },
            item = "Ruby of Determined Assault",
          },
          Secondary = {
            aliases = {
              "Crystal Dagger",
            },
            ids = {
            },
            item = "Crystal Dagger",
          },
          Shoulder = {
            aliases = {
              "Pauldron of Dark Auspices",
            },
            ids = {
            },
            item = "Pauldron of Dark Auspices",
          },
          Waist = {
            aliases = {
              "Belt of Inevitable Conversion",
            },
            ids = {
            },
            item = "Belt of Inevitable Conversion",
          },
          Wrist1 = {
            aliases = {
              "Wristguard of Chaotic Essence",
            },
            ids = {
            },
            item = "Wristguard of Chaotic Essence",
          },
          Wrist2 = {
            aliases = {
              "Red Crystal Bracer",
            },
            ids = {
              70619,
            },
            item = "Red Crystal Bracer",
          },
        },
        ["Shadow Knight"] = {
          Arms = {
            aliases = {
              "Armguards of Insidious Corruption",
            },
            ids = {
              69168,
            },
            item = "Armguards of Insidious Corruption",
          },
          Aug1 = {
            aliases = {
              "Hulcror Pearl",
            },
            ids = {
              70694,
            },
            item = "Hulcror Pearl",
          },
          Aug2 = {
            aliases = {
              "Enchanted Orb of Defense",
            },
            ids = {
              68019,
            },
            item = "Enchanted Orb of Defense",
          },
          Aug3 = {
            aliases = {
              "Glyphed Sandstone",
            },
            ids = {
              68800,
            },
            item = "Glyphed Sandstone",
          },
          Aug4 = {
            aliases = {
              "Blessed Shard",
            },
            ids = {
              68667,
            },
            item = "Blessed Shard",
          },
          Aug5 = {
            aliases = {
              "Experimental Gem of Enhanced Protection",
            },
            ids = {
              68048,
            },
            item = "Experimental Gem of Enhanced Protection",
          },
          Aug6 = {
            aliases = {
              "Frosty Gem of Enhanced Protection",
            },
            ids = {
              68107,
            },
            item = "Frosty Gem of Enhanced Protection",
          },
          Aug7 = {
            aliases = {
              "Guardian's Stone of Enhanced Protection",
            },
            ids = {
              68049,
            },
            item = "Guardian's Stone of Enhanced Protection",
          },
          Aug8 = {
            aliases = {
              "Yenner's Rock of Enhanced Protection",
            },
            ids = {
              68047,
            },
            item = "Yenner's Rock of Enhanced Protection",
          },
          Back = {
            aliases = {
              "Two-Toned Fur Cape",
            },
            ids = {
              47248,
            },
            item = "Two-Toned Fur Cape",
          },
          Charm = {
            aliases = {
              "Grim Idol of the Brute",
            },
            ids = {
              150111,
            },
            item = "Grim Idol of the Brute",
          },
          Chest = {
            aliases = {
              "Rayin's Chestplate of Abhorrence",
            },
            ids = {
              68966,
            },
            item = "Rayin's Chestplate of Abhorrence",
          },
          Clicky1 = {
            aliases = {
              "Band of Primordial Energy",
            },
            ids = {
              26990,
            },
            item = "Band of Primordial Energy",
          },
          Clicky2 = {
            aliases = {
              "Cloak of Retribution",
            },
            ids = {
              15842,
            },
            item = "Cloak of Retribution",
          },
          Clicky3 = {
            aliases = {
              "Ring of Organic Darkness",
            },
            ids = {
              69131,
            },
            item = "Ring of Organic Darkness",
          },
          Ear1 = {
            aliases = {
              "Earring of Mental Incursion",
            },
            ids = {
              47233,
            },
            item = "Earring of Mental Incursion",
          },
          Ear2 = {
            aliases = {
              "Stud of Focused Aptitude",
            },
            ids = {
              47236,
            },
            item = "Stud of Focused Aptitude",
          },
          Face = {
            aliases = {
              "Cynin's Mask",
            },
            ids = {
            },
            item = "Cynin's Mask",
          },
          Feet = {
            aliases = {
              "Boots of Shifting Time",
            },
            ids = {
              47216,
            },
            item = "Boots of Shifting Time",
          },
          Finger1 = {
            aliases = {
              "Divine Crystal Ring",
            },
            ids = {
            },
            item = "Divine Crystal Ring",
          },
          Finger2 = {
            aliases = {
              "Ring of the Brutish Beasts",
            },
            ids = {
            },
            item = "Ring of the Brutish Beasts",
          },
          GoDAug1 = {
            aliases = {
              "Discordian Alloy of Tenacity",
            },
            ids = {
              150041,
            },
            item = "Discordian Alloy of Tenacity",
          },
          Hands = {
            aliases = {
              "Crystal Gauntlets",
            },
            ids = {
              70723,
            },
            item = "Crystal Gauntlets",
          },
          Head = {
            aliases = {
              "Rayin's Helm of Abhorrence",
            },
            ids = {
              68865,
            },
            item = "Rayin's Helm of Abhorrence",
          },
          Legs = {
            aliases = {
              "Greaves of Seething Rage",
            },
            ids = {
              47200,
            },
            item = "Greaves of Seething Rage",
          },
          MainHand = {
            aliases = {
              "Innoruuk's Voice",
            },
            ids = {
              50003,
            },
            item = "Innoruuk's Voice",
          },
          Neck = {
            aliases = {
              "Assistant Researcher's Symbol",
            },
            ids = {
              67625,
            },
            item = "Assistant Researcher's Symbol",
          },
          Range = {
            aliases = {
              "Screaming Skull of Discontent",
            },
            ids = {
              47242,
            },
            item = "Screaming Skull of Discontent",
          },
          Secondary = {
            aliases = {
              "Battleworn Dented Aegis",
            },
            ids = {
              47252,
            },
            item = "Battleworn Dented Aegis",
          },
          Shoulder = {
            aliases = {
              "Forlorn Mantle of Shadows",
            },
            ids = {
            },
            item = "Forlorn Mantle of Shadows",
          },
          Waist = {
            aliases = {
              "Belt of Intangible Clairvoyance",
            },
            ids = {
              47230,
            },
            item = "Belt of Intangible Clairvoyance",
          },
          Wrist1 = {
            aliases = {
              "Xxeric's Battleworn Bracer",
            },
            ids = {
              69126,
            },
            item = "Xxeric's Battleworn Bracer",
          },
          Wrist2 = {
            aliases = {
              "Bracer of the Debauched",
            },
            ids = {
              47220,
            },
            item = "Bracer of the Debauched",
          },
        },
        Shaman = {
          Arms = {
            aliases = {
              "Vambraces of Perseverance",
            },
            ids = {
              70711,
            },
            item = "Vambraces of Perseverance",
          },
          Back = {
            aliases = {
              "Cloak of Nightmarish Visions",
            },
            ids = {
              69164,
            },
            item = "Cloak of Nightmarish Visions",
          },
          Charm = {
            aliases = {
              "Fetish of Irreverent Knowledge",
            },
            ids = {
              150112,
            },
            item = "Fetish of Irreverent Knowledge",
          },
          Chest = {
            aliases = {
              "Crystal Mail",
            },
            ids = {
              70713,
            },
            item = "Crystal Mail",
          },
          Clicky1 = {
            aliases = {
              "Earring of Pain Deliverance",
            },
            ids = {
              69133,
            },
            item = "Earring of Pain Deliverance",
          },
          Clicky2 = {
            aliases = {
              "Loop of Endless Insanity",
            },
            ids = {
              68957,
            },
            item = "Loop of Endless Insanity",
          },
          Clicky3 = {
            aliases = {
              "Mantle of Corruption",
            },
            ids = {
              69163,
            },
            item = "Mantle of Corruption",
          },
          Clicky4 = {
            aliases = {
              "Prismatic Ring of Resistance",
            },
            ids = {
              26989,
            },
            item = "Prismatic Ring of Resistance",
          },
          Clicky5 = {
            aliases = {
              "Wand of the Vortex",
            },
            ids = {
              26899,
            },
            item = "Wand of the Vortex",
          },
          Clicky6 = {
            aliases = {
              "Aged Hammer of the Dragonborn",
            },
            ids = {
              69412,
            },
            item = "Aged Hammer of the Dragonborn",
            source = "Silverwing",
          },
          Clicky7 = {
            aliases = {
              "Zun'Muram's Spear of Doom",
            },
            ids = {
              69118,
            },
            item = "Zun'Muram's Spear of Doom",
            source = "Zun'Muram Mordl Delt",
          },
          Ear1 = {
            aliases = {
              "Loop of Entropic Hues",
            },
            ids = {
              69166,
            },
            item = "Loop of Entropic Hues",
          },
          Ear2 = {
            aliases = {
              "Clawed Earring of Determination",
            },
            ids = {
              47234,
            },
            item = "Clawed Earring of Determination",
          },
          Face = {
            aliases = {
              "Xxeric's Matted-Fur Mask",
            },
            ids = {
              69132,
            },
            item = "Xxeric's Matted-Fur Mask",
          },
          Feet = {
            aliases = {
              "Boots of Altered Perception",
            },
            ids = {
              47217,
            },
            item = "Boots of Altered Perception",
          },
          Finger1 = {
            aliases = {
              "Ring of the Serpent",
            },
            ids = {
              69160,
            },
            item = "Ring of the Serpent",
          },
          Finger2 = {
            aliases = {
              "Ring of Ire Intent",
            },
            ids = {
              47240,
            },
            item = "Ring of Ire Intent",
          },
          GoDAug1 = {
            aliases = {
              "Discordian Alloy of Tenacity",
            },
            ids = {
              150041,
            },
            item = "Discordian Alloy of Tenacity",
          },
          GoDAug2 = {
            aliases = {
              "Focus Shard of Aggregate Annihilation",
            },
            ids = {
              41142,
            },
            item = "Focus Shard of Aggregate Annihilation",
          },
          GoDAug3 = {
            aliases = {
              "Focus Shard of Destruction",
            },
            ids = {
              150047,
            },
            item = "Focus Shard of Destruction",
          },
          GoDAug4 = {
            aliases = {
              "Volatile Discordian Rune",
            },
            ids = {
              150040,
            },
            item = "Volatile Discordian Rune",
          },
          Hands = {
            aliases = {
              "Chain Gauntlets of Adroitness",
            },
            ids = {
              47213,
            },
            item = "Chain Gauntlets of Adroitness",
          },
          Head = {
            aliases = {
              "Helm of Inventive Perception",
            },
            ids = {
              47209,
            },
            item = "Helm of Inventive Perception",
          },
          Legs = {
            aliases = {
              "Legplates of Abhorrent Memories",
            },
            ids = {
              47201,
            },
            item = "Legplates of Abhorrent Memories",
          },
          MainHand = {
            aliases = {
              "Crafted Talisman of Fates",
            },
            ids = {
              57400,
            },
            item = "Crafted Talisman of Fates",
          },
          Neck = {
            aliases = {
              "Zulaqua's Necklace",
            },
            ids = {
              70705,
            },
            item = "Zulaqua's Necklace",
          },
          Range = {
            aliases = {
              "Tome of New Beginnings",
            },
            ids = {
              67606,
            },
            item = "Tome of New Beginnings",
          },
          Secondary = {
            aliases = {
              "Blackstone Figurine",
            },
            ids = {
              69051,
            },
            item = "Blackstone Figurine",
          },
          Shoulder = {
            aliases = {
              "Mantle of Corruption",
            },
            ids = {
              69163,
            },
            item = "Mantle of Corruption",
          },
          Waist = {
            aliases = {
              "Cord of the Malcontent",
            },
            ids = {
              47231,
            },
            item = "Cord of the Malcontent",
          },
          Wrist1 = {
            aliases = {
              "Wristguard of Chaotic Essence",
            },
            ids = {
              69127,
            },
            item = "Wristguard of Chaotic Essence",
          },
          Wrist2 = {
            aliases = {
              "Muramite's Heavy Shackles",
            },
            ids = {
              69100,
            },
            item = "Muramite's Heavy Shackles",
          },
        },
        Warrior = {
          Arms = {
            aliases = {
              "Armguards of Insidious Corruption",
            },
            ids = {
              69168,
            },
            item = "Armguards of Insidious Corruption",
          },
          Aug1 = {
            aliases = {
              "Hulcror Pearl",
            },
            ids = {
              70694,
            },
            item = "Hulcror Pearl",
          },
          Aug2 = {
            aliases = {
              "Enchanted Orb of Defense",
            },
            ids = {
              68019,
            },
            item = "Enchanted Orb of Defense",
          },
          Aug3 = {
            aliases = {
              "Glyphed Sandstone",
            },
            ids = {
              68800,
            },
            item = "Glyphed Sandstone",
          },
          Aug4 = {
            aliases = {
              "Blessed Shard",
            },
            ids = {
              68667,
            },
            item = "Blessed Shard",
          },
          Aug5 = {
            aliases = {
              "Frosty Gem of Enhanced Protection",
            },
            ids = {
              68107,
            },
            item = "Frosty Gem of Enhanced Protection",
          },
          Aug6 = {
            aliases = {
              "Guardian's Stone of Enhanced Protection",
            },
            ids = {
              68049,
            },
            item = "Guardian's Stone of Enhanced Protection",
          },
          Aug7 = {
            aliases = {
              "Experimental Gem of Enhanced Protection",
            },
            ids = {
              68048,
            },
            item = "Experimental Gem of Enhanced Protection",
          },
          Aug8 = {
            aliases = {
              "Yenner's Rock of Enhanced Protection",
            },
            ids = {
              68047,
            },
            item = "Yenner's Rock of Enhanced Protection",
          },
          Back = {
            aliases = {
              "Two-Toned Fur Cape",
            },
            ids = {
              47248,
            },
            item = "Two-Toned Fur Cape",
          },
          Charm = {
            aliases = {
              "Grim Idol of the Brute",
            },
            ids = {
              150111,
            },
            item = "Grim Idol of the Brute",
          },
          Chest = {
            aliases = {
              "Vadd's Chestplate of Elite Combat",
            },
            ids = {
              68960,
            },
            item = "Vadd's Chestplate of Elite Combat",
          },
          Clicky1 = {
            aliases = {
              "Band of Primordial Energy",
            },
            ids = {
              26990,
            },
            item = "Band of Primordial Energy",
          },
          Clicky2 = {
            aliases = {
              "Cloak of Retribution",
            },
            ids = {
              15842,
            },
            item = "Cloak of Retribution",
          },
          Clicky3 = {
            aliases = {
              "Ring of Organic Darkness",
            },
            ids = {
              69131,
            },
            item = "Ring of Organic Darkness",
          },
          Clicky4 = {
            aliases = {
              "Sparkling Bracer of the Jeweled Hero",
            },
            ids = {
              68084,
            },
            item = "Sparkling Bracer of the Jeweled Hero",
          },
          Ear1 = {
            aliases = {
              "Earring of Mental Incursion",
            },
            ids = {
              47233,
            },
            item = "Earring of Mental Incursion",
          },
          Ear2 = {
            aliases = {
              "Stud of Focused Aptitude",
            },
            ids = {
              47236,
            },
            item = "Stud of Focused Aptitude",
          },
          Face = {
            aliases = {
              "Cynin's Mask",
            },
            ids = {
            },
            item = "Cynin's Mask",
          },
          Feet = {
            aliases = {
              "Boots of Shifting Time",
            },
            ids = {
              47216,
            },
            item = "Boots of Shifting Time",
          },
          Finger1 = {
            aliases = {
              "Divine Crystal Ring",
            },
            ids = {
            },
            item = "Divine Crystal Ring",
          },
          Finger2 = {
            aliases = {
              "Ring of the Brutish Beasts",
            },
            ids = {
            },
            item = "Ring of the Brutish Beasts",
          },
          GoDAug1 = {
            aliases = {
              "Discordian Alloy of Tenacity",
            },
            ids = {
              150041,
            },
            item = "Discordian Alloy of Tenacity",
          },
          Hands = {
            aliases = {
              "Crystal Gauntlets",
            },
            ids = {
              70723,
            },
            item = "Crystal Gauntlets",
          },
          Head = {
            aliases = {
              "Vadd's Helm of Elite Combat",
            },
            ids = {
              67719,
            },
            item = "Vadd's Helm of Elite Combat",
          },
          Legs = {
            aliases = {
              "Greaves of Seething Rage",
            },
            ids = {
              47200,
            },
            item = "Greaves of Seething Rage",
          },
          MainHand = {
            aliases = {
              "Champion's Sword of Eternal Power",
            },
            ids = {
              60321,
            },
            item = "Champion's Sword of Eternal Power",
          },
          Neck = {
            aliases = {
              "Assistant Researcher's Symbol",
            },
            ids = {
              67625,
            },
            item = "Assistant Researcher's Symbol",
          },
          Range = {
            aliases = {
              "Screaming Skull of Discontent",
            },
            ids = {
              47242,
            },
            item = "Screaming Skull of Discontent",
          },
          Secondary = {
            aliases = {
              "Battleworn Dented Aegis",
            },
            ids = {
              47252,
            },
            item = "Battleworn Dented Aegis",
          },
          Shoulder = {
            aliases = {
              "Forlorn Mantle of Shadows",
            },
            ids = {
            },
            item = "Forlorn Mantle of Shadows",
          },
          Waist = {
            aliases = {
              "Belt of Intangible Clairvoyance",
            },
            ids = {
              47230,
            },
            item = "Belt of Intangible Clairvoyance",
          },
          Wrist1 = {
            aliases = {
              "Xxeric's Battleworn Bracer",
            },
            ids = {
              69126,
            },
            item = "Xxeric's Battleworn Bracer",
          },
          Wrist2 = {
            aliases = {
              "Bracer of the Debauched",
            },
            ids = {
              47220,
            },
            item = "Bracer of the Debauched",
          },
        },
        Wizard = {
          Arms = {
            aliases = {
              "Sleeves of Malefic Rapture",
            },
            ids = {
              69176,
            },
            item = "Sleeves of Malefic Rapture",
          },
          Aug1 = {
            aliases = {
              "Velrek's Enchanted Prism",
            },
            ids = {
              68020,
            },
            item = "Velrek's Enchanted Prism",
          },
          Back = {
            aliases = {
              "Cloak of Nightmarish Visions",
            },
            ids = {
              69164,
            },
            item = "Cloak of Nightmarish Visions",
          },
          Charm = {
            aliases = {
              "Fetish of Irreverent Knowledge",
            },
            ids = {
              150112,
            },
            item = "Fetish of Irreverent Knowledge",
          },
          Chest = {
            aliases = {
              "Crystal Silk Robe",
            },
            ids = {
              70714,
            },
            item = "Crystal Silk Robe",
          },
          Clicky1 = {
            aliases = {
              "Earring of Pain Deliverance",
            },
            ids = {
              69133,
            },
            item = "Earring of Pain Deliverance",
          },
          Clicky2 = {
            aliases = {
              "Loop of Endless Insanity",
            },
            ids = {
              68957,
            },
            item = "Loop of Endless Insanity",
          },
          Clicky3 = {
            aliases = {
              "Mantle of Corruption",
            },
            ids = {
              69163,
            },
            item = "Mantle of Corruption",
          },
          Clicky4 = {
            aliases = {
              "Wand of the Vortex",
            },
            ids = {
              26899,
            },
            item = "Wand of the Vortex",
          },
          Clicky5 = {
            aliases = {
              "Aged Shissar Elementalist's Staff",
            },
            ids = {
              69434,
            },
            item = "Aged Shissar Elementalist's Staff",
            source = "Hoshkar",
          },
          Clicky6 = {
            aliases = {
              "Scepter of Incantations",
            },
            ids = {
              69122,
            },
            item = "Scepter of Incantations",
            source = "Zun'Muram Kvxe Pirik",
          },
          Ear1 = {
            aliases = {
              "Loop of Entropic Hues",
            },
            ids = {
              69166,
            },
            item = "Loop of Entropic Hues",
          },
          Ear2 = {
            aliases = {
              "Clawed Earring of Determination",
            },
            ids = {
              47234,
            },
            item = "Clawed Earring of Determination",
          },
          Face = {
            aliases = {
              "Xxeric's Matted-Fur Mask",
            },
            ids = {
              69132,
            },
            item = "Xxeric's Matted-Fur Mask",
          },
          Feet = {
            aliases = {
              "Supple Slippers of Transformation",
            },
            ids = {
              47219,
            },
            item = "Supple Slippers of Transformation",
          },
          Finger1 = {
            aliases = {
              "Band of Eternal Gaze",
            },
            ids = {
              47238,
            },
            item = "Band of Eternal Gaze",
          },
          Finger2 = {
            aliases = {
              "Ring of Ire Intent",
            },
            ids = {
              47240,
            },
            item = "Ring of Ire Intent",
          },
          GoDAug1 = {
            aliases = {
              "Focus Shard of Aggregate Annihilation",
            },
            ids = {
              41142,
            },
            item = "Focus Shard of Aggregate Annihilation",
          },
          GoDAug2 = {
            aliases = {
              "Focus Shard of Destruction",
            },
            ids = {
              150047,
            },
            item = "Focus Shard of Destruction",
          },
          GoDAug3 = {
            aliases = {
              "Volatile Discordian Rune",
            },
            ids = {
              150040,
            },
            item = "Volatile Discordian Rune",
          },
          Hands = {
            aliases = {
              "Laced Gloves of Superiority",
            },
            ids = {
              47215,
            },
            item = "Laced Gloves of Superiority",
          },
          Head = {
            aliases = {
              "Twisted Crown of Consciousness",
            },
            ids = {
              47211,
            },
            item = "Twisted Crown of Consciousness",
          },
          Legs = {
            aliases = {
              "Envenomed Leggings of Enmity",
            },
            ids = {
              47203,
            },
            item = "Envenomed Leggings of Enmity",
          },
          MainHand = {
            aliases = {
              "Staff of Prismatic Power",
            },
            ids = {
              12665,
            },
            item = "Staff of Prismatic Power",
          },
          Neck = {
            aliases = {
              "Zulaqua's Necklace",
            },
            ids = {
              70705,
            },
            item = "Zulaqua's Necklace",
          },
          PoPAug1 = {
            aliases = {
              "Volatile Planar Rune",
            },
            ids = {
              150033,
            },
            item = "Volatile Planar Rune",
          },
          Range = {
            aliases = {
              "Golden Idol of Destruction",
            },
            ids = {
              69162,
            },
            item = "Golden Idol of Destruction",
          },
          Secondary = {
            aliases = {
              "Lana's Crystal Shield",
            },
            ids = {
              70708,
            },
            item = "Lana's Crystal Shield",
          },
          Shoulder = {
            aliases = {
              "Mantle of Corruption",
            },
            ids = {
              69163,
            },
            item = "Mantle of Corruption",
          },
          Waist = {
            aliases = {
              "Cord of the Malcontent",
            },
            ids = {
              47231,
            },
            item = "Cord of the Malcontent",
          },
          Wrist1 = {
            aliases = {
              "Bracelet of the Corrupter",
            },
            ids = {
              47223,
            },
            item = "Bracelet of the Corrupter",
          },
          Wrist2 = {
            aliases = {
              "Muramite's Heavy Shackles",
            },
            ids = {
              69100,
            },
            item = "Muramite's Heavy Shackles",
          },
        },
      },
      group = "Group Best In Slot",
      id = "preanguish",
      name = "Pre-Anguish",
      show_base = {
      },
      template = {
      },
      visible = {
      },
    },
    questitems = {
      categories = {
        {
          name = "Power of 3 (HS)",
          slots = {
            "Lucky Grass Trinket",
            "Lucky Copper/Silver",
          },
        },
        {
          name = "Power of 6 (Keepsakes)",
          slots = {
            "Symbol",
            "Destruction",
            "Mending",
            "Persistence",
            "Suffering",
            "Cleaving",
            "Deflection",
            "Evasion",
            "Ferocity",
          },
        },
        {
          name = "Power of 9 (Clue)",
          slots = {
            "Eyes",
            "Tongue",
            "Idol",
            "Oculus",
            "Horseshoe",
          },
        },
        {
          name = "The Crimson Curse",
          slots = {
            "BloodcursedCrown",
            "FireCrown",
          },
        },
        {
          name = "Chromatic Veil",
          slots = {
            "VeiledBastion",
            "VeiledBlade",
            "VeiledSeal",
            "VeiledEclipse",
          },
        },
        {
          name = "VP Hardcore",
          slots = {
            "Ember (Pri)",
            "Tempest (Pri)",
            "Cranium (Pri/2nd)",
            "Sigil",
            "Satchel",
            "HeartAnguish",
            "HeartDread",
          },
        },
        {
          name = "Mana Source",
          slots = {
            "Honed",
            "FracturedIris",
            "GuardianPetamorph",
          },
        },
        {
          name = "Kithicor",
          slots = {
            "BellikosClaws",
            "BellikosFang",
            "BellikosEye",
            "BellikosTear",
            "BellikosDoll",
          },
        },
        {
          name = "Powersource",
          slots = {
            "EOC",
            "Radix",
            "LuminousEssence",
            "OtherworldlySoul",
          },
        },
        {
          name = "Augs",
          slots = {
            "BIC1",
            "BIC2",
            "BIC3",
            "BIC4",
            "IntricateFigurine",
            "Wayfarer",
          },
        },
        {
          name = "Other",
          slots = {
            "ImbuedRune",
            "FabledBrew",
            "LazCharm",
            "Tacvi Clicky",
            "Veeshan Clicky",
            "Kithikor PortKey",
            "West Karana PortKey",
          },
        },
        {
          name = "Food/Drink",
          slots = {
            "Food",
            "Drink",
          },
        },
      },
      classes = {
        Bard = {
          BellikosClaws = {
            aliases = {
              "Splintered Bellikos Claws",
            },
            ids = {
            },
            item = "Splintered Bellikos Claws",
          },
          Drink = {
            aliases = {
              "Stalker's Spirit Slush",
            },
            ids = {
            },
            item = "Stalker's Spirit Slush",
          },
          Food = {
            aliases = {
              "Hunter's Meat and Taters",
            },
            ids = {
            },
            item = "Hunter's Meat and Taters",
          },
          Honed = {
            aliases = {
              "Honed Manastone",
            },
            ids = {
            },
            item = "Honed Manastone",
          },
          Idol = {
            aliases = {
              "9 Paths of Despair",
            },
            ids = {
            },
            item = "9 Paths of Despair",
          },
          ImbuedRune = {
            aliases = {
              "Imbued Rune of Echoes",
            },
            ids = {
            },
            item = "Imbued Rune of Echoes",
          },
          VeiledBlade = {
            aliases = {
              "Nightveil Emblem - DPS",
            },
            ids = {
              82789,
            },
            item = "Nightveil Emblem - DPS",
          },
        },
        Beastlord = {
          BellikosClaws = {
            aliases = {
              "Splintered Bellikos Claws",
            },
            ids = {
            },
            item = "Splintered Bellikos Claws",
          },
          ["Cranium (Pri/2nd)"] = {
            aliases = {
              "Cranium of Eternal Pain",
            },
            ids = {
            },
            item = "Cranium of Eternal Pain",
          },
          Drink = {
            aliases = {
              "Stalker's Spirit Slush",
            },
            ids = {
            },
            item = "Stalker's Spirit Slush",
          },
          Food = {
            aliases = {
              "Hunter's Meat and Taters",
            },
            ids = {
            },
            item = "Hunter's Meat and Taters",
          },
          Honed = {
            aliases = {
              "Honed Manastone",
            },
            ids = {
            },
            item = "Honed Manastone",
          },
          Idol = {
            aliases = {
              "9 Paths of Despair",
            },
            ids = {
            },
            item = "9 Paths of Despair",
          },
          ImbuedRune = {
            aliases = {
              "Imbued Rune of Mikkily's Healing",
            },
            ids = {
            },
            item = "Imbued Rune of Mikkily's Healing",
          },
          VeiledBlade = {
            aliases = {
              "Nightveil Emblem - DPS",
            },
            ids = {
              82789,
            },
            item = "Nightveil Emblem - DPS",
          },
        },
        Berserker = {
          BellikosFang = {
            aliases = {
              "Fragmented Bellikos Fang",
            },
            ids = {
            },
            item = "Fragmented Bellikos Fang",
          },
          Drink = {
            aliases = {
              "Stalker's Spirit Slush",
            },
            ids = {
            },
            item = "Stalker's Spirit Slush",
          },
          Food = {
            aliases = {
              "Hunter's Meat and Taters",
            },
            ids = {
            },
            item = "Hunter's Meat and Taters",
          },
          Idol = {
            aliases = {
              "9 Paths of Despair",
            },
            ids = {
            },
            item = "9 Paths of Despair",
          },
          ImbuedRune = {
            aliases = {
              "Imbued Rune of Overpowering Frenzy",
            },
            ids = {
            },
            item = "Imbued Rune of Overpowering Frenzy",
          },
          VeiledBlade = {
            aliases = {
              "Nightveil Emblem - DPS",
            },
            ids = {
              82789,
            },
            item = "Nightveil Emblem - DPS",
          },
        },
        Cleric = {
          BellikosEye = {
            aliases = {
              "Obsidian Bellikos Eye",
            },
            ids = {
            },
            item = "Obsidian Bellikos Eye",
          },
          BellikosFang = {
            aliases = {
              "Fragmented Bellikos Fang",
            },
            ids = {
            },
            item = "Fragmented Bellikos Fang",
          },
          Drink = {
            aliases = {
              "Darting Dragonroot Daiquiri",
            },
            ids = {
            },
            item = "Darting Dragonroot Daiquiri",
          },
          Food = {
            aliases = {
              "Sleek Spring Roll Sampler",
            },
            ids = {
            },
            item = "Sleek Spring Roll Sampler",
          },
          Honed = {
            aliases = {
              "Honed Manastone",
            },
            ids = {
            },
            item = "Honed Manastone",
          },
          ImbuedRune = {
            aliases = {
              "Imbued Rune of Vie",
            },
            ids = {
            },
            item = "Imbued Rune of Vie",
          },
          ["Tacvi Clicky"] = {
            aliases = {
              "Weighted Hammer of Conviction",
            },
            ids = {
            },
            item = "Weighted Hammer of Conviction",
            source = "Zun'Muram Kvxe Pirik",
          },
          ["Veeshan Clicky"] = {
            aliases = {
              "Aged Shissar Apothic Staff",
            },
            ids = {
            },
            item = "Aged Shissar Apothic Staff",
            source = "Hoshkar",
          },
          VeiledSeal = {
            aliases = {
              "Nightveil Emblem - Priest",
            },
            ids = {
              82788,
            },
            item = "Nightveil Emblem - Priest",
          },
        },
        Druid = {
          BellikosEye = {
            aliases = {
              "Obsidian Bellikos Eye",
            },
            ids = {
            },
            item = "Obsidian Bellikos Eye",
          },
          Drink = {
            aliases = {
              "Darting Dragonroot Daiquiri",
            },
            ids = {
            },
            item = "Darting Dragonroot Daiquiri",
          },
          FireCrown = {
            aliases = {
              "Crown of Fire Nimbus",
            },
            ids = {
            },
            item = "Crown of Fire Nimbus",
          },
          Food = {
            aliases = {
              "Sleek Spring Roll Sampler",
            },
            ids = {
            },
            item = "Sleek Spring Roll Sampler",
          },
          Honed = {
            aliases = {
              "Honed Manastone",
            },
            ids = {
            },
            item = "Honed Manastone",
          },
          ImbuedRune = {
            aliases = {
              "Imbued Rune of the Immolating Sun",
            },
            ids = {
            },
            item = "Imbued Rune of the Immolating Sun",
          },
          ["Tacvi Clicky"] = {
            aliases = {
              "Kelp-Covered Hammer",
            },
            ids = {
            },
            item = "Kelp-Covered Hammer",
            source = "Zun'Muram Shaldn Boc",
          },
          ["Veeshan Clicky"] = {
            aliases = {
              "Aged Dragon Spine Staff",
            },
            ids = {
            },
            item = "Aged Dragon Spine Staff",
            source = "Silverwing",
          },
          VeiledSeal = {
            aliases = {
              "Nightveil Emblem - Priest",
            },
            ids = {
              82788,
            },
            item = "Nightveil Emblem - Priest",
          },
        },
        Enchanter = {
          BellikosEye = {
            aliases = {
              "Obsidian Bellikos Eye",
            },
            ids = {
            },
            item = "Obsidian Bellikos Eye",
          },
          Drink = {
            aliases = {
              "Arcane Ambrosia Daiquiri",
            },
            ids = {
            },
            item = "Arcane Ambrosia Daiquiri",
          },
          Food = {
            aliases = {
              "Sorcerer's Spice Chicken",
            },
            ids = {
            },
            item = "Sorcerer's Spice Chicken",
          },
          Honed = {
            aliases = {
              "Honed Manastone",
            },
            ids = {
            },
            item = "Honed Manastone",
          },
          ImbuedRune = {
            aliases = {
              "Imbued Rune of Tashan's Echo",
            },
            ids = {
            },
            item = "Imbued Rune of Tashan's Echo",
          },
          ["Tacvi Clicky"] = {
            aliases = {
              "Hammer of Delusions",
            },
            ids = {
            },
            item = "Hammer of Delusions",
            source = "Zun'Muram Shaldn Boc",
          },
          ["Veeshan Clicky"] = {
            aliases = {
              "Aged Shissar Focus Staff",
            },
            ids = {
            },
            item = "Aged Shissar Focus Staff",
            source = "Druushk",
          },
          VeiledEclipse = {
            aliases = {
              "Nightveil Emblem - Caster",
            },
            ids = {
              82790,
            },
            item = "Nightveil Emblem - Caster",
          },
        },
        Magician = {
          BellikosEye = {
            aliases = {
              "Obsidian Bellikos Eye",
            },
            ids = {
            },
            item = "Obsidian Bellikos Eye",
          },
          Drink = {
            aliases = {
              "Arcane Ambrosia Daiquiri",
            },
            ids = {
            },
            item = "Arcane Ambrosia Daiquiri",
          },
          FireCrown = {
            aliases = {
              "Crown of Fire Nimbus",
            },
            ids = {
            },
            item = "Crown of Fire Nimbus",
          },
          Food = {
            aliases = {
              "Sorcerer's Spice Chicken",
            },
            ids = {
            },
            item = "Sorcerer's Spice Chicken",
          },
          Honed = {
            aliases = {
              "Honed Manastone",
            },
            ids = {
            },
            item = "Honed Manastone",
          },
          ImbuedRune = {
            aliases = {
              "Imbued Rune of Jerikor's Renewal",
            },
            ids = {
            },
            item = "Imbued Rune of Jerikor's Renewal",
          },
          ["Tacvi Clicky"] = {
            aliases = {
              "Dagger of Evil Summons",
            },
            ids = {
            },
            item = "Dagger of Evil Summons",
            source = "Zun'Muram Mordl Delt",
          },
          ["Veeshan Clicky"] = {
            aliases = {
              "Aged Sarnak Channeler Staff",
            },
            ids = {
            },
            item = "Aged Sarnak Channeler Staff",
            source = "Druushk",
          },
          VeiledEclipse = {
            aliases = {
              "Nightveil Emblem - Caster",
            },
            ids = {
              82790,
            },
            item = "Nightveil Emblem - Caster",
          },
        },
        Monk = {
          BellikosClaws = {
            aliases = {
              "Splintered Bellikos Claws",
            },
            ids = {
            },
            item = "Splintered Bellikos Claws",
          },
          BellikosFang = {
            aliases = {
              "Fragmented Bellikos Fang",
            },
            ids = {
            },
            item = "Fragmented Bellikos Fang",
          },
          Drink = {
            aliases = {
              "Stalker's Spirit Slush",
            },
            ids = {
            },
            item = "Stalker's Spirit Slush",
          },
          Food = {
            aliases = {
              "Hunter's Meat and Taters",
            },
            ids = {
            },
            item = "Hunter's Meat and Taters",
          },
          Idol = {
            aliases = {
              "9 Paths of Despair",
            },
            ids = {
            },
            item = "9 Paths of Despair",
          },
          ImbuedRune = {
            aliases = {
              "Imbued Rune of Dragon Fang",
            },
            ids = {
            },
            item = "Imbued Rune of Dragon Fang",
          },
          VeiledBlade = {
            aliases = {
              "Nightveil Emblem - DPS",
            },
            ids = {
              82789,
            },
            item = "Nightveil Emblem - DPS",
          },
        },
        Necromancer = {
          BellikosEye = {
            aliases = {
              "Obsidian Bellikos Eye",
            },
            ids = {
            },
            item = "Obsidian Bellikos Eye",
          },
          Drink = {
            aliases = {
              "Darting Dragonroot Daiquiri",
            },
            ids = {
            },
            item = "Darting Dragonroot Daiquiri",
          },
          Food = {
            aliases = {
              "Sleek Spring Roll Sampler",
            },
            ids = {
            },
            item = "Sleek Spring Roll Sampler",
          },
          Honed = {
            aliases = {
              "Honed Manastone",
            },
            ids = {
            },
            item = "Honed Manastone",
          },
          ImbuedRune = {
            aliases = {
              "Imbued Rune of Dark Salve",
            },
            ids = {
            },
            item = "Imbued Rune of Dark Salve",
          },
          ["Tacvi Clicky"] = {
            aliases = {
              "Dagger of Death",
            },
            ids = {
            },
            item = "Dagger of Death",
            source = "Zun'Muram Yihst Vor",
          },
          ["Veeshan Clicky"] = {
            aliases = {
              "Aged Shissar Deathspeaker Staff",
            },
            ids = {
            },
            item = "Aged Shissar Deathspeaker Staff",
            source = "Druushk",
          },
          VeiledEclipse = {
            aliases = {
              "Nightveil Emblem - Caster",
            },
            ids = {
              82790,
            },
            item = "Nightveil Emblem - Caster",
          },
        },
        Paladin = {
          BellikosClaws = {
            aliases = {
              "Splintered Bellikos Claws",
            },
            ids = {
            },
            item = "Splintered Bellikos Claws",
          },
          BellikosFang = {
            aliases = {
              "Fragmented Bellikos Fang",
            },
            ids = {
            },
            item = "Fragmented Bellikos Fang",
          },
          BellikosTear = {
            aliases = {
              "Hardened Tear of the Bellikos",
            },
            ids = {
            },
            item = "Hardened Tear of the Bellikos",
          },
          Drink = {
            aliases = {
              "Bamboo Defender Margarita",
            },
            ids = {
            },
            item = "Bamboo Defender Margarita",
          },
          Food = {
            aliases = {
              "Armored Starfish Skewers",
            },
            ids = {
            },
            item = "Armored Starfish Skewers",
          },
          Honed = {
            aliases = {
              "Honed Manastone",
            },
            ids = {
            },
            item = "Honed Manastone",
          },
          Idol = {
            aliases = {
              "9 Paths of Despair",
            },
            ids = {
            },
            item = "9 Paths of Despair",
          },
          ImbuedRune = {
            aliases = {
              "Imbued Rune of Piety",
            },
            ids = {
            },
            item = "Imbued Rune of Piety",
          },
          ["Tempest (Pri)"] = {
            aliases = {
              "Tempest of the Wyrm",
            },
            ids = {
            },
            item = "Tempest of the Wyrm",
          },
          VeiledBastion = {
            aliases = {
              "Nightveil Emblem - Tank",
            },
            ids = {
              82787,
            },
            item = "Nightveil Emblem - Tank",
          },
        },
        Ranger = {
          BellikosClaws = {
            aliases = {
              "Splintered Bellikos Claws",
            },
            ids = {
            },
            item = "Splintered Bellikos Claws",
          },
          BellikosEye = {
            aliases = {
              "Obsidian Bellikos Eye",
            },
            ids = {
            },
            item = "Obsidian Bellikos Eye",
          },
          BellikosFang = {
            aliases = {
              "Fragmented Bellikos Fang",
            },
            ids = {
            },
            item = "Fragmented Bellikos Fang",
          },
          Drink = {
            aliases = {
              "Stalker's Spirit Slush",
            },
            ids = {
            },
            item = "Stalker's Spirit Slush",
          },
          FireCrown = {
            aliases = {
              "Crown of Fire Nimbus",
            },
            ids = {
            },
            item = "Crown of Fire Nimbus",
          },
          Food = {
            aliases = {
              "Hunter's Meat and Taters",
            },
            ids = {
            },
            item = "Hunter's Meat and Taters",
          },
          Honed = {
            aliases = {
              "Honed Manastone",
            },
            ids = {
            },
            item = "Honed Manastone",
          },
          ImbuedRune = {
            aliases = {
              "Imbued Rune of Jolting Snapkicks",
            },
            ids = {
            },
            item = "Imbued Rune of Jolting Snapkicks",
          },
          VeiledBlade = {
            aliases = {
              "Nightveil Emblem - DPS",
            },
            ids = {
              82789,
            },
            item = "Nightveil Emblem - DPS",
          },
        },
        Rogue = {
          BellikosClaws = {
            aliases = {
              "Splintered Bellikos Claws",
            },
            ids = {
            },
            item = "Splintered Bellikos Claws",
          },
          Drink = {
            aliases = {
              "Stalker's Spirit Slush",
            },
            ids = {
            },
            item = "Stalker's Spirit Slush",
          },
          Food = {
            aliases = {
              "Hunter's Meat and Taters",
            },
            ids = {
            },
            item = "Hunter's Meat and Taters",
          },
          Idol = {
            aliases = {
              "9 Paths of Despair",
            },
            ids = {
            },
            item = "9 Paths of Despair",
          },
          ImbuedRune = {
            aliases = {
              "Imbued Rune of Assault",
            },
            ids = {
            },
            item = "Imbued Rune of Assault",
          },
          VeiledBlade = {
            aliases = {
              "Nightveil Emblem - DPS",
            },
            ids = {
              82789,
            },
            item = "Nightveil Emblem - DPS",
          },
        },
        ["Shadow Knight"] = {
          BellikosClaws = {
            aliases = {
              "Splintered Bellikos Claws",
            },
            ids = {
            },
            item = "Splintered Bellikos Claws",
          },
          BellikosFang = {
            aliases = {
              "Fragmented Bellikos Fang",
            },
            ids = {
            },
            item = "Fragmented Bellikos Fang",
          },
          BellikosTear = {
            aliases = {
              "Hardened Tear of the Bellikos",
            },
            ids = {
            },
            item = "Hardened Tear of the Bellikos",
          },
          Drink = {
            aliases = {
              "Bamboo Defender Margarita",
            },
            ids = {
            },
            item = "Bamboo Defender Margarita",
          },
          Food = {
            aliases = {
              "Armored Starfish Skewers",
            },
            ids = {
            },
            item = "Armored Starfish Skewers",
          },
          Honed = {
            aliases = {
              "Honed Manastone",
            },
            ids = {
            },
            item = "Honed Manastone",
          },
          Idol = {
            aliases = {
              "9 Paths of Despair",
            },
            ids = {
            },
            item = "9 Paths of Despair",
          },
          ImbuedRune = {
            aliases = {
              "Imbued Rune of Agony and Hate",
            },
            ids = {
            },
            item = "Imbued Rune of Agony and Hate",
          },
          ["Tempest (Pri)"] = {
            aliases = {
              "Tempest of the Wyrm",
            },
            ids = {
            },
            item = "Tempest of the Wyrm",
          },
          VeiledBastion = {
            aliases = {
              "Nightveil Emblem - Tank",
            },
            ids = {
              82787,
            },
            item = "Nightveil Emblem - Tank",
          },
        },
        Shaman = {
          BellikosEye = {
            aliases = {
              "Obsidian Bellikos Eye",
            },
            ids = {
            },
            item = "Obsidian Bellikos Eye",
          },
          Drink = {
            aliases = {
              "Darting Dragonroot Daiquiri",
            },
            ids = {
            },
            item = "Darting Dragonroot Daiquiri",
          },
          Food = {
            aliases = {
              "Sleek Spring Roll Sampler",
            },
            ids = {
            },
            item = "Sleek Spring Roll Sampler",
          },
          Honed = {
            aliases = {
              "Honed Manastone",
            },
            ids = {
            },
            item = "Honed Manastone",
          },
          ImbuedRune = {
            aliases = {
              "Imbued Rune of the Panther",
            },
            ids = {
            },
            item = "Imbued Rune of the Panther",
          },
          ["Tacvi Clicky"] = {
            aliases = {
              "Zun'Muram's Spear of Doom",
            },
            ids = {
            },
            item = "Zun'Muram's Spear of Doom",
            source = "Zun'Muram Mordl Delt",
          },
          ["Veeshan Clicky"] = {
            aliases = {
              "Aged Hammer of the Dragonborn",
            },
            ids = {
            },
            item = "Aged Hammer of the Dragonborn",
            source = "Silverwing",
          },
          VeiledSeal = {
            aliases = {
              "Nightveil Emblem - Priest",
            },
            ids = {
              82788,
            },
            item = "Nightveil Emblem - Priest",
          },
        },
        Warrior = {
          BellikosClaws = {
            aliases = {
              "Splintered Bellikos Claws",
            },
            ids = {
            },
            item = "Splintered Bellikos Claws",
          },
          BellikosFang = {
            aliases = {
              "Fragmented Bellikos Fang",
            },
            ids = {
            },
            item = "Fragmented Bellikos Fang",
          },
          BellikosTear = {
            aliases = {
              "Hardened Tear of the Bellikos",
            },
            ids = {
            },
            item = "Hardened Tear of the Bellikos",
          },
          Drink = {
            aliases = {
              "Bamboo Defender Margarita",
            },
            ids = {
            },
            item = "Bamboo Defender Margarita",
          },
          ["Ember (Pri)"] = {
            aliases = {
              "Ember of the Broodlords",
            },
            ids = {
            },
            item = "Ember of the Broodlords",
          },
          Food = {
            aliases = {
              "Armored Starfish Skewers",
            },
            ids = {
            },
            item = "Armored Starfish Skewers",
          },
          Idol = {
            aliases = {
              "9 Paths of Despair",
            },
            ids = {
            },
            item = "9 Paths of Despair",
          },
          ImbuedRune = {
            aliases = {
              "Imbued Rune of Brutal Onslaught",
            },
            ids = {
            },
            item = "Imbued Rune of Brutal Onslaught",
          },
          VeiledBastion = {
            aliases = {
              "Nightveil Emblem - Tank",
            },
            ids = {
              82787,
            },
            item = "Nightveil Emblem - Tank",
          },
        },
        Wizard = {
          BellikosEye = {
            aliases = {
              "Obsidian Bellikos Eye",
            },
            ids = {
            },
            item = "Obsidian Bellikos Eye",
          },
          Drink = {
            aliases = {
              "Arcane Ambrosia Daiquiri",
            },
            ids = {
            },
            item = "Arcane Ambrosia Daiquiri",
          },
          FireCrown = {
            aliases = {
              "Crown of Fire Nimbus",
            },
            ids = {
            },
            item = "Crown of Fire Nimbus",
          },
          Food = {
            aliases = {
              "Sorcerer's Spice Chicken",
            },
            ids = {
            },
            item = "Sorcerer's Spice Chicken",
          },
          Honed = {
            aliases = {
              "Honed Manastone",
            },
            ids = {
            },
            item = "Honed Manastone",
          },
          ImbuedRune = {
            aliases = {
              "Imbued Rune of Mana Weave",
            },
            ids = {
            },
            item = "Imbued Rune of Mana Weave",
          },
          ["Tacvi Clicky"] = {
            aliases = {
              "Scepter of Incantations",
            },
            ids = {
            },
            item = "Scepter of Incantations",
            source = "Zun'Muram Kvxe Pirik",
          },
          ["Veeshan Clicky"] = {
            aliases = {
              "Aged Shissar Elementalist's Staff",
            },
            ids = {
            },
            item = "Aged Shissar Elementalist's Staff",
            source = "Hoshkar",
          },
          VeiledEclipse = {
            aliases = {
              "Nightveil Emblem - Caster",
            },
            ids = {
              82790,
            },
            item = "Nightveil Emblem - Caster",
          },
        },
      },
      group = "Other Checklists",
      id = "questitems",
      name = "Quest Items",
      show_base = {
      },
      template = {
        BIC1 = {
          aliases = {
            "Black Gemstone of Death",
          },
          ids = {
          },
          item = "Black Gemstone of Death",
        },
        BIC2 = {
          aliases = {
            "Black Gemstone of Pain",
          },
          ids = {
          },
          item = "Black Gemstone of Pain",
        },
        BIC3 = {
          aliases = {
            "Black Gemstone of Suffering",
          },
          ids = {
          },
          item = "Black Gemstone of Suffering",
        },
        BIC4 = {
          aliases = {
            "Black Gemstone of Torture",
          },
          ids = {
          },
          item = "Black Gemstone of Torture",
        },
        BellikosDoll = {
          aliases = {
            "Living Bellikos Doll - Tranquility",
          },
          ids = {
          },
          item = "Living Bellikos Doll - Tranquility",
        },
        BloodcursedCrown = {
          aliases = {
            "Bloodcursed Crown of Vzith",
          },
          ids = {
          },
          item = "Bloodcursed Crown of Vzith",
        },
        Cleaving = {
          aliases = {
            "Hexed Umbra of Cleaving",
          },
          ids = {
          },
          item = "Hexed Umbra of Cleaving",
        },
        Deflection = {
          aliases = {
            "Hexed Umbra of Deflection",
          },
          ids = {
          },
          item = "Hexed Umbra of Deflection",
        },
        Destruction = {
          aliases = {
            "Hexed Umbra of Destruction",
          },
          ids = {
          },
          item = "Hexed Umbra of Destruction",
        },
        EOC = {
          aliases = {
            "Essence of Creation",
          },
          ids = {
            150402,
          },
          item = "Essence of Creation",
        },
        Evasion = {
          aliases = {
            "Hexed Umbra of Evasion",
          },
          ids = {
          },
          item = "Hexed Umbra of Evasion",
        },
        Eyes = {
          aliases = {
            "9 Eyes of the Ghost",
          },
          ids = {
          },
          item = "9 Eyes of the Ghost",
        },
        FabledBrew = {
          aliases = {
            "Fabled Blackout Brew",
          },
          ids = {
          },
          item = "Fabled Blackout Brew",
        },
        Ferocity = {
          aliases = {
            "Hexed Umbra of Ferocity",
          },
          ids = {
          },
          item = "Hexed Umbra of Ferocity",
        },
        FracturedIris = {
          aliases = {
            "Gaze of the Fractured Iris",
          },
          ids = {
          },
          item = "Gaze of the Fractured Iris",
        },
        GuardianPetamorph = {
          aliases = {
            "Petamorph Wand - Crystalline Guardian",
          },
          ids = {
          },
          item = "Petamorph Wand - Crystalline Guardian",
        },
        HeartAnguish = {
          aliases = {
            "Heart of Anguish",
          },
          ids = {
          },
          item = "Heart of Anguish",
        },
        HeartDread = {
          aliases = {
            "Heart of Dread",
          },
          ids = {
          },
          item = "Heart of Dread",
        },
        Horseshoe = {
          aliases = {
            "9 Spheres of Ascension",
          },
          ids = {
          },
          item = "9 Spheres of Ascension",
        },
        IntricateFigurine = {
          aliases = {
            "Intricate Wooden Figurine",
          },
          ids = {
          },
          item = "Intricate Wooden Figurine",
        },
        ["Kithikor PortKey"] = {
          aliases = {
            "Dollmaker's Key",
          },
          ids = {
          },
          item = "Dollmaker's Key",
        },
        LazCharm = {
          aliases = {
            "Master Lazarus Charm",
          },
          ids = {
          },
          item = "Master Lazarus Charm",
        },
        ["Lucky Copper/Silver"] = {
          aliases = {
            "Tarnished Coin of the Triad Oath",
            "Blackened Tithe of the Triumvirate",
          },
          ids = {
          },
          item = "Tarnished Coin of the Triad Oath",
        },
        ["Lucky Grass Trinket"] = {
          aliases = {
            "Woven Fetish of the Trine Sentinel",
          },
          ids = {
          },
          item = "Woven Fetish of the Trine Sentinel",
        },
        LuminousEssence = {
          aliases = {
            "Luminous Essence",
          },
          ids = {
            50633,
          },
          item = "Luminous Essence",
        },
        Mending = {
          aliases = {
            "Hexed Umbra of Mending",
          },
          ids = {
          },
          item = "Hexed Umbra of Mending",
        },
        Oculus = {
          aliases = {
            "9 Echoes of Reflection",
          },
          ids = {
          },
          item = "9 Echoes of Reflection",
        },
        OtherworldlySoul = {
          aliases = {
            "Otherworldly Soul",
          },
          ids = {
          },
          item = "Otherworldly Soul",
        },
        Persistence = {
          aliases = {
            "Hexed Umbra of Persistence",
          },
          ids = {
          },
          item = "Hexed Umbra of Persistence",
        },
        Radix = {
          aliases = {
            "Radix",
          },
          ids = {
          },
          item = "Radix",
        },
        Satchel = {
          aliases = {
            "Ascendant Dragonhide Satchel",
          },
          ids = {
          },
          item = "Ascendant Dragonhide Satchel",
        },
        Sigil = {
          aliases = {
            "Sigil of the Claws",
          },
          ids = {
          },
          item = "Sigil of the Claws",
        },
        Suffering = {
          aliases = {
            "Hexed Umbra of Suffering",
          },
          ids = {
          },
          item = "Hexed Umbra of Suffering",
        },
        Symbol = {
          aliases = {
            "Symbol of Uhl'Zaroth",
          },
          ids = {
          },
          item = "Symbol of Uhl'Zaroth",
        },
        Tongue = {
          aliases = {
            "9 Realms of Transition",
          },
          ids = {
          },
          item = "9 Realms of Transition",
        },
        Wayfarer = {
          aliases = {
            "Wayfarers Brotherhood Emblem",
          },
          ids = {
          },
          item = "Wayfarers Brotherhood Emblem",
        },
        ["West Karana PortKey"] = {
          aliases = {
            "Moonlit Mirror",
          },
          ids = {
          },
          item = "Moonlit Mirror",
        },
      },
      visible = {
      },
    },
    sebilis = {
      categories = {
        {
          name = "Epic",
          slots = {
            "Epic2.5",
          },
        },
        {
          name = "Originator's Overlooked Oddity",
          slots = {
            "PSAug1",
            "PSAug2",
            "PSAug3",
            "PSAugSprings",
            "PSAugContainer",
            "PSAugFinal",
          },
        },
        {
          name = "Infused Flux Augs",
          slots = {
            "FluxAug1 (Spell Shield)",
            "FluxAug2 (Regen)",
            "FluxAug3 (20 Attack/Acc)",
            "FluxAug4 (50 Attack/Acc)",
            "FluxAug5 (20 Attack/Acc)",
            "FluxAug6 (Regen)",
            "FluxAug7 (Dot/Stun)",
            "FluxAug8 (3 Shield/5 Avoidance)",
            "FluxAug9 (Avoidance)",
          },
        },
        {
          name = "Noxious Bloom Augs",
          slots = {
            "FlowerAug1 (Parry/Block)",
            "FlowerAug2 (Increase Duration)",
            "FlowerAug3 (Double Attack)",
            "FlowerAug4 (Crit)",
            "FlowerAug5 (Dodge)",
            "FlowerAug6 (Healing)",
            "FlowerAug7 (Reduce Mana Cost)",
          },
        },
        {
          name = "Slime of Suffering Augs",
          slots = {
            "SlimeAug1 (Poison)",
            "SlimeAug2 (Cold)",
            "SlimeAug3 (Disease)",
            "SlimeAug4 (Magic)",
            "SlimeAug5 (Fire)",
          },
        },
        {
          name = "Weapon Augs",
          slots = {
            "WeaponAug1",
            "WeaponAug2",
            "WeaponAug3",
            "WeaponAug4",
            "WeaponAug5",
            "WeaponAug6",
            "WeaponAug7",
            "WeaponAug8",
            "WeaponAug9",
            "WeaponAug10",
            "WeaponAug11",
            "WeaponAug12",
            "WeaponAug13",
          },
        },
        {
          name = "Forsaken Armor",
          slots = {
            "Arms",
            "Chest",
            "Feet",
            "Hands",
            "Head",
            "Legs",
            "Wrist",
          },
        },
        {
          name = "Forsaken Clickies",
          slots = {
            "ClickyWep1",
            "ClickyWep2",
            "ClickyWep3",
            "ClickyWep4",
            "ClickyWep5",
            "ClickyWep6",
            "ClickyWep7",
            "ClickyWep8",
            "Fungi",
          },
        },
      },
      classes = {
        Bard = {
          Arms = {
            aliases = {
              "Forsaken Singing Steel Vambraces",
            },
            ids = {
              36017,
            },
            item = "Forsaken Singing Steel Vambraces",
          },
          Chest = {
            aliases = {
              "Forsaken Singing Steel Breastplate",
            },
            ids = {
              36033,
            },
            item = "Forsaken Singing Steel Breastplate",
          },
          ClickyWep1 = {
            aliases = {
              "Forsaken Rod of Lamentation",
            },
            ids = {
            },
            item = "Forsaken Rod of Lamentation",
          },
          ClickyWep2 = {
            aliases = {
              "Forsaken Sword of the Morning",
            },
            ids = {
            },
            item = "Forsaken Sword of the Morning",
          },
          ClickyWep3 = {
            aliases = {
              "Forsaken Fayguard Bladecatcher",
            },
            ids = {
            },
            item = "Forsaken Fayguard Bladecatcher",
          },
          ClickyWep5 = {
            aliases = {
              "Forsaken Shieldstorm",
            },
            ids = {
            },
            item = "Forsaken Shieldstorm",
          },
          ClickyWep8 = {
            aliases = {
              "Forsaken Zealot's Incarnadine Sword",
            },
            ids = {
            },
            item = "Forsaken Zealot's Incarnadine Sword",
          },
          ["Epic2.5"] = {
            aliases = {
              "Ancient Blade of Vesagran",
            },
            ids = {
            },
            item = "Ancient Blade of Vesagran",
          },
          Feet = {
            aliases = {
              "Forsaken Singing Steel Boots",
            },
            ids = {
              39603,
            },
            item = "Forsaken Singing Steel Boots",
          },
          Hands = {
            aliases = {
              "Forsaken Singing Steel Gauntlets",
            },
            ids = {
              39628,
            },
            item = "Forsaken Singing Steel Gauntlets",
          },
          Head = {
            aliases = {
              "Forsaken Singing Steel Helm",
            },
            ids = {
              39596,
            },
            item = "Forsaken Singing Steel Helm",
          },
          Legs = {
            aliases = {
              "Forsaken Singing Steel Greaves",
            },
            ids = {
              40388,
            },
            item = "Forsaken Singing Steel Greaves",
          },
          WeaponAug1 = {
            aliases = {
              "Desolate Black Sapphire",
            },
            ids = {
            },
            item = "Desolate Black Sapphire",
          },
          WeaponAug12 = {
            aliases = {
              "Grotesque Skull of Grit",
            },
            ids = {
            },
            item = "Grotesque Skull of Grit",
          },
          WeaponAug2 = {
            aliases = {
              "Desolate Bloodstone",
            },
            ids = {
            },
            item = "Desolate Bloodstone",
          },
          WeaponAug3 = {
            aliases = {
              "Desolate Carnelian",
            },
            ids = {
            },
            item = "Desolate Carnelian",
          },
          WeaponAug4 = {
            aliases = {
              "Desolate Cat's Eye Agate",
            },
            ids = {
            },
            item = "Desolate Cat's Eye Agate",
          },
          WeaponAug5 = {
            aliases = {
              "Desolate Fire Emerald",
            },
            ids = {
            },
            item = "Desolate Fire Emerald",
          },
          WeaponAug6 = {
            aliases = {
              "Desolate Hematite",
            },
            ids = {
            },
            item = "Desolate Hematite",
          },
          WeaponAug7 = {
            aliases = {
              "Desolate Onyx",
            },
            ids = {
            },
            item = "Desolate Onyx",
          },
          Wrist = {
            aliases = {
              "Forsaken Singing Steel Bracer",
            },
            ids = {
              33210,
            },
            item = "Forsaken Singing Steel Bracer",
          },
        },
        Beastlord = {
          Arms = {
            aliases = {
              "Forsaken Wild Lord's Sleeves",
            },
            ids = {
              36016,
            },
            item = "Forsaken Wild Lord's Sleeves",
          },
          Chest = {
            aliases = {
              "Forsaken Wild Lord's Tunic",
            },
            ids = {
              36032,
            },
            item = "Forsaken Wild Lord's Tunic",
          },
          ClickyWep3 = {
            aliases = {
              "Forsaken Fayguard Bladecatcher",
            },
            ids = {
            },
            item = "Forsaken Fayguard Bladecatcher",
          },
          ClickyWep4 = {
            aliases = {
              "Forsaken Sword of Skyfire",
            },
            ids = {
            },
            item = "Forsaken Sword of Skyfire",
          },
          ClickyWep6 = {
            aliases = {
              "Forsaken Breath of Harmony",
            },
            ids = {
            },
            item = "Forsaken Breath of Harmony",
          },
          ClickyWep7 = {
            aliases = {
              "Forsaken Poison Wind Censer",
            },
            ids = {
            },
            item = "Forsaken Poison Wind Censer",
          },
          ["Epic2.5"] = {
            aliases = {
              "Spiritcaller Totem of the Ancients",
            },
            ids = {
            },
            item = "Spiritcaller Totem of the Ancients",
          },
          Feet = {
            aliases = {
              "Forsaken Wild Lord's Sandals",
            },
            ids = {
              39608,
            },
            item = "Forsaken Wild Lord's Sandals",
          },
          Hands = {
            aliases = {
              "Forsaken Wild Lord's Gauntlets",
            },
            ids = {
              39627,
            },
            item = "Forsaken Wild Lord's Gauntlets",
          },
          Head = {
            aliases = {
              "Forsaken Wild Lord's Crown",
            },
            ids = {
              39595,
            },
            item = "Forsaken Wild Lord's Crown",
          },
          Legs = {
            aliases = {
              "Forsaken Wild Lord's Trousers",
            },
            ids = {
              40387,
            },
            item = "Forsaken Wild Lord's Trousers",
          },
          WeaponAug1 = {
            aliases = {
              "Desolate Black Sapphire",
            },
            ids = {
            },
            item = "Desolate Black Sapphire",
          },
          WeaponAug10 = {
            aliases = {
              "Desolate Star Rose Quartz",
            },
            ids = {
            },
            item = "Desolate Star Rose Quartz",
          },
          WeaponAug11 = {
            aliases = {
              "Desolate Star Ruby",
            },
            ids = {
            },
            item = "Desolate Star Ruby",
          },
          WeaponAug12 = {
            aliases = {
              "Grotesque Skull of Grit",
            },
            ids = {
            },
            item = "Grotesque Skull of Grit",
          },
          WeaponAug2 = {
            aliases = {
              "Desolate Bloodstone",
            },
            ids = {
            },
            item = "Desolate Bloodstone",
          },
          WeaponAug3 = {
            aliases = {
              "Desolate Carnelian",
            },
            ids = {
            },
            item = "Desolate Carnelian",
          },
          WeaponAug4 = {
            aliases = {
              "Desolate Cat's Eye Agate",
            },
            ids = {
            },
            item = "Desolate Cat's Eye Agate",
          },
          WeaponAug5 = {
            aliases = {
              "Desolate Fire Emerald",
            },
            ids = {
            },
            item = "Desolate Fire Emerald",
          },
          WeaponAug6 = {
            aliases = {
              "Desolate Hematite",
            },
            ids = {
            },
            item = "Desolate Hematite",
          },
          WeaponAug7 = {
            aliases = {
              "Desolate Onyx",
            },
            ids = {
            },
            item = "Desolate Onyx",
          },
          WeaponAug8 = {
            aliases = {
              "Desolate Lapis Lazuli",
            },
            ids = {
            },
            item = "Desolate Lapis Lazuli",
          },
          WeaponAug9 = {
            aliases = {
              "Desolate Malachite",
            },
            ids = {
            },
            item = "Desolate Malachite",
          },
          Wrist = {
            aliases = {
              "Forsaken Wild Lord's Bracer",
            },
            ids = {
              33209,
            },
            item = "Forsaken Wild Lord's Bracer",
          },
        },
        Berserker = {
          Arms = {
            aliases = {
              "Forsaken Sleeves of Wrath",
            },
            ids = {
              33214,
            },
            item = "Forsaken Sleeves of Wrath",
          },
          Chest = {
            aliases = {
              "Forsaken Tunic of Wrath",
            },
            ids = {
              36021,
            },
            item = "Forsaken Tunic of Wrath",
          },
          ClickyWep2 = {
            aliases = {
              "Forsaken Sword of the Morning",
            },
            ids = {
            },
            item = "Forsaken Sword of the Morning",
          },
          ClickyWep3 = {
            aliases = {
              "Forsaken Fayguard Bladecatcher",
            },
            ids = {
            },
            item = "Forsaken Fayguard Bladecatcher",
          },
          ClickyWep4 = {
            aliases = {
              "Forsaken Sword of Skyfire",
            },
            ids = {
            },
            item = "Forsaken Sword of Skyfire",
          },
          ClickyWep5 = {
            aliases = {
              "Forsaken Shieldstorm",
            },
            ids = {
            },
            item = "Forsaken Shieldstorm",
          },
          ["Epic2.5"] = {
            aliases = {
              "Ancient Taelosian Blood Axe",
            },
            ids = {
            },
            item = "Ancient Taelosian Blood Axe",
          },
          Feet = {
            aliases = {
              "Forsaken Boots of Wrath",
            },
            ids = {
              39602,
            },
            item = "Forsaken Boots of Wrath",
          },
          Hands = {
            aliases = {
              "Forsaken Gloves of Wrath",
            },
            ids = {
              39616,
            },
            item = "Forsaken Gloves of Wrath",
          },
          Head = {
            aliases = {
              "Forsaken Coif of Wrath",
            },
            ids = {
              39087,
            },
            item = "Forsaken Coif of Wrath",
          },
          Legs = {
            aliases = {
              "Forsaken Leggings of Wrath",
            },
            ids = {
              40376,
            },
            item = "Forsaken Leggings of Wrath",
          },
          WeaponAug1 = {
            aliases = {
              "Desolate Black Sapphire",
            },
            ids = {
            },
            item = "Desolate Black Sapphire",
          },
          WeaponAug12 = {
            aliases = {
              "Grotesque Skull of Grit",
            },
            ids = {
            },
            item = "Grotesque Skull of Grit",
          },
          WeaponAug2 = {
            aliases = {
              "Desolate Bloodstone",
            },
            ids = {
            },
            item = "Desolate Bloodstone",
          },
          WeaponAug3 = {
            aliases = {
              "Desolate Carnelian",
            },
            ids = {
            },
            item = "Desolate Carnelian",
          },
          WeaponAug4 = {
            aliases = {
              "Desolate Cat's Eye Agate",
            },
            ids = {
            },
            item = "Desolate Cat's Eye Agate",
          },
          WeaponAug5 = {
            aliases = {
              "Desolate Fire Emerald",
            },
            ids = {
            },
            item = "Desolate Fire Emerald",
          },
          WeaponAug6 = {
            aliases = {
              "Desolate Hematite",
            },
            ids = {
            },
            item = "Desolate Hematite",
          },
          WeaponAug7 = {
            aliases = {
              "Desolate Onyx",
            },
            ids = {
            },
            item = "Desolate Onyx",
          },
          Wrist = {
            aliases = {
              "Forsaken Bracer of Wrath",
            },
            ids = {
              33198,
            },
            item = "Forsaken Bracer of Wrath",
          },
        },
        Cleric = {
          Arms = {
            aliases = {
              "Forsaken Donal's Vambraces of Mourning",
            },
            ids = {
              33215,
            },
            item = "Forsaken Donal's Vambraces of Mourning",
          },
          Chest = {
            aliases = {
              "Forsaken Donal's Chestplate of Mourning",
            },
            ids = {
              36022,
            },
            item = "Forsaken Donal's Chestplate of Mourning",
          },
          ClickyWep1 = {
            aliases = {
              "Forsaken Rod of Lamentation",
            },
            ids = {
            },
            item = "Forsaken Rod of Lamentation",
          },
          ClickyWep2 = {
            aliases = {
              "Forsaken Sword of the Morning",
            },
            ids = {
            },
            item = "Forsaken Sword of the Morning",
          },
          ClickyWep5 = {
            aliases = {
              "Forsaken Shieldstorm",
            },
            ids = {
            },
            item = "Forsaken Shieldstorm",
          },
          ClickyWep8 = {
            aliases = {
              "Forsaken Zealot's Incarnadine Sword",
            },
            ids = {
            },
            item = "Forsaken Zealot's Incarnadine Sword",
          },
          ["Epic2.5"] = {
            aliases = {
              "Aegis of Ancient Divinity",
            },
            ids = {
            },
            item = "Aegis of Ancient Divinity",
          },
          Feet = {
            aliases = {
              "Forsaken Donal's Boots of Mourning",
            },
            ids = {
              39612,
            },
            item = "Forsaken Donal's Boots of Mourning",
          },
          Hands = {
            aliases = {
              "Forsaken Donal's Gauntlets of Mourning",
            },
            ids = {
              39621,
            },
            item = "Forsaken Donal's Gauntlets of Mourning",
          },
          Head = {
            aliases = {
              "Forsaken Donal's Helm of Mourning",
            },
            ids = {
              39088,
            },
            item = "Forsaken Donal's Helm of Mourning",
          },
          Legs = {
            aliases = {
              "Forsaken Donal's Leggings of Mourning",
            },
            ids = {
              40377,
            },
            item = "Forsaken Donal's Leggings of Mourning",
          },
          WeaponAug10 = {
            aliases = {
              "Desolate Star Rose Quartz",
            },
            ids = {
            },
            item = "Desolate Star Rose Quartz",
          },
          WeaponAug11 = {
            aliases = {
              "Desolate Star Ruby",
            },
            ids = {
            },
            item = "Desolate Star Ruby",
          },
          WeaponAug12 = {
            aliases = {
              "Grotesque Skull of Grit",
            },
            ids = {
            },
            item = "Grotesque Skull of Grit",
          },
          WeaponAug6 = {
            aliases = {
              "Desolate Hematite",
            },
            ids = {
            },
            item = "Desolate Hematite",
          },
          WeaponAug8 = {
            aliases = {
              "Desolate Lapis Lazuli",
            },
            ids = {
            },
            item = "Desolate Lapis Lazuli",
          },
          WeaponAug9 = {
            aliases = {
              "Desolate Malachite",
            },
            ids = {
            },
            item = "Desolate Malachite",
          },
          Wrist = {
            aliases = {
              "Forsaken Donal's Bracer of Mourning",
            },
            ids = {
              33199,
            },
            item = "Forsaken Donal's Bracer of Mourning",
          },
        },
        Druid = {
          Arms = {
            aliases = {
              "Forsaken Elder Spiritist's Vambraces",
            },
            ids = {
              33217,
            },
            item = "Forsaken Elder Spiritist's Vambraces",
          },
          Chest = {
            aliases = {
              "Forsaken Elder Spiritist's Breastplate",
            },
            ids = {
              36024,
            },
            item = "Forsaken Elder Spiritist's Breastplate",
          },
          ClickyWep1 = {
            aliases = {
              "Forsaken Rod of Lamentation",
            },
            ids = {
            },
            item = "Forsaken Rod of Lamentation",
          },
          ClickyWep4 = {
            aliases = {
              "Forsaken Sword of Skyfire",
            },
            ids = {
            },
            item = "Forsaken Sword of Skyfire",
          },
          ClickyWep5 = {
            aliases = {
              "Forsaken Shieldstorm",
            },
            ids = {
            },
            item = "Forsaken Shieldstorm",
          },
          ClickyWep7 = {
            aliases = {
              "Forsaken Poison Wind Censer",
            },
            ids = {
            },
            item = "Forsaken Poison Wind Censer",
          },
          ["Epic2.5"] = {
            aliases = {
              "Staff of Ancient Brambles",
            },
            ids = {
            },
            item = "Staff of Ancient Brambles",
          },
          Feet = {
            aliases = {
              "Forsaken Elder Spiritist's Boots",
            },
            ids = {
              39605,
            },
            item = "Forsaken Elder Spiritist's Boots",
          },
          Hands = {
            aliases = {
              "Forsaken Elder Spiritist's Gauntlets",
            },
            ids = {
              39623,
            },
            item = "Forsaken Elder Spiritist's Gauntlets",
          },
          Head = {
            aliases = {
              "Forsaken Elder Spiritist's Helm",
            },
            ids = {
              39090,
            },
            item = "Forsaken Elder Spiritist's Helm",
          },
          Legs = {
            aliases = {
              "Forsaken Elder Spiritist's Greaves",
            },
            ids = {
              40379,
            },
            item = "Forsaken Elder Spiritist's Greaves",
          },
          WeaponAug10 = {
            aliases = {
              "Desolate Star Rose Quartz",
            },
            ids = {
            },
            item = "Desolate Star Rose Quartz",
          },
          WeaponAug11 = {
            aliases = {
              "Desolate Star Ruby",
            },
            ids = {
            },
            item = "Desolate Star Ruby",
          },
          WeaponAug12 = {
            aliases = {
              "Grotesque Skull of Grit",
            },
            ids = {
            },
            item = "Grotesque Skull of Grit",
          },
          WeaponAug6 = {
            aliases = {
              "Desolate Hematite",
            },
            ids = {
            },
            item = "Desolate Hematite",
          },
          WeaponAug8 = {
            aliases = {
              "Desolate Lapis Lazuli",
            },
            ids = {
            },
            item = "Desolate Lapis Lazuli",
          },
          WeaponAug9 = {
            aliases = {
              "Desolate Malachite",
            },
            ids = {
            },
            item = "Desolate Malachite",
          },
          Wrist = {
            aliases = {
              "Forsaken Elder Spiritist's Bracer",
            },
            ids = {
              33201,
            },
            item = "Forsaken Elder Spiritist's Bracer",
          },
        },
        Enchanter = {
          Arms = {
            aliases = {
              "Forsaken Illusionist's Sleeves",
            },
            ids = {
              33220,
            },
            item = "Forsaken Illusionist's Sleeves",
          },
          Chest = {
            aliases = {
              "Forsaken Illusionist's Blouse",
            },
            ids = {
              36027,
            },
            item = "Forsaken Illusionist's Blouse",
          },
          ClickyWep1 = {
            aliases = {
              "Forsaken Rod of Lamentation",
            },
            ids = {
            },
            item = "Forsaken Rod of Lamentation",
          },
          ClickyWep2 = {
            aliases = {
              "Forsaken Sword of the Morning",
            },
            ids = {
            },
            item = "Forsaken Sword of the Morning",
          },
          ClickyWep6 = {
            aliases = {
              "Forsaken Breath of Harmony",
            },
            ids = {
            },
            item = "Forsaken Breath of Harmony",
          },
          ClickyWep8 = {
            aliases = {
              "Forsaken Zealot's Incarnadine Sword",
            },
            ids = {
            },
            item = "Forsaken Zealot's Incarnadine Sword",
          },
          ["Epic2.5"] = {
            aliases = {
              "Staff of Ancient Eloquence",
            },
            ids = {
            },
            item = "Staff of Ancient Eloquence",
          },
          Feet = {
            aliases = {
              "Forsaken Illusionist's Shoes",
            },
            ids = {
              39611,
            },
            item = "Forsaken Illusionist's Shoes",
          },
          Hands = {
            aliases = {
              "Forsaken Illusionist's Gloves",
            },
            ids = {
              39619,
            },
            item = "Forsaken Illusionist's Gloves",
          },
          Head = {
            aliases = {
              "Forsaken Illusionist's Cap",
            },
            ids = {
              39590,
            },
            item = "Forsaken Illusionist's Cap",
          },
          Legs = {
            aliases = {
              "Forsaken Illusionist's Trousers",
            },
            ids = {
              40382,
            },
            item = "Forsaken Illusionist's Trousers",
          },
          WeaponAug10 = {
            aliases = {
              "Desolate Star Rose Quartz",
            },
            ids = {
            },
            item = "Desolate Star Rose Quartz",
          },
          WeaponAug11 = {
            aliases = {
              "Desolate Star Ruby",
            },
            ids = {
            },
            item = "Desolate Star Ruby",
          },
          WeaponAug12 = {
            aliases = {
              "Grotesque Skull of Grit",
            },
            ids = {
            },
            item = "Grotesque Skull of Grit",
          },
          WeaponAug8 = {
            aliases = {
              "Desolate Lapis Lazuli",
            },
            ids = {
            },
            item = "Desolate Lapis Lazuli",
          },
          WeaponAug9 = {
            aliases = {
              "Desolate Malachite",
            },
            ids = {
            },
            item = "Desolate Malachite",
          },
          Wrist = {
            aliases = {
              "Forsaken Illusionist's Bracelet",
            },
            ids = {
              33204,
            },
            item = "Forsaken Illusionist's Bracelet",
          },
        },
        Magician = {
          Arms = {
            aliases = {
              "Forsaken Conjurer's Sleeves",
            },
            ids = {
              33219,
            },
            item = "Forsaken Conjurer's Sleeves",
          },
          Chest = {
            aliases = {
              "Forsaken Conjurer's Blouse",
            },
            ids = {
              36026,
            },
            item = "Forsaken Conjurer's Blouse",
          },
          ClickyWep1 = {
            aliases = {
              "Forsaken Rod of Lamentation",
            },
            ids = {
            },
            item = "Forsaken Rod of Lamentation",
          },
          ClickyWep4 = {
            aliases = {
              "Forsaken Sword of Skyfire",
            },
            ids = {
            },
            item = "Forsaken Sword of Skyfire",
          },
          ClickyWep6 = {
            aliases = {
              "Forsaken Breath of Harmony",
            },
            ids = {
            },
            item = "Forsaken Breath of Harmony",
          },
          ClickyWep7 = {
            aliases = {
              "Forsaken Poison Wind Censer",
            },
            ids = {
            },
            item = "Forsaken Poison Wind Censer",
          },
          ["Epic2.5"] = {
            aliases = {
              "Focus of Ancient Elements",
            },
            ids = {
            },
            item = "Focus of Ancient Elements",
          },
          Feet = {
            aliases = {
              "Forsaken Conjurer's Shoes",
            },
            ids = {
              39606,
            },
            item = "Forsaken Conjurer's Shoes",
          },
          Hands = {
            aliases = {
              "Forsaken Conjurer's Gloves",
            },
            ids = {
              39618,
            },
            item = "Forsaken Conjurer's Gloves",
          },
          Head = {
            aliases = {
              "Forsaken Conjurer's Cap",
            },
            ids = {
              39589,
            },
            item = "Forsaken Conjurer's Cap",
          },
          Legs = {
            aliases = {
              "Forsaken Conjurer's Trousers",
            },
            ids = {
              40381,
            },
            item = "Forsaken Conjurer's Trousers",
          },
          WeaponAug10 = {
            aliases = {
              "Desolate Star Rose Quartz",
            },
            ids = {
            },
            item = "Desolate Star Rose Quartz",
          },
          WeaponAug11 = {
            aliases = {
              "Desolate Star Ruby",
            },
            ids = {
            },
            item = "Desolate Star Ruby",
          },
          WeaponAug12 = {
            aliases = {
              "Grotesque Skull of Grit",
            },
            ids = {
            },
            item = "Grotesque Skull of Grit",
          },
          WeaponAug8 = {
            aliases = {
              "Desolate Lapis Lazuli",
            },
            ids = {
            },
            item = "Desolate Lapis Lazuli",
          },
          WeaponAug9 = {
            aliases = {
              "Desolate Malachite",
            },
            ids = {
            },
            item = "Desolate Malachite",
          },
          Wrist = {
            aliases = {
              "Forsaken Conjurer's Bracelet",
            },
            ids = {
              33203,
            },
            item = "Forsaken Conjurer's Bracelet",
          },
        },
        Monk = {
          Arms = {
            aliases = {
              "Forsaken Martialist Sleeves",
            },
            ids = {
              33212,
            },
            item = "Forsaken Martialist Sleeves",
          },
          Chest = {
            aliases = {
              "Forsaken Martialist Chestguard",
            },
            ids = {
              36019,
            },
            item = "Forsaken Martialist Chestguard",
          },
          ClickyWep2 = {
            aliases = {
              "Forsaken Sword of the Morning",
            },
            ids = {
            },
            item = "Forsaken Sword of the Morning",
          },
          ClickyWep3 = {
            aliases = {
              "Forsaken Fayguard Bladecatcher",
            },
            ids = {
            },
            item = "Forsaken Fayguard Bladecatcher",
          },
          ClickyWep5 = {
            aliases = {
              "Forsaken Shieldstorm",
            },
            ids = {
            },
            item = "Forsaken Shieldstorm",
          },
          ClickyWep8 = {
            aliases = {
              "Forsaken Zealot's Incarnadine Sword",
            },
            ids = {
            },
            item = "Forsaken Zealot's Incarnadine Sword",
          },
          ["Epic2.5"] = {
            aliases = {
              "Ancient Fistwraps of Immortality",
            },
            ids = {
            },
            item = "Ancient Fistwraps of Immortality",
          },
          Feet = {
            aliases = {
              "Forsaken Martialist Sandals",
            },
            ids = {
              39600,
            },
            item = "Forsaken Martialist Sandals",
          },
          Hands = {
            aliases = {
              "Forsaken Martialist Gloves",
            },
            ids = {
              39614,
            },
            item = "Forsaken Martialist Gloves",
          },
          Head = {
            aliases = {
              "Forsaken Martialist Cap",
            },
            ids = {
              39085,
            },
            item = "Forsaken Martialist Cap",
          },
          Legs = {
            aliases = {
              "Forsaken Martialist Pants",
            },
            ids = {
              40374,
            },
            item = "Forsaken Martialist Pants",
          },
          WeaponAug1 = {
            aliases = {
              "Desolate Black Sapphire",
            },
            ids = {
            },
            item = "Desolate Black Sapphire",
          },
          WeaponAug12 = {
            aliases = {
              "Grotesque Skull of Grit",
            },
            ids = {
            },
            item = "Grotesque Skull of Grit",
          },
          WeaponAug2 = {
            aliases = {
              "Desolate Bloodstone",
            },
            ids = {
            },
            item = "Desolate Bloodstone",
          },
          WeaponAug3 = {
            aliases = {
              "Desolate Carnelian",
            },
            ids = {
            },
            item = "Desolate Carnelian",
          },
          WeaponAug4 = {
            aliases = {
              "Desolate Cat's Eye Agate",
            },
            ids = {
            },
            item = "Desolate Cat's Eye Agate",
          },
          WeaponAug5 = {
            aliases = {
              "Desolate Fire Emerald",
            },
            ids = {
            },
            item = "Desolate Fire Emerald",
          },
          WeaponAug6 = {
            aliases = {
              "Desolate Hematite",
            },
            ids = {
            },
            item = "Desolate Hematite",
          },
          WeaponAug7 = {
            aliases = {
              "Desolate Onyx",
            },
            ids = {
            },
            item = "Desolate Onyx",
          },
          Wrist = {
            aliases = {
              "Forsaken Martialist Wristguard",
            },
            ids = {
              33196,
            },
            item = "Forsaken Martialist Wristguard",
          },
        },
        Necromancer = {
          Arms = {
            aliases = {
              "Forsaken Graverobber's Sleeves",
            },
            ids = {
              33221,
            },
            item = "Forsaken Graverobber's Sleeves",
          },
          Chest = {
            aliases = {
              "Forsaken Graverobber's Blouse",
            },
            ids = {
              36028,
            },
            item = "Forsaken Graverobber's Blouse",
          },
          ClickyWep1 = {
            aliases = {
              "Forsaken Rod of Lamentation",
            },
            ids = {
            },
            item = "Forsaken Rod of Lamentation",
          },
          ClickyWep6 = {
            aliases = {
              "Forsaken Breath of Harmony",
            },
            ids = {
            },
            item = "Forsaken Breath of Harmony",
          },
          ClickyWep7 = {
            aliases = {
              "Forsaken Poison Wind Censer",
            },
            ids = {
            },
            item = "Forsaken Poison Wind Censer",
          },
          ClickyWep8 = {
            aliases = {
              "Forsaken Zealot's Incarnadine Sword",
            },
            ids = {
            },
            item = "Forsaken Zealot's Incarnadine Sword",
          },
          ["Epic2.5"] = {
            aliases = {
              "Ancient Deathwhisper",
            },
            ids = {
            },
            item = "Ancient Deathwhisper",
          },
          Feet = {
            aliases = {
              "Forsaken Graverobber's Shoes",
            },
            ids = {
              39607,
            },
            item = "Forsaken Graverobber's Shoes",
          },
          Hands = {
            aliases = {
              "Forsaken Graverobber's Gloves",
            },
            ids = {
              39620,
            },
            item = "Forsaken Graverobber's Gloves",
          },
          Head = {
            aliases = {
              "Forsaken Graverobber's Cap",
            },
            ids = {
              39591,
            },
            item = "Forsaken Graverobber's Cap",
          },
          Legs = {
            aliases = {
              "Forsaken Graverobber's Trousers",
            },
            ids = {
              40383,
            },
            item = "Forsaken Graverobber's Trousers",
          },
          WeaponAug10 = {
            aliases = {
              "Desolate Star Rose Quartz",
            },
            ids = {
            },
            item = "Desolate Star Rose Quartz",
          },
          WeaponAug11 = {
            aliases = {
              "Desolate Star Ruby",
            },
            ids = {
            },
            item = "Desolate Star Ruby",
          },
          WeaponAug12 = {
            aliases = {
              "Grotesque Skull of Grit",
            },
            ids = {
            },
            item = "Grotesque Skull of Grit",
          },
          WeaponAug8 = {
            aliases = {
              "Desolate Lapis Lazuli",
            },
            ids = {
            },
            item = "Desolate Lapis Lazuli",
          },
          WeaponAug9 = {
            aliases = {
              "Desolate Malachite",
            },
            ids = {
            },
            item = "Desolate Malachite",
          },
          Wrist = {
            aliases = {
              "Forsaken Graverobber's Bracelet",
            },
            ids = {
              33205,
            },
            item = "Forsaken Graverobber's Bracelet",
          },
        },
        Paladin = {
          Arms = {
            aliases = {
              "Forsaken Deepwater Vambraces",
            },
            ids = {
              36014,
            },
            item = "Forsaken Deepwater Vambraces",
          },
          Chest = {
            aliases = {
              "Forsaken Deepwater Breastplate",
            },
            ids = {
              36030,
            },
            item = "Forsaken Deepwater Breastplate",
          },
          ClickyWep2 = {
            aliases = {
              "Forsaken Sword of the Morning",
            },
            ids = {
            },
            item = "Forsaken Sword of the Morning",
          },
          ClickyWep3 = {
            aliases = {
              "Forsaken Fayguard Bladecatcher",
            },
            ids = {
            },
            item = "Forsaken Fayguard Bladecatcher",
          },
          ClickyWep4 = {
            aliases = {
              "Forsaken Sword of Skyfire",
            },
            ids = {
            },
            item = "Forsaken Sword of Skyfire",
          },
          ClickyWep6 = {
            aliases = {
              "Forsaken Breath of Harmony",
            },
            ids = {
            },
            item = "Forsaken Breath of Harmony",
          },
          ["Epic2.5"] = {
            aliases = {
              "Nightbane, Sword of the Ancients",
            },
            ids = {
            },
            item = "Nightbane, Sword of the Ancients",
          },
          Feet = {
            aliases = {
              "Forsaken Deepwater Boots",
            },
            ids = {
              39599,
            },
            item = "Forsaken Deepwater Boots",
          },
          Hands = {
            aliases = {
              "Forsaken Deepwater Gauntlets",
            },
            ids = {
              39625,
            },
            item = "Forsaken Deepwater Gauntlets",
          },
          Head = {
            aliases = {
              "Forsaken Deepwater Helm",
            },
            ids = {
              39593,
            },
            item = "Forsaken Deepwater Helm",
          },
          Legs = {
            aliases = {
              "Forsaken Deepwater Greaves",
            },
            ids = {
              40385,
            },
            item = "Forsaken Deepwater Greaves",
          },
          WeaponAug1 = {
            aliases = {
              "Desolate Black Sapphire",
            },
            ids = {
            },
            item = "Desolate Black Sapphire",
          },
          WeaponAug10 = {
            aliases = {
              "Desolate Star Rose Quartz",
            },
            ids = {
            },
            item = "Desolate Star Rose Quartz",
          },
          WeaponAug11 = {
            aliases = {
              "Desolate Star Ruby",
            },
            ids = {
            },
            item = "Desolate Star Ruby",
          },
          WeaponAug12 = {
            aliases = {
              "Grotesque Skull of Grit",
            },
            ids = {
            },
            item = "Grotesque Skull of Grit",
          },
          WeaponAug2 = {
            aliases = {
              "Desolate Bloodstone",
            },
            ids = {
            },
            item = "Desolate Bloodstone",
          },
          WeaponAug3 = {
            aliases = {
              "Desolate Carnelian",
            },
            ids = {
            },
            item = "Desolate Carnelian",
          },
          WeaponAug4 = {
            aliases = {
              "Desolate Cat's Eye Agate",
            },
            ids = {
            },
            item = "Desolate Cat's Eye Agate",
          },
          WeaponAug5 = {
            aliases = {
              "Desolate Fire Emerald",
            },
            ids = {
            },
            item = "Desolate Fire Emerald",
          },
          WeaponAug6 = {
            aliases = {
              "Desolate Hematite",
            },
            ids = {
            },
            item = "Desolate Hematite",
          },
          WeaponAug7 = {
            aliases = {
              "Desolate Onyx",
            },
            ids = {
            },
            item = "Desolate Onyx",
          },
          WeaponAug8 = {
            aliases = {
              "Desolate Lapis Lazuli",
            },
            ids = {
            },
            item = "Desolate Lapis Lazuli",
          },
          WeaponAug9 = {
            aliases = {
              "Desolate Malachite",
            },
            ids = {
            },
            item = "Desolate Malachite",
          },
          Wrist = {
            aliases = {
              "Forsaken Deepwater Bracer",
            },
            ids = {
              33207,
            },
            item = "Forsaken Deepwater Bracer",
          },
        },
        Ranger = {
          Arms = {
            aliases = {
              "Forsaken Tolan's Darkwood Vambraces",
            },
            ids = {
              36015,
            },
            item = "Forsaken Tolan's Darkwood Vambraces",
          },
          Chest = {
            aliases = {
              "Forsaken Tolan's Darkwood Breastplate",
            },
            ids = {
              36031,
            },
            item = "Forsaken Tolan's Darkwood Breastplate",
          },
          ClickyWep3 = {
            aliases = {
              "Forsaken Fayguard Bladecatcher",
            },
            ids = {
            },
            item = "Forsaken Fayguard Bladecatcher",
          },
          ClickyWep4 = {
            aliases = {
              "Forsaken Sword of Skyfire",
            },
            ids = {
            },
            item = "Forsaken Sword of Skyfire",
          },
          ClickyWep6 = {
            aliases = {
              "Forsaken Breath of Harmony",
            },
            ids = {
            },
            item = "Forsaken Breath of Harmony",
          },
          ClickyWep7 = {
            aliases = {
              "Forsaken Poison Wind Censer",
            },
            ids = {
            },
            item = "Forsaken Poison Wind Censer",
          },
          ["Epic2.5"] = {
            aliases = {
              "Aurora, the Ancient Bow",
            },
            ids = {
            },
            item = "Aurora, the Ancient Bow",
          },
          Feet = {
            aliases = {
              "Forsaken Tolan's Darkwood Boots",
            },
            ids = {
              39609,
            },
            item = "Forsaken Tolan's Darkwood Boots",
          },
          Hands = {
            aliases = {
              "Forsaken Tolan's Darkwood Gauntlets",
            },
            ids = {
              39626,
            },
            item = "Forsaken Tolan's Darkwood Gauntlets",
          },
          Head = {
            aliases = {
              "Forsaken Tolan's Darkwood Helm",
            },
            ids = {
              39594,
            },
            item = "Forsaken Tolan's Darkwood Helm",
          },
          Legs = {
            aliases = {
              "Forsaken Tolan's Darkwood Greaves",
            },
            ids = {
              40386,
            },
            item = "Forsaken Tolan's Darkwood Greaves",
          },
          WeaponAug1 = {
            aliases = {
              "Desolate Black Sapphire",
            },
            ids = {
            },
            item = "Desolate Black Sapphire",
          },
          WeaponAug10 = {
            aliases = {
              "Desolate Star Rose Quartz",
            },
            ids = {
            },
            item = "Desolate Star Rose Quartz",
          },
          WeaponAug11 = {
            aliases = {
              "Desolate Star Ruby",
            },
            ids = {
            },
            item = "Desolate Star Ruby",
          },
          WeaponAug12 = {
            aliases = {
              "Grotesque Skull of Grit",
            },
            ids = {
            },
            item = "Grotesque Skull of Grit",
          },
          WeaponAug2 = {
            aliases = {
              "Desolate Bloodstone",
            },
            ids = {
            },
            item = "Desolate Bloodstone",
          },
          WeaponAug3 = {
            aliases = {
              "Desolate Carnelian",
            },
            ids = {
            },
            item = "Desolate Carnelian",
          },
          WeaponAug4 = {
            aliases = {
              "Desolate Cat's Eye Agate",
            },
            ids = {
            },
            item = "Desolate Cat's Eye Agate",
          },
          WeaponAug5 = {
            aliases = {
              "Desolate Fire Emerald",
            },
            ids = {
            },
            item = "Desolate Fire Emerald",
          },
          WeaponAug6 = {
            aliases = {
              "Desolate Hematite",
            },
            ids = {
            },
            item = "Desolate Hematite",
          },
          WeaponAug7 = {
            aliases = {
              "Desolate Onyx",
            },
            ids = {
            },
            item = "Desolate Onyx",
          },
          WeaponAug8 = {
            aliases = {
              "Desolate Lapis Lazuli",
            },
            ids = {
            },
            item = "Desolate Lapis Lazuli",
          },
          WeaponAug9 = {
            aliases = {
              "Desolate Malachite",
            },
            ids = {
            },
            item = "Desolate Malachite",
          },
          Wrist = {
            aliases = {
              "Forsaken Tolan's Darkwood Bracer",
            },
            ids = {
              33208,
            },
            item = "Forsaken Tolan's Darkwood Bracer",
          },
        },
        Rogue = {
          Arms = {
            aliases = {
              "Forsaken Mrylokar's Vambraces",
            },
            ids = {
              33213,
            },
            item = "Forsaken Mrylokar's Vambraces",
          },
          Chest = {
            aliases = {
              "Forsaken Mrylokar's Breastplate",
            },
            ids = {
              36020,
            },
            item = "Forsaken Mrylokar's Breastplate",
          },
          ClickyWep3 = {
            aliases = {
              "Forsaken Fayguard Bladecatcher",
            },
            ids = {
            },
            item = "Forsaken Fayguard Bladecatcher",
          },
          ClickyWep5 = {
            aliases = {
              "Forsaken Shieldstorm",
            },
            ids = {
            },
            item = "Forsaken Shieldstorm",
          },
          ClickyWep7 = {
            aliases = {
              "Forsaken Poison Wind Censer",
            },
            ids = {
            },
            item = "Forsaken Poison Wind Censer",
          },
          ClickyWep8 = {
            aliases = {
              "Forsaken Zealot's Incarnadine Sword",
            },
            ids = {
            },
            item = "Forsaken Zealot's Incarnadine Sword",
          },
          ["Epic2.5"] = {
            aliases = {
              "Nightshade, Blade of Ancient Entropy",
            },
            ids = {
            },
            item = "Nightshade, Blade of Ancient Entropy",
          },
          Feet = {
            aliases = {
              "Forsaken Mrylokar's Boots",
            },
            ids = {
              39601,
            },
            item = "Forsaken Mrylokar's Boots",
          },
          Hands = {
            aliases = {
              "Forsaken Mrylokar's Gauntlets",
            },
            ids = {
              39615,
            },
            item = "Forsaken Mrylokar's Gauntlets",
          },
          Head = {
            aliases = {
              "Forsaken Mrylokar's Helm",
            },
            ids = {
              39086,
            },
            item = "Forsaken Mrylokar's Helm",
          },
          Legs = {
            aliases = {
              "Forsaken Mrylokar's Greaves",
            },
            ids = {
              40375,
            },
            item = "Forsaken Mrylokar's Greaves",
          },
          WeaponAug1 = {
            aliases = {
              "Desolate Black Sapphire",
            },
            ids = {
            },
            item = "Desolate Black Sapphire",
          },
          WeaponAug12 = {
            aliases = {
              "Grotesque Skull of Grit",
            },
            ids = {
            },
            item = "Grotesque Skull of Grit",
          },
          WeaponAug2 = {
            aliases = {
              "Desolate Bloodstone",
            },
            ids = {
            },
            item = "Desolate Bloodstone",
          },
          WeaponAug3 = {
            aliases = {
              "Desolate Carnelian",
            },
            ids = {
            },
            item = "Desolate Carnelian",
          },
          WeaponAug4 = {
            aliases = {
              "Desolate Cat's Eye Agate",
            },
            ids = {
            },
            item = "Desolate Cat's Eye Agate",
          },
          WeaponAug5 = {
            aliases = {
              "Desolate Fire Emerald",
            },
            ids = {
            },
            item = "Desolate Fire Emerald",
          },
          WeaponAug6 = {
            aliases = {
              "Desolate Hematite",
            },
            ids = {
            },
            item = "Desolate Hematite",
          },
          WeaponAug7 = {
            aliases = {
              "Desolate Onyx",
            },
            ids = {
            },
            item = "Desolate Onyx",
          },
          Wrist = {
            aliases = {
              "Forsaken Mrylokar's Bracer",
            },
            ids = {
              33197,
            },
            item = "Forsaken Mrylokar's Bracer",
          },
        },
        ["Shadow Knight"] = {
          Arms = {
            aliases = {
              "Forsaken Blood Ember Vambraces",
            },
            ids = {
              36013,
            },
            item = "Forsaken Blood Ember Vambraces",
          },
          Chest = {
            aliases = {
              "Forsaken Blood Ember Breastplate",
            },
            ids = {
              36029,
            },
            item = "Forsaken Blood Ember Breastplate",
          },
          ClickyWep3 = {
            aliases = {
              "Forsaken Fayguard Bladecatcher",
            },
            ids = {
            },
            item = "Forsaken Fayguard Bladecatcher",
          },
          ClickyWep6 = {
            aliases = {
              "Forsaken Breath of Harmony",
            },
            ids = {
            },
            item = "Forsaken Breath of Harmony",
          },
          ClickyWep7 = {
            aliases = {
              "Forsaken Poison Wind Censer",
            },
            ids = {
            },
            item = "Forsaken Poison Wind Censer",
          },
          ClickyWep8 = {
            aliases = {
              "Forsaken Zealot's Incarnadine Sword",
            },
            ids = {
            },
            item = "Forsaken Zealot's Incarnadine Sword",
          },
          ["Epic2.5"] = {
            aliases = {
              "Innoruuk's Ancient Blessing",
            },
            ids = {
            },
            item = "Innoruuk's Ancient Blessing",
          },
          Feet = {
            aliases = {
              "Forsaken Blood Ember Boots",
            },
            ids = {
              39598,
            },
            item = "Forsaken Blood Ember Boots",
          },
          Hands = {
            aliases = {
              "Forsaken Blood Ember Gauntlets",
            },
            ids = {
              39624,
            },
            item = "Forsaken Blood Ember Gauntlets",
          },
          Head = {
            aliases = {
              "Forsaken Blood Ember Helm",
            },
            ids = {
              39592,
            },
            item = "Forsaken Blood Ember Helm",
          },
          Legs = {
            aliases = {
              "Forsaken Blood Ember Greaves",
            },
            ids = {
              40384,
            },
            item = "Forsaken Blood Ember Greaves",
          },
          WeaponAug1 = {
            aliases = {
              "Desolate Black Sapphire",
            },
            ids = {
            },
            item = "Desolate Black Sapphire",
          },
          WeaponAug10 = {
            aliases = {
              "Desolate Star Rose Quartz",
            },
            ids = {
            },
            item = "Desolate Star Rose Quartz",
          },
          WeaponAug11 = {
            aliases = {
              "Desolate Star Ruby",
            },
            ids = {
            },
            item = "Desolate Star Ruby",
          },
          WeaponAug12 = {
            aliases = {
              "Grotesque Skull of Grit",
            },
            ids = {
            },
            item = "Grotesque Skull of Grit",
          },
          WeaponAug2 = {
            aliases = {
              "Desolate Bloodstone",
            },
            ids = {
            },
            item = "Desolate Bloodstone",
          },
          WeaponAug3 = {
            aliases = {
              "Desolate Carnelian",
            },
            ids = {
            },
            item = "Desolate Carnelian",
          },
          WeaponAug4 = {
            aliases = {
              "Desolate Cat's Eye Agate",
            },
            ids = {
            },
            item = "Desolate Cat's Eye Agate",
          },
          WeaponAug5 = {
            aliases = {
              "Desolate Fire Emerald",
            },
            ids = {
            },
            item = "Desolate Fire Emerald",
          },
          WeaponAug6 = {
            aliases = {
              "Desolate Hematite",
            },
            ids = {
            },
            item = "Desolate Hematite",
          },
          WeaponAug7 = {
            aliases = {
              "Desolate Onyx",
            },
            ids = {
            },
            item = "Desolate Onyx",
          },
          WeaponAug8 = {
            aliases = {
              "Desolate Lapis Lazuli",
            },
            ids = {
            },
            item = "Desolate Lapis Lazuli",
          },
          WeaponAug9 = {
            aliases = {
              "Desolate Malachite",
            },
            ids = {
            },
            item = "Desolate Malachite",
          },
          Wrist = {
            aliases = {
              "Forsaken Blood Ember Bracer",
            },
            ids = {
              33206,
            },
            item = "Forsaken Blood Ember Bracer",
          },
        },
        Shaman = {
          Arms = {
            aliases = {
              "Forsaken Jaundiced Bone Vambraces",
            },
            ids = {
              33216,
            },
            item = "Forsaken Jaundiced Bone Vambraces",
          },
          Chest = {
            aliases = {
              "Forsaken Jaundiced Bone Breastplate",
            },
            ids = {
              36023,
            },
            item = "Forsaken Jaundiced Bone Breastplate",
          },
          ClickyWep1 = {
            aliases = {
              "Forsaken Rod of Lamentation",
            },
            ids = {
            },
            item = "Forsaken Rod of Lamentation",
          },
          ClickyWep5 = {
            aliases = {
              "Forsaken Shieldstorm",
            },
            ids = {
            },
            item = "Forsaken Shieldstorm",
          },
          ClickyWep7 = {
            aliases = {
              "Forsaken Poison Wind Censer",
            },
            ids = {
            },
            item = "Forsaken Poison Wind Censer",
          },
          ClickyWep8 = {
            aliases = {
              "Forsaken Zealot's Incarnadine Sword",
            },
            ids = {
            },
            item = "Forsaken Zealot's Incarnadine Sword",
          },
          ["Epic2.5"] = {
            aliases = {
              "Ancient Spiritstaff of the Heyokah",
            },
            ids = {
            },
            item = "Ancient Spiritstaff of the Heyokah",
          },
          Feet = {
            aliases = {
              "Forsaken Jaundiced Bone Boots",
            },
            ids = {
              39610,
            },
            item = "Forsaken Jaundiced Bone Boots",
          },
          Hands = {
            aliases = {
              "Forsaken Jaundiced Bone Gauntlets",
            },
            ids = {
              39622,
            },
            item = "Forsaken Jaundiced Bone Gauntlets",
          },
          Head = {
            aliases = {
              "Forsaken Jaundiced Bone Helm",
            },
            ids = {
              39089,
            },
            item = "Forsaken Jaundiced Bone Helm",
          },
          Legs = {
            aliases = {
              "Forsaken Jaundiced Bone Greaves",
            },
            ids = {
              40378,
            },
            item = "Forsaken Jaundiced Bone Greaves",
          },
          WeaponAug10 = {
            aliases = {
              "Desolate Star Rose Quartz",
            },
            ids = {
            },
            item = "Desolate Star Rose Quartz",
          },
          WeaponAug11 = {
            aliases = {
              "Desolate Star Ruby",
            },
            ids = {
            },
            item = "Desolate Star Ruby",
          },
          WeaponAug12 = {
            aliases = {
              "Grotesque Skull of Grit",
            },
            ids = {
            },
            item = "Grotesque Skull of Grit",
          },
          WeaponAug6 = {
            aliases = {
              "Desolate Hematite",
            },
            ids = {
            },
            item = "Desolate Hematite",
          },
          WeaponAug8 = {
            aliases = {
              "Desolate Lapis Lazuli",
            },
            ids = {
            },
            item = "Desolate Lapis Lazuli",
          },
          WeaponAug9 = {
            aliases = {
              "Desolate Malachite",
            },
            ids = {
            },
            item = "Desolate Malachite",
          },
          Wrist = {
            aliases = {
              "Forsaken Jaundiced Bone Bracer",
            },
            ids = {
              33200,
            },
            item = "Forsaken Jaundiced Bone Bracer",
          },
        },
        Warrior = {
          Arms = {
            aliases = {
              "Forsaken Cobalt Vambraces",
            },
            ids = {
              33211,
            },
            item = "Forsaken Cobalt Vambraces",
          },
          Chest = {
            aliases = {
              "Forsaken Cobalt Breastplate",
            },
            ids = {
              36018,
            },
            item = "Forsaken Cobalt Breastplate",
          },
          ClickyWep2 = {
            aliases = {
              "Forsaken Sword of the Morning",
            },
            ids = {
            },
            item = "Forsaken Sword of the Morning",
          },
          ClickyWep3 = {
            aliases = {
              "Forsaken Fayguard Bladecatcher",
            },
            ids = {
            },
            item = "Forsaken Fayguard Bladecatcher",
          },
          ClickyWep4 = {
            aliases = {
              "Forsaken Sword of Skyfire",
            },
            ids = {
            },
            item = "Forsaken Sword of Skyfire",
          },
          ClickyWep5 = {
            aliases = {
              "Forsaken Shieldstorm",
            },
            ids = {
            },
            item = "Forsaken Shieldstorm",
          },
          ["Epic2.5"] = {
            aliases = {
              "Kreljnok's Sword of Ancient Power",
            },
            ids = {
            },
            item = "Kreljnok's Sword of Ancient Power",
          },
          Feet = {
            aliases = {
              "Forsaken Cobalt Boots",
            },
            ids = {
              39597,
            },
            item = "Forsaken Cobalt Boots",
          },
          Hands = {
            aliases = {
              "Forsaken Cobalt Gauntlets",
            },
            ids = {
              39613,
            },
            item = "Forsaken Cobalt Gauntlets",
          },
          Head = {
            aliases = {
              "Forsaken Cobalt Helm",
            },
            ids = {
              39084,
            },
            item = "Forsaken Cobalt Helm",
          },
          Legs = {
            aliases = {
              "Forsaken Cobalt Greaves",
            },
            ids = {
              39675,
            },
            item = "Forsaken Cobalt Greaves",
          },
          WeaponAug1 = {
            aliases = {
              "Desolate Black Sapphire",
            },
            ids = {
            },
            item = "Desolate Black Sapphire",
          },
          WeaponAug12 = {
            aliases = {
              "Grotesque Skull of Grit",
            },
            ids = {
            },
            item = "Grotesque Skull of Grit",
          },
          WeaponAug2 = {
            aliases = {
              "Desolate Bloodstone",
            },
            ids = {
            },
            item = "Desolate Bloodstone",
          },
          WeaponAug3 = {
            aliases = {
              "Desolate Carnelian",
            },
            ids = {
            },
            item = "Desolate Carnelian",
          },
          WeaponAug4 = {
            aliases = {
              "Desolate Cat's Eye Agate",
            },
            ids = {
            },
            item = "Desolate Cat's Eye Agate",
          },
          WeaponAug5 = {
            aliases = {
              "Desolate Fire Emerald",
            },
            ids = {
            },
            item = "Desolate Fire Emerald",
          },
          WeaponAug6 = {
            aliases = {
              "Desolate Hematite",
            },
            ids = {
            },
            item = "Desolate Hematite",
          },
          WeaponAug7 = {
            aliases = {
              "Desolate Onyx",
            },
            ids = {
            },
            item = "Desolate Onyx",
          },
          Wrist = {
            aliases = {
              "Forsaken Cobalt Bracer",
            },
            ids = {
              33195,
            },
            item = "Forsaken Cobalt Bracer",
          },
        },
        Wizard = {
          Arms = {
            aliases = {
              "Forsaken Sorcerer's Sleeves",
            },
            ids = {
              33218,
            },
            item = "Forsaken Sorcerer's Sleeves",
          },
          Chest = {
            aliases = {
              "Forsaken Sorcerer's Blouse",
            },
            ids = {
              36025,
            },
            item = "Forsaken Sorcerer's Blouse",
          },
          ClickyWep1 = {
            aliases = {
              "Forsaken Rod of Lamentation",
            },
            ids = {
            },
            item = "Forsaken Rod of Lamentation",
          },
          ClickyWep2 = {
            aliases = {
              "Forsaken Sword of the Morning",
            },
            ids = {
            },
            item = "Forsaken Sword of the Morning",
          },
          ClickyWep4 = {
            aliases = {
              "Forsaken Sword of Skyfire",
            },
            ids = {
            },
            item = "Forsaken Sword of Skyfire",
          },
          ClickyWep6 = {
            aliases = {
              "Forsaken Breath of Harmony",
            },
            ids = {
            },
            item = "Forsaken Breath of Harmony",
          },
          ["Epic2.5"] = {
            aliases = {
              "Staff of Ancient Power",
            },
            ids = {
            },
            item = "Staff of Ancient Power",
          },
          Feet = {
            aliases = {
              "Forsaken Sorcerer's Shoes",
            },
            ids = {
              39604,
            },
            item = "Forsaken Sorcerer's Shoes",
          },
          Hands = {
            aliases = {
              "Forsaken Sorcerer's Gloves",
            },
            ids = {
              39617,
            },
            item = "Forsaken Sorcerer's Gloves",
          },
          Head = {
            aliases = {
              "Forsaken Sorcerer's Cap",
            },
            ids = {
              39588,
            },
            item = "Forsaken Sorcerer's Cap",
          },
          Legs = {
            aliases = {
              "Forsaken Sorcerer's Trousers",
            },
            ids = {
              40380,
            },
            item = "Forsaken Sorcerer's Trousers",
          },
          WeaponAug10 = {
            aliases = {
              "Desolate Star Rose Quartz",
            },
            ids = {
            },
            item = "Desolate Star Rose Quartz",
          },
          WeaponAug11 = {
            aliases = {
              "Desolate Star Ruby",
            },
            ids = {
            },
            item = "Desolate Star Ruby",
          },
          WeaponAug13 = {
            aliases = {
              "Vitreous Skull of Vitality",
            },
            ids = {
            },
            item = "Vitreous Skull of Vitality",
          },
          WeaponAug8 = {
            aliases = {
              "Desolate Lapis Lazuli",
            },
            ids = {
            },
            item = "Desolate Lapis Lazuli",
          },
          WeaponAug9 = {
            aliases = {
              "Desolate Malachite",
            },
            ids = {
            },
            item = "Desolate Malachite",
          },
          Wrist = {
            aliases = {
              "Forsaken Sorcerer's Bracelet",
            },
            ids = {
              33202,
            },
            item = "Forsaken Sorcerer's Bracelet",
          },
        },
      },
      group = "Raid Best In Slot",
      id = "sebilis",
      name = "Sebilis",
      show_base = {
        PSAug1 = 1,
        PSAug2 = 1,
        PSAug3 = 1,
        PSAugContainer = 1,
        PSAugSprings = 1,
      },
      template = {
        ["FlowerAug1 (Parry/Block)"] = {
          aliases = {
            "Noxious Bloom of Brittle Bones",
          },
          ids = {
          },
          item = "Noxious Bloom of Brittle Bones",
        },
        ["FlowerAug2 (Increase Duration)"] = {
          aliases = {
            "Noxious Bloom of Corporeal Calamity",
          },
          ids = {
          },
          item = "Noxious Bloom of Corporeal Calamity",
        },
        ["FlowerAug3 (Double Attack)"] = {
          aliases = {
            "Noxious Bloom of Ebbing Exertion",
          },
          ids = {
          },
          item = "Noxious Bloom of Ebbing Exertion",
        },
        ["FlowerAug4 (Crit)"] = {
          aliases = {
            "Noxious Bloom of Feeble Finesse",
          },
          ids = {
          },
          item = "Noxious Bloom of Feeble Finesse",
        },
        ["FlowerAug5 (Dodge)"] = {
          aliases = {
            "Noxious Bloom of Languid Limbs",
          },
          ids = {
          },
          item = "Noxious Bloom of Languid Limbs",
        },
        ["FlowerAug6 (Healing)"] = {
          aliases = {
            "Noxious Bloom of Meager Mettle",
          },
          ids = {
          },
          item = "Noxious Bloom of Meager Mettle",
        },
        ["FlowerAug7 (Reduce Mana Cost)"] = {
          aliases = {
            "Noxious Bloom of Wavering Willpower",
          },
          ids = {
          },
          item = "Noxious Bloom of Wavering Willpower",
        },
        ["FluxAug1 (Spell Shield)"] = {
          aliases = {
            "Infused Flux of Acumen",
          },
          ids = {
          },
          item = "Infused Flux of Acumen",
        },
        ["FluxAug2 (Regen)"] = {
          aliases = {
            "Infused Flux of Decay",
          },
          ids = {
          },
          item = "Infused Flux of Decay",
        },
        ["FluxAug3 (20 Attack/Acc)"] = {
          aliases = {
            "Infused Flux of Glamour",
          },
          ids = {
          },
          item = "Infused Flux of Glamour",
        },
        ["FluxAug4 (50 Attack/Acc)"] = {
          aliases = {
            "Infused Flux of Potency",
          },
          ids = {
          },
          item = "Infused Flux of Potency",
        },
        ["FluxAug5 (20 Attack/Acc)"] = {
          aliases = {
            "Infused Flux of Proficiency",
          },
          ids = {
          },
          item = "Infused Flux of Proficiency",
        },
        ["FluxAug6 (Regen)"] = {
          aliases = {
            "Infused Flux of Radiance",
          },
          ids = {
          },
          item = "Infused Flux of Radiance",
        },
        ["FluxAug7 (Dot/Stun)"] = {
          aliases = {
            "Infused Flux of Sagacity",
          },
          ids = {
          },
          item = "Infused Flux of Sagacity",
        },
        ["FluxAug8 (3 Shield/5 Avoidance)"] = {
          aliases = {
            "Infused Flux of Vigor",
          },
          ids = {
          },
          item = "Infused Flux of Vigor",
        },
        ["FluxAug9 (Avoidance)"] = {
          aliases = {
            "Infused Flux of Vivacity",
          },
          ids = {
          },
          item = "Infused Flux of Vivacity",
        },
        Fungi = {
          aliases = {
            "Forsaken Fungus Covered Scale Tunic",
          },
          ids = {
          },
          item = "Forsaken Fungus Covered Scale Tunic",
        },
        PSAug1 = {
          aliases = {
            "Bloodstained Gear Set #1",
          },
          ids = {
            39071,
            40469,
          },
          item = "Bloodstained Gear Set #1",
        },
        PSAug2 = {
          aliases = {
            "Bloodstained Gear Set #2",
          },
          ids = {
            39071,
            40470,
          },
          item = "Bloodstained Gear Set #2",
        },
        PSAug3 = {
          aliases = {
            "Bloodstained Gear Set #3",
          },
          ids = {
            39071,
            40471,
          },
          item = "Bloodstained Gear Set #3",
        },
        PSAugContainer = {
          aliases = {
            "Bloodstained Gear Assembly",
          },
          ids = {
            39071,
            40472,
          },
          item = "Bloodstained Gear Assembly",
        },
        PSAugFinal = {
          aliases = {
            "Originator's Overlooked Oddity",
          },
          ids = {
          },
          item = "Originator's Overlooked Oddity",
        },
        PSAugSprings = {
          aliases = {
            "Bloodstained Spring",
          },
          ids = {
            39071,
            40468,
          },
          item = "Bloodstained Spring",
        },
        ["SlimeAug1 (Poison)"] = {
          aliases = {
            "Corrosive Slime of Suffering",
          },
          ids = {
          },
          item = "Corrosive Slime of Suffering",
        },
        ["SlimeAug2 (Cold)"] = {
          aliases = {
            "Frigid Slime of Suffering",
          },
          ids = {
          },
          item = "Frigid Slime of Suffering",
        },
        ["SlimeAug3 (Disease)"] = {
          aliases = {
            "Necrotic Slime of Suffering",
          },
          ids = {
          },
          item = "Necrotic Slime of Suffering",
        },
        ["SlimeAug4 (Magic)"] = {
          aliases = {
            "Ruinous Slime of Suffering",
          },
          ids = {
          },
          item = "Ruinous Slime of Suffering",
        },
        ["SlimeAug5 (Fire)"] = {
          aliases = {
            "Searing Slime of Suffering",
          },
          ids = {
          },
          item = "Searing Slime of Suffering",
        },
      },
      visible = {
        Arms = {
          aliases = {
            "Ruined Shadowy Armguards",
          },
          ids = {
          },
          item = "Ruined Shadowy Armguards",
        },
        Chest = {
          aliases = {
            "Ruined Shadowy Chestguard",
          },
          ids = {
          },
          item = "Ruined Shadowy Chestguard",
        },
        ["Epic2.5"] = {
          aliases = {
            "Shadowy Scale of the Fallen",
          },
          ids = {
          },
          item = "Shadowy Scale of the Fallen",
        },
        Feet = {
          aliases = {
            "Ruined Shadowy Boots",
          },
          ids = {
          },
          item = "Ruined Shadowy Boots",
        },
        Hands = {
          aliases = {
            "Ruined Shadowy Gauntlets",
          },
          ids = {
          },
          item = "Ruined Shadowy Gauntlets",
        },
        Head = {
          aliases = {
            "Ruined Shadowy Helm",
          },
          ids = {
          },
          item = "Ruined Shadowy Helm",
        },
        Legs = {
          aliases = {
            "Ruined Shadowy Leggings",
          },
          ids = {
          },
          item = "Ruined Shadowy Leggings",
        },
        Wrist = {
          aliases = {
            "Ruined Shadowy Bracer",
          },
          ids = {
          },
          item = "Ruined Shadowy Bracer",
        },
      },
    },
    veksar = {
      categories = {
        {
          name = "FUKU Aug",
          slots = {
            "Glyphed Sarnak Skull",
            "Glyph Aug",
          },
        },
        {
          name = "Ancient Bauble",
          slots = {
            "Base (Trash)",
            "Gem1 (Minis)",
            "Gem2 (Gamus)",
            "Gem3 (Warlocks)",
            "Gem4 (Sythrax)",
            "Gem5 (Brother)",
            "Gem6 (Garudon)",
            "Final",
          },
        },
        {
          name = "Mini Clickies",
          slots = {
            "Sap",
            "MeleeFamiliar",
            "CasterFamiliar",
          },
        },
        {
          name = "Boss Clickies",
          slots = {
            "Ageless Enmity",
            "Ancestral Memories",
            "Armor of Experience",
            "Dimensional Shield",
            "Divine Companion's Aura",
            "Feral Swipe",
            "Forceful Rejuvenation",
            "Frenzied Devastation",
            "Howl of Tashan",
            "Intensity of the Resolute",
            "Prot of the Spirit Wolf",
            "Radiant Cure",
            "Rally",
            "Retreat",
            "Staunch Recovery",
            "Warlord's Bravery",
          },
        },
        {
          name = "Vaults",
          slots = {
            "Key1",
            "Vault1",
            "Key2",
            "Vault2",
            "Key3",
            "Vault3",
            "Key4",
            "Vault4",
          },
        },
      },
      classes = {
        Bard = {
          ["Ancestral Memories"] = {
            aliases = {
              "Zealous Soulscream Belt",
            },
            ids = {
            },
            item = "Zealous Soulscream Belt",
            source = "Gamus",
          },
          ["Dimensional Shield"] = {
            aliases = {
              "Elusive Ritual Talisman of Fate",
            },
            ids = {
            },
            item = "Elusive Ritual Talisman of Fate",
            source = "Gamus",
          },
          ["Glyph Aug"] = {
            aliases = {
              "Invocation Glyph: Vulka's Chant of Lightning",
            },
            ids = {
            },
            item = "Invocation Glyph: Vulka's Chant of Lightning",
          },
          ["Glyphed Sarnak Skull"] = {
            aliases = {
              "Glyphed Sarnak Skull",
            },
            ids = {
              40844,
            },
            item = "Glyphed Sarnak Skull",
          },
          ["Howl of Tashan"] = {
            aliases = {
              "Malignant Bloodgill Shaman's Effigy",
            },
            ids = {
            },
            item = "Malignant Bloodgill Shaman's Effigy",
            source = "Gamus",
          },
          Key1 = {
            aliases = {
              "Melodic Key of Musical Manipulation",
            },
            ids = {
              40821,
            },
            item = "Melodic Key of Musical Manipulation",
          },
          Key2 = {
            aliases = {
              "Resilient Key",
            },
            ids = {
              42461,
            },
            item = "Resilient Key",
          },
          MeleeFamiliar = {
            aliases = {
              "Forgotten Leather Leash",
            },
            ids = {
            },
            item = "Forgotten Leather Leash",
            source = "Behemoth",
          },
          ["Radiant Cure"] = {
            aliases = {
              "Cleansing Band of Twilight",
            },
            ids = {
            },
            item = "Cleansing Band of Twilight",
            source = "Warlocks",
          },
          Retreat = {
            aliases = {
              "Shadowy Silken Veil of Gazing",
            },
            ids = {
            },
            item = "Shadowy Silken Veil of Gazing",
            source = "Sythrax",
          },
          Sap = {
            aliases = {
              "Forgotten Mugger's Sap",
            },
            ids = {
            },
            item = "Forgotten Mugger's Sap",
            source = "Chef",
          },
          ["Staunch Recovery"] = {
            aliases = {
              "Vitalizing Earring of the Darkfaith",
            },
            ids = {
            },
            item = "Vitalizing Earring of the Darkfaith",
            source = "Brother",
          },
          Vault1 = {
            aliases = {
              "Froglok Gut String Lute",
            },
            ids = {
            },
            item = "Froglok Gut String Lute",
          },
          Vault2 = {
            aliases = {
              "Defiant Trithcink",
            },
            ids = {
            },
            item = "Defiant Trithcink",
          },
        },
        Beastlord = {
          ["Ancestral Memories"] = {
            aliases = {
              "Zealous Soulscream Belt",
            },
            ids = {
            },
            item = "Zealous Soulscream Belt",
            source = "Gamus",
          },
          ["Dimensional Shield"] = {
            aliases = {
              "Elusive Ritual Talisman of Fate",
            },
            ids = {
            },
            item = "Elusive Ritual Talisman of Fate",
            source = "Gamus",
          },
          ["Divine Companion's Aura"] = {
            aliases = {
              "Enduring Bloodgill Belt",
            },
            ids = {
            },
            item = "Enduring Bloodgill Belt",
            source = "Gamus",
          },
          ["Feral Swipe"] = {
            aliases = {
              "Cunning Razor-edged Claw",
            },
            ids = {
            },
            item = "Cunning Razor-edged Claw",
            source = "Brother",
          },
          ["Forceful Rejuvenation"] = {
            aliases = {
              "Cunning Necklace of Dark Rituals",
            },
            ids = {
            },
            item = "Cunning Necklace of Dark Rituals",
            source = "Warlocks",
          },
          ["Glyph Aug"] = {
            aliases = {
              "Destructive Focus Glyph: Reptilian Venom",
            },
            ids = {
            },
            item = "Destructive Focus Glyph: Reptilian Venom",
          },
          ["Glyphed Sarnak Skull"] = {
            aliases = {
              "Glyphed Sarnak Skull",
            },
            ids = {
              40859,
            },
            item = "Glyphed Sarnak Skull",
          },
          ["Intensity of the Resolute"] = {
            aliases = {
              "Audacious Kunzar Tu'Lal",
            },
            ids = {
            },
            item = "Audacious Kunzar Tu'Lal",
            source = "Brother",
          },
          Key2 = {
            aliases = {
              "Resilient Key",
            },
            ids = {
              42461,
            },
            item = "Resilient Key",
          },
          MeleeFamiliar = {
            aliases = {
              "Forgotten Leather Leash",
            },
            ids = {
            },
            item = "Forgotten Leather Leash",
            source = "Behemoth",
          },
          Retreat = {
            aliases = {
              "Shadowy Silken Veil of Gazing",
            },
            ids = {
            },
            item = "Shadowy Silken Veil of Gazing",
            source = "Sythrax",
          },
          Vault2 = {
            aliases = {
              "Defiant Trithcink",
            },
            ids = {
            },
            item = "Defiant Trithcink",
          },
        },
        Berserker = {
          ["Ancestral Memories"] = {
            aliases = {
              "Zealous Soulscream Belt",
            },
            ids = {
            },
            item = "Zealous Soulscream Belt",
            source = "Gamus",
          },
          ["Dimensional Shield"] = {
            aliases = {
              "Elusive Ritual Talisman of Fate",
            },
            ids = {
            },
            item = "Elusive Ritual Talisman of Fate",
            source = "Gamus",
          },
          ["Feral Swipe"] = {
            aliases = {
              "Cunning Razor-edged Claw",
            },
            ids = {
            },
            item = "Cunning Razor-edged Claw",
            source = "Brother",
          },
          ["Glyph Aug"] = {
            aliases = {
              "Rapid Focus Glyph: Destroyer's Volley",
            },
            ids = {
            },
            item = "Rapid Focus Glyph: Destroyer's Volley",
          },
          ["Glyphed Sarnak Skull"] = {
            aliases = {
              "Glyphed Sarnak Skull",
            },
            ids = {
              40850,
            },
            item = "Glyphed Sarnak Skull",
          },
          ["Intensity of the Resolute"] = {
            aliases = {
              "Audacious Kunzar Tu'Lal",
            },
            ids = {
            },
            item = "Audacious Kunzar Tu'Lal",
            source = "Brother",
          },
          Key2 = {
            aliases = {
              "Resilient Key",
            },
            ids = {
              42461,
            },
            item = "Resilient Key",
          },
          MeleeFamiliar = {
            aliases = {
              "Forgotten Leather Leash",
            },
            ids = {
            },
            item = "Forgotten Leather Leash",
            source = "Behemoth",
          },
          ["Prot of the Spirit Wolf"] = {
            aliases = {
              "Fervent Eyepatch of Warding",
            },
            ids = {
            },
            item = "Fervent Eyepatch of Warding",
            source = "Warlocks",
          },
          Retreat = {
            aliases = {
              "Shadowy Silken Veil of Gazing",
            },
            ids = {
            },
            item = "Shadowy Silken Veil of Gazing",
            source = "Sythrax",
          },
          Vault2 = {
            aliases = {
              "Defiant Trithcink",
            },
            ids = {
            },
            item = "Defiant Trithcink",
          },
          ["Warlord's Bravery"] = {
            aliases = {
              "Obstinate Kunzar Deathguard Shield",
            },
            ids = {
            },
            item = "Obstinate Kunzar Deathguard Shield",
            source = "Brother",
          },
        },
        Cleric = {
          CasterFamiliar = {
            aliases = {
              "Forgotten Warlock's Ring",
            },
            ids = {
            },
            item = "Forgotten Warlock's Ring",
            source = "Highborn",
          },
          ["Forceful Rejuvenation"] = {
            aliases = {
              "Cunning Necklace of Dark Rituals",
            },
            ids = {
            },
            item = "Cunning Necklace of Dark Rituals",
            source = "Warlocks",
          },
          ["Frenzied Devastation"] = {
            aliases = {
              "Malefic Ceremonial Sh'Voth",
            },
            ids = {
            },
            item = "Malefic Ceremonial Sh'Voth",
            source = "Sythrax",
          },
          ["Glyph Aug"] = {
            aliases = {
              "Enduring Focus Glyph: Pious Elixir of Divinity",
            },
            ids = {
            },
            item = "Enduring Focus Glyph: Pious Elixir of Divinity",
          },
          ["Glyphed Sarnak Skull"] = {
            aliases = {
              "Glyphed Sarnak Skull",
            },
            ids = {
              40851,
            },
            item = "Glyphed Sarnak Skull",
          },
          Key1 = {
            aliases = {
              "Gilded Key",
            },
            ids = {
              40820,
            },
            item = "Gilded Key",
          },
          Key2 = {
            aliases = {
              "Resilient Key",
            },
            ids = {
              42461,
            },
            item = "Resilient Key",
          },
          Key3 = {
            aliases = {
              "Sanctified Key",
            },
            ids = {
              40813,
            },
            item = "Sanctified Key",
          },
          Key4 = {
            aliases = {
              "Stout Key",
            },
            ids = {
              40816,
            },
            item = "Stout Key",
          },
          ["Radiant Cure"] = {
            aliases = {
              "Cleansing Band of Twilight",
            },
            ids = {
            },
            item = "Cleansing Band of Twilight",
            source = "Warlocks",
          },
          Retreat = {
            aliases = {
              "Shadowy Silken Veil of Gazing",
            },
            ids = {
            },
            item = "Shadowy Silken Veil of Gazing",
            source = "Sythrax",
          },
          ["Staunch Recovery"] = {
            aliases = {
              "Vitalizing Earring of the Darkfaith",
            },
            ids = {
            },
            item = "Vitalizing Earring of the Darkfaith",
            source = "Brother",
          },
          Vault1 = {
            aliases = {
              "Fanatical Hammer of the Forgotten City",
            },
            ids = {
            },
            item = "Fanatical Hammer of the Forgotten City",
          },
          Vault2 = {
            aliases = {
              "Defiant Trithcink",
            },
            ids = {
            },
            item = "Defiant Trithcink",
          },
          Vault3 = {
            aliases = {
              "Exalted Glowing Bath Token",
            },
            ids = {
            },
            item = "Exalted Glowing Bath Token",
          },
          Vault4 = {
            aliases = {
              "Bloodthirsty Draconic Idol",
            },
            ids = {
            },
            item = "Bloodthirsty Draconic Idol",
          },
        },
        Druid = {
          CasterFamiliar = {
            aliases = {
              "Forgotten Warlock's Ring",
            },
            ids = {
            },
            item = "Forgotten Warlock's Ring",
            source = "Highborn",
          },
          ["Divine Companion's Aura"] = {
            aliases = {
              "Enduring Bloodgill Belt",
            },
            ids = {
            },
            item = "Enduring Bloodgill Belt",
            source = "Gamus",
          },
          ["Forceful Rejuvenation"] = {
            aliases = {
              "Cunning Necklace of Dark Rituals",
            },
            ids = {
            },
            item = "Cunning Necklace of Dark Rituals",
            source = "Warlocks",
          },
          ["Frenzied Devastation"] = {
            aliases = {
              "Malefic Ceremonial Sh'Voth",
            },
            ids = {
            },
            item = "Malefic Ceremonial Sh'Voth",
            source = "Sythrax",
          },
          ["Glyph Aug"] = {
            aliases = {
              "Destructive Focus Glyph: Wasp Swarm",
            },
            ids = {
            },
            item = "Destructive Focus Glyph: Wasp Swarm",
          },
          ["Glyphed Sarnak Skull"] = {
            aliases = {
              "Glyphed Sarnak Skull",
            },
            ids = {
              40853,
            },
            item = "Glyphed Sarnak Skull",
          },
          Key1 = {
            aliases = {
              "Key of Ill Omen",
            },
            ids = {
            },
            item = "Key of Ill Omen",
          },
          Key2 = {
            aliases = {
              "Resilient Key",
            },
            ids = {
              42461,
            },
            item = "Resilient Key",
          },
          Key3 = {
            aliases = {
              "Sanctified Key",
            },
            ids = {
              40813,
            },
            item = "Sanctified Key",
          },
          ["Prot of the Spirit Wolf"] = {
            aliases = {
              "Fervent Eyepatch of Warding",
            },
            ids = {
            },
            item = "Fervent Eyepatch of Warding",
            source = "Warlocks",
          },
          ["Radiant Cure"] = {
            aliases = {
              "Cleansing Band of Twilight",
            },
            ids = {
            },
            item = "Cleansing Band of Twilight",
            source = "Warlocks",
          },
          Retreat = {
            aliases = {
              "Shadowy Silken Veil of Gazing",
            },
            ids = {
            },
            item = "Shadowy Silken Veil of Gazing",
            source = "Sythrax",
          },
          ["Staunch Recovery"] = {
            aliases = {
              "Vitalizing Earring of the Darkfaith",
            },
            ids = {
            },
            item = "Vitalizing Earring of the Darkfaith",
            source = "Brother",
          },
          Vault2 = {
            aliases = {
              "Defiant Trithcink",
            },
            ids = {
            },
            item = "Defiant Trithcink",
          },
          Vault3 = {
            aliases = {
              "Exalted Glowing Bath Token",
            },
            ids = {
            },
            item = "Exalted Glowing Bath Token",
          },
        },
        Enchanter = {
          CasterFamiliar = {
            aliases = {
              "Forgotten Warlock's Ring",
            },
            ids = {
            },
            item = "Forgotten Warlock's Ring",
            source = "Highborn",
          },
          ["Dimensional Shield"] = {
            aliases = {
              "Elusive Ritual Talisman of Fate",
            },
            ids = {
            },
            item = "Elusive Ritual Talisman of Fate",
            source = "Gamus",
          },
          ["Forceful Rejuvenation"] = {
            aliases = {
              "Cunning Necklace of Dark Rituals",
            },
            ids = {
            },
            item = "Cunning Necklace of Dark Rituals",
            source = "Warlocks",
          },
          ["Frenzied Devastation"] = {
            aliases = {
              "Malefic Ceremonial Sh'Voth",
            },
            ids = {
            },
            item = "Malefic Ceremonial Sh'Voth",
            source = "Sythrax",
          },
          ["Glyph Aug"] = {
            aliases = {
              "Destructive Focus Glyph: Mind Shatter",
            },
            ids = {
            },
            item = "Destructive Focus Glyph: Mind Shatter",
          },
          ["Glyphed Sarnak Skull"] = {
            aliases = {
              "Glyphed Sarnak Skull",
            },
            ids = {
              40856,
            },
            item = "Glyphed Sarnak Skull",
          },
          Key2 = {
            aliases = {
              "Resilient Key",
            },
            ids = {
              42461,
            },
            item = "Resilient Key",
          },
          ["Radiant Cure"] = {
            aliases = {
              "Cleansing Band of Twilight",
            },
            ids = {
            },
            item = "Cleansing Band of Twilight",
            source = "Warlocks",
          },
          Retreat = {
            aliases = {
              "Shadowy Silken Veil of Gazing",
            },
            ids = {
            },
            item = "Shadowy Silken Veil of Gazing",
            source = "Sythrax",
          },
          ["Staunch Recovery"] = {
            aliases = {
              "Vitalizing Earring of the Darkfaith",
            },
            ids = {
            },
            item = "Vitalizing Earring of the Darkfaith",
            source = "Brother",
          },
          Vault2 = {
            aliases = {
              "Defiant Trithcink",
            },
            ids = {
            },
            item = "Defiant Trithcink",
          },
        },
        Magician = {
          CasterFamiliar = {
            aliases = {
              "Forgotten Warlock's Ring",
            },
            ids = {
            },
            item = "Forgotten Warlock's Ring",
            source = "Highborn",
          },
          ["Dimensional Shield"] = {
            aliases = {
              "Elusive Ritual Talisman of Fate",
            },
            ids = {
            },
            item = "Elusive Ritual Talisman of Fate",
            source = "Gamus",
          },
          ["Divine Companion's Aura"] = {
            aliases = {
              "Enduring Bloodgill Belt",
            },
            ids = {
            },
            item = "Enduring Bloodgill Belt",
            source = "Gamus",
          },
          ["Forceful Rejuvenation"] = {
            aliases = {
              "Cunning Necklace of Dark Rituals",
            },
            ids = {
            },
            item = "Cunning Necklace of Dark Rituals",
            source = "Warlocks",
          },
          ["Frenzied Devastation"] = {
            aliases = {
              "Malefic Ceremonial Sh'Voth",
            },
            ids = {
            },
            item = "Malefic Ceremonial Sh'Voth",
            source = "Sythrax",
          },
          ["Glyph Aug"] = {
            aliases = {
              "Destructive Focus Glyph: Spear of Ro",
            },
            ids = {
            },
            item = "Destructive Focus Glyph: Spear of Ro",
          },
          ["Glyphed Sarnak Skull"] = {
            aliases = {
              "Glyphed Sarnak Skull",
            },
            ids = {
              40855,
            },
            item = "Glyphed Sarnak Skull",
          },
          ["Intensity of the Resolute"] = {
            aliases = {
              "Audacious Kunzar Tu'Lal",
            },
            ids = {
            },
            item = "Audacious Kunzar Tu'Lal",
            source = "Brother",
          },
          Key2 = {
            aliases = {
              "Resilient Key",
            },
            ids = {
              42461,
            },
            item = "Resilient Key",
          },
          Retreat = {
            aliases = {
              "Shadowy Silken Veil of Gazing",
            },
            ids = {
            },
            item = "Shadowy Silken Veil of Gazing",
            source = "Sythrax",
          },
          Vault2 = {
            aliases = {
              "Defiant Trithcink",
            },
            ids = {
            },
            item = "Defiant Trithcink",
          },
        },
        Monk = {
          ["Ancestral Memories"] = {
            aliases = {
              "Zealous Soulscream Belt",
            },
            ids = {
            },
            item = "Zealous Soulscream Belt",
            source = "Gamus",
          },
          ["Dimensional Shield"] = {
            aliases = {
              "Elusive Ritual Talisman of Fate",
            },
            ids = {
            },
            item = "Elusive Ritual Talisman of Fate",
            source = "Gamus",
          },
          ["Feral Swipe"] = {
            aliases = {
              "Cunning Razor-edged Claw",
            },
            ids = {
            },
            item = "Cunning Razor-edged Claw",
            source = "Brother",
          },
          ["Glyph Aug"] = {
            aliases = {
              "Rapid Focus Glyph: Dragon Fang",
            },
            ids = {
            },
            item = "Rapid Focus Glyph: Dragon Fang",
          },
          ["Glyphed Sarnak Skull"] = {
            aliases = {
              "Glyphed Sarnak Skull",
            },
            ids = {
              40848,
            },
            item = "Glyphed Sarnak Skull",
          },
          ["Intensity of the Resolute"] = {
            aliases = {
              "Audacious Kunzar Tu'Lal",
            },
            ids = {
            },
            item = "Audacious Kunzar Tu'Lal",
            source = "Brother",
          },
          Key1 = {
            aliases = {
              "Pliant Key",
            },
            ids = {
              40818,
            },
            item = "Pliant Key",
          },
          Key2 = {
            aliases = {
              "Resilient Key",
            },
            ids = {
              42461,
            },
            item = "Resilient Key",
          },
          MeleeFamiliar = {
            aliases = {
              "Forgotten Leather Leash",
            },
            ids = {
            },
            item = "Forgotten Leather Leash",
            source = "Behemoth",
          },
          ["Prot of the Spirit Wolf"] = {
            aliases = {
              "Fervent Eyepatch of Warding",
            },
            ids = {
            },
            item = "Fervent Eyepatch of Warding",
            source = "Warlocks",
          },
          ["Radiant Cure"] = {
            aliases = {
              "Cleansing Band of Twilight",
            },
            ids = {
            },
            item = "Cleansing Band of Twilight",
            source = "Warlocks",
          },
          Rally = {
            aliases = {
              "Vigilant Tu'Nakk Parryblade",
            },
            ids = {
            },
            item = "Vigilant Tu'Nakk Parryblade",
            source = "Brother",
          },
          Vault1 = {
            aliases = {
              "Stalwart Battleworn Ch'Ror",
            },
            ids = {
            },
            item = "Stalwart Battleworn Ch'Ror",
          },
          Vault2 = {
            aliases = {
              "Defiant Trithcink",
            },
            ids = {
            },
            item = "Defiant Trithcink",
          },
        },
        Necromancer = {
          CasterFamiliar = {
            aliases = {
              "Forgotten Warlock's Ring",
            },
            ids = {
            },
            item = "Forgotten Warlock's Ring",
            source = "Highborn",
          },
          ["Dimensional Shield"] = {
            aliases = {
              "Elusive Ritual Talisman of Fate",
            },
            ids = {
            },
            item = "Elusive Ritual Talisman of Fate",
            source = "Gamus",
          },
          ["Divine Companion's Aura"] = {
            aliases = {
              "Enduring Bloodgill Belt",
            },
            ids = {
            },
            item = "Enduring Bloodgill Belt",
            source = "Gamus",
          },
          ["Forceful Rejuvenation"] = {
            aliases = {
              "Cunning Necklace of Dark Rituals",
            },
            ids = {
            },
            item = "Cunning Necklace of Dark Rituals",
            source = "Warlocks",
          },
          ["Frenzied Devastation"] = {
            aliases = {
              "Malefic Ceremonial Sh'Voth",
            },
            ids = {
            },
            item = "Malefic Ceremonial Sh'Voth",
            source = "Sythrax",
          },
          ["Glyph Aug"] = {
            aliases = {
              "Destructive Focus Glyph: Chaos Plague",
            },
            ids = {
            },
            item = "Destructive Focus Glyph: Chaos Plague",
          },
          ["Glyphed Sarnak Skull"] = {
            aliases = {
              "Glyphed Sarnak Skull",
            },
            ids = {
              40857,
            },
            item = "Glyphed Sarnak Skull",
          },
          ["Intensity of the Resolute"] = {
            aliases = {
              "Audacious Kunzar Tu'Lal",
            },
            ids = {
            },
            item = "Audacious Kunzar Tu'Lal",
            source = "Brother",
          },
          Key2 = {
            aliases = {
              "Resilient Key",
            },
            ids = {
              42461,
            },
            item = "Resilient Key",
          },
          Key3 = {
            aliases = {
              "Sanctified Key",
            },
            ids = {
              40813,
            },
            item = "Sanctified Key",
          },
          Retreat = {
            aliases = {
              "Shadowy Silken Veil of Gazing",
            },
            ids = {
            },
            item = "Shadowy Silken Veil of Gazing",
            source = "Sythrax",
          },
          Vault2 = {
            aliases = {
              "Defiant Trithcink",
            },
            ids = {
            },
            item = "Defiant Trithcink",
          },
          Vault3 = {
            aliases = {
              "Exalted Glowing Bath Token",
            },
            ids = {
            },
            item = "Exalted Glowing Bath Token",
          },
        },
        Paladin = {
          ["Ageless Enmity"] = {
            aliases = {
              "Rancorous Mantle of Ill Omen",
            },
            ids = {
            },
            item = "Rancorous Mantle of Ill Omen",
            source = "Sythrax",
          },
          ["Ancestral Memories"] = {
            aliases = {
              "Zealous Soulscream Belt",
            },
            ids = {
            },
            item = "Zealous Soulscream Belt",
            source = "Gamus",
          },
          ["Armor of Experience"] = {
            aliases = {
              "Stout Mithril Spiked Collar",
            },
            ids = {
            },
            item = "Stout Mithril Spiked Collar",
            source = "Warlocks",
          },
          ["Forceful Rejuvenation"] = {
            aliases = {
              "Cunning Necklace of Dark Rituals",
            },
            ids = {
            },
            item = "Cunning Necklace of Dark Rituals",
            source = "Warlocks",
          },
          ["Glyph Aug"] = {
            aliases = {
              "Mending Focus Glyph: Light of Piety",
            },
            ids = {
            },
            item = "Mending Focus Glyph: Light of Piety",
          },
          ["Glyphed Sarnak Skull"] = {
            aliases = {
              "Glyphed Sarnak Skull",
            },
            ids = {
              40846,
            },
            item = "Glyphed Sarnak Skull",
          },
          Key3 = {
            aliases = {
              "Sanctified Key",
            },
            ids = {
              40813,
            },
            item = "Sanctified Key",
          },
          Key4 = {
            aliases = {
              "Stout Key",
            },
            ids = {
              40816,
            },
            item = "Stout Key",
          },
          MeleeFamiliar = {
            aliases = {
              "Forgotten Leather Leash",
            },
            ids = {
            },
            item = "Forgotten Leather Leash",
            source = "Behemoth",
          },
          Rally = {
            aliases = {
              "Vigilant Tu'Nakk Parryblade",
            },
            ids = {
            },
            item = "Vigilant Tu'Nakk Parryblade",
            source = "Brother",
          },
          Vault3 = {
            aliases = {
              "Exalted Glowing Bath Token",
            },
            ids = {
            },
            item = "Exalted Glowing Bath Token",
          },
          Vault4 = {
            aliases = {
              "Bloodthirsty Draconic Idol",
            },
            ids = {
            },
            item = "Bloodthirsty Draconic Idol",
          },
          ["Warlord's Bravery"] = {
            aliases = {
              "Obstinate Kunzar Deathguard Shield",
            },
            ids = {
            },
            item = "Obstinate Kunzar Deathguard Shield",
            source = "Brother",
          },
        },
        Ranger = {
          ["Ageless Enmity"] = {
            aliases = {
              "Rancorous Mantle of Ill Omen",
            },
            ids = {
            },
            item = "Rancorous Mantle of Ill Omen",
            source = "Sythrax",
          },
          ["Ancestral Memories"] = {
            aliases = {
              "Zealous Soulscream Belt",
            },
            ids = {
            },
            item = "Zealous Soulscream Belt",
            source = "Gamus",
          },
          ["Dimensional Shield"] = {
            aliases = {
              "Elusive Ritual Talisman of Fate",
            },
            ids = {
            },
            item = "Elusive Ritual Talisman of Fate",
            source = "Gamus",
          },
          ["Feral Swipe"] = {
            aliases = {
              "Cunning Razor-edged Claw",
            },
            ids = {
            },
            item = "Cunning Razor-edged Claw",
            source = "Brother",
          },
          ["Forceful Rejuvenation"] = {
            aliases = {
              "Cunning Necklace of Dark Rituals",
            },
            ids = {
            },
            item = "Cunning Necklace of Dark Rituals",
            source = "Warlocks",
          },
          ["Glyph Aug"] = {
            aliases = {
              "Destructive Focus Glyph: Scorched Earth",
            },
            ids = {
            },
            item = "Destructive Focus Glyph: Scorched Earth",
          },
          ["Glyphed Sarnak Skull"] = {
            aliases = {
              "Glyphed Sarnak Skull",
            },
            ids = {
              40858,
            },
            item = "Glyphed Sarnak Skull",
          },
          ["Intensity of the Resolute"] = {
            aliases = {
              "Audacious Kunzar Tu'Lal",
            },
            ids = {
            },
            item = "Audacious Kunzar Tu'Lal",
            source = "Brother",
          },
          Key1 = {
            aliases = {
              "Barbed Key",
            },
            ids = {
              41172,
            },
            item = "Barbed Key",
          },
          Key2 = {
            aliases = {
              "Resilient Key",
            },
            ids = {
              42461,
            },
            item = "Resilient Key",
          },
          MeleeFamiliar = {
            aliases = {
              "Forgotten Leather Leash",
            },
            ids = {
            },
            item = "Forgotten Leather Leash",
            source = "Behemoth",
          },
          ["Prot of the Spirit Wolf"] = {
            aliases = {
              "Fervent Eyepatch of Warding",
            },
            ids = {
            },
            item = "Fervent Eyepatch of Warding",
            source = "Warlocks",
          },
          Retreat = {
            aliases = {
              "Shadowy Silken Veil of Gazing",
            },
            ids = {
            },
            item = "Shadowy Silken Veil of Gazing",
            source = "Sythrax",
          },
          Vault1 = {
            aliases = {
              "Kylong Stalker's Quiver",
            },
            ids = {
            },
            item = "Kylong Stalker's Quiver",
          },
          Vault2 = {
            aliases = {
              "Defiant Trithcink",
            },
            ids = {
            },
            item = "Defiant Trithcink",
          },
        },
        Rogue = {
          ["Ancestral Memories"] = {
            aliases = {
              "Zealous Soulscream Belt",
            },
            ids = {
            },
            item = "Zealous Soulscream Belt",
            source = "Gamus",
          },
          ["Dimensional Shield"] = {
            aliases = {
              "Elusive Ritual Talisman of Fate",
            },
            ids = {
            },
            item = "Elusive Ritual Talisman of Fate",
            source = "Gamus",
          },
          ["Feral Swipe"] = {
            aliases = {
              "Cunning Razor-edged Claw",
            },
            ids = {
            },
            item = "Cunning Razor-edged Claw",
            source = "Brother",
          },
          ["Glyph Aug"] = {
            aliases = {
              "Rapid Focus Glyph: Assault",
            },
            ids = {
            },
            item = "Rapid Focus Glyph: Assault",
          },
          ["Glyphed Sarnak Skull"] = {
            aliases = {
              "Glyphed Sarnak Skull",
            },
            ids = {
              40849,
            },
            item = "Glyphed Sarnak Skull",
          },
          ["Intensity of the Resolute"] = {
            aliases = {
              "Audacious Kunzar Tu'Lal",
            },
            ids = {
            },
            item = "Audacious Kunzar Tu'Lal",
            source = "Brother",
          },
          Key2 = {
            aliases = {
              "Resilient Key",
            },
            ids = {
              42461,
            },
            item = "Resilient Key",
          },
          MeleeFamiliar = {
            aliases = {
              "Forgotten Leather Leash",
            },
            ids = {
            },
            item = "Forgotten Leather Leash",
            source = "Behemoth",
          },
          ["Prot of the Spirit Wolf"] = {
            aliases = {
              "Fervent Eyepatch of Warding",
            },
            ids = {
            },
            item = "Fervent Eyepatch of Warding",
            source = "Warlocks",
          },
          Retreat = {
            aliases = {
              "Shadowy Silken Veil of Gazing",
            },
            ids = {
            },
            item = "Shadowy Silken Veil of Gazing",
            source = "Sythrax",
          },
          Sap = {
            aliases = {
              "Forgotten Mugger's Sap",
            },
            ids = {
            },
            item = "Forgotten Mugger's Sap",
            source = "Chef",
          },
          Vault2 = {
            aliases = {
              "Defiant Trithcink",
            },
            ids = {
            },
            item = "Defiant Trithcink",
          },
          ["Warlord's Bravery"] = {
            aliases = {
              "Obstinate Kunzar Deathguard Shield",
            },
            ids = {
            },
            item = "Obstinate Kunzar Deathguard Shield",
            source = "Brother",
          },
        },
        ["Shadow Knight"] = {
          ["Ageless Enmity"] = {
            aliases = {
              "Rancorous Mantle of Ill Omen",
            },
            ids = {
            },
            item = "Rancorous Mantle of Ill Omen",
            source = "Sythrax",
          },
          ["Ancestral Memories"] = {
            aliases = {
              "Zealous Soulscream Belt",
            },
            ids = {
            },
            item = "Zealous Soulscream Belt",
            source = "Gamus",
          },
          ["Armor of Experience"] = {
            aliases = {
              "Stout Mithril Spiked Collar",
            },
            ids = {
            },
            item = "Stout Mithril Spiked Collar",
            source = "Warlocks",
          },
          ["Divine Companion's Aura"] = {
            aliases = {
              "Enduring Bloodgill Belt",
            },
            ids = {
            },
            item = "Enduring Bloodgill Belt",
            source = "Gamus",
          },
          ["Forceful Rejuvenation"] = {
            aliases = {
              "Cunning Necklace of Dark Rituals",
            },
            ids = {
            },
            item = "Cunning Necklace of Dark Rituals",
            source = "Warlocks",
          },
          ["Glyph Aug"] = {
            aliases = {
              "Destructive Focus Glyph: Touch of the Devourer",
            },
            ids = {
            },
            item = "Destructive Focus Glyph: Touch of the Devourer",
          },
          ["Glyphed Sarnak Skull"] = {
            aliases = {
              "Glyphed Sarnak Skull",
            },
            ids = {
              40847,
            },
            item = "Glyphed Sarnak Skull",
          },
          Key3 = {
            aliases = {
              "Sanctified Key",
            },
            ids = {
              40813,
            },
            item = "Sanctified Key",
          },
          Key4 = {
            aliases = {
              "Stout Key",
            },
            ids = {
              40816,
            },
            item = "Stout Key",
          },
          MeleeFamiliar = {
            aliases = {
              "Forgotten Leather Leash",
            },
            ids = {
            },
            item = "Forgotten Leather Leash",
            source = "Behemoth",
          },
          Rally = {
            aliases = {
              "Vigilant Tu'Nakk Parryblade",
            },
            ids = {
            },
            item = "Vigilant Tu'Nakk Parryblade",
            source = "Brother",
          },
          Vault3 = {
            aliases = {
              "Exalted Glowing Bath Token",
            },
            ids = {
            },
            item = "Exalted Glowing Bath Token",
          },
          Vault4 = {
            aliases = {
              "Bloodthirsty Draconic Idol",
            },
            ids = {
            },
            item = "Bloodthirsty Draconic Idol",
          },
          ["Warlord's Bravery"] = {
            aliases = {
              "Obstinate Kunzar Deathguard Shield",
            },
            ids = {
            },
            item = "Obstinate Kunzar Deathguard Shield",
            source = "Brother",
          },
        },
        Shaman = {
          CasterFamiliar = {
            aliases = {
              "Forgotten Warlock's Ring",
            },
            ids = {
            },
            item = "Forgotten Warlock's Ring",
            source = "Highborn",
          },
          ["Divine Companion's Aura"] = {
            aliases = {
              "Enduring Bloodgill Belt",
            },
            ids = {
            },
            item = "Enduring Bloodgill Belt",
            source = "Gamus",
          },
          ["Forceful Rejuvenation"] = {
            aliases = {
              "Cunning Necklace of Dark Rituals",
            },
            ids = {
            },
            item = "Cunning Necklace of Dark Rituals",
            source = "Warlocks",
          },
          ["Frenzied Devastation"] = {
            aliases = {
              "Malefic Ceremonial Sh'Voth",
            },
            ids = {
            },
            item = "Malefic Ceremonial Sh'Voth",
            source = "Sythrax",
          },
          ["Glyph Aug"] = {
            aliases = {
              "Destructive Focus Glyph: Blood of Yoppa",
            },
            ids = {
            },
            item = "Destructive Focus Glyph: Blood of Yoppa",
          },
          ["Glyphed Sarnak Skull"] = {
            aliases = {
              "Glyphed Sarnak Skull",
            },
            ids = {
              40852,
            },
            item = "Glyphed Sarnak Skull",
          },
          Key2 = {
            aliases = {
              "Resilient Key",
            },
            ids = {
              42461,
            },
            item = "Resilient Key",
          },
          Key3 = {
            aliases = {
              "Sanctified Key",
            },
            ids = {
              40813,
            },
            item = "Sanctified Key",
          },
          ["Prot of the Spirit Wolf"] = {
            aliases = {
              "Fervent Eyepatch of Warding",
            },
            ids = {
            },
            item = "Fervent Eyepatch of Warding",
            source = "Warlocks",
          },
          ["Radiant Cure"] = {
            aliases = {
              "Cleansing Band of Twilight",
            },
            ids = {
            },
            item = "Cleansing Band of Twilight",
            source = "Warlocks",
          },
          Retreat = {
            aliases = {
              "Shadowy Silken Veil of Gazing",
            },
            ids = {
            },
            item = "Shadowy Silken Veil of Gazing",
            source = "Sythrax",
          },
          ["Staunch Recovery"] = {
            aliases = {
              "Vitalizing Earring of the Darkfaith",
            },
            ids = {
            },
            item = "Vitalizing Earring of the Darkfaith",
            source = "Brother",
          },
          Vault2 = {
            aliases = {
              "Defiant Trithcink",
            },
            ids = {
            },
            item = "Defiant Trithcink",
          },
          Vault3 = {
            aliases = {
              "Exalted Glowing Bath Token",
            },
            ids = {
            },
            item = "Exalted Glowing Bath Token",
          },
        },
        Warrior = {
          ["Ageless Enmity"] = {
            aliases = {
              "Rancorous Mantle of Ill Omen",
            },
            ids = {
            },
            item = "Rancorous Mantle of Ill Omen",
            source = "Sythrax",
          },
          ["Ancestral Memories"] = {
            aliases = {
              "Zealous Soulscream Belt",
            },
            ids = {
            },
            item = "Zealous Soulscream Belt",
            source = "Gamus",
          },
          ["Armor of Experience"] = {
            aliases = {
              "Stout Mithril Spiked Collar",
            },
            ids = {
            },
            item = "Stout Mithril Spiked Collar",
            source = "Warlocks",
          },
          ["Feral Swipe"] = {
            aliases = {
              "Cunning Razor-edged Claw",
            },
            ids = {
            },
            item = "Cunning Razor-edged Claw",
            source = "Brother",
          },
          ["Glyph Aug"] = {
            aliases = {
              "Rapid Focus Glyph: Mock and Flaunt",
            },
            ids = {
            },
            item = "Rapid Focus Glyph: Mock and Flaunt",
          },
          ["Glyphed Sarnak Skull"] = {
            aliases = {
              "Glyphed Sarnak Skull",
            },
            ids = {
              40845,
            },
            item = "Glyphed Sarnak Skull",
          },
          Key1 = {
            aliases = {
              "Abrasive Key",
            },
            ids = {
              40819,
            },
            item = "Abrasive Key",
          },
          Key3 = {
            aliases = {
              "Sanctified Key",
            },
            ids = {
              40813,
            },
            item = "Sanctified Key",
          },
          Key4 = {
            aliases = {
              "Stout Key",
            },
            ids = {
              40816,
            },
            item = "Stout Key",
          },
          MeleeFamiliar = {
            aliases = {
              "Forgotten Leather Leash",
            },
            ids = {
            },
            item = "Forgotten Leather Leash",
            source = "Behemoth",
          },
          Rally = {
            aliases = {
              "Vigilant Tu'Nakk Parryblade",
            },
            ids = {
            },
            item = "Vigilant Tu'Nakk Parryblade",
            source = "Brother",
          },
          Vault1 = {
            aliases = {
              "Ruinous Razor-Edged Shan'Tok",
            },
            ids = {
            },
            item = "Ruinous Razor-Edged Shan'Tok",
          },
          Vault3 = {
            aliases = {
              "Exalted Glowing Bath Token",
            },
            ids = {
            },
            item = "Exalted Glowing Bath Token",
          },
          Vault4 = {
            aliases = {
              "Bloodthirsty Draconic Idol",
            },
            ids = {
            },
            item = "Bloodthirsty Draconic Idol",
          },
          ["Warlord's Bravery"] = {
            aliases = {
              "Obstinate Kunzar Deathguard Shield",
            },
            ids = {
            },
            item = "Obstinate Kunzar Deathguard Shield",
            source = "Brother",
          },
        },
        Wizard = {
          CasterFamiliar = {
            aliases = {
              "Forgotten Warlock's Ring",
            },
            ids = {
            },
            item = "Forgotten Warlock's Ring",
            source = "Highborn",
          },
          ["Dimensional Shield"] = {
            aliases = {
              "Elusive Ritual Talisman of Fate",
            },
            ids = {
            },
            item = "Elusive Ritual Talisman of Fate",
            source = "Gamus",
          },
          ["Forceful Rejuvenation"] = {
            aliases = {
              "Cunning Necklace of Dark Rituals",
            },
            ids = {
            },
            item = "Cunning Necklace of Dark Rituals",
            source = "Warlocks",
          },
          ["Frenzied Devastation"] = {
            aliases = {
              "Malefic Ceremonial Sh'Voth",
            },
            ids = {
            },
            item = "Malefic Ceremonial Sh'Voth",
            source = "Sythrax",
          },
          ["Glyph Aug"] = {
            aliases = {
              "Destructive Focus Glyph: Ether Flame",
            },
            ids = {
            },
            item = "Destructive Focus Glyph: Ether Flame",
          },
          ["Glyphed Sarnak Skull"] = {
            aliases = {
              "Glyphed Sarnak Skull",
            },
            ids = {
              40854,
            },
            item = "Glyphed Sarnak Skull",
          },
          ["Intensity of the Resolute"] = {
            aliases = {
              "Audacious Kunzar Tu'Lal",
            },
            ids = {
            },
            item = "Audacious Kunzar Tu'Lal",
            source = "Brother",
          },
          Key1 = {
            aliases = {
              "Key of Ill Omen",
            },
            ids = {
            },
            item = "Key of Ill Omen",
          },
          Key2 = {
            aliases = {
              "Resilient Key",
            },
            ids = {
              42461,
            },
            item = "Resilient Key",
          },
          Retreat = {
            aliases = {
              "Shadowy Silken Veil of Gazing",
            },
            ids = {
            },
            item = "Shadowy Silken Veil of Gazing",
            source = "Sythrax",
          },
          Vault2 = {
            aliases = {
              "Defiant Trithcink",
            },
            ids = {
            },
            item = "Defiant Trithcink",
          },
          ["Warlord's Bravery"] = {
            aliases = {
              "Obstinate Kunzar Deathguard Shield",
            },
            ids = {
            },
            item = "Obstinate Kunzar Deathguard Shield",
            source = "Brother",
          },
        },
      },
      group = "Raid Best In Slot",
      id = "veksar",
      name = "Veksar",
      show_base = {
        ["Base (Trash)"] = 1,
        ["Gem1 (Minis)"] = 1,
        ["Gem2 (Gamus)"] = 1,
        ["Gem3 (Warlocks)"] = 1,
        ["Gem4 (Sythrax)"] = 1,
        ["Gem5 (Brother)"] = 1,
        ["Gem6 (Garudon)"] = 1,
        ["Glyphed Sarnak Skull"] = 1,
        Key1 = 1,
        Key2 = 1,
        Key3 = 1,
        Key4 = 1,
      },
      template = {
        ["Base (Trash)"] = {
          aliases = {
            "Ancient Bauble Remnant",
          },
          ids = {
            40805,
            40806,
            40807,
            40808,
            40809,
            40810,
          },
          item = "Ancient Bauble Remnant",
        },
        Final = {
          aliases = {
            "Ancient Bauble of Ill Omen",
          },
          ids = {
          },
          item = "Ancient Bauble of Ill Omen",
        },
        ["Gem1 (Minis)"] = {
          aliases = {
            "Xanthous Prismatic Remnant",
          },
          ids = {
            40805,
            40806,
            40807,
            40808,
            40809,
            40810,
          },
          item = "Xanthous Prismatic Remnant",
        },
        ["Gem2 (Gamus)"] = {
          aliases = {
            "Cerulean Prismatic Remnant",
          },
          ids = {
            40806,
            40807,
            40808,
            40809,
            40810,
          },
          item = "Cerulean Prismatic Remnant",
        },
        ["Gem3 (Warlocks)"] = {
          aliases = {
            "Titian Prismatic Remnant",
          },
          ids = {
            40807,
            40808,
            40809,
            40810,
          },
          item = "Titian Prismatic Remnant",
        },
        ["Gem4 (Sythrax)"] = {
          aliases = {
            "Violaceous Prismatic Remnant",
          },
          ids = {
            40808,
            40809,
            40810,
          },
          item = "Violaceous Prismatic Remnant",
        },
        ["Gem5 (Brother)"] = {
          aliases = {
            "Incarnadine Prismatic Remnant",
          },
          ids = {
            40809,
            40810,
          },
          item = "Incarnadine Prismatic Remnant",
        },
        ["Gem6 (Garudon)"] = {
          aliases = {
            "Nacreous Prismatic Remnant",
          },
          ids = {
            40810,
          },
          item = "Nacreous Prismatic Remnant",
        },
      },
      visible = {
      },
    },
    vendoritems = {
      categories = {
        {
          name = "Discordian",
          slots = {
            "Annihilation(Spell Damage)",
            "VolatileDiscordian(Spell Damage)",
            "FocusDestruction(Overall Spell damage)",
            "FocusAtrophy(Overall DoT damage)",
            "Evasion(Avoidance)",
            "MysticalAegis(DoT Shield)",
            "Precision(Accuracy)",
            "Rapidity(Attack)",
            "Tenacity(Defense)",
          },
        },
        {
          name = "Planar",
          slots = {
            "AdeptBlows(Tiger Claw)",
            "BruteForce(Bash)",
            "DexterousStriking(Flying Kick)",
            "EnchantedJewel(Shielding)",
            "EscalatingOnslaught(HStr)",
            "FoulPlay(Backstab)",
            "FuriousAssault(Frenzy)",
            "MysticalAegis(Spell Shield)",
            "Prowess(Offense)",
            "Striking(Kick)",
            "VolatilePlanar(Spell Damage)",
          },
        },
        {
          name = "Diamond Coins",
          slots = {
            "Manastone",
          },
        },
        {
          name = "Gold Coins",
          slots = {
            "DarkArachnids(Does not stack with other Dodge)",
            "Dragorn(+ 10 to Wep Skills)",
            "War Bear Saddle(Or any other AC Mount)",
            "WarPirate(Does not stack with Brell)",
          },
          display_only_slots = {
            ["WarPirate(Does not stack with Brell)"] = "Legacy Gold Coin display reminder; no canonical item identity is present in the repository source.",
          },
        },
        {
          name = "Celestial Crests",
          slots = {
            "Bifold",
            "BloodDrinker",
            "IdolScale",
            "Lucky Copper/Silver",
            "Lucky Grass",
            "Lucky Horseshoe",
            "Mount",
            "Oculous",
            "VenomVial",
          },
        },
        {
          name = "Player Made",
          slots = {
            "BoarWhistle",
            "SnakeFlute",
          },
        },
      },
      classes = {
        Bard = {
          BloodDrinker = {
            aliases = {
              "Blood Drinker's Coating",
            },
            ids = {
            },
            item = "Blood Drinker's Coating",
          },
          BoarWhistle = {
            aliases = {
              "Boar Caller's Whistle",
            },
            ids = {
              150851,
            },
            item = "Boar Caller's Whistle",
          },
          ["Dragorn(+ 10 to Wep Skills)"] = {
            aliases = {
              "Dragorn War Mask",
            },
            ids = {
            },
            item = "Dragorn War Mask",
          },
          ["EscalatingOnslaught(HStr)"] = {
            aliases = {
              "Planar Alloy of Escalating Onslaught",
            },
            ids = {
            },
            item = "Planar Alloy of Escalating Onslaught",
          },
          IdolScale = {
            aliases = {
              "Idol of the Scale",
            },
            ids = {
              150977,
            },
            item = "Idol of the Scale",
          },
          ["Striking(Kick)"] = {
            aliases = {
              "Focus Rune of Striking",
            },
            ids = {
            },
            item = "Focus Rune of Striking",
          },
          VenomVial = {
            aliases = {
              "Bottomless Venom Vial",
            },
            ids = {
            },
            item = "Bottomless Venom Vial",
          },
        },
        Beastlord = {
          Bifold = {
            aliases = {
              "Bifold Focus of the Evil Eye",
            },
            ids = {
            },
            item = "Bifold Focus of the Evil Eye",
          },
          BloodDrinker = {
            aliases = {
              "Blood Drinker's Coating",
            },
            ids = {
            },
            item = "Blood Drinker's Coating",
          },
          BoarWhistle = {
            aliases = {
              "Boar Caller's Whistle",
            },
            ids = {
              150851,
            },
            item = "Boar Caller's Whistle",
          },
          ["Dragorn(+ 10 to Wep Skills)"] = {
            aliases = {
              "Dragorn War Mask",
            },
            ids = {
            },
            item = "Dragorn War Mask",
          },
          ["EscalatingOnslaught(HStr)"] = {
            aliases = {
              "Planar Alloy of Escalating Onslaught",
            },
            ids = {
            },
            item = "Planar Alloy of Escalating Onslaught",
          },
          ["FocusAtrophy(Overall DoT damage)"] = {
            aliases = {
              "Focus Shard of Atrophy",
            },
            ids = {
              150048,
            },
            item = "Focus Shard of Atrophy",
            notes = "Not as strong as typed DoT-damage augs, but covers all DoT types. Useful for one broad boost while filling other slots with physical prowess or other augs.",
          },
          ["FocusDestruction(Overall Spell damage)"] = {
            aliases = {
              "Focus Shard of Destruction",
            },
            ids = {
              150047,
            },
            item = "Focus Shard of Destruction",
            notes = "Not as strong as typed spell-damage augs, but covers all spell types. Useful for one broad boost while filling other slots with physical prowess or other augs.",
          },
          IdolScale = {
            aliases = {
              "Idol of the Scale",
            },
            ids = {
              150977,
            },
            item = "Idol of the Scale",
          },
          Manastone = {
            aliases = {
              "Manastone",
            },
            ids = {
            },
            item = "Manastone",
          },
          ["Striking(Kick)"] = {
            aliases = {
              "Focus Rune of Striking",
            },
            ids = {
            },
            item = "Focus Rune of Striking",
          },
          VenomVial = {
            aliases = {
              "Bottomless Venom Vial",
            },
            ids = {
            },
            item = "Bottomless Venom Vial",
          },
          ["VolatileDiscordian(Spell Damage)"] = {
            aliases = {
              "Volatile Discordian Rune",
            },
            ids = {
              150040,
            },
            item = "Volatile Discordian Rune",
          },
          ["VolatilePlanar(Spell Damage)"] = {
            aliases = {
              "Volatile Planar Rune",
            },
            ids = {
              150033,
            },
            item = "Volatile Planar Rune",
          },
        },
        Berserker = {
          BloodDrinker = {
            aliases = {
              "Blood Drinker's Coating",
            },
            ids = {
            },
            item = "Blood Drinker's Coating",
          },
          BoarWhistle = {
            aliases = {
              "Boar Caller's Whistle",
            },
            ids = {
              150851,
            },
            item = "Boar Caller's Whistle",
          },
          ["Dragorn(+ 10 to Wep Skills)"] = {
            aliases = {
              "Dragorn War Mask",
            },
            ids = {
            },
            item = "Dragorn War Mask",
          },
          ["EscalatingOnslaught(HStr)"] = {
            aliases = {
              "Planar Alloy of Escalating Onslaught",
            },
            ids = {
            },
            item = "Planar Alloy of Escalating Onslaught",
          },
          ["FuriousAssault(Frenzy)"] = {
            aliases = {
              "Focus Rune of Furious Assault",
            },
            ids = {
            },
            item = "Focus Rune of Furious Assault",
          },
          IdolScale = {
            aliases = {
              "Idol of the Scale",
            },
            ids = {
              150977,
            },
            item = "Idol of the Scale",
          },
          VenomVial = {
            aliases = {
              "Bottomless Venom Vial",
            },
            ids = {
            },
            item = "Bottomless Venom Vial",
          },
        },
        Cleric = {
          Bifold = {
            aliases = {
              "Bifold Focus of the Evil Eye",
            },
            ids = {
            },
            item = "Bifold Focus of the Evil Eye",
          },
          ["FocusAtrophy(Overall DoT damage)"] = {
            aliases = {
              "Focus Shard of Atrophy",
            },
            ids = {
              150048,
            },
            item = "Focus Shard of Atrophy",
            notes = "Not as strong as typed DoT-damage augs, but covers all DoT types. Useful for one broad boost while filling other slots with physical prowess or other augs.",
          },
          ["FocusDestruction(Overall Spell damage)"] = {
            aliases = {
              "Focus Shard of Destruction",
            },
            ids = {
              150047,
            },
            item = "Focus Shard of Destruction",
            notes = "Not as strong as typed spell-damage augs, but covers all spell types. Useful for one broad boost while filling other slots with physical prowess or other augs.",
          },
          Manastone = {
            aliases = {
              "Manastone",
            },
            ids = {
            },
            item = "Manastone",
          },
          SnakeFlute = {
            aliases = {
              "Snake Charmer's Flute",
            },
            ids = {
              40459,
            },
            item = "Snake Charmer's Flute",
          },
          ["VolatileDiscordian(Spell Damage)"] = {
            aliases = {
              "Volatile Discordian Rune",
            },
            ids = {
              150040,
            },
            item = "Volatile Discordian Rune",
          },
          ["VolatilePlanar(Spell Damage)"] = {
            aliases = {
              "Volatile Planar Rune",
            },
            ids = {
              150033,
            },
            item = "Volatile Planar Rune",
          },
        },
        Druid = {
          Bifold = {
            aliases = {
              "Bifold Focus of the Evil Eye",
            },
            ids = {
            },
            item = "Bifold Focus of the Evil Eye",
          },
          ["FocusAtrophy(Overall DoT damage)"] = {
            aliases = {
              "Focus Shard of Atrophy",
            },
            ids = {
              150048,
            },
            item = "Focus Shard of Atrophy",
            notes = "Not as strong as typed DoT-damage augs, but covers all DoT types. Useful for one broad boost while filling other slots with physical prowess or other augs.",
          },
          ["FocusDestruction(Overall Spell damage)"] = {
            aliases = {
              "Focus Shard of Destruction",
            },
            ids = {
              150047,
            },
            item = "Focus Shard of Destruction",
            notes = "Not as strong as typed spell-damage augs, but covers all spell types. Useful for one broad boost while filling other slots with physical prowess or other augs.",
          },
          Manastone = {
            aliases = {
              "Manastone",
            },
            ids = {
            },
            item = "Manastone",
          },
          SnakeFlute = {
            aliases = {
              "Snake Charmer's Flute",
            },
            ids = {
              40459,
            },
            item = "Snake Charmer's Flute",
          },
          ["VolatileDiscordian(Spell Damage)"] = {
            aliases = {
              "Volatile Discordian Rune",
            },
            ids = {
              150040,
            },
            item = "Volatile Discordian Rune",
          },
          ["VolatilePlanar(Spell Damage)"] = {
            aliases = {
              "Volatile Planar Rune",
            },
            ids = {
              150033,
            },
            item = "Volatile Planar Rune",
          },
        },
        Enchanter = {
          Bifold = {
            aliases = {
              "Bifold Focus of the Evil Eye",
            },
            ids = {
            },
            item = "Bifold Focus of the Evil Eye",
          },
          ["FocusAtrophy(Overall DoT damage)"] = {
            aliases = {
              "Focus Shard of Atrophy",
            },
            ids = {
              150048,
            },
            item = "Focus Shard of Atrophy",
            notes = "Not as strong as typed DoT-damage augs, but covers all DoT types. Useful for one broad boost while filling other slots with physical prowess or other augs.",
          },
          ["FocusDestruction(Overall Spell damage)"] = {
            aliases = {
              "Focus Shard of Destruction",
            },
            ids = {
              150047,
            },
            item = "Focus Shard of Destruction",
            notes = "Not as strong as typed spell-damage augs, but covers all spell types. Useful for one broad boost while filling other slots with physical prowess or other augs.",
          },
          Manastone = {
            aliases = {
              "Manastone",
            },
            ids = {
            },
            item = "Manastone",
          },
          SnakeFlute = {
            aliases = {
              "Snake Charmer's Flute",
            },
            ids = {
              40459,
            },
            item = "Snake Charmer's Flute",
          },
          ["VolatileDiscordian(Spell Damage)"] = {
            aliases = {
              "Volatile Discordian Rune",
            },
            ids = {
              150040,
            },
            item = "Volatile Discordian Rune",
          },
          ["VolatilePlanar(Spell Damage)"] = {
            aliases = {
              "Volatile Planar Rune",
            },
            ids = {
              150033,
            },
            item = "Volatile Planar Rune",
          },
        },
        Magician = {
          Bifold = {
            aliases = {
              "Bifold Focus of the Evil Eye",
            },
            ids = {
            },
            item = "Bifold Focus of the Evil Eye",
          },
          ["FocusAtrophy(Overall DoT damage)"] = {
            aliases = {
              "Focus Shard of Atrophy",
            },
            ids = {
              150048,
            },
            item = "Focus Shard of Atrophy",
            notes = "Not as strong as typed DoT-damage augs, but covers all DoT types. Useful for one broad boost while filling other slots with physical prowess or other augs.",
          },
          ["FocusDestruction(Overall Spell damage)"] = {
            aliases = {
              "Focus Shard of Destruction",
            },
            ids = {
              150047,
            },
            item = "Focus Shard of Destruction",
            notes = "Not as strong as typed spell-damage augs, but covers all spell types. Useful for one broad boost while filling other slots with physical prowess or other augs.",
          },
          Manastone = {
            aliases = {
              "Manastone",
            },
            ids = {
            },
            item = "Manastone",
          },
          SnakeFlute = {
            aliases = {
              "Snake Charmer's Flute",
            },
            ids = {
              40459,
            },
            item = "Snake Charmer's Flute",
          },
          ["VolatileDiscordian(Spell Damage)"] = {
            aliases = {
              "Volatile Discordian Rune",
            },
            ids = {
              150040,
            },
            item = "Volatile Discordian Rune",
          },
          ["VolatilePlanar(Spell Damage)"] = {
            aliases = {
              "Volatile Planar Rune",
            },
            ids = {
              150033,
            },
            item = "Volatile Planar Rune",
          },
        },
        Monk = {
          ["AdeptBlows(Tiger Claw)"] = {
            aliases = {
              "Focus Rune of Adept Blows",
            },
            ids = {
            },
            item = "Focus Rune of Adept Blows",
          },
          BloodDrinker = {
            aliases = {
              "Blood Drinker's Coating",
            },
            ids = {
            },
            item = "Blood Drinker's Coating",
          },
          BoarWhistle = {
            aliases = {
              "Boar Caller's Whistle",
            },
            ids = {
              150851,
            },
            item = "Boar Caller's Whistle",
          },
          ["DexterousStriking(Flying Kick)"] = {
            aliases = {
              "Focus Rune of Dexterous Striking",
            },
            ids = {
            },
            item = "Focus Rune of Dexterous Striking",
          },
          ["Dragorn(+ 10 to Wep Skills)"] = {
            aliases = {
              "Dragorn War Mask",
            },
            ids = {
            },
            item = "Dragorn War Mask",
          },
          ["EscalatingOnslaught(HStr)"] = {
            aliases = {
              "Planar Alloy of Escalating Onslaught",
            },
            ids = {
            },
            item = "Planar Alloy of Escalating Onslaught",
          },
          IdolScale = {
            aliases = {
              "Idol of the Scale",
            },
            ids = {
              150977,
            },
            item = "Idol of the Scale",
          },
          VenomVial = {
            aliases = {
              "Bottomless Venom Vial",
            },
            ids = {
            },
            item = "Bottomless Venom Vial",
          },
        },
        Necromancer = {
          Bifold = {
            aliases = {
              "Bifold Focus of the Evil Eye",
            },
            ids = {
            },
            item = "Bifold Focus of the Evil Eye",
          },
          ["FocusAtrophy(Overall DoT damage)"] = {
            aliases = {
              "Focus Shard of Atrophy",
            },
            ids = {
              150048,
            },
            item = "Focus Shard of Atrophy",
            notes = "Not as strong as typed DoT-damage augs, but covers all DoT types. Useful for one broad boost while filling other slots with physical prowess or other augs.",
          },
          ["FocusDestruction(Overall Spell damage)"] = {
            aliases = {
              "Focus Shard of Destruction",
            },
            ids = {
              150047,
            },
            item = "Focus Shard of Destruction",
            notes = "Not as strong as typed spell-damage augs, but covers all spell types. Useful for one broad boost while filling other slots with physical prowess or other augs.",
          },
          Manastone = {
            aliases = {
              "Manastone",
            },
            ids = {
            },
            item = "Manastone",
          },
          SnakeFlute = {
            aliases = {
              "Snake Charmer's Flute",
            },
            ids = {
              40459,
            },
            item = "Snake Charmer's Flute",
          },
          ["VolatileDiscordian(Spell Damage)"] = {
            aliases = {
              "Volatile Discordian Rune",
            },
            ids = {
              150040,
            },
            item = "Volatile Discordian Rune",
          },
          ["VolatilePlanar(Spell Damage)"] = {
            aliases = {
              "Volatile Planar Rune",
            },
            ids = {
              150033,
            },
            item = "Volatile Planar Rune",
          },
        },
        Paladin = {
          BloodDrinker = {
            aliases = {
              "Blood Drinker's Coating",
            },
            ids = {
            },
            item = "Blood Drinker's Coating",
          },
          BoarWhistle = {
            aliases = {
              "Boar Caller's Whistle",
            },
            ids = {
              150851,
            },
            item = "Boar Caller's Whistle",
          },
          ["BruteForce(Bash)"] = {
            aliases = {
              "Focus Rune of Brute Force",
            },
            ids = {
            },
            item = "Focus Rune of Brute Force",
          },
          ["Dragorn(+ 10 to Wep Skills)"] = {
            aliases = {
              "Dragorn War Mask",
            },
            ids = {
            },
            item = "Dragorn War Mask",
          },
          ["EscalatingOnslaught(HStr)"] = {
            aliases = {
              "Planar Alloy of Escalating Onslaught",
            },
            ids = {
            },
            item = "Planar Alloy of Escalating Onslaught",
          },
          ["FocusAtrophy(Overall DoT damage)"] = {
            aliases = {
              "Focus Shard of Atrophy",
            },
            ids = {
              150048,
            },
            item = "Focus Shard of Atrophy",
            notes = "Not as strong as typed DoT-damage augs, but covers all DoT types. Useful for one broad boost while filling other slots with physical prowess or other augs.",
          },
          ["FocusDestruction(Overall Spell damage)"] = {
            aliases = {
              "Focus Shard of Destruction",
            },
            ids = {
              150047,
            },
            item = "Focus Shard of Destruction",
            notes = "Not as strong as typed spell-damage augs, but covers all spell types. Useful for one broad boost while filling other slots with physical prowess or other augs.",
          },
          IdolScale = {
            aliases = {
              "Idol of the Scale",
            },
            ids = {
              150977,
            },
            item = "Idol of the Scale",
          },
          Manastone = {
            aliases = {
              "Manastone",
            },
            ids = {
            },
            item = "Manastone",
          },
          VenomVial = {
            aliases = {
              "Bottomless Venom Vial",
            },
            ids = {
            },
            item = "Bottomless Venom Vial",
          },
          ["VolatileDiscordian(Spell Damage)"] = {
            aliases = {
              "Volatile Discordian Rune",
            },
            ids = {
              150040,
            },
            item = "Volatile Discordian Rune",
          },
          ["VolatilePlanar(Spell Damage)"] = {
            aliases = {
              "Volatile Planar Rune",
            },
            ids = {
              150033,
            },
            item = "Volatile Planar Rune",
          },
        },
        Ranger = {
          Bifold = {
            aliases = {
              "Bifold Focus of the Evil Eye",
            },
            ids = {
            },
            item = "Bifold Focus of the Evil Eye",
          },
          BloodDrinker = {
            aliases = {
              "Blood Drinker's Coating",
            },
            ids = {
            },
            item = "Blood Drinker's Coating",
          },
          BoarWhistle = {
            aliases = {
              "Boar Caller's Whistle",
            },
            ids = {
              150851,
            },
            item = "Boar Caller's Whistle",
          },
          ["Dragorn(+ 10 to Wep Skills)"] = {
            aliases = {
              "Dragorn War Mask",
            },
            ids = {
            },
            item = "Dragorn War Mask",
          },
          ["EscalatingOnslaught(HStr)"] = {
            aliases = {
              "Planar Alloy of Escalating Onslaught",
            },
            ids = {
            },
            item = "Planar Alloy of Escalating Onslaught",
          },
          ["FocusAtrophy(Overall DoT damage)"] = {
            aliases = {
              "Focus Shard of Atrophy",
            },
            ids = {
              150048,
            },
            item = "Focus Shard of Atrophy",
            notes = "Not as strong as typed DoT-damage augs, but covers all DoT types. Useful for one broad boost while filling other slots with physical prowess or other augs.",
          },
          ["FocusDestruction(Overall Spell damage)"] = {
            aliases = {
              "Focus Shard of Destruction",
            },
            ids = {
              150047,
            },
            item = "Focus Shard of Destruction",
            notes = "Not as strong as typed spell-damage augs, but covers all spell types. Useful for one broad boost while filling other slots with physical prowess or other augs.",
          },
          Manastone = {
            aliases = {
              "Manastone",
            },
            ids = {
            },
            item = "Manastone",
          },
          ["Striking(Kick)"] = {
            aliases = {
              "Focus Rune of Striking",
            },
            ids = {
            },
            item = "Focus Rune of Striking",
          },
          VenomVial = {
            aliases = {
              "Bottomless Venom Vial",
            },
            ids = {
            },
            item = "Bottomless Venom Vial",
          },
          ["VolatileDiscordian(Spell Damage)"] = {
            aliases = {
              "Volatile Discordian Rune",
            },
            ids = {
              150040,
            },
            item = "Volatile Discordian Rune",
          },
          ["VolatilePlanar(Spell Damage)"] = {
            aliases = {
              "Volatile Planar Rune",
            },
            ids = {
              150033,
            },
            item = "Volatile Planar Rune",
          },
        },
        Rogue = {
          BloodDrinker = {
            aliases = {
              "Blood Drinker's Coating",
            },
            ids = {
            },
            item = "Blood Drinker's Coating",
          },
          BoarWhistle = {
            aliases = {
              "Boar Caller's Whistle",
            },
            ids = {
              150851,
            },
            item = "Boar Caller's Whistle",
          },
          ["Dragorn(+ 10 to Wep Skills)"] = {
            aliases = {
              "Dragorn War Mask",
            },
            ids = {
            },
            item = "Dragorn War Mask",
          },
          ["EscalatingOnslaught(HStr)"] = {
            aliases = {
              "Planar Alloy of Escalating Onslaught",
            },
            ids = {
            },
            item = "Planar Alloy of Escalating Onslaught",
          },
          ["FoulPlay(Backstab)"] = {
            aliases = {
              "Focus Rune of Foul Play",
            },
            ids = {
            },
            item = "Focus Rune of Foul Play",
          },
          IdolScale = {
            aliases = {
              "Idol of the Scale",
            },
            ids = {
              150977,
            },
            item = "Idol of the Scale",
          },
        },
        ["Shadow Knight"] = {
          BloodDrinker = {
            aliases = {
              "Blood Drinker's Coating",
            },
            ids = {
            },
            item = "Blood Drinker's Coating",
          },
          BoarWhistle = {
            aliases = {
              "Boar Caller's Whistle",
            },
            ids = {
              150851,
            },
            item = "Boar Caller's Whistle",
          },
          ["BruteForce(Bash)"] = {
            aliases = {
              "Focus Rune of Brute Force",
            },
            ids = {
            },
            item = "Focus Rune of Brute Force",
          },
          ["Dragorn(+ 10 to Wep Skills)"] = {
            aliases = {
              "Dragorn War Mask",
            },
            ids = {
            },
            item = "Dragorn War Mask",
          },
          ["EscalatingOnslaught(HStr)"] = {
            aliases = {
              "Planar Alloy of Escalating Onslaught",
            },
            ids = {
            },
            item = "Planar Alloy of Escalating Onslaught",
          },
          ["FocusAtrophy(Overall DoT damage)"] = {
            aliases = {
              "Focus Shard of Atrophy",
            },
            ids = {
              150048,
            },
            item = "Focus Shard of Atrophy",
            notes = "Not as strong as typed DoT-damage augs, but covers all DoT types. Useful for one broad boost while filling other slots with physical prowess or other augs.",
          },
          ["FocusDestruction(Overall Spell damage)"] = {
            aliases = {
              "Focus Shard of Destruction",
            },
            ids = {
              150047,
            },
            item = "Focus Shard of Destruction",
            notes = "Not as strong as typed spell-damage augs, but covers all spell types. Useful for one broad boost while filling other slots with physical prowess or other augs.",
          },
          IdolScale = {
            aliases = {
              "Idol of the Scale",
            },
            ids = {
              150977,
            },
            item = "Idol of the Scale",
          },
          Manastone = {
            aliases = {
              "Manastone",
            },
            ids = {
            },
            item = "Manastone",
          },
          VenomVial = {
            aliases = {
              "Bottomless Venom Vial",
            },
            ids = {
            },
            item = "Bottomless Venom Vial",
          },
          ["VolatileDiscordian(Spell Damage)"] = {
            aliases = {
              "Volatile Discordian Rune",
            },
            ids = {
              150040,
            },
            item = "Volatile Discordian Rune",
          },
          ["VolatilePlanar(Spell Damage)"] = {
            aliases = {
              "Volatile Planar Rune",
            },
            ids = {
              150033,
            },
            item = "Volatile Planar Rune",
          },
        },
        Shaman = {
          Bifold = {
            aliases = {
              "Bifold Focus of the Evil Eye",
            },
            ids = {
            },
            item = "Bifold Focus of the Evil Eye",
          },
          ["FocusAtrophy(Overall DoT damage)"] = {
            aliases = {
              "Focus Shard of Atrophy",
            },
            ids = {
              150048,
            },
            item = "Focus Shard of Atrophy",
            notes = "Not as strong as typed DoT-damage augs, but covers all DoT types. Useful for one broad boost while filling other slots with physical prowess or other augs.",
          },
          ["FocusDestruction(Overall Spell damage)"] = {
            aliases = {
              "Focus Shard of Destruction",
            },
            ids = {
              150047,
            },
            item = "Focus Shard of Destruction",
            notes = "Not as strong as typed spell-damage augs, but covers all spell types. Useful for one broad boost while filling other slots with physical prowess or other augs.",
          },
          Manastone = {
            aliases = {
              "Manastone",
            },
            ids = {
            },
            item = "Manastone",
          },
          SnakeFlute = {
            aliases = {
              "Snake Charmer's Flute",
            },
            ids = {
              40459,
            },
            item = "Snake Charmer's Flute",
          },
          ["VolatileDiscordian(Spell Damage)"] = {
            aliases = {
              "Volatile Discordian Rune",
            },
            ids = {
              150040,
            },
            item = "Volatile Discordian Rune",
          },
          ["VolatilePlanar(Spell Damage)"] = {
            aliases = {
              "Volatile Planar Rune",
            },
            ids = {
              150033,
            },
            item = "Volatile Planar Rune",
          },
        },
        Warrior = {
          BloodDrinker = {
            aliases = {
              "Blood Drinker's Coating",
            },
            ids = {
            },
            item = "Blood Drinker's Coating",
          },
          BoarWhistle = {
            aliases = {
              "Boar Caller's Whistle",
            },
            ids = {
              150851,
            },
            item = "Boar Caller's Whistle",
          },
          ["BruteForce(Bash)"] = {
            aliases = {
              "Focus Rune of Brute Force",
            },
            ids = {
            },
            item = "Focus Rune of Brute Force",
          },
          ["Dragorn(+ 10 to Wep Skills)"] = {
            aliases = {
              "Dragorn War Mask",
            },
            ids = {
            },
            item = "Dragorn War Mask",
          },
          ["EscalatingOnslaught(HStr)"] = {
            aliases = {
              "Planar Alloy of Escalating Onslaught",
            },
            ids = {
            },
            item = "Planar Alloy of Escalating Onslaught",
          },
          IdolScale = {
            aliases = {
              "Idol of the Scale",
            },
            ids = {
              150977,
            },
            item = "Idol of the Scale",
          },
          ["Striking(Kick)"] = {
            aliases = {
              "Focus Rune of Striking",
            },
            ids = {
            },
            item = "Focus Rune of Striking",
          },
          VenomVial = {
            aliases = {
              "Bottomless Venom Vial",
            },
            ids = {
            },
            item = "Bottomless Venom Vial",
          },
        },
        Wizard = {
          Bifold = {
            aliases = {
              "Bifold Focus of the Evil Eye",
            },
            ids = {
            },
            item = "Bifold Focus of the Evil Eye",
          },
          ["FocusAtrophy(Overall DoT damage)"] = {
            aliases = {
              "Focus Shard of Atrophy",
            },
            ids = {
              150048,
            },
            item = "Focus Shard of Atrophy",
            notes = "Not as strong as typed DoT-damage augs, but covers all DoT types. Useful for one broad boost while filling other slots with physical prowess or other augs.",
          },
          ["FocusDestruction(Overall Spell damage)"] = {
            aliases = {
              "Focus Shard of Destruction",
            },
            ids = {
              150047,
            },
            item = "Focus Shard of Destruction",
            notes = "Not as strong as typed spell-damage augs, but covers all spell types. Useful for one broad boost while filling other slots with physical prowess or other augs.",
          },
          Manastone = {
            aliases = {
              "Manastone",
            },
            ids = {
            },
            item = "Manastone",
          },
          SnakeFlute = {
            aliases = {
              "Snake Charmer's Flute",
            },
            ids = {
              40459,
            },
            item = "Snake Charmer's Flute",
          },
          ["VolatileDiscordian(Spell Damage)"] = {
            aliases = {
              "Volatile Discordian Rune",
            },
            ids = {
              150040,
            },
            item = "Volatile Discordian Rune",
          },
          ["VolatilePlanar(Spell Damage)"] = {
            aliases = {
              "Volatile Planar Rune",
            },
            ids = {
              150033,
            },
            item = "Volatile Planar Rune",
          },
        },
      },
      group = "Other Checklists",
      id = "vendoritems",
      name = "Vendor Items",
      show_base = {
      },
      template = {
        ["Annihilation(Spell Damage)"] = {
          aliases = {
            "Focus Shard of Aggregate Annihilation",
          },
          ids = {
          },
          item = "Focus Shard of Aggregate Annihilation",
        },
        ["DarkArachnids(Does not stack with other Dodge)"] = {
          aliases = {
            "Visage of the Dark Arachnids",
          },
          ids = {
          },
          item = "Visage of the Dark Arachnids",
        },
        ["EnchantedJewel(Shielding)"] = {
          aliases = {
            "Enchanted Jewel of Shielding",
          },
          ids = {
          },
          item = "Enchanted Jewel of Shielding",
        },
        ["Evasion(Avoidance)"] = {
          aliases = {
            "Discordian Rune of Evasion",
          },
          ids = {
          },
          item = "Discordian Rune of Evasion",
        },
        ["Lucky Copper/Silver"] = {
          aliases = {
            "Lucky Copper",
            "Lucky Silver",
          },
          ids = {
            151042,
            151043,
          },
          item = "Lucky Copper",
        },
        ["Lucky Grass"] = {
          aliases = {
            "Lucky Grass Trinket",
          },
          ids = {
            151044,
          },
          item = "Lucky Grass Trinket",
        },
        ["Lucky Horseshoe"] = {
          aliases = {
            "Luckiest of Horseshoes",
          },
          ids = {
            150978,
          },
          item = "Luckiest of Horseshoes",
        },
        Mount = {
          aliases = {
            "Whirligig Flyer Control Device",
            "Ornate Flying Carpet",
          },
          ids = {
            39632,
            39635,
          },
          item = "Whirligig Flyer Control Device",
        },
        ["MysticalAegis(DoT Shield)"] = {
          aliases = {
            "Discordian Orb of Mystical Aegis",
          },
          ids = {
          },
          item = "Discordian Orb of Mystical Aegis",
        },
        ["MysticalAegis(Spell Shield)"] = {
          aliases = {
            "Planar Orb of Mystical Aegis",
          },
          ids = {
          },
          item = "Planar Orb of Mystical Aegis",
        },
        Oculous = {
          aliases = {
            "Illuminious Oculus",
          },
          ids = {
            150980,
          },
          item = "Illuminious Oculus",
        },
        ["Precision(Accuracy)"] = {
          aliases = {
            "Discordian Alloy of Precision",
          },
          ids = {
          },
          item = "Discordian Alloy of Precision",
        },
        ["Prowess(Offense)"] = {
          aliases = {
            "Planar Alloy of Prowess",
          },
          ids = {
          },
          item = "Planar Alloy of Prowess",
        },
        ["Rapidity(Attack)"] = {
          aliases = {
            "Discordian Alloy of Rapidity",
          },
          ids = {
          },
          item = "Discordian Alloy of Rapidity",
        },
        ["Tenacity(Defense)"] = {
          aliases = {
            "Discordian Alloy of Tenacity",
          },
          ids = {
          },
          item = "Discordian Alloy of Tenacity",
        },
        ["War Bear Saddle(Or any other AC Mount)"] = {
          aliases = {
            "War Bear Saddle",
          },
          ids = {
            39635,
          },
          item = "War Bear Saddle",
        },
      },
      visible = {
      },
    },
  },
  schema = "turbogear_bis_canonical_v1",
  source_owner = "TurboGear",
  zone_map = {
    anguish = {
      group = "Raid Best In Slot",
      index = 1,
    },
    dreadspire = {
      group = "Raid Best In Slot",
      index = 3,
    },
    fungal = {
      group = "Raid Best In Slot",
      index = 5,
    },
    sebilis = {
      group = "Raid Best In Slot",
      index = 4,
    },
    thevoida = {
      group = "Raid Best In Slot",
      index = 3,
    },
    unrest = {
      group = "Raid Best In Slot",
      index = 2,
    },
    veksar = {
      group = "Raid Best In Slot",
      index = 6,
    },
  },
}
