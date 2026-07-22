-- TurboGear/tabs/setup.lua
-- Setup tab: sync status + traffic counters + peer list, launch/stop/clean-restart
-- peers, print login auto-start, broadcast method, debug + display toggles.

local ImGui = require('ImGui')
local mq    = require('mq')
local theme = require('theme')
local Theme, col_text = theme.Theme, theme.col_text
local themed_button, toggle_button, section_header = theme.themed_button, theme.toggle_button, theme.section_header
local collapsing_section = theme.collapsing_section
local cfg = require('config')
local CFG, Settings, SaveSettings = cfg.CFG, cfg.Settings, cfg.SaveSettings
local SharedSettings, SaveSharedSettings = cfg.SharedSettings, cfg.SaveSharedSettings
local BIS_ANNOUNCE_PRESETS = cfg.BIS_ANNOUNCE_PRESETS
local store = require('store')
local Store, my_key = store.Store, store.my_key
local Engine = require('engine').Engine
local views = require('views')
local status_color, status_tag = views.status_color, views.status_tag
local empty_tab = require('tabs.empty')
local bis = require('bis')
local catalog = require('bis_catalog')
local userlists = require('userlists')
local userlists_ui = require('tabs.userlists_ui')
local announcer = require('announcer')
local items = require('items')
local lockouts = require('lockouts')
local diag = require('diagnostics')
local peer_discovery = require('peer_discovery')
local runtime_state = require('state')

local M = {}

local ul_status = ""            -- last user-list action result (shown in section)
local ul_edit_list_id = ""      -- selected list for in-app editor
local ul_add_item = ""
local ul_add_ids = ""
local ul_add_slot = ""
local ul_add_group = ""
local ul_add_socket = ""
local ul_add_kind = "gear"
local ul_add_slot_pick = ""
local ul_bulk_buf = ""
local ul_save_name = ""
local ul_import_name = ""
local ul_entry_filter = ""
local ul_found = nil
local ul_confirm_delete = nil
local ul_show_slot_layout = false
local draw_user_lists           -- legacy compact list section, retained as fallback

local function trim(s)
    -- gsub returns (string, count); tonumber(trim(x)) must not see the count as base.
    return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function age_label(ts)
    local last = tonumber(ts) or 0
    if last <= 0 then return "never" end
    local age = math.max(0, os.time() - last)
    if age < 60 then return tostring(age) .. "s ago" end
    if age < 3600 then return tostring(math.floor(age / 60)) .. "m ago" end
    return tostring(math.floor(age / 3600)) .. "h ago"
end

local function bank_label(snap)
    if type(snap) ~= "table" then return "Bank: no local snapshot yet", Theme.amber end
    local count = #(snap.bank or {})
    if snap.bankLive == true then
        return string.format("Bank: live now (%d item%s)", count, count == 1 and "" or "s"), Theme.online
    end
    if snap.bankValid == true then
        return string.format("Bank: cached %s (%d item%s)", age_label(snap.bankCapturedAt or snap.inventoryUpdated or snap.updated), count, count == 1 and "" or "s"), Theme.dim
    end
    return "Bank: not synced yet - open a bank and use Sync Bank.", Theme.amber
end

local function parse_id_list(text, item_field)
    local ids = {}
    local seen = {}
    local function add_id(n)
        n = tonumber(n)
        if n and n > 0 and not seen[n] then
            seen[n] = true
            ids[#ids + 1] = math.floor(n)
        end
    end
    for part in tostring(text or ""):gmatch("[^,]+") do
        add_id(trim(part))
    end
    local lone = trim(item_field)
    if lone ~= "" and tonumber(lone) then add_id(lone) end
    return ids
end

local function entries_for_slot_labels(list)
    local by_slot = {}
    for _, entry in ipairs(list.entries or {}) do
        local slot = trim(entry.slot)
        if slot ~= "" then
            local slot_id = items.slot_id_for_label(slot)
            local key = slot_id and tostring(slot_id) or slot:lower()
            if not by_slot[key] then by_slot[key] = entry end
        end
    end
    return by_slot
end

local function slot_pick_options()
    local out = {}
    for _, group in ipairs(items.grouped_slots()) do
        for _, slot in ipairs(group.slots or {}) do
            out[#out + 1] = { id = slot.id, label = slot.label or items.slot_display_name(slot.id) }
        end
    end
    return out
end

local function draw_slot_picker()
    local picks = slot_pick_options()
    local label = ul_add_slot_pick ~= "" and ul_add_slot_pick or "Pick worn slot"
    ImGui.SetNextItemWidth(130.0)
    if ImGui.BeginCombo("##ul_add_slot_pick", label) then
        for _, pick in ipairs(picks) do
            if ImGui.Selectable(pick.label .. "##ul_slot_pick_" .. tostring(pick.id), ul_add_slot_pick == pick.label) then
                ul_add_slot_pick = pick.label
                ul_add_slot = pick.label
            end
        end
        ImGui.EndCombo()
    end
end

local function draw_list_slot_layout(list)
    local by_slot = entries_for_slot_labels(list)
    if views.begin_scroll_table("UserListSlotLayout", 3, views.scroll_table_flags(), 12.0, 220.0) then
        ImGui.TableSetupColumn("Slot", ImGuiTableColumnFlags.WidthFixed, 110.0)
        ImGui.TableSetupColumn("Item", ImGuiTableColumnFlags.WidthStretch, 2.0)
        ImGui.TableSetupColumn("IDs", ImGuiTableColumnFlags.WidthFixed, 90.0)
        pcall(function() ImGui.TableSetupScrollFreeze(0, 1) end)
        views.table_headers_centered({ "Slot", "Item", "IDs" })
        for _, group in ipairs(items.grouped_slots()) do
            ImGui.TableNextRow()
            ImGui.TableSetColumnIndex(0)
            col_text(Theme.category or Theme.cyan, group.label or "?")
            ImGui.TableSetColumnIndex(1); ImGui.TextDisabled("")
            ImGui.TableSetColumnIndex(2); ImGui.TextDisabled("")
            for _, slot in ipairs(group.slots or {}) do
                local key = tostring(slot.id)
                local entry = by_slot[key] or by_slot[trim(slot.label):lower()]
                ImGui.TableNextRow()
                ImGui.TableSetColumnIndex(0)
                col_text(Theme.slot or Theme.dim, slot.label or "?")
                ImGui.TableSetColumnIndex(1)
                if entry then
                    col_text(Theme.item, entry.item or "?")
                else
                    col_text(Theme.missing or Theme.amber, "- (empty)")
                end
                ImGui.TableSetColumnIndex(2)
                if entry and type(entry.ids) == "table" and #entry.ids > 0 then
                    col_text(Theme.dim, table.concat(entry.ids, ", "))
                else
                    ImGui.TextDisabled("-")
                end
            end
        end
        ImGui.EndTable()
    end
    col_text(Theme.dim, "Standard worn layout. Assign Slot when adding gear; use Group=Aug + Socket for planned augs on that item.")
end

local function entry_is_aug(entry)
    return trim(entry and entry.group):lower():find("aug", 1, true) ~= nil
end

local function toggle_setting(label, key)
    local active = Settings[key] ~= false
    if toggle_button(label .. "##setup_" .. key, active) then
        Settings[key] = not active
        SaveSettings()
    end
end

local function draw_focus_display_settings()
    col_text(Theme.dim, "Choose optional Focus table columns.")
    toggle_setting("Kind", "focusColKind")
    ImGui.SameLine()
    toggle_setting("Value", "focusColValue")
    ImGui.SameLine()
    toggle_setting("Level", "focusColLevel")
    ImGui.SameLine()
    toggle_setting("Spell Type", "focusColSpellType")
    ImGui.SameLine()
    toggle_setting("Resist", "focusColResist")
    if Settings.setupFocusDisplayJump then
        if ImGui.SetScrollHereY then pcall(ImGui.SetScrollHereY, 0.35) end
        Settings.setupFocusDisplayJump = false
        SaveSettings()
    end
end

local function setup_button_text_width(text)
    if not ImGui.CalcTextSize then return 120.0 end
    local ok, w = pcall(ImGui.CalcTextSize, tostring(text or ""))
    if not ok then return 120.0 end
    if type(w) == "table" then w = tonumber(w.x or w[1]) or 0 end
    return math.max((tonumber(w) or 0) + 22.0, 44.0)
end

local function setup_content_avail_x()
    local avail = ImGui.GetContentRegionAvail and ImGui.GetContentRegionAvail() or 0
    if type(avail) == "table" then return tonumber(avail.x or avail[1]) or 0 end
    return tonumber(avail) or 0
end

local function draw_bis_list_visibility()
    col_text(Theme.dim, "Lists on the TurboBiS tab (off hides the list button there).")
    local specs = catalog.ui_list_specs()
    local x0, y0 = 0, 0
    if ImGui.GetCursorPos then x0, y0 = ImGui.GetCursorPos(); x0, y0 = tonumber(x0) or 0, tonumber(y0) or 0 end
    local line_w = setup_content_avail_x()
    local row_x, row_y = x0, y0
    local row_h = 24.0
    for idx, spec in ipairs(specs) do
        local visible = not catalog.list_hidden(spec.id)
        local label = string.format("%s: %s", spec.label, visible and "ON" or "OFF")
        local est_w = setup_button_text_width(label)
        if idx > 1 and (row_x + est_w > x0 + line_w + 0.5) then
            row_x, row_y = x0, row_y + row_h + 4
        end
        if ImGui.SetCursorPos then ImGui.SetCursorPos(row_x, row_y) end
        if toggle_button(label .. "##setup_bislist_" .. spec.id, visible) then
            catalog.set_list_hidden(spec.id, visible)
        end
        row_x = row_x + est_w + 4
    end
    if ImGui.SetCursorPos then ImGui.SetCursorPos(x0, row_y + row_h + 4) end
end

local function draw_bis_announce_visibility()
    col_text(Theme.dim, "Announce linked needs from these lists (off = still visible on tab, won't chat announce). All ON by default.")
    local specs = catalog.announce_list_specs()
    local x0, y0 = 0, 0
    if ImGui.GetCursorPos then x0, y0 = ImGui.GetCursorPos(); x0, y0 = tonumber(x0) or 0, tonumber(y0) or 0 end
    local line_w = setup_content_avail_x()
    local row_x, row_y = x0, y0
    local row_h = 24.0
    for idx, spec in ipairs(specs) do
        local enabled = catalog.list_announce_enabled(spec.id)
        local prefix = spec.user and "Custom: " or ""
        local label = string.format("%s%s: %s", prefix, spec.label, enabled and "Announce ON" or "Announce OFF")
        local est_w = setup_button_text_width(label)
        if idx > 1 and (row_x + est_w > x0 + line_w + 0.5) then
            row_x, row_y = x0, row_y + row_h + 4
        end
        if ImGui.SetCursorPos then ImGui.SetCursorPos(row_x, row_y) end
        if toggle_button(label .. "##setup_bisann_" .. spec.id, enabled) then
            catalog.set_list_announce_enabled(spec.id, not enabled)
        end
        row_x = row_x + est_w + 4
    end
    if ImGui.SetCursorPos then ImGui.SetCursorPos(x0, row_y + row_h + 4) end
end

local function draw_bis_list_matrix()
    col_text(Theme.section or Theme.header, "TurboBiS Lists")
    col_text(Theme.dim, "Tab visibility moved to the List picker on the BiS + Lists tab.")
    col_text(Theme.dim, "Announce controls linked-needs chat for that list (display is unchanged).")
    local announce_specs = catalog.announce_list_specs()
    if views.begin_scroll_table("SetupTurboBiSListMatrix", 2, views.scroll_table_flags(), 92.0, 260.0) then
        ImGui.TableSetupColumn("List", ImGuiTableColumnFlags.WidthStretch, 1.6)
        ImGui.TableSetupColumn("Announce", ImGuiTableColumnFlags.WidthFixed, 98.0)
        views.table_headers_centered({ "List", "Announce" })
        for _, spec in ipairs(announce_specs or {}) do
            local enabled = catalog.list_announce_enabled(spec.id)
            ImGui.TableNextRow()
            ImGui.TableSetColumnIndex(0)
            local prefix = spec.user and "Custom: " or ""
            col_text(spec.user and (Theme.purple or Theme.item) or Theme.item, prefix .. tostring(spec.label or spec.id or "?"))
            ImGui.TableSetColumnIndex(1)
            if toggle_button((enabled and "ON" or "OFF") .. "##setup_bis_matrix_ann_" .. tostring(spec.id), enabled, 64, 0) then
                catalog.set_list_announce_enabled(spec.id, not enabled)
            end
        end
        ImGui.EndTable()
    end
end

local function draw_announce_status()
    local st = announcer.status()
    col_text(Theme.section or Theme.header, "Linked-needs status")
    local ready_col = st.ready and Theme.online or Theme.amber
    col_text(ready_col, string.format("Index: %s  |  Pending: %d  |  Lists announcing: %d/%d",
        st.index_label or (st.ready and "ready" or "warming"), st.pending or 0, st.lists_on or 0, st.lists_total or 0))
    col_text(Theme.dim, string.format("Transport: actor %s  |  chat fallback  |  respond via %s",
        st.actor and "ON" or "OFF", tostring(st.channel or "/g")))
    if st.last_loot_item ~= "" then
        col_text(Theme.dim, string.format("Last loot seen: %s (%s, %s)",
            st.last_loot_item, st.last_loot_source or "?", st.last_loot_age or "?"))
    else
        col_text(Theme.dim, "Last loot seen: never (post a linked [ANNOUNCE] or loot line in group)")
    end
    if st.last_sent_item ~= "" then
        col_text(Theme.online, string.format("Last [TG] sent: %s (%s)", st.last_sent_item, st.last_sent_age or "?"))
    elseif st.last_skip_item ~= "" then
        col_text(Theme.amber, string.format("Last skip: %s - %s (%s)",
            st.last_skip_item, st.last_skip_reason or "?", st.last_skip_age or "?"))
    end
    if not st.ready then
        col_text(Theme.amber, "Catalog still warming — wait a few seconds after startup before pulling.")
    end
    if st.enabled and not st.actor then
        col_text(Theme.amber, "Actor transport OFF — peers only hear group chat (less reliable).")
    end
    ImGui.Spacing()
    if themed_button("Apply recommended announcing defaults", Theme.purple) then
        cfg.apply_bis_announcing_defaults()
        announcer.invalidate()
        announcer.warm(true)
    end
    if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
        ImGui.SetTooltip("Turns on linked needs, actor transport, auto-launch peers, auto-stop peers, and group channel.")
    end
end

local function draw_turbobis_settings()
    draw_announce_status()
    ImGui.Spacing()
    if toggle_button(SharedSettings.bisAnnounceEnabled and "Linked needs: ON" or "Linked needs: OFF", SharedSettings.bisAnnounceEnabled) then
        SharedSettings.bisAnnounceEnabled = not SharedSettings.bisAnnounceEnabled
        SaveSharedSettings()
        announcer.invalidate()
    end
    ImGui.SameLine()
    if toggle_button(SharedSettings.announceUseActor ~= false and "Actor transport: ON" or "Actor transport: OFF", SharedSettings.announceUseActor ~= false) then
        SharedSettings.announceUseActor = not (SharedSettings.announceUseActor ~= false)
        SaveSharedSettings()
    end
    if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
        ImGui.SetTooltip("Looter broadcasts LOOT_LINK to all TurboGear boxes (reliable). Chat remains a fallback.")
    end
    ImGui.SameLine(); ImGui.Text("Method:"); ImGui.SameLine(); ImGui.SetNextItemWidth(190.0)
    local cur = BIS_ANNOUNCE_PRESETS[SharedSettings.bisAnnounceIdx or 2] or BIS_ANNOUNCE_PRESETS[2]
    if ImGui.BeginCombo("##setup_bisannounce", cur.label) then
        for i, p in ipairs(BIS_ANNOUNCE_PRESETS) do
            if ImGui.Selectable(p.label, SharedSettings.bisAnnounceIdx == i) then
                SharedSettings.bisAnnounceIdx = i
                SaveSharedSettings()
            end
        end
        ImGui.EndCombo()
    end
    if themed_button("Become announce driver##setup_become_coord", Theme.purple) then
        local label = announcer.become_announce_driver and announcer.become_announce_driver() or "?"
        ul_status = "Announce driver: " .. tostring(label)
    end
    if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
        ImGui.SetTooltip("Claim sticky [TG] announce driver for your current EQ group. Other same-group TurboGear UIs defer while you hold it.")
    end
    do
        local coord = announcer.coordinator_label and announcer.coordinator_label() or "?"
        col_text(Theme.dim, "Announce driver: " .. tostring(coord))
        col_text(Theme.dim, "Needer names follow BiS Characters Source + columns. Selected List pill is viewing only; [TG] uses all announce-enabled lists.")
    end
    if BIS_ANNOUNCE_PRESETS[SharedSettings.bisAnnounceIdx or 2] and BIS_ANNOUNCE_PRESETS[SharedSettings.bisAnnounceIdx or 2].cmd == nil then
        ImGui.SameLine(); ImGui.SetNextItemWidth(140.0)
        local nv = ImGui.InputText("##setup_bisannouncecustom", SharedSettings.bisAnnounceCustom or "/g") or "/g"
        if nv ~= SharedSettings.bisAnnounceCustom then SharedSettings.bisAnnounceCustom = nv; SaveSharedSettings() end
    end
    ImGui.Spacing()
    if toggle_button(SharedSettings.bisAnnounceListenGuild == true and "Listen guild links: ON" or "Listen guild links: OFF", SharedSettings.bisAnnounceListenGuild == true) then
        SharedSettings.bisAnnounceListenGuild = not (SharedSettings.bisAnnounceListenGuild == true)
        SaveSharedSettings()
        announcer.invalidate()
    end
    if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
        ImGui.SetTooltip("When ON, item links in guild chat can trigger linked-needs announces. Off by default.")
    end
    ImGui.SameLine()
    if toggle_button(SharedSettings.bisAnnounceListenOoc == true and "Listen OOC links: ON" or "Listen OOC links: OFF", SharedSettings.bisAnnounceListenOoc == true) then
        SharedSettings.bisAnnounceListenOoc = not (SharedSettings.bisAnnounceListenOoc == true)
        SaveSharedSettings()
        announcer.invalidate()
    end
    if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
        ImGui.SetTooltip("When ON, item links in OOC can trigger linked-needs announces. Off by default.")
    end
    col_text(Theme.dim, "Linked-needs announce is shared across all TurboGear characters on this install.")
    col_text(Theme.dim, "Guild/OOC link listening is off by default; group/raid/say still work when Linked needs is ON.")
    col_text(Theme.dim, "Roster Compact toggle is on the TurboBiS tab.")
    col_text(Theme.dim, "Add custom lockouts on the Lockouts tab (Add Lockout panel).")

    ImGui.Spacing()
    if toggle_button(Settings.bisShowUserLists ~= false and "Custom Lists row: ON" or "Custom Lists row: OFF", Settings.bisShowUserLists ~= false) then
        Settings.bisShowUserLists = not (Settings.bisShowUserLists ~= false)
        SaveSettings()
    end
    ImGui.Spacing()
    draw_bis_list_matrix()
end

local function input_text_hint(id, hint, value)
    if ImGui.InputTextWithHint then
        local ok, rv = pcall(ImGui.InputTextWithHint, id, hint, value or "")
        if ok then return rv or "" end
    end
    return ImGui.InputText(id, value or "") or ""
end

local function select_editor_list(list_id)
    list_id = tostring(list_id or "")
    if list_id == "" then return end
    ul_edit_list_id = list_id
    Settings.bisListMode = "user"
    Settings.bisSelectedList = list_id
    Settings.bisListsTab = "edit"
    SaveSettings()
end

local function current_editor_list(names)
    names = names or bis.list_names()
    if Settings.bisSelectedList ~= "" and bis.get(Settings.bisSelectedList) then
        ul_edit_list_id = Settings.bisSelectedList
    elseif ul_edit_list_id == "" or not bis.get(ul_edit_list_id) then
        ul_edit_list_id = names[1] and names[1].id or ""
    end
    return ul_edit_list_id ~= "" and bis.get(ul_edit_list_id) or nil
end

local function draw_new_import_row()
    ImGui.SetNextItemWidth(210.0)
    ul_save_name = input_text_hint("##ul_editor_new_name", "New list name (optional)", ul_save_name)
    ImGui.SameLine()
    if themed_button("New List##ul_editor_new", Theme.blue) then
        local list, err = userlists.create_empty(ul_save_name)
        if list then
            ul_status = string.format("Created '%s'.", list.name)
            ul_save_name = ""
            select_editor_list(list.id)
        else
            ul_status = err or "Could not create list."
        end
    end
    ImGui.SameLine()
    if themed_button("New from Worn##ul_editor_worn", Theme.steel) then
        local snap = views.source_snapshot("__self__")
        local list, err = userlists.save_worn(snap, ul_save_name)
        if list then
            ul_status = string.format("Saved '%s' (%d entries).", list.name, #(list.entries or {}))
            ul_save_name = ""
            select_editor_list(list.id)
        else
            ul_status = err or "Could not save worn list."
        end
    end

    ImGui.SetNextItemWidth(250.0)
    ul_import_name = input_text_hint("##ul_editor_import_name", "File name or path to import", ul_import_name)
    ImGui.SameLine()
    if themed_button("Import##ul_editor_import", Theme.purple) then
        local list, err = userlists.import(ul_import_name)
        if list then
            ul_status = string.format("Imported '%s' (%d entries).", list.name, #(list.entries or {}))
            ul_import_name = ""
            ul_found = nil
            select_editor_list(list.id)
        else
            ul_status = err or "Import failed."
        end
    end
    ImGui.SameLine()
    if themed_button("Rescan##ul_editor_rescan", Theme.steel) then ul_found = nil end
    ImGui.SameLine()
    if themed_button("Open Config##ul_editor_open_cfg", Theme.steel) then
        local ok, detail = userlists.open_config_folder()
        ul_status = ok and ("Opened Config: " .. tostring(detail or "")) or tostring(detail or "Could not open Config.")
    end

    if ul_found == nil then ul_found = userlists.scan_importables() end
    if #ul_found > 0 then
        col_text(Theme.dim, "Found in Config:")
        for i, f in ipairs(ul_found) do
            if i > 1 then ImGui.SameLine() end
            if themed_button(f .. "##ul_editor_found_" .. tostring(i), Theme.steel) then ul_import_name = f end
        end
    end
end

local function draw_editor_header(names, edit_list)
    section_header("List", Theme.section or Theme.header)
    if #names == 0 then
        draw_new_import_row()
        col_text(Theme.dim, "Create or import a list to start adding entries.")
        return
    end

    ImGui.Text("List:")
    ImGui.SameLine()
    ImGui.SetNextItemWidth(260.0)
    local edit_label = edit_list and edit_list.name or "Select list"
    if ImGui.BeginCombo("##ul_editor_list", edit_label) then
        for _, rec in ipairs(names) do
            if ImGui.Selectable(rec.name .. "##ul_editor_pick_" .. rec.id, ul_edit_list_id == rec.id) then
                select_editor_list(rec.id)
                edit_list = bis.get(rec.id)
            end
        end
        ImGui.EndCombo()
    end
    if edit_list then
        ImGui.SameLine()
        col_text(Theme.dim, string.format("%d entries%s",
            #(edit_list.entries or {}),
            (edit_list.class and edit_list.class ~= "") and ("  " .. edit_list.class) or ""))
    end

    if edit_list then
        local list_id = edit_list.id or ul_edit_list_id
        if themed_button("Announce Needs##ul_editor_ann", Theme.sync) then
            local ok, detail = userlists.prepare_for_announces(list_id)
            ul_status = ok
                and string.format("'%s' is active for linked-needs announces.", tostring(detail or edit_list.name))
                or tostring(detail or "Could not enable announces.")
        end
        ImGui.SameLine()
        if themed_button("Analyze##ul_editor_analyze", Theme.blue) then
            local ok_lo, loadout = pcall(require, 'loadout')
            if ok_lo and loadout and loadout.open_analyze_list then
                loadout.open_analyze_list(list_id)
            end
        end
        ImGui.SameLine()
        if themed_button("Compare Worn##ul_editor_compare_worn", Theme.cyan) then
            local ok_cmp, cmp = pcall(require, 'tabs.compare')
            if ok_cmp and cmp and cmp.open_worn_vs_list then cmp.open_worn_vs_list(list_id) end
        end
        ImGui.SameLine()
        if themed_button("Compare List##ul_editor_compare_list", Theme.cyan) then
            local ok_cmp, cmp = pcall(require, 'tabs.compare')
            if ok_cmp and cmp and cmp.open_list_vs_list then cmp.open_list_vs_list(list_id) end
        end
        ImGui.SameLine()
        if themed_button("Export##ul_editor_export", Theme.blue) then
            local path, err = userlists.export(list_id)
            if path then
                pcall(userlists.open_config_folder)
                ul_status = "Exported " .. tostring(path)
            else
                ul_status = err or "Export failed."
            end
        end
        ImGui.SameLine()
        if themed_button("Share##ul_editor_share", Theme.purple) then
            local ok, detail = userlists.share_list(list_id)
            ul_status = ok
                and string.format("Shared '%s' to online TurboGear peers.", tostring(detail or edit_list.name))
                or tostring(detail or "Share failed.")
        end
        ImGui.SameLine()
        if themed_button("Duplicate##ul_editor_dup", Theme.steel) then
            local copy, err = userlists.duplicate(list_id)
            if copy then
                ul_status = string.format("Duplicated as '%s'.", copy.name)
                select_editor_list(copy.id)
            else
                ul_status = err or "Duplicate failed."
            end
        end
        ImGui.SameLine()
        if themed_button("Add Worn##ul_editor_add_worn", Theme.steel) then
            local snap = views.source_snapshot("__self__")
            local list, info = userlists.merge_worn_missing(snap, list_id)
            ul_status = list and string.format("Added %d worn item(s) to '%s'.", tonumber(info) or 0, list.name)
                or tostring(info or "Could not add worn items.")
        end
        ImGui.SameLine()
        if ul_confirm_delete == list_id then
            if themed_button("Confirm Delete##ul_editor_del_confirm", Theme.amber) then
                local ok, err = userlists.delete(list_id)
                ul_status = ok and ("Deleted '" .. tostring(edit_list.name or list_id) .. "'.") or (err or "Delete failed.")
                ul_confirm_delete = nil
                ul_edit_list_id = ""
                Settings.bisSelectedList = ""
                SaveSettings()
            end
            ImGui.SameLine()
            if themed_button("Cancel##ul_editor_del_cancel", Theme.steel) then ul_confirm_delete = nil end
        elseif themed_button("Delete##ul_editor_delete", Theme.steel) then
            ul_confirm_delete = list_id
        end
    end

    ImGui.Spacing()
    draw_new_import_row()
end

local function draw_bulk_add(edit_list)
    section_header("Bulk Add", Theme.section or Theme.header)
    ImGui.SetNextItemWidth(-1)
    ul_bulk_buf = input_text_hint("##ul_editor_bulk_paste", "Paste item names or IDs, comma-separated", ul_bulk_buf)
    if themed_button("Add Items##ul_editor_bulk_add", Theme.blue) then
        local list, added, extra = userlists.add_entries_bulk(ul_edit_list_id, ul_bulk_buf)
        if list then
            local skip = (tonumber(extra) or 0) > 0 and string.format(" (%d skipped)", extra) or ""
            ul_status = string.format("Added %d item(s) to '%s'%s.", tonumber(added) or 0, list.name, skip)
            ul_bulk_buf = ""
        else
            ul_status = tostring(added or extra or "Bulk add failed.")
        end
    end
end

local function draw_quick_add()
    section_header("Quick Add", Theme.section or Theme.header)
    if toggle_button("Gear##ul_editor_kind_gear", ul_add_kind == "gear") then
        ul_add_kind = "gear"
        ul_add_group = "Worn"
    end
    ImGui.SameLine()
    if toggle_button("Aug##ul_editor_kind_aug", ul_add_kind == "aug") then
        ul_add_kind = "aug"
        ul_add_group = "Aug"
    end
    ImGui.SameLine()
    if themed_button("Use Cursor Item##ul_editor_cursor_item", Theme.sync) then
        local cur = mq.TLO.Cursor
        if cur and cur() then
            ul_add_item = cur.Name() or ""
            local id = tonumber(cur.ID()) or 0
            if id > 0 then ul_add_ids = tostring(math.floor(id)) end
            ul_status = "Captured cursor item: " .. tostring(ul_add_item)
        else
            ul_status = "No item on cursor - pick one up in-game first."
        end
    end
    ImGui.SameLine()
    if themed_button("Add Cursor Item##ul_editor_cursor_add", Theme.blue) then
        local cur = mq.TLO.Cursor
        if not (cur and cur()) then
            ul_status = "No item on cursor - pick one up in-game first."
        else
            ul_add_item = cur.Name() or ""
            local ids = {}
            local id = tonumber(cur.ID()) or 0
            if id > 0 then ids[#ids + 1] = math.floor(id) end
            local list, err = bis.add_entry(ul_edit_list_id, {
                item = ul_add_item,
                ids = ids,
                slot = ul_add_slot,
                group = ul_add_kind == "aug" and "Aug" or "Worn",
                socket = ul_add_kind == "aug" and tonumber(ul_add_socket or "1") or nil,
            })
            if list then
                ul_status = string.format("Added '%s' from cursor to '%s' (%d total).", ul_add_item, list.name, #(list.entries or {}))
                ul_add_item = ""
                ul_add_ids = ""
            else
                ul_status = err or "Could not add cursor item."
            end
        end
    end

    ImGui.SetNextItemWidth(260.0)
    ul_add_item = input_text_hint("##ul_editor_add_item", "Item name or ID", ul_add_item)
    ImGui.SameLine()
    draw_slot_picker()
    if ul_add_kind == "aug" then
        ImGui.SameLine()
        ImGui.SetNextItemWidth(70.0)
        ul_add_socket = input_text_hint("##ul_editor_add_socket", "Socket", ul_add_socket ~= "" and ul_add_socket or "1")
    end
    ImGui.SameLine()
    if themed_button("Add One##ul_editor_add_one", Theme.blue) then
        local ids = parse_id_list(ul_add_ids, ul_add_item)
        local item = trim(ul_add_item)
        if item ~= "" and tonumber(item) then item = "" end
        local list, err = bis.add_entry(ul_edit_list_id, {
            item = item,
            ids = ids,
            slot = ul_add_slot,
            group = ul_add_kind == "aug" and "Aug" or "Worn",
            socket = ul_add_kind == "aug" and tonumber(ul_add_socket or "1") or nil,
        })
        if list then
            ul_status = string.format("Added entry to '%s' (%d total).", list.name, #(list.entries or {}))
            ul_add_item = ""
            ul_add_ids = ""
            ul_add_slot = ""
            ul_add_slot_pick = ""
            ul_add_group = ul_add_kind == "aug" and "Aug" or "Worn"
            ul_add_socket = ul_add_kind == "aug" and "1" or ""
        else
            ul_status = err or "Could not add entry."
        end
    end
    ImGui.SetNextItemWidth(260.0)
    ul_add_ids = input_text_hint("##ul_editor_add_ids", "IDs optional, comma-separated", ul_add_ids)
end

local function draw_entries_table(edit_list)
    local entries = edit_list.entries or {}
    section_header("Entries", Theme.section or Theme.header)
    ImGui.SetNextItemWidth(260.0)
    ul_entry_filter = input_text_hint("##ul_editor_entry_filter", "Search entries", ul_entry_filter)
    ImGui.SameLine()
    if toggle_button(ul_show_slot_layout and "Slot layout: ON##ul_editor_slot_layout" or "Slot layout: OFF##ul_editor_slot_layout", ul_show_slot_layout) then
        ul_show_slot_layout = not ul_show_slot_layout
    end
    if ul_show_slot_layout then
        draw_list_slot_layout(edit_list)
        ImGui.Spacing()
    end

    local needle = trim(ul_entry_filter):lower()
    if views.begin_scroll_table("UserListEditorDedicated", 5, views.scroll_table_flags(), 12.0, 260.0) then
        ImGui.TableSetupColumn("#", ImGuiTableColumnFlags.WidthFixed, 36.0)
        ImGui.TableSetupColumn("Item", ImGuiTableColumnFlags.WidthStretch, 2.0)
        ImGui.TableSetupColumn("Slot / Group", ImGuiTableColumnFlags.WidthStretch, 1.0)
        ImGui.TableSetupColumn("Socket", ImGuiTableColumnFlags.WidthFixed, 150.0)
        ImGui.TableSetupColumn("Action", ImGuiTableColumnFlags.WidthFixed, 80.0)
        pcall(function() ImGui.TableSetupScrollFreeze(0, 1) end)
        views.table_headers_centered({ "#", "Item", "Slot / Group", "Socket", "Action" })
        for i, entry in ipairs(entries) do
            local hay = table.concat({
                entry.item or "",
                entry.slot or "",
                entry.group or "",
                type(entry.ids) == "table" and table.concat(entry.ids, ",") or "",
            }, " "):lower()
            if needle == "" or hay:find(needle, 1, true) then
                ImGui.TableNextRow()
                ImGui.TableSetColumnIndex(0)
                col_text(Theme.dim, tostring(i))
                ImGui.TableSetColumnIndex(1)
                col_text(Theme.item, entry.item or "?")
                ImGui.TableSetColumnIndex(2)
                local meta = {}
                if entry.slot and entry.slot ~= "" then meta[#meta + 1] = entry.slot end
                if entry.group and entry.group ~= "" then meta[#meta + 1] = entry.group end
                if type(entry.ids) == "table" and #entry.ids > 0 then
                    meta[#meta + 1] = "ids:" .. table.concat(entry.ids, ",")
                end
                col_text(Theme.dim, #meta > 0 and table.concat(meta, " | ") or "-")
                ImGui.TableSetColumnIndex(3)
                if entry_is_aug(entry) then
                    local cur = tonumber(entry.socket) or 0
                    for socket = 1, 6 do
                        if socket > 1 then ImGui.SameLine() end
                        local label = "S" .. tostring(socket)
                        if themed_button(label .. "##ul_editor_sock_" .. tostring(i) .. "_" .. tostring(socket), cur == socket, 0, 18.0) then
                            local list, err = bis.update_entry_at(ul_edit_list_id, i, { socket = socket })
                            ul_status = list and string.format("Set %s to socket %d.", entry.item or "aug", socket)
                                or (err or "Could not update socket.")
                        end
                    end
                else
                    ImGui.TextDisabled("-")
                end
                ImGui.TableSetColumnIndex(4)
                if themed_button("Remove##ul_editor_rm_" .. tostring(i), Theme.steel) then
                    local list, err = bis.remove_entry_at(ul_edit_list_id, i)
                    ul_status = list and string.format("Removed entry from '%s' (%d left).", list.name, #(list.entries or {}))
                        or (err or "Remove failed.")
                end
            end
        end
        ImGui.EndTable()
    end

    if #entries == 0 then
        col_text(Theme.dim, "This list has no entries yet.")
    end
end

local function draw_list_editor_page()
    local names = bis.list_names()
    local edit_list = current_editor_list(names)
    draw_editor_header(names, edit_list)
    edit_list = current_editor_list(bis.list_names())
    if not edit_list then
        if ul_status ~= "" then col_text(Theme.dim, ul_status) end
        return
    end
    draw_bulk_add(edit_list)
    draw_quick_add()
    draw_entries_table(edit_list)
    if ul_status ~= "" then
        ImGui.Spacing()
        col_text(Theme.dim, ul_status)
    end
end

-- User/shared BiS lists: save-worn, import, export, delete. The generated
-- LazBiS catalog is read-only and lives elsewhere; these lists are stored as
-- separate flat files in the Config dir, so catalog updates never touch them.
local function draw_edit_list_entries(names)
    if not collapsing_section("Edit List Entries", false) then return end
    col_text(Theme.dim, "Add items by name or item ID. IDs work even when you do not know the exact name.")
    if #names == 0 then
        col_text(Theme.dim, "Click Create Empty List above, then paste a list of names/IDs here.")
        if themed_button("Create Empty List##ul_edit_create_empty", Theme.blue) then
            local list, err = userlists.create_empty("")
            if list then
                ul_edit_list_id = list.id
                Settings.bisListMode = "user"
                Settings.bisSelectedList = list.id
                SaveSettings()
                ul_status = string.format("Created '%s' - paste items below.", list.name)
            else
                ul_status = err or "Could not create list."
            end
        end
        if ul_status ~= "" then col_text(Theme.dim, ul_status) end
        return
    end

    if Settings.bisSelectedList ~= "" and bis.get(Settings.bisSelectedList) then
        ul_edit_list_id = Settings.bisSelectedList
    elseif ul_edit_list_id == "" or not bis.get(ul_edit_list_id) then
        ul_edit_list_id = names[1].id
    end

    ImGui.Text("List:")
    ImGui.SameLine()
    ImGui.SetNextItemWidth(260.0)
    local edit_label = "Select list"
    for _, rec in ipairs(names) do
        if rec.id == ul_edit_list_id then edit_label = rec.name; break end
    end
    if ImGui.BeginCombo("##ul_edit_list", edit_label) then
        for _, rec in ipairs(names) do
            if ImGui.Selectable(rec.name .. "##ul_edit_" .. rec.id, ul_edit_list_id == rec.id) then
                ul_edit_list_id = rec.id
            end
        end
        ImGui.EndCombo()
    end

    local edit_list = bis.get(ul_edit_list_id)
    if not edit_list then return end

    col_text(Theme.dim, "Bulk add: paste item names or IDs (comma-separated).")
    ul_bulk_buf = input_text_hint("##ul_bulk_paste", "e.g. Robe of the Ishva, 12345, Shard of ...", ul_bulk_buf)
    if themed_button("Add Bulk##ul_bulk_add", Theme.blue) then
        local list, added, extra = userlists.add_entries_bulk(ul_edit_list_id, ul_bulk_buf)
        if list then
            local skip = (tonumber(extra) or 0) > 0 and string.format(" (%d skipped)", extra) or ""
            ul_status = string.format("Added %d item(s) to '%s'%s.", tonumber(added) or 0, list.name, skip)
            ul_bulk_buf = ""
        else
            ul_status = tostring(added or extra or "Bulk add failed.")
        end
    end
    ImGui.Spacing()

    col_text(Theme.dim, "Or add one at a time: pick up an item, Use Cursor Item, or type below.")
    if toggle_button(ul_add_kind == "gear" and "Add: Gear##ul_kind_gear" or "Add: Gear##ul_kind_gear", ul_add_kind == "gear") then
        ul_add_kind = "gear"
        ul_add_group = "Worn"
    end
    ImGui.SameLine()
    if toggle_button(ul_add_kind == "aug" and "Add: Aug##ul_kind_aug" or "Add: Aug##ul_kind_aug", ul_add_kind == "aug") then
        ul_add_kind = "aug"
        ul_add_group = "Aug"
    end
    if themed_button("Use Cursor Item##ul_cursor_item", Theme.sync) then
        local cur = mq.TLO.Cursor
        if cur and cur() then
            ul_add_item = cur.Name() or ""
            local id = tonumber(cur.ID()) or 0
            if id > 0 then ul_add_ids = tostring(math.floor(id)) end
            ul_status = "Captured cursor item: " .. tostring(ul_add_item)
        else
            ul_status = "No item on cursor - pick one up in-game first."
        end
    end
    ImGui.SameLine()
    if themed_button("Add Cursor Item##ul_cursor_add", Theme.blue) then
        local cur = mq.TLO.Cursor
        if not (cur and cur()) then
            ul_status = "No item on cursor - pick one up in-game first."
        else
            ul_add_item = cur.Name() or ""
            local ids = {}
            local id = tonumber(cur.ID()) or 0
            if id > 0 then ids[#ids + 1] = math.floor(id) end
            local list, err = bis.add_entry(ul_edit_list_id, {
                item = ul_add_item,
                ids = ids,
                slot = ul_add_slot,
                group = ul_add_kind == "aug" and "Aug" or "Worn",
                socket = ul_add_kind == "aug" and tonumber(ul_add_socket or "1") or nil,
            })
            if list then
                ul_status = string.format("Added '%s' from cursor to '%s' (%d total).", ul_add_item, list.name, #(list.entries or {}))
                ul_add_item = ""
                ul_add_ids = ""
            else
                ul_status = err or "Could not add cursor item."
            end
        end
    end

    ImGui.SetNextItemWidth(260.0)
    ul_add_item = input_text_hint("##ul_add_item", "Item name or ID", ul_add_item)
    ImGui.SameLine()
    draw_slot_picker()
    if ul_add_kind == "aug" then
        ImGui.SameLine()
        ImGui.SetNextItemWidth(70.0)
        ul_add_socket = input_text_hint("##ul_add_socket", "Socket", ul_add_socket ~= "" and ul_add_socket or "1")
    end
    ImGui.SetNextItemWidth(220.0)
    ul_add_ids = input_text_hint("##ul_add_ids", "IDs (optional, comma-separated)", ul_add_ids)
    ImGui.SameLine()
    if themed_button("Add Entry##ul_add_entry", Theme.blue) then
        local ids = parse_id_list(ul_add_ids, ul_add_item)
        local item = trim(ul_add_item)
        if item ~= "" and tonumber(item) then item = "" end
        local list, err = bis.add_entry(ul_edit_list_id, {
            item = item,
            ids = ids,
            slot = ul_add_slot,
            group = ul_add_kind == "aug" and "Aug" or "Worn",
            socket = ul_add_kind == "aug" and tonumber(ul_add_socket or "1") or nil,
        })
        if list then
            ul_status = string.format("Added entry to '%s' (%d total).", list.name, #(list.entries or {}))
            ul_add_item = ""
            ul_add_ids = ""
            ul_add_slot = ""
            ul_add_slot_pick = ""
            ul_add_group = ul_add_kind == "aug" and "Aug" or "Worn"
            ul_add_socket = ul_add_kind == "aug" and "1" or ""
        else
            ul_status = err or "Could not add entry."
        end
    end

    local entries = edit_list.entries or {}
    if toggle_button(ul_show_slot_layout and "Slot layout: ON" or "Slot layout: OFF", ul_show_slot_layout) then
        ul_show_slot_layout = not ul_show_slot_layout
    end
    if ul_show_slot_layout then
        ImGui.Spacing()
        draw_list_slot_layout(edit_list)
        ImGui.Spacing()
    end

    if views.begin_scroll_table("UserListEditor", 5, views.scroll_table_flags(), 12.0, 160.0) then
        ImGui.TableSetupColumn("#", ImGuiTableColumnFlags.WidthFixed, 28.0)
        ImGui.TableSetupColumn("Item", ImGuiTableColumnFlags.WidthStretch, 2.0)
        ImGui.TableSetupColumn("Slot / Group", ImGuiTableColumnFlags.WidthStretch, 1.0)
        ImGui.TableSetupColumn("Socket", ImGuiTableColumnFlags.WidthFixed, 150.0)
        ImGui.TableSetupColumn("Action", ImGuiTableColumnFlags.WidthFixed, 72.0)
        pcall(function() ImGui.TableSetupScrollFreeze(0, 1) end)
        views.table_headers_centered({ "#", "Item", "Slot / Group", "Socket", "Action" })
        for i, entry in ipairs(entries) do
            ImGui.TableNextRow()
            ImGui.TableSetColumnIndex(0)
            col_text(Theme.dim, tostring(i))
            ImGui.TableSetColumnIndex(1)
            col_text(Theme.item, entry.item or "?")
            ImGui.TableSetColumnIndex(2)
            local meta = {}
            if entry.slot and entry.slot ~= "" then meta[#meta + 1] = entry.slot end
            if entry.group and entry.group ~= "" then meta[#meta + 1] = entry.group end
            if type(entry.ids) == "table" and #entry.ids > 0 then
                meta[#meta + 1] = "ids:" .. table.concat(entry.ids, ",")
            end
            col_text(Theme.dim, #meta > 0 and table.concat(meta, " | ") or "-")
            ImGui.TableSetColumnIndex(3)
            if entry_is_aug(entry) then
                local cur = tonumber(entry.socket) or 0
                for socket = 1, 6 do
                    if socket > 1 then ImGui.SameLine() end
                    local label = "S" .. tostring(socket)
                    if themed_button(label .. "##ul_sock_" .. tostring(i) .. "_" .. tostring(socket), cur == socket, 0, 18.0) then
                        local list, err = bis.update_entry_at(ul_edit_list_id, i, { socket = socket })
                        ul_status = list and string.format("Set %s to socket %d.", entry.item or "aug", socket)
                            or (err or "Could not update socket.")
                    end
                end
            else
                ImGui.TextDisabled("-")
            end
            ImGui.TableSetColumnIndex(4)
            if themed_button("Remove##ul_rm_" .. tostring(i), Theme.steel) then
                local list, err = bis.remove_entry_at(ul_edit_list_id, i)
                ul_status = list and string.format("Removed entry from '%s' (%d left).", list.name, #(list.entries or {}))
                    or (err or "Remove failed.")
            end
        end
        ImGui.EndTable()
    end

    if #entries == 0 then
        col_text(Theme.dim, "This list has no entries yet - paste names/IDs above.")
    end

    if ul_status ~= "" then
        ImGui.Spacing()
        col_text(Theme.dim, ul_status)
    end
end

draw_user_lists = function()
    userlists_ui.draw_full_section(draw_edit_list_entries)
    local msg = userlists_ui.get_status()
    if msg and msg ~= "" then ul_status = msg end
end

function M.draw_user_lists_editor()
    draw_list_editor_page()
end

function M.draw()
    if collapsing_section("Sync / Online Peers", true) then
    local on, st, off = Store.counts()
    local invalid = Store.invalid_peer_keys and Store.invalid_peer_keys() or {}
    col_text(Theme.dim, string.format("This box: %s   |   role: %s   |   peers known: %d online, %d stale, %d offline",
        my_key(), tostring(runtime_state.local_guard_role or "?"), on, st, off))
    col_text(Engine.ok and Theme.online or Theme.amber,
        string.format("%s   |   local scripts: %s",
            Engine.ok and "Actor engine: connected" or "Actor engine: NOT registered (cache-only)",
            tostring(runtime_state.local_guard_summary or "main=? bg=?")))
    if tostring(runtime_state.local_guard_last_action or "") ~= "" then
        col_text(Theme.amber, "local guard: " .. tostring(runtime_state.local_guard_last_action))
    end
    local s = Engine.stats
    col_text(Theme.dim, string.format("traffic  tx: req %d / snap %d    rx: req %d / snap %d / bad %d", s.tx_req, s.tx_snap, s.rx_req, s.rx_snap, s.rx_bad))
    local local_bank_text, local_bank_color = bank_label(Store.get(my_key()))
    col_text(local_bank_color, local_bank_text)
    if Settings.peerDiscoveryEnabled ~= false then
        col_text(Theme.dim, "discovery: " .. tostring(peer_discovery.status()))
    end
    local pk = Store.peer_keys()
    if #pk == 0 then col_text(Theme.amber, "No peers replied yet. Use Launch Group Peers, Launch All Online, or expand Broadcast / Launch below.")
    else
        for _, k in ipairs(pk) do
            local p = Store.get(k)
            if p then
                local count = #(p.equipped or {}) + #(p.bags or {}) + #(p.bank or {})
                local detail = count > 0 and string.format("%d items", count) or "waiting for snapshot"
                local inv_age = age_label(p.inventoryUpdated or p.updated)
                local bank_age = p.bankValid == true and age_label(p.bankCapturedAt or p.inventoryUpdated or p.updated) or "not synced"
                local state = views.source_state and views.source_state(k) or nil
                local tag = (state and state.tag) or status_tag(p.status)
                local responder = (state and state.responder) or ("peer " .. age_label(p.last_seen))
                local line_color = (state and state.actorLive) and Theme.online or status_color(p.status)
                col_text(line_color, string.format("  %s  [%s]  (%s, %s, inv %s, bank %s)",
                    p.name, tag, detail, responder, inv_age, bank_age))
                ImGui.SameLine()
                if themed_button("Mute##ign_" .. k, Theme.steel) then Store.set_ignored(p.name, true) end
                if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
                    ImGui.SetTooltip("Hide this character and stop scanning/announcing it (fleet-wide). Reversible in Ignored characters below.")
                end
                ImGui.SameLine()
                if themed_button("Forget##frg_" .. k, Theme.brick or Theme.amber) then Store.forget_char(k) end
                if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
                    ImGui.SetTooltip("Mute AND purge this character's cached inventory to reclaim memory.")
                end
            end
        end
    end
    if #invalid > 0 then
        col_text(Theme.amber, string.format("%d invalid cached source(s) hidden from menus.", #invalid))
    end
    local ignored = Store.ignored_names and Store.ignored_names() or {}
    if #ignored > 0 then
        ImGui.Spacing()
        col_text(Theme.section or Theme.header, string.format("Ignored characters (%d) - hidden & not scanned", #ignored))
        for _, e in ipairs(ignored) do
            col_text(Theme.dim, "  " .. e.label)
            ImGui.SameLine()
            if themed_button("Unmute##unign_" .. e.norm, Theme.online or Theme.steel) then
                Store.set_ignored(e.label, false)
            end
        end
        col_text(Theme.dim, "Ignored list is shared across all TurboGear characters on this install.")
    end
    ImGui.Spacing()
    if theme.sync_button("Sync Now") then
        if runtime_state.engine_claim_disabled then
            local bg_name = tostring((cfg.CFG and cfg.CFG.bg_lua_name) or 'turbogear_bg')
            mq.cmd('/squelch /lua run ' .. bg_name)
            mq.cmd('/timed 5 /squelch /tgearbg sync')
            ul_status = "Sync requested through the local TurboGear bg responder."
        else
            require('snapshot').invalidate()
            lockouts.invalidate_cache()
            Engine.publish(true, "full")
            Engine.request_all(true)
        end
    end
    ImGui.SameLine()
    if themed_button("Sync Banks", Theme.purple) then
        if runtime_state.engine_claim_disabled then
            local bg_name = tostring((cfg.CFG and cfg.CFG.bg_lua_name) or 'turbogear_bg')
            mq.cmd('/squelch /lua run ' .. bg_name)
            mq.cmd('/timed 5 /squelch /tgearbg sync')
            ul_status = "Bank sync requested through the local TurboGear bg responder."
        else
            Engine.sync_banks_network()
        end
    end
    if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
        ImGui.SetTooltip("Open the bank on the owner first. Captures local bank and requests full peer snapshots.")
    end
    ImGui.SameLine()
    if themed_button("Launch Group Peers", Theme.purple) then cfg.launch_peers() end
    if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
        ImGui.SetTooltip("Starts TurboGear bg on grouped peers using the selected transport's group template. Excludes this box when the transport supports group targeting.")
    end
    ImGui.SameLine()
    if themed_button("Launch All Online", Theme.blue) then
        local ok, reason = cfg.launch_all_online_peers()
        ul_status = ok
            and ("Sent all-online TurboGear autostart via " .. tostring((cfg.transport_profile() or {}).label or "transport") .. ".")
            or tostring(cfg.last_all_online_launch_status and cfg.last_all_online_launch_status() or reason or "All-online autostart skipped.")
    end
    if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
        ImGui.SetTooltip("Starts TurboGear bg on online clients using the selected transport's All template. Use this before BiS Scope = Online when boxes are outside group.")
    end
    if themed_button("Stop Peers", Theme.steel) then cfg.stop_peers() end
    if #invalid > 0 then
        ImGui.SameLine()
        if themed_button("Clean Invalid Cache", Theme.amber) then
            local removed = Store.prune_invalid_sources and Store.prune_invalid_sources() or 0
            ul_status = string.format("Removed %d invalid cached source(s).", removed)
            Store.save()
        end
    end
    end

    if collapsing_section("Broadcast / Launch", false) then
        ImGui.TextWrapped("How other boxes are told to run in the background. Pick the broadcast system your MQ setup uses; EQBC usually needs /bccmd connect first.")
        local active = cfg.transport_profile()
        ImGui.Text("Transport:"); ImGui.SameLine(); ImGui.SetNextItemWidth(190.0)
        if ImGui.BeginCombo("##tg_transport_profile", active and active.label or "E3") then
            for _, p in ipairs(cfg.TRANSPORT_PROFILES) do
                if ImGui.Selectable(p.label, Settings.transportProfile == p.key) then
                    Settings.transportProfile = p.key
                    SaveSettings()
                end
            end
            ImGui.EndCombo()
        end
        if Settings.transportProfile == "custom" then
            ImGui.Text("All:"); ImGui.SameLine(); ImGui.SetNextItemWidth(330.0)
            local all = ImGui.InputText("##tg_transport_all", Settings.transportCustomAll or "") or ""
            if all ~= Settings.transportCustomAll then Settings.transportCustomAll = all; SaveSettings() end
            ImGui.Text("Group:"); ImGui.SameLine(); ImGui.SetNextItemWidth(330.0)
            local group = ImGui.InputText("##tg_transport_group", Settings.transportCustomGroup or "") or ""
            if group ~= Settings.transportCustomGroup then Settings.transportCustomGroup = group; SaveSettings() end
            ImGui.Text("Target:"); ImGui.SameLine(); ImGui.SetNextItemWidth(330.0)
            local target = ImGui.InputText("##tg_transport_target", Settings.transportCustomTarget or "") or ""
            if target ~= Settings.transportCustomTarget then Settings.transportCustomTarget = target; SaveSettings() end
            col_text(Theme.dim, "Use {cmd}; target commands may also use {name}. Leave a template blank to disable it.")
        end
        ImGui.Text("Test target:"); ImGui.SameLine(); ImGui.SetNextItemWidth(145.0)
        local test_target = ImGui.InputText("##tg_transport_test_target", Settings.transportTestTarget or "") or ""
        if test_target ~= Settings.transportTestTarget then Settings.transportTestTarget = test_target; SaveSettings() end
        local target_name = trim(Settings.transportTestTarget)
        col_text(Theme.dim, "Group peer fleet:  " .. cfg.launch_command())
        col_text(Theme.dim, "All-online autostart:  " .. cfg.all_online_soft_start_bg_command())
        col_text(Theme.dim, "Preview all:  " .. cfg.transport_preview("all", "echo TurboGear reachable", target_name))
        col_text(Theme.dim, "Preview group:  " .. cfg.transport_preview("group", "echo TurboGear reachable", target_name))
        col_text(Theme.dim, "Preview target:  " .. cfg.transport_preview("target", "echo TurboGear reachable", target_name ~= "" and target_name or "<name>"))
        if not cfg.can_safely_launch_peers() then
            col_text(Theme.amber, "Group launch needs a supported group template and an active group; use Launch All Online for out-of-group clients.")
        end
        if themed_button("Test All", Theme.blue) then
            local cmd = cfg.transport_command("all", "echo TurboGear reachable", target_name)
            if cmd ~= "" then mq.cmd(cmd) end
        end
        ImGui.SameLine()
        if themed_button("Test Group", Theme.blue) then
            local cmd = cfg.transport_command("group", "echo TurboGear reachable", target_name)
            if cmd ~= "" then mq.cmd(cmd) end
        end
        ImGui.SameLine()
        if themed_button("Test Target", Theme.blue) then
            local cmd = cfg.transport_command("target", "echo TurboGear reachable", target_name)
            if cmd ~= "" then mq.cmd(cmd) else ul_status = "Enter a target name and choose a target-capable transport." end
        end
        ImGui.SameLine()
        if toggle_button(Settings.autoLaunch and "Auto-launch peers: ON" or "Auto-launch peers: OFF", Settings.autoLaunch) then
            Settings.autoLaunch = not Settings.autoLaunch; SaveSettings()
        end
        if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
            ImGui.SetTooltip("When TurboGear UI starts, ask grouped peers to run the bg responder once. New group members get a private /e3bct autostart. Sync Now does not rebroadcast launches.")
        end
        ImGui.SameLine()
        if toggle_button(Settings.autoAddOnlinePeers ~= false and "Auto-add online peers: ON" or "Auto-add online peers: OFF", Settings.autoAddOnlinePeers ~= false) then
            Settings.autoAddOnlinePeers = not (Settings.autoAddOnlinePeers ~= false); SaveSettings()
        end
        if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
            ImGui.SetTooltip("When ON, peer discovery can soft-start newly seen online clients via /e3bct. All-online broadcast is Launch All Online only (not Sync Now / UI startup).")
        end
        ImGui.SameLine()
        if toggle_button(Settings.peerDiscoveryEnabled ~= false and "Detect logins: ON" or "Detect logins: OFF", Settings.peerDiscoveryEnabled ~= false) then
            Settings.peerDiscoveryEnabled = not (Settings.peerDiscoveryEnabled ~= false); SaveSettings()
        end
        if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
            ImGui.SetTooltip("UI-only lightweight watcher. Polls connected client names every few seconds and soft-starts newly logged-in peers using the selected transport.")
        end
        ImGui.SameLine()
        if toggle_button(Settings.autoStopPeers ~= false and "Auto-stop peers: ON" or "Auto-stop peers: OFF", Settings.autoStopPeers ~= false) then
            Settings.autoStopPeers = not (Settings.autoStopPeers ~= false); SaveSettings()
        end
        if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
            ImGui.SetTooltip("When this UI box unloads TurboGear (/lua stop or /tgear stop), broadcast /lua stop turbogear_bg to peers and clean up legacy turbogear bg responders.")
        end
        ImGui.SameLine()
        do
            -- Storage backend selector (Phase 6): cycles auto -> file -> sqlite.
            -- The backend is chosen at load, so a change applies on restart.
            local sb = tostring(Settings.storeBackend or "auto")
            if themed_button("Storage: " .. sb, Theme.blue) then
                Settings.storeBackend = (sb == "auto" and "file") or (sb == "file" and "sqlite") or "auto"
                SaveSettings()
            end
            if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
                ImGui.SetTooltip("Persistence backend. auto = SQLite when lsqlite3 is available (auto-installed on first use), else the file cache. Restart TurboGear (/lua run turbogear) to apply a change.")
            end
        end
        ImGui.SameLine()
        if toggle_button(Settings.startMinimized and "Start minimized: ON" or "Start minimized: OFF", Settings.startMinimized) then
            Settings.startMinimized = not Settings.startMinimized; SaveSettings()
        end
        if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
            ImGui.SetTooltip("ON starts the UI as the small TG icon. /lua run turbogear mini does the same for one launch.")
        end
        ImGui.SameLine()
        if toggle_button(Settings.autoPeerRefresh and "Auto peer refresh: ON" or "Auto peer refresh: OFF", Settings.autoPeerRefresh) then
            Settings.autoPeerRefresh = not Settings.autoPeerRefresh; SaveSettings()
        end
        if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
            ImGui.SetTooltip("OFF is cache-first: peers refresh on startup and Sync Now. ON requests peer snapshots on cooldown while the UI is open.")
        end
        ImGui.SameLine()
        if toggle_button(Settings.autoCaptureBankOnOpen ~= false and "Auto bank sync: ON" or "Auto bank sync: OFF", Settings.autoCaptureBankOnOpen ~= false) then
            Settings.autoCaptureBankOnOpen = not (Settings.autoCaptureBankOnOpen ~= false); SaveSettings()
        end
        if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
            ImGui.SetTooltip("When this character opens a bank, TurboGear captures bank contents once and preserves them for BiS/search while the bank is closed.")
        end
        ImGui.SameLine()
        if toggle_button(Engine.debug and "Debug Metrics: ON" or "Debug Metrics: OFF", Engine.debug) then
            Engine.debug = not Engine.debug
            diag.set_enabled(Engine.debug)
        end
        ImGui.SameLine()
        ImGui.SetNextItemWidth(100.0)
        if ImGui.BeginCombo("##perf_mode", Settings.performanceMode == "lean" and "Lean" or (Settings.performanceMode == "full" and "Full" or "Auto")) then
            local opts = {
                { key = "auto", label = "Auto" },
                { key = "lean", label = "Lean" },
                { key = "full", label = "Full" },
            }
            for _, opt in ipairs(opts) do
                if ImGui.Selectable(opt.label .. "##perf_" .. opt.key, Settings.performanceMode == opt.key) then
                    Settings.performanceMode = opt.key
                    SaveSettings()
                end
            end
            ImGui.EndCombo()
        end
        if themed_button("Clean Restart Peers", Theme.amber) then
            cfg.stop_peers()
            mq.cmd("/timed " .. tostring(math.max(5, math.floor(tonumber(Settings.peerLaunchDelayDs) or 20))) .. " " .. cfg.start_bg_command())
        end
        ImGui.SameLine()
        if themed_button("Print Login Auto-Start", Theme.blue) then
            print("[TurboGear] For plug-and-play, add this to each box's ingame.cfg (Config folder):")
            print("/squelch /timed " .. math.random(10, 60) .. " /lua run " .. tostring(CFG.bg_lua_name or "turbogear_bg"))
            print("[TurboGear] (random delay staggers logins; every box self-starts the responder)")
        end
    end

    if collapsing_section("TurboBiS", false) then
        draw_turbobis_settings()
    end

    if collapsing_section("Focus Display", false) then
        draw_focus_display_settings()
    end

    if collapsing_section("Display / Paths", false) then
        if toggle_button(Settings.hideOrnament and "Empty Slots: skipping ornament/special (Type 20/30)" or "Empty Slots: showing every socket", not Settings.hideOrnament) then
            Settings.hideOrnament = not Settings.hideOrnament; SaveSettings(); empty_tab.invalidate()
        end
        if toggle_button(Settings.miniIconSmall and "Mini icon: small (28px)" or "Mini icon: standard (48px)", not Settings.miniIconSmall) then
            Settings.miniIconSmall = not Settings.miniIconSmall; SaveSettings()
        end
        if ImGui.IsItemHovered() and ImGui.SetTooltip then
            ImGui.SetTooltip("Size of the minimized TG icon. Also available by right-clicking the icon.")
        end
        if toggle_button(Settings.miniHideWhenTurboMini and "Mini icon: hidden while Turbo hub runs" or "Mini icon: always shown when minimized", not Settings.miniHideWhenTurboMini) then
            Settings.miniHideWhenTurboMini = not Settings.miniHideWhenTurboMini; SaveSettings()
        end
        if ImGui.IsItemHovered() and ImGui.SetTooltip then
            ImGui.SetTooltip("Opt-in: while the Turbo hub is running, its mini bar carries a TG chip,\nso the standalone TG icon stays hidden. It returns automatically if Turbo stops.")
        end
        ImGui.Spacing()
        col_text(Theme.dim, "Settings: " .. cfg.SettingsFile)
        col_text(Theme.dim, "Shared: " .. cfg.SharedSettingsFile)
        col_text(Theme.dim, "Cache: " .. cfg.CacheFile)
    end
end

return M
