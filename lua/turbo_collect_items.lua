--[[
  turbo_collect_items.lua - generic preset item collector for TurboGear.

  First-pass usage:
    /lua run turbo_collect_items list A,B,C to Collector preset sebilis_armor

  The coordinator runs on the driver. Each sender runs this same Lua only long
  enough to count one preset item, then hands off to TurboGive.mac's safe stack
  send path. The sender Lua must not wait on TurboGive, because MacroQuest only
  runs one macro and one Lua lifecycle cleanly when each owns its own step.
]]

local mq = require('mq')
local core = require('turbo_lib.core')
local orch = require('turbo_lib.orchestrate')

local TAG = '\at[TurboItems]\ax'
local ITEM_TIMEOUT_MS = 90000
local IDLE_AFTER_DONE_MS = 800

local PRESETS = {
    sebilis_armor = {
        label = 'Sebilis Armor',
        items = {
            { id = 150781, name = 'Corrosive Bile' },
            { id = 150780, name = 'Gem of Swirling Shadows' },
            { id = 150779, name = 'Sebilisian Seal of Command' },
            { id = 150782, name = 'Variegated Powder' },
        },
    },
    don_armor = {
        label = 'DoN Armor',
        items = {
            { id = 60542, name = 'Draconic Alloy Rings' },
            { id = 60541, name = 'Draconic Leather Scales' },
            { id = 60543, name = 'Draconic Sheet Metal' },
            { id = 60540, name = 'Draconic Silk Webbing' },
        },
    },
    mephit_bloods = {
        label = 'Mephit Bloods',
        items = {
            { id = 29524, name = 'Air Mephit Blood' },
            { id = 29523, name = 'Earth Mephit Blood' },
            { id = 29521, name = 'Fire Mephit Blood' },
            { id = 29522, name = 'Water Mephit Blood' },
        },
    },
    anguish_armor = {
        label = 'Anguish Armor',
        items = {
            { id = 51503, name = 'Bar of Nashtar Berry Soap' },
            { id = 51497, name = 'Bazu Nail Bracelet' },
            { id = 51484, name = 'Blackened Discordling Tail' },
            { id = 51483, name = 'Ceremonial Dragorn Candle' },
            { id = 51499, name = 'Chimera Gut String' },
            { id = 51488, name = 'Crystal of Yearning' },
            { id = 51498, name = 'Discordling Hoof' },
            { id = 51492, name = 'Dragorn Muramite Ring' },
            { id = 51502, name = 'Fine Chimera Hide' },
            { id = 51493, name = 'Ikaav Head' },
            { id = 51506, name = 'Ikaav Tail' },
            { id = 51509, name = 'Kuuan Whetstone' },
            { id = 51482, name = 'Kyv Food Sack' },
            { id = 51485, name = 'Kyv Hunter Ring' },
            { id = 51489, name = 'Kyv Scout Ring' },
            { id = 51490, name = 'Kyv Short Bow' },
            { id = 51495, name = 'Kyv Whetstone' },
            { id = 51487, name = 'Large Piece of Kuuan Ore' },
            { id = 51496, name = "Muramite Noble's March Award" },
            { id = 51486, name = 'Noc Right Hand' },
            { id = 51504, name = 'Piece of Vrenlar Fruit' },
            { id = 51501, name = 'Quality Feran Hide' },
            { id = 51508, name = 'Riftseeker Trinket' },
            { id = 51491, name = 'Shattered Ukun Hide' },
            { id = 51505, name = 'Softened Feran Hide' },
            { id = 51500, name = 'Spiked Discordling Collar' },
            { id = 51507, name = 'Spool of Balemoon Silk' },
            { id = 51494, name = 'Withered Discordling Tongue' },
        },
    },
    nvs_items = {
        label = 'NVS Items',
        items = {
            { id = 150987, name = 'Ancient Alpha Skull' },
            { id = 50429, name = 'Blacksalt Compass' },
            { id = 151046, name = 'Charred Obulus Relic' },
            { id = 50430, name = 'Coldfire Lantern' },
            { id = 50444, name = 'Crown of Radiant Dominion' },
            { id = 50448, name = 'Death Quill' },
            { id = 50467, name = 'Eternal Jack-o-Lantern' },
            { id = 151048, name = 'Fragment of Vzith' },
            { id = 50428, name = 'Glass Key to the Nowhere Door' },
            { id = 50445, name = 'Hat of the Forsaken Jester' },
            { id = 50470, name = 'Map of Midnight' },
            { id = 50449, name = 'Mirror of the Last Gaze' },
            { id = 50446, name = 'Obsidian Chalice' },
            { id = 50466, name = "Phantom's Bride Doll" },
            { id = 50427, name = 'Quill of Tomorrow' },
            { id = 50450, name = 'Scythe of Silence' },
            { id = 50468, name = 'Shroud of the Forgotten King' },
            { id = 50443, name = 'Sword of the Celestial Dawn' },
            { id = 50464, name = 'The Ash Crown' },
            { id = 50465, name = 'The Bone Violin' },
            { id = 50447, name = 'The Crimson Dice' },
            { id = 50451, name = "The Witch's Bell" },
            { id = 50469, name = 'Withered Rose' },
        },
    },
    lucky_ticket = {
        label = 'Lucky Ticket',
        items = {
            { id = 150762, name = 'A Lucky Ticket' },
        },
    },
    radiant_void = {
        label = 'Radiant + Void',
        items = {
            { id = 17699, name = 'A Radiant Morsel' },
            { id = 17729, name = 'A Placid Void' },
        },
    },
    veksar_armor = {
        label = 'Veksar Armor',
        items = {
            { id = 40838, name = 'Contaminated Armguards of the Healing Waters' },
            { id = 40870, name = 'Contaminated Boots of the Healing Waters' },
            { id = 41134, name = 'Contaminated Bracer of the Healing Waters' },
            { id = 40842, name = 'Contaminated Breastplate of the Healing Waters' },
            { id = 41133, name = 'Contaminated Gauntlets of the Healing Waters' },
            { id = 41135, name = 'Contaminated Greaves of the Healing Waters' },
            { id = 41136, name = 'Contaminated Helm of the Healing Waters' },
            { id = 40837, name = 'Corroded Kylong Darkmail Armguards' },
            { id = 40839, name = 'Corroded Kylong Darkmail Chestguard' },
            { id = 40869, name = 'Corroded Kylong Darkmail Footguards' },
            { id = 41129, name = 'Corroded Kylong Darkmail Handguards' },
            { id = 41132, name = 'Corroded Kylong Darkmail Headguard' },
            { id = 41131, name = 'Corroded Kylong Darkmail Legguards' },
            { id = 41130, name = 'Corroded Kylong Darkmail Wristguards' },
            { id = 40840, name = 'Fraying Waterlogged Silk Blouse' },
            { id = 40876, name = 'Fraying Waterlogged Silk Bracelet' },
            { id = 40875, name = 'Fraying Waterlogged Silk Gloves' },
            { id = 40878, name = 'Fraying Waterlogged Silk Headband' },
            { id = 40877, name = 'Fraying Waterlogged Silk Pantaloons' },
            { id = 40868, name = 'Fraying Waterlogged Silk Shoes' },
            { id = 40836, name = 'Fraying Waterlogged Silk Sleeves' },
            { id = 40835, name = 'Soggy Moss Covered Armwraps' },
            { id = 40871, name = 'Soggy Moss Covered Handwraps' },
            { id = 40873, name = 'Soggy Moss Covered Leggings' },
            { id = 40867, name = 'Soggy Moss Covered Sandals' },
            { id = 40874, name = 'Soggy Moss Covered Skullcap' },
            { id = 40841, name = 'Soggy Moss Covered Tunic' },
            { id = 40872, name = 'Soggy Moss Covered Wristband' },
        },
    },
    tradeskill_items = {
        label = 'Tradeskill Items',
        items = {
            { id = 10012, name = 'Black Pearl' },
            { id = 10036, name = 'Black Sapphire' },
            { id = 22503, name = 'Blue Diamond' },
            { id = 16282, name = 'Brick of Ethereal Energy' },
            { id = 34247, name = 'Cobalt Ore' },
            { id = 10037, name = 'Diamond' },
            { id = 34233, name = 'Excellent Animal Pelt' },
            { id = 34220, name = 'Excellent Silk' },
            { id = 34232, name = 'Fine Animal Pelt' },
            { id = 34219, name = 'Fine Silk' },
            { id = 10033, name = 'Fire Emerald' },
            { id = 10031, name = 'Fire Opal' },
            { id = 34244, name = 'Indium Ore' },
            { id = 10053, name = 'Jacinth' },
            { id = 35084, name = 'Lucidem' },
            { id = 16972, name = 'Mt. Death Mineral Salts' },
            { id = 34217, name = 'Natural Silk' },
            { id = 24094, name = 'Nodding Blue Lily' },
            { id = 34231, name = 'Pristine Animal Pelt' },
            { id = 34218, name = 'Pristine Silk' },
            { id = 44756, name = 'Refined Grade A Nigriventer Venom' },
            { id = 34245, name = 'Rhenium Ore' },
            { id = 10034, name = 'Sapphire' },
            { id = 10021, name = 'Star Rose Quartz' },
            { id = 10032, name = 'Star Ruby' },
            { id = 16285, name = 'Strand of Ether' },
            { id = 34234, name = 'Superb Animal Pelt' },
            { id = 34221, name = 'Superb Silk' },
            { id = 34246, name = 'Tungsten Ore' },
        },
    },
}

local args = { ... }
local item_done = {}

local function out(fmt, ...)
    local msg = select('#', ...) > 0 and string.format(fmt, ...) or tostring(fmt or '')
    if _G.printf then
        printf('%s %s', TAG, msg)
    else
        print(TAG .. ' ' .. msg)
    end
end

local function clean_name(name)
    return orch.clean_name(name)
end

local function safe_arg_name(name)
    return tostring(name or ''):match('^[%w_]+') or ''
end

local function preset_from_args()
    local selected = ''
    for i = 1, #args do
        local low = tostring(args[i] or ''):lower()
        if (low == 'preset' or low == 'set') and args[i + 1] then
            selected = tostring(args[i + 1] or ''):lower()
            break
        elseif PRESETS[low] then
            selected = low
            break
        end
    end
    if selected == '' then selected = 'sebilis_armor' end
    return PRESETS[selected], selected
end

local function parse_sender_args()
    local recipient, notify = '', ''
    local i = 1
    while i <= #args do
        local low = tostring(args[i] or ''):lower()
        if low == 'sendto' and args[i + 1] then
            recipient = safe_arg_name(args[i + 1])
            i = i + 1
        elseif low == 'notify' and args[i + 1] then
            notify = safe_arg_name(args[i + 1])
            i = i + 1
        end
        i = i + 1
    end
    return recipient, notify
end

local function item_from_args()
    for i = 1, #args do
        local low = tostring(args[i] or ''):lower()
        if low == 'item' and args[i + 1] then
            local id = tonumber(args[i + 1]) or 0
            if id > 0 then return id end
            i = i + 1
        end
    end
    return 0
end

local function send_done_signal(notify, sender)
    notify = safe_arg_name(notify)
    sender = safe_arg_name(sender)
    if sender == '' then return end
    mq.cmdf('/echo %s \\ar[DONE]\\aw %s->LOCAL', TAG, sender)
    if notify ~= '' and clean_name(notify) ~= clean_name(sender) then
        mq.cmdf('/squelch /e3bct %s /echo %s \\ar[SIGNAL_DONE]\\aw %s', notify, TAG, sender)
    end
end

local function run_sender()
    local preset, preset_key = preset_from_args()
    local recipient, notify = parse_sender_args()
    local item_id = item_from_args()
    local me = core.me_name()
    if not preset then
        out('\arAborting:\ax unknown preset.')
        return false
    end
    if recipient == '' then
        out('\arAborting:\ax missing recipient.')
        return false
    end
    if item_id <= 0 then
        out('\arAborting:\ax missing item id.')
        send_done_signal(notify, me)
        return false
    end
    if clean_name(recipient) == clean_name(me) then
        out('\arAborting:\ax sender and recipient are both %s.', recipient)
        send_done_signal(notify, me)
        return false
    end
    if not orch.preflight_trade(out) then
        send_done_signal(notify, me)
        return false
    end

    local selected = nil
    for _, item in ipairs(preset.items or {}) do
        if tonumber(item.id) == item_id then
            selected = item
            break
        end
    end
    if not selected then
        out('\arAborting:\ax item id %d is not in preset %s.', item_id, preset_key)
        send_done_signal(notify, me)
        return false
    end

    local qty = core.item_count(selected.name, true)
    if qty <= 0 then
        out('\ay[%s]\ax No %s to send.', preset.label, selected.name)
        send_done_signal(notify, me)
        return true
    end

    out('\ao[%s]\ax Sending %dx %s to \ag%s\ax.', preset.label, qty, selected.name, recipient)
    mq.cmdf('/mac turbogive _sendstack %s %d %d', recipient, tonumber(selected.id) or 0, qty)
    return true
end

local function ask_sender_item(name, recipient, preset_key, notify, item_id)
    orch.clear_done(item_done, name)
    mq.cmdf('/squelch /e3bct %s /lua run turbo_collect_items sendto %s notify %s preset %s item %d',
        name, recipient, notify, preset_key, tonumber(item_id) or 0)
end

local function ask_local_item(name, recipient, item)
    orch.clear_done(item_done, name)
    local qty = core.item_count(item.name, true)
    if qty <= 0 then
        out('\ay[COLLECT ITEMS]\ax No %s on %s.', item.name, name)
        item_done[clean_name(name)] = true
        return false
    end
    out('\ao[COLLECT ITEMS]\ax Sending local %dx %s to \ag%s\ax.', qty, item.name, recipient)
    mq.cmdf('/mac turbogive _sendstack %s %d %d', recipient, tonumber(item.id) or 0, qty)
    return true
end

local function wait_sender_item(name, recipient, preset_key, notify, collect_locally, item)
    out('\ao[COLLECT ITEMS]\ax Asking \ag%s\ax for %s...', name, item.name)
    local start = core.now_ms()
    local last_activity = start
    local saw_trade = false
    local trades = 0
    local local_sender = clean_name(name) == clean_name(core.me_name())
    if local_sender then
        local launched = ask_local_item(name, recipient, item)
        if not launched then
            return 0, true
        end
    else
        ask_sender_item(name, recipient, preset_key, notify, item.id)
    end

    while true do
        if mq.doevents then mq.doevents() end

        if collect_locally and core.window_open('TradeWnd') then
            saw_trade = true
            last_activity = core.now_ms()
            if core.accept_trade() then
                trades = trades + 1
                last_activity = core.now_ms()
            else
                out('\ay[COLLECT ITEMS]\ax Trade with %s did not close cleanly; moving on.', name)
                break
            end
        end

        if orch.is_done(item_done, name) then
            if core.now_ms() - last_activity >= IDLE_AFTER_DONE_MS then break end
        elseif saw_trade then
            if core.now_ms() - last_activity >= 8000 then break end
        elseif core.now_ms() - start >= ITEM_TIMEOUT_MS then
            out('\ay[COLLECT ITEMS]\ax Timed out waiting for %s to send %s.', name, item.name)
            break
        end

        mq.delay(100)
    end
    return trades, orch.is_done(item_done, name)
end

local function run_coordinator()
    local preset, preset_key = preset_from_args()
    if not preset then
        out('\arAborting:\ax unknown preset.')
        return false
    end

    local scope, _, recipient, from_only, explicit_senders = orch.parse_scope_args(args)
    local me = core.me_name()
    if recipient == '' then recipient = me end
    local collect_locally = clean_name(recipient) == clean_name(me)

    if not orch.preflight_trade(out) then return false end
    if not collect_locally and not orch.spawn_exists(recipient) then
        out('\arAborting:\ax recipient %s is not in zone.', recipient)
        return false
    end

    local active, resolve_err = orch.resolve_active_senders(scope, recipient, from_only, explicit_senders)
    if resolve_err == 'from_to_same' then
        out('\arAborting:\ax from and to cannot be the same (%s).', from_only)
        return false
    elseif resolve_err == 'from_missing' then
        out('\arAborting:\ax sender %s is not in zone.', from_only)
        return false
    elseif #active == 0 then
        out('\arNo selected in-zone senders found for %s.', preset.label)
        return false
    end

    out('\ao[COLLECT ITEMS]\ax %s -> \ag%s\ax from %d sender(s).',
        preset.label, recipient, #active)

    orch.register_done_events(item_done)
    local responded, requests = 0, 0
    for _, name in ipairs(active) do
        local sender_active = false
        for _, item in ipairs(preset.items or {}) do
            requests = requests + 1
            local trades, signaled = wait_sender_item(name, recipient, preset_key, me, collect_locally, item)
            if signaled or trades > 0 then sender_active = true end
            mq.delay(350)
        end
        if sender_active then responded = responded + 1 end
        mq.delay(500)
    end
    orch.unregister_done_events()
    core.clear_cursor('finishing', 4000, out)
    out('\agComplete.\ax %d/%d sender(s) responded for %s (%d item checks).', responded, #active, preset.label, requests)
    return true
end

local function main()
    local mode = tostring(args[1] or ''):lower()
    if mode == 'sendto' then
        return run_sender()
    end
    return run_coordinator()
end

local ok, err = pcall(main)
orch.unregister_done_events()
if not ok then
    out('\arERROR:\ax %s', tostring(err))
end
