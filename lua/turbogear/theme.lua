-- TurboGear/theme.lua
-- Turbo-aligned theme tokens and the small ImGui draw helpers built on them.
-- Color tokens follow the Turbo suite convention (brick-red = Destroy ONLY).

local ImGui = require('ImGui')
local CFG   = require('config').CFG

local M = {}

M.Theme = {
    green = { 0.45, 0.90, 0.62, 1.0 }, purple = { 0.55, 0.47, 0.72, 1.0 },
    blue  = { 0.20, 0.34, 0.55, 1.0 }, steel  = { 0.20, 0.23, 0.29, 1.0 },
    menu  = { 0.255, 0.378, 0.544, 1.0 },
    brick = { 0.70, 0.34, 0.34, 1.0 }, gold   = { 0.85, 0.64, 0.25, 1.0 },
    cyan  = { 0.36, 0.66, 0.76, 1.0 }, amber  = { 0.95, 0.72, 0.30, 1.0 },
    item  = { 0.30, 0.78, 0.92, 1.0 }, dim    = { 0.50, 0.55, 0.62, 1.0 },
    sync  = { 0.20, 0.44, 0.47, 1.0 },
    online= { 0.42, 0.78, 0.52, 1.0 }, offline= { 0.46, 0.49, 0.55, 1.0 },
    header= { 0.78, 0.82, 0.88, 1.0 }, slot   = { 0.72, 0.66, 0.38, 1.0 },
    haveWorn = { 0.45, 0.90, 0.62, 1.0 },
    haveBag  = { 0.52, 0.72, 1.00, 1.0 },
    missing  = { 0.92, 0.36, 0.34, 1.0 },
    partial  = { 0.95, 0.72, 0.30, 1.0 },
    category = { 0.35, 0.70, 0.85, 1.0 },
    muted    = { 0.50, 0.55, 0.62, 1.0 },
    placeholder = { 0.32, 0.35, 0.40, 1.0 },
    aug = { 0.42, 0.82, 0.62, 1.0 }, socket = { 0.48, 0.51, 0.58, 1.0 },
    emptySocket = { 0.88, 0.66, 0.23, 1.0 }, section = { 0.35, 0.70, 0.85, 1.0 },
    sectionBg = { 0.18, 0.22, 0.28, 0.96 },
    upgradeRow = { 0.10, 0.17, 0.13, 0.88 },
    tank = { 0.50, 0.58, 0.68, 1.0 }, healer = { 0.38, 0.78, 0.62, 1.0 },
    melee = { 0.86, 0.62, 0.38, 1.0 }, caster = { 0.62, 0.47, 0.82, 1.0 },
    utility = { 0.36, 0.74, 0.78, 1.0 },
    bag = { 0.32, 0.47, 0.68, 1.0 }, bank = { 0.55, 0.47, 0.72, 1.0 },
    -- Characters chrome: muted teal - quiet tint, distinct from Sync/action blues.
    charactersPill = { 0.30, 0.44, 0.42, 1.0 },
    location = { 0.58, 0.61, 0.68, 1.0 }, owner = { 0.64, 0.68, 0.75, 1.0 },
    value = { 0.72, 0.88, 0.74, 1.0 }, valueTop = { 0.85, 0.64, 0.25, 1.0 },
    neutral = { 0.78, 0.82, 0.88, 1.0 },
    poison = { 0.42, 0.86, 0.42, 1.0 }, cold = { 0.38, 0.70, 1.00, 1.0 },
    disease = { 0.55, 0.62, 0.34, 1.0 }, magic = { 0.96, 0.56, 0.92, 1.0 },
    fire = { 1.00, 0.42, 0.32, 1.0 },
}

function M.col_text(c, txt)
    ImGui.TextColored(c[1], c[2], c[3], c[4], txt)
end

function M.location_color(group, text)
    local g = tostring(group or ""):lower()
    local t = tostring(text or ""):lower()
    if g == "bank" or t:find("^bank") then return M.Theme.bank or M.Theme.purple end
    if g == "bags" or t:find("^bags") or t:find("^bag") then return M.Theme.bag or M.Theme.blue end
    return M.Theme.location or M.Theme.dim
end

function M.report_owner_color()
    return M.Theme.owner or M.Theme.dim
end

local function color_u32(c)
    c = c or M.Theme.slot
    if ImGui.GetColorU32 then return ImGui.GetColorU32(c[1], c[2], c[3], c[4]) end
    return IM_COL32(math.floor((c[1] or 1) * 255), math.floor((c[2] or 1) * 255), math.floor((c[3] or 1) * 255), math.floor((c[4] or 1) * 255))
end
M.color_u32 = color_u32

function M.segmented_text(segments)
    if not (ImGui.GetWindowDrawList and ImGui.GetCursorScreenPos and ImGui.CalcTextSize and ImGui.Dummy) then
        local text = {}
        for _, seg in ipairs(segments or {}) do text[#text+1] = tostring(seg.text or "") end
        M.col_text((segments and segments[1] and segments[1].color) or M.Theme.slot, table.concat(text))
        return
    end
    local x, y = ImGui.GetCursorScreenPos()
    local draw = ImGui.GetWindowDrawList()
    local cx = x
    local total_w = 0
    for _, seg in ipairs(segments or {}) do
        local text = tostring(seg.text or "")
        if text ~= "" then
            draw:AddText(ImVec2(cx, y), color_u32(seg.color), text)
            local w, h = ImGui.CalcTextSize(text)
            if type(w) == "table" then w = w.x or w[1] end
            w = tonumber(w) or 0
            cx = cx + w
            total_w = total_w + w
        end
    end
    local line_h = (ImGui.GetTextLineHeight and ImGui.GetTextLineHeight()) or (ImGui.GetFontSize and ImGui.GetFontSize()) or 14
    ImGui.Dummy(math.max(total_w, 1), line_h)
end

local PAREN_COLOR_KEYS = {
    poison = "poison",
    cold = "cold",
    disease = "disease",
    fire = "fire",
    magic = "magic",
    ["p/b"] = "magic",
    defensive = "cold",
    defense = "cold",
    avoidance = "cold",
    dodge = "cold",
    shielding = "cold",
    shield = "cold",
    durable = "cold",
    dur = "cold",
    offensive = "fire",
    offense = "fire",
    attack = "fire",
    frenzy = "fire",
    backstab = "fire",
    kick = "fire",
    ["tiger claw"] = "fire",
    ["flying kick"] = "fire",
    ["spell damage"] = "fire",
    accuracy = "gold",
    healing = "green",
    mana = "purple",
    crit = "gold",
}

function M.parenthetical_color(label, fallback)
    local text = tostring(label or ""):lower()
    for key, color_key in pairs(PAREN_COLOR_KEYS) do
        if text:find(key, 1, true) then return M.Theme[color_key] or fallback or M.Theme.slot end
    end
    return fallback or M.Theme.slot
end

function M.colored_text_segments(text, base_color)
    text = tostring(text or "")
    base_color = base_color or M.Theme.item
    local segments, pos = {}, 1
    while pos <= #text do
        local s, e, inside = text:find("%(([^%)]-)%)", pos)
        if not s then
            local rest = text:sub(pos)
            if rest ~= "" then segments[#segments + 1] = { text = rest, color = base_color } end
            break
        end
        if s > pos then segments[#segments + 1] = { text = text:sub(pos, s - 1), color = base_color } end
        local part = text:sub(s, e)
        segments[#segments + 1] = { text = part, color = M.parenthetical_color(inside, M.Theme.slot) }
        pos = e + 1
    end
    if #segments == 0 then segments[1] = { text = text, color = base_color } end
    return segments
end

function M.colored_text(text, base_color)
    M.segmented_text(M.colored_text_segments(text, base_color or M.Theme.item))
end

function M.themed_button(label, c, w, h)
    ImGui.PushStyleColor(ImGuiCol.Button,        c[1]*0.90, c[2]*0.90, c[3]*0.90, 1.0)
    ImGui.PushStyleColor(ImGuiCol.ButtonHovered, math.min(c[1]*1.20,1), math.min(c[2]*1.20,1), math.min(c[3]*1.20,1), 1.0)
    ImGui.PushStyleColor(ImGuiCol.ButtonActive,  c[1]*0.70, c[2]*0.70, c[3]*0.70, 1.0)
    local clicked = ImGui.Button(label, w or 0, h or 0)
    ImGui.PopStyleColor(3)
    return clicked
end

function M.toggle_button(label, active, w, h)
    return M.themed_button(label, active and M.Theme.blue or M.Theme.steel, w, h)
end

function M.sync_button(label, w, h)
    local pushed_border, pushed_var = false, false
    if ImGuiCol and ImGuiCol.Border and ImGui.PushStyleColor then
        local c = M.Theme.gold or { 0.85, 0.64, 0.25, 1.0 }
        ImGui.PushStyleColor(ImGuiCol.Border, c[1], c[2], c[3], 0.95)
        pushed_border = true
    end
    if ImGuiStyleVar and ImGuiStyleVar.FrameBorderSize and ImGui.PushStyleVar then
        ImGui.PushStyleVar(ImGuiStyleVar.FrameBorderSize, 1.25)
        pushed_var = true
    end
    local clicked = M.themed_button(label or "Sync Now", M.Theme.sync, w, h)
    if pushed_var then ImGui.PopStyleVar(1) end
    if pushed_border then ImGui.PopStyleColor(1) end
    return clicked
end

function M.nav_button(label, active, secondary, w, h)
    local bg = active and (secondary and { 0.16, 0.20, 0.27, 1.0 } or { 0.13, 0.17, 0.24, 1.0 }) or { 0.07, 0.09, 0.12, 1.0 }
    local hov = active and { 0.20, 0.24, 0.32, 1.0 } or { 0.12, 0.15, 0.20, 1.0 }
    local act = active and { 0.24, 0.26, 0.30, 1.0 } or { 0.10, 0.12, 0.16, 1.0 }
    local txt = active and M.Theme.gold or { 0.68, 0.71, 0.77, 1.0 }
    ImGui.PushStyleColor(ImGuiCol.Button, bg[1], bg[2], bg[3], bg[4])
    ImGui.PushStyleColor(ImGuiCol.ButtonHovered, hov[1], hov[2], hov[3], hov[4])
    ImGui.PushStyleColor(ImGuiCol.ButtonActive, act[1], act[2], act[3], act[4])
    ImGui.PushStyleColor(ImGuiCol.Text, txt[1], txt[2], txt[3], txt[4])
    local clicked = ImGui.Button(label, w or 0, h or (secondary and 22.0 or 24.0))
    ImGui.PopStyleColor(4)
    return clicked
end

function M.section_header(label, c)
    ImGui.Spacing(); M.col_text(c, label); ImGui.Separator()
end

function M.bis_status_color(status)
    if status == "equipped" then return M.Theme.haveWorn or M.Theme.green end
    if status == "carried" then return M.Theme.haveBag or M.Theme.blue end
    if status == "partial" then return M.Theme.partial or M.Theme.amber end
    return M.Theme.missing or M.Theme.brick
end

function M.bis_status_label(status)
    if status == "equipped" then return "Worn" end
    if status == "carried" then return "In Bag/Bank" end
    if status == "partial" then return "Partial" end
    return "Missing"
end

function M.item_link_color()
    return M.Theme.item
end

function M.collapsing_section(label, default_open)
    label = tostring(label or "")
    if ImGui.CollapsingHeader then
        local flags = 0
        if default_open and ImGuiTreeNodeFlags and ImGuiTreeNodeFlags.DefaultOpen then
            flags = ImGuiTreeNodeFlags.DefaultOpen
        end
        local ok, open = pcall(ImGui.CollapsingHeader, label .. "##tg_collapse", flags)
        if ok then return open end
    end
    M.section_header(label, M.Theme.category or M.Theme.cyan)
    return true
end

function M.push_compact_style()
    return M.push_density_style("compact")
end

function M.push_density_style(mode)
    local state = { vars = 0 }
    local function pv(v, ...)
        if v ~= nil and pcall(ImGui.PushStyleVar, v, ...) then state.vars = state.vars + 1 end
    end
    mode = tostring(mode or "normal")
    if mode == "ultra" then
        pv(ImGuiStyleVar.ItemSpacing, 4.0, 0.0)
        pv(ImGuiStyleVar.FramePadding, 3.0, 1.0)
        if ImGuiStyleVar.CellPadding then pv(ImGuiStyleVar.CellPadding, 2.0, 1.0) end
    elseif mode == "compact" then
        pv(ImGuiStyleVar.ItemSpacing, 4.0, 1.0)
        pv(ImGuiStyleVar.FramePadding, 4.0, 2.0)
        if ImGuiStyleVar.CellPadding then pv(ImGuiStyleVar.CellPadding, 4.0, 2.0) end
    end
    return state
end

function M.pop_compact_style(state)
    M.pop_density_style(state)
end

function M.pop_density_style(state)
    if state and (state.vars or 0) > 0 then ImGui.PopStyleVar(state.vars) end
end

function M.push_theme()
    local vars, cols = 0, 0
    local function pv(v, ...) if v ~= nil and pcall(ImGui.PushStyleVar, v, ...) then vars = vars + 1 end end
    local function pc(c, r, g, b, a) if c ~= nil and pcall(ImGui.PushStyleColor, c, r, g, b, a) then cols = cols + 1 end end
    pv(ImGuiStyleVar.FrameRounding, CFG.frame_round); pv(ImGuiStyleVar.GrabRounding, CFG.frame_round)
    pv(ImGuiStyleVar.TabRounding, CFG.frame_round);   pv(ImGuiStyleVar.WindowRounding, CFG.window_round)
    pv(ImGuiStyleVar.FramePadding, 7.0, 4.0)
    pc(ImGuiCol.WindowBg, 0.055,0.058,0.075,1.0); pc(ImGuiCol.ChildBg, 0.090,0.100,0.120,1.0)
    pc(ImGuiCol.Border, 0.78,0.58,0.22,0.78)
    pc(ImGuiCol.FrameBg, 0.130,0.140,0.170,1.0);  pc(ImGuiCol.FrameBgHovered, 0.180,0.200,0.240,1.0)
    pc(ImGuiCol.FrameBgActive, 0.200,0.230,0.280,1.0); pc(ImGuiCol.TitleBg, 0.070,0.075,0.095,1.0)
    pc(ImGuiCol.TitleBgActive, 0.110,0.130,0.180,1.0); pc(ImGuiCol.Tab, 0.130,0.150,0.190,1.0)
    pc(ImGuiCol.TabHovered, 0.220,0.380,0.680,1.0); pc(ImGuiCol.TabActive, 0.180,0.320,0.560,1.0)
    pc(ImGuiCol.Header, 0.180,0.320,0.560,0.55); pc(ImGuiCol.HeaderHovered, 0.220,0.380,0.680,0.80)
    pc(ImGuiCol.HeaderActive, 0.180,0.320,0.560,1.0); pc(ImGuiCol.TableHeaderBg, 0.125,0.140,0.170,1.0)
    pc(ImGuiCol.TableRowBg, 0.075,0.078,0.092,1.0); pc(ImGuiCol.TableRowBgAlt, 0.105,0.110,0.132,1.0)
    pc(ImGuiCol.TableBorderStrong, 0.330,0.370,0.460,1.0); pc(ImGuiCol.TableBorderLight, 0.230,0.255,0.320,1.0)
    pc(ImGuiCol.Separator, 0.260,0.300,0.380,1.0)
    return { vars = vars, colors = cols }
end

function M.pop_theme(p)
    ImGui.PopStyleColor(p.colors); ImGui.PopStyleVar(p.vars)
end

return M
