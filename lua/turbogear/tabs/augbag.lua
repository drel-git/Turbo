-- TurboGear/tabs/augbag.lua
-- Stored Augs tab: loose augments and augments installed in stored gear.

local ImGui = require('ImGui')
local theme = require('theme')
local Theme, col_text, toggle_button = theme.Theme, theme.col_text, theme.toggle_button
local cfg = require('config')
local Settings, SaveSettings = cfg.Settings, cfg.SaveSettings
local views = require('views')
local item_actions = require('item_actions')

local M = {}

local aug_mode, aug_filter = "loose", ""

local LOC_FILTERS = {
    { key = "all", label = "All" },
    { key = "bags", label = "Bags" },
    { key = "bank", label = "Bank" },
}

local MODE_OPTIONS = {
    { key = "single", label = "Character" },
    { key = "group", label = "Group" },
    { key = "e3", label = "E3 Online" },
}

local SORTABLE_SINGLE_COLS = {
    { key = "loc", label = "Loc" },
    { key = "where", label = "Where" },
    { key = "name", label = "Augment" },
}

local function mode_label()
    for _, opt in ipairs(MODE_OPTIONS) do if opt.key == Settings.storedViewMode then return opt.label end end
    return "Character"
end

local function draw_mode_picker()
    ImGui.Text("Viewing:"); ImGui.SameLine(); ImGui.SetNextItemWidth(110.0)
    if ImGui.BeginCombo("##stored_mode", mode_label()) then
        for _, opt in ipairs(MODE_OPTIONS) do
            if ImGui.Selectable(opt.label .. "##stored_mode_" .. opt.key, Settings.storedViewMode == opt.key) then
                Settings.storedViewMode = opt.key
                SaveSettings()
            end
        end
        ImGui.EndCombo()
    end
end

local function stored_pool(snap)
    local pool = {}
    for _, it in ipairs((snap and snap.bags) or {}) do pool[#pool+1] = it end
    for _, it in ipairs((snap and snap.bank) or {}) do pool[#pool+1] = it end
    return pool
end

local function loc_allowed(loc)
    local filter = Settings.storedLocFilter or "all"
    if filter == "bags" then return loc == "Bags" end
    if filter == "bank" then return loc == "Bank" end
    return true
end

local function collect_rows(snap, mode, match)
    local rows = {}
    for _, it in ipairs(stored_pool(snap)) do
        if not loc_allowed(it.location or "") then goto continue_item end
        if mode == "loose" then
            if (it.augType or 0) > 0 and match(it.name) then
                rows[#rows+1] = {
                    name = it.name or "?",
                    id = it.id,
                    loc = it.location or "",
                    where = it.where or "",
                    locationGroup = (it.location == "Bank") and "bank" or "bags",
                    slotid = it.slotid,
                    slotname = it.slotname,
                    owner = snap and snap.name or nil,
                    host = nil,
                    host_id = nil,
                }
            end
        else
            local filled, names = {}, {}
            for _, a in ipairs(it.augs or {}) do
                if not a.empty then filled[#filled+1] = a; names[#names+1] = a.name end
            end
            if #filled > 0 and (match(it.name) or match(table.concat(names, " "))) then
                for _, a in ipairs(filled) do
                    rows[#rows+1] = {
                        name = a.name or "?",
                        id = a.id,
                        loc = it.location or "",
                        where = "installed_aug",
                        locationGroup = "installed_aug",
                        host = it.name or "?",
                        host_id = it.id,
                    }
                end
            end
        end
        ::continue_item::
    end
    return rows
end

local function loc_color(loc)
    return theme.location_color(nil, loc)
end

local function draw_loc_filter()
    for i, opt in ipairs(LOC_FILTERS) do
        if i > 1 then ImGui.SameLine() end
        local active = (Settings.storedLocFilter or "all") == opt.key
        local color = active and ((opt.key == "bags" and Theme.bag) or (opt.key == "bank" and Theme.bank) or Theme.blue) or Theme.steel
        if theme.themed_button(opt.label .. "##stored_loc_" .. opt.key, color) then
            Settings.storedLocFilter = opt.key
            SaveSettings()
        end
    end
end

local function draw_loc_legend()
    ImGui.SameLine()
    col_text(loc_color("Bags"), "Bag locations")
    ImGui.SameLine()
    col_text(loc_color("Bank"), "Bank locations")
end

local function input_text_hint(id, hint, value)
    if ImGui.InputTextWithHint then
        local ok, rv = pcall(ImGui.InputTextWithHint, id, hint, value or "")
        if ok then return rv or "" end
    end
    return ImGui.InputText(id, value or "") or ""
end

local function sort_label(label, key)
    if (Settings.storedSortKey or "scan") ~= key then return label end
    return label .. ((Settings.storedSortDesc == true) and " v" or " ^")
end

local function set_sort(key)
    if (Settings.storedSortKey or "scan") == key then
        Settings.storedSortDesc = not (Settings.storedSortDesc == true)
    else
        Settings.storedSortKey = key
        Settings.storedSortDesc = false
    end
    SaveSettings()
end

local function draw_single_headers()
    ImGui.TableNextRow()
    for idx, col in ipairs(SORTABLE_SINGLE_COLS) do
        ImGui.TableSetColumnIndex(idx - 1)
        if ImGui.Selectable(sort_label(col.label, col.key) .. "##stored_sort_" .. col.key, false) then
            set_sort(col.key)
        end
    end
end

local function sort_single_rows(rows)
    rows = rows or {}
    local key = Settings.storedSortKey or "scan"
    if key == "scan" or key == "" then return rows end
    local desc = Settings.storedSortDesc == true
    table.sort(rows, function(a, b)
        local av = tostring((key == "loc" and a.loc) or (key == "where" and a.where) or a.name or ""):lower()
        local bv = tostring((key == "loc" and b.loc) or (key == "where" and b.where) or b.name or ""):lower()
        if av ~= bv then
            if desc then return av > bv end
            return av < bv
        end
        local an = tostring(a.name or ""):lower()
        local bn = tostring(b.name or ""):lower()
        if an ~= bn then return an < bn end
        return tostring(a.where or ""):lower() < tostring(b.where or ""):lower()
    end)
    return rows
end

local function draw_single(snap, match)
    local shown = 0
    if views.begin_scroll_table("StoredAugSingle", 3, views.scroll_table_flags(), 8.0, 220.0) then
        local ok, err = pcall(function()
            ImGui.TableSetupColumn("Loc", ImGuiTableColumnFlags.WidthFixed, 60.0)
            ImGui.TableSetupColumn("Where", ImGuiTableColumnFlags.WidthStretch, 1.4)
            ImGui.TableSetupColumn("Augment", ImGuiTableColumnFlags.WidthStretch, 3.0)
            pcall(function() ImGui.TableSetupScrollFreeze(0, 1) end)
            draw_single_headers()
            for _, row in ipairs(sort_single_rows(collect_rows(snap, aug_mode, match))) do
                shown = shown + 1
                ImGui.TableNextRow()
                ImGui.TableSetColumnIndex(0); col_text(loc_color(row.loc), row.loc)
                ImGui.TableSetColumnIndex(1)
                if row.host then
                    ImGui.Text(tostring(row.where or "") .. " / "); ImGui.SameLine()
                    item_actions.draw_name(row.host, Theme.item, "stored_host_" .. tostring(shown), row.host_id)
                else
                    col_text(Theme.dim, row.where)
                end
                ImGui.TableSetColumnIndex(2); item_actions.draw_name(row.name, Theme.aug or Theme.green, "stored_aug_single_" .. tostring(shown), row.id, item_actions.context_opts(nil, row))
            end
        end)
        ImGui.EndTable()
        if not ok then col_text(Theme.amber, "Stored aug table render issue: " .. tostring(err)) end
    end
    if shown == 0 then
        col_text(Theme.dim, aug_mode == "loose" and "No loose augments in bags or bank." or "No stored gear with installed augments.")
    end
end

local function draw_roster(scope, match)
    local keys = views.scoped_source_keys(scope)
    local by_key, names, seen, ids, counts = {}, {}, {}, {}, {}
    for _, key in ipairs(keys) do
        local snap = views.source_snapshot(key)
        by_key[key] = collect_rows(snap, aug_mode, match)
        for _, row in ipairs(by_key[key]) do
            local k = tostring(row.name or ""):lower()
            if k ~= "" and not seen[k] then seen[k] = true; names[#names+1] = row.name end
            if k ~= "" and not ids[k] then ids[k] = row.id end
            if k ~= "" then counts[k] = (counts[k] or 0) + 1 end
        end
    end
    table.sort(names, function(a, b) return tostring(a):lower() < tostring(b):lower() end)
    if #keys == 0 then col_text(Theme.amber, "No characters match this view yet."); return end
    if views.begin_scroll_table("StoredAugRoster", 2 + #keys, views.scroll_table_flags(), 8.0, 220.0) then
        local ok, err = pcall(function()
            ImGui.TableSetupColumn("Augment", ImGuiTableColumnFlags.WidthFixed, 300.0)
            ImGui.TableSetupColumn("Count", ImGuiTableColumnFlags.WidthFixed, 54.0)
            for _, key in ipairs(keys) do ImGui.TableSetupColumn("##stored_col_" .. tostring(key), ImGuiTableColumnFlags.WidthStretch, 1.0) end
            pcall(function() ImGui.TableSetupScrollFreeze(2, 1) end)
            local headers = { "Augment", "Count" }
            for _, key in ipairs(keys) do headers[#headers + 1] = views.roster_column_label(key) end
            views.table_headers_centered(headers)
            for _, name in ipairs(names) do
                ImGui.TableNextRow()
                ImGui.TableSetColumnIndex(0); item_actions.draw_name(name, Theme.aug or Theme.green, "stored_aug_name_" .. tostring(name), ids[tostring(name or ""):lower()])
                ImGui.TableSetColumnIndex(1); views.col_text_centered(Theme.value or Theme.green, tostring(counts[tostring(name or ""):lower()] or 0), 54.0)
                for cidx, key in ipairs(keys) do
                    ImGui.TableSetColumnIndex(cidx + 1)
                    local places = {}
                    for _, row in ipairs(by_key[key] or {}) do
                        if row.name == name then places[#places+1] = row end
                    end
                    if #places == 0 then
                        views.placeholder("-")
                    else
                        for _, row in ipairs(places) do
                            col_text(loc_color(row.loc), row.where)
                            if row.host then
                                ImGui.SameLine()
                                ImGui.Text("/"); ImGui.SameLine()
                                item_actions.draw_name(row.host, Theme.item, "stored_roster_host_" .. tostring(cidx) .. "_" .. tostring(name), row.host_id)
                            end
                        end
                    end
                end
            end
        end)
        ImGui.EndTable()
        if not ok then col_text(Theme.amber, "Stored aug roster render issue: " .. tostring(err)) end
    end
end

function M.draw()
    if toggle_button("Loose Augs", aug_mode == "loose") and aug_mode ~= "loose" then aug_mode = "loose" end
    ImGui.SameLine()
    if toggle_button("In Stored Gear", aug_mode == "slotted") and aug_mode ~= "slotted" then aug_mode = "slotted" end
    ImGui.SameLine()
    draw_loc_filter()
    ImGui.SameLine(); ImGui.SetNextItemWidth(200.0)
    aug_filter = input_text_hint("##augfilter", "Search", aug_filter or "")
    ImGui.NewLine()
    draw_mode_picker()
    local snap
    if Settings.storedViewMode == "single" then
        ImGui.SameLine()
        local old = Settings.storedViewKey
        Settings.storedViewKey = views.draw_source_picker("##stored_source", Settings.storedViewKey or "__self__", 220.0)
        if old ~= Settings.storedViewKey then SaveSettings() end
        snap = views.source_snapshot(Settings.storedViewKey)
    end
    ImGui.SameLine()
    draw_loc_legend()
    ImGui.Separator()

    ImGui.Spacing()

    local needle = (aug_filter or ""):lower()
    local function match(s) return needle == "" or (s and tostring(s):lower():find(needle, 1, true) ~= nil) end
    if Settings.storedViewMode == "single" then
        if not snap then col_text(Theme.amber, "No data yet - waiting for sync."); return end
        draw_single(snap, match)
    else
        draw_roster(Settings.storedViewMode == "e3" and "e3" or "group", match)
    end
end

return M
