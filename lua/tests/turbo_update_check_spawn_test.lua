-- Run from repo root: luajit lua\tests\turbo_update_check_spawn_test.lua
-- Verifies hidden CreateProcess fetch (curl/powershell) without os.execute.

package.path = 'lua/?.lua;lua/?/init.lua;' .. package.path

local tempDir = (os.getenv('TEMP') or os.getenv('TMP') or '.') .. '\\turbo_uc_test_' .. tostring(os.time())
-- Use lfs or PowerShell-free mkdir via ffi if needed; simple CreateDirectory via os is ok in tests only.
pcall(function()
    local ffi = require('ffi')
    pcall(ffi.cdef, 'int CreateDirectoryA(const char* p, void* s);')
    ffi.C.CreateDirectoryA(tempDir, nil)
end)

package.preload['mq'] = function()
    return {
        configDir = tempDir,
        luaDir = 'lua',
    }
end

local UC = require('Turbo.update_check')
local g = { checkForUpdates = true, updateCheckAt = 0 }
assert(UC.force_check(g, { immediate = true }) == true, 'force_check should start a fetch')

local resultPath = tempDir .. '\\turbo_update_check.txt'
local deadline = os.clock() + 30
local got = nil
while os.clock() < deadline do
    local f = io.open(resultPath, 'r')
    if f then
        for line in f:lines() do
            local v = line:match('^%s*(%d+%.%d+[%d%.]*)')
            if v then got = v; break end
        end
        f:close()
        if got then break end
    end
    local t = os.clock() + 0.2
    while os.clock() < t do end
    UC.tick(g)
end

local ok = got and got:match('^%d+%.%d+')
io.write(string.format(
    'turbo_update_check_spawn_test: %s (remote=%s available=%s)\n',
    ok and 'passed' or 'FAILED',
    tostring(got or 'nil'),
    tostring(g.turboUpdateAvailable)))

os.exit(ok and 0 or 1)
