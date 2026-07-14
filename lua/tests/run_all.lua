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
    "turbogear_needs_index_test.lua",
    "turbogear_runtime_guard_test.lua",
    "turbogear_snapshot_delta_test.lua",
    "turbogear_spells_index_test.lua",
    "turbogear_store_test.lua",
    "turbogear_store_save_test.lua",
    "turbogear_store_sqlite_test.lua",
    "turbogear_store_sqlite_integration_test.lua",
    "turbogear_bis_catalog_lazy_test.lua",
    "turbogear_announcer_budget_test.lua",
    "turbogear_engine_dispatch_test.lua",
    "turbogear_suggestions_stats_test.lua",
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
