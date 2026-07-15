-- Turbo/paths.lua
-- Shared generated-file locations. Live turboloot*.ini profiles intentionally
-- remain in Config for MacroQuest/E3/macro compatibility.

local mq = require('mq')

local M = {}

local function trim_sep(path)
    return tostring(path or ''):gsub('[\\/]+$', '')
end

local function join(a, b)
    a = trim_sep(a)
    b = tostring(b or ''):gsub('^[\\/]+', '')
    if a == '' then return b end
    if b == '' then return a end
    return a .. '\\' .. b
end

local function file_exists(path)
    local f = io.open(path, 'r')
    if f then f:close(); return true end
    return false
end

local function folder_exists(path)
    local ok, _, code = os.rename(path, path)
    return ok == true or code == 13
end

local function create_dir_quiet(path)
    local okFfi, ffi = pcall(require, 'ffi')
    if not okFfi or not ffi then return false end
    if not _G.TurboPathsCreateDirectoryCdef then
        pcall(ffi.cdef, [[
            int CreateDirectoryA(const char* lpPathName, void* lpSecurityAttributes);
        ]])
        _G.TurboPathsCreateDirectoryCdef = true
    end

    local winPath = trim_sep(path):gsub('/', '\\')
    if winPath == '' then return false end
    local current = ''
    local rest = winPath
    local drive = winPath:match('^%a:')
    if drive then
        current = drive
        rest = winPath:sub(4)
    elseif winPath:sub(1, 2) == '\\\\' then
        local server, share, tail = winPath:match('^\\\\([^\\]+)\\([^\\]+)\\?(.*)$')
        if server and share then
            current = '\\\\' .. server .. '\\' .. share
            rest = tail or ''
        end
    end

    for part in rest:gmatch('[^\\]+') do
        if current == '' then current = part else current = current .. '\\' .. part end
        if not folder_exists(current) then
            pcall(function() ffi.C.CreateDirectoryA(current, nil) end)
        end
    end
    return folder_exists(winPath)
end

function M.config_dir()
    local dir = tostring(mq.configDir or '')
    if dir ~= '' then return trim_sep(dir):gsub('/', '\\') end
    local mqPath = tostring(mq.TLO.MacroQuest.Path() or '')
    if mqPath == '' then return nil end
    return join(mqPath, 'Config')
end

function M.mq_root()
    local mqPath = tostring(mq.TLO.MacroQuest.Path() or '')
    if mqPath == '' then return nil end
    return trim_sep(mqPath):gsub('/', '\\')
end

function M.ensure_dir(path)
    path = trim_sep(path):gsub('/', '\\')
    if path == '' then return false end
    if folder_exists(path) then return true end
    create_dir_quiet(path)
    return folder_exists(path)
end

function M.root()
    local dir = M.config_dir()
    if not dir then return nil end
    return join(dir, 'Turbo')
end

function M.dir(kind)
    local root = M.root()
    if not root then return nil end
    if not M.ensure_dir(root) then return nil end
    kind = tostring(kind or '')
    if kind == '' then return root end
    local child = join(root, kind)
    if not M.ensure_dir(child) then return nil end
    return child
end

function M.state_dir()
    return M.dir('state')
end

function M.logs_dir()
    return M.dir('logs')
end

function M.exports_dir()
    return M.dir('exports')
end

function M.diagnostics_dir()
    return M.dir('diagnostics')
end

function M.backups_dir()
    return M.dir('backups')
end

function M.cache_dir()
    return M.dir('cache')
end

function M.tool_dir(name)
    name = tostring(name or ''):gsub('[^%w_%-]', '')
    if name == '' then return M.dir('tools') end
    return M.dir(name)
end

function M.state_file(name)
    local dir = M.state_dir()
    if not dir then return nil end
    return join(dir, name)
end

function M.log_file(name)
    local dir = M.logs_dir()
    if not dir then return nil end
    return join(dir, name)
end

function M.config_file(name)
    local dir = M.config_dir()
    if not dir then return nil end
    return join(dir, name)
end

function M.first_existing(paths)
    for _, path in ipairs(paths or {}) do
        if path and file_exists(path) then return path end
    end
    return nil
end

function M.file_exists(path)
    return file_exists(path)
end

function M.join(a, b)
    return join(a, b)
end

return M
