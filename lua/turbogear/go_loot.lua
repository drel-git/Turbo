-- TurboGear/go_loot.lua
-- "Go loot" dispatcher: ask this character (or a peer via actor) to run
-- TurboLoot's targeted GO mode — /mac TurboLoot go <corpseId> <Item Name>.
--
-- The actual pause/nav/loot/confirm work stays in TurboLoot.mac (blocking
-- /delay model). This module only launches the mac, tracks one pending job,
-- and finishes when /tgearbg golootdone arrives (or a timeout).
--
-- Outcome notes stay space-free for /tgear golootnote parsing.

local mq = require('mq')
local cfg = require('config')
local CFG = cfg.CFG

local M = {}

local job = nil
local JOB_MAX_S = 120.0

local function now_s() return os.clock() end

local function me_name()
    local ok, n = pcall(function() return tostring(mq.TLO.Me.CleanName() or "") end)
    if ok then return n end
    return ""
end

local function turboloot_running()
    local ok, name = pcall(function()
        return tostring(mq.TLO.Macro.Name() or "")
    end)
    if not ok then return false end
    name = name:lower()
    return name:find("turboloot", 1, true) ~= nil
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
        pcall(function()
            require('announcer').note_go_status(j.item_name, me_name(), note)
        end)
    end
end

local function finish(ok, note)
    if not job then return end
    local j = job
    job = nil
    report(j, ok, note)
    if ok == true then
        pcall(function() require('inventory_watch').note_change(true, false) end)
        -- Turbo Review: drop the skip row once TurboLoot confirmed looted.
        pcall(function()
            mq.cmd(string.format('/squelch /turboreviewgoloot looted %d %s',
                tonumber(j.corpse_id) or 0, tostring(j.item_name or '')))
        end)
    end
end

local function launch_turboloot_go(corpse_id, item_name)
    corpse_id = tonumber(corpse_id) or 0
    item_name = tostring(item_name or ""):match("^%s*(.-)%s*$") or ""
    if corpse_id <= 0 or item_name == "" then return false end
    -- Spaces in the item name become separate mac params (Param2..); TurboLoot
    -- BuildGoItemName joins them again.
    mq.cmd(string.format('/mac TurboLoot go %d %s', corpse_id, item_name))
    return true
end

-- Start a job. payload: { item_name, item_id, corpse_id, reply_to }.
-- Returns true, or false + token.
function M.request(payload)
    payload = type(payload) == "table" and payload or {}
    local corpse_id = tonumber(payload.corpse_id) or 0
    local item_name = tostring(payload.item_name or "")
    if job then
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
    if turboloot_running() then return false, "busy" end

    local okC, combat = pcall(function() return mq.TLO.Me.Combat() == true end)
    if okC and combat then return false, "in_combat" end

    job = {
        item_name = item_name,
        item_id = tonumber(payload.item_id) or 0,
        corpse_id = corpse_id,
        reply_to = tostring(payload.reply_to or ""),
        started_at = now_s(),
        launched = false,
    }
    if not launch_turboloot_go(corpse_id, item_name) then
        job = nil
        return false, "launch_failed"
    end
    job.launched = true
    print(string.format("\at[TurboGear]\ax go-loot: launching TurboLoot go %d %s",
        corpse_id, item_name))
    return true
end

-- Called from /tgearbg golootdone (TurboLoot GO mode outcome).
function M.on_mac_line(status, detail, corpse_id, item_hint)
    if not job then return false end
    status = tostring(status or ""):lower()
    corpse_id = tonumber(corpse_id) or 0
    if corpse_id > 0 and (tonumber(job.corpse_id) or 0) > 0 and corpse_id ~= job.corpse_id then
        return false
    end
    if status == "looted" or status == "ok" or status == "success" then
        finish(true, "looted")
        return true
    end
    if status == "starting" then
        report(job, true, "going")
        return true
    end
    if status == "failed" or status == "fail" then
        local note = tostring(detail or "failed"):match("^(%S+)") or "failed"
        note = note:gsub("[^%w_]", "")
        if note == "" then note = "failed" end
        finish(false, note)
        return true
    end
    return false
end

function M.busy() return job ~= nil end

function M.tick()
    if not job then return end
    local age = now_s() - (tonumber(job.started_at) or now_s())
    if age >= JOB_MAX_S then
        finish(false, "timeout_job")
        return
    end
    -- Mac finished without a [GOLOOT] outcome line (crash/endmac): fail after a
    -- short grace so the echo can still arrive.
    if job.launched and not turboloot_running() and age >= 8 then
        if not job.ended_at then
            job.ended_at = now_s()
        elseif (now_s() - job.ended_at) >= 3 then
            finish(false, "loot_failed")
        end
    elseif turboloot_running() then
        job.ended_at = nil
    end
end

-- Kept for unit tests that still exercise decide(); GO mode does not use it.
function M.decide(phase, ctx)
    ctx = ctx or {}
    return { action = "fail", note = "legacy_decide_unused" }
end

return M
