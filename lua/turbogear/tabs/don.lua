-- TurboGear/tabs/don.lua
-- Dedicated Dragons of Norrath matrix. Draw is a cached-state operation:
-- snapshot -> DoNState -> don_state.resolve -> local countdown. No Task[],
-- /tasktime, actor, or Store writes from this file.

local ImGui = require('ImGui')
local theme = require('theme')
local Theme, col_text, toggle_button, themed_button = theme.Theme, theme.col_text, theme.toggle_button, theme.themed_button
local cfg = require('config')
local Settings = cfg.Settings
local views = require('views')
local characters = require('characters')
local don_ref = require('references.don_lockouts')
local don_matrix = require('don_matrix')
local don_track = require('don_track')
local diag = require('diagnostics')

local M = {}

local SCOPE_OPTS = {}
local NO_DON_STATE = {}
local UI = {
    header_bg = { 0.10, 0.15, 0.22, 1.00 },
    row_alt = { 0.08, 0.10, 0.14, 0.68 },
    row_open = { 0.055, 0.070, 0.095, 0.72 },
    row_problem = { 0.14, 0.11, 0.08, 0.86 },
    row_hover = { 0.13, 0.20, 0.29, 0.95 },
    mission = { 0.76, 0.78, 0.82, 1.00 },
    ready = { 0.34, 0.62, 0.42, 0.82 },
    active = { 0.34, 0.78, 0.90, 1.00 },
    locked = { 0.94, 0.55, 0.35, 1.00 },
    unknown = { 0.42, 0.45, 0.50, 1.00 },
    meta = { 0.58, 0.62, 0.70, 1.00 },
    section = {
        raid = { bg = { 0.22, 0.16, 0.07, 0.94 }, fg = { 0.88, 0.66, 0.30, 1.00 }, border = { 0.70, 0.46, 0.16, 0.90 } },
        t1_missions = { bg = { 0.05, 0.24, 0.26, 0.94 }, fg = { 0.38, 0.84, 0.86, 1.00 }, border = { 0.16, 0.68, 0.72, 0.90 } },
        t1_progression = { bg = { 0.06, 0.14, 0.30, 0.94 }, fg = { 0.40, 0.64, 1.00, 1.00 }, border = { 0.20, 0.42, 0.90, 0.90 } },
        t2_missions = { bg = { 0.05, 0.20, 0.31, 0.94 }, fg = { 0.38, 0.76, 0.96, 1.00 }, border = { 0.16, 0.58, 0.82, 0.90 } },
        t2_progression = { bg = { 0.07, 0.12, 0.25, 0.94 }, fg = { 0.46, 0.62, 0.96, 1.00 }, border = { 0.20, 0.34, 0.78, 0.90 } },
        t3_missions = { bg = { 0.18, 0.10, 0.32, 0.94 }, fg = { 0.68, 0.52, 0.96, 1.00 }, border = { 0.46, 0.28, 0.84, 0.90 } },
    },
    badge = {
        active = { bg = { 0.08, 0.23, 0.29, 1.00 }, fg = { 0.42, 0.86, 0.96, 1.00 } },
        locked = { bg = { 0.22, 0.10, 0.08, 0.96 }, border = { 0.54, 0.18, 0.16, 0.76 }, label = { 0.84, 0.48, 0.42, 1.00 }, value = { 1.00, 0.57, 0.48, 1.00 } },
        open = { bg = { 0.08, 0.17, 0.11, 0.96 }, border = { 0.18, 0.42, 0.25, 0.76 }, label = { 0.48, 0.74, 0.54, 1.00 }, value = { 0.58, 0.92, 0.64, 1.00 } },
        chars = { bg = { 0.11, 0.14, 0.20, 0.96 }, border = { 0.24, 0.32, 0.44, 0.76 }, label = { 0.62, 0.68, 0.76, 1.00 }, value = { 0.82, 0.86, 0.92, 1.00 } },
    },
}

-- missing key / false = expanded; true = collapsed. First run has no keys.
local function collapsed_map()
    if type(Settings.donCollapsedSections) ~= "table" then
        Settings.donCollapsedSections = {}
    end
    return Settings.donCollapsedSections
end

local function section_collapsed(section_id)
    return collapsed_map()[tostring(section_id or "")] == true
end

local function toggle_section(section_id)
    local map = collapsed_map()
    local id = tostring(section_id or "")
    map[id] = not (map[id] == true)
    cfg.MarkSettingsDirty("don_section")
    return map[id] == true
end

local function all_sections_collapsed()
    local map = collapsed_map()
    for _, section in ipairs(don_ref.sections or {}) do
        if map[section.id] ~= true then return false end
    end
    return true
end

local function set_all_sections(v)
    local map = collapsed_map()
    local collapsed = v == true
    for _, section in ipairs(don_ref.sections or {}) do
        map[section.id] = collapsed
    end
    cfg.MarkSettingsDirty("don_sections")
end

local function toggle_locked_only()
    Settings.donLockedOnly = not (Settings.donLockedOnly == true)
    cfg.MarkSettingsDirty("don_locked")
    return Settings.donLockedOnly == true
end

local function toggle_compact()
    Settings.donCompact = not (Settings.donCompact == true)
    cfg.MarkSettingsDirty("don_compact")
    return Settings.donCompact == true
end

M.section_collapsed = section_collapsed
M.toggle_section = toggle_section
M.all_sections_collapsed = all_sections_collapsed
M.set_all_sections = set_all_sections
M.toggle_locked_only = toggle_locked_only
M.toggle_compact = toggle_compact

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

local function table_col_text_right(color, text, col_w)
    text = tostring(text or "")
    col_w = tonumber(col_w) or column_width_now() or 80.0
    local tw = views.text_width and views.text_width(text) or 0
    if col_w > 0 and tw > 0 and tw < col_w and ImGui.GetCursorPosX and ImGui.SetCursorPosX then
        local ok, x = pcall(ImGui.GetCursorPosX)
        if ok and tonumber(x) then pcall(ImGui.SetCursorPosX, tonumber(x) + math.max(0, col_w - tw - 8.0)) end
    end
    col_text(color, text)
end

local function color_u32(color)
    if theme.color_u32 then return theme.color_u32(color) end
    if not (IM_COL32 and type(color) == "table") then return nil end
    return IM_COL32(
        math.floor((color[1] or 0) * 255),
        math.floor((color[2] or 0) * 255),
        math.floor((color[3] or 0) * 255),
        math.floor((color[4] or 1) * 255))
end

local function set_row_bg(color)
    if not (ImGui.TableSetBgColor and ImGuiTableBgTarget) then return end
    local c = color_u32(color)
    if not c then return end
    pcall(ImGui.TableSetBgColor, ImGuiTableBgTarget.RowBg0, c)
    if ImGuiTableBgTarget.RowBg1 then pcall(ImGui.TableSetBgColor, ImGuiTableBgTarget.RowBg1, c) end
end

local function push_table_style()
    local pushed = 0
    if ImGui.PushStyleColor and ImGuiCol then
        local function pc(which, color)
            if which and color then
                ImGui.PushStyleColor(which, color[1], color[2], color[3], color[4])
                pushed = pushed + 1
            end
        end
        pc(ImGuiCol.TableHeaderBg, UI.header_bg)
        pc(ImGuiCol.TableRowBg, UI.row_open)
        pc(ImGuiCol.TableRowBgAlt, UI.row_alt)
        pc(ImGuiCol.TableBorderLight, { 0.17, 0.21, 0.27, 0.72 })
        pc(ImGuiCol.TableBorderStrong, { 0.22, 0.30, 0.38, 0.95 })
        pc(ImGuiCol.HeaderHovered, UI.row_hover)
    end
    return pushed
end

local function draw_header_cell(snap)
    local cc = views.class_color(snap and snap.class)
    local name = snap and snap.name or "?"
    local w = column_width_now() or 96.0
    table_col_text_centered(cc, name, w)
end

local function current_scope()
    if Settings.showCharactersPill == true then
        return characters.get_scope("lockouts")
    end
    return Settings.lockoutsRosterScope or "online"
end

local function snap_is_live(snap)
    if type(snap) ~= "table" then return false end
    return snap.status == "online" or snap.status == "stale"
end

local function selected_keys()
    local view_key, keys
    if Settings.showCharactersPill == true then
        keys = characters.source_keys("lockouts", SCOPE_OPTS)
        view_key = characters.get_view_key("lockouts")
    else
        keys = views.scoped_source_keys(Settings.lockoutsRosterScope or "online", SCOPE_OPTS)
        view_key = Settings.lockoutsViewKey or "__all__"
    end
    if (Settings.lockoutsRosterScope or "online") == "self" then
        return { "__self__" }
    end
    if view_key == characters.VIEW_SELECTED then
        return characters.active_keys("lockouts", SCOPE_OPTS)
    end
    if view_key ~= "__all__" then
        return { view_key }
    end
    return keys or {}
end

local function filter_keys_for_don(keys, scope)
    if tostring(scope or "online") ~= "online" then return keys or {}, 0 end
    local out, hidden = {}, 0
    for _, key in ipairs(keys or {}) do
        local snap = views.source_snapshot(key)
        local state = don_matrix.state_for_key(key, snap)
        if key == "__self__" or state ~= nil or snap_is_live(snap) then
            out[#out + 1] = key
        else
            hidden = hidden + 1
        end
    end
    return out, hidden
end

local function bind_sources(keys)
    local now = os.time()
    local snaps, states, state_list = {}, {}, {}
    diag.time("ui.don.resolve", function()
        for _, key in ipairs(keys or {}) do
            local snap = views.source_snapshot(key)
            snaps[key] = snap
            local state = don_matrix.state_for_key(key, snap)
            states[key] = state or (snap and not snap_is_live(snap) and NO_DON_STATE or nil)
            -- false marks a missing character snapshot so summary does not
            -- convert that column into 36 Unknown cells. Offline/cache rows
            -- without DoNState are also not authority; show them as not synced
            -- instead of polluting the summary with one ? per mission.
            state_list[#state_list + 1] = (snap and (state or (snap_is_live(snap) and {} or false))) or false
        end
    end)
    return now, snaps, states, state_list
end

local function row_has_locked(state_list, row, now)
    return don_matrix.row_qualifies_locked(state_list, row.name, now)
end

local function section_visible_rows(section, state_list, now)
    local out = {}
    for _, row in ipairs(section.rows or {}) do
        if Settings.donLockedOnly ~= true or row_has_locked(state_list, row, now) then
            out[#out + 1] = row
        end
    end
    return out
end

local function section_meta(section)
    local desc = tostring(section.description or "")
    local req, timer = desc:match("^(.-)%s+%-%s+([^%-]+)$")
    if req then return req, timer end
    if desc:match("^%d") then return "", desc end
    return desc, ""
end

local function section_color(section)
    local rec = UI.section[tostring(section and section.id or "")]
    if rec then return rec.fg, rec.bg, rec.border end
    local family = tostring(section and section.color_family or "")
    if family == "raid" then return Theme.gold or Theme.amber, { 0.20, 0.15, 0.07, 0.94 } end
    if family == "progression" then return Theme.purple or Theme.magic or Theme.category, { 0.08, 0.12, 0.26, 0.94 } end
    return Theme.cyan or Theme.category or Theme.blue, { 0.05, 0.18, 0.24, 0.94 }
end

local function cell_tooltip(cell)
    if not (cell and cell.tooltip) then return end
    if not (ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip) then return end
    ImGui.SetTooltip(tostring(cell.tooltip))
end

local function draw_cell(state, row, now)
    if state == NO_DON_STATE then
        table_col_text_centered(Theme.dim, "not synced", column_width_now())
        if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
            ImGui.SetTooltip("No DoN lockout snapshot for this cached character.")
        end
        return
    end
    local cell = don_matrix.present(state, row.name, now, { compact = false })
    if cell.kind == don_matrix.KIND_ACTIVE then
        table_col_text_centered(UI.active, cell.text, column_width_now())
        cell_tooltip(cell)
    elseif cell.kind == don_matrix.KIND_REPLAY then
        table_col_text_centered(UI.locked, cell.text, column_width_now())
        cell_tooltip(cell)
    elseif cell.kind == don_matrix.KIND_READY then
        if not theme.draw_unlock_icon(UI.ready, 11.0, true) then
            table_col_text_centered(UI.ready, "Open", column_width_now())
        end
    else
        table_col_text_centered(UI.unknown, "?", column_width_now())
        cell_tooltip(cell)
    end
end

local function count_summary(state_list, now)
    return diag.time("ui.don.summary", function()
        return don_matrix.count_kinds(state_list, don_ref.all_rows() or {}, now)
    end)
end

local function draw_badge(label, value, style)
    style = style or UI.badge.chars
    label = tostring(label or "")
    value = tostring(value or 0)
    local text = label .. " " .. value
    local pad_x, pad_y = 7.0, 2.0
    local w = math.max(62.0, (views.text_width and views.text_width(text) or 0) + pad_x * 2)
    local h = ((ImGui.GetTextLineHeight and ImGui.GetTextLineHeight()) or 14.0) + pad_y * 2
    local label_color = style.label or style.fg or Theme.dim
    local value_color = style.value or style.fg or Theme.header
    if ImGui.GetWindowDrawList and ImGui.GetCursorScreenPos and ImGui.Dummy and theme.color_u32 then
        local x, y = ImGui.GetCursorScreenPos()
        local draw = ImGui.GetWindowDrawList()
        draw:AddRectFilled(ImVec2(x, y), ImVec2(x + w, y + h), theme.color_u32(style.bg), 4.0)
        draw:AddRect(ImVec2(x, y), ImVec2(x + w, y + h), theme.color_u32(style.border or style.bg), 4.0, 0, 1.0)
        draw:AddText(ImVec2(x + pad_x, y + pad_y), theme.color_u32(label_color), label)
        draw:AddText(ImVec2(x + pad_x + ((views.text_width and views.text_width(label .. " ")) or 0), y + pad_y), theme.color_u32(value_color), value)
        ImGui.Dummy(w, h)
    else
        col_text(label_color, text)
    end
end

local function badge_width(label, value)
    local text = tostring(label or "") .. " " .. tostring(value or 0)
    return math.max(62.0, (views.text_width and views.text_width(text) or 0) + 14.0)
end

local function draw_summary_badges_right(counts, nchars)
    local specs = {
        { "Locked", counts.replay or 0, UI.badge.locked },
        { "Open", counts.ready or 0, UI.badge.open },
        { "Chars", nchars or 0, UI.badge.chars },
    }
    local total_w = 0
    for _, spec in ipairs(specs) do total_w = total_w + badge_width(spec[1], spec[2]) end
    total_w = total_w + 8.0 * (#specs - 1)
    if ImGui.GetContentRegionAvail and ImGui.SetCursorPosX and ImGui.GetCursorPosX then
        local avail = ImGui.GetContentRegionAvail()
        if type(avail) == "table" then avail = avail.x or avail[1] end
        local cur_x = tonumber(ImGui.GetCursorPosX()) or 0
        if tonumber(avail) and tonumber(avail) > total_w then
            ImGui.SameLine()
            ImGui.SetCursorPosX(cur_x + tonumber(avail) - total_w)
        else
            ImGui.SameLine()
        end
    else
        ImGui.SameLine()
    end
    for i, spec in ipairs(specs) do
        if i > 1 then ImGui.SameLine() end
        draw_badge(spec[1], spec[2], spec[3])
    end
end

local function row_problem_kind(states, row, now)
    local saw_unknown = false
    for _, state in pairs(states or {}) do
        if state == NO_DON_STATE then
            saw_unknown = true
        else
            local cell = don_matrix.present(state, row.name, now, { compact = false })
            if cell.kind == don_matrix.KIND_ACTIVE then return "active" end
            if cell.kind == don_matrix.KIND_REPLAY then return "locked" end
            if cell.kind == don_matrix.KIND_UNKNOWN then saw_unknown = true end
        end
    end
    return saw_unknown and "unknown" or "open"
end

local function draw_section_row(section, keys)
    ImGui.TableNextRow()
    local fg, bg = section_color(section)
    set_row_bg(bg)
    ImGui.TableSetColumnIndex(0)
    local req, timer = section_meta(section)
    local arrow = section_collapsed(section.id) and "[+] " or "[-] "
    local label = arrow .. tostring(section.title or section.id or "?")
    if req ~= "" then label = label .. "    " .. req end
    local selectable_flags = ImGuiSelectableFlags and (ImGuiSelectableFlags.SpanAllColumns or 0) or 0
    local pushed_text = false
    if ImGui.PushStyleColor and ImGuiCol and ImGuiCol.Text then
        ImGui.PushStyleColor(ImGuiCol.Text, fg[1], fg[2], fg[3], fg[4])
        pushed_text = true
    end
    if ImGui.Selectable(label .. "##don_sec_" .. tostring(section.id), false, selectable_flags) then
        toggle_section(section.id)
    end
    if pushed_text and ImGui.PopStyleColor then pcall(ImGui.PopStyleColor, 1) end
    if ImGui.IsItemHovered and ImGui.IsItemHovered() then set_row_bg(UI.row_hover) end
    for cidx = 1, #keys do
        ImGui.TableSetColumnIndex(cidx)
        if cidx == #keys and timer ~= "" then
            table_col_text_right(fg, timer, column_width_now())
        else
            ImGui.TextDisabled("")
        end
    end
end

function M.draw()
    local scope = current_scope()
    local keys, hidden_cache_only = filter_keys_for_don(selected_keys(), scope)
    if #keys == 0 then
        col_text(Theme.amber, "No characters in this scope.")
        return
    end

    local now, snaps, states, state_list = bind_sources(keys)
    local counts = count_summary(state_list, now)

    if toggle_button(Settings.donLockedOnly and "Locked Only: ON##don_locked" or "Locked Only: OFF##don_locked", Settings.donLockedOnly == true, 126, 0) then
        toggle_locked_only()
    end
    ImGui.SameLine()
    local all_collapsed = all_sections_collapsed()
    if themed_button((all_collapsed and "Expand All##don_expand_all" or "Collapse All##don_collapse_all"), Theme.steel) then
        set_all_sections(not all_collapsed)
    end
    draw_summary_badges_right(counts, #keys)
    if hidden_cache_only and hidden_cache_only > 0 then
        col_text(Theme.dim, string.format("%d cache-only character%s hidden from Live Peers.",
            hidden_cache_only, hidden_cache_only == 1 and "" or "s"))
    end

    local cols = 1 + #keys
    local extra = 0
    if ImGuiTableFlags then extra = (ImGuiTableFlags.ScrollX or 0) + (ImGuiTableFlags.ScrollY or 0) end
    local pushed = push_table_style()
    if views.begin_scroll_table("DoNReplayLockouts", cols, views.scroll_table_flags(extra), 52.0, 220.0) then
        local ok, err = pcall(function()
            ImGui.TableSetupColumn("Mission", ImGuiTableColumnFlags.WidthFixed, 300.0)
            for _, key in ipairs(keys) do
                ImGui.TableSetupColumn("##don_col_" .. tostring(key), ImGuiTableColumnFlags.WidthStretch, 1.0)
            end
            views.setup_scroll_freeze("DoNReplayLockouts", 1, 1)
            ImGui.TableNextRow()
            set_row_bg(UI.header_bg)
            ImGui.TableSetColumnIndex(0)
            col_text(Theme.header or Theme.item, "Mission")
            for cidx, key in ipairs(keys) do
                ImGui.TableSetColumnIndex(cidx)
                draw_header_cell(snaps[key])
            end
            for _, section in ipairs(don_ref.sections or {}) do
                local rows = section_visible_rows(section, state_list, now)
                if #rows > 0 then
                    draw_section_row(section, keys)
                    if not section_collapsed(section.id) then
                        for ridx, row in ipairs(rows) do
                            ImGui.TableNextRow()
                            local kind = row_problem_kind(states, row, now)
                            if kind ~= "open" then
                                set_row_bg(kind == "unknown" and { 0.11, 0.12, 0.15, 0.88 } or UI.row_problem)
                            elseif ridx % 2 == 0 then
                                set_row_bg(UI.row_alt)
                            end
                            ImGui.TableSetColumnIndex(0)
                            local selectable_flags = ImGuiSelectableFlags and (ImGuiSelectableFlags.SpanAllColumns or 0) or 0
                            local pushed_text = false
                            if ImGui.PushStyleColor and ImGuiCol and ImGuiCol.Text then
                                ImGui.PushStyleColor(ImGuiCol.Text, UI.mission[1], UI.mission[2], UI.mission[3], UI.mission[4])
                                pushed_text = true
                            end
                            if ImGui.Selectable then
                                ImGui.Selectable(tostring(row.name) .. "##don_row_" .. tostring(section.id) .. "_" .. tostring(row.name), false, selectable_flags)
                            else
                                col_text(UI.mission, row.name)
                            end
                            local hovered = ImGui.IsItemHovered and ImGui.IsItemHovered()
                            if pushed_text and ImGui.PopStyleColor then pcall(ImGui.PopStyleColor, 1) end
                            if hovered then set_row_bg(UI.row_hover) end
                            for cidx, key in ipairs(keys) do
                                ImGui.TableSetColumnIndex(cidx)
                                draw_cell(states[key], row, now)
                            end
                        end
                    end
                end
            end
        end)
        ImGui.EndTable()
        if not ok then col_text(Theme.amber, "DoN table error: " .. tostring(err)) end
    end
    if pushed > 0 then ImGui.PopStyleColor(pushed) end
    col_text(Theme.dim, "Active = current mission | Timer = replay lockout | Unlock = ready | ? = not synchronized")
end

function M.on_tab_enter()
    -- ui.lua calls this once when mainTab becomes "don", not per draw.
    -- Local flags stay in this process; peer REQUEST is direct only when this
    -- process owns the actor mailbox, otherwise /tgearbg donrefresh.
    don_track.ui_tab_enter()
end

return M
