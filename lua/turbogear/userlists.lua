-- TurboGear/userlists.lua
-- Import/export + management for user/shared BiS lists. Pure file I/O around
-- the bis.lua user-list model; never touches the generated catalog, the actor
-- engine, or live MQ item TLOs. Safe to call from button handlers (no blocking).
--
-- Portable file format (what Export writes / Import reads): a plain Lua file
-- that returns one list table:
--   return {
--     name  = "Drel Tank Augs",       -- display name (id derives from this)
--     class = "Shadow Knight",         -- optional
--     owner = "Drel",                  -- optional
--     entries = {
--       { item = "Duskbringer's Ascendant Helm of the Hateful",
--         ids = { 32533, 31648 },      -- optional; any id present satisfies
--         slot = "Head", group = "Visibles", notes = nil },
--       ...
--     },
--   }
-- Name-only entries are allowed (ids optional), matching LazBiS slash-ID
-- equivalence semantics. Files live in the MQ Config dir.

local mq  = require('mq')
local cfg = require('config')
local bis = require('bis')

local okShell, ShellOpen = pcall(require, 'Turbo.shell_open')
if not okShell then ShellOpen = nil end

local M = {}

local function trim(s)
    return tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function norm_item_key(s)
    s = trim(s):lower()
    s = s:gsub("%s*%(%s*[^%)]-%s*%)%s*$", "")
    s = s:gsub("%s*%[%s*[^%]]-%s*%]%s*$", "")
    s = s:gsub("%s+", " ")
    local stripped = s:gsub("%s*%d%d%d+$", "")
    if stripped ~= "" then s = stripped end
    return trim(s)
end

local function sanitize_file_id(s)
    s = tostring(s or ""):lower():gsub("[^%w]+", "_"):gsub("^_+", ""):gsub("_+$", "")
    if s == "" then s = "list" end
    return s:sub(1, 48)
end

local function set_sync_hint(msg, seconds)
    local ok, state = pcall(require, 'state')
    if ok and state then
        state.sync_hint = tostring(msg or "")
        state.sync_hint_until = os.clock() + (tonumber(seconds) or 3.0)
    end
end

local function copy_entries(entries)
    local out = {}
    for _, e in ipairs(entries or {}) do
        out[#out + 1] = {
            item = e.item, ids = e.ids, names = e.names,
            slot = e.slot, group = e.group, socket = e.socket, notes = e.notes,
        }
    end
    return out
end

local function list_name_exists(name)
    name = trim(name):lower()
    if name == "" then return false end
    for _, rec in ipairs(bis.list_names()) do
        if trim(rec.name):lower() == name then return true end
    end
    return false
end

local function unique_list_name(base)
    base = trim(base)
    if base == "" then base = "Custom List" end
    if not list_name_exists(base) then return base end
    for i = 2, 99 do
        local candidate = string.format("%s %d", base, i)
        if not list_name_exists(candidate) then return candidate end
    end
    return string.format("%s %d", base, os.time())
end

function M.build_portable(list)
    list = type(list) == "table" and list or bis.get(list)
    if not list then return nil end
    return {
        name = list.name,
        class = list.class,
        owner = list.owner,
        server = list.server,
        updated = list.updated,
        exported_by = cfg.CFG.script_name .. " " .. cfg.CFG.version,
        entries = copy_entries(list.entries),
    }
end

function M.export_path(list)
    local owner = sanitize_file_id(list and list.owner or "")
    local class = sanitize_file_id(list and list.class or "")
    local tag = owner
    if class ~= "" and class ~= owner then
        tag = (tag ~= "" and (tag .. "_" .. class) or class)
    end
    if tag == "" then tag = sanitize_file_id(list and (list.id or list.name) or "list") end
    return string.format("%s/%s_export_%s.lua", mq.configDir, cfg.CFG.script_name, tag)
end

function M.export_basename(list)
    local path = M.export_path(list)
    return path:match("([^/\\]+)$") or path
end

-- Export a user list to a portable single file. Returns path or nil+err.
function M.export(list_or_id)
    local list = type(list_or_id) == "table" and list_or_id or bis.get(list_or_id)
    if not list then return nil, "List not found: " .. tostring(list_or_id) end
    local out = M.build_portable(list)
    if not out then return nil, "Could not build export." end
    local path = M.export_path(list)
    local ok, err = pcall(function() mq.pickle(path, out) end)
    if not ok then return nil, "Export failed: " .. tostring(err) end
    return path
end

function M.open_config_folder()
    local dir = tostring(mq.configDir or ""):gsub("/", "\\")
    if dir == "" then return false, "Config path unknown." end
    if ShellOpen and ShellOpen.shellOpenFolder(dir) then
        return true, dir
    end
    return false, "Could not open Config folder."
end

-- Resolve an import name to an existing readable file path, or nil.
local function resolve_import_path(name)
    name = trim(name)
    if name == "" then return nil end
    local candidates = {}
    local function add(p) candidates[#candidates+1] = p end
    if name:find("[/\\]") then
        add(name)                                    -- absolute / relative path given
    else
        add(string.format("%s/%s", mq.configDir, name))
        if not name:lower():find("%.lua$") then
            add(string.format("%s/%s.lua", mq.configDir, name))
            add(string.format("%s/%s_export_%s.lua", mq.configDir, cfg.CFG.script_name, sanitize_file_id(name)))
        end
    end
    for _, p in ipairs(candidates) do
        local f = io.open(p, "r")
        if f then f:close(); return p end
    end
    return nil
end

function M.import_table(t, opts)
    opts = type(opts) == "table" and opts or {}
    if type(t) ~= "table" then return nil, "Not a list table." end
    if type(t.entries) ~= "table" or #t.entries == 0 then
        return nil, "List has no entries."
    end
    if trim(t.name) == "" then
        t.name = "Imported List"
    end
    if opts.from_name and trim(opts.from_name) ~= "" then
        local suffix = " (from " .. trim(opts.from_name) .. ")"
        if not t.name:find(suffix, 1, true) then
            t.name = trim(t.name) .. suffix
        end
    end
    local list = bis.save_list(t)
    if not list then return nil, "Failed to save imported list." end
    return list
end

-- Import a portable list file. Saves it as a user list (normalized via bis).
-- Returns list or nil+err. Never overwrites the generated catalog.
function M.import(name)
    local path = resolve_import_path(name)
    if not path then return nil, "File not found: " .. tostring(name) end
    local ok, t = pcall(dofile, path)
    if not ok then return nil, "Could not read " .. path .. ": " .. tostring(t) end
    if type(t) ~= "table" then return nil, "Not a list file (expected a returned table): " .. path end
    return M.import_table(t)
end

-- Scan the Config dir for portable list files (best effort; needs lfs).
-- Returns array of filenames (not full paths), possibly empty.
function M.scan_importables()
    local out = {}
    local ok, lfs = pcall(require, 'lfs')
    if not ok or type(lfs) ~= "table" or not lfs.dir then return out end
    local prefix = (cfg.CFG.script_name .. "_export_"):lower()
    local ok2 = pcall(function()
        for f in lfs.dir(mq.configDir) do
            local lf = tostring(f):lower()
            if lf:sub(1, #prefix) == prefix and lf:find("%.lua$") then out[#out+1] = f end
        end
    end)
    if not ok2 then return {} end
    table.sort(out)
    return out
end

-- Create (or refresh) a user list from a snapshot's worn gear and save it.
function M.save_worn(snap, name)
    local list, err = bis.snapshot_to_list(snap, name)
    if not list then return nil, err end
    return bis.save_list(list)
end

function M.copy_catalog_list(list_id, opts)
    opts = type(opts) == "table" and opts or {}
    local okCat, catalog = pcall(require, 'bis_catalog')
    if not okCat or not catalog then return nil, "Catalog is not available." end
    local src = catalog.list(list_id)
    if not src then return nil, "BiS catalog list not found." end

    local class_name = trim(opts.class_name or mq.TLO.Me.Class() or "")
    local entries = {}
    for _, cat in ipairs(src.categories or {}) do
        for _, slot in ipairs(cat.slots or {}) do
            local entry = catalog.resolve_entry(list_id, class_name, slot)
            if entry and trim(entry.item) ~= "" then
                entries[#entries + 1] = {
                    item = entry.item,
                    names = entry.names,
                    ids = entry.ids,
                    slot = slot or entry.slot or "",
                    group = cat.name or entry.group or "",
                    socket = entry.socket,
                    notes = entry.notes,
                }
            end
        end
    end
    if #entries == 0 then
        return nil, "No catalog entries were available for this class."
    end

    local label = trim(catalog.list_label(list_id))
    if label == "" then label = "BiS Catalog" end
    local name = trim(opts.name)
    if name == "" then
        local suffix = class_name ~= "" and (" - " .. class_name) or ""
        name = unique_list_name(label .. suffix)
    end

    local list = bis.save_list({
        name = name,
        class = class_name,
        owner = trim(opts.owner or mq.TLO.Me.CleanName() or mq.TLO.Me.Name() or ""),
        server = trim(opts.server or mq.TLO.MacroQuest.Server() or ""),
        updated = os.time(),
        entries = entries,
    })
    if not list then return nil, "Could not save custom list." end
    return list
end

function M.duplicate(list_or_id, new_name)
    local list = type(list_or_id) == "table" and list_or_id or bis.get(list_or_id)
    if not list then return nil, "List not found." end
    new_name = trim(new_name)
    if new_name == "" then new_name = trim(list.name) .. " copy" end
    local copy = {
        name = new_name,
        class = list.class,
        owner = trim(mq.TLO.Me.CleanName() or mq.TLO.Me.Name() or list.owner or ""),
        server = trim(mq.TLO.MacroQuest.Server() or list.server or ""),
        updated = os.time(),
        entries = copy_entries(list.entries),
    }
    return bis.save_list(copy)
end

function M.merge_worn_missing(snap, list_or_id)
    local list = type(list_or_id) == "table" and list_or_id or bis.get(list_or_id)
    if not list then return nil, "List not found." end
    local worn, err = bis.snapshot_to_list(snap, list.name)
    if not worn then return nil, err end
    local seen = {}
    for _, e in ipairs(list.entries or {}) do
        seen[norm_item_key(e.item)] = true
    end
    local added = 0
    for _, e in ipairs(worn.entries or {}) do
        local key = norm_item_key(e.item)
        if key ~= "" and not seen[key] then
            list.entries[#list.entries + 1] = {
                item = e.item, names = e.names, ids = e.ids,
                slot = e.slot, group = e.group, notes = e.notes,
            }
            seen[key] = true
            added = added + 1
        end
    end
    if added == 0 then return nil, "No new worn items to add." end
    list.updated = os.time()
    local saved = bis.save_list(list)
    return saved, added
end

function M.create_empty(name)
    name = trim(name)
    if name == "" then
        local who = trim(mq.TLO.Me.CleanName() or mq.TLO.Me.Name() or "My")
        name = who .. " Wishlist"
    end
    local list = bis.save_list({
        name = name,
        owner = trim(mq.TLO.Me.CleanName() or mq.TLO.Me.Name() or ""),
        class = trim(mq.TLO.Me.Class() or ""),
        server = trim(mq.TLO.MacroQuest.Server() or ""),
        updated = os.time(),
        entries = {},
    })
    if not list then return nil, "Could not create list." end
    return list
end

local function split_bulk_lines(text)
    text = tostring(text or "")
    if trim(text) == "" then return {} end
    local lines = {}
    if text:find("\n", 1, true) then
        for line in text:gmatch("[^\r\n]+") do
            line = trim(line)
            if line ~= "" then lines[#lines + 1] = line end
        end
    else
        for part in text:gmatch("[^,]+") do
            part = trim(part)
            if part ~= "" then lines[#lines + 1] = part end
        end
    end
    return lines
end

function M.add_entries_bulk(list_or_id, text)
    local list = type(list_or_id) == "table" and list_or_id or bis.get(list_or_id)
    if not list then return nil, "List not found." end
    local lines = split_bulk_lines(text)
    if #lines == 0 then return nil, "Paste item names or IDs (one per line, or comma-separated)." end
    local added, failed = 0, 0
    for _, line in ipairs(lines) do
        local item = line
        local ids = {}
        local num = tonumber(line)
        if num and num > 0 then
            item = ""
            ids = { math.floor(num) }
        else
            local id_part = line:match("^(%d+)%s*$")
            if id_part then
                item = ""
                ids = { math.floor(tonumber(id_part)) }
            end
        end
        local saved, err = bis.add_entry(list.id, { item = item, ids = ids })
        if saved then
            added = added + 1
        else
            failed = failed + 1
        end
    end
    if added == 0 then
        return nil, failed > 0 and "No entries added. Check names or IDs." or "Nothing to add."
    end
    return bis.get(list.id), added, failed
end

function M.prepare_for_announces(list_or_id)
    local list = type(list_or_id) == "table" and list_or_id or bis.get(list_or_id)
    if not list then return false, "List not found." end
    cfg.Settings.bisListMode = "user"
    cfg.Settings.bisSelectedList = list.id
    pcall(cfg.SaveSettings)
    local okCat, catalog = pcall(require, 'bis_catalog')
    if okCat and catalog and catalog.set_list_announce_enabled then
        catalog.set_list_announce_enabled(list.id, true)
    end
    if cfg.SharedSettings then
        cfg.SharedSettings.bisAnnounceEnabled = true
        pcall(cfg.SaveSharedSettings)
    end
    return true, list.name
end

function M.delete(id)
    return bis.remove_list(id)
end

local function actor_mailbox()
    local ok, engine = pcall(require, 'engine')
    if not ok or not engine or not engine.Engine or not engine.Engine.ok then
        return nil
    end
    return engine.Engine.mailbox
end

local function my_actor_key()
    local ok, store = pcall(require, 'store')
    if ok and store and store.my_key then return store.my_key() end
    return (mq.TLO.MacroQuest.Server() or "?") .. "_" .. (mq.TLO.Me.CleanName() or "?")
end

function M.share_list(list_or_id)
    local list = type(list_or_id) == "table" and list_or_id or bis.get(list_or_id)
    if not list then return false, "List not found." end
    local mb = actor_mailbox()
    if not mb then return false, "Actor sync not available on this box." end
    local portable = M.build_portable(list)
    if not portable then return false, "Could not build list payload." end
    local ok = pcall(function()
        mb:send({ mailbox = cfg.CFG.mailbox }, {
            type = 'list_share',
            proto = cfg.CFG.proto,
            list = portable,
            from_key = my_actor_key(),
            from_name = trim(mq.TLO.Me.CleanName() or mq.TLO.Me.Name() or ""),
        })
    end)
    if not ok then return false, "Could not send list to peers." end
    return true, list.name
end

function M.request_lists_from_peer(peer_key, list_id)
    peer_key = trim(peer_key)
    if peer_key == "" then return false, "Pick an online peer." end
    local okStore, store = pcall(require, 'store')
    if okStore and store and store.Store then
        for _, key in ipairs(store.Store.peer_keys()) do
            local s = store.Store.get(key)
            if s and (key == peer_key or s.name == peer_key) then
                peer_key = key
                break
            end
        end
    end
    local mb = actor_mailbox()
    if not mb then return false, "Actor sync not available on this box." end
    local ok = pcall(function()
        mb:send({ mailbox = cfg.CFG.mailbox }, {
            type = 'list_request',
            proto = cfg.CFG.proto,
            target_key = peer_key,
            list_id = list_id and trim(list_id) or nil,
            from_key = my_actor_key(),
            from_name = trim(mq.TLO.Me.CleanName() or mq.TLO.Me.Name() or ""),
        })
    end)
    if not ok then return false, "Could not request lists." end
    return true
end

function M.respond_list_request(c)
    c = type(c) == "table" and c or {}
    local target = trim(c.target_key or "")
    if target == "" or target ~= my_actor_key() then return end
    local list_id = trim(c.list_id or "")
    if list_id ~= "" then
        M.share_list(list_id)
        return
    end
    for _, rec in ipairs(bis.list_names()) do
        M.share_list(rec.id)
    end
end

function M.handle_actor_message(c)
    c = type(c) == "table" and c or {}
    if c.proto and c.proto ~= cfg.CFG.proto then return end
    if c.type == 'list_share' and type(c.list) == 'table' then
        local list, err = M.import_table(c.list, { from_name = c.from_name })
        if list then
            set_sync_hint(string.format("Imported list '%s' from %s", list.name, tostring(c.from_name or "peer")), 4.0)
            cfg.Settings.bisListMode = "user"
            cfg.Settings.bisSelectedList = list.id
            pcall(cfg.SaveSettings)
        else
            set_sync_hint("List import from peer failed: " .. tostring(err or "?"), 4.0)
        end
    elseif c.type == 'list_request' then
        M.respond_list_request(c)
    end
end

return M
