--[[
  Turbo UI Components
  -------------------
  @version lua/Turbo/ui/components.lua 1.3.0

  ImGui primitive wrappers (buttons, toggles, separators, section headers,
  tooltips). All styling goes through Theme.col so colors never get
  hardcoded in render code. Required by every view in lua/Turbo/ui/views/.
]]

local ImGui = require('ImGui')
local Theme = require('Turbo.theme')

local M = {}

M.size = {
    smallH = 22,
    normalH = 24,
    wideH = 26,
    fullH = 28,
    smallMinW = 58,
    normalMinW = 82,
    wideMinW = 128,
    gap = Theme.space.xs,
    sectionTop = Theme.space.sm,
    sectionBottom = Theme.space.xs,
}

M.intentVariant = {
    primary = 'primaryButton',
    nav = 'primaryButton',
    positive = 'successButton',
    execute = 'successButton',
    confirm = 'successButton',
    danger = 'dangerButton',
    stop = 'dangerButton',
    value = 'valueButton',
    currency = 'valueButton',
    storage = 'storageButton',
    bank = 'storageButton',
    info = 'infoButton',
    announce = 'infoButton',
    utility = 'utilityButton',
    neutral = 'secondaryButton',
    disabled = 'secondaryButton',
}

local function rgba(c, alphaOverride)
    if not c then return IM_COL32(255, 255, 255, 255) end
    return IM_COL32(c[1], c[2], c[3], alphaOverride or c[4] or 255)
end

function M.tooltip(text, wrapCols)
    if not ImGui.IsItemHovered() then return end
    ImGui.BeginTooltip()
    ImGui.PushTextWrapPos(ImGui.GetFontSize() * (wrapCols or 30.0))
    ImGui.Text(text)
    ImGui.PopTextWrapPos()
    ImGui.EndTooltip()
end

function M.pushButtonPalette(palette)
    ImGui.PushStyleColor(ImGuiCol.Button, rgba(palette.base))
    ImGui.PushStyleColor(ImGuiCol.ButtonHovered, rgba(palette.hover or palette.base))
    ImGui.PushStyleColor(ImGuiCol.ButtonActive, rgba(palette.active or palette.base))
    if palette.text then
        ImGui.PushStyleColor(ImGuiCol.Text, rgba(palette.text))
        return 4
    end
    return 3
end

function M.popButtonPalette(count)
    ImGui.PopStyleColor(count or 2)
end

function M.buttonVariant(label, variant, width, height)
    local palette = Theme.component[variant] or Theme.component.secondaryButton
    local pushed = M.pushButtonPalette(palette)
    local clicked
    if width ~= nil then
        clicked = ImGui.Button(label, width, height or 0)
    else
        clicked = ImGui.Button(label)
    end
    M.popButtonPalette(pushed)
    return clicked
end

function M.buttonIntent(label, intent, width, height)
    return M.buttonVariant(label, M.intentVariant[intent or 'neutral'] or intent or 'secondaryButton', width, height)
end

function M.buttonRow(buttons, opts)
    opts = opts or {}
    local desiredCols = opts.cols or #buttons
    local minW = opts.minW or M.size.normalMinW
    local gap = opts.gap or Theme.space.xs
    local height = opts.height or M.size.normalH
    local cols, btnW, resolvedGap = M.adaptiveColumns(desiredCols, minW, gap, opts.availX)
    for i, btn in ipairs(buttons or {}) do
        M.gridSameLine(i, cols, resolvedGap)
        local label = M.fitLabel(btn.label, btn.shortLabel, btnW)
        local clicked = M.buttonIntent(label, btn.intent or btn.variant or 'neutral', btnW, height)
        if clicked and btn.onClick then btn.onClick() end
        if btn.tooltip then M.tooltip(btn.tooltip, btn.tooltipWrap) end
    end
end

function M.section(kind, label, opts)
    opts = opts or {}
    if opts.topGap ~= false then ImGui.Dummy(0, opts.topGap or M.size.sectionTop) end
    local colorTable = Theme.col[kind or 'utility'] or Theme.col.utility
    M.sectionHeader(colorTable, label)
    if opts.bottomGap ~= false then ImGui.Dummy(0, opts.bottomGap or M.size.sectionBottom) end
end

--- Horizontal space from ImGui.GetContentRegionAvail().
--- MQ binds this as multiple returns (availX, availY). Never wrap the bare call in
--- tonumber(...) — Lua forwards both values and tonumber(x, y) treats y as radix.
local function contentAvailX(default)
    default = default or 120
    local v = (ImGui.GetContentRegionAvail())
    if type(v) == 'number' then
        return v
    end
    if type(v) == 'table' then
        return tonumber(v.x or v.X or v[1]) or default
    end
    if v ~= nil then
        local ok, x = pcall(function() return v.x end)
        if ok and type(x) == 'number' then
            return x
        end
    end
    return default
end

M.availX = contentAvailX

function M.compactInput(label, value, opts)
    opts = opts or {}
    local labelW = tonumber(opts.labelW) or 86
    ImGui.TextColored(0.58, 0.63, 0.72, 1.0, label)
    ImGui.SameLine()
    local avail = contentAvailX(120)
    local width = tonumber(opts.width) or math.max(80, avail - labelW)
    ImGui.PushItemWidth(width)
    local nextValue = ImGui.InputText(opts.id or ('##input_' .. tostring(label)), tostring(value or ''))
    ImGui.PopItemWidth()
    return nextValue
end

function M.compactCombo(label, current, options, opts)
    opts = opts or {}
    ImGui.TextColored(0.58, 0.63, 0.72, 1.0, label)
    ImGui.SameLine()
    ImGui.PushItemWidth(tonumber(opts.width) or math.max(100, contentAvailX(100)))
    local changed = false
    local nextValue = current
    if ImGui.BeginCombo(opts.id or ('##combo_' .. tostring(label)), tostring(current or '')) then
        for _, opt in ipairs(options or {}) do
            if ImGui.Selectable(tostring(opt) .. '##opt_' .. tostring(opt), tostring(opt) == tostring(current)) then
                nextValue = opt
                changed = true
            end
        end
        ImGui.EndCombo()
    end
    ImGui.PopItemWidth()
    return nextValue, changed
end

function M.pushTableStyle()
    ImGui.PushStyleColor(ImGuiCol.TableHeaderBg, rgba(Theme.col.header))
    ImGui.PushStyleColor(ImGuiCol.TableRowBg, rgba(Theme.col.tableRowBg))
    ImGui.PushStyleColor(ImGuiCol.TableRowBgAlt, rgba(Theme.col.tableRowBgAlt))
    ImGui.PushStyleColor(ImGuiCol.TableBorderStrong, rgba(Theme.col.tableBorderS))
    ImGui.PushStyleColor(ImGuiCol.TableBorderLight, rgba(Theme.col.tableBorderL))
    ImGui.PushStyleVar(ImGuiStyleVar.CellPadding, 4, 3)
    return 6
end

function M.popTableStyle(count)
    count = tonumber(count) or 6
    ImGui.PopStyleVar(1)
    ImGui.PopStyleColor(math.max(0, count - 1))
end

function M.menuItem(label, onClick, enabled, color)
    if enabled == false then ImGui.BeginDisabled() end
    local pushedColor = false
    if color and enabled ~= false then
        ImGui.PushStyleColor(ImGuiCol.Text, rgba(color))
        pushedColor = true
    end
    local clicked = ImGui.Selectable(label)
    if pushedColor then ImGui.PopStyleColor(1) end
    if enabled == false then ImGui.EndDisabled() end
    if clicked and enabled ~= false and onClick then onClick() end
    return clicked and enabled ~= false
end

function M.buttonRgb(label, rgb, width, height, text)
    local palette = {
        base = { rgb[1], rgb[2], rgb[3], 255 },
        hover = { math.min(rgb[1] + 25, 255), math.min(rgb[2] + 25, 255), math.min(rgb[3] + 25, 255), 255 },
        text = text,
    }
    local pushed = M.pushButtonPalette(palette)
    local clicked
    if width ~= nil then
        clicked = ImGui.Button(label, width, height or 0)
    else
        clicked = ImGui.Button(label)
    end
    M.popButtonPalette(pushed)
    return clicked
end

function M.adaptiveColumns(desiredCols, minButtonW, gap, hintW)
    desiredCols = math.max(1, tonumber(desiredCols) or 1)
    minButtonW = tonumber(minButtonW) or 82
    gap = tonumber(gap) or ImGui.GetStyle().ItemSpacing.x
    local availW = hintW
    if availW == nil then
        availW = contentAvailX(minButtonW)
    else
        availW = tonumber(availW) or contentAvailX(minButtonW)
    end

    for cols = desiredCols, 2, -1 do
        local w = math.floor((availW - (gap * (cols - 1))) / cols)
        if w >= minButtonW then
            return cols, math.max(1, w), gap
        end
    end

    return 1, math.max(1, math.floor(availW)), gap
end

function M.gridSameLine(index, cols, gap)
    if cols > 1 and ((index - 1) % cols) > 0 then
        ImGui.SameLine(0, gap or ImGui.GetStyle().ItemSpacing.x)
    end
end

function M.fitLabel(longLabel, shortLabel, width, approxCharW)
    longLabel = tostring(longLabel or '')
    shortLabel = tostring(shortLabel or longLabel)
    width = tonumber(width) or 0
    approxCharW = tonumber(approxCharW) or (ImGui.GetFontSize() * 0.58)
    local visible = longLabel:match('^(.-)##') or longLabel
    local needed = (#visible * approxCharW) + 18
    if width > 0 and needed > width then
        local suffix = longLabel:match('(##.*)$') or ''
        return shortLabel .. suffix
    end
    return longLabel
end

function M.toggleChip(id, isOn, opts)
    opts = opts or {}
    local width = opts.width or 28
    local height = opts.height or 14
    local radius = height * 0.5
    local screenX, screenY = ImGui.GetCursorScreenPos()
    ImGui.InvisibleButton(id, width, height)
    local rawClicked = ImGui.IsItemClicked()
    local clicked = rawClicked
    if rawClicked and opts.nowMS and opts.debounceMs and opts.lastToggleMS and opts.setLastToggleMS then
        local t = opts.nowMS()
        clicked = (t - opts.lastToggleMS()) >= opts.debounceMs
        if clicked then opts.setLastToggleMS(t) end
    end

    local drawList = ImGui.GetWindowDrawList()
    local palette = isOn and Theme.component.toggleOn or Theme.component.toggleOff
    drawList:AddRectFilled(
        ImVec2(screenX, screenY),
        ImVec2(screenX + width, screenY + height),
        rgba(palette.track),
        radius
    )
    local knobX = isOn and (screenX + width - radius) or (screenX + radius)
    drawList:AddCircleFilled(ImVec2(knobX, screenY + radius), radius - 1.5, rgba(palette.knob), 0)
    return clicked
end

function M.stopSignButton(id, width, height)
    width = width or 28
    height = height or width
    local x, y = ImGui.GetCursorScreenPos()
    ImGui.InvisibleButton(id, width, height)
    local clicked = ImGui.IsItemClicked()
    local hovered = ImGui.IsItemHovered()
    local drawList = ImGui.GetWindowDrawList()
    local cx = x + width * 0.5
    local cy = y + height * 0.5
    --- 1.1.1: octagon + horizontal bar (universal "halt" sign) replaces the
    --- prior red-circle + exclamation glyph. The old glyph read as a system
    --- error/warning icon (the same shape every OS uses for "something is
    --- wrong"), so users misread the button as a Turbo error indicator. The
    --- 8-segment circle naturally draws as an octagon (the road-sign "STOP"
    --- shape) and the white bar is the "halt / do not enter" mark, which is
    --- unambiguously a button without looking like an alert.
    --- Geometry uses AddCircleFilled with num_segments = 8 — same primitive
    --- as the prior code path, just with the inner glyph replaced. Avoids
    --- the AddConvexPolyFilled binding which isn't used anywhere else in
    --- this codebase and could silently fail to render on the MQ Next side.
    local radius = math.max(8, math.min(width, height) * 0.46)
    local red = hovered and IM_COL32(210, 50, 45, 255) or IM_COL32(160, 38, 36, 255)
    drawList:AddCircleFilled(ImVec2(cx, cy), radius, red, 8)
    --- White horizontal bar in the middle. Width = ~55% of the octagon's
    --- circumscribed radius, centered, ~13% of radius tall. Reads as a
    --- "halt" mark at any reasonable button size.
    local barHalfW = radius * 0.55
    local barHalfH = math.max(1.2, radius * 0.13)
    drawList:AddRectFilled(
        ImVec2(cx - barHalfW, cy - barHalfH),
        ImVec2(cx + barHalfW, cy + barHalfH),
        IM_COL32(255, 248, 240, 255),
        1.0
    )
    return clicked
end

function M.separator(r, g, b, a)
    ImGui.PushStyleColor(ImGuiCol.Separator, IM_COL32(r, g, b, a or 100))
    ImGui.Separator()
    ImGui.PopStyleColor(1)
end

function M.sectionHeader(colorTable, label)
    local sep = colorTable and colorTable.sep or Theme.col.turboloot.sep
    local labelColor = colorTable and colorTable.label or Theme.component.sectionHeader.text
    M.separator(sep[1], sep[2], sep[3], sep[4])
    if not (label and label ~= '') then return end

    --- 1.1.0: optional colored dot before the label. Set per-section via
    --- Theme.col.<section>.dot = {r, g, b, a}. Acts as a quick visual anchor
    --- so the eye finds section breaks (TurboLoot / TurboGive / Currency /
    --- etc.) faster than reading text alone. Falls through cleanly when the
    --- field is absent — older themes / sections without a `dot` value just
    --- render as before (no dot, label flush left).
    local dot = colorTable and colorTable.dot
    if dot then
        --- Dot geometry: ~6px radius, vertically centered on the label line.
        --- Padding before/after is handled by SameLine spacing so we don't
        --- need to advance the cursor manually.
        local fontSize = ImGui.GetFontSize()
        local radius = math.max(3, math.floor(fontSize * 0.30))
        local cx, cy = ImGui.GetCursorScreenPos()
        --- Vertical center of the upcoming text line — fontSize / 2 below the
        --- cursor's top edge. Add a 1px nudge so the dot looks visually
        --- centered with the cap-height of the label (font ascender bias).
        local centerY = cy + math.floor(fontSize * 0.5) + 1
        local centerX = cx + radius + 2
        local drawList = ImGui.GetWindowDrawList()
        drawList:AddCircleFilled(ImVec2(centerX, centerY), radius, rgba(dot), 0)
        --- Reserve horizontal space for the dot so the label doesn't draw on top of it.
        --- 2 px lead + diameter + 4 px trail = a tidy gap before the label.
        ImGui.Dummy(radius * 2 + 6, 1)
        ImGui.SameLine(0, 0)
    end

    ImGui.TextColored(labelColor[1], labelColor[2], labelColor[3], labelColor[4] or 1.0, label)
end

function M.tabButton(label, isActive, hasAttention, width, height)
    local palette = Theme.tabVariant(isActive, hasAttention)
    local pushed = M.pushButtonPalette(palette)
    local clicked = ImGui.Button(label, width, height)
    M.popButtonPalette(pushed)
    return clicked
end

function M.subTabButton(label, isActive, width, height)
    local variant = isActive and 'subTabActive' or 'subTabInactive'
    return M.buttonVariant(label, variant, width, height or 22)
end

return M
