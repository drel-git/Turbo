-- TurboGear/lockouts.lua
-- Dynamic zone lockout reads + custom user lockout entries (Config file).

local mq = require('mq')
local cfg = require('config')
local diag = require('diagnostics')
local ref = require('references.lockouts')
local don_ref = require('references.don_lockouts')
local don_track = require('don_track')

local M = {}

local CACHE_TTL_S = 30.0
local BG_CACHE_TTL_S = 300.0
-- How long a read that could not see the source is held before retrying.
local UNREADABLE_RETRY_S = 15.0
local cached_local, cached_at = nil, 0
local bg_open_attempted = false
local custom_loaded, custom_entries = false, {}
local synced_custom_entries = {}

local CUSTOM_FILE = string.format("%s/%s_lockouts_custom.lua", mq.configDir, cfg.CFG.script_name)

local function trim(s)
    return tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function empty_lockout_map()
    local out = {}
    for _, cat in ipairs(ref.category_order or {}) do
        out[cat] = {}
    end
    out.DoN = {}
    out.Custom = {}
    return out
end

local function parse_timer_seconds(text)
    text = trim(text)
    if text == "" then return nil end
    local lower = text:lower()
    if lower:find("open", 1, true) or lower:find("expired", 1, true) then return 0 end
    local total = 0
    local matched = false
    for n, unit in lower:gmatch("(%d+)%s*([dhms])") do
        n = tonumber(n) or 0
        if unit == "d" then total = total + n * 86400
        elseif unit == "h" then total = total + n * 3600
        elseif unit == "m" then total = total + n * 60
        elseif unit == "s" then total = total + n end
        matched = true
    end
    if matched then return total end
    local a, b, c = lower:match("^(%d+):(%d+):(%d+)$")
    if a and b and c then return ((tonumber(a) or 0) * 3600) + ((tonumber(b) or 0) * 60) + (tonumber(c) or 0) end
    a, b = lower:match("^(%d+):(%d+)$")
    if a and b then return ((tonumber(a) or 0) * 60) + (tonumber(b) or 0) end
    return nil
end

local function format_seconds(sec)
    sec = math.max(0, math.floor(tonumber(sec) or 0))
    local d = math.floor(sec / 86400); sec = sec % 86400
    local h = math.floor(sec / 3600); sec = sec % 3600
    local m = math.floor(sec / 60)
    if d > 0 then return string.format("%dD:%02dH:%02dM", d, h, m) end
    if h > 0 then return string.format("%dH:%02dM", h, m) end
    return string.format("%dM", m)
end

--- Build a record from an exact second count rather than display text.
--- The DynamicZone TLO reports whole seconds; the window's text is truncated to
--- minutes, which put up to 59s of error into every expiresAt.
local function make_timer_record_seconds(seconds, found, custom)
    local captured = os.time()
    local remaining = math.max(0, math.floor(tonumber(seconds) or 0))
    return {
        timerText = format_seconds(remaining),
        remainingSeconds = remaining,
        capturedAt = captured,
        expiresAt = captured + remaining,
        found = found ~= false,
        custom = custom == true,
    }
end

local function make_timer_record(timer, found, custom)
    local captured = os.time()
    local remaining = parse_timer_seconds(timer)
    return {
        timerText = trim(timer),
        remainingSeconds = remaining,
        capturedAt = captured,
        expiresAt = remaining and (captured + remaining) or nil,
        found = found ~= false,
        custom = custom == true,
    }
end

function M.load_custom(force)
    if custom_loaded and not force then return custom_entries end
    custom_loaded = true
    custom_entries = {}
    local fh = io.open(CUSTOM_FILE, "r")
    if not fh then return custom_entries end
    fh:close()
    local ok, data = pcall(dofile, CUSTOM_FILE)
    if ok and type(data) == "table" and type(data.entries) == "table" then
        for _, e in ipairs(data.entries) do
            if type(e) == "table" and trim(e.name) ~= "" and
               (trim(e.lockout) ~= "" or (type(e.manualTimers) == "table" and next(e.manualTimers))) then
                local chars = nil
                if type(e.characters) == "table" and #e.characters > 0 then
                    chars = {}
                    for _, c in ipairs(e.characters) do
                        local cs = trim(c)
                        if cs ~= "" then chars[#chars + 1] = cs end
                    end
                    if #chars == 0 then chars = nil end
                end
                local manual_timers = nil
                if type(e.manualTimers) == "table" then
                    for k, v in pairs(e.manualTimers) do
                        local exp = tonumber(v)
                        if type(k) == "string" and k ~= "" and exp then
                            manual_timers = manual_timers or {}
                            manual_timers[k] = exp
                        end
                    end
                end
                custom_entries[#custom_entries + 1] = {
                    name = trim(e.name),
                    lockout = trim(e.lockout),
                    zone = trim(e.zone or ""),
                    category = trim(e.category or "Custom"),
                    label = trim(e.label or ""),
                    index = tonumber(e.index) or 2,
                    characters = chars,
                    manualTimers = manual_timers,
                    custom = true,
                }
            end
        end
    end
    return custom_entries
end

function M.save_custom(entries)
    custom_entries = type(entries) == "table" and entries or {}
    custom_loaded = true
    local ok, err = pcall(function()
        mq.pickle(CUSTOM_FILE, { entries = custom_entries, updated = os.time() })
    end)
    if not ok then return false, tostring(err) end
    cached_local, cached_at = nil, 0
    return true
end

function M.export_custom_for_sync()
    local out = {}
    for _, e in ipairs(M.load_custom()) do
        out[#out + 1] = {
            name = e.name,
            lockout = e.lockout,
            zone = e.zone,
            category = e.category,
            label = e.label,
            index = e.index,
            characters = e.characters,
            manualTimers = e.manualTimers,
            custom = true,
        }
    end
    return out
end

function M.set_synced_custom(entries)
    synced_custom_entries = {}
    if type(entries) ~= "table" then return end
    for _, e in ipairs(entries) do
        if type(e) == "table" and trim(e.name) ~= "" and
           (trim(e.lockout) ~= "" or (type(e.manualTimers) == "table" and next(e.manualTimers))) then
            local chars = nil
            if type(e.characters) == "table" and #e.characters > 0 then
                chars = {}
                for _, c in ipairs(e.characters) do
                    local cs = trim(c)
                    if cs ~= "" then chars[#chars + 1] = cs end
                end
                if #chars == 0 then chars = nil end
            end
            local manual_timers = nil
            if type(e.manualTimers) == "table" then
                for k, v in pairs(e.manualTimers) do
                    local exp = tonumber(v)
                    if type(k) == "string" and k ~= "" and exp then
                        manual_timers = manual_timers or {}
                        manual_timers[k] = exp
                    end
                end
            end
            synced_custom_entries[#synced_custom_entries + 1] = {
                name = trim(e.name),
                lockout = trim(e.lockout),
                zone = trim(e.zone or ""),
                category = trim(e.category or "Custom"),
                label = trim(e.label or ""),
                index = tonumber(e.index) or 2,
                characters = chars,
                manualTimers = manual_timers,
                custom = true,
                synced = true,
            }
        end
    end
    M.invalidate_cache()
end

local function custom_entries_for_scan()
    local out, seen = {}, {}
    local function add(entry)
        local key = trim(entry.category or "Custom") .. "\31" .. trim(entry.name) .. "\31" .. trim(entry.lockout)
        if not seen[key] then
            seen[key] = true
            out[#out + 1] = entry
        end
    end
    for _, e in ipairs(M.load_custom()) do add(e) end
    for _, e in ipairs(synced_custom_entries) do add(e) end
    return out
end

function M.add_custom(entry)
    entry = type(entry) == "table" and entry or {}
    local chars = nil
    if type(entry.characters) == "table" and #entry.characters > 0 then
        chars = {}
        for _, c in ipairs(entry.characters) do
            local cs = trim(c)
            if cs ~= "" then chars[#chars + 1] = cs end
        end
        if #chars == 0 then chars = nil end
    end
    -- Parse optional manual duration string (e.g. "6d", "4d 6h 30m")
    -- Builds a per-character expiry map: manualTimers[charname] = unix timestamp
    local manual_timers = nil
    local dur_str = trim(entry.manualDuration or "")
    if dur_str ~= "" then
        local secs = parse_timer_seconds(dur_str)
        if secs and secs > 0 then
            local exp = os.time() + secs
            -- Apply to selected characters; fall back to local char if scope is "all"
            local targets = chars
            if not targets or #targets == 0 then
                local local_name = tostring(mq.TLO.Me and mq.TLO.Me.CleanName() or "")
                if local_name ~= "" then targets = { local_name } end
            end
            if targets and #targets > 0 then
                manual_timers = {}
                for _, c in ipairs(targets) do manual_timers[c] = exp end
            end
        end
    end
    local ne = {
        name = trim(entry.name),
        lockout = trim(entry.lockout or ""),
        zone = trim(entry.zone or ""),
        category = trim(entry.category or "Custom"),
        label = trim(entry.label or ""),
        index = tonumber(entry.index) or 2,
        characters = chars,
        manualTimers = manual_timers,
        custom = true,
    }
    if ne.name == "" then
        return false, "Display name is required."
    end
    if ne.lockout == "" and (not ne.manualTimers or not next(ne.manualTimers)) then
        return false, "Enter a DZ timer label, a duration, or both."
    end
    if ne.label == "" then
        ne.label = ne.zone ~= "" and string.format("%s (%s)", ne.name, ne.zone) or ne.name
    end
    local list = M.load_custom()
    list[#list + 1] = ne
    return M.save_custom(list)
end

local function purge_synced_by_name(name)
    for i = #synced_custom_entries, 1, -1 do
        if trim(synced_custom_entries[i].name) == name then
            table.remove(synced_custom_entries, i)
        end
    end
end

function M.remove_custom_by_name(name)
    local list = M.load_custom()
    name = trim(name or "")
    for i, e in ipairs(list) do
        if trim(e.name) == name then
            table.remove(list, i)
            purge_synced_by_name(name)
            return M.save_custom(list)
        end
    end
    return false, "Entry not found."
end

function M.remove_custom_at(index)
    local list = M.load_custom()
    index = tonumber(index)
    if not index or index < 1 or index > #list then
        return false, "Invalid index."
    end
    local name = trim(list[index].name or "")
    table.remove(list, index)
    purge_synced_by_name(name)
    return M.save_custom(list)
end

function M.all_entries()
    local out = {}
    for _, cat in ipairs(ref.category_order or {}) do
        local rows = ref.categories and ref.categories[cat] or {}
        for _, entry in ipairs(rows) do
            out[#out + 1] = { category = cat, entry = entry }
        end
    end
    for _, entry in ipairs(custom_entries_for_scan()) do
        out[#out + 1] = { category = entry.category or "Custom", entry = entry }
    end
    return out
end

function M.categories_for_ui()
    local cats = {}
    for _, cat in ipairs(ref.ui_category_order or ref.category_order or {}) do
        if cat ~= "Custom" or #custom_entries_for_scan() > 0 then
            cats[#cats + 1] = cat
        end
    end
    return cats
end

function M.entries_for_category(category)
    category = tostring(category or "")
    if category == "Custom" then return custom_entries_for_scan() end
    return ref.categories and ref.categories[category] or {}
end

local function read_timer(lockout_key, index)
    lockout_key = tostring(lockout_key or "")
    if lockout_key == "" then return nil end
    index = tonumber(index) or 2
    local wnd = mq.TLO.Window and mq.TLO.Window("DynamicZoneWnd/DZ_TimerList")
    if not wnd then return nil end
    local ok, idx = pcall(function() return wnd.List(lockout_key, index)() end)
    if not ok or not idx then return nil end
    local ok2, timer = pcall(function() return wnd.List(idx, 1)() end)
    if ok2 and timer and tostring(timer) ~= "" then return tostring(timer) end
    return nil
end

local function read_first_timer(keys, index)
    for _, key in ipairs(keys or {}) do
        local timer = read_timer(key, index)
        if timer then return timer, key end
    end
    return nil, nil
end

local DZ_TIMER_CAP = 64

--- Structured timer read straight from the DynamicZone TLO.
---
--- Verified on Project Lazarus with the Expedition Information window CLOSED:
--- MaxTimers, ExpeditionName, EventName and Timer.TotalSeconds are all
--- readable. That is the whole point -- a background responder never has that
--- window open, which is why peers used to show an open padlock for a lockout
--- they demonstrably had.
---
--- It also replaces one Window.List call per tracked entry (313 per gather, all
--- of them misses in practice) with one pass over the handful of timers that
--- actually exist.
---
--- idx.ok distinguishes "the TLO says there are no timers" from "the TLO could
--- not be read", so the caller knows whether an empty result is trustworthy.
local function read_dz_timer_index()
    local idx = { by_expedition = {}, by_event = {}, rows = {}, ok = false }
    local dz = mq.TLO and mq.TLO.DynamicZone
    if not dz then return idx end

    local ok_max, max = pcall(function() return dz.MaxTimers() end)
    max = ok_max and tonumber(max) or nil
    if max == nil then return idx end
    idx.ok = true

    local function member(fn)
        local good, v = pcall(fn)
        if not good then return nil end
        return v
    end

    for i = 1, math.min(max, DZ_TIMER_CAP) do
        local timer_obj = member(function() return dz.Timer(i) end)
        if timer_obj then
            local expedition = trim(tostring(member(function() return timer_obj.ExpeditionName() end) or ""))
            local event = trim(tostring(member(function() return timer_obj.EventName() end) or ""))
            local seconds = tonumber(member(function() return timer_obj.Timer.TotalSeconds() end))
            local event_id = tonumber(member(function() return timer_obj.EventID() end))
            if seconds and seconds > 0 and (expedition ~= "" or event ~= "") then
                local rec = {
                    expedition = expedition,
                    event = event,
                    event_id = event_id,
                    seconds = seconds,
                    -- EventID -1 marks a replay timer as opposed to an event lockout.
                    replay = event_id == -1,
                }
                idx.rows[#idx.rows + 1] = rec
                -- Entries are matched case-insensitively as a fallback; the
                -- window path this replaces was exact-match only.
                if expedition ~= "" then
                    idx.by_expedition[expedition] = idx.by_expedition[expedition] or rec
                    local lower = expedition:lower()
                    idx.by_expedition[lower] = idx.by_expedition[lower] or rec
                end
                if event ~= "" then
                    idx.by_event[event] = idx.by_event[event] or rec
                    local lower = event:lower()
                    idx.by_event[lower] = idx.by_event[lower] or rec
                end
            end
        end
    end
    return idx
end

--- True when `name` is `key` followed by a qualifier rather than a longer word.
---
--- The client reports full expedition names -- "Txevu, Lair of the Elite
--- [Solo]" -- while the reference stores the short form the tab displays,
--- "Txevu". Exact matching silently dropped those lockouts: the timer was read
--- and then matched nothing, so the row rendered open.
---
--- The boundary check is what keeps this from being sloppy substring matching.
--- Requiring a non-alphanumeric next character means "Txevu" matches "Txevu,
--- Lair of the Elite [Solo]" but not a different expedition that merely starts
--- with the same letters.
local function is_qualified_name(name, key)
    if #name <= #key then return false end
    if name:sub(1, #key) ~= key then return false end
    return name:sub(#key + 1, #key + 1):match("%w") == nil
end

--- Bucketed to the minute because a row's expiry is derived as now + remaining
--- and can wobble a second between reads. A digest that wobbled would report a
--- change on every check.
local SIG_BUCKET_S = 60

--- Digest of a timer index. Absolute expiry, so a counting-down timer is stable.
local function raw_signature_from_index(idx, now)
    if type(idx) ~= "table" or not idx.ok then return nil end
    now = tonumber(now) or os.time()
    local parts = {}
    for _, row in ipairs(idx.rows or {}) do
        local seconds = tonumber(row.seconds) or 0
        if seconds > 0 then
            parts[#parts + 1] = string.format("%s|%s:%d",
                tostring(row.expedition or ""), tostring(row.event or ""),
                math.floor((now + seconds) / SIG_BUCKET_S))
        end
    end
    table.sort(parts)
    return table.concat(parts, "\31")
end

--- Raw signature the currently cached map was built from, or nil if we have
--- never completed a read. Lets a caller ask "is what I last published still
--- true?" without keeping a second copy of the truth.
local last_built_raw_sig = nil

function M.last_built_signature()
    return last_built_raw_sig
end

--- Entries carry the column they match on: 2 is the expedition name (default),
--- 3 is the event name, mirroring the old DZ_TimerList column indices.
local function lookup_dz(idx, key, column)
    if type(idx) ~= "table" or not idx.ok then return nil end
    key = trim(key)
    if key == "" then return nil end
    local by_event = tonumber(column) == 3
    local map = by_event and idx.by_event or idx.by_expedition
    local hit = map[key] or map[key:lower()]
    if hit then return hit end

    -- Only on a miss, and only across the handful of live timers.
    local lower_key = key:lower()
    for _, row in ipairs(idx.rows or {}) do
        local name = by_event and row.event or row.expedition
        if type(name) == "string" and is_qualified_name(name:lower(), lower_key) then
            return row
        end
    end
    return nil
end

local function first_dz_hit(idx, keys, column)
    for _, key in ipairs(keys or {}) do
        local hit = lookup_dz(idx, key, column)
        if hit then return hit, key end
    end
    return nil, nil
end

local function is_bg_responder()
    local ok, st = pcall(require, 'state')
    return ok and st and st.bg == true
end

local function gather_lockout_data()
    local data = empty_lockout_map()
    local any = false

    -- One structured pass replaces the per-entry window search entirely. The
    -- window path is kept only for builds where the TLO cannot be read.
    local dz_idx = read_dz_timer_index()

    local function timer_record_for(key, column, custom)
        local hit = lookup_dz(dz_idx, key, column)
        if hit then
            hit.matched = true
            return make_timer_record_seconds(hit.seconds, true, custom), hit
        end
        if dz_idx.ok then return nil, nil end
        local text = read_timer(key, column)
        if text then return make_timer_record(text, true, custom), nil end
        return nil, nil
    end

    for _, cat in ipairs(ref.category_order or {}) do
        for _, dz in ipairs(ref.categories[cat] or {}) do
            local rec = timer_record_for(dz.lockout, dz.index, false)
            if rec then
                data[cat][dz.name] = rec
                any = true
            end
        end
    end
    data.DoN = data.DoN or {}
    for _, dz in ipairs(don_ref.all_rows()) do
        local keys = don_ref.lookup_keys(dz)
        local rec, matched_key
        local hit
        hit, matched_key = first_dz_hit(dz_idx, keys, dz.index)
        if hit then
            hit.matched = true
            rec = make_timer_record_seconds(hit.seconds, true, false)
        elseif not dz_idx.ok then
            local timer
            timer, matched_key = read_first_timer(keys, dz.index)
            if timer then rec = make_timer_record(timer, true, false) end
        end
        if rec then
            rec.replay_group = dz.replay_group
            rec.matchedKey = matched_key
            rec.don = true
            data.DoN[dz.name] = rec
            any = true
        end
    end
    local local_name = tostring(mq.TLO.Me and mq.TLO.Me.CleanName() or "")
    for _, dz in ipairs(custom_entries_for_scan()) do
        local rec = dz.lockout ~= "" and timer_record_for(dz.lockout, dz.index, true) or nil
        local cat = dz.category or "Custom"
        data[cat] = data[cat] or {}
        if rec then
            data[cat][dz.name] = rec
            any = true  -- only count as "found" when a real timer was read
        else
            -- Fall back to this character's manual expiry if the DZ lookup found nothing
            local manual_exp = dz.manualTimers and local_name ~= ""
                and tonumber(dz.manualTimers[local_name]) or nil
            if manual_exp and manual_exp > os.time() then
                local remaining = math.max(0, manual_exp - os.time())
                data[cat][dz.name] = {
                    timerText = format_seconds(remaining),
                    remainingSeconds = remaining,
                    capturedAt = os.time(),
                    expiresAt = manual_exp,
                    found = true,
                    custom = true,
                    manual = true,
                }
                any = true  -- manual timer counts as found data
            else
                data[cat][dz.name] = make_timer_record("", false, true)
                -- don't set any = true: DZ window may just not be open yet
            end
        end
    end
    return data, any, dz_idx.ok, dz_idx
end

local function open_dynamic_zone_window()
    local dz = mq.TLO.Window and mq.TLO.Window("DynamicZoneWnd")
    if dz and dz.DoOpen then dz.DoOpen() end
end

local function close_dynamic_zone_window()
    local dz = mq.TLO.Window and mq.TLO.Window("DynamicZoneWnd")
    if dz and dz.DoClose then dz.DoClose() end
end

-- DoN replay state is chat-derived and advances between gathers, so it is
-- attached on every return rather than baked into the cached map. The attach is
-- a small copy; the journal read behind it rate-limits itself.
local function with_don(data)
    return don_track.embed(data)
end

--- Records we have actually observed, kept until their own expiresAt passes.
---
--- Deliberately NOT cleared by invalidate_cache(). That function exists to force
--- a re-read, and it runs on every incoming sync request via set_synced_custom.
--- Clearing observed lockouts there meant a sync could erase a timer we had
--- already read -- the "it cleared itself again" symptom, made worse by Sync Now.
local known_records = {}

--- Fold freshly read records into the known set.
local function remember_records(map)
    if type(map) ~= "table" then return end
    local now = os.time()
    for cat, entries in pairs(map) do
        if type(entries) == "table" then
            for name, rec in pairs(entries) do
                if type(rec) == "table" and rec.found == true then
                    local expires_at = tonumber(rec.expiresAt)
                    if expires_at and expires_at > now then
                        known_records[cat] = known_records[cat] or {}
                        known_records[cat][name] = rec
                    end
                end
            end
        end
    end
end

--- Carry forward records that have not reached their own expiresAt.
---
--- A gather that cannot read the timers does not report "unknown" -- it reports
--- a full map of found=false records, which is indistinguishable from "not
--- locked". Publishing that map destroys a record that was still valid by its
--- own timestamp, so a lockout would appear on login and vanish minutes later
--- once any gather ran while the timers were unreadable.
---
--- Every record carries an absolute expiresAt, so it stays true whether or not
--- the timers can be read right now. Only a real, freshly read timer replaces one.
local function preserve_unexpired(new_map, old_map)
    if type(new_map) ~= "table" or type(old_map) ~= "table" then return 0 end
    local now = os.time()
    local kept = 0
    for cat, entries in pairs(old_map) do
        if type(entries) == "table" then
            for name, rec in pairs(entries) do
                local expires_at = type(rec) == "table" and tonumber(rec.expiresAt) or nil
                if expires_at and expires_at > now then
                    local fresh = new_map[cat] and new_map[cat][name]
                    local read_now = type(fresh) == "table" and fresh.found == true
                        and trim(fresh.timerText or "") ~= ""
                    if not read_now then
                        new_map[cat] = new_map[cat] or {}
                        new_map[cat][name] = rec
                        kept = kept + 1
                    end
                end
            end
        end
    end
    return kept
end

M._preserve_unexpired = preserve_unexpired

--- Read the lockout map.
---
--- Accepts a boolean for the old force semantics, or a table separating two
--- things that used to be one. "Bypass the cache" and "you may open the
--- Expedition window" are different permissions: a background responder often
--- wants a genuinely fresh structured read and must never flash that window.
---
---   gather_local(true)                                  -- legacy: both
---   gather_local({ bypass_cache = true,
---                  allow_window_fallback = false })     -- fresh, silent
local function gather_options(arg)
    if type(arg) == "table" then
        return arg.bypass_cache == true, arg.allow_window_fallback ~= false
    end
    return arg == true, true
end

function M.gather_local(arg)
    local bypass_cache, allow_window = gather_options(arg)
    local now = os.clock()
    local bg = is_bg_responder()
    local ttl = bg and BG_CACHE_TTL_S or CACHE_TTL_S
    if not bypass_cache and cached_local and (now - cached_at) < ttl then
        diag.count("lockouts.gather.cache_hit")
        return with_don(cached_local)
    end
    diag.count("lockouts.gather.cache_miss")

    -- Read without opening first; avoids flashing the expedition window when timers are already loaded.
    local data, any, tlo_ok, idx = gather_lockout_data()
    remember_records(data)
    preserve_unexpired(data, known_records)
    -- tlo_ok means the DynamicZone TLO answered, so an empty result is a real
    -- "no timers" rather than "could not read". Opening the window would tell
    -- us nothing further, and on a background box it is pure cost.
    if any or tlo_ok then
        cached_local = data
        cached_at = now
        last_built_raw_sig = raw_signature_from_index(idx)
        return with_don(data)
    end

    -- Structured read failed and we are not allowed to fall back. Return what
    -- we know: preserve_unexpired has already restored the records we have
    -- seen, so this reports "still locked" rather than a confident all-open map
    -- built on data nobody could read.
    --
    -- Hold it only briefly. Caching for the full TTL would pin a stale answer
    -- for five minutes, but not caching at all would make every snapshot pay
    -- the per-entry window scan that an unreadable TLO falls back to.
    if not allow_window then
        diag.count("lockouts.gather.unreadable_no_fallback")
        cached_local = data
        cached_at = now - math.max(0, ttl - UNREADABLE_RETRY_S)
        return with_don(data)
    end

    if bg and not bypass_cache then
        if cached_local then return with_don(cached_local) end
        if bg_open_attempted then
            cached_local = data
            cached_at = now
            return with_don(data)
        end
        bg_open_attempted = true
    end

    pcall(open_dynamic_zone_window)
    data, any, tlo_ok, idx = gather_lockout_data()
    pcall(close_dynamic_zone_window)
    remember_records(data)
    preserve_unexpired(data, known_records)

    cached_local = data
    cached_at = now
    last_built_raw_sig = raw_signature_from_index(idx)
    return with_don(data)
end

--- Compact digest of what this box currently holds locked.
---
--- Keyed on absolute expiry rather than remaining seconds, so it changes only
--- when a lockout is gained, replaced, or drops out -- not on every tick. A
--- digest that churned would publish a snapshot every time it was checked.
---
--- Bucketed to the minute for the same reason as the raw digest: expiresAt is
--- recomputed as capturedAt + remaining on each read and wobbles a second.
function M.signature(data)
    data = type(data) == "table" and data or M.gather_local(false)
    local parts = {}
    for cat, entries in pairs(data or {}) do
        -- DoNState is state, not a lockout map, and rides in the same table.
        if type(entries) == "table" and cat ~= "DoNState" then
            for name, rec in pairs(entries) do
                if type(rec) == "table" and rec.found == true then
                    local expires = math.floor((tonumber(rec.expiresAt) or 0) / SIG_BUCKET_S)
                    parts[#parts + 1] = string.format("%s/%s:%d", cat, name, expires)
                end
            end
        end
    end
    table.sort(parts)
    return table.concat(parts, "\31")
end

--- Digest of the raw DynamicZone rows, before any matching.
---
--- A change detector cheap enough to run on a schedule: MaxTimers plus a few
--- reads per timer, no per-entry matching, and it never touches the Expedition
--- window. That last part matters -- a forced gather_local falls back to
--- opening that window when the TLO cannot be read, which on a background box
--- would mean flashing it open every minute.
---
--- Returns nil, not "", when the TLO is unreadable. "" means "no timers" and
--- would read as a change the moment we lost the ability to see them.
---
--- `now` is injectable so tests can advance the clock exactly.
function M.timer_signature(now)
    return raw_signature_from_index(read_dz_timer_index(), now)
end

--- Report what THIS process sees, as lines of text.
---
--- A standalone probe script cannot answer this. It has its own module state and
--- reads the client directly, so it can report a timer the responder never puts
--- in a snapshot. This runs inside the process that actually publishes.
function M.diagnose()
    local out = {}
    local function add(fmt, ...)
        out[#out + 1] = select('#', ...) > 0 and string.format(fmt, ...) or fmt
    end

    local me = tostring(mq.TLO.Me and mq.TLO.Me.CleanName() or "?")
    local bg = is_bg_responder()
    add("[TurboGear] lockout diag: %s  role=%s", me, bg and "bg responder" or "ui/viewer")
    add("  cache: %s, age %.1fs (ttl %ds)",
        cached_local and "populated" or "empty",
        cached_local and (os.clock() - cached_at) or 0,
        bg and BG_CACHE_TTL_S or CACHE_TTL_S)

    -- Gather directly rather than through gather_local: this must report what
    -- the TLO says right now, without disturbing the cache or the record of
    -- what state the last published map was built from.
    local data, _, tlo_ok, idx = gather_lockout_data()
    remember_records(data)
    preserve_unexpired(data, known_records)

    add("  DynamicZone TLO readable: %s, rows %d", tostring(idx.ok), #(idx.rows or {}))
    for i, row in ipairs(idx.rows or {}) do
        add("    [%d] expedition=%q event=%q seconds=%s matched=%s", i,
            tostring(row.expedition or ""), tostring(row.event or ""), tostring(row.seconds),
            tostring(row.matched == true))
    end

    local scan = custom_entries_for_scan()
    add("  custom entries in scan list: %d", #scan)
    for _, e in ipairs(scan) do
        add("    %s: name=%q lockout=%q index=%s scope=%s",
            e.synced and "synced" or "file",
            tostring(e.name), tostring(e.lockout), tostring(e.index),
            e.characters and table.concat(e.characters, ",") or "all")
    end

    local known = 0
    for _, entries in pairs(known_records) do
        for _ in pairs(entries) do known = known + 1 end
    end
    add("  remembered unexpired records: %d", known)

    local locked = 0
    for cat, entries in pairs(data) do
        if type(entries) == "table" and cat ~= "DoNState" then
            for name, rec in pairs(entries) do
                if type(rec) == "table" and rec.found == true then
                    locked = locked + 1
                    add("  LOCKED %s / %s -> %s", cat, name, tostring(rec.timerText))
                end
            end
        end
    end
    if locked == 0 then add("  LOCKED: none") end

    -- A sparse map stores absence as "open", so a row can render open either
    -- because there is genuinely no lockout or because a live timer matched no
    -- canonical entry. Only the diagnostic needs to tell those apart.
    add("  raw timers %d, matched %d, source readable %s, last published built from %s",
        #(idx.rows or {}), locked, tostring(tlo_ok),
        last_built_raw_sig == nil and "(never gathered)" or (last_built_raw_sig == "" and "no timers" or "a timer set"))
    for _, row in ipairs(idx.rows or {}) do
        if not row.matched then
            add("    UNMATCHED raw timer: expedition=%q event=%q -- no canonical row claims this",
                tostring(row.expedition or ""), tostring(row.event or ""))
        end
    end

    -- The other half. Producing a correct map locally proves nothing about what
    -- the tab renders, which reads the Store. Listing every row here separates
    -- "the peer never sent it" from "it arrived and the cell is wrong".
    local ok_store, store = pcall(function() return require('store').Store end)
    if ok_store and type(store) == "table" and type(store.sources) == "table" then
        add("  Store rows (what this box would render):")
        local keys = {}
        for key in pairs(store.sources) do keys[#keys + 1] = tostring(key) end
        table.sort(keys)
        if #keys == 0 then add("    (none)") end
        for _, key in ipairs(keys) do
            local row = store.sources[key]
            local lmap = type(row) == "table" and row.lockouts or nil
            if type(lmap) ~= "table" then
                add("    %s: NO lockout map", key)
            else
                local held, entries_seen = {}, 0
                for cat, entries in pairs(lmap) do
                    if type(entries) == "table" and cat ~= "DoNState" then
                        for name, rec in pairs(entries) do
                            entries_seen = entries_seen + 1
                            if type(rec) == "table" and rec.found == true then
                                held[#held + 1] = cat .. "/" .. name
                            end
                        end
                    end
                end
                table.sort(held)
                add("    %s: %d entries, %d locked%s", key, entries_seen, #held,
                    #held > 0 and (" -- " .. table.concat(held, ", ")) or "")
            end
        end
    end
    return out
end

function M.read_from_snap(snap)
    if snap and type(snap.lockouts) == "table" then return snap.lockouts end
    return nil
end

function M.is_locked(snap, category, entry_name)
    local data = M.read_from_snap(snap)
    if not data then return false, nil end
    category = tostring(category or "")
    entry_name = tostring(entry_name or "")
    local record = data[category] and data[category][entry_name]
    if type(record) == "table" then
        if record.found == false then return false, nil, "missing_custom" end
        local expires = tonumber(record.expiresAt)
        if expires and expires <= os.time() then return false, "Expired", "expired" end
        local remaining = expires and math.max(0, expires - os.time()) or tonumber(record.remainingSeconds)
        local display = remaining and format_seconds(remaining) or tostring(record.timerText or "")
        if display ~= "" then return true, display, "locked" end
        return false, nil, "open"
    end
    if record and tostring(record) ~= "" then
        local remaining = parse_timer_seconds(record)
        if remaining == 0 then return false, "Expired", "expired" end
        return true, tostring(record), "locked_legacy"
    end
    return false, nil, "open"
end

function M.cell_status(snap, category, entry_name)
    local locked, timer, status = M.is_locked(snap, category, entry_name)
    return { locked = locked, timer = timer, status = status or (locked and "locked" or "open") }
end

function M.record(snap, category, entry_name)
    local data = M.read_from_snap(snap)
    if not data then return nil end
    category = tostring(category or "")
    entry_name = tostring(entry_name or "")
    local record = data[category] and data[category][entry_name]
    return type(record) == "table" and record or nil
end

--- Force the next gather to re-read. Observed lockouts are intentionally kept:
--- forcing a re-read is not the same as declaring what we already saw untrue.
function M.invalidate_cache()
    cached_local, cached_at = nil, 0
    bg_open_attempted = false
end

--- Drop observed lockouts as well. For tests, and for a deliberate user reset.
function M.forget_known_lockouts()
    known_records = {}
end

-- Returns true if a DZ label string is already tracked (catalog or custom).
function M.label_already_tracked(label)
    label = trim(label or "")
    if label == "" then return true end
    for _, cat in ipairs(ref.category_order or {}) do
        for _, entry in ipairs(ref.categories[cat] or {}) do
            if trim(entry.lockout or "") == label then return true end
        end
    end
    if don_ref.lookup(label) then return true end
    for _, e in ipairs(custom_entries_for_scan()) do
        if trim(e.lockout or "") == label or trim(e.name or "") == label then return true end
    end
    return false
end

-- Reads all timers currently visible in the Dynamic Zone window.
-- Returns a list of { label, timer, kind } — label is the string to search by (col2),
-- timer is the countdown text (col1), kind is the timer type e.g. "Replay Timer" (col3).
function M.read_dz_timers()
    -- Prefer the TLO: it works with the expedition window closed, so "Pick from
    -- DZ" no longer requires the user to open it first.
    local idx = read_dz_timer_index()
    if idx.ok and #idx.rows > 0 then
        local out = {}
        for _, rec in ipairs(idx.rows) do
            out[#out + 1] = {
                label = rec.expedition ~= "" and rec.expedition or rec.event,
                timer = format_seconds(rec.seconds),
                kind = rec.event,
            }
        end
        return out
    end

    local list_wnd = mq.TLO.Window and mq.TLO.Window("DynamicZoneWnd/DZ_TimerList")
    if not list_wnd then return {} end
    local ok_count, count = pcall(function() return list_wnd.Items() end)
    count = ok_count and tonumber(count) or 0
    if not count or count < 1 then return {} end
    local out = {}
    for i = 1, count do
        local ok1, col1 = pcall(function() return list_wnd.List(i, 1)() end)
        local ok2, col2 = pcall(function() return list_wnd.List(i, 2)() end)
        local ok3, col3 = pcall(function() return list_wnd.List(i, 3)() end)
        local label = ok2 and trim(tostring(col2 or "")) or ""
        local timer = ok1 and trim(tostring(col1 or "")) or ""
        local kind  = ok3 and trim(tostring(col3 or "")) or ""
        if label ~= "" and label ~= "nil" then
            out[#out + 1] = { label = label, timer = timer, kind = kind }
        end
    end
    return out
end

-- Returns true if entry has no character scope, or char_name is in its characters list.
function M.entry_applies_to(entry, char_name)
    if type(entry) ~= "table" then return true end
    local chars = entry.characters
    if type(chars) ~= "table" or #chars == 0 then return true end
    local lower = tostring(char_name or ""):lower()
    for _, c in ipairs(chars) do
        if tostring(c):lower() == lower then return true end
    end
    return false
end

return M
