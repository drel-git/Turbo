-- TurboGear/tabs/worn.lua
-- Augs tab: worn gear + installed augment view for one character, Group, or E3.

local ImGui = require('ImGui')
local theme = require('theme')
local Theme, col_text, themed_button, toggle_button = theme.Theme, theme.col_text, theme.themed_button, theme.toggle_button
local cfg = require('config')
local Settings, SaveSettings = cfg.Settings, cfg.SaveSettings
local items = require('items')
local grouped_slots = items.grouped_slots
local views = require('views')
local Engine = require('engine').Engine
local item_actions = require('item_actions')

local M = {}
local suggest_tab
local function open_suggestions(target_key, slot_id)
    if not suggest_tab then suggest_tab = require('tabs.suggestions') end
    suggest_tab.open_for(target_key, slot_id, { sortUpgrades = true, overview = false })
end

local MODE_OPTIONS = {
    { key = "single", label = "Character" },
    { key = "group",  label = "Group" },
    { key = "e3",     label = "E3 Online" },
}

local function mode_label()
    local cur = Settings.augsViewMode or "single"
    for _, opt in ipairs(MODE_OPTIONS) do if opt.key == cur then return opt.label end end
    return "Character"
end

local function draw_mode_picker()
    ImGui.Text("Viewing:"); ImGui.SameLine(); ImGui.SetNextItemWidth(120.0)
    if ImGui.BeginCombo("##augs_mode", mode_label()) then
        for _, opt in ipairs(MODE_OPTIONS) do
            if ImGui.Selectable(opt.label .. "##augs_mode_" .. opt.key, Settings.augsViewMode == opt.key) then
                Settings.augsViewMode = opt.key
                SaveSettings()
            end
        end
        ImGui.EndCombo()
    end
end

local function draw_character_picker()
    Settings.augsViewKey = views.draw_source_picker("##augs_source", Settings.augsViewKey or "__self__", 240.0)
end

local function source_keys()
    local mode = Settings.augsViewMode or "single"
    if mode == "group" then return views.scoped_source_keys("group") end
    if mode == "e3" then return views.scoped_source_keys("e3") end
    local key = views.validate_source_key(Settings.augsViewKey or "__self__")
    Settings.augsViewKey = key
    return { key }
end

local function slot_item(snap, slot_id)
    return views.index_equipped(snap)[slot_id]
end

local function render_aug_lines(item)
    if not item then views.blank_cell(); return end
    if not item.augs or #item.augs == 0 then views.placeholder("No sockets"); return end
    local shown = 0
    for _, a in ipairs(item.augs) do
        if not views.aug_visible(a) then goto continue_aug end
        shown = shown + 1
        if a.empty then
            col_text(Theme.emptySocket or Theme.gold, string.format("S%d T%d", tonumber(a.index) or 0, tonumber(a.type) or 0))
        else
            col_text(Theme.socket or Theme.dim, string.format("S%d T%d:", tonumber(a.index) or 0, tonumber(a.type) or 0)); ImGui.SameLine()
            item_actions.draw_name(a.name or "?", Theme.aug or Theme.green, "worn_aug_" .. tostring(item.id or "") .. "_" .. tostring(a.index or ""), a.id)
        end
        ::continue_aug::
    end
    if shown == 0 then views.placeholder("T20/30 hidden") end
end

local function render_compact_cell(item)
    if not item then views.blank_cell(); return end
    item_actions.draw_name(item.name or "?", Theme.item, "worn_item_" .. tostring(item.slotid or "") .. "_" .. tostring(item.id or ""), item.id)
    render_aug_lines(item)
end

local function draw_single(snap, source_key)
    local map = views.index_equipped(snap)
    if views.begin_scroll_table("AugsSingleTable", 4, views.scroll_table_flags(), 8.0, 220.0) then
        ImGui.TableSetupColumn("Slot", ImGuiTableColumnFlags.WidthFixed, 100.0)
        ImGui.TableSetupColumn("Item Name", ImGuiTableColumnFlags.WidthStretch, 2.0)
        ImGui.TableSetupColumn("Augmentations", ImGuiTableColumnFlags.WidthStretch, 3.0)
        ImGui.TableSetupColumn("Action", ImGuiTableColumnFlags.WidthFixed, 72.0)
        pcall(function() ImGui.TableSetupScrollFreeze(0, 1) end)
        views.table_headers_centered({ "Slot", "Item Name", "Augmentations", "Action" })
        for _, group in ipairs(grouped_slots()) do
            views.draw_section_row(group.label, 4)
            for _, slot in ipairs(group.slots or {}) do
                ImGui.TableNextRow()
                ImGui.TableSetColumnIndex(0); col_text(Theme.slot, slot.label)
                local it = map[slot.id]
                ImGui.TableSetColumnIndex(1)
                if it then item_actions.draw_name(it.name, Theme.item, "worn_single_item_" .. tostring(slot.id), it.id) else views.blank_cell() end
                ImGui.TableSetColumnIndex(2)
                render_aug_lines(it)
                ImGui.TableSetColumnIndex(3)
                if themed_button("Suggest##worn_suggest_" .. tostring(slot.id), Theme.blue) then
                    open_suggestions(source_key or Settings.augsViewKey or "__self__", slot.id)
                end
            end
        end
        ImGui.EndTable()
    end
end

local function draw_roster(keys)
    local snaps = {}
    for _, key in ipairs(keys) do snaps[key] = views.source_snapshot(key) end
    local cols = 1 + #keys
    if views.begin_scroll_table("AugsRosterTable", cols, views.scroll_table_flags(), 8.0, 220.0) then
        ImGui.TableSetupColumn("Slot", ImGuiTableColumnFlags.WidthFixed, 118.0)
        for _, key in ipairs(keys) do
            ImGui.TableSetupColumn("##augs_col_" .. tostring(key), ImGuiTableColumnFlags.WidthStretch, 1.4)
        end
        pcall(function() ImGui.TableSetupScrollFreeze(1, 1) end)
        views.draw_roster_header_row("Slot", keys)
        for _, group in ipairs(grouped_slots()) do
            views.draw_section_row(group.label, cols)
            for _, slot in ipairs(group.slots or {}) do
                ImGui.TableNextRow()
                ImGui.TableSetColumnIndex(0); col_text(Theme.slot, slot.label)
                for cidx, key in ipairs(keys) do
                    ImGui.TableSetColumnIndex(cidx)
                    render_compact_cell(slot_item(snaps[key], slot.id))
                end
            end
        end
        ImGui.EndTable()
    end
end

function M.draw()
    local st = require('state')
    if not (st.lean and st.lean()) then
        Engine.request_all(false)
    end
    draw_mode_picker()
    if (Settings.augsViewMode or "single") == "single" then
        ImGui.SameLine()
        draw_character_picker()
    end
    ImGui.SameLine()
    if toggle_button(Settings.hideOrnament and "Show T20/30" or "Hide T20/30", not Settings.hideOrnament) then
        Settings.hideOrnament = not Settings.hideOrnament
        SaveSettings()
    end
    ImGui.Spacing()

    local keys = source_keys()
    if #keys == 0 then col_text(Theme.amber, "No characters match this view yet."); return end
    if #keys == 1 then
        local snap = views.source_snapshot(keys[1])
        if snap then draw_single(snap, keys[1]) else col_text(Theme.amber, "No data yet - waiting for sync.") end
    else
        draw_roster(keys)
    end
end

return M
