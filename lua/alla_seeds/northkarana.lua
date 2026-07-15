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
    northkarana = {
      zone = 'northkarana',
      named = {
        {
          schema = 'TurboMobsAllaSeedNpc',
          npc_id = 13129,
          id = 13129,
          name = 'a dire griffon',
          source_url = 'https://lazaruseq.com/alla/npcs/13129',
          timer_source = 'lazarus_alla',
          points = {
            { x = 1149.0, y = 1303.0, z = 0.0, chance = 100.0, respawn_seconds = 7200, source_url = 'https://lazaruseq.com/alla/npcs/13129', timer_source = 'lazarus_alla', ph_names = {  } },
          },
        },
        {
          schema = 'TurboMobsAllaSeedNpc',
          npc_id = 13130,
          id = 13130,
          name = 'a plains dragon',
          source_url = 'https://lazaruseq.com/alla/npcs/13130',
          timer_source = 'lazarus_alla',
          points = {
          },
        },
      },
    },
  },
}
