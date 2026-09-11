-- Run from repo root: luajit lua/tests/turbogear_local_needs_shadow_test.lua
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

package.preload['bis'] = function() error("local_needs must not require bis") end
package.preload['bis_catalog'] = function() error("local_needs must not require bis_catalog") end
package.preload['store'] = function() error("local_needs must not require store") end
package.preload['snapshot'] = function() error("local_needs must not require snapshot") end
package.preload['items'] = function() error("local_needs must not require items") end
package.preload['inventory_stats'] = function() error("local_needs must not require inventory_stats") end
package.preload['focus_extract'] = function() error("local_needs must not require focus_extract") end

local ownership_index = require('ownership_index')
local local_needs = require('local_needs')

local pass, fail = 0, 0
local function check(cond, msg)
    if cond then pass = pass + 1 else fail = fail + 1; print("  FAIL: " .. tostring(msg)) end
end

local function cand(fields)
    fields = fields or {}
    fields.kind = fields.kind or "builtin"
    fields.eval_path = fields.eval_path or (fields.kind == "user" and "user_entry" or "built_in_slot")
    fields.list_id = fields.list_id or "preanguish"
    fields.list_name = fields.list_name or "Pre-Raid"
    fields.slot = fields.slot or (fields.entry and fields.entry.slot) or "Primary"
    fields.link_matched = fields.link_matched == true
    fields.entry = fields.entry or {
        item = fields.item or "Test Sword",
        names = fields.names or { fields.item or "Test Sword" },
        ids = fields.ids or { fields.id or 1001 },
        slot = fields.slot or "Primary",
    }
    return fields
end

local function state_for(snap, candidates, extra)
    extra = extra or {}
    return local_needs.build_local_state({
        identity = extra.identity or { name = "Tester", server = "Srv", class = "Warrior", local_owner = false },
        freshness = extra.freshness or { updated = 1, bankValid = true },
        ownership = ownership_index.build_snapshot_index(snap or { equipped = {}, bags = {}, bank = {} }),
        candidates = candidates or {},
        live_provider = extra.live_provider,
        peer_freshness_provider = extra.peer_freshness_provider,
    })
end

local empty_snap = { equipped = {}, bags = {}, bank = {} }

local s = state_for(empty_snap, { cand({ item = "Exact Blade", id = 111 }) })
local r = local_needs.evaluate_link(s, { name = "Exact Blade", id = 0 })
check(r.need == true and r.reason == "need", "exact name missing is need")

s = state_for(empty_snap, { cand({ item = "ID Blade", id = 222, names = { "Other Name" } }) })
r = local_needs.evaluate_link(s, { name = "Bad Parse Name", id = 222 })
check(r.need == true and r.matched == true, "item id match works")

s = state_for(empty_snap, { cand({ item = "Correct Name", id = 333 }) })
r = local_needs.evaluate_link(s, { name = "Correct Name", id = 999999 })
check(r.need == true, "bad id with correct name still matches")

s = state_for(empty_snap, { cand({ item = "Fire Fungus of Suffering - Tier IV", names = {
    "Fire Fungus of Suffering - Tier IV",
    "Fire Slime of Suffering",
} }) })
r = local_needs.evaluate_link(s, { name = "Fire Slime of Suffering", id = 0 })
check(r.need == true, "equivalent/fungal alias candidate matches")

s = state_for(empty_snap, { cand({ item = "Jonas Dagmire's Triquetrum", names = {
    "Jonas Dagmire's Triquetrum",
    "Triquetrum",
} }) })
r = local_needs.evaluate_link(s, { name = "Triquetrum", id = 0 })
check(r.need == true, "Jonas alias candidate matches")

s = state_for(empty_snap, { cand({ list_id = "jonas", slot = "Frenzied Ghoul (GukBottom)",
    item = "Little Finger Metacarpal",
    names = { "Little Finger Metacarpal", "Jonas Dagmire's Little Finger Metacarpal" },
    ids = { 33170, 33171, 33175 },
}) })
r = local_needs.evaluate_link(s, { name = "Jonas Dagmire's Little Finger Metacarpal", id = 0 })
check(r.need == true, "Jonas Little Finger missing remains need")

s = state_for({ equipped = {}, bags = { { name = "Later Jonas Little Completion", id = 33175 } }, bank = {} },
    { cand({ list_id = "jonas", slot = "Frenzied Ghoul (GukBottom)",
        item = "Little Finger Metacarpal",
        names = { "Little Finger Metacarpal", "Jonas Dagmire's Little Finger Metacarpal" },
        ids = { 33170, 33171, 33175 },
    }) })
r = local_needs.evaluate_link(s, { name = "Jonas Dagmire's Little Finger Metacarpal", id = 0 })
check(r.need == false and r.reason == "owned", "Jonas Little Finger satisfied by later completion id")

s = state_for({ equipped = {}, bags = { { name = "Later Jonas Forefinger Completion", id = 33171 } }, bank = {} },
    { cand({ list_id = "jonas", slot = "Spectres (Oasis)",
        item = "Forefinger Metacarpal",
        names = { "Forefinger Metacarpal", "Jonas Dagmire's Forefinger Metacarpal" },
        ids = { 33168, 33169, 33170, 33171, 33173 },
    }) })
r = local_needs.evaluate_link(s, { name = "Jonas Dagmire's Forefinger Metacarpal", id = 0 })
check(r.need == false and r.reason == "owned", "Jonas Forefinger satisfied by later completion id")

s = state_for(empty_snap, { cand({ list_id = "don", item = "Ancient Teaching", names = {
    "Ancient Teaching",
    "Source Container",
} }) })
r = local_needs.evaluate_link(s, { name = "Source Container", id = 0 })
check(r.need == true, "DoN compact alias candidate matches")

s = state_for(empty_snap, { cand({ list_id = "bagitems", item = "Adventurer's Tattered Sack (Celestial)", names = {
    "Adventurer's Tattered Sack (Celestial)",
    "Master Tailor's Celestial Lining (T5 Trash)",
} }) })
r = local_needs.evaluate_link(s, { name = "Master Tailor's Celestial Lining (T5 Trash)", id = 0 })
check(r.need == true, "bag chain compact alias candidate matches")

s = state_for(empty_snap, {
    cand({ item = "Slot Ring", slot = "Left Finger", id = 444 }),
    cand({ item = "Slot Ring", slot = "Right Finger", id = 444 }),
})
r = local_needs.evaluate_link(s, { name = "Slot Ring", id = 444 })
check(r.need == true and r.candidate.slot == "Left Finger", "multi-slot preserves candidate order/context")

s = state_for({ equipped = { { name = "Owned Worn", id = 501, augs = {} } }, bags = {}, bank = {} },
    { cand({ item = "Owned Worn", id = 501 }) })
r = local_needs.evaluate_link(s, { name = "Owned Worn", id = 501 })
check(r.need == false and r.status == "equipped", "owned worn suppresses need")

s = state_for({ equipped = {}, bags = { { name = "Owned Bag", id = 502, augs = {} } }, bank = {} },
    { cand({ item = "Owned Bag", id = 502 }) })
r = local_needs.evaluate_link(s, { name = "Owned Bag", id = 502 })
check(r.need == false and r.status == "carried", "owned bag suppresses need")

s = state_for({ equipped = {}, bags = {}, bank = { { name = "Owned Bank", id = 503, augs = {} } }, bankPreserved = true },
    { cand({ item = "Owned Bank", id = 503 }) },
    { freshness = { bankPreserved = true, bankValid = true } })
r = local_needs.evaluate_link(s, { name = "Owned Bank", id = 503 })
check(r.need == false and r.status == "carried", "owned preserved bank suppresses need")

s = state_for({ equipped = { { name = "Host", id = 600, augs = { { name = "Owned Aug", id = 601, index = 1 } } } }, bags = {}, bank = {} },
    { cand({ item = "Owned Aug", id = 601 }) })
r = local_needs.evaluate_link(s, { name = "Owned Aug", id = 601 })
check(r.need == false and r.status == "equipped", "owned aug suppresses need")

s = state_for({ equipped = {}, bags = {}, bank = {}, spells = { ["Known Spell"] = { name = "Known Spell", book = true, id = 7001 } } },
    { cand({ item = "Spell Scroll", id = 701, entry = {
        item = "Spell Scroll",
        names = { "Spell Scroll" },
        ids = { 701 },
        spell = "Known Spell",
        spells = { "Known Spell" },
        spell_ids = { 7001 },
    } }) })
r = local_needs.evaluate_link(s, { name = "Spell Scroll", id = 701 })
check(r.need == false and r.status == "known", "spell-aware row suppresses need when spell known")

s = state_for(empty_snap, { cand({ item = "Disabled Item", id = 901, enabled = false }) })
r = local_needs.evaluate_link(s, { name = "Disabled Item", id = 901 })
check(r.need == false and r.reason == "no-row", "disabled announce candidate skipped")

s = state_for(empty_snap, { cand({ item = "Live Owned", id = 10001 }) }, {
    identity = { name = "Tester", server = "Srv", class = "Warrior", local_owner = true },
    live_provider = function() return "carried" end,
})
r = local_needs.evaluate_link(s, { name = "Live Owned", id = 10001 })
check(r.need == false and r.live_used == true and r.reason == "owned-live", "injected local live provider can suppress need")

s = state_for(empty_snap, { cand({ item = "Live Diff", id = 10002 }) }, {
    identity = { name = "Tester", server = "Srv", class = "Warrior", local_owner = true },
    live_provider = function() return nil end,
})
r = local_needs.evaluate_link(s, { name = "Live Diff", id = 10002 })
check(local_needs.classify_mismatch({ need = false, reason = "owned" }, r, s, { name = "Live Diff", id = 10002 }) == "local-live-fallback",
    "local live mismatch classified")

s = state_for(empty_snap, { cand({ kind = "builtin", item = "Peer Fresh", id = 10003 }) }, {
    identity = { name = "Peer", server = "Srv", class = "Warrior", local_owner = false },
})
r = local_needs.evaluate_link(s, { name = "Peer Fresh", id = 10003 })
check(local_needs.classify_mismatch({ need = false, reason = "owned" }, r, s, { name = "Peer Fresh", id = 10003 }) == "peer-live/bis_search-freshness",
    "peer bis_search freshness mismatch classified")

s = state_for(empty_snap, { cand({ kind = "builtin", list_id = "jonas", slot = "Elite Gnolls", item = "Peer Slot Fresh", id = 100031 }) }, {
    identity = { name = "Peer", server = "Srv", class = "Berserker", local_owner = false },
    peer_freshness_provider = function(candidate)
        if candidate.list_id == "jonas" and candidate.slot == "Elite Gnolls" then
            return { status = "carried", name = "Peer Slot Fresh", count = 1, location = "Bags" }
        end
    end,
})
r = local_needs.evaluate_link(s, { name = "Peer Slot Fresh", id = 100031 })
check(r.need == false and r.reason == "owned-peer-fresh" and r.peer_fresh_used == true,
    "peer freshness slot record satisfies generated built-in candidate")

s = state_for(empty_snap, { cand({ kind = "builtin", list_id = "jonas", slot = "Frenzied Ghoul", item = "Peer Slot Missing", id = 100032 }) }, {
    identity = { name = "Peer", server = "Srv", class = "Berserker", local_owner = false },
    peer_freshness_provider = function()
        return { status = "missing", name = "Peer Slot Missing", count = 0, location = "" }
    end,
})
r = local_needs.evaluate_link(s, { name = "Peer Slot Missing", id = 100032 })
check(r.need == true and r.peer_fresh_used == true,
    "peer freshness missing slot remains need")

s = state_for({ bags = { { name = "Peer Snapshot Fallback", id = 100033 } }, equipped = {}, bank = {} },
    { cand({ kind = "builtin", list_id = "jonas", slot = "Fallback", item = "Peer Snapshot Fallback", id = 100033 }) }, {
    identity = { name = "Peer", server = "Srv", class = "Berserker", local_owner = false },
    peer_freshness_provider = function() return nil end,
})
r = local_needs.evaluate_link(s, { name = "Peer Snapshot Fallback", id = 100033 })
check(r.need == false and r.reason == "owned" and r.peer_fresh_used ~= true,
    "missing peer freshness record falls back to compact snapshot ownership")

s = state_for(empty_snap, { cand({ item = "Stale Item", id = 10004 }) }, {
    freshness = { inventoryIncomplete = true },
})
r = local_needs.evaluate_link(s, { name = "Stale Item", id = 10004 })
check(local_needs.classify_mismatch({ need = false, reason = "owned" }, r, s, { name = "Stale Item", id = 10004 }) == "stale-or-incomplete-input",
    "stale/incomplete mismatch classified")

s = state_for(empty_snap, { cand({ item = "Other", id = 1, link_matched = false }) })
r = local_needs.evaluate_link(s, { name = "No Candidate", id = 2 })
check(local_needs.classify_mismatch({ need = true, reason = "need" }, r, s, { name = "No Candidate", id = 2 }) == "normalization/key",
    "normalization/key mismatch classified")

s = state_for(empty_snap, {
    cand({ list_id = "preanguish", item = "Shared Drop", id = 11001 }),
    cand({ list_id = "sebilis", item = "Shared Drop", id = 11001 }),
})
r = local_needs.evaluate_link(s, { name = "Shared Drop", id = 11001 })
check(r.need == true and r.candidate.list_id == "preanguish", "same item across built-in lists needs first missing candidate")

s = state_for(empty_snap, {
    cand({ list_id = "preanguish", item = "Hybrid Drop", id = 11002 }),
    cand({ list_id = "anguish", item = "Hybrid Drop", id = 11002 }),
})
r = local_needs.evaluate_link(s, { name = "Hybrid Drop", id = 11002 })
check(r.need == true and r.candidate.list_id == "preanguish", "multiple built-in matches keep first missing candidate")

s = state_for({ bags = { { name = "Owned Match", id = 11003 } }, equipped = {}, bank = {} }, {
    cand({ list_id = "owned_list", item = "Owned Match", names = { "Owned Match" }, id = 11003 }),
    cand({ list_id = "missing_list", item = "Missing Match", names = { "Missing Match" }, id = 11004 }),
})
r = local_needs.evaluate_link(s, { name = "Missing Match", id = 11003 })
check(r.need == true and r.candidate.list_id == "missing_list", "one owned match does not suppress a later missing matching row")

s = state_for({ bags = { { name = "Alias Owned", id = 11005 } }, equipped = {}, bank = {} }, {
    cand({ list_id = "alias_owned", item = "Alias Owned", names = { "Alias Owned" }, id = 11005 }),
    cand({ list_id = "alias_missing", item = "Alias Missing", names = { "Alias Missing", "Alias Linked" }, id = 11007 }),
})
r = local_needs.evaluate_link(s, { name = "Alias Linked", id = 11005 })
check(r.need == true and r.candidate.list_id == "alias_missing", "equivalent alias across multiple lists needs if any alias row is missing")

s = state_for({ equipped = { { name = "Duplicate Name", id = 12001 } }, bags = {}, bank = {} }, {
    cand({ list_id = "id_owned", item = "Duplicate Name", names = { "Duplicate Name" }, id = 12001 }),
    cand({ list_id = "id_missing", item = "Duplicate Name", names = { "Duplicate Name" }, id = 12002 }),
})
r = local_needs.evaluate_link(s, { name = "Duplicate Name", id = 12002 })
check(r.need == false and r.status == "equipped", "duplicate normalized names with different ids follow current name-owned semantics")

print(string.format("local needs shadow: %d passed, %d failed", pass, fail))
os.exit(fail == 0 and 0 or 1)
