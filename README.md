<img width="861" height="114" alt="TurboSuite" src="https://github.com/user-attachments/assets/c2c5ad06-d38b-4faa-82e5-cb64f12af4af" />


> Quality-of-life tools for EverQuest EMU servers (E3Next / MacroQuest): smart looting, fleet-wide inventory and BiS tracking, loot announcements, spell research automation, spawn tracking, raid rolls, and more. It's your loot, do whatever you want with it.

**On this page:** [Install](#install-in-under-a-minute) · [What's included](#whats-included) · [Feature tour](#feature-tour) · [Updating](#updating) · [Your settings are safe](#your-settings-are-safe) · [Manual install](#manual-install)


## Install in Under a Minute

1. `Windows` - [**Download the patcher, TurboPatcher.exe**](https://github.com/drel-git/TurboPatcher/releases/latest/download/TurboPatcher.exe). Drop it in your MacroQuest folder (any spot works, but that location lets the in-game Turbo Patcher button find it).
2. `Linux` - [**Download the latest release**](https://github.com/drel-git/Turbo/releases) and extract to your E3Next or MQ folder.
2. **Run `TurboPatcher.exe`.** It finds your MacroQuest folder automatically (or click Browse and pick the folder that contains `lua` and `Macros`).
3. **Click Install.** That's it. The patcher shows the patch notes and keeps you updated from then on.


> Windows may show a SmartScreen prompt the first time since the exe is unsigned. Click "More info", then "Run anyway".

Then in game:

```
/lua run Turbo          the suite hub
```

## What's Included

| Tool | Run | What it does |
| ---- | --- | ------------ |
| **Turbo** (hub) | `/lua run Turbo` | Central control panel: auto-loot on/off, pick the group looter, one-click INI setup, rulepack browser, loot gains and skip tracking |
| **TurboLoot** | `/mac turboloot` | INI-driven corpse looting, then selling, banking, tributing, and destroying in town. [More info](https://github.com/drel-git/TurboLoot) |
| **TurboKey** | `/mac TurboKey RULE` | Pick an item up, run one command, and it's categorized in your loot rules (KEEP, SELL, BANK, TRIBUTE, DESTROY, IGNORE) |
| **TurboGive** | `/mac TurboGive` | Hand out and collect items between your characters using a shared give list [More info](https://github.com/drel-git/TurboLoot/blob/main/TurboGive%20Getting%20Started.md) |
| **TurboGear** | `/lua run turbogear` | Live inventory of every boxed character in one window, BiS upgrade flags, and automatic "who needs this" announcements when an item is linked in chat |
| **TurboMobs** | `/lua run TurboMobs` | Lightweight NPC spawn tracker with alerts |
| **TurboRolls** | `/lua run TurboRolls` | Raid roll tracking: start a roll range, see everyone's rolls ranked live |
| Extras | various | `turbo_bank_all` (bank everything), `turbo_collect_cash` / `turbo_collect_dc` (gather plat and Diamond Coins from your boxes), `turbo_reclaim_lotto`, an xtarget heal macro, and more |

## Feature Tour

### Looting that runs itself

TurboLoot decides what to grab from each corpse using your rules: exact item rules first, then wildcards (spells, tomes, skill-ups), then platinum value thresholds. Kill, loot, keep grinding. When your bags fill up, one command near a banker and vendor (`/mac turboloot unload`) banks, tributes, sells, and destroys everything according to your rules. Tag new items as you meet them with TurboKey instead of ever editing the INI by hand.

The Turbo hub adds the multibox glue: a toggle that turns auto-looting on and off for the whole group, a looter picker, setup helpers that wire the E3Next event hooks for you, and trackers that show what you gained and what got skipped.

### Know your whole fleet's gear

TurboGear keeps a live inventory snapshot of every character you box, shared over the MacroQuest actor bus. Open one window and see who is wearing what, who has an upgrade sitting in the bank, and what each character still needs from the BiS lists (Lazarus lists built in, plus your own custom lists).

The headline feature: when anyone links an item in chat, TurboGear instantly announces who actually needs it, checked against every box's real inventory. No more "does anyone need this?" silence while six people alt-tab.

The Spells tab also tracks each caster's researchable spells (levels 66-70), shows what is still missing across the fleet, and exports per-character want lists with one click.

### Raid night helpers

TurboRolls runs loot rolls with a live ranked window (start a range, everyone `/random`s, done). TurboMobs keeps an eye out for the spawns you care about.

## Updating

Open TurboPatcher and click **Update Now**. Running Turbo scripts notice the update starting and stop themselves on every box, files get replaced, and you just `/lua run turbogear` (or `/lua run Turbo`) again. The patcher shows exactly what changed in each release.

## Your Settings Are Safe

Updates never touch your personal data. Character settings, the inventory cache, BiS and watch lists, and your `turboloot.ini` all live in MacroQuest's `config` folder and are left alone. Shipped default files in `config/` are only copied when you don't already have them. On top of that, the patcher backs up every file it replaces to `config/TurboPatcher_backup/` (the newest 5 backups are kept).

## Manual Install

Prefer not to use the patcher? Click **Code, then Download ZIP** on this page, then copy the `lua` and `Macros` folders into your MacroQuest folder. Check the `config` folder for example INI templates.

## Requirements

- An EverQuest EMU server (built and tested on Project Lazarus)
- MacroQuest with E3Next (RoF2 client)
- Windows for the patcher; the scripts themselves run wherever MQ runs
- An extractor for Linux; extract to your E3Next or MQ folder and you're ready to go.

## License

MIT. See [LICENSE](LICENSE).
