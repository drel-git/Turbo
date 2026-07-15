-- Run from repo root:  luajit lua\tests\turbogear_announce_rules_test.lua
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

local R = require('announce_rules')

local passed, failed = 0, 0
local function check(cond, label)
    if cond then
        passed = passed + 1
    else
        failed = failed + 1
        io.stderr:write('FAIL: ', tostring(label), '\n')
    end
end

-- should_skip_line
check(R.should_skip_line("", "Hez") == true, 'skip: empty line')
check(R.should_skip_line("Drel tells the group, '[TG] - Sword - Hez'", "Hez") == true, 'skip: own TG output')
check(R.should_skip_line("[TurboGear] status line", "Hez") == true, 'skip: turbogear log line')
check(R.should_skip_line("Drel tells you, 'want this Sword?'", "Hez") == true, 'skip: private tells')
check(R.should_skip_line("Drel tells the group, 'turbounload now'", "Hez") == true, 'skip: turbounload')
check(R.should_skip_line("Drel tells the group, 'Sword of Truth'", "Hez") == false, 'no skip: normal group chat')
check(R.should_skip_line("replayed text - hez", "Hez") == true, 'skip: trailing - <me> suffix (unquoted)')
check(R.should_skip_line("Drel tells the group, 'grats - hez'", "Hez") == false, 'no skip: quoted line does not match <me> suffix')

-- line classification
check(R.is_player_link_chat_line("You tell the group, 'Sword'") == true, 'link line: self group')
check(R.is_player_link_chat_line("Drel tells the group, 'Sword'") == true, 'link line: other group')
check(R.is_player_link_chat_line("Drel tells the raid,  'Sword'") == true, 'link line: raid')
check(R.is_player_link_chat_line("Drel says, 'Sword'") == true, 'link line: say')
check(R.is_player_link_chat_line("Drel tells the guild, 'Sword'") == true, 'link line: guild')
check(R.is_player_link_chat_line("You tell the guild, 'Sword'") == true, 'link line: self guild')
check(R.is_player_link_chat_line("Drel says out of character, 'Sword'") == true, 'link line: ooc')
check(R.is_player_link_chat_line("You say out of character, 'Sword'") == true, 'link line: self ooc')
check(R.is_player_link_chat_line("Drel auctions, 'WTS Sword'") == false, 'link line: auction excluded')
check(R.is_player_link_chat_line("[19:19:25] Drel tells the group, 'Sword'") == true, 'link line: timestamped group')
check(R.is_player_link_chat_line("[01:02:03] You tell the group, 'Sword'") == true, 'link line: timestamped self group')
check(R.is_player_link_chat_line("[01:02:03] Drel tells the guild, 'Sword'") == true, 'link line: timestamped guild')

check(R.is_self_loot_line("You tell your party, 'Sword'") == true, 'self line: party')
check(R.is_self_loot_line("[01:02:03] You tell your party, 'Sword'") == true, 'self line: timestamped party')
check(R.is_self_loot_line("You say out of character, 'Sword'") == true, 'self line: ooc')
check(R.is_self_loot_line("Drel tells the group, 'Sword'") == false, 'self line: other is not self')

check(R.is_other_player_chat_line("Drel tells the group, 'Sword'") == true, 'other line: group')
check(R.is_other_player_chat_line("Drel tells the guild, 'Sword'") == true, 'other line: guild')
check(R.is_other_player_chat_line("Drel says out of character, 'Sword'") == true, 'other line: ooc')
check(R.is_other_player_chat_line("[19:19:25] Drel tells the group, 'Sword'") == true, 'other line: timestamped group')
check(R.is_other_player_chat_line("You tell the group, 'Sword'") == false, 'other line: self excluded')
check(R.is_other_player_chat_line("You say, 'Sword'") == false, 'other line: self say excluded')

-- normalize_item_name
check(R.normalize_item_name("  Blade  OF   War ") == "blade of war", 'normalize: trim/lower/collapse')
check(R.normalize_item_name(nil) == "", 'normalize: nil safe')

-- dedupe_key
check(R.dedupe_key("Srv", "Hez", "anguish", "Blade of War", 101)
    == "Srv:Hez:anguish:id:101", 'dedupe: id preferred')
check(R.dedupe_key("Srv", "Hez", "anguish", "Blade of War", 0)
    == "Srv:Hez:anguish:name:blade of war", 'dedupe: name fallback')
check(R.dedupe_key(nil, nil, nil, "X", nil)
    == "?:?::name:x", 'dedupe: nil-safe')

-- grouped_item_key: name > id > link
local is_link = function(s) return tostring(s or ""):find("\18", 1, true) ~= nil end
check(R.grouped_item_key("Blade", 101, "", is_link) == "name:blade", 'group key: name wins')
check(R.grouped_item_key("", 101, "", is_link) == "id:101", 'group key: id fallback')
check(R.grouped_item_key("Blade", 0, "\18link-payload\18", is_link) == "name:blade", 'group key: name beats link')
check(R.grouped_item_key("", 0, "\18link-payload\18", is_link) == "link:\18link-payload\18", 'group key: link fallback')
check(R.grouped_item_key("Blade", 0, "not a link", is_link) == "name:blade", 'group key: name fallback')
check(R.grouped_item_key("Blade", 0, "\18x\18", nil) == "name:blade", 'group key: no predicate -> name')

-- format_message
check(R.format_message("Blade of War", "Hez") == "[TG] - Blade of War - Hez", 'format: single name')
check(R.format_message("Blade of War", { "drel", "Ana", "hez" })
    == "[TG] - Blade of War - Ana | drel | hez", 'format: grouped names pipe-separated, sorted case-insensitively')
check(R.format_message(nil, nil) == "[TG] - ? - ?", 'format: nil safe')

-- parse_tg_line: extract the item payload from [TG] announce lines
check(R.parse_tg_line("You tell your party, '[TG] - Forsaken Shieldstorm - Kanaelle | Vythril'")
    == "Forsaken Shieldstorm", 'tg parse: plain item, quoted line')
check(R.parse_tg_line("Remia tells the group, '[TG] - Infused Flux of Acumen - Eliska | Vythril | Zaeri | Zhugg'")
    == "Infused Flux of Acumen", 'tg parse: other box line')
check(R.parse_tg_line("You tell your party, '[TG] - Corrosive Fungus of Suffering - Tier II - Discord | Drel'")
    == "Corrosive Fungus of Suffering - Tier II", 'tg parse: item containing dash segment')
check(R.parse_tg_line("You tell your party, '[TG] - \18linkdata\18Noxious Bloom\18 - Drel'")
    == "\18linkdata\18Noxious Bloom\18", 'tg parse: raw link payload preserved')
check(R.parse_tg_line("Drel tells the group, 'grats on the sword'") == nil, 'tg parse: non-TG line is nil')
check(R.parse_tg_line("") == nil, 'tg parse: empty line is nil')
check(R.parse_tg_line("[TG] - Solo Item") == "Solo Item", 'tg parse: payload without names segment')

-- confirmable_needers: cache-derived peer needers only (skip self + actor-reply)
do
    local order = { "Gears", "Hez", "Captaain", "Drel" }
    local sources = { gears = "index", hez = "index", captaain = "actor-reply", drel = "targeted" }
    local out = R.confirmable_needers(order, sources, "Gears")
    check(#out == 2 and out[1] == "Hez" and out[2] == "Drel", 'confirm: skips self and actor-reply needers')
    out = R.confirmable_needers(order, nil, "Gears")
    check(#out == 3, 'confirm: nil sources treats all remote needers as cache-derived')
    check(#R.confirmable_needers(nil, sources, "Gears") == 0, 'confirm: nil order safe')
    check(#R.confirmable_needers({ "Gears" }, {}, "gears") == 0, 'confirm: self match is case-insensitive')
end

-- remove_needer: drops one character from bucket needer tables
do
    local names = { hez = "Hez", drel = "Drel" }
    local order = { "Hez", "Drel" }
    check(R.remove_needer(names, order, "HEZ") == true, 'remove: case-insensitive hit')
    check(names.hez == nil and #order == 1 and order[1] == "Drel", 'remove: cleared from both tables')
    check(R.remove_needer(names, order, "Hez") == false, 'remove: absent character returns false')
    check(R.remove_needer(names, order, "") == false, 'remove: empty character safe')
    check(R.remove_needer(nil, order, "Drel") == false, 'remove: nil names safe')
end

-- beacon_fresh: driver-first coordinator beacon freshness
check(R.beacon_fresh(1000, 1050, 90) == true, 'beacon: fresh within ttl')
check(R.beacon_fresh(1000, 1091, 90) == false, 'beacon: stale past ttl')
check(R.beacon_fresh(1000, 1090, 90) == true, 'beacon: boundary inclusive')
check(R.beacon_fresh(0, 1000, 90) == false, 'beacon: zero stamp never fresh')
check(R.beacon_fresh(nil, 1000, 90) == false, 'beacon: nil stamp never fresh')
check(R.beacon_fresh(2000, 1000, 90) == false, 'beacon: future stamp (clock skew) not fresh')

io.write(string.format('announce_rules: %d passed, %d failed\n', passed, failed))
os.exit(failed == 0 and 0 or 1)
