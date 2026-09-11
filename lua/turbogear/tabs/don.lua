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

local function draw_header_cell(snap)
    local cc = views.class_color(snap and snap.class)
    local name = snap and snap.name or "?"
    local cls = views.class_abbrev(snap and snap.class)
    table_col_text_centered(cc, string.format("%s (%s)", name, cls), column_width_now() or 96.0)
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

local function section_label(section)
    local prefix = section_collapsed(section.id) and "[+] " or "[-] "
    local label = prefix .. tostring(section.title or section.id or "?")
    if section.description and section.description ~= "" then
        label = label .. " · " .. tostring(section.description)
    end
    return label
end

local function section_color(section)
    local family = tostring(section and section.color_family or "")
    if family == "raid" then return Theme.gold or Theme.amber end
    if family == "progression" then return Theme.purple or Theme.magic or Theme.category end
    return Theme.cyan or Theme.category or Theme.blue
end

local function cell_tooltip(cell)
    if not (cell and cell.tooltip) then return end
    if not (ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip) then return end
    ImGui.SetTooltip(tostring(cell.tooltip))
end

local function draw_cell(state, row, now)
    if state == NO_DON_STATE then
        table_col_text_centered(Theme.dim, Settings.donCompact and "-" or "not synced", column_width_now())
        if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
            ImGui.SetTooltip("No DoN lockout snapshot for this cached character.")
        end
        return
    end
    local cell = don_matrix.present(state, row.name, now, { compact = Settings.donCompact == true })
    if cell.kind == don_matrix.KIND_ACTIVE then
        table_col_text_centered(Theme.gold or Theme.amber, cell.text, column_width_now())
        cell_tooltip(cell)
    elseif cell.kind == don_matrix.KIND_REPLAY then
        table_col_text_centered(Theme.amber or Theme.gold, cell.text, column_width_now())
        cell_tooltip(cell)
    elseif cell.kind == don_matrix.KIND_READY then
        if not theme.draw_unlock_icon(Theme.online or Theme.green, 12.0, true) then
            table_col_text_centered(Theme.online or Theme.green, "Open", column_width_now())
        end
    else
        table_col_text_centered(Theme.amber or Theme.dim, "?", column_width_now())
        cell_tooltip(cell)
    end
end

local function count_summary(state_list, now)
    return diag.time("ui.don.summary", function()
        return don_matrix.count_kinds(state_list, don_ref.all_rows() or {}, now)
    end)
end

local function summary_line(counts, nchars)
    local bits = {
        string.format("%d active", counts.active or 0),
        string.format("%d locked", counts.replay or 0),
        string.format("%d open", counts.ready or 0),
    }
    if (counts.unknown or 0) > 0 then
        bits[#bits + 1] = string.format("%d unknown", counts.unknown)
    end
    local extra = ""
    if (counts.missing or 0) > 0 then
        extra = string.format(" | %d missing snapshot%s", counts.missing, counts.missing == 1 and "" or "s")
    end
    return string.format("%s across %d character%s%s",
        table.concat(bits, " / "),
        nchars, nchars == 1 and "" or "s", extra)
end

function M.draw()
    if toggle_button(Settings.donLockedOnly and "Locked Only: ON##don_locked" or "Locked Only: OFF##don_locked", Settings.donLockedOnly == true) then
        toggle_locked_only()
    end
    ImGui.SameLine()
    if toggle_button(Settings.donCompact and "Compact: ON##don_compact" or "Compact: OFF##don_compact", Settings.donCompact == true) then
        toggle_compact()
    end
    ImGui.SameLine()
    local all_collapsed = all_sections_collapsed()
    if themed_button((all_collapsed and "Expand All##don_expand_all" or "Collapse All##don_collapse_all"), Theme.steel) then
        set_all_sections(not all_collapsed)
    end
    ImGui.Spacing()

    local scope = current_scope()
    local keys, hidden_cache_only = filter_keys_for_don(selected_keys(), scope)
    if #keys == 0 then
        col_text(Theme.amber, "No characters in this scope.")
        return
    end

    local now, snaps, states, state_list = bind_sources(keys)
    local counts = count_summary(state_list, now)
    col_text(Theme.dim, summary_line(counts, #keys))
    if hidden_cache_only and hidden_cache_only > 0 then
        col_text(Theme.dim, string.format("%d cache-only character%s hidden from Live Peers.",
            hidden_cache_only, hidden_cache_only == 1 and "" or "s"))
    end

    local cols = 1 + #keys
    local extra = 0
    if ImGuiTableFlags then extra = (ImGuiTableFlags.ScrollX or 0) + (ImGuiTableFlags.ScrollY or 0) end
    if views.begin_scroll_table("DoNReplayLockouts", cols, views.scroll_table_flags(extra), 52.0, 220.0) then
        local ok, err = pcall(function()
            ImGui.TableSetupColumn("Mission", ImGuiTableColumnFlags.WidthFixed, Settings.donCompact and 210.0 or 300.0)
            for _, key in ipairs(keys) do
                if Settings.donCompact then
                    ImGui.TableSetupColumn("##don_col_" .. tostring(key), ImGuiTableColumnFlags.WidthFixed, 74.0)
                else
                    ImGui.TableSetupColumn("##don_col_" .. tostring(key), ImGuiTableColumnFlags.WidthStretch, 1.0)
                end
            end
            views.setup_scroll_freeze("DoNReplayLockouts", 1, 1)
            ImGui.TableNextRow()
            ImGui.TableSetColumnIndex(0)
            col_text(Theme.header or Theme.item, "Mission")
            for cidx, key in ipairs(keys) do
                ImGui.TableSetColumnIndex(cidx)
                draw_header_cell(snaps[key])
            end
            for _, section in ipairs(don_ref.sections or {}) do
                local rows = section_visible_rows(section, state_list, now)
                if #rows > 0 then
                    ImGui.TableNextRow()
                    ImGui.TableSetColumnIndex(0)
                    local pushed = false
                    if ImGui.PushStyleColor and ImGuiCol and ImGuiCol.Text then
                        local c = section_color(section)
                        pushed = pcall(ImGui.PushStyleColor, ImGuiCol.Text, c[1], c[2], c[3], c[4])
                    end
                    if ImGui.Selectable(section_label(section) .. "##don_sec_" .. tostring(section.id), false) then
                        toggle_section(section.id)
                    end
                    if pushed and ImGui.PopStyleColor then pcall(ImGui.PopStyleColor, 1) end
                    for cidx = 1, #keys do
                        ImGui.TableSetColumnIndex(cidx)
                        ImGui.TextDisabled("")
                    end
                    if not section_collapsed(section.id) then
                        for _, row in ipairs(rows) do
                            ImGui.TableNextRow()
                            ImGui.TableSetColumnIndex(0)
                            col_text(Theme.slot or Theme.dim, row.name)
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
    col_text(Theme.dim, "Active = current mission. Timer = replay lockout. Unlock = ready. ? = not synchronized.")
end

function M.on_tab_enter()
    -- ui.lua calls this once when mainTab becomes "don", not per draw.
    -- Local flags stay in this process; peer REQUEST is direct only when this
    -- process owns the actor mailbox, otherwise /tgearbg donrefresh.
    don_track.ui_tab_enter()
end

return M
