-- Run from repo root: luajit lua/tests/turbogear_generated_catalog_drift_test.lua
-- The shipped direct artifact must match canonical catalog content, not only shape.
package.path = "lua/turbogear/?.lua;lua/turbogear/?/init.lua;" .. package.path

package.preload["mq"] = function()
    local empty = setmetatable({}, { __call = function() return nil end, __index = function() return nil end })
    return {
        TLO = {
            Me = {
                CleanName = function() return "DriftTest" end,
                Class = { Name = function() return "Warrior" end },
            },
            MacroQuest = { Server = function() return "Test" end },
            EverQuest = { GameState = function() return "INGAME" end },
            FindItem = function() return empty end,
            FindItemBank = function() return empty end,
            Cursor = empty,
        },
        configDir = ".",
        pickle = function() end,
    }
end
package.preload["config"] = function()
    return {
        CFG = {},
        Settings = {},
        SharedSettings = { bisAnnounceDisabledLists = {} },
        SaveSettings = function() end,
        SaveSharedSettings = function() end,
        known_class = function(c) return c end,
        canonical_class = function(c) return c end,
    }
end
package.preload["diagnostics"] = function()
    return {
        time = function(_, fn) return fn() end,
        count = function() end,
        event = function() end,
        sample = function() end,
        context = function() end,
    }
end

local catalog = require("bis_catalog")
catalog.warm_catalog("test-startup")
catalog._reset_generated_builtin_for_tests()
local status = catalog.generated_builtin_index_status()
assert(status.ready ~= true and status.reason == "not-loaded",
    "generated index status is observational")
local before_candidates, before_reason = catalog.generated_builtin_compact_candidates_for_link(
    { class = "Warrior", name = "DriftTest" }, "Hanvar's Hoop", 0)
assert(#before_candidates == 0 and before_reason == "not-ready",
    "first linked candidate lookup performs zero generated-index loading")
assert(catalog.generated_builtin_index_status().ready ~= true,
    "candidate lookup leaves a cold generated index cold")
assert(package.loaded["catalog_content_hash"] == nil,
    "production runtime does not require the full catalog hash walker")

local payload, warm_reason = catalog.warm_generated_builtin_index("test-startup")
assert(payload and warm_reason == "ok", "startup warm loads generated authority")
status = catalog.generated_builtin_index_status()
assert(status.ready == true and status.load_origin == "test-startup",
    "generated catalog reports resident startup origin")
assert(tostring(status.catalog_fingerprint or ""):match("^%d+:%d+:%x+_%x+:%d+$"),
    "generated catalog must carry a deterministic content signature")
assert((tonumber(status.eager_resolved_locators) or 0) == 0,
    "drift validation must not eagerly resolve all generated locators")

local canonical = require("catalogs.lazbis")
local hash = require("catalog_content_hash")
local recomputed = hash.compute(canonical)
assert(recomputed == canonical.content_hash,
    "independent canonical content walk matches embedded catalog hash")
assert(recomputed == payload.catalog_fingerprint,
    "generated artifact hash matches canonical catalog hash")

local changed_entry = nil
for _, list in pairs(canonical.lists or {}) do
    for _, bucket in pairs(list.classes or {}) do
        for _, entry in pairs(bucket or {}) do
            if type(entry) == "table" and type(entry.item) == "string" then
                changed_entry = entry
                break
            end
        end
        if changed_entry then break end
    end
    if changed_entry then break end
end
assert(changed_entry, "canonical fixture contains an item entry")
local original_item = changed_entry.item
changed_entry.item = original_item .. " [drift]"
local changed_hash = hash.compute(canonical)
changed_entry.item = original_item
assert(changed_hash ~= recomputed,
    "same-shape canonical item edit fails deterministic content validation")

print("generated catalog drift: 12 passed, 0 failed")
