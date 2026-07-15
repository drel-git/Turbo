-- Run from repo root:  luajit lua\tests\turbogear_needs_index_test.lua
-- Tests the pure core of the inverted needs index. Runtime deps are stubbed so
-- the module loads outside MacroQuest.
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

package.preload['mq'] = function()
    return {
        TLO = {
            Me = { CleanName = function() return "Tester" end },
            MacroQuest = { Server = function() return "Srv" end },
        },
    }
end
package.preload['config'] = function()
    return { CFG = {}, Settings = {}, SharedSettings = {} }
end
package.preload['store'] = function()
    return {
        Store = {
            content_version = 0,
            content_signatures = {},
            peer_keys = function() return {} end,
            get = function() return nil end,
            is_recently_visible = function() return false end,
        },
        my_key = function() return "Srv_Tester" end,
    }
end
package.preload['diagnostics'] = function()
    return {
        time = function(_, fn) return fn() end,
        count = function() end,
        event = function() end,
        context = function() end,
    }
end

local NI = require('needs_index')
local core = NI.core

local passed, failed = 0, 0
local function check(cond, label)
    if cond then
        passed = passed + 1
    else
        failed = failed + 1
        io.stderr:write('FAIL: ', tostring(label), '\n')
    end
end

-- key normalization
check(core.norm_key("  Blade of  War ") == "blade of war", 'norm_key trims/lowers/collapses')
check(core.strip_key("Blade of War (Azia)") == "blade of war", 'strip_key drops parenthetical')
check(core.strip_key("Blade of War 12345") == "blade of war", 'strip_key drops trailing long id')
check(core.strip_key("Ring of Tunare") == "ring of tunare", 'strip_key leaves plain names')

-- build_char_needs: only missing entries are indexed, deduped per entry
local entry_sword = { item = "Blade of War", names = { "Blade of War", "Blade of War (Azia)" }, ids = { 101 } }
local entry_helm  = { item = "Crown of Rile", names = { "Crown of Rile" }, ids = { 202 } }
local entry_owned = { item = "Owned Thing", names = { "Owned Thing" }, ids = { 303 } }
local recs = {
    { entry = entry_sword, item_name = "Blade of War", list_id = "anguish" },
    { entry = entry_sword, item_name = "Blade of War (Azia)", list_id = "anguish" }, -- same entry, alias
    { entry = entry_helm, item_name = "Crown of Rile", list_id = "anguish" },
    { entry = entry_owned, item_name = "Owned Thing", list_id = "anguish" },
}
local statuses = { [entry_sword] = "missing", [entry_helm] = "missing", [entry_owned] = "equipped" }
local needs = core.build_char_needs(recs, function(e) return statuses[e] end)
check(needs.count == 2, 'build: two missing entries indexed')
check(needs.by_id[101] ~= nil and needs.by_id[202] ~= nil, 'build: ids indexed')
check(needs.by_id[303] == nil, 'build: owned entry not indexed')
check(needs.by_name["blade of war"] ~= nil, 'build: name key indexed')
check(needs.by_name["blade of war (azia)"] ~= nil, 'build: alias norm key indexed')

-- merge + query
local chars = {
    ["Srv_Alice"] = { name = "Alice", needs = needs },
    ["Srv_Bob"] = {
        name = "Bob",
        needs = core.build_char_needs(
            { { entry = entry_sword, item_name = "Blade of War", list_id = "anguish" } },
            function() return "missing" end),
    },
}
local merged = core.merge(chars)
check(merged.item_count == 3, 'merge: item_count sums per-char needs')

local needers = core.query(merged, "Blade of War", 101)
check(#needers == 2, 'query by id+name: both needers found')
local names = {}
for _, n in ipairs(needers) do names[n.character] = true end
check(names.Alice and names.Bob, 'query: correct characters')

-- query dedupes when id and name both hit the same character
local needers2 = core.query(merged, "Blade of War (Azia)", 101)
check(#needers2 == 2, 'query: alias + id dedupes per character')

-- query by name only (no id)
local needers3 = core.query(merged, "crown of rile", 0)
check(#needers3 == 1 and needers3[1].character == "Alice", 'query by name only')

-- query misses cleanly
check(#core.query(merged, "Nonexistent Item", 0) == 0, 'query: miss returns empty')
check(#core.query(nil, "x", 1) == 0, 'query: nil merged safe')

-- text_candidates: finds needed names inside chat lines, with needers attached
local hits = core.text_candidates(merged, "Anyone want Blade of War before I vendor it?", 8)
check(#hits == 1, 'text: one needed item found in line')
check(#(hits[1].needers or {}) == 2, 'text: needers attached')
check(hits[1].id == 101, 'text: primary id resolved')

-- text: longest match preferred and limit respected
local entry_long = { item = "Blade of War Ornament", names = { "Blade of War Ornament" }, ids = { 404 } }
chars["Srv_Cara"] = {
    name = "Cara",
    needs = core.build_char_needs(
        { { entry = entry_long, item_name = "Blade of War Ornament", list_id = "dsk" } },
        function() return "missing" end),
}
local merged2 = core.merge(chars)
local hits2 = core.text_candidates(merged2, "selling Blade of War Ornament now", 8)
check(hits2[1] and hits2[1].name == "Blade of War Ornament", 'text: longest name ranked first')

local hits3 = core.text_candidates(merged2, "Blade of War Ornament and Crown of Rile", 1)
check(#hits3 == 1, 'text: limit respected')

-- no needed items in line
check(#core.text_candidates(merged2, "hello there", 8) == 0, 'text: clean line yields nothing')

-- Display-name rules for multi-alias entries (fungal-chain regression):
-- id hits must show the canonical item name; name hits must show the alias
-- that matched, never an arbitrary sibling alias like "... - Tier II".
local entry_slime = {
    item = "Corrosive Slime of Suffering",
    names = {
        "Corrosive Slime of Suffering",
        "Corrosive Fungus of Suffering - Tier II",
        "Corrosive Fungus of Suffering - Final",
    },
    ids = { 909 },
}
local slime_needs = core.build_char_needs(
    { { entry = entry_slime, item_name = "Corrosive Fungus of Suffering - Tier II", list_id = "fungal" } },
    function() return "missing" end)
check(slime_needs.by_id[909].display == "Corrosive Slime of Suffering",
    'alias: id hit displays canonical item name')
check(slime_needs.by_name["corrosive slime of suffering"].display == "Corrosive Slime of Suffering",
    'alias: name key displays its own alias (canonical)')
check(slime_needs.by_name["corrosive fungus of suffering - tier ii"].display == "Corrosive Fungus of Suffering - Tier II",
    'alias: name key displays its own alias (tier)')

local slime_merged = core.merge({ ["Srv_Dee"] = { name = "Dee", needs = slime_needs } })
local slime_by_id = core.query(slime_merged, "", 909)
check(#slime_by_id == 1 and slime_by_id[1].display == "Corrosive Slime of Suffering",
    'alias: id query returns canonical display')
local slime_hits = core.text_candidates(slime_merged, "selling Corrosive Slime of Suffering cheap", 8)
check(#slime_hits == 1 and slime_hits[1].name == "Corrosive Slime of Suffering",
    'alias: text hit shows the name that appeared in the line')

-- Jonas-hand alias pairs: one entry indexed under BOTH "X" and "Jonas
-- Dagmire's X" must yield ONE text hit (displayed under the most specific
-- alias in the line), not a double announce. Regression for the
-- Triquetrum double-[TG] report.
local entry_bone = {
    item = "Triquetrum",
    names = { "Triquetrum", "Jonas Dagmire's Triquetrum" },
    ids = { 33166, 33167 },
}
local bone_needs = core.build_char_needs(
    { { entry = entry_bone, item_name = "Triquetrum", list_id = "jonas" } },
    function() return "missing" end)
check(bone_needs.by_name["triquetrum"] ~= nil
    and bone_needs.by_name["jonas dagmire's triquetrum"] ~= nil,
    'jonas: both alias keys indexed')
local bone_merged = core.merge({ ["Srv_Eve"] = { name = "Eve", needs = bone_needs } })
local bone_hits = core.text_candidates(bone_merged, "check out Jonas Dagmire's Triquetrum wow", 8)
check(#bone_hits == 1, 'jonas: alias pair collapses to one text hit')
check(bone_hits[1] and bone_hits[1].name == "Jonas Dagmire's Triquetrum",
    'jonas: hit displays the most specific alias in the line')
local bone_hits_chars = core.text_candidates_chars(
    { ["Srv_Eve"] = { name = "Eve", needs = bone_needs } },
    "check out Jonas Dagmire's Triquetrum wow", 8)
check(#bone_hits_chars == 1 and bone_hits_chars[1].name == "Jonas Dagmire's Triquetrum",
    'jonas: per-char scan collapses the alias pair too')
check(#(bone_hits_chars[1].needers or {}) == 1, 'jonas: needers attached to the single hit')

-- Shared-id hazard: Jonas bone entries share id lists across DIFFERENT bones,
-- so a name hit must win over an id hit that points at another item.
local entry_other_bone = {
    item = "Trapezium",
    names = { "Trapezium", "Jonas Dagmire's Trapezium" },
    ids = { 33166, 33167 }, -- same shared ids as Triquetrum
}
local two_bone_needs = core.build_char_needs({
    { entry = entry_other_bone, item_name = "Trapezium", list_id = "jonas" },
    { entry = entry_bone, item_name = "Triquetrum", list_id = "jonas" },
}, function() return "missing" end)
local two_bone_chars = { ["Srv_Fay"] = { name = "Fay", needs = two_bone_needs } }
local qn = core.query_chars(two_bone_chars, "Triquetrum", 33166)
check(#qn == 1 and qn[1].display == "Triquetrum",
    'jonas: name match beats shared-id hit pointing at a different bone')

-- Tombstoned (failed) characters carry no needs and must be invisible to the
-- merged index (stutter regression: failed rebuilds must not affect merges).
local with_tombstone = core.merge({
    ["Srv_Alice"] = { name = "Alice", needs = needs },
    ["Srv_Ghost"] = { name = "Srv_Ghost", failed = true, sig = "store:" },
})
check(with_tombstone.item_count == 2, 'tombstone: merge ignores failed chars')
check(#core.query(with_tombstone, "Blade of War", 101) == 1, 'tombstone: no ghost needers')

-- query_chars / text_candidates_chars: the merge-free runtime paths must
-- behave identically to the merged variants (stutter fix: no O(all-needs)
-- merge exists anymore; queries walk per-character maps directly).
local qc = core.query_chars(chars, "Blade of War", 101)
check(#qc == 2, 'query_chars: needers across chars (Cara needs only the Ornament)')
local qc_names = {}
for _, n in ipairs(qc) do qc_names[n.character] = true end
check(qc_names.Alice == true and qc_names.Bob == true, 'query_chars: correct characters')

local qc_tomb = core.query_chars({
    ["Srv_Alice"] = { name = "Alice", needs = needs },
    ["Srv_Ghost"] = { name = "Srv_Ghost", failed = true, sig = "store:" },
}, "Blade of War", 101)
check(#qc_tomb == 1 and qc_tomb[1].character == "Alice", 'query_chars: tombstones invisible')

local slime_qc = core.query_chars({ ["Srv_Dee"] = { name = "Dee", needs = slime_needs } }, "", 909)
check(#slime_qc == 1 and slime_qc[1].display == "Corrosive Slime of Suffering",
    'query_chars: id hit canonical display')

local tc = core.text_candidates_chars(chars, "Anyone want Blade of War before I vendor it?", 8)
check(#tc == 1 and #(tc[1].needers or {}) >= 2, 'text_candidates_chars: hit with needers')
check(#core.text_candidates_chars(chars, "hello there", 8) == 0, 'text_candidates_chars: clean line')

-- R3: memo-cache size accounting is exposed and behaves (grows on new keys,
-- does not double-count, reports a cap and a zero clear-count in normal use).
do
    local cs = core.cache_sizes()
    check(type(cs) == "table" and type(cs.norm) == "number" and type(cs.strip) == "number",
        'cache_sizes: returns numeric counts')
    check((cs.cap or 0) > 0, 'cache_sizes: reports a positive cap')
    check(cs.clears == 0, 'cache_sizes: no overflow clears under normal catalog vocab')
    local before = core.cache_sizes().norm
    core.norm_key("Unique Cache Probe Name 246810")
    check(core.cache_sizes().norm == before + 1, 'cache_sizes: norm count grows on a new key')
    core.norm_key("Unique Cache Probe Name 246810")
    check(core.cache_sizes().norm == before + 1, 'cache_sizes: repeated key is not re-counted')
end

io.write(string.format('needs_index core: %d passed, %d failed\n', passed, failed))
os.exit(failed == 0 and 0 or 1)
