local mq = require('mq')

local M = {}

local LEASE_SECONDS = 18
local HEARTBEAT_MS = 5000
local READ_TTL_MS = 900

local state = {
    path = nil,
    name = nil,
    server = nil,
    token = nil,
    lease = nil,
    lastRead = 0,
    lastHeartbeat = 0,
}

local function nowMs()
    if mq and mq.gettime then return mq.gettime() end
    return os.time() * 1000
end

local function nowSec()
    return math.floor(nowMs() / 1000)
end

local function trim(s)
    return (tostring(s or ''):match('^%s*(.-)%s*$') or '')
end

local function safeTlo(fn, fallback)
    local ok, val = pcall(fn)
    if ok and val ~= nil then return val end
    return fallback
end

local function resolveName()
    local clean = safeTlo(function()
        if mq.TLO.Me and mq.TLO.Me.CleanName then return mq.TLO.Me.CleanName() end
        return nil
    end, nil)
    clean = trim(clean)
    if clean ~= '' then return clean end
    local name = safeTlo(function() return mq.TLO.Me.Name() end, nil)
    name = trim(name)
    if name ~= '' then return name end
    return 'unknown'
end

local function resolveServer()
    local server = safeTlo(function()
        if mq.TLO.EverQuest and mq.TLO.EverQuest.Server then return mq.TLO.EverQuest.Server() end
        return nil
    end, nil)
    server = trim(server)
    if server ~= '' then return server end
    return trim(safeTlo(function() return mq.TLO.MacroQuest.Server() end, '')) or ''
end

local function resolvePath()
    local base = trim(safeTlo(function() return mq.TLO.MacroQuest.Path() end, ''))
    if base == '' then return nil end
    return base .. '\\Config\\Turbo_shared_control.lua'
end

local function writeLease(lease)
    if not state.path then return false end
    local f = io.open(state.path, 'w')
    if not f then return false end
    f:write('return {\n')
    f:write(string.format('  owner = %q,\n', tostring(lease.owner or '')))
    f:write(string.format('  server = %q,\n', tostring(lease.server or '')))
    f:write(string.format('  token = %q,\n', tostring(lease.token or '')))
    f:write(string.format('  updatedAt = %d,\n', tonumber(lease.updatedAt) or nowSec()))
    f:write(string.format('  expiresAt = %d,\n', tonumber(lease.expiresAt) or (nowSec() + LEASE_SECONDS)))
    f:write('  version = 1,\n')
    f:write('}\n')
    f:close()
    state.lease = lease
    state.lastRead = nowMs()
    return true
end

local function loadLease()
    if not state.path then return nil end
    local fn = loadfile(state.path)
    if not fn then return nil end
    local ok, tbl = pcall(fn)
    if ok and type(tbl) == 'table' then return tbl end
    return nil
end

function M.setup()
    state.path = state.path or resolvePath()
    state.name = state.name or resolveName()
    state.server = state.server or resolveServer()
    state.token = state.token or string.format('%s:%s:%d', state.server or '', state.name or '', nowSec())
end

function M.read(force)
    M.setup()
    local t = nowMs()
    if not force and state.lease and (t - state.lastRead) < READ_TTL_MS then
        return state.lease
    end
    state.lease = loadLease()
    state.lastRead = t
    return state.lease
end

function M.isExpired(lease)
    if not lease or not lease.expiresAt then return true end
    return (tonumber(lease.expiresAt) or 0) <= nowSec()
end

function M.isMine(lease)
    lease = lease or M.read(false)
    return lease and lease.token == state.token and lease.owner == state.name
end

function M.claim(force)
    M.setup()
    local lease = loadLease()
    if lease and not force and not M.isExpired(lease) and not M.isMine(lease) then
        state.lease = lease
        state.lastRead = nowMs()
        return false, lease
    end
    local t = nowSec()
    local nextLease = {
        owner = state.name,
        server = state.server,
        token = state.token,
        updatedAt = t,
        expiresAt = t + LEASE_SECONDS,
    }
    return writeLease(nextLease), nextLease
end

function M.heartbeat()
    M.setup()
    local t = nowMs()
    if (t - state.lastHeartbeat) < HEARTBEAT_MS then return end
    state.lastHeartbeat = t
    local lease = M.read(true)
    if M.isMine(lease) or M.isExpired(lease) then
        M.claim(true)
    end
end

function M.status(force)
    M.setup()
    M.heartbeat()
    local lease = M.read(force)
    local expired = M.isExpired(lease)
    local mine = (not expired) and M.isMine(lease)
    return {
        path = state.path,
        owner = (lease and trim(lease.owner)) or '',
        server = (lease and trim(lease.server)) or '',
        isOwner = mine == true,
        expired = expired == true,
        expiresAt = lease and lease.expiresAt or 0,
        updatedAt = lease and lease.updatedAt or 0,
        selfName = state.name,
    }
end

function M.canWrite()
    local st = M.status(false)
    return st.isOwner == true
end

function M.takeControl()
    local ok, lease = M.claim(true)
    return ok, lease
end

function M.describe()
    local st = M.status(false)
    if st.isOwner then return 'Control: this box' end
    if st.owner ~= '' and not st.expired then return 'Browse: ' .. st.owner end
    return 'Control: unclaimed'
end

return M
