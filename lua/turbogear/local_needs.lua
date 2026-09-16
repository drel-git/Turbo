-- TurboGear/local_needs.lua
-- Linked-item need evaluation from compact Core-oriented state only.

local ownership_index = require('ownership_index')

local M = {}

local function trim(s)
    return tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function copy_array(src)
    local out = {}
    if type(src) == "table" then
        for _, v in ipairs(src) do out[#out + 1] = v end
    end
    return out
end

local function compact_entry(entry)
    entry = type(entry) == "table" and entry or {}
    return {
        item = trim(entry.item or entry.name or ""),
        names = copy_array(entry.names),
        ids = copy_array(entry.ids),
        slot = trim(entry.slot or ""),
        group = trim(entry.group or ""),
        spell = entry.spell,
        spells = copy_array(entry.spells),
        spell_ids = copy_array(entry.spell_ids),
    }
end

function M.build_local_state(opts)
    opts = type(opts) == "table" and opts or {}
    local candidates = {}
    for _, c in ipairs(opts.candidates or {}) do
        candidates[#candidates + 1] = {
            kind = tostring(c.kind or ""),
            eval_path = tostring(c.eval_path or ""),
            list_id = tostring(c.list_id or ""),
            list_name = tostring(c.list_name or ""),
            slot = trim(c.slot or (c.entry and c.entry.slot) or ""),
            group = trim(c.group or (c.entry and c.entry.group) or ""),
            entry = compact_entry(c.entry),
            satisfy = c.satisfy and compact_entry(c.satisfy) or nil,
            match = c.match and compact_entry(c.match) or nil,
            item_name = trim(c.item_name or (c.entry and c.entry.item) or ""),
            enabled = c.enabled ~= false,
            link_matched = c.link_matched == true,
            matched_by = tostring(c.matched_by or ""),
            peer_freshness = c.peer_freshness,
            locator_id = c.locator_id,
            semantic_version = c.semantic_version,
        }
    end
    return {
        identity = type(opts.identity) == "table" and opts.identity or {},
        freshness = type(opts.freshness) == "table" and opts.freshness or {},
        ownership = type(opts.ownership) == "table" and opts.ownership or { by_id = {}, by_name = {}, known_spells = {} },
        candidates = candidates,
        live_provider = opts.live_provider,
        peer_freshness_provider = opts.peer_freshness_provider,
    }
end

local function link_matches_entry(entry, link)
    entry = type(entry) == "table" and entry or {}
    link = type(link) == "table" and link or {}
    local lname = ownership_index.norm_item_name(link.name)
    if lname ~= "" then
        for _, name in ipairs(entry.names or { entry.item }) do
            if ownership_index.norm_item_name(name) == lname
                and not ownership_index.name_is_id_only(name) then
                return true, "name"
            end
        end
    end
    local iid = tonumber(link.id)
    if iid and iid > 0 then
        for _, id in ipairs(entry.ids or {}) do
            if tonumber(id) == iid then return true, "id" end
        end
    end
    return false, ""
end

local function known_spell_name(ownership, spell_name)
    local want = ownership_index.norm(trim(spell_name))
    return want ~= "" and type(ownership.known_spells) == "table" and ownership.known_spells[want] == true
end

local function entry_spells_known(entry, ownership)
    local list = nil
    if type(entry.spells) == "table" and #entry.spells > 0 then
        list = entry.spells
    elseif trim(entry.spell or "") ~= "" then
        list = { entry.spell }
    end
    local ids = entry.spell_ids
    if type(ids) == "table" and #ids > 0 and (not list or #list <= 1) then
        local by_id = ownership.known_spell_ids
        if type(by_id) == "table" then
            for _, id in ipairs(ids) do
                if by_id[tonumber(id)] then return true end
            end
        end
        if list then
            for _, spell in ipairs(list) do
                if known_spell_name(ownership, spell) then return true end
            end
        end
        return false
    end
    if not list then return false end
    for _, spell in ipairs(list) do
        if not known_spell_name(ownership, spell) then return false end
    end
    return true
end

local function live_status(state, candidate, link)
    local provider = state and state.live_provider
    if type(provider) == "function" then
        local ok, status = pcall(provider, candidate.entry, link, candidate)
        if ok then return status end
        return nil, tostring(status or "live provider error")
    end
    if type(provider) == "table" and type(provider.status) == "function" then
        local ok, status = pcall(provider.status, candidate.entry, link, candidate)
        if ok then return status end
        return nil, tostring(status or "live provider error")
    end
    return nil
end

local function status_is_have(status)
    return status ~= nil and status ~= "missing"
end

local function peer_fresh_status(state, candidate)
    local ident = type(state and state.identity) == "table" and state.identity or {}
    if ident.local_owner == true then return nil end
    candidate = type(candidate) == "table" and candidate or {}
    if candidate.kind ~= "builtin" then return nil end
    if trim(candidate.list_id or "") == "" or trim(candidate.slot or "") == "" then return nil end
    local provider = state and state.peer_freshness_provider
    if type(provider) ~= "function" then return nil end
    local ok, rec = pcall(provider, candidate)
    if not ok then return nil, tostring(rec or "peer freshness provider error") end
    if type(rec) ~= "table" or rec.status == nil then return nil end
    local status = tostring(rec.status or "")
    if status ~= "equipped" and status ~= "carried" and status ~= "missing" then
        status = (tonumber(rec.count) or 0) > 0 and "carried" or "missing"
    end
    local loc = tostring(rec.location or "")
    if loc == "" then loc = status == "equipped" and "Equipped" or "Bags" end
    local match = nil
    if status_is_have(status) then
        match = {
            name = rec.name or candidate.item_name or (candidate.entry and candidate.entry.item) or "",
            id = tonumber(rec.id) or nil,
            where = loc,
            slotname = loc,
            location = loc,
            source = "bis_search",
            count = tonumber(rec.count) or nil,
        }
    end
    return {
        status = status,
        match = match,
        record = {
            present = true,
            status = status,
            name = rec.name,
            count = rec.count,
            location = loc,
            updated = rec.updated,
        },
    }
end

local function ownership_summary(ownership)
    local ids, names, spells, spell_ids = 0, 0, 0, 0
    for _ in pairs(ownership.by_id or {}) do ids = ids + 1 end
    for _ in pairs(ownership.by_name or {}) do names = names + 1 end
    for _ in pairs(ownership.known_spells or {}) do spells = spells + 1 end
    for _ in pairs(ownership.known_spell_ids or {}) do spell_ids = spell_ids + 1 end
    return { ids = ids, names = names, spells = spells, spell_ids = spell_ids }
end
M.ownership_summary = ownership_summary

function M.evaluate_link(state, link)
    state = type(state) == "table" and state or {}
    link = type(link) == "table" and link or {}
    local ownership = type(state.ownership) == "table" and state.ownership or {}
    local matched_any = false
    local last_owned = nil
    for _, candidate in ipairs(state.candidates or {}) do
        if candidate.enabled then
            local matched, matched_by = true, tostring(candidate.matched_by or "")
            if not candidate.link_matched then
                matched, matched_by = link_matches_entry(candidate.entry, link)
            end
            if matched then
                matched_any = true
                local satisfy = candidate.satisfy or candidate.entry
                local peer_fresh, peer_err = peer_fresh_status(state, candidate)
                if peer_err then
                    return {
                        need = false,
                        reason = "error",
                        error = peer_err,
                        candidate = candidate,
                        ownership = ownership_summary(ownership),
                    }
                end
                local match, status
                if peer_fresh then
                    match, status = peer_fresh.match, peer_fresh.status
                else
                    match, status = ownership_index.entry_status(satisfy, ownership)
                end
                if not peer_fresh and not status_is_have(status) and entry_spells_known(satisfy, ownership) then
                    match, status = satisfy.item, "known"
                end
                local live_used = false
                if not peer_fresh and not status_is_have(status) and state.live_provider then
                    local original_entry = candidate.entry
                    candidate.entry = satisfy
                    local live, live_err = live_status(state, candidate, link)
                    candidate.entry = original_entry
                    if live_err then
                        return {
                            need = false,
                            reason = "error",
                            error = live_err,
                            candidate = candidate,
                            ownership = ownership_summary(ownership),
                        }
                    end
                    if status_is_have(live) then
                        status = live
                        live_used = true
                    end
                end
                if not status_is_have(status) then
                    return {
                        need = true,
                        reason = "need",
                        status = "missing",
                        match = nil,
                        matched = true,
                        matched_by = matched_by,
                        candidate = candidate,
                        peer_fresh_used = peer_fresh ~= nil,
                        peer_fresh_record = peer_fresh and peer_fresh.record or nil,
                        ownership = ownership_summary(ownership),
                    }
                end
                last_owned = {
                    need = false,
                    reason = live_used and "owned-live" or (peer_fresh and "owned-peer-fresh" or "owned"),
                    status = status,
                    match = match,
                    matched = true,
                    matched_by = matched_by,
                    live_used = live_used,
                    candidate = candidate,
                    peer_fresh_used = peer_fresh ~= nil,
                    peer_fresh_record = peer_fresh and peer_fresh.record or nil,
                    ownership = ownership_summary(ownership),
                }
            end
        end
    end
    if last_owned then return last_owned end
    return {
        need = false,
        reason = matched_any and "owned" or "no-row",
        matched = matched_any,
        ownership = ownership_summary(ownership),
    }
end

function M.trace_link(state, link)
    state = type(state) == "table" and state or {}
    link = type(link) == "table" and link or {}
    local result = M.evaluate_link(state, link)
    local candidate = type(result.candidate) == "table" and result.candidate or nil
    local ownership = type(state.ownership) == "table" and state.ownership or {}
    local store_match, store_status = nil, nil
    if candidate then
        store_match, store_status = ownership_index.entry_status(candidate.satisfy or candidate.entry or candidate, ownership)
    end
    local now = tonumber(state.now) or os.time()
    local fresh = type(state.freshness) == "table" and state.freshness or {}
    local peer_rec = type(result.peer_fresh_record) == "table" and result.peer_fresh_record or nil
    local function age(ts)
        ts = tonumber(ts) or 0
        if ts <= 0 then return nil end
        return math.max(0, now - ts)
    end
    local source = "store"
    if result.peer_fresh_used == true then
        source = "bis_search"
    elseif result.live_used == true then
        source = "live"
    end
    return {
        character = state.identity and state.identity.name or nil,
        item = link.name,
        id = link.id,
        final_need = result.need == true,
        final_reason = result.reason,
        final_source = source,
        decision_source = source,
        linked_needs_source = source,
        store_status = store_status,
        store_name = type(store_match) == "table" and store_match.name or store_match,
        bis_search_present = peer_rec ~= nil,
        bis_search_status = peer_rec and peer_rec.status or nil,
        bis_search_name = peer_rec and peer_rec.name or nil,
        snapshot_age = age(fresh.inventoryUpdated or fresh.updated),
        snapshot_depth = fresh.depth,
        bis_search_age = age(peer_rec and peer_rec.updated),
        candidate = candidate,
        result = result,
    }
end

function M.classify_mismatch(authoritative, shadow, state, link)
    authoritative = type(authoritative) == "table" and authoritative or {}
    shadow = type(shadow) == "table" and shadow or {}
    state = type(state) == "table" and state or {}
    if (authoritative.need == true) == (shadow.need == true) then return nil end
    if shadow.error then return "unknown/error" end
    local fresh = type(state.freshness) == "table" and state.freshness or {}
    if fresh.inventoryIncomplete == true or fresh.bankUnknown == true then
        return "stale-or-incomplete-input"
    end
    if shadow.matched ~= true or shadow.reason == "no-row" then
        return "normalization/key"
    end
    local ident = type(state.identity) == "table" and state.identity or {}
    if ident.local_owner == true and (shadow.live_used == true or state.live_provider ~= nil) then
        return "local-live-fallback"
    end
    local cand = shadow.candidate or {}
    if ident.local_owner ~= true and cand.kind == "builtin" then
        return "peer-live/bis_search-freshness"
    end
    if link and trim(link.name) == "" and (tonumber(link.id) or 0) <= 0 then
        return "normalization/key"
    end
    return "semantic/rule"
end

return M
