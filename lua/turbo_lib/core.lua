-- turbo_lib/core.lua
-- Shared TLO helpers, cursor/trade/inventory, and alt-currency reclaim.

local mq = require('mq')
local bot_pause = require('turbo_lib.bot_pause')

local M = {}

M.RECLAIM_ITEMS = {
    { item = 'Celestial Crest', list = 'Celestial Crests' },
    { item = 'Diamond Coin', list = 'Diamond Coins' },
    { item = 'Gold Coin', list = 'Gold Coins' },
    { item = 'Planar Symbol', list = 'Planar Symbols' },
    { item = 'Taelosian Symbol', list = 'Taelosian Symbols' },
}

function M.now_ms()
    return (mq.gettime and mq.gettime()) or (os.time() * 1000)
end

function M.safe_call(default, fn)
    local ok, value = pcall(fn)
    if ok and value ~= nil then return value end
    return default
end

function M.safe_num(fn)
    return tonumber(M.safe_call(0, fn)) or 0
end

function M.safe_bool(fn)
    return M.safe_call(false, fn) and true or false
end

function M.me_name()
    return tostring(M.safe_call('', function() return mq.TLO.Me.CleanName() end)
        or M.safe_call('', function() return mq.TLO.Me.Name() end)
        or '')
end

function M.item_count(name, exact)
    local query = exact and ('=' .. tostring(name or '')) or tostring(name or '')
    if query == '' or query == '=' then return 0 end
    return M.safe_num(function() return mq.TLO.FindItemCount(query)() end)
end

function M.has_item(name, exact)
    local query = exact and ('=' .. tostring(name or '')) or tostring(name or '')
    if query == '' or query == '=' then return false end
    return M.safe_num(function() return mq.TLO.FindItem(query).ID() end) > 0
end

function M.free_inventory()
    return M.safe_num(function() return mq.TLO.Me.FreeInventory() end)
end

function M.cursor_id()
    return M.safe_num(function() return mq.TLO.Cursor.ID() end)
end

function M.cursor_name()
    return tostring(M.safe_call('', function() return mq.TLO.Cursor.Name() end) or '')
end

function M.window_open(name)
    return M.safe_bool(function() return mq.TLO.Window(name).Open() end)
end

function M.platinum()
    return M.safe_num(function() return mq.TLO.Me.Platinum() end)
end

function M.read_alt_dc()
    local n = M.safe_num(function()
        local t = mq.TLO.Me.AltCurrency('Diamond Coins')
        return t and t() or 0
    end)
    if n > 0 then return n end
    return M.safe_num(function() return mq.TLO.Me.AltCurrency(20)() end)
end

function M.clear_cursor(context, timeout_ms, out_fn)
    local deadline = M.now_ms() + (tonumber(timeout_ms) or 5000)
    local tries = 0
    while M.cursor_id() > 0 and M.now_ms() < deadline do
        tries = tries + 1
        mq.cmd('/autoinventory')
        mq.delay(250, function() return M.cursor_id() == 0 end)
        if M.cursor_id() > 0 then
            mq.cmd('/autoinv')
            mq.delay(250, function() return M.cursor_id() == 0 end)
        end
        if tries >= 20 then break end
    end
    if M.cursor_id() > 0 then
        if out_fn then
            out_fn('\arWARNING:\ax cursor still has %s while %s.',
                M.cursor_name() ~= '' and M.cursor_name() or 'an item',
                context or 'clearing cursor')
        end
        return false
    end
    return true
end

function M.ensure_inventory_window(out_fn)
    if M.window_open('InventoryWindow') then return true end
    M.safe_call(nil, function() return mq.TLO.Window('InventoryWindow').DoOpen() end)
    mq.delay(700, function() return M.window_open('InventoryWindow') end)
    if M.window_open('InventoryWindow') then return true end
    if out_fn then out_fn('\arWARNING:\ax could not open InventoryWindow.') end
    return false
end

function M.close_inventory()
    if M.window_open('InventoryWindow') then
        mq.cmd('/nomodkey /notify InventoryWindow DoneButton leftmouseup')
        mq.delay(500, function() return not M.window_open('InventoryWindow') end)
    end
    if M.window_open('InventoryWindow') then
        mq.cmd('/windowstate InventoryWindow close')
    end
end

function M.alt_currency_list_id(label)
    return M.safe_num(function()
        return mq.TLO.Window('InventoryWindow').Child('IW_AltCurr_PointList').List('=' .. label, 2)()
    end)
end

function M.accept_trade()
    if not M.window_open('TradeWnd') then return false end
    mq.cmd('/notify TradeWnd TRDW_Trade_Button leftmouseup')
    mq.delay(1200, function() return not M.window_open('TradeWnd') end)
    if M.window_open('TradeWnd') then
        mq.cmd('/notify TradeWnd TRDW_Trade_Button leftmouseup')
        mq.delay(2000, function() return not M.window_open('TradeWnd') end)
    end
    return not M.window_open('TradeWnd')
end

function M.has_reclaim_currency(items)
    items = items or M.RECLAIM_ITEMS
    for _, rec in ipairs(items) do
        if M.item_count(rec.item, false) > 0 then return true end
    end
    return false
end

function M.reclaim_alt_currency(opts)
    opts = opts or {}
    local items = opts.items or M.RECLAIM_ITEMS
    local out_fn = opts.out
    local quiet = opts.quiet == true

    if not M.has_reclaim_currency(items) then return 0 end
    bot_pause.pause()
    mq.delay(100)
    if not M.ensure_inventory_window(out_fn) then
        bot_pause.resume()
        return 0
    end

    mq.cmd('/nomodkey /notify InventoryWindow IW_Subwindows tabselect 5')
    mq.delay(300)

    local clicks = 0
    for _, rec in ipairs(items) do
        if M.item_count(rec.item, false) > 0 then
            local list_id = M.alt_currency_list_id(rec.list)
            if list_id > 0 then
                mq.cmd(string.format('/nomodkey /notify InventoryWindow IW_AltCurr_PointList listselect %d leftmouseup', list_id))
                mq.delay(150)
                mq.cmd('/nomodkey /notify InventoryWindow IW_AltCurr_Reclaimbutton leftmouseup')
                clicks = clicks + 1
                mq.delay(250)
            elseif out_fn and not quiet then
                out_fn('\aySkipped reclaim:\ax could not find %s in alt-currency list.', rec.list)
            end
        end
    end
    bot_pause.resume()
    return clicks
end

function M.reclaim_diamond_coin(out_fn)
    if M.item_count('Diamond Coin', true) <= 0 then return 0 end
    bot_pause.pause()
    mq.delay(100)
    if not M.ensure_inventory_window(out_fn) then
        bot_pause.resume()
        return 0
    end

    mq.cmd('/nomodkey /notify InventoryWindow IW_Subwindows tabselect 5')
    mq.delay(250)

    local id = M.alt_currency_list_id('Diamond Coins')
    if id <= 0 then
        id = M.alt_currency_list_id('Diamond Coin')
    end
    if id <= 0 then
        if out_fn then out_fn('\aySkipped reclaim:\ax could not find Diamond Coins in the alt-currency list.') end
        bot_pause.resume()
        return 0
    end

    local before_inv = M.item_count('Diamond Coin', true)
    local before_alt = M.read_alt_dc()
    mq.cmdf('/nomodkey /notify InventoryWindow IW_AltCurr_PointList listselect %d leftmouseup', id)
    mq.delay(120)
    mq.cmd('/nomodkey /notify InventoryWindow AltCurr_ReclaimButton leftmouseup')
    mq.delay(800, function()
        return M.item_count('Diamond Coin', true) < before_inv or M.read_alt_dc() > before_alt
    end)
    if M.item_count('Diamond Coin', true) >= before_inv then
        mq.cmd('/nomodkey /notify InventoryWindow IW_AltCurr_Reclaimbutton leftmouseup')
        mq.delay(800, function()
            return M.item_count('Diamond Coin', true) < before_inv or M.read_alt_dc() > before_alt
        end)
    end
    bot_pause.resume()
    return math.max(0, before_inv - M.item_count('Diamond Coin', true))
end

return M
