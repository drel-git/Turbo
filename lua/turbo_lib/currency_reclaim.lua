-- turbo_lib/currency_reclaim.lua
-- One-shot exact alt-currency reclaim helpers for stack currency items.

local mq = require('mq')
local core = require('turbo_lib.core')
local bot_pause = require('turbo_lib.bot_pause')

local M = {}

M.CURRENCIES = {
    dc = {
        key = 'dc',
        label = 'Diamond Coins',
        item = 'Diamond Coin',
        alt = 'Diamond Coins',
        alt_singular = 'Diamond Coin',
        send_mode = '_senddc',
    },
    ps = {
        key = 'ps',
        label = 'Planar Symbols',
        item = 'Planar Symbol',
        alt = 'Planar Symbols',
        alt_singular = 'Planar Symbol',
        send_mode = '_sendps',
    },
    ts = {
        key = 'ts',
        label = 'Taelosian Symbols',
        item = 'Taelosian Symbol',
        alt = 'Taelosian Symbols',
        alt_singular = 'Taelosian Symbol',
        send_mode = '_sendts',
    },
}

function M.currency_from_key(key)
    key = tostring(key or ''):lower()
    if key == 'diamond' or key == 'diamond_coin' or key == 'diamond_coins' then key = 'dc' end
    if key == 'planar' or key == 'planar_symbols' then key = 'ps' end
    if key == 'taelosian' or key == 'taelosian_symbols' then key = 'ts' end
    return M.CURRENCIES[key], key
end

local function exact_count(item)
    return core.item_count('=' .. tostring(item or ''), false)
end

local function alt_list_id(meta)
    local id = core.alt_currency_list_id(meta.alt)
    if id <= 0 and meta.alt_singular then
        id = core.alt_currency_list_id(meta.alt_singular)
    end
    return id
end

function M.reclaim_one(meta, opts)
    opts = opts or {}
    local out = opts.out
    if type(meta) ~= 'table' then return 'fail_list', 0 end
    if core.cursor_id() > 0 then return 'fail_cursor', 0 end

    local inventory_was_open = core.window_open('InventoryWindow')
    local before = exact_count(meta.item)
    if before <= 0 then
        if opts.close and not inventory_was_open then core.close_inventory() end
        return 'empty', 0
    end

    bot_pause.pause()
    local ok, status, qty = pcall(function()
        if not core.ensure_inventory_window(out) then return 'fail_inventory', 0 end

        mq.cmd('/nomodkey /notify InventoryWindow IW_Subwindows tabselect 5')
        mq.delay(300)

        local list_id = alt_list_id(meta)
        if list_id <= 0 then return 'fail_list', 0 end

        mq.cmdf('/nomodkey /notify InventoryWindow IW_AltCurr_PointList listselect %d leftmouseup', list_id)
        mq.delay(150)

        mq.cmd('/nomodkey /notify InventoryWindow AltCurr_ReclaimButton leftmouseup')
        mq.delay(800, function() return exact_count(meta.item) < before end)
        if exact_count(meta.item) >= before then
            mq.cmd('/nomodkey /notify InventoryWindow IW_AltCurr_Reclaimbutton leftmouseup')
            mq.delay(800, function() return exact_count(meta.item) < before end)
        end

        local after = exact_count(meta.item)
        local reclaimed = math.max(0, before - after)
        if reclaimed > 0 then return 'ok', reclaimed end
        return 'fail_reclaim', 0
    end)
    bot_pause.resume()
    if opts.close and not inventory_was_open then core.close_inventory() end
    if not ok then
        if out then out('\arReclaim error:\ax %s', tostring(status)) end
        return 'fail_reclaim', 0
    end
    return status, qty or 0
end

return M
