# TurboGear

Live multi-character inventory, BiS, and linked-loot announce engine for EQEmu
(RoF2) on MacroQuest + e3next. Every boxed character shares a snapshot of its
gear over the MQ actor bus; the UI shows the whole fleet, flags BiS upgrades, and
announces who needs an item when it's linked in chat.

```
/lua run turbogear           UI (auto-launches the background responder)
/lua run turbogear_bg        headless responder only
/tgear show|hide|sync|status|perfdiag|stop     (also /turbogear)
```

## Process roles (static — no promotion/handoff)

Each box runs **one owner of the actor mailbox**: the background responder
(`turbogear_bg`). It owns actor sync and publishing. Every visible UI process is
a **viewer** — it reads the shared cache the responder writes and coordinates
announces, but never claims the mailbox. If the responder dies, the UI restarts
it; it never promotes itself. This removes a whole class of two-owners race.

- `init.lua` — entry point, run loop, command binds, perfdiag capture.
- `state.lua` / `runtime_guard.lua` — runtime flags; single-owner detection and
  the startup readiness gate.
- `engine.lua` — the actor mailbox: answers REQUESTs by publishing this box's
  snapshot, ingests peer SNAPSHOTs/DELTAs into the Store.
- `snapshot.lua` / `snapshot_delta.lua` — gather this box's inventory (lite/full)
  and compute changed-slot deltas.

## Store & storage backends

`store.lua` is the in-memory, hybrid (live + cached) source store, keyed by
`"<server>_<name>"`. It ages sources online → stale → offline and persists them
through a **pluggable backend** (selected by `Settings.storeBackend`):

- **file** (`store_backend_file.lua`, default) — a single atomic Lua-pickle
  cache with a read-merge that avoids clobbering concurrent writers.
- **sqlite** (`store_backend_sqlite.lua`) — an on-disk SQLite DB (WAL) with
  change-detected upserts and no clobber race. Enable with
  `storeBackend = "auto"` (or `"sqlite"`); it imports the legacy pickle cache
  once and falls back to the file backend if `lsqlite3` is unavailable.

Both expose the same contract: `load / reload / signature / save / status`.

**Cross-box ordering** uses a per-publisher monotonic `seq` on each snapshot/
delta (not wall-clock time), so clock skew between boxes can't drop a fresh
update or accept a stale one; it falls back to wall-clock recency for snapshots
from responders that predate the field.

## Announce path

`announcer.lua` + `needs_index.lua` + `bis*.lua` + `catalogs/lazbis.lua`. When an
item is linked, an inverted "who needs this" index resolves needers in a couple
of hash lookups. The ~34k-line catalog is lazy-loaded on first use. Background
catalog-warm and needs-index work draw down from a single per-frame budget so
warm-up can't cause a visible stutter.

## Diagnostics / perfdiag

`diagnostics.lua` keeps in-memory counters/timings (debug mode only) plus an
always-on swallowed-error tally. `/tgear perfdiag [seconds]` records a run and
writes a file including runtime status, timings, swallowed errors, a Memory &
Caches section (Lua heap, needs-index cache sizes, catalog residency), and the
recent slow-event ring. `/tgear diag` prints the live counters.

## Graceful degradation

| Missing | Behavior |
|---|---|
| `actors` library | `Engine.init` returns `no_actors`; cache-only UI still runs |
| `lsqlite3` | store silently uses the file backend |
| cache file | loads empty; store stays usable |
| `mq.ExtractLinks` | announces fall back to text-only name matching |

## Tests

Pure/core logic is unit-tested and runnable offline under LuaJIT (MQ's runtime):

```
luajit lua/tests/run_all.lua           # or: lua5.4 lua/tests/run_all.lua
```

The runner executes each `*_test.lua` in its own process and exits nonzero on
failure. The SQLite backend tests run against a real SQLite engine via an
`lsqlite3` FFI shim (`lua/tests/helpers/`), so no LuaRock is needed to run them.
