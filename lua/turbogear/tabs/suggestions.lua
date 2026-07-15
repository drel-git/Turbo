-- TurboGear/tabs/suggestions.lua
-- Character + aug socket overviews and per-slot detail for cross-box suggestions.

local ImGui = require('ImGui')
local mq = require('mq')
local theme = require('theme')
local Theme, col_text, toggle_button, nav_button, themed_button = theme.Theme, theme.col_text, theme.toggle_button, theme.nav_button, theme.themed_button
local cfg = require('config')
local Settings, SaveSettings = cfg.Settings, cfg.SaveSettings
local items = require('items')
local suggestions = require('suggestions')
local aug_suggestions = require('aug_suggestions')
local stat_defs = require('stat_defs')
local ui_table = require('ui_table')
local views = require('views')
local item_actions = require('item_actions')
local item_index = require('item_index')
local Engine = require('engine').Engine
local Store = require('store').Store

local M = {}
M._state = require('state')
M._diag = require('diagnostics')
M.EQUIP_REPLACE_STATS = { mode = "base" }

local search_text = ""
local aug_search_text = ""
local overview_why_text = ""
local detail_key, detail_rows, detail_meta = nil, {}, nil
local overview_key, overview_slots, overview_meta = nil, {}, nil
local aug_overview_key, aug_overview_rows, aug_overview_meta = nil, {}, nil
local aug_detail_key, aug_detail_rows, aug_detail_meta = nil, {}, nil
local aug_plan_key, aug_plan_rows, aug_plan_meta = nil, {}, nil
local selected_detail_key, selected_detail_row = nil, nil
local whatif_status = ""
local invalidate_caches
local aug_plan_rejects = {}
local aug_plan_reject_serial = 0
local target_refresh_requests = {}
local local_source_refresh_last = 0
local cache_reload_last = 0
local TARGET_REFRESH_GAP_S = 2.0
local TARGET_AUTOSTART_GAP_S = 300.0
local TARGET_REPAIR_AFTER_S = 2
local TARGET_REPAIR_GAP_S = 90.0
local TARGET_HEARTBEAT_FRESH_S = 30
local ACTIONABLE_TARGET_MAX_AGE_S = 300
M.CACHE_WATCH_S = 10.0
M.CACHE_WATCH_INTERVAL_S = 0.25
M.last_cache_reload_reason = ""

local SUGGEST_UPGRADE_ROW = { 0.10, 0.17, 0.13, 0.70 }
local SUGGEST_NO_UPGRADE = { 0.78, 0.61, 0.28, 1.0 }
local SUGGEST_RESULT_VALUE = { 0.82, 0.86, 0.92, 1.0 }

local SOURCE_SCOPES = {
    { key = "all", label = "All Known" },
    { key = "online", label = "Online" },
    { key = "group", label = "Group" },
    { key = "e3", label = "E3 Online" },
}

local LOCATION_FILTERS = {
    { key = "all", label = "All Locations" },
    { key = "equipped", label = "Equipped" },
    { key = "stored", label = "Bags + Bank" },
    { key = "bags", label = "Bags" },
    { key = "bank", label = "Bank" },
}

local AUG_PLAN_STRENGTHS = {
    { key = "any", label = "Any Upgrade", hint = "Shows any positive gain in the selected priority stats." },
    { key = "meaningful", label = "Meaningful", hint = "Primary stat +2 or combined priority gain +4." },
    { key = "major", label = "Major", hint = "Primary stat +5 or combined priority gain +10." },
}

local COMPARE_STATS = {}
for _, key in ipairs(stat_defs.suggest_compare_keys or {}) do
    COMPARE_STATS[#COMPARE_STATS + 1] = { key = key, label = stat_defs.label(key) }
end

local MAX_COMPARE_STATS = tonumber(stat_defs.suggest_compare_max) or 5
local VALID_COMPARE, COMPARE_LABEL = {}, {}
for _, opt in ipairs(COMPARE_STATS) do
    VALID_COMPARE[opt.key] = true
    COMPARE_LABEL[opt.key] = opt.label
end

local SLOT_OPTIONS = {}
for _, group in ipairs(items.grouped_slots()) do
    for _, slot in ipairs(group.slots or {}) do
        if tonumber(slot.id) ~= 22 then
            SLOT_OPTIONS[#SLOT_OPTIONS + 1] = { id = slot.id, label = slot.label, group = group.label }
        end
    end
end

local function valid_suggest_slot_id(slot_id)
    slot_id = tonumber(slot_id)
    if not slot_id then return false end
    for _, slot in ipairs(SLOT_OPTIONS) do
        if tonumber(slot.id) == slot_id then return true end
    end
    return false
end

local function normalize_suggest_slot_id(slot_id, fallback)
    slot_id = tonumber(slot_id)
    if valid_suggest_slot_id(slot_id) then return slot_id end
    fallback = tonumber(fallback) or 2
    if valid_suggest_slot_id(fallback) then return fallback end
    return SLOT_OPTIONS[1] and SLOT_OPTIONS[1].id or 2
end

local function normalize_compare_stats()
    if type(Settings.suggestCompareStats) ~= "table" or #Settings.suggestCompareStats == 0 then
        local legacy = tostring(Settings.suggestCompareStat or "ac")
        if not VALID_COMPARE[legacy] then legacy = "ac" end
        Settings.suggestCompareStats = { legacy }
    end
    local seen = {}
    local cleaned = {}
    for _, key in ipairs(Settings.suggestCompareStats) do
        key = tostring(key or "")
        if VALID_COMPARE[key] and not seen[key] then
            seen[key] = true
            cleaned[#cleaned + 1] = key
            if #cleaned >= MAX_COMPARE_STATS then break end
        end
    end
    if #cleaned == 0 then
        cleaned[1] = "ac"
        seen.ac = true
    end
    Settings.suggestCompareStats = cleaned
    local primary = tostring(Settings.suggestComparePrimary or "")
    if primary == "" or not seen[primary] then
        Settings.suggestComparePrimary = cleaned[1]
    end
    Settings.suggestCompareStat = Settings.suggestComparePrimary
end

local function ensure_defaults()
    Settings.suggestTargetKey = Settings.suggestTargetKey or "__self__"
    Settings.suggestSlotId = normalize_suggest_slot_id(Settings.suggestSlotId, 2)
    Settings.suggestViewMode = Settings.suggestViewMode or "overview"
    if Settings.suggestOverviewActionable == nil then Settings.suggestOverviewActionable = true end
    Settings.suggestSourceScope = Settings.suggestSourceScope or "all"
    Settings.suggestLocationFilter = Settings.suggestLocationFilter or "all"
    if Settings.suggestExcludeSameEquipped == nil then Settings.suggestExcludeSameEquipped = true end
    Settings.suggestCompareStat = Settings.suggestCompareStat or "ac"
    if Settings.suggestUpgradesOnly == true and Settings.suggestOverviewActionable ~= true then
        Settings.suggestOverviewActionable = true
    end
    Settings.suggestUpgradesOnly = false
    Settings.suggestSortKey = Settings.suggestSortKey or "upgrade"
    if Settings.suggestSortDesc == nil then Settings.suggestSortDesc = true end
    if Settings.suggestShowAllRows == nil then Settings.suggestShowAllRows = false end
    Settings.suggestRowLimit = tonumber(Settings.suggestRowLimit) or 200
    Settings.suggestAugHostItem = Settings.suggestAugHostItem or ""
    Settings.suggestAugHostId = tonumber(Settings.suggestAugHostId) or 0
    Settings.suggestAugSocketIndex = tonumber(Settings.suggestAugSocketIndex) or 1
    Settings.suggestAugSocketType = tonumber(Settings.suggestAugSocketType) or 0
    Settings.suggestAugSlotId = tonumber(Settings.suggestAugSlotId) or 2
    Settings.suggestAugPlanStrength = Settings.suggestAugPlanStrength or "any"
    Settings.suggestWhatIfItem = Settings.suggestWhatIfItem or ""
    Settings.suggestWhatIfSlotId = normalize_suggest_slot_id(Settings.suggestWhatIfSlotId, Settings.suggestSlotId or 2)
    if Settings.suggestWhatIfOpen == nil then Settings.suggestWhatIfOpen = true end
    normalize_compare_stats()
end

local function clear_aug_plan_rejects()
    aug_plan_rejects = {}
    aug_plan_reject_serial = aug_plan_reject_serial + 1
    aug_plan_key = nil
end

local function is_equip_mode()
    local mode = Settings.suggestViewMode or "overview"
    return mode == "overview" or mode == "detail"
end

local function is_aug_mode()
    local mode = Settings.suggestViewMode or "overview"
    return mode == "aug_overview" or mode == "aug_detail" or mode == "aug_plan"
end

local function compare_stat_keys()
    normalize_compare_stats()
    return Settings.suggestCompareStats
end

local function compare_primary_key()
    normalize_compare_stats()
    return Settings.suggestComparePrimary or compare_stat_keys()[1] or "ac"
end

local function compare_stat_key()
    return compare_primary_key()
end

local function compare_stat_label()
    return COMPARE_LABEL[compare_stat_key()] or stat_defs.label(compare_stat_key())
end

local function compare_stat_short_label(key)
    return COMPARE_LABEL[key] or stat_defs.label(key)
end

local function compare_stat_compact_label(key)
    return stat_defs.compact_label(key)
end

local function aug_plan_strength_label()
    local cur = tostring(Settings.suggestAugPlanStrength or "any")
    for _, opt in ipairs(AUG_PLAN_STRENGTHS) do
        if opt.key == cur then return opt.label end
    end
    return "Any Upgrade"
end

local function draw_aug_plan_strength_picker()
    ImGui.SameLine()
    ImGui.Text("Show:")
    ImGui.SameLine()
    ImGui.SetNextItemWidth(124.0)
    if ImGui.BeginCombo("##suggest_aug_plan_strength", aug_plan_strength_label()) then
        for _, opt in ipairs(AUG_PLAN_STRENGTHS) do
            if ImGui.Selectable(opt.label .. "##suggest_aug_plan_strength_" .. opt.key, Settings.suggestAugPlanStrength == opt.key) then
                Settings.suggestAugPlanStrength = opt.key
                SaveSettings()
                invalidate_caches()
            end
            if opt.hint and opt.hint ~= "" and ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
                ImGui.SetTooltip(opt.hint)
            end
        end
        ImGui.EndCombo()
    end
end

local function compare_picker_label()
    local keys = compare_stat_keys()
    if #keys <= 1 then return compare_stat_short_label(keys[1] or "ac") end
    return string.format("%d stats · %s primary", #keys, compare_stat_short_label(compare_primary_key()))
end

local function compare_stats_summary()
    local keys = compare_stat_keys()
    if #keys <= 1 then return compare_stat_label() end
    local parts = {}
    for _, key in ipairs(keys) do
        local label = compare_stat_short_label(key)
        if key == compare_primary_key() then label = label .. " (primary)" end
        parts[#parts + 1] = label
    end
    return table.concat(parts, ", ")
end

local function upgrades_focus_on()
    return Settings.suggestOverviewActionable == true
end

local function slot_label(slot_id)
    for _, slot in ipairs(SLOT_OPTIONS) do
        if slot.id == tonumber(slot_id) then return slot.label end
    end
    return items.slot_display_name(slot_id)
end

local function input_text_hint(id, hint, value)
    if ImGui.InputTextWithHint then
        local ok, rv = pcall(ImGui.InputTextWithHint, id, hint, value or "")
        if ok then return rv or "" end
    end
    return ImGui.InputText(id, value or "") or ""
end

local function scope_label()
    for _, opt in ipairs(SOURCE_SCOPES) do
        if opt.key == Settings.suggestSourceScope then return opt.label end
    end
    return "All Known"
end

local function location_label()
    for _, opt in ipairs(LOCATION_FILTERS) do
        if opt.key == Settings.suggestLocationFilter then return opt.label end
    end
    return "All Locations"
end

local function owner_label(row)
    local cls = views.class_abbrev(row.ownerClass or "")
    if cls and cls ~= "" then return string.format("%s (%s)", row.owner or "?", cls) end
    return row.owner or "?"
end

local function compact_location(row)
    if not row then return "-" end
    local bucket = suggestions.location_bucket(row)
    local where = bucket == "equipped" and "Equipped" or (bucket == "bank" and "Bank" or (bucket == "bags" and "Bags" or "Stored"))
    local loc = tostring(row.location or "")
    local short = loc:match("([^:]+)$") or loc
    short = short:gsub("^%s+", ""):gsub("%s+$", "")
    if short == "" then short = loc end
    return string.format("%s @ %s", row.owner or "?", where .. (short ~= "" and (": " .. short) or ""))
end

local function age_text(seconds)
    seconds = math.max(0, tonumber(seconds) or 0)
    if seconds < 60 then return tostring(math.floor(seconds)) .. "s" end
    if seconds < 3600 then return tostring(math.floor(seconds / 60)) .. "m" end
    return tostring(math.floor(seconds / 3600)) .. "h"
end

local function selected_target_key()
    return views.validate_source_key(Settings.suggestTargetKey or "__self__")
end

local function snapshot_inventory_age(snap)
    if type(snap) ~= "table" then return nil end
    local updated = tonumber(snap.inventoryUpdated) or tonumber(snap.updated) or 0
    if updated <= 0 then return nil end
    return math.max(0, os.time() - updated)
end

local function maybe_reload_store_cache(force, active_watch)
    local now = os.clock()
    local gap = active_watch and M.CACHE_WATCH_INTERVAL_S or 3.0
    if not force and (now - (cache_reload_last or 0)) < gap then return false end
    cache_reload_last = now
    local changed, reason
    if Store.reload_cache_if_changed then
        changed, reason = Store.reload_cache_if_changed(force)
    elseif Store.reload_cache then
        changed = Store.reload_cache()
        reason = changed and "cache reloaded" or "cache unchanged"
    end
    M.last_cache_reload_reason = tostring(reason or "")
    if changed then
        if invalidate_caches then invalidate_caches() end
        return true
    end
    return false
end

local function maybe_refresh_selected_target(snap)
    local key = selected_target_key()
    if type(snap) ~= "table" then return nil end
    local age = snapshot_inventory_age(snap) or 999999
    local needs_full = snap.depth ~= "full"
    local needs_fresh = age > 120
    if not needs_full and not needs_fresh then return nil end

    local now = os.clock()
    local rec = target_refresh_requests[key] or {
        last = 0,
        requested = 0,
        waiting_since = 0,
        ok = false,
        last_autostart = -TARGET_AUTOSTART_GAP_S,
        last_repair = -TARGET_REPAIR_GAP_S,
        cache_watch_until = 0,
        request_id = "",
    }
    maybe_reload_store_cache(false, (tonumber(rec.cache_watch_until) or 0) > now)
    if M._state.engine_claim_disabled then
        rec.cache_reason = M.last_cache_reload_reason
        target_refresh_requests[key] = rec
        return rec
    end
    if (now - (rec.last or 0)) >= TARGET_REFRESH_GAP_S then
        rec.last = now
        rec.requested = os.time()
        if key == "__self__" then
            rec.ok = Engine.publish(true, "full", { skipLockouts = true, skipLiveStats = true }) and true or false
        else
            if cfg.Settings.autoAddOnlinePeers ~= false then
                local name = tostring(snap.name or ""):match("^%s*(.-)%s*$") or ""
                local cmd = name ~= "" and cfg.soft_start_bg_command_for(name) or ""
                local actor_seen = tonumber(snap.actorSeenAt) or 0
                local actor_age = actor_seen > 0 and math.max(0, os.time() - actor_seen) or 999999
                local peer_fresh = tostring(snap.status or "") == "online" and actor_age <= TARGET_HEARTBEAT_FRESH_S
                if peer_fresh then
                    rec.waiting_since = 0
                elseif (rec.waiting_since or 0) <= 0 then
                    rec.waiting_since = os.time()
                end
                if cmd ~= "" and not peer_fresh and (now - (rec.last_autostart or 0)) >= TARGET_AUTOSTART_GAP_S then
                    mq.cmd(cmd)
                    rec.last_autostart = now
                end
                local waited_for_actor = (rec.waiting_since or 0) > 0 and math.max(0, os.time() - rec.waiting_since) or 0
                if name ~= "" and not peer_fresh and waited_for_actor >= TARGET_REPAIR_AFTER_S
                    and (now - (rec.last_repair or 0)) >= TARGET_REPAIR_GAP_S
                then
                    local repair_cmd = cfg.repair_bg_command_for and cfg.repair_bg_command_for(name) or ""
                    if repair_cmd ~= "" then
                        mq.cmd(repair_cmd)
                        rec.last_repair = now
                    end
                end
            end
            local ok, request_id = Engine.request_source(key, true, { depth = "full", fastInventory = true })
            rec.ok = ok and true or false
            if request_id then rec.request_id = request_id end
            rec.cache_watch_until = now + M.CACHE_WATCH_S
            rec.cache_reason = M.last_cache_reload_reason
        end
        if invalidate_caches then invalidate_caches() end
        target_refresh_requests[key] = rec
    end
    rec.cache_reason = M.last_cache_reload_reason
    return rec
end

local function maybe_refresh_local_source()
    if M._state.engine_claim_disabled then return end
    local snap = views.source_snapshot("__self__")
    if type(snap) ~= "table" then return end
    local age = snapshot_inventory_age(snap) or 999999
    if snap.depth == "full" and age <= 120 then return end
    local now = os.clock()
    if (now - (local_source_refresh_last or 0)) < TARGET_REFRESH_GAP_S then return end
    local_source_refresh_last = now
    if Engine.publish(true, "full", { skipLockouts = true, skipLiveStats = true }) and invalidate_caches then invalidate_caches() end
end

local function draw_target_freshness_warning(snap)
    if type(snap) ~= "table" then return end
    local age = snapshot_inventory_age(snap) or 0
    local refresh = target_refresh_requests[selected_target_key()]
    local requested = refresh and tonumber(refresh.requested)
    local waited = requested and requested > 0 and math.max(0, os.time() - requested) or nil
    local wait_text = waited and ("fresh request sent " .. age_text(waited) .. " ago") or "fresh request queued"
    local wait_hint = waited and waited >= 15 and "; no fresh reply yet" or ""
    local target_name = tostring(snap.name or "target")
    local actor_seen = tonumber(snap.actorSeenAt) or 0
    local actor_age = actor_seen > 0 and math.max(0, os.time() - actor_seen) or 999999
    local actor_hint = actor_age > TARGET_HEARTBEAT_FRESH_S and " TurboGear bg is not answering yet; starting or repairing it automatically." or ""
    local function draw_request_diag()
        if not refresh then return end
        local parts = {}
        if refresh.request_id and refresh.request_id ~= "" then
            parts[#parts + 1] = "request " .. tostring(refresh.request_id)
        end
        if waited then parts[#parts + 1] = "sent " .. age_text(waited) .. " ago" end
        local reply = Engine.last_source_reply
        if reply and refresh.request_id and reply.id == refresh.request_id then
            parts[#parts + 1] = "reply " .. age_text(os.time() - (tonumber(reply.received) or os.time())) .. " ago"
        end
        local cache_reason = tostring(refresh.cache_reason or M.last_cache_reload_reason or "")
        if cache_reason ~= "" then parts[#parts + 1] = "cache " .. cache_reason end
        if #parts > 0 then col_text(Theme.dim, "Target sync: " .. table.concat(parts, " | ")) end
    end
    if snap.depth ~= "full" then
        if refresh and refresh.ok then
            col_text(Theme.amber or Theme.gold,
                "Waiting for full inventory from " .. target_name .. " (" .. wait_text .. wait_hint .. "); showing lite data for now." .. actor_hint)
            draw_request_diag()
        else
            col_text(Theme.amber or Theme.gold, "Target inventory is lite; Sync Now if suggestions look stale.")
        end
    elseif age > 300 then
        if refresh and refresh.ok then
            col_text(Theme.amber or Theme.gold,
                "Waiting for fresh inventory from " .. target_name .. " (" .. wait_text .. wait_hint .. "); using " .. age_text(age) .. "-old cache until the peer answers." .. actor_hint)
            draw_request_diag()
        else
            col_text(Theme.amber or Theme.gold, "Target inventory snapshot is " .. age_text(age) .. " old; Sync Now if gear changed recently.")
        end
    end
end

local function selected_target_inventory_ready(snap)
    if selected_target_key() == "__self__" then return true end
    if type(snap) ~= "table" then return false end
    local age = snapshot_inventory_age(snap) or 999999
    return snap.depth == "full" and age <= ACTIONABLE_TARGET_MAX_AGE_S
end

local function draw_target_inventory_wait(snap)
    local key = selected_target_key()
    local rec = target_refresh_requests[key]
    maybe_reload_store_cache(false, rec and (tonumber(rec.cache_watch_until) or 0) > os.clock())
    snap = views.source_snapshot(key)
    if selected_target_inventory_ready(snap) then return false end
    local target_name = tostring((snap and snap.name) or views.source_owner_name(key) or "target")
    local age = snapshot_inventory_age(snap)
    local age_line = age and ("Last inventory cache: " .. age_text(age) .. " old.") or "No inventory cache yet."
    local state = views.source_state and views.source_state(key) or nil
    local actor_live = state and state.actorLive == true

    col_text(Theme.amber or Theme.gold,
        target_name .. " is visible, but TurboGear does not have a fresh full inventory snapshot yet.")
    col_text(Theme.dim,
        "Suggestions are hidden until the background responder publishes a fresh inventory snapshot.")
    col_text(Theme.dim, age_line)
    if state then
        col_text(actor_live and (Theme.online or Theme.green) or Theme.dim,
            "Responder: " .. tostring(state.responder or "not answering") .. " | source state: " .. tostring(state.tag or "?"))
    elseif not actor_live then
        col_text(Theme.dim, "Responder: not answering yet.")
    end
    local refresh = target_refresh_requests[key]
    if refresh then
        local reply = Engine.last_source_reply
        local parts = {}
        if refresh.request_id and refresh.request_id ~= "" then parts[#parts + 1] = "request " .. tostring(refresh.request_id) end
        if tonumber(refresh.requested) and tonumber(refresh.requested) > 0 then
            parts[#parts + 1] = "sent " .. age_text(os.time() - tonumber(refresh.requested)) .. " ago"
        end
        if reply and refresh.request_id and reply.id == refresh.request_id then
            parts[#parts + 1] = "reply " .. age_text(os.time() - (tonumber(reply.received) or os.time())) .. " ago"
        end
        local cache_reason = tostring(refresh.cache_reason or M.last_cache_reload_reason or "")
        if cache_reason ~= "" then parts[#parts + 1] = "cache " .. cache_reason end
        if #parts > 0 then col_text(Theme.dim, "Target sync: " .. table.concat(parts, " | ")) end
    end

    if themed_button("Request inventory now##tg_request_target_inventory", Theme.blue, 150, 0) then
        target_refresh_requests[key] = nil
        maybe_reload_store_cache(true)
        local rec = {
            last = os.clock(),
            requested = os.time(),
            waiting_since = os.time(),
            ok = true,
            cache_watch_until = os.clock() + M.CACHE_WATCH_S,
            cache_reason = M.last_cache_reload_reason,
        }
        target_refresh_requests[key] = rec
        if M._state.engine_claim_disabled then
            mq.cmd('/squelch /tgearbg sync')
        else
            target_refresh_requests[key] = nil
            maybe_refresh_selected_target(snap)
        end
    end
    ImGui.SameLine()
    if themed_button("Start bg on " .. target_name .. "##tg_start_target_bg", Theme.purple, 170, 0) then
        local cmd = cfg.soft_start_bg_command_for(target_name)
        if cmd ~= "" then mq.cmd(cmd) end
    end
    ImGui.SameLine()
    if themed_button("Repair bg##tg_repair_target_bg", Theme.amber or Theme.gold, 100, 0) then
        local cmd = cfg.repair_bg_command_for and cfg.repair_bg_command_for(target_name) or ""
        if cmd ~= "" then mq.cmd(cmd) end
        local rec = target_refresh_requests[key] or {}
        rec.last_repair = os.clock()
        rec.waiting_since = os.time()
        target_refresh_requests[key] = rec
    end
    ImGui.SameLine()
    col_text(Theme.dim, "This prevents 14h-old gear from being treated as current.")
    return true
end

local function row_key(row)
    if not row then return "" end
    return tostring(row.sourceKey or table.concat({
        row.server or "", row.owner or "", row.where or "", row.id or 0, row.location or ""
    }, ":"))
end

local function aug_list_sig(augs)
    local parts = {}
    for _, aug in ipairs(augs or {}) do
        parts[#parts + 1] = table.concat({
            tostring(aug.index or ""),
            tostring(aug.type or ""),
            tostring(aug.id or 0),
            tostring(aug.name or ""),
            aug.empty and "empty" or "filled",
        }, ":")
    end
    return table.concat(parts, ",")
end

local function target_snapshot_sig(snap)
    if type(snap) ~= "table" then return "no-snap" end
    local parts = {
        tostring(snap.inventoryUpdated or snap.updated or 0),
        tostring(snap.depth or ""),
        tostring(snap.status or ""),
        tostring(snap.last_seen or 0),
    }
    for _, item in ipairs(snap.equipped or {}) do
        parts[#parts + 1] = table.concat({
            tostring(item.slotid or ""),
            tostring(item.id or 0),
            tostring(item.name or ""),
            aug_list_sig(item.augs),
        }, "|")
    end
    return table.concat(parts, "\30")
end

local function shared_controls_key(index_version, mode)
    local snap = views.source_snapshot(Settings.suggestTargetKey or "__self__")
    return table.concat({
        tostring(mode or ""),
        tostring(index_version or 0),
        tostring(Settings.suggestTargetKey or ""),
        target_snapshot_sig(snap),
        tostring(snap and snap.level or 0),
        tostring(Settings.suggestSourceScope or ""),
        tostring(Settings.suggestLocationFilter or ""),
        tostring(Settings.suggestExcludeSameEquipped),
        table.concat(compare_stat_keys(), ",") .. "|" .. compare_primary_key(),
        tostring(Settings.suggestOverviewActionable),
    }, "\1")
end

local function detail_controls_key(index_version)
    return shared_controls_key(index_version, "detail") .. "\1" .. table.concat({
        tostring(Settings.suggestSlotId or ""),
        tostring(Settings.suggestSortKey or ""),
        tostring(Settings.suggestSortDesc),
        tostring(search_text or ""),
    }, "\1")
end

local function format_delta(delta)
    if delta == nil then return "-", Theme.placeholder or Theme.dim end
    local n = math.floor(delta)
    if n > 0 then return "+" .. tostring(n), SUGGEST_RESULT_VALUE end
    if n < 0 then return tostring(n), Theme.brick or Theme.missing or Theme.amber end
    return "=", Theme.dim
end

local function delta_result_color(delta)
    if delta == nil then return Theme.placeholder or Theme.dim end
    local n = math.floor(delta)
    if n > 0 then return SUGGEST_RESULT_VALUE end
    if n < 0 then return Theme.brick or Theme.missing or Theme.amber end
    return Theme.header or Theme.cyan or Theme.dim
end

local function best_available_text(delta)
    if delta == nil then return "-" end
    local n = math.floor(delta)
    if n == 0 then return "-" end
    if n > 0 then return "+" .. tostring(n) end
    return tostring(n)
end

local function delta_label()
    return "Result"
end

local function result_label(delta)
    local delta_text, _ = format_delta(delta)
    local delta_color = delta_result_color(delta)
    if delta == nil then return "-", delta_color end
    local n = math.floor(delta)
    if n > 0 then return "Upgrade " .. delta_text, delta_color end
    if n == 0 then return "No upgrade =", delta_color end
    return "No upgrade " .. delta_text, delta_color
end

local function draw_result_inline(delta)
    if delta == nil then
        col_text(Theme.placeholder or Theme.dim, "-")
        return
    end
    local n = math.floor(delta)
    local value_text, value_color = format_delta(delta)
    if n > 0 then
        col_text(Theme.green or Theme.valueTop, "Upgrade")
        ImGui.SameLine(0, 4)
        col_text(SUGGEST_RESULT_VALUE, value_text)
    else
        col_text(SUGGEST_NO_UPGRADE, "No upgrade")
        ImGui.SameLine(0, 4)
        col_text(n < 0 and value_color or Theme.dim, best_available_text(delta))
    end
end

local function format_secondary_also_line(wrapped, hide_unchanged)
    if not wrapped then return "" end
    local primary = compare_primary_key()
    local parts = {}
    for _, key in ipairs(compare_stat_keys()) do
        if key ~= primary then
            local delta = wrapped.deltas and wrapped.deltas[key]
            if delta ~= nil then
                if not hide_unchanged or math.floor(delta) ~= 0 then
                    local text = format_delta(delta)
                    parts[#parts + 1] = compare_stat_compact_label(key) .. " " .. text
                end
            end
        end
    end
    return table.concat(parts, " · ")
end

local function format_aug_stat_values(row, keys, hide_zero)
    local parts = {}
    for _, key in ipairs(keys or compare_stat_keys()) do
        local val = suggestions.stat_value(row, key)
        if val ~= nil and (not hide_zero or tonumber(val) ~= 0) then
            parts[#parts + 1] = compare_stat_compact_label(key) .. " " .. stat_defs.format_value(key, val)
        end
    end
    return table.concat(parts, " | ")
end

function M.format_item_stat_value(row, key)
    local base = suggestions.base_stat_value(row, key)
    local bonus = suggestions.aug_stat_bonus(row, key)
    local text = compare_stat_compact_label(key) .. " " .. stat_defs.format_value(key, base)
    if bonus ~= 0 then
        text = text .. " (" .. stat_defs.format_signed_delta(key, bonus) .. " aug)"
    end
    return text
end

function M.format_item_primary_stat(row)
    if not row then return "" end
    return M.format_item_stat_value(row, compare_primary_key())
end

local function draw_aug_stat_values(row, color)
    local line = format_aug_stat_values(row, compare_stat_keys(), true)
    if line ~= "" then
        col_text(color or Theme.value or Theme.green, line)
    end
end

local function draw_secondary_also_line(wrapped, hide_unchanged)
    local line = format_secondary_also_line(wrapped, hide_unchanged ~= false)
    if line == "" then return end
    col_text(Theme.dim, "Also: " .. line)
end

local function draw_detail_result_cell(wrapped)
    if not wrapped or wrapped.delta == nil then
        col_text(Theme.placeholder or Theme.dim, "-")
        return
    end
    local stat = compare_stat_compact_label(compare_primary_key())
    local value_text, value_color = format_delta(wrapped.delta)
    local n = math.floor(wrapped.delta)
    local also = format_secondary_also_line(wrapped, true)
    if n > 0 then
        col_text(Theme.green or Theme.valueTop, "Upgrade:")
        ImGui.SameLine(0, 4)
        col_text(SUGGEST_RESULT_VALUE, stat .. " " .. value_text)
    elseif n == 0 then
        col_text(Theme.dim, "Sidegrade:")
        ImGui.SameLine(0, 4)
        col_text(Theme.dim, stat .. " =")
    else
        col_text(Theme.dim, "Best known:")
        ImGui.SameLine(0, 4)
        col_text(value_color, stat .. " " .. best_available_text(wrapped.delta))
    end
    if also ~= "" then
        if ImGui.PushTextWrapPos and ImGui.GetContentRegionAvail then
            local ok, avail = pcall(ImGui.GetContentRegionAvail)
            if ok and avail then
                local w = type(avail) == "table" and (tonumber(avail.x) or tonumber(avail[1])) or tonumber(avail)
                if w and w > 40 then
                    pcall(ImGui.PushTextWrapPos, ImGui.GetCursorPosX() + w - 4)
                end
            end
        end
        col_text(Theme.dim, "Also: " .. also)
        if ImGui.PopTextWrapPos then pcall(ImGui.PopTextWrapPos) end
    end
    local stat_line = M.format_item_primary_stat(wrapped.row)
    if stat_line ~= "" then col_text(Theme.dim, "Base: " .. stat_line) end
end

local function draw_candidate_result(wrapped, pick_kind)
    pick_kind = pick_kind or "best"
    if not wrapped then
        col_text(Theme.placeholder or Theme.dim, "-")
        return
    end
    local delta = wrapped.delta
    local stat = compare_stat_compact_label(compare_primary_key())
    local value_text, value_color = format_delta(delta)
    if delta == nil then
        if pick_kind == "alt" then
            col_text(Theme.dim, "Closest: —")
        else
            col_text(Theme.dim, "Best available: —")
        end
        return
    end
    local n = math.floor(delta)
    if n > 0 then
        col_text(Theme.green or Theme.valueTop, "Upgrade:"); ImGui.SameLine()
        col_text(SUGGEST_RESULT_VALUE, string.format("%s %s", stat, value_text))
        local stat_line = M.format_item_primary_stat(wrapped.row)
        if stat_line ~= "" then col_text(Theme.dim, "Base: " .. stat_line) end
        draw_secondary_also_line(wrapped, true)
        return
    end
    if n == 0 then
        col_text(Theme.dim, "Sidegrade:"); ImGui.SameLine()
        col_text(Theme.dim, string.format("%s =", stat))
    elseif pick_kind == "alt" then
        col_text(Theme.dim, "Alt known:"); ImGui.SameLine()
        col_text(value_color, string.format("%s %s", stat, best_available_text(delta)))
    else
        col_text(Theme.dim, "Best known:"); ImGui.SameLine()
        col_text(value_color, string.format("%s %s", stat, best_available_text(delta)))
    end
    local stat_line = M.format_item_primary_stat(wrapped.row)
    if stat_line ~= "" then col_text(Theme.dim, "Base: " .. stat_line) end
    draw_secondary_also_line(wrapped, true)
end

local function candidate_color(wrapped)
    if wrapped and wrapped.delta and math.floor(wrapped.delta) > 0 then return Theme.valueTop or Theme.green or Theme.item end
    if wrapped and wrapped.delta and math.floor(wrapped.delta) < 0 then return Theme.dim or Theme.item end
    if wrapped then return Theme.item end
    return Theme.placeholder or Theme.dim
end

local function owner_snap(row)
    local owner_clean = views.clean_name(row and row.owner)
    if owner_clean == "" then return nil end
    local me = ""
    pcall(function() me = mq.TLO.Me.CleanName() or "" end)
    if owner_clean == views.clean_name(me) then
        local snap = views.source_snapshot("__self__")
        return snap
    end
    for _, snap in pairs(Store.sources or {}) do
        if views.clean_name(snap and snap.name) == owner_clean then return snap end
    end
    return nil
end

local function brief_age(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    if seconds < 90 then return tostring(seconds) .. "s" end
    if seconds < 5400 then return tostring(math.floor(seconds / 60)) .. "m" end
    if seconds < 129600 then return tostring(math.floor(seconds / 3600)) .. "h" end
    return tostring(math.floor(seconds / 86400)) .. "d"
end

local function target_name(meta)
    local name = tostring((meta and meta.targetName) or views.source_owner_name(Settings.suggestTargetKey or "__self__") or "")
    return name ~= "" and name or "target"
end

local function target_short(meta)
    local name = target_name(meta)
    return name:match("^([^%s%(]+)") or name
end

local function suggest_scope_keys()
    local scope = Settings.suggestSourceScope or "all"
    local keys = views.scoped_source_keys(scope, { include_offline_cache = scope == "all" }) or {}
    if #keys == 0 then keys = { "__self__" } end
    return keys
end

local function target_in_suggest_scope(target_key)
    target_key = views.validate_source_key(target_key or "__self__")
    for _, key in ipairs(suggest_scope_keys()) do
        if key == target_key then return true end
    end
    return false
end

local function normalize_suggest_target_key(target_key)
    target_key = views.validate_source_key(target_key or "__self__")
    if target_in_suggest_scope(target_key) then return target_key end
    for _, key in ipairs(suggest_scope_keys()) do
        if key == "__self__" then return "__self__" end
    end
    return suggest_scope_keys()[1] or "__self__"
end

local function candidate_classification(wrapped, current)
    if not wrapped then return "none", "No candidate", Theme.placeholder or Theme.dim end
    if not current or not current.name or current.name == "" then
        return "fill", "Fill empty slot", Theme.amber or Theme.gold
    end
    local n = wrapped.delta ~= nil and math.floor(wrapped.delta) or nil
    if n and n > 0 then return "upgrade", "Upgrade", Theme.valueTop or Theme.green end
    if n and n == 0 then return "sidegrade", "Sidegrade", Theme.dim end
    return "best", "Best known only", SUGGEST_NO_UPGRADE
end

local function transfer_lines(action)
    local lines = {
        "Item: " .. tostring(action.item or "?"),
        "From: " .. tostring(action.owner or "?"),
        "To: " .. tostring(action.recipient or "?"),
        "Location: " .. tostring(action.location or "-"),
        "Slot: " .. tostring(action.slot or "-"),
        "Result: " .. tostring(action.result or "-"),
        "Mode: " .. tostring(action.mode or "writes a TurboGive [GiveList] rule; it does not start a trade."),
    }
    if action.warning and action.warning ~= "" then lines[#lines + 1] = "Verify: " .. action.warning end
    if action.reason and action.reason ~= "" then lines[#lines + 1] = "Guard: " .. action.reason end
    return lines
end

local function action_guarded_by_source(action, row, recipient)
    if not action or not row then return action end
    local recipient_clean = views.clean_name(recipient)
    local owner_clean = views.clean_name(row.owner)
    local bucket = suggestions.location_bucket(row)
    local status = tostring(row.ownerStatus or "")
    local status_lower = status:lower()
    local snap = owner_snap(row)

    if recipient_clean == "" then
        action.label = "Blocked"
        action.reason = "No recipient selected."
        return action
    end
    if owner_clean == recipient_clean then
        action.label = "Owned"
        action.detailOnly = true
        action.reason = "Candidate is already owned by " .. tostring(recipient or "target") .. "."
        return action
    end
    if (tonumber(row.nodrop) or 0) == 1 then
        action.label = "Blocked"
        action.reason = "No-drop item cannot be handed to another character."
        return action
    end
    if row.attuned == true then
        action.label = "Blocked"
        action.reason = "Attuned item cannot be handed to another character."
        return action
    end
    if bucket == "equipped" or bucket == "installed_aug" then
        action.label = "Blocked"
        action.reason = "Item is equipped/installed on " .. tostring(row.owner or "?") .. ". Move it to bags before Give Now."
        return action
    end

    local reasons = {}
    local queue_only = false
    if status_lower:find("offline", 1, true) then
        queue_only = true
        reasons[#reasons + 1] = "source owner is offline/cache"
    elseif status_lower:find("stale", 1, true) then
        queue_only = true
        reasons[#reasons + 1] = "source owner snapshot is stale"
    elseif status_lower ~= "" and not status_lower:find("live", 1, true) and not status_lower:find("online", 1, true) then
        queue_only = true
        reasons[#reasons + 1] = "source status is " .. status
    end

    if bucket == "bank" then
        queue_only = true
        local bank_age = snap and tonumber(snap.bankCapturedAt) and math.max(0, os.time() - tonumber(snap.bankCapturedAt)) or nil
        if snap and snap.bankLive == true then
            reasons[#reasons + 1] = "source item is in a live bank snapshot"
        elseif bank_age then
            reasons[#reasons + 1] = "source item is bank cache " .. brief_age(bank_age) .. " old"
        else
            reasons[#reasons + 1] = "source item is in cached bank data"
        end
    end

    action.enabled = true
    action.queueOnly = queue_only
    action.reason = table.concat(reasons, "; ")
    return action
end

local function build_transfer_action(meta, wrapped, slot_id, current)
    local row = wrapped and wrapped.row
    if not row then return { label = "Details", enabled = false, detailOnly = true, reason = "No candidate." } end
    local class_key, class_label = candidate_classification(wrapped, current)
    local recipient = target_name(meta)
    local bucket = suggestions.location_bucket(row)
    local stat = compare_stat_compact_label(compare_primary_key())
    local delta_text = format_delta(wrapped.delta)
    local result = class_label .. (wrapped.delta ~= nil and (" (" .. stat .. " " .. delta_text .. ")") or "")
    local action = {
        item = row.name or "?",
        id = row.id,
        owner = row.owner or "?",
        recipient = recipient,
        location = compact_location(row),
        slot = slot_label(slot_id),
        result = result,
        opts = {
            id = row.id,
            owner = row.owner,
            sourceLocation = compact_location(row),
            locationGroup = row.locationGroup,
            where = row.where,
            nodrop = row.nodrop,
            attuned = row.attuned,
            attunable = row.attunable,
        },
    }

    if class_key ~= "upgrade" and class_key ~= "fill" then
        action.label = "Details"
        action.detailOnly = true
        action.reason = class_label .. "; not queued by default."
        return action
    end

    action = action_guarded_by_source(action, row, recipient)
    if action.enabled then
        if bucket == "bank" and row.id and item_actions.bank_give_now_available(row.id, row.owner, recipient, action.opts) then
            action.bankGive = true
            action.queueOnly = false
            action.reason = ""
            action.mode = "pull from bank, then live trade via configured transport; no INI rule written."
            action.label = "Bank + Give"
        elseif not action.queueOnly and row.id and item_actions.give_now_available(row.id, row.owner, recipient, action.opts) then
            action.liveGive = true
            action.mode = "live trade now via configured transport; no INI rule written."
            action.label = "Give"
        else
            action.label = "Details"
            action.detailOnly = true
            action.reason = action.reason ~= "" and action.reason
                or (bucket == "bank"
                    and "Bring source and recipient to the same zone; source must be able to open a banker for Bank + Give."
                    or "Bring the source and recipient to the same zone with the item in bags, then use Give Now.")
        end
    end
    return action
end

local function run_transfer_action(action)
    if not action or not action.item then return end
    if action.detailOnly then return false end
    if not action.enabled then
        item_actions.show_action_notice("TurboGear Transfer Blocked", transfer_lines(action))
        return false
    end
    local lines = transfer_lines(action)
    if action.bankGive then
        lines[#lines + 1] = "Source must be online, same zone, and able to open a banker."
        lines[#lines + 1] = "TurboGive verifies the exact bank item ID before moving it."
        return item_actions.bank_give_now_action(
            action.item,
            action.id,
            action.owner,
            action.recipient,
            action.opts,
            lines
        )
    elseif action.liveGive then
        lines[#lines + 1] = "Source and recipient must be online and in the same zone/range."
        return item_actions.give_now_action(
            action.item,
            action.id,
            action.owner,
            action.recipient,
            action.opts,
            lines
        )
    end
    if action.queueOnly then
        lines[#lines + 1] = "Before running TurboGive: sync/open the source owner if this cache may be stale."
    else
        lines[#lines + 1] = "Before running TurboGive: source and recipient should be online and ready."
    end
    return item_actions.queue_turbogive_rule(
        action.item,
        action.recipient,
        1,
        action.opts,
        lines,
        action.queueOnly and "Queue TurboGive Rule" or "Give Gear Via TurboGive",
        action.queueOnly and "Queue" or "Write"
    )
end

local function sort_text(v)
    return tostring(v or ""):lower()
end

local function compare_text(a, b, desc)
    if a == b then return nil end
    if desc then return a > b end
    return a < b
end

local function decorate_rows(rows, meta)
    local current = meta and meta.currentEquipped
    local keys = compare_stat_keys()
    local primary = compare_primary_key()
    local out = {}
    for i, row in ipairs(rows or {}) do
        local wrapped = {
            row = row,
            delta = suggestions.upgrade_delta(row, current, primary, M.EQUIP_REPLACE_STATS),
            stat = suggestions.stat_value(row, primary, M.EQUIP_REPLACE_STATS),
            stats = {},
            deltas = {},
        }
        for _, key in ipairs(keys) do
            wrapped.stats[key] = suggestions.stat_value(row, key, M.EQUIP_REPLACE_STATS)
            wrapped.deltas[key] = suggestions.upgrade_delta(row, current, key, M.EQUIP_REPLACE_STATS)
        end
        out[i] = wrapped
    end
    return out
end

local function row_sort_value(wrapped, sort_key)
    local row = wrapped.row
    if sort_key == "upgrade" then return wrapped.delta, true end
    if sort_key == "item" then return sort_text(row.name), false end
    if sort_key == "owner" then return sort_text(owner_label(row)), false end
    if sort_key == "location" then return sort_text(row.location), false end
    if sort_key == "stat" then return wrapped.stat or 0, true end
    return wrapped.delta, true
end

local function sort_wrapped_rows(wrapped)
    local sort_key = Settings.suggestSortKey or "upgrade"
    local desc = Settings.suggestSortDesc ~= false
    ui_table.stable_sort(wrapped, function(a, b)
        local primary_a, num_a = row_sort_value(a, sort_key)
        local primary_b, num_b = row_sort_value(b, sort_key)
        if num_a then
            local primary = ui_table.compare_number(primary_a, primary_b, desc)
            if primary ~= nil then return primary end
        else
            local text_cmp = compare_text(primary_a, primary_b, desc)
            if text_cmp ~= nil then return text_cmp end
        end
        local delta_cmp = ui_table.compare_number(a.delta, b.delta, true)
        if delta_cmp ~= nil then return delta_cmp end
        return false
    end)
end

local function visible_detail_rows()
    local _, index_version = item_index.get(false)
    local key = detail_controls_key(index_version)
    if detail_key == key then return detail_rows, detail_meta end

    return M._diag.time("ui.suggestions.visible_detail", function()
        local rows, meta = suggestions.get_available({
            targetKey = Settings.suggestTargetKey,
            slotId = Settings.suggestSlotId,
            scope = Settings.suggestSourceScope,
            locationFilter = Settings.suggestLocationFilter,
            excludeSameEquipped = Settings.suggestExcludeSameEquipped ~= false,
            upgradesOnly = upgrades_focus_on(),
            compareStat = compare_stat_key(),
            search = search_text,
        })
        local wrapped = decorate_rows(rows, meta)
        sort_wrapped_rows(wrapped)
        detail_rows = wrapped
        detail_meta = meta
        detail_key = key
        if selected_detail_key then
            local found = false
            for _, rec in ipairs(wrapped) do
                if row_key(rec.row) == selected_detail_key then found = true; break end
            end
            if not found then selected_detail_key, selected_detail_row = nil, nil end
        end
        return detail_rows, detail_meta
    end)
end

local function visible_overview()
    local _, index_version = item_index.get(false)
    local key = shared_controls_key(index_version, "overview")
    if overview_key == key then return overview_slots, overview_meta end

    return M._diag.time("ui.suggestions.visible_overview", function()
        local slots, meta = suggestions.build_overview({
            targetKey = Settings.suggestTargetKey,
            scope = Settings.suggestSourceScope,
            locationFilter = Settings.suggestLocationFilter,
            excludeSameEquipped = Settings.suggestExcludeSameEquipped ~= false,
            upgradesOnly = upgrades_focus_on(),
            compareStat = compare_primary_key(),
            compareStats = compare_stat_keys(),
            comparePrimary = compare_primary_key(),
            slot_defs = SLOT_OPTIONS,
            topN = 3,
        })
        overview_slots = slots
        overview_meta = meta
        overview_key = key
        return overview_slots, overview_meta
    end)
end

invalidate_caches = function()
    detail_key = nil
    overview_key = nil
    aug_overview_key = nil
    aug_detail_key = nil
    aug_plan_key = nil
end

function M.open_for(target_key, slot_id, opts)
    ensure_defaults()
    opts = type(opts) == "table" and opts or {}
    Settings.suggestTargetKey = views.validate_source_key(target_key or "__self__")
    Settings.suggestSlotId = normalize_suggest_slot_id(slot_id, Settings.suggestSlotId or 2)
    Settings.mainTab = "upgrade"
    Settings.upgradeTab = "suggestions"
    Settings.suggestViewMode = opts.overview and "overview" or "detail"
    if opts.sortUpgrades ~= false then
        Settings.suggestSortKey = "upgrade"
        Settings.suggestSortDesc = true
    end
    if opts.upgradesOnly == true then Settings.suggestOverviewActionable = true end
    SaveSettings()
    invalidate_caches()
end

function M.open_for_aug(target_key, host_item, host_id, slot_id, socket_index, socket_type, opts)
    ensure_defaults()
    opts = type(opts) == "table" and opts or {}
    Settings.suggestTargetKey = views.validate_source_key(target_key or "__self__")
    Settings.suggestAugHostItem = tostring(host_item or "")
    Settings.suggestAugHostId = tonumber(host_id) or 0
    Settings.suggestAugSlotId = tonumber(slot_id) or Settings.suggestAugSlotId or 2
    Settings.suggestAugSocketIndex = tonumber(socket_index) or 1
    Settings.suggestAugSocketType = tonumber(socket_type) or 0
    Settings.mainTab = "upgrade"
    Settings.upgradeTab = "suggestions"
    Settings.suggestViewMode = opts.overview and "aug_overview" or "aug_detail"
    SaveSettings()
    invalidate_caches()
end

local function draw_target_picker()
    Settings.suggestTargetKey = normalize_suggest_target_key(Settings.suggestTargetKey)
    ImGui.Text("Character:")
    ImGui.SameLine()
    local old = Settings.suggestTargetKey
    ImGui.SetNextItemWidth(220.0)
    if ImGui.BeginCombo("##suggest_target", views.source_label(Settings.suggestTargetKey or "__self__")) then
        for _, key in ipairs(suggest_scope_keys()) do
            if ImGui.Selectable(views.source_label(key) .. "##suggest_target_" .. tostring(key), Settings.suggestTargetKey == key) then
                Settings.suggestTargetKey = key
            end
        end
        ImGui.EndCombo()
    end
    if Settings.suggestTargetKey ~= old then
        SaveSettings()
        invalidate_caches()
    end
end

local function draw_scope_picker()
    ImGui.Text("Scope:")
    ImGui.SameLine()
    ImGui.SetNextItemWidth(120.0)
    if ImGui.BeginCombo("##suggest_scope", scope_label()) then
        for _, opt in ipairs(SOURCE_SCOPES) do
            if ImGui.Selectable(opt.label .. "##suggest_scope_" .. opt.key, Settings.suggestSourceScope == opt.key) then
                Settings.suggestSourceScope = opt.key
                Settings.suggestTargetKey = normalize_suggest_target_key(Settings.suggestTargetKey)
                cfg.apply_linked_roster_scope(opt.key, "suggestions")
                SaveSettings()
                invalidate_caches()
            end
        end
        ImGui.EndCombo()
    end
    ImGui.SameLine()
    if toggle_button("Link Scope##suggest_link_scope", Settings.syncRosterScopeAcrossTabs == true) then
        Settings.syncRosterScopeAcrossTabs = not (Settings.syncRosterScopeAcrossTabs == true)
        if Settings.syncRosterScopeAcrossTabs then
            cfg.apply_linked_roster_scope(Settings.suggestSourceScope or "all", "suggestions")
        end
        SaveSettings()
        invalidate_caches()
    end
end

local function draw_location_picker()
    ImGui.Text("Location:")
    ImGui.SameLine()
    ImGui.SetNextItemWidth(130.0)
    if ImGui.BeginCombo("##suggest_location", location_label()) then
        for _, opt in ipairs(LOCATION_FILTERS) do
            if ImGui.Selectable(opt.label .. "##suggest_loc_" .. opt.key, Settings.suggestLocationFilter == opt.key) then
                Settings.suggestLocationFilter = opt.key
                SaveSettings()
                invalidate_caches()
            end
        end
        ImGui.EndCombo()
    end
end

local function reset_compare_stats()
    Settings.suggestCompareStats = { "ac" }
    Settings.suggestComparePrimary = "ac"
    Settings.suggestCompareStat = "ac"
    SaveSettings()
    invalidate_caches()
end

local function draw_compare_stat_picker()
    ImGui.Text("Compare:")
    ImGui.SameLine()
    ImGui.SetNextItemWidth(170.0)
    if ImGui.SetNextWindowSizeConstraints then
        pcall(ImGui.SetNextWindowSizeConstraints, 260.0, 340.0, 420.0, 620.0)
    end
    local combo_open = ImGui.BeginCombo("##suggest_compare_stat", compare_picker_label())
    if combo_open then
        local keys = compare_stat_keys()
        local key_set = {}
        for _, k in ipairs(keys) do key_set[k] = true end
        for _, opt in ipairs(COMPARE_STATS) do
            local checked = key_set[opt.key] == true
            local rv1, rv2 = ImGui.Checkbox(opt.label .. "##suggest_cmp_chk_" .. opt.key, checked)
            local new_checked, changed = checked, false
            if type(rv2) == "boolean" then
                new_checked, changed = rv1, rv2
            elseif type(rv1) == "boolean" and rv1 ~= checked then
                new_checked, changed = rv1, true
            end
            local blocked_msg = nil
            if changed then
                if new_checked then
                    if #keys >= MAX_COMPARE_STATS then
                        blocked_msg = string.format("Max %d stats selected.", MAX_COMPARE_STATS)
                    else
                        keys[#keys + 1] = opt.key
                        key_set[opt.key] = true
                        Settings.suggestCompareStats = keys
                        if #keys == 1 then Settings.suggestComparePrimary = opt.key end
                        Settings.suggestCompareStat = Settings.suggestComparePrimary
                        SaveSettings()
                        invalidate_caches()
                    end
                elseif #keys > 1 then
                    local new_keys = {}
                    for _, k in ipairs(keys) do
                        if k ~= opt.key then new_keys[#new_keys + 1] = k end
                    end
                    key_set[opt.key] = nil
                    Settings.suggestCompareStats = new_keys
                    keys = new_keys
                    if Settings.suggestComparePrimary == opt.key then
                        Settings.suggestComparePrimary = new_keys[1]
                    end
                    Settings.suggestCompareStat = Settings.suggestComparePrimary
                    SaveSettings()
                    invalidate_caches()
                else
                    blocked_msg = "At least one compare stat required."
                end
            end
            if blocked_msg then
                ImGui.SameLine()
                ImGui.TextDisabled(blocked_msg)
            end
            local active = key_set[opt.key] == true
            if active then
                local is_primary = compare_primary_key() == opt.key
                ImGui.SameLine()
                if is_primary then
                    col_text(Theme.green or Theme.valueTop, "primary")
                elseif ImGui.SmallButton and ImGui.SmallButton("Set primary##suggest_cmp_pri_" .. opt.key) then
                    Settings.suggestComparePrimary = opt.key
                    Settings.suggestCompareStat = opt.key
                    SaveSettings()
                    invalidate_caches()
                end
            end
        end
        ImGui.Separator()
        ImGui.TextDisabled(string.format("%d / %d selected", #compare_stat_keys(), MAX_COMPARE_STATS))
        ImGui.EndCombo()
    end
    ImGui.SameLine()
    if themed_button("Clear##suggest_cmp_clear", Theme.steel) then
        reset_compare_stats()
    end
    if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
        ImGui.SetTooltip("Reset compare to AC only.")
    end
end

local function draw_whatif_slot_picker()
    local slot_id = tonumber(Settings.suggestWhatIfSlotId) or tonumber(Settings.suggestSlotId) or 2
    ImGui.SetNextItemWidth(120.0)
    if ImGui.BeginCombo("##suggest_whatif_slot", slot_label(slot_id)) then
        for _, opt in ipairs(SLOT_OPTIONS) do
            if ImGui.Selectable(opt.label .. "##whatif_slot_" .. tostring(opt.id), slot_id == opt.id) then
                Settings.suggestWhatIfSlotId = opt.id
                SaveSettings()
            end
        end
        ImGui.EndCombo()
    end
end

local function draw_whatif_panel()
    local open = Settings.suggestWhatIfOpen == true
    if ImGui.CollapsingHeader then
        local _, toggled = ImGui.CollapsingHeader("Who Should Get This?##suggest_whatif", open)
        if toggled ~= nil then
            Settings.suggestWhatIfOpen = toggled and true or false
            SaveSettings()
            open = Settings.suggestWhatIfOpen == true
        end
    else
        col_text(Theme.section or Theme.header, "Who Should Get This?")
    end
    if ImGui.CollapsingHeader and not open then return end

    col_text(Theme.dim, "Check one item against every character in scope. Results are sorted by best upgrade first.")
    ImGui.SetNextItemWidth(240.0)
    Settings.suggestWhatIfItem = input_text_hint("##suggest_whatif_item", "Item name or ID", Settings.suggestWhatIfItem or "")
    ImGui.SameLine()
    draw_whatif_slot_picker()
    ImGui.SameLine()
    if themed_button("Use Cursor Item##suggest_whatif_cursor", Theme.sync) then
        local cur = mq.TLO.Cursor
        if cur and cur() then
            Settings.suggestWhatIfItem = cur.Name() or ""
            whatif_status = "Captured cursor item: " .. tostring(Settings.suggestWhatIfItem)
            SaveSettings()
        else
            whatif_status = "No item on cursor."
        end
    end

    local slot_id = tonumber(Settings.suggestWhatIfSlotId) or tonumber(Settings.suggestSlotId) or 2
    local raw = tostring(Settings.suggestWhatIfItem or ""):match("^%s*(.-)%s*$") or ""
    if raw == "" then
        if whatif_status ~= "" then col_text(Theme.dim, whatif_status) end
        return
    end

    local item_id = tonumber(raw) or 0
    local item_name = item_id > 0 and "" or raw
    local stat_keys = compare_stat_keys()
    local rows, candidate = suggestions.whatif_targets(item_id, item_name, slot_id, Settings.suggestSourceScope or "all", stat_keys)
    if not candidate then
        col_text(Theme.amber, "Could not evaluate item.")
        return
    end

    col_text(Theme.dim, string.format("%s in %s | %d character(s) | sorted by %s delta",
        candidate.name or "?", slot_label(slot_id), #rows, compare_stat_short_label(compare_primary_key())))
    if whatif_status ~= "" then col_text(Theme.dim, whatif_status) end

    if #rows == 0 then
        col_text(Theme.placeholder or Theme.dim, "No characters in the current scope.")
        return
    end

    local col_count = 3 + #stat_keys
    local flags = (ImGuiTableFlags.BordersInnerV or 0)
        + (ImGuiTableFlags.RowBg or 0)
        + (ImGuiTableFlags.ScrollY or 0)
        + (ImGuiTableFlags.Resizable or 0)
    ImGui.BeginChild("suggest_whatif_wrap", 0, math.min(260.0, 28.0 + #rows * 22.0), false)
    if ImGui.BeginTable("suggest_whatif", col_count, flags) then
        ImGui.TableSetupColumn("Character", ImGuiTableColumnFlags.WidthStretch, 1.4)
        ImGui.TableSetupColumn("Worn", ImGuiTableColumnFlags.WidthStretch, 1.6)
        for _, key in ipairs(stat_keys) do
            ImGui.TableSetupColumn(compare_stat_short_label(key), ImGuiTableColumnFlags.WidthFixed, 58.0)
        end
        ImGui.TableSetupColumn("Result", ImGuiTableColumnFlags.WidthFixed, 72.0)
        ImGui.TableHeadersRow()
        for _, rec in ipairs(rows) do
            ImGui.TableNextRow()
            ImGui.TableSetColumnIndex(0)
            local cls = views.class_abbrev(rec.class or "")
            local label = cls ~= "" and string.format("%s (%s)", rec.name or "?", cls) or (rec.name or "?")
            col_text(rec.status == "online" and Theme.online or Theme.dim, label)
            ImGui.TableSetColumnIndex(1)
            local cur = rec.current
            if cur and cur.name and cur.name ~= "" then
                item_actions.draw_name(cur.name, Theme.item, "whatif_worn_" .. tostring(rec.key), cur.id)
            else
                col_text(Theme.missing or Theme.amber, "(empty)")
            end
            local col_idx = 2
            for _, key in ipairs(stat_keys) do
                ImGui.TableSetColumnIndex(col_idx)
                local delta_text, delta_color = format_delta(rec.deltas and rec.deltas[key])
                col_text(delta_color, delta_text)
                col_idx = col_idx + 1
            end
            ImGui.TableSetColumnIndex(col_idx)
            local result_text, result_color = result_label(rec.primary_delta)
            col_text(result_color, result_text)
        end
        ImGui.EndTable()
    end
    ImGui.EndChild()
end

local function draw_worn_totals_bar(meta)
    local keys = compare_stat_keys()
    if #keys == 0 then return end
    if meta and meta.wornTotalsAvailable == false then
        col_text(Theme.section or Theme.header, "Worn totals: unavailable (offline or lite snapshot — Sync Now for full stats)")
        return
    end
    local totals = meta and meta.wornTotals
    local parts = {}
    for _, key in ipairs(keys) do
        local val = totals and totals[key] or 0
        parts[#parts + 1] = string.format("%s: %s", compare_stat_short_label(key), stat_defs.format_value(key, val))
    end
    col_text(Theme.section or Theme.header, "Worn totals: " .. table.concat(parts, " | "))
end

local function draw_view_mode_picker()
    local cur = Settings.suggestViewMode or "overview"
    local equip_active = cur == "overview" or cur == "detail"
    local aug_active = cur == "aug_overview" or cur == "aug_detail"
    local aug_plan_active = cur == "aug_plan"
    if nav_button("Character##suggest_mode_overview", equip_active, true, 0, 22.0) and not equip_active then
        Settings.suggestViewMode = "overview"
        SaveSettings()
        invalidate_caches()
    end
    ImGui.SameLine()
    if nav_button("Augs##suggest_mode_aug", aug_active, true, 0, 22.0) and not aug_active then
        Settings.suggestViewMode = "aug_overview"
        SaveSettings()
        invalidate_caches()
    end
    ImGui.SameLine()
    if nav_button("Aug Plan##suggest_mode_aug_plan", aug_plan_active, true, 0, 22.0) and not aug_plan_active then
        Settings.suggestViewMode = "aug_plan"
        SaveSettings()
        invalidate_caches()
    end
end

local function draw_shared_filters()
    draw_location_picker()
    ImGui.SameLine()
    draw_compare_stat_picker()
    ImGui.SameLine()
    if is_equip_mode() and (Settings.suggestViewMode == "overview" or Settings.suggestViewMode == "detail") then
        if toggle_button(upgrades_focus_on() and "Filter: Upgrades##suggest_ov_focus" or "Filter: All Slots##suggest_ov_focus", upgrades_focus_on()) then
            Settings.suggestOverviewActionable = not upgrades_focus_on()
            SaveSettings()
            invalidate_caches()
        end
    elseif is_aug_mode() and (Settings.suggestViewMode == "aug_overview" or Settings.suggestViewMode == "aug_detail" or Settings.suggestViewMode == "aug_plan") then
        local plan_mode = Settings.suggestViewMode == "aug_plan"
        local on_label = plan_mode and "Filter: Upgrades##suggest_aug_focus" or "Filter: With Augs##suggest_aug_focus"
        local off_label = plan_mode and "Filter: All Sockets##suggest_aug_focus" or "Filter: All Empty##suggest_aug_focus"
        if toggle_button(upgrades_focus_on() and on_label or off_label, upgrades_focus_on()) then
            Settings.suggestOverviewActionable = not upgrades_focus_on()
            SaveSettings()
            invalidate_caches()
        end
        if plan_mode then
            draw_aug_plan_strength_picker()
        end
    end
    if (Settings.suggestViewMode or "overview") == "detail" then
        ImGui.SameLine()
        if toggle_button(Settings.suggestExcludeSameEquipped and "Filter: Hide Current##suggest_hide_cur" or "Filter: Show Current##suggest_hide_cur", Settings.suggestExcludeSameEquipped ~= false) then
            Settings.suggestExcludeSameEquipped = not (Settings.suggestExcludeSameEquipped ~= false)
            SaveSettings()
            invalidate_caches()
        end
    end
end

local function draw_equipped_cell(slot_rec)
    local eq = slot_rec.equipped
    if not eq or not eq.name or eq.name == "" then
        col_text(Theme.missing or Theme.amber, "(empty)")
        return
    end
    item_actions.draw_name(eq.name, Theme.item, "suggest_ov_eq_" .. tostring(slot_rec.slotId), eq.id)
    local keys = compare_stat_keys()
    local parts = {}
    for _, key in ipairs(keys) do
        local val = (slot_rec.equippedStats and slot_rec.equippedStats[key])
            or (key == compare_primary_key() and slot_rec.equippedStat) or 0
        local bonus = suggestions.aug_stat_bonus(eq, key)
        if val > 0 or bonus ~= 0 then
            local text = compare_stat_compact_label(key) .. " " .. stat_defs.format_value(key, val)
            if bonus ~= 0 then text = text .. " (" .. stat_defs.format_signed_delta(key, bonus) .. " aug)" end
            parts[#parts + 1] = text
        end
    end
    if #parts > 0 then
        col_text(Theme.dim, table.concat(parts, " · "))
    end
end

local function draw_compact_candidate(wrapped, suffix, slot_id)
    if not wrapped then
        col_text(Theme.placeholder or Theme.dim, upgrades_focus_on() and "-" or "none")
        return
    end
    local row = wrapped.row
    item_actions.draw_name(row.name or "?", candidate_color(wrapped), "suggest_ov_" .. suffix .. "_" .. tostring(slot_id), row.id, item_actions.context_opts({
        sourceLocation = compact_location(row),
        targetKey = Settings.suggestTargetKey,
        slotid = slot_id,
        slotname = slot_label(slot_id),
    }, row))
    draw_candidate_result(wrapped, suffix == "alt" and "alt" or "best")
    col_text(theme.location_color(row.locationGroup, row.location), compact_location(row))
end

local function draw_best_pick_cell(slot_rec)
    if not slot_rec.best then
        col_text(Theme.placeholder or Theme.dim, upgrades_focus_on() and "No upgrades" or "No candidates")
        return
    end
    draw_compact_candidate(slot_rec.best, "best", slot_rec.slotId)
end

local function draw_alt_pick_cell(slot_rec)
    draw_compact_candidate(slot_rec.alt, "alt", slot_rec.slotId)
end

local function highlight_upgrade_row(slot_rec)
    if not (slot_rec.upgradeCount and slot_rec.upgradeCount > 0) then return end
    if ImGui.TableSetBgColor and ImGuiTableBgTarget and ImGuiTableBgTarget.RowBg0 and theme.color_u32 then
        pcall(ImGui.TableSetBgColor, ImGuiTableBgTarget.RowBg0, theme.color_u32(SUGGEST_UPGRADE_ROW))
    end
end

local function draw_more_cell(slot_rec)
    local total = slot_rec.totalCount or 0
    if total == 0 then
        ImGui.TextDisabled("-")
        return
    end
    local label = total > 1 and string.format("Details (%d)", total) or "Details"
    if themed_button(label .. "##suggest_ov_all_" .. tostring(slot_rec.slotId), Theme.steel) then
        Settings.suggestSlotId = slot_rec.slotId
        Settings.suggestViewMode = "detail"
        SaveSettings()
        invalidate_caches()
    end
    if slot_rec.upgradeCount and slot_rec.upgradeCount > 0 then
        col_text(Theme.valueTop or Theme.green, string.format("%d upgrade%s", slot_rec.upgradeCount, slot_rec.upgradeCount == 1 and "" or "s"))
    end
end

local function open_detail_for_slot(slot_id)
    Settings.suggestSlotId = slot_id
    Settings.suggestViewMode = "detail"
    SaveSettings()
    invalidate_caches()
end

local function transfer_detail_status(action)
    if not action then return nil end
    local label = tostring(action.label or "")
    local reason = tostring(action.reason or ""):lower()
    if label == "Owned" or reason:find("already owned", 1, true) then
        return "Owned", Theme.value or Theme.green
    end
    if reason:find("no%-drop", 1, false)
        or reason:find("attuned", 1, true)
        or reason:find("cannot be handed", 1, true)
        or reason:find("cannot be traded", 1, true) then
        return "No trade", Theme.missing or Theme.brick
    end
    if reason:find("offline", 1, true) or reason:find("cache", 1, true) then
        return "Offline", Theme.offline or Theme.dim
    end
    if reason:find("stale", 1, true) then
        return "Stale", Theme.amber or Theme.gold
    end
    if reason:find("same zone", 1, true) or reason:find("zone", 1, true) then
        return "Need zone", Theme.amber or Theme.gold
    end
    if reason:find("snapshot", 1, true) or reason:find("sync", 1, true) then
        return "Sync", Theme.amber or Theme.gold
    end
    if reason:find("bank", 1, true) then
        return "Bank", Theme.bank or Theme.purple
    end
    if reason:find("equipped", 1, true) or reason:find("installed", 1, true) then
        return "Installed", Theme.amber or Theme.gold
    end
    if reason:find("class", 1, true) then
        return "Verify", Theme.amber or Theme.gold
    end
    if label ~= "" and label ~= "Details" and label ~= "Blocked" then
        return label, Theme.dim
    end
    return nil
end

local function draw_transfer_action_cell(action, suffix, details_slot_id, total_count)
    if not action then
        ImGui.TextDisabled("-")
        return
    end
    if action.detailOnly then
        local status, status_color = transfer_detail_status(action)
        if status then
            col_text(status_color, status)
            ImGui.SameLine()
        end
        if themed_button("Details##tg_suggest_details_" .. tostring(suffix), Theme.steel, 76, 0) then
            open_detail_for_slot(details_slot_id)
        end
        if action.reason and action.reason ~= "" and ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
            ImGui.SetTooltip(action.reason)
        end
        return
    end

    local color = action.enabled and (action.queueOnly and (Theme.amber or Theme.gold) or (Theme.sync or Theme.green))
        or (Theme.steel or Theme.dim)
    if themed_button((action.label or "Action") .. "##tg_suggest_action_" .. tostring(suffix), color, 104, 0) then
        run_transfer_action(action)
    end
    if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
        if action.reason and action.reason ~= "" then
            ImGui.SetTooltip(action.reason)
        else
            ImGui.SetTooltip(string.format("%s %s from %s to %s",
                tostring(action.label or "Action"), tostring(action.item or "item"),
                tostring(action.owner or "?"), tostring(action.recipient or "?")))
        end
    end
    if total_count and total_count > 1 then
        ImGui.SameLine()
        if themed_button("Details##tg_suggest_details_" .. tostring(suffix), Theme.steel, 68, 0) then
            open_detail_for_slot(details_slot_id)
        end
        if action.reason and action.reason ~= "" and ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
            ImGui.SetTooltip(action.reason)
        end
    end
end

local function overview_row_visible(slot_rec)
    if Settings.suggestOverviewActionable ~= true then return true end
    if slot_rec.upgradeCount and slot_rec.upgradeCount > 0 then return true end
    if not slot_rec.equipped or not slot_rec.equipped.name or slot_rec.equipped.name == "" then
        return (slot_rec.totalCount or 0) > 0
    end
    return false
end

local function preferred_action_candidate(slot_rec)
    for _, cand in ipairs((slot_rec and slot_rec.candidates) or {}) do
        local class_key = candidate_classification(cand, slot_rec.equipped)
        if class_key == "upgrade" or class_key == "fill" then return cand end
    end
    return slot_rec and slot_rec.best or nil
end

local function overview_counts(slots)
    local counts = { upgrade = 0, fill = 0, sidegrade = 0, best = 0, blocked = 0 }
    for _, slot_rec in ipairs(slots or {}) do
        if overview_row_visible(slot_rec) then
            local cand = preferred_action_candidate(slot_rec)
            local class_key = candidate_classification(cand, slot_rec.equipped)
            if counts[class_key] ~= nil then counts[class_key] = counts[class_key] + 1 end
            local action = build_transfer_action(nil, cand, slot_rec.slotId, slot_rec.equipped)
            if action and not action.detailOnly and not action.enabled then counts.blocked = counts.blocked + 1 end
        end
    end
    return counts
end

local function draw_overview(slots, meta)
    local shown = 0
    local last_group = nil
    local counts = overview_counts(slots)
    col_text(Theme.dim, string.format("Actionable: %d upgrade%s, %d empty-slot fill%s | Informational: %d sidegrade%s, %d best-known",
        counts.upgrade, counts.upgrade == 1 and "" or "s",
        counts.fill, counts.fill == 1 and "" or "s",
        counts.sidegrade, counts.sidegrade == 1 and "" or "s",
        counts.best))
    if counts.blocked > 0 then
        ImGui.SameLine()
        col_text(Theme.amber or Theme.gold, string.format("| %d blocked", counts.blocked))
    end

    if views.begin_scroll_table("SuggestOverview", 5, views.scroll_table_flags(), 52.0, 180.0) then
        ImGui.TableSetupColumn("Slot", ImGuiTableColumnFlags.WidthFixed, 88.0)
        ImGui.TableSetupColumn("Equipped", ImGuiTableColumnFlags.WidthStretch, 1.2)
        ImGui.TableSetupColumn("Best Pick", ImGuiTableColumnFlags.WidthStretch, 1.5)
        ImGui.TableSetupColumn("Alt Pick", ImGuiTableColumnFlags.WidthStretch, 1.5)
        ImGui.TableSetupColumn("Action", ImGuiTableColumnFlags.WidthFixed, 184.0)
        pcall(function() ImGui.TableSetupScrollFreeze(0, 1) end)
        views.table_headers_centered({ "Slot", "Equipped", "Best Pick", "Alt Pick", "Action" })

        for _, slot_rec in ipairs(slots or {}) do
            if overview_row_visible(slot_rec) then
                if slot_rec.group ~= last_group then
                    last_group = slot_rec.group
                    views.draw_section_row(slot_rec.group or "Slots", 5)
                end
                shown = shown + 1
                ImGui.TableNextRow()
                highlight_upgrade_row(slot_rec)
                ImGui.TableSetColumnIndex(0)
                col_text(Theme.slot, slot_rec.label or "?")
                ImGui.TableSetColumnIndex(1)
                draw_equipped_cell(slot_rec)
                ImGui.TableSetColumnIndex(2)
                draw_best_pick_cell(slot_rec)
                ImGui.TableSetColumnIndex(3)
                draw_alt_pick_cell(slot_rec)
                ImGui.TableSetColumnIndex(4)
                local cand = preferred_action_candidate(slot_rec)
                draw_transfer_action_cell(build_transfer_action(meta, cand, slot_rec.slotId, slot_rec.equipped),
                    "ov_" .. tostring(slot_rec.slotId), slot_rec.slotId, slot_rec.totalCount)
            end
        end
        ImGui.EndTable()
    end

    if shown == 0 then
        col_text(Theme.placeholder or Theme.dim, upgrades_focus_on()
            and "No actionable slots. Turn off Actionable to see the full worn layout."
            or "No slot data for this character.")
    end
end

local function draw_detail_slot_picker()
    ImGui.Text("Slot:")
    ImGui.SameLine()
    ImGui.SetNextItemWidth(150.0)
    if ImGui.BeginCombo("##suggest_slot", slot_label(Settings.suggestSlotId)) then
        local last_group = nil
        for _, slot in ipairs(SLOT_OPTIONS) do
            if slot.group ~= last_group then
                last_group = slot.group
                ImGui.TextDisabled(slot.group or "")
            end
            if ImGui.Selectable(slot.label .. "##suggest_slot_" .. tostring(slot.id), Settings.suggestSlotId == slot.id) then
                Settings.suggestSlotId = slot.id
                SaveSettings()
                invalidate_caches()
            end
        end
        ImGui.EndCombo()
    end
end

local function set_sort(key, default_desc)
    if (Settings.suggestSortKey or "upgrade") == key then
        Settings.suggestSortDesc = not (Settings.suggestSortDesc ~= false)
    else
        Settings.suggestSortKey = key
        Settings.suggestSortDesc = default_desc ~= false
    end
    SaveSettings()
    detail_key = nil
end

local function sort_label(label, key)
    if (Settings.suggestSortKey or "upgrade") ~= key then return label end
    return label .. (Settings.suggestSortDesc ~= false and " v" or " ^")
end

local function draw_detail_headers()
    ImGui.TableNextRow()
    ImGui.TableSetColumnIndex(0)
    if ImGui.Selectable(sort_label("Item", "item") .. "##suggest_sort_item", false) then set_sort("item", false) end
    ImGui.TableSetColumnIndex(1)
    if ImGui.Selectable(sort_label(delta_label(), "upgrade") .. "##suggest_sort_upgrade", false) then set_sort("upgrade", true) end
    ImGui.TableSetColumnIndex(2)
    if ImGui.Selectable(sort_label("Owner", "owner") .. "##suggest_sort_owner", false) then set_sort("owner", false) end
    ImGui.TableSetColumnIndex(3)
    if ImGui.Selectable(sort_label("Location", "location") .. "##suggest_sort_location", false) then set_sort("location", false) end
    ImGui.TableSetColumnIndex(4)
    ImGui.Text("Action")
end

local function draw_detail_rows(wrapped_rows)
    local total = #(wrapped_rows or {})
    local limit = Settings.suggestShowAllRows and total or math.min(total, Settings.suggestRowLimit or 200)
    if views.begin_scroll_table("SuggestRows", 5, views.scroll_table_flags(), 56.0, 180.0) then
        ImGui.TableSetupColumn("Item", ImGuiTableColumnFlags.WidthStretch, 1.8)
        ImGui.TableSetupColumn(delta_label(), ImGuiTableColumnFlags.WidthStretch, 2.4)
        ImGui.TableSetupColumn("Owner", ImGuiTableColumnFlags.WidthFixed, 88.0)
        ImGui.TableSetupColumn("Location", ImGuiTableColumnFlags.WidthStretch, 1.0)
        ImGui.TableSetupColumn("Action", ImGuiTableColumnFlags.WidthFixed, 132.0)
        pcall(function() ImGui.TableSetupScrollFreeze(0, 1) end)
        draw_detail_headers()

        for i = 1, limit do
            local wrapped = wrapped_rows[i]
            local row = wrapped.row
            ImGui.TableNextRow()

            ImGui.TableSetColumnIndex(0)
            local key = row_key(row)
            if ImGui.SmallButton and ImGui.SmallButton("i##suggest_select_" .. tostring(i) .. "_" .. key) then
                selected_detail_key = key
                selected_detail_row = row
            end
            if ImGui.SmallButton then ImGui.SameLine() end
            item_actions.draw_name(row.name or "?", candidate_color(wrapped), "suggest_item_" .. tostring(i) .. "_" .. tostring(row.sourceKey or ""), row.id, item_actions.context_opts({
                sourceLocation = compact_location(row),
                targetKey = Settings.suggestTargetKey,
                slotid = Settings.suggestSlotId,
                slotname = slot_label(Settings.suggestSlotId),
            }, row))

            ImGui.TableSetColumnIndex(1)
            draw_detail_result_cell(wrapped)

            ImGui.TableSetColumnIndex(2)
            col_text(theme.report_owner_color(), owner_label(row))

            ImGui.TableSetColumnIndex(3)
            col_text(theme.location_color(row.locationGroup, row.location), compact_location(row))

            ImGui.TableSetColumnIndex(4)
            draw_transfer_action_cell(build_transfer_action(detail_meta, wrapped, Settings.suggestSlotId, detail_meta and detail_meta.currentEquipped),
                "detail_" .. tostring(i) .. "_" .. key, Settings.suggestSlotId, nil)
        end

        ImGui.EndTable()
    end
end

local function draw_candidate_delta_panel(meta)
    local row = selected_detail_row
    if not row or row_key(row) ~= selected_detail_key then return end
    local current = meta and meta.currentEquipped
    local keys = compare_stat_keys()
    local primary = compare_primary_key()

    ImGui.Separator()
    col_text(Theme.dim, "Selected:")
    ImGui.SameLine()
    local primary_delta = suggestions.upgrade_delta(row, current, primary, M.EQUIP_REPLACE_STATS)
    item_actions.draw_name(row.name or "?", candidate_color({ delta = primary_delta }), "suggest_selected_candidate", row.id, item_actions.context_opts({
        sourceLocation = compact_location(row),
        targetKey = Settings.suggestTargetKey,
        slotid = Settings.suggestSlotId,
        slotname = slot_label(Settings.suggestSlotId),
    }, row))
    ImGui.SameLine()
    col_text(theme.location_color(row.locationGroup, row.location), compact_location(row))

    col_text(Theme.dim, "Worn:")
    ImGui.SameLine()
    if current and current.name and current.name ~= "" then
        item_actions.draw_name(current.name, Theme.item, "suggest_selected_current", current.id)
    else
        col_text(Theme.placeholder or Theme.dim, "(empty)")
    end
    ImGui.SameLine()
    col_text(Theme.dim, compare_stat_compact_label(primary))
    ImGui.SameLine(0, 4)
    draw_result_inline(primary_delta)
    ImGui.SameLine()
    col_text(Theme.dim, string.format("| candidate %s / worn %s",
        stat_defs.format_value(primary, suggestions.stat_value(row, primary, M.EQUIP_REPLACE_STATS)),
        stat_defs.format_value(primary, suggestions.stat_value(current, primary, M.EQUIP_REPLACE_STATS))))

    if #keys > 1 then
        local sec_deltas = {}
        for _, key in ipairs(keys) do
            if key ~= primary then
                sec_deltas[key] = suggestions.upgrade_delta(row, current, key, M.EQUIP_REPLACE_STATS)
            end
        end
        local also = format_secondary_also_line({ deltas = sec_deltas }, true)
        if also ~= "" then
            col_text(Theme.dim, "Also: " .. also)
        end
    end

    local req = tonumber(row.requiredLevel) or 0
    local rec = tonumber(row.recommendedLevel) or 0
    if req > 0 or rec > 0 then
        col_text(Theme.dim, string.format("Level req %d / rec %d", req, rec))
    end
end

local function aug_controls_key(index_version, mode)
    return shared_controls_key(index_version, mode)
        .. "\1" .. tostring(aug_search_text or "")
        .. "\1" .. tostring(aug_plan_reject_serial)
end

local function visible_aug_overview()
    local _, index_version = item_index.get(false)
    local key = aug_controls_key(index_version, "aug_overview")
    if aug_overview_key == key then return aug_overview_rows, aug_overview_meta end

    return M._diag.time("ui.suggestions.visible_aug_overview", function()
        local rows, meta = aug_suggestions.build_overview({
            targetKey = Settings.suggestTargetKey,
            scope = Settings.suggestSourceScope,
            locationFilter = Settings.suggestLocationFilter,
            compareStat = compare_stat_key(),
            actionableOnly = upgrades_focus_on(),
            topN = 2,
            rejectedKeys = aug_plan_rejects,
        })
        aug_overview_rows = rows
        aug_overview_meta = meta
        aug_overview_key = key
        return aug_overview_rows, aug_overview_meta
    end)
end

local function visible_aug_plan()
    local _, index_version = item_index.get(false)
    local key = aug_controls_key(index_version, "aug_plan")
        .. "\1" .. table.concat(compare_stat_keys(), ",")
        .. "\1" .. tostring(Settings.suggestAugPlanStrength or "any")
        .. "\1" .. tostring(aug_plan_reject_serial)
    if aug_plan_key == key then return aug_plan_rows, aug_plan_meta end

    return M._diag.time("ui.suggestions.visible_aug_plan", function()
        local rows, meta = aug_suggestions.build_plan({
            targetKey = Settings.suggestTargetKey,
            scope = Settings.suggestSourceScope,
            locationFilter = Settings.suggestLocationFilter,
            compareStat = compare_stat_key(),
            compareStats = compare_stat_keys(),
            strength = Settings.suggestAugPlanStrength or "any",
            actionableOnly = upgrades_focus_on(),
            topN = Settings.suggestShowAllRows and 80 or 40,
            rejectedKeys = aug_plan_rejects,
        })
        aug_plan_rows = rows
        aug_plan_meta = meta
        aug_plan_key = key
        return aug_plan_rows, aug_plan_meta
    end)
end

local function visible_aug_detail()
    local _, index_version = item_index.get(false)
    local key = aug_controls_key(index_version, "aug_detail") .. "\1" .. table.concat({
        tostring(Settings.suggestAugSocketType or ""),
        tostring(Settings.suggestAugSocketIndex or ""),
        tostring(Settings.suggestAugHostItem or ""),
    }, "\1")
    if aug_detail_key == key then return aug_detail_rows, aug_detail_meta end

    return M._diag.time("ui.suggestions.visible_aug_detail", function()
        local rows, meta = aug_suggestions.get_available({
            targetKey = Settings.suggestTargetKey,
            socketType = Settings.suggestAugSocketType,
            scope = Settings.suggestSourceScope,
            locationFilter = Settings.suggestLocationFilter,
            compareStat = compare_stat_key(),
            search = aug_search_text,
        })
        aug_detail_rows = rows
        aug_detail_meta = meta
        aug_detail_key = key
        return aug_detail_rows, aug_detail_meta
    end)
end

local function aug_summary_text(summary)
    if type(summary) ~= "table" then return "" end
    local types = {}
    for _, stype in ipairs(summary.socketTypes or {}) do types[#types + 1] = "T" .. tostring(stype) end
    local type_text = #types > 0 and table.concat(types, ",") or "none"
    return string.format("Loose aug check: %d indexed | %d match empty socket types (%s) | %d class confirmed | %d verify class | %d level | %d scope | %d location | %d tradeable",
        summary.loose or 0,
        summary.socket or 0,
        type_text,
        summary.class or 0,
        summary.classWarning or 0,
        summary.level or 0,
        summary.scope or 0,
        summary.location or 0,
        summary.tradeable or 0)
end

local function aug_plan_funnel_text(meta)
    if type(meta) ~= "table" then return "" end
    local summary = meta.looseSummary or {}
    local pairs = meta.pairSummary or {}
    local types = {}
    for _, stype in ipairs(summary.socketTypes or {}) do types[#types + 1] = "T" .. tostring(stype) end
    local type_text = #types > 0 and table.concat(types, ",") or "none"
    return string.format(
        "Aug plan check: %d loose augs indexed | sockets need %s | %d socket-fit pairs | %d pass level | %d pass scope | %d pass location | %d movable | %d no-drop blocked | %d positive by %s",
        summary.loose or 0,
        type_text,
        pairs.socketPairs or 0,
        pairs.levelPairs or 0,
        pairs.scopePairs or 0,
        pairs.locationPairs or 0,
        pairs.tradeablePairs or 0,
        pairs.noDropBlockedPairs or summary.noDropBlocked or 0,
        pairs.positivePairs or 0,
        compare_stats_summary())
end

function M.aug_plan_empty_reason(meta)
    if type(meta) ~= "table" then return "" end
    local pairs = meta.pairSummary or {}
    local socket_pairs = tonumber(pairs.socketPairs) or 0
    local movable = tonumber(pairs.tradeablePairs) or 0
    local no_drop = tonumber(pairs.noDropBlockedPairs) or 0
    local rejected = tonumber(pairs.rejectedPairs) or 0
    local positive = tonumber(pairs.positivePairs) or 0
    if socket_pairs > 0 and movable == 0 and no_drop > 0 then
        return string.format("No movable aug upgrades. %d matching aug%s blocked because they are no-drop/attuned on other characters.",
            no_drop, no_drop == 1 and " is" or "s are")
    end
    if movable > 0 and positive == 0 then
        return "Movable augs were found, but none improve the selected compare stats under the current filters."
    end
    if rejected > 0 then
        return string.format("%d candidate%s hidden by temporary aug-plan skips.",
            rejected, rejected == 1 and " is" or "s are")
    end
    return ""
end

function M.draw_blocked_aug_examples(meta)
    if type(meta) ~= "table" or type(meta.pairSummary) ~= "table" then return end
    local examples = meta.pairSummary.blockedExamples
    if type(examples) ~= "table" or #examples == 0 then return end
    col_text(Theme.dim, "Blocked aug matches:")
    for _, ex in ipairs(examples) do
        col_text(Theme.amber or Theme.gold, string.format("  %s on %s -> %s T%d",
            tostring(ex.name or "?"),
            tostring(ex.owner or "?"),
            tostring(ex.slot or "?"),
            tonumber(ex.socketType) or 0))
    end
end

local function draw_aug_candidate(wrapped, suffix, sock_id)
    if not wrapped then
        col_text(Theme.placeholder or Theme.dim, "-")
        return
    end
    local row = wrapped.row
    item_actions.draw_name(row.name or "?", Theme.aug or Theme.green, "suggest_aug_" .. suffix .. "_" .. tostring(sock_id), row.id, item_actions.context_opts({
        sourceLocation = compact_location(row),
    }, row))
    draw_aug_stat_values(row, Theme.value or Theme.green)
    if wrapped.classWarning and wrapped.classWarning ~= "" then
        col_text(Theme.amber or Theme.gold, "Verify class")
        if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
            ImGui.SetTooltip(wrapped.classWarning)
        end
    end
    col_text(theme.location_color(row.locationGroup, row.location), compact_location(row))
end

local function aug_socket_text(sock_rec)
    if not sock_rec then
        return string.format("%s S%d T%d",
            slot_label(Settings.suggestAugSlotId),
            Settings.suggestAugSocketIndex or 0,
            Settings.suggestAugSocketType or 0)
    end
    return string.format("%s S%d T%d",
        sock_rec.slotLabel or slot_label(sock_rec.slotId),
        sock_rec.socketIndex or 0,
        sock_rec.socketType or 0)
end

local function open_aug_detail_for_socket(sock_rec)
    if not sock_rec then return end
    Settings.suggestAugHostItem = sock_rec.hostItem or ""
    Settings.suggestAugHostId = sock_rec.hostItemId or 0
    Settings.suggestAugSlotId = sock_rec.slotId
    Settings.suggestAugSocketIndex = sock_rec.socketIndex
    Settings.suggestAugSocketType = sock_rec.socketType
    Settings.suggestViewMode = "aug_detail"
    SaveSettings()
    invalidate_caches()
end

local function current_aug_socket_rec()
    return {
        slotId = Settings.suggestAugSlotId,
        slotLabel = slot_label(Settings.suggestAugSlotId),
        hostItem = Settings.suggestAugHostItem,
        hostItemId = Settings.suggestAugHostId,
        socketIndex = Settings.suggestAugSocketIndex,
        socketType = Settings.suggestAugSocketType,
    }
end

local function build_aug_transfer_action(meta, wrapped, sock_rec)
    local row = wrapped and wrapped.row
    if not row then return { label = "Details", enabled = false, detailOnly = true, reason = "No aug candidate." } end
    local recipient = target_name(meta)
    local bucket = suggestions.location_bucket(row)
    local stat = compare_stat_compact_label(compare_primary_key())
    local stat_val = tonumber(wrapped.stat) or 0
    local socket_text = aug_socket_text(sock_rec)
    local result_label = (sock_rec and sock_rec.currentAug) and "Replace aug" or "Fill empty aug socket"
    local action = {
        item = row.name or "?",
        id = row.id,
        owner = row.owner or "?",
        recipient = recipient,
        location = compact_location(row),
        slot = socket_text .. ((sock_rec and sock_rec.hostItem and sock_rec.hostItem ~= "") and (" on " .. sock_rec.hostItem) or ""),
        result = result_label .. (stat_val > 0 and (" (" .. stat .. " " .. stat_defs.format_value(compare_primary_key(), stat_val) .. ")") or ""),
        mode = "live Give Now moves the loose aug; it does not install the aug.",
        warning = wrapped.classWarning,
        opts = {
            id = row.id,
            owner = row.owner,
            sourceLocation = compact_location(row),
            locationGroup = row.locationGroup,
            where = row.where,
            nodrop = row.nodrop,
            attuned = row.attuned,
            attunable = row.attunable,
        },
    }

    action = action_guarded_by_source(action, row, recipient)
    if action.detailOnly and action.label == "Owned" then
        action.reason = "Loose aug is already owned by " .. tostring(recipient or "target") .. "; install it in " .. socket_text .. " manually."
        return action
    end
    if action.enabled then
        if bucket == "bank" and row.id and item_actions.bank_give_now_available(row.id, row.owner, recipient, action.opts) then
            action.bankGive = true
            action.queueOnly = false
            action.reason = ""
            action.mode = "pull from bank, then live trade via configured transport; no INI rule written."
            action.label = "Bank + Give"
        elseif row.id and item_actions.give_now_available(row.id, row.owner, recipient, action.opts) then
            action.liveGive = true
            action.mode = "live trade now via configured transport; no INI rule written."
            action.label = "Give"
        else
            action.label = "Details"
            action.detailOnly = true
            action.reason = action.reason ~= "" and action.reason
                or (bucket == "bank"
                    and "Bring source and recipient to the same zone; source must be able to open a banker for Bank + Give."
                    or "Bring the source and recipient to the same zone with the aug in bags, then use Give Now.")
        end
    end
    return action
end

local function run_aug_transfer_action(action)
    if not action or not action.item then return end
    if action.detailOnly then return false end
    if not action.enabled then
        item_actions.show_action_notice("TurboGear Aug Transfer Blocked", transfer_lines(action))
        return false
    end
    local lines = transfer_lines(action)
    lines[#lines + 1] = "After Give Now moves the aug, install it into the listed socket manually."
    if action.bankGive then
        lines[#lines] = "After Bank + Give moves the aug, install it into the listed socket manually."
        lines[#lines + 1] = "Source must be online, same zone, and able to open a banker."
        lines[#lines + 1] = "TurboGive verifies the exact bank aug ID before moving it."
        return item_actions.bank_give_now_action(
            action.item,
            action.id,
            action.owner,
            action.recipient,
            action.opts,
            lines
        )
    elseif action.liveGive then
        return item_actions.give_now_action(
            action.item,
            action.id,
            action.owner,
            action.recipient,
            action.opts,
            lines
        )
    end
    item_actions.show_action_notice("TurboGear Aug Transfer Blocked", lines)
    return false
end

local function aug_plan_pair_reject_key(meta, pair)
    local sock = pair and pair.socket
    local row = pair and pair.aug and pair.aug.row
    return aug_suggestions.plan_reject_key((meta and meta.targetKey) or Settings.suggestTargetKey, sock, row)
end

local function reject_aug_plan_pair(meta, pair)
    local key = aug_plan_pair_reject_key(meta, pair)
    if not key or key == "" then return end
    aug_plan_rejects[key] = true
    aug_plan_reject_serial = aug_plan_reject_serial + 1
    aug_overview_key = nil
    aug_plan_key = nil
end

local function reject_aug_candidate(meta, sock, wrapped)
    local row = wrapped and wrapped.row
    local key = aug_suggestions.plan_reject_key((meta and meta.targetKey) or Settings.suggestTargetKey, sock, row)
    if not key or key == "" then return end
    aug_plan_rejects[key] = true
    aug_plan_reject_serial = aug_plan_reject_serial + 1
    aug_overview_key = nil
    aug_detail_key = nil
    aug_plan_key = nil
end

local function highlight_aug_row(sock_rec)
    if not (sock_rec.totalCount and sock_rec.totalCount > 0) then return end
    if ImGui.TableSetBgColor and ImGuiTableBgTarget and ImGuiTableBgTarget.RowBg0 and theme.color_u32 then
        pcall(ImGui.TableSetBgColor, ImGuiTableBgTarget.RowBg0, theme.color_u32(SUGGEST_UPGRADE_ROW))
    end
end

local function action_status_label(action)
    if not action then return "-", Theme.placeholder or Theme.dim end
    if action.bankGive then return "Ready bank", Theme.sync or Theme.green end
    if action.liveGive then return "Ready", Theme.sync or Theme.green end
    local label = tostring(action.label or "")
    local reason = tostring(action.reason or ""):lower()
    if label == "Owned" or reason:find("already owned", 1, true) then
        return "Owned", Theme.value or Theme.green
    end
    if reason:find("no%-drop", 1, false) or reason:find("cannot be handed", 1, true) then
        return "No trade", Theme.missing or Theme.brick
    end
    if reason:find("offline", 1, true) then
        return "Offline", Theme.offline or Theme.dim
    end
    if reason:find("stale", 1, true) then
        return "Stale", Theme.amber or Theme.gold
    end
    if reason:find("same zone", 1, true) then
        return "Need zone", Theme.amber or Theme.gold
    end
    if reason:find("bank", 1, true) then
        return "Bank", Theme.bank or Theme.purple
    end
    if reason:find("equipped", 1, true) or reason:find("installed", 1, true) then
        return "Installed", Theme.amber or Theme.gold
    end
    if reason:find("class", 1, true) then
        return "Verify", Theme.amber or Theme.gold
    end
    if label ~= "" and label ~= "Details" and label ~= "Blocked" then
        return label, Theme.dim
    end
    return "Details", Theme.dim
end

local function draw_aug_action_cell(action, suffix, sock_rec, total_count)
    if not action then
        ImGui.TextDisabled("-")
        return
    end
    if action.detailOnly then
        local status, status_color = action_status_label(action)
        if status ~= "Details" then
            col_text(status_color, status)
            ImGui.SameLine()
        end
        if themed_button("Details##tg_suggest_aug_details_" .. tostring(suffix), Theme.steel, 68, 0) then
            open_aug_detail_for_socket(sock_rec)
        end
        if action.reason and action.reason ~= "" and ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
            ImGui.SetTooltip(action.reason)
        end
        return
    end

    local color = action.enabled and (action.queueOnly and (Theme.amber or Theme.gold) or (Theme.sync or Theme.green))
        or (Theme.steel or Theme.dim)
    if themed_button((action.label or "Action") .. "##tg_suggest_aug_action_" .. tostring(suffix), color, 104, 0) then
        run_aug_transfer_action(action)
    end
    if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
        if action.reason and action.reason ~= "" then
            ImGui.SetTooltip(action.reason)
        else
            ImGui.SetTooltip(string.format("%s %s from %s to %s",
                tostring(action.label or "Action"), tostring(action.item or "aug"),
                tostring(action.owner or "?"), tostring(action.recipient or "?")))
        end
    end
    if total_count and total_count > 1 then
        ImGui.SameLine()
        if themed_button("Details##tg_suggest_aug_all_" .. tostring(suffix), Theme.steel, 68, 0) then
            open_aug_detail_for_socket(sock_rec)
        end
    end
end

local function delta_summary(deltas, keys)
    local parts = {}
    for _, key in ipairs(keys or compare_stat_keys()) do
        local val = tonumber(deltas and deltas[key]) or 0
        if val ~= 0 then
            parts[#parts + 1] = compare_stat_compact_label(key) .. " " .. stat_defs.format_signed_delta(key, val)
        end
    end
    return #parts > 0 and table.concat(parts, " | ") or "-"
end

local function draw_current_aug(sock)
    local cur = sock and sock.currentAug
    if not cur then
        col_text(Theme.emptySocket or Theme.gold, "Empty")
        return
    end
    item_actions.draw_name(cur.name or "?", Theme.aug or Theme.green,
        "suggest_aug_plan_cur_" .. tostring(sock.slotId) .. "_" .. tostring(sock.socketIndex),
        cur.id)
    local stats = delta_summary(cur.stats, compare_stat_keys())
    if stats ~= "-" then
        col_text(Theme.dim, stats:gsub("%+", ""))
    end
end

local function draw_plan_totals(meta)
    local keys = (meta and meta.compareStats) or compare_stat_keys()
    local totals = meta and meta.totals or {}
    local parts = {}
    for _, key in ipairs(keys or {}) do
        local val = tonumber(totals[key]) or 0
        if val ~= 0 then parts[#parts + 1] = compare_stat_compact_label(key) .. " " .. stat_defs.format_signed_delta(key, val) end
    end
    if #parts == 0 then
        col_text(Theme.dim, "Plan recap: no positive net stat changes under the current filters.")
    else
        col_text(Theme.valueTop or Theme.gold, "Plan recap: " .. table.concat(parts, " | "))
    end

    local live = (meta and meta.capStatsReliable == true) and meta.liveStats or nil
    if type(live) == "table" then
        local projected = {}
        for _, key in ipairs(keys or {}) do
            local delta = tonumber(totals[key]) or 0
            if delta ~= 0 then
                local cur = tonumber(live[key])
                if cur then
                    local after = cur + delta
                    local cap = meta and meta.caps and tonumber(meta.caps[key]) or nil
                    local value = stat_defs.format_value(key, cur) .. "->" .. stat_defs.format_value(key, after)
                    if cap then value = value .. "/" .. stat_defs.format_value(key, cap) end
                    projected[#projected + 1] = compare_stat_compact_label(key) .. " " .. value
                end
            end
        end
        if #projected > 0 then
            col_text(Theme.dim, "Projected selected totals: " .. table.concat(projected, " | "))
        end
    end
end

local function plan_step_target(sock)
    return string.format("%s S%d T%d", tostring(sock and sock.slotLabel or "?"),
        tonumber(sock and sock.socketIndex) or 0,
        tonumber(sock and sock.socketType) or 0)
end

local function plan_step_text(pair, meta)
    local sock = pair and pair.socket or {}
    local wrapped = pair and pair.aug or {}
    local row = wrapped.row or {}
    local current = sock.currentAug and tostring(sock.currentAug.name or "") or "empty"
    local verb = sock.currentAug and "Replace" or "Fill"
    local target = plan_step_target(sock)
    local install = tostring(row.name or "?")
    if sock.currentAug then
        return string.format("%s: %s %s -> %s", target, verb, current, install)
    end
    return string.format("%s: %s %s", target, verb, install)
end

local function plan_pair_visible_change(pair, meta)
    return delta_summary(pair and pair.deltas, (meta and meta.compareStats) or compare_stat_keys())
end

local function plan_pair_has_visible_gain(pair, meta)
    return plan_pair_visible_change(pair, meta) ~= "-"
end

local function collect_top_plan_actions(rows, meta)
    local out = {}
    for _, pair in ipairs(rows or {}) do
        if plan_pair_has_visible_gain(pair, meta) then
            out[#out + 1] = pair
            if #out >= 5 then return out end
        end
    end
    if #out > 0 then return out end
    for _, pair in ipairs(rows or {}) do
        out[#out + 1] = pair
        if #out >= 5 then break end
    end
    return out
end

local function plan_action_counts(rows, meta)
    local counts = { total = #(rows or {}), fills = 0, replacements = 0, give = 0, bank = 0, owned = 0, offline = 0, blocked = 0 }
    for _, pair in ipairs(rows or {}) do
        local sock = pair and pair.socket or {}
        if sock.currentAug then counts.replacements = counts.replacements + 1 else counts.fills = counts.fills + 1 end
        local action = build_aug_transfer_action(meta, pair and pair.aug, sock)
        local status = action_status_label(action)
        if action and action.liveGive then
            counts.give = counts.give + 1
        elseif action and action.bankGive then
            counts.bank = counts.bank + 1
        elseif status == "Owned" then
            counts.owned = counts.owned + 1
        elseif status == "Offline" then
            counts.offline = counts.offline + 1
        elseif status ~= "Ready" and status ~= "Ready bank" then
            counts.blocked = counts.blocked + 1
        end
    end
    return counts
end

local function draw_plan_action_button(action, suffix)
    if not action or action.detailOnly then return false end
    local color = action.bankGive and (Theme.sync or Theme.green) or (Theme.sync or Theme.green)
    local label = action.bankGive and "Bank" or tostring(action.label or "Give")
    return themed_button(label .. "##tg_aug_top_action_" .. tostring(suffix), color, 72, 0)
end

local function draw_aug_plan_steps(rows, meta)
    if not rows or #rows == 0 then return end
    local top_rows = collect_top_plan_actions(rows, meta)
    local counts = plan_action_counts(rows, meta)
    col_text(Theme.section or Theme.header, "Top Actions")
    col_text(Theme.dim, string.format("%d actions | %d replacement%s | %d fill%s | %d give | %d bank | %d owned | %d offline",
        counts.total,
        counts.replacements, counts.replacements == 1 and "" or "s",
        counts.fills, counts.fills == 1 and "" or "s",
        counts.give,
        counts.bank,
        counts.owned,
        counts.offline))
    local flags = ImGuiTableFlags.Borders + ImGuiTableFlags.RowBg + ImGuiTableFlags.SizingStretchProp
    if ImGui.BeginTable("SuggestAugPlanTopActions", 5, flags) then
        local ok, err = pcall(function()
            ImGui.TableSetupColumn("Status", ImGuiTableColumnFlags.WidthFixed, 112.0)
            ImGui.TableSetupColumn("Action", ImGuiTableColumnFlags.WidthStretch, 2.0)
            ImGui.TableSetupColumn("Change", ImGuiTableColumnFlags.WidthStretch, 0.9)
            ImGui.TableSetupColumn("Source", ImGuiTableColumnFlags.WidthStretch, 1.0)
            ImGui.TableSetupColumn("", ImGuiTableColumnFlags.WidthFixed, 144.0)
            views.table_headers_centered({ "Status", "Action", "Change", "Source", "" })
            for i, pair in ipairs(top_rows) do
                local sock = pair.socket or {}
                local action = build_aug_transfer_action(meta, pair.aug, sock)
                local status, status_color = action_status_label(action)
                ImGui.TableNextRow()
                ImGui.TableSetColumnIndex(0)
                col_text(status_color, status)
                ImGui.TableSetColumnIndex(1)
                views.col_text_fit(Theme.neutral or Theme.header, plan_step_text(pair, meta))
                if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then ImGui.SetTooltip(plan_step_text(pair, meta)) end
                ImGui.TableSetColumnIndex(2)
                col_text(Theme.value or Theme.green, plan_pair_visible_change(pair, meta))
                ImGui.TableSetColumnIndex(3)
                local row = pair and pair.aug and pair.aug.row or {}
                col_text(theme.location_color(row.locationGroup, row.location), compact_location(row))
                ImGui.TableSetColumnIndex(4)
                if draw_plan_action_button(action, tostring(i)) then
                    run_aug_transfer_action(action)
                end
                if action and action.detailOnly then
                    if themed_button("Details##tg_aug_top_details_" .. tostring(i), Theme.steel, 62, 0) then
                        open_aug_detail_for_socket(sock)
                    end
                end
                ImGui.SameLine()
                if themed_button("Skip##tg_aug_top_reject_" .. tostring(i), Theme.steel, 46, 0) then
                    reject_aug_plan_pair(meta, pair)
                end
                if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
                    ImGui.SetTooltip("Skip this candidate for this socket until TurboGear reloads or the plan is reset.")
                end
                if action and action.reason and action.reason ~= "" and ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
                    ImGui.SetTooltip(action.reason)
                end
            end
        end)
        ImGui.EndTable()
        if not ok then col_text(Theme.amber, "Aug top actions render issue: " .. tostring(err)) end
    end
    if #rows > #top_rows then
        col_text(Theme.dim, string.format("+%d more plan row%s in the table below.", #rows - #top_rows, (#rows - #top_rows) == 1 and "" or "s"))
    end
    if aug_plan_reject_serial > 0 then
        ImGui.SameLine()
        if themed_button("Reset skips##tg_aug_reset_rejected", Theme.steel, 98, 0) then
            clear_aug_plan_rejects()
        end
    end
    ImGui.Separator()
end

local function draw_aug_plan(rows, meta)
    local shown = 0
    local last_group = nil
    if views.begin_scroll_table("SuggestAugPlan", 7, views.scroll_table_flags(), 86.0, 180.0) then
        local ok, err = pcall(function()
            ImGui.TableSetupColumn("Slot", ImGuiTableColumnFlags.WidthFixed, 72.0)
            ImGui.TableSetupColumn("In Item", ImGuiTableColumnFlags.WidthStretch, 1.15)
            ImGui.TableSetupColumn("Socket", ImGuiTableColumnFlags.WidthFixed, 58.0)
            ImGui.TableSetupColumn("Current", ImGuiTableColumnFlags.WidthStretch, 1.2)
            ImGui.TableSetupColumn("Install", ImGuiTableColumnFlags.WidthStretch, 1.35)
            ImGui.TableSetupColumn("Change", ImGuiTableColumnFlags.WidthStretch, 1.0)
            ImGui.TableSetupColumn("Action", ImGuiTableColumnFlags.WidthFixed, 188.0)
            pcall(function() ImGui.TableSetupScrollFreeze(0, 1) end)
            views.table_headers_centered({ "Slot", "In Item", "Socket", "Current", "Install", "Change", "Action" })

            for i, pair in ipairs(rows or {}) do
                local sock = pair.socket or {}
                if sock.group ~= last_group then
                    last_group = sock.group
                    views.draw_section_row(sock.group or "Sockets", 7)
                end
                shown = shown + 1
                ImGui.TableNextRow()
                if ImGui.TableSetBgColor and ImGuiTableBgTarget and ImGuiTableBgTarget.RowBg0 and theme.color_u32 then
                    pcall(ImGui.TableSetBgColor, ImGuiTableBgTarget.RowBg0, theme.color_u32(SUGGEST_UPGRADE_ROW))
                end
                ImGui.TableSetColumnIndex(0)
                col_text(Theme.slot, sock.slotLabel or "?")
                ImGui.TableSetColumnIndex(1)
                item_actions.draw_name(sock.hostItem or "?", Theme.item,
                    "suggest_aug_plan_host_" .. tostring(sock.slotId) .. "_" .. tostring(sock.socketIndex),
                    sock.hostItemId)
                ImGui.TableSetColumnIndex(2)
                col_text(Theme.emptySocket or Theme.gold, string.format("S%d T%d", sock.socketIndex or 0, sock.socketType or 0))
                ImGui.TableSetColumnIndex(3)
                draw_current_aug(sock)
                ImGui.TableSetColumnIndex(4)
                draw_aug_candidate(pair.aug, "plan_" .. tostring(i), tostring(sock.slotId) .. "_" .. tostring(sock.socketIndex))
                ImGui.TableSetColumnIndex(5)
                col_text(Theme.value or Theme.green, delta_summary(pair.deltas, (meta and meta.compareStats) or compare_stat_keys()))
                ImGui.TableSetColumnIndex(6)
                draw_aug_action_cell(build_aug_transfer_action(meta, pair.aug, sock),
                    "plan_" .. tostring(i) .. "_" .. tostring(sock.slotId) .. "_" .. tostring(sock.socketIndex),
                    sock,
                    nil)
                ImGui.SameLine()
                if themed_button("Skip##tg_aug_plan_reject_" .. tostring(i), Theme.steel, 46, 0) then
                    reject_aug_plan_pair(meta, pair)
                end
                if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
                    ImGui.SetTooltip("Skip this candidate for this socket until TurboGear reloads or the plan is reset.")
                end
            end
        end)
        ImGui.EndTable()
        if not ok then col_text(Theme.amber, "Aug plan table render issue: " .. tostring(err)) end
    end

    if shown == 0 then
        col_text(Theme.placeholder or Theme.dim, upgrades_focus_on()
            and "No positive aug swaps under the current stat priorities and filters."
            or "No aug plan rows under the current filters.")
    end
end

local function draw_aug_overview(rows, meta)
    local shown = 0
    local last_group = nil
    if views.begin_scroll_table("SuggestAugOverview", 6, views.scroll_table_flags(), 52.0, 180.0) then
        local ok, err = pcall(function()
            ImGui.TableSetupColumn("Slot", ImGuiTableColumnFlags.WidthFixed, 72.0)
            ImGui.TableSetupColumn("In Item", ImGuiTableColumnFlags.WidthStretch, 1.3)
            ImGui.TableSetupColumn("Socket", ImGuiTableColumnFlags.WidthFixed, 58.0)
            ImGui.TableSetupColumn("Best Aug", ImGuiTableColumnFlags.WidthStretch, 1.5)
            ImGui.TableSetupColumn("Alt Aug", ImGuiTableColumnFlags.WidthStretch, 1.5)
            ImGui.TableSetupColumn("Action", ImGuiTableColumnFlags.WidthFixed, 184.0)
            pcall(function() ImGui.TableSetupScrollFreeze(0, 1) end)
            views.table_headers_centered({ "Slot", "In Item", "Socket", "Best Aug", "Alt Aug", "Action" })

            for _, sock in ipairs(rows or {}) do
                if sock.group ~= last_group then
                    last_group = sock.group
                    views.draw_section_row(sock.group or "Sockets", 6)
                end
                shown = shown + 1
                ImGui.TableNextRow()
                highlight_aug_row(sock)
                ImGui.TableSetColumnIndex(0)
                col_text(Theme.slot, sock.slotLabel or "?")
                ImGui.TableSetColumnIndex(1)
                item_actions.draw_name(sock.hostItem or "?", Theme.item, "suggest_aug_host_" .. tostring(sock.slotId) .. "_" .. tostring(sock.socketIndex), sock.hostItemId)
                ImGui.TableSetColumnIndex(2)
                col_text(Theme.emptySocket or Theme.gold, string.format("S%d T%d", sock.socketIndex or 0, sock.socketType or 0))
                ImGui.TableSetColumnIndex(3)
                draw_aug_candidate(sock.best, "best", sock.slotId .. "_" .. sock.socketIndex)
                ImGui.TableSetColumnIndex(4)
                draw_aug_candidate(sock.alt, "alt", sock.slotId .. "_" .. sock.socketIndex)
                ImGui.TableSetColumnIndex(5)
                draw_aug_action_cell(build_aug_transfer_action(meta, sock.best, sock),
                    tostring(sock.slotId) .. "_" .. tostring(sock.socketIndex), sock, sock.totalCount)
                if sock.best then
                    ImGui.SameLine()
                    if themed_button("Skip##tg_suggest_aug_skip_" .. tostring(sock.slotId) .. "_" .. tostring(sock.socketIndex), Theme.steel, 46, 0) then
                        reject_aug_candidate(meta, sock, sock.best)
                    end
                    if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
                        ImGui.SetTooltip("Skip this aug for this socket until TurboGear reloads or skips are reset.")
                    end
                end
            end
        end)
        ImGui.EndTable()
        if not ok then col_text(Theme.amber, "Aug overview table render issue: " .. tostring(err)) end
    end

    if shown == 0 then
        col_text(Theme.placeholder or Theme.dim, upgrades_focus_on()
            and "No empty sockets with network aug candidates. Turn off Actionable or check sync."
            or "No empty aug sockets on this character.")
    end
end

local function draw_aug_detail_rows(wrapped_rows)
    local total = #(wrapped_rows or {})
    local limit = Settings.suggestShowAllRows and total or math.min(total, Settings.suggestRowLimit or 200)
    local sock_rec = current_aug_socket_rec()
    if views.begin_scroll_table("SuggestAugRows", 5, views.scroll_table_flags(), 72.0, 180.0) then
        local ok, err = pcall(function()
            ImGui.TableSetupColumn("Augment", ImGuiTableColumnFlags.WidthStretch, 2.0)
            ImGui.TableSetupColumn("Owner", ImGuiTableColumnFlags.WidthFixed, 120.0)
            ImGui.TableSetupColumn("Location", ImGuiTableColumnFlags.WidthStretch, 1.5)
            ImGui.TableSetupColumn("Stats", ImGuiTableColumnFlags.WidthStretch, 1.0)
            ImGui.TableSetupColumn("Action", ImGuiTableColumnFlags.WidthFixed, 132.0)
            pcall(function() ImGui.TableSetupScrollFreeze(0, 1) end)
            views.table_headers_centered({ "Augment", "Owner", "Location", "Stats", "Action" })

            for i = 1, limit do
                local wrapped = wrapped_rows[i]
                local row = wrapped.row
                ImGui.TableNextRow()
                ImGui.TableSetColumnIndex(0)
                item_actions.draw_name(row.name or "?", Theme.aug or Theme.green, "suggest_aug_item_" .. tostring(i), row.id, item_actions.context_opts({
                    sourceLocation = compact_location(row),
                }, row))
                ImGui.TableSetColumnIndex(1)
                col_text(theme.report_owner_color(), owner_label(row))
                ImGui.TableSetColumnIndex(2)
                col_text(theme.location_color(row.locationGroup, row.location), row.location or "-")
                ImGui.TableSetColumnIndex(3)
                local stat_line = format_aug_stat_values(row, compare_stat_keys(), true)
                col_text(stat_line ~= "" and (Theme.value or Theme.green) or (Theme.placeholder or Theme.dim), stat_line ~= "" and stat_line or "-")

                ImGui.TableSetColumnIndex(4)
                draw_aug_action_cell(build_aug_transfer_action(aug_detail_meta, wrapped, sock_rec),
                    "detail_" .. tostring(i) .. "_" .. tostring(row.id or row.name or ""), sock_rec, nil)
            end
        end)
        ImGui.EndTable()
        if not ok then col_text(Theme.amber, "Aug detail table render issue: " .. tostring(err)) end
    end
end

local function draw_aug_detail_context()
    col_text(Theme.dim, string.format("%s | Socket S%d type T%d on",
        slot_label(Settings.suggestAugSlotId),
        Settings.suggestAugSocketIndex or 0,
        Settings.suggestAugSocketType or 0))
    ImGui.SameLine()
    if Settings.suggestAugHostItem and Settings.suggestAugHostItem ~= "" then
        item_actions.draw_name(Settings.suggestAugHostItem, Theme.item, "suggest_aug_ctx_host", Settings.suggestAugHostId)
    else
        col_text(Theme.placeholder or Theme.dim, "(unknown item)")
    end
end

local function draw_detail_current(meta)
    local current = meta and meta.currentEquipped
    if not current or not current.name or current.name == "" then
        col_text(Theme.missing or Theme.amber, string.format("%s: (empty)", slot_label(meta and meta.slotId)))
        return
    end
    local keys = compare_stat_keys()
    col_text(Theme.dim, string.format("%s worn:", slot_label(meta and meta.slotId)))
    ImGui.SameLine()
    item_actions.draw_name(current.name, Theme.item, "suggest_current_" .. tostring(current.id or ""), current.id)
    local parts = {}
    for _, key in ipairs(keys) do
        local cur_stat = suggestions.stat_value(current, key, M.EQUIP_REPLACE_STATS)
        local bonus = suggestions.aug_stat_bonus(current, key)
        if cur_stat > 0 or bonus ~= 0 then
            local text = compare_stat_compact_label(key) .. " " .. stat_defs.format_value(key, cur_stat)
            if bonus ~= 0 then text = text .. " (" .. stat_defs.format_signed_delta(key, bonus) .. " aug)" end
            parts[#parts + 1] = text
        end
    end
    if #parts > 0 then
        ImGui.SameLine()
        col_text(Theme.dim, table.concat(parts, " · "))
    end
end

function M.draw()
    return M._diag.time("ui.suggestions.draw", function()
    ensure_defaults()
    local mode = Settings.suggestViewMode or "overview"

    draw_target_picker()
    ImGui.SameLine()
    draw_scope_picker()
    ImGui.SameLine()
    draw_view_mode_picker()

    ImGui.Separator()
    draw_shared_filters()
    draw_whatif_panel()

    if mode == "detail" then
        ImGui.Separator()
        if themed_button("< Back to Character##suggest_back_overview", Theme.blue) then
            Settings.suggestViewMode = "overview"
            SaveSettings()
        end
        ImGui.SameLine()
        draw_detail_slot_picker()
        ImGui.SetNextItemWidth(220.0)
        local next_search = input_text_hint("##suggest_search", "Search candidates", search_text)
        if next_search ~= search_text then
            search_text = next_search or ""
            detail_key = nil
        end
    elseif mode == "aug_detail" then
        ImGui.Separator()
        if themed_button("< Back to Augs##suggest_back_aug", Theme.blue) then
            Settings.suggestViewMode = "aug_overview"
            SaveSettings()
        end
        ImGui.SameLine()
        ImGui.SetNextItemWidth(220.0)
        local next_aug_search = input_text_hint("##suggest_aug_search", "Search loose augs", aug_search_text)
        if next_aug_search ~= aug_search_text then
            aug_search_text = next_aug_search or ""
            aug_detail_key = nil
        end
    elseif mode == "aug_overview" then
        ImGui.Separator()
        ImGui.Text("Why not shown?")
        ImGui.SameLine()
        ImGui.SetNextItemWidth(220.0)
        local next_aug_search = input_text_hint("##suggest_aug_why", "Aug name to diagnose", aug_search_text)
        if next_aug_search ~= aug_search_text then
            aug_search_text = next_aug_search or ""
        end
    end

    ImGui.Spacing()
    maybe_refresh_local_source()
    local selected_snap = views.source_snapshot(Settings.suggestTargetKey or "__self__")
    if draw_target_inventory_wait(selected_snap) then
        return
    end

    if mode == "overview" then
        local slots, meta = visible_overview()
        draw_target_freshness_warning(views.source_snapshot(Settings.suggestTargetKey or "__self__"))
        draw_worn_totals_bar(meta)
        col_text(Theme.dim, string.format("%s (%s) | %d slot%s with network upgrades | %d total upgrade candidate%s by %s",
            meta and meta.targetName or "?",
            meta and meta.targetClass or "?",
            meta and meta.slotsWithUpgrades or 0,
            (meta and meta.slotsWithUpgrades or 0) == 1 and "" or "s",
            meta and meta.totalUpgrades or 0,
            (meta and meta.totalUpgrades or 0) == 1 and "" or "s",
            compare_stats_summary()))
        col_text(Theme.dim, "Green = better than worn on primary stat | Secondary stat deltas shown when multi-compare | Highlighted rows have upgrades")
        ImGui.SetNextItemWidth(220.0)
        local next_why = input_text_hint("##suggest_overview_why", "Why not shown? item name", overview_why_text)
        if next_why ~= overview_why_text then overview_why_text = next_why or "" end
        if (overview_why_text or ""):match("^%s*(.-)%s*$") ~= "" then
            local explain = suggestions.explain({
                targetKey = Settings.suggestTargetKey,
                scope = Settings.suggestSourceScope,
                locationFilter = Settings.suggestLocationFilter,
                needle = overview_why_text,
            })
            for _, line in ipairs(explain) do
                local hit = tostring(line):find("WOULD SHOW", 1, true) ~= nil
                col_text(hit and (Theme.valueTop or Theme.green) or (Theme.amber or Theme.gold), line)
            end
            col_text(Theme.dim, "(\"Would show\" checks slot/class/level/scope/location only; the Upgrades filter may still hide non-upgrades.)")
        end
        ImGui.Spacing()
        local ok, err = pcall(draw_overview, slots, meta)
        if not ok then col_text(Theme.amber, "Overview render issue: " .. tostring(err)) end
    elseif mode == "aug_plan" then
        local rows, meta = visible_aug_plan()
        draw_target_freshness_warning(views.source_snapshot(Settings.suggestTargetKey or "__self__"))
        col_text(Theme.dim, string.format("%s (%s) | %d sockets (%d filled, %d empty) | %d positive match%s",
            meta and meta.targetName or "?",
            meta and meta.targetClass or "?",
            meta and meta.socketCount or 0,
            meta and meta.filledCount or 0,
            meta and meta.emptyCount or 0,
            meta and meta.candidatePairs or 0,
            (meta and meta.candidatePairs or 0) == 1 and "" or "es"))
        col_text(Theme.dim, "Aug Plan evaluates filled and empty sockets. Compare stats act as priority order; capped stats use live totals when available.")
        if meta and (tonumber(meta.loreBlocked) or 0) > 0 then
            col_text(Theme.amber or Theme.gold, tostring(meta.loreBlocked) .. " duplicate Lore candidate matches hidden.")
        end
        if meta and ((tonumber(meta.candidatePairs) or 0) == 0 or #rows == 0) then
            local reason = M.aug_plan_empty_reason(meta)
            if reason ~= "" then col_text(Theme.amber or Theme.gold, reason) end
            local text = aug_plan_funnel_text(meta)
            if text ~= "" then col_text(Theme.amber or Theme.gold, text) end
            M.draw_blocked_aug_examples(meta)
        end
        draw_plan_totals(meta)
        ImGui.Spacing()
        draw_aug_plan_steps(rows, meta)
        ImGui.Spacing()
        local ok, err = pcall(draw_aug_plan, rows, meta)
        if not ok then col_text(Theme.amber, "Aug plan render issue: " .. tostring(err)) end
    elseif mode == "aug_overview" then
        local rows, meta = visible_aug_overview()
        draw_target_freshness_warning(views.source_snapshot(Settings.suggestTargetKey or "__self__"))
        col_text(Theme.dim, string.format("%s (%s) | %d empty aug socket%s | %d actionable | %d loose aug match%s",
            meta and meta.targetName or "?",
            meta and meta.targetClass or "?",
            meta and meta.totalEmptySockets or 0,
            (meta and meta.totalEmptySockets or 0) == 1 and "" or "s",
            meta and meta.socketsWithCandidates or 0,
            meta and meta.totalCandidates or 0,
            (meta and meta.totalCandidates or 0) == 1 and "" or "es"))
        col_text(Theme.dim, "Best loose augs for empty sockets. Give Now moves the aug; install remains manual.")
        if (meta and (meta.totalCandidates or 0) == 0) then
            local text = aug_summary_text(meta.looseSummary)
            if text ~= "" then col_text(Theme.amber or Theme.gold, text) end
        end
        if (aug_search_text or ""):match("^%s*(.-)%s*$") ~= "" then
            local explain = aug_suggestions.explain({
                targetKey = Settings.suggestTargetKey,
                scope = Settings.suggestSourceScope,
                locationFilter = Settings.suggestLocationFilter,
                needle = aug_search_text,
            })
            for _, line in ipairs(explain) do
                local hit = tostring(line):find("WOULD SHOW", 1, true) ~= nil
                col_text(hit and (Theme.valueTop or Theme.green) or (Theme.amber or Theme.gold), line)
            end
        end
        ImGui.Spacing()
        local ok, err = pcall(draw_aug_overview, rows, meta)
        if not ok then col_text(Theme.amber, "Aug overview render issue: " .. tostring(err)) end
        if aug_plan_reject_serial > 0 then
            ImGui.Spacing()
            if themed_button("Reset skips##tg_aug_overview_reset_rejected", Theme.steel, 98, 0) then
                clear_aug_plan_rejects()
            end
        end
    elseif mode == "aug_detail" then
        local rows, meta = visible_aug_detail()
        draw_target_freshness_warning(views.source_snapshot(Settings.suggestTargetKey or "__self__"))
        draw_aug_detail_context()
        col_text(Theme.dim, string.format("%d loose aug candidate%s matching type T%d, sorted by %s",
            #rows, #rows == 1 and "" or "s",
            Settings.suggestAugSocketType or 0,
            compare_stat_label()))
        ImGui.Spacing()
        if #rows == 0 then
            col_text(Theme.placeholder or Theme.dim, "No loose augs in the network match this socket type, level, scope, and location.")
        else
            local ok, err = pcall(draw_aug_detail_rows, rows)
            if not ok then col_text(Theme.amber, "Aug detail render issue: " .. tostring(err)) end
        end
    else
        local rows, meta = visible_detail_rows()
        draw_target_freshness_warning(views.source_snapshot(Settings.suggestTargetKey or "__self__"))
        draw_detail_current(meta)
        local upgrade_count = 0
        for _, wrapped in ipairs(rows) do
            if wrapped.delta and wrapped.delta > 0 then upgrade_count = upgrade_count + 1 end
        end
        col_text(Theme.dim, string.format("%d candidate%s for %s | %d upgrade%s by %s",
            #rows, #rows == 1 and "" or "s",
            slot_label(meta and meta.slotId),
            upgrade_count, upgrade_count == 1 and "" or "s",
            compare_stats_summary()))
        ImGui.Spacing()
        if #rows == 0 then
            col_text(Theme.placeholder or Theme.dim, upgrades_focus_on()
                and "No upgrades in the network for this slot. Switch to Filter: All Slots or use Character view."
                or "No cached items match this slot and filters.")
        else
            local ok, err = pcall(draw_detail_rows, rows)
            if not ok then col_text(Theme.amber, "Detail render issue: " .. tostring(err)) end
            draw_candidate_delta_panel(meta)
        end
    end

    local status = item_actions.status()
    if status and status ~= "" then col_text(Theme.dim, status) end
    end)
end

function M.set_search(text)
    search_text = tostring(text or "")
    detail_key = nil
    overview_key = nil
end

return M
