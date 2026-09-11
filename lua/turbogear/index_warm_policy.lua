-- TurboGear/index_warm_policy.lua
-- Demand-driven Search/Upgrade item_index ticks, and needs_index only when
-- generated [TG] authority is off (legacy enrichment). Background responders
-- keep both off by default; CFG.bg_index_prewarm is an internal tester
-- rollback for item_index only and is not surfaced in normal settings.

local cfg = require('config')
local state = require('state')

local M = {}

local ITEM_INDEX_TTL_S = 3.0
local item_index_until = 0
local item_index_reason = ""
local elapsed_now_s = nil

local function bg_prewarm_enabled()
    local CFG = cfg.CFG or {}
    return CFG.bg_index_prewarm == true
end

local function generated_authority_on()
    local CFG = cfg.CFG or {}
    return CFG.generated_authority_enabled ~= false
end

-- Demand TTL is a user-facing elapsed contract ("ticks stop ~3s after last
-- request"), so this must be monotonic wall time, not os.clock() CPU time.
local function now_s()
    if type(elapsed_now_s) == "function" then
        local ok, value = pcall(elapsed_now_s)
        if ok and tonumber(value) then return tonumber(value) end
    end
    local ok_mq, mqmod = pcall(require, "mq")
    if ok_mq and mqmod and mqmod.gettime then
        local okv, value = pcall(mqmod.gettime)
        if okv and tonumber(value) then return tonumber(value) / 1000 end
    end
    return os.time()
end

--- Search/Upgrade call this while they need fleet item rows. The run loop
--- only advances item_index.tick while the request is live.
function M.request_item_index(reason, ttl_s)
    ttl_s = tonumber(ttl_s)
    if ttl_s == nil then ttl_s = ITEM_INDEX_TTL_S end
    if ttl_s <= 0 then
        item_index_until = 0
        item_index_reason = ""
        return
    end
    item_index_until = now_s() + ttl_s
    item_index_reason = tostring(reason or "")
end

function M.clear_item_index_request()
    item_index_until = 0
    item_index_reason = ""
end

function M.item_index_requested()
    return now_s() < item_index_until
end

function M.item_index_request_reason()
    if not M.item_index_requested() then return "" end
    return item_index_reason
end

function M.allow_item_index_tick()
    if state.bg == true then return bg_prewarm_enabled() end
    return M.item_index_requested()
end

function M.allow_needs_index_tick()
    -- Generated [TG] does not read needs_index. Keep it cold unless that
    -- authority is explicitly off (legacy enrichment / validation).
    if generated_authority_on() then return false end
    if state.bg == true then return bg_prewarm_enabled() end
    return true
end

function M.bg_index_prewarm_enabled()
    return bg_prewarm_enabled()
end

function M._set_elapsed_s_for_tests(fn)
    elapsed_now_s = type(fn) == "function" and fn or nil
end

function M._reset_for_tests()
    item_index_until = 0
    item_index_reason = ""
    elapsed_now_s = nil
end

return M
