---
id: WF-4
title: Custom-module porting plan
label: wayfinder:grilling
status: closed
assignee: claude
blocked-by:
  - WF-1
  - WF-3
resolved: 2026-08-05
---

Parent map: [Replace waybar with a quickshell full shell](../MAP.md)

## Question

For each custom/unusual module that must survive the cutover, what is the
porting plan in the chosen config?

Per the standing decisions, the generic modules are adopted from the fork; the
unusual custom ones are ported, and the existing shell scripts are kept (called
from QML via Quickshell's `Process` API). Walk each module and decide:

- **tailscale** — toggle up/down, right-click switch-profile, middle-click
  exit-node picker (currently `scripts/tailscale.sh`). Which widget/host in the
  chosen config does it attach to, and how is the click routing + icon swap
  (on/off) reproduced?
- **cava** — audio spectrum (`scripts/cava.sh`, ~30fps JSON stream, auto-collapse
  when silent). Where does it sit in the new bar, and how is a continuous
  streaming exec consumed in QML?
- **sysinfo** — CPU / CPU-temp / MEM / GPU / GPU-temp / disk
  (`scripts/sysinfo.sh`, `scripts/disk.sh`). Do these become separate pills
  grouped like today, or fold into the config's existing resource widgets?
- **weather** — `scripts/weather.sh` (wttr.in, geo-located, cached). Where in
  the bar/center, tooltip behavior?

For each: target widget, script→`Process` wiring, warm-metal styling hook
(from [Theming mechanism](theming-mechanism.md)), and anything the chosen
config already provides that supersedes it.

### Items graduated from fog / surfaced by WF-3 (also in scope here)

- **Dashboard overlap.** Caelestia ships a dashboard with built-in **perf
  monitoring** and **weather** (plus MPRIS). Decide whether the dashboard's
  perf/weather displaces the custom `sysinfo.sh`/`weather.sh` porting — i.e.
  use caelestia's dashboard widgets for CPU/MEM/GPU/temp/weather instead of
  porting the scripts, and only port what the dashboard lacks (tailscale,
  cava, disk). This may shrink the porting set considerably.
- **Gradients (per-widget QML, not scheme.json).** WF-3 established the palette
  is flat — gradients are widget edits: active-workspace pill = gold→copper
  (`m3primary`→`m3secondary`), power button = terracotta→rust
  (`m3error`→`m3errorContainer`). Decide whether to keep these two gradients
  from the current waybar or accept caelestia's flat styling.
- **Workspace representation.** Keep persistent numbered 1-5, or adopt
  caelestia's default workspace widget? Decide here as part of the bar layout.
- **Sever the CLI regen path (WF-3 open risk).** While porting bar/launcher
  widgets, confirm that removing wallpaper/scheme actions from
  `shell.json` `launcher.actions` fully prevents the CLI from being invoked
  from the UI (the bar wallpaper picker and nexus Settings page may have
  independent paths) — so the vendored warm-metal `scheme.json` can't be
  overwritten.
- **Tailscale exit-node picker menu host (surfaced by WF-6).** WF-6 confirmed
  wofi is retired system-wide, but `scripts/tailscale.sh` uses
  `wofi --dmenu --prompt "Tailscale exit node"` for the middle-click exit-node
  picker. Porting the tailscale module must give that picker a new menu host
  (caelestia's launcher/overview in dmenu-equivalent mode, or a quickshell
  dialog) — the script can't keep calling `wofi` once the package is gone. Part
  of the tailscale porting plan below.

This is a grilling ticket — resolve in dialogue with the human; do not answer
unilaterally.

Blocked by [Select the quickshell config to fork](select-config-to-fork.md)
(closed) and [Theming mechanism of the chosen config](theming-mechanism.md)
(closed) — **now unblocked**.

## Resolution

Resolved in dialogue with the human on 2026-08-05. Caelestia already ships
built-in **Cava** (audio viz + beat detection), a dashboard **Performance**
tab (CPU/GPU/temp/mem/storage/battery), a **Weather** tab + small-weather,
and a **Media** tab (MPRIS) — so the porting set collapses to **tailscale
only**; everything else is dropped into the built-ins.

### Dropped into caelestia built-ins (no port)

- `scripts/cava.sh` → caelestia's built-in Cava service.
- `scripts/sysinfo.sh` (CPU/MEM/GPU/temp) → dashboard Performance tab.
- `scripts/disk.sh` → dashboard Storage card.
- `scripts/weather.sh` → dashboard Weather tab + small-weather widget.
- waybar `mpris` → dashboard Media tab.
- `scripts/netspeed.sh` → dropped; caelestia's network status-icon popout
  shows connection state only (no throughput). If throughput is missed in
  practice, extending the network delegate is a **build-time** tweak, not a
  map decision. (Note: `custom/netspeed` was already commented out in the
  waybar config in favour of the network-module tooltip.)

### The one true port — tailscale

- **Target widget:** a new `tailscale` entry in the bar `statusIcons`
  cluster (`Config.bar.statusIcons.values` + a `DelegateChooser` delegate),
  peer to network/bluetooth/battery.
- **Exit-node picker host (WF-6 wofi retirement):** a **QML popout** on the
  tailscale status-icon — no wofi, no dmenu binary. Selecting an entry calls
  `tailscale set --exit-node <name>` (or a new `--set-exit-node` subcommand)
  via Quickshell's `Process` API. The script's `wofi --dmenu` path is
  deleted.
- **Status wiring:** `tailscale.sh --status` restructured to emit
  **structured JSON** — `{ up, loginName, tailnet, exitNode, exitNodes,
  peers }` — from the single `tailscale status --json` parse it already
  performs. QML binds icon + popout to those fields. `--toggle`,
  `--switch-profile`, and `--set-exit-node` are `Process`-invoked. Tailscale
  logic stays in the script; only the output shape changes (waybar-Pango →
  structured JSON) — satisfies standing decision #6.
- **Click routing:** popout on **hover** (status + exit-node list +
  profile-switch row); **left-click = toggle up/down**, **right-click =
  switch profile** — both instant actions preserved. The old middle-click
  picker is absorbed into the hover popout (more discoverable, and matches
  caelestia's popout-on-hover pattern for network/battery).
- **Icon + warm-metal styling hook:** tailscale brand mark kept as a
  **monochrome SVG/Image, tinted by state** — up = `m3success` (olive
  `#b3bf80`), down = `m3outline` (overlay0 `#937c63`), matching the script's
  existing peer colours. Popout: labels `m3primary` (gold), values
  `m3onSurface` (text), online peers `m3success`, offline `m3outline`,
  selected exit-node row `m3secondary` (copper). All roles from the vendored
  `scheme.json`.

### Bar-styling decisions (graduated from fog / WF-3)

- **Gradients — dropped.** Accept caelestia's **flat** styling; no per-widget
  gradient QML edits. Active workspace = solid `m3primary` (gold); power
  button = solid `m3error` (terracotta). Resolves WF-3's forward-reference
  (the gold→copper and terracotta→rust gradients are not ported).
- **Workspace representation — adopt caelestia's default** workspace widget;
  do not pin persistent numbered 1-5. Clears the map's "Workspace
  representation" fog.

### Sever the CLI regen path (WF-3 open risk — resolved)

Removing `launcher.actions` is **not** sufficient: Nexus has an independent
"Wallpaper & Style" page (`WallpaperSelect.qml` → `Wallpapers.setWallpaper`
→ `caelestia wallpaper -f`; `ColourSelect.qml` → scheme regen;
`Colours.setMode()` dark/light toggle). The bar has no wallpaper/scheme
control (clean).

- **Sever set:** remove the Nexus **"Wallpaper & Style" page** from the page
  registry **and** drop the `>scheme` / `>variant` / `>wallpaper` launcher
  actions from the vendored `shell.json`. Set `appearance.transparency` and
  `background.wallpaperEnabled` directly in the vendored `shell.json`. Keep
  `wallpaper/path.txt` pre-populated (WF-3) so the `Wallpapers.qml`
  empty-path fallback never fires.
- **Build-time confirmation owed (not a decision):** that `Colours.setMode()`
  and any general `Actions.qml` entry don't independently regenerate
  `scheme.json` — but with the Nexus page and the three launcher actions
  gone, they have no UI trigger.

### Hand-off

This completes the bar-widget porting decisions. No new tickets surfaced;
the only carried-forward item is the build-time `Colours.setMode()` /
`Actions.qml` confirmation above, which belongs to the spec-first build,
not the map.