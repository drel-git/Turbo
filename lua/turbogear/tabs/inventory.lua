-- TurboGear/tabs/inventory.lua
-- Cached character inventory browser: worn grid, bags/bank table, and slot
-- comparison across known characters. Draw code only reads snapshots.

local ImGui = require('ImGui')
local mq = require('mq')
local theme = require('theme')
local Theme, col_text, toggle_button = theme.Theme, theme.col_text, theme.toggle_button
local cfg = require('config')
local Settings, SaveSettings = cfg.Settings, cfg.SaveSettings
local items = require('items')
local views = require('views')
local item_actions = require('item_actions')
local keep_qty = require('keep_qty')
local transfers = require('turbogive_transfers')
local integrations = require('item_integrations')
local ui_table = require('ui_table')
local diag = require('diagnostics')
local Engine = require('engine').Engine
local characters = require('characters')
local Store = require('store')
local okShell, ShellOpen = pcall(require, 'Turbo.shell_open')
if not okShell then ShellOpen = nil end

local M = {}

local EQ_ICON_OFFSET = 500
local ICON_SIZE = 26.0
local GRID_CELL = 46.0
-- After a donor signals [DONE], pause briefly before the next send (like
-- turbo_collect_dc's inter-sender delay). Avoid fire-and-forget macro overlap.
local STOCK_SEND_GAP_S = 1.0
local STOCK_AWAIT_TIMEOUT_S = 45.0
local STOCK_LOCAL_GRACE_S = 2.0 -- after local /mac, Macro.Name may be empty briefly
local STOCK_DRY_TTL_S = 60.0
local STOCK_DRY_MAX_LINES = 14
local STOCK_SHORT_COLOR = { 0.95, 0.62, 0.30, 1.0 }
local STOCK_ITEM_COL_W = 300.0
local STOCK_SPACER_W = 16.0
local STOCK_GROUP_BG = { 0.13, 0.19, 0.24, 0.98 }
local STOCK_GROUP_TEXT = { 0.52, 0.76, 0.82, 1.0 }

local anim_items
local rows_key, rows_cache, rows_meta = nil, {}, {}
local stock_rows_key, stock_rows_cache, stock_board_index = nil, {}, nil
local stock_board_state = {
    pending_key = nil,
    pending_records = nil,
    building = false,
    status = "empty",
    built_at = 0,
    build_ms = 0,
}
local scope_cache = { key = nil, at = 0, keys = nil }
local stock_job = {
    running = false,
    queue = {},
    next_at = 0,
    total = 0,
    done = 0,
    label = "Even Out",
    phase = "idle", -- idle | await | gap
    awaiting = nil,
    await_until = 0,
    await_started = 0,
    await_done = false,
    await_local = false,
    events_on = false,
}
local stock_dry = { label = "", lines = {}, total = 0 }
local stock_selected_rule_key = nil

characters.set_on_changed(function()
    rows_key = nil
    stock_rows_key = nil
    stock_board_index = nil
    stock_board_state.pending_key = nil
    stock_board_state.pending_records = nil
    stock_board_state.status = "stale"
    scope_cache = { key = nil, at = 0, keys = nil }
end, "inventory")

local LOCATION_FILTERS = {
    { key = "all", label = "All" },
    { key = "equipped", label = "Worn" },
    { key = "bags", label = "Bags" },
    { key = "bank", label = "Bank" },
    { key = "aug", label = "Augs" },
}

local SCOPE_OPTIONS = {
    { key = "single", label = "Selected" },
    { key = "online", label = "Live" },
    { key = "group", label = "Group" },
    { key = "e3", label = "E3" },
    { key = "all", label = "All Cache" },
}

local SLOT_LAYOUT = {
    { 2, 3, 1, 4 },
    { 5, 6, 7, 8 },
    { 17, 12, 9, 10 },
    { 15, 16, 0, 21 },
    { 13, 14, 11, 22 },
}

local function ensure_defaults()
    Settings.inventoryViewKey = views.validate_source_key(Settings.inventoryViewKey or "__self__")
    local mode = tostring(Settings.inventoryViewMode or "table")
    if mode == "stock" then mode = "table" end -- migrated to Gear > Stock Up
    if mode ~= "table" and mode ~= "bags" and mode ~= "transfers" then mode = "table" end
    Settings.inventoryViewMode = mode
    local scope = tostring(Settings.inventoryScope or "single")
    if scope ~= "single" and scope ~= "online" and scope ~= "group" and scope ~= "e3" and scope ~= "all" then scope = "single" end
    Settings.inventoryScope = scope
    Settings.inventoryLocationFilter = "all"
    Settings.inventorySearch = Settings.inventorySearch or ""
    Settings.inventoryShowAugs = true
    Settings.inventorySelectedSlotId = tonumber(Settings.inventorySelectedSlotId)
    Settings.inventorySelectedContainer = tostring(Settings.inventorySelectedContainer or "")
    Settings.inventoryBagSubview = tostring(Settings.inventoryBagSubview or "container")
    if Settings.inventoryBagSubview ~= "container" and Settings.inventoryBagSubview ~= "all" then Settings.inventoryBagSubview = "container" end
    if Settings.inventoryShowAllRows == nil then Settings.inventoryShowAllRows = false end
    Settings.inventoryRowLimit = math.max(100, math.min(200, math.floor(tonumber(Settings.inventoryRowLimit) or 200)))
    Settings.inventoryTableCompact = "auto"
end

local function input_text_hint(id, hint, value)
    if ImGui.InputTextWithHint then
        local ok, rv = pcall(ImGui.InputTextWithHint, id, hint, value or "")
        if ok then return rv or "" end
    end
    return ImGui.InputText(id, value or "") or ""
end

local function icon_text(item)
    if not item then return "-" end
    return tostring(item.icon or item.id or "")
end

local function format_age(seconds)
    seconds = tonumber(seconds)
    if not seconds then return "cache age unknown" end
    seconds = math.max(0, seconds)
    if seconds >= 86400 then return string.format("%dd old", math.floor(seconds / 86400)) end
    if seconds >= 3600 then return string.format("%dh old", math.floor(seconds / 3600)) end
    if seconds >= 60 then return string.format("%dm old", math.floor(seconds / 60)) end
    return string.format("%ds old", math.floor(seconds))
end

local function bank_status_text(snap)
    if type(snap) ~= "table" then return nil, Theme.dim end
    if snap.bankLive == true then
        return string.format("Bank: live now (%d cached bank item%s)", #(snap.bank or {}), #(snap.bank or {}) == 1 and "" or "s"), Theme.online
    end
    if snap.bankValid == true then
        local captured = tonumber(snap.bankCapturedAt) or tonumber(snap.inventoryUpdated) or tonumber(snap.updated)
        local age = captured and math.max(0, os.time() - captured) or nil
        return string.format("Bank: cached %s (%d bank item%s)", format_age(age), #(snap.bank or {}), #(snap.bank or {}) == 1 and "" or "s"), Theme.dim
    end
    return "Bank: not synced yet - open a bank.", Theme.amber
end

local function ensure_textures()
    if anim_items ~= nil then return end
    pcall(function() anim_items = mq.FindTextureAnimation('A_DragItem') end)
end

local function draw_icon(icon, size)
    ensure_textures()
    icon = tonumber(icon) or 0
    size = tonumber(size) or ICON_SIZE
    if anim_items and icon > 0 and ImGui.DrawTextureAnimation then
        local ok = pcall(function()
            anim_items:SetTextureCell(icon - EQ_ICON_OFFSET)
            ImGui.DrawTextureAnimation(anim_items, size, size)
        end)
        if ok then return end
    end
    col_text(Theme.dim, icon > 0 and tostring(icon) or "-")
end

local function item_rect()
    if not (ImGui.GetItemRectMin and ImGui.GetItemRectMax) then return nil end
    local a, b = ImGui.GetItemRectMin()
    local c, d = ImGui.GetItemRectMax()
    local x1, y1 = type(a) == "table" and (a.x or a[1]) or a, type(a) == "table" and (a.y or a[2]) or b
    local x2, y2 = type(c) == "table" and (c.x or c[1]) or c, type(c) == "table" and (c.y or c[2]) or d
    x1, y1, x2, y2 = tonumber(x1), tonumber(y1), tonumber(x2), tonumber(y2)
    if not (x1 and y1 and x2 and y2) then return nil end
    return { x1 = x1, y1 = y1, x2 = x2, y2 = y2 }
end

local function source_owner(key, snap)
    if key == "__self__" then
        return tostring(mq.TLO.Me.CleanName() or (snap and snap.name) or "Self")
    end
    return tostring((snap and snap.name) or views.source_owner_name(key) or "?")
end

local function scope_label_for(scope)
    local cur = tostring(scope or Settings.inventoryScope or "single")
    for _, opt in ipairs(SCOPE_OPTIONS) do
        if opt.key == cur then return opt.label end
    end
    return "Selected"
end

local function scope_label()
    return scope_label_for(Settings.inventoryScope)
end

local function table_compact_enabled(show_owner)
    return show_owner and true or false
end

local function scope_keys()
    local scope = tostring(Settings.inventoryScope or "single")
    if scope == "single" then
        return { views.validate_source_key(Settings.inventoryViewKey or "__self__") }
    end
    local now = os.clock()
    if scope_cache.key == scope and scope_cache.keys and (now - (scope_cache.at or 0)) < 2.0 then
        local out = {}
        for i, key in ipairs(scope_cache.keys) do out[i] = key end
        return out
    end
    local keys = views.scoped_source_keys(scope)
    scope_cache = { key = scope, at = now, keys = keys }
    return keys
end

local function source_records_for_keys(keys)
    local records = {}
    for _, key in ipairs(keys or {}) do
        local snap = views.source_snapshot(key)
        if snap then
            records[#records + 1] = { key = key, snap = snap }
        end
    end
    return records
end

local function source_records()
    return source_records_for_keys(scope_keys())
end

local function source_records_for_scope(scope)
    scope = tostring(scope or "all")
    if scope == "single" then
        return source_records_for_keys({ views.validate_source_key(Settings.inventoryViewKey or "__self__") })
    end
    return source_records_for_keys(views.scoped_source_keys(scope))
end

local function source_signature(records)
    local parts = { tostring(Settings.inventoryScope or "single") }
    for _, rec in ipairs(records or {}) do
        local snap = rec.snap
        parts[#parts + 1] = table.concat({
            tostring(rec.key or ""),
            tostring(snap and (snap.inventoryUpdated or snap.updated) or ""),
            tostring(snap and snap.depth or ""),
            tostring(snap and snap.status or ""),
        }, ":")
    end
    return table.concat(parts, "|")
end

local function records_signature(records)
    local parts = {}
    for _, rec in ipairs(records or {}) do
        local snap = rec.snap
        parts[#parts + 1] = table.concat({
            tostring(rec.key or ""),
            tostring(snap and (snap.inventoryUpdated or snap.updated) or ""),
            tostring(snap and snap.depth or ""),
            tostring(snap and snap.status or ""),
        }, ":")
    end
    return table.concat(parts, "|")
end

local function stat(item, key)
    local stats = item and item.stats
    return type(stats) == "table" and (tonumber(stats[key]) or 0) or 0
end

local function has_full_stats(item)
    return type(item) == "table" and tostring(item.depth or "") == "full"
end

local function stat_text(item, key)
    if not has_full_stats(item) then return "-" end
    return tostring(stat(item, key))
end

local function stat_color(item)
    return has_full_stats(item) and (Theme.value or Theme.green) or Theme.dim
end

local function item_location_group(item)
    local loc = tostring(item and item.location or "")
    if loc == "Equipped" then return "equipped" end
    if loc == "Bags" then return "bags" end
    if loc == "Bank" then return "bank" end
    return "unknown"
end

local function row_location(row)
    if not row then return "" end
    if row.locationGroup == "equipped" then
        return tostring(row.slotname or row.where or "Equipped")
    end
    return tostring(row.location or row.where or "")
end

local function add_row(rows, snap, source_key, item, opts)
    if type(item) ~= "table" or item.empty then return end
    opts = opts or {}
    local name = tostring(item.name or "")
    if name == "" or name == "Empty" then return end
    local owner = source_owner(source_key, snap)
    local group = opts.locationGroup or item_location_group(item)
    rows[#rows + 1] = {
        owner = owner,
        ownerClass = snap and snap.class or "",
        sourceKey = table.concat({
            tostring(source_key or ""),
            tostring(opts.kind or "item"),
            tostring(group),
            tostring(item.slotid or ""),
            tostring(item.slotname or ""),
            tostring(item.id or 0),
            tostring(opts.augIndex or "")
        }, ":"),
        source = source_key,
        kind = opts.kind or "item",
        name = name,
        id = tonumber(item.id) or 0,
        icon = tonumber(item.icon) or 0,
        qty = tonumber(item.qty) or 1,
        locationGroup = group,
        where = opts.where or item.where or group,
        location = opts.location or row_location({
            locationGroup = group,
            slotname = item.slotname,
            where = item.where,
            location = item.location,
        }),
        slotid = tonumber(item.slotid) or item.slotid,
        slotname = item.slotname,
        installedIn = opts.installedIn or "",
        augIndex = opts.augIndex,
        stats = type(item.stats) == "table" and item.stats or {},
        requiredLevel = tonumber(item.requiredLevel) or 0,
        recommendedLevel = tonumber(item.recommendedLevel) or 0,
        tribute = tonumber(item.tribute) or 0,
        depth = tostring(item.depth or snap and snap.depth or "lite"),
    }
end

local function add_installed_augs(rows, snap, source_key, item)
    if not Settings.inventoryShowAugs then return end
    if type(item) ~= "table" or type(item.augs) ~= "table" then return end
    local parent_loc = item.slotname or item.where or item.location or "Item"
    for _, aug in ipairs(item.augs) do
        if aug and not aug.empty and views.aug_visible(aug) then
            add_row(rows, snap, source_key, aug, {
                kind = "aug",
                locationGroup = "installed_aug",
                where = "installed_aug",
                location = string.format("%s: %s Aug %s", parent_loc, item.name or "item", tostring(aug.index or "?")),
                installedIn = item.name or "",
                augIndex = aug.index,
            })
        end
    end
end

local function flatten_snapshot(snap, source_key)
    local rows = {}
    for _, item in ipairs((snap and snap.equipped) or {}) do
        add_row(rows, snap, source_key, item, {
            locationGroup = "equipped",
            where = "equipped",
            location = item.slotname or item.where or "Equipped",
        })
        add_installed_augs(rows, snap, source_key, item)
    end
    for _, item in ipairs((snap and snap.bags) or {}) do
        add_row(rows, snap, source_key, item, {
            locationGroup = "bags",
            where = "bags",
            location = string.format("%s: %s", item.location or "Bags", item.where or ""),
        })
        add_installed_augs(rows, snap, source_key, item)
    end
    for _, item in ipairs((snap and snap.bank) or {}) do
        add_row(rows, snap, source_key, item, {
            locationGroup = "bank",
            where = "bank",
            location = string.format("%s: %s", item.location or "Bank", item.where or ""),
        })
        add_installed_augs(rows, snap, source_key, item)
    end
    return rows
end

local function matches_filter(row)
    local loc = tostring(Settings.inventoryLocationFilter or "all")
    if loc == "equipped" and row.locationGroup ~= "equipped" then return false end
    if loc == "bags" and row.locationGroup ~= "bags" then return false end
    if loc == "bank" and row.locationGroup ~= "bank" then return false end
    if loc == "aug" and row.kind ~= "aug" then return false end

    local needle = tostring(Settings.inventorySearch or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if needle == "" then return true end
    local hay = table.concat({
        row.name or "",
        row.location or "",
        row.installedIn or "",
        tostring(row.id or ""),
    }, " "):lower()
    return hay:find(needle, 1, true) ~= nil
end

local function search_text()
    return tostring(Settings.inventorySearch or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
end

local function visible_rows(records)
    local key = table.concat({
        source_signature(records),
        tostring(Settings.inventoryLocationFilter or ""),
        tostring(Settings.inventorySearch or ""),
        tostring(Settings.inventoryShowAugs),
    }, "\1")
    if rows_key == key then return rows_cache, rows_meta end

    return diag.time("ui.inventory.rows_rebuild", function()
        local flat = {}
        for _, rec in ipairs(records or {}) do
            local rows = flatten_snapshot(rec.snap, rec.key)
            for _, row in ipairs(rows) do flat[#flat + 1] = row end
        end
        ui_table.stable_sort(flat, ui_table.stable_row_less)
        local filtered = {}
        for _, row in ipairs(flat) do
            if matches_filter(row) then filtered[#filtered + 1] = row end
        end
        rows_cache = filtered
        rows_meta = { total = #flat, shown = #filtered }
        rows_key = key
        return rows_cache, rows_meta
    end)
end

local function stock_rows_for_records(records)
    local key = table.concat({
        records_signature(records),
        tostring(Store and Store.content_version or 0),
        tostring(Settings.inventoryShowAugs),
    }, "\1")
    if stock_rows_key == key and stock_board_index then
        return stock_rows_cache, stock_board_index
    end

    if stock_board_state.pending_key ~= key then
        stock_board_state.pending_key = key
        stock_board_state.pending_records = records or {}
        stock_board_state.status = stock_board_index and "stale" or "building"
    end
    return stock_rows_cache, stock_board_index
end

local function stock_build_pending_board()
    local key = stock_board_state.pending_key
    if not key or key == stock_rows_key then return false end
    local records = stock_board_state.pending_records or {}
    stock_board_state.building = true
    stock_board_state.status = stock_board_index and "stale" or "building"
    local t0 = os.clock()
    local flat = {}
    for _, rec in ipairs(records) do
        local rows = flatten_snapshot(rec.snap, rec.key)
        for _, row in ipairs(rows) do flat[#flat + 1] = row end
    end
    ui_table.stable_sort(flat, ui_table.stable_row_less)
    local index = keep_qty.build_board_index(flat)
    stock_rows_key = key
    stock_rows_cache = flat
    stock_board_index = index
    stock_board_state.pending_key = nil
    stock_board_state.pending_records = nil
    stock_board_state.building = false
    stock_board_state.status = "ready"
    stock_board_state.built_at = os.clock()
    stock_board_state.build_ms = (stock_board_state.built_at - t0) * 1000
    return true
end

local function selected_slot_label()
    local sid = tonumber(Settings.inventorySelectedSlotId)
    if not sid then return nil end
    return items.slot_display_name(sid)
end

local function draw_slot_cell(slot_id, item)
    local slot_name = items.slot_display_name(slot_id)
    local selected = tonumber(Settings.inventorySelectedSlotId) == tonumber(slot_id)
    local clicked = false
    local hovered = false
    local rect = nil
    ImGui.PushID("inv_slot_" .. tostring(slot_id))
    if ImGui.InvisibleButton then
        clicked = ImGui.InvisibleButton("##slot", GRID_CELL, GRID_CELL)
    else
        clicked = ImGui.Button(slot_name .. "##slot", GRID_CELL, GRID_CELL)
    end
    hovered = ImGui.IsItemHovered and ImGui.IsItemHovered() or false
    rect = item_rect()
    if rect and ImGui.SetCursorScreenPos then ImGui.SetCursorScreenPos(rect.x1 + 3, rect.y1 + 3) end
    if item and item.icon and tonumber(item.icon) and tonumber(item.icon) > 0 then
        draw_icon(item.icon, GRID_CELL - 8)
    else
        local short = slot_name:gsub(" ", "\n")
        col_text(Theme.placeholder or Theme.dim, short)
    end
    if selected and rect and ImGui.GetWindowDrawList and theme.color_u32 then
        pcall(function()
            ImGui.GetWindowDrawList():AddRect(ImVec2(rect.x1, rect.y1), ImVec2(rect.x2, rect.y2), theme.color_u32(Theme.gold), 0, 0, 2.0)
        end)
    end
    if clicked then
        Settings.inventorySelectedSlotId = slot_id
        SaveSettings()
    end
    if hovered then
        ImGui.BeginTooltip()
        col_text(Theme.slot, slot_name)
        if item then
            item_actions.draw_name(item.name or "?", Theme.item, "inv_grid_tip_" .. tostring(slot_id), item.id)
            col_text(Theme.dim, string.format("AC %s  HP %s  Mana %s", stat_text(item, "ac"), stat_text(item, "hp"), stat_text(item, "mana")))
        else
            col_text(Theme.placeholder or Theme.dim, "(empty)")
        end
        ImGui.EndTooltip()
    end
    ImGui.PopID()
end

local function draw_equipped_grid(snap)
    local map = views.index_equipped(snap)
    col_text(Theme.section or Theme.header, "Worn")
    if ImGui.BeginTable("InventoryEquippedGrid", 4, ImGuiTableFlags.Borders + ImGuiTableFlags.RowBg + ImGuiTableFlags.SizingFixedFit) then
        for _, row in ipairs(SLOT_LAYOUT) do
            ImGui.TableNextRow(0, GRID_CELL + 5)
            for _, slot_id in ipairs(row) do
                ImGui.TableNextColumn()
                draw_slot_cell(slot_id, map[slot_id])
            end
        end
        ImGui.EndTable()
    end
    local selected = selected_slot_label()
    if selected then
        col_text(Theme.dim, "Selected slot: " .. selected)
        ImGui.SameLine()
        if theme.themed_button("Clear##inv_clear_slot", Theme.steel, 54, 0) then
            Settings.inventorySelectedSlotId = nil
            SaveSettings()
        end
    else
        col_text(Theme.dim, "Click slot for compare.")
    end
end

local function draw_filters()
    local use_pill = Settings.showCharactersPill == true
    if not use_pill then
        ImGui.Text("Viewing:")
        ImGui.SameLine()
        local old_key = Settings.inventoryViewKey
        Settings.inventoryViewKey = views.draw_source_picker("##inventory_source", Settings.inventoryViewKey or "__self__", 220.0)
        if old_key ~= Settings.inventoryViewKey then
            rows_key = nil
            SaveSettings()
        end
        ImGui.SameLine()
        ImGui.Text("Source:")
        ImGui.SameLine()
        ImGui.SetNextItemWidth(106.0)
        if ImGui.BeginCombo("##inventory_scope", scope_label()) then
            for _, opt in ipairs(SCOPE_OPTIONS) do
                if ImGui.Selectable(opt.label .. "##inv_scope_" .. opt.key, Settings.inventoryScope == opt.key) then
                    Settings.inventoryScope = opt.key
                    Settings.inventorySelectedContainer = ""
                    rows_key = nil
                    SaveSettings()
                end
            end
            ImGui.EndCombo()
        end
        ImGui.SameLine()
    elseif Settings.inventoryScope ~= "single" then
        Settings.inventoryScope = "single"
    end
    if toggle_button("Items##inv_mode_table", Settings.inventoryViewMode == "table", 62, 0) then
        Settings.inventoryViewMode = "table"
        SaveSettings()
    end
    ImGui.SameLine()
    if toggle_button(Settings.inventoryViewMode == "bags" and "Bags##inv_mode_bags" or "Bags##inv_mode_bags", Settings.inventoryViewMode == "bags", 58, 0) then
        Settings.inventoryViewMode = "bags"
        SaveSettings()
    end
    if Settings.inventoryViewMode == "bags" then
        ImGui.SameLine()
        local all_contents = Settings.inventoryBagSubview == "all"
        if toggle_button(all_contents and "All Contents##inv_bag_all" or "Container##inv_bag_all", all_contents, 112, 0) then
            Settings.inventoryBagSubview = all_contents and "container" or "all"
            SaveSettings()
        end
    end
    ImGui.SameLine()
    if toggle_button("Transfers##inv_mode_transfers", Settings.inventoryViewMode == "transfers", 92, 0) then
        Settings.inventoryViewMode = "transfers"
        SaveSettings()
    end

    local search_hint = Settings.inventoryScope == "single" and "Search selected character inventory..."
        or ("Search " .. scope_label() .. " cached inventory...")
    ImGui.SetNextItemWidth(-62)
    local next_search = input_text_hint("##inventory_search", search_hint, Settings.inventorySearch or "")
    if next_search ~= (Settings.inventorySearch or "") then
        Settings.inventorySearch = next_search
        rows_key = nil
        SaveSettings()
    end
    ImGui.SameLine()
    if theme.themed_button("Clear##inv_search_clear", Theme.steel, 56, 0) then
        if tostring(Settings.inventorySearch or "") ~= "" then
            Settings.inventorySearch = ""
            rows_key = nil
            SaveSettings()
        end
    end
end

local function draw_row_item(row, index)
    local suffix = "inventory_item_" .. tostring(index) .. "_" .. tostring(row.sourceKey or "")
    theme.colored_text(tostring(row.name or "?"), row.kind == "aug" and (Theme.aug or Theme.green) or Theme.item)
    if item_actions.context_needed and not item_actions.context_needed(suffix) then return end
    item_actions.draw_context(row.name or "?", row.id, suffix,
        item_actions.context_opts({
            sourceLocation = row.location or "",
        }, row))
end

local function draw_row_item_fit(row, index, max_width)
    local suffix = "inventory_item_" .. tostring(index) .. "_" .. tostring(row.sourceKey or "")
    local name = tostring(row.name or "?")
    local shown, clipped = views.fit_text(name, math.max(24.0, tonumber(max_width) or 0))
    theme.colored_text(shown, row.kind == "aug" and (Theme.aug or Theme.green) or Theme.item)
    if clipped and ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
        ImGui.SetTooltip(name)
    end
    if item_actions.context_needed and not item_actions.context_needed(suffix) then return end
    item_actions.draw_context(name, row.id, suffix,
        item_actions.context_opts({
            sourceLocation = row.location or "",
        }, row))
end

local function set_cursor_x(x)
    if ImGui.SetCursorPosX then pcall(ImGui.SetCursorPosX, tonumber(x) or 0) end
end

local function same_line_at(x)
    if ImGui.SameLine then ImGui.SameLine(0, 0) end
    set_cursor_x(x)
end

local function draw_text_cell(x, color, text, width, first)
    if first then set_cursor_x(x) else same_line_at(x) end
    views.col_text_fit(color, text, width)
end

local function draw_item_cell(row, index, x, width, first)
    if first then set_cursor_x(x) else same_line_at(x) end
    draw_row_item_fit(row, index, width)
end

local function item_list_layout(show_owner, show_icon)
    local avail_w = select(1, views.content_avail()) or 1120.0
    local base_x = 0.0
    if ImGui.GetCursorPosX then
        local ok, x = pcall(ImGui.GetCursorPosX)
        if ok and tonumber(x) then base_x = tonumber(x) end
    end
    local right_x = base_x + math.max(720.0, tonumber(avail_w) or 1120.0)
    local id_w, mana_w, hp_w, ac_w, qty_w = 70.0, 58.0, 58.0, 46.0, 38.0
    local id_x = right_x - id_w
    local mana_x = id_x - mana_w
    local hp_x = mana_x - hp_w
    local ac_x = hp_x - ac_w
    local qty_x = ac_x - qty_w
    local owner_w = show_owner and 112.0 or 0.0
    local icon_w = show_icon and 36.0 or 0.0
    local item_x = base_x + owner_w + icon_w
    local loc_w = math.min(300.0, math.max(145.0, (right_x - item_x) * 0.28))
    local loc_x = qty_x - loc_w
    local item_w = math.max(120.0, loc_x - item_x - 8.0)
    return {
        base_x = base_x,
        owner_x = base_x,
        owner_w = owner_w,
        icon_x = base_x + owner_w,
        icon_w = icon_w,
        item_x = item_x,
        item_w = item_w,
        loc_x = loc_x,
        loc_w = math.max(80.0, qty_x - loc_x - 4.0),
        qty_x = qty_x,
        qty_w = qty_w,
        ac_x = ac_x,
        ac_w = ac_w,
        hp_x = hp_x,
        hp_w = hp_w,
        mana_x = mana_x,
        mana_w = mana_w,
        id_x = id_x,
        id_w = id_w,
    }
end

local function draw_item_list_header(layout, show_owner, show_icon)
    local first = true
    if show_owner then
        draw_text_cell(layout.owner_x, Theme.header, "Owner", layout.owner_w, first); first = false
    end
    if show_icon then
        draw_text_cell(layout.icon_x, Theme.header, "Icon", layout.icon_w, first); first = false
    end
    draw_text_cell(layout.item_x, Theme.header, "Item", layout.item_w, first); first = false
    draw_text_cell(layout.loc_x, Theme.header, "Location", layout.loc_w, false)
    draw_text_cell(layout.qty_x, Theme.header, "Qty", layout.qty_w, false)
    draw_text_cell(layout.ac_x, Theme.header, "AC", layout.ac_w, false)
    draw_text_cell(layout.hp_x, Theme.header, "HP", layout.hp_w, false)
    draw_text_cell(layout.mana_x, Theme.header, "Mana", layout.mana_w, false)
    draw_text_cell(layout.id_x, Theme.header, "ID", layout.id_w, false)
    if ImGui.Separator then ImGui.Separator() end
end

local function draw_item_list_row(row, index, layout, show_owner, show_icon)
    local first = true
    if show_owner then
        draw_text_cell(layout.owner_x, views.class_color(row.ownerClass), views.owner_label(row), layout.owner_w, first); first = false
    end
    if show_icon then
        if first then set_cursor_x(layout.icon_x) else same_line_at(layout.icon_x) end
        draw_icon(row.icon, 18.0)
        if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then ImGui.SetTooltip(icon_text(row)) end
        first = false
    end
    draw_item_cell(row, index, layout.item_x, layout.item_w, first)
    draw_text_cell(layout.loc_x, theme.location_color(row.locationGroup, row.location), row.location or "-", layout.loc_w, false)
    draw_text_cell(layout.qty_x, Theme.dim, tostring(row.qty or 1), layout.qty_w, false)
    draw_text_cell(layout.ac_x, stat_color(row), stat_text(row, "ac"), layout.ac_w, false)
    draw_text_cell(layout.hp_x, stat_color(row), stat_text(row, "hp"), layout.hp_w, false)
    draw_text_cell(layout.mana_x, stat_color(row), stat_text(row, "mana"), layout.mana_w, false)
    draw_text_cell(layout.id_x, Theme.dim, tonumber(row.id) and row.id > 0 and tostring(math.floor(row.id)) or "-", layout.id_w, false)
end

local function draw_item_table(rows, show_owner)
    return diag.time("ui.inventory.table", function()
    local total = #(rows or {})
    local limit = Settings.inventoryShowAllRows and total or math.min(total, tonumber(Settings.inventoryRowLimit) or 200)
    if total > limit then
        col_text(Theme.dim, string.format("Showing first %d of %d rows.", limit, total))
        ImGui.SameLine()
        if theme.themed_button("Show all##inv_show_all_rows", Theme.steel, 76, 0) then
            Settings.inventoryShowAllRows = true
            SaveSettings()
        end
    elseif Settings.inventoryShowAllRows and total > (tonumber(Settings.inventoryRowLimit) or 200) then
        col_text(Theme.dim, string.format("Showing all %d rows.", total))
        ImGui.SameLine()
        if theme.themed_button("Limit##inv_limit_rows", Theme.steel, 62, 0) then
            Settings.inventoryShowAllRows = false
            SaveSettings()
        end
    end

    local compact = table_compact_enabled(show_owner)
    local show_icon = not compact
    local layout = item_list_layout(show_owner, show_icon)
    draw_item_list_header(layout, show_owner, show_icon)
    for i = 1, limit do
        local row = rows[i]
        if not row then break end
        draw_item_list_row(row, i, layout, show_owner, show_icon)
    end
    end)
end

local function stock_search_needle()
    local g = tostring(Settings.globalSearch or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if g ~= "" then return g end
    return search_text()
end

local function stock_rule_matches_search(rule)
    local needle = stock_search_needle()
    if needle == "" then return true end
    local hay = table.concat({
        rule.name or "",
        keep_qty.display_name(rule.name or ""),
        tostring(rule.id or ""),
        tostring(rule.group or ""),
        tostring(rule.resource or ""),
        tostring(rule.scope or ""),
        keep_qty.hint_label(rule),
    }, " "):lower()
    return hay:find(needle, 1, true) ~= nil
end

local function stock_roster_and_records()
    -- Respect Characters pill scope (Live Peers vs All Known). Do not force
    -- include_offline_cache — that leaked offline columns into Live Peers.
    local keys = characters.active_keys("stock") or {}
    local records = source_records_for_keys(keys)
    local roster = {}
    for _, rec in ipairs(records or {}) do
        roster[#roster + 1] = {
            name = source_owner(rec.key, rec.snap),
            class = tostring(rec.snap and rec.snap.class or ""),
            key = rec.key,
            updated = tonumber(rec.snap and (rec.snap.inventoryUpdated or rec.snap.updated)) or 0,
        }
    end
    table.sort(roster, function(a, b)
        return tostring(a.name or ""):lower() < tostring(b.name or ""):lower()
    end)
    return roster, records
end

local function stock_short_header(name)
    name = tostring(name or "?")
    if #name <= 7 then return name end
    return name:sub(1, 7)
end

local function stock_draw_header_cell(text, color)
    local w = ImGui.GetColumnWidth and ImGui.GetColumnWidth() or nil
    if type(w) == "table" then w = tonumber(w.x or w[1]) end
    views.col_text_centered(color or Theme.header or Theme.item, tostring(text or ""), tonumber(w) or 48.0)
end

local function stock_draw_center_cell(color, text)
    local w = ImGui.GetColumnWidth and ImGui.GetColumnWidth() or nil
    if type(w) == "table" then w = tonumber(w.x or w[1]) end
    views.col_text_centered(color or Theme.dim, tostring(text or ""), tonumber(w) or 48.0)
end

local function stock_cell_tooltip(cell, item_name)
    ImGui.BeginTooltip()
    ImGui.Text(tostring(item_name or ""))
    ImGui.Text(string.format("%s (%s)", tostring(cell.owner or "?"),
        keep_qty.class_abbrev(cell.class) ~= "" and keep_qty.class_abbrev(cell.class) or "?"))
    if cell.eligible then
        ImGui.TextColored(0.70, 0.76, 0.86, 1.0, string.format("Have %d / Target %d", cell.have or 0, cell.want or 0))
    else
        ImGui.TextDisabled(string.format("Have %d (not needed for this class)", cell.have or 0))
    end
    for _, loc in ipairs(cell.locations or {}) do
        ImGui.TextDisabled(tostring(loc))
    end
    ImGui.EndTooltip()
end

local function stock_add_cursor_item()
    local ok, name, id = pcall(function()
        local cur = mq.TLO.Cursor
        if not cur or not cur() then return nil, 0 end
        return tostring(cur.Name() or ""), tonumber(cur.ID()) or 0
    end)
    if not ok or not name or name == "" then
        item_actions.status_msg = "Put an item on your cursor, then click Add."
        return
    end
    local saved, err = keep_qty.add_or_update(name, id, 5, "group")
    item_actions.status_msg = saved and tostring(err or ("Added " .. name .. ".")) or tostring(err or "Could not add item.")
    stock_rows_key = nil
    stock_board_state.status = stock_board_index and "stale" or "building"
end

local function stock_rule_ui_key(rule)
    if type(rule) ~= "table" then return "" end
    local name = tostring(rule.name or ""):match("^%s*(.-)%s*$") or ""
    if name ~= "" then return "name:" .. name:lower() end
    local id = tonumber(rule.id) or 0
    if id > 0 then return "id:" .. tostring(math.floor(id)) end
    return ""
end

local function stock_remove_selected_rule()
    if not stock_selected_rule_key or stock_selected_rule_key == "" then
        item_actions.status_msg = "Select a stock row first."
        return
    end
    local rules = keep_qty.rules()
    for i, rule in ipairs(rules or {}) do
        if stock_rule_ui_key(rule) == stock_selected_rule_key then
            local ok, err = keep_qty.remove(i)
            item_actions.status_msg = ok and tostring(err or "Removed stock rule.") or tostring(err or "Could not remove.")
            stock_selected_rule_key = nil
            stock_rows_key = nil
            stock_board_index = nil
            stock_board_state.status = "building"
            return
        end
    end
    stock_selected_rule_key = nil
    item_actions.status_msg = "Selected stock row no longer exists."
end

local function stock_selected_rule_label()
    if not stock_selected_rule_key or stock_selected_rule_key == "" then return nil end
    for _, rule in ipairs(keep_qty.rules() or {}) do
        if stock_rule_ui_key(rule) == stock_selected_rule_key then
            local name = tostring(rule.name or "")
            if name ~= "" then return keep_qty.display_name(name) end
            local id = tonumber(rule.id) or 0
            if id > 0 then return "item " .. tostring(math.floor(id)) end
        end
    end
    return nil
end

local function stock_selected_rule_summary(board_index, roster)
    if not stock_selected_rule_key or stock_selected_rule_key == "" then return nil end
    for _, rule in ipairs(keep_qty.rules() or {}) do
        if stock_rule_ui_key(rule) == stock_selected_rule_key then
            local label = tostring(rule.name or "")
            if label ~= "" then
                label = keep_qty.display_name(label)
            else
                label = "item " .. tostring(rule.id or "?")
            end
            local board = board_index and keep_qty.evaluate_board_from_index(rule, board_index, roster) or nil
            local target = stock_board_want(board, rule.qty)
            local short = tonumber(board and board.need) or 0
            return string.format("Selected: %s | Target %d | Short %d", label, target, short)
        end
    end
    return nil
end

local function stock_ensure_defaults()
    if Settings.stockDefaultsSeeded == true then
        keep_qty.load()
        if Settings.stockShortOnly == nil then Settings.stockShortOnly = true end
        return
    end
    keep_qty.ensure_adventure_preset(5, "group")
    if Settings.stockShortOnly == nil then Settings.stockShortOnly = true end
    Settings.stockDefaultsSeeded = true
    if SaveSettings then SaveSettings() end
    stock_rows_key = nil
    stock_board_state.status = stock_board_index and "stale" or "building"
end

local function stock_norm(s)
    return tostring(s or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
end

local function stock_id_for_rule(rule)
    local id = math.floor(tonumber(rule and rule.id) or 0)
    if id > 0 then return id end
    local want = stock_norm(rule and rule.name)
    if want == "" then return 0 end
    for _, row in ipairs(stock_rows_cache or {}) do
        if stock_norm(row.name) == want then
            local rid = math.floor(tonumber(row.id) or 0)
            if rid > 0 then return rid end
        end
    end
    return 0
end

local function stock_me_name()
    local ok, name = pcall(function() return mq.TLO.Me.Name() end)
    return (ok and tostring(name or "") or ""):match("^%s*(.-)%s*$") or ""
end

local function stock_append_plan(plan, rule, steps)
    local id = stock_id_for_rule(rule)
    for _, step in ipairs(steps or {}) do
        plan[#plan + 1] = {
            from = step.from,
            to = step.to,
            qty = step.qty,
            item = rule.name ~= "" and rule.name or step.item,
            id = id > 0 and id or (tonumber(step.id) or 0),
        }
    end
end

local function stock_build_even_plan(roster, board_index)
    local plan = {}
    for _, rule in ipairs(keep_qty.rules() or {}) do
        if stock_rule_matches_search(rule) then
            local board = keep_qty.evaluate_board_from_index(rule, board_index, roster)
            stock_append_plan(plan, rule, keep_qty.plan_even_out(rule, board and board.cells))
        end
    end
    return plan
end

local function stock_build_collect_plan(roster, board_index, collector)
    collector = tostring(collector or stock_me_name())
    local plan = {}
    if collector == "" then return plan end
    for _, rule in ipairs(keep_qty.rules() or {}) do
        if stock_rule_matches_search(rule) then
            local board = keep_qty.evaluate_board_from_index(rule, board_index, roster)
            stock_append_plan(plan, rule, keep_qty.plan_collect(rule, board and board.cells, collector))
        end
    end
    return plan
end

local function stock_clean_name(name)
    return tostring(name or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
end

local function stock_summarize_plan(plan, label)
    label = tostring(label or "Plan")
    local n = #(plan or {})
    if n == 0 then
        if label == "Collect" then
            return "Collect: nothing to pull (others hold none of these items)."
        end
        return "Even Out: nothing to move (everyone at Target, or no surplus)."
    end
    local units = 0
    for _, step in ipairs(plan) do units = units + (tonumber(step.qty) or 0) end
    local sample = plan[1]
    local extra = n > 1 and string.format(" (+%d more)", n - 1) or ""
    return string.format("%s: %d send%s / %d item%s. e.g. %s -> %s %dx %s%s",
        label,
        n, n == 1 and "" or "s",
        units, units == 1 and "" or "s",
        tostring(sample.from), tostring(sample.to), tonumber(sample.qty) or 0,
        tostring(sample.item or "?"),
        extra)
end

local function stock_set_dry_plan(plan, label)
    label = tostring(label or "Plan")
    stock_dry.label = label
    stock_dry.total = #(plan or {})
    stock_dry.lines = {}
    for i, step in ipairs(plan or {}) do
        if i > STOCK_DRY_MAX_LINES then break end
        stock_dry.lines[#stock_dry.lines + 1] = string.format(
            "%s -> %s  %dx %s",
            tostring(step.from or "?"),
            tostring(step.to or "?"),
            tonumber(step.qty) or 0,
            tostring(step.item or "?"))
    end
    local summary = stock_summarize_plan(plan, label)
    if item_actions.set_status then
        item_actions.set_status(summary, STOCK_DRY_TTL_S)
    else
        item_actions.status_msg = summary
    end
end

local function stock_clear_dry_plan()
    stock_dry.label = ""
    stock_dry.lines = {}
    stock_dry.total = 0
end

local function stock_on_done_signal(line, name)
    name = stock_clean_name(name)
    if name == "" then
        -- Fallback: parse "Name->Dest" / "Name->LOCAL" when #1# missed (color codes).
        local raw = tostring(line or ""):gsub("\a.", "")
        local from = raw:match("%[DONE%]%s*(%w+)%s*%-%>")
        name = stock_clean_name(from)
    end
    if name == "" or not stock_job.running then return end
    if stock_job.phase == "await" and stock_clean_name(stock_job.awaiting) == name then
        stock_job.await_done = true
    end
end

--- True when no TurboGive macro is active on this client (local donor completion).
local function stock_local_turbogive_idle()
    local ok, running = pcall(function()
        local m = mq.TLO.Macro
        if not m then return false end
        local name = m.Name and m.Name() or nil
        if name == nil then return false end
        name = tostring(name)
        if name == "" or name == "NULL" then return false end
        return name:lower():find("turbogive", 1, true) ~= nil
    end)
    if not ok then return false end
    return not running
end

local function stock_ensure_done_events()
    if stock_job.events_on then return end
    pcall(function()
        mq.event("tgStockDoneBC", "#*#[DONE]#*##1#->#2#", function(line, name)
            stock_on_done_signal(line, name)
        end)
    end)
    pcall(function()
        mq.event("tgStockDoneSig", "#*#[SIGNAL_DONE]#*##1#", function(line, name)
            stock_on_done_signal(line, name)
        end)
    end)
    pcall(function()
        mq.event("tgStockDoneAny", "#*#[DONE]#*#", function(line)
            stock_on_done_signal(line, nil)
        end)
    end)
    stock_job.events_on = true
end

local function stock_clear_done_events()
    if not stock_job.events_on then return end
    pcall(function() mq.unevent("tgStockDoneBC") end)
    pcall(function() mq.unevent("tgStockDoneSig") end)
    pcall(function() mq.unevent("tgStockDoneAny") end)
    stock_job.events_on = false
end

local function stock_finish_job(msg)
    stock_job.running = false
    stock_job.phase = "idle"
    stock_job.awaiting = nil
    stock_job.await_done = false
    stock_job.queue = {}
    stock_clear_done_events()
    if msg then item_actions.status_msg = msg end
    stock_rows_key = nil
    stock_board_index = nil
    stock_board_state.status = "building"
end

local function stock_start_job(plan, label)
    label = tostring(label or "Job")
    if stock_job.running then
        item_actions.status_msg = (stock_job.label or "Job") .. " already running."
        return
    end
    if type(plan) ~= "table" or #plan == 0 then
        stock_set_dry_plan(plan, label)
        return
    end
    stock_clear_dry_plan()
    stock_job.queue = {}
    for i, step in ipairs(plan) do stock_job.queue[i] = step end
    stock_job.total = #plan
    stock_job.done = 0
    stock_job.running = true
    stock_job.next_at = 0
    stock_job.label = label
    stock_job.phase = "gap"
    stock_job.awaiting = nil
    stock_job.await_done = false
    stock_ensure_done_events()
    item_actions.status_msg = string.format(
        "%s started (%d sends). Waits for each turboGive [DONE] before the next.",
        label, #plan)
end

local function stock_tick_job()
    if not stock_job.running then return end
    local now = os.clock()
    local label = stock_job.label or "Job"

    if stock_job.phase == "await" then
        -- Same-box donor: /squelch e3bc DONE used to never reach this UI. Local
        -- /echo is fixed in TurboGive 1.9.9; also treat TurboGive macro end as done.
        if not stock_job.await_done and stock_job.await_local
            and (now - (stock_job.await_started or 0)) >= STOCK_LOCAL_GRACE_S
            and stock_local_turbogive_idle() then
            stock_job.await_done = true
        end
        if stock_job.await_done or now >= (stock_job.await_until or 0) then
            if not stock_job.await_done then
                item_actions.status_msg = string.format(
                    "[%d/%d] timed out waiting for %s [DONE] - continuing.",
                    stock_job.done or 0, stock_job.total or 0,
                    tostring(stock_job.awaiting or "?"))
            end
            stock_job.phase = "gap"
            stock_job.next_at = now + STOCK_SEND_GAP_S
            stock_job.awaiting = nil
            stock_job.await_done = false
            stock_job.await_local = false
        end
        return
    end

    if now < (stock_job.next_at or 0) then return end

    local step = table.remove(stock_job.queue, 1)
    if not step then
        stock_finish_job(string.format("%s finished (%d sends).", label, stock_job.done or 0))
        return
    end

    stock_ensure_done_events()
    stock_job.await_done = false
    stock_job.awaiting = step.from
    stock_job.await_started = now
    stock_job.await_until = now + STOCK_AWAIT_TIMEOUT_S
    stock_job.await_local = stock_clean_name(step.from) == stock_clean_name(stock_me_name())
    stock_job.phase = "await"

    local ok, msg = integrations.send_stack(step.item, step.id, step.qty, step.from, step.to)
    stock_job.done = (stock_job.done or 0) + 1
    item_actions.status_msg = ok
        and string.format("[%d/%d] %s (waiting DONE)", stock_job.done, stock_job.total, tostring(msg))
        or string.format("[%d/%d] failed: %s", stock_job.done, stock_job.total, tostring(msg))
    -- Command dispatch failed: do not block the queue on a DONE that will never come.
    if not ok then
        stock_job.phase = "gap"
        stock_job.next_at = now + STOCK_SEND_GAP_S
        stock_job.awaiting = nil
        stock_job.await_done = false
        stock_job.await_local = false
    end
end

local function draw_stock_dry_preview()
    if stock_job.running then return end
    if not stock_dry.lines or #stock_dry.lines == 0 then return end
    col_text(Theme.amber or Theme.gold, string.format("%s preview (no trades) - %d send%s:",
        stock_dry.label ~= "" and stock_dry.label or "Plan",
        stock_dry.total or #stock_dry.lines,
        (stock_dry.total or 0) == 1 and "" or "s"))
    for _, line in ipairs(stock_dry.lines) do
        ImGui.TextDisabled(line)
    end
    local more = (stock_dry.total or 0) - #stock_dry.lines
    if more > 0 then
        ImGui.TextDisabled(string.format("... +%d more (run Even Out / Collect to execute)", more))
    end
end

local function draw_stock_toolbar(roster, records, board_index)
    stock_tick_job()
    local me = stock_me_name()

    col_text(Theme.dim, "Manage:")
    ImGui.SameLine()
    if theme.themed_button("Refresh##inv_stock_refresh", Theme.steel, 72, 0) then
        if Engine and Engine.request_all then
            Engine.request_all(true)
            if Engine.publish then Engine.publish(true, "full", { reason = "stock_refresh" }) end
            item_actions.status_msg = "Requested fresh inventory publishes."
        else
            item_actions.status_msg = "Sync unavailable (engine offline)."
        end
        stock_rows_key = nil
        stock_board_index = nil
        stock_board_state.status = "building"
    end
    if ImGui.IsItemHovered() and ImGui.SetTooltip then
        ImGui.SetTooltip("Ask peers to republish inventory over the TurboGear bus.")
    end
    ImGui.SameLine()
    if theme.themed_button("Add##inv_stock_add_cursor", Theme.steel, 52, 0) then
        stock_add_cursor_item()
    end
    if ImGui.IsItemHovered() and ImGui.SetTooltip then
        ImGui.SetTooltip("Add the cursor item as a stock rule (Target 5). Or right-click Keep Qty anywhere.")
    end
    ImGui.SameLine()
    local remove_label = stock_selected_rule_key and stock_selected_rule_key ~= ""
        and "Remove Selected##inv_stock_remove_selected"
        or "Remove##inv_stock_remove_selected"
    local remove_color = stock_selected_rule_key and stock_selected_rule_key ~= ""
        and (Theme.mutedBrick or { 0.58, 0.28, 0.30, 1.0 })
        or (Theme.steel or Theme.dim)
    if theme.themed_button(remove_label, remove_color, stock_selected_rule_key and stock_selected_rule_key ~= "" and 128 or 76, 0) then
        stock_remove_selected_rule()
    end
    if ImGui.IsItemHovered() and ImGui.SetTooltip then
        ImGui.SetTooltip("Select a stock row, then remove it from this board.")
    end
    ImGui.SameLine()
    col_text(Theme.dim, "Preview:")
    ImGui.SameLine()
    if theme.themed_button("Preview Even##inv_stock_dry_even", Theme.steel, 104, 0) then
        stock_set_dry_plan(stock_build_even_plan(roster, board_index), "Even Out")
    end
    if ImGui.IsItemHovered() and ImGui.SetTooltip then
        ImGui.SetTooltip("Preview Even Out: surplus -> short until Target (no trades). Stays listed below.")
    end
    ImGui.SameLine()
    if theme.themed_button("Preview Collect##inv_stock_dry_collect", Theme.steel, 116, 0) then
        stock_set_dry_plan(stock_build_collect_plan(roster, board_index, me), "Collect")
    end
    if ImGui.IsItemHovered() and ImGui.SetTooltip then
        ImGui.SetTooltip("Preview Collect: everyone else sends all board items to you (no trades). Stays listed below.")
    end
    ImGui.SameLine()
    col_text(Theme.dim, "Execute:")
    ImGui.SameLine()
    if stock_job.running then
        if theme.themed_button("Stop##inv_stock_stop", Theme.brick or Theme.steel, 56, 0) then
            local label = stock_job.label or "Job"
            local done, total = stock_job.done or 0, stock_job.total or 0
            stock_finish_job(string.format("%s stopped (%d/%d).", label, done, total))
        end
        if ImGui.IsItemHovered() and ImGui.SetTooltip then
            ImGui.SetTooltip("Cancel the remaining send queue (in-flight TurboGive may still finish).")
        end
    else
        if theme.themed_button("Even Out##inv_stock_even", Theme.blue or Theme.steel, 80, 0) then
            stock_start_job(stock_build_even_plan(roster, board_index), "Even Out")
        end
        if ImGui.IsItemHovered() and ImGui.SetTooltip then
            ImGui.SetTooltip("Donors TurboGive-send surplus to short toons one-at-a-time (waits [DONE]). Sync/Refresh first.")
        end
        ImGui.SameLine()
        if theme.themed_button("Collect to Me##inv_stock_collect", Theme.bag or Theme.blue or Theme.steel, 104, 0) then
            if me == "" then
                item_actions.status_msg = "Collect: could not resolve this character name."
            else
                stock_start_job(stock_build_collect_plan(roster, board_index, me), "Collect")
            end
        end
        if ImGui.IsItemHovered() and ImGui.SetTooltip then
            ImGui.SetTooltip(string.format(
                "Pull all board items from other toons to %s via TurboGive send (serial, wait DONE). Then Even Out to redistribute.",
                me ~= "" and me or "you"))
        end
    end

    ImGui.SameLine()
    if toggle_button("Short only##inv_stock_short_only", Settings.stockShortOnly == true, 92, 0) then
        Settings.stockShortOnly = not (Settings.stockShortOnly == true)
        SaveSettings()
    end
    if ImGui.IsItemHovered() and ImGui.SetTooltip then
        ImGui.SetTooltip("Show only rules with a current roster shortage.")
    end

    if stock_job.running then
        ImGui.NewLine()
        local phase = stock_job.phase == "await"
            and (" wait " .. tostring(stock_job.awaiting or "?"))
            or ""
        -- ASCII "..." only; MQ fonts turn unicode ellipsis into "?".
        col_text(Theme.amber or Theme.gold, string.format("%s %d/%d%s ...",
            stock_job.label or "Job", stock_job.done or 0, stock_job.total or 0, phase))
    end
end

local function draw_stock_group_header(label, nCols)
    ImGui.TableNextRow()
    if ImGui.TableSetBgColor and ImGuiTableBgTarget and ImGuiTableBgTarget.RowBg0 and theme.color_u32 then
        pcall(ImGui.TableSetBgColor, ImGuiTableBgTarget.RowBg0, theme.color_u32(Theme.sectionBg or Theme.steel))
    end
    ImGui.TableSetColumnIndex(0)
    col_text(Theme.category or Theme.section or Theme.cyan, tostring(label or ""))
    for c = 1, (nCols or 1) - 1 do
        ImGui.TableSetColumnIndex(c)
        ImGui.Dummy(1, 1)
    end
end

local function stock_board_want(board, fallback)
    local max_want = tonumber(fallback) or 0
    for _, cell in ipairs((board and board.cells) or {}) do
        local want = tonumber(cell.want) or 0
        if want > max_want then max_want = want end
    end
    return max_want
end

local function stock_cell_color(cell)
    if not cell or cell.eligible ~= true then return Theme.placeholder or Theme.dim end
    local have = tonumber(cell.have) or 0
    local want = tonumber(cell.want) or 0
    if have <= 0 then return Theme.dim end
    if (tonumber(cell.short) or 0) > 0 then return Theme.stockShort or STOCK_SHORT_COLOR end
    if want > 0 and have > want then return Theme.green or Theme.online end
    return Theme.value or Theme.online or Theme.green
end

local function stock_selected_row_bg()
    if not (ImGui.TableSetBgColor and ImGuiTableBgTarget and ImGuiTableBgTarget.RowBg0 and theme.color_u32) then
        return
    end
    pcall(ImGui.TableSetBgColor, ImGuiTableBgTarget.RowBg0, theme.color_u32({ 0.15, 0.24, 0.36, 1.0 }))
end

local function stock_draw_group_header(nChars)
    ImGui.TableNextRow()
    if ImGui.TableSetBgColor and ImGuiTableBgTarget and ImGuiTableBgTarget.RowBg0 and theme.color_u32 then
        pcall(ImGui.TableSetBgColor, ImGuiTableBgTarget.RowBg0, theme.color_u32(STOCK_GROUP_BG))
    end
    ImGui.TableSetColumnIndex(0)
    stock_draw_header_cell("Item", STOCK_GROUP_TEXT)
    ImGui.TableSetColumnIndex(1)
    ImGui.Dummy(1, 1)
    ImGui.TableSetColumnIndex(3)
    stock_draw_header_cell("Stock", STOCK_GROUP_TEXT)
    ImGui.TableSetColumnIndex(5)
    ImGui.Dummy(1, 1)
    if nChars > 0 then
        ImGui.TableSetColumnIndex(6 + math.floor((nChars - 1) * 0.5))
        stock_draw_header_cell("Toons", STOCK_GROUP_TEXT)
    end
end

local function draw_stock_view()
    stock_ensure_defaults()
    local roster, records = stock_roster_and_records()
    local _, board_index = stock_rows_for_records(records)
    draw_stock_toolbar(roster, records, board_index)
    draw_stock_dry_preview()
    if not board_index then
        col_text(Theme.dim, "Preparing stock board from synced inventory...")
        return
    end

    local rules = keep_qty.rules()
    if #rules == 0 then
        col_text(Theme.placeholder or Theme.dim, "No stock rules yet. Add from cursor, or right-click Keep Qty on an item.")
        return
    end
    if #roster == 0 then
        col_text(Theme.amber, "No characters selected. Open the Characters pill (Source + Show Columns), then Sync Now.")
        return
    end
    local nChars = #roster
    local nCols = 1 + 1 + 3 + 1 + nChars -- Item | spacer | Have | Target | Short | spacer | chars...
    local char_w = nChars >= 7 and 52.0 or 58.0
    local shown = 0
    local last_group = nil
    -- Fill remaining window height (small reserve for legend). Prior min_h=420
    -- forced a tall table into a shorter region -> cut off + empty chrome below.
    local table_id = "InventoryStockBoardV2"
    local extra_flags = (ImGuiTableFlags.ScrollX or 0)
        + (ImGuiTableFlags.BordersOuter or 0)
        + (ImGuiTableFlags.NoSavedSettings or 0)
    local flags = views.scroll_table_flags(extra_flags)
    if views.begin_scroll_table(table_id, nCols, flags, 22.0, 160.0) then
        ImGui.TableSetupColumn("Item", ImGuiTableColumnFlags.WidthFixed, STOCK_ITEM_COL_W)
        ImGui.TableSetupColumn("", ImGuiTableColumnFlags.WidthFixed, STOCK_SPACER_W)
        ImGui.TableSetupColumn("Have", ImGuiTableColumnFlags.WidthFixed, 56.0)
        ImGui.TableSetupColumn("Target", ImGuiTableColumnFlags.WidthFixed, 64.0)
        ImGui.TableSetupColumn("Short", ImGuiTableColumnFlags.WidthFixed, 58.0)
        ImGui.TableSetupColumn("", ImGuiTableColumnFlags.WidthFixed, STOCK_SPACER_W)
        for _, member in ipairs(roster) do
            ImGui.TableSetupColumn(stock_short_header(member.name), ImGuiTableColumnFlags.WidthFixed, char_w)
        end
        views.setup_scroll_freeze(table_id, 6, 2)
        stock_draw_group_header(nChars)
        ImGui.TableNextRow()
        ImGui.TableSetColumnIndex(0); stock_draw_header_cell("", Theme.header or Theme.item)
        ImGui.TableSetColumnIndex(1); stock_draw_header_cell("", Theme.dim)
        ImGui.TableSetColumnIndex(2); stock_draw_header_cell("Have", Theme.header or Theme.item)
        ImGui.TableSetColumnIndex(3); stock_draw_header_cell("Target", Theme.header or Theme.item)
        ImGui.TableSetColumnIndex(4); stock_draw_header_cell("Short", Theme.header or Theme.item)
        ImGui.TableSetColumnIndex(5); stock_draw_header_cell("", Theme.dim)
        for c, member in ipairs(roster) do
            ImGui.TableSetColumnIndex(c + 5)
            stock_draw_header_cell(stock_short_header(member.name), views.class_color(member.class))
            if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
                ImGui.SetTooltip(string.format("%s (%s)", tostring(member.name or "?"), keep_qty.class_abbrev(member.class)))
            end
        end

        for i, rule in ipairs(rules) do
            if stock_rule_matches_search(rule) then
                local board = keep_qty.evaluate_board_from_index(rule, board_index, roster)
                local need = board and board.need or 0
                if not (Settings.stockShortOnly == true and need <= 0) then
                    local group = tostring(rule.group or "")
                    if group == "" then group = "Other" end
                    if group ~= last_group then
                        draw_stock_group_header(group, nCols)
                        last_group = group
                    end

                    shown = shown + 1
                    ImGui.TableNextRow()
                    local rule_key = stock_rule_ui_key(rule)
                    local selected = rule_key ~= "" and rule_key == stock_selected_rule_key
                    if selected then stock_selected_row_bg() end
                    ImGui.TableSetColumnIndex(0)
                    local full = rule.name ~= "" and rule.name or ("item " .. tostring(rule.id))
                    local label = keep_qty.display_name(full)
                    local hint = keep_qty.hint_label(rule)
                    local color = Theme.item or Theme.cyan
                    theme.colored_text(label, color)
                    if ImGui.IsItemClicked and ImGui.IsItemClicked() and rule_key ~= "" then
                        stock_selected_rule_key = rule_key
                    end
                    if ImGui.IsItemHovered() and ImGui.SetTooltip then
                        local tip = full
                        tip = tip .. "\nClick to select for Remove."
                        if hint ~= "" then tip = tip .. "\n" .. hint end
                        if need > 0 then tip = tip .. string.format("\nShort %d across roster", need) end
                        ImGui.SetTooltip(tip)
                    end
                    item_actions.draw_context(full, rule.id, "inv_stock_" .. tostring(i),
                        item_actions.context_opts({}, { name = full, id = rule.id }))

                    local total_have = tonumber(board and board.total) or 0
                    local want_v = stock_board_want(board, rule.qty)

                    ImGui.TableSetColumnIndex(1)
                    ImGui.Dummy(1, 1)

                    ImGui.TableSetColumnIndex(2)
                    stock_draw_center_cell(need > 0 and (Theme.value or Theme.neutral or Theme.dim) or (Theme.green or Theme.online), tostring(total_have))

                    ImGui.TableSetColumnIndex(3)
                    ImGui.SetNextItemWidth(-1)
                    if ImGui.InputInt then
                        local next_v, changed = ImGui.InputInt("##stock_want_" .. tostring(i), want_v, 0)
                        next_v = math.max(0, math.floor(tonumber(next_v) or want_v))
                        if next_v ~= (tonumber(rule.qty) or 0) and (changed == nil or changed) then
                            local ok, err = keep_qty.set_qty(i, next_v)
                            item_actions.status_msg = ok and "Stock Target updated." or tostring(err or "Could not save Target.")
                        end
                    else
                        col_text(Theme.dim, tostring(want_v))
                    end
                    if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
                        ImGui.SetTooltip("Target count per eligible toon. Click to edit.")
                    end

                    ImGui.TableSetColumnIndex(4)
                    if need > 0 then
                        stock_draw_center_cell(Theme.stockShort or STOCK_SHORT_COLOR, tostring(need))
                    else
                        stock_draw_center_cell(Theme.green or Theme.online, "Met")
                    end

                    ImGui.TableSetColumnIndex(5)
                    ImGui.Dummy(1, 1)

                    for c, cell in ipairs((board and board.cells) or {}) do
                        ImGui.TableSetColumnIndex(c + 5)
                        local text = tostring(cell.have or 0)
                        stock_draw_center_cell(stock_cell_color(cell), text)
                        if ImGui.IsItemHovered() then stock_cell_tooltip(cell, full) end
                    end
                end
            end
        end
        ImGui.EndTable()
    end

    if shown == 0 then
        col_text(Theme.placeholder or Theme.dim, Settings.stockShortOnly == true
            and "No short stock rules match Search everywhere."
            or "No stock rules match Search everywhere.")
    else
        local selected_summary = stock_selected_rule_summary(board_index, roster)
        if selected_summary then
            col_text(Theme.muted or Theme.dim, selected_summary .. " | Collect to Me, then Even Out.")
        else
            col_text(Theme.muted or Theme.dim, "Select a row to remove. Collect to Me, then Even Out.")
        end
    end
    local status = item_actions.status and item_actions.status() or ""
    if status ~= "" then col_text(Theme.amber or Theme.item, status) end
end

local function file_label(path)
    return tostring(path or ""):match("([^/\\]+)$") or tostring(path or "")
end

local function transfer_time_label(at)
    at = tonumber(at) or 0
    if at <= 0 then return "-" end
    local ok, text = pcall(os.date, "%H:%M", at)
    return ok and text or "-"
end

local function transfer_qty_label(qty)
    qty = tonumber(qty) or 0
    return qty > 0 and tostring(qty) or "all"
end

local function transfer_matches_search(row)
    local needle = search_text()
    if needle == "" then return true end
    local hay = table.concat({
        row.item or "",
        row.from or "",
        row.to or "",
        row.location or "",
        row.ini or "",
        row.value or "",
    }, " "):lower()
    return hay:find(needle, 1, true) ~= nil
end

local function open_transfer_ini(path)
    path = tostring(path or "")
    if path == "" then
        item_actions.status_msg = "No INI path recorded for this transfer."
        return
    end
    if ShellOpen and ShellOpen.shellOpenFile and ShellOpen.shellOpenFile(path) then
        item_actions.status_msg = "Opened " .. file_label(path) .. "."
    else
        item_actions.status_msg = "Could not open " .. file_label(path) .. "."
    end
end

local function search_transfer_item(row)
    Settings.inventoryViewMode = "table"
    Settings.inventoryScope = "all"
    Settings.inventorySearch = tostring(row and row.item or "")
    Settings.inventoryShowAllRows = false
    rows_key = nil
    SaveSettings()
end

local function draw_transfers_view()
    local rows = transfers.entries()
    if #rows == 0 then
        col_text(Theme.placeholder or Theme.dim, "No TurboGive rules recorded yet. Right-click an item and choose TurboGive Rule.")
        return
    end

    col_text(Theme.dim, "Recent explicit TurboGive [GiveList] writes in the active TurboLoot INI. Stock/Keep Qty rules are stored separately in TurboGear's Keep Qty cache.")
    ImGui.SameLine()
    if theme.themed_button("Clear Recent##inv_transfers_clear", Theme.steel, 92, 0) then
        local ok, err = transfers.clear()
        item_actions.status_msg = ok and "Cleared TurboGive transfer history." or tostring(err or "Could not clear transfers.")
        return
    end

    local shown = 0
    if views.begin_scroll_table("InventoryTransfers", 8, views.scroll_table_flags(), 160.0, 420.0) then
        ImGui.TableSetupColumn("Time", ImGuiTableColumnFlags.WidthFixed, 48.0)
        ImGui.TableSetupColumn("Item", ImGuiTableColumnFlags.WidthStretch, 1.7)
        ImGui.TableSetupColumn("From", ImGuiTableColumnFlags.WidthFixed, 104.0)
        ImGui.TableSetupColumn("To", ImGuiTableColumnFlags.WidthFixed, 104.0)
        ImGui.TableSetupColumn("Qty", ImGuiTableColumnFlags.WidthFixed, 42.0)
        ImGui.TableSetupColumn("Location", ImGuiTableColumnFlags.WidthStretch, 1.4)
        ImGui.TableSetupColumn("INI", ImGuiTableColumnFlags.WidthFixed, 132.0)
        ImGui.TableSetupColumn("Actions", ImGuiTableColumnFlags.WidthFixed, 188.0)
        views.table_headers_centered({ "Time", "Item", "From", "To", "Qty", "Location", "INI", "Actions" })
        for i, row in ipairs(rows) do
            if transfer_matches_search(row) then
                shown = shown + 1
                ImGui.TableNextRow()
                ImGui.TableSetColumnIndex(0)
                col_text(Theme.dim, transfer_time_label(row.at))
                ImGui.TableSetColumnIndex(1)
                item_actions.draw_name(row.item or "?", Theme.item, "inv_transfer_item_" .. tostring(i), row.id, item_actions.context_opts({
                    owner = row.from,
                    sourceLocation = row.location,
                }, { owner = row.from, location = row.location, id = row.id, name = row.item }))
                ImGui.TableSetColumnIndex(2)
                col_text(Theme.dim, row.from ~= "" and row.from or "-")
                ImGui.TableSetColumnIndex(3)
                col_text(Theme.value or Theme.green, row.to or "?")
                ImGui.TableSetColumnIndex(4)
                col_text(Theme.dim, transfer_qty_label(row.qty))
                ImGui.TableSetColumnIndex(5)
                local loc = row.location ~= "" and row.location or "-"
                local _, loc_clipped = views.col_text_fit(Theme.dim, loc, views.current_column_width())
                if loc_clipped and ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then ImGui.SetTooltip(loc) end
                ImGui.TableSetColumnIndex(6)
                local ini = file_label(row.ini)
                local _, ini_clipped = views.col_text_fit(Theme.dim, ini, views.current_column_width())
                if ini_clipped and ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then ImGui.SetTooltip(row.ini or "") end
                ImGui.TableSetColumnIndex(7)
                if theme.themed_button("Find##inv_transfer_find_" .. tostring(i), Theme.steel, 42, 0) then
                    search_transfer_item(row)
                end
                ImGui.SameLine()
                if theme.themed_button("INI##inv_transfer_ini_" .. tostring(i), Theme.steel, 36, 0) then
                    open_transfer_ini(row.ini)
                end
                ImGui.SameLine()
                if theme.themed_button("Cmd##inv_transfer_cmd_" .. tostring(i), Theme.steel, 42, 0) then
                    item_actions.copy_text("TurboGive command", "/mac TurboGive " .. tostring(row.to or ""))
                end
                ImGui.SameLine()
                if theme.themed_button("X##inv_transfer_remove_" .. tostring(i), Theme.steel, 28, 0) then
                    local ok, err = transfers.remove(i)
                    item_actions.status_msg = ok and tostring(err or "Removed transfer.") or tostring(err or "Could not remove transfer.")
                    ImGui.EndTable()
                    return
                end
            end
        end
        ImGui.EndTable()
    end
    if shown == 0 then
        col_text(Theme.placeholder or Theme.dim, "No TurboGive transfer rows match the current search.")
    end
end

local function is_container_root(item, group)
    if type(item) ~= "table" then return false end
    if group == "bags" then return tostring(item.slotname or "") == "Bag" end
    if group == "bank" then return tonumber(item.slotname) == 0 end
    return false
end

local function container_key(source_key, group, slotid)
    return tostring(source_key or "?") .. ":" .. tostring(group or "?") .. ":" .. tostring(slotid or "?")
end

local function container_sort(a, b)
    if a.source ~= b.source then return tostring(a.owner or a.source) < tostring(b.owner or b.source) end
    if a.group ~= b.group then return tostring(a.group) < tostring(b.group) end
    return (tonumber(a.slotid) or 0) < (tonumber(b.slotid) or 0)
end

local function slot_sort(a, b)
    return (tonumber(a.slotname) or 9999) < (tonumber(b.slotname) or 9999)
end

local function row_from_item(snap, source_key, item, group, location)
    local out = {}
    add_row(out, snap, source_key, item, {
        locationGroup = group,
        where = group,
        location = location or item.location or item.where or group,
    })
    return out[1]
end

local function build_containers(records)
    local wanted = tostring(Settings.inventoryLocationFilter or "all")
    local visual_all = wanted ~= "bags" and wanted ~= "bank"
    local allow_bags = visual_all or wanted == "bags"
    local allow_bank = visual_all or wanted == "bank"
    local map, containers = {}, {}
    local multi = #(records or {}) > 1

    local function ensure_container(rec_source, group, slotid, root)
        local key = container_key(rec_source.key, group, slotid)
        local rec = map[key]
        if not rec then
            local prefix = group == "bank" and "Bank " or "Bag "
            local n = group == "bags" and ((tonumber(slotid) or 22) - 22) or tonumber(slotid)
            local owner = source_owner(rec_source.key, rec_source.snap)
            rec = {
                key = key,
                group = group,
                slotid = slotid,
                source = rec_source.key,
                snap = rec_source.snap,
                owner = owner,
                root = root,
                label = string.format("%s%s", prefix, tostring(n or "?")),
                items = {},
            }
            map[key] = rec
            containers[#containers + 1] = rec
        elseif root and not rec.root then
            rec.root = root
        end
        return rec
    end

    local function scan(rec_source, list, group, allowed)
        if not allowed then return end
        for _, item in ipairs(list or {}) do
            local slotid = tonumber(item.slotid) or item.slotid
            if is_container_root(item, group) then
                local rec = ensure_container(rec_source, group, slotid, item)
                local owner_prefix = multi and (tostring(rec.owner or "?") .. " - ") or ""
                rec.label = string.format("%s%s: %s", owner_prefix, rec.label, tostring(item.name or "item"))
            else
                local rec = ensure_container(rec_source, group, slotid, nil)
                rec.items[#rec.items + 1] = item
            end
        end
    end

    for _, rec_source in ipairs(records or {}) do
        scan(rec_source, rec_source.snap and rec_source.snap.bags, "bags", allow_bags)
        scan(rec_source, rec_source.snap and rec_source.snap.bank, "bank", allow_bank)
    end
    table.sort(containers, container_sort)
    for _, rec in ipairs(containers) do table.sort(rec.items, slot_sort) end

    local selected = Settings.inventorySelectedContainer
    if selected == "" or not map[selected] then
        selected = containers[1] and containers[1].key or ""
        Settings.inventorySelectedContainer = selected
    end
    return containers, map[selected]
end

local function draw_container_list(containers)
    col_text(Theme.section or Theme.header, "Containers")
    if views.begin_scroll_table("InventoryContainers", 2, views.scroll_table_flags(), 120.0, 260.0) then
        ImGui.TableSetupColumn("Icon", ImGuiTableColumnFlags.WidthFixed, 34.0)
        ImGui.TableSetupColumn("Bag", ImGuiTableColumnFlags.WidthStretch, 1.0)
        views.table_headers_centered({ "Icon", "Bag" })
        for i, rec in ipairs(containers or {}) do
            ImGui.TableNextRow()
            ImGui.TableSetColumnIndex(0)
            if rec.root then draw_icon(rec.root.icon, 22.0) else col_text(Theme.placeholder or Theme.dim, "-") end
            ImGui.TableSetColumnIndex(1)
            local selected = Settings.inventorySelectedContainer == rec.key
            if ImGui.Selectable(tostring(rec.label or rec.key) .. "##inv_container_" .. tostring(i), selected) then
                Settings.inventorySelectedContainer = rec.key
                SaveSettings()
            end
            if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
                ImGui.SetTooltip(string.format("%d cached item%s", #(rec.items or {}), #(rec.items or {}) == 1 and "" or "s"))
            end
        end
        ImGui.EndTable()
    end
end

local function draw_bag_item_cell(rec, item, snap, source_key, index)
    local slot_label = tostring(item and item.slotname or index or "?")
    local row = item and row_from_item(snap, source_key, item, rec.group, tostring(item.where or rec.label or "")) or nil
    ImGui.PushID("inv_bag_cell_" .. tostring(rec.key) .. "_" .. tostring(slot_label))
    if ImGui.InvisibleButton then
        ImGui.InvisibleButton("##bagcell", GRID_CELL, GRID_CELL)
    else
        ImGui.Button(slot_label .. "##bagcell", GRID_CELL, GRID_CELL)
    end
    local hovered = ImGui.IsItemHovered and ImGui.IsItemHovered() or false
    if row then
        item_actions.draw_context(row.name, row.id, "inv_bag_grid_" .. tostring(rec.key) .. "_" .. tostring(slot_label),
            item_actions.context_opts({ sourceLocation = row.location or "" }, row))
    end
    local rect = item_rect()
    if rect and ImGui.SetCursorScreenPos then ImGui.SetCursorScreenPos(rect.x1 + 4, rect.y1 + 3) end
    if row and row.icon and row.icon > 0 then
        draw_icon(row.icon, GRID_CELL - 10)
    else
        col_text(Theme.placeholder or Theme.dim, slot_label)
    end
    if hovered then
        ImGui.BeginTooltip()
        col_text(Theme.slot, "Slot " .. slot_label)
        if row then
            item_actions.draw_name(row.name or "?", row.kind == "aug" and (Theme.aug or Theme.green) or Theme.item,
                "inv_bag_tip_" .. tostring(rec.key) .. "_" .. tostring(slot_label), row.id)
            col_text(Theme.dim, tostring(row.location or rec.label or ""))
            col_text(Theme.dim, string.format("AC %s  HP %s  Mana %s", stat_text(row, "ac"), stat_text(row, "hp"), stat_text(row, "mana")))
        else
            col_text(Theme.placeholder or Theme.dim, "(empty)")
        end
        ImGui.EndTooltip()
    end
    ImGui.PopID()
end

local function draw_container_contents(rec)
    if not rec then
        col_text(Theme.dim, "No cached bags or bank slots for this character.")
        return
    end
    col_text(Theme.section or Theme.header, tostring(rec.label or "Container"))
    local count = #(rec.items or {})
    local root_name = rec.root and tostring(rec.root.name or "") or ""
    local subtitle = root_name ~= "" and string.format("%s | %d cached item%s", root_name, count, count == 1 and "" or "s")
        or string.format("%d cached item%s", count, count == 1 and "" or "s")
    col_text(Theme.dim, subtitle)
    if rec.root then
        local root_row = row_from_item(rec.snap, rec.source, rec.root, rec.group, tostring(rec.root.where or rec.label or ""))
        if root_row then
            item_actions.draw_name(root_row.name or "?", Theme.item, "inv_container_root_" .. tostring(rec.key), root_row.id,
                item_actions.context_opts({ sourceLocation = root_row.location or "" }, root_row))
        end
    end
    ImGui.Separator()
    if count <= 0 then
        col_text(Theme.placeholder or Theme.dim, "No cached contents in this container.")
        return
    end

    if ImGui.BeginTable("InventoryContainerGrid", 6, ImGuiTableFlags.Borders + ImGuiTableFlags.RowBg + ImGuiTableFlags.SizingFixedFit) then
        local shown = 0
        for i, item in ipairs(rec.items or {}) do
            local row = row_from_item(rec.snap, rec.source, item, rec.group, tostring(item.where or rec.label or ""))
            if row and not matches_filter(row) then goto continue end
            shown = shown + 1
            if (shown - 1) % 6 == 0 then ImGui.TableNextRow(0, GRID_CELL + 6) end
            ImGui.TableNextColumn()
            draw_bag_item_cell(rec, item, rec.snap, rec.source, i)
            ::continue::
        end
        if shown == 0 then
            ImGui.TableNextRow(0, GRID_CELL + 6)
            ImGui.TableNextColumn()
            col_text(Theme.placeholder or Theme.dim, "No matches.")
        end
        ImGui.EndTable()
    end
end

local function draw_bag_search_results(containers)
    local matches = {}
    for _, rec in ipairs(containers or {}) do
        for i, item in ipairs(rec.items or {}) do
            local row = row_from_item(rec.snap, rec.source, item, rec.group, tostring(item.where or rec.label or ""))
            if row and matches_filter(row) then
                row.containerLabel = rec.label
                row.containerIndex = i
                matches[#matches + 1] = row
            end
        end
    end
    col_text(Theme.section or Theme.header, string.format("Bag Search Matches: %d", #matches))
    if #matches == 0 then
        col_text(Theme.placeholder or Theme.dim, "No cached bag or bank matches.")
        return
    end
    if views.begin_scroll_table("InventoryBagSearch", 5, views.scroll_table_flags(), 92.0, 260.0) then
        ImGui.TableSetupColumn("Owner", ImGuiTableColumnFlags.WidthFixed, 118.0)
        ImGui.TableSetupColumn("Icon", ImGuiTableColumnFlags.WidthFixed, 34.0)
        ImGui.TableSetupColumn("Item", ImGuiTableColumnFlags.WidthStretch, 1.7)
        ImGui.TableSetupColumn("Container", ImGuiTableColumnFlags.WidthStretch, 1.2)
        ImGui.TableSetupColumn("ID", ImGuiTableColumnFlags.WidthFixed, 70.0)
        views.table_headers_centered({ "Owner", "Icon", "Item", "Container", "ID" })
        for i, row in ipairs(matches) do
            ImGui.TableNextRow()
            ImGui.TableSetColumnIndex(0)
            views.draw_owner_cell(row)
            ImGui.TableSetColumnIndex(1)
            draw_icon(row.icon, 22.0)
            ImGui.TableSetColumnIndex(2)
            draw_row_item(row, i)
            ImGui.TableSetColumnIndex(3)
            col_text(theme.location_color(row.locationGroup, row.location), row.location or row.containerLabel or "-")
            ImGui.TableSetColumnIndex(4)
            col_text(Theme.dim, tonumber(row.id) and row.id > 0 and tostring(math.floor(row.id)) or "-")
        end
        ImGui.EndTable()
    end
end

local function draw_all_bag_contents(containers)
    local rows = {}
    for _, rec in ipairs(containers or {}) do
        for i, item in ipairs(rec.items or {}) do
            local row = row_from_item(rec.snap, rec.source, item, rec.group, tostring(item.where or rec.label or ""))
            if row and matches_filter(row) then
                row.containerLabel = rec.label
                row.containerIndex = i
                rows[#rows + 1] = row
            end
        end
    end
    col_text(Theme.section or Theme.header, string.format("All Bag/Bank Contents: %d", #rows))
    if #rows == 0 then
        col_text(Theme.placeholder or Theme.dim, "No cached occupied bag or bank slots match.")
        return
    end
    if views.begin_scroll_table("InventoryBagAllContents", 6, views.scroll_table_flags(), 92.0, 260.0) then
        ImGui.TableSetupColumn("Owner", ImGuiTableColumnFlags.WidthFixed, 118.0)
        ImGui.TableSetupColumn("Icon", ImGuiTableColumnFlags.WidthFixed, 34.0)
        ImGui.TableSetupColumn("Item", ImGuiTableColumnFlags.WidthStretch, 1.7)
        ImGui.TableSetupColumn("Container", ImGuiTableColumnFlags.WidthStretch, 1.2)
        ImGui.TableSetupColumn("Qty", ImGuiTableColumnFlags.WidthFixed, 42.0)
        ImGui.TableSetupColumn("ID", ImGuiTableColumnFlags.WidthFixed, 70.0)
        views.table_headers_centered({ "Owner", "Icon", "Item", "Container", "Qty", "ID" })
        for i, row in ipairs(rows) do
            ImGui.TableNextRow()
            ImGui.TableSetColumnIndex(0)
            views.draw_owner_cell(row)
            ImGui.TableSetColumnIndex(1)
            draw_icon(row.icon, 22.0)
            ImGui.TableSetColumnIndex(2)
            draw_row_item(row, i)
            ImGui.TableSetColumnIndex(3)
            col_text(theme.location_color(row.locationGroup, row.location), row.location or row.containerLabel or "-")
            ImGui.TableSetColumnIndex(4)
            col_text(Theme.dim, tostring(row.qty or 1))
            ImGui.TableSetColumnIndex(5)
            col_text(Theme.dim, tonumber(row.id) and row.id > 0 and tostring(math.floor(row.id)) or "-")
        end
        ImGui.EndTable()
    end
end

local function draw_bag_browser(records)
    local containers, selected = build_containers(records)
    if ImGui.BeginTable("InventoryBagLayout", 2, ImGuiTableFlags.Resizable + ImGuiTableFlags.BordersInnerV) then
        ImGui.TableSetupColumn("Containers", ImGuiTableColumnFlags.WidthFixed, 260.0)
        ImGui.TableSetupColumn("Contents", ImGuiTableColumnFlags.WidthStretch, 1.0)
        ImGui.TableNextRow()
        ImGui.TableSetColumnIndex(0)
        draw_container_list(containers)
        ImGui.TableSetColumnIndex(1)
        if search_text() ~= "" then
            draw_bag_search_results(containers)
        elseif Settings.inventoryBagSubview == "all" then
            draw_all_bag_contents(containers)
        else
            draw_container_contents(selected)
        end
        ImGui.EndTable()
    else
        draw_container_list(containers)
        if search_text() ~= "" then
            draw_bag_search_results(containers)
        elseif Settings.inventoryBagSubview == "all" then
            draw_all_bag_contents(containers)
        else
            draw_container_contents(selected)
        end
    end
end

local function slot_item_for_snap(snap, slot_id)
    return views.index_equipped(snap or {})[tonumber(slot_id)]
end

local function slot_compare_keys()
    local primary = characters.get_primary("inventory")
    local keys = characters.source_keys("inventory")
    if #keys == 0 then
        keys = views.source_keys(true) or {}
    end
    local out, seen = {}, {}
    local function add(key)
        key = tostring(key or "")
        if key == "" or seen[key] then return end
        seen[key] = true
        out[#out + 1] = key
    end
    add(primary)
    for _, key in ipairs(keys) do add(key) end
    return out
end

local function draw_slot_compare()
    local slot_id = tonumber(Settings.inventorySelectedSlotId)
    if not slot_id then return end
    local slot_name = items.slot_display_name(slot_id)
    local open = theme.collapsing_section(
        "Compare Selected Slot: " .. tostring(slot_name), false)
    if not open then return end
    local keys = slot_compare_keys()
    local rows = {}
    for _, key in ipairs(keys) do
        local snap = views.source_snapshot(key)
        if snap then
            rows[#rows + 1] = {
                key = key,
                snap = snap,
                item = slot_item_for_snap(snap, slot_id),
            }
        end
    end
    if #rows == 0 then
        col_text(Theme.dim, "No characters in this Source yet. Open the Characters pill to change Source.")
        return
    end
    -- Fit height to row count (ScrollY tables otherwise eat remaining window height).
    local table_h = 26.0 + (#rows * 22.0) + 6.0
    if table_h > 220.0 then table_h = 220.0 end
    if views.begin_scroll_table("InventorySlotCompare", 6, views.scroll_table_flags(), 8.0, table_h, table_h) then
        ImGui.TableSetupColumn("Character", ImGuiTableColumnFlags.WidthFixed, 132.0)
        ImGui.TableSetupColumn("Icon", ImGuiTableColumnFlags.WidthFixed, 34.0)
        ImGui.TableSetupColumn("Item", ImGuiTableColumnFlags.WidthStretch, 2.0)
        ImGui.TableSetupColumn("AC", ImGuiTableColumnFlags.WidthFixed, 48.0)
        ImGui.TableSetupColumn("HP", ImGuiTableColumnFlags.WidthFixed, 58.0)
        ImGui.TableSetupColumn("Mana", ImGuiTableColumnFlags.WidthFixed, 58.0)
        views.setup_scroll_freeze("InventorySlotCompare", 0, 1)
        views.table_headers_centered({ "Character", "Icon", "Item", "AC", "HP", "Mana" })
        local primary = characters.get_primary("inventory")
        for i, rec in ipairs(rows) do
            local item = rec.item
            ImGui.TableNextRow()
            ImGui.TableSetColumnIndex(0)
            local name_color = views.source_header_color(rec.key)
            if rec.key == primary then
                name_color = Theme.item or name_color
            end
            col_text(name_color, views.source_label(rec.key):gsub("%s*%[[^%]]+%]", ""))
            ImGui.TableSetColumnIndex(1)
            if item then draw_icon(item.icon, 22.0) else col_text(Theme.placeholder or Theme.dim, "-") end
            ImGui.TableSetColumnIndex(2)
            if item then
                local owner = source_owner(rec.key, rec.snap)
                item_actions.draw_name(item.name or "?", Theme.item, "inv_slot_cmp_" .. tostring(i), item.id,
                    item_actions.context_opts({ sourceLocation = tostring(item.slotname or item.where or "") }, item, owner))
            else
                col_text(Theme.placeholder or Theme.dim, "(empty)")
            end
            ImGui.TableSetColumnIndex(3)
            col_text(stat_color(item), item and stat_text(item, "ac") or "-")
            ImGui.TableSetColumnIndex(4)
            col_text(stat_color(item), item and stat_text(item, "hp") or "-")
            ImGui.TableSetColumnIndex(5)
            col_text(stat_color(item), item and stat_text(item, "mana") or "-")
        end
        ImGui.EndTable()
    end
end

local function draw_inventory_content()
    local snap = nil
    local key = views.validate_source_key(Settings.inventoryViewKey or "__self__")
    Settings.inventoryViewKey = key
    snap = views.source_snapshot(key)
    local records = source_records()

    if not snap and #records == 0 then
        col_text(Theme.amber, "No cached inventory for this character yet. Use Sync Now when ready.")
        return
    end

    local mode = tostring(Settings.inventoryViewMode or "table")
    local rows, meta = {}, { shown = 0, total = 0 }
    if mode ~= "transfers" then
        rows, meta = visible_rows(records)
    end
    local updated = tonumber(snap and (snap.inventoryUpdated or snap.updated)) or 0
    local age = updated > 0 and math.max(0, os.time() - updated) or nil
    local depth = tostring(snap and snap.depth or "lite")
    local scope = tostring(Settings.inventoryScope or "single")
    local scope_desc = scope == "single" and views.source_label(key) or string.format("%s scope (%d cached character%s)",
        scope_label(), #records, #records == 1 and "" or "s")
    if mode == "transfers" then
        local transfer_count = #transfers.entries()
        col_text(Theme.dim, string.format("%s | %s cache | %d TurboGive transfer%s | %s",
            scope_desc,
            depth,
            transfer_count,
            transfer_count == 1 and "" or "s",
            format_age(age)))
    else
        col_text(Theme.dim, string.format("%s | %s cache | %d shown / %d cached item%s | %s",
            scope_desc,
            depth,
            meta.shown or #rows,
            meta.total or #rows,
            (meta.total or #rows) == 1 and "" or "s",
            format_age(age)))
    end
    local bank_text, bank_color = bank_status_text(snap)
    if bank_text then col_text(bank_color, bank_text) end

    if ImGui.BeginTable("InventoryMainLayout", 2, ImGuiTableFlags.Resizable + ImGuiTableFlags.BordersInnerV) then
        ImGui.TableSetupColumn("Worn", ImGuiTableColumnFlags.WidthFixed, 226.0)
        ImGui.TableSetupColumn("Inventory", ImGuiTableColumnFlags.WidthStretch, 1.0)
        ImGui.TableNextRow()
        ImGui.TableSetColumnIndex(0)
        draw_equipped_grid(snap)
        ImGui.TableSetColumnIndex(1)
        if Settings.inventoryViewMode == "bags" then
            draw_bag_browser(records)
        elseif Settings.inventoryViewMode == "transfers" then
            draw_transfers_view()
        else
            draw_item_table(rows, #records > 1)
        end
        ImGui.EndTable()
    else
        draw_equipped_grid(snap)
        if Settings.inventoryViewMode == "bags" then
            draw_bag_browser(records)
        elseif Settings.inventoryViewMode == "transfers" then
            draw_transfers_view()
        else
            draw_item_table(rows, #records > 1)
        end
    end
    draw_slot_compare()
end

local function draw_inventory_body()
    ensure_defaults()
    draw_filters()

    local child_began = false
    local child_open = true
    if ImGui.BeginChild then
        local ok, open = pcall(function()
            if ImVec2 then
                return ImGui.BeginChild("##inventory_content_scroll", ImVec2(0, 0), false, 0)
            end
            return ImGui.BeginChild("##inventory_content_scroll", 0, 0, false, 0)
        end)
        if ok then
            child_began = true
            child_open = (open ~= false)
        end
    end
    if child_open then draw_inventory_content() end
    if child_began and ImGui.EndChild then ImGui.EndChild() end
end

function M.draw()
    return diag.time("ui.inventory.draw", draw_inventory_body)
end

local function draw_stock_body()
    ensure_defaults()
    stock_ensure_defaults()
    -- No nested scroll child: the board table owns ScrollY and fills avail height.
    -- A wrapping BeginChild(0,0) left empty chrome under a min-height table.
    local rule_count = #keep_qty.rules()
    col_text(Theme.header or Theme.neutral, string.format(
        "Stock Up - %d rule%s. Target = per eligible toon.",
        rule_count, rule_count == 1 and "" or "s"))
    draw_stock_view()
end

function M.draw_stock()
    return diag.time("ui.stock.draw", draw_stock_body)
end

function M.tick()
    if stock_board_state.pending_key then
        diag.time("stock.board_build", stock_build_pending_board)
    end
end

return M
