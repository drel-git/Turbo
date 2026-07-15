-- TurboGear/store_backend_sqlite.lua
-- SQLite persistence backend for the Store (Phase 3). Same contract as
-- store_backend_file.lua, but backed by an on-disk SQLite database:
--   * WAL journalling -> concurrent multi-box readers/writers with no clobber
--     race (the file cache's read-merge existed only to paper over that race).
--   * change-detected upserts -> only rows whose payload actually changed are
--     written, instead of rewriting + reparsing the whole cache every save.
--   * PRAGMA data_version -> cheap detection of another box's writes for the
--     UI's "reload if changed" path.
--
-- Requires the lsqlite3 LuaRock (bundled with most MacroQuest installs). If it
-- is unavailable, new():available() returns false and store.lua falls back to
-- the file backend.
--
-- Schema is hybrid: a few scalar columns for inspectability / future indexed
-- queries, plus a serialized `payload` that is the authoritative snapshot (the
-- in-memory Store remains the query structure, so we don't model item rows).

local cfg = require('config')
local diag = require('diagnostics')

-- Load lsqlite3, auto-installing it from the MacroQuest LuaRocks server on first
-- use via mq/PackageMan (plug-and-play, mirroring LazBis). Falls back to a plain
-- require, and returns nil on any failure so the store uses the file backend.
local function load_lsqlite3()
    local ok_pm, PackageMan = pcall(require, 'mq/PackageMan')
    if ok_pm and type(PackageMan) == "table" and PackageMan.Require then
        local ok_req, mod = pcall(function() return PackageMan.Require('lsqlite3') end)
        if ok_req and type(mod) == "table" then return mod end
    end
    local ok, mod = pcall(require, 'lsqlite3')
    if ok and type(mod) == "table" then return mod end
    return nil
end

local loader = loadstring or load

-- Deterministic serializer (sorted keys) so an unchanged snapshot always yields
-- the same string -> the same hash -> no spurious rewrite.
local function serialize(v)
    local t = type(v)
    if t == "number" then
        if v == math.floor(v) and math.abs(v) < 9e15 then return string.format("%d", v) end
        return string.format("%.17g", v)
    elseif t == "boolean" then return tostring(v)
    elseif t == "string" then return string.format("%q", v)
    elseif t == "table" then
        local keys = {}
        for k in pairs(v) do
            local tk = type(k)
            if tk == "number" or tk == "string" then keys[#keys + 1] = k end
        end
        table.sort(keys, function(a, b)
            local ta, tb = type(a), type(b)
            if ta ~= tb then return ta < tb end
            return a < b
        end)
        local parts = {}
        for _, k in ipairs(keys) do
            local kk = (type(k) == "number") and ("[" .. string.format("%d", k) .. "]")
                or ("[" .. string.format("%q", tostring(k)) .. "]")
            parts[#parts + 1] = kk .. "=" .. serialize(v[k])
        end
        return "{" .. table.concat(parts, ",") .. "}"
    end
    return "nil"
end

local function deserialize(s)
    if type(s) ~= "string" or s == "" then return nil end
    local f = loader("return " .. s)
    if not f then return nil end
    if setfenv then setfenv(f, {}) end   -- sandbox (Lua 5.1 / LuaJIT)
    local ok, v = pcall(f)
    if ok and type(v) == "table" then return v end
    return nil
end

-- djb2 over the payload (+ length) - only cost of a miss is a delayed rewrite,
-- which self-heals on the next change.
local function hash(s)
    local h = 5381
    for i = 1, #s do h = (h * 33 + s:byte(i)) % 4294967296 end
    return #s .. ":" .. h
end

local M = {}
local Backend = {}
Backend.__index = Backend

local function bind_row(stmt, key, snap, payload)
    stmt:reset()
    stmt:bind_values(
        tostring(key), tostring(snap.name or ""), tostring(snap.server or ""),
        tostring(snap.class or ""), tonumber(snap.level) or 0,
        tonumber(snap.updated) or tonumber(snap.inventoryUpdated) or 0, payload)
end

function M.new(opts)
    local self = setmetatable({ kind = "sqlite", row_hash = {}, opts = opts or {} }, Backend)
    local sqlite3 = load_lsqlite3()
    if type(sqlite3) ~= "table" then
        self.unavailable_reason = "lsqlite3 not available"
        return self
    end
    self.sqlite3 = sqlite3
    local path = tostring(cfg.DbFile or "")
    if path == "" then self.unavailable_reason = "no db path"; return self end
    local db = sqlite3.open(path)
    if not db then self.unavailable_reason = "open failed"; return self end
    self.db = db
    pcall(function() db:busy_timeout(3000) end)
    db:exec("PRAGMA journal_mode=WAL")
    db:exec("PRAGMA synchronous=NORMAL")
    db:exec([[CREATE TABLE IF NOT EXISTS sources(
        key TEXT PRIMARY KEY, name TEXT, server TEXT, class TEXT, level INTEGER,
        updated INTEGER, payload TEXT NOT NULL)]])
    self._upsert = db:prepare("INSERT OR REPLACE INTO sources(key,name,server,class,level,updated,payload) VALUES(?,?,?,?,?,?,?)")
    self._delete = db:prepare("DELETE FROM sources WHERE key=?")
    if not self._upsert or not self._delete then
        self.unavailable_reason = "prepare failed"
        self.db = nil
        return self
    end
    self:maybe_import_pickle()
    return self
end

function Backend:available() return self.db ~= nil end

-- One-time migration: if the DB has no rows yet but a legacy pickle cache
-- exists, import it so nothing is lost on the switch to SQLite.
function Backend:maybe_import_pickle()
    local has_row = false
    for _ in self.db:nrows("SELECT 1 AS one FROM sources LIMIT 1") do has_row = true end
    if has_row then return end
    local path = tostring(cfg.CacheFile or "")
    if path == "" then return end
    local chunk = loadfile(path)
    if type(chunk) ~= "function" then return end
    local ok, t = pcall(chunk)
    if not ok or type(t) ~= "table" then return end
    local imported = 0
    self.db:exec("BEGIN")
    for key, snap in pairs(t) do
        if type(snap) == "table" then
            local payload = serialize(snap)
            bind_row(self._upsert, key, snap, payload)
            if self._upsert:step() == self.sqlite3.DONE then
                self.row_hash[tostring(key)] = hash(payload)
                imported = imported + 1
            end
        end
    end
    self.db:exec("COMMIT")
    self.imported = imported
    diag.count("store.sqlite_import", imported)
    diag.event("store.sqlite_import", "imported " .. imported .. " rows from pickle cache")
end

function Backend:signature()
    if not self.db then return "nodb" end
    local st = self.db:prepare("PRAGMA data_version")
    if not st then return "err" end
    st:step()
    local v = st:get_values()[1]
    st:finalize()
    return "dv:" .. tostring(v)
end

function Backend:load()
    if not self.db then return false, nil, "no db" end
    local out = {}
    self.row_hash = {}
    for row in self.db:nrows("SELECT key, payload FROM sources") do
        local snap = deserialize(row.payload)
        if type(snap) == "table" then
            out[row.key] = snap
            self.row_hash[row.key] = hash(row.payload)
        end
    end
    return true, out, "loaded"
end

Backend.reload = Backend.load

-- Persist the full stripped set. Only rows whose serialized payload changed are
-- upserted; rows no longer present are deleted. One transaction; WAL handles
-- concurrency so no read-merge is needed.
function Backend:save(out)
    if not self.db then return false, "no db" end
    local sq = self.sqlite3
    self.db:exec("BEGIN")
    local present, wrote = {}, 0
    for key, snap in pairs(out) do
        key = tostring(key)
        present[key] = true
        local payload = serialize(snap)
        local h = hash(payload)
        if self.row_hash[key] ~= h then
            bind_row(self._upsert, key, snap, payload)
            if self._upsert:step() ~= sq.DONE then
                self.db:exec("ROLLBACK")
                return false, "upsert failed: " .. tostring(self.db:errmsg())
            end
            self.row_hash[key] = h
            wrote = wrote + 1
        end
    end
    local stale = {}
    for key in pairs(self.row_hash) do
        if not present[key] then stale[#stale + 1] = key end
    end
    for _, key in ipairs(stale) do
        self._delete:reset(); self._delete:bind_values(key); self._delete:step()
        self.row_hash[key] = nil
    end
    self.db:exec("COMMIT")
    diag.count("store.sqlite_rows_written", wrote)
    if #stale > 0 then diag.count("store.sqlite_rows_deleted", #stale) end
    return true, "saved"
end

function Backend:status()
    return { file = cfg.DbFile, backend = self.kind, reason = self.unavailable_reason }
end

function Backend:close()
    pcall(function() if self._upsert then self._upsert:finalize() end end)
    pcall(function() if self._delete then self._delete:finalize() end end)
    if self.db then pcall(function() self.db:close() end); self.db = nil end
end

-- exposed for tests
M._serialize = serialize
M._deserialize = deserialize
return M
