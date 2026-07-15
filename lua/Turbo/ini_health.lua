local M = {}

local function trim(s)
    return (tostring(s or ''):gsub('^%s+', ''):gsub('%s+$', ''))
end

local function section_key(section)
    return trim(section):lower()
end

local function read_lines(path)
    local f = io.open(path, 'r')
    if not f then return nil, 'Could not read INI' end
    local lines = {}
    for line in f:lines() do lines[#lines + 1] = line end
    f:close()
    return lines
end

local function write_lines(path, lines)
    local f = io.open(path, 'w')
    if not f then return false, 'Could not write INI' end
    for _, line in ipairs(lines or {}) do f:write(tostring(line or '') .. '\n') end
    f:close()
    return true
end

function M.scan_sections(path)
    local lines, err = read_lines(path)
    if not lines then return nil, err end

    local out = {
        counts = {},
        names = {},
        firstLine = {},
        duplicates = {},
    }
    local duplicateByKey = {}

    for i, line in ipairs(lines) do
        local section = line:match('^%s*%[(.-)%]%s*$')
        if section then
            local clean = trim(section)
            local key = section_key(clean)
            if key ~= '' then
                out.counts[key] = (out.counts[key] or 0) + 1
                out.names[key] = out.names[key] or clean
                out.firstLine[key] = out.firstLine[key] or i
                if out.counts[key] >= 2 then
                    local dup = duplicateByKey[key]
                    if not dup then
                        dup = {
                            key = key,
                            section = out.names[key],
                            firstLine = out.firstLine[key],
                            lines = {},
                            count = out.counts[key],
                        }
                        duplicateByKey[key] = dup
                        out.duplicates[#out.duplicates + 1] = dup
                    end
                    dup.lines[#dup.lines + 1] = i
                    dup.count = out.counts[key]
                end
            end
        end
    end

    return out
end

function M.duplicate_sections(path, wanted)
    local scan, err = M.scan_sections(path)
    if not scan then return nil, err end
    local wantedSet = nil
    if type(wanted) == 'string' and wanted ~= '' then
        wantedSet = { [section_key(wanted)] = true }
    elseif type(wanted) == 'table' then
        wantedSet = {}
        for _, section in ipairs(wanted) do
            wantedSet[section_key(section)] = true
        end
    end

    if not wantedSet then return scan.duplicates, nil, scan end
    local filtered = {}
    for _, dup in ipairs(scan.duplicates or {}) do
        if wantedSet[dup.key] then filtered[#filtered + 1] = dup end
    end
    return filtered, nil, scan
end

function M.format_duplicates(duplicates)
    local parts = {}
    for _, dup in ipairs(duplicates or {}) do
        parts[#parts + 1] = string.format('[%s] x%d', tostring(dup.section or '?'), tonumber(dup.count) or 2)
    end
    return table.concat(parts, ', ')
end

function M.write_key_verified(path, section, key, value, writeFn, readFn)
    if type(writeFn) ~= 'function' or type(readFn) ~= 'function' then
        return false, 'INI helpers unavailable'
    end
    value = tostring(value or '')
    local ok = writeFn(path, section, key, value)
    if not ok then return false, 'write failed' end

    local actual = readFn(path, section, key)
    if trim(actual) ~= trim(value) then
        return false, string.format('read-back mismatch: expected %s, got %s',
            value, actual == nil and '<nil>' or tostring(actual))
    end
    return true
end

function M.merge_section(path, section, opts)
    opts = opts or {}
    local lines, err = read_lines(path)
    if not lines then
        if opts.allowCreate == false then return false, err end
        lines = {}
    end

    local targetKey = section_key(section)
    local before, body, after = {}, {}, {}
    local found = false
    local inTarget = false
    local duplicateHeaders = 0
    local removed = 0

    for _, line in ipairs(lines) do
        local sec = line:match('^%s*%[(.-)%]%s*$')
        if sec then
            local isTarget = section_key(sec) == targetKey
            if isTarget then
                if found then duplicateHeaders = duplicateHeaders + 1 end
                found = true
                inTarget = true
            else
                inTarget = false
                if found then after[#after + 1] = line else before[#before + 1] = line end
            end
        elseif inTarget then
            local k, v = line:match('^([^=]+)=(.*)$')
            local key = k and trim(k) or ''
            local value = v and trim(v) or ''
            if opts.removeLine and opts.removeLine(key, value, line) then
                removed = removed + 1
            else
                body[#body + 1] = line
            end
        else
            if found then after[#after + 1] = line else before[#before + 1] = line end
        end
    end

    while #body > 0 and trim(body[#body]) == '' do body[#body] = nil end
    for _, line in ipairs(opts.newLines or {}) do
        if tostring(line or '') ~= '' then body[#body + 1] = tostring(line) end
    end

    local result = {}
    for _, line in ipairs(before) do result[#result + 1] = line end
    if #result > 0 and trim(result[#result]) ~= '' then result[#result + 1] = '' end
    result[#result + 1] = '[' .. section .. ']'
    for _, line in ipairs(body) do result[#result + 1] = line end
    for _, line in ipairs(after) do result[#result + 1] = line end

    local ok, werr = write_lines(path, result)
    if not ok then return false, werr end
    return true, {
        removed = removed,
        duplicateHeaders = duplicateHeaders,
        existed = found,
    }
end

return M
