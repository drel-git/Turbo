-- Run from repo root: luajit lua/tests/turbogear_spells_startup_test.lua
-- Cold-start spell authority: restore cache, never live-scan, never empty-book.

package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

package.preload['mq'] = function()
    return {
        TLO = {
            Me = {
                CleanName = function() return 'Sketti' end,
                Class = {
                    Name = function() return 'Necromancer' end,
                    ShortName = function() return 'NEC' end,
                },
            },
            MacroQuest = { Server = function() return 'Project Lazarus' end },
            Spell = function() return nil end,
        },
    }
end
package.preload['config'] = function()
    return { CFG = { script_name = 'TurboGear' }, Settings = {}, SharedSettings = {} }
end
package.preload['diagnostics'] = function()
    return {
        enabled = true,
        count = function() end,
        event = function() end,
        time = function(_, fn) return fn() end,
        context = function() end,
    }
end
package.preload['items'] = function()
    return {
        inventory_slots = {},
        make_item = function() return {} end,
        make_item_lite = function() return {} end,
        clear_meta_cache = function() end,
    }
end
package.preload['inventory_stats'] = function()
    return {}
end
package.preload['store'] = function()
    return {
        Store = { get = function() return nil end },
        my_key = function() return 'Project Lazarus_Sketti' end,
    }
end

local gather_calls = 0
package.preload['spell_snapshot'] = function()
    return {
        gather = function()
            gather_calls = gather_calls + 1
            error('live spell gather must not run at startup')
        end,
        signature = function(map, ids)
            local parts = {}
            for k, row in pairs(map or {}) do
                parts[#parts + 1] = string.format('%s:%d:%d:%d',
                    k, tonumber(row.book) or 0, tonumber(row.scroll) or 0, tonumber(row.spell_id) or 0)
            end
            for id, v in pairs(ids or {}) do
                if v then parts[#parts + 1] = 'i' .. tostring(id) end
            end
            table.sort(parts)
            return table.concat(parts, '\31')
        end,
    }
end

local plan = require('spells_startup')
local SC = require('spell_cache')
local snapshot = require('snapshot')
local idxmod = require('ownership_index')
local tab_plan = require('spells_refresh')

local pass, fail = 0, 0
local function check(cond, msg)
    if cond then
        pass = pass + 1
    else
        fail = fail + 1
        print('FAIL: ' .. tostring(msg))
    end
end

local CACHED = {
    class = 'Necromancer',
    spells_sig = 'aegis of vie:1:0:9742\31i9742',
    spells = {
        ['aegis of vie'] = { name = 'Aegis of Vie', book = 1, scroll = 0, spell_id = 9742 },
    },
    spell_ids = { [9742] = true },
    server = 'Project Lazarus',
    name = 'Sketti',
    bankValid = true,
    bankLive = false,
    bankPreserved = true,
    equipped = { { name = 'Eq', id = 1, augs = {} } },
    bags = {},
    bank = {},
}

-- Cached startup: restore, no live gather, ownership sees same spells_sig
SC._reset_for_tests()
gather_calls = 0
local p = plan.plan_bg_startup({ snap = CACHED })
check(p.action == 'restore_cache' and p.live_scan == false and p.includeSpells == false,
    'cached startup restores, does not live-scan or includeSpells')
local ok, why = SC.restore_from_snapshot(CACHED)
check(ok == true and why == 'restored', 'restore_from_snapshot succeeds')
check(SC.ready() == true, 'cache ready after restore')
check(SC.signature() == CACHED.spells_sig, 'restored spells_sig is canonical')
check(SC.is_known('Aegis of Vie') == true, 'restored name is known')
check(SC.is_known(9742) == true, 'restored id is known')
check(gather_calls == 0, 'restore does not live-gather')
check(snapshot.seed_spell_authority(CACHED) == true, 'snapshot seeds restored maps')
local owned = idxmod.snapshot_semantic_key(CACHED)
local carried = { server = CACHED.server, name = CACHED.name, bankValid = true,
    bankLive = false, bankPreserved = true,
    equipped = CACHED.equipped, bags = CACHED.bags, bank = CACHED.bank }
snapshot._apply_cached_spell_authority(carried, CACHED)
check(carried.spells_sig == CACHED.spells_sig, 'lite gather carries cached spells_sig')
check(idxmod.snapshot_semantic_key(carried) == owned,
    'ownership semantic key matches restored spells_sig')

-- Missing cache: do not manufacture empty, do not live-scan
SC._reset_for_tests()
if snapshot.invalidate then snapshot.invalidate() end
gather_calls = 0
p = plan.plan_bg_startup({ snap = {} })
check(p.action == 'defer_live' and p.unknown == true and p.live_scan == false,
    'missing cache defers live scan')
check(plan.snapshot_is_usable({}) == false, 'empty snap is not usable')
check(plan.snapshot_is_usable({ spells_sig = '', spells = {} }) == false,
    'empty sig is not usable even with spells table')
check(plan.snapshot_is_usable({ spells = {} }) == false, 'spells table without sig is not usable')
ok, why = SC.restore_from_snapshot({})
check(ok == false and why == 'missing', 'restore refuses missing snap')
check(SC.ready() == false, 'missing restore leaves cache unready')
SC.note_deferred_unready()
check(SC.deferred_unready() == true, 'deferred unready flag set')
check(SC.ensure_built() == false, 'ensure_built does not live-scan when deferred')
check(SC.is_known('Aegis of Vie') == false, 'is_known does not rebuild when deferred')
check(gather_calls == 0, 'missing cache never live-gathers')
local blank = { name = 'Sketti' }
snapshot._apply_cached_spell_authority(blank, {})
check(blank.spells_sig == nil, 'missing cache does not stamp empty spells_sig')
check(blank.spells == nil, 'missing cache does not stamp empty spells map')

-- Deferred live refresh: old complete result stays visible, then atomic swap
SC._reset_for_tests()
ok = SC.restore_from_snapshot(CACHED)
check(ok == true, 'restore before deferred rebuild')
package.loaded['spell_snapshot'] = nil
package.preload['spell_snapshot'] = function()
    return {
        gather = function()
            gather_calls = gather_calls + 1
            local SC2 = require('spell_cache')
            check(SC2.ready() == true, 'ready stays true during rebuild')
            check(SC2.is_known('Aegis of Vie') == true, 'old result visible during rebuild')
            check(SC2.is_known('New Spell') == false, 'new spell not visible until swap')
            return {
                ['new spell'] = { name = 'New Spell', book = 1, scroll = 0, spell_id = 42 },
            }, { [42] = true }
        end,
        signature = function(map, ids)
            local parts = {}
            for k, row in pairs(map or {}) do
                parts[#parts + 1] = string.format('%s:%d:%d:%d',
                    k, tonumber(row.book) or 0, tonumber(row.scroll) or 0, tonumber(row.spell_id) or 0)
            end
            for id, v in pairs(ids or {}) do
                if v then parts[#parts + 1] = 'i' .. tostring(id) end
            end
            table.sort(parts)
            return table.concat(parts, '\31')
        end,
    }
end
gather_calls = 0
local changed = SC.rebuild('Necromancer')
check(changed == true, 'rebuild with new spells changes sig')
check(gather_calls == 1, 'rebuild live-gathers once')
check(SC.is_known('New Spell') == true, 'new result visible after swap')
check(SC.is_known(42) == true, 'new id visible after swap')
check(SC.is_known('Aegis of Vie') == false, 'old name replaced after swap')
check(SC.signature() ~= CACHED.spells_sig, 'spells_sig changed after real spell change')

-- Real spell change invalidates ownership once
local before = idxmod.snapshot_semantic_key(CACHED)
local after_spells = {}
for k, v in pairs(CACHED) do after_spells[k] = v end
after_spells.spells_sig = SC.signature()
check(idxmod.snapshot_semantic_key(after_spells) ~= before,
    'spell set change -> ownership semantic invalidation')

-- Non-spell changes do not imply a spell rescan
p = plan.plan_bg_startup({
    snap = CACHED,
    don_changed = true,
    lockouts_changed = true,
    inventory_seq = 99,
})
check(p.live_scan == false and p.action == 'restore_cache',
    'DoN/lockout/seq changes do not request a spell rescan')
check(idxmod.snapshot_semantic_key(CACHED) == owned,
    'DoN/lockout-free cached snap keeps the same ownership key')

-- Spells tab: usable cache -> first open does not synchronously rescan
local tab = tab_plan.plan_tab_enter({
    spell_cache_ready = true,
    spell_cache_sig = CACHED.spells_sig,
    last_spell_cache_at = 0,
    now = 2000000,
    interval_minutes = 5,
})
check(tab.action == 'draw_cache' and tab.source == 'cache',
    'Spells first-open with usable cache draws cache')
check(tab_plan.local_rebuild_allowed(false) == false, 'viewer still must not rebuild locally')

print(string.format('spells_startup: %d passed, %d failed', pass, fail))
if fail > 0 then os.exit(1) end
