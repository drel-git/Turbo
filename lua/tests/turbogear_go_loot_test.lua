-- Run from repo root:  luajit lua\tests\turbogear_go_loot_test.lua
-- Covers the pure pieces of the "go loot" feature: corpse-id extraction from
-- TurboLoot control lines (announce_rules) and the runner's phase decisions
-- (go_loot.decide). The mq/config preloads keep go_loot.lua loadable offline.
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

package.preload['mq'] = function()
    return { TLO = {}, cmd = function() end }
end
package.preload['config'] = function()
    return { CFG = {} }
end

local R = require('announce_rules')
local G = require('go_loot')

local passed, failed = 0, 0
local function check(cond, label)
    if cond then
        passed = passed + 1
    else
        failed = failed + 1
        io.stderr:write('FAIL: ', tostring(label), '\n')
    end
end

-- corpse_id_from_line: only left-on-corpse tags carry an actionable corpse id
check(R.corpse_id_from_line("[tl] [ANNOUNCE] Rayin's Helm of Abhorrence (ID: 3241)") == 3241,
    'corpse id: ANNOUNCE line')
check(R.corpse_id_from_line("[tl] [SKIP] Essence of Earth (ID: 148) - Already have") == 148,
    'corpse id: SKIP line')
check(R.corpse_id_from_line("[tl] [IGNORE] Rusty Sword (ID: 77)") == 77,
    'corpse id: IGNORE line')
check(R.corpse_id_from_line("Drel tells the group, '[tl] [ANNOUNCE] Boots of Shifting Time (ID: 512)'") == 512,
    'corpse id: chat-wrapped ANNOUNCE')
check(R.corpse_id_from_line("[tl] [KEEP] Shiny Thing (ID: 99)") == nil,
    'corpse id: KEEP looted the item - no id')
check(R.corpse_id_from_line("[tl] [SELL] Junk (ID: 5)") == nil,
    'corpse id: SELL looted the item - no id')
check(R.corpse_id_from_line("[tl] [ANNOUNCE] No id here") == nil,
    'corpse id: ANNOUNCE without (ID: n)')
check(R.corpse_id_from_line("[tl] [ANNOUNCE] Foo (ID: 11) bar (ID: 131)") == 131,
    'corpse id: last (ID:) wins')
check(R.corpse_id_from_line("") == nil, 'corpse id: empty line')
check(R.corpse_id_from_line("You tell the group, 'Sword of Truth'") == nil,
    'corpse id: plain link chat')

-- decide: reveal phase (hidecorpse none before spawn check)
check(G.decide("reveal", { corpse_exists = false }).action == "wait",
    'reveal: waits for client refresh')
check(G.decide("reveal", {
    corpse_exists = true, distance = 50, max_distance = 400,
}).action == "ready", 'reveal: visible corpse is ready')
check(G.decide("reveal", {
    corpse_exists = true, distance = 500, max_distance = 400,
}).note == "too_far", 'reveal: too far after unhide')
check(G.decide("reveal", {
    corpse_exists = false, timed_out = true, reveal_retries_left = 1,
}).action == "retry_reveal", 'reveal: one retry when still missing')
check(G.decide("reveal", {
    corpse_exists = false, timed_out = true, reveal_retries_left = 0,
}).note == "corpse_gone", 'reveal: still gone after retries')

-- decide: move phase
check(G.decide("move", { corpse_exists = false }).note == "corpse_gone", 'move: corpse gone fails')
check(G.decide("move", { corpse_exists = true, distance = 10, arrive_dist = 15 }).action == "arrived",
    'move: within range arrives')
check(G.decide("move", { corpse_exists = true, distance = 100, arrive_dist = 15, timed_out = true }).note == "timeout_move",
    'move: timeout fails')
check(G.decide("move", { corpse_exists = true, distance = 100, arrive_dist = 15 }).action == "wait",
    'move: still walking waits')
check(G.decide("move", {
    corpse_exists = false, allow_blind = true, nav_active = true,
}).action == "wait", 'move: blind nav active waits')
check(G.decide("move", {
    corpse_exists = false, allow_blind = true, nav_active = false,
}).action == "blind_retry", 'move: blind nav idle reissues')
check(G.decide("move", {
    corpse_exists = false, allow_blind = true, timed_out = true,
}).note == "timeout_move", 'move: blind nav timeout')

-- decide: open phase
check(G.decide("open", { corpse_exists = true, target_is_corpse = true }).action == "open_window",
    'open: targeted corpse opens')
check(G.decide("open", { corpse_exists = false, target_is_corpse = true }).action == "open_window",
    'open: target id is enough without spawn TLO')
check(G.decide("open", { corpse_exists = false }).note == "corpse_gone", 'open: corpse rotted fails')
check(G.decide("open", { corpse_exists = true, target_is_corpse = false, timed_out = true }).note == "no_target",
    'open: cannot target fails')
check(G.decide("open", {
    corpse_exists = true, target_is_corpse = false, timed_out = true, close_enough = true,
}).action == "loot_anyway", 'open: close enough tries loot without target')

-- decide: scan timeout
check(G.decide("scan", {
    window_open = true, item_slot = 0, scan_complete = false, timed_out = true,
}).note == "not_found", 'scan: timeout fails')
check(G.decide("scan", {
    window_open = true, item_slot = 0, items_pending = true,
}).action == "wait", 'scan: waits while Corpse.Items populates')
check(G.decide("scan", {
    window_open = true, item_slot = 0, items_pending = true, timed_out = true,
}).note == "not_found", 'scan: pending populate eventually times out')

-- decide: window phase
check(G.decide("window", { window_open = true }).action == "found", 'window: open proceeds')
check(G.decide("window", { window_open = false, timed_out = true }).note == "no_window", 'window: timeout fails')
check(G.decide("window", { window_open = false }).action == "wait", 'window: waits for open')

-- decide: scan phase
check(G.decide("scan", { window_open = true, item_slot = 3 }).action == "found", 'scan: slot found')
check(G.decide("scan", { window_open = true, item_slot = 0, scan_complete = true }).note == "not_found",
    'scan: item already gone')
check(G.decide("scan", { window_open = false }).note == "window_closed", 'scan: window vanished fails')

-- decide: pickup phase (dialog handling before completion)
check(G.decide("pickup", { confirm_open = true }).action == "confirm", 'pickup: no-drop confirm first')
check(G.decide("pickup", { quantity_open = true }).action == "accept_quantity", 'pickup: quantity accept')
check(G.decide("pickup", { cursor_item = true }).action == "stash_cursor", 'pickup: cursor to bags')
check(G.decide("pickup", { slot_empty = true }).note == "looted", 'pickup: slot empty = looted')
check(G.decide("pickup", { timed_out = true }).note == "loot_failed", 'pickup: timeout fails')
check(G.decide("pickup", {}).action == "wait", 'pickup: otherwise waits')

-- unknown phase is a hard failure, never a hang
check(G.decide("nonsense", {}).note == "bad_phase", 'decide: unknown phase fails fast')

print(string.format("go_loot: %d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
