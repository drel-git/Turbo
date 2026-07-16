<img width="861" height="114" alt="TurboSuite" src="https://github.com/user-attachments/assets/c2c5ad06-d38b-4faa-82e5-cb64f12af4af" />


> Quality-of-life tools for EverQuest EMU (E3Next / MacroQuest): smart looting, fleet inventory and BiS, linked-needs announces, spell research, spawn tracking, raid rolls, and more. It's your loot, do whatever you want with it.

**On this page:** [Install](#install-in-under-a-minute) · [What's included](#whats-included) · [Feature tour](#feature-tour) · [Updating](#updating) · [Your settings are safe](#your-settings-are-safe) · [Requirements](#requirements) · [Manual install](#manual-install) · [Support](#support)


## Install in Under a Minute

### Windows

1. [**Download the patcher, TurboPatcher.exe**](https://github.com/drel-git/TurboPatcher/releases/latest/download/TurboPatcher.exe). Drop it in your MacroQuest folder (any spot works, but that location lets the in-game Turbo Patcher button find it).
2. **Run `TurboPatcher.exe`.** It finds your MacroQuest folder automatically (or click Browse and pick the folder that contains `lua` and `Macros`).
3. **Click Install.** That's it. The patcher shows the patch notes and keeps you updated from then on.

> Windows may show a SmartScreen prompt the first time since the exe is unsigned. Click "More info", then "Run anyway".

### Linux

1. [**Download the latest release zip**](https://github.com/drel-git/Turbo/releases/latest) and extract it into your MacroQuest folder (the one containing `lua` and `Macros`). Done. Grab the new zip whenever a release drops.

### In game

```
/lua run Turbo          the suite hub
```

That one window drives the whole suite. Its Actions tab handles town chores, item handouts, currency collection, turn-ins, companion tools, and even patcher updates. The commands below are still useful for hotkeys and automation, but you don't need to memorize them.

## What's Included

| Tool | Run | What it does |
| ---- | --- | ------------ |
| **Turbo** (hub) | `/lua run Turbo` | Central control panel: auto-loot on/off, pick the group looter, one-click INI setup, rulepack browser, loot gains and skipped-item tracking, TurboWares merchant sidecar, install doctor |
| **TurboLoot** | `/mac turboloot` | INI-driven corpse looting, then selling, banking, tributing, and destroying in town. [More info](https://github.com/drel-git/TurboLoot) |
| **TurboKey** | `/mac TurboKey RULE` | Pick up an item and run one command to add it to your loot rules as KEEP, SELL, BANK, TRIBUTE, DESTROY, ANNOUNCE, or IGNORE. Items can also be tagged with a click from TurboGear's item view |
| **TurboGive** | `/mac TurboGive` | Hand out and collect items between your characters using a shared give list. [More info](https://github.com/drel-git/TurboLoot/blob/main/TurboGive%20Getting%20Started.md) |
| **TurboGear** | `/lua run turbogear` | Live inventory of every boxed character in one window, BiS / upgrade views, and linked-needs announces when an item is linked in chat |
| **TurboHandins** | `/lua run Turbo/handins` | One-window PoT and GoD symbol turn-ins (`/giveplanar`, `/givediscord`), with per-character exclusion lists |
| **TurboMobs** | `/lua run TurboMobs` | NPC spawn tracker with alerts, preloaded with spawn lists for 114 Lazarus zones |
| **TurboRolls** | `/lua run TurboRolls` | Raid roll tracking: start a roll range, see everyone's rolls ranked live |
| **Utilities** | various | `turbo_bank_all` (bank everything), `turbo_collect_cash` / `turbo_collect_dc` (gather plat and Diamond Coins from your boxes), `turbo_reclaim_lotto`, an xtarget heal macro, and more |

## Feature Tour

### Looting that runs itself

TurboLoot decides what to grab from each corpse using exact item matches first, then wildcards (spells, tomes, skill-ups), then platinum value thresholds. Kill, loot, keep grinding. When your bags fill up, one command near a banker and vendor (`/mac turboloot unload`) banks, tributes, sells, and destroys everything according to your rules. Tag new items as you meet them with TurboKey instead of ever editing the INI by hand.

The Turbo hub adds the multibox glue: a toggle that turns auto-looting on and off for the whole group, a looter picker, setup helpers that wire the E3Next event hooks for you, and trackers that show what you gained and what got skipped. Stuck? `/turbodoctor` prints an install and profile health report.

On Review, right-click a skipped item with a corpse id to Nav or Go loot (same best-effort path as TurboGear linked-needs Go).

### Know your whole fleet's gear

TurboGear keeps a live inventory snapshot of every character you box, shared over the MacroQuest actor bus. Open one window and see who is wearing what, who has an upgrade sitting in the bank, and what each character still needs from the BiS lists (Lazarus lists built in, plus your own custom lists).

The headline feature: when anyone links an item in chat, TurboGear instantly announces who actually needs it, checked against every box's real inventory. No more "does anyone need this?" silence while six people alt-tab. Group, raid, and say links are listened to by default; guild and OOC listening stay off until you turn them on in TurboGear Setup.

The Spells tab also tracks each caster's researchable spells (levels 66-70), shows what is still missing across the fleet, and exports per-character want lists with one click.

### Town chores, handled

The hub turns your loot rules into one-click town workflows. Park near a banker, tribute master, and vendor and hit the **Unload** button on the Actions tab: one click banks, tributes, sells, and destroys everything in a single pass. A whole grind session's worth of bag cleanup in seconds. Prefer it piecemeal? Sell, Bank, Tribute, and Destroy each have their own button (or `/mac turboloot sell`, `bank`, `tribute`, `destroy`).

TurboWares (built into the hub) is a merchant sidecar that pops up when you're at a vendor. TurboHandins turns the PoT and GoD symbol grind into one window: it scans your bags, shows what each character can turn in, and `/giveplanar` or `/givediscord` does the rest, with an exclusion list for items you're hoarding.

### Raid night helpers

TurboRolls runs loot rolls with a live ranked window (start a range, everyone rolls with `/random`, done). TurboMobs watches for the spawns you care about, with prebuilt spawn lists covering 114 Lazarus zones so you don't have to type in mob names yourself.

## Updating

Open TurboPatcher and click **Update Now**. Running Turbo scripts notice the update starting and stop themselves on every box, updated files are installed, and you just `/lua run turbogear` (or `/lua run Turbo`) again. The patcher shows exactly what changed in each release.

## Your Settings Are Safe

Updates never touch your personal data. Character settings, the inventory cache, BiS and watch lists, and your `turboloot.ini` all live in MacroQuest's `config` folder and are left alone. Shipped default files in `config/` are only copied when you don't already have them. On top of that, the patcher backs up every file it replaces to `config/TurboPatcher_backup/` (the five newest backups are kept). Want to roll back an update? Copy the contents of the newest `config/TurboPatcher_backup/<timestamp>` folder back into your MacroQuest folder.

## Requirements

- An EverQuest EMU server that allows boxing/automation (built and tested on Project Lazarus)
- MacroQuest with E3Next (RoF2 client)
- Windows for the patcher; on Linux, extract the release zip instead. The scripts themselves run wherever MQ runs

> The core tools run on any compatible EMU server. The bundled datasets (BiS lists, the 114-zone spawn catalog, Diamond Coin collection, and the PoT/GoD turn-in lists) are tailored to Project Lazarus.

## Manual Install

Prefer not to use the patcher? Click **Code, then Download ZIP** on this page, then copy the `lua` and `Macros` folders into your MacroQuest folder. Check the `config` folder for example INI templates.

Removing Turbo is just as simple: delete the `Turbo`, `turbogear`, `turbo_lib`, and `alla_seeds` folders from `lua`, then use the release zip's contents as the exact list for the remaining `lua` and `Macros` files so you don't remove unrelated scripts. Your personal settings in `config` can stay for a future reinstall.

## Support

Found a bug or need a hand? Open an [issue](https://github.com/drel-git/Turbo/issues) or ping **dr3l** on Discord. For loot problems, turn on `logToFile=ON`, reproduce it, and send `Logs/TurboLoot.mac.log`.

## License

MIT. See [LICENSE](LICENSE).
