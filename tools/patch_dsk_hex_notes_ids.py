#!/usr/bin/env python3
"""Fill DSK Hideous Hex Aug entries with item ids + DoN-style hover notes."""

from __future__ import annotations

import re
from pathlib import Path

LAZBIS = Path(__file__).resolve().parents[1] / "lua" / "turbogear" / "catalogs" / "lazbis.lua"
PREFIX = "Hideous Hex of "

# short -> (item_id, notes)  notes use ASCII '-' for MQ fonts
HEX_META: dict[str, tuple[int, str]] = {
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


def short_from_body(body: str) -> str | None:
    im = re.search(r'item = "([^"]+)"', body)
    if not im:
        return None
    item = im.group(1)
    if item.startswith(PREFIX):
        return item[len(PREFIX) :]
    if item in HEX_META:
        return item
    fm = re.search(r'"(Hideous Hex of [^"]+)"', body)
    if fm:
        return fm.group(1)[len(PREFIX) :]
    return None


def rewrite_body(body: str, short: str, item_id: int, notes: str) -> str:
    field_ind_m = re.search(r"^([ \t]+)(?:ids|item) = ", body, re.M)
    field_ind = field_ind_m.group(1) if field_ind_m else "          "
    slot_m = re.search(r'slot = "([^"]+)"', body)
    if not slot_m:
        raise RuntimeError(f"no slot in entry for {short}")
    full = PREFIX + short
    return (
        f"\n{field_ind}ids = {{\n"
        f"{field_ind}  {item_id},\n"
        f"{field_ind}}},\n"
        f'{field_ind}item = "{short}",\n'
        f"{field_ind}names = {{\n"
        f'{field_ind}  "{short}",\n'
        f'{field_ind}  "{full}",\n'
        f"{field_ind}}},\n"
        f'{field_ind}notes = "{notes}",\n'
        f'{field_ind}slot = "{slot_m.group(1)}",\n'
    )


def main() -> None:
    text = LAZBIS.read_text(encoding="utf-8")
    m = re.search(r"\n    dsk = \{", text)
    if not m:
        raise SystemExit("dsk not found")
    open_i = m.end() - 1
    close_i = find_matching_brace(text, open_i)
    dsk = text[open_i : close_i + 1]

    pieces: list[str] = []
    i = 0
    n = len(dsk)
    changed = 0
    while i < n:
        em = re.match(r"[ \t]*Aug\d+[ \t]*=[ \t]*\{", dsk[i:])
        if not em:
            pieces.append(dsk[i])
            i += 1
            continue
        brace = i + em.end() - 1
        end = find_matching_brace(dsk, brace)
        body = dsk[brace + 1 : end]
        short = short_from_body(body)
        if not short or short not in HEX_META:
            pieces.append(dsk[i : end + 1])
            i = end + 1
            continue
        item_id, notes = HEX_META[short]
        new_body = rewrite_body(body, short, item_id, notes)
        head = dsk[i : brace + 1]
        j = end + 1
        suffix = ""
        if j < n and dsk[j] == ",":
            suffix += ","
            j += 1
        if j < n and dsk[j] == "\n":
            suffix += "\n"
            j += 1
        pieces.append(head + new_body + "}" + suffix)
        i = j
        changed += 1

    new_dsk = "".join(pieces)
    # Fix closer indents (template Aug / class Aug20)
    new_dsk = re.sub(r"\n\},\n(        Aug\d+ = )", r"\n        },\n\1", new_dsk)
    new_dsk = re.sub(r"\n\},\n(        Charm = )", r"\n        },\n\1", new_dsk)
    new_dsk = re.sub(r"\n\},\n(        \},)", r"\n          },\n\1", new_dsk)

    LAZBIS.write_text(text[:open_i] + new_dsk + text[close_i + 1 :], encoding="utf-8")

    assert "notes = \"+5% magic spell damage" in new_dsk
    assert "27620" in new_dsk  # Benevolent Efficiency id
    assert "33008" in new_dsk  # Physical Prowess
    assert "33011" in new_dsk  # Mental Prowess
    assert changed >= 35, f"expected >=35 hex entries, got {changed}"
    print(f"Updated {changed} Hideous Hex entries with ids+notes")


if __name__ == "__main__":
    main()
