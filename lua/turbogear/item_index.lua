-- TurboGear/item_index.lua
-- Flattens Store snapshots into cached searchable rows. The current box's
-- cached live snapshot is overlaid so viewer-mode UIs do not show self-owned
-- items as offline/cache when Store still has an older persisted copy.

local store = require('store')
local Store = store.Store
local self_snapshot = require('snapshot')

local M = {
    rows = {},
    version = 0,
    content_version = -1,
    self_signature = "",
    summary = { total = 0, withAnyStat = 0 },
}

local function safe_stats(stats)
    return type(stats) == "table" and stats or {}
end

local function row_stats(item)
    local out = {}
    local stats = safe_stats(item and item.stats)
    for k, v in pairs(stats) do out[k] = v end
    if item and item.statsMerged ~= true and type(item.augs) == "table" then
        for _, aug in ipairs(item.augs) do
            if aug and not aug.empty and type(aug.stats) == "table" then
                for k, v in pairs(aug.stats) do
                    local n = tonumber(v) or 0
                    if n ~= 0 then out[k] = (tonumber(out[k]) or 0) + n end
                end
            end
        end
    end
    out.tribute = tonumber(item and item.tribute) or tonumber(out.tribute) or 0
    return out
end

local function row_base_stats(item)
    local out = {}
    local source = type(item and item.baseStats) == "table" and item.baseStats or nil
    if source then
        for k, v in pairs(source) do out[k] = v end
    else
        local stats = row_stats(item)
        for k, v in pairs(stats) do out[k] = v end
        if item and item.statsMerged == true and type(item.augs) == "table" then
            for _, aug in ipairs(item.augs) do
                if aug and not aug.empty and type(aug.stats) == "table" then
                    for k, v in pairs(aug.stats) do
                        local n = tonumber(v) or 0
                        if n ~= 0 then out[k] = (tonumber(out[k]) or 0) - n end
                    end
                end
            end
        end
    end
    out.tribute = tonumber(item and item.tribute) or tonumber(out.tribute) or 0
    return out
end

local function item_kind(item)
    if not item then return "item" end
    if (tonumber(item.augType) or 0) > 0 then return "aug" end
    if tostring(item.itemType or "") == "aug" then return "aug" end
    return "item"
end

local function source_label(snap)
    local status = tostring(snap.status or "offline")
    if status == "online" then
        local actor_seen = tonumber(snap.actorSeenAt) or 0
        if actor_seen > 0 and (os.time() - actor_seen) <= 45 then return "live" end
        return "visible/cache"
    end
    if status == "stale" then return "stale/cache" end
    return "offline/cache"
end

local function clean_text(s)
    return tostring(s or ""):lower():match("^%s*(.-)%s*$") or ""
end

local function same_owner(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then return false end
    local an, bn = clean_text(a.name), clean_text(b.name)
    if an == "" or bn == "" or an ~= bn then return false end
    local as, bs = clean_text(a.server), clean_text(b.server)
    return as == "" or bs == "" or as == bs
end

local function live_self_snapshot_for_index()
    local ok, snap = pcall(function() return self_snapshot.cached() end)
    if not ok or type(snap) ~= "table" or not snap.name then return nil end
    local out = {}
    for k, v in pairs(snap) do out[k] = v end
    local now = os.time()
    out.status = "online"
    out.actorSeenAt = now
    out.last_seen = now
    return out
end

local function self_index_signature()
    local snap = live_self_snapshot_for_index()
    if not snap then return "" end
    return table.concat({
        tostring(snap.server or ""),
        tostring(snap.name or ""),
        tostring(snap.depth or ""),
        tostring(snap.inventoryUpdated or snap.updated or ""),
        tostring(#(snap.equipped or {})),
        tostring(#(snap.bags or {})),
        tostring(#(snap.bank or {})),
    }, "|")
end

local function add_row(rows, snap, item, opts)
    if not snap or not item or item.empty then return end
    opts = opts or {}
    local name = item.name or "?"
    if name == "" or name == "Empty" then return end

    rows[#rows+1] = {
        owner = snap.name or "?",
        ownerClass = snap.class or "",
        ownerStatus = source_label(snap),
        server = snap.server or "",

        name = name,
        id = tonumber(item.id) or 0,
        qty = math.max(1, math.floor(tonumber(item.qty or item.count) or 1)),
        icon = tonumber(item.icon) or 0,
        kind = opts.kind or item_kind(item),
        where = opts.where or "unknown",
        locationGroup = opts.locationGroup or opts.where or "unknown",
        location = opts.location or item.where or item.location or "",
        slotid = tonumber(item.slotid) or item.slotid,
        slotname = item.slotname,
        installedIn = opts.installedIn or "",
        installedInId = opts.installedInId or 0,

        slots = type(item.slots) == "table" and item.slots or {},
        classes = type(item.classes) == "table" and item.classes or {},
        allClasses = item.allClasses and true or false,
        itemType = item.itemType or (item_kind(item) == "aug" and "aug" or "unknown"),
        requiredLevel = tonumber(item.requiredLevel) or 0,
        recommendedLevel = tonumber(item.recommendedLevel) or 0,
        tribute = tonumber(item.tribute) or 0,
        augType = tonumber(item.augType) or 0,
        nodrop = tonumber(item.nodrop) or 0,
        attuned = item.attuned and true or false,
        attunable = item.attunable and true or false,
        lore = item.lore and true or false,
        loreGroup = tonumber(item.loreGroup) or 0,
        depth = tostring(item.depth or snap.depth or ""),
        stats = row_stats(item),
        baseStats = row_base_stats(item),
        focusEffects = type(item.focusEffects) == "table" and item.focusEffects or {},
        wornFocusEffects = type(item.wornFocusEffects) == "table" and item.wornFocusEffects or {},
        clicky = item.clicky,

        sourceKey = opts.sourceKey or table.concat({
            snap.server or "", snap.name or "", opts.where or "",
            tostring(item.id or 0), tostring(opts.location or "")
        }, ":"),
    }
end

local function add_installed_augs(rows, snap, item, parent_where, parent_loc_group)
    if not item or not item.augs then return end
    local slot_label = item.slotname or item.where or item.location or "Item"
    for _, aug in ipairs(item.augs or {}) do
        if aug and not aug.empty then
            local loc = string.format("%s Aug Slot %s", slot_label, tostring(aug.index or "?"))
            if item.location and item.location ~= "Equipped" then
                loc = string.format("%s: %s Aug Slot %s", item.location, tostring(item.where or slot_label), tostring(aug.index or "?"))
            end
            add_row(rows, snap, aug, {
                kind = "aug",
                where = "installed_aug",
                locationGroup = parent_loc_group or parent_where or "installed_aug",
                location = loc,
                installedIn = item.name or "",
                installedInId = item.id or 0,
                sourceKey = table.concat({
                    snap.server or "", snap.name or "", parent_where or "",
                    tostring(item.slotid or ""), "aug" .. tostring(aug.index or ""),
                    tostring(aug.id or 0)
                }, ":"),
            })
        end
    end
end

local function add_equipped(rows, snap)
    for _, item in ipairs((snap and snap.equipped) or {}) do
        add_row(rows, snap, item, {
            kind = item_kind(item),
            where = "equipped",
            locationGroup = "equipped",
            location = item.slotname or item.where or "Equipped",
            sourceKey = table.concat({ snap.server or "", snap.name or "", "equipped", tostring(item.slotid or ""), tostring(item.id or 0) }, ":"),
        })
        add_installed_augs(rows, snap, item, "equipped", "installed_aug")
    end
end

local function add_storage_item(rows, snap, item, group)
    local kind = item_kind(item)
    local where = kind == "aug" and "loose_aug" or "stored_gear"
    add_row(rows, snap, item, {
        kind = kind,
        where = where,
        locationGroup = group,
        location = string.format("%s: %s", item.location or group, item.where or ""),
        sourceKey = table.concat({ snap.server or "", snap.name or "", group, tostring(item.slotid or ""), tostring(item.slotname or ""), tostring(item.id or 0) }, ":"),
    })
    add_installed_augs(rows, snap, item, "stored_gear", group)
end

local function add_storage(rows, snap)
    for _, item in ipairs((snap and snap.bags) or {}) do add_storage_item(rows, snap, item, "bags") end
    for _, item in ipairs((snap and snap.bank) or {}) do add_storage_item(rows, snap, item, "bank") end
end

local function preserve_self_bank_cache(self_snap)
    if type(self_snap) ~= "table" or type(self_snap.bank) == "table" and #self_snap.bank > 0 then return end
    for _, snap in pairs(Store.sources or {}) do
        if same_owner(self_snap, snap) and type(snap.bank) == "table" and #snap.bank > 0 then
            self_snap.bank = snap.bank
            self_snap.bankValid = snap.bankValid
            self_snap.bankLive = false
            self_snap.bankOpen = snap.bankOpen
            self_snap.bankPreserved = true
            self_snap.bankCapturedAt = snap.bankCapturedAt
            self_snap.bankReason = snap.bankReason or "cached"
            return
        end
    end
end

local function build_summary(rows)
    local summary = {
        total = #(rows or {}),
        withAnyStat = 0,
        byStat = {},
    }
    for _, row in ipairs(rows or {}) do
        local has_any = false
        for key, value in pairs(row.stats or {}) do
            if (tonumber(value) or 0) > 0 then
                summary.byStat[key] = (summary.byStat[key] or 0) + 1
                has_any = true
            end
        end
        if has_any then summary.withAnyStat = summary.withAnyStat + 1 end
    end
    return summary
end

function M.rebuild()
    local rows = {}
    local self_snap = live_self_snapshot_for_index()
    if self_snap then
        preserve_self_bank_cache(self_snap)
        add_equipped(rows, self_snap)
        add_storage(rows, self_snap)
    end
    for _, snap in pairs(Store.sources or {}) do
        if self_snap and same_owner(self_snap, snap) then goto continue_source end
        add_equipped(rows, snap)
        add_storage(rows, snap)
        ::continue_source::
    end
    M.rows = rows
    M.summary = build_summary(rows)
    M.version = (M.version or 0) + 1
    M.content_version = Store.content_version or 0
    M.self_signature = self_index_signature()
    return M.rows, M.version
end

function M.get(force)
    if force or M.content_version ~= (Store.content_version or 0) or M.self_signature ~= self_index_signature() then
        return M.rebuild()
    end
    return M.rows, M.version
end

function M.refresh()
    return M.rebuild()
end

function M.get_summary()
    M.get(false)
    return M.summary or { total = 0, withAnyStat = 0, byStat = {} }
end

return M
