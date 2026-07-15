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
    draniksscar = {
      zone = 'draniksscar',
      named = {
        {
          schema = 'TurboMobsAllaSeedNpc',
          npc_id = 302063,
          id = 302063,
          name = 'Fang',
          source_url = 'https://lazaruseq.com/alla/npcs/302063',
          timer_source = 'lazarus_alla',
          points = {
            { x = -1131.0, y = 1411.0, z = -52.0, chance = 33.0, respawn_seconds = 960, source_url = 'https://lazaruseq.com/alla/npcs/302063', timer_source = 'lazarus_alla', ph_names = { 'an ukun', 'an ukun fleshhound' } },
          },
        },
        {
          schema = 'TurboMobsAllaSeedNpc',
          npc_id = 302072,
          id = 302072,
          name = 'Ukun Gutfeaster',
          source_url = 'https://lazaruseq.com/alla/npcs/302072',
          timer_source = 'lazarus_alla',
          points = {
            { x = -1579.0, y = -991.0, z = 234.0, chance = 20.0, respawn_seconds = 960, source_url = 'https://lazaruseq.com/alla/npcs/302072', timer_source = 'lazarus_alla', ph_names = { 'an ukun' } },
          },
        },
        {
          schema = 'TurboMobsAllaSeedNpc',
          npc_id = 302010,
          id = 302010,
          name = 'Ukun Slavehunter',
          source_url = 'https://lazaruseq.com/alla/npcs/302010',
          timer_source = 'lazarus_alla',
          points = {
            { x = 769.0, y = -796.0, z = 440.0, chance = 34.0, respawn_seconds = 960, source_url = 'https://lazaruseq.com/alla/npcs/302010', timer_source = 'lazarus_alla', ph_names = { 'an ukun', 'an ukun deathhound' } },
          },
        },
      },
    },
  },
}
