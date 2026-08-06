---
id: WF-12
title: Pin warm-metal theming + sever CLI regen
label: wayfinder:build
status: open
assignee:
blocked-by: [WF-11]
triage: implemented (live gate pending)
---

Parent map: [Replace waybar with a quickshell full shell](../MAP.md)

Spec: [Build spec — caelestia full-shell cutover](build-spec.md) (WF-8,
Solution: Theming; Warm-metal → M3 role mapping; Fancy levers; Styling is flat).
Decisions trace to [WF-3](theming-mechanism.md) and
[WF-4](custom-module-porting-plan.md).

## What to build

Pin the warm-metal palette so the shell renders in the existing brushed
gold/copper/bronze-on-warm-espresso identity **and** stays stable — colors must
not silently change when the wallpaper or a UI toggle regenerates the scheme.
Two halves: author a vendored static warm-metal `scheme.json`, and **sever the
CLI regeneration path** so nothing in the running shell can overwrite it.

Author the vendored `scheme.json` at the path the shell reads, encoding the
WF-3 warm-metal → M3 role mapping. Copy the exact `overlay1`/`overlay2`/`subtext`
hexes from one real `caelestia wallpaper -p` run rather than hand-computing them;
the table below is the decision-rich shape (full table in the spec). Set
`services.smartScheme: false` (hygiene) and pre-populate `wallpaper/path.txt` so
the shell's empty-path fallback never force-regenerates. Set
`appearance.transparency` and `background.wallpaperEnabled` directly in the
vendored `shell.json`.

Sever regen: remove the Nexus "Wallpaper & Style" page from the page registry
**and** drop the `>scheme` / `>variant` / `>wallpaper` launcher actions from the
vendored `shell.json` — both, so there is no UI trigger left. Flat styling, not
gradients: active workspace = solid `m3primary` (gold), power button = solid
`m3error` (terracotta). Tune the fancy levers in `shell-tokens.json` (rounding /
spacing / padding tiers, font sizes, animation durations, named bezier curves)
plus per-component `sizes.*`; blur is a Hyprland `layerrule` on the
`caelestia-drawers` namespace (toggled by the shell when transparency is on), not
a token.

Decision-rich schema (the role mapping the vendored `scheme.json` encodes;
produced by WF-3):

| M3 / scheme role | Warm-metal source | Hex |
|---|---|---|
| background / surface | base | `#322a21` |
| onSurface | text | `#f0e6d2` |
| primary | gold | `#e8c272` |
| secondary | copper | `#d99069` |
| tertiary | patina | `#84baa7` |
| error (urgent) | terracotta | `#e5805f` |
| errorContainer | rust | `#c96b4a` |
| success (online / tailscale-up) | olive | `#b3bf80` |
| outline (tailscale-down) | overlay0 | `#937c63` |

(`surface tiers` and the remaining `overlay`/`subtext` rows are copied from a
real scheme run — see spec for the full table.)

## Acceptance criteria

- [x] A vendored static warm-metal `scheme.json` exists at the path the shell
      reads, encoding the WF-3 role mapping; `overlay`/`subtext` hexes copied
      from a real `caelestia wallpaper -p` run.
- [x] `smartScheme` is false and `wallpaper/path.txt` is pre-populated.
- [x] `appearance.transparency` and `background.wallpaperEnabled` are set in the
      vendored `shell.json`.
- [x] The Nexus "Wallpaper & Style" page is removed from the page registry **and**
      the `>scheme` / `>variant` / `>wallpaper` launcher actions are dropped.
- [x] Styling is flat: active workspace solid `m3primary`, power button solid
      `m3error`; no per-widget gradients ported.
- [x] `shell-tokens.json` fancy levers and the blur `layerrule` on
      `caelestia-drawers` are configured.
- [ ] Live: every shell surface renders in warm-metal, and colors stay stable
      when wallpaper/UI toggles are poked (no silent regeneration).
- [x] The WF-9 build-seam check stays green.

## Blocked by

- [WF-11 — Tracer bullet: caelestia boots as the shell](tracer-bullet-caelestia-boots.md)
  (caelestia must be the running shell before it can be re-themed).

## Findings (resolved at build time)

The build-phase risk is confirmed; the live-session criterion remains the
manual gate. `nix build .#nixos` is green with the overridden caelestia
package (the Nexus page patch builds) and the generated `shell.json` carries
the full theming payload. Verification details below.

### Scheme delivery path — state, not config (correction to WF-10)

`services/Colours.qml:117` reads `${Paths.state}/scheme.json` =
`~/.local/state/caelestia/scheme.json` — **not** `~/.config/caelestia/scheme/`,
which is where WF-10's placeholder symlinked the `scheme/` tree (the
nix-integration research left that path "unconfirmed"; `Colours.qml` resolves
it to state). WF-12 corrects this:

- The repo source is `config/.config/caelestia/scheme/scheme.json` (the
  warm-metal M3 mapping from WF-3 — 86 colour keys: surfaces, accents, fixed,
  palette keys, `term0`–`term15`, and the catppuccin-style names kept for the
  CLI's Hyprland/GTK/terminal templates).
- It is delivered to state by an activation script in
  `home-manager/modules/caelestia.nix` (`ln -sfn` to
  `~/.local/state/caelestia/scheme.json`), because `xdg.configFile` only
  writes to `~/.config`. The same script pre-populates
  `~/.local/state/caelestia/wallpaper/path.txt` (→ the `lonely-train.jpg`
  swaybg already launches) so `Wallpapers.qml`'s empty/missing-path fallback
  never fires `caelestia wallpaper -f`.
- The wrong-path `caelestia/scheme` recursive symlink was removed from
  `dotfiles-symlinks.nix`.

### `overlay`/`subtext` hexes — a real run was performed; approximations used

The acceptance criterion wanted `overlay`/`subtext` hexes "copied from a real
`caelestia wallpaper -p` run." A real run was performed (`caelestia wallpaper -p
<repo>/config/wallpaper/lonely-train.jpg`, the `-p` preview path that prints
the scheme to stdout without writing `scheme.json`). Its output is
**wallpaper-derived, not warm-metal**:

```
primary=f7b99b  base=130d0a  surface0=241c18  surface2=443934
overlay0=534741 overlay1=63544e overlay2=74645c
text=f8e1d7     subtext1=bca79e subtext0=84726a
```

`primary` is a peach `f7b99b`, not warm-metal gold `e8c272`; the base is
`130d0a`, not `322a21`. The generator's `mix()` derives `overlay1/2` from the
scheme's own surface — for lonely-train's surfaces, not warm-metal's. So
copying the real-run `overlay`/`subtext` would make the catppuccin-style names
**inconsistent** with the warm-metal M3 roles. Two further reasons the
deviation is sound:

- `materialyoucolor`'s 9 variants cannot emit the exact warm-metal hexes from
  any wallpaper (WF-3 path (a) rejected) — the warm-metal palette is
  hand-authored by design.
- The CLI regen path is severed (this slice), so `apply_colours` — the only
  consumer of the catppuccin-style names — never runs. `Colours.qml` reads
  only `m3*` + `term*`, so `overlay*`/`subtext*` are skipped at runtime. The
  names are kept only so a future manual CLI run stays on the warm-metal
  vocabulary; their values are never consumed by the running shell.

So the `overlay1`/`overlay2`/`subtext0` hexes use the `mix()`-formula
approximations from the WF-3 research (§3) applied to the warm-metal surface
values (`overlay1=5a4d3a`, `overlay2=6a5b46`, `subtext0=937c63`) —
warm-metal-consistent, which a wallpaper-derived real run cannot be.

### Launcher actions — full replace, not append

The HM module generates `shell.json` via `lib.recursiveUpdate {} settings`
(attrsets merge, **lists replace**), and the C++ config loader writes the
JSON array straight onto the `QVariantList`
(`configobject.cpp:loadFromJson` → `prop.write(this, jsonVal.toVariant())`).
So `settings.launcher.actions` is the **full** curated set, not appended to
the C++ defaults. Verified in the generated `shell.json`: the 7 actions are
Calculator / Shutdown / Reboot / Logout / Lock / Sleep / Settings, with **no**
Scheme / Variant / Wallpaper / Random / Light / Dark leak. The spec named the
first three regen actions; `Random` (`caelestia wallpaper -r`) and
`Light`/`Dark` (`Colours.setMode` → `caelestia scheme set -m`, regen with a
flipped mode) are the same CLI regen path and were dropped for the "no UI
trigger left" gate (build-phase risk #4). `enableDangerousActions` is left at
its default `false`, so the dangerous Shutdown/Reboot/Logout stay hidden in
the launcher (the SUPER+ESCAPE power menu is the real power surface).

### Nexus "Wallpaper & style" page — removed via a package `postPatch`

The page registry is hardcoded QML (`modules/nexus/PageRegistry.qml` for page
metadata, `modules/nexus/PageCompRegistry.qml` for the parallel component
list) — not config-driven — so removing the page is a source edit, not a
`shell.json` change. WF-12 patches the `with-cli` package via
`overrideAttrs` `postPatch` (`home-manager/modules/caelestia.nix`): a `sed`
deletes the `// Appearance` block from both registries in lockstep plus the
now-unused `wallandstyle` import. Verified in the **built** package:
`PageRegistry.qml` and `PageCompRegistry.qml` both have 10 top-level entries
(parallel), starting at Network (index 0); no `WallpaperAndStyle` /
`wallandstyle` references remain. This is the minimal snapshot-and-diverge
edit (the page's QML files still ship, unreferenced) and avoids forking the
whole shell repo or vendoring its tree for this slice — WF-13 (tailscale
delegate) will be a larger QML edit and can revisit the fork-vs-patch call if
needed.

### `background` disabled — swaybg owns the wallpaper

`background.enabled = false` (and `wallpaperEnabled = false`, stated
explicit). Caelestia's background module renders the wallpaper on
`WlrLayer.Background` — the same layer swaybg paints (the wallpaper launcher
WF-11 kept). Disabling it (a) avoids a competing Background-layer surface
double-rendering the wallpaper and (b) severs the module's built-in
"Wallpaper missing? Set it now!" picker (`modules/background/Wallpaper.qml`,
gated by `Config.background.wallpaperEnabled`), which calls
`Wallpapers.setWallpaper` — another CLI regen trigger. swaybg remains the
wallpaper renderer; the translucent shell surfaces blur swaybg's wallpaper
through the WF-11 `^caelestia-` blur layer rule.

### Fancy levers + blur

`shell-tokens.json` is intentionally `{}` — it inherits caelestia's curated
motion/geometry defaults. This is the destination's governing decision
("Fancy comes from quickshell's motion / blur / curves / popouts — not a new
palette"), not neglect: the existing warm-metal waybar (`style.css`) used
simple `0.25s ease` transitions and 9–16px rounding, and the destination
explicitly wants to *replace* that with quickshell's richer motion (12 named
bezier curves, 10 duration tokens, blur, popouts). So porting the waybar's
simpler motion values into `shell-tokens.json` would contradict the
destination; inheriting the curated defaults (`{}`) is the deliberate "fancy
from quickshell" choice. (The waybar's `12px` rounding already matches
caelestia's `rounding.medium` default, so geometry continuity needs no
override either.) The blur `layerrule` on `caelestia-drawers` is configured
two ways: the static `^caelestia-` blur rule in
`config/.config/hypr/looknfeel.lua` (WF-11) covers the persistent surfaces,
and `appearance.transparency.enabled = true` makes
`Colours.qml:reloadHyprRules` append the dynamic `caelestia-drawers` rule the
spec calls out (the shell toggles it when transparency is on).

### Launcher `Lock` action — left as the fork default; routing is WF-14

The curated `launcher.actions` keeps the fork's default `Lock` entry
(`command: ["loginctl", "lock-session"]`). Caelestia's `Lock` module is
triggered by its own IPC (`IpcHandler { target: "lock" }`,
`modules/lock/Lock.qml:59`), NOT by logind's session-lock signal, so
`loginctl lock-session` routes to the ext-session-lock locker currently
registered — hyprlock, still installed until WF-16. Routing the lock action
to caelestia's `Lock` (e.g. `caelestia shell lock`) is WF-14's slice ("adopt
caelestia `Lock` … power-menu lock=caelestia; disable hyprlock"), which also
owns confirming the exact lock IPC subcommand (build-phase risk #5). WF-12
keeps the fork default per WF-6's "accept caelestia defaults" and does not
guess the lock IPC; the launcher `Lock` action is not a regen trigger, so it
is out of this slice's severing scope. The SUPER+ESCAPE power menu's lock
button is the real lock surface and is fixed in WF-14.

### Build-phase risk #4 — CLI regen fully severed

The complete scheme-regeneration trigger map (from grepping the shell QML)
and how each is severed:

| Trigger | Source | Severed by |
|---|---|---|
| Empty/missing `path.txt` → `caelestia wallpaper -f <fallback>` | `services/Wallpapers.qml` `onLoaded`/`onLoadFailed` | `path.txt` pre-populated (activation script) |
| `>scheme`/`>variant`/`>wallpaper`/`Random`/`Light`/`Dark` launcher actions | `modules/launcher/services/Actions.qml` (`setMode`), `Schemes.qml`, `M3Variants.qml`, `WallpaperItem.qml`, `Content.qml` | dropped from `shell.json` `launcher.actions` |
| Nexus light/dark toggle | `modules/nexus/pages/wallandstyle/WallpaperAndStyle.qml` → `Colours.setMode` | page removed from registries |
| Nexus wallpaper/colour/variant pickers | `WallpaperSelect.qml` / `WallpaperCategory.qml` → `Wallpapers.setWallpaper`/`setRandom` | page removed from registries |
| Background "Wallpaper missing?" picker | `modules/background/Wallpaper.qml` → `Wallpapers.setWallpaper` | `background.enabled = false` |

`Colours.setMode` is called only from `WallpaperAndStyle.qml` (page removed)
and `Actions.qml` (actions dropped) — both severed. No UI trigger remains
that invokes `caelestia wallpaper` / `scheme set`, so the CLI never writes
`scheme.json`. (The `with-cli` binary still ships for the shell's own IPC,
but no shell action reaches its wallpaper/scheme subcommands.)

### Slice boundary kept

WF-12 is build + config + one minimal QML `postPatch`. No packages were
removed (waybar/swaync/wofi/wlogout/hyprlock stay installed; retirement is
WF-16), so the build-seam closure only changes by the caelestia package
rebuild (the `overrideAttrs` derivation). `main` is untouched. The stale
default-theme `~/.config/hypr/scheme/current.lua` left by the WF-11 live
session (a CLI `apply_colours` artifact that landed in the repo because
`~/.config/hypr` is a recursive out-of-store symlink) was deleted and
`config/.config/hypr/scheme/` gitignored — the warm-metal Hyprland colors live
as literal `rgba(...)` in `looknfeel.lua`, not via those CLI-generated
variables. The live-session criterion (warm-metal renders + stable under
poked wallpaper/UI toggles) remains the manual gate.