-- TurboGear/snapshot.lua
-- Builds this box's own snapshot (equipped + bags + bank, each item with augs).
-- Lite gathers skip stats/focus meta (heartbeat + bg default). Full gathers
-- run on Sync Now, startup, and Stats/Focus/Suggest tabs.

local mq       = require('mq')
local cfg      = require('config')
local CFG      = cfg.CFG
local Settings = cfg.Settings
local items    = require('items')
local diag     = require('diagnostics')
local inventory_stats = require('inventory_stats')

local inventory_slots = items.inventory_slots
local make_item       = items.make_item
local make_item_lite  = items.make_item_lite

-- R1: per-publisher monotonic sequence. SEQ_EPOCH (captured once at load) makes
-- seqs from a later session sort above an earlier one after a restart; the
-- counter orders publishes within a session. Encoded as one comparable number
-- that stays well under 2^53. Used ONLY to order snapshots for the SAME key
-- (same owner), so it is immune to cross-box clock skew.
local SEQ_EPOCH = os.time()
local seq_counter = 0
local function next_seq()
    seq_counter = seq_counter + 1
    return SEQ_EPOCH * 1000000 + seq_counter
end

local M = {}

local FULL_TABS = { stats = true, focus = true, suggestions = true, live = true }

local self_lite_snap, self_lite_time = nil, 0
local self_full_snap, self_full_time = nil, 0
local self_bank_cache = nil

-- Phase 1: last spell gather (ID/signature keyed). Cleared on invalidate / scribe.
local spell_cache_store = { class = nil, spells = nil, ids = nil, sig = nil }

-- Phase 1: coalesce burst force=true gathers (startup / peer_request storms).
local last_force_snap, last_force_time, last_force_depth = nil, 0, nil

local function perf_snapshot_cache_on()
    return CFG.perf_snapshot_cache ~= false
end

-- Top-level clone only. Nested equipped/bags/bank/spells tables are shared —
-- snapshots are read-only by contract (Store.save builds its own out table).
local function shallow_copy_snap(src)
    if type(src) ~= "table" then return src end
    local dst = {}
    for k, v in pairs(src) do dst[k] = v end
    return dst
end

local function normalize_opts(arg)
    if type(arg) == "boolean" then
        return { force = arg, depth = arg and "full" or nil }
    end
    if type(arg) == "table" then return arg end
    return {}
end

function M.depth_for_settings()
    local tab = Settings.mainTab or "bis"
    if tab == "inspect" then tab = Settings.inspectTab or "stats" end
    if tab == "upgrade" then tab = Settings.upgradeTab or "suggestions" end
    if FULL_TABS[tab] then return "full" end
    return "lite"
end

function M.cached()
    if self_full_snap then return self_full_snap end
    return self_lite_snap
end

-- Phase 2: worn-slot signature. ~23 Inventory(id).ID() reads — no make_item,
-- no bag/bank walk. Change detector for silent equip/unequip.
function M.worn_signature()
    local parts = {}
    for _, slot in ipairs(inventory_slots) do
        local id = 0
        pcall(function()
            id = tonumber(mq.TLO.Me.Inventory(slot.id).ID() or 0) or 0
        end)
        parts[#parts + 1] = tostring(slot.id) .. ":" .. tostring(id)
    end
    return table.concat(parts, "|")
end

-- Phase 2: ID-only bag-slot locate (no make_item / stats walk).
function M.find_bag_slot_by_id(item_id)
    item_id = tonumber(item_id) or 0
    if item_id <= 0 then return nil end
    -- Cursor counts as carried for BiS ownership (mid-swap must not go missing).
    do
        local cur = mq.TLO.Cursor
        local cid = 0
        pcall(function() cid = tonumber(cur and cur.ID() or 0) or 0 end)
        if cid == item_id then
            return { where = "Cursor", slotid = nil, slotname = "Cursor" }
        end
    end
    for inv = 23, 34 do
        local pack = mq.TLO.Me.Inventory(inv)
        local pack_id = 0
        pcall(function() pack_id = tonumber(pack and pack.ID() or 0) or 0 end)
        if pack_id == item_id then
            return {
                where = "Inventory Bag " .. tostring(inv - 22),
                slotid = inv,
                slotname = "Bag",
            }
        end
        local slots = 0
        pcall(function() slots = tonumber(pack and pack.Container() or 0) or 0 end)
        for i = 1, slots do
            local it = pack.Item(i)
            local id = 0
            pcall(function() id = tonumber(it and it.ID() or 0) or 0 end)
            if id == item_id then
                local pack_name = "Bag" .. tostring(inv - 22)
                pcall(function() pack_name = tostring(pack.Name() or pack_name) end)
                return {
                    where = pack_name .. " #" .. i,
                    slotid = inv,
                    slotname = i,
                }
            end
        end
    end
    return nil
end

-- True when an item row has any non-zero base/effective stat (or class/slot
-- meta). Used to reject EQ "not loaded yet" full builds that would stamp
-- depth=full with all-zero stats. Do NOT use AC==0 alone — many worn items
-- legitimately have 0 AC.
function M.item_has_populated_stats(it)
    if type(it) ~= "table" then return false end
    local s = it.baseStats or it.stats
    if type(s) == "table" then
        for _, key in ipairs({
            "ac", "hp", "mana", "endurance",
            "str", "sta", "agi", "dex", "wis", "int", "cha",
            "attack", "hpRegen", "manaRegen", "healAmount", "spellDamage",
            "shielding", "spellShield", "dotShielding", "damageShield",
            "avoidance", "accuracy", "stunResist", "strikeThrough",
        }) do
            if (tonumber(s[key]) or 0) ~= 0 then return true end
        end
    end
    if type(it.classes) == "table" then
        if it.classes[1] ~= nil or next(it.classes) ~= nil then return true end
    end
    if type(it.slots) == "table" and #it.slots > 0 then return true end
    if it.allClasses == true then return true end
    if type(it.focusEffects) == "table" and (it.focusEffects[1] ~= nil or next(it.focusEffects) ~= nil) then
        return true
    end
    if type(it.wornFocusEffects) == "table" and (it.wornFocusEffects[1] ~= nil or next(it.wornFocusEffects) ~= nil) then
        return true
    end
    if it.clicky ~= nil then return true end
    return false
end

-- Reuse unchanged slot+id rows. When want_depth is "full", also rebuild rows
-- still stamped depth=lite (or legacy rows with no depth and no stats) so a
-- poisoned worn set heals without a full 22-slot walk when most rows are full.
-- Worst case one pass ≈ all worn slots full-build off-UI — rare; typical equip
-- is ~1 full make_item.
function M.worn_entry_needs_rebuild(prev, live_id, want_depth)
    live_id = tonumber(live_id) or 0
    if live_id <= 0 then return false end
    if type(prev) ~= "table" or tonumber(prev.id) ~= live_id then return true end
    if want_depth == "full" then
        local d = tostring(prev.depth or "")
        if d == "lite" then return true end
        -- Legacy / false-full poison: no usable meta yet (not the same as AC==0).
        if not M.item_has_populated_stats(prev) then return true end
    end
    return false
end

function M.equipped_has_lite_items(snap)
    if type(snap) ~= "table" or type(snap.equipped) ~= "table" then return false end
    for _, it in ipairs(snap.equipped) do
        if not it then goto continue end
        local d = tostring(it.depth or "")
        if d == "lite" then return true end
        -- Named worn with no usable stats (missing depth or false full zeros).
        if (it.name and it.name ~= "") and not M.item_has_populated_stats(it) then
            return true
        end
        ::continue::
    end
    return false
end

-- Phase 2: re-read worn slots and patch the cached snap in place.
-- Reuses cached entries by slot+id (typical equip = ~1 make_item when depth=full).
-- Removes newly-worn IDs from bags (equip-from-bags ghost).
-- Relocates departed worn IDs into bags (keeps ownership; BiS stays blue not red).
-- Bumps seq so peer cache-newer / is_newer accepts the patch.
-- Returns the patched snap, or nil if there is no cached snap to patch.
function M.refresh_equipped(depth)
    local snap = M.cached()
    if type(snap) ~= "table" or type(snap.equipped) ~= "table" then return nil end
    local want_full = depth == "full"

    local old_by_slot_id = {}
    local old_by_id = {}
    for _, it in ipairs(snap.equipped) do
        if it and it.slotid ~= nil then
            old_by_slot_id[it.slotid] = it
        end
        local id = tonumber(it and it.id)
        if id and id > 0 then old_by_id[id] = it end
    end

    local new_equipped, now_ids = {}, {}
    for _, slot in ipairs(inventory_slots) do
        local item = mq.TLO.Me.Inventory(slot.id)
        local live_id = 0
        pcall(function()
            live_id = tonumber(item and item.ID() or 0) or 0
        end)
        if live_id ~= 0 then
            local prev = old_by_slot_id[slot.id]
            local entry
            if not M.worn_entry_needs_rebuild(prev, live_id, want_full and "full" or "lite") then
                entry = prev
            elseif want_full then
                -- Full stats/aug walk for this slot only (bg thread). If EQ has
                -- not loaded item meta yet, keep depth=lite so UI stays honest
                -- and a later heal can retry — never stamp false full zeros.
                entry = make_item(item, "Equipped", slot.name, slot.id, slot.name)
                if not M.item_has_populated_stats(entry) then
                    entry = make_item_lite(item, "Equipped", slot.name, slot.id, slot.name)
                    diag.count("snapshot.equipped_full_empty")
                end
            else
                entry = make_item_lite(item, "Equipped", slot.name, slot.id, slot.name)
            end
            new_equipped[#new_equipped + 1] = entry
            now_ids[live_id] = true
        end
    end

    snap.bags = type(snap.bags) == "table" and snap.bags or {}

    -- Ghost removal: item now worn must not remain listed in bags.
    do
        local kept = {}
        for _, it in ipairs(snap.bags) do
            local id = tonumber(it and it.id)
            if not (id and now_ids[id]) then
                kept[#kept + 1] = it
            end
        end
        snap.bags = kept
    end

    -- Worn -> bags: keep ownership so BiS doesn't go missing/red. Prefer a live
    -- bag slot; if the item is mid-cursor, still keep a Carried stub.
    local bags_have = {}
    for _, it in ipairs(snap.bags) do
        local id = tonumber(it and it.id)
        if id then bags_have[id] = true end
    end
    for id, old in pairs(old_by_id) do
        if not now_ids[id] and not bags_have[id] then
            local loc = M.find_bag_slot_by_id(id)
            old.location = "Bags"
            if loc then
                old.where = loc.where
                old.slotid = loc.slotid
                old.slotname = loc.slotname
            else
                old.where = "Bags"
                old.slotid = nil
                old.slotname = nil
            end
            snap.bags[#snap.bags + 1] = old
            bags_have[id] = true
            diag.count("snapshot.equipped_to_bags")
        end
    end

    snap.equipped = new_equipped
    -- Must bump seq: peer cache ingest uses is_newer(seq). Same seq = rejected,
    -- which left re-equips stuck on the post-unequip (missing) snap.
    snap.seq = next_seq()
    snap.updated = os.time()
    snap.inventoryUpdated = snap.updated
    -- Ownership index is stale after equipped/bags patch.
    snap._bis_index = nil
    snap._bis_index_key = nil
    -- Keep lite/full cache pointers coherent with the patched snap.
    M.adopt(snap)
    diag.count("snapshot.equipped_patch")
    return snap
end

function M.invalidate()
    self_lite_snap, self_lite_time = nil, 0
    self_full_snap, self_full_time = nil, 0
    spell_cache_store = { class = nil, spells = nil, ids = nil, sig = nil }
    last_force_snap, last_force_time, last_force_depth = nil, 0, nil
end

--- Attach spells to snap: reuse module cache when spell_cache signature matches
--- (ID-level known-set); otherwise gather once and store.
local function attach_spells(snap)
    local spell_snap = require('spell_snapshot')
    local className = snap.class
    if perf_snapshot_cache_on()
        and spell_cache_store.spells
        and spell_cache_store.class == className
        and type(spell_cache_store.sig) == "string"
        and spell_cache_store.sig ~= "" then
        local reuse = false
        local okC, SC = pcall(require, 'spell_cache')
        if okC and SC and SC.ready and SC.ready() and SC.signature then
            local live_sig = tostring(SC.signature() or "")
            reuse = live_sig ~= "" and live_sig == spell_cache_store.sig
        else
            -- spell_cache not ready: keep last gather until invalidate/scribe.
            reuse = true
        end
        if reuse then
            snap.spells = spell_cache_store.spells
            snap.spell_ids = spell_cache_store.ids
            snap.spells_sig = spell_cache_store.sig
            diag.count("snapshot.spells_cache_hit")
            return
        end
    end
    local spells, spell_ids = spell_snap.gather(className)
    local sig = spell_snap.signature(spells, spell_ids)
    snap.spells = spells
    snap.spell_ids = spell_ids
    snap.spells_sig = sig
    spell_cache_store = {
        class = className,
        spells = spells,
        ids = spell_ids,
        sig = sig,
    }
    diag.count("snapshot.spells_cache_miss")
end

local function append_item(snap, list_key, item, location, where, slotid, slotname, depth)
    local mk = depth == "full" and make_item or make_item_lite
    snap[list_key][#snap[list_key] + 1] = mk(item, location, where, slotid, slotname)
end

local function try_tlo_value(fn)
    local ok, value = pcall(fn)
    if ok then return value end
    return nil
end

local function bank_window_open()
    local function is_open(v)
        if v == true or v == 1 then return true end
        local s = tostring(v or ""):lower()
        return s == "true" or s == "1"
    end
    local value = try_tlo_value(function() return mq.TLO.Window("BigBankWnd").Open() end)
    if is_open(value) then return true end
    value = try_tlo_value(function() return mq.TLO.Window("BankWnd").Open() end)
    return is_open(value)
end

M.bank_window_open = bank_window_open

local function safe_num(...)
    local fns = { ... }
    for _, fn in ipairs(fns) do
        local value = tonumber(try_tlo_value(fn))
        if value ~= nil then return value end
    end
    return nil
end

local function safe_member_num(obj, fields)
    for _, field in ipairs(fields or {}) do
        local value = try_tlo_value(function()
            local member = obj[field]
            if member ~= nil then return member() end
            return nil
        end)
        value = tonumber(value)
        if value ~= nil then return value end
    end
    return nil
end

local function safe_member_str(obj, fields)
    for _, field in ipairs(fields or {}) do
        local value = try_tlo_value(function()
            local member = obj[field]
            if member ~= nil then return member() end
            return nil
        end)
        if value ~= nil and tostring(value) ~= "" and tostring(value) ~= "NULL" then return tostring(value) end
    end
    return nil
end

local function append_buff(out, buff, slot, kind)
    if not buff then return end
    local name = tostring(try_tlo_value(function() return buff.Name() end) or "")
    if name == "" or name == "NULL" then
        name = tostring(try_tlo_value(function() return buff() end) or "")
    end
    if name == "" or name == "NULL" then return end
    local remaining = safe_member_num(buff, { "Duration" })
    if remaining then remaining = math.floor(remaining / 1000) end
    local duration = try_tlo_value(function()
        local d = buff.MyDuration
        if d and d.TotalSeconds then return d.TotalSeconds() end
        return nil
    end)
    out[#out + 1] = {
        name = name,
        duration = tonumber(remaining),
        fullDuration = tonumber(duration),
        hitCount = safe_member_num(buff, { "HitCount" }),
        icon = safe_member_num(buff, { "SpellIcon" }),
        spellType = safe_member_str(buff, { "SpellType" }),
        slot = slot,
        kind = kind,
    }
end

local function gather_buffs()
    local out = {}
    local me = mq.TLO.Me
    local max_buffs = safe_num(function() return me.MaxBuffSlots() end) or 60
    if max_buffs < 1 then max_buffs = 60 end
    if max_buffs > 80 then max_buffs = 80 end
    for i = 1, max_buffs do
        append_buff(out, try_tlo_value(function() return me.Buff(i) end), i, "Buff")
    end
    for i = 1, 30 do
        append_buff(out, try_tlo_value(function() return me.Song(i) end), i, "Song")
    end
    return out
end

local function gather_live_stats()
    local me = mq.TLO.Me
    local stats = {}
    stats.hp = safe_num(function() return me.MaxHPs() end, function() return me.MaxHP() end, function() return me.CurrentHPs() end, function() return me.HP() end)
    stats.currentHp = safe_num(function() return me.CurrentHPs() end, function() return me.HP() end)
    stats.mana = safe_num(function() return me.MaxMana() end, function() return me.CurrentMana() end, function() return me.Mana() end)
    stats.currentMana = safe_num(function() return me.CurrentMana() end, function() return me.Mana() end)
    stats.endurance = safe_num(function() return me.MaxEndurance() end, function() return me.Endurance() end, function() return me.CurrentEndurance() end)
    stats.currentEndurance = safe_num(function() return me.CurrentEndurance() end, function() return me.Endurance() end)
    stats.ac = safe_num(function() return me.AC() end, function() return me.ArmorClass() end)
    stats.attack = safe_num(function() return me.Attack() end, function() return me.ATK() end)
    stats.atk = stats.attack
    stats.str = safe_num(function() return me.STR() end, function() return me.Str() end) or safe_member_num(me, { "STR", "Str", "Strength" })
    stats.sta = safe_num(function() return me.STA() end, function() return me.Sta() end) or safe_member_num(me, { "STA", "Sta", "Stamina" })
    stats.agi = safe_num(function() return me.AGI() end, function() return me.Agi() end) or safe_member_num(me, { "AGI", "Agi", "Agility" })
    stats.dex = safe_num(function() return me.DEX() end, function() return me.Dex() end) or safe_member_num(me, { "DEX", "Dex", "Dexterity" })
    stats.wis = safe_num(function() return me.WIS() end, function() return me.Wis() end) or safe_member_num(me, { "WIS", "Wis", "Wisdom" })
    stats.int = safe_num(function() return me.INT() end, function() return me.Int() end) or safe_member_num(me, { "INT", "Int", "Intelligence" })
    stats.cha = safe_num(function() return me.CHA() end, function() return me.Cha() end) or safe_member_num(me, { "CHA", "Cha", "Charisma" })
    stats.heroicStr = safe_num(function() return me.HeroicSTR() end, function() return me.HSTR() end) or safe_member_num(me, { "HeroicSTR", "HeroicStr", "HSTR", "HeroicStrength" })
    stats.heroicSta = safe_num(function() return me.HeroicSTA() end, function() return me.HSTA() end) or safe_member_num(me, { "HeroicSTA", "HeroicSta", "HSTA", "HeroicStamina" })
    stats.heroicAgi = safe_num(function() return me.HeroicAGI() end, function() return me.HAGI() end) or safe_member_num(me, { "HeroicAGI", "HeroicAgi", "HAGI", "HeroicAgility" })
    stats.heroicDex = safe_num(function() return me.HeroicDEX() end, function() return me.HDEX() end) or safe_member_num(me, { "HeroicDEX", "HeroicDex", "HDEX", "HeroicDexterity" })
    stats.heroicWis = safe_num(function() return me.HeroicWIS() end, function() return me.HWIS() end) or safe_member_num(me, { "HeroicWIS", "HeroicWis", "HWIS", "HeroicWisdom" })
    stats.heroicInt = safe_num(function() return me.HeroicINT() end, function() return me.HINT() end) or safe_member_num(me, { "HeroicINT", "HeroicInt", "HINT", "HeroicIntelligence" })
    stats.heroicCha = safe_num(function() return me.HeroicCHA() end, function() return me.HCHA() end) or safe_member_num(me, { "HeroicCHA", "HeroicCha", "HCHA", "HeroicCharisma" })
    stats.haste = safe_member_num(me, { "Haste" })
    stats.combatEffects = safe_member_num(me, { "CombatEffects" })
    stats.shielding = safe_member_num(me, { "Shielding" })
    stats.avoidance = safe_member_num(me, { "Avoidance" })
    stats.accuracy = safe_member_num(me, { "Accuracy" })
    stats.spellShield = safe_member_num(me, { "SpellShield" })
    stats.dotShielding = safe_member_num(me, { "DoTShielding", "DotShielding" })
    stats.dsMitigation = safe_member_num(me, { "DSMitigation", "DamageShieldMitigation", "DamageshieldMitigation" })
    stats.stunResist = safe_member_num(me, { "StunResist" })
    stats.strikethrough = safe_member_num(me, { "StrikeThrough", "Strikethrough" })
    stats.spellDamage = safe_member_num(me, { "SpellDamage" })
    stats.healAmount = safe_member_num(me, { "HealAmount" })
    pcall(function()
        inventory_stats.merge_into(stats, { open = false })
    end)
    stats.buffs = gather_buffs()
    stats.updated = os.time()
    return stats
end

--- Wallet / DoN totals: alt-currency + matching bag stacks (FindItemCount only).
local function fill_wallet_fields(snap)
    if type(snap) ~= "table" then return snap end
    pcall(function()
        local e = mq.TLO.Me.EbonCrystals()
        if e ~= nil then snap.ebon_crystals = tonumber(e) end
    end)
    pcall(function()
        local p = mq.TLO.Me.Platinum()
        if p ~= nil then snap.platinum = tonumber(p) end
    end)
    pcall(function()
        local t = mq.TLO.Me.AltCurrency('Diamond Coins')
        local n = t and t() or nil
        if n == nil then
            t = mq.TLO.Me.AltCurrency(20)
            n = t and t() or nil
        end
        local alt = n ~= nil and tonumber(n) or nil
        local bag = tonumber(mq.TLO.FindItemCount('=Diamond Coin')()) or 0
        if alt ~= nil then
            snap.diamond_coins = alt + bag
        elseif bag > 0 then
            snap.diamond_coins = bag
        end
    end)
    pcall(function()
        local f = mq.TLO.Me.CurrentFavor()
        if f ~= nil then snap.tribute_favor = tonumber(f) end
    end)
    pcall(function()
        local t = mq.TLO.Me.AltCurrency('Celestial Crests')
        local n = t and t() or nil
        if n == nil then
            t = mq.TLO.Me.AltCurrency('Celestial Crest')
            n = t and t() or nil
        end
        local alt = n ~= nil and tonumber(n) or nil
        local bag = tonumber(mq.TLO.FindItemCount('=Celestial Crest')()) or 0
        if alt ~= nil then
            snap.celestial_crests = alt + bag
        elseif bag > 0 then
            snap.celestial_crests = bag
        end
    end)
    pcall(function()
        local WalletCurrency = require('turbo_lib.wallet_currency')
        local total = WalletCurrency.radiant_total()
        if total ~= nil then snap.radiant_crystals = total end
    end)
    pcall(function()
        local a = mq.TLO.Me.AAPoints()
        if a ~= nil then snap.aa_unspent = tonumber(a) end
    end)
    return snap
end

function M.wallet_signature(snap)
    if type(snap) ~= "table" then return "" end
    return table.concat({
        tostring(snap.platinum or ""),
        tostring(snap.diamond_coins or ""),
        tostring(snap.radiant_crystals or ""),
        tostring(snap.ebon_crystals or ""),
        tostring(snap.tribute_favor or ""),
        tostring(snap.celestial_crests or ""),
        tostring(snap.aa_unspent or ""),
    }, "|")
end

--- Cheap wallet-only gather (no inventory walk). For Fleet $ live refresh.
local function me_class_name()
    local canon = cfg.canonical_class
    local function take(v)
        if canon then return canon(v) end
        return cfg.known_class and cfg.known_class(v) or nil
    end
    local c = take(try_tlo_value(function() return mq.TLO.Me.Class.Name() end))
    if c then return c end
    c = take(try_tlo_value(function() return mq.TLO.Me.Class() end))
    if c then return c end
    c = take(try_tlo_value(function() return mq.TLO.Me.Class.ShortName() end))
    if c then return c end
    -- Never persist "?" — that sentinel made peer BiS paint list.template junk.
    return ""
end

function M.gather_wallet()
    local snap = {
        name = mq.TLO.Me.CleanName() or "?",
        server = mq.TLO.MacroQuest.Server() or "?",
        class = me_class_name(),
        level = mq.TLO.Me.Level() or 0,
        updated = os.time(),
        depth = "wallet",
        proto = CFG.proto,
    }
    fill_wallet_fields(snap)
    return snap
end

--- Compact E3 var payload: t<unix>:p:d:r:f:c:a  (no spaces/pipes)
function M.encode_wallet_e3(snap)
    if type(snap) ~= "table" then return "" end
    local function n(v)
        if v == nil then return "" end
        return tostring(math.floor(tonumber(v) or 0))
    end
    return string.format("t%d:p%s:d%s:r%s:f%s:c%s:a%s",
        tonumber(snap.updated) or os.time(),
        n(snap.platinum), n(snap.diamond_coins), n(snap.radiant_crystals),
        n(snap.tribute_favor), n(snap.celestial_crests), n(snap.aa_unspent))
end

function M.decode_wallet_e3(text)
    text = tostring(text or "")
    if text == "" or text == "NULL" then return nil end
    local map = {}
    for piece in string.gmatch(text, "[^:]+") do
        local k, v = piece:match("^(%a)(.*)$")
        if k then map[k] = v end
    end
    local function num(v)
        if v == nil or v == "" then return nil end
        return tonumber(v)
    end
    local p, d, r, f, c, a = num(map.p), num(map.d), num(map.r), num(map.f), num(map.c), num(map.a)
    if p == nil and d == nil and r == nil and f == nil and c == nil and a == nil then
        return nil
    end
    return {
        updated = num(map.t),
        plat = p,
        dc = d,
        rc = r,
        favor = f,
        crests = c,
        aa = a,
    }
end

local function build_snap(depth, opts)
    opts = opts or {}
    local now = os.time()
    local bank_open = bank_window_open()
    local snap = {
        name = mq.TLO.Me.CleanName() or "?",
        server = mq.TLO.MacroQuest.Server() or "?",
        class = me_class_name(),
        level = mq.TLO.Me.Level() or 0,
        zoneShortName = tostring(try_tlo_value(function() return mq.TLO.Zone.ShortName() end) or ""),
        zoneName = tostring(try_tlo_value(function() return mq.TLO.Zone.Name() end) or ""),
        updated = now,
        seq = next_seq(),
        proto = CFG.proto,
        depth = depth,
        equipped = {},
        bags = {},
        bank = {},
        bankOpen = bank_open,
        bankLive = bank_open,
        bankValid = bank_open,
        bankCapturedAt = bank_open and now or nil,
        bankReason = bank_open and "live" or "bank window closed; cached bank preserved if available",
    }
    -- Wallet extras (cheap TLOs + FindItemCount; not a bag walk).
    fill_wallet_fields(snap)
    pcall(function()
        diag.context("snapshot.inventory", string.format("depth=%s bankOpen=%s scanBank=%s",
            tostring(depth), tostring(bank_open == true), tostring(bank_open == true)))
        diag.time("snapshot.inventory", function()
            for _, slot in ipairs(inventory_slots) do
                local item = mq.TLO.Me.Inventory(slot.id)
                if item and item() then
                    append_item(snap, "equipped", item, "Equipped", slot.name, slot.id, slot.name, depth)
                end
            end
            if depth == "full" then
                local extra_slots = {
                    { key = "food", name = "Food", slotid = -101 },
                    { key = "drink", name = "Drink", slotid = -102 },
                }
                for _, slot in ipairs(extra_slots) do
                    local item = mq.TLO.Me.Inventory(slot.key)
                    if item and item() then
                        append_item(snap, "equipped", item, "Equipped", slot.name, slot.slotid, slot.name, depth)
                    end
                end
            end
            for inv = 23, 34 do
                local pack = mq.TLO.Me.Inventory(inv)
                if pack and pack() then
                    append_item(snap, "bags", pack, "Bags", "Inventory Bag " .. tostring(inv - 22), inv, "Bag", depth)
                    local slots = tonumber(pack.Container()) or 0
                    for i = 1, slots do
                        local it = pack.Item(i)
                        if it and it() then
                            append_item(snap, "bags", it, "Bags", (pack.Name() or ("Bag" .. (inv - 22))) .. " #" .. i, inv, i, depth)
                        end
                    end
                end
            end
            -- Item on cursor is owned (carried) — peer_request mid-swap was
            -- publishing eq/bags without Face Guard and BiS went red.
            do
                local cur = mq.TLO.Cursor
                if cur and cur() then
                    append_item(snap, "bags", cur, "Bags", "Cursor", nil, "Cursor", depth)
                    diag.count("snapshot.cursor_carried")
                end
            end
            if bank_open then
                for b = 1, CFG.max_bank do
                    local bk = mq.TLO.Me.Bank(b)
                    if bk and bk() then
                        append_item(snap, "bank", bk, "Bank", "Bank " .. b, b, 0, depth)
                        if (bk.Container() or 0) > 0 then
                            for i = 1, bk.Container() do
                                local it = bk.Item(i)
                                if it and it() then
                                    append_item(snap, "bank", it, "Bank", (bk.Name() or ("Bank" .. b)) .. " #" .. i, b, i, depth)
                                end
                            end
                        end
                    end
                end
            end
        end)
    end)
    if opts.includeSpells == true then
        pcall(function()
            diag.time("snapshot.spells", function()
                attach_spells(snap)
            end)
        end)
    end
    if opts.skipLockouts ~= true then
        pcall(function()
            diag.time("snapshot.lockouts", function()
                snap.lockouts = require('lockouts').gather_local(false)
            end)
        end)
    end
    if depth == "full" and opts.skipLiveStats ~= true then
        pcall(function()
            diag.time("snapshot.live_stats", function()
                snap.liveStats = gather_live_stats()
            end)
        end)
    end
    return snap
end

local function preserve_cached_bank(snap, cached)
    if type(snap) ~= "table" or snap.bankValid == true then return snap end
    if type(cached) ~= "table" or type(cached.bank) ~= "table" then cached = self_bank_cache end
    if type(cached) ~= "table" or type(cached.bank) ~= "table" then
        pcall(function()
            local store = require('store').Store
            local key = tostring(snap.server or "") .. "_" .. tostring(snap.name or "")
            cached = store and store.get and store.get(key) or nil
        end)
    end
    if type(cached) ~= "table" or type(cached.bank) ~= "table" then return snap end
    if cached.bankValid ~= true and #cached.bank == 0 then return snap end
    snap.bank = cached.bank
    snap.bankValid = true
    snap.bankLive = false
    snap.bankPreserved = true
    snap.bankCapturedAt = tonumber(cached.bankCapturedAt) or tonumber(cached.updated)
    snap.bankReason = "cached; bank window closed"
    return snap
end

local function remember_bank(snap)
    if type(snap) ~= "table" or type(snap.bank) ~= "table" then return end
    if snap.bankValid ~= true and #snap.bank == 0 then return end
    self_bank_cache = {
        bank = snap.bank,
        bankValid = true,
        bankLive = snap.bankLive == true,
        bankCapturedAt = tonumber(snap.bankCapturedAt) or tonumber(snap.updated) or os.time(),
        updated = tonumber(snap.updated) or os.time(),
    }
end

function M.lite_signature(snap)
    if type(snap) ~= "table" then return "" end
    local parts = {}
    local function add_list(list, prefix)
        for _, item in ipairs(list or {}) do
            -- Include qty/slot: Give Now / Stock Up change stacks without moving slots.
            parts[#parts + 1] = string.format(
                "%s:%d:%s:%s:%s:%s:%d",
                prefix,
                tonumber(item.id) or 0,
                tostring(item.name or ""),
                tostring(item.location or ""),
                tostring(item.where or ""),
                tostring(item.slotid or ""),
                math.max(1, math.floor(tonumber(item.qty or item.count) or 1))
            )
            for _, aug in ipairs(item.augs or {}) do
                parts[#parts + 1] = string.format(
                    "a%d:%s",
                    tonumber(aug.index) or 0,
                    aug.empty and "e" or tostring(aug.id or 0)
                )
            end
        end
    end
    add_list(snap.equipped, "eq")
    add_list(snap.bags, "bg")
    add_list(snap.bank, "bn")
    table.sort(parts)
    if snap.spells_sig and snap.spells_sig ~= "" then
        parts[#parts + 1] = "sp:" .. snap.spells_sig
    end
    return table.concat(parts, "\31")
end

-- Adopt an externally-built snap (e.g. fresher Store self from bg cache) into
-- the in-process cache so __self__ views update without a second TLO walk.
function M.adopt(snap)
    if type(snap) ~= "table" then return false end
    if not snap.name or snap.name == "?" then return false end
    local now = os.clock()
    local depth = tostring(snap.depth or "lite")
    local snap_ts = tonumber(snap.inventoryUpdated or snap.updated) or 0
    if depth == "full" then
        self_full_snap = snap
        self_full_time = now
        self_lite_snap = snap
        self_lite_time = now
    else
        self_lite_snap = snap
        self_lite_time = now
        -- cached() prefers full; a fresher lite must not leave a stale full
        -- snap as the Inventory source (qty-only Give Now looked "stuck").
        if self_full_snap then
            local full_ts = tonumber(self_full_snap.inventoryUpdated or self_full_snap.updated) or 0
            if snap_ts >= full_ts then
                self_full_snap = nil
                self_full_time = 0
            end
        end
    end
    remember_bank(snap)
    return true
end

local function list_item_id(it)
    return math.floor(tonumber(it and it.id) or 0)
end

local function list_item_qty(it)
    local q = math.floor(tonumber(it and (it.qty or it.stack or it.count)) or 1)
    if q < 1 then q = 1 end
    return q
end

-- Subtract qty of item_id from a bags/bank list. Prefers where/slotid match.
-- Returns how many were removed.
local function consume_from_list(list, item_id, qty, prefer_where, prefer_slotid)
    if type(list) ~= "table" or item_id <= 0 or qty <= 0 then return 0 end
    local remaining = qty
    local prefer = (prefer_where and prefer_where ~= "")
        or (prefer_slotid ~= nil and tostring(prefer_slotid) ~= "")

    local function pass(strict)
        local i = 1
        while i <= #list and remaining > 0 do
            local it = list[i]
            if list_item_id(it) ~= item_id then
                i = i + 1
            elseif strict then
                local where_ok = (not prefer_where or prefer_where == "")
                    or tostring(it.where or "") == tostring(prefer_where)
                local slot_ok = (prefer_slotid == nil or tostring(prefer_slotid) == "")
                    or tostring(it.slotid or "") == tostring(prefer_slotid)
                if not (where_ok and slot_ok) then
                    i = i + 1
                else
                    local have = list_item_qty(it)
                    if have <= remaining then
                        remaining = remaining - have
                        table.remove(list, i)
                    else
                        local left = have - remaining
                        it.qty = left
                        if it.stack ~= nil then it.stack = left end
                        if it.count ~= nil then it.count = left end
                        remaining = 0
                    end
                end
            else
                local have = list_item_qty(it)
                if have <= remaining then
                    remaining = remaining - have
                    table.remove(list, i)
                else
                    local left = have - remaining
                    it.qty = left
                    if it.stack ~= nil then it.stack = left end
                    if it.count ~= nil then it.count = left end
                    remaining = 0
                end
            end
        end
    end

    if prefer then pass(true) end
    if remaining > 0 then pass(false) end
    return qty - remaining
end

local function stamp_snap_inventory(snap)
    local now = os.time()
    snap.updated = now
    snap.inventoryUpdated = now
    snap.seq = next_seq()
end

-- Optimistic local Give Now / Give To: subtract id/qty from in-memory bags or
-- bank with no TLO walk. UI redraws immediately; bg /tgearbg note reconciles.
-- opts: locationGroup ("bags"|"bank"), where, slotid
function M.apply_local_give_delta(item_id, qty, opts)
    item_id = math.floor(tonumber(item_id) or 0)
    qty = math.floor(tonumber(qty) or 0)
    opts = type(opts) == "table" and opts or {}
    if item_id <= 0 or qty <= 0 then return false end

    local group = tostring(opts.locationGroup or opts.location or "bags"):lower()
    local list_key = (group == "bank") and "bank" or "bags"
    local prefer_where = opts.where
    local prefer_slotid = opts.slotid

    local targets = {}
    if self_full_snap then targets[#targets + 1] = self_full_snap end
    if self_lite_snap and self_lite_snap ~= self_full_snap then
        targets[#targets + 1] = self_lite_snap
    end
    if #targets == 0 then
        local ok_store, store_mod = pcall(require, 'store')
        if ok_store and store_mod and store_mod.Store and store_mod.my_key then
            local s = store_mod.Store.get(store_mod.my_key())
            if type(s) == "table" and type(s[list_key]) == "table" then
                targets[#targets + 1] = s
            end
        end
    end
    if #targets == 0 then return false end

    local any = false
    for _, snap in ipairs(targets) do
        local list = snap[list_key]
        if type(list) == "table" then
            local taken = consume_from_list(list, item_id, qty, prefer_where, prefer_slotid)
            if taken > 0 then
                any = true
                stamp_snap_inventory(snap)
                if list_key == "bank" then
                    snap.bankValid = true
                end
            end
        end
    end
    if not any then return false end

    local clock = os.clock()
    if self_full_snap then self_full_time = clock end
    if self_lite_snap then self_lite_time = clock end
    -- Fresher lite/full bags after qty patch: drop stale full if lite is newer.
    if self_full_snap and self_lite_snap and self_lite_snap ~= self_full_snap then
        local full_ts = tonumber(self_full_snap.inventoryUpdated or self_full_snap.updated) or 0
        local lite_ts = tonumber(self_lite_snap.inventoryUpdated or self_lite_snap.updated) or 0
        if lite_ts > full_ts then
            self_full_snap = nil
            self_full_time = 0
        end
    end

    local best = self_full_snap or self_lite_snap or targets[1]
    if best then
        remember_bank(best)
        pcall(function()
            local store_mod = require('store')
            if store_mod and store_mod.Store and store_mod.Store.put then
                store_mod.Store.put(best, "client")
            end
        end)
    end
    diag.count("snapshot.local_give_delta")
    return true
end

function M.gather(arg)
    local opts = normalize_opts(arg)
    local force = opts.force == true
    local depth = opts.depth or M.depth_for_settings()
    local include_spells = opts.includeSpells == true
    if depth ~= "full" then depth = "lite" end
    diag.context("snapshot.gather", string.format("force=%s depth=%s includeSpells=%s skipLockouts=%s skipLiveStats=%s",
        tostring(force), tostring(depth), tostring(include_spells),
        tostring(opts.skipLockouts == true), tostring(opts.skipLiveStats == true)))

    local now = os.clock()
    -- force=true must always re-walk TLOs (post-trade / inventory_watch).
    if not force and not include_spells and depth == "lite" and self_full_snap
        and (now - self_full_time) < (tonumber(CFG.self_cache_lite_s) or 8.0) then
        return self_full_snap
    end

    local cache_snap = depth == "full" and self_full_snap or self_lite_snap
    local cache_time = depth == "full" and self_full_time or self_lite_time
    local cache_s = depth == "full"
        and (tonumber(CFG.self_cache_full_s) or 5.0)
        or (tonumber(CFG.self_cache_lite_s) or 8.0)

    if not force and cache_snap and (now - cache_time) < cache_s
        and (not include_spells or (cache_snap.spells_sig and cache_snap.spells_sig ~= "")) then
        return cache_snap
    end

    -- Coalesce burst force gathers (startup / peer_request). inventory_watch sets noCoalesce.
    -- Snapshots are read-only by contract; coalesce returns a shallow copy so
    -- callers cannot corrupt last_force_snap via top-level field writes.
    local coalesce_s = tonumber(CFG.perf_force_gather_coalesce_s) or 2.5
    local bank_live_now = bank_window_open()
    local bank_live_cached = last_force_snap and last_force_snap.bankLive == true
    if force and perf_snapshot_cache_on() and opts.noCoalesce ~= true
        and last_force_snap and last_force_depth == depth
        and coalesce_s > 0 and (now - last_force_time) < coalesce_s
        and bank_live_now == bank_live_cached then
        local out = shallow_copy_snap(last_force_snap)
        if include_spells then
            pcall(function()
                diag.time("snapshot.spells", function()
                    attach_spells(out)
                end)
            end)
            -- Keep cache spell fields warm without exposing the cache table.
            last_force_snap.spells = out.spells
            last_force_snap.spell_ids = out.spell_ids
            last_force_snap.spells_sig = out.spells_sig
        end
        diag.count("snapshot.force_coalesced")
        diag.event("snapshot.gather", string.format(
            "force=true coalesced depth=%s age=%.2fs eq=%d bag=%d bankLive=%s",
            tostring(depth), now - last_force_time,
            #(out.equipped or {}), #(out.bags or {}), tostring(bank_live_cached)))
        return out
    end

    local snap = diag.time("snapshot.gather", function() return build_snap(depth, opts) end)
    snap = preserve_cached_bank(snap, cache_snap)
    remember_bank(snap)
    diag.event("snapshot.gather", string.format("force=%s depth=%s eq=%d bag=%d bank=%d bankOpen=%s bankLive=%s bankPreserved=%s",
        tostring(force), tostring(depth), #(snap.equipped or {}), #(snap.bags or {}), #(snap.bank or {}),
        tostring(snap.bankOpen == true), tostring(snap.bankLive == true), tostring(snap.bankPreserved == true)))
    if depth == "full" then
        self_full_snap = snap
        self_full_time = now
        self_lite_snap = snap
        self_lite_time = now
    else
        self_lite_snap = snap
        self_lite_time = now
    end
    if force then
        last_force_snap = snap
        last_force_time = now
        last_force_depth = depth
    end
    return snap
end

function M.ensure_full()
    local snap = self_full_snap
    local now = os.clock()
    local cache_s = tonumber(CFG.self_cache_full_s) or 5.0
    if snap and snap.depth == "full" and (now - self_full_time) < cache_s then
        return snap
    end
    return M.gather({ force = true, depth = "full" })
end

function M.lite_age()
    if not self_lite_snap or not self_lite_time or self_lite_time <= 0 then return nil end
    return os.clock() - self_lite_time
end

return M
