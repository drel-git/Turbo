-- TurboGear/announce_rules.lua
-- Pure announce-path rules: chat-line classification, skip filters, dedupe key
-- construction, and the [TG] message format. No mq/config dependencies so every
-- rule is unit-testable offline (tests/turbogear_announce_rules_test.lua).

local M = {}

function M.trim(s)
    return tostring(s or ""):match("^%s*(.-)%s*$") or ""
end

function M.normalize_item_name(item_name)
    return tostring(item_name or ""):lower():gsub("%s+", " "):match("^%s*(.-)%s*$") or ""
end

local function chat_payload(line)
    line = tostring(line or "")
    -- MQ console/chat windows may prepend timestamps or UI prefixes before the
    -- actual chat text. Keep the anchored checks below stable by trimming
    -- everything before a known EQ chat phrase.
    -- Order matters: longer phrases before shorter ones ("says out of character,"
    -- before "says,"; "tells the guild," before a generic tells match).
    local patterns = {
        "You tell the group,", "You tell your party,", "You tell your raid,",
        "You tell the guild,", "You say to your guild,",
        "You say out of character,", "You say,",
        "tells the group,", "tells the party,", "tells the raid,", "tells the guild,",
        "says out of character,", "says,",
    }
    for _, pat in ipairs(patterns) do
        local s = line:find(pat, 1, true)
        if s then
            if pat:sub(1, 5) == "tells" or pat:sub(1, 4) == "says" then
                local before = line:sub(1, s - 1)
                local who = before:match("([%w_'`%-]+)%s*$")
                if who and who ~= "" then return who .. " " .. line:sub(s) end
            else
                return line:sub(s)
            end
        end
    end
    return line
end

-- Lines the announcer must never react to (its own output, tells, merchants).
function M.should_skip_line(line, me_name)
    line = tostring(line or "")
    if line == "" then return true end
    if line:find("%[TG%]", 1, false) ~= nil then return true end
    if line:find("%[TurboGear%]", 1, false) ~= nil then return true end
    local lower = line:lower()
    if lower:find("turbounload", 1, true) ~= nil then return true end
    if lower:find(" tells you,", 1, true) ~= nil then return true end
    if lower:find("^you receive ") and lower:find(" merchant", 1, true) then return true end
    me_name = tostring(me_name or "")
    if me_name ~= "" and lower:find(" - " .. me_name:lower() .. "$") then return true end
    return false
end

-- Any player chat line that can carry item links (self or others).
-- Covers group/party/raid/guild/say/ooc. [TG] need-lines are filtered earlier
-- by should_skip_line so we never re-announce our own (or a peer's) [TG] output.
function M.is_player_link_chat_line(line)
    line = chat_payload(line)
    if line:find("^You tell the group,", 1) then return true end
    if line:find("^You tell your party,", 1) then return true end
    if line:find("^You tell your raid,", 1) then return true end
    if line:find("^You tell the guild,", 1) then return true end
    if line:find("^You say to your guild,", 1) then return true end
    if line:find("^You say out of character,", 1) then return true end
    if line:find("^You say,", 1) then return true end
    if line:find("^.- tells the group,", 1) then return true end
    if line:find("^.- tells the party,", 1) then return true end
    if line:find("^.- tells the raid,", 1) then return true end
    if line:find("^.- tells the guild,", 1) then return true end
    if line:find("^.- says out of character,", 1) then return true end
    if line:find("^.- says,", 1) then return true end
    return false
end

function M.is_guild_link_chat_line(line)
    line = chat_payload(line)
    if line:find("^You tell the guild,", 1) then return true end
    if line:find("^You say to your guild,", 1) then return true end
    if line:find("^.- tells the guild,", 1) then return true end
    return false
end

function M.is_ooc_link_chat_line(line)
    line = chat_payload(line)
    if line:find("^You say out of character,", 1) then return true end
    if line:find("^.- says out of character,", 1) then return true end
    return false
end

-- Our own outgoing chat lines.
function M.is_self_loot_line(line)
    line = chat_payload(line)
    if line:find("^You tell the group,", 1) then return true end
    if line:find("^You tell your party,", 1) then return true end
    if line:find("^You tell your raid,", 1) then return true end
    if line:find("^You tell the guild,", 1) then return true end
    if line:find("^You say to your guild,", 1) then return true end
    if line:find("^You say out of character,", 1) then return true end
    if line:find("^You say,", 1) then return true end
    return false
end

-- Another player's chat line (never matches our own outgoing lines).
function M.is_other_player_chat_line(line)
    line = chat_payload(line)
    if M.is_self_loot_line(line) then return false end
    if line:find("^.- tells the group,", 1) then return true end
    if line:find("^.- tells the party,", 1) then return true end
    if line:find("^.- tells the raid,", 1) then return true end
    if line:find("^.- tells the guild,", 1) then return true end
    if line:find("^.- says out of character,", 1) then return true end
    if line:find("^.- says,", 1) then return true end
    return false
end

-- Cooldown/dedupe key for a single announce: prefer item id, fall back to the
-- normalized name, scoped to server + character + list.
function M.dedupe_key(server, me_name, list_id, item_name, item_id)
    item_id = tonumber(item_id) or 0
    local item_key = item_id > 0 and ("id:" .. tostring(math.floor(item_id)))
        or ("name:" .. M.normalize_item_name(item_name))
    return tostring(server or "?") .. ":" ..
           tostring(me_name or "?") .. ":" ..
           tostring(list_id or "") .. ":" .. item_key
end

-- Grouping key for the announce-collapse window: name > id > clickable link.
-- Raw link payloads can vary across chat/event paths even when the displayed
-- item is the same. Some MQ link parse paths can also expose non-item ids, so
-- prefer the stable displayed item name whenever we have one.
-- is_link is a predicate (string -> boolean) supplied by the caller since link
-- detection depends on the runtime (item_actions.looks_like_item_link).
function M.grouped_item_key(item_name, item_id, item_link, is_link)
    item_id = tonumber(item_id) or 0
    local name = M.normalize_item_name(item_name)
    if name ~= "" then return "name:" .. name end
    if item_id > 0 then return "id:" .. tostring(math.floor(item_id)) end
    local link = tostring(item_link or "")
    if type(is_link) == "function" and is_link(link) then return "link:" .. link end
    return "name:"
end

-- Needers in a grouped announce whose need came from CACHED peer snapshots and
-- should be live-confirmed over actors before the [TG] line goes out. Skips:
--   * the local character (needers_for already live-confirms it), and
--   * "actor-reply" needers (the peer just self-evaluated on its own box).
-- order: bucket.order (display names); sources: lower(name) -> source string.
function M.confirmable_needers(order, sources, me_name)
    local out = {}
    local me = M.normalize_item_name(me_name)
    sources = type(sources) == "table" and sources or {}
    for _, name in ipairs(order or {}) do
        local key = M.normalize_item_name(name)
        if key ~= "" and key ~= me and tostring(sources[key] or "") ~= "actor-reply" then
            out[#out + 1] = name
        end
    end
    return out
end

-- Remove one character from a grouped announce bucket's needer tables.
-- names: lower(name) -> display name; order: array of display names.
-- Returns true when the character was present and removed.
function M.remove_needer(names, order, character)
    local key = M.normalize_item_name(character)
    if key == "" or type(names) ~= "table" or not names[key] then return false end
    names[key] = nil
    for i = #(order or {}), 1, -1 do
        if M.normalize_item_name(order[i]) == key then
            table.remove(order, i)
        end
    end
    return true
end

-- Corpse spawn id from a TurboLoot control line, when the item is still ON the
-- corpse. [ANNOUNCE]/[SKIP]/[IGNORE] lines carry "(ID: <corpse spawn id>)" and
-- the item was deliberately left behind, so the id is actionable (go loot it).
-- Looted-class tags (KEEP/SELL/BANK/...) are ignored: the item is gone.
function M.corpse_id_from_line(line)
    line = tostring(line or "")
    local left_on_corpse = false
    for tag in line:gmatch("%[([^%]]+)%]") do
        local t = tostring(tag or ""):lower()
        if t:find("announce", 1, true) or t:find("skip", 1, true) or t:find("ignore", 1, true) then
            left_on_corpse = true
            break
        end
        -- Looted-class tags mean the item is gone; never treat their (ID:) as
        -- an actionable corpse spawn id.
        if t:find("keep", 1, true) or t:find("sell", 1, true) or t:find("bank", 1, true)
            or t:find("destroy", 1, true) or t:find("tribute", 1, true) then
            return nil
        end
    end
    if not left_on_corpse then return nil end
    -- Last (ID: n) wins: TurboLoot stamps the corpse id at the end of the line;
    -- link frames can embed earlier numeric noise.
    local id
    for n in line:gmatch("%(%s*ID%s*:%s*(%d+)%s*%)") do
        id = n
    end
    return id and tonumber(id) or nil
end

-- Coordinator beacon freshness: the driver UI stamps shared settings while it
-- is announce-active; bg responders defer to it while the stamp is fresh.
function M.beacon_fresh(seen_at, now, ttl_s)
    seen_at = tonumber(seen_at) or 0
    if seen_at <= 0 then return false end
    now = tonumber(now) or 0
    ttl_s = tonumber(ttl_s) or 90
    local age = now - seen_at
    return age >= 0 and age <= ttl_s
end

local function norm_name(s)
    return tostring(s or ""):lower():gsub("%s+", ""):match("^%s*(.-)%s*$") or ""
end

--- Build a stable group signature from member names (sorted, pipe-joined).
function M.group_sig_from_names(names)
    local clean = {}
    for _, name in ipairs(type(names) == "table" and names or {}) do
        local n = tostring(name or ""):match("^%s*(.-)%s*$") or ""
        if n ~= "" then clean[#clean + 1] = n end
    end
    table.sort(clean, function(a, b) return a:lower() < b:lower() end)
    return table.concat(clean, "|")
end

--- Look up the per-group coordinator record.
function M.coordinator_record(coordinators, group_sig)
    if type(coordinators) ~= "table" then return nil end
    group_sig = tostring(group_sig or "")
    if group_sig == "" then return nil end
    local rec = coordinators[group_sig]
    if type(rec) ~= "table" then return nil end
    return rec
end

--- Sticky per-group claim decision for an announce-active UI.
--- Returns: action ("refresh"|"claim"|"defer"|"skip"), holder_name, reason
--- force_claim=true steals even when another holder is fresh.
function M.coordinator_claim_decision(opts)
    opts = opts or {}
    local group_sig = tostring(opts.group_sig or "")
    local me = tostring(opts.me_name or "")
    local now = tonumber(opts.now) or 0
    local ttl = tonumber(opts.ttl_s) or 90
    if group_sig == "" or me == "" then
        return "skip", "", "ungrouped"
    end
    local rec = M.coordinator_record(opts.coordinators, group_sig)
    local holder = rec and tostring(rec.name or "") or ""
    local seen_at = rec and tonumber(rec.seenAt) or 0
    local fresh = M.beacon_fresh(seen_at, now, ttl)
    if opts.force_claim == true then
        return "claim", me, "force_claim"
    end
    if fresh and holder ~= "" and norm_name(holder) ~= norm_name(me) then
        return "defer", holder, "other_holder"
    end
    if fresh and norm_name(holder) == norm_name(me) then
        return "refresh", me, "self_holder"
    end
    return "claim", me, "vacant_or_stale"
end

--- Should this process defer chat-triggered [TG] emission?
--- UI defers only when another same-group holder is fresh.
--- Bg defers when same-group holder is fresh, or (fallback) legacy machine stamp.
--- Returns defer(bool), reason, holder_name
function M.should_defer_announce(opts)
    opts = opts or {}
    local group_sig = tostring(opts.group_sig or "")
    local me = tostring(opts.me_name or "")
    local now = tonumber(opts.now) or 0
    local ttl = tonumber(opts.ttl_s) or 90
    local is_bg = opts.is_bg == true
    local rec = M.coordinator_record(opts.coordinators, group_sig)
    local holder = rec and tostring(rec.name or "") or ""
    local seen_at = rec and tonumber(rec.seenAt) or 0
    if group_sig ~= "" and M.beacon_fresh(seen_at, now, ttl) and holder ~= "" then
        if is_bg then
            return true, "group_beacon", holder
        end
        if norm_name(holder) ~= norm_name(me) then
            return true, "other_holder", holder
        end
        return false, "self_holder", holder
    end
    -- Legacy machine-wide stamp: older boxes / transition. Bg always defers;
    -- UI only defers when the legacy stamp exists and we have no per-group claim
    -- of our own (ungrouped UI should not silence itself forever).
    local legacy = tonumber(opts.legacy_seen_at) or 0
    if is_bg and M.beacon_fresh(legacy, now, ttl) then
        return true, "legacy_beacon", holder
    end
    return false, "no_beacon", holder
end

--- Apply a claim/refresh into a coordinators table (mutates a copy-friendly shape).
--- Returns updated table, changed(bool).
function M.apply_coordinator_stamp(coordinators, group_sig, name, seen_at)
    coordinators = type(coordinators) == "table" and coordinators or {}
    group_sig = tostring(group_sig or "")
    name = tostring(name or "")
    seen_at = tonumber(seen_at) or 0
    if group_sig == "" or name == "" or seen_at <= 0 then
        return coordinators, false
    end
    local prev = coordinators[group_sig]
    local same = type(prev) == "table"
        and tostring(prev.name or "") == name
        and tonumber(prev.seenAt) == seen_at
    if same then return coordinators, false end
    coordinators[group_sig] = { name = name, seenAt = seen_at }
    return coordinators, true
end

--- Drop coordinator entries older than ttl (and empty keys).
function M.prune_coordinators(coordinators, now, ttl_s)
    coordinators = type(coordinators) == "table" and coordinators or {}
    now = tonumber(now) or 0
    ttl_s = tonumber(ttl_s) or 90
    local out, changed = {}, false
    for sig, rec in pairs(coordinators) do
        if type(rec) == "table" and tostring(sig or "") ~= ""
            and M.beacon_fresh(rec.seenAt, now, ttl_s * 2) then
            out[sig] = rec
        else
            changed = true
        end
    end
    if not changed then
        local n = 0
        for _ in pairs(coordinators) do n = n + 1 end
        local m = 0
        for _ in pairs(out) do m = m + 1 end
        if n ~= m then changed = true end
    end
    return changed and out or coordinators, changed
end

-- TurboLoot GO mode outcome echo:
--   [GOLOOT] starting Wand of Foo (ID: 141)
--   [GOLOOT] looted Wand of Foo (ID: 141)
--   [GOLOOT] failed corpse_gone (ID: 141)
-- Returns status, detail (item name or fail reason), corpse_id — or nils.
function M.parse_goloot_line(line)
    line = tostring(line or "")
    local lower = line:lower()
    local tag_at = lower:find("%[goloot%]")
    if not tag_at then return nil end
    local after = line:sub(tag_at + 8):match("^%s*(.-)%s*$") or ""
    local status, rest = after:match("^(%S+)%s*(.*)$")
    if not status then return nil end
    status = status:lower()
    rest = tostring(rest or "")
    local corpse_id
    for n in rest:gmatch("%(%s*ID%s*:%s*(%d+)%s*%)") do
        corpse_id = tonumber(n)
    end
    rest = rest:gsub("%(%s*ID%s*:%s*%d+%s*%)", ""):match("^%s*(.-)%s*$") or ""
    local detail = rest
    if status == "failed" or status == "fail" then
        detail = rest:match("^(%S+)") or "failed"
    end
    return status, detail, corpse_id
end

-- Extract the item payload from a [TG] announce line (ours or another box's).
-- Format: "... '[TG] - <payload> - <names>'". The payload may itself contain
-- " - " (e.g. "Corrosive Fungus of Suffering - Tier II") so the NAMES are
-- taken after the LAST " - "; names never contain " - " (they are pipe-joined).
-- Returns the payload string (may be a raw \18 link) or nil.
function M.parse_tg_line(line)
    line = tostring(line or "")
    local s = line:find("[TG] - ", 1, true)
    if not s then return nil end
    local rest = line:sub(s + 7)
    rest = rest:gsub("['\"]+%s*$", "")
    local payload = rest
    local cut, idx = nil, 1
    while true do
        local f = rest:find(" - ", idx, true)
        if not f then break end
        cut = f
        idx = f + 1
    end
    if cut then payload = rest:sub(1, cut - 1) end
    payload = M.trim(payload)
    if payload == "" then return nil end
    return payload
end

-- The one true [TG] output format. names may be a string or an array (sorted
-- case-insensitively for stable grouped output). Multiple needers are joined
-- with " | " for legibility.
function M.format_message(payload, names)
    if type(names) == "table" then
        local sorted = {}
        for _, n in ipairs(names) do sorted[#sorted + 1] = tostring(n) end
        table.sort(sorted, function(a, b) return a:lower() < b:lower() end)
        names = table.concat(sorted, " | ")
    end
    return string.format("[TG] - %s - %s", tostring(payload or "?"), tostring(names or "?"))
end

return M
