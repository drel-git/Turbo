-- TurboGear/views.lua
-- Shared view utilities used by multiple tabs: the source render helpers and the
-- "Viewing:" selector. Lives between the data layer and the tabs so tabs depend
-- on this (not on the UI shell), keeping the require graph acyclic.

local ImGui = require('ImGui')
local mq    = require('mq')
local theme = require('theme')
local Theme, col_text, themed_button = theme.Theme, theme.col_text, theme.themed_button
local store = require('store')
local Store = store.Store
local Settings = require('config').Settings
local gather_self_snapshot = require('snapshot')
local snapshot = gather_self_snapshot
local Engine = require('engine').Engine
local item_actions = require('item_actions')
local roster_sets = require('roster_sets')

local M = {}

-- currently-selected source key for the shared selector ("__self__" or a peer
-- key). Exposed on the module so the Empty Slots tab can key its cache on it.
M.view_key = "__self__"

-- ===================== RENDER HELPERS ==================================== --
function M.index_equipped(snap)
    local map = {}
    if snap and snap.equipped then for _, it in ipairs(snap.equipped) do map[it.slotid] = it end end
    return map
end

function M.render_item_augs(item, list_id, context_prefix)
    if not item.augs or #item.augs == 0 then M.placeholder("No sockets"); return end
    context_prefix = tostring(context_prefix or "")
    local shown = 0
    for _, a in ipairs(item.augs) do
        if not M.aug_visible(a) then goto continue_aug end
        shown = shown + 1
        col_text(Theme.socket or Theme.dim, string.format("Slot %d (Type %d):", a.index, a.type)); ImGui.SameLine()
        if a.empty then
            col_text(Theme.emptySocket or Theme.gold, "Empty")
        else
            local color = a.unresolved and Theme.amber or (Theme.aug or Theme.green)
            local aug_opts = nil
            if list_id and a.loadoutEntryIndex then
                aug_opts = { loadoutListId = list_id, loadoutEntryIndex = a.loadoutEntryIndex }
            end
            local ctx_suffix = context_prefix .. "aug_" .. tostring(item.id or "") .. "_" .. tostring(a.index or "")
            item_actions.draw_name(a.name, color, ctx_suffix, a.id, aug_opts)
        end
        ::continue_aug::
    end
    if shown == 0 then M.placeholder("T20/30 hidden") end
end

local function status_color(s) return s == "online" and Theme.online or (s == "stale" and Theme.amber or Theme.offline) end
local function status_tag(s)   return s == "online" and "online" or (s == "stale" and "stale" or "offline") end
local function compare_status_tag(s) return s == "online" and "live" or (s == "stale" and "stale/cache" or "offline/cache") end
M.status_color = status_color
M.status_tag   = status_tag
M.compare_status_tag = compare_status_tag

local function tag_color(tag)
    tag = tostring(tag or "")
    if tag:find("live", 1, true) or tag:find("online", 1, true) then return Theme.online or Theme.green end
    if tag:find("stale", 1, true) then return Theme.amber or Theme.gold end
    return Theme.offline or Theme.dim
end

local function text_width(text)
    if not ImGui.CalcTextSize then return 0 end
    local ok, w = pcall(ImGui.CalcTextSize, tostring(text or ""))
    if not ok then return 0 end
    if type(w) == "table" then return tonumber(w.x or w[1]) or 0 end
    return tonumber(w) or 0
end
M.text_width = text_width

local function style_cell_padding_x()
    if ImGui.GetStyle then
        local ok, style = pcall(ImGui.GetStyle)
        if ok and style and style.CellPadding then
            local cp = style.CellPadding
            if type(cp) == "table" then return tonumber(cp.x or cp[1]) or 4.0 end
        end
        if ok and style and style.FramePadding then
            local fp = style.FramePadding
            if type(fp) == "table" then return tonumber(fp.x or fp[1]) or 4.0 end
        end
    end
    return 4.0
end

function M.current_column_width(fallback)
    if ImGui.GetColumnWidth then
        local ok, w = pcall(ImGui.GetColumnWidth)
        if ok then
            if type(w) == "table" then return tonumber(w.x or w[1]) or fallback end
            return tonumber(w) or fallback
        end
    end
    return fallback
end

function M.fit_text(text, max_width)
    text = tostring(text or "")
    max_width = tonumber(max_width) or 0
    if max_width <= 0 or text_width(text) <= max_width then return text, false end
    local ell = "..."
    local ell_w = text_width(ell)
    if ell_w >= max_width then return ell, true end
    local lo, hi, best = 0, #text, ""
    while lo <= hi do
        local mid = math.floor((lo + hi) * 0.5)
        local candidate = text:sub(1, mid)
        if text_width(candidate) + ell_w <= max_width then
            best = candidate
            lo = mid + 1
        else
            hi = mid - 1
        end
    end
    return best .. ell, true
end

function M.col_text_centered(color, text, col_width, y_offset)
    text = tostring(text or "")
    col_width = tonumber(col_width) or M.current_column_width()
    y_offset = tonumber(y_offset) or 0
    if col_width and col_width > 0 and ImGui.GetCursorPosX and ImGui.SetCursorPosX then
        local tw = text_width(text)
        if tw > 0 and tw < col_width then
            local ok, x = pcall(ImGui.GetCursorPosX)
            if ok and tonumber(x) then
                pcall(ImGui.SetCursorPosX, tonumber(x) + math.max(0, (col_width - tw) * 0.5))
            end
        end
    end
    col_text(color, text)
end

function M.col_text_fit(color, text, max_width)
    local width = tonumber(max_width) or M.current_column_width()
    if width and width > 0 then width = math.max(8.0, width - (style_cell_padding_x() * 2.0) - 2.0) end
    local shown, clipped = M.fit_text(text, width or 0)
    col_text(color, shown)
    return shown, clipped
end

function M.colored_text_fit(color, text, max_width)
    local width = tonumber(max_width) or M.current_column_width()
    if width and width > 0 then width = math.max(8.0, width - (style_cell_padding_x() * 2.0) - 2.0) end
    local shown, clipped = M.fit_text(text, width or 0)
    theme.colored_text(shown, color or Theme.item)
    return shown, clipped
end

function M.center_cursor_for_text(text, col_width)
    col_width = tonumber(col_width) or M.current_column_width()
    if not (col_width and col_width > 0 and ImGui.GetCursorPosX and ImGui.SetCursorPosX) then return end
    local tw = text_width(text)
    if tw <= 0 or tw >= col_width then return end
    local ok, x = pcall(ImGui.GetCursorPosX)
    if ok and tonumber(x) then
        pcall(ImGui.SetCursorPosX, tonumber(x) + math.max(0, (col_width - tw) * 0.5))
    end
end

function M.selectable_centered(label, id)
    label = tostring(label or "")
    M.center_cursor_for_text(label)
    return ImGui.Selectable(label .. tostring(id or ""), false)
end

function M.table_headers_centered(labels, colors)
    ImGui.TableNextRow()
    for i, label in ipairs(labels or {}) do
        ImGui.TableSetColumnIndex(i - 1)
        M.col_text_centered((colors and colors[i]) or Theme.header or Theme.item, label)
    end
end

local CLASS_ABBREV = {
    warrior = "WAR", war = "WAR", cleric = "CLR", clr = "CLR",
    paladin = "PAL", pal = "PAL", ranger = "RNG", rng = "RNG",
    shadowknight = "SHD", shadow = "SHD", shd = "SHD", sk = "SHD",
    druid = "DRU", dru = "DRU", monk = "MNK", mnk = "MNK",
    bard = "BRD", brd = "BRD", rogue = "ROG", rog = "ROG",
    shaman = "SHM", shm = "SHM", necromancer = "NEC", nec = "NEC",
    wizard = "WIZ", wiz = "WIZ", magician = "MAG", mage = "MAG", mag = "MAG",
    enchanter = "ENC", enc = "ENC", beastlord = "BST", bst = "BST",
    berserker = "BRS", ber = "BRS", brs = "BRS",
}

local CLASS_ROLE = {
    WAR = "tank", PAL = "tank", SHD = "tank",
    CLR = "healer", SHM = "healer", DRU = "healer",
    BRD = "utility", ENC = "utility",
    BRS = "melee", BST = "melee", MNK = "melee", RNG = "melee", ROG = "melee",
    MAG = "caster", NEC = "caster", WIZ = "caster",
}

local function clean_source_name(name)
    return tostring(name or ""):lower():gsub("%s+", ""):gsub("[^%w_]", "")
end

-- Role palette shared with LazBiS roster headers (vivid, distinct from slot gold).
local ROLE_COLORS = {
    tank    = { 0.58, 0.66, 0.76, 1.0 },
    healer  = { 0.431, 0.906, 0.718, 1.0 },
    melee   = { 0.992, 0.729, 0.455, 1.0 },
    caster  = { 0.753, 0.518, 0.988, 1.0 },
    utility = { 0.404, 0.910, 0.976, 1.0 },
}

local function norm_class(class_name)
    return tostring(class_name or ""):lower():gsub("%s+", ""):gsub("[^%w]", "")
end

local function self_class_name()
    local ok, cls = pcall(function()
        if mq.TLO.Me and mq.TLO.Me.Class and mq.TLO.Me.Class.ShortName then return mq.TLO.Me.Class.ShortName() end
        return nil
    end)
    if ok and cls and cls ~= "" then return cls end
    ok, cls = pcall(function() return mq.TLO.Me.Class() end)
    return ok and cls or ""
end

function M.class_abbrev(class_name)
    local raw = tostring(class_name or "")
    local key = norm_class(raw)
    if CLASS_ABBREV[key] then return CLASS_ABBREV[key] end
    if #raw <= 4 then return raw:upper() end
    return raw:sub(1, 3):upper()
end

function M.class_role(class_name)
    return CLASS_ROLE[M.class_abbrev(class_name)]
end

function M.class_color(class_name)
    local role = M.class_role(class_name)
    if role and ROLE_COLORS[role] then return ROLE_COLORS[role] end
    return Theme.header or Theme.item
end

function M.role_color_from_abbrev(abbrev)
    local role = CLASS_ROLE[tostring(abbrev or ""):upper()]
    if role and ROLE_COLORS[role] then return ROLE_COLORS[role] end
    return Theme.header or Theme.item
end

function M.draw_class_abbrevs(class_str)
    class_str = tostring(class_str or "")
    if class_str == "" then
        ImGui.TextDisabled("-")
        return
    end
    -- Draw-list only: segmented_text uses ImGui.Dummy, which breaks inside tables.
    if ImGui.GetWindowDrawList and ImGui.GetCursorScreenPos and ImGui.CalcTextSize and theme.color_u32 then
        local x, y = ImGui.GetCursorScreenPos()
        local draw = ImGui.GetWindowDrawList()
        local cx = x
        local first = true
        for abbrev in class_str:gmatch("[^,%s]+") do
            if not first then
                local sep = ", "
                draw:AddText(ImVec2(cx, y), theme.color_u32(Theme.dim), sep)
                local sw = ImGui.CalcTextSize(sep)
                if type(sw) == "table" then sw = sw.x or sw[1] end
                cx = cx + (tonumber(sw) or 0)
            end
            draw:AddText(ImVec2(cx, y), theme.color_u32(M.role_color_from_abbrev(abbrev)), abbrev)
            local aw = ImGui.CalcTextSize(abbrev)
            if type(aw) == "table" then aw = aw.x or aw[1] end
            cx = cx + (tonumber(aw) or 0)
            first = false
        end
        return
    end
    ImGui.Text(class_str)
end

function M.owner_label(row)
    row = row or {}
    local cls = M.class_abbrev(row.ownerClass or "")
    if cls and cls ~= "" then return string.format("%s (%s)", row.owner or "?", cls) end
    return row.owner or "?"
end

function M.draw_owner_cell(row)
    col_text(M.class_color(row and row.ownerClass), M.owner_label(row))
end

local function source_parts(key)
    if key == "__self__" then
        return tostring(mq.TLO.Me.CleanName() or "Self"), self_class_name(), "live"
    end
    local ok_loadout, loadout = pcall(require, 'loadout')
    if ok_loadout and loadout and loadout.is_list_key and loadout.is_list_key(key) then
        local list = loadout.get_list(key)
        if list then return "List: " .. tostring(list.name or list.id), list.class or "", "loadout" end
        return tostring(key or "?"), "", "loadout"
    end
    local s = Store.get(key)
    if not s then return tostring(key or "?"), "", "offline/cache" end
    local actor_seen = tonumber(s.actorSeenAt) or 0
    local actor_live = actor_seen > 0 and (os.time() - actor_seen) <= 45
    local tag
    if s.status == "online" and actor_live then
        tag = "live"
    elseif s.status == "online" then
        tag = "visible"
    else
        tag = s.status == "stale" and "stale" or "offline"
    end
    return s.name or key, s.class or "", tag
end

local function source_label_with_class(key, compare_mode)
    local name, class_name, tag = source_parts(key)
    if compare_mode and tag == "offline" then tag = "offline/cache" end
    local cls = M.class_abbrev(class_name)
    if cls and cls ~= "" then return string.format("%s (%s) [%s]", name, cls, tag) end
    return string.format("%s [%s]", name, tag)
end

local function state_age_label(seconds)
    seconds = tonumber(seconds) or 0
    if seconds < 0 then seconds = 0 end
    if seconds < 90 then return tostring(math.floor(seconds)) .. "s" end
    if seconds < 5400 then return tostring(math.floor(seconds / 60)) .. "m" end
    return tostring(math.floor(seconds / 3600)) .. "h"
end

local function source_inventory_stamp(s)
    return tonumber(s and s.inventoryUpdated) or tonumber(s and s.updated) or 0
end

local function source_rank(s)
    if type(s) ~= "table" then return -1, 0 end
    local now = os.time()
    local actor_seen = tonumber(s.actorSeenAt) or 0
    local inv_seen = source_inventory_stamp(s)
    local actor_live = actor_seen > 0 and (now - actor_seen) <= 45 and tostring(s.status or "") == "online"
    local inv_fresh = inv_seen > 0 and (now - inv_seen) <= 300 and tostring(s.depth or "") == "full"
    if actor_live and inv_fresh then return 400, inv_seen end
    if actor_live then return 300, inv_seen end
    if tostring(s.status or "") == "online" then return 200, inv_seen end
    if tostring(s.status or "") == "stale" then return 100, inv_seen end
    return 0, inv_seen
end

local function freshest_matching_source_key(key)
    if key == "__self__" then return key end
    local current = Store.get(key)
    if not current then return nil end
    local want = clean_source_name(current.name or key)
    if want == "" then return key end
    local best_key, best_rank, best_stamp = key, source_rank(current)
    for _, peer_key in ipairs(Store.peer_keys()) do
        local snap = Store.get(peer_key)
        if snap and clean_source_name(snap.name or peer_key) == want then
            local rank, stamp = source_rank(snap)
            if rank > best_rank or (rank == best_rank and stamp > best_stamp) then
                best_key, best_rank, best_stamp = peer_key, rank, stamp
            end
        end
    end
    return best_key
end

function M.source_state(key)
    if key == "__self__" then
        local snap = M.source_snapshot("__self__")
        local updated = source_inventory_stamp(snap)
        return {
            tag = "live",
            responder = "local UI",
            actorLive = true,
            inventoryFresh = updated > 0 and (os.time() - updated) <= 300,
            inventoryAge = updated > 0 and math.max(0, os.time() - updated) or nil,
            itemCount = #(snap and snap.equipped or {}) + #(snap and snap.bags or {}) + #(snap and snap.bank or {}),
            depth = snap and snap.depth or "",
        }
    end
    local s = Store.get(key)
    if not s then return { tag = "missing", responder = "no source", actorLive = false } end
    local actor_seen = tonumber(s.actorSeenAt) or 0
    local discovery_seen = tonumber(s.discoverySeenAt) or 0
    local updated = source_inventory_stamp(s)
    local bank_captured = tonumber(s.bankCapturedAt) or 0
    local actor_age = actor_seen > 0 and math.max(0, os.time() - actor_seen) or nil
    local inv_age = updated > 0 and math.max(0, os.time() - updated) or nil
    local actor_live = actor_age ~= nil and actor_age <= 45 and tostring(s.status or "") == "online"
    local inventory_fresh = inv_age ~= nil and inv_age <= 300 and tostring(s.depth or "") == "full"
    local tag
    if actor_live and inventory_fresh then tag = "live"
    elseif actor_live then tag = "live/stale inventory"
    elseif tostring(s.status or "") == "online" and discovery_seen > 0 then tag = "visible"
    elseif tostring(s.status or "") == "stale" then tag = "stale/cache"
    else tag = "offline/cache" end
    local responder = actor_live and ("actor " .. state_age_label(actor_age) .. " ago")
        or (discovery_seen > 0 and ("client seen " .. state_age_label(math.max(0, os.time() - discovery_seen)) .. " ago") or "not answering")
    return {
        tag = tag,
        responder = responder,
        actorLive = actor_live,
        actorAge = actor_age,
        inventoryFresh = inventory_fresh,
        inventoryAge = inv_age,
        itemCount = #(s.equipped or {}) + #(s.bags or {}) + #(s.bank or {}),
        depth = s.depth or "",
        status = s.status or "",
        bankAge = bank_captured > 0 and math.max(0, os.time() - bank_captured) or nil,
    }
end

function M.aug_visible(a)
    if not a then return false end
    local t = tonumber(a.type) or 0
    if Settings.hideOrnament and (t == 20 or t == 30) then return false end
    return true
end

local function age_label(seconds)
    seconds = tonumber(seconds) or 0
    if seconds < 0 then seconds = 0 end
    if seconds < 90 then return tostring(math.floor(seconds)) .. "s ago" end
    if seconds < 5400 then return tostring(math.floor(seconds / 60)) .. "m ago" end
    return tostring(math.floor(seconds / 3600)) .. "h ago"
end

local function latest_peer_seen()
    local latest = nil
    for _, key in ipairs(Store.peer_keys()) do
        local s = Store.get(key)
        if s and s.last_seen and s.last_seen > 0 and (not latest or s.last_seen > latest) then
            latest = s.last_seen
        end
    end
    return latest
end

function M.source_keys(include_self)
    local keys = {}
    if include_self ~= false then keys[#keys+1] = "__self__" end
    for _, k in ipairs(Store.peer_keys()) do keys[#keys+1] = k end
    return keys
end

function M.source_label(key)
    return source_label_with_class(M.validate_source_key(key), false)
end

function M.source_owner_name(key)
    local name = source_parts(M.validate_source_key(key or "__self__"))
    return tostring(name or "")
end

function M.roster_column_label(key)
    return source_label_with_class(M.validate_source_key(key), false)
end

function M.compare_source_label(key)
    return source_label_with_class(M.validate_source_key(key), true)
end

function M.source_header_color(key)
    local _, class_name = source_parts(key)
    return M.class_color(class_name)
end

function M.source_header_parts(key, compare_mode)
    local name, class_name, tag = source_parts(key)
    if compare_mode and tag == "offline" then tag = "offline/cache" end
    if compare_mode and tag == "stale" then tag = "stale/cache" end
    return name, M.class_abbrev(class_name), tag, M.class_color(class_name), tag_color(tag)
end

local function table_next_section_row()
    local ok = false
    if ImGui.TableNextRow then ok = pcall(ImGui.TableNextRow, 0, 22.0) end
    if not ok then ImGui.TableNextRow() end
end

function M.draw_section_row(label, cols)
    table_next_section_row()
    if ImGui.TableSetBgColor and ImGuiTableBgTarget and ImGuiTableBgTarget.RowBg0 and theme.color_u32 then
        pcall(ImGui.TableSetBgColor, ImGuiTableBgTarget.RowBg0, theme.color_u32(Theme.sectionBg or Theme.steel))
    end
    ImGui.TableSetColumnIndex(0)
    col_text(Theme.category or Theme.section or Theme.cyan, tostring(label or ""))
    for c = 1, (cols or 1) - 1 do
        ImGui.TableSetColumnIndex(c)
        ImGui.TextDisabled("")
    end
end

function M.draw_roster_header_row(first_label, keys)
    ImGui.TableNextRow()
    ImGui.TableSetColumnIndex(0)
    M.col_text_centered(Theme.header or Theme.item, tostring(first_label or "Slot"), M.current_column_width())
    for cidx, key in ipairs(keys or {}) do
        ImGui.TableSetColumnIndex(cidx)
        local name, cls, tag, role_color, state_color = M.source_header_parts(key, false)
        local label = cls and cls ~= "" and string.format("%s (%s)", name, cls) or tostring(name or "?")
        M.col_text_centered(role_color, label, M.current_column_width())
        M.col_text_centered(state_color, "[" .. tostring(tag or "offline") .. "]", M.current_column_width())
    end
end

function M.draw_compare_header_row(key1, key2)
    local function cell(col, key, suffix)
        local name, cls, tag, role_color = M.source_header_parts(key, true)
        local label = cls and cls ~= "" and string.format("%s (%s) [%s]", name, cls, tag) or string.format("%s [%s]", name or "?", tag)
        ImGui.TableSetColumnIndex(col)
        M.col_text_centered(role_color, label, M.current_column_width())
        M.col_text_centered(Theme.header or Theme.item, suffix, M.current_column_width())
    end
    ImGui.TableNextRow()
    ImGui.TableSetColumnIndex(0)
    M.col_text_centered(Theme.header or Theme.item, "Slot", M.current_column_width())
    cell(1, key1, "Item")
    cell(2, key1, "Augs")
    cell(3, key2, "Item")
    cell(4, key2, "Augs")
end

function M.draw_column_context(view_label, keys)
    if not keys or #keys == 0 then return end
    local parts = {}
    for _, key in ipairs(keys) do
        local label = M.roster_column_label(key):gsub("%s*%[[^%]]+%]", "")
        parts[#parts+1] = label
    end
    col_text(Theme.dim, string.format("%s columns: %s", tostring(view_label or "Visible"), table.concat(parts, " | ")))
end

function M.placeholder(text)
    col_text(Theme.placeholder or Theme.dim, tostring(text or "-"))
end

function M.blank_cell()
    ImGui.TextDisabled("")
end

function M.draw_status_strip(view_label)
    if ImGui.NewLine then ImGui.NewLine() end
    local on, st, off = Store.counts()
    local latest = latest_peer_seen()
    local sync = latest and age_label(os.time() - latest) or "never"
    local text = string.format("%s View | %d online | %d stale | %d offline | Last sync: %s",
        tostring(view_label or "Current"), on, st, off, sync)
    col_text(Theme.dim, text)
end

-- Scrollable tables need an explicit size for TableSetupScrollFreeze to keep
-- header rows visible. Keep the BeginTable signature detection cached so we do
-- not pay pcall cost every frame.
local table_begin_modes = {}

local function vec_component(vec, field, index)
    if vec == nil then return nil end
    if type(vec) == "table" then return tonumber(vec[field] or vec[index]) end
    local ok, value = pcall(function() return vec[field] end)
    if ok then return tonumber(value) end
    return nil
end

function M.content_avail()
    if not ImGui.GetContentRegionAvail then return nil, nil end
    local a, b = ImGui.GetContentRegionAvail()
    local ax, ay = vec_component(a, "x", 1), vec_component(a, "y", 2)
    if ax or ay then
        return ax, ay
    end
    return tonumber(a), tonumber(b)
end

function M.scroll_table_flags(extra)
    local flags = ImGuiTableFlags.Borders + ImGuiTableFlags.RowBg + ImGuiTableFlags.Resizable + (extra or 0)
    if ImGuiTableFlags.ScrollY then flags = flags + ImGuiTableFlags.ScrollY end
    return flags
end

function M.begin_scroll_table(id, col_count, flags, reserve_h, min_h, fixed_h)
    local avail_w, avail_h = M.content_avail()
    local width = math.max(320.0, avail_w or 0.0)
    local height = tonumber(fixed_h)
        or math.max(min_h or 220.0, (avail_h or 520.0) - (reserve_h or 8.0))
    local mode = table_begin_modes[id]

    if mode == "numeric" then
        return ImGui.BeginTable(id, col_count, flags, width, height)
    elseif mode == "vec" then
        return ImGui.BeginTable(id, col_count, flags, ImVec2(width, height))
    elseif mode == "plain" then
        return ImGui.BeginTable(id, col_count, flags - (ImGuiTableFlags.ScrollY or 0))
    end

    local ok, open = pcall(function()
        return ImGui.BeginTable(id, col_count, flags, width, height)
    end)
    if ok then table_begin_modes[id] = "numeric"; return open end

    local ok_vec, open_vec = pcall(function()
        return ImGui.BeginTable(id, col_count, flags, ImVec2(width, height))
    end)
    if ok_vec then table_begin_modes[id] = "vec"; return open_vec end

    table_begin_modes[id] = "plain"
    return ImGui.BeginTable(id, col_count, flags - (ImGuiTableFlags.ScrollY or 0))
end

function M.table_scroll_active(table_id)
    local mode = table_begin_modes[table_id]
    return mode == "numeric" or mode == "vec"
end

-- ScrollFreeze without ScrollY breaks this MQ ImGui binding (Missing End() crash).
function M.setup_scroll_freeze(table_id, frozen_cols, frozen_rows)
    if not M.table_scroll_active(table_id) then return end
    if ImGui.TableSetupScrollFreeze then
        pcall(ImGui.TableSetupScrollFreeze, frozen_cols or 0, frozen_rows or 1)
    end
end

function M.source_snapshot(key)
    key = M.validate_source_key(key or "__self__")
    if key == "__self__" then
        local depth = snapshot.depth_for_settings()
        local cached = snapshot.cached()
        if cached and (depth == "lite" or cached.depth == "full") then
            return cached, true, "Self"
        end
        return snapshot.gather({ force = false, depth = depth }), true, "Self"
    end
    local ok_loadout, loadout = pcall(require, 'loadout')
    if ok_loadout and loadout and loadout.is_list_key and loadout.is_list_key(key) then
        local snap = loadout.build_snapshot(loadout.list_id_from_key(key))
        return snap, false, snap and snap.name or "?"
    end
    local s = Store.get(key)
    return s, false, (s and s.name or "?")
end

function M.validate_source_key(key)
    if key == "__self__" then return key end
    local fresh_key = freshest_matching_source_key(key)
    if fresh_key then return fresh_key end
    if Store.get(key) then return key end
    local ok_loadout, loadout = pcall(require, 'loadout')
    if ok_loadout and loadout and loadout.is_list_key and loadout.is_list_key(key) then
        if loadout.get_list(loadout.list_id_from_key(key)) then return key end
    end
    return "__self__"
end

function M.clean_name(name)
    return clean_source_name(name)
end

function M.e3_connected_names()
    local out = {}
    local ok, peers = pcall(function()
        if mq.TLO.MQ2Mono and mq.TLO.MQ2Mono.Query then return mq.TLO.MQ2Mono.Query("e3,E3Bots.ConnectedClients")() end
        return nil
    end)
    if ok and type(peers) == "string" then
        for peer in peers:gmatch("([^,]+)") do
            local name = tostring(peer or ""):match("^%s*(.-)%s*$") or ""
            name = name:match("^[%w_]+") or name
            if name ~= "" then out[M.clean_name(name)] = true end
        end
    end
    out[M.clean_name(mq.TLO.Me.CleanName() or "")] = true
    return out
end

function M.is_group_member(name)
    if M.clean_name(name) == M.clean_name(mq.TLO.Me.CleanName() or "") then return true end
    local ok, result = pcall(function()
        return mq.TLO.Group and mq.TLO.Group.Member and mq.TLO.Group.Member(name)()
    end)
    return ok and result and true or false
end

function M.scoped_source_keys(scope, opts)
    return roster_sets.source_keys(scope or "online", opts)
end

function M.draw_source_picker(id, key, width)
    key = M.validate_source_key(key or "__self__")
    local stable_id = tostring(id or "source"):gsub("#", "")
    ImGui.SetNextItemWidth(width or 240.0)
    if ImGui.BeginCombo(id, M.source_label(key)) then
        if ImGui.Selectable(M.source_label("__self__") .. "##" .. stable_id .. "_self", key == "__self__") then key = "__self__" end
        for _, k in ipairs(Store.peer_keys()) do
            local label = string.format("%s##%s_%s", M.source_label(k), stable_id, k)
            if ImGui.Selectable(label, key == k) then key = k end
        end
        ImGui.EndCombo()
    end
    return key
end

-- ===================== SHARED VIEW SELECTOR ============================== --
function M.draw_view_selector()
    local st = require('state')
    if Settings.autoPeerRefresh == true and not (st.lean and st.lean()) then
        Engine.request_all(false)
    end

    ImGui.Text("Viewing:"); ImGui.SameLine()
    M.view_key = M.draw_source_picker("##ViewSel", M.view_key, 240.0)

    M.draw_status_strip("Current")

    return M.source_snapshot(M.view_key)
end

return M
