-- Run from repo root:  luajit lua/tests/turbomobs_settings_bool_test.lua
-- Guards the settings-load bug where `data.x ~= nil and data.x or default`
-- turned a saved `false` back into a default `true` on every restart
-- (tester report: "Sound on respawn" kept turning itself back on).
-- Static + extracted-function checks only: TurboMobs.lua needs mq/ImGui to load.

local path = (arg and arg[1]) or "lua/TurboMobs.lua"
local fh = assert(io.open(path, "rb"), "cannot open " .. path)
local src = fh:read("*a"):gsub("\r\n", "\n")
fh:close()

local passed, failed = 0, 0
local function check(ok, msg)
    if ok then passed = passed + 1 else failed = failed + 1; print("  FAIL: " .. msg) end
end

-- 1. Body of applySettingsTable
local s = src:find("local function applySettingsTable%(data%)")
local e = s and src:find("\nlocal function loadSettings%(%)", s)
check(s ~= nil and e ~= nil, "applySettingsTable / loadSettings markers found")
local body = (s and e) and src:sub(s, e) or ""

-- 2. No boolean load uses the and/or idiom that drops false
local bad = {}
for key in body:gmatch("data%.([%w_]+) ~= nil and data%.%1 or") do bad[#bad + 1] = key end
check(#bad == 0, "and/or boolean idiom still used for: " .. table.concat(bad, ", "))

-- 3. Every setting that defaults to true is loaded in a false-preserving way
local default_true = {
    "respawnSound", "alertEcho", "spawnPopup", "showAlertPopup", "enabled",
    "compactMode", "compatVarsEnabled", "spawnMasterCompat", "doubleClickNav",
    "learnAllSpawns", "autoPauseSafeZones", "namedOrPHOnly", "watchShowAll",
    "watchCurrentZoneOnly", "showIdColumn", "showTypeColumn", "showBodyColumn",
    "showDirectionArrows", "sortAscending",
}
for _, key in ipairs(default_true) do
    local safe = body:find("pickBool%(data%." .. key .. "[,%)]")
        or body:find("data%." .. key .. " ~= false")
        or body:find("data%." .. key .. " == true")
    check(safe ~= nil, key .. " loads with a false-preserving check")
end

-- 4. pickBool itself behaves correctly (extracted and executed in isolation)
local fn_src = src:match("(ux%.pickBool = function%b()%s.-\nend)")
check(fn_src ~= nil, "ux.pickBool definition found")
if fn_src then
    local env = { ux = {} }
    local chunk = assert(loadstring and loadstring(fn_src) or load(fn_src))
    if setfenv then setfenv(chunk, env) end
    chunk()
    local pick = env.ux.pickBool
    check(pick(false, true) == false, "saved false beats default true")
    check(pick(true, false) == true, "saved true beats default false")
    check(pick(nil, true) == true, "missing key keeps default true")
    check(pick(nil, false) == false, "missing key keeps default false")
    check(pick(nil, pick(false, true)) == false, "legacy alertBeep=false fallback preserved")
    check(pick("yes", true) == false, "non-boolean saved value is not treated as true")
end

print(string.format("turbomobs settings bool: %d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
