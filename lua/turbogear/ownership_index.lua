-- TurboGear/ownership_index.lua
-- Core-safe compact ownership index over plain snapshot-shaped tables.

local M = {}

local work_clock = os.clock
local fingerprint_cache = setmetatable({}, { __mode = "k" })
local published_indexes = {}
local published_order = {}
local PUBLISHED_INDEX_MAX = 128
local fingerprint_stats = {
    builds = 0,
    hits = 0,
    seq_changes = 0,
    equipped_ref_changes = 0,
    bags_ref_changes = 0,
    bank_ref_changes = 0,
    bank_state_changes = 0,
    published_hits = 0,
    published_writes = 0,
}

--- CPU/work clock injection for deterministic budget tests. This clock is
--- intentionally separate from user-facing elapsed deadlines in announcer.
function M._set_work_clock_for_tests(fn)
    work_clock = type(fn) == "function" and fn or os.clock
end

local function trim(s)
    return tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end
M.trim = trim

local function norm(s)
    s = trim(s):lower()
    -- EQ / Lucy often use backtick or curly quotes in names like Adventurer's.
    s = s:gsub("`", "'"):gsub("\226\128\152", "'"):gsub("\226\128\153", "'")
    return s
end
M.norm = norm

local function keep_tattered_sack_rank_paren(s)
    return s:find("tattered sack", 1, true) ~= nil
end

local norm_name_cache = {}
local function norm_item_name_uncached(s)
    s = norm(s)
    if not keep_tattered_sack_rank_paren(s) then
        s = s:gsub("%s*%(%s*[^%)]-%s*%)%s*$", "")
    end
    s = s:gsub("%s*%[%s*[^%]]-%s*%]%s*$", "")
    s = s:gsub("%s+", " ")
    local stripped = s:gsub("%s*%d%d%d+$", "")
    if stripped ~= "" then s = stripped end
    return trim(s)
end

function M.norm_item_name(s)
    if type(s) ~= "string" then return norm_item_name_uncached(s) end
    local hit = norm_name_cache[s]
    if hit == nil then
        hit = norm_item_name_uncached(s)
        norm_name_cache[s] = hit
    end
    return hit
end

-- Item names shared by several DIFFERENT item IDs. Jonas Hand tiers 2-6
-- (33167-33171) are all "Jonas Dagmire's Skeletal Hand": a name hit cannot
-- tell a Tier 2 hand from the final one, so these names never match or
-- satisfy a row - only IDs do. Keyed by norm_item_name. Every name matcher
-- consults this (not a per-entry flag) so entry copies cannot lose it.
local ID_ONLY_NAMES = {
    ["jonas dagmire's skeletal hand"] = true,
    ["skeletal hand"] = true,
}

function M.name_is_id_only(name)
    local key = M.norm_item_name(name)
    return key ~= "" and ID_ONLY_NAMES[key] == true
end

local function tier_rank(name)
    name = tostring(name or ""):lower()
    if name:find("- final", 1, true) then return 4 end
    if name:find("- tier iii", 1, true) then return 3 end
    if name:find("- tier ii", 1, true) then return 2 end
    if name:find("- tier i", 1, true) then return 1 end
    return nil
end

function M.fungal_aliases(name)
    local aliases, n = {}, tostring(name or "")
    local rank = tier_rank(n)

    local elem = n:match("^%s*(%S+)%s+Fungus of Suffering%s*%-")
        or n:match("^%s*(%S+)%s+Fungus of Suffering%s*$")
    if elem then
        rank = rank or 4
        aliases[#aliases + 1] = elem .. " Slime of Suffering"
        for i = 1, rank do
            local suffix = i == 4 and "Final" or ("Tier " .. ({ "I", "II", "III" })[i])
            aliases[#aliases + 1] = elem .. " Fungus of Suffering - " .. suffix
        end
        return aliases
    end

    elem = n:match("^%s*(%S+)%s+Slime of Suffering%s*$")
        or n:match("^%s*Base (%S+)%s+Slime of Suffering")
    if elem then
        aliases[#aliases + 1] = elem .. " Slime of Suffering"
        for i = 1, 4 do
            local suffix = i == 4 and "Final" or ("Tier " .. ({ "I", "II", "III" })[i])
            aliases[#aliases + 1] = elem .. " Fungus of Suffering - " .. suffix
        end
        return aliases
    end

    local bloom = n:match("^%s*Fungal Bloom of (.-)%s*%-")
        or n:match("^%s*Fungal Bloom of (.-)%s*$")
    if bloom and bloom ~= "" then
        rank = rank or 4
        aliases[#aliases + 1] = "Noxious Bloom of " .. bloom
        for i = 1, rank do
            local suffix = i == 4 and "Final" or ("Tier " .. ({ "I", "II", "III" })[i])
            aliases[#aliases + 1] = "Fungal Bloom of " .. bloom .. " - " .. suffix
        end
    end
    return aliases
end

local function all_items(snap)
    local out = {}
    for _, spec in ipairs({
        { bucket = snap and snap.equipped or {}, status = "equipped" },
        { bucket = snap and snap.bags or {}, status = "carried" },
        { bucket = snap and snap.bank or {}, status = "carried" },
    }) do
        for _, it in ipairs(spec.bucket) do
            out[#out + 1] = { item = it, status = spec.status }
        end
    end
    return out
end

local function all_augments(snap)
    local out = {}
    for _, spec in ipairs({
        { bucket = snap and snap.equipped or {}, status = "equipped" },
        { bucket = snap and snap.bags or {}, status = "carried" },
        { bucket = snap and snap.bank or {}, status = "carried" },
    }) do
        for _, host in ipairs(spec.bucket) do
            for _, aug in ipairs(host.augs or {}) do
                if not aug.empty and aug.name and aug.name ~= "" and aug.name ~= "Empty" then
                    out[#out + 1] = {
                        status = spec.status,
                        item = {
                            name = aug.name,
                            id = aug.id or 0,
                            icon = aug.icon or 0,
                            location = host.location,
                            where = string.format("%s / %s slot %d", host.where or "", host.name or "item", aug.index or 0),
                            slotname = spec.status == "equipped" and (host.slotname or host.where) or nil,
                            augType = aug.type or 0,
                            host = host.name,
                            augIndex = aug.index,
                        },
                    }
                end
            end
        end
    end
    return out
end

local function better_match(a, b)
    if not a then return b end
    if not b then return a end
    if a.status == "equipped" and b.status ~= "equipped" then return a end
    if b.status == "equipped" and a.status ~= "equipped" then return b end
    return a
end

local function new_index()
    return { by_id = {}, by_name = {}, known_spells = {}, known_spell_ids = {} }
end

local function add_record(idx, rec)
    if type(idx) ~= "table" or type(rec) ~= "table" then return end
    local it = rec.item
    local iid = tonumber(it and it.id)
    if iid and iid > 0 then
        idx.by_id[iid] = better_match(idx.by_id[iid], rec)
    end
    local n = M.norm_item_name(it and it.name)
    if n ~= "" then
        idx.by_name[n] = better_match(idx.by_name[n], rec)
        for _, alias in ipairs(M.fungal_aliases(it and it.name)) do
            local an = M.norm_item_name(alias)
            if an ~= "" then idx.by_name[an] = better_match(idx.by_name[an], rec) end
        end
    end
end

local function add_host_augments(idx, host, status)
    for _, aug in ipairs(type(host) == "table" and host.augs or {}) do
        if not aug.empty and aug.name and aug.name ~= "" and aug.name ~= "Empty" then
            add_record(idx, {
                status = status,
                item = {
                    name = aug.name,
                    id = aug.id or 0,
                    icon = aug.icon or 0,
                    location = host.location,
                    where = string.format("%s / %s slot %d", host.where or "", host.name or "item", aug.index or 0),
                    slotname = status == "equipped" and (host.slotname or host.where) or nil,
                    augType = aug.type or 0,
                    host = host.name,
                    augIndex = aug.index,
                },
            })
        end
    end
end

-- Ownership-only fingerprint of item/aug contents. Intentionally ignores
-- publication freshness, DoN/lockouts, and bank capture timestamps.
-- Store.content_signatures is NOT used: that digest correctly includes
-- lockouts for persistence, which would false-invalidate ownership.
-- Bucket is mixed in so the same item moving worn <-> bag <-> bank changes
-- the token. Records are sorted before hashing so publication order changes
-- during lite/rich settling do not invalidate linked-gear ownership.
local function ownership_items_fp(snap)
    if type(snap) ~= "table" then return "0" end
    local cached = fingerprint_cache[snap]
    if type(cached) == "table"
        and cached.equipped == snap.equipped
        and cached.bags == snap.bags
        and cached.bank == snap.bank
        and cached.bankValid == snap.bankValid
        and cached.bankLive == snap.bankLive
        and cached.bankPreserved == snap.bankPreserved
        and type(cached.value) == "string" then
        local diag = require('diagnostics')
        if type(diag.count) == "function" then diag.count("ownership.fingerprint_cache_hit") end
        fingerprint_stats.hits = fingerprint_stats.hits + 1
        if cached.seq ~= snap.seq then
            cached.seq = snap.seq
            fingerprint_stats.seq_changes = fingerprint_stats.seq_changes + 1
            if type(diag.count) == "function" then diag.count("ownership.snapshot_seq_change") end
        end
        return cached.value
    end
    if type(cached) == "table" then
        local diag = require('diagnostics')
        local function changed(field, metric)
            if cached[field] ~= snap[field] then
                fingerprint_stats[metric] = fingerprint_stats[metric] + 1
                if type(diag.count) == "function" then
                    diag.count("ownership.fingerprint_invalidate." .. field)
                end
            end
        end
        changed("equipped", "equipped_ref_changes")
        changed("bags", "bags_ref_changes")
        changed("bank", "bank_ref_changes")
        if cached.bankValid ~= snap.bankValid or cached.bankLive ~= snap.bankLive
            or cached.bankPreserved ~= snap.bankPreserved then
            fingerprint_stats.bank_state_changes = fingerprint_stats.bank_state_changes + 1
            if type(diag.count) == "function" then
                diag.count("ownership.fingerprint_invalidate.bank_state")
            end
        end
    end
    local fingerprint_t0 = os.clock()
    local tokens, n = {}, 0
    local function item_token(bucket, it)
        it = type(it) == "table" and it or {}
        local aug_tokens = {}
        for _, aug in ipairs(type(it.augs) == "table" and it.augs or {}) do
            aug = type(aug) == "table" and aug or {}
            aug_tokens[#aug_tokens + 1] = table.concat({
                tostring(tonumber(aug.index) or 0),
                tostring(tonumber(aug.id) or 0),
                tostring(aug.empty == true and 1 or 0),
                norm_item_name_uncached(aug.name),
            }, ":")
        end
        table.sort(aug_tokens)
        return table.concat({
            tostring(bucket),
            tostring(tonumber(it.id) or 0),
            norm_item_name_uncached(it.name),
            table.concat(aug_tokens, ","),
        }, "|")
    end
    local function eat(list, bucket)
        for _, it in ipairs(list or {}) do
            n = n + 1
            tokens[#tokens + 1] = item_token(bucket, it)
        end
    end
    eat(snap.equipped, 1)
    eat(snap.bags, 2)
    eat(snap.bank, 3)
    table.sort(tokens)
    local h = 5381
    local function mix(v)
        h = (h * 33 + (tonumber(v) or 0)) % 2147483648
    end
    for _, token in ipairs(tokens) do
        mix(#token)
        for i = 1, #token do
            mix(token:byte(i))
        end
    end
    local value = tostring(n) .. ":" .. string.format("%08x", h)
    fingerprint_cache[snap] = {
        equipped = snap.equipped,
        bags = snap.bags,
        bank = snap.bank,
        bankValid = snap.bankValid,
        bankLive = snap.bankLive,
        bankPreserved = snap.bankPreserved,
        seq = snap.seq,
        value = value,
    }
    fingerprint_stats.builds = fingerprint_stats.builds + 1
    local diag = require('diagnostics')
    if type(diag.count) == "function" then diag.count("ownership.fingerprint_build") end
    if type(diag.sample) == "function" then
        diag.sample("ownership.fingerprint_ms", math.max(0, (os.clock() - fingerprint_t0) * 1000))
    end
    return value
end

function M.invalidate_snapshot_cache(snap)
    if type(snap) == "table" then fingerprint_cache[snap] = nil end
end

function M.has_cached_fingerprint(snap)
    return type(snap) == "table" and fingerprint_cache[snap] ~= nil
end

function M.fingerprint_cache_stats()
    local out = {}
    for key, value in pairs(fingerprint_stats) do out[key] = value end
    return out
end

local function publish_index(cache_key, idx)
    cache_key = tostring(cache_key or "")
    if cache_key == "" or type(idx) ~= "table" then return end
    if published_indexes[cache_key] == nil then
        published_order[#published_order + 1] = cache_key
    end
    published_indexes[cache_key] = idx
    fingerprint_stats.published_writes = fingerprint_stats.published_writes + 1
    while #published_order > PUBLISHED_INDEX_MAX do
        local old = table.remove(published_order, 1)
        if old then published_indexes[old] = nil end
    end
end

local function published_index(cache_key)
    cache_key = tostring(cache_key or "")
    if cache_key == "" then return nil end
    local idx = published_indexes[cache_key]
    if type(idx) == "table" then
        fingerprint_stats.published_hits = fingerprint_stats.published_hits + 1
        local ok, diag = pcall(require, 'diagnostics')
        if ok and diag and type(diag.count) == "function" then
            diag.count("ownership.published_cache_hit")
        end
        return idx
    end
    return nil
end

function M.clear_published_indexes_for_tests()
    published_indexes = {}
    published_order = {}
end

--- Gear ownership cache key. Covers item/aug contents and bank-validity
--- flags. Ignores spells_sig so spell refreshes do not invalidate gear-linked
--- loot announce readiness.
function M.snapshot_gear_key(snap)
    if type(snap) ~= "table" then return "" end
    return table.concat({
        tostring(snap.server or ""),
        tostring(snap.name or ""),
        ownership_items_fp(snap),
        tostring(snap.bankValid == true and "1" or "0"),
        tostring(snap.bankLive == true and "1" or "0"),
        tostring(snap.bankPreserved == true and "1" or "0"),
    }, "|")
end

--- Full ownership semantic key. Covers gear key plus spell ownership.
--- Ignores seq, inventoryUpdated, Store reload
--- stamps, DoN/expedition lockouts, and bankCapturedAt.
function M.snapshot_semantic_key(snap)
    if type(snap) ~= "table" then return "" end
    return table.concat({
        M.snapshot_gear_key(snap),
        tostring(snap.spells_sig or ""),
    }, "|")
end

function M.snapshot_key_parts(snap)
    if type(snap) ~= "table" then
        return {
            key = "",
            hash = "00000000",
            server = "",
            name = "",
            items = "0",
            bank = "0/0/0",
            spells = "",
            full_hash = "00000000",
        }
    end
    local items = ownership_items_fp(snap)
    local bank = table.concat({
        tostring(snap.bankValid == true and "1" or "0"),
        tostring(snap.bankLive == true and "1" or "0"),
        tostring(snap.bankPreserved == true and "1" or "0"),
    }, "/")
    local spells = tostring(snap.spells_sig or "")
    local gear_key = table.concat({
        tostring(snap.server or ""),
        tostring(snap.name or ""),
        items,
        tostring(snap.bankValid == true and "1" or "0"),
        tostring(snap.bankLive == true and "1" or "0"),
        tostring(snap.bankPreserved == true and "1" or "0"),
    }, "|")
    local full_key = gear_key .. "|" .. spells
    local function hash_key(key)
        local h = 5381
        for i = 1, #key do
            h = (h * 33 + key:byte(i)) % 2147483648
        end
        return string.format("%08x", h)
    end
    return {
        key = gear_key,
        hash = hash_key(gear_key),
        full_key = full_key,
        full_hash = hash_key(full_key),
        server = tostring(snap.server or ""),
        name = tostring(snap.name or ""),
        items = items,
        bank = bank,
        spells = spells,
    }
end

function M.snapshot_cache_key(snap)
    return M.snapshot_gear_key(snap)
end

function M.warm_who(row, snap)
    if type(row) == "table" then
        local who = tostring(row.key or "")
        if who ~= "" then return who end
    end
    snap = snap or (type(row) == "table" and row.snap)
    if type(snap) ~= "table" then return "" end
    return tostring(snap.server or "") .. "_" .. tostring(snap.name or "")
end

--- Idempotent warm enqueue. Same semantic key is a no-op; a newer semantic
--- key for the same character replaces the queued/active job.
function M.enqueue_warm(warm, row, reason)
    local diag = require('diagnostics')
    if type(warm) ~= "table" then return false, "no-state" end
    if type(row) ~= "table" or type(row.snap) ~= "table" then return false, "no-row" end
    local snap = row.snap
    local who = M.warm_who(row, snap)
    local key = M.snapshot_cache_key(snap)
    if who == "" or key == "" then return false, "no-key" end
    reason = tostring(reason or "roster")
    warm.queue = type(warm.queue) == "table" and warm.queue or {}

    if M.is_snapshot_index_cached(snap) then
        diag.count("ownership.enqueue_same_semantic_skip")
        diag.count("core_ownership.cache_hit")
        return false, "same_semantic"
    end

    if type(warm.active) == "table" and tostring(warm.active.who or "") == who then
        if warm.active.key == key then
            local previous = warm.active.snap
            if previous ~= snap and type(previous) == "table" then
                local partial = previous._bis_index_warm_job
                if type(partial) == "table" and partial.key == key then
                    previous._bis_index_warm_job = nil
                    partial.snap = snap
                    snap._bis_index_warm_job = partial
                end
            end
            warm.active.row = row
            warm.active.snap = snap
            warm.active.reason = reason
            diag.count("ownership.enqueue_duplicate_skip")
            return false, "duplicate"
        end
        snap._bis_index_warm_job = nil
        if type(warm.active.snap) == "table" then
            warm.active.snap._bis_index_warm_job = nil
        end
        warm.active = nil
        diag.count("ownership.restart_new_semantic")
    end

    for i, q in ipairs(warm.queue) do
        if tostring(q.who or "") == who then
            if q.key == key then
                q.row = row
                q.snap = snap
                q.reason = reason
                diag.count("ownership.enqueue_duplicate_skip")
                return false, "duplicate"
            end
            warm.queue[i] = {
                who = who, key = key, row = row, snap = snap,
                reason = reason, at = work_clock(),
            }
            diag.count("ownership.restart_new_semantic")
            return true, "restart"
        end
    end

    warm.queue[#warm.queue + 1] = {
        who = who, key = key, row = row, snap = snap,
        reason = reason, at = work_clock(),
    }
    diag.count("ownership.enqueue_new")
    diag.count("core_ownership.warm_queued")
    return true, "new"
end

--- Semantic key currently on the job snap. Character identity stays on
--- job.who; it is not prefixed into this string.
function M.warm_job_current_key(job)
    if type(job) ~= "table" then return "" end
    return M.snapshot_cache_key(job.snap)
end

--- True when the queued/active job's stored key no longer matches the snap.
--- Same-format comparison: both sides are snapshot_cache_key, never who|key.
function M.warm_job_is_stale(job)
    if type(job) ~= "table" then return true end
    local current = M.warm_job_current_key(job)
    if current == "" then return true end
    return current ~= tostring(job.key or "")
end

-- Spell-state token for a snapshot. The ownership cache key is gear-only on
-- purpose (a spell refresh must not force a full gear re-warm), so each index
-- remembers the spell state it was built from; when only spells changed the
-- known_spells maps are rebuilt alone (no gear walk). spells_sig when present,
-- else the spells/spell_ids table identities.
local function spell_token(snap)
    if type(snap) ~= "table" then return "" end
    local sig = snap.spells_sig
    if sig ~= nil and tostring(sig) ~= "" then return "sig:" .. tostring(sig) end
    return "ref:" .. tostring(snap.spells) .. "/" .. tostring(snap.spell_ids)
end

local fill_spells -- forward

local function with_current_spells(idx, snap)
    if type(idx) ~= "table" or type(snap) ~= "table" then return idx, false end
    local tok = spell_token(snap)
    if idx._spell_token == tok then return idx, false end
    local out = { by_id = idx.by_id, by_name = idx.by_name, known_spells = {}, known_spell_ids = {} }
    fill_spells(out, snap)
    out._spell_token = tok
    fingerprint_stats.spell_refreshes = (fingerprint_stats.spell_refreshes or 0) + 1
    return out, true
end

function M.build_snapshot_index(snap)
    if not snap then return new_index() end
    local idx = new_index()
    for _, rec in ipairs(all_items(snap)) do add_record(idx, rec) end
    for _, rec in ipairs(all_augments(snap)) do add_record(idx, rec) end
    fill_spells(idx, snap)
    idx._spell_token = spell_token(snap)
    return idx
end

fill_spells = function(idx, snap)
    local known = idx.known_spells
    local spells = snap.spells
    if type(spells) == "table" then
        for key, rec in pairs(spells) do
            if type(rec) == "table" then
                if (rec.book == true) or ((tonumber(rec.book) or 0) > 0) then
                    local n = norm(rec.name or key)
                    if n ~= "" then known[n] = true end
                    local id = tonumber(rec.id or rec.spell_id or rec.spellId)
                    if id and id > 0 then idx.known_spell_ids[id] = true end
                end
            elseif rec == true then
                local n = norm(key)
                if n ~= "" then known[n] = true end
            end
        end
    end
    if type(snap.spell_ids) == "table" then
        for id, v in pairs(snap.spell_ids) do
            if v then
                local n = tonumber(id)
                if n and n > 0 then idx.known_spell_ids[n] = true end
            end
        end
    end
    return idx
end

--- Build only the ownership records that can satisfy the supplied canonical
--- candidates. This scans one snapshot once and never publishes a full cache.
function M.targeted_snapshot_index(snap, candidates)
    local idx = new_index()
    if type(snap) ~= "table" then return idx end
    local wanted_ids, wanted_names = {}, {}
    local wanted_spell_ids, wanted_spells = {}, {}
    local function collect(entry)
        entry = type(entry) == "table" and entry or {}
        local id = tonumber(entry.id)
        if id and id > 0 then wanted_ids[id] = true end
        for _, value in ipairs(entry.ids or {}) do
            id = tonumber(value)
            if id and id > 0 then wanted_ids[id] = true end
        end
        local function add_name(value)
            local key = M.norm_item_name(value)
            if key ~= "" then wanted_names[key] = true end
        end
        add_name(entry.item)
        for _, value in ipairs(entry.names or {}) do add_name(value) end
        local function add_spell(value)
            local key = norm(value)
            if key ~= "" then wanted_spells[key] = true end
        end
        add_spell(entry.spell)
        for _, value in ipairs(entry.spells or {}) do add_spell(value) end
        for _, value in ipairs(entry.spell_ids or {}) do
            id = tonumber(value)
            if id and id > 0 then wanted_spell_ids[id] = true end
        end
    end
    for _, candidate in ipairs(candidates or {}) do
        collect(candidate.satisfy or candidate.entry)
    end

    local function wanted_item(item)
        if type(item) ~= "table" then return false end
        local id = tonumber(item.id)
        if id and id > 0 and wanted_ids[id] then return true end
        local key = M.norm_item_name(item.name)
        if key ~= "" and wanted_names[key] then return true end
        for _, alias in ipairs(M.fungal_aliases(item.name)) do
            if wanted_names[M.norm_item_name(alias)] then return true end
        end
        return false
    end
    local function visit(bucket, status)
        for _, item in ipairs(bucket or {}) do
            if wanted_item(item) then add_record(idx, { item = item, status = status }) end
            for _, aug in ipairs(type(item) == "table" and item.augs or {}) do
                if not aug.empty and wanted_item(aug) then
                    add_host_augments(idx, {
                        name = item.name,
                        location = item.location,
                        where = item.where,
                        slotname = item.slotname,
                        augs = { aug },
                    }, status)
                end
            end
        end
    end
    visit(snap.equipped, "equipped")
    visit(snap.bags, "carried")
    visit(snap.bank, "carried")

    for key, rec in pairs(type(snap.spells) == "table" and snap.spells or {}) do
        if type(rec) == "table" and ((rec.book == true) or ((tonumber(rec.book) or 0) > 0)) then
            local spell_key = norm(rec.name or key)
            local spell_id = tonumber(rec.id or rec.spell_id or rec.spellId)
            if wanted_spells[spell_key] then idx.known_spells[spell_key] = true end
            if spell_id and wanted_spell_ids[spell_id] then idx.known_spell_ids[spell_id] = true end
        elseif rec == true then
            local spell_key = norm(key)
            if wanted_spells[spell_key] then idx.known_spells[spell_key] = true end
        end
    end
    for id, value in pairs(type(snap.spell_ids) == "table" and snap.spell_ids or {}) do
        id = tonumber(id)
        if value and id and wanted_spell_ids[id] then idx.known_spell_ids[id] = true end
    end
    return idx
end

function M.is_snapshot_index_cached(snap)
    if type(snap) ~= "table" then return false, "" end
    local cache_key = M.snapshot_cache_key(snap)
    if snap._bis_index_key == cache_key and snap._bis_index ~= nil then
        return true, cache_key
    end
    return published_index(cache_key) ~= nil, cache_key
end

function M.invalidate_snapshot_index(snap)
    if type(snap) ~= "table" then return end
    snap._bis_index = nil
    snap._bis_index_key = nil
    snap._bis_index_warm_job = nil
end

function M.empty_snapshot_index()
    return new_index()
end

--- Peek only. Never walks the snapshot or writes cache. [TG] emit uses this.
function M.peek_snapshot_index(snap)
    if type(snap) ~= "table" then
        return nil, { cache = "miss", key = "" }
    end
    local cache_key = M.snapshot_cache_key(snap)
    if snap._bis_index_key == cache_key and snap._bis_index then
        return snap._bis_index, { cache = "hit", key = cache_key }
    end
    local published = published_index(cache_key)
    if published then
        return published, { cache = "hit", key = cache_key, source = "published" }
    end
    return nil, { cache = "miss", key = cache_key }
end

function M.cached_snapshot_index(snap)
    if not snap then
        return M.build_snapshot_index(nil), { cache = "miss", key = "" }
    end
    local cache_key = M.snapshot_cache_key(snap)
    if snap._bis_index_key == cache_key and snap._bis_index then
        local current, refreshed = with_current_spells(snap._bis_index, snap)
        if refreshed then
            snap._bis_index = current
            publish_index(cache_key, current)
        end
        return current, { cache = "hit", key = cache_key, spells_refreshed = refreshed or nil }
    end
    local published = published_index(cache_key)
    if published then
        local current, refreshed = with_current_spells(published, snap)
        if refreshed then publish_index(cache_key, current) end
        snap._bis_index_key = cache_key
        snap._bis_index = current
        snap._bis_index_warm_job = nil
        return current, { cache = "hit", key = cache_key, source = "published", spells_refreshed = refreshed or nil }
    end
    local idx = M.build_snapshot_index(snap)
    snap._bis_index_key = cache_key
    snap._bis_index = idx
    snap._bis_index_warm_job = nil
    publish_index(cache_key, idx)
    return idx, { cache = "miss", key = cache_key }
end

local warm_sections = {
    { name = "equipped", status = "equipped" },
    { name = "bags", status = "carried" },
    { name = "bank", status = "carried" },
}

function M.begin_snapshot_warm(snap, clock_fn)
    if type(snap) ~= "table" then return nil, { done = true, reason = "no-snap" } end
    local cached, cache_key = M.is_snapshot_index_cached(snap)
    if cached then return nil, { done = true, cache = "hit", key = cache_key } end
    local job = snap._bis_index_warm_job
    if type(job) == "table" and job.key == cache_key then
        return job, { cache = "warming", key = cache_key }
    end
    if type(job) == "table" and job.key ~= cache_key then
        snap._bis_index_warm_job = nil
        return nil, { stale = true, key = job.key, current_key = cache_key }
    end
    local clock = type(clock_fn) == "function" and clock_fn or work_clock
    job = {
        snap = snap,
        key = cache_key,
        idx = new_index(),
        phase = "items",
        section_i = 1,
        item_i = 1,
        spell_key = nil,
        spell_id_key = nil,
        units = 0,
        started = clock(),
    }
    snap._bis_index_warm_job = job
    return job, { cache = "miss", key = cache_key }
end

local function warm_step_items(job)
    local spec = warm_sections[job.section_i]
    if not spec then
        job.phase = "spells"
        job.spell_key = nil
        return true
    end
    local bucket = job.snap and job.snap[spec.name] or {}
    if job.item_i > #bucket then
        job.section_i = job.section_i + 1
        job.item_i = 1
        return true
    end
    local it = bucket[job.item_i]
    job.item_i = job.item_i + 1
    add_record(job.idx, { item = it, status = spec.status })
    add_host_augments(job.idx, it, spec.status)
    return true
end

local function warm_step_spells(job)
    local idx = job.idx
    local spells = job.snap and job.snap.spells
    if type(spells) == "table" then
        local key, rec = next(spells, job.spell_key)
        if key ~= nil then
            job.spell_key = key
            if type(rec) == "table" then
                if (rec.book == true) or ((tonumber(rec.book) or 0) > 0) then
                    local n = norm(rec.name or key)
                    if n ~= "" then idx.known_spells[n] = true end
                    local id = tonumber(rec.id or rec.spell_id or rec.spellId)
                    if id and id > 0 then idx.known_spell_ids[id] = true end
                end
            elseif rec == true then
                local n = norm(key)
                if n ~= "" then idx.known_spells[n] = true end
            end
            return true
        end
    end
    job.phase = "spell_ids"
    job.spell_id_key = nil
    return true
end

local function warm_step_spell_ids(job)
    local idx = job.idx
    local spell_ids = job.snap and job.snap.spell_ids
    if type(spell_ids) == "table" then
        local key, value = next(spell_ids, job.spell_id_key)
        if key ~= nil then
            job.spell_id_key = key
            if value then
                local n = tonumber(key)
                if n and n > 0 then idx.known_spell_ids[n] = true end
            end
            return true
        end
    end
    job.phase = "done"
    return true
end

function M.tick_snapshot_warm(snap, budget_ms, max_units, clock_fn)
    local diag = require('diagnostics')
    local clock = type(clock_fn) == "function" and clock_fn or work_clock
    local call_t0 = clock()
    local job, meta = M.begin_snapshot_warm(snap, clock)
    if not job then
        meta = meta or { done = true }
        meta.call_ms = math.max(0, (clock() - call_t0) * 1000)
        diag.sample("ownership.warm_call_ms", meta.call_ms)
        if meta.stale == true then return false, meta end
        return true, meta
    end
    if M.snapshot_cache_key(snap) ~= job.key then
        snap._bis_index_warm_job = nil
        local call_ms = math.max(0, (clock() - call_t0) * 1000)
        diag.sample("ownership.warm_call_ms", call_ms)
        return false, { stale = true, key = job.key, call_ms = call_ms }
    end
    local t0 = clock()
    local budget = math.max(0.01, tonumber(budget_ms) or 2)
    local deadline = t0 + (budget / 1000)
    -- Production is limited by measured elapsed time, not a record count.
    -- The optional max_units remains only as a deterministic test hook.
    max_units = tonumber(max_units)
    if max_units ~= nil then max_units = math.max(1, math.floor(max_units)) end
    local units = 0
    local max_unit_ms = 0
    while (max_units == nil or units < max_units) and clock() < deadline do
        local phase = job.phase
        local unit_t0 = clock()
        if phase == "items" then
            warm_step_items(job)
        elseif phase == "spells" then
            warm_step_spells(job)
        elseif phase == "spell_ids" then
            warm_step_spell_ids(job)
        elseif phase == "done" then
            -- Publish only when the replacement index is complete.
            job.idx._spell_token = spell_token(job.snap or snap)
            snap._bis_index_key = job.key
            snap._bis_index = job.idx
            snap._bis_index_warm_job = nil
            publish_index(job.key, job.idx)
            local finalize_ms = math.max(0, (clock() - unit_t0) * 1000)
            diag.sample("ownership.unit.finalize", finalize_ms)
            diag.sample("ownership.warm_tick_units", units)
            diag.sample("ownership.warm_tick_ms", math.max(0, (clock() - t0) * 1000))
            diag.sample("ownership.max_unit_ms", math.max(max_unit_ms, finalize_ms))
            local call_ms = math.max(0, (clock() - call_t0) * 1000)
            diag.sample("ownership.warm_call_ms", call_ms)
            return true, {
                completed = true,
                key = job.key,
                units = job.units,
                tick_units = units,
                tick_ms = math.max(0, (clock() - t0) * 1000),
                max_unit_ms = math.max(max_unit_ms, finalize_ms),
                elapsed_ms = (clock() - (tonumber(job.started) or t0)) * 1000,
                call_ms = call_ms,
            }
        else
            job.phase = "done"
        end
        local unit_ms = math.max(0, (clock() - unit_t0) * 1000)
        if unit_ms > max_unit_ms then max_unit_ms = unit_ms end
        if phase == "items" then
            diag.sample("ownership.unit.items", unit_ms)
        elseif phase == "spells" or phase == "spell_ids" then
            diag.sample("ownership.unit.spells", unit_ms)
        end
        units = units + 1
        job.units = (tonumber(job.units) or 0) + 1
        -- One atomic unit may overrun the nominal slice. Do not start another
        -- after that happens; expose the overrun through max_unit/tick metrics.
        if clock() >= deadline then break end
    end
    local tick_ms = math.max(0, (clock() - t0) * 1000)
    local yielded = clock() >= deadline
    diag.sample("ownership.warm_tick_units", units)
    diag.sample("ownership.warm_tick_ms", tick_ms)
    diag.sample("ownership.max_unit_ms", max_unit_ms)
    local call_ms = math.max(0, (clock() - call_t0) * 1000)
    diag.sample("ownership.warm_call_ms", call_ms)
    if yielded then diag.count("ownership.warm_budget_yield") end
    return false, {
        warming = true,
        key = job.key,
        phase = job.phase,
        units = units,
        tick_units = units,
        tick_ms = tick_ms,
        max_unit_ms = max_unit_ms,
        budget_yield = yielded,
        total_units = job.units,
        elapsed_ms = (clock() - (tonumber(job.started) or t0)) * 1000,
        call_ms = call_ms,
    }
end

function M.entry_status(entry, ownership)
    ownership = type(ownership) == "table" and ownership or {}
    entry = type(entry) == "table" and entry or {}
    for _, id in ipairs(entry.ids or {}) do
        local rec = ownership.by_id and ownership.by_id[tonumber(id)]
        if rec then return rec.item, rec.status or "carried" end
    end
    for _, name in ipairs(entry.names or { entry.item }) do
        if not M.name_is_id_only(name) then
            local rec = ownership.by_name and ownership.by_name[M.norm_item_name(name)]
            if rec then return rec.item, rec.status or "carried" end
        end
    end
    return nil, "missing"
end

return M
