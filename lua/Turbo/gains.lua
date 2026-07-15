--[[
   *  *  *  *  *  *  *  *  *  *  [  T u r b o G a i n s  ]  *  *  *  *  *  *  *  *  *  *
            ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⢛⠛⠛⡻⢿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
            ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⣻⣵⡲⣝⢮⡙⢶⣽⣿⣷⣾⣾⣟⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
            ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⣳⣿⣿⣷⣿⡹⣖⡹⣿⣿⣿⣿⣿⣿⣿⣦⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
            ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⣸⣿⣿⣿⣿⣿⡷⢬⢱⣿⣿⣿⣿⣿⣿⣿⣿⡇⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
            ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢸⣿⣿⣿⣿⣿⣿⡙⢦⢩⣿⡟⡉⢁⣉⢻⡿⠛⠉⣸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
            ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⣾⣿⡿⣿⣟⡻⢦⡙⢆⠢⢻⣿⣧⣶⣿⣿⡕⣶⣤⡇⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
            ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡗⢻⣍⠳⡱⢎⡱⠣⠜⡠⢃⡝⡿⣿⣿⣿⣿⣿⡹⡟⡀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
            ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⠰⢌⠣⡑⢊⠔⠡⢃⠰⠡⡘⣽⣳⣽⡚⠙⠋⢃⡑⣸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
            ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡆⢌⠢⡑⡈⠄⡁⠂⠄⢃⠜⢲⡝⡎⠣⣀⠞⠣⢄⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
            ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣯⢀⠣⠔⣀⠂⢀⠁⠈⠄⠊⠔⢫⢿⣦⣤⣶⠃⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
            ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡆⢹⡘⣄⠂⠄⢂⠀⠀⠁⠈⠄⠋⢿⡿⠇⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
            ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠃⢲⡙⢦⢩⠐⠢⢌⠠⢀⠀⠀⣠⣤⣤⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
            ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠻⠿⠋⠀⠀⠀⠙⠎⣦⢉⠲⣈⠒⠠⢀⢰⠽⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
            ⣿⣿⣿⣿⣿⡿⣿⠛⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠁⡪⢷⡌⡌⢁⣞⣾⠀⠈⠀⠋⠛⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
            ⣿⣿⠋⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⢻⣮⡴⠯⢾⣿⡄⠀⠀⠀⠀⠀⠀⠈⠙⠙⠿⡿⣿⣿⣿⣿⣿⣿⣿⣿⣿
            ⣿⡁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⢀⠀⠀⠘⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠁⠛⣿⣿⣿⣿⣿⣿⣿⣿
            ⣇⢅⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢶⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢼⣿⣿⣿⣿⣿⣿⣿
            ⣿⡀⠆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠹⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢾⣿⣿⣿⣿⣿⣿⣿
            ⣿⡗⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⢿⣿⣿⣿⣿⣿⣿
            ⣿⣏⡈⡐⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢘⣿⣿⣿⣿⣿⣿
            ⣿⣿⠂⡔⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡺⣿⣿⣿⣿⣿
            ⣿⣿⡎⠓⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⢿⢿⣿⣿⣿
            ⣿⣿⣧⡠⠖⠀⠀⠀⠀⠀⠀⠀⠀⠀⢲⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢼⣿⣿⣿
            ⣿⣿⣯⢃⡒⠈⠄⠀⠀⠀⠀⠀⠀⠀⠈⠋⠦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⣿
            ⣿⣿⣿⣯⡐⠡⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡤⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⣿
            ⣿⣿⣿⣿⣖⠀⢁⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⣟⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⢽
            ⣿⣿⣿⣿⣿⡀⠀⠠⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠻⠿⠻⠁⠀⠀⠀⠀⠀⠀⠀⠀⠘
            ⣿⣿⣿⣿⣿⣧⠀⠀⠀⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢺
            ⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸
            ⣿⣿⣿⣿⣿⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸
            ⣿⣿⣿⣿⣿⣿⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⢀⡀⣀⢀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸
            ⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠁⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⡀⢀⣠⣽
            ▀▀█▀▀ █   █ █▀▀▀▄ █▀▀▀▄ ▄▀▀▀▄ ▄▀▀▀▀ ▄▀▀▀▄ ▀▀█▀▀ █▄  █ ▄▀▀▀▀ 
              █   █   █ █▀▀▀▄ █▀▀▀▄ █   █ █ ▀▀█ █▀▀▀█   █   █ ▀▄█  ▀▀▀▄ 
              ▀    ▀▀▀  ▀   ▀ ▀▀▀▀   ▀▀▀   ▀▀▀  ▀   ▀ ▀▀▀▀▀ ▀   ▀ ▀▀▀▀  
                                XP/AA/Coin tracker
                                by Drel and Dorfus

   Fire it up:
     /lua run Turbo/gains
     /lua run Turbo/gains_toggle start   -- driver: /e3bcaa /lua run Turbo/gains_toggle start

   EQBC loot lines default OFF (UI + Actors do not need them). Enable with:
     /turbogains coin announce on

   Primary commands:
     /turbogains status
     /turbogains xp pause|resume|reset|snapshot|clear|status
     /turbogains coin snapshot|clear|reset|report|announce on|off
     /turbogains mini xp|aa|coin|time on|off|toggle
     /turbogains page xp|aa|coin|feed|snapshots on|off|toggle
     /turbogains pause|resume|reset all|snapshot all|clear snapshots|stop
     /tgains ...                -- short alias

   Compatibility aliases kept:
     /turbostats, /turbomoney, /txp, /turboxp

   @version lua/Turbo/gains.lua 1.0.3
]]

local mq    = require('mq')
local ImGui = require('ImGui')

-- Actors is optional. When present we use it for clean, low-latency state
-- mirroring; when not, we fall back to scraping the EQBC chat announcement.
local okActors, Actors = pcall(require, 'actors')
if not okActors then Actors = nil end

-- One engine instance per MQ Lua VM — duplicate /lua run Turbo/gains is a no-op.
if _G.TurboGainsEngineM then
    printf('\at[TurboGains]\ax \ayEngine already running — duplicate /lua run ignored.\ax')
    return _G.TurboGainsEngineM
end

local M = {
    running = true,
}

-- =============================================================================
-- Configuration & state
-- =============================================================================

local MyName   = mq.TLO.Me.CleanName() or 'unknown'
local MyServer = (mq.TLO.EverQuest.Server() or 'unknown'):gsub(' ', '_')

-- Internal storage is always copper. 1pp = 1000gp = 10000sp = 100000cp.
local CP_PER_SP = 10
local CP_PER_GP = 100
local CP_PER_PP = 1000

-- Tag in the EQBC line. Unique enough to scrape back as Actors fallback.
local BC_TAG = '[TurboGains]'

local stateDir  = string.format('%s/Turbo/Gains/%s', mq.configDir, MyServer)
local oldStateDir = string.format('%s/Turbo/Money/%s', mq.configDir, MyServer)
local stateFile = string.format('%s/%s_gains.lua', stateDir, MyName)
local oldStateFile = string.format('%s/%s_money.lua', oldStateDir, MyName)
-- Live state is read by Turbo's UI process for the embedded Gains tab and
-- the mini-bar gains line. Written on events and heartbeats; rate-limited
-- internally to avoid file thrash.
local liveFile  = string.format('%s/%s_live.lua', stateDir, MyName)
local oldLiveFile  = string.format('%s/%s_live.lua', oldStateDir, MyName)
local xpSettingsFile = string.format('%s/%s_gains_settings.lua', stateDir, MyName)
local oldXPSettingsFile = string.format('%s/%s_xp_settings.lua', oldStateDir, MyName)
local xpSnapshotFile = string.format('%s/%s_xp_snapshots.lua', stateDir, MyName)
local oldXPSnapshotFile = string.format('%s/%s_xp_snapshots.lua', oldStateDir, MyName)
local moneySnapshotFile = string.format('%s/%s_coin_snapshots.lua', stateDir, MyName)

M.config = {
    -- Off by default: plat/XP/AA + ImGui use local state + Actors; EQBC is optional
    -- (visible loot feed / fallback when Actors is unavailable — see header notes).
    announce        = false,
    announceChannel = '/e3bc',   -- /e3bc, /e3bca, /bc, /bca, /dgt — server choice
    minAnnouncePP   = 0,         -- announce only when looted >= N plat (0 = always)
    debug           = false,
    xpSampleMs      = 2000,
    xpMinRateSeconds = 30,
    showXP          = true,
    showAA          = true,
    showZone        = true,
    miniShowXP      = false,
    miniShowAA      = false,
    miniShowCoin    = false,
    miniShowTime    = false,
    pageShowXP      = true,
    pageShowAA      = true,
    pageShowCoin    = true,
    pageShowFeed    = true,
    pageShowSnapshots = true,
    xpShowCurrent   = true,
    xpShowGained    = true,
    xpShowRate      = true,
    xpShowEta       = true,
    aaShowCurrent   = true,
    aaShowGained    = true,
    aaShowRate      = true,
    aaShowEta       = true,
    metaShowLevel   = true,
    metaShowAA      = true,
    metaShowRuntime = true,
    metaShowZone    = true,
    coinShowTotal   = true,
    coinShowTime    = true,
    coinShowEvents  = true,
    coinShowBiggest = true,
    coinShowPerChar = true,
    coinShowFeed    = true,
    coinShowSnapshots = true,
    viewCompact     = true,
}

M.state = {
    session = {
        startedAt   = os.time(),
        -- Pause state: when pausedAt > 0 the timer is frozen at that wall
        -- time. pausedAccum holds the total seconds the timer has been
        -- paused so far across the session, so resume picks up where the
        -- elapsed display left off rather than jumping forward.
        pausedAt    = 0,
        pausedAccum = 0,
        totalCp     = 0,
        events      = 0,
        biggestCp   = 0,
        biggestWho  = '',
        byChar      = {},        -- [name] = { cp, events, lastAt }
        -- Sales-specific subtotals. Only one character in the group runs
        -- TurboLoot.mac sell mode, so salesCp tracks merchant income for the
        -- whole group. These are ALSO folded into totalCp/events above so
        -- existing displays work with no changes; the breakdown lets the UI
        -- (and /turbomoney report) show "Looted vs Sold" at a glance.
        salesCp     = 0,
        salesEvents = 0,
    },
    lifetime = {
        totalCp = 0,
        events  = 0,
        byChar  = {},
        salesCp     = 0,
        salesEvents = 0,
    },
    recent     = {},             -- last N events
    recentMax  = 50,
    moneySnapshots = {},
    moneySnapshotMax = 50,
    xp = {
        tracking = true,
        snapshots = {},
        snapshotMax = 50,
        lastSampleMs = 0,
        status = 'Ready.',
        session = {},
    },
    showWindow = true,           -- visible by default in standalone mode
    collapsed  = false,          -- expanded by default; toggled by [+]/[-]
    actorReady = false,
    eventsBound = false,
}

-- =============================================================================
-- Logging
-- =============================================================================

local function info(fmt, ...)
    printf('\at[TurboGains]\ax ' .. fmt, ...)
end

local function dbg(fmt, ...)
    if M.config.debug then
        printf('\at[TurboGains]\ax \ay' .. fmt .. '\ax', ...)
    end
end

local function safeCall(fn, fallback)
    local ok, value = pcall(fn)
    if ok and value ~= nil then return value end
    return fallback
end

local function currentZoneName()
    local zone = tostring(safeCall(function() return mq.TLO.Zone.Name() end, '') or '')
    if zone == '' or zone == 'NULL' then
        zone = tostring(safeCall(function() return mq.TLO.Zone.ShortName() end, 'Unknown') or 'Unknown')
    end
    return zone
end

-- =============================================================================
-- Parsing & formatting
-- =============================================================================

--- Pull denominations out of EQ loot lines. Examples we want to match:
---   "You receive 5 platinum, 3 gold, 2 silver and 1 copper from the corpse."
---   "You receive 12 platinum from a corpse."
---   "--You have looted 5 platinum from a corpse.--"
---   "You receive 100 gold from <mob>'s corpse."
--- Lines we want to skip (still mention coin words but aren't loot):
---   "You give 5 platinum to ..."
---   "You sold ... for 5 platinum"
---   "You purchase ... for 5 platinum"
local function parseMoneyLine(line)
    if not line or line == '' then return 0, nil end
    local lower = line:lower()
    if not (lower:find('platinum') or lower:find('gold')
        or lower:find('silver') or lower:find('copper')) then
        return 0, nil
    end
    if lower:find('you give')    or lower:find('you trade')
        or lower:find('purchas') or lower:find('sold')
        or lower:find('buy ')    or lower:find('cost ')
        or lower:find('discount') then
        return 0, nil
    end

    local b = { pp = 0, gp = 0, sp = 0, cp = 0 }
    for amt in lower:gmatch('(%d+)%s*platinum') do b.pp = b.pp + (tonumber(amt) or 0) end
    for amt in lower:gmatch('(%d+)%s*gold')     do b.gp = b.gp + (tonumber(amt) or 0) end
    for amt in lower:gmatch('(%d+)%s*silver')   do b.sp = b.sp + (tonumber(amt) or 0) end
    for amt in lower:gmatch('(%d+)%s*copper')   do b.cp = b.cp + (tonumber(amt) or 0) end

    local total = b.pp * CP_PER_PP + b.gp * CP_PER_GP + b.sp * CP_PER_SP + b.cp
    return total, b
end

--- Parse the abbreviated form Turbo broadcasts use, like
---   "156pp 8gp 3sp 1cp from orc legionnaire"
--- This is what other characters' [TurboGains] announce lines contain.
--- Live EQ loot lines still go through parseMoneyLine() so we keep the
--- strict denomination-word guard against merchant/sell/buy false matches.
local function parseAnnounceBreakdown(s)
    if not s or s == '' then return 0, nil end
    local b = { pp = 0, gp = 0, sp = 0, cp = 0 }
    for amt in s:gmatch('(%d+)%s*pp') do b.pp = b.pp + (tonumber(amt) or 0) end
    for amt in s:gmatch('(%d+)%s*gp') do b.gp = b.gp + (tonumber(amt) or 0) end
    for amt in s:gmatch('(%d+)%s*sp') do b.sp = b.sp + (tonumber(amt) or 0) end
    for amt in s:gmatch('(%d+)%s*cp') do b.cp = b.cp + (tonumber(amt) or 0) end
    local total = b.pp * CP_PER_PP + b.gp * CP_PER_GP + b.sp * CP_PER_SP + b.cp
    return total, b
end

local function formatCopper(total)
    total = tonumber(total) or 0
    if total == 0 then return '0cp' end
    local pp = math.floor(total / CP_PER_PP); total = total - pp * CP_PER_PP
    local gp = math.floor(total / CP_PER_GP); total = total - gp * CP_PER_GP
    local sp = math.floor(total / CP_PER_SP); total = total - sp * CP_PER_SP
    local cp = total
    local parts = {}
    if pp > 0 then table.insert(parts, string.format('%dpp', pp)) end
    if gp > 0 then table.insert(parts, string.format('%dgp', gp)) end
    if sp > 0 then table.insert(parts, string.format('%dsp', sp)) end
    if cp > 0 then table.insert(parts, string.format('%dcp', cp)) end
    return table.concat(parts, ' ')
end

local function formatBreakdown(b)
    if not b then return '0pp' end
    local parts = {}
    if b.pp > 0 then table.insert(parts, string.format('%dpp', b.pp)) end
    if b.gp > 0 then table.insert(parts, string.format('%dgp', b.gp)) end
    if b.sp > 0 then table.insert(parts, string.format('%dsp', b.sp)) end
    if b.cp > 0 then table.insert(parts, string.format('%dcp', b.cp)) end
    if #parts == 0 then return '0pp' end
    return table.concat(parts, ' ')
end

local function formatDuration(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60

    if days > 0 then
        return string.format('%dd %02dh %02dm', days, hours, mins)
    elseif hours > 0 then
        return string.format('%02dh %02dm', hours, mins)
    end
    return string.format('%02dm %02ds', mins, secs)
end

-- =============================================================================
-- Persistence
-- =============================================================================

-- Directory creation is done EXACTLY ONCE per script run, at boot time.
-- After that, ensureStateDir is a no-op. The hot path (every loot) must
-- not probe the filesystem, must not spawn any subprocess, must not even
-- touch a temp file -- antivirus/indexing services on Windows can react
-- to any of those with a brief window flash that's visible to the user.
local stateDirEnsured = false

local function ensureStateDir()
    if stateDirEnsured then return end
    stateDirEnsured = true   -- set FIRST so any failure path still no-ops next call

    -- Try lfs first (pure Lua, no subprocess).
    local okLfs, lfs = pcall(require, 'lfs')
    if okLfs and lfs and lfs.mkdir then
        local parts = {}
        for part in stateDir:gmatch('[^/\\]+') do
            table.insert(parts, part)
        end
        local sep = package.config:sub(1, 1) == '\\' and '\\' or '/'
        local accum = (package.config:sub(1, 1) == '\\' and '' or '/')
        for _, part in ipairs(parts) do
            accum = (accum == '' or accum == '/') and (accum .. part)
                                                  or (accum .. sep .. part)
            pcall(lfs.mkdir, accum)
        end
        return
    end

    -- Fallback: Windows API directory creation. Avoid spawning cmd.exe on every
    -- box when TurboGains is started with /e3bcaa.
    local okFfi, ffi = pcall(require, 'ffi')
    if okFfi and package.config:sub(1, 1) == '\\' then
        if not _G.TurboGainsCreateDirectoryCdef then
            pcall(ffi.cdef, [[
                int CreateDirectoryA(const char* lpPathName, void* lpSecurityAttributes);
            ]])
            _G.TurboGainsCreateDirectoryCdef = true
        end
        local winPath = stateDir:gsub('/', '\\'):gsub('\\+$', '')
        local current = ''
        local rest = winPath
        local drive = winPath:match('^%a:')
        if drive then
            current = drive
            rest = winPath:sub(4)
        end
        for part in rest:gmatch('[^\\]+') do
            if current == '' then current = part else current = current .. '\\' .. part end
            pcall(function() ffi.C.CreateDirectoryA(current, nil) end)
        end
    end
end

local function saveState()
    ensureStateDir()
    local f = io.open(stateFile, 'w')
    if not f then return end
    f:write('-- TurboGains state. Auto-generated; safe to delete to reset.\n')
    f:write('return {\n')
    f:write(string.format('  lifetimeTotalCp = %d,\n', M.state.lifetime.totalCp))
    f:write(string.format('  lifetimeEvents  = %d,\n', M.state.lifetime.events))
    f:write(string.format('  lifetimeSalesCp     = %d,\n', M.state.lifetime.salesCp or 0))
    f:write(string.format('  lifetimeSalesEvents = %d,\n', M.state.lifetime.salesEvents or 0))
    f:write('  lifetimeByChar = {\n')
    for name, cp in pairs(M.state.lifetime.byChar) do
        f:write(string.format('    [%q] = %d,\n', name, cp))
    end
    f:write('  },\n')
    f:write('}\n')
    f:close()
end

local stateSaveDirty = false
local lastStateSaveMs = 0
local STATE_SAVE_MIN_MS = 5000

local function nowMs()
    return (mq.gettime and mq.gettime()) or (os.time() * 1000)
end

local function markStateDirty()
    stateSaveDirty = true
end

local function flushStateIfDue(force)
    if not force and not stateSaveDirty then return end
    local t = nowMs()
    if not force and (t - lastStateSaveMs) < STATE_SAVE_MIN_MS then return end
    saveState()
    lastStateSaveMs = t
    stateSaveDirty = false
end

local function loadState()
    local path = stateFile
    local f = io.open(path, 'r')
    if not f then
        path = oldStateFile
        f = io.open(path, 'r')
    end
    if not f then return end
    f:close()
    local ok, data = pcall(dofile, path)
    if not ok or type(data) ~= 'table' then return end
    M.state.lifetime.totalCp = tonumber(data.lifetimeTotalCp) or 0
    M.state.lifetime.events  = tonumber(data.lifetimeEvents)  or 0
    M.state.lifetime.salesCp     = tonumber(data.lifetimeSalesCp)     or 0
    M.state.lifetime.salesEvents = tonumber(data.lifetimeSalesEvents) or 0
    M.state.lifetime.byChar  = {}
    if type(data.lifetimeByChar) == 'table' then
        for k, v in pairs(data.lifetimeByChar) do
            if type(k) == 'string' and type(v) == 'number' then
                M.state.lifetime.byChar[k] = v
            end
        end
    end
end

local saveLiveState

-- =============================================================================
-- XP / AA tracking
-- =============================================================================

local function isEmuBuild()
    local buildName = tostring(safeCall(function() return mq.TLO.MacroQuest.BuildName() end, '') or ''):lower()
    return buildName == 'emu' or buildName:find('emu', 1, true) ~= nil
end

local ON_EMU = isEmuBuild()

local function getLevel()
    return tonumber(safeCall(function() return mq.TLO.Me.Level() end, 0)) or 0
end

local function getAA()
    return tonumber(safeCall(function() return mq.TLO.Me.AAPointsTotal() end, 0)) or 0
end

local function getPctExp()
    return tonumber(safeCall(function() return mq.TLO.Me.PctExp() end, 0)) or 0
end

local function getPctAAExp()
    return tonumber(safeCall(function() return mq.TLO.Me.PctAAExp() end, 0)) or 0
end

local function getRawExp()
    return tonumber(safeCall(function() return mq.TLO.Me.Exp() end, nil))
end

local function getRawAAExp()
    return tonumber(safeCall(function() return mq.TLO.Me.AAExp() end, nil))
end

local function currentXPUnits()
    local level = getLevel()
    local pctExp = getPctExp()

    -- EQEmu/RoF2-safe tracking:
    -- 1 level = 100 units, current percent is fractional progress.
    -- Do not use raw Me.Exp() here; it can report unstable values on emu.
    return level * 100 + pctExp, level, pctExp, 'pct'
end

local function currentAAUnits()
    local aa = getAA()
    local pctAA = getPctAAExp()

    -- EQEmu/RoF2-safe tracking:
    -- 1 AA = 100 units, current percent is fractional progress.
    -- Do not use raw Me.AAExp() here; it can report unstable values on emu.
    return aa * 100 + pctAA, aa, pctAA, 'pct'
end

local function xpValuesReady()
    local level = getLevel()
    local pctExp = getPctExp()
    local aa = getAA()
    local pctAA = getPctAAExp()

    return level > 0
        and pctExp >= 0 and pctExp <= 100
        and aa >= 0
        and pctAA >= 0 and pctAA <= 100
end

local function sessionSeconds()
    local s = M.state.session
    if not s.startedAt then return 0 end
    local refTime = (s.pausedAt and s.pausedAt > 0) and s.pausedAt or os.time()
    return math.max(0, refTime - s.startedAt - (s.pausedAccum or 0))
end

local function updateXPRates()
    local xs = M.state.xp.session
    local secs = math.max(1, sessionSeconds())
    xs.xpPerHour = (xs.xpGained or 0) / secs * 3600
    xs.aaPerHour = (xs.aaGained or 0) / secs * 3600

    if secs < (M.config.xpMinRateSeconds or 30) or (xs.xpPerHour or 0) <= 0 then
        xs.etaLevel = '-'
    else
        xs.etaLevel = formatDuration(((100 - (xs.currentPctExp or 0)) / xs.xpPerHour) * 3600)
    end

    if secs < (M.config.xpMinRateSeconds or 30) or (xs.aaPerHour or 0) <= 0 then
        xs.etaAA = '-'
    else
        xs.etaAA = formatDuration(((100 - (xs.currentPctAA or 0)) / xs.aaPerHour) * 3600)
    end
end

local function resetXP()
    if not xpValuesReady() then
        M.state.xp.status = 'Waiting for valid XP/AA values...'
        return false
    end

    local xpUnits, level, pctExp, xpMode = currentXPUnits()
    local aaUnits, aa, pctAA, aaMode = currentAAUnits()

    M.state.xp.session = {
        startXPUnits = xpUnits,
        startAAUnits = aaUnits,
        currentXPUnits = xpUnits,
        currentAAUnits = aaUnits,
        startLevel = level,
        currentLevel = level,
        startAA = aa,
        currentAA = aa,
        startPctExp = pctExp,
        currentPctExp = pctExp,
        startPctAA = pctAA,
        currentPctAA = pctAA,
        xpMode = xpMode,
        aaMode = aaMode,
        xpGained = 0,
        aaGained = 0,
        xpPerHour = 0,
        aaPerHour = 0,
        etaLevel = '-',
        etaAA = '-',
        levelUps = 0,
        aaPointsGained = 0,
        startZone = currentZoneName(),
        currentZone = currentZoneName(),
    }
    M.state.xp.lastSampleMs = nowMs()
    M.state.xp.status = 'XP session reset.'
    return true
end

local function sampleXP(force)
    if not force then
        if not M.state.xp.tracking then return end
        if M.state.session.pausedAt and M.state.session.pausedAt > 0 then return end
    end
    if not xpValuesReady() then
        M.state.xp.status = 'Skipped invalid XP/AA sample.'
        return
    end
    
    if not M.state.xp.session or not M.state.xp.session.startXPUnits then
        if not resetXP() then return end
    end
    
    local xs = M.state.xp.session
    local xpUnits, level, pctExp = currentXPUnits()
    local aaUnits, aa, pctAA = currentAAUnits()

    xs.currentXPUnits = xpUnits
    xs.currentAAUnits = aaUnits
    xs.currentLevel = level
    xs.currentAA = aa
    xs.currentPctExp = pctExp
    xs.currentPctAA = pctAA
    xs.currentZone = currentZoneName()
    
    local newXpGained = xpUnits - (xs.startXPUnits or xpUnits)
    local newAaGained = aaUnits - (xs.startAAUnits or aaUnits)
    local newLevelUps = level - (xs.startLevel or level)
    local newAaPointsGained = aa - (xs.startAA or aa)
    
    if math.abs(newXpGained) > 500 or math.abs(newAaGained) > 50000 then
        M.state.xp.status = string.format(
            'Ignored suspicious XP sample: XP %.2f AA %.2f',
            newXpGained,
            newAaGained / 100
        )
        return
    end
    
    xs.xpGained = newXpGained
    xs.aaGained = newAaGained
    xs.levelUps = newLevelUps
    xs.aaPointsGained = newAaPointsGained
    
    updateXPRates()
    M.state.xp.lastSampleMs = nowMs()
    M.state.xp.status = 'Updated ' .. os.date('%H:%M:%S')
end

local function sampleXPIfDue()
    if nowMs() - (M.state.xp.lastSampleMs or 0) >= (M.config.xpSampleMs or 2000) then
        if M.state.xp.tracking and not (M.state.session.pausedAt and M.state.session.pausedAt > 0) then
            sampleXP(false)
        end
        -- Heartbeat the live file even when XP/session sampling is paused so
        -- the UI can tell a real running engine from an old stale state file.
        saveLiveState(false)
    end
end

local DISPLAY_SETTING_KEYS = {
    'miniShowXP', 'miniShowAA', 'miniShowCoin', 'miniShowTime',
    'pageShowXP', 'pageShowAA', 'pageShowCoin', 'pageShowFeed', 'pageShowSnapshots',
    'xpShowCurrent', 'xpShowGained', 'xpShowRate', 'xpShowEta',
    'aaShowCurrent', 'aaShowGained', 'aaShowRate', 'aaShowEta',
    'metaShowLevel', 'metaShowAA', 'metaShowRuntime', 'metaShowZone',
    'coinShowTotal', 'coinShowTime', 'coinShowEvents', 'coinShowBiggest',
    'coinShowPerChar', 'coinShowFeed', 'coinShowSnapshots',
    'viewCompact',
}

local function saveXPSettings()
    ensureStateDir()
    local f = io.open(xpSettingsFile, 'w')
    if not f then return end
    f:write('return {\n')
    f:write(string.format('  tracking = %s,\n', tostring(M.state.xp.tracking)))
    f:write(string.format('  sampleMs = %d,\n', tonumber(M.config.xpSampleMs) or 2000))
    f:write(string.format('  minRateSeconds = %d,\n', tonumber(M.config.xpMinRateSeconds) or 30))
    f:write(string.format('  showXP = %s,\n', tostring(M.config.showXP)))
    f:write(string.format('  showAA = %s,\n', tostring(M.config.showAA)))
    f:write(string.format('  showZone = %s,\n', tostring(M.config.showZone)))
    for _, key in ipairs(DISPLAY_SETTING_KEYS) do
        f:write(string.format('  %s = %s,\n', key, tostring(M.config[key])))
    end
    f:write('}\n')
    f:close()
end

local function loadXPSettings()
    local path = xpSettingsFile
    local f = io.open(path, 'r')
    if not f then
        path = oldXPSettingsFile
        f = io.open(path, 'r')
    end
    if not f then return end
    f:close()
    local ok, data = pcall(dofile, path)
    if not ok or type(data) ~= 'table' then return end
    if data.tracking ~= nil then M.state.xp.tracking = data.tracking == true end
    M.config.xpSampleMs = math.max(500, tonumber(data.sampleMs) or M.config.xpSampleMs)
    M.config.xpMinRateSeconds = math.max(1, tonumber(data.minRateSeconds) or M.config.xpMinRateSeconds)
    if data.showXP ~= nil then M.config.showXP = data.showXP == true end
    if data.showAA ~= nil then M.config.showAA = data.showAA == true end
    if data.showZone ~= nil then M.config.showZone = data.showZone == true end
    for _, key in ipairs(DISPLAY_SETTING_KEYS) do
        if data[key] ~= nil then M.config[key] = data[key] == true end
    end
    if not M.config.pageShowXP and not M.config.pageShowAA and not M.config.pageShowCoin and not M.config.pageShowFeed and not M.config.pageShowSnapshots then
        M.config.pageShowXP, M.config.pageShowAA, M.config.pageShowCoin, M.config.pageShowFeed, M.config.pageShowSnapshots = true, true, true, true, true
    end
    if not M.config.showXP and not M.config.showAA then
        M.config.showXP = true
        M.config.showAA = true
    end
end

local function saveXPSnapshots()
    ensureStateDir()
    local f = io.open(xpSnapshotFile, 'w')
    if not f then return end
    f:write('return {\n')
    for _, row in ipairs(M.state.xp.snapshots or {}) do
        f:write(string.format(
            '  { time = %q, ts = %d, zone = %q, runtime = %d, xpGained = %.6f, aaGained = %.6f, xpPerHour = %.6f, aaPerHour = %.6f, level = %d, aa = %d },\n',
            tostring(row.time or ''), tonumber(row.ts) or 0, tostring(row.zone or ''), tonumber(row.runtime) or 0,
            tonumber(row.xpGained) or 0, tonumber(row.aaGained) or 0,
            tonumber(row.xpPerHour) or 0, tonumber(row.aaPerHour) or 0,
            tonumber(row.level) or 0, tonumber(row.aa) or 0))
    end
    f:write('}\n')
    f:close()
end

local function loadXPSnapshots()
    local path = xpSnapshotFile
    local f = io.open(path, 'r')
    if not f then
        path = oldXPSnapshotFile
        f = io.open(path, 'r')
    end
    if not f then return end
    f:close()
    local ok, data = pcall(dofile, path)
    if ok and type(data) == 'table' then
        M.state.xp.snapshots = data
    end
end

local function addXPSnapshot()
    sampleXP(true)
    local xs = M.state.xp.session
    local newRow = {
        time = os.date('%H:%M:%S'),
        ts   = os.time(),   -- unix timestamp for age-based pruning
        zone = currentZoneName(),
        runtime = sessionSeconds(),
        xpGained = xs.xpGained or 0,
        aaGained = xs.aaGained or 0,
        xpPerHour = xs.xpPerHour or 0,
        aaPerHour = xs.aaPerHour or 0,
        level = xs.currentLevel or 0,
        aa = xs.currentAA or 0,
    }
    table.insert(M.state.xp.snapshots, 1, newRow)

    -- Personal best: check if this run beats prior bests for this zone.
    local zone = newRow.zone
    local xphr = tonumber(newRow.xpPerHour) or 0
    local aahr = tonumber(newRow.aaPerHour) or 0
    if zone ~= '' and (tonumber(newRow.runtime) or 0) >= 60 then
        local prevBestXP, prevBestAA = 0, 0
        for i = 2, #M.state.xp.snapshots do
            local r = M.state.xp.snapshots[i]
            if r.zone == zone then
                prevBestXP = math.max(prevBestXP, tonumber(r.xpPerHour) or 0)
                prevBestAA = math.max(prevBestAA, tonumber(r.aaPerHour) or 0)
            end
        end
        if xphr > 0 and prevBestXP > 0 and xphr > prevBestXP then
            info('\ag*** Personal best XP/hr in %s: %.2f%%/hr (prev %.2f%%/hr) ***\ax',
                zone, xphr, prevBestXP)
        end
        if aahr > 0 and prevBestAA > 0 and aahr > prevBestAA then
            info('\ag*** Personal best AA/hr in %s: %.1f AA/hr (prev %.1f AA/hr) ***\ax',
                zone, aahr / 100, prevBestAA / 100)
        end
    end

    while #M.state.xp.snapshots > (M.state.xp.snapshotMax or 50) do
        table.remove(M.state.xp.snapshots)
    end
    saveXPSnapshots()
    saveLiveState(true)
    M.state.xp.status = 'Snapshot saved.'
end

local function saveMoneySnapshots()
    ensureStateDir()
    local f = io.open(moneySnapshotFile, 'w')
    if not f then return end
    f:write('return {\n')
    for _, row in ipairs(M.state.moneySnapshots or {}) do
        f:write(string.format('  { time = %q, ts = %d, zone = %q, runtime = %d, totalCp = %d, lootedCp = %d, salesCp = %d, events = %d, biggestCp = %d, biggestWho = %q },\n', tostring(row.time or ''), tonumber(row.ts) or 0, tostring(row.zone or ''), tonumber(row.runtime) or 0, tonumber(row.totalCp) or 0, tonumber(row.lootedCp) or 0, tonumber(row.salesCp) or 0, tonumber(row.events) or 0, tonumber(row.biggestCp) or 0, tostring(row.biggestWho or '')))
    end
    f:write('}\n')
    f:close()
end

local function loadMoneySnapshots()
    local f = io.open(moneySnapshotFile, 'r')
    if not f then return end
    f:close()
    local ok, data = pcall(dofile, moneySnapshotFile)
    if ok and type(data) == 'table' then M.state.moneySnapshots = data end
end

local function addMoneySnapshot()
    local s = M.state.session
    local salesCp = tonumber(s.salesCp) or 0
    local newSnap = {
        time = os.date('%H:%M:%S'), ts = os.time(), zone = currentZoneName(), runtime = sessionSeconds(),
        totalCp = tonumber(s.totalCp) or 0, lootedCp = math.max(0, (tonumber(s.totalCp) or 0) - salesCp),
        salesCp = salesCp, events = tonumber(s.events) or 0,
        biggestCp = tonumber(s.biggestCp) or 0, biggestWho = tostring(s.biggestWho or ''),
    }
    table.insert(M.state.moneySnapshots, 1, newSnap)

    -- Personal best: check if this run's coin/hr beats prior bests for this zone.
    local zone = newSnap.zone
    local runtime = tonumber(newSnap.runtime) or 0
    local totalCp = tonumber(newSnap.totalCp) or 0
    if zone ~= '' and runtime >= 60 and totalCp > 0 then
        local newCpHr = (totalCp / runtime) * 3600
        local prevBestCpHr = 0
        for i = 2, #M.state.moneySnapshots do
            local r = M.state.moneySnapshots[i]
            if r.zone == zone then
                local rt = tonumber(r.runtime) or 0
                local cp = tonumber(r.totalCp) or 0
                if rt >= 60 then
                    prevBestCpHr = math.max(prevBestCpHr, (cp / rt) * 3600)
                end
            end
        end
        if prevBestCpHr > 0 and newCpHr > prevBestCpHr then
            info('\ag*** Personal best coin/hr in %s: %s/hr ***\ax',
                zone, formatCopper(math.floor(newCpHr + 0.5)))
        end
    end

    while #M.state.moneySnapshots > (M.state.moneySnapshotMax or 50) do table.remove(M.state.moneySnapshots) end
    saveMoneySnapshots()
    saveLiveState(true)
    info('\agCoin snapshot saved.\ax')
end


-- =============================================================================
-- Snapshot pruning
-- =============================================================================

local PRUNE_DEFAULT_DAYS = 30

--- Prune XP snapshots older than keepDays days, preserving per-zone personal bests.
--- Rows without a ts field (saved before this version) are never pruned.
local function pruneXPSnapshots(keepDays)
    keepDays = tonumber(keepDays) or PRUNE_DEFAULT_DAYS
    local cutoff = os.time() - keepDays * 86400
    -- Identify per-zone personal bests first so we never drop them.
    local bestXP, bestAA = {}, {}
    for _, r in ipairs(M.state.xp.snapshots or {}) do
        local z = tostring(r.zone or '')
        local xphr = tonumber(r.xpPerHour) or 0
        local aahr = tonumber(r.aaPerHour) or 0
        if xphr > (bestXP[z] or 0) then bestXP[z] = xphr end
        if aahr > (bestAA[z] or 0) then bestAA[z] = aahr end
    end
    local keep, pruned = {}, 0
    for _, r in ipairs(M.state.xp.snapshots or {}) do
        local ts = tonumber(r.ts) or 0
        local isOld = ts > 0 and ts < cutoff
        local z = tostring(r.zone or '')
        local isPBxp = (bestXP[z] or 0) > 0 and (tonumber(r.xpPerHour) or 0) >= bestXP[z]
        local isPBaa = (bestAA[z] or 0) > 0 and (tonumber(r.aaPerHour) or 0) >= bestAA[z]
        if isOld and not isPBxp and not isPBaa then
            pruned = pruned + 1
        else
            keep[#keep + 1] = r
        end
    end
    M.state.xp.snapshots = keep
    if pruned > 0 then
        saveXPSnapshots()
        info('\agPruned %d old XP snapshot%s (personal bests kept).\ax', pruned, pruned == 1 and '' or 's')
    else
        info('\agNo old XP snapshots to prune (<%d days).\ax', keepDays)
    end
    return pruned
end

local function pruneMoneySnapshots(keepDays)
    keepDays = tonumber(keepDays) or PRUNE_DEFAULT_DAYS
    local cutoff = os.time() - keepDays * 86400
    local bestCpHr = {}
    for _, r in ipairs(M.state.moneySnapshots or {}) do
        local z = tostring(r.zone or '')
        local rt = tonumber(r.runtime) or 0
        local cp = tonumber(r.totalCp) or 0
        if rt >= 60 then
            local cphr = (cp / rt) * 3600
            if cphr > (bestCpHr[z] or 0) then bestCpHr[z] = cphr end
        end
    end
    local keep, pruned = {}, 0
    for _, r in ipairs(M.state.moneySnapshots or {}) do
        local ts = tonumber(r.ts) or 0
        local isOld = ts > 0 and ts < cutoff
        local z = tostring(r.zone or '')
        local rt = tonumber(r.runtime) or 0
        local cp = tonumber(r.totalCp) or 0
        local cphr = rt >= 60 and (cp / rt) * 3600 or 0
        local isPB = (bestCpHr[z] or 0) > 0 and cphr >= bestCpHr[z]
        if isOld and not isPB then
            pruned = pruned + 1
        else
            keep[#keep + 1] = r
        end
    end
    M.state.moneySnapshots = keep
    if pruned > 0 then
        saveMoneySnapshots()
        info('\agPruned %d old coin snapshot%s (personal bests kept).\ax', pruned, pruned == 1 and '' or 's')
    else
        info('\agNo old coin snapshots to prune (<%d days).\ax', keepDays)
    end
    return pruned
end

local function clearMoneySnapshots()
    M.state.moneySnapshots = {}
    saveMoneySnapshots()
    saveLiveState(true)
    info('\ayCoin snapshots cleared.\ax')
end

-- Live-state file write. Turbo's UI process reads this every render frame
-- (rate-limited there) to populate the embedded Money tab and mini bar.
-- We rate-limit writes here too so a burst of N loots doesn't write the
-- file N times in the same second.
local lastLiveWriteMs = 0
local LIVE_WRITE_MIN_MS = 500
local liveSaveErrLogged = false   -- log first failure to chat, then go quiet

saveLiveState = function(force)
    local t = nowMs()
    if not force and (t - lastLiveWriteMs) < LIVE_WRITE_MIN_MS then
        return
    end
    lastLiveWriteMs = t

    ensureStateDir()
    -- Write directly to the live file. We previously used a tmp+rename for
    -- atomicity, but Windows os.rename FAILS when the destination already
    -- exists -- which means every save after the first one was silently
    -- dropped, the file went stale, and the embedded UI thought the engine
    -- was offline. The file is small enough that a half-read is harmless;
    -- the reader uses pcall around dofile and just keeps the prior snap.
    local f, openErr = io.open(liveFile, 'w')
    if not f then
        if not liveSaveErrLogged then
            liveSaveErrLogged = true
            info('\arsaveLiveState: cannot open %s (%s)\ax',
                liveFile, tostring(openErr))
        end
        return
    end

    -- Build the file body in a single string to keep writes atomic-ish from
    -- the perspective of any concurrent reader (one OS-level write call).
    local lines = {
        '-- TurboGains live state. Auto-generated. Read-only for UI.',
        'return {',
        '  schema    = "TurboGainsLive",',
        '  version   = 3,',
        string.format('  running   = %s,', tostring(M.running == true)),
        string.format('  updatedAt = %d,', os.time()),
        string.format('  myName    = %q,', MyName),
        string.format('  announce  = %s,', tostring(M.config.announce)),
        string.format('  channel   = %q,', M.config.announceChannel or ''),
        '  display = {',
        string.format('    miniXP = %s,', tostring(M.config.miniShowXP)),
        string.format('    miniAA = %s,', tostring(M.config.miniShowAA)),
        string.format('    miniCoin = %s,', tostring(M.config.miniShowCoin)),
        string.format('    miniTime = %s,', tostring(M.config.miniShowTime)),
        string.format('    pageXP = %s,', tostring(M.config.pageShowXP)),
        string.format('    pageAA = %s,', tostring(M.config.pageShowAA)),
        string.format('    pageCoin = %s,', tostring(M.config.pageShowCoin)),
        string.format('    pageFeed = %s,', tostring(M.config.pageShowFeed)),
        string.format('    pageSnapshots = %s,', tostring(M.config.pageShowSnapshots)),
        string.format('    xpCurrent = %s,', tostring(M.config.xpShowCurrent)),
        string.format('    xpGained = %s,', tostring(M.config.xpShowGained)),
        string.format('    xpRate = %s,', tostring(M.config.xpShowRate)),
        string.format('    xpEta = %s,', tostring(M.config.xpShowEta)),
        string.format('    aaCurrent = %s,', tostring(M.config.aaShowCurrent)),
        string.format('    aaGained = %s,', tostring(M.config.aaShowGained)),
        string.format('    aaRate = %s,', tostring(M.config.aaShowRate)),
        string.format('    aaEta = %s,', tostring(M.config.aaShowEta)),
        string.format('    metaLevel = %s,', tostring(M.config.metaShowLevel)),
        string.format('    metaAA = %s,', tostring(M.config.metaShowAA)),
        string.format('    metaRuntime = %s,', tostring(M.config.metaShowRuntime)),
        string.format('    metaZone = %s,', tostring(M.config.metaShowZone)),
        string.format('    coinTotal = %s,', tostring(M.config.coinShowTotal)),
        string.format('    coinTime = %s,', tostring(M.config.coinShowTime)),
        string.format('    coinEvents = %s,', tostring(M.config.coinShowEvents)),
        string.format('    coinBiggest = %s,', tostring(M.config.coinShowBiggest)),
        string.format('    coinPerChar = %s,', tostring(M.config.coinShowPerChar)),
        string.format('    coinFeed = %s,', tostring(M.config.coinShowFeed)),
        string.format('    coinSnapshots = %s,', tostring(M.config.coinShowSnapshots)),
        string.format('    compact = %s,', tostring(M.config.viewCompact)),
        '  },',
        '  session = {',
        string.format('    startedAt   = %d,', M.state.session.startedAt or os.time()),
        string.format('    pausedAt    = %d,', M.state.session.pausedAt or 0),
        string.format('    pausedAccum = %d,', M.state.session.pausedAccum or 0),
        string.format('    totalCp     = %d,', M.state.session.totalCp or 0),
        string.format('    events      = %d,', M.state.session.events or 0),
        string.format('    biggestCp   = %d,', M.state.session.biggestCp or 0),
        string.format('    biggestWho  = %q,', M.state.session.biggestWho or ''),
        string.format('    salesCp     = %d,', M.state.session.salesCp or 0),
        string.format('    salesEvents = %d,', M.state.session.salesEvents or 0),
        '    byChar = {',
    }
    for name, info_ in pairs(M.state.session.byChar or {}) do
        table.insert(lines, string.format(
            '      [%q] = { cp = %d, events = %d },',
            tostring(name), tonumber(info_.cp) or 0,
            tonumber(info_.events) or 0))
    end
    table.insert(lines, '    },')
    table.insert(lines, '  },')
    table.insert(lines, '  lifetime = {')
    table.insert(lines, string.format('    totalCp = %d,',
        M.state.lifetime.totalCp or 0))
    table.insert(lines, string.format('    events  = %d,',
        M.state.lifetime.events or 0))
    table.insert(lines, string.format('    salesCp     = %d,',
        M.state.lifetime.salesCp or 0))
    table.insert(lines, string.format('    salesEvents = %d,',
        M.state.lifetime.salesEvents or 0))
    table.insert(lines, '  },')
    table.insert(lines, '  recent = {')
    local cap = math.min(25, #M.state.recent)
    for i = 1, cap do
        local r = M.state.recent[i] or {}
        local b = r.breakdown or {}
        table.insert(lines, string.format(
            '    { at = %q, who = %q, cp = %d, corpse = %q, zone = %q,'
            .. ' pp = %d, gp = %d, sp = %d, ccp = %d },',
            tostring(r.at or ''), tostring(r.who or ''),
            tonumber(r.cp) or 0, tostring(r.corpse or ''), tostring(r.zone or ''),
            tonumber(b.pp) or 0, tonumber(b.gp) or 0,
            tonumber(b.sp) or 0, tonumber(b.cp) or 0))
    end
    table.insert(lines, '  },')

    -- New combined schema. The legacy top-level session/lifetime/recent
    -- fields above stay in place so older Money views keep working.
    table.insert(lines, '  money = {')
    table.insert(lines, '    session = {')
    table.insert(lines, string.format('      startedAt = %d,', M.state.session.startedAt or os.time()))
    table.insert(lines, string.format('      pausedAt = %d,', M.state.session.pausedAt or 0))
    table.insert(lines, string.format('      pausedAccum = %d,', M.state.session.pausedAccum or 0))
    table.insert(lines, string.format('      totalCp = %d,', M.state.session.totalCp or 0))
    table.insert(lines, string.format('      events = %d,', M.state.session.events or 0))
    table.insert(lines, string.format('      biggestCp = %d,', M.state.session.biggestCp or 0))
    table.insert(lines, string.format('      biggestWho = %q,', M.state.session.biggestWho or ''))
    table.insert(lines, string.format('      salesCp = %d,', M.state.session.salesCp or 0))
    table.insert(lines, string.format('      salesEvents = %d,', M.state.session.salesEvents or 0))
    table.insert(lines, '    },')
    table.insert(lines, '    lifetime = {')
    table.insert(lines, string.format('      totalCp = %d,', M.state.lifetime.totalCp or 0))
    table.insert(lines, string.format('      events = %d,', M.state.lifetime.events or 0))
    table.insert(lines, string.format('      salesCp = %d,', M.state.lifetime.salesCp or 0))
    table.insert(lines, string.format('      salesEvents = %d,', M.state.lifetime.salesEvents or 0))
    table.insert(lines, '    },')
    table.insert(lines, '    snapshots = {')
    local mcap = math.min(25, #(M.state.moneySnapshots or {}))
    for i = 1, mcap do
        local row = M.state.moneySnapshots[i] or {}
        table.insert(lines, string.format(
            '      { time = %q, zone = %q, runtime = %d, totalCp = %d, lootedCp = %d, salesCp = %d, events = %d, biggestCp = %d, biggestWho = %q },',
            tostring(row.time or ''), tostring(row.zone or ''), tonumber(row.runtime) or 0,
            tonumber(row.totalCp) or 0, tonumber(row.lootedCp) or 0, tonumber(row.salesCp) or 0,
            tonumber(row.events) or 0, tonumber(row.biggestCp) or 0, tostring(row.biggestWho or '')))
    end
    table.insert(lines, '    },')
    table.insert(lines, '  },')

    local xs = M.state.xp.session or {}
    table.insert(lines, '  xp = {')
    table.insert(lines, string.format('    tracking = %s,', tostring(M.state.xp.tracking)))
    table.insert(lines, string.format('    status = %q,', tostring(M.state.xp.status or '')))
    table.insert(lines, string.format('    sampleMs = %d,', tonumber(M.config.xpSampleMs) or 2000))
    table.insert(lines, string.format('    minRateSeconds = %d,', tonumber(M.config.xpMinRateSeconds) or 30))
    table.insert(lines, string.format('    showXP = %s,', tostring(M.config.showXP)))
    table.insert(lines, string.format('    showAA = %s,', tostring(M.config.showAA)))
    table.insert(lines, string.format('    showZone = %s,', tostring(M.config.showZone)))
    table.insert(lines, string.format('    runtime = %d,', sessionSeconds()))
    table.insert(lines, string.format('    mode = %q,', 'safe pct tracking'))
    table.insert(lines, '    session = {')
    table.insert(lines, string.format('      currentLevel = %d,', xs.currentLevel or 0))
    table.insert(lines, string.format('      currentAA = %d,', xs.currentAA or 0))
    table.insert(lines, string.format('      currentPctExp = %.6f,', xs.currentPctExp or 0))
    table.insert(lines, string.format('      currentPctAA = %.6f,', xs.currentPctAA or 0))
    table.insert(lines, string.format('      xpGained = %.6f,', xs.xpGained or 0))
    table.insert(lines, string.format('      aaGained = %.6f,', xs.aaGained or 0))
    table.insert(lines, string.format('      xpPerHour = %.6f,', xs.xpPerHour or 0))
    table.insert(lines, string.format('      aaPerHour = %.6f,', xs.aaPerHour or 0))
    table.insert(lines, string.format('      etaLevel = %q,', xs.etaLevel or '-'))
    table.insert(lines, string.format('      etaAA = %q,', xs.etaAA or '-'))
    table.insert(lines, string.format('      levelUps = %d,', xs.levelUps or 0))
    table.insert(lines, string.format('      aaPointsGained = %d,', xs.aaPointsGained or 0))
    table.insert(lines, string.format('      startZone = %q,', xs.startZone or ''))
    table.insert(lines, string.format('      currentZone = %q,', xs.currentZone or currentZoneName()))
    table.insert(lines, '    },')
    table.insert(lines, '    snapshots = {')
    local xcap = math.min(25, #(M.state.xp.snapshots or {}))
    for i = 1, xcap do
        local row = M.state.xp.snapshots[i] or {}
        table.insert(lines, string.format(
            '      { time = %q, zone = %q, runtime = %d, xpGained = %.6f, aaGained = %.6f, xpPerHour = %.6f, aaPerHour = %.6f, level = %d, aa = %d },',
            tostring(row.time or ''), tostring(row.zone or ''), tonumber(row.runtime) or 0,
            tonumber(row.xpGained) or 0, tonumber(row.aaGained) or 0,
            tonumber(row.xpPerHour) or 0, tonumber(row.aaPerHour) or 0,
            tonumber(row.level) or 0, tonumber(row.aa) or 0))
    end
    table.insert(lines, '    },')
    table.insert(lines, '  },')
    table.insert(lines, '}')
    table.insert(lines, '')

    local body = table.concat(lines, '\n')
    local okWrite = pcall(function() f:write(body) end)
    f:close()
    if not okWrite and not liveSaveErrLogged then
        liveSaveErrLogged = true
        info('\arsaveLiveState: write failed for %s\ax', liveFile)
    end
end

-- =============================================================================
-- Recording loot
-- =============================================================================

local function recordLoot(who, cp, breakdown, corpse, source)
    if not who or who == '' then who = 'unknown' end
    cp = tonumber(cp) or 0
    if cp <= 0 then return end

    -- When paused, skip recording entirely. This keeps AFK / cleanup-loot
    -- coin out of the session totals so the per-hour rate stays honest.
    -- The looter still announces (their own engine fires before the message
    -- reaches us); we just choose not to credit it on this side.
    if M.state.session.pausedAt and M.state.session.pausedAt > 0 then
        dbg('skipping loot record: session is paused')
        return
    end

    local s = M.state.session
    s.totalCp = s.totalCp + cp
    s.events  = s.events  + 1
    if cp > s.biggestCp then
        s.biggestCp  = cp
        s.biggestWho = who
    end
    s.byChar[who] = s.byChar[who] or { cp = 0, events = 0, lastAt = 0 }
    s.byChar[who].cp     = s.byChar[who].cp     + cp
    s.byChar[who].events = s.byChar[who].events + 1
    s.byChar[who].lastAt = os.time()

    -- Lifetime is local to this character; only count when *this* char looted.
    if who == MyName then
        M.state.lifetime.totalCp = M.state.lifetime.totalCp + cp
        M.state.lifetime.events  = M.state.lifetime.events  + 1
        M.state.lifetime.byChar[who] = (M.state.lifetime.byChar[who] or 0) + cp
        markStateDirty()
    end

    table.insert(M.state.recent, 1, {
        at        = os.date('%H:%M:%S'),
        who       = who,
        cp        = cp,
        breakdown = breakdown or {},
        corpse    = corpse or '',
        zone      = currentZoneName(),
        source    = source or 'local',
    })
    while #M.state.recent > M.state.recentMax do
        table.remove(M.state.recent)
    end

    dbg('recorded %s for %s (%s%s)', formatCopper(cp), who, source,
        corpse ~= '' and (' from ' .. corpse) or '')

    -- Mirror state to the live file so Turbo's embedded UI sees the update.
    saveLiveState(false)
end

--- Record merchant sale income. Behaves like recordLoot for session/lifetime
--- totals (so all existing displays "just work") but ALSO bumps the sales
--- subtotals and tags the recent-feed entry as a sale rather than a corpse
--- loot. `cp` is the gross copper received from the merchant; `count` is the
--- number of items sold (purely informational, used for the recent-feed
--- summary line).
local function recordSale(who, cp, count, source)
    if not who or who == '' then who = 'unknown' end
    cp    = tonumber(cp)    or 0
    count = tonumber(count) or 0
    if cp <= 0 then return end

    -- Same pause-respecting behavior as loot. AFK selling shouldn't pollute
    -- the per-hour rate any more than AFK looting does.
    if M.state.session.pausedAt and M.state.session.pausedAt > 0 then
        dbg('skipping sale record: session is paused')
        return
    end

    local s = M.state.session
    s.totalCp     = s.totalCp     + cp
    s.events      = s.events      + 1
    s.salesCp     = (s.salesCp     or 0) + cp
    s.salesEvents = (s.salesEvents or 0) + 1
    -- Sales aren't a single-loot event in the gameplay sense, so we
    -- intentionally do NOT update biggestCp/biggestWho with sale totals --
    -- that stat is meant to highlight a juicy corpse, not a stack vendor.
    s.byChar[who] = s.byChar[who] or { cp = 0, events = 0, lastAt = 0 }
    s.byChar[who].cp     = s.byChar[who].cp     + cp
    s.byChar[who].events = s.byChar[who].events + 1
    s.byChar[who].lastAt = os.time()

    -- Lifetime is local to this character; only credit when *this* char sold.
    if who == MyName then
        M.state.lifetime.totalCp     = M.state.lifetime.totalCp     + cp
        M.state.lifetime.events      = M.state.lifetime.events      + 1
        M.state.lifetime.salesCp     = (M.state.lifetime.salesCp     or 0) + cp
        M.state.lifetime.salesEvents = (M.state.lifetime.salesEvents or 0) + 1
        M.state.lifetime.byChar[who] = (M.state.lifetime.byChar[who] or 0) + cp
        markStateDirty()
    end

    -- Decompose the gross copper into a pp/gp/sp/cp breakdown so the recent
    -- feed renders consistent with looted entries. The view's existing code
    -- reads pp/gp/sp/ccp from each recent row.
    local pp = math.floor(cp / CP_PER_PP)
    local rem = cp - pp * CP_PER_PP
    local gp = math.floor(rem / CP_PER_GP); rem = rem - gp * CP_PER_GP
    local sp = math.floor(rem / CP_PER_SP); rem = rem - sp * CP_PER_SP
    local ccp = rem

    -- Tag the corpse column with [SOLD xN] so the recent feed makes the
    -- difference between a corpse loot and a merchant sale obvious.
    local corpseTag = (count > 0)
        and string.format('[SOLD x%d]', count)
        or  '[SOLD]'

    table.insert(M.state.recent, 1, {
        at        = os.date('%H:%M:%S'),
        who       = who,
        cp        = cp,
        breakdown = { pp = pp, gp = gp, sp = sp, cp = ccp },
        corpse    = corpseTag,
        source    = source or 'sale',
    })
    while #M.state.recent > M.state.recentMax do
        table.remove(M.state.recent)
    end

    dbg('recorded SALE %s for %s (x%d items, %s)',
        formatCopper(cp), who, count, source or 'sale')

    saveLiveState(false)
end

-- =============================================================================
-- Actors: cross-instance state mirroring
-- =============================================================================

local function sendActorMessage(payload)
    if not M.state.actorReady or not M.actor then return false end
    local ok = pcall(function() M.actor:send(payload) end)
    return ok
end

function M.creditSale(cp, count, opts)
    opts = opts or {}
    cp = tonumber(cp) or 0
    count = tonumber(count) or 0
    if cp <= 0 then return false, 'No sale copper to credit' end

    local who = tostring(opts.who or MyName or 'unknown')
    local source = tostring(opts.source or 'local')
    recordSale(who, cp, count, source)
    sendActorMessage({
        kind = 'sale',
        server = MyServer,
        who = who,
        cp = cp,
        count = count,
        source = source,
        ts = os.time(),
    })
    saveLiveState(true)

    if opts.quiet ~= true then
        info('credited %s sold from %s stack%s.',
            formatCopper(cp), count, count == 1 and '' or 's')
    end
    return true
end

local function registerActor()
    if not Actors then
        info('Actors module not present — using EQBC chat fallback only.')
        return
    end
    local ok, actor = pcall(Actors.register, 'turbogains', function(message)
        local m = message()
        if type(m) ~= 'table' then return end
        if m.server and m.server ~= MyServer then return end
        -- Ignore our own broadcasts (we already recorded locally).
        if m.who == MyName and (m.source == 'local' or m.source == 'wares') then return end
        if m.kind == 'loot' then
            recordLoot(m.who, tonumber(m.cp) or 0, m.breakdown, m.corpse, 'actor')
        elseif m.kind == 'sale' then
            -- Mirror a merchant sale from the looter character's TurboLoot
            -- macro. Only one box runs sell mode at a time, so we don't have
            -- to worry about double-counting from multiple sellers.
            recordSale(m.who, tonumber(m.cp) or 0, tonumber(m.count) or 0, 'actor')
        elseif m.kind == 'reset_group' and m.who ~= MyName then
            -- Silent reset triggered by another character's /turbomoney reset group
            M.state.session = {
                startedAt = os.time(), pausedAt = 0, pausedAccum = 0,
                totalCp = 0, events = 0,
                biggestCp = 0, biggestWho = '', byChar = {},
                salesCp = 0, salesEvents = 0,
            }
            M.state.recent = {}
            resetXP()
            saveLiveState(true)
            info('\agSession totals reset by %s.\ax', tostring(m.who))
        elseif m.kind == 'pause_session' and m.who ~= MyName then
            -- Mirror a peer's pause without re-broadcasting (would loop).
            if not (M.state.session.pausedAt and M.state.session.pausedAt > 0) then
                sampleXP(true)
                M.state.session.pausedAt = os.time()
                saveLiveState(true)
                info('\ayTimer paused by %s.\ax', tostring(m.who))
            end
        elseif m.kind == 'resume_session' and m.who ~= MyName then
            local s = M.state.session
            if s.pausedAt and s.pausedAt > 0 then
                local pausedFor = os.time() - s.pausedAt
                if pausedFor < 0 then pausedFor = 0 end
                s.pausedAccum = (s.pausedAccum or 0) + pausedFor
                s.pausedAt    = 0
                sampleXP(true)
                saveLiveState(true)
                info('\agTimer resumed by %s (was paused %ds).\ax',
                    tostring(m.who), pausedFor)
            end
        end
    end)
    if ok then
        M.actor = actor
        M.state.actorReady = true
        dbg('actor registered')
    else
        info('\arFailed to register Actors handler: %s\ax', tostring(actor))
    end
end

-- =============================================================================
-- mq.event handlers
-- =============================================================================

--- Two broad patterns cover the EQ loot lines we care about:
---   "You receive ... [coin words] from [the corpse|a corpse|<mob>'s corpse]."
---   "[--]You have looted ... [coin words] from <corpse>[--]"
--- The parser does the actual coin-vs-not-coin decision; using only two
--- patterns avoids one line being matched (and fired) multiple times when
--- it contains more than one coin denomination.
local LOOT_EVENT_PATTERNS = {
    'You receive #*#from #*#corpse#*#',
    '#*#You have looted #*#from #*#corpse#*#',
}

-- Dedupe state. Some MQ Lua builds fire mq.event callbacks more than once
-- for the same chat line (greedy/non-greedy wildcard ambiguity, color-code
-- variants of the same line, etc.). We dedupe on two levels: identical
-- text within a window, and identical parsed amount within a window. A
-- real second loot of the EXACT same coin amount within 1.5s is improbable
-- enough that suppressing it is the right tradeoff.
local lastLine, lastLineMs = nil, 0
local lastAmountCp, lastAmountMs = 0, 0
local DEDUPE_MS = 1500

local function onLocalMoneyEvent(line)
    -- HARD GUARD: reject our own EQBC broadcast when it echoes back as chat.
    -- /e3bc adds a "[E3] HH:MM:SS <CharName> ..." prefix when other boxes
    -- (and ourselves) see it, and that line still contains "looted ...
    -- from the corpse" plus coin words, so it would match our patterns.
    -- This guard breaks the feedback loop dead.
    if line:find('[TurboGains]', 1, true) or line:find('[TurboMoney]', 1, true) then
        dbg('reject: own broadcast echo')
        return
    end
    -- Also reject anything that looks like a channel echo. A real first-person
    -- "You receive X from corpse" line never contains '<Name>' or '[E3]' or
    -- '[BC]' tags. If we see those, it's a chat broadcast we're hearing from
    -- another character, and that character's own tracker already counted it.
    if line:find('<%a+>') or line:find('%[E3%]')
        or line:find('%[BC%]') or line:find('%[BCA%]') then
        dbg('reject: channel echo')
        return
    end

    local nowMs = (mq.gettime and mq.gettime()) or (os.time() * 1000)
    if line == lastLine and (nowMs - lastLineMs) < DEDUPE_MS then
        dbg('dedup TEXT: %dms ago', nowMs - lastLineMs)
        return
    end
    lastLine, lastLineMs = line, nowMs

    dbg('event line: %s', tostring(line))
    local cp, breakdown = parseMoneyLine(line)
    if cp <= 0 then
        dbg('parser rejected line (not a loot or 0 amount)')
        return
    end
    breakdown = breakdown or {}

    -- Second-level dedupe: same parsed amount within window. Catches
    -- variants where the byte-level line differs (color codes, whitespace)
    -- but the meaning is identical to the prior fire.
    if cp == lastAmountCp and (nowMs - lastAmountMs) < DEDUPE_MS then
        dbg('dedup AMOUNT: %dcp %dms ago', cp, nowMs - lastAmountMs)
        return
    end
    lastAmountCp, lastAmountMs = cp, nowMs

    -- Get the actual NPC name. EQ's loot line on most servers just says
    -- "from the corpse", which is useless. The looter targets the corpse
    -- to loot it, so mq.TLO.Target.CleanName() at the moment we see the
    -- "You receive ..." line is the mob's name (e.g. "a decaying skeleton's
    -- corpse"). Strip the trailing "'s corpse" / "`s corpse" suffix to leave
    -- just the mob name.
    local corpse = ''
    local ok, t = pcall(function() return mq.TLO.Target.CleanName() end)
    if ok and type(t) == 'string' and t ~= '' then
        corpse = t:gsub("['`]s corpse$", "")
                  :gsub("'s corpse$", "")
                  :gsub("`s corpse$", "")
    end
    -- Fallback: try to grab a name from the loot line itself for servers
    -- that DO embed the npc name (e.g. "from a decaying skeleton's corpse").
    if corpse == '' or corpse == 'the corpse' or corpse == 'a corpse' then
        local fromLine = line:match("from%s+(.-)'s corpse")
                      or line:match("from%s+(.-)`s corpse")
        if fromLine and fromLine ~= '' then corpse = fromLine end
    end
    -- Final fallback: both target-read and line-regex failed (looter
    -- already retargeted before the chat event fired, OR the server emits
    -- a plain "from the corpse" line with no name to scrape). Surface the
    -- failure in the feed instead of leaving the column blank so users can
    -- see which entries lost the name vs. which were captured.
    if corpse == '' or corpse == 'the corpse' or corpse == 'a corpse' then
        corpse = 'too fast'
    end

    -- Record locally first so this character's UI updates instantly.
    recordLoot(MyName, cp, breakdown, corpse, 'local')

    -- Mirror to other TurboGains instances via Actors (no chat spam).
    sendActorMessage({
        kind = 'loot', server = MyServer,
        who  = MyName, cp = cp, breakdown = breakdown,
        corpse = corpse, zone = currentZoneName(), source = 'local', ts = os.time(),
    })

    -- Announce on EQBC so the driving character SEES it on their chat panel.
    if M.config.announce and (breakdown.pp or 0) >= (M.config.minAnnouncePP or 0) then
        local channel = M.config.announceChannel or '/bc'
        local sessTotal = formatCopper(M.state.session.totalCp)
        mq.cmdf('%s %s %s looted %s%s | session: %s',
            channel, BC_TAG, MyName, formatBreakdown(breakdown),
            (corpse ~= '' and (' from ' .. corpse)) or '',
            sessTotal)
        dbg('announced via %s', channel)
    end
end

-- Dedupe map for the BC echo path: prevents double-counting when both
-- Actors and the chat scrape arrive for the same loot event.
local recentEcho = {}
local ECHO_DEDUPE_MS = 4000
local lastAutoSnapshotZone = ''

-- Safe zones: session timer auto-pauses on entry, auto-resumes on exit.
local SAFE_ZONES = {
    poknowledge = true, nexus = true, potranquility = true,
    bazaar = true, guildhall = true, guildlobby = true,
    freportw = true, freporte = true,
}
local autoPausedForSafeZone = false

local function onAnnounceEcho(line)
    line = tostring(line or ''):gsub('%[TurboGains%]', '[TurboMoney]')
    -- Prune stale dedupe entries to prevent unbounded growth over long sessions.
    do
        local nowPrune = (mq.gettime and mq.gettime()) or (os.time() * 1000)
        for k, ts in pairs(recentEcho) do
            if (nowPrune - ts) >= ECHO_DEDUPE_MS then recentEcho[k] = nil end
        end
    end
    -- Sale shape FIRST (so we don't accidentally match a "sold" line with
    -- the looted parser if both keywords ever appear in the same string):
    --   "[TurboGains] <name> sold <N> items for <breakdown> | session: ..."
    --   "[TurboGains] <name> sold <N> items for <breakdown>"
    -- Sales come from TurboLoot.mac. Unlike loot, they have no in-engine
    -- "local first then mirror" path because the macro is the only producer
    -- -- so we DO credit when who == MyName for sales. The recentEcho map
    -- still dedupes any duplicate broadcasts within the window.
    do
        local sWho, sCount, sBreakdown = line:match(
            '%[TurboGains%]%s+(%S+)%s+sold%s+(%d+)%s+items?%s+for%s+([^|]+)%s*|')
        if not sWho then
            sWho, sCount, sBreakdown = line:match(
                '%[TurboGains%]%s+(%S+)%s+sold%s+(%d+)%s+items?%s+for%s+(.+)$')
        end
        if sWho and sBreakdown then
            local cp = parseAnnounceBreakdown(sBreakdown or '')
            if cp > 0 then
                local key = string.format('SALE|%s|%d', sWho, cp)
                local nowMs = (mq.gettime and mq.gettime()) or (os.time() * 1000)
                if not (recentEcho[key]
                        and (nowMs - recentEcho[key]) < ECHO_DEDUPE_MS) then
                    recentEcho[key] = nowMs
                    recordSale(sWho, cp, tonumber(sCount) or 0, 'echo')
                end
            end
            return  -- sale handled; do NOT fall through to loot parser
        end
    end

    -- Two announce-line shapes we need to handle:
    --   With session suffix (full engine on the looter):
    --     "[TurboGains] <name> looted <breakdown> [from <c>] | session: ..."
    --   Without session suffix (tiny announcer on a boxed character):
    --     "[TurboGains] <name> looted <breakdown> [from <c>]"
    -- Try the suffixed form first, then fall back to the bare form.
    local who, breakdownStr = line:match(
        '%[TurboGains%]%s+(%S+)%s+looted%s+([^|]+)%s*|')
    if not who then
        who, breakdownStr = line:match(
            '%[TurboGains%]%s+(%S+)%s+looted%s+(.+)$')
    end
    if not who or not breakdownStr then return end
    if who == MyName then return end                 -- already recorded locally
    -- NOTE: we used to skip this handler when Actors was ready. That
    -- assumption breaks when boxed chars run the tiny loot_announce.lua
    -- which has NO Actors traffic -- chat is the ONLY signal for them.
    -- The recentEcho dedupe below catches any overlap with Actors traffic.

    local cp, breakdown = parseAnnounceBreakdown(breakdownStr or '')
    if cp <= 0 then return end

    local key = string.format('%s|%d', who, cp)
    local nowMs = (mq.gettime and mq.gettime()) or (os.time() * 1000)
    if recentEcho[key] and (nowMs - recentEcho[key]) < ECHO_DEDUPE_MS then return end
    recentEcho[key] = nowMs

    local corpse = (breakdownStr or ''):match('from%s+(.-)%s*$') or ''
    recordLoot(who, cp, breakdown, corpse, 'echo')
end

local function bindEvents()
    if M.state.eventsBound then return end
    for i, pat in ipairs(LOOT_EVENT_PATTERNS) do
        local ok, err = pcall(function()
            mq.event('TurboGainsLoot' .. i, pat, onLocalMoneyEvent)
        end)
        if not ok then dbg('mq.event #%d failed: %s', i, tostring(err)) end
    end
    pcall(function()
        mq.event('TurboGainsEcho', '#*#[TurboGains]#*#', onAnnounceEcho)
    end)
    pcall(function()
        mq.event('TurboGainsMoneyEcho', '#*#[TurboMoney]#*#', onAnnounceEcho)
    end)
    M.state.eventsBound = true
    dbg('events bound (%d patterns + 1 echo)', #LOOT_EVENT_PATTERNS)
end

local function unbindEvents()
    if not M.state.eventsBound then return end
    for i = 1, #LOOT_EVENT_PATTERNS do
        pcall(function() mq.unevent('TurboGainsLoot' .. i) end)
    end
    pcall(function() mq.unevent('TurboGainsEcho') end)
    pcall(function() mq.unevent('TurboGainsMoneyEcho') end)
    M.state.eventsBound = false
end

-- =============================================================================
-- Public ops
-- =============================================================================

function M.resetSession(broadcast)
    M.state.session = {
        startedAt = os.time(), pausedAt = 0, pausedAccum = 0,
        totalCp = 0, events = 0,
        biggestCp = 0, biggestWho = '', byChar = {},
        salesCp = 0, salesEvents = 0,
    }
    M.state.recent = {}
    resetXP()
    info('\agSession totals reset.\ax')
    if broadcast then
        sendActorMessage({ kind = 'reset_group', server = MyServer, who = MyName })
    end
    saveLiveState(true)
end

function M.resetLifetime()
    M.state.lifetime = { totalCp = 0, events = 0, byChar = {},
                         salesCp = 0, salesEvents = 0 }
    saveState()
    saveLiveState(true)
    info('\arLifetime totals reset for %s.\ax', MyName)
end

--- Pause the session timer. Records the wall time so a later resume can
--- compute how long we were paused for and add it to pausedAccum, keeping
--- the elapsed display continuous from the user's perspective.
function M.pauseSession(broadcast)
    autoPausedForSafeZone = false  -- manual pause cancels safe-zone auto-resume
    if M.state.session.pausedAt and M.state.session.pausedAt > 0 then
        info('Session timer is already paused.')
        return
    end
    sampleXP(true)
    M.state.session.pausedAt = os.time()
    saveLiveState(true)
    info('\ayTimer paused.\ax')
    if broadcast then
        sendActorMessage({ kind = 'pause_session', server = MyServer, who = MyName })
    end
end

function M.resumeSession(broadcast)
    local s = M.state.session
    if not s.pausedAt or s.pausedAt == 0 then
        info('Session timer is already running.')
        return
    end
    local pausedFor = os.time() - s.pausedAt
    if pausedFor < 0 then pausedFor = 0 end
    s.pausedAccum = (s.pausedAccum or 0) + pausedFor
    s.pausedAt    = 0
    sampleXP(true)
    saveLiveState(true)
    info('\agTimer resumed (was paused %ds).\ax', pausedFor)
    if broadcast then
        sendActorMessage({ kind = 'resume_session', server = MyServer, who = MyName })
    end
end

function M.togglePause(broadcast)
    if M.state.session.pausedAt and M.state.session.pausedAt > 0 then
        M.resumeSession(broadcast)
    else
        M.pauseSession(broadcast)
    end
end

function M.printReport()
    local s = M.state.session
    local l = M.state.lifetime
    info('\au==== Session ====\ax')
    printf('  Total: \ag%s\ax over \ay%d\ax events',
        formatCopper(s.totalCp), s.events)
    -- Break out looted-from-corpses vs merchant sales when there's been any
    -- selling this session, so the user sees how the total decomposes.
    local salesCp = tonumber(s.salesCp) or 0
    if salesCp > 0 then
        local lootedCp = math.max(0, (s.totalCp or 0) - salesCp)
        local lootedEv = math.max(0, (s.events or 0) - (s.salesEvents or 0))
        printf('    \ay-> Looted:\ax \ag%s\ax (%d events)',
            formatCopper(lootedCp), lootedEv)
        printf('    \ay-> Sold:  \ax \ag%s\ax (%d sells)',
            formatCopper(salesCp), s.salesEvents or 0)
    end
    if s.biggestCp > 0 then
        printf('  Biggest single loot: \ag%s\ax by \at%s\ax',
            formatCopper(s.biggestCp), s.biggestWho)
    end
    local rows = {}
    for name, info_ in pairs(s.byChar) do
        table.insert(rows, { name = name, cp = info_.cp, events = info_.events })
    end
    table.sort(rows, function(a, b) return a.cp > b.cp end)
    for _, r in ipairs(rows) do
        printf('    \at%-16s\ax \ag%-22s\ax (%d loots)',
            r.name, formatCopper(r.cp), r.events)
    end
    info('\au==== Lifetime (%s) ====\ax', MyName)
    printf('  Total: \ag%s\ax over \ay%d\ax events',
        formatCopper(l.totalCp), l.events)
    if (l.salesCp or 0) > 0 then
        printf('    \ay-> Sold lifetime:\ax \ag%s\ax (%d sells)',
            formatCopper(l.salesCp), l.salesEvents or 0)
    end
end

local function pct(value)
    return string.format('%.3f%%', tonumber(value) or 0)
end

local function ratePct(value)
    return string.format('%.2f%%/hr', tonumber(value) or 0)
end

local function printXPStatus()
    sampleXP(true)
    local xs = M.state.xp.session
    info('XP: \ag%s\ax gained (\ag%s\ax) | AA: \at%s\ax gained (\at%s\ax) | runtime: \ay%s\ax | tracking=%s',
        pct(xs.xpGained or 0), ratePct(xs.xpPerHour or 0),
        pct(xs.aaGained or 0), ratePct(xs.aaPerHour or 0),
        formatDuration(sessionSeconds()), tostring(M.state.xp.tracking))
end

local function parseArgs(...)
    local raw = { ... }
    if #raw == 1 and type(raw[1]) == 'string' and raw[1]:find('%s') then
        local split = {}
        for word in tostring(raw[1] or ''):gmatch('%S+') do
            table.insert(split, word)
        end
        return split
    end
    return raw
end

local function handleXPCommand(...)
    local args = parseArgs(...)
    local sub = (args[1] or ''):lower()

    if sub == '' or sub == 'status' or sub == 'show' or sub == 'full' or sub == 'mini' then
        printXPStatus()
        if sub == 'show' or sub == 'full' or sub == 'mini' then
            info('XP/AA UI is embedded in the TurboGains tab and mini line.')
        end
    elseif sub == 'on' or sub == 'resume' then
        M.state.xp.tracking = true
        sampleXP(true)
        saveXPSettings()
        saveLiveState(true)
        info('\agXP tracking resumed.\ax')
    elseif sub == 'off' or sub == 'pause' then
        sampleXP(true)
        M.state.xp.tracking = false
        saveXPSettings()
        saveLiveState(true)
        info('\ayXP tracking paused.\ax')
    elseif sub == 'reset' then
        resetXP()
        saveLiveState(true)
        info('\agXP session reset.\ax')
    elseif sub == 'snapshot' or sub == 'snap' then
        addXPSnapshot()
        info('\agXP snapshot saved.\ax')
    elseif sub == 'clear' then
        M.state.xp.snapshots = {}
        saveXPSnapshots()
        saveLiveState(true)
        info('\ayXP snapshots cleared.\ax')
    elseif sub == 'sample' then
        sampleXP(true)
        saveLiveState(true)
        printXPStatus()
    elseif sub == 'quit' or sub == 'exit' or sub == 'stop' then
        M.running = false
    elseif sub == 'help' then
        info('XP commands:')
        printf('  /txp status|show            -- print XP/AA status')
        printf('  /txp on|off                 -- resume/pause XP sampling')
        printf('  /txp reset                  -- reset XP/AA session')
        printf('  /txp snapshot               -- save XP/AA snapshot')
        printf('  /txp clear                  -- clear XP/AA snapshots')
        printf('  /txp quit                   -- stop combined tracker')
    else
        info('unknown XP subcommand "%s" -- /txp help', tostring(sub))
    end
end


-- =============================================================================
-- Slash command
-- =============================================================================

local function handleSlash(...)
    local args = parseArgs(...)
    local sub = (args[1] or ''):lower()

    if sub == '' or sub == 'status' then
        local salesCp = tonumber(M.state.session.salesCp) or 0
        local salesEv = tonumber(M.state.session.salesEvents) or 0
        if salesCp > 0 then
            info('session: \ag%s\ax (%d events, sold \ag%s\ax in %d sells) | lifetime (%s): \ag%s\ax | announce=%s | actors=%s',
                formatCopper(M.state.session.totalCp), M.state.session.events,
                formatCopper(salesCp), salesEv,
                MyName, formatCopper(M.state.lifetime.totalCp),
                tostring(M.config.announce),
                M.state.actorReady and 'OK' or 'OFF')
        else
            info('session: \ag%s\ax (%d events) | lifetime (%s): \ag%s\ax | announce=%s | actors=%s',
                formatCopper(M.state.session.totalCp), M.state.session.events,
                MyName, formatCopper(M.state.lifetime.totalCp),
                tostring(M.config.announce),
                M.state.actorReady and 'OK' or 'OFF')
        end
    elseif sub == 'show' or sub == 'open' or sub == 'window' then
        -- Back-compat with older UI/buttons. The engine is headless now;
        -- Turbo's Actions page reads the live-state file and renders summary.
        saveLiveState(true)
        info('UI is embedded in Turbo Actions. Session: \ag%s\ax (%d events)',
            formatCopper(M.state.session.totalCp), M.state.session.events)
    elseif sub == 'report' then
        M.printReport()
    elseif sub == 'reset' then
        local what = (args[2] or 'session'):lower()
        if what == 'session' then
            M.resetSession(false)
        elseif what == 'group' then
            M.resetSession(true)
        elseif what == 'lifetime' then
            if (args[3] or ''):lower() == 'confirm' then
                M.resetLifetime()
            else
                info('\arUse\ax \ag/turbomoney reset lifetime confirm\ax \arto wipe %s lifetime totals.\ax', MyName)
            end
        else
            info('usage: /turbomoney reset session|group|lifetime')
        end
    elseif sub == 'pause' then
        M.pauseSession(true)
    elseif sub == 'resume' or sub == 'unpause' then
        M.resumeSession(true)
    elseif sub == 'announce' then
        local v = (args[2] or ''):lower()
        if v == 'on' or v == '1' or v == 'true' then
            M.config.announce = true
        elseif v == 'off' or v == '0' or v == 'false' then
            M.config.announce = false
        else
            M.config.announce = not M.config.announce
        end
        info('announce=%s', tostring(M.config.announce))
    elseif sub == 'channel' then
        if args[2] then
            M.config.announceChannel = args[2]
            info('announce channel = %s', args[2])
        else
            info('current channel = %s', tostring(M.config.announceChannel))
        end
    elseif sub == 'debug' then
        M.config.debug = not M.config.debug
        info('debug=%s', tostring(M.config.debug))
    elseif sub == 'test' then
        -- Inject a fake loot line through the same code path as a real event
        -- so you can verify announce + tracking without waiting for a corpse.
        info('\ayinjecting test loot...\ax')
        onLocalMoneyEvent('You receive 5 platinum, 3 gold, 2 silver and 1 copper from the corpse.')
    elseif sub == 'sold' then
        -- Public entry point used by TurboLoot.mac to credit merchant income.
        -- Usage:
        --   /turbomoney sold <copperAmount> [itemCount]
        -- TurboLoot calls this exactly once per AutoSell run with the total
        -- copper across all items sold and the total item count, so the
        -- group session total reflects vendor income alongside corpse loot.
        local cp    = tonumber(args[2]) or 0
        local count = tonumber(args[3]) or 0
        if cp <= 0 then
            info('usage: /turbomoney sold <copperAmount> [itemCount]')
        else
            -- Credit locally first so this character's UI updates instantly.
            recordSale(MyName, cp, count, 'local')
            -- Always print a visible confirmation so it's easy to see in chat
            -- that the macro -> lua bridge actually fired. Without this it's
            -- impossible to tell from the chat log whether the credit landed.
            info('credited \ag%s\ax from \ay%d\ax sold item(s); session total now \ag%s\ax',
                formatCopper(cp), count, formatCopper(M.state.session.totalCp))
            -- Mirror to other TurboGains instances via Actors so the rest
            -- of the boxes' Money tabs see the updated group total.
            sendActorMessage({
                kind = 'sale', server = MyServer,
                who  = MyName, cp = cp, count = count,
                source = 'local', ts = os.time(),
            })
            -- EQBC announce so the driver sees it on chat. Same channel /
            -- enable-toggle as loot announces; we DO NOT route this through
            -- the usual loot-announce text because that would round-trip
            -- through onAnnounceEcho and double-count.
            if M.config.announce then
                local channel = M.config.announceChannel or '/bc'
                mq.cmdf('%s %s %s sold %d items for %s | session: %s',
                    channel, BC_TAG, MyName, count, formatCopper(cp),
                    formatCopper(M.state.session.totalCp))
            end
            -- Force a live-state flush so the UI updates immediately even if
            -- the rate-limit window in saveLiveState would otherwise defer it.
            saveLiveState(true)
        end
    elseif sub == 'where' or sub == 'path' then
        -- Diagnostic: print where the engine writes its live-state file so
        -- it can be cross-checked against where the embedded view reads.
        info('live file: %s', liveFile)
        info('state dir: %s', stateDir)
        local f = io.open(liveFile, 'r')
        if f then
            f:close()
            info('\agfile exists\ax')
        else
            info('\arfile NOT found at that path\ax')
        end
        -- Force a save right now so the user can re-check.
        saveLiveState(true)
        info('forced live save -- check the path above again')
    elseif sub == 'stop' or sub == 'quit' or sub == 'exit' then
        M.running = false
    elseif sub == 'help' then
        info('commands:')
        printf('  /turbomoney                    -- quick status')
        printf('  /turbomoney status             -- quick status')
        printf('  /turbomoney show               -- embedded UI status/back-compat')
        printf('  /turbomoney report             -- per-character breakdown')
        printf('  /turbomoney where              -- print live-state file path (diag)')
        printf('  /turbomoney reset session      -- clear local session totals')
        printf('  /turbomoney reset group        -- clear shared session everywhere')
        printf('  /turbomoney reset lifetime confirm -- wipe %s lifetime', MyName)
        printf('  /turbomoney pause              -- pause timer + stop counting loots (everywhere)')
        printf('  /turbomoney resume             -- resume timer + counting loots')
        printf('  /turbomoney announce on|off    -- toggle EQBC announce')
        printf('  /turbomoney channel /bc        -- set announce channel')
        printf('  /turbomoney debug              -- toggle debug logging')
        printf('  /turbomoney test               -- inject a fake loot line')
        printf('  /turbomoney sold <cp> [count]  -- credit merchant income (called by TurboLoot.mac)')
        printf('  /txp help                      -- XP/AA tracking commands')
        printf('  /turbostats status             -- combined coin + XP/AA status')
        printf('  /turbomoney stop               -- exit this script')
    else
        info('unknown subcommand "%s" -- /turbomoney help', tostring(sub))
    end
end

local function handleStatsCommand(...)
    local args = parseArgs(...)
    local sub = (args[1] or 'status'):lower()

    if sub == '' or sub == 'status' then
        handleSlash('status')
        printXPStatus()
    elseif sub == 'reset' and (args[2] or ''):lower() == 'xp' then
        handleXPCommand('reset')
    elseif sub == 'reset' and (args[2] or ''):lower() == 'money' then
        M.resetSession(false)
    elseif sub == 'reset' and ((args[2] or ''):lower() == 'all' or (args[2] or '') == '') then
        M.resetSession(false)
        resetXP()
        saveLiveState(true)
        info('\agCoin and XP sessions reset.\ax')
    elseif sub == 'pause' then
        M.pauseSession(true)
    elseif sub == 'resume' or sub == 'unpause' then
        M.resumeSession(true)
    elseif sub == 'snapshot' then
        addXPSnapshot()
    elseif sub == 'stop' or sub == 'quit' or sub == 'exit' then
        M.running = false
    elseif sub == 'help' then
        info('TurboGains compatibility commands:')
        printf('  /turbostats status            -- coin + XP/AA status')
        printf('  /turbostats reset all|xp|money -- reset sessions')
        printf('  /turbostats pause|resume      -- pause/resume shared session timer')
        printf('  /turbostats snapshot          -- save XP/AA snapshot')
        printf('  /turbostats stop              -- stop combined tracker')
    else
        info('unknown stats subcommand "%s" -- /turbostats help', tostring(sub))
    end
end

local function boolFromArg(value, current)
    local v = tostring(value or 'toggle'):lower()
    if v == 'on' or v == '1' or v == 'true' or v == 'yes' then return true end
    if v == 'off' or v == '0' or v == 'false' or v == 'no' then return false end
    return not current
end

local miniKeys = { xp = 'miniShowXP', aa = 'miniShowAA', coin = 'miniShowCoin', money = 'miniShowCoin', time = 'miniShowTime' }
local pageKeys = { xp = 'pageShowXP', aa = 'pageShowAA', coin = 'pageShowCoin', money = 'pageShowCoin', feed = 'pageShowFeed', loot = 'pageShowFeed', snapshots = 'pageShowSnapshots', snaps = 'pageShowSnapshots' }
local fieldKeys = {
    currentxp = 'xpShowCurrent', xpgained = 'xpShowGained', xprate = 'xpShowRate', xpeta = 'xpShowEta',
    currentaa = 'aaShowCurrent', aagained = 'aaShowGained', aarate = 'aaShowRate', aaeta = 'aaShowEta',
    level = 'metaShowLevel', aatotal = 'metaShowAA', runtime = 'metaShowRuntime', zone = 'metaShowZone',
    cointotal = 'coinShowTotal', cointime = 'coinShowTime', coinevents = 'coinShowEvents', coinbiggest = 'coinShowBiggest',
    coinperchar = 'coinShowPerChar', coinfeed = 'coinShowFeed', coinsnapshots = 'coinShowSnapshots',
}
local viewKeys = { compact = 'viewCompact', dashboard = 'viewCompact', full = 'viewCompact' }

local function setDisplayFlag(scope, key, value)
    local map = scope == 'mini' and miniKeys or (scope == 'page' and pageKeys or (scope == 'view' and viewKeys or fieldKeys))
    local cfgKey = map[(key or ''):lower()]
    if not cfgKey then
        info('usage: /turbogains %s <option> on|off|toggle', scope)
        return
    end
    if scope == 'view' and (key or ''):lower() == 'full' then
        M.config[cfgKey] = not boolFromArg(value, not M.config[cfgKey])
    else
        M.config[cfgKey] = boolFromArg(value, M.config[cfgKey])
    end
    saveXPSettings()
    saveLiveState(true)
    info('%s %s=%s', scope, key, tostring(M.config[cfgKey]))
end

local function handleGainsCommand(...)
    local args = parseArgs(...)
    local sub = (args[1] or 'status'):lower()
    local arg2 = (args[2] or ''):lower()

    if sub == '' or sub == 'status' then
        handleSlash('status')
        printXPStatus()
    elseif sub == 'xp' or sub == 'aa' then
        local action = arg2
        if action == 'pause' or action == 'off' then handleXPCommand('off')
        elseif action == 'resume' or action == 'on' then handleXPCommand('on')
        elseif action == 'reset' then handleXPCommand('reset')
        elseif action == 'snapshot' or action == 'snap' then handleXPCommand('snapshot')
        elseif action == 'clear' then handleXPCommand('clear')
        elseif action == '' or action == 'status' then handleXPCommand('status')
        else info('usage: /turbogains xp pause|resume|reset|snapshot|clear|status') end
    elseif sub == 'coin' or sub == 'money' then
        if arg2 == 'snapshot' or arg2 == 'snap' then addMoneySnapshot()
        elseif arg2 == 'reset' then M.resetSession(false)
        elseif arg2 == 'clear' then clearMoneySnapshots()
        elseif arg2 == 'report' or arg2 == 'status' or arg2 == '' then M.printReport()
        elseif arg2 == 'announce' then handleSlash('announce', args[3]); saveLiveState(true)
        else info('usage: /turbogains coin snapshot|clear|reset|report|announce on|off') end
    elseif sub == 'mini' then setDisplayFlag('mini', arg2, args[3])
    elseif sub == 'page' then setDisplayFlag('page', arg2, args[3])
    elseif sub == 'view' or sub == 'mode' then setDisplayFlag('view', arg2, args[3])
    elseif sub == 'field' or sub == 'display' then setDisplayFlag('field', arg2, args[3])
    elseif sub == 'snapshot' or sub == 'snap' then
        local what = arg2
        if what == 'coin' or what == 'money' then addMoneySnapshot()
        elseif what == 'xp' or what == 'aa' then addXPSnapshot()
        else addXPSnapshot(); addMoneySnapshot(); info('\agTurboGains snapshot saved.\ax') end
    elseif sub == 'clear' then
        if arg2 == 'xp' or arg2 == 'aa' then handleXPCommand('clear')
        elseif arg2 == 'coin' or arg2 == 'money' then clearMoneySnapshots()
        elseif arg2 == 'snapshots' or arg2 == 'snaps' or arg2 == 'all' or arg2 == '' then
            handleXPCommand('clear')
            clearMoneySnapshots()
            info('\ayTurboGains snapshots cleared.\ax')
        else info('usage: /turbogains clear snapshots|xp|coin') end
    elseif sub == 'reset' then
        if arg2 == 'xp' or arg2 == 'aa' then handleXPCommand('reset')
        elseif arg2 == 'coin' or arg2 == 'money' or arg2 == 'session' then M.resetSession(false)
        else M.resetSession(false); resetXP(); saveLiveState(true); info('\agTurboGains sessions reset.\ax') end
    elseif sub == 'pause' then M.pauseSession(true)
    elseif sub == 'resume' or sub == 'unpause' then M.resumeSession(true)
    elseif sub == 'sold' then handleSlash('sold', args[2], args[3])
    elseif sub == 'announce' or sub == 'channel' or sub == 'report' or sub == 'where' or sub == 'path' or sub == 'debug' or sub == 'test' then handleSlash(sub, args[2], args[3])
    elseif sub == 'prune' then
        local days = tonumber(arg2) or PRUNE_DEFAULT_DAYS
        pruneXPSnapshots(days)
        pruneMoneySnapshots(days)
    elseif sub == 'stop' or sub == 'quit' or sub == 'exit' then M.running = false
    elseif sub == 'help' then
        info('TurboGains commands:')
        printf('  /turbogains status')
        printf('  /turbogains xp pause|resume|reset|snapshot|clear|status')
        printf('  /turbogains coin snapshot|clear|reset|report|announce on|off')
        printf('  /turbogains mini xp|aa|coin|time on|off|toggle')
        printf('  /turbogains page xp|aa|coin|feed|snapshots on|off|toggle')
        printf('  /turbogains view compact|full on|off|toggle')
        printf('  /turbogains field currentxp|xpgained|xprate|xpeta|currentaa|aagained|aarate|aaeta|level|aatotal|runtime|zone|cointotal|cointime|coinevents|coinbiggest|coinperchar|coinfeed|coinsnapshots on|off|toggle')
        printf('  /turbogains snapshot all|xp|coin')
        printf('  /turbogains clear snapshots|xp|coin')
        printf('  /turbogains pause|resume|reset all|stop')
        printf('  /turbogains prune [days]  -- remove non-best snapshots older than N days (default 30)')
    else
        info('unknown TurboGains subcommand "%s" -- /turbogains help', tostring(sub))
    end
end

-- =============================================================================
-- Boot / shutdown / main loop
-- =============================================================================

local function boot()
    loadState()
    loadXPSettings()
    loadXPSnapshots()
    loadMoneySnapshots()
    resetXP()
    if mq.TLO.MQ2Mono and mq.TLO.MQ2Mono.Query then
        local ok, v = pcall(function() return mq.TLO.MQ2Mono.Query('e3,TurboGainsQuiet')() end)
        if ok and v then
            local s = tostring(v):lower()
            if s == 'true' or s == '1' or s == 'on' or s == 'yes' then
                M.config.announce = false
            end
        end
    end
    bindEvents()
    registerActor()
    pcall(function() mq.bind('/turbogains', handleGainsCommand) end)
    pcall(function() mq.bind('/tgains', handleGainsCommand) end)
    pcall(function() mq.bind('/turbomoney', handleSlash) end)
    pcall(function() mq.bind('/txp', handleXPCommand) end)
    pcall(function() mq.bind('/turboxp', handleXPCommand) end)
    pcall(function() mq.bind('/turbostats', handleGainsCommand) end)
    -- The engine runs headless now -- Turbo's main UI hosts the embedded
    -- Stats tab and mini-bar line by reading the live-state file we write.
    saveLiveState(true)
    info('\agTurboGains online for %s on %s -- /turbogains help\ax', MyName, MyServer)
    info('\ayBound %d loot patterns. Money + XP/AA UI lives in the TurboGains tab.\ax',
        #LOOT_EVENT_PATTERNS)
end

local function shutdown()
    sampleXP(true)
    flushStateIfDue(true)
    saveXPSettings()
    saveXPSnapshots()
    saveMoneySnapshots()
    saveLiveState(true)
    unbindEvents()
    pcall(function() mq.unbind('/turbogains') end)
    pcall(function() mq.unbind('/tgains') end)
    pcall(function() mq.unbind('/turbomoney') end)
    pcall(function() mq.unbind('/txp') end)
    pcall(function() mq.unbind('/turboxp') end)
    pcall(function() mq.unbind('/turbostats') end)
    if M.actor and M.actor.unregister then
        pcall(function() M.actor:unregister() end)
    end
    M.state.actorReady = false
    info('\arstopped.\ax')
    _G.TurboGainsEngineM = nil
end

-- Auto-snapshot on zone change. Defined here (after addXPSnapshot /
-- addMoneySnapshot) so there are no forward-reference issues. Called
-- from the main loop after sampleXPIfDue() has updated xs.currentZone.
local function checkZoneAutoSnapshot()
    if M.state.session.pausedAt and M.state.session.pausedAt > 0 then return end
    local xs = M.state.xp.session
    if not xs then return end
    local newZone = xs.currentZone
    if not newZone or newZone == '' then return end
    if lastAutoSnapshotZone == '' then
        lastAutoSnapshotZone = newZone
        return
    end
    if newZone == lastAutoSnapshotZone then return end
    -- Zone changed — snapshot if there is anything worth saving.
    local hasData = (xs.xpGained or 0) ~= 0 or (xs.aaGained or 0) ~= 0
        or (M.state.session.totalCp or 0) > 0
    local oldZone = lastAutoSnapshotZone
    lastAutoSnapshotZone = newZone   -- update BEFORE calling snapshot to prevent re-entry
    if hasData then
        addXPSnapshot()
        addMoneySnapshot()
        info('\ayAuto-snapshot: left %s\ax', oldZone)
    end
end

-- Auto-pause when entering a safe/lobby zone; auto-resume when leaving.
-- Only auto-resumes if WE paused it (doesn't override a manual pause).
local function checkSafeZonePause()
    local xs = M.state.xp.session
    if not xs then return end
    local zone = tostring(xs.currentZone or ''):lower():gsub(' ', '')
    if zone == '' then return end
    local inSafe = SAFE_ZONES[zone] == true
    local s = M.state.session
    local running = s.startedAt and s.startedAt > 0
    if not running then return end
    local isPaused = s.pausedAt and s.pausedAt > 0
    if inSafe and not isPaused then
        -- Entering safe zone while timer is running -> auto-pause
        M.pauseSession(false)
        autoPausedForSafeZone = true
        info('\ayAuto-paused: entered %s\ax', xs.currentZone or zone)
    elseif not inSafe and isPaused and autoPausedForSafeZone then
        -- Leaving safe zone and WE were the ones who paused -> auto-resume
        M.resumeSession(false)
        autoPausedForSafeZone = false
        info('\ayAuto-resumed: left safe zone\ax')
    end
end

boot()
_G.TurboGainsEngineM = M

-- CRITICAL: every tick must call mq.doevents() or our mq.event callbacks
-- never fire. This is the whole reason this script runs standalone instead
-- of being embedded in Turbo/init.lua's main loop.
while M.running do
    mq.doevents()
    sampleXPIfDue()
    checkZoneAutoSnapshot()
    checkSafeZonePause()
    flushStateIfDue(false)
    --- 15ms yields faster reaction to /turbogains stop (was 50ms worst-case
    --- latency before the loop noticed M.running = false). Still cheap vs
    --- XP sampling intervals.
    mq.delay(15)
end

shutdown()

return M
