--[[
    turbomobs_logic.lua

    Pure decision/geometry/name primitives for TurboMobs: no dependency on `mq`,
    ImGui, or shared mutable state. Inputs are explicit, so these are
    unit-testable without a running game (turbomobs_logic_test.lua) and are the
    single source of truth that TurboMobs.lua delegates to. Uses only string/math
    primitives whose semantics match across LuaJIT and Lua 5.1-5.4.
]]

local M = {}

local function trim(s)
    return (tostring(s or '')):gsub('^%s+', ''):gsub('%s+$', '')
end
M.trim = trim

-- Round a coordinate to one decimal place (matches host roundedCoord).
function M.roundedCoord(value)
    value = tonumber(value) or 0
    return math.floor((value * 10) + 0.5) / 10
end

-- Build a "loc:Y,X" point key from explicit coords. Note Y is emitted first,
-- matching the host's historical key format. Returns nil if either is nil.
function M.pointKeyFromCoords(x, y)
    if x == nil or y == nil then return nil end
    return string.format('loc:%.1f,%.1f', M.roundedCoord(y), M.roundedCoord(x))
end

-- Build a point key from a spawn row ({x=, y=}). Returns nil if row/coords nil.
function M.spawnPointKey(row)
    if not row or row.x == nil or row.y == nil then return nil end
    return string.format('loc:%.1f,%.1f', M.roundedCoord(row.y), M.roundedCoord(row.x))
end

-- Inverse of pointKeyFromCoords: parse "loc:Y,X" -> (x, y). Returns nils on
-- a malformed key.
function M.coordsFromPointKey(pointKey)
    local y, x = tostring(pointKey or ''):match('^loc:([%-%.%d]+),([%-%.%d]+)$')
    return tonumber(x), tonumber(y)
end

-- Planar distance between a spawn row and an (x, y). Returns nil if any input
-- is missing (caller decides what a nil distance means).
function M.rowDistanceFromLoc(row, x, y)
    if not row or row.x == nil or row.y == nil or x == nil or y == nil then return nil end
    local dx = (tonumber(row.x) or 0) - (tonumber(x) or 0)
    local dy = (tonumber(row.y) or 0) - (tonumber(y) or 0)
    return math.sqrt(dx * dx + dy * dy)
end

-- True when a row is within `radius` of (x, y). radius is REQUIRED here (the
-- host wrapper supplies its default); a nil/<=0 radius yields false.
function M.withinLoc(row, x, y, radius)
    local dist = M.rowDistanceFromLoc(row, x, y)
    local r = tonumber(radius)
    if dist == nil or r == nil then return false end
    return dist <= r
end

-- Normalize a target/corpse name for watch matching: lowercased, with a
-- trailing "'s corpse" / " corpse" / "(level)"-style parenthetical stripped.
function M.normalizeWatchTargetName(name)
    name = trim(tostring(name or ''):lower())
    if name == '' then return name end
    name = name:gsub("%s*'s corpse%s*$", '')
    name = name:gsub('%s* corpse%s*$', '')
    name = name:gsub('%s*%([^)]+%)%s*$', '')
    return trim(name)
end

-- Canonical key for seed/named matching: lowercased, backtick->apostrophe,
-- a leading "the fabled " stripped, non-word/apostrophe runs collapsed to
-- single spaces, then whitespace-normalized.
function M.seedNameKey(value)
    local text = trim(tostring(value or '')):lower():gsub('`', "'")
    text = text:gsub('^the fabled%s+', '')
    text = text:gsub("[^%w']+", ' ')
    text = trim(text:gsub('%s+', ' '))
    return text
end

-- ===========================================================================
-- Watch state derivation
-- ---------------------------------------------------------------------------
-- `ev` (evidence) carries the live game/runtime inputs the host gathers per
-- call; point / known-PH / session-timer booleans are derived from `watch`
-- directly so they can't drift from a stale ev:
--   inCurrentZone     false => watch belongs to another zone
--   baselineReady     ux.watchBaselineReady
--   zoneEntryPending  ux.zoneEntryRefreshPending
--   hasRow            a live named row resolved for this watch
--   hasPlaceholderRow a live PH row at the camp
--   now               os.time()
--   respawnSeconds    number|function (thunk so the costly lookup is only paid
--                     on the one branch that needs it)
-- ===========================================================================

M.WATCH_STATES = { UP = 'UP', DOWN = 'DOWN', DUE = 'DUE', UNKNOWN = 'UNKNOWN' }

local function evNow(ev) return tonumber(ev and ev.now) or 0 end
local function evRespawnSeconds(ev)
    local r = ev and ev.respawnSeconds
    if type(r) == 'function' then r = r() end
    return tonumber(r) or 0
end

-- watch has a saved spawn point.
function M.watchHasPoint(watch)
    return watch and tostring(watch.lastSpawnPointKey or '') ~= ''
end

-- watch lists known placeholder names (live or from seed).
function M.watchHasKnownPhNames(watch)
    if type(watch) ~= 'table' then return false end
    if type(watch.phNames) == 'table' and #watch.phNames > 0 then return true end
    if type(watch.seedPhNames) == 'table' and #watch.seedPhNames > 0 then return true end
    return false
end

-- watch has a session timer (a recorded death or an armed expected-respawn).
function M.watchHasSessionTimer(watch)
    if type(watch) ~= 'table' then return false end
    if (tonumber(watch.despawnedAt or 0) or 0) > 0 then return true end
    if (tonumber(watch.expectedRespawnAt or 0) or 0) > 0 then return true end
    return false
end

-- True when there is live evidence (named up, PH up, or an anchor-confirmed
-- occupant) for this watch right now.
function M.watchHasLiveEvidence(watch, ev)
    watch = watch or {}
    ev = ev or {}
    if watch.isUp or ev.hasRow then return true end
    if ev.hasOffAnchorNamed then return true end
    if ev.hasPlaceholderRow then return true end
    if ev.hasRoamingPh then return true end
    if watch.pointOccupied == true and watch.occupantConfirmedAtAnchor == true
        and (tonumber(watch.occupantSpawnId or 0) or 0) > 0 and watch.isUp ~= true then
        return true
    end
    return false
end

-- True when the watch's session timer has elapsed.
function M.watchSessionTimerExpired(watch, ev)
    if not M.watchHasSessionTimer(watch) then return false end
    local now = evNow(ev)
    local eta = tonumber(watch.expectedRespawnAt or 0) or 0
    if eta > 0 then return eta <= now end
    local despawnedAt = tonumber(watch.despawnedAt or 0) or 0
    if despawnedAt <= 0 then return false end
    local respawn = evRespawnSeconds(ev)
    return respawn > 0 and (despawnedAt + respawn) <= now
end

-- True when the watch is a known-PH camp that is due to be checked (no live
-- evidence, but the respawn window has elapsed).
function M.watchIsCampCheckable(watch, ev)
    if not watch then return false end
    if M.watchHasLiveEvidence(watch, ev) then return false end
    if not M.watchHasKnownPhNames(watch) then return false end
    if not M.watchHasSessionTimer(watch) then return false end
    return M.watchSessionTimerExpired(watch, ev)
end

-- Returns { state, kind, display, color }. state is UP/DOWN/DUE/UNKNOWN;
-- display/color reproduce the legacy ux.watchDisplayStatus strings exactly.
-- Branch order matches the original, so the mapping is behavior-preserving.
function M.computeWatchState(watch, ev)
    watch = watch or {}
    ev = ev or {}
    if ev.inCurrentZone == false then
        return { state = 'UNKNOWN', kind = 'offzone', display = 'Off-zone', color = 'muted' }
    end
    if (ev.baselineReady ~= true or ev.zoneEntryPending == true) and watch.initialResolved ~= true then
        return { state = 'UNKNOWN', kind = 'scanning', display = '...', color = 'muted' }
    end
    if watch.isUp or ev.hasRow then
        return { state = 'UP', kind = 'named', display = 'N UP', color = 'alertUp' }
    end
    if ev.hasOffAnchorNamed then
        return { state = 'UP', kind = 'named_off_anchor', display = 'N UP', color = 'alertUp' }
    end
    if ev.hasPlaceholderRow or ev.hasRoamingPh then
        return { state = 'UP', kind = 'placeholder', display = 'PH UP', color = 'etaSoon' }
    end
    if M.watchIsCampCheckable(watch, ev) then
        return { state = 'DUE', kind = 'camp', display = 'Camp', color = 'etaSoon' }
    end
    local now = evNow(ev)
    local eta = tonumber(watch.expectedRespawnAt or 0) or 0
    local overdue = eta > 0 and eta <= now
    if overdue and M.watchHasSessionTimer(watch) then
        return { state = 'DOWN', kind = 'overdue', display = 'Down', color = 'muted' }
    end
    if eta > 0 and M.watchHasSessionTimer(watch) then
        return { state = 'DOWN', kind = 'timer', display = 'Down', color = 'alertDown' }
    end
    if M.watchHasPoint(watch) then
        return { state = 'DOWN', kind = 'point', display = 'Down', color = 'muted' }
    end
    return { state = 'UNKNOWN', kind = 'manual', display = 'WATCH', color = 'muted' }
end

function M.watchDefaultSortTier(state, kind, hasTimer, showUnknown)
    state = tostring(state or '')
    kind = tostring(kind or '')
    if state == 'UP' and (kind == 'named' or kind == 'named_off_anchor') then return 0 end
    if state == 'UP' and kind == 'placeholder' then return 1 end
    if state == 'DUE' and kind == 'camp' then return 2 end
    if state == 'UNKNOWN' and showUnknown == true then return 3 end
    if hasTimer then return 4 end
    return 5
end

function M.watchTimerVisible(expectedRespawnAt, now, hideKnownTimersUntilSoon, soonSeconds)
    local eta = tonumber(expectedRespawnAt or 0) or 0
    if eta <= 0 then return false end
    if hideKnownTimersUntilSoon ~= true then return true end
    local remaining = eta - (tonumber(now) or os.time())
    return remaining <= (tonumber(soonSeconds) or 240)
end

-- ===========================================================================
-- Spawn row classification
-- ---------------------------------------------------------------------------
-- Pure per-row helpers (operate on an already-read row table) for the corpse /
-- pet / player / ground / untargetable flags that drive filtering and PH
-- detection.
-- ===========================================================================

-- Cache lowercased fields + type/body flags on a row. Mutates and returns it.
function M.finalizeSpawnRow(row)
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

-- True when a row should be treated as untargetable. Reads cached *_l fields
-- when finalizeSpawnRow has run, else falls back to raw fields.
function M.rowIsUntargetable(row)
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

return M
