-- Run from repo root: luajit lua/tests/turbogear_don_lockouts_test.lua
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

local don = require('references.don_lockouts')

local pass, fail = 0, 0
local function check(cond, msg)
    if cond then pass = pass + 1 else fail = fail + 1; print("FAIL: " .. tostring(msg)) end
end

check(don.row_count() == 36, "exactly 36 canonical DoN rows")
check(#don.sections == 6, "six DoN sections")
check(don.sections[1].title == "Raid Events", "raid events first")
check(don.sections[1].description == "Kindly + Tier 2 complete - 5d 12h", "raid header compact description")
check(don.sections[1].default_collapsed == false, "raid events starts expanded")
for i = 2, #don.sections do
    check(don.sections[i].default_collapsed == true, don.sections[i].title .. " starts collapsed")
    check(not tostring(don.sections[i].description or ""):find("6h limit", 1, true), don.sections[i].title .. " omits 6h limit")
    check(not tostring(don.sections[i].description or ""):find("replay", 1, true), don.sections[i].title .. " omits replay")
end
check(don.sections[1].color_family == "raid", "raid section uses raid color family")
check(don.sections[2].color_family == "mission", "mission sections use mission color family")
check(don.sections[3].color_family == "progression", "progression sections use progression color family")

local fanning = don.lookup("5501")
check(fanning and fanning.name == "Fanning the Flames", "Fanning task 5501 maps to shared replay row")
check(fanning and fanning.replay_group == 5500, "Fanning replay group is 5500")

local lavaspinner = don.lookup("301")
check(lavaspinner and lavaspinner.name == "Lavaspinner Hunting", "Lavaspinner Hunting replay group 301")

local locals1 = don.lookup("Lavaspinner's Locals")
local locals2 = don.lookup("Lavaspinners Locals")
check(locals1 and locals2 and locals1 == locals2, "Lavaspinner's Locals spelling aliases share row")

local children = don.lookup("Children of Gimblax [2 Group Progression]")
check(children and children.name == "Children of Gimblax", "Children suffix normalizes")

local sickness = don.lookup("Sickness of the Spirit [2 Group Progression]")
check(sickness and sickness.name == "Sickness of the Spirit", "Sickness suffix normalizes")

local volkara_full = don.lookup("Volkara [Raid Event]")
check(volkara_full and volkara_full.name == "Volkara's Bite", "Volkara full donbis alias normalizes")

local best_solo = don.lookup("Best Laid Plans [Solo]")
local best_duo = don.lookup("Best Laid Plans [Duo]")
check(best_solo and best_solo == best_duo, "Solo and Duo aliases share canonical row")
check(best_solo and best_solo.replay_group == 4809, "Best Laid Plans replay group")

local decorated = don.lookup("T3: Flight of the Black Wing Drakes [Duo]")
check(decorated and decorated.name == "Flight of the Black Wing Drakes", "T3/Duo decorations normalize")

local keys = don.lookup_keys(best_solo or {})
local seen_4809, seen_74, seen_4811 = false, false, false
for _, key in ipairs(keys) do
    if key == "4809" then seen_4809 = true end
    if key == "74" then seen_74 = true end
    if key == "4811" then seen_4811 = true end
end
check(seen_4809 and seen_74 and seen_4811, "lookup keys include replay group and Solo/Duo task IDs")

print(string.format("don lockouts: %d passed, %d failed", pass, fail))
if fail > 0 then os.exit(1) end
