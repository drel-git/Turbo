-- TurboGear/snapshot_delta.lua
-- Pure helpers for changed-slot inventory deltas: diff two item lists by slot
-- identity and apply a delta to a cached list. No mq/store dependencies so the
-- logic is unit-testable offline (see tests/turbogear_snapshot_delta_test.lua).
--
-- A "slot key" identifies WHERE an item sits (location/where/slotid/slotname),
-- deliberately excluding the item id so a swapped item shows as changed-in-place
-- rather than remove+add.

local M = {}

local BUCKETS = { "equipped", "bags", "bank" }
M.BUCKETS = BUCKETS

function M.slot_key(item)
    if type(item) ~= "table" then return "" end
    return table.concat({
        tostring(item.location or ""),
        tostring(item.where or ""),
        tostring(item.slotid or ""),
        tostring(item.slotname or ""),
    }, "\31")
end

-- Content signature for change detection (id + name + qty + augs). Mirrors the
-- fields store.lua considers meaningful for inventory payloads.
function M.item_sig(item)
    if type(item) ~= "table" then return "" end
    local parts = {
        tostring(item.id or 0),
        tostring(item.name or ""),
        tostring(item.qty or item.count or 1),
        item.empty and "e" or "f",
    }
    if type(item.augs) == "table" then
        for _, aug in ipairs(item.augs) do
            parts[#parts + 1] = string.format("a%s:%s:%s",
                tostring(aug.index or 0),
                tostring(aug.id or 0),
                aug.empty and "e" or "f")
        end
    end
    return table.concat(parts, "|")
end

function M.index_list(list)
    local out = {}
    for _, item in ipairs(list or {}) do
        local key = M.slot_key(item)
        if key ~= "" then out[key] = item end
    end
    return out
end

-- Diff one bucket. old_by_key: slot_key -> item (baseline). new_list: array.
-- Returns changed (array of items from new_list) and removed (array of slot keys).
function M.diff_lists(old_by_key, new_list)
    old_by_key = type(old_by_key) == "table" and old_by_key or {}
    local changed, removed = {}, {}
    local seen = {}
    for _, item in ipairs(new_list or {}) do
        local key = M.slot_key(item)
        if key ~= "" then
            seen[key] = true
            local prev = old_by_key[key]
            if not prev or M.item_sig(prev) ~= M.item_sig(item) then
                changed[#changed + 1] = item
            end
        end
    end
    for key, _ in pairs(old_by_key) do
        if not seen[key] then removed[#removed + 1] = key end
    end
    table.sort(removed)
    return changed, removed
end

-- Build a delta between a baseline ({ equipped = by_key, bags = by_key, bank = by_key })
-- and a fresh snapshot. opts.include_bank must only be true when the snapshot's
-- bank list came from a live scan; otherwise a closed bank window would look
-- like every bank item being removed.
-- Returns delta table (or nil if baseline missing) and total change count.
function M.diff_snapshot(baseline, snap, opts)
    if type(baseline) ~= "table" or type(snap) ~= "table" then return nil, 0 end
    opts = type(opts) == "table" and opts or {}
    local delta = {
        name = snap.name,
        server = snap.server,
        class = snap.class,
        level = snap.level,
        updated = snap.updated,
        seq = tonumber(snap.seq),
        inventoryUpdated = tonumber(snap.inventoryUpdated) or tonumber(snap.updated),
        changed = {},
        removed = {},
    }
    local total = 0
    for _, bucket in ipairs(BUCKETS) do
        local skip = bucket == "bank" and opts.include_bank ~= true
        if not skip and type(baseline[bucket]) == "table" then
            local changed, removed = M.diff_lists(baseline[bucket], snap[bucket])
            if #changed > 0 then delta.changed[bucket] = changed end
            if #removed > 0 then delta.removed[bucket] = removed end
            total = total + #changed + #removed
        end
    end
    return delta, total
end

-- Apply changed/removed to a cached list. Returns a new array (input untouched).
function M.apply_to_list(list, changed, removed)
    local by_key, order = {}, {}
    for _, item in ipairs(list or {}) do
        local key = M.slot_key(item)
        if key ~= "" and not by_key[key] then
            by_key[key] = item
            order[#order + 1] = key
        end
    end
    for _, key in ipairs(removed or {}) do
        by_key[tostring(key)] = nil
    end
    for _, item in ipairs(changed or {}) do
        local key = M.slot_key(item)
        if key ~= "" then
            if not by_key[key] then order[#order + 1] = key end
            by_key[key] = item
        end
    end
    local out = {}
    for _, key in ipairs(order) do
        if by_key[key] ~= nil then
            out[#out + 1] = by_key[key]
            by_key[key] = nil -- guard against duplicate keys in order
        end
    end
    return out
end

-- Snapshot -> baseline shape used by diff_snapshot.
function M.baseline_from_snapshot(snap, opts)
    if type(snap) ~= "table" then return nil end
    opts = type(opts) == "table" and opts or {}
    local out = {}
    for _, bucket in ipairs(BUCKETS) do
        if bucket ~= "bank" or opts.include_bank == true then
            out[bucket] = M.index_list(snap[bucket])
        end
    end
    return out
end

function M.count_changes(delta)
    if type(delta) ~= "table" then return 0 end
    local total = 0
    for _, bucket in ipairs(BUCKETS) do
        total = total + #((delta.changed or {})[bucket] or {})
        total = total + #((delta.removed or {})[bucket] or {})
    end
    return total
end

return M
