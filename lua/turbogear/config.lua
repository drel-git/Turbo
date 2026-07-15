-- TurboGear/config.lua
-- Constants, per-character settings, broadcast presets, file paths, launch helpers.
-- Owns the single shared Settings table (mutated in place so every module that
-- requires this sees the same live values).

local mq = require('mq')
local ok_ffi, ffi = pcall(require, 'ffi')
if ok_ffi and ffi then
    pcall(ffi.cdef, [[
        typedef unsigned long DWORD;
        typedef int BOOL;
        typedef struct _FILETIME {
            DWORD dwLowDateTime;
            DWORD dwHighDateTime;
        } FILETIME;
        typedef struct _WIN32_FILE_ATTRIBUTE_DATA {
            DWORD dwFileAttributes;
            FILETIME ftCreationTime;
            FILETIME ftLastAccessTime;
            FILETIME ftLastWriteTime;
            DWORD nFileSizeHigh;
            DWORD nFileSizeLow;
        } WIN32_FILE_ATTRIBUTE_DATA;
        BOOL GetFileAttributesExA(const char* lpFileName, int fInfoLevelId, void* lpFileInformation);
    ]])
else
    ffi = nil
end

local M = {}
local shared_settings_signature = nil

-- ============================ CONFIG ===================================== --
M.CFG = {
    script_name  = 'TurboGear',    -- display/settings/cache name
    lua_name     = 'turbogear',     -- folder/module name used by /lua run and /lua stop
    bg_lua_name  = 'turbogear_bg',  -- wrapper responder name; leaves /lua run turbogear free for UI
    version      = '1.2.1',
    mailbox      = 'turbogear',     -- shared actor mailbox name across all boxes
    proto        = 1,              -- snapshot protocol version (guards mismatched boxes)
    frame_round  = 5.0,
    window_round = 6.0,
    max_bank     = 24,             -- RoF2 bank slots
    self_cache_lite_s = 8.0,       -- lite gather cache (heartbeat / bg / most tabs)
    self_cache_full_s = 5.0,       -- full gather cache (Stats / Focus / Suggest)
    save_every_s = 15.0,           -- debounce cache writes (UI open)
    age_sweep_interval_s = 1.0,    -- P3: throttle source online/stale/offline aging sweep (status is second-granular)
    cache_tmp_validate_s = 30.0,   -- P1 interim: re-validate the temp cache file at most this often (not every save)
    bg_sync_ack_deadline_s = 5.0,  -- R5: viewer waits this long for the bg readiness ack before syncing anyway
    bg_ready_ttl_s = 90.0,         -- R5: bg-ready marker is "fresh" if written within this window
    bg_ready_write_every_s = 20.0, -- R5: bg refreshes its readiness marker at most this often
    patch_lock_poll_s = 1.0,       -- how often to check for the patcher's turbo_patch.lock
    -- Scripts stopped (on this box) when the patch lock appears, so the updater
    -- can replace files cleanly. The shared config dir means every box sees the
    -- lock and stops its own Turbo. Stopping a non-running script is a harmless no-op.
    patch_stop_scripts = {
        "Turbo",
        "turbogear", "turbogear_bg", "turbogear_autostart",
        "TurboMobs", "turbomobs_logic", "TurboRolls",
        "ToggleTurboLoot", "ToggleMeleeDist",
        "turbo_bank_all", "turbo_collect_cash", "turbo_collect_dc", "turbo_reclaim_lotto",
    },
    save_every_bg_s = 30.0,        -- debounce bg cache writes; actors carry live updates without disk stalls
    save_every_heavy_ui_s = 120.0, -- avoid disk-pickle hitches while Inventory/TurboBiS are open
    save_every_minimized_s = 30.0, -- slower disk writes when minimized
    request_cooldown_s = 10.0,     -- min gap between background roster refresh requests
    publish_every_s = 12.0,        -- heartbeat while UI open (lite unless deep tab)
    publish_every_minimized_s = 30.0,
    publish_every_bg_s = 30.0,     -- bg responder heartbeat
    publish_every_lean_s = 60.0,   -- metadata heartbeat only in auto-lean mode
    publish_jitter_s = 2.0,
    peer_soft_sync_delay_s = 3.0,   -- wait for bg script to register before requesting snapshots
    all_online_autostart_cooldown_s = 5.0, -- short guard against multi-team launch storms
    bis_announce_cooldown_s = 1.8, -- duplicate suppression after chat + actor reports
    announce_snap_max_age_s = 60.0, -- chat uses cached context; candidate ownership is checked live
    announce_snap_max_age_lean_s = 60.0,
    announce_catalog_budget_ms = 5,
    announce_catalog_budget_lean_ms = 5,
    announce_catalog_budget_bg_ms = 5,   -- bg responder should not take large warm-up slices
    announce_catalog_steps_ui = 1,
    announce_catalog_steps_lean = 1,
    announce_catalog_steps_bg = 1,
    announce_catalog_steps_flush = 64,
    announce_flush_budget_ms = 800,
    announce_loop_delay_lean_ms = 50,
    announce_pending_budget_ms = 4,
    announce_pending_items_per_tick = 1,
    announce_pending_max = 128,
    announce_outbox_delay_ms = 75,
    announce_outbox_max = 64,
    announce_target_check_budget_ms = 4, -- fallback only while the needs index is warming/rebuilding
    announce_target_check_max_per_tick = 1,
    announce_target_wait_max_s = 8.0,
    announce_text_fallback_candidates = 8,
    announce_replay_ttl_s = 90,
    announce_replay_max = 24,
    announce_seen_ttl_s = 90,      -- fleet-wide dedupe: suppress re-announcing an item seen in any [TG] line this recently
    announce_item_cooldown_s = 30, -- LazBis-style same-item spam guard for linked-needs output
    announce_coordinator_beacon_s = 30, -- driver UI stamps shared settings this often while announce-active
    announce_coordinator_ttl_s = 90,    -- bg responders defer to the driver while its stamp is fresher than this
    announce_confirm_needers = true,    -- live-confirm cache-derived peer needers over actors before sending [TG]
    announce_confirm_wait_s = 2.0,      -- max hold on a grouped announce while confirm replies arrive (fail-open)
    announce_confirm_refresh_cooldown_s = 30.0, -- min gap between fresh-snapshot requests for a stale-confirmed peer
    needs_index_enabled = true,  -- linked announces use the prebuilt needs index in steady state
    needs_index_build_peers = true,
    needs_index_budget_ms = 4,     -- inverted needs-index rebuild budget per tick (UI)
    needs_index_budget_lean_ms = 2, -- minimized/lean should yield quickly while zoning/running
    needs_index_budget_bg_ms = 2,  -- bg responder builds only local needs and should yield quickly
    frame_work_budget_ms = 10,     -- P5: per-tick ceiling for background build work (catalog warm + needs index) on the UI
    frame_work_budget_lean_ms = 6, -- minimized/lean: keep frames snappy while moving/zoning
    frame_work_budget_bg_ms = 40,  -- bg responder can spend more; no render to protect
    delta_publish_enabled = true,  -- send changed-slot deltas immediately on inventory change
    delta_max_items = 24,          -- above this many changed slots, rely on the full publish instead
    inventory_watch_enabled = true,
    inventory_watch_debounce_s = 0.4,
    inventory_watch_publish_cooldown_s = 2.0,
    inventory_watch_bg_poll_s = 0.0,  -- disabled by default; dirty events handle normal loot/equip changes without periodic scan stalls
    bank_open_capture_delay_s = 1.0,  -- RoF2 exposes bank reliably only while BigBankWnd is open
}

-- ============================ FILE PATHS ================================= --
-- Paths derive from script_name so a rename only needs CFG.script_name changed.
local me = mq.TLO.Me.CleanName() or "char"
M.SettingsFile = string.format("%s/%s_%s.lua", mq.configDir, M.CFG.script_name, me)
M.CacheFile    = string.format("%s/%s_cache.lua", mq.configDir, M.CFG.script_name)
M.DbFile       = string.format("%s/%s_cache.db", mq.configDir, M.CFG.script_name)  -- Phase 3 SQLite backend
M.BgReadyFile  = string.format("%s/%s_bgready", mq.configDir, M.CFG.script_name)   -- R5 bg-responder readiness ack
M.PatchLockFile = string.format("%s/turbo_patch.lock", mq.configDir)              -- patcher writes this to stop Turbo before updating
M.SharedSettingsFile = string.format("%s/%s_shared.lua", mq.configDir, M.CFG.script_name)

-- One-time warm migration from the old TurboAugs files (so the broadcast method
-- and offline cache carry over on first TurboGear launch). Harmless once the new
-- files exist.
M.LegacySettingsFile = string.format("%s/TurboAugs_%s.lua", mq.configDir, me)
M.LegacyCacheFile    = string.format("%s/TurboAugs_cache.lua", mq.configDir)

-- ============================ SETTINGS (per character) =================== --
-- Broadcast transports. Templates receive a command without the leading
-- broadcast slash convention normalized away. Use {cmd}; target templates also
-- receive {name}. Legacy BROADCAST_PRESETS remains for older UI/settings.
M.TRANSPORT_PROFILES = {
    { key = "e3", label = "E3", all = "/e3bcaa /{cmd}", group = "/e3bcg /{cmd}", target = "/e3bct {name} /{cmd}" },
    { key = "eqbc", label = "EQBC", all = "/bca //{cmd}", group = "", target = "/bct {name} //{cmd}" },
    { key = "dannet", label = "DanNet", all = "/dgga /{cmd}", group = "/dgge /{cmd}", target = "/dex {name} /{cmd}" },
    { key = "dannet_alt", label = "DanNet Alt", all = "/dge /{cmd}", group = "/dgge /{cmd}", target = "" },
    { key = "custom", label = "Custom", all = "", group = "", target = "" },
}

M.BROADCAST_PRESETS = {
    { label = "E3 - All Online (/e3bcaa)", prefix = "/e3bcaa /" },
    { label = "E3 - Group (/e3bcg)", prefix = "/e3bcg /" },
    { label = "EQBC - All (/bca)", prefix = "/bca //" },
    { label = "DanNet - All (/dgga)", prefix = "/dgga /" },
    { label = "DanNet - Group (/dgge)", prefix = "/dgge /" },
    { label = "Custom", prefix = nil },
}

M.Settings = {
    broadcastIdx    = 1,
    broadcastCustom = "/e3bcaa /",
    transportProfile = "e3",
    transportCustomAll = "/e3bcaa /{cmd}",
    transportCustomGroup = "/e3bcg /{cmd}",
    transportCustomTarget = "/e3bct {name} /{cmd}",
    transportTestTarget = "",
    autoLaunch      = true,
    autoAddOnlinePeers = true,
    peerDiscoveryEnabled = true,
    peerDiscoveryProvider = "auto",
    peerDiscoveryIntervalSeconds = 10,
    autoCaptureBankOnOpen = true,
    autoStopPeers   = false,       -- explicit Stop Peers only; closing UI should not kill responders
    peerLaunchDelayDs = 20,        -- deciseconds between peer stop and bg start (/timed 20 = 2s)
    peerBroadcastGroupOnly = true, -- when grouped, use /e3bcg (excludes self) for peer fleet cmds
    headless        = false,       -- legacy setting; bg responder now uses turbogear_bg
    startMinimized  = false,
    performanceMode = "auto",      -- auto=lean when minimized/bg, rich when UI is open
    storeBackend    = "auto",      -- "auto" (default): SQLite when lsqlite3 is available (auto-installed via PackageMan), else file. Also "file" / "sqlite".
    autoPeerRefresh = false,        -- when false, open UI uses cached peers until Sync Now/startup
    syncRosterScopeAcrossTabs = false, -- opt-in: changing roster scope in one tab updates matching roster tabs
    hideOrnament    = true,
    augsViewMode    = "single",
    augsViewKey     = "__self__",
    emptyViewMode   = "single",
    emptyViewKey    = "__self__",
    emptyActionableOnly = true,
    storedViewMode  = "single",
    storedViewKey   = "__self__",
    storedLocFilter = "all",
    storedSortKey   = "scan",
    storedSortDesc  = false,
    mainTab         = "bis",
    gearTab         = "inventory",
    inspectTab      = "stats",
    upgradeTab      = "suggestions",
    bisListsTab     = "catalog",
    augsSubTab      = "equipped",
    compareKey1     = "__self__",
    compareKey2     = nil,
    compareMode     = "chars",
    compareListKey  = "",
    compareListKey2 = "",
    compareDiffOnly = true,
    statsSelectedStat = "shielding",
    liveStatsRosterScope = "online",
    liveStatsViewKey = "__self__",
    statsAugsOnly = true,
    statsViewMode = "character",
    statsSearchScope = "all",
    statsSourceScope = "character",
    statsSourceKey = "__self__",
    statsLoadoutList = "",
    statsAnalyzeMode = "list",
    statsAnalyzeCompareList = "",
    statsAnalyzeWornKey = "",
    statsSortKey = "value",
    statsSortDesc = true,
    statsLocEquipped = true,
    statsLocInstalled = true,
    statsLocLoose = true,
    statsLocBags = true,
    statsLocBank = true,
    statsShowAllRows = false,
    statsRowLimit = 300,
    focusSourceScope = "all",
    focusSourceKey = "__self__",
    focusLoadoutList = "",
    focusSortKey = "value",
    focusSortDesc = true,
    focusIncludeFocus = true,
    focusIncludeWorn = true,
    focusLocEquipped = true,
    focusLocInstalled = true,
    focusLocLoose = true,
    focusLocBags = true,
    focusLocBank = true,
    focusShowAllRows = false,
    focusRowLimit = 300,
    focusColKind = true,
    focusColValue = true,
    focusColLevel = true,
    focusColSpellType = true,
    focusColResist = true,
    setupFocusDisplayJump = false,
    staleSeconds    = 20,
    offlineSeconds  = 45,
    peerVisibleGraceSeconds = 180,
    bisSelectedList = "",
    bisCatalogList = "",
    bisCatalogGroup = "",
    bisCatalogLastByGroup = {},
    bisViewKey = "__all__",
    bisViewSelectedChars = {},
    bisRosterScope = "online",
    lockoutsViewKey = "__all__",
    lockoutsRosterScope = "online",
    inventoryViewKey = "__self__",
    inventoryViewMode = "table",
    inventoryScope = "single",
    inventoryLocationFilter = "all",
    inventorySearch = "",
    inventoryShowAugs = true,
    inventorySelectedSlotId = nil,
    inventorySelectedContainer = "",
    inventoryShowAllRows = false,
    inventoryRowLimit = 200,
    inventoryTableCompact = "auto",
    inventoryCompactAutoDefaulted = true,
    spellsRosterScope = "online",
    spellsViewKey = "__all__",
    spellsLevelFilter = "all",
    spellsHideNonResearch = false,
    spellsHideOwned = false,
    spellsExportCopies = 1,
    spellsAutoRefreshMinutes = 5,
    bisListMode = "catalog",
    bisShowMissingOnly = false,
    bisViewDensity = "compact",    -- compact=Regular | ultra=Compact (TurboBiS roster layout)
    bisCompactFullNames = false,   -- compact mode: wider columns + longer truncated names
    bisCompactRows = true,         -- legacy; migrated to bisViewDensity on load
    bisShowElsewhere = false,      -- opt-in: scan cache for missing BiS items owned by other characters
    bisHiddenLists = {},           -- list id -> true when hidden from TurboBiS tab bar
    bisShowUserLists = true,       -- show Custom Lists nav button on TurboBiS tab
    bisCollapsedCategories = {},
    suggestTargetKey = "__self__",
    suggestSlotId = 2,
    suggestSourceScope = "all",
    suggestLocationFilter = "all",
    suggestExcludeSameEquipped = true,
    suggestViewMode = "overview",
    suggestOverviewActionable = false,
    suggestCompareStat = "ac",
    suggestCompareStats = { "ac" },
    suggestComparePrimary = "ac",
    suggestSortKey = "upgrade",
    suggestSortDesc = true,
    suggestShowAllRows = false,
    suggestRowLimit = 200,
    suggestAugHostItem = "",
    suggestAugHostId = 0,
    suggestAugSocketIndex = 1,
    suggestAugSocketType = 0,
    suggestAugSlotId = 2,
    miniWindowPos = nil,           -- { x, y } last mini-icon position (persisted)
    inspectDockEnabled = false,    -- reposition native inspect beside TG (off: less window weirdness)
    globalSearch = "",
}

M.SharedSettings = {
    bisAnnounceEnabled = true,
    bisAnnounceIdx = 2,             -- Group (/g) by default
    bisAnnounceCustom = "/g",
    bisAnnounceDisabledLists = {},  -- list id -> true opts OUT of linked-needs announce
    announceUseActor = true,        -- broadcast LOOT_LINK to peers (reliable; chat remains fallback)
    ignoredChars = {},              -- normalized char name -> display name; muted/forgotten, hidden & not scanned (fleet-wide)
    characterSets = {},             -- id -> { name, members = { normalized char name -> display name } }
}

M.BIS_ANNOUNCE_PRESETS = {
    { label = "Echo (/echo)",       cmd = "/echo" },
    { label = "Group (/g)",         cmd = "/g"    },
    { label = "Raid (/rs)",         cmd = "/rs"   },
    { label = "Raid else Group",    cmd = "auto"  },
    { label = "Say (/say)",         cmd = "/say"  },
    { label = "Guild (/gu)",        cmd = "/gu"   },
    { label = "Custom",             cmd = nil     },
}

function M.bis_announce_command()
    local preset = M.BIS_ANNOUNCE_PRESETS[M.SharedSettings.bisAnnounceIdx or 2]
    local cmd = preset and preset.cmd
    if cmd == "auto" then
        return (mq.TLO.Raid.Members() or 0) > 0 and "/rs" or "/g"
    end
    if not cmd then cmd = M.SharedSettings.bisAnnounceCustom or "/g" end
    cmd = tostring(cmd or "/echo"):gsub("^%s+", ""):gsub("%s+$", "")
    if cmd == "" then cmd = "/echo" end
    if cmd:sub(1, 1) ~= "/" then cmd = "/" .. cmd end
    if cmd:lower() == "/s" then return "/say" end
    return cmd
end

local function file_signature(path)
    path = tostring(path or "")
    if path == "" then return "missing" end
    if ffi then
        local data = ffi.new("WIN32_FILE_ATTRIBUTE_DATA[1]")
        local ok, rc = pcall(function()
            return ffi.C.GetFileAttributesExA(path, 0, data)
        end)
        if ok and rc ~= 0 and data[0] then
            local d = data[0]
            return table.concat({
                tostring(tonumber(d.nFileSizeHigh) or 0),
                tostring(tonumber(d.nFileSizeLow) or 0),
                tostring(tonumber(d.ftLastWriteTime.dwHighDateTime) or 0),
                tostring(tonumber(d.ftLastWriteTime.dwLowDateTime) or 0),
            }, ":")
        end
    end
    local f = io.open(path, "rb")
    if not f then return "missing" end
    local size = f:seek("end") or 0
    f:close()
    return "size:" .. tostring(size)
end

function M.LoadSharedSettings(force)
    local sig = file_signature(M.SharedSettingsFile)
    if not force and shared_settings_signature ~= nil and sig == shared_settings_signature then
        return false, "unchanged"
    end
    local ok, t = pcall(dofile, M.SharedSettingsFile)
    if ok and type(t) == "table" then
        for k, v in pairs(t) do M.SharedSettings[k] = v end
        shared_settings_signature = sig
        return true, "loaded"
    end
    shared_settings_signature = sig
    return false, "unavailable"
end

function M.SaveSharedSettings()
    pcall(function() mq.pickle(M.SharedSettingsFile, M.SharedSettings) end)
    shared_settings_signature = file_signature(M.SharedSettingsFile)
end

function M.SharedSettingsStatus()
    return {
        file = M.SharedSettingsFile,
        signature = shared_settings_signature,
    }
end

local function legacy_transport_key_from_idx()
    local idx = tonumber(M.Settings.broadcastIdx) or 1
    if idx == 3 then return "eqbc" end
    if idx == 4 or idx == 5 then return "dannet" end
    if idx == 6 then return "custom" end
    return "e3"
end

function M.sanitize_ui_settings()
    local raw_main = tostring(M.Settings.mainTab or "")
    if raw_main == "inventory" then
        M.Settings.mainTab = "gear"
        M.Settings.gearTab = "inventory"
    elseif raw_main == "augs" then
        M.Settings.mainTab = "gear"
        local aug_tab = tostring(M.Settings.augsSubTab or "equipped")
        M.Settings.gearTab = (aug_tab == "empty" and "empty") or (aug_tab == "stored" and "stored") or "worn"
    elseif raw_main == "compare" then
        M.Settings.mainTab = "upgrade"
        M.Settings.upgradeTab = "compare"
    elseif raw_main == "stats" then
        M.Settings.mainTab = "inspect"
        M.Settings.inspectTab = "stats"
    elseif raw_main == "focus" then
        M.Settings.mainTab = "inspect"
        M.Settings.inspectTab = "focus"
    elseif raw_main == "suggestions" then
        M.Settings.mainTab = "upgrade"
        M.Settings.upgradeTab = "suggestions"
    end

    local valid_main = {
        gear = true, inspect = true, upgrade = true, bis = true,
        spells = true, lockouts = true, setup = true,
    }
    if not valid_main[tostring(M.Settings.mainTab or "")] then
        M.Settings.mainTab = "bis"
    end
    if M.Settings.mainTab == "gear" and tostring(M.Settings.gearTab or "") == "empty" then
        M.Settings.mainTab = "upgrade"
        M.Settings.upgradeTab = "empty"
        M.Settings.gearTab = "inventory"
    end
    local valid_gear = { inventory = true, worn = true, stored = true }
    if not valid_gear[tostring(M.Settings.gearTab or "")] then M.Settings.gearTab = "inventory" end
    local valid_inspect = { stats = true, focus = true, live = true }
    if not valid_inspect[tostring(M.Settings.inspectTab or "")] then M.Settings.inspectTab = "stats" end
    local valid_upgrade = { suggestions = true, compare = true, empty = true }
    if not valid_upgrade[tostring(M.Settings.upgradeTab or "")] then M.Settings.upgradeTab = "suggestions" end
    local valid_bis_lists = { catalog = true, my = true, edit = true }
    if not valid_bis_lists[tostring(M.Settings.bisListsTab or "")] then
        M.Settings.bisListsTab = tostring(M.Settings.bisListMode or "catalog") == "user" and "my" or "catalog"
    end

    local density = tostring(M.Settings.bisViewDensity or "compact")
    if density == "normal" then
        M.Settings.bisViewDensity = "compact"
    elseif density ~= "compact" and density ~= "ultra" then
        M.Settings.bisViewDensity = "compact"
    end

    local function valid_roster_scope(scope, allow_self)
        scope = tostring(scope or "")
        if scope:match("^set:[%w_%-]+$") then return true end
        if allow_self and scope == "self" then return true end
        return scope == "online" or scope == "group" or scope == "e3" or scope == "all"
    end

    local scope = tostring(M.Settings.bisRosterScope or "online")
    if not valid_roster_scope(scope, true) then
        M.Settings.bisRosterScope = "online"
    end
    if type(M.Settings.bisViewSelectedChars) ~= "table" then
        M.Settings.bisViewSelectedChars = {}
    end
    local lo_scope = tostring(M.Settings.lockoutsRosterScope or "online")
    if not valid_roster_scope(lo_scope, true) then
        M.Settings.lockoutsRosterScope = "online"
    end
    local live_scope = tostring(M.Settings.liveStatsRosterScope or "online")
    if not valid_roster_scope(live_scope, true) then
        M.Settings.liveStatsRosterScope = "online"
    end
    M.Settings.liveStatsViewKey = tostring(M.Settings.liveStatsViewKey or "__self__")
    if M.Settings.liveStatsViewKey == "" then M.Settings.liveStatsViewKey = "__self__" end
    local sp_scope = tostring(M.Settings.spellsRosterScope or "online")
    if not valid_roster_scope(sp_scope, true) then
        M.Settings.spellsRosterScope = "online"
    end
    local sp_view = tostring(M.Settings.spellsViewKey or "__all__")
    if sp_view == "" then M.Settings.spellsViewKey = "__all__" end
    local sp_lvl = tostring(M.Settings.spellsLevelFilter or "all")
    if sp_lvl ~= "all" and not tonumber(sp_lvl) then M.Settings.spellsLevelFilter = "all" end
    if M.Settings.spellsResearchOnly == nil then M.Settings.spellsResearchOnly = true end
    if M.Settings.spellsHideNonResearch == nil then M.Settings.spellsHideNonResearch = false end
    if M.Settings.spellsHideOwned == nil then M.Settings.spellsHideOwned = false end
    M.Settings.spellsExportCopies = math.max(1, math.floor(tonumber(M.Settings.spellsExportCopies) or 1))
    M.Settings.spellsAutoRefreshMinutes = math.max(1, math.min(60, math.floor(tonumber(M.Settings.spellsAutoRefreshMinutes) or 5)))
    local lo_view = tostring(M.Settings.lockoutsViewKey or "__all__")
    if lo_view == "" then M.Settings.lockoutsViewKey = "__all__" end
    M.Settings.inventoryViewKey = tostring(M.Settings.inventoryViewKey or "__self__")
    local inv_mode = tostring(M.Settings.inventoryViewMode or "table")
    if inv_mode ~= "table" and inv_mode ~= "bags" and inv_mode ~= "stock" and inv_mode ~= "transfers" then inv_mode = "table" end
    M.Settings.inventoryViewMode = inv_mode
    local inv_scope = tostring(M.Settings.inventoryScope or "single")
    if inv_scope ~= "single" and inv_scope ~= "online" and inv_scope ~= "group" and inv_scope ~= "e3" and inv_scope ~= "all" then
        inv_scope = "single"
    end
    M.Settings.inventoryScope = inv_scope
    local inv_loc = tostring(M.Settings.inventoryLocationFilter or "all")
    if inv_loc ~= "all" and inv_loc ~= "equipped" and inv_loc ~= "bags" and inv_loc ~= "bank" and inv_loc ~= "aug" then
        inv_loc = "all"
    end
    M.Settings.inventoryLocationFilter = inv_loc
    M.Settings.inventorySearch = tostring(M.Settings.inventorySearch or "")
    if #M.Settings.inventorySearch > 256 then M.Settings.inventorySearch = "" end
    if M.Settings.inventoryShowAugs == nil then M.Settings.inventoryShowAugs = true end
    local stored_sort = tostring(M.Settings.storedSortKey or "scan")
    if stored_sort ~= "scan" and stored_sort ~= "loc" and stored_sort ~= "where" and stored_sort ~= "name" then
        stored_sort = "scan"
    end
    M.Settings.storedSortKey = stored_sort
    M.Settings.storedSortDesc = M.Settings.storedSortDesc == true
    M.Settings.inventorySelectedSlotId = tonumber(M.Settings.inventorySelectedSlotId)
    M.Settings.inventorySelectedContainer = tostring(M.Settings.inventorySelectedContainer or "")
    if M.Settings.inventoryShowAllRows == nil then M.Settings.inventoryShowAllRows = false end
    M.Settings.inventoryRowLimit = math.max(100, math.min(200, math.floor(tonumber(M.Settings.inventoryRowLimit) or 200)))
    local inv_compact = tostring(M.Settings.inventoryTableCompact or "auto")
    if inv_compact ~= "auto" and inv_compact ~= "on" and inv_compact ~= "off" then inv_compact = "auto" end
    if M.Settings.inventoryCompactAutoDefaulted ~= true then
        inv_compact = "auto"
        M.Settings.inventoryCompactAutoDefaulted = true
    end
    M.Settings.inventoryTableCompact = inv_compact
    if M.Settings.lockoutsLockedOnly == nil then M.Settings.lockoutsLockedOnly = false end
    if M.Settings.lockoutsCompact == nil then M.Settings.lockoutsCompact = false end
    if type(M.Settings.lockoutsCollapsedCategories) ~= "table" then
        M.Settings.lockoutsCollapsedCategories = {}
    end

    M.Settings.globalSearch = tostring(M.Settings.globalSearch or "")
    if #M.Settings.globalSearch > 256 then
        M.Settings.globalSearch = ""
    end

    if type(M.Settings.bisCollapsedCategories) ~= "table" then
        M.Settings.bisCollapsedCategories = {}
    end
    if type(M.Settings.bisHiddenLists) ~= "table" then
        M.Settings.bisHiddenLists = {}
    end
    M.Settings.bisShowElsewhere = M.Settings.bisShowElsewhere == true
    if M.Settings.bisShowUserLists == nil then
        M.Settings.bisShowUserLists = true
    end
    if type(M.SharedSettings.bisAnnounceDisabledLists) ~= "table" then
        M.SharedSettings.bisAnnounceDisabledLists = {}
    end
    if type(M.SharedSettings.ignoredChars) ~= "table" then
        M.SharedSettings.ignoredChars = {}
    end
    if type(M.SharedSettings.characterSets) ~= "table" then
        M.SharedSettings.characterSets = {}
    end
    if M.SharedSettings.announceUseActor == nil then
        M.SharedSettings.announceUseActor = true
    end
    local perf = tostring(M.Settings.performanceMode or "auto"):lower()
    if perf ~= "auto" and perf ~= "lean" and perf ~= "full" then perf = "auto" end
    M.Settings.performanceMode = perf
    local sb = tostring(M.Settings.storeBackend or "auto"):lower()
    if sb ~= "auto" and sb ~= "file" and sb ~= "sqlite" then sb = "auto" end
    M.Settings.storeBackend = sb
    M.Settings.autoPeerRefresh = M.Settings.autoPeerRefresh == true
    if tostring(M.Settings.transportProfile or "") == "" then
        M.Settings.transportProfile = legacy_transport_key_from_idx()
    end
    local profile_ok = false
    for _, profile in ipairs(M.TRANSPORT_PROFILES) do
        if profile.key == M.Settings.transportProfile then profile_ok = true; break end
    end
    if not profile_ok then M.Settings.transportProfile = legacy_transport_key_from_idx() end
    if M.Settings.transportProfile == "custom" then
        local legacy = tostring(M.Settings.broadcastCustom or "")
        if tostring(M.Settings.transportCustomAll or "") == "" and legacy ~= "" then
            M.Settings.transportCustomAll = legacy:find("{cmd}", 1, true) and legacy or (legacy .. "{cmd}")
        end
    end
    if tostring(M.Settings.transportCustomAll or "") == "" then M.Settings.transportCustomAll = "/e3bcaa /{cmd}" end
    if tostring(M.Settings.transportCustomGroup or "") == "" then M.Settings.transportCustomGroup = "/e3bcg /{cmd}" end
    if tostring(M.Settings.transportCustomTarget or "") == "" then M.Settings.transportCustomTarget = "/e3bct {name} /{cmd}" end
    M.Settings.transportTestTarget = tostring(M.Settings.transportTestTarget or "")
    M.Settings.headless = M.Settings.headless == true
    M.Settings.startMinimized = M.Settings.startMinimized == true
    M.Settings.autoAddOnlinePeers = M.Settings.autoAddOnlinePeers ~= false
    M.Settings.peerDiscoveryEnabled = M.Settings.peerDiscoveryEnabled ~= false
    M.Settings.autoCaptureBankOnOpen = M.Settings.autoCaptureBankOnOpen ~= false
    local discovery = tostring(M.Settings.peerDiscoveryProvider or "auto"):lower()
    if discovery ~= "auto" and discovery ~= "e3" and discovery ~= "off" then discovery = "auto" end
    M.Settings.peerDiscoveryProvider = discovery
    M.Settings.peerDiscoveryIntervalSeconds = math.max(5, math.min(60, math.floor(tonumber(M.Settings.peerDiscoveryIntervalSeconds) or 10)))
    M.Settings.autoStopPeers = M.Settings.autoStopPeers == true
    M.Settings.peerBroadcastGroupOnly = M.Settings.peerBroadcastGroupOnly ~= false
    M.Settings.peerLaunchDelayDs = math.max(5, math.min(100, math.floor(tonumber(M.Settings.peerLaunchDelayDs) or 20)))
    M.Settings.peerVisibleGraceSeconds = math.max(45, math.min(600, math.floor(tonumber(M.Settings.peerVisibleGraceSeconds) or 180)))

    if type(M.Settings.suggestCompareStats) ~= "table" or #M.Settings.suggestCompareStats == 0 then
        local legacy = tostring(M.Settings.suggestCompareStat or "ac")
        M.Settings.suggestCompareStats = { legacy ~= "" and legacy or "ac" }
    end
    if tostring(M.Settings.suggestComparePrimary or "") == "" then
        M.Settings.suggestComparePrimary = M.Settings.suggestCompareStats[1] or "ac"
    end
    M.Settings.suggestCompareStat = M.Settings.suggestComparePrimary
end

function M.apply_linked_roster_scope(scope, source)
    if M.Settings.syncRosterScopeAcrossTabs ~= true then return false end
    scope = tostring(scope or "")
    if scope ~= "online" and scope ~= "group" and scope ~= "e3" and scope ~= "all"
        and not scope:match("^set:[%w_%-]+$") then return false end
    source = tostring(source or "")

    if source ~= "bis" then M.Settings.bisRosterScope = scope end
    if source ~= "spells" then M.Settings.spellsRosterScope = scope end
    if source ~= "lockouts" then M.Settings.lockoutsRosterScope = scope end
    if source ~= "live_stats" then M.Settings.liveStatsRosterScope = scope end
    if source ~= "suggestions" then M.Settings.suggestSourceScope = scope end
    return true
end

function M.reset_ui_settings()
    M.Settings.mainTab = "bis"
    M.Settings.gearTab = "inventory"
    M.Settings.inspectTab = "stats"
    M.Settings.upgradeTab = "suggestions"
    M.Settings.bisListsTab = "catalog"
    M.Settings.globalSearch = ""
    M.Settings.bisViewDensity = "compact"
    M.Settings.bisCompactFullNames = false
    M.Settings.bisShowMissingOnly = false
    M.Settings.bisShowElsewhere = false
    M.Settings.bisRosterScope = "online"
    M.Settings.bisViewKey = "__all__"
    M.Settings.bisViewSelectedChars = {}
    M.Settings.lockoutsRosterScope = "online"
    M.Settings.lockoutsViewKey = "__all__"
    M.Settings.lockoutsLockedOnly = false
    M.Settings.lockoutsCompact = false
    M.Settings.lockoutsCollapsedCategories = {}
    M.Settings.inventoryViewKey = "__self__"
    M.Settings.inventoryViewMode = "table"
    M.Settings.inventoryScope = "single"
    M.Settings.inventoryLocationFilter = "all"
    M.Settings.inventorySearch = ""
    M.Settings.inventoryShowAugs = true
    M.Settings.inventorySelectedSlotId = nil
    M.Settings.inventorySelectedContainer = ""
    M.Settings.inventoryShowAllRows = false
    M.Settings.inventoryRowLimit = 200
    M.Settings.inventoryTableCompact = "auto"
    M.Settings.inventoryCompactAutoDefaulted = true
    M.Settings.autoPeerRefresh = false
    M.Settings.syncRosterScopeAcrossTabs = false
    M.Settings.bisListMode = "catalog"
    M.Settings.bisCollapsedCategories = {}
    M.sanitize_ui_settings()
    M.SaveSettings()
end

function M.LoadSettings()
    local ok, t = pcall(dofile, M.SettingsFile)
    if not (ok and type(t) == "table") then
        -- fall back to the pre-rename file once, if present
        ok, t = pcall(dofile, M.LegacySettingsFile)
    end
    if ok and type(t) == "table" then
        for k, v in pairs(t) do M.Settings[k] = v end
        if t.transportProfile == nil and t.broadcastIdx ~= nil then
            M.Settings.transportProfile = legacy_transport_key_from_idx()
        end
        if t.transportProfile == nil and tonumber(t.broadcastIdx) == 6 and tostring(t.broadcastCustom or "") ~= "" then
            local legacy = tostring(t.broadcastCustom or "")
            M.Settings.transportCustomAll = legacy:find("{cmd}", 1, true) and legacy or (legacy .. "{cmd}")
        end
    end
    M.sanitize_ui_settings()
end

function M.SaveSettings()
    pcall(function() mq.pickle(M.SettingsFile, M.Settings) end)
end

-- ============================ LAUNCH HELPERS ============================= --
local function trim(s)
    return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local last_all_online_launch_at = 0
local last_all_online_launch_status = ""

local function legacy_transport_key()
    local idx = tonumber(M.Settings.broadcastIdx) or 1
    if idx == 3 then return "eqbc" end
    if idx == 4 or idx == 5 then return "dannet" end
    if idx == 6 then return "custom" end
    return "e3"
end

local function profile_by_key(key)
    key = tostring(key or ""):lower()
    for _, profile in ipairs(M.TRANSPORT_PROFILES) do
        if profile.key == key then return profile end
    end
    return M.TRANSPORT_PROFILES[1]
end

function M.transport_profile()
    local key = tostring(M.Settings.transportProfile or "")
    if key == "" then
        key = legacy_transport_key()
        M.Settings.transportProfile = key
    end
    return profile_by_key(key)
end

function M.transport_template(scope)
    scope = tostring(scope or "all"):lower()
    local profile = M.transport_profile()
    if profile.key == "custom" then
        if scope == "group" then return trim(M.Settings.transportCustomGroup) end
        if scope == "target" then return trim(M.Settings.transportCustomTarget) end
        return trim(M.Settings.transportCustomAll)
    end
    return trim(profile[scope] or "")
end

function M.render_transport_template(template, cmd, name)
    template = trim(template)
    cmd = trim(cmd)
    name = trim(name)
    if template == "" or cmd == "" then return "" end
    if template:find("{name}", 1, true) and name == "" then return "" end
    local out = template:gsub("{cmd}", cmd):gsub("{name}", name)
    if not template:find("{cmd}", 1, true) then
        out = out .. cmd
    end
    return trim(out)
end

function M.transport_command(scope, cmd, name)
    return M.render_transport_template(M.transport_template(scope), cmd, name)
end

function M.transport_preview(scope, cmd, name)
    local built = M.transport_command(scope, cmd or ("echo " .. M.CFG.script_name .. " reachable"), name or "<name>")
    return built ~= "" and built or "(unsupported)"
end

function M.launch_prefix()
    local template = M.transport_template("all")
    local prefix = template:gsub("{cmd}", ""):gsub("{name}", "")
    return trim(prefix)
end

--- Prefix for peer fleet stop/start. Prefers /e3bcg when grouped so the UI box is not stopped.
function M.peer_scope()
    if M.Settings.peerBroadcastGroupOnly ~= false then
        local ok, grouped = pcall(function() return mq.TLO.Me.Grouped() end)
        if ok and grouped then
            if M.transport_template("group") ~= "" then return "group" end
        end
    end
    return "all"
end

function M.peer_prefix()
    local template = M.transport_template(M.peer_scope())
    return trim(template:gsub("{cmd}", ""):gsub("{name}", ""))
end

function M.start_bg_command()
    return M.transport_command(M.peer_scope(), "squelch /lua run " .. M.CFG.bg_lua_name)
end

function M.soft_start_bg_command()
    return M.transport_command(M.peer_scope(), "squelch /lua run turbogear_autostart")
end

function M.all_online_soft_start_bg_command()
    return M.transport_command("all", "squelch /lua run turbogear_autostart")
end

--- Tell one peer to run turbogear_autostart (avoids group-chat spam from /e3bcg).
function M.soft_start_bg_command_for(name)
    name = tostring(name or ""):match("^%s*(.-)%s*$") or ""
    if name == "" then return "" end
    return M.transport_command("target", "squelch /lua run turbogear_autostart", name)
end

--- Tell one peer to repair only the TurboGear bg responder. This leaves any
--- visible TurboGear UI alone, but restarts a stuck bg script if one exists.
function M.repair_bg_command_for(name)
    name = tostring(name or ""):match("^%s*(.-)%s*$") or ""
    if name == "" then return "" end
    return M.transport_command("target", "squelch /lua run turbogear_autostart repair", name)
end

function M.stop_peers_command()
    return M.transport_command(M.peer_scope(), "squelch /lua stop " .. M.CFG.bg_lua_name)
end

function M.stop_legacy_peers_command()
    return M.transport_command(M.peer_scope(), "squelch /lua stop " .. M.CFG.lua_name)
end

--- Human-readable summary for Setup UI.
function M.launch_command()
    local delay = math.floor(tonumber(M.Settings.peerLaunchDelayDs) or 20)
    return M.soft_start_bg_command() .. "  ->  /timed " .. tostring(delay) .. " sync request"
end

function M.stop_command()
    return M.stop_peers_command()
end

--- True when peer fleet cmds can run without stopping this UI instance.
function M.can_safely_launch_peers()
    if M.peer_scope() == "group" then return true end
    local ok, grouped = pcall(function() return mq.TLO.Me.Grouped() end)
    return ok and grouped and M.Settings.peerBroadcastGroupOnly ~= false
end

function M.launch_peers()
    if not M.can_safely_launch_peers() then
        print("[TurboGear] Group peer bg launch skipped: be in a group and use a Group broadcast (/e3bcg) so this UI box is not stopped. Then use Launch Group Peers or re-run TurboGear.")
        return false
    end
    mq.cmd(M.soft_start_bg_command())
    return true
end

function M.launch_all_online_peers(force)
    local now = os.clock()
    local cooldown = tonumber(M.CFG.all_online_autostart_cooldown_s) or 5.0
    if force ~= true and cooldown > 0 and (now - last_all_online_launch_at) < cooldown then
        last_all_online_launch_status = string.format("All-online autostart skipped; cooldown %.1fs remaining.",
            cooldown - (now - last_all_online_launch_at))
        return false, "cooldown"
    end
    local cmd = M.all_online_soft_start_bg_command()
    if cmd == "" then return false end
    mq.cmd(cmd)
    last_all_online_launch_at = now
    last_all_online_launch_status = "All-online autostart sent."
    return true
end

function M.last_all_online_launch_status()
    return last_all_online_launch_status
end

function M.soft_launch_peers(target_names)
    if not M.can_safely_launch_peers() then return false end
    target_names = type(target_names) == "table" and target_names or nil
    if not target_names or #target_names == 0 then
        mq.cmd(M.soft_start_bg_command())
        return true
    end
    local me = ""
    pcall(function() me = mq.TLO.Me.CleanName() or "" end)
    me = me:lower()
    local sent = 0
    for _, name in ipairs(target_names) do
        local clean = tostring(name or ""):match("^%s*(.-)%s*$") or ""
        if clean ~= "" and clean:lower() ~= me then
            local cmd = M.soft_start_bg_command_for(clean)
            if cmd ~= "" then
                mq.cmd(cmd)
                sent = sent + 1
            end
        end
    end
    return sent > 0
end

function M.stop_peers()
    mq.cmd(M.stop_peers_command())
end

--- One-click defaults for reliable BiS linked-needs announcing.
function M.apply_bis_announcing_defaults()
    M.Settings.autoLaunch = true
    M.Settings.autoStopPeers = false
    M.Settings.peerBroadcastGroupOnly = true
    M.SharedSettings.bisAnnounceEnabled = true
    M.SharedSettings.announceUseActor = true
    M.SharedSettings.bisAnnounceIdx = 2
    M.SaveSettings()
    M.SaveSharedSettings()
end

-- R5: bg-responder readiness ack. The bg writes this marker (a unix time) once
-- its actor mailbox is registered and refreshes it on heartbeat; the viewer
-- reads its age to know when delegating a startup sync is safe, instead of
-- guessing with a fixed /timed delay.
function M.write_bg_ready()
    pcall(function()
        local f = io.open(M.BgReadyFile, "w")
        if f then f:write(tostring(os.time())); f:close() end
    end)
end

function M.clear_bg_ready()
    pcall(function() os.remove(M.BgReadyFile) end)
end

-- Age in seconds of the readiness marker, or nil if absent/unreadable.
-- True when the patcher's stop sentinel is present in the (shared) config dir.
function M.patch_lock_present()
    local f = io.open(M.PatchLockFile, "rb")
    if not f then return false end
    f:close()
    return true
end

function M.bg_ready_age()
    local f = io.open(M.BgReadyFile, "rb")
    if not f then return nil end
    local body = f:read("*a") or ""
    f:close()
    local t = tonumber((tostring(body):gsub("%s+", "")))
    if not t then return nil end
    return os.time() - t
end

return M
