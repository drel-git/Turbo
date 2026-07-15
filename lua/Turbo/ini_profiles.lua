-- Turbo/ini_profiles.lua
-- Shared turboloot INI profile file helpers for Turbo UI and Quick Start.

local mq = require('mq')
local Paths = require('Turbo.paths')

local M = {}

local function fileExists(path)
    local f = io.open(path, 'r')
    if f then f:close() return true end
    return false
end

local function joinPath(a, b)
    a = tostring(a or ''):gsub('[\\/]+$', '')
    return a .. '\\' .. tostring(b or '')
end

function M.readAll(path)
    local f = io.open(path, 'rb')
    if not f then return nil, 'could not open ' .. tostring(path) end
    local data = f:read('*a')
    f:close()
    return data
end

function M.writeAll(path, data)
    local f = io.open(path, 'wb')
    if not f then return false, 'could not write ' .. tostring(path) end
    f:write(data or '')
    f:close()
    return true
end

function M.findExampleIni(mqPath)
    mqPath = mqPath or tostring(mq.TLO.MacroQuest.Path() or '')
    if mqPath == '' then return nil end
    local candidates = {
        joinPath(joinPath(mqPath, 'Macros'), 'turbolootexample.ini'),
        joinPath(joinPath(mqPath, 'Macros'), 'TurboLootExample.ini'),
        joinPath(joinPath(mqPath, 'Config'), 'turbolootexample.ini'),
        joinPath(joinPath(mqPath, 'Config'), 'TurboLootExample.ini'),
    }
    for _, path in ipairs(candidates) do
        if fileExists(path) then return path end
    end
    return nil
end

function M.findExistingDefaultIni(mqPath)
    mqPath = mqPath or tostring(mq.TLO.MacroQuest.Path() or '')
    if mqPath == '' then return nil end
    local config = joinPath(joinPath(mqPath, 'Config'), 'turboloot.ini')
    if fileExists(config) then return config end
    local macros = joinPath(joinPath(mqPath, 'Macros'), 'turboloot.ini')
    if fileExists(macros) then return macros end
    return nil
end

function M.createDefaultIni()
    local mqPath = tostring(mq.TLO.MacroQuest.Path() or '')
    if mqPath == '' then
        return false, '', '', 'Could not resolve MacroQuest.Path.'
    end

    local existing = M.findExistingDefaultIni(mqPath)
    if existing then
        return true, existing, '', nil
    end

    local source = M.findExampleIni(mqPath)
    if not source then
        return false, '', '', 'Missing turbolootexample.ini in Macros or Config.'
    end

    local data, readErr = M.readAll(source)
    if not data then
        return false, '', source, readErr
    end

    local targets = {
        joinPath(joinPath(mqPath, 'Config'), 'turboloot.ini'),
        joinPath(joinPath(mqPath, 'Macros'), 'turboloot.ini'),
    }
    local lastErr = ''
    for _, target in ipairs(targets) do
        local ok, writeErr = M.writeAll(target, data)
        if ok then
            return true, target, source, nil, true
        end
        lastErr = writeErr or ''
    end

    return false, '', source, lastErr ~= '' and lastErr or 'Could not create turboloot.ini.'
end

function M.queueNavigation(tabName)
    local path = Paths.state_file('turbo_pending_nav.lua')
    if not path then return false end
    local f = io.open(path, 'w')
    if not f then return false end
    f:write(string.format('return %q\n', tostring(tabName or '')))
    f:close()
    return true
end

return M
