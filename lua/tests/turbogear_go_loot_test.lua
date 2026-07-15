-- Run from repo root:  luajit lua\tests\turbogear_go_loot_test.lua
-- Covers corpse-id extraction, [GOLOOT] line parsing, and the TurboLoot-backed
-- go_loot dispatcher (request / on_mac_line / timeout tick).
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

local last_cmd = nil
local last_note = nil
local macro_name = ""

package.preload['mq'] = function()
    return {
        TLO = {
            Me = {
                CleanName = function() return "Tester" end,
                Combat = function() return false end,
            },
            Macro = {
                Name = function() return macro_name end,
            },
        },
        cmd = function(s) last_cmd = s end,
    }
end
package.preload['config'] = function()
    return { CFG = {} }
end
package.preload['announcer'] = function()
    return {
        note_go_status = function(item, who, note)
            last_note = { item = item, who = who, note = note }
        end,
    }
end
package.preload['engine'] = function()
    return { Engine = {} }
end
package.preload['inventory_watch'] = function()
    return { note_change = function() end }
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

-- parse_goloot_line
local st, det, cid = R.parse_goloot_line("[tl] [GOLOOT] starting Wand of Foo (ID: 141)")
check(st == "starting" and det == "Wand of Foo" and cid == 141, 'goloot: starting')
st, det, cid = R.parse_goloot_line("[tl] [GOLOOT] looted Wand of Foo (ID: 141)")
check(st == "looted" and det == "Wand of Foo" and cid == 141, 'goloot: looted')
st, det, cid = R.parse_goloot_line("[tl] [GOLOOT] failed corpse_gone (ID: 141)")
check(st == "failed" and det == "corpse_gone" and cid == 141, 'goloot: failed reason')
check(R.parse_goloot_line("[tl] [ANNOUNCE] Foo (ID: 1)") == nil, 'goloot: ignores announce')

-- dispatcher: rejects bad payloads
local ok, err = G.request({ item_name = "Wand", corpse_id = 0 })
check(ok == false and err == "no_corpse_id", 'request: no corpse id')
ok, err = G.request({ item_name = "", corpse_id = 141 })
check(ok == false and err == "no_item", 'request: no item')

-- dispatcher: launches TurboLoot go and finishes on golootdone
last_cmd = nil
last_note = nil
ok, err = G.request({ item_name = "Wand of Foo", corpse_id = 141, item_id = 9 })
check(ok == true and err == nil, 'request: accepts')
check(last_cmd == "/mac TurboLoot go 141 Wand of Foo", 'request: launches mac')
check(G.busy() == true, 'request: busy while pending')

ok, err = G.request({ item_name = "Other", corpse_id = 99 })
check(ok == false and err == "busy", 'request: busy for different job')
ok, err = G.request({ item_name = "Wand of Foo", corpse_id = 141 })
check(ok == true and err == "already", 'request: duplicate is already')

G.on_mac_line("starting", "Wand of Foo", 141, "Wand of Foo")
check(last_note and last_note.note == "going" and G.busy() == true, 'on_mac_line: starting keeps job')

G.on_mac_line("looted", "Wand of Foo", 141, "Wand of Foo")
check(last_note and last_note.note == "looted" and G.busy() == false, 'on_mac_line: looted finishes')

-- failed path
last_note = nil
G.request({ item_name = "Bone Chips", corpse_id = 136 })
G.on_mac_line("failed", "corpse_gone", 136, "Bone Chips")
check(last_note and last_note.note == "corpse_gone" and G.busy() == false, 'on_mac_line: failed reason')

-- legacy decide stub still loadable
check(G.decide("reveal", {}).note == "legacy_decide_unused", 'decide: legacy stub')

print(string.format("go_loot: %d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
