-- TurboGear/type12_matrix.lua
-- Demand-loaded UI helper for the compact Type 12 Augs fleet matrix.
-- It reads existing focusitems catalog rows and cached snapshots only.

local ImGui = require('ImGui')
local theme = require('theme')
local Theme, col_text = theme.Theme, theme.col_text
local cfg = require('config')
local Settings = cfg.Settings
local views = require('views')
local Store = require('store').Store
local snapshot_mod = require('snapshot')
local bis = require('bis')
local ownership_index = require('ownership_index')
local type12 = require('type12_ownership')

local M = {}

local cache = { key = nil, rows = nil, keys = nil }
local DSK_SOURCE_COLOR = { 0.62, 0.58, 0.92, 1.00 }

local function trim(s)
    return tostring(s or ""):match("^%s*(.-)%s*$") or ""
end

local function table_col_text_centered(color, text)
    local w = ImGui.GetColumnWidth and ImGui.GetColumnWidth() or nil
    if type(w) == "table" then w = tonumber(w.x or w[1]) end
    views.col_text_centered(color, text, tonumber(w))
end

local function snap_for_key(key)
    if key == "__self__" then
        local my_key = Store.my_key and Store.my_key() or nil
        return snapshot_mod.cached() or (my_key and Store.get(my_key)) or views.source_snapshot(key)
    end
    return Store.get(key) or views.source_snapshot(key)
end

-- Cells resolve against the snapshot's ownership index, so that index's own
-- semantic cache key is the invalidation signal (item/aug contents, bank
-- validity, spells — not publication freshness, DoN/lockouts, or Store's
-- broad content signature).
local function source_token(key)
    local snap = snap_for_key(key)
    if not snap then return "0" end
    return ownership_index.snapshot_cache_key(snap)
end

local function live_gen()
    local gen = 0
    pcall(function()
        if bis.live_ownership_gen then gen = tonumber(bis.live_ownership_gen()) or 0 end
    end)
    return gen
end

-- Peer cells resolve through the bis_search FindItem map, so a new map has to
-- invalidate the matrix the same way it invalidates the BiS roster.
local function bis_search_gen()
    local ver = 0
    pcall(function()
        local bs = require('bis_search')
        if bs.reload_if_changed then bs.reload_if_changed() end
        ver = tonumber(bs.version and bs.version()) or 0
    end)
    return ver
end

-- The FindItem map is only needed for keys we cannot evaluate locally at all.
-- With aug data present in every snapshot (lite gathers included) that is rare,
-- so the fleet sweep stays off instead of running on a standing 12s timer.
-- Whether any key is blind is recorded during the rebuild, so the common case
-- costs one boolean per frame.
local function request_source_maps()
    local sent = false
    pcall(function()
        local bs = require('bis_search')
        if not bs.request_via_bg then return end
        sent = bs.request_via_bg("don") or bs.request_via_bg("dsk") or false
    end)
    return sent
end

local function cache_key(keys)
    local parts = {
        "type12",
        tostring(Settings.bisShowMissingOnly == true),
        "lg" .. tostring(live_gen()),
        "bs" .. tostring(bis_search_gen()),
    }
    for _, key in ipairs(keys or {}) do
        parts[#parts + 1] = tostring(key) .. ":" .. source_token(key)
    end
    return table.concat(parts, "|")
end

local function effect_color(effect)
    local s = trim(effect):lower()
    if s:find("adept", 1, true) or s:find("guard", 1, true)
        or s:find("nimble", 1, true) or s:find("elusion", 1, true)
        or s:find("dodge", 1, true) or s:find("block", 1, true)
        or s:find("parry", 1, true) then
        return Theme.cold or Theme.blue or Theme.slot
    end
    if s:find("benevolent", 1, true) or s:find("beneficial", 1, true)
        or s:find("companion", 1, true) or s:find("mercy", 1, true)
        or s:find("reach", 1, true) then
        return Theme.cyan or Theme.utility or Theme.item
    end
    if s:find("malevolent", 1, true) or s:find("detrimental", 1, true)
        or s:find("mental", 1, true) then
        return Theme.purple or Theme.magic or Theme.slot
    end
    if s:find("chilling", 1, true) or s:find("ice", 1, true) or s:find("cold", 1, true) then
        return Theme.cold or Theme.blue or Theme.item
    end
    if s:find("fiery", 1, true) or s:find("fire", 1, true) then
        return Theme.fire or Theme.melee or Theme.gold
    end
    if s:find("noxious", 1, true) or s:find("poison", 1, true) then
        return Theme.poison or Theme.green
    end
    if s:find("festering", 1, true) or s:find("disease", 1, true) then
        return Theme.disease or Theme.slot
    end
    if s:find("arcane", 1, true) or s:find("magic", 1, true) then
        return Theme.magic or Theme.purple
    end
    if s:find("merciful", 1, true) or s:find("mending", 1, true)
        or s:find("healing", 1, true) then
        return Theme.green or Theme.healer
    end
    if s:find("physical", 1, true) or s:find("lethal", 1, true)
        or s:find("visceral", 1, true) or s:find("wanton", 1, true)
        or s:find("cleave", 1, true) or s:find("double attack", 1, true)
        or s:find("barrage", 1, true) or s:find("malice", 1, true)
        or s:find("assault", 1, true) or s:find("ranged", 1, true)
        or s:find("archery", 1, true) or s:find("throwing", 1, true) then
        return Theme.melee or Theme.gold or Theme.amber
    end
    return Theme.slot or Theme.dim
end

local function source_color(source)
    if source == "DoN" then return Theme.green or Theme.haveWorn end
    if source == "DSK" then return DSK_SOURCE_COLOR end
    return Theme.dim
end

local function nonempty(v)
    local s = trim(v)
    if s ~= "" and s ~= "nil" then return s end
    return nil
end

local function match_item_name(match, fallback)
    if type(match) == "table" then
        return nonempty(match.name)
            or nonempty(match.item)
            or nonempty(match.item_name)
            or fallback
    end
    return nonempty(match) or fallback
end

local function match_location(match)
    if type(match) ~= "table" then return nil end
    local slotname = nonempty(match.slotname)
    if slotname then return slotname end
    local loc = nonempty(match.location)
    local where = nonempty(match.where)
    if loc and where and loc:lower() ~= where:lower() then
        return loc .. " - " .. where
    end
    return loc or where
end

local function source_tooltip(cell)
    local source = tostring((cell and cell.text) or "")
    local item = match_item_name(cell and cell.match, source .. " Type 12 aug")
    local loc = match_location(cell and cell.match)
    if loc then
        return string.format("Found '%s' in slot (%s)", item, loc)
    end
    return string.format("Found '%s'", item)
end

local function draw_cell_divider()
    if not (ImGui.GetWindowDrawList and ImGui.GetItemRectMin and ImGui.GetItemRectMax and theme.color_u32) then
        return
    end
    local min, max = ImGui.GetItemRectMin(), ImGui.GetItemRectMax()
    if type(min) ~= "table" or type(max) ~= "table" then return end
    local x1, y = tonumber(min.x or min[1]), tonumber(max.y or max[2])
    local x2 = tonumber(max.x or max[1])
    if not x1 or not x2 or not y then return end
    local c = Theme.sectionBg or Theme.placeholder or Theme.dim
    local draw = ImGui.GetWindowDrawList()
    if draw and draw.AddLine then
        draw:AddLine(ImVec2(x1, y + 1), ImVec2(x2, y + 1), theme.color_u32(c), 1.0)
    end
end

local function build(keys)
    local rows = {}
    local snaps, blind = {}, false
    for _, key in ipairs(keys or {}) do
        local snap = snap_for_key(key)
        snaps[key] = snap
        if not snap then blind = true end
    end
    for _, spec in ipairs(type12.rows()) do
        local cells = {}
        local applicable, all_don = 0, true
        for _, key in ipairs(keys or {}) do
            local snap = snaps[key]
            local status = type12.classify(snap, spec, { key = key })
            local cell = {
                text = status.source or "-",
                color = source_color(status.source),
                applicable = status.applicable == true,
                via = status.via,
                slot = status.slot,
                match = status.match,
            }
            cells[key] = cell
            if cell.applicable then
                applicable = applicable + 1
                if cell.text ~= "DoN" then all_don = false end
            end
        end
        if not (Settings.bisShowMissingOnly == true and applicable > 0 and all_don) then
            rows[#rows + 1] = {
                effect = spec.effect,
                label = spec.display or spec.effect,
                divider_after = spec.divider_after == true,
                cells = cells,
            }
        end
    end
    return rows, blind
end

local function ensure(keys)
    local key = cache_key(keys)
    if cache.key ~= key then
        local rows, blind = build(keys)
        cache = { key = key, rows = rows, keys = keys, blind = blind }
    end
    return cache.rows or {}
end

local function cell_tooltip(cell, snap)
    if not (ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip) then return end
    local name = snap and snap.name or "?"
    if cell.text == "DoN" then
        ImGui.SetTooltip(source_tooltip(cell))
    elseif cell.text == "DSK" then
        ImGui.SetTooltip(source_tooltip(cell))
    elseif cell.applicable then
        ImGui.SetTooltip(tostring(name) .. " is missing this Type 12 aug.")
    else
        ImGui.SetTooltip("No applicable focus row for this character/class.")
    end
end

function M.draw(keys, opts)
    opts = type(opts) == "table" and opts or {}
    keys = type(keys) == "table" and keys or {}
    local rows = ensure(keys)
    if cache.blind then request_source_maps() end
    if #rows == 0 then
        col_text(Theme.dim, "No Type 12 Aug rows matched this view.")
        return
    end

    local cols = 1 + #keys
    local flags = views.scroll_table_flags(0)
    if ImGuiTableFlags then
        flags = flags + (ImGuiTableFlags.ScrollX or 0) + (ImGuiTableFlags.ScrollY or 0)
    end
    if views.begin_scroll_table(
        opts.id or "Type12AugsMatrix",
        cols,
        flags,
        tonumber(opts.reserve_h) or 52.0,
        tonumber(opts.min_h) or 220.0,
        tonumber(opts.height)
    ) then
        local ok, err = pcall(function()
            ImGui.TableSetupColumn("Effect", ImGuiTableColumnFlags.WidthFixed, 210.0)
            for _, key in ipairs(keys) do
                local snap = snap_for_key(key)
                ImGui.TableSetupColumn(tostring((snap and snap.name) or views.source_label(key) or key), ImGuiTableColumnFlags.WidthFixed, 86.0)
            end
            views.setup_scroll_freeze(opts.id or "Type12AugsMatrix", 1, 1)
            ImGui.TableNextRow()
            ImGui.TableSetColumnIndex(0)
            col_text(Theme.header or Theme.item, "Effect")
            for cidx, key in ipairs(keys) do
                ImGui.TableSetColumnIndex(cidx)
                local snap = snap_for_key(key)
                table_col_text_centered(views.class_color(snap and snap.class), tostring((snap and snap.name) or views.source_label(key) or "?"))
            end
            for _, row in ipairs(rows) do
                ImGui.TableNextRow()
                ImGui.TableSetColumnIndex(0)
                col_text(effect_color(row.effect), row.label or row.effect)
                if row.divider_after then draw_cell_divider() end
                for cidx, key in ipairs(keys) do
                    ImGui.TableSetColumnIndex(cidx)
                    local snap = snap_for_key(key)
                    local cell = row.cells[key] or { text = "-", color = Theme.dim }
                    table_col_text_centered(cell.color or Theme.dim, cell.text or "-")
                    if row.divider_after then draw_cell_divider() end
                    cell_tooltip(cell, snap)
                end
            end
        end)
        ImGui.EndTable()
        if not ok then col_text(Theme.amber or Theme.gold, "Type 12 matrix error: " .. tostring(err)) end
    end
    if opts.show_legend ~= false then
        col_text(Theme.dim, "DoN = best Type 12 aug owned. DSK = DSK aug owned but DoN missing. - = missing or not applicable.")
    end
end

function M.invalidate()
    cache.key = nil
end

return M
