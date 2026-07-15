--[[
  Turbo Skip Queue Drain
  ----------------------
  @version lua/Turbo/skip_queue.lua 1.1.1

  Polls Config\TurboLoot_skip_queue.ini every POLL_INTERVAL_MS and appends any
  new rows into TurboLoot_skips_log.txt via Turbo/skip_log.append_event().

  Queue writer: TurboLoot.mac LogSkipListIniLine (two /ini calls per skip).
  Drain reader: this file (called from init.lua render loop + skip_journal_daemon).

  Why the odd read strategy:
    TurboLoot.mac's /ini writes hold an exclusive Windows file lock for the
    duration of the write. On a busy pull, this poller's io.open + f:lines()
    could land mid-write and blow up with "Permission denied" at the iterator
    boundary, killing the whole Lua script (1.0.0 behavior — see pic 2).
    1.1.0 fix: read the file in one shot with io.open + f:read('*a'), wrap the
    whole thing in pcall, and silently skip this poll on any failure. Next
    poll (500 ms later) will succeed once the writer releases the lock.
]]

local mq = require('mq')

local M = {}

local QUEUE_FILENAME = 'TurboLoot_skip_queue.ini'
local STATE_FILENAME = 'turbo_skip_queue_state.lua'
local POLL_INTERVAL_MS = 500
--- Back off polling briefly after a read failure — the macro is likely
--- mid-write on the queue INI. Anything >~100 ms is enough in practice.
local READ_FAIL_BACKOFF_MS = 250

local MAX_APPENDS_PER_POLL = 25
local lastPollTime = 0
local lastQueuePath = nil
local lastQueueSize = nil
local skipLogWriter = nil
local state = { offsets = {} }

local function getConfigDir()
    local mqPath = mq.TLO.MacroQuest.Path() or ''
    if mqPath == '' then return nil end
    return mqPath .. '\\Config'
end

local function getQueuePath()
    local dir = getConfigDir()
    if not dir then return nil end
    return dir .. '\\' .. QUEUE_FILENAME
end

local function getStatePath()
    local dir = getConfigDir()
    if not dir then return nil end
    return dir .. '\\' .. STATE_FILENAME
end

local function serialize(tbl, indent)
    indent = indent or ''
    local inner = indent .. '  '
    local parts = { '{\n' }
    local n = #parts
    for k, v in pairs(tbl) do
        n = n + 1
        if type(k) == 'string' then
            if k:match('^[%a_][%w_]*$') then
                parts[n] = inner .. k .. ' = '
            else
                parts[n] = inner .. '["' .. k:gsub('\\', '\\\\'):gsub('"', '\\"') .. '"] = '
            end
        else
            parts[n] = inner .. '[' .. tostring(k) .. '] = '
        end
        if type(v) == 'table' then
            n = n + 1
            parts[n] = serialize(v, inner)
        elseif type(v) == 'string' then
            n = n + 1
            parts[n] = '"' .. v:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '\\r') .. '"'
        elseif type(v) == 'number' or type(v) == 'boolean' then
            n = n + 1
            parts[n] = tostring(v)
        else
            n = n + 1
            parts[n] = 'nil'
        end
        n = n + 1
        parts[n] = ',\n'
    end
    n = n + 1
    parts[n] = indent .. '}'
    return table.concat(parts)
end

local function saveState()
    local path = getStatePath()
    if not path then return false end
    local tmpPath = path .. '.tmp'
    local f = io.open(tmpPath, 'w')
    if not f then return false end
    f:write('-- Turbo skip queue state (auto-generated)\nreturn ')
    f:write(serialize(state))
    f:write('\n')
    f:close()
    os.remove(path)
    os.rename(tmpPath, path)
    return true
end

local function loadState()
    local path = getStatePath()
    if not path then return end
    local fn = loadfile(path)
    if not fn then return end
    local ok, tbl = pcall(fn)
    if ok and type(tbl) == 'table' and type(tbl.offsets) == 'table' then
        state.offsets = tbl.offsets
    end
end

local function trim(s)
    return (tostring(s or ''):match('^%s*(.-)%s*$') or '')
end

local function loadSkipLog()
    if skipLogWriter and skipLogWriter.append_event then
        return skipLogWriter
    end
    for _, name in ipairs({ 'Turbo/skip_log', 'turbo/skip_log' }) do
        local ok, m = pcall(require, name)
        if ok and type(m) == 'table' and m.append_event then
            skipLogWriter = m
            return m
        end
    end
    local base = (mq.TLO.MacroQuest.Path() or ''):gsub('\\', '/')
    local paths = {
        base .. '/lua/Turbo/skip_log.lua',
        base .. '/lua/turbo/skip_log.lua',
        base .. '/Macros/lua/Turbo/skip_log.lua',
        base .. '/Macros/lua/turbo/skip_log.lua',
    }
    for _, p in ipairs(paths) do
        for _, variant in ipairs({ p, p:gsub('/', '\\') }) do
            local lf = loadfile(variant)
            if lf then
                local ok, m = pcall(lf)
                if ok and type(m) == 'table' and m.append_event then
                    skipLogWriter = m
                    return m
                end
            end
        end
    end
    return nil
end

local function getFileSize(path)
    local f = io.open(path, 'rb')
    if not f then return nil, 'missing' end
    local ok, size = pcall(function()
        local s = f:seek('end')
        f:close()
        return s
    end)
    if not ok or type(size) ~= 'number' then
        pcall(function() f:close() end)
        return nil, 'locked'
    end
    return size
end

--- Read the queue INI safely. Returns:
---   sections table : parse succeeded
---   nil, 'missing' : file does not exist yet (not an error)
---   nil, 'locked'  : io.open/read failed — writer likely holds the lock.
--- Never raises. Mid-write contention should NOT kill the Lua script (1.0.0 bug).
local function parseQueueFile(path)
    local f = io.open(path, 'r')
    if not f then
        return nil, 'missing'
    end

    --- f:read('*a') reads the whole file in one syscall and returns the
    --- buffer. If the write lock is contested, the read will fail immediately
    --- (not mid-iteration), and the pcall catches it cleanly.
    local ok, data = pcall(function()
        local d = f:read('*a')
        f:close()
        return d
    end)
    if not ok or type(data) ~= 'string' then
        pcall(function() f:close() end)
        return nil, 'locked'
    end

    local sections = {}
    local current = nil
    --- Split on \n; strip trailing \r so CRLF and LF both work.
    for line in (data .. '\n'):gmatch('([^\n]*)\n') do
        if line:sub(-1) == '\r' then line = line:sub(1, -2) end
        if line ~= '' then
            local first = line:sub(1, 1)
            if first ~= ';' and first ~= '#' then
                local sec = line:match('^%[(.-)%]%s*$')
                if sec then
                    current = trim(sec)
                    sections[current] = sections[current] or {}
                elseif current then
                    local k, v = line:match('^([^=]+)=(.*)$')
                    if k then
                        sections[current][trim(k)] = trim(v)
                    end
                end
            end
        end
    end
    return sections
end

local function parseEntry(value)
    local fields = {}
    local n = 0
    for f in (tostring(value or '') .. '|'):gmatch('([^|]*)|') do
        n = n + 1
        fields[n] = f
    end
    local itemName = trim(fields[1] or '')
    if itemName == '' or itemName == 'NULL' or itemName == 'null' then return nil end
    return {
        itemName = itemName,
        reason = trim(fields[2] or ''),
        itemId = trim(fields[3] or ''),
        source = trim(fields[4] or ''),
        iniDir = trim(fields[5] or ''),
        corpseId = trim(fields[6] or ''),
    }
end

function M.get_queue_path()
    return getQueuePath()
end

function M.get_state_path()
    return getStatePath()
end

function M.reset_state(deleteQueueFile)
    local removed = 0
    state.offsets = {}
    lastPollTime = 0
    lastQueuePath = nil
    lastQueueSize = nil

    local statePath = getStatePath()
    if statePath and os.remove(statePath) then
        removed = removed + 1
    end

    if deleteQueueFile then
        local queuePath = getQueuePath()
        if queuePath and os.remove(queuePath) then
            removed = removed + 1
        end
    end

    return removed
end

function M.poll()
    local now = (mq.gettime and mq.gettime()) or (os.clock() * 1000)
    if (now - lastPollTime) < POLL_INTERVAL_MS then return false end
    lastPollTime = now

    --- Full pcall so ANY unexpected failure inside the drain cannot kill the
    --- host Lua script. Previous behavior: a single "Permission denied" at
    --- the f:lines() boundary ended the Turbo GUI script, causing subsequent
    --- skips to accumulate in the queue INI without ever being journaled.
    local ok, dirty = pcall(function()
        local queuePath = getQueuePath()
        if not queuePath then return false end
        local size, sizeReason = getFileSize(queuePath)
        if not size then
            if sizeReason == 'locked' then
                lastPollTime = now - (POLL_INTERVAL_MS - READ_FAIL_BACKOFF_MS)
            else
                lastQueuePath = nil
                lastQueueSize = nil
            end
            return false
        end
        if queuePath == lastQueuePath and size == lastQueueSize then
            return false
        end

        local sections, reason = parseQueueFile(queuePath)
        if not sections then
            if reason == 'locked' then
                --- Writer has the file. Try again soon — don't wait the full
                --- POLL_INTERVAL_MS, shave it so we catch up quickly.
                lastPollTime = now - (POLL_INTERVAL_MS - READ_FAIL_BACKOFF_MS)
            else
                lastQueuePath = nil
                lastQueueSize = nil
            end
            return false
        end
        lastQueuePath = queuePath
        lastQueueSize = size

        local writer = loadSkipLog()
        if not writer then
            printf('\ar[turboLoot]\ax skip_queue: skip_log.lua not found')
            return false
        end

        local changed = false
        local appendedThisPoll = 0
        
        for sectionName, data in pairs(sections) do
            if type(sectionName) == 'string' and sectionName:match('^Queue_') then
                local keys = {}
                for k in pairs(data) do
                    local id = tonumber(k)
                    if id then
                        keys[#keys + 1] = id
                    end
                end
                table.sort(keys)
        
                local lastDone = tonumber(state.offsets[sectionName] or 0) or 0
                for _, id in ipairs(keys) do
                    if id > lastDone then
                        local rec = parseEntry(data[tostring(id)])
                        local okAppend = true
                        if rec then
                            okAppend = writer.append_event(
                                rec.itemName,
                                rec.reason,
                                rec.corpseId ~= '' and ('corpse=' .. rec.corpseId) or '',
                                rec.itemId,
                                '',
                                rec.source,
                                rec.iniDir,
                                true
                            )
                        end
        
                        if okAppend then
                            state.offsets[sectionName] = id
                            lastDone = id
                            changed = true
        
                            appendedThisPoll = appendedThisPoll + 1
                            if appendedThisPoll >= MAX_APPENDS_PER_POLL then
                                saveState()
                                return true
                            end
                        else
                            break
                        end
                    end
                end
            end
        end

        if changed then
            saveState()
        end
        return changed
    end)

    if not ok then
        --- pcall caught something unexpected (not the routine "locked" path).
        --- Log once so we don't spam on every tick, then keep going.
        printf('\ar[turboLoot]\ax skip_queue.poll: %s', tostring(dirty))
        return false
    end
    return dirty and true or false
end

loadState()

return M
