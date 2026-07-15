local mq = require('mq')

local TAG = '\at[TurboStartup]\ax'

local tools = {
    turbo = '/lua run Turbo mini',
    turbogear = '/lua run turbogear mini',
    turborolls = '/lua run TurboRolls',
    turbogains = '/lua run Turbo/gains_toggle start',
    turbomobs = '/lua run TurboMobs',
}

local delayStartDs = tonumber((select(1, ...))) or 100
local delayStepDs = tonumber((select(2, ...))) or 50
local toolIds = {}

for i = 3, select('#', ...) do
    local id = tostring(select(i, ...) or ''):lower():match('^%s*(.-)%s*$') or ''
    if id ~= '' then toolIds[#toolIds + 1] = id end
end

-- Backward compatibility with the first helper format:
-- /lua run Turbo/startup_tool 100 turbo
if #toolIds == 0 then
    local id = tostring(select(2, ...) or ''):lower():match('^%s*(.-)%s*$') or ''
    if id ~= '' and tools[id] then
        delayStepDs = 50
        toolIds[1] = id
    end
end

if #toolIds == 0 then
    printf('%s no startup tools requested', TAG)
    return
end

for i, toolId in ipairs(toolIds) do
    local cmd = tools[toolId]
    if cmd then
        local delayDs = (i == 1) and delayStartDs or delayStepDs
        mq.delay(math.max(0, math.floor(delayDs * 100)))
        printf('%s launching %s', TAG, toolId)
        mq.cmd(cmd)
    else
        printf('%s unknown startup tool: %s', TAG, tostring(toolId))
    end
end
