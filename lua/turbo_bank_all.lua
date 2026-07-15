--[[
  turbo_bank_all.lua - Bank every item in your bags at the nearest banker.
  @version lua/turbo_bank_all.lua 1.0.0

  Usage:
    /lua run turbo_bank_all

  Deposits all items from pack1-pack10 via the bank window. Stops safely when
  the bank appears full (autobank leaves the item on cursor). Based on
  TurboLoot.mac BankItem/AutoBank and TurboGive.mac FindAndOpenBank.
]]

local mq = require('mq')

local TAG = '\at[TurboBank]\ax'
local MAX_BANK_SLOTS = 24
local BANKER_DIST = 10
local NAV_TIMEOUT_MS = 20000

local bank_full = false
local items_banked = 0
local items_skipped = 0

local function out(fmt, ...)
    local msg = select('#', ...) > 0 and string.format(fmt, ...) or tostring(fmt or '')
    if _G.printf then
        printf('%s %s', TAG, msg)
    else
        print(TAG .. ' ' .. msg)
    end
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

local function now_ms()
    return (mq.gettime and mq.gettime()) or (os.time() * 1000)
end

local function window_open(name)
    return safe_bool(function() return mq.TLO.Window(name).Open() end)
end

local function cursor_id()
    return safe_num(function() return mq.TLO.Cursor.ID() end)
end

local function cursor_name()
    return tostring(safe_call('', function() return mq.TLO.Cursor.Name() end) or '')
end

local function target_valid_banker()
    local id = safe_num(function() return mq.TLO.Target.ID() end)
    if id <= 0 then return false end
    if id == safe_num(function() return mq.TLO.Me.ID() end) then return false end
    local typ = tostring(safe_call('', function() return mq.TLO.Target.Type() end) or ''):lower()
    if typ == 'pc' then return false end
    return typ == 'banker' or typ == 'npc'
end

local function pack_slots(pack_num)
    return safe_num(function() return mq.TLO.Me.Inventory('pack' .. pack_num).Container() end)
end

local function pack_item_name(pack_num, slot_num)
    return tostring(safe_call('', function()
        return mq.TLO.Me.Inventory('pack' .. pack_num).Item(slot_num).Name()
    end) or '')
end

local function pack_item_link(pack_num, slot_num)
    return tostring(safe_call('', function()
        return mq.TLO.Me.Inventory('pack' .. pack_num).Item(slot_num).ItemLink('CLICKABLE')()
    end) or pack_item_name(pack_num, slot_num))
end

local function is_empty_name(name)
    name = tostring(name or '')
    return name == '' or name:lower() == 'null'
end

local function clear_cursor()
    if cursor_id() <= 0 then return true end
    if not window_open('InventoryWindow') then
        mq.cmd('/keypress i')
        mq.delay(300, function() return window_open('InventoryWindow') end)
    end
    if window_open('InventoryWindow') then
        mq.cmd('/notify InventoryWindow IW_CharacterView leftmouseup')
        mq.delay(250, function() return cursor_id() == 0 end)
    end
    if cursor_id() > 0 then
        mq.cmd('/autoinventory')
        mq.delay(250, function() return cursor_id() == 0 end)
    end
    return cursor_id() == 0
end

local function accept_quantity_window()
    if not window_open('QuantityWnd') then return end
    mq.cmd('/notify QuantityWnd QTYW_Accept_Button leftmouseup')
    mq.delay(100, function() return not window_open('QuantityWnd') end)
    if window_open('QuantityWnd') then
        mq.cmd('/notify QuantityWnd AcceptButton leftmouseup')
        mq.delay(100, function() return not window_open('QuantityWnd') end)
    end
    if window_open('QuantityWnd') then
        mq.cmd('/keypress enter')
        mq.delay(100, function() return not window_open('QuantityWnd') end)
    end
end

local function count_free_top_bank_slots()
    local free = 0
    for i = 1, MAX_BANK_SLOTS do
        local bank = mq.TLO.Me.Bank(i)
        if not bank() then
            free = free + 1
        else
            local id = safe_num(function() return bank.ID() end)
            if id <= 0 then free = free + 1 end
        end
    end
    return free
end

local function nav_to_target(max_dist)
    local tid = safe_num(function() return mq.TLO.Target.ID() end)
    if tid <= 0 then return false end
    if safe_num(function() return mq.TLO.Target.Distance() end) <= max_dist then return true end

    local started = now_ms()
    if safe_bool(function()
        return mq.TLO.Navigation and mq.TLO.Navigation.PathExists('id ' .. tid)()
    end) then
        mq.cmdf('/squelch /nav id %d distance=%d', tid, max_dist)
        while now_ms() - started < NAV_TIMEOUT_MS do
            mq.doevents()
            if safe_num(function() return mq.TLO.Target.Distance() end) <= max_dist then
                mq.cmd('/squelch /nav stop')
                return true
            end
            if not safe_bool(function() return mq.TLO.Navigation.Active() end) then break end
            mq.delay(50)
        end
        mq.cmd('/squelch /nav stop')
    end

    local tries = 0
    while tries < 40 and now_ms() - started < NAV_TIMEOUT_MS do
        tries = tries + 1
        if safe_num(function() return mq.TLO.Target.ID() end) ~= tid then return false end
        if safe_num(function() return mq.TLO.Target.Distance() end) <= max_dist then return true end
        mq.cmdf('/squelch /face fast')
        mq.cmdf('/squelch /moveto id %d dist %d', tid, max_dist)
        mq.delay(100)
        mq.doevents()
    end
    return safe_num(function() return mq.TLO.Target.Distance() end) <= (max_dist + 2)
end

local function find_and_open_bank()
    if window_open('BigBankWnd') then
        out('\agBank window already open.')
        return true
    end

    if safe_bool(function() return mq.TLO.Me.Feigning() end) then
        out('\arCannot bank while feigned. Stand up first.')
        return false
    end

    if safe_bool(function() return mq.TLO.Me.Levitating() end) then
        mq.cmd('/removelev')
        mq.delay(200, function() return not mq.TLO.Me.Levitating() end)
    end

    mq.cmd('/target clear')
    mq.delay(50)

    if target_valid_banker() and safe_num(function() return mq.TLO.Target.Distance() end) <= BANKER_DIST then
        mq.cmd('/click right target')
        mq.delay(1500, function() return window_open('BigBankWnd') end)
        if window_open('BigBankWnd') then
            out('\agBank window opened (targeted banker).')
            return true
        end
    end

    mq.cmd('/squelch /target npc banker')
    mq.delay(200)
    if not target_valid_banker() then
        mq.cmd('/squelch /target npc banker radius 200')
        mq.delay(200)
    end

    if not target_valid_banker() then
        out('\arNo banker found nearby (200 radius). Target a banker and run again.')
        return false
    end

    out('\ayFound banker: \aw%s\ay (distance \aw%.1f\ay).',
        tostring(safe_call('', function() return mq.TLO.Target.CleanName() end) or 'banker'),
        safe_num(function() return mq.TLO.Target.Distance() end))

    if safe_num(function() return mq.TLO.Target.Distance() end) > BANKER_DIST then
        out('\ayNavigating to banker...')
        if not nav_to_target(BANKER_DIST) then
            out('\ayCould not fully reach banker - trying to open bank anyway.')
        end
    end

    mq.cmd('/face fast')
    mq.delay(100)
    mq.cmd('/click right target')
    mq.delay(2000, function() return window_open('BigBankWnd') end)

    if window_open('BigBankWnd') then
        out('\agBank window opened.')
        return true
    end

    out('\arFailed to open bank window. Target the banker, open bank manually, and run again.')
    return false
end

local function close_bank()
    if not window_open('BigBankWnd') then return end
    mq.cmd('/notify BigBankWnd DoneButton leftmouseup')
    mq.delay(500, function() return not window_open('BigBankWnd') end)
    if window_open('BigBankWnd') then
        mq.cmd('/windowstate BigBankWnd close')
    end
end

local function return_cursor_to_pack(pack_num, slot_num)
    if cursor_id() <= 0 then return true end
    clear_cursor()
    if cursor_id() > 0 and pack_num > 0 and slot_num > 0 then
        mq.cmdf('/nomodkey /itemnotify in pack%d %d leftmouseup', pack_num, slot_num)
        mq.delay(250, function() return cursor_id() == 0 end)
    end
    return cursor_id() == 0
end

local function deposit_cursor_item()
    mq.cmd('/notify BigBankWnd BIGB_AutoButton leftmouseup')
    mq.delay(300, function() return cursor_id() == 0 end)
    if cursor_id() > 0 then
        mq.cmd('/notify BigBankWnd BIGB_AutoButton leftmouseup')
        mq.delay(300, function() return cursor_id() == 0 end)
    end
    return cursor_id() == 0
end

local function bank_pack_slot(pack_num, slot_num)
    if bank_full then return 'full' end
    if not window_open('BigBankWnd') then
        out('\arBank window closed during scan.')
        return 'closed'
    end

    local item_name = pack_item_name(pack_num, slot_num)
    if is_empty_name(item_name) then return 'empty' end
    local item_display = pack_item_link(pack_num, slot_num)

    if count_free_top_bank_slots() <= 0 then
        local container_slots = safe_num(function()
            return mq.TLO.Me.Inventory('pack' .. pack_num).Item(slot_num).Container()
        end)
        local stackable = safe_bool(function()
            return mq.TLO.Me.Inventory('pack' .. pack_num).Item(slot_num).Stackable()
        end)
        if container_slots > 0 and not stackable then
            items_skipped = items_skipped + 1
            out('\aySkipping container \aw%s\ay - no empty top-level bank slots.', item_display)
            return 'skip'
        end
    end

    if cursor_id() > 0 and not clear_cursor() then
        out('\arCould not clear cursor. Stopping.')
        bank_full = true
        return 'fail'
    end

    mq.cmdf('/nomodkey /shift /itemnotify in pack%d %d leftmouseup', pack_num, slot_num)
    mq.delay(150, function() return cursor_id() > 0 or window_open('QuantityWnd') end)
    accept_quantity_window()

    if cursor_id() <= 0 then
        mq.cmdf('/nomodkey /shift /itemnotify in pack%d %d leftmouseup', pack_num, slot_num)
        mq.delay(150, function() return cursor_id() > 0 end)
        accept_quantity_window()
    end

    if cursor_id() <= 0 then
        return 'empty'
    end

    if not deposit_cursor_item() then
        out('\arBank full or deposit failed for \aw%s\ar. Stopping.', item_display)
        return_cursor_to_pack(pack_num, slot_num)
        if cursor_id() > 0 then
            clear_cursor()
        end
        bank_full = true
        return 'full'
    end

    items_banked = items_banked + 1
    if items_banked % 25 == 0 then
        out('\ayBanked \aw%d\ay items so far...', items_banked)
    end
    return 'ok'
end

local function bank_all_bags()
    items_banked = 0
    items_skipped = 0
    bank_full = false

    local free_slots = count_free_top_bank_slots()
    out('\ayScanning bags... (\aw%d\ay free top-level bank slots)', free_slots)
    if free_slots <= 0 then
        out('\ayNo empty top-level bank slots - will still try stacking into existing bank stacks.')
    end

    for pack_num = 1, 10 do
        if bank_full then break end
        local slots = pack_slots(pack_num)
        if slots > 0 then
            for slot_num = 1, slots do
                if bank_full then break end
                local result = bank_pack_slot(pack_num, slot_num)
                if result == 'closed' then return end
                mq.doevents()
            end
        end
    end
end

local function main()
    out('\au=======================================================')
    out('\aoStarting bag dump to bank...')

    if not find_and_open_bank() then
        return false
    end

    bank_all_bags()
    clear_cursor()
    close_bank()

    if bank_full then
        out('\agDone.\ax Banked \ag%d\ax item(s); skipped \ay%d\ax. Stopped early - bank may be full.',
            items_banked, items_skipped)
    elseif items_banked == 0 then
        out('\agDone.\ax No bag items found to bank.')
    else
        out('\agDone.\ax Banked \ag%d\ax item(s); skipped \ay%d\ax.',
            items_banked, items_skipped)
    end
    return true
end

main()
