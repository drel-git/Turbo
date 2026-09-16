-- TurboGear/bis_search.lua
-- BiS-shaped peer ownership: each box FindItems the active catalog list
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
local diag_cache = {}
local REQUEST_COOLDOWN_S = 12.0

local function trim(s)
    return tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

-- Match bis.norm_item_name enough to accept "(Augmented)" and reject
-- substring false-hits (short focus name vs "Hideous Hex of …").
local function norm_item_name(s)
    s = trim(s):lower()
    s = s:gsub("`", "'"):gsub("\226\128\152", "'"):gsub("\226\128\153", "'")
    s = s:gsub("%s*%(%s*[^%)]-%s*%)%s*$", "")
    s = s:gsub("%s*%[%s*[^%]]-%s*%]%s*$", "")
    s = s:gsub("%s+", " ")
    return trim(s)
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

local function ignored_cache_record(key, rec)
    local ok_store, store_mod = pcall(require, 'store')
    local Store = ok_store and store_mod and store_mod.Store or nil
    if not Store or type(Store.is_ignored_name) ~= "function" then return false end
    return Store.is_ignored_name(rec and rec.name or key) or Store.is_ignored_name(key)
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
    local function fi_matches_query(fi, query)
        if type(query) == "number" then return true end
        local qname = tostring(query or ""):gsub("^%=", "")
        if trim(qname) == "" then return false end
        local actual = ""
        pcall(function() actual = tostring(fi.Name() or "") end)
        local a, b = norm_item_name(actual), norm_item_name(qname)
        return a ~= "" and a == b
    end
    local function lookup(query)
        local ok, fi = pcall(function()
            if bank then
                return mq.TLO.FindItemBank and mq.TLO.FindItemBank(query) or nil
            end
            return mq.TLO.FindItem and mq.TLO.FindItem(query) or nil
        end)
        if ok and valid(fi) and fi_matches_query(fi, query) then return fi end
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

--- Bounded FindItem(+Bank) for one catalog entry.
--- Order: the row's own name(s) first (the item this row literally asks for),
--- then ids highest-first (progression chains list later/final upgrades at
--- the top of the id range, e.g. Jonas final hand 33171), then the canonical
--- name. Previously ids ran first and a 6-id Jonas row spent the whole
--- 12-lookup budget before its own bone name was ever tried, so a peer
--- holding a Tier 1 bone showed missing. Shared multi-ID names are skipped.
local SEARCH_LOOKUP_BUDGET = 16
local SEARCH_OWN_NAMES = 2
local function progression_candidate_is_exact(entry, id, name)
    id = tonumber(id)
    name = norm_item_name(name)
    local exact_pairs = type(entry.progression_exact_pairs) == "table" and entry.progression_exact_pairs or nil
    local exact_ids = type(entry.progression_exact_ids) == "table" and entry.progression_exact_ids or nil
    local exact_names = type(entry.progression_exact_names) == "table" and entry.progression_exact_names or nil
    if id and id > 0 and exact_pairs and exact_pairs[id] then
        if name ~= "" and exact_pairs[id][name] then return true end
        if name == "" and not exact_ids then return true end
    end
    if id and id > 0 and exact_ids and exact_ids[id] then return true end
    if name ~= "" and exact_names and exact_names[name] then return true end
    return false
end

local function has_progression_exact(entry)
    return type(entry) == "table"
        and (type(entry.progression_exact_ids) == "table"
            or type(entry.progression_exact_names) == "table"
            or type(entry.progression_exact_pairs) == "table")
end

local function prefer_later_progression(entry)
    return type(entry) == "table" and entry.progression_prefer_later == true and has_progression_exact(entry)
end

local function search_entry(entry)
    entry = entry or {}
    local id_only_name = require('ownership_index').name_is_id_only
    local tried = 0
    local function try(v, bank)
        if type(v) == "string" and id_only_name(v) then return nil end
        tried = tried + 1
        if tried > SEARCH_LOOKUP_BUDGET then return nil end
        local fi = find_tlo(v, bank)
        if not fi then return nil end
        local status, loc = status_from_fi(fi, bank)
        local actual = nil
        pcall(function() actual = tostring(fi.Name() or fi() or "") end)
        local fallback_name = tostring(entry.item or "")
        if type(v) == "string" then
            fallback_name = trim((v:gsub("^=", ""):gsub("%s+%(Augmented%)%s*$", "")))
            if fallback_name == "" then fallback_name = tostring(entry.item or "") end
        end
        return {
            status = status or "carried",
            location = loc or "",
            name = (actual and actual ~= "" and actual) or fallback_name,
            count = 1,
        }
    end
    local names = entry.names or {}
    local ids, seen = {}, {}
    for _, id in ipairs(entry.ids or {}) do
        local n = tonumber(id)
        if n and n > 0 and not seen[n] then
            seen[n] = true
            ids[#ids + 1] = n
        end
    end
    table.sort(ids, function(a, b) return a > b end)
    if prefer_later_progression(entry) then
        for _, n in ipairs(ids) do
            if not progression_candidate_is_exact(entry, n, nil) then
                local hit = try(n, false) or try(n, true)
                if hit then return hit end
            end
        end
        local nmax = math.min(#names, 6)
        for i = 1, nmax do
            if not progression_candidate_is_exact(entry, nil, names[i]) then
                local hit = try(names[i], false) or try(names[i], true)
                if hit then return hit end
            end
        end
    end
    local own = math.min(#names, SEARCH_OWN_NAMES)
    for i = 1, own do
        local hit = try(names[i], false) or try(names[i], true)
        if hit then return hit end
    end
    for _, n in ipairs(ids) do
        local hit = try(n, false) or try(n, true)
        if hit then return hit end
    end
    local nmax = math.min(#names, 6)
    for i = own + 1, nmax do
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

M._search_entry = search_entry -- test hook

local SPELL_STATUS_LOCATION = {
    known = "Spell book / discs",
    ready = "Ready to learn",
    pack_owned = "Pack owned",
}

--- Run BiS-style FindItem scan for this box + list_id.
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
    -- DoN learned-ability rows (spell_index refs above) are answered by THIS
    -- box's own spellbook: lean Book/CombatAbility + tome/pack by id. Peers
    -- used to fall back to the snapshot spellbook (often absent) -> false red.
    if list_id == "don" then
        local ok_ds, DS = pcall(require, 'don_spells')
        local ok_sk, SK = pcall(require, 'spell_known')
        if ok_sk and SK and SK.reset_lookup_count then SK.reset_lookup_count() end
        local rows = 0
        if ok_ds and DS and DS.spell_slots_for_class and DS.try_live_match then
            for _, slot in ipairs(DS.spell_slots_for_class(class_name)) do
                local entry = catalog.resolve_entry(list_id, class_name, slot)
                if entry then
                    local handled, match, status = DS.try_live_match(entry, { fresh = true })
                    if handled then
                        rows = rows + 1
                        status = tostring(status or "missing")
                        slots[slot] = {
                            status = status,
                            location = SPELL_STATUS_LOCATION[status] or "",
                            name = tostring(match or entry.item or slot),
                            count = status ~= "missing" and 1 or 0,
                        }
                    end
                end
            end
        end
        diag.sample("bis_search.don_spell_rows", rows)
        if ok_sk and SK and SK.lookup_count then
            diag.sample("bis_search.don_spell_lookups", SK.lookup_count())
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

function M.slot_rec_meta(snap_or_key, list_id, slot)
    if not loaded then M.load(true) end
    list_id = trim(list_id)
    slot = trim(slot)
    if list_id == "" or slot == "" then return nil, nil end
    local key = snap_or_key
    if type(snap_or_key) == "table" then
        key = char_key(snap_or_key.server, snap_or_key.name)
    end
    key = tostring(key or "")
    local rec = cache[key]
    if type(rec) ~= "table" then return nil, nil end
    local list = rec.lists and rec.lists[list_id]
    if type(list) ~= "table" or type(list.slots) ~= "table" then return nil, nil end
    return list.slots[slot], {
        key = key,
        updated = tonumber(list.updated) or 0,
        list_id = list_id,
        slot = slot,
    }
end

function M.cache_diag(snap_or_key, list_id, slot, opts)
    if not loaded then M.load(true) end
    opts = type(opts) == "table" and opts or {}
    local now = tonumber(opts.now) or os.time()
    local throttle_s = tonumber(opts.throttle_s)
    if throttle_s == nil then throttle_s = 1.0 end
    local key = snap_or_key
    if type(snap_or_key) == "table" then
        key = char_key(snap_or_key.server, snap_or_key.name)
    end
    key = tostring(key or "")
    list_id = trim(list_id)
    slot = trim(slot)
    local cache_key = table.concat({ key, list_id, slot, tostring(cache_version) }, "\31")
    local clock_now = os.clock()
    local cached = diag_cache[cache_key]
    if throttle_s > 0 and cached and (clock_now - cached.at) < throttle_s then
        return cached.value
    end
    local rec = cache[key]
    if type(rec) ~= "table" then return nil end
    local latest, oldest, list_count, slot_count = 0, nil, 0, 0
    for _, list in pairs(rec.lists or {}) do
        if type(list) == "table" then
            list_count = list_count + 1
            local updated = tonumber(list.updated) or 0
            if updated > latest then latest = updated end
            if updated > 0 and (oldest == nil or updated < oldest) then oldest = updated end
            if type(list.slots) == "table" then
                for _ in pairs(list.slots) do slot_count = slot_count + 1 end
            end
        end
    end
    local function age(ts)
        ts = tonumber(ts) or 0
        if ts <= 0 then return nil end
        return math.max(0, now - ts)
    end
    local out = {
        key = key,
        name = rec.name,
        server = rec.server,
        class = rec.class,
        listCount = list_count,
        slotCount = slot_count,
        latestUpdated = latest > 0 and latest or nil,
        latestAge = age(latest),
        oldestUpdated = oldest,
        oldestAge = age(oldest),
        ignored = ignored_cache_record(key, rec),
    }
    if list_id ~= "" then
        local list = rec.lists and rec.lists[list_id]
        if type(list) == "table" then
            out.list_id = list_id
            out.listUpdated = tonumber(list.updated) or nil
            out.listAge = age(out.listUpdated)
            if slot ~= "" then
                out.slot = slot
                local srec = type(list.slots) == "table" and list.slots[slot] or nil
                if type(srec) == "table" then
                    out.slotPresent = true
                    out.slotStatus = tostring(srec.status or "")
                    out.slotName = srec.name
                    out.slotLocation = srec.location
                    out.slotItemCount = tonumber(srec.count) or nil
                    out.slotUpdated = out.listUpdated
                    out.slotAge = out.listAge
                else
                    out.slotPresent = false
                end
            end
        end
    end
    if throttle_s > 0 then
        diag_cache[cache_key] = { at = clock_now, value = out }
    end
    return out
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
        local rec = cache[k]
        if not seen[k] and k ~= mine and not ignored_cache_record(k, rec) then
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
function M.request_via_bg(list_id, force)
    list_id = trim(list_id)
    diag.count("bis_search.request_via_bg.calls")
    if list_id == "" then
        diag.count("bis_search.request_via_bg.skipped")
        return false
    end
    if force ~= true and not M.should_request(list_id) then
        diag.count("bis_search.request_via_bg.cooldown")
        return false
    end
    M.mark_requested(list_id)
    local ok = pcall(function()
        diag.time("bis_search.request_via_bg.cmd", function()
            mq.cmd(string.format('/squelch /tgearbg bissearch %s', list_id))
        end)
    end)
    if ok then diag.count("bis_search.request_via_bg.sent") end
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
