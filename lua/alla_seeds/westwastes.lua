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
    westwastes = {
      zone = 'westwastes',
      named = {
        {
          schema = 'TurboMobsAllaSeedNpc',
          npc_id = 120084,
          id = 120084,
          name = 'Klandicar',
          source_url = 'https://lazaruseq.com/alla/npcs/120084',
          timer_source = 'lazarus_alla',
          points = {
            { x = -233.0, y = -2775.0, z = -281.0, chance = 100.0, respawn_seconds = 3, source_url = 'https://lazaruseq.com/alla/npcs/120084', timer_source = 'lazarus_alla', ph_names = {  } },
          },
        },
        {
          schema = 'TurboMobsAllaSeedNpc',
          npc_id = 120112,
          id = 120112,
          name = 'Scout Pirri',
          source_url = 'https://lazaruseq.com/alla/npcs/120112',
          timer_source = 'lazarus_alla',
          points = {
            { x = 2307.0, y = 889.0, z = -22.0, chance = 100.0, respawn_seconds = 7200, source_url = 'https://lazaruseq.com/alla/npcs/120132', timer_source = 'lazarus_alla', ph_names = {  } },
          },
        },
        {
          schema = 'TurboMobsAllaSeedNpc',
          npc_id = 120129,
          id = 120129,
          name = 'a banished efreeti',
          source_url = 'https://lazaruseq.com/alla/npcs/120129',
          timer_source = 'lazarus_alla',
          points = {
            { x = 4014.0, y = -1010.0, z = -34.0, chance = 100.0, respawn_seconds = 3600, source_url = 'https://lazaruseq.com/alla/npcs/120129', timer_source = 'lazarus_alla', ph_names = {  } },
          },
        },
      },
    },
  },
}
