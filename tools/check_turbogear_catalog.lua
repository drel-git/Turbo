-- Run the safe TurboGear BiS catalog developer pipeline.
--
-- Default mode is read-only/temp-only:
--   luajit tools/check_turbogear_catalog.lua
--
-- Controlled runtime write mode:
--   luajit tools/check_turbogear_catalog.lua --write-runtime

local args = arg or {}
local write_runtime = false

for _, a in ipairs(args) do
    if a == "--write-runtime" then
        write_runtime = true
    elseif a == "--help" or a == "-h" then
        io.write("usage: luajit tools/check_turbogear_catalog.lua [--write-runtime]\n")
        os.exit(0)
    else
        io.stderr:write("unknown argument: " .. tostring(a) .. "\n")
        os.exit(2)
    end
end

local SOURCE = "catalog_source/bis/catalog.lua"
local RUNTIME_CATALOG = "lua/turbogear/catalogs/lazbis.lua"
local RUNTIME_ANNOUNCE = "lua/turbogear/generated/builtin_announce_index.lua"
local TMP = "tmp/phase2_pipeline"
local TEMP_CATALOG_A = TMP .. "/catalog-a.lua"
local TEMP_CATALOG_B = TMP .. "/catalog-b.lua"
local TEMP_RUNTIME_ROOT = TMP .. "/runtime"
local TEMP_RUNTIME_CATALOG = TEMP_RUNTIME_ROOT .. "/catalogs/lazbis.lua"
local TEMP_ANNOUNCE_A = TMP .. "/announce-a.lua"
local TEMP_ANNOUNCE_B = TMP .. "/announce-b.lua"
local FIXED_GENERATED_AT = "2026-01-01T00:00:00Z"

local stages = {}

local function slash(path)
    return tostring(path or ""):gsub("\\", "/")
end

local function q(path)
    return '"' .. tostring(path):gsub('"', '\\"') .. '"'
end

local function read_file(path)
    local f, err = io.open(path, "rb")
    if not f then return nil, err end
    local s = f:read("*a")
    f:close()
    return s
end

local function write_file(path, data)
    local f, err = io.open(path, "wb")
    if not f then error("cannot write " .. tostring(path) .. ": " .. tostring(err)) end
    f:write(data)
    f:close()
end

local function copy_file(src, dst)
    local data, err = read_file(src)
    if not data then error("cannot read " .. tostring(src) .. ": " .. tostring(err)) end
    write_file(dst, data)
end

local function same_file(a, b)
    local aa = assert(read_file(a))
    local bb = assert(read_file(b))
    return aa == bb
end

local function mkdirs()
    os.execute('cmd /c if not exist "tmp\\phase2_pipeline" mkdir "tmp\\phase2_pipeline" >NUL 2>NUL')
    os.execute('cmd /c if not exist "tmp\\phase2_pipeline\\runtime\\catalogs" mkdir "tmp\\phase2_pipeline\\runtime\\catalogs" >NUL 2>NUL')
    os.execute('cmd /c if not exist "tmp\\phase2_pipeline\\rollback" mkdir "tmp\\phase2_pipeline\\rollback" >NUL 2>NUL')
end

local function command_status(ok, _, code)
    if ok == true then return 0 end
    if type(ok) == "number" then return ok end
    return tonumber(code) or 1
end

local function run_capture(cmd)
    local f = io.popen(cmd .. " 2>&1")
    local output = f and f:read("*a") or ""
    local ok, why, code = f:close()
    return command_status(ok, why, code), output
end

local function stage(name, fn)
    local rec = { name = name, ok = false, detail = "" }
    stages[#stages + 1] = rec
    local ok, err = pcall(fn)
    if ok then
        rec.ok = true
        rec.detail = err or ""
        return true
    end
    rec.detail = tostring(err)
    return false
end

local function run_stage_command(label, cmd)
    local code, output = run_capture(cmd)
    if code ~= 0 then
        error(label .. " failed with exit " .. tostring(code) .. "\n" .. output)
    end
    return output
end

local function load_table(path)
    local chunk, err = loadfile(path)
    if type(chunk) ~= "function" then error("cannot load " .. tostring(path) .. ": " .. tostring(err)) end
    local ok, value = pcall(chunk)
    if not ok then error("cannot execute " .. tostring(path) .. ": " .. tostring(value)) end
    if type(value) ~= "table" then error("file did not return table: " .. tostring(path)) end
    return value
end

local function compare_tables(a, b, path, diffs)
    if path == "generated_at" then return end
    if type(a) ~= type(b) then
        diffs[#diffs + 1] = path .. ": type " .. type(a) .. " != " .. type(b)
        return
    end
    if type(a) ~= "table" then
        if a ~= b then diffs[#diffs + 1] = path .. ": " .. tostring(a) .. " != " .. tostring(b) end
        return
    end
    local seen = {}
    for k in pairs(a) do
        seen[k] = true
        local child = path == "" and tostring(k) or (path .. "." .. tostring(k))
        compare_tables(a[k], b[k], child, diffs)
        if #diffs >= 20 then return end
    end
    for k in pairs(b) do
        if not seen[k] then
            local child = path == "" and tostring(k) or (path .. "." .. tostring(k))
            diffs[#diffs + 1] = child .. ": missing in runtime"
            if #diffs >= 20 then return end
        end
    end
end

local function count_don_virtual_275(payload)
    local n = 0
    for _, loc in ipairs(payload.locators or {}) do
        if loc.list_id == "don" and loc.slot == "2.75" and loc.source_kind == "don_virtual" then n = n + 1 end
    end
    return n
end

local function count_don_scales_misc4(payload)
    local n = 0
    for _, loc in ipairs(payload.locators or {}) do
        if loc.list_id == "don" and loc.slot == "Scales" and loc.source_slot == "Misc4" then n = n + 1 end
    end
    return n
end

local function count_custom_user_locators(payload)
    local n = 0
    for _, loc in ipairs(payload.locators or {}) do
        local sk = tostring(loc.source_kind or ""):lower()
        if sk:find("custom", 1, true) or sk:find("user", 1, true) then n = n + 1 end
    end
    return n
end

local function check_announce_semantics(runtime_path, temp_path)
    local runtime = load_table(runtime_path)
    local temp = load_table(temp_path)
    local diffs = {}
    compare_tables(runtime, temp, "", diffs)
    if #diffs > 0 then error("announce semantic differences:\n" .. table.concat(diffs, "\n")) end
    if count_don_virtual_275(temp) ~= 16 then error("DoN 2.75 don_virtual locator count mismatch") end
    if count_don_scales_misc4(temp) ~= 16 then error("DoN Scales Misc4 locator count mismatch") end
    if count_custom_user_locators(temp) ~= 0 then error("custom/user locators present") end
    return temp
end

local function catalog_counts(catalog)
    local counts = {
        groups = #(catalog.groups or {}),
        lists = 0,
        categories = 0,
        category_slot_refs = 0,
        zone_map_entries = 0,
    }
    for _ in pairs(catalog.zone_map or {}) do counts.zone_map_entries = counts.zone_map_entries + 1 end
    for _, list in pairs(catalog.lists or {}) do
        counts.lists = counts.lists + 1
        for _, cat in ipairs(list.categories or {}) do
            counts.categories = counts.categories + 1
            for _ in ipairs(cat.slots or {}) do counts.category_slot_refs = counts.category_slot_refs + 1 end
        end
    end
    return counts
end

mkdirs()

local summary = {
    catalog_hash = "",
    locators = "",
    keys = "",
}

local ok = true
ok = stage("source validation", function()
    run_stage_command("source validation", "luajit tools\\verify_turbogear_catalog.lua --source " .. q(SOURCE))
end) and ok

ok = stage("catalog build", function()
    run_stage_command("catalog build A", "luajit tools\\build_turbogear_catalog.lua --source " .. q(SOURCE) .. " --out " .. q(TEMP_CATALOG_A))
    copy_file(TEMP_CATALOG_A, TEMP_RUNTIME_CATALOG)
    local catalog = load_table(TEMP_CATALOG_A)
    summary.catalog_hash = tostring(catalog.content_hash or "")
end) and ok

ok = stage("catalog determinism", function()
    run_stage_command("catalog build B", "luajit tools\\build_turbogear_catalog.lua --source " .. q(SOURCE) .. " --out " .. q(TEMP_CATALOG_B))
    if not same_file(TEMP_CATALOG_A, TEMP_CATALOG_B) then error("catalog A/B outputs are not byte-identical") end
end) and ok

ok = stage("catalog semantics", function()
    local code, output = run_capture("luajit tools\\compare_turbogear_catalog_semantics.lua " .. q(RUNTIME_CATALOG) .. " " .. q(TEMP_CATALOG_A))
    if code ~= 0 and not write_runtime then
        error("catalog semantics failed with exit " .. tostring(code) .. "\n" .. output)
    end
    if code ~= 0 then
        return "runtime catalog drift accepted because --write-runtime was requested"
    end
end) and ok

ok = stage("announce generation", function()
    run_stage_command("announce generation A", "luajit lua\\tools\\generate_turbogear_builtin_announce_index.lua --catalog-root=" .. q(TEMP_RUNTIME_ROOT) .. " --out=" .. q(TEMP_ANNOUNCE_A) .. " --generated-at=" .. FIXED_GENERATED_AT)
end) and ok

ok = stage("announce determinism", function()
    run_stage_command("announce generation B", "luajit lua\\tools\\generate_turbogear_builtin_announce_index.lua --catalog-root=" .. q(TEMP_RUNTIME_ROOT) .. " --out=" .. q(TEMP_ANNOUNCE_B) .. " --generated-at=" .. FIXED_GENERATED_AT)
    if not same_file(TEMP_ANNOUNCE_A, TEMP_ANNOUNCE_B) then error("announce A/B outputs are not byte-identical") end
end) and ok

ok = stage("announce semantics", function()
    local ok_sem, payload_or_err = pcall(check_announce_semantics, RUNTIME_ANNOUNCE, TEMP_ANNOUNCE_A)
    if not ok_sem and not write_runtime then error(payload_or_err) end
    if ok_sem then
        summary.locators = tostring(payload_or_err.locator_count or "")
        summary.keys = tostring(payload_or_err.key_count or "")
    else
        local temp = load_table(TEMP_ANNOUNCE_A)
        summary.locators = tostring(temp.locator_count or "")
        summary.keys = tostring(temp.key_count or "")
        return "runtime announce drift accepted because --write-runtime was requested"
    end
end) and ok

if write_runtime and ok then
    ok = stage("runtime write", function()
        io.write("Runtime write requested. Will write:\n")
        io.write("  " .. RUNTIME_CATALOG .. "\n")
        io.write("  " .. RUNTIME_ANNOUNCE .. "\n")
        copy_file(RUNTIME_CATALOG, TMP .. "/rollback/lazbis.lua")
        copy_file(RUNTIME_ANNOUNCE, TMP .. "/rollback/builtin_announce_index.lua")
        copy_file(TEMP_CATALOG_A, RUNTIME_CATALOG)
        run_stage_command("runtime announce generation", "luajit lua\\tools\\generate_turbogear_builtin_announce_index.lua")
        local runtime_catalog = load_table(RUNTIME_CATALOG)
        local counts = catalog_counts(runtime_catalog)
        if counts.groups ~= 3 or counts.lists ~= 16 or counts.categories ~= 86 or counts.zone_map_entries <= 0 then
            error("runtime catalog structural counts changed unexpectedly")
        end
    end) and ok
end

io.write("\nTurboGear BiS pipeline: " .. (ok and "PASS" or "FAIL") .. "\n\n")
local width = 27
for _, rec in ipairs(stages) do
    io.write(string.format("%-" .. width .. "s %s\n", rec.name .. " ............", rec.ok and "PASS" or "FAIL"))
    if not rec.ok then
        io.write("\n" .. rec.detail .. "\n")
        break
    end
end
if ok then
    io.write("\n")
    io.write("catalog hash: " .. tostring(summary.catalog_hash) .. "\n")
    io.write("locators: " .. tostring(summary.locators) .. "\n")
    io.write("keys: " .. tostring(summary.keys) .. "\n")
end

os.exit(ok and 0 or 1)
