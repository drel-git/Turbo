-- TEST-ONLY lsqlite3 shim: implements the subset of the lsqlite3 API that the
-- TurboGear SQLite store backend uses, over LuaJIT FFI -> the system libsqlite3.
-- This lets the offline harness run the real backend against a real SQLite
-- engine without the lsqlite3 LuaRock. NOT shipped; production uses real lsqlite3.
local ffi = require('ffi')

ffi.cdef[[
  typedef struct sqlite3 sqlite3;
  typedef struct sqlite3_stmt sqlite3_stmt;
  int sqlite3_open(const char*, sqlite3**);
  int sqlite3_close(sqlite3*);
  int sqlite3_exec(sqlite3*, const char*, void*, void*, char**);
  int sqlite3_busy_timeout(sqlite3*, int);
  const char* sqlite3_errmsg(sqlite3*);
  int sqlite3_changes(sqlite3*);
  long long sqlite3_last_insert_rowid(sqlite3*);
  int sqlite3_prepare_v2(sqlite3*, const char*, int, sqlite3_stmt**, const char**);
  int sqlite3_step(sqlite3_stmt*);
  int sqlite3_reset(sqlite3_stmt*);
  int sqlite3_finalize(sqlite3_stmt*);
  int sqlite3_bind_text(sqlite3_stmt*, int, const char*, int, void*);
  int sqlite3_bind_int64(sqlite3_stmt*, int, long long);
  int sqlite3_bind_double(sqlite3_stmt*, int, double);
  int sqlite3_bind_null(sqlite3_stmt*, int);
  int sqlite3_column_count(sqlite3_stmt*);
  int sqlite3_column_type(sqlite3_stmt*, int);
  long long sqlite3_column_int64(sqlite3_stmt*, int);
  double sqlite3_column_double(sqlite3_stmt*, int);
  const unsigned char* sqlite3_column_text(sqlite3_stmt*, int);
  const char* sqlite3_column_name(sqlite3_stmt*, int);
]]

local C
for _, name in ipairs({ "sqlite3", "/lib/x86_64-linux-gnu/libsqlite3.so.0",
                        "/usr/lib/x86_64-linux-gnu/libsqlite3.so.0", "libsqlite3.so.0" }) do
    local ok, lib = pcall(ffi.load, name)
    if ok then C = lib; break end
end
assert(C, "lsqlite3 shim: could not load libsqlite3")

local OK, ROW, DONE = 0, 100, 101
local INTEGER, FLOAT, TEXT, NULLTYPE = 1, 2, 3, 5
local TRANSIENT = ffi.cast("void*", -1)

local Stmt = {}
Stmt.__index = Stmt

function Stmt:bind(i, v)
    local t = type(v)
    if v == nil then return C.sqlite3_bind_null(self._h, i) end
    if t == "number" then
        if v == math.floor(v) and math.abs(v) < 9e15 then
            return C.sqlite3_bind_int64(self._h, i, v)
        end
        return C.sqlite3_bind_double(self._h, i, v)
    elseif t == "boolean" then
        return C.sqlite3_bind_int64(self._h, i, v and 1 or 0)
    else
        v = tostring(v)
        return C.sqlite3_bind_text(self._h, i, v, #v, TRANSIENT)
    end
end

function Stmt:bind_values(...)
    local n = select("#", ...)
    for i = 1, n do self:bind(i, (select(i, ...))) end
    return OK
end

function Stmt:step() return C.sqlite3_step(self._h) end
function Stmt:reset() return C.sqlite3_reset(self._h) end
function Stmt:finalize() local rc = C.sqlite3_finalize(self._h); self._h = nil; return rc end

local function col_value(h, i)
    local ct = C.sqlite3_column_type(h, i)
    if ct == NULLTYPE then return nil
    elseif ct == INTEGER then return tonumber(C.sqlite3_column_int64(h, i))
    elseif ct == FLOAT then return C.sqlite3_column_double(h, i)
    else
        local p = C.sqlite3_column_text(h, i)
        return p ~= nil and ffi.string(p) or nil
    end
end

function Stmt:get_values()
    local n = C.sqlite3_column_count(self._h)
    local out = {}
    for i = 0, n - 1 do out[i + 1] = col_value(self._h, i) end
    return out
end

function Stmt:get_named_values()
    local n = C.sqlite3_column_count(self._h)
    local out = {}
    for i = 0, n - 1 do
        out[ffi.string(C.sqlite3_column_name(self._h, i))] = col_value(self._h, i)
    end
    return out
end

local Db = {}
Db.__index = Db

function Db:exec(sql)
    return C.sqlite3_exec(self._h, sql, nil, nil, nil)
end

function Db:busy_timeout(ms) return C.sqlite3_busy_timeout(self._h, ms) end
function Db:changes() return C.sqlite3_changes(self._h) end
function Db:last_insert_rowid() return tonumber(C.sqlite3_last_insert_rowid(self._h)) end
function Db:errmsg() local p = C.sqlite3_errmsg(self._h); return p ~= nil and ffi.string(p) or "" end

function Db:prepare(sql)
    local pstmt = ffi.new("sqlite3_stmt*[1]")
    local rc = C.sqlite3_prepare_v2(self._h, sql, #sql, pstmt, nil)
    if rc ~= OK or pstmt[0] == nil then return nil, self:errmsg() end
    return setmetatable({ _h = pstmt[0], _db = self }, Stmt)
end

-- named-row iterator (subset of lsqlite3 db:nrows)
function Db:nrows(sql)
    local stmt = assert(self:prepare(sql))
    return function()
        if stmt:step() == ROW then return stmt:get_named_values() end
        stmt:finalize(); return nil
    end
end

function Db:close()
    if self._h then C.sqlite3_close(self._h); self._h = nil end
    return OK
end

local M = { OK = OK, ROW = ROW, DONE = DONE, ERROR = 1 }
function M.open(path)
    local pdb = ffi.new("sqlite3*[1]")
    local rc = C.sqlite3_open(path or ":memory:", pdb)
    if rc ~= OK or pdb[0] == nil then return nil, rc, "open failed" end
    return setmetatable({ _h = pdb[0] }, Db)
end
M.open_memory = function() return M.open(":memory:") end
function M.version() return "shim-over-libsqlite3" end
return M
