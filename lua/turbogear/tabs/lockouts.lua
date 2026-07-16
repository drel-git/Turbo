-- TurboGear/tabs/lockouts.lua
-- Main Lockouts tab: DZ timer roster + inline custom lockout editor.

local ImGui = require('ImGui')
local mq = require('mq')
local theme = require('theme')
local Theme, col_text, toggle_button, themed_button = theme.Theme, theme.col_text, theme.toggle_button, theme.themed_button
local cfg = require('config')
local Settings, SaveSettings = cfg.Settings, cfg.SaveSettings
local views = require('views')
local characters = require('characters')
local lockouts = require('lockouts')
local lockout_ref = require('references.lockouts')
local snapshot_mod = require('snapshot')
local Engine = require('engine').Engine

local M = {}

local lo_add_name = ""
local lo_add_lockout = ""
local lo_add_zone = ""
local lo_add_category = "Custom"
local lo_add_chars = {}   -- map of charname -> bool; empty = all characters
local lo_add_duration = ""
local lo_status = ""
local lo_dz_picker_entries = {}
local lo_show_advanced = false

local function seconds_to_duration_str(secs)
    secs = math.max(0, math.floor(tonumber(secs) or 0))
    local parts = {}
    local d = math.floor(secs / 86400); secs = secs % 86400
    local h = math.floor(secs / 3600);  secs = secs % 3600
    local m = math.floor(secs / 60);    secs = secs % 60
    if d > 0 then parts[#parts + 1] = d .. "d" end
    if h > 0 then parts[#parts + 1] = h .. "h" end
    if m > 0 then parts[#parts + 1] = m .. "m" end
    if secs > 0 and d == 0 then parts[#parts + 1] = secs .. "s" end
    return table.concat(parts, " ")
end
local show_add_panel = false

local function chars_combo_label(chars_map)
    local selected = {}
    for name, checked in pairs(chars_map) do
        if checked then selected[#selected + 1] = name end
    end
    table.sort(selected)
    if #selected == 0 then return "All characters" end
    return table.concat(selected, ", ")
end

local function load_entry_for_edit(e)
    lo_add_name     = e.name or ""
    lo_add_lockout  = e.lockout or ""
    lo_add_zone     = e.zone or ""
    lo_add_category = e.category or "Custom"
    lo_add_chars    = {}
    if type(e.characters) == "table" then
        for _, c in ipairs(e.characters) do lo_add_chars[c] = true end
    end
    -- Restore remaining manual timer for the local character
    local local_name = tostring(mq.TLO.Me and mq.TLO.Me.CleanName() or "")
    local manual_exp = e.manualTimers and local_name ~= "" and tonumber(e.manualTimers[local_name])
    lo_add_duration = (manual_exp and manual_exp > os.time())
        and seconds_to_duration_str(manual_exp - os.time()) or ""
    show_add_panel  = true
end

local function entry_hidden_key(cat, name)
    return tostring(cat) .. "\31" .. tostring(name)
end

local function is_entry_hidden(cat, name)
    local t = Settings.lockoutsHiddenEntries
    return type(t) == "table" and t[entry_hidden_key(cat, name)] == true
end

local function toggle_entry_hidden(cat, name)
    Settings.lockoutsHiddenEntries = type(Settings.lockoutsHiddenEntries) == "table"
        and Settings.lockoutsHiddenEntries or {}
    local key = entry_hidden_key(cat, name)
    if Settings.lockoutsHiddenEntries[key] then
        Settings.lockoutsHiddenEntries[key] = nil
    else
        Settings.lockoutsHiddenEntries[key] = true
    end
    SaveSettings()
end

local SCOPE_OPTIONS = {
    { key = "online", label = "Live Peers" },
    { key = "all", label = "All Cached" },
    { key = "group", label = "Group" },
    { key = "e3", label = "E3" },
    { key = "self", label = "Self" },
}

local function input_text_hint(id, hint, value)
    if ImGui.InputTextWithHint then
        local ok, rv = pcall(ImGui.InputTextWithHint, id, hint, value or "")
        if ok then return rv or "" end
    end
    return ImGui.InputText(id, value or "") or ""
end

local function table_col_text_centered(color, text, col_w)
    views.col_text_centered(color, text, col_w or column_width_now())
end

local function column_width_now()
    if ImGui.GetColumnWidth then
        local w = ImGui.GetColumnWidth()
        if type(w) == "table" then return tonumber(w.x or w[1]) end
        return tonumber(w)
    end
    return nil
end

local function draw_header_cell(snap, counts)
    local cc = views.class_color(snap and snap.class)
    local name = snap and snap.name or "?"
    local cls = views.class_abbrev(snap and snap.class)
    local w = column_width_now() or 96.0
    table_col_text_centered(cc, string.format("%s (%s)", name, cls), w)
    if counts then
        if counts.no_data then
            table_col_text_centered(Theme.dim, "no lockout data", w)
        else
            local locked, open = counts[1] or 0, counts[2] or 0
            table_col_text_centered(Theme.dim, string.format("%d locked / %d open", locked, open), w)
        end
    end
end

local function lockout_counts_for_snap(snap)
    if not lockouts.read_from_snap(snap) then return { no_data = true } end
    local locked, open = 0, 0
    for _, row in ipairs(lockouts.all_entries()) do
        local is_locked = select(1, lockouts.is_locked(snap, row.category, row.entry.name))
        if is_locked then locked = locked + 1 else open = open + 1 end
    end
    return { locked, open }
end

local function draw_lockout_cell(snap, category, entry)
    if not snap then
        ImGui.TextDisabled("-")
        return
    end
    if not lockouts.entry_applies_to(entry, snap.name) then
        ImGui.TextDisabled("-")
        return
    end
    local data = lockouts.read_from_snap(snap)
    if not data then
        col_text(Theme.amber, "?")
        if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
            ImGui.SetTooltip("No lockout data yet — Sync Now or wait for peer snapshot.")
        end
        return
    end
    local state = lockouts.cell_status(snap, category, entry.name)
    if state.locked then
        col_text(Theme.missing or Theme.brick, "Locked")
        if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
            ImGui.SetTooltip("Available in: " .. tostring(state.timer or "?"))
        end
    elseif state.status == "missing_custom" then
        col_text(Theme.online or Theme.green, "Open")
        if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
            ImGui.SetTooltip("No active lockout found — character hasn't done this yet or timer has expired.")
        end
    elseif state.status == "expired" then
        col_text(Theme.online or Theme.green, "Open")
        if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
            ImGui.SetTooltip("Cached timer expired.")
        end
    else
        col_text(Theme.online or Theme.green, "Open")
    end
end

local function draw_lockout_cell_compact(snap, category, entry)
    if not snap then
        ImGui.TextDisabled("-")
        return
    end
    if not lockouts.entry_applies_to(entry, snap.name) then
        views.col_text_centered(Theme.dim, "-", column_width_now())
        return
    end
    local data = lockouts.read_from_snap(snap)
    if not data then
        views.col_text_centered(Theme.amber, "?", column_width_now())
        if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
            ImGui.SetTooltip("No lockout data yet. Sync Now or wait for peer snapshot.")
        end
        return
    end
    local state = lockouts.cell_status(snap, category, entry.name)
    if state.locked then
        views.col_text_centered(Theme.missing or Theme.brick, "L", column_width_now())
        if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
            ImGui.SetTooltip("Locked\nAvailable in: " .. tostring(state.timer or "?"))
        end
    elseif state.status == "missing_custom" then
        views.col_text_centered(Theme.online or Theme.green, "O", column_width_now())
        if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
            ImGui.SetTooltip("No active lockout found — character hasn't done this yet or timer has expired.")
        end
    else
        views.col_text_centered(Theme.online or Theme.green, "O", column_width_now())
    end
end

local function category_collapsed(category)
    local t = Settings.lockoutsCollapsedCategories
    return type(t) == "table" and t[category or ""] == true
end

local function toggle_category(category)
    Settings.lockoutsCollapsedCategories = type(Settings.lockoutsCollapsedCategories) == "table" and Settings.lockoutsCollapsedCategories or {}
    category = tostring(category or "")
    Settings.lockoutsCollapsedCategories[category] = not Settings.lockoutsCollapsedCategories[category]
    SaveSettings()
end

local function entry_has_locked(keys, category, entry)
    for _, key in ipairs(keys or {}) do
        local snap = views.source_snapshot(key)
        if snap and select(1, lockouts.is_locked(snap, category, entry.name)) then return true end
    end
    return false
end

local function aggregate_counts(counts_by_key)
    local locked, open, missing = 0, 0, 0
    for _, c in pairs(counts_by_key or {}) do
        if c.no_data then
            missing = missing + 1
        else
            locked = locked + (c[1] or 0)
            open = open + (c[2] or 0)
        end
    end
    return locked, open, missing
end

local function draw_add_lockout_panel()
    if toggle_button(show_add_panel and "Add Lockout: ON" or "Add Lockout: OFF", show_add_panel) then
        show_add_panel = not show_add_panel
    end
    if not show_add_panel then return end

    -- Primary action row
    if themed_button("Pick from DZ window##lo_pick_dz", Theme.blue) then
        lo_dz_picker_entries = lockouts.read_dz_timers()
        ImGui.OpenPopup("##lo_dz_picker_popup")
    end
    ImGui.SameLine()
    if themed_button("Add all from DZ##lo_addall_main", Theme.blue) then
        local entries = lockouts.read_dz_timers()
        local added = 0
        for _, e in ipairs(entries) do
            if not lockouts.label_already_tracked(e.label) then
                lockouts.add_custom({ name = e.label, lockout = e.label })
                added = added + 1
            end
        end
        if added > 0 then
            snapshot_mod.invalidate()
            lockouts.invalidate_cache()
            lo_status = string.format("Added %d new lockout%s.", added, added == 1 and "" or "s")
        else
            lo_status = "All DZ timers are already tracked."
        end
    end
    ImGui.SameLine()
    if toggle_button(lo_show_advanced and "Advanced: ON##lo_adv" or "Advanced##lo_adv", lo_show_advanced) then
        lo_show_advanced = not lo_show_advanced
    end

    -- DZ picker popup
    if ImGui.BeginPopup and ImGui.BeginPopup("##lo_dz_picker_popup") then
        if #lo_dz_picker_entries == 0 then
            col_text(Theme.amber, "No timers found.")
            col_text(Theme.dim, "Open your Dynamic Zone window first.")
        else
            col_text(Theme.dim, lo_show_advanced and "Click to fill the form below:" or "Click to add immediately:")
            ImGui.Separator()
            for _, e in ipairs(lo_dz_picker_entries) do
                local already = lockouts.label_already_tracked(e.label)
                local row_label = e.timer ~= "" and string.format("%s  (%s)", e.label, e.timer) or e.label
                if already then
                    col_text(Theme.dim, row_label .. "  [tracked]")
                else
                    if ImGui.Selectable(row_label .. "##dz_pk_" .. e.label, false) then
                        if lo_show_advanced then
                            lo_add_lockout = e.label
                            if lo_add_name == "" then lo_add_name = e.label end
                            ImGui.CloseCurrentPopup()
                        else
                            local ok, err = lockouts.add_custom({ name = e.label, lockout = e.label })
                            if ok then
                                lo_status = string.format("Added '%s'.", e.label)
                                snapshot_mod.invalidate()
                                lockouts.invalidate_cache()
                                lo_dz_picker_entries = lockouts.read_dz_timers()
                            else
                                lo_status = err or "Could not add."
                            end
                        end
                    end
                end
            end
        end
        if ImGui.Button and ImGui.Button("Refresh##lo_dz_refresh") then
            lo_dz_picker_entries = lockouts.read_dz_timers()
        end
        ImGui.EndPopup()
    end

    -- Advanced form (manual entry + character scope + duration)
    if lo_show_advanced then
        col_text(Theme.dim, "Manual entry — or use Pick above to fill from DZ window.")
        ImGui.SetNextItemWidth(160.0)
        lo_add_name = input_text_hint("##lo_tab_name", "Display name", lo_add_name)
        ImGui.SameLine()
        ImGui.SetNextItemWidth(160.0)
        lo_add_lockout = input_text_hint("##lo_tab_lockout", "DZ timer label (exact)", lo_add_lockout)
        ImGui.SameLine()
        ImGui.SetNextItemWidth(110.0)
        lo_add_duration = input_text_hint("##lo_tab_duration", "Duration (e.g. 6d)", lo_add_duration)
        ImGui.SetNextItemWidth(160.0)
        lo_add_zone = input_text_hint("##lo_tab_zone", "Zone label (optional)", lo_add_zone)
        ImGui.SameLine()
        ImGui.SetNextItemWidth(120.0)
        lo_add_category = input_text_hint("##lo_tab_category", "Category", lo_add_category)
        ImGui.SameLine()
        ImGui.SetNextItemWidth(200.0)
        if ImGui.BeginCombo("##lo_tab_chars", chars_combo_label(lo_add_chars)) then
            if ImGui.Selectable("All characters##lo_chars_all", next(lo_add_chars) == nil) then
                lo_add_chars = {}
            end
            ImGui.Separator()
            local all_char_keys = views.scoped_source_keys("all", { include_offline_cache = true })
            for _, key in ipairs(all_char_keys) do
                local snap = views.source_snapshot(key)
                local cname = snap and snap.name or nil
                if cname and cname ~= "" then
                    local checked = lo_add_chars[cname] == true
                    local rv1, rv2 = ImGui.Checkbox(cname .. "##lo_char_" .. tostring(key), checked)
                    local new_checked = checked
                    if type(rv2) == "boolean" then new_checked = rv1
                    elseif type(rv1) == "boolean" then new_checked = rv1 end
                    if new_checked ~= checked then lo_add_chars[cname] = new_checked or nil end
                end
            end
            ImGui.EndCombo()
        end
        ImGui.SameLine()
        if themed_button("Add##lo_tab_add", Theme.blue) then
            local chars_arr = {}
            for cname, checked in pairs(lo_add_chars) do
                if checked then chars_arr[#chars_arr + 1] = cname end
            end
            table.sort(chars_arr)
            local ok, err = lockouts.add_custom({
                name = lo_add_name,
                lockout = lo_add_lockout,
                zone = lo_add_zone,
                category = lo_add_category,
                characters = #chars_arr > 0 and chars_arr or nil,
                manualDuration = lo_add_duration,
            })
            if ok then
                local scope_note = #chars_arr > 0 and (" (" .. table.concat(chars_arr, ", ") .. ")") or ""
                lo_status = string.format("Added '%s'%s.", lo_add_name, scope_note)
                lo_add_name = ""
                lo_add_lockout = ""
                lo_add_zone = ""
                lo_add_duration = ""
                lo_add_chars = {}
                snapshot_mod.invalidate()
                lockouts.invalidate_cache()
            else
                lo_status = err or "Could not add lockout."
            end
        end
    end

    if lo_status ~= "" then col_text(Theme.dim, lo_status) end

    -- Existing custom entries
    local custom_list = lockouts.load_custom()
    if #custom_list > 0 then
        ImGui.Separator()
        col_text(Theme.dim, "Existing custom lockouts:")
        local remove_idx, edit_idx = nil, nil
        for i, e in ipairs(custom_list) do
            if themed_button("x##lo_del_" .. i, Theme.missing or Theme.brick) then
                remove_idx = i
            end
            ImGui.SameLine()
            if themed_button("Edit##lo_edit_" .. i, Theme.blue) then
                edit_idx = i
            end
            ImGui.SameLine()
            local scope = (type(e.characters) == "table" and #e.characters > 0)
                and (" [" .. table.concat(e.characters, ", ") .. "]") or " [all]"
            col_text(Theme.slot or Theme.dim, (e.label ~= "" and e.label or e.name) .. scope)
        end
        if remove_idx then
            local removed_name = custom_list[remove_idx].name
            lockouts.remove_custom_at(remove_idx)
            snapshot_mod.invalidate()
            lockouts.invalidate_cache()
            lo_status = string.format("Removed '%s'.", removed_name)
        elseif edit_idx then
            local e = custom_list[edit_idx]
            load_entry_for_edit(e)
            lo_show_advanced = true
            lockouts.remove_custom_at(edit_idx)
            snapshot_mod.invalidate()
            lockouts.invalidate_cache()
            lo_status = string.format("Editing '%s' - update fields and click Add.", e.name)
        end
    end
    ImGui.Spacing()
end

local function scope_label()
    local cur = Settings.lockoutsRosterScope or "online"
    for _, opt in ipairs(SCOPE_OPTIONS) do
        if opt.key == cur then return opt.label end
    end
    return "Live Peers"
end

local SCOPE_OPTS = { include_offline_cache = true }

local function selected_keys_for_scope()
    return views.scoped_source_keys(Settings.lockoutsRosterScope or "online", SCOPE_OPTS)
end

local function key_in_scope(key, keys)
    for _, k in ipairs(keys or {}) do
        if k == key then return true end
    end
    return false
end

local function draw_scope_picker()
    ImGui.SetNextItemWidth(140.0)
    if ImGui.BeginCombo("##lockouts_scope", "Show: " .. scope_label()) then
        for _, opt in ipairs(SCOPE_OPTIONS) do
            if ImGui.Selectable(opt.label .. "##lockouts_scope_" .. opt.key, Settings.lockoutsRosterScope == opt.key) then
                Settings.lockoutsRosterScope = opt.key
                cfg.apply_linked_roster_scope(opt.key, "lockouts")
                if opt.key == "self" then
                    Settings.lockoutsViewKey = "__self__"
                elseif Settings.lockoutsViewKey ~= "__all__" then
                    local keys = views.scoped_source_keys(opt.key, SCOPE_OPTS)
                    if not key_in_scope(Settings.lockoutsViewKey, keys) then
                        Settings.lockoutsViewKey = "__all__"
                    end
                end
                SaveSettings()
            end
        end
        ImGui.EndCombo()
    end
    ImGui.SameLine()
    if toggle_button("Link Scope##lockouts_link_scope", Settings.syncRosterScopeAcrossTabs == true) then
        Settings.syncRosterScopeAcrossTabs = not (Settings.syncRosterScopeAcrossTabs == true)
        if Settings.syncRosterScopeAcrossTabs then
            cfg.apply_linked_roster_scope(Settings.lockoutsRosterScope or "online", "lockouts")
        end
        SaveSettings()
    end
end

local function draw_view_picker()
    local keys = selected_keys_for_scope()
    local cur = Settings.lockoutsViewKey or "__all__"
    if (Settings.lockoutsRosterScope or "online") == "self" then
        cur = "__self__"
    elseif cur == characters.VIEW_SELECTED then
        -- keep selected subset from Characters pill
    elseif cur ~= "__all__" then
        cur = views.validate_source_key(cur)
        if not key_in_scope(cur, keys) then cur = "__all__" end
    end

    local label = cur == "__all__" and "All Characters"
        or (cur == characters.VIEW_SELECTED and string.format("Selected (%d)", #characters.active_keys("lockouts", SCOPE_OPTS)))
        or views.source_label(cur)
    local changed = false
    ImGui.SetNextItemWidth(220.0)
    if ImGui.BeginCombo("##lockouts_view", "View: " .. label) then
        if (Settings.lockoutsRosterScope or "online") ~= "self" then
            if ImGui.Selectable("All Characters##lockouts_view_all", cur == "__all__") then
                cur = "__all__"
                changed = true
            end
        end
        for _, key in ipairs(keys) do
            local snap = views.source_snapshot(key)
            local item_label = snap and (snap.name or views.source_label(key)) or views.source_label(key)
            if ImGui.Selectable(item_label .. "##lockouts_view_" .. tostring(key), cur == key) then
                cur = key
                changed = true
            end
        end
        ImGui.EndCombo()
    end
    if changed or Settings.lockoutsViewKey ~= cur then
        Settings.lockoutsViewKey = cur
        SaveSettings()
    end
    return cur, keys
end

local function draw_scope_row()
    if Settings.showCharactersPill == true then
        local scoped = characters.source_keys("lockouts", SCOPE_OPTS)
        local view = characters.get_view_key("lockouts")
        return view, scoped
    end
    draw_scope_picker()
    ImGui.SameLine()
    return draw_view_picker()
end

function M.draw()
    draw_add_lockout_panel()
    local view_key, scoped_keys = draw_scope_row()
    ImGui.SameLine()
    if toggle_button(Settings.lockoutsLockedOnly and "Locked Only: ON##lo_locked_only" or "Locked Only: OFF##lo_locked_only", Settings.lockoutsLockedOnly == true) then
        Settings.lockoutsLockedOnly = not (Settings.lockoutsLockedOnly == true)
        SaveSettings()
    end
    ImGui.SameLine()
    if toggle_button(Settings.lockoutsCompact and "Compact: ON##lo_compact" or "Compact: OFF##lo_compact", Settings.lockoutsCompact == true) then
        Settings.lockoutsCompact = not (Settings.lockoutsCompact == true)
        SaveSettings()
    end
    ImGui.SameLine()
    if toggle_button(Settings.lockoutsShowHidden and "Show Hidden: ON##lo_showhidden" or "Show Hidden: OFF##lo_showhidden", Settings.lockoutsShowHidden == true) then
        Settings.lockoutsShowHidden = not (Settings.lockoutsShowHidden == true)
        SaveSettings()
    end
    ImGui.Spacing()

    if (Settings.lockoutsRosterScope or "online") == "self" then
        view_key = "__self__"
    end

    local keys = scoped_keys or selected_keys_for_scope()
    if view_key == characters.VIEW_SELECTED then
        keys = characters.active_keys("lockouts", SCOPE_OPTS)
    elseif view_key ~= "__all__" then
        keys = { view_key }
    end
    if #keys == 0 then
        col_text(Theme.amber, "No characters in this scope.")
        return
    end

    local counts_by_key = {}
    for _, key in ipairs(keys) do
        local snap = views.source_snapshot(key)
        counts_by_key[key] = lockout_counts_for_snap(snap)
    end
    local total_locked, total_open, missing_snaps = aggregate_counts(counts_by_key)
    col_text(Theme.dim, string.format("%d locked / %d open across %d character%s%s",
        total_locked, total_open, #keys, #keys == 1 and "" or "s",
        missing_snaps > 0 and string.format(" | %d missing snapshot%s", missing_snaps, missing_snaps == 1 and "" or "s") or ""))

    local cols = 1 + #keys
    local extra = 0
    if Settings.lockoutsCompact and ImGuiTableFlags and ImGuiTableFlags.ScrollX then
        extra = ImGuiTableFlags.ScrollX
    end
    if views.begin_scroll_table("LockoutsMain", cols, views.scroll_table_flags(extra), 52.0, 220.0) then
        local ok, err = pcall(function()
            ImGui.TableSetupColumn("Lockout", ImGuiTableColumnFlags.WidthFixed, Settings.lockoutsCompact and 220.0 or 260.0)
            for _, key in ipairs(keys) do
                if Settings.lockoutsCompact then
                    ImGui.TableSetupColumn("##lock_col_" .. tostring(key), ImGuiTableColumnFlags.WidthFixed, 74.0)
                else
                    ImGui.TableSetupColumn("##lock_col_" .. tostring(key), ImGuiTableColumnFlags.WidthStretch, 1.0)
                end
            end
            views.setup_scroll_freeze("LockoutsMain", 1, 1)
            ImGui.TableNextRow()
            ImGui.TableSetColumnIndex(0)
            col_text(Theme.header or Theme.item, "Lockout")
            for cidx, key in ipairs(keys) do
                ImGui.TableSetColumnIndex(cidx)
                local snap = views.source_snapshot(key)
                draw_header_cell(snap, counts_by_key[key])
            end

            for _, cat in ipairs(lockouts.categories_for_ui()) do
                ImGui.TableNextRow()
                ImGui.TableSetColumnIndex(0)
                local label = (category_collapsed(cat) and "+ " or "- ") .. cat
                local pushed = false
                if ImGui.PushStyleColor and ImGuiCol and ImGuiCol.Text then
                    local c = Theme.category or Theme.cyan
                    pushed = pcall(ImGui.PushStyleColor, ImGuiCol.Text, c[1], c[2], c[3], c[4])
                end
                if ImGui.Selectable(label .. "##lo_cat_" .. tostring(cat), false) then
                    toggle_category(cat)
                end
                if pushed and ImGui.PopStyleColor then pcall(ImGui.PopStyleColor, 1) end
                for cidx = 1, #keys do
                    ImGui.TableSetColumnIndex(cidx)
                    ImGui.TextDisabled("")
                end
                if not category_collapsed(cat) then for _, entry in ipairs(lockouts.entries_for_category(cat)) do
                    local hidden = is_entry_hidden(cat, entry.name)
                    if hidden and not Settings.lockoutsShowHidden then goto continue_lockout_entry end
                    if Settings.lockoutsLockedOnly and not entry_has_locked(keys, cat, entry) then goto continue_lockout_entry end
                    ImGui.TableNextRow()
                    ImGui.TableSetColumnIndex(0)
                    local row_label = lockout_ref.display_label(entry)
                    if hidden then
                        col_text(Theme.dim, "(" .. row_label .. ")")
                    else
                        col_text(Theme.slot or Theme.dim, row_label)
                    end
                    -- Right-click context menu for all entries
                    if ImGui.BeginPopupContextItem then
                        pcall(function()
                            if ImGui.BeginPopupContextItem("##lo_ctx_" .. cat .. "_" .. tostring(entry.name)) then
                                if entry.custom then
                                    if ImGui.MenuItem("Edit") then
                                        load_entry_for_edit(entry)
                                        lockouts.remove_custom_by_name(entry.name)
                                        lo_status = string.format("Editing '%s' - update fields and click Add.", entry.name)
                                        snapshot_mod.invalidate()
                                        lockouts.invalidate_cache()
                                    end
                                    if ImGui.MenuItem("Delete") then
                                        lockouts.remove_custom_by_name(entry.name)
                                        lo_status = string.format("Removed '%s'.", entry.name)
                                        snapshot_mod.invalidate()
                                        lockouts.invalidate_cache()
                                    end
                                    ImGui.Separator()
                                end
                                local hide_label = hidden and "Show this lockout" or "Hide this lockout"
                                if ImGui.MenuItem(hide_label) then
                                    toggle_entry_hidden(cat, entry.name)
                                end
                                ImGui.EndPopup()
                            end
                        end)
                    end
                    for cidx, key in ipairs(keys) do
                        ImGui.TableSetColumnIndex(cidx)
                        local snap = views.source_snapshot(key)
                        if Settings.lockoutsCompact then
                            draw_lockout_cell_compact(snap, cat, entry)
                        else
                            draw_lockout_cell(snap, cat, entry)
                        end
                    end
                    ::continue_lockout_entry::
                end end
            end
        end)
        ImGui.EndTable()
        if not ok then col_text(Theme.amber, "Lockouts table error: " .. tostring(err)) end
    end
    col_text(Theme.dim, "Locked = on timer (hover for expiry). Open = available. Sync refreshes all boxes.")
end

function M.on_tab_enter()
    snapshot_mod.gather({ force = false, depth = "lite" })
    if Engine.ok then Engine.request_all(false, { depth = "lite" }) end
end

return M
