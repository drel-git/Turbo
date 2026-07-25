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

-- Debounced flush after live inventory content changes (put/delta). Lets the
-- UI BiS/announce path see peer loot in ~seconds instead of waiting for the
-- normal bg save_every (~30s). Cache reloads do not schedule this.
local content_flush_due_at = nil
-- Keys whose content_signature changed since last successful persist. Default
-- Store.save only serializes these (partial) — full-fleet serialize was 400s+.
local dirty_persist_keys = {}
local persisted_content_sig = {}

-- In-flight budgeted payload build (bags/bank). Aborted when inventory changes again.
local persist_job = nil
local begin_persist_job, progress_persist_job

local function schedule_content_flush()
    local coalesce = tonumber(CFG.save_content_coalesce_s)
    if coalesce == nil then coalesce = 8.0 end
    if coalesce <= 0 then return end
    -- Restart the window on every change so a loot train collapses to one write.
    content_flush_due_at = os.clock() + coalesce
end

local function mark_persist_dirty(key)
    key = tostring(key or "")
    if key == "" then return end
    dirty_persist_keys[key] = true
end

local function my_key()
    return (mq.TLO.MacroQuest.Server() or "?") .. "_" .. (mq.TLO.Me.CleanName() or "?")
end

-- Own row: always persist. Peer rows: only when this bg shares the box with a
-- TurboGear UI (viewer reads SQLite, not actor mail). Pure bg bots must not
-- rewrite peer rows — that reintroduced Discord's multi-minute serialize hitch.
local function should_persist_key(key)
    if key == my_key() then return true end
    local ok, st = pcall(require, 'state')
    if not ok or type(st) ~= "table" or st.bg ~= true then return false end
    local scripts = st.local_guard_scripts
    return type(scripts) == "table" and scripts.main == true
end

local function abort_persist_job(reason)
    if not persist_job then return end
    persist_job = nil
    diag.count("store.persist_job_aborted")
    if reason then
        diag.event("store.persist_job_aborted", tostring(reason))
    end
end

local function note_persist_dirty(key)
    if not should_persist_key(key) then return end
    mark_persist_dirty(key)
    -- Inventory moved again: drop in-flight chunked build and re-settle.
    abort_persist_job("content_changed")
    schedule_content_flush()
    Store.dirty = true
end

-- "?" is discover_peer / failed Class.Name sentinel — never overwrite a real class.
-- Prefer canonical_class so SHD / Shadowknight land on LazBiS "Shadow Knight".
local function known_class(c)
    if cfg.canonical_class then return cfg.canonical_class(c) end
    return cfg.known_class and cfg.known_class(c) or nil
end

local function coalesce_class(preferred, fallback)
    return known_class(preferred) or known_class(fallback) or ""
end

-- Viewer-side fill: peer rows often land as discover stubs (class="") while the
-- toon is in group/zone. BiS needs a real class; pull it from Group/Spawn TLOs.
local function class_from_world(name)
    name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then return nil end
    local c = nil
    pcall(function()
        local m = mq.TLO.Group and mq.TLO.Group.Member and mq.TLO.Group.Member(name)
        if m and m() then
            if m.Class and m.Class.Name then c = m.Class.Name() end
            if (not c or c == "" or c == "?") and m.Class then c = m.Class() end
            if (not c or c == "" or c == "?") and m.Class and m.Class.ShortName then c = m.Class.ShortName() end
        end
    end)
    if known_class(c) then return known_class(c) end
    pcall(function()
        local s = mq.TLO.Spawn("pc =" .. name)
        if not (s and s()) then s = mq.TLO.Spawn(name) end
        if s and s() then
            if s.Class and s.Class.Name then c = s.Class.Name() end
            if (not c or c == "" or c == "?") and s.Class then c = s.Class() end
            if (not c or c == "" or c == "?") and s.Class and s.Class.ShortName then c = s.Class.ShortName() end
        end
    end)
    return known_class(c)
end

function Store.enrich_class(snap)
    if type(snap) ~= "table" then return snap end
    if known_class(snap.class) then
        snap.class = known_class(snap.class)
        return snap
    end
    local c = class_from_world(snap.name)
    if c then
        snap.class = c
        Store.version = (Store.version or 0) + 1
    end
    return snap
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
        class = coalesce_class(snap.class, existing.class),
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
        radiant_crystals = snap.radiant_crystals ~= nil and snap.radiant_crystals or existing.radiant_crystals,
        ebon_crystals = snap.ebon_crystals ~= nil and snap.ebon_crystals or existing.ebon_crystals,
        platinum = snap.platinum ~= nil and snap.platinum or existing.platinum,
        diamond_coins = snap.diamond_coins ~= nil and snap.diamond_coins or existing.diamond_coins,
        tribute_favor = snap.tribute_favor ~= nil and snap.tribute_favor or existing.tribute_favor,
        celestial_crests = snap.celestial_crests ~= nil and snap.celestial_crests or existing.celestial_crests,
        aa_unspent = snap.aa_unspent ~= nil and snap.aa_unspent or existing.aa_unspent,
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
        out.spell_ids = snap.spell_ids
    else
        out.spells = existing.spells
        out.spells_sig = existing.spells_sig
        out.spell_ids = existing.spell_ids
    end
    return out
end

local function merge_snapshot(existing, snap)
    if type(existing) ~= "table" or type(snap) ~= "table" then return snap end
    if snap.depth ~= "full" then return merge_lite_snapshot(existing, snap) end
    -- Never let a full publish wipe a known class ("?" / blank → BiS (?)).
    snap.class = coalesce_class(snap.class, existing.class)
    if snap.lockouts == nil then snap.lockouts = existing.lockouts end
    if snap.liveStats == nil then snap.liveStats = existing.liveStats end
    if snap.radiant_crystals == nil then snap.radiant_crystals = existing.radiant_crystals end
    if snap.ebon_crystals == nil then snap.ebon_crystals = existing.ebon_crystals end
    if snap.platinum == nil then snap.platinum = existing.platinum end
    if snap.diamond_coins == nil then snap.diamond_coins = existing.diamond_coins end
    if snap.tribute_favor == nil then snap.tribute_favor = existing.tribute_favor end
    if snap.celestial_crests == nil then snap.celestial_crests = existing.celestial_crests end
    if snap.aa_unspent == nil then snap.aa_unspent = existing.aa_unspent end
    if not snap.spells_sig or snap.spells_sig == "" then
        snap.spells = existing.spells
        snap.spells_sig = existing.spells_sig
        snap.spell_ids = existing.spell_ids
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
            -- Own row always. Peer rows only on UI+bg boxes so the viewer process
            -- (cache-only) can see actor SNAPSHOTs; pure bg peers skip (hitch).
            note_persist_dirty(key)
        end
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
        existing.class = coalesce_class(delta.class, existing.class)
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
            note_persist_dirty(key)
        end
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
        existing.class = coalesce_class(snap.class, existing.class)
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
        class = coalesce_class(snap.class, nil),
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
        class = "",
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
    local now = os.clock()
    -- Quiet settle: while the coalesce window is still open, do not disk-save
    -- (including save_every). Actor publish already updated peers.
    if content_flush_due_at and now < content_flush_due_at then
        return
    end
    -- Budgeted payload build in progress.
    if persist_job then
        progress_persist_job(CFG.save_persist_budget_ms)
        return
    end
    if content_flush_due_at and Store.dirty and now >= content_flush_due_at then
        diag.count("store.content_flush")
        content_flush_due_at = nil
        begin_persist_job()
        if persist_job then progress_persist_job(CFG.save_persist_budget_ms) end
    elseif Store.dirty and (now - Store.last_save) > save_every then
        begin_persist_job()
        if persist_job then
            progress_persist_job(CFG.save_persist_budget_ms)
        end
    end
end

local function write_wallet_sidecar(out)
    -- Tiny TurboGear_wallet.lua for Turbo $ panel (avoid scanning multi-MB cache).
    local path = tostring(cfg.WalletFile or '')
    if path == '' or type(out) ~= 'table' then return end
    local slim = {}
    for k, s in pairs(out) do
        if type(s) == 'table' then
            slim[k] = {
                name = s.name,
                platinum = s.platinum,
                diamond_coins = s.diamond_coins,
                radiant_crystals = s.radiant_crystals,
                ebon_crystals = s.ebon_crystals,
                tribute_favor = s.tribute_favor,
                celestial_crests = s.celestial_crests,
                aa_unspent = s.aa_unspent,
            }
        end
    end
    local tmp = path .. '.tmp'
    pcall(function() os.remove(tmp) end)
    local ok = pcall(function() mq.pickle(tmp, slim) end)
    if not ok then
        pcall(function() os.remove(tmp) end)
        return
    end
    pcall(function() os.remove(path) end)
    if not os.rename(tmp, path) then
        pcall(function() os.remove(tmp) end)
    end
end

local WALLET_KEYS = {
    'platinum', 'diamond_coins', 'radiant_crystals', 'ebon_crystals',
    'tribute_favor', 'celestial_crests', 'aa_unspent',
}

--- Merge wallet-only fields (depth=wallet) and rewrite sidecar immediately.
function Store.put_wallet(wallet, kind)
    if type(wallet) ~= 'table' or not wallet.name or not wallet.server then return false end
    local key = wallet.server .. '_' .. wallet.name
    local existing = Store.sources[key]
    local out
    if type(existing) == 'table' then
        out = existing
        for _, k in ipairs(WALLET_KEYS) do
            if wallet[k] ~= nil then out[k] = wallet[k] end
        end
        out.updated = tonumber(wallet.updated) or os.time()
        out.class = coalesce_class(wallet.class, out.class)
        out.level = wallet.level or out.level
    else
        out = {
            name = wallet.name,
            server = wallet.server,
            class = coalesce_class(wallet.class, nil),
            level = wallet.level,
            updated = tonumber(wallet.updated) or os.time(),
            depth = 'wallet',
            kind = kind or 'client',
        }
        for _, k in ipairs(WALLET_KEYS) do
            out[k] = wallet[k]
        end
        Store.sources[key] = out
    end
    out.status = 'online'
    out.last_seen = os.time()
    out.kind = kind or out.kind or 'client'
    if (kind or 'client') == 'client' then out.actorSeenAt = os.time() end
    Store.sources[key] = out
    Store.version = (Store.version or 0) + 1
    pcall(write_wallet_sidecar, Store.sources)
    return true
end

function Store.flush_wallet_sidecar()
    pcall(write_wallet_sidecar, Store.sources)
end

-- Persist-slim: drop stats/focus/classes blobs. Ownership + Inventory need
-- name/id/location/augs; Stats/Focus re-enrich from live gather when opened.
-- This is what made own-row serialize 30–60s for a ~370KB rich tree.
local function slim_aug(a)
    if type(a) ~= "table" then return a end
    return {
        index = a.index, type = a.type, name = a.name, id = a.id,
        icon = a.icon, empty = a.empty,
    }
end

local function slim_item(it)
    if type(it) ~= "table" then return it end
    local augs = {}
    for i, a in ipairs(it.augs or {}) do
        augs[i] = slim_aug(a)
    end
    return {
        name = it.name, id = it.id, icon = it.icon,
        location = it.location, where = it.where,
        slotid = it.slotid, slotname = it.slotname,
        qty = it.qty, nodrop = it.nodrop,
        attuned = it.attuned, attunable = it.attunable,
        lore = it.lore, loreGroup = it.loreGroup,
        augType = it.augType, depth = it.depth or "lite",
        augs = augs,
    }
end

local function slim_item_list(list)
    if type(list) ~= "table" then return {} end
    local out = {}
    for i, it in ipairs(list) do
        out[i] = slim_item(it)
    end
    return out
end

local function persist_row(s)
    local has_spell_ids = type(s.spell_ids) == "table" and #s.spell_ids > 0
    return {
        name = s.name, server = s.server, class = s.class, level = s.level,
        updated = s.updated, seq = s.seq, inventoryUpdated = s.inventoryUpdated,
        metaUpdated = s.metaUpdated, actorSeenAt = s.actorSeenAt,
        discoverySeenAt = s.discoverySeenAt, kind = s.kind, depth = s.depth,
        equipped = slim_item_list(s.equipped),
        bags = slim_item_list(s.bags),
        bank = slim_item_list(s.bank),
        bankValid = s.bankValid, bankLive = s.bankLive, bankOpen = s.bankOpen,
        bankPreserved = s.bankPreserved, bankCapturedAt = s.bankCapturedAt,
        bankReason = s.bankReason,
        lockouts = s.lockouts,
        -- Prefer compact spell ids; full spell name tables are large and rebuildable.
        spells = has_spell_ids and nil or s.spells,
        spells_sig = s.spells_sig,
        spell_ids = s.spell_ids,
        radiant_crystals = s.radiant_crystals, ebon_crystals = s.ebon_crystals,
        platinum = s.platinum, diamond_coins = s.diamond_coins,
        tribute_favor = s.tribute_favor, celestial_crests = s.celestial_crests,
        aa_unspent = s.aa_unspent,
    }
end

-- Sectional payload cache: bags/bank dominate serialize time (~7–11s). Equip-only
-- changes reuse those section strings; full content_sig match skips the row.
local section_ser_cache = {}

local function backend_codec()
    if not backend or backend.kind ~= "sqlite" then return nil, nil end
    local mod = package.loaded["store_backend_sqlite"]
    if type(mod) ~= "table" then return nil, nil end
    return mod._serialize, mod._hash
end

local function encode_scalar(v)
    local t = type(v)
    if t == "number" then
        if v == math.floor(v) and math.abs(v) < 9e15 then return string.format("%d", v) end
        return string.format("%.17g", v)
    elseif t == "boolean" then
        return tostring(v)
    elseif t == "string" then
        return string.format("%q", v)
    end
    return "nil"
end

local function encode_field(k, encoded_v)
    return "[" .. string.format("%q", tostring(k)) .. "]=" .. encoded_v
end

local function section_payload(cache, sig_key, ser_key, sig, live_list, serialize_fn)
    if cache[sig_key] == sig and type(cache[ser_key]) == "string" then
        return cache[ser_key], true
    end
    local ser = serialize_fn(slim_item_list(live_list))
    cache[sig_key] = sig
    cache[ser_key] = ser
    return ser, false
end

-- Build SQLite payload with sectional reuse. Equip-only flushes keep bags/bank
-- strings and only re-slim/re-serialize the changed list(s).
local function build_row_payload(key, live, serialize_fn, hash_fn)
    local content_sig = Store.content_signatures[key]
    local cache = section_ser_cache[key]
    if not cache then
        cache = {}
        section_ser_cache[key] = cache
    end
    if content_sig and cache.full_sig == content_sig and type(cache.full_payload) == "string" then
        diag.count("store.serialize_full_reuse")
        return cache.full_payload, cache.full_hash or hash_fn(cache.full_payload)
    end

    local eq_sig = item_list_sig(live.equipped)
    local bags_sig = item_list_sig(live.bags)
    local bank_sig = item_list_sig(live.bank)
    local reused = 0
    local eq_ser, hit = section_payload(cache, "eq_sig", "eq", eq_sig, live.equipped, serialize_fn)
    if hit then reused = reused + 1 end
    local bags_ser
    bags_ser, hit = section_payload(cache, "bags_sig", "bags", bags_sig, live.bags, serialize_fn)
    if hit then reused = reused + 1 end
    local bank_ser
    bank_ser, hit = section_payload(cache, "bank_sig", "bank", bank_sig, live.bank, serialize_fn)
    if hit then reused = reused + 1 end
    if reused > 0 then diag.count("store.serialize_section_reuse", reused) end

    local has_spell_ids = type(live.spell_ids) == "table" and #live.spell_ids > 0
    local parts = {
        encode_field("name", encode_scalar(live.name)),
        encode_field("server", encode_scalar(live.server)),
        encode_field("class", encode_scalar(live.class)),
        encode_field("level", encode_scalar(live.level)),
        encode_field("updated", encode_scalar(live.updated)),
        encode_field("seq", encode_scalar(live.seq)),
        encode_field("inventoryUpdated", encode_scalar(live.inventoryUpdated)),
        encode_field("metaUpdated", encode_scalar(live.metaUpdated)),
        encode_field("actorSeenAt", encode_scalar(live.actorSeenAt)),
        encode_field("discoverySeenAt", encode_scalar(live.discoverySeenAt)),
        encode_field("kind", encode_scalar(live.kind)),
        encode_field("depth", encode_scalar(live.depth)),
        encode_field("equipped", eq_ser),
        encode_field("bags", bags_ser),
        encode_field("bank", bank_ser),
        encode_field("bankValid", encode_scalar(live.bankValid)),
        encode_field("bankLive", encode_scalar(live.bankLive)),
        encode_field("bankOpen", encode_scalar(live.bankOpen)),
        encode_field("bankPreserved", encode_scalar(live.bankPreserved)),
        encode_field("bankCapturedAt", encode_scalar(live.bankCapturedAt)),
        encode_field("bankReason", encode_scalar(live.bankReason)),
        encode_field("lockouts", serialize_fn(live.lockouts)),
        encode_field("spells", serialize_fn(has_spell_ids and nil or live.spells)),
        encode_field("spells_sig", encode_scalar(live.spells_sig)),
        encode_field("spell_ids", serialize_fn(live.spell_ids)),
        encode_field("radiant_crystals", encode_scalar(live.radiant_crystals)),
        encode_field("ebon_crystals", encode_scalar(live.ebon_crystals)),
        encode_field("platinum", encode_scalar(live.platinum)),
        encode_field("diamond_coins", encode_scalar(live.diamond_coins)),
        encode_field("tribute_favor", encode_scalar(live.tribute_favor)),
        encode_field("celestial_crests", encode_scalar(live.celestial_crests)),
        encode_field("aa_unspent", encode_scalar(live.aa_unspent)),
    }
    local payload = "{" .. table.concat(parts, ",") .. "}"
    local h = hash_fn(payload)
    cache.full_sig = content_sig
    cache.full_payload = payload
    cache.full_hash = h
    return payload, h
end

local function assemble_payload_from_cache(key, live, cache, serialize_fn, hash_fn)
    local has_spell_ids = type(live.spell_ids) == "table" and #live.spell_ids > 0
    local parts = {
        encode_field("name", encode_scalar(live.name)),
        encode_field("server", encode_scalar(live.server)),
        encode_field("class", encode_scalar(live.class)),
        encode_field("level", encode_scalar(live.level)),
        encode_field("updated", encode_scalar(live.updated)),
        encode_field("seq", encode_scalar(live.seq)),
        encode_field("inventoryUpdated", encode_scalar(live.inventoryUpdated)),
        encode_field("metaUpdated", encode_scalar(live.metaUpdated)),
        encode_field("actorSeenAt", encode_scalar(live.actorSeenAt)),
        encode_field("discoverySeenAt", encode_scalar(live.discoverySeenAt)),
        encode_field("kind", encode_scalar(live.kind)),
        encode_field("depth", encode_scalar(live.depth)),
        encode_field("equipped", cache.eq or "{}"),
        encode_field("bags", cache.bags or "{}"),
        encode_field("bank", cache.bank or "{}"),
        encode_field("bankValid", encode_scalar(live.bankValid)),
        encode_field("bankLive", encode_scalar(live.bankLive)),
        encode_field("bankOpen", encode_scalar(live.bankOpen)),
        encode_field("bankPreserved", encode_scalar(live.bankPreserved)),
        encode_field("bankCapturedAt", encode_scalar(live.bankCapturedAt)),
        encode_field("bankReason", encode_scalar(live.bankReason)),
        encode_field("lockouts", serialize_fn(live.lockouts)),
        encode_field("spells", serialize_fn(has_spell_ids and nil or live.spells)),
        encode_field("spells_sig", encode_scalar(live.spells_sig)),
        encode_field("spell_ids", serialize_fn(live.spell_ids)),
        encode_field("radiant_crystals", encode_scalar(live.radiant_crystals)),
        encode_field("ebon_crystals", encode_scalar(live.ebon_crystals)),
        encode_field("platinum", encode_scalar(live.platinum)),
        encode_field("diamond_coins", encode_scalar(live.diamond_coins)),
        encode_field("tribute_favor", encode_scalar(live.tribute_favor)),
        encode_field("celestial_crests", encode_scalar(live.celestial_crests)),
        encode_field("aa_unspent", encode_scalar(live.aa_unspent)),
    }
    local payload = "{" .. table.concat(parts, ",") .. "}"
    local h = hash_fn(payload)
    local content_sig = Store.content_signatures[key]
    cache.full_sig = content_sig
    cache.full_payload = payload
    cache.full_hash = h
    return payload, h
end

begin_persist_job = function()
    local serialize_fn, hash_fn = backend_codec()
    if not serialize_fn or not hash_fn then
        Store.save()
        return
    end
    local keys = {}
    for k in pairs(dirty_persist_keys) do
        if type(Store.sources[k]) == "table" then keys[#keys + 1] = k end
    end
    if #keys == 0 then
        content_flush_due_at = nil
        Store.dirty = false
        diag.count("store.save_skipped_clean")
        return
    end
    persist_job = {
        keys = keys,
        ki = 1,
        out = {},
        serialize_fn = serialize_fn,
        hash_fn = hash_fn,
        work = nil,
        section = nil,
    }
    diag.count("store.persist_job_started")
    diag.event("store.persist_job_started", string.format("keys=%d", #keys))
end

local function finish_persist_job()
    local job = persist_job
    if not job then return end
    local any = false
    for _ in pairs(job.out) do any = true; break end
    if not any then
        persist_job = nil
        return
    end
    local ok_save, save_reason = backend:save(job.out, { partial = true })
    Store.cache_last_reload_reason = ok_save and "saved atomically" or ("save failed: " .. tostring(save_reason or "?"))
    Store.last_save = os.clock()
    if not ok_save then
        diag.count("store.save_failed")
        for k in pairs(job.out) do dirty_persist_keys[k] = true end
        Store.dirty = true
        schedule_content_flush()
    else
        for k in pairs(job.out) do
            persisted_content_sig[k] = Store.content_signatures[k]
            dirty_persist_keys[k] = nil
        end
        pcall(write_wallet_sidecar, Store.sources)
        Store.cache_signature = backend:signature()
        local still = false
        for _ in pairs(dirty_persist_keys) do still = true; break end
        if still then
            Store.dirty = true
            schedule_content_flush()
        else
            Store.dirty = false
            content_flush_due_at = nil
        end
        diag.count("store.persist_job_finished")
    end
    persist_job = nil
end

progress_persist_job = function(budget_ms)
    local job = persist_job
    if not job then return end
    local budget = (tonumber(budget_ms) or tonumber(CFG.save_persist_budget_ms) or 4.0) / 1000.0
    if budget <= 0 then budget = 0.004 end
    local t0 = os.clock()
    local serialize_fn, hash_fn = job.serialize_fn, job.hash_fn

    while (os.clock() - t0) < budget do
        local key = job.keys[job.ki]
        if not key then
            finish_persist_job()
            return
        end
        local live = Store.sources[key]
        if type(live) ~= "table" then
            job.ki = job.ki + 1
            job.work = nil
            job.section = nil
            goto continue_persist
        end
        local content_sig = Store.content_signatures[key]
        if persisted_content_sig[key] ~= nil and persisted_content_sig[key] == content_sig then
            dirty_persist_keys[key] = nil
            job.ki = job.ki + 1
            job.work = nil
            job.section = nil
            goto continue_persist
        end

        if not job.section then
            local cache = section_ser_cache[key]
            if not cache then
                cache = {}
                section_ser_cache[key] = cache
            end
            if content_sig and cache.full_sig == content_sig and type(cache.full_payload) == "string" then
                job.out[key] = {
                    name = live.name, server = live.server, class = live.class, level = live.level,
                    updated = live.updated, seq = live.seq,
                    inventoryUpdated = live.inventoryUpdated,
                    bankCapturedAt = live.bankCapturedAt,
                    _payload = cache.full_payload,
                    _payload_hash = cache.full_hash or hash_fn(cache.full_payload),
                }
                diag.count("store.serialize_full_reuse")
                job.ki = job.ki + 1
                goto continue_persist
            end
            job.cache = cache
            job.key_sig = content_sig
            job.eq_sig = item_list_sig(live.equipped)
            job.bags_sig = item_list_sig(live.bags)
            job.bank_sig = item_list_sig(live.bank)
            job.need = {}
            if not (cache.eq_sig == job.eq_sig and type(cache.eq) == "string") then
                job.need[#job.need + 1] = { name = "eq", list = live.equipped, sig = job.eq_sig, sig_key = "eq_sig", ser_key = "eq" }
            end
            if not (cache.bags_sig == job.bags_sig and type(cache.bags) == "string") then
                job.need[#job.need + 1] = { name = "bags", list = live.bags, sig = job.bags_sig, sig_key = "bags_sig", ser_key = "bags" }
            else
                diag.count("store.serialize_section_reuse")
            end
            if not (cache.bank_sig == job.bank_sig and type(cache.bank) == "string") then
                job.need[#job.need + 1] = { name = "bank", list = live.bank, sig = job.bank_sig, sig_key = "bank_sig", ser_key = "bank" }
            else
                diag.count("store.serialize_section_reuse")
            end
            if cache.eq_sig == job.eq_sig and type(cache.eq) == "string" then
                diag.count("store.serialize_section_reuse")
            end
            job.need_i = 1
            job.section = "build"
            job.work = nil
        end

        if Store.content_signatures[key] ~= job.key_sig then
            -- Live inventory changed mid-build; settle path will restart.
            abort_persist_job("sig_drift")
            return
        end

        if job.need_i <= #job.need then
            local need = job.need[job.need_i]
            local work = job.work
            if not work then
                local list = need.list or {}
                work = { i = 1, n = #list, list = list, parts = {} }
                job.work = work
                if work.n <= 0 then
                    job.cache[need.sig_key] = need.sig
                    job.cache[need.ser_key] = "{}"
                    job.need_i = job.need_i + 1
                    job.work = nil
                    goto continue_persist
                end
            end
            while work.i <= work.n and (os.clock() - t0) < budget do
                work.parts[work.i] = serialize_fn(slim_item(work.list[work.i]))
                work.i = work.i + 1
            end
            if work.i <= work.n then return end -- budget exhausted mid-section
            local ser = "{" .. table.concat(work.parts, ",") .. "}"
            job.cache[need.sig_key] = need.sig
            job.cache[need.ser_key] = ser
            job.need_i = job.need_i + 1
            job.work = nil
            goto continue_persist
        end

        -- All sections ready: assemble + queue for upsert.
        local payload, phash = assemble_payload_from_cache(key, live, job.cache, serialize_fn, hash_fn)
        job.out[key] = {
            name = live.name, server = live.server, class = live.class, level = live.level,
            updated = live.updated, seq = live.seq,
            inventoryUpdated = live.inventoryUpdated,
            bankCapturedAt = live.bankCapturedAt,
            _payload = payload,
            _payload_hash = phash,
        }
        job.ki = job.ki + 1
        job.section = nil
        job.work = nil
        job.need = nil
        ::continue_persist::
    end
end

-- True while a quiet-settle content flush or chunked persist job is in flight.
function Store.persist_busy()
    if persist_job ~= nil then return true end
    if content_flush_due_at and os.clock() < content_flush_due_at then return true end
    return false
end

-- Blocking flush for unload/shutdown. May hitch once; preferred over losing gear state.
function Store.flush_pending()
    abort_persist_job("flush_pending")
    content_flush_due_at = nil
    local any = false
    for _ in pairs(dirty_persist_keys) do any = true; break end
    if not any and not Store.dirty then return false end
    diag.count("store.flush_pending")
    if any then
        Store.save()
    else
        Store.save({ only_self = true })
    end
    return true
end

-- opts.only_self: persist just this box's row (worn_persist).
-- opts.keys: optional list/set of store keys to include.
-- opts.force_all: serialize every source (rare; setup/manual). Default saves only
-- dirty_persist_keys so content_flush cannot re-serialize the whole fleet.
function Store.save(opts)
    opts = type(opts) == "table" and opts or {}
    abort_persist_job("blocking_save")
    content_flush_due_at = nil
    Store.last_save = os.clock(); Store.dirty = false
    local filter = nil
    if opts.only_self == true then
        local k = my_key()
        if k and k ~= "" then filter = { [k] = true } end
    elseif type(opts.keys) == "table" then
        filter = {}
        if opts.keys[1] ~= nil then
            for _, k in ipairs(opts.keys) do filter[tostring(k)] = true end
        else
            for k, v in pairs(opts.keys) do
                if v then filter[tostring(k)] = true end
            end
        end
    elseif opts.force_all ~= true then
        filter = dirty_persist_keys
        dirty_persist_keys = {}
        local any = false
        for _ in pairs(filter) do any = true; break end
        if not any then
            diag.count("store.save_skipped_clean")
            return
        end
    end
    local partial = filter ~= nil
    local source_count = 0
    for _ in pairs(Store.sources) do source_count = source_count + 1 end
    diag.context("store.save", string.format("sources=%d backend=%s partial=%s",
        source_count, tostring(backend and backend.kind or "?"), tostring(partial)))
    diag.time("store.save", function()
        local serialize_fn, hash_fn = backend_codec()
        local out = {}
        local skipped_unchanged = 0
        for k, s in pairs(Store.sources) do
            if filter and not filter[k] then goto continue_save_key end
            -- Disk already has this inventory content; skip slim+serialize.
            if opts.force_all ~= true
                and persisted_content_sig[k] ~= nil
                and persisted_content_sig[k] == Store.content_signatures[k] then
                skipped_unchanged = skipped_unchanged + 1
                goto continue_save_key
            end
            if serialize_fn and hash_fn then
                local payload, phash = build_row_payload(k, s, serialize_fn, hash_fn)
                -- Scalars for bind_row / merge-by-newer; lists live in _payload.
                out[k] = {
                    name = s.name, server = s.server, class = s.class, level = s.level,
                    updated = s.updated, seq = s.seq,
                    inventoryUpdated = s.inventoryUpdated,
                    bankCapturedAt = s.bankCapturedAt,
                    _payload = payload,
                    _payload_hash = phash,
                }
            else
                out[k] = persist_row(s)
            end
            ::continue_save_key::
        end
        if skipped_unchanged > 0 then
            diag.count("store.save_skipped_unchanged", skipped_unchanged)
        end
        local any_out = false
        for _ in pairs(out) do any_out = true; break end
        if not any_out then
            diag.count("store.save_skipped_clean")
            return
        end
        local ok_save, save_reason = backend:save(out, { partial = partial })
        Store.cache_last_reload_reason = ok_save and "saved atomically" or ("save failed: " .. tostring(save_reason or "?"))
        if not ok_save then
            diag.count("store.save_failed")
            if partial then
                for k in pairs(out) do dirty_persist_keys[k] = true end
            end
        else
            for k in pairs(out) do
                persisted_content_sig[k] = Store.content_signatures[k]
                dirty_persist_keys[k] = nil
            end
            pcall(write_wallet_sidecar, Store.sources)
        end
        -- Partial own-row saves: adopt data_version without re-deserializing the
        -- whole fleet (that re-parse was a second hitch after serialize). UI/bg
        -- already poll reload_cache_if_changed for peer updates.
        if ok_save and partial then
            Store.cache_signature = backend:signature()
        elseif ok_save then
            Store.cache_signature = nil
            pcall(function() Store.reload_cache_if_changed(true) end)
        else
            Store.cache_signature = backend:signature()
        end
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
                -- Loaded from disk: already persisted at this content.
                persisted_content_sig[k] = sig
                accepted = true
                content_changed = true
            elseif is_newer(s, existing) then
                s = preserve_presence(existing, s, mark_offline and "offline" or existing.status)
                -- Disk/actor rows with class="?" must not clobber a known in-memory class.
                s.class = coalesce_class(s.class, existing.class)
                Store.sources[k] = s
                accepted = true
                -- Newer timestamp does not imply new content (bg re-saves on
                -- heartbeats). Only bump content_version - which wakes heavy
                -- consumers like the needs index - when the payload changed.
                local sig = snapshot_content_sig(s)
                if Store.content_signatures[k] ~= sig then
                    note_content_change("cache-newer", k, s, Store.content_signatures[k], sig)
                    Store.content_signatures[k] = sig
                    -- Fresher disk/actor row replaces memory; treat as persisted.
                    persisted_content_sig[k] = sig
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
    -- Refresh lean wallet sidecar for Turbo $ even when main cache was not rewritten.
    if ok then pcall(write_wallet_sidecar, Store.sources) end
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
    persisted_content_sig[key] = nil
    section_ser_cache[key] = nil
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

function Store.get(key)
    local snap = Store.sources[key]
    if type(snap) == "table" and not known_class(snap.class) then
        Store.enrich_class(snap)
    end
    return snap
end

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
