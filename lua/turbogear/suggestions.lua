-- TurboGear/suggestions.lua
-- Cross-character equip-slot suggestions from cached item_index rows.
-- Never touches live MQ item TLOs or the actor engine.

local item_index = require('item_index')
local views = require('views')
local stat_defs = require('stat_defs')

local M = {}

local EQUIP_REPLACE_STATS = { mode = "base" }

local EQUIV_SLOT_GROUP = {
    [1] = "ear", [4] = "ear",
    [9] = "wrist", [10] = "wrist",
    [15] = "finger", [16] = "finger",
}

function M.equivalent_slot_group(slot_id)
    return EQUIV_SLOT_GROUP[tonumber(slot_id)]
end

function M.is_same_target_equipped_in_equivalent_slot(row, target_clean, slot_id)
    if not row or M.location_bucket(row) ~= "equipped" then return false end
    if views.clean_name(row.owner) ~= target_clean then return false end
    local wanted_group = M.equivalent_slot_group(slot_id)
    if not wanted_group then return false end
    if type(row.slots) ~= "table" then return false end
    for _, sid in ipairs(row.slots) do
        local sid_num = tonumber(sid)
        if sid_num and sid_num ~= tonumber(slot_id) and M.equivalent_slot_group(sid_num) == wanted_group then
            return true
        end
    end
    return false
end

function M.can_class_use(row, target_class, opts)
    opts = type(opts) == "table" and opts or {}
    target_class = tostring(target_class or "")
    if target_class == "" or not row then return false end
    if row.allClasses then return true end
    local target_abbrev = views.class_abbrev(target_class)
    if type(row.classes) == "table" and #row.classes > 0 then
        for _, cls in ipairs(row.classes) do
            if tostring(cls or "") == target_class or views.class_abbrev(cls) == target_abbrev then return true end
        end
        return false
    end
    return opts.allowUnknownClass == true
end

function M.is_equipment_row(row)
    if not row then return false end
    if row.kind == "aug" then return false end
    if tostring(row.itemType or "") == "aug" then return false end
    if row.where == "installed_aug" or row.where == "loose_aug" then return false end
    return true
end

function M.is_usable_in_slot(row, slot_id, target_class)
    if not M.is_equipment_row(row) then return false end
    if not row.name or row.name == "" or row.name == "?" then return false end
    if not M.can_class_use(row, target_class) then return false end

    slot_id = tonumber(slot_id)
    if not slot_id then return false end

    if type(row.slots) == "table" and #row.slots > 0 then
        for _, sid in ipairs(row.slots) do
            if tonumber(sid) == slot_id then return true end
        end
        return false
    end

    if slot_id == 22 and tostring(row.itemType or "") == "ammo" then return true end
    return false
end

function M.class_info(row)
    if not row then return "Unknown" end
    if row.allClasses then return "All Classes" end
    if type(row.classes) == "table" and #row.classes > 0 then
        return table.concat(row.classes, ", ")
    end
    return "Unknown"
end

local function stat_from_table(stats, stat_key)
    if type(stats) ~= "table" then return nil end
    local value = tonumber(stats[stat_key]) or 0
    if value ~= value then return 0 end
    return value
end

function M.effective_stat_value(item_or_row, stat_key)
    if not item_or_row then return 0 end
    local stats = item_or_row and item_or_row.stats
    local value = stat_from_table(stats, stat_key) or 0
    if item_or_row.statsMerged ~= true and type(item_or_row.augs) == "table" then
        for _, aug in ipairs(item_or_row.augs) do
            if aug and not aug.empty and type(aug.stats) == "table" then
                local av = tonumber(aug.stats[stat_key]) or 0
                if av ~= 0 then value = value + av end
            end
        end
    end
    return value
end

function M.base_stat_value(item_or_row, stat_key)
    local value = stat_from_table(item_or_row and (item_or_row.baseStats or item_or_row._baseStats), stat_key)
    if value ~= nil then return value end

    value = M.effective_stat_value(item_or_row, stat_key)
    if item_or_row and item_or_row.statsMerged == true and type(item_or_row.augs) == "table" then
        for _, aug in ipairs(item_or_row.augs) do
            if aug and not aug.empty and type(aug.stats) == "table" then
                local av = tonumber(aug.stats[stat_key]) or 0
                if av ~= 0 then value = value - av end
            end
        end
    end
    return value
end

function M.aug_stat_bonus(item_or_row, stat_key)
    return M.effective_stat_value(item_or_row, stat_key) - M.base_stat_value(item_or_row, stat_key)
end

function M.stat_value(item_or_row, stat_key, opts)
    opts = type(opts) == "table" and opts or nil
    if opts and (opts.mode == "base" or opts.base == true) then
        return M.base_stat_value(item_or_row, stat_key)
    end
    return M.effective_stat_value(item_or_row, stat_key)
end

function M.upgrade_delta(row, current, stat_key, opts)
    stat_key = tostring(stat_key or "ac")
    if not current then return nil end
    local cur = M.stat_value(current, stat_key, opts)
    local cand = M.stat_value(row, stat_key, opts)
    if cand == 0 and cur == 0 then return 0 end
    if stat_defs.lower_better(stat_key) then return cur - cand end
    return cand - cur
end

function M.is_upgrade(row, current, stat_key, opts)
    local delta = M.upgrade_delta(row, current, stat_key, opts)
    return delta ~= nil and delta > 0
end

function M.target_equipped_item(target_key, slot_id)
    local snap = views.source_snapshot(target_key)
    if not snap then return nil end
    local map = views.index_equipped(snap)
    return map[tonumber(slot_id)]
end

function M.worn_stat_totals(target_key, stat_keys)
    stat_keys = stat_keys or {}
    local snap = views.source_snapshot(target_key)
    if not snap then return nil, false end
    local equipped_map = views.index_equipped(snap) or {}
    local has_equipped = false
    for _, item in pairs(equipped_map) do
        if item and item.name and item.name ~= "" then
            has_equipped = true
            break
        end
    end

    local totals = {}
    for _, stat_key in ipairs(stat_keys) do totals[stat_key] = 0 end

    if not has_equipped then
        return totals, true
    end

    local stats_available = tostring(snap.depth or "") == "full"
    if not stats_available then
        for _, item in pairs(equipped_map) do
            for _, stat_key in ipairs(stat_keys) do
                if M.stat_value(item, stat_key) > 0 then
                    stats_available = true
                    break
                end
            end
            if stats_available then break end
        end
    end

    if not stats_available then
        return nil, false
    end

    for _, item in pairs(equipped_map) do
        if item and item.name and item.name ~= "" then
            for _, stat_key in ipairs(stat_keys) do
                totals[stat_key] = (totals[stat_key] or 0) + M.stat_value(item, stat_key)
            end
        end
    end
    return totals, true
end

function M.location_bucket(row)
    if not row then return "other" end
    if row.where == "equipped" then return "equipped" end
    if row.locationGroup == "bank" then return "bank" end
    if row.locationGroup == "bags" then return "bags" end
    return "other"
end

local function owner_allowed(row, scope, e3_names)
    scope = scope or "all"
    if scope == "all" then return true end
    if scope == "online" then return row.ownerStatus == "live" end
    if scope == "group" then return views.is_group_member(row.owner) end
    if scope == "e3" then
        return row.ownerStatus == "live" and e3_names and e3_names[views.clean_name(row.owner)] == true
    end
    return true
end

local function location_allowed(row, loc_filter)
    loc_filter = loc_filter or "all"
    if loc_filter == "all" then return true end
    local bucket = M.location_bucket(row)
    if loc_filter == "equipped" then return bucket == "equipped" end
    if loc_filter == "bags" then return bucket == "bags" end
    if loc_filter == "bank" then return bucket == "bank" end
    if loc_filter == "stored" then return bucket == "bags" or bucket == "bank" end
    return true
end

function M.level_allowed(row, target_level)
    target_level = tonumber(target_level) or 0
    if target_level <= 0 then return true end
    local req = tonumber(row and row.requiredLevel) or 0
    return req <= 0 or req <= target_level
end

function M.get_available(opts)
    opts = type(opts) == "table" and opts or {}
    local target_key = opts.targetKey or "__self__"
    local slot_id = tonumber(opts.slotId) or 2
    local scope = opts.scope or "all"
    local loc_filter = opts.locationFilter or "all"
    local exclude_same = opts.excludeSameEquipped ~= false
    local upgrades_only = opts.upgradesOnly == true
    local compare_stat = tostring(opts.compareStat or "ac")
    local needle = tostring(opts.search or ""):lower()

    local snap = views.source_snapshot(target_key)
    local target_class = snap and snap.class or ""
    local target_level = tonumber(snap and snap.level) or 0
    local target_name = snap and snap.name or views.source_owner_name(target_key)
    local target_clean = views.clean_name(target_name)
    local current = M.target_equipped_item(target_key, slot_id)

    item_index.get(false)
    local e3_names = scope == "e3" and views.e3_connected_names() or nil
    local results = {}

    for _, row in ipairs(item_index.rows or {}) do
        if not M.is_usable_in_slot(row, slot_id, target_class) then goto continue end
        if not M.level_allowed(row, target_level) then goto continue end
        if not owner_allowed(row, scope, e3_names) then goto continue end
        if not location_allowed(row, loc_filter) then goto continue end
        if (tonumber(row.nodrop) or 0) == 1 and views.clean_name(row.owner) ~= target_clean then goto continue end
        if exclude_same and current and current.name and row.name == current.name
            and views.clean_name(row.owner) == target_clean
            and M.location_bucket(row) == "equipped" then goto continue end
        if exclude_same and M.is_same_target_equipped_in_equivalent_slot(row, target_clean, slot_id) then goto continue end
        if needle ~= "" then
            local hay = table.concat({
                row.name or "", row.owner or "", row.location or "", M.class_info(row),
            }, " "):lower()
            if not hay:find(needle, 1, true) then goto continue end
        end
        if upgrades_only and not M.is_upgrade(row, current, compare_stat, EQUIP_REPLACE_STATS) then goto continue end
        results[#results+1] = row
        ::continue::
    end

    return results, {
        targetKey = target_key,
        targetClass = target_class,
        targetLevel = target_level,
        targetName = target_name,
        slotId = slot_id,
        currentEquipped = current,
        compareStat = compare_stat,
    }
end

local function decorate_candidate(row, current, primary_key, compare_keys)
    primary_key = tostring(primary_key or "ac")
    compare_keys = type(compare_keys) == "table" and compare_keys or { primary_key }
    local wrapped = {
        row = row,
        delta = M.upgrade_delta(row, current, primary_key, EQUIP_REPLACE_STATS),
        stat = M.stat_value(row, primary_key, EQUIP_REPLACE_STATS),
        stats = {},
        deltas = {},
    }
    for _, key in ipairs(compare_keys) do
        wrapped.stats[key] = M.stat_value(row, key, EQUIP_REPLACE_STATS)
        wrapped.deltas[key] = M.upgrade_delta(row, current, key, EQUIP_REPLACE_STATS)
    end
    return wrapped
end

local function sort_candidates(wrapped, prefer_upgrades)
    table.sort(wrapped, function(a, b)
        local da = a.delta
        local db = b.delta
        if prefer_upgrades then
            local a_up = da and da > 0
            local b_up = db and db > 0
            if a_up ~= b_up then return a_up end
        end
        if da ~= db then
            if da == nil then return false end
            if db == nil then return true end
            return da > db
        end
        if (a.stat or 0) ~= (b.stat or 0) then return (a.stat or 0) > (b.stat or 0) end
        return tostring(a.row.name or ""):lower() < tostring(b.row.name or ""):lower()
    end)
end

function M.build_overview(opts)
    opts = type(opts) == "table" and opts or {}
    local target_key = opts.targetKey or "__self__"
    local scope = opts.scope or "all"
    local loc_filter = opts.locationFilter or "all"
    local exclude_same = opts.excludeSameEquipped ~= false
    local upgrades_only = opts.upgradesOnly == true
    local compare_keys = opts.compareStats
    if type(compare_keys) ~= "table" or #compare_keys == 0 then
        compare_keys = { tostring(opts.compareStat or "ac") }
    end
    local primary_key = tostring(opts.comparePrimary or opts.compareStat or compare_keys[1] or "ac")
    local top_n = tonumber(opts.topN) or 3

    local snap = views.source_snapshot(target_key)
    local target_class = snap and snap.class or ""
    local target_level = tonumber(snap and snap.level) or 0
    local target_name = snap and snap.name or views.source_owner_name(target_key)
    local target_clean = views.clean_name(target_name)
    local equipped_map = snap and views.index_equipped(snap) or {}

    item_index.get(false)
    local e3_names = scope == "e3" and views.e3_connected_names() or nil

    local buckets = {}
    local function bucket(slot_id)
        if not buckets[slot_id] then buckets[slot_id] = {} end
        return buckets[slot_id]
    end

    local function consider_row(row, slot_id)
        if not M.is_usable_in_slot(row, slot_id, target_class) then return end
        if not M.level_allowed(row, target_level) then return end
        if not owner_allowed(row, scope, e3_names) then return end
        if not location_allowed(row, loc_filter) then return end
        if (tonumber(row.nodrop) or 0) == 1 and views.clean_name(row.owner) ~= target_clean then return end
        local current = equipped_map[slot_id]
        if exclude_same and current and current.name and row.name == current.name
            and views.clean_name(row.owner) == target_clean
            and M.location_bucket(row) == "equipped" then return end
        if exclude_same and M.is_same_target_equipped_in_equivalent_slot(row, target_clean, slot_id) then return end
        if upgrades_only and not M.is_upgrade(row, current, primary_key, EQUIP_REPLACE_STATS) then return end
        local list = bucket(slot_id)
        list[#list + 1] = row
    end

    for _, row in ipairs(item_index.rows or {}) do
        if not M.is_equipment_row(row) then goto continue_row end
        if not M.can_class_use(row, target_class) then goto continue_row end
        if type(row.slots) == "table" and #row.slots > 0 then
            for _, sid in ipairs(row.slots) do
                consider_row(row, tonumber(sid))
            end
        elseif M.is_usable_in_slot(row, 22, target_class) then
            consider_row(row, 22)
        end
        ::continue_row::
    end

    local slots_out = {}
    local slots_with_upgrades = 0
    local total_upgrades = 0

    for _, slot_def in ipairs(opts.slot_defs or {}) do
        local slot_id = tonumber(slot_def.id)
        local current = equipped_map[slot_id]
        local wrapped = {}
        for _, row in ipairs(buckets[slot_id] or {}) do
            wrapped[#wrapped + 1] = decorate_candidate(row, current, primary_key, compare_keys)
        end
        sort_candidates(wrapped, true)

        local upgrade_count = 0
        for _, cand in ipairs(wrapped) do
            if cand.delta and cand.delta > 0 then upgrade_count = upgrade_count + 1 end
        end
        if upgrade_count > 0 then slots_with_upgrades = slots_with_upgrades + 1 end
        total_upgrades = total_upgrades + upgrade_count

        local top = {}
        for i = 1, math.min(top_n, #wrapped) do top[i] = wrapped[i] end

        local equipped_stats = {}
        for _, key in ipairs(compare_keys) do
            equipped_stats[key] = M.stat_value(current, key, EQUIP_REPLACE_STATS)
        end

        slots_out[#slots_out + 1] = {
            slotId = slot_id,
            label = slot_def.label,
            group = slot_def.group,
            equipped = current,
            equippedStat = equipped_stats[primary_key] or 0,
            equippedStats = equipped_stats,
            candidates = wrapped,
            top = top,
            best = wrapped[1],
            alt = wrapped[2],
            upgradeCount = upgrade_count,
            totalCount = #wrapped,
        }
    end

    local worn_totals, worn_ok = M.worn_stat_totals(target_key, compare_keys)

    return slots_out, {
        targetKey = target_key,
        targetClass = target_class,
        targetLevel = target_level,
        targetName = target_name,
        compareStat = primary_key,
        compareStats = compare_keys,
        comparePrimary = primary_key,
        wornTotals = worn_totals,
        wornTotalsAvailable = worn_ok == true,
        slotsWithUpgrades = slots_with_upgrades,
        totalUpgrades = total_upgrades,
    }
end

-- Per-item "why isn't this showing?" check for equipment suggestions. Given a
-- name fragment, reports the first gate each matching item fails for the target
-- (or that it would show, and for which slot). Mirrors aug_suggestions.explain.
function M.explain(opts)
    opts = type(opts) == "table" and opts or {}
    local needle = tostring(opts.needle or ""):lower():match("^%s*(.-)%s*$") or ""
    if needle == "" then return {} end
    local items = require('items')
    local target_key = opts.targetKey or "__self__"
    local scope = opts.scope or "all"
    local loc_filter = opts.locationFilter or "all"
    local snap = views.source_snapshot(target_key)
    local target_class = snap and snap.class or ""
    local target_level = tonumber(snap and snap.level) or 0
    local target_name = snap and snap.name or views.source_owner_name(target_key)
    local target_clean = views.clean_name(target_name)
    local equipped_map = snap and views.index_equipped(snap) or {}
    local e3_names = scope == "e3" and views.e3_connected_names() or nil

    item_index.get(false)
    local lines = {}
    for _, row in ipairs(item_index.rows or {}) do
        if M.is_equipment_row(row) and tostring(row.name or ""):lower():find(needle, 1, true) then
            local who = string.format("%s [%s]", row.name or "?", row.owner or "?")
            local fit_slots = {}
            if type(row.slots) == "table" then
                for _, sid in ipairs(row.slots) do fit_slots[#fit_slots + 1] = tonumber(sid) end
            end
            local reason
            if not M.can_class_use(row, target_class) then
                if type(row.classes) ~= "table" or #row.classes == 0 then
                    reason = "no class data captured for this item (re-sync source for full data)"
                else
                    reason = string.format("%s (%s) is not in the item's class list", target_name or "target", target_class)
                end
            elseif #fit_slots == 0 then
                reason = "no equip slot recorded for this item (re-sync source for full data)"
            else
                local show_slot, blocked = nil, nil
                for _, sid in ipairs(fit_slots) do
                    local gate
                    if not M.level_allowed(row, target_level) then
                        gate = string.format("needs level %d (target is %d)", tonumber(row.requiredLevel) or 0, target_level)
                    elseif not owner_allowed(row, scope, e3_names) then
                        gate = "owner is outside the current Scope filter"
                    elseif not location_allowed(row, loc_filter) then
                        gate = "hidden by the Location filter"
                    elseif (tonumber(row.nodrop) or 0) == 1 and views.clean_name(row.owner) ~= target_clean then
                        gate = "no-drop and owned by another character"
                    else
                        local current = equipped_map[sid]
                        if current and current.name and row.name == current.name
                            and views.clean_name(row.owner) == target_clean
                            and M.location_bucket(row) == "equipped" then
                            gate = "this is the item already worn in that slot"
                        elseif M.is_same_target_equipped_in_equivalent_slot(row, target_clean, sid) then
                            gate = "already worn in the paired slot"
                        end
                    end
                    if gate == nil then show_slot = sid; break end
                    blocked = blocked or gate
                end
                if show_slot then
                    reason = "WOULD SHOW for " .. tostring(items.slot_display_name(show_slot) or ("slot " .. show_slot))
                else
                    reason = blocked or "filtered out"
                end
            end
            lines[#lines + 1] = who .. ": " .. reason
            if #lines >= 8 then break end
        end
    end
    if #lines == 0 then
        lines[1] = string.format("No equipment named like '%s' is in the indexed pool (synced? in scope?).", needle)
    end
    return lines
end

function M.virtual_candidate(item_id, item_name, slot_id)
    local items = require('items')
    slot_id = tonumber(slot_id) or 2
    local id = tonumber(item_id) or 0
    local name = tostring(item_name or "")
    local virtual = items.make_virtual_item(id, name, slot_id)
    return {
        name = virtual.name or name or "?",
        id = tonumber(virtual.id) or id,
        stats = virtual.stats or stat_defs.default_stats(),
        baseStats = virtual.baseStats or virtual._baseStats or virtual.stats or stat_defs.default_stats(),
        depth = virtual.depth or "loadout",
    }
end

function M.whatif_targets(item_id, item_name, slot_id, scope, stat_keys)
    scope = scope or "all"
    stat_keys = type(stat_keys) == "table" and stat_keys or { "ac" }
    local primary = stat_keys[1] or "ac"
    slot_id = tonumber(slot_id) or 2
    local candidate = M.virtual_candidate(item_id, item_name, slot_id)
    local keys = views.scoped_source_keys(scope) or views.source_keys(true)
    local out = {}
    for _, key in ipairs(keys) do
        local snap = views.source_snapshot(key)
        if not snap then goto continue_target end
        local current = M.target_equipped_item(key, slot_id)
        local deltas, stats = {}, {}
        for _, sk in ipairs(stat_keys) do
            deltas[sk] = M.upgrade_delta(candidate, current, sk, EQUIP_REPLACE_STATS)
            stats[sk] = M.stat_value(candidate, sk, EQUIP_REPLACE_STATS)
        end
        out[#out + 1] = {
            key = key,
            name = snap.name or views.source_owner_name(key),
            class = snap.class or "",
            status = snap.status or "",
            current = current,
            deltas = deltas,
            stats = stats,
            primary_delta = M.upgrade_delta(candidate, current, primary, EQUIP_REPLACE_STATS),
        }
        ::continue_target::
    end
    table.sort(out, function(a, b)
        local da = a.primary_delta
        local db = b.primary_delta
        if da == nil and db == nil then return tostring(a.name) < tostring(b.name) end
        if da == nil then return false end
        if db == nil then return true end
        if da ~= db then return da > db end
        return tostring(a.name) < tostring(b.name)
    end)
    return out, candidate
end

return M
