--[[ ============================================================================
  TurboGear/init.lua  -- live multi-character inventory engine (modular)
  EQEmu RoF2 + e3next / MacroQuest        (formerly TurboAugs, Phase 1 engine)
  ----------------------------------------------------------------------------
  STRUCTURE (lean modular; tabs broken out for headroom)
    config.lua   constants, settings, broadcast presets, paths, launch helpers
    state.lua    runtime control flags (run / show / bg)
    theme.lua    Turbo theme tokens + ImGui draw helpers
    items.lua    slot order + item/aug TLO helpers (make_item shape)
    store.lua    unified hybrid store + cache persistence
    snapshot.lua self inventory gather (cached)
    engine.lua   actor sync engine  [E3 broadcast HARD-STOP: logic verbatim]
    views.lua    shared render helpers + "Viewing:" selector
    ui.lua       window shell + tab bar (crash-safe render)
    tabs/        worn | empty | augbag | compare | spells | setup
    data/        researchlearn.ini (bundled spell recipes)
    references/  spells.lua + lockouts + anguish refs
  ----------------------------------------------------------------------------
  RUN   /lua run turbogear            (opens UI, auto-launches peers in bg)
  BG    /lua run turbogear_bg         (headless responder; leaves UI entrypoint free)
  MINI  /lua run turbogear mini       (UI loaded, starts as mini icon)
  UI    /lua run turbogear ui         (explicit UI start)
  CMDS  /tgear show|hide|sync|publish|status|debug|diag|perfdiag|stop|toggle   (also /turbogear)
        /tgear exportspells [copies]  export missing research list
        /tgear import <file>  /tgear export <list>  /tgear sharelist <list>
        /tgear pulllists <Server_CharName>
============================================================================ ]]

local mq = require('mq')

local SCRIPT_ARGS = { ... }              -- must be captured at chunk top level

local cfg    = require('config')
local CFG    = cfg.CFG
cfg.LoadSettings()
cfg.LoadSharedSettings()
local guard  = require('runtime_guard')

local FORCE_BG = rawget(_G, '__TurboGearForceBg') == true

local state  = require('state')
state.bg     = FORCE_BG
    or (SCRIPT_ARGS[1] == 'bg')
-- Background/responder instances start hidden. Full UI launches are viewers and
-- controls; if a local bg responder is already running, the UI leaves it as the
-- actor owner and reads the shared cache instead of stealing the mailbox.
state.show   = not state.bg
    and not (SCRIPT_ARGS[1] == 'mini' or (cfg.Settings.startMinimized == true and SCRIPT_ARGS[1] ~= 'ui'))

local store  = require('store')
local Store, my_key = store.Store, store.my_key
local Engine = require('engine').Engine
local announcer = require('announcer')
local inventory_watch = require('inventory_watch')
local diag   = require('diagnostics')
local peer_discovery = require('peer_discovery')

-- ===================== ENTRY POINTS ===================================== --
Store.load()

local local_owner_guard = {
    next_at = 0,
    last_action = "",
    last_action_at = 0,
}
local refresh_local_guard_state
local request_local_bg_start

-- Actor mailbox registration helper (bg responder only). NON-FATAL by design: a
-- failed claim (mailbox briefly held by a just-crashed instance, transient actor
-- hiccup, etc.) must never abort startup - doing so would leave the box with no
-- command binds and no responder (the exact "Discord won't run" failure). We
-- always bind and run; the run loop keeps retrying registration so a degraded
-- responder self-heals the moment the mailbox frees.
--
-- STATIC ROLES: the bg responder always owns actor sync and publishing; the UI
-- is always a viewer/announce-coordinator and never claims the mailbox. If the
-- bg responder is missing, the UI's only job is to (re)start it.
local function init_engine_with_retry(attempts, gap_ms)
    attempts = tonumber(attempts) or 6
    gap_ms = tonumber(gap_ms) or 120
    for i = 1, attempts do
        local ok, why = Engine.init()
        if ok then return true end
        if why == "no_actors" then break end       -- retrying cannot help
        if i < attempts then pcall(function() mq.delay(gap_ms) end) end
    end
    return Engine.ok == true
end

announcer.register()
inventory_watch.register()
inventory_watch.seed_signature()

local function age_text(seconds)
    seconds = tonumber(seconds)
    if not seconds or seconds < 0 then return "never" end
    if seconds < 60 then return string.format("%ds", math.floor(seconds + 0.5)) end
    if seconds < 3600 then return string.format("%dm", math.floor(seconds / 60 + 0.5)) end
    return string.format("%dh", math.floor(seconds / 3600 + 0.5))
end

local function announce_status_safe()
    local ok, ast = pcall(function() return announcer.status() end)
    if ok and type(ast) == "table" then return ast end
    return {
        enabled = cfg.SharedSettings.bisAnnounceEnabled ~= false,
        actor = false,
        ready = false,
        index_label = "status unavailable",
        pending = 0,
        pending_chat = 0,
        pending_actor = 0,
        pending_outbox = 0,
        pending_group = 0,
        lists_on = 0,
        lists_total = 0,
        channel = "?",
        status_error = tostring(ast or "unknown"),
    }
end

local function status_lines(max_peers, colorize)
    max_peers = tonumber(max_peers) or 12
    colorize = colorize == true
    local lines = {}
    local views = require('views')
    local on, st, off = Store.counts()
    local s = Engine.stats
    local scripts = refresh_local_guard_state and refresh_local_guard_state() or state.local_guard_scripts or {}
    lines[#lines + 1] = string.format("[TurboGear] %s | role=%s | scripts %s | engine=%s | mode=%s | debug=%s | peers %d/%d/%d | tx req=%d snap=%d skip=%d | rx req=%d snap=%d bad=%d",
        my_key(), tostring(state.local_guard_role or "?"), guard.script_summary(scripts),
        tostring(Engine.ok), (state.lean and state.lean()) and "lean" or "rich", tostring(Engine.debug),
        on, st, off, s.tx_req, s.tx_snap, s.tx_skip or 0, s.rx_req, s.rx_snap, s.rx_bad)
    if tostring(state.local_guard_last_action or "") ~= "" then
        lines[#lines + 1] = "[TurboGear] local guard: " .. tostring(state.local_guard_last_action)
    end
    if Engine.last_source_request then
        local req = Engine.last_source_request
        local reply = Engine.last_source_reply
        local reply_text = "-"
        if reply then
            reply_text = string.format("%s %s ago id=%s",
                tostring(reply.name or "?"), age_text(os.time() - (tonumber(reply.received) or os.time())), tostring(reply.id or "?"))
        end
        lines[#lines + 1] = string.format("[TurboGear] last target request: %s %s ago id=%s depth=%s | last reply: %s",
            tostring(req.name or req.key or "?"), age_text(os.time() - (tonumber(req.sent) or os.time())),
            tostring(req.id or "?"), tostring(req.depth or "?"), reply_text)
    end
    local keys = Store.peer_keys and Store.peer_keys() or {}
    table.sort(keys)
    local shown = 0
    for _, key in ipairs(keys) do
        if key ~= my_key() then
            local ps = views.source_state(key)
            shown = shown + 1
            lines[#lines + 1] = string.format("[TurboGear]   peer %s [%s] | %s | inv %s %s | bank %s | items %d",
                tostring(ps.label or key),
                tostring(ps.tag or "?"),
                tostring(ps.responder or "?"),
                age_text(ps.inventoryAge),
                tostring(ps.depth or ""),
                age_text(ps.bankAge),
                tonumber(ps.itemCount) or 0)
            if shown >= max_peers then break end
        end
    end
    if #keys > shown then
        lines[#lines + 1] = string.format("[TurboGear]   peers truncated: %d shown / %d total", shown, #keys)
    end
    local ast = announce_status_safe()
    local actor_label = ast.passive and "passive" or (ast.actor and "ON" or "OFF")
    lines[#lines + 1] = string.format("[TurboGear] announce: %s | %s | actor=%s | pending=%d | lists %d/%d | channel=%s | coord=%s",
        ast.enabled and "ON" or "OFF", ast.index_label or (ast.ready and "ready" or "warming"),
        actor_label, ast.pending or 0, ast.lists_on or 0, ast.lists_total or 0, tostring(ast.channel or "?"),
        tostring(ast.coordinator or "?"))
    lines[#lines + 1] = string.format("[TurboGear]   announce roster: scope=%s | viewing=%s | chars=%d%s%s",
        tostring(ast.announce_scope or "?"),
        tostring(ast.announce_view or "?"),
        tonumber(ast.announce_roster_count) or 0,
        tostring(ast.announce_roster_names or "") ~= "" and (" | " .. tostring(ast.announce_roster_names or "")) or "",
        ast.announce_roster_truncated and ", ..." or "")
    lines[#lines + 1] = string.format("[TurboGear]   pending: chat=%d actor=%d group=%d target=%d outbox=%d | duplicate=%d | dropped pending=%d outbox=%d | replay rx=%d tx=%d checked=%d",
        ast.pending_chat or 0, ast.pending_actor or 0, ast.pending_group or 0,
        ast.target_checks_pending or 0, ast.pending_outbox or 0,
        ast.duplicate_suppressed or 0, ast.pending_dropped or 0, ast.outbox_dropped or 0,
        ast.replay_received or 0, ast.replay_sent or 0, ast.replay_checked or 0)
    if (ast.target_checks_pending or 0) > 0 or (ast.target_checks_completed or 0) > 0 then
        lines[#lines + 1] = string.format("[TurboGear]   targeted linked checks: pending=%d completed=%d | last=%s via %s items=%d peers=%d added=%d",
            ast.target_checks_pending or 0, ast.target_checks_completed or 0,
            tostring(ast.last_group_scan_mode or "-"), tostring(ast.last_group_scan_source or "-"),
            ast.last_group_scan_items or 0, ast.last_group_scan_snaps or 0, ast.last_group_scan_added or 0)
    end
    if tostring(ast.last_chat_sample or "") ~= "" then
        lines[#lines + 1] = string.format("[TurboGear]   last chat: links=%d first=%s note=%s (%s) | %s",
            ast.last_chat_links or 0,
            tostring(ast.last_chat_first_item or "-"),
            tostring(ast.last_chat_note or "-"),
            ast.last_chat_age or "?",
            tostring(ast.last_chat_sample or ""):sub(1, 120))
    end
    if ast.last_loot_item ~= "" then
        lines[#lines + 1] = string.format("[TurboGear]   last loot: %s via %s (%s)",
            ast.last_loot_item, ast.last_loot_source or "?", ast.last_loot_age or "?")
    end
    if ast.last_sent_item ~= "" then
        lines[#lines + 1] = string.format("[TurboGear]   last [TG]: %s (%s)", ast.last_sent_item, ast.last_sent_age or "?")
    end
    if ast.last_skip_item ~= "" then
        lines[#lines + 1] = string.format("[TurboGear]   last skip: %s - %s (%s)",
            ast.last_skip_item, ast.last_skip_reason or "?", ast.last_skip_age or "?")
    end
    if (ast.pending or 0) > 0 and ast.last_pending_item ~= "" then
        lines[#lines + 1] = string.format("[TurboGear]   last pending: %s via %s - %s (%s)",
            ast.last_pending_item, ast.last_pending_source or "?",
            ast.last_pending_reason or "?", ast.last_pending_age or "?")
    end
    if type(ast.needs_index) == "table" then
        local ni = ast.needs_index
        local cb = ""
        if type(ni.catalog_build) == "table" then
            cb = string.format(" | catalogBuild=list %d/%d (%d entries)",
                tonumber(ni.catalog_build.ref_i) or 0,
                tonumber(ni.catalog_build.refs_total) or 0,
                tonumber(ni.catalog_build.entries) or 0)
        end
        if ni.disabled then
            lines[#lines + 1] = "[TurboGear]   needs index: off | linked announces use bounded direct checks"
        else
            lines[#lines + 1] = string.format("[TurboGear]   needs index: %s | chars=%d items=%d queued=%d rebuilds=%d attempts=%d failures=%d tombstoned=%d%s",
                ni.ready and "ready" or "warming", tonumber(ni.chars) or 0, tonumber(ni.items) or 0,
                tonumber(ni.queued) or 0, tonumber(ni.rebuilds) or 0,
                tonumber(ni.attempts) or 0, tonumber(ni.failures) or 0,
                tonumber(ni.tombstoned) or 0, cb)
            lines[#lines + 1] = string.format("[TurboGear]   needs work: builds %d/%d | evalEntries=%d | maxEntry=%.1fms | oldestQueue=%.1fs",
                tonumber(ni.builds_finished) or 0, tonumber(ni.builds_started) or 0,
                tonumber(ni.eval_entries) or 0, tonumber(ni.max_single_entry_ms) or 0,
                tonumber(ni.oldest_queue_age_s) or 0)
        end
        if ni.building_key then
            lines[#lines + 1] = string.format("[TurboGear]   needs building: %s %d/%d",
                tostring(ni.building_key),
                tonumber(ni.building_i) or 0,
                tonumber(ni.building_recs) or 0)
        end
        if type(ni.last_build) == "table" then
            lines[#lines + 1] = string.format("[TurboGear]   needs last build: %s recs=%d needs=%d elapsed=%.1fms",
                tostring(ni.last_build.key or "?"),
                tonumber(ni.last_build.recs) or 0,
                tonumber(ni.last_build.needs) or 0,
                tonumber(ni.last_build.elapsed_ms) or 0)
        end
        if type(ni.last_enqueue) == "table" then
            lines[#lines + 1] = string.format("[TurboGear]   needs last enqueue: %s reason=%s %s",
                tostring(ni.last_enqueue.key or "?"),
                tostring(ni.last_enqueue.reason or "?"),
                tostring(ni.last_enqueue.detail or ""))
        end
    end
    if type(ast.link_capture) == "table" then
        local lc = ast.link_capture
        lines[#lines + 1] = string.format("[TurboGear]   link capture: chatLinks=%s linkdb=%s cachedLinks=%d seenAnnounces=%d",
            lc.chat_links and "yes" or "NO (MQ build lacks ExtractLinks - text-only announces)",
            lc.linkdb and "yes" or "no",
            tonumber(lc.cached) or 0, tonumber(lc.seen) or 0)
    end
    if (ast.last_group_scan_items or 0) > 0 then
        lines[#lines + 1] = string.format("[TurboGear]   last group scan: %s via %s | items=%d snaps=%d names=%d (%s)",
            ast.last_group_scan_mode or "?",
            ast.last_group_scan_source or "?",
            ast.last_group_scan_items or 0,
            ast.last_group_scan_snaps or 0,
            ast.last_group_scan_added or 0,
            ast.last_group_scan_age or "?")
    end
    if colorize then
        local function color_for(line)
            line = tostring(line or "")
            if line:find("WARNING", 1, true) or line:find("warming", 1, true) or line:find("pending:", 1, true) then return "\ay" end
            if line:find("ready", 1, true) or line:find("[visible]", 1, true) or line:find("last [TG]", 1, true) then return "\ag" end
            if line:find("last loot", 1, true) or line:find("last group scan", 1, true) or line:find("linked checks", 1, true) or line:find("needs index: off", 1, true) then return "\at" end
            if line:find("[offline", 1, true) or line:find("not answering", 1, true) then return "\aw" end
            if line:find("failures=", 1, true) or line:find("last skip", 1, true) then return "\ao" end
            return "\aw"
        end
        for i, line in ipairs(lines) do
            lines[i] = color_for(line) .. tostring(line or "") .. "\ax"
        end
    end
    return lines
end

local perfdiag_capture = nil

local function append_lines(out, lines)
    for _, line in ipairs(lines or {}) do out[#out + 1] = tostring(line or "") end
end

local function sanitize_filename_part(s)
    s = tostring(s or ""):gsub("[^%w_%-.]+", "_")
    if s == "" then s = "unknown" end
    return s
end

local function perfdiag_path()
    local stamp = os.date("%Y%m%d_%H%M%S")
    return string.format("%s/%s_diag_%s_%s.txt",
        mq.configDir, tostring(CFG.script_name or "TurboGear"), sanitize_filename_part(my_key()), stamp)
end

local function build_perfdiag_lines(capture, reason)
    local lines = {}
    capture = capture or {}
    lines[#lines + 1] = "TurboGear Performance Diagnostic"
    lines[#lines + 1] = string.format("Written: %s", os.date("%Y-%m-%d %H:%M:%S"))
    lines[#lines + 1] = string.format("Reason: %s", tostring(reason or "manual"))
    lines[#lines + 1] = string.format("Version: %s", tostring(CFG.version or "?"))
    lines[#lines + 1] = string.format("Character: %s", my_key())
    if capture.mode then
        lines[#lines + 1] = string.format("Capture mode: %s", tostring(capture.mode))
    end
    if capture.started_wall then
        lines[#lines + 1] = string.format("Capture started: %s", tostring(capture.started_wall))
        lines[#lines + 1] = string.format("Capture seconds: %.1f", math.max(0, os.clock() - (tonumber(capture.started_clock) or os.clock())))
    end
    lines[#lines + 1] = ""
    lines[#lines + 1] = "Runtime Status"
    append_lines(lines, status_lines(80))
    lines[#lines + 1] = ""
    lines[#lines + 1] = "Performance Settings"
    local ast = announce_status_safe()
    local cache_status = Store.cache_status and Store.cache_status() or {}
    lines[#lines + 1] = string.format("show=%s bg=%s lean=%s mainTab=%s gearTab=%s performanceMode=%s autoPeerRefresh=%s",
        tostring(state.show), tostring(state.bg), tostring(state.lean and state.lean() or false),
        tostring(cfg.Settings.mainTab or ""), tostring(cfg.Settings.gearTab or ""),
        tostring(cfg.Settings.performanceMode or ""), tostring(cfg.Settings.autoPeerRefresh))
    lines[#lines + 1] = string.format("publish every: ui=%.1fs minimized=%.1fs bg=%.1fs lean=%.1fs jitter=%.1fs",
        tonumber(CFG.publish_every_s) or 0, tonumber(CFG.publish_every_minimized_s) or 0,
        tonumber(CFG.publish_every_bg_s) or 0, tonumber(CFG.publish_every_lean_s) or 0,
        tonumber(CFG.publish_jitter_s) or 0)
    lines[#lines + 1] = string.format("keepalive every: ui=%.1fs bg=%.1fs lean=%.1fs",
        tonumber(CFG.keepalive_publish_s) or 45, tonumber(CFG.keepalive_publish_bg_s) or 30,
        tonumber(CFG.keepalive_publish_lean_s) or 90)
    lines[#lines + 1] = string.format("save every: ui=%.1fs minimized=%.1fs bg=%.1fs heavyUI=%.1fs",
        tonumber(CFG.save_every_s) or 0, tonumber(CFG.save_every_minimized_s) or 0,
        tonumber(CFG.save_every_bg_s) or 0, tonumber(CFG.save_every_heavy_ui_s) or 0)
    lines[#lines + 1] = string.format("inventory watch: enabled=%s debounce=%.1fs publishCooldown=%.1fs bgPoll=%.1fs",
        tostring(CFG.inventory_watch_enabled ~= false), tonumber(CFG.inventory_watch_debounce_s) or 0,
        tonumber(CFG.inventory_watch_publish_cooldown_s) or 0, tonumber(CFG.inventory_watch_bg_poll_s) or 0)
    lines[#lines + 1] = string.format("announce budgets: ui=%dms lean=%dms bg=%dms flush=%dms",
        tonumber(CFG.announce_catalog_budget_ms) or 0, tonumber(CFG.announce_catalog_budget_lean_ms) or 0,
        tonumber(CFG.announce_catalog_budget_bg_ms) or 0, tonumber(CFG.announce_flush_budget_ms) or 0)
    lines[#lines + 1] = string.format("announce queues: dedupe=%.1fs pendingMax=%d outboxMax=%d pendingPerTick=%d pendingBudget=%dms outboxDelay=%dms",
        tonumber(CFG.bis_announce_cooldown_s) or 0,
        tonumber(CFG.announce_pending_max) or 0,
        tonumber(CFG.announce_outbox_max) or 0,
        tonumber(CFG.announce_pending_items_per_tick) or 0,
        tonumber(CFG.announce_pending_budget_ms) or 0,
        tonumber(CFG.announce_outbox_delay_ms) or 0)
    lines[#lines + 1] = string.format("announce role: passive=%s sharedSettings=%s",
        tostring(ast.passive == true), tostring(cfg.SharedSettingsFile or ""))
    lines[#lines + 1] = string.format("cache status: %s", tostring(cache_status.reason or ""))
    lines[#lines + 1] = string.format("cacheFile=%s", tostring(cfg.CacheFile or ""))
    lines[#lines + 1] = string.format("settingsFile=%s", tostring(cfg.SettingsFile or ""))
    lines[#lines + 1] = ""
    for _, filter in ipairs({ "", "snapshot", "engine", "store", "announce", "inventory_watch", "ui" }) do
        append_lines(lines, diag.lines(filter))
        lines[#lines + 1] = ""
    end
    lines[#lines + 1] = "Memory & Caches"
    lines[#lines + 1] = string.format("Lua heap: %.0f KB", collectgarbage("count"))
    do
        local ok_ni, needs_index = pcall(require, 'needs_index')
        if ok_ni and needs_index and needs_index.status then
            local ok_s, ni = pcall(needs_index.status)
            if ok_s and type(ni) == "table" and type(ni.caches) == "table" then
                lines[#lines + 1] = string.format("needs-index key caches: norm=%d strip=%d cap=%d clears=%d",
                    tonumber(ni.caches.norm) or 0, tonumber(ni.caches.strip) or 0,
                    tonumber(ni.caches.cap) or 0, tonumber(ni.caches.clears) or 0)
            end
        end
        -- Process-level memory gauge stands in for catalog residency (P2): the
        -- 34k-line catalog is the dominant fixed allocation, so a spike here
        -- after a lazy-load change is directly visible.
        -- P2: report whether the big catalog DATA is resident (requiring the
        -- module no longer loads the 34k-line table thanks to the lazy proxy).
        local ok_cat, catalog = pcall(require, 'bis_catalog')
        local cat_resident = ok_cat and catalog and catalog.catalog_loaded and catalog.catalog_loaded() or false
        lines[#lines + 1] = string.format("catalog data resident: %s", tostring(cat_resident))
    end
    lines[#lines + 1] = ""
    -- Swallowed-error tally (always recorded, even with debug off): a dropped
    -- actor send / file write shows here instead of looking like a silent no-op.
    if diag.error_lines then
        append_lines(lines, diag.error_lines())
        lines[#lines + 1] = ""
    end
    append_lines(lines, diag.recent_slow_lines(80))
    lines[#lines + 1] = ""
    append_lines(lines, diag.recent_event_lines(100))
    return lines
end

local function write_perfdiag_file(capture, reason)
    local path = perfdiag_path()
    local lines = build_perfdiag_lines(capture, reason)
    local ok, err = pcall(function()
        local fh = assert(io.open(path, "w"))
        for _, line in ipairs(lines) do
            fh:write(tostring(line or ""), "\n")
        end
        fh:close()
    end)
    if not ok then return nil, err end
    return path
end

local function finish_perfdiag(reason)
    if not perfdiag_capture then return false end
    local capture = perfdiag_capture
    perfdiag_capture = nil
    local path, err = write_perfdiag_file(capture, reason or "complete")
    Engine.debug = capture.previous_debug == true
    diag.set_enabled(capture.previous_diag == true)
    if path then
        print("[TurboGear] perfdiag file written: " .. tostring(path))
        return true
    end
    print("[TurboGear] perfdiag write failed: " .. tostring(err))
    return false
end

local function start_perfdiag(arg1, arg2)
    local mode = "debug"
    local seconds = tonumber(arg1)
    if seconds == nil then
        local first = tostring(arg1 or ""):lower()
        if first == "nodebug" or first == "lean" or first == "low" or first == "lowoverhead" then
            mode = "nodebug"
            seconds = tonumber(arg2)
        elseif first ~= "" then
            seconds = tonumber(arg2)
        end
    end
    seconds = tonumber(seconds) or 180
    if seconds < 30 then seconds = 30 end
    if seconds > 600 then seconds = 600 end
    perfdiag_capture = {
        started_clock = os.clock(),
        deadline = os.clock() + seconds,
        started_wall = os.date("%Y-%m-%d %H:%M:%S"),
        mode = mode,
        previous_debug = Engine.debug == true,
        previous_diag = diag.is_enabled and diag.is_enabled() or false,
    }
    diag.reset()
    diag.set_slow_threshold(50)
    Engine.debug = mode ~= "nodebug"
    diag.set_enabled(true)
    print(string.format("[TurboGear] perfdiag recording for %.0fs (%s). Reproduce the stutter; a file will be written automatically.",
        seconds, mode))
    return true
end

local function tick_perfdiag_capture()
    if perfdiag_capture and os.clock() >= (tonumber(perfdiag_capture.deadline) or 0) then
        finish_perfdiag("timer complete")
    end
end

local function parse_item_name_id(text)
    text = tostring(text or ""):match("^%s*(.-)%s*$") or ""
    local item_id = 0
    local name = text
    local n1, id1 = text:match("^(.-)%s*%(%s*ID%s*:%s*(%d+)%s*%)%s*$")
    if n1 and id1 then
        name, item_id = n1, tonumber(id1) or 0
    elseif text:match("%s(%d+)$") then
        name, item_id = text:match("^(.-)%s(%d+)$")
        item_id = tonumber(item_id) or 0
    end
    name = tostring(name or ""):match("^%s*(.-)%s*$") or ""
    return name, item_id
end

local function tgear_command(...)
    local args = { ... }
    local arg = (args[1] or ""):lower()
    local rest = table.concat(args, " ", 2)   -- list names / file names may contain spaces
    if arg == "import" then
        local list, err = require('userlists').import(rest)
        print(list and string.format("[TurboGear] imported list '%s' (%d entries)", list.name, #(list.entries or {}))
            or ("[TurboGear] import failed: " .. tostring(err)))
    elseif arg == "export" then
        local path, err = require('userlists').export(rest)
        if path then
            require('userlists').open_config_folder()
            print("[TurboGear] exported to " .. path)
        else
            print("[TurboGear] export failed: " .. tostring(err))
        end
    elseif arg == "sharelist" or arg == "share" then
        local target = rest ~= "" and rest or cfg.Settings.bisSelectedList
        local ok, detail = require('userlists').share_list(target)
        print(ok and string.format("[TurboGear] shared list '%s' to peers", tostring(detail or "?"))
            or ("[TurboGear] share failed: " .. tostring(detail)))
    elseif arg == "pulllists" or arg == "pull" then
        local ok, err = require('userlists').request_lists_from_peer(rest)
        print(ok and "[TurboGear] requested lists from peer (imports arrive automatically)."
            or ("[TurboGear] pull failed: " .. tostring(err)))
    elseif arg == "exportspells" then
        local okExp, export_mod = pcall(require, 'export_spells')
        if okExp and export_mod and export_mod.export then
            export_mod.export(1)
        else
            local okCat, Catalog = pcall(require, 'research_catalog')
            if okCat and Catalog then
                local path, count, err = Catalog.export_missing({ copies = 1, source = "TurboGear" })
                print(path and string.format("[TurboGear] exported %d spells -> %s", count or 0, path)
                    or ("[TurboGear] spell export failed: " .. tostring(err or count)))
            else
                print("[TurboGear] research_catalog.lua not found in turbogear folder")
            end
        end
    elseif arg == "sync" then
        require('snapshot').invalidate()
        if not state.bg then
            request_local_bg_start("sync command")
            mq.cmd('/timed 5 /squelch /tgearbg sync')
            print("[TurboGear] sync: delegated to local bg responder")
        else
            Engine.publish(true, "full", { reason = "manual_sync" }); Engine.request_all(true)
            if cfg.Settings.autoLaunch then cfg.launch_peers() end
            if cfg.Settings.autoAddOnlinePeers ~= false then cfg.launch_all_online_peers() end
            print("[TurboGear] sync: full publish + requested peers")
        end
    elseif arg == "publish" or arg == "publishnow" or arg == "inventory" then
        require('snapshot').invalidate()
        local ok = false
        if not state.bg then
            request_local_bg_start("publish command")
            mq.cmd('/timed 5 /squelch /tgearbg publish')
            ok = true
        else
            ok = Engine.publish(true, "full", { skipLockouts = true, skipLiveStats = true, reason = "manual_publish" })
        end
        print(ok and "[TurboGear] publish: full local inventory sent" or "[TurboGear] publish: local inventory queued/cache updated")
    elseif arg == "spellsync" then
        -- Spell-book round trip. The Spells tab delegates here because the UI
        -- never owns the actor mailbox (static roles).
        if not state.bg then
            request_local_bg_start("spellsync command")
            mq.cmd('/timed 5 /squelch /tgearbg spellsync')
            print("[TurboGear] spellsync: delegated to local bg responder")
        else
            require('snapshot').gather({ force = true, depth = "lite", includeSpells = true })
            Engine.publish(true, "lite", { includeSpells = true, reason = "spellsync" })
            Engine.request_all(true, { includeSpells = true, depth = "lite" })
            print("[TurboGear] spellsync: published spell book + requested peer spell books")
        end
    elseif arg == "launch" or arg == "launchpeers" then
        if cfg.launch_peers() then
            print("[TurboGear] peer bg launch broadcast sent")
        end
    elseif arg == "launchall" or arg == "launchonline" then
        if cfg.launch_all_online_peers() then
            print("[TurboGear] all-online peer bg launch broadcast sent via " .. tostring((cfg.transport_profile() or {}).label or "transport"))
        end
    elseif arg == "stoppeers" then
        cfg.stop_peers()
        print("[TurboGear] peer stop broadcast sent")
    elseif arg == "debug" then
        Engine.debug = not Engine.debug
        diag.set_enabled(Engine.debug)
        print("[TurboGear] debug metrics " .. (Engine.debug and "ON" or "OFF") .. " (use /tgear diag to print)")
    elseif arg == "perfdiag" or arg == "profilediag" then
        start_perfdiag(args[2], args[3])
    elseif arg == "diagfile" or arg == "diagnosticfile" then
        local path, err = write_perfdiag_file(nil, "manual diagfile")
        print(path and ("[TurboGear] diag file written: " .. tostring(path))
            or ("[TurboGear] diag file write failed: " .. tostring(err)))
    elseif arg == "diag" or arg == "diagnostics" then
        local filter = (args[2] or ""):lower()
        if filter == "reset" or filter == "clear" then
            diag.reset()
            print("[TurboGear] diagnostics reset")
        else
            diag.print(rest)
        end
    elseif arg == "lootseen" or arg == "lootseenquiet" or arg == "loot" or arg == "linkedloot" then
        local quiet = arg == "lootseenquiet"
        -- lootseenquiet "Item Name" [itemId] [corpseId]
        -- Trailing integers: last is corpse id when two are present; alone a
        -- trailing int is treated as corpse id (TurboLoot always passes 0 item
        -- id + real corpse id).
        local tokens = {}
        for token in tostring(rest or ""):gmatch("%S+") do tokens[#tokens + 1] = token end
        local corpse_id, item_id = 0, 0
        if #tokens >= 2 and tonumber(tokens[#tokens]) and tonumber(tokens[#tokens - 1]) then
            corpse_id = tonumber(tokens[#tokens]) or 0
            item_id = tonumber(tokens[#tokens - 1]) or 0
            table.remove(tokens)
            table.remove(tokens)
        elseif #tokens >= 1 and tonumber(tokens[#tokens]) then
            corpse_id = tonumber(tokens[#tokens]) or 0
            table.remove(tokens)
        end
        local item_name = table.concat(tokens, " "):gsub('^%s*"', ""):gsub('"%s*$', "")
        item_name = tostring(item_name or ""):match("^%s*(.-)%s*$") or ""
        if item_name == "" then
            local n, id = parse_item_name_id(rest)
            item_name, item_id = n, id
        end
        if item_name == "" then
            if not quiet then print("[TurboGear] Usage: /tgear[bg] lootseen \"Item Name\" [itemId] [corpseId]") end
        elseif announcer.on_loot_seen(item_name, item_id, "", quiet and "turboloot" or "turbogear-command", corpse_id) then
            if not quiet then
                print(string.format("[TurboGear] structured loot seen: %s%s%s",
                    tostring(item_name),
                    item_id > 0 and (" (" .. tostring(item_id) .. ")") or "",
                    corpse_id > 0 and (" corpse=" .. tostring(corpse_id)) or ""))
            end
        end
    elseif arg == "goloot" then
        -- goloot <character> <corpse_id> <item_id> <item name...>
        -- Viewer UIs delegate here (/tgearbg goloot) because only the bg
        -- responder owns the actor mailbox; announcer routes appropriately.
        local character = args[2] or ""
        local corpse_id = tonumber(args[3]) or 0
        local item_id = tonumber(args[4]) or 0
        local item_name = table.concat(args, " ", 5)
        local ok, err = announcer.dispatch_go_loot(character, corpse_id, item_id, item_name)
        if not ok then
            print("[TurboGear] go-loot failed: " .. tostring(err or "?"))
        end
    elseif arg == "golootdone" then
        -- TurboLoot GO mode → bg: golootdone looted <corpseId> <item...>
        --                     or: golootdone failed <reason> <corpseId> <item...>
        --                     or: golootdone starting <corpseId> <item...>
        local status = tostring(args[2] or ""):lower()
        local detail, corpse_id, item_name
        if status == "failed" or status == "fail" then
            detail = tostring(args[3] or "failed")
            corpse_id = tonumber(args[4]) or 0
            item_name = table.concat(args, " ", 5)
            require('go_loot').on_mac_line("failed", detail, corpse_id, item_name)
        else
            corpse_id = tonumber(args[3]) or 0
            item_name = table.concat(args, " ", 4)
            require('go_loot').on_mac_line(status, item_name, corpse_id, item_name)
        end
    elseif arg == "golootnote" then
        -- golootnote <character> <note_token> <item name...>  (bg -> UI relay)
        announcer.note_go_status(table.concat(args, " ", 4), args[2] or "?", args[3] or "?")
    elseif arg == "announcetest" or arg == "atest" then
        if (args[2] or ""):lower() == "burst" then
            local names = {}
            for i = 3, #args do names[#names + 1] = args[i] end
            announcer.diagnose_burst(names)
        elseif (args[2] or ""):lower() == "group" then
            local item_name, item_id = parse_item_name_id(table.concat(args, " ", 3))
            announcer.diagnose_group(item_name, item_id)
        else
            local item_name, item_id = parse_item_name_id(rest)
            announcer.diagnose(item_name, item_id)
        end
    elseif arg == "mystats" or arg == "#mystats" then
        require('mystats').open()
    elseif arg == "mystatsprobe" or arg == "#mystatsprobe" then
        require('mystats').probe({ open = false })
    elseif arg == "invstats" or arg == "inventorystats" then
        require('inventory_stats').probe({ open = (args[2] or ""):lower() == "open" })
    elseif arg == "backend" or arg == "storebackend" then
        local mode = (args[2] or ""):lower()
        if mode == "auto" or mode == "file" or mode == "sqlite" then
            cfg.Settings.storeBackend = mode
            cfg.SaveSettings()
            print(string.format("[TurboGear] storeBackend = '%s'. Restart TurboGear (/lua run turbogear) to apply.", mode))
        else
            local active = "?"
            pcall(function() active = tostring((require('store').Store.cache_status() or {}).backend or "?") end)
            print(string.format("[TurboGear] storeBackend = '%s' (active this session: %s). Usage: /tgear backend auto|file|sqlite",
                tostring(cfg.Settings.storeBackend or "auto"), active))
        end
    elseif arg == "resetui" or arg == "safeui" then
        cfg.reset_ui_settings()
        print("[TurboGear] UI settings reset (bis tab, normal density, search cleared). Run /mqoverlay resume then /lua run turbogear")
    elseif arg == "status" then
        for _, line in ipairs(status_lines(12, true)) do print(line) end
    elseif arg == "stop" then
        print("[TurboGear] stopping"); state.run = false
    elseif arg == "hide" or arg == "close" then
        state.show = false
    elseif arg == "mini" or arg == "minimize" then
        state.show = false
    elseif arg == "toggle" then
        state.show = not state.show
    elseif arg == "show" or arg == "open" or arg == "compare" then
        state.show = true
    else
        state.show = true
    end
end

local bound_commands = {}
local function bind_command(cmd)
    pcall(function() mq.bind(cmd, tgear_command) end)
    bound_commands[#bound_commands + 1] = cmd
end

if state.bg then
    bind_command('/tgearbg')
    bind_command('/turbogearbg')
else
    bind_command('/tgear')
    bind_command('/turbogear')
end

local function unbind_all(stop_peers)
    if stop_peers and not state.bg and cfg.Settings.autoStopPeers == true then
        pcall(function() cfg.stop_peers() end)
    end
    pcall(function() require('inspect_dock').cancel() end)
    if not state.bg then
        pcall(function() mq.imgui.destroy('TurboGearUI') end)
    end
    for _, cmd in ipairs(bound_commands) do
        pcall(function() mq.unbind(cmd) end)
    end
    inventory_watch.unregister()
    announcer.unregister()
end

local peer_autostart = {
    last_at = 0,
    last_sig = "",
    sync_at = 0,
}
-- R5: viewer's delegated startup sync, gated on the bg readiness ack.
local startup_bg_sync = {
    pending = false,
    sent = false,
    deadline = 0,
}
-- Patcher shutdown hook: when the updater drops turbo_patch.lock in the shared
-- config dir, every box's Turbo self-stops so files can be replaced cleanly.
local patch_stop = { next_check = 0, stopping = false }
local function do_patch_stop()
    if patch_stop.stopping then return end
    patch_stop.stopping = true
    print("[TurboGear] patch lock detected - stopping Turbo so the updater can replace files.")
    for _, name in ipairs(CFG.patch_stop_scripts or {}) do
        if name ~= CFG.lua_name then pcall(function() mq.cmd('/squelch /lua stop ' .. name) end) end
    end
    pcall(function() mq.cmd('/squelch /endmacro') end)
    state.run = false   -- stop this instance last
end
local announce_role_guard = {
    next_at = 0,
    passive = nil,
}

function refresh_local_guard_state()
    state.local_guard_scripts = guard.detect(mq, CFG)
    state.local_guard_role = guard.role(state, Engine.ok, state.local_guard_scripts)
    state.local_guard_summary = guard.script_summary(state.local_guard_scripts)
    state.local_guard_last_action = local_owner_guard.last_action
    state.local_guard_last_action_at = local_owner_guard.last_action_at
    return state.local_guard_scripts
end

function request_local_bg_start(reason)
    reason = tostring(reason or "start_bg")
    local scripts = refresh_local_guard_state()
    if scripts.bg == true then return true end
    -- R5: the marker (if any) belongs to the OLD bg; drop it so the viewer only
    -- trusts readiness once the freshly-started bg re-writes it.
    pcall(function() cfg.clear_bg_ready() end)
    local bg_name = tostring(CFG.bg_lua_name or 'turbogear_bg')
    mq.cmd('/squelch /lua run ' .. bg_name)
    local_owner_guard.last_action = 'started local bg responder: ' .. reason
    local_owner_guard.last_action_at = os.clock()
    local_owner_guard.next_at = os.clock() + 5.0
    state.local_guard_last_action = local_owner_guard.last_action
    state.local_guard_last_action_at = local_owner_guard.last_action_at
    return true
end

-- Announce roles are static per process: the UI always coordinates announces;
-- a bg responder goes announce-passive only while a main UI runs on the same
-- box (so one box never announces twice).
local function refresh_announce_role(force)
    local scripts = state.local_guard_scripts or refresh_local_guard_state()
    local should_passive = guard.announce_passive(state.bg == true, scripts)
    if force or announce_role_guard.passive ~= should_passive then
        announcer.set_passive(should_passive)
        announce_role_guard.passive = should_passive
    end
    return should_passive
end

local function group_roster_sig()
    local names = {}
    pcall(function()
        local group = mq.TLO.Group
        local n = tonumber(group and group.Members and group.Members()) or 0
        for i = 1, n do
            local member = group.Member(i)
            local name = member and member.Name and member.Name() or ""
            if name and name ~= "" then names[#names + 1] = tostring(name) end
        end
    end)
    table.sort(names)
    return table.concat(names, "|")
end

local function added_group_names(old_sig, new_sig)
    local old = {}
    for name in tostring(old_sig or ""):gmatch("[^|]+") do
        if name ~= "" then old[name] = true end
    end
    local added = {}
    for name in tostring(new_sig or ""):gmatch("[^|]+") do
        if name ~= "" and not old[name] then added[#added + 1] = name end
    end
    return added
end

local function tick_peer_autostart()
    if state.bg or cfg.Settings.autoLaunch ~= true then return end
    local now = os.clock()
    if peer_autostart.sync_at > 0 and now >= peer_autostart.sync_at then
        peer_autostart.sync_at = 0
        if Engine.ok then
            Engine.request_all(true)
        else
            -- Viewer UI: the local bg responder owns actor sync.
            mq.cmd('/squelch /tgearbg sync')
        end
    end
    local sig = group_roster_sig()
    if sig == "" then
        peer_autostart.last_sig = ""
        return
    end
    if sig == peer_autostart.last_sig then return end

    local added = added_group_names(peer_autostart.last_sig, sig)
    peer_autostart.last_sig = sig
    if #added == 0 then return end

    if cfg.soft_launch_peers(added) then
        peer_autostart.last_at = now
        peer_autostart.sync_at = now + (tonumber(CFG.peer_soft_sync_delay_s) or 3.0)
    end
end

local function run_loop(inspect_tick, peer_refresh)
    local next_engine_retry = os.clock() + 5.0
    while state.run do
        local frame_t0 = os.clock()
        if mq.doevents then mq.doevents() end
        -- Bg self-heal: if the actor mailbox was busy at start, keep retrying so
        -- the responder comes alive once the mailbox frees.
        if state.bg and not Engine.ok and os.clock() >= next_engine_retry then
            Engine.init()
            next_engine_retry = os.clock() + 5.0
        end
        Engine.heartbeat()
        tick_peer_autostart()
        if startup_bg_sync.pending then
            local age = cfg.bg_ready_age()
            local ready = age ~= nil and age <= (tonumber(CFG.bg_ready_ttl_s) or 90.0)
            if guard.should_request_bg_sync({ bg_ready = ready, now = os.clock(), deadline = startup_bg_sync.deadline }) then
                mq.cmd('/squelch /tgearbg sync')
                startup_bg_sync.pending = false
                startup_bg_sync.sent = true
            end
        end
        if os.clock() >= patch_stop.next_check then
            patch_stop.next_check = os.clock() + (tonumber(CFG.patch_lock_poll_s) or 1.0)
            if guard.should_patch_stop({ lock_present = cfg.patch_lock_present(), stopping = patch_stop.stopping }) then
                do_patch_stop()
            end
        end
        if os.clock() >= announce_role_guard.next_at then
            announce_role_guard.next_at = os.clock() + 1.0
            if state.bg then refresh_local_guard_state() end
            refresh_announce_role(false)
            -- The UI never receives actor snapshots; keep its Store fresh from
            -- the shared cache the bg responder writes (cheap file-attr check).
            if not state.bg and Store.reload_cache_if_changed then
                Store.reload_cache_if_changed(false)
            end
        end
        if not state.bg then peer_discovery.tick(Engine) end
        if peer_refresh and cfg.Settings.autoPeerRefresh == true and not (state.lean and state.lean()) then
            Engine.request_all(false)
        end
        -- Static roles: the UI's only guard duty is keeping the local bg
        -- responder alive. No handoff, no promotion.
        if not state.bg and os.clock() >= local_owner_guard.next_at then
            local_owner_guard.next_at = os.clock() + 5.0
            local scripts = refresh_local_guard_state()
            if scripts.bg ~= true then
                request_local_bg_start("bg responder missing")
            end
        end
        Store.tick()
        inventory_watch.tick()
        if announcer.is_passive() then
            -- UI owns [TG] emission while present, but the bg still advances the
            -- peer needs index. Direct catalogs persist to disk (dcat_*), so the
            -- UI driver's warm-up can load them instead of rebuilding from scratch.
            if CFG.needs_index_enabled ~= false and CFG.needs_index_build_peers == true then
                pcall(function()
                    require('needs_index').tick(
                        tonumber(CFG.needs_index_budget_bg_ms) or 25,
                        { allow_peers = true })
                end)
            end
        else
            announcer.tick()
        end
        -- Never let a go-loot tick error kill the bg/UI run loop (that left E3
        -- paused and the panel stuck on "sent"/"going" with no finish).
        local okGo, goErr = pcall(function() require('go_loot').tick() end)
        if not okGo then
            print(string.format("\ar[TurboGear]\ax go-loot tick error: %s", tostring(goErr)))
        end
        if inspect_tick then inspect_tick() end
        tick_perfdiag_capture()
        -- Per-frame non-render work gauge (P5): total time this loop pass spent
        -- doing work, excluding the yield below. Visible in perfdiag as
        -- loop.frame_work (last/avg/max) so additive sub-tick budgets can be
        -- checked against real numbers.
        diag.sample("loop.frame_work", (os.clock() - frame_t0) * 1000)
        mq.delay(announcer.loop_delay_ms())
    end
end

-- ===================== UNIFIED RUN ===================================== --
-- STATIC ROLES: only bg responders claim the actor mailbox. The visible UI is
-- always a viewer/announce-coordinator; heavy sync work stays out of the render
-- process. If the bg responder dies, the run loop restarts it (never promotes).
state.local_guard_scripts = guard.detect(mq, CFG)
if state.bg then
    state.engine_claim_disabled = false
    init_engine_with_retry()
else
    state.engine_claim_disabled = true
    if state.local_guard_scripts.bg ~= true then
        request_local_bg_start("ui startup")
    end
end
refresh_local_guard_state()
refresh_announce_role(true)
if not Engine.ok then
    if state.bg then
        print("[TurboGear] actor sync not registered yet - retrying in background; /tgearbg still works.")
    else
        print("[TurboGear] UI online in viewer mode; local bg responder owns actor sync.")
    end
end

local announce_ready = announcer.warm(state.bg)
do
    local ast = announcer.status()
    print(string.format("\at[TurboGear]\ax \ag%s online:\ax \aw%s\ax | \atrole=%s\ax | engine=%s | announce=%s | %s  \aw(/tgear show|stop|status)\ax",
        state.bg and "responder" or "UI", my_key(), tostring(state.local_guard_role or "?"), tostring(Engine.ok),
        cfg.SharedSettings.bisAnnounceEnabled ~= false and "ON" or "OFF",
        ast.index_label or (announce_ready and "ready" or "warming")))
    if state.bg and not announce_ready then
        print("\at[TurboGear]\ax \ayNOTICE:\ax announce catalog warming - linked loot uses bounded direct checks while /tgear status warms")
    end
end

local ui = nil
if not state.bg then
    ui = require('ui')
    pcall(function() mq.imgui.destroy('TurboGearUI') end)
    mq.imgui.init('TurboGearUI', ui.draw_ui)
end

if state.show then
    -- Interactive driver: wake peers and pull fresh data right away. All actor
    -- work is delegated to the local bg responder that owns sync.
    if cfg.Settings.autoLaunch then
        mq.delay(50)
        if cfg.launch_peers() then
            peer_autostart.last_at = os.clock()
            peer_autostart.last_sig = group_roster_sig()
        end
    end
    if cfg.Settings.autoAddOnlinePeers ~= false then
        cfg.launch_all_online_peers()
    end
    request_local_bg_start("startup sync")
    -- R5: gate the delegated sync on the bg readiness ack (deadline fallback)
    -- rather than a fixed /timed delay that may fire before the mailbox is live.
    startup_bg_sync.pending = true
    startup_bg_sync.deadline = os.clock() + (tonumber(CFG.bg_sync_ack_deadline_s) or 5.0)
elseif Engine.ok then
    -- Background responder: publish our own inventory once up front; the
    -- metadata keepalive keeps it visible. Inventory changes and requests publish fresh snapshots.
    Engine.publish(true, "full", { skipLockouts = true, skipLiveStats = true, reason = "startup_bg_full" })
end

run_loop(function()
    if state.show and ui then
        local inspect_dock = require('inspect_dock')
        if inspect_dock.enabled and inspect_dock.enabled() then
            inspect_dock.tick(ui.main_window_rect())
        end
    end
end, true)

unbind_all(not state.bg)
