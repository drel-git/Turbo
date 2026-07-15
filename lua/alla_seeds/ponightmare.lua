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
    ponightmare = {
      zone = 'ponightmare',
      named = {
        {
          schema = 'TurboMobsAllaSeedNpc',
          npc_id = 204034,
          id = 204034,
          name = 'Terror Matriarch',
          source_url = 'https://lazaruseq.com/alla/npcs/204034',
          timer_source = 'lazarus_alla',
          points = {
            { x = -516.0, y = -1281.0, z = 181.0, chance = 100.0, respawn_seconds = 1800, source_url = 'https://lazaruseq.com/alla/npcs/204034', timer_source = 'lazarus_alla', ph_names = {  } },
          },
        },
        {
          schema = 'TurboMobsAllaSeedNpc',
          npc_id = 204054,
          id = 204054,
          name = 'Tyrant of Nightmare',
          source_url = 'https://lazaruseq.com/alla/npcs/204054',
          timer_source = 'lazarus_alla',
          points = {
            { x = -1846.0, y = 195.0, z = 126.0, chance = 100.0, respawn_seconds = 1800, source_url = 'https://lazaruseq.com/alla/npcs/204054', timer_source = 'lazarus_alla', ph_names = {  } },
          },
        },
      },
    },
  },
}
