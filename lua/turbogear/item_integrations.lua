-- TurboGear/item_integrations.lua
-- Action helpers for connecting item context menus to TurboBiS and TurboLoot.
-- These run only from explicit UI actions; no background scanning lives here.

local mq = require('mq')
local cfg = require('config')
local Settings, SaveSettings = cfg.Settings, cfg.SaveSettings
local bis = require('bis')
local keep_qty = require('keep_qty')
local transfers = require('turbogive_transfers')

local M = {}

local RULES = {
    { label = "KEEP", value = "KEEP" },
    { label = "SELL", value = "SELL" },
    { label = "BANK", value = "BANK" },
    { label = "TRIBUTE", value = "TRIBUTE" },
    { label = "IGNORE", value = "IGNORE" },
    { label = "ANNOUNCE", value = "ANNOUNCE" },
    { label = "DESTROY", value = "DESTROY" },
}

local COUNTS = { 1, 5, 10, 20 }
local STOCK_COUNTS = { 5, 10, 20, 50, 100 }

local function trim(s)
    return tostring(s or ""):match("^%s*(.-)%s*$") or ""
end

local function basename(path)
    return tostring(path or ""):match("([^/\\]+)$") or tostring(path or "")
end

local function join_path(a, b)
    a = tostring(a or ""):gsub("[/\\]+$", "")
    return a .. "\\" .. tostring(b or "")
end

local function file_exists(path)
    local f = io.open(path, "r")
    if f then f:close(); return true end
    return false
end

local function macroquest_path()
    local ok, path = pcall(function() return mq.TLO.MacroQuest.Path() end)
    return ok and trim(path) or ""
end

local function active_turboloot_profile()
    local ok, prof = pcall(function()
        return mq.TLO.MQ2Mono and mq.TLO.MQ2Mono.Query and mq.TLO.MQ2Mono.Query("e3,TurboLootIni")()
    end)
    prof = ok and trim(prof) or ""
    if prof == "" or prof:lower() == "null" then prof = "turboloot.ini" end
    return basename(prof)
end

function M.resolve_turboloot_ini()
    local profile = active_turboloot_profile()
    local mq_path = macroquest_path()
    local candidates = {}
    if mq_path ~= "" then
        candidates[#candidates + 1] = join_path(join_path(mq_path, "Config"), profile)
        candidates[#candidates + 1] = join_path(join_path(mq_path, "Macros"), profile)
        if profile:lower() ~= "turboloot.ini" then
            candidates[#candidates + 1] = join_path(join_path(mq_path, "Config"), "turboloot.ini")
            candidates[#candidates + 1] = join_path(join_path(mq_path, "Macros"), "turboloot.ini")
        end
    end
    for _, path in ipairs(candidates) do
        if file_exists(path) then return path end
    end
    return nil, "Could not find active turboloot INI."
end

local function read_all(path)
    local f = io.open(path, "rb")
    if not f then return nil, "Could not open " .. tostring(path) end
    local data = f:read("*a")
    f:close()
    return data or ""
end

local function write_all(path, data)
    local f = io.open(path, "wb")
    if not f then return false, "Could not write " .. tostring(path) end
    f:write(data or "")
    f:close()
    return true
end

local function set_ini_value_text(data, section, key, value)
    data = tostring(data or "")
    section, key, value = trim(section), trim(key), trim(value)
    local lines = {}
    if data ~= "" then
        for line in (data .. "\n"):gmatch("([^\r\n]*)\r?\n") do
            lines[#lines + 1] = line
        end
    end

    local out, in_section, section_found, key_written = {}, false, false, false
    local header_pat = "^%s*%[([^%]]+)%]%s*$"
    local key_pat = "^%s*([^=;#][^=]-)%s*="
    for _, line in ipairs(lines) do
        local hdr = line:match(header_pat)
        if hdr then
            if in_section and not key_written then
                out[#out + 1] = key .. "=" .. value
                key_written = true
            end
            in_section = trim(hdr):lower() == section:lower()
            if in_section then section_found = true end
            out[#out + 1] = line
        elseif in_section then
            local existing = line:match(key_pat)
            if existing and trim(existing):lower() == key:lower() then
                if not key_written then
                    out[#out + 1] = key .. "=" .. value
                    key_written = true
                end
            else
                out[#out + 1] = line
            end
        else
            out[#out + 1] = line
        end
    end

    if not section_found then
        if #out > 0 and trim(out[#out]) ~= "" then out[#out + 1] = "" end
        out[#out + 1] = "[" .. section .. "]"
        out[#out + 1] = key .. "=" .. value
    elseif in_section and not key_written then
        out[#out + 1] = key .. "=" .. value
    end
    return table.concat(out, "\n") .. "\n"
end

local function get_ini_value_text(data, section, key)
    data = tostring(data or "")
    section, key = trim(section), trim(key)
    local in_section = false
    local header_pat = "^%s*%[([^%]]+)%]%s*$"
    local kv_pat = "^%s*([^=;#][^=]-)%s*=%s*(.-)%s*$"
    for line in (data .. "\n"):gmatch("([^\r\n]*)\r?\n") do
        local hdr = line:match(header_pat)
        if hdr then
            in_section = trim(hdr):lower() == section:lower()
        elseif in_section then
            local k, v = line:match(kv_pat)
            if k and trim(k):lower() == key:lower() then
                return trim(v)
            end
        end
    end
    return nil
end

local function recipient_token(recipient, qty)
    recipient = trim(recipient)
    qty = math.floor(tonumber(qty) or 0)
    if qty > 0 then return string.format("%s %d", recipient, qty) end
    return recipient
end

local function recipient_name_from_token(token)
    token = trim(token)
    local left, right = token:match("^(.-)%s+(%d+)%s*$")
    if left and right then return trim(left) end
    return token
end

local function merge_givelist_value(existing, recipient, qty)
    recipient = trim(recipient)
    if recipient == "" then return existing or "" end
    local token = recipient_token(recipient, qty)
    existing = trim(existing)
    if existing == "" then return token end

    local out, replaced = {}, false
    for part in (existing .. "|"):gmatch("(.-)|") do
        part = trim(part)
        if part ~= "" then
            if recipient_name_from_token(part):lower() == recipient:lower() then
                out[#out + 1] = token
                replaced = true
            else
                out[#out + 1] = part
            end
        end
    end
    if not replaced then out[#out + 1] = token end
    return table.concat(out, "|")
end

function M.set_turboloot_rule(item_name, rule)
    item_name, rule = trim(item_name), trim(rule)
    if item_name == "" then return false, "No item name." end
    if rule == "" then return false, "No rule." end
    local path, err = M.resolve_turboloot_ini()
    if not path then return false, err end
    local data, read_err = read_all(path)
    if not data then return false, read_err end
    local next_data = set_ini_value_text(data, "ItemLimits", item_name, rule)
    local ok, write_err = write_all(path, next_data)
    if not ok then return false, write_err end
    return true, string.format("%s -> %s in %s", item_name, rule, basename(path))
end

function M.preview_turboloot_rule(item_name, rule)
    item_name, rule = trim(item_name), trim(rule)
    if item_name == "" then return false, "No item name." end
    if rule == "" then return false, "No rule." end
    local path, err = M.resolve_turboloot_ini()
    if not path then return false, err end
    local data, read_err = read_all(path)
    if not data then return false, read_err end
    return true, {
        path = path,
        file = basename(path),
        section = "ItemLimits",
        key = item_name,
        value = rule,
        existing = get_ini_value_text(data, "ItemLimits", item_name) or "",
    }
end

function M.set_turbogive_rule(item_name, recipient, qty, opts)
    item_name, recipient = trim(item_name), trim(recipient)
    opts = type(opts) == "table" and opts or {}
    if item_name == "" then return false, "No item name." end
    if recipient == "" then return false, "No recipient selected." end
    local path, err = M.resolve_turboloot_ini()
    if not path then return false, err end
    local data, read_err = read_all(path)
    if not data then return false, read_err end
    local existing = get_ini_value_text(data, "GiveList", item_name)
    local value = merge_givelist_value(existing, recipient, qty)
    local next_data = set_ini_value_text(data, "GiveList", item_name, value)
    local ok, write_err = write_all(path, next_data)
    if not ok then return false, write_err end
    transfers.record({
        item = item_name,
        id = opts.id,
        from = opts.owner,
        to = recipient,
        qty = qty,
        location = opts.sourceLocation,
        ini = path,
        value = value,
        at = os.time(),
        status = "rule",
    })
    return true, string.format("TurboGive: %s -> %s in %s", item_name, value, basename(path))
end

function M.preview_turbogive_rule(item_name, recipient, qty, opts)
    item_name, recipient = trim(item_name), trim(recipient)
    opts = type(opts) == "table" and opts or {}
    if item_name == "" then return false, "No item name." end
    if recipient == "" then return false, "No recipient selected." end
    local path, err = M.resolve_turboloot_ini()
    if not path then return false, err end
    local data, read_err = read_all(path)
    if not data then return false, read_err end
    local existing = get_ini_value_text(data, "GiveList", item_name)
    local value = merge_givelist_value(existing, recipient, qty)
    return true, {
        path = path,
        file = basename(path),
        section = "GiveList",
        key = item_name,
        value = value,
        existing = existing or "",
        recipient = recipient,
        qty = math.floor(tonumber(qty) or 0),
        owner = trim(opts.owner),
        sourceLocation = trim(opts.sourceLocation),
    }
end

-- =====================================================================
-- GIVE NOW (live cross-box hand-off; no INI rule written or read)
-- Builds the command from the configured broadcast transport so it follows
-- whatever the user picked in Setup (E3 / EQBC / DanNet / Custom). Returns an
-- empty command when the active transport has no targeted-send template (e.g.
-- DanNet Alt), so callers fall back to writing a TurboGive rule instead.
-- =====================================================================
local function clean_name(s)
    return tostring(s or ""):lower():gsub("[^%w]", "")
end

local function me_clean()
    local ok, n = pcall(function() return mq.TLO.Me.CleanName() end)
    return clean_name(ok and n or "")
end

local function current_zone_short()
    local ok, zone = pcall(function() return mq.TLO.Zone.ShortName() end)
    return ok and trim(zone):lower() or ""
end

local function pc_in_current_zone(name)
    name = trim(name)
    if name == "" then return false end
    if clean_name(name) == me_clean() then return true end
    local ok, id = pcall(function() return mq.TLO.Spawn("pc " .. name).ID() end)
    if ok and tonumber(id) and tonumber(id) > 0 then return true end
    ok, id = pcall(function() return mq.TLO.Spawn(name).ID() end)
    return ok and tonumber(id) and tonumber(id) > 0
end

local function snapshot_for_name(name)
    name = trim(name)
    local target_clean = clean_name(name)
    if target_clean == "" then return nil, false end
    local views = require('views')
    for _, key in ipairs(views.source_keys(true)) do
        local snap = views.source_snapshot(key)
        if snap and clean_name(snap.name or views.source_owner_name(key)) == target_clean then
            return snap, key == "__self__"
        end
    end
    return nil, false
end

local function live_zone_for(name)
    local snap, is_self = snapshot_for_name(name)
    local current_zone = current_zone_short()
    if is_self then
        if current_zone ~= "" then return current_zone, snap, is_self, "self" end
    end
    local z = trim(snap and snap.zoneShortName):lower()
    if z ~= "" then return z, snap, is_self, "snapshot" end
    if current_zone ~= "" and pc_in_current_zone(name) then
        return current_zone, snap, is_self, "spawn"
    end
    return "", snap, is_self, "unknown"
end

local function status_label(snap, is_self)
    if is_self then return "online" end
    return tostring(snap and snap.status or "")
end

local function preflight_give_now(item_id, source, recipient, opts, allow_bank)
    opts = type(opts) == "table" and opts or {}
    allow_bank = allow_bank == true
    item_id = math.floor(tonumber(item_id) or 0)
    source, recipient = trim(source), trim(recipient)
    if item_id <= 0 then return nil, "No item id (re-sync the source character)." end
    if source == "" then return nil, "No source character." end
    if recipient == "" then return nil, "No recipient selected." end
    if clean_name(source) == clean_name(recipient) then return nil, "Source and recipient are the same character." end

    local source_snap, source_self = snapshot_for_name(source)
    local recipient_snap, recipient_self = snapshot_for_name(recipient)
    local source_status = status_label(source_snap, source_self)
    local recipient_status = status_label(recipient_snap, recipient_self)
    if not source_snap and not source_self then return nil, source .. " has no live TurboGear snapshot." end
    if not recipient_snap and not recipient_self then return nil, recipient .. " has no live TurboGear snapshot." end
    if source_status ~= "online" then return nil, source .. " is " .. (source_status ~= "" and source_status or "not online") .. "." end
    if recipient_status ~= "online" then return nil, recipient .. " is " .. (recipient_status ~= "" and recipient_status or "not online") .. "." end

    local source_zone, _, _, source_zone_source = live_zone_for(source)
    local recipient_zone, _, _, recipient_zone_source = live_zone_for(recipient)
    if source_zone == "" then return nil, "Source zone unknown; Sync Now on " .. source .. "." end
    if recipient_zone == "" then return nil, "Recipient zone unknown; Sync Now on " .. recipient .. "." end
    if source_zone ~= recipient_zone then
        return nil, string.format("Not same zone: %s is in %s, %s is in %s.",
            source, source_zone, recipient, recipient_zone)
    end

    local group = tostring(opts.locationGroup or ""):lower()
    local where = tostring(opts.where or ""):lower()
    local is_bank_item = group == "bank" or where == "bank"
    if is_bank_item and not allow_bank then return nil, "Item is in bank/cache; use Bank + Give or move it to bags first." end
    if allow_bank and not is_bank_item then return nil, "Item is not marked as banked; use normal Give Now." end
    if group == "equipped" or where == "equipped" then return nil, "Item is equipped; remove it to bags first." end
    if group == "installed_aug" or where == "installed_aug" then return nil, "Aug is installed; remove it to bags first." end
    if not is_bank_item and group ~= "" and group ~= "bags" then return nil, "Item is not in a bag location TurboGive can pick up." end
    if opts.attuned == true then return nil, "Attuned item cannot be traded." end
    if (tonumber(opts.nodrop) or 0) == 1 then return nil, "No-drop item cannot be traded." end

    return {
        sourceZone = source_zone,
        recipientZone = recipient_zone,
        sourceZoneSource = source_zone_source,
        recipientZoneSource = recipient_zone_source,
        sourceStatus = source_status,
        recipientStatus = recipient_status,
    }
end

function M.give_now_command(item_id, source, recipient)
    item_id = math.floor(tonumber(item_id) or 0)
    source, recipient = trim(source), trim(recipient)
    if item_id <= 0 then return "", "No item id (re-sync the source character)." end
    if recipient == "" then return "", "No recipient selected." end
    if source == "" then return "", "No source character." end
    local inner = string.format("mac turbogive _senditem %s %d", recipient, item_id)
    if clean_name(source) == me_clean() then
        return "/" .. inner
    end
    local cmd = cfg.transport_command("target", inner, source)
    if cmd == "" then
        return "", "Active broadcast transport has no targeted-send option; use a TurboGive rule instead."
    end
    return cmd
end

function M.bank_give_now_command(item_id, source, recipient)
    item_id = math.floor(tonumber(item_id) or 0)
    source, recipient = trim(source), trim(recipient)
    if item_id <= 0 then return "", "No item id (re-sync the source character)." end
    if recipient == "" then return "", "No recipient selected." end
    if source == "" then return "", "No source character." end
    local inner = string.format("mac turbogive _banksenditem %s %d", recipient, item_id)
    if clean_name(source) == me_clean() then
        return "/" .. inner
    end
    local cmd = cfg.transport_command("target", inner, source)
    if cmd == "" then
        return "", "Active broadcast transport has no targeted-send option."
    end
    return cmd
end

function M.preview_give_now(item_name, item_id, source, recipient, opts)
    item_name = trim(item_name)
    source, recipient = trim(source), trim(recipient)
    local guard, guard_err = preflight_give_now(item_id, source, recipient, opts)
    if not guard then return false, guard_err end
    local cmd, err = M.give_now_command(item_id, source, recipient)
    if cmd == "" then return false, err end
    return true, {
        item = item_name,
        id = math.floor(tonumber(item_id) or 0),
        source = source,
        recipient = recipient,
        zone = guard.sourceZone,
        zoneSource = guard.recipientZoneSource == "spawn" and "current-zone spawn" or "snapshot",
        command = cmd,
        transport = cfg.transport_profile().label,
    }
end

function M.preview_bank_give_now(item_name, item_id, source, recipient, opts)
    item_name = trim(item_name)
    source, recipient = trim(source), trim(recipient)
    local guard, guard_err = preflight_give_now(item_id, source, recipient, opts, true)
    if not guard then return false, guard_err end
    local cmd, err = M.bank_give_now_command(item_id, source, recipient)
    if cmd == "" then return false, err end
    return true, {
        item = item_name,
        id = math.floor(tonumber(item_id) or 0),
        source = source,
        recipient = recipient,
        zone = guard.sourceZone,
        zoneSource = guard.recipientZoneSource == "spawn" and "current-zone spawn" or "snapshot",
        command = cmd,
        transport = cfg.transport_profile().label,
        requiresBanker = true,
    }
end

function M.give_now(item_name, item_id, source, recipient, opts)
    opts = type(opts) == "table" and opts or {}
    item_name = trim(item_name)
    source, recipient = trim(source), trim(recipient)
    local guard, guard_err = preflight_give_now(item_id, source, recipient, opts)
    if not guard then return false, guard_err end
    local cmd, err = M.give_now_command(item_id, source, recipient)
    if cmd == "" then return false, err end
    mq.cmd(cmd)
    transfers.record({
        item = item_name ~= "" and item_name or ("id " .. tostring(math.floor(tonumber(item_id) or 0))),
        id = item_id,
        from = source,
        to = recipient,
        qty = 1,
        location = trim(opts.sourceLocation),
        at = os.time(),
        status = "give-now",
    })
    return true, string.format("Give now: %s -> %s (%s)",
        item_name ~= "" and item_name or ("id " .. tostring(item_id)), recipient, cfg.transport_profile().label)
end

function M.bank_give_now(item_name, item_id, source, recipient, opts)
    opts = type(opts) == "table" and opts or {}
    item_name = trim(item_name)
    source, recipient = trim(source), trim(recipient)
    local guard, guard_err = preflight_give_now(item_id, source, recipient, opts, true)
    if not guard then return false, guard_err end
    local cmd, err = M.bank_give_now_command(item_id, source, recipient)
    if cmd == "" then return false, err end
    mq.cmd(cmd)
    transfers.record({
        item = item_name ~= "" and item_name or ("id " .. tostring(math.floor(tonumber(item_id) or 0))),
        id = item_id,
        from = source,
        to = recipient,
        qty = 1,
        location = trim(opts.sourceLocation),
        at = os.time(),
        status = "bank-give-now",
    })
    return true, string.format("Bank + Give: %s -> %s (%s)",
        item_name ~= "" and item_name or ("id " .. tostring(item_id)), recipient, cfg.transport_profile().label)
end

local function bis_entry_payload(item_name, item_id, slot_name, opts)
    item_name = trim(item_name)
    item_id = tonumber(item_id) or 0
    slot_name = trim(slot_name)
    opts = type(opts) == "table" and opts or {}
    local group = trim(opts.group)
    if group == "" then
        group = opts.isAug and "Aug" or (slot_name ~= "" and "Worn" or "Inventory")
    end
    local entry = {
        item = item_name,
        names = item_name ~= "" and { item_name } or {},
        ids = item_id > 0 and { math.floor(item_id) } or {},
        slot = trim(opts.hostSlot or slot_name),
        group = group,
    }
    local socket = tonumber(opts.socket)
    if socket and socket >= 1 and socket <= 6 then entry.socket = math.floor(socket) end
    return entry
end

function M.add_to_bis_list(list_id, item_name, item_id, slot_name, opts)
    list_id = trim(list_id)
    local list = bis.get(list_id)
    if not list then return false, "List not found." end
    local saved, err = bis.add_entry(list.id, bis_entry_payload(item_name, item_id, slot_name, opts))
    if not saved then return false, err or "Could not add item." end
    Settings.bisSelectedList = saved.id
    SaveSettings()
    pcall(function() require('loadout').invalidate(saved.id) end)
    local label = trim(item_name)
    if label == "" and (tonumber(item_id) or 0) > 0 then label = "item " .. tostring(math.floor(item_id)) end
    return true, string.format("Added %s to %s.", label ~= "" and label or "item", saved.name)
end

function M.preview_bis_add(list_id, item_name, item_id, slot_name, opts)
    list_id = trim(list_id)
    local list = bis.get(list_id)
    if not list then return false, "List not found." end
    item_name = trim(item_name)
    item_id = tonumber(item_id) or 0
    opts = type(opts) == "table" and opts or {}
    local payload = bis_entry_payload(item_name, item_id, slot_name, opts)
    return true, {
        list = list.name or list.id or "list",
        listId = list.id,
        item = item_name,
        id = item_id > 0 and math.floor(item_id) or 0,
        slot = payload.slot,
        group = payload.group,
        socket = payload.socket,
    }
end

function M.move_loadout_aug(list_id, entry_index, socket_index)
    local ok, loadout = pcall(require, 'loadout')
    if not ok or not loadout or not loadout.set_entry_socket then
        return false, "Loadout aug move is not available."
    end
    return loadout.set_entry_socket(list_id, entry_index, socket_index)
end

function M.create_list_and_add(item_name, item_id, slot_name, opts)
    local ok_ul, userlists = pcall(require, 'userlists')
    if not ok_ul or not userlists or not userlists.create_empty then
        return false, "List creation is not available."
    end
    local list, err = userlists.create_empty(nil)
    if not list then return false, err or "Could not create list." end
    return M.add_to_bis_list(list.id, item_name, item_id, slot_name, opts)
end

function M.add_to_selected_bis(item_name, item_id, slot_name)
    local list = bis.get(Settings.bisSelectedList)
    if not list then return false, "Select a TurboBiS user list first." end
    return M.add_to_bis_list(list.id, item_name, item_id, slot_name)
end

function M.preview_selected_bis_add(item_name, item_id, slot_name)
    local list = bis.get(Settings.bisSelectedList)
    if not list then return false, "Select a TurboBiS user list first." end
    return M.preview_bis_add(list.id, item_name, item_id, slot_name)
end

function M.bis_list_options()
    local out = {}
    for _, rec in ipairs(bis.list_names()) do
        out[#out + 1] = {
            id = rec.id,
            name = rec.name or rec.id,
            selected = rec.id == Settings.bisSelectedList,
        }
    end
    return out
end

function M.search_inventory_for(item_name)
    item_name = trim(item_name)
    if item_name == "" then return false, "No item name." end
    Settings.mainTab = "gear"
    Settings.gearTab = "inventory"
    Settings.inventoryScope = "all"
    Settings.inventoryViewMode = "table"
    Settings.inventorySearch = item_name
    SaveSettings()
    return true, "Searching cached inventory for " .. item_name .. "."
end

function M.search_inventory_and_lists(item_name)
    item_name = trim(item_name)
    if item_name == "" then return false, "No item name." end
    Settings.globalSearch = item_name
    local ok, global_search = pcall(require, 'global_search')
    if ok and global_search and global_search.invalidate then global_search.invalidate() end
    SaveSettings()
    return true, "Searching inventory and TurboBiS lists for " .. item_name .. "."
end

function M.open_bis_search(item_name)
    item_name = trim(item_name)
    if item_name == "" then return false, "No item name." end
    local ok, bis_tab = pcall(require, 'tabs.bis')
    if ok and bis_tab and bis_tab.set_filter then bis_tab.set_filter(item_name) end
    Settings.mainTab = "bis"
    Settings.bisListsTab = "catalog"
    Settings.bisListMode = "catalog"
    SaveSettings()
    return true, "Searching TurboBiS for " .. item_name .. "."
end

function M.open_suggest_for_slot(target_key, slot_id)
    slot_id = tonumber(slot_id)
    if not slot_id then return false, "No slot mapping for Suggest." end
    local ok, suggest_tab = pcall(require, 'tabs.suggestions')
    if not ok or not suggest_tab or not suggest_tab.open_for then return false, "Suggest tab is not available." end
    suggest_tab.open_for(target_key or "__self__", slot_id, { sortUpgrades = true, overview = false })
    return true, "Opening Suggest candidates."
end

function M.add_keep_qty(item_name, item_id, qty, scope)
    return keep_qty.add_or_update(item_name, item_id, qty, scope or "all")
end

function M.open_stock_view()
    Settings.mainTab = "gear"
    Settings.gearTab = "inventory"
    Settings.inventoryViewMode = "stock"
    SaveSettings()
    return true, "Opening Inventory Stock view."
end

function M.open_transfers_view()
    Settings.mainTab = "gear"
    Settings.gearTab = "inventory"
    Settings.inventoryViewMode = "transfers"
    SaveSettings()
    return true, "Opening TurboGive Transfers."
end

function M.rule_options()
    return RULES
end

function M.count_options()
    return COUNTS
end

function M.stock_count_options()
    return STOCK_COUNTS
end

function M.give_target_options(owner)
    local views = require('views')
    local owner_clean = views.clean_name(owner)
    local out, seen = {}, {}
    for _, key in ipairs(views.source_keys(true)) do
        local name = views.source_owner_name(key)
        local clean = views.clean_name(name)
        if name ~= "" and clean ~= "" and clean ~= owner_clean and not seen[clean] then
            seen[clean] = true
            out[#out + 1] = { key = key, name = name, label = views.source_label(key) }
        end
    end
    table.sort(out, function(a, b) return a.name:lower() < b.name:lower() end)
    return out
end

return M
