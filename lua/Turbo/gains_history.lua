-- Persistent TurboGains activity journal.
--
-- This file is intentionally independent from the live TurboGains engine so
-- small tools can record lifetime/history events even when TurboGains is not
-- running.

local mq = require('mq')

local M = {}

local MyName = tostring((mq.TLO.Me.CleanName and mq.TLO.Me.CleanName()) or 'unknown')
local MyServer = tostring((mq.TLO.EverQuest.Server and mq.TLO.EverQuest.Server()) or 'unknown'):gsub(' ', '_')
local stateDir = string.format('%s/Turbo/Gains/%s', mq.configDir, MyServer)
local historyFile = string.format('%s/%s_activity_history.lua', stateDir, MyName)
local MAX_EVENTS = 250

local dirEnsured = false

local function ensureStateDir()
    if dirEnsured then return end
    dirEnsured = true

    local okLfs, lfs = pcall(require, 'lfs')
    if okLfs and lfs and lfs.mkdir then
        local sep = package.config:sub(1, 1) == '\\' and '\\' or '/'
        local accum = package.config:sub(1, 1) == '\\' and '' or '/'
        for part in stateDir:gmatch('[^/\\]+') do
            accum = (accum == '' or accum == '/') and (accum .. part) or (accum .. sep .. part)
            pcall(lfs.mkdir, accum)
        end
        return
    end

    local okFfi, ffi = pcall(require, 'ffi')
    if okFfi and package.config:sub(1, 1) == '\\' then
        if not _G.TurboGainsHistoryCreateDirectoryCdef then
            pcall(ffi.cdef, [[
                int CreateDirectoryA(const char* lpPathName, void* lpSecurityAttributes);
            ]])
            _G.TurboGainsHistoryCreateDirectoryCdef = true
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
            current = current == '' and part or (current .. '\\' .. part)
            pcall(function() ffi.C.CreateDirectoryA(current, nil) end)
        end
    end
end

local function loadHistory()
    local f = io.open(historyFile, 'r')
    if not f then return { version = 1, events = {} } end
    f:close()
    local ok, data = pcall(dofile, historyFile)
    if ok and type(data) == 'table' then
        data.events = type(data.events) == 'table' and data.events or {}
        return data
    end
    return { version = 1, events = {} }
end

local function writeValue(f, value, indent)
    indent = indent or ''
    local valueType = type(value)
    if valueType == 'table' then
        f:write('{\n')
        local childIndent = indent .. '  '
        for k, v in pairs(value) do
            if type(k) == 'number' then
                f:write(childIndent .. '[' .. tostring(k) .. '] = ')
            else
                f:write(childIndent .. '[' .. string.format('%q', tostring(k)) .. '] = ')
            end
            writeValue(f, v, childIndent)
            f:write(',\n')
        end
        f:write(indent .. '}')
    elseif valueType == 'number' then
        f:write(tostring(value))
    elseif valueType == 'boolean' then
        f:write(value and 'true' or 'false')
    else
        f:write(string.format('%q', tostring(value or '')))
    end
end

local function saveHistory(data)
    ensureStateDir()
    local f = io.open(historyFile, 'w')
    if not f then return false, 'unable to open history file for write' end
    f:write('-- TurboGains activity history. Auto-generated.\n')
    f:write('return ')
    writeValue(f, data, '')
    f:write('\n')
    f:close()
    return true
end

local function currentZone()
    local shortName = ''
    pcall(function() shortName = tostring(mq.TLO.Zone.ShortName() or '') end)
    if shortName ~= '' then return shortName end
    local longName = ''
    pcall(function() longName = tostring(mq.TLO.Zone.Name() or '') end)
    return longName
end

function M.append_event(event)
    if type(event) ~= 'table' then return false, 'event must be a table' end
    local data = loadHistory()
    local events = data.events
    local row = {}
    for k, v in pairs(event) do row[k] = v end
    row.version = 1
    row.at = tonumber(row.at) or os.time()
    row.time = tostring(row.time or os.date('%H:%M:%S', row.at))
    row.character = tostring(row.character or MyName)
    row.server = tostring(row.server or MyServer)
    row.zone = tostring(row.zone or currentZone())
    row.kind = tostring(row.kind or 'activity')
    row.source = tostring(row.source or 'unknown')
    table.insert(events, 1, row)
    while #events > MAX_EVENTS do table.remove(events) end
    data.version = 1
    data.savedAt = os.time()
    return saveHistory(data)
end

function M.events(limit)
    local data = loadHistory()
    local events = data.events or {}
    if not limit or limit <= 0 or limit >= #events then return events end
    local out = {}
    for i = 1, math.min(limit, #events) do out[#out + 1] = events[i] end
    return out
end

function M.file_path()
    return historyFile
end

return M
