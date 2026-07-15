return {
  _meta = {
    format = 'TurboMobsAllaSeed',
    schema_version = 1,
    generator = 'tools/laz_alla_seed.py',
    generated_at = '2026-06-02',
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
    kurn = {
      zone = 'kurn',
      named = {
        {
          schema = 'TurboMobsAllaSeedNpc',
          npc_id = 97075,
          id = 97075,
          name = 'Bargynn',
          source_url = 'https://lazaruseq.com/alla/npcs/97075',
          timer_source = 'lazarus_alla',
          points = {
            { x = 264.0, y = -115.0, z = -122.0, chance = 34.0, respawn_seconds = 1200, source_url = 'https://lazaruseq.com/alla/npcs/97075', timer_source = 'lazarus_alla', ph_names = { 'Burynai Sapper' } },
          },
        },
        {
          schema = 'TurboMobsAllaSeedNpc',
          npc_id = 97074,
          id = 97074,
          name = 'Crackling Bones',
          source_url = 'https://lazaruseq.com/alla/npcs/97074',
          timer_source = 'lazarus_alla',
          points = {
            { x = 80.0, y = -31.0, z = -39.0, chance = 25.0, respawn_seconds = 1200, source_url = 'https://lazaruseq.com/alla/npcs/97074', timer_source = 'lazarus_alla', ph_names = { 'lesser charbone skeleton' } },
          },
        },
        {
          schema = 'TurboMobsAllaSeedNpc',
          npc_id = 97009,
          id = 97009,
          name = 'an odd mole',
          source_url = 'https://lazaruseq.com/alla/npcs/97009',
          timer_source = 'lazarus_alla',
          points = {
            { x = -58.0, y = 15.0, z = 127.0, chance = 100.0, respawn_seconds = 1200, source_url = 'https://lazaruseq.com/alla/npcs/97009', timer_source = 'lazarus_alla', ph_names = {  } },
          },
        },
      },
    },
  },
}
