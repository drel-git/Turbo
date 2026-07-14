-- TurboGear/store.lua
-- The unified, hybrid (live + cached) source store. Holds every box's snapshot
-- keyed by "<server>_<name>", ages them online -> stale -> offline, and persists
-- to a single cache file so offline characters still show and the UI warm-starts.

local mq  = require('mq')
local cfg = require('config')
local CFG, Settings = cfg.CFG, cfg.Settings
local diag = require('diagnostics')

local M = {}

-- Persistence backend (Phase 3). Assigned once the helpers it needs (recency)
-- exist, below. File backend today; SQLite selected here in a later step.
local backend

-- sources[key] = snapshot table + { status, last_seen, kind }
-- version tracks any visible source/status update. content_version only tracks
-- inventory payload changes and is what heavy indexes should invalidate on.
local Store = {
    sources = {},
    dirty = false,
    last_save = 0,
    last_age_sweep = 0,
    version = 0,
    content_version = 0,
    content_signatures = {},
    last_content_change_by_key = {},
    cache_signature = nil,
    cache_last_reload_reason = "",
}

local function my_key()
    return (mq.TLO.MacroQuest.Server() or "?") .. "_" .. (mq.TLO.Me.CleanName() or "?")
end

local function is_invalid_source_key(key, snap)
    local name = tostring(snap and snap.name or "")
    local hay = (tostring(key or "") .. " " .. name):lower()
    if hay:find("corpse", 1, true) then return true end
    if hay:find("'s%s+corpse") or hay:find("%s+corpse$") or hay:find("%[corpse%]") then return true end
    if name ~= "" and name:lower():find("corpse", 1, true) then return true end
    return false
end

local function sorted_kv_sig(t)
    if type(t) ~= "table" then return "" end
    local keys = {}
    for k, _ in pairs(t) do keys[#keys+1] = tostring(k) end
    table.sort(keys)
    local parts = {}
    for _, k in ipairs(keys) do
        parts[#parts+1] = k .. "=" .. tostring(t[k] or "")
    end
    return table.concat(parts, ",")
end

local function list_sig(t)
    if type(t) ~= "table" then return "" end
    local parts = {}
    for i, entry in ipairs(t) do
        parts[#parts+1] = tostring(i) .. ":" .. sorted_kv_sig(entry)
    end
    return table.concat(parts, ";")
end

local function item_sig(item)
    if type(item) ~= "table" then return "" end
    local parts = {
        tostring(item.id or 0),
        tostring(item.name or ""),
        tostring(item.location or ""),
        tostring(item.where or ""),
        tostring(item.slotid or ""),
        tostring(item.slotname or ""),
        tostring(item.qty or item.count or 1),
        item.empty and "empty" or "filled",
    }
    if type(item.augs) == "table" then
        for _, aug in ipairs(item.augs) do
            parts[#parts+1] = "aug"
            parts[#parts+1] = tostring(aug.index or 0)
            parts[#parts+1] = tostring(aug.id or 0)
            parts[#parts+1] = tostring(aug.name or "")
            parts[#parts+1] = aug.empty and "empty" or "filled"
        end
    end
    return table.concat(parts, "|")
end

local function item_list_sig(list)
    if type(list) ~= "table" then return "" end
    local parts = {}
    for _, item in ipairs(list) do parts[#parts+1] = item_sig(item) end
    table.sort(parts)
    return table.concat(parts, "\30")
end

local function list_count(list)
    return type(list) == "table" and #list or 0
end

local function note_content_change(source, key, snap, old_sig, new_sig)
    local change = {
        source = tostring(source or "?"),
        key = tostring(key or "?"),
        name = tostring(snap and snap.name or "?"),
        kind = tostring(snap and snap.kind or "?"),
        depth = tostring(snap and snap.depth or "?"),
        version = (Store.content_version or 0) + 1,
        old_len = #(tostring(old_sig or "")),
        new_len = #(tostring(new_sig or "")),
        equipped = list_count(snap and snap.equipped),
        bags = list_count(snap and snap.bags),
        bank = list_count(snap and snap.bank),
    }
    Store.last_content_change = change
    Store.last_content_change_by_key[tostring(key or "?")] = change
    diag.count("store.content_changed")
    diag.event("store.content_changed", string.format(
        "%s key=%s name=%s depth=%s eq=%d bag=%d bank=%d oldLen=%d newLen=%d v=%d",
        change.source,
        change.key,
        change.name,
        change.depth,
        change.equipped,
        change.bags,
        change.bank,
        change.old_len,
        change.new_len,
        change.version))
end

local function snapshot_content_sig(snap)
    if type(snap) ~= "table" then return "" end
    return table.concat({
        tostring(snap.server or ""),
        tostring(snap.name or ""),
        tostring(snap.class or ""),
        tostring(snap.level or ""),
        item_list_sig(snap.equipped),
        item_list_sig(snap.bags),
        item_list_sig(snap.bank),
    }, "\31")
end

local function snapshot_inventory_stamp(snap)
    if type(snap) ~= "table" then return nil end
    return tonumber(snap.inventoryUpdated) or tonumber(snap.updated)
end

local function has_inventory_payload(snap)
    if type(snap) ~= "table" then return false end
    if snap.depth == "full" or snap.depth == "lite" or snap.depth == "loadout" then return true end
    return (type(snap.equipped) == "table" and #snap.equipped > 0)
        or (type(snap.bags) == "table" and #snap.bags > 0)
        or (type(snap.bank) == "table" and #snap.bank > 0)
end

local function snapshot_inventory_recency(snap)
    if type(snap) ~= "table" then return 0 end
    local best = tonumber(snap.inventoryUpdated) or 0
    if best <= 0 and has_inventory_payload(snap) then
        best = tonumber(snap.updated) or 0
    end
    local bank = tonumber(snap.bankCapturedAt) or 0
    if bank > best then best = bank end
    return best
end

-- R1 cross-box ordering: prefer the publisher's monotonic seq (immune to clock
-- skew between boxes, since we only ever compare two snapshots of the SAME key /
-- owner) and fall back to wall-clock recency for snapshots from pre-seq
-- responders. Additive + backward-compatible, so no protocol version bump: a box
-- that lacks seq simply gets the recency path.
local function snapshot_seq(snap)
    local s = tonumber(snap and snap.seq)
    if s and s > 0 then return s end
    return nil
end
local function is_newer(candidate, existing)
    local cs, es = snapshot_seq(candidate), snapshot_seq(existing)
    if cs and es then return cs > es end
    return snapshot_inventory_recency(candidate) > snapshot_inventory_recency(existing)
end

-- Select the persistence backend now that the recency comparator exists.
-- "auto"/"sqlite": use the SQLite backend when lsqlite3 is available; fall back
-- to the file backend otherwise (or when storeBackend="file"). The interface is
-- identical, so the rest of the Store is agnostic to which one is active.
do
    local backend_opts = { newer = is_newer, key_fn = my_key }
    local pref = tostring((Settings and Settings.storeBackend) or "auto"):lower()
    if pref == "auto" or pref == "sqlite" then
        local ok, sqlite_mod = pcall(require, 'store_backend_sqlite')
        if ok and sqlite_mod then
            local b = sqlite_mod.new(backend_opts)
            if b and b:available() then
                backend = b
                diag.event("store.backend", "using sqlite backend")
            end
        end
    end
    if not backend then
        backend = require('store_backend_file').new(backend_opts)
        diag.event("store.backend", "using file backend")
    end
end

local function item_match_key(item)
    if type(item) ~= "table" then return "" end
    return table.concat({
        tostring(item.id or 0),
        tostring(item.location or ""),
        tostring(item.where or ""),
        tostring(item.slotid or ""),
        tostring(item.slotname or ""),
    }, ":")
end

local function item_has_full_meta(item)
    if type(item) ~= "table" then return false end
    if item.depth == "full" then return true end
    if type(item.stats) == "table" then
        for _, value in pairs(item.stats) do
            if (tonumber(value) or 0) > 0 then return true end
        end
    end
    if type(item.focusEffects) == "table" and #item.focusEffects > 0 then return true end
    if type(item.wornFocusEffects) == "table" and #item.wornFocusEffects > 0 then return true end
    return false
end

local function merge_item_lists(old_list, new_list)
    if type(new_list) ~= "table" then return new_list end
    if type(old_list) ~= "table" then return new_list end
    local old_by_key = {}
    for _, item in ipairs(old_list) do
        old_by_key[item_match_key(item)] = item
    end
    for i, item in ipairs(new_list) do
        local prev = old_by_key[item_match_key(item)]
        if prev and item_has_full_meta(prev) and not item_has_full_meta(item) then
            local merged = {}
            for k, v in pairs(item) do merged[k] = v end
            merged.stats = prev.stats
            merged.classes = prev.classes
            merged.allClasses = prev.allClasses
            merged.slots = prev.slots
            merged.itemType = prev.itemType
            merged.requiredLevel = prev.requiredLevel
            merged.recommendedLevel = prev.recommendedLevel
            merged.focusEffects = prev.focusEffects
            merged.wornFocusEffects = prev.wornFocusEffects
            merged.lore = prev.lore
            merged.loreGroup = prev.loreGroup
            merged.depth = "full"
            if type(item.augs) == "table" and type(prev.augs) == "table" then
                local aug_old = {}
                for _, aug in ipairs(prev.augs) do
                    aug_old[tostring(aug.index or 0)] = aug
                end
                merged.augs = {}
                for _, aug in ipairs(item.augs) do
                    local paug = aug_old[tostring(aug.index or 0)]
                    if paug and item_has_full_meta(paug) and not item_has_full_meta(aug) then
                        local maug = {}
                        for k, v in pairs(aug) do maug[k] = v end
                        maug.stats = paug.stats
                        maug.classes = paug.classes
                        maug.allClasses = paug.allClasses
                        maug.slots = paug.slots
                        maug.requiredLevel = paug.requiredLevel
                        maug.recommendedLevel = paug.recommendedLevel
                        maug.focusEffects = paug.focusEffects
                        maug.wornFocusEffects = paug.wornFocusEffects
                        maug.lore = paug.lore
                        maug.loreGroup = paug.loreGroup
                        maug.depth = "full"
                        merged.augs[#merged.augs + 1] = maug
                    else
                        merged.augs[#merged.augs + 1] = aug
                    end
                end
            end
            new_list[i] = merged
        end
    end
    return new_list
end

local function merge_lite_snapshot(existing, snap)
    if type(existing) ~= "table" or type(snap) ~= "table" then return snap end
    if snap.depth == "full" then return snap end
    local out = {
        name = snap.name,
        server = snap.server,
        class = snap.class or existing.class,
        level = snap.level or existing.level,
        zoneShortName = snap.zoneShortName or existing.zoneShortName,
        zoneName = snap.zoneName or existing.zoneName,
        updated = snap.updated or existing.updated,
        inventoryUpdated = snapshot_inventory_stamp(snap) or existing.inventoryUpdated or existing.updated,
        seq = snapshot_seq(snap) or snapshot_seq(existing),
        metaUpdated = existing.metaUpdated,
        proto = snap.proto or existing.proto,
        depth = existing.depth == "full" and "full" or "lite",
        status = snap.status,
        last_seen = snap.last_seen,
        kind = snap.kind or existing.kind,
        equipped = merge_item_lists(existing.equipped, snap.equipped or {}),
        bags = merge_item_lists(existing.bags, snap.bags or {}),
        bank = merge_item_lists(existing.bank, snap.bank or {}),
        bankValid = snap.bankValid,
        bankLive = snap.bankLive,
        bankOpen = snap.bankOpen,
        bankPreserved = snap.bankPreserved,
        bankCapturedAt = snap.bankCapturedAt,
        bankReason = snap.bankReason,
        lockouts = snap.lockouts or existing.lockouts,
        liveStats = snap.liveStats or existing.liveStats,
    }
    if snap.bankValid ~= true and type(existing.bank) == "table" and #existing.bank > 0 then
        out.bank = existing.bank
        out.bankValid = true
        out.bankLive = false
        out.bankOpen = snap.bankOpen
        out.bankPreserved = true
        out.bankCapturedAt = tonumber(existing.bankCapturedAt) or snapshot_inventory_stamp(existing)
        out.bankReason = "cached; bank window closed"
    end
    if snap.spells_sig and snap.spells_sig ~= "" then
        out.spells = snap.spells
        out.spells_sig = snap.spells_sig
    else
        out.spells = existing.spells
        out.spells_sig = existing.spells_sig
    end
    return out
end

local function merge_snapshot(existing, snap)
    if type(existing) ~= "table" or type(snap) ~= "table" then return snap end
    if snap.depth ~= "full" then return merge_lite_snapshot(existing, snap) end
    if snap.lockouts == nil then snap.lockouts = existing.lockouts end
    if snap.liveStats == nil then snap.liveStats = existing.liveStats end
    if not snap.spells_sig or snap.spells_sig == "" then
        snap.spells = existing.spells
        snap.spells_sig = existing.spells_sig
    end
    if snap.bankValid == true then return snap end
    if type(existing.bank) ~= "table" or #existing.bank == 0 then return snap end
    local out = {}
    for k, v in pairs(snap) do out[k] = v end
    out.bank = existing.bank
    out.bankValid = true
    out.bankLive = false
    out.bankOpen = snap.bankOpen
    out.bankPreserved = true
    out.bankCapturedAt = tonumber(existing.bankCapturedAt) or snapshot_inventory_stamp(existing)
    out.bankReason = "cached; bank window closed"
    return out
end

local function preserve_presence(existing, snap, fallback_status)
    if type(existing) ~= "table" or type(snap) ~= "table" then return snap end
    local prior_actor = tonumber(existing.actorSeenAt) or 0
    local prior_discovery = tonumber(existing.discoverySeenAt) or 0
    snap.status = existing.status or snap.status or fallback_status or "offline"
    snap.last_seen = existing.last_seen or snap.last_seen or 0
    if prior_actor > (tonumber(snap.actorSeenAt) or 0) then snap.actorSeenAt = prior_actor end
    if prior_discovery > (tonumber(snap.discoverySeenAt) or 0) then snap.discoverySeenAt = prior_discovery end
    return snap
end

function Store.put(snap, kind)
    return diag.time("store.put", function()
        if not snap or not snap.name or not snap.server then return end
        local key = snap.server .. "_" .. snap.name
        local existing = Store.sources[key]
        if existing then
            snap = merge_snapshot(existing, snap)
        end
        snap.inventoryUpdated = snapshot_inventory_stamp(snap) or os.time()
        snap.metaUpdated = snap.metaUpdated or (existing and existing.metaUpdated)
        local sig = snapshot_content_sig(snap)
        snap.status = "online"; snap.last_seen = os.time(); snap.kind = kind or "client"
        if (kind or "client") == "client" then snap.actorSeenAt = os.time() end
        Store.sources[key] = snap
        if Store.content_signatures[key] ~= sig then
            note_content_change("put", key, snap, Store.content_signatures[key], sig)
            Store.content_signatures[key] = sig
            Store.content_version = (Store.content_version or 0) + 1
        end
        Store.dirty = true
        Store.version = (Store.version or 0) + 1
    end)
end

-- Apply a changed-slot delta from a peer (or ourselves). Only merges on top of
-- an existing inventory payload; without a baseline the caller should request a
-- full snapshot instead. Returns true when applied.
function Store.apply_delta(delta, kind)
    if type(delta) ~= "table" or not delta.name or not delta.server then return false end
    local key = delta.server .. "_" .. delta.name
    local existing = Store.sources[key]
    if type(existing) ~= "table" then return false end
    if not has_inventory_payload(existing) then return false end
    -- Never regress. Prefer the publisher's monotonic seq (robust to cross-box
    -- clock skew); fall back to wall-clock stamps for pre-seq responders.
    local stamp = tonumber(delta.inventoryUpdated) or tonumber(delta.updated) or os.time()
    local dseq, eseq = snapshot_seq(delta), snapshot_seq(existing)
    if dseq and eseq then
        if dseq <= eseq then return false end
    else
        local have = tonumber(existing.inventoryUpdated) or 0
        if stamp < have then return false end
    end
    local ok_sd, sd = pcall(require, 'snapshot_delta')
    if not ok_sd or not sd then return false end
    return diag.time("store.apply_delta", function()
        local touched = false
        for _, bucket in ipairs(sd.BUCKETS) do
            local changed = delta.changed and delta.changed[bucket]
            local removed = delta.removed and delta.removed[bucket]
            if (type(changed) == "table" and #changed > 0)
                or (type(removed) == "table" and #removed > 0) then
                existing[bucket] = sd.apply_to_list(existing[bucket], changed, removed)
                touched = true
            end
        end
        if not touched then return false end
        existing.updated = tonumber(delta.updated) or os.time()
        existing.inventoryUpdated = stamp
        existing.seq = tonumber(delta.seq) or existing.seq
        existing.class = delta.class or existing.class
        existing.level = delta.level or existing.level
        existing.status = "online"
        existing.last_seen = os.time()
        existing.kind = kind or existing.kind or "client"
        if (kind or "client") == "client" then existing.actorSeenAt = os.time() end
        local sig = snapshot_content_sig(existing)
        if Store.content_signatures[key] ~= sig then
            note_content_change("delta", key, existing, Store.content_signatures[key], sig)
            Store.content_signatures[key] = sig
            Store.content_version = (Store.content_version or 0) + 1
        end
        Store.dirty = true
        Store.version = (Store.version or 0) + 1
        return true
    end)
end

function Store.touch(snap, kind)
    if not snap or not snap.name or not snap.server then return end
    local key = snap.server .. "_" .. snap.name
    local existing = Store.sources[key]
    local is_meta = snap.depth == "meta"
    local now = os.time()
    if existing then
        local prior_inventory_updated = existing.inventoryUpdated or existing.updated
        local changed = existing.status ~= "online"
            or existing.class ~= snap.class
            or existing.level ~= snap.level
            or existing.zoneShortName ~= snap.zoneShortName
            or existing.kind ~= (kind or existing.kind)
        existing.status = "online"
        existing.last_seen = now
        existing.kind = kind or existing.kind or "client"
        if (kind or "client") == "client" then existing.actorSeenAt = now end
        existing.class = snap.class or existing.class
        existing.level = snap.level or existing.level
        existing.zoneShortName = snap.zoneShortName or existing.zoneShortName
        existing.zoneName = snap.zoneName or existing.zoneName
        if is_meta then
            existing.metaUpdated = tonumber(snap.updated) or now
        else
            existing.updated = snap.updated or existing.updated
            existing.inventoryUpdated = snapshot_inventory_stamp(snap) or existing.inventoryUpdated or existing.updated
            if tostring(existing.inventoryUpdated or "") ~= tostring(prior_inventory_updated or "") then
                changed = true
                Store.dirty = true
            end
        end
        if changed then Store.version = (Store.version or 0) + 1 end
        return
    end
    Store.sources[key] = {
        name = snap.name,
        server = snap.server,
        class = snap.class,
        level = snap.level,
        zoneShortName = snap.zoneShortName,
        zoneName = snap.zoneName,
        updated = is_meta and nil or snap.updated,
        inventoryUpdated = is_meta and nil or snapshot_inventory_stamp(snap),
        metaUpdated = is_meta and (tonumber(snap.updated) or now) or nil,
        actorSeenAt = (kind or "client") == "client" and now or nil,
        kind = kind or "client",
        status = "online",
        last_seen = now,
        equipped = {},
        bags = {},
        bank = {},
        lockouts = snap.lockouts,
    }
    Store.version = (Store.version or 0) + 1
end

function Store.discover_peer(name, provider)
    name = tostring(name or ""):match("^%s*(.-)%s*$") or ""
    if name == "" then return false end
    local server = mq.TLO.MacroQuest.Server() or "?"
    local key = server .. "_" .. name
    if key == my_key() then return false end
    if is_invalid_source_key(key, { name = name }) then return false end
    local existing = Store.sources[key]
    local now = os.time()
    if existing then
        local changed = existing.status ~= "online" or existing.kind == nil
        existing.status = "online"
        existing.last_seen = now
        existing.kind = existing.kind or tostring(provider or "discovery")
        existing.name = existing.name or name
        existing.server = existing.server or server
        existing.discoverySeenAt = now
        existing.metaUpdated = now
        if changed then Store.version = (Store.version or 0) + 1 end
        return false, changed, key
    end
    Store.sources[key] = {
        name = name,
        server = server,
        class = "?",
        level = 0,
        updated = nil,
        inventoryUpdated = nil,
        metaUpdated = now,
        kind = tostring(provider or "discovery"),
        discovered = true,
        discoverySeenAt = now,
        status = "online",
        last_seen = now,
        equipped = {},
        bags = {},
        bank = {},
    }
    Store.version = (Store.version or 0) + 1
    Store.dirty = true
    return true, true, key
end

function Store.tick()
    -- Aging is second-granular (stale/offline thresholds are in seconds), so the
    -- per-source sweep is throttled to ~1Hz instead of running every loop pass
    -- (P3). The save debounce below still runs every tick.
    local sweep_now = os.clock()
    if (sweep_now - (Store.last_age_sweep or 0)) >= (tonumber(CFG.age_sweep_interval_s) or 1.0) then
        Store.last_age_sweep = sweep_now
        local now = os.time()
        for _, s in pairs(Store.sources) do
            if s.last_seen and s.last_seen > 0 then
                local age = now - s.last_seen
                local next_status = s.status
                if age > (Settings.offlineSeconds or 45) then next_status = "offline"
                elseif age > (Settings.staleSeconds or 20) then next_status = "stale" end
                if next_status ~= s.status then
                    s.status = next_status
                    Store.version = (Store.version or 0) + 1
                end
            end
        end
    end
    local st = require('state')
    local save_every = tonumber(CFG.save_every_s) or 15.0
    if st and st.bg == true then
        save_every = tonumber(CFG.save_every_bg_s) or 1.0
    elseif st and st.show == false then
        save_every = tonumber(CFG.save_every_minimized_s) or save_every
    elseif st and st.show ~= false then
        local tab = tostring(Settings.mainTab or "")
        if tab == "inventory" or tab == "bis" then
            save_every = math.max(save_every, tonumber(CFG.save_every_heavy_ui_s) or 120.0)
        end
    end
    if Store.dirty and (os.clock() - Store.last_save) > save_every then Store.save() end
end

function Store.save()
    Store.last_save = os.clock(); Store.dirty = false
    local source_count = 0
    for _ in pairs(Store.sources) do source_count = source_count + 1 end
    diag.context("store.save", string.format("sources=%d backend=%s", source_count, tostring(backend and backend.kind or "?")))
    diag.time("store.save", function()
        -- strip volatile status before persisting; mark loaded ones offline on read
        local out = {}
        for k, s in pairs(Store.sources) do
            out[k] = { name=s.name, server=s.server, class=s.class, level=s.level,
                       updated=s.updated, seq=s.seq, inventoryUpdated=s.inventoryUpdated,
                       metaUpdated=s.metaUpdated, actorSeenAt=s.actorSeenAt,
                       discoverySeenAt=s.discoverySeenAt, kind=s.kind, depth=s.depth,
                       equipped=s.equipped, bags=s.bags, bank=s.bank,
                       bankValid=s.bankValid, bankLive=s.bankLive, bankOpen=s.bankOpen,
                       bankPreserved=s.bankPreserved, bankCapturedAt=s.bankCapturedAt,
                       bankReason=s.bankReason,
                       lockouts=s.lockouts, spells=s.spells, spells_sig=s.spells_sig,
                       liveStats=s.liveStats }
        end
        local ok_save, save_reason = backend:save(out)
        Store.cache_last_reload_reason = ok_save and "saved atomically" or ("save failed: " .. tostring(save_reason or "?"))
        if not ok_save then diag.count("store.save_failed") end
        Store.cache_signature = backend:signature()
    end)
end

local function ingest_cache_table(t, mark_offline)
    local accepted = false
    local content_changed = false
    if type(t) ~= "table" then return false end
    for k, s in pairs(t) do
        if type(s) == "table" then
            if mark_offline then
                s.status = "offline"
                s.last_seen = 0
            end
            s.kind = s.kind or "client"
            if s.bankValid == nil and type(s.bank) == "table" and #s.bank > 0 then
                s.bankValid = true
                s.bankLive = false
                s.bankPreserved = true
                s.bankCapturedAt = tonumber(s.bankCapturedAt) or snapshot_inventory_stamp(s)
                s.bankReason = "cached"
            end
            if tonumber(s.inventoryUpdated) == nil and ((type(s.equipped) == "table" and #s.equipped > 0) or (type(s.bags) == "table" and #s.bags > 0)) then
                s.inventoryUpdated = tonumber(s.updated)
            end
            local existing = Store.sources[k]
            if type(existing) ~= "table" then
                Store.sources[k] = s
                local sig = snapshot_content_sig(s)
                note_content_change("cache-new", k, s, Store.content_signatures[k], sig)
                Store.content_signatures[k] = sig
                accepted = true
                content_changed = true
            elseif is_newer(s, existing) then
                s = preserve_presence(existing, s, mark_offline and "offline" or existing.status)
                Store.sources[k] = s
                accepted = true
                -- Newer timestamp does not imply new content (bg re-saves on
                -- heartbeats). Only bump content_version - which wakes heavy
                -- consumers like the needs index - when the payload changed.
                local sig = snapshot_content_sig(s)
                if Store.content_signatures[k] ~= sig then
                    note_content_change("cache-newer", k, s, Store.content_signatures[k], sig)
                    Store.content_signatures[k] = sig
                    content_changed = true
                end
            end
        end
    end
    if accepted then
        Store.version = (Store.version or 0) + 1
    end
    if content_changed then
        Store.content_version = (Store.content_version or 0) + 1
    end
    return content_changed
end

function Store.load()
    local ok, t, reason = backend:load()
    if ok and type(t) == "table" then ingest_cache_table(t, true) end
    Store.cache_signature = backend:signature()
    Store.cache_last_reload_reason = ok and "loaded cache" or ("cache unavailable: " .. tostring(reason or "?"))
end

function Store.reload_cache()
    local ok, t, reason = backend:reload()
    if not ok or type(t) ~= "table" then
        Store.cache_last_reload_reason = "cache load skipped: " .. tostring(reason or "?")
        diag.count("store.cache_load_skipped")
        return false
    end
    local changed = ingest_cache_table(t, false)
    Store.cache_signature = backend:signature()
    Store.cache_last_reload_reason = changed and "loaded changed inventory" or "loaded unchanged inventory"
    return changed
end

function Store.reload_cache_if_changed(force)
    local sig = backend:signature()
    if not force and Store.cache_signature ~= nil and sig == Store.cache_signature then
        Store.cache_last_reload_reason = "cache file unchanged"
        return false, "unchanged"
    end
    local ok, t, reason = backend:reload()
    if not ok or type(t) ~= "table" then
        Store.cache_last_reload_reason = "cache load skipped: " .. tostring(reason or "?")
        diag.count("store.cache_load_skipped")
        return false, "unavailable"
    end
    local changed = ingest_cache_table(t, false)
    Store.cache_signature = sig
    Store.cache_last_reload_reason = changed and "accepted newer inventory" or "cache loaded; no newer inventory"
    return changed, Store.cache_last_reload_reason
end

function Store.cache_status()
    local st = (backend and backend:status()) or {}
    return {
        signature = Store.cache_signature,
        reason = Store.cache_last_reload_reason,
        file = st.file or cfg.CacheFile,
        backend = st.backend,
    }
end

-- ---- Ignored characters (shared, fleet-wide) --------------------------------
-- Muted/forgotten characters (buff bots, one-off logins) are excluded here so
-- they vanish from the roster AND from every consumer of peer_keys(): the
-- needs-index scan (visible_char_keys) and the announce group-scan. One
-- chokepoint, both the display win and the performance win.
local function ignore_norm(name)
    return tostring(name or ""):lower():gsub("%s+", ""):gsub("[^%w]", "")
end

function Store.ignored_set()
    local t = cfg.SharedSettings and cfg.SharedSettings.ignoredChars
    return type(t) == "table" and t or {}
end

function Store.is_ignored_name(name)
    local n = ignore_norm(name)
    if n == "" then return false end
    return Store.ignored_set()[n] ~= nil
end

function Store.is_ignored_key(key)
    local s = Store.sources[key]
    return Store.is_ignored_name(s and s.name or key)
end

-- on=true mutes (hide + skip scan, reversible); on=false un-mutes. Shared file
-- is saved immediately so the whole fleet picks it up via LoadSharedSettings.
function Store.set_ignored(name, on)
    local n = ignore_norm(name)
    if n == "" then return false end
    cfg.SharedSettings.ignoredChars = cfg.SharedSettings.ignoredChars or {}
    cfg.SharedSettings.ignoredChars[n] = on and tostring(name) or nil
    if cfg.SaveSharedSettings then cfg.SaveSharedSettings() end
    Store.version = (Store.version or 0) + 1
    Store.content_version = (Store.content_version or 0) + 1
    Store.dirty = true
    return true
end

-- Forget = mute AND purge cached snapshot (reclaim memory). The mute keeps the
-- character from re-appearing the next time it announces; un-mute to restore.
function Store.forget_char(key)
    key = tostring(key or "")
    local s = Store.sources[key]
    Store.set_ignored((s and s.name) or key, true)
    Store.remove_source(key)
    return true
end

function Store.ignored_names()
    local out = {}
    for n, label in pairs(Store.ignored_set()) do
        out[#out + 1] = { norm = n, label = tostring(label == true and n or label) }
    end
    table.sort(out, function(a, b) return a.label:lower() < b.label:lower() end)
    return out
end

function Store.peer_keys()
    local mine = my_key()
    local keys = {}
    for k, s in pairs(Store.sources) do
        if k ~= mine and not is_invalid_source_key(k, s)
            and not Store.is_ignored_name(s and s.name or k) then
            keys[#keys+1] = k
        end
    end
    table.sort(keys, function(a, b) return (Store.sources[a].name or a) < (Store.sources[b].name or b) end)
    return keys
end

function Store.invalid_peer_keys()
    local mine = my_key()
    local keys = {}
    for k, s in pairs(Store.sources) do
        if k ~= mine and is_invalid_source_key(k, s) then keys[#keys + 1] = k end
    end
    table.sort(keys)
    return keys
end

function Store.remove_source(key)
    key = tostring(key or "")
    if key == "" or key == my_key() or not Store.sources[key] then return false end
    Store.sources[key] = nil
    Store.content_signatures[key] = nil
    Store.last_content_change_by_key[key] = nil
    Store.version = (Store.version or 0) + 1
    Store.content_version = (Store.content_version or 0) + 1
    Store.dirty = true
    return true
end

function Store.prune_invalid_sources()
    local removed = 0
    for _, key in ipairs(Store.invalid_peer_keys()) do
        if Store.remove_source(key) then removed = removed + 1 end
    end
    return removed
end

function Store.is_invalid_source_key(key)
    return is_invalid_source_key(key, Store.sources[key])
end

function Store.is_recently_visible(key, snap)
    snap = snap or Store.sources[key]
    if not snap then return false end
    if snap.status == "online" or snap.status == "stale" then return true end
    local last = tonumber(snap.last_seen) or 0
    if last <= 0 then return false end
    local grace = tonumber(Settings.peerVisibleGraceSeconds) or 180
    return (os.time() - last) <= grace
end

function Store.get(key) return Store.sources[key] end

function Store.counts()
    local on, st, off = 0, 0, 0
    for k, s in pairs(Store.sources) do
        if k ~= my_key() and not is_invalid_source_key(k, s) then
            if s.status == "online" then on = on + 1 elseif s.status == "stale" then st = st + 1 else off = off + 1 end
        end
    end
    return on, st, off
end

M.Store  = Store
M.my_key = my_key
return M
