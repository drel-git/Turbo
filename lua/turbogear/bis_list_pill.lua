-- Global BiS List pill (mode + custom lists + catalog visibility).
-- Kept out of tabs/bis.lua to stay under LuaJIT's 200-local main-chunk limit.
--
-- Same OpenPopup pattern as Characters pill (themed_button + BeginPopup).

local ImGui = require('ImGui')
local theme = require('theme')
local Theme, col_text, themed_button = theme.Theme, theme.col_text, theme.themed_button
local cfg = require('config')
local Settings, SaveSettings = cfg.Settings, cfg.SaveSettings
local bis = require('bis')
local catalog = require('bis_catalog')

local M = {}

-- Bump when this file changes so /lua run turbogear reloads a cached require().
M.VERSION = 12

-- Gated click/popup diagnostics (toggle: /tgear pilldebug). Prints one line
-- when the pill click registers and one when the popup actually opens, so an
-- "unclickable pill" report can be bisected: no CLICK line = input never
-- reaches the button (overlap/blocker); CLICK without OPEN = popup killed
-- same-frame (ID or CloseCurrentPopup issue).
local function pill_debug(msg)
    if Settings.debugListPill == true then
        print("[TurboGear][listpill] " .. tostring(msg))
    end
end

-- Open-state and logging state live in _G so a module reload (hot-reload shim,
-- stale-version re-require) cannot reset them and silently close the panel.
local function panel_is_open() return rawget(_G, "__TGListPillOpen") == true end
local function set_panel_open(v) rawset(_G, "__TGListPillOpen", v == true) end

if Settings.debugListPill == true then
    print("[TurboGear][listpill] module loaded (VERSION 9). If this line repeats, something is reloading the module every frame.")
end

local function truncate_pill_label(text, max_chars)
    text = tostring(text or "")
    max_chars = tonumber(max_chars) or 22
    if #text <= max_chars then return text end
    return text:sub(1, math.max(1, max_chars - 1)) .. "..."
end

local function list_pill_label()
    return "Click Here to choose your pages & lists"
end

local function checkbox_value(label, checked)
    if not ImGui.Checkbox then return checked, false end
    local rv1, rv2 = ImGui.Checkbox(label, checked and true or false)
    if type(rv2) == "boolean" then return rv1 and true or false, rv2 end
    if type(rv1) == "boolean" and rv1 ~= checked then return rv1, true end
    return checked, false
end

-- Manual panel. The BeginPopup variant died exactly one frame after OpenPopup
-- (verified via /tgear pilldebug); a manually-managed window with _G-backed
-- open-state is immune to both popup semantics and module reloads.
local close_requested = false

local function close_popup()
    close_requested = true
end

local function ensure_visible_catalog(api)
    if api and api.ensure_visible_catalog then
        api.ensure_visible_catalog()
        return
    end
    if tostring(Settings.bisListsTab or "") == "my" then return end
    local id = tostring(Settings.bisCatalogList or "")
    if id ~= "" and catalog.list(id) and not catalog.list_hidden(id) then return end
    local first = catalog.first_visible_list_button()
    if first and first.rec and first.rec.id then
        Settings.bisCatalogList = first.rec.id
        Settings.bisCatalogGroup = first.group and first.group.name or ""
        if SaveSettings then SaveSettings() end
    end
end

local function enter_catalog_mode(api)
    Settings.bisListsTab = "catalog"
    Settings.bisListMode = "catalog"
    ensure_visible_catalog(api)
    if api and api.invalidate_roster then api.invalidate_roster() end
    if SaveSettings then SaveSettings() end
    close_popup()
end

local function enter_manage_lists()
    Settings.bisListsTab = "edit"
    if SaveSettings then SaveSettings() end
    close_popup()
end

local function enter_custom_list(list_id, api)
    list_id = tostring(list_id or "")
    if list_id == "" then return end
    if api and api.clear_filter then api.clear_filter() end
    Settings.bisListsTab = "my"
    Settings.bisListMode = "user"
    Settings.bisSelectedList = list_id
    if api and api.select_user_list then
        api.select_user_list(list_id)
    end
    Settings.bisListsTab = "my"
    Settings.bisListMode = "user"
    if api and api.invalidate_roster then api.invalidate_roster() end
    if SaveSettings then SaveSettings() end
    close_popup()
end

local function can_copy_catalog(api)
    if Settings.bisShowUserLists == false then return false end
    if tostring(Settings.bisListsTab or "catalog") == "edit" then return false end
    if tostring(Settings.bisListMode or "") == "user" then return false end
    local id = ""
    if api and api.selected_catalog_id then
        id = tostring(api.selected_catalog_id() or "")
    else
        id = tostring(Settings.bisCatalogList or "")
    end
    return id ~= ""
end

local function draw_list_pill_panel(api)
    local tab = tostring(Settings.bisListsTab or "catalog")
    local in_edit = tab == "edit"
    local in_user = tab == "my"
    local in_catalog = not in_edit and not in_user

    col_text(Theme.dim, "MODE")
    -- MQ's Selectable returns true EVERY frame for a row drawn selected=true
    -- (not just on click). Guard with "if not selected", same as characters.lua,
    -- otherwise the active mode row fires each frame and instantly closes the
    -- panel ("panel CLOSED (entry selected)" on open).
    if ImGui.Selectable("BiS Catalog##tg_list_pill_mode_catalog", in_catalog) then
        if not in_catalog then enter_catalog_mode(api) end
    end
    if ImGui.Selectable("Manage Lists##tg_list_pill_mode_edit", in_edit) then
        if not in_edit then enter_manage_lists() end
    end
    if can_copy_catalog(api) and api.copy_catalog_to_custom then
        if ImGui.Selectable("Copy to Custom List##tg_list_pill_copy") then
            api.copy_catalog_to_custom()
            close_popup()
        end
        if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
            ImGui.SetTooltip("Make an editable copy of this BiS catalog for the current character/class.")
        end
    end

    if ImGui.Separator then ImGui.Separator() end
    col_text(Theme.dim, "VIEW")
    if api.is_compact and api.toggle_compact then
        local compact = api.is_compact() and true or false
        local new_v, changed = checkbox_value("Compact##tg_list_pill_compact", compact)
        if changed and new_v ~= compact then api.toggle_compact() end
        if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
            ImGui.SetTooltip(compact
                and "Compact (dense) columns on. Uncheck for full item names."
                or "Full item names on. Check for compact (dense) columns.")
        end
    end

    if ImGui.Separator then ImGui.Separator() end
    col_text(Theme.dim, "CUSTOM LISTS")
    local names = bis.list_names()
    if #names == 0 then
        col_text(Theme.dim, "No custom lists yet.")
        if ImGui.Selectable("Create / Manage Lists##tg_list_pill_create") then
            enter_manage_lists()
        end
    else
        for _, rec in ipairs(names) do
            local id = tostring(rec.id or "")
            local selected = in_user and tostring(Settings.bisSelectedList or "") == id
            local label = tostring(rec.name or id)
            if ImGui.Selectable(label .. "##tg_list_pill_custom_" .. id, selected) then
                -- Selected row returns true every frame (see MODE note): only
                -- act on rows that were not already the active list.
                if not selected then enter_custom_list(id, api) end
            end
        end
    end

    if ImGui.Separator then ImGui.Separator() end
    col_text(Theme.dim, "CATALOG TABS")
    col_text(Theme.dim, "Unchecked catalogs hide from the tab row.")
    local active_id = tostring(Settings.bisCatalogList or "")
    for _, spec in ipairs(catalog.ui_list_specs()) do
        local visible = not catalog.list_hidden(spec.id)
        local box_label = string.format("%s##tg_list_pill_vis_%s",
            tostring(spec.label or spec.id), tostring(spec.id))
        local new_vis, changed = checkbox_value(box_label, visible)
        if changed then
            local ok_hide = catalog.set_list_hidden(spec.id, not new_vis)
            if not ok_hide and not new_vis then
                if api and api.set_status then
                    api.set_status("At least one catalog tab must stay visible.")
                end
            elseif tostring(spec.id) == active_id and not new_vis then
                ensure_visible_catalog(api)
            end
        end
    end

    col_text(Theme.dim, "List mode is global (not Link Scope).")
end

--- Pill button + manually-managed dropdown panel (immune to popup closing).
function M.draw(opts, api)
    opts = type(opts) == "table" and opts or {}
    api = type(api) == "table" and api or {}

    local id = "##tg_list_pill"
    local label = list_pill_label()
    local width = tonumber(opts.width) or 0
    if width <= 0 and ImGui.CalcTextSize then
        local ok, w = pcall(ImGui.CalcTextSize, label)
        if ok then
            if type(w) == "table" then width = (tonumber(w.x or w[1]) or 140) + 28 end
            if type(w) == "number" then width = w + 28 end
        end
    end
    if width <= 0 then width = 200 end
    if width > 280 then width = 280 end

    local color = Theme.customize or Theme.listPill or Theme.steel or Theme.blue
    if themed_button(label .. id, color, width, opts.height or 22) then
        set_panel_open(not panel_is_open())
        pill_debug(panel_is_open() and "CLICK: panel opening" or "CLICK: panel closing")
    end
    local pill_hovered = ImGui.IsItemHovered and ImGui.IsItemHovered() or false
    -- Anchor the panel under the button.
    local bx, by2 = nil, nil
    if ImGui.GetItemRectMin and ImGui.GetItemRectMax then
        pcall(function()
            local x1 = select(1, ImGui.GetItemRectMin())
            local _, y2 = ImGui.GetItemRectMax()
            bx, by2 = tonumber(x1), tonumber(y2)
        end)
    end
    if pill_hovered and ImGui.SetTooltip then
        ImGui.SetTooltip("Catalog pages, custom lists, Manage Lists, compact view, and visible TurboBiS tabs.")
    end

    if close_requested then
        close_requested = false
        set_panel_open(false)
        pill_debug("panel CLOSED (entry selected)")
    end

    if panel_is_open() and ImGui.Begin then
        if ImGui.SetNextWindowPos and bx and by2 then
            pcall(ImGui.SetNextWindowPos, bx, by2 + 2)
        end
        local flags = 0
        if ImGuiWindowFlags then
            flags = (ImGuiWindowFlags.NoTitleBar or 0)
                + (ImGuiWindowFlags.NoResize or 0)
                + (ImGuiWindowFlags.AlwaysAutoResize or 0)
                + (ImGuiWindowFlags.NoSavedSettings or 0)
                + (ImGuiWindowFlags.NoCollapse or 0)
        end
        -- MQ's Begin returns (shouldDraw) or (open, shouldDraw); tolerate both.
        local a, b = ImGui.Begin("TGListPill##panel", true, flags)
        local should_draw = (b == nil) and a or b
        local panel_hovered = false
        if should_draw then
            if ImGui.IsWindowHovered then
                local hf = 0
                if ImGuiHoveredFlags then
                    hf = (ImGuiHoveredFlags.RootAndChildWindows or 0)
                        + (ImGuiHoveredFlags.AllowWhenBlockedByActiveItem or 0)
                end
                panel_hovered = ImGui.IsWindowHovered(hf) or false
            end
            draw_list_pill_panel(api)
        end
        ImGui.End()
        -- Click-away closes the panel (clicking the pill toggles it instead).
        if ImGui.IsMouseClicked and (ImGui.IsMouseClicked(0) or ImGui.IsMouseClicked(1)) then
            if not panel_hovered and not pill_hovered then
                set_panel_open(false)
                pill_debug(string.format(
                    "panel CLOSED (click-away: panel_hovered=%s pill_hovered=%s should_draw=%s)",
                    tostring(panel_hovered), tostring(pill_hovered), tostring(should_draw)))
            end
        end
        if close_requested then
            close_requested = false
            set_panel_open(false)
            pill_debug("panel CLOSED (entry selected)")
        end
    end
    return true
end

return M
