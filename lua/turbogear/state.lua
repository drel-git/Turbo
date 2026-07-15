-- TurboGear/state.lua
-- Shared runtime control flags (NOT persisted). One table, required everywhere,
-- so the UI shell, the command handler, and the run loops all mutate the same
-- values.
--   run  : main loops continue while true
--   show : UI window is drawn while true (Minimize / X set this false)
--   bg   : this instance is the headless background responder
--   err_once : last render error, surfaced once then cleared
local M = {
    run      = true,
    show     = true,
    bg       = false,
    err_once = nil,
    sync_hint = nil,
    sync_hint_until = 0,
    local_guard_role = "unknown",
    local_guard_summary = "main=? bg=?",
    local_guard_last_action = "",
    local_guard_last_action_at = 0,
}

function M.lean()
    local ok, cfg = pcall(require, 'config')
    if not ok or not cfg or not cfg.Settings then return false end
    local mode = tostring(cfg.Settings.performanceMode or "auto"):lower()
    if mode == "full" or mode == "rich" then return false end
    if mode == "lean" then return true end
    return M.bg == true or M.show == false
end

return M
