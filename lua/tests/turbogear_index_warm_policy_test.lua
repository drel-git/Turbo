-- Run from repo root: luajit lua/tests/turbogear_index_warm_policy_test.lua
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

local CFG = {}
local state = { bg = false }

package.preload['config'] = function()
    return { CFG = CFG, Settings = {}, SharedSettings = {} }
end

package.preload['state'] = function()
    return state
end

local policy = require('index_warm_policy')

local pass, fail = 0, 0
local function check(condition, message)
    if condition then
        pass = pass + 1
    else
        fail = fail + 1
        print("  FAIL: " .. tostring(message))
    end
end

policy._reset_for_tests()
state.bg = true
CFG.bg_index_prewarm = nil
CFG.generated_authority_enabled = nil
check(policy.allow_item_index_tick() == false, "background skips item_index prewarm by default")
check(policy.allow_needs_index_tick() == false, "generated authority keeps needs_index cold on bg")

state.bg = false
check(policy.allow_item_index_tick() == false, "UI does not tick item_index until Search/Upgrade request it")
check(policy.allow_needs_index_tick() == false, "generated authority keeps needs_index cold on UI")

policy.request_item_index("search", 60)
check(policy.item_index_requested() == true, "request_item_index marks search demand")
check(policy.allow_item_index_tick() == true, "search request allows item_index ticks")
check(policy.item_index_request_reason() == "search", "request reason is search")
policy.clear_item_index_request()
check(policy.allow_item_index_tick() == false, "clearing the request stops item_index ticks")

policy.request_item_index("upgrade", 60)
check(policy.allow_item_index_tick() == true, "upgrade request allows item_index ticks")
policy.request_item_index("upgrade", 0)
check(policy.allow_item_index_tick() == false, "ttl 0 clears item_index request")

policy.request_item_index("stats", 60)
check(policy.allow_item_index_tick() == true, "stats request allows item_index ticks")
policy.request_item_index("focus", 60)
check(policy.item_index_request_reason() == "focus", "focus request reason overwrites stats")
policy.clear_item_index_request()
check(policy.allow_item_index_tick() == false, "clearing stats/focus request stops item_index ticks")

state.bg = true
CFG.bg_index_prewarm = true
check(policy.allow_item_index_tick() == true, "temporary rollback allows background item_index prewarm")
check(policy.allow_needs_index_tick() == false, "generated authority still keeps needs_index cold during item prewarm")

CFG.bg_index_prewarm = false
check(policy.allow_item_index_tick() == false, "explicit false keeps background item_index prewarm disabled")

CFG.generated_authority_enabled = false
state.bg = false
CFG.bg_index_prewarm = nil
check(policy.allow_needs_index_tick() == true, "legacy UI allows needs_index when generated authority is off")
state.bg = true
check(policy.allow_needs_index_tick() == false, "legacy background skips needs_index prewarm by default")
CFG.bg_index_prewarm = true
check(policy.allow_needs_index_tick() == true, "legacy background prewarm allows needs_index")

-- Elapsed TTL: demand lives in real seconds, not CPU time.
policy._reset_for_tests()
state.bg = false
CFG.generated_authority_enabled = true
local fake = 0
policy._set_elapsed_s_for_tests(function() return fake end)
policy.request_item_index("search", 3)
fake = 2.9
check(policy.item_index_requested() == true, "item_index still requested at 2.9 elapsed seconds")
check(policy.allow_item_index_tick() == true, "item_index ticks still allowed at 2.9s")
fake = 3.1
check(policy.item_index_requested() == false, "item_index demand expired at 3.1 elapsed seconds")
check(policy.allow_item_index_tick() == false, "item_index ticks stop after 3 elapsed seconds")

policy._reset_for_tests()
fake = 0
policy._set_elapsed_s_for_tests(function() return fake end)
policy.request_item_index("upgrade", 3)
fake = 2
policy.request_item_index("upgrade", 3)
fake = 4
check(policy.item_index_requested() == true, "refresh at t=2 keeps demand alive at t=4")
fake = 5.1
check(policy.item_index_requested() == false, "refreshed demand expires after t=5 elapsed seconds")
policy._reset_for_tests()

print(string.format("index warm policy: %d passed, %d failed", pass, fail))
os.exit(fail == 0 and 0 or 1)
