-- TurboGear/item_index.lua
-- Flattens Store snapshots into cached searchable rows. The current box's
-- cached live snapshot is overlaid so viewer-mode UIs do not show self-owned
-- items as offline/cache when Store still has an older persisted copy.
--
-- Rebuilds are budgeted across ticks (M.tick): M.rows always holds the last
-- complete index until a job finishes, then swaps atomically.

local store = require('store')
local Store = store.Store
local self_snapshot = require('snapshot')

local M = {
    rows = {},
    version = 0,
    content_version = -1, -- legacy alias; payload_sig is the real staleness key
    payload_sig = "",
    self_signature = "",
    summary = { total = 0, withAnyStat = 0 },
}

-- In-progress rebuild. Never assigned to M.rows until complete.
local job = nil

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

local function snap_item_count(snap)
    if type(snap) ~= "table" then return 0 end
    return #(snap.equipped or {}) + #(snap.bags or {}) + #(snap.bank or {})
end

local function list_quick_sig(list)
    list = list or {}
    local n = #list
    if n == 0 then return "0" end
    local a, b = list[1], list[n]
    return table.concat({
        tostring(n),
        tostring(a and a.id or 0),
        tostring(b and b.id or 0),
        tostring(a and a.name or ""),
        tostring(b and b.name or ""),
    }, ":")
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

--- Prefer Store self when live cache is empty/lite-sparse so Search indexes
--- the same bags/bank the Characters pill reports (488 items etc.).
local function self_snap_for_index()
    local live = live_self_snapshot_for_index()
    local store_self = nil
    pcall(function()
        if store.my_key then
            store_self = Store.get(store.my_key())
        end
    end)
    if type(store_self) ~= "table" or not store_self.name then store_self = nil end

    local live_n = snap_item_count(live)
    local store_n = snap_item_count(store_self)
    if store_self and store_n > live_n then
        local out = {}
        for k, v in pairs(store_self) do out[k] = v end
        out.status = "online"
        return out
    end
    if live then
        if store_self then
            if #(live.bags or {}) == 0 and #(store_self.bags or {}) > 0 then
                live.bags = store_self.bags
            end
            if #(live.bank or {}) == 0 and #(store_self.bank or {}) > 0 then
                live.bank = store_self.bank
                live.bankValid = store_self.bankValid
                live.bankCapturedAt = store_self.bankCapturedAt
                live.bankPreserved = true
            end
        end
        return live
    end
    return store_self
end

-- Item-payload signature (ignores bankLive / bankCapturedAt stamp-only bumps
-- that raise Store.content_version). Mid-job restarts on those stamps left
-- Search stuck at 0 rows after async get() (1.2.89+).
local payload_sig_cache = { store_v = -1, store_cv = -1, live_key = "", sig = "" }

local function fleet_payload_sig()
    local store_v = Store.version or 0
    local store_cv = Store.content_version or 0
    local live = live_self_snapshot_for_index()
    local live_key = ""
    if live then
        live_key = table.concat({
            list_quick_sig(live.equipped),
            list_quick_sig(live.bags),
            list_quick_sig(live.bank),
        }, "/")
    end
    if payload_sig_cache.store_v == store_v
        and payload_sig_cache.store_cv == store_cv
        and payload_sig_cache.live_key == live_key then
        return payload_sig_cache.sig
    end
    local parts = {}
    for _, snap in pairs(Store.sources or {}) do
        if type(snap) == "table" and snap.name then
            parts[#parts + 1] = table.concat({
                clean_text(snap.server),
                clean_text(snap.name),
                list_quick_sig(snap.equipped),
                list_quick_sig(snap.bags),
                list_quick_sig(snap.bank),
            }, "|")
        end
    end
    if live then
        parts[#parts + 1] = table.concat({
            "live",
            clean_text(live.server),
            clean_text(live.name),
            list_quick_sig(live.equipped),
            list_quick_sig(live.bags),
            list_quick_sig(live.bank),
        }, "|")
    end
    table.sort(parts)
    local sig = table.concat(parts, "\n")
    payload_sig_cache.store_v = store_v
    payload_sig_cache.store_cv = store_cv
    payload_sig_cache.live_key = live_key
    payload_sig_cache.sig = sig
    return sig
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

local function is_stale()
    return M.payload_sig ~= fleet_payload_sig()
end

local function job_targets_match(j)
    if not j then return false end
    return j.target_payload_sig == fleet_payload_sig()
end

local function collect_peer_sources(self_snap)
    local peers = {}
    for _, snap in pairs(Store.sources or {}) do
        if type(snap) == "table" and snap.name then
            if not (self_snap and same_owner(self_snap, snap)) then
                peers[#peers + 1] = snap
            end
        end
    end
    table.sort(peers, function(a, b)
        local an = clean_text(a.name)
        local bn = clean_text(b.name)
        if an ~= bn then return an < bn end
        return clean_text(a.server) < clean_text(b.server)
    end)
    return peers
end

-- Items processed between deadline checks inside a single peer list.
local ITEM_CHUNK = 48
-- phase: 0=equipped, 1=bags, 2=bank
local PHASE_EQUIPPED, PHASE_BAGS, PHASE_BANK = 0, 1, 2

local function start_job()
    local target_payload_sig = fleet_payload_sig()
    local self_snap = self_snap_for_index()
    -- Self is peer_i=1 so cold-start never does a synchronous full walk in get().
    local peers = {}
    if self_snap then peers[1] = self_snap end
    for _, snap in ipairs(collect_peer_sources(self_snap)) do
        peers[#peers + 1] = snap
    end
    job = {
        rows = {},
        peers = peers,
        peer_i = 1,
        phase = PHASE_EQUIPPED,
        item_i = 1,
        target_payload_sig = target_payload_sig,
        target_cv = Store.content_version or 0,
        started_at = os.clock(),
    }
    return job
end

local function finish_job(j)
    if not j then return M.rows, M.version end
    M.rows = j.rows
    M.summary = build_summary(j.rows)
    M.version = (M.version or 0) + 1
    M.payload_sig = j.target_payload_sig or fleet_payload_sig()
    M.content_version = j.target_cv or (Store.content_version or 0)
    M.self_signature = M.payload_sig
    job = nil
    return M.rows, M.version
end

local function ensure_job(force)
    if force or is_stale() then
        if not job or not job_targets_match(job) then
            start_job()
        end
        return true
    end
    return job ~= nil
end

local function phase_list(snap, phase)
    if phase == PHASE_EQUIPPED then return (snap and snap.equipped) or {} end
    if phase == PHASE_BAGS then return (snap and snap.bags) or {} end
    return (snap and snap.bank) or {}
end

-- Process up to ITEM_CHUNK items (or until deadline). Returns true when the
-- current peer is fully consumed (caller may advance peer_i).
local function advance_peer_chunk(j, deadline)
    local snap = j.peers[j.peer_i]
    if not snap then
        j.peer_i = j.peer_i + 1
        j.phase = PHASE_EQUIPPED
        j.item_i = 1
        return true
    end
    local n = 0
    while j.phase <= PHASE_BANK do
        local list = phase_list(snap, j.phase)
        while j.item_i <= #list do
            if n > 0 and (n % ITEM_CHUNK) == 0 and os.clock() >= deadline then
                return false
            end
            local item = list[j.item_i]
            j.item_i = j.item_i + 1
            n = n + 1
            if j.phase == PHASE_EQUIPPED then
                add_row(j.rows, snap, item, {
                    kind = item_kind(item),
                    where = "equipped",
                    locationGroup = "equipped",
                    location = item.slotname or item.where or "Equipped",
                    sourceKey = table.concat({
                        snap.server or "", snap.name or "", "equipped",
                        tostring(item.slotid or ""), tostring(item.id or 0),
                    }, ":"),
                })
                add_installed_augs(j.rows, snap, item, "equipped", "installed_aug")
            elseif j.phase == PHASE_BAGS then
                add_storage_item(j.rows, snap, item, "bags")
            else
                add_storage_item(j.rows, snap, item, "bank")
            end
            if os.clock() >= deadline and n > 0 then return false end
        end
        j.phase = j.phase + 1
        j.item_i = 1
    end
    return true
end

--- Drain the in-flight job to completion (tests / rare explicit callers).
--- Prefer get+tick in the live loop — never call this from UI get().
function M.rebuild()
    start_job()
    local j = job
    local guard = 0
    while j and j.peer_i <= #(j.peers or {}) do
        guard = guard + 1
        if guard > 100000 then break end
        if advance_peer_chunk(j, os.clock() + 3600) then
            j.peer_i = j.peer_i + 1
            j.phase = PHASE_EQUIPPED
            j.item_i = 1
        end
    end
    return finish_job(j)
end

--- Advance an in-progress rebuild within budget_ms. Returns true if a job finished.
function M.tick(budget_ms)
    if job and not job_targets_match(job) then
        start_job()
    end
    if not job and is_stale() then
        start_job()
    end
    local j = job
    if not j then return false end

    budget_ms = tonumber(budget_ms) or 4
    if budget_ms < 0.25 then budget_ms = 0.25 end
    local deadline = os.clock() + budget_ms / 1000

    while j.peer_i <= #(j.peers or {}) do
        if os.clock() >= deadline then break end
        if advance_peer_chunk(j, deadline) then
            j.peer_i = j.peer_i + 1
            j.phase = PHASE_EQUIPPED
            j.item_i = 1
        else
            break
        end
    end

    if j.peer_i > #(j.peers or {}) then
        finish_job(j)
        return true
    end
    return false
end

function M.building()
    return job ~= nil
end

function M.get(force)
    force = force == true
    -- Never synchronous-rebuild here: cold start used to call M.rebuild() and
    -- freeze the game thread for multi-second fleet walks (6s in captures).
    -- Serve last-good (or empty) and let M.tick fill/swap.
    ensure_job(force or is_stale())
    return M.rows, M.version
end

function M.refresh()
    ensure_job(true)
    return M.rows, M.version
end

function M.get_summary()
    M.get(false)
    return M.summary or { total = 0, withAnyStat = 0, byStat = {} }
end

--- Test helper: drop in-flight job and published index.
function M._reset_for_tests()
    job = nil
    M.rows = {}
    M.version = 0
    M.content_version = -1
    M.payload_sig = ""
    M.self_signature = ""
    M.summary = { total = 0, withAnyStat = 0 }
    payload_sig_cache.store_v = -1
    payload_sig_cache.store_cv = -1
    payload_sig_cache.live_key = ""
    payload_sig_cache.sig = ""
end

return M
