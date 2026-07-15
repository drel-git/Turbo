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
            if tostring(link or ""):find("RAWNOXIOUS", 1, true) then
                return { itemName = "Noxious Bloom of Corporeal Calamity", itemID = 777 }
            end
            return nil
        end,
        cmd = function() end,
        cmdf = function() end,
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

package.preload['bis_catalog'] = function()
    return {
        announce_catalog_ready = function() return true end,
        direct_build_progress = function() return nil end,
        announce_list_specs = function() return {} end,
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

package.preload['needs_index'] = function()
    return {
        char_count = function() return 0 end,
        ready = function() return false end,
        needers_for = function() return {} end,
        text_needs = function() return {} end,
        needs_tick = function() return false end,
        tick = function() end,
        status = function() return {} end,
    }
end

local A = require('announcer')
local parse = A._parse_item_links_for_test
local has_unparseable = A._has_unparseable_item_link_payload_for_test

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

local skip = parse("[01:54:29] Ahffrait tells the group, '[SKIP] Elemental Gauntlet Mold (ID: 148) - Already have'")
check(#skip == 1, 'timestamp before SKIP does not consume payload')
check(skip[1] and skip[1].name == "Elemental Gauntlet Mold", 'SKIP name parsed')
check(skip[1] and skip[1].id == 0, 'SKIP corpse id ignored')

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

io.write(string.format('announcer parser: %d passed, %d failed\n', passed, failed))
os.exit(failed == 0 and 0 or 1)
