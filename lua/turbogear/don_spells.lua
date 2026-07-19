-- TurboGear/don_spells.lua
-- Per-ability DoN BiS ownership from references/don_spell_catalog.lua.
--
-- Status priority for each ability:
--   known       -> character knows learned_spell_id
--   ready       -> owns primary or alternate teaching item
--   pack_owned  -> owns source_container_item_id (bundle only)
--   missing     -> none of the above

local M = {}

local catalog = nil
local by_class = nil          -- className -> sorted ability list
local by_slot = nil           -- className -> { [slot_key] = ability }
local by_teach_id = nil       -- teaching item id -> ability (any class; for is_learn)
local by_container_id = nil   -- container id -> true
local by_spell_id = nil       -- learned spell id -> true

local function trim(s)
    return tostring(s or ''):match('^%s*(.-)%s*$') or ''
end

local function norm(s)
    s = trim(s):lower()
    s = s:gsub('`', "'"):gsub('\226\128\152', "'"):gsub('\226\128\153', "'")
    return s
end

local function class_key(className)
    className = trim(className)
    if className == 'Shadowknight' then return 'Shadow Knight' end
    return className
end

local function slot_key(ability)
    return trim(ability and ability.display_name or '')
end

local function learned_from_label(ability)
    if not ability then return '' end
    if tostring(ability.source_type or '') == 'bundle' then
        return trim(ability.source_name)
    end
    return trim(ability.teaching_item_name or ability.source_name or '')
end

local function sort_abilities(list)
    table.sort(list, function(a, b)
        return norm(a.display_name) < norm(b.display_name)
    end)
end

local function ensure_index()
    if by_class then return true end
    local ok, data = pcall(require, 'references.don_spell_catalog')
    if not ok or type(data) ~= 'table' then
        catalog = {}
        by_class = {}
        by_slot = {}
        by_teach_id = {}
        by_container_id = {}
        by_spell_id = {}
        return false
    end
    catalog = data
    by_class = {}
    by_slot = {}
    by_teach_id = {}
    by_container_id = {}
    by_spell_id = {}
    for className, list in pairs(data) do
        if type(list) == 'table' then
            local abilities = {}
            local slots = {}
            for _, rec in ipairs(list) do
                if type(rec) == 'table' and trim(rec.display_name) ~= '' then
                    abilities[#abilities + 1] = rec
                    local sk = slot_key(rec)
                    if sk ~= '' then slots[sk] = rec end
                    local tid = tonumber(rec.primary_teaching_item_id)
                    if tid and tid > 0 then by_teach_id[tid] = true end
                    for _, alt in ipairs(rec.alternate_teaching_item_ids or {}) do
                        alt = tonumber(alt)
                        if alt and alt > 0 then by_teach_id[alt] = true end
                    end
                    local cid = tonumber(rec.source_container_item_id)
                    if cid and cid > 0 then by_container_id[cid] = true end
                    local sid = tonumber(rec.learned_spell_id)
                    if sid and sid > 0 then by_spell_id[sid] = true end
                end
            end
            sort_abilities(abilities)
            by_class[className] = abilities
            by_slot[className] = slots
        end
    end
    return true
end

--- Sorted ability records for a class (A-Z by display name).
function M.abilities_for_class(className)
    if not ensure_index() then return {} end
    return by_class[class_key(className)] or {}
end

--- Slot keys (display names) for BiS Spells category, same order as abilities_for_class.
function M.spell_slots_for_class(className)
    local out = {}
    for _, ab in ipairs(M.abilities_for_class(className)) do
        local sk = slot_key(ab)
        if sk ~= '' then out[#out + 1] = sk end
    end
    return out
end

--- Max per-class spell-slot count among the given class names (roster height).
function M.max_spell_slots_for_classes(class_names)
    local max_n = 0
    if type(class_names) ~= 'table' then return 0 end
    for _, cn in ipairs(class_names) do
        local n = #M.spell_slots_for_class(cn)
        if n > max_n then max_n = n end
    end
    return max_n
end

--- Legacy union of ability names across all classes (not used by roster Spells).
function M.spell_slots_union()
    if not ensure_index() then return {} end
    local seen = {}
    local out = {}
    for _, list in pairs(by_class or {}) do
        for _, ab in ipairs(list) do
            local sk = slot_key(ab)
            if sk ~= '' and not seen[sk] then
                seen[sk] = true
                out[#out + 1] = sk
            end
        end
    end
    table.sort(out, function(a, b) return norm(a) < norm(b) end)
    return out
end

function M.ability_for_slot(className, slot)
    if not ensure_index() then return nil end
    local slots = by_slot[class_key(className)]
    if not slots then return nil end
    return slots[trim(slot)]
end

--- True if slot is a known DoN ability display name (any class).
function M.is_ability_slot(slot)
    if not ensure_index() then return false end
    slot = trim(slot)
    if slot == '' then return false end
    for _, slots in pairs(by_slot or {}) do
        if slots[slot] then return true end
    end
    return false
end

--- Build a BiS entry table for an ability (display name = learned name).
function M.bis_entry_for_ability(ability)
    if type(ability) ~= 'table' then return nil end
    local ids = {}
    local tid = tonumber(ability.primary_teaching_item_id)
    if tid and tid > 0 then ids[#ids + 1] = tid end
    for _, alt in ipairs(ability.alternate_teaching_item_ids or {}) do
        alt = tonumber(alt)
        if alt and alt > 0 then ids[#ids + 1] = alt end
    end
    local cid = tonumber(ability.source_container_item_id)
    if cid and cid > 0 then ids[#ids + 1] = cid end
    local name = trim(ability.display_name)
    return {
        item = name,
        names = { name },
        ids = ids,
        slot = name,
        spell = name,
        spells = { name },
        spell_ids = { tonumber(ability.learned_spell_id) },
        don_ability = ability,
        learned_from = learned_from_label(ability),
    }
end

--- Resolve a BiS entry to a catalog ability, or nil.
function M.lookup_entry(entry)
    if type(entry) ~= 'table' then return nil end
    if type(entry.don_ability) == 'table' then
        return { kind = 'ability', row = entry.don_ability }
    end
    if not ensure_index() then return nil end
    -- Prefer explicit spell_ids + display name match across classes (rare).
    local sid = nil
    if type(entry.spell_ids) == 'table' then
        sid = tonumber(entry.spell_ids[1])
    end
    local want = norm(entry.item or entry.slot)
    if want == '' and type(entry.spells) == 'table' then
        want = norm(entry.spells[1])
    end
    if want ~= '' then
        for _, list in pairs(by_class or {}) do
            for _, ab in ipairs(list) do
                if norm(ab.display_name) == want then
                    if not sid or tonumber(ab.learned_spell_id) == sid then
                        return { kind = 'ability', row = ab }
                    end
                end
            end
        end
    end
    -- Teaching / container id fallback (legacy Pack rows).
    for _, id in ipairs(entry.ids or {}) do
        id = tonumber(id)
        if id then
            for _, list in pairs(by_class or {}) do
                for _, ab in ipairs(list) do
                    if tonumber(ab.primary_teaching_item_id) == id then
                        return { kind = 'ability', row = ab }
                    end
                    for _, alt in ipairs(ab.alternate_teaching_item_ids or {}) do
                        if tonumber(alt) == id then
                            return { kind = 'ability', row = ab }
                        end
                    end
                end
            end
            -- Container-only: do not map pack id to a single ability (ambiguous).
        end
    end
    return nil
end

local function snap_has_id(snap, item_id)
    item_id = tonumber(item_id)
    if not item_id or item_id <= 0 or type(snap) ~= 'table' then return nil end
    local idx = snap._bis_index
    if type(idx) == 'table' and type(idx.by_id) == 'table' then
        return idx.by_id[item_id]
    end
    local function scan(list)
        for _, it in ipairs(list or {}) do
            if tonumber(it.id) == item_id then
                return { item = it, status = 'carried' }
            end
        end
        return nil
    end
    return scan(snap.equipped) or scan(snap.bags) or scan(snap.bank)
end

local function snap_knows(snap, ability)
    if type(ability) ~= 'table' or type(snap) ~= 'table' then return false end
    local sid = tonumber(ability.learned_spell_id or ability.spell_id)
    if sid and sid > 0 and type(snap.spell_ids) == 'table' and snap.spell_ids[sid] then
        return true
    end
    local want = norm(ability.display_name or ability.ability)
    if want == '' then return false end
    local spells = snap.spells
    if type(spells) ~= 'table' then return false end
    local row = spells[want]
    if type(row) == 'table' and ((row.book == true) or (tonumber(row.book) or 0) > 0) then
        return true
    end
    for key, rec in pairs(spells) do
        if type(rec) == 'table' then
            local n = norm(rec.name or key)
            if n == want and ((rec.book == true) or (tonumber(rec.book) or 0) > 0) then
                return true
            end
        end
    end
    return false
end

local function snap_has_teaching(snap, ability)
    local tid = tonumber(ability.primary_teaching_item_id)
    if tid and snap_has_id(snap, tid) then return true, tid end
    for _, alt in ipairs(ability.alternate_teaching_item_ids or {}) do
        alt = tonumber(alt)
        if alt and snap_has_id(snap, alt) then return true, alt end
    end
    return false, nil
end

local function resolve_status(ability, has_known, has_teach, has_pack)
    local name = trim(ability.display_name)
    if has_known then return name, 'known' end
    if has_teach then return name, 'ready' end
    if has_pack then return name, 'pack_owned' end
    return nil, 'missing'
end

--- Snapshot match. Returns handled, match, status.
function M.try_match(entry, snap)
    local hit = M.lookup_entry(entry)
    if not hit or hit.kind ~= 'ability' then return false, nil, nil end
    local ability = hit.row
    local known = snap_knows(snap, ability)
    local teach = select(1, snap_has_teaching(snap, ability))
    local pack = false
    local cid = tonumber(ability.source_container_item_id)
    if cid and cid > 0 and snap_has_id(snap, cid) then pack = true end
    local match, status = resolve_status(ability, known, teach, pack)
    return true, match, status
end

--- True if item_id is a DoN teaching item or pack container (scribe/consume paths).
function M.is_learn_item_id(item_id)
    item_id = tonumber(item_id)
    if not item_id or item_id <= 0 then return false end
    if not ensure_index() then return false end
    return by_teach_id[item_id] == true or by_container_id[item_id] == true
end

local function live_has_item(item_id)
    item_id = tonumber(item_id)
    if not item_id or item_id <= 0 then return false end
    local ok, cnt = pcall(function()
        local mq = require('mq')
        local fi = mq.TLO.FindItem and mq.TLO.FindItem(item_id)
        if fi and fi() then return tonumber(fi.Count()) or 0 end
        return 0
    end)
    return ok and (cnt or 0) > 0
end

local function live_knows(ability)
    local sid = tonumber(ability.learned_spell_id or ability.spell_id)
    local name = trim(ability.display_name or ability.ability or ability.name)
    local ok, mod = pcall(require, 'spell_known')
    if not ok or not mod then return false end
    local known = false
    if sid and sid > 0 and mod.live_id and mod.live_id(sid) then known = true end
    if not known and name ~= '' and mod.live and mod.live(name) then known = true end
    if known then
        pcall(function()
            local SC = require('spell_cache')
            if sid and sid > 0 and SC.probe_id then SC.probe_id(sid) end
            if name ~= '' and SC.probe_name then SC.probe_name(name) end
        end)
    end
    return known
end

local function live_has_teaching(ability)
    local tid = tonumber(ability.primary_teaching_item_id)
    if tid and live_has_item(tid) then return true end
    for _, alt in ipairs(ability.alternate_teaching_item_ids or {}) do
        if live_has_item(alt) then return true end
    end
    return false
end

--- Live match (FindItem + Book/CombatAbility). Same return shape as try_match.
function M.try_live_match(entry)
    local hit = M.lookup_entry(entry)
    if not hit or hit.kind ~= 'ability' then return false, nil, nil end
    local ability = hit.row
    local known = live_knows(ability)
    local teach = live_has_teaching(ability)
    local pack = false
    local cid = tonumber(ability.source_container_item_id)
    if cid and cid > 0 and live_has_item(cid) then pack = true end
    local match, status = resolve_status(ability, known, teach, pack)
    return true, match, status
end

--- Probe every catalog ability for a class into spell maps (spellsync).
function M.merge_into_spell_maps(className, out, spell_ids_out, probe_book, probe_id)
    if not ensure_index() then return end
    for _, ab in ipairs(M.abilities_for_class(className)) do
        local ability = trim(ab.display_name)
        local spell_id = tonumber(ab.learned_spell_id)
        local known = false
        if spell_id and spell_id > 0 and probe_id then
            known = probe_id(spell_id) == true
            if known then spell_ids_out[spell_id] = true end
        end
        if ability ~= '' and probe_book and probe_book(ability) then
            known = true
        end
        if ability == '' then goto continue end
        local key = norm(ability)
        local prev = out[key]
        if not prev then
            out[key] = {
                name = ability,
                book = known and 1 or 0,
                scroll = 0,
                spell_id = spell_id,
            }
        elseif known then
            prev.book = 1
            if spell_id then prev.spell_id = spell_id end
        end
        ::continue::
    end
end

function M.learned_from(ability_or_entry)
    if type(ability_or_entry) == 'table' and ability_or_entry.don_ability then
        return learned_from_label(ability_or_entry.don_ability)
    end
    if type(ability_or_entry) == 'table' and ability_or_entry.learned_from then
        return trim(ability_or_entry.learned_from)
    end
    return learned_from_label(ability_or_entry)
end

-- Test / debug helpers
function M._reset_index_for_tests()
    catalog = nil
    by_class = nil
    by_slot = nil
    by_teach_id = nil
    by_container_id = nil
    by_spell_id = nil
end

return M
