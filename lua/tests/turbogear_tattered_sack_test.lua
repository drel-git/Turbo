-- Run from repo root:  luajit lua\tests\turbogear_tattered_sack_test.lua
-- Adventurer's Tattered Sack progression: higher rank clears lower + materials.
package.path = "lua/turbogear/?.lua;lua/turbogear/?/init.lua;" .. package.path

package.preload["mq"] = function()
    return {
        configDir = ".",
        TLO = {
            Me = { CleanName = function() return "Tester" end },
            MacroQuest = { Server = function() return "Srv" end },
            FindItem = function() return nil end,
        },
    }
end
package.preload["config"] = function()
    return {
        CFG = { script_name = "TurboGear" },
        Settings = {},
        SharedSettings = {},
        SaveSettings = function() end,
        SaveSharedSettings = function() end,
    }
end

local bis = require("bis")
local catalog = require("bis_catalog")

local passed, failed = 0, 0
local function check(cond, label)
    if cond then
        passed = passed + 1
    else
        failed = failed + 1
        io.stderr:write("FAIL: ", tostring(label), "\n")
    end
end

local function has_id(entry, id)
    for _, v in ipairs((entry and entry.ids) or {}) do
        if tonumber(v) == id then return true end
    end
    return false
end

local function has_name(entry, name)
    name = tostring(name or ""):lower()
    for _, v in ipairs((entry and entry.names) or {}) do
        if tostring(v):lower() == name then return true end
    end
    return false
end

local function snap_with(item_name, item_id)
    return {
        name = "Tester",
        class = "Wizard",
        bags = { { name = item_name, id = item_id, location = "Bags", where = "Bag" } },
        equipped = {},
        bank = {},
    }
end

-- resolve_entry expands Celestial onto base + frame
local base = catalog.resolve_entry("bagitems", "Wizard", "Adventurer's Tattered Sack (Base) (T1 Named)")
check(base ~= nil, "base entry resolves")
check(has_id(base, 151053) and has_id(base, 151057), "base ids include own + celestial")
check(has_name(base, "Adventurer's Tattered Sack (Celestial)"), "base names include celestial")

local frame = catalog.resolve_entry("bagitems", "Wizard", "Reinforced Stitching Frame (T2 Trash)")
check(frame ~= nil, "frame entry resolves")
check(has_id(frame, 151058) and has_id(frame, 151057), "frame ids include frame + celestial")
check(has_name(frame, "Adventurer's Tattered Sack (Celestial)"), "frame names include celestial")
check(not has_name(frame, "Adventurer's Tattered Sack"), "frame does not clear on base name alone")

local arc = catalog.resolve_entry("bagitems", "Wizard", "Adventurer's Tattered Sack (Arcwoven) (UP3)")
check(has_id(arc, 151056) and has_id(arc, 151057), "arcwoven ids include own + celestial")
check(not has_id(arc, 151053), "arcwoven does not list base id as owned alias")

-- Owning Celestial clears base + frame via evaluate_entry
local celestial_snap = snap_with("Adventurer's Tattered Sack (Celestial)", 151057)
local base_eval = bis.evaluate_entry(base, celestial_snap, { skip_live = true })
check(base_eval.status == "carried", "celestial clears base sack row")
local frame_eval = bis.evaluate_entry(frame, celestial_snap, { skip_live = true })
check(frame_eval.status == "carried", "celestial clears stitching frame")

-- Owning only base must NOT clear frame (rank parens preserved)
local base_only = snap_with("Adventurer's Tattered Sack", 151053)
local frame_base_only = bis.evaluate_entry(frame, base_only, { skip_live = true })
check(frame_base_only.status == "missing", "base sack does not clear frame")

-- Owning Arcwoven clears base, not celestial, not frame
local arc_snap = snap_with("Adventurer's Tattered Sack (Arcwoven)", 151056)
local base_from_arc = bis.evaluate_entry(base, arc_snap, { skip_live = true })
check(base_from_arc.status == "carried", "arcwoven clears base")
local cel = catalog.resolve_entry("bagitems", "Wizard", "Adventurer's Tattered Sack (Celestial)")
local cel_from_arc = bis.evaluate_entry(cel, arc_snap, { skip_live = true })
check(cel_from_arc.status == "missing", "arcwoven does not clear celestial")
local frame_from_arc = bis.evaluate_entry(frame, arc_snap, { skip_live = true })
check(frame_from_arc.status == "missing", "arcwoven does not clear frame")

-- Backtick apostrophe in inventory name still matches
local tick_snap = snap_with("Adventurer`s Tattered Sack (Celestial)", 151057)
local base_tick = bis.evaluate_entry(base, tick_snap, { skip_live = true })
check(base_tick.status == "carried", "backtick apostrophe matches celestial")

io.write(string.format("tattered_sack_test: %d passed, %d failed\n", passed, failed))
if failed > 0 then os.exit(1) end
