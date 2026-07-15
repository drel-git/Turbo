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
    stonebrunt = {
      zone = 'stonebrunt',
      named = {
        {
          schema = 'TurboMobsAllaSeedNpc',
          npc_id = 100226,
          id = 100226,
          name = 'a dire panda',
          source_url = 'https://lazaruseq.com/alla/npcs/100226',
          timer_source = 'lazarus_alla',
          points = {
            { x = -1745.0, y = -556.0, z = 628.0, chance = 100.0, respawn_seconds = 7200, source_url = 'https://lazaruseq.com/alla/npcs/100226', timer_source = 'lazarus_alla', ph_names = {  } },
          },
        },
        {
          schema = 'TurboMobsAllaSeedNpc',
          npc_id = 100227,
          id = 100227,
          name = 'a mountain dragon',
          source_url = 'https://lazaruseq.com/alla/npcs/100227',
          timer_source = 'lazarus_alla',
          points = {
          },
        },
      },
    },
  },
}
