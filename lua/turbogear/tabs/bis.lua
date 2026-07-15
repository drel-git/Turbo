-- TurboGear/tabs/bis.lua
-- BiS/checklist view: save worn gear as a list, select any source, and render
-- have/need across equipped + bags + bank.

local ImGui = require('ImGui')
local mq = require('mq')
local theme = require('theme')
local Theme, col_text, toggle_button, nav_button, themed_button = theme.Theme, theme.col_text, theme.toggle_button, theme.nav_button, theme.themed_button
local cfg = require('config')
local Settings, SaveSettings = cfg.Settings, cfg.SaveSettings
local bis = require('bis')
local userlists = require('userlists')
local userlists_ui = require('tabs.userlists_ui')
local catalog = require('bis_catalog')
local views = require('views')
local item_actions = require('item_actions')
local items = require('items')
local item_index = require('item_index')
local Store = require('store').Store
local my_key = require('store').my_key
local snapshot_mod = require('snapshot')
local diag = require('diagnostics')
local roster_sets = require('roster_sets')
local anguish_ref = require('references.anguish')
local announcer = require('announcer')
local ok_dsk_type12_ref, dsk_type12_ref = pcall(require, 'references.dsk_type12_focus')
if not ok_dsk_type12_ref or type(dsk_type12_ref) ~= 'table' then dsk_type12_ref = nil end

local M = {}

local show_armor_priority = false

local DSK_TYPE12_FILTER_NONE = "none"
local DSK_TYPE12_FILTER_ALL = "all"
local SELECTED_VIEW_KEY = roster_sets.VIEW_SELECTED

local REF_LISTS_FOCUS = { anguish = true, dsk = true }
local REF_LISTS_PRIORITY = { anguish = true, dsk = true }

local draft_name, filter = "", ""
local status_msg = ""
local suggest_tab
local draw_bis_color_legend
local set_popup_open = false
local set_popup_mode = "save"
local set_draft_name = ""
local set_draft_members = {}

local function open_find_candidates(view_key, slot_name)
    local slot_id = items.slot_id_for_label(slot_name)
    if not slot_id then
        status_msg = "No equip slot mapping for: " .. tostring(slot_name or "?")
        return
    end
    if not suggest_tab then suggest_tab = require('tabs.suggestions') end
    suggest_tab.open_for(view_key, slot_id, { sortUpgrades = true, overview = false })
    status_msg = ""
end

local SCOPE_OPTIONS = {
    { key = "self", label = "This Character" },
    { key = "online", label = "Live Peers" },
    { key = "group", label = "Group" },
    { key = "e3", label = "E3 Online" },
    { key = "all", label = "All Known" },
}

local ROLE_COLORS = {
    tank    = { 0.58, 0.66, 0.76, 1.0 }, -- steel-blue  WAR / SHD / PAL
    healer  = { 0.431, 0.906, 0.718, 1.0 }, -- #6EE7B7  CLR / SHM / DRU
    melee   = { 0.992, 0.729, 0.455, 1.0 }, -- #FDBA74  BRS / ROG / MNK / BST / RNG
    caster  = { 0.753, 0.518, 0.988, 1.0 }, -- #C084FC  MAG / NEC / WIZ
    utility = { 0.404, 0.910, 0.976, 1.0 }, -- #67E8F9  BRD / ENC
}

local CLASS_ROLE = {
    war = "tank", warrior = "tank",
    shd = "tank", shadowknight = "tank",
    pal = "tank", paladin = "tank",
    clr = "healer", cleric = "healer",
    shm = "healer", shaman = "healer",
    dru = "healer", druid = "healer",
    brs = "melee", brz = "melee", berserker = "melee",
    rog = "melee", rogue = "melee",
    mnk = "melee", monk = "melee",
    bst = "melee", beastlord = "melee",
    rng = "melee", ranger = "melee",
    mag = "caster", magician = "caster",
    nec = "caster", necromancer = "caster",
    wiz = "caster", wizard = "caster",
    brd = "utility", bard = "utility",
    enc = "utility", enchanter = "utility",
}

local ROLE_LABELS = {
    tank = "Tank", healer = "Healer", melee = "Melee", caster = "Caster", utility = "Utility",
}

local CLASS_ABBREV = {
    warrior = "WAR", shadowknight = "SHD", paladin = "PAL",
    cleric = "CLR", shaman = "SHM", druid = "DRU",
    berserker = "BRS", rogue = "ROG", monk = "MNK", beastlord = "BST", ranger = "RNG",
    magician = "MAG", necromancer = "NEC", wizard = "WIZ",
    bard = "BRD", enchanter = "ENC",
}

local function norm_class(class_name)
    local s = tostring(class_name or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if s == "shadow knight" or s == "shadowknight" then return "shadowknight" end
    return s:gsub("%s+", "")
end

local function class_role(class_name)
    return CLASS_ROLE[norm_class(class_name)]
end

local function class_color(class_name)
    local role = class_role(class_name)
    if role then return ROLE_COLORS[role] end
    return Theme.header or Theme.item
end

local function class_abbrev(class_name)
    local key = norm_class(class_name)
    return CLASS_ABBREV[key] or tostring(class_name or "?"):upper():sub(1, 3)
end

local DENSITY_OPTIONS = {
    { key = "compact", label = "Regular" },
    { key = "ultra", label = "Compact" },
}

local DENSITY_CFG = {
    normal  = { col_w = nil,  slot_w = 145.0, name_max = 999, glyph = false, min_col_w = 120.0, max_col_w = 320.0 },
    compact = { col_w = nil,  slot_w = 110.0, name_max = 22, glyph = false, min_col_w = 84.0,  max_col_w = 92.0, fit_w = 88.0 },
    ultra   = { col_w = 44.0, slot_w = 72.0,  name_max = 0,  glyph = true, min_col_w = 44.0, max_col_w = 44.0 },
}

local FULL_NAME_CFG = { col_w = nil, slot_w = 124.0, name_max = 36, min_col_w = 140.0, max_col_w = 220.0, fit_w = nil }

-- TurboBiS roster colors (slot gold stays on Theme.slot; carried uses bag-blue).
local BIS_GREEN  = { 0.43, 0.82, 0.58, 1.0 }
local BIS_BAG    = { 0.52, 0.72, 1.00, 1.0 }  -- owned in bags/bank (not slot gold)
local BIS_MISS   = { 0.62, 0.34, 0.34, 1.0 }
local BIS_ELSE   = { 0.95, 0.72, 0.30, 1.0 }
local BIS_CYAN   = { 0.36, 0.66, 0.76, 1.0 }
local BIS_ITEM   = { 0.37, 0.68, 0.80, 1.0 }
local ULTRA_CELL_BG = {
    equipped = { 0.10, 0.20, 0.14, 0.94 },
    carried  = { 0.10, 0.15, 0.26, 0.94 },
}

-- Friendlier slot labels for the frozen column (catalog keys -> display).
local SLOT_LABELS = {
    Wrist1 = "Wrist 1", Wrist2 = "Wrist 2",
    Ear1 = "Ear 1", Ear2 = "Ear 2",
    Finger1 = "Finger 1", Finger2 = "Finger 2",
    MainHand = "Main Hand", Secondary = "Secondary",
    RangedAug = "Ranged Aug",
    ["Middle Finger (Mayong)"] = "Mid Finger",
}

local function slot_display_label(slot)
    slot = SLOT_LABELS[slot] or slot or ""
    local function eff(e)
        local map = {
            ["Increase Duration"] = "Dur",
            ["Double Attack"] = "DA",
            ["Reduce Mana Cost"] = "Mana",
            ["Parry/Block"] = "P/B",
        }
        return map[e] or e
    end
    local base_elem, effect = slot:match("^Base (%S+) Slime of Suffering %((.-)%)$")
    if base_elem then return string.format("%s Slime (%s)", base_elem, eff(effect)) end
    local base_bloom
    base_bloom, effect = slot:match("^Base Noxious Bloom of (.-) %((.-)%)$")
    if base_bloom then return string.format("%s (%s)", base_bloom, eff(effect)) end
    local ord, elem
    ord, elem, effect = slot:match("^(%d)%a%a (%S+) Fungus of Suffering %((.-)%)$")
    if ord then return string.format("%s %s (%s)", ord, elem, eff(effect)) end
    local bloom
    ord, bloom, effect = slot:match("^(%d)%a%a Fungal Bloom of (.-) %((.-)%)$")
    if ord then return string.format("%s %s (%s)", ord, bloom, eff(effect)) end
    return slot
end

local roster_cache = { key = nil, refs = nil, rows = nil, counts = nil, keys = nil }
local roster_build_job = nil
local elsewhere_cache = { key = nil, hits = {} }
local elsewhere_budget_until = 0
local bis_dropdown_open = false
local bis_roster_table_h = nil
local bis_roster_table_w = nil
local peek_snapshot
local catalog_cell_text
local select_catalog
local select_user_list

local function ensure_density_defaults()
    if Settings.bisViewDensity == nil or Settings.bisViewDensity == "" then
        Settings.bisViewDensity = "compact"
    end
    local mode = tostring(Settings.bisViewDensity or "compact")
    if mode == "normal" then
        Settings.bisViewDensity = "compact"
    elseif mode ~= "compact" and mode ~= "ultra" then
        Settings.bisViewDensity = "compact"
    end
end

local function density_mode()
    ensure_density_defaults()
    return Settings.bisViewDensity or "compact"
end

local function roster_layout_cfg()
    local layout = density_mode()
    if layout == "compact" and Settings.bisCompactFullNames then
        return layout, FULL_NAME_CFG
    end
    return layout, DENSITY_CFG[layout] or DENSITY_CFG.normal
end

local function show_elsewhere()
    return false
end

local function matches_filter(row, needle)
    if needle == "" then return true end
    local e, m = row.entry or {}, row.match or {}
    local x = show_elsewhere() and (row.elsewhere or {}) or {}
    local hay = table.concat({ e.item or "", e.slot or "", e.group or "", m.location or "", m.where or "", m.name or "", x.owner or "", x.location or "", x.name or "" }, " "):lower()
    return hay:find(needle, 1, true) ~= nil
end

local function selected_catalog_id()
    local id = Settings.bisCatalogList or ""
    if id ~= "" and catalog.list(id) and not catalog.list_hidden(id) then return id end
    id = catalog.default_list_id()
    if id ~= "" then
        Settings.bisCatalogList = id
        SaveSettings()
    end
    return id
end

select_catalog = function(group, rec)
    if not rec or not rec.id then return end
    Settings.bisListMode = "catalog"
    Settings.bisCatalogGroup = group and group.name or ""
    Settings.bisCatalogList = rec.id
    Settings.bisCatalogLastByGroup = type(Settings.bisCatalogLastByGroup) == "table" and Settings.bisCatalogLastByGroup or {}
    Settings.bisCatalogLastByGroup[Settings.bisCatalogGroup] = rec.id
    roster_cache.key = nil
    SaveSettings()
end

select_user_list = function(id)
    Settings.bisListMode = "user"
    Settings.bisSelectedList = id
    roster_cache.key = nil
    SaveSettings()
end

local function ensure_visible_catalog()
    if Settings.bisListMode == "user" then return end
    local id = Settings.bisCatalogList or ""
    if id ~= "" and catalog.list(id) and not catalog.list_hidden(id) then return end
    local first = catalog.first_visible_list_button()
    if first and first.group then
        select_catalog(first.group, first.rec)
    end
end

-- Active user list, or nil when in catalog mode / list missing.
local function active_user_list()
    if Settings.bisListMode ~= "user" then return nil end
    return bis.get(Settings.bisSelectedList)
end

local function clear_bis_filter()
    if filter and filter ~= "" then
        filter = ""
        roster_cache.key = nil
    end
end

local NAV_BTN_H = 22.0
local BIS_TABLE_FOOTER_RESERVE = 28.0
local COMBO_ROW_H = 24.0

local function button_text_width(text)
    if not ImGui.CalcTextSize then return 120.0 end
    local ok, w = pcall(ImGui.CalcTextSize, tostring(text or ""))
    if not ok then return 120.0 end
    if type(w) == "table" then w = tonumber(w.x or w[1]) or 0 end
    return math.max((tonumber(w) or 0) + 22.0, 44.0)
end

local function content_avail_x()
    local avail = ImGui.GetContentRegionAvail and ImGui.GetContentRegionAvail() or 0
    if type(avail) == "table" then return tonumber(avail.x or avail[1]) or 0 end
    return tonumber(avail) or 0
end

-- Available width, stabilised against the ~14px jump when a vertical scrollbar
-- shows/hides. Layout decisions (toolbar wrapping, the "Tip:" line, roster column
-- widths) read THIS instead of the raw value, so a scrollbar flicker can no longer
-- feed back into the layout and make the dropdowns/roster jitter. Only a real
-- change (window resize > 32px) updates the cached width.
local _stable_avail_x = nil
local function stable_avail_x()
    local raw = content_avail_x()
    if raw <= 0 then return _stable_avail_x or raw end
    if not _stable_avail_x or math.abs(raw - _stable_avail_x) > 32.0 then
        _stable_avail_x = raw
    end
    return _stable_avail_x
end

local function stable_bis_roster_table_h(reserve_h, min_h)
    local avail_w, avail_h = views.content_avail()
    local raw = math.max(min_h or 220.0, (avail_h or 520.0) - (reserve_h or 8.0))
    avail_w = tonumber(avail_w) or 0

    if bis_dropdown_open and bis_roster_table_h then
        return bis_roster_table_h
    end

    if not bis_roster_table_h
        or math.abs(raw - bis_roster_table_h) > 24.0
        or math.abs(avail_w - (bis_roster_table_w or avail_w)) > 32.0 then
        bis_roster_table_h = raw
        bis_roster_table_w = avail_w
    elseif not bis_dropdown_open then
        bis_roster_table_h = raw
        bis_roster_table_w = avail_w
    end

    return bis_roster_table_h or raw
end

local function style_spacing_x()
    if ImGui.GetStyle then
        local sp = ImGui.GetStyle().ItemSpacing
        if type(sp) == "table" then return tonumber(sp.x or sp[1]) or 4 end
    end
    return 4
end

local function item_rect_width(fallback)
    fallback = tonumber(fallback) or 44.0
    if ImGui.GetItemRectSize then
        local sz = ImGui.GetItemRectSize()
        if type(sz) == "table" then return tonumber(sz.x or sz[1]) or fallback end
        return tonumber(sz) or fallback
    end
    return fallback
end

local function draw_wrapped_nav_buttons(items, render_btn)
    if #items == 0 then return end
    local x0, y0 = 0, 0
    if ImGui.GetCursorPos then
        x0, y0 = ImGui.GetCursorPos()
        x0, y0 = tonumber(x0) or 0, tonumber(y0) or 0
    end
    local line_w = stable_avail_x()
    local spacing = style_spacing_x()
    local row_x, row_y = x0, y0
    local row_h = NAV_BTN_H
    for i, item in ipairs(items) do
        local label = type(item) == "table" and item.label or tostring(item)
        local est_w = button_text_width(label)
        if i > 1 and (row_x + est_w > x0 + line_w + 0.5) then
            row_x = x0
            row_y = row_y + row_h + spacing
        end
        if ImGui.SetCursorPos then ImGui.SetCursorPos(row_x, row_y) end
        render_btn(item, i)
        row_x = row_x + est_w + spacing
        row_h = math.max(row_h, NAV_BTN_H)
    end
    if ImGui.SetCursorPos then
        ImGui.SetCursorPos(x0, row_y + row_h + spacing)
    elseif ImGui.Dummy then
        ImGui.Dummy(0, row_h + spacing)
    end
end

local function ui_text_width(text)
    if not ImGui.CalcTextSize then return 80.0 end
    local ok, w = pcall(ImGui.CalcTextSize, tostring(text or ""))
    if not ok then return 80.0 end
    if type(w) == "table" then w = tonumber(w.x or w[1]) or 0 end
    return (tonumber(w) or 0) + 8.0
end

local function char_column_flags(col_w, _layout)
    local flags = col_w and ImGuiTableColumnFlags.WidthFixed or ImGuiTableColumnFlags.WidthStretch
    return flags, col_w or 1.5
end

local function column_width_now()
    if ImGui.GetColumnWidth then
        local w = ImGui.GetColumnWidth()
        if type(w) == "table" then return tonumber(w.x or w[1]) end
        return tonumber(w)
    end
    return nil
end

local function table_col_text_centered(color, text, col_w)
    views.col_text_centered(color, text, col_w or column_width_now())
end

local function measure_slot_col_w(layout, layout_cfg)
    local min_w = tonumber(layout_cfg and layout_cfg.slot_w) or 104.0
    local max_w = min_w
    for _, rec in ipairs(roster_cache.rows or {}) do
        if rec.header then
            max_w = math.max(max_w, ui_text_width(tostring(rec.category or "")))
        elseif rec.slot then
            max_w = math.max(max_w, ui_text_width(slot_display_label(rec.slot)) + 14.0)
        end
    end
    local cap = 340.0
    if layout == "ultra" then cap = 96.0
    elseif layout == "compact" and not Settings.bisCompactFullNames then cap = 200.0 end
    return math.min(math.max(max_w, min_w), cap)
end

local function cap_char_col_w_for_viewport(measured_w, num_keys, slot_w, layout_cfg, layout)
    measured_w = tonumber(measured_w) or 96.0
    num_keys = math.max(1, tonumber(num_keys) or 1)
    slot_w = tonumber(slot_w) or 120.0
    local floor_w = tonumber(layout_cfg and layout_cfg.min_col_w) or 88.0
    local cfg_cap = tonumber(layout_cfg and layout_cfg.max_col_w) or 196.0
    if layout == "ultra" then return tonumber(layout_cfg and layout_cfg.col_w) or floor_w end
    local compact_short = layout == "compact" and not Settings.bisCompactFullNames
    if compact_short then
        floor_w = tonumber(layout_cfg and layout_cfg.fit_w) or floor_w
        measured_w = math.max(measured_w, floor_w)
        -- Short-name compact mode is usually 88px, but on wide monitors a
        -- moderate roster should fill the viewport instead of leaving a blank
        -- right side. Very large rosters keep the compact fixed-scroll width.
        cfg_cap = num_keys <= 12 and 170.0 or floor_w
    end
    local avail = stable_avail_x()
    if avail <= 0 then avail = 800.0 end
    local budget = math.max(120.0, avail - slot_w - 28.0)
    local equal = math.floor(budget / num_keys)
    if num_keys > 12 and cfg_cap > 160 then cfg_cap = 160 end
    local desired = math.max(measured_w, floor_w)
    if num_keys <= 12 and equal > desired then
        desired = equal
    end
    return math.min(desired, cfg_cap)
end

local function measure_roster_char_col_w(keys, layout, layout_cfg)
    if layout == "ultra" then return layout_cfg.col_w or 24.0 end
    if layout == "compact" and not Settings.bisCompactFullNames then
        return tonumber(layout_cfg.fit_w) or 88.0
    end
    if layout == "normal" then return nil end
    local max_w = tonumber(layout_cfg.min_col_w) or 96.0
    local cap = tonumber(layout_cfg.max_col_w) or 196.0
    local num_keys = #(keys or {})
    if num_keys > 6 and cap > 180 then cap = 180 end
    for _, key in ipairs(keys) do
        local snap = peek_snapshot(key)
        if snap then
            local hdr = string.format("%s (%s)", snap.name or "?", class_abbrev(snap.class))
            max_w = math.max(max_w, ui_text_width(hdr))
            local c = roster_cache.counts and roster_cache.counts[key] or { 0, 0, 0 }
            max_w = math.max(max_w, ui_text_width(string.format("%d / %d / %d", c[1] or 0, c[2] or 0, c[3] or 0)))
        end
    end
    for _, rec in ipairs(roster_cache.rows or {}) do
        if rec.rows then
            for _, key in ipairs(keys) do
                local row = rec.rows[key]
            if row and not row.empty then
                    local txt = catalog_cell_text(row, layout, layout_cfg.name_max)
                    if layout_cfg.fit_w then
                        txt = views.fit_text(txt, layout_cfg.fit_w)
                    end
                    max_w = math.max(max_w, ui_text_width(txt))
                end
            end
        end
    end
    return math.min(math.max(max_w, tonumber(layout_cfg.min_col_w) or 96.0), cap)
end

local function draw_wrapped_controls(items)
    if #items == 0 then return end
    local x0, y0 = 0, 0
    if ImGui.GetCursorPos then
        x0, y0 = ImGui.GetCursorPos()
        x0, y0 = tonumber(x0) or 0, tonumber(y0) or 0
    end
    local line_w = stable_avail_x()
    local spacing = style_spacing_x()
    local row_x, row_y = x0, y0
    local row_h = NAV_BTN_H
    for i, item in ipairs(items) do
        local est_w = tonumber(item.width) or 80.0
        if i > 1 and (row_x + est_w > x0 + line_w + 0.5) then
            row_x = x0
            row_y = row_y + row_h + spacing
        end
        if ImGui.SetCursorPos then ImGui.SetCursorPos(row_x, row_y) end
        item.draw(item, i)
        -- Advance by the DECLARED width, never GetItemRectSize(): while a combo's
        -- popup is open the measured rect is unstable, which reflowed the toolbar
        -- every frame and made the open dropdown jitter. Declared widths are fixed.
        row_x = row_x + est_w + spacing
        row_h = math.max(row_h, tonumber(item.height) or NAV_BTN_H)
    end
    if ImGui.SetCursorPos then
        ImGui.SetCursorPos(x0, row_y + row_h + spacing)
    elseif ImGui.Dummy then
        ImGui.Dummy(0, row_h + spacing)
    end
end

local function draw_fixed_control_row(items)
    if #items == 0 or not ImGui.BeginTable then return false end
    local spacing = style_spacing_x()
    local total_w = 0
    for _, item in ipairs(items) do
        total_w = total_w + (tonumber(item.width) or 80.0) + spacing
    end
    if total_w > stable_avail_x() then return false end

    local flags = (ImGuiTableFlags.NoSavedSettings or 0) + (ImGuiTableFlags.NoPadOuterX or 0)
    if not ImGui.BeginTable("##bis_toolbar_fixed", #items, flags) then return false end
    for i, item in ipairs(items) do
        ImGui.TableSetupColumn("##c" .. tostring(i), ImGuiTableColumnFlags.WidthFixed, tonumber(item.width) or 80.0)
    end
    ImGui.TableNextRow()
    for i, item in ipairs(items) do
        ImGui.TableSetColumnIndex(i - 1)
        item.draw(item, i)
    end
    ImGui.EndTable()
    return true
end

local function draw_wrapped_nav_button(_i, label, active, id, on_click)
    if nav_button(label .. id, active, true, 0, NAV_BTN_H) then
        on_click()
    end
end

local function custom_lists_combo_label()
    if Settings.bisListMode == "user" then
        local list = bis.get(Settings.bisSelectedList)
        if list and list.name and list.name ~= "" then
            local suffix = catalog.list_announce_enabled(list.id) and "" or " !"
            return tostring(list.name) .. suffix
        end
        return "Pick a list..."
    end
    return "Switch to Custom List..."
end

local function run_analyze_list(list_id)
    list_id = tostring(list_id or Settings.bisSelectedList or "")
    local ok_lo, loadout = pcall(require, 'loadout')
    if ok_lo and loadout and loadout.open_analyze_list then
        loadout.open_analyze_list(list_id)
    end
end

local function run_compare_worn(list_id)
    list_id = tostring(list_id or Settings.bisSelectedList or "")
    local ok_lo, loadout = pcall(require, 'loadout')
    if ok_lo and loadout and loadout.open_analyze_vs_worn then
        loadout.open_analyze_vs_worn(list_id)
    end
end

local function run_compare_lists(list_id)
    list_id = tostring(list_id or Settings.bisSelectedList or "")
    local ok_lo, loadout = pcall(require, 'loadout')
    if ok_lo and loadout and loadout.open_analyze_vs_list then
        loadout.open_analyze_vs_list(list_id)
    end
end

local function run_export_list(list_id)
    list_id = tostring(list_id or Settings.bisSelectedList or "")
    local ok_lo, loadout = pcall(require, 'loadout')
    if ok_lo and loadout and loadout.export_list then
        local ok, detail = loadout.export_list(list_id)
        status_msg = ok and ("Exported list to " .. tostring(detail)) or tostring(detail or "Export failed.")
    end
end

local function current_copy_source()
    local view_key = tostring(Settings.bisViewKey or "")
    local snap = nil
    if view_key ~= "" and view_key ~= "__all__" and view_key ~= SELECTED_VIEW_KEY then
        snap = views.source_snapshot(view_key)
    end
    snap = snap or views.source_snapshot("__self__")
    return snap
end

local function copy_catalog_to_custom(catalog_id)
    catalog_id = tostring(catalog_id or selected_catalog_id() or "")
    if catalog_id == "" then
        status_msg = "Pick a BiS catalog first."
        return
    end
    local snap = current_copy_source()
    local list, err = userlists.copy_catalog_list(catalog_id, {
        class_name = snap and snap.class or nil,
        owner = snap and snap.name or nil,
    })
    if list then
        Settings.bisListMode = "user"
        Settings.bisListsTab = "my"
        Settings.bisSelectedList = list.id
        roster_cache.key = nil
        SaveSettings()
        status_msg = string.format("Copied '%s' to editable Custom List '%s'.", catalog.list_label(catalog_id), list.name)
    else
        status_msg = tostring(err or "Could not copy catalog.")
    end
end

local function draw_user_list_actions(list_id)
    list_id = tostring(list_id or "")
    if list_id == "" then return end
    if themed_button("Analyze##bis_act_analyze", Theme.blue) then
        run_analyze_list(list_id)
    end
    if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
        ImGui.SetTooltip("Plan stat & focus totals (Stats tab)")
    end
    ImGui.SameLine()
    if themed_button("Compare vs Worn##bis_act_worn", Theme.cyan) then
        run_compare_worn(list_id)
    end
    if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
        ImGui.SetTooltip("This list vs what you wear now — stat & focus changes")
    end
    ImGui.SameLine()
    if themed_button("Compare vs List##bis_act_lists", Theme.cyan) then
        run_compare_lists(list_id)
    end
    if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
        ImGui.SetTooltip("Compare this list against another plan")
    end
    ImGui.SameLine()
    if themed_button("Export##bis_act_export", Theme.sync) then
        run_export_list(list_id)
    end
    ImGui.SameLine()
    if themed_button("Focus View##bis_act_focus", Theme.purple) then
        local ok_lo, loadout = pcall(require, 'loadout')
        if ok_lo and loadout and loadout.open_for_list then
            loadout.open_for_list(list_id, "focus")
        end
    end
    ImGui.SameLine()
    if themed_button("Use for Linked Needs##bis_act_ann", Theme.sync) then
        local ok, detail = userlists.prepare_for_announces(list_id)
        status_msg = ok
            and string.format("'%s' is active for linked-needs announces.", tostring(detail or list_id))
            or tostring(detail or "Could not enable linked needs.")
    end
    ImGui.SameLine()
    if themed_button("Manage Lists##bis_act_edit", Theme.steel) then
        Settings.mainTab = "bis"
        Settings.bisListsTab = "edit"
        Settings.bisListMode = "user"
        SaveSettings()
    end
end

local function draw_custom_lists_combo()
    local names = bis.list_names()
    local in_user = Settings.bisListMode == "user"
    local label = custom_lists_combo_label()

    ImGui.SetNextItemWidth(190.0)
    if ImGui.BeginCombo("##bis_custom_lists", label) then
        bis_dropdown_open = true
        if #names == 0 then
            ImGui.TextDisabled("No custom lists yet")
            if ImGui.Selectable("Create / Manage Lists##bis_custom_setup") then
                Settings.mainTab = "bis"
                Settings.bisListsTab = "edit"
                Settings.bisListMode = "user"
                SaveSettings()
            end
        else
            for _, rec in ipairs(names) do
                local rec_label = tostring(rec.name) .. (catalog.list_announce_enabled(rec.id) and "" or " !")
                if ImGui.Selectable(rec_label .. "##bis_custom_" .. tostring(rec.id), in_user and Settings.bisSelectedList == rec.id) then
                    clear_bis_filter()
                    select_user_list(rec.id)
                end
                if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
                    local l = rec.list or {}
                    ImGui.SetTooltip(string.format("%s\n%d entries%s\nBiS + Lists -> Manage Lists",
                        rec.name, #(l.entries or {}), (l.class and l.class ~= "") and (" - " .. l.class) or ""))
                end
            end
        end
        ImGui.EndCombo()
    end
    if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
        ImGui.SetTooltip("Your wishlists and loadout plans (not zone catalogs)")
    end
end

local function draw_my_lists_header()
    local names = bis.list_names()
    if #names > 0 and not bis.get(Settings.bisSelectedList) then
        select_user_list(names[1].id)
    end
    if #names == 0 then
        col_text(Theme.amber, "No custom lists yet — build a wishlist or loadout plan here.")
        if themed_button("Create / Manage Lists##bis_empty_setup", Theme.blue) then
            Settings.mainTab = "bis"
            Settings.bisListsTab = "edit"
            Settings.bisListMode = "user"
            SaveSettings()
        end
        ImGui.SameLine()
        col_text(Theme.dim, "Tip: right-click any item -> Add to List...")
        return
    end

    col_text(Theme.header or Theme.item, "List:")
    ImGui.SameLine()
    draw_custom_lists_combo()
    local user_list = active_user_list()
    if user_list then
        ImGui.SameLine()
        col_text(Theme.dim, string.format("(%d items)", #(user_list.entries or {})))
    end
    ImGui.Spacing()
    draw_user_list_actions(Settings.bisSelectedList)
end

local function draw_catalog_buttons()
    local cur_id = selected_catalog_id()
    local in_user_mode = Settings.bisListMode == "user"
    local src = catalog.ui_list_buttons()
    local buttons = {}
    for i, b in ipairs(src) do buttons[i] = b end
    draw_wrapped_nav_buttons(buttons, function(b, i)
        if not b.label or not b.id then return end
        local cat_label = tostring(b.label) .. (catalog.list_announce_enabled(b.id) and "" or " !")
        draw_wrapped_nav_button(i, cat_label, (not in_user_mode) and cur_id == b.id, "##catbtn_" .. tostring(b.id), function()
            if b.group then
                clear_bis_filter()
                select_catalog(b.group, b.rec)
                cur_id = b.id
            end
        end)
    end)
end

local function active_announce_list_id()
    if Settings.bisListMode == "user" then return tostring(Settings.bisSelectedList or "") end
    return tostring(selected_catalog_id() or "")
end

local function draw_announce_disabled_warning()
    local id = active_announce_list_id()
    if id == "" or catalog.list_announce_enabled(id) then return end
    col_text(Theme.amber, "! Announce OFF for this TurboBiS list.")
end

local function linked_item_age_text(age_s)
    age_s = math.max(0, math.floor(tonumber(age_s) or 0))
    if age_s < 60 then return tostring(age_s) .. "s" end
    return tostring(math.floor(age_s / 60)) .. "m"
end

local draw_linked_send_buttons
local draw_linked_needers

local function draw_linked_items_panel()
    local ok, rows = pcall(function() return announcer.linked_items() end)
    if not ok or type(rows) ~= "table" or #rows == 0 then return end

    col_text(Theme.header, "Linked items:")
    ImGui.SameLine()
    if themed_button("Clear##bis_linked_clear", Theme.steel, button_text_width("Clear"), NAV_BTN_H) then
        announcer.clear_linked_items()
        status_msg = "Cleared linked item history."
        return
    end

    if not ImGui.BeginTable then
        for i = 1, math.min(#rows, 6) do
            local row = rows[i]
            col_text(Theme.item, tostring(row.item_name or "?") .. " - " .. table.concat(row.needers or {}, " | "))
        end
        return
    end

    local flags = (ImGuiTableFlags.BordersInnerV or 0)
        + (ImGuiTableFlags.RowBg or 0)
        + (ImGuiTableFlags.NoSavedSettings or 0)
    if ImGui.BeginTable("##bis_linked_items", 6, flags) then
        ImGui.TableSetupColumn("", ImGuiTableColumnFlags.WidthFixed, 30.0)
        ImGui.TableSetupColumn("Send", ImGuiTableColumnFlags.WidthFixed, 150.0)
        ImGui.TableSetupColumn("Item", ImGuiTableColumnFlags.WidthStretch, 1.8)
        ImGui.TableSetupColumn("Needers", ImGuiTableColumnFlags.WidthStretch, 2.2)
        -- Corpse spawn id from TurboLoot [ANNOUNCE]/[SKIP] so callers can say
        -- "loot corpse 132" without digging through chat.
        ImGui.TableSetupColumn("ID", ImGuiTableColumnFlags.WidthFixed, 48.0)
        ImGui.TableSetupColumn("Age", ImGuiTableColumnFlags.WidthFixed, 42.0)
        ImGui.TableHeadersRow()
        for i = 1, math.min(#rows, 6) do
            local row = rows[i]
            local id = tostring(i) .. "_" .. tostring(row.id or "row")
            ImGui.TableNextRow()
            ImGui.TableSetColumnIndex(0)
            if themed_button("X##bis_linked_x_" .. id, Theme.brick or Theme.steel, 24, NAV_BTN_H) then
                announcer.dismiss_linked_item(row.id)
                status_msg = "Removed linked item."
            end
            ImGui.TableSetColumnIndex(1)
            draw_linked_send_buttons(row, id)
            ImGui.TableSetColumnIndex(2)
            item_actions.draw_name(
                tostring(row.item_name or "?"),
                Theme.item,
                "linked_panel_" .. tostring(id),
                tonumber(row.item_id) or nil)
            ImGui.TableSetColumnIndex(3)
            draw_linked_needers(row, id)
            ImGui.TableSetColumnIndex(4)
            local cid = tonumber(row.corpse_id)
            if cid then
                col_text(Theme.dim, tostring(math.floor(cid)))
                if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
                    ImGui.SetTooltip(string.format(
                        "Corpse spawn id %d — tell others which corpse still has this item.",
                        math.floor(cid)))
                end
            else
                ImGui.TextDisabled("-")
                if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
                    ImGui.SetTooltip("No corpse id — Go buttons stay off until an [ANNOUNCE]/[SKIP] handoff arrives.")
                end
            end
            ImGui.TableSetColumnIndex(5)
            ImGui.TextDisabled(linked_item_age_text(row.age_s))
        end
        ImGui.EndTable()
    end
    if #rows > 6 then
        col_text(Theme.dim, string.format("%d older linked items hidden.", #rows - 6))
    end
end

local LINKED_SEND_BUTTONS = {
    { label = "G",  channel = "group", text = "group", width = 28 },
    { label = "R",  channel = "raid",  text = "raid",  width = 28 },
    { label = "GU", channel = "guild", text = "guild", width = 38 },
    { label = "S",  channel = "say",   text = "say",   width = 28 },
}

-- Friendly text for go-loot outcome tokens (tokens stay space-free because
-- they travel through /tgear golootnote argument parsing).
local GO_LOOT_NOTES = {
    sent = "sent", going = "going", looted = "looted",
    revealing = "revealing", heading = "heading", opening = "opening",
    looting = "looting",
    busy = "runner busy", in_combat = "in combat",
    corpse_gone = "corpse gone", too_far = "too far", not_found = "item gone",
    empty_corpse = "empty corpse", lore = "lore blocked",
    timeout_move = "couldn't reach", timeout_job = "timed out",
    no_target = "no target",
    no_window = "window didn't open", window_closed = "window closed",
    loot_failed = "loot failed", no_corpse_id = "no corpse id",
}

-- Needers cell: when the row carries a fresh corpse id (TurboLoot left the
-- item on the corpse), each needer becomes a click-to-go button that sends
-- that character to loot it. Otherwise plain text, as before.
draw_linked_needers = function(row, id)
    local needers = row.needers or {}
    if #needers == 0 then
        col_text(Theme.dim, "-")
        return
    end
    local ttl = tonumber(cfg.CFG.go_loot_corpse_ttl_s) or 420
    -- Missing corpse_at still counts as fresh when we have a corpse_id (stamp
    -- can lag a tick behind the id on pending rows).
    local corpse_age = tonumber(row.corpse_age_s)
    local can_go = tonumber(row.corpse_id) ~= nil
        and (corpse_age == nil or corpse_age <= ttl)
    local go_status = row.go_status or {}
    for i, name in ipairs(needers) do
        if i > 1 then ImGui.SameLine() end
        if can_go then
            local clicked = themed_button(
                tostring(name) .. "##bis_linked_go_" .. tostring(i) .. "_" .. tostring(id),
                Theme.steel,
                button_text_width(tostring(name)),
                NAV_BTN_H)
            if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
                ImGui.SetTooltip(string.format(
                    "Send %s to loot this item from corpse %d.\nWorks when they are in that zone with loot rights; result reports back here.",
                    tostring(name), tonumber(row.corpse_id) or 0))
            end
            if clicked then
                local ok, err = announcer.go_loot_request(row.id, name)
                status_msg = ok
                    and string.format("Go-loot sent: %s -> corpse %d.", tostring(name), tonumber(row.corpse_id) or 0)
                    or ("Go-loot failed: " .. tostring(GO_LOOT_NOTES[tostring(err)] or err or "?"))
            end
        else
            col_text(Theme.missing, tostring(name))
            if i == 1 and ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
                ImGui.SetTooltip("Go loot unavailable: no corpse id on this linked row.\nNeeds a TurboLoot [ANNOUNCE]/[SKIP] handoff (or actor relay) while the corpse is fresh.")
            end
        end
        local note = go_status[tostring(name)]
        if note and note ~= "" then
            ImGui.SameLine()
            col_text(note == "looted" and Theme.green or Theme.dim,
                "(" .. tostring(GO_LOOT_NOTES[tostring(note)] or note) .. ")")
        end
    end
end

draw_linked_send_buttons = function(row, id)
    for i, btn in ipairs(LINKED_SEND_BUTTONS) do
        if i > 1 then ImGui.SameLine() end
        local clicked = themed_button(
            tostring(btn.label) .. "##bis_linked_send_" .. tostring(btn.channel) .. "_" .. tostring(id),
            Theme.blue,
            btn.width,
            NAV_BTN_H)
        if clicked then
            local sent = announcer.announce_linked_item(row.id, btn.channel)
            status_msg = sent
                and ("Re-linked item with [ANNOUNCE] to " .. tostring(btn.text) .. ".")
                or "Linked item no longer available."
        end
    end
end

local function input_text_hint(id, hint, value)
    if ImGui.InputTextWithHint then
        local ok, rv = pcall(ImGui.InputTextWithHint, id, hint, value or "")
        if ok then return rv or "" end
    end
    return ImGui.InputText(id, value or "") or ""
end

local function draw_bis_search()
    local clear_w = math.ceil(button_text_width("Clear"))
    local gap = style_spacing_x()
    local hint = Settings.bisListMode == "user" and "Search this list..." or "Search this catalog..."
    if ImGui.BeginTable then
        local flags = (ImGuiTableFlags.NoSavedSettings or 0) + (ImGuiTableFlags.NoPadOuterX or 0)
        if ImGui.BeginTable("##bisfilter_row", 2, flags) then
            ImGui.TableSetupColumn("Search", ImGuiTableColumnFlags.WidthStretch, 1.0)
            ImGui.TableSetupColumn("Clear", ImGuiTableColumnFlags.WidthFixed, clear_w + gap)
            ImGui.TableNextRow()
            ImGui.TableSetColumnIndex(0)
            ImGui.SetNextItemWidth(-1)
            local new_filter = input_text_hint("##bisfilter", hint, filter or "")
            if new_filter ~= filter then
                filter = new_filter or ""
                roster_cache.key = nil
            end
            ImGui.TableSetColumnIndex(1)
            if themed_button("Clear##bisfilter_clear", Theme.steel, clear_w, NAV_BTN_H) then
                clear_bis_filter()
            end
            ImGui.EndTable()
        end
        return
    end

    local avail = stable_avail_x()
    if avail <= 0 then avail = 400.0 end
    local search_w = math.max(100.0, avail - clear_w - gap - 10.0)
    draw_wrapped_controls({
        {
            width = search_w,
            height = NAV_BTN_H,
            draw = function()
                ImGui.SetNextItemWidth(search_w)
                local new_filter = input_text_hint("##bisfilter", hint, filter or "")
                if new_filter ~= filter then
                    filter = new_filter or ""
                    roster_cache.key = nil
                end
            end,
        },
        {
            width = clear_w,
            height = NAV_BTN_H,
            draw = function()
                if themed_button("Clear##bisfilter_clear", Theme.steel, clear_w, NAV_BTN_H) then
                    clear_bis_filter()
                end
            end,
        },
    })
end

local function row_color(row)
    if row and row.status == "equipped" then return BIS_GREEN end
    if row and row.status == "carried" then return BIS_BAG end
    if show_elsewhere() and row and row.elsewhere then return BIS_ELSE end
    return BIS_MISS
end

local function apply_ultra_cell_bg(row)
    if not row or row.empty or (row.status == "missing" and not (show_elsewhere() and row.elsewhere)) then return end
    local bg = row.status == "equipped" and ULTRA_CELL_BG.equipped or ULTRA_CELL_BG.carried
    if not (ImGui.TableSetBgColor and ImGuiTableBgTarget and theme.color_u32) then return end
    local target = ImGuiTableBgTarget.CellBg or ImGuiTableBgTarget.RowBg0
    pcall(ImGui.TableSetBgColor, target, theme.color_u32(bg))
end

local function tip(text)
    if text and text ~= "" and ImGui.IsItemHovered and ImGui.IsItemHovered() then
        if ImGui.SetTooltip then ImGui.SetTooltip(text) end
    end
end


-- Table cells must use normal ImGui widgets (Text/col_text). Draw-list-only cells
-- and SetCursorPosX/Dummy break MQ table stacks.
local function roster_table_flags(use_fixed)
    if not use_fixed then
        return views.scroll_table_flags(0)
    end
    local flags = ImGuiTableFlags.Borders + ImGuiTableFlags.RowBg
    if ImGuiTableFlags.Resizable then flags = flags + ImGuiTableFlags.Resizable end
    if ImGuiTableFlags.SizingFixedFit then flags = flags + ImGuiTableFlags.SizingFixedFit end
    if ImGuiTableFlags.ScrollX then flags = flags + ImGuiTableFlags.ScrollX end
    if ImGuiTableFlags.NoSavedSettings then flags = flags + ImGuiTableFlags.NoSavedSettings end
    if ImGuiTableFlags.ScrollY then flags = flags + ImGuiTableFlags.ScrollY end
    return flags
end

local function roster_use_fixed_columns(layout, key_count)
    key_count = tonumber(key_count) or 0
    if layout == "ultra" then return true end
    -- A single group should use the whole window on wide monitors. Larger
    -- rosters keep the fixed-column horizontal-scroll behavior.
    if layout == "compact" then return key_count > 6 end
    return false
end

local function draw_slot_column_cell(rec)
    ImGui.TableSetColumnIndex(0)
    local col_w = column_width_now()
    if rec.header then
        views.col_text_fit(BIS_CYAN, rec.category or "", col_w)
    else
        local label = string.rep(" ", 3) .. slot_display_label(rec.slot)
        views.colored_text_fit(Theme.slot, label, col_w)
    end
end

local function category_collapsed(category)
    local t = Settings.bisCollapsedCategories
    return type(t) == "table" and t[category or ""] == true
end

local function toggle_category(category)
    category = tostring(category or "")
    Settings.bisCollapsedCategories = type(Settings.bisCollapsedCategories) == "table" and Settings.bisCollapsedCategories or {}
    Settings.bisCollapsedCategories[category] = not Settings.bisCollapsedCategories[category]
    SaveSettings()
end

local function draw_category_header_cell(category)
    ImGui.TableSetColumnIndex(0)
    local collapsed = category_collapsed(category)
    local label = tostring(category or "")
    if collapsed then label = "+ " .. label end
    if ImGui.TableSetBgColor and ImGuiTableBgTarget and ImGuiTableBgTarget.RowBg0 and theme.color_u32 then
        pcall(ImGui.TableSetBgColor, ImGuiTableBgTarget.RowBg0, theme.color_u32(Theme.sectionBg or Theme.steel))
        if ImGuiTableBgTarget.RowBg1 then
            pcall(ImGui.TableSetBgColor, ImGuiTableBgTarget.RowBg1, theme.color_u32(Theme.sectionBg or Theme.steel))
        end
    end
    local pushed = false
    if ImGuiCol and ImGuiCol.Text and ImGui.PushStyleColor then
        pushed = pcall(ImGui.PushStyleColor, ImGuiCol.Text, BIS_CYAN[1], BIS_CYAN[2], BIS_CYAN[3], BIS_CYAN[4])
    end
    if ImGui.Selectable(label .. "##bis_cat_" .. tostring(category), false) then
        toggle_category(category)
    end
    if pushed then ImGui.PopStyleColor(1) end
    if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
        ImGui.SetTooltip(collapsed and "Expand category" or "Collapse category")
    end
end

local function draw_count_badges(c)
    c = c or { 0, 0, 0 }
    col_text(BIS_GREEN, tostring(c[1] or 0))
    ImGui.SameLine(0, 4); ImGui.TextDisabled("/")
    ImGui.SameLine(0, 4); col_text(BIS_BAG, tostring(c[2] or 0))
    ImGui.SameLine(0, 4); ImGui.TextDisabled("/")
    ImGui.SameLine(0, 4); col_text(BIS_MISS, tostring(c[3] or 0))
end

local function status_glyph(row)
    if not row or row.empty then return "-" end
    if row.status == "equipped" then return "W" end
    if row.status == "carried" then return "B" end
    if show_elsewhere() and row.elsewhere then return "E" end
    return "X"
end

local function row_label(row)
    if row and row.status == "equipped" then return "Equipped" end
    if row and row.status == "carried" then return "Carried" end
    if show_elsewhere() and row and row.elsewhere then return "Elsewhere" end
    return "Need"
end

local function row_location(row)
    local m = row.match
    if not m then return "-" end
    if row.status == "equipped" then return m.slotname or m.where or "Equipped" end
    return (m.location or "") .. " - " .. (m.where or "")
end

local function elsewhere_location(row)
    local e = row and row.elsewhere
    if not e then return "" end
    local loc = tostring(e.location or "")
    if loc == "" then loc = tostring(e.where or "") end
    if loc == "" then return tostring(e.owner or "?") end
    return string.format("%s @ %s", tostring(e.owner or "?"), loc)
end

local function cell_tooltip(row, snap, slot)
    if not row or row.empty or not row.entry then return nil end
    local parts = {
        row.entry.item or "?",
        string.format("Status: %s", row_label(row)),
    }
    if row.entry.source and row.entry.source ~= "" then
        parts[#parts + 1] = "Source: " .. row.entry.source
    end
    if slot and slot ~= "" then parts[#parts + 1] = "Slot: " .. slot end
    if snap then parts[#parts + 1] = string.format("%s (%s)", snap.name or "?", snap.class or "?") end
    if row.match and row.status ~= "missing" then parts[#parts + 1] = row_location(row) end
    if show_elsewhere() and row.elsewhere then parts[#parts + 1] = "Available: " .. elsewhere_location(row) end
    return table.concat(parts, "\n")
end

local function tooltip_label(label, color, value, value_color)
    col_text(color or Theme.dim, tostring(label or ""))
    ImGui.SameLine()
    theme.colored_text(tostring(value or "-"), value_color or Theme.dim)
end

local function draw_cell_tooltip(row, snap, slot)
    if not (row and not row.empty and row.entry and ImGui.IsItemHovered and ImGui.IsItemHovered()) then return false end
    if not (ImGui.BeginTooltip and ImGui.EndTooltip) then
        tip(cell_tooltip(row, snap, slot))
        return true
    end
    local ok = pcall(ImGui.BeginTooltip)
    if not ok then
        tip(cell_tooltip(row, snap, slot))
        return true
    end
    theme.colored_text(row.entry.item or "?", row_color(row))
    tooltip_label("Status:", Theme.dim, row_label(row), row_color(row))
    if slot and slot ~= "" then
        tooltip_label("Slot:", Theme.dim, slot_display_label(slot), Theme.slot)
    end
    if row.entry.group and row.entry.group ~= "" then
        tooltip_label("Group:", Theme.dim, row.entry.group, Theme.category or Theme.cyan)
    end
    if row.entry.source and row.entry.source ~= "" then
        tooltip_label("Source:", Theme.dim, row.entry.source, Theme.category or Theme.cyan)
    end
    if snap then
        local owner = string.format("%s (%s)", snap.name or "?", class_abbrev(snap.class))
        tooltip_label("Owner:", Theme.dim, owner, class_color(snap.class))
    end
    if row.match and row.status ~= "missing" then
        local loc_color = row.status == "carried" and theme.location_color(row.match.location, row.match.where) or row_color(row)
        tooltip_label("Location:", Theme.dim, row_location(row), loc_color)
    elseif show_elsewhere() and row.elsewhere then
        tooltip_label("Available:", Theme.dim, elsewhere_location(row), BIS_ELSE)
    elseif row.status == "missing" then
        tooltip_label("Need:", Theme.dim, "not found in worn, bags, or bank", BIS_MISS)
    end
    pcall(ImGui.EndTooltip)
    return true
end

local function row_item_id(row)
    local id = row and row.match and tonumber(row.match.id)
    if id and id > 0 then return id end
    id = show_elsewhere() and row and row.elsewhere and tonumber(row.elsewhere.id)
    if id and id > 0 then return id end
    local ids = row and row.entry and row.entry.ids
    if type(ids) == "table" then
        for _, v in ipairs(ids) do
            id = tonumber(v)
            if id and id > 0 then return id end
        end
    end
    return nil
end

local function draw_item_context(row, suffix, snap, source_key)
    if not row or row.empty or not row.entry then return end
    local context_suffix = "bis_" .. tostring(suffix or row.entry.item or "")
    if item_actions.context_needed and not item_actions.context_needed(context_suffix) then return end
    local use_elsewhere = show_elsewhere() and row.elsewhere
    local source = use_elsewhere or row.match
    local name = use_elsewhere and row.elsewhere.name or row.entry.item or "?"
    local id = row_item_id(row)
    local opts = {
        sourceLocation = use_elsewhere and elsewhere_location(row) or (row.match and row_location(row) or ""),
        owner = use_elsewhere and row.elsewhere.owner or (snap and snap.name or nil),
        targetKey = source_key,
        slotname = row.entry.slot or row.slot or "",
        slotid = items.slot_id_for_label(row.entry.slot or row.slot or ""),
    }
    if source then
        opts = item_actions.context_opts(opts, source, use_elsewhere and row.elsewhere.owner or (snap and snap.name or nil))
    end
    item_actions.draw_context(name, id, context_suffix, opts)
end

local function compact_location(row)
    if not row or not row.match then return "" end
    if row.status == "equipped" then return row.match.slotname or row.match.where or "Equipped" end
    return row_location(row)
end

local function clean_name(name)
    return tostring(name or ""):lower():gsub("%s+", ""):gsub("[^%w_]", "")
end

local function norm_bis_item(name)
    name = tostring(name or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    name = name:gsub("%s*%(%s*[^%)]-%s*%)%s*$", "")
    name = name:gsub("%s*%[%s*[^%]]-%s*%]%s*$", "")
    name = name:gsub("%s+", " ")
    local stripped = name:gsub("%s*%d%d%d+$", "")
    if stripped ~= "" then name = stripped end
    return name:gsub("^%s+", ""):gsub("%s+$", "")
end

local function entry_key(entry, target_owner)
    entry = entry or {}
    local ids, names = {}, {}
    for _, id in ipairs(entry.ids or {}) do
        local n = tonumber(id)
        if n and n > 0 then ids[#ids + 1] = tostring(math.floor(n)) end
    end
    table.sort(ids)
    for _, name in ipairs(entry.names or { entry.item }) do
        local n = norm_bis_item(name)
        if n ~= "" then names[#names + 1] = n end
    end
    table.sort(names)
    return table.concat({
        tostring(Store.content_version or 0),
        clean_name(target_owner),
        table.concat(ids, ","),
        table.concat(names, ","),
    }, "|")
end

local function row_matches_entry_index(row, entry)
    if not row or not entry then return false end
    local rid = tonumber(row.id) or 0
    if rid > 0 then
        for _, id in ipairs(entry.ids or {}) do
            if tonumber(id) == rid then return true end
        end
    end
    local rn = norm_bis_item(row.name)
    if rn ~= "" then
        for _, name in ipairs(entry.names or { entry.item }) do
            if norm_bis_item(name) == rn then return true end
        end
    end
    return false
end

local function elsewhere_sort(a, b)
    local rank = { bags = 1, bank = 2, equipped = 3 }
    local ar = rank[tostring(a.locationGroup or a.where or "")] or 9
    local br = rank[tostring(b.locationGroup or b.where or "")] or 9
    if ar ~= br then return ar < br end
    if tostring(a.owner or "") ~= tostring(b.owner or "") then return tostring(a.owner or "") < tostring(b.owner or "") end
    return tostring(a.location or "") < tostring(b.location or "")
end

local function find_elsewhere(entry, target_snap)
    if not entry or not target_snap then return nil end
    local target_owner = target_snap.name or ""
    local key = entry_key(entry, target_owner)
    if elsewhere_cache.key ~= tostring(Store.content_version or 0) then
        elsewhere_cache = { key = tostring(Store.content_version or 0), hits = {} }
    elseif elsewhere_cache.hits[key] ~= nil then
        return elsewhere_cache.hits[key] or nil
    end
    if elsewhere_budget_until > 0 and os.clock() > elsewhere_budget_until then
        return nil
    end

    item_index.get(false)
    local target_clean = clean_name(target_owner)
    local hits = {}
    for _, row in ipairs(item_index.rows or {}) do
        if clean_name(row.owner) ~= target_clean and row_matches_entry_index(row, entry) then
            if (tonumber(row.nodrop) or 0) ~= 1 then
                hits[#hits + 1] = row
            end
        end
    end
    table.sort(hits, elsewhere_sort)
    elsewhere_cache.hits[key] = hits[1] or false
    return hits[1]
end

local function decorate_elsewhere(row, snap)
    if not row or row.empty or row.status ~= "missing" or row.elsewhere or not row.entry then return row end
    if not show_elsewhere() then return row end
    if elsewhere_budget_until > 0 and os.clock() > elsewhere_budget_until then return row end
    row.elsewhere = find_elsewhere(row.entry, snap)
    return row
end

local function scoped_source_keys()
    return views.scoped_source_keys(Settings.bisRosterScope or "online")
end

local function selected_chars()
    Settings.bisViewSelectedChars = type(Settings.bisViewSelectedChars) == "table"
        and Settings.bisViewSelectedChars or {}
    return Settings.bisViewSelectedChars
end

local function source_member_key(key)
    local name = views.source_owner_name(key)
    local clean = roster_sets.clean_name(name)
    if clean == "" then clean = roster_sets.clean_name(key) end
    return clean, name
end

local function selected_roster_source_keys()
    return roster_sets.active_source_keys(Settings.bisRosterScope or "online", {
        view_key = SELECTED_VIEW_KEY,
    })
end

local function roster_source_keys_for_view(view_key)
    return roster_sets.active_source_keys(Settings.bisRosterScope or "online", {
        view_key = view_key or Settings.bisViewKey or "__all__",
    })
end

local function selected_count()
    local n = 0
    for _, key in ipairs(selected_roster_source_keys()) do
        if key then n = n + 1 end
    end
    return n
end

local function scope_label()
    return roster_sets.scope_label(Settings.bisRosterScope or "online")
end

local function apply_bis_roster_scope(scope)
    scope = tostring(scope or "online")
    Settings.bisRosterScope = scope
    if scope ~= "self" then cfg.apply_linked_roster_scope(scope, "bis") end
    Settings.bisViewKey = scope == "self" and "__self__" or "__all__"
    roster_cache.key = nil
    SaveSettings()
end

local function draw_scope_picker()
    if Settings.bisRosterScope == "e3" then
        apply_bis_roster_scope("online")
    end
    ImGui.SetNextItemWidth(130.0)
    if ImGui.BeginCombo("##bisscope", "Scope: " .. scope_label()) then
        bis_dropdown_open = true
        for _, opt in ipairs(roster_sets.builtin_options()) do
            if opt.key ~= "e3" then
                if ImGui.Selectable(opt.label .. "##scope_" .. opt.key, Settings.bisRosterScope == opt.key) then
                    apply_bis_roster_scope(opt.key)
                end
            end
        end
        local sets = roster_sets.list_sets()
        if #sets > 0 then
            if ImGui.Separator then ImGui.Separator() end
            for _, rec in ipairs(sets) do
                local label = string.format("%s (%d)##scope_set_%s", rec.label, rec.count or 0, rec.id)
                if ImGui.Selectable(label, Settings.bisRosterScope == rec.key) then
                    apply_bis_roster_scope(rec.key)
                end
            end
        end
        ImGui.EndCombo()
    end
end

local function checkbox_value(label, checked)
    if not ImGui.Checkbox then return checked, false end
    local rv1, rv2 = ImGui.Checkbox(label, checked and true or false)
    if type(rv2) == "boolean" then return rv1 and true or false, rv2 end
    if type(rv1) == "boolean" and rv1 ~= checked then return rv1, true end
    return checked, false
end

local function copy_members(members)
    local out = {}
    for k, v in pairs(type(members) == "table" and members or {}) do out[k] = v end
    return out
end

local function open_character_set_popup(mode)
    set_popup_mode = tostring(mode or "save")
    local current_id = roster_sets.set_id(Settings.bisRosterScope)
    if set_popup_mode == "edit" and current_id then
        local rec = roster_sets.get_set(current_id)
        set_draft_name = tostring(rec and rec.name or current_id)
        set_draft_members = copy_members(rec and rec.members or {})
    else
        set_draft_name = ""
        set_draft_members = roster_sets.members_from_source_keys(
            roster_source_keys_for_view(Settings.bisViewKey or "__all__"))
    end
    set_popup_open = true
end

local function draw_character_set_popup()
    if not set_popup_open then return end

    if ImGui.Separator then ImGui.Separator() end
    col_text(Theme.header or Theme.item, set_popup_mode == "edit" and "Edit Team" or "Save Team")
    ImGui.SameLine()
    col_text(Theme.dim, "Name and select characters.")
    ImGui.SetNextItemWidth(240.0)
    set_draft_name = input_text_hint("##bis_set_name", "Team name...", set_draft_name)

    local rows = roster_sets.known_character_rows()
    if #rows == 0 then
        col_text(Theme.dim, "No known characters yet.")
    else
        for _, row in ipairs(rows) do
            local checked = set_draft_members[row.clean] ~= nil
            local label = string.format("%s%s##bis_set_member_%s",
                tostring(row.name or "?"),
                row.status ~= "" and (" [" .. tostring(row.status) .. "]") or "",
                tostring(row.clean or row.key))
            local new_checked, changed = checkbox_value(label, checked)
            if changed then
                if new_checked then
                    set_draft_members[row.clean] = row.name
                else
                    set_draft_members[row.clean] = nil
                end
            end
        end
    end

    if themed_button("Save##bis_char_set_save", Theme.blue, 72, NAV_BTN_H) then
        local scope, detail = roster_sets.save_set(set_draft_name, set_draft_members)
        if scope then
            apply_bis_roster_scope(scope)
            status_msg = string.format("Saved character set (%s characters).", tostring(detail or "?"))
            set_popup_open = false
            return
        else
            status_msg = tostring(detail or "Could not save character set.")
        end
    end
    ImGui.SameLine()
    if themed_button("Cancel##bis_char_set_cancel", Theme.steel, 76, NAV_BTN_H) then
        set_popup_open = false
        return
    end
end

local function draw_view_picker()
    local cur = Settings.bisViewKey or "__all__"
    if cur ~= "__all__" and cur ~= SELECTED_VIEW_KEY then cur = views.validate_source_key(cur) end
    local label = cur == "__all__" and "All Characters"
        or (cur == SELECTED_VIEW_KEY and string.format("Selected (%d)", selected_count()))
        or views.source_label(cur)
    local changed = false
    ImGui.SetNextItemWidth(170.0)
    if ImGui.BeginCombo("##bisview", "Viewing: " .. label) then
        bis_dropdown_open = true
        if ImGui.Selectable("All Characters##bisview_all", cur == "__all__") then cur = "__all__"; changed = true end
        if ImGui.Separator then ImGui.Separator() end
        for _, key in ipairs(scoped_source_keys()) do
            local snap = views.source_snapshot(key)
            if snap then
                local clean, name = source_member_key(key)
                local selected = selected_chars()
                local checked = (cur == "__all__")
                    or (cur == key)
                    or (cur == SELECTED_VIEW_KEY and clean ~= "" and selected[clean] ~= nil)
                local new_checked, box_changed = checkbox_value((snap.name or name or views.source_label(key)) .. "##bisview_check_" .. tostring(key), checked)
                if box_changed then
                    if cur == "__all__" then
                        selected = roster_sets.members_from_source_keys(scoped_source_keys())
                    elseif cur ~= SELECTED_VIEW_KEY then
                        selected = {}
                        local cur_clean, cur_name = source_member_key(cur)
                        if cur_clean ~= "" then selected[cur_clean] = cur_name end
                    end
                    if clean ~= "" then
                        if new_checked then selected[clean] = name else selected[clean] = nil end
                    end
                    Settings.bisViewSelectedChars = selected
                    cur = SELECTED_VIEW_KEY
                    changed = true
                elseif ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.IsMouseDoubleClicked and ImGui.IsMouseDoubleClicked(0) then
                    cur = key
                    changed = true
                end
            end
        end
        ImGui.EndCombo()
    end
    if changed or Settings.bisViewKey ~= cur then
        Settings.bisViewKey = cur
        roster_cache.key = nil
        SaveSettings()
    end
    return cur
end

local function dsk_type12_filter()
    local v = tostring(Settings.bisDskType12FocusFilter or DSK_TYPE12_FILTER_NONE)
    if v == "" then v = DSK_TYPE12_FILTER_NONE end
    return v
end

local function dsk_type12_set_filter(v)
    v = tostring(v or DSK_TYPE12_FILTER_NONE)
    if Settings.bisDskType12FocusFilter == v then return end
    Settings.bisDskType12FocusFilter = v
    SaveSettings()
end

local function dsk_type12_rows()
    local ref = dsk_type12_ref or anguish_ref.focus_groups or anguish_ref.focus or {}
    return type(ref) == "table" and ref or {}
end

local function dsk_type12_filter_label(filter_key, catalog_id)
    filter_key = tostring(filter_key or dsk_type12_filter())
    if filter_key == DSK_TYPE12_FILTER_NONE then
        if catalog_id == "anguish" or catalog_id == "dsk" then
            return "Anguish Gear"
        end
        return "None"
    end
    if filter_key == DSK_TYPE12_FILTER_ALL then return "All" end
    return filter_key
end

local function dsk_type12_combo_label(filter_key, catalog_id)
    return "DSK Focus: " .. dsk_type12_filter_label(filter_key, catalog_id)
end

local function dsk_type12_effect_options()
    local out = {
        { key = DSK_TYPE12_FILTER_NONE, label = "None" },
        { key = DSK_TYPE12_FILTER_ALL, label = "All" },
    }
    local seen = {}
    for _, row in ipairs(dsk_type12_rows()) do
        local effect = tostring(row.effect or "")
        if effect ~= "" and not seen[effect] then
            seen[effect] = true
            out[#out + 1] = { key = effect, label = effect }
        end
    end
    return out
end

local function reset_anguish_reference_toggles(catalog_id)
    if catalog_id == "" then
        dsk_type12_set_filter(DSK_TYPE12_FILTER_NONE)
        show_armor_priority = false
        return
    end
    if not REF_LISTS_FOCUS[catalog_id] then dsk_type12_set_filter(DSK_TYPE12_FILTER_NONE) end
    if not REF_LISTS_PRIORITY[catalog_id] then show_armor_priority = false end
end

local function draw_dsk_type12_focus_record(row, idx)
    if not row then return end

    -- Focus names intentionally use a different color from item names.
    theme.colored_text(tostring(row.focus or row.effect or row.item or "?"), { 0.78, 0.62, 1.00, 1.00 })

    if row.effect and row.focus then
        ImGui.SameLine()
        col_text(Theme.dim, " - " .. tostring(row.effect))
    end

    if type(row.items) == "table" then
        for j, item in ipairs(row.items) do
            local item_name = type(item) == "table" and item.name or item
            local item_slot = type(item) == "table" and item.slot or nil
            local item_source = type(item) == "table" and item.source or nil

            col_text(Theme.dim, "  -")
            ImGui.SameLine()

            item_actions.draw_name(
                tostring(item_name or "?"),
                Theme.item,
                "dsk_type12_focus_item_" .. tostring(idx or 0) .. "_" .. tostring(j),
                nil
            )

            if item_slot and item_slot ~= "" then
                ImGui.SameLine()
                col_text(Theme.dim, "(" .. tostring(item_slot) .. ")")
            end

            if item_source and item_source ~= "" then
                ImGui.SameLine()
                col_text(Theme.amber or Theme.gold or Theme.header, " - " .. tostring(item_source))
            end
        end
    elseif row.item then
        col_text(Theme.dim, "  -")
        ImGui.SameLine()
        item_actions.draw_name(row.item, Theme.item, "anguish_focus_" .. tostring(idx or 0), nil)
    end
end

local function draw_dsk_type12_focus_reference()
    local ref = dsk_type12_rows()
    local filter_key = dsk_type12_filter()
    if filter_key == DSK_TYPE12_FILTER_NONE then return end

    local title = "DSK Type 12 Focus Augs"
    if filter_key ~= DSK_TYPE12_FILTER_ALL then
        title = title .. " - " .. filter_key
    end

    theme.colored_text(title, Theme.orange or Theme.gold or Theme.amber or Theme.category or Theme.header or Theme.cyan)

    local current_category = nil
    local shown = 0

    if filter_key ~= DSK_TYPE12_FILTER_ALL then
        for i, row in ipairs(ref) do
            if tostring(row.effect or "") == filter_key then
                shown = shown + 1
                if shown > 1 then ImGui.Spacing() end
                draw_dsk_type12_focus_record(row, i)
            end
        end
    else
        for i, row in ipairs(ref) do
            if row.category and row.category ~= current_category then
                current_category = row.category
                ImGui.Spacing()
                col_text(Theme.header or Theme.item, tostring(current_category))
            end
            shown = shown + 1
            draw_dsk_type12_focus_record(row, i)
        end
    end

    if shown == 0 then
        col_text(Theme.amber, "No DSK Type 12 focus reference rows matched this selection.")
    end
end

local function draw_anguish_reference_panel(catalog_id)
    local show_focus = REF_LISTS_FOCUS[catalog_id] and dsk_type12_filter() ~= DSK_TYPE12_FILTER_NONE
    local show_priority = REF_LISTS_PRIORITY[catalog_id] and show_armor_priority
    if not show_focus and not show_priority then return end
    local panel_h = 220.0
    if show_focus and show_priority then panel_h = 300.0 end
    if ImGui.BeginChild then
        local child_began = false
        local child_open = false
        local ok, open = pcall(function()
            return ImGui.BeginChild(
                "##bis_anguish_ref",
                ImVec2(0, panel_h),
                true,
                (ImGuiWindowFlags.HorizontalScrollbar or 0)
            )
        end)
        if ok then
            child_began = true
            child_open = (open ~= false)
        end
        if child_open then
            if show_focus then
                draw_dsk_type12_focus_reference()
            end
            if show_priority then
                if show_focus then
                    ImGui.Spacing()
                    ImGui.Separator()
                    ImGui.Spacing()
                end
                for _, row in ipairs(anguish_ref.priority or {}) do
                    col_text(Theme.header or Theme.item, tostring(row.slot or "?"))
                    ImGui.SameLine()
                    col_text(Theme.dim, tostring(row.chain or ""))
                end
            end
        end
        if child_began and ImGui.EndChild then
            ImGui.EndChild()
        end
    end
    ImGui.Spacing()
end

local function draw_single(list, snap, view_key)
    local rows = bis.evaluate(list, snap)
    local equipped, carried, missing = bis.counts(rows)
    col_text(Theme.dim, string.format("%s vs %s: %d equipped / %d carried / %d missing", snap.name or "Source", list.name, equipped, carried, missing))

    local needle = (filter or ""):lower()
    local shown = 0
    if views.begin_scroll_table("BiSHaveNeed", 6, views.scroll_table_flags(), 8.0, 220.0) then
        local ok, err = pcall(function()
            ImGui.TableSetupColumn("Status", ImGuiTableColumnFlags.WidthFixed, 70.0)
            ImGui.TableSetupColumn("Slot", ImGuiTableColumnFlags.WidthFixed, 95.0)
            ImGui.TableSetupColumn("BiS Item", ImGuiTableColumnFlags.WidthStretch, 2.5)
            ImGui.TableSetupColumn("Found Where", ImGuiTableColumnFlags.WidthStretch, 1.5)
            ImGui.TableSetupColumn("IDs", ImGuiTableColumnFlags.WidthFixed, 90.0)
            ImGui.TableSetupColumn("Find", ImGuiTableColumnFlags.WidthFixed, 56.0)
            views.setup_scroll_freeze("BiSHaveNeed", 0, 1)
            views.table_headers_centered({ "Status", "Slot", "BiS Item", "Found Where", "IDs", "Find" })
            for i, row in ipairs(rows) do
                if (not Settings.bisShowMissingOnly or row.status == "missing") and matches_filter(row, needle) then
                    decorate_elsewhere(row, snap)
                    shown = shown + 1
                    local e = row.entry
                    ImGui.TableNextRow()
                    ImGui.TableSetColumnIndex(0); col_text(row_color(row), row_label(row))
                    ImGui.TableSetColumnIndex(1); ImGui.Text(e.slot or "")
                    ImGui.TableSetColumnIndex(2); col_text(row_color(row), e.item or "?"); draw_item_context(row, "single_" .. tostring(i), snap, view_key)
                    ImGui.TableSetColumnIndex(3)
                    if row.match then
                        ImGui.Text(row_location(row))
                    elseif row.elsewhere then
                        col_text(BIS_ELSE, elsewhere_location(row))
                    else
                        ImGui.TextDisabled("-")
                    end
                    ImGui.TableSetColumnIndex(4)
                    if e.ids and #e.ids > 0 then ImGui.Text(table.concat(e.ids, ", ")) else ImGui.TextDisabled("-") end
                    ImGui.TableSetColumnIndex(5)
                    if row.status == "missing" and items.slot_id_for_label(e.slot) and themed_button("Find##bis_find_" .. tostring(i), Theme.blue) then
                        open_find_candidates(view_key, e.slot)
                    else
                        ImGui.TextDisabled("-")
                    end
                end
            end
        end)
        ImGui.EndTable()
        if not ok then status_msg = "List table error: " .. tostring(err) end
    end
    if shown == 0 then col_text(Theme.dim, "No rows match this view.") end
end

local function draw_roster(list)
    local keys = roster_source_keys_for_view(Settings.bisViewKey or "__all__")
    if #keys == 0 then col_text(Theme.amber, "No characters in this scope."); return end
    local rows_by_key, counts_by_key = {}, {}
    for _, key in ipairs(keys) do
        local snap = views.source_snapshot(key)
        rows_by_key[key] = bis.evaluate(list, snap)
        counts_by_key[key] = { bis.counts(rows_by_key[key]) }
    end

    local cols = 2 + #keys
    if views.begin_scroll_table("BiSRoster", cols, views.scroll_table_flags(), 8.0, 220.0) then
        local ok, err = pcall(function()
            ImGui.TableSetupColumn("Slot", ImGuiTableColumnFlags.WidthFixed, 95.0)
            ImGui.TableSetupColumn("BiS Item", ImGuiTableColumnFlags.WidthStretch, 2.0)
            for _, key in ipairs(keys) do
                local snap = views.source_snapshot(key)
                local c = counts_by_key[key] or { 0, 0, 0 }
                local label = string.format("%s (%d/%d/%d)", snap and snap.name or views.source_label(key), c[1] or 0, c[2] or 0, c[3] or 0)
                ImGui.TableSetupColumn(label, ImGuiTableColumnFlags.WidthStretch, 1.2)
            end
            views.setup_scroll_freeze("BiSRoster", 0, 1)
            local hdrs = { "Slot", "BiS Item" }
            for _, key in ipairs(keys) do
                local snap = views.source_snapshot(key)
                local c = counts_by_key[key] or { 0, 0, 0 }
                hdrs[#hdrs + 1] = string.format("%s (%d/%d/%d)", snap and snap.name or views.source_label(key), c[1] or 0, c[2] or 0, c[3] or 0)
            end
            views.table_headers_centered(hdrs)

            local reference_snap = views.source_snapshot(keys[1] or "__self__")
            local reference = bis.evaluate(list, reference_snap)
            if #reference == 0 and #(list.entries or {}) > 0 then
                for _, entry in ipairs(list.entries or {}) do
                    reference[#reference + 1] = { entry = entry, have = false, match = nil, status = "missing" }
                end
            end
            local needle = (filter or ""):lower()
            for i, ref in ipairs(reference) do
                local any_missing = false
                for _, key in ipairs(keys) do
                    local row = rows_by_key[key] and rows_by_key[key][i]
                    if row and row.status == "missing" then any_missing = true; break end
                end
                if (not Settings.bisShowMissingOnly or any_missing) and matches_filter(ref, needle) then
                    decorate_elsewhere(ref, reference_snap)
                    ImGui.TableNextRow()
                    ImGui.TableSetColumnIndex(0); ImGui.Text(ref.entry.slot or "")
                    ImGui.TableSetColumnIndex(1); col_text(BIS_ITEM, ref.entry.item or "?"); draw_item_context(ref, "roster_ref_" .. tostring(i), nil, nil)
                    for cidx, key in ipairs(keys) do
                        local row = rows_by_key[key] and rows_by_key[key][i]
                        ImGui.TableSetColumnIndex(1 + cidx)
                        if row then
                            decorate_elsewhere(row, views.source_snapshot(key))
                            local where = row.match and row_location(row) or (row.elsewhere and elsewhere_location(row) or "")
                            col_text(row_color(row), row_label(row) .. (where ~= "" and (" - " .. where) or ""))
                            draw_item_context(row, "roster_" .. tostring(i) .. "_" .. tostring(cidx), views.source_snapshot(key), key)
                        else
                            ImGui.TextDisabled("-")
                        end
                    end
                end
            end
        end)
        ImGui.EndTable()
        if not ok then status_msg = "Roster table error: " .. tostring(err) end
    end
    if #(list.entries or {}) == 0 then
        col_text(Theme.amber, "This list has no items yet. Add entries in Setup or right-click items -> Add to List.")
    end
    draw_bis_color_legend(density_mode())
end

local function catalog_row_matches(row, needle)
    if needle == "" then return true end
    if row.header then return tostring(row.category or ""):lower():find(needle, 1, true) ~= nil end
    local e, m = row.entry or {}, row.match or {}
    local x = show_elsewhere() and (row.elsewhere or {}) or {}
    local hay = table.concat({ row.category or "", row.slot or "", e.item or "", e.source or "", m.location or "", m.where or "", m.name or "", x.owner or "", x.location or "", x.name or "" }, " "):lower()
    return hay:find(needle, 1, true) ~= nil
end

local function trim_search(s)
    return tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function search_all_lists(needle, limit)
    needle = trim_search(needle):lower()
    if needle == "" then return {} end
    limit = tonumber(limit) or 80
    local out = {}
    for _, row in ipairs(catalog.search_items(needle, limit)) do
        out[#out + 1] = {
            kind = "catalog",
            list_id = row.list_id,
            list_name = row.list_name or row.list_label,
            name = row.name,
            slot = row.slot or "",
            classes = row.classes or "",
        }
    end
    bis.load_all()
    for _, rec in ipairs(bis.list_names()) do
        if #out >= limit then break end
        for _, entry in ipairs((rec.list or {}).entries or {}) do
            if #out >= limit then break end
            local ne = bis.normalize_entry(entry)
            for _, nm in ipairs(ne.names or { ne.item }) do
                if tostring(nm):lower():find(needle, 1, true) then
                    out[#out + 1] = {
                        kind = "user",
                        list_id = rec.id,
                        list_name = rec.name,
                        name = ne.item,
                        slot = ne.slot or "",
                        classes = rec.list and rec.list.class or "",
                    }
                    break
                end
            end
        end
    end
    return out
end

local function open_list_hit(hit)
    if not hit then return end
    if hit.kind == "user" then
        select_user_list(hit.list_id)
    else
        for _, b in ipairs(catalog.ui_list_buttons()) do
            if b.id == hit.list_id and b.group then
                select_catalog(b.group, b.rec)
                break
            end
        end
    end
    if hit.name and hit.name ~= "" then
        filter = ""
    end
    roster_cache.key = nil
end

local function draw_all_lists_search(needle)
    local hits = search_all_lists(needle, 100)
    col_text(Theme.section or Theme.cyan, string.format("All lists - %d match(es) for \"%s\"", #hits, trim_search(needle)))
    col_text(Theme.dim, "Click Go to open that list. Clear search to return to the roster view.")
    if #hits == 0 then
        col_text(Theme.amber, "No items matched across catalog or custom lists.")
        return
    end
    if views.begin_scroll_table("BiSAllListSearch", 4, views.scroll_table_flags(), 8.0, 220.0) then
        ImGui.TableSetupColumn("List", ImGuiTableColumnFlags.WidthFixed, 96.0)
        ImGui.TableSetupColumn("Item", ImGuiTableColumnFlags.WidthStretch, 2.0)
        ImGui.TableSetupColumn("Slot", ImGuiTableColumnFlags.WidthFixed, 110.0)
        ImGui.TableSetupColumn("Open", ImGuiTableColumnFlags.WidthFixed, 56.0)
        views.setup_scroll_freeze("BiSAllListSearch", 0, 1)
        views.table_headers_centered({ "List", "Item", "Slot", "Open" })
        for i, hit in ipairs(hits) do
            ImGui.TableNextRow()
            ImGui.TableSetColumnIndex(0)
            col_text(Theme.dim, hit.list_name or "?")
            ImGui.TableSetColumnIndex(1)
            col_text(Theme.item, hit.name or "?")
            ImGui.TableSetColumnIndex(2)
            col_text(Theme.dim, hit.slot ~= "" and hit.slot or "-")
            ImGui.TableSetColumnIndex(3)
            if themed_button("Go##bis_srch_" .. tostring(i), Theme.blue) then
                open_list_hit(hit)
            end
        end
        ImGui.EndTable()
    end
end

local function draw_catalog_single(list_id, snap, view_key)
    local rows = catalog.rows_for_snap(list_id, snap)
    local equipped, carried, missing = bis.counts(rows)
    col_text(Theme.dim, string.format("%s %s: %d equipped / %d carried / %d missing", snap.name or "Source", catalog.list_label(list_id), equipped, carried, missing))
    local needle = (filter or ""):lower()
    if views.begin_scroll_table("BiSCatalogSingle", 6, views.scroll_table_flags(), 8.0, 220.0) then
        local ok, err = pcall(function()
            ImGui.TableSetupColumn("Slot", ImGuiTableColumnFlags.WidthFixed, 115.0)
            ImGui.TableSetupColumn("BiS Item", ImGuiTableColumnFlags.WidthStretch, 2.5)
            ImGui.TableSetupColumn("Status", ImGuiTableColumnFlags.WidthFixed, 80.0)
            ImGui.TableSetupColumn("Found Where", ImGuiTableColumnFlags.WidthStretch, 1.5)
            ImGui.TableSetupColumn("Source", ImGuiTableColumnFlags.WidthStretch, 1.2)
            ImGui.TableSetupColumn("Find", ImGuiTableColumnFlags.WidthFixed, 56.0)
            views.setup_scroll_freeze("BiSCatalogSingle", 0, 1)
            views.table_headers_centered({ "Slot", "BiS Item", "Status", "Found Where", "Source", "Find" })
            for i, row in ipairs(rows) do
                if row.header then
                    if catalog_row_matches(row, needle) then
                        ImGui.TableNextRow()
                        draw_category_header_cell(row.category)
                        for c = 1, 5 do
                            ImGui.TableSetColumnIndex(c)
                            ImGui.TextDisabled("")
                        end
                    end
                elseif not row.empty and (not Settings.bisShowMissingOnly or row.status == "missing") and catalog_row_matches(row, needle) then
                    decorate_elsewhere(row, snap)
                    local slot_name = row.entry.slot or row.slot or ""
                    ImGui.TableNextRow()
                    ImGui.TableSetColumnIndex(0); ImGui.Text(slot_name)
                    ImGui.TableSetColumnIndex(1); col_text(row_color(row), row.entry.item or "?"); draw_item_context(row, "cat_single_" .. tostring(i), snap, view_key)
                    ImGui.TableSetColumnIndex(2); col_text(row_color(row), row_label(row))
                    ImGui.TableSetColumnIndex(3)
                    if row.match then
                        ImGui.Text(row_location(row))
                    elseif row.elsewhere then
                        col_text(BIS_ELSE, elsewhere_location(row))
                    else
                        ImGui.TextDisabled("-")
                    end
                    ImGui.TableSetColumnIndex(4); if row.entry.source then ImGui.Text(row.entry.source) else ImGui.TextDisabled("-") end
                    ImGui.TableSetColumnIndex(5)
                    if row.status == "missing" and items.slot_id_for_label(slot_name) and themed_button("Find##biscat_find_" .. tostring(i), Theme.blue) then
                        open_find_candidates(view_key, slot_name)
                    else
                        ImGui.TextDisabled("-")
                    end
                end
            end
        end)
        ImGui.EndTable()
        if not ok then status_msg = "Catalog table error: " .. tostring(err) end
    end
end

catalog_cell_text = function(row, layout, name_max)
    if not row or row.empty or not row.entry then return "-" end
    if layout == "ultra" then return status_glyph(row) end
    local item = row.entry.item or "?"
    if row.status == "equipped" and row.match then return item .. " (" .. compact_location(row) .. ")" end
    if row.elsewhere then return item .. " (" .. elsewhere_location(row) .. ")" end
    return item
end

peek_snapshot = function(key)
    if key == "__self__" then return snapshot_mod.cached() or Store.get(my_key()) end
    return Store.get(key)
end

local function roster_source_token(key)
    local store_key = key
    if key == "__self__" then store_key = my_key() end
    if Store.content_signatures and store_key then
        return tostring(Store.content_signatures[store_key] or "")
    end
    return ""
end

local function roster_cache_key(list_id, keys)
    local parts = {
        tostring(list_id or ""),
        tostring(Settings.bisShowMissingOnly),
        tostring(filter or ""),
        tostring(density_mode()),
        tostring(Settings.bisCompactFullNames),
        tostring(show_elsewhere()),
    }
    for _, key in ipairs(keys or {}) do
        parts[#parts + 1] = tostring(key) .. ":" .. roster_source_token(key)
    end
    return table.concat(parts, "|")
end

local function copy_keys(keys)
    local out = {}
    for _, key in ipairs(keys or {}) do out[#out + 1] = key end
    return out
end

local function start_roster_build_job(list_id, keys, cache_key)
    local refs = catalog.reference_rows(list_id)
    local counts_by_key, snaps_by_key = {}, {}
    local build_keys = copy_keys(keys)
    for _, key in ipairs(build_keys) do
        snaps_by_key[key] = views.source_snapshot(key)
        counts_by_key[key] = { 0, 0, 0 }
    end
    roster_build_job = {
        key = cache_key,
        list_id = list_id,
        refs = refs,
        index = 1,
        keys = build_keys,
        snaps = snaps_by_key,
        counts = counts_by_key,
        rows = {},
        needle = (filter or ""):lower(),
        started = os.clock(),
    }
end

local function finish_roster_build_job(job)
    roster_cache = { key = job.key, rows = job.rows, counts = job.counts, keys = job.keys }
    local layout, layout_cfg = roster_layout_cfg()
    if layout == "compact" or layout == "ultra" then
        roster_cache.slot_col_w = layout_cfg.slot_w or 110.0
        roster_cache.measured_char_col_w = layout_cfg.fit_w or layout_cfg.col_w or layout_cfg.min_col_w or 88.0
    else
        roster_cache.slot_col_w = measure_slot_col_w(layout, layout_cfg)
        roster_cache.measured_char_col_w = measure_roster_char_col_w(job.keys, layout, layout_cfg)
    end
    roster_build_job = nil
end

local function process_roster_build_job(cache_key)
    local job = roster_build_job
    if not job or job.key ~= cache_key then return false end
    return diag.time("ui.bis.roster_rebuild_tick", function()
        local deadline = os.clock() + 0.0035
        local refs = job.refs or {}
        while job.index <= #refs do
            local ref = refs[job.index]
            job.index = job.index + 1
            if ref.header then
                if catalog_row_matches(ref, job.needle or "") then
                    job.rows[#job.rows + 1] = { header = true, category = ref.category }
                end
            else
                local rows, any_missing, any_match = {}, false, (job.needle or "") == ""
                for _, key in ipairs(job.keys or {}) do
                    local snap = job.snaps and job.snaps[key]
                    local row = catalog.evaluate_slot(job.list_id, snap, ref.slot, ref.category)
                    rows[key] = row
                    if row and not row.header and not row.empty then
                        local c = job.counts[key]
                        if row.status == "equipped" then c[1] = (c[1] or 0) + 1
                        elseif row.status == "carried" then c[2] = (c[2] or 0) + 1
                        else c[3] = (c[3] or 0) + 1 end
                    end
                    if row and row.status == "missing" then any_missing = true end
                    if catalog_row_matches(row, job.needle or "") then any_match = true end
                end
                if any_match and (not Settings.bisShowMissingOnly or any_missing) then
                    job.rows[#job.rows + 1] = { slot = ref.slot, rows = rows }
                end
            end
            if os.clock() >= deadline then break end
        end
        if job.index > #refs then
            finish_roster_build_job(job)
            return true
        end
        return false
    end)
end

-- Right-click a character's name in the roster header -> Mute / Forget. Attaches
-- to the name text item just drawn (same BeginPopupContextItem pattern used on the
-- Lockouts/Spells tabs). roster_cache.key = nil forces a rebuild so the muted
-- character drops out of the roster immediately.
local function draw_roster_header_menu(key, name)
    if not (key and ImGui.BeginPopupContextItem) then return end
    if ImGui.BeginPopupContextItem("##hdrctx_" .. tostring(key)) then
        col_text(Theme.header or Theme.item, tostring(name or "?"))
        ImGui.Separator()
        if ImGui.Selectable("Mute (hide + skip scan)##mute_" .. tostring(key)) then
            Store.set_ignored(name, true)
            roster_cache.key = nil
        end
        if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
            ImGui.SetTooltip("Hide this character everywhere and stop scanning/announcing it (fleet-wide). Un-mute in Setup.")
        end
        if ImGui.Selectable("Forget (purge cache)##forget_" .. tostring(key)) then
            Store.forget_char(key)
            roster_cache.key = nil
        end
        if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
            ImGui.SetTooltip("Mute AND purge this character's cached inventory to reclaim memory.")
        end
        ImGui.EndPopup()
    end
end

local function draw_roster_header_cell(snap, c, layout, col_w, key)
    local cc = class_color(snap and snap.class)
    local name = snap and snap.name or "?"
    local w = column_width_now() or col_w
    local function hdr_text(color, text)
        table_col_text_centered(color, text, w)
    end
    if layout == "ultra" then
        local short = tostring(name or "?"):sub(1, 4)
        hdr_text(cc, short ~= "" and short or class_abbrev(snap and snap.class))
        draw_roster_header_menu(key, name)
    elseif layout == "compact" then
        hdr_text(cc, string.format("%s (%s)", name, class_abbrev(snap and snap.class)))
        draw_roster_header_menu(key, name)
    else
        -- Counts (#/#/#) removed from the header for vertical room; per-cell colour
        -- still conveys equipped/upgrade/missing status (see the legend below).
        hdr_text(cc, string.format("%s (%s)", name, class_abbrev(snap and snap.class)))
        draw_roster_header_menu(key, name)
    end
end

local function draw_catalog_cell(row, layout, layout_cfg, snap, slot, ridx, col_idx)
    ImGui.TableSetColumnIndex(col_idx)
    local name_max = layout_cfg and layout_cfg.name_max or 20
    if Settings.bisShowMissingOnly and row and not row.empty and row.status ~= "missing" then
        ImGui.TextDisabled("-")
        return
    end
    if row and not row.empty then
        decorate_elsewhere(row, snap)
        if layout == "ultra" then apply_ultra_cell_bg(row) end
        local txt = catalog_cell_text(row, layout, name_max)
        local clipped = false
        if layout == "ultra" then
            views.col_text_centered(row_color(row), txt, column_width_now())
        else
            local fit_w = column_width_now() or (layout_cfg and layout_cfg.fit_w)
            _, clipped = views.colored_text_fit(row_color(row), txt, fit_w)
        end
        draw_item_context(row, "cat_roster_" .. tostring(ridx) .. "_" .. tostring(col_idx), snap, nil)
        draw_cell_tooltip(row, snap, slot)
    else
        ImGui.TextDisabled("-")
    end
end

draw_bis_color_legend = function(layout)
    local _, avail_h = views.content_avail()
    if layout ~= "ultra" and (tonumber(avail_h) or 0) < 42 then
        col_text(Theme.dim, "Legend: hover BiS cells for color/status details.")
        if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
            ImGui.SetTooltip("Green = equipped\nBlue = carried\nGrey-red = missing\nRight-click cells for Inspect / Alla / Copy.")
        end
        return
    end
    if layout == "ultra" then
        col_text(BIS_GREEN, "W")
        ImGui.SameLine(); col_text(Theme.dim, "= equipped")
        ImGui.SameLine(); col_text(BIS_BAG, "B")
        ImGui.SameLine(); col_text(Theme.dim, "= carried (bag/bank)")
        if show_elsewhere() then
            ImGui.SameLine(); col_text(BIS_ELSE, "E")
            ImGui.SameLine(); col_text(Theme.dim, "= elsewhere")
        end
        ImGui.SameLine(); col_text(BIS_MISS, "X")
        ImGui.SameLine(); col_text(Theme.dim, "= missing | hover cell for full item + location")
    else
        col_text(BIS_GREEN, "Green = equipped")
        ImGui.SameLine(); col_text(BIS_BAG, "Blue = carried")
        if show_elsewhere() then
            ImGui.SameLine(); col_text(BIS_ELSE, "Gold = elsewhere")
        end
        ImGui.SameLine(); col_text(BIS_MISS, "Grey-red = missing")
        if show_elsewhere() then
            ImGui.SameLine(); col_text(BIS_ELSE, "Gold = elsewhere · ")
        end
        ImGui.SameLine(); col_text(Theme.dim, "Hover for info · Right-click for Inspect / Alla / Copy")
    end
end

local function draw_catalog_roster(list_id)
    local keys = roster_source_keys_for_view(Settings.bisViewKey or "__all__")
    local cache_key = roster_cache_key(list_id, keys)
    if roster_cache.key ~= cache_key then
        if not roster_build_job or roster_build_job.key ~= cache_key then
            start_roster_build_job(list_id, keys, cache_key)
        end
        process_roster_build_job(cache_key)
        if roster_cache.key ~= cache_key then
            if not roster_cache.rows or #roster_cache.rows == 0 then
                return
            end
        end
    end
    keys = roster_cache.keys or keys
    local layout, layout_cfg = roster_layout_cfg()
    local short_header = layout ~= "normal"
    local slot_col_w = roster_cache.slot_col_w or layout_cfg.slot_w or 145.0
    local use_fixed_columns = roster_use_fixed_columns(layout, #keys)
    local char_col_w = nil
    if use_fixed_columns then
        char_col_w = cap_char_col_w_for_viewport(
            roster_cache.measured_char_col_w or layout_cfg.min_col_w,
            #keys,
            slot_col_w,
            layout_cfg,
            layout
        )
    end
    local layout_cfg_use = {
        col_w = char_col_w or layout_cfg.col_w,
        slot_w = slot_col_w,
        name_max = layout_cfg.name_max,
        glyph = layout_cfg.glyph,
        min_col_w = layout_cfg.min_col_w,
        max_col_w = layout_cfg.max_col_w,
        fit_w = layout_cfg.fit_w,
    }
    local cols = 1 + #keys
    if cols < 1 then return end
    -- (Removed the "Tip: N characters" hint line: it cost a line of height and was
    -- a layout oscillator when it toggled. Horizontal scroll still works as before.)
    local table_flags = roster_table_flags(use_fixed_columns)
    local table_h = stable_bis_roster_table_h(44.0, 220.0)
    if views.begin_scroll_table("BiSCatalogRoster", cols, table_flags, 44.0, 220.0, table_h) then
        local ok, err = pcall(function()
            ImGui.TableSetupColumn("Slot", ImGuiTableColumnFlags.WidthFixed, layout_cfg_use.slot_w or 145.0)
            for _, key in ipairs(keys) do
                local snap = peek_snapshot(key)
                local c = roster_cache.counts[key] or { 0, 0, 0 }
                local hdr = short_header and (snap and snap.name or views.source_label(key))
                    or string.format("%s (%d/%d/%d)", snap and snap.name or views.source_label(key), c[1] or 0, c[2] or 0, c[3] or 0)
                local col_flags, col_w = char_column_flags(char_col_w, layout)
                ImGui.TableSetupColumn(hdr .. "##col_" .. tostring(key), col_flags, col_w)
            end
            views.setup_scroll_freeze("BiSCatalogRoster", 1, 1)
            ImGui.TableNextRow()
            ImGui.TableSetColumnIndex(0); col_text(Theme.header or Theme.item, "Slot")
            for cidx, key in ipairs(keys) do
                local snap = peek_snapshot(key)
                local c = roster_cache.counts[key] or { 0, 0, 0 }
                ImGui.TableSetColumnIndex(cidx)
                draw_roster_header_cell(snap, c, layout, char_col_w or layout_cfg_use.col_w or 138.0, key)
            end
            local current_collapsed = false
            for ridx, rec in ipairs(roster_cache.rows or {}) do
                if rec.header then
                    current_collapsed = category_collapsed(rec.category)
                elseif current_collapsed then
                    goto continue_roster_row
                end
                ImGui.TableNextRow()
                if rec.header then
                    draw_category_header_cell(rec.category)
                    for cidx = 1, #keys do
                        ImGui.TableSetColumnIndex(cidx)
                        ImGui.TextDisabled("")
                    end
                else
                    draw_slot_column_cell(rec)
                    for cidx, key in ipairs(keys) do
                        local snap = peek_snapshot(key)
                        local row = rec.rows and rec.rows[key]
                        draw_catalog_cell(row, layout, layout_cfg_use, snap, rec.slot, ridx, cidx)
                    end
                end
                ::continue_roster_row::
            end
        end)
        ImGui.EndTable()
        if not ok then status_msg = "Roster table error: " .. tostring(err) end
    end
    draw_bis_color_legend(layout)
end

local function draw_bis_toolbar(catalog_id)
    local view_key = Settings.bisViewKey or "__all__"
    local toolbar = {}

    toolbar[#toolbar + 1] = {
        width = 188,
        height = COMBO_ROW_H,
        draw = function()
            view_key = draw_view_picker()
        end,
    }

    toolbar[#toolbar + 1] = {
        width = 148,
        height = COMBO_ROW_H,
        draw = function()
            draw_scope_picker()
        end,
    }

    toolbar[#toolbar + 1] = {
        width = button_text_width("Save Team"),
        draw = function()
            if themed_button("Save Team##bis_save_char_set", Theme.blue, 0, NAV_BTN_H) then
                open_character_set_popup("save")
            end
        end,
    }

    if roster_sets.is_set_scope(Settings.bisRosterScope) then
        toolbar[#toolbar + 1] = {
            width = button_text_width("Edit Team"),
            draw = function()
                if themed_button("Edit Team##bis_edit_char_set", Theme.steel, 0, NAV_BTN_H) then
                    open_character_set_popup("edit")
                end
            end,
        }
        toolbar[#toolbar + 1] = {
            width = button_text_width("Delete Team"),
            draw = function()
                if themed_button("Delete Team##bis_delete_char_set", Theme.red or Theme.steel, 0, NAV_BTN_H) then
                    if roster_sets.delete_set(Settings.bisRosterScope) then
                        apply_bis_roster_scope("online")
                        status_msg = "Deleted character set."
                    end
                end
            end,
        }
    end

    toolbar[#toolbar + 1] = {
        width = 128,
        height = COMBO_ROW_H,
        draw = function()
            local missing_only = Settings.bisShowMissingOnly and true or false
            if ImGui.Checkbox then
                local rv1, rv2 = ImGui.Checkbox("Missing Only##bismissing", missing_only)
                local new_val, apply = nil, false
                if type(rv2) == "boolean" then
                    new_val, apply = rv1, rv2
                elseif type(rv1) == "boolean" and rv1 ~= missing_only then
                    new_val, apply = rv1, true
                end
                if apply then
                    Settings.bisShowMissingOnly = new_val and true or false
                    roster_cache.key = nil
                    SaveSettings()
                end
            end
        end,
    }

    toolbar[#toolbar + 1] = {
        width = button_text_width("Compact"),
        draw = function()
            local compact = density_mode() == "ultra"
            if toggle_button("Compact##bis_density_compact", compact, 0, NAV_BTN_H) then
                Settings.bisViewDensity = compact and "compact" or "ultra"
                Settings.bisCompactRows = not compact
                roster_cache.key = nil
                SaveSettings()
            end
        end,
    }

    if density_mode() == "compact" then
        local names_label = Settings.bisCompactFullNames and "Full Names" or "Short Names"
        toolbar[#toolbar + 1] = {
            width = button_text_width(names_label),
            draw = function()
                if toggle_button(names_label .. "##bis_names", Settings.bisCompactFullNames == true) then
                    Settings.bisCompactFullNames = not (Settings.bisCompactFullNames == true)
                    roster_cache.key = nil
                    SaveSettings()
                end
            end,
        }
    end

    if Settings.bisShowUserLists ~= false and Settings.bisListMode ~= "user" then
        toolbar[#toolbar + 1] = {
            width = 190,
            height = COMBO_ROW_H,
            draw = draw_custom_lists_combo,
        }
        toolbar[#toolbar + 1] = {
            width = button_text_width("Copy to Custom List"),
            draw = function()
                if themed_button("Copy to Custom List##bis_copy_catalog", Theme.sync, 0, NAV_BTN_H) then
                    copy_catalog_to_custom(catalog_id)
                end
                if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
                    ImGui.SetTooltip("Make an editable copy of this BiS catalog for the current character/class.")
                end
            end,
        }
    end

    if REF_LISTS_FOCUS[catalog_id] then
        toolbar[#toolbar + 1] = {
            width = 230,
            height = COMBO_ROW_H,
            draw = function()
                local cur = dsk_type12_filter()
                local label = dsk_type12_combo_label(cur, catalog_id)
                local changed = false
    
                ImGui.SetNextItemWidth(220.0)
    
                if ImGui.BeginCombo("##bis_dsk_type12_focus_filter", label) then
                    bis_dropdown_open = true
                    for _, opt in ipairs(dsk_type12_effect_options()) do
                        if ImGui.Selectable(
                            tostring(opt.label) .. "##bis_dsk_focus_" .. tostring(opt.key),
                            cur == opt.key
                        ) then
                            cur = opt.key
                            changed = true
                        end
                    end
    
                    ImGui.EndCombo()
                end
    
                if changed then
                    dsk_type12_set_filter(cur)
                    roster_cache.key = nil
                end
            end,
        }
    end

    if REF_LISTS_PRIORITY[catalog_id] then
        local armor_label = "Armor Class Priority"
        toolbar[#toolbar + 1] = {
            width = button_text_width(armor_label),
            draw = function()
                if toggle_button(armor_label .. "##bis_armor_pri", show_armor_priority) then
                    show_armor_priority = not show_armor_priority
                end
            end,
        }
    end

    if not draw_fixed_control_row(toolbar) then
        draw_wrapped_controls(toolbar)
    end
    draw_character_set_popup()
    return view_key
end

local function draw_bis_body()
    bis_dropdown_open = false
    elsewhere_budget_until = os.clock() + 0.0025
    ensure_density_defaults()
    ensure_visible_catalog()
    if Settings.bisListMode ~= "user" then
        draw_catalog_buttons()
        ImGui.Spacing()
    end
    draw_bis_search()
    local catalog_id = (Settings.bisListMode ~= "user") and selected_catalog_id() or ""
    if catalog_id ~= "" then
        reset_anguish_reference_toggles(catalog_id)
    end
    local view_key = draw_bis_toolbar(catalog_id)
    if Settings.bisListMode == "user" then
        draw_my_lists_header()
    end
    if (Settings.bisRosterScope or "online") == "self" then
        view_key = "__self__"
    end
    draw_announce_disabled_warning()
    draw_anguish_reference_panel(catalog_id)
    draw_linked_items_panel()
    ImGui.Separator()
    if view_key ~= "__all__" then
        col_text(Theme.dim, "Single-character checklist - set Viewing to All Characters for the multi-column roster.")
    end

    local density = density_mode()
    local density_style = (density == "compact" or density == "ultra") and theme.push_density_style(density) or nil
    local search_needle = trim_search(filter)
    local draw_ok, draw_err = pcall(function()
        local user_list = active_user_list()
        if search_needle ~= "" then
            draw_all_lists_search(search_needle)
        elseif Settings.bisListMode == "user" then
            if not user_list then
                col_text(Theme.amber, "No custom lists yet. Right-click an item -> Add to List..., or create one in Manage Lists.")
                if themed_button("Open Manage Lists##bis_custom_setup", Theme.blue) then
                    Settings.mainTab = "bis"
                    Settings.bisListsTab = "edit"
                    Settings.bisListMode = "user"
                    SaveSettings()
                end
            elseif view_key == "__all__" or view_key == SELECTED_VIEW_KEY then
                draw_roster(user_list)
            else
                local snap = views.source_snapshot(view_key)
                if snap then draw_single(user_list, snap, view_key)
                else col_text(Theme.amber, "No data for selected character.") end
            end
        else
            catalog_id = selected_catalog_id()
            if catalog_id == "" then
                col_text(Theme.amber, "No catalog data loaded.")
            elseif view_key == "__all__" or view_key == SELECTED_VIEW_KEY then
                draw_catalog_roster(catalog_id)
            else
                local snap = views.source_snapshot(view_key)
                if snap then draw_catalog_single(catalog_id, snap, view_key)
                else col_text(Theme.amber, "No data for selected character.") end
            end
        end
    end)
    if density_style then theme.pop_density_style(density_style) end
    if not draw_ok then status_msg = "TurboBiS draw error: " .. tostring(draw_err) end
    local action_status = item_actions.status()
    if action_status and action_status ~= "" then col_text(Theme.dim, action_status)
    elseif status_msg and status_msg ~= "" then col_text(Theme.dim, status_msg) end
end

function M.draw()
    return diag.time("ui.bis.draw", draw_bis_body)
end

function M.set_filter(text)
    filter = tostring(text or "")
end

function M.open_catalog_list(list_id, search_text)
    list_id = tostring(list_id or "")
    if list_id == "" then return end
    for _, b in ipairs(catalog.ui_list_specs()) do
        if b.id == list_id and b.group then
            select_catalog(b.group, b.rec)
            break
        end
    end
    if search_text and tostring(search_text) ~= "" then
        filter = tostring(search_text)
    end
end

return M
