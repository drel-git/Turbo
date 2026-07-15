--[[
  Turbo skip journal — batch flush (MQ Next)
  -------------------------------------------
  @version lua/Turbo/skip_append.lua 1.1.2

  Called once at top-level after looting: /lua run Turbo/skip_append "<batch>"

  TurboLoot.mac batch format:
    ~item@reason@itemId~item2@reason2@id2...
  Record = text after each ~ ; fields = split on first two @ (plain substring).

  argv: typically [ "Turbo/skip_append", batchString ] — we concat args[2..n].
  MQ Next tokenizes quoted args on whitespace — reassemble with a SPACE
  separator (1.1.0 fix) so multi-word item names ("Crystallized Marrow")
  don't merge into single-word ("CrystallizedMarrow") during reassembly.
  Orphan " characters from unbalanced quote splits are stripped post-reassembly.
]]

local mq = require('mq')

local function loadSkipMod()
    for _, n in ipairs({ 'Turbo/skip_log', 'turbo/skip_log' }) do
        local ok, m = pcall(require, n)
        if ok and type(m) == 'table' and m.append_event then
            return m
        end
    end
    local base = (mq.TLO.MacroQuest.Path() or ''):gsub('\\', '/')
    for _, s in ipairs({ 'Turbo', 'turbo' }) do
        for _, sub in ipairs({ '/lua/', '/Macros/lua/' }) do
            local p = base .. sub .. s .. '/skip_log.lua'
            for _, v in ipairs({ p, p:gsub('/', '\\') }) do
                local f = loadfile(v)
                if f then
                    local ok, m = pcall(f)
                    if ok and type(m) == 'table' and m.append_event then
                        return m
                    end
                end
            end
        end
    end
    return nil
end

--- Split one record on the first two plain @ (reason can be long; id is rest).
local function split_at_fields(rec)
    local a1 = rec:find('@', 1, true)
    if not a1 then
        return nil
    end
    local a2 = rec:find('@', a1 + 1, true)
    if not a2 then
        return nil
    end
    return rec:sub(1, a1 - 1), rec:sub(a1 + 1, a2 - 1), rec:sub(a2 + 1)
end

--- Primary: records separated by ~, fields name@reason@id (two @ delimiters per record).
--- Legacy: # / ^ / ~|...|...| if primary yields no rows.
local function parse_batch(batch)
    local rows = {}
    if not batch or batch == '' then
        return rows
    end
    batch = tostring(batch):match('^%s*(.-)%s*$') or tostring(batch)
    -- MQ sometimes passes the batch wrapped in an extra pair of quotes; strip one layer.
    while #batch >= 2 and batch:sub(1, 1) == '"' and batch:sub(-1, -1) == '"' do
        batch = batch:sub(2, -2):match('^%s*(.-)%s*$') or batch:sub(2, -2)
    end

    -- Defensive: strip any remaining " characters. Unbalanced quotes can survive
    -- MQ Next argv tokenization and land mid-batch, then leak into id fields
    -- as stray " (e.g., |16986"| or |16986""|). EQ item names and reason codes
    -- never legitimately contain quotes, so unconditional strip is safe here.
    batch = batch:gsub('"', '')

    local function push_row(name, reason, id)
        name = (name and name:match('^%s*(.-)%s*$') or '') or ''
        if name ~= '' then
            rows[#rows + 1] = {
                name = name,
                reason = (reason or ''):match('^%s*(.-)%s*$') or '',
                id = (id or ''):match('^%s*(.-)%s*$') or '',
            }
        end
    end

    for rec in batch:gmatch('~([^~]+)') do
        local name, reason, id = split_at_fields(rec)
        if name then
            push_row(name, reason, id)
        else
            name, reason, id = rec:match('^([^#]*)#([^#]*)#([^#]*)$')
            if name then
                push_row(name, reason, id)
            else
                name, reason, id = rec:match('^([^%^]*)%^([^%^]*)%^([^%^]*)$')
                if name then
                    push_row(name, reason, id)
                end
            end
        end
    end
    if #rows > 0 then
        return rows
    end

    for rec in (batch .. '~|'):gmatch('~|(.-)~|') do
        if rec ~= '' then
            local name, reason, id = rec:match('^([^|]*)|([^|]*)|([^|]*)$')
            if name then
                push_row(name, reason, id)
            end
        end
    end
    return rows
end

local function run_batch(batch, journalIniDir)
    local m = loadSkipMod()
    if not m then
        printf('\ar[turboLoot]\ax skip_append: skip_log.lua not found')
        return
    end

    local rows = parse_batch(batch)
    if #rows == 0 then
        -- 1.1.1: silent no-op for unstructured / empty batches. If the batch
        -- contains NO record markers (~ or @), there was nothing to flush —
        -- likely a spurious re-flush after TurboLoot.mac's PrintSummary +
        -- Cleanup both ran. The 3.8.5 macro guard prevents this upstream;
        -- this is belt-and-suspenders for older macros or edge cases.
        -- If structure was present but parsing still yielded 0 rows, that IS
        -- a real bug — keep the red echo so we see it.
        local b = tostring(batch or '')
        if b:find('~', 1, true) or b:find('@', 1, true) then
            printf('\ar[turboLoot]\ax skip_append: batch parsed 0 rows')
        end
        return
    end

    local src = tostring(mq.TLO.Me.Name() or '')
    local wrote = 0
    local failed = 0
    for _, r in ipairs(rows) do
        local ok = m.append_event(r.name, r.reason, '', r.id, 'NULL', src, journalIniDir, true)
        if ok then
            wrote = wrote + 1
        else
            failed = failed + 1
        end
    end
    if failed > 0 or wrote ~= #rows then
        printf('\ar[turboLoot]\ax skip_append: wrote \ay%d/%d\ax skip row(s) to journal (\ar%d failed\ax)', wrote, #rows, failed)
    else
        printf('\ag[turboLoot]\ax skip_append: wrote \ay%d/%d\ax skip row(s) to journal', wrote, #rows)
    end
end

local export_table = { run = run_batch }

local nargs = select('#', ...)
if nargs == 0 then
    return export_table
end

local args = { ... }
if nargs == 1 then
    local a = args[1]
    if type(a) == 'string' and (a:find('/', 1, true) or a:lower():find('skip_append', 1, true)) then
        return export_table
    end
    run_batch(a or '', nil)
    return
end

local iniDir = nil
local startIdx = 2
if nargs >= 3 then
    local probe = tostring(args[2] or '')
    while #probe >= 2 and probe:sub(1, 1) == '"' and probe:sub(-1, -1) == '"' do
        probe = probe:sub(2, -2):match('^%s*(.-)%s*$') or probe:sub(2, -2)
    end
    local lc = probe:lower()
    if lc:find('config', 1, true) or lc:find('macros', 1, true) or lc:find('..\\', 1, true) or lc:find('../', 1, true) then
        iniDir = probe
        startIdx = 3
    end
end

local parts = {}
for i = startIdx, nargs do
    parts[#parts + 1] = tostring(args[i] or '')
end
-- Separator ' ' (not ''): MQ Next tokenizes quoted /lua run args on whitespace.
-- Concat with '' silently drops inter-word spaces in multi-word item names
-- ('Crystallized Marrow' → 'CrystallizedMarrow'). Space separator restores them.
run_batch(table.concat(parts, ' '), iniDir)
