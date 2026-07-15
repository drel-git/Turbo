-- TurboGear/tabs/userlists_ui.lua
-- Shared Create / Import / Export list actions for TurboBiS tab and Setup.

local ImGui = require('ImGui')
local mq = require('mq')
local theme = require('theme')
local Theme, col_text = theme.Theme, theme.col_text
local themed_button = theme.themed_button
local cfg = require('config')
local Settings, SaveSettings = cfg.Settings, cfg.SaveSettings
local views = require('views')
local bis = require('bis')
local userlists = require('userlists')

local M = {}

local ul_status = ""
local ul_import_name = ""
local ul_save_name = ""
local ul_confirm_delete = nil
local ul_found = nil
local ul_peer_key = ""
local ul_last_export_path = ""

local function input_text_hint(id, hint, value)
    if ImGui.InputTextWithHint then
        local ok, rv = pcall(ImGui.InputTextWithHint, id, hint, value or "")
        if ok then return rv or "" end
    end
    return ImGui.InputText(id, value or "") or ""
end

local function copy_clipboard(text)
    text = tostring(text or "")
    if text == "" then return false end
    if ImGui.SetClipboardText then
        local ok = pcall(ImGui.SetClipboardText, text)
        return ok == true
    end
    return false
end

local function online_peers()
    local ok, store = pcall(require, 'store')
    if not ok or not store or not store.Store then return {} end
    local out = {}
    for _, key in ipairs(store.Store.peer_keys()) do
        local s = store.Store.get(key)
        if s and s.status == "online" then
            out[#out + 1] = {
                key = key,
                name = s.name or key,
                label = string.format("%s (%s)", tostring(s.name or key), tostring(s.class or "?")),
            }
        end
    end
    return out
end

local function draw_howto_create()
    col_text(Theme.dim, "Build an editable wishlist or loadout plan:")
    col_text(Theme.dim, "  1) Create Empty List or Create from Worn")
    col_text(Theme.dim, "  2) Add items here or right-click items in BiS Catalog")
    col_text(Theme.dim, "  3) Custom Lists can analyze, compare, export, share, and drive linked needs")
end

local function draw_howto_announce()
    col_text(Theme.dim, "To announce when you still NEED an item:")
    col_text(Theme.dim, "  1) Add items to your list (names or item IDs both work)")
    col_text(Theme.dim, "  2) Click Use for Linked Needs on the list")
    col_text(Theme.dim, "  3) Select it from the Custom Lists dropdown")
    col_text(Theme.dim, "  4) Keep Linked needs ON - chat announces when a linked drop is still missing")
end

local function draw_share_recipe()
    col_text(Theme.dim,
        "Share: Export (file) or Share to peers (multibox). Friend: Import List or Pull from peer.")
end

local function after_export(path)
    if not path or path == "" then return end
    ul_last_export_path = path
    ul_found = nil
    local opened = userlists.open_config_folder()
    local base = path:match("([^/\\]+)$") or path
    copy_clipboard(path)
    ul_status = opened
        and string.format("Exported %s - Config folder opened; full path copied to clipboard.", base)
        or string.format("Exported %s - path copied to clipboard.", base)
end

function M.get_status()
    return ul_status
end

function M.draw_compact_actions(opts)
    opts = type(opts) == 'table' and opts or {}
    local names = bis.list_names()
    local show_heading = opts.show_heading ~= false
    local expanded = opts.expanded == true or #names == 0

    if show_heading then
        if #names == 0 then
            col_text(Theme.item, "Custom Lists - start here")
            draw_howto_create()
        else
            col_text(Theme.dim, "Custom Lists:")
        end
    end

    if not expanded and #names > 0 then return ul_status end

    if #names == 0 then
        draw_howto_announce()
        ImGui.Spacing()
    elseif show_heading then
        draw_share_recipe()
    end

    ImGui.SetNextItemWidth(200.0)
    ul_save_name = input_text_hint("##ul_save_name_compact", "New list name (optional)", ul_save_name)
    ImGui.SameLine()
    if themed_button("Create Empty List", Theme.blue) then
        local list, err = userlists.create_empty(ul_save_name)
        if list then
            ul_status = string.format("Created empty list '%s' - add items below.", list.name)
            ul_save_name = ""
            Settings.bisListMode = "user"
            Settings.bisSelectedList = list.id
            SaveSettings()
        else
            ul_status = err or "Could not create list."
        end
    end
    ImGui.SameLine()
    if themed_button("Create from Worn", Theme.steel) then
        local snap = views.source_snapshot("__self__")
        local list, err = userlists.save_worn(snap, ul_save_name)
        if list then
            ul_status = string.format("Saved '%s' (%d entries).", list.name, #(list.entries or {}))
            ul_save_name = ""
            Settings.bisListMode = "user"
            Settings.bisSelectedList = list.id
            SaveSettings()
        else
            ul_status = err or "Could not save worn list."
        end
    end

    ImGui.SetNextItemWidth(220.0)
    ul_import_name = input_text_hint("##ul_import_name_compact", "File name or path to import", ul_import_name)
    ImGui.SameLine()
    if themed_button("Import List", Theme.purple) then
        local list, err = userlists.import(ul_import_name)
        if list then
            ul_status = string.format("Imported '%s' (%d entries).", list.name, #(list.entries or {}))
            ul_import_name = ""
            Settings.bisListMode = "user"
            Settings.bisSelectedList = list.id
            SaveSettings()
            ul_found = nil
        else
            ul_status = err or "Import failed."
        end
    end
    ImGui.SameLine()
    if themed_button("Rescan##ul_rescan_compact", Theme.steel) then ul_found = nil end
    ImGui.SameLine()
    if themed_button("Open Config##ul_open_cfg_compact", Theme.steel) then
        local ok, detail = userlists.open_config_folder()
        ul_status = ok and ("Opened Config: " .. tostring(detail or "")) or tostring(detail or "Could not open Config.")
    end

    if ul_found == nil then ul_found = userlists.scan_importables() end
    local found = ul_found
    if #found > 0 then
        col_text(Theme.dim, "Found in Config (click to fill import):")
        for i, f in ipairs(found) do
            if i > 1 then ImGui.SameLine() end
            if themed_button(f .. "##ul_found_compact_" .. tostring(i), Theme.steel) then ul_import_name = f end
        end
    end

    local peers = online_peers()
    if #peers > 0 then
        col_text(Theme.dim, "Pull lists from an online TurboGear peer:")
        if ul_peer_key == "" and peers[1] then ul_peer_key = peers[1].key end
        local peer_label = ul_peer_key
        for _, p in ipairs(peers) do
            if p.key == ul_peer_key then peer_label = p.label break end
        end
        ImGui.SetNextItemWidth(220.0)
        if ImGui.BeginCombo("##ul_peer_combo", peer_label ~= "" and peer_label or "Choose peer") then
            for _, p in ipairs(peers) do
                if ImGui.Selectable(p.label .. "##ul_peer_" .. p.key, ul_peer_key == p.key) then
                    ul_peer_key = p.key
                end
            end
            ImGui.EndCombo()
        end
        ImGui.SameLine()
        if themed_button("Pull lists##ul_pull_peer", Theme.blue) then
            local ok, err = userlists.request_lists_from_peer(ul_peer_key)
            ul_status = ok and "Requested lists from peer - imports arrive automatically."
                or tostring(err or "Pull failed.")
        end
    end

    if #names > 0 then
        if not show_heading or #names > 0 then
            draw_share_recipe()
        end
        for _, rec in ipairs(names) do
            local l = rec.list or {}
            col_text(Theme.item, string.format("%s  (%d entries%s)",
                rec.name, #(l.entries or {}), (l.class and l.class ~= "") and (", " .. l.class) or ""))
            ImGui.SameLine()
            if themed_button("Use for Linked Needs##ul_ann_" .. rec.id, Theme.sync) then
                local ok, detail = userlists.prepare_for_announces(rec.id)
                ul_status = ok
                    and string.format("'%s' is active for linked-needs announces. Select it on TurboBiS.", tostring(detail or rec.name))
                    or tostring(detail or "Could not enable announces.")
            end
            ImGui.SameLine()
            if themed_button("Export##ul_exp_compact_" .. rec.id, Theme.blue) then
                local path, err = userlists.export(rec.id)
                if path then
                    after_export(path)
                else
                    ul_status = err or "Export failed."
                end
            end
            ImGui.SameLine()
            if themed_button("Share##ul_share_compact_" .. rec.id, Theme.purple) then
                local ok, detail = userlists.share_list(rec.id)
                ul_status = ok
                    and string.format("Shared '%s' to online TurboGear peers.", tostring(detail or rec.name))
                    or tostring(detail or "Share failed.")
            end
            ImGui.SameLine()
            if themed_button("Duplicate##ul_dup_compact_" .. rec.id, Theme.steel) then
                local copy, err = userlists.duplicate(rec.id)
                if copy then
                    ul_status = string.format("Duplicated as '%s'.", copy.name)
                    Settings.bisListMode = "user"
                    Settings.bisSelectedList = copy.id
                    SaveSettings()
                else
                    ul_status = err or "Duplicate failed."
                end
            end
            ImGui.SameLine()
            if themed_button("Add Worn Items##ul_worn_compact_" .. rec.id, Theme.steel) then
                local snap = views.source_snapshot("__self__")
                local list, info = userlists.merge_worn_missing(snap, rec.id)
                if list then
                    ul_status = string.format("Added %d worn item(s) to '%s'.", tonumber(info) or 0, list.name)
                else
                    ul_status = tostring(info or "Could not add worn items.")
                end
            end
            ImGui.SameLine()
            if ul_confirm_delete == rec.id then
                if themed_button("Confirm##ul_del_compact_" .. rec.id, Theme.amber) then
                    local ok, err = userlists.delete(rec.id)
                    ul_status = ok and ("Deleted '" .. rec.name .. "'.") or (err or "Delete failed.")
                    ul_confirm_delete = nil
                    SaveSettings()
                end
                ImGui.SameLine()
                if themed_button("Cancel##ul_cancel_compact_" .. rec.id, Theme.steel) then ul_confirm_delete = nil end
            else
                if themed_button("Delete##ul_del_compact_" .. rec.id, Theme.steel) then ul_confirm_delete = rec.id end
            end
        end
        if ul_last_export_path ~= "" then
            if themed_button("Copy last export path##ul_copy_path", Theme.steel) then
                if copy_clipboard(ul_last_export_path) then
                    ul_status = "Export path copied to clipboard."
                end
            end
        end
    end

    if ul_status ~= "" then col_text(Theme.dim, ul_status) end
    return ul_status
end

function M.draw_full_section(draw_edit_list_entries)
    local names = bis.list_names()
    if theme.collapsing_section("Custom Lists", true) then
        col_text(Theme.dim, "Build editable lists from item names or IDs, share them, and use them for linked needs.")
        M.draw_compact_actions({ show_heading = false, expanded = true })
        if draw_edit_list_entries then draw_edit_list_entries(names) end
    end
    return ul_status
end

return M
