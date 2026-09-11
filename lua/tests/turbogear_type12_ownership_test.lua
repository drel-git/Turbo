-- Run from repo root: luajit lua/tests/turbogear_type12_ownership_test.lua
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

package.preload['mq'] = function()
    return {
        configDir = '.',
        gettime = function() return 0 end,
        TLO = {
            Me = { CleanName = function() return 'LocalOnly' end },
            MacroQuest = { Server = function() return 'Srv' end },
            FindItem = function() return nil end,
            FindItemBank = function() return nil end,
        },
    }
end

package.preload['config'] = function()
    return {
        CFG = { script_name = 'TurboGear', perf_live_self_bis = true },
        Settings = {},
        SharedSettings = {},
        canonical_class = function(class_name) return class_name end,
    }
end

-- Peer snapshots can be present but incomplete, so the FindItem map the source
-- pages paint from is a fallback for peer cells. Empty by default so the
-- snapshot-only cases below are unaffected.
local bis_search_map = {}
package.preload['bis_search'] = function()
    return {
        slot_rec = function(_, list_id, slot)
            local by_slot = bis_search_map[list_id]
            return by_slot and by_slot[slot] or nil
        end,
        version = function() return 1 end,
        reload_if_changed = function() end,
        request_via_bg = function() return false end,
    }
end

local type12 = require('type12_ownership')

local pass, fail = 0, 0
local function check(cond, msg)
    if cond then pass = pass + 1 else fail = fail + 1; print('FAIL: ' .. tostring(msg)) end
end

local function row(effect)
    for _, rec in ipairs(type12.rows()) do
        if rec.effect == effect then return rec end
    end
    return nil
end

local function snap(items)
    return {
        name = 'Peer',
        class = 'Shadow Knight',
        equipped = {},
        bags = items or {},
        bank = {},
    }
end

local extended = row('Extended Reach')
check(extended ~= nil, 'Extended Reach row exists')

local hex = snap({ { name = 'Hideous Hex of Expanded Reach', id = 28115 } })
check(type12.classify(hex, extended).source == 'DSK', 'Hideous Hex classifies as DSK')

local healing = row('Increased Healing')
check(type12.classify(snap({ { name = 'Hideous Hex of Merciful Mending', id = 28110 } }), healing).source == 'DSK',
    'DSK Merciful Mending classifies as DSK')

local mana = row('Beneficial Reduction of Mana')
check(type12.classify(snap({ { name = 'Hideous Hex of Benevolent Efficiency', id = 27620 } }), mana).source == 'DSK',
    'DSK Benevolent Efficiency classifies as DSK')

local cleave = row('Cleave')
check(type12.classify(snap({ { name = 'Hideous Hex of Visceral Malice', id = 28117 } }), cleave).source == 'DSK',
    'DSK Visceral Malice classifies as DSK')

local parry = row('Block and Parry')
check(type12.classify(snap({ { name = 'Hideous Hex of Adept Guard', id = 28118 } }), parry).source == 'DSK',
    'DSK Adept Guard classifies as DSK')

local ranged = row('Ranged Accuracy')
check(ranged ~= nil, 'Ranged Accuracy row exists')
check(type12.classify(snap({ { name = 'Cryptic Clutch of Lethal Barrage', id = 62557 } }), ranged).source == 'DoN',
    'DoN Lethal Barrage classifies as DoN')
check(type12.classify(snap({ { name = 'Hideous Hex of Lethal Barrage' } }), ranged).source == 'DSK',
    'DSK Lethal Barrage classifies as DSK')

local clutch = snap({ { name = 'Cryptic Clutch of Expanded Reach', id = 62552 } })
check(type12.classify(clutch, extended).source == 'DoN', 'Cryptic Clutch classifies as DoN')

local both = snap({
    { name = 'Hideous Hex of Expanded Reach', id = 28115 },
    { name = 'Cryptic Clutch of Expanded Reach', id = 62552 },
})
check(type12.classify(both, extended).source == 'DoN', 'DoN wins when both are owned')

local missing = snap({})
check(type12.classify(missing, extended).source == '-', 'missing classifies as dash')

-- The user's ruling: an unfilled Vacant Vessel still reads as DoN ownership.
check(type12.classify(snap({ { name = 'Vacant Vessel of Expanded Reach', id = 63018 } }), extended).source == 'DoN',
    'Vacant Vessel counts as DoN')

-- Augs socketed into worn gear resolve, not just loose ones in a bag.
local socketed = {
    name = 'Peer', class = 'Shadow Knight', bags = {}, bank = {},
    equipped = { { name = 'Some Bracer', where = 'Wrist', augs = {
        { name = 'Hideous Hex of Expanded Reach', id = 28115, index = 1, type = 12 },
    } } },
}
check(type12.classify(socketed, extended).source == 'DSK', 'socketed aug classifies from equipped augs')

-- Bank contents count too.
local banked = {
    name = 'Peer', class = 'Shadow Knight', equipped = {}, bags = {},
    bank = { { name = 'Cryptic Clutch of Expanded Reach', id = 62552 } },
}
check(type12.classify(banked, extended).source == 'DoN', 'banked aug classifies from bank')

-- Both families list the bare focus name in `names`, so matching on it could
-- never tell them apart. Only the family-prefixed names may match.
check(type12.classify(snap({ { name = 'Expanded Reach' } }), extended).source == '-',
    'bare focus name does not classify as either family')

local don_slot = type12.classify(clutch, extended).slot
local dsk_slot = type12.classify(hex, extended).slot
check(tostring(don_slot or '') ~= '', 'DoN hit reports its catalog slot')
check(tostring(dsk_slot or '') ~= '', 'DSK hit reports its catalog slot')
check(type12.classify(clutch, extended).via == 'snapshot', 'snapshot hits report via=snapshot')

-- A peer whose aug is known only to the FindItem map: the source page paints it
-- owned, so the summary must too.
bis_search_map.don = { [don_slot] = { status = 'equipped', name = 'Cryptic Clutch of Expanded Reach' } }
check(type12.classify(missing, extended).source == 'DoN',
    'peer DoN aug known only to bis_search classifies as DoN')
check(type12.classify(missing, extended).via == 'bis_search', 'map hits report via=bis_search')
bis_search_map.don = nil

bis_search_map.dsk = { [dsk_slot] = { status = 'carried', name = 'Hideous Hex of Expanded Reach' } }
check(type12.classify(missing, extended).source == 'DSK',
    'peer DSK aug known only to bis_search classifies as DSK')

-- DoN still wins when the map reports both.
bis_search_map.don = { [don_slot] = { status = 'equipped', name = 'Cryptic Clutch of Expanded Reach' } }
check(type12.classify(missing, extended).source == 'DoN',
    'DoN wins over DSK through the bis_search map')

-- Ownership is a union: each source has its own blind spot, so a map that has
-- not caught up must not erase an aug the snapshot can prove.
bis_search_map.don = { [don_slot] = { status = 'missing' } }
bis_search_map.dsk = { [dsk_slot] = { status = 'missing' } }
check(type12.classify(clutch, extended).source == 'DoN',
    'a stale bis_search miss does not erase a snapshot hit')
check(type12.classify(missing, extended).source == '-',
    'an explicit map miss with nothing in the snapshot stays a dash')
bis_search_map.don, bis_search_map.dsk = nil, nil

-- Self columns skip the peer map; the local character has snapshot plus live.
local self_empty = { name = 'LocalOnly', class = 'Shadow Knight', equipped = {}, bags = {}, bank = {} }
bis_search_map.don = { [don_slot] = { status = 'equipped', name = 'Cryptic Clutch of Expanded Reach' } }
check(type12.classify(self_empty, extended).source == '-',
    'self column ignores the peer FindItem map')
bis_search_map.don = nil

local self_owned = {
    name = 'LocalOnly', class = 'Shadow Knight', equipped = {}, bank = {},
    bags = { { name = 'Cryptic Clutch of Expanded Reach', id = 62552 } },
}
check(type12.classify(self_owned, extended).source == 'DoN',
    'self column classifies from its own snapshot')

-- The self column's live fallback resolves a catalog entry by (list, class, slot)
-- before handing it to bis. Guard that lookup here; the live evaluation itself is
-- covered by turbogear_bis_augmented_live_test.
local function resolves_family_name(list_id, slot, want)
    local ok, entry = pcall(require('bis_catalog').resolve_entry, list_id, 'Shadow Knight', slot)
    if not ok or type(entry) ~= 'table' then return false end
    for _, n in ipairs(entry.names or {}) do
        if tostring(n):lower() == want:lower() then return true end
    end
    return false
end
check(resolves_family_name('don', don_slot, 'Cryptic Clutch of Expanded Reach'),
    'DoN slot resolves a catalog entry for the self live fallback')
check(resolves_family_name('dsk', dsk_slot, 'Hideous Hex of Expanded Reach'),
    'DSK slot resolves a catalog entry for the self live fallback')

-- The derived source table must cover every row in both families, or cells can
-- never resolve. 18 effects, DoN carrying aug+vessel ids and DSK carrying one.
local summary = type12.source_summary()
check(summary.effects == 18, 'source table covers 18 effects, got ' .. tostring(summary.effects))
check(summary.DoN == 18, 'every effect resolves a DoN aug, got ' .. tostring(summary.DoN))
check(summary.DSK == 18, 'every effect resolves a DSK aug, got ' .. tostring(summary.DSK))
check(summary.ids == 18 * 3, 'DoN contributes 2 ids and DSK 1 per effect, got ' .. tostring(summary.ids))
check(summary.names == 18 * 3, 'DoN contributes 2 names and DSK 1 per effect, got ' .. tostring(summary.names))

check(#type12.rows() == 18, 'exactly 18 Type 12 display rows')
check(type12.display_label('Beneficial Reduction of Mana') == 'Beneficial Mana Reduction',
    'Beneficial Reduction of Mana display rename')
check(type12.display_label('Detrimental Reduction of Mana') == 'Detrimental Mana Reduction',
    'Detrimental Mana Reduction display rename')

-- Every row must name an aug family, or its cells can never resolve.
for _, rec in ipairs(type12.rows()) do
    check(tostring(rec.source or '') ~= '', 'row ' .. tostring(rec.effect) .. ' names a source aug')
end

local order = {
    'Increased Healing',
    'Extended Reach',
    'Beneficial Extension',
    'Beneficial Reduction of Mana',
    'Beneficial Cast Time Reduction',
    'Detrimental Extension',
    'Detrimental Reduction of Mana',
    'Detrimental Cast Time Reduction',
    'Magic Damage',
    'Fire Damage',
    'Ice Damage',
    'Poison Damage',
    'Disease Damage',
    'Cleave',
    'Double Attack',
    'Ranged Accuracy',
    'Improved Dodge',
    'Block and Parry',
}
for i, effect in ipairs(order) do
    check(type12.rows()[i] and type12.rows()[i].effect == effect, 'row order #' .. i .. ' is ' .. effect)
end

local dividers = {
    ['Extended Reach'] = true,
    ['Beneficial Cast Time Reduction'] = true,
    ['Detrimental Cast Time Reduction'] = true,
    ['Disease Damage'] = true,
    ['Ranged Accuracy'] = true,
}
for _, rec in ipairs(type12.rows()) do
    check((rec.divider_after == true) == (dividers[rec.effect] == true),
        'divider metadata for ' .. tostring(rec.effect))
end

print(string.format('type12 ownership: %d passed, %d failed', pass, fail))
if fail > 0 then os.exit(1) end
