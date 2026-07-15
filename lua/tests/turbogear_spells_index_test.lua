-- Run from repo root:  luajit lua\tests\turbogear_spells_index_test.lua
-- Tests the pure core of the spells display index. Runtime deps stubbed.
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

package.preload['diagnostics'] = function()
    return { time = function(_, fn) return fn() end, count = function() end,
             event = function() end, context = function() end }
end
package.preload['research_catalog'] = function()
    return nil -- force pcall(require) failure path; core does not need it
end

local SI = require('spells_index')
local core = SI.core

local passed, failed = 0, 0
local function check(cond, label)
    if cond then
        passed = passed + 1
    else
        failed = failed + 1
        io.stderr:write('FAIL: ', tostring(label), '\n')
    end
end

-- classification helpers (mirror research_catalog.classify_source behavior)
local function classify(source)
    local s = tostring(source or ""):lower()
    if s:find("random drop", 1, true) then return "drop", "Drop" end
    if s:find("anguish", 1, true) then return "anguish", "Anguish" end
    if s:find("library", 1, true) then return "library", "PoK Library" end
    if s:find("quest", 1, true) then return "quest", "Quest" end
    if s:find("research", 1, true) then return "research", tostring(source) end
    return "other", tostring(source)
end
local function norm(name)
    return tostring(name or ""):lower():gsub("%s+", " ")
end

-- location_short
check(core.location_short("drop", "Random Drop", true) == "Random (non-research)", 'location: drop tagged non-research')
check(core.location_short("research", "Researched or Glowing Rune", false) == "Research", 'location: research collapses to Research')
check(core.location_short("anguish", "Anguish Rune Turn In", true) == "Anguish (non-research)", 'location: anguish')
check(core.location_short(nil, "", false) == "Unknown", 'location: empty source -> Unknown')

-- build_class_roster
local laz_entries = {
    [70] = {
        "Ancient: Call of Power|Anguish Rune Turn In",
        "Arcane Aria|Random Drop",
        "Voice of the Vampire|Researched or Glowing Rune",
    },
    [69] = { "Chorus of Life|Researched or Greater Rune" },
}
local ini_recipes = {
    { level = 70, name = "Voice of the Vampire", norm = norm("Voice of the Vampire"),
      ingredients = { "Glowing Rune", "Quill" } },
    { level = 69, name = "INI Only Spell", norm = norm("INI Only Spell"), ingredients = {} },
}
local roster = core.build_class_roster(laz_entries, ini_recipes, classify, norm)
check(#roster == 5, 'roster: 4 laz + 1 ini-only rows, got ' .. #roster)
check(roster[1].level == 70, 'roster: sorted level desc')
local by_name = {}
for _, r in ipairs(roster) do by_name[r.name] = r end
check(by_name["Voice of the Vampire"].inIni == true, 'roster: ini recipe matched')
check(by_name["Voice of the Vampire"].recipeTip == "Glowing Rune, Quill", 'roster: recipe tooltip baked')
check(by_name["Arcane Aria"].nonResearch == true, 'roster: drop is non-research')
check(by_name["Arcane Aria"].location == "Random (non-research)", 'roster: drop location label')
check(by_name["INI Only Spell"] ~= nil, 'roster: ini-only spell included')
check(by_name["INI Only Spell"].location == "Research", 'roster: ini-only location')
check(by_name["Chorus of Life"].inIni == false, 'roster: laz row without recipe')

-- eval_char_rows: full book
local book = {
    [norm("Voice of the Vampire")] = { inBook = true, scroll = 0 },
    [norm("Arcane Aria")] = { inBook = false, scroll = 2 },
}
local function inv_info(name, sb)
    local row = sb[norm(name)]
    if sb._partial then
        if sb._missing and sb._missing[norm(name)] then return { inBook = false, scroll = 0, partial = true } end
        return { inBook = false, scroll = 0, noData = true, partial = true }
    end
    if row then return { inBook = row.inBook, scroll = row.scroll } end
    return { inBook = false, scroll = 0 }
end
local rows = core.eval_char_rows(roster, book, inv_info)
local kinds = {}
for _, r in ipairs(rows) do kinds[r.name] = r.kind end
check(kinds["Voice of the Vampire"] == "owned", 'eval: scribed spell owned')
check(kinds["Arcane Aria"] == "owned", 'eval: scroll-only counts as owned')
check(kinds["Chorus of Life"] == "missing", 'eval: absent spell missing')

-- eval: no book at all -> everything unknown
local rows_nil = core.eval_char_rows(roster, nil, inv_info)
for _, r in ipairs(rows_nil) do
    if r.kind ~= "unknown" then
        check(false, 'eval: nil book row not unknown: ' .. r.name)
    end
end
check(rows_nil[1].kind == "unknown", 'eval: nil book -> unknown')

-- eval: partial want-file book -> exported missing red, rest unknown
local partial = { _partial = true, _missing = { [norm("Chorus of Life")] = true } }
local rows_partial = core.eval_char_rows(roster, partial, inv_info)
local pk = {}
for _, r in ipairs(rows_partial) do pk[r.name] = r end
check(pk["Chorus of Life"].kind == "missing", 'eval: want-file missing is red')
check(pk["Chorus of Life"].partial == true, 'eval: partial flagged')
check(pk["Voice of the Vampire"].kind == "unknown", 'eval: non-exported spell unknown in partial book')

-- filter_rows
local by_level, summary = core.filter_rows(rows, {})
check(summary.total == 5, 'filter: no filters keeps all')
check(#(by_level[70] or {}) == 3, 'filter: level grouping')

local _, s2 = core.filter_rows(rows, { hide_owned = true })
check(s2.owned == nil or s2.owned == 0, 'filter: hide_owned removes owned')
check(s2.total == 3, 'filter: hide_owned total (2 owned removed)')

local _, s3 = core.filter_rows(rows, { hide_non_research = true })
check(s3.total == 3, 'filter: hide_non_research removes drop+anguish')

local bl4, s4 = core.filter_rows(rows, { level = 69 })
check(s4.total == 2 and bl4[70] == nil, 'filter: level chip')

local _, s5 = core.filter_rows(rows, { level = "all" })
check(s5.total == 5, 'filter: level "all" keeps everything')

-- summary kinds
check((s5.owned or 0) == 2 and (s5.missing or 0) == 3, 'filter: summary counts by kind')

io.write(string.format('spells_index core: %d passed, %d failed\n', passed, failed))
os.exit(failed == 0 and 0 or 1)
