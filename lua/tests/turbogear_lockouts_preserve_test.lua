-- Run from repo root: luajit lua/tests/turbogear_lockouts_preserve_test.lua
-- Regression cover for a lockout that appeared on login and then vanished.
--
-- A gather that cannot read DZ_TimerList does not return "unknown" -- it
-- returns a full map of found=false records, which looks identical to "not
-- locked". Publishing that map overwrote a record that was still valid by its
-- own expiresAt, so the Lockouts tab flipped back to an open padlock while the
-- expedition window was sitting there showing 23 hours remaining.
--
-- Confirmed live: an exact-match lookup returned HIT for the very entry the tab
-- was rendering as open, so the read path was never the problem.
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

package.preload['mq'] = function()
    return {
        TLO = { Me = { CleanName = function() return "Drel" end }, Window = function() return nil end },
        configDir = '.',
        cmd = function() end,
        event = function() end,
    }
end
package.preload['config'] = function()
    return { CFG = { script_name = 'TurboGear' }, Settings = {}, SharedSettings = {} }
end

local lockouts = require('lockouts')
local preserve = lockouts._preserve_unexpired

local pass, fail = 0, 0
local function check(cond, msg)
    if cond then pass = pass + 1 else fail = fail + 1; print("  FAIL: " .. tostring(msg)) end
end

local NOW = os.time()
local NAME = "Nagafen's Lair [Group]"

local function locked_record(seconds_left, text)
    return {
        timerText = text or "0D:23H:45M",
        remainingSeconds = seconds_left,
        capturedAt = NOW - 60,
        expiresAt = NOW + seconds_left,
        found = true,
        custom = true,
    }
end

-- What a gather produces when the window cannot be read: complete, and wrong.
local function unreadable_record()
    return { timerText = "", remainingSeconds = nil, capturedAt = NOW, expiresAt = nil, found = false, custom = true }
end

-- ------------------------------------------------- the reported regression
local old = { Custom = { [NAME] = locked_record(23 * 3600 + 45 * 60) } }
local new = { Custom = { [NAME] = unreadable_record() } }
local kept = preserve(new, old)
check(kept == 1, "one unexpired record carried forward, got " .. tostring(kept))
check(new.Custom[NAME].found == true, "an unreadable gather no longer clobbers a live lockout")
check(new.Custom[NAME].timerText == "0D:23H:45M", "original timer text retained")
check(new.Custom[NAME].expiresAt == old.Custom[NAME].expiresAt, "absolute expiry retained")

-- A record missing from the new map entirely is also restored.
local dropped = { Custom = {} }
check(preserve(dropped, old) == 1, "record absent from the new map is restored")
check(dropped.Custom[NAME] ~= nil, "restored into the empty category")

local no_category = {}
check(preserve(no_category, old) == 1, "category is created when missing")
check(no_category.Custom and no_category.Custom[NAME] ~= nil, "record lands in a created category")

-- ------------------------------------------------ a real read always wins
local fresher = { Custom = { [NAME] = locked_record(20 * 3600, "0D:20H:00M") } }
check(preserve(fresher, old) == 0, "a freshly read timer is never overwritten by the cached one")
check(fresher.Custom[NAME].timerText == "0D:20H:00M", "the newly read value survives")

-- found=true but blank text is not a real read; it must not win.
local blank = { Custom = { [NAME] = { found = true, timerText = "", expiresAt = nil } } }
check(preserve(blank, old) == 1, "found=true with no timer text does not count as a read")
check(blank.Custom[NAME].timerText == "0D:23H:45M", "cached value kept over an empty one")

-- ------------------------------------------------------- expiry is honoured
local expired = { Custom = { [NAME] = {
    timerText = "0D:00H:00M", expiresAt = NOW - 1, found = true, custom = true,
} } }
local after = { Custom = { [NAME] = unreadable_record() } }
check(preserve(after, expired) == 0, "an expired record is allowed to fall off")
check(after.Custom[NAME].found == false, "expired lockout correctly reads as open")

local no_expiry = { Custom = { [NAME] = { timerText = "soon", found = true } } }
local target = { Custom = { [NAME] = unreadable_record() } }
check(preserve(target, no_expiry) == 0, "a record with no expiresAt is not carried forward indefinitely")

-- --------------------------------------------------------- multi-category
local many = {
    Raids = { ["Anguish (Wall of Slaughter)"] = locked_record(3600) },
    Custom = { [NAME] = locked_record(7200) },
    ["1 Group"] = { ["Fenrir (West Karana)"] = { found = true, expiresAt = NOW - 5 } },
}
local wiped = { Raids = {}, Custom = {}, ["1 Group"] = {} }
check(preserve(wiped, many) == 2, "two live records kept, the expired one dropped")
check(wiped.Raids["Anguish (Wall of Slaughter)"] ~= nil, "raid lockout preserved")
check(wiped.Custom[NAME] ~= nil, "custom lockout preserved")
check(wiped["1 Group"]["Fenrir (West Karana)"] == nil, "expired lockout not resurrected")

-- ------------------------------------------------------------- robustness
check(preserve(nil, old) == 0, "nil new map is a noop")
check(preserve({}, nil) == 0, "nil old map is a noop")
check(preserve({}, {}) == 0, "empty maps are a noop")
check(preserve({}, { Custom = "not a table" }) == 0, "malformed category ignored")
check(preserve({}, { Custom = { [NAME] = "not a table" } }) == 0, "malformed record ignored")

-- DoN state rides in the same map and is not a lockout category; it must not
-- be walked as one.
check(preserve({}, { DoNState = { capturedAt = NOW, replays = {} } }) == 0,
    "DoNState is not mistaken for a lockout category")

print(string.format('lockouts preserve: %d passed, %d failed', pass, fail))
if fail > 0 then os.exit(1) end
