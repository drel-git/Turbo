--[[
  Turbo Skip Review — CLI validator
  ----------------------------------
  @version lua/Turbo/skips_show.lua 1.0.0
  Usage: /lua run Turbo/skips_show
         /lua run Turbo/skips_show all       (include applied/dismissed)
         /lua run Turbo/skips_show 20        (show top N, default 30)

  Prints the deduplicated skip list to the MQ chat window.
  Uses the same journal and state files the GUI will read.
]]

local mq = require('mq')

local args = { ... }
local showAll = false
local maxShow = 30

for _, a in ipairs(args) do
    if a:lower() == 'all' then
        showAll = true
    elseif tonumber(a) then
        maxShow = tonumber(a)
    end
end

-- Load the tracker.
local tracker
local ok, err = pcall(function()
    -- Try the standard require paths (Turbo/ or turbo/).
    for _, name in ipairs({ 'Turbo/skip_tracker', 'turbo/skip_tracker' }) do
        local s, m = pcall(require, name)
        if s and m then tracker = m; return end
    end
    -- Fallback: loadfile from same directory.
    local mqPath = mq.TLO.MacroQuest.Path() or ''
    for _, sub in ipairs({ 'Turbo', 'turbo' }) do
        local p = mqPath .. '\\lua\\' .. sub .. '\\skip_tracker.lua'
        local fn = loadfile(p)
        if fn then
            tracker = fn()
            return
        end
    end
    error('skip_tracker.lua not found in lua/Turbo/')
end)

if not ok or not tracker then
    printf('\ar[turboLoot]\ax skips_show: %s', tostring(err))
    return
end

-- We need the INI helpers. Import them from init.lua's public interface if available,
-- or provide simple stubs for read-only display.
local function stubWriteIniKey() return false end
local function stubReadIniKey() return nil end
local function stubGetIniPath()
    local mqPath = mq.TLO.MacroQuest.Path() or ''
    local profile = 'turboloot.ini'
    local mono = mq.TLO.MQ2Mono
    if mono and mono.Query then
        local v = mono.Query('e3,TurboLootIni')()
        if v and v ~= '' and v ~= 'NULL' then profile = v end
    end
    for _, sub in ipairs({ 'Config', 'Macros' }) do
        local p = mqPath .. '\\' .. sub .. '\\' .. profile
        local f = io.open(p, 'r')
        if f then f:close(); return p end
    end
    return nil
end

-- Initialize.
tracker.init(stubWriteIniKey, stubReadIniKey, stubGetIniPath)

if not tracker.is_ready() then
    printf('\ar[turboLoot]\ax skips_show: journal not found (is logSkipListForIni=ON in turboloot.ini?)')
    return
end

-- Display.
local pending = tracker.get_pending()
local total = tracker.pending_count()

printf('\ag[turboLoot]\ax \at--- Skip Review ---\ax')
printf('\ag[turboLoot]\ax \ay%d\ax pending items (showing top %d)', total, math.min(total, maxShow))
printf('')

if total == 0 then
    printf('\ag[turboLoot]\ax No pending skips. All caught up!')
    printf('\ag[turboLoot]\ax (Ensure \atlogSkipListForIni=ON\ax in turboloot.ini [Settings])')
else
    -- Header
    printf('  \at%-35s  %5s  %-18s  %-12s\ax', 'Item', 'Count', 'Reason', 'Zone')
    printf('  \at%-35s  %5s  %-18s  %-12s\ax',
        string.rep('-', 35), '-----', string.rep('-', 18), string.rep('-', 12))

    local shown = 0
    for i, rec in ipairs(pending) do
        if shown >= maxShow then break end
        shown = shown + 1
        local _, reasonDisplay = tracker.primary_reason(rec)
        local hasLink = (tracker.get_link(rec) ~= '')

        local nameCol = rec.name
        if #nameCol > 35 then nameCol = nameCol:sub(1, 32) .. '...' end

        local linkIcon = hasLink and '\ag*\ax' or ' '
        printf('  %s%-35s  %5d  %-18s  %-12s',
            linkIcon, nameCol, rec.count, reasonDisplay, rec.last_zone)
    end

    if total > maxShow then
        printf('\n  ... and %d more. Use \at/lua run Turbo/skips_show %d\ax to see more.',
            total - maxShow, total)
    end
end

-- Show applied if requested.
if showAll then
    local applied = tracker.get_applied()
    if #applied > 0 then
        printf('\n  \at--- Applied (%d) ---\ax', #applied)
        for _, info in ipairs(applied) do
            printf('  \ag[%s]\ax %s (x%d)', info.rule, info.name, info.count)
        end
    end
end

printf('\n\ag[turboLoot]\ax Review via GUI: \at/lua run Turbo\ax -> Review tab')
printf('\ag[turboLoot]\ax Journal: \at/lua run Turbo/skip_log path\ax')
