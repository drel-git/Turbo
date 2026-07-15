-- Run from repo root:  luajit lua/tests/turbogear_engine_dispatch_test.lua
-- Drives engine.on_message (exposed as M._on_message) with fake actor messages
-- and asserts Store side effects + protocol guards. Also verifies that a failing
-- actor send is recorded via diagnostics (the R4 observability change) instead of
-- being silently swallowed. actors/lockouts/etc are absent so require() fails
-- gracefully; mq/config/state/snapshot are stubbed.
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

-- 'actors' must be unavailable so Engine stays cache-only (Engine.ok=false).
package.preload['actors'] = function() error("no actors in test") end

package.preload['mq'] = function()
    return {
        TLO = {
            Me = { CleanName = function() return "Me" end },
            MacroQuest = { Server = function() return "Srv" end },
            EverQuest = { GameState = function() return "INGAME" end },
            Zone = { ShortName = function() return "z" end, Name = function() return "Zone" end },
        },
        cmd = function() end,
        pickle = function() end,
        configDir = "/tmp",
        delay = function() end,
    }
end
package.preload['config'] = function()
    return {
        CFG = {
            proto = 1, mailbox = "turbogear", request_cooldown_s = 10,
            publish_every_s = 12, publish_every_bg_s = 30, publish_every_lean_s = 60,
            publish_every_minimized_s = 30, keepalive_publish_s = 45,
            publish_jitter_s = 0, delta_publish_enabled = true,
        },
        Settings = { offlineSeconds = 45, staleSeconds = 20, mainTab = "bis", autoPeerRefresh = false },
        SharedSettings = { ignoredChars = {}, announceUseActor = true },
        CacheFile = "/tmp/turbogear_engine_test_cache.lua",
        LegacyCacheFile = "/tmp/turbogear_engine_test_legacy.lua",
        SaveSharedSettings = function() end,
        LoadSharedSettings = function() end,
    }
end
package.preload['state'] = function()
    return { bg = false, show = true, engine_claim_disabled = true, lean = function() return false end }
end
package.preload['snapshot'] = function()
    local s = {}
    function s.gather() return { name = "Me", server = "Srv", class = "War", level = 70,
        depth = "full", equipped = {}, bags = {}, bank = {}, updated = 1 } end
    function s.depth_for_settings() return "lite" end
    function s.lite_signature() return "SIG" end
    function s.cached() return nil end
    function s.invalidate() end
    function s.bank_window_open() return false end
    return s
end

local engine_mod = require('engine')
local Engine = engine_mod.Engine
local Store = require('store').Store
local diag = require('diagnostics')
local dispatch = engine_mod._on_message
assert(type(dispatch) == "function", "engine exposes _on_message test seam")

-- helper: wrap a table as an actor message (called as message() in on_message)
local function msg(t) return function() return t end end

local pass, fail = 0, 0
local function check(cond, m) if cond then pass = pass + 1 else fail = fail + 1; print("  FAIL: " .. tostring(m)) end end

-- ---- 1. protocol guard: wrong proto is dropped, rx_bad increments ----------
do
    local before = Engine.stats.rx_bad
    dispatch(msg({ type = "snapshot", proto = 999, snap = { name = "X", server = "Srv" } }))
    check(Engine.stats.rx_bad == before + 1, "wrong-proto message counted as rx_bad")
    check(Store.get("Srv_X") == nil, "wrong-proto snapshot not stored")
end

-- ---- 2. non-table payload is dropped safely --------------------------------
do
    local before = Engine.stats.rx_bad
    dispatch(msg(42))
    check(Engine.stats.rx_bad == before + 1, "non-table message counted as rx_bad")
end

-- ---- 3. SNAPSHOT ingests into the Store ------------------------------------
do
    local before = Engine.stats.rx_snap
    dispatch(msg({ type = "snapshot", proto = 1, kind = "client", snap = {
        name = "Peer", server = "Srv", class = "Clr", level = 65,
        depth = "full", equipped = { { id = 7, name = "Rod", location = "Equipped", where = "Equipped", slotid = 13, slotname = "Primary" } },
        bags = {}, bank = {}, updated = 100,
    } }))
    check(Engine.stats.rx_snap == before + 1, "snapshot counted as rx_snap")
    local p = Store.get("Srv_Peer")
    check(p ~= nil and p.class == "Clr", "snapshot stored peer with class")
    check(p and p.equipped and p.equipped[1] and p.equipped[1].id == 7, "snapshot equipped item stored")
end

-- ---- 4. HEARTBEAT updates presence without inventory -----------------------
do
    dispatch(msg({ type = "heartbeat", proto = 1, kind = "client", snap = {
        name = "Peer", server = "Srv", class = "Clr", level = 66, depth = "meta", updated = 200,
    } }))
    local p = Store.get("Srv_Peer")
    check(p and p.level == 66, "heartbeat updated level")
    check(p and #p.equipped == 1, "heartbeat preserved existing inventory")
end

-- ---- 5. SNAPSHOT_DELTA applies onto the existing baseline -------------------
do
    dispatch(msg({ type = "snapshot_delta", proto = 1, kind = "client", delta = {
        name = "Peer", server = "Srv", updated = 300, inventoryUpdated = 300,
        changed = { equipped = { { id = 9, name = "Staff", location = "Equipped", where = "Equipped", slotid = 13, slotname = "Primary" } } },
    } }))
    local p = Store.get("Srv_Peer")
    check(p and p.equipped[1] and p.equipped[1].id == 9, "delta swapped item in-place (id 9)")
end

-- ---- 6. REQUEST is handled without error (viewer short-circuits publish) ----
do
    local before = Engine.stats.rx_req
    local ok = pcall(dispatch, msg({ type = "request", proto = 1, force = false, depth = "lite" }))
    check(ok, "request dispatch did not error")
    check(Engine.stats.rx_req == before + 1, "request counted as rx_req")
end

-- ---- 7. R4: a failing actor send is RECORDED, not silently swallowed --------
do
    Engine.ok = true
    Engine.last_publish_sig = nil
    Engine.mailbox = { send = function() error("simulated bus failure") end }
    local before = (diag.errors["engine.send.snapshot"] and diag.errors["engine.send.snapshot"].count) or 0
    -- forced full publish -> gathers stub snap -> send_mail -> mailbox errors
    Engine.publish(true, "full", { reason = "test" })
    local rec = diag.errors["engine.send.snapshot"]
    check(rec ~= nil and rec.count == before + 1, "failed snapshot send recorded under engine.send.snapshot")
    check(rec and rec.last:find("simulated bus failure"), "recorded error keeps the failure detail")
    Engine.ok = false
    Engine.mailbox = nil
end

print(string.format("engine dispatch: %d passed, %d failed", pass, fail))
os.exit(fail == 0 and 0 or 1)
