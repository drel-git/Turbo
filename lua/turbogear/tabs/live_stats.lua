-- TurboGear/tabs/live_stats.lua
-- Live Effects view. Existing Stats remains the authoritative item/source analysis.

local ImGui = require('ImGui')
local mq = require('mq')
local theme = require('theme')
local Theme, col_text = theme.Theme, theme.col_text
local views = require('views')
local cfg = require('config')
local Settings, SaveSettings = cfg.Settings, cfg.SaveSettings
local stat_defs = require('stat_defs')
local suggestions = require('suggestions')
local Engine = require('engine').Engine
local inventory_stats = require('inventory_stats')
local mystats = require('mystats')
local item_actions = require('item_actions')

local M = {}
local effects_status = ""
local effects_search = ""

local SCOPE_OPTIONS = {
    { key = "online", label = "Online" },
    { key = "group", label = "Group" },
    { key = "e3", label = "E3" },
    { key = "all", label = "All Cached" },
    { key = "self", label = "Self" },
}

local ANALYZE_STAT_KEYS = {}
do
    local seen = {}
    local function add(key)
        if key and not seen[key] then
            seen[key] = true
            ANALYZE_STAT_KEYS[#ANALYZE_STAT_KEYS + 1] = key
        end
    end
    for _, group in ipairs(stat_defs.analyze_column_groups or {}) do
        for _, key in ipairs(group or {}) do add(key) end
    end
    for _, key in ipairs(stat_defs.analyze_extra_keys or {}) do add(key) end
end

local function current_scope()
    return Settings.liveStatsRosterScope or Settings.bisRosterScope or "online"
end

local function scope_label()
    local cur = current_scope()
    for _, opt in ipairs(SCOPE_OPTIONS) do
        if opt.key == cur then return opt.label end
    end
    return "Online"
end

local function set_scope(scope)
    Settings.liveStatsRosterScope = scope
    cfg.apply_linked_roster_scope(scope, "live_stats")
    SaveSettings()
end

local function age_label(ts)
    ts = tonumber(ts) or 0
    if ts <= 0 then return "unavailable" end
    local age = math.max(0, os.time() - ts)
    if age < 60 then return tostring(age) .. "s ago" end
    if age < 3600 then return tostring(math.floor(age / 60)) .. "m ago" end
    return tostring(math.floor(age / 3600)) .. "h ago"
end

local function source_display(key, snap)
    local label = views.source_label(key)
    if snap and snap.name and snap.name ~= "" then
        local cls = views.class_abbrev(snap.class or "")
        if cls and cls ~= "" then return string.format("%s (%s)", snap.name, cls) end
        return tostring(snap.name)
    end
    return label
end

local function scoped_keys()
    local keys, seen = {}, {}
    local function add(key)
        if key and not seen[key] then
            seen[key] = true
            keys[#keys + 1] = key
        end
    end
    for _, key in ipairs(views.scoped_source_keys(current_scope(), { include_offline_cache = true }) or {}) do add(key) end
    -- Keep the picker usable even when a scope ages a peer out between frames.
    for _, key in ipairs(views.source_keys(true) or {}) do add(key) end
    if #keys == 0 then add("__self__") end
    return keys
end

local function selected_key()
    local wanted = views.validate_source_key(Settings.liveStatsViewKey or "__self__")
    local keys = scoped_keys()
    for _, key in ipairs(keys) do
        if key == wanted then
            Settings.liveStatsViewKey = wanted
            return wanted, keys
        end
    end
    Settings.liveStatsViewKey = keys[1]
    return keys[1], keys
end

local function draw_scope()
    ImGui.SetNextItemWidth(150.0)
    if ImGui.BeginCombo("##live_stats_scope", "Scope: " .. scope_label()) then
        for _, opt in ipairs(SCOPE_OPTIONS) do
            if ImGui.Selectable(opt.label .. "##live_stats_scope_" .. opt.key, current_scope() == opt.key) then
                set_scope(opt.key)
                local keys = scoped_keys()
                if keys and keys[1] then
                    Settings.liveStatsViewKey = keys[1]
                    SaveSettings()
                end
            end
        end
        ImGui.EndCombo()
    end
end

local function draw_character_picker()
    local key = selected_key()
    ImGui.SameLine()
    ImGui.Text("Character:")
    ImGui.SameLine()
    local old_key = key
    key = views.draw_source_picker("##live_stats_character", key, 250.0)
    if key ~= old_key then
        Settings.liveStatsViewKey = key
        SaveSettings()
    end
end

local function draw_controls()
    local use_pill = Settings.showCharactersPill == true
    if not use_pill then
        draw_scope()
        draw_character_picker()
        ImGui.SameLine()
    end
    if theme.themed_button("Refresh##live_stats_refresh", Theme.blue) then
        Engine.request_all(true, { depth = "full" })
    end
    ImGui.SameLine()
    if theme.themed_button("Open Inv Stats##live_stats_open_inv_stats", Theme.steel) then
        inventory_stats.open_stats_page()
        Engine.publish(true, "full")
    end
    if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
        ImGui.SetTooltip("Opens this box's Inventory Stats page and republishes a full snapshot from the named stat labels.")
    end
    ImGui.SameLine()
    if theme.themed_button("Show #mystats##live_stats_show_mystats", Theme.steel) then
        mystats.open()
    end
    if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
        ImGui.SetTooltip("#mystats can be displayed for manual comparison; TurboGear avoids reading its STML body because it crashed this client.")
    end
    ImGui.SameLine()
    ImGui.SetNextItemWidth(220.0)
    effects_search = ImGui.InputText("##effects_search", effects_search or "", 128) or ""
    if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
        ImGui.SetTooltip("Filter buffs and songs by name.")
    end
    if ImGui.SameLine then ImGui.SameLine() end
    col_text(Theme.dim, "Search effects")
    if ImGui.NewLine then ImGui.NewLine() end
end

local function open_spell_alla(name)
    name = tostring(name or ""):match("^%s*(.-)%s*$") or ""
    if name == "" then
        effects_status = "No spell name to open."
        return false
    end
    local ok = item_actions.open_alla_spell(name)
    effects_status = item_actions.status_msg
    return ok and true or false
end

local function copy_buff_name(name)
    name = tostring(name or ""):match("^%s*(.-)%s*$") or ""
    if name == "" then return false end
    if ImGui.SetClipboardText then pcall(ImGui.SetClipboardText, name) end
    effects_status = "Copied " .. name
    return true
end

local function inspect_live_self_buff(buff, source_key)
    if source_key ~= "__self__" then
        effects_status = "Inspect is available for this box's live buffs only."
        return false
    end
    local slot = tonumber(buff and buff.slot)
    if not slot or slot < 1 then
        effects_status = "No live buff slot available."
        return false
    end
    local inspected = false
    local ok = pcall(function()
        local tlo = tostring(buff.kind or "") == "Song" and mq.TLO.Me.Song(slot) or mq.TLO.Me.Buff(slot)
        if tlo and tlo() and tlo.Inspect then
            tlo.Inspect()
            inspected = true
        end
    end)
    local success = ok and inspected
    effects_status = success and ("Inspecting " .. tostring(buff.name or "effect")) or "Could not inspect this effect."
    return success
end

local function normalize_stats(stats)
    stats = stats or {}
    local out = {}
    for k, v in pairs(stats) do out[k] = v end
    if out.attack == nil then out.attack = out.atk end
    if out.atk == nil then out.atk = out.attack end
    return out
end

local function merged_live_stats(source_key, live_stats)
    local merged = normalize_stats(live_stats)
    local worn, worn_ok = suggestions.worn_stat_totals(source_key, ANALYZE_STAT_KEYS)
    local filled = 0
    if worn_ok and worn then
        for _, key in ipairs(ANALYZE_STAT_KEYS) do
            if tonumber(merged[key]) == nil then
                local value = tonumber(worn[key])
                if value and value ~= 0 then
                    merged[key] = value
                    filled = filled + 1
                end
            end
        end
        if merged.attack == nil then merged.attack = merged.atk end
        if merged.atk == nil then merged.atk = merged.attack end
    end
    return merged, filled, worn_ok
end

local function draw_stat_totals(totals, table_id)
    totals = normalize_stats(totals)
    local num_cols = #stat_defs.analyze_column_groups
    local per_col = 0
    for i = 1, num_cols do
        per_col = math.max(per_col, #(stat_defs.analyze_column_groups[i] or {}))
    end

    local pair_cols = num_cols * 2
    local flags = ImGuiTableFlags.BordersInnerV + ImGuiTableFlags.RowBg
    if ImGui.BeginTable(table_id, pair_cols, flags) then
        local fixed = (ImGuiTableColumnFlags and ImGuiTableColumnFlags.WidthFixed) or 0
        for c = 1, num_cols do
            ImGui.TableSetupColumn("Stat##" .. table_id .. "_s" .. c, fixed, c == 1 and 78.0 or 82.0)
            ImGui.TableSetupColumn("Total##" .. table_id .. "_v" .. c, fixed, 54.0)
        end
        ImGui.TableNextRow()
        for c = 0, num_cols - 1 do
            ImGui.TableSetColumnIndex(c * 2)
            col_text(Theme.section or Theme.header, stat_defs.analyze_column_headers[c + 1] or "")
            ImGui.TableSetColumnIndex(c * 2 + 1)
            ImGui.TextDisabled("")
        end
        for row_idx = 1, per_col do
            ImGui.TableNextRow()
            for c = 0, num_cols - 1 do
                local key = stat_defs.analyze_column_groups[c + 1] and stat_defs.analyze_column_groups[c + 1][row_idx]
                ImGui.TableSetColumnIndex(c * 2)
                if key then
                    col_text(Theme.header, stat_defs.analyze_label(key))
                    ImGui.TableSetColumnIndex(c * 2 + 1)
                    local value = tonumber(totals and totals[key])
                    if value ~= nil then
                        col_text(Theme.value, stat_defs.analyze_value(key, totals))
                    else
                        col_text(Theme.placeholder or Theme.dim, "-")
                    end
                else
                    ImGui.TextDisabled("")
                    ImGui.TableSetColumnIndex(c * 2 + 1)
                    ImGui.TextDisabled("")
                end
            end
        end
        ImGui.EndTable()
    end
end

local function format_duration(seconds)
    seconds = tonumber(seconds)
    if not seconds or seconds <= 0 then return "-" end
    seconds = math.floor(seconds)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    if h > 0 then return string.format("%d:%02d:%02d", h, m, s) end
    return string.format("%d:%02d", m, s)
end

local function effect_context_menu(buff, source_key, suffix)
    local name = tostring(buff and buff.name or "")
    if ImGui.BeginPopupContextItem and ImGui.BeginPopupContextItem("##effect_ctx_" .. tostring(suffix or name)) then
        local self_live = source_key == "__self__"
        if ImGui.BeginDisabled and not self_live then ImGui.BeginDisabled(true) end
        if ImGui.Selectable("Inspect in-game##effect_inspect_" .. tostring(suffix)) then
            inspect_live_self_buff(buff, source_key)
        end
        if ImGui.EndDisabled and not self_live then ImGui.EndDisabled() end
        if not self_live and ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
            ImGui.SetTooltip("Inspect uses the live buff slot and only works for this box.")
        end
        if ImGui.Selectable("Copy name##effect_copy_" .. tostring(suffix)) then
            copy_buff_name(name)
        end
        if ImGui.Selectable("Open Alla##effect_alla_" .. tostring(suffix)) then
            open_spell_alla(name)
        end
        ImGui.EndPopup()
    end
end

local function filtered_effects(stats, wanted_kind)
    local out = {}
    local needle = tostring(effects_search or ""):lower()
    for _, buff in ipairs((stats and stats.buffs) or {}) do
        local name = tostring(buff.name or "")
        if tostring(buff.kind or "Buff") == wanted_kind
            and (needle == "" or name:lower():find(needle, 1, true)) then
            out[#out + 1] = buff
        end
    end
    return out
end

local function draw_effect_table(title, rows, source_key, table_id)
    col_text(Theme.section or Theme.header, title)
    if type(rows) ~= "table" or #rows == 0 then
        col_text(Theme.placeholder or Theme.dim, "None in this live snapshot.")
        return
    end
    local flags = ImGuiTableFlags.Borders + ImGuiTableFlags.RowBg + ImGuiTableFlags.Resizable
    if ImGuiTableFlags.NoSavedSettings then flags = flags + ImGuiTableFlags.NoSavedSettings end
    if ImGui.BeginTable(table_id, 3, flags) then
        ImGui.TableSetupColumn("Slot", ImGuiTableColumnFlags.WidthFixed, 48.0)
        ImGui.TableSetupColumn("Name", ImGuiTableColumnFlags.WidthStretch, 1.0)
        ImGui.TableSetupColumn("Time", ImGuiTableColumnFlags.WidthFixed, 78.0)
        ImGui.TableHeadersRow()
        for i, buff in ipairs(rows) do
            local suffix = tostring(table_id) .. "_" .. tostring(i) .. "_" .. tostring(buff.slot or "")
            ImGui.TableNextRow()
            ImGui.TableSetColumnIndex(0)
            col_text(Theme.dim, tostring(buff.slot or "-"))
            ImGui.TableSetColumnIndex(1)
            col_text(Theme.item, tostring(buff.name or "?"))
            effect_context_menu(buff, source_key, suffix)
            ImGui.TableSetColumnIndex(2)
            col_text(Theme.value, format_duration(buff.duration))
        end
        ImGui.EndTable()
    end
end

local function draw_current_line(stats)
    local parts = {}
    local function add(label, current, maxv)
        current, maxv = tonumber(current), tonumber(maxv)
        if current and maxv and current ~= maxv then
            parts[#parts + 1] = string.format("%s %d/%d", label, current, maxv)
        elseif maxv then
            parts[#parts + 1] = string.format("%s %d", label, maxv)
        end
    end
    add("HP", stats.currentHp, stats.hp)
    add("Mana", stats.currentMana, stats.mana)
    add("End", stats.currentEndurance, stats.endurance)
    if #parts > 0 then col_text(Theme.dim, table.concat(parts, " | ")) end
end

local function draw_live_stats_content()
    local key = selected_key()
    local snap = views.source_snapshot(key)
    local stats = snap and snap.liveStats or nil

    if not snap then
        col_text(Theme.amber, "No snapshot for this character yet. Use Sync Now or wait for the peer to publish.")
        return
    end

    col_text(Theme.section or Theme.header, "Effects: " .. source_display(key, snap))
    if stats then
        col_text(Theme.dim, "Snapshot: " .. age_label(stats.updated))
        draw_current_line(stats)
        if tonumber(stats.inventoryStatsMerged) and tonumber(stats.inventoryStatsMerged) > 0 then
            col_text(Theme.dim, string.format("Inventory Stats labels merged %d live row(s).", tonumber(stats.inventoryStatsMerged) or 0))
        end
    else
        col_text(Theme.amber, "No live stat snapshot yet for this character.")
        return
    end
    local buffs = filtered_effects(stats, "Buff")
    local songs = filtered_effects(stats, "Song")
    col_text(Theme.dim, string.format("%d buff%s | %d song/short-duration effect%s",
        #buffs, #buffs == 1 and "" or "s", #songs, #songs == 1 and "" or "s"))
    if effects_status ~= "" then col_text(Theme.dim, effects_status) end

    ImGui.Spacing()
    local display_stats, filled_count, worn_ok = merged_live_stats(key, stats)
    local confident = (tonumber(stats.inventoryStatsMerged) or 0) > 0
    if confident then
        draw_stat_totals(display_stats, "EffectsCompactTotals_" .. tostring(key))
        ImGui.Spacing()
    elseif filled_count > 0 or not worn_ok then
        col_text(Theme.dim, "Stat detail lives on the Stats tab; Effects focuses on current buffs and songs.")
    end

    draw_effect_table("Buffs", buffs, key, "EffectsBuffsTable")
    ImGui.Spacing()
    draw_effect_table("Songs / Short Duration", songs, key, "EffectsSongsTable")
end

function M.draw()
    draw_controls()

    local child_began = false
    local child_open = true
    if ImGui.BeginChild then
        local ok, open = pcall(function()
            if ImVec2 then
                return ImGui.BeginChild("##live_stats_content_scroll", ImVec2(0, 0), false, 0)
            end
            return ImGui.BeginChild("##live_stats_content_scroll", 0, 0, false, 0)
        end)
        if ok then
            child_began = true
            child_open = (open ~= false)
        end
    end
    if child_open then draw_live_stats_content() end
    if child_began and ImGui.EndChild then ImGui.EndChild() end
end

return M
