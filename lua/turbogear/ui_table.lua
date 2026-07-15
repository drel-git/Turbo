-- TurboGear/ui_table.lua
-- Small table/sort helpers shared by cached-data tabs.

local M = {}

local LOCATION_ORDER = {
    equipped = 10,
    installed_aug = 20,
    loose_aug = 30,
    bags = 40,
    bank = 50,
    stored_gear = 60,
    offline_cache = 70,
    unknown = 999,
}

local function lower(v) return tostring(v or ""):lower() end

local function safe_number(v)
    v = tonumber(v) or 0
    if v ~= v then return 0 end
    return v
end

function M.stable_sort(rows, less)
    local n = #(rows or {})
    if n < 2 or type(less) ~= "function" then return end
    local src, dst = rows, {}
    local width = 1
    while width < n do
        local out = 1
        local start = 1
        while start <= n do
            local left, right = start, math.min(start + width, n + 1)
            local left_end, right_end = right, math.min(start + (width * 2), n + 1)
            while left < left_end or right < right_end do
                if left >= left_end then
                    dst[out] = src[right]
                    right = right + 1
                elseif right >= right_end then
                    dst[out] = src[left]
                    left = left + 1
                elseif less(src[right], src[left]) then
                    dst[out] = src[right]
                    right = right + 1
                else
                    dst[out] = src[left]
                    left = left + 1
                end
                out = out + 1
            end
            start = start + (width * 2)
        end
        src, dst = dst, src
        width = width * 2
    end
    if src ~= rows then
        for i = 1, n do rows[i] = src[i] end
    end
end

function M.location_sort_value(row)
    local key = row and (row.locationGroup or row.where) or "unknown"
    return LOCATION_ORDER[key] or LOCATION_ORDER.unknown
end

function M.compare_string(a, b)
    a, b = lower(a), lower(b)
    if a == b then return nil end
    return a < b
end

function M.compare_number(a, b, desc)
    a, b = safe_number(a), safe_number(b)
    if a == b then return nil end
    if desc then return a > b end
    return a < b
end

function M.stable_row_less(a, b)
    local loc = M.compare_number(M.location_sort_value(a), M.location_sort_value(b), false)
    if loc ~= nil then return loc end
    local owner = M.compare_string(a and a.owner, b and b.owner)
    if owner ~= nil then return owner end
    local name = M.compare_string(a and a.name, b and b.name)
    if name ~= nil then return name end
    return lower(a and a.sourceKey) < lower(b and b.sourceKey)
end

function M.sort_stat_rows(rows, stat_key, direction)
    stat_key = stat_key or "shielding"
    local desc = direction ~= "asc"
    local wrappers = {}
    for i, row in ipairs(rows or {}) do wrappers[i] = { row = row, index = i } end
    M.stable_sort(wrappers, function(a, b)
        local ar, br = a.row, b.row
        local av = ar and ar.stats and safe_number(ar.stats[stat_key]) or 0
        local bv = br and br.stats and safe_number(br.stats[stat_key]) or 0
        local stat_cmp = M.compare_number(av, bv, desc)
        if stat_cmp ~= nil then return stat_cmp end
        local loc = M.compare_number(M.location_sort_value(ar), M.location_sort_value(br), false)
        if loc ~= nil then return loc end
        local owner = M.compare_string(ar and ar.owner, br and br.owner)
        if owner ~= nil then return owner end
        local name = M.compare_string(ar and ar.name, br and br.name)
        if name ~= nil then return name end
        local source = M.compare_string(ar and ar.sourceKey, br and br.sourceKey)
        if source ~= nil then return source end
        return (a.index or 0) < (b.index or 0)
    end)
    for i, wrapped in ipairs(wrappers) do rows[i] = wrapped.row end
end

function M.placeholder(text)
    return tostring(text or "-")
end

return M
