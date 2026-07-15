--[[
  Turbo Loot Active State
  -----------------------
  Small helper module so init.lua does not grow its top-level local count.
]]

local M = {}

local function is_active_value(value)
    local v = tostring(value or ''):upper():gsub('%s+', '')
    return v == 'ON' or v == 'TRUE' or v == '1' or v == 'ACTIVE'
end

local function query_active_for_name(mq, name, me)
    local function query(key)
        if name and name ~= '' and name ~= 'NOBODY' and name ~= me then
            return mq.TLO.MQ2Mono.Query('e3,' .. name .. ',' .. key)()
        end
        return mq.TLO.MQ2Mono.Query('e3,' .. key)()
    end

    local ok_active, active_value = pcall(query, 'TurboLootActive')
    if not ok_active or not is_active_value(active_value) then return false end

    local ok_at, at_value = pcall(query, 'TurboLootActiveAt')
    local active_at = ok_at and tonumber(at_value) or nil
    if not active_at or active_at <= 0 then return false end
    return (os.time() - active_at) <= 180
end

function M.refresh(mq, state, targets, now_ms)
    local t = tonumber(now_ms) or 0
    if t < (tonumber(state.cachedLootActiveExpiry) or 0) then
        return state.cachedLootActive == true
    end

    local active = t < (tonumber(state.lootPulseUntilMS) or 0)
    if not active then
        local me = mq.TLO.Me.Name() or mq.TLO.Me.CleanName() or ''
        for _, name in ipairs(targets or {}) do
            if query_active_for_name(mq, name, me) then
                active = true
                break
            end
        end
    end

    state.cachedLootActive = active
    state.cachedLootActiveExpiry = t + 500
    return active
end

return M
