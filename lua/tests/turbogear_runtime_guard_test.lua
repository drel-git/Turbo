package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

local G = require('runtime_guard')

local passed, failed = 0, 0

local function check(cond, label)
    if cond then
        passed = passed + 1
    else
        failed = failed + 1
        io.stderr:write('FAIL: ', tostring(label), '\n')
    end
end

check(G.status_is_running('Running') == true, 'Running is active')
check(G.status_is_running('running') == true, 'running is active')
check(G.status_is_running('RUN') == true, 'RUN is active')
check(G.status_is_running('Not Running') == false, 'Not Running is inactive')
check(G.status_is_running('Stopped') == false, 'Stopped is inactive')
check(G.status_is_running('Ending') == false, 'Ending is inactive')
check(G.status_is_running('') == false, 'empty is inactive')

check(G.autostart_decision({ main = false, bg = false }, '') == 'start_bg', 'no owner starts bg')
check(G.autostart_decision({ main = false, bg = true }, '') == 'publish_bg', 'bg owner publishes')
check(G.autostart_decision({ main = true, bg = false }, '') == 'start_bg', 'main UI starts bg owner')
check(G.autostart_decision({ main = true, bg = true }, '') == 'publish_bg', 'normal duplicate prefers existing bg command path')
check(G.autostart_decision({ main = true, bg = false }, 'repair') == 'repair_bg', 'repair starts bg beside main UI')
check(G.autostart_decision({ main = true, bg = true }, 'repair') == 'repair_bg', 'repair restarts bg and leaves main UI')
check(G.autostart_decision({ main = false, bg = true }, 'repair') == 'repair_bg', 'repair restarts bg owner')
check(G.autostart_decision({ main = false, bg = false }, 'repair') == 'repair_bg', 'repair starts bg when no owner')

-- STATIC ROLES: bg processes are 'bg-owner', every UI process is 'viewer';
-- there is no ui-owner or promotion state.
check(G.role({ bg = true }, true, { bg = true }) == 'bg-owner', 'role bg owner')
check(G.role({ bg = false, engine_claim_disabled = true }, false, { bg = true }) == 'viewer', 'role viewer')
check(G.role({ bg = false, engine_claim_disabled = false }, true, {}) == 'viewer', 'ui is always viewer (engine ok ignored)')
check(G.role({ bg = false, engine_claim_disabled = false }, false, {}) == 'viewer', 'ui is always viewer (no promote-pending)')
check(G.role(nil, false, nil) == 'viewer', 'role nil-safe')

-- Announce passivity: bg mutes only while a main UI runs on the same box.
check(G.announce_passive(true, { main = true }) == true, 'bg passive when local UI running')
check(G.announce_passive(true, { main = false }) == false, 'bg active when no local UI')
check(G.announce_passive(true, nil) == false, 'bg active when scripts unknown')
check(G.announce_passive(false, { main = true }) == false, 'ui never announce-passive')
check(G.announce_passive(false, { main = false }) == false, 'ui never announce-passive (no ui script flag)')

check(G.script_summary({ main = true, bg = false }) == 'main=running bg=off', 'script summary')

-- R5: should_request_bg_sync gating
check(select(1, G.should_request_bg_sync({ bg_ready = true, now = 0, deadline = 100 })) == true, 'sync fires when bg is ready')
check(select(2, G.should_request_bg_sync({ bg_ready = true, now = 0, deadline = 100 })) == 'bg_ready', 'reason is bg_ready')
check(G.should_request_bg_sync({ bg_ready = false, now = 1, deadline = 100 }) == false, 'sync waits before deadline when not ready')
check(select(1, G.should_request_bg_sync({ bg_ready = false, now = 100, deadline = 100 })) == true, 'sync fires at the deadline fallback')
check(select(2, G.should_request_bg_sync({ bg_ready = false, now = 100, deadline = 100 })) == 'deadline', 'reason is deadline')
check(G.should_request_bg_sync({ sent = true, bg_ready = true, now = 999, deadline = 0 }) == false, 'never re-sends once sent')

if failed > 0 then
    io.stderr:write(string.format('turbogear_runtime_guard_test: %d passed, %d failed\n', passed, failed))
    os.exit(1)
end

print(string.format('turbogear_runtime_guard_test: %d passed, %d failed', passed, failed))
