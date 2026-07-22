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

function M.invalidate()
    self_lite_snap, self_lite_time = nil, 0
    self_full_snap, self_full_time = nil, 0
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
    local value = try_tlo_value(function() return mq.TLO.Window("BigBankWnd").Open() end)
    if value == true or tostring(value):lower() == "true" then return true end
    value = try_tlo_value(function() return mq.TLO.Window("BankWnd").Open() end)
    return value == true or tostring(value):lower() == "true"
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
function M.gather_wallet()
    local snap = {
        name = mq.TLO.Me.CleanName() or "?",
        server = mq.TLO.MacroQuest.Server() or "?",
        class = mq.TLO.Me.Class.Name() or "?",
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
        class = mq.TLO.Me.Class.Name() or "?",
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
                local spell_snap = require('spell_snapshot')
                local spells, spell_ids = spell_snap.gather(snap.class)
                snap.spells = spells
                snap.spell_ids = spell_ids
                snap.spells_sig = spell_snap.signature(snap.spells)
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
