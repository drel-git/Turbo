--[[
 /$$$$$$$$                  /$$                 /$$$$$$$            /$$ /$$          
|__  $$__/                 | $$                | $$__  $$          | $$| $$          
   | $$ /$$   /$$  /$$$$$$ | $$$$$$$   /$$$$$$ | $$  \ $$  /$$$$$$ | $$| $$  /$$$$$$$
   | $$| $$  | $$ /$$__  $$| $$__  $$ /$$__  $$| $$$$$$$/ /$$__  $$| $$| $$ /$$_____/
   | $$| $$  | $$| $$  \__/| $$  \ $$| $$  \ $$| $$__  $$| $$  \ $$| $$| $$|  $$$$$$ 
   | $$| $$  | $$| $$      | $$  | $$| $$  | $$| $$  \ $$| $$  | $$| $$| $$ \____  $$
   | $$|  $$$$$$/| $$      | $$$$$$$/|  $$$$$$/| $$  | $$|  $$$$$$/| $$| $$ /$$$$$$$/
   |__/ \______/ |__/      |_______/  \______/ |__/  |__/ \______/ |__/|__/|_______/                                                                                                                                                                                                                                                          
                                  ____
                                 /\' .\    _____
                                /: \___\  / .  /\
                                \' / . / /____/..\
                                 \/___/  \'  '\  /
                                          \'__'\/
                        tool for tracking rolls in raids
                            by Drel <Lederhosen>

    Drop into your MQ lua folder, then run:
        /lua run TurboRolls

    Primary commands:
        /troll                  Toggle compact/full mode
        /troll show             Show full window
        /troll togglefull       Show/hide the full window
        /troll mini             Show compact window
        /troll hide             Hide window
        /troll start            Clear, unlock, start current range
        /troll start 1000       Clear, unlock, start 0-1000
        /troll start 1 100      Clear, unlock, start 1-100
        /troll lock             Lock current roll session
        /troll unlock           Unlock current roll session
        /troll clear            Clear rolls, keep session/settings
        /troll reset            Clear rolls, unlock, stop session
        /troll announce         Announce current winner to raid
        /troll top              Announce top 3 to raid
        /troll help             Print help
        /troll quit             End script

    Alias:
        /turborolls             Same as /troll

    Fast workflow:
        1. /troll start 1000
        2. Players /random 1000
        3. Click Announce
        4. Click Next Roll

    Notes:
        - Captures normal EQ /random output.
        - Supports two-line RoF2 random output.
        - Prevents duplicate rolls by default.
        - Rejects wrong range by default.
        - Compact mode is intended for raid leaders who want minimal interaction.
]]

local mq = require('mq')
local ImGui = require('ImGui')

local SCRIPT_NAME = 'TurboRolls'
local VERSION = '2.5.1'

local running = true
local showWindow = true
local compactMode = true
local active = false
local locked = false

local lowRoll = 0
local highRoll = 1000
local itemName = ''

local preventDuplicates = true
local rejectWrongRange = true
local announceBadRolls = true
local announceChannel = 'rs'
local autoLockOnAnnounce = true

local rolls = {}
local order = 0
local statusText = 'Ready.'
local lastWinnerText = 'None'
local pendingRoller = nil
local pendingRollTime = 0
local showSettings = false
local showTools = false
local startRoll
local rememberCurrentWinner
local announceTop
local clearRolls

local buttonColors = {
    -- Muted Turbo-suite style colors: darker base, soft hover, no neon blocks.
    start = {0.22, 0.42, 0.27, 1.00, 0.28, 0.52, 0.34, 1.00, 0.17, 0.32, 0.21, 1.00},
    stop = {0.50, 0.32, 0.14, 1.00, 0.60, 0.40, 0.18, 1.00, 0.38, 0.24, 0.10, 1.00},
    announce = {0.26, 0.39, 0.58, 1.00, 0.32, 0.47, 0.68, 1.00, 0.20, 0.31, 0.48, 1.00},
    next = {0.34, 0.30, 0.45, 1.00, 0.43, 0.38, 0.56, 1.00, 0.26, 0.23, 0.36, 1.00},
    danger = {0.42, 0.18, 0.18, 1.00, 0.54, 0.22, 0.22, 1.00, 0.32, 0.13, 0.13, 1.00},
    neutral = {0.28, 0.34, 0.42, 1.00, 0.36, 0.43, 0.52, 1.00, 0.22, 0.27, 0.34, 1.00},
    menu = {0.23, 0.34, 0.49, 1.00, 0.29, 0.41, 0.58, 1.00, 0.19, 0.29, 0.43, 1.00},
    tools = {0.32, 0.40, 0.50, 1.00, 0.40, 0.50, 0.62, 1.00, 0.24, 0.30, 0.38, 1.00},
    expand = {0.48, 0.36, 0.17, 1.00, 0.60, 0.46, 0.22, 1.00, 0.38, 0.28, 0.13, 1.00},
}

local textColors = {
    active = {0.33, 0.78, 0.76, 1.00},
    stopped = {0.90, 0.70, 0.38, 1.00},
    idle = {0.65, 0.69, 0.76, 1.00},
    winner = {0.40, 1.00, 0.52, 1.00},
    roll = {0.95, 0.72, 0.28, 1.00},
    lastWinner = {0.72, 0.52, 0.86, 1.00},
    muted = {0.70, 0.74, 0.80, 1.00},
}

local function trim(s)
    return (s or ''):gsub('^%s+', ''):gsub('%s+$', '')
end

local function splitArgs(line)
    local args = {}
    for word in tostring(line or ''):gmatch('%S+') do
        table.insert(args, word)
    end
    return args
end

local function chat(msg)
    mq.cmdf('/echo \\at[%s]\\ax %s', SCRIPT_NAME, msg)
end

local function raid(msg)
    mq.cmdf('/%s %s', announceChannel, msg)
end

local function styledButton(label, colorKey, padX, padY, tooltip, buttonW, buttonH)
    local pushedColors = 0
    local c = buttonColors[colorKey or 'neutral']

    ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 5)
    ImGui.PushStyleVar(ImGuiStyleVar.FramePadding, padX or 8, padY or 4)

    if c then
        ImGui.PushStyleColor(ImGuiCol.Button, c[1], c[2], c[3], c[4])
        ImGui.PushStyleColor(ImGuiCol.ButtonHovered, c[5], c[6], c[7], c[8])
        ImGui.PushStyleColor(ImGuiCol.ButtonActive, c[9], c[10], c[11], c[12])
        pushedColors = 3
    end

    local clicked
    if buttonW and buttonH then
        clicked = ImGui.Button(label, buttonW, buttonH)
    elseif buttonW then
        clicked = ImGui.Button(label, buttonW, 0)
    else
        clicked = ImGui.Button(label)
    end

    if tooltip and tooltip ~= '' and ImGui.IsItemHovered() then
        ImGui.SetTooltip(tooltip)
    end

    if pushedColors > 0 then ImGui.PopStyleColor(pushedColors) end
    ImGui.PopStyleVar(2)

    return clicked
end

local function coloredText(text, colorKey)
    local c = textColors[colorKey or 'muted']
    if c then
        ImGui.PushStyleColor(ImGuiCol.Text, c[1], c[2], c[3], c[4])
        ImGui.Text(text)
        ImGui.PopStyleColor()
    else
        ImGui.Text(text)
    end
end

local function sameLineColoredText(text, colorKey)
    ImGui.SameLine()
    coloredText(text, colorKey)
end

local function startStopRoll()
    if active and not locked then
        locked = true
        statusText = 'Roll stopped.'
        return
    end

    startRoll(lowRoll, highRoll)
end

clearRolls = function()
    rolls = {}
    order = 0
    statusText = 'Rolls cleared.'
end

local function getSortedRolls()
    local sorted = {}
    for _, data in pairs(rolls) do
        table.insert(sorted, data)
    end

    table.sort(sorted, function(a, b)
        if a.roll == b.roll then
            return a.order < b.order
        end
        return a.roll > b.roll
    end)

    return sorted
end

local function getWinner()
    local sorted = getSortedRolls()
    return sorted[1], sorted
end

local function formatRange()
    return string.format('%d-%d', tonumber(lowRoll) or 0, tonumber(highRoll) or 0)
end

local function formatItemSuffix()
    local trimmed = trim(itemName)
    if trimmed ~= '' then
        return string.format(' for %s', trimmed)
    end
    return ''
end

local function shortText(text, maxLen)
    text = tostring(text or '')
    maxLen = maxLen or 14

    if #text <= maxLen then
        return text
    end

    return text:sub(1, math.max(1, maxLen - 1)) .. '…'
end

local function winnerDisplay(winner, maxNameLen)
    if not winner then return 'None' end
    return string.format('%s - %d', shortText(winner.name, maxNameLen or 14), winner.roll)
end

local function coloredWinnerLine(label, name, roll, nameColor)
    ImGui.Text(label)
    ImGui.SameLine()
    coloredText(shortText(name, 18), nameColor or 'winner')
    ImGui.SameLine()
    coloredText('- ' .. tostring(roll), 'roll')
end

local function drawLastWinnerLine()
    if lastWinnerText == 'None' then
        ImGui.Text('Last:')
        sameLineColoredText('None', 'muted')
        return
    end

    local name, roll = lastWinnerText:match('^(.-)%s%-%s(%d+)$')
    if name and roll then
        coloredWinnerLine('Last:', name, roll, 'lastWinner')
    else
        ImGui.Text('Last:')
        sameLineColoredText(shortText(lastWinnerText, 26), 'lastWinner')
    end
end

local function textWidth(text)
    text = tostring(text or '')
    if ImGui.CalcTextSize then
        local w = ImGui.CalcTextSize(text)
        if type(w) == 'table' then return tonumber(w.x or w[1]) or 0 end
        return tonumber(w) or 0
    end
    return #text * 7
end

local function contentRegionWidth()
    if ImGui.GetWindowContentRegionMin and ImGui.GetWindowContentRegionMax then
        local minX, maxX = 0, 0
        local cmin = { ImGui.GetWindowContentRegionMin() }
        local cmax = { ImGui.GetWindowContentRegionMax() }
        if type(cmin[1]) == 'table' then minX = tonumber(cmin[1].x or cmin[1][1]) or 0 else minX = tonumber(cmin[1]) or 0 end
        if type(cmax[1]) == 'table' then maxX = tonumber(cmax[1].x or cmax[1][1]) or minX else maxX = tonumber(cmax[1]) or minX end
        if maxX > minX then return maxX - minX end
    end
    local avail = ImGui.GetContentRegionAvail and ImGui.GetContentRegionAvail() or 0
    if type(avail) == 'table' then return tonumber(avail.x or avail[1]) or 0 end
    return tonumber(avail) or 0
end

local function drawButtonRow(buttons, gap)
    gap = gap or 4
    local avail = contentRegionWidth()
    local fixedTotal, flexCount = 0, 0
    for _, btn in ipairs(buttons) do
        if btn.width then
            fixedTotal = fixedTotal + btn.width
        else
            flexCount = flexCount + 1
        end
    end
    local spacingTotal = gap * math.max(0, #buttons - 1)
    local flexW = flexCount > 0 and math.max(44, math.floor((avail - fixedTotal - spacingTotal) / flexCount)) or 44

    for i, btn in ipairs(buttons) do
        if i > 1 and ImGui.SameLine then ImGui.SameLine(0, gap) end
        local w = btn.width or flexW
        if styledButton(btn.label, btn.color, btn.padX or 9, btn.padY or 4, btn.tip, w, btn.height or 24) and btn.onClick then
            btn.onClick()
        end
    end
end

local function dragCurrentWindow()
    if not (ImGui.IsMouseDragging and ImGui.GetMouseDragDelta and ImGui.SetWindowPos) then return end
    if not ImGui.IsMouseDragging(0, 0.0) then return end
    local delta = ImGui.GetMouseDragDelta(0)
    local dx = type(delta) == 'table' and tonumber(delta.x or delta[1]) or tonumber(delta) or 0
    local dy = type(delta) == 'table' and tonumber(delta.y or delta[2]) or 0
    if dx == 0 and dy == 0 then return end
    local px, py = ImGui.GetWindowPos()
    ImGui.SetWindowPos((tonumber(px) or 0) + dx, (tonumber(py) or 0) + dy)
    if ImGui.ResetMouseDragDelta then ImGui.ResetMouseDragDelta(0) end
end

local chromeDragState = {
    excludes = {},
    band = nil,
    grabbing = false,
    lastX = nil,
    lastY = nil,
}

local function vec2XY(v, y)
    if type(v) == 'table' then
        return tonumber(v.x or v.X or v[1]) or 0, tonumber(v.y or v.Y or v[2]) or 0
    end
    return tonumber(v) or 0, tonumber(y) or 0
end

local function chromeDragCanHandle()
    return ImGui.GetMousePos and ImGui.GetWindowPos and ImGui.GetWindowSize
        and ImGui.GetCursorScreenPos and ImGui.GetItemRectMin and ImGui.GetItemRectMax
        and ImGui.SetWindowPos and ImGui.IsMouseClicked and ImGui.IsMouseDown
end

local function chromeMousePos()
    if not ImGui.GetMousePos then return nil, nil end
    local x, y = ImGui.GetMousePos()
    return vec2XY(x, y)
end

local function chromeWindowRect()
    if not (ImGui.GetWindowPos and ImGui.GetWindowSize) then return nil end
    local x, y = vec2XY(ImGui.GetWindowPos())
    local w, h = vec2XY(ImGui.GetWindowSize())
    return { x1 = x, y1 = y, x2 = x + w, y2 = y + h }
end

local function chromeCursorScreenY()
    if not ImGui.GetCursorScreenPos then return nil end
    local _, y = vec2XY(ImGui.GetCursorScreenPos())
    return y
end

local function chromeItemRect()
    if not (ImGui.GetItemRectMin and ImGui.GetItemRectMax) then return nil end
    local minX, minY = ImGui.GetItemRectMin()
    local maxX, maxY = ImGui.GetItemRectMax()
    local x1, y1 = vec2XY(minX, minY)
    local x2, y2 = vec2XY(maxX, maxY)
    return { x1 = x1, y1 = y1, x2 = x2, y2 = y2 }
end

local function pointInRect(x, y, r)
    return r and x >= r.x1 and x <= r.x2 and y >= r.y1 and y <= r.y2
end

local function chromeDragReset()
    chromeDragState.excludes = {}
    chromeDragState.band = nil
end

local function chromeDragAddLastItem()
    local r = chromeItemRect()
    if r then chromeDragState.excludes[#chromeDragState.excludes + 1] = r end
end

local function chromeDragSetBandToCursor()
    local win = chromeWindowRect()
    local cy = chromeCursorScreenY()
    if not win or not cy then return end
    chromeDragState.band = {
        x1 = win.x1,
        y1 = win.y1,
        x2 = win.x2,
        y2 = math.max(win.y1 + 48, cy),
    }
end

local function chromeDragBlocked(x, y)
    for _, r in ipairs(chromeDragState.excludes or {}) do
        if pointInRect(x, y, r) then return true end
    end
    return false
end

local function chromeDragMove(x, y)
    if not (ImGui.SetWindowPos and x and y) then return end
    if chromeDragState.lastX and chromeDragState.lastY then
        local dx = x - chromeDragState.lastX
        local dy = y - chromeDragState.lastY
        if dx ~= 0 or dy ~= 0 then
            local wx, wy = vec2XY(ImGui.GetWindowPos())
            ImGui.SetWindowPos(wx + dx, wy + dy)
        end
    end
    chromeDragState.lastX, chromeDragState.lastY = x, y
end

local function chromeDragApplyActive()
    if not chromeDragState.grabbing then return end
    if not (ImGui.IsMouseDown and ImGui.IsMouseDown(0)) then
        chromeDragState.grabbing = false
        chromeDragState.lastX, chromeDragState.lastY = nil, nil
        return
    end
    local mx, my = chromeMousePos()
    if not mx or not my then return end
    if ImGui.ClearActiveID then ImGui.ClearActiveID() end
    chromeDragMove(mx, my)
end

local function chromeDragActiveItem()
    if not (ImGui.IsItemActive and ImGui.IsItemActive()) then return false end
    if not (ImGui.IsMouseDown and ImGui.IsMouseDown(0)) then return false end
    local mx, my = chromeMousePos()
    if not mx or not my then return false end
    if not chromeDragState.grabbing then
        chromeDragState.grabbing = true
        chromeDragState.lastX, chromeDragState.lastY = mx, my
        if ImGui.ResetMouseDragDelta then ImGui.ResetMouseDragDelta(0) end
    end
    if ImGui.ClearActiveID then ImGui.ClearActiveID() end
    chromeDragMove(mx, my)
    return true
end

local function chromeDragHandle(tooltip)
    if not chromeDragCanHandle() then return end
    local mx, my = chromeMousePos()
    if not mx or not my or not chromeDragState.band then return end
    local hovered = not ImGui.IsWindowHovered or ImGui.IsWindowHovered()
    local inBand = pointInRect(mx, my, chromeDragState.band)
    local blocked = chromeDragBlocked(mx, my)
    local down = ImGui.IsMouseDown(0)

    if ImGui.IsMouseClicked(0) then
        if hovered and inBand and not blocked then
            chromeDragState.grabbing = true
            chromeDragState.lastX, chromeDragState.lastY = mx, my
            if ImGui.ResetMouseDragDelta then ImGui.ResetMouseDragDelta(0) end
        elseif not chromeDragState.grabbing then
            chromeDragState.lastX, chromeDragState.lastY = nil, nil
        end
    end

    if not down then
        chromeDragState.grabbing = false
        chromeDragState.lastX, chromeDragState.lastY = nil, nil
        return
    end

    if chromeDragState.grabbing then
        if ImGui.ClearActiveID then ImGui.ClearActiveID() end
    elseif hovered and inBand and not blocked and ImGui.SetTooltip then
        ImGui.SetTooltip(tooltip or 'Drag empty header space to move this window.')
    end
end

local function drawTitleChrome(isFull)
    chromeDragReset()
    local barW = contentRegionWidth()
    local titleA = 'Turbo'
    local titleB = isFull and string.format('Rolls v%s', VERSION) or 'Rolls'
    local titleW = textWidth(titleA) + textWidth(titleB)
    local btnW, btnH = 30, 22
    local x0, y0 = 0, 0
    if ImGui.GetCursorPos then
        x0, y0 = ImGui.GetCursorPos()
        x0, y0 = tonumber(x0) or 0, tonumber(y0) or 0
    end

    if styledButton('...##tr_menu_btn', 'menu', 7, 3, 'TurboRolls menu.', btnW, btnH) then
        if ImGui.OpenPopup then ImGui.OpenPopup('##tr_title_menu') end
    end
    chromeDragAddLastItem()
    if ImGui.BeginPopup and ImGui.BeginPopup('##tr_title_menu') then
        if styledButton('Top 3##tr_menu_top', 'announce', 7, 3, 'Announce the top three valid rolls.', 130, 22) then
            announceTop(3)
            if ImGui.CloseCurrentPopup then ImGui.CloseCurrentPopup() end
        end
        if styledButton('Clear Rolls##tr_menu_clear', 'danger', 7, 3, 'Clear all current rolls and stop the session.', 130, 22) then
            rememberCurrentWinner(); clearRolls(); active = false; locked = false
            if ImGui.CloseCurrentPopup then ImGui.CloseCurrentPopup() end
        end
        if styledButton('Settings##tr_menu_settings', 'tools', 7, 3, 'Open settings in full view.', 130, 22) then
            compactMode = false
            showTools = true
            showSettings = true
            if ImGui.CloseCurrentPopup then ImGui.CloseCurrentPopup() end
        end
        ImGui.Separator()
        if styledButton('Unload TurboRolls##tr_menu_unload', 'danger', 7, 3, 'Unload TurboRolls.', 130, 22) then
            running = false
            showWindow = false
            if ImGui.CloseCurrentPopup then ImGui.CloseCurrentPopup() end
        end
        ImGui.EndPopup()
    end

    local hasRightButton = true
    local dragX = x0 + btnW + 4
    local dragW = math.max(20, barW - (hasRightButton and ((btnW * 2) + 8) or (btnW + 4)))
    local dragMinX, dragMinY, dragMaxX = nil, nil, nil
    if ImGui.SetCursorPos and ImGui.InvisibleButton then
        ImGui.SetCursorPos(dragX, y0)
        ImGui.InvisibleButton('##tr_header_drag', dragW, 38)
        if ImGui.GetItemRectMin and ImGui.GetItemRectMax then
            local rmin, rminY = ImGui.GetItemRectMin()
            local rmax = ImGui.GetItemRectMax()
            dragMinX = type(rmin) == 'table' and tonumber(rmin.x or rmin[1]) or tonumber(rmin) or nil
            dragMinY = type(rmin) == 'table' and tonumber(rmin.y or rmin[2]) or tonumber(rminY) or nil
            dragMaxX = type(rmax) == 'table' and tonumber(rmax.x or rmax[1]) or tonumber(rmax) or nil
        end
        chromeDragActiveItem()
        if (not chromeDragCanHandle()) and ImGui.IsItemActive and ImGui.IsItemActive() then dragCurrentWindow() end
        if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then ImGui.SetTooltip('Drag to move TurboRolls.') end
    end

    if ImGui.GetWindowDrawList and dragMinX and dragMinY and dragMaxX and IM_COL32 then
        local drawX = dragMinX + math.max(0, ((dragMaxX - dragMinX) - titleW) * 0.5)
        local drawY = dragMinY + 4
        ImGui.GetWindowDrawList():AddText(ImVec2(drawX, drawY), IM_COL32(255, 199, 82, 255), titleA)
        ImGui.GetWindowDrawList():AddText(ImVec2(drawX + textWidth(titleA), drawY), IM_COL32(235, 240, 250, 255), titleB)
    elseif ImGui.SetCursorPos then
        ImGui.SetCursorPos(x0 + math.max(btnW + 8, (barW - titleW) * 0.5), y0 + 4)
        ImGui.TextColored(1.00, 0.78, 0.32, 1.00, titleA)
        ImGui.SameLine(0, 0)
        ImGui.TextColored(0.92, 0.94, 0.98, 1.00, titleB)
    end

    if hasRightButton then
        if ImGui.SetCursorPos then ImGui.SetCursorPos(x0 + math.max(0, barW - btnW), y0) end
        local toggleLabel = isFull and '-##tr_mode_toggle' or '+##tr_mode_toggle'
        local toggleTip = isFull and 'Collapse to mini view.' or 'Expand to the full roll table and tools view.'
        if styledButton(toggleLabel, 'expand', 7, 3, toggleTip, btnW, btnH) then
            compactMode = isFull
        end
        chromeDragAddLastItem()
    end

    if ImGui.SetCursorPos then ImGui.SetCursorPos(x0, y0 + 42) end
    chromeDragSetBandToCursor()
    chromeDragHandle('Drag empty TurboRolls header space to move the window.')
    ImGui.Separator()
end

rememberCurrentWinner = function()
    local winner = getWinner()
    if winner then
        lastWinnerText = string.format('%s - %d', winner.name, winner.roll)
    end
end

function startRoll(newLow, newHigh)
    if newLow ~= nil and newHigh ~= nil then
        lowRoll = tonumber(newLow) or lowRoll
        highRoll = tonumber(newHigh) or highRoll
    elseif newLow ~= nil then
        lowRoll = 0
        highRoll = tonumber(newLow) or highRoll
    end

    if lowRoll > highRoll then
        lowRoll, highRoll = highRoll, lowRoll
    end

    clearRolls()
    active = true
    locked = false
    statusText = string.format('Roll started: %s', formatRange())
    raid(string.format('Roll now: /random %d %d%s', lowRoll, highRoll, formatItemSuffix()))
end

local function nextRoll()
    rememberCurrentWinner()
    startRoll(lowRoll, highRoll)
end

local function lockRolls(silent)
    locked = true
    statusText = 'Rolls locked.'
    if not silent then raid('Rolls are now locked.') end
end

local function unlockRolls()
    locked = false
    statusText = 'Rolls unlocked.'
    chat('Rolls unlocked.')
end

local function announceWinner()
    local winner = getWinner()
    if not winner then
        chat('No valid rolls to announce.')
        return
    end

    if autoLockOnAnnounce then
        locked = true
    end

    lastWinnerText = string.format('%s - %d', winner.name, winner.roll)
    raid(string.format('Winner%s: %s with %d', formatItemSuffix(), winner.name, winner.roll))
    statusText = string.format('Announced winner: %s %d', winner.name, winner.roll)
end

announceTop = function(count)
    count = count or 3
    local winner, sorted = getWinner()
    if not winner then
        chat('No valid rolls to announce.')
        return
    end

    local parts = {}
    for i = 1, math.min(count, #sorted) do
        table.insert(parts, string.format('#%d %s=%d', i, sorted[i].name, sorted[i].roll))
    end

    if autoLockOnAnnounce then
        locked = true
    end

    lastWinnerText = string.format('%s - %d', winner.name, winner.roll)
    raid(string.format('Top rolls%s: %s', formatItemSuffix(), table.concat(parts, ', ')))
    statusText = 'Announced top rolls.'
end

local function awardAndNext()
    local winner = getWinner()
    if not winner then
        chat('No valid rolls to award.')
        return
    end

    lastWinnerText = string.format('%s - %d', winner.name, winner.roll)
    raid(string.format('Winner%s: %s with %d', formatItemSuffix(), winner.name, winner.roll))
    startRoll(lowRoll, highRoll)
end

local function awardAndStop()
    local winner = getWinner()
    if not winner then
        chat('No valid rolls to award.')
        return
    end

    lastWinnerText = string.format('%s - %d', winner.name, winner.roll)
    raid(string.format('Winner%s: %s with %d', formatItemSuffix(), winner.name, winner.roll))
    clearRolls()
    active = false
    locked = false
    statusText = string.format('Awarded and stopped: %s %d', winner.name, winner.roll)
end

local function printHelp()
    chat('Commands:')
    chat('/troll show | togglefull | mini | hide | start [max] | start [min] [max] | awardnext | awardstop | lock | unlock | clear | reset | announce | top | quit')
    chat('Examples: /troll start 1000  OR  /troll start 1 100')
end

local function addRoll(name, minText, maxText, rollText, rawLine)
    name = trim(name)
    local minValue = tonumber(minText)
    local maxValue = tonumber(maxText)
    local rollValue = tonumber(rollText)

    if name == '' or not minValue or not maxValue or not rollValue then
        return
    end

    if not active then
        return
    end

    if locked then
        statusText = string.format('Ignored late roll from %s: %d', name, rollValue)
        return
    end

    if rejectWrongRange and (minValue ~= lowRoll or maxValue ~= highRoll) then
        statusText = string.format('Rejected %s: wrong range %d-%d', name, minValue, maxValue)
        if announceBadRolls then
            raid(string.format('%s rolled wrong range %d-%d. Current range is %s.', name, minValue, maxValue, formatRange()))
        else
            chat(statusText)
        end
        return
    end

    if preventDuplicates and rolls[name] then
        statusText = string.format('Ignored duplicate roll from %s: %d', name, rollValue)
        chat(statusText)
        return
    end

    order = order + 1
    rolls[name] = {
        name = name,
        roll = rollValue,
        min = minValue,
        max = maxValue,
        order = order,
        time = os.date('%H:%M'),
        raw = rawLine or '',
    }

    statusText = string.format('Added %s: %d', name, rollValue)
end

local function removeRoll(name)
    if rolls[name] then
        rolls[name] = nil
        statusText = string.format('Removed %s.', name)
    end
end

local function resetRolls()
    rememberCurrentWinner()
    clearRolls()
    active = false
    locked = false
    statusText = 'Reset complete.'
end

local function handleCommand(line)
    local args = splitArgs(line)
    local cmd = string.lower(args[1] or '')

    if cmd == '' then
        compactMode = not compactMode
        showWindow = true
        return
    end

    if cmd == 'show' or cmd == 'full' then
        showWindow = true
        compactMode = false
    elseif cmd == 'togglefull' then
        if showWindow and not compactMode then
            showWindow = false
        else
            showWindow = true
            compactMode = false
        end
    elseif cmd == 'mini' or cmd == 'min' or cmd == 'compact' then
        showWindow = true
        compactMode = true
    elseif cmd == 'hide' then
        showWindow = false
    elseif cmd == 'start' then
        if args[2] and args[3] then
            startRoll(tonumber(args[2]), tonumber(args[3]))
        elseif args[2] then
            startRoll(tonumber(args[2]))
        else
            startStopRoll()
        end
        showWindow = true
        compactMode = true
    elseif cmd == 'next' then
        nextRoll()
        showWindow = true
        compactMode = true
    elseif cmd == 'lock' or cmd == 'stop' then
        locked = true
        statusText = 'Roll stopped.'
    elseif cmd == 'unlock' then
        unlockRolls()
    elseif cmd == 'clear' then
        rememberCurrentWinner()
        clearRolls()
    elseif cmd == 'reset' then
        resetRolls()
    elseif cmd == 'announce' or cmd == 'winner' or cmd == 'win' then
        announceWinner()
    elseif cmd == 'awardnext' or cmd == 'award' or cmd == 'award+next' then
        awardAndNext()
        showWindow = true
        compactMode = true
    elseif cmd == 'awardstop' or cmd == 'award+stop' or cmd == 'awardandstop' then
        awardAndStop()
        showWindow = true
        compactMode = true
    elseif cmd == 'top' then
        announceTop(3)
    elseif cmd == 'help' then
        printHelp()
    elseif cmd == 'quit' or cmd == 'exit' then
        running = false
    else
        chat('Unknown command. Use /troll help')
    end
end

-- RoF2/EQ clients often print /random as TWO chat lines:
-- **A Magic Die is rolled by Bob.
-- **It could have been any number from 0 to 1000, but this time it turned up a 987.
-- Some clients/log filters may print it as one line, so we support both.
local function onRandomNameLine(line, name)
    pendingRoller = trim(name)
    pendingRollTime = os.clock()
end

local function onRandomResultLine(line, minText, maxText, rollText)
    if not pendingRoller or pendingRoller == '' then
        return
    end

    if os.clock() - pendingRollTime > 5 then
        pendingRoller = nil
        pendingRollTime = 0
        return
    end

    addRoll(pendingRoller, minText, maxText, rollText, line)
    pendingRoller = nil
    pendingRollTime = 0
end

local function onRandomOneLine(line, name, minText, maxText, rollText)
    addRoll(name, minText, maxText, rollText, line)
end

mq.event('turborolls_random_name_line', '#*#A Magic Die is rolled by #1#.', onRandomNameLine)
mq.event('turborolls_random_result_line', '#*#It could have been any number from #1# to #2#, but this time it turned up a #3#.', onRandomResultLine)
mq.event('turborolls_random_one_line', '#*#A Magic Die is rolled by #1#. It could have been any number from #2# to #3#, but this time it turned up a #4#.', onRandomOneLine)

mq.bind('/troll', handleCommand)
mq.bind('/turborolls', handleCommand)

local function drawRollTable(sorted, maxRows)
    maxRows = maxRows or #sorted

    if ImGui.BeginTable('##turborolls_table', 5, bit32.bor(ImGuiTableFlags.Borders, ImGuiTableFlags.RowBg, ImGuiTableFlags.ScrollY, ImGuiTableFlags.Resizable, ImGuiTableFlags.SizingStretchProp), 0, 220) then
        ImGui.TableSetupColumn('#', ImGuiTableColumnFlags.WidthFixed, 28)
        ImGui.TableSetupColumn('Name', ImGuiTableColumnFlags.WidthStretch, 1.25)
        ImGui.TableSetupColumn('Roll', ImGuiTableColumnFlags.WidthFixed, 52)
        ImGui.TableSetupColumn('Time', ImGuiTableColumnFlags.WidthFixed, 52)
        ImGui.TableSetupColumn('X', ImGuiTableColumnFlags.WidthFixed, 42)
        ImGui.TableHeadersRow()

        for i = 1, math.min(maxRows, #sorted) do
            local data = sorted[i]
            ImGui.TableNextRow()

            ImGui.TableSetColumnIndex(0)
            ImGui.Text(tostring(i))

            ImGui.TableSetColumnIndex(1)
            ImGui.Text(data.name)

            ImGui.TableSetColumnIndex(2)
            ImGui.Text(tostring(data.roll))

            ImGui.TableSetColumnIndex(3)
            ImGui.Text(data.time or '')

            ImGui.TableSetColumnIndex(4)
            if styledButton('X##remove_' .. data.name, 'danger', nil, nil, 'Remove this roll from the list.') then
                removeRoll(data.name)
            end
        end

        ImGui.EndTable()
    end
end

local function drawCompactWindow(sorted, winner)
    local compactW = 250
    local compactH = 154
    local compactFlags = bit32.bor(ImGuiWindowFlags.NoTitleBar or 0, ImGuiWindowFlags.NoResize or 0)
    if ImGuiWindowFlags.NoScrollbar then
        compactFlags = bit32.bor(compactFlags, ImGuiWindowFlags.NoScrollbar)
    end
    if ImGui.SetNextWindowSizeConstraints then ImGui.SetNextWindowSizeConstraints(compactW, compactH, compactW, compactH) end
    ImGui.SetNextWindowSize(compactW, compactH, ImGuiCond.Always)

    ImGui.PushStyleVar(ImGuiStyleVar.WindowRounding, 6)
    ImGui.PushStyleVar(ImGuiStyleVar.WindowBorderSize, 2)
    ImGui.PushStyleColor(ImGuiCol.WindowBg, 0.05, 0.06, 0.09, 0.96)
    ImGui.PushStyleColor(ImGuiCol.Border, 0.72, 0.56, 0.24, 0.95)
    ImGui.PushStyleColor(ImGuiCol.TitleBg, 0.08, 0.11, 0.16, 1.00)
    ImGui.PushStyleColor(ImGuiCol.TitleBgActive, 0.10, 0.14, 0.20, 1.00)
    ImGui.PushStyleColor(ImGuiCol.TitleBgCollapsed, 0.08, 0.11, 0.16, 1.00)

    local open = showWindow
    open = ImGui.Begin(SCRIPT_NAME, open, compactFlags)
    showWindow = open

    if not open then
        running = false
        ImGui.End()
        ImGui.PopStyleColor(5)
        ImGui.PopStyleVar(2)
        return
    end

    chromeDragApplyActive()
    drawTitleChrome(false)

    if winner then
        coloredWinnerLine('Winner:', winner.name, winner.roll, 'winner')
    else
        ImGui.Text('Winner:')
        sameLineColoredText('None', 'muted')
    end
    ImGui.Text('Rolls:')
    ImGui.SameLine()
    coloredText(tostring(#sorted), 'muted')
    drawLastWinnerLine()

    drawButtonRow({
        {
            label = (active and not locked) and 'Stop' or 'Start',
            color = (active and not locked) and 'stop' or 'start',
            tip = (active and not locked) and 'Stop accepting rolls without clearing.' or 'Start a fresh roll using the current range.',
            onClick = startStopRoll,
        },
        { label = 'Award', color = 'announce', tip = 'Announce the current winner and stop without starting another roll.', onClick = awardAndStop },
        { label = 'New', color = 'start', tip = 'Start a fresh roll using the current range.', onClick = nextRoll },
    })

    ImGui.End()
    ImGui.PopStyleColor(5)
    ImGui.PopStyleVar(2)
end

local function drawFullWindow(sorted, winner)
    local fullW = 360
    local targetHeight = 386
    if showTools and showSettings then
        targetHeight = 548
    elseif showTools then
        targetHeight = 432
    end
    if ImGui.SetNextWindowSizeConstraints then ImGui.SetNextWindowSizeConstraints(fullW, targetHeight, fullW, targetHeight) end
    ImGui.SetNextWindowSize(fullW, targetHeight, ImGuiCond.Always)

    ImGui.PushStyleVar(ImGuiStyleVar.WindowRounding, 6)
    ImGui.PushStyleVar(ImGuiStyleVar.WindowBorderSize, 2)
    ImGui.PushStyleColor(ImGuiCol.WindowBg, 0.05, 0.06, 0.09, 0.96)
    ImGui.PushStyleColor(ImGuiCol.Border, 0.72, 0.56, 0.24, 0.95)
    ImGui.PushStyleColor(ImGuiCol.TitleBg, 0.08, 0.11, 0.16, 1.00)
    ImGui.PushStyleColor(ImGuiCol.TitleBgActive, 0.10, 0.14, 0.20, 1.00)
    ImGui.PushStyleColor(ImGuiCol.TitleBgCollapsed, 0.08, 0.11, 0.16, 1.00)

    local open = showWindow
    open = ImGui.Begin(string.format('%s v%s', SCRIPT_NAME, VERSION), open, ImGuiWindowFlags.NoTitleBar or 0)
    showWindow = open

    if not open then
        running = false
        ImGui.End()
        ImGui.PopStyleColor(5)
        ImGui.PopStyleVar(2)
        return
    end

    chromeDragApplyActive()
    drawTitleChrome(true)

    if winner then
        coloredWinnerLine('Winner:', winner.name, winner.roll, 'winner')
    else
        ImGui.Text('Winner:')
        sameLineColoredText('None', 'muted')
    end

    drawLastWinnerLine()
    coloredText(string.format('Range: %s | Rolls: %d', formatRange(), #sorted), 'muted')
    ImGui.Separator()

    drawButtonRow({
        {
            label = (active and not locked) and 'Stop' or 'Start',
            color = (active and not locked) and 'stop' or 'start',
            tip = (active and not locked) and 'Stop accepting rolls without clearing.' or 'Start a fresh roll using the current range.',
            onClick = startStopRoll,
        },
        { label = 'Award', color = 'announce', tip = 'Announce the current winner and stop without starting another roll.', onClick = awardAndStop },
        { label = 'New', color = 'start', tip = 'Start a fresh roll using the current range.', onClick = nextRoll },
        {
            label = (showTools and '^' or 'v') .. '##tools_toggle',
            color = 'tools',
            tip = 'Show or hide Top 3, Clear Rolls, and Settings.',
            width = 28,
            padX = 4,
            onClick = function() showTools = not showTools end,
        },
    })

    if showTools then
        ImGui.Separator()
        drawButtonRow({
            { label = 'Top 3', color = 'announce', padX = nil, tip = 'Announce the top three valid rolls.', onClick = function() announceTop(3) end },
            { label = 'Clear Rolls', color = 'danger', padX = nil, tip = 'Clear all current rolls and stop the session.', onClick = function() rememberCurrentWinner(); clearRolls(); active = false; locked = false end },
            { label = showSettings and 'Hide' or 'Settings', color = 'neutral', padX = nil, tip = 'Show or hide range, item note, and roll rule options.', onClick = function() showSettings = not showSettings end },
        })
    end

    if showTools and showSettings then
        ImGui.Separator()
        coloredText('Roll Setup', 'muted')

        local setupAvail = contentRegionWidth()
        local minW = math.min(70, math.max(52, math.floor((setupAvail - 8) * 0.32)))
        local maxW = math.min(100, math.max(60, math.floor((setupAvail - 8) * 0.42)))

        ImGui.SetNextItemWidth(minW)
        local newLow, changedLow = ImGui.InputInt('Min', lowRoll)
        if changedLow then lowRoll = tonumber(newLow) or lowRoll end

        ImGui.SameLine(0, 8)
        ImGui.SetNextItemWidth(maxW)
        local newHigh, changedHigh = ImGui.InputInt('Max', highRoll)
        if changedHigh then highRoll = tonumber(newHigh) or highRoll end

        ImGui.SetNextItemWidth(math.max(120, setupAvail))
        local newItem, changedItem = ImGui.InputText('Item / Note', itemName, 128)
        if changedItem then itemName = newItem or '' end

        coloredText('Options', 'muted')

        local dupValue, dupChanged = ImGui.Checkbox('Prevent duplicate rolls', preventDuplicates)
        if dupChanged then preventDuplicates = dupValue end

        local rangeValue, rangeChanged = ImGui.Checkbox('Reject wrong range', rejectWrongRange)
        if rangeChanged then rejectWrongRange = rangeValue end

        local badValue, badChanged = ImGui.Checkbox('Announce bad rolls to raid', announceBadRolls)
        if badChanged then announceBadRolls = badValue end

        local autoLockValue, autoLockChanged = ImGui.Checkbox('Auto-lock when announcing', autoLockOnAnnounce)
        if autoLockChanged then autoLockOnAnnounce = autoLockValue end
    end

    ImGui.Separator()
    drawRollTable(sorted)

    ImGui.End()
    ImGui.PopStyleColor(5)
    ImGui.PopStyleVar(2)
end

local function drawWindow()
    if not showWindow then return end

    local winner, sorted = getWinner()
    sorted = sorted or {}

    if compactMode then
        drawCompactWindow(sorted, winner)
    else
        drawFullWindow(sorted, winner)
    end
end

mq.imgui.init(SCRIPT_NAME, drawWindow)

chat('\\agLoaded.\\ax Use \\ay/troll start 1000\\ax, \\ay/troll mini\\ax, or \\ay/troll help\\ax.')

while running do
    mq.doevents()
    mq.delay(50)
end

mq.unbind('/troll')
mq.unbind('/turborolls')
chat('Unloaded.')
