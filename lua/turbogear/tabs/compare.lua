-- TurboGear/tabs/compare.lua
-- Compare tab: characters side-by-side, worn vs loadout list, or list vs list.

local ImGui = require('ImGui')
local theme = require('theme')
local Theme, col_text, toggle_button = theme.Theme, theme.col_text, theme.toggle_button
local grouped_slots = require('items').grouped_slots
local views = require('views')
local cfg = require('config')
local Settings, SaveSettings = cfg.Settings, cfg.SaveSettings
local item_actions = require('item_actions')
local loadout = require('loadout')
local stat_defs = require('stat_defs')

local M = {}

local COMPARE_MODES = {
    { key = "chars", label = "Character vs Character" },
    { key = "worn_list", label = "Worn vs List" },
    { key = "list_list", label = "List vs List" },
}

local function mode_label(key)
    for _, opt in ipairs(COMPARE_MODES) do
        if opt.key == key then return opt.label end
    end
    return COMPARE_MODES[1].label
end

local function ensure_defaults()
    Settings.compareMode = Settings.compareMode or "chars"
    Settings.compareListKey = Settings.compareListKey or ""
    Settings.compareListKey2 = Settings.compareListKey2 or ""
end

local function aug_signature(item)
    if not item then return "" end
    local parts = { item.name or "" }
    for _, a in ipairs(item.augs or {}) do
        if not views.aug_visible(a) then goto continue_aug end
        parts[#parts+1] = string.format("%s:%s:%s", tostring(a.index or ""), tostring(a.type or ""), tostring(a.name or ""))
        ::continue_aug::
    end
    return table.concat(parts, "|")
end

local function stat_signature(item)
    if not item or type(item.stats) ~= "table" then return "" end
    local parts = {}
    for _, def in ipairs(stat_defs.stats) do
        local v = tonumber(item.stats[def.key]) or 0
        if v ~= 0 then parts[#parts+1] = def.key .. "=" .. tostring(v) end
    end
    return table.concat(parts, "|")
end

local function slot_changed(i1, i2, mode)
    if mode == "chars" then
        return aug_signature(i1) ~= aug_signature(i2)
    end
    return aug_signature(i1) ~= aug_signature(i2) or stat_signature(i1) ~= stat_signature(i2)
end

local function resolve_side_snapshots(mode)
    if mode == "worn_list" then
        local worn = views.source_snapshot(Settings.compareKey1 or "__self__")
        local list_id = Settings.compareListKey or loadout.selected_list_id()
        Settings.compareListKey = list_id
        local list_snap = list_id ~= "" and loadout.build_snapshot(list_id) or nil
        return worn, list_snap, Settings.compareKey1 or "__self__", loadout.list_key(list_id)
    end
    if mode == "list_list" then
        local list1 = Settings.compareListKey or loadout.selected_list_id()
        local list2 = Settings.compareListKey2 or list1
        Settings.compareListKey = list1
        Settings.compareListKey2 = list2
        return loadout.build_snapshot(list1), loadout.build_snapshot(list2),
            loadout.list_key(list1), loadout.list_key(list2)
    end
    return views.source_snapshot(Settings.compareKey1 or "__self__"),
        views.source_snapshot(Settings.compareKey2 or "__self__"),
        Settings.compareKey1 or "__self__",
        Settings.compareKey2 or "__self__"
end

local function draw_mode_picker()
    ensure_defaults()
    ImGui.Text("Mode:")
    ImGui.SameLine()
    ImGui.SetNextItemWidth(190.0)
    if ImGui.BeginCombo("##cmp_mode", mode_label(Settings.compareMode)) then
        for _, opt in ipairs(COMPARE_MODES) do
            if ImGui.Selectable(opt.label .. "##cmp_mode_" .. opt.key, Settings.compareMode == opt.key) then
                Settings.compareMode = opt.key
                SaveSettings()
            end
        end
        ImGui.EndCombo()
    end
end

local function draw_source_controls(mode)
    if mode == "worn_list" then
        ImGui.Text("Worn:"); ImGui.SameLine()
        local next1 = views.draw_source_picker("##cmp1", Settings.compareKey1 or "__self__", 180.0)
        if next1 ~= Settings.compareKey1 then Settings.compareKey1 = next1; SaveSettings() end
        ImGui.SameLine(); ImGui.Text("  vs  "); ImGui.SameLine()
        ImGui.Text("List:"); ImGui.SameLine()
        local old = Settings.compareListKey or ""
        Settings.compareListKey = loadout.draw_list_picker("##cmp_list", old ~= "" and old or loadout.selected_list_id(), 180.0)
        if Settings.compareListKey ~= old then SaveSettings() end
        return
    end
    if mode == "list_list" then
        ImGui.Text("List A:"); ImGui.SameLine()
        local old1 = Settings.compareListKey or ""
        Settings.compareListKey = loadout.draw_list_picker("##cmp_list_a", old1 ~= "" and old1 or loadout.selected_list_id(), 180.0)
        if Settings.compareListKey ~= old1 then SaveSettings() end
        ImGui.SameLine(); ImGui.Text("  vs  "); ImGui.SameLine()
        ImGui.Text("List B:"); ImGui.SameLine()
        local old2 = Settings.compareListKey2 or ""
        Settings.compareListKey2 = loadout.draw_list_picker("##cmp_list_b", old2 ~= "" and old2 or Settings.compareListKey, 180.0)
        if Settings.compareListKey2 ~= old2 then SaveSettings() end
        return
    end

    local peer_keys = views.source_keys(false)
    if Settings.compareKey2 == nil then Settings.compareKey2 = peer_keys[1] or "__self__" end
    ImGui.Text("Character 1:"); ImGui.SameLine()
    local next1 = views.draw_source_picker("##cmp1", Settings.compareKey1 or "__self__", 180.0)
    if next1 ~= Settings.compareKey1 then Settings.compareKey1 = next1; SaveSettings() end
    ImGui.SameLine(); ImGui.Text("  vs  "); ImGui.SameLine()
    local next2 = views.draw_source_picker("##cmp2", Settings.compareKey2 or "__self__", 180.0)
    if next2 ~= Settings.compareKey2 then Settings.compareKey2 = next2; SaveSettings() end
end

local function draw_compare_deltas(s1, s2, mode)
    if mode == "chars" then return end
    if not s1 or not s2 then return end
    local left = mode == "worn_list" and "Worn" or "List A"
    local right = mode == "worn_list" and "List" or "List B"
    loadout.draw_compare_deltas(s1, s2, {
        left = left,
        right = right,
        changes_only = true,
    })
end

function M.draw()
    ensure_defaults()
    local mode = Settings.compareMode or "chars"
    draw_mode_picker()
    ImGui.SameLine()
    draw_source_controls(mode)
    ImGui.SameLine()
    local diff_only = Settings.compareDiffOnly ~= false
    local rv1, rv2 = ImGui.Checkbox("Differences Only##cmpdiff", diff_only)
    local new_diff, changed = diff_only, false
    if type(rv2) == "boolean" then new_diff, changed = rv1, rv2 elseif type(rv1) == "boolean" and rv1 ~= diff_only then new_diff, changed = rv1, true end
    if changed then Settings.compareDiffOnly = new_diff and true or false; SaveSettings(); diff_only = Settings.compareDiffOnly ~= false end
    ImGui.SameLine()
    if toggle_button(Settings.hideOrnament and "Show T20/30##cmp_t20" or "Hide T20/30##cmp_t20", not Settings.hideOrnament) then
        Settings.hideOrnament = not Settings.hideOrnament
        SaveSettings()
    end
    ImGui.Separator()

    local s1, s2, key1, key2 = resolve_side_snapshots(mode)
    if not s1 or not s2 then col_text(Theme.amber, "Waiting for data on one or both sides."); return end

    local list_id_1 = loadout.is_list_key(key1) and loadout.list_id_from_key(key1) or nil
    local list_id_2 = loadout.is_list_key(key2) and loadout.list_id_from_key(key2) or nil
    local m1 = list_id_1 and loadout.index_equipped(s1) or views.index_equipped(s1)
    local m2 = list_id_2 and loadout.index_equipped(s2) or views.index_equipped(s2)

    if views.begin_scroll_table("Cmp", 5, views.scroll_table_flags(), 8.0, 220.0) then
        ImGui.TableSetupColumn("Slot", ImGuiTableColumnFlags.WidthFixed, 95.0)
        ImGui.TableSetupColumn("##cmp1_item", ImGuiTableColumnFlags.WidthStretch, 2.0)
        ImGui.TableSetupColumn("##cmp1_augs", ImGuiTableColumnFlags.WidthStretch, 2.5)
        ImGui.TableSetupColumn("##cmp2_item", ImGuiTableColumnFlags.WidthStretch, 2.0)
        ImGui.TableSetupColumn("##cmp2_augs", ImGuiTableColumnFlags.WidthStretch, 2.5)
        pcall(function() ImGui.TableSetupScrollFreeze(1, 1) end)
        views.draw_compare_header_row(key1, key2)
        for _, group in ipairs(grouped_slots()) do
            views.draw_section_row(group.label, 5)
            for _, slot in ipairs(group.slots or {}) do
                local i1, i2 = m1[slot.id], m2[slot.id]
                local different = slot_changed(i1, i2, mode)
                if (not diff_only) or different then
                    ImGui.TableNextRow()
                    ImGui.TableSetColumnIndex(0); col_text(different and Theme.amber or Theme.slot, slot.label)
                    ImGui.TableSetColumnIndex(1)
                    if i1 then
                        local color = i1.unresolved and Theme.amber or Theme.item
                        item_actions.draw_name(i1.name, color, "cmp_i1_" .. tostring(slot.id), i1.id)
                    else views.blank_cell() end
                    ImGui.TableSetColumnIndex(2); if i1 then views.render_item_augs(i1, list_id_1, "cmp1_" .. tostring(slot.id) .. "_") else views.blank_cell() end
                    ImGui.TableSetColumnIndex(3)
                    if i2 then
                        local color = i2.unresolved and Theme.amber or Theme.item
                        item_actions.draw_name(i2.name, color, "cmp_i2_" .. tostring(slot.id), i2.id)
                    else views.blank_cell() end
                    ImGui.TableSetColumnIndex(4); if i2 then views.render_item_augs(i2, list_id_2, "cmp2_" .. tostring(slot.id) .. "_") else views.blank_cell() end
                end
            end
        end
        ImGui.EndTable()
    end

    draw_compare_deltas(s1, s2, mode)
    if mode ~= "chars" then
        col_text(Theme.dim, "Loadout augs: right-click an aug -> Move to Socket. Add with Group=Aug, Slot=host item, Socket=1-6 in Setup.")
    end
end

function M.open_worn_vs_list(list_id)
    list_id = tostring(list_id or "")
    if list_id == "" then list_id = loadout.selected_list_id() or "" end
    Settings.mainTab = "upgrade"
    Settings.upgradeTab = "compare"
    Settings.compareMode = "worn_list"
    Settings.compareKey1 = Settings.compareKey1 or "__self__"
    Settings.compareListKey = list_id
    if list_id ~= "" then Settings.bisSelectedList = list_id end
    SaveSettings()
end

function M.open_list_vs_list(list_id)
    list_id = tostring(list_id or "")
    if list_id == "" then list_id = loadout.selected_list_id() or "" end
    Settings.mainTab = "upgrade"
    Settings.upgradeTab = "compare"
    Settings.compareMode = "list_list"
    Settings.compareListKey = list_id
    Settings.compareListKey2 = Settings.compareListKey2 or list_id
    if list_id ~= "" then Settings.bisSelectedList = list_id end
    SaveSettings()
end

return M
