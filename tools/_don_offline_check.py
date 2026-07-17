"""Offline checks for DoN catalog + spell-aware pack matching helpers."""
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
LUA = r"""
local bis_path = package.path
package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

-- Stub mq for bis.lua load
package.preload['mq'] = function()
  return {
    configDir = '.',
    TLO = { Me = setmetatable({}, { __index = function() return function() return nil end end }) },
  }
end
package.preload['config'] = function()
  return { Settings = {}, CFG = { script_name = 'TurboGear' }, SaveSettings = function() end }
end

local cat = dofile('lua/turbogear/catalogs/lazbis.lua')
assert(cat.lists.don, 'missing lists.don')
assert(cat.lists.don.name == 'DoN' or cat.lists.don.name == 'Dragons of Norrath')
local war = cat.lists.don.classes.Warrior
assert(war.Pack1 and war.Pack1.spell == 'Malicious Onslaught Discipline')
assert(war.Pack1.item == 'Tome Pack: Ancient: Malicious Onslaught')
assert(war.Pack4 and war.Pack4.spell == 'Fourth Wind')
assert(war.Glyph1 and not war.Glyph1.spell, 'glyph must stay item-only')
local clr = cat.lists.don.classes.Cleric
assert(#clr.Pack1.spells == 3)
assert(clr.Pack4 and clr.Pack4.spell == 'Chromablast')
local spells_slots = nil
for _, catrow in ipairs(cat.lists.don.categories or {}) do
  if catrow.name == 'Spells' then spells_slots = catrow.slots break end
end
assert(spells_slots and #spells_slots >= 10, 'expected Pack1-Pack10 spell slots')
local clicky_slots = nil
for _, catrow in ipairs(cat.lists.don.categories or {}) do
  if catrow.name == 'Clickies' then clicky_slots = catrow.slots break end
end
assert(clicky_slots and #clicky_slots == 3, 'expected Clicky1-3')
assert(war.Clicky1 and war.Clicky1.item == 'Icon of Ancient Boon')
assert(war.Clicky2 and war.Clicky2.item == 'Icon of Unwavering Defense')
assert(war.Clicky3 and war.Clicky3.item == 'Icon of Ancient Defense')

-- Load bis match helpers via a tiny inline reimplementation of known-check semantics
local function snap_knows(snap, spell)
  spell = tostring(spell or ''):lower()
  local row = snap.spells and snap.spells[spell]
  return type(row) == 'table' and ((tonumber(row.book) or 0) > 0)
end
local function spells_known(entry, snap)
  for _, s in ipairs(entry.spells or {}) do
    if not snap_knows(snap, s) then return false end
  end
  return true
end

local snap = { spells = { allegiance = { name = 'Allegiance', book = 1 } } }
assert(not spells_known(clr.Pack1, snap), 'partial pack spells should not clear')
snap.spells['hand of allegiance'] = { name = 'Hand of Allegiance', book = 1 }
snap.spells['symbol of elushar'] = { name = 'Symbol of Elushar', book = 1 }
assert(spells_known(clr.Pack1, snap), 'all pack spells should clear')

print('don_offline_ok')
"""

def main() -> None:
    # Write temp lua script
    script = ROOT / "tools" / "_don_offline_check.lua"
    script.write_text(LUA, encoding="utf-8")
    r = subprocess.run(
        ["luajit", str(script)],
        cwd=str(ROOT),
        capture_output=True,
        text=True,
    )
    print(r.stdout)
    print(r.stderr, file=sys.stderr)
    if r.returncode != 0 or "don_offline_ok" not in r.stdout:
        raise SystemExit(r.returncode or 1)
    print("PASS")


if __name__ == "__main__":
    main()
