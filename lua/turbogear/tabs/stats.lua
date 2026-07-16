-- TurboGear/tabs/stats.lua
-- Character overview, loadout plan analysis, and roster stat search.

local ImGui = require('ImGui')
local theme = require('theme')
local Theme, col_text, toggle_button, nav_button = theme.Theme, theme.col_text, theme.toggle_button, theme.nav_button
local cfg = require('config')
local Settings, SaveSettings = cfg.Settings, cfg.SaveSettings
local stat_defs = require('stat_defs')
local item_index = require('item_index')
local ui_table = require('ui_table')
local views = require('views')
local item_actions = require('item_actions')
local Engine = require('engine').Engine
local Store = require('store').Store
local characters = require('characters')

local M = {}

local search_text = ""
local filtered_key, filtered_rows = nil, {}

characters.set_on_changed(function()
    filtered_key = nil
end, "stats")

local VIEW_MODES = {
    { key = "character", label = "Character" },
    { key = "plan", label = "Plan" },
    { key = "search", label = "Search" },
}

local SEARCH_SCOPES = {
    { key = "all", label = "All Known" },
    { key = "online", label = "Online" },
    { key = "group", label = "Group" },
    { key = "e3", label = "E3 Online" },
}

local function sync_legacy_scope()
    local mode = Settings.statsViewMode or "character"
    if mode == "plan" then
        Settings.statsSourceScope = "loadout"
    elseif mode == "character" then
        Settings.statsSourceScope = "character"
    else
        Settings.statsSourceScope = Settings.statsSearchScope or "all"
    end
end

local function ensure_defaults()
    Settings.statsSelectedStat = Settings.statsSelectedStat or "shielding"
    Settings.statsAugsOnly = Settings.statsAugsOnly ~= false
    Settings.statsSourceKey = Settings.statsSourceKey or "__self__"
    Settings.statsLoadoutList = Settings.statsLoadoutList or ""
    Settings.statsSearchScope = Settings.statsSearchScope or "all"
    Settings.statsSortKey = Settings.statsSortKey or "value"
    if Settings.statsSortDesc == nil then Settings.statsSortDesc = true end
    if Settings.statsLocEquipped == nil then Settings.statsLocEquipped = true end
    if Settings.statsLocInstalled == nil then Settings.statsLocInstalled = true end
    if Settings.statsLocLoose == nil then Settings.statsLocLoose = true end
    if Settings.statsLocBags == nil then Settings.statsLocBags = true end
    if Settings.statsLocBank == nil then Settings.statsLocBank = true end
    if Settings.statsShowAllRows == nil then Settings.statsShowAllRows = false end
    Settings.statsRowLimit = tonumber(Settings.statsRowLimit) or 300

    if Settings.statsViewMode == nil then
        local scope = Settings.statsSourceScope or "all"
        if scope == "loadout" then
            Settings.statsViewMode = "plan"
        elseif scope == "character" then
            Settings.statsViewMode = "character"
        else
            Settings.statsViewMode = "search"
            Settings.statsSearchScope = scope
        end
    end
    Settings.statsViewMode = Settings.statsViewMode or "character"
    sync_legacy_scope()
end

local function view_mode()
    ensure_defaults()
    return Settings.statsViewMode or "character"
end

local function input_text_hint(id, hint, value)
    if ImGui.InputTextWithHint then
        local ok, rv = pcall(ImGui.InputTextWithHint, id, hint, value or "")
        if ok then return rv or "" end
    end
    return ImGui.InputText(id, value or "") or ""
end

local function stat_label(key)
    return stat_defs.label(key or Settings.statsSelectedStat)
end

local function set_view_mode(key)
    if view_mode() == key then return end
    Settings.statsViewMode = key
    sync_legacy_scope()
    SaveSettings()
    filtered_key = nil
end

local function draw_view_tabs()
    local mode = view_mode()
    for i, opt in ipairs(VIEW_MODES) do
        if i > 1 then ImGui.SameLine() end
        if nav_button(opt.label .. "##stats_view_" .. opt.key, mode == opt.key, true, 0, 22.0) then
            set_view_mode(opt.key)
        end
    end
end

-- Drawn above ##tg_main_scroll_body so Character / Plan / Search stay pinned.
function M.draw_view_chrome()
    ensure_defaults()
    draw_view_tabs()
    ImGui.Separator()
end

local function search_scope_label()
    for _, opt in ipairs(SEARCH_SCOPES) do
        if opt.key == (Settings.statsSearchScope or "all") then return opt.label end
    end
    return "All Known"
end

local function draw_stat_picker()
    ImGui.Text("Stat:")
    ImGui.SameLine()
    ImGui.SetNextItemWidth(170.0)
    if ImGui.BeginCombo("##stats_stat", stat_label(Settings.statsSelectedStat)) then
        for _, def in ipairs(stat_defs.stats) do
            if ImGui.Selectable(def.label .. "##stats_stat_" .. def.key, Settings.statsSelectedStat == def.key) then
                Settings.statsSelectedStat = def.key
                SaveSettings()
                filtered_key = nil
            end
        end
        ImGui.EndCombo()
    end
end

local function draw_mode_picker()
    local mode = view_mode()
    local use_pill = Settings.showCharactersPill == true
    if mode == "character" then
        if not use_pill then
            ImGui.Text("Character:")
            ImGui.SameLine()
            local old = Settings.statsSourceKey or "__self__"
            Settings.statsSourceKey = views.draw_source_picker("##stats_source_key", old, 220.0)
            if Settings.statsSourceKey ~= old then
                SaveSettings()
                filtered_key = nil
            end
        end
    elseif mode == "plan" then
        if not use_pill then
            ImGui.Text("List:")
            ImGui.SameLine()
            local ok_loadout, loadout = pcall(require, 'loadout')
            if ok_loadout and loadout then
                local old = Settings.statsLoadoutList or ""
                Settings.statsLoadoutList = loadout.draw_list_picker("##stats_loadout_list", old ~= "" and old or loadout.selected_list_id(), 220.0)
                if Settings.statsLoadoutList ~= old then
                    SaveSettings()
                    filtered_key = nil
                end
            end
        end
    elseif not use_pill then
        ImGui.Text("Scope:")
        ImGui.SameLine()
        ImGui.SetNextItemWidth(120.0)
        if ImGui.BeginCombo("##stats_search_scope", search_scope_label()) then
            for _, opt in ipairs(SEARCH_SCOPES) do
                if ImGui.Selectable(opt.label .. "##stats_search_scope_" .. opt.key, Settings.statsSearchScope == opt.key) then
                    Settings.statsSearchScope = opt.key
                    sync_legacy_scope()
                    SaveSettings()
                    filtered_key = nil
                end
            end
            ImGui.EndCombo()
        end
    end
end

local function loc_toggle(label, setting_key)
    local active = Settings[setting_key] ~= false
    local color = active and ((label == "Bags" and Theme.bag) or (label == "Bank" and Theme.bank) or Theme.blue) or Theme.steel
    if theme.themed_button(label .. "##stats_" .. setting_key, color) then
        Settings[setting_key] = not active
        SaveSettings()
        filtered_key = nil
    end
end

local function row_source_allowed(row, e3_names)
    if Settings.showCharactersPill == true and view_mode() == "search" then
        local view = characters.get_view_key("stats_search")
        if view == characters.VIEW_SELECTED then
            local selected = Settings.statsSearchSelectedChars or {}
            local clean = views.clean_name(row.owner)
            return clean ~= "" and selected[clean] ~= nil
        elseif view ~= characters.VIEW_ALL and view ~= "" then
            local want = views.clean_name(views.source_owner_name(view))
            return want ~= "" and views.clean_name(row.owner) == want
        end
    end
    local scope = Settings.statsSearchScope or "all"
    if scope == "all" then return true end
    if scope == "self" then
        return views.clean_name(row.owner) == views.clean_name(views.source_owner_name("__self__"))
    end
    if scope == "online" then return row.ownerStatus == "live" end
    if scope == "group" then return views.is_group_member(row.owner) end
    if scope == "e3" then
        return row.ownerStatus == "live" and e3_names and e3_names[views.clean_name(row.owner)] == true
    end
    return true
end

local function row_location_allowed(row)
    if row.where == "equipped" and Settings.statsLocEquipped == false then return false end
    if row.where == "installed_aug" and Settings.statsLocInstalled == false then return false end
    if row.where == "loose_aug" and Settings.statsLocLoose == false then return false end
    if row.locationGroup == "bags" and Settings.statsLocBags == false then return false end
    if row.locationGroup == "bank" and Settings.statsLocBank == false then return false end
    return true
end

local function norm_class_name(name)
    return tostring(name or ""):lower():gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", "")
end

local function row_class_allowed(row)
    row = row or {}
    if row.allClasses then return true end
    local classes = type(row.classes) == "table" and row.classes or {}
    if #classes == 0 then
        return tostring(row.depth or "") ~= "full"
    end
    local owner = norm_class_name(row.ownerClass)
    if owner == "" then return true end
    for _, class_name in ipairs(classes) do
        if norm_class_name(class_name) == owner then return true end
    end
    return false
end

local function matches_search(row, needle)
    if needle == "" then return true end
    local hay = table.concat({
        row.name or "",
        row.owner or "",
        row.location or "",
        row.installedIn or "",
        row.ownerClass or "",
        row.ownerStatus or "",
    }, " "):lower()
    return hay:find(needle, 1, true) ~= nil
end

local function controls_key(index_version)
    return table.concat({
        tostring(index_version or 0),
        tostring(Settings.statsViewMode or ""),
        tostring(Settings.statsSelectedStat or ""),
        tostring(Settings.statsAugsOnly),
        tostring(Settings.statsSourceScope or ""),
        tostring(Settings.statsSearchScope or ""),
        tostring(Settings.statsSourceKey or ""),
        tostring(Settings.statsLoadoutList or ""),
        tostring(Settings.statsSortKey or ""),
        tostring(Settings.statsSortDesc),
        tostring(Settings.statsLocEquipped),
        tostring(Settings.statsLocInstalled),
        tostring(Settings.statsLocLoose),
        tostring(Settings.statsLocBags),
        tostring(Settings.statsLocBank),
        tostring(search_text or ""),
    }, "\1")
end

local function owner_label(row)
    local cls = views.class_abbrev(row.ownerClass or "")
    if cls and cls ~= "" then return string.format("%s (%s)", row.owner or "?", cls) end
    return row.owner or "?"
end

local function sort_text(v)
    return tostring(v or ""):lower()
end

local function compare_text(a, b, desc)
    if a == b then return nil end
    if desc then return a > b end
    return a < b
end

local function row_stat_value(row, stat_key)
    local value = row and row.stats and tonumber(row.stats[stat_key]) or 0
    if value ~= value then return 0 end
    return value
end

local function row_sort_value(row, sort_key, stat_key)
    if sort_key == "value" then return row_stat_value(row, stat_key), true end
    if sort_key == "item" then return sort_text(row and row.name), false end
    if sort_key == "owner" then return sort_text(owner_label(row or {})), false end
    if sort_key == "location" then return sort_text(row and row.location), false end
    if sort_key == "installedIn" then return sort_text(row and row.installedIn), false end
    return row_stat_value(row, stat_key), true
end

local function make_sort_wrapper(row, index, stat_key, sort_key)
    local primary, number_sort = row_sort_value(row, sort_key, stat_key)
    return {
        row = row,
        index = index,
        primary = primary,
        numberSort = number_sort,
        stat = row_stat_value(row, stat_key),
        loc = ui_table.location_sort_value(row),
        owner = sort_text(row and row.owner),
        name = sort_text(row and row.name),
        source = sort_text(row and row.sourceKey),
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
            local fallback = ui_table.compare_number(a.stat, b.stat, true)
            if fallback ~= nil then return fallback end
        end
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

local function sort_stat_rows(rows, stat_key)
    local sort_key = Settings.statsSortKey or "value"
    local desc = Settings.statsSortDesc ~= false
    local wrappers = {}
    for i, row in ipairs(rows or {}) do wrappers[i] = make_sort_wrapper(row, i, stat_key, sort_key) end
    sort_wrappers(wrappers, sort_key, desc)
    for i, wrapped in ipairs(wrappers) do rows[i] = wrapped.row end
end

local function snapshot_rows(mode)
    local ok_loadout, loadout = pcall(require, 'loadout')
    if not ok_loadout or not loadout then return {} end
    if mode == "plan" then
        local list_id = Settings.statsLoadoutList or ""
        if list_id == "" then list_id = loadout.selected_list_id() or "" end
        Settings.statsLoadoutList = list_id
        if list_id == "" then return {} end
        return loadout.index_rows(list_id) or {}
    end
    local source_key = views.validate_source_key(Settings.statsSourceKey or "__self__")
    local snap = views.source_snapshot(source_key)
    return loadout.snapshot_index_rows(snap) or {}
end

local function visible_rows()
    local stat_key = Settings.statsSelectedStat or "shielding"
    local needle = tostring(search_text or ""):lower()
    local mode = view_mode()

    if mode == "character" or mode == "plan" then
        local cache_id = mode == "plan" and (Settings.statsLoadoutList or "") or (Settings.statsSourceKey or "__self__")
        local key = controls_key(cache_id)
        if filtered_key == key then return filtered_rows end
        local out = {}
        for _, row in ipairs(snapshot_rows(mode)) do
            local value = row.stats and tonumber(row.stats[stat_key]) or 0
            if value and value > 0 and matches_search(row, needle) then
                out[#out + 1] = row
            end
        end
        sort_stat_rows(out, stat_key)
        filtered_rows = out
        filtered_key = key
        return filtered_rows
    end

    local all_rows, index_version = item_index.get(false)
    local key = controls_key(index_version)
    if filtered_key == key then return filtered_rows end

    local e3_names = Settings.statsSearchScope == "e3" and views.e3_connected_names() or nil
    local out = {}

    for _, row in ipairs(all_rows or {}) do
        local value = row.stats and tonumber(row.stats[stat_key]) or 0
        if value and value > 0
            and (not Settings.statsAugsOnly or row.kind == "aug")
            and row_class_allowed(row)
            and row_source_allowed(row, e3_names)
            and row_location_allowed(row)
            and matches_search(row, needle)
        then
            out[#out + 1] = row
        end
    end

    sort_stat_rows(out, stat_key)
    filtered_rows = out
    filtered_key = key
    return filtered_rows
end

local function draw_owner_totals(rows)
    local stat_key = Settings.statsSelectedStat or "shielding"
    local totals, order = {}, {}
    for _, row in ipairs(rows or {}) do
        local owner = owner_label(row)
        local value = row_stat_value(row, stat_key)
        if value > 0 then
            if not totals[owner] then order[#order + 1] = owner; totals[owner] = 0 end
            totals[owner] = totals[owner] + value
        end
    end
    table.sort(order, function(a, b)
        local av, bv = totals[a] or 0, totals[b] or 0
        if av ~= bv then return av > bv end
        return tostring(a) < tostring(b)
    end)
    if #order == 0 then return end
    local parts = {}
    for _, owner in ipairs(order) do
        parts[#parts + 1] = string.format("%s: %s", owner, stat_defs.format_value(stat_key, totals[owner] or 0))
    end
    col_text(Theme.section or Theme.header, stat_label(stat_key) .. " totals: " .. table.concat(parts, " | "))
end

local function draw_controls()
    draw_mode_picker()
    if view_mode() == "search" then
        ImGui.SameLine()
        draw_stat_picker()
    end
    ImGui.SameLine()
    if theme.themed_button("Refresh##stats_refresh", Theme.blue) then
        local mode = view_mode()
        if mode == "plan" then
            pcall(function() require('loadout').invalidate() end)
        elseif mode == "character" then
            pcall(function() require('snapshot').gather({ force = true, depth = require('snapshot').depth_for_settings() }) end)
        else
            item_index.refresh()
        end
        filtered_key = nil
    end
    ImGui.SameLine()
    if view_mode() == "search" and toggle_button(Settings.statsAugsOnly and "Augs Only##stats_augs_only" or "All Items##stats_augs_only", Settings.statsAugsOnly) then
        Settings.statsAugsOnly = not Settings.statsAugsOnly
        SaveSettings()
        filtered_key = nil
    end

    if view_mode() == "search" then
        ImGui.Separator()
        loc_toggle("Equipped", "statsLocEquipped")
        ImGui.SameLine()
        loc_toggle("Installed Augs", "statsLocInstalled")
        ImGui.SameLine()
        loc_toggle("Loose Augs", "statsLocLoose")
        ImGui.SameLine()
        loc_toggle("Bags", "statsLocBags")
        ImGui.SameLine()
        loc_toggle("Bank", "statsLocBank")
        ImGui.SameLine()
        ImGui.SetNextItemWidth(220.0)
        local next_search = input_text_hint("##stats_search", "Search", search_text)
        if next_search ~= search_text then
            search_text = next_search or ""
            filtered_key = nil
        end
    end
    if ImGui.NewLine then ImGui.NewLine() end
end

local function draw_breakdown_filters()
    local mode = view_mode()
    if mode == "search" then return end
    ImGui.Separator()
    draw_stat_picker()
    ImGui.SameLine()
    ImGui.SetNextItemWidth(260.0)
    local next_search = input_text_hint("##stats_breakdown_search", "Search item breakdown", search_text)
    if next_search ~= search_text then
        search_text = next_search or ""
        filtered_key = nil
    end
end

local function source_location_text(row)
    if not row then return "" end
    local parts = {
        owner_label(row),
        row.location or "-",
    }
    if row.installedIn and row.installedIn ~= "" then
        parts[#parts + 1] = "installed in " .. row.installedIn
    end
    return table.concat(parts, " | ")
end

local function sort_label(label, key)
    if (Settings.statsSortKey or "value") ~= key then return label end
    return label .. (Settings.statsSortDesc ~= false and " v" or " ^")
end

local function set_sort(key, default_desc)
    if (Settings.statsSortKey or "value") == key then
        Settings.statsSortDesc = not (Settings.statsSortDesc ~= false)
    else
        Settings.statsSortKey = key
        Settings.statsSortDesc = default_desc ~= false
    end
    SaveSettings()
    filtered_key = nil
end

local function draw_sort_header(col, label, key, default_desc)
    ImGui.TableSetColumnIndex(col)
    if views.selectable_centered(sort_label(label, key), "##stats_sort_" .. key) then
        set_sort(key, default_desc)
    end
end

local function draw_headers()
    ImGui.TableNextRow()
    draw_sort_header(0, "Value", "value", true)
    draw_sort_header(1, "Item/Aug", "item", false)
    draw_sort_header(2, "Owner", "owner", false)
    draw_sort_header(3, "Location", "location", false)
    draw_sort_header(4, "Installed In", "installedIn", false)
end

local function begin_stats_table()
    return views.begin_scroll_table("StatsRows", 5, views.scroll_table_flags(), 28.0, 220.0)
end

local function draw_rows(rows)
    local stat_key = Settings.statsSelectedStat or "shielding"
    local total = #(rows or {})
    local limit = Settings.statsShowAllRows and total or math.min(total, Settings.statsRowLimit or 300)
    if begin_stats_table() then
        ImGui.TableSetupColumn("Value", ImGuiTableColumnFlags.WidthFixed, 70.0)
        ImGui.TableSetupColumn("Item/Aug", ImGuiTableColumnFlags.WidthStretch, 2.0)
        ImGui.TableSetupColumn("Owner", ImGuiTableColumnFlags.WidthFixed, 130.0)
        ImGui.TableSetupColumn("Location", ImGuiTableColumnFlags.WidthStretch, 1.5)
        ImGui.TableSetupColumn("Installed In", ImGuiTableColumnFlags.WidthStretch, 1.5)
        pcall(function() ImGui.TableSetupScrollFreeze(0, 1) end)
        draw_headers()

        for i = 1, limit do
            local row = rows[i]
            local value = row.stats and tonumber(row.stats[stat_key]) or 0
            ImGui.TableNextRow()

            ImGui.TableSetColumnIndex(0)
            local val_color = i <= 3 and (Theme.valueTop or Theme.gold) or (Theme.value or Theme.green)
            views.col_text_centered(val_color, stat_defs.format_value(stat_key, value), 70.0)

            ImGui.TableSetColumnIndex(1)
            local name_color = row.kind == "aug" and (Theme.aug or Theme.green) or Theme.item
            if row.unresolved then name_color = Theme.amber end
            item_actions.draw_name(row.name or "?", name_color, "stats_item_" .. tostring(i) .. "_" .. tostring(row.sourceKey or ""), row.id, item_actions.context_opts({
                sourceLocation = source_location_text(row),
            }, row))

            ImGui.TableSetColumnIndex(2)
            views.draw_owner_cell(row)

            ImGui.TableSetColumnIndex(3)
            col_text(theme.location_color(row.locationGroup, row.location), row.location or "-")

            ImGui.TableSetColumnIndex(4)
            if row.installedIn and row.installedIn ~= "" then
                item_actions.draw_name(row.installedIn, Theme.item, "stats_host_" .. tostring(i) .. "_" .. tostring(row.installedInId or ""), row.installedInId)
            else
                col_text(Theme.placeholder or Theme.dim, "-")
            end
        end

        ImGui.EndTable()
    end
    if limit < total then
        col_text(Theme.dim, string.format("Showing top %d of %d rows.", limit, total))
        ImGui.SameLine()
        if toggle_button("Show All##stats_show_all_rows", false) then
            Settings.statsShowAllRows = true
            SaveSettings()
        end
    elseif total > (Settings.statsRowLimit or 300) then
        col_text(Theme.dim, string.format("Showing all %d rows.", total))
        ImGui.SameLine()
        if toggle_button("Top " .. tostring(Settings.statsRowLimit or 300) .. "##stats_top_rows", true) then
            Settings.statsShowAllRows = false
            SaveSettings()
        end
    end
end

local function draw_stats_content()
    ImGui.Spacing()
    local mode = view_mode()
    local ok_loadout, loadout = pcall(require, 'loadout')

    if mode == "character" and ok_loadout and loadout and loadout.draw_worn_summary then
        loadout.draw_worn_summary(Settings.statsSourceKey or "__self__")
    elseif mode == "plan" and ok_loadout and loadout then
        local list_id = Settings.statsLoadoutList or ""
        if list_id == "" then list_id = loadout.selected_list_id() or "" end
        Settings.statsLoadoutList = list_id
        if list_id == "" then
            col_text(Theme.amber, "No loadout lists yet. Create one on TurboBiS or in Setup.")
        else
            loadout.draw_summary(list_id)
        end
    end

    draw_breakdown_filters()
    local rows = visible_rows()
    if mode == "character" or mode == "plan" then
        col_text(Theme.dim, string.format("Item breakdown for %s - pick another stat above to filter rows (right-click items for Inspect / Alla)", stat_label(Settings.statsSelectedStat)))
    else
        col_text(Theme.dim, string.format("%d cached %s row%s with %s > 0",
            #rows,
            Settings.statsAugsOnly and "augment" or "item/augment",
            #rows == 1 and "" or "s",
            stat_label(Settings.statsSelectedStat)))
    end
    if Engine.debug then
        local summary = item_index.get_summary()
        local stat_key = Settings.statsSelectedStat or "shielding"
        col_text(Theme.dim, string.format("Index: %d total rows | %d with any supported stat | %d with %s | index v%d / data v%d",
            summary.total or 0,
            summary.withAnyStat or 0,
            (summary.byStat and summary.byStat[stat_key]) or 0,
            stat_label(stat_key),
            item_index.version or 0,
            Store.content_version or 0))
    end
    ImGui.Spacing()

    if #rows == 0 then
        local empty
        if mode == "plan" then
            empty = "No loadout items match this stat or search. Add slotted entries on TurboBiS, or pick another list."
        elseif mode == "character" then
            empty = "No worn items match this stat or search."
        else
            empty = "No cached rows match the current stat and filters."
        end
        col_text(Theme.placeholder or Theme.dim, empty)
        return
    end

    draw_owner_totals(rows)
    draw_rows(rows)
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
                return ImGui.BeginChild("##stats_content_scroll", ImVec2(0, 0), false, 0)
            end
            return ImGui.BeginChild("##stats_content_scroll", 0, 0, false, 0)
        end)
        if ok then
            child_began = true
            child_open = (open ~= false)
        end
    end
    if child_open then draw_stats_content() end
    if child_began and ImGui.EndChild then ImGui.EndChild() end
end

function M.set_search(text)
    search_text = tostring(text or "")
    filtered_key = nil
end

return M
