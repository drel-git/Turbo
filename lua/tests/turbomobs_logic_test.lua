--[[
    turbomobs_logic_test.lua
    ---------------------------------------------------------------------------
    Unit tests for turbomobs_logic.lua.

    Run from your toolchain exactly like the compile checks:
        luajit lua\tests\turbomobs_logic_test.lua
    (or from anywhere; the script locates the module relative to itself.)

    Strategy: for every extracted function we keep a byte-identical REFERENCE
    implementation here and assert module == reference across a battery of
    inputs (including the corpse/parenthetical/seed edge cases from the tester
    diagnostics). If a future edit to the module changes behavior, this fails
    loudly instead of shipping a silent regression.

    Exit code is non-zero on failure when run standalone, so it slots into the
    same scripted gate as `luajit -b`.
]]

-- Locate the module relative to this test file, so cwd doesn't matter.
do
    local src = debug and debug.getinfo and debug.getinfo(1, 'S').source or ''
    local dir = src:sub(1, 1) == '@' and src:sub(2):gsub('\\', '/'):match('^(.+)/[^/]+$') or nil
    if dir then
        package.path = dir .. '/?.lua;' .. dir .. '/../?.lua;' .. package.path
    end
end

local M = require('turbomobs_logic')

-- ---------------------------------------------------------------------------
-- Reference implementations (must mirror the ORIGINAL TurboMobs.lua inline
-- versions exactly). The point of the test is M == ref.
-- ---------------------------------------------------------------------------
local function trim(s) return (tostring(s or '')):gsub('^%s+', ''):gsub('%s+$', '') end

local ref = {}
function ref.roundedCoord(value)
    value = tonumber(value) or 0
    return math.floor((value * 10) + 0.5) / 10
end
function ref.pointKeyFromCoords(x, y)
    if x == nil or y == nil then return nil end
    return string.format('loc:%.1f,%.1f', ref.roundedCoord(y), ref.roundedCoord(x))
end
function ref.spawnPointKey(row)
    if not row or row.x == nil or row.y == nil then return nil end
    return string.format('loc:%.1f,%.1f', ref.roundedCoord(row.y), ref.roundedCoord(row.x))
end
function ref.coordsFromPointKey(pointKey)
    local y, x = tostring(pointKey or ''):match('^loc:([%-%.%d]+),([%-%.%d]+)$')
    return tonumber(x), tonumber(y)
end
function ref.rowDistanceFromLoc(row, x, y)
    if not row or row.x == nil or row.y == nil or x == nil or y == nil then return nil end
    local dx = (tonumber(row.x) or 0) - (tonumber(x) or 0)
    local dy = (tonumber(row.y) or 0) - (tonumber(y) or 0)
    return math.sqrt(dx * dx + dy * dy)
end
function ref.normalizeWatchTargetName(name)
    name = trim(tostring(name or ''):lower())
    if name == '' then return name end
    name = name:gsub("%s*'s corpse%s*$", '')
    name = name:gsub('%s* corpse%s*$', '')
    name = name:gsub('%s*%([^)]+%)%s*$', '')
    return trim(name)
end
function ref.seedNameKey(value)
    local text = trim(tostring(value or '')):lower():gsub('`', "'")
    text = text:gsub('^the fabled%s+', '')
    text = text:gsub("[^%w']+", ' ')
    text = trim(text:gsub('%s+', ' '))
    return text
end

-- ---------------------------------------------------------------------------
-- Tiny assert framework
-- ---------------------------------------------------------------------------
local passed, failed = 0, 0
local failLines = {}
local function check(cond, label)
    if cond then
        passed = passed + 1
    else
        failed = failed + 1
        failLines[#failLines + 1] = label
        print('FAIL: ' .. tostring(label))
    end
end
local function eq(a, b) return a == b end
local function approx(a, b)
    if a == nil or b == nil then return a == b end
    return math.abs(a - b) < 1e-9
end

-- ---------------------------------------------------------------------------
-- Geometry + naming (step 1)
-- ---------------------------------------------------------------------------
for _, v in ipairs({0, 1, -1, 0.04, 0.05, 0.06, -0.05, 4751.04, 4751.06, -233.05, 39.6, 4407.6}) do
    check(approx(M.roundedCoord(v), ref.roundedCoord(v)), 'roundedCoord(' .. tostring(v) .. ')')
end
check(approx(M.roundedCoord(nil), 0), 'roundedCoord(nil) == 0')
check(approx(M.roundedCoord('12.34'), 12.3), "roundedCoord('12.34') == 12.3")

local rows = {
    { x = 4407.6, y = 39.6 }, { x = 4751.0, y = -233.0 }, { x = 887.0, y = -1051.0 },
    { x = 146.9, y = -231.1 }, { x = 4684, y = -940 }, { x = 0, y = 0 },
    { x = -0.04, y = 0.06 }, { x = nil, y = 5 }, { x = 5, y = nil },
}
for i, r in ipairs(rows) do
    check(eq(M.spawnPointKey(r), ref.spawnPointKey(r)), 'spawnPointKey row#' .. i)
    check(eq(M.pointKeyFromCoords(r.x, r.y), ref.pointKeyFromCoords(r.x, r.y)), 'pointKeyFromCoords row#' .. i)
end
check(M.spawnPointKey(nil) == nil, 'spawnPointKey(nil) == nil')
check(M.spawnPointKey({ x = nil, y = nil }) == nil, 'spawnPointKey(empty) == nil')
check(M.spawnPointKey({ x = 4407.6, y = 39.6 }) == 'loc:39.6,4407.6', 'spawnPointKey explicit Y-first')
do
    local key = M.spawnPointKey({ x = 4751.0, y = -233.0 })
    local x, y = M.coordsFromPointKey(key)
    check(approx(x, 4751.0) and approx(y, -233.0), 'coordsFromPointKey round trip')
    check(M.pointKeyFromCoords(x, y) == key, 'pointKeyFromCoords round trip stable')
end
check(select('#', M.coordsFromPointKey('garbage')) == 2, 'coordsFromPointKey malformed returns 2 nils')
do local x, y = M.coordsFromPointKey('garbage'); check(x == nil and y == nil, 'coordsFromPointKey malformed nils') end

check(approx(M.rowDistanceFromLoc({ x = 0, y = 0 }, 3, 4), 5), 'distance 3-4-5')
check(M.rowDistanceFromLoc(nil, 1, 1) == nil, 'distance nil row')
check(M.rowDistanceFromLoc({ x = 1, y = 1 }, nil, 1) == nil, 'distance nil x')
check(approx(M.rowDistanceFromLoc({ x = 887.0, y = -1051.0 }, 146.9, -231.1),
    ref.rowDistanceFromLoc({ x = 887.0, y = -1051.0 }, 146.9, -231.1)), 'distance vs ref (Scruffy case)')

check(M.withinLoc({ x = 0, y = 0 }, 3, 4, 5) == true, 'withinLoc on boundary inclusive')
check(M.withinLoc({ x = 0, y = 0 }, 3, 4, 4.99) == false, 'withinLoc outside')
check(M.withinLoc({ x = 0, y = 0 }, 3, 4, nil) == false, 'withinLoc nil radius false')
check(M.withinLoc(nil, 3, 4, 5) == false, 'withinLoc nil row false')

local nameCases = {
    "a froglok gaz knight's corpse",
    'a froglok gaz squire',
    "a decaying skeleton's corpse's corpse",
    'Hierophant Prime Grekal (hunter)',
    'a giant rat (87)',
    'Tovax Vmar',
    '   Mixed CASE Name  ',
    '',
    nil,
    "Lord Nagafen's corpse (level 60)",
}
for i, n in ipairs(nameCases) do
    check(eq(M.normalizeWatchTargetName(n), ref.normalizeWatchTargetName(n)), 'normalizeWatchTargetName #' .. i .. ' (' .. tostring(n) .. ')')
end
check(M.normalizeWatchTargetName("a froglok gaz knight's corpse") == 'a froglok gaz knight', 'normalize corpse explicit')
check(M.normalizeWatchTargetName('Hierophant Prime Grekal (hunter)') == 'hierophant prime grekal', 'normalize parenthetical explicit')

local seedCases = {
    'The Fabled Lord Nagafen', 'the fabled  Vox', 'Pyzjn`Varsoon', 'a giant rat',
    "Tovax Vmar", '  spaced   out  name ', 'Name-With-Dashes!!!', '', nil, 'CaSeD NaMe',
}
for i, n in ipairs(seedCases) do
    check(eq(M.seedNameKey(n), ref.seedNameKey(n)), 'seedNameKey #' .. i .. ' (' .. tostring(n) .. ')')
end
check(M.seedNameKey('The Fabled Lord Nagafen') == 'lord nagafen', 'seedNameKey fabled strip explicit')
check(M.seedNameKey('Pyzjn`Varsoon') == "pyzjn'varsoon", 'seedNameKey backtick explicit')

-- ---------------------------------------------------------------------------
-- Watch state derivation (step 2): module vs byte-identical reference of the
-- ORIGINAL ux.watchDisplayStatus + helpers. Proves the refactor preserves the
-- displayed status/color across a cross-product of watch/evidence shapes.
-- ---------------------------------------------------------------------------
local refw = {}
function refw.hasPoint(watch) return watch and tostring(watch.lastSpawnPointKey or '') ~= '' end
function refw.hasKnownPhNames(watch)
    if type(watch) ~= 'table' then return false end
    if type(watch.phNames) == 'table' and #watch.phNames > 0 then return true end
    if type(watch.seedPhNames) == 'table' and #watch.seedPhNames > 0 then return true end
    return false
end
function refw.hasSessionTimer(watch)
    if type(watch) ~= 'table' then return false end
    if (tonumber(watch.despawnedAt or 0) or 0) > 0 then return true end
    if (tonumber(watch.expectedRespawnAt or 0) or 0) > 0 then return true end
    return false
end
function refw.hasLiveEvidence(watch, ev)
    if watch.isUp or ev.hasRow then return true end
    if ev.hasOffAnchorNamed then return true end
    if ev.hasPlaceholderRow then return true end
    if ev.hasRoamingPh then return true end
    if watch.pointOccupied == true and watch.occupantConfirmedAtAnchor == true
        and (tonumber(watch.occupantSpawnId or 0) or 0) > 0 and watch.isUp ~= true then return true end
    return false
end
function refw.timerExpired(watch, ev)
    if not refw.hasSessionTimer(watch) then return false end
    local eta = tonumber(watch.expectedRespawnAt or 0) or 0
    if eta > 0 then return eta <= ev.now end
    local d = tonumber(watch.despawnedAt or 0) or 0
    if d <= 0 then return false end
    local respawn = ev.respawnSeconds
    if type(respawn) == 'function' then respawn = respawn() end
    respawn = tonumber(respawn) or 0
    return respawn > 0 and (d + respawn) <= ev.now
end
function refw.isCampCheckable(watch, ev)
    if not watch then return false end
    if refw.hasLiveEvidence(watch, ev) then return false end
    if not refw.hasKnownPhNames(watch) then return false end
    if not refw.hasSessionTimer(watch) then return false end
    return refw.timerExpired(watch, ev)
end
-- Mirror of the ORIGINAL ux.watchDisplayStatus (returns display, color).
function refw.displayStatus(watch, ev)
    if ev.inCurrentZone == false then return 'Off-zone', 'muted' end
    if (ev.baselineReady ~= true or ev.zoneEntryPending == true) and watch.initialResolved ~= true then
        return '...', 'muted'
    end
    if watch.isUp or ev.hasRow then return 'N UP', 'alertUp'
    elseif ev.hasOffAnchorNamed then return 'N UP', 'alertUp'
    elseif ev.hasPlaceholderRow or ev.hasRoamingPh then return 'PH UP', 'etaSoon' end
    if refw.isCampCheckable(watch, ev) then return 'Camp', 'etaSoon' end
    local eta = tonumber(watch.expectedRespawnAt or 0) or 0
    local overdue = eta > 0 and eta <= ev.now
    if overdue and refw.hasSessionTimer(watch) then return 'Down', 'muted' end
    if eta > 0 and refw.hasSessionTimer(watch) then return 'Down', 'alertDown' end
    if refw.hasPoint(watch) then return 'Down', 'muted' end
    return 'WATCH', 'muted'
end

local NOW = 100000
local watchVariants = {
    named_isUp        = { isUp = true },
    plain             = {},
    resolved          = { initialResolved = true },
    point_only        = { lastSpawnPointKey = 'loc:1.0,1.0' },
    timer_future      = { expectedRespawnAt = NOW + 120, lastSpawnPointKey = 'loc:1.0,1.0' },
    timer_overdue     = { expectedRespawnAt = NOW - 30, lastSpawnPointKey = 'loc:1.0,1.0' },
    despawn_only      = { despawnedAt = NOW - 5, lastSpawnPointKey = 'loc:1.0,1.0' },
    camp_ready        = { despawnedAt = NOW - 9000, phNames = { 'a froglok' }, lastSpawnPointKey = 'loc:1.0,1.0' },
    camp_notyet       = { despawnedAt = NOW - 5,    phNames = { 'a froglok' }, lastSpawnPointKey = 'loc:1.0,1.0' },
    camp_seedph       = { despawnedAt = NOW - 9000, seedPhNames = { 'a froglok' }, lastSpawnPointKey = 'loc:1.0,1.0' },
    anchor_occupant   = { pointOccupied = true, occupantConfirmedAtAnchor = true, occupantSpawnId = 7, lastSpawnPointKey = 'loc:1.0,1.0' },
    manual            = {},
}
local evVariants = {
    ready        = { baselineReady = true },
    scanning     = { baselineReady = false },
    scan_pending = { baselineReady = true, zoneEntryPending = true },
    hasRow       = { baselineReady = true, hasRow = true },
    hasPH        = { baselineReady = true, hasPlaceholderRow = true },
    offAnchorN   = { baselineReady = true, hasOffAnchorNamed = true },
    roamingPH    = { baselineReady = true, hasRoamingPh = true },
    offzone      = { baselineReady = true, inCurrentZone = false },
}
local respawnVariants = { small = 60, large = 1e9, thunkSmall = function() return 60 end }

local validStates = { UP = true, DOWN = true, DUE = true, UNKNOWN = true }
for wn, w in pairs(watchVariants) do
    for en, e in pairs(evVariants) do
        for rn, rs in pairs(respawnVariants) do
            local ev = { now = NOW, respawnSeconds = rs }
            for k, v in pairs(e) do ev[k] = v end
            local tag = wn .. '/' .. en .. '/' .. rn
            local rd, rc = refw.displayStatus(w, ev)
            local res = M.computeWatchState(w, ev)
            check(res.display == rd, 'computeWatchState display ' .. tag .. ' (' .. tostring(res.display) .. ' vs ' .. tostring(rd) .. ')')
            check(res.color == rc, 'computeWatchState color ' .. tag)
            check(validStates[res.state] == true, 'computeWatchState valid enum ' .. tag .. ' (' .. tostring(res.state) .. ')')
            check(M.watchHasLiveEvidence(w, ev) == refw.hasLiveEvidence(w, ev), 'hasLiveEvidence ' .. tag)
            check(M.watchIsCampCheckable(w, ev) == refw.isCampCheckable(w, ev), 'isCampCheckable ' .. tag)
            check(M.watchSessionTimerExpired(w, ev) == refw.timerExpired(w, ev), 'timerExpired ' .. tag)
            check((M.watchHasSessionTimer(w) and true or false) == (refw.hasSessionTimer(w) and true or false), 'hasSessionTimer ' .. tag)
            check((M.watchHasPoint(w) and true or false) == (refw.hasPoint(w) and true or false), 'hasPoint ' .. tag)
            check((M.watchHasKnownPhNames(w) and true or false) == (refw.hasKnownPhNames(w) and true or false), 'hasKnownPhNames ' .. tag)
        end
    end
end

-- Explicit enum locks for the documented scenarios (the new step-2 capability).
local function st(w, ev) return M.computeWatchState(w, ev).state end
local READY = { baselineReady = true, now = NOW, respawnSeconds = 60 }
check(st({ isUp = true }, READY) == 'UP', 'enum: named isUp -> UP')
check(st({}, { baselineReady = true, hasRow = true, now = NOW }) == 'UP', 'enum: live named row -> UP')
check(st({}, { baselineReady = true, hasPlaceholderRow = true, now = NOW }) == 'UP', 'enum: PH up -> UP')
check(M.computeWatchState({}, { baselineReady = true, hasPlaceholderRow = true, now = NOW }).kind == 'placeholder', 'enum: PH kind=placeholder')
check(st({ despawnedAt = NOW - 9000, phNames = { 'x' }, lastSpawnPointKey = 'loc:1.0,1.0' }, { baselineReady = true, hasOffAnchorNamed = true, now = NOW, respawnSeconds = 60 }) == 'UP', 'enum: off-anchor named live -> UP')
check(M.computeWatchState({}, { baselineReady = true, hasOffAnchorNamed = true, now = NOW }).kind == 'named_off_anchor', 'enum: off-anchor named kind=named_off_anchor')
check(st({ despawnedAt = NOW - 9000, phNames = { 'x' }, lastSpawnPointKey = 'loc:1.0,1.0' }, { baselineReady = true, hasRoamingPh = true, now = NOW, respawnSeconds = 60 }) == 'UP', 'enum: confirmed roaming PH live -> UP')
check(M.computeWatchState({}, { baselineReady = true, hasRoamingPh = true, now = NOW }).kind == 'placeholder', 'enum: roaming PH kind=placeholder')
check(st({ despawnedAt = NOW - 9000, phNames = { 'x' }, lastSpawnPointKey = 'loc:1.0,1.0' }, READY) == 'DUE', 'enum: ready camp -> DUE')
check(st({ expectedRespawnAt = NOW + 120, lastSpawnPointKey = 'loc:1.0,1.0' }, READY) == 'DOWN', 'enum: counting timer -> DOWN')
check(st({ expectedRespawnAt = NOW - 30, lastSpawnPointKey = 'loc:1.0,1.0' }, READY) == 'DOWN', 'enum: overdue -> DOWN')
check(st({ lastSpawnPointKey = 'loc:1.0,1.0' }, READY) == 'DOWN', 'enum: point only -> DOWN')
check(st({}, READY) == 'UNKNOWN', 'enum: manual -> UNKNOWN')
check(st({}, { baselineReady = false, now = NOW }) == 'UNKNOWN', 'enum: scanning -> UNKNOWN')
check(st({}, { baselineReady = true, inCurrentZone = false, now = NOW }) == 'UNKNOWN', 'enum: off-zone -> UNKNOWN')
check(M.watchSessionTimerExpired({ despawnedAt = NOW - 100 }, { now = NOW, respawnSeconds = function() return 50 end }) == true, 'thunk respawn expired true')
check(M.watchSessionTimerExpired({ despawnedAt = NOW - 100 }, { now = NOW, respawnSeconds = function() return 5000 end }) == false, 'thunk respawn expired false')
check(M.watchDefaultSortTier('UP', 'named', false, false) < M.watchDefaultSortTier('UP', 'placeholder', false, false), 'sort: named UP before PH')
check(M.watchDefaultSortTier('UP', 'placeholder', false, false) < M.watchDefaultSortTier('DUE', 'camp', false, false), 'sort: PH before Camp')
check(M.watchDefaultSortTier('DUE', 'camp', false, true) < M.watchDefaultSortTier('UNKNOWN', 'manual', false, true), 'sort: Camp before Unknown')
check(M.watchDefaultSortTier('UNKNOWN', 'manual', false, true) < M.watchDefaultSortTier('DOWN', 'timer', true, true), 'sort: Unknown before timers when shown')
check(M.watchDefaultSortTier('DOWN', 'timer', true, false) < M.watchDefaultSortTier('UNKNOWN', 'manual', false, false), 'sort: timers before hidden unknown tier')
check(M.watchTimerVisible(NOW + 300, NOW, true, 240) == false, 'timer hide: above four minutes hidden')
check(M.watchTimerVisible(NOW + 240, NOW, true, 240) == true, 'timer hide: four minutes visible')
check(M.watchTimerVisible(NOW + 300, NOW, false, 240) == true, 'timer hide: option off visible')

-- ---------------------------------------------------------------------------
-- Spawn row classification (step 3): module vs byte-identical reference of the
-- ORIGINAL finalizeSpawnRow + rowIsUntargetable, over a battery of row shapes.
-- ---------------------------------------------------------------------------
local function refFinalize(row)
    if not row then return row end
    local name = tostring(row.name or '')
    row.name_l = name:lower()
    row.trueName_l = tostring(row.trueName or ''):lower()
    row.type_l = tostring(row.type or ''):lower()
    row.body_l = tostring(row.body or ''):lower()
    row.class_l = tostring(row.class or ''):lower()
    row.race_l = tostring(row.race or ''):lower()
    row.is_corpse = row.type_l:find('corpse', 1, true) ~= nil
    row.is_player = row.type_l == 'pc' or row.body_l == 'player'
    row.is_ground = row.type_l == 'item' or row.body_l == 'item' or row.type_l == 'ground item'
    row.is_pet_type = row.type_l:find('pet', 1, true) ~= nil
    row.is_pet_body = row.body_l == 'familiar' or row.body_l == 'summoned creature' or row.body_l == 'undeadpet'
    row.is_pet_name = row.name_l:find("'s pet", 1, true) ~= nil or row.name_l:find('`s pet', 1, true) ~= nil
    return row
end
local function refUntarget(row)
    if not row then return false end
    local value = row.targetable
    if value == false or value == 0 then return true end
    local text = tostring(value or ''):lower()
    local rowType = row.type_l or tostring(row.type or ''):lower()
    local rowBody = row.body_l or tostring(row.body or ''):lower()
    return text == 'false' or text == '0' or text == 'no'
        or text == 'off' or text == 'untargetable'
        or rowType:find('untargetable', 1, true) ~= nil
        or rowBody:find('untargetable', 1, true) ~= nil
end
local function cloneRow(t) local n = {}; for k, v in pairs(t) do n[k] = v end; return n end
local rowFlagKeys = { 'name_l','trueName_l','type_l','body_l','class_l','race_l','is_corpse','is_player','is_ground','is_pet_type','is_pet_body','is_pet_name' }
local rowNames = { 'a decaying skeleton', "Soandso's pet", 'Gnasher', 'a giant rat', '', "X`s pet" }
local rowTypes = { 'NPC', 'PC', 'Corpse', 'Untargetable Corpse', 'Pet', 'Item', 'Ground Item', '' }
local rowBodies = { '', 'Player', 'Familiar', 'Summoned Creature', 'Undeadpet', 'Untargetable' }
for _, nm in ipairs(rowNames) do for _, ty in ipairs(rowTypes) do for _, bd in ipairs(rowBodies) do
    local base = { name = nm, trueName = nm, type = ty, body = bd, class = 'Warrior', race = 'Human' }
    local a = M.finalizeSpawnRow(cloneRow(base))
    local b = refFinalize(cloneRow(base))
    local same = true
    for _, k in ipairs(rowFlagKeys) do if a[k] ~= b[k] then same = false end end
    check(same, 'finalizeSpawnRow ' .. nm .. '/' .. ty .. '/' .. bd)
    for _, tg in ipairs({ true, false, 0, 1, 'no', 'off', 'Untargetable', '' }) do
        local r1 = cloneRow(a); r1.targetable = tg
        local r2 = cloneRow(b); r2.targetable = tg
        check(M.rowIsUntargetable(r1) == refUntarget(r2), 'rowIsUntargetable ' .. tostring(tg) .. ' ' .. ty .. '/' .. bd)
    end
end end end
check(M.finalizeSpawnRow(nil) == nil, 'finalizeSpawnRow(nil) == nil')
check(M.rowIsUntargetable(nil) == false, 'rowIsUntargetable(nil) == false')
check(M.finalizeSpawnRow({ name = 'a', type = 'Corpse' }).is_corpse == true, 'corpse flag explicit')
check(M.finalizeSpawnRow({ name = "bob's pet", type = 'Pet' }).is_pet_name == true, 'pet-name flag explicit')
check(M.finalizeSpawnRow({ name = 'x', type = 'PC' }).is_player == true, 'player flag explicit')
check(M.rowIsUntargetable({ targetable = false }) == true, 'untargetable false explicit')
check(M.rowIsUntargetable({ targetable = true, type = 'NPC', body = '' }) == false, 'targetable true explicit')

-- ---------------------------------------------------------------------------
-- Summary
-- ---------------------------------------------------------------------------
print(string.format('turbomobs_logic_test: %d passed, %d failed', passed, failed))
TEST_RESULT = { passed = passed, failed = failed, fails = failLines }

if failed > 0 and arg ~= nil then os.exit(1) end
return TEST_RESULT
