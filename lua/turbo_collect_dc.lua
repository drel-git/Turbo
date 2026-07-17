--[[
  turbo_collect_dc.lua - Lua coordinator for collecting Diamond Coins.
  @version lua/turbo_collect_dc.lua 1.0.0
  Usage:
    /lua run turbo_collect_dc
    /lua run turbo_collect_dc all
    /lua run turbo_collect_dc 500
    /lua run turbo_collect_dc all 500

  First pass is intentionally hybrid: this collector script handles serialized
  orchestration, trade acceptance, reclaiming, and summaries; sender boxes still
  use TurboGive.mac _senddc for the hard-earned item pickup/trade-fill logic.
]]

local mq = require('mq')

local TAG = '\at[TurboDC]\ax'
local DEFAULT_CHUNK = 7000
local MAX_PASSES = 200
local FIRST_ACTIVITY_TIMEOUT_MS = 45000
local IDLE_AFTER_TRADE_MS = 12000
local IDLE_AFTER_DONE_MS = 3000

local args = { ... }

local done = {}

local function now_ms()
    return (mq.gettime and mq.gettime()) or (os.time() * 1000)
end

local function out(fmt, ...)
    local msg = select('#', ...) > 0 and string.format(fmt, ...) or tostring(fmt or '')
    if _G.printf then
        printf('%s %s', TAG, msg)
    else
        print(TAG .. ' ' .. msg)
    end
end

local function clean_name(name)
    return tostring(name or ''):lower():gsub('[^%w_]', '')
end

local function sender_name(text)
    return (tostring(text or ''):match('([%w_]+)%s*$')) or ''
end

local function safe_call(default, fn)
    local ok, value = pcall(fn)
    if ok and value ~= nil then return value end
    return default
end

local function safe_num(fn)
    return tonumber(safe_call(0, fn)) or 0
end

local function safe_bool(fn)
    return safe_call(false, fn) and true or false
end

local function me_name()
    return tostring(safe_call('', function() return mq.TLO.Me.CleanName() end)
        or safe_call('', function() return mq.TLO.Me.Name() end)
        or '')
end

local function item_count(name)
    return safe_num(function() return mq.TLO.FindItemCount('=' .. name)() end)
end

local function free_inventory()
    return safe_num(function() return mq.TLO.Me.FreeInventory() end)
end

local function cursor_id()
    return safe_num(function() return mq.TLO.Cursor.ID() end)
end

local function cursor_name()
    return tostring(safe_call('', function() return mq.TLO.Cursor.Name() end) or '')
end

local function window_open(name)
    return safe_bool(function() return mq.TLO.Window(name).Open() end)
end

local function read_alt_dc()
    local n = safe_num(function()
        local t = mq.TLO.Me.AltCurrency('Diamond Coins')
        return t and t() or 0
    end)
    if n > 0 then return n end
    return safe_num(function() return mq.TLO.Me.AltCurrency(20)() end)
end

local function clear_cursor(context, timeout_ms)
    local deadline = now_ms() + (tonumber(timeout_ms) or 5000)
    while cursor_id() > 0 and now_ms() < deadline do
        mq.cmd('/autoinventory')
        mq.delay(250, function() return cursor_id() == 0 end)
        if cursor_id() > 0 then
            mq.cmd('/autoinv')
            mq.delay(250, function() return cursor_id() == 0 end)
        end
    end
    if cursor_id() > 0 then
        out('\arWARNING:\ax cursor still has %s while %s.',
            cursor_name() ~= '' and cursor_name() or 'an item',
            context or 'clearing cursor')
        return false
    end
    return true
end

local function ensure_inventory_window()
    if window_open('InventoryWindow') then return true end
    safe_call(nil, function() return mq.TLO.Window('InventoryWindow').DoOpen() end)
    mq.delay(700, function() return window_open('InventoryWindow') end)
    if window_open('InventoryWindow') then return true end
    out('\arWARNING:\ax could not open InventoryWindow.')
    return false
end

local function alt_currency_list_id()
    local id = safe_num(function()
        return mq.TLO.Window('InventoryWindow').Child('IW_AltCurr_PointList').List('=Diamond Coins', 2)()
    end)
    if id > 0 then return id end
    return safe_num(function()
        return mq.TLO.Window('InventoryWindow').Child('IW_AltCurr_PointList').List('=Diamond Coin', 2)()
    end)
end

local function reclaim_dc()
    if item_count('Diamond Coin') <= 0 then return 0 end
    if mq.TLO.Lua.Script('rgmercs').Status.Equal('RUNNING')() then
        mq.cmd('/rgl pause')
    else
        mq.cmd('/e3p on')
    end
    mq.delay(100)
    if not ensure_inventory_window() then
        if mq.TLO.Lua.Script('rgmercs').Status.Equal('RUNNING')() then
            mq.cmd('/rgl unpause')
        else
            mq.cmd('/e3p off')
        end
        return 0
    end

    mq.cmd('/nomodkey /notify InventoryWindow IW_Subwindows tabselect 5')
    mq.delay(300)

    local id = alt_currency_list_id()
    if id <= 0 then
        out('\aySkipped reclaim:\ax could not find Diamond Coins in the alt-currency list.')
        if mq.TLO.Lua.Script('rgmercs').Status.Equal('RUNNING')() then
            mq.cmd('/rgl unpause')
        else
            mq.cmd('/e3p off')
        end
        return 0
    end

    local before_inv = item_count('Diamond Coin')
    mq.cmdf('/nomodkey /notify InventoryWindow IW_AltCurr_PointList listselect %d leftmouseup', id)
    mq.delay(150)
    mq.cmd('/nomodkey /notify InventoryWindow AltCurr_ReclaimButton leftmouseup')
    mq.delay(250, function() return item_count('Diamond Coin') < before_inv end)
    if item_count('Diamond Coin') >= before_inv then
        mq.cmd('/nomodkey /notify InventoryWindow IW_AltCurr_Reclaimbutton leftmouseup')
    end
    mq.delay(800, function() return item_count('Diamond Coin') < before_inv end)
    if mq.TLO.Lua.Script('rgmercs').Status.Equal('RUNNING')() then
        mq.cmd('/rgl unpause')
    else
        mq.cmd('/e3p off')
    end
    return math.max(0, before_inv - item_count('Diamond Coin'))
end

local function close_inventory()
    if window_open('InventoryWindow') then
        mq.cmd('/nomodkey /notify InventoryWindow DoneButton leftmouseup')
        mq.delay(500, function() return not window_open('InventoryWindow') end)
    end
end

local function accept_trade()
    if not window_open('TradeWnd') then return false end
    mq.cmd('/notify TradeWnd TRDW_Trade_Button leftmouseup')
    mq.delay(1200, function() return not window_open('TradeWnd') end)
    if window_open('TradeWnd') then
        mq.cmd('/notify TradeWnd TRDW_Trade_Button leftmouseup')
        mq.delay(2000, function() return not window_open('TradeWnd') end)
    end
    return not window_open('TradeWnd')
end

local function register_done_events()
    local function mark_done_from_text(text)
        text = tostring(text or '')
        local name = text:match('%[SIGNAL_DONE%].-([%w_]+)%s*$')
            or text:match('%[DONE%].-([%w_]+)%s*%-%>')
            or text:match('%[DONE%].-([%w_]+)%s*$')
        if name and name ~= '' then
            done[clean_name(name)] = true
        end
    end

    local function on_signal(line, name)
        name = sender_name(name)
        if name ~= '' then
            done[clean_name(name)] = true
        else
            mark_done_from_text(line)
        end
    end

    local function on_done(line, name)
        name = sender_name(name)
        if name ~= '' then
            done[clean_name(name)] = true
        else
            mark_done_from_text(line)
        end
    end

    pcall(function() mq.event('TurboCollectDCSignal', '#*#[SIGNAL_DONE]#*##1#', on_signal) end)
    pcall(function() mq.event('TurboCollectDCDoneArrow', '#*#[DONE]#*##1#->#2#', on_done) end)
    pcall(function() mq.event('TurboCollectDCDoneAny', '#*#[DONE]#*#', on_done) end)
end

local function unregister_done_events()
    pcall(function() mq.unevent('TurboCollectDCSignal') end)
    pcall(function() mq.unevent('TurboCollectDCDoneArrow') end)
    pcall(function() mq.unevent('TurboCollectDCDoneAny') end)
end

local function add_unique(out_list, seen, name)
    name = tostring(name or ''):match('^%s*(.-)%s*$') or ''
    name = name:match('^[%w_]+') or name
    if name == '' then return end
    if clean_name(name) == clean_name(me_name()) then return end
    local key = clean_name(name)
    if key == '' or seen[key] then return end
    seen[key] = true
    out_list[#out_list + 1] = name
end

local function group_members()
    local out_list, seen = {}, {}
    local n = safe_num(function() return mq.TLO.Group.Members() end)
    for i = 1, n do
        local name = tostring(safe_call('', function() return mq.TLO.Group.Member(i).Name() end) or '')
        add_unique(out_list, seen, name)
    end
    return out_list
end

local function e3_members()
    local out_list, seen = {}, {}
    local peers = tostring(safe_call('', function()
        if mq.TLO.MQ2Mono and mq.TLO.MQ2Mono.Query then
            return mq.TLO.MQ2Mono.Query('e3,E3Bots.ConnectedClients')()
        end
        return ''
    end) or '')
    for name in peers:gmatch('([^,]+)') do
        add_unique(out_list, seen, name)
    end
    if #out_list == 0 then
        return group_members()
    end
    return out_list
end

local function spawn_exists(name)
    if name == '' then return false end
    return safe_num(function() return mq.TLO.Spawn('pc ' .. name).ID() end) > 0
end

local function parse_args()
    local scope = 'group'
    local max_amount = 0
    for _, raw in ipairs(args) do
        local s = tostring(raw or ''):lower()
        if s == 'all' or s == 'e3' or s == 'raid' then
            scope = 'all'
        elseif tonumber(s) and tonumber(s) > 0 then
            max_amount = math.floor(tonumber(s))
        end
    end
    return scope, max_amount
end

local function ask_sender(name, chunk)
    done[clean_name(name)] = nil
    if chunk and chunk > 0 then
        mq.cmdf('/squelch /e3bct %s /mac turbogive _senddc %s %d', name, me_name(), chunk)
    else
        mq.cmdf('/squelch /e3bct %s /mac turbogive _senddc %s', name, me_name())
    end
end

local function collect_from_sender(name, chunk)
    out('\ao[COLLECT DC]\ax Asking \ag%s\ax to send DC...', name)
    local before_alt = read_alt_dc()
    local before_inv = item_count('Diamond Coin')
    local start = now_ms()
    local last_activity = start
    local saw_trade = false
    local trade_count = 0

    ask_sender(name, chunk)

    while true do
        if mq.doevents then mq.doevents() end

        if window_open('TradeWnd') then
            saw_trade = true
            last_activity = now_ms()
            if accept_trade() then
                trade_count = trade_count + 1
                mq.delay(350)
                reclaim_dc()
                last_activity = now_ms()
            else
                out('\ay[COLLECT DC]\ax Trade with %s did not close cleanly; moving on.', name)
                break
            end
        end

        if item_count('Diamond Coin') > 0 then
            reclaim_dc()
            last_activity = now_ms()
        end

        local key = clean_name(name)
        if done[key] then
            if now_ms() - last_activity >= IDLE_AFTER_DONE_MS then break end
        elseif saw_trade then
            if now_ms() - last_activity >= IDLE_AFTER_TRADE_MS then break end
        elseif now_ms() - start >= FIRST_ACTIVITY_TIMEOUT_MS then
            out('\ay[COLLECT DC]\ax Timed out waiting for %s to open trade or signal done.', name)
            break
        end

        mq.delay(100)
    end

    reclaim_dc()
    local after_alt = read_alt_dc()
    local after_inv = item_count('Diamond Coin')
    local received = math.max(0, (after_alt - before_alt) + math.max(0, after_inv - before_inv))
    return received, trade_count, done[clean_name(name)] == true
end

local function main()
    local scope, max_amount = parse_args()
    if cursor_id() > 0 then
        out('\arAborting:\ax cursor item detected before start: %s.', cursor_name() ~= '' and cursor_name() or 'unknown item')
        return false
    end
    if safe_bool(function() return mq.TLO.Me.Feigning() end) then
        out('\arAborting:\ax cannot trade while feigned.')
        return false
    end

    if item_count('Diamond Coin') > 0 then
        out('\ao[COLLECT DC]\ax Reclaiming existing inventory Diamond Coin before collection.')
        reclaim_dc()
    end

    local members = scope == 'all' and e3_members() or group_members()
    local active = {}
    for _, name in ipairs(members) do
        if spawn_exists(name) then
            active[#active + 1] = name
        end
    end

    if #active == 0 then
        out('\arNo %s members found in-zone to collect DC from.', scope == 'all' and 'E3' or 'group')
        return false
    end

    if free_inventory() <= 0 and item_count('Diamond Coin') <= 0 then
        out('\ayWarning:\ax no free inventory slots. Incoming DC may fail if it cannot stack.')
    end

    local chunk = max_amount > 0 and math.min(max_amount, DEFAULT_CHUNK) or DEFAULT_CHUNK
    out('\ao[COLLECT DC]\ax Collecting from %s: %d sender(s), chunk %d%s.',
        scope == 'all' and 'all E3 peers' or 'group',
        #active,
        chunk,
        max_amount > 0 and (' each, limit ' .. tostring(max_amount)) or '')

    register_done_events()

    local total_received, sent_count, responded = 0, 0, 0
    local passes, empty_passes = 0, 0

    for pass = 1, MAX_PASSES do
        passes = pass
        local pass_received = 0
        for _, name in ipairs(active) do
            local remaining = max_amount > 0 and max_amount or 0
            local request_chunk = remaining > 0 and math.min(remaining, DEFAULT_CHUNK) or DEFAULT_CHUNK
            local got, trades, signaled = collect_from_sender(name, request_chunk)
            sent_count = sent_count + 1
            if signaled or trades > 0 then responded = responded + 1 end
            total_received = total_received + got
            pass_received = pass_received + got
            if got > 0 then
                out('\ao[COLLECT DC]\ax Pass %d: %s delivered \ag%d\ax DC. Alt-currency DC now: \ag%d\ax.',
                    pass, name, got, read_alt_dc())
            end
            mq.delay(350)
        end

        if pass_received <= 0 then
            empty_passes = empty_passes + 1
        else
            empty_passes = 0
        end
        if empty_passes >= 1 then break end
    end

    unregister_done_events()
    reclaim_dc()
    clear_cursor('finishing', 4000)
    close_inventory()

    out('\agComplete\ax after \ag%d\ax pass(es). \ag%d\ax/\ag%d\ax requests returned activity. Total received/reclaimed: \ag%d\ax DC. Alt-currency DC now: \ag%d\ax.',
        passes, responded, sent_count, total_received, read_alt_dc())
    return true
end

local ok, err = pcall(main)
unregister_done_events()
if not ok then
    out('\arERROR:\ax %s', tostring(err))
end
