-- TurboGear/roster_sets.lua
-- Named character-set scopes shared by BiS roster display and linked-needs
-- announcing. Item lists decide what can be needed; roster sets decide who is
-- considered for viewing/announcing.

local mq = require('mq')
local cfg = require('config')
local Settings, SharedSettings = cfg.Settings, cfg.SharedSettings
local store_mod = require('store')
local Store, my_key = store_mod.Store, store_mod.my_key

local M = {}
M.VIEW_ALL = "__all__"
M.VIEW_SELECTED = "__selected__"

local BUILTIN_OPTIONS = {
    { key = "self",   label = "This Character" },
    { key = "online", label = "Live Peers" },
    { key = "group",  label = "Group" },
    { key = "e3",     label = "E3 Online" },
    { key = "all",    label = "All Known" },
}

local BUILTIN_LABELS = {}
for _, opt in ipairs(BUILTIN_OPTIONS) do BUILTIN_LABELS[opt.key] = opt.label end

local function trim(s)
    return tostring(s or ""):match("^%s*(.-)%s*$") or ""
end

function M.clean_name(name)
    return tostring(name or ""):lower():gsub("%s+", ""):gsub("[^%w]", "")
end

local function local_name()
    return tostring(mq.TLO.Me.CleanName() or "")
end

local function set_id_from_name(name)
    local id = M.clean_name(name)
    if id == "" then id = "set" end
    return id
end

function M.set_scope(id)
    id = set_id_from_name(id)
    return "set:" .. id
end

function M.set_id(scope)
    local id = tostring(scope or ""):match("^set:(.+)$")
    return id and set_id_from_name(id) or nil
end

function M.is_set_scope(scope)
    return M.set_id(scope) ~= nil
end

local function ensure_sets()
    if type(SharedSettings.characterSets) ~= "table" then
        SharedSettings.characterSets = {}
    end
    return SharedSettings.characterSets
end

local function normalize_members(raw)
    local out = {}
    if type(raw) ~= "table" then return out end
    for k, v in pairs(raw) do
        local label = v == true and tostring(k or "") or tostring(v or k or "")
        local clean = M.clean_name(k)
        if clean == "" then clean = M.clean_name(label) end
        if clean ~= "" then out[clean] = trim(label) ~= "" and trim(label) or clean end
    end
    return out
end

function M.get_set(id_or_scope)
    local id = M.set_id(id_or_scope) or set_id_from_name(id_or_scope)
    local rec = ensure_sets()[id]
    if type(rec) ~= "table" then return nil end
    rec.name = trim(rec.name) ~= "" and trim(rec.name) or id
    rec.members = normalize_members(rec.members)
    return rec, id
end

function M.list_sets()
    local out = {}
    for id, rec in pairs(ensure_sets()) do
        if type(rec) == "table" then
            out[#out + 1] = {
                id = id,
                key = M.set_scope(id),
                label = trim(rec.name) ~= "" and trim(rec.name) or id,
                count = (function()
                    local n = 0
                    for _ in pairs(normalize_members(rec.members)) do n = n + 1 end
                    return n
                end)(),
            }
        end
    end
    table.sort(out, function(a, b) return a.label:lower() < b.label:lower() end)
    return out
end

function M.save_set(name, members)
    name = trim(name)
    if name == "" then return nil, "Name required" end
    local normalized = normalize_members(members)
    local count = 0
    for _ in pairs(normalized) do count = count + 1 end
    if count == 0 then return nil, "Select at least one character" end
    local id = set_id_from_name(name)
    ensure_sets()[id] = {
        name = name,
        members = normalized,
        updated = os.time(),
    }
    if cfg.SaveSharedSettings then cfg.SaveSharedSettings() end
    return M.set_scope(id), count
end

function M.delete_set(id_or_scope)
    local id = M.set_id(id_or_scope) or set_id_from_name(id_or_scope)
    local sets = ensure_sets()
    if sets[id] == nil then return false end
    sets[id] = nil
    if Settings.bisRosterScope == M.set_scope(id) then
        Settings.bisRosterScope = "online"
        if cfg.SaveSettings then cfg.SaveSettings() end
    end
    if cfg.SaveSharedSettings then cfg.SaveSharedSettings() end
    return true
end

function M.scope_label(scope)
    scope = tostring(scope or "online")
    local id = M.set_id(scope)
    if id then
        local rec = M.get_set(id)
        return rec and ("Set: " .. tostring(rec.name or id)) or "Set: missing"
    end
    return BUILTIN_LABELS[scope] or BUILTIN_LABELS.online
end

function M.builtin_options()
    return BUILTIN_OPTIONS
end

local function e3_connected_names()
    local out = {}
    local ok, peers = pcall(function()
        if mq.TLO.MQ2Mono and mq.TLO.MQ2Mono.Query then
            return mq.TLO.MQ2Mono.Query("e3,E3Bots.ConnectedClients")()
        end
        return nil
    end)
    if ok and type(peers) == "string" then
        for peer in peers:gmatch("([^,]+)") do
            local name = trim(peer):match("^[%w_]+") or trim(peer)
            if name ~= "" then out[M.clean_name(name)] = true end
        end
    end
    out[M.clean_name(local_name())] = true
    return out
end

local function is_group_member(name)
    if M.clean_name(name) == M.clean_name(local_name()) then return true end
    local ok, result = pcall(function()
        return mq.TLO.Group and mq.TLO.Group.Member and mq.TLO.Group.Member(name)()
    end)
    return ok and result and true or false
end

local function recently_visible(key, snap)
    if key == "__self__" then return true end
    if Store.is_recently_visible and Store.is_recently_visible(key, snap) then return true end
    return snap and (snap.status == "online" or snap.status == "stale")
end

local function include_source(scope, key, name, snap, opts)
    opts = type(opts) == "table" and opts or {}
    scope = tostring(scope or "online")
    local set_id = M.set_id(scope)
    if set_id then
        local rec = M.get_set(set_id)
        local members = rec and rec.members or {}
        local included = members[M.clean_name(name)] ~= nil
        if not included then return false end
        if opts.for_announce then return recently_visible(key, snap) end
        return true
    end
    if scope == "self" then return key == "__self__" end
    if scope == "all" then return true end
    if scope == "group" then return is_group_member(name) end
    if scope == "e3" then
        local e3 = opts.e3 or e3_connected_names()
        return e3[M.clean_name(name)] == true and recently_visible(key, snap)
    end
    if opts.include_offline_cache and snap and snap.status == "offline" then return true end
    return key == "__self__" or recently_visible(key, snap)
end

function M.source_keys(scope, opts)
    opts = type(opts) == "table" and opts or {}
    local out = {}
    local e3 = tostring(scope or "") == "e3" and e3_connected_names() or nil
    if include_source(scope, "__self__", local_name(), nil, { e3 = e3, for_announce = opts.for_announce }) then
        out[#out + 1] = "__self__"
    end
    for _, key in ipairs(Store.peer_keys and Store.peer_keys() or {}) do
        local snap = Store.get(key)
        local name = tostring(snap and snap.name or key)
        local inc_opts = {
            e3 = e3,
            for_announce = opts.for_announce,
            include_offline_cache = opts.include_offline_cache,
        }
        if include_source(scope, key, name, snap, inc_opts) then
            out[#out + 1] = key
        end
    end
    return out
end

local function source_name_for_key(key)
    if key == "__self__" then return local_name() end
    local snap = Store.get(key)
    return tostring(snap and snap.name or key)
end

local function selected_members()
    Settings.bisViewSelectedChars = type(Settings.bisViewSelectedChars) == "table"
        and Settings.bisViewSelectedChars or {}
    return Settings.bisViewSelectedChars
end

function M.active_source_keys(scope, opts)
    opts = type(opts) == "table" and opts or {}
    local base = M.source_keys(scope, opts)
    local view_key = tostring(opts.view_key or Settings.bisViewKey or M.VIEW_ALL)
    if view_key == "" or view_key == M.VIEW_ALL then return base end

    local out = {}
    if view_key == M.VIEW_SELECTED then
        local selected = type(opts.selected) == "table" and opts.selected or selected_members()
        for _, key in ipairs(base) do
            local clean = M.clean_name(source_name_for_key(key))
            if clean ~= "" and selected[clean] ~= nil then out[#out + 1] = key end
        end
        return out
    end

    local view_clean = M.clean_name(source_name_for_key(view_key))
    for _, key in ipairs(base) do
        if key == view_key or (view_clean ~= "" and M.clean_name(source_name_for_key(key)) == view_clean) then
            out[#out + 1] = key
            break
        end
    end
    return out
end

function M.store_keys(scope, opts)
    local out = {}
    for _, key in ipairs(M.source_keys(scope, opts)) do
        out[#out + 1] = key == "__self__" and my_key() or key
    end
    return out
end

function M.active_store_keys(scope, opts)
    local out = {}
    for _, key in ipairs(M.active_source_keys(scope, opts)) do
        out[#out + 1] = key == "__self__" and my_key() or key
    end
    return out
end

function M.known_character_rows()
    local rows, seen = {}, {}
    local lname = local_name()
    local lclean = M.clean_name(lname)
    if lclean ~= "" then
        rows[#rows + 1] = { key = "__self__", name = lname, clean = lclean, status = "self" }
        seen[lclean] = true
    end
    for _, key in ipairs(Store.peer_keys and Store.peer_keys() or {}) do
        local snap = Store.get(key)
        local name = tostring(snap and snap.name or key)
        local clean = M.clean_name(name)
        if clean ~= "" and not seen[clean] then
            rows[#rows + 1] = {
                key = key,
                name = name,
                clean = clean,
                status = tostring(snap and snap.status or ""),
            }
            seen[clean] = true
        end
    end
    table.sort(rows, function(a, b)
        if a.key == "__self__" then return true end
        if b.key == "__self__" then return false end
        return tostring(a.name):lower() < tostring(b.name):lower()
    end)
    return rows
end

function M.members_from_source_keys(keys)
    local members = {}
    for _, key in ipairs(keys or {}) do
        local name
        if key == "__self__" then
            name = local_name()
        else
            local snap = Store.get(key)
            name = snap and snap.name or key
        end
        local clean = M.clean_name(name)
        if clean ~= "" then members[clean] = trim(name) ~= "" and trim(name) or clean end
    end
    return members
end

return M
