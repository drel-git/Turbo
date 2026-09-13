-- TurboGear/tabs/wallet.lua
-- Passive in-game currency roster. Reads cached wallet fields from Store; only
-- refreshes local wallet data on tab entry or an explicit button click.

local ImGui = require('ImGui')

local theme = require('theme')
local Theme, col_text = theme.Theme, theme.col_text
local themed_button = theme.themed_button

local mq = require('mq')
local cfg = require('config')
local characters = require('characters')
local diag = require('diagnostics')
local store_mod = require('store')
local transport = require('turbo_lib.transport')
local Store = store_mod.Store

local M = {}

local last_refresh_at = 0
local last_manual_refresh_at = 0
local last_auto_refresh_at = 0
local status_msg = ""
local status_until = 0
local MANUAL_REFRESH_COOLDOWN_S = 4.0
local AUTO_REFRESH_COOLDOWN_S = 60.0
local SIDECAR_CHECK_INTERVAL_S = 1.0
local visible_row_diag_sig = {}
local auto_refresh_pending = false
local auto_refresh_done = false
local sidecar_next_check_at = 0
local sidecar_sig = nil
local sidecar_rows = {}

local CURRENCIES = {
    { key = 'platinum', label = 'PP', full = 'Platinum' },
    { key = 'diamond_coins', label = 'DC', full = 'Diamond Coins' },
    { key = 'radiant_crystals', label = 'RC', full = 'Radiant Crystals' },
    { key = 'planar_symbols', label = 'PS', full = 'Planar Symbols' },
    { key = 'taelosian_symbols', label = 'TS', full = 'Taelosian Symbols' },
    { key = 'tribute_favor', label = 'Favor', full = 'Tribute Favor' },
    { key = 'celestial_crests', label = 'Crests', full = 'Celestial Crests' },
    { key = 'nightveil_scrip', label = 'NVS', full = 'Nightveil Scrip' },
    { key = 'aa_unspent', label = 'AA', full = 'Unspent AA' },
}

local SUMMARY_KEYS = {
    { key = 'platinum', label = 'PP' },
    { key = 'diamond_coins', label = 'DC' },
    { key = 'celestial_crests', label = 'Crests' },
    { key = 'planar_symbols', label = 'PS' },
    { key = 'taelosian_symbols', label = 'TS' },
}

local UI = {
    header_bg = { 0.10, 0.16, 0.22, 1.00 },
    row_alt = { 0.08, 0.10, 0.14, 0.68 },
    row_hover = { 0.13, 0.21, 0.29, 0.95 },
    zero = { 0.34, 0.38, 0.44, 1.00 },
    value = { 0.78, 0.90, 0.78, 1.00 },
    name = { 0.76, 0.82, 0.92, 1.00 },
    age_fresh = { 0.48, 0.82, 0.58, 1.00 },
    age_aging = { 0.58, 0.62, 0.68, 1.00 },
    badge_bg = { 0.085, 0.115, 0.145, 0.96 },
    badge_border = { 0.18, 0.24, 0.30, 0.76 },
    badge_label = { 0.55, 0.62, 0.70, 1.00 },
    badge_value = { 0.82, 0.90, 0.88, 1.00 },
}

local WALLET_KEYS = {}
for _, col in ipairs(CURRENCIES) do
    WALLET_KEYS[#WALLET_KEYS + 1] = col.key
end

local function wallet_diag_ms()
    if mq.gettime then
        local t = tonumber(mq.gettime())
        if t then return math.floor(t) end
    end
    return math.floor((os.time() or 0) * 1000)
end

local function file_signature(path)
    path = tostring(path or "")
    if path == "" then return "" end
    local f = io.open(path, "rb")
    if not f then return "" end
    local data = f:read("*a") or ""
    f:close()
    local hash = 0
    for i = 1, #data do
        hash = (hash * 131 + data:byte(i)) % 4294967291
    end
    return "content:" .. tostring(#data) .. ":" .. tostring(hash)
end

local function has_wallet_payload(row)
    if type(row) ~= "table" then return false end
    for _, key in ipairs(WALLET_KEYS) do
        if row[key] ~= nil then return true end
    end
    return false
end

local function refresh_sidecar(force)
    local now = os.clock()
    if force ~= true and now < sidecar_next_check_at then return false end
    sidecar_next_check_at = now + SIDECAR_CHECK_INTERVAL_S

    local path = tostring(cfg.WalletFile or "")
    local sig = file_signature(path)
    if sig == "" then
        if sidecar_sig ~= "" then
            sidecar_rows = {}
            sidecar_sig = ""
        end
        return false
    end
    if force ~= true and sig == sidecar_sig then return false end

    local ok, value = pcall(function()
        local chunk = loadfile(path)
        if type(chunk) ~= "function" then return nil end
        return chunk()
    end)
    if ok and type(value) == "table" then
        sidecar_rows = value
        sidecar_sig = sig
        return true
    end
    return false
end

local function sidecar_for_key(key)
    key = tostring(key or "")
    if key == "" then return nil end
    return sidecar_rows[key]
end

local function apply_wallet_overlay(key, snap)
    local side = sidecar_for_key(key)
    if type(side) ~= "table" or not has_wallet_payload(side) then return snap end
    local side_stamp = tonumber(side.walletUpdated) or tonumber(side.updated) or 0
    local snap_stamp = tonumber(snap and snap.walletUpdated) or tonumber(snap and snap.updated) or 0
    if side_stamp <= 0 or side_stamp < snap_stamp then return snap end

    local out = {}
    if type(snap) == "table" then
        for k, v in pairs(snap) do out[k] = v end
    end
    out.name = out.name or side.name
    out.walletUpdated = side_stamp
    out.updated = tonumber(side.updated) or out.updated or side_stamp
    out.depth = out.depth or "wallet"
    for _, field in ipairs(WALLET_KEYS) do
        if side[field] ~= nil then out[field] = side[field] end
    end
    out._walletSource = "sidecar"
    return out
end

local function wallet_row_signature(snap)
    if type(snap) ~= "table" then return "" end
    local parts = {
        tostring(snap.walletUpdated or snap.updated or ""),
        tostring(snap.status or ""),
    }
    for _, col in ipairs(CURRENCIES) do
        parts[#parts + 1] = tostring(snap[col.key] or "")
    end
    return table.concat(parts, "|")
end

local function note_visible_row_change(key, snap)
    if type(snap) ~= "table" then return end
    local sig = wallet_row_signature(snap)
    if sig == "" then return end
    local prior = visible_row_diag_sig[key]
    visible_row_diag_sig[key] = sig
    if prior ~= nil and prior ~= sig and diag.is_enabled and diag.is_enabled() then
        print(string.format("[TurboGear] wallet visible: row changed t=%d name=%s pp=%s crests=%s walletUpdated=%s source=%s",
            wallet_diag_ms(),
            tostring(snap.name or key),
            tostring(snap.platinum),
            tostring(snap.celestial_crests),
            tostring(snap.walletUpdated or snap.updated or ""),
            tostring(snap._walletSource or "store")))
    end
end

local function set_status(msg, ttl)
    status_msg = tostring(msg or "")
    status_until = os.clock() + (tonumber(ttl) or 4.0)
end

local function age_label(ts)
    ts = tonumber(ts) or 0
    if ts <= 0 then return "?" end
    local age = math.max(0, os.time() - ts)
    if age < 90 then return tostring(math.floor(age)) .. "s" end
    if age < 5400 then return tostring(math.floor(age / 60)) .. "m" end
    return tostring(math.floor(age / 3600)) .. "h"
end

local function stale_age_label(ts)
    ts = tonumber(ts) or 0
    if ts <= 0 then return "?" end
    local age = math.max(0, os.time() - ts)
    if age >= 600 then return "10m+" end
    return tostring(math.max(1, math.floor(age / 60))) .. "m"
end

local function duration_label(seconds)
    seconds = tonumber(seconds) or 0
    if seconds < 0 then seconds = 0 end
    if seconds < 90 then return tostring(math.floor(seconds)) .. "s" end
    if seconds < 5400 then return tostring(math.floor(seconds / 60)) .. "m" end
    return tostring(math.floor(seconds / 3600)) .. "h"
end

local function comma_value(v)
    local n = tonumber(v)
    if not n then return "?" end
    local sign = n < 0 and "-" or ""
    local s = tostring(math.floor(math.abs(n)))
    while true do
        local next_s, changed = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
        s = next_s
        if changed == 0 then break end
    end
    return sign .. s
end

local function compact_value(v)
    local n = tonumber(v) or 0
    local sign = n < 0 and "-" or ""
    n = math.abs(n)
    if n >= 1000000 then return string.format("%s%.2fm", sign, n / 1000000) end
    if n >= 100000 then return string.format("%s%.1fk", sign, n / 1000) end
    return sign .. comma_value(n)
end

local function text_width(text)
    if not ImGui.CalcTextSize then return 0 end
    local ok, w = pcall(ImGui.CalcTextSize, tostring(text or ""))
    if not ok then return 0 end
    if type(w) == "table" then return tonumber(w.x or w[1]) or 0 end
    return tonumber(w) or 0
end

local function column_width(fallback)
    if ImGui.GetColumnWidth then
        local ok, w = pcall(ImGui.GetColumnWidth)
        if ok then
            if type(w) == "table" then return tonumber(w.x or w[1]) or fallback end
            return tonumber(w) or fallback
        end
    end
    return fallback
end

local function table_col_text_centered(color, text)
    text = tostring(text or "")
    local col_w = column_width(72.0)
    local tw = text_width(text)
    if col_w and tw > 0 and tw < col_w and ImGui.GetCursorPosX and ImGui.SetCursorPosX then
        local ok, x = pcall(ImGui.GetCursorPosX)
        if ok and tonumber(x) then pcall(ImGui.SetCursorPosX, tonumber(x) + math.max(0, (col_w - tw) * 0.5)) end
    end
    col_text(color, text)
end

local function table_col_text_right(color, text)
    text = tostring(text or "")
    local col_w = column_width(80.0)
    local tw = text_width(text)
    if col_w and tw > 0 and tw < col_w and ImGui.GetCursorPosX and ImGui.SetCursorPosX then
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
        pc(ImGuiCol.TableRowBg, { 0.06, 0.08, 0.11, 0.72 })
        pc(ImGuiCol.TableRowBgAlt, UI.row_alt)
        pc(ImGuiCol.TableBorderLight, { 0.17, 0.21, 0.27, 0.70 })
        pc(ImGuiCol.TableBorderStrong, { 0.20, 0.28, 0.34, 0.95 })
        pc(ImGuiCol.HeaderHovered, UI.row_hover)
    end
    return pushed
end

local function draw_badge(label, value)
    label = tostring(label or "")
    value = tostring(value or "0")
    local text = label .. " " .. value
    local pad_x, pad_y = 7.0, 2.0
    local w = math.max(54.0, text_width(text) + pad_x * 2)
    local h = ((ImGui.GetTextLineHeight and ImGui.GetTextLineHeight()) or 14.0) + pad_y * 2
    if ImGui.GetWindowDrawList and ImGui.GetCursorScreenPos and ImGui.Dummy and theme.color_u32 then
        local x, y = ImGui.GetCursorScreenPos()
        local draw = ImGui.GetWindowDrawList()
        draw:AddRectFilled(ImVec2(x, y), ImVec2(x + w, y + h), theme.color_u32(UI.badge_bg), 4.0)
        draw:AddRect(ImVec2(x, y), ImVec2(x + w, y + h), theme.color_u32(UI.badge_border), 4.0, 0, 1.0)
        draw:AddText(ImVec2(x + pad_x, y + pad_y), theme.color_u32(UI.badge_label), label)
        local lx = x + pad_x + text_width(label .. " ")
        draw:AddText(ImVec2(lx, y + pad_y), theme.color_u32(UI.badge_value), value)
        ImGui.Dummy(w, h)
    else
        col_text(UI.badge_label, label)
        ImGui.SameLine(0, 3)
        col_text(UI.badge_value, value)
    end
end

local function has_wallet_fields(snap)
    if type(snap) ~= "table" then return false end
    for _, col in ipairs(CURRENCIES) do
        if snap[col.key] ~= nil then return true end
    end
    return false
end

local function snap_for_key(key)
    key = tostring(key or "")
    if key == "__self__" and store_mod.my_key then
        key = store_mod.my_key()
    end
    if key == "" then return nil end
    return apply_wallet_overlay(key, Store.get(key))
end

local function clean_name(name)
    return tostring(name or ""):match("^%s*([%w_]+)") or ""
end

local function self_key()
    return store_mod.my_key and store_mod.my_key() or "__self__"
end

local function is_self_key(key)
    key = tostring(key or "")
    return key == "__self__" or key == self_key()
end

local function refresh_local(reason)
    local ok, Engine = pcall(function() return require('engine').Engine end)
    if not ok or not Engine or not Engine.publish_wallet then
        set_status("Wallet refresh unavailable.", 5.0)
        return false
    end
    local published = Engine.publish_wallet(nil, {
        reason = reason or "wallet_refresh",
        force = true,
    })
    last_refresh_at = os.clock()
    set_status(published and "Wallet refreshed." or "Wallet refresh skipped.", 4.0)
    return published == true
end

function M.on_tab_enter()
    refresh_sidecar(true)
    refresh_local("wallet_tab_enter")
    if not auto_refresh_done then
        auto_refresh_pending = true
    end
end

local function peer_name_for_key(key)
    local snap = snap_for_key(key)
    local name = clean_name(snap and snap.name)
    if name ~= "" then return name end
    return clean_name(tostring(key or ""):match("_(.+)$") or key)
end

local function request_peer_wallet(name)
    name = clean_name(name)
    if name == "" then return false end
    return transport.send_target(name, "/tgearbg wallet") == true
end

local function refresh_roster(keys, opts)
    opts = type(opts) == "table" and opts or {}
    local auto = opts.auto == true
    local now = os.clock()
    if auto then
        if auto_refresh_done or (now - last_auto_refresh_at) < AUTO_REFRESH_COOLDOWN_S then
            return
        end
        last_auto_refresh_at = now
        auto_refresh_done = true
    elseif (now - last_manual_refresh_at) < MANUAL_REFRESH_COOLDOWN_S then
        set_status("Refresh Wallet cooling down.", 3.0)
        return
    else
        last_manual_refresh_at = now
    end

    local local_sent = false
    local peer_sent, peer_skipped = 0, 0
    for _, key in ipairs(keys or {}) do
        if is_self_key(key) then
            refresh_local("wallet_manual")
            local_sent = true
        else
            if request_peer_wallet(peer_name_for_key(key)) then
                peer_sent = peer_sent + 1
            else
                peer_skipped = peer_skipped + 1
            end
        end
    end
    if not local_sent then
        refresh_local(auto and "wallet_tab_entry_auto" or "wallet_manual")
    end
    if peer_sent > 0 then
        set_status(string.format("Wallet refresh requested: self + %d peer%s.",
            peer_sent, peer_sent == 1 and "" or "s"), 5.0)
    elseif peer_skipped > 0 then
        set_status("Wallet refreshed; some peers could not be targeted.", 5.0)
    else
        set_status("Wallet refreshed.", 4.0)
    end
end

local function collect_wallet_rows(keys)
    local rows = {}
    for _, key in ipairs(keys or {}) do
        rows[#rows + 1] = {
            key = key,
            snap = snap_for_key(key),
        }
    end
    return rows
end

local function maybe_auto_refresh(keys)
    if not auto_refresh_pending or auto_refresh_done then return end
    if type(keys) ~= "table" or #keys == 0 then return end
    auto_refresh_pending = false
    refresh_roster(keys, { auto = true })
end

local function draw_summary(rows)
    local totals = {}
    for _, row in ipairs(rows or {}) do
        local snap = row.snap
        if type(snap) == "table" and has_wallet_fields(snap) then
            for _, spec in ipairs(SUMMARY_KEYS) do
                totals[spec.key] = (totals[spec.key] or 0) + (tonumber(snap[spec.key]) or 0)
            end
        end
    end
    local shown = 0
    for _, spec in ipairs(SUMMARY_KEYS) do
        local total = totals[spec.key] or 0
        if total > 0 or shown == 0 then
            if shown > 0 then ImGui.SameLine() end
            draw_badge(spec.label, compact_value(total))
            shown = shown + 1
        end
    end
end

local function copy_selected_chars(list)
    local out = {}
    if type(list) == "table" then
        for k, v in pairs(list) do out[k] = v end
    end
    return out
end

local function go_to_collect()
    local Settings = cfg.Settings
    if type(Settings) ~= "table" then return end
    Settings.stockRosterScope = Settings.walletRosterScope or Settings.stockRosterScope or "online"
    Settings.stockViewKey = Settings.walletViewKey or Settings.stockViewKey or "__all__"
    Settings.stockViewSelectedChars = copy_selected_chars(Settings.walletViewSelectedChars)
    Settings.mainTab = "collect"
    if cfg.MarkSettingsDirty then
        cfg.MarkSettingsDirty("wallet_go_collect")
    elseif cfg.SaveSettings then
        cfg.SaveSettings()
    end
end

local function draw_toolbar(keys)
    if themed_button("Refresh Wallet##tg_wallet_refresh", Theme.sync or Theme.blue, 122, 0) then
        refresh_roster(keys)
    end
    if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
        ImGui.SetTooltip("Refresh this character and request wallet-only updates from the visible Wallet roster.")
    end
    ImGui.SameLine()
    if themed_button("Go to Collect##tg_wallet_go_collect", Theme.blue or Theme.sync, 112, 0) then
        go_to_collect()
    end
    if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
        ImGui.SetTooltip("Open Collect with this Wallet roster scope.")
    end
    if status_msg ~= "" and os.clock() < status_until then
        ImGui.SameLine()
        col_text(Theme.dim, status_msg)
    end
end

local function draw_status_cell(snap)
    if type(snap) ~= "table" then
        table_col_text_centered(Theme.placeholder or Theme.dim, "?")
        return
    end
    local updated = tonumber(snap.walletUpdated) or tonumber(snap.updated) or 0
    if not has_wallet_fields(snap) then
        table_col_text_centered(Theme.placeholder or Theme.dim, "?")
        return
    end
    local age = updated > 0 and (os.time() - updated) or 999999
    if age > 300 then
        table_col_text_centered(Theme.amber or Theme.gold, "stale " .. stale_age_label(updated))
    elseif age > 90 then
        table_col_text_centered(UI.age_aging, age_label(updated))
    else
        table_col_text_centered(UI.age_fresh, age_label(updated))
    end
end

local function draw_value_cell(value)
    local n = tonumber(value)
    local color = value ~= nil and (n == 0 and UI.zero or UI.value) or (Theme.placeholder or Theme.dim)
    table_col_text_right(color, comma_value(value))
    if value == nil and ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
        ImGui.SetTooltip("No value published yet. Refresh Wallet to request updated peer data.")
    end
end

local function draw_wallet_table(rows)
    local cols = 2 + #CURRENCIES
    local flags = (ImGuiTableFlags.Borders or 0)
        + (ImGuiTableFlags.RowBg or 0)
        + (ImGuiTableFlags.Resizable or 0)
        + (ImGuiTableFlags.NoSavedSettings or 0)
        + (ImGuiTableFlags.SizingStretchProp or 0)

    local pushed = push_table_style()
    if not ImGui.BeginTable("##tg_wallet_table", cols, flags) then
        if pushed > 0 then ImGui.PopStyleColor(pushed) end
        col_text(Theme.amber, "Wallet table unavailable.")
        return
    end

    ImGui.TableSetupColumn("Character", ImGuiTableColumnFlags.WidthFixed, 128.0)
    ImGui.TableSetupColumn("Age", ImGuiTableColumnFlags.WidthFixed, 72.0)
    for _, col in ipairs(CURRENCIES) do
        ImGui.TableSetupColumn(col.label, ImGuiTableColumnFlags.WidthStretch, 1.0)
    end
    ImGui.TableNextRow()
    set_row_bg(UI.header_bg)
    ImGui.TableSetColumnIndex(0)
    col_text(Theme.header or Theme.item, "Character")
    ImGui.TableSetColumnIndex(1)
    table_col_text_centered(Theme.header or Theme.item, "Age")
    for idx, col in ipairs(CURRENCIES) do
        ImGui.TableSetColumnIndex(idx + 1)
        table_col_text_right(Theme.header or Theme.item, col.label)
        if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
            ImGui.SetTooltip(col.full or col.label)
        end
    end

    local selectable_flags = ImGuiSelectableFlags and (ImGuiSelectableFlags.SpanAllColumns or 0) or 0
    for idx_row, row in ipairs(rows or {}) do
        local key, snap = row.key, row.snap
        ImGui.TableNextRow()
        if idx_row % 2 == 0 then set_row_bg(UI.row_alt) end

        ImGui.TableSetColumnIndex(0)
        local name = tostring((snap and snap.name) or (key == "__self__" and "Self") or key or "?")
        local pushed_text = false
        if ImGui.PushStyleColor and ImGuiCol and ImGuiCol.Text then
            ImGui.PushStyleColor(ImGuiCol.Text, UI.name[1], UI.name[2], UI.name[3], UI.name[4])
            pushed_text = true
        end
        if ImGui.Selectable then
            ImGui.Selectable(name .. "##wallet_row_" .. tostring(key), false, selectable_flags)
        else
            col_text(UI.name, name)
        end
        local hovered = ImGui.IsItemHovered and ImGui.IsItemHovered()
        if pushed_text and ImGui.PopStyleColor then pcall(ImGui.PopStyleColor, 1) end
        if hovered then set_row_bg(UI.row_hover) end

        ImGui.TableSetColumnIndex(1)
        draw_status_cell(snap)

        for idx, col in ipairs(CURRENCIES) do
            ImGui.TableSetColumnIndex(idx + 1)
            local value = snap and snap[col.key] or nil
            draw_value_cell(value)
        end
        note_visible_row_change(key, snap)
    end

    ImGui.EndTable()
    if pushed > 0 then ImGui.PopStyleColor(pushed) end
end

local function draw_body()
    local keys = characters.active_keys("wallet") or {}
    refresh_sidecar(false)
    maybe_auto_refresh(keys)
    local rows = collect_wallet_rows(keys)
    draw_toolbar(keys)
    if #rows > 0 then
        ImGui.Spacing()
        draw_summary(rows)
    end
    if ImGui.Separator then ImGui.Separator() end

    if #keys == 0 then
        col_text(Theme.amber, "No characters in this Wallet scope.")
        return
    end

    draw_wallet_table(rows)
    if last_refresh_at > 0 then
        col_text(Theme.dim, "Last local refresh: " .. duration_label(os.clock() - last_refresh_at))
    elseif #rows <= 3 then
        col_text(Theme.dim, "Wallet rows update on tab entry or Refresh Wallet; values shown are the latest visible Store rows.")
    end
end

function M.draw()
    return (diag.time_pair or diag.time)("ui.wallet.draw", draw_body)
end

return M
