return {
  _meta = {
    format = 'TurboMobsAllaSeed',
    schema_version = 1,
    generator = 'tools/laz_alla_seed.py',
    generated_at = '2026-06-16',
    source = 'Project Lazarus Alla',
    report = {
      records = 3,
      points = 3,
      records_without_points = 0,
      duplicate_points = 0,
      points_missing_timers = 0,
    },
  },
  zones = {
    fearplane = {
      zone = 'fearplane',
      named = {
        {
          schema = 'TurboMobsAllaSeedNpc',
          npc_id = 72000,
          id = 72000,
          name = 'Dread',
          source_url = 'https://lazaruseq.com/alla/npcs/72000',
          timer_source = 'lazarus_alla',
          points = {
            { x = -1201.0, y = -635.0, z = 148.0, chance = 100.0, respawn_seconds = 3, source_url = 'https://lazaruseq.com/alla/npcs/72000', timer_source = 'lazarus_alla', ph_names = {  } },
          },
        },
        {
          schema = 'TurboMobsAllaSeedNpc',
          npc_id = 72004,
          id = 72004,
          name = 'Fright',
          source_url = 'https://lazaruseq.com/alla/npcs/72004',
          timer_source = 'lazarus_alla',
          points = {
            { x = -358.0, y = -636.0, z = 135.0, chance = 100.0, respawn_seconds = 3, source_url = 'https://lazaruseq.com/alla/npcs/72004', timer_source = 'lazarus_alla', ph_names = {  } },
          },
        },
        {
          schema = 'TurboMobsAllaSeedNpc',
          npc_id = 72002,
          id = 72002,
          name = 'Terror',
          source_url = 'https://lazaruseq.com/alla/npcs/72002',
          timer_source = 'lazarus_alla',
          points = {
            { x = -365.0, y = 199.0, z = 125.0, chance = 100.0, respawn_seconds = 3, source_url = 'https://lazaruseq.com/alla/npcs/72002', timer_source = 'lazarus_alla', ph_names = {  } },
          },
        },
      },
    },
  },
}
