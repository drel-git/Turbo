--[[
  Turbo View — Footer (Commands)
  ------------------------------------------
  @version lua/Turbo/ui/views/footer.lua 1.2.1
]]

local ImGui = require('ImGui')

local M = {}

function M.render(state, actions)
    local helpId = state.popupIds.help

    actions.coloredSep(55, 60, 75, 60)

    local availX = ImGui.GetContentRegionAvail()
    local avail = tonumber(availX) or 120
    local btnW = math.min(128, math.max(96, avail))
    if avail > btnW then
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + avail - btnW)
    end
    if actions.ui.buttonVariant('Commands##footerhelp', 'footerCommandsButton', btnW, 0) then
        ImGui.OpenPopup(helpId)
    end
    actions.tip('Commands for TurboLoot, TurboGive, TurboKey, and the Turbo window')

    if helpId and actions.renderHelpPopupBody and ImGui.BeginPopup(helpId) then
        actions.renderHelpPopupBody(state.raw)
        ImGui.EndPopup()
    end
end

return M
