--[[
  Turbo Skip Tracker
  ------------------
  @version lua/Turbo/skip_tracker.lua 1.3.1

  Loaded once by init.lua at GUI startup. Owns the in-memory dedup table,
  reads/tails the journal, persists applied/dismissed state, and provides
  the API for rule application and undo.

  Performance targets:
    - Initial load of 10K journal lines: < 50ms
    - Tail check (every 2s): < 1ms when no new data
    - pending_count(): cached integer, zero cost per frame
    - apply_rule(): < 20ms (INI write + state serialize)
    - Multi-row Review: GUI wraps persist_batch_begin/end → one state serialize

  Usage from init.lua:
    local tracker = require('Turbo/skip_tracker')
    tracker.init(writeIniKeyFn, readIniKeyFn, getIniPathFn)
    -- per frame (throttled to every ~2s):
    tracker.poll()
    -- footer chip:
    local n = tracker.pending_count()
    -- rule buttons:
    tracker.apply_rule('Silver Ring', 'SELL')
    tracker.persist_batch_begin()  -- skip Review: bulk apply/dismiss → one flush
    -- ...many apply_rule / dismiss...
    tracker.persist_batch_end()
    tracker.undo_last()
    -- data for table rendering:
    local items = tracker.get_pending()   -- sorted by count desc
    local applied = tracker.get_applied() -- for "show applied" toggle
]]

local mq = require('mq')

-- ==============================================================
-- Module state
-- ==============================================================

local M = {}

-- In-memory dedup table. Key = lowercase item name. Value = record table.
local items = {}

-- Ordered list cache; rebuilt on change. nil = needs rebuild.
local pendingListCache = nil
local pendingCountCache = 0
--- Bumped on every merged journal event so poll() can refresh UI when counts on existing rows change.
local itemsVersion = 0

-- Applied/dismissed state (persisted to disk).
local state = {
    version   = 1,
    applied   = {},   -- [lower_name] = { rule='SELL', name='Silver Ring', at='...' }
    dismissed = {},   -- [lower_name] = { name='Silver Ring', at='...', mark_ts='...' }
                      --   1.3.0: mark_ts is the high-water-mark journal TS at dismiss time.
                      --   Rows with ts <= mark_ts are suppressed; rows with ts > mark_ts
                      --   revive the item as a FRESH record (count restarts from zero).
    last_undo = nil,  -- { key=lower_name, rule='SELL', name='Silver Ring', at='...' }
}

-- Journal tail position (byte offset of last read).
local journalPath = nil
local journalSpecs = {}
local journalOffsets = {}
local lastPollTime = 0
local POLL_INTERVAL_MS = 2000
--- Set when mergeEvent clears a dismiss (batched save at end of load/tail).
local stateNeedsSave = false

-- External dependencies injected via init().
local writeIniKey          = nil
local readIniKey           = nil
local getIniPath           = nil
local getJournalWatchSpecs = nil
--- 1.1.0 additions — orphan INI key cleanup (Fix A+).
--- deleteIniKey(path, section, key) -> bool     (removes the key entirely)
--- readIniSectionPairs(path, section) -> array of {key, value}
--- Both optional; orphan cleanup is skipped silently if either is nil.
local deleteIniKey         = nil
local readIniSectionPairs  = nil

-- LinkDB cache: [lower_name] = link_string or false (= looked up, not found)
local linkCache = {}

--- When false, get_link() skips MQ2LinkDB (journal field only if it is a raw 0x12 item link).
local linkDbEnabled = true

-- ==============================================================
-- State file I/O
-- ==============================================================

local function getConfigDir()
    local mqPath = mq.TLO.MacroQuest.Path() or ''
    if mqPath == '' then return nil end
    return mqPath .. '\\Config'
end

local STATE_FILENAME = 'turbo_skips_state.lua'

local function getStatePath()
    local dir = getConfigDir()
    if not dir then return nil end
    return dir .. '\\' .. STATE_FILENAME
end

--- Serialize a Lua table to a string (flat; supports string/number/bool/nil/table).
--- Intentionally simple — no metatables, no circular refs, no functions.
local function serialize(tbl, indent)
    indent = indent or ''
    local inner = indent .. '  '
    local parts = { '{\n' }
    local n = #parts
    for k, v in pairs(tbl) do
        n = n + 1
        -- Key
        if type(k) == 'string' then
            -- Quote keys that aren't valid Lua identifiers.
            if k:match('^[%a_][%w_]*$') then
                parts[n] = inner .. k .. ' = '
            else
                parts[n] = inner .. '["' .. k:gsub('\\', '\\\\'):gsub('"', '\\"') .. '"] = '
            end
        else
            parts[n] = inner .. '[' .. tostring(k) .. '] = '
        end
        -- Value
        if type(v) == 'table' then
            n = n + 1
            parts[n] = serialize(v, inner)
        elseif type(v) == 'string' then
            n = n + 1
            parts[n] = '"' .. v:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '\\r') .. '"'
        elseif type(v) == 'number' or type(v) == 'boolean' then
            n = n + 1
            parts[n] = tostring(v)
        else
            n = n + 1
            parts[n] = 'nil'
        end
        n = n + 1
        parts[n] = ',\n'
    end
    n = n + 1
    parts[n] = indent .. '}'
    return table.concat(parts)
end

local function saveState()
    local path = getStatePath()
    if not path then return false end
    local tmpPath = path .. '.tmp'
    local f = io.open(tmpPath, 'w')
    if not f then return false end
    f:write('-- Turbo Skip Tracker state (auto-generated, do not hand-edit)\n')
    f:write('return ')
    f:write(serialize(state))
    f:write('\n')
    f:close()
    os.remove(path)
    os.rename(tmpPath, path)
    return true
end

--- Coalesce turbo_skips_state.lua writes across multi-row Review actions so the
--- ImGui loop does not block on N synchronous disk persists (INI writes stay
--- per-row). Normal calls still flush immediately (batch depth zero).
local persistBatchDepth = 0
local statePersistQueued = false

local function persistStateFlush()
    if not statePersistQueued then return end
    saveState()
    statePersistQueued = false
end

local function persistStateSoon()
    statePersistQueued = true
    if persistBatchDepth <= 0 then
        persistStateFlush()
    end
end

function M.persist_batch_begin()
    persistBatchDepth = persistBatchDepth + 1
end

function M.persist_batch_end()
    persistBatchDepth = persistBatchDepth - 1
    if persistBatchDepth < 0 then persistBatchDepth = 0 end
    if persistBatchDepth <= 0 then
        persistStateFlush()
    end
end

local function loadState()
    local path = getStatePath()
    if not path then return end
    local fn = loadfile(path)
    if not fn then return end
    local ok, tbl = pcall(fn)
    if ok and type(tbl) == 'table' then
        state.applied   = tbl.applied   or {}
        state.dismissed = tbl.dismissed or {}
        state.last_undo = tbl.last_undo
        state.version   = tbl.version   or 1
    end
end

-- ==============================================================
-- Reason taxonomy
-- ==============================================================

local REASON_DISPLAY = {
    unlisted              = 'Unlisted',
    below_threshold       = 'Below #',
    stackable_below_pp_threshold = 'Below $',
    lore_already_have     = 'Lore (have)',
    lore_already_owned    = 'Lore (owned)',
    lore_have_copy_cannot_destroy = 'Lore (no destroy)',
    lore_denied_cache     = 'Lore (denied)',
    numeric_limit_reached = 'Limit reached',
    wildcard_excluded     = 'Excluded',
    stack_cap             = 'Stack cap',
    bag_full              = 'Bags full',
    inventory_full        = 'Bags full',
    other                 = 'Other',
}

--- Normalize a reason code from the journal. Known codes pass through;
--- unknown codes get stored as-is with display = 'Other'.
local function normalizeReason(raw)
    if not raw or raw == '' then return 'unlisted' end
    local lc = raw:lower():gsub('%s+', '_')
    if REASON_DISPLAY[lc] then return lc end
    -- Try pattern-based classification for free-text reasons (legacy compat).
    if lc:find('below') and lc:find('threshold') then return 'below_threshold' end
    if lc:find('unlisted') then return 'unlisted' end
    if lc:find('lore') then return 'lore_already_have' end
    if lc:find('bag') and lc:find('full') then return 'bag_full' end
    return raw  -- preserve original as reason code; display will show 'Other'
end

local function reasonDisplayText(code)
    return REASON_DISPLAY[code] or 'Other'
end

-- ==============================================================
-- Journal parsing
-- ==============================================================

--- Parse one pipe-delimited journal line into a table, or nil if comment/blank.
--- Format: iso_ts|zone|reason|detail|item_id|item_name|item_link|source
local function parseLine(line)
    -- Skip comment/blank lines.
    if not line or line == '' then return nil end
    if line:sub(-1) == '\r' then line = line:sub(1, -2) end
    local first = line:sub(1, 1)
    if first == '#' or first == ';' then return nil end

    -- Split on pipes. We expect 8 fields (v2); tolerate 7 (v1 — source absent).
    local fields = {}
    local n = 0
    for field in (line .. '|'):gmatch('([^|]*)|') do
        n = n + 1
        fields[n] = field
    end

    -- Minimum viable: need at least field 6 (item_name).
    local itemName = (fields[6] or '')
    if n < 6 or itemName == '' or itemName == 'NULL' or itemName == 'null' then return nil end

    return {
        ts       = fields[1] or '',
        zone     = fields[2] or '',
        reason   = fields[3] or '',
        detail   = fields[4] or '',
        item_id  = fields[5] or '',
        name     = itemName,
        link     = (n >= 7) and fields[7] or '',
        source   = (n >= 8) and fields[8] or '',  -- looter char name (v2+); '' for v1 rows
    }
end

--- True if `s` looks like a raw EverQuest/MQ clickable item link (starts with 0x12).
--- Journals and /e3bc often contain truncated or plain-text junk in the link field; those must not win over LinkDB.
local function looksLikeEverQuestItemLink(s)
    if type(s) ~= 'string' or s == '' or s == 'NULL' then return false end
    return s:byte(1) == 18
end

local function extractCorpseId(detail)
    local d = tostring(detail or '')
    local id = d:match('corpse=(%d+)')
    if id then return id end
    id = d:match('^%s*(%d+)%s*$')
    return id or ''
end

--- Canonical dedup key for an item name (1.1.0 — Fix A).
--- Collapses whitespace and punctuation variants that historically appeared as
--- separate Skip Review entries (e.g. 'Crystallized Marrow' vs 'CrystallizedMarrow'
--- vs '  Crystallized Marrow  ') into one key.
---
--- Rules:
---   - nil / non-string -> empty string
---   - lowercase
---   - keep only a-z and 0-9 (everything else — spaces, quotes, hyphens,
---     apostrophes, punctuation — is dropped)
---
--- Examples:
---   'Crystallized Marrow'  -> 'crystallizedmarrow'
---   'CrystallizedMarrow'   -> 'crystallizedmarrow'
---   "Pierce's Pouch"       -> 'piercespouch'
---   'Large Raw-hide Boots' -> 'largerawhideboots'
---
--- Collision safety: two legitimately-different items with the same canonical
--- key would merge incorrectly. mergeEvent adds an item_id tiebreak when
--- present and non-empty on both records — different ids means different items.
local function canonicalKey(name)
    if type(name) ~= 'string' or name == '' then return '' end
    return (name:lower():gsub('[^a-z0-9]', ''))
end

--- Prefer the "cleanest" display variant when merging events for the same
--- canonical key. A variant with internal whitespace wins over a
--- space-stripped one (EQ item names are legitimately space-separated, so the
--- spaced variant is the real name). Stray leading/trailing quotes are
--- stripped defensively against dirty rows already on disk.
local function cleanerDisplayName(existing, incoming)
    local function clean(s)
        s = tostring(s or ''):match('^%s*(.-)%s*$') or ''
        -- Strip any leading/trailing " (dirty pre-Fix-B rows).
        s = s:gsub('^"+', ''):gsub('"+$', '')
        return s
    end
    local a = clean(existing)
    local b = clean(incoming)
    if a == '' then return b end
    if b == '' then return a end
    local aHasSpace = a:find(' ', 1, true) ~= nil
    local bHasSpace = b:find(' ', 1, true) ~= nil
    -- Prefer spaced variant. If both (or neither) have spaces, keep existing for stability.
    if bHasSpace and not aHasSpace then return b end
    return a
end

--- Merge one parsed event into the in-memory dedup table.
local function mergeEvent(evt, reviveDismissed)
    local key = canonicalKey(evt.name)
    if key == '' then return end   -- ignore empty / all-punctuation names

    if state.applied[key] then return end

    -- Dismissed revive (1.3.0 — high-water-mark gated):
    --   Dismiss is "hide everything seen up to now". The dismiss record stores
    --   a mark_ts equal to the latest row TS already merged for this item at
    --   dismiss time. A row is suppressed iff rowTs <= mark_ts. A strictly
    --   newer row revives the item as a FRESH record — count restarts from
    --   zero, so the user sees the new occurrence cleanly.
    --
    --   Legacy fallback: pre-1.3.0 dismiss entries only have `at`. If `mark_ts`
    --   is absent, fall back to `at` (same behavior as 1.2.0 for legacy rows —
    --   no migration step needed).
    --
    --   Timestamps are ISO 8601 ('YYYY-MM-DDTHH:MM:SS') — same format used
    --   by skip_log.lua's nowIso() and by dismiss()/clear_all()'s os.date()
    --   call — so plain string compare is chronologically correct.
    local dismissed = state.dismissed[key]
    if dismissed then
        local rowTs = evt.ts or ''
        local markTs = dismissed.mark_ts or dismissed.at or ''
        --- Revive only if the row is strictly newer than the mark.
        --- Older or equal → row stays suppressed (already accounted for at dismiss time).
        --- reviveDismissed flag still gates this (kept for API compatibility).
        if reviveDismissed and rowTs ~= '' and markTs ~= '' and rowTs > markTs then
            state.dismissed[key] = nil
            --- Fresh-start on revive: blow away any stale items[key] record so
            --- the new row creates a clean entry (count = 0 → 1, reasons reset,
            --- last_zone from the new row). Matches user expectation that a
            --- dismissed item "appearing again" looks like a brand-new sighting.
            items[key] = nil
            stateNeedsSave = true
            --- Fall through to normal merge path — item re-enters pending list.
        else
            --- Still dismissed; don't add to items table.
            return
        end
    end

    -- Strip any stray leading/trailing " from the evt.name (pre-Fix-B dirty rows).
    local evtDisplayName = (evt.name:gsub('^"+', ''):gsub('"+$', ''))

    local rec = items[key]
    if not rec then
        rec = {
            name       = evtDisplayName,  -- preserve original casing (cleaned of stray quotes)
            key        = key,
            count      = 0,
            reasons    = {},              -- [reason_code] = count
            last_zone  = '',
            last_seen  = '',
            first_seen = evt.ts,
            item_id    = '',
            corpse_id  = '',
            link       = '',
            detail     = '',
            source     = '',              -- most recent looter who skipped this item
        }
        items[key] = rec
    else
        -- Collision safety (1.1.0): if both records have non-empty item_ids and they
        -- differ, treat as a distinct item despite the shared canonical key. Uses a
        -- secondary bucket keyed by "canonicalKey#item_id" so neither collapses
        -- into the other. Only matters for legitimately-different items that
        -- happen to canonicalize to the same key (rare).
        local cleanEvtId = (evt.item_id or ''):gsub('"', '')
        local cleanRecId = (rec.item_id or ''):gsub('"', '')
        if cleanEvtId ~= '' and cleanRecId ~= '' and cleanEvtId ~= cleanRecId then
            local altKey = key .. '#' .. cleanEvtId
            rec = items[altKey]
            if not rec then
                rec = {
                    name       = evtDisplayName,
                    key        = altKey,
                    count      = 0,
                    reasons    = {},
                    last_zone  = '',
                    last_seen  = '',
                    first_seen = evt.ts,
                    item_id    = '',
                    corpse_id  = '',
                    link       = '',
                    detail     = '',
                    source     = '',
                }
                items[altKey] = rec
            end
            key = altKey  -- subsequent state lookups go to altKey
        else
            -- Same item: upgrade display name to cleanest variant if incoming is better.
            rec.name = cleanerDisplayName(rec.name, evtDisplayName)
        end
    end

    rec.count = rec.count + 1
    rec.last_seen = evt.ts
    rec.last_zone = evt.zone ~= '' and evt.zone or rec.last_zone

    local rc = normalizeReason(evt.reason)
    rec.reasons[rc] = (rec.reasons[rc] or 0) + 1

    -- Keep the most recent non-empty values for enrichment fields.
    -- Strip any stray " from item_id (pre-Fix-B dirty rows) before storing.
    if evt.item_id ~= '' then
        rec.item_id = (evt.item_id:gsub('"', ''))
    end
    if looksLikeEverQuestItemLink(evt.link) then rec.link = evt.link end
    if evt.detail ~= '' then
        rec.detail = evt.detail
        local corpseId = extractCorpseId(evt.detail)
        if corpseId ~= '' then rec.corpse_id = corpseId end
    end
    if evt.source ~= '' then rec.source = evt.source end  -- track most recent looter

    -- Invalidate sorted cache.
    pendingListCache = nil
    itemsVersion = itemsVersion + 1
end

-- ==============================================================
-- Journal load and tail
-- ==============================================================

--- Resolve the journal path (same logic as skip_log.lua).
local function resolveJournalPath()
    local mqPath = mq.TLO.MacroQuest.Path() or ''
    if mqPath == '' then return nil end

    local profile = 'turboloot.ini'
    local mono = mq.TLO.MQ2Mono
    if mono and mono.Query then
        local v = mono.Query('e3,TurboLootIni')()
        if v and v ~= '' and v ~= 'NULL' then profile = v end
    end

    -- Primary: journal sits next to the active profile INI.
    for _, sub in ipairs({ 'Config', 'Macros' }) do
        local p = mqPath .. '\\' .. sub .. '\\' .. profile
        local f = io.open(p, 'r')
        if f then
            f:close()
            local dir = p:match('^(.*)[\\/][^\\/]+$')
            if dir then
                return dir .. '\\TurboLoot_skips_log.txt'
            end
        end
    end

    -- Fallback: look for an existing journal in Config or Macros.
    for _, sub in ipairs({ 'Config', 'Macros' }) do
        local jp = mqPath .. '\\' .. sub .. '\\TurboLoot_skips_log.txt'
        local f = io.open(jp, 'r')
        if f then
            f:close()
            return jp
        end
    end

    return mqPath .. '\\Config\\TurboLoot_skips_log.txt'
end

local function shallowCopyArray(src)
    local out = {}
    for i, v in ipairs(src or {}) do out[i] = v end
    return out
end

local function normalizeWatchSpecs(rawSpecs)
    local specs = {}
    local seen = {}
    for _, raw in ipairs(rawSpecs or {}) do
        local path = raw and tostring(raw.path or '') or ''
        path = path:gsub('/', '\\'):match('^%s*(.-)%s*$') or ''
        if path ~= '' then
            local key = path:lower()
            local spec = seen[key]
            if not spec then
                spec = {
                    path = path,
                    profile = raw.profile or (path:match('[^\\/]+$') or 'turboloot.ini'),
                    iniPath = raw.iniPath or '',
                    looters = {},
                    _looterSeen = {},
                }
                seen[key] = spec
                specs[#specs + 1] = spec
            end
            for _, looter in ipairs(raw.looters or {}) do
                local nm = tostring(looter or ''):match('^%s*(.-)%s*$') or ''
                local lk = nm:lower()
                if nm ~= '' and not spec._looterSeen[lk] then
                    spec._looterSeen[lk] = true
                    spec.looters[#spec.looters + 1] = nm
                end
            end
        end
    end
    for _, spec in ipairs(specs) do spec._looterSeen = nil end
    return specs
end

local function resolveJournalSpecs()
    local specs = normalizeWatchSpecs(getJournalWatchSpecs and getJournalWatchSpecs() or nil)
    if #specs > 0 then return specs end

    local fallback = resolveJournalPath()
    if not fallback then return {} end
    return {{
        path = fallback,
        profile = fallback:match('[^\\/]+$') or 'TurboLoot_skips_log.txt',
        iniPath = '',
        looters = {},
    }}
end

local function specsSignature(specs)
    local parts = {}
    for _, spec in ipairs(specs or {}) do
        parts[#parts + 1] = spec.path:lower()
        parts[#parts + 1] = '\1'
        for _, looter in ipairs(spec.looters or {}) do
            parts[#parts + 1] = looter:lower()
            parts[#parts + 1] = ','
        end
        parts[#parts + 1] = '\2'
    end
    return table.concat(parts)
end

--- Split a byte blob into lines (LF or CRLF). Used with 'rb' so tail offsets match skip_log.lua appends on Windows.
local function forEachLineBlob(blob, callback)
    if not blob or blob == '' then return end
    local start = 1
    local len = #blob
    while start <= len do
        local nl = blob:find('[\r\n]', start)
        if not nl then
            local line = blob:sub(start)
            if line ~= '' then callback(line) end
            break
        end
        local line = blob:sub(start, nl - 1)
        if line ~= '' then callback(line) end
        if blob:sub(nl, nl + 1) == '\r\n' then
            start = nl + 2
        else
            start = nl + 1
        end
    end
end

--- Full load: read the entire journal from disk, merge all events.
local function loadJournal()
    journalSpecs = resolveJournalSpecs()
    journalOffsets = {}
    journalPath = journalSpecs[1] and journalSpecs[1].path or nil
    if not journalPath then return end

    local hadMerge = false
    for _, spec in ipairs(journalSpecs) do
        local f = io.open(spec.path, 'rb')
        if not f then
            journalOffsets[spec.path] = 0
        else
            local data = f:read('*a') or ''
            f:close()
            journalOffsets[spec.path] = #data
            forEachLineBlob(data, function(line)
                local evt = parseLine(line)
                if evt then
                    --- 1.2.0: revive on full load too. mergeEvent's own
                    --- timestamp check ensures only journal rows newer than
                    --- the dismiss timestamp actually revive. Pre-1.2.0 this
                    --- was false, which meant reopening the GUI silently
                    --- dropped 74% of journal rows (diag: 223 of 303 observed).
                    mergeEvent(evt, true)
                    hadMerge = true
                end
            end)
        end
    end

    if not hadMerge then
        itemsVersion = itemsVersion + 1
    end

    pendingListCache = nil
    if stateNeedsSave then
        stateNeedsSave = false
        persistStateSoon()
    end
end

--- Incremental tail: read only bytes appended since last check.
local function tailJournal()
    if not journalPath then return end

    for _, spec in ipairs(journalSpecs) do
        local f = io.open(spec.path, 'rb')
        if f then
            local size = f:seek('end')
            if size then
                local lastPos = journalOffsets[spec.path] or 0
                if size < lastPos then
                    f:close()
                    items = {}
                    pendingListCache = nil
                    journalOffsets = {}
                    loadJournal()
                    return
                end
                if size > lastPos then
                    f:seek('set', lastPos)
                    local chunk = f:read('*a') or ''
                    journalOffsets[spec.path] = size
                    forEachLineBlob(chunk, function(line)
                        local evt = parseLine(line)
                        if evt then mergeEvent(evt, true) end
                    end)
                end
            end
            f:close()
        end
    end

    if stateNeedsSave then
        stateNeedsSave = false
        persistStateSoon()
    end
end

-- ==============================================================
-- LinkDB fallback (lazy, cached)
-- ==============================================================

--- Try to resolve a clickable item link for the given item name.
--- Returns the link string, or '' if unavailable.
local function resolveLink(name)
    local key = name:lower()

    -- Already cached?
    if linkCache[key] ~= nil then
        return linkCache[key] or ''
    end

    -- Try LinkDB TLO (MQ2LinkDB plugin).
    local linkDB = mq.TLO.LinkDB
    if linkDB then
        local ok, result = pcall(function()
            return linkDB('=' .. name)()
        end)
        if ok and result and result ~= '' and result ~= 'NULL' then
            linkCache[key] = result
            return result
        end
    end

    -- Not found; cache the miss so we don't retry every frame.
    linkCache[key] = false
    return ''
end

-- ==============================================================
-- Public API: queries
-- ==============================================================

--- Return the count of pending (not applied, not dismissed) items.
--- Cached; zero cost per frame.
function M.pending_count()
    if pendingListCache then return pendingCountCache end
    -- Rebuild count from items table.
    local n = 0
    for key, rec in pairs(items) do
        if not state.applied[key] and not state.dismissed[key] then
            n = n + 1
        end
    end
    pendingCountCache = n
    return n
end

--- Return sorted list of pending items (by count desc). Cached until invalidated.
function M.get_pending()
    if pendingListCache then return pendingListCache end

    local list = {}
    local n = 0
    for key, rec in pairs(items) do
        if not state.applied[key] and not state.dismissed[key] then
            n = n + 1
            list[n] = rec
        end
    end

    table.sort(list, function(a, b) return a.count > b.count end)

    pendingListCache = list
    pendingCountCache = n
    return list
end

--- Return list of applied items (for "show applied" toggle).
function M.get_applied()
    local list = {}
    local n = 0
    for key, info in pairs(state.applied) do
        local rec = items[key]
        if rec then
            n = n + 1
            list[n] = {
                name  = rec.name,
                count = rec.count,
                rule  = info.rule,
                at    = info.at,
            }
        end
    end
    table.sort(list, function(a, b) return (a.at or '') > (b.at or '') end)
    return list
end

--- Clear in-memory and persisted Skip Review state. When deleteJournals is
--- true, also deletes watched journal files so old count history cannot
--- repopulate the review list on the next load.
function M.reset_all(deleteJournals)
    local removed = 0
    local specs = journalSpecs
    if not specs or #specs == 0 then specs = resolveJournalSpecs() end
    if deleteJournals then
        for _, spec in ipairs(specs or {}) do
            if spec.path and spec.path ~= '' then
                if os.remove(spec.path) then removed = removed + 1 end
            end
        end
    end

    items = {}
    pendingListCache = nil
    pendingCountCache = 0
    itemsVersion = itemsVersion + 1
    journalOffsets = {}
    state = {
        version = 1,
        applied = {},
        dismissed = {},
        last_undo = nil,
    }
    persistStateSoon()
    loadJournal()
    return removed
end

--- Get the primary display reason for an item record.
function M.primary_reason(rec)
    if not rec or not rec.reasons then return 'unlisted', 'Unlisted' end
    local best_code, best_count = 'unlisted', 0
    for code, cnt in pairs(rec.reasons) do
        if cnt > best_count then
            best_code = code
            best_count = cnt
        end
    end
    return best_code, reasonDisplayText(best_code)
end

--- Get link for an item (journal link → LinkDB fallback → empty).
function M.get_link(rec)
    local stored = rec and rec.link
    if looksLikeEverQuestItemLink(stored) then
        return stored
    end
    if not linkDbEnabled then
        return ''
    end
    return resolveLink(rec.name)
end

--- Enable/disable MQ2LinkDB resolution for inspect links (GUI toggle; raw journal links still used when valid).
function M.set_linkdb_enabled(enabled)
    linkDbEnabled = enabled and true or false
    if not linkDbEnabled then
        linkCache = {}
    end
end

function M.is_linkdb_enabled()
    return linkDbEnabled
end

--- Return the most recent looter character name that skipped this item, or ''.
--- Used by the GUI to resolve the default INI target for rule writes.
function M.get_source(rec)
    return (rec and rec.source) and rec.source or ''
end

--- Reason display text lookup.
M.reason_display = reasonDisplayText

-- ==============================================================
-- Public API: mutations
-- ==============================================================

--- Apply a rule to a skipped item. Writes to [ItemLimits] in the chosen INI.
---
--- 1.1.0 changes:
---   - 3rd param `targetIniPath` (optional) — when non-nil, writes to that INI
---     instead of getIniPath(). Supports the multi-INI picker in Skip Review
---     (per-character / per-profile rule assignment).
---   - Orphan cleanup: after writing the new key, enumerates [ItemLimits] on
---     the target INI and deletes any other key whose canonicalKey matches
---     the new key's canonical form (e.g. 'CrystallizedMarrow' orphans left
---     over from pre-Fix-B corrupted writes). Requires deleteIniKey AND
---     readIniSectionPairs; silently skipped if either injector is absent.
---   - Returns `(ok, info)` — `info` is a table on success with:
---         { name, rule, iniPath, oldVal, deletedOrphans = { {key, value}, ... } }
---     Existing callers doing `local ok = apply_rule(...)` keep working
---     (they just ignore the info table).
---
--- Callers with a picker (Skip Review dropdown → targetIni) should pass the
--- user-selected INI as the 3rd param. Callers without a picker (legacy,
--- TG.applySkipRule) pass nil and get local-INI behavior unchanged.
function M.apply_rule(itemName, rule, targetIniPath)
    if not writeIniKey then return false end

    local key = canonicalKey(itemName)
    if key == '' then return false end

    local rec = items[key]
    if not rec then return false end

    -- Choose target INI: explicit param wins, else fall back to configured local INI.
    local iniPath = targetIniPath
    if not iniPath or iniPath == '' then
        if not getIniPath then return false end
        iniPath = getIniPath()
    end
    if not iniPath or iniPath == '' then return false end

    -- Read old value for undo support.
    local oldVal = readIniKey and readIniKey(iniPath, 'ItemLimits', rec.name) or nil

    local ok = writeIniKey(iniPath, 'ItemLimits', rec.name, rule)
    if not ok then return false end

    -- Orphan cleanup (Fix A+): delete any pre-existing [ItemLimits] keys on the
    -- target INI whose canonicalKey matches the one we just wrote, except the
    -- new key itself. Handles leftover dirty names from pre-Fix-B corruption.
    -- Requires both injectors; skipped silently otherwise.
    local deletedOrphans = {}
    if deleteIniKey and readIniSectionPairs then
        local pairs_list = readIniSectionPairs(iniPath, 'ItemLimits') or {}
        for _, pair in ipairs(pairs_list) do
            local pk = pair.key
            if pk and pk ~= rec.name and canonicalKey(pk) == key then
                deletedOrphans[#deletedOrphans + 1] = { key = pk, value = pair.value }
                deleteIniKey(iniPath, 'ItemLimits', pk)
            end
        end
    end

    -- Mark applied in state.
    local ts = os.date('%Y-%m-%dT%H:%M:%S')
    state.applied[key] = {
        rule = rule,
        name = rec.name,
        at   = ts,
    }

    -- Store undo info (includes target INI + any deleted orphans so undo
    -- restores the full pre-apply state).
    state.last_undo = {
        key             = key,
        name            = rec.name,
        rule            = rule,
        old_val         = oldVal,
        ini_path        = iniPath,
        deleted_orphans = deletedOrphans,
        at              = ts,
    }

    pendingListCache = nil
    persistStateSoon()

    return true, {
        name             = rec.name,
        rule             = rule,
        ini_path         = iniPath,
        old_val          = oldVal,
        deleted_orphans  = deletedOrphans,
    }
end

--- Dismiss an item (hide without making a rule).
--- 1.1.0: uses canonicalKey() to match mergeEvent's dedup — so dismissing one
--- variant also hides space-stripped / quote-contaminated siblings already on
--- the pending list from pre-Fix-B dirty rows.
--- 1.3.0: stores mark_ts (high-water-mark journal TS) so future skips of the
--- same item appear as fresh rows with count restarting from zero. Also
--- removes the in-memory items[key] record so the row vanishes from the
--- Review list immediately on click — no waiting for the next render with a
--- stale entry visible.
function M.dismiss(itemName)
    local key = canonicalKey(itemName)
    if key == '' then return false end
    local rec = items[key]
    --- mark_ts is the latest journal row already merged for this item.
    --- Falls back to dismiss wall-clock if rec.last_seen is empty (shouldn't
    --- happen in practice — you can't dismiss something with no merged rows —
    --- but the fallback keeps us safe vs. clock skew between machine and journal).
    local markTs = (rec and rec.last_seen ~= '' and rec.last_seen) or os.date('%Y-%m-%dT%H:%M:%S')
    state.dismissed[key] = {
        name    = (rec and rec.name) or itemName,
        at      = os.date('%Y-%m-%dT%H:%M:%S'),
        mark_ts = markTs,
    }
    --- Clear the in-memory record so the row drops out of get_pending() this frame.
    --- Without this, get_pending still iterates the items table — the dismiss check
    --- filters it out, but only after the loop sees it. Removing it here is faster
    --- and makes the UX feel instant.
    items[key] = nil
    pendingListCache = nil
    persistStateSoon()
    return true
end

--- Undo the most recent apply_rule. Removes the INI entry (or restores old value).
function M.undo_last()
    if not state.last_undo then return false, 'Nothing to undo' end
    if not writeIniKey then return false, 'No INI functions' end

    local undo = state.last_undo

    -- 1.1.0: undo targets the same INI the apply wrote to. Falls back to
    -- getIniPath() for undo records saved before 1.1.0 (no ini_path field).
    local iniPath = undo.ini_path
    if not iniPath or iniPath == '' then
        if not getIniPath then return false, 'No INI path (legacy undo record)' end
        iniPath = getIniPath()
    end
    if not iniPath or iniPath == '' then return false, 'INI path not found' end

    if undo.old_val then
        -- Restore previous value.
        writeIniKey(iniPath, 'ItemLimits', undo.name, undo.old_val)
    else
        -- Remove the key entirely. Prefer the injected deleteIniKey helper
        -- (1.1.0); fall back to inline file rewrite for callers that didn't
        -- wire it (legacy / CLI).
        if deleteIniKey then
            deleteIniKey(iniPath, 'ItemLimits', undo.name)
        else
            local f = io.open(iniPath, 'r')
            if f then
                local lines = {}
                local inSection = false
                for line in f:lines() do
                    local sec = line:match('^%[(.-)%]%s*$')
                    if sec then
                        inSection = (sec == 'ItemLimits')
                    end
                    -- Skip the line if it's our key in the right section.
                    if inSection then
                        local k = line:match('^([^=]+)=')
                        if k and k:match('^%s*(.-)%s*$') == undo.name then
                            -- Drop this line (don't add to output).
                            goto skip_line
                        end
                    end
                    lines[#lines + 1] = line
                    ::skip_line::
                end
                f:close()
                local wf = io.open(iniPath, 'w')
                if wf then
                    for _, line in ipairs(lines) do wf:write(line .. '\n') end
                    wf:close()
                end
            end
        end
    end

    -- Restore any orphan keys we deleted during the apply (1.1.0).
    if undo.deleted_orphans then
        for _, pair in ipairs(undo.deleted_orphans) do
            if pair.key and pair.value then
                writeIniKey(iniPath, 'ItemLimits', pair.key, pair.value)
            end
        end
    end

    -- Un-apply.
    state.applied[undo.key] = nil
    state.last_undo = nil

    pendingListCache = nil
    persistStateSoon()
    return true
end

--- Clear all pending items (mark all as dismissed). Confirmation should happen in UI.
--- 1.3.0: each item gets its own mark_ts (from rec.last_seen), so each one
--- revives independently when a fresh skip lands — same semantics as a manual
--- dismiss applied to every row at once. items[] is cleared so rows drop
--- from the view immediately.
function M.clear_all()
    local nowStr = os.date('%Y-%m-%dT%H:%M:%S')
    for key, rec in pairs(items) do
        if not state.applied[key] and not state.dismissed[key] then
            state.dismissed[key] = {
                name    = rec.name,
                at      = nowStr,
                mark_ts = (rec.last_seen ~= '' and rec.last_seen) or nowStr,
            }
        end
    end
    --- Drop in-memory records so rows clear from the view this frame.
    --- Anything still applied stays in state.applied; clearing items[] does
    --- not touch state.applied / state.dismissed metadata.
    items = {}
    pendingListCache = nil
    persistStateSoon()
end

--- Force a full re-read of the journal (e.g. after profile switch).
function M.refresh()
    items = {}
    linkCache = {}
    pendingListCache = nil
    journalOffsets = {}
    loadJournal()
end

-- ==============================================================
-- Public API: lifecycle
-- ==============================================================

--- Initialize the tracker. Call once from init.lua after helpers are available.
---   writeIniKeyFn(path, section, key, value) -> bool
---   readIniKeyFn(path, section, key) -> string|nil
---   getIniPathFn() -> string|nil
--- 1.1.0 optional injectors (enable Fix A+ orphan cleanup on apply_rule):
---   deleteIniKeyFn(path, section, key) -> bool      removes the key entirely
---   readIniSectionPairsFn(path, section) -> array of {key, value}
--- Pre-1.1.0 callers (3 args) keep working — orphan cleanup is simply skipped.
function M.init(writeIniKeyFn, readIniKeyFn, getIniPathFn, deleteIniKeyFn, readIniSectionPairsFn, getJournalWatchSpecsFn)
    writeIniKey         = writeIniKeyFn
    readIniKey          = readIniKeyFn
    getIniPath          = getIniPathFn
    deleteIniKey        = deleteIniKeyFn        -- optional (nil ok)
    readIniSectionPairs = readIniSectionPairsFn -- optional (nil ok)
    getJournalWatchSpecs = getJournalWatchSpecsFn

    loadState()

    -- State migration (1.1.0): pre-1.1.0 state used `name:lower()` as the key;
    -- 1.1.0 uses canonicalKey() which strips whitespace and punctuation.
    -- On first load after upgrade, remap any keys that differ under the new
    -- scheme so dismiss/undo/applied lookups keep working. Idempotent — re-
    -- running is a no-op because canonicalKey on a canonical key returns
    -- itself. Bumps state.version to 2 on completion so the rewrite only
    -- happens once per state file.
    if (state.version or 1) < 2 then
        local function remap(tbl)
            if type(tbl) ~= 'table' then return end
            local rewrites = {}
            for oldKey, rec in pairs(tbl) do
                local newKey = canonicalKey(rec and rec.name or oldKey)
                if newKey ~= '' and newKey ~= oldKey then
                    rewrites[#rewrites + 1] = { oldKey = oldKey, newKey = newKey, rec = rec }
                end
            end
            for _, r in ipairs(rewrites) do
                -- If a canonical-keyed record already exists (rare — user had
                -- both spellings as separate applied/dismissed entries),
                -- keep the one with the later timestamp.
                local existing = tbl[r.newKey]
                if existing and (existing.at or '') >= (r.rec.at or '') then
                    tbl[r.oldKey] = nil
                else
                    tbl[r.newKey] = r.rec
                    tbl[r.oldKey] = nil
                end
            end
        end
        remap(state.applied)
        remap(state.dismissed)
        -- last_undo's key may also be a legacy lowercase key.
        if state.last_undo and state.last_undo.key then
            local nk = canonicalKey(state.last_undo.name or state.last_undo.key)
            if nk ~= '' then state.last_undo.key = nk end
        end
        state.version = 2
        persistStateSoon()
    end

    loadJournal()
end

--- Poll for new journal entries. Call from the GUI render loop, throttled.
--- Returns true if new journal rows were merged (including extra skips for an item already in the list).
function M.poll()
    local now = (mq.gettime and mq.gettime()) or (os.clock() * 1000)
    if (now - lastPollTime) < POLL_INTERVAL_MS then return false end
    lastPollTime = now

    local nextSpecs = resolveJournalSpecs()
    if specsSignature(nextSpecs) ~= specsSignature(journalSpecs) then
        M.refresh()
        return true
    end

    local v0 = itemsVersion
    tailJournal()
    return itemsVersion ~= v0
end

--- Get the last undo info (for UI display).
function M.get_last_undo()
    if not state.last_undo then return nil end
    return {
        name = state.last_undo.name,
        rule = state.last_undo.rule,
    }
end

--- Check if tracker has been initialized and has a valid journal path.
function M.is_ready()
    return journalPath ~= nil
end

function M.get_watch_info()
    local out = {}
    for i, spec in ipairs(journalSpecs) do
        out[i] = {
            path = spec.path,
            profile = spec.profile,
            iniPath = spec.iniPath,
            looters = shallowCopyArray(spec.looters),
        }
    end
    return out
end

return M
