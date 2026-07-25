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

-- Prefer spell_cache hits; on miss fall through to spell_known (stale cache
-- after scribe must not force book=0 into a published snap).
local function probe_book(spellName)
    local okC, SC = pcall(require, 'spell_cache')
    if okC and SC then
        if SC.building and SC.building() and SC.probe_name then
            return SC.probe_name(spellName) == true
        end
        if SC.ready and SC.ready() and SC.is_known and SC.is_known(spellName) then
            return true
        end
    end
    local ok, mod = pcall(require, 'spell_known')
    local known = ok and mod and mod.live and mod.live(spellName) == true
    if known and okC and SC and SC.probe_name then SC.probe_name(spellName) end
    return known == true
end

local function probe_id(spell_id)
    local okC, SC = pcall(require, 'spell_cache')
    if okC and SC then
        if SC.building and SC.building() and SC.probe_id then
            return SC.probe_id(spell_id) == true
        end
        if SC.ready and SC.ready() and SC.is_known and SC.is_known(spell_id) then
            return true
        end
    end
    local ok, mod = pcall(require, 'spell_known')
    local known = ok and mod and mod.live_id and mod.live_id(spell_id) == true
    if known and okC and SC and SC.probe_id then SC.probe_id(spell_id) end
    return known == true
end

local function merge_don_pack_spells(className, out, spell_ids_out)
    local ok, cat = pcall(require, 'catalogs.lazbis')
    if not ok or type(cat) ~= 'table' then return end
    local list = cat.lists and cat.lists.don
    if type(list) ~= 'table' then return end
    local bucket = list.classes and list.classes[class_key(className)]
    if type(bucket) ~= 'table' then return end
    for _, entry in pairs(bucket) do
        if type(entry) == 'table' then
            if type(entry.spell_ids) == 'table' then
                for _, sid in ipairs(entry.spell_ids) do
                    sid = tonumber(sid)
                    if sid and sid > 0 then
                        local known = probe_id(sid)
                        if known then spell_ids_out[sid] = true end
                        local spellName = nil
                        pcall(function()
                            local sp = mq.TLO.Spell(sid)
                            if sp and sp() then spellName = sp.Name() end
                        end)
                        spellName = trim(spellName)
                        if spellName == '' and type(entry.spells) == 'table' then
                            spellName = trim(entry.spells[1])
                        end
                        if spellName ~= '' then
                            local norm = spell_norm(spellName)
                            local prev = out[norm]
                            if not prev then
                                out[norm] = {
                                    name = spellName,
                                    book = known and 1 or 0,
                                    scroll = 0,
                                    spell_id = sid,
                                }
                            elseif known then
                                prev.book = 1
                                prev.spell_id = sid
                            end
                        end
                    end
                end
            end
            if type(entry.spells) == 'table' then
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
end

function M.gather(className)
    className = className or (mq.TLO.Me.Class.Name and mq.TLO.Me.Class.Name()) or ''
    if trim(className) == '' then
        className = (mq.TLO.Me.Class.ShortName and mq.TLO.Me.Class.ShortName()) or ''
    end
    if trim(className) == '' then return {} end

    local out = {}
    local spell_ids_out = {}
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
    merge_don_pack_spells(className, out, spell_ids_out)
    do
        local okDS, DS = pcall(require, 'don_spells')
        if okDS and DS and DS.merge_into_spell_maps then
            DS.merge_into_spell_maps(className, out, spell_ids_out, probe_book, probe_id)
        end
    end
    return out, spell_ids_out
end

-- Known-set signature. Keys on name+book/scroll and known spell IDs so a
-- same-count swap of different spells still invalidates caches.
function M.signature(spellMap, spellIds)
    if type(spellMap) ~= 'table' then return '' end
    local parts = {}
    for norm, row in pairs(spellMap) do
        if type(row) == 'table' then
            local sid = tonumber(row.spell_id) or 0
            parts[#parts + 1] = string.format('%s:%d:%d:%d',
                norm, tonumber(row.book) or 0, tonumber(row.scroll) or 0, sid)
        end
    end
    if type(spellIds) == 'table' then
        for id, v in pairs(spellIds) do
            if v then
                id = tonumber(id) or 0
                if id > 0 then parts[#parts + 1] = 'i' .. tostring(id) end
            end
        end
    end
    table.sort(parts)
    return table.concat(parts, '\31')
end

return M
