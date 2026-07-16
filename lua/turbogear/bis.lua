-- TurboGear/bis.lua
-- Saved BiS/checklist model plus have/need matching against TurboGear snapshots.
-- This is a pure Store/snapshot consumer: no actor or broadcast behavior lives here.

local mq  = require('mq')
local cfg = require('config')
local Settings = cfg.Settings

local M = {}

local manifest_file = string.format("%s/%s_bis_manifest.lua", mq.configDir, cfg.CFG.script_name)
local lists, order = {}, {}
local loaded = false

local function trim(s)
    return tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function norm(s)
    s = trim(s):lower()
    -- EQ / Lucy often use backtick or curly quotes in names like Adventurer's.
    s = s:gsub("`", "'"):gsub("\226\128\152", "'"):gsub("\226\128\153", "'")
    return s
end

-- Rank suffixes on Adventurer's Tattered Sack must stay distinct. Stripping
-- trailing "(Reinforced)" / "(Celestial)" collapsed every rank to the base
-- name, so ID chains and material clear-when-owned could not work reliably.
local function keep_tattered_sack_rank_paren(s)
    return s:find("tattered sack", 1, true) ~= nil
end

-- norm_item_name runs 3-4 regex gsubs per call and is invoked per alias name
-- per entry per evaluation - tens of thousands of times per needs-index
-- rebuild on fungal/Jonas-expanded entries. The vocabulary of names is small
-- and stable, so memoize per input string.
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

local function norm_item_name(s)
    if type(s) ~= "string" then return norm_item_name_uncached(s) end
    local hit = norm_name_cache[s]
    if hit == nil then
        hit = norm_item_name_uncached(s)
        norm_name_cache[s] = hit
    end
    return hit
end

local function tier_rank(name)
    name = tostring(name or ""):lower()
    if name:find("- final", 1, true) then return 4 end
    if name:find("- tier iii", 1, true) then return 3 end
    if name:find("- tier ii", 1, true) then return 2 end
    if name:find("- tier i", 1, true) then return 1 end
    return nil
end

local function fungal_aliases(name)
    local aliases, n = {}, tostring(name or "")
    local rank = tier_rank(n)

    local elem = n:match("^%s*(%S+)%s+Fungus of Suffering%s*%-")
        or n:match("^%s*(%S+)%s+Fungus of Suffering%s*$")
    if elem then
        rank = rank or 4
        aliases[#aliases+1] = elem .. " Slime of Suffering"
        for i = 1, rank do
            local suffix = i == 4 and "Final" or ("Tier " .. ({ "I", "II", "III" })[i])
            aliases[#aliases+1] = elem .. " Fungus of Suffering - " .. suffix
        end
        return aliases
    end

    local bloom = n:match("^%s*Fungal Bloom of (.-)%s*%-")
        or n:match("^%s*Fungal Bloom of (.-)%s*$")
    if bloom and bloom ~= "" then
        rank = rank or 4
        aliases[#aliases+1] = "Noxious Bloom of " .. bloom
        for i = 1, rank do
            local suffix = i == 4 and "Final" or ("Tier " .. ({ "I", "II", "III" })[i])
            aliases[#aliases+1] = "Fungal Bloom of " .. bloom .. " - " .. suffix
        end
    end
    return aliases
end

local function safe_id(name)
    local s = norm(name):gsub("[^%w]+", "_"):gsub("^_+", ""):gsub("_+$", "")
    if s == "" then s = "list" end
    return s:sub(1, 48)
end

local function list_file(id)
    return string.format("%s/%s_bis_%s.lua", mq.configDir, cfg.CFG.script_name, safe_id(id))
end

local function contains_order(id)
    for _, v in ipairs(order) do if v == id then return true end end
    return false
end

local function add_order(id)
    if id and id ~= "" and not contains_order(id) then
        order[#order+1] = id
        table.sort(order, function(a, b)
            local la, lb = lists[a], lists[b]
            return tostring((la and la.name) or a):lower() < tostring((lb and lb.name) or b):lower()
        end)
    end
end

local function save_manifest()
    pcall(function() mq.pickle(manifest_file, order) end)
end

local function normalize_ids(ids)
    local out, seen = {}, {}
    if type(ids) == "table" then
        for _, id in ipairs(ids) do
            local n = tonumber(id)
            if n and n > 0 and not seen[n] then
                seen[n] = true
                out[#out+1] = n
            end
        end
    end
    table.sort(out)
    return out
end

local function normalize_names(names, primary)
    local out, seen = {}, {}
    local function add(v)
        v = trim(v)
        local k = norm(v)
        if v ~= "" and not seen[k] then
            seen[k] = true
            out[#out+1] = v
        end
    end
    add(primary)
    if type(names) == "table" then
        for _, v in ipairs(names) do add(v) end
    elseif type(names) == "string" then
        add(names)
    end
    return out
end

function M.normalize_entry(e)
    if type(e) ~= "table" then e = { item = tostring(e or "") } end
    local item = trim(e.item or e.name or "")
    local spells = nil
    if type(e.spells) == "table" then
        spells = {}
        for _, s in ipairs(e.spells) do
            s = trim(s)
            if s ~= "" then spells[#spells + 1] = s end
        end
        if #spells == 0 then spells = nil end
    end
    local spell = trim(e.spell or "")
    if spell == "" and spells then spell = spells[1] end
    if spell == "" then spell = nil end
    if not spells and spell then spells = { spell } end
    return {
        item = item,
        names = normalize_names(e.names, item),
        ids = normalize_ids(e.ids),
        slot = trim(e.slot or ""),
        group = trim(e.group or ""),
        socket = tonumber(e.socket) and math.floor(tonumber(e.socket)) or nil,
        notes = e.notes,
        spell = spell,
        spells = spells,
    }
end

local function normalize_list(list)
    list = type(list) == "table" and list or {}
    list.name = trim(list.name)
    if list.name == "" then list.name = "Untitled BiS List" end
    list.id = safe_id(list.id or list.name)
    list.owner = trim(list.owner or "")
    list.server = trim(list.server or "")
    list.class = trim(list.class or "")
    list.updated = tonumber(list.updated) or os.time()
    local entries = {}
    for _, e in ipairs(list.entries or {}) do
        local ne = M.normalize_entry(e)
        if ne.item ~= "" then entries[#entries+1] = ne end
    end
    list.entries = entries
    return list
end

function M.load_all(force)
    if loaded and not force then return end
    lists, order = {}, {}
    local ok, manifest = pcall(dofile, manifest_file)
    if ok and type(manifest) == "table" then
        for _, id in ipairs(manifest) do
            local lok, list = pcall(dofile, list_file(id))
            if lok and type(list) == "table" then
                list = normalize_list(list)
                lists[list.id] = list
                add_order(list.id)
            end
        end
    end
    loaded = true
end

function M.save_list(list)
    M.load_all()
    list = normalize_list(list)
    lists[list.id] = list
    add_order(list.id)
    pcall(function() mq.pickle(list_file(list.id), list) end)
    save_manifest()
    pcall(function() require('loadout').invalidate(list.id) end)
    return list
end

local function resolve_item_name_from_ids(ids)
    for _, raw in ipairs(ids or {}) do
        local id = tonumber(raw)
        if id and id > 0 then
            local ok, name = pcall(function()
                local fi = mq.TLO.FindItem and mq.TLO.FindItem(id)
                if fi and fi() then return fi.Name() or "" end
                local it = mq.TLO.Item and mq.TLO.Item(id)
                if it and it() then return it.Name() or "" end
                return ""
            end)
            name = ok and trim(name) or ""
            if name ~= "" then return name end
        end
    end
    return ""
end

function M.add_entry(list_id, entry)
    M.load_all()
    local list = M.get(list_id)
    if not list then return nil, "List not found: " .. tostring(list_id) end
    local ne = M.normalize_entry(entry)
    if ne.item == "" and #(ne.ids or {}) > 0 then
        ne.item = resolve_item_name_from_ids(ne.ids)
    end
    if ne.item == "" then return nil, "Item name or valid item ID is required." end
    list.entries[#list.entries + 1] = ne
    list.updated = os.time()
    return M.save_list(list)
end

function M.remove_entry_at(list_id, index)
    M.load_all()
    local list = M.get(list_id)
    if not list then return nil, "List not found: " .. tostring(list_id) end
    index = tonumber(index)
    if not index or index < 1 or index > #(list.entries or {}) then
        return nil, "Invalid entry index."
    end
    table.remove(list.entries, index)
    list.updated = os.time()
    return M.save_list(list)
end

function M.update_entry_at(list_id, index, patch)
    M.load_all()
    local list = M.get(list_id)
    if not list then return nil, "List not found: " .. tostring(list_id) end
    index = tonumber(index)
    if not index or index < 1 or index > #(list.entries or {}) then
        return nil, "Invalid entry index."
    end
    patch = type(patch) == "table" and patch or {}
    local entry = M.normalize_entry(list.entries[index])
    for _, key in ipairs({ "item", "slot", "group", "notes" }) do
        if patch[key] ~= nil then entry[key] = trim(patch[key]) end
    end
    if patch.names ~= nil then entry.names = normalize_names(patch.names, entry.item) end
    if patch.ids ~= nil then entry.ids = normalize_ids(patch.ids) end
    if patch.socket ~= nil then
        local socket = tonumber(patch.socket)
        entry.socket = (socket and socket >= 1 and socket <= 6) and math.floor(socket) or nil
    end
    list.entries[index] = entry
    list.updated = os.time()
    return M.save_list(list)
end

function M.remove_list(id)
    M.load_all()
    if not id or id == "" then return false, "No list id given." end
    id = safe_id(id)
    if not lists[id] then return false, "List not found: " .. tostring(id) end
    lists[id] = nil
    for i = #order, 1, -1 do
        if order[i] == id then table.remove(order, i) end
    end
    save_manifest()
    pcall(os.remove, list_file(id))
    if Settings.bisSelectedList == id then Settings.bisSelectedList = "" end
    return true
end

function M.list_names()
    M.load_all()
    local out = {}
    for _, id in ipairs(order) do
        local list = lists[id]
        if list then out[#out+1] = { id = id, name = list.name, list = list } end
    end
    return out
end

function M.get(id)
    M.load_all()
    if not id or id == "" then return nil end
    id = safe_id(id)
    return lists[id]
end

function M.default_list_for_snap(snap)
    M.load_all()
    local chosen = M.get(Settings.bisSelectedList)
    if chosen then return chosen end
    local cname = norm(snap and snap.name)
    local cclass = norm(snap and snap.class)
    for _, id in ipairs(order) do
        local list = lists[id]
        if list and norm(list.owner) == cname and cname ~= "" then return list end
    end
    for _, id in ipairs(order) do
        local list = lists[id]
        if list and norm(list.class) == cclass and cclass ~= "" then return list end
    end
    return lists[order[1]]
end

function M.snapshot_to_list(snap, name)
    if not snap then return nil, "No source snapshot is available." end
    local entries = {}
    for _, it in ipairs(snap.equipped or {}) do
        if it.name and it.name ~= "" and it.name ~= "?" then
            entries[#entries+1] = {
                item = it.name,
                names = { it.name },
                ids = (tonumber(it.id) and tonumber(it.id) > 0) and { tonumber(it.id) } or {},
                slot = it.slotname or it.where or "",
                group = "Worn",
            }
        end
    end
    if #entries == 0 then return nil, "No worn items found on this source." end
    local list_name = trim(name)
    if list_name == "" then list_name = string.format("%s Worn", snap.name or "Character") end
    return normalize_list({
        name = list_name,
        owner = snap.name or "",
        server = snap.server or "",
        class = snap.class or "",
        updated = os.time(),
        entries = entries,
    })
end

local function all_items(snap)
    local out = {}
    for _, spec in ipairs({
        { bucket = snap and snap.equipped or {}, status = "equipped" },
        { bucket = snap and snap.bags or {},     status = "carried"  },
        { bucket = snap and snap.bank or {},     status = "carried"  },
    }) do
        for _, it in ipairs(spec.bucket) do
            out[#out+1] = { item = it, status = spec.status }
        end
    end
    return out
end

local function all_augments(snap)
    local out = {}
    for _, spec in ipairs({
        { bucket = snap and snap.equipped or {}, status = "equipped" },
        { bucket = snap and snap.bags or {},     status = "carried"  },
        { bucket = snap and snap.bank or {},     status = "carried"  },
    }) do
        for _, host in ipairs(spec.bucket) do
            for _, aug in ipairs(host.augs or {}) do
                if not aug.empty and aug.name and aug.name ~= "" and aug.name ~= "Empty" then
                    out[#out+1] = {
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

local function snapshot_index(snap)
    if not snap then return { by_id = {}, by_name = {} } end
    local cache_key = table.concat({
        tostring(snap.server or ""),
        tostring(snap.name or ""),
        tostring(snap.inventoryUpdated or snap.updated or ""),
        tostring(#(snap.equipped or {})),
        tostring(#(snap.bags or {})),
        tostring(#(snap.bank or {})),
    }, "|")
    if snap._bis_index_key == cache_key and snap._bis_index then return snap._bis_index end

    local idx = { by_id = {}, by_name = {} }
    local function add_rec(rec)
        local it = rec.item
        local iid = tonumber(it and it.id)
        if iid and iid > 0 then
            idx.by_id[iid] = better_match(idx.by_id[iid], rec)
        end
        local n = norm_item_name(it and it.name)
        if n ~= "" then
            idx.by_name[n] = better_match(idx.by_name[n], rec)
            for _, alias in ipairs(fungal_aliases(it and it.name)) do
                local an = norm_item_name(alias)
                if an ~= "" then idx.by_name[an] = better_match(idx.by_name[an], rec) end
            end
        end
    end
    for _, rec in ipairs(all_items(snap)) do add_rec(rec) end
    for _, rec in ipairs(all_augments(snap)) do add_rec(rec) end
    snap._bis_index_key = cache_key
    snap._bis_index = idx
    return idx
end

local function entry_matches_item(entry, it)
    if not entry or not it then return false end
    local item_name = norm_item_name(it.name)
    if item_name ~= "" then
        for _, name in ipairs(entry.names or { entry.item }) do
            if norm_item_name(name) == item_name then return true end
        end
    end
    local iid = tonumber(it.id)
    if iid and iid > 0 then
        for _, id in ipairs(entry.ids or {}) do if tonumber(id) == iid then return true end end
    end
    return false
end

-- LazBiS-style live ownership check (FindItem scans worn, bags, and bank).
-- BOUNDED by design: this confirm exists to catch an item looted SECONDS ago
-- (snapshot lag) - and that item is by definition the linked/looted one, so
-- checking the entry ids + the linked name + the canonical entry name is
-- semantically complete. Iterating every alias name (80+ on expanded
-- fungal/Jonas entries) ran hundreds of FindItem/FindItemBank scans per call
-- and froze the game for 29-39s when chat hit a warm-up fallback scan.
function M.live_own_item(entry, item_name, item_id)
    local function find_count(id)
        id = tonumber(id)
        if not id or id <= 0 then return 0 end
        local ok, cnt = pcall(function()
            local fi = mq.TLO.FindItem and mq.TLO.FindItem(id)
            if fi and fi() then return tonumber(fi.Count()) or 0 end
            return 0
        end)
        return ok and cnt or 0
    end

    local function find_count_name(name)
        name = trim(name)
        if name == "" then return 0 end
        local ok, cnt = pcall(function()
            local fi = mq.TLO.FindItem and mq.TLO.FindItem("=" .. name)
            if fi and fi() then return tonumber(fi.Count()) or 0 end
            return 0
        end)
        return ok and cnt or 0
    end

    entry = entry and M.normalize_entry(entry) or {}
    for _, id in ipairs(entry.ids or {}) do
        if find_count(id) > 0 then return true end
    end
    item_id = tonumber(item_id) or 0
    if item_id > 0 and find_count(item_id) > 0 then return true end
    item_name = trim(item_name)
    if item_name ~= "" and find_count_name(item_name) > 0 then return true end
    local canonical = trim(entry.item)
    if canonical ~= "" and canonical ~= item_name and find_count_name(canonical) > 0 then
        return true
    end
    return false
end

local live_fallback_cache = {}
local LIVE_FALLBACK_TTL = 2.0

local function live_fallback_key(entry)
    entry = M.normalize_entry(entry)
    return norm_item_name(entry.item)
end

local function live_own_cached(entry)
    local key = live_fallback_key(entry)
    local now = os.clock()
    local hit = live_fallback_cache[key]
    if hit and (now - hit.at) <= LIVE_FALLBACK_TTL then
        return hit.owned
    end
    local owned = M.live_own_item(entry, entry.item, nil)
    live_fallback_cache[key] = { owned = owned, at = now }
    return owned
end

-- Read-only normalized-entry memo for the match/evaluate hot paths. Catalog
-- entries are stable shared tables evaluated thousands of times per index
-- rebuild; normalize_entry deep-copies names/ids each call (50+ aliases on
-- expanded entries). Cached results are treated as IMMUTABLE - list-editing
-- paths keep calling M.normalize_entry directly for fresh copies.
local normalize_ro_cache = setmetatable({}, { __mode = "k" })

local function normalize_entry_ro(e)
    if type(e) ~= "table" then return M.normalize_entry(e) end
    local hit = normalize_ro_cache[e]
    if hit == nil then
        hit = M.normalize_entry(e)
        normalize_ro_cache[e] = hit
        -- An already-normalized entry normalizes to itself semantically; cache
        -- the RESULT under its own key too so repeat lookups short-circuit.
        normalize_ro_cache[hit] = hit
    end
    return hit
end

local function entry_spell_list(entry)
    if type(entry) ~= "table" then return nil end
    if type(entry.spells) == "table" and #entry.spells > 0 then return entry.spells end
    local spell = trim(entry.spell or "")
    if spell ~= "" then return { spell } end
    return nil
end

local function snap_knows_spell(snap, spell_name)
    spell_name = trim(spell_name)
    if spell_name == "" then return false end
    local spells = snap and snap.spells
    if type(spells) ~= "table" then return false end
    local want = norm(spell_name)
    local row = spells[want]
    if type(row) == "table" and ((row.book == true) or (tonumber(row.book) or 0) > 0) then
        return true
    end
    for key, rec in pairs(spells) do
        if type(rec) == "table" then
            local n = norm(rec.name or key)
            if n == want and ((rec.book == true) or (tonumber(rec.book) or 0) > 0) then
                return true
            end
        end
    end
    return false
end

local function entry_spells_known_in_snap(entry, snap)
    local list = entry_spell_list(entry)
    if not list then return false end
    for _, spell in ipairs(list) do
        if not snap_knows_spell(snap, spell) then return false end
    end
    return true
end

local function live_spells_known(entry)
    local list = entry_spell_list(entry)
    if not list then return false end
    for _, spell in ipairs(list) do
        local known = false
        pcall(function()
            if (mq.TLO.Me.Book(spell)() or 0) > 0 or (mq.TLO.Me.CombatAbility(spell)() or 0) > 0 then
                known = true
            end
        end)
        if not known then return false end
    end
    return true
end

local function match_entry(entry, snap)
    entry = normalize_entry_ro(entry)
    local idx = snapshot_index(snap)
    for _, id in ipairs(entry.ids or {}) do
        local rec = idx.by_id[tonumber(id)]
        if rec then return rec.item, rec.status, entry end
    end
    for _, name in ipairs(entry.names or { entry.item }) do
        local rec = idx.by_name[norm_item_name(name)]
        if rec then return rec.item, rec.status, entry end
    end
    -- Spell-aware packs: own the pack item OR know every listed spell/disc.
    -- Glyphs and normal gear omit spell metadata and stay item-only.
    if entry_spells_known_in_snap(entry, snap) then
        return entry.item, "known", entry
    end
    return nil, "missing", entry
end

function M.evaluate(list, snap)
    list = type(list) == "table" and list or M.get(list)
    local rows = {}
    if not list then return rows end
    if not snap then
        for _, entry in ipairs(list.entries or {}) do
            entry = M.normalize_entry(entry)
            rows[#rows + 1] = { entry = entry, have = false, match = nil, status = "missing" }
        end
        return rows
    end
    for _, entry in ipairs(list.entries or {}) do
        local match, status
        match, status, entry = match_entry(entry, snap)
        rows[#rows+1] = { entry = entry, have = match ~= nil, match = match, status = status }
    end
    return rows
end

function M.evaluate_entry(entry, snap, opts)
    local match, status
    match, status, entry = match_entry(entry, snap or {})
    -- opts.skip_live: bulk callers (needs index builds) evaluate purely against
    -- the snapshot. The self-snapshot live FindItem fallback below scans the
    -- whole inventory+bank per missing entry - hundreds of entries per build
    -- made that a multi-second stall on the game thread. Announce paths still
    -- live-confirm individual hits at announce time.
    if match == nil and status == "missing" and not (opts and opts.skip_live) then
        local self_snap = snap and snap.name and snap.name == (mq.TLO.Me.CleanName() or "")
        if (opts and opts.live_fallback) or self_snap then
            if live_own_cached(entry) then
                return { entry = entry, have = true, match = nil, status = "carried" }
            end
            if live_spells_known(entry) then
                return { entry = entry, have = true, match = entry.item, status = "known" }
            end
        end
    end
    return { entry = entry, have = match ~= nil, match = match, status = status }
end

local function link_matches_entry(entry, item_name, item_id)
    if not entry then return false end
    local lname = norm(item_name)
    if lname ~= "" then
        for _, name in ipairs(entry.names or { entry.item }) do
            if norm_item_name(name) == norm_item_name(lname) then return true end
        end
    end
    local iid = tonumber(item_id)
    if iid and iid > 0 then
        for _, id in ipairs(entry.ids or {}) do if tonumber(id) == iid then return true end end
    end
    return false
end

M.link_matches_entry = link_matches_entry

local function applicable_lists_for_snap(snap)
    M.load_all()
    local out = {}
    if Settings.bisListMode == "user" then
        local selected = M.get(Settings.bisSelectedList)
        if selected then return { selected } end
    end
    local cname, cclass = norm(snap and snap.name), norm(snap and snap.class)
    for _, id in ipairs(order) do
        local list = lists[id]
        if list and ((cname ~= "" and norm(list.owner) == cname) or (cclass ~= "" and norm(list.class) == cclass)) then
            out[#out+1] = list
        end
    end
    return out
end

function M.find_link_need(snap, item_name, item_id)
    if not snap then return nil end
    for _, list in ipairs(applicable_lists_for_snap(snap)) do
        local rows = M.evaluate(list, snap)
        for _, row in ipairs(rows) do
            if row.status == "missing" and link_matches_entry(row.entry, item_name, item_id) then
                return { list = list, entry = row.entry }
            end
        end
    end
    return nil
end

function M.counts(rows)
    local equipped, carried, missing = 0, 0, 0
    for _, row in ipairs(rows or {}) do
        if not row.header and not row.empty then
            if row.status == "equipped" then equipped = equipped + 1
            elseif row.status == "carried" or row.status == "known" then carried = carried + 1
            else missing = missing + 1 end
        end
    end
    return equipped, carried, missing
end

M.manifest_file = manifest_file
return M
