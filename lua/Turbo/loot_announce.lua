--[[
   TurboGains Announcer (tiny boxed-character helper)
   ---------------------------------------------------
   Purpose: a minimal companion to Turbo/gains for setups where you
   only want the FULL tracker (Turbo + loot_money) running on your main
   character. Boxed characters run THIS script instead -- it just watches
   for "You receive X plat from the corpse" lines and rebroadcasts them
   over EQBC so the main character's tracker can credit the looter.

   What it does:
     - Listens for the standard EQ money-loot chat lines.
     - Captures the targeted corpse name (mq.TLO.Target.CleanName).
     - Sends one /e3bc line per loot, tagged [TurboGains] so the main
       character's loot_money engine recognizes it and updates totals.

   What it does NOT do:
     - No tracking, no UI, no persistence, no slash commands beyond stop.
     - No anti-feedback dedupe needed -- the main char's engine handles
       that on its side. We just emit.
     - No Actors. The main char's engine listens via chat scrape.

   Usage:
     /lua run Turbo/loot_announce
     /lua stop Turbo/loot_announce
     /turbogains_announce stop     -- alternate stop
     /turbomoney_announce stop     -- compatibility stop

   Recommended: have your boxed-char autoexec or a startup macro fire the
   /lua run command on login.

   @version lua/Turbo/loot_announce.lua 1.0.0
]]

local mq = require('mq')

local CHANNEL = '/e3bc'   -- change to /bc /bca /dgt etc if your server uses different
local TAG     = '[TurboGains]'
local OLD_TAG = '[TurboMoney]'

local MyName = mq.TLO.Me.CleanName() or 'unknown'
local running = true

-- Same dedupe + feedback-loop guards as the main engine, in miniature.
-- Without them, /e3bc echoes back into chat as "[E3] HH:MM:SS <Name> [TurboGains]..."
-- which would otherwise re-trigger our patterns and announce again.
local lastLine, lastLineMs = nil, 0
local lastAmountCp, lastAmountMs = 0, 0
local DEDUPE_MS = 1500

local CP_PER_SP, CP_PER_GP, CP_PER_PP = 10, 100, 1000

--- Parse coin denominations out of an EQ loot line into total copper plus
--- a {pp,gp,sp,cp} breakdown. Skips give/sell/buy lines that mention coin
--- words but aren't loot.
local function parseMoneyLine(line)
    if not line or line == '' then return 0, nil end
    local lower = line:lower()
    if not (lower:find('platinum') or lower:find('gold')
        or lower:find('silver') or lower:find('copper')) then
        return 0, nil
    end
    if lower:find('you give')  or lower:find('you trade')
        or lower:find('purchas') or lower:find('sold')
        or lower:find('buy ')    or lower:find('cost ')
        or lower:find('discount') then
        return 0, nil
    end
    local b = { pp = 0, gp = 0, sp = 0, cp = 0 }
    for amt in lower:gmatch('(%d+)%s*platinum') do b.pp = b.pp + (tonumber(amt) or 0) end
    for amt in lower:gmatch('(%d+)%s*gold')     do b.gp = b.gp + (tonumber(amt) or 0) end
    for amt in lower:gmatch('(%d+)%s*silver')   do b.sp = b.sp + (tonumber(amt) or 0) end
    for amt in lower:gmatch('(%d+)%s*copper')   do b.cp = b.cp + (tonumber(amt) or 0) end
    local total = b.pp * CP_PER_PP + b.gp * CP_PER_GP + b.sp * CP_PER_SP + b.cp
    return total, b
end

local function formatBreakdown(b)
    if not b then return '0pp' end
    local parts = {}
    if b.pp > 0 then table.insert(parts, string.format('%dpp', b.pp)) end
    if b.gp > 0 then table.insert(parts, string.format('%dgp', b.gp)) end
    if b.sp > 0 then table.insert(parts, string.format('%dsp', b.sp)) end
    if b.cp > 0 then table.insert(parts, string.format('%dcp', b.cp)) end
    if #parts == 0 then return '0pp' end
    return table.concat(parts, ' ')
end

local function onLootLine(line)
    -- Reject our own EQBC echoes so we don't announce the announcement.
    if line:find(TAG, 1, true) or line:find(OLD_TAG, 1, true) then return end
    -- Channel-prefix markers indicate this is some other character's
    -- broadcast we're seeing; their announcer (if any) handles it.
    if line:find('<%a+>') or line:find('%[E3%]')
        or line:find('%[BC%]') or line:find('%[BCA%]') then
        return
    end

    local nowMs = (mq.gettime and mq.gettime()) or (os.time() * 1000)
    if line == lastLine and (nowMs - lastLineMs) < DEDUPE_MS then return end
    lastLine, lastLineMs = line, nowMs

    local cp, breakdown = parseMoneyLine(line)
    if cp <= 0 then return end

    -- Same-amount dedupe catches color-code variants of the same loot line.
    if cp == lastAmountCp and (nowMs - lastAmountMs) < DEDUPE_MS then return end
    lastAmountCp, lastAmountMs = cp, nowMs

    -- Try to grab the targeted corpse's name. CleanName on a corpse returns
    -- something like "a decaying skeleton's corpse"; strip the suffix.
    local corpse = ''
    local okT, t = pcall(function() return mq.TLO.Target.CleanName() end)
    if okT and type(t) == 'string' and t ~= '' then
        corpse = t:gsub("['`]s corpse$", "")
                  :gsub("'s corpse$", "")
                  :gsub("`s corpse$", "")
    end
    if corpse == '' or corpse == 'the corpse' or corpse == 'a corpse' then
        local fromLine = line:match("from%s+(.-)'s corpse")
                      or line:match("from%s+(.-)`s corpse")
        if fromLine and fromLine ~= '' then corpse = fromLine end
    end

    -- Emit the same chat format the main char's loot_money engine emits
    -- for itself. Its echo-scrape handler will pick this up, dedupe it
    -- against any Actors traffic, and credit MyName as the looter.
    -- We omit "session: ..." since we don't track totals here.
    mq.cmdf('%s %s %s looted %s%s', CHANNEL, TAG, MyName,
        formatBreakdown(breakdown),
        (corpse ~= '' and (' from ' .. corpse)) or '')
end

-- Same broad patterns the main engine uses. The parser does the actual
-- loot-vs-not-loot decision; using only two patterns avoids the same line
-- firing the callback multiple times when it contains multiple coin types.
local PATTERNS = {
    'You receive #*#from #*#corpse#*#',
    '#*#You have looted #*#from #*#corpse#*#',
}

for i, pat in ipairs(PATTERNS) do
    pcall(function() mq.event('TurboMoneyAnnounce' .. i, pat, onLootLine) end)
end

local function handleSlash(...)
    local args = { ... }
    local sub = (args[1] or ''):lower()
    if sub == 'stop' or sub == 'quit' or sub == 'exit' then
        running = false
    elseif sub == 'channel' then
        if args[2] then
            CHANNEL = args[2]
            printf('\at[TurboGainsAnnounce]\ax channel = %s', CHANNEL)
        else
            printf('\at[TurboGainsAnnounce]\ax current channel: %s', CHANNEL)
        end
    elseif sub == 'test' then
        onLootLine('You receive 5 platinum, 3 gold, 2 silver and 1 copper from the corpse.')
    else
        printf('\at[TurboGainsAnnounce]\ax announcer running on %s -> %s. ' ..
               'Subcommands: stop, channel <chan>, test', MyName, CHANNEL)
    end
end
pcall(function() mq.bind('/turbogains_announce', handleSlash) end)
pcall(function() mq.bind('/turbomoney_announce', handleSlash) end)

printf('\at[TurboGainsAnnounce]\ax \agonline for %s. broadcasting loot to %s as %s\ax',
    MyName, CHANNEL, TAG)

while running do
    mq.doevents()
    mq.delay(50)
end

for i = 1, #PATTERNS do
    pcall(function() mq.unevent('TurboMoneyAnnounce' .. i) end)
end
pcall(function() mq.unbind('/turbogains_announce') end)
pcall(function() mq.unbind('/turbomoney_announce') end)
printf('\at[TurboGainsAnnounce]\ax \arstopped.\ax')
