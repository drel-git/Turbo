--[[
  TurboGear/research_catalog.lua
  Spell roster + recipe merge (bundled references/spells.lua + data/researchlearn.ini).

  External overrides still work: Config/Macros researchlearn.ini, lazbis/spells.lua.
]]

local mq = require('mq')

local M = {
    FORMAT = 'ResearchLearn want-list v1',
    INI_NAME = 'researchlearn.ini',
}

local function mq_root()
    return (tostring(mq.TLO.MacroQuest.Path() or ''):gsub('^%s*(.-)%s*$', '%1')):gsub('[\\/]+$', '')
end

function M.turbogear_root()
    local root = mq_root()
    if root == '' then return '' end
    return root .. '\\lua\\turbogear'
end

M.LEVEL_NUMS = { 70, 69, 68, 67, 66 }

M.CLASS_NORMALIZE = {
    brd = 'bard', bst = 'beastlord', ber = 'berserker', clr = 'cleric',
    dru = 'druid', enc = 'enchanter', mag = 'magician', mnk = 'monk',
    nec = 'necromancer', pal = 'paladin', rng = 'ranger', rog = 'rogue',
    shd = 'shadowknight', shm = 'shaman', wiz = 'wizard', war = 'warrior',
    bard = 'bard', beastlord = 'beastlord', berserker = 'berserker', cleric = 'cleric',
    druid = 'druid', enchanter = 'enchanter', magician = 'magician', monk = 'monk',
    necromancer = 'necromancer', paladin = 'paladin', ranger = 'ranger', rogue = 'rogue',
    shadowknight = 'shadowknight', shaman = 'shaman', wizard = 'wizard', warrior = 'warrior',
}

M.CLASS_TO_LAZ = {
    cleric = 'Cleric', beastlord = 'Beastlord', magician = 'Magician', bard = 'Bard',
    druid = 'Druid', enchanter = 'Enchanter', necromancer = 'Necromancer', ranger = 'Ranger',
    shadowknight = 'Shadow Knight', shaman = 'Shaman', wizard = 'Wizard', paladin = 'Paladin',
    berserker = 'Berserker', monk = 'Monk', rogue = 'Rogue', warrior = 'Warrior',
}

M.DEFAULT_CLASSES = {
    'cleric', 'beastlord', 'magician', 'bard', 'druid', 'enchanter',
    'necromancer', 'ranger', 'shadowknight', 'shaman', 'wizard', 'paladin',
    'berserker', 'monk', 'rogue', 'warrior',
}

local cache = {
    iniPath = nil,
    iniSections = nil,
    spellsConfig = nil,
    spellsLoaded = false,
    wantFiles = nil,
    wantFilesAt = 0,
}

local function trim(s)
    return (tostring(s or ''):gsub('^%s*(.-)%s*$', '%1'))
end

function M.normalize_class(className)
    local key = trim(className):lower():gsub('%s+', '')
    return M.CLASS_NORMALIZE[key] or key
end

function M.normalize_name(name)
    return trim(name):lower():gsub('^spell:%s*', ''):gsub('^skill:%s*', ''):gsub('^tome of%s*', '')
end

local SPELL_LEARNED_ALIASES = {
    ['cloud of indifference'] = { 'Suppression Field', 'Supression Field' },
    ['circle of nettles'] = { 'Legacy of Nettles' },
}

local function base_product_norm(raw)
    return M.normalize_name(tostring(raw or ''):gsub('^Spell:%s*', ''):gsub('^Skill:%s*', ''):gsub('^Tome of%s*', ''):gsub('%s+Rk%.%s*II$', ''))
end

function M.learned_alias_names(name)
    local norm = base_product_norm(name)
    local out = {}
    for _, alias in ipairs(SPELL_LEARNED_ALIASES[norm] or {}) do
        out[#out + 1] = alias
    end
    return out
end

function M.learned_alias_norms(name)
    local out = {}
    for _, alias in ipairs(M.learned_alias_names(name)) do
        out[#out + 1] = base_product_norm(alias)
    end
    return out
end

local function product_norm_candidates(name)
    local seen, out = {}, {}
    local function add(norm)
        norm = tostring(norm or '')
        if norm ~= '' and not seen[norm] then
            seen[norm] = true
            out[#out + 1] = norm
        end
    end
    add(M.product_norm(name))
    add(base_product_norm(name))
    for _, alias_norm in ipairs(M.learned_alias_norms(name)) do add(alias_norm) end
    return out
end

function M.product_norm(raw)
    local norm = base_product_norm(raw)
    local aliases = SPELL_LEARNED_ALIASES[norm]
    if aliases and aliases[1] then return base_product_norm(aliases[1]) end
    return norm
end

function M.class_to_laz(classKey)
    return M.CLASS_TO_LAZ[M.normalize_class(classKey)]
end

local function scroll_label(name)
    name = trim(name)
    if name:lower():find('^spell:') then return name end
    return 'Spell: ' .. name
end

function M.file_exists(path)
    local fh = io.open(path, 'r')
    if fh then fh:close(); return true end
    return false
end

function M.resolve_config_dir()
    local mqPath = trim(mq.TLO.MacroQuest.Path() or ''):gsub('[\\/]+$', '')
    if mqPath == '' then return nil end
    return mqPath .. '\\Config'
end

function M.parse_ini_file(iniPath)
    local sections = {}
    if not iniPath or not M.file_exists(iniPath) then return sections end
    local fh = io.open(iniPath, 'r')
    if not fh then return sections end
    local current = nil
    for line in fh:lines() do
        local sec = line:match('^%[(.-)%]$')
        if sec then
            current = trim(sec)
            sections[current] = sections[current] or {}
        elseif current then
            local key, val = line:match('^([^=]+)=(.*)$')
            if key then sections[current][trim(key)] = trim(val) end
        end
    end
    fh:close()
    return sections
end

function M.resolve_ini_path()
    local mqPath = mq_root()
    if mqPath == '' then return nil end
    local tg = M.turbogear_root()
    local candidates = {
        mqPath .. '\\Macros\\' .. M.INI_NAME,
        mqPath .. '\\Config\\' .. M.INI_NAME,
        mqPath .. '\\lua\\' .. M.INI_NAME,
    }
    if tg ~= '' then
        candidates[#candidates + 1] = tg .. '\\data\\' .. M.INI_NAME
    end
    local bestPath, bestScore = nil, -1
    for _, p in ipairs(candidates) do
        if M.file_exists(p) then
            local sections = M.parse_ini_file(p)
            local score = 0
            for secName, sec in pairs(sections) do
                if secName:match('_%d+$') then
                    score = score + (tonumber(sec.SpellCount) or 0)
                end
            end
            if score > bestScore then
                bestScore = score
                bestPath = p
            end
        end
    end
    if bestPath then return bestPath end
    return candidates[1]
end

function M.load_ini(force)
    local path = M.resolve_ini_path()
    if not path then
        cache.iniPath = nil
        cache.iniSections = {}
        return cache.iniSections, nil
    end
    if force or cache.iniPath ~= path or not cache.iniSections then
        cache.iniPath = path
        cache.iniSections = M.parse_ini_file(path)
    end
    return cache.iniSections, cache.iniPath
end

function M.load_spells_config(force)
    if not force and cache.spellsLoaded then return cache.spellsConfig end
    cache.spellsLoaded = true

    local mqPath = mq_root()
    local paths = {
        mqPath .. '\\lua\\lazbis\\spells.lua',
        mqPath .. '\\lazbis\\spells.lua',
    }
    for _, p in ipairs(paths) do
        local chunk = loadfile(p)
        if chunk then
            local ok, data = pcall(chunk)
            if ok and type(data) == 'table' then
                cache.spellsConfig = data
                return data
            end
        end
    end

    local okRef, bundled = pcall(require, 'references.spells')
    if okRef and type(bundled) == 'table' then
        cache.spellsConfig = bundled
        return bundled
    end

    local tg = M.turbogear_root()
    if tg ~= '' then
        local chunk = loadfile(tg .. '\\references\\spells.lua')
        if chunk then
            local ok, data = pcall(chunk)
            if ok and type(data) == 'table' then
                cache.spellsConfig = data
                return data
            end
        end
    end
    cache.spellsConfig = nil
    return nil
end

function M.classify_source(source)
    local s = trim(source):lower()
    if s:find('random drop', 1, true) then return 'drop', 'Drop' end
    if s:find('anguish', 1, true) then return 'anguish', 'Anguish' end
    if s:find('pok library', 1, true) or s:find('library', 1, true) then return 'library', 'PoK Library' end
    if s:find('quest', 1, true) then return 'quest', 'Quest' end
    if s:find('research', 1, true) then return 'research', trim(source) end
    if s == '???' or s == '' then return 'other', source or '?' end
    return 'other', trim(source)
end

function M.levels_for_selection(levelStr)
    if type(levelStr) == 'table' then return levelStr end
    levelStr = tostring(levelStr or 'all'):lower()
    if levelStr == 'all' then return M.LEVEL_NUMS end
    local n = tonumber(levelStr)
    if n then return { n } end
    return M.LEVEL_NUMS
end

function M.ini_recipes_for_class(className)
    M.load_ini(false)
    local out = {}
    local sections = cache.iniSections or {}
    className = M.normalize_class(className)
    for secName, sec in pairs(sections) do
        local cls, lv = secName:match('^(.+)_(%d+)$')
        if cls and M.normalize_class(cls) == className then
            local spellCount = tonumber(sec.SpellCount) or 0
            for sn = 1, spellCount do
                local raw = sec['Spell' .. sn]
                if raw and raw ~= '' then
                    local display = raw:gsub('^Spell:%s*', ''):gsub('^Skill:%s*', ''):gsub('^Tome of%s*', '')
                    local ings = {}
                    for ing = 1, 20 do
                        local iname = sec['Spell' .. sn .. '_Ingredient' .. ing]
                        if iname and iname ~= '' then ings[#ings + 1] = iname end
                    end
                    out[#out + 1] = {
                        section = secName,
                        level = tonumber(lv),
                        spellNum = sn,
                        iniRaw = raw,
                        name = display,
                        norm = M.product_norm(raw),
                        ingredients = ings,
                    }
                end
            end
        end
    end
    table.sort(out, function(a, b)
        if a.level == b.level then return a.spellNum < b.spellNum end
        return (a.level or 0) > (b.level or 0)
    end)
    return out
end

function M.find_ini_recipe(className, spellName)
    className = M.normalize_class(className)
    local norm = M.normalize_name(spellName)
    local candidates = { norm, M.product_norm(spellName) }
    for _, alias_norm in ipairs(M.learned_alias_norms(spellName)) do
        candidates[#candidates + 1] = alias_norm
    end
    if not norm:find('^tome of ') then
        candidates[#candidates + 1] = M.normalize_name('Tome of ' .. spellName)
        candidates[#candidates + 1] = M.normalize_name('Tome of ' .. spellName .. ' Rk. II')
        candidates[#candidates + 1] = M.normalize_name('Skill: ' .. spellName)
    end
    for _, rec in ipairs(M.ini_recipes_for_class(className)) do
        for _, c in ipairs(candidates) do
            if rec.norm == c or M.product_norm(rec.iniRaw) == c then return rec end
        end
    end
    for _, rec in ipairs(M.ini_recipes_for_class(className)) do
        for _, c in ipairs(candidates) do
            if rec.norm:find(c, 1, true) or c:find(rec.norm, 1, true) then return rec end
        end
    end
    return nil
end

function M.spell_inventory_info(displayName, iniRaw, spellBook, allowLive)
    displayName = trim(displayName)
    local norm = M.product_norm(displayName)
    local norm_candidates = product_norm_candidates(displayName)
    if type(spellBook) == 'table' then
        if spellBook._partial then
            if spellBook._missing then
                for _, c in ipairs(norm_candidates) do
                    if spellBook._missing[c] then
                        return { inBook = false, scroll = 0, partial = true }
                    end
                end
            end
            return { inBook = false, scroll = 0, noData = true, partial = true }
        end
        local row = nil
        for _, c in ipairs(norm_candidates) do
            row = spellBook[c]
            if row then break end
        end
        if row then
            return {
                inBook = row.book and true or false,
                scroll = tonumber(row.scroll) or 0,
            }
        end
        if allowLive == false then
            return { inBook = false, scroll = 0, noData = true }
        end
        return { inBook = false, scroll = 0 }
    end
    if allowLive == false then
        return { inBook = false, scroll = 0, noData = true }
    end

    local variants = { displayName, scroll_label(displayName) }
    if iniRaw and trim(iniRaw) ~= '' then
        variants[#variants + 1] = trim(iniRaw)
    end
    for _, alias in ipairs(M.learned_alias_names(displayName)) do
        variants[#variants + 1] = alias
        variants[#variants + 1] = scroll_label(alias)
    end
    local inBook = false
    local SpellKnown = nil
    pcall(function()
        local ok, mod = pcall(require, 'spell_known')
        if ok then SpellKnown = mod end
    end)
    pcall(function()
        for _, variant in ipairs(variants) do
            if SpellKnown and SpellKnown.live and SpellKnown.live(variant) then
                inBook = true
                break
            end
            if (tonumber(mq.TLO.Me.Book(variant)()) or 0) > 0
                or (tonumber(mq.TLO.Me.CombatAbility(variant)()) or 0) > 0 then
                inBook = true
                break
            end
        end
    end)
    local scroll = 0
    pcall(function()
        for _, variant in ipairs(variants) do
            scroll = math.max(scroll, mq.TLO.FindItemCount('=' .. variant)() or 0)
            scroll = math.max(scroll, mq.TLO.FindItemBankCount('=' .. variant)() or 0)
        end
    end)
    return { inBook = inBook, scroll = scroll }
end

function M.spell_owned_count(info, runMode)
    runMode = runMode or 'roster'
    if runMode == 'import' or runMode == 'spell' then
        return info.scroll
    end
    return info.scroll + (info.inBook and 1 or 0)
end

function M.spell_plan_from_inventory(info, qty, runMode)
    qty = math.max(1, math.floor(tonumber(qty) or 1))
    local owned = M.spell_owned_count(info, runMode)
    local need = math.max(0, qty - owned)
    return owned, need, M.format_have_label(info, qty, runMode)
end

function M.format_have_label(info, qty, runMode)
    runMode = runMode or 'roster'
    if info.noData then return '?' end
    if runMode == 'import' or runMode == 'spell' then
        local scr = string.format('%d/%d scr', info.scroll, qty)
        if info.inBook then return 'Scribed, ' .. scr end
        return scr
    end
    if info.inBook and info.scroll == 0 then return 'Scribed' end
    if info.inBook and info.scroll > 0 then return string.format('Scribed + %d scr', info.scroll) end
    if info.scroll > 0 then return string.format('%d/%d scr', info.scroll, qty) end
    return string.format('0/%d', qty)
end

function M.item_count(name)
    local n = 0
    pcall(function()
        n = (mq.TLO.FindItemCount('=' .. name)() or 0) + (mq.TLO.FindItemBankCount('=' .. name)() or 0)
    end)
    return n
end

function M.gather_spell_book(classKey, levels)
    classKey = M.normalize_class(classKey)
    M.load_ini(false)
    M.load_spells_config(false)
    levels = levels or M.LEVEL_NUMS

    local norms = {}
    local lazClass = M.class_to_laz(classKey)
    if cache.spellsConfig and lazClass and cache.spellsConfig[lazClass] then
        for _, lv in ipairs(levels) do
            for _, entry in ipairs(cache.spellsConfig[lazClass][lv] or {}) do
                local n = entry:match('^([^|]+)')
                if n then norms[M.product_norm(n)] = trim(n) end
            end
        end
    end
    for _, rec in ipairs(M.ini_recipes_for_class(classKey)) do
        local include = false
        for _, lv in ipairs(levels) do
            if rec.level == lv then include = true; break end
        end
        if include then norms[rec.norm] = rec.name end
    end

    local out = {}
    for norm, display in pairs(norms) do
        local rec = M.find_ini_recipe(classKey, display)
        local inv = M.spell_inventory_info(display, rec and rec.iniRaw, nil)
        out[norm] = {
            name = display,
            norm = norm,
            book = inv.inBook and 1 or 0,
            scroll = inv.scroll,
        }
    end
    return out
end

function M.spell_book_from_snap(snap)
    if type(snap) ~= 'table' or type(snap.spells) ~= 'table' then return nil end
    local out = {}
    for k, v in pairs(snap.spells) do
        if k == '_partial' then
            out._partial = v
        elseif k == '_missing' and type(v) == 'table' then
            out._missing = v
        elseif type(v) == 'table' then
            out[M.product_norm(k)] = {
                book = (v.book and tonumber(v.book) or 0) > 0,
                scroll = tonumber(v.scroll) or 0,
            }
        end
    end
    if snap.spells._partial then
        out._partial = true
        out._missing = snap.spells._missing or out._missing
    end
    if not next(out) and not out._partial then return nil end
    return out
end

function M.spell_book_from_want_missing(entries)
    local book = { _partial = true, _missing = {} }
    for _, entry in ipairs(entries or {}) do
        local norm = M.product_norm(entry.name)
        if norm ~= '' then
            book._missing[norm] = true
            book[norm] = { book = false, scroll = 0 }
        end
    end
    if not next(book._missing) then return nil end
    return book
end

local function resolve_peer_spell_book(snap, useWantFiles)
    if type(snap) ~= 'table' then return nil end
    local book = M.spell_book_from_snap(snap)
    if book then return book end
    if useWantFiles ~= true then return nil end
    local charName = trim(snap.name or '')
    if charName == '' then return nil end
    local wf = M.find_want_file_for_character(charName)
    if wf and wf.entries and #wf.entries > 0 then
        return M.spell_book_from_want_missing(wf.entries)
    end
    return nil
end

local function laz_display_name(lazClass, level, norm)
    for _, entry in ipairs((cache.spellsConfig[lazClass] or {})[level] or {}) do
        local n = entry:match('^([^|]+)')
        if M.normalize_name(n or '') == norm then return trim(n) end
    end
    return norm
end

function M.build_manifest(opts)
    opts = opts or {}
    M.load_ini(false)
    M.load_spells_config(false)

    local qty = math.max(1, math.floor(tonumber(opts.qty) or 1))
    local hideNonResearch = opts.hideNonResearch == true
    local hideOwned = opts.hideOwned == true
    local uiOnly = opts.uiOnly == true
    local runMode = opts.runMode or 'roster'
    local classKey = M.normalize_class(opts.class or mq.TLO.Me.Class.ShortName() or '')
    local levels = M.levels_for_selection(opts.levels or 'all')
    local liveInventory = opts.liveInventory == true
    local spellBook = opts.spellBook
    local isSelf = opts.sourceKey == '__self__'
    if spellBook == nil and opts.snap then
        if liveInventory then
            spellBook = nil
        elseif isSelf then
            spellBook = M.spell_book_from_snap(opts.snap)
            if spellBook == nil then
                liveInventory = opts.liveInventory == true
            else
                liveInventory = false
            end
        else
            spellBook = resolve_peer_spell_book(opts.snap, opts.useWantFiles)
            liveInventory = false
            if spellBook == nil then
                spellBook = {}
            end
        end
    end

    local plan = {
        rows = {},
        ingredients = {},
        summary = { total = 0, craftable = 0, satisfied = 0, missing = 0, reference = 0 },
        hasSpellsLua = cache.spellsConfig ~= nil,
        iniPath = cache.iniPath,
        class = classKey,
        warns = {},
    }

    if not cache.iniPath or not M.file_exists(cache.iniPath) then
        plan.warns[#plan.warns + 1] = 'researchlearn.ini not found (bundled copy: turbogear/data/).'
    end
    if not plan.hasSpellsLua then
        plan.warns[#plan.warns + 1] = 'Spell roster not found (bundled copy: turbogear/references/spells.lua).'
    end

    local lazClass = M.class_to_laz(classKey)
    local lazByNorm = {}
    if cache.spellsConfig and lazClass and cache.spellsConfig[lazClass] then
        for _, lv in ipairs(levels) do
            for _, entry in ipairs(cache.spellsConfig[lazClass][lv] or {}) do
                local parts = {}
                for p in entry:gmatch('[^|]+') do parts[#parts + 1] = p end
                local lazName = parts[1] or entry
                local kind, src = M.classify_source(parts[2] or '')
                lazByNorm[M.product_norm(lazName)] = { kind = kind, source = src, level = lv }
            end
        end
    end

    local iniByNorm = {}
    for _, rec in ipairs(M.ini_recipes_for_class(classKey)) do
        local include = false
        for _, lv in ipairs(levels) do
            if rec.level == lv then include = true; break end
        end
        if include then iniByNorm[rec.norm] = rec end
    end

    local ingTotals = {}
    local seenNorm = {}

    local function is_non_research_kind(kind)
        return kind == 'drop' or kind == 'anguish' or kind == 'library' or kind == 'quest' or kind == 'other'
    end

    local function push_row(row)
        if hideNonResearch and is_non_research_kind(row.sourceKind) then
            return
        end
        if hideOwned and row.have >= qty then
            return
        end
        plan.rows[#plan.rows + 1] = row
        plan.summary.total = plan.summary.total + 1
        if row.status == 'satisfied' then
            plan.summary.satisfied = plan.summary.satisfied + 1
        elseif row.status == 'craftable' and row.need > 0 then
            plan.summary.craftable = plan.summary.craftable + 1
            plan.summary.missing = plan.summary.missing + 1
        elseif row.status == 'drop' or row.status == 'anguish' or row.status == 'library' or row.status == 'quest' then
            plan.summary.reference = plan.summary.reference + 1
        elseif row.need > 0 then
            plan.summary.missing = plan.summary.missing + 1
        end
    end

    if next(lazByNorm) then
        for norm, laz in pairs(lazByNorm) do
            seenNorm[norm] = true
            local rec = iniByNorm[norm]
            local display = lazClass and laz_display_name(lazClass, laz.level, norm) or norm
            local inv = M.spell_inventory_info(display, rec and rec.iniRaw, spellBook, liveInventory)
            local have, need, haveLabel = M.spell_plan_from_inventory(inv, qty, runMode)
            local status = 'other'
            if inv.noData then
                need = 0
                status = 'unknown'
            elseif have >= qty then
                status = 'satisfied'
            elseif laz.kind == 'drop' then
                status = 'drop'
            elseif laz.kind == 'anguish' then
                status = 'anguish'
            elseif laz.kind == 'library' then
                status = 'library'
            elseif laz.kind == 'quest' then
                status = 'quest'
            elseif rec then
                status = 'craftable'
            else
                status = 'noRecipe'
            end
            if rec and need > 0 and laz.kind ~= 'drop' and laz.kind ~= 'anguish' and laz.kind ~= 'library' and laz.kind ~= 'quest' then
                for _, ingName in ipairs(rec.ingredients) do
                    ingTotals[ingName] = (ingTotals[ingName] or 0) + need
                end
            end
            push_row({
                level = laz.level,
                name = display,
                norm = norm,
                source = laz.source,
                sourceKind = laz.kind,
                nonResearch = is_non_research_kind(laz.kind),
                inIni = rec ~= nil,
                inBook = inv.inBook,
                scrollCount = inv.scroll,
                noData = inv.noData == true,
                partial = inv.partial == true,
                have = have,
                haveLabel = haveLabel,
                need = need,
                status = status,
                recipe = rec,
            })
        end
    end

    for norm, rec in pairs(iniByNorm) do
        if not seenNorm[norm] then
            local inv = M.spell_inventory_info(rec.name, rec.iniRaw, spellBook, liveInventory)
            local have, need, haveLabel = M.spell_plan_from_inventory(inv, qty, runMode)
            local status = have >= qty and 'satisfied' or 'craftable'
            if inv.noData then
                need = 0
                status = 'unknown'
            end
            if need > 0 then
                for _, ingName in ipairs(rec.ingredients) do
                    ingTotals[ingName] = (ingTotals[ingName] or 0) + need
                end
            end
            push_row({
                level = rec.level,
                name = rec.name,
                norm = norm,
                source = 'INI only',
                sourceKind = 'research',
                inIni = true,
                inBook = inv.inBook,
                scrollCount = inv.scroll,
                noData = inv.noData == true,
                partial = inv.partial == true,
                have = have,
                haveLabel = haveLabel,
                need = need,
                status = status,
                recipe = rec,
            })
        end
    end

    table.sort(plan.rows, function(a, b)
        if a.level == b.level then return (a.name or '') < (b.name or '') end
        return (a.level or 0) > (b.level or 0)
    end)

    if not uiOnly then
        for ingName, need in pairs(ingTotals) do
            local have = M.item_count(ingName)
            plan.ingredients[#plan.ingredients + 1] = {
                name = ingName,
                need = need,
                have = have,
                short = math.max(0, need - have),
            }
        end
        table.sort(plan.ingredients, function(a, b)
            if a.short == b.short then return a.name < b.name end
            return a.short > b.short
        end)
    end

    return plan
end

function M.missing_export_rows(opts)
    opts = opts or {}
    opts.hideNonResearch = true
    opts.hideOwned = true
    opts.runMode = opts.runMode or 'roster'
    local plan = M.build_manifest(opts)
    local out = {}
    for _, row in ipairs(plan.rows) do
        if row.inIni and row.need and row.need > 0 and row.sourceKind == 'research' and not row.noData then
            out[#out + 1] = row
        end
    end
    return out, plan
end

function M.export_path(character)
    local dir = M.resolve_config_dir()
    if not dir then return '' end
    character = tostring(character or mq.TLO.Me.CleanName() or 'unknown'):gsub('[^%w_%-]', '_')
    return dir .. '\\ResearchLearn_want_' .. character .. '.txt'
end

function M.open_config_dir()
    local dir = M.resolve_config_dir()
    if not dir or dir == '' then return false, 'MacroQuest Config folder not found.' end
    local okShell, ShellOpen = pcall(require, 'Turbo.shell_open')
    if okShell and ShellOpen and ShellOpen.shellOpenFolder then
        return ShellOpen.shellOpenFolder(dir)
    end
    if package.config:sub(1, 1) ~= '\\' then
        os.execute(string.format('xdg-open "%s"', dir:gsub('"', '')))
        return true
    end
    local safe = dir:gsub('"', '')
    local okFfi, ffi = pcall(require, 'ffi')
    if okFfi and ffi then
        if not _G.TurboGearExportShellExecuteCdef then
            pcall(ffi.cdef, [[
                void* ShellExecuteA(void* hwnd, const char* lpOperation, const char* lpFile, const char* lpParameters, const char* lpDirectory, int nShowCmd);
            ]])
            _G.TurboGearExportShellExecuteCdef = true
        end
        local ok = pcall(function()
            if not _G.TurboGearExportShell32 then
                _G.TurboGearExportShell32 = ffi.load('shell32')
            end
            _G.TurboGearExportShell32.ShellExecuteA(nil, 'open', safe, nil, nil, 1)
        end)
        if ok then return true end
    end
    os.execute('explorer.exe "' .. safe .. '"')
    return true
end

function M.write_want_file(path, rows, meta)
    meta = meta or {}
    local copies = math.max(1, math.floor(tonumber(meta.copies) or 1))
    local fh = io.open(path, 'w')
    if not fh then return false, 'Could not write: ' .. tostring(path) end
    fh:write('# ' .. M.FORMAT .. '\n')
    fh:write('# character=' .. tostring(meta.character or '') .. '\n')
    fh:write('# class=' .. tostring(meta.class or '') .. '\n')
    fh:write('# exported=' .. tostring(meta.exported or os.date('%Y-%m-%d %H:%M')) .. '\n')
    if meta.source then fh:write('# source=' .. tostring(meta.source) .. '\n') end
    fh:write('copies=' .. copies .. '\n')
    fh:write('---\n')
    for _, row in ipairs(rows or {}) do
        fh:write(string.format('%s|%d|%s|%d\n',
            M.normalize_class(row.class or meta.class or ''),
            tonumber(row.level) or 0,
            tostring(row.name or ''),
            math.max(1, math.floor(tonumber(row.copies) or copies))))
    end
    fh:close()
    return true
end

function M.export_missing(opts)
    opts = opts or {}
    local classKey = M.normalize_class(opts.class or mq.TLO.Me.Class.ShortName() or '')
    local character = opts.character or mq.TLO.Me.CleanName() or 'unknown'
    local copies = math.max(1, math.floor(tonumber(opts.copies) or 1))
    local rows, plan = M.missing_export_rows(opts)
    local exportRows = {}
    for _, row in ipairs(rows) do
        exportRows[#exportRows + 1] = {
            class = classKey,
            level = row.level,
            name = row.name,
            copies = copies,
        }
    end
    local path = opts.path or M.export_path(character)
    local ok, err = M.write_want_file(path, exportRows, {
        character = character,
        class = classKey,
        copies = copies,
        exported = os.date('%Y-%m-%d %H:%M'),
        source = opts.source or 'TurboGear',
    })
    if not ok then return nil, 0, err end
    M.invalidate_want_cache()
    return path, #exportRows, plan
end

function M.parse_import_file(path)
    local entries = {}
    local meta = { copies = 1, class = '', character = '', exported = '' }
    if not path or path == '' or not M.file_exists(path) then return entries, meta end
    local fh = io.open(path, 'r')
    if not fh then return entries, meta end
    for line in fh:lines() do
        line = trim(line)
        if line == '' or line:sub(1, 1) == '#' then
            local k, v = line:match('^#%s*([^=]+)=(.+)$')
            if k and v then
                k = trim(k):lower()
                if k == 'class' then meta.class = M.normalize_class(v)
                elseif k == 'character' then meta.character = trim(v)
                elseif k == 'exported' then meta.exported = trim(v)
                elseif k == 'copies' then meta.copies = tonumber(v) or meta.copies end
            end
        elseif line == '---' then
        elseif line:match('^copies=%d+') then
            meta.copies = tonumber(line:match('(%d+)')) or meta.copies
        else
            local parts = {}
            for p in line:gmatch('[^|]+') do parts[#parts + 1] = trim(p) end
            local cls, level, name, copies = meta.class, nil, nil, meta.copies
            if #parts == 1 then
                name = parts[1]
            elseif #parts == 2 then
                if tonumber(parts[1]) then level = tonumber(parts[1]); name = parts[2]
                elseif tonumber(parts[2]) then name = parts[1]; copies = tonumber(parts[2])
                else cls = M.normalize_class(parts[1]); name = parts[2] end
            elseif #parts >= 3 then
                cls = M.normalize_class(parts[1])
                level = tonumber(parts[2])
                name = parts[3]
                if parts[4] then copies = tonumber(parts[4]) or copies end
            end
            if name and name ~= '' then
                entries[#entries + 1] = {
                    class = cls,
                    level = level,
                    name = name,
                    copies = math.max(1, math.floor(tonumber(copies) or meta.copies or 1)),
                }
            end
        end
    end
    fh:close()
    return entries, meta
end

function M.invalidate_want_cache()
    cache.wantFiles = nil
    cache.wantFilesAt = 0
end

function M.scan_want_files()
    if cache.wantFiles then return cache.wantFiles end
    local now = os.clock()
    local dir = M.resolve_config_dir()
    local files = {}
    if not dir then return files end
    local ok, lfs = pcall(require, 'lfs')
    local names = nil
    if ok and lfs and lfs.dir then
        names = {}
        for entry in lfs.dir(dir) do
            if entry ~= '.' and entry ~= '..' and entry:match('^ResearchLearn_want_.+%.txt$') then
                names[#names + 1] = entry
            end
        end
    end
    if not names then
        local handle = io.popen(string.format('dir /b "%s\\ResearchLearn_want_*.txt" 2>nul', dir))
        names = {}
        if handle then
            for fname in handle:lines() do
                fname = trim(fname)
                if fname ~= '' then names[#names + 1] = fname end
            end
            handle:close()
        end
    end
    for _, fname in ipairs(names or {}) do
        local path = dir .. '\\' .. fname
        local entries, meta = M.parse_import_file(path)
        files[#files + 1] = {
            path = path,
            fname = fname,
            meta = meta,
            spellCount = #entries,
            entries = entries,
        }
    end
    table.sort(files, function(a, b)
        return (a.meta.exported or a.fname) > (b.meta.exported or b.fname)
    end)
    cache.wantFiles = files
    cache.wantFilesAt = now
    return files
end

function M.find_want_file_for_character(charName)
    charName = trim(charName):lower()
    if charName == '' then return nil end
    for _, f in ipairs(M.scan_want_files()) do
        local metaChar = trim(f.meta.character or ''):lower()
        if metaChar ~= '' and metaChar == charName then return f end
        local from_fname = f.fname and f.fname:match('^ResearchLearn_want_(.+)%.txt$')
        if from_fname and trim(from_fname):lower() == charName then return f end
    end
    return nil
end

function M.status_color(row)
    if not row then return 0.6, 0.6, 0.6, 1 end
    if row.status == 'satisfied' then return 0.35, 0.85, 0.45, 1 end
    if row.status == 'craftable' and row.need > 0 then return 0.95, 0.45, 0.35, 1 end
    if row.status == 'drop' or row.status == 'anguish' or row.status == 'library' or row.status == 'quest' then
        return 0.55, 0.55, 0.58, 1
    end
    return 0.85, 0.65, 0.25, 1
end

return M
