return {
  _meta = {
    format = 'TurboMobsAllaSeed',
    schema_version = 1,
    generator = 'tools/laz_alla_seed.py',
    generated_at = '2026-06-02',
    source = 'Project Lazarus Alla',
    report = {
      records = 3,
      points = 2,
      records_without_points = 1,
      duplicate_points = 0,
      points_missing_timers = 0,
    },
  },
  zones = {
    wakening = {
      zone = 'wakening',
      named = {
        {
          schema = 'TurboMobsAllaSeedNpc',
          npc_id = 119182,
          id = 119182,
          name = 'Cristoc Bonethug',
          source_url = 'https://lazaruseq.com/alla/npcs/119182',
          timer_source = 'lazarus_alla',
          points = {
          },
        },
        {
          schema = 'TurboMobsAllaSeedNpc',
          npc_id = 119180,
          id = 119180,
          name = 'a giant herald',
          source_url = 'https://lazaruseq.com/alla/npcs/119180',
          timer_source = 'lazarus_alla',
          points = {
            { x = -1209.0, y = -64.0, z = -178.0, chance = 100.0, respawn_seconds = 1800, source_url = 'https://lazaruseq.com/alla/npcs/119180', timer_source = 'lazarus_alla', ph_names = {  } },
          },
        },
        {
          schema = 'TurboMobsAllaSeedNpc',
          npc_id = 119181,
          id = 119181,
          name = 'a giant messenger',
          source_url = 'https://lazaruseq.com/alla/npcs/119181',
          timer_source = 'lazarus_alla',
          points = {
            { x = -3164.0, y = 265.0, z = -175.0, chance = 100.0, respawn_seconds = 1800, source_url = 'https://lazaruseq.com/alla/npcs/119181', timer_source = 'lazarus_alla', ph_names = {  } },
          },
        },
      },
    },
  },
}
