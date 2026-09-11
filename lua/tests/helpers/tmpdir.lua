-- Writable scratch directory for tests that create real files.
-- Most tests only need mq.configDir as a string nobody writes to, and those can
-- keep any placeholder. This is for the ones doing real file I/O: /tmp does not
-- exist on Windows, so resolve the platform temp dir and fall back to it.

local M = {}

local sep = package.config:sub(1, 1)

function M.dir()
    local d = os.getenv('TMPDIR') or os.getenv('TEMP') or os.getenv('TMP') or '/tmp'
    return (tostring(d):gsub('[/\\]+$', ''))
end

function M.path(name)
    return M.dir() .. sep .. tostring(name)
end

return M
