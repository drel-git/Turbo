--[[
  Turbo Skip Journal Writer
  -------------------------
  @version lua/Turbo/skip_log.lua 1.1.0

  Invocation forms (all from TurboLoot.mac):

    /squelch /lua run Turbo/skip_log session
        - Writes a session-header banner to the journal.

    /squelch /lua run Turbo/skip_log test
        - Appends one dummy row (self-test). Use when the log has only # headers but loot should skip.
        - MQ Next may pass the script path as argv[1] and "test" as argv[2]; dispatch scans for the verb.

    /squelch /lua run Turbo/skip_log append "Item Name" "reason_code" "detail" "itemID" "link" ["source"]
        - Manual append (extra fields optional). TurboLoot.mac uses only item + reason.
    TurboLoot.mac queues skips in SkipBatch and flushes once via /lua run Turbo/skip_append (PrintSummary/Cleanup).
        - MQ Next often ignores /lua run when invoked deep inside the loot call stack; top-level flush matches /lua run … test/session.

  Journal file: TurboLoot_skips_log.txt
    Location:   same directory as the active turboloot profile INI
                (Config checked before Macros, matching TurboLoot.mac)
    Format:     pipe-delimited, one event per line
                <iso_ts>|<zone>|<reason>|<detail>|<item_id>|<item_name>|<link>

  Design notes:
    - Append-only; never rewrites the file inline.
    - Auto-trims when file exceeds size cap (~1.5 MB).
    - Single open/write/close per call; no buffering, no module state between calls.
    - Zero dependencies beyond 'mq'.
]]

local mq = require('mq')

-- ==============================================================
-- Constants
-- ==============================================================

local JOURNAL_FILENAME     = 'TurboLoot_skips_log.txt'
local JOURNAL_VERSION      = 2
--- Trim when the file exceeds this size in bytes.
--- ~1.5 MB ≈ 20K lines × ~75 bytes avg. Generous; trims to ~75% of cap.
local TRIM_SIZE_BYTES      = 5000000
local TRIM_TARGET_LINES    = 30000   -- keep this many lines after a trim

-- ==============================================================
-- Path resolution (folded in from old skip_session_path.lua)
-- ==============================================================

local function activeProfileName()
    local profile = 'turboloot.ini'
    local mono = mq.TLO.MQ2Mono
    if mono and mono.Query then
        local q = mono.Query('e3,TurboLootIni')
        local v = nil
        if type(q) == 'function' then
            v = q()
        elseif type(q) == 'string' then
            v = q
        elseif q ~= nil then
            local ok, r = pcall(function() return q() end)
            if ok then v = r end
        end
        if v and v ~= '' and v ~= 'NULL' then
            profile = v
        end
    end
    return profile
end

local function resolveActiveIniPath(mqPath, profile)
    for _, sub in ipairs({ 'Config', 'Macros' }) do
        local p = mqPath .. '\\' .. sub .. '\\' .. profile
        local f = io.open(p, 'r')
        if f then
            f:close()
            return p
        end
    end
    return nil
end

local function getJournalPath()
    local mqPath = mq.TLO.MacroQuest.Path() or ''
    if mqPath == '' then return nil end

    local iniPath = resolveActiveIniPath(mqPath, activeProfileName())
    if iniPath then
        local dir = iniPath:match('^(.*)[\\/][^\\/]+$')
        if dir then
            return dir .. '\\' .. JOURNAL_FILENAME
        end
    end
    return mqPath .. '\\Config\\' .. JOURNAL_FILENAME
end

--- Absolute journal path when TurboLoot.mac passes the INI folder (Config or Macros).
--- Eliminates rare MQ2Mono / Lua-context mismatches that wrote skips to a different TurboLoot_skips_log.txt than CLI tests.
local function getJournalPathFromIniDir(iniDir)
    if iniDir == nil or iniDir == '' then return nil end
    local d = tostring(iniDir):gsub('/', '\\'):match('^%s*(.-)%s*$') or ''
    while #d >= 2 and d:sub(1, 1) == '"' and d:sub(-1, -1) == '"' do
        d = d:sub(2, -2):match('^%s*(.-)%s*$') or d:sub(2, -2)
    end
    d = d:gsub('\\+$', '')
    if d == '' then return nil end
    if d:find('^%.%.\\') or d:find('^%.%./') then
        local base = mq.TLO.MacroQuest.Path() or ''
        if base ~= '' then
            local tail = d:gsub('^%.%.[\\/]*', '')
            d = base .. '\\' .. tail
        end
    end
    return d .. '\\' .. JOURNAL_FILENAME
end

local function resolveJournalFile(journalIniDir)
    local jp = getJournalPathFromIniDir(journalIniDir)
    if jp then return jp end
    return getJournalPath()
end

local function pathForDisplay(winPath)
    if not winPath then return '' end
    return (winPath:gsub('\\', '/'))
end

-- ==============================================================
-- Sanitization (hot path — avoid allocations where possible)
-- ==============================================================

local function sanitizeField(s)
    if s == nil then return '' end
    s = tostring(s)
    s = s:gsub('[\r\n]', ' '):gsub('|', '/')
    return s:match('^%s*(.-)%s*$') or ''
end

local function nowIso()
    return os.date('%Y-%m-%dT%H:%M:%S')
end

local function currentZone()
    return (mq.TLO.Zone and mq.TLO.Zone.ShortName and mq.TLO.Zone.ShortName()) or ''
end

-- ==============================================================
-- Trim logic (size-based; no sidecar counter file)
-- ==============================================================

--- Check file size; return true if trim is needed.
local function needsTrim(journalPath)
    local f = io.open(journalPath, 'rb')
    if not f then return false end
    local size = f:seek('end')
    f:close()
    return size and size > TRIM_SIZE_BYTES
end

--- Keep the most recent TRIM_TARGET_LINES lines. Single-pass rewrite.
local function trimJournal(journalPath)
    local rf = io.open(journalPath, 'r')
    if not rf then return end

    local lines, n = {}, 0
    for line in rf:lines() do
        n = n + 1
        lines[n] = line
    end
    rf:close()

    if n <= TRIM_TARGET_LINES then return end

    local startIdx = n - TRIM_TARGET_LINES + 1

    -- Write temp, rename over original (atomic on Windows same-directory).
    local tmpPath = journalPath .. '.tmp'
    local wf = io.open(tmpPath, 'wb')
    if not wf then
        -- Fallback: direct overwrite.
        wf = io.open(journalPath, 'wb')
        if not wf then return end
        for i = startIdx, n do wf:write(lines[i]); wf:write('\r\n') end
        wf:close()
        return
    end

    for i = startIdx, n do wf:write(lines[i]); wf:write('\r\n') end
    wf:close()

    os.remove(journalPath)
    os.rename(tmpPath, journalPath)
end

-- ==============================================================
-- Append (hot path)
-- ==============================================================

--- Collapse macro local append + mq.event append for the same skip (~same ms). Rare same-item double-loot keeps both (different timestamps in key if needed).
local dedupe_sig, dedupe_t = '', 0
local DEDUPE_MS = 120

--- Pending session-banner lines (Fix D 1.1.0): writeSessionBanner no longer writes
--- to disk unconditionally. Lines are stashed here and flushed inside the next
--- appendEvent for the same journal path. This prevents the empty-session-header
--- spam (every /lua run Turbo on startup wrote a banner even if no skips occurred).
--- Keyed by absolute journal path so multi-profile switches still work.
local pendingBannersByPath = {}
local pendingTrimByPath = {}
local lastTrimCheckByPath = {}
local TRIM_CHECK_INTERVAL_MS = 10000

--- journalIniDir: optional absolute path to the Config or Macros folder (from TurboLoot.mac); nil = auto-resolve.
--- bypassDedupe: true when replaying a queued batch; preserves intentionally repeated skips in the same flush.
local function appendEvent(itemName, reason, detail, itemId, link, source, journalIniDir, bypassDedupe)
    itemName = sanitizeField(itemName)
    if itemName == '' or itemName == 'NULL' or itemName == 'null' then
        printf('\ar[turboLoot]\ax skip_log append_event: invalid item name after sanitize (%s)', tostring(itemName))
        return false
    end

    local now_ms = (mq.gettime and mq.gettime()) or (os.time() * 1000)
    local sig = table.concat({
        itemName,
        '\1', sanitizeField(reason), '\1', sanitizeField(itemId), '\1',
        sanitizeField(source), '\1', tostring(journalIniDir or ''),
    })
    if not bypassDedupe and sig == dedupe_sig and (now_ms - dedupe_t) < DEDUPE_MS then
        return true
    end
    dedupe_sig, dedupe_t = sig, now_ms

    local journalPath = resolveJournalFile(journalIniDir)
    if not journalPath then
        printf('\ar[turboLoot]\ax skip_log append_event: journal path unresolved (MacroQuest.Path / INI)')
        return false
    end

    local f, err = io.open(journalPath, 'ab')
    if not f then
        printf('\ar[turboLoot]\ax skip log: cannot write %s (%s)', journalPath, tostring(err))
        return false
    end

    -- Flush any pending session banner for this journal path (Fix D 1.1.0).
    -- Banner was stashed by writeSessionBanner; write it now, immediately before the first row.
    local pendingBanner = pendingBannersByPath[journalPath]
    if pendingBanner then
        f:write(pendingBanner)
        pendingBannersByPath[journalPath] = nil
    end

    -- Build the full line with table.concat — one allocation, one write call.
    -- Format: iso_ts|zone|reason|detail|item_id|item_name|link|source
    local row = {
        nowIso(),
        sanitizeField(currentZone()),
        sanitizeField(reason),
        sanitizeField(detail),
        sanitizeField(itemId),
        itemName,   -- already sanitized
        sanitizeField(link),
        sanitizeField(source),  -- looter character name; empty string for legacy/solo calls
    }
    f:write(table.concat(row, '|'))
    f:write('\r\n')
    f:close()

    -- Hot path: do not trim synchronously during looting.
    -- Trimming can read/rewrite thousands of lines and cause a visible hitch.
    -- The GUI/daemon/CLI can call trim_if_needed during safer moments.
    pendingTrimByPath[journalPath] = true

    return true
end

-- ==============================================================
-- Session banner
-- ==============================================================

--- journalIniDir: optional; same as appendEvent (TurboLoot.mac RefreshSkipJournalDir).
--- Fix D 1.1.0: banner is stashed in memory, flushed by the next appendEvent
--- for this journal path. Prevents empty-session spam when TurboLoot starts
--- but no skips are recorded in that session. The user-facing chat message
--- ("Skip journal ON — path") still prints immediately so the user sees
--- confirmation that journaling is active.
local function writeSessionBanner(journalIniDir)
    local journalPath = resolveJournalFile(journalIniDir)
    if not journalPath then
        printf('\ar[turboLoot]\ax skip log: MacroQuest path unknown.')
        return false
    end

    local disp = pathForDisplay(journalPath)
    local banner = string.format(
        '# ==================== session %s ====================\r\n' ..
        '# journal v%d  path=%s\r\n' ..
        '# format: iso_ts|zone|reason|detail|item_id|item_name|item_link|source\r\n' ..
        '# Review via Turbo GUI (Review tab) or: /lua run Turbo/skips_show\r\n',
        os.date('%Y-%m-%d %H:%M:%S'), JOURNAL_VERSION, disp)
    pendingBannersByPath[journalPath] = banner

    printf('\ag[turboLoot]\ax Skip journal \atON\ax - \ay%s\ax', disp)
    return true
end

-- ==============================================================
-- CLI dispatch + module export
-- ==============================================================
-- loadfile(...)( ) with no args returns this table (used by TurboLoot.mac /lua parse and init.lua).
-- require('Turbo/skip_log') passes a module path as first ... arg — not a CLI verb — return export only.
-- MQ Next often passes argv as: [ full/path/skip_log.lua , "test" ]  — scan for the verb, not only args[1].
local function trimIfNeeded(journalPath)
    journalPath = journalPath or getJournalPath()
    if not journalPath or journalPath == '' then return false end

    local now = (mq.gettime and mq.gettime()) or (os.time() * 1000)
    local last = tonumber(lastTrimCheckByPath[journalPath]) or 0
    if (now - last) < TRIM_CHECK_INTERVAL_MS then
        return false
    end
    lastTrimCheckByPath[journalPath] = now

    if needsTrim(journalPath) then
        trimJournal(journalPath)
        pendingTrimByPath[journalPath] = nil
        return true
    end

    pendingTrimByPath[journalPath] = nil
    return false
end

local export_table = {
    version       = JOURNAL_VERSION,
    append_event  = appendEvent,
    write_session = writeSessionBanner,
    get_path      = getJournalPath,
    trim_if_needed = trimIfNeeded,
    append_skip   = function(item, reason)
        return appendEvent(item, reason, '', '', '', '', nil)
    end,
}

local CLI_VERBS = { session = true, append = true, path = true, test = true }

local nargs = select('#', ...)
if nargs == 0 then
    return export_table
end

local args = { ... }
local verbIdx, verb = nil, nil
for i = 1, nargs do
    local a = args[i]
    if type(a) == 'string' then
        local lc = a:lower()
        if CLI_VERBS[lc] then
            verbIdx, verb = i, lc
            break
        end
    end
end

if not verb then
    return export_table
end

local function argk(k)
    return args[verbIdx + k]
end

if verb == 'session' then
    local iniDir = argk(1)
    iniDir = (iniDir and iniDir ~= '' and iniDir ~= 'NULL') and iniDir or nil
    writeSessionBanner(iniDir)
    return
end

if verb == 'append' then
    local nm = argk(1)
    if nm == nil or sanitizeField(nm) == '' then
        printf('\ar[turboLoot]\ax skip_log append: missing item name (argv after append)')
        return
    end
    local src = argk(6)
    if src == nil or tostring(src) == '' then
        src = tostring(mq.TLO.Me.Name() or '')
    end
    appendEvent(nm, argk(2), argk(3), argk(4), argk(5), src)
    return
end

if verb == 'path' then
    local p = getJournalPath()
    if p then
        printf('\ag[turboLoot]\ax skip journal path: \ay%s\ax', pathForDisplay(p))
    else
        printf('\ar[turboLoot]\ax skip journal path: unresolved')
    end
    return
end

if verb == 'test' then
    local ok = appendEvent('__TurboSkip_Journal_SelfTest__', 'self_test', '', '0', 'NULL', 'cli')
    if ok then
        printf('\ag[turboLoot]\ax skip_log test: OK — one row written (item __TurboSkip_Journal_SelfTest__). Open TurboLoot_skips_log.txt to confirm.')
    else
        printf('\ar[turboLoot]\ax skip_log test: FAILED — append_event returned false (path/permissions/empty name). Run: /lua run Turbo/skip_log path')
    end
    return
end

return export_table
