-- TurboGear/tabs/empty.lua
-- Empty Slots tab: unfilled sockets and empty equip slots for the selected
-- source. Skips ornament/special socket types (20/30) when hideOrnament is on.

local ImGui = require('ImGui')
local theme = require('theme')
local Theme, col_text, themed_button, toggle_button = theme.Theme, theme.col_text, theme.themed_button, theme.toggle_button
local segmented_text = theme.segmented_text
local cfg = require('config')
local Settings, SaveSettings = cfg.Settings, cfg.SaveSettings
local items = require('items')
local grouped_slots, is_skippable_socket = items.grouped_slots, items.is_skippable_socket
local views = require('views')
local item_actions = require('item_actions')

local M = {}
local suggest_tab
local function open_suggestions(target_key, slot_id)
    if not suggest_tab then suggest_tab = require('tabs.suggestions') end
    suggest_tab.open_for(target_key, slot_id, { sortUpgrades = true, overview = false })
end

local function open_aug_suggestions(target_key, host_item, host_id, slot_id, socket_index, socket_type)
    if not suggest_tab then suggest_tab = require('tabs.suggestions') end
    suggest_tab.open_for_aug(target_key, host_item, host_id, slot_id, socket_index, socket_type, { overview = false })
end

local empty_cache, empty_key = nil, nil
local MODE_OPTIONS = {
    { key = "single", label = "Character" },
    { key = "group", label = "Group" },
    { key = "e3", label = "E3 Online" },
}

-- Force a rebuild of the cached empty-slot list (called by Setup when the
-- ornament toggle changes there).
function M.invalidate() empty_key = nil end

local function mode_label()
    for _, opt in ipairs(MODE_OPTIONS) do if opt.key == Settings.emptyViewMode then return opt.label end end
    return "Character"
end

local function draw_mode_picker()
    ImGui.Text("Viewing:"); ImGui.SameLine(); ImGui.SetNextItemWidth(110.0)
    if ImGui.BeginCombo("##empty_mode", mode_label()) then
        for _, opt in ipairs(MODE_OPTIONS) do
            if ImGui.Selectable(opt.label .. "##empty_mode_" .. opt.key, Settings.emptyViewMode == opt.key) then
                Settings.emptyViewMode = opt.key
                SaveSettings()
                empty_key = nil
            end
        end
        ImGui.EndCombo()
    end
end

local function build_empty(snap, actionable_only)
    local rows = {}
    local map = views.index_equipped(snap)
    for _, group in ipairs(grouped_slots()) do
        for _, slot in ipairs(group.slots or {}) do
            local it = map[slot.id]
            if not it then
                if not actionable_only then
                    rows[#rows+1] = { slot = slot.label, slot_id = slot.id, socket = nil, atype = nil, kind = "slot", item = nil, item_id = nil }
                end
            else
                for _, a in ipairs(it.augs or {}) do
                    if a.empty and not is_skippable_socket(a.type) then
                        rows[#rows+1] = { slot = slot.label, slot_id = slot.id, socket = a.index, atype = a.type, kind = "aug", item = it.name, item_id = it.id }
                    end
                end
            end
        end
    end
    return rows
end

local function grouped_empty_rows(rows)
    local out, by_key = {}, {}
    for _, e in ipairs(rows or {}) do
        if e.kind == "slot" then
            out[#out+1] = { kind = "slot", slot = e.slot }
        else
            local key = tostring(e.slot or "") .. "\1" .. tostring(e.item or "")
            local g = by_key[key]
            if not g then
                g = { kind = "aug", slot = e.slot, slot_id = e.slot_id, item = e.item, item_id = e.item_id, sockets = {} }
                by_key[key] = g
                out[#out+1] = g
            end
            g.sockets[#g.sockets+1] = { socket = e.socket, atype = e.atype }
        end
    end
    return out
end

local function draw_socket_lines(sockets)
    for _, s in ipairs(sockets or {}) do
        segmented_text({
            { text = "S" .. tostring(s.socket or "?"), color = Theme.socket or Theme.dim },
            { text = "  T" .. tostring(s.atype or "?"), color = Theme.emptySocket or Theme.gold },
        })
    end
end

local function draw_empty_group_cell(list, suffix)
    local groups = grouped_empty_rows(list)
    for i, g in ipairs(groups) do
        if g.kind == "slot" then
            views.blank_cell()
        else
            item_actions.draw_name(g.item or "Equipped item", Theme.item, tostring(suffix or "empty") .. "_host_" .. tostring(i), g.item_id)
            draw_socket_lines(g.sockets)
        end
    end
end

local function draw_single(snap, dname)
    local actionable_only = Settings.emptyActionableOnly ~= false
    local key = "single|" .. tostring(Settings.hideOrnament) .. "|" .. tostring(actionable_only) .. "|" .. tostring(snap.inventoryUpdated or snap.updated) .. "|" .. tostring(dname or "")
    if empty_key ~= key then
        empty_cache = build_empty(snap, actionable_only)
        empty_key = key
    end
    if #empty_cache == 0 then
        col_text(Theme.green, actionable_only and ("No actionable empty sockets for " .. (dname or "this character") .. ".") or ("All sockets filled for " .. (dname or "this character") .. "."))
        return
    end
    if actionable_only then
        col_text(Theme.amber, string.format("%d empty socket %s", #empty_cache, #empty_cache == 1 and "row" or "rows"))
    else
        col_text(Theme.amber, string.format("%d empty/no-item %s", #empty_cache, #empty_cache == 1 and "row" or "rows"))
    end
    local grouped, by_slot = grouped_empty_rows(empty_cache), {}
    for _, e in ipairs(grouped) do
        by_slot[e.slot] = by_slot[e.slot] or {}
        by_slot[e.slot][#by_slot[e.slot]+1] = e
    end
    if views.begin_scroll_table("EmptyTable", 4, views.scroll_table_flags(), 8.0, 220.0) then
        ImGui.TableSetupColumn("Slot", ImGuiTableColumnFlags.WidthFixed, 120.0)
        ImGui.TableSetupColumn("Item", ImGuiTableColumnFlags.WidthStretch, 2.0)
        ImGui.TableSetupColumn("Empty Sockets", ImGuiTableColumnFlags.WidthStretch, 1.2)
        ImGui.TableSetupColumn("Action", ImGuiTableColumnFlags.WidthFixed, 96.0)
        pcall(function() ImGui.TableSetupScrollFreeze(0, 1) end)
        views.table_headers_centered({ "Slot", "Item", "Empty Sockets", "Action" })
        for _, group in ipairs(grouped_slots()) do
            local group_has_rows = false
            for _, slot in ipairs(group.slots or {}) do
                if by_slot[slot.label] then group_has_rows = true; break end
            end
            if group_has_rows then
                views.draw_section_row(group.label, 4)
                for _, slot in ipairs(group.slots or {}) do
                    for _, e in ipairs(by_slot[slot.label] or {}) do
                        ImGui.TableNextRow()
                        ImGui.TableSetColumnIndex(0); col_text(Theme.slot, e.slot)
                        ImGui.TableSetColumnIndex(1)
                        if e.item then item_actions.draw_name(e.item, Theme.item, "empty_single_item_" .. tostring(e.slot or ""), e.item_id) else views.blank_cell() end
                        ImGui.TableSetColumnIndex(2)
                        if e.kind == "slot" then
                            views.blank_cell()
                        else
                            draw_socket_lines(e.sockets)
                        end
                        ImGui.TableSetColumnIndex(3)
                        if e.kind == "slot" then
                            if themed_button("Suggest##empty_suggest_" .. tostring(slot.id), Theme.blue) then
                                open_suggestions(Settings.emptyViewKey or "__self__", slot.id)
                            end
                        elseif e.kind == "aug" then
                            for si, s in ipairs(e.sockets or {}) do
                                local btn_id = string.format("empty_findaug_%s_%d_%d_%d", tostring(e.slot_id or slot.id), tostring(e.item_id or 0), s.socket or 0, s.atype or 0)
                                if themed_button(string.format("Find S%d##%s", s.socket or 0, btn_id), Theme.steel) then
                                    open_aug_suggestions(
                                        Settings.emptyViewKey or "__self__",
                                        e.item,
                                        e.item_id,
                                        e.slot_id or slot.id,
                                        s.socket,
                                        s.atype
                                    )
                                end
                            end
                        else
                            views.blank_cell()
                        end
                    end
                end
            end
        end
        ImGui.EndTable()
    end
end

local function draw_roster(scope)
    local keys = views.scoped_source_keys(scope)
    local rows_by_key, slot_order, seen = {}, {}, {}
    for _, key in ipairs(keys) do
        local snap = views.source_snapshot(key)
        rows_by_key[key] = build_empty(snap, Settings.emptyActionableOnly ~= false)
        for _, e in ipairs(rows_by_key[key]) do
            if not seen[e.slot] then seen[e.slot] = true; slot_order[#slot_order+1] = e.slot end
        end
    end
    if #keys == 0 then col_text(Theme.amber, "No characters match this view yet."); return end
    if #slot_order == 0 then
        col_text(Theme.green, (Settings.emptyActionableOnly ~= false) and "No actionable empty sockets in this view." or "No empty-slot rows in this view.")
        return
    end
    if views.begin_scroll_table("EmptyRosterTable", 1 + #keys, views.scroll_table_flags(), 8.0, 220.0) then
        ImGui.TableSetupColumn("Slot", ImGuiTableColumnFlags.WidthFixed, 115.0)
        for _, key in ipairs(keys) do
            ImGui.TableSetupColumn(views.roster_column_label(key), ImGuiTableColumnFlags.WidthStretch, 1.0)
        end
        pcall(function() ImGui.TableSetupScrollFreeze(1, 1) end)
        views.draw_roster_header_row("Slot", keys)
        for _, group in ipairs(grouped_slots()) do
            local group_has_rows = false
            for _, slot in ipairs(group.slots or {}) do
                if seen[slot.label] then group_has_rows = true; break end
            end
            if group_has_rows then
                views.draw_section_row(group.label, 1 + #keys)
                for _, slot in ipairs(group.slots or {}) do
                    if seen[slot.label] then
                        ImGui.TableNextRow()
                        ImGui.TableSetColumnIndex(0); col_text(Theme.slot, slot.label)
                        for cidx, key in ipairs(keys) do
                            ImGui.TableSetColumnIndex(cidx)
                            local list = {}
                            for _, e in ipairs(rows_by_key[key] or {}) do if e.slot == slot.label then list[#list+1] = e end end
                            if #list == 0 then views.placeholder("-") else
                                draw_empty_group_cell(list, "empty_roster_" .. tostring(cidx) .. "_" .. tostring(slot.label))
                            end
                        end
                    end
                end
            end
        end
        ImGui.EndTable()
    end
    col_text(Theme.dim, "Empty sockets are gold. Right-click item names for Inspect, Alla, or Copy Name.")
end

function M.draw()
    if themed_button("Refresh", Theme.blue) then empty_key = nil end
    ImGui.SameLine()
    if toggle_button(Settings.hideOrnament and "Sockets: Hide T20/30##empty_t2030" or "Sockets: Show T20/30##empty_t2030", not Settings.hideOrnament) then
        Settings.hideOrnament = not Settings.hideOrnament; SaveSettings(); empty_key = nil
    end
    ImGui.SameLine()
    local actionable_only = Settings.emptyActionableOnly ~= false
    if toggle_button(actionable_only and "Filter: Useful Empty##empty_actionable" or "Filter: All Empty##empty_actionable", actionable_only) then
        Settings.emptyActionableOnly = not actionable_only
        SaveSettings()
        empty_key = nil
    end
    ImGui.Separator()
    draw_mode_picker()
    local snap, _, dname
    if Settings.emptyViewMode == "single" then
        ImGui.SameLine()
        local old = Settings.emptyViewKey
        Settings.emptyViewKey = views.draw_source_picker("##empty_source", Settings.emptyViewKey or "__self__", 220.0)
        if old ~= Settings.emptyViewKey then SaveSettings() end
        snap, _, dname = views.source_snapshot(Settings.emptyViewKey)
    else
        snap = nil
    end
    ImGui.Spacing()
    if Settings.emptyViewMode == "single" then
        if not snap then col_text(Theme.amber, "No data yet - waiting for sync."); return end
        draw_single(snap, dname)
    else
        draw_roster(Settings.emptyViewMode == "e3" and "e3" or "group")
    end
end

return M
