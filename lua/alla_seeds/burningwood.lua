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
      duplicate_points = 1,
      points_missing_timers = 0,
    },
  },
  zones = {
    burningwood = {
      zone = 'burningwood',
      named = {
        {
          schema = 'TurboMobsAllaSeedNpc',
          npc_id = 87070,
          id = 87070,
          name = 'Gylton',
          source_url = 'https://lazaruseq.com/alla/npcs/87070',
          timer_source = 'lazarus_alla',
          points = {
            { x = -2852.0, y = 3475.0, z = -170.0, chance = 11.0, respawn_seconds = 172, source_url = 'https://lazaruseq.com/alla/npcs/87070', timer_source = 'lazarus_alla', ph_names = { 'greater plague skeleton', 'greater war boned skeleton', 'a Sarnak champion', 'a Sarnak extremist', 'a forest giant ancient', 'a moldering gorilla', 'Entalon' } },
          },
        },
        {
          schema = 'TurboMobsAllaSeedNpc',
          npc_id = 87034,
          id = 87034,
          name = 'Nezekezena',
          source_url = 'https://lazaruseq.com/alla/npcs/87034',
          timer_source = 'lazarus_alla',
          points = {
            { x = -2546.0, y = -469.0, z = -361.0, chance = 10.0, respawn_seconds = 80, source_url = 'https://lazaruseq.com/alla/npcs/87034', timer_source = 'lazarus_alla', ph_names = { 'a Sarnak zealot', 'a forest giant verdant', 'wurm', 'greater war boned skeleton', 'a scoriae hornet', 'a tatterback gorilla', 'a forest giant ancient', 'a moldering gorilla', 'Phurzikon' } },
          },
        },
        {
          schema = 'TurboMobsAllaSeedNpc',
          npc_id = 87148,
          id = 87148,
          name = 'Phurzikon',
          source_url = 'https://lazaruseq.com/alla/npcs/87148',
          timer_source = 'lazarus_alla',
          points = {
            { x = -2546.0, y = -469.0, z = -361.0, chance = 10.0, respawn_seconds = 80, source_url = 'https://lazaruseq.com/alla/npcs/87148', timer_source = 'lazarus_alla', ph_names = { 'a Sarnak zealot', 'a forest giant verdant', 'wurm', 'greater war boned skeleton', 'Nezekezena', 'a scoriae hornet', 'a tatterback gorilla', 'a forest giant ancient', 'a moldering gorilla' } },
          },
        },
      },
    },
  },
}
