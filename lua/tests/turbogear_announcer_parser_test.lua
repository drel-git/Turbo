-- Run from repo root:  luajit lua\tests\turbogear_announcer_parser_test.lua
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

package.preload['mq'] = function()
    return {
        LinkTypes = { Item = "item" },
        TLO = {
            Me = { CleanName = function() return "Tester" end },
            MacroQuest = { Server = function() return "Srv" end },
            EverQuest = { GameState = function() return "INGAME" end },
            Zone = { ShortName = function() return "testzone" end },
        },
        ExtractLinks = function() return {} end,
        ParseItemLink = function(link)
            local s = tostring(link or "")
            if s:find("RAWNOXIOUS", 1, true) then
                return { itemName = "Noxious Bloom of Corporeal Calamity", itemID = 777 }
            end
            -- Corrupt hex → wrong ParseItemLink id/name; visible name must win.
            if s:find("006BE9", 1, true) then
                return { itemName = "Crystal Silk Robe", itemID = 70714 }
            end
            return nil
        end,
        cmd = function() end,
        cmdf = function() end,
        delay = function() end,
    }
end

package.preload['config'] = function()
    return {
        CFG = {},
        Settings = {},
        SharedSettings = { bisAnnounceEnabled = true },
        LoadSharedSettings = function() end,
        bis_announce_command = function() return "/g" end,
    }
end

package.preload['state'] = function()
    return { bg = false, lean = function() return false end }
end

local text_line_scan_calls = 0
package.preload['bis_catalog'] = function()
    return {
        announce_catalog_ready = function() return true end,
        direct_build_progress = function() return nil end,
        announce_list_specs = function() return {} end,
        find_announce_needs_in_line = function()
            text_line_scan_calls = text_line_scan_calls + 1
            return { { item_name = "Infused Flux of Potency", item_id = 1, need = { item_name = "Infused Flux of Potency" } } }
        end,
        ensure_announce_catalog = function() end,
        check_announce_need_direct = function() return nil end,
    }
end

package.preload['snapshot'] = function()
    return {
        cached = function() return { name = "Tester", class = "WAR" } end,
        lite_age = function() return 0 end,
        gather = function() return { name = "Tester", class = "WAR" } end,
    }
end

package.preload['item_actions'] = function()
    return {
        looks_like_item_link = function(text) return tostring(text or ""):find("\x12", 1, true) ~= nil end,
        remember_item_link = function() end,
        resolve_announce_link = function() return "" end,
        observed_link_count = function() return 0 end,
    }
end

package.preload['diagnostics'] = function()
    return {
        time = function(_, fn) return fn() end,
        count = function() end,
        event = function() end,
        sample = function() end,
        is_enabled = function() return false end,
    }
end

package.preload['store'] = function()
    return {
        Store = {
            peer_keys = function() return {} end,
            get = function() return nil end,
            is_recently_visible = function() return false end,
        },
    }
end

local text_needs_calls = 0
package.preload['needs_index'] = function()
    return {
        char_count = function() return 1 end,
        ready = function() return true end,
        group_ready = function() return true end,
        needers_for = function() return {} end,
        text_needs = function()
            text_needs_calls = text_needs_calls + 1
            return {
                {
                    name = "Infused Flux of Potency",
                    id = 1,
                    needers = { { character = "Tester" } },
                },
            }
        end,
        needs_tick = function() return false end,
        tick = function() end,
        status = function() return {} end,
    }
end

package.preload['roster_sets'] = function()
    return {
        resolve_active = function() return nil end,
        member_set = function() return nil end,
    }
end

package.preload['engine'] = function()
    return {
        Engine = {
            ok = true,
            broadcast_loot_links = function() end,
        },
    }
end

local A = require('announcer')
local parse = A._parse_item_links_for_test
local has_unparseable = A._has_unparseable_item_link_payload_for_test
local try_chat = A._try_process_chat_for_test
local runtime = A._runtime_for_test

local passed, failed = 0, 0
local function check(cond, label)
    if cond then
        passed = passed + 1
    else
        failed = failed + 1
        io.stderr:write('FAIL: ', tostring(label), '\n')
    end
end

local hit = parse("[19:19:25] Ghee tells the group, '[ANNOUNCE] Imbued Feather (ID: 209)'")
check(#hit == 1, 'timestamp before ANNOUNCE does not consume payload')
check(hit[1] and hit[1].name == "Imbued Feather", 'ANNOUNCE name parsed')
check(hit[1] and hit[1].id == 0, 'ANNOUNCE corpse id ignored')
check(hit[1] and hit[1].corpse_id == 209, 'ANNOUNCE corpse_id attached')

local skip = parse("[01:54:29] Ahffrait tells the group, '[SKIP] Elemental Gauntlet Mold (ID: 148) - Already have'")
check(#skip == 1, 'timestamp before SKIP does not consume payload')
check(skip[1] and skip[1].name == "Elemental Gauntlet Mold", 'SKIP name parsed')
check(skip[1] and skip[1].id == 0, 'SKIP corpse id ignored')
check(skip[1] and skip[1].corpse_id == 148, 'SKIP corpse_id attached')

-- Other-player events sometimes wrap only a link frame between the tag and (ID:)
local framed = parse("Sketti tells the group, '[ANNOUNCE] \x12RAWNOXIOUS\x12 (ID: 128)'")
check(#framed >= 1, 'ANNOUNCE with link frame still yields an item')
local framed_hit = framed[1]
check(framed_hit and framed_hit.name == "Noxious Bloom of Corporeal Calamity", 'ANNOUNCE frame name via ParseItemLink')
check(framed_hit and framed_hit.corpse_id == 128, 'ANNOUNCE frame keeps corpse_id')

local framed_plain = parse("Sketti tells the group, '[ANNOUNCE] \x12DEADBEEF\x12Wand of Ruptured Reality\x12 (ID: 99)'")
check(#framed_plain >= 1, 'ANNOUNCE with opaque frame + visible name')
local found_wand = false
for _, it in ipairs(framed_plain) do
    if it.name == "Wand of Ruptured Reality" and it.corpse_id == 99 then found_wand = true end
end
check(found_wand, 'ANNOUNCE strips opaque frames and keeps visible name + corpse_id')
local none = parse("[19:19:25] Morgouna auctions, 'wts Idol of the Scale 500k each'")
check(#none == 0, 'plain timestamp line without control tag ignored')

local raw = parse("You tell your raid, '\x12RAWNOXIOUS\x12 \x12RAWNOXIOUS\x12'")
check(#raw == 1, 'raw item-link frames parse when ExtractLinks is empty')
check(raw[1] and raw[1].name == "Noxious Bloom of Corporeal Calamity", 'raw frame name parsed')
check(raw[1] and raw[1].id == 777, 'raw frame id parsed')

check(has_unparseable("You tell your raid, '\x12RAWNOXIOUS\x12'") == true, 'fallback detector sees raw frame')
check(has_unparseable("You tell your raid, '00989C0000000000000000000000000000000000000000000C7776F6Noxious Bloom'") == true,
    'fallback detector sees long hex payload')
check(has_unparseable("You tell your raid, 'hello team'") == false, 'fallback detector ignores normal chat')

-- Links-only: typed BiS names must not announce (even when index would match).
text_needs_calls = 0
text_line_scan_calls = 0
local typed = try_chat("You tell your party, 'Infused Flux of Potency'", false)
check(typed == false, 'typed BiS name does not announce')
check(text_needs_calls == 0, 'typed name does not run needs_index.text_needs')
check(text_line_scan_calls == 0, 'typed name does not run catalog line scan')
check(runtime.last_chat_note == "no item link", 'typed name notes no item link')

local typed_say = try_chat("You say, 'Exalted Glowing Bath Token'", false)
check(typed_say == false, 'typed BiS name in say does not announce')
check(runtime.last_chat_note == "no item link", 'say typed name notes no item link')

-- Peer plain text (and dirty keepLinks junk without a parseable item) must not
-- fall back to whole-line BiS name scanning.
text_needs_calls = 0
local peer_plain = try_chat(
    "Creatos tells the group, 'Infused Flux of Glamour'",
    false,
    { other_event = true })
check(peer_plain == false, 'peer typed BiS name does not announce')
check(text_needs_calls == 0, 'peer typed name does not run text_needs')
check(runtime.last_chat_note == "no item link", 'peer typed name notes no item link')

-- Hex dump + visible name is a real MQ self/peer link shape (ExtractLinks empty).
local hex_link = parse(
    "You tell your party, ' 006BE9000000000000000000000000000000000000000000000CECBB12FHideous Hex of Noxious Demise '")
check(#hex_link == 1, 'hex self-link payload parses as one item')
check(hex_link[1] and hex_link[1].name == "Hideous Hex of Noxious Demise",
    'hex self-link recovers visible item name')
check(hex_link[1] and (tonumber(hex_link[1].id) or 0) == 0,
    'mismatched ParseItemLink id is discarded for hex self-links')

local hex_quote = parse(
    "You tell your party, '008CCD00000000000000000000000000000000000000000000000AC7F59C9Noxious Bloom of Ebbing Exertion\">")
check(#hex_quote == 1, 'hex self-link with trailing quote-angle parses')
check(hex_quote[1] and hex_quote[1].name == "Noxious Bloom of Ebbing Exertion",
    'trailing "> stripped from hex self-link name')

-- Contaminated name shapes that previously painted as no-row while MQ pretty-printed the link.
local framed = parse("You tell your party, '\x12ABCDEF0123456789ABCDEF0123456789ABCDEF01Desolate Black Sapphire\x12'>")
-- Frame-only lines depend on ParseItemLink; without mq stubs just ensure no crash / no junk name.
if #framed > 0 then
    check(framed[1].name == "Desolate Black Sapphire"
        or not tostring(framed[1].name or ""):find("\x12", 1, true),
        'framed self-link name has no raw \\x12 bytes')
end

local announce_hex = parse(
    "You tell your party, '[ANNOUNCE] 010CEA00000000000000000000000000000000000000000000C4263BE8Divine Crystal Ring '")
check(#announce_hex == 1, 'ANNOUNCE hex+name parses without (ID:)')
check(announce_hex[1] and announce_hex[1].name == "Divine Crystal Ring",
    'ANNOUNCE hex+name recovers item name')

-- Multi-link hex dumps jammed into one party line.
local multi = parse(
    "You tell your party, '0098A500000000000000000000000000000000000000000000008F17CD86Corrosive Slime of Suffering  0098A4000000000000000000000000000000000000000000000BB963495Frigid Slime of Suffering '")
check(#multi >= 2, 'multi hex self-links parse as multiple items')
local multi_names = {}
for _, it in ipairs(multi) do multi_names[it.name] = true end
check(multi_names["Corrosive Slime of Suffering"] == true, 'multi hex recovers Corrosive Slime')
check(multi_names["Frigid Slime of Suffering"] == true, 'multi hex recovers Frigid Slime')

-- Typed BiS name with no hex / frames still ignored.
local peer_dirty_plain = try_chat(
    "Creatos tells the group, 'Infused Flux of Glamour'",
    false,
    { other_event = true })
check(peer_dirty_plain == false, 'peer typed name without hex still ignored')

-- Control-tag lines still count as parsed "links" (TurboLoot ANNOUNCE path).
local announce_links = parse("Ghee tells the group, '[ANNOUNCE] Imbued Feather (ID: 209)'")
check(#announce_links == 1, 'ANNOUNCE still parses as a link for announce path')

local ignore_links = parse("Ghee tells the group, '[IGNORE] Imbued Feather (ID: 209)'")
check(#ignore_links == 0, 'IGNORE control tag does not seed announce parse')

-- lootseen / LOOT_LINK: Linked handoff only, never queues [TG] paint.
local runtime = A._runtime_for_test
A.on_loot_seen("Imbued Feather", 0, "", "structured", 209)
check(tostring(runtime.last_chat_note or ""):find("no emit", 1, true) ~= nil,
    'lootseen sets no-emit note')
local linked = A.linked_items()
local saw_feather = false
for _, row in ipairs(linked or {}) do
    if tostring(row.item_name or "") == "Imbued Feather"
        and tonumber(row.corpse_id) == 209
    then
        saw_feather = true
        break
    end
end
check(saw_feather, 'lootseen still attaches corpse id for Go-loot')

A.on_loot_link({
    from = "OtherBot",
    items = {{ name = "Elemental Gauntlet Mold", id = 0, corpse_id = 148 }},
})
check(tostring(runtime.last_chat_note or ""):find("no emit", 1, true) ~= nil,
    'LOOT_LINK sets no-emit note')

io.write(string.format('announcer parser: %d passed, %d failed\n', passed, failed))
os.exit(failed == 0 and 0 or 1)
