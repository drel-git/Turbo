-- TurboGear/go_loot.lua
-- "Go loot" runner: walk this character to a corpse TurboLoot left an item on
-- (linked-items Go buttons) and pick that item up. One job at a time, driven
-- as a non-blocking state machine from the main run loop (M.tick()), so it
-- never stalls sync or the UI.
--
-- Phases: reveal -> move -> open -> window -> scan -> pickup -> (report)
-- "reveal" mirrors Turbo Reloot: /hidecorpse none so a looter who already hid
-- corpses can still see the spawn id, then we restore hidecorpse looted.
-- Outcome notes are single tokens (no spaces) because they travel through
-- /tgear golootnote argument parsing on the way to the panel.
--
-- The decision core (M.decide) is pure - plain values in, {action, note} out -
-- so the phase logic is unit-testable offline (turbogear_go_loot_test.lua).

local mq = require('mq')
local cfg = require('config')
local CFG = cfg.CFG

local M = {}

local job = nil

local ARRIVE_DIST = 15.0
local REVEAL_WAIT_S = 2.0
local NAV_REISSUE_S = 4.0
local JOB_MAX_S = 90.0

local function now_s() return os.clock() end

local function spawn_with_id(id)
    id = tonumber(id) or 0
    if id <= 0 then return nil end
    local function accept(sp)
        if not sp or not sp.ID then return nil end
        if (tonumber(sp.ID()) or 0) ~= id then return nil end
        return sp
    end
    -- TurboLoot stamped this spawn id. Trust any resolvable spawn with that id
    -- (some builds report corpses as NPC/blank Type right after hidecorpse none).
    local sp = accept(mq.TLO.Spawn(id))
    if sp then return sp end
    sp = accept(mq.TLO.Spawn(string.format('id %d', id)))
    if sp then return sp end
    sp = accept(mq.TLO.Spawn(string.format('corpse id %d', id)))
    if sp then return sp end
    return nil
end

local function corpse_spawn(corpse_id)
    local ok, s = pcall(function() return spawn_with_id(corpse_id) end)
    if ok then return s end
    return nil
end

local function corpse_distance(corpse_id)
    local s = corpse_spawn(corpse_id)
    if not s then return nil end
    local ok, d = pcall(function()
        local d3 = tonumber(s.Distance3D())
        if d3 ~= nil then return d3 end
        return tonumber(s.Distance() or 0)
    end)
    if ok then return d end
    return nil
end

local function nav_active()
    local ok, active = pcall(function()
        local nav = mq.TLO.Navigation
        return nav ~= nil and nav.Active ~= nil and nav.Active() == true
    end)
    return ok and active == true
end

local function reveal_hidden_corpses()
    pcall(function() mq.cmd('/squelch /hidecorpse none') end)
end

-- Restore the common TurboLoot post-loot hide so Reloot-style unhide does not
-- leave every corpse visible for the rest of the session. Exact INI mode is
-- not read here; looted matches the default that caused Go-loot "corpse gone".
local function restore_corpse_hide()
    pcall(function() mq.cmd('/squelch /hidecorpse looted') end)
end

local function pause_e3_for_job()
    -- Same idea as TurboLoot PauseE3Logic: E3 will otherwise re-assert follow /
    -- chase and cancel our nav mid-run (common right after a Reloot/TurboLoot).
    -- Issue twice: after TurboLoot, the first /e3p on is often delayed behind
    -- the mac's /e3p off echo and we spent ~8s revealing while E3 was still live.
    pcall(function()
        mq.cmd('/squelch /e3p on')
        mq.cmd('/squelch /e3p on')
    end)
    return true
end

local function resume_e3_for_job(was_paused)
    if not was_paused then return end
    pcall(function() mq.cmd('/squelch /e3p off') end)
end

local function nav_available()
    local ok, loaded = pcall(function()
        local nav = mq.TLO.Navigation
        return nav ~= nil and nav.MeshLoaded ~= nil and nav.MeshLoaded() == true
    end)
    return ok and loaded == true
end

local function stop_movement(used_nav)
    pcall(function()
        if used_nav then
            mq.cmd('/squelch /nav stop')
        else
            mq.cmd('/squelch /moveto off')
        end
    end)
end

-- Mirror turboloot.mac PauseAFollow / UnpauseAFollow / StopChaseForUtility /
-- StopFollowAndMovement so a Go-loot run does not fight /afollow or leave the
-- character stranded after the corpse. /chaseme off is fire-and-forget like the
-- mac (the chase leader re-asserts); /afollow uses pause/unpause so the exact
-- prior follow target is restored.
local function advpath_following()
    local ok, following = pcall(function()
        local ap = mq.TLO.AdvPath
        return ap ~= nil and ap.Following ~= nil and ap.Following() == true
    end)
    return ok and following == true
end

local function advpath_loaded()
    local ok, loaded = pcall(function()
        local name = mq.TLO.Plugin('MQ2AdvPath').Name()
        return name ~= nil and tostring(name) ~= ""
    end)
    return ok and loaded == true
end

local function pause_follow_for_job()
    local paused = false
    if advpath_loaded() then
        if advpath_following() then
            paused = true
        end
    else
        -- Plugin not loaded: assume /afollow might still be active (mac does this).
        paused = true
    end
    if paused then
        pcall(function() mq.cmd('/squelch /afollow pause') end)
    end
    return paused
end

local function resume_follow_for_job(was_paused)
    if not was_paused then return end
    local ok_fd, feigning = pcall(function() return mq.TLO.Me.Feigning() == true end)
    if ok_fd and feigning then return end
    pcall(function() mq.cmd('/squelch /afollow unpause') end)
end

local function stop_chase_and_stick()
    pcall(function()
        mq.cmd('/squelch /chaseme off')
        mq.cmd('/squelch /stick off')
        mq.cmd('/squelch /keypress forward')
    end)
end

local function target_corpse(corpse_id)
    pcall(function()
        mq.cmd(string.format('/squelch /target id %d', corpse_id))
        mq.cmd(string.format('/squelch /face fast id %d', corpse_id))
    end)
end

-- ---------------------------------------------------------------------------
-- Pure decision core. ctx carries plain values; returns { action = <string>,
-- note = <token or nil> }. Actions: "wait", "arrived", "fail", "open_window",
-- "loot_anyway", "found", "not_found", "confirm", "accept_quantity",
-- "stash_cursor", "done_looted", "fail_loot", "ready", "retry_reveal".
-- ---------------------------------------------------------------------------
function M.decide(phase, ctx)
    ctx = ctx or {}
    if phase == "reveal" then
        if ctx.corpse_exists then
            local max_dist = tonumber(ctx.max_distance) or 400
            if (tonumber(ctx.distance) or 0) > max_dist then
                return { action = "fail", note = "too_far" }
            end
            return { action = "ready" }
        end
        if ctx.timed_out then
            if (tonumber(ctx.reveal_retries_left) or 0) > 0 then
                return { action = "retry_reveal" }
            end
            return { action = "fail", note = "corpse_gone" }
        end
        return { action = "wait" }
    elseif phase == "move" then
        if ctx.corpse_exists then
            if (tonumber(ctx.distance) or math.huge) <= (tonumber(ctx.arrive_dist) or ARRIVE_DIST) then
                return { action = "arrived" }
            end
            if ctx.timed_out then return { action = "fail", note = "timeout_move" } end
            return { action = "wait" }
        end
        -- Spawn TLO still empty after reveal: keep blind /nav id alive, or give up.
        if ctx.allow_blind then
            if ctx.nav_active then return { action = "wait" } end
            if ctx.timed_out then return { action = "fail", note = "timeout_move" } end
            return { action = "blind_retry" }
        end
        return { action = "fail", note = "corpse_gone" }
    elseif phase == "open" then
        -- Target id match is enough even when Spawn TLO type/filter is weird.
        if ctx.target_is_corpse then return { action = "open_window" } end
        if not ctx.corpse_exists then return { action = "fail", note = "corpse_gone" } end
        if ctx.timed_out then
            if ctx.close_enough then return { action = "loot_anyway" } end
            return { action = "fail", note = "no_target" }
        end
        return { action = "wait" }
    elseif phase == "window" then
        if ctx.window_open then return { action = "found" } end -- proceed to scan
        if ctx.timed_out then return { action = "fail", note = "no_window" } end
        return { action = "wait" }
    elseif phase == "scan" then
        if not ctx.window_open then return { action = "fail", note = "window_closed" } end
        if (tonumber(ctx.item_slot) or 0) > 0 then return { action = "found" } end
        if ctx.scan_complete then return { action = "not_found", note = "not_found" } end
        if ctx.timed_out then return { action = "fail", note = "not_found" } end
        return { action = "wait" }
    elseif phase == "pickup" then
        if ctx.confirm_open then return { action = "confirm" } end
        if ctx.quantity_open then return { action = "accept_quantity" } end
        if ctx.cursor_item then return { action = "stash_cursor" } end
        if ctx.slot_empty or ctx.got_item then return { action = "done_looted", note = "looted" } end
        if ctx.timed_out then return { action = "fail_loot", note = "loot_failed" } end
        return { action = "wait" }
    end
    return { action = "fail", note = "bad_phase" }
end

-- ---------------------------------------------------------------------------
-- Job lifecycle
-- ---------------------------------------------------------------------------
local function close_loot_window()
    pcall(function()
        if mq.TLO.Window('LootWnd').Open() then
            mq.cmd('/squelch /notify LootWnd DoneButton leftmouseup')
        end
    end)
end

local function report(j, ok, note)
    note = tostring(note or (ok and "looted" or "failed"))
    print(string.format("\at[TurboGear]\ax go-loot %s: %s", tostring(j.item_name or "?"), note))
    if tostring(j.reply_to or "") ~= "" then
        pcall(function()
            local Engine = require('engine').Engine
            if Engine and Engine.send_go_loot_result then
                Engine.send_go_loot_result(j.reply_to, {
                    item_name = j.item_name,
                    corpse_id = j.corpse_id,
                    ok = ok == true,
                    note = note,
                })
            end
        end)
    else
        -- Locally-initiated run: update this instance's panel directly.
        pcall(function()
            require('announcer').note_go_status(j.item_name, tostring(mq.TLO.Me.CleanName() or "?"), note)
        end)
    end
end

-- Interim panel/chat status (does not end the job). Tokens stay space-free.
local function progress(j, note)
    note = tostring(note or "")
    if note == "" or not j then return end
    if j.last_progress == note then return end
    j.last_progress = note
    report(j, true, note)
end

local function enter_window_phase(j)
    -- Match TurboLoot: accept no-drop prompts automatically for this pickup.
    pcall(function() mq.cmd('/squelch /lootnodrop always') end)
    mq.cmd('/loot')
    j.phase = "window"
    j.deadline = now_s() + (tonumber(CFG.go_loot_window_timeout_s) or 8)
    progress(j, "looting")
    print(string.format("\at[TurboGear]\ax go-loot: /loot on corpse %d for %s",
        j.corpse_id, j.item_name))
end

local function begin_open(j)
    stop_movement(j.used_nav)
    j.moving = false
    target_corpse(j.corpse_id)
    progress(j, "opening")
    print(string.format("\at[TurboGear]\ax go-loot: opening corpse %d for %s",
        j.corpse_id, j.item_name))
    -- Issue /loot immediately (TurboLoot does target+/loot in one step). Waiting
    -- in phase "open" for another tick left us looking stuck on "going" while
    -- the loot window never appeared.
    enter_window_phase(j)
end

local function begin_move(j, opts)
    opts = opts or {}
    local dist = corpse_distance(j.corpse_id)
    -- Already in loot range: do not fire /nav (Nav "Reached destination" can
    -- arrive long after we should have /loot'd, and left us stuck in move).
    if dist ~= nil and dist <= ARRIVE_DIST then
        print(string.format("\at[TurboGear]\ax go-loot: already at corpse %d for %s (%.0fft)",
            j.corpse_id, j.item_name, dist))
        begin_open(j)
        return
    end
    local used_nav = nav_available()
    j.used_nav = used_nav
    j.moving = true
    j.phase = "move"
    j.allow_blind = opts.blind == true or dist == nil
    j.deadline = now_s() + (tonumber(CFG.go_loot_arrive_timeout_s) or 45)
    j.last_nav_at = now_s()
    if used_nav then
        mq.cmd(string.format('/squelch /nav id %d distance=%d', j.corpse_id, math.floor(ARRIVE_DIST) - 5))
    else
        mq.cmd(string.format('/squelch /moveto id %d', j.corpse_id))
    end
    progress(j, "heading")
    local how = used_nav and "nav" or "moveto"
    if j.allow_blind and dist == nil then how = how .. "+blind" end
    print(string.format("\at[TurboGear]\ax go-loot: heading to corpse %d for %s (%s, %.0fft)",
        j.corpse_id, j.item_name, how, tonumber(dist) or -1))
end

local function finish(ok, note)
    if not job then return end
    if job.moving then stop_movement(job.used_nav) end
    close_loot_window()
    pcall(function() mq.cmd('/squelch /lootnodrop never') end)
    local was_paused = job.afollow_paused == true
    local e3_paused = job.e3_paused == true
    local did_reveal = job.revealed_corpses == true
    local j = job
    job = nil
    if did_reveal then restore_corpse_hide() end
    resume_follow_for_job(was_paused)
    resume_e3_for_job(e3_paused)
    report(j, ok, note)
    -- Inventory may already be updated before the "You have looted" chat line
    -- fires; nudge the watch so peers (and our own Store) see ownership soon
    -- without waiting for a heartbeat.
    if ok == true then
        pcall(function() require('inventory_watch').note_change(true, false) end)
    end
end

-- Start a job. payload: { item_name, item_id, corpse_id, reply_to }.
-- Returns true, or false + a token describing why it refused.
function M.request(payload)
    payload = type(payload) == "table" and payload or {}
    local corpse_id = tonumber(payload.corpse_id) or 0
    local item_name = tostring(payload.item_name or "")
    if job then
        -- Stale job that never finished (e.g. tick error left E3 paused): clear
        -- it so a new Go click can recover instead of returning "already" forever.
        local age = now_s() - (tonumber(job.started_at) or now_s())
        if age >= JOB_MAX_S then
            finish(false, "timeout_job")
        else
            local same = (tonumber(job.corpse_id) or 0) == corpse_id
                and tostring(job.item_name or ""):lower() == item_name:lower()
            if same then
                local reply = tostring(payload.reply_to or "")
                if reply ~= "" then job.reply_to = reply end
                return true, "already"
            end
            return false, "busy"
        end
    end
    if corpse_id <= 0 then return false, "no_corpse_id" end
    if item_name == "" then return false, "no_item" end
    local okC, combat = pcall(function() return mq.TLO.Me.Combat() == true end)
    if okC and combat then return false, "in_combat" end

    -- Same prelude as turboloot sell/bank/tribute/loot: pause E3, stop chase,
    -- pause afollow, clear stick/nav before we issue our own movement.
    local e3_paused = pause_e3_for_job()
    stop_chase_and_stick()
    local afollow_paused = pause_follow_for_job()
    stop_movement(true)
    stop_movement(false)

    local max_dist = tonumber(CFG.go_loot_max_distance) or 400
    local dist = corpse_distance(corpse_id)
    job = {
        item_name = item_name,
        item_id = tonumber(payload.item_id) or 0,
        corpse_id = corpse_id,
        reply_to = tostring(payload.reply_to or ""),
        used_nav = false,
        moving = false,
        slot = 0,
        afollow_paused = afollow_paused,
        e3_paused = e3_paused,
        max_distance = max_dist,
        revealed_corpses = false,
        reveal_retries_left = 4,
        started_at = now_s(),
        last_reveal_pulse = 0,
    }

    if dist ~= nil then
        if dist > max_dist then
            job = nil
            resume_follow_for_job(afollow_paused)
            resume_e3_for_job(e3_paused)
            return false, "too_far"
        end
        begin_move(job)
        return true
    end

    -- Corpse not in spawn list: usually hidecorpse after TurboLoot. Unhide
    -- like Reloot, wait a beat for the client, then start nav (or fail).
    reveal_hidden_corpses()
    job.revealed_corpses = true
    job.phase = "reveal"
    job.deadline = now_s() + REVEAL_WAIT_S
    progress(job, "revealing")
    print(string.format("\at[TurboGear]\ax go-loot: revealing hidden corpses for id %d (%s)",
        corpse_id, job.item_name))
    return true
end

function M.busy() return job ~= nil end

local function find_item_slot(j)
    -- Scan the open corpse for the item by name (case-insensitive exact).
    local want = tostring(j.item_name or ""):lower()
    local okN, count = pcall(function() return tonumber(mq.TLO.Corpse.Items() or 0) end)
    if not okN then return 0, true end
    count = count or 0
    for slot = 1, count do
        local okI, name = pcall(function()
            return tostring(mq.TLO.Corpse.Item(slot).Name() or "")
        end)
        if okI and name ~= "" and name:lower() == want then return slot, true end
    end
    return 0, true
end

local function tick_once()
    local j = job
    if not j then return false end
    local phase_before = j.phase
    local timed_out = now_s() > (tonumber(j.deadline) or 0)

    if j.phase == "reveal" then
        local dist = corpse_distance(j.corpse_id)
        local d = M.decide("reveal", {
            corpse_exists = dist ~= nil,
            distance = dist,
            max_distance = j.max_distance,
            timed_out = timed_out,
            reveal_retries_left = j.reveal_retries_left,
        })
        if d.action == "ready" then
            begin_move(j)
        elseif d.action == "retry_reveal" then
            j.reveal_retries_left = math.max(0, (tonumber(j.reveal_retries_left) or 0) - 1)
            reveal_hidden_corpses()
            target_corpse(j.corpse_id)
            j.deadline = now_s() + REVEAL_WAIT_S
            print(string.format("\at[TurboGear]\ax go-loot: reveal retry (%d left) for id %d",
                j.reveal_retries_left, j.corpse_id))
        elseif d.action == "wait" then
            -- Keep pulsing unhide + target while the client refreshes spawns.
            local now = now_s()
            if (now - (tonumber(j.last_reveal_pulse) or 0)) >= 1.0 then
                j.last_reveal_pulse = now
                reveal_hidden_corpses()
                target_corpse(j.corpse_id)
            end
        elseif d.action == "fail" then
            -- Last chance: /nav by id even when Spawn TLO is still empty.
            print(string.format("\at[TurboGear]\ax go-loot: spawn TLO empty for id %d - trying blind nav",
                j.corpse_id))
            begin_move(j, { blind = true })
        end
    elseif j.phase == "move" then
        local dist = corpse_distance(j.corpse_id)
        local d = M.decide("move", {
            corpse_exists = dist ~= nil,
            distance = dist,
            arrive_dist = ARRIVE_DIST,
            timed_out = timed_out,
            allow_blind = j.allow_blind == true,
            nav_active = nav_active(),
        })
        if d.action == "arrived" then
            begin_open(j)
        elseif d.action == "wait" or d.action == "blind_retry" then
            local now = now_s()
            if (now - (tonumber(j.last_nav_at) or 0)) >= NAV_REISSUE_S then
                j.last_nav_at = now
                stop_chase_and_stick()
                pause_follow_for_job()
                reveal_hidden_corpses()
                if j.used_nav then
                    mq.cmd(string.format('/squelch /nav id %d distance=%d', j.corpse_id, math.floor(ARRIVE_DIST) - 5))
                else
                    mq.cmd(string.format('/squelch /moveto id %d', j.corpse_id))
                end
            end
            -- If we somehow got close enough for /loot without a clean TLO read,
            -- keep trying to target/open while nav settles.
            if j.allow_blind and not nav_active() then
                target_corpse(j.corpse_id)
                local okT, tid = pcall(function() return tonumber(mq.TLO.Target.ID() or 0) end)
                if okT and (tid or 0) == j.corpse_id then
                    begin_open(j)
                end
            end
        elseif d.action == "fail" then
            finish(false, d.note)
        end
    elseif j.phase == "open" then
        local s = corpse_spawn(j.corpse_id)
        local dist = s and corpse_distance(j.corpse_id) or nil
        local okT, target_id = pcall(function() return tonumber(mq.TLO.Target.ID() or 0) end)
        local d = M.decide("open", {
            corpse_exists = s ~= nil,
            target_is_corpse = okT and (target_id or 0) == j.corpse_id,
            close_enough = dist ~= nil and dist <= ARRIVE_DIST,
            timed_out = timed_out,
        })
        if d.action == "open_window" or d.action == "loot_anyway" then
            enter_window_phase(j)
        elseif d.action == "wait" then
            target_corpse(j.corpse_id)
        elseif d.action == "fail" then
            finish(false, d.note)
        end
    elseif j.phase == "window" then
        local okW, open = pcall(function() return mq.TLO.Window('LootWnd').Open() == true end)
        local d = M.decide("window", { window_open = okW and open, timed_out = timed_out })
        if d.action == "found" then
            j.phase = "scan"
            j.deadline = now_s() + 4
        elseif d.action == "fail" then
            finish(false, d.note)
        elseif d.action == "wait" then
            -- Keep trying /loot while waiting for the window.
            target_corpse(j.corpse_id)
            mq.cmd('/loot')
        end
    elseif j.phase == "scan" then
        local okW, open = pcall(function() return mq.TLO.Window('LootWnd').Open() == true end)
        local slot, complete = find_item_slot(j)
        local d = M.decide("scan", {
            window_open = okW and open,
            item_slot = slot,
            scan_complete = complete,
            timed_out = timed_out,
        })
        if d.action == "found" then
            j.slot = slot
            mq.cmd(string.format('/ctrl /itemnotify loot%d rightmouseup', slot))
            j.phase = "pickup"
            j.deadline = now_s() + 6
        elseif d.action == "not_found" or d.action == "fail" then
            finish(false, d.note)
        end
    elseif j.phase == "pickup" then
        local ctx = { got_item = j.got_item == true }
        pcall(function() ctx.confirm_open = mq.TLO.Window('ConfirmationDialogBox').Open() == true end)
        pcall(function() ctx.quantity_open = mq.TLO.Window('QuantityWnd').Open() == true end)
        pcall(function() ctx.cursor_item = (tonumber(mq.TLO.Cursor.ID() or 0) or 0) > 0 end)
        pcall(function()
            ctx.slot_empty = (tonumber(mq.TLO.Corpse.Item(j.slot).ID() or 0) or 0) <= 0
        end)
        ctx.timed_out = timed_out
        local d = M.decide("pickup", ctx)
        if d.action == "confirm" then
            mq.cmd('/squelch /notify ConfirmationDialogBox Yes_Button leftmouseup')
            mq.cmd('/squelch /notify ConfirmationDialogBox CD_Yes_Button leftmouseup')
        elseif d.action == "accept_quantity" then
            mq.cmd('/squelch /notify QuantityWnd AcceptButton leftmouseup')
        elseif d.action == "stash_cursor" then
            mq.cmd('/squelch /autoinventory')
            j.got_item = true
        elseif d.action == "done_looted" then
            finish(true, d.note)
        elseif d.action == "fail_loot" then
            finish(false, d.note)
        end
    else
        finish(false, "bad_phase")
    end

    return job ~= nil and job.phase ~= phase_before
end

function M.tick()
    if not job then return end
    if (now_s() - (tonumber(job.started_at) or now_s())) >= JOB_MAX_S then
        finish(false, "timeout_job")
        return
    end
    -- Allow reveal->open->window to advance in one frame when already in range
    -- so we do not sit in "move" waiting on a pointless /nav completion.
    for _ = 1, 6 do
        if not tick_once() then break end
    end
end

return M
