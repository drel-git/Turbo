-- TurboGear/announcer.lua
-- (needs-index fast path added 2026-07-04)
-- BiS linked-needs: the box that links an item starts a short aggregation
-- window. Peers evaluate their own lists and privately report needs back, so
-- chat gets one grouped line instead of one line per responder.

local mq  = require('mq')
local cfg = require('config')
local CFG, SharedSettings = cfg.CFG, cfg.SharedSettings
local state = require('state')
local catalog = require('bis_catalog')
local gather_self_snapshot = require('snapshot')
local item_actions = require('item_actions')
local diag = require('diagnostics')
local Store = require('store').Store
local needs_index = require('needs_index')
local rules = require('announce_rules')
local roster_sets = require('roster_sets')

local M = { registered = false }
local registered_events = {}
local recent = {}
local pending = {}
local pending_items = {}
local announce_outbox = {}
local group_announces = {}
local targeted_checks = {}
local targeted_seen = {}
local text_batches = {}
local next_announce_send_at = 0
local announce_ready = false
local settings_refresh_ms = 0
local MULTI_ANNOUNCE_DELAY_MS = 75
local needs_index_warm = true
local passive = false
local SETTINGS_REFRESH_MS = 10000
local PENDING_TTL_S = 300.0
local DEFAULT_PENDING_MAX = 64
local DEFAULT_OUTBOX_MAX = 64
local DEFAULT_REPLAY_TTL_S = 90.0
local DEFAULT_REPLAY_MAX = 24
local DEFAULT_GROUP_WINDOW_MS = 75

local runtime = {
    last_loot_at = 0,
    last_loot_item = "",
    last_loot_source = "",
    last_sent_at = 0,
    last_sent_item = "",
    last_skip_at = 0,
    last_skip_item = "",
    last_skip_reason = "",
    last_pending_at = 0,
    last_pending_item = "",
    last_pending_source = "",
    last_pending_reason = "",
    duplicate_suppressed = 0,
    pending_dropped = 0,
    outbox_dropped = 0,
    replay_checked = 0,
    replay_sent = 0,
    replay_received = 0,
    replay_requested_at = 0,
    replay_ready_requested = false,
    last_replay_notice_at = 0,
    startup_notice_printed = false,
    ready_notice_printed = false,
    last_group_scan_at = 0,
    last_group_scan_source = "",
    last_group_scan_mode = "",
    last_group_scan_items = 0,
    last_group_scan_snaps = 0,
    last_group_scan_added = 0,
    last_group_scan_pending = 0,
    last_chat_at = 0,
    last_chat_sample = "",
    last_chat_links = 0,
    last_chat_first_item = "",
    last_chat_note = "",
    target_checks_completed = 0,
    target_checks_pending = 0,
}
local recent_replay = {}
local replay_received_seen = {}
-- Fleet-wide dedupe: items seen in ANY [TG] line (ours or another box's).
-- Suppresses queued/pending/replayed re-announces without needing actors.
local announce_seen = {}
local item_announce_recent = {}
local linked_items = {}
local linked_item_seq = 0
local LINKED_ITEMS_MAX = 20
local LINKED_ITEMS_TTL_S = 600

local function pending_max()
    return math.max(16, math.floor(tonumber(CFG.announce_pending_max) or DEFAULT_PENDING_MAX))
end

local function outbox_max()
    return math.max(16, math.floor(tonumber(CFG.announce_outbox_max) or DEFAULT_OUTBOX_MAX))
end

local function replay_ttl_s()
    return math.max(15, tonumber(CFG.announce_replay_ttl_s) or DEFAULT_REPLAY_TTL_S)
end

local function replay_max()
    return math.max(4, math.floor(tonumber(CFG.announce_replay_max) or DEFAULT_REPLAY_MAX))
end

local function group_window_s()
    return math.max(0.05, (tonumber(CFG.announce_group_window_ms) or DEFAULT_GROUP_WINDOW_MS) / 1000)
end

local function dprint(...)
    local Engine = require('engine').Engine
    if Engine and Engine.debug then
        diag.count("announce.debug_events")
    end
end

local function me_name()
    return mq.TLO.Me.CleanName() or "I"
end

local function trim(s)
    return tostring(s or ""):match("^%s*(.-)%s*$") or ""
end

local function announce_seen_ttl_s()
    return math.max(5, tonumber(CFG.announce_seen_ttl_s) or 90)
end

local function item_announce_cooldown_s()
    return math.max(0, tonumber(CFG.announce_item_cooldown_s) or 30)
end

-- Coordinator beacon: while a driver UI is announce-active it stamps shared
-- settings; bg responders on the same machine defer their chat-triggered
-- announces to it ("driver-first"). Staleness (driver closed/crashed) makes
-- bg boxes resume automatically. The fleet-wide [TG] dedupe remains the
-- safety net for warm-up races and multi-PC fleets.
local coordinator_beacon_next = 0

local function tick_coordinator_beacon()
    if state.bg == true or passive then return end
    if SharedSettings.bisAnnounceEnabled == false then return end
    local now = os.clock()
    if now < coordinator_beacon_next then return end
    coordinator_beacon_next = now + math.max(10, tonumber(CFG.announce_coordinator_beacon_s) or 30)
    SharedSettings.announceCoordinatorSeenAt = os.time()
    pcall(function()
        if cfg.SaveSharedSettings then cfg.SaveSharedSettings() end
    end)
end

local function coordinator_active()
    if state.bg ~= true then return false end
    return rules.beacon_fresh(
        SharedSettings.announceCoordinatorSeenAt,
        os.time(),
        tonumber(CFG.announce_coordinator_ttl_s) or 90)
end

-- The dedupe maps only ever gained keys; prune entries that are far past
-- their windows so long sessions do not grow them without bound.
local function prune_recent_sent()
    local cutoff = os.clock() - math.max(30, (tonumber(CFG.bis_announce_cooldown_s) or 1.8) * 10)
    for key, at in pairs(recent) do
        if (tonumber(at) or 0) < cutoff then recent[key] = nil end
    end
    local seen_cutoff = os.clock() - (announce_seen_ttl_s() * 2)
    for key, at in pairs(announce_seen) do
        if (tonumber(at) or 0) < seen_cutoff then announce_seen[key] = nil end
    end
    local item_cutoff = os.clock() - math.max(30, item_announce_cooldown_s() * 2)
    for key, at in pairs(item_announce_recent) do
        if (tonumber(at) or 0) < item_cutoff then item_announce_recent[key] = nil end
    end
end

local function refresh_settings_if_due()
    local now_ms = (mq.gettime and mq.gettime()) or (os.time() * 1000)
    if (now_ms - settings_refresh_ms) < SETTINGS_REFRESH_MS then return false end
    settings_refresh_ms = now_ms
    diag.time("announce.settings_reload", function()
        cfg.LoadSharedSettings()
    end)
    prune_recent_sent()
    return true
end

local function announce_work_pending()
    if #pending > 0 or #pending_items > 0 or #announce_outbox > 0 or #targeted_checks > 0 then return true end
    for _, _ in pairs(group_announces or {}) do return true end
    return false
end

-- Line classification and skip rules live in announce_rules.lua (pure, tested).
local function should_skip_line(line)
    return rules.should_skip_line(line, me_name())
end

local is_player_link_chat_line = rules.is_player_link_chat_line
local is_self_loot_line = rules.is_self_loot_line
local is_other_player_chat_line = rules.is_other_player_chat_line

local function link_name(item)
    if type(item) ~= "table" then return nil, 0 end
    local name = item.itemName or item.name or item.Name or item.item
    local id = tonumber(item.itemID or item.itemId or item.id or item.ItemID or 0) or 0
    name = name and tostring(name) or ""
    if name == "" then return nil, id end
    return name, id
end

local function copy_items(items)
    local out = {}
    for _, item in ipairs(items or {}) do
        local name = tostring(item and item.name or "")
        if name ~= "" then
            local cid = tonumber(item.corpse_id)
            out[#out + 1] = {
                name = name,
                id = tonumber(item.id) or 0,
                link = tostring(item.link or ""),
                corpse_id = (cid and cid > 0) and math.floor(cid) or nil,
            }
        end
    end
    return out
end

local function prune_recent_replay(now)
    now = now or os.clock()
    local ttl = replay_ttl_s()
    for i = #recent_replay, 1, -1 do
        local at = tonumber(recent_replay[i] and recent_replay[i].at) or 0
        if at <= 0 or (now - at) > ttl then
            table.remove(recent_replay, i)
        end
    end
    while #recent_replay > replay_max() do
        table.remove(recent_replay, 1)
    end
end

local function replay_entry_sig(line, items)
    local parts = { tostring(line or "") }
    for _, item in ipairs(items or {}) do
        parts[#parts + 1] = tostring(item.name or ""):lower() .. ":" .. tostring(math.floor(tonumber(item.id) or 0))
    end
    return table.concat(parts, "|")
end

local function remember_recent_replay(line, items, source)
    line = tostring(line or "")
    items = copy_items(items)
    if #items == 0 then return end

    local now = os.clock()
    prune_recent_replay(now)
    local sig = replay_entry_sig(line, items)
    if sig == "" then return end
    for i = #recent_replay, 1, -1 do
        if recent_replay[i] and recent_replay[i].sig == sig then
            table.remove(recent_replay, i)
            break
        end
    end
    recent_replay[#recent_replay + 1] = {
        at = now,
        sig = sig,
        source = tostring(source or ""),
        line = line,
        items = items,
    }
    prune_recent_replay(now)
end

local function prune_replay_received_seen(now)
    now = now or os.clock()
    local ttl = replay_ttl_s()
    for sig, at in pairs(replay_received_seen) do
        at = tonumber(at) or 0
        if at <= 0 or (now - at) > ttl then
            replay_received_seen[sig] = nil
        end
    end
end

local function clean_text_candidate(s)
    s = tostring(s or "")
    s = s:gsub("\r", " "):gsub("\n", " ")
    s = s:gsub("^%s+", ""):gsub("%s+$", "")
    s = s:gsub("^['\"`]+", ""):gsub("['\"`]+$", "")
    s = s:gsub("^%s+", ""):gsub("%s+$", "")
    return s
end

-- Visible item name from a TurboLoot control payload that may wrap a clickable
-- link. Other-player mq.event lines often keep \x12 frames but drop a clean
-- ExtractLinks hit; strip frames and read the name before "(ID: n)".
local function control_line_item_name(payload)
    payload = tostring(payload or "")
    if payload == "" then return nil end
    -- Try ParseItemLink on any raw frames first (best when the frame is intact).
    if mq.ParseItemLink then
        for frame in payload:gmatch("\x12([^\x12]+)\x12") do
            local raw = "\x12" .. frame .. "\x12"
            local pok, item = pcall(function() return mq.ParseItemLink(raw) end)
            if pok and type(item) == "table" then
                local name = link_name(item)
                if name and name ~= "" then return name end
            end
        end
    end
    local plain = payload:gsub("\x12[^\x12]*\x12", " "):gsub("\x12", " ")
    local name = plain:match("^%s*(.-)%s*%(%s*ID%s*:%s*%d+%s*%)")
    name = clean_text_candidate(name)
    if name == "" then return nil end
    return name
end

local function parse_item_links(line)
    local out = {}
    local seen = {}
    local function is_control_tag(tag)
        local tag_l = tostring(tag or ""):lower()
        return tag_l:find("announce", 1, true)
            or tag_l:find("skip", 1, true)
            or tag_l:find("ignore", 1, true)
            or tag_l:find("sell", 1, true)
            or tag_l:find("bank", 1, true)
            or tag_l:find("tribute", 1, true)
            or tag_l:find("destroy", 1, true)
            or tag_l:find("keep", 1, true)
            or tag_l:find("value", 1, true)
    end
    local function add_item(name, id, link)
        name = clean_text_candidate(name)
        id = tonumber(id) or 0
        if name == "" then return end
        local key = (id > 0 and ("id:" .. tostring(math.floor(id)))) or ("name:" .. rules.normalize_item_name(name))
        if seen[key] then return end
        seen[key] = true
        out[#out + 1] = { name = name, id = id, link = tostring(link or "") }
        if item_actions.looks_like_item_link(link) then
            -- Feed the observed-link cache so later announces can link this
            -- item without possessing it.
            pcall(function() item_actions.remember_item_link(name, id, link) end)
        end
    end

    if mq.ExtractLinks and mq.ParseItemLink and mq.LinkTypes and mq.LinkTypes.Item then
        local ok, links = pcall(function() return mq.ExtractLinks(line) end)
        if ok and type(links) == "table" then
            for _, link in ipairs(links) do
                local raw_link = type(link) == "table" and link.link or link
                local looks_item = type(link) ~= "table"
                    or link.type == mq.LinkTypes.Item
                    or tostring(link.type or ""):lower() == "item"
                if not looks_item and item_actions.looks_like_item_link(raw_link) then
                    looks_item = true
                end
                if looks_item then
                    local pok, item = pcall(function() return mq.ParseItemLink(raw_link) end)
                    if pok and type(item) == "table" then
                        local name, id = link_name(item)
                        if name then add_item(name, id, raw_link) end
                    end
                end
            end
        end
    end

    -- Some MQ builds/event paths preserve the raw clickable-link frame in the
    -- chat line but ExtractLinks returns nothing, especially on self group/raid
    -- chat. Parse each raw frame directly before falling back to plain text.
    if mq.ParseItemLink then
        for payload in tostring(line or ""):gmatch("\x12([^\x12]+)\x12") do
            local raw_link = "\x12" .. payload .. "\x12"
            local pok, item = pcall(function() return mq.ParseItemLink(raw_link) end)
            if pok and type(item) == "table" then
                local name, id = link_name(item)
                if name then add_item(name, id, raw_link) end
            end
        end
    end

    -- TurboLoot-style control lines are often plain text, not MQ item links:
    -- [ANNOUNCE] Adventurer's Tattered Sack (ID: 34)
    -- [SKIP] Essence of Earth (ID: 148) - Already have
    -- TurboLoot's displayed ID is the corpse/target ID, not the item ID. Keep
    -- this fallback name-only; real item IDs come from parsed clickable links.
    -- Always run this even when ExtractLinks already hit: other-player events
    -- sometimes yield a useless/empty parse while the control text is intact.
    for tag, payload_start in tostring(line or ""):gmatch("%[([^%]]+)%]()") do
        if is_control_tag(tag) then
            local payload = tostring(line or ""):sub(payload_start)
            local name = control_line_item_name(payload)
            if name then add_item(name, 0, nil) end
        end
    end

    -- ANNOUNCE/SKIP-class lines mean the item was left ON that corpse; carry
    -- the corpse spawn id so the linked-items panel can offer "go loot it".
    local corpse_id = rules.corpse_id_from_line(line)
    if corpse_id then
        for _, item in ipairs(out) do item.corpse_id = corpse_id end
    end

    return out
end

local function has_unparseable_item_link_payload(line)
    line = tostring(line or "")
    if line == "" then return false end
    if line:find("\x12", 1, true) then return true end
    -- MQ sometimes exposes outgoing self links as visible hex-ish payload text
    -- in mq.event callbacks. Require a long run so normal item/chat text does
    -- not enter the fallback.
    return line:find("%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x") ~= nil
end

local function text_item_candidates(line)
    line = tostring(line or "")
    local out, seen = {}, {}
    local function add(s)
        s = clean_text_candidate(s)
        if s == "" or #s < 3 or #s > 96 then return end
        local key = s:lower()
        if seen[key] then return end
        seen[key] = true
        out[#out + 1] = s
    end

    for q in line:gmatch("'([^']+)'") do add(q) end
    for q in line:gmatch('"([^"]+)"') do add(q) end

    local payload = line:match("^[^,]+,%s*(.+)$")
    if payload then add(payload) end
    add(line)

    while #out > 4 do table.remove(out) end
    return out
end

local normalize_item_name = rules.normalize_item_name

-- Record any [TG] line we hear (from any box) so the same item is not
-- re-announced fleet-wide inside the announce_seen window. Also feeds the
-- observed-link cache when the payload is a raw link.
local function note_announce_seen(line)
    local payload = rules.parse_tg_line(line)
    if not payload then return end
    local name, id = payload, 0
    if item_actions.looks_like_item_link(payload) then
        local ok, item = pcall(function()
            return mq.ParseItemLink and mq.ParseItemLink(payload) or nil
        end)
        if ok and type(item) == "table" then
            local n, i = link_name(item)
            if n and n ~= "" then name = n end
            id = tonumber(i) or 0
        end
        pcall(function()
            item_actions.remember_item_link(name ~= payload and name or "", id, payload)
        end)
    end
    local now = os.clock()
    if tostring(name or "") ~= "" and not item_actions.looks_like_item_link(name) then
        announce_seen["name:" .. normalize_item_name(name)] = now
    end
    if id > 0 then
        announce_seen["id:" .. tostring(math.floor(id))] = now
    end
end

local function announce_seen_recently(item_name, item_id)
    local ttl = announce_seen_ttl_s()
    local now = os.clock()
    item_id = tonumber(item_id) or 0
    if item_id > 0 then
        local at = announce_seen["id:" .. tostring(math.floor(item_id))]
        if at and (now - at) <= ttl then return true end
    end
    local at = announce_seen["name:" .. normalize_item_name(item_name)]
    return at ~= nil and (os.clock() - at) <= ttl
end

local function item_cooldown_key(item_name, item_id)
    item_id = tonumber(item_id) or 0
    local name = normalize_item_name(item_name)
    if name ~= "" then return "name:" .. name end
    if item_id > 0 then return "id:" .. tostring(math.floor(item_id)) end
    return ""
end

local function item_announced_recently(item_name, item_id)
    local ttl = item_announce_cooldown_s()
    if ttl <= 0 then return false end
    local key = item_cooldown_key(item_name, item_id)
    if key == "" then return false end
    local at = item_announce_recent[key]
    return at ~= nil and (os.clock() - at) <= ttl
end

local function note_item_announced(item_name, item_id)
    local key = item_cooldown_key(item_name, item_id)
    if key ~= "" then item_announce_recent[key] = os.clock() end
end

local note_recent_sent, recently_sent, note_skip, note_sent, note_loot_seen
local snap_for_announce

local function dedupe_key(item_name, list_id, item_id)
    return rules.dedupe_key(mq.TLO.MacroQuest.Server(), me_name(), list_id, item_name, item_id)
end

local function grouped_item_key(item_name, item_id, item_link)
    return rules.grouped_item_key(item_name, item_id, item_link, item_actions.looks_like_item_link)
end

local function copy_order(order)
    local out = {}
    if type(order) ~= "table" then return out end
    for _, name in ipairs(order) do
        name = trim(name)
        if name ~= "" then out[#out + 1] = name end
    end
    return out
end

local function linked_item_display_key(item_name)
    local name = normalize_item_name(item_name)
    if name == "" then return "" end
    return "name:" .. name
end

local function prune_linked_items(now)
    now = tonumber(now) or os.clock()
    local kept = {}
    local seen = {}
    for _, row in ipairs(linked_items or {}) do
        local at = tonumber(row and row.at) or now
        if row then row.display_key = row.display_key or linked_item_display_key(row.item_name) end
        local dedupe = tostring((row and row.display_key ~= "" and row.display_key) or (row and row.key) or "")
        if (now - at) <= LINKED_ITEMS_TTL_S and (dedupe == "" or not seen[dedupe]) then
            if dedupe ~= "" then seen[dedupe] = true end
            kept[#kept + 1] = row
            if #kept >= LINKED_ITEMS_MAX then break end
        end
    end
    linked_items = kept
end

local function row_corpse_id(bucket)
    local cid = tonumber(bucket and bucket.corpse_id)
    if cid and cid > 0 then return math.floor(cid) end
    return nil
end

local function record_linked_item(bucket, status)
    if type(bucket) ~= "table" or type(bucket.order) ~= "table" or #bucket.order == 0 then return end
    local key = tostring(bucket.key or grouped_item_key(bucket.item_name, bucket.item_id, bucket.item_link))
    local display_key = linked_item_display_key(bucket.item_name)
    if key == "" or key == "name:" then return end
    local now = os.clock()
    prune_linked_items(now)
    for i, row in ipairs(linked_items) do
        if row.key == key or (display_key ~= "" and row.display_key == display_key) then
            row.item_name = tostring(bucket.item_name or row.item_name or "")
            row.item_id = tonumber(bucket.item_id) or row.item_id or 0
            row.item_link = tostring(bucket.item_link or row.item_link or "")
            row.key = key
            row.display_key = display_key
            row.needers = copy_order(bucket.order)
            row.source = tostring(bucket.source or row.source or "")
            row.status = tostring(status or row.status or "")
            row.at = now
            local cid = tonumber(bucket.corpse_id)
            if cid and cid > 0 then
                row.corpse_id = math.floor(cid)
                row.corpse_at = tonumber(bucket.corpse_at) or now
            end
            table.remove(linked_items, i)
            table.insert(linked_items, 1, row)
            return
        end
    end
    linked_item_seq = linked_item_seq + 1
    table.insert(linked_items, 1, {
        id = linked_item_seq,
        key = key,
        display_key = display_key,
        item_name = tostring(bucket.item_name or ""),
        item_id = tonumber(bucket.item_id) or 0,
        item_link = tostring(bucket.item_link or ""),
        needers = copy_order(bucket.order),
        source = tostring(bucket.source or ""),
        status = tostring(status or ""),
        at = now,
        corpse_id = row_corpse_id(bucket),
        corpse_at = tonumber(bucket.corpse_at),
    })
    prune_linked_items(now)
end

local function display_payload(item_name, item_link)
    local link = tostring(item_link or "")
    if item_actions.looks_like_item_link(link) then return link end
    return tostring(item_name or "?")
end

local function manual_channel_command(channel)
    channel = tostring(channel or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if channel == "g" or channel == "group" or channel == "/g" then return "/g" end
    if channel == "r" or channel == "raid" or channel == "rs" or channel == "rsay" or channel == "/rs" or channel == "/rsay" then return "/rs" end
    if channel == "gu" or channel == "guild" or channel == "/gu" then return "/gu" end
    if channel == "s" or channel == "say" or channel == "/s" or channel == "/say" then return "/say" end
    return nil
end

local function resolve_group_item_link(item_name, item_link, item_id)
    local resolved = item_actions.resolve_announce_link(item_name, item_link, item_id)
    if resolved ~= "" and item_actions.looks_like_item_link(resolved) then return resolved end
    return nil
end

local function note_group_scan(mode, source, items, snaps, added)
    runtime.last_group_scan_at = os.clock()
    runtime.last_group_scan_mode = tostring(mode or "")
    runtime.last_group_scan_source = tostring(source or "")
    runtime.last_group_scan_items = tonumber(items) or 0
    runtime.last_group_scan_snaps = tonumber(snaps) or 0
    runtime.last_group_scan_added = tonumber(added) or 0
    runtime.last_group_scan_pending = #targeted_checks
end

local function ensure_group_announce(item_name, item_link, item_id, source, corpse_id)
    local key = grouped_item_key(item_name, item_id, item_link)
    if key == "name:" then return nil end
    local now = os.clock()
    local bucket = group_announces[key]
    if not bucket then
        bucket = {
            key = key,
            item_name = tostring(item_name or "?"),
            item_link = tostring(item_link or ""),
            item_id = tonumber(item_id) or 0,
            source = tostring(source or ""),
            names = {},
            order = {},
            sources = {},
            created = now,
            due = now + group_window_s(),
            pending_targets = 0,
            target_total = 0,
        }
        group_announces[key] = bucket
    else
        if tostring(item_link or "") ~= "" then bucket.item_link = tostring(item_link) end
        -- Never overwrite an established bucket name: late needers (actor
        -- replies, index aliases) must not rename an already-correct bucket.
        local have_name = tostring(bucket.item_name or "")
        if (have_name == "" or have_name == "?") and tostring(item_name or "") ~= "" then
            bucket.item_name = tostring(item_name)
        end
        if (tonumber(item_id) or 0) > 0 then bucket.item_id = tonumber(item_id) or 0 end
        bucket.due = math.max(tonumber(bucket.due) or now, now + group_window_s())
    end
    -- Corpse hint (from TurboLoot ANNOUNCE/SKIP lines): newest wins so a fresh
    -- drop of the same item replaces a stale corpse id.
    local cid = tonumber(corpse_id)
    if cid and cid > 0 then
        bucket.corpse_id = math.floor(cid)
        bucket.corpse_at = now
    end
    return bucket
end

local function target_seen_key(bucket_key, char_key)
    return tostring(bucket_key or "") .. "\31" .. tostring(char_key or "")
end

local function clear_targeted_seen(bucket_key)
    local prefix = tostring(bucket_key or "") .. "\31"
    for key, _ in pairs(targeted_seen) do
        if tostring(key):sub(1, #prefix) == prefix then targeted_seen[key] = nil end
    end
end

local function finish_target_check(bucket)
    if bucket then
        bucket.pending_targets = math.max(0, (tonumber(bucket.pending_targets) or 0) - 1)
    end
    runtime.target_checks_completed = (runtime.target_checks_completed or 0) + 1
end

local function add_group_need(item_name, item_link, item_id, character, source)
    character = trim(character)
    if character == "" then return false end
    local bucket = ensure_group_announce(item_name, item_link, item_id, source)
    if not bucket then return false end
    local key = character:lower()
    if not bucket.names[key] then
        bucket.names[key] = character
        bucket.order[#bucket.order + 1] = character
    end
    -- Track WHERE each needer came from: actor-reply needers were just
    -- live-confirmed on their own box; cache/index needers may be stale and
    -- get a confirm round before the announce goes out.
    bucket.sources = bucket.sources or {}
    if source == "actor-reply" or not bucket.sources[key] then
        bucket.sources[key] = tostring(source or "")
    end
    return true
end

local function local_snap_key()
    return tostring(mq.TLO.MacroQuest.Server() or "?") .. "_" .. tostring(me_name())
end

local function should_scan_peer_snapshot(key, snap)
    if type(snap) ~= "table" then return false end
    if Store.is_recently_visible and Store.is_recently_visible(key, snap) then return true end
    return tostring(snap.status or "") == "online" or tostring(snap.status or "") == "stale"
end

local function group_scan_snapshots()
    local snaps = {}
    local local_key = local_snap_key()
    for _, key in ipairs(roster_sets.active_store_keys(cfg.Settings.bisRosterScope or "online", { for_announce = true })) do
        if key == local_key then
            local local_snap = snap_for_announce()
            if local_snap then
                snaps[#snaps + 1] = { key = local_key, snap = local_snap, local_owner = true }
            end
        else
            local snap = Store.get(key)
            if should_scan_peer_snapshot(key, snap) then
                snaps[#snaps + 1] = { key = key, snap = snap, local_owner = false }
            end
        end
    end
    return snaps
end

local function peer_index_allowed()
    if CFG.needs_index_build_peers ~= true then return false end
    -- Both the UI driver and bg responder build peer needs. When a UI is up
    -- the bg is announce-passive but still ticks the index (init.lua) so its
    -- direct catalogs land on disk for the UI to load; the UI also boosts its
    -- lean budget when the oldest queued rebuild goes stale.
    return true
end

local function view_label_for_status()
    local view_key = tostring(cfg.Settings.bisViewKey or roster_sets.VIEW_ALL)
    if view_key == "" or view_key == roster_sets.VIEW_ALL then
        return "All Characters"
    end
    if view_key == roster_sets.VIEW_SELECTED then
        local n = 0
        local selected = cfg.Settings.bisViewSelectedChars
        if type(selected) == "table" then
            for _, _ in pairs(selected) do n = n + 1 end
        end
        return string.format("Selected (%d)", n)
    end
    if view_key == "__self__" or view_key == local_snap_key() then
        return me_name()
    end
    local snap = Store.get(view_key)
    return tostring(snap and snap.name or view_key)
end

local function active_announce_roster_status(limit)
    limit = tonumber(limit) or 12
    local keys = roster_sets.active_store_keys(cfg.Settings.bisRosterScope or "online", { for_announce = true })
    local names = {}
    for _, key in ipairs(keys) do
        local name
        if key == local_snap_key() then
            name = me_name()
        else
            local snap = Store.get(key)
            name = tostring(snap and snap.name or key)
        end
        if tostring(name or "") ~= "" then
            names[#names + 1] = tostring(name)
        end
        if #names >= limit then break end
    end
    return {
        scope = roster_sets.scope_label(cfg.Settings.bisRosterScope or "online"),
        view = view_label_for_status(),
        count = #keys,
        names = table.concat(names, ", "),
        truncated = #keys > #names,
    }
end

local function try_direct_need_for_snapshot(item, row, item_link, bucket, source)
    local snap = row and row.snap
    if type(snap) ~= "table" or not snap.class or snap.class == "?" then return 0, true end
    local item_name = tostring(item and item.name or "")
    if item_name == "" then return 0, true end
    local item_id = tonumber(item and item.id) or 0
    local need = catalog.check_announce_need_direct(snap, item_name, item_id, {
        skip_live = not (row and row.local_owner),
    })
    if need then
        return add_group_need(item_name, item_link, item_id, tostring(snap.name or row.key or "?"), source or "direct-cache") and 1 or 0, true
    end
    return 0, true
end

local function queue_target_check(item, row, item_link, bucket, source)
    if not bucket or type(row) ~= "table" or type(row.snap) ~= "table" then return false end
    local char_key = tostring(row.key or "")
    if char_key == "" then return false end
    local skey = target_seen_key(bucket.key, char_key)
    if targeted_seen[skey] then return false end
    targeted_seen[skey] = true

    bucket.pending_targets = (tonumber(bucket.pending_targets) or 0) + 1
    bucket.target_total = (tonumber(bucket.target_total) or 0) + 1
    bucket.due = math.max(tonumber(bucket.due) or 0, os.clock() + group_window_s())
    targeted_checks[#targeted_checks + 1] = {
        bucket_key = bucket.key,
        item = { name = item.name, id = tonumber(item.id) or 0, link = item.link },
        row = row,
        item_link = item_link,
        source = tostring(source or "targeted"),
        at = os.clock(),
    }
    runtime.target_checks_pending = #targeted_checks
    diag.count("announce.target_checks_queued")
    return true
end

local function queue_group_target_checks(item, item_link, bucket, source)
    local added, queued, snaps = 0, 0, 0
    for _, row in ipairs(group_scan_snapshots()) do
        local key = tostring(row.key or "")
        if key ~= "" and type(row.snap) == "table" then
            snaps = snaps + 1
            local skey = target_seen_key(bucket and bucket.key or "", key)
            if not targeted_seen[skey] then
                local idx = catalog.direct_catalog_if_ready(row.snap.class, row.snap.name)
                if idx then
                    targeted_seen[skey] = true
                    local hit = try_direct_need_for_snapshot(item, row, item_link, bucket, source)
                    added = added + (tonumber(hit) or 0)
                elseif queue_target_check(item, row, item_link, bucket, source) then
                    queued = queued + 1
                end
            end
        end
    end
    return added, queued, snaps
end

local function text_batch_pending(batch_key)
    local batch = text_batches[tostring(batch_key or "")]
    return batch and (tonumber(batch.pending) or 0) or 0
end

local function finish_text_batch_check(batch_key)
    batch_key = tostring(batch_key or "")
    local batch = text_batches[batch_key]
    if not batch then return end
    batch.pending = math.max(0, (tonumber(batch.pending) or 0) - 1)
    if batch.pending <= 0 then batch.finished_at = os.clock() end
end

local function queue_group_text_target_checks(line, source)
    line = tostring(line or "")
    if line == "" then return 0, 0 end
    local batch_key = "text:" .. tostring(os.clock()) .. ":" .. tostring(#line)
    local batch = {
        key = batch_key,
        line = line,
        source = tostring(source or "text-targeted"),
        created = os.clock(),
        pending = 0,
        snaps = 0,
    }
    local queued = 0
    for _, row in ipairs(group_scan_snapshots()) do
        local key = tostring(row.key or "")
        if key ~= "" and type(row.snap) == "table" then
            batch.snaps = batch.snaps + 1
            batch.pending = batch.pending + 1
            targeted_checks[#targeted_checks + 1] = {
                mode = "text",
                batch_key = batch_key,
                row = row,
                line = line,
                source = batch.source,
                at = os.clock(),
            }
            queued = queued + 1
        end
    end
    if queued > 0 then
        text_batches[batch_key] = batch
        runtime.target_checks_pending = #targeted_checks
        note_group_scan("text-targeted", source, 1, batch.snaps, 0)
        diag.count("announce.text_target_checks_queued", queued)
    end
    return queued, batch.snaps
end

local function add_text_candidate_need(hit, row, source, batch_key, corpse_id)
    local snap = row and row.snap
    if type(snap) ~= "table" or not snap.class or snap.class == "?" then return 0 end
    local item_name = tostring(hit and hit.name or "")
    if item_name == "" then return 0 end
    local item_id = tonumber(hit and hit.id) or 0
    local need = catalog.check_announce_need_direct(snap, item_name, item_id, {
        skip_live = not (row and row.local_owner),
    })
    if not need then return 0 end
    note_loot_seen(item_name, source)
    local item_link = resolve_group_item_link(item_name, nil, item_id)
    local bucket = ensure_group_announce(item_name, item_link, item_id, source, corpse_id)
    if bucket then
        bucket.text_batch_key = tostring(batch_key or "")
        bucket.due = math.max(tonumber(bucket.due) or 0, os.clock() + group_window_s())
    end
    return add_group_need(item_name, item_link, item_id, tostring(snap.name or row.key or "?"), source or "text-targeted") and 1 or 0
end

local function scan_group_needs_from_cache(links, source)
    if type(links) ~= "table" or #links == 0 then return 0 end

    local added = 0
    local queued = 0
    local snaps_seen = 0
    local index_enabled = CFG.needs_index_enabled ~= false
    local group_index_ready = index_enabled
        and (needs_index.group_ready and needs_index.group_ready() or needs_index.ready())
    local indexed = index_enabled and needs_index.char_count() or 0
    for _, item in ipairs(links) do
        local item_name = tostring(item and item.name or "")
        if item_name ~= "" then
            note_loot_seen(item_name, source)
            local item_link = resolve_group_item_link(item_name, item.link, item.id)
            local bucket = ensure_group_announce(item_name, item_link, item.id, source, item.corpse_id)
            -- Announce under the LINKED item's own name (a real item), never
            -- an index alias like "... - Tier II" (see needs_index display rules).
            if index_enabled then
                for _, need in ipairs(needs_index.needers_for(item_name, item.id)) do
                    if add_group_need(item_name, item_link, item.id, need.character or "?", "index") then
                        added = added + 1
                    end
                end
            end
            if not group_index_ready then
                local d_added, d_queued, d_snaps = queue_group_target_checks(item, item_link, bucket, source)
                added = added + (tonumber(d_added) or 0)
                queued = queued + (tonumber(d_queued) or 0)
                snaps_seen = math.max(snaps_seen, tonumber(d_snaps) or 0)
            end
            -- Surface Go-loot buttons as soon as we know a corpse id and at
            -- least one needer - don't wait for the [TG] collapse flush.
            if bucket and row_corpse_id(bucket) and type(bucket.order) == "table" and #bucket.order > 0 then
                record_linked_item(bucket, "pending")
            end
        end
    end
    if queued > 0 then
        note_group_scan("links-targeted", source, #links, snaps_seen, added)
        diag.count("announce.group_targeted_queued", queued)
    elseif group_index_ready then
        note_group_scan("links-idx", source, #links, indexed, added)
        if added > 0 then diag.count("announce.index_group_needs") end
    else
        note_group_scan("links-query", source, #links, indexed, added)
        diag.count("announce.group_needs_query")
    end
    return added
end

local function scan_group_text_needs_from_cache(line, source)
    line = tostring(line or "")
    if line == "" then return 0 end

    -- Fast path: scan only the needed-item names (small set) via the index.
    local index_enabled = CFG.needs_index_enabled ~= false
    local group_index_ready = index_enabled
        and (needs_index.group_ready and needs_index.group_ready() or needs_index.ready())
    if group_index_ready then
        local added = 0
        local corpse_id = rules.corpse_id_from_line(line)
        local hits = needs_index.text_needs(line, 24)
        for _, hit in ipairs(hits) do
            local item_link = resolve_group_item_link(hit.name, nil, hit.id)
            local bucket = ensure_group_announce(hit.name, item_link, hit.id, source or "line", corpse_id)
            -- hit.name is the alias that actually appeared in the line; use it
            -- for every needer rather than each needer's own index alias.
            for _, need in ipairs(hit.needers or {}) do
                if add_group_need(hit.name, item_link, hit.id, need.character or "?", source or "line") then
                    added = added + 1
                end
            end
            if bucket and row_corpse_id(bucket) and type(bucket.order) == "table" and #bucket.order > 0 then
                record_linked_item(bucket, "pending")
            end
        end
        note_group_scan("text-idx", source, #hits, needs_index.char_count(), added)
        if added > 0 then diag.count("announce.index_group_text_needs") end
        return added
    end

    -- Same as linked-item fallback above: defer text scans until the grouped
    -- index covers visible peers instead of synchronously walking every cached
    -- peer from chat.
    note_group_scan("text-deferred", source, 0, 0, 0)
    diag.count("announce.group_text_deferred")
    return 0
end

local function send_group_announce(bucket, opts)
    opts = type(opts) == "table" and opts or {}
    if type(bucket) ~= "table" or type(bucket.order) ~= "table" or #bucket.order == 0 then
        return false
    end
    local dedupe = {
        key = tostring(mq.TLO.MacroQuest.Server() or "?") .. ":group:" .. tostring(bucket.key or ""),
        source = bucket.source or "group",
        respect_recent = true,
    }
    local bypass_cooldown = opts.manual == true
    if not bypass_cooldown and recently_sent(dedupe.key) then
        runtime.duplicate_suppressed = (runtime.duplicate_suppressed or 0) + 1
        diag.count("announce.duplicates_suppressed")
        note_skip(bucket.item_name, "duplicate collapse grouped")
        record_linked_item(bucket, "suppressed")
        return false
    end
    if not bypass_cooldown and announce_seen_recently(bucket.item_name, bucket.item_id) then
        runtime.duplicate_suppressed = (runtime.duplicate_suppressed or 0) + 1
        diag.count("announce.fleet_duplicates_suppressed")
        note_skip(bucket.item_name, "another box already announced")
        record_linked_item(bucket, "suppressed")
        return false
    end
    if not bypass_cooldown and item_announced_recently(bucket.item_name, bucket.item_id) then
        runtime.duplicate_suppressed = (runtime.duplicate_suppressed or 0) + 1
        diag.count("announce.item_cooldown_suppressed")
        note_skip(bucket.item_name, "same item announce cooldown")
        record_linked_item(bucket, "suppressed")
        return false
    end
    local cmd = opts.cmd or manual_channel_command(opts.channel) or cfg.bis_announce_command()
    local msg = rules.format_message(display_payload(bucket.item_name, bucket.item_link), bucket.order)
    if item_actions.looks_like_item_link(bucket.item_link) then
        mq.cmd(tostring(cmd or "/g") .. " " .. msg)
    else
        mq.cmdf("/squelch %s %s", cmd, msg)
    end
    note_sent(bucket.item_name)
    note_recent_sent(dedupe.key)
    note_item_announced(bucket.item_name, bucket.item_id)
    record_linked_item(bucket, "sent")
    return true
end

function M.linked_items()
    prune_linked_items(os.clock())
    local now = os.clock()
    local out = {}
    for _, row in ipairs(linked_items or {}) do
        local go = {}
        for name, s in pairs(row.go_status or {}) do go[name] = s end
        out[#out + 1] = {
            id = row.id,
            key = row.key,
            item_name = row.item_name,
            item_id = row.item_id,
            item_link = row.item_link,
            needers = copy_order(row.needers),
            source = row.source,
            status = row.status,
            age_s = math.max(0, now - (tonumber(row.at) or now)),
            corpse_id = row.corpse_id,
            corpse_age_s = row.corpse_at and math.max(0, now - row.corpse_at) or nil,
            go_status = go,
        }
    end
    return out
end

-- "Go loot" round-trip for the linked-items panel. The viewer UI never owns
-- the actor mailbox (static roles), so remote requests are delegated to the
-- local bg responder over the /tgearbg bind; the responder does the actor
-- send. Results come back the same way (/tgear golootnote) so the panel can
-- show what happened.
local function set_go_status(item_name, character, text)
    local dk = linked_item_display_key(item_name)
    for _, row in ipairs(linked_items or {}) do
        if (dk ~= "" and row.display_key == dk) then
            row.go_status = row.go_status or {}
            row.go_status[tostring(character or "?")] = tostring(text or "")
            return true
        end
    end
    return false
end

function M.note_go_status(item_name, character, note)
    return set_go_status(item_name, trim(character), note)
end

local function local_bg_running()
    local ok, running = pcall(function()
        local script = mq.TLO.Lua and mq.TLO.Lua.Script and mq.TLO.Lua.Script(CFG.bg_lua_name)
        return script and script.Status and tostring(script.Status() or ""):upper() == "RUNNING"
    end)
    return ok and running == true
end

-- Panel entry point (any instance). Runs locally for our own character;
-- otherwise hands off to whoever owns the actor mailbox.
function M.go_loot_request(id, character)
    id = tonumber(id) or 0
    character = trim(character)
    if character == "" then return false, "no character" end
    for _, row in ipairs(linked_items or {}) do
        if tonumber(row.id) == id then
            local corpse_id = tonumber(row.corpse_id) or 0
            if corpse_id <= 0 then return false, "no corpse id for this item" end
            if character:lower() == me_name():lower() then
                local ok, err = require('go_loot').request({
                    item_name = row.item_name,
                    item_id = row.item_id,
                    corpse_id = corpse_id,
                    reply_to = "",
                })
                set_go_status(row.item_name, character, ok and "going" or tostring(err or "busy"))
                return ok, err
            end
            return M.dispatch_go_loot(character, corpse_id, row.item_id, row.item_name)
        end
    end
    return false, "item no longer listed"
end

-- Actor send when we own the mailbox; /tgearbg delegation when we are the
-- viewer UI. Also the /tgear[bg] goloot command body.
function M.dispatch_go_loot(character, corpse_id, item_id, item_name)
    character = trim(character)
    item_name = tostring(item_name or "")
    corpse_id = tonumber(corpse_id) or 0
    if character == "" or corpse_id <= 0 then return false, "bad go-loot request" end
    if character:lower() == me_name():lower() then
        local ok, err = require('go_loot').request({
            item_name = item_name,
            item_id = tonumber(item_id) or 0,
            corpse_id = corpse_id,
            reply_to = "",
        })
        set_go_status(item_name, character, ok and "going" or tostring(err or "busy"))
        return ok, err
    end
    local okE, Engine = pcall(function() return require('engine').Engine end)
    if okE and Engine and Engine.ok and type(Engine.send_go_loot) == "function" then
        local sent = Engine.send_go_loot(character, {
            item_name = item_name,
            item_id = tonumber(item_id) or 0,
            corpse_id = corpse_id,
        })
        set_go_status(item_name, character, sent and "sent" or "send failed")
        return sent, sent and nil or "send failed"
    end
    if local_bg_running() then
        mq.cmd(string.format('/squelch /tgearbg goloot %s %d %d %s',
            character, corpse_id, tonumber(item_id) or 0, item_name))
        set_go_status(item_name, character, "sent")
        return true
    end
    return false, "bg responder not running (actor sends live there)"
end

-- Target side: another box asked THIS character to go loot (actor dispatch,
-- runs in the mailbox owner = bg responder).
function M.on_go_loot(msg)
    if type(msg) ~= "table" then return end
    local ok, err = require('go_loot').request({
        item_name = tostring(msg.item_name or ""),
        item_id = tonumber(msg.item_id) or 0,
        corpse_id = tonumber(msg.corpse_id) or 0,
        reply_to = trim(msg.from or ""),
    })
    if not ok then
        pcall(function()
            local Engine = require('engine').Engine
            if Engine and Engine.send_go_loot_result then
                Engine.send_go_loot_result(trim(msg.from or ""), {
                    item_name = tostring(msg.item_name or ""),
                    corpse_id = tonumber(msg.corpse_id) or 0,
                    ok = false,
                    note = tostring(err or "busy"),
                })
            end
        end)
    end
end

-- Origin side: the runner's outcome arrived. Print it, record it, and forward
-- to the viewer UI (separate script, separate Lua state) if one is open.
-- Cooldown map shared by need-confirm and go-loot ownership refreshes so a
-- burst of "owned" signals does not spam request_source for the same peer.
local confirm_refresh_at = {}

function M.on_go_loot_result(msg)
    if type(msg) ~= "table" then return end
    local who = trim(msg.from or "?")
    local note = tostring(msg.note or (msg.ok == true and "looted" or "failed"))
    local item_name = tostring(msg.item_name or "?")
    set_go_status(item_name, who, note)
    print(string.format("\at[TurboGear]\ax go-loot %s: %s - %s", item_name, who, note))
    if state.bg == true then
        local okUi, ui_running = pcall(function()
            local script = mq.TLO.Lua.Script(CFG.lua_name)
            return tostring(script.Status() or ""):upper() == "RUNNING"
        end)
        if okUi and ui_running == true then
            pcall(function()
                mq.cmd(string.format('/squelch /tgear golootnote %s %s %s', who, note, item_name))
            end)
        end
    end
    -- Same ownership refresh as need-confirm: ask the looter for a fast lite
    -- inventory snap so BiS / needs_index drop them as needers without a hitch
    -- (async actor request; disk flush happens when the reply lands).
    local looted = msg.ok == true or note == "looted"
    if looted and who ~= "" and who:lower() ~= me_name():lower() then
        local server = tostring(mq.TLO.MacroQuest.Server() or "?")
        local char_key = server .. "_" .. who
        local now = os.clock()
        local cooldown = math.max(5, tonumber(CFG.announce_confirm_refresh_cooldown_s) or 30)
        if (now - (tonumber(confirm_refresh_at[char_key]) or 0)) >= cooldown then
            confirm_refresh_at[char_key] = now
            pcall(function()
                local Engine = require('engine').Engine
                if Engine and Engine.request_source then
                    Engine.request_source(char_key, true, { fastInventory = true })
                end
            end)
        end
    elseif looted and who:lower() == me_name():lower() then
        -- Local go-loot: inventory_watch.note_change already ran on the runner;
        -- nudge once more here if this instance is the announce UI without the
        -- runner's watch tick owning publish.
        pcall(function() require('inventory_watch').note_change(true, false) end)
    end
end

function M.dismiss_linked_item(id)
    id = tonumber(id) or 0
    for i, row in ipairs(linked_items or {}) do
        if tonumber(row.id) == id then
            table.remove(linked_items, i)
            return true
        end
    end
    return false
end

function M.clear_linked_items()
    linked_items = {}
end

function M.announce_linked_item(id, channel)
    id = tonumber(id) or 0
    for _, row in ipairs(linked_items or {}) do
        if tonumber(row.id) == id then
            local cmd = manual_channel_command(channel)
            if not cmd then return false end
            local item_name = tostring(row.item_name or "?")
            local item_id = tonumber(row.item_id) or 0
            local link = item_actions.resolve_announce_link(item_name, row.item_link, item_id)
            local payload = item_actions.looks_like_item_link(link) and link or item_name
            local msg = "[ANNOUNCE] " .. tostring(payload or "?")
            if item_actions.looks_like_item_link(payload) then
                mq.cmd(tostring(cmd) .. " " .. msg)
            else
                mq.cmd("/squelch " .. tostring(cmd) .. " " .. msg)
            end
            row.status = "linked"
            row.at = os.clock()
            note_sent(item_name)
            return true
        end
    end
    return false
end

local function process_target_check(entry, deadline)
    if type(entry) ~= "table" then return true end
    if entry.mode == "text" then
        local batch = text_batches[tostring(entry.batch_key or "")]
        if batch and batch.expired then
            finish_text_batch_check(entry.batch_key)
            return true
        end
        local row = entry.row or {}
        local snap = row.snap
        if type(snap) ~= "table" or not snap.class or snap.class == "?" then
            finish_text_batch_check(entry.batch_key)
            return true
        end
        local idx = catalog.direct_catalog_if_ready(snap.class, snap.name)
        if not idx then
            idx = catalog.tick_direct_build(snap.class, snap.name, deadline)
        end
        if not idx then return false end

        local added = 0
        local ok, hits = pcall(function()
            return catalog.direct_item_candidates_in_text(
                snap,
                entry.line,
                tonumber(CFG.announce_text_fallback_candidates) or 8)
        end)
        if ok and type(hits) == "table" then
            local corpse_id = rules.corpse_id_from_line(entry.line)
            for _, hit in ipairs(hits) do
                added = added + add_text_candidate_need(
                    hit, row, entry.source or "text-targeted", entry.batch_key, corpse_id)
            end
        end
        if added > 0 then
            diag.count("announce.text_target_checks_hits", added)
            note_group_scan("text-targeted-hit", entry.source or "text-targeted", #((ok and type(hits) == "table") and hits or {}), 1, added)
        end
        finish_text_batch_check(entry.batch_key)
        return true
    end

    local bucket = group_announces[tostring(entry.bucket_key or "")]
    if not bucket then return true end
    local row = entry.row or {}
    local snap = row.snap
    if type(snap) ~= "table" or not snap.class or snap.class == "?" then
        finish_target_check(bucket)
        return true
    end

    local idx = catalog.direct_catalog_if_ready(snap.class, snap.name)
    if not idx then
        idx = catalog.tick_direct_build(snap.class, snap.name, deadline)
    end
    if not idx then return false end

    local added = 0
    local item = entry.item or {}
    local ok, hit = pcall(function()
        local n = try_direct_need_for_snapshot(item, row, entry.item_link, bucket, entry.source or "targeted")
        return tonumber(n) or 0
    end)
    if ok then added = hit end
    if added > 0 then diag.count("announce.target_checks_hits", added) end
    finish_target_check(bucket)
    return true
end

local function drain_targeted_checks()
    if #targeted_checks == 0 then return end
    local budget_ms = math.max(0.25, tonumber(CFG.announce_target_check_budget_ms) or 2)
    local max_entries = math.max(1, math.floor(tonumber(CFG.announce_target_check_max_per_tick) or 2))
    local deadline = os.clock() + (budget_ms / 1000)
    local processed = 0
    while #targeted_checks > 0 and processed < max_entries and os.clock() < deadline do
        local entry = table.remove(targeted_checks, 1)
        local done = process_target_check(entry, deadline)
        processed = processed + 1
        if not done then
            targeted_checks[#targeted_checks + 1] = entry
            break
        end
    end
    runtime.target_checks_pending = #targeted_checks
end

local function confirms_enabled()
    if CFG.announce_confirm_needers == false then return false end
    if SharedSettings.announceUseActor == false then return false end
    local ok, Engine = pcall(function() return require('engine').Engine end)
    return ok and Engine ~= nil and Engine.ok == true
        and type(Engine.send_need_confirm) == "function"
end

-- Live-confirm round for a due bucket: cache-derived peer needers get one
-- actor round-trip ("do you still own/need this?") before the [TG] line goes
-- out, so a stale peer snapshot cannot announce someone who looted the item
-- minutes ago. Runs at most once per bucket; FAIL-OPEN by design - peers that
-- do not answer within announce_confirm_wait_s stay announced (current
-- behavior). Returns true when the bucket should be held for replies.
local function try_start_confirm_round(bucket, now)
    if type(bucket) ~= "table" or type(bucket.order) ~= "table" or #bucket.order == 0 then
        return false
    end
    if bucket.confirms_sent then return false end -- due passed again = wait expired
    bucket.confirms_sent = true
    if not confirms_enabled() then return false end
    local targets = rules.confirmable_needers(bucket.order, bucket.sources, me_name())
    if #targets == 0 then return false end
    local Engine = require('engine').Engine
    local sent = 0
    for _, character in ipairs(targets) do
        local ok, did = pcall(function()
            return Engine.send_need_confirm(character, {
                item_name = bucket.item_name,
                item_id = bucket.item_id,
                bucket_key = bucket.key,
            })
        end)
        if ok and did then sent = sent + 1 end
    end
    if sent == 0 then return false end
    bucket.pending_confirms = sent
    bucket.confirm_started = now
    bucket.due = now + math.max(0.25, tonumber(CFG.announce_confirm_wait_s) or 2.0)
    runtime.confirm_requests = (runtime.confirm_requests or 0) + sent
    diag.count("announce.confirm_requests", sent)
    return true
end

local function drain_group_announces()
    local now = os.clock()
    for key, bucket in pairs(group_announces) do
        local pending_targets = bucket and (tonumber(bucket.pending_targets) or 0) or 0
        local batch_key = bucket and tostring(bucket.text_batch_key or "") or ""
        local pending_text = batch_key ~= "" and text_batch_pending(batch_key) > 0
        local target_wait_max = math.max(1.0, tonumber(CFG.announce_target_wait_max_s) or 8.0)
        local batch = pending_text and text_batches[batch_key] or nil
        local wait_started = tonumber((batch and batch.created) or (bucket and bucket.created)) or now
        local target_wait_expired = bucket
            and (pending_targets > 0 or pending_text)
            and (now - wait_started) >= target_wait_max
        if bucket and (pending_targets > 0 or pending_text) and not target_wait_expired then
            bucket.due = math.max(tonumber(bucket.due) or 0, now + group_window_s())
        elseif not bucket or (tonumber(bucket.due) or 0) <= now then
            if bucket and not target_wait_expired and try_start_confirm_round(bucket, now) then
                -- held: confirm replies (or the confirm wait) will re-due it
            else
                group_announces[key] = nil
                clear_targeted_seen(key)
                if target_wait_expired then
                    bucket.pending_targets = 0
                    if batch then
                        batch.expired = true
                        batch.pending = 0
                    end
                    runtime.target_checks_pending = #targeted_checks
                    note_skip(bucket.item_name, "targeted peer checks timed out")
                    diag.count("announce.target_checks_timed_out")
                end
                send_group_announce(bucket)
            end
        end
    end
    for batch_key, batch in pairs(text_batches) do
        local done = batch and ((tonumber(batch.pending) or 0) <= 0 or batch.expired)
        local at = tonumber((batch and (batch.finished_at or batch.created)) or now) or now
        if done and (now - at) > 30 then
            text_batches[batch_key] = nil
        end
    end
end

note_recent_sent = function(key)
    key = tostring(key or "")
    if key ~= "" then recent[key] = os.clock() end
end

recently_sent = function(key)
    key = tostring(key or "")
    if key == "" then return false end
    local at = recent[key]
    return at and (os.clock() - at) <= (tonumber(CFG.bis_announce_cooldown_s) or 1.8)
end

local function entry_primary_id(entry)
    if type(entry) ~= "table" then return 0 end
    for _, id in ipairs(entry.ids or {}) do
        id = tonumber(id)
        if id and id > 0 then return math.floor(id) end
    end
    return 0
end

note_loot_seen = function(item_name, source)
    runtime.last_loot_at = os.clock()
    runtime.last_loot_item = tostring(item_name or "")
    runtime.last_loot_source = tostring(source or "")
end

note_skip = function(item_name, reason)
    runtime.last_skip_at = os.clock()
    runtime.last_skip_item = tostring(item_name or "")
    runtime.last_skip_reason = tostring(reason or "")
end

local function note_pending(item_name, source, reason)
    runtime.last_pending_at = os.clock()
    runtime.last_pending_item = tostring(item_name or "")
    runtime.last_pending_source = tostring(source or "")
    runtime.last_pending_reason = tostring(reason or "queued")
end

local function note_chat_seen(line, opts)
    runtime.last_chat_at = os.clock()
    runtime.last_chat_sample = tostring(line or ""):gsub("[%c]", " "):sub(1, 160)
    runtime.last_chat_links = 0
    runtime.last_chat_first_item = ""
    opts = type(opts) == "table" and opts or {}
    if opts.self_event then
        runtime.last_chat_note = "self event"
    elseif opts.other_event then
        runtime.last_chat_note = "other event"
    elseif opts.replay then
        runtime.last_chat_note = "replay"
    else
        runtime.last_chat_note = ""
    end
end

local function note_chat_links(links)
    runtime.last_chat_links = type(links) == "table" and #links or 0
    local first = type(links) == "table" and links[1] or nil
    runtime.last_chat_first_item = tostring(first and first.name or "")
end

note_sent = function(item_name)
    runtime.last_sent_at = os.clock()
    runtime.last_sent_item = tostring(item_name or "")
end

local function send_announce_now(item_name, item_link, dedupe)
    if dedupe and dedupe.key and dedupe.respect_recent and recently_sent(dedupe.key) then
        runtime.duplicate_suppressed = (runtime.duplicate_suppressed or 0) + 1
        diag.count("announce.duplicates_suppressed")
        note_skip(item_name, "duplicate collapse " .. tostring(dedupe.source or "?"))
        return false
    end
    if announce_seen_recently(item_name, 0) then
        runtime.duplicate_suppressed = (runtime.duplicate_suppressed or 0) + 1
        diag.count("announce.fleet_duplicates_suppressed")
        note_skip(item_name, "another box already announced")
        return false
    end
    if item_announced_recently(item_name, 0) then
        runtime.duplicate_suppressed = (runtime.duplicate_suppressed or 0) + 1
        diag.count("announce.item_cooldown_suppressed")
        note_skip(item_name, "same item announce cooldown")
        return false
    end
    local cmd = cfg.bis_announce_command()
    item_name = tostring(item_name or "?")
    local payload = item_name
    local link = tostring(item_link or "")
    if item_actions.looks_like_item_link(link) then
        payload = link
    end
    local msg = rules.format_message(payload, me_name())
    if item_actions.looks_like_item_link(payload) then
        mq.cmd(tostring(cmd or "/g") .. " " .. msg)
    else
        mq.cmdf("/squelch %s %s", cmd, msg)
    end
    note_sent(item_name)
    if dedupe and dedupe.key then note_recent_sent(dedupe.key) end
    note_item_announced(item_name, 0)
    return true
end

local function send_need_to_origin(target_name, item_name, item_link, item_id, key)
    target_name = trim(target_name)
    if target_name == "" then return false end
    local ok, sent = pcall(function()
        local Engine = require('engine').Engine
        if Engine and Engine.send_loot_need then
            return Engine.send_loot_need(target_name, {
                item_name = tostring(item_name or ""),
                loot_item_name = tostring(item_name or ""),
                item_link = tostring(item_link or ""),
                item_id = tonumber(item_id) or 0,
                character = me_name(),
                key = tostring(key or ""),
            })
        end
        return false
    end)
    if ok and sent then
        diag.count("announce.need_reports_sent")
        note_sent(item_name)
        return true
    end
    return false
end

local function queue_announce(item_name, item_link, dedupe)
    announce_outbox[#announce_outbox + 1] = {
        item_name = tostring(item_name or "?"),
        item_link = tostring(item_link or ""),
        dedupe = dedupe,
        at = os.clock(),
    }
    while #announce_outbox > outbox_max() do
        table.remove(announce_outbox, 1)
        runtime.outbox_dropped = (runtime.outbox_dropped or 0) + 1
        diag.count("announce.outbox_dropped")
    end
end

local function client_ready_for_chat_send()
    local ok_gs, gs = pcall(function() return mq.TLO.EverQuest.GameState() end)
    if ok_gs and gs and tostring(gs) ~= "" and tostring(gs):upper() ~= "INGAME" then return false end
    local ok_zone, zone = pcall(function() return mq.TLO.Zone.ShortName() end)
    zone = ok_zone and trim(zone) or ""
    local zl = zone:lower()
    if zone == "" or zl == "unknown" or zl == "nil" or zl == "null" then return false end
    local ok_name, name = pcall(function() return mq.TLO.Me.CleanName() end)
    name = ok_name and trim(name) or ""
    if name == "" or name == "?" then return false end
    return true
end

local function drain_announce_outbox()
    if #announce_outbox == 0 then return end
    local now = os.clock()
    if now < next_announce_send_at then return end
    if not client_ready_for_chat_send() then
        next_announce_send_at = now + 1.0
        diag.count("announce.outbox_zoning_hold")
        return
    end
    local entry = table.remove(announce_outbox, 1)
    if not entry then return end
    send_announce_now(entry.item_name, entry.item_link, entry.dedupe)
    local delay_ms = tonumber(CFG.announce_outbox_delay_ms) or MULTI_ANNOUNCE_DELAY_MS
    next_announce_send_at = os.clock() + math.max(0, delay_ms) / 1000
end

local function explain_skip(snap, item_name, item_id, ready)
    if not SharedSettings.bisAnnounceEnabled then
        return "linked needs disabled"
    end
    if not ready then
        return "catalog warming"
    end
    item_name = tostring(item_name or "")
    item_id = tonumber(item_id) or 0
    if item_name == "" then
        return "empty item name"
    end
    local bis = require('bis')
    local probe = { item = item_name, names = { item_name }, ids = item_id > 0 and { item_id } or {} }
    if bis.live_own_item(probe, item_name, item_id) then
        return "already owned"
    end
    return "not missing on announce-enabled BiS lists"
end

local function announce_from_need(need, source, item_link, item_id, snap, ready, loot_item_name, opts)
    if not need then
        return false
    end
    opts = type(opts) == "table" and opts or {}
    local display_name = need.item_name or "?"
    local dedupe_id = entry_primary_id(need.entry)
    if dedupe_id <= 0 then dedupe_id = tonumber(item_id) or 0 end
    local key = dedupe_key(
        tostring(loot_item_name or "") ~= "" and tostring(loot_item_name) or display_name,
        need.list and need.list.id,
        dedupe_id
    )
    local direct_chat = source == "chat" or source == "line"
    local respect_recent = not direct_chat
    if respect_recent and recently_sent(key) then
        runtime.duplicate_suppressed = (runtime.duplicate_suppressed or 0) + 1
        diag.count("announce.duplicates_suppressed")
        note_skip(display_name, "duplicate collapse " .. tostring(source or "?"))
        dprint("skip: cooldown active for %s", display_name)
        return false
    end
    dprint("MATCH %s via %s", display_name, tostring(source))
    local resolved = item_actions.resolve_announce_link(
        tostring(loot_item_name or "") ~= "" and tostring(loot_item_name) or display_name,
        item_link,
        dedupe_id
    )
    if resolved == "" and tostring(loot_item_name or "") ~= "" and tostring(loot_item_name) ~= display_name then
        resolved = item_actions.resolve_announce_link(display_name, nil, entry_primary_id(need.entry))
    end
    if resolved == "" then
        dprint("no link resolved for %s; announcing name only", display_name)
    end
    local dedupe = { key = key, source = source, respect_recent = respect_recent }
    if opts.reply_to then
        send_need_to_origin(opts.reply_to, display_name, resolved, dedupe_id > 0 and dedupe_id or item_id, key)
    elseif opts.group_local then
        add_group_need(display_name, resolved, dedupe_id > 0 and dedupe_id or item_id, me_name(), source)
    elseif direct_chat then
        send_announce_now(display_name, resolved, dedupe)
    else
        queue_announce(display_name, resolved, dedupe)
    end
    return true
end

snap_for_announce = function()
    local lean = state.lean and state.lean()
    local max_age = lean and (tonumber(CFG.announce_snap_max_age_lean_s) or 60.0)
        or (tonumber(CFG.announce_snap_max_age_s) or 4.0)
    local age = gather_self_snapshot.lite_age()
    if age and age <= max_age then
        local cached = gather_self_snapshot.cached()
        if cached then return cached end
    end
    return gather_self_snapshot.cached()
        or gather_self_snapshot.gather({ force = false, depth = "lite" })
end

local function catalog_ready_for(snap)
    return snap and snap.class and catalog.announce_catalog_ready(snap.class, snap.name)
end

local function ensure_catalog_for_chat(snap, flush)
    if not snap or not snap.class then return false end
    if catalog_ready_for(snap) then
        announce_ready = true
        return true
    end
    if flush then
        local ready = catalog.flush_announce_catalog(
            snap.class, snap.name, tonumber(CFG.announce_flush_budget_ms) or 800)
        announce_ready = ready
        return ready
    end
    catalog.ensure_announce_catalog(snap.class, { owner = snap.name })
    announce_ready = catalog_ready_for(snap)
    if not announce_ready then
        dprint("defer: catalog still building")
    end
    return announce_ready
end

local function queue_pending_line(line, reason)
    line = tostring(line or "")
    if line == "" then return end
    pending[#pending + 1] = { line = line, at = os.clock() }
    note_pending("chat line", "chat", reason or "catalog warming")
    while #pending > pending_max() do
        table.remove(pending, 1)
        runtime.pending_dropped = (runtime.pending_dropped or 0) + 1
        diag.count("announce.pending_dropped")
    end
    dprint("queued pending chat (%d)", #pending)
end

local function queue_pending_items(items, source, reason, reply_to)
    if type(items) ~= "table" or #items == 0 then return end
    for _, item in ipairs(items) do
        pending_items[#pending_items + 1] = {
            items = { item },
            source = source,
            reason = reason or "catalog warming",
            reply_to = reply_to,
            at = os.clock(),
        }
        note_pending(item and item.name or "item link", source, reason or "catalog warming")
    end
    while #pending_items > pending_max() do
        table.remove(pending_items, 1)
        runtime.pending_dropped = (runtime.pending_dropped or 0) + 1
        diag.count("announce.pending_dropped")
    end
end

local function try_process_direct_chat_links_while_warming(links, snap, allow_queue, source, opts)
    source = tostring(source or "chat")
    opts = type(opts) == "table" and opts or {}
    for _, item in ipairs(links) do
        note_loot_seen(item.name, source)
        if opts.group_local then
            ensure_group_announce(item.name, item.link, item.id, source, item.corpse_id)
        end
    end
    if allow_queue then
        queue_pending_items(links, source, "index/catalog warming", opts.reply_to)
    else
        diag.count("announce.direct_links_deferred")
    end
    return false
end

local function try_process_direct_chat_text_while_warming(line, snap, allow_queue, source)
    source = tostring(source or "line")
    if allow_queue then
        queue_pending_line(line, "index/catalog warming")
    else
        diag.count("announce.direct_text_deferred")
    end
    return false
end

local function try_process_item_links(links, source, allow_queue, line, opts)
    if not SharedSettings.bisAnnounceEnabled then return false end
    if type(links) ~= "table" or #links == 0 then return false end
    opts = type(opts) == "table" and opts or {}

    if opts.group_local then
        local added = scan_group_needs_from_cache(links, source)
        return added > 0
    end

    local snap = snap_for_announce()
    if not snap then return false end
    local ready = ensure_catalog_for_chat(snap, false)
    if not ready then
        if source == "chat" or source == "replay" then
            return try_process_direct_chat_links_while_warming(links, snap, allow_queue, source, opts)
        end
        if allow_queue then queue_pending_items(links, source, nil, opts.reply_to) end
        return false
    end

    local announced = 0
    for _, item in ipairs(links) do
        note_loot_seen(item.name, source)
        if opts.group_local then
            ensure_group_announce(item.name, item.link, item.id, source, item.corpse_id)
        end
        local need = catalog.check_announce_need(snap, item.name, item.id)
        if announce_from_need(need, source, item.link, item.id, snap, ready, item.name, opts) then
            announced = announced + 1
        else
            note_skip(item.name, explain_skip(snap, item.name, item.id, ready))
        end
    end
    return announced > 0
end

local function try_process_chat(line, allow_queue, opts)
    if not SharedSettings.bisAnnounceEnabled then return false end
    opts = type(opts) == "table" and opts or {}
    line = tostring(line or "")
    note_chat_seen(line, opts)
    -- Record [TG] lines for fleet-wide dedupe BEFORE the skip filter eats them.
    if line:find("%[TG%]", 1, false) then
        pcall(note_announce_seen, line)
    end
    if should_skip_line(line) then
        runtime.last_chat_note = "skip filter"
        return false
    end
    dprint("chat: %s", line:sub(1, 120))
    local ui_coordinator = state.bg ~= true

    local links = parse_item_links(line)
    note_chat_links(links)
    if #links > 0 and not opts.replay and is_player_link_chat_line(line) then
        remember_recent_replay(line, links, "chat")
    end
    -- Driver-first: while a driver UI is announce-active (fresh beacon), bg
    -- responders stay quiet for chat-triggered needs - the driver's cache scan
    -- covers every character. Link capture, replay memory, and [TG] dedupe
    -- recording above still ran, so nothing else degrades.
    if state.bg == true and coordinator_active() then
        runtime.last_chat_note = "driver coordinator"
        return false
    end
    if #links > 0 then
        local self_line = opts.self_event == true or is_self_loot_line(line)
        local group_local = self_line or ui_coordinator
        if not group_local and not opts.replay and SharedSettings.announceUseActor ~= false then
            runtime.last_chat_note = "actor expected"
            return false
        end
        return try_process_item_links(links, opts.replay and "replay" or "chat", allow_queue, line, {
            group_local = group_local,
        })
    end

    if not opts.replay and SharedSettings.announceUseActor ~= false
        and not ui_coordinator
        and (opts.other_event == true or is_other_player_chat_line(line)) then
        return false
    end

    local snap = snap_for_announce()
    if not snap then return false end
    local group_local = opts.self_event == true or is_self_loot_line(line)
        or (ui_coordinator and is_player_link_chat_line(line))
    if group_local then
        if is_player_link_chat_line(line) and has_unparseable_item_link_payload(line) then
            local queued = queue_group_text_target_checks(line, opts.replay and "replay" or "text-targeted")
            if queued > 0 then
                runtime.last_chat_note = "linked text fallback"
                return true
            end
        end
        local added = scan_group_text_needs_from_cache(line, opts.replay and "replay" or "line")
        return added > 0
    end
    if not ensure_catalog_for_chat(snap, false) then
        return try_process_direct_chat_text_while_warming(line, snap, allow_queue, opts.replay and "replay" or "line")
    end

    local announced = 0
    for _, hit in ipairs(catalog.find_announce_needs_in_line(snap, line)) do
        local source = opts.replay and "replay" or "line"
        note_loot_seen(hit.item_name or "?", source)
        if announce_from_need(hit.need, source, hit.link, hit.item_id, snap, true, hit.item_name, {
            group_local = group_local,
        }) then
            announced = announced + 1
        else
            note_skip(hit.item_name or "?", explain_skip(snap, hit.item_name, 0, true))
        end
    end
    return announced > 0
end

local function on_chat(line)
    if passive then return end
    diag.time("announce.chat", function()
        try_process_chat(line, true)
    end)
end

local function on_chat_self(line)
    if passive then return end
    diag.time("announce.chat", function()
        try_process_chat(line, true, { self_event = true })
    end)
end

local function on_chat_other(line)
    if passive then return end
    diag.time("announce.chat", function()
        try_process_chat(line, true, { other_event = true })
    end)
end

local function drain_pending(budget_ms, max_entries)
    -- Nothing queued: skip entirely (the snapshot + catalog-signature checks
    -- below are not free, and this runs every tick).
    if #pending == 0 and #pending_items == 0 then return end
    if not SharedSettings.bisAnnounceEnabled then return end
    local snap = gather_self_snapshot.cached() or snap_for_announce()
    if not snap or not catalog_ready_for(snap) then return end

    local now = os.clock()
    local deadline = now + (math.max(1, tonumber(budget_ms) or 4) / 1000)
    max_entries = math.max(1, math.floor(tonumber(max_entries) or 1))
    local processed = 0
    local i = 1
    while i <= #pending and processed < max_entries and os.clock() < deadline do
        local entry = pending[i]
        if not entry or (now - entry.at) > PENDING_TTL_S then
            table.remove(pending, i)
        else
            try_process_chat(entry.line, false)
            table.remove(pending, i)
            processed = processed + 1
        end
    end

    i = 1
    while i <= #pending_items and processed < max_entries and os.clock() < deadline do
        local entry = pending_items[i]
        if not entry or (now - entry.at) > PENDING_TTL_S then
            table.remove(pending_items, i)
        else
            try_process_item_links(entry.items, entry.source or "actor", false, nil, {
                reply_to = entry.reply_to,
            })
            table.remove(pending_items, i)
            processed = processed + 1
        end
    end
end

M._parse_item_links_for_test = parse_item_links
M._has_unparseable_item_link_payload_for_test = has_unparseable_item_link_payload

-- Driver boxes run UI (announce-active) + bg (announce-passive). Actors land
-- on the bg mailbox only; without a local relay, corpse-aware LOOT_LINK never
-- reaches the Linked items panel that draws Go buttons.
local function forward_loot_to_local_ui(item_name, item_id, corpse_id)
    if state.bg ~= true then return end
    item_name = trim(item_name)
    if item_name == "" then return end
    mq.cmd(string.format('/squelch /tgear lootseenquiet "%s" %d %d',
        item_name:gsub('"', ""),
        math.floor(tonumber(item_id) or 0),
        math.floor(tonumber(corpse_id) or 0)))
end

function M.on_loot_link(msg)
    if type(msg) ~= "table" or type(msg.items) ~= "table" or #msg.items == 0 then return end
    local from = tostring(msg.from or "")
    if from ~= "" and from:lower() == me_name():lower() then return end

    if passive then
        for _, it in ipairs(msg.items) do
            forward_loot_to_local_ui(it.name, it.id, it.corpse_id)
        end
        return
    end
    if not SharedSettings.bisAnnounceEnabled then return end

    refresh_settings_if_due()
    local links = {}
    for _, it in ipairs(msg.items) do
        local name = tostring(it.name or "")
        if name ~= "" then
            local cid = tonumber(it.corpse_id)
            links[#links + 1] = {
                name = name,
                id = tonumber(it.id) or 0,
                link = tostring(it.link or ""),
                corpse_id = (cid and cid > 0) and math.floor(cid) or nil,
            }
            pcall(function() item_actions.remember_item_link(name, it.id, it.link) end)
        end
    end
    if #links == 0 then return end
    remember_recent_replay("", links, "actor")
    -- Actor loot links from a looter are fleet-visible drops: run the same
    -- grouped needs scan the chat driver uses (including corpse hints).
    diag.time("announce.actor", function()
        try_process_item_links(links, "actor", true, nil, {
            reply_to = from,
            group_local = true,
        })
    end)
end

function M.on_loot_seen(item_name, item_id, item_link, source, corpse_id)
    item_name = trim(item_name or "")
    item_id = tonumber(item_id) or 0
    item_link = tostring(item_link or "")
    corpse_id = tonumber(corpse_id) or 0
    if item_name == "" then return false end
    if passive then
        forward_loot_to_local_ui(item_name, item_id, corpse_id)
        return false
    end
    if not SharedSettings.bisAnnounceEnabled then return false end
    refresh_settings_if_due()

    local links = {{
        name = item_name,
        id = item_id,
        link = item_link,
        corpse_id = corpse_id > 0 and math.floor(corpse_id) or nil,
    }}
    if item_link ~= "" then
        pcall(function() item_actions.remember_item_link(item_name, item_id, item_link) end)
    end
    remember_recent_replay("", links, tostring(source or "structured"))
    diag.time("announce.structured_loot", function()
        try_process_item_links(links, tostring(source or "structured"), true, nil, {
            group_local = true,
        })
    end)
    -- Tell peer drivers about the corpse-left item even when this box is not
    -- the announce UI - Go-loot buttons live on the driver panel.
    pcall(function()
        local Engine = require('engine').Engine
        if Engine and Engine.ok and Engine.broadcast_loot_links then
            Engine.broadcast_loot_links(links, me_name())
        end
    end)
    return true
end

function M.on_loot_need(msg)
    if passive then return end
    if not SharedSettings.bisAnnounceEnabled then return end
    if type(msg) ~= "table" then return end
    local from = trim(msg.from or msg.character or "")
    if from == "" or from:lower() == me_name():lower() then return end
    local item_name = trim(msg.item_name or msg.loot_item_name or "")
    if item_name == "" then return end
    local item_link = tostring(msg.item_link or "")
    local item_id = tonumber(msg.item_id) or 0
    add_group_need(item_name, item_link, item_id, from, "actor-reply")
    diag.count("announce.need_reports_received")
end

-- Peer side of the confirm round: another box is about to announce US as a
-- needer based on its cached copy of our inventory; answer with a LIVE
-- ownership check so a just-looted item never gets announced as needed.
-- Deliberately not gated on announce/passive state - this is an inventory
-- question, not an announce.
function M.on_need_confirm(msg)
    if type(msg) ~= "table" then return end
    local from = trim(msg.from or "")
    if from == "" or from:lower() == me_name():lower() then return end
    local item_name = trim(msg.item_name or "")
    local item_id = tonumber(msg.item_id) or 0
    if item_name == "" and item_id <= 0 then return end
    local owned = false
    pcall(function()
        local bis = require('bis')
        owned = bis.live_own_item(nil, item_name, item_id) == true
    end)
    pcall(function()
        local Engine = require('engine').Engine
        if Engine and Engine.send_need_confirm_reply then
            Engine.send_need_confirm_reply(from, {
                item_name = item_name,
                item_id = item_id,
                bucket_key = msg.bucket_key,
                owned = owned,
            })
        end
    end)
    diag.count("announce.confirms_answered")
end

-- Driver side: a peer answered the confirm round. Owned peers are dropped
-- from the held bucket, and their box is asked for a fresh snapshot so the
-- needs index rebuilds and future announces are right without a confirm.

function M.on_need_confirm_reply(msg)
    if type(msg) ~= "table" then return end
    local from = trim(msg.from or "")
    if from == "" or from:lower() == me_name():lower() then return end
    local bucket = group_announces[tostring(msg.bucket_key or "")]
    if bucket then
        bucket.pending_confirms = math.max(0, (tonumber(bucket.pending_confirms) or 0) - 1)
        if msg.owned == true and rules.remove_needer(bucket.names, bucket.order, from) then
            if type(bucket.sources) == "table" then bucket.sources[from:lower()] = nil end
            runtime.confirm_owned = (runtime.confirm_owned or 0) + 1
            diag.count("announce.confirm_owned")
            note_skip(bucket.item_name, #bucket.order == 0
                and "all needers already own it (live confirm)"
                or string.format("%s already owns it (live confirm)", from))
        end
        if bucket.pending_confirms <= 0 then
            -- All replies in: flush on the next drain instead of waiting out
            -- the full confirm window.
            bucket.due = math.min(tonumber(bucket.due) or 0, os.clock())
        end
    end
    if msg.owned == true then
        local server = trim(msg.server or "")
        if server == "" then server = tostring(mq.TLO.MacroQuest.Server() or "?") end
        local char_key = server .. "_" .. from
        local now = os.clock()
        local cooldown = math.max(5, tonumber(CFG.announce_confirm_refresh_cooldown_s) or 30)
        if (now - (tonumber(confirm_refresh_at[char_key]) or 0)) >= cooldown then
            confirm_refresh_at[char_key] = now
            pcall(function()
                local Engine = require('engine').Engine
                if Engine and Engine.request_source then
                    Engine.request_source(char_key, true, { fastInventory = true })
                end
            end)
        end
    end
end

local function replay_payload()
    local now = os.clock()
    prune_recent_replay(now)
    local out = {}
    for _, entry in ipairs(recent_replay or {}) do
        out[#out + 1] = {
            age = now - (tonumber(entry.at) or now),
            line = tostring(entry.line or ""),
            items = copy_items(entry.items),
        }
    end
    return out
end

local function request_recent_replay(reason)
    local now = os.clock()
    if (now - (tonumber(runtime.replay_requested_at) or 0)) < 5.0 then return end
    runtime.replay_requested_at = now
    local ok = pcall(function()
        local Engine = require('engine').Engine
        if Engine and Engine.request_loot_replay then
            Engine.request_loot_replay()
        end
    end)
    if ok then dprint("requested recent loot replay: %s", tostring(reason or "")) end
end

local function note_startup_progress(ready, reason)
    if SharedSettings.bisAnnounceEnabled == false then return end
    if ready then
        if not runtime.ready_notice_printed and not state.bg then
            runtime.ready_notice_printed = true
            print("\at[TurboGear]\ax \aglinked-needs listener ready.\ax")
        end
        if not runtime.replay_ready_requested then
            runtime.replay_ready_requested = true
            request_recent_replay(reason or "ready")
        end
        return
    end
    if not runtime.startup_notice_printed and not state.bg then
        runtime.startup_notice_printed = true
        print("\at[TurboGear]\ax \aylinked-needs listener warming\ax - \awrecent links will replay when ready.\ax")
    end
end

function M.on_replay_request(msg)
    if passive then return end
    if not SharedSettings.bisAnnounceEnabled then return end
    local from = tostring(msg and msg.from or "")
    if from == "" or from:lower() == me_name():lower() then return end
    local entries = replay_payload()
    if #entries == 0 then return end
    runtime.replay_sent = (runtime.replay_sent or 0) + #entries
    pcall(function()
        local Engine = require('engine').Engine
        if Engine and Engine.send_loot_replay then
            Engine.send_loot_replay(from, entries)
        end
    end)
end

function M.on_loot_replay(msg)
    if passive then return end
    if not SharedSettings.bisAnnounceEnabled then return end
    local entries = msg and msg.entries
    if type(entries) ~= "table" or #entries == 0 then return end
    runtime.replay_received = (runtime.replay_received or 0) + #entries
    local checked = 0
    diag.time("announce.replay", function()
        local now = os.clock()
        prune_replay_received_seen(now)
        for _, entry in ipairs(entries) do
            local line = tostring(entry and entry.line or "")
            local items = copy_items(entry and entry.items)
            local sig = replay_entry_sig(line, items)
            if sig ~= "" and replay_received_seen[sig] and (now - replay_received_seen[sig]) <= replay_ttl_s() then
                diag.count("announce.replay_duplicates_suppressed")
            else
                if sig ~= "" then replay_received_seen[sig] = now end
                if line ~= "" then
                    try_process_chat(line, true, { suppress_actor_broadcast = true, replay = true })
                    checked = checked + 1
                elseif #items > 0 then
                    try_process_item_links(items, "replay", true)
                    checked = checked + #items
                end
            end
        end
    end)
    if checked > 0 then
        runtime.replay_checked = (runtime.replay_checked or 0) + checked
    end
end

function M.invalidate(reason)
    diag.event("announce.invalidate", tostring(reason or "manual"))
    announce_ready = false
    needs_index_warm = true
    pending = {}
    pending_items = {}
    announce_outbox = {}
    group_announces = {}
    next_announce_send_at = 0
    pcall(function() needs_index.invalidate(reason or "announce.invalidate") end)
end

function M.warm(flush)
    if passive then
        announce_ready = false
        return false
    end
    refresh_settings_if_due()
    if not SharedSettings.bisAnnounceEnabled then
        announce_ready = false
        return false
    end
    local snap = gather_self_snapshot.cached()
        or gather_self_snapshot.gather({ force = true, depth = "lite" })
    if not snap or not snap.class or snap.class == "?" then
        announce_ready = false
        return false
    end
    if flush then
        -- Sync build: time-limited flush often leaves bg bots ready=false (15+ BiS lists).
        catalog.ensure_announce_catalog(snap.class, { owner = snap.name, sync = true })
        announce_ready = catalog_ready_for(snap)
        needs_index_warm = not announce_ready
        note_startup_progress(announce_ready, announce_ready and "warm_ready" or "warm_startup")
        return announce_ready
    end
    catalog.ensure_announce_catalog(snap.class, { owner = snap.name })
    announce_ready = catalog_ready_for(snap)
    needs_index_warm = not announce_ready
    note_startup_progress(announce_ready, announce_ready and "warm_ready" or "warm_startup")
    return announce_ready
end

function M.count_announcing_lists()
    local n, total = 0, 0
    for _, spec in ipairs(catalog.announce_list_specs() or {}) do
        total = total + 1
        if catalog.list_announce_enabled(spec.id) then
            n = n + 1
        end
    end
    return n, total
end

function M.status()
    refresh_settings_if_due()
    local snap = gather_self_snapshot.cached()
    local lists_on, lists_total = M.count_announcing_lists()
    local build = catalog.catalog_build_state and catalog.catalog_build_state() or {}
    local pending_actor, pending_item_chat = 0, 0
    for _, entry in ipairs(pending_items or {}) do
        if entry and entry.source == "actor" then pending_actor = pending_actor + 1
        else pending_item_chat = pending_item_chat + 1 end
    end
    local now = os.clock()
    local function age_str(at)
        at = tonumber(at) or 0
        if at <= 0 then return "never" end
        local s = math.floor(now - at)
        if s < 1 then return "just now" end
        if s < 60 then return string.format("%ds ago", s) end
        return string.format("%dm ago", math.floor(s / 60))
    end
    local ready = announce_ready and catalog_ready_for(snap)
    local index_label = passive and "passive viewer" or (ready and "ready" or (build.building and "building" or "warming"))
    if passive then
        index_label = "passive viewer"
    elseif build.building and (build.entries or 0) > 0 then
        index_label = string.format("building (%d items)", build.entries or 0)
    elseif ready and (build.entries or 0) > 0 then
        index_label = string.format("ready (%d items)", build.entries or 0)
    end
    local pending_group = 0
    for _, _ in pairs(group_announces or {}) do pending_group = pending_group + 1 end
    local roster_status = active_announce_roster_status(12)
    return {
        enabled = SharedSettings.bisAnnounceEnabled ~= false,
        actor = SharedSettings.announceUseActor ~= false,
        ready = ready,
        index_label = index_label,
        passive = passive,
        registered = M.registered,
        pending = #pending + #pending_items + #announce_outbox + pending_group + #targeted_checks,
        pending_chat = #pending + pending_item_chat,
        pending_actor = pending_actor,
        pending_outbox = #announce_outbox,
        pending_group = pending_group,
        channel = cfg.bis_announce_command(),
        lists_on = lists_on,
        lists_total = lists_total,
        catalog_entries = build.entries or 0,
        catalog_building = build.building == true,
        announce_scope = roster_status.scope,
        announce_view = roster_status.view,
        announce_roster_count = roster_status.count,
        announce_roster_names = roster_status.names,
        announce_roster_truncated = roster_status.truncated,
        last_loot_item = runtime.last_loot_item,
        last_loot_source = runtime.last_loot_source,
        last_loot_age = age_str(runtime.last_loot_at),
        last_sent_item = runtime.last_sent_item,
        last_sent_age = age_str(runtime.last_sent_at),
        last_skip_item = runtime.last_skip_item,
        last_skip_reason = runtime.last_skip_reason,
        last_skip_age = age_str(runtime.last_skip_at),
        last_pending_item = runtime.last_pending_item,
        last_pending_source = runtime.last_pending_source,
        last_pending_reason = runtime.last_pending_reason,
        last_pending_age = age_str(runtime.last_pending_at),
        last_group_scan_source = runtime.last_group_scan_source,
        last_group_scan_mode = runtime.last_group_scan_mode,
        last_group_scan_items = runtime.last_group_scan_items or 0,
        last_group_scan_snaps = runtime.last_group_scan_snaps or 0,
        last_group_scan_added = runtime.last_group_scan_added or 0,
        last_group_scan_pending = runtime.last_group_scan_pending or 0,
        last_group_scan_age = age_str(runtime.last_group_scan_at),
        last_chat_sample = runtime.last_chat_sample or "",
        last_chat_links = runtime.last_chat_links or 0,
        last_chat_first_item = runtime.last_chat_first_item or "",
        last_chat_note = runtime.last_chat_note or "",
        last_chat_age = age_str(runtime.last_chat_at),
        duplicate_suppressed = runtime.duplicate_suppressed or 0,
        pending_dropped = runtime.pending_dropped or 0,
        outbox_dropped = runtime.outbox_dropped or 0,
        target_checks_pending = #targeted_checks,
        target_checks_completed = runtime.target_checks_completed or 0,
        replay_checked = runtime.replay_checked or 0,
        replay_received = runtime.replay_received or 0,
        replay_sent = runtime.replay_sent or 0,
        needs_index = (function()
            if CFG.needs_index_enabled == false then
                return {
                    disabled = true,
                    ready = true,
                    chars = 0,
                    items = 0,
                    queued = 0,
                    rebuilds = 0,
                    attempts = 0,
                    failures = 0,
                    tombstoned = 0,
                    builds_started = 0,
                    builds_finished = 0,
                    eval_entries = 0,
                    max_single_entry_ms = 0,
                    oldest_queue_age_s = 0,
                }
            end
            local ok, st = pcall(function() return needs_index.status() end)
            if ok and type(st) == "table" then return st end
            return { ready = false, chars = 0, items = 0, queued = 0, rebuilds = 0, age_s = -1 }
        end)(),
        coordinator = (function()
            if state.bg ~= true then
                return SharedSettings.bisAnnounceEnabled ~= false and not passive and "driver" or "off"
            end
            return coordinator_active() and "deferring to driver" or "announcing (no driver beacon)"
        end)(),
        link_capture = (function()
            local seen = 0
            for _ in pairs(announce_seen) do seen = seen + 1 end
            local has_extract = mq.ExtractLinks ~= nil and mq.ParseItemLink ~= nil
                and mq.LinkTypes ~= nil and mq.LinkTypes.Item ~= nil
            local has_linkdb = false
            pcall(function() has_linkdb = mq.TLO.LinkDB ~= nil end)
            return {
                chat_links = has_extract,
                linkdb = has_linkdb,
                cached = item_actions.observed_link_count and item_actions.observed_link_count() or 0,
                seen = seen,
            }
        end)(),
    }
end

function M.tick()
    return diag.time("announce.tick", function()
        if passive then
            diag.count("announce.tick.passive")
            return
        end
        tick_coordinator_beacon()
        local settings_reloaded = refresh_settings_if_due()
        if not SharedSettings.bisAnnounceEnabled then
            announce_ready = false
            pending = {}
            pending_items = {}
            announce_outbox = {}
            diag.count("announce.tick.disabled")
            return
        end
        local work_pending = announce_work_pending()
        local allow_peer_index = peer_index_allowed()
        local index_enabled = CFG.needs_index_enabled ~= false
        local index_needed = index_enabled and needs_index.needs_tick({ allow_peers = allow_peer_index }) or false
        if announce_ready and not settings_reloaded and not needs_index_warm
            and not work_pending and not index_needed then
            diag.count("announce.tick.early_out")
            return
        end
        diag.count("announce.tick.full_body")
        if settings_reloaded then diag.count("announce.tick.full_reason.settings") end
        if needs_index_warm then diag.count("announce.tick.full_reason.warm") end
        if work_pending then diag.count("announce.tick.full_reason.pending") end
        if index_needed then diag.count("announce.tick.full_reason.index") end
        if not announce_ready then diag.count("announce.tick.full_reason.not_ready") end
        local snap = gather_self_snapshot.cached()
        if not snap then
            snap = diag.time("announce.snapshot_lite", function()
                return gather_self_snapshot.gather({ force = false, depth = "lite" })
            end)
        end
        if not snap or not snap.class then
            announce_ready = false
            return
        end
        local was_ready = announce_ready and catalog_ready_for(snap)

        if needs_index_warm then
            needs_index_warm = false
            catalog.ensure_announce_catalog(snap.class, { owner = snap.name })
        end

        -- Single per-frame work budget (P5): the background build steps below
        -- (catalog warm + needs-index) draw down from ONE deadline so their
        -- individually-small budgets can't sum into a visible frame spike. The
        -- time-sensitive announce drains further down are NOT gated by this.
        local frame_budget_ms
        local oldest_queue_s = 0
        if index_enabled then
            local ok_age, age = pcall(function() return needs_index.oldest_queue_age_s() end)
            if ok_age then oldest_queue_s = tonumber(age) or 0 end
        end
        local stale_s = tonumber(CFG.needs_index_stale_queue_s) or 60
        local index_stale = oldest_queue_s >= stale_s
        if state.bg then
            frame_budget_ms = tonumber(CFG.frame_work_budget_bg_ms) or 40
        elseif index_stale then
            -- Announce driver is lean/minimized but the needs queue is aging:
            -- temporarily spend like a light bg tick so warm-up finishes.
            frame_budget_ms = tonumber(CFG.frame_work_budget_stale_ms)
                or tonumber(CFG.frame_work_budget_ms) or 30
        elseif state.lean and state.lean() then
            frame_budget_ms = tonumber(CFG.frame_work_budget_lean_ms) or 6
        else
            frame_budget_ms = tonumber(CFG.frame_work_budget_ms) or 10
        end
        local frame_deadline = os.clock() + (frame_budget_ms / 1000)

        if not catalog_ready_for(snap) then
            local budget, max_steps
            if state.bg and not announce_ready then
                budget = tonumber(CFG.announce_catalog_budget_bg_ms) or 40
                max_steps = tonumber(CFG.announce_catalog_steps_bg) or 8
            elseif state.lean and state.lean() then
                budget = tonumber(CFG.announce_catalog_budget_lean_ms) or 5
                max_steps = tonumber(CFG.announce_catalog_steps_lean) or 1
            else
                budget = tonumber(CFG.announce_catalog_budget_ms) or 45
                max_steps = tonumber(CFG.announce_catalog_steps_ui) or 1
            end
            diag.time("announce.catalog_tick", function()
                catalog.tick_announce_catalog(budget, max_steps)
            end)
        end
        announce_ready = catalog_ready_for(snap)
        if announce_ready and not was_ready then
            note_startup_progress(true, "ready")
        end
        -- Decoupled from announce_ready: the index does not depend on the
        -- static catalog, and gating on it starved index warm-up whenever the
        -- static build was slow (Rydell 17:05: 76 index ticks in 626 loops).
        if index_enabled and index_needed then
            local idx_budget
            if state.bg then
                idx_budget = tonumber(CFG.needs_index_budget_bg_ms) or 25
            elseif index_stale then
                idx_budget = tonumber(CFG.needs_index_budget_stale_ms) or 20
            elseif state.lean and state.lean() then
                idx_budget = tonumber(CFG.needs_index_budget_lean_ms) or tonumber(CFG.needs_index_budget_ms) or 4
            else
                idx_budget = tonumber(CFG.needs_index_budget_ms) or 4
            end
            -- Draw down from the shared frame budget: subtract whatever the
            -- catalog warm already spent, and skip this frame if the budget is
            -- exhausted (the index build is resumable next tick).
            local remaining_ms = (frame_deadline - os.clock()) * 1000
            if remaining_ms < idx_budget then idx_budget = remaining_ms end
            if idx_budget >= 1 then
                needs_index.tick(idx_budget, { allow_peers = allow_peer_index })
            end
        end
        diag.time("announce.pending", function()
            drain_pending(CFG.announce_pending_budget_ms, CFG.announce_pending_items_per_tick)
        end)
        diag.time("announce.outbox", function()
            diag.time("announce.targeted_checks", function()
                drain_targeted_checks()
            end)
            diag.time("announce.group_announces", function()
                drain_group_announces()
            end)
            diag.time("announce.outbox_send", function()
                drain_announce_outbox()
            end)
        end)
    end)
end

function M.loop_delay_ms()
    if state.lean and state.lean() then
        if announce_ready and not announce_work_pending() then return 250 end
        return tonumber(CFG.announce_loop_delay_lean_ms) or 50
    end
    if not SharedSettings.bisAnnounceEnabled then
        return state.show and 50 or 150
    end
    if announce_ready and not announce_work_pending() then
        return state.show and 75 or 150
    end
    return state.show and 25 or 50
end

local function diagnose_one(snap, ready, idx, item_name, item_id)
    item_name = tostring(item_name or "")
    item_id = tonumber(item_id) or 0
    if item_name == "" then return false end
    local t0 = os.clock()
    local need = ready and catalog.check_announce_need(snap, item_name, item_id) or nil
    local lookup_ms = (os.clock() - t0) * 1000
    print(string.format("[TurboGear] %s | lookup %.1fms", item_name, lookup_ms))
    if need then
        print(string.format("[TurboGear]   WOULD announce: [TG] - %s - %s",
            need.item_name or item_name, me_name()))
        return true
    end
    local reason = explain_skip(snap, item_name, item_id, ready)
    print(string.format("[TurboGear]   would NOT announce: %s", reason))
    return false
end

function M.diagnose(item_name, item_id)
    refresh_settings_if_due()
    item_name = tostring(item_name or "")
    if item_name == "" then
        return false, "Usage: /tgear announcetest \"Item Name\" [itemId] | announcetest burst \"A\" \"B\""
    end
    local mode = state.bg and "bg" or "ui"
    local snap = snap_for_announce()
    print(string.format("[TurboGear] announcetest on %s | mode=%s | ready=%s | channel=%s",
        me_name(), mode, tostring(announce_ready), cfg.bis_announce_command()))
    do
        local has_extract = mq.ExtractLinks ~= nil and mq.ParseItemLink ~= nil
            and mq.LinkTypes ~= nil and mq.LinkTypes.Item ~= nil
        local has_linkdb = false
        pcall(function() has_linkdb = mq.TLO.LinkDB ~= nil end)
        print(string.format("[TurboGear] link capture: chatLinks=%s | linkdb=%s | cachedLinks=%d",
            has_extract and "yes" or "NO - this MQ build cannot read links from chat; announces fall back to names",
            has_linkdb and "yes" or "no",
            item_actions.observed_link_count and item_actions.observed_link_count() or 0))
    end
    local ready, idx = false, nil
    if snap and snap.class then
        ready, idx = catalog.flush_announce_catalog(snap.class, snap.name, 2000)
        announce_ready = ready
    end
    if not ready then
        print("[TurboGear] catalog index still building (wait a few seconds and retry)")
    end
    print(string.format("[TurboGear] catalog index: %d lists, %d tracked items",
        idx and idx.list_count or 0, idx and idx.catalog_entries or 0))

    item_id = tonumber(item_id) or 0
    return diagnose_one(snap, ready, idx, item_name, item_id)
end

function M.diagnose_group(item_name, item_id)
    refresh_settings_if_due()
    item_name = tostring(item_name or "")
    item_id = tonumber(item_id) or 0
    if item_name == "" then
        return false, "Usage: /tgear announcetest group \"Item Name\" [itemId]"
    end

    local mode = state.bg and "bg" or "ui"
    local allow_peers = peer_index_allowed()
    local roster_status = active_announce_roster_status(24)
    print(string.format("[TurboGear] group announcetest on %s | mode=%s | enabled=%s | channel=%s",
        me_name(), mode, tostring(SharedSettings.bisAnnounceEnabled ~= false), cfg.bis_announce_command()))
    print(string.format("[TurboGear] announce roster: scope=%s | viewing=%s | chars=%d%s%s",
        tostring(roster_status.scope or "?"),
        tostring(roster_status.view or "?"),
        tonumber(roster_status.count) or 0,
        tostring(roster_status.names or "") ~= "" and (" | " .. tostring(roster_status.names or "")) or "",
        roster_status.truncated and ", ..." or ""))
    if CFG.needs_index_enabled == false then
        print("[TurboGear] needs index is disabled; real linked announces will use bounded direct checks instead")
        return false
    end
    if not allow_peers then
        print("[TurboGear] peer needs index is not building in this mode; open the TurboGear UI driver to test grouped announces")
    end

    local deadline = os.clock() + 2.0
    while needs_index.needs_tick({ allow_peers = allow_peers }) and os.clock() < deadline do
        needs_index.tick(25, { allow_peers = allow_peers })
        if needs_index.group_ready and needs_index.group_ready() then break end
        mq.delay(10)
    end

    local st = needs_index.status and needs_index.status() or {}
    local group_ready = st.group_ready == true
    print(string.format("[TurboGear] needs index: local=%s group=%s chars=%d items=%d queued=%d failures=%d",
        tostring(st.local_ready or st.ready or false),
        tostring(group_ready),
        tonumber(st.chars) or 0,
        tonumber(st.items) or 0,
        tonumber(st.queued) or 0,
        tonumber(st.failures) or 0))

    local needers = needs_index.needers_for(item_name, item_id)
    local names = {}
    for _, need in ipairs(needers or {}) do
        names[#names + 1] = tostring(need.character or "?")
    end
    if not group_ready then
        print(string.format("[TurboGear] PARTIAL group test: needs index is still warming; built chars=%d queued=%d",
            tonumber(st.chars) or 0,
            tonumber(st.queued) or 0))
        if #names > 0 then
            print(string.format("[TurboGear] partial needers so far: %s", table.concat(names, " | ")))
        else
            print("[TurboGear] partial needers so far: none")
        end
        print("[TurboGear] Retry after /tgear status shows needs index group=true or queued=0.")
        return false
    end
    if #names > 0 then
        print(string.format("[TurboGear] WOULD group announce: [TG] - %s - %s",
            item_name, table.concat(names, " | ")))
        return true
    end
    print(string.format("[TurboGear] would NOT group announce: no visible announce-roster needers for %s",
        item_name))
    return false
end

function M.diagnose_burst(names)
    refresh_settings_if_due()
    if type(names) ~= "table" or #names == 0 then
        return false, "Usage: /tgear announcetest burst \"Item One\" \"Item Two\""
    end
    local mode = state.bg and "bg" or "ui"
    local snap = snap_for_announce()
    print(string.format("[TurboGear] announcetest burst on %s | mode=%s | items=%d",
        me_name(), mode, #names))
    local ready, idx = false, nil
    if snap and snap.class then
        ready, idx = catalog.flush_announce_catalog(snap.class, snap.name, 2000)
        announce_ready = ready
    end
    print(string.format("[TurboGear] simulating %d rapid loot lines (no announce_guard)...", #names))
    local any = false
    for i, name in ipairs(names) do
        if i > 1 then mq.delay(10) end
        local line = string.format("[ANNOUNCE] %s (test line %d)", tostring(name), i)
        local hit = try_process_chat(line, false)
        print(string.format("[TurboGear] line %d %s -> %s", i, name, hit and "announced" or "skipped"))
        any = any or hit
        diagnose_one(snap, ready, idx, name, 0)
    end
    return any
end

function M.register()
    if M.registered then return end
    cfg.LoadSharedSettings()
    local safe_name = tostring(me_name() or "me"):gsub("[^%w_]", "_")
    local prefix = string.format("tgear%s_%s_", state.bg and "Bg" or "Ui", safe_name)
    local function add(id, pattern, cb)
        local name = prefix .. id
        registered_events[#registered_events + 1] = name
        pcall(function() mq.event(name, pattern, cb, { keepLinks = true }) end)
    end
    add("MeSayItems", 'You say, #*#', on_chat_self)
    add("SayItems", '#*# says, #*#', on_chat_other)
    add("RaidItems", '#*# tells the raid, #*#', on_chat_other)
    add("MeRaidItems", 'You tell your raid, #*#', on_chat_self)
    add("GroupItems", '#*# tells the group, #*#', on_chat_other)
    add("MeGroupItems", 'You tell your party, #*#', on_chat_self)
    add("MeGroupTellGroup", 'You tell the group, #*#', on_chat_self)
    add("PartyItems", '#*# tells the party, #*#', on_chat_other)
    add("GuildItems", '#*# tells the guild, #*#', on_chat_other)
    add("MeGuildItems", 'You tell the guild, #*#', on_chat_self)
    add("MeGuildSay", 'You say to your guild, #*#', on_chat_self)
    add("OocItems", '#*# says out of character, #*#', on_chat_other)
    add("MeOocItems", 'You say out of character, #*#', on_chat_self)
    M.registered = true
    needs_index_warm = true
end

function M.set_passive(value)
    passive = value == true
    if passive then
        announce_ready = false
        pending = {}
        pending_items = {}
        announce_outbox = {}
        group_announces = {}
        next_announce_send_at = 0
    else
        M.register()
        needs_index_warm = true
        settings_refresh_ms = 0
    end
end

function M.is_passive()
    return passive
end

function M.unregister()
    if not M.registered then return end
    for _, name in ipairs(registered_events or {}) do
        pcall(function() mq.unevent(name) end)
    end
    registered_events = {}
    M.registered = false
    announce_ready = false
    pending = {}
    pending_items = {}
    announce_outbox = {}
    next_announce_send_at = 0
end

return M
