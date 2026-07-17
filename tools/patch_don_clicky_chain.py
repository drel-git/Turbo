#!/usr/bin/env python3
"""Replace DoN single Clicky with Boon + specialty + combined final rows."""

from pathlib import Path
import re

BLOCK = Path(__file__).resolve().parents[1] / "tools" / "don_bis_block.lua"

# specialty_id -> (specialty_name, final_id, final_name)
SPECIALTY = {
    56755: ("Icon of Unwavering Defense", 57141, "Icon of Ancient Defense"),
    56756: ("Icon of Scribe's Endurance", 57143, "Icon of the Ancient Scribe"),
    56757: ("Icon of Potent Prowess", 57142, "Icon of Ancient Prowess"),
}

BOON = ("Icon of Ancient Boon", 56758)


def lua_str(s: str) -> str:
    return "'" + s.replace("\\", "\\\\").replace("'", "\\'") + "'"


def main() -> None:
    text = BLOCK.read_text(encoding="utf-8")
    pat = re.compile(
        r"\['Clicky'\] = 'Icon of (?:Unwavering Defense|Scribe\\'s Endurance|Potent Prowess)/(5675[567])',"
    )

    def repl(m: re.Match) -> str:
        sid = int(m.group(1))
        sname, fid, fname = SPECIALTY[sid]
        bname, bid = BOON
        return (
            f"['Clicky1'] = {lua_str(f'{bname}/{bid}')},\n"
            f"\t\t\t['Clicky2'] = {lua_str(f'{sname}/{sid}')},\n"
            f"\t\t\t['Clicky3'] = {lua_str(f'{fname}/{fid}')},"
        )

    text, n = pat.subn(repl, text)
    if n != 16:
        raise SystemExit(f"expected 16 Clicky replacements, got {n}")

    text, n2 = re.subn(
        r"\{Name='Clickies',\s*Slots=\{'Clicky',\}\}",
        "{Name='Clickies', Slots={'Clicky1','Clicky2','Clicky3',}}",
        text,
        count=1,
    )
    if n2 != 1:
        raise SystemExit(f"Clickies slots replace failed n={n2}")

    BLOCK.write_text(text, encoding="utf-8")
    print(f"Updated {BLOCK}: {n} classes -> Clicky1/2/3")


if __name__ == "__main__":
    main()
