-- TurboGear/type12_ownership.lua
-- UI-only Type 12 source classifier.
--
-- Type 12 ownership is a pure item-identity question: does this character hold
-- one of 36 specific augs?  Both the DoN and DSK focus augs live in their list's
-- shared `template` (every class bucket holds only the class-gated Prowess aug),
-- so there is nothing to resolve per class, per chain, or per tier.  The source
-- table below is therefore derived from the catalog once and evaluated by
-- identity against the shared ownership index that bis/needs_index already
-- build and cache on each snapshot.
--
-- Ownership is a union of the cheap sources, because each one has a distinct
-- blind spot: a peer snapshot can be present but incomplete, and a bis_search
-- FindItem map can be stale or absent.  If either says the aug is held, it is.

local mq = require('mq')
local catalog = require('bis_catalog')
local bis = require('bis')
local cfg = require('config')
local ownership_index = require('ownership_index')

local M = {}

local FAMILIES = {
    { family = "DoN", list_id = "don" },
    { family = "DSK", list_id = "dsk" },
}

local ROWS = {
    { effect = "Increased Healing", display = "Increased Healing", source = "Merciful Mending" },
    { effect = "Extended Reach", display = "Extended Reach", source = "Expanded Reach", divider_after = true },
    { effect = "Beneficial Extension", display = "Beneficial Extension", source = "Benevolent Extension" },
    { effect = "Beneficial Reduction of Mana", display = "Beneficial Mana Reduction", source = "Benevolent Efficiency" },
    { effect = "Beneficial Cast Time Reduction", display = "Beneficial Cast Time Reduction", source = "Benevolent Alacrity", divider_after = true },
    { effect = "Detrimental Extension", display = "Detrimental Extension", source = "Malevolent Extension" },
    { effect = "Detrimental Reduction of Mana", display = "Detrimental Mana Reduction", source = "Malevolent Efficiency" },
    { effect = "Detrimental Cast Time Reduction", display = "Detrimental Cast Time Reduction", source = "Malevolent Alacrity", divider_after = true },
    { effect = "Magic Damage", display = "Magic Damage", source = "Arcane Demise" },
    { effect = "Fire Damage", display = "Fire Damage", source = "Fiery Demise" },
    { effect = "Ice Damage", display = "Ice Damage", source = "Chilling Demise" },
    { effect = "Poison Damage", display = "Poison Damage", source = "Noxious Demise" },
    { effect = "Disease Damage", display = "Disease Damage", source = "Festering Demise", divider_after = true },
    { effect = "Cleave", display = "Cleave", source = "Visceral Malice" },
    { effect = "Double Attack", display = "Double Attack", source = "Wanton Assault" },
    { effect = "Ranged Accuracy", display = "Ranged Accuracy", source = "Lethal Barrage", divider_after = true },
    { effect = "Improved Dodge", display = "Improved Dodge", source = "Nimble Elusion" },
    { effect = "Block and Parry", display = "Block and Parry", source = "Adept Guard" },
}

local function trim(s)
    return tostring(s or ""):match("^%s*(.-)%s*$") or ""
end

local function norm_source(s)
    return trim(s):lower():gsub("`", "'"):gsub("\226\128\152", "'"):gsub("\226\128\153", "'"):gsub("%s+", " ")
end

-- effect -> { DoN = { slot, ids, names }, DSK = { ... } }, built once from the
-- catalog templates.  Keyed on the short focus name (`entry.item`), which both
-- families share, so a future catalog edit cannot silently misalign them.
local sources = nil

local function build_sources()
    local out = {}
    local wanted = {}
    for _, row in ipairs(ROWS) do
        local key = norm_source(row.source)
        if key ~= "" then wanted[key] = row.effect end
    end

    for _, spec in ipairs(FAMILIES) do
        local ok, list = pcall(catalog.list, spec.list_id)
        if ok and type(list) == "table" and type(list.template) == "table" then
            for slot, raw in pairs(list.template) do
                local effect = type(raw) == "table" and wanted[norm_source(raw.item)] or nil
                if effect then
                    local rec = { slot = tostring(slot or ""), ids = {}, names = {} }
                    for _, id in ipairs(raw.ids or {}) do
                        local n = tonumber(id)
                        if n and n > 0 then rec.ids[#rec.ids + 1] = n end
                    end
                    -- Match only the family-prefixed names ("Cryptic Clutch of
                    -- X", "Vacant Vessel of X", "Hideous Hex of X").  Both
                    -- families also carry the bare focus name as names[1], which
                    -- is identical across them and so cannot disambiguate.
                    local short = ownership_index.norm_item_name(raw.item)
                    local seen = {}
                    for _, n in ipairs(raw.names or {}) do
                        local v = ownership_index.norm_item_name(n)
                        if v ~= "" and v ~= short and not seen[v] then
                            seen[v] = true
                            rec.names[#rec.names + 1] = v
                        end
                    end
                    out[effect] = out[effect] or {}
                    out[effect][spec.family] = rec
                end
            end
        end
    end
    return out
end

local function ensure_sources()
    if sources == nil then sources = build_sources() end
    return sources
end

local function index_hit(rec, idx)
    if type(rec) ~= "table" or type(idx) ~= "table" then return nil end
    for _, id in ipairs(rec.ids) do
        local hit = idx.by_id and idx.by_id[id]
        if hit then return hit end
    end
    for _, name in ipairs(rec.names) do
        local hit = idx.by_name and idx.by_name[name]
        if hit then return hit end
    end
    return nil
end

local function search_map_hit(rec, list_id, snap, key)
    local target = key
    if target == nil or target == "" then target = snap end
    if target == nil then return nil end
    local ok, bis_search = pcall(require, 'bis_search')
    if not ok or type(bis_search) ~= "table" or not bis_search.slot_rec then return nil end
    local ok2, hit = pcall(bis_search.slot_rec, target, list_id, rec.slot)
    if not ok2 or type(hit) ~= "table" then return nil end
    local status = tostring(hit.status or "")
    if status == "equipped" or status == "carried" then return hit end
    if status == "" and (tonumber(hit.count) or 0) > 0 then return hit end
    return nil
end

local function is_self_snap(snap)
    if type(snap) ~= "table" then return false end
    local mine = ""
    pcall(function() mine = tostring(mq.TLO.Me.CleanName() or ""):lower() end)
    if mine == "" then return false end
    return tostring(snap.name or ""):lower() == mine
end

local function class_key(class_name)
    if cfg and cfg.canonical_class then return cfg.canonical_class(class_name) end
    class_name = trim(class_name)
    if class_name == "" or class_name == "?" then return nil end
    if class_name == "Shadowknight" then return "Shadow Knight" end
    return class_name
end

-- Local column only: the live FindItem path (bis.evaluate_entry on the resolved
-- catalog row) keeps equip/unequip instant without waiting on a re-gather.  Paid
-- at most once per missing effect for one character, never for peers.
local self_entry_cache = {}

local function self_live_hit(rec, list_id, snap)
    if type(rec) ~= "table" or trim(rec.slot) == "" then return nil end
    local ck = table.concat({ list_id, tostring(class_key(snap and snap.class) or ""), rec.slot }, "\31")
    local entry = self_entry_cache[ck]
    if entry == nil then
        local ok, resolved = pcall(catalog.resolve_entry, list_id, snap and snap.class, rec.slot)
        entry = (ok and type(resolved) == "table") and resolved or false
        self_entry_cache[ck] = entry
    end
    if entry == false then return nil end
    local ok, row = pcall(bis.evaluate_entry, entry, snap)
    if ok and type(row) == "table" and row.have == true then return row end
    return nil
end

function M.rows()
    return ROWS
end

function M.display_label(row_or_effect)
    if type(row_or_effect) == "table" then return row_or_effect.display or row_or_effect.effect or "" end
    local effect = tostring(row_or_effect or "")
    for _, row in ipairs(ROWS) do
        if row.effect == effect then return row.display end
    end
    return effect
end

function M.classify(snap, row, opts)
    row = type(row) == "table" and row or nil
    if not snap or trim(snap.class) == "" or not row then
        return { source = "-", applicable = false }
    end
    opts = type(opts) == "table" and opts or {}

    local by_family = ensure_sources()[row.effect]
    if not by_family then return { source = "-", applicable = false } end

    local idx = ownership_index.cached_snapshot_index(snap)
    local self_col = is_self_snap(snap)

    for _, spec in ipairs(FAMILIES) do
        local rec = by_family[spec.family]
        if rec then
            local hit = index_hit(rec, idx)
            local via = hit and "snapshot" or nil
            -- Peers only: the FindItem map covers incomplete peer snapshots. The
            -- local character has its own live read, which is strictly better.
            if not hit and not self_col then
                hit = search_map_hit(rec, spec.list_id, snap, opts.key)
                via = hit and "bis_search" or nil
            end
            if not hit and self_col then
                hit = self_live_hit(rec, spec.list_id, snap)
                via = hit and "live" or nil
            end
            if hit then
                return {
                    source = spec.family,
                    applicable = true,
                    via = via,
                    slot = rec.slot,
                    match = hit.item or hit.match or hit,
                }
            end
        end
    end

    return { source = "-", applicable = true }
end

--- Test/diagnostic hook: drop the derived source table and cached self rows.
function M.invalidate()
    sources = nil
    self_entry_cache = {}
end

--- Diagnostic: how many effects resolved a source aug per family.
function M.source_summary()
    local out = { effects = 0, DoN = 0, DSK = 0, ids = 0, names = 0 }
    for _, by_family in pairs(ensure_sources()) do
        out.effects = out.effects + 1
        for _, spec in ipairs(FAMILIES) do
            local rec = by_family[spec.family]
            if rec then
                out[spec.family] = out[spec.family] + 1
                out.ids = out.ids + #rec.ids
                out.names = out.names + #rec.names
            end
        end
    end
    return out
end

return M
