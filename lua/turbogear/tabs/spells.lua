-- TurboGear/tabs/spells.lua
-- Spell research roster (66-70): missing list, peer sync, export for ResearchLearn.
--
-- Display path reads from spells_index (precomputed per-character rows, LazBis
-- style); filters are applied at draw time so toggles never rebuild anything.
-- The research planner (Catalog.build_manifest) only runs for exports/rollups.

local ImGui = require('ImGui')
local mq = require('mq')
local theme = require('theme')
local Theme, col_text, toggle_button, themed_button, segmented_text = theme.Theme, theme.col_text, theme.toggle_button, theme.themed_button, theme.segmented_text
local cfg = require('config')
local Settings, SaveSettings = cfg.Settings, cfg.SaveSettings
local views = require('views')
local snapshot_mod = require('snapshot')
local Engine = require('engine').Engine
local item_actions = require('item_actions')
local spells_index = require('spells_index')

local ok_catalog, Catalog = pcall(require, 'research_catalog')
if not ok_catalog then Catalog = nil end

local M = {}

local status_msg = ""

local SCOPE_OPTIONS = {
    { key = "online", label = "Live Peers" },
    { key = "all", label = "All Cached" },
    { key = "group", label = "Group" },
    { key = "e3", label = "E3" },
    { key = "self", label = "Self" },
}

local LEVEL_NUMS = { 70, 69, 68, 67, 66 }

local COL_WIDTH = 248.0
local COL_HEIGHT = 320.0
local COL_HEADER_H = 48.0
local LOC_COL_W = 108.0
local BTN_ROLLUP = { 0.54, 0.36, 0.18, 1.0 }
local BTN_EXPORTS_DIR = { 0.24, 0.46, 0.32, 1.0 }

local REFRESH_MIN_S = 2.0
local REFRESH_TIMEOUT_S = 12.0
local INDEX_BUDGET_MS = 5

local selected_keys_for_scope
local self_spell_book_ready
local last_auto_refresh_at = 0
local last_spell_cache_at = 0
local pending_refresh = nil

local refresh = {
    active = false,
    keys = {},
    baseline = {},
    started = 0,
    deadline = 0,
}

-- Computed once per tab entry (path resolution does file IO).
local catalog_warning = nil
local catalog_warning_checked = false

local function refresh_catalog_warning()
    catalog_warning_checked = true
    catalog_warning = nil
    if not Catalog then return end
    local warns = {}
    local ok_ini, ini_path = pcall(function()
        local _, path = Catalog.load_ini(false)
        return path
    end)
    if not ok_ini or not ini_path then
        warns[#warns + 1] = "researchlearn.ini not found (bundled copy: turbogear/data/)."
    end
    local ok_cfg, cfg_tbl = pcall(function() return Catalog.load_spells_config(false) end)
    if not ok_cfg or type(cfg_tbl) ~= "table" then
        warns[#warns + 1] = "Spell roster not found (bundled copy: turbogear/references/spells.lua)."
    end
    if #warns > 0 then catalog_warning = table.concat(warns, " ") end
end

local SCOPE_OPTS = { include_offline_cache = true }

-- Snapshot resolver shared with the index: self reads the local snapshot
-- cache; peers read the Store snapshot.
local function source_snap(key)
    if key == "__self__" then
        return snapshot_mod.cached and snapshot_mod.cached() or nil
    end
    return views.source_snapshot(key)
end

local function column_keys_for_view(view_key, scoped_keys)
    if view_key == "__all__" then
        return scoped_keys or selected_keys_for_scope()
    end
    return { view_key }
end

-- ===================== refresh state machine ============================ --

local function peer_spell_ready(key, baseline, started, now)
    local snap = views.source_snapshot(key)
    if not snap or not snap.spells_sig or snap.spells_sig == "" then
        return false
    end
    if key == "__self__" then
        return self_spell_book_ready()
    end

    baseline = baseline or {}
    local last_seen = tonumber(snap.last_seen) or 0
    local base_last = tonumber(baseline.last_seen) or 0
    if last_seen > base_last then return true end
    if (baseline.spells_sig or "") == "" then return true end
    if (now - started) >= REFRESH_MIN_S then return true end
    return false
end

local function count_ready_peers(keys, started, now)
    local ready = 0
    for _, key in ipairs(keys) do
        if peer_spell_ready(key, refresh.baseline[key], started, now) then
            ready = ready + 1
        end
    end
    return ready
end

local function run_refresh_network()
    -- Local spell book for the __self__ column (stays in the snapshot cache).
    snapshot_mod.gather({ force = true, depth = "lite", includeSpells = true })
    if Engine.ok then
        Engine.publish(true, "lite", { includeSpells = true })
        Engine.request_all(true, { includeSpells = true, depth = "lite" })
    else
        -- Static roles: the UI has no actor mailbox; the bg responder runs the
        -- publish + peer request round trip. Peer books arrive via the shared
        -- cache reload within a second or two.
        mq.cmd('/squelch /tgearbg spellsync')
    end
end

local function start_spell_refresh(view_key, scoped_keys)
    local keys = column_keys_for_view(view_key, scoped_keys)
    if #keys == 0 then
        status_msg = "No characters in scope to refresh."
        return false
    end
    if refresh.active then return false end

    pending_refresh = nil
    refresh.active = true
    refresh.keys = keys
    refresh.baseline = {}
    refresh.started = os.clock()
    refresh.deadline = refresh.started + REFRESH_TIMEOUT_S

    for _, key in ipairs(keys) do
        local snap = views.source_snapshot(key)
        refresh.baseline[key] = {
            spells_sig = snap and snap.spells_sig or "",
            last_seen = snap and snap.last_seen or 0,
        }
    end

    if Catalog and Catalog.invalidate_want_cache then Catalog.invalidate_want_cache() end
    run_refresh_network()
    status_msg = string.format("Refreshing spell lists... 0/%d peers", #keys)
    return true
end

local function queue_auto_refresh(view_key, scoped_keys)
    pending_refresh = {
        view_key = view_key,
        scoped_keys = scoped_keys,
        due_at = os.clock() + 0.75,
    }
end

local function tick_pending_refresh()
    if not pending_refresh or refresh.active then return end
    if os.clock() < pending_refresh.due_at then return end
    local pr = pending_refresh
    pending_refresh = nil
    start_spell_refresh(pr.view_key, pr.scoped_keys)
end

self_spell_book_ready = function()
    local snap = snapshot_mod.gather({ force = false, depth = "lite", includeSpells = true })
    if not snap or not snap.spells_sig or snap.spells_sig == "" then return false end
    if Catalog and Catalog.spell_book_from_snap then
        local book = Catalog.spell_book_from_snap(snap)
        if book and not book._partial then return true end
    end
    return false
end

local function tick_spell_refresh()
    if not refresh.active then return end

    local now = os.clock()
    local keys = refresh.keys or {}
    local ready = count_ready_peers(keys, refresh.started, now)
    local elapsed = now - refresh.started
    local all_ready = ready >= #keys and elapsed >= REFRESH_MIN_S
    local timed_out = now >= refresh.deadline

    status_msg = string.format("Refreshing spell lists... %d/%d peers", ready, #keys)

    if not all_ready and not timed_out then return end

    refresh.active = false
    last_spell_cache_at = os.time()
    last_auto_refresh_at = os.clock()
    -- The index picks up new spell signatures automatically via M.ensure.

    local missing = #keys - ready
    if timed_out and missing > 0 then
        local self_missing = false
        for _, key in ipairs(keys) do
            if key == "__self__" and not self_spell_book_ready() then self_missing = true end
        end
        if self_missing then
            status_msg = string.format(
                "Updated %d/%d character(s). Driver has no spell snapshot yet; peers that did not reply may be offline or missing TurboGear.",
                ready, #keys
            )
        else
            status_msg = string.format(
                "Updated %d/%d character(s). %d peer(s) did not reply or have no spell snapshot yet.",
                ready, #keys, missing
            )
        end
    else
        status_msg = string.format("Updated %d character(s).", #keys)
    end
end

-- ===================== ImGui helpers ==================================== --

local function column_width_now()
    if ImGui.GetColumnWidth then
        local w = ImGui.GetColumnWidth()
        if type(w) == "table" then return tonumber(w.x or w[1]) end
        return tonumber(w)
    end
    return nil
end

local function content_avail_x()
    local avail = ImGui.GetContentRegionAvail and ImGui.GetContentRegionAvail() or 0
    if type(avail) == "table" then return tonumber(avail.x or avail[1]) or 0 end
    return tonumber(avail) or 0
end

local function center_cursor_block(block_w)
    block_w = tonumber(block_w) or COL_WIDTH
    local avail = content_avail_x()
    if avail <= block_w or not ImGui.GetCursorPosX or not ImGui.SetCursorPosX then return end
    local ok, x = pcall(ImGui.GetCursorPosX)
    if ok and tonumber(x) then
        pcall(ImGui.SetCursorPosX, tonumber(x) + math.max(0, (avail - block_w) * 0.5))
    end
end

local LEVEL_OPTIONS = {
    { key = "all", label = "All" },
    { key = "70", label = "70" },
    { key = "69", label = "69" },
    { key = "68", label = "68" },
    { key = "67", label = "67" },
    { key = "66", label = "66" },
}

local function ensure_defaults()
    Settings.spellsRosterScope = Settings.spellsRosterScope or "online"
    Settings.spellsViewKey = Settings.spellsViewKey or "__all__"
    Settings.spellsLevelFilter = Settings.spellsLevelFilter or "all"
    if Settings.spellsResearchOnly == nil then Settings.spellsResearchOnly = true end
    if Settings.spellsHideNonResearch == nil then Settings.spellsHideNonResearch = false end
    if Settings.spellsHideOwned == nil then Settings.spellsHideOwned = false end
    Settings.spellsExportCopies = math.max(1, math.floor(tonumber(Settings.spellsExportCopies) or 1))
end

local function scope_label()
    local cur = Settings.spellsRosterScope or "online"
    for _, opt in ipairs(SCOPE_OPTIONS) do
        if opt.key == cur then return opt.label end
    end
    return "Live Peers"
end

local function key_in_scope(key, keys)
    for _, k in ipairs(keys or {}) do
        if k == key then return true end
    end
    return false
end

selected_keys_for_scope = function()
    return views.scoped_source_keys(Settings.spellsRosterScope or "online", SCOPE_OPTS)
end

local function draw_scope_picker()
    ImGui.SetNextItemWidth(140.0)
    if ImGui.BeginCombo("##spells_scope", "Show: " .. scope_label()) then
        for _, opt in ipairs(SCOPE_OPTIONS) do
            if ImGui.Selectable(opt.label .. "##spells_scope_" .. opt.key, Settings.spellsRosterScope == opt.key) then
                Settings.spellsRosterScope = opt.key
                cfg.apply_linked_roster_scope(opt.key, "spells")
                if opt.key == "self" then
                    Settings.spellsViewKey = "__self__"
                elseif Settings.spellsViewKey ~= "__all__" then
                    local keys = views.scoped_source_keys(opt.key, SCOPE_OPTS)
                    if not key_in_scope(Settings.spellsViewKey, keys) then
                        Settings.spellsViewKey = "__all__"
                    end
                end
                SaveSettings()
            end
        end
        ImGui.EndCombo()
    end
    ImGui.SameLine()
    if toggle_button("Link Scope##spells_link_scope", Settings.syncRosterScopeAcrossTabs == true) then
        Settings.syncRosterScopeAcrossTabs = not (Settings.syncRosterScopeAcrossTabs == true)
        if Settings.syncRosterScopeAcrossTabs then
            cfg.apply_linked_roster_scope(Settings.spellsRosterScope or "online", "spells")
        end
        SaveSettings()
    end
end

local function draw_view_picker()
    local keys = selected_keys_for_scope()
    local cur = Settings.spellsViewKey or "__all__"
    if (Settings.spellsRosterScope or "online") == "self" then
        cur = "__self__"
    elseif cur ~= "__all__" then
        cur = views.validate_source_key(cur)
        if not key_in_scope(cur, keys) then cur = "__all__" end
    end

    local label = cur == "__all__" and "All Characters" or views.source_label(cur)
    local changed = false
    ImGui.SetNextItemWidth(220.0)
    if ImGui.BeginCombo("##spells_view", "View: " .. label) then
        if (Settings.spellsRosterScope or "online") ~= "self" then
            if ImGui.Selectable("All Characters##spells_view_all", cur == "__all__") then
                cur = "__all__"
                changed = true
            end
        end
        for _, key in ipairs(keys) do
            local snap = views.source_snapshot(key)
            local item_label = snap and (snap.name or views.source_label(key)) or views.source_label(key)
            if ImGui.Selectable(item_label .. "##spells_view_" .. tostring(key), cur == key) then
                cur = key
                changed = true
            end
        end
        ImGui.EndCombo()
    end
    if changed or Settings.spellsViewKey ~= cur then
        Settings.spellsViewKey = cur
        SaveSettings()
    end
    return cur, keys
end

local function trim(s)
    return tostring(s or ""):match("^%s*(.-)%s*$") or ""
end

local function is_live_character(key, snap)
    if key == "__self__" then return true end
    snap = snap or views.source_snapshot(key)
    local me = mq.TLO.Me.CleanName and mq.TLO.Me.CleanName() or ""
    if trim(me) == "" then return false end
    return views.clean_name(snap and snap.name) == views.clean_name(me)
end

local function spell_data_kind(key)
    if is_live_character(key) then return "live" end
    local st = spells_index.char_state(key)
    if st and st.has_book then
        if st.partial then return "partial" end
        return "synced"
    end
    return "none"
end

local function spell_data_note(key)
    local kind = spell_data_kind(key)
    if kind == "live" then return "Live spell book." end
    if kind == "synced" then return "Synced from peer." end
    if kind == "partial" then return "Export-only list." end
    return "No spell book."
end

local function spell_data_tooltip(key)
    local kind = spell_data_kind(key)
    if kind == "live" then return "Live spell book from this game client." end
    if kind == "synced" then return "Synced spell book from a TurboGear peer snapshot." end
    if kind == "partial" then
        return "Partial list from a ResearchLearn export only.\nAmber = unknown, red = exported missing.\nRefresh after the character is online with TurboGear."
    end
    return "No spell book synced yet.\nClick Refresh while this character is online with TurboGear."
end

local function draw_spell_legend()
    segmented_text({
        { text = "Green = owned, ", color = Theme.online or Theme.green },
        { text = "red = missing, ", color = Theme.missing or Theme.brick },
        { text = "amber = unknown (no spell book synced). ", color = Theme.amber },
        { text = "Non-research spells tagged separately.", color = Theme.dim },
    })
end

-- ===================== exports (planner path) =========================== --

local function manifest_opts_for_key(key)
    local snap = views.source_snapshot(key)
    local className = snap and snap.class or mq.TLO.Me.Class.ShortName() or ""
    if key == "__self__" and (not className or className == "") then
        className = mq.TLO.Me.Class.ShortName() or ""
    end
    local live = is_live_character(key, snap)
    return {
        class = className,
        snap = snap,
        sourceKey = key,
        levels = Settings.spellsLevelFilter or "all",
        hideNonResearch = Settings.spellsHideNonResearch == true,
        hideOwned = Settings.spellsHideOwned == true,
        qty = 1,
        uiOnly = false,
        useWantFiles = true,
        liveInventory = live,
    }
end

local function export_for_key(key)
    if not Catalog then
        status_msg = "research_catalog.lua not found."
        return false
    end
    local snap = views.source_snapshot(key)
    local char = (snap and snap.name) or (key == "__self__" and mq.TLO.Me.CleanName()) or "unknown"
    local opts = manifest_opts_for_key(key)
    opts.copies = 1
    opts.character = char
    opts.source = "TurboGear"
    local path, count, err = Catalog.export_missing(opts)
    if not path then
        status_msg = tostring(err or "Export failed.")
        return false
    end
    status_msg = string.format("Exported %d spells for %s -> %s", count or 0, char, path)
    if Catalog.invalidate_want_cache then Catalog.invalidate_want_cache() end
    spells_index.invalidate(key)
    return true
end

local function box_rollup_rows(keys)
    if not Catalog then return {} end
    local merged = {}
    local order = {}
    for _, key in ipairs(keys or {}) do
        local opts = manifest_opts_for_key(key)
        opts.copies = 1
        local rows = Catalog.missing_export_rows(opts)
        for _, row in ipairs(rows or {}) do
            local norm = row.norm or Catalog.product_norm(row.name)
            local mk = string.format("%s|%d|%s", opts.class or "", row.level or 0, norm)
            local copies = math.max(1, math.floor(tonumber(row.need or row.copies) or 1))
            if not merged[mk] then
                merged[mk] = {
                    class = Catalog.normalize_class(opts.class or ""),
                    level = row.level,
                    name = row.name,
                    copies = copies,
                }
                order[#order + 1] = mk
            else
                merged[mk].copies = (merged[mk].copies or 1) + copies
            end
        end
    end
    table.sort(order, function(a, b)
        local ra, rb = merged[a], merged[b]
        if ra.level == rb.level then return (ra.name or "") < (rb.name or "") end
        return (ra.level or 0) > (rb.level or 0)
    end)
    local out = {}
    for _, mk in ipairs(order) do out[#out + 1] = merged[mk] end
    return out
end

local function export_box_rollup(keys)
    if not Catalog then
        status_msg = "research_catalog.lua not found."
        return false
    end
    local rows = box_rollup_rows(keys)
    local path = Catalog.export_path("BoxRollup")
    local ok, err = Catalog.write_want_file(path, rows, {
        character = "BoxRollup",
        class = "mixed",
        copies = 1,
        exported = os.date('%Y-%m-%d %H:%M'),
        source = "TurboGear box rollup",
    })
    if not ok then
        status_msg = tostring(err or "Export failed.")
        return false
    end
    status_msg = string.format("Box rollup: %d spells -> %s", #rows, path)
    return true
end

-- ===================== toolbar ========================================== --

local function draw_level_chips()
    for i, opt in ipairs(LEVEL_OPTIONS) do
        if i > 1 then ImGui.SameLine() end
        local on = (Settings.spellsLevelFilter or "all") == opt.key
        if toggle_button(opt.label .. "##spells_lvl_" .. opt.key, on) then
            Settings.spellsLevelFilter = opt.key
            SaveSettings()
        end
    end
end

local function open_exports_folder()
    if not Catalog or not Catalog.open_config_dir then
        status_msg = "Config folder helper not available."
        return false
    end
    local ok, err = Catalog.open_config_dir()
    if not ok then
        status_msg = tostring(err or "Could not open Config folder.")
        return false
    end
    status_msg = "Opened MacroQuest Config folder (ResearchLearn_want_*.txt exports)."
    return true
end

local function spell_cache_age_seconds()
    local stamp = tonumber(last_spell_cache_at) or 0
    if stamp <= 0 then return nil end
    return math.max(0, os.time() - stamp)
end

local function spell_cache_age_label()
    local age = spell_cache_age_seconds()
    local mins = math.max(1, math.floor(tonumber(Settings.spellsAutoRefreshMinutes) or 5))
    if not age then return string.format("Cache: none (auto %dm)", mins) end
    if age < 90 then return string.format("Cache: %ds old (auto %dm)", math.floor(age), mins) end
    return string.format("Cache: %dm old (auto %dm)", math.floor(age / 60), mins)
end

local function spell_cache_refresh_due()
    local age = spell_cache_age_seconds()
    if not age then return true end
    local mins = math.max(1, math.floor(tonumber(Settings.spellsAutoRefreshMinutes) or 5))
    return age >= (mins * 60)
end

local function draw_toolbar(view_key, scoped_keys)
    scoped_keys = scoped_keys or {}
    local refresh_busy = refresh.active == true
    if refresh_busy and ImGui.BeginDisabled then ImGui.BeginDisabled(true) end
    if themed_button("Refresh##spells_refresh", Theme.gold) and not refresh_busy then
        start_spell_refresh(view_key, scoped_keys)
    end
    if refresh_busy and ImGui.EndDisabled then ImGui.EndDisabled() end
    if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
        ImGui.SetTooltip("Request spell books from live peers; columns update as replies arrive.")
    end
    ImGui.SameLine()
    col_text(Theme.dim, spell_cache_age_label())
    if #scoped_keys > 1 and view_key == "__all__" then
        ImGui.SameLine()
        if themed_button("Export box rollup##spells_export_box", BTN_ROLLUP) then
            export_box_rollup(scoped_keys)
        end
    end
    ImGui.SameLine()
    if themed_button("Open Exports Folder##spells_open_exports", BTN_EXPORTS_DIR) then
        open_exports_folder()
    end
    if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
        ImGui.SetTooltip("Open MacroQuest/Config where ResearchLearn_want_<Character>.txt files are saved.")
    end
    ImGui.Spacing()
    draw_level_chips()
    ImGui.SameLine()
    if toggle_button(Settings.spellsHideNonResearch and "Hide non-research: ON##sp_hide_ref" or "Hide non-research: OFF##sp_hide_ref", Settings.spellsHideNonResearch == true) then
        Settings.spellsHideNonResearch = not (Settings.spellsHideNonResearch == true)
        SaveSettings()
    end
    if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
        ImGui.SetTooltip("Hide drops, library, anguish, and other non-researchable spells from the roster.")
    end
    ImGui.SameLine()
    if toggle_button(Settings.spellsHideOwned and "Missing only: ON##sp_hide" or "Missing only: OFF##sp_hide", Settings.spellsHideOwned == true) then
        Settings.spellsHideOwned = not (Settings.spellsHideOwned == true)
        SaveSettings()
    end
end

-- ===================== columns ========================================== --

local function active_levels()
    local f = Settings.spellsLevelFilter or "all"
    if f == "all" then return LEVEL_NUMS end
    local n = tonumber(f)
    if n then return { n } end
    return LEVEL_NUMS
end

local function filter_opts()
    return {
        level = Settings.spellsLevelFilter or "all",
        hide_non_research = Settings.spellsHideNonResearch == true,
        hide_owned = Settings.spellsHideOwned == true,
    }
end

local function color_for_kind(kind)
    if kind == "unknown" then return Theme.amber or { 0.85, 0.65, 0.25, 1.0 } end
    if kind == "owned" then return Theme.online or { 0.35, 0.85, 0.45, 1.0 } end
    return Theme.missing or { 0.95, 0.35, 0.35, 1.0 }
end

local function table_col_text(color, text, col_w)
    return views.col_text_fit(color, text, col_w or column_width_now())
end

local function tooltip_if_hovered(text)
    if not text or text == "" then return end
    if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
        ImGui.SetTooltip(text)
    end
end

local function spell_popup_suffix(text)
    return tostring(text or ""):gsub("[^%w_]", "_")
end

local function draw_spell_context(name, suffix)
    name = tostring(name or ""):match("^%s*(.-)%s*$") or ""
    if name == "" or not ImGui.BeginPopupContextItem then return end
    suffix = spell_popup_suffix(suffix or name)
    if ImGui.BeginPopupContextItem("##spells_spell_ctx_" .. suffix) then
        col_text(Theme.item, name)
        ImGui.Separator()
        if ImGui.Selectable("Open Alla##spells_spell_alla_" .. suffix) then
            item_actions.open_alla_spell(name)
            status_msg = item_actions.status_msg or status_msg
        end
        if ImGui.Selectable("Copy name##spells_spell_copy_" .. suffix) then
            item_actions.copy_text("Spell name", name)
            status_msg = item_actions.status_msg or status_msg
        end
        if ImGui.Selectable("Copy Alla URL##spells_spell_alla_url_" .. suffix) then
            local id = item_actions.resolve_spell_id(name)
            if id and id > 0 then
                item_actions.copy_text("Alla URL", item_actions.alla_spell_url(id))
                status_msg = item_actions.status_msg or status_msg
            else
                status_msg = "No spell id resolved from MQ for this name."
            end
        end
        ImGui.EndPopup()
    end
end

local function draw_level_table(key, by_level, levels)
    local table_flags = ImGuiTableFlags.BordersInner + ImGuiTableFlags.RowBg + ImGuiTableFlags.ScrollY
    if ImGuiTableFlags.NoSavedSettings then table_flags = table_flags + ImGuiTableFlags.NoSavedSettings end

    local table_id = "##spells_" .. tostring(key):gsub("[^%w_]", "_")
    if not ImGui.BeginTable(table_id, 2, table_flags, COL_WIDTH - 8.0, COL_HEIGHT - COL_HEADER_H - 8.0) then
        return
    end
    if ImGui.TableSetupScrollFreeze then
        pcall(ImGui.TableSetupScrollFreeze, 0, 1)
    end
    ImGui.TableSetupColumn("Name", ImGuiTableColumnFlags.WidthStretch, 1.0)
    ImGui.TableSetupColumn("Location", ImGuiTableColumnFlags.WidthFixed, LOC_COL_W)
    ImGui.TableNextRow()
    ImGui.TableSetColumnIndex(0)
    table_col_text(Theme.header or Theme.item, "Name")
    ImGui.TableSetColumnIndex(1)
    table_col_text(Theme.header or Theme.item, "Location", LOC_COL_W)

    for _, level in ipairs(levels) do
        local level_rows = by_level[level] or {}
        if #level_rows > 0 then
            ImGui.TableNextRow()
            if ImGui.TableSetColumnIndex then ImGui.TableSetColumnIndex(0) end
            col_text(Theme.category or Theme.dim, tostring(level))
            for _, dr in ipairs(level_rows) do
                ImGui.TableNextRow()
                if ImGui.TableSetColumnIndex then ImGui.TableSetColumnIndex(0) end
                local _, clipped_name = table_col_text(color_for_kind(dr.kind), dr.name)
                draw_spell_context(dr.name, tostring(key) .. "_" .. tostring(level) .. "_" .. tostring(dr.name or ""))
                if dr.recipeTip then
                    tooltip_if_hovered(dr.name .. "\n" .. dr.recipeTip)
                elseif clipped_name or dr.kind == "unknown" then
                    tooltip_if_hovered(dr.kind == "unknown" and (dr.name .. "\nSpell data unknown (no full book synced).") or dr.name)
                end
                if ImGui.TableSetColumnIndex then ImGui.TableSetColumnIndex(1) end
                local _, clipped_location = table_col_text(Theme.dim, dr.location, LOC_COL_W)
                if clipped_location then
                    tooltip_if_hovered(dr.location)
                end
            end
        end
    end
    ImGui.EndTable()
end

local function draw_column_header(key)
    local snap = views.source_snapshot(key)
    local name = snap and snap.name or views.source_label(key)
    local _, cls = views.source_header_parts(key, false)
    local label = cls and cls ~= "" and string.format("%s (%s)", name, cls) or tostring(name or "?")
    local hdr_color = views.source_header_color(key)
    local hdr_id = "##sp_hdr_" .. tostring(key):gsub("[^%w_]", "_")
    local hdr_began = false
    local hdr_open = true
    if ImGui.BeginChild then
        local ok, open = pcall(function()
            if ImVec2 then
                return ImGui.BeginChild(hdr_id, ImVec2(COL_WIDTH, COL_HEADER_H), false, 0)
            end
            return ImGui.BeginChild(hdr_id, COL_WIDTH, COL_HEADER_H, false, 0)
        end)
        if ok then
            hdr_began = true
            hdr_open = (open ~= false)
        end
    end
    if hdr_open then
        views.col_text_centered(hdr_color, label, COL_WIDTH - 12.0)
        if themed_button("Export##sp_ex_" .. tostring(key):gsub("[^%w_]", "_"), Theme.blue, COL_WIDTH - 16.0, 20.0) then
            export_for_key(key)
        end
        if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
            ImGui.SetTooltip("Export this character's missing research spells to Config/ResearchLearn_want_<Name>.txt")
        end
    end
    if hdr_began and ImGui.EndChild then ImGui.EndChild() end
end

local function draw_column_body(key, show_summary)
    local rows = spells_index.rows_for(key)
    if not rows then
        col_text(Theme.dim, "Loading roster...")
        return
    end

    local data_kind = spell_data_kind(key)
    if data_kind ~= "live" and data_kind ~= "synced" then
        col_text(Theme.amber, spell_data_note(key))
        tooltip_if_hovered(spell_data_tooltip(key))
    end

    local by_level, summary = spells_index.core.filter_rows(rows, filter_opts())
    if summary.total == 0 then
        col_text(Theme.dim, Settings.spellsHideOwned and "Nothing missing." or "No spells in filter.")
        return
    end

    draw_level_table(key, by_level, active_levels())

    if show_summary then
        col_text(Theme.dim, string.format(
            "%d shown | %d need | %d have",
            summary.total or 0, (summary.missing or 0) + (summary.unknown or 0), summary.owned or 0
        ))
    end
end

local function draw_spell_columns(column_keys)
    column_keys = column_keys or {}
    if #column_keys == 0 then
        col_text(Theme.amber, "No characters in this scope.")
        return
    end

    if not Catalog then
        col_text(Theme.amber, "Missing research catalog.")
        return
    end

    if #column_keys > 1 then
        draw_spell_legend()
    end

    if #column_keys == 1 then
        center_cursor_block(COL_WIDTH)
    end

    local scroll_began = false
    local scroll_open = true
    if #column_keys > 1 and ImGui.BeginChild then
        local avail = content_avail_x()
        local body_h = COL_HEIGHT - COL_HEADER_H
        local block_h = COL_HEADER_H + body_h + 4.0
        local scroll_flags = 0
        if ImGuiWindowFlags and ImGuiWindowFlags.HorizontalScrollbar then
            scroll_flags = ImGuiWindowFlags.HorizontalScrollbar
        end
        local ok, open = pcall(function()
            if ImVec2 then
                return ImGui.BeginChild("##spells_cols_scroll", ImVec2(avail, block_h), false, scroll_flags)
            end
            return ImGui.BeginChild("##spells_cols_scroll", avail, block_h, false, scroll_flags)
        end)
        if ok then
            scroll_began = true
            scroll_open = (open ~= false)
        end
    end

    if scroll_open then
        for i, key in ipairs(column_keys) do
            if i > 1 then ImGui.SameLine(0, 8) end
            draw_column_header(key)
        end

        if #column_keys == 1 then
            center_cursor_block(COL_WIDTH)
        end

        for i, key in ipairs(column_keys) do
            if i > 1 then ImGui.SameLine(0, 8) end
            local col_began = false
            local col_open = true
            if ImGui.BeginChild then
                local child_id = "##spells_col_" .. tostring(key):gsub("[^%w_]", "_")
                local body_h = COL_HEIGHT - COL_HEADER_H
                local ok, open = pcall(function()
                    if ImVec2 then
                        return ImGui.BeginChild(child_id, ImVec2(COL_WIDTH, body_h), true, 0)
                    end
                    return ImGui.BeginChild(child_id, COL_WIDTH, body_h, true, 0)
                end)
                if ok then
                    col_began = true
                    col_open = (open ~= false)
                end
            end
            if col_open then
                draw_column_body(key, #column_keys == 1)
            end
            if col_began and ImGui.EndChild then ImGui.EndChild() end
        end
    end

    if scroll_began and ImGui.EndChild then ImGui.EndChild() end
end

-- ===================== tab entry points ================================= --

function M.draw()
    ensure_defaults()
    if not Catalog then
        col_text(Theme.amber, "Missing research_catalog.lua in turbogear folder.")
        return
    end

    tick_pending_refresh()
    tick_spell_refresh()

    draw_scope_picker()
    ImGui.SameLine()
    local view_key, scoped_keys = draw_view_picker()
    draw_toolbar(view_key, scoped_keys)

    if (Settings.spellsRosterScope or "online") == "self" then
        view_key = "__self__"
    end

    if status_msg ~= "" then
        col_text(Theme.dim, status_msg)
    end
    if not catalog_warning_checked then refresh_catalog_warning() end
    if catalog_warning then
        col_text(Theme.amber, catalog_warning)
    end

    ImGui.Spacing()
    local column_keys = column_keys_for_view(view_key, scoped_keys)
    spells_index.ensure(column_keys, source_snap)
    spells_index.tick(INDEX_BUDGET_MS, source_snap)
    draw_spell_columns(column_keys)
end

function M.on_tab_enter()
    ensure_defaults()
    refresh_catalog_warning()
    local scoped_keys = selected_keys_for_scope()
    local view_key = Settings.spellsViewKey or "__all__"
    if (Settings.spellsRosterScope or "online") == "self" then
        view_key = "__self__"
    end
    spells_index.ensure(column_keys_for_view(view_key, scoped_keys), source_snap)
    if refresh.active or pending_refresh then return end
    local now = os.clock()
    if spell_cache_refresh_due() and (now - last_auto_refresh_at) >= REFRESH_MIN_S then
        queue_auto_refresh(view_key, scoped_keys)
    end
end

function M.export_current()
    ensure_defaults()
    return export_for_key("__self__")
end

return M
