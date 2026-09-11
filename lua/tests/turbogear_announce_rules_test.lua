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

do
    local n0, id0 = R.parse_item_name_id("Hanvar's Hoop")
    local n1, id1 = R.parse_item_name_id("Hanvar's Hoop 47286")
    local n2, id2 = R.parse_item_name_id("Hanvar's Hoop [47286]")
    local n3, id3 = R.parse_item_name_id("Hanvar's Hoop (ID: 47286)")
    check(n0 == "Hanvar's Hoop" and id0 == 0, 'cli identity: name only')
    check(n1 == "Hanvar's Hoop" and id1 == 47286, 'cli identity: trailing numeric id')
    check(n2 == "Hanvar's Hoop" and id2 == 47286, 'cli identity: bracketed optional id')
    check(n3 == "Hanvar's Hoop" and id3 == 47286, 'cli identity: labeled id')
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
check(R.should_skip_line(
    "Sarku tells the group, '[Rez] => Chaan <= {attempting to rez with Exalted Glowing Bath Token}'",
    "Hez") == true, 'skip: [Rez] status with clicky name')
check(R.should_skip_line(
    "Creatos tells the group, 'attempting to rez with Blessing of Resurrection'",
    "Hez") == true, 'skip: rez phrase without [Rez] tag')
check(R.should_skip_line(
    "Drel tells the group, '[ANNOUNCE] Exalted Glowing Bath Token (ID: 12)'",
    "Hez") == false, 'no skip: TurboLoot announce line')

-- line classification
check(R.is_player_link_chat_line("You tell the group, 'Sword'") == true, 'link line: self group')
check(R.is_player_link_chat_line("Drel tells the group, 'Sword'") == true, 'link line: other group')
check(R.is_player_link_chat_line("Drel tells the raid,  'Sword'") == true, 'link line: raid')
check(R.is_player_link_chat_line("Drel says, 'Sword'") == true, 'link line: say')
check(R.is_player_link_chat_line("Drel tells the guild, 'Sword'") == true, 'link line: guild')
check(R.is_player_link_chat_line("You tell the guild, 'Sword'") == true, 'link line: self guild')
check(R.is_player_link_chat_line("Drel says out of character, 'Sword'") == true, 'link line: ooc')
check(R.is_player_link_chat_line("You say out of character, 'Sword'") == true, 'link line: self ooc')
check(R.is_guild_link_chat_line("Drel tells the guild, 'Sword'") == true, 'guild only: other guild')
check(R.is_guild_link_chat_line("You tell the guild, 'Sword'") == true, 'guild only: self guild')
check(R.is_guild_link_chat_line("Drel tells the group, 'Sword'") == false, 'guild only: group excluded')
check(R.is_ooc_link_chat_line("Drel says out of character, 'Sword'") == true, 'ooc only: other ooc')
check(R.is_ooc_link_chat_line("You say out of character, 'Sword'") == true, 'ooc only: self ooc')
check(R.is_ooc_link_chat_line("Drel says, 'Sword'") == false, 'ooc only: say excluded')
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
check(R.normalize_item_name("Bloodstained Spring (ID: 8)") == "bloodstained spring",
    'normalize: strips trailing corpse id')
check(R.normalize_item_name("Bloodstained Spring ( id : 8 )") == "bloodstained spring",
    'normalize: strips loose trailing corpse id')
check(R.strip_trailing_corpse_id("Bloodstained Spring (ID: 8)") == "Bloodstained Spring",
    'strip corpse id: preserves display case')

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

-- Jonas short catalog name and loot-link full name share one group key.
check(R.jonas_canonical_name("Jonas Dagmire's Forefinger Proximal Phalanx")
    == "forefinger proximal phalanx", 'jonas: strip prefix')
check(R.jonas_canonical_name("Forefinger Proximal Phalanx")
    == "forefinger proximal phalanx", 'jonas: bare name unchanged')
check(R.grouped_item_key("Jonas Dagmire's Forefinger Proximal Phalanx", 0, "", is_link)
    == R.grouped_item_key("Forefinger Proximal Phalanx", 0, "", is_link),
    'jonas: short + full name same group key')
check(R.grouped_item_key("Jonas Dagmire's Triquetrum", 0, "", is_link)
    ~= R.grouped_item_key("Jonas Dagmire's Trapezium", 0, "", is_link),
    'jonas: different bones stay distinct')
check(R.prefer_announce_item_name("Forefinger Proximal Phalanx", "Jonas Dagmire's Forefinger Proximal Phalanx")
    == "Jonas Dagmire's Forefinger Proximal Phalanx", 'jonas: prefer full display name')
check(R.prefer_announce_item_name("Jonas Dagmire's Forefinger Proximal Phalanx", "Forefinger Proximal Phalanx")
    == "Jonas Dagmire's Forefinger Proximal Phalanx", 'jonas: keep full when short arrives late')
check(R.prefer_announce_item_name("Bloodstained Spring", "Bloodstained Spring (ID: 8)")
    == "Bloodstained Spring", 'prefer display: dirty corpse id suffix never wins')
check(R.dedupe_key("Srv", "Hez", "jonas", "Jonas Dagmire's Capitate", 0)
    == R.dedupe_key("Srv", "Hez", "jonas", "Capitate", 0),
    'jonas: dedupe key collapses alias pair')

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

local five = {
    "Forgotten Leather Leash",
    "Hanvar's Hoop",
    "Noxious Bloom of Corporeal Calamity",
    "Duality of Desire",
    "Jonas Dagmire's Scaphoid",
}
do
    local keys = {}
    for _, name in ipairs(five) do
        local k = R.grouped_item_key(name, 0, "", is_link)
        check(keys[k] == nil, 'five-item burst keys do not collide: ' .. name)
        keys[k] = name
    end
    check(R.jonas_canonical_name("Jonas Dagmire's Scaphoid")
        == R.jonas_canonical_name("Scaphoid"), 'jonas alias: Scaphoid collapses to same canonical')
    check(R.jonas_canonical_name("Duality of Desire")
        ~= R.jonas_canonical_name("Jonas Dagmire's Scaphoid"), 'jonas alias does not collide with Duality')
end

do
    local a = R.parse_tg_announce("[TG] - Forgotten Leather Leash - Discord | Drel | Sketti")
    check(a and a.item_name == "Forgotten Leather Leash", 'tg announce: plaintext item')
    check(a and #a.needers == 3 and a.needers[1] == "Discord" and a.needers[3] == "Sketti",
        'tg announce: pipe needers preserve order')
    check(R.parse_tg_announce("Drel tells the group, 'grats on the sword'") == nil,
        'tg announce: non-TG is nil')
    check(R.parse_tg_announce("[TG] - Solo Item") == nil,
        'tg announce: payload without needers is not a complete announce')
    local hex = R.parse_tg_announce(
        "You tell your party, '[TG] -  0138300000000000000000000000000000000000000000002F8181D1Jonas Dagmire's Scaphoid  - Discord | Sketti'")
    check(hex and hex.item_name == "Jonas Dagmire's Scaphoid",
        'tg announce: strips leading item-link hex from payload')
    check(hex and #hex.needers == 2 and hex.needers[1] == "Discord",
        'tg announce: needers after hex payload')
    local framed = R.parse_tg_announce("You tell your party, '[TG] - \18linkdata\18Noxious Bloom\18 - Drel'")
    check(framed and framed.item_name == "Noxious Bloom", 'tg announce: framed link display name')
end

-- confirmable_needers: cache-derived peer needers only (skip self + live sources)
do
    local order = { "Gears", "Hez", "Captaain", "Drel", "Vyth", "Ana" }
    local sources = {
        gears = "local-live", hez = "index", captaain = "actor-reply",
        drel = "targeted", vyth = "local-live", ana = "direct-cache",
    }
    local out = R.confirmable_needers(order, sources, "Gears")
    check(#out == 2 and out[1] == "Hez" and out[2] == "Drel",
        'confirm: skips self, actor-reply, local-live, and direct-cache needers')
    out = R.confirmable_needers(order, nil, "Gears")
    check(#out == 5, 'confirm: nil sources treats all remote needers as cache-derived')
    check(#R.confirmable_needers(nil, sources, "Gears") == 0, 'confirm: nil order safe')
    check(#R.confirmable_needers({ "Gears" }, {}, "gears") == 0, 'confirm: self match is case-insensitive')
    check(#R.confirmable_needers({ "Ana" }, { ana = "store-snap" }, "Gears") == 0,
        'confirm: store-snap needers skip confirm round')
    check(#R.confirmable_needers({ "Ana" }, { ana = "bis-paint" }, "Gears") == 0,
        'confirm: bis-paint needers skip confirm round')
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

-- sticky per-group coordinator election
do
    local sig = R.group_sig_from_names({ "Alghol", "Dhaimon" })
    check(sig == "Alghol|Dhaimon", 'group_sig: two members sorted')
    local coords = { [sig] = { name = "Alghol", seenAt = 1000 } }
    local action, holder, reason = R.coordinator_claim_decision({
        me_name = "Dhaimon", group_sig = sig, now = 1020, ttl_s = 90,
        coordinators = coords,
    })
    check(action == "defer" and holder == "Alghol" and reason == "other_holder", 'claim: defer to sticky holder')
    action, holder, reason = R.coordinator_claim_decision({
        me_name = "Alghol", group_sig = sig, now = 1020, ttl_s = 90,
        coordinators = coords,
    })
    check(action == "refresh" and reason == "self_holder", 'claim: self refreshes')
    action, holder, reason = R.coordinator_claim_decision({
        me_name = "Dhaimon", group_sig = sig, now = 1020, ttl_s = 90,
        coordinators = coords, force_claim = true,
    })
    check(action == "claim" and reason == "force_claim", 'claim: force steals')
    action = select(1, R.coordinator_claim_decision({
        me_name = "Dhaimon", group_sig = sig, now = 1200, ttl_s = 90,
        coordinators = coords,
    }))
    check(action == "claim", 'claim: stale beacon is vacant')
    local defer, dreason = R.should_defer_announce({
        is_bg = true, me_name = "Bot", group_sig = sig, now = 1020, ttl_s = 90,
        coordinators = coords, legacy_seen_at = 0,
    })
    check(defer == true and dreason == "group_beacon", 'defer: bg defers to group holder')
    defer, dreason = R.should_defer_announce({
        is_bg = false, me_name = "Alghol", group_sig = sig, now = 1020, ttl_s = 90,
        coordinators = coords, legacy_seen_at = 0,
    })
    check(defer == false and dreason == "self_holder", 'defer: holder UI does not defer')
    defer, dreason = R.should_defer_announce({
        is_bg = true, me_name = "Bot", group_sig = "", now = 1020, ttl_s = 90,
        coordinators = {}, legacy_seen_at = 1000,
    })
    check(defer == true and dreason == "legacy_beacon", 'defer: bg uses legacy stamp')
    -- Fail-closed: bg with no fresh beacon must not announce (no N-way [TG] spam).
    defer, dreason = R.should_defer_announce({
        is_bg = true, me_name = "Bot", group_sig = sig, now = 2000, ttl_s = 90,
        coordinators = {}, legacy_seen_at = 0,
    })
    check(defer == true and dreason == "no_ui_driver", 'defer: bg empty coords fail-closed')
    defer, dreason = R.should_defer_announce({
        is_bg = true, me_name = "Bot", group_sig = sig, now = 2000, ttl_s = 90,
        coordinators = { [sig] = { name = "Alghol", seenAt = 1000 } }, legacy_seen_at = 1000,
    })
    check(defer == true and dreason == "no_ui_driver", 'defer: bg stale beacon fail-closed')
    -- Lone UI with no beacon may still claim/speak.
    defer, dreason = R.should_defer_announce({
        is_bg = false, me_name = "Alghol", group_sig = sig, now = 2000, ttl_s = 90,
        coordinators = {}, legacy_seen_at = 0,
    })
    check(defer == false and dreason == "no_beacon", 'defer: UI no beacon still speaks')
    local next_coords, changed = R.apply_coordinator_stamp({}, sig, "Alghol", 1000)
    check(changed and next_coords[sig].name == "Alghol", 'stamp: writes record')
end

io.write(string.format('announce_rules: %d passed, %d failed\n', passed, failed))
os.exit(failed == 0 and 0 or 1)
