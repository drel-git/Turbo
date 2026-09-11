-- TurboGear/tabs/spells_don.lua
-- Dragons of Norrath spell/disc/aura roster inside the Spells tab.

local ImGui = require('ImGui')
local theme = require('theme')
local Theme, col_text, toggle_button = theme.Theme, theme.col_text, theme.toggle_button
local cfg = require('config')
local Settings, SaveSettings = cfg.Settings, cfg.SaveSettings
local views = require('views')
local don_spells = require('don_spells')
local item_actions = require('item_actions')

local M = {}

local COL_WIDTH = 248.0
local COL_HEIGHT = 320.0
local COL_HEADER_H = 28.0
local STATUS_COL_W = 72.0

local function trim(s)
    return tostring(s or ""):match("^%s*(.-)%s*$") or ""
end

local function class_name(snap)
    return trim(snap and (snap.class or snap.className or ""))
end

local function clean_name(s)
    return trim(s):lower()
end

local function is_self_key(key, snap)
    if key == "__self__" then return true end
    local ok, mq = pcall(require, 'mq')
    if not ok or not mq or not mq.TLO or not mq.TLO.Me then return false end
    local me = mq.TLO.Me.CleanName and mq.TLO.Me.CleanName() or ""
    return clean_name(me) ~= "" and clean_name(snap and snap.name) == clean_name(me)
end

local function ability_entry(ability)
    return don_spells.bis_entry_for_ability(ability)
end

local PEER_SEARCH_STATUS = { known = true, ready = true, pack_owned = true, missing = true }

local function snap_has_spell_data(snap)
    if type(snap) ~= "table" then return false end
    if type(snap.spell_ids) == "table" and next(snap.spell_ids) ~= nil then return true end
    return type(snap.spells) == "table" and next(snap.spells) ~= nil
end

local function resolve_status(key, snap, ability)
    local entry = ability_entry(ability)
    if not entry then return "missing" end
    local handled, _match, status
    local self_col = is_self_key(key, snap)
    if self_col then
        -- Memoized inside don_spells (TTL + per-window refresh cap): cheap per frame.
        handled, _match, status = don_spells.try_live_match(entry)
    else
        -- Peer: its own spellbook answer from the last bis_search("don") reply.
        local ok_bs, bs = pcall(require, 'bis_search')
        local rec = ok_bs and bs and bs.slot_rec and bs.slot_rec(snap or key, "don", trim(ability.display_name)) or nil
        if type(rec) == "table" and PEER_SEARCH_STATUS[tostring(rec.status)] then
            return tostring(rec.status)
        end
    end
    if not handled then
        handled, _match, status = don_spells.try_match(entry, snap or {})
    end
    status = status or "missing"
    if not self_col and status == "missing" and not snap_has_spell_data(snap) then
        return "unknown"
    end
    return status
end

local function status_label(status)
    if status == "known" then return "Known" end
    if status == "ready" then return "Ready" end
    if status == "pack_owned" then return "Pack" end
    if status == "unknown" then return "Unknown" end
    return "Missing"
end

local function status_color(status)
    if status == "known" then return Theme.online or Theme.green end
    if status == "ready" then return Theme.item or Theme.gold or Theme.amber end
    if status == "pack_owned" then return Theme.amber end
    if status == "unknown" then return Theme.dim end
    return Theme.missing or Theme.brick
end

local function ability_tooltip(ability, status)
    local bits = {}
    bits[#bits + 1] = trim(ability.display_name)
    bits[#bits + 1] = "Status: " .. status_label(status)
    local learned = trim(ability.teaching_item_name or ability.source_name or "")
    if learned ~= "" then bits[#bits + 1] = "Learned from: " .. learned end
    local pack = trim(ability.source_name or "")
    if tostring(ability.source_type or "") == "bundle" and pack ~= "" then
        bits[#bits + 1] = "Pack: " .. pack
    end
    return table.concat(bits, "\n")
end

local function tooltip_if_hovered(text)
    if text and text ~= "" and ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
        ImGui.SetTooltip(text)
    end
end

local function popup_suffix(text)
    return tostring(text or ""):gsub("[^%w_]", "_")
end

local function draw_ability_context(ability, suffix)
    local name = trim(ability and ability.display_name)
    if name == "" or not ImGui.BeginPopupContextItem then return end
    suffix = popup_suffix(suffix or name)
    if ImGui.BeginPopupContextItem("##spells_don_ctx_" .. suffix) then
        col_text(Theme.item, name)
        ImGui.Separator()
        if ImGui.Selectable("Open Alla##spells_don_alla_" .. suffix) then
            item_actions.open_alla_spell(name)
        end
        if ImGui.Selectable("Copy name##spells_don_copy_" .. suffix) then
            item_actions.copy_text("DoN ability", name)
        end
        ImGui.EndPopup()
    end
end

-- Each header occupies a fixed COL_WIDTH slot (a child window), exactly like
-- the Research tab. Centered text alone only advances by the text width, so
-- SameLine placed the next name right after the previous one and the names
-- drifted left of their columns.
local HEADER_SLOT_H = 22.0
local function draw_header(key)
    local snap = views.source_snapshot(key)
    local name = snap and snap.name or views.source_label(key)
    local _, cls = views.source_header_parts(key, false) -- short class (SHD, BRS), same as Research
    local label = cls and cls ~= "" and string.format("%s (%s)", name, cls) or tostring(name or "?")
    local began, open = false, true
    if ImGui.BeginChild then
        local id = "##spells_don_hdr_" .. tostring(key):gsub("[^%w_]", "_")
        local ok, child_open = pcall(function()
            if ImVec2 then return ImGui.BeginChild(id, ImVec2(COL_WIDTH, HEADER_SLOT_H), false, 0) end
            return ImGui.BeginChild(id, COL_WIDTH, HEADER_SLOT_H, false, 0)
        end)
        if ok then began = true; open = (child_open ~= false) end
    end
    if open then views.col_text_centered(views.source_header_color(key), label, COL_WIDTH - 12.0) end
    if began and ImGui.EndChild then ImGui.EndChild() end
end

local function draw_column(key)
    local snap = views.source_snapshot(key)
    local cls = class_name(snap)
    if cls == "" then
        col_text(Theme.amber, "No class data.")
        return
    end
    local abilities = don_spells.abilities_for_class(cls)
    if #abilities == 0 then
        col_text(Theme.dim, "No DoN abilities for " .. cls .. ".")
        return
    end

    local table_flags = ImGuiTableFlags.BordersInner + ImGuiTableFlags.RowBg + ImGuiTableFlags.ScrollY
    if ImGuiTableFlags.NoSavedSettings then table_flags = table_flags + ImGuiTableFlags.NoSavedSettings end
    local table_id = "##spells_don_" .. tostring(key):gsub("[^%w_]", "_")
    if not ImGui.BeginTable(table_id, 2, table_flags, COL_WIDTH - 8.0, COL_HEIGHT - COL_HEADER_H - 8.0) then
        return
    end
    if ImGui.TableSetupScrollFreeze then pcall(ImGui.TableSetupScrollFreeze, 0, 1) end
    ImGui.TableSetupColumn("Name", ImGuiTableColumnFlags.WidthStretch, 1.0)
    ImGui.TableSetupColumn("Status", ImGuiTableColumnFlags.WidthFixed, STATUS_COL_W)
    ImGui.TableNextRow()
    ImGui.TableSetColumnIndex(0)
    col_text(Theme.header or Theme.item, "Ability")
    ImGui.TableSetColumnIndex(1)
    col_text(Theme.header or Theme.item, "Status")

    local shown = 0
    for _, ability in ipairs(abilities) do
        local status = resolve_status(key, snap, ability)
        -- Missing only: keep missing + unknown; known / ready / pack count as done.
        if Settings.spellsDonMissingOnly == true and status ~= "missing" and status ~= "unknown" then goto continue end
        shown = shown + 1
        ImGui.TableNextRow()
        ImGui.TableSetColumnIndex(0)
        col_text(status_color(status), trim(ability.display_name))
        draw_ability_context(ability, tostring(key) .. "_" .. tostring(ability.display_name))
        tooltip_if_hovered(ability_tooltip(ability, status))
        ImGui.TableSetColumnIndex(1)
        col_text(status_color(status), status_label(status))
        tooltip_if_hovered(ability_tooltip(ability, status))
        ::continue::
    end
    ImGui.EndTable()
    if shown == 0 then col_text(Theme.dim, "Nothing missing.") end
end

local function content_avail_x()
    if ImGui.GetContentRegionAvail then
        local ok, v1, v2 = pcall(ImGui.GetContentRegionAvail)
        if ok then
            if type(v1) == "table" then
                return tonumber(v1.x or v1[1]) or 0
            end
            return tonumber(v1) or tonumber(v2) or 0
        end
    end
    return 0
end

local function center_cursor_block(width)
    if not ImGui.GetCursorPosX or not ImGui.SetCursorPosX then return end
    local avail = content_avail_x()
    if avail > width then
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + math.max(0, (avail - width) * 0.5))
    end
end

-- Same row as the Research tab: Missing only, legend, "..." menu.
function M.draw_toolbar()
    if toggle_button(Settings.spellsDonMissingOnly and "Missing only: ON##sp_don_missing" or "Missing only: OFF##sp_don_missing", Settings.spellsDonMissingOnly == true) then
        Settings.spellsDonMissingOnly = not (Settings.spellsDonMissingOnly == true)
        SaveSettings()
    end
    ImGui.SameLine()
    theme.segmented_text({
        { text = "Owned", color = Theme.online or Theme.green },
        { text = " / ", color = Theme.dim },
        { text = "Missing", color = Theme.missing or Theme.brick },
        { text = " / ", color = Theme.dim },
        { text = "Unknown", color = Theme.dim },
    })
    ImGui.SameLine()
    if theme.themed_button("...##spells_don_more", Theme.blue) and ImGui.OpenPopup then
        ImGui.OpenPopup("##spells_don_more_menu")
    end
    if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
        ImGui.SetTooltip("Refresh / status key")
    end
    if ImGui.BeginPopup and ImGui.BeginPopup("##spells_don_more_menu") then
        if ImGui.MenuItem("Refresh now") then
            pcall(function()
                local bs = require('bis_search')
                if bs.request_via_bg then bs.request_via_bg("don", true) end
            end)
        end
        ImGui.Separator()
        col_text(status_color("known"), "Known = learned")
        col_text(status_color("ready"), "Ready = teaching item held")
        col_text(status_color("pack_owned"), "Pack = unopened pack held")
        col_text(status_color("missing"), "Missing")
        col_text(status_color("unknown"), "Unknown = no data yet")
        ImGui.EndPopup()
    end
end

function M.draw(column_keys)
    column_keys = column_keys or {}
    if #column_keys == 0 then
        col_text(Theme.amber, "No characters in this scope.")
        return
    end
    -- Same as the BiS tab: ask peers to answer the "don" list from their own
    -- spellbook (cooldown-gated in bis_search, so this is cheap per frame).
    pcall(function()
        local bs = require('bis_search')
        if bs.request_via_bg then bs.request_via_bg("don") end
    end)

    if #column_keys == 1 then
        center_cursor_block(COL_WIDTH)
    end

    local scroll_began = false
    local scroll_open = true
    if #column_keys > 1 and ImGui.BeginChild then
        local avail = content_avail_x()
        local block_h = HEADER_SLOT_H + COL_HEIGHT + 12.0
        local flags = (ImGuiWindowFlags and ImGuiWindowFlags.HorizontalScrollbar) or 0
        local ok, open = pcall(function()
            if ImVec2 then
                return ImGui.BeginChild("##spells_don_cols_scroll", ImVec2(avail, block_h), false, flags)
            end
            return ImGui.BeginChild("##spells_don_cols_scroll", avail, block_h, false, flags)
        end)
        if ok then
            scroll_began = true
            scroll_open = (open ~= false)
        end
    end

    if scroll_open then
        for i, key in ipairs(column_keys) do
            if i > 1 then ImGui.SameLine(0, 8) end
            draw_header(key)
        end
        if #column_keys == 1 then center_cursor_block(COL_WIDTH) end
        for i, key in ipairs(column_keys) do
            if i > 1 then ImGui.SameLine(0, 8) end
            local began, open = false, true
            if ImGui.BeginChild then
                local child_id = "##spells_don_col_" .. tostring(key):gsub("[^%w_]", "_")
                local ok, child_open = pcall(function()
                    if ImVec2 then return ImGui.BeginChild(child_id, ImVec2(COL_WIDTH, COL_HEIGHT), true, 0) end
                    return ImGui.BeginChild(child_id, COL_WIDTH, COL_HEIGHT, true, 0)
                end)
                if ok then
                    began = true
                    open = (child_open ~= false)
                end
            end
            if open then draw_column(key) end
            if began and ImGui.EndChild then ImGui.EndChild() end
        end
    end

    if scroll_began and ImGui.EndChild then ImGui.EndChild() end
end

return M
