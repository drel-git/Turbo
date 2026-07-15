-- TurboGear headless responder wrapper.
-- Runs the unified TurboGear in background mode under a separate script name so
-- `/lua run turbogear` stays free to open the UI. The UI is a viewer/control
-- surface; this responder owns actor sync and inventory publishing.
--
-- Two things this wrapper must handle, because it lives in lua/ (not in
-- lua/turbogear/):
--
-- 1) Module path. init.lua uses bare requires ('config', 'store', ...) that only
--    resolve when lua/turbogear/ is on package.path. We add it below, otherwise
--    the responder dies on load with "module 'config' not found".
--
-- 2) NOT require()-ing init. init.lua is a long-running script: it calls mq.delay
--    and ends in an infinite run loop. require() would execute it during the
--    module-import phase, where MQ forbids mq.delay ("Cannot delay while
--    importing a module") and where the never-returning loop would block the
--    import forever. So we loadfile() the chunk and CALL it as this script's own
--    body, where delays and the run loop are perfectly fine.
local src = (debug.getinfo(1, "S").source or ""):gsub("^@", "")
local dir = src:gsub("[/\\][^/\\]*$", "")
if dir == "" or dir == src then dir = "lua" end
local base = dir .. "/turbogear/"
package.path = base .. "?.lua;" .. base .. "?/init.lua;" .. package.path

_G.__TurboGearForceBg = true
local chunk, err = loadfile(base .. "init.lua")
if not chunk then
    _G.__TurboGearForceBg = nil
    error("[turbogear_bg] could not load turbogear/init.lua: " .. tostring(err))
end
chunk()                       -- runs init.lua as this script's body (blocks in its run loop)
_G.__TurboGearForceBg = nil   -- reached only after TurboGear stops
