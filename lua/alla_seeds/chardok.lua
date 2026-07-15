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
    chardok = {
      zone = 'chardok',
      named = {
        {
          schema = 'TurboMobsAllaSeedNpc',
          npc_id = 103200,
          id = 103200,
          name = 'Grand Lorekeeper Kino Shai`din',
          source_url = 'https://lazaruseq.com/alla/npcs/103200',
          timer_source = 'lazarus_alla',
          points = {
            { x = 975.0, y = -819.0, z = -214.0, chance = 10.0, respawn_seconds = 640, source_url = 'https://lazaruseq.com/alla/npcs/103200', timer_source = 'lazarus_alla', ph_names = { 'an apprentice lorekeeper', 'Loremaster Piza`tak' } },
          },
        },
        {
          schema = 'TurboMobsAllaSeedNpc',
          npc_id = 103220,
          id = 103220,
          name = 'Interrogator Gi`mok',
          source_url = 'https://lazaruseq.com/alla/npcs/103220',
          timer_source = 'lazarus_alla',
          points = {
            { x = -364.0, y = -527.0, z = -134.0, chance = 20.0, respawn_seconds = 640, source_url = 'https://lazaruseq.com/alla/npcs/103220', timer_source = 'lazarus_alla', ph_names = { 'an Imperial Inspector' } },
          },
        },
        {
          schema = 'TurboMobsAllaSeedNpc',
          npc_id = 103056,
          id = 103056,
          name = 'Overking Bathezid',
          source_url = 'https://lazaruseq.com/alla/npcs/103056',
          timer_source = 'lazarus_alla',
          points = {
            { x = 960.0, y = -839.0, z = -272.0, chance = 100.0, respawn_seconds = 7200, source_url = 'https://lazaruseq.com/alla/npcs/103056', timer_source = 'lazarus_alla', ph_names = {  } },
          },
        },
      },
    },
  },
}
