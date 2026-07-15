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
    jaggedpine = {
      zone = 'jaggedpine',
      named = {
        {
          schema = 'TurboMobsAllaSeedNpc',
          npc_id = 181223,
          id = 181223,
          name = 'a dire kodiak',
          source_url = 'https://lazaruseq.com/alla/npcs/181223',
          timer_source = 'lazarus_alla',
          points = {
            { x = -1010.0, y = -1634.0, z = -18.0, chance = 100.0, respawn_seconds = 7200, source_url = 'https://lazaruseq.com/alla/npcs/181223', timer_source = 'lazarus_alla', ph_names = {  } },
          },
        },
        {
          schema = 'TurboMobsAllaSeedNpc',
          npc_id = 181224,
          id = 181224,
          name = 'a forest dragon',
          source_url = 'https://lazaruseq.com/alla/npcs/181224',
          timer_source = 'lazarus_alla',
          points = {
          },
        },
      },
    },
  },
}
