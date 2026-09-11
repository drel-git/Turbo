-- TurboGear/ui.lua
-- The UI shell: window frame, header (Minimize), tab bar, and the crash-safe
-- render wrapper. Draw reads cached Store/snapshot data. Engine/main-loop owns
-- Store refresh; this file does not poll cache because ImGui presented a frame.

local ImGui = require('ImGui')
local mq    = require('mq')
local cfg = require('config')
local CFG, Settings, SaveSettings = cfg.CFG, cfg.Settings, cfg.SaveSettings
local theme = require('theme')
local Theme, col_text, nav_button = theme.Theme, theme.col_text, theme.nav_button
local push_theme, pop_theme = theme.push_theme, theme.pop_theme
local state  = require('state')
local Engine = require('engine').Engine
local Store = require('store').Store
local diag = require('diagnostics')

local inventory = require('tabs.inventory')
local worn    = require('tabs.worn')
local empty   = require('tabs.empty')
local augbag  = require('tabs.augbag')
local compare = require('tabs.compare')
local stats   = require('tabs.stats')
local live_stats = require('tabs.live_stats')
local focus   = require('tabs.focus')
local suggest = require('tabs.suggestions')
local bis     = require('tabs.bis')
local type12_tab = require('tabs.type12')
local don_tab = require('tabs.don')
local lockouts_tab = require('tabs.lockouts')
local spells_tab   = require('tabs.spells')
local setup   = require('tabs.setup')
local global_search = require('global_search')
local index_warm_policy = require('index_warm_policy')
local snapshot = require('snapshot')
local item_actions = require('item_actions')
local inspect_dock = require('inspect_dock')
local views = require('views')
local location_color = theme.location_color
local characters = require('characters')

local M = {}
M._last_main_rect = nil
M._last_main_h = 500
M._last_main_w = 900

local last_main_tab = nil
local last_view_key = nil
local last_enter_view_key = nil

local function request_item_index(reason)
    pcall(function()
        index_warm_policy.request_item_index(reason, 3.0)
    end)
end

local iconImg = nil
local iconLoadAttempted = false
local MINI_CLICK_SLOP = 6.0
local MAIN_WINDOW_FLAGS = (ImGuiWindowFlags.NoTitleBar or 0) + (ImGuiWindowFlags.NoCollapse or 0)

local function vec2_xy(v, vy)
    if type(v) == "table" then
        return tonumber(v.x or v.X or v[1]) or 0, tonumber(v.y or v.Y or v[2]) or 0
    end
    return tonumber(v) or 0, tonumber(vy) or 0
end

local CHROME_SIDE_BTN_W = 28.0
local CHROME_ROW_H = 26.0
local CHROME_GAP = 4.0
local CHROME_TAIL_H = 14.0
local HEADER_BAND_H = 46.0

local function pointer_held()
    return ImGui.IsMouseDown and ImGui.IsMouseDown(0) == true
end

local function mark_ui_settings(reason)
    if cfg.MarkSettingsDirty then
        cfg.MarkSettingsDirty(reason or "ui")
    elseif SaveSettings then
        SaveSettings()
    end
end

local function geom_changed(prev, x, y, w, h)
    if not prev then return true end
    if x and math.abs((tonumber(prev.x) or 0) - x) >= 0.5 then return true end
    if y and math.abs((tonumber(prev.y) or 0) - y) >= 0.5 then return true end
    if w and math.abs((tonumber(prev.w) or 0) - w) >= 0.5 then return true end
    if h and math.abs((tonumber(prev.h) or 0) - h) >= 0.5 then return true end
    return false
end

-- Observe live ImGui geometry. Never pickle while the pointer is held.
local function persist_window_geom(pos_key, size_key)
    if not ImGui.GetWindowPos then return end
    local wx, wy = vec2_xy(ImGui.GetWindowPos())
    local ww, wh = 0, 0
    if ImGui.GetWindowSize then ww, wh = vec2_xy(ImGui.GetWindowSize()) end
    if pointer_held() then return end
    local dirty = false
    if pos_key and geom_changed(Settings[pos_key], wx, wy) then
        Settings[pos_key] = { x = wx, y = wy }
        dirty = true
    end
    if size_key and ww > 0 and wh > 0 and geom_changed(Settings[size_key], nil, nil, ww, wh) then
        Settings[size_key] = { w = ww, h = wh }
        dirty = true
    end
    if dirty then mark_ui_settings("window_geom") end
end

local function content_avail_x()
    local avail = ImGui.GetContentRegionAvail and ImGui.GetContentRegionAvail() or 0
    if type(avail) == "table" then return tonumber(avail.x or avail[1]) or 0 end
    return tonumber(avail) or 0
end

local function content_region_width()
    if ImGui.GetWindowContentRegionMin and ImGui.GetWindowContentRegionMax then
        local cmin = ImGui.GetWindowContentRegionMin()
        local cmax = ImGui.GetWindowContentRegionMax()
        local min_x = type(cmin) == "table" and (cmin.x or cmin[1]) or tonumber(cmin) or 0
        local max_x = type(cmax) == "table" and (cmax.x or cmax[1]) or tonumber(cmax) or min_x
        min_x, max_x = tonumber(min_x) or 0, tonumber(max_x) or 0
        if max_x > min_x then return max_x - min_x end
    end
    return content_avail_x()
end

local function window_screen_rect()
    if not ImGui.GetWindowPos then return nil end
    local wx, wy = vec2_xy(ImGui.GetWindowPos())
    local w, h = 0, 0
    if ImGui.GetWindowSize then
        w, h = vec2_xy(ImGui.GetWindowSize())
    end
    if w <= 0 then
        w = M._last_main_w or content_region_width() + 16
    else
        M._last_main_w = w
    end
    if h > 0 then
        M._last_main_h = h
    else
        h = M._last_main_h or HEADER_BAND_H
    end
    return { x1 = wx, y1 = wy, x2 = wx + w, y2 = wy + h }
end

local function screen_rect_at_cursor(w, h)
    w, h = tonumber(w) or 0, tonumber(h) or 0
    if w <= 0 or h <= 0 then return nil end
    local x, y = 0, 0
    if ImGui.GetCursorScreenPos then
        x, y = vec2_xy(ImGui.GetCursorScreenPos())
    else
        local win = window_screen_rect()
        local cx, cy = 0, 0
        if ImGui.GetCursorPos then cx, cy = vec2_xy(ImGui.GetCursorPos()) end
        if win then
            x, y = win.x1 + cx, win.y1 + cy
        end
    end
    return { x1 = x, y1 = y, x2 = x + w, y2 = y + h }
end

local function hide_main_window()
    state.show = false
    M._last_main_rect = nil
end

local function persistMiniPos()
    persist_window_geom("miniWindowPos", nil)
end

local function sync_full()
    snapshot.invalidate()
    -- Match Suggestions Request: keep polling shared cache for late peer snaps.
    if suggest.begin_cache_watch then
        suggest.begin_cache_watch(suggest.CACHE_WATCH_S or 45)
    end
    state.sync_hint = "Sync requested - waiting for peer inventories (often 15-45s)..."
    state.sync_hint_until = os.clock() + (tonumber(suggest.CACHE_WATCH_S) or 45)

    -- Wake the Suggestions target's bg when that peer looks stale / not live.
    -- Full-group soft-start stays Launch All Online (launch-storm footgun).
    if Settings.autoAddOnlinePeers ~= false then
        local tkey = Settings.suggestTargetKey or views.view_key or "__self__"
        if tkey ~= "__self__" then
            local snap = views.source_snapshot and views.source_snapshot(tkey)
            local name = tostring(snap and snap.name or ""):match("^%s*(.-)%s*$") or ""
            local state_info = views.source_state and views.source_state(tkey) or nil
            local actor_live = state_info and state_info.actorLive == true
            local age = 999999
            if snap then
                local ts = tonumber(snap.inventoryUpdated or snap.updated) or 0
                if ts > 0 then age = math.max(0, os.time() - ts) end
            end
            if name ~= "" and (not actor_live or age > 120) then
                local cmd = cfg.soft_start_bg_command_for and cfg.soft_start_bg_command_for(name) or ""
                if cmd ~= "" then mq.cmd(cmd) end
            end
        end
    end

    if state.engine_claim_disabled then
        -- Ensure local bg only; do not /e3bcg soft-start the whole group.
        local bg_name = tostring((cfg.CFG and cfg.CFG.bg_lua_name) or 'turbogear_bg')
        mq.cmd('/squelch /lua run ' .. bg_name)
        mq.cmd('/squelch /tgearbg sync')
        pcall(function()
            if Store.reload_cache_if_changed then Store.reload_cache_if_changed(true)
            else Store.reload_cache() end
        end)
        return
    end
    Engine.publish(true, "full")
    Engine.request_all(true, { depth = "full", fastInventory = true })
    Engine.begin_startup_sync(8.0)
end

local function input_text_hint(id, hint, value)
    if ImGui.InputTextWithHint then
        local ok, rv = pcall(ImGui.InputTextWithHint, id, hint, value or "")
        if ok and rv ~= nil then return rv end
    end
    return ImGui.InputText(id, value or "") or ""
end

local function header_status_text()
    -- Sync hints take priority; otherwise fall back to transient action feedback
    -- (item_actions.status() self-clears via its TTL). Both share this band, whose
    -- height is reserved every frame, so nothing here shifts the window layout.
    if state.sync_hint and os.clock() < (tonumber(state.sync_hint_until) or 0) then
        return tostring(state.sync_hint), Theme.amber
    end
    local action_status = item_actions.status()
    if action_status and action_status ~= "" then
        return action_status, Theme.dim
    end
    return nil
end

local function draw_sync_status()
    local text, color = header_status_text()
    if text then col_text(color or Theme.amber, text) end
end

local function draw_global_search_bar()
    local clear_w = 64.0
    local sync_w = 88.0
    if ImGui.BeginTable then
        local flags = (ImGuiTableFlags.NoSavedSettings or 0) + (ImGuiTableFlags.NoPadOuterX or 0)
        if ImGui.BeginTable("##tg_global_search_bar", 3, flags) then
            ImGui.TableSetupColumn("Search", ImGuiTableColumnFlags.WidthStretch, 1.0)
            ImGui.TableSetupColumn("Clear", ImGuiTableColumnFlags.WidthFixed, clear_w + 8.0)
            ImGui.TableSetupColumn("Sync", ImGuiTableColumnFlags.WidthFixed, sync_w + 8.0)
            ImGui.TableNextRow()

            ImGui.TableSetColumnIndex(0)
            ImGui.SetNextItemWidth(-1)
            local next_val = input_text_hint("##tg_global_search", "Search everywhere...", Settings.globalSearch or "")
            local search_hot = tostring(next_val or ""):gsub("^%s+", ""):gsub("%s+$", "") ~= ""
            if ImGui.IsItemActive and ImGui.IsItemActive() then search_hot = true end
            if ImGui.IsItemFocused and ImGui.IsItemFocused() then search_hot = true end
            if search_hot then request_item_index("search") end
            if next_val ~= (Settings.globalSearch or "") then
                Settings.globalSearch = next_val
                global_search.invalidate()
                mark_ui_settings("global_search")
            end

            ImGui.TableSetColumnIndex(1)
            if theme.themed_button("Clear##tg_gs_clear", Theme.steel, clear_w, 0) then
                if tostring(Settings.globalSearch or "") ~= "" then
                    Settings.globalSearch = ""
                    global_search.invalidate()
                    mark_ui_settings("global_search")
                end
            end
            if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
                ImGui.SetTooltip("Clear the search box.")
            end

            ImGui.TableSetColumnIndex(2)
            if theme.sync_button("Sync Now##tg_global", sync_w, 0) then sync_full() end
            if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
                ImGui.SetTooltip("Refresh inventory cache and sync peers. Cached bank contents are preserved when the bank is closed.")
            end
            ImGui.EndTable()
        end
        return
    end

    ImGui.SetNextItemWidth(math.max(120.0, content_avail_x() - (clear_w + sync_w + 24.0)))
    local next_val = input_text_hint("##tg_global_search", "Search everywhere...", Settings.globalSearch or "")
    local search_hot = tostring(next_val or ""):gsub("^%s+", ""):gsub("%s+$", "") ~= ""
    if ImGui.IsItemActive and ImGui.IsItemActive() then search_hot = true end
    if ImGui.IsItemFocused and ImGui.IsItemFocused() then search_hot = true end
    if search_hot then request_item_index("search") end
    if next_val ~= (Settings.globalSearch or "") then
        Settings.globalSearch = next_val
        global_search.invalidate()
        mark_ui_settings("global_search")
    end
    ImGui.SameLine()
    if theme.themed_button("Clear##tg_gs_clear", Theme.steel, clear_w, 0) then
        if tostring(Settings.globalSearch or "") ~= "" then
            Settings.globalSearch = ""
            global_search.invalidate()
            mark_ui_settings("global_search")
        end
    end
    ImGui.SameLine()
    if theme.sync_button("Sync Now##tg_global", sync_w, 0) then sync_full() end
end

-- Sortable search results: click Owner/Item/Qty/Location headers to sort.
-- Uses ImGui table sort specs (same mechanism as LazBis); the sorted copy is
-- cached and only re-sorted when the specs or the result set change.
local SEARCH_COL_OWNER, SEARCH_COL_ITEM, SEARCH_COL_QTY, SEARCH_COL_LOCATION = 1, 2, 3, 4
local search_sort = { key = nil, rows = nil }
local current_search_sort_specs = nil

local function search_sort_value(row, column_id)
    if column_id == SEARCH_COL_OWNER then return tostring(row.owner or ""):lower() end
    if column_id == SEARCH_COL_QTY then return tonumber(row.qty) or 0 end
    if column_id == SEARCH_COL_LOCATION then return tostring(row.location or row.where or ""):lower() end
    return tostring(row.name or ""):lower()
end

local function compare_search_rows(a, b)
    local specs = current_search_sort_specs
    if specs then
        for n = 1, (specs.SpecsCount or 0) do
            local spec = specs:Specs(n)
            local va = search_sort_value(a, spec.ColumnUserID)
            local vb = search_sort_value(b, spec.ColumnUserID)
            if va ~= vb then
                local less = va < vb
                if spec.SortDirection == ImGuiSortDirection.Ascending then return less end
                return not less
            end
        end
    end
    return tostring(a.name or ""):lower() < tostring(b.name or ""):lower()
end

local function search_sort_supported()
    return ImGui.TableGetSortSpecs ~= nil
        and ImGuiTableFlags.Sortable ~= nil
        and ImGuiSortDirection ~= nil
end

-- Must be called inside the table, after column setup + headers.
local function sorted_search_rows(rows, needle)
    if not search_sort_supported() then return rows end
    local ok, specs = pcall(ImGui.TableGetSortSpecs)
    if not ok or not specs then return rows end
    local cache_key = tostring(needle) .. ":" .. tostring(#rows) .. ":" .. tostring(Store.content_version or 0)
    if specs.SpecsDirty or search_sort.key ~= cache_key then
        local copy = {}
        for i, row in ipairs(rows) do copy[i] = row end
        if (specs.SpecsCount or 0) > 0 then
            current_search_sort_specs = specs
            local sort_ok = pcall(table.sort, copy, compare_search_rows)
            current_search_sort_specs = nil
            if not sort_ok then copy = rows end
        end
        search_sort.key = cache_key
        search_sort.rows = copy
        pcall(function() specs.SpecsDirty = false end)
    end
    return search_sort.rows or rows
end

local function global_search_active()
    return tostring(Settings.globalSearch or ""):gsub("^%s+", ""):gsub("%s+$", "") ~= ""
end

local function draw_global_search_results()
    local needle = tostring(Settings.globalSearch or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if needle == "" then return end

    col_text(Theme.dim, "Showing search results - Clear to return to the current tab.")
    local rows = global_search.filter(needle, 60)
    col_text(Theme.dim, string.format("%d inventory match(es)", #rows))
    col_text(Theme.dim, "Searches worn gear, bags, bank, and installed augs. Tab = where a left-click opens.")
    local max_h = math.min(320.0, 28.0 + math.max(1, #rows) * 22.0)
    if #rows > 0 and views.begin_scroll_table then
        local sortable = search_sort_supported()
        local table_flags = views.scroll_table_flags(sortable and ImGuiTableFlags.Sortable or 0)
        if views.begin_scroll_table("TGGlobalSearch", 5, table_flags, 8.0, max_h, max_h) then
            local row_ok, row_err = pcall(function()
                ImGui.TableSetupColumn("Owner", ImGuiTableColumnFlags.WidthFixed, 108.0, SEARCH_COL_OWNER)
                ImGui.TableSetupColumn("Item", ImGuiTableColumnFlags.WidthStretch, 2.0, SEARCH_COL_ITEM)
                ImGui.TableSetupColumn("Qty", ImGuiTableColumnFlags.WidthFixed, 42.0, SEARCH_COL_QTY)
                ImGui.TableSetupColumn("Location", ImGuiTableColumnFlags.WidthStretch, 1.5, SEARCH_COL_LOCATION)
                ImGui.TableSetupColumn("Open", ImGuiTableColumnFlags.WidthFixed + (ImGuiTableColumnFlags.NoSort or 0), 88.0)
                if sortable and ImGui.TableHeadersRow then
                    -- Standard headers so clicks drive the sort arrows.
                    if ImGui.TableSetupScrollFreeze then pcall(ImGui.TableSetupScrollFreeze, 0, 1) end
                    ImGui.TableHeadersRow()
                    rows = sorted_search_rows(rows, needle)
                else
                    views.table_headers_centered({ "Owner", "Item", "Qty", "Location", "Open" })
                end
                for i, row in ipairs(rows) do
                    ImGui.TableNextRow()
                    ImGui.TableSetColumnIndex(0)
                    views.draw_owner_cell(row)
                    ImGui.TableSetColumnIndex(1)
                    local item_name = tostring(row.name or "?")
                    if ImGui.Selectable(item_name .. "##tg_gs_" .. tostring(i), false) then
                        global_search.apply_row(row)
                    end
                    item_actions.draw_context(item_name, row.id, "tg_gs_" .. tostring(i), item_actions.context_opts({
                        sourceLocation = tostring(row.location or row.where or ""),
                    }, row))
                    ImGui.TableSetColumnIndex(2)
                    local qty = tonumber(row.qty) or 0
                    if qty > 1 then ImGui.Text(tostring(qty)) else ImGui.TextDisabled("-") end
                    ImGui.TableSetColumnIndex(3)
                    col_text(location_color(row.locationGroup, row.location), tostring(row.location or row.where or ""))
                    ImGui.TableSetColumnIndex(4)
                    ImGui.TextDisabled(global_search.row_hint(row))
                end
            end)
            ImGui.EndTable()
            if not row_ok and not state.err_once then
                state.err_once = "Search table: " .. tostring(row_err)
            end
        end
    elseif #rows == 0 then
        col_text(Theme.placeholder or Theme.dim, "No inventory matches.")
    end

    local bis_rows = global_search.filter_bis(needle, 30)
    if #bis_rows > 0 and views.begin_scroll_table then
        ImGui.Spacing()
        col_text(Theme.section or Theme.cyan, string.format("BiS recommendations (%d)", #bis_rows))
        col_text(Theme.dim, "Left-click a row to open that list on TurboBiS.")
        local bis_h = math.min(280.0, 28.0 + (#bis_rows * 22.0))
        if views.begin_scroll_table("TGGlobalSearchBiS", 4, views.scroll_table_flags(), 8.0, bis_h, bis_h) then
            local row_ok, row_err = pcall(function()
                ImGui.TableSetupColumn("Item", ImGuiTableColumnFlags.WidthStretch, 2.0)
                ImGui.TableSetupColumn("List", ImGuiTableColumnFlags.WidthFixed, 88.0)
                ImGui.TableSetupColumn("Classes", ImGuiTableColumnFlags.WidthStretch, 1.2)
                ImGui.TableSetupColumn("Slot", ImGuiTableColumnFlags.WidthFixed, 96.0)
                views.table_headers_centered({ "Item", "List", "Classes", "Slot" })
                for i, row in ipairs(bis_rows) do
                    ImGui.TableNextRow()
                    ImGui.TableSetColumnIndex(0)
                    local item_name = tostring(row.name or "?")
                    if ImGui.Selectable(item_name .. "##tg_gs_bis_" .. tostring(i), false) then
                        global_search.apply_bis_row(row)
                    end
                    item_actions.draw_context(item_name, row.id, "tg_gs_bis_" .. tostring(i))
                    ImGui.TableSetColumnIndex(1)
                    ImGui.Text(tostring(row.list_label or row.list_id or "?"))
                    ImGui.TableSetColumnIndex(2)
                    ImGui.TextDisabled(tostring(row.classes or ""))
                    ImGui.TableSetColumnIndex(3)
                    ImGui.TextDisabled(tostring(row.slot or ""))
                end
            end)
            ImGui.EndTable()
            if not row_ok and not state.err_once then
                state.err_once = "BiS search table: " .. tostring(row_err)
            end
        end
    end
end

local function load_mini_icon()
    if iconLoadAttempted then return iconImg end
    iconLoadAttempted = true

    local icon_path = string.format("%s/%s/icon_turbogear.png", mq.luaDir, CFG.lua_name or "turbogear")
    local ok, tex = pcall(mq.CreateTexture, icon_path)
    if ok and tex then
        iconImg = tex
    else
        print(string.format("[TurboGear] mini icon not loaded from %s; using TG text fallback.", icon_path))
    end

    return iconImg
end

-- Throttled probe: is the Turbo hub script running? Used by the opt-in
-- "hide mini while Turbo runs" mode (the hub's mini bar carries a TG chip).
-- If Turbo stops, the probe flips false within ~5s and the mini auto-returns,
-- so the user is never left without a TurboGear entry point.
local turbo_hub_probe = { next_at = 0, running = false }
local function turbo_hub_running()
    local now = os.clock()
    if now >= (turbo_hub_probe.next_at or 0) then
        turbo_hub_probe.next_at = now + 5.0
        local guard = require('runtime_guard')
        turbo_hub_probe.running = guard.script_running(mq, 'Turbo')
            or guard.script_running(mq, 'turbo')
    end
    return turbo_hub_probe.running == true
end

-- Settings checkbox tolerant of both MQ ImGui.Checkbox return conventions
-- ((newValue, pressed) or just (newValue)); same pattern as bis.draw_quick_toggles.
local function mini_settings_checkbox(label, key)
    if not ImGui.Checkbox then return end
    local cur = Settings[key] and true or false
    local rv1, rv2 = ImGui.Checkbox(label, cur)
    local new_val, apply = nil, false
    if type(rv2) == "boolean" then
        new_val, apply = rv1, rv2
    elseif type(rv1) == "boolean" and rv1 ~= cur then
        new_val, apply = rv1, true
    end
    if apply then
        Settings[key] = new_val and true or false
        mark_ui_settings("mini_icon")
    end
end

local function draw_mini()
    return diag.time("ui.window.mini", function()
    -- Opt-in dock mode: while the Turbo hub is up, its mini bar owns the TG
    -- entry point; skip drawing our own icon. Auto-shows again if Turbo stops.
    if Settings.miniHideWhenTurboMini and turbo_hub_running() then return end

    local flags =
        (ImGuiWindowFlags.AlwaysAutoResize or 0) +
        (ImGuiWindowFlags.NoTitleBar or 0) +
        (ImGuiWindowFlags.NoResize or 0)

    -- LazBiS-style mini: icon is clickable, but a generous padded border stays
    -- draggable (ImageButton consumed almost the whole window before).
    local small = Settings.miniIconSmall == true
    local icon_draw_size = small and 28.0 or 48.0
    local border_pad = small and 4.0 or 8.0

    local pos = Settings.miniWindowPos
    if pos and pos.x and pos.y and ImGui.SetNextWindowPos then
        ImGui.SetNextWindowPos(pos.x, pos.y, ImGuiCond.Appearing)
    end

    ImGui.PushStyleVar(ImGuiStyleVar.WindowBorderSize, 2.5)
    ImGui.PushStyleVar(ImGuiStyleVar.WindowPadding, ImVec2(border_pad, border_pad))
    ImGui.PushStyleVar(ImGuiStyleVar.FramePadding, ImVec2(0, 0))
    ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, ImVec2(0, 0))

    ImGui.PushStyleColor(ImGuiCol.WindowBg, 0.060, 0.075, 0.115, 0.98)
    ImGui.PushStyleColor(ImGuiCol.Border, 1.00, 0.74, 0.28, 0.94)

    local open, vis = ImGui.Begin("TurboGear###TurboGearMini", true, flags)
    if open then
        if vis then
            local icon = load_mini_icon and load_mini_icon() or nil
            local icon_size = ImVec2(icon_draw_size, icon_draw_size)

            if icon and ImGui.Image then
                ImGui.Image(icon:GetTextureID(), icon_size)
                if ImGui.IsItemClicked and ImGui.IsItemClicked(0)
                    and (not ImGui.IsMouseDragging or not ImGui.IsMouseDragging(0, MINI_CLICK_SLOP)) then
                    state.show = not state.show
                end
                if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
                    ImGui.SetTooltip("TurboGear is running.\nClick icon to open/close full view.\nRight-click for icon options.\nDrag gold border to move.")
                end
            else
                if ImGui.Button("TG", icon_size) then
                    state.show = not state.show
                end
                if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
                    ImGui.SetTooltip("TurboGear is running.\nClick to open/close full view.\nRight-click for icon options.\nDrag gold border to move.")
                end
            end
            if ImGui.IsItemClicked and ImGui.IsItemClicked(1) and ImGui.OpenPopup then
                ImGui.OpenPopup("##tg_mini_ctx")
            end
            if ImGui.BeginPopup and ImGui.BeginPopup("##tg_mini_ctx") then
                mini_settings_checkbox("Small icon##tg_mini_small", "miniIconSmall")
                mini_settings_checkbox("Hide while Turbo hub runs##tg_mini_dock", "miniHideWhenTurboMini")
                if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
                    ImGui.SetTooltip("Use the TG chip on Turbo's mini bar instead.\nThis icon returns automatically if Turbo stops.")
                end
                ImGui.EndPopup()
            end

            persistMiniPos()
        end

        ImGui.End()
    end

    ImGui.PopStyleColor(2)
    ImGui.PopStyleVar(4)
    end)
end

local function text_width(text)
    text = tostring(text or "")
    if ImGui.CalcTextSize then
        local w = ImGui.CalcTextSize(text)
        if type(w) == "table" then return tonumber(w.x or w[1]) or 0 end
        return tonumber(w) or 0
    end
    return #text * 7
end

local function draw_window_chrome()
    return diag.time("ui.chrome", function()
    local version = tostring(CFG.version or "?")
    local title_a = "Turbo"
    local title_b = string.format("Gear v%s", version)
    local x0, y0 = 0, 0
    if ImGui.GetCursorPos then
        x0, y0 = ImGui.GetCursorPos()
        x0, y0 = tonumber(x0) or 0, tonumber(y0) or 0
    end
    local bar_w = content_region_width()
    local side = CHROME_SIDE_BTN_W
    local gap = CHROME_GAP
    local drag_w = math.max(80, bar_w - (side * 2) - (gap * 2))
    local title_sx, title_sy, title_ex, title_ey = x0 + side + gap, y0, x0 + side + gap + drag_w, y0 + CHROME_ROW_H

    if ImGui.SetCursorPos then ImGui.SetCursorPos(x0, y0) end
    if theme.themed_button("...##tg_menu", Theme.menu or Theme.steel, side, CHROME_ROW_H) then
        if ImGui.OpenPopup then ImGui.OpenPopup("##tg_title_menu") end
    end
    if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
        ImGui.SetTooltip("TurboGear menu.")
    end
    if ImGui.BeginPopup and ImGui.BeginPopup("##tg_title_menu") then
        if theme.themed_button("Unload TurboGear##tg_menu_unload", Theme.brick, 142, 22) then
            pcall(function() inspect_dock.cancel() end)
            state.pending_stop = true
            if ImGui.CloseCurrentPopup then ImGui.CloseCurrentPopup() end
        end
        if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
            ImGui.SetTooltip("Unload TurboGear on this character (/tgear stop).")
        end
        ImGui.EndPopup()
    end

    if ImGui.SetCursorPos then ImGui.SetCursorPos(x0 + side + gap, y0) end
    local title_rect = screen_rect_at_cursor(drag_w, CHROME_ROW_H)
    if title_rect then
        title_sx, title_sy, title_ex, title_ey = title_rect.x1, title_rect.y1, title_rect.x2, title_rect.y2
    end

    if ImGui.SetCursorPos then
        ImGui.SetCursorPos(x0 + math.max(0, bar_w - side), y0)
    end
    if theme.themed_button("-##tg_hide", Theme.gold, side, CHROME_ROW_H) then
        hide_main_window()
    end
    if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
        ImGui.SetTooltip("Minimize TurboGear to the TG icon.")
    end

    if ImGui.GetWindowDrawList and theme.color_u32 then
        local title_w = text_width(title_a) + text_width(title_b)
        local cx = title_sx + math.max(0, (title_ex - title_sx - title_w) * 0.5)
        local cy = title_sy + math.max(0, (title_ey - title_sy - 14) * 0.5)
        local draw = ImGui.GetWindowDrawList()
        draw:AddText(ImVec2(cx, cy), theme.color_u32(Theme.gold), title_a)
        draw:AddText(ImVec2(cx + text_width(title_a), cy), theme.color_u32(Theme.header), title_b)
    end

    if ImGui.SetCursorPos then
        ImGui.SetCursorPos(x0, y0 + CHROME_ROW_H + 1)
    elseif ImGui.Dummy then
        ImGui.Dummy(0, CHROME_ROW_H + 1)
    end
    ImGui.Separator()

    local has_sync = header_status_text() ~= nil
    local tail_x, tail_y = x0, y0 + CHROME_ROW_H + 1
    if ImGui.GetCursorPos then
        tail_x, tail_y = ImGui.GetCursorPos()
        tail_x, tail_y = tonumber(tail_x) or x0, tonumber(tail_y) or tail_y
    end
    if ImGui.Dummy then ImGui.Dummy(bar_w, CHROME_TAIL_H) end
    if has_sync then
        if ImGui.SetCursorPos then ImGui.SetCursorPos(tail_x + 2, tail_y + 1) end
        draw_sync_status()
    end
    if ImGui.SetCursorPos then ImGui.SetCursorPos(x0, tail_y + CHROME_TAIL_H + 1) end
    end)
end

local function draw_tab_buttons(defs, current, id, secondary, on_change)
    for i, tab in ipairs(defs) do
        if i > 1 then ImGui.SameLine() end
        if nav_button(tab.label .. "##" .. id .. "_" .. tab.key, current == tab.key, secondary, 0, secondary and 22.0 or 24.0)
            and current ~= tab.key then
            current = tab.key
            on_change(tab.key)
        end
    end
    return current
end

local function gear_to_legacy_aug_tab(tab)
    if tab == "stored" then return "stored" end
    if tab == "stats" or tab == "effects" or tab == "focus" then return Settings.augsSubTab or "equipped" end
    return "equipped"
end

local function current_view_key()
    local main = tostring(Settings.mainTab or "bis")
    if main == "gear" then
        return "gear:" .. tostring(Settings.gearTab or "inventory")
    elseif main == "upgrade" then
        return "upgrade:" .. tostring(Settings.upgradeTab or "suggestions")
    elseif main == "bis" then
        return "bis:" .. tostring(Settings.bisListsTab or "catalog")
    elseif main == "lockouts" then
        return "lockouts:" .. tostring(Settings.lockoutsTab or "expeditions")
    end
    return main
end

local function current_view_requires_full()
    local main = tostring(Settings.mainTab or "bis")
    if main == "gear" then
        local tab = tostring(Settings.gearTab or "inventory")
        return tab == "stats" or tab == "focus" or tab == "effects"
    end
    if main == "upgrade" then
        return tostring(Settings.upgradeTab or "suggestions") == "suggestions"
    end
    return false
end

local function sync_current_view_if_needed()
    local view_key = current_view_key()
    if current_view_requires_full() and last_view_key ~= view_key then
        if state.engine_claim_disabled then
            last_view_key = view_key
            return
        end
        -- Effects/Focus: raise cooperative rich enrichment. Do not blocking-walk
        -- inventory, and do not drop the current lite/full cache.
        local main = tostring(Settings.mainTab or "")
        local gear = tostring(Settings.gearTab or "inventory")
        local force_inspect = main == "gear" and (gear == "effects" or gear == "focus")
        if force_inspect then
            pcall(function()
                local items = require('items')
                if items.clear_meta_cache then items.clear_meta_cache() end
            end)
            if Engine.ok then
                Engine.publish(true, "lite", {
                    skipLockouts = true,
                    includeLiveStats = true,
                    reason = "inspect_tab_enter",
                })
            end
            if gear == "focus" and focus.on_tab_enter then
                pcall(focus.on_tab_enter)
            end
        end
        snapshot.ensure_full()
    end
    last_view_key = view_key
end

local function set_gear_tab(tab)
    Settings.gearTab = tab
    Settings.augsSubTab = gear_to_legacy_aug_tab(tab)
    if tab == "stats" then Settings.inspectTab = "stats"
    elseif tab == "effects" then Settings.inspectTab = "live"
    elseif tab == "focus" then Settings.inspectTab = "focus" end
    mark_ui_settings("gear_tab")
end

local function set_lockouts_tab(tab)
    Settings.lockoutsTab = tab
    mark_ui_settings("lockouts_tab")
end

local function characters_tab_for_main(main)
    main = tostring(main or "")
    if main == "bis" then
        if tostring(Settings.bisListsTab or "catalog") == "edit" then return nil end
        return "bis"
    end
    if main == "spells" then return "spells" end
    if main == "lockouts" then return "lockouts" end
    if main == "gear" then
        local gear = tostring(Settings.gearTab or "inventory")
        if gear == "effects" then return "effects" end
        if gear == "focus" then return "focus" end
        if gear == "stats" then
            local mode = tostring(Settings.statsViewMode or "character")
            if mode == "search" then return "stats_search" end
            if mode == "character" then return "stats_character" end
            if mode == "plan" then return "stats_plan" end
            return nil
        end
    end
    if main == "upgrade" then
        local upgrade = tostring(Settings.upgradeTab or "suggestions")
        if upgrade == "suggestions" then return "suggestions" end
        if upgrade == "empty" then return "empty" end
        if upgrade == "compare" then
            if tostring(Settings.compareMode or "chars") == "list_list" then return nil end
            return "compare"
        end
        return nil
    end
    if main == "gear" then
        local gear = tostring(Settings.gearTab or "inventory")
        if gear == "worn" then return "worn" end
        if gear == "stored" then return "stored" end
        return "inventory"
    end
    if main == "stock" then return "stock" end
    if main == "type12" then return "type12" end
    return nil
end

local function draw_characters_chrome(main)
    local drew = false
    if Settings.showCharactersPill == true then
        local tab = characters_tab_for_main(main)
        if tab then
            local width = 260
            if characters.is_list and characters.is_list(tab) then width = 280
            elseif characters.is_primary(tab) then width = 320
            elseif characters.is_picker(tab) then width = 280 end
            characters.draw_pill(tab, { width = width, height = 22 })
            drew = true
            local msg = characters.take_status()
            if msg and msg ~= "" then
                ImGui.SameLine()
                col_text(Theme.dim, msg)
            end
        end
    end
    -- List pill is global BiS mode chrome (not Link Scope). Shown even in Manage Lists.
    if tostring(main or "") == "bis" and bis.draw_list_pill then
        -- Clear dropdown-open guard before chrome combos (DSK Focus) draw;
        -- body runs after this and must not wipe the flag mid-frame.
        if bis.prep_chrome then bis.prep_chrome() end
        if drew then ImGui.SameLine() end
        if bis.draw_list_pill({ height = 22 }) then drew = true end
        -- Missing Only + Anguish/DSK focus live right of the pill (not in edit mode).
        if tostring(Settings.bisListsTab or "catalog") ~= "edit" and bis.draw_quick_toggles then
            if drew then ImGui.SameLine() end
            bis.draw_quick_toggles()
        end
    end
    return drew
end

local function draw_gear_chrome()
    local cur = Settings.gearTab or "inventory"
    cur = draw_tab_buttons({
        { key = "inventory", label = "Inventory" },
        { key = "worn", label = "Worn Augs" },
        { key = "stored", label = "Stored Augs" },
        { key = "stats", label = "Stats" },
        { key = "effects", label = "Effects" },
        { key = "focus", label = "Focus" },
    }, cur, "tg_gear", true, set_gear_tab)
    ImGui.Separator()
    if cur == "stats" and stats.draw_view_chrome then
        stats.draw_view_chrome()
    end
    return cur
end

local function draw_gear_body(cur)
    cur = tostring(cur or Settings.gearTab or "inventory")
    if cur == "stats" then request_item_index("stats")
    elseif cur == "focus" then request_item_index("focus") end
    sync_current_view_if_needed()
    if cur == "worn" then diag.time("ui.gear.worn", worn.draw)
    elseif cur == "stored" then diag.time("ui.gear.stored", augbag.draw)
    elseif cur == "stats" then diag.time("ui.gear.stats", stats.draw)
    elseif cur == "effects" then diag.time("ui.gear.effects", live_stats.draw)
    elseif cur == "focus" then diag.time("ui.gear.focus", focus.draw)
    else diag.time("ui.gear.inventory", inventory.draw) end
end

local function draw_inspect_chrome()
    local cur = Settings.inspectTab or "stats"
    cur = draw_tab_buttons({
        { key = "stats", label = "Stats" },
        { key = "live", label = "Effects" },
        { key = "focus", label = "Focus" },
    }, cur, "tg_inspect", true, function(tab)
        Settings.inspectTab = tab
        mark_ui_settings("inspect_tab")
    end)
    ImGui.Separator()
    if cur == "stats" and stats.draw_view_chrome then
        stats.draw_view_chrome()
    end
    return cur
end

local function draw_inspect_body(cur)
    cur = tostring(cur or Settings.inspectTab or "stats")
    if cur == "stats" then request_item_index("stats")
    elseif cur == "focus" then request_item_index("focus") end
    sync_current_view_if_needed()
    if cur == "focus" then diag.time("ui.inspect.focus", focus.draw)
    elseif cur == "live" then diag.time("ui.inspect.live", live_stats.draw)
    else diag.time("ui.inspect.stats", stats.draw) end
end

local function draw_upgrade_chrome()
    local cur = Settings.upgradeTab or "suggestions"
    cur = draw_tab_buttons({
        { key = "suggestions", label = "Suggestions" },
        { key = "compare", label = "Compare" },
        { key = "empty", label = "Empty" },
    }, cur, "tg_upgrade", true, function(tab)
        Settings.upgradeTab = tab
        mark_ui_settings("upgrade_tab")
    end)
    ImGui.Separator()
    return cur
end

local function draw_upgrade_body(cur)
    request_item_index("upgrade")
    cur = tostring(cur or Settings.upgradeTab or "suggestions")
    sync_current_view_if_needed()
    if cur == "compare" then diag.time("ui.upgrade.compare", compare.draw)
    elseif cur == "empty" then diag.time("ui.upgrade.empty", empty.draw)
    else diag.time("ui.upgrade.suggestions", suggest.draw) end
end

local function draw_bis_lists_chrome()
    -- List pill owns bisListsTab + bisListMode. Do not rewrite them here —
    -- syncing tab from mode every frame made it impossible to leave custom lists.
    return Settings.bisListsTab or "catalog"
end

local function draw_bis_lists_body(cur)
    cur = tostring(cur or Settings.bisListsTab or "catalog")
    sync_current_view_if_needed()
    if cur == "edit" then
        if setup.draw_user_lists_editor then diag.time("ui.bis_lists.edit", setup.draw_user_lists_editor)
        else col_text(Theme.amber, "List editor is unavailable.") end
    else
        -- Tab wins: keep bisListMode aligned so bis.draw matches the pill.
        if cur == "catalog" then
            if Settings.bisListMode ~= "catalog" then Settings.bisListMode = "catalog" end
        elseif cur == "my" then
            if Settings.bisListMode ~= "user" then Settings.bisListMode = "user" end
        end
        diag.time("ui.bis_lists.catalog", bis.draw)
    end
end

local function draw_lockouts_chrome()
    local cur = Settings.lockoutsTab or "expeditions"
    cur = draw_tab_buttons({
        { key = "expeditions", label = "Instances" },
        { key = "don", label = "Dragons of Norrath" },
    }, cur, "tg_lockouts", true, set_lockouts_tab)
    ImGui.Separator()
    return cur
end

local function draw_lockouts_mode_chrome()
    local cur = Settings.lockoutsTab or "expeditions"
    return draw_tab_buttons({
        { key = "expeditions", label = "Instances" },
        { key = "don", label = "Dragons of Norrath" },
    }, cur, "tg_lockouts_inline", true, set_lockouts_tab)
end

local function draw_lockouts_body(cur)
    cur = tostring(cur or Settings.lockoutsTab or "expeditions")
    sync_current_view_if_needed()
    if cur == "don" then diag.time("ui.lockouts.don", don_tab.draw)
    else diag.time("ui.lockouts.expeditions", lockouts_tab.draw) end
end

local function draw_secondary_chrome(main)
    main = tostring(main or "")
    if main == "gear" then return draw_gear_chrome() end
    if main == "upgrade" then return draw_upgrade_chrome() end
    if main == "bis" then return draw_bis_lists_chrome() end
    if main == "lockouts" then return draw_lockouts_chrome() end
    return nil
end

local function draw_main_tab_chrome()
    local cur = Settings.mainTab or "bis"
    local tabs = {
        { key = "gear", label = "Gear" },
        { key = "upgrade", label = "Upgrade" },
        { key = "bis", label = "TurboBiS" },
        { key = "type12", label = "Type 12" },
        { key = "spells", label = "Spells" },
        { key = "lockouts", label = "Lockouts" },
        { key = "stock", label = "Stock Up" },
        { key = "setup", label = "Setup" },
    }
    cur = draw_tab_buttons(tabs, cur, "tg_main", false, function(tab_key)
        if cur ~= tab_key then
            Settings.mainTab = tab_key
            mark_ui_settings("main_tab")
        end
    end)
    ImGui.Separator()
    local drew = draw_characters_chrome(cur)
    local inline_secondary = nil
    if cur == "spells" and spells_tab.draw_mode_chrome then
        if drew then ImGui.SameLine() end
        inline_secondary = spells_tab.draw_mode_chrome()
        drew = true
    elseif cur == "lockouts" then
        if drew then ImGui.SameLine() end
        inline_secondary = draw_lockouts_mode_chrome()
        drew = true
    end
    if drew then
        ImGui.Separator()
    end
    local secondary = inline_secondary or draw_secondary_chrome(cur)
    return cur, secondary
end

local function draw_main_tab_body(cur, secondary)
    cur = tostring(cur or Settings.mainTab or "bis")
    local enter_key = cur .. ":" .. tostring(secondary or "")
    if last_enter_view_key ~= enter_key then
        if cur == "spells" and spells_tab.on_tab_enter then spells_tab.on_tab_enter()
        elseif cur == "lockouts" and tostring(secondary or Settings.lockoutsTab or "expeditions") == "don"
            and don_tab.on_tab_enter then don_tab.on_tab_enter()
        elseif cur == "lockouts" and lockouts_tab.on_tab_enter then lockouts_tab.on_tab_enter() end
    end
    last_enter_view_key = enter_key
    last_main_tab = cur
    local tab_key = "ui.tab." .. cur
    diag.time(tab_key, function()
        if cur == "gear" then draw_gear_body(secondary)
        elseif cur == "upgrade" then draw_upgrade_body(secondary)
        elseif cur == "bis" then draw_bis_lists_body(secondary)
        elseif cur == "type12" then
            sync_current_view_if_needed()
            diag.time("ui.type12", type12_tab.draw)
        elseif cur == "lockouts" then draw_lockouts_body(secondary)
        elseif cur == "stock" then
            sync_current_view_if_needed()
            diag.time("ui.stock", inventory.draw_stock)
        else
            sync_current_view_if_needed()
            if cur == "spells" then spells_tab.draw()
            elseif cur == "setup" then setup.draw()
            else draw_bis_lists_body(secondary) end
        end
    end)
end

local function begin_main_scroll_child()
    local child_began, child_open = false, true
    if not ImGui.BeginChild then return child_began, child_open end
    -- Always reserve the vertical scrollbar so GetContentRegionAvail().x is
    -- constant. Without this, the scrollbar appearing/disappearing shifts the
    -- available width ~14px, which flips toolbar wrapping / the "Tip:" line /
    -- column widths every frame -> the BiS dropdowns and roster jitter wildly.
    local body_flags = (ImGuiWindowFlags and ImGuiWindowFlags.AlwaysVerticalScrollbar) or 0
    local ok, open = pcall(function()
        if ImVec2 then
            return ImGui.BeginChild("##tg_main_scroll_body", ImVec2(0, 0), false, body_flags)
        end
        return ImGui.BeginChild("##tg_main_scroll_body", 0, 0, false, body_flags)
    end)
    if ok then
        child_began = true
        child_open = (open ~= false)
    end
    return child_began, child_open
end

local function draw_scroll_body_offline_note()
    -- Viewer mode (UI + local bg) is normal; do not burn a footer row for it
    -- (that row alone pushed some tabs into a vertical scrollbar).
    if Engine.ok or state.engine_claim_disabled then return end
    ImGui.Separator()
    col_text(Theme.amber, "Sync offline - showing cached data only.")
end

local function draw_main_body()
    return diag.time("ui.main_body", function()
        if item_actions.reset_popup_frame then item_actions.reset_popup_frame() end
        -- Action feedback is drawn in the fixed-height header status band (see
        -- draw_sync_status); rendering it inline here inserted/removed a row and
        -- shoved the whole window down, which read as a distracting resize.
        if item_actions.draw_pending_modal then item_actions.draw_pending_modal() end
        if item_actions.draw_in_flight then item_actions.draw_in_flight() end
        diag.time("ui.global_search.bar", draw_global_search_bar)
        ImGui.Separator()

        local searching = global_search_active()
        local cur, secondary = nil, nil
        if not searching then
            -- Keep main + secondary tabs (+ Characters pill) above the scroll
            -- region so they stay visible on every tab, including Inspect.
            cur, secondary = draw_main_tab_chrome()
        end

        local child_began, child_open = begin_main_scroll_child()
        local ok, err = true, nil
        if child_open then
            ok, err = pcall(function()
                if searching then
                    diag.time("ui.global_search.results", draw_global_search_results)
                else
                    draw_main_tab_body(cur, secondary)
                    draw_scroll_body_offline_note()
                end
            end)
        end
        if child_began then
            ImGui.EndChild()
        end
        if not ok then error(err) end
    end)
end

function M.main_window_rect()
    return M._last_main_rect
end

function M.draw_ui()
    return diag.time("ui.draw", function()
    -- Background responder draws nothing until shown (/tgear show sets state.show,
    -- promoting the hidden instance to a visible window without a new process).
    if state.bg and not state.show then return end
    local th = push_theme()
    local visible = state.show == true and not state.bg
    diag.time(visible and "ui.draw_visible" or "ui.draw_hidden", function()
    if not state.show then draw_mini() end
    if state.show then
        diag.time("ui.window.main", function()
        ImGui.PushStyleVar(ImGuiStyleVar.WindowBorderSize, 1.5)
        ImGui.PushStyleVar(ImGuiStyleVar.WindowPadding, ImVec2(6, 4))
        ImGui.PushStyleColor(ImGuiCol.Border, 0.88, 0.65, 0.24, 0.78)
        local title = string.format("TurboGear v%s###TurboGearMain", tostring(CFG.version or "?"))
        local window_open = state.show ~= false
        local pos = Settings.mainWindowPos
        if pos and pos.x and pos.y and ImGui.SetNextWindowPos then
            ImGui.SetNextWindowPos(pos.x, pos.y, ImGuiCond.Appearing)
        end
        local size = Settings.mainWindowSize
        if size and size.w and size.h and ImGui.SetNextWindowSize then
            ImGui.SetNextWindowSize(size.w, size.h, ImGuiCond.Appearing)
        end
        local begin_ok, open, vis = pcall(function()
            return diag.time("ui.main_begin", function()
            return ImGui.Begin(title, window_open, MAIN_WINDOW_FLAGS)
            end)
        end)
        if not begin_ok then
            state.err_once = open
        else
            if vis == nil then vis = open end
            if open == false then
                hide_main_window()
                vis = false
            end
            if vis and state.show ~= false then
                local ok, e = pcall(function()
                    draw_window_chrome()
                    draw_main_body()
                    persist_window_geom("mainWindowPos", "mainWindowSize")
                    M._last_main_rect = window_screen_rect()
                    if inspect_dock.enabled and inspect_dock.enabled() then
                        inspect_dock.set_anchor(M._last_main_rect)
                    end
                end)
                if not ok then state.err_once = e end
                if state.err_once then col_text(Theme.amber, "Render warning (console): " .. tostring(state.err_once)) end
            end
            ImGui.End()
        end
        ImGui.PopStyleColor(1)
        ImGui.PopStyleVar(2)
        end)
    end
    end)
    pop_theme(th)
    if state.err_once then print(string.format("[TurboGear] render error: %s", tostring(state.err_once))); state.err_once = nil end
    if state.pending_stop then
        state.pending_stop = nil
        state.run = false
    end
    end)
end

return M
