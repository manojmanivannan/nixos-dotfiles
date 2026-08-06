# WF-3 Research: Theming mechanism of caelestia-dots/shell

Deep dive into how caelestia (v2.2.0) defines and distributes colors, and a
concrete re-theme map for pinning the warm-metal palette. All facts are from
primary sources (the `caelestia-dots/shell` and `caelestia-dots/cli` repos at
tag/HEAD retrieved 2026-08-05, plus the project deepwiki). Unconfirmed items
are marked.

Companion to `select-config-to-fork.md` (high-level). This file goes deep.

---

## 1. Color architecture

Caelestia's color system is split across **two repos** and **three files**:

| Layer | Owner | File (runtime) | Source in repo |
|---|---|---|---|
| Scheme data (the actual hexes) | `caelestia-cli` (Python) | `~/.local/state/caelestia/scheme.json` | `caelestia-dots/cli` `src/caelestia/utils/scheme.py`, `utils/material/generator.py` |
| Scheme loader / M3 palette QML | `caelestia-dots/shell` | `services/Colours.qml` | `services/Colours.qml` |
| Appearance + tokens (non-color) | shell C++ plugin | `~/.config/caelestia/shell.json` + `shell-tokens.json` | `plugin/src/Caelestia/Config/*.hpp` |

### 1a. Where `services.smartScheme` lives

- **Declaration:** `plugin/src/Caelestia/Config/serviceconfig.hpp:31`
  ```cpp
  CONFIG_GLOBAL_PROPERTY(bool, smartScheme, true)
  ```
  It is a **global-only** property (per-monitor overlays cannot override it).
- **Consumed in QML:** `services/Wallpapers.qml:15`
  ```qml
  readonly property list<string> smartArg: GlobalConfig.services.smartScheme ? [] : ["--no-smart"]
  ```
  `smartArg` is appended to every `caelestia wallpaper -f/-r/-p` invocation
  (Wallpapers.qml lines 33, 38, 94, 102, 117).
- **What `--no-smart` actually does** (confirmed in `caelestia-dots/cli`
  `utils/wallpaper.py:150-185` and `parser.py:123`): it **does NOT disable
  wallpaper-driven color generation**. It only skips auto-picking the
  `mode` (light/dark) and `variant` from the wallpaper's luminance. When
  `--no-smart` is passed, `set_wallpaper` keeps the current scheme's
  mode/variant and still calls `scheme.update_colours()` →
  `get_colours_for_image()` → regenerates the M3 palette from the new
  wallpaper. **Crucial correction to the prior research:** `smartScheme:
  false` does NOT freeze the palette; it only stops mode/variant flipping.

### 1b. How `caelestia scheme set` / wallpaper generates a scheme

The CLI (`caelestia-dots/cli`, Python) is the sole writer of `scheme.json`:

1. `caelestia wallpaper -f <img>` → `utils/wallpaper.py:set_wallpaper()`:
   writes the wallpaper path to `${state}/wallpaper/path.txt`, generates a
   thumbnail, then (if scheme name is `"dynamic"`) calls
   `scheme.update_colours()` → `Scheme._update_colours()`
   (`utils/scheme.py:156-174`).
2. For a `dynamic` scheme, `_update_colours` calls
   `utils.material.get_colours_for_image()` which runs
   `material/generator.py:gen_scheme()` using the **`materialyoucolor`**
   Python library (NOT `matugen`). It scores the thumbnail for a primary
   HCT color (`material/score.py`), then instantiates one of 9 M3
   `DynamicScheme` variants (`tonalspot`, `vibrant`, `expressive`,
   `fidelity`, `fruitsalad`, `monochrome`, `neutral`, `rainbow`,
   `content`) and reads every `MaterialDynamicColors` role.
3. `gen_scheme` also synthesizes the **catppuccin-style named colors**
   that match the waybar/warm-metal vocabulary
   (`generator.py:236-247`): `text`, `subtext1`, `subtext0`, `overlay0/1/2`,
   `surface0/1/2`, `base`, `mantle`, `crust` (derived from `surface` +
   `outline`). Plus `term0`-`term15` and 14 harmonized catppuccin names
   (`rosewater`…`lavender`) and 5 `klink*` colors.
4. `Scheme.save()` (`utils/scheme.py:123-134`) atomically writes
   `~/.local/state/caelestia/scheme.json`:
   ```json
   { "name": "...", "flavour": "...", "mode": "light|dark",
     "variant": "...", "colours": { "<role>": "<rrggbb>", ... } }
   ```
   Hex values are **without** the `#` prefix (e.g. `"322a21"`). The shell
   re-adds `#` on load (`Colours.qml:77`).
5. `apply_colours()` (`utils/theme.py:408`) then fans the same `colours`
   dict to Hyprland (`~/.config/hypr/scheme/current.{conf,lua}` as
   `$name = hex` lines), GTK, Qt, fuzzel, btop, cava, terminals, etc. via
   templates in `cli/data/templates/`. Toggles per `~/.config/caelestia/cli.json`
   `theme.enable*` keys.

Built-in **named** (non-dynamic) schemes ship as static `.txt` files in
`caelestia-dots/cli/src/caelestia/data/schemes/<name>/<flavour>/<mode>.txt`
(`catppuccin/mocha/dark.txt`, `caelestia/default/dark.txt`, … 14 schemes).
Format: `<roleName> <rrggbb>` per line, 109 lines. `caelestia scheme set -n
<name>` switches to a named scheme and reads colors from these files instead
of generating from a wallpaper. `dynamic` is the only name that generates
from the wallpaper.

### 1c. Scheme data shape — the M3 roles the shell reads

`services/Colours.qml` is the singleton that consumes `scheme.json`. Its
`load()` (`Colours.qml:62-79`) parses JSON, and for each key in
`scheme.colours` sets a property on the `M3Palette` component
(`Colours.qml:230-305`). The property name is `m3<key>` unless the key
starts with `term` (terminals map directly). **Only properties that exist
on `M3Palette` are applied; unknown keys are silently dropped.**

The shell therefore reads **only** these `m3*` roles from `scheme.json`
(defaults shown are caelestia's built-in pink-ish defaults, `Colours.qml:231-304`):

- **Palette key colors:** `primary_paletteKeyColor`, `secondary_paletteKeyColor`,
  `tertiary_paletteKeyColor`, `neutral_paletteKeyColor`,
  `neutral_variant_paletteKeyColor` (note: `scheme.json` uses snake_case
  `primary_paletteKeyColor`; the generator also emits camelCase
  `primaryPaletteKeyColor` for the CLI templates — the shell reads snake_case).
- **Background/surface:** `background`, `onBackground`, `surface`,
  `surfaceDim`, `surfaceBright`, `surfaceContainerLowest`,
  `surfaceContainerLow`, `surfaceContainer`, `surfaceContainerHigh`,
  `surfaceContainerHighest`, `onSurface`, `surfaceVariant`,
  `onSurfaceVariant`, `inverseSurface`, `inverseOnSurface`, `surfaceTint`.
- **Outline/shadow:** `outline`, `outlineVariant`, `shadow`, `scrim`.
- **Primary:** `primary`, `onPrimary`, `primaryContainer`, `onPrimaryContainer`,
  `inversePrimary`.
- **Secondary:** `secondary`, `onSecondary`, `secondaryContainer`,
  `onSecondaryContainer`.
- **Tertiary:** `tertiary`, `onTertiary`, `tertiaryContainer`,
  `onTertiaryContainer`.
- **Error:** `error`, `onError`, `errorContainer`, `onErrorContainer`.
- **Success** (added by `generator.py:267-276`, not from materialyoucolor):
  `success`, `onSuccess`, `successContainer`, `onSuccessContainer`.
- **Fixed (M3 light-mode artifacts, kept in dark too):** `primaryFixed`,
  `primaryFixedDim`, `onPrimaryFixed`, `onPrimaryFixedVariant`,
  `secondaryFixed`, `secondaryFixedDim`, `onSecondaryFixed`,
  `onSecondaryFixedVariant`, `tertiaryFixed`, `tertiaryFixedDim`,
  `onTertiaryFixed`, `onTertiaryFixedVariant`.
- **Terminal:** `term0`–`term15`.

**The shell does NOT read `base/mantle/crust/surface0-2/overlay0-2/text/
subtext0-1`** — those catppuccin-style names are written to `scheme.json`
but `Colours.qml` prefixes them to `m3base` etc., which don't exist on
`M3Palette`, so they're skipped. They exist solely for the CLI's
`apply_colours` template substitution (Hyprland `$base`, GTK, terminals) —
which is exactly where the existing waybar `style.css` got those same
names. This is convenient: one hand-authored `scheme.json` feeds both the
shell's M3 roles AND the Hyprland/GTK/terminal warm-metal colors with the
same vocabulary.

### 1d. How `shell.json` + `shell-tokens.json` feed the widgets (non-color)

- **`shell.json` → `GlobalConfig`** (C++ singleton, `Config` attached
  property). Holds everything EXCEPT raw color hexes: `appearance.transparency`
  (`{enabled, base, layers}` — global-only), `appearance.rounding.scale`,
  `appearance.spacing.scale`, `appearance.padding.scale`, `appearance.font.*`
  (families + per-style size/weight/italic/vaxes), `appearance.anim.durations.scale`,
  plus all subsystem config (`bar`, `notifs`, `launcher`, `session`, `services`,
  etc.). Example block in `README.md:267-348`.
- **`shell-tokens.json` → `TokenConfig`** (`Tokens` attached property,
  `plugin/src/Caelestia/Config/tokens.hpp`). Holds the **base token values**:
  `appearance.rounding.*`, `appearance.spacing.*`, `appearance.padding.*`,
  `appearance.fontSize.*`, `appearance.animDurations.*`, `appearance.curves.*`,
  and `sizes.*` (per-component dimensions). The `Appearance` singleton
  (`appearanceconfig.hpp`) multiplies base token values by the `scale`
  factors from `shell.json` to produce computed values widgets read via
  `Tokens.rounding.medium` etc.
- Both use `QQuickAttachedPropertyPropagator`, so a per-monitor overlay
  (`~/.config/caelestia/monitors/<screen>/shell{,-tokens}.json`) propagates
  to children. `CONFIG_GLOBAL_PROPERTY` flags values that can't be
  overridden per-monitor (transparency, all curves, all anim durations,
  `services.smartScheme`, etc.).
- `Colours.qml` reads `Tokens.transparency.enabled/base/layers`
  (`Colours.qml:150-152`) and applies the `layer()`/`alterColour()`
  system (lines 37-54) to every M3 color, producing `tPalette` (the
  transparent palette widgets actually bind to). `alterColour` uses
  `wallLuminance` from the C++ `ImageAnalyser` (lines 123-127) — so even
  with a frozen scheme, transparency contrast still tracks the current
  wallpaper's luminance. (Set `appearance.transparency.enabled: false` to
  make colors fully opaque and stop that tracking.)

**Loading order at startup:** `Colours.qml`'s `FileView` on
`${Paths.state}/scheme.json` (`Colours.qml:116-121`) watches the file and
re-runs `load()` on any change. `Wallpapers.qml`'s `FileView` on
`${Paths.state}/wallpaper/path.txt` (lines 85-104) will, if the file is
empty/missing, **force** `caelestia wallpaper -f <fallback>` (the bundled
`assets/wallpaper.webp`) — which regenerates `scheme.json`. So to freeze,
`path.txt` must already point at a valid file (see §2b).

Paths (from `utils/Paths.qml:15-18` and cli `utils/paths.py:17-37`):
- `Paths.state` = `$XDG_STATE_HOME/caelestia` → `~/.local/state/caelestia`
- `scheme.json` → `~/.local/state/caelestia/scheme.json`
- `wallpaper/path.txt` → `~/.local/state/caelestia/wallpaper/path.txt`
- `Paths.config` = `~/.config/caelestia` → `shell.json`, `shell-tokens.json`

---

## 2. The two pin paths

### Path (a): Generate-and-freeze

Generate a `scheme.json` once from a chosen warm-metal wallpaper via the
CLI's `materialyoucolor` path, then prevent it from being rewritten.

**What matugen-equivalent writes:** caelestia does NOT use matugen. The CLI's
`utils/material/generator.py:gen_scheme` writes `scheme.json` via
`Scheme.save()` (`utils/scheme.py:123`). The frozen artifact is
`~/.local/state/caelestia/scheme.json`.

**How to freeze it:**
1. `caelestia wallpaper -f ~/Pictures/Wallpapers/<warm-metal-image>` →
   generates `scheme.json`.
2. `caelestia scheme set -n <name>` to a **named** scheme (not `dynamic`)
   so subsequent wallpaper changes don't regenerate — but named schemes
   ship their own colors, not yours. So instead keep `dynamic` and…
3. Set `services.smartScheme: false` in `shell.json` (stops mode/variant
   auto-flip but NOT regeneration — see §1a).
4. **Manually edit `scheme.json`** to the exact warm-metal hexes you want,
   then make it read-only / vendored. Never invoke `caelestia wallpaper`
   or `caelestia scheme set` again.

**Problems:** (i) `materialyoucolor`'s 9 variants will almost never produce
the exact warm-metal hexes (`#e8c272` gold etc.) from any wallpaper — you'd
be fighting the generator and then hand-editing anyway. (ii) The
`Wallpapers.qml` fallback path force-regenerates if `path.txt` is ever
empty/missing. (iii) Any user trigger of the launcher's "change wallpaper"
or "scheme" action re-runs the CLI and overwrites your file. (iv) You inherit
the CLI's `materialyoucolor` dependency at runtime even though you no longer
want generation.

### Path (b): Bypass smartScheme (RECOMMENDED)

Disable auto-generation entirely and inject a fixed warm-metal palette by
authoring `scheme.json` directly, as a vendored file.

**What turns off auto-generation:** There is no single "disable colors"
flag. The combination is:
1. **`shell.json` → `services.smartScheme: false`** — stops the shell
   passing smart-mode/variant guesses to the CLI. (Not strictly required
   for bypass, but correct hygiene.)
2. **Pre-populate `~/.local/state/caelestia/wallpaper/path.txt`** with a
   valid path to a warm-metal wallpaper (or any image) so
   `Wallpapers.qml`'s `onLoadFailed`/empty-`onLoaded` fallback never
   fires `caelestia wallpaper -f` (which would overwrite `scheme.json`).
3. **Vendor a static `scheme.json`** (the warm-metal M3 mapping in §3
   below) into the Nix derivation, symlinked/written to
   `~/.local/state/caelestia/scheme.json`. The shell's `FileView` loads
   it and never regenerates because nothing invokes the CLI.
4. **Optionally drop the `with-cli` package variant** (or at least don't
   wire `caelestia wallpaper`/`scheme set` to any keybind/launcher
   action) so there's no path to overwrite the file. The launcher's
   scheme/wallpaper actions (`autocomplete scheme`, `autocomplete
   variant`, wallpaper grid) can be left in place — they'll call the CLI,
   which will overwrite the file, so either remove those actions from the
   vendored `shell.json` `launcher.actions` or accept that the user
   must not use them.

**Where the fixed palette goes:** `~/.local/state/caelestia/scheme.json`
(the single source the shell reads). No QML edits required for the base
palette — `Colours.qml.load()` will ingest any valid scheme.json. For
gradients (active workspace, power) you edit the relevant widget QML
(see §3 notes).

### Recommendation: **Path (b) — bypass + vendored scheme.json**

Rationale:
- **Less work:** one hand-authored JSON, no `materialyoucolor` tuning, no
  CLI build dependency for theming, no per-role fighting the generator.
- **More stable under snapshot-and-diverge:** the frozen artifact is a
  plain JSON file you own; no external Python library can overwrite it
  unless the user explicitly invokes the CLI. Path (a) keeps a runtime
  regeneration path live that path (b) severs.
- **Aligns with the warm-metal vocabulary:** `generator.py` already
  emits `base/mantle/crust/surface0-2/overlay0-2/text/subtext0-1` for
  Hyprland/GTK templates, so one scheme.json keeps the desktop-wide
  warm-metal identity (ghostty/hyprland/GTK) intact with the same names
  the existing waybar `style.css` already uses.
- **Risk:** the launcher/bar still expose wallpaper + scheme switcher UI
  that call the CLI. Mitigation: remove those actions in the vendored
  `shell.json` (`launcher.actions`) and document "do not run
  `caelestia wallpaper`/`scheme set`."

Path (a) only wins if the user later wants wallpaper-driven M3 back — but
the wayfinder destination explicitly wants a fixed palette, so (b) fits.

---

## 3. Warm-metal → M3 role mapping

Dark mode. Hexes are the warm-metal palette values (without `#`, as
`scheme.json` requires). `on*` roles are text-on-color, set to the dark
base for contrast on light accents.

### Surfaces & text (the espresso base)

| `scheme.json` key | warm-metal source | hex (rrggbb) |
|---|---|---|
| `background` | base | `322a21` |
| `surface` | base | `322a21` |
| `surfaceDim` | mantle | `2b241b` |
| `surfaceBright` | surface2 | `62523f` |
| `surfaceContainerLowest` | crust | `221b14` |
| `surfaceContainerLow` | mantle | `2b241b` |
| `surfaceContainer` | surface0 | `423627` |
| `surfaceContainerHigh` | surface1 | `4f4332` |
| `surfaceContainerHighest` | surface2 | `62523f` |
| `surfaceVariant` | surface1 | `4f4332` |
| `onBackground` | text | `f0e6d2` |
| `onSurface` | text | `f0e6d2` |
| `onSurfaceVariant` | subtext | `d8c9ac` |
| `surfaceTint` | gold | `e8c272` |
| `inverseSurface` | text | `f0e6d2` |
| `inverseOnSurface` | base | `322a21` |
| `outline` | overlay0 | `937c63` |
| `outlineVariant` | surface2 | `62523f` |
| `shadow` | black | `000000` |
| `scrim` | black | `000000` |

### Accents (the metals & patinas)

| `scheme.json` key | warm-metal source | hex | Use in shell |
|---|---|---|---|
| `primary` | gold | `e8c272` | active workspace, focus rings, primary buttons |
| `onPrimary` | base | `322a21` | text on gold |
| `primaryContainer` | bronze | `c08a4f` | gold's container variant |
| `onPrimaryContainer` | palegold | `f0dca0` | text on bronze |
| `inversePrimary` | copper | `d99069` | inverse emphasis |
| `secondary` | copper | `d99069` | secondary accent, hover states |
| `onSecondary` | base | `322a21` | text on copper |
| `secondaryContainer` | bronze | `c08a4f` | |
| `onSecondaryContainer` | palegold | `f0dca0` | |
| `tertiary` | patina | `84baa7` | tertiary accent (media, weather) |
| `onTertiary` | base | `322a21` | |
| `tertiaryContainer` | olive | `b3bf80` | |
| `onTertiaryContainer` | base | `322a21` | |
| `error` | terracotta | `e5805f` | **urgent workspace, error states** |
| `onError` | base | `322a21` | |
| `errorContainer` | rust | `c96b4a` | **power/session gradient end** |
| `onErrorContainer` | palegold | `f0dca0` | |
| `success` | olive | `b3bf80` | success toasts |
| `onSuccess` | base | `322a21` | |
| `successContainer` | patina | `84baa7` | |
| `onSuccessContainer` | base | `322a21` | |

### Fixed (M3 light-mode artifacts; kept for completeness)

| `scheme.json` key | hex |
|---|---|
| `primaryFixed` | `f0dca0` (palegold) |
| `primaryFixedDim` | `e8c272` (gold) |
| `onPrimaryFixed` | `322a21` |
| `onPrimaryFixedVariant` | `c08a4f` (bronze) |
| `secondaryFixed` | `f0dca0` |
| `secondaryFixedDim` | `d99069` (copper) |
| `onSecondaryFixed` | `322a21` |
| `onSecondaryFixedVariant` | `c08a4f` |
| `tertiaryFixed` | `f0dca0` |
| `tertiaryFixedDim` | `84baa7` (patina) |
| `onTertiaryFixed` | `322a21` |
| `onTertiaryFixedVariant` | `b3bf80` (olive) |

### Palette key colors

| key | hex |
|---|---|
| `primary_paletteKeyColor` | `e8c272` |
| `secondary_paletteKeyColor` | `d99069` |
| `tertiary_paletteKeyColor` | `84baa7` |
| `neutral_paletteKeyColor` | `937c63` (overlay0) |
| `neutral_variant_paletteKeyColor` | `62523f` (surface2) |

### Terminal (`term0`–`term15`) — warm-metal ANSI mapping

| key | role | hex |
|---|---|---|
| `term0` | bg (crust) | `221b14` |
| `term1` | rust (red) | `c96b4a` |
| `term2` | olive (green) | `b3bf80` |
| `term3` | amber (yellow) | `e6c25a` |
| `term4` | copper (blue) | `d99069` |
| `term5` | terracotta (magenta) | `e5805f` |
| `term6` | patina (cyan) | `84baa7` |
| `term7` | subtext | `d8c9ac` |
| `term8` | overlay0 | `937c63` |
| `term9` | terracotta (bright red) | `e5805f` |
| `term10` | olive bright | `b3bf80` |
| `term11` | palegold (bright yellow) | `f0dca0` |
| `term12` | gold (bright blue/copper) | `e8c272` |
| `term13` | dustyrose (bright magenta) | `d99a9a` |
| `term14` | steel (bright cyan) | `94a6ba` |
| `term15` | text | `f0e6d2` |

### Catppuccin-style names (for Hyprland/GTK/terminal templates — NOT read by shell QML)

Include these in the same `scheme.json` so `caelestia-cli`'s
`apply_colours` templates keep Hyprland/GTK/terminals on warm-metal:

| key | hex |
|---|---|
| `base` | `322a21` |
| `mantle` | `2b241b` |
| `crust` | `221b14` |
| `surface0` | `423627` |
| `surface1` | `4f4332` |
| `surface2` | `62523f` |
| `overlay0` | `937c63` |
| `overlay1` | mix(surface,#62523f,0.71) ≈ `5a4d3a` |
| `overlay2` | mix(surface,#62523f,0.86) ≈ `6a5b46` |
| `text` | `f0e6d2` |
| `subtext1` | `d8c9ac` (onSurfaceVariant) |
| `subtext0` | `937c63` (outline) |

(The `overlay1/2` and `subtext0` values are approximations of
`generator.py`'s `mix()` formula — confirm by running `gen_scheme` once
and copying the exact values, or accept these as close-enough for a
hand-authored file.)

### Where the gradients plug in (WF-4 widget work, not scheme.json)

Caelestia's M3 palette is **flat colors** — no gradient support in
`Colours.qml`. The waybar gradients are per-widget styling:

- **Active workspace = gold→copper gradient.** The workspace widget reads
  `Colours.palette.m3primary` (gold) for the active pill. To get a
  gold→copper gradient, edit the workspace pill QML (under
  `components/` bar workspaces, or `modules/nexus`) to use a
  `QtQuick.Shapes` linear gradient from `m3primary` (`#e8c272`) to
  `m3secondary` (`#d99069`). The mapping above sets primary=gold,
  secondary=copper so the gradient endpoints come from the palette for
  free.
- **Power = terracotta→rust gradient.** The session/power widget
  (`modules/nexus` session page) buttons use `m3error` for destructive
  actions. Edit the power button QML to gradient from `m3error`
  (`#e5805f` terracotta) to `m3errorContainer` (`#c96b4a` rust). Mapping
  sets error=terracotta, errorContainer=rust.

These are WF-4 (per-widget porting) tasks; the scheme.json just supplies
the endpoints.

---

## 4. Fancy levers — the token list

Confirmed from `plugin/src/Caelestia/Config/tokens.hpp` and
`appearanceconfig.hpp`. **`shell-tokens.json`** is `TokenConfig`
(`tokens.hpp:366-388`) with two top-level subobjects: `appearance` and
`sizes`. **`shell.json`** holds the `scale` factors and `transparency`
(via `GlobalConfig`/`AppearanceConfig`, `appearanceconfig.hpp:307-328`).

### `shell-tokens.json` → `appearance.*` (design tokens)

| Path | Keys | Default(s) | Source |
|---|---|---|---|
| `appearance.rounding.*` | `extraSmall, small, medium, large, largeIncreased, extraLarge, extraLargeIncreased, extraExtraLarge, full` | 4,8,12,16,20,28,32,48,maxint | `tokens.hpp:45-62` |
| `appearance.spacing.*` | same 8 levels (no `full`) | 4,8,12,16,20,28,32,48 | `tokens.hpp:64-80` |
| `appearance.padding.*` | same 8 levels (no `full`) | 4,8,12,16,20,28,32,48 | `tokens.hpp:82-98` |
| `appearance.fontSize.*` | `small, smaller, normal, larger, large, extraLarge` | 11,12,13,15,18,28 | `tokens.hpp:100-114` |
| `appearance.animDurations.*` | `small, normal, large, extraLarge, expressiveFastSpatial, expressiveDefaultSpatial, expressiveSlowSpatial, expressiveFastEffects, expressiveDefaultEffects, expressiveSlowEffects` | 200,400,600,1000,350,500,650,150,200,300 (ms) | `tokens.hpp:116-134` — **GLOBAL only** |
| `appearance.curves.*` | `emphasized, emphasizedAccel, emphasizedDecel, standard, standardAccel, standardDecel, expressiveFastSpatial, expressiveDefaultSpatial, expressiveSlowSpatial, expressiveFastEffects, expressiveDefaultEffects, expressiveSlowEffects` | each a `QList<qreal>` of bezier control points (see `tokens.hpp:31-42`) | `tokens.hpp:11-43` — **GLOBAL only** |

`shell.json` multiplies each tier by `appearance.<rounding|spacing|padding>.scale`
and `appearance.anim.durations.scale` (`appearanceconfig.hpp:21-105, 241-280`).
Fonts scale by `appearance.font.scale`.

### `shell-tokens.json` → `sizes.*` (per-component dimensions)

All `CONFIG_PROPERTY` (per-monitor overridable) unless noted. Source:
`tokens.hpp:158-332`.

| Path | Notable keys |
|---|---|
| `sizes.bar.*` | `innerWidth` (40), `windowPreviewSize` (400), `trayMenuWidth` (300), `batteryWidth` (250), `networkWidth` (320), `kbLayoutWidth` (320) |
| `sizes.dashboard.*` | `tabIndicatorHeight`, `userWidth`, `mediaWidth`, `weatherWidth`, `perfHeroCardWidth`, `perfNetworkCardWidth`, `perfBattWidth*`, … |
| `sizes.launcher.*` | `itemWidth` (600), `itemHeight` (57), `wallpaperWidth` (280), `wallpaperHeight` (200) |
| `sizes.notifs.*` | `width` (430), `image` (42, **global**), `badge` (20) |
| `sizes.osd.*` | `sliderWidth` (30), `sliderHeight` (150) |
| `sizes.session.*` | `button` (80) |
| `sizes.sidebar.*` | `width` (430) |
| `sizes.utilities.*` | `width` (430), `toastWidth` (430) |
| `sizes.lock.*` | `heightMult`, `ratio`, `centerWidth`, `largeLogoWidth`, `largeFontWidth`, `fetch*LinesHeight`, … |
| `sizes.winfo.*` | `heightMult`, `detailsWidth` (500) |
| `sizes.nexus.*` | `heightMult`, `ratio`, `minWidth` (800), `minHeight` (500), `maxNavWidth`, `maxContentWidth`, `popupWidth`, `min/maxPopupHeight`, `networkShowEthDetailWidth` |

### Transparency & blur (in `shell.json`, NOT `shell-tokens.json`)

`shell.json` → `appearance.transparency` (`appearanceconfig.hpp:294-305`,
**all global-only**):

| Key | Type | Default | Effect |
|---|---|---|---|
| `enabled` | bool | `false` | Master toggle. When true, `Colours.qml` applies `layer()` alpha to every M3 color and reloads Hyprland `layerrule blur` on `caelestia-drawers` (`Colours.qml:85-95, 149-167`). |
| `base` | qreal | `0.85` | Alpha for layer 0 (backgrounds). Reduced by 0.1 in light mode. |
| `layers` | qreal | `0.4` | Alpha for elevated layers (1+); `alterColour()` also shifts luminance by `wallLuminance`. |

**Blur is NOT a user token.** It is a Hyprland layer rule the shell toggles
on the `caelestia-drawers` namespace when `transparency.enabled` is true
(`Colours.qml:reloadHyprRules`, lines 85-95). To get blur without the
alpha-varying transparent palette, leave `transparency.enabled: false` and
add a Hyprland `layerrule blur, caelestia-drawers` (and
`layerrule ignore_alpha 0.x, caelestia-drawers`) in the Hyprland config —
the warm-metal waybar already does this pattern via Hyprland `layerrule`.

### Easing curves — confirmed

Yes, `shell-tokens.json` exposes easing via `appearance.curves.*` (12 named
curves, each a list of bezier control points, **global-only**). Combined
with `appearance.animDurations.*` (10 duration tokens, global-only) these
are the "fancy motion" levers. The README's claim that shell-tokens exposes
"animation duration/easing curves" is confirmed.

---

## Sources

- `caelestia-dots/shell` v2.2.0 (cloned): `services/Colours.qml`,
  `services/Wallpapers.qml`, `utils/Paths.qml`,
  `plugin/src/Caelestia/Config/serviceconfig.hpp`,
  `plugin/src/Caelestia/Config/tokens.hpp`,
  `plugin/src/Caelestia/Config/appearanceconfig.hpp`, `README.md`.
  https://github.com/caelestia-dots/shell
- `caelestia-dots/cli` HEAD (cloned): `src/caelestia/utils/scheme.py`,
  `utils/material/generator.py`, `utils/material/__init__.py`,
  `utils/wallpaper.py`, `utils/theme.py`, `utils/paths.py`,
  `subcommands/scheme.py`, `subcommands/wallpaper.py`, `parser.py`,
  `data/schemes/caelestia/default/dark.txt`,
  `data/schemes/catppuccin/mocha/dark.txt`.
  https://github.com/caelestia-dots/cli
- Deepwiki: https://deepwiki.com/caelestia-dots/shell/6.2-appearance-and-theming-system ,
  /5.4-wallpaper-and-color-management , /6.1-configuration-system .

### Unconfirmed / to verify at build time

- Exact `overlay1/overlay2/subtext0` hexes when hand-authoring
  `scheme.json` (the `mix()` formula in `generator.py:239-241` is
  replicable but I did not run it). Recommend running
  `caelestia wallpaper -p <warm-metal-img>` once and copying the emitted
  `colours` block as a starting point, then overwriting the M3 roles with
  the table in §3.
- Whether removing `launcher.actions` scheme/wallpaper entries fully
  prevents CLI invocation from the UI (the bar's wallpaper picker may
  have its own path) — to confirm during WF-4 porting.
- `materialyoucolor` is a Python runtime dependency of the CLI only; the
  shell (quickshell + C++ plugin) does not depend on it for theming once
  `scheme.json` is frozen. (Confirmed by reading `Colours.qml` — it only
  parses JSON — but the Nix `with-cli` variant still pulls it in.)