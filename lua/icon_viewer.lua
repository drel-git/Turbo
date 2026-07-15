--[[
  Minimal ImGui loop to browse `lib.icons` (RedGuides "ImGui, Lua and Font Icons" pattern).

  Prerequisites:
    - lua/lib/icons.lua from that resource (require path: lib.icons)

  Run in game:
    /lua run icon_viewer

  If it fails: read the FIRST red line in mq chat / console — usually require() or mq.imgui.
]]

local mq = require('mq')
local ImGui = require('ImGui')

--- Clear a half-loaded chunk so retries / this script show the real error, not only
--- "loop or previous error loading module 'lib.icons'".
package.loaded['lib.icons'] = nil

local ICON
do
    local ok, mod = pcall(require, 'lib.icons')
    if not ok or type(mod) ~= 'table' then
        local mqPath = (mq.TLO and mq.TLO.MacroQuest and mq.TLO.MacroQuest.Path and mq.TLO.MacroQuest.Path()) or ''
        mq.cmdf('/echo [icon_viewer] require("lib.icons") failed: %s', tostring(mod))
        mq.cmd('/echo [icon_viewer] Expected: ...\\\\MacroQuest\\\\lua\\\\lib\\\\icons.lua')
        if mqPath ~= '' then
            mq.cmdf('/echo [icon_viewer] MacroQuest.Path: %s', (mqPath:gsub('\\', '/')))
            local probe = mqPath .. '\\lua\\lib\\icons.lua'
            mq.cmdf('/echo [icon_viewer] Probing %s', (probe:gsub('\\', '/')))
            local chunk, ferr = loadfile(probe)
            if not chunk then
                mq.cmdf('/echo [icon_viewer] loadfile diagnostics: %s', tostring(ferr))
            else
                local r2, err2 = pcall(chunk)
                if not r2 then
                    mq.cmdf('/echo [icon_viewer] icons.lua runtime: %s', tostring(err2))
                end
            end
        end
        return
    end
    ICON = mod
end

local scriptName = 'icon_viewer'
local TG = {
    mq = mq,
    ImGui = ImGui,
    windowOpen = true,
}

local function trim(s)
    return (tostring(s or ''):gsub('^%s*(.-)%s*$', '%1'))
end

local searchText = ''

local function renderWindow()
    local g = TG
    local ImGui_ = g.ImGui

    if not g.windowOpen then
        return
    end

    local shouldDraw
    g.windowOpen, shouldDraw = ImGui_.Begin('Icon viewer###icon_viewer_win', g.windowOpen, 0)
    if shouldDraw == nil then
        shouldDraw = g.windowOpen
    end

    if shouldDraw then
        searchText = ImGui_.InputText('Filter##icon_filter', searchText, 96)
        searchText = trim(searchText)

        if ImGui_.BeginChild('##icon_scroll', 0, 0, false) then
            local patt = (#searchText > 0) and searchText:lower() or nil
            local n = 0
            for key, value in pairs(ICON) do
                local name = tostring(key)
                if not patt or name:lower():find(patt, 1, true) then
                    ImGui_.Text(string.format('%s\t%s', tostring(value), name))
                    n = n + 1
                end
            end
            if n == 0 then
                ImGui_.TextDisabled('No icons match filter.')
            end
            ImGui_.EndChild()
        end
    end

    ImGui_.End()
end

mq.imgui.init(scriptName, renderWindow)
mq.cmd('/echo [icon_viewer] Window open — close UI to unload script.')

while TG.windowOpen do
    mq.delay(100)
end

mq.imgui.destroy(scriptName)
mq.cmd('/echo [icon_viewer] exited.')
