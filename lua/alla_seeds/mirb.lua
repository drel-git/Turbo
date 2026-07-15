return {
  _meta = {
    format = 'TurboMobsAllaSeed',
    schema_version = 1,
    generator = 'tools/laz_alla_seed.py',
    generated_at = '2026-06-02',
    source = 'Project Lazarus Alla',
    report = {
      records = 2,
      points = 1,
      records_without_points = 1,
      duplicate_points = 0,
      points_missing_timers = 0,
    },
  },
  zones = {
    mirb = {
      zone = 'mirb',
      named = {
        {
          schema = 'TurboMobsAllaSeedNpc',
          npc_id = 237797,
          id = 237797,
          name = 'Laskuth the Colossus',
          source_url = 'https://lazaruseq.com/alla/npcs/237797',
          timer_source = 'lazarus_alla',
          points = {
          },
        },
        {
          schema = 'TurboMobsAllaSeedNpc',
          npc_id = 237760,
          id = 237760,
          name = 'Marrow the Broken',
          source_url = 'https://lazaruseq.com/alla/npcs/237760',
          timer_source = 'lazarus_alla',
          points = {
            { x = 23.0, y = -319.0, z = 58.0, chance = 100.0, respawn_seconds = 10800, source_url = 'https://lazaruseq.com/alla/npcs/237760', timer_source = 'lazarus_alla', ph_names = {  } },
          },
        },
      },
    },
  },
}
