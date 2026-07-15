-- TurboGear/loadout.lua
-- Virtual worn snapshots built from TurboBiS user lists (loadout planning).

local mq = require('mq')
local ImGui = require('ImGui')
local bis = require('bis')
local items = require('items')
local stat_defs = require('stat_defs')
local theme = require('theme')
local Theme, col_text = theme.Theme, theme.col_text
local themed_button = theme.themed_button
local nav_button = theme.nav_button
local views = require('views')
local item_actions = require('item_actions')

local M = {}

M.LIST_PREFIX = "list:"

local ANALYZE_MODES = {
    { key = "list", label = "This list" },
    { key = "worn", label = "vs Worn" },
    { key = "list_list", label = "vs List" },
}

local snapshot_cache = {}

local function trim(s)
    return tostring(s or ""):match("^%s*(.-)%s*$") or ""
end

local function clone_map(src)
    local out = {}
    for k, v in pairs(src or {}) do out[k] = v end
    return out
end

function M.list_key(list_id)
    list_id = trim(list_id)
    if list_id == "" then return nil end
    return M.LIST_PREFIX .. list_id
end

function M.is_list_key(key)
    return type(key) == "string" and key:sub(1, #M.LIST_PREFIX) == M.LIST_PREFIX
end

function M.list_id_from_key(key)
    if not M.is_list_key(key) then return nil end
    local id = trim(key:sub(#M.LIST_PREFIX + 1))
    return id ~= "" and id or nil
end

function M.get_list(list_id)
    list_id = M.list_id_from_key(list_id) or list_id
    return bis.get(list_id)
end

function M.list_options()
    return bis.list_names()
end

function M.selected_list_id(fallback)
    local Settings = require('config').Settings
    local id = trim(Settings and Settings.bisSelectedList or "")
    if id ~= "" and bis.get(id) then return id end
    local lists = M.list_options()
    if lists[1] then return lists[1].id end
    return fallback
end

function M.invalidate(list_id)
    if list_id then
        snapshot_cache[list_id] = nil
        return
    end
    snapshot_cache = {}
end

local function entry_item_id(entry)
    for _, raw in ipairs(entry and entry.ids or {}) do
        local id = tonumber(raw)
        if id and id > 0 then return math.floor(id) end
    end
    return 0
end

local function entry_item_name(entry)
    local name = trim(entry and entry.item)
    if name ~= "" then return name end
    for _, raw in ipairs(entry and entry.names or {}) do
        name = trim(raw)
        if name ~= "" then return name end
    end
    return ""
end

local function entry_group(entry)
    return trim(entry and entry.group):lower()
end

local function entry_is_aug(entry, virtual)
    if entry_group(entry):find("aug", 1, true) then return true end
    if (tonumber(virtual and virtual.augType) or 0) > 0 then return true end
    if virtual and virtual.itemType == "aug" then return true end
    return false
end

local function parse_host_slot_label(entry)
    local slot_str = trim(entry and entry.slot)
    if slot_str == "" then return nil, nil end
    local host, sock = slot_str:match("^(.-)%s+[Ss](%d+)%s*$")
    if host and sock then return trim(host), tonumber(sock) end
    host, sock = slot_str:match("^(.-)%s+[Aa]ug%s*(%d+)%s*$")
    if host and sock then return trim(host), tonumber(sock) end
    return slot_str, nil
end

local function entry_socket_index(entry, parsed_sock)
    local n = tonumber(entry and entry.socket)
    if n and n >= 1 and n <= 6 then return math.floor(n) end
    n = tonumber(parsed_sock)
    if n and n >= 1 and n <= 6 then return math.floor(n) end
    return nil
end

local function infer_slot_id(entry, virtual)
    local host_label, _ = parse_host_slot_label(entry)
    if host_label and host_label ~= "" then
        local slot_id = items.slot_id_for_label(host_label)
        if slot_id then return slot_id end
    end
    local from_label = items.slot_id_for_label(entry and entry.slot)
    if from_label then return from_label end
    for _, sid in ipairs(virtual and virtual.slots or {}) do
        sid = tonumber(sid)
        if sid and sid >= 0 and sid <= 22 then return sid end
    end
    return nil
end

local function host_base_stats(virtual)
    if virtual and virtual._baseStats then return virtual._baseStats end
    local total = clone_map(virtual and virtual.stats or stat_defs.default_stats())
    if virtual and virtual.statsMerged == true and type(virtual.augs) == "table" then
        for _, aug in ipairs(virtual.augs) do
            if aug and not aug.empty and type(aug.stats) == "table" then
                for k, v in pairs(aug.stats) do
                    local n = tonumber(v) or 0
                    if n ~= 0 then total[k] = (tonumber(total[k]) or 0) - n end
                end
            end
        end
    end
    return total
end

local function ensure_host_augs(host)
    if type(host.augs) == "table" and #host.augs > 0 then return end
    host.augs = {}
    for i = 1, 6 do
        host.augs[#host.augs + 1] = {
            index = i,
            type = 0,
            name = "Empty",
            id = 0,
            icon = 0,
            empty = true,
            stats = stat_defs.default_stats(),
            classes = {},
            allClasses = false,
            slots = {},
            itemType = "aug",
            requiredLevel = 0,
            recommendedLevel = 0,
            tribute = 0,
            focusEffects = {},
            wornFocusEffects = {},
            clicky = nil,
        }
    end
end

local function apply_planned_aug(host, aug_virtual, socket_index, entry_index)
    ensure_host_augs(host)
    socket_index = math.max(1, math.min(6, math.floor(tonumber(socket_index) or 1)))

    local target = nil
    for _, a in ipairs(host.augs) do
        if tonumber(a.index) == socket_index then target = a; break end
    end
    if not target then
        target = { index = socket_index, type = 0 }
        host.augs[#host.augs + 1] = target
    end

    target.name = aug_virtual.name or "?"
    target.id = aug_virtual.id or 0
    target.icon = aug_virtual.icon or 0
    target.empty = false
    target.stats = clone_map(aug_virtual.stats or stat_defs.default_stats())
    target.classes = aug_virtual.classes or {}
    target.allClasses = aug_virtual.allClasses
    target.itemType = "aug"
    target.focusEffects = aug_virtual.focusEffects or {}
    target.wornFocusEffects = aug_virtual.wornFocusEffects or {}
    target.unresolved = aug_virtual.unresolved
    target.loadoutEntryIndex = entry_index
    if (tonumber(aug_virtual.augType) or 0) > 0 and (tonumber(target.type) or 0) == 0 then
        target.type = aug_virtual.augType
    end
end

local function recompute_host_stats(host)
    host._baseStats = host._baseStats or host_base_stats(host)
    host.stats = items.effective_stats(host._baseStats, host.augs)
    host.statsMerged = true
end

function M.build_snapshot(list_id, opts)
    opts = type(opts) == "table" and opts or {}
    list_id = M.list_id_from_key(list_id) or trim(list_id)
    if list_id == "" then return nil end
    if not opts.force and snapshot_cache[list_id] then return snapshot_cache[list_id] end

    local list = bis.get(list_id)
    if not list then return nil end

    local slot_map = {}
    local aug_queue = {}
    local unresolved = 0

    for index, entry in ipairs(list.entries or {}) do
        local item_id = entry_item_id(entry)
        local item_name = entry_item_name(entry)
        if item_name == "" and item_id <= 0 then goto continue_entry end

        local host_label, parsed_sock = parse_host_slot_label(entry)
        local probe_slot = items.slot_id_for_label(host_label or entry.slot)
        local virtual = items.make_virtual_item(item_id, item_name, probe_slot, host_label or entry.slot)

        if entry_is_aug(entry, virtual) then
            local host_slot_id = items.slot_id_for_label(host_label or entry.slot)
            local socket_index = entry_socket_index(entry, parsed_sock) or 1
            aug_queue[#aug_queue + 1] = {
                entry = entry,
                index = index,
                virtual = virtual,
                host_slot_id = host_slot_id,
                socket_index = socket_index,
            }
            goto continue_entry
        end

        local slot_id = infer_slot_id(entry, virtual)
        if not slot_id then goto continue_entry end

        virtual.slotid = slot_id
        virtual.slotname = items.slot_display_name(slot_id)
        virtual.where = virtual.slotname
        virtual._baseStats = host_base_stats(virtual)
        if virtual.unresolved then unresolved = unresolved + 1 end
        slot_map[slot_id] = virtual
        ::continue_entry::
    end

    for _, rec in ipairs(aug_queue) do
        local host = rec.host_slot_id and slot_map[rec.host_slot_id] or nil
        if host then
            apply_planned_aug(host, rec.virtual, rec.socket_index, rec.index)
            if rec.virtual.unresolved then unresolved = unresolved + 1 end
        end
    end

    for _, host in pairs(slot_map) do
        recompute_host_stats(host)
    end

    local equipped = {}
    for slot_id = 0, 22 do
        local it = slot_map[slot_id]
        if it then equipped[#equipped + 1] = it end
    end

    local snap = {
        name = list.name or list_id,
        class = list.class or "",
        owner = list.owner or "",
        server = trim(mq.TLO.MacroQuest.Server() or list.server or ""),
        status = "loadout",
        depth = "loadout",
        listId = list.id,
        equipped = equipped,
        unresolved = unresolved,
        updated = list.updated or os.time(),
    }
    snapshot_cache[list_id] = snap
    return snap
end

function M.set_entry_socket(list_id, entry_index, socket_index)
    list_id = trim(list_id)
    entry_index = tonumber(entry_index)
    socket_index = tonumber(socket_index)
    if list_id == "" or not entry_index or not socket_index then return false, "Invalid loadout aug move." end
    if socket_index < 1 or socket_index > 6 then return false, "Socket must be 1-6." end
    local list, err = bis.update_entry_at(list_id, entry_index, { socket = math.floor(socket_index) })
    if not list then return false, err or "Could not update list entry." end
    M.invalidate(list_id)
    return true, string.format("Moved aug to socket %d.", math.floor(socket_index))
end

function M.index_equipped(snap)
    local map = {}
    for _, it in ipairs((snap and snap.equipped) or {}) do
        if it.slotid ~= nil then map[it.slotid] = it end
    end
    return map
end

local function row_stats(item)
    local out = {}
    local stats = type(item and item.stats) == "table" and item.stats or stat_defs.default_stats()
    for k, v in pairs(stats) do out[k] = v end
    if item and item.statsMerged ~= true and type(item.augs) == "table" then
        for _, aug in ipairs(item.augs) do
            if aug and not aug.empty and type(aug.stats) == "table" then
                for k, v in pairs(aug.stats) do
                    local n = tonumber(v) or 0
                    if n ~= 0 then out[k] = (tonumber(out[k]) or 0) + n end
                end
            end
        end
    end
    out.tribute = tonumber(item and item.tribute) or tonumber(out.tribute) or 0
    return out
end

local function row_base_stats(item)
    local out = {}
    local source = type(item and item._baseStats) == "table" and item._baseStats
        or type(item and item.baseStats) == "table" and item.baseStats
        or nil
    if source then
        for k, v in pairs(source) do out[k] = v end
    else
        local stats = row_stats(item)
        for k, v in pairs(stats) do out[k] = v end
        if item and item.statsMerged == true and type(item.augs) == "table" then
            for _, aug in ipairs(item.augs) do
                if aug and not aug.empty and type(aug.stats) == "table" then
                    for k, v in pairs(aug.stats) do
                        local n = tonumber(v) or 0
                        if n ~= 0 then out[k] = (tonumber(out[k]) or 0) - n end
                    end
                end
            end
        end
    end
    out.tribute = tonumber(item and item.tribute) or tonumber(out.tribute) or 0
    return out
end

function M.snapshot_index_rows(snap)
    if not snap then return {} end
    local rows = {}
    local owner_status = tostring(snap.depth or "") == "loadout" and "loadout" or (snap.online and "live" or "cached")
    for _, item in ipairs(snap.equipped or {}) do
        rows[#rows + 1] = {
            owner = snap.name or "?",
            ownerClass = snap.class or "",
            ownerStatus = owner_status,
            server = snap.server or "",
            name = item.name or "?",
            id = tonumber(item.id) or 0,
            icon = tonumber(item.icon) or 0,
            kind = "item",
            where = "equipped",
            locationGroup = "equipped",
            location = item.slotname or item.where or "Equipped",
            slotid = item.slotid,
            slotname = item.slotname,
            installedIn = "",
            installedInId = 0,
            slots = type(item.slots) == "table" and item.slots or {},
            classes = type(item.classes) == "table" and item.classes or {},
            allClasses = item.allClasses and true or false,
            itemType = item.itemType or "unknown",
            requiredLevel = tonumber(item.requiredLevel) or 0,
            recommendedLevel = tonumber(item.recommendedLevel) or 0,
            tribute = tonumber(item.tribute) or 0,
            augType = tonumber(item.augType) or 0,
            nodrop = tonumber(item.nodrop) or 0,
            depth = tostring(item.depth or snap.depth or "full"),
            stats = row_stats(item),
            baseStats = row_base_stats(item),
            focusEffects = type(item.focusEffects) == "table" and item.focusEffects or {},
            wornFocusEffects = type(item.wornFocusEffects) == "table" and item.wornFocusEffects or {},
            clicky = item.clicky,
            unresolved = item.unresolved and true or false,
            sourceKey = table.concat({ snap.server or "", snap.name or "", tostring(snap.depth or "worn"), tostring(item.slotid or ""), tostring(item.id or 0) }, ":"),
        }
        for _, aug in ipairs(item.augs or {}) do
            if aug and not aug.empty then
                rows[#rows + 1] = {
                    owner = snap.name or "?",
                    ownerClass = snap.class or "",
                    ownerStatus = owner_status,
                    server = snap.server or "",
                    name = aug.name or "?",
                    id = tonumber(aug.id) or 0,
                    icon = tonumber(aug.icon) or 0,
                    kind = "aug",
                    where = "installed_aug",
                    locationGroup = "installed_aug",
                    location = string.format("%s Aug Slot %s", item.slotname or "Item", tostring(aug.index or "?")),
                    slotid = item.slotid,
                    slotname = item.slotname,
                    installedIn = item.name or "",
                    installedInId = item.id or 0,
                    slots = {},
                    classes = type(aug.classes) == "table" and aug.classes or {},
                    allClasses = aug.allClasses and true or false,
                    itemType = "aug",
                    requiredLevel = tonumber(aug.requiredLevel) or 0,
                    recommendedLevel = tonumber(aug.recommendedLevel) or 0,
                    tribute = tonumber(aug.tribute) or 0,
                    augType = tonumber(aug.type) or 0,
                    nodrop = 0,
                    depth = tostring(aug.depth or snap.depth or "full"),
                    stats = row_stats(aug),
                    focusEffects = type(aug.focusEffects) == "table" and aug.focusEffects or {},
                    wornFocusEffects = type(aug.wornFocusEffects) == "table" and aug.wornFocusEffects or {},
                    clicky = nil,
                    unresolved = aug.unresolved and true or false,
                    loadoutEntryIndex = aug.loadoutEntryIndex,
                    sourceKey = table.concat({ snap.server or "", snap.name or "", tostring(snap.depth or "worn"), "aug", tostring(item.slotid or ""), tostring(aug.index or ""), tostring(aug.id or 0) }, ":"),
                }
            end
        end
    end
    return rows
end

function M.index_rows(list_id)
    return M.snapshot_index_rows(M.build_snapshot(list_id))
end

function M.total_stats(snap)
    local totals = stat_defs.default_stats()
    for _, item in ipairs((snap and snap.equipped) or {}) do
        local stats = row_stats(item)
        for k, v in pairs(stats) do
            local n = tonumber(v) or 0
            if n ~= 0 then totals[k] = (tonumber(totals[k]) or 0) + n end
        end
    end
    return totals
end

function M.stat_delta(totals_a, totals_b)
    local delta = {}
    for _, def in ipairs(stat_defs.stats) do
        local a = tonumber(totals_a and totals_a[def.key]) or 0
        local b = tonumber(totals_b and totals_b[def.key]) or 0
        local d = b - a
        if d ~= 0 then delta[def.key] = d end
    end
    return delta
end

function M.format_delta_summary(delta, max_parts)
    max_parts = tonumber(max_parts) or 8
    local parts = {}
    local function append(key, d)
        if not d or d == 0 or stat_defs.analyze_skip_key(key) then return end
        local sign = d > 0 and "+" or ""
        parts[#parts + 1] = string.format("%s %s%s", stat_defs.analyze_label(key), sign, stat_defs.format_value(key, d))
    end
    for _, group in ipairs(stat_defs.analyze_column_groups) do
        for _, key in ipairs(group) do
            append(key, delta and delta[key])
            if #parts >= max_parts then break end
        end
        if #parts >= max_parts then break end
    end
    for _, key in ipairs(stat_defs.analyze_extra_keys or {}) do
        append(key, delta and delta[key])
        if #parts >= max_parts then break end
    end
    if #parts == 0 then return "No stat differences" end
    return table.concat(parts, " | ")
end

local function focus_entry_sig(kind, effect, slot_label)
    return table.concat({
        tostring(kind or ""),
        tostring(effect and effect.typeName or ""),
        tostring(effect and (effect.spellName or effect.description) or ""),
        tostring(slot_label or ""),
    }, "\1")
end

local function append_focus_entries(out, host, kind, effects)
    for _, effect in ipairs(effects or {}) do
        local slot_label = host.slotname or host.where or ""
        if host.kind == "aug" then
            slot_label = string.format("%s S%s", tostring(host.slotname or "Item"), tostring(host.index or "?"))
        end
        out[#out + 1] = {
            kind = kind,
            typeName = effect.typeName or "",
            maxEffect = tonumber(effect.maxEffect) or 0,
            rank = tonumber(effect.rank) or 0,
            spellName = effect.spellName or effect.description or "",
            slot = slot_label,
            itemName = host.name or "?",
            itemId = tonumber(host.id) or 0,
            sig = focus_entry_sig(kind, effect, slot_label),
        }
    end
end

function M.collect_focus_entries(snap)
    local out = {}
    for _, item in ipairs((snap and snap.equipped) or {}) do
        append_focus_entries(out, item, "Focus", item.focusEffects)
        append_focus_entries(out, item, "Worn", item.wornFocusEffects)
        for _, aug in ipairs(item.augs or {}) do
            if aug and not aug.empty then
                local host = {
                    name = aug.name,
                    id = aug.id,
                    slotname = item.slotname,
                    index = aug.index,
                    kind = "aug",
                }
                append_focus_entries(out, host, "Focus", aug.focusEffects)
                append_focus_entries(out, host, "Worn", aug.wornFocusEffects)
            end
        end
    end
    return out
end

function M.focus_delta(snap_a, snap_b)
    local map_a, map_b = {}, {}
    for _, entry in ipairs(M.collect_focus_entries(snap_a)) do
        map_a[entry.sig] = entry
    end
    for _, entry in ipairs(M.collect_focus_entries(snap_b)) do
        map_b[entry.sig] = entry
    end
    local gained, lost = {}, {}
    for sig, entry in pairs(map_b) do
        if not map_a[sig] then gained[#gained + 1] = entry end
    end
    for sig, entry in pairs(map_a) do
        if not map_b[sig] then lost[#lost + 1] = entry end
    end
    table.sort(gained, function(a, b)
        local ak = (a.kind or "") .. (a.typeName or "")
        local bk = (b.kind or "") .. (b.typeName or "")
        if ak ~= bk then return ak < bk end
        return (a.slot or "") < (b.slot or "")
    end)
    table.sort(lost, function(a, b)
        local ak = (a.kind or "") .. (a.typeName or "")
        local bk = (b.kind or "") .. (b.typeName or "")
        if ak ~= bk then return ak < bk end
        return (a.slot or "") < (b.slot or "")
    end)
    return gained, lost
end

local function delta_color(value, stat_key)
    local n = tonumber(value) or 0
    if n == 0 then return Theme.dim end
    if stat_defs.lower_better(stat_key) then
        return n < 0 and Theme.haveWorn or Theme.missing
    end
    return n > 0 and Theme.haveWorn or Theme.missing
end

local function focus_value_text(entry)
    if (entry.rank or 0) > 0 then return "Rank " .. tostring(entry.rank) end
    if (entry.maxEffect or 0) ~= 0 then return tostring(entry.maxEffect) end
    return "-"
end

local function stat_rows_nonzero(totals)
    local rows = {}
    for _, group in ipairs(stat_defs.analyze_column_groups) do
        for _, key in ipairs(group) do
            if stat_defs.analyze_has_value(key, totals) then
                rows[#rows + 1] = {
                    key = key,
                    label = stat_defs.analyze_label(key),
                    value = stat_defs.analyze_value(key, totals),
                }
            end
        end
    end
    for _, key in ipairs(stat_defs.analyze_extra_keys or {}) do
        if stat_defs.analyze_has_value(key, totals) then
            rows[#rows + 1] = {
                key = key,
                label = stat_defs.analyze_label(key),
                value = stat_defs.analyze_value(key, totals),
            }
        end
    end
    return rows
end

local function stat_compare_rows(totals_a, totals_b)
    return stat_defs.analyze_compare_rows(totals_a, totals_b)
end

local function compare_row_changed(row)
    return row and (tonumber(row.d) or 0) ~= 0
end

local function compare_row_label(row)
    return row.label or (row.def and row.def.label) or "?"
end

local function draw_compare_row_values(row, col_a, col_b, col_change)
    ImGui.TableSetColumnIndex(col_a)
    col_text(Theme.dim, stat_defs.format_value(row.def.key, row.a))
    ImGui.TableSetColumnIndex(col_b)
    col_text(Theme.item, stat_defs.format_value(row.def.key, row.b))
    ImGui.TableSetColumnIndex(col_change)
    local sign = row.d > 0 and "+" or ""
    col_text(delta_color(row.d, row.def.key), sign .. stat_defs.format_value(row.def.key, row.d))
end

local function draw_focus_source(entry, suffix)
    local name = entry.itemName or "?"
    local slot = entry.slot or "?"
    item_actions.draw_name(name, Theme.item, suffix, entry.itemId)
    if slot ~= "" then
        ImGui.SameLine()
        col_text(Theme.dim, "(" .. slot .. ")")
    end
end

local function table_scroll_flags()
    return (ImGuiTableFlags.BordersInnerV or 0)
        + (ImGuiTableFlags.RowBg or 0)
        + (ImGuiTableFlags.ScrollY or 0)
end

local function table_header_scroll_flags()
    return table_scroll_flags() + (ImGuiTableFlags.ScrollY or 0)
end

local function setup_frozen_header(table_id)
    pcall(function() ImGui.TableSetupScrollFreeze(0, 1) end)
    if views.setup_scroll_freeze then
        pcall(views.setup_scroll_freeze, table_id, 0, 1)
    end
end

local function delta_is_good(d, stat_key)
    d = tonumber(d) or 0
    if d == 0 then return nil end
    if stat_defs.lower_better(stat_key) then return d < 0 end
    return d > 0
end

local function analyze_stat_scores(totals_a, totals_b)
    local better, worse, same = 0, 0, 0
    local top_gain, top_loss = {}, {}
    for _, row in ipairs(stat_compare_rows(totals_a, totals_b)) do
        local d = tonumber(row.d) or 0
        if d == 0 then
            same = same + 1
        elseif delta_is_good(d, row.def.key) then
            better = better + 1
            top_gain[#top_gain + 1] = row
        else
            worse = worse + 1
            top_loss[#top_loss + 1] = row
        end
    end
    local function sort_abs(a, b)
        return math.abs(a.d) > math.abs(b.d)
    end
    table.sort(top_gain, sort_abs)
    table.sort(top_loss, sort_abs)
    return better, worse, same, top_gain, top_loss
end

local function format_top_delta_parts(rows, limit)
    limit = tonumber(limit) or 4
    local parts = {}
    for i = 1, math.min(limit, #(rows or {})) do
        local row = rows[i]
        local sign = row.d > 0 and "+" or ""
        parts[#parts + 1] = string.format("%s %s%s", row.def.label, sign, stat_defs.format_value(row.def.key, row.d))
    end
    if #parts == 0 then return "" end
    return table.concat(parts, ", ")
end

local function focus_shared_count(snap_a, snap_b)
    local map_a = {}
    for _, entry in ipairs(M.collect_focus_entries(snap_a)) do
        map_a[entry.sig] = true
    end
    local shared = 0
    for _, entry in ipairs(M.collect_focus_entries(snap_b)) do
        if map_a[entry.sig] then shared = shared + 1 end
    end
    return shared
end

local function draw_comparison_summary(totals_a, totals_b, label_a, label_b, snap_a, snap_b, target_label)
    target_label = target_label or label_b
    local better, worse, same, top_gain, top_loss = analyze_stat_scores(totals_a, totals_b)
    local gained, lost = M.focus_delta(snap_a, snap_b)
    local shared = focus_shared_count(snap_a, snap_b)

    col_text(Theme.section or Theme.header, "Comparison summary")
    col_text(Theme.dim, string.format("Change column = %s compared to %s (positive usually means %s is higher).",
        label_b, label_a, label_b))

    col_text(Theme.header, string.format("Stats: %d better | %d worse | %d same",
        better, worse, same))

    local gain_text = format_top_delta_parts(top_gain, 4)
    if gain_text ~= "" then
        col_text(Theme.haveWorn, "Biggest gains: " .. gain_text)
    end
    local loss_text = format_top_delta_parts(top_loss, 4)
    if loss_text ~= "" then
        col_text(Theme.missing, "Biggest losses: " .. loss_text)
    end

    col_text(Theme.header, string.format("Focus: %d shared | +%d new on %s | -%d only on %s",
        shared, #gained, label_b, #lost, label_a))

    local stat_verdict
    if better == 0 and worse == 0 then
        stat_verdict = "Stats: identical totals."
    elseif better > worse then
        stat_verdict = string.format("Stats: %s looks stronger overall (%d upgrades vs %d losses).",
            target_label, better, worse)
    elseif worse > better then
        stat_verdict = string.format("Stats: %s trades down on more stats (%d losses vs %d upgrades). Review losses before switching.",
            target_label, worse, better)
    else
        stat_verdict = string.format("Stats: mixed tradeoff (%d upgrades, %d losses). No clear stat winner.",
            better, worse)
    end

    local focus_verdict
    if #gained == 0 and #lost == 0 then
        focus_verdict = "Focus: same effects on both sides."
    elseif #gained > #lost then
        focus_verdict = string.format("Focus: %s adds more effects than it removes (+%d new, -%d lost).",
            target_label, #gained, #lost)
    elseif #lost > #gained then
        focus_verdict = string.format("Focus: switching costs more effects than you gain (-%d lost, +%d new).",
            #lost, #gained)
    else
        focus_verdict = string.format("Focus: equal swap (%d new, %d lost) - check which lines matter for your class.",
            #gained, #lost)
    end

    col_text(better >= worse and Theme.haveWorn or Theme.amber, stat_verdict)
    col_text(#gained >= #lost and Theme.haveWorn or Theme.amber, focus_verdict)
    ImGui.Spacing()
end

local function draw_stat_totals_multi_column(totals, table_id, max_height, num_cols)
    num_cols = math.max(1, tonumber(num_cols) or #stat_defs.analyze_column_groups)
    local groups = stat_defs.analyze_totals_rows(totals)
    local any = false
    for i = 1, num_cols do
        if groups[i] and #groups[i] > 0 then any = true; break end
    end
    if not any then
        col_text(Theme.placeholder or Theme.dim, "No stat totals (add slotted items or resolve amber entries).")
        return
    end
    local per_col = 0
    for i = 1, num_cols do
        per_col = math.max(per_col, groups[i] and #groups[i] or 0)
    end
    local pair_cols = num_cols * 2
    local stat_w, val_w = 76.0, 46.0
    if num_cols >= 5 then stat_w, val_w = 72.0, 44.0 end
    ImGui.BeginChild(table_id .. "_wrap", 0, max_height or 200.0, false)
    if ImGui.BeginTable(table_id, pair_cols, table_scroll_flags()) then
        for c = 1, num_cols do
            ImGui.TableSetupColumn("Stat##" .. table_id .. "_s" .. c, ImGuiTableColumnFlags.WidthFixed, stat_w)
            ImGui.TableSetupColumn("Total##" .. table_id .. "_v" .. c, ImGuiTableColumnFlags.WidthFixed, val_w)
        end
        ImGui.TableNextRow()
        for c = 0, num_cols - 1 do
            ImGui.TableSetColumnIndex(c * 2)
            local header = stat_defs.analyze_column_headers and stat_defs.analyze_column_headers[c + 1] or ""
            col_text(Theme.section or Theme.header, header)
            ImGui.TableSetColumnIndex(c * 2 + 1)
            ImGui.TextDisabled("")
        end
        for i = 1, per_col do
            ImGui.TableNextRow()
            for c = 0, num_cols - 1 do
                local row = groups[c + 1] and groups[c + 1][i]
                ImGui.TableSetColumnIndex(c * 2)
                if row then
                    col_text(Theme.header, row.label)
                    ImGui.TableSetColumnIndex(c * 2 + 1)
                    col_text(Theme.value, row.value)
                else
                    ImGui.TextDisabled("")
                    ImGui.TableSetColumnIndex(c * 2 + 1)
                    ImGui.TextDisabled("")
                end
            end
        end
        ImGui.EndTable()
    end
    ImGui.EndChild()
end

local function draw_stat_totals_dual_column(totals, table_id, max_height)
    draw_stat_totals_multi_column(totals, table_id, max_height, #stat_defs.analyze_column_groups)
end

local function draw_stat_compare_table(totals_a, totals_b, label_a, label_b, table_id, max_height)
    local rows = stat_compare_rows(totals_a, totals_b)
    if #rows == 0 then
        col_text(Theme.placeholder or Theme.dim, "No stat data to compare.")
        return false
    end
    local any_delta = false
    for _, row in ipairs(rows) do
        if compare_row_changed(row) then any_delta = true; break end
    end
    if not any_delta then
        col_text(Theme.dim, "Same stat totals - no differences.")
    end
    ImGui.BeginChild(table_id .. "_wrap", 0, max_height or 240.0, false)
    if ImGui.BeginTable(table_id, 4, table_header_scroll_flags()) then
        ImGui.TableSetupColumn("Stat", ImGuiTableColumnFlags.WidthFixed, 118.0)
        ImGui.TableSetupColumn(label_a, ImGuiTableColumnFlags.WidthStretch, 1.0)
        ImGui.TableSetupColumn(label_b, ImGuiTableColumnFlags.WidthStretch, 1.0)
        ImGui.TableSetupColumn("Change", ImGuiTableColumnFlags.WidthFixed, 72.0)
        setup_frozen_header(table_id)
        ImGui.TableHeadersRow()
        for _, row in ipairs(rows) do
            ImGui.TableNextRow()
            ImGui.TableSetColumnIndex(0)
            col_text(compare_row_changed(row) and Theme.amber or Theme.dim, compare_row_label(row))
            draw_compare_row_values(row, 1, 2, 3)
        end
        ImGui.EndTable()
    end
    ImGui.EndChild()
    return true
end

local function draw_focus_summary_table(entries, table_id, max_height)
    if #(entries or {}) == 0 then
        col_text(Theme.placeholder or Theme.dim, "No focus or worn effects on this loadout.")
        return
    end
    local flags = (ImGuiTableFlags.BordersInnerV or 0)
        + (ImGuiTableFlags.RowBg or 0)
        + (ImGuiTableFlags.ScrollY or 0)
    ImGui.BeginChild(table_id .. "_wrap", 0, max_height or 160.0, false)
    if ImGui.BeginTable(table_id, 4, flags) then
        ImGui.TableSetupColumn("Kind", ImGuiTableColumnFlags.WidthFixed, 52.0)
        ImGui.TableSetupColumn("Effect", ImGuiTableColumnFlags.WidthStretch, 1.4)
        ImGui.TableSetupColumn("Value", ImGuiTableColumnFlags.WidthFixed, 56.0)
        ImGui.TableSetupColumn("From", ImGuiTableColumnFlags.WidthStretch, 1.6)
        for fi, entry in ipairs(entries) do
            ImGui.TableNextRow()
            ImGui.TableSetColumnIndex(0)
            col_text(entry.kind == "Worn" and Theme.cyan or Theme.purple, entry.kind or "?")
            ImGui.TableSetColumnIndex(1)
            col_text(Theme.item, entry.typeName ~= "" and entry.typeName or entry.spellName or "?")
            ImGui.TableSetColumnIndex(2)
            col_text(Theme.value, focus_value_text(entry))
            ImGui.TableSetColumnIndex(3)
            draw_focus_source(entry, table_id .. "_from_" .. tostring(fi))
        end
        ImGui.EndTable()
    end
    ImGui.EndChild()
end

local function draw_focus_delta_tables(gained, lost, label_gained, label_lost, table_suffix)
    table_suffix = tostring(table_suffix or "focus")
    if #gained == 0 and #lost == 0 then
        col_text(Theme.dim, "No focus or worn effect differences.")
        return
    end
    col_text(Theme.dim, "New = on the right side only. Lost = on the left side only. Shared effects are not listed.")
    local function draw_table(entries, label, color, suffix)
        if #entries == 0 then return end
        col_text(color or Theme.header, label)
        local flags = table_header_scroll_flags()
        local tid = "loadout_analyze_focus_" .. table_suffix .. "_" .. suffix
        ImGui.BeginChild(tid .. "_wrap", 0, math.min(180.0, 28.0 + #entries * 20.0), false)
        if ImGui.BeginTable(tid, 3, flags) then
            ImGui.TableSetupColumn("Effect", ImGuiTableColumnFlags.WidthStretch, 1.4)
            ImGui.TableSetupColumn("Value", ImGuiTableColumnFlags.WidthFixed, 56.0)
            ImGui.TableSetupColumn("From", ImGuiTableColumnFlags.WidthStretch, 1.6)
            setup_frozen_header(tid)
            ImGui.TableHeadersRow()
            for fi, entry in ipairs(entries) do
                ImGui.TableNextRow()
                ImGui.TableSetColumnIndex(0)
                col_text(Theme.item, string.format("%s %s", entry.kind or "?", entry.typeName or entry.spellName or "?"))
                ImGui.TableSetColumnIndex(1)
                col_text(Theme.value, focus_value_text(entry))
                ImGui.TableSetColumnIndex(2)
                draw_focus_source(entry, tid .. "_from_" .. tostring(fi))
            end
            ImGui.EndTable()
        end
        ImGui.EndChild()
    end
    draw_table(gained, label_gained, Theme.haveWorn, "gain")
    draw_table(lost, label_lost, Theme.missing, "lost")
end

local function ensure_analyze_defaults(Settings)
    Settings.statsAnalyzeMode = Settings.statsAnalyzeMode or "list"
    Settings.statsAnalyzeCompareList = Settings.statsAnalyzeCompareList or ""
    Settings.statsAnalyzeWornKey = Settings.statsAnalyzeWornKey or ""
end

local function resolve_worn_key(list_id, preferred_key)
    preferred_key = trim(preferred_key)
    if preferred_key ~= "" then
        return views.validate_source_key(preferred_key)
    end
    local list = M.get_list(list_id)
    local owner = trim(list and list.owner or "")
    if owner ~= "" then
        for _, key in ipairs(views.source_keys(true)) do
            local snap = views.source_snapshot(key)
            if snap and views.clean_name(snap.name) == views.clean_name(owner) then
                return key
            end
        end
    end
    return "__self__"
end

local function character_label(key)
    key = views.validate_source_key(key or "__self__")
    local snap = views.source_snapshot(key)
    if not snap then return views.source_label(key) end
    local cls = views.class_abbrev and views.class_abbrev(snap.class or "") or ""
    if cls and cls ~= "" then return string.format("%s (%s)", snap.name or "?", cls) end
    return snap.name or views.source_label(key)
end

local function snapshot_stats_ok(snap)
    if not snap then return false end
    if tostring(snap.depth or "") == "full" then return true end
    local totals = M.total_stats(snap)
    for _, def in ipairs(stat_defs.stats) do
        if (tonumber(totals[def.key]) or 0) ~= 0 then return true end
    end
    return false
end

local function worn_slot_map(snap)
    local out = {}
    for _, item in ipairs((snap and snap.equipped) or {}) do
        local sid = tonumber(item.slotid)
        if sid and sid >= 0 and sid <= 22 then out[sid] = item end
    end
    return out
end

local function aug_summary(item)
    local parts = {}
    for _, aug in ipairs((item and item.augs) or {}) do
        if not aug.empty and views.aug_visible(aug) then
            local slot = tonumber(aug.index) or #parts + 1
            parts[#parts + 1] = string.format("S%d: %s", slot, tostring(aug.name or "?"))
        end
    end
    return parts
end

local function draw_worn_gear_table(snap, source_key, table_id, max_height)
    local map = worn_slot_map(snap)
    col_text(Theme.section or Theme.header, "Worn gear")
    ImGui.BeginChild(table_id .. "_wrap", 0, max_height or 470.0, false)
    if ImGui.BeginTable(table_id, 3, table_header_scroll_flags()) then
        ImGui.TableSetupColumn("Slot", ImGuiTableColumnFlags.WidthFixed, 72.0)
        ImGui.TableSetupColumn("Item", ImGuiTableColumnFlags.WidthStretch, 1.4)
        ImGui.TableSetupColumn("Augs", ImGuiTableColumnFlags.WidthStretch, 1.6)
        setup_frozen_header(table_id)
        ImGui.TableHeadersRow()
        for _, group in ipairs(items.grouped_slots()) do
            views.draw_section_row(group.label, 3)
            for _, slot in ipairs(group.slots or {}) do
                local item = map[slot.id]
                ImGui.TableNextRow()
                ImGui.TableSetColumnIndex(0)
                col_text(Theme.slot, slot.label)
                ImGui.TableSetColumnIndex(1)
                if item then
                    item_actions.draw_name(item.name or "?", Theme.item,
                        table_id .. "_item_" .. tostring(slot.id), item.id,
                        item_actions.context_opts({ sourceLocation = tostring(item.slotname or slot.label) }, item, snap and snap.name))
                else
                    col_text(Theme.placeholder or Theme.dim, "(empty)")
                end
                ImGui.TableSetColumnIndex(2)
                local parts = aug_summary(item)
                if #parts == 0 then
                    col_text(Theme.placeholder or Theme.dim, "-")
                else
                    for i, text in ipairs(parts) do
                        if i > 1 then ImGui.SameLine(); col_text(Theme.dim, " | "); ImGui.SameLine() end
                        col_text(Theme.aug or Theme.green, text)
                    end
                end
            end
        end
        ImGui.EndTable()
    end
    ImGui.EndChild()
end

local function draw_analyze_mode_picker(Settings, SaveSettings)
    ensure_analyze_defaults(Settings)
    local mode = Settings.statsAnalyzeMode or "list"
    for i, opt in ipairs(ANALYZE_MODES) do
        if i > 1 then ImGui.SameLine() end
        if nav_button(opt.label .. "##analyze_mode_" .. opt.key, mode == opt.key, true, 0, 22.0) then
            Settings.statsAnalyzeMode = opt.key
            SaveSettings()
        end
    end
end

local function find_list_for_character(name)
    name = views.clean_name(name)
    if name == "" then return "" end
    for _, rec in ipairs(M.list_options()) do
        local list = M.get_list(rec.id)
        if list and views.clean_name(list.owner or "") == name then
            return rec.id
        end
    end
    return ""
end

function M.draw_worn_summary(source_key, opts)
    opts = type(opts) == "table" and opts or {}
    local config = require('config')
    local Settings = config.Settings
    local SaveSettings = config.SaveSettings
    source_key = views.validate_source_key(source_key or Settings.statsSourceKey or "__self__")
    local snap = views.source_snapshot(source_key)
    if not snap then
        col_text(Theme.amber, "Could not load character snapshot. Sync Now or pick another character.")
        return
    end

    local label = character_label(source_key)
    local item_count = #(snap.equipped or {})
    local worn_focus = M.collect_focus_entries(snap)
    local worn_totals = M.total_stats(snap)

    col_text(Theme.section or Theme.header, string.format("Worn totals: %s", label))
    col_text(Theme.dim, string.format("%d equipped items | %d focus/worn effects", item_count, #worn_focus))
    if not snapshot_stats_ok(snap) then
        if tostring(snap.depth or "") ~= "full" and #(snap.equipped or {}) > 0 then
            col_text(Theme.amber, "Cached inventory only - stat totals need a full Sync while this character is online.")
        else
            col_text(Theme.amber, "Stats may be incomplete - Sync Now for full totals.")
        end
    end

    local layout_id = "stats_worn_layout_" .. tostring(source_key)
    if ImGui.BeginTable(layout_id, 2, ImGuiTableFlags.Resizable + ImGuiTableFlags.BordersInnerV) then
        ImGui.TableSetupColumn("Gear", ImGuiTableColumnFlags.WidthFixed, opts.gear_width or 370.0)
        ImGui.TableSetupColumn("Analysis", ImGuiTableColumnFlags.WidthStretch, 1.0)
        ImGui.TableNextRow()
        ImGui.TableSetColumnIndex(0)
        draw_worn_gear_table(snap, source_key, "stats_worn_gear_" .. tostring(source_key), opts.gear_height or 470.0)
        ImGui.TableSetColumnIndex(1)
        col_text(Theme.section or Theme.header, "Stat totals")
        draw_stat_totals_multi_column(worn_totals, "stats_worn_totals_" .. tostring(source_key), opts.stat_height or 250.0)

        ImGui.Spacing()
        col_text(Theme.section or Theme.header, string.format("Focus and worn effects (%d)", #worn_focus))
        draw_focus_summary_table(worn_focus, "stats_worn_focus_" .. tostring(source_key), opts.focus_height or 170.0)
        ImGui.EndTable()
    else
        draw_worn_gear_table(snap, source_key, "stats_worn_gear_" .. tostring(source_key), opts.gear_height or 260.0)
        ImGui.Spacing()
        col_text(Theme.section or Theme.header, "Stat totals")
        draw_stat_totals_multi_column(worn_totals, "stats_worn_totals_" .. tostring(source_key), opts.stat_height or 280.0)

        ImGui.Spacing()
        col_text(Theme.section or Theme.header, string.format("Focus and worn effects (%d)", #worn_focus))
        draw_focus_summary_table(worn_focus, "stats_worn_focus_" .. tostring(source_key), opts.focus_height or 170.0)
    end

    if opts.show_actions ~= false then
        ImGui.Spacing()
        local plan_id = find_list_for_character(snap.name) or M.selected_list_id() or ""
        if plan_id ~= "" then
            if themed_button("Compare to plan##stats_worn_plan", Theme.cyan) then
                Settings.statsViewMode = "plan"
                Settings.statsSourceScope = "loadout"
                Settings.statsLoadoutList = plan_id
                Settings.statsAnalyzeMode = "worn"
                Settings.statsAnalyzeWornKey = source_key
                SaveSettings()
                M.invalidate(plan_id)
            end
            ImGui.SameLine()
        else
            if themed_button("Create a plan##stats_worn_create", Theme.cyan) then
                Settings.mainTab = "setup"
                SaveSettings()
            end
            ImGui.SameLine()
        end
        if themed_button("Open slot compare##stats_worn_slots", Theme.cyan) then
            local ok_cmp, cmp = pcall(require, 'tabs.compare')
            if ok_cmp and cmp then
                Settings.mainTab = "upgrade"
                Settings.upgradeTab = "compare"
                Settings.compareMode = "chars"
                Settings.compareKey1 = source_key
                SaveSettings()
            end
        end
    end
    ImGui.Separator()
end

function M.draw_summary(list_id, opts)
    opts = type(opts) == "table" and opts or {}
    list_id = trim(list_id)
    if list_id == "" then list_id = M.selected_list_id() or "" end
    if list_id == "" then
        col_text(Theme.amber, "Pick a loadout list to analyze.")
        return
    end

    local Settings = require('config').Settings
    local SaveSettings = require('config').SaveSettings
    ensure_analyze_defaults(Settings)

    local snap = M.build_snapshot(list_id)
    if not snap then
        col_text(Theme.amber, "Could not build loadout snapshot.")
        return
    end

    local mode = Settings.statsAnalyzeMode or "list"
    local item_count = #(snap.equipped or {})
    local list_focus = M.collect_focus_entries(snap)
    local list_totals = M.total_stats(snap)

    col_text(Theme.section or Theme.header, string.format("Plan totals: %s", snap.name or list_id))
    draw_analyze_mode_picker(Settings, SaveSettings)
    mode = Settings.statsAnalyzeMode or "list"

    local status = string.format("List: %s (%d items) | %d focus/worn effects",
        snap.name or list_id, item_count, #list_focus)
    if (snap.unresolved or 0) > 0 then
        status = status .. string.format(" | %d unresolved", snap.unresolved)
    end
    col_text(Theme.dim, status)

    local worn_key, worn_snap, worn_label
    local other_id, other_snap, other_label
    local compare_left, compare_right, label_left, label_right

    if mode == "worn" then
        worn_key = resolve_worn_key(list_id, Settings.statsAnalyzeWornKey)
        worn_snap = views.source_snapshot(worn_key)
        worn_label = character_label(worn_key)
        ImGui.Text("Character:")
        ImGui.SameLine()
        local picked = views.draw_source_picker("##analyze_worn_key", Settings.statsAnalyzeWornKey ~= "" and Settings.statsAnalyzeWornKey or worn_key, 200.0)
        if picked ~= Settings.statsAnalyzeWornKey then
            Settings.statsAnalyzeWornKey = picked
            SaveSettings()
            worn_key = resolve_worn_key(list_id, picked)
            worn_snap = views.source_snapshot(worn_key)
            worn_label = character_label(worn_key)
        end
        col_text(Theme.dim, string.format("Comparing this list to worn gear on %s", worn_label))
        if not snapshot_stats_ok(worn_snap) then
            col_text(Theme.amber, "Worn stats may be incomplete - Sync Now for full totals.")
        end
        compare_left = worn_snap
        compare_right = snap
        label_left = worn_label or "Worn"
        label_right = snap.name or "This list"
    elseif mode == "list_list" then
        other_id = trim(Settings.statsAnalyzeCompareList or "")
        if other_id == "" or other_id == list_id then
            for _, rec in ipairs(M.list_options()) do
                if rec.id ~= list_id then other_id = rec.id; break end
            end
        end
        Settings.statsAnalyzeCompareList = other_id
        other_snap = other_id ~= "" and M.build_snapshot(other_id) or nil
        other_label = other_snap and other_snap.name or "Other list"
        ImGui.Text("Other list:")
        ImGui.SameLine()
        other_id = M.draw_list_picker("##analyze_other_list", other_id, 200.0, list_id)
        if other_id ~= Settings.statsAnalyzeCompareList then
            Settings.statsAnalyzeCompareList = other_id
            SaveSettings()
            other_snap = other_id ~= "" and M.build_snapshot(other_id) or nil
            other_label = other_snap and other_snap.name or "Other list"
        end
        if not other_snap then
            col_text(Theme.amber, "Pick another list to compare, or create one in Setup.")
        else
            col_text(Theme.dim, string.format("Comparing %s vs %s", snap.name or list_id, other_label))
            if (other_snap.unresolved or 0) > 0 then
                col_text(Theme.amber, string.format("%d unresolved on %s - stats may be incomplete.", other_snap.unresolved, other_label))
            end
        end
        compare_left = snap
        compare_right = other_snap
        label_left = snap.name or "This list"
        label_right = other_label or "Other list"
    end

    ImGui.Spacing()
    if mode ~= "list" and compare_left and compare_right then
        draw_comparison_summary(
            M.total_stats(compare_left),
            M.total_stats(compare_right),
            label_left,
            label_right,
            compare_left,
            compare_right,
            label_right)
    end

    col_text(Theme.section or Theme.header, "Stat totals")

    if mode == "list" then
        draw_stat_totals_multi_column(list_totals, "loadout_summary_stats_" .. list_id, opts.stat_height or 280.0)
    elseif compare_left and compare_right then
        draw_stat_compare_table(
            M.total_stats(compare_left),
            M.total_stats(compare_right),
            label_left,
            label_right,
            "loadout_analyze_cmp_stats_" .. list_id,
            opts.stat_height or 240.0
        )
    end

    ImGui.Spacing()
    if mode == "list" then
        col_text(Theme.section or Theme.header, string.format("Focus and worn effects (%d)", #list_focus))
        draw_focus_summary_table(list_focus, "loadout_summary_focus_" .. list_id, opts.focus_height or 170.0)
    elseif compare_left and compare_right then
        local gained, lost = M.focus_delta(compare_left, compare_right)
        col_text(Theme.section or Theme.header, "Focus tradeoffs")
        draw_focus_delta_tables(
            gained,
            lost,
            string.format("New on %s (not on %s)", label_right, label_left),
            string.format("Only on %s (not on %s)", label_left, label_right),
            list_id .. "_" .. mode)
    end

    if opts.show_actions ~= false then
        ImGui.Spacing()
        if mode == "worn" and themed_button("Open slot compare##loadout_sum_slots_worn", Theme.cyan) then
            local ok_cmp, cmp = pcall(require, 'tabs.compare')
            if ok_cmp and cmp and cmp.open_worn_vs_list then
                cmp.open_worn_vs_list(list_id)
                if worn_key and worn_key ~= "__self__" then
                    Settings.compareKey1 = worn_key
                    SaveSettings()
                end
            end
        end
        if mode == "list_list" and themed_button("Open slot compare##loadout_sum_slots_list", Theme.cyan) then
            local ok_cmp, cmp = pcall(require, 'tabs.compare')
            if ok_cmp and cmp and cmp.open_list_vs_list then
                cmp.open_list_vs_list(list_id)
            end
        end
        if mode ~= "list" then ImGui.SameLine() end
        if themed_button("Focus breakdown##loadout_sum_focus", Theme.purple) then
            M.open_for_list(list_id, "focus")
        end
        ImGui.SameLine()
        if themed_button("Export##loadout_sum_export", Theme.sync) then
            local ok, detail = M.export_list(list_id)
            if opts.set_status then
                opts.set_status(ok and ("Exported list to " .. tostring(detail)) or tostring(detail or "Export failed."))
            end
        end
    end
    ImGui.Separator()
end

function M.draw_compare_deltas(s1, s2, opts)
    opts = type(opts) == "table" and opts or {}
    if not s1 or not s2 then return end
    local left = tostring(opts.left or "Left")
    local right = tostring(opts.right or "Right")
    local totals_a = M.total_stats(s1)
    local totals_b = M.total_stats(s2)
    local delta = M.stat_delta(totals_a, totals_b)

    ImGui.Spacing()
    col_text(Theme.section or Theme.header, string.format("Stat totals: %s vs %s", left, right))
    col_text(Theme.dim, string.format("%s -> %s: %s", left, right, M.format_delta_summary(delta, 12)))

    local stat_rows = stat_compare_rows(totals_a, totals_b)
    if opts.changes_only then
        local filtered = {}
        for _, row in ipairs(stat_rows) do
            if compare_row_changed(row) then filtered[#filtered + 1] = row end
        end
        stat_rows = filtered
    end

    if #stat_rows == 0 then
        col_text(Theme.placeholder or Theme.dim, "No stat data to compare.")
    else
        local flags = table_header_scroll_flags()
        ImGui.BeginChild("loadout_cmp_stat_wrap", 0, opts.stat_height or 200.0, false)
        if ImGui.BeginTable("loadout_cmp_stats", 4, flags) then
            ImGui.TableSetupColumn("Stat", ImGuiTableColumnFlags.WidthFixed, 120.0)
            ImGui.TableSetupColumn(left, ImGuiTableColumnFlags.WidthStretch, 1.0)
            ImGui.TableSetupColumn(right, ImGuiTableColumnFlags.WidthStretch, 1.0)
            ImGui.TableSetupColumn("Change", ImGuiTableColumnFlags.WidthFixed, 72.0)
            setup_frozen_header("loadout_cmp_stats")
            ImGui.TableHeadersRow()
            for _, row in ipairs(stat_rows) do
                ImGui.TableNextRow()
                ImGui.TableSetColumnIndex(0)
                col_text(compare_row_changed(row) and Theme.amber or Theme.dim, compare_row_label(row))
                draw_compare_row_values(row, 1, 2, 3)
            end
            ImGui.EndTable()
        end
        ImGui.EndChild()
    end

    local gained, lost = M.focus_delta(s1, s2)
    ImGui.Spacing()
    col_text(Theme.section or Theme.header, "Focus tradeoffs")
    draw_focus_delta_tables(
        gained,
        lost,
        string.format("New on %s (not on %s)", right, left),
        string.format("Only on %s (not on %s)", left, right),
        "compare_footer")
end

function M.open_analyze_list(list_id, mode)
    list_id = trim(list_id)
    if list_id == "" then list_id = M.selected_list_id() or "" end
    if list_id == "" then return false end
    local Settings = require('config').Settings
    local SaveSettings = require('config').SaveSettings
    Settings.bisSelectedList = list_id
    Settings.mainTab = "inspect"
    Settings.inspectTab = "stats"
    Settings.statsViewMode = "plan"
    Settings.statsSourceScope = "loadout"
    Settings.statsLoadoutList = list_id
    Settings.statsAnalyzeMode = mode or "list"
    SaveSettings()
    M.invalidate(list_id)
    return true
end

function M.open_analyze_vs_worn(list_id)
    return M.open_analyze_list(list_id, "worn")
end

function M.open_analyze_vs_list(list_id, compare_list_id)
    list_id = trim(list_id)
    compare_list_id = trim(compare_list_id or "")
    if compare_list_id ~= "" then
        local Settings = require('config').Settings
        local SaveSettings = require('config').SaveSettings
        Settings.statsAnalyzeCompareList = compare_list_id
        SaveSettings()
    end
    return M.open_analyze_list(list_id, "list_list")
end

function M.draw_list_picker(id, selected_id, width, exclude_id)
    selected_id = trim(selected_id)
    exclude_id = trim(exclude_id or "")
    local lists = M.list_options()
    local label = "No lists"
    for _, rec in ipairs(lists) do
        if rec.id == selected_id then
            label = rec.name or rec.id
            break
        end
    end
    if selected_id == "" then
        for _, rec in ipairs(lists) do
            if rec.id ~= exclude_id then
                selected_id = rec.id
                label = rec.name or rec.id
                break
            end
        end
    end

    ImGui.SetNextItemWidth(width or 220.0)
    if ImGui.BeginCombo(id, label) then
        for _, rec in ipairs(lists) do
            if exclude_id == "" or rec.id ~= exclude_id then
                local picked = selected_id == rec.id
                if ImGui.Selectable(tostring(rec.name or rec.id) .. "##loadout_list_" .. tostring(rec.id), picked) then
                    selected_id = rec.id
                end
            end
        end
        ImGui.EndCombo()
    end
    return selected_id
end

function M.open_for_list(list_id, tab)
    list_id = trim(list_id)
    if list_id == "" then list_id = M.selected_list_id() or "" end
    if list_id == "" then return false end
    local Settings = require('config').Settings
    local SaveSettings = require('config').SaveSettings
    Settings.bisSelectedList = list_id
    tab = tostring(tab or "stats")
    if tab == "focus" then
        Settings.mainTab = "inspect"
        Settings.inspectTab = "focus"
        Settings.focusSourceScope = "loadout"
        Settings.focusLoadoutList = list_id
    else
        Settings.mainTab = "inspect"
        Settings.inspectTab = "stats"
        Settings.statsViewMode = "plan"
        Settings.statsSourceScope = "loadout"
        Settings.statsLoadoutList = list_id
    end
    SaveSettings()
    M.invalidate(list_id)
    return true
end

function M.export_list(list_id)
    list_id = trim(list_id)
    if list_id == "" then return false, "No list selected." end
    local ok_ul, userlists = pcall(require, 'userlists')
    if not ok_ul or not userlists or not userlists.export then
        return false, "Export is not available."
    end
    local path, err = userlists.export(list_id)
    if not path then return false, err or "Export failed." end
    pcall(userlists.open_config_folder)
    return true, path
end

return M
