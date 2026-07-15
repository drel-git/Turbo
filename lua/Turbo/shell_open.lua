--[[
  Turbo/shell_open.lua
  Safe external file / folder / URL opener for ImGui callbacks.

  ShellExecuteA lives in shell32.dll, not ffi.C. Load shell32 explicitly,
  pcall-guard every FFI and fallback path so a failed open cannot abort
  an ImGui draw frame.
]]

local M = {}

local state = {
    shell32 = nil,
    ffi = nil,
    cdefDone = false,
}

function M.winQuotedArg(p)
    if not p then return '""' end
    return '"' .. tostring(p):gsub('"', '') .. '"'
end

function M.isSafeHttpUrl(url)
    url = tostring(url or ''):match('^%s*(.-)%s*$') or ''
    if url == '' then return false end
    local lower = url:lower()
    if not (lower:match('^https://') or lower:match('^http://')) then
        return false
    end
    if url:find('[%c%s"\'`&|<>^]') then
        return false
    end
    return true
end

--- Alias kept for callers that validate URL bases before appending IDs.
M.isSafeHttpBaseUrl = M.isSafeHttpUrl

function M.shellOpenExternal(target)
    target = tostring(target or ''):match('^%s*(.-)%s*$') or ''
    if target == '' then return false end

    local okFfi, ffi = pcall(require, 'ffi')
    if okFfi and ffi then
        if not state.cdefDone then
            pcall(ffi.cdef, [[
                void* ShellExecuteA(
                    void* hwnd,
                    const char* lpOperation,
                    const char* lpFile,
                    const char* lpParameters,
                    const char* lpDirectory,
                    int nShowCmd
                );
            ]])
            state.cdefDone = true
        end

        local ok = pcall(function()
            if not state.shell32 then
                state.shell32 = ffi.load('shell32')
                state.ffi = ffi
            end
            local ret = state.shell32.ShellExecuteA(nil, 'open', target, nil, nil, 1)
            local code = tonumber(state.ffi.cast('intptr_t', ret))
            if not code or code <= 32 then
                error('ShellExecuteA failed: ' .. tostring(code))
            end
        end)
        if ok then return true end
    end

    local ok2 = pcall(function()
        if target:lower():match('^https?://') then
            os.execute(string.format('start "" %s', M.winQuotedArg(target)))
        else
            os.execute(string.format('explorer %s', M.winQuotedArg(target)))
        end
    end)
    return ok2 == true
end

function M.shellOpenFile(path)
    path = tostring(path or ''):match('^%s*(.-)%s*$') or ''
    if path == '' then return false end
    return M.shellOpenExternal(path)
end

function M.shellOpenFolder(dir)
    dir = tostring(dir or ''):match('^%s*(.-)%s*$') or ''
    if dir == '' then return false end
    return M.shellOpenExternal(dir)
end

function M.shellOpenUrl(url)
    url = tostring(url or ''):match('^%s*(.-)%s*$') or ''
    if not M.isSafeHttpUrl(url) then return false end
    return M.shellOpenExternal(url)
end

function M.openAllaPage(baseUrl, id)
    id = tonumber(id)
    if not id or id <= 0 then return false end
    baseUrl = tostring(baseUrl or '')
    if not M.isSafeHttpUrl(baseUrl) then return false end
    return M.shellOpenExternal(baseUrl .. tostring(math.floor(id)))
end

return M
