-- TurboGear/bis_search.lua
-- LazBiS-shaped peer BiS ownership: each box FindItems the active catalog list
-- (not a full bag walk) and returns a tiny slot map over actors. The UI host
-- persists those maps so offline columns can warm without rich snapshots.

local mq = require('mq')
local cfg = require('config')
local CFG = cfg.CFG
local diag = require('diagnostics')

local M = {}

-- cache[key] = { name, server, class, lists = { [list_id] = { updated, slots = { [slot]=rec } } } }
local cache = {}
local cache_version = 0
local loaded = false
local last_file_sig = nil
local last_request_at = {}
local REQUEST_COOLDOWN_S = 12.0

local function trim(s)
    return tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function cache_path()
    return tostring(cfg.BisSearchFile or (tostring(mq.configDir or "") .. "/TurboGear_bissearch.lua"))
end

local function me_class()
    local c = cfg.canonical_class and cfg.canonical_class(mq.TLO.Me.Class.Name())
    if c then return c end
    c = cfg.canonical_class and cfg.canonical_class(mq.TLO.Me.Class and mq.TLO.Me.Class())
    if c then return c end
    c = cfg.canonical_class and cfg.canonical_class(mq.TLO.Me.Class and mq.TLO.Me.Class.ShortName and mq.TLO.Me.Class.ShortName())
    return c or ""
end

local function me_name()
    return tostring(mq.TLO.Me.CleanName() or "")
end

local function me_server()
    return tostring(mq.TLO.MacroQuest.Server() or "")
end

local function char_key(server, name)
    return tostring(server or "") .. "_" .. tostring(name or "")
end

local function file_sig()
    local path = cache_path()
    local ok, attr = pcall(function()
        if mq.TLO.File and mq.TLO.File(path) and mq.TLO.File(path).Size then
            return tostring(mq.TLO.File(path).Size() or 0) .. ":" .. tostring(mq.TLO.File(path).Modified() or 0)
        end
        return nil
    end)
    if ok and attr then return attr end
    local f = io.open(path, "rb")
    if not f then return "missing" end
    local body = f:read("*a") or ""
    f:close()
    return tostring(#body)
end

function M.version()
    return cache_version
end

function M.load(force)
    local path = cache_path()
    local sig = file_sig()
    if not force and loaded and sig == last_file_sig then return false end
    local chunk = loadfile(path)
    if type(chunk) ~= "function" then
        loaded = true
        last_file_sig = sig
        return false
    end
    local ok, t = pcall(chunk)
    if ok and type(t) == "table" then
        cache = t
        cache_version = cache_version + 1
    end
    loaded = true
    last_file_sig = sig
    return true
end

local function should_persist()
    local ok, st = pcall(require, 'state')
    if not ok or type(st) ~= "table" then return false end
    -- UI process may persist; bg persists only when sharing the box with a UI.
    if st.bg ~= true then return true end
    local scripts = st.local_guard_scripts
    return type(scripts) == "table" and scripts.main == true
end

function M.save()
    if not should_persist() then return false end
    local path = cache_path()
    if path == "" then return false end
    local tmp = path .. ".tmp"
    pcall(function() os.remove(tmp) end)
    local ok = pcall(function() mq.pickle(tmp, cache) end)
    if not ok then
        pcall(function() os.remove(tmp) end)
        return false
    end
    pcall(function() os.remove(path) end)
    if not os.rename(tmp, path) then
        pcall(function() os.remove(tmp) end)
        return false
    end
    last_file_sig = file_sig()
    return true
end

local function find_tlo(id_or_name, bank)
    local function valid(fi)
        local ok, exists = pcall(function() return fi and fi() end)
        return ok and exists and true or false
    end
    local function lookup(query)
        local ok, fi = pcall(function()
            if bank then
                return mq.TLO.FindItemBank and mq.TLO.FindItemBank(query) or nil
            end
            return mq.TLO.FindItem and mq.TLO.FindItem(query) or nil
        end)
        if ok and valid(fi) then return fi end
        return nil
    end
    if type(id_or_name) == "number" then
        if (tonumber(id_or_name) or 0) <= 0 then return nil end
        return lookup(id_or_name)
    end
    local name = trim(id_or_name)
    if name == "" then return nil end
    local fi = lookup("=" .. name)
    if fi then return fi end
    local low = name:lower()
    if not low:find("%(augmented%)%s*$") then
        fi = lookup("=" .. name .. " (Augmented)")
        if fi then return fi end
    end
    return lookup(name)
end

local function status_from_fi(fi, bank)
    if not fi then return nil, nil end
    -- Keep labels short: "Bags" / "Bank" / worn slot name. Avoid "Bags - Bags".
    if bank then return "carried", "Bank" end
    local slot = nil
    pcall(function() slot = tonumber(fi.ItemSlot()) end)
    if slot and slot >= 0 and slot <= 22 then
        local slotname = nil
        pcall(function() slotname = tostring(fi.ItemSlotName and fi.ItemSlotName() or "") end)
        if not slotname or slotname == "" or slotname == "nil" then slotname = "Equipped" end
        local low = slotname:lower()
        if low == "bags" or low == "bank" then slotname = "Equipped" end
        return "equipped", slotname
    end
    return "carried", "Bags"
end

--- Bounded FindItem(+Bank) for one catalog entry. Same id/name budget as live_item_status.
local function search_entry(entry)
    entry = entry or {}
    local tried = 0
    local function try(v, bank)
        tried = tried + 1
        if tried > 12 then return nil end
        local fi = find_tlo(v, bank)
        if not fi then return nil end
        local status, loc = status_from_fi(fi, bank)
        local actual = nil
        pcall(function() actual = tostring(fi.Name() or fi() or "") end)
        return {
            status = status or "carried",
            location = loc or "",
            name = (actual and actual ~= "" and actual) or tostring(entry.item or ""),
            count = 1,
        }
    end
    for _, id in ipairs(entry.ids or {}) do
        local n = tonumber(id)
        if n and n > 0 then
            local hit = try(n, false) or try(n, true)
            if hit then return hit end
        end
    end
    local names = entry.names or {}
    local nmax = math.min(#names, 6)
    for i = 1, nmax do
        local hit = try(names[i], false) or try(names[i], true)
        if hit then return hit end
    end
    local canonical = trim(entry.item)
    if canonical ~= "" then
        local hit = try(canonical, false) or try(canonical, true)
        if hit then return hit end
    end
    return { status = "missing", location = "", name = tostring(entry.item or ""), count = 0 }
end

--- Run LazBiS-style FindItem scan for this box + list_id.
function M.search_local(list_id)
    list_id = trim(list_id)
    if list_id == "" then return nil end
    local catalog = require('bis_catalog')
    local bis = require('bis')
    local class_name = me_class()
    if class_name == "" then return nil end
    local refs = catalog.reference_rows(list_id, { class_names = { class_name } })
    local slots = {}
    for _, ref in ipairs(refs or {}) do
        if ref and ref.slot and not ref.header and not ref.spell_index then
            local entry = catalog.resolve_entry(list_id, class_name, ref.slot)
            if entry then
                entry = bis.normalize_entry(entry)
                slots[ref.slot] = search_entry(entry)
            end
        end
    end
    return {
        name = me_name(),
        server = me_server(),
        class = class_name,
        list_id = list_id,
        updated = os.time(),
        slots = slots,
    }
end

function M.apply_result(payload)
    if type(payload) ~= "table" then return false end
    local name = trim(payload.name)
    local server = trim(payload.server)
    local list_id = trim(payload.list_id or payload.list)
    if name == "" or server == "" or list_id == "" then return false end
    local key = char_key(server, name)
    local rec = cache[key]
    if type(rec) ~= "table" then
        rec = { name = name, server = server, class = "", lists = {} }
        cache[key] = rec
    end
    rec.name = name
    rec.server = server
    if cfg.canonical_class then
        rec.class = cfg.canonical_class(payload.class) or rec.class or ""
    else
        rec.class = trim(payload.class) ~= "" and trim(payload.class) or rec.class
    end
    rec.lists = type(rec.lists) == "table" and rec.lists or {}
    rec.lists[list_id] = {
        updated = tonumber(payload.updated) or os.time(),
        slots = type(payload.slots) == "table" and payload.slots or {},
    }
    cache_version = cache_version + 1
    return true
end

function M.slot_rec(snap_or_key, list_id, slot)
    if not loaded then M.load(true) end
    list_id = trim(list_id)
    slot = trim(slot)
    if list_id == "" or slot == "" then return nil end
    local key = snap_or_key
    if type(snap_or_key) == "table" then
        key = char_key(snap_or_key.server, snap_or_key.name)
    end
    key = tostring(key or "")
    local rec = cache[key]
    if type(rec) ~= "table" then return nil end
    local list = rec.lists and rec.lists[list_id]
    if type(list) ~= "table" or type(list.slots) ~= "table" then return nil end
    return list.slots[slot]
end

function M.stub_snap(key)
    if not loaded then M.load(true) end
    local rec = cache[tostring(key or "")]
    if type(rec) ~= "table" then return nil end
    return {
        name = rec.name,
        server = rec.server,
        class = rec.class,
        level = 0,
        status = "offline",
        depth = "bis_search",
        equipped = {},
        bags = {},
        bank = {},
        _bis_search = true,
    }
end

function M.known_keys()
    if not loaded then M.load(true) end
    local keys = {}
    for k, rec in pairs(cache) do
        if type(rec) == "table" and trim(rec.name) ~= "" then
            keys[#keys + 1] = k
        end
    end
    table.sort(keys)
    return keys
end

--- Merge offline BiS-search characters into an All Known key list.
function M.merge_roster_keys(keys, scope)
    scope = tostring(scope or "")
    if scope ~= "all" then return keys end
    if not loaded then M.load(true) end
    local seen = {}
    local out = {}
    for _, k in ipairs(keys or {}) do
        out[#out + 1] = k
        seen[k] = true
    end
    local mine = char_key(me_server(), me_name())
    for _, k in ipairs(M.known_keys()) do
        if not seen[k] and k ~= mine then
            out[#out + 1] = k
            seen[k] = true
        end
    end
    return out
end

function M.should_request(list_id)
    list_id = trim(list_id)
    if list_id == "" then return false end
    local last = tonumber(last_request_at[list_id]) or 0
    return (os.clock() - last) >= REQUEST_COOLDOWN_S
end

function M.mark_requested(list_id)
    last_request_at[trim(list_id)] = os.clock()
end

--- UI helper: ask local bg to broadcast a list search (quiet).
function M.request_via_bg(list_id)
    list_id = trim(list_id)
    if list_id == "" or not M.should_request(list_id) then return false end
    M.mark_requested(list_id)
    pcall(function()
        mq.cmd(string.format('/squelch /tgearbg bissearch %s', list_id))
    end)
    return true
end

function M.reload_if_changed()
    return M.load(false)
end

-- Ensure path is registered even if config is older mid-session.
if not cfg.BisSearchFile then
    cfg.BisSearchFile = string.format("%s/%s_bissearch.lua", mq.configDir, CFG.script_name or "TurboGear")
end

M.load(true)
return M
