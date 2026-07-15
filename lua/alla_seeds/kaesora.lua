return {
  _meta = {
    format = 'TurboMobsAllaSeed',
    schema_version = 1,
    generator = 'tools/laz_alla_seed.py',
    generated_at = '2026-06-16',
    source = 'Project Lazarus Alla',
    report = {
      records = 4,
      points = 3,
      records_without_points = 1,
      duplicate_points = 0,
      points_missing_timers = 0,
    },
  },
  zones = {
    kaesora = {
      zone = 'kaesora',
      named = {
        {
          schema = 'TurboMobsAllaSeedNpc',
          npc_id = 88073,
          id = 88073,
          name = 'Xalgoz',
          source_url = 'https://lazaruseq.com/alla/npcs/88073',
          timer_source = 'lazarus_alla',
          points = {
            { x = 560.0, y = -112.0, z = -292.0, chance = 50.0, respawn_seconds = 640, source_url = 'https://lazaruseq.com/alla/npcs/88073', timer_source = 'lazarus_alla', ph_names = { 'guardian of Xalgoz' } },
          },
        },
        {
          schema = 'TurboMobsAllaSeedNpc',
          npc_id = 88087,
          id = 88087,
          name = 'enraged spectral librarian',
          source_url = 'https://lazaruseq.com/alla/npcs/88087',
          timer_source = 'lazarus_alla',
          points = {
          },
        },
        {
          schema = 'TurboMobsAllaSeedNpc',
          npc_id = 88061,
          id = 88061,
          name = 'spectral librarian',
          source_url = 'https://lazaruseq.com/alla/npcs/88061',
          timer_source = 'lazarus_alla',
          points = {
            { x = -415.0, y = 116.0, z = -99.0, chance = 20.0, respawn_seconds = 640, source_url = 'https://lazaruseq.com/alla/npcs/88061', timer_source = 'lazarus_alla', ph_names = { 'spectral guardian' } },
          },
        },
        {
          schema = 'TurboMobsAllaSeedNpc',
          npc_id = 88055,
          id = 88055,
          name = 'tortured librarian',
          source_url = 'https://lazaruseq.com/alla/npcs/88055',
          timer_source = 'lazarus_alla',
          points = {
            { x = -395.0, y = 115.0, z = -98.0, chance = 20.0, respawn_seconds = 640, source_url = 'https://lazaruseq.com/alla/npcs/88055', timer_source = 'lazarus_alla', ph_names = { 'spectral guardian' } },
          },
        },
      },
    },
  },
}
