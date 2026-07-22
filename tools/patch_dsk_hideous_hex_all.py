#!/usr/bin/env python3
"""Unify DSK Hideous Hex augs for all classes; class-gate Physical/Mental Prowess.

Mirrors tools/patch_don_cryptic_clutch_all.py:
  - Shared Hex foci live on dsk.template (Aug1-Aug19)
  - Each class keeps only Aug20 = Physical or Mental Prowess
  - Augs category lists Middle Finger + Aug1-Aug20
"""

from __future__ import annotations

import re
from pathlib import Path

LAZBIS = Path(__file__).resolve().parents[1] / "lua" / "turbogear" / "catalogs" / "lazbis.lua"

# Same order as DoN Cryptic Clutch shared foci, plus Companion's Mercy.
SHARED_SHORT = [
    "Benevolent Efficiency",
    "Benevolent Extension",
    "Benevolent Alacrity",
    "Malevolent Efficiency",
    "Malevolent Extension",
    "Malevolent Alacrity",
    "Arcane Demise",
    "Fiery Demise",
    "Chilling Demise",
    "Noxious Demise",
    "Festering Demise",
    "Merciful Mending",
    "Expanded Reach",
    "Nimble Elusion",
    "Adept Guard",
    "Visceral Malice",
    "Wanton Assault",
    "Lethal Barrage",
    "Companion's Mercy",
]

PHYSICAL_CLASSES = {
    "Warrior", "Paladin", "Ranger", "Shadow Knight", "Monk",
    "Bard", "Rogue", "Beastlord", "Berserker",
}
MENTAL_CLASSES = {
    "Cleric", "Druid", "Shaman", "Necromancer", "Wizard", "Magician", "Enchanter",
}

CLASS_KEYS = [
    "Bard", "Beastlord", "Berserker", "Cleric", "Druid", "Enchanter", "Magician",
    "Monk", "Necromancer", "Paladin", "Ranger", "Rogue", "Shadow Knight",
    "Shaman", "Warrior", "Wizard",
]


def hex_name(short: str) -> str:
    return f"Hideous Hex of {short}"


def find_matching_brace(text: str, open_idx: int) -> int:
    depth = 0
    i = open_idx
    n = len(text)
    in_str = None
    while i < n:
        ch = text[i]
        if in_str:
            if ch == "\\":
                i += 2
                continue
            if ch == in_str:
                in_str = None
            i += 1
            continue
        if ch in "\"'":
            in_str = ch
        elif ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return i
        i += 1
    raise RuntimeError("unbalanced brace")


# short -> (item_id, notes); kept in sync with patch_dsk_hex_notes_ids.py
HEX_META = {
    "Benevolent Efficiency": (27620, "-5% beneficial spell mana cost | +50 hp/mana/endur"),
    "Benevolent Extension": (28113, "+35% beneficial spell duration | +50 hp/mana/endur"),
    "Benevolent Alacrity": (27622, "-35% beneficial spell cast time | +50 hp/mana/endur"),
    "Malevolent Efficiency": (27618, "-5% detrimental spell mana cost | +50 hp/mana/endur"),
    "Malevolent Extension": (28112, "+35% detrimental spell duration | +50 hp/mana/endur"),
    "Malevolent Alacrity": (27621, "-35% detrimental spell cast time | +50 hp/mana/endur"),
    "Arcane Demise": (28114, "+5% magic spell damage | +50 hp/mana/endur"),
    "Fiery Demise": (27623, "+5% fire spell damage | +50 hp/mana/endur"),
    "Chilling Demise": (27624, "+5% cold spell damage | +50 hp/mana/endur"),
    "Noxious Demise": (27625, "+5% poison spell damage | +50 hp/mana/endur"),
    "Festering Demise": (28109, "+5% disease spell damage | +50 hp/mana/endur"),
    "Merciful Mending": (28110, "+5% healing | +50 hp/mana/endur"),
    "Companion's Mercy": (28111, "+30% companion healing | +50 hp/mana/endur"),
    "Expanded Reach": (28115, "+40% spell range | +50 hp/mana/endur"),
    "Nimble Elusion": (28119, "+60% dodge | +50 hp/mana/endur"),
    "Adept Guard": (28118, "+60% parry, +60% block | +50 hp/mana/endur"),
    "Visceral Malice": (28117, "+250% melee critical damage | +50 hp/mana/endur"),
    "Wanton Assault": (28116, "+18% double attack, +6% triple attack, +3% chance to hit | +50 hp/mana/endur"),
    "Lethal Barrage": (28120, "+20% archery and throwing chance to hit | +50 hp/mana/endur"),
    "Physical Prowess": (
        33008,
        "No focus effect | +15 STR/STA/AGI/DEX, +5 WIS/INT/CHA, +150 hp, +200 mana/endur, +15 ac",
    ),
    "Mental Prowess": (
        33011,
        "No focus effect | +15 WIS/INT/CHA, +5 STR/STA/AGI/DEX, +130 hp, +360 mana, +13 ac, +10 resists",
    ),
}


def lua_hex_entry(slot: str, short: str, indent: str) -> str:
    full = hex_name(short)
    item_id, notes = HEX_META[short]
    # item = short (DoN-style UI label); names keep full for ownership match.
    return (
        f"{indent}{slot} = {{\n"
        f"{indent}  ids = {{\n"
        f"{indent}    {item_id},\n"
        f"{indent}  }},\n"
        f'{indent}  item = "{short}",\n'
        f"{indent}  names = {{\n"
        f'{indent}    "{short}",\n'
        f'{indent}    "{full}",\n'
        f"{indent}  }},\n"
        f'{indent}  notes = "{notes}",\n'
        f'{indent}  slot = "{slot}",\n'
        f"{indent}}},\n"
    )


def strip_aug_keys(body: str) -> str:
    out: list[str] = []
    i = 0
    n = len(body)
    while i < n:
        m = re.match(r"[ \t]*Aug\d+[ \t]*=[ \t]*\{", body[i:])
        if not m:
            out.append(body[i])
            i += 1
            continue
        while out and out[-1] in " \t":
            out.pop()
        if out and out[-1] != "\n":
            out.append(body[i])
            i += 1
            continue
        brace_at = i + m.end() - 1
        end = find_matching_brace(body, brace_at)
        j = end + 1
        if j < n and body[j] == ",":
            j += 1
        if j < n and body[j] == "\n":
            j += 1
        i = j
    text = "".join(out)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text


def class_key_pattern(cls: str) -> re.Pattern[str]:
    if cls == "Shadow Knight":
        return re.compile(r'\n([ \t]+)\["Shadow Knight"\][ \t]*=[ \t]*\{')
    return re.compile(rf"\n([ \t]+){re.escape(cls)}[ \t]*=[ \t]*\{{")


def patch_categories(dsk: str) -> str:
    old = """        {
          name = "Augs",
          slots = {
            "Middle Finger (Mayong)",
            "Aug1",
            "Aug2",
            "Aug3",
            "Aug4",
            "Aug5",
            "Aug6",
            "Aug7",
            "Aug8",
            "Aug9",
            "Aug10",
            "Aug11",
            "Aug12",
            "Aug13",
          },
        },"""
    slots = ",\n".join(f'            "Aug{i}"' for i in range(1, 21))
    new = f"""        {{
          name = "Augs",
          slots = {{
            "Middle Finger (Mayong)",
{slots},
          }},
        }},"""
    if old not in dsk:
        raise SystemExit("DSK Augs category block not found (already patched?)")
    return dsk.replace(old, new, 1)


def patch_classes(dsk: str) -> str:
    classes_m = re.search(r"\n      classes = \{", dsk)
    if not classes_m:
        raise SystemExit("dsk.classes not found")
    classes_open = classes_m.end() - 1
    classes_close = find_matching_brace(dsk, classes_open)
    classes_block = dsk[classes_open : classes_close + 1]

    spans: list[tuple[int, int, str]] = []
    for cls in CLASS_KEYS:
        m = class_key_pattern(cls).search(classes_block)
        if not m:
            raise SystemExit(f"missing class {cls}")
        brace = m.end() - 1
        end = find_matching_brace(classes_block, brace)
        indent = m.group(1) + "  "
        body = strip_aug_keys(classes_block[brace + 1 : end])
        body = body.rstrip() + "\n"
        if cls in PHYSICAL_CLASSES:
            body += lua_hex_entry("Aug20", "Physical Prowess", indent)
        elif cls in MENTAL_CLASSES:
            body += lua_hex_entry("Aug20", "Mental Prowess", indent)
        else:
            raise SystemExit(f"{cls}: no prowess assignment")
        leftovers = [
            h for h in re.findall(r'Hideous Hex of ([^"]+)', body)
            if h not in ("Physical Prowess", "Mental Prowess")
        ]
        if leftovers:
            raise SystemExit(f"{cls}: leftover shared hex: {leftovers[:3]}")
        # Keep class-closing brace indentation when content is replaced.
        close_indent = m.group(1)
        spans.append((brace + 1, end, body + close_indent))

    spans.sort(key=lambda s: s[0], reverse=True)
    for start, end, body in spans:
        classes_block = classes_block[:start] + body + classes_block[end:]

    return dsk[:classes_open] + classes_block + dsk[classes_close + 1 :]


def patch_template(dsk: str) -> str:
    tmpl_m = re.search(r"\n      template = \{", dsk)
    if not tmpl_m:
        raise SystemExit("dsk.template not found")
    tmpl_open = tmpl_m.end() - 1
    tmpl_close = find_matching_brace(dsk, tmpl_open)
    body = dsk[tmpl_open + 1 : tmpl_close]
    body = strip_aug_keys(body)
    shared = "".join(
        lua_hex_entry(f"Aug{i}", short, indent="        ")
        for i, short in enumerate(SHARED_SHORT, start=1)
    )
    return dsk[: tmpl_open + 1] + "\n" + shared + body + dsk[tmpl_close:]


def main() -> None:
    text = LAZBIS.read_text(encoding="utf-8")
    dsk_m = re.search(r"\n    dsk = \{", text)
    if not dsk_m:
        raise SystemExit("dsk = { not found")
    dsk_open = dsk_m.end() - 1
    dsk_close = find_matching_brace(text, dsk_open)
    dsk = text[dsk_open : dsk_close + 1]

    dsk = patch_categories(dsk)
    dsk = patch_classes(dsk)
    dsk = patch_template(dsk)

    text = text[:dsk_open] + dsk + text[dsk_close + 1 :]
    LAZBIS.write_text(text, encoding="utf-8")

    assert 'name = "Augs"' in dsk
    assert '"Aug20"' in dsk
    assert "Companion's Mercy" in dsk
    bard = re.search(r"\n        Bard = \{(.*?)\n        Beastlord =", dsk, re.S)
    assert bard, "Bard class missing"
    augs = re.findall(r"\bAug(\d+)\s*=", bard.group(1))
    assert augs == ["20"], f"Bard augs unexpected: {augs}"
    assert 'item = "Physical Prowess"' in bard.group(1)
    assert "Hideous Hex of Physical Prowess" in bard.group(1)
    clr = re.search(r"\n        Cleric = \{(.*?)\n        Druid =", dsk, re.S)
    assert clr and re.findall(r"\bAug(\d+)\s*=", clr.group(1)) == ["20"]
    assert 'item = "Mental Prowess"' in clr.group(1)
    rng = re.search(r"\n        Ranger = \{(.*?)\n        Rogue =", dsk, re.S)
    assert rng and 'item = "Physical Prowess"' in rng.group(1)
    assert re.search(r"template = \{.*?Aug1 = \{", dsk, re.S)
    tmpl = re.search(r"template = \{(.*?)\n      visible =", dsk, re.S).group(1)
    shared_items = re.findall(r'item = "([^"]+)"', tmpl)
    hex_items = [x for x in shared_items if x in SHARED_SHORT or x.startswith("Hideous Hex")]
    assert len([x for x in shared_items if x in SHARED_SHORT]) == 19, shared_items
    assert "Companion's Mercy" in shared_items
    assert "Physical Prowess" not in shared_items
    assert "Hideous Hex of Companion's Mercy" in tmpl
    print("Patched OK:", LAZBIS)


if __name__ == "__main__":
    main()
