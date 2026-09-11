-- TurboGear test runner.
-- Run from the repo root, e.g.:
--     luajit lua/tests/run_all.lua
--     lua5.4 lua/tests/run_all.lua
--     lua/tests/run_all.lua lua5.4          (override the interpreter as arg[1])
--
-- Runs every turbogear *_test.lua in its OWN interpreter process (the test files
-- call os.exit, so they cannot share one process) and reports a combined result.
-- Exit code is nonzero if any test file fails, so CI / pre-commit hooks can gate
-- on it.

local sep = package.config:sub(1, 1)         -- "\\" on Windows, "/" elsewhere
local function join(...)
    return table.concat({ ... }, sep)
end

-- Interpreter: explicit arg[1], else the one running us (arg[-1]), else luajit.
local interp = (arg and arg[1]) or (arg and arg[-1]) or "luajit"

local tests = {
    "turbogear_announce_rules_test.lua",
    "turbogear_announcer_parser_test.lua",
    "turbogear_linked_items_history_test.lua",
    "turbogear_announce_link_need_test.lua",
    "turbogear_go_loot_test.lua",
    "turbogear_needs_index_test.lua",
    "turbogear_jonas_hand_progression_test.lua",
    "turbogear_needs_index_tick_test.lua",
    "turbogear_item_index_test.lua",
    "turbogear_characters_test.lua",
    "turbogear_runtime_guard_test.lua",
    "turbogear_config_bgready_test.lua",
    "turbogear_degradation_test.lua",
    "turbogear_snapshot_delta_test.lua",
    "turbogear_snapshot_carry_forward_test.lua",
    "turbogear_snapshot_metadata_publish_test.lua",
    "turbogear_spells_index_test.lua",
    "turbogear_don_spells_test.lua",
    "turbogear_don_spells_lean_test.lua",
    "turbogear_don_scribe_push_test.lua",
    "turbogear_research_spells_lean_test.lua",
    "turbogear_don_shadow_finals_test.lua",
    "turbogear_spell_known_test.lua",
    "turbogear_spell_cache_test.lua",
    "turbogear_spells_refresh_test.lua",
    "turbogear_spells_startup_test.lua",
    "turbogear_rich_inventory_test.lua",
    "turbogear_inventory_probe_test.lua",
    "turbogear_settings_debounce_test.lua",
    "turbo_ui_native_move_test.lua",
    "turbogear_store_test.lua",
    "turbogear_store_save_test.lua",
    "turbogear_store_content_flush_test.lua",
    "turbogear_store_persist_encoder_test.lua",
    "turbogear_keep_qty_board_test.lua",
    "turbogear_store_sqlite_test.lua",
    "turbogear_sqlite_packageman_test.lua",
    "turbogear_store_sqlite_integration_test.lua",
    "turbogear_bis_catalog_lazy_test.lua",
    "turbogear_bis_augmented_live_test.lua",
    "turbogear_bis_roster_col_w_test.lua",
    "turbogear_tattered_sack_test.lua",
    "turbogear_ownership_index_test.lua",
    "turbogear_local_needs_shadow_test.lua",
    "turbogear_index_warm_policy_test.lua",
    "turbogear_core_diet_a_test.lua",
    "turbogear_core_diet_a_tg_defer_test.lua",
    "turbogear_elapsed_deadlines_test.lua",
    "turbogear_type12_ownership_test.lua",
    "turbogear_lockouts_ref_test.lua",
    "turbogear_lockouts_preserve_test.lua",
    "turbogear_lockouts_dz_tlo_test.lua",
    "turbogear_lockout_watch_test.lua",
    "turbogear_store_lockout_dirty_test.lua",
    "turbogear_don_lockouts_test.lua",
    "turbogear_don_state_test.lua",
    "turbogear_don_persist_test.lua",
    "turbogear_don_track_test.lua",
    "turbogear_don_propagation_test.lua",
    "turbogear_don_matrix_test.lua",
    "turbogear_don_ui_prefs_test.lua",
    "turbogear_announcer_budget_test.lua",
    "turbogear_engine_dispatch_test.lua",
    "turbogear_suggestions_stats_test.lua",
    "turbogear_worn_refresh_test.lua",
    "turbogear_inventory_watch_worn_poll_test.lua",
    "turbogear_inventory_watch_worn_poll_policy_test.lua",
    "turbo_loot_doctor_test.lua",
    "turbo_bot_pause_test.lua",
    "turbo_update_check_spawn_test.lua",
    "turbomobs_logic_test.lua",
}

-- os.execute returns differ across Lua versions:
--   5.1: a numeric exit code (0 = success)
--   5.2+: ok(boolean), "exit"|"signal", code
local function run(cmd)
    local a, b, c = os.execute(cmd)
    if type(a) == "number" then return a == 0 end
    if a == true and (c == nil or c == 0) then return true end
    return false
end

local passed, failed = 0, {}
for _, name in ipairs(tests) do
    local path = join("lua", "tests", name)
    io.write(("-> %s ... "):format(name))
    io.flush()
    local ok = run(('%s "%s"'):format(interp, path))
    if ok then
        passed = passed + 1
        print("PASS")
    else
        failed[#failed + 1] = name
        print("FAIL")
    end
end

print("")
if #failed == 0 then
    print(("ALL %d TEST FILES PASSED"):format(#tests))
    os.exit(0)
else
    print(("%d PASSED, %d FAILED:"):format(passed, #failed))
    for _, n in ipairs(failed) do print("   FAIL " .. n) end
    os.exit(1)
end
