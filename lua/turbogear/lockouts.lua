-- TurboGear/lockouts.lua
-- Dynamic zone lockout reads + custom user lockout entries (Config file).

local mq = require('mq')
local cfg = require('config')
local ref = require('references.lockouts')

local M = {}

local CACHE_TTL_S = 30.0
local BG_CACHE_TTL_S = 300.0
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
    for _, cat in ipairs(ref.category_order or {}) do cats[#cats + 1] = cat end
    if #custom_entries_for_scan() > 0 then cats[#cats + 1] = "Custom" end
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

local function is_bg_responder()
    local ok, st = pcall(require, 'state')
    return ok and st and st.bg == true
end

local function gather_lockout_data()
    local data = empty_lockout_map()
    local any = false
    for _, cat in ipairs(ref.category_order or {}) do
        for _, dz in ipairs(ref.categories[cat] or {}) do
            local timer = read_timer(dz.lockout, dz.index)
            if timer then
                data[cat][dz.name] = make_timer_record(timer, true, false)
                any = true
            end
        end
    end
    local local_name = tostring(mq.TLO.Me and mq.TLO.Me.CleanName() or "")
    for _, dz in ipairs(custom_entries_for_scan()) do
        local timer = dz.lockout ~= "" and read_timer(dz.lockout, dz.index) or nil
        local cat = dz.category or "Custom"
        data[cat] = data[cat] or {}
        if timer then
            data[cat][dz.name] = make_timer_record(timer, true, true)
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
    return data, any
end

local function open_dynamic_zone_window()
    local dz = mq.TLO.Window and mq.TLO.Window("DynamicZoneWnd")
    if dz and dz.DoOpen then dz.DoOpen() end
end

local function close_dynamic_zone_window()
    local dz = mq.TLO.Window and mq.TLO.Window("DynamicZoneWnd")
    if dz and dz.DoClose then dz.DoClose() end
end

function M.gather_local(force)
    local now = os.clock()
    local bg = is_bg_responder()
    local ttl = bg and BG_CACHE_TTL_S or CACHE_TTL_S
    if not force and cached_local and (now - cached_at) < ttl then
        return cached_local
    end

    -- Read without opening first; avoids flashing the expedition window when timers are already loaded.
    local data, any = gather_lockout_data()
    if any then
        cached_local = data
        cached_at = now
        return data
    end

    if bg and not force then
        if cached_local then return cached_local end
        if bg_open_attempted then
            cached_local = data
            cached_at = now
            return data
        end
        bg_open_attempted = true
    end

    pcall(open_dynamic_zone_window)
    data, any = gather_lockout_data()
    pcall(close_dynamic_zone_window)

    cached_local = data
    cached_at = now
    return data
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

function M.invalidate_cache()
    cached_local, cached_at = nil, 0
    bg_open_attempted = false
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
    for _, e in ipairs(custom_entries_for_scan()) do
        if trim(e.lockout or "") == label or trim(e.name or "") == label then return true end
    end
    return false
end

-- Reads all timers currently visible in the Dynamic Zone window.
-- Returns a list of { label, timer, kind } — label is the string to search by (col2),
-- timer is the countdown text (col1), kind is the timer type e.g. "Replay Timer" (col3).
function M.read_dz_timers()
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
