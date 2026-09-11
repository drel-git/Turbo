-- Offline: check_announce_need_for_link finds needs without reverse-index / dcat.
-- Run from repo root: luajit lua/tests/turbogear_announce_link_need_test.lua
package.path = "lua/turbogear/?.lua;lua/turbogear/?/init.lua;" .. package.path

package.preload["mq"] = function()
    local function empty_item()
        return setmetatable({}, {
            __call = function() return nil end,
            __index = function() return nil end,
        })
    end
    return {
        TLO = {
            Me = {
                CleanName = function() return "Drel" end,
                Class = { Name = function() return "Wizard" end },
            },
            MacroQuest = { Server = function() return "Project Lazarus" end },
            EverQuest = { GameState = function() return "INGAME" end },
            FindItem = function() return empty_item() end,
            FindItemBank = function() return empty_item() end,
            Cursor = empty_item(),
        },
        configDir = ".",
    }
end

package.preload["config"] = function()
    return {
        CFG = { perf_live_self_bis = true },
        Settings = {},
        SharedSettings = { bisAnnounceDisabledLists = {} },
        SaveSettings = function() end,
        SaveSharedSettings = function() end,
        known_class = function(c)
            c = tostring(c or "")
            if c == "" or c == "?" then return nil end
            return c
        end,
        canonical_class = function(c)
            c = tostring(c or "")
            if c == "" or c == "?" then return nil end
            if c == "Shadowknight" then return "Shadow Knight" end
            return c
        end,
    }
end

local diag_counts = {}
local diag_samples = {}
package.preload["diagnostics"] = function()
    return {
        time = function(_, fn) return fn() end,
        count = function(k) diag_counts[k] = (diag_counts[k] or 0) + 1 end,
        event = function() end,
        sample = function(k, v) diag_samples[k] = v end,
    }
end

local pass, fail = 0, 0
local function check(cond, msg)
    if cond then
        pass = pass + 1
    else
        fail = fail + 1
        print("FAIL: " .. tostring(msg))
    end
end

local catalog = require("bis_catalog")
catalog.warm_catalog()
check(catalog.catalog_loaded() == true, "catalog_loaded after warm")

local function empty_snap(class, name)
    return {
        name = name or "Drel",
        server = "Project Lazarus",
        class = class,
        equipped = {},
        bags = {},
        bank = {},
        augs = {},
        spells = {},
    }
end

local function tick_compact_ready()
    for _ = 1, 2000 do
        if catalog.tick_compact_announce_rules(500, 64) then return true end
    end
    return false
end

local function tick_shared_ready(snap)
    catalog.request_shared_compact_rule_index(snap.class, snap.name, "test")
    for _ = 1, 2000 do
        if catalog.tick_shared_compact_rule_index(500, 64) then
            local status = catalog.shared_compact_rule_index_status()
            if status and status.common_ready and status.user_ready then
                local cands = catalog.shared_compact_candidates_for_link(snap, "Frigid Slime of Suffering", 0)
                if cands then return true end
            end
        end
    end
    return false
end

local wizard = empty_snap("Wizard", "Drel")
local prepared1, prep_reason1, prep_meta1 = catalog.prepare_compact_announce_rules(wizard)
check(prepared1 == nil and prep_reason1 == "not-ready" and prep_meta1.not_ready == true,
    "compact announce rules do not synchronously prepare on first character signature")
check(tick_compact_ready(), "compact announce rules cooperative build finishes")
local prepared2, prep_reason2, prep_meta2 = catalog.prepare_compact_announce_rules(wizard)
local prepared3, prep_reason3, prep_meta3 = catalog.prepare_compact_announce_rules(wizard)
check(prepared2 ~= nil and prep_reason2 == "ok" and prep_meta2.cache == "hit",
    "compact announce rules become ready after cooperative build")
check(prepared3 == prepared2 and prep_reason3 == "ok" and prep_meta3.cache == "hit",
    "compact announce rules reuse prepared character signature")
local compact_cands, compact_reason, compact_meta = catalog.compact_announce_candidates_for_link(wizard, "Frigid Slime of Suffering", 0)
check(compact_reason == "ok" and #compact_cands > 0 and compact_meta.cache == "hit",
    "compact candidate lookup uses prepared rules")
local sk_compact = empty_snap("Shadow Knight", "Drel")
catalog.request_compact_announce_rules(sk_compact, "test")
check(tick_compact_ready(), "compact announce rules cooperative build finishes for SK")
local jonas_cands, jonas_reason = catalog.compact_announce_candidates_for_link(sk_compact, "Jonas Dagmire's Pisiform", 0)
check(jonas_reason == "ok" and #jonas_cands > 0,
    "compact prepared rules index Jonas prefixed aliases directly")
local war_compact = empty_snap("Warrior", "Discord")
catalog.request_compact_announce_rules(war_compact, "test")
check(tick_compact_ready(), "compact announce rules cooperative build finishes for Warrior")
local scales_cands, scales_reason = catalog.compact_announce_candidates_for_link(war_compact, "Kreljnok's Sword of Draconic Power", 55079)
check(scales_reason == "ok" and #scales_cands > 0,
    "compact prepared rules index DoN scales class epic equivalents directly")

local shared_first, shared_first_reason, shared_first_meta = catalog.shared_compact_candidates_for_link(wizard, "Frigid Slime of Suffering", 0)
check(shared_first_reason == "not-ready" and shared_first_meta.not_ready == true and #shared_first == 0,
    "shared compact index does not synchronously build from link lookup")
check(tick_shared_ready(wizard), "shared compact index cooperative build reaches Wizard readiness")
local shared_cands, shared_reason, shared_meta = catalog.shared_compact_candidates_for_link(wizard, "Frigid Slime of Suffering", 0)
check(shared_reason == "ok" and #shared_cands > 0 and shared_meta.cache == "hit",
    "shared compact index direct lookup finds fungal match")
local shared_bloom, shared_bloom_reason = catalog.shared_compact_candidates_for_link(wizard, "Noxious Bloom of Ebbing Exertion", 0)
check(shared_bloom_reason == "ok" and #shared_bloom > 0,
    "shared match-ref index includes directional Noxious Bloom link alias")
local shared_bag_mat, shared_bag_mat_reason = catalog.shared_compact_candidates_for_link(wizard, "Master Tailor's Celestial Lining (T5 Trash)", 0)
check(shared_bag_mat_reason == "ok" and #shared_bag_mat > 0,
    "shared match-ref index includes tattered sack upgrade material link")
check((diag_counts["local_needs.semantic.cache_miss"] or 0) > 0,
    "shared compact index materializes semantic refs on demand")
local shared_rule_id = shared_cands[1] and shared_cands[1].rule_id
local shared_ref_id = shared_cands[1] and shared_cands[1].ref_id
local shared_match_id = shared_cands[1] and shared_cands[1].match and shared_cands[1].match.ids
    and shared_cands[1].match.ids[1]
if shared_match_id then
    local by_id_cands, by_id_reason = catalog.shared_compact_candidates_for_link(wizard, "Bad Parse Name", shared_match_id)
    check(by_id_reason == "ok" and by_id_cands[1]
        and by_id_cands[1].rule_id == shared_rule_id
        and by_id_cands[1].ref_id == shared_ref_id,
        "shared compact index reaches one canonical match ref through both name and id")
    check((diag_counts["local_needs.semantic.cache_hit"] or 0) > 0,
        "shared compact index reuses semantic materialization after first candidate use")
else
    check(false, "shared fungal candidate exposes an id match key")
end
check(tick_shared_ready(sk_compact), "shared compact index cooperative build reaches SK readiness")
local shared_jonas, shared_jonas_reason = catalog.shared_compact_candidates_for_link(sk_compact, "Jonas Dagmire's Pisiform", 0)
check(shared_jonas_reason == "ok" and #shared_jonas > 0,
    "shared match-ref index includes Jonas prefixed link alias")
check(tick_shared_ready(war_compact), "shared compact index cooperative build reaches Warrior readiness")
local shared_scales, shared_scales_reason = catalog.shared_compact_candidates_for_link(war_compact, "Scales of the Lava Dragon", 0)
check(shared_scales_reason == "ok" and #shared_scales > 0,
    "shared compact index matches DoN scales linked row")
local function has_name(entry, needle)
    local key = tostring(needle or ""):lower()
    if tostring(entry and entry.item or ""):lower() == key then return true end
    for _, name in ipairs(entry and entry.names or {}) do
        if tostring(name or ""):lower() == key then return true end
    end
    return false
end
check(has_name(shared_scales[1] and shared_scales[1].satisfy, "Kreljnok's Sword of Draconic Power"),
    "shared compact DoN scales Warrior variant includes Warrior epic satisfaction")
local shared_wiz_scales, shared_wiz_scales_reason = catalog.shared_compact_candidates_for_link(wizard, "Scales of the Lava Dragon", 0)
check(shared_wiz_scales_reason == "ok" and #shared_wiz_scales > 0,
    "shared compact index matches DoN scales linked row for Wizard")
check(has_name(shared_wiz_scales[1] and shared_wiz_scales[1].satisfy, "Staff of Draconic Power")
    and not has_name(shared_wiz_scales[1] and shared_wiz_scales[1].satisfy, "Kreljnok's Sword of Draconic Power"),
    "shared compact DoN class variant does not mutate another class satisfaction")
local shared_epic, shared_epic_reason = catalog.shared_compact_candidates_for_link(war_compact, "Kreljnok's Sword of Draconic Power", 55079)
check(shared_epic_reason == "no-row" and #shared_epic == 0,
    "shared compact index keeps DoN scales class epic as satisfaction-only")

catalog.warm_generated_builtin_index("test-startup")
local gen_status = catalog.generated_builtin_index_status()
check(gen_status and gen_status.ready == true and (tonumber(gen_status.locators) or 0) > 0,
    "generated built-in announce index loads and validates")
check(gen_status and tonumber(gen_status.eager_resolved_locators) == 0,
    "generated index load does not eagerly resolve every locator on first link")
local hanvar_name = "Hanvar's Hoop"
local hanvar_by_name, hanvar_name_reason, hanvar_name_meta =
    catalog.generated_builtin_compact_candidates_for_link(sk_compact, hanvar_name, 0)
local hanvar_by_id, hanvar_id_reason, hanvar_id_meta =
    catalog.generated_builtin_compact_candidates_for_link(sk_compact, hanvar_name, 47286)
local function locator_sig(rows)
    local ids = {}
    for _, row in ipairs(rows or {}) do ids[#ids + 1] = tostring(row.locator_id or "") end
    table.sort(ids)
    return table.concat(ids, ",")
end
check(hanvar_name_reason == "ok" and #hanvar_by_name > 0,
    "generated Hanvar name-only lookup resolves")
check(hanvar_id_reason == "ok" and #hanvar_by_id > 0,
    "generated Hanvar lookup with live item id resolves")
check(locator_sig(hanvar_by_name) == locator_sig(hanvar_by_id),
    "generated Hanvar ID=0 and ID=47286 resolve the same canonical candidates")
check((hanvar_name_meta.name_count or 0) > 0 and (hanvar_name_meta.id_count or 0) == 0,
    "generated Hanvar name-only trace records name candidates")
check((hanvar_id_meta.name_count or 0) > 0 and (hanvar_id_meta.id_count or 0) == 0,
    "unknown generated Hanvar item id preserves name candidates")
check(catalog.check_announce_need_for_link(sk_compact, hanvar_name, 0, { skip_live = true }) ~= nil
    and catalog.check_announce_need_for_link(sk_compact, hanvar_name, 47286, { skip_live = true }) ~= nil,
    "Hanvar ID=0 and ID=47286 produce the same missing need truth")
local ber_hanvar = empty_snap("Berserker", "Discord")
local ber_hanvar_name = catalog.generated_builtin_compact_candidates_for_link(ber_hanvar, hanvar_name, 0)
local ber_hanvar_id = catalog.generated_builtin_compact_candidates_for_link(ber_hanvar, hanvar_name, 47286)
check(#ber_hanvar_name > 0 and locator_sig(ber_hanvar_name) == locator_sig(ber_hanvar_id),
    "Berserker Hanvar ID=0 and ID=47286 resolve the same canonical candidates")
check(catalog.check_announce_need_for_link(ber_hanvar, hanvar_name, 0, { skip_live = true }) ~= nil
    and catalog.check_announce_need_for_link(ber_hanvar, hanvar_name, 47286, { skip_live = true }) ~= nil,
    "Berserker Hanvar ID=0 and ID=47286 produce the same missing need truth")
local beaded_dump = "00B8B700000000000000000000000000000000000000000000000061F5D471Beaded Hoop of Demise"
check(catalog.clean_link_item_name(beaded_dump) == "Beaded Hoop of Demise",
    "catalog cleaner preserves all-hex leading item word Beaded")
local gen_cands, gen_reason, gen_meta = catalog.generated_builtin_compact_candidates_for_link(wizard, "Frigid Slime of Suffering", 0)
check(gen_reason == "ok" and #gen_cands > 0 and gen_meta.cache == "hit",
    "generated built-in index direct lookup finds fungal match")
local gen_bag_mat, gen_bag_reason = catalog.generated_builtin_compact_candidates_for_link(wizard, "Master Tailor's Celestial Lining (T5 Trash)", 0)
check(gen_bag_reason == "ok" and #gen_bag_mat > 0,
    "generated built-in index includes tattered sack upgrade material link")
local gen_scales, gen_scales_reason = catalog.generated_builtin_compact_candidates_for_link(war_compact, "Scales of the Lava Dragon", 0)
check(gen_scales_reason == "ok" and #gen_scales > 0,
    "generated built-in index matches DoN scales linked row")
check(has_name(gen_scales[1] and gen_scales[1].satisfy, "Kreljnok's Sword of Draconic Power"),
    "generated built-in DoN scales Warrior locator materializes epic satisfaction")
local gen_epic, gen_epic_reason = catalog.generated_builtin_compact_candidates_for_link(war_compact, "Kreljnok's Sword of Draconic Power", 55079)
check(gen_epic_reason == "no-row" and #gen_epic == 0,
    "generated built-in index keeps DoN scales class epic as satisfaction-only")
do
    local payload = require("generated.builtin_announce_index")
    local custom_locs = 0
    for _, loc in ipairs(payload.locators or {}) do
        if loc.source_kind == "user" or loc.list_id == "custom_announce_test" then
            custom_locs = custom_locs + 1
        end
    end
    check(custom_locs == 0, "generated payload contains zero custom/user locators")
end

catalog.set_list_announce_enabled("jonas", false)
check(catalog.check_announce_need_for_link(sk_compact, "Jonas Dagmire's Pisiform", 0, { skip_live = true }) == nil,
    "disabled built-in list is excluded from authoritative TG")
local disabled_gen, disabled_gen_reason = catalog.generated_builtin_compact_candidates_for_link(sk_compact, "Jonas Dagmire's Pisiform", 0)
check(disabled_gen_reason == "no-row" and #disabled_gen == 0,
    "disabled built-in list is filtered after generated lookup")
catalog.set_list_announce_enabled("jonas", true)

do
    local bis_mod = require("bis")
    local old_load_all, old_list_names, old_get = bis_mod.load_all, bis_mod.list_names, bis_mod.get
    local custom = {
        id = "custom_announce_test",
        name = "Custom Announce Test",
        owner = "Drel",
        class = "Wizard",
        entries = {
            { item = "Custom Only Drop", names = { "Custom Only Drop" }, ids = { 987654 } },
        },
    }
    bis_mod.load_all = function() end
    bis_mod.list_names = function() return { { id = custom.id, name = custom.name, list = custom } } end
    bis_mod.get = function(id) if id == custom.id then return custom end return old_get(id) end
    check(catalog.check_announce_need_for_link(wizard, "Custom Only Drop", 987654, { skip_live = true }) == nil,
        "custom-list-only item does not produce authoritative TG")
    catalog.request_compact_announce_rules(wizard, "custom-ignore-test")
    check(tick_compact_ready(), "compact announce rules rebuild after built-in toggle")
    local custom_compact, custom_compact_reason = catalog.compact_announce_candidates_for_link(wizard, "Custom Only Drop", 987654)
    check(custom_compact_reason == "no-row" and #custom_compact == 0,
        "legacy compact announce candidates ignore custom-list-only item")
    local custom_shared, custom_shared_reason = catalog.shared_compact_candidates_for_link(wizard, "Custom Only Drop", 987654)
    check((custom_shared_reason == "no-row" or custom_shared_reason == "not-ready") and #custom_shared == 0,
        "runtime shared announce candidates ignore custom-list-only item")
    local custom_gen, custom_gen_reason = catalog.generated_builtin_compact_candidates_for_link(wizard, "Custom Only Drop", 987654)
    check(custom_gen_reason == "no-row" and #custom_gen == 0,
        "generated built-in announce index ignores custom-list-only item")
    for _, spec in ipairs(catalog.announce_list_specs() or {}) do
        check(spec.user ~= true and spec.id ~= custom.id,
            "announce list specs are built-in-only")
    end
    bis_mod.load_all, bis_mod.list_names, bis_mod.get = old_load_all, old_list_names, old_get
end
for _, name in ipairs({ "Frigid Slime of Suffering", "Hideous Hex of Noxious Demise" }) do
    local need = catalog.check_announce_need_for_link(wizard, name, 0, { skip_live = true })
    check(need ~= nil, "Wizard empty snap needs " .. name)
end

-- Melee-only preanguish clickies: Wizard should not need; Warrior should.
check(catalog.check_announce_need_for_link(wizard, "Ring of Organic Darkness", 0, { skip_live = true }) == nil,
    "Wizard does not need Ring of Organic Darkness")
local warrior = empty_snap("Warrior", "Discord")
check(catalog.check_announce_need_for_link(warrior, "Ring of Organic Darkness", 0, { skip_live = true }) ~= nil,
    "Warrior empty snap needs Ring of Organic Darkness")

-- Unknown class: class-specific preanguish rows stay gated.
check(catalog.check_announce_need_for_link(empty_snap("?", "Discord"), "Ring of Organic Darkness", 0, { skip_live = true }) == nil,
    "class ? yields no ring need")
-- Unknown class: shared template rows (fungal/augs) still need-check.
check(catalog.check_announce_need_for_link(empty_snap("", "Discord"), "Frigid Slime of Suffering", 0, { skip_live = true }) ~= nil,
    "blank class still needs template fungal item")
check(catalog.check_announce_need_for_link(empty_snap("?", "Discord"), "Hideous Hex of Noxious Demise", 0, { skip_live = true }) ~= nil,
    "class ? still needs template Hideous Hex")

-- Wrong link id that matches an OWNED early row must not hide a real name need.
local chest = catalog.resolve_entry("preanguish", "Wizard", "Chest")
check(chest and chest.ids and chest.ids[1], "Wizard preanguish Chest resolves")
local owned_early = empty_snap("Wizard", "Drel")
owned_early.bags = { { name = chest.item, id = chest.ids[1] } }
local need = catalog.check_announce_need_for_link(
    owned_early, "Frigid Slime of Suffering", chest.ids[1], { skip_live = true })
check(need ~= nil and need.item_name == "Frigid Slime of Suffering",
    "name match preferred over owned wrong-id row")

-- Status explain: owned vs class-gated no-row.
check(catalog.explain_announce_skip_for_link(wizard, "Desolate Black Sapphire", 0, { skip_live = true }) == "no-row",
    "Wizard sapphire explain is no-row")
check(catalog.explain_announce_skip_for_link(warrior, "Desolate Black Sapphire", 0, { skip_live = true }) == "owned"
    or catalog.check_announce_need_for_link(warrior, "Desolate Black Sapphire", 0, { skip_live = true }) ~= nil,
    "Warrior empty sapphire is need (or owned only if somehow present)")
local bloom = "Noxious Bloom of Ebbing Exertion"
check(catalog.check_announce_need_for_link(empty_snap("Enchanter", "Discord"), bloom, 0, { skip_live = true }) ~= nil,
    "empty Enchanter needs Noxious Bloom")
local tiered = empty_snap("Enchanter", "Discord")
tiered.bags = { { name = "Fungal Bloom of Ebbing Exertion - Tier I", id = 1 } }
check(catalog.check_announce_need_for_link(tiered, bloom, 0, { skip_live = true }) == nil,
    "Tier I fungal owns base Noxious Bloom link")
check(catalog.explain_announce_skip_for_link(tiered, bloom, 0, { skip_live = true }) == "owned",
    "Tier I fungal explain is owned")

-- Self-link chat junk on the visible name must not yield no-row.
local junk = bloom .. ' ">'
check(catalog.check_announce_need_for_link(empty_snap("Wizard", "Drel"), junk, 0, { skip_live = true }) ~= nil,
    "trailing quote-angle on bloom name still needs")
check(catalog.clean_link_item_name(bloom .. '">') == bloom, "clean strips trailing quote-angle")
check(catalog.clean_link_item_name("\x12ABC\x12" .. bloom .. '">') == bloom,
    "clean strips link frames and trailing junk")
local hex_bloom = "008CCD00000000000000000000000000000000000000000000000AC7F59C9" .. bloom .. '">'
check(catalog.clean_link_item_name(hex_bloom) == bloom, "clean strips leading item-link hex")
check(catalog.check_announce_need_for_link(empty_snap("Wizard", "Drel"), hex_bloom, 0, { skip_live = true }) ~= nil,
    "hex-prefixed bloom name still needs")
local sapphire = "Desolate Black Sapphire"
local hex_sap = "008CCD00000000000000000000000000000000000000000000000AC7F59C9" .. sapphire .. '">'
check(catalog.clean_link_item_name(hex_sap) == sapphire, "clean strips hex from sapphire")
check(catalog.check_announce_need_for_link(empty_snap("Shadow Knight", "Drel"), hex_sap, 0, { skip_live = true }) ~= nil,
    "hex-prefixed sapphire still needs for SK")
check(catalog.check_announce_need_for_link(empty_snap("Berserker", "Discord"), hex_sap, 0, { skip_live = true }) ~= nil,
    "hex-prefixed sapphire still needs for Ber")

-- BiS paint (bis_search) wins over Store for peer columns — same as the grid.
do
    local slot_hits = {}
    package.loaded["bis_search"] = {
        slot_rec = function(snap, list_id, slot)
            local k = tostring(snap and snap.name) .. "\31" .. tostring(list_id) .. "\31" .. tostring(slot)
            return slot_hits[k]
        end,
    }
    local function paint(list_id, slot, status)
        slot_hits["Discord\31" .. list_id .. "\31" .. slot] = {
            status = status, count = status == "missing" and 0 or 1, name = bloom, location = "Bags",
        }
    end
    local peer = empty_snap("Enchanter", "Discord")
    peer.bags = { { name = bloom, id = 42 } } -- Store says owned
    paint("fungal", "Base Noxious Bloom of Ebbing Exertion (Double Attack)", "missing")
    check(catalog.check_announce_need_for_link(peer, bloom, 0, { skip_live = true }) ~= nil,
        "bis_search missing overrides Store owned (BiS paint truth)")
    -- All matching announce lists must paint owned (bloom hits fungal + sebilis).
    paint("fungal", "Base Noxious Bloom of Ebbing Exertion (Double Attack)", "carried")
    paint("sebilis", "FlowerAug3 (Double Attack)", "carried")
    local empty_peer = empty_snap("Enchanter", "Discord")
    check(catalog.check_announce_need_for_link(empty_peer, bloom, 0, { skip_live = true }) == nil,
        "bis_search carried overrides empty Store (BiS paint truth)")
    package.loaded["bis_search"] = nil
end

print(string.format("announce_link_need: %d passed, %d failed", pass, fail))
os.exit(fail == 0 and 0 or 1)
