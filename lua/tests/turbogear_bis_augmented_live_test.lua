-- Run from repo root:  luajit lua/tests/turbogear_bis_augmented_live_test.lua
-- Local BiS live ownership must find "... (Augmented)" worn gear when exact
-- FindItem(=base) fails (common MQ Name() for socketted items).
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

local inv = {
    [2] = {
        name = "Duskbringer's Ascendant Helm of the Hateful (Augmented)",
        id = 32465,
    },
}

local function make_fi(name, id, slot)
    local fi = {}
    setmetatable(fi, {
        __call = function() return true end,
    })
    fi.Name = function() return name end
    fi.ID = function() return id end
    fi.ItemSlot = function() return slot end
    fi.ItemSlotName = function() return "Head" end
    return fi
end

package.preload['mq'] = function()
    return {
        configDir = '.',
        TLO = {
            Me = {
                CleanName = function() return 'Drel' end,
                Inventory = function(slot)
                    local rec = inv[tonumber(slot) or -1]
                    if not rec then return nil end
                    local it = make_fi(rec.name, rec.id, tonumber(slot))
                    return it
                end,
            },
            MacroQuest = { Server = function() return 'Srv' end },
            -- Exact =base fails; =base (Augmented) and partial succeed.
            FindItem = function(q)
                q = tostring(q or '')
                if q == "=Duskbringer's Ascendant Helm of the Hateful" then
                    return nil
                end
                if q == 32465
                    or q == "=Duskbringer's Ascendant Helm of the Hateful (Augmented)"
                    or q == "Duskbringer's Ascendant Helm of the Hateful" then
                    return make_fi(
                        "Duskbringer's Ascendant Helm of the Hateful (Augmented)",
                        32465, 2)
                end
                return nil
            end,
            FindItemBank = function() return nil end,
        },
    }
end

package.preload['config'] = function()
    return {
        CFG = { script_name = 'TurboGear', perf_live_self_bis = true },
        Settings = {},
        SharedSettings = {},
    }
end

package.preload['items'] = function()
    return {
        slot_id_for_label = function(label)
            label = tostring(label or ''):lower()
            if label == 'head' then return 2 end
            return nil
        end,
        inventory_slots = { { id = 2, name = 'Head' } },
    }
end

package.preload['store'] = function()
    return { Store = { my_key = function() return nil end, get = function() return nil end } }
end

local bis = require('bis')

local pass, fail = 0, 0
local function check(cond, msg)
    if cond then pass = pass + 1 else fail = fail + 1; print('  FAIL: ' .. tostring(msg)) end
end

local entry = {
    item = "Duskbringer's Ascendant Helm of the Hateful",
    names = { "Duskbringer's Ascendant Helm of the Hateful" },
    ids = {},
    slot = 'Head',
}

-- Name-only entry: exact =base fails; Augmented / partial / worn-slot must hit.
local st = bis.live_item_status(entry, entry.item, nil)
check(st == 'equipped', 'live_item_status: Augmented helm is equipped (name-only entry)')

-- Empty inventory slot → not owned (unequip path).
inv[2] = nil
package.loaded['mq'].TLO.FindItem = function() return nil end
bis.invalidate_live_ownership_cache()
st = bis.live_item_status(entry, entry.item, nil)
check(st == nil, 'live_item_status: empty Head slot is not owned')

-- Id path still works when FindItem(id) succeeds.
inv[2] = {
    name = "Duskbringer's Ascendant Helm of the Hateful (Augmented)",
    id = 32465,
}
package.loaded['mq'].TLO.FindItem = function(q)
    if tonumber(q) == 32465 then
        return make_fi(
            "Duskbringer's Ascendant Helm of the Hateful (Augmented)",
            32465, 2)
    end
    return nil
end
bis.invalidate_live_ownership_cache()
st = bis.live_item_status({
    item = entry.item,
    names = entry.names,
    ids = { 32465 },
    slot = 'Head',
}, entry.item, nil)
check(st == 'equipped', 'live_item_status: id 32465 finds Augmented helm')

-- evaluate_entry local column must not force missing when live finds Augmented.
local snap = {
    name = 'Drel',
    class = 'Shadow Knight',
    equipped = {},
    bags = {},
    bank = {},
}
package.loaded['mq'].TLO.FindItem = function(q)
    q = tostring(q or '')
    if q == "=Duskbringer's Ascendant Helm of the Hateful" then return nil end
    if q == "=Duskbringer's Ascendant Helm of the Hateful (Augmented)"
        or q == "Duskbringer's Ascendant Helm of the Hateful" then
        return make_fi(
            "Duskbringer's Ascendant Helm of the Hateful (Augmented)",
            32465, 2)
    end
    return nil
end
bis.invalidate_live_ownership_cache()
local row = bis.evaluate_entry(entry, snap)
check(row and row.status == 'equipped' and row.have == true,
    'evaluate_entry: local live paints Augmented helm equipped')

print(string.format('turbogear_bis_augmented_live_test: %d passed, %d failed', pass, fail))
if fail > 0 then os.exit(1) end
