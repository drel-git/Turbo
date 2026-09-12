-- TurboGear/bis.lua
-- Saved BiS/checklist model plus have/need matching against TurboGear snapshots.
-- This is a pure Store/snapshot consumer: no actor or broadcast behavior lives here.

local mq  = require('mq')
local cfg = require('config')
local CFG, Settings = cfg.CFG, cfg.Settings
local ownership_index = require('ownership_index')

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

local norm_item_name = ownership_index.norm_item_name

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
        -- Shared multi-ID names (Jonas "Skeletal Hand") never become match names.
        if v ~= "" and not seen[k] and not ownership_index.name_is_id_only(v) then
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

local FORSAKEN_SHADOWY_BY_SLOT = {
    Arms = "Ruined Shadowy Armguards",
    Chest = "Ruined Shadowy Chestguard",
    Feet = "Ruined Shadowy Boots",
    Hands = "Ruined Shadowy Gauntlets",
    Head = "Ruined Shadowy Helm",
    Legs = "Ruined Shadowy Leggings",
    Wrist = "Ruined Shadowy Bracer",
}

local function add_name_alias_once(names, alias)
    alias = trim(alias)
    if alias == "" then return end
    local key = norm(alias)
    for _, name in ipairs(names or {}) do
        if norm(name) == key then return end
    end
    names[#names + 1] = alias
end

local function forsaken_shadowy_alias_for_entry(entry)
    local alias = FORSAKEN_SHADOWY_BY_SLOT[trim(entry and entry.slot or "")]
    if not alias then return nil end
    local item = trim(entry and (entry.item or entry.name) or "")
    if item:match("^Forsaken%s+") then return alias end
    return nil
end

local function add_forsaken_shadowy_aliases(entry, names)
    -- Sebilis Forsaken class armor is completed from a Ruined Shadowy base
    -- piece. Treat either the finished class item or its base piece as owned.
    local alias = forsaken_shadowy_alias_for_entry(entry)
    if alias then add_name_alias_once(names, alias) end
end

local function forsaken_status_for_match(entry, matched_name, status)
    local alias = forsaken_shadowy_alias_for_entry(entry)
    if not alias then return status end
    local matched = norm_item_name(matched_name)
    if matched ~= "" and matched == norm_item_name(alias) then
        return "forsaken_base"
    end
    if matched ~= "" and matched == norm_item_name(entry and entry.item or "") then
        if status == "equipped" then return status end
        return "forsaken_complete"
    end
    return status
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
    local spell_ids = nil
    if type(e.spell_ids) == "table" then
        spell_ids = {}
        local seen = {}
        for _, raw in ipairs(e.spell_ids) do
            local id = tonumber(raw)
            if id and id > 0 and not seen[id] then
                seen[id] = true
                spell_ids[#spell_ids + 1] = id
            end
        end
        if #spell_ids == 0 then spell_ids = nil end
    end
    local names = normalize_names(e.names, item)
    add_forsaken_shadowy_aliases(e, names)
    return {
        item = item,
        names = names,
        ids = normalize_ids(e.ids),
        slot = trim(e.slot or ""),
        group = trim(e.group or ""),
        socket = tonumber(e.socket) and math.floor(tonumber(e.socket)) or nil,
        notes = e.notes,
        spell = spell,
        spells = spells,
        spell_ids = spell_ids,
        progression_id_match = e.progression_id_match == true,
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

local function snapshot_index(snap)
    local idx = ownership_index.cached_snapshot_index(snap)
    return idx
end

--- Prewarm ownership index (items + augs + known spells). Call once before
--- bulk needs-index evaluation so the first entry does not pay the full build.
function M.ensure_snapshot_index(snap)
    return snapshot_index(snap)
end

local function jonas_bare(name)
    name = norm_item_name(name)
    if name == "" then return "" end
    local prefix = "jonas dagmire's "
    if name:sub(1, #prefix) == prefix then
        return trim(name:sub(#prefix + 1))
    end
    return name
end

local function names_match_owned(a, b)
    a, b = norm_item_name(a), norm_item_name(b)
    if a == "" or b == "" then return false end
    if a == b then return true end
    local ca, cb = jonas_bare(a), jonas_bare(b)
    return ca ~= "" and ca == cb
end

local function entry_name_matches_actual(entry, actual_name)
    actual_name = tostring(actual_name or "")
    if trim(actual_name) == "" then return true end
    if entry and entry.progression_id_match == true then return true end
    local saw_named_target = false
    for _, name in ipairs(entry and (entry.names or { entry.item }) or {}) do
        if not ownership_index.name_is_id_only(name) and norm_item_name(name) ~= "" then
            saw_named_target = true
            if names_match_owned(actual_name, name) then return true end
        end
    end
    -- ID-only/custom rows have no reliable name contract to verify.
    return not saw_named_target
end

local function entry_matches_item(entry, it)
    if not entry or not it then return false end
    local item_name = norm_item_name(it.name)
    if item_name ~= "" then
        for _, name in ipairs(entry.names or { entry.item }) do
            if norm_item_name(name) == item_name and not ownership_index.name_is_id_only(name) then
                return true
            end
        end
    end
    local iid = tonumber(it.id)
    if iid and iid > 0 and entry_name_matches_actual(entry, it.name) then
        for _, id in ipairs(entry.ids or {}) do if tonumber(id) == iid then return true end end
    end
    return false
end

-- BiS-style live ownership check (FindItem + FindItemBank).
-- BOUNDED by design: this confirm exists to catch an item looted SECONDS ago
-- (snapshot lag) - and that item is by definition the linked/looted one, so
-- checking the entry ids + the linked name + the canonical entry name is
-- semantically complete. Iterating every alias name (80+ on expanded
-- fungal/Jonas entries) ran hundreds of FindItem/FindItemBank scans per call
-- and froze the game for 29-39s when chat hit a warm-up fallback scan.
local function find_item_tlo(id_or_name, bank)
    local function valid(fi)
        local ok, exists = pcall(function() return fi and fi() end)
        return ok and exists and true or false
    end
    -- Name queries: reject substring false-hits (e.g. FindItem("Arcane Demise")
    -- returning "Hideous Hex of Arcane Demise"). Norm match still allows
    -- "... (Augmented)" vs bare catalog names.
    local function fi_matches_query(fi, query)
        if type(query) == "number" then return true end
        local qname = tostring(query or ""):gsub("^%=", "")
        if trim(qname) == "" then return false end
        local actual = ""
        pcall(function() actual = tostring(fi.Name() or "") end)
        return names_match_owned(actual, qname)
    end
    local function lookup(query)
        local ok, fi = pcall(function()
            if bank then
                return mq.TLO.FindItemBank and mq.TLO.FindItemBank(query) or nil
            end
            return mq.TLO.FindItem and mq.TLO.FindItem(query) or nil
        end)
        if ok and valid(fi) and fi_matches_query(fi, query) then return fi end
        return nil
    end
    if type(id_or_name) == "number" then
        if (tonumber(id_or_name) or 0) <= 0 then return nil end
        return lookup(id_or_name)
    end
    local name = trim(id_or_name)
    if name == "" then return nil end
    local fi = lookup("=" .. name)
    if fi then return fi end
    -- Augmented gear often has Name() "... (Augmented)"; exact =base misses
    -- while local BiS ignores snap ownership → false red for worn gear.
    local low = name:lower()
    if not low:find("%(augmented%)%s*$") then
        fi = lookup("=" .. name .. " (Augmented)")
        if fi then return fi end
    end
    -- Partial match (same fallback as items.resolve_item_tlo), then confirm name.
    return lookup(name)
end

-- When FindItem-by-name fails, confirm the worn Inventory slot for this entry.
-- Strips (Augmented) via entry_matches_item / norm_item_name.
local function live_worn_slot_status(entry)
    local slot_label = trim(entry and entry.slot)
    if slot_label == "" then return nil end
    local ok_items, items = pcall(require, 'items')
    if not ok_items or not items or not items.slot_id_for_label then return nil end
    local slot_id = items.slot_id_for_label(slot_label)
    if slot_id == nil then return nil end
    local ok, it = pcall(function() return mq.TLO.Me.Inventory(slot_id) end)
    if not ok or not it then return nil end
    local exists = false
    pcall(function() exists = it() and true or false end)
    if not exists then return nil end
    local name, id = "", 0
    pcall(function() name = tostring(it.Name() or "") end)
    pcall(function() id = tonumber(it.ID()) or 0 end)
    if entry_matches_item(entry, { name = name, id = id }) then
        return "equipped"
    end
    return nil
end

local function live_status_from_fi(fi, bank)
    if not fi then return nil end
    if bank then return "carried" end
    local slot = nil
    pcall(function() slot = tonumber(fi.ItemSlot()) end)
    -- InvSlots 0-22 are worn; bag/bank pack slots are higher.
    if slot and slot >= 0 and slot <= 22 then return "equipped" end
    return "carried"
end

-- After zone, FindItemBank can fail while Store still holds a preserved bank.
local function owned_in_store_bank(entry, item_name, item_id)
    local bank = nil
    pcall(function()
        local store = require('store').Store
        local key = store and store.my_key and store.my_key() or nil
        local snap = key and store.get and store.get(key) or nil
        if type(snap) == "table" and type(snap.bank) == "table" and #snap.bank > 0 then
            bank = snap.bank
        end
    end)
    if not bank then return false end
    item_id = tonumber(item_id) or 0
    local ids = {}
    for _, id in ipairs(entry.ids or {}) do
        id = tonumber(id) or 0
        if id > 0 then ids[id] = true end
    end
    if item_id > 0 then ids[item_id] = true end
    local names = {}
    local function note_name(n)
        n = trim(n)
        if n ~= "" and not ownership_index.name_is_id_only(n) then names[#names + 1] = n end
    end
    note_name(item_name)
    note_name(entry.item)
    for _, n in ipairs(entry.names or {}) do note_name(n) end
    for _, it in ipairs(bank) do
        local bid = tonumber(it and it.id) or 0
        local bname = tostring(it and it.name or "")
        if bid > 0 and ids[bid] and entry_name_matches_actual(entry, bname) then return true end
        for _, n in ipairs(names) do
            if names_match_owned(bname, n) then return true end
        end
    end
    return false
end

--- Returns "equipped", "carried", or nil (not owned on this box).
function M.live_item_status(entry, item_name, item_id)
    entry = entry and M.normalize_entry(entry) or {}
    local function try(v, verify_name)
        local fi = find_item_tlo(v, false)
        if fi then
            local actual = ""
            pcall(function() actual = tostring(fi.Name() or "") end)
            if not verify_name or entry_name_matches_actual(entry, actual) then
                return live_status_from_fi(fi, false)
            end
        end
        fi = find_item_tlo(v, true)
        if fi then
            local actual = ""
            pcall(function() actual = tostring(fi.Name() or "") end)
            if not verify_name or entry_name_matches_actual(entry, actual) then
                return live_status_from_fi(fi, true)
            end
        end
        return nil
    end
    for _, id in ipairs(entry.ids or {}) do
        local st = try(tonumber(id) or 0, true)
        if st then return st end
    end
    item_id = tonumber(item_id) or 0
    if item_id > 0 then
        local st = try(item_id, true)
        if st then return st end
    end
    item_name = trim(item_name)
    if item_name ~= "" and not ownership_index.name_is_id_only(item_name) then
        local st = try(item_name)
        if st then return forsaken_status_for_match(entry, item_name, st) end
    end
    local canonical = trim(entry.item)
    if canonical ~= "" and canonical ~= item_name and not ownership_index.name_is_id_only(canonical) then
        local st = try(canonical)
        if st then return forsaken_status_for_match(entry, canonical, st) end
    end
    local shadowy_alias = forsaken_shadowy_alias_for_entry(entry)
    if shadowy_alias and not ownership_index.name_is_id_only(shadowy_alias) then
        local st = try(shadowy_alias)
        if st then return "forsaken_base" end
    end
    local worn = live_worn_slot_status(entry)
    if worn then return worn end
    if owned_in_store_bank(entry, item_name, item_id) then
        return "carried"
    end
    return nil
end

function M.live_own_item(entry, item_name, item_id)
    return M.live_item_status(entry, item_name, item_id) ~= nil
end

local live_fallback_cache = {}
local LIVE_FALLBACK_TTL = 0.4 -- snappy local BiS; short enough for equip/unequip
local live_ownership_gen = 0

local function live_fallback_key(entry)
    entry = M.normalize_entry(entry)
    return norm_item_name(entry.item)
end

local function live_status_cached(entry)
    local key = live_fallback_key(entry)
    local now = os.clock()
    local hit = live_fallback_cache[key]
    if hit and (now - hit.at) <= LIVE_FALLBACK_TTL then
        return hit.status
    end
    local status = M.live_item_status(entry, entry.item, nil)
    live_fallback_cache[key] = { status = status, at = now }
    return status
end

local function live_own_cached(entry)
    return live_status_cached(entry) ~= nil
end

function M.invalidate_live_ownership_cache()
    live_fallback_cache = {}
    pcall(function() require('don_spells').invalidate_live() end)
    live_ownership_gen = live_ownership_gen + 1
end

--- Generation bumped on worn change; BiS paint caches local column rows against it.
function M.live_ownership_gen()
    return live_ownership_gen
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
    local want = norm(spell_name)
    local idx = snap and snap._bis_index
    if type(idx) == "table" and type(idx.known_spells) == "table" then
        return idx.known_spells[want] == true
    end
    local spells = snap and snap.spells
    if type(spells) ~= "table" then return false end
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
    local ids = entry and entry.spell_ids
    if type(ids) == "table" and #ids > 0 and (not list or #list <= 1) then
        local by_id = snap and snap.spell_ids
        if type(by_id) == "table" then
            for _, id in ipairs(ids) do
                if by_id[tonumber(id)] then return true end
            end
        end
        if list then
            for _, spell in ipairs(list) do
                if snap_knows_spell(snap, spell) then return true end
            end
        end
        return false
    end
    if not list then return false end
    for _, spell in ipairs(list) do
        if not snap_knows_spell(snap, spell) then return false end
    end
    return true
end

local SpellKnown = nil
local function ensure_spell_known()
    if SpellKnown ~= nil then return SpellKnown end
    local ok, mod = pcall(require, 'spell_known')
    SpellKnown = ok and mod or false
    return SpellKnown
end

local function spell_known_live(name)
    local mod = ensure_spell_known()
    if mod and mod.live then return mod.live(name) == true end
    return false
end

local function spell_known_live_id(spell_id)
    local mod = ensure_spell_known()
    if mod and mod.live_id then return mod.live_id(spell_id) == true end
    return false
end

local function live_spells_known(entry)
    local list = entry_spell_list(entry)
    local ids = entry and entry.spell_ids
    -- Single-ability rows (typical vendor scroll/tome): id OR name is enough.
    if type(ids) == "table" and #ids > 0 and (not list or #list <= 1) then
        for _, id in ipairs(ids) do
            if spell_known_live_id(id) then return true end
        end
        if list then
            for _, spell in ipairs(list) do
                if spell_known_live(spell) then return true end
            end
        end
        return false
    end
    if not list then return false end
    for _, spell in ipairs(list) do
        if not spell_known_live(spell) then return false end
    end
    return true
end

local function is_local_eval_snap(snap)
    if type(snap) ~= "table" then return false end
    local my = trim(mq.TLO.Me.CleanName() or ""):lower()
    if my == "" then return false end
    return trim(snap.name or ""):lower() == my
end

local DonSpells = nil
local function ensure_don_spells()
    if DonSpells ~= nil then return DonSpells end
    local ok, mod = pcall(require, 'don_spells')
    DonSpells = ok and mod or false
    return DonSpells
end

local function match_entry(entry, snap)
    entry = normalize_entry_ro(entry)
    local idx = snapshot_index(snap)
    -- DoN pack/single catalog: pack held OR every scroll/ability satisfied.
    local DS = ensure_don_spells()
    if DS and DS.try_match then
        local handled, match, status = DS.try_match(entry, snap)
        if handled then
            return match, status or "missing", entry
        end
    end
    for _, id in ipairs(entry.ids or {}) do
        local rec = idx.by_id[tonumber(id)]
        local matched_name = rec and (rec.item and rec.item.name or rec.item) or nil
        if rec and entry_name_matches_actual(entry, matched_name) then
            return rec.item, forsaken_status_for_match(entry, matched_name, rec.status), entry
        end
    end
    for _, name in ipairs(entry.names or { entry.item }) do
        local rec = not ownership_index.name_is_id_only(name) and idx.by_name[norm_item_name(name)] or nil
        local matched_name = rec and (rec.item and rec.item.name or rec.item) or name
        if rec then return rec.item, forsaken_status_for_match(entry, matched_name, rec.status), entry end
    end
    -- Spell-aware packs: own the pack item OR know every listed spell/disc.
    -- Glyphs and normal gear omit spell metadata and stay item-only.
    if entry_spells_known_in_snap(entry, snap) then
        return entry.item, "known", entry
    end
    return nil, "missing", entry
end

-- Same ownership rules as evaluate_entry(..., { skip_live = true }). Used by
-- needs-index warm so bulk status checks stay faithful (never thinner than
-- evaluate for owned) without the live FindItem path.
function M.snap_entry_status(entry, snap)
    local _, status = match_entry(entry, snap or {})
    return status or "missing"
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
    -- Local checklist/roster: same live FindItem path as evaluate_entry so
    -- equip/unequip colors match reality without waiting on Store persist.
    -- Cached (~0.4s TTL); invalidate_live_ownership_cache on worn changes.
    if (CFG.perf_live_self_bis ~= false) and is_local_eval_snap(snap) then
        for _, entry in ipairs(list.entries or {}) do
            rows[#rows + 1] = M.evaluate_entry(entry, snap)
        end
        return rows
    end
    for _, entry in ipairs(list.entries or {}) do
        local match, status
        match, status, entry = match_entry(entry, snap)
        local have = status ~= nil and status ~= "missing"
        rows[#rows + 1] = { entry = entry, have = have, match = match, status = status }
    end
    return rows
end

local function status_is_have(status)
    return status ~= nil and status ~= "missing"
end

function M.evaluate_entry(entry, snap, opts)
    local match, status
    match, status, entry = match_entry(entry, snap or {})
    -- opts.skip_live: bulk callers (needs index builds) evaluate purely against
    -- the snapshot. Local BiS display (perf_live_self_bis) reconciles with live
    -- FindItem so equip/unequip is instant without waiting on Store persist.
    local want_live = not (opts and opts.skip_live)
        and ((opts and opts.live_fallback) or is_local_eval_snap(snap))
    local live_self = want_live and (CFG.perf_live_self_bis ~= false) and is_local_eval_snap(snap)

    if live_self then
        -- Spell/pack rows keep snap/live spell helpers; gear uses live slot status.
        local DS = ensure_don_spells()
        if DS and DS.try_live_match then
            local handled, liveMatch, liveStatus = DS.try_live_match(entry)
            if handled then
                return {
                    entry = entry,
                    have = status_is_have(liveStatus),
                    match = liveMatch,
                    status = liveStatus or "missing",
                }
            end
        end
        if status == "known" or status == "ready" or status == "pack_owned" then
            if live_spells_known(entry) or status_is_have(status) then
                return { entry = entry, have = true, match = match or entry.item, status = status }
            end
        end
        local live = live_status_cached(entry)
        if status_is_have(live) then
            return {
                entry = entry,
                have = true,
                match = match or entry.item,
                status = live,
            }
        end
        if live_spells_known(entry) then
            return { entry = entry, have = true, match = entry.item, status = "known" }
        end
        return { entry = entry, have = false, match = nil, status = "missing" }
    end

    if match == nil and status == "missing" and want_live then
        local DS = ensure_don_spells()
        if DS and DS.try_live_match then
            local handled, liveMatch, liveStatus = DS.try_live_match(entry)
            if handled then
                return {
                    entry = entry,
                    have = status_is_have(liveStatus),
                    match = liveMatch,
                    status = liveStatus or "missing",
                }
            end
        end
        local live = live_status_cached(entry)
        if live then
            return { entry = entry, have = true, match = nil, status = live }
        end
        if live_spells_known(entry) then
            return { entry = entry, have = true, match = entry.item, status = "known" }
        end
    end
    return { entry = entry, have = status_is_have(status), match = match, status = status }
end

local function link_matches_entry(entry, item_name, item_id)
    if not entry then return false end
    local lname = norm(item_name)
    if lname ~= "" then
        for _, name in ipairs(entry.names or { entry.item }) do
            if norm_item_name(name) == norm_item_name(lname)
                and not ownership_index.name_is_id_only(name) then
                return true
            end
        end
    end
    local iid = tonumber(item_id)
    if iid and iid > 0 then
        for _, id in ipairs(entry.ids or {}) do if tonumber(id) == iid then return true end end
    end
    -- DoN catalog: looted teaching item / pack matches the ability row.
    local DS = ensure_don_spells()
    if DS and DS.lookup_entry then
        local hit = DS.lookup_entry(entry)
        if hit and hit.kind == 'ability' and hit.row then
            local ab = hit.row
            if iid and tonumber(ab.primary_teaching_item_id) == iid then return true end
            if iid and tonumber(ab.source_container_item_id) == iid then return true end
            for _, alt in ipairs(ab.alternate_teaching_item_ids or {}) do
                if iid and tonumber(alt) == iid then return true end
            end
            if lname ~= "" then
                if norm(ab.display_name) == lname then return true end
                if norm(ab.teaching_item_name) == lname then return true end
                if norm(ab.source_name) == lname then return true end
            end
        end
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
            elseif row.status == "carried" or row.status == "known"
                or row.status == "ready" or row.status == "pack_owned" then
                carried = carried + 1
            else missing = missing + 1 end
        end
    end
    return equipped, carried, missing
end

M.manifest_file = manifest_file
return M
