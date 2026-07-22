--[[
  turbo_collect_rc.lua - Lua coordinator for Radiant Crystal collect / give-to.
  @version lua/turbo_collect_rc.lua 1.0.0
  Usage:
    /lua run turbo_collect_rc              -- collect from group to me
    /lua run turbo_collect_rc all          -- collect from E3 peers to me
    /lua run turbo_collect_rc from Name    -- collect from one peer to me
    /lua run turbo_collect_rc to Name      -- peers send all RC to Name
    /lua run turbo_collect_rc from A to B  -- A sends RC to B
    /lua run turbo_collect_rc all to Name

  Orchestration + trade accept (collect-to-me) live here; senders use
  TurboGive.mac _sendrc for create-item + trade fill. Give-to relies on
  sender e3bct trade-accept on the recipient.
]]

local mq = require('mq')
do
    local src = (debug.getinfo(1, 'S').source or ''):gsub('^@', '')
    local dir = src:gsub('[/\\][^/\\]*$', '')
    if dir ~= '' and dir ~= src then
        package.path = dir .. '/?.lua;' .. dir .. '/?/init.lua;' .. package.path
    end
end
local bot_pause = require('turbo_lib.bot_pause')

local TAG = '\at[TurboRC]\ax'
local DEFAULT_CHUNK = 7000
local MAX_PASSES = 200
local FIRST_ACTIVITY_TIMEOUT_MS = 45000
local IDLE_AFTER_TRADE_MS = 12000
local IDLE_AFTER_DONE_MS = 3000
local ITEM_NAME = 'Radiant Crystal'

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

local function item_count()
    return safe_num(function() return mq.TLO.FindItemCount('=' .. ITEM_NAME)() end)
end

local function read_rc()
    local ok, n = pcall(function()
        return require('turbo_lib.wallet_currency').radiant_alt()
    end)
    if ok and n ~= nil then return tonumber(n) or 0 end
    return safe_num(function() return mq.TLO.Me.RadiantCrystals() end)
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
    return window_open('InventoryWindow')
end

local function alt_currency_list_id()
    local id = safe_num(function()
        return mq.TLO.Window('InventoryWindow').Child('IW_AltCurr_PointList').List('=Radiant Crystals', 2)()
    end)
    if id > 0 then return id end
    return safe_num(function()
        return mq.TLO.Window('InventoryWindow').Child('IW_AltCurr_PointList').List('=Radiant Crystal', 2)()
    end)
end

local function reclaim_rc()
    if item_count() <= 0 then return 0 end
    bot_pause.pause()
    mq.delay(100)
    if not ensure_inventory_window() then
        bot_pause.resume()
        return 0
    end

    mq.cmd('/nomodkey /notify InventoryWindow IW_Subwindows tabselect 5')
    mq.delay(300)

    local id = alt_currency_list_id()
    if id <= 0 then
        out('\aySkipped reclaim:\ax could not find Radiant Crystals in the alt-currency list.')
        bot_pause.resume()
        return 0
    end

    local before_inv = item_count()
    mq.cmdf('/nomodkey /notify InventoryWindow IW_AltCurr_PointList listselect %d leftmouseup', id)
    mq.delay(150)
    mq.cmd('/nomodkey /notify InventoryWindow AltCurr_ReclaimButton leftmouseup')
    mq.delay(250, function() return item_count() < before_inv end)
    if item_count() >= before_inv then
        mq.cmd('/nomodkey /notify InventoryWindow IW_AltCurr_Reclaimbutton leftmouseup')
    end
    mq.delay(800, function() return item_count() < before_inv end)
    bot_pause.resume()
    return math.max(0, before_inv - item_count())
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

    pcall(function() mq.event('TurboCollectRCSignal', '#*#[SIGNAL_DONE]#*##1#', on_signal) end)
    pcall(function() mq.event('TurboCollectRCDoneArrow', '#*#[DONE]#*##1#->#2#', on_done) end)
    pcall(function() mq.event('TurboCollectRCDoneAny', '#*#[DONE]#*#', on_done) end)
end

local function unregister_done_events()
    pcall(function() mq.unevent('TurboCollectRCSignal') end)
    pcall(function() mq.unevent('TurboCollectRCDoneArrow') end)
    pcall(function() mq.unevent('TurboCollectRCDoneAny') end)
end

local function add_unique(out_list, seen, name)
    name = tostring(name or ''):match('^%s*(.-)%s*$') or ''
    name = name:match('^[%w_]+') or name
    if name == '' then return end
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
    local recipient = ''
    local from_only = ''
    local max_amount = 0
    local i = 1
    while i <= #args do
        local s = tostring(args[i] or '')
        local low = s:lower()
        if low == 'all' or low == 'e3' or low == 'raid' then
            scope = 'all'
        elseif low == 'from' and args[i + 1] then
            from_only = tostring(args[i + 1]):match('^[%w_]+') or ''
            i = i + 1
        elseif low == 'to' and args[i + 1] then
            recipient = tostring(args[i + 1]):match('^[%w_]+') or ''
            i = i + 1
        elseif tonumber(s) and tonumber(s) > 0 then
            max_amount = math.floor(tonumber(s))
        elseif recipient == '' and s:match('^[%w_]+$') and low ~= 'group' then
            -- bare name after optional all: treat as recipient only with explicit "to"
        end
        i = i + 1
    end
    if recipient == '' then
        recipient = me_name()
    end
    return scope, recipient, from_only, max_amount
end

local function ask_sender(name, recipient, chunk)
    done[clean_name(name)] = nil
    if chunk and chunk > 0 then
        mq.cmdf('/squelch /e3bct %s /mac turbogive _sendrc %s %d', name, recipient, chunk)
    else
        mq.cmdf('/squelch /e3bct %s /mac turbogive _sendrc %s', name, recipient)
    end
end

local function wait_sender(name, collect_locally)
    out('\ao[RC]\ax Asking \ag%s\ax...', name)
    local before_alt = collect_locally and read_rc() or 0
    local before_inv = collect_locally and item_count() or 0
    local start = now_ms()
    local last_activity = start
    local saw_trade = false
    local trade_count = 0

    while true do
        if mq.doevents then mq.doevents() end

        if collect_locally and window_open('TradeWnd') then
            saw_trade = true
            last_activity = now_ms()
            if accept_trade() then
                trade_count = trade_count + 1
                mq.delay(350)
                reclaim_rc()
                last_activity = now_ms()
            else
                out('\ay[RC]\ax Trade with %s did not close cleanly; moving on.', name)
                break
            end
        end

        if collect_locally and item_count() > 0 then
            reclaim_rc()
            last_activity = now_ms()
        end

        local key = clean_name(name)
        if done[key] then
            if now_ms() - last_activity >= IDLE_AFTER_DONE_MS then break end
        elseif saw_trade then
            if now_ms() - last_activity >= IDLE_AFTER_TRADE_MS then break end
        elseif now_ms() - start >= FIRST_ACTIVITY_TIMEOUT_MS then
            out('\ay[RC]\ax Timed out waiting for %s.', name)
            break
        end

        mq.delay(100)
    end

    if collect_locally then
        reclaim_rc()
        local after_alt = read_rc()
        local after_inv = item_count()
        local received = math.max(0, (after_alt - before_alt) + math.max(0, after_inv - before_inv))
        return received, trade_count, done[clean_name(name)] == true
    end
    return 0, trade_count, done[clean_name(name)] == true
end

local function main()
    local scope, recipient, from_only, max_amount = parse_args()
    local send_chunk = (tonumber(max_amount) or 0) > 0 and math.floor(max_amount) or DEFAULT_CHUNK
    local me = me_name()
    local collect_locally = clean_name(recipient) == clean_name(me)

    if cursor_id() > 0 then
        out('\arAborting:\ax cursor item detected before start: %s.', cursor_name() ~= '' and cursor_name() or 'unknown item')
        return false
    end
    if safe_bool(function() return mq.TLO.Me.Feigning() end) then
        out('\arAborting:\ax cannot trade while feigned.')
        return false
    end
    if recipient == '' then
        out('\arAborting:\ax no recipient.')
        return false
    end
    if not collect_locally and not spawn_exists(recipient) then
        out('\arAborting:\ax recipient %s is not in zone.', recipient)
        return false
    end

    if collect_locally and item_count() > 0 then
        out('\ao[RC]\ax Reclaiming existing inventory Radiant Crystal before collection.')
        reclaim_rc()
    end

    local active = {}
    if from_only ~= '' then
        if clean_name(from_only) == clean_name(recipient) then
            out('\arAborting:\ax from and to cannot be the same (%s).', from_only)
            return false
        end
        if not spawn_exists(from_only) then
            out('\arAborting:\ax sender %s is not in zone.', from_only)
            return false
        end
        active[1] = from_only
    else
        local members = scope == 'all' and e3_members() or group_members()
        for _, name in ipairs(members) do
            if clean_name(name) ~= clean_name(recipient) and spawn_exists(name) then
                active[#active + 1] = name
            end
        end
    end

    if #active == 0 then
        out('\arNo %s members found in-zone to move RC from (recipient %s excluded).',
            from_only ~= '' and 'named' or (scope == 'all' and 'E3' or 'group'), recipient)
        return false
    end

    if collect_locally and free_inventory() <= 0 and item_count() <= 0 then
        out('\ayWarning:\ax no free inventory slots. Incoming RC may fail if it cannot stack.')
    end

    out('\ao[RC]\ax %s -> \ag%s\ax from %d sender(s) (%s).',
        collect_locally and 'Collect' or 'Give',
        recipient,
        #active,
        from_only ~= '' and ('from ' .. from_only)
            or (scope == 'all' and 'E3 peers' or 'group'))

    register_done_events()

    local total_received, sent_count, responded = 0, 0, 0
    local passes, empty_passes = 0, 0

    for pass = 1, MAX_PASSES do
        passes = pass
        local pass_received = 0
        local pass_activity = 0
        for _, name in ipairs(active) do
            ask_sender(name, recipient, send_chunk)
            local got, trades, signaled = wait_sender(name, collect_locally)
            sent_count = sent_count + 1
            if signaled or trades > 0 then
                responded = responded + 1
                pass_activity = pass_activity + 1
            end
            total_received = total_received + got
            pass_received = pass_received + got
            if got > 0 then
                out('\ao[RC]\ax Pass %d: %s delivered \ag%d\ax RC. You now have \ag%d\ax.',
                    pass, name, got, read_rc())
            elseif signaled then
                out('\ao[RC]\ax Pass %d: %s signaled done.', pass, name)
            end
            mq.delay(350)
        end

        if collect_locally then
            if pass_received <= 0 then
                empty_passes = empty_passes + 1
            else
                empty_passes = 0
            end
        else
            if pass_activity <= 0 then
                empty_passes = empty_passes + 1
            else
                empty_passes = 0
            end
        end
        if empty_passes >= 1 then break end
    end

    unregister_done_events()
    if collect_locally then
        reclaim_rc()
    end
    clear_cursor('finishing', 4000)
    close_inventory()

    if collect_locally then
        out('\agComplete\ax after \ag%d\ax pass(es). \ag%d\ax/\ag%d\ax requests returned activity. Total received/reclaimed: \ag%d\ax RC. You now have \ag%d\ax.',
            passes, responded, sent_count, total_received, read_rc())
    else
        out('\agComplete\ax after \ag%d\ax pass(es). \ag%d\ax/\ag%d\ax senders signaled. Recipient: \ag%s\ax.',
            passes, responded, sent_count, recipient)
    end
    return true
end

local ok, err = pcall(main)
unregister_done_events()
if not ok then
    out('\arERROR:\ax %s', tostring(err))
end
