-- TurboGear/store_backend_file.lua
-- File persistence backend for the Store (Phase 3): the atomic Lua-pickle cache
-- with a read-merge that avoids clobbering concurrent writers. This is the
-- original store.lua persistence, extracted behind the backend interface so a
-- SQLite backend can slot in via the same contract.
--
-- Backend interface (see also store_backend_sqlite.lua):
--   B:load()      -> ok, table, reason   -- primary cache, then one-time legacy
--   B:reload()    -> ok, table, reason   -- primary only (UI reading bg writes)
--   B:signature() -> token               -- cheap change-detection
--   B:save(out)   -> ok, reason          -- sole-writer-skip + read-merge + atomic
--   B:status()    -> { file=, backend= }
--   B.kind = "file"
--
-- opts.newer(a,b) -> bool       : "a is newer than b" (seq-aware; from store) for the merge
-- opts.key_fn()      -> string  : this box's key, for a collision-safe temp name

local mq  = require('mq')
local cfg = require('config')
local CFG = cfg.CFG
local diag = require('diagnostics')

local ok_ffi, ffi = pcall(require, 'ffi')
if ok_ffi and ffi then
    pcall(ffi.cdef, [[
        typedef unsigned long DWORD;
        typedef int BOOL;
        typedef struct _FILETIME {
            DWORD dwLowDateTime;
            DWORD dwHighDateTime;
        } FILETIME;
        typedef struct _WIN32_FILE_ATTRIBUTE_DATA {
            DWORD dwFileAttributes;
            FILETIME ftCreationTime;
            FILETIME ftLastAccessTime;
            FILETIME ftLastWriteTime;
            DWORD nFileSizeHigh;
            DWORD nFileSizeLow;
        } WIN32_FILE_ATTRIBUTE_DATA;
        BOOL GetFileAttributesExA(const char* lpFileName, int fInfoLevelId, void* lpFileInformation);
        BOOL MoveFileExA(const char* lpExistingFileName, const char* lpNewFileName, DWORD dwFlags);
    ]])
else
    ffi = nil
end

local function signature()
    local path = tostring(cfg.CacheFile or "")
    if path == "" then return "missing" end
    if ffi then
        local data = ffi.new("WIN32_FILE_ATTRIBUTE_DATA[1]")
        local ok, rc = pcall(function()
            return ffi.C.GetFileAttributesExA(path, 0, data)
        end)
        if ok and rc ~= 0 and data[0] then
            local d = data[0]
            return table.concat({
                tostring(tonumber(d.nFileSizeHigh) or 0),
                tostring(tonumber(d.nFileSizeLow) or 0),
                tostring(tonumber(d.ftLastWriteTime.dwHighDateTime) or 0),
                tostring(tonumber(d.ftLastWriteTime.dwLowDateTime) or 0),
            }, ":")
        end
    end
    local f = io.open(path, "rb")
    if not f then return "missing" end
    local size = f:seek("end") or 0
    f:close()
    return "size:" .. tostring(size)
end

local function safe_load_lua_table(path)
    path = tostring(path or "")
    if path == "" then return false, nil, "missing path" end
    local chunk, load_err = loadfile(path)
    if type(chunk) ~= "function" then
        return false, nil, tostring(load_err or "load failed")
    end
    local ok, value = pcall(chunk)
    if not ok then
        return false, nil, tostring(value or "run failed")
    end
    if type(value) ~= "table" then
        return false, nil, "not a table"
    end
    return true, value, nil
end

local function replace_file(tmp_path, final_path)
    tmp_path = tostring(tmp_path or "")
    final_path = tostring(final_path or "")
    if tmp_path == "" or final_path == "" then return false end
    if ffi then
        local ok, rc = pcall(function()
            return ffi.C.MoveFileExA(tmp_path, final_path, 0x1 + 0x8) -- replace existing, write through
        end)
        if ok and rc ~= 0 then return true end
    end
    pcall(function() os.remove(final_path) end)
    return os.rename(tmp_path, final_path) == true
end

local M = {}
local Backend = {}
Backend.__index = Backend

function M.new(opts)
    opts = opts or {}
    return setmetatable({
        kind = "file",
        newer = opts.newer or function() return false end,
        key_fn = opts.key_fn or function() return "?" end,
        last_written_sig = nil,   -- sig of what WE last wrote (sole-writer skip)
        last_tmp_validate = 0,
    }, Backend)
end

function Backend:signature() return signature() end

function Backend:load()
    local ok, t, reason = safe_load_lua_table(cfg.CacheFile)
    if not (ok and type(t) == "table") then
        -- one-time warm start from the pre-rename cache, if present
        ok, t, reason = safe_load_lua_table(cfg.LegacyCacheFile)
    end
    self.last_written_sig = signature()
    return ok, t, reason
end

function Backend:reload()
    return safe_load_lua_table(cfg.CacheFile)
end

-- Persist the full stripped source set. Read-merge avoids clobbering another
-- box that wrote since our last write; skipped when we're the sole writer.
function Backend:save(out)
    local disk_sig = signature()
    if self.last_written_sig == nil or disk_sig ~= self.last_written_sig then
        diag.count("store.save_merge")
        local ok_existing, existing = safe_load_lua_table(cfg.CacheFile)
        if ok_existing and type(existing) == "table" then
            for k, disk in pairs(existing) do
                if type(disk) == "table" then
                    local mem = out[k]
                    if type(mem) ~= "table" or self.newer(disk, mem) then
                        out[k] = disk
                    end
                end
            end
        end
    else
        diag.count("store.save_merge_skipped")
    end

    local final_path = tostring(cfg.CacheFile or "")
    if final_path == "" then return false, "missing cache path" end
    local suffix = tostring(self.key_fn()):gsub("[^%w_%-]", "_")
    local tmp_path = string.format("%s.%s.%d.tmp", final_path, suffix, math.floor(os.clock() * 1000000))
    pcall(function() os.remove(tmp_path) end)
    local ok_pickle, pickle_err = pcall(function() mq.pickle(tmp_path, out) end)
    if not ok_pickle then
        pcall(function() os.remove(tmp_path) end)
        return false, tostring(pickle_err or "pickle failed")
    end
    -- Temp re-validation is belt-and-suspenders; demoted to periodic (P1 interim).
    local now_validate = os.clock()
    local validate_every = tonumber(CFG.cache_tmp_validate_s) or 30
    if self.last_tmp_validate == 0 or (now_validate - self.last_tmp_validate) >= validate_every then
        local ok_tmp, _, load_err = safe_load_lua_table(tmp_path)
        if not ok_tmp then
            pcall(function() os.remove(tmp_path) end)
            return false, "temp cache invalid: " .. tostring(load_err or "?")
        end
        self.last_tmp_validate = now_validate
    end
    if not replace_file(tmp_path, final_path) then
        pcall(function() os.remove(tmp_path) end)
        return false, "replace failed"
    end
    self.last_written_sig = signature()
    return true, "saved"
end

function Backend:status()
    return { file = cfg.CacheFile, backend = self.kind }
end

return M
