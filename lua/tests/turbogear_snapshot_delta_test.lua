-- Run from repo root:  luajit lua\tests\turbogear_snapshot_delta_test.lua
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

local SD = require('snapshot_delta')

local passed, failed = 0, 0
local function check(cond, label)
    if cond then
        passed = passed + 1
    else
        failed = failed + 1
        io.stderr:write('FAIL: ', tostring(label), '\n')
    end
end

local function item(name, id, loc, where, slotid, slotname, extra)
    local it = {
        name = name, id = id,
        location = loc or "Equipped", where = where or name,
        slotid = slotid or 1, slotname = slotname or where or name,
    }
    for k, v in pairs(extra or {}) do it[k] = v end
    return it
end

-- slot_key ignores item identity, keeps slot identity
check(SD.slot_key(item("Sword", 1, "Equipped", "Mainhand", 13, "Mainhand"))
    == SD.slot_key(item("Axe", 2, "Equipped", "Mainhand", 13, "Mainhand")),
    'slot_key same slot different item matches')
check(SD.slot_key(item("Sword", 1, "Equipped", "Mainhand", 13, "Mainhand"))
    ~= SD.slot_key(item("Sword", 1, "Equipped", "Offhand", 14, "Offhand")),
    'slot_key different slot differs')
check(SD.slot_key(nil) == "", 'slot_key nil safe')

-- item_sig reflects id/name/qty/aug changes
local base = item("Sword", 10, "Equipped", "Mainhand", 13, "Mainhand")
check(SD.item_sig(base) == SD.item_sig(item("Sword", 10, "Equipped", "Mainhand", 13, "Mainhand")),
    'item_sig stable')
check(SD.item_sig(base) ~= SD.item_sig(item("Axe", 11, "Equipped", "Mainhand", 13, "Mainhand")),
    'item_sig differs on swap')
local with_aug = item("Sword", 10, "Equipped", "Mainhand", 13, "Mainhand",
    { augs = { { index = 1, id = 500 } } })
check(SD.item_sig(base) ~= SD.item_sig(with_aug), 'item_sig differs on aug insert')

-- diff_lists
local old_list = {
    item("Sword", 10, "Equipped", "Mainhand", 13, "Mainhand"),
    item("Helm", 20, "Equipped", "Head", 2, "Head"),
}
local old_by_key = SD.index_list(old_list)
local new_list = {
    item("Axe", 11, "Equipped", "Mainhand", 13, "Mainhand"),   -- swapped
    -- Helm removed
    item("Ring", 30, "Equipped", "Finger", 15, "Finger"),      -- added
}
local changed, removed = SD.diff_lists(old_by_key, new_list)
check(#changed == 2, 'diff: two changed (swap + add)')
check(#removed == 1, 'diff: one removed')
check(removed[1] == SD.slot_key(old_list[2]), 'diff: removed key is Helm slot')

-- no-op diff
local changed2, removed2 = SD.diff_lists(SD.index_list(old_list), old_list)
check(#changed2 == 0 and #removed2 == 0, 'diff: identical lists produce empty delta')

-- apply_to_list round-trip: old + delta == new
local applied = SD.apply_to_list(old_list, changed, removed)
local function list_sig(list)
    local parts = {}
    for _, it in ipairs(list) do parts[#parts + 1] = SD.slot_key(it) .. "=" .. SD.item_sig(it) end
    table.sort(parts)
    return table.concat(parts, ";")
end
check(list_sig(applied) == list_sig(new_list), 'apply: old + delta reproduces new list')
check(#old_list == 2, 'apply: input list untouched')

-- diff_snapshot: bank excluded unless include_bank
local snap_old = {
    name = "Tester", server = "Srv", class = "Ranger", level = 65,
    updated = 100, inventoryUpdated = 100,
    equipped = old_list, bags = {}, bank = { item("Gem", 40, "Bank", "Bank 1", 1, 0) },
}
local snap_new = {
    name = "Tester", server = "Srv", class = "Ranger", level = 65,
    updated = 200, inventoryUpdated = 200,
    equipped = new_list, bags = {}, bank = {}, -- bank "empty" because window closed
}
local baseline = SD.baseline_from_snapshot(snap_old, { include_bank = true })
local delta, count = SD.diff_snapshot(baseline, snap_new, { include_bank = false })
check(delta ~= nil, 'diff_snapshot returns delta')
check(delta.removed.bank == nil and delta.changed.bank == nil,
    'diff_snapshot: closed bank window never produces bank removals')
check(count == 3, 'diff_snapshot: equipped changes counted (2 changed + 1 removed)')
check(delta.inventoryUpdated == 200, 'diff_snapshot: carries inventory stamp')

-- with include_bank, bank removal is seen
local delta_b, count_b = SD.diff_snapshot(baseline, snap_new, { include_bank = true })
check(count_b == 4 and #(delta_b.removed.bank or {}) == 1,
    'diff_snapshot: live bank diff sees bank removal')

-- count_changes agrees
check(SD.count_changes(delta) == 3, 'count_changes matches diff count')
check(SD.count_changes(nil) == 0, 'count_changes nil safe')

-- baseline without bank: bank diffs are skipped even if asked for
local baseline_nb = SD.baseline_from_snapshot(snap_old, { include_bank = false })
local delta_nb = select(1, SD.diff_snapshot(baseline_nb, snap_new, { include_bank = true }))
check(delta_nb.removed.bank == nil, 'no bank baseline -> no bank removals')

-- R1: diff_snapshot carries the source snapshot's publisher seq
do
    local base = SD.baseline_from_snapshot({ equipped = {}, bags = {}, bank = {} })
    local snp = { name = "X", server = "Srv", updated = 5, seq = 4242,
        equipped = { { id = 1, name = "A", location = "Equipped", where = "Equipped", slotid = 13, slotname = "Primary" } },
        bags = {}, bank = {} }
    local d = SD.diff_snapshot(base, snp)
    check(d.seq == 4242, 'diff_snapshot carries source seq into the delta')
end

io.write(string.format('snapshot_delta: %d passed, %d failed\n', passed, failed))
os.exit(failed == 0 and 0 or 1)
