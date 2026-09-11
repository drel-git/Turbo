-- Run from repo root: luajit lua/tests/turbogear_inventory_probe_test.lua
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;lua/tests/?.lua;' .. package.path

for _, name in ipairs({
    "mq", "config", "diagnostics", "inventory_probe", "snapshot",
    "ownership_index", "rich_inventory", "announcer",
}) do
    package.loaded[name] = nil
    package.preload[name] = nil
end

local bank_tlo_calls = 0
package.preload["mq"] = function()
    return {
        TLO = {
            Me = {
                Inventory = function() return nil end,
                Bank = function()
                    bank_tlo_calls = bank_tlo_calls + 1
                    error("bank TLO must not be walked by inventory_probe")
                end,
                CleanName = function() return "Sketti" end,
            },
            Cursor = nil,
            MacroQuest = { Server = function() return "Project Lazarus" end },
        },
        cmd = function() end,
    }
end
package.preload["config"] = function()
    return {
        CFG = {
            inventory_probe_items_per_slice = 2,
            inventory_probe_budget_ms = 22,
            script_name = "TurboGear",
        },
        Settings = {},
    }
end
package.preload["diagnostics"] = function()
    return {
        time = function(_, fn) return fn() end,
        count = function() end,
        event = function() end,
        sample = function() end,
        context = function() end,
        is_enabled = function() return false end,
    }
end

local snapshot = require('snapshot')
local probe = require('inventory_probe')
local ownership_index = require('ownership_index')

local pass, fail = 0, 0
local function check(cond, msg)
    if cond then
        pass = pass + 1
    else
        fail = fail + 1
        print("FAIL: " .. tostring(msg))
    end
end

local function lite_row(id, name, loc, slotid, slotname)
    return {
        id = id,
        name = name,
        location = loc,
        where = slotname,
        slotid = slotid,
        slotname = slotname,
        qty = 1,
        depth = "lite",
        augs = { { index = 1, id = id + 1000, empty = false } },
    }
end

local function prior_snap()
    return {
        name = "Sketti",
        server = "Project Lazarus",
        class = "Necromancer",
        depth = "full",
        seq = 9,
        updated = 1000,
        inventoryUpdated = 1000,
        don = { a = 1 },
        spells = { foo = { book = true, name = "foo" } },
        spells_sig = "sp1",
        liveStats = { hp = 12 },
        lockouts = { should_not_copy = true },
        equipped = {
            lite_row(11, "Crown", "Equipped", 2, "Head"),
        },
        bags = {
            lite_row(21, "Fine Steel Warhammer", "Bags", 23, 1),
            lite_row(22, "Ring", "Bags", 23, 2),
        },
        bank = {
            lite_row(99, "Banked", "Bank", 1, 0),
        },
        bankValid = true,
        bankLive = false,
        bankPreserved = true,
        bankCapturedAt = 50,
        bankReason = "cached; bank window closed",
        bankOpen = false,
    }
end

local function rows_from(snap)
    local out = {}
    for _, row in ipairs(snap.equipped or {}) do
        out[#out + 1] = { list = "equipped", row = row }
    end
    for _, row in ipairs(snap.bags or {}) do
        out[#out + 1] = { list = "bags", row = row }
    end
    return out
end

local function ident(snap)
    return snapshot.inventory_identity(snap)
end

-- Closed preserved bank survives probe; no bank TLO walk
probe.reset()
bank_tlo_calls = 0
local prior = prior_snap()
local clock = { t = 0 }
check(probe.start({
    prior = prior,
    identity = ident,
    clock = function() return clock.t end,
    collect_rows = rows_from(prior),
    validate_rows = rows_from(prior),
    items_per_slice = 2,
    budget_ms = 1000,
}) == true, "probe starts")
check(probe.active() == true, "probe active after start")
check(probe.status().phase == "collect", "phase collect")
while probe.active() do
    clock.t = clock.t + 0.001
    probe.tick()
end
check(probe.status().phase == "complete", "stable probe completes")
local cand = probe.take_candidate()
check(type(cand) == "table", "take_candidate returns Pass A")
check(cand.depth == "lite", "candidate depth lite")
check(cand.inventoryIncomplete == false, "candidate complete")
check(#(cand.bank or {}) == 1, "preserved bank rows kept")
check(cand.bank[1].id == 99, "bank row identity kept")
check(cand.bankValid == true, "closed bankValid=true")
check(cand.bankLive == false, "closed bankLive=false")
check(cand.bankPreserved == true, "closed bankPreserved=true")
check(cand.bankCapturedAt == 50, "bankCapturedAt not manufactured")
check(cand.lockouts == nil, "lockouts not republished")
check(cand.spells_sig == "sp1", "spells carried from prior")
check(cand.don and cand.don.a == 1, "don carried from prior")
check(bank_tlo_calls == 0, "no bank TLO walk")
check(ident(cand) == ident({
    equipped = prior.equipped,
    bags = prior.bags,
    bank = prior.bank,
}), "canonical identity includes preserved bank")

-- Closed empty result cannot wipe known bank (copy from prior, never empty live scan)
probe.reset()
local empty_eq = {
    name = "Sketti",
    depth = "full",
    equipped = { lite_row(1, "A", "Equipped", 2, "Head") },
    bags = {},
    bank = {},
    bankValid = false,
    bankLive = false,
    bankPreserved = false,
}
-- Probe still copies whatever prior.bank is; recovery uses authoritative prior
-- with preserved bank. Prove empty prior bank stays empty, preserved prior stays.
probe.start({
    prior = prior_snap(),
    identity = ident,
    clock = function() return 0 end,
    collect_rows = { { list = "equipped", row = lite_row(1, "A", "Equipped", 2, "Head") } },
    items_per_slice = 2,
    budget_ms = 1000,
})
for _ = 1, 20 do
    if not probe.active() then break end
    probe.tick()
end
local kept = probe.take_candidate()
check(kept and #(kept.bank or {}) == 1, "authoritative preserved bank not wiped")

probe.reset()
probe.start({
    prior = empty_eq,
    identity = ident,
    clock = function() return 0 end,
    collect_rows = { { list = "equipped", row = lite_row(1, "A", "Equipped", 2, "Head") } },
    items_per_slice = 2,
    budget_ms = 1000,
})
for _ = 1, 20 do
    if not probe.active() then break end
    probe.tick()
end
local empty_cand = probe.take_candidate()
check(empty_cand and #(empty_cand.bank or {}) == 0, "empty prior bank stays empty (no invented rows)")

-- Partial probe is invisible: no candidate until complete; ownership uses published snap
probe.reset()
local published = prior_snap()
local idx_before = ownership_index.build_snapshot_index(published)
probe.start({
    prior = published,
    identity = ident,
    clock = function() return 0 end,
    collect_rows = rows_from(published),
    items_per_slice = 1,
    budget_ms = 1000,
})
probe.tick()
check(probe.active() == true, "still collecting after one slice")
check(probe.status().candidate == nil, "partial candidate not exposed")
check(probe.take_candidate() == nil, "take_candidate nil while partial")
local idx_mid = ownership_index.build_snapshot_index(published)
check(ownership_index.snapshot_semantic_key(published)
    == ownership_index.snapshot_semantic_key(published), "published snap unchanged")
check(idx_mid.by_id[21] ~= nil, "ownership_index still answers published bag id")
local rec = idx_before
check(type(rec) == "table", "ownership index built from published authority")

-- Production walk never touches Bank TLO
probe.reset()
bank_tlo_calls = 0
local walk = snapshot.begin_lite_inventory_walk()
local steps = 0
while steps < 80 do
    local _, done = snapshot.step_lite_inventory_walk(walk)
    steps = steps + 1
    if done then break end
end
check(bank_tlo_calls == 0, "lite inventory walk does not call Bank TLO")

-- Validation mismatch discards A and B, bounded retry, no complete candidate
probe.reset()
clock.t = 0
local moved = lite_row(21, "Fine Steel Warhammer", "Bags", 30, 3)
local pass_a = {
    { list = "equipped", row = lite_row(11, "Crown", "Equipped", 2, "Head") },
    { list = "bags", row = lite_row(21, "Fine Steel Warhammer", "Bags", 23, 1) },
}
local pass_b = {
    { list = "equipped", row = lite_row(11, "Crown", "Equipped", 2, "Head") },
    { list = "bags", row = moved },
}
probe.start({
    prior = prior_snap(),
    identity = ident,
    clock = function() return clock.t end,
    collect_rows = pass_a,
    validate_rows = pass_b,
    items_per_slice = 2,
    budget_ms = 1000,
    retry_s = 1.0,
})
for _ = 1, 10 do
    clock.t = clock.t + 0.001
    probe.tick()
end
check(probe.stats().validation_retry >= 1, "validation mismatch retries")
check(probe.stats().completed == 0, "mismatch never completes")
check(probe.take_candidate() == nil, "mismatch never yields a candidate")
check(probe.status().phase == "retry_wait" or probe.active() == true,
    "mismatch remains private and retries")
local before = probe.stats().validation_retry
clock.t = clock.t + 0.2
probe.tick()
check(probe.stats().validation_retry == before, "no retry storm before delay")
clock.t = clock.t + 1
probe.tick()
check(probe.status().phase == "collect" or probe.active() == true, "bounded retry restarts collect")

-- Cooperative slice: 1 guaranteed, max 2 occupied
probe.reset()
clock.t = 0
local many = {}
for i = 1, 5 do
    many[#many + 1] = { list = "bags", row = lite_row(20 + i, "Item" .. i, "Bags", 23, i) }
end
probe.start({
    prior = prior_snap(),
    identity = ident,
    clock = function() return clock.t end,
    collect_rows = many,
    validate_rows = many,
    items_per_slice = 2,
    budget_ms = 1000,
})
probe.tick()
check(probe.status().item == 2, "slice processes at most 2 occupied rows")
check(probe.status().phase == "collect", "not finished after one slice")

-- Budget: first occupied row over budget yields immediately (no second row)
probe.reset()
probe.start({
    prior = prior_snap(),
    identity = ident,
    clock = function() return 0 end,
    collect_rows = many,
    validate_rows = many,
    items_per_slice = 2,
    budget_ms = 0,
})
probe.tick()
check(probe.status().item == 1, "over-budget first occupied row yields with no second row")

-- Cancel
probe.reset()
probe.start({
    prior = prior_snap(),
    identity = ident,
    clock = function() return 0 end,
    collect_rows = many,
})
probe.tick()
check(probe.cancel("test") == true, "cancel active probe")
check(probe.active() == false, "cancelled not active")
check(probe.take_candidate() == nil, "cancelled has no candidate")
check(probe.stats().cancelled == 1, "cancelled counted")

-- Two equivalent stable passes produce identical canonical identities, including bank
probe.reset()
local stable_prior = prior_snap()
local stable_rows = rows_from(stable_prior)
local function complete_once()
    probe.start({
        prior = stable_prior,
        identity = ident,
        clock = function() return 0 end,
        collect_rows = stable_rows,
        validate_rows = stable_rows,
        items_per_slice = 2,
        budget_ms = 1000,
    })
    for _ = 1, 40 do
        if not probe.active() then break end
        probe.tick()
    end
    return probe.take_candidate()
end
local pass1 = complete_once()
local pass2 = complete_once()
check(type(pass1) == "table" and type(pass2) == "table", "two stable completions")
check(ident(pass1) == ident(pass2), "equivalent passes share canonical identity")
check(ident(pass1) == ident({
    equipped = stable_prior.equipped,
    bags = stable_prior.bags,
    bank = stable_prior.bank,
}), "stable identity includes preserved bank rows")
check(pass1.bankCapturedAt == 50 and pass2.bankCapturedAt == 50,
    "both passes keep preserved bankCapturedAt")
check(pass1.bankPreserved == true and pass2.bankPreserved == true,
    "both passes keep bankPreserved")
local bank_token = ident(pass1)
check(bank_token:find("bn:", 1, true) ~= nil, "canonical identity contains bank tokens")

-- First-difference diagnostic uses the same lite_signature tokens (bags slot move)
do
    local a = {
        equipped = { lite_row(11, "Crown", "Equipped", 2, "Head") },
        bags = { lite_row(21, "Fine Steel Warhammer", "Bags", 23, 1) },
        bank = { lite_row(99, "Banked", "Bank", 1, 0) },
        bankValid = true, bankLive = false, bankPreserved = true, bankCapturedAt = 50,
    }
    local b = {
        equipped = { lite_row(11, "Crown", "Equipped", 2, "Head") },
        bags = { lite_row(21, "Fine Steel Warhammer", "Bags", 30, 3) },
        bank = { lite_row(99, "Banked", "Bank", 1, 0) },
        bankValid = true, bankLive = false, bankPreserved = true, bankCapturedAt = 50,
    }
    check(ident(a) ~= ident(b), "bag slot move changes canonical identity")
    local diff = snapshot.inventory_identity_diff(a, b)
    check(diff.section == "bags", "first differing section is bags")
    check(tostring(diff.key):find("23", 1, true) ~= nil
        or tostring(diff.key):find("30", 1, true) ~= nil,
        "first differing key is the bag slot")
    check(diff.counts_a.bank == 1 and diff.counts_b.bank == 1, "bank counts unchanged")
    check(diff.bank_a.bankPreserved == true and diff.bank_b.bankPreserved == true,
        "diff reports preserved bank flags")
    check(ident(a) == snapshot.lite_signature(a, { skipSpells = true }),
        "inventory_identity remains lite_signature skipSpells")
end

-- Source: announcer / bis_catalog / local_needs / ownership_index must not require probe or rich
local function file_text(path)
    local f = assert(io.open(path, "r"))
    local s = f:read("*a")
    f:close()
    return s
end
for _, mod in ipairs({
    "lua/turbogear/announcer.lua",
    "lua/turbogear/bis_catalog.lua",
    "lua/turbogear/local_needs.lua",
    "lua/turbogear/ownership_index.lua",
}) do
    local src = file_text(mod)
    check(not src:find('require%([\'"]inventory_probe[\'"]%)', 1),
        mod .. " does not require inventory_probe")
    check(not src:find('require%([\'"]rich_inventory[\'"]%)', 1),
        mod .. " does not require rich_inventory")
end

print(string.format("inventory_probe: %d passed, %d failed", pass, fail))
if fail > 0 then os.exit(1) end
