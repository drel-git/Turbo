-- TurboGear/ui.lua
-- The UI shell: window frame, header (Minimize), tab bar, and the crash-safe
-- render wrapper. Data/IO never runs in here beyond what the tabs read from the
-- already-gathered Store/snapshot.

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
local lockouts_tab = require('tabs.lockouts')
local spells_tab   = require('tabs.spells')
local setup   = require('tabs.setup')
local global_search = require('global_search')
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
local last_cache_reload = 0

local iconImg = nil
local iconLoadAttempted = false
local lastMiniPosSaveMs = 0

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
local MAIN_WINDOW_FLAGS = (ImGuiWindowFlags.NoTitleBar or 0) + (ImGuiWindowFlags.NoCollapse or 0)

local ui_drag = { excludes = {}, grabbing = false, drag_candidate = false, header_band = nil, last_mx = nil, last_my = nil }
local MAIN_DRAG_THRESHOLD = 4.0
local MINI_DRAG_THRESHOLD = 6.0
local MAIN_CUSTOM_DRAG = true

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

local function mouse_screen_pos()
    if not ImGui.GetMousePos then return nil, nil end
    return vec2_xy(ImGui.GetMousePos())
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

local function item_screen_rect(w, h)
    if ImGui.GetItemRectMin and ImGui.GetItemRectMax then
        local rmin, rmin_y = ImGui.GetItemRectMin()
        local rmax, rmax_y = ImGui.GetItemRectMax()
        local x1, y1 = vec2_xy(rmin, rmin_y)
        local x2, y2 = vec2_xy(rmax, rmax_y)
        if x2 > x1 and y2 > y1 then
            return { x1 = x1, y1 = y1, x2 = x2, y2 = y2 }
        end
    end
    return screen_rect_at_cursor(w, h)
end

local function point_in_rect(px, py, rect)
    if not rect then return false end
    return px >= rect.x1 and px <= rect.x2 and py >= rect.y1 and py <= rect.y2
end

local function ui_drag_clear_frame_regions()
    ui_drag.excludes = {}
    ui_drag.header_band = nil
end

local function ui_drag_reset()
    ui_drag_clear_frame_regions()
    ui_drag.grabbing = false
    ui_drag.drag_candidate = false
    ui_drag.last_mx, ui_drag.last_my = nil, nil
end

local function hide_main_window()
    state.show = false
    M._last_main_rect = nil
    ui_drag_reset()
end

local function ui_drag_set_header_band()
    if not MAIN_CUSTOM_DRAG then return end
    local win = window_screen_rect()
    if not win then return end
    ui_drag.header_band = {
        x1 = win.x1,
        y1 = win.y1,
        x2 = win.x2,
        y2 = win.y1 + HEADER_BAND_H,
    }
end

local function drag_main_window_manual(mx, my)
    if not (ImGui.SetWindowPos and mx and my) then return false end
    if ui_drag.last_mx and ui_drag.last_my then
        local dx = mx - ui_drag.last_mx
        local dy = my - ui_drag.last_my
        if dx ~= 0 or dy ~= 0 then
            local px, py = vec2_xy(ImGui.GetWindowPos())
            local nx = math.floor((px + dx) + 0.5)
            local ny = math.floor((py + dy) + 0.5)
            ImGui.SetWindowPos(nx, ny)
        end
    end
    ui_drag.last_mx, ui_drag.last_my = mx, my
    return true
end

local function ui_drag_add_exclude(rect)
    if rect then ui_drag.excludes[#ui_drag.excludes + 1] = rect end
end

local function ui_drag_pointer_blocked(px, py)
    for _, rect in ipairs(ui_drag.excludes) do
        if point_in_rect(px, py, rect) then return true end
    end
    return false
end

local function ui_drag_apply_move()
    if not MAIN_CUSTOM_DRAG then return end
    if not ui_drag.grabbing then return end
    if not (ImGui.IsMouseDown and ImGui.IsMouseDown(0)) then return end
    local mx, my = mouse_screen_pos()
    if mx and my then drag_main_window_manual(mx, my) end
end

local function ui_drag_handle_input()
    if not MAIN_CUSTOM_DRAG then return end
    local mx, my = mouse_screen_pos()
    if not mx or not my or not ui_drag.header_band then
        return
    end
    local in_header = point_in_rect(mx, my, ui_drag.header_band)
    local blocked = ui_drag_pointer_blocked(mx, my)
    local mouse_down = ImGui.IsMouseDown and ImGui.IsMouseDown(0)

    if ImGui.IsMouseClicked and ImGui.IsMouseClicked(0) then
        if in_header and not blocked then
            ui_drag.drag_candidate = true
            ui_drag.last_mx, ui_drag.last_my = mx, my
            if ImGui.ResetMouseDragDelta then ImGui.ResetMouseDragDelta(0) end
        elseif not ui_drag.grabbing then
            ui_drag.drag_candidate = false
            ui_drag.last_mx, ui_drag.last_my = nil, nil
        end
    end

    if ui_drag.drag_candidate and ImGui.IsMouseDragging and ImGui.IsMouseDragging(0, MAIN_DRAG_THRESHOLD) then
        ui_drag.grabbing = true
    end

    if not mouse_down then
        ui_drag.grabbing = false
        ui_drag.drag_candidate = false
        ui_drag.last_mx, ui_drag.last_my = nil, nil
    end

    if in_header and not blocked and not ui_drag.grabbing and not ui_drag.drag_candidate
        and not mouse_down and ImGui.SetTooltip then
        ImGui.SetTooltip("Drag title bar to move TurboGear.")
    end
end

local function nowMs()
    return (mq.gettime and mq.gettime()) or (os.time() * 1000)
end

local function persistMiniPos(force)
    if not SaveSettings then return end
    local wx, wy = ImGui.GetWindowPos()
    wx, wy = tonumber(wx), tonumber(wy)
    if not wx or not wy then return end
    local prev = Settings.miniWindowPos
    if not force and prev and math.abs((prev.x or 0) - wx) < 0.5 and math.abs((prev.y or 0) - wy) < 0.5 then
        return
    end
    local t = nowMs()
    if not force and (t - lastMiniPosSaveMs) < 400 then return end
    Settings.miniWindowPos = { x = wx, y = wy }
    lastMiniPosSaveMs = t
    SaveSettings()
end

local function dragMiniWindow(dragThreshold)
    dragThreshold = tonumber(dragThreshold) or 0.0
    if not ImGui.IsMouseDragging or not ImGui.GetMouseDragDelta or not ImGui.SetWindowPos then return false end
    if not ImGui.IsMouseDragging(0, dragThreshold) then return false end
    local delta = ImGui.GetMouseDragDelta(0)
    local dx = type(delta) == "table" and tonumber(delta.x or delta[1]) or tonumber(delta) or 0
    local dy = type(delta) == "table" and tonumber(delta.y or delta[2]) or 0
    if dx == 0 and dy == 0 then return false end
    local px, py = vec2_xy(ImGui.GetWindowPos())
    ImGui.SetWindowPos(px + dx, py + dy)
    if ImGui.ResetMouseDragDelta then ImGui.ResetMouseDragDelta(0) end
    persistMiniPos(false)
    return true
end

local function sync_full()
    snapshot.invalidate()
    if state.engine_claim_disabled then
        mq.cmd(cfg.soft_start_bg_command())
        mq.cmd('/squelch /tgearbg sync')
        pcall(function()
            if Store.reload_cache_if_changed then Store.reload_cache_if_changed(false)
            else Store.reload_cache() end
        end)
        return
    end
    if cfg.Settings.autoLaunch then cfg.launch_peers() end
    if cfg.Settings.autoAddOnlinePeers ~= false then cfg.launch_all_online_peers() end
    Engine.publish(true, "full")
    Engine.request_all(true)
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
    local bank_w = 88.0
    if ImGui.BeginTable then
        local flags = (ImGuiTableFlags.NoSavedSettings or 0) + (ImGuiTableFlags.NoPadOuterX or 0)
        if ImGui.BeginTable("##tg_global_search_bar", 4, flags) then
            ImGui.TableSetupColumn("Search", ImGuiTableColumnFlags.WidthStretch, 1.0)
            ImGui.TableSetupColumn("Clear", ImGuiTableColumnFlags.WidthFixed, clear_w + 8.0)
            ImGui.TableSetupColumn("Sync", ImGuiTableColumnFlags.WidthFixed, sync_w + 8.0)
            ImGui.TableSetupColumn("Bank", ImGuiTableColumnFlags.WidthFixed, bank_w + 8.0)
            ImGui.TableNextRow()

            ImGui.TableSetColumnIndex(0)
            ImGui.SetNextItemWidth(-1)
            local next_val = input_text_hint("##tg_global_search", "Search everywhere...", Settings.globalSearch or "")
            if next_val ~= (Settings.globalSearch or "") then
                Settings.globalSearch = next_val
                global_search.invalidate()
                SaveSettings()
            end

            ImGui.TableSetColumnIndex(1)
            if theme.themed_button("Clear##tg_gs_clear", Theme.steel, clear_w, 0) then
                if tostring(Settings.globalSearch or "") ~= "" then
                    Settings.globalSearch = ""
                    global_search.invalidate()
                    SaveSettings()
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

            ImGui.TableSetColumnIndex(3)
            if theme.themed_button("Sync Banks##tg_global_bank", Theme.purple, bank_w, 0) then
                if state.engine_claim_disabled then
                    mq.cmd(cfg.soft_start_bg_command())
                    mq.cmd('/timed 5 /squelch /tgearbg sync')
                else
                    Engine.sync_banks_network()
                end
            end
            if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
                ImGui.SetTooltip("Capture this character's open bank and request full snapshots from peers. Open the bank on the owner first.")
            end
            ImGui.EndTable()
        end
        return
    end

    ImGui.SetNextItemWidth(math.max(120.0, content_avail_x() - (clear_w + sync_w + bank_w + 36.0)))
    local next_val = input_text_hint("##tg_global_search", "Search everywhere...", Settings.globalSearch or "")
    if next_val ~= (Settings.globalSearch or "") then
        Settings.globalSearch = next_val
        global_search.invalidate()
        SaveSettings()
    end
    ImGui.SameLine()
    if theme.themed_button("Clear##tg_gs_clear", Theme.steel, clear_w, 0) then
        if tostring(Settings.globalSearch or "") ~= "" then
            Settings.globalSearch = ""
            global_search.invalidate()
            SaveSettings()
        end
    end
    ImGui.SameLine()
    if theme.sync_button("Sync Now##tg_global", sync_w, 0) then sync_full() end
    ImGui.SameLine()
    if theme.themed_button("Sync Banks##tg_global_bank", Theme.purple, bank_w, 0) then
        if state.engine_claim_disabled then
            mq.cmd(cfg.soft_start_bg_command())
            mq.cmd('/timed 5 /squelch /tgearbg sync')
        else
            Engine.sync_banks_network()
        end
    end
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

local function draw_mini()
    return diag.time("ui.mini", function()
    local flags =
        (ImGuiWindowFlags.AlwaysAutoResize or 0) +
        (ImGuiWindowFlags.NoTitleBar or 0) +
        (ImGuiWindowFlags.NoResize or 0)

    -- LazBiS-style mini: icon is clickable, but a generous padded border stays
    -- draggable (ImageButton consumed almost the whole window before).
    local icon_draw_size = 48.0
    local border_pad = 8.0

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
                    and (not ImGui.IsMouseDragging or not ImGui.IsMouseDragging(0, MINI_DRAG_THRESHOLD)) then
                    state.show = not state.show
                end
                if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
                    ImGui.SetTooltip("TurboGear is running.\nClick icon to open/close full view.\nDrag gold border to move.")
                end
            else
                if ImGui.Button("TG", icon_size) then
                    state.show = not state.show
                end
                if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
                    ImGui.SetTooltip("TurboGear is running.\nClick to open/close full view.\nDrag gold border to move.")
                end
            end

            if ImGui.IsWindowHovered and ImGui.IsWindowHovered()
                and ImGui.IsMouseDragging and ImGui.IsMouseDragging(0, MINI_DRAG_THRESHOLD) then
                dragMiniWindow(MINI_DRAG_THRESHOLD)
            end

            persistMiniPos(false)
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
    ui_drag_add_exclude(item_screen_rect(side, CHROME_ROW_H))
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
    if ImGui.Dummy then
        ImGui.Dummy(drag_w, CHROME_ROW_H)
    end

    if ImGui.SetCursorPos then
        ImGui.SetCursorPos(x0 + math.max(0, bar_w - side), y0)
    end
    if theme.themed_button("-##tg_hide", Theme.gold, side, CHROME_ROW_H) then
        hide_main_window()
    end
    ui_drag_add_exclude(item_screen_rect(side, CHROME_ROW_H))
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
    return "equipped"
end

local function current_view_key()
    local main = tostring(Settings.mainTab or "bis")
    if main == "gear" then
        return "gear:" .. tostring(Settings.gearTab or "inventory")
    elseif main == "inspect" then
        return "inspect:" .. tostring(Settings.inspectTab or "stats")
    elseif main == "upgrade" then
        return "upgrade:" .. tostring(Settings.upgradeTab or "suggestions")
    elseif main == "bis" then
        return "bis:" .. tostring(Settings.bisListsTab or "catalog")
    end
    return main
end

local function current_view_requires_full()
    local main = tostring(Settings.mainTab or "bis")
    if main == "inspect" then
        local tab = tostring(Settings.inspectTab or "stats")
        return tab == "stats" or tab == "focus" or tab == "live"
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
        snapshot.ensure_full()
        if Engine.ok then Engine.publish(false, "full") end
    end
    last_view_key = view_key
end

local function set_gear_tab(tab)
    Settings.gearTab = tab
    Settings.augsSubTab = gear_to_legacy_aug_tab(tab)
    SaveSettings()
end

local function characters_tab_for_main(main)
    main = tostring(main or "")
    if main == "bis" then
        if tostring(Settings.bisListsTab or "catalog") == "edit" then return nil end
        return "bis"
    end
    if main == "spells" then return "spells" end
    if main == "lockouts" then return "lockouts" end
    if main == "inspect" then
        local inspect = tostring(Settings.inspectTab or "stats")
        if inspect == "live" then return "effects" end
        if inspect == "focus" then return "focus" end
        if inspect == "stats" then
            local mode = tostring(Settings.statsViewMode or "character")
            if mode == "search" then return "stats_search" end
            if mode == "character" then return "stats_character" end
            if mode == "plan" then return "stats_plan" end
            return nil
        end
        return nil
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
    return nil
end

local function draw_characters_chrome(main)
    if Settings.showCharactersPill ~= true then return false end
    local tab = characters_tab_for_main(main)
    if not tab then return false end
    local width = 260
    if characters.is_list and characters.is_list(tab) then width = 280
    elseif characters.is_primary(tab) then width = 320
    elseif characters.is_picker(tab) then width = 280 end
    characters.draw_pill(tab, { width = width, height = 22 })
    local msg = characters.take_status()
    if msg and msg ~= "" then
        ImGui.SameLine()
        col_text(Theme.dim, msg)
    end
    return true
end

local function draw_gear_chrome()
    local cur = Settings.gearTab or "inventory"
    cur = draw_tab_buttons({
        { key = "inventory", label = "Inventory" },
        { key = "worn", label = "Worn Augs" },
        { key = "stored", label = "Stored" },
    }, cur, "tg_gear", true, set_gear_tab)
    ImGui.Separator()
    return cur
end

local function draw_gear_body(cur)
    cur = tostring(cur or Settings.gearTab or "inventory")
    sync_current_view_if_needed()
    if cur == "worn" then diag.time("ui.gear.worn", worn.draw)
    elseif cur == "stored" then diag.time("ui.gear.stored", augbag.draw)
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
        SaveSettings()
    end)
    ImGui.Separator()
    if cur == "stats" and stats.draw_view_chrome then
        stats.draw_view_chrome()
    end
    return cur
end

local function draw_inspect_body(cur)
    cur = tostring(cur or Settings.inspectTab or "stats")
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
        SaveSettings()
    end)
    ImGui.Separator()
    return cur
end

local function draw_upgrade_body(cur)
    cur = tostring(cur or Settings.upgradeTab or "suggestions")
    sync_current_view_if_needed()
    if cur == "compare" then diag.time("ui.upgrade.compare", compare.draw)
    elseif cur == "empty" then diag.time("ui.upgrade.empty", empty.draw)
    else diag.time("ui.upgrade.suggestions", suggest.draw) end
end

local function draw_bis_lists_chrome()
    if (Settings.bisListsTab or "catalog") ~= "edit" then
        Settings.bisListsTab = tostring(Settings.bisListMode or "catalog") == "user" and "my" or "catalog"
    end
    local cur = Settings.bisListsTab or "catalog"
    cur = draw_tab_buttons({
        { key = "catalog", label = "BiS Catalog" },
        { key = "my", label = "Custom Lists" },
        { key = "edit", label = "Manage Lists" },
    }, cur, "tg_bis_lists", true, function(tab)
        Settings.bisListsTab = tab
        if tab == "catalog" then Settings.bisListMode = "catalog"
        elseif tab == "my" then Settings.bisListMode = "user" end
        SaveSettings()
    end)
    ImGui.Separator()
    return cur
end

local function draw_bis_lists_body(cur)
    cur = tostring(cur or Settings.bisListsTab or "catalog")
    sync_current_view_if_needed()
    if cur == "edit" then
        if setup.draw_user_lists_editor then diag.time("ui.bis_lists.edit", setup.draw_user_lists_editor)
        else col_text(Theme.amber, "List editor is unavailable.") end
    else
        if cur == "catalog" and Settings.bisListMode ~= "catalog" then
            Settings.bisListMode = "catalog"; SaveSettings()
        elseif cur == "my" and Settings.bisListMode ~= "user" then
            Settings.bisListMode = "user"; SaveSettings()
        end
        diag.time("ui.bis_lists.catalog", bis.draw)
    end
end

local function draw_secondary_chrome(main)
    main = tostring(main or "")
    if main == "gear" then return draw_gear_chrome() end
    if main == "inspect" then return draw_inspect_chrome() end
    if main == "upgrade" then return draw_upgrade_chrome() end
    if main == "bis" then return draw_bis_lists_chrome() end
    return nil
end

local function draw_main_tab_chrome()
    local cur = Settings.mainTab or "bis"
    local tabs = {
        { key = "gear", label = "Gear" },
        { key = "inspect", label = "Inspect" },
        { key = "upgrade", label = "Upgrade" },
        { key = "bis", label = "BiS + Lists" },
        { key = "spells", label = "Spells" },
        { key = "lockouts", label = "Lockouts" },
        { key = "setup", label = "Setup" },
    }
    cur = draw_tab_buttons(tabs, cur, "tg_main", false, function(tab_key)
        if cur ~= tab_key then
            Settings.mainTab = tab_key
            SaveSettings()
        end
    end)
    ImGui.Separator()
    if draw_characters_chrome(cur) then
        ImGui.Separator()
    end
    local secondary = draw_secondary_chrome(cur)
    return cur, secondary
end

local function draw_main_tab_body(cur, secondary)
    cur = tostring(cur or Settings.mainTab or "bis")
    local prev_tab = last_main_tab
    if prev_tab ~= cur then
        if cur == "spells" and spells_tab.on_tab_enter then spells_tab.on_tab_enter()
        elseif cur == "lockouts" and lockouts_tab.on_tab_enter then lockouts_tab.on_tab_enter() end
    end
    last_main_tab = cur
    if cur == "gear" then draw_gear_body(secondary)
    elseif cur == "inspect" then draw_inspect_body(secondary)
    elseif cur == "upgrade" then draw_upgrade_body(secondary)
    elseif cur == "bis" then draw_bis_lists_body(secondary)
    else
        sync_current_view_if_needed()
        if cur == "spells" then diag.time("ui.tab.spells", spells_tab.draw)
        elseif cur == "lockouts" then diag.time("ui.tab.lockouts", lockouts_tab.draw)
        elseif cur == "setup" then diag.time("ui.tab.setup", setup.draw)
        else draw_bis_lists_body(secondary) end
    end
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
    if Engine.ok then return end
    ImGui.Separator()
    if state.engine_claim_disabled then
        col_text(Theme.dim, "Viewer mode - using TurboGear bg/cache data.")
    else
        col_text(Theme.amber, "Sync offline - showing cached data only.")
    end
end

local function draw_main_body()
    return diag.time("ui.main_body", function()
        if item_actions.reset_popup_frame then item_actions.reset_popup_frame() end
        -- Action feedback is drawn in the fixed-height header status band (see
        -- draw_sync_status); rendering it inline here inserted/removed a row and
        -- shoved the whole window down, which read as a distracting resize.
        if item_actions.draw_pending_modal then item_actions.draw_pending_modal() end
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
    return diag.time("ui.draw_ui", function()
    -- Background responder draws nothing until shown (/tgear show sets state.show,
    -- promoting the hidden instance to a visible window without a new process).
    if state.bg and not state.show then return end
    local th = push_theme()
    if state.show and not state.bg then
        local now = os.clock()
        if (now - (last_cache_reload or 0)) >= 0.75 then
            last_cache_reload = now
            pcall(function()
                if Store.reload_cache_if_changed then Store.reload_cache_if_changed(false)
                else Store.reload_cache() end
            end)
        end
    end
    if not state.show then draw_mini() end
    if state.show then
        diag.time("ui.main_shell", function()
        ImGui.PushStyleVar(ImGuiStyleVar.WindowBorderSize, 1.5)
        ImGui.PushStyleVar(ImGuiStyleVar.WindowPadding, ImVec2(6, 4))
        ImGui.PushStyleColor(ImGuiCol.Border, 0.88, 0.65, 0.24, 0.78)
        local title = string.format("TurboGear v%s###TurboGearMain", tostring(CFG.version or "?"))
        local window_open = state.show ~= false
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
                    ui_drag_set_header_band()
                    ui_drag_handle_input()
                    ui_drag_apply_move()
                    -- Move before drawing this frame. Calling SetWindowPos after
                    -- chrome/body rendering makes the right edge appear to pulse
                    -- because some draw calls used the old position.
                    ui_drag_clear_frame_regions()
                    ui_drag_set_header_band()
                    draw_window_chrome()
                    draw_main_body()
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
    pop_theme(th)
    if state.err_once then print(string.format("[TurboGear] render error: %s", tostring(state.err_once))); state.err_once = nil end
    if state.pending_stop then
        state.pending_stop = nil
        state.run = false
    end
    end)
end

return M
