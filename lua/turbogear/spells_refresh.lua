-- TurboGear/spells_refresh.lua
-- First-open / auto-refresh policy for the Spells tab. Pure: no ImGui, no mq.cmd.
-- Authority is existing spell_cache ready+signature or a snapshot spells_sig.

local M = {}

function M.cache_is_usable(opts)
    opts = type(opts) == "table" and opts or {}
    local sig = tostring(opts.spell_cache_sig or "")
    if opts.spell_cache_ready == true and sig ~= "" then
        return true, "spell_cache"
    end
    local snap = opts.snap
    if type(snap) == "table" and tostring(snap.spells_sig or "") ~= "" then
        return true, "snapshot"
    end
    return false, nil
end

--- Engine owner may rebuild+gather locally. Viewer must not: bg /tgearbg
--- spellsync already does that work in the responder VM.
function M.local_rebuild_allowed(engine_ok)
    return engine_ok == true
end

--- First Spells open / tab-enter decision.
--- last_at==0 used to mean "always refresh"; that forced a hitch whenever
--- a usable cache already existed. Stamp a usable cache instead.
function M.plan_tab_enter(opts)
    opts = type(opts) == "table" and opts or {}
    local now = tonumber(opts.now) or os.time()
    local last_at = tonumber(opts.last_spell_cache_at) or 0
    local interval_s = math.max(60, (tonumber(opts.interval_minutes) or 5) * 60)
    local usable, source = M.cache_is_usable(opts)
    if usable then
        local stamp = last_at == 0
        local age = last_at > 0 and (now - last_at) or 0
        if last_at > 0 and age >= interval_s then
            return {
                action = "schedule_refresh",
                source = "refresh_scheduled",
                reason = "expired",
                stamp = false,
                usable_from = source,
            }
        end
        return {
            action = "draw_cache",
            source = "cache",
            reason = stamp and "first_open_usable" or "fresh",
            stamp = stamp,
            usable_from = source,
        }
    end
    return {
        action = "schedule_refresh",
        source = "refresh_scheduled",
        reason = "no_cache",
        stamp = false,
        usable_from = nil,
    }
end

return M
