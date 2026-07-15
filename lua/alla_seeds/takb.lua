return {
  _meta = {
    format = 'TurboMobsAllaSeed',
    schema_version = 1,
    generator = 'tools/laz_alla_seed.py',
    generated_at = '2026-06-02',
    source = 'Project Lazarus Alla',
    report = {
      records = 2,
      points = 2,
      records_without_points = 0,
      duplicate_points = 0,
      points_missing_timers = 0,
    },
  },
  zones = {
    takb = {
      zone = 'takb',
      named = {
        {
          schema = 'TurboMobsAllaSeedNpc',
          npc_id = 236032,
          id = 236032,
          name = 'Amethyst Summoning',
          source_url = 'https://lazaruseq.com/alla/npcs/236032',
          timer_source = 'lazarus_alla',
          points = {
            { x = 459.0, y = -176.0, z = 14.0, chance = 100.0, respawn_seconds = 14400, source_url = 'https://lazaruseq.com/alla/npcs/236032', timer_source = 'lazarus_alla', ph_names = {  } },
          },
        },
        {
          schema = 'TurboMobsAllaSeedNpc',
          npc_id = 236026,
          id = 236026,
          name = 'Panicked Summoning',
          source_url = 'https://lazaruseq.com/alla/npcs/236026',
          timer_source = 'lazarus_alla',
          points = {
            { x = 607.0, y = -107.0, z = 13.0, chance = 100.0, respawn_seconds = 14400, source_url = 'https://lazaruseq.com/alla/npcs/236026', timer_source = 'lazarus_alla', ph_names = {  } },
          },
        },
      },
    },
  },
}
