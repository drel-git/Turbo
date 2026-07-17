-- TurboGear/spell_snapshot.lua
-- Lite spell-book slice (66-70 research roster + DoN BiS pack spells) for peer sync.

local mq = require('mq')

local okCatalog, Catalog = pcall(require, 'research_catalog')
if not okCatalog then Catalog = nil end

local M = {}

local function trim(s)
    return tostring(s or ''):match('^%s*(.-)%s*$') or ''
end

local function class_key(className)
    className = trim(className)
    if className == 'Shadowknight' then return 'Shadow Knight' end
    return className
end

local function spell_norm(name)
    name = trim(name):lower()
    -- Match bis.lua / announce norms so snap keys align with ownership checks.
    name = name:gsub("`", "'"):gsub("\226\128\152", "'"):gsub("\226\128\153", "'")
    return name
end

local SpellKnown = nil
local function probe_book(spellName)
    if not SpellKnown then
        local ok, mod = pcall(require, 'spell_known')
        SpellKnown = ok and mod or nil
    end
    if SpellKnown and SpellKnown.live then
        return SpellKnown.live(spellName) == true
    end
    local inBook = false
    pcall(function()
        if (tonumber(mq.TLO.Me.Book(spellName)()) or 0) > 0
            or (tonumber(mq.TLO.Me.CombatAbility(spellName)()) or 0) > 0 then
            inBook = true
        end
    end)
    return inBook
end

local function merge_don_pack_spells(className, out)
    local ok, cat = pcall(require, 'catalogs.lazbis')
    if not ok or type(cat) ~= 'table' then return end
    local list = cat.lists and cat.lists.don
    if type(list) ~= 'table' then return end
    local bucket = list.classes and list.classes[class_key(className)]
    if type(bucket) ~= 'table' then return end
    for _, entry in pairs(bucket) do
        if type(entry) == 'table' and type(entry.spells) == 'table' then
            for _, spellName in ipairs(entry.spells) do
                spellName = trim(spellName)
                if spellName ~= '' then
                    local norm = spell_norm(spellName)
                    local known = probe_book(spellName)
                    local prev = out[norm]
                    if not prev then
                        out[norm] = {
                            name = spellName,
                            book = known and 1 or 0,
                            scroll = 0,
                        }
                    elseif known then
                        prev.book = 1
                    end
                end
            end
        end
    end
end

function M.gather(className)
    className = className or (mq.TLO.Me.Class.Name and mq.TLO.Me.Class.Name()) or ''
    if trim(className) == '' then
        className = (mq.TLO.Me.Class.ShortName and mq.TLO.Me.Class.ShortName()) or ''
    end
    if trim(className) == '' then return {} end

    local out = {}
    if Catalog then
        local book = Catalog.gather_spell_book(className, Catalog.LEVEL_NUMS)
        for norm, row in pairs(book or {}) do
            out[norm] = {
                name = row.name or norm,
                book = row.book or 0,
                scroll = row.scroll or 0,
            }
        end
    end
    merge_don_pack_spells(className, out)
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
