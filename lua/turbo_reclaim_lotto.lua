--[[
  turbo_reclaim_lotto.lua - Reclaim alt-currency, open Lazarus lotto items,
  then reclaim again.
  @version lua/turbo_reclaim_lotto.lua 1.0.0
  Usage: /lua run turbo_reclaim_lotto
]]

local mq = require('mq')

local TAG = '\at[TurboRL]\ax'
local MAX_PASSES = 12
local MAX_STALLS = 3

local RECLAIM_ITEMS = {
    { item = 'Celestial Crest', list = 'Celestial Crests' },
    { item = 'Diamond Coin', list = 'Diamond Coins' },
    { item = 'Gold Coin', list = 'Gold Coins' },
    { item = 'Planar Symbol', list = 'Planar Symbols' },
    { item = 'Taelosian Symbol', list = 'Taelosian Symbols' },
}

local STACKABLE_PRIZES = {
    'Resplendent Coin',
    'Glimmering Coin',
    'Tarnished Coin',
}

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

local function quote(s)
    return tostring(s or ''):gsub('\\', '\\\\'):gsub('"', '\\"')
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

local function item_count(name, exact)
    local query = exact and ('=' .. tostring(name or '')) or tostring(name or '')
    if query == '' or query == '=' then return 0 end
    return safe_num(function() return mq.TLO.FindItemCount(query)() end)
end

local function has_item(name, exact)
    local query = exact and ('=' .. tostring(name or '')) or tostring(name or '')
    if query == '' or query == '=' then return false end
    return safe_num(function() return mq.TLO.FindItem(query).ID() end) > 0
end

local function cursor_id()
    return safe_num(function() return mq.TLO.Cursor.ID() end)
end

local function cursor_name()
    return tostring(safe_call('', function() return mq.TLO.Cursor.Name() end) or '')
end

local function free_inventory()
    return safe_num(function() return mq.TLO.Me.FreeInventory() end)
end

local function item_ready(name)
    return safe_bool(function() return mq.TLO.Me.ItemReady(name)() end)
end

local function item_timer(name)
    return safe_num(function() return mq.TLO.FindItem('=' .. name).Timer() end)
end

local function window_open(name)
    return safe_bool(function() return mq.TLO.Window(name).Open() end)
end

local function clear_cursor(context, timeout_ms)
    timeout_ms = tonumber(timeout_ms) or 5000
    local deadline = now_ms() + timeout_ms
    local tries = 0
    while cursor_id() > 0 and now_ms() < deadline do
        tries = tries + 1
        mq.cmd('/autoinventory')
        mq.delay(250, function() return cursor_id() == 0 end)
        if cursor_id() > 0 then
            mq.cmd('/autoinv')
            mq.delay(250, function() return cursor_id() == 0 end)
        end
        if tries >= 20 then break end
    end
    if cursor_id() > 0 then
        out('\arWARNING:\ax Cursor still has %s while %s. Inventory may be full.',
            cursor_name() ~= '' and cursor_name() or 'an item',
            context or 'clearing cursor')
        return false
    end
    return true
end

local function effective_prize_space()
    local free = free_inventory()
    if free > 3 then return free end
    local effective = free
    for _, name in ipairs(STACKABLE_PRIZES) do
        if item_count(name, false) < 800 then
            effective = effective + 1
        end
    end
    return effective
end

local function ensure_prize_space(context)
    if effective_prize_space() > 3 then return true end
    out('\arAborting:\ax not enough free inventory space for possible prizes while %s.', context or 'opening lotto items')
    return false
end

local function wait_ready(name, timeout_ms)
    timeout_ms = tonumber(timeout_ms) or 5000
    if item_ready(name) then return true end
    mq.delay(timeout_ms, function() return item_ready(name) end)
    return item_ready(name)
end

local function wait_cast_done()
    mq.delay(500, function()
        return safe_num(function() return mq.TLO.Me.Casting.ID() end) > 0
    end)
    if safe_num(function() return mq.TLO.Me.Casting.ID() end) > 0 then
        mq.delay(10000, function()
            return safe_num(function() return mq.TLO.Me.Casting.ID() end) == 0
        end)
    end
end

local function has_reclaim_currency()
    for _, rec in ipairs(RECLAIM_ITEMS) do
        if item_count(rec.item, false) > 0 then return true end
    end
    return false
end

local function ensure_inventory_window()
    if window_open('InventoryWindow') then return true end
    safe_call(nil, function() return mq.TLO.Window('InventoryWindow').DoOpen() end)
    mq.delay(700, function() return window_open('InventoryWindow') end)
    if window_open('InventoryWindow') then return true end
    out('\arWARNING:\ax could not open InventoryWindow for reclaim.')
    return false
end

local function alt_currency_list_id(label)
    return safe_num(function()
        return mq.TLO.Window('InventoryWindow').Child('IW_AltCurr_PointList').List('=' .. label, 2)()
    end)
end

local function reclaim_alt_currency()
    if not has_reclaim_currency() then return 0 end
    mq.cmd('/e3p on')
    mq.delay(100)
    if not ensure_inventory_window() then
        mq.cmd('/e3p off')
        return 0
    end

    mq.cmd('/nomodkey /notify InventoryWindow IW_Subwindows tabselect 5')
    mq.delay(300)

    local clicks = 0
    for _, rec in ipairs(RECLAIM_ITEMS) do
        if item_count(rec.item, false) > 0 then
            local list_id = alt_currency_list_id(rec.list)
            if list_id > 0 then
                mq.cmd(string.format('/nomodkey /notify InventoryWindow IW_AltCurr_PointList listselect %d leftmouseup', list_id))
                mq.delay(150)
                mq.cmd('/nomodkey /notify InventoryWindow IW_AltCurr_Reclaimbutton leftmouseup')
                clicks = clicks + 1
                mq.delay(250)
            else
                out('\aySkipped reclaim:\ax could not find %s in alt-currency list.', rec.list)
            end
        end
    end
    mq.cmd('/e3p off')
    return clicks
end

local function use_lucky_coins()
    local opened = 0
    local stalls = 0
    while item_count('Lucky Coin', true) > 0 do
        if cursor_id() > 0 and not clear_cursor('starting Lucky Coin') then return opened, false end
        if not ensure_prize_space('using Lucky Coin') then return opened, false end
        if not has_item('Lucky Coin', true) then break end
        if not wait_ready('Lucky Coin', 6000) then
            stalls = stalls + 1
            if stalls >= MAX_STALLS then
                out('\ayStopping Lucky Coins:\ax Lucky Coin did not become ready after %d waits.', stalls)
                return opened, false
            end
            mq.delay(500)
        else
            local before = item_count('Lucky Coin', true)
            mq.cmd('/useitem "Lucky Coin"')
            mq.delay(750, function()
                return cursor_id() > 0 or item_count('Lucky Coin', true) < before
            end)
            if cursor_id() > 0 and not clear_cursor('using Lucky Coin') then return opened, false end
            mq.delay(1500, function() return item_count('Lucky Coin', true) < before end)
            local after = item_count('Lucky Coin', true)
            if after < before then
                opened = opened + (before - after)
                stalls = 0
                mq.delay(250)
            else
                stalls = stalls + 1
                if stalls >= MAX_STALLS then
                    out('\ayStopping Lucky Coins:\ax count did not decrease after %d attempts.', stalls)
                    return opened, false
                end
                mq.delay(500)
            end
        end
    end
    return opened, true
end

local function click_inventory_item(name)
    mq.cmd(string.format('/itemnotify "%s" rightmouseup', quote(name)))
end

local function use_guarded_clickies(name, label)
    local opened = 0
    local stalls = 0
    while item_count(name, true) > 0 do
        if cursor_id() > 0 and not clear_cursor('starting ' .. label) then return opened, false end
        if not ensure_prize_space('using ' .. label) then return opened, false end
        if not has_item(name, true) then break end

        local timer = item_timer(name)
        if timer > 0 then
            mq.delay(math.min(timer * 1000 + 300, 12000))
        end

        local before = item_count(name, true)
        click_inventory_item(name)
        wait_cast_done()
        mq.delay(1100)
        if cursor_id() > 0 and not clear_cursor('using ' .. label) then return opened, false end
        mq.delay(1500, function() return item_count(name, true) < before end)

        local after = item_count(name, true)
        if after < before then
            opened = opened + (before - after)
            stalls = 0
        else
            stalls = stalls + 1
            if stalls >= MAX_STALLS then
                out('\ayStopping %s:\ax count did not decrease after %d attempts.', label, stalls)
                return opened, false
            end
            mq.delay(500)
        end
    end
    return opened, true
end

local function close_inventory()
    if window_open('InventoryWindow') then
        mq.cmd('/nomodkey /notify InventoryWindow DoneButton leftmouseup')
        mq.delay(500, function() return not window_open('InventoryWindow') end)
    end
    if window_open('InventoryWindow') then
        mq.cmd('/windowstate InventoryWindow close')
    end
end

local function has_lotto_work()
    return item_count('Lucky Coin', true) > 0
        or item_count('A Lucky Ticket', true) > 0
        or item_count("Spelunker's Supply Sack", true) > 0
        or item_count('Bag of Gems', true) > 0
end

local function record_gains_history(summary)
    local ok, history = pcall(require, 'Turbo.gains_history')
    if not ok or type(history) ~= 'table' or type(history.append_event) ~= 'function' then
        out('\ayHistory skipped:\ax TurboGains history helper unavailable.')
        return
    end

    local totalOpened = (tonumber(summary.coins) or 0)
        + (tonumber(summary.tickets) or 0)
        + (tonumber(summary.sacks) or 0)
        + (tonumber(summary.gems) or 0)
    local wrote, err = history.append_event({
        kind = 'reclaim_lotto',
        source = 'turbo_reclaim_lotto',
        label = 'Reclaim + Lotto',
        passes = tonumber(summary.passes) or 0,
        reclaim = tonumber(summary.reclaim) or 0,
        coins = tonumber(summary.coins) or 0,
        tickets = tonumber(summary.tickets) or 0,
        sacks = tonumber(summary.sacks) or 0,
        gems = tonumber(summary.gems) or 0,
        opened = totalOpened,
    })
    if not wrote then
        out('\ayHistory skipped:\ax %s', tostring(err or 'write failed'))
    end
end

local function main()
    out('Starting Reclaim + Lotto.')

    local server = tostring(safe_call('', function() return mq.TLO.EverQuest.Server() end) or '')
    if server ~= 'Project Lazarus' then
        out('\arAborting:\ax intended for Project Lazarus; detected server is "%s".', server ~= '' and server or 'unknown')
        return false
    end

    if cursor_id() > 0 then
        out('\arAborting:\ax cursor item detected before start: %s.', cursor_name() ~= '' and cursor_name() or 'unknown item')
        return false
    end

    local summary = {
        reclaim = 0,
        coins = 0,
        tickets = 0,
        sacks = 0,
        gems = 0,
        passes = 0,
    }

    for pass = 1, MAX_PASSES do
        summary.passes = pass
        local progress = 0

        local reclaimed = reclaim_alt_currency()
        summary.reclaim = summary.reclaim + reclaimed
        progress = progress + reclaimed

        local coins, coins_ok = use_lucky_coins()
        summary.coins = summary.coins + coins
        progress = progress + coins
        if not coins_ok then break end

        local tickets, tickets_ok = use_guarded_clickies('A Lucky Ticket', 'Lucky Tickets')
        summary.tickets = summary.tickets + tickets
        progress = progress + tickets
        if not tickets_ok then break end

        local sacks, sacks_ok = use_guarded_clickies("Spelunker's Supply Sack", 'Supply Sacks')
        summary.sacks = summary.sacks + sacks
        progress = progress + sacks
        if not sacks_ok then break end

        local gems, gems_ok = use_guarded_clickies('Bag of Gems', 'Gem Bags')
        summary.gems = summary.gems + gems
        progress = progress + gems
        if not gems_ok then break end

        if progress == 0 then break end
        if not has_lotto_work() and not has_reclaim_currency() then break end
        mq.delay(300)
    end

    local final_reclaim = reclaim_alt_currency()
    summary.reclaim = summary.reclaim + final_reclaim

    clear_cursor('finishing', 4000)
    close_inventory()

    out('\agDone.\ax Passes: \ay%d\ax. Reclaim clicks: \ag%d\ax. Lotto opened: \ag%d\ax (coins \ay%d\ax, tickets \ay%d\ax, sacks \ay%d\ax, gems \ay%d\ax).',
        summary.passes,
        summary.reclaim,
        summary.coins + summary.tickets + summary.sacks + summary.gems,
        summary.coins,
        summary.tickets,
        summary.sacks,
        summary.gems)
    record_gains_history(summary)
    return true
end

main()
