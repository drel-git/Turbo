-- TurboGear/characters.lua
-- Shared "who am I looking at" control.
-- Roster: Source + Show columns + teams (BiS / Spells / Lockouts / Stats Search).
-- Primary: Source + one character (Upgrade Suggestions / Gear Inventory).
-- Picker: flat character list only (Worn / Stored / Effects / Stats Character / Focus / Empty / Compare).
-- List: loadout/list picker (Stats Plan).
-- Dual-drives existing per-tab Settings keys. Tabs keep legacy pickers as fallback.

local ImGui = require('ImGui')
local theme = require('theme')
local Theme, col_text, themed_button = theme.Theme, theme.col_text, theme.themed_button
local cfg = require('config')
local Settings, SaveSettings = cfg.Settings, cfg.SaveSettings
local roster_sets = require('roster_sets')
local views = require('views')

local M = {}

M.VIEW_ALL = roster_sets.VIEW_ALL
M.VIEW_SELECTED = roster_sets.VIEW_SELECTED
M.MODE_ROSTER = "roster"
M.MODE_PRIMARY = "primary"
M.MODE_PICKER = "picker"
M.MODE_LIST = "list"

local change_hooks = {}
local last_status = nil
local set_editor = {
    open = false,
    mode = "save",
    name = "",
    members = {},
}
local panel_save_name = ""

-- ===================== PURE HELPERS (testable) ============================ --

function M.format_pill_label(scope_label, shown, total)
    scope_label = tostring(scope_label or "")
    shown = tonumber(shown) or 0
    total = tonumber(total) or 0
    if scope_label == "" then scope_label = "Characters" end
    if total <= 0 then
        return string.format("Characters: %s", scope_label)
    end
    -- ASCII only: EQ ImGui fonts often render Unicode dashes/dots as "?".
    return string.format("Characters: %s - %d of %d", scope_label, shown, total)
end

function M.format_primary_pill_label(scope_label, char_label)
    scope_label = tostring(scope_label or "")
    char_label = tostring(char_label or "")
    if scope_label == "" then scope_label = "Source" end
    if char_label == "" then char_label = "Character" end
    return string.format("Characters: %s - %s", scope_label, char_label)
end

function M.format_picker_pill_label(char_label)
    char_label = tostring(char_label or "")
    if char_label == "" then char_label = "Character" end
    return string.format("Character: %s", char_label)
end

function M.format_list_pill_label(list_label)
    list_label = tostring(list_label or "")
    if list_label == "" then list_label = "List" end
    return string.format("List: %s", list_label)
end

function M.view_key_for_new_scope(scope)
    return tostring(scope or "") == "self" and "__self__" or M.VIEW_ALL
end

function M.normalize_scope(scope)
    scope = tostring(scope or "online")
    if scope == "e3" then return "online" end
    return scope
end

-- ===================== TAB ADAPTERS ======================================= --

local function ensure_selected_table(val)
    if type(val) ~= "table" then return {} end
    return val
end

local function make_roster_adapter(scope_key, view_key_name, selected_key, link_source, source_opts, footer)
    return {
        mode = M.MODE_ROSTER,
        get_scope = function()
            return Settings[scope_key] or "online"
        end,
        set_scope = function(scope)
            Settings[scope_key] = scope
        end,
        get_view_key = function()
            return Settings[view_key_name] or M.VIEW_ALL
        end,
        set_view_key = function(key)
            Settings[view_key_name] = key
        end,
        get_selected = function()
            Settings[selected_key] = ensure_selected_table(Settings[selected_key])
            return Settings[selected_key]
        end,
        set_selected = function(members)
            Settings[selected_key] = ensure_selected_table(members)
        end,
        link_source = link_source,
        source_opts = source_opts or {},
        footer = footer,
    }
end

-- Primary tabs: one character from a source pool (not multi-column roster).
local function make_primary_adapter(scope_key, primary_key, link_source, source_opts, footer, default_scope, on_commit)
    return {
        mode = M.MODE_PRIMARY,
        get_scope = function()
            return Settings[scope_key] or default_scope or "online"
        end,
        set_scope = function(scope)
            Settings[scope_key] = scope
        end,
        get_primary = function()
            return Settings[primary_key] or "__self__"
        end,
        set_primary = function(key)
            Settings[primary_key] = key
        end,
        get_view_key = function()
            return Settings[primary_key] or "__self__"
        end,
        set_view_key = function(key)
            Settings[primary_key] = key
        end,
        get_selected = function()
            return {}
        end,
        set_selected = function() end,
        link_source = link_source,
        source_opts = source_opts or {},
        footer = footer,
        on_commit = on_commit,
    }
end

-- Picker tabs: flat character list from All Known (no Source/teams UI).
local function make_picker_adapter(primary_key, footer, on_commit)
    return {
        mode = M.MODE_PICKER,
        get_scope = function()
            return "all"
        end,
        set_scope = function() end,
        get_primary = function()
            return Settings[primary_key] or "__self__"
        end,
        set_primary = function(key)
            Settings[primary_key] = key
        end,
        get_view_key = function()
            return Settings[primary_key] or "__self__"
        end,
        set_view_key = function(key)
            Settings[primary_key] = key
        end,
        get_selected = function()
            return {}
        end,
        set_selected = function() end,
        link_source = nil,
        source_opts = { include_offline_cache = true },
        footer = footer,
        on_commit = on_commit,
    }
end

-- List tabs: pick a user list / loadout (Stats Plan).
local function make_list_adapter(list_key, footer, on_commit)
    return {
        mode = M.MODE_LIST,
        get_scope = function()
            return "all"
        end,
        set_scope = function() end,
        get_list = function()
            return tostring(Settings[list_key] or "")
        end,
        set_list = function(id)
            Settings[list_key] = tostring(id or "")
        end,
        get_primary = function()
            return tostring(Settings[list_key] or "")
        end,
        set_primary = function(id)
            Settings[list_key] = tostring(id or "")
        end,
        get_view_key = function()
            return tostring(Settings[list_key] or "")
        end,
        set_view_key = function(id)
            Settings[list_key] = tostring(id or "")
        end,
        get_selected = function()
            return {}
        end,
        set_selected = function() end,
        link_source = nil,
        source_opts = {},
        footer = footer,
        on_commit = on_commit,
    }
end

local function force_inventory_single()
    Settings.inventoryScope = "single"
end

local function force_augs_single()
    Settings.augsViewMode = "single"
end

local function force_stored_single()
    Settings.storedViewMode = "single"
end

local function force_focus_character()
    Settings.focusSourceScope = "character"
end

local function force_empty_single()
    Settings.emptyViewMode = "single"
end

local adapters = {
    bis = make_roster_adapter(
        "bisRosterScope", "bisViewKey", "bisViewSelectedChars", "bis",
        {}, "Source + columns + teams drive this BiS roster"),
    spells = make_roster_adapter(
        "spellsRosterScope", "spellsViewKey", "spellsViewSelectedChars", "spells",
        { include_offline_cache = true }, "Source + columns + teams drive this Spells roster"),
    lockouts = make_roster_adapter(
        "lockoutsRosterScope", "lockoutsViewKey", "lockoutsViewSelectedChars", "lockouts",
        { include_offline_cache = true }, "Source + columns + teams drive this Lockouts roster"),
    stats_search = make_roster_adapter(
        "statsSearchScope", "statsSearchViewKey", "statsSearchSelectedChars", "stats_search",
        { include_offline_cache = true }, "Source + columns drive Stats Search"),
    suggestions = make_primary_adapter(
        "suggestSourceScope", "suggestTargetKey", "suggestions",
        {}, "Source + character drive Upgrade Suggestions", "all"),
    inventory = make_primary_adapter(
        "inventoryRosterScope", "inventoryViewKey", "inventory",
        { include_offline_cache = true },
        "Source = Slot Across Characters; Character = inventory view",
        "online", force_inventory_single),
    worn = make_picker_adapter(
        "augsViewKey", "Pick who Worn Augs shows", force_augs_single),
    stored = make_picker_adapter(
        "storedViewKey", "Pick who Stored Augs shows", force_stored_single),
    effects = make_picker_adapter(
        "liveStatsViewKey", "Pick who Inspect Effects shows"),
    stats_character = make_picker_adapter(
        "statsSourceKey", "Pick who Stats Character shows"),
    stats_plan = make_list_adapter(
        "statsLoadoutList", "Pick which loadout / list Plan analyzes"),
    focus = make_picker_adapter(
        "focusSourceKey", "Pick who Inspect Focus shows", force_focus_character),
    empty = make_picker_adapter(
        "emptyViewKey", "Pick who Empty sockets shows", force_empty_single),
    compare = make_picker_adapter(
        "compareKey1", "Pick Worn / Character 1 for Compare"),
}

local function adapter(tab)
    local a = adapters[tostring(tab or "")]
    if not a then error("characters: unsupported tab " .. tostring(tab)) end
    return a
end

function M.is_primary(tab)
    return adapter(tab).mode == M.MODE_PRIMARY
end

function M.is_picker(tab)
    return adapter(tab).mode == M.MODE_PICKER
end

function M.is_roster(tab)
    return adapter(tab).mode == M.MODE_ROSTER
end

function M.is_list(tab)
    return adapter(tab).mode == M.MODE_LIST
end

function M.set_on_changed(fn, hook_id)
    hook_id = tostring(hook_id or "default")
    if type(fn) == "function" then
        change_hooks[hook_id] = fn
    else
        change_hooks[hook_id] = nil
    end
end

function M.take_status()
    local s = last_status
    last_status = nil
    return s
end

local function notify_changed()
    for _, fn in pairs(change_hooks) do
        if type(fn) == "function" then fn() end
    end
end

local function set_status(msg)
    last_status = tostring(msg or "")
end

local function merge_opts(tab, opts)
    opts = type(opts) == "table" and opts or {}
    local a = adapter(tab)
    local out = {}
    for k, v in pairs(a.source_opts or {}) do out[k] = v end
    for k, v in pairs(opts) do out[k] = v end
    return out
end

local function primary_display(key)
    key = views.validate_source_key(key or "__self__")
    local snap = views.source_snapshot(key)
    if snap and snap.name and tostring(snap.name) ~= "" then
        local cls = ""
        if views.class_abbrev then
            cls = tostring(views.class_abbrev(snap.class or "") or "")
        end
        local status = tostring(snap.status or "")
        if key == "__self__" then status = "self" end
        local label = tostring(snap.name)
        if cls ~= "" then label = string.format("%s (%s)", label, cls) end
        if status ~= "" then label = string.format("%s [%s]", label, status) end
        return label
    end
    return views.source_label(key)
end

-- ===================== STATE API ========================================== --

function M.get_scope(tab)
    return M.normalize_scope(adapter(tab).get_scope())
end

function M.get_view_key(tab)
    return tostring(adapter(tab).get_view_key() or M.VIEW_ALL)
end

function M.get_primary(tab)
    local a = adapter(tab)
    if a.mode == M.MODE_LIST then
        return tostring(a.get_list() or "")
    end
    if a.mode ~= M.MODE_PRIMARY and a.mode ~= M.MODE_PICKER then
        return M.get_view_key(tab)
    end
    return views.validate_source_key(a.get_primary() or "__self__")
end

function M.get_list(tab)
    local a = adapter(tab)
    if a.mode ~= M.MODE_LIST then return "" end
    return tostring(a.get_list() or "")
end

function M.source_keys(tab, opts)
    local a = adapter(tab)
    if a.mode == M.MODE_LIST then return {} end
    if a.mode == M.MODE_PICKER then
        return roster_sets.source_keys("all", merge_opts(tab, opts))
    end
    return roster_sets.source_keys(M.get_scope(tab), merge_opts(tab, opts))
end

function M.primary_for_new_scope(tab, scope, prefer_key)
    scope = M.normalize_scope(scope)
    if scope == "self" then return "__self__" end
    local keys = roster_sets.source_keys(scope, merge_opts(tab, {}))
    prefer_key = views.validate_source_key(prefer_key or M.get_primary(tab))
    for _, key in ipairs(keys) do
        if key == prefer_key then return prefer_key end
    end
    return keys[1] or "__self__"
end

function M.active_keys(tab, opts)
    opts = merge_opts(tab, opts)
    local a = adapter(tab)
    if a.mode == M.MODE_LIST then return {} end
    if a.mode == M.MODE_PRIMARY or a.mode == M.MODE_PICKER then
        local primary = opts.view_key or M.get_primary(tab)
        primary = views.validate_source_key(primary)
        local keys = M.source_keys(tab, opts)
        for _, key in ipairs(keys) do
            if key == primary then return { primary } end
        end
        return { keys[1] or "__self__" }
    end
    local view_key = opts.view_key or M.get_view_key(tab)
    return roster_sets.active_source_keys(M.get_scope(tab), {
        view_key = view_key,
        selected = a.get_selected and a.get_selected() or nil,
        for_announce = opts.for_announce,
        include_offline_cache = opts.include_offline_cache,
    })
end

function M.apply_scope(tab, scope)
    local a = adapter(tab)
    if a.mode == M.MODE_PICKER or a.mode == M.MODE_LIST then
        -- Picker/list have a fixed pool; scope changes are ignored.
        return M.get_scope(tab)
    end
    scope = M.normalize_scope(scope)
    a.set_scope(scope)
    if scope ~= "self" and a.link_source then
        cfg.apply_linked_roster_scope(scope, a.link_source)
    end
    if a.mode == M.MODE_PRIMARY then
        a.set_primary(M.primary_for_new_scope(tab, scope))
    else
        a.set_view_key(M.view_key_for_new_scope(scope))
    end
    if type(a.on_commit) == "function" then a.on_commit() end
    if SaveSettings then SaveSettings() end
    notify_changed()
    return scope
end

function M.set_view_key(tab, key)
    local a = adapter(tab)
    if a.mode == M.MODE_LIST then
        return M.set_list(tab, key)
    end
    if a.mode == M.MODE_PRIMARY or a.mode == M.MODE_PICKER then
        return M.set_primary(tab, key)
    end
    key = tostring(key or M.VIEW_ALL)
    if key ~= M.VIEW_ALL and key ~= M.VIEW_SELECTED then
        key = views.validate_source_key(key)
    end
    if a.get_view_key() == key then return key end
    a.set_view_key(key)
    if SaveSettings then SaveSettings() end
    notify_changed()
    return key
end

function M.set_list(tab, list_id)
    local a = adapter(tab)
    if a.mode ~= M.MODE_LIST then return "" end
    list_id = tostring(list_id or "")
    local changed = a.get_list() ~= list_id
    a.set_list(list_id)
    if type(a.on_commit) == "function" then a.on_commit() end
    if changed then
        if SaveSettings then SaveSettings() end
        notify_changed()
    end
    return list_id
end

function M.set_primary(tab, key)
    local a = adapter(tab)
    if a.mode == M.MODE_LIST then
        return M.set_list(tab, key)
    end
    if a.mode ~= M.MODE_PRIMARY and a.mode ~= M.MODE_PICKER then
        return M.set_view_key(tab, key)
    end
    key = views.validate_source_key(key or "__self__")
    local changed = a.get_primary() ~= key
    a.set_primary(key)
    if type(a.on_commit) == "function" then a.on_commit() end
    if SaveSettings then SaveSettings() end
    if changed then notify_changed() end
    return key
end

local function source_member_key(key)
    local name = views.source_owner_name(key)
    local clean = roster_sets.clean_name(name)
    if clean == "" then clean = roster_sets.clean_name(key) end
    return clean, name
end

function M.apply_column_toggle(tab, key, new_checked)
    local a = adapter(tab)
    if a.mode == M.MODE_LIST then
        return M.get_list(tab)
    end
    if a.mode == M.MODE_PRIMARY or a.mode == M.MODE_PICKER then
        if new_checked then return M.set_primary(tab, key) end
        return M.get_primary(tab)
    end
    local cur = M.get_view_key(tab)
    local clean, name = source_member_key(key)
    local selected = a.get_selected()

    if cur == M.VIEW_ALL then
        selected = roster_sets.members_from_source_keys(M.source_keys(tab))
    elseif cur ~= M.VIEW_SELECTED then
        selected = {}
        local cur_clean, cur_name = source_member_key(cur)
        if cur_clean ~= "" then selected[cur_clean] = cur_name end
    end

    if clean ~= "" then
        if new_checked then
            selected[clean] = name
        else
            selected[clean] = nil
        end
    end
    a.set_selected(selected)
    a.set_view_key(M.VIEW_SELECTED)
    if SaveSettings then SaveSettings() end
    notify_changed()
    return M.VIEW_SELECTED
end

local function list_display(list_id)
    list_id = tostring(list_id or "")
    if list_id == "" then return "No lists" end
    local ok, loadout = pcall(require, "loadout")
    if ok and loadout and loadout.list_options then
        for _, rec in ipairs(loadout.list_options() or {}) do
            if tostring(rec.id) == list_id then
                return tostring(rec.name or rec.id)
            end
        end
    end
    return list_id
end

function M.pill_label(tab)
    local mode = adapter(tab).mode
    if mode == M.MODE_LIST then
        return M.format_list_pill_label(list_display(M.get_list(tab)))
    end
    if mode == M.MODE_PICKER then
        return M.format_picker_pill_label(primary_display(M.get_primary(tab)))
    end
    local scope = M.get_scope(tab)
    local label = roster_sets.scope_label(scope)
    local set_id = roster_sets.set_id(scope)
    if set_id then
        local rec = roster_sets.get_set(set_id)
        label = tostring(rec and rec.name or set_id)
    end
    if mode == M.MODE_PRIMARY then
        return M.format_primary_pill_label(label, primary_display(M.get_primary(tab)))
    end
    local total = #M.source_keys(tab)
    local shown = #M.active_keys(tab)
    return M.format_pill_label(label, shown, total)
end

-- ===================== SET EDITOR ========================================= --

local function copy_members(members)
    local out = {}
    for k, v in pairs(type(members) == "table" and members or {}) do out[k] = v end
    return out
end

local function checkbox_value(label, checked)
    if not ImGui.Checkbox then return checked, false end
    local rv1, rv2 = ImGui.Checkbox(label, checked and true or false)
    if type(rv2) == "boolean" then return rv1 and true or false, rv2 end
    if type(rv1) == "boolean" and rv1 ~= checked then return rv1, true end
    return checked, false
end

local function input_text_hint(id, hint, value)
    if ImGui.InputTextWithHint then
        local ok, rv = pcall(ImGui.InputTextWithHint, id, hint, value or "")
        if ok and rv ~= nil then return rv end
    end
    return ImGui.InputText(id, value or "") or ""
end

function M.open_set_editor(tab, mode)
    set_editor.mode = tostring(mode or "save")
    local scope = M.get_scope(tab)
    local current_id = roster_sets.set_id(scope)
    if set_editor.mode == "edit" and current_id then
        local rec = roster_sets.get_set(current_id)
        set_editor.name = tostring(rec and rec.name or current_id)
        set_editor.members = copy_members(rec and rec.members or {})
    else
        set_editor.name = ""
        local seed_keys = M.is_primary(tab) and M.source_keys(tab)
            or M.active_keys(tab, { view_key = M.get_view_key(tab) })
        set_editor.members = roster_sets.members_from_source_keys(seed_keys)
    end
    set_editor.open = true
end

function M.is_set_editor_open()
    return set_editor.open == true
end

function M.close_set_editor()
    set_editor.open = false
end

local function save_team_from_draft(tab, name, members)
    local scope, detail = roster_sets.save_set(name, members)
    if scope then
        M.apply_scope(tab, scope)
        set_status(string.format("Saved character set (%s characters).", tostring(detail or "?")))
        return true
    end
    set_status(tostring(detail or "Could not save character set."))
    return false
end

function M.draw_set_editor(tab)
    if not set_editor.open then return end

    if ImGui.Separator then ImGui.Separator() end
    col_text(Theme.header or Theme.item, set_editor.mode == "edit" and "Edit Team" or "Save Team")
    ImGui.SameLine()
    col_text(Theme.dim, "Name and select characters.")
    ImGui.SetNextItemWidth(240.0)
    set_editor.name = input_text_hint("##tg_chars_set_name", "Team name...", set_editor.name)

    local rows = roster_sets.known_character_rows()
    if #rows == 0 then
        col_text(Theme.dim, "No known characters yet.")
    else
        for _, row in ipairs(rows) do
            local checked = set_editor.members[row.clean] ~= nil
            local label = string.format("%s%s##tg_chars_set_member_%s",
                tostring(row.name or "?"),
                row.status ~= "" and (" [" .. tostring(row.status) .. "]") or "",
                tostring(row.clean or row.key))
            local new_checked, changed = checkbox_value(label, checked)
            if changed then
                if new_checked then
                    set_editor.members[row.clean] = row.name
                else
                    set_editor.members[row.clean] = nil
                end
            end
        end
    end

    if themed_button("Save##tg_chars_set_save", Theme.blue, 72, 22) then
        if save_team_from_draft(tab, set_editor.name, set_editor.members) then
            set_editor.open = false
        end
    end
    ImGui.SameLine()
    if themed_button("Cancel##tg_chars_set_cancel", Theme.steel, 76, 22) then
        set_editor.open = false
    end
end

-- ===================== PILL / PANEL UI ==================================== --

local function column_checked(tab, key, view_key)
    view_key = view_key or M.get_view_key(tab)
    if view_key == M.VIEW_ALL then return true end
    if view_key == key then return true end
    if view_key == M.VIEW_SELECTED then
        local clean = source_member_key(key)
        local selected = adapter(tab).get_selected()
        return clean ~= "" and selected[clean] ~= nil
    end
    return false
end

local function draw_character_list(tab, id_prefix)
    local primary_key = M.get_primary(tab)
    local keys = M.source_keys(tab)
    if #keys == 0 then
        col_text(Theme.dim, "No known characters yet.")
        return
    end
    local found = false
    for _, key in ipairs(keys) do
        if key == primary_key then found = true; break end
    end
    if not found then
        M.set_primary(tab, keys[1])
        primary_key = keys[1]
    end
    for _, key in ipairs(keys) do
        local snap = views.source_snapshot(key)
        local display = snap and (snap.name or views.source_label(key)) or views.source_label(key)
        local status = snap and tostring(snap.status or "") or ""
        if key == "__self__" then status = "self" end
        local selected = key == primary_key
        local row_label = string.format("%s%s##%s_char_%s",
            tostring(display),
            status ~= "" and (" [" .. status .. "]") or "",
            id_prefix,
            tostring(key))
        if ImGui.Selectable(row_label, selected) then
            if not selected then M.set_primary(tab, key) end
        end
    end
end

function M.draw_panel(tab, opts)
    opts = type(opts) == "table" and opts or {}
    local id_prefix = tostring(opts.id_prefix or ("tg_chars_" .. tostring(tab)))
    local mode = adapter(tab).mode

    if mode == M.MODE_LIST then
        col_text(Theme.dim, "LIST")
        local ok, loadout = pcall(require, "loadout")
        local lists = (ok and loadout and loadout.list_options and loadout.list_options()) or {}
        local cur = M.get_list(tab)
        if #lists == 0 then
            col_text(Theme.dim, "No custom lists yet.")
        else
            if cur == "" then
                M.set_list(tab, tostring(lists[1].id or ""))
                cur = M.get_list(tab)
            end
            for _, rec in ipairs(lists) do
                local id = tostring(rec.id or "")
                local selected = id == cur
                local row_label = string.format("%s##%s_list_%s",
                    tostring(rec.name or id), id_prefix, id)
                if ImGui.Selectable(row_label, selected) then
                    if not selected then M.set_list(tab, id) end
                end
            end
        end
        col_text(Theme.dim, tostring(opts.footer or adapter(tab).footer
            or "Pick a list for this tab"))
        return
    end

    if mode == M.MODE_PICKER then
        col_text(Theme.dim, "CHARACTER")
        draw_character_list(tab, id_prefix)
        col_text(Theme.dim, tostring(opts.footer or adapter(tab).footer
            or "Pick one character for this tab"))
        return
    end

    -- Migrate legacy e3 scope if still present.
    if tostring(adapter(tab).get_scope()) == "e3" then
        M.apply_scope(tab, "online")
    end

    local cur_scope = M.get_scope(tab)
    local primary = mode == M.MODE_PRIMARY
    col_text(Theme.dim, "SOURCE")
    for _, opt in ipairs(roster_sets.builtin_options()) do
        if opt.key ~= "e3" then
            local selected = cur_scope == opt.key
            if ImGui.Selectable(opt.label .. "##" .. id_prefix .. "_src_" .. opt.key, selected) then
                if not selected then M.apply_scope(tab, opt.key) end
            end
        end
    end
    local sets = roster_sets.list_sets()
    if #sets > 0 then
        col_text(Theme.dim, "-- saved teams --")
        for _, rec in ipairs(sets) do
            local selected = cur_scope == rec.key
            local label = string.format("%s (%d)##%s_src_set_%s",
                rec.label, rec.count or 0, id_prefix, rec.id)
            if ImGui.Selectable(label, selected) then
                if not selected then M.apply_scope(tab, rec.key) end
            end
        end
    end

    if ImGui.Separator then ImGui.Separator() end
    if primary then
        col_text(Theme.dim, "CHARACTER")
        draw_character_list(tab, id_prefix)
    else
        col_text(Theme.dim, "SHOW COLUMNS")
        local view_key = M.get_view_key(tab)
        local keys = M.source_keys(tab)
        if #keys == 0 then
            col_text(Theme.dim, "No characters in this source.")
        else
            if ImGui.Selectable("All Characters##" .. id_prefix .. "_cols_all", view_key == M.VIEW_ALL) then
                M.set_view_key(tab, M.VIEW_ALL)
                view_key = M.VIEW_ALL
            end
            for _, key in ipairs(keys) do
                local snap = views.source_snapshot(key)
                local display = snap and (snap.name or views.source_label(key)) or views.source_label(key)
                local status = snap and tostring(snap.status or "") or ""
                if key == "__self__" then status = "self" end
                local checked = column_checked(tab, key, view_key)
                local box_label = string.format("%s%s##%s_col_%s",
                    tostring(display),
                    status ~= "" and (" [" .. status .. "]") or "",
                    id_prefix,
                    tostring(key))
                local new_checked, changed = checkbox_value(box_label, checked)
                if changed then
                    M.apply_column_toggle(tab, key, new_checked)
                    view_key = M.get_view_key(tab)
                elseif ImGui.IsItemHovered and ImGui.IsItemHovered()
                    and ImGui.IsMouseDoubleClicked and ImGui.IsMouseDoubleClicked(0) then
                    M.set_view_key(tab, key)
                    view_key = key
                end
            end
        end
    end

    if ImGui.Separator then ImGui.Separator() end
    col_text(Theme.dim, "SAVE AS TEAM")
    ImGui.SetNextItemWidth(180.0)
    panel_save_name = input_text_hint("##" .. id_prefix .. "_save_name", "Name this team...", panel_save_name)
    ImGui.SameLine()
    if themed_button("Save##" .. id_prefix .. "_save_btn", Theme.blue, 64, 22) then
        local members = roster_sets.members_from_source_keys(
            primary and M.source_keys(tab) or M.active_keys(tab))
        if save_team_from_draft(tab, panel_save_name, members) then
            panel_save_name = ""
        end
    end

    if roster_sets.is_set_scope(cur_scope) then
        if themed_button("Edit Team##" .. id_prefix .. "_edit", Theme.steel, 84, 22) then
            M.open_set_editor(tab, "edit")
        end
        ImGui.SameLine()
        if themed_button("Delete Team##" .. id_prefix .. "_del", Theme.red or Theme.steel, 92, 22) then
            if roster_sets.delete_set(cur_scope) then
                M.apply_scope(tab, "online")
                set_status("Deleted character set.")
            end
        end
    end

    if ImGui.Separator then ImGui.Separator() end
    local linked = Settings.syncRosterScopeAcrossTabs == true
    local new_linked, link_changed = checkbox_value(
        "Link Scope across tabs##" .. id_prefix .. "_link", linked)
    if link_changed then
        Settings.syncRosterScopeAcrossTabs = new_linked and true or false
        if Settings.syncRosterScopeAcrossTabs == true then
            local a = adapter(tab)
            if a.link_source then
                cfg.apply_linked_roster_scope(M.get_scope(tab), a.link_source)
            end
        end
        if SaveSettings then SaveSettings() end
    end
    col_text(Theme.dim, tostring(opts.footer or adapter(tab).footer
        or "Source + columns + teams - this tab"))
end

function M.draw_pill(tab, opts)
    opts = type(opts) == "table" and opts or {}
    if Settings.showCharactersPill ~= true then return false end

    local id = "##tg_chars_pill_" .. tostring(tab)
    local popup_id = id .. "_popup"
    local label = M.pill_label(tab)
    local width = tonumber(opts.width) or 0
    if width <= 0 and ImGui.CalcTextSize then
        local ok, w = pcall(ImGui.CalcTextSize, label)
        if ok then
            if type(w) == "table" then width = (tonumber(w.x or w[1]) or 160) + 28 end
            if type(w) == "number" then width = w + 28 end
        end
    end
    if width <= 0 then width = 240 end

    local color = Theme.charactersPill or Theme.steel or Theme.blue
    if themed_button(label .. id, color, width, opts.height or 22) then
        if ImGui.OpenPopup then ImGui.OpenPopup(popup_id) end
    end
    if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
        local mode = adapter(tab).mode
        if mode == M.MODE_LIST then
            ImGui.SetTooltip("Pick which list / loadout this tab analyzes.")
        elseif mode == M.MODE_PICKER then
            ImGui.SetTooltip("Pick which character this tab shows.")
        elseif mode == M.MODE_PRIMARY then
            ImGui.SetTooltip("Who to show: source pool and character.")
        else
            ImGui.SetTooltip("Who to show: source pool, columns, and saved teams.")
        end
    end

    if ImGui.BeginPopup and ImGui.BeginPopup(popup_id) then
        M.draw_panel(tab, { id_prefix = "tg_chars_panel_" .. tostring(tab) })
        ImGui.EndPopup()
    end
    if adapter(tab).mode ~= M.MODE_PICKER and adapter(tab).mode ~= M.MODE_LIST then
        M.draw_set_editor(tab)
    end
    return true
end

return M
