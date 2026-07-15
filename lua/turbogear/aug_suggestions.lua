-- TurboGear/aug_suggestions.lua
-- Loose-aug candidates for empty equip sockets (Phase 2C). Snapshot/index only.

local item_index = require('item_index')
local views = require('views')
local items = require('items')
local suggestions = require('suggestions')
local stat_defs = require('stat_defs')

local M = {}

local MAX_AUG_SOCKET_TYPE = 30
local STAT_CAPS = {
    shielding = 50,
    avoidance = 100,
    accuracy = 150,
    spellShield = 50,
    dotShielding = 50,
    dsMitigation = 50,
    stunResist = 50,
    strikethrough = 50,
}

-- Aug socket matching.
-- On this server (and for these items generally), ${Item.AugType} returns the
-- SCALAR socket type number, e.g. 8 for a "Type 8" socket, and the host socket
-- type read from AugSlotN is the same scalar. So an aug fits when its augType
-- equals the socket type. A previous bitfield model (treating augType as a
-- 2^(type-1) bitmask) was a regression: a scalar type-8 aug failed its real T8
-- socket and falsely matched T4. Evidence it's scalar here: under the old
-- exact-match code, a type-8 aug correctly matched an S1 T8 socket.
--
-- If you ever run a server whose Item.AugType is a true bitfield, flip this to
-- true. Do NOT "accept both" - on a scalar server the bitfield branch creates
-- false positives (scalar 8 -> T4).
local AUG_TYPE_IS_BITFIELD = false

local function aug_type_has_socket(aug_type, socket_type)
    aug_type = math.floor(tonumber(aug_type) or 0)
    socket_type = math.floor(tonumber(socket_type) or 0)
    if aug_type <= 0 or socket_type <= 0 or socket_type > MAX_AUG_SOCKET_TYPE then return false end
    if not AUG_TYPE_IS_BITFIELD then
        return aug_type == socket_type
    end
    local mask = 2 ^ (socket_type - 1)
    return (math.floor(aug_type / mask) % 2) == 1
end

local function aug_fit_types(row)
    local out = {}
    local aug_type = tonumber(row and row.augType) or 0
    for stype = 1, MAX_AUG_SOCKET_TYPE do
        if aug_type_has_socket(aug_type, stype) then out[#out + 1] = stype end
    end
    return out
end

local function aug_fit_label(row)
    local parts = {}
    for _, stype in ipairs(aug_fit_types(row)) do parts[#parts + 1] = "T" .. tostring(stype) end
    if #parts == 0 then return "raw " .. tostring(row and row.augType or 0) end
    return table.concat(parts, ",")
end

function M.aug_fits_socket(row, socket_type)
    socket_type = tonumber(socket_type) or 0
    if socket_type <= 0 or not row then return false end
    if row.kind ~= "aug" and tostring(row.itemType or "") ~= "aug" then return false end
    local aug_type = tonumber(row.augType) or 0
    return aug_type_has_socket(aug_type, socket_type)
end

function M.is_loose_aug_row(row)
    return row and row.where == "loose_aug"
end

function M.collect_empty_sockets(snap)
    local out = {}
    if not snap then return out end
    local map = views.index_equipped(snap)
    for _, group in ipairs(items.grouped_slots()) do
        for _, slot in ipairs(group.slots or {}) do
            if tonumber(slot.id) == 22 then goto continue_slot end
            local it = map[slot.id]
            if it then
                for _, a in ipairs(it.augs or {}) do
                    if a.empty and not items.is_skippable_socket(a.type) then
                        out[#out + 1] = {
                            slotId = slot.id,
                            slotLabel = slot.label,
                            group = group.label,
                            hostItem = it.name,
                            hostItemId = it.id,
                            socketIndex = a.index,
                            socketType = a.type,
                        }
                    end
                end
            end
            ::continue_slot::
        end
    end
    return out
end

function M.collect_aug_sockets(snap, opts)
    opts = type(opts) == "table" and opts or {}
    local include_filled = opts.includeFilled == true
    local out = {}
    if not snap then return out end
    local map = views.index_equipped(snap)
    for _, group in ipairs(items.grouped_slots()) do
        for _, slot in ipairs(group.slots or {}) do
            if tonumber(slot.id) == 22 then goto continue_slot end
            local it = map[slot.id]
            if it then
                for _, a in ipairs(it.augs or {}) do
                    if not items.is_skippable_socket(a.type) and (include_filled or a.empty) then
                        out[#out + 1] = {
                            slotId = slot.id,
                            slotLabel = slot.label,
                            group = group.label,
                            hostItem = it.name,
                            hostItemId = it.id,
                            socketIndex = a.index,
                            socketType = a.type,
                            currentAug = (not a.empty) and a or nil,
                            empty = a.empty and true or false,
                        }
                    end
                end
            end
            ::continue_slot::
        end
    end
    return out
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
    local bucket = suggestions.location_bucket(row)
    if loc_filter == "equipped" then return bucket == "equipped" end
    if loc_filter == "bags" then return bucket == "bags" end
    if loc_filter == "bank" then return bucket == "bank" end
    if loc_filter == "stored" then return bucket == "bags" or bucket == "bank" end
    return true
end

local function decorate_candidate(row, stat_key)
    return {
        row = row,
        stat = suggestions.stat_value(row, stat_key),
    }
end

local function class_warning_for(row, target_class)
    target_class = tostring(target_class or "")
    if suggestions.can_class_use(row, target_class, { allowUnknownClass = true }) then return nil end
    if target_class == "" then
        return "Target class unknown; verify the aug before installing."
    end
    return "Class metadata does not confirm " .. target_class .. "; verify before installing."
end

local function decorate_aug_candidate(row, stat_key, target_class)
    local wrapped = decorate_candidate(row, stat_key)
    wrapped.classWarning = class_warning_for(row, target_class)
    return wrapped
end

local function sort_candidates(wrapped)
    table.sort(wrapped, function(a, b)
        if (a.stat or 0) ~= (b.stat or 0) then return (a.stat or 0) > (b.stat or 0) end
        return tostring(a.row.name or ""):lower() < tostring(b.row.name or ""):lower()
    end)
end

local function normalize_compare_stats(stats, fallback)
    local out = {}
    local seen = {}
    if type(stats) == "table" then
        for _, key in ipairs(stats) do
            key = tostring(key or "")
            if key ~= "" and not seen[key] then
                seen[key] = true
                out[#out + 1] = key
            end
        end
    end
    fallback = tostring(fallback or "")
    if #out == 0 and fallback ~= "" then out[1] = fallback end
    if #out == 0 then out[1] = "shielding" end
    return out
end

local function stat_value(obj, key)
    return suggestions.stat_value(obj, key)
end

local function capped_delta(key, raw_delta, live_stats)
    raw_delta = tonumber(raw_delta) or 0
    local cap = STAT_CAPS[key]
    if not cap then return raw_delta end
    local live = tonumber(live_stats and live_stats[key])
    if not live then return raw_delta end
    if raw_delta > 0 then
        return math.max(0, math.min(raw_delta, cap - live))
    end
    return raw_delta
end

local function current_stat_totals(snap, keys)
    local totals = {}
    for _, key in ipairs(keys or {}) do totals[key] = 0 end
    for _, item in ipairs((snap and snap.equipped) or {}) do
        for _, key in ipairs(keys or {}) do
            totals[key] = (totals[key] or 0) + stat_value(item, key)
        end
    end
    return totals
end

local function cap_stat_totals(snap, keys)
    local live = snap and snap.liveStats or nil
    local worn = current_stat_totals(snap, keys)
    local out = {}
    local reliable = false
    for _, key in ipairs(keys or {}) do
        local live_val = tonumber(live and live[key])
        local worn_val = tonumber(worn and worn[key]) or 0
        if live_val and live_val > 0 then
            out[key] = live_val
            reliable = true
        elseif worn_val > 0 then
            out[key] = worn_val
            reliable = true
        else
            out[key] = nil
        end
    end
    return out, worn, reliable
end

local function candidate_delta(candidate, current_aug, key)
    local cand = stat_value(candidate, key)
    local cur = stat_value(current_aug, key)
    if stat_defs.lower_better(key) then return cur - cand end
    return cand - cur
end

local function score_candidate(candidate, current_aug, keys, live_stats)
    local score = 0
    local deltas = {}
    local effective = {}
    for i, key in ipairs(keys or {}) do
        local raw = candidate_delta(candidate, current_aug, key)
        local eff = capped_delta(key, raw, live_stats)
        deltas[key] = raw
        effective[key] = eff
        local weight = 10 ^ math.max(0, 6 - i)
        score = score + eff * weight
    end
    return score, deltas, effective
end

local function positive_sum(values, keys)
    local total = 0
    for _, key in ipairs(keys or {}) do
        local n = tonumber(values and values[key]) or 0
        if n > 0 then total = total + n end
    end
    return total
end

local function strength_pass(pair, keys, strength)
    strength = tostring(strength or "any")
    local effective = pair and pair.effectiveDeltas or {}
    local primary = tonumber(effective[keys[1]]) or 0
    local combined = positive_sum(effective, keys)
    if strength == "major" then
        return primary >= 5 or combined >= 10
    elseif strength == "meaningful" then
        return primary >= 2 or combined >= 4
    end
    return (pair and tonumber(pair.score) or 0) > 0
end

local function decorate_plan_candidate(row, current_aug, keys, live_stats, target_class)
    local wrapped = decorate_aug_candidate(row, keys[1], target_class)
    wrapped.score, wrapped.deltas, wrapped.effectiveDeltas = score_candidate(row, current_aug, keys, live_stats)
    return wrapped
end

local function socket_key(sock)
    return table.concat({
        tostring(sock and sock.slotId or ""),
        tostring(sock and sock.socketIndex or ""),
        tostring(sock and sock.socketType or ""),
        tostring(sock and sock.hostItemId or ""),
    }, ":")
end

local function row_key(row)
    if type(row) ~= "table" then return "" end
    return tostring(row.sourceKey or row.id or row.name or "")
end

local function aug_identity(row)
    if type(row) ~= "table" then return "" end
    local id = tonumber(row.id) or 0
    if id > 0 then return "id:" .. tostring(id) end
    local name = tostring(row.name or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if name ~= "" then return "n:" .. name end
    return row_key(row)
end

local function plan_reject_key(target_key, sock, row)
    return table.concat({
        tostring(target_key or ""),
        socket_key(sock),
        row_key(row),
    }, "\31")
end

local function lore_key(obj)
    if type(obj) ~= "table" then return nil end
    if not (obj.lore == true or (tonumber(obj.loreGroup) or 0) > 0) then return nil end
    local group = tonumber(obj.loreGroup) or 0
    if group > 0 then return "g:" .. tostring(group) end
    local id = tonumber(obj.id) or 0
    if id > 0 then return "i:" .. tostring(id) end
    local name = tostring(obj.name or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if name ~= "" then return "n:" .. name end
    return nil
end

local function installed_lore_keys(sockets)
    local out = {}
    for _, sock in ipairs(sockets or {}) do
        local key = lore_key(sock and sock.currentAug)
        if key then out[key] = true end
    end
    return out
end

local function socket_type_set(sockets)
    local out = {}
    for _, sock in ipairs(sockets or {}) do
        local stype = tonumber(sock.socketType) or 0
        if stype > 0 then out[stype] = true end
    end
    return out
end

local function aug_matches_socket_set(row, socket_types)
    for stype in pairs(socket_types or {}) do
        if M.aug_fits_socket(row, stype) then return true end
    end
    return false
end

local function scan_pool_summary(opts, sockets)
    opts = type(opts) == "table" and opts or {}
    local scope = opts.scope or "all"
    local loc_filter = opts.locationFilter or "all"
    local target_key = opts.targetKey or "__self__"
    local snap = views.source_snapshot(target_key)
    local target_class = snap and snap.class or ""
    local target_level = tonumber(snap and snap.level) or 0
    local target_clean = views.clean_name(snap and snap.name or views.source_owner_name(target_key))
    local types = socket_type_set(sockets)
    local e3_names = scope == "e3" and views.e3_connected_names() or nil
    local summary = {
        loose = 0,
        socket = 0,
        class = 0,
        classWarning = 0,
        level = 0,
        scope = 0,
        location = 0,
        tradeable = 0,
        noDropBlocked = 0,
        socketTypes = {},
    }
    for stype in pairs(types) do summary.socketTypes[#summary.socketTypes + 1] = stype end
    table.sort(summary.socketTypes)

    item_index.get(false)
    for _, row in ipairs(item_index.rows or {}) do
        if M.is_loose_aug_row(row) then
            summary.loose = summary.loose + 1
            if aug_matches_socket_set(row, types) then
                summary.socket = summary.socket + 1
                if suggestions.can_class_use(row, target_class, { allowUnknownClass = true }) then
                    summary.class = summary.class + 1
                else
                    summary.classWarning = summary.classWarning + 1
                end
                if suggestions.level_allowed(row, target_level) then
                    summary.level = summary.level + 1
                    if owner_allowed(row, scope, e3_names) then
                        summary.scope = summary.scope + 1
                        if location_allowed(row, loc_filter) then
                            summary.location = summary.location + 1
                            if ((tonumber(row.nodrop) or 0) ~= 1 and row.attuned ~= true) or views.clean_name(row.owner) == target_clean then
                                summary.tradeable = summary.tradeable + 1
                            else
                                summary.noDropBlocked = summary.noDropBlocked + 1
                            end
                        end
                    end
                end
            end
        end
    end
    return summary
end

local function scan_candidates(opts)
    opts = type(opts) == "table" and opts or {}
    local target_key = opts.targetKey or "__self__"
    local socket_type = tonumber(opts.socketType) or 0
    local scope = opts.scope or "all"
    local loc_filter = opts.locationFilter or "all"
    local compare_stat = tostring(opts.compareStat or "shielding")
    local needle = tostring(opts.search or ""):lower()

    local snap = views.source_snapshot(target_key)
    local target_class = snap and snap.class or ""
    local target_level = tonumber(snap and snap.level) or 0
    local target_clean = views.clean_name(snap and snap.name or views.source_owner_name(target_key))

    item_index.get(false)
    local e3_names = scope == "e3" and views.e3_connected_names() or nil
    local results = {}

    for _, row in ipairs(item_index.rows or {}) do
        if not M.is_loose_aug_row(row) then goto continue end
        if not M.aug_fits_socket(row, socket_type) then goto continue end
        if not suggestions.level_allowed(row, target_level) then goto continue end
        if not owner_allowed(row, scope, e3_names) then goto continue end
        if not location_allowed(row, loc_filter) then goto continue end
        if ((tonumber(row.nodrop) or 0) == 1 or row.attuned == true) and views.clean_name(row.owner) ~= target_clean then goto continue end
        if needle ~= "" then
            local hay = table.concat({ row.name or "", row.owner or "", row.location or "" }, " "):lower()
            if not hay:find(needle, 1, true) then goto continue end
        end
        results[#results + 1] = row
        ::continue::
    end

    local wrapped = {}
    for i, row in ipairs(results) do wrapped[i] = decorate_aug_candidate(row, compare_stat, target_class) end
    sort_candidates(wrapped)

    return wrapped, {
        targetKey = target_key,
        targetClass = target_class,
        targetLevel = target_level,
        targetName = snap and snap.name or views.source_owner_name(target_key),
        socketType = socket_type,
        compareStat = compare_stat,
    }
end

function M.get_available(opts)
    return scan_candidates(opts)
end

function M.build_overview(opts)
    opts = type(opts) == "table" and opts or {}
    local target_key = opts.targetKey or "__self__"
    local scope = opts.scope or "all"
    local loc_filter = opts.locationFilter or "all"
    local compare_stat = tostring(opts.compareStat or "shielding")
    local actionable_only = opts.actionableOnly == true
    local top_n = tonumber(opts.topN) or 2
    local rejected = type(opts.rejectedKeys) == "table" and opts.rejectedKeys or {}

    local snap = views.source_snapshot(target_key)
    local sockets = M.collect_empty_sockets(snap)
    local out = {}
    local with_candidates = 0
    local total_candidates = 0

    for _, sock in ipairs(sockets) do
        local wrapped = scan_candidates({
            targetKey = target_key,
            socketType = sock.socketType,
            scope = scope,
            locationFilter = loc_filter,
            compareStat = compare_stat,
        })
        if next(rejected) ~= nil then
            local filtered = {}
            for _, cand in ipairs(wrapped) do
                if not rejected[plan_reject_key(target_key, sock, cand and cand.row)] then
                    filtered[#filtered + 1] = cand
                end
            end
            wrapped = filtered
        end
        local count = #wrapped
        if count > 0 then with_candidates = with_candidates + 1 end
        total_candidates = total_candidates + count

        local best = wrapped[1]
        local alt = nil
        local best_identity = aug_identity(best and best.row)
        for i = 2, count do
            local cand_identity = aug_identity(wrapped[i] and wrapped[i].row)
            if cand_identity ~= "" and cand_identity ~= best_identity then
                alt = wrapped[i]
                break
            end
        end

        local rec = {
            slotId = sock.slotId,
            slotLabel = sock.slotLabel,
            group = sock.group,
            hostItem = sock.hostItem,
            hostItemId = sock.hostItemId,
            socketIndex = sock.socketIndex,
            socketType = sock.socketType,
            candidates = wrapped,
            best = best,
            alt = alt,
            totalCount = count,
        }
        if not actionable_only or count > 0 then
            out[#out + 1] = rec
        end
    end

    return out, {
        targetKey = target_key,
        targetClass = snap and snap.class or "",
        targetLevel = tonumber(snap and snap.level) or 0,
        targetName = snap and snap.name or views.source_owner_name(target_key),
        compareStat = compare_stat,
        looseSummary = scan_pool_summary(opts, sockets),
        socketsWithCandidates = with_candidates,
        totalCandidates = total_candidates,
        totalEmptySockets = #sockets,
    }
end

function M.build_plan(opts)
    opts = type(opts) == "table" and opts or {}
    local target_key = opts.targetKey or "__self__"
    local scope = opts.scope or "all"
    local loc_filter = opts.locationFilter or "all"
    local compare_stats = normalize_compare_stats(opts.compareStats, opts.compareStat)
    local actionable_only = opts.actionableOnly ~= false
    local strength = tostring(opts.strength or "any")
    local top_n = tonumber(opts.topN) or 40
    local rejected = type(opts.rejectedKeys) == "table" and opts.rejectedKeys or {}

    local snap = views.source_snapshot(target_key)
    local target_class = snap and snap.class or ""
    local target_level = tonumber(snap and snap.level) or 0
    local target_name = snap and snap.name or views.source_owner_name(target_key)
    local target_clean = views.clean_name(target_name)
    local e3_names = scope == "e3" and views.e3_connected_names() or nil
    local sockets = M.collect_aug_sockets(snap, { includeFilled = true })
    local cap_stats, worn_stats, cap_stats_reliable = cap_stat_totals(snap, compare_stats)
    local target_installed_lore = installed_lore_keys(sockets)

    item_index.get(false)
    local all_pairs = {}
    local socket_count, filled_count, empty_count = #sockets, 0, 0
    local lore_blocked = 0
    local pair_summary = {
        socketPairs = 0,
        classConfirmedPairs = 0,
        classWarningPairs = 0,
        levelPairs = 0,
        scopePairs = 0,
        locationPairs = 0,
        tradeablePairs = 0,
        rejectedPairs = 0,
        noDropBlockedPairs = 0,
        loreBlockedPairs = 0,
        positivePairs = 0,
        blockedExamples = {},
    }

    for _, sock in ipairs(sockets) do
        if sock.currentAug then filled_count = filled_count + 1 else empty_count = empty_count + 1 end
        for _, row in ipairs(item_index.rows or {}) do
            if not M.is_loose_aug_row(row) then goto continue_aug end
            if not M.aug_fits_socket(row, sock.socketType) then goto continue_aug end
            pair_summary.socketPairs = pair_summary.socketPairs + 1
            if suggestions.can_class_use(row, target_class, { allowUnknownClass = true }) then
                pair_summary.classConfirmedPairs = pair_summary.classConfirmedPairs + 1
            else
                pair_summary.classWarningPairs = pair_summary.classWarningPairs + 1
            end
            if not suggestions.level_allowed(row, target_level) then goto continue_aug end
            pair_summary.levelPairs = pair_summary.levelPairs + 1
            if not owner_allowed(row, scope, e3_names) then goto continue_aug end
            pair_summary.scopePairs = pair_summary.scopePairs + 1
            if not location_allowed(row, loc_filter) then goto continue_aug end
            pair_summary.locationPairs = pair_summary.locationPairs + 1
            if rejected[plan_reject_key(target_key, sock, row)] then
                pair_summary.rejectedPairs = pair_summary.rejectedPairs + 1
                goto continue_aug
            end
            if ((tonumber(row.nodrop) or 0) == 1 or row.attuned == true) and views.clean_name(row.owner) ~= target_clean then
                pair_summary.noDropBlockedPairs = pair_summary.noDropBlockedPairs + 1
                if #pair_summary.blockedExamples < 8 then
                    pair_summary.blockedExamples[#pair_summary.blockedExamples + 1] = {
                        name = row.name,
                        owner = row.owner,
                        slot = sock.slotLabel,
                        socketType = sock.socketType,
                    }
                end
                goto continue_aug
            end
            pair_summary.tradeablePairs = pair_summary.tradeablePairs + 1
            local lkey = lore_key(row)
            if lkey and target_installed_lore[lkey] and lore_key(sock.currentAug) ~= lkey then
                lore_blocked = lore_blocked + 1
                pair_summary.loreBlockedPairs = pair_summary.loreBlockedPairs + 1
                goto continue_aug
            end

            local wrapped = decorate_plan_candidate(row, sock.currentAug, compare_stats, cap_stats, target_class)
            local pair = {
                socket = sock,
                aug = wrapped,
                score = wrapped.score,
                deltas = wrapped.deltas,
                effectiveDeltas = wrapped.effectiveDeltas,
                loreKey = lkey,
            }
            local passes_strength = strength_pass(pair, compare_stats, strength)
            if passes_strength then pair_summary.positivePairs = pair_summary.positivePairs + 1 end
            if passes_strength or (not actionable_only and strength == "any") then
                all_pairs[#all_pairs + 1] = pair
            end
            ::continue_aug::
        end
    end

    table.sort(all_pairs, function(a, b)
        if (a.score or 0) ~= (b.score or 0) then return (a.score or 0) > (b.score or 0) end
        local an = tostring(a.aug and a.aug.row and a.aug.row.name or ""):lower()
        local bn = tostring(b.aug and b.aug.row and b.aug.row.name or ""):lower()
        return an < bn
    end)

    local used_socket, used_aug, used_lore = {}, {}, {}
    local steps = {}
    local totals = {}
    for _, key in ipairs(compare_stats) do totals[key] = 0 end

    for _, pair in ipairs(all_pairs) do
        if #steps >= top_n then break end
        local skey = socket_key(pair.socket)
        local row = pair.aug and pair.aug.row
        local akey = tostring(row and row.sourceKey or row and row.id or "")
        local lkey = pair.loreKey
        if skey ~= "" and akey ~= "" and not used_socket[skey] and not used_aug[akey]
            and not (lkey and used_lore[lkey]) then
            local passes_strength = strength_pass(pair, compare_stats, strength)
            if passes_strength or (not actionable_only and strength == "any") then
                used_socket[skey] = true
                used_aug[akey] = true
                if lkey then used_lore[lkey] = true end
                for _, key in ipairs(compare_stats) do
                    totals[key] = (totals[key] or 0) + (tonumber(pair.deltas and pair.deltas[key]) or 0)
                end
                steps[#steps + 1] = pair
            end
        end
    end

    return steps, {
        targetKey = target_key,
        targetClass = target_class,
        targetLevel = target_level,
        targetName = target_name,
        compareStats = compare_stats,
        strength = strength,
        socketCount = socket_count,
        filledCount = filled_count,
        emptyCount = empty_count,
        candidatePairs = #all_pairs,
        totals = totals,
        liveStats = cap_stats,
        wornStats = worn_stats,
        capStatsReliable = cap_stats_reliable,
        loreBlocked = lore_blocked,
        looseSummary = scan_pool_summary(opts, sockets),
        pairSummary = pair_summary,
        caps = STAT_CAPS,
    }
end

function M.plan_reject_key(target_key, sock, row)
    return plan_reject_key(target_key, sock, row)
end

-- Per-aug "why isn't this showing?" check. Given a name fragment, reports the
-- first gate each matching loose aug fails for the target (or that it would
-- show). Lets testers self-diagnose instead of reading the aggregate funnel.
function M.explain(opts)
    opts = type(opts) == "table" and opts or {}
    local needle = tostring(opts.needle or ""):lower():match("^%s*(.-)%s*$") or ""
    if needle == "" then return {} end
    local target_key = opts.targetKey or "__self__"
    local scope = opts.scope or "all"
    local loc_filter = opts.locationFilter or "all"
    local snap = views.source_snapshot(target_key)
    local target_class = snap and snap.class or ""
    local target_level = tonumber(snap and snap.level) or 0
    local target_name = snap and snap.name or views.source_owner_name(target_key)
    local target_clean = views.clean_name(target_name)
    local empty_types = socket_type_set(M.collect_empty_sockets(snap))
    local e3_names = scope == "e3" and views.e3_connected_names() or nil

    item_index.get(false)
    local lines = {}
    for _, row in ipairs(item_index.rows or {}) do
        if M.is_loose_aug_row(row) and tostring(row.name or ""):lower():find(needle, 1, true) then
            local atype = tonumber(row.augType) or 0
            local who = string.format("%s [%s, %s]", row.name or "?", aug_fit_label(row), row.owner or "?")
            local reason
            if atype <= 0 then
                reason = "no aug type captured - re-sync the source character (full snapshot)"
            elseif not aug_matches_socket_set(row, empty_types) then
                reason = string.format("%s has no empty %s socket open", target_name or "target", aug_fit_label(row))
            else
                local class_warning = class_warning_for(row, target_class)
                if not suggestions.level_allowed(row, target_level) then
                    reason = string.format("needs level %d (target is %d)", tonumber(row.requiredLevel) or 0, target_level)
                elseif not owner_allowed(row, scope, e3_names) then
                    reason = "owner is outside the current Scope filter"
                elseif not location_allowed(row, loc_filter) then
                    reason = "hidden by the Location filter"
                elseif ((tonumber(row.nodrop) or 0) == 1 or row.attuned == true) and views.clean_name(row.owner) ~= target_clean then
                    reason = "no-drop/attuned and owned by another character"
                elseif class_warning then
                    reason = "WOULD SHOW with class warning - " .. class_warning
                else
                    reason = "WOULD SHOW - fits an empty socket and passes all filters"
                end
            end
            lines[#lines + 1] = who .. ": " .. reason
            if #lines >= 8 then break end
        end
    end
    if #lines == 0 then
        lines[1] = string.format("No loose aug named like '%s' is in the indexed pool (synced? in bags/bank?).", needle)
    end
    return lines
end

return M
