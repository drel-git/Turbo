-- TurboGear/catalog_content_hash.lua
-- Build/test-only deterministic hash of canonical catalog list content.
-- Production runtime must compare embedded strings and must not require this.

local M = {}

function M.compute(catalog)
    local h1, h2, tokens = 5381, 52711, 0
    local function feed(value)
        value = tostring(value or "")
        for i = 1, #value do
            local byte = value:byte(i)
            h1 = (h1 * 33 + byte) % 4294967296
            h2 = (h2 * 31 + byte) % 4294967296
        end
        h1 = (h1 * 33 + 255) % 4294967296
        h2 = (h2 * 31 + 255) % 4294967296
        tokens = tokens + 1
    end
    local function walk(value)
        local kind = type(value)
        feed(kind)
        if kind ~= "table" then
            feed(value)
            return
        end
        local keys = {}
        for key in pairs(value) do keys[#keys + 1] = key end
        table.sort(keys, function(a, b)
            local ta, tb = type(a), type(b)
            if ta ~= tb then return ta < tb end
            if ta == "number" then return a < b end
            return tostring(a) < tostring(b)
        end)
        for _, key in ipairs(keys) do
            feed(type(key))
            feed(key)
            walk(value[key])
        end
        feed("end")
    end
    local lists, slots = 0, 0
    for _, list in pairs(type(catalog) == "table" and catalog.lists or {}) do
        lists = lists + 1
        for _, category in ipairs(list.categories or {}) do
            slots = slots + #(category.slots or {})
        end
    end
    walk(type(catalog) == "table" and catalog.lists or {})
    return string.format("%d:%d:%08x_%08x:%d", lists, slots, h1, h2, tokens)
end

return M
