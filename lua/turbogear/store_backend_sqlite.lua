-- TurboGear/store_backend_sqlite.lua
-- SQLite persistence backend for the Store (Phase 3). Same contract as
-- store_backend_file.lua, but backed by an on-disk SQLite database:
--   * WAL journalling -> concurrent multi-box readers/writers.
--   * Per-row merge-by-newer on save (same rule as the file backend) so one
--     box's save cannot clobber a peer's fresher inventory row.
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

-- Runtime-only keys that must never be persisted (indexes attached to live snaps).
local SKIP_KEYS = {
    _bis_index = true,
    _bis_index_key = true,
    _payload = true,
    _payload_hash = true,
}

-- Dense array (1..n contiguous)? Skip key sort + emit Lua array form — the hot
-- path for equipped/bags/bank lists. Map form is preserved for mixed tables.
local function is_dense_array(t)
    local n = #t
    if n <= 0 then return false end
    local count = 0
    for k in pairs(t) do
        if type(k) ~= "number" or k ~= math.floor(k) or k < 1 or k > n then
            return false
        end
        count = count + 1
    end
    return count == n
end

-- Deterministic serializer. Memoize by table identity (cycles + shared subtrees).
-- Array-fast path avoids per-element sort/key formatting that dominated 30–60s
-- own-row saves of ~200 item lists.
local function serialize(v, seen, stats)
    local t = type(v)
    if t == "number" then
        if stats then stats.leaves = (stats.leaves or 0) + 1 end
        if v == math.floor(v) and math.abs(v) < 9e15 then return string.format("%d", v) end
        return string.format("%.17g", v)
    elseif t == "boolean" then
        if stats then stats.leaves = (stats.leaves or 0) + 1 end
        return tostring(v)
    elseif t == "string" then
        if stats then stats.leaves = (stats.leaves or 0) + 1 end
        return string.format("%q", v)
    elseif t == "table" then
        seen = seen or {}
        local cached = seen[v]
        if cached ~= nil then
            if stats then stats.hits = (stats.hits or 0) + 1 end
            return cached
        end
        if stats then stats.tables = (stats.tables or 0) + 1 end
        -- Placeholder breaks cycles; replaced with the real payload below.
        seen[v] = "{}"
        local out
        if is_dense_array(v) then
            if stats then stats.arrays = (stats.arrays or 0) + 1 end
            local parts = {}
            for i = 1, #v do
                parts[i] = serialize(v[i], seen, stats)
            end
            out = "{" .. table.concat(parts, ",") .. "}"
        else
            local keys = {}
            for k in pairs(v) do
                local tk = type(k)
                if (tk == "number" or tk == "string") and not SKIP_KEYS[k] then
                    keys[#keys + 1] = k
                end
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
                parts[#parts + 1] = kk .. "=" .. serialize(v[k], seen, stats)
            end
            out = "{" .. table.concat(parts, ",") .. "}"
        end
        seen[v] = out
        return out
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

-- Sampled djb2 (+ length). Full-byte hashing of multi-MB payloads was a major
-- contributor to store.save.serialize times (hundreds of seconds).
local function hash(s)
    local n = #s
    if n == 0 then return "0:0" end
    local h = 5381
    local step = math.max(1, math.floor(n / 4096))
    for i = 1, n, step do
        h = (h * 33 + s:byte(i)) % 4294967296
    end
    local tail = math.max(1, n - 31)
    for i = tail, n do
        h = (h * 33 + s:byte(i)) % 4294967296
    end
    return n .. ":" .. h
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
    self._select = db:prepare("SELECT payload FROM sources WHERE key=?")
    if not self._upsert or not self._delete or not self._select then
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

-- Wall ms for Phase 0 RC-3 cross-check (os.clock alone can be CPU-time on some builds).
local function wall_ms_now()
    local ok, mq = pcall(require, 'mq')
    if ok and mq and mq.gettime then
        local t = tonumber(mq.gettime())
        if t then return t end
    end
    return (os.time() or 0) * 1000
end

-- Persist the full stripped set. Only rows whose serialized payload changed are
-- upserted. Serialize happens BEFORE BEGIN so the write lock is short.
function Backend:save(out, save_opts)
    if not self.db then return false, "no db" end
    save_opts = type(save_opts) == "table" and save_opts or {}
    local partial = save_opts.partial == true
    local sq = self.sqlite3
    local newer = self.opts and self.opts.newer
    local my_key = ""
    if self.opts and self.opts.key_fn then
        pcall(function() my_key = tostring(self.opts.key_fn() or "") end)
    end
    local diag_on = diag.is_enabled and diag.is_enabled()
    local wall0 = diag_on and wall_ms_now() or 0
    local clk0 = diag_on and os.clock() or 0
    local ser_ms, upsert_ms, del_ms, begin_ms, commit_ms = 0, 0, 0, 0, 0
    local source_n, merged = 0, 0
    local ser_bytes, ser_max_key, ser_max_ms = 0, "", 0
    local ser_stats_max = nil

    -- Phase A: merge-from-disk + serialize outside the transaction.
    local prepared = {}
    for key, snap in pairs(out) do
        source_n = source_n + 1
        key = tostring(key)
        local is_own = (my_key ~= "" and key == my_key)
        if (not is_own) and type(newer) == "function" and self._select then
            self._select:reset()
            self._select:bind_values(key)
            if self._select:step() == sq.ROW then
                local disk_payload = self._select:get_values()[1]
                local disk_snap = deserialize(disk_payload)
                if type(disk_snap) == "table" and newer(disk_snap, snap) then
                    out[key] = disk_snap
                    snap = disk_snap
                    merged = merged + 1
                    if type(disk_payload) == "string" then
                        self.row_hash[key] = hash(disk_payload)
                    end
                end
            end
        end
        local stats = diag_on and { tables = 0, arrays = 0, hits = 0, leaves = 0 } or nil
        local t_ser = os.clock()
        -- Store may attach a prebuilt payload (sectional cache). Skip the full
        -- tree walk when present — that walk was the 7–11s own-row hitch.
        local payload = snap._payload
        local h = snap._payload_hash
        snap._payload = nil
        snap._payload_hash = nil
        if type(payload) == "string" and payload ~= "" then
            if type(h) ~= "string" or h == "" then h = hash(payload) end
            if stats then stats.hits = (stats.hits or 0) + 1 end
        else
            payload = serialize(snap, nil, stats)
            h = hash(payload)
        end
        local this_ser = (os.clock() - t_ser) * 1000
        ser_ms = ser_ms + this_ser
        local plen = payload and #payload or 0
        ser_bytes = ser_bytes + plen
        if this_ser >= ser_max_ms then
            ser_max_ms = this_ser
            ser_max_key = string.format("%s:%dB", key, plen)
            ser_stats_max = stats
        end
        prepared[#prepared + 1] = { key = key, snap = snap, payload = payload, hash = h }
    end

    local t0 = diag_on and os.clock() or 0
    self.db:exec("BEGIN")
    if diag_on then begin_ms = (os.clock() - t0) * 1000 end

    local present, wrote = {}, 0
    for _, row in ipairs(prepared) do
        present[row.key] = true
        if self.row_hash[row.key] ~= row.hash then
            local t_up = diag_on and os.clock() or 0
            bind_row(self._upsert, row.key, row.snap, row.payload)
            if self._upsert:step() ~= sq.DONE then
                self.db:exec("ROLLBACK")
                return false, "upsert failed: " .. tostring(self.db:errmsg())
            end
            if diag_on then upsert_ms = upsert_ms + (os.clock() - t_up) * 1000 end
            self.row_hash[row.key] = row.hash
            wrote = wrote + 1
        end
    end

    local deleted = 0
    local t_del = diag_on and os.clock() or 0
    if not partial then
        local stale = {}
        for key in pairs(self.row_hash) do
            if not present[key] then stale[#stale + 1] = key end
        end
        for _, key in ipairs(stale) do
            if my_key ~= "" and key == my_key then
                self._delete:reset(); self._delete:bind_values(key); self._delete:step()
                deleted = deleted + 1
            end
            self.row_hash[key] = nil
        end
    end
    if diag_on then del_ms = (os.clock() - t_del) * 1000 end

    local t_c = diag_on and os.clock() or 0
    self.db:exec("COMMIT")
    if diag_on then commit_ms = (os.clock() - t_c) * 1000 end

    diag.count("store.sqlite_rows_written", wrote)
    if merged > 0 then diag.count("store.sqlite_rows_merged", merged) end
    if deleted > 0 then diag.count("store.sqlite_rows_deleted", deleted) end

    if diag_on then
        local clock_ms = (os.clock() - clk0) * 1000
        local wall_ms = wall_ms_now() - wall0
        diag.sample("store.save.serialize", ser_ms)
        diag.sample("store.save.upsert", upsert_ms)
        diag.sample("store.save.delete", del_ms)
        diag.sample("store.save.commit", commit_ms)
        diag.sample("store.save.wall_ms", wall_ms)
        diag.sample("store.save.clock_ms", clock_ms)
        local extra = ""
        if ser_stats_max then
            extra = string.format(" tables=%d arrays=%d hits=%d leaves=%d",
                ser_stats_max.tables or 0, ser_stats_max.arrays or 0,
                ser_stats_max.hits or 0, ser_stats_max.leaves or 0)
        end
        diag.event("store.save.breakdown", string.format(
            "sources=%d wrote=%d merged=%d deleted=%d partial=%s bytes=%d slowest=%s wall=%.0fms clock=%.0fms begin=%.0f ser=%.0f upsert=%.0f del=%.0f commit=%.0f%s",
            source_n, wrote, merged, deleted, tostring(partial), ser_bytes, ser_max_key,
            wall_ms, clock_ms, begin_ms, ser_ms, upsert_ms, del_ms, commit_ms, extra))
    end
    return true, "saved"
end

function Backend:status()
    return {
        file = cfg.DbFile,
        backend = self.kind,
        unavailable = self.unavailable_reason,
        imported = self.imported,
    }
end

M._serialize = serialize
M._deserialize = deserialize
M._hash = hash
return M
