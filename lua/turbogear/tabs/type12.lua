-- TurboGear/tabs/type12.lua
-- Combined Type 12 planning view: compact ownership matrix plus source-item reference.

local ImGui = require('ImGui')
local theme = require('theme')
local Theme, col_text = theme.Theme, theme.col_text
local views = require('views')
local characters = require('characters')
local type12_matrix = require('type12_matrix')
local item_actions = require('item_actions')

local ok_ref, dsk_ref = pcall(require, 'references.dsk_type12_focus')
if not ok_ref or type(dsk_ref) ~= "table" then dsk_ref = {} end

local M = {}

local search_text = ""

local function lower(s)
    return tostring(s or ""):lower()
end

local function input_text_hint(id, hint, value)
    if ImGui.InputTextWithHint then
        local ok, rv = pcall(ImGui.InputTextWithHint, id, hint, value or "")
        if ok then return rv or "" end
    end
    return ImGui.InputText(id, value or "") or ""
end

local function row_matches(row, q)
    if q == "" then return true end
    local hay = {
        row.category,
        row.focus,
        row.effect,
        row.item,
    }
    if type(row.items) == "table" then
        for _, item in ipairs(row.items) do
            if type(item) == "table" then
                hay[#hay + 1] = item.name
                hay[#hay + 1] = item.slot
                hay[#hay + 1] = item.source
            else
                hay[#hay + 1] = item
            end
        end
    end
    for _, s in ipairs(hay) do
        if lower(s):find(q, 1, true) then return true end
    end
    return false
end

local function draw_item_source(item, idx)
    local item_name = type(item) == "table" and item.name or item
    local item_slot = type(item) == "table" and item.slot or nil
    local item_source = type(item) == "table" and item.source or nil

    col_text(Theme.dim, "  -")
    ImGui.SameLine()
    item_actions.draw_name(
        tostring(item_name or "?"),
        Theme.item,
        "type12_source_item_" .. tostring(idx),
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

local function draw_focus_record(row, idx)
    if not row then return end
    theme.colored_text(tostring(row.focus or row.effect or "?"), Theme.purple or Theme.header)
    if row.effect and row.focus then
        ImGui.SameLine()
        col_text(Theme.dim, " - " .. tostring(row.effect))
    end

    if type(row.items) == "table" then
        for j, item in ipairs(row.items) do
            draw_item_source(item, tostring(idx) .. "_" .. tostring(j))
        end
    elseif row.item then
        draw_item_source(row.item, tostring(idx))
    end
end

local function draw_reference()
    col_text(Theme.header or Theme.item, "Anguish source items")

    ImGui.SetNextItemWidth(320.0)
    local next_search = input_text_hint("##type12_source_search", "Search focus, effect, item, source...", search_text)
    if next_search ~= search_text then search_text = tostring(next_search or "") end
    if search_text ~= "" then
        ImGui.SameLine()
        if theme.themed_button("Clear##type12_source_search_clear", Theme.steel, 60, 22) then
            search_text = ""
        end
    end

    local q = lower(search_text):match("^%s*(.-)%s*$") or ""
    local current_category = nil
    local shown = 0

    for i, row in ipairs(dsk_ref) do
        if row_matches(row, q) then
            if tostring(row.category or "") ~= tostring(current_category or "") then
                current_category = row.category
                ImGui.Spacing()
                col_text(Theme.section or Theme.header or Theme.item, tostring(current_category or "Other"))
            end
            shown = shown + 1
            draw_focus_record(row, i)
        end
    end

    if shown == 0 then
        col_text(Theme.dim, "No Type 12 source rows matched the search.")
    end
end

function M.draw()
    local keys = characters.active_keys("type12")
    type12_matrix.draw(keys, {
        id = "Type12FocusMatrix",
        height = 382.0,
        show_legend = false,
    })

    ImGui.Spacing()
    ImGui.Separator()
    ImGui.Spacing()
    draw_reference()
end

return M
