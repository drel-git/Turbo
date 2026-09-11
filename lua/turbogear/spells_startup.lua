-- TurboGear/spells_startup.lua
-- Bg startup spell-authority policy. Pure: no ImGui, no MQ TLO probes.
--
-- A persisted spells_sig with spell maps is usable stale authority.
-- Missing/unreadable data is unknown — never an authoritative empty book.

local M = {}

function M.snapshot_is_usable(snap)
    if type(snap) ~= "table" then return false end
    if tostring(snap.spells_sig or "") == "" then return false end
    if type(snap.spells) == "table" then return true end
    if type(snap.spell_ids) == "table" then return true end
    return false
end

--- Bg startup: never live-scan the spell book on the critical path.
--- restore_cache  -> ownership/Core may use persisted spells_sig
--- defer_live     -> no authority yet; do not publish an empty known-set
function M.plan_bg_startup(opts)
    opts = type(opts) == "table" and opts or {}
    if M.snapshot_is_usable(opts.snap) then
        return {
            action = "restore_cache",
            live_scan = false,
            includeSpells = false,
            publish_spells = false,
            reason = "cached_authority",
        }
    end
    return {
        action = "defer_live",
        live_scan = false,
        includeSpells = false,
        publish_spells = false,
        unknown = true,
        reason = "missing_cache",
    }
end

return M
