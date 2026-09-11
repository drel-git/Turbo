-- Run from repo root: luajit lua/tests/turbogear_linked_items_history_test.lua
-- Linked Items history: observed [TG] chat converges on the same row model
-- as local send / LOOT_LINK. Display bookkeeping only — no re-announce.

package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

local cmd_calls = 0
local store_puts = 0
local needs_lookups = 0
local engine_requests = 0

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
        ParseItemLink = function() return nil end,
        cmd = function() cmd_calls = cmd_calls + 1 end,
        cmdf = function() cmd_calls = cmd_calls + 1 end,
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

package.preload['bis_catalog'] = function()
    return {
        announce_catalog_ready = function() return true end,
        direct_build_progress = function() return nil end,
        announce_list_specs = function() return {} end,
        find_announce_needs_in_line = function() return {} end,
        ensure_announce_catalog = function() end,
        check_announce_need_direct = function() return nil end,
        clean_link_item_name = function(name) return name end,
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
        context = function() end,
        is_enabled = function() return false end,
    }
end

package.preload['store'] = function()
    return {
        Store = {
            peer_keys = function() return {} end,
            get = function() return nil end,
            put = function() store_puts = store_puts + 1 end,
            is_recently_visible = function() return false end,
        },
    }
end

package.preload['needs_index'] = function()
    return {
        char_count = function() return 1 end,
        ready = function() return true end,
        group_ready = function() return true end,
        needers_for = function()
            needs_lookups = needs_lookups + 1
            return {}
        end,
        text_needs = function()
            needs_lookups = needs_lookups + 1
            return {}
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
            request_all = function() engine_requests = engine_requests + 1 end,
            publish = function() end,
        },
    }
end

local A = require('announcer')
local try_chat = A._try_process_chat_for_test
local upsert = A._upsert_linked_item_for_test

local pass, fail = 0, 0
local function check(cond, msg)
    if cond then
        pass = pass + 1
    else
        fail = fail + 1
        print('FAIL: ' .. tostring(msg))
    end
end

local function by_name(rows)
    local out = {}
    for _, row in ipairs(rows or {}) do
        out[tostring(row.item_name or "")] = row
    end
    return out
end

local function needers_of(row)
    return table.concat(row.needers or {}, " | ")
end

A.clear_linked_items()

-- Five distinct observed announces
local burst = {
    { item = "Forgotten Leather Leash", line = "[TG] - Forgotten Leather Leash - Discord | Drel | Sketti", needers = "Discord | Drel | Sketti" },
    { item = "Hanvar's Hoop", line = "[TG] - Hanvar's Hoop - Discord | Drel | Sketti", needers = "Discord | Drel | Sketti" },
    { item = "Noxious Bloom of Corporeal Calamity", line = "[TG] - Noxious Bloom of Corporeal Calamity - Discord | Drel | Sketti", needers = "Discord | Drel | Sketti" },
    { item = "Duality of Desire", line = "[TG] - Duality of Desire - Discord | Drel | Sketti", needers = "Discord | Drel | Sketti" },
    { item = "Jonas Dagmire's Scaphoid", line = "[TG] - Jonas Dagmire's Scaphoid - Discord | Sketti", needers = "Discord | Sketti" },
}
cmd_calls, store_puts, needs_lookups, engine_requests = 0, 0, 0, 0
for _, rec in ipairs(burst) do
    try_chat("You tell your party, '" .. rec.line .. "'", true)
end
local rows = A.linked_items()
check(#rows == 5, 'five distinct observed [TG] lines -> 5 Linked Items rows')
local named = by_name(rows)
for _, rec in ipairs(burst) do
    check(named[rec.item] ~= nil, 'row present: ' .. rec.item)
    check(named[rec.item] and needers_of(named[rec.item]) == rec.needers,
        'needers correct: ' .. rec.item)
end
check(cmd_calls == 0, 'observed [TG] does not send another announce')
check(needs_lookups == 0, 'observed [TG] does not run needs lookup')
check(store_puts == 0, 'observed [TG] does not write Store')
check(engine_requests == 0, 'observed [TG] does not request peers')

-- Own-send echo: local record then observed line -> one row
A.clear_linked_items()
upsert({
    item_name = "Foo",
    needers = { "Drel", "Sketti" },
    history_source = "local_send",
    status = "sent",
    create_if_missing = true,
})
try_chat("You tell your party, '[TG] - Foo - Drel | Sketti'", true)
rows = A.linked_items()
check(#rows == 1, 'own-send echo upserts rather than duplicating')
check(rows[1] and rows[1].item_name == "Foo", 'echo row keeps Foo')
check(rows[1] and needers_of(rows[1]) == "Drel | Sketti", 'echo needers from observed line')

-- Different-process simulation: no local record, only observed chat
A.clear_linked_items()
try_chat("Discord tells the group, '[TG] - Duality of Desire - Discord | Drel | Sketti'", true)
rows = A.linked_items()
check(#rows == 1 and rows[1].item_name == "Duality of Desire",
    'observed [TG] without local send still creates a row')
check(rows[1] and rows[1].source == "observed_tg", 'history source is observed_tg')

-- Alias normalization: Jonas full name and Scaphoid merge; Duality does not
A.clear_linked_items()
try_chat("[TG] - Jonas Dagmire's Scaphoid - Discord | Sketti", true)
try_chat("[TG] - Scaphoid - Discord | Sketti", true)
try_chat("[TG] - Duality of Desire - Discord | Drel | Sketti", true)
rows = A.linked_items()
check(#rows == 2, 'Jonas alias merges; Duality stays separate')
named = by_name(rows)
check(named["Duality of Desire"] ~= nil, 'Duality remains its own row')
local jonas = named["Jonas Dagmire's Scaphoid"] or named["Scaphoid"]
check(jonas ~= nil, 'Jonas/Scaphoid collapsed to one row')

-- LOOT_LINK enrichment of an observed row
A.clear_linked_items()
try_chat("[TG] - Foo - Drel | Sketti", true)
A.on_loot_link({
    from = "OtherBot",
    items = {{ name = "Foo", id = 42, corpse_id = 148, link = "link-foo" }},
})
rows = A.linked_items()
check(#rows == 1, 'LOOT_LINK enriches rather than adding a second row')
check(rows[1] and needers_of(rows[1]) == "Drel | Sketti", 'enrichment keeps observed needers')
check(rows[1] and tonumber(rows[1].corpse_id) == 148, 'enrichment attaches corpse id')
check(rows[1] and tonumber(rows[1].item_id) == 42, 'enrichment attaches item id')

A.clear_linked_items()
try_chat("[TG] - Bloodstained Spring - Drel | Sketti", true)
A.on_loot_link({
    from = "OtherBot",
    items = {{ name = "Bloodstained Spring (ID: 8)", id = 0, corpse_id = 8 }},
})
rows = A.linked_items()
check(#rows == 1, 'contaminated corpse-id loot handoff merges with clean linked row')
check(rows[1] and rows[1].item_name == "Bloodstained Spring", 'contaminated handoff keeps clean display name')
check(rows[1] and needers_of(rows[1]) == "Drel | Sketti", 'contaminated handoff keeps needers')
check(rows[1] and tonumber(rows[1].corpse_id) == 8, 'contaminated handoff attaches corpse id')

print(string.format('linked_items_history: %d passed, %d failed', pass, fail))
if fail > 0 then os.exit(1) end
