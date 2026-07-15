-- TurboGear/go_loot.lua
-- "Go loot" runner: walk this character to a corpse TurboLoot left an item on
-- (linked-items Go buttons) and pick that item up. One job at a time, driven
-- as a non-blocking state machine from the main run loop (M.tick()), so it
-- never stalls sync or the UI.
--
-- Phases: move -> open -> window -> scan -> pickup -> (report)
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

local function now_s() return os.clock() end

local function corpse_spawn(corpse_id)
    local ok, s = pcall(function()
        local sp = mq.TLO.Spawn(tonumber(corpse_id) or 0)
        if not sp or not sp.ID then return nil end
        if (tonumber(sp.ID()) or 0) <= 0 then return nil end
        if tostring(sp.Type() or "") ~= "Corpse" then return nil end
        return sp
    end)
    if ok then return s end
    return nil
end

local function corpse_distance(corpse_id)
    local s = corpse_spawn(corpse_id)
    if not s then return nil end
    local ok, d = pcall(function() return tonumber(s.Distance3D() or 0) end)
    if ok then return d end
    return nil
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

-- ---------------------------------------------------------------------------
-- Pure decision core. ctx carries plain values; returns { action = <string>,
-- note = <token or nil> }. Actions: "wait", "arrived", "fail", "open_window",
-- "found", "not_found", "confirm", "accept_quantity", "stash_cursor",
-- "done_looted", "fail_loot".
-- ---------------------------------------------------------------------------
function M.decide(phase, ctx)
    ctx = ctx or {}
    if phase == "move" then
        if not ctx.corpse_exists then return { action = "fail", note = "corpse_gone" } end
        if (tonumber(ctx.distance) or math.huge) <= (tonumber(ctx.arrive_dist) or ARRIVE_DIST) then
            return { action = "arrived" }
        end
        if ctx.timed_out then return { action = "fail", note = "timeout_move" } end
        return { action = "wait" }
    elseif phase == "open" then
        if not ctx.corpse_exists then return { action = "fail", note = "corpse_gone" } end
        if ctx.target_is_corpse then return { action = "open_window" } end
        if ctx.timed_out then return { action = "fail", note = "no_target" } end
        return { action = "wait" }
    elseif phase == "window" then
        if ctx.window_open then return { action = "found" } end -- proceed to scan
        if ctx.timed_out then return { action = "fail", note = "no_window" } end
        return { action = "wait" }
    elseif phase == "scan" then
        if not ctx.window_open then return { action = "fail", note = "window_closed" } end
        if (tonumber(ctx.item_slot) or 0) > 0 then return { action = "found" } end
        if ctx.scan_complete then return { action = "not_found", note = "not_found" } end
        return { action = "wait" }
    elseif phase == "pickup" then
        if ctx.confirm_open then return { action = "confirm" } end
        if ctx.quantity_open then return { action = "accept_quantity" } end
        if ctx.cursor_item then return { action = "stash_cursor" } end
        if ctx.slot_empty then return { action = "done_looted", note = "looted" } end
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

local function finish(ok, note)
    if not job then return end
    if job.moving then stop_movement(job.used_nav) end
    close_loot_window()
    local was_paused = job.afollow_paused == true
    local j = job
    job = nil
    resume_follow_for_job(was_paused)
    report(j, ok, note)
end

-- Start a job. payload: { item_name, item_id, corpse_id, reply_to }.
-- Returns true, or false + a token describing why it refused.
function M.request(payload)
    payload = type(payload) == "table" and payload or {}
    if job then return false, "busy" end
    local corpse_id = tonumber(payload.corpse_id) or 0
    if corpse_id <= 0 then return false, "no_corpse_id" end
    if tostring(payload.item_name or "") == "" then return false, "no_item" end
    local okC, combat = pcall(function() return mq.TLO.Me.Combat() == true end)
    if okC and combat then return false, "in_combat" end
    local dist = corpse_distance(corpse_id)
    if dist == nil then return false, "corpse_gone" end
    local max_dist = tonumber(CFG.go_loot_max_distance) or 400
    if dist > max_dist then return false, "too_far" end

    -- Same prelude as turboloot sell/bank/tribute/loot: stop chase, pause
    -- afollow, clear stick/nav before we issue our own movement.
    stop_chase_and_stick()
    local afollow_paused = pause_follow_for_job()
    stop_movement(true)
    stop_movement(false)

    local used_nav = nav_available()
    if used_nav then
        mq.cmd(string.format('/squelch /nav id %d distance=%d', corpse_id, math.floor(ARRIVE_DIST) - 5))
    else
        mq.cmd(string.format('/squelch /moveto id %d', corpse_id))
    end
    job = {
        item_name = tostring(payload.item_name or ""),
        item_id = tonumber(payload.item_id) or 0,
        corpse_id = corpse_id,
        reply_to = tostring(payload.reply_to or ""),
        phase = "move",
        deadline = now_s() + (tonumber(CFG.go_loot_arrive_timeout_s) or 45),
        used_nav = used_nav,
        moving = true,
        slot = 0,
        afollow_paused = afollow_paused,
    }
    print(string.format("\at[TurboGear]\ax go-loot: heading to corpse %d for %s (%s)",
        corpse_id, job.item_name, used_nav and "nav" or "moveto"))
    return true
end

function M.busy() return job ~= nil end

local function find_item_slot(j)
    -- Scan the open corpse for the item by name (case-insensitive exact first,
    -- then prefix - loot slots show full names, so exact should normally hit).
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

function M.tick()
    if not job then return end
    local j = job
    local timed_out = now_s() > (tonumber(j.deadline) or 0)

    if j.phase == "move" then
        local dist = corpse_distance(j.corpse_id)
        local d = M.decide("move", {
            corpse_exists = dist ~= nil,
            distance = dist,
            arrive_dist = ARRIVE_DIST,
            timed_out = timed_out,
        })
        if d.action == "arrived" then
            stop_movement(j.used_nav)
            j.moving = false
            mq.cmd(string.format('/squelch /target id %d', j.corpse_id))
            j.phase = "open"
            j.deadline = now_s() + 3
        elseif d.action == "fail" then
            finish(false, d.note)
        end
    elseif j.phase == "open" then
        local s = corpse_spawn(j.corpse_id)
        local okT, target_id = pcall(function() return tonumber(mq.TLO.Target.ID() or 0) end)
        local d = M.decide("open", {
            corpse_exists = s ~= nil,
            target_is_corpse = okT and (target_id or 0) == j.corpse_id,
            timed_out = timed_out,
        })
        if d.action == "open_window" then
            mq.cmd('/loot')
            j.phase = "window"
            j.deadline = now_s() + (tonumber(CFG.go_loot_window_timeout_s) or 6)
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
        end
    elseif j.phase == "scan" then
        local okW, open = pcall(function() return mq.TLO.Window('LootWnd').Open() == true end)
        local slot, complete = find_item_slot(j)
        local d = M.decide("scan", {
            window_open = okW and open,
            item_slot = slot,
            scan_complete = complete,
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
        local ctx = {}
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
        elseif d.action == "accept_quantity" then
            mq.cmd('/squelch /notify QuantityWnd AcceptButton leftmouseup')
        elseif d.action == "stash_cursor" then
            mq.cmd('/squelch /autoinventory')
            -- Cursor had the item: the pickup worked even if the slot read lags.
            j.got_item = true
        elseif d.action == "done_looted" then
            finish(true, d.note)
        elseif d.action == "fail_loot" then
            finish(false, d.note)
        end
    else
        finish(false, "bad_phase")
    end
end

return M
