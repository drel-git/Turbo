-- TurboGear/tabs/focus.lua
-- Read-only cached focus browser powered by item_index rows.

local ImGui = require('ImGui')
local theme = require('theme')
local Theme, col_text, toggle_button = theme.Theme, theme.col_text, theme.toggle_button
local cfg = require('config')
local Settings, SaveSettings = cfg.Settings, cfg.SaveSettings
local item_index = require('item_index')
local ui_table = require('ui_table')
local views = require('views')
local item_actions = require('item_actions')
local Engine = require('engine').Engine
local Store = require('store').Store
local characters = require('characters')

local M = {}

local search_text = ""
local filtered_key, filtered_entries = nil, {}

characters.set_on_changed(function()
    filtered_key = nil
end, "focus")

local SOURCE_SCOPES = {
    { key = "all",    label = "All Known" },
    { key = "online", label = "Online" },
    { key = "group",  label = "Group" },
    { key = "e3",     label = "E3 Online" },
    { key = "character", label = "Character" },
    { key = "loadout", label = "Loadout List" },
}

local GROUP_MODES = {
    { key = "none",     label = "None" },
    { key = "effect",   label = "Effect" },
    { key = "owner",    label = "Owner" },
    { key = "location", label = "Location" },
}

local function ensure_defaults()
    Settings.focusSourceScope = Settings.focusSourceScope or "all"
    Settings.focusSourceKey = Settings.focusSourceKey or "__self__"
    Settings.focusLoadoutList = Settings.focusLoadoutList or ""
    Settings.focusSortKey = Settings.focusSortKey or "value"
    Settings.focusGroupMode = Settings.focusGroupMode or "none"
    if Settings.focusSortDesc == nil then Settings.focusSortDesc = true end
    if Settings.focusIncludeFocus == nil then Settings.focusIncludeFocus = true end
    if Settings.focusIncludeWorn == nil then Settings.focusIncludeWorn = true end
    if Settings.focusLocEquipped == nil then Settings.focusLocEquipped = true end
    if Settings.focusLocInstalled == nil then Settings.focusLocInstalled = true end
    if Settings.focusLocLoose == nil then Settings.focusLocLoose = true end
    if Settings.focusLocBags == nil then Settings.focusLocBags = true end
    if Settings.focusLocBank == nil then Settings.focusLocBank = true end
    if Settings.focusShowAllRows == nil then Settings.focusShowAllRows = false end
    if Settings.focusColKind == nil then Settings.focusColKind = true end
    if Settings.focusColValue == nil then Settings.focusColValue = true end
    if Settings.focusColLevel == nil then Settings.focusColLevel = true end
    if Settings.focusColSpellType == nil then Settings.focusColSpellType = true end
    if Settings.focusColResist == nil then Settings.focusColResist = true end
    Settings.focusRowLimit = tonumber(Settings.focusRowLimit) or 300
end

local function group_label()
    for _, opt in ipairs(GROUP_MODES) do
        if opt.key == Settings.focusGroupMode then return opt.label end
    end
    return "None"
end

local function draw_group_picker()
    ImGui.Text("Group:")
    ImGui.SameLine()
    ImGui.SetNextItemWidth(110.0)
    if ImGui.BeginCombo("##focus_group", group_label()) then
        for _, opt in ipairs(GROUP_MODES) do
            if ImGui.Selectable(opt.label .. "##focus_group_" .. opt.key, Settings.focusGroupMode == opt.key) then
                Settings.focusGroupMode = opt.key
                SaveSettings()
                filtered_key = nil
            end
        end
        ImGui.EndCombo()
    end
end

local function input_text_hint(id, hint, value)
    if ImGui.InputTextWithHint then
        local ok, rv = pcall(ImGui.InputTextWithHint, id, hint, value or "")
        if ok then return rv or "" end
    end
    return ImGui.InputText(id, value or "") or ""
end

local function scope_label()
    for _, opt in ipairs(SOURCE_SCOPES) do
        if opt.key == Settings.focusSourceScope then return opt.label end
    end
    return "All Known"
end

local function draw_scope_picker()
    ImGui.Text("Source:")
    ImGui.SameLine()
    ImGui.SetNextItemWidth(120.0)
    if ImGui.BeginCombo("##focus_scope", scope_label()) then
        for _, opt in ipairs(SOURCE_SCOPES) do
            if ImGui.Selectable(opt.label .. "##focus_scope_" .. opt.key, Settings.focusSourceScope == opt.key) then
                Settings.focusSourceScope = opt.key
                SaveSettings()
                filtered_key = nil
            end
        end
        ImGui.EndCombo()
    end
    if Settings.focusSourceScope == "character" then
        ImGui.SameLine()
        local old = Settings.focusSourceKey
        Settings.focusSourceKey = views.draw_source_picker("##focus_source_key", Settings.focusSourceKey or "__self__", 220.0)
        if Settings.focusSourceKey ~= old then
            SaveSettings()
            filtered_key = nil
        end
    elseif Settings.focusSourceScope == "loadout" then
        ImGui.SameLine()
        local ok_loadout, loadout = pcall(require, 'loadout')
        if ok_loadout and loadout then
            local old = Settings.focusLoadoutList or ""
            Settings.focusLoadoutList = loadout.draw_list_picker("##focus_loadout_list", old ~= "" and old or loadout.selected_list_id(), 220.0)
            if Settings.focusLoadoutList ~= old then
                SaveSettings()
                filtered_key = nil
            end
        end
    end
end

local function loc_toggle(label, setting_key)
    local active = Settings[setting_key] ~= false
    local color = active and ((label == "Bags" and Theme.bag) or (label == "Bank" and Theme.bank) or Theme.blue) or Theme.steel
    if theme.themed_button(label .. "##focus_" .. setting_key, color) then
        Settings[setting_key] = not active
        SaveSettings()
        filtered_key = nil
    end
end

local function row_source_allowed(row, e3_names, source_owner)
    local scope = Settings.focusSourceScope or "all"
    if scope == "loadout" then return true end
    if scope == "all" then return true end
    if scope == "online" then return row.ownerStatus == "live" end
    if scope == "group" then return views.is_group_member(row.owner) end
    if scope == "e3" then
        return row.ownerStatus == "live" and e3_names and e3_names[views.clean_name(row.owner)] == true
    end
    if scope == "character" then
        return source_owner and source_owner ~= "" and views.clean_name(row.owner) == source_owner
    end
    return true
end

local function row_location_allowed(row)
    if row.where == "equipped" and Settings.focusLocEquipped == false then return false end
    if row.where == "installed_aug" and Settings.focusLocInstalled == false then return false end
    if row.where == "loose_aug" and Settings.focusLocLoose == false then return false end
    if row.locationGroup == "bags" and Settings.focusLocBags == false then return false end
    if row.locationGroup == "bank" and Settings.focusLocBank == false then return false end
    return true
end

local function owner_label(row)
    local cls = views.class_abbrev(row.ownerClass or "")
    if cls and cls ~= "" then return string.format("%s (%s)", row.owner or "?", cls) end
    return row.owner or "?"
end

local function source_location_text(row)
    if not row then return "" end
    local parts = { owner_label(row), row.location or "-" }
    if row.installedIn and row.installedIn ~= "" then
        parts[#parts+1] = "installed in " .. row.installedIn
    end
    return table.concat(parts, " | ")
end

local function entry_search_blob(entry)
    local row = entry.row or {}
    return table.concat({
        entry.typeName or "",
        entry.kindLabel or "",
        entry.spellName or "",
        entry.spellType or "",
        entry.resist or "",
        row.name or "",
        row.owner or "",
        row.location or "",
        row.installedIn or "",
        row.ownerClass or "",
    }, " "):lower()
end

local function entry_matches(entry, needle)
    return needle == "" or entry_search_blob(entry):find(needle, 1, true) ~= nil
end

local function controls_key(index_version)
    return table.concat({
        tostring(index_version or 0),
        tostring(Settings.focusSourceScope or ""),
        tostring(Settings.focusSourceKey or ""),
        tostring(Settings.focusLoadoutList or ""),
        tostring(Settings.focusSortKey or ""),
        tostring(Settings.focusSortDesc),
        tostring(Settings.focusGroupMode or ""),
        tostring(Settings.focusIncludeFocus),
        tostring(Settings.focusIncludeWorn),
        tostring(Settings.focusLocEquipped),
        tostring(Settings.focusLocInstalled),
        tostring(Settings.focusLocLoose),
        tostring(Settings.focusLocBags),
        tostring(Settings.focusLocBank),
        tostring(search_text or ""),
    }, "\1")
end

local function location_group_label(row)
    local where = tostring(row and row.where or "")
    if where == "equipped" then return "Equipped" end
    if where == "installed_aug" then return "Installed Augs" end
    if where == "loose_aug" then return "Loose Augs" end
    local group = tostring(row and row.locationGroup or "")
    if group == "equipped" then return "Equipped" end
    if group == "bags" then return "Bags" end
    if group == "bank" then return "Bank" end
    if group == "aug" or group == "installed_aug" then return "Installed Augs" end
    local loc = tostring(row and row.location or "")
    return loc ~= "" and loc or "Other"
end

local function entry_group_value(entry)
    local mode = Settings.focusGroupMode or "none"
    local row = entry and entry.row or {}
    if mode == "effect" then
        local effect = tostring(entry and entry.typeName or "")
        return effect ~= "" and effect or "Other"
    end
    if mode == "owner" then return owner_label(row) end
    if mode == "location" then return location_group_label(row) end
    return ""
end

local function group_sort_key(entry)
    return tostring(entry_group_value(entry) or ""):lower()
end

local function add_effect_entries(out, row, effects, kind_label, needle)
    for _, effect in ipairs(effects or {}) do
        local entry = {
            row = row,
            kindLabel = kind_label,
            typeName = effect.typeName or "",
            maxEffect = tonumber(effect.maxEffect) or 0,
            effectiveLevel = tonumber(effect.effectiveLevel) or 0,
            rank = tonumber(effect.rank) or 0,
            spellType = effect.spellType or "",
            resist = effect.resist or "",
            spellName = effect.spellName or effect.description or "",
            spellId = tonumber(effect.spellId) or 0,
        }
        if entry_matches(entry, needle) then out[#out+1] = entry end
    end
end

local function entry_sort_value(entry)
    local value = tonumber(entry.maxEffect) or 0
    if value == 0 then value = tonumber(entry.rank) or 0 end
    if value ~= value then return 0 end
    return value
end

local function safe_number(value)
    value = tonumber(value) or 0
    if value ~= value then return 0 end
    return value
end

local function sort_text(v)
    return tostring(v or ""):lower()
end

local function compare_text(a, b, desc)
    if a == b then return nil end
    if desc then return a > b end
    return a < b
end

local function entry_primary_value(entry, row, sort_key)
    if sort_key == "effect" then return sort_text(entry.typeName), false end
    if sort_key == "kind" then return sort_text(entry.kindLabel), false end
    if sort_key == "value" then return entry_sort_value(entry), true end
    if sort_key == "level" then return safe_number(entry.effectiveLevel), true end
    if sort_key == "spellType" then return sort_text(entry.spellType), false end
    if sort_key == "resist" then return sort_text(entry.resist), false end
    if sort_key == "item" then return sort_text(row.name), false end
    if sort_key == "owner" then return sort_text(owner_label(row)), false end
    if sort_key == "location" then return sort_text(row.location), false end
    return entry_sort_value(entry), true
end

local function make_sort_wrapper(entry, index, sort_key)
    local row = entry.row or {}
    local primary, number_sort = entry_primary_value(entry, row, sort_key)
    return {
        entry = entry,
        index = index,
        primary = primary,
        numberSort = number_sort,
        value = entry_sort_value(entry),
        effect = sort_text(entry.typeName),
        loc = ui_table.location_sort_value(row),
        owner = sort_text(row.owner),
        name = sort_text(row.name),
        source = sort_text(row.sourceKey),
    }
end

local function sort_wrappers(wrappers, sort_key, desc)
    ui_table.stable_sort(wrappers, function(a, b)
        local primary = a.numberSort and ui_table.compare_number(a.primary, b.primary, desc) or nil
        if primary ~= nil then return primary end
        if not a.numberSort then
            local text_cmp = compare_text(a.primary, b.primary, desc)
            if text_cmp ~= nil then return text_cmp end
        end
        if sort_key ~= "value" then
            local fallback = ui_table.compare_number(a.value, b.value, true)
            if fallback ~= nil then return fallback end
        end
        local effect = compare_text(a.effect, b.effect, false)
        if effect ~= nil then return effect end
        local loc = ui_table.compare_number(a.loc, b.loc, false)
        if loc ~= nil then return loc end
        local owner = compare_text(a.owner, b.owner, false)
        if owner ~= nil then return owner end
        local name = compare_text(a.name, b.name, false)
        if name ~= nil then return name end
        local source = compare_text(a.source, b.source, false)
        if source ~= nil then return source end
        return (a.index or 0) < (b.index or 0)
    end)
end

local function sort_entries(entries)
    local sort_key = Settings.focusSortKey or "value"
    local desc = Settings.focusSortDesc ~= false
    local wrappers = {}
    for i, entry in ipairs(entries or {}) do wrappers[i] = make_sort_wrapper(entry, i, sort_key) end
    sort_wrappers(wrappers, sort_key, desc)
    for i, wrapped in ipairs(wrappers) do entries[i] = wrapped.entry end
end

local function sort_grouped_entries(entries)
    if (Settings.focusGroupMode or "none") == "none" then return end
    local wrappers = {}
    local sort_key = Settings.focusSortKey or "value"
    local desc = Settings.focusSortDesc ~= false
    for i, entry in ipairs(entries or {}) do
        local wrapped = make_sort_wrapper(entry, i, sort_key)
        wrapped.group = group_sort_key(entry)
        wrappers[i] = wrapped
    end
    ui_table.stable_sort(wrappers, function(a, b)
        local group_cmp = compare_text(a.group, b.group, false)
        if group_cmp ~= nil then return group_cmp end
        local primary = a.numberSort and ui_table.compare_number(a.primary, b.primary, desc) or nil
        if primary ~= nil then return primary end
        if not a.numberSort then
            local text_cmp = compare_text(a.primary, b.primary, desc)
            if text_cmp ~= nil then return text_cmp end
        end
        local fallback = ui_table.compare_number(a.value, b.value, true)
        if fallback ~= nil then return fallback end
        local name = compare_text(a.name, b.name, false)
        if name ~= nil then return name end
        return (a.index or 0) < (b.index or 0)
    end)
    for i, wrapped in ipairs(wrappers) do entries[i] = wrapped.entry end
end

local function visible_entries()
    if Settings.focusSourceScope == "loadout" then
        local ok_loadout, loadout = pcall(require, 'loadout')
        local list_id = Settings.focusLoadoutList or ""
        if ok_loadout and loadout then
            if list_id == "" then list_id = loadout.selected_list_id() or "" end
            Settings.focusLoadoutList = list_id
        end
        local key = controls_key(list_id)
        if filtered_key == key then return filtered_entries end

        local out = {}
        local needle = tostring(search_text or ""):lower()
        if ok_loadout and loadout and list_id ~= "" then
            for _, row in ipairs(loadout.index_rows(list_id) or {}) do
                if Settings.focusIncludeFocus ~= false then
                    add_effect_entries(out, row, row.focusEffects, "Focus", needle)
                end
                if Settings.focusIncludeWorn ~= false then
                    add_effect_entries(out, row, row.wornFocusEffects, "Worn", needle)
                end
            end
        end

        if (Settings.focusGroupMode or "none") == "none" then
            sort_entries(out)
        else
            sort_grouped_entries(out)
        end

        filtered_entries = out
        filtered_key = key
        return filtered_entries
    end

    local rows, index_version = item_index.get(false)
    local key = controls_key(index_version)
    if filtered_key == key then return filtered_entries end

    local out = {}
    local needle = tostring(search_text or ""):lower()
    local e3_names = Settings.focusSourceScope == "e3" and views.e3_connected_names() or nil
    local source_owner = Settings.focusSourceScope == "character" and views.clean_name(views.source_owner_name(Settings.focusSourceKey)) or nil
    for _, row in ipairs(rows or {}) do
        if row_source_allowed(row, e3_names, source_owner) and row_location_allowed(row) then
            if Settings.focusIncludeFocus ~= false then
                add_effect_entries(out, row, row.focusEffects, "Focus", needle)
            end
            if Settings.focusIncludeWorn ~= false then
                add_effect_entries(out, row, row.wornFocusEffects, "Worn", needle)
            end
        end
    end

    if (Settings.focusGroupMode or "none") == "none" then
        sort_entries(out)
    else
        sort_grouped_entries(out)
    end

    filtered_entries = out
    filtered_key = key
    return filtered_entries
end

local function draw_controls()
    local use_pill = Settings.showCharactersPill == true
    if use_pill then
        if Settings.focusSourceScope ~= "character" then
            Settings.focusSourceScope = "character"
        end
    else
        draw_scope_picker()
        ImGui.SameLine()
    end
    if theme.themed_button("Refresh##focus_refresh", Theme.blue) then
        if Settings.focusSourceScope == "loadout" then
            pcall(function() require('loadout').invalidate() end)
        else
            item_index.refresh()
        end
        filtered_key = nil
    end
    ImGui.SameLine()
    if toggle_button("Focus##focus_include_focus", Settings.focusIncludeFocus ~= false) then
        Settings.focusIncludeFocus = not (Settings.focusIncludeFocus ~= false)
        SaveSettings()
        filtered_key = nil
    end
    ImGui.SameLine()
    if toggle_button("Worn##focus_include_worn", Settings.focusIncludeWorn ~= false) then
        Settings.focusIncludeWorn = not (Settings.focusIncludeWorn ~= false)
        SaveSettings()
        filtered_key = nil
    end
    ImGui.SameLine()
    draw_group_picker()
    ImGui.SameLine()
    if theme.themed_button("Display Settings##focus_display_settings", Theme.steel) then
        Settings.mainTab = "setup"
        Settings.setupFocusDisplayJump = true
        SaveSettings()
    end

    ImGui.Separator()
    if Settings.focusSourceScope ~= "loadout" then
        loc_toggle("Equipped", "focusLocEquipped")
        ImGui.SameLine()
        loc_toggle("Installed Augs", "focusLocInstalled")
        ImGui.SameLine()
        loc_toggle("Loose Augs", "focusLocLoose")
        ImGui.SameLine()
        loc_toggle("Bags", "focusLocBags")
        ImGui.SameLine()
        loc_toggle("Bank", "focusLocBank")
        ImGui.SameLine()
    end
    ImGui.SetNextItemWidth(220.0)
    local next_search = input_text_hint("##focus_search", "Search", search_text)
    if next_search ~= search_text then
        search_text = next_search or ""
        filtered_key = nil
    end
end

local function value_label(entry)
    if (tonumber(entry.maxEffect) or 0) ~= 0 then return tostring(math.floor(entry.maxEffect)) end
    if (tonumber(entry.rank) or 0) ~= 0 then return "R" .. tostring(math.floor(entry.rank)) end
    return "-"
end

local function level_label(entry)
    local level = tonumber(entry.effectiveLevel) or 0
    return level > 0 and tostring(math.floor(level)) or "-"
end

local EFFECT_TYPE_COLORS = {
    ["Spell Damage"] = Theme.fire,
    ["Healing"] = Theme.healer,
    ["Hate"] = Theme.melee,
    ["Range"] = Theme.melee,
    ["Cleave"] = Theme.melee,
    ["Ferocity"] = Theme.melee,
    ["Trigger Chance"] = Theme.melee,
    ["Pet Power"] = Theme.melee,
    ["Dodge"] = Theme.tank,
    ["Parry"] = Theme.tank,
    ["Resist"] = Theme.cyan,
    ["Cast Time"] = Theme.caster,
    ["Duration"] = Theme.caster,
    ["Mana Cost"] = Theme.caster,
    ["Reagent"] = Theme.caster,
    ["Spell Haste"] = Theme.caster,
    ["Stun Time"] = Theme.utility,
}

local function effect_type_color(entry)
    local name = tostring(entry.typeName or "")
    if EFFECT_TYPE_COLORS[name] then return EFFECT_TYPE_COLORS[name] end
    if entry.kindLabel == "Worn" then return Theme.valueTop or Theme.gold end
    return Theme.header or Theme.neutral
end

local function column_width_now()
    if ImGui.GetColumnWidth then
        local w = ImGui.GetColumnWidth()
        if type(w) == "table" then return tonumber(w.x or w[1]) end
        return tonumber(w)
    end
    return nil
end

local function begin_focus_table(col_count)
    return views.begin_scroll_table("FocusRows", col_count, views.scroll_table_flags(), 28.0, 220.0)
end

local function visible_columns()
    local effect_flags = ImGuiTableColumnFlags.WidthStretch
    if ImGuiTableColumnFlags and ImGuiTableColumnFlags.AlignCenter then
        effect_flags = effect_flags + ImGuiTableColumnFlags.AlignCenter
    end
    local cols = {
        { key = "effect", label = "Effect", flags = effect_flags, width = 1.1 },
    }
    if Settings.focusColKind ~= false then cols[#cols+1] = { key = "kind", label = "Kind", flags = ImGuiTableColumnFlags.WidthFixed, width = 58.0 } end
    if Settings.focusColValue ~= false then cols[#cols+1] = { key = "value", label = "Value", flags = ImGuiTableColumnFlags.WidthFixed, width = 58.0 } end
    if Settings.focusColLevel ~= false then cols[#cols+1] = { key = "level", label = "Level", flags = ImGuiTableColumnFlags.WidthFixed, width = 54.0 } end
    if Settings.focusColSpellType ~= false then cols[#cols+1] = { key = "spellType", label = "Spell Type", flags = ImGuiTableColumnFlags.WidthFixed, width = 95.0 } end
    if Settings.focusColResist ~= false then cols[#cols+1] = { key = "resist", label = "Resist", flags = ImGuiTableColumnFlags.WidthFixed, width = 78.0 } end
    cols[#cols+1] = { key = "item", label = "Item/Aug", flags = ImGuiTableColumnFlags.WidthStretch, width = 1.4 }
    cols[#cols+1] = { key = "owner", label = "Owner", flags = ImGuiTableColumnFlags.WidthFixed, width = 120.0 }
    cols[#cols+1] = { key = "location", label = "Location", flags = ImGuiTableColumnFlags.WidthStretch, width = 1.4 }
    return cols
end

local function sort_label(label, key)
    if (Settings.focusSortKey or "value") ~= key then return label end
    return label .. (Settings.focusSortDesc ~= false and " v" or " ^")
end

local function set_sort(key, default_desc)
    if (Settings.focusSortKey or "value") == key then
        Settings.focusSortDesc = not (Settings.focusSortDesc ~= false)
    else
        Settings.focusSortKey = key
        Settings.focusSortDesc = default_desc ~= false
    end
    SaveSettings()
    filtered_key = nil
end

local function draw_sort_header(col, label, key, default_desc)
    ImGui.TableSetColumnIndex(col)
    if views.selectable_centered(sort_label(label, key), "##focus_sort_" .. key) then
        set_sort(key, default_desc)
    end
end

local function draw_headers(cols)
    ImGui.TableNextRow()
    for cidx, col in ipairs(cols or {}) do
        draw_sort_header(cidx - 1, col.label, col.key, col.key == "value" or col.key == "level")
    end
end

local function draw_entry_column(col_key, entry, row, index)
    if col_key == "effect" then
        local label = entry.typeName ~= "" and entry.typeName or "-"
        views.col_text_centered(effect_type_color(entry), label, column_width_now())
    elseif col_key == "kind" then
        col_text(entry.kindLabel == "Worn" and (Theme.valueTop or Theme.gold) or (Theme.owner or Theme.dim), entry.kindLabel or "-")
    elseif col_key == "value" then
        local val = value_label(entry)
        local val_color = (tonumber(entry.maxEffect) or 0) >= 30 and (Theme.valueTop or Theme.gold)
            or (Theme.value or Theme.green)
        views.col_text_centered(val_color, val, 58.0)
    elseif col_key == "level" then
        col_text(Theme.dim, level_label(entry))
    elseif col_key == "spellType" then
        col_text(Theme.dim, entry.spellType ~= "" and entry.spellType or "-")
    elseif col_key == "resist" then
        col_text(Theme.dim, entry.resist ~= "" and entry.resist or "-")
    elseif col_key == "item" then
        local name_color = row.kind == "aug" and (Theme.aug or Theme.green) or Theme.item
        if row.unresolved then name_color = Theme.amber end
        item_actions.draw_name(row.name or "?", name_color, "focus_item_" .. tostring(index) .. "_" .. tostring(row.sourceKey or ""), row.id, item_actions.context_opts({
            sourceLocation = source_location_text(row),
        }, row))
    elseif col_key == "owner" then
        views.draw_owner_cell(row)
    elseif col_key == "location" then
        col_text(theme.location_color(row.locationGroup, row.location), row.location or "-")
    end
end

local function draw_rows(entries)
    local total = #(entries or {})
    local limit = Settings.focusShowAllRows and total or math.min(total, Settings.focusRowLimit or 300)
    local cols = visible_columns()
    local group_mode = Settings.focusGroupMode or "none"
    local last_group = nil
    if begin_focus_table(#cols) then
        for _, col in ipairs(cols) do
            ImGui.TableSetupColumn(col.label, col.flags, col.width)
        end
        pcall(function() ImGui.TableSetupScrollFreeze(0, 1) end)
        draw_headers(cols)

        for i = 1, limit do
            local entry = entries[i]
            local row = entry.row or {}
            if group_mode ~= "none" then
                local current_group = entry_group_value(entry)
                if current_group ~= last_group then
                    last_group = current_group
                    views.draw_section_row(current_group ~= "" and current_group or "Other", #cols)
                end
            end
            ImGui.TableNextRow()
            for cidx, col in ipairs(cols) do
                ImGui.TableSetColumnIndex(cidx - 1)
                draw_entry_column(col.key, entry, row, i)
            end
        end

        ImGui.EndTable()
    end
    if limit < total then
        col_text(Theme.dim, string.format("Showing top %d of %d rows.", limit, total))
        ImGui.SameLine()
        if toggle_button("Show All##focus_show_all_rows", false) then
            Settings.focusShowAllRows = true
            SaveSettings()
        end
    elseif total > (Settings.focusRowLimit or 300) then
        col_text(Theme.dim, string.format("Showing all %d rows.", total))
        ImGui.SameLine()
        if toggle_button("Top " .. tostring(Settings.focusRowLimit or 300) .. "##focus_top_rows", true) then
            Settings.focusShowAllRows = false
            SaveSettings()
        end
    end
end

local function draw_focus_content()
    ImGui.Spacing()

    local entries = visible_entries()
    if Settings.focusSourceScope == "loadout" then
        local ok_loadout, loadout = pcall(require, 'loadout')
        local list_id = Settings.focusLoadoutList or ""
        if ok_loadout and loadout then
            if list_id == "" then list_id = loadout.selected_list_id() or "" end
            local snap = list_id ~= "" and loadout.build_snapshot(list_id) or nil
            if snap then
                local msg = string.format("Loadout list: %s (%d slotted items, %d focus rows)", snap.name or "?", #(snap.equipped or {}), #entries)
                if (snap.unresolved or 0) > 0 then
                    msg = msg .. string.format(" | %d unresolved (amber)", snap.unresolved)
                end
                col_text(Theme.dim, msg)
            else
                col_text(Theme.amber, "Pick a loadout list from Source, or create one on TurboBiS.")
            end
        end
    else
        col_text(Theme.dim, string.format("%d cached focus row%s", #entries, #entries == 1 and "" or "s"))
    end
    if Engine.debug then
        col_text(Theme.dim, string.format("Index v%d / data v%d", item_index.version or 0, Store.content_version or 0))
    end
    ImGui.Spacing()

    if #entries == 0 then
        local empty = Settings.focusSourceScope == "loadout"
            and "No focus effects on this loadout list for the current filters."
            or "No cached focus rows match the current filters. Sync after this build so snapshots include focus data."
        col_text(Theme.placeholder or Theme.dim, empty)
        return
    end

    draw_rows(entries)
    local status = item_actions.status()
    if status and status ~= "" then col_text(Theme.dim, status) end
end

function M.draw()
    ensure_defaults()
    draw_controls()

    local child_began = false
    local child_open = true
    if ImGui.BeginChild then
        local ok, open = pcall(function()
            if ImVec2 then
                return ImGui.BeginChild("##focus_content_scroll", ImVec2(0, 0), false, 0)
            end
            return ImGui.BeginChild("##focus_content_scroll", 0, 0, false, 0)
        end)
        if ok then
            child_began = true
            child_open = (open ~= false)
        end
    end
    if child_open then draw_focus_content() end
    if child_began and ImGui.EndChild then ImGui.EndChild() end
end

function M.set_search(text)
    search_text = tostring(text or "")
    filtered_key = nil
end

return M
