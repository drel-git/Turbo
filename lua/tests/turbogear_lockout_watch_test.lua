-- Run from repo root:  luajit lua/tests/turbogear_lockout_watch_test.lua
-- Drives the engine's lockout watcher directly (M._tick_lockout_change) with a
-- fake lockouts module, and asserts what it publishes.
--
-- Why this exists: a peer could hold a lockout for many minutes before the
-- viewer showed it. The raw detector was right the whole time -- the delay was
-- downstream, in how the matched map was fetched and in a startup baseline that
-- adopted the truth without ever announcing it.
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;lua/tests/?.lua;' .. package.path

package.preload['actors'] = function() error("no actors in test") end
package.preload['mq'] = function()
    return {
        TLO = {
            Me = { CleanName = function() return "Sketti" end },
            MacroQuest = { Server = function() return "Srv" end },
            EverQuest = { GameState = function() return "INGAME" end },
            Zone = { ShortName = function() return "z" end, Name = function() return "Zone" end },
        },
        cmd = function() end,
        pickle = function() end,
        configDir = require('helpers.tmpdir').dir(),
        delay = function() end,
    }
end
package.preload['config'] = function()
    return {
        CFG = {
            proto = 1, mailbox = "turbogear", request_cooldown_s = 10,
            publish_every_s = 12, publish_every_bg_s = 30, publish_every_lean_s = 60,
            publish_every_minimized_s = 30, keepalive_publish_s = 45,
            publish_jitter_s = 0, delta_publish_enabled = true, lockout_check_s = 60,
        },
        Settings = { offlineSeconds = 45, staleSeconds = 20, mainTab = "bis", autoPeerRefresh = false },
        SharedSettings = { ignoredChars = {}, announceUseActor = true },
        CacheFile = require('helpers.tmpdir').path("turbogear_lockout_watch_cache.lua"),
        LegacyCacheFile = require('helpers.tmpdir').path("turbogear_lockout_watch_legacy.lua"),
        SaveSharedSettings = function() end,
        LoadSharedSettings = function() end,
    }
end
package.preload['state'] = function()
    return { bg = true, show = false, engine_claim_disabled = true, lean = function() return false end }
end
local snap_stub = { gather_calls = 0 }
package.preload['snapshot'] = function()
    local s = {}
    local stamp = 0
    local authority = {
        name = "Sketti", server = "Srv", class = "Rog", level = 70,
        depth = "lite",
        equipped = { { id = 1, name = "Sword", location = "Equipped", where = "Primary", slotid = 13, qty = 1 } },
        bags = { { id = 2, name = "BagItem", location = "Bags", where = "Inventory Bag 1", slotid = 23, qty = 1 } },
        bank = { { id = 3, name = "BankItem", location = "Bank", where = "Bank 1", slotid = 2000, qty = 1 } },
        bankValid = true, bankLive = false, bankPreserved = true, bankCapturedAt = 111,
        inventoryUpdated = 50, updated = 1, seq = 10, spells_sig = "SPELLS",
    }
    function s.gather()
        snap_stub.gather_calls = snap_stub.gather_calls + 1
        error("lockout watcher must not gather inventory")
    end
    function s.stamp_for_publish(snap)
        stamp = stamp + 1
        snap.seq = 1000 + stamp
        snap.updated = 99
        return snap
    end
    function s.prepare_metadata_publish(updates, opts)
        updates = type(updates) == "table" and updates or {}
        local out = {}
        for k, v in pairs(authority) do out[k] = v end
        if updates.lockouts ~= nil then out.lockouts = updates.lockouts end
        s.stamp_for_publish(out)
        return out
    end
    function s.depth_for_settings() return "lite" end
    function s.lite_signature() return "SIG" end
    function s.cached() return authority end
    function s.invalidate() end
    function s.bank_window_open() return false end
    return s
end

-- The fake responder-side lockouts module. `raw` is what DynamicZone reports
-- right now; `matched` is what a real gather would produce from it; `cached` is
-- the stale map a non-bypassing gather would hand back.
local lo = {
    raw = "",
    matched = {},
    cached = {},
    built = nil,          -- raw state the cached map was built from
    gathers = {},         -- one entry per gather_local call, recording its opts
}
package.preload['lockouts'] = function()
    local m = {}
    function m.timer_signature() return lo.raw end
    function m.last_built_signature() return lo.built end
    function m.gather_local(arg)
        local bypass = arg == true or (type(arg) == "table" and arg.bypass_cache == true)
        local window = arg == true or (type(arg) == "table" and arg.allow_window_fallback ~= false)
        lo.gathers[#lo.gathers + 1] = { bypass = bypass, window = window }
        if not bypass then return lo.cached end
        lo.built = lo.raw
        return lo.matched
    end
    return m
end

-- DoN missions are tasks, so nothing about them reaches DynamicZone and the raw
-- detector above is blind to them. The watcher checks a second source; this
-- stands in for it. "C0" is the digest of a box that knows nothing and holds
-- nothing, which is what a fresh process reports.
local don = { sig = "C0", refreshes = 0 }
package.preload['don_track'] = function()
    return {
        signature = function() return don.sig end,
        refresh_active_if_due = function() don.refreshes = don.refreshes + 1; return true end,
    }
end

local engine_mod = require('engine')
local Engine = engine_mod.Engine
local watch = engine_mod._lockout_watch
local tick = engine_mod._tick_lockout_change

local pass, fail = 0, 0
local function check(cond, m) if cond then pass = pass + 1 else fail = fail + 1; print("  FAIL: " .. tostring(m)) end end

-- Capture publishes instead of sending them. The real one returns true only
-- when a snapshot actually went out.
local published = nil
local publish_count = 0
local publish_result = true
Engine.publish_snapshot = function(snap, opts)
    publish_count = publish_count + 1
    published = { snap = snap, opts = opts }
    return publish_result
end

local function locked_set(map)
    local names = {}
    for cat, entries in pairs(map or {}) do
        if type(entries) == "table" and cat ~= "DoNState" then
            for name, rec in pairs(entries) do
                if type(rec) == "table" and rec.found == true then names[#names + 1] = name end
            end
        end
    end
    table.sort(names)
    return table.concat(names, ",")
end

local function map_of(...)
    local out = { Custom = {} }
    for _, name in ipairs({ ... }) do
        out.Custom[name] = { found = true, expiresAt = 1800000000 }
    end
    return out
end

--- Put the watcher in a known state: no baseline, interval elapsed.
local function reset(opts)
    opts = opts or {}
    watch.sig, watch.next_at = opts.sig, 0
    watch.don = opts.don_base
    don.sig, don.refreshes = opts.don or "C0", 0
    lo.raw = opts.raw or ""
    lo.matched = opts.matched or {}
    lo.cached = opts.cached or {}
    lo.built = opts.built
    lo.gathers = {}
    published, publish_count = nil, 0
    publish_result = opts.publish_result ~= false
    snap_stub.gather_calls = 0
end

-- ---- A. a detected change must not publish a stale matched map -------------
-- The failure this covers: the detector correctly saw a third timer, but the
-- publish took gather_local's cached map, which on a responder is up to 300s
-- old. The snapshot went out confidently missing the very lockout that
-- triggered it.
do
    reset({
        sig = "Nagafen|:1",                              -- baseline already set
        raw = "Nagafen|:1\31Txevu|:1\31Venril|:1",       -- Txevu just appeared
        matched = map_of("Nagafen's Lair [Group]", "Txevu", "Venril Sathir"),
        cached = map_of("Nagafen's Lair [Group]", "Venril Sathir"),  -- the stale answer
    })
    tick()

    check(publish_count == 1, "a raw change publishes exactly once")
    check(published and locked_set(published.snap.lockouts) ==
        "Nagafen's Lair [Group],Txevu,Venril Sathir",
        "the published map includes the newly detected lockout, got " ..
        tostring(published and locked_set(published.snap.lockouts)))
    check(#lo.gathers == 1 and lo.gathers[1].bypass == true,
        "the gather bypassed the cache rather than waiting out its TTL")
    check(published and published.opts and published.opts.reason == "lockout_change",
        "publish is tagged with its reason")
    check(published and published.snap.seq == 1001,
        "a lockout-only publish gets a new seq so the viewer will accept it, got " ..
        tostring(published and published.snap.seq))
    check(snap_stub.gather_calls == 0, "lockout-only publish does not gather inventory")
    check(published and published.snap.inventoryUpdated == 50,
        "lockout-only publish keeps the original inventoryUpdated")
    check(published and published.snap.bankPreserved == true
        and published.snap.bankLive == false
        and published.snap.bankCapturedAt == 111,
        "lockout-only publish carries preserved bank provenance")
end

-- ---- C. bypassing the cache must not license opening the window ------------
-- Separate permissions. A background box may need a fresh structured read and
-- must still never flash the Expedition window at the player.
do
    reset({
        sig = "Nagafen|:1",
        raw = "Nagafen|:1\31Txevu|:1",
        matched = map_of("Nagafen's Lair [Group]", "Txevu"),
    })
    tick()
    check(#lo.gathers == 1 and lo.gathers[1].window == false,
        "a forced refresh explicitly refuses the window fallback")
end

-- ---- D. startup baseline reconciliation ------------------------------------
-- The old rule was "first sample is the baseline, say nothing". If the startup
-- publish went out before DynamicZone was populated, the watcher would then see
-- the correct timers, quietly adopt them, and leave the viewer stale until some
-- unrelated publish happened to carry the map.
do
    reset({
        sig = nil,                                   -- fresh process
        raw = "Nagafen|:1\31Venril|:1",              -- what we actually hold
        built = "Nagafen|:1",                        -- what the published map was built from
        matched = map_of("Nagafen's Lair [Group]", "Venril Sathir"),
        cached = map_of("Nagafen's Lair [Group]"),
    })
    tick()
    check(publish_count == 1, "a first pass that disagrees with the published state corrects it")
    check(published and locked_set(published.snap.lockouts) ==
        "Nagafen's Lair [Group],Venril Sathir", "and the correction carries the full set")
    check(watch.sig == lo.raw, "the baseline is adopted after correcting")
end

do
    reset({
        sig = nil,
        raw = "Nagafen|:1",
        built = "Nagafen|:1",                        -- already published this exact state
        matched = map_of("Nagafen's Lair [Group]"),
    })
    tick()
    check(publish_count == 0, "a first pass that agrees publishes nothing")
    check(#lo.gathers == 0, "and does not even pay for a matched gather")
    check(watch.sig == "Nagafen|:1", "but does take the baseline")
end

do
    -- Nothing gathered yet and no timers held: there is nothing to correct.
    reset({ sig = nil, raw = "", built = nil })
    tick()
    check(publish_count == 0, "a cold process holding no lockouts stays quiet")
    check(watch.sig == "", "and baselines at empty")
end

do
    -- Nothing gathered yet but timers are held. We cannot show that the viewer
    -- already knows, so say it.
    reset({ sig = nil, raw = "Txevu|:1", built = nil, matched = map_of("Txevu") })
    tick()
    check(publish_count == 1, "a cold process holding a lockout announces it")
end

-- ---- E. a countdown must not publish every interval ------------------------
-- timer_signature is absolute-expiry and minute-bucketed, so the same lockout
-- ticking down produces the same digest. If it did not, an idle box would
-- publish a snapshot every 60 seconds for the life of every lockout.
do
    reset({
        sig = "Nagafen|:30000000",
        raw = "Nagafen|:30000000",
        matched = map_of("Nagafen's Lair [Group]"),
    })
    tick()
    check(publish_count == 0, "an unchanged timer set publishes nothing")
    check(#lo.gathers == 0, "and skips the matched gather entirely")
end

-- ---- the interval is respected --------------------------------------------
do
    reset({ sig = "a", raw = "b", matched = map_of("Txevu") })
    tick()
    check(publish_count == 1, "first tick acts on the change")
    lo.raw = "c"
    tick()
    check(publish_count == 1, "a second tick inside the interval does no work")
end

-- ---- a change is only baselined once it has actually gone out --------------
-- Committing the new signature before publishing meant a snapshot taken
-- mid-zone, or any transient failure, silently adopted the change as the
-- baseline and never announced it -- the same shape of bug as the old startup
-- race, just rarer.
do
    reset({
        sig = "Nagafen|:1",
        raw = "Nagafen|:1\31Txevu|:1",
        matched = map_of("Nagafen's Lair [Group]", "Txevu"),
        publish_result = false,
    })
    tick()
    check(publish_count == 1, "the publish was attempted")
    check(watch.sig == "Nagafen|:1", "a failed publish does not become the new baseline")

    -- Next interval, still changed, and this time it goes out.
    watch.next_at = 0
    publish_result = true
    tick()
    check(publish_count == 2, "the change is retried on the following interval")
    check(watch.sig == "Nagafen|:1\31Txevu|:1", "and is baselined once it really goes out")
end

do
    -- A gather that fails outright is the same story.
    reset({ sig = "Nagafen|:1", raw = "Nagafen|:1\31Txevu|:1" })
    lo.matched = nil          -- gather_local returns a non-table
    tick()
    check(publish_count == 0, "a failed gather publishes nothing")
    check(watch.sig == "Nagafen|:1", "and leaves the baseline alone so the next interval retries")
end

-- ---- an unreadable source is not a change ----------------------------------
-- Otherwise a box that lost the ability to read would publish an all-open map
-- and clear every peer's padlocks.
do
    reset({ sig = "Nagafen|:1", raw = nil, matched = {} })
    lo.raw = nil
    tick()
    check(publish_count == 0, "an unreadable TLO reports unknown, and unknown is not a change")
    check(watch.sig == "Nagafen|:1", "the last known signature is kept")
end

-- ---- DoN state moves on its own and must be watched separately -------------
-- Replay grants arrive by chat, a /tasktime sweep settles on its own schedule,
-- and a mission being accepted touches neither inventory nor DynamicZone. So
-- every trigger this watcher already had is blind to DoN, and without a second
-- check a peer's DoN state would ship only when something unrelated published.
do
    reset({
        sig = "Nagafen|:1", raw = "Nagafen|:1",       -- expedition timers unchanged
        don_base = "C0",
        don = "C1\31R|Blood of the Dragon:30000240",  -- a replay was granted
        matched = map_of("Nagafen's Lair [Group]"),
    })
    tick()
    check(publish_count == 1, "a DoN-only change publishes even though the timer set is identical")
    check(published and published.opts and published.opts.reason == "don_change",
        "a DoN-only publish is tagged don_change")
    check(snap_stub.gather_calls == 0, "DoN-only publish does not gather inventory")
    check(watch.don == don.sig, "and is baselined once it goes out")
    check(watch.sig == "Nagafen|:1", "the expedition baseline is untouched")
    check(don.refreshes == 0, "the watcher compares the DoN digest and does not walk the journal")
end

do
    reset({ sig = "Nagafen|:1", raw = "Nagafen|:1", don_base = "C1\31R|x:1", don = "C1\31R|x:1",
        matched = map_of("Nagafen's Lair [Group]") })
    tick()
    check(publish_count == 0, "unchanged DoN state publishes nothing")
    check(#lo.gathers == 0, "and pays for no gather")
end

do
    -- Same commit rule as the expedition side: a change that failed to go out
    -- is not a change we have handled.
    reset({
        sig = "Nagafen|:1", raw = "Nagafen|:1",
        don_base = "C0", don = "C1\31R|Blood of the Dragon:30000240",
        matched = map_of("Nagafen's Lair [Group]"),
        publish_result = false,
    })
    tick()
    check(watch.don == "C0", "a failed publish does not baseline the new DoN state")
    watch.next_at, publish_result = 0, true
    tick()
    check(publish_count == 2 and watch.don == don.sig, "the next interval retries and then baselines it")
end

do
    -- A fresh process that knows nothing has nothing to announce; one that
    -- already holds state does, because the startup publish skips lockouts
    -- entirely and the viewer has therefore never seen it.
    reset({ sig = "", raw = "", don_base = nil, don = "C0" })
    tick()
    check(publish_count == 0, "a cold process with no DoN state stays quiet")
    check(watch.don == "C0", "and baselines at nothing-known")

    reset({ sig = "", raw = "", don_base = nil, don = "C1\31R|Volkara's Bite:30008640",
        matched = map_of() })
    tick()
    check(publish_count == 1, "a cold process already holding a replay timer announces it")
end

do
    -- Unknown expedition state must not suppress a DoN change, and must not be
    -- mistaken for one either.
    reset({ sig = "Nagafen|:1", don_base = "C0", don = "C1\31R|x:1", matched = map_of("Txevu") })
    lo.raw = nil
    tick()
    check(publish_count == 1, "an unreadable DynamicZone does not block a DoN change")
    check(watch.sig == "Nagafen|:1", "and the unreadable source does not overwrite the expedition baseline")
end

print(string.format('lockout watch: %d passed, %d failed', pass, fail))
if fail > 0 then os.exit(1) end
