-- TurboGear/spell_snapshot.lua
-- Lite spell-book slice (66-70 research roster) for peer sync.

local mq = require('mq')

local okCatalog, Catalog = pcall(require, 'research_catalog')
if not okCatalog then Catalog = nil end

local M = {}

local function trim(s)
    return tostring(s or ''):match('^%s*(.-)%s*$') or ''
end

function M.gather(className)
    if not Catalog then return {} end
    className = className or (mq.TLO.Me.Class.ShortName and mq.TLO.Me.Class.ShortName()) or ''
    if trim(className) == '' then return {} end

    local book = Catalog.gather_spell_book(className, Catalog.LEVEL_NUMS)
    local out = {}
    for norm, row in pairs(book or {}) do
        out[norm] = {
            name = row.name or norm,
            book = row.book or 0,
            scroll = row.scroll or 0,
        }
    end
    return out
end

function M.signature(spellMap)
    if type(spellMap) ~= 'table' then return '' end
    local parts = {}
    for norm, row in pairs(spellMap) do
        if type(row) == 'table' then
            parts[#parts + 1] = string.format('%s:%d:%d', norm, tonumber(row.book) or 0, tonumber(row.scroll) or 0)
        end
    end
    table.sort(parts)
    return table.concat(parts, '\31')
end

return M
