---
id: WF-3
title: Theming mechanism of the chosen config
label: wayfinder:research
status: closed
assignee: claude
blocked-by:
  - WF-1
resolved: 2026-08-05
---

Parent map: [Replace waybar with a quickshell full shell](../MAP.md)

## Question

How does the chosen config define and apply colors, and where does the
warm-metal palette plug in?

Investigate:

1. **Color definition** — does the config centralize colors in a single file
   (e.g. `colors.conf`, `Theme.qml`, a `QtObject` of properties), scatter them
   per-widget, or read them from an external source (wallpaper, matugen,
   material-color-utilities)?
2. **Re-theme surface** — exactly which file(s) / properties must change to
   swap the palette to warm-metal? Is it a clean single-point swap, or does
   warm-metal need to be threaded through many widgets?
3. **Warm-metal mapping** — map the current waybar `style.css` palette
   (`base #322a21`, `mantle`, `crust`, `surface0-2`, `text #f0e6d2`, `gold
   #e8c272`, `copper #d99069`, `bronze #c08a4f`, `terracotta #e5805f`, etc.)
   onto the config's color roles (bg, surface, text, accent, urgent, etc.).
4. **Fancy levers** — what does the config expose for the "fancy" budget
   (blur, corner radius, animation curves, hover transitions)? Confirm these
   are tunable without rewriting widgets.

Produce a re-theme map: the file(s) to edit, the property→warm-metal mapping,
and the fancy-lever knobs. Capture findings as
`docs/wayfinder/research/theming-mechanism.md` and link it back here.

Blocked by [Select the quickshell config to fork](select-config-to-fork.md).
Unblocks the per-widget styling fog and the custom-module porting plan.

## Resolution

Caelestia's color system spans two repos + three files; the shell reads only
`~/.local/state/caelestia/scheme.json` (M3 roles) via `services/Colours.qml`.
Full findings + the complete warm-metal→M3 role mapping table:
[`../research/theming-mechanism.md`](../research/theming-mechanism.md).

**Recommended pin path: (b) Bypass + vendored `scheme.json`.** Author a static
warm-metal `scheme.json` and vendor it to `~/.local/state/caelestia/scheme.json`;
set `services.smartScheme: false` (hygiene only); pre-populate
`wallpaper/path.txt` so the shell's empty-path fallback never force-regenerates;
and sever the CLI regeneration path by removing wallpaper/scheme actions from
`launcher.actions` (and not running `caelestia wallpaper`/`scheme set`).
Rejected path (a) generate-and-freeze: caelestia uses `materialyoucolor` (not
matugen), whose 9 variants won't hit exact warm-metal hexes, and it leaves a
live regeneration path any UI action can trigger.

**Key correction to prior research:** `services.smartScheme` does NOT control
whether colors are wallpaper-driven — it only auto-picks light/dark + variant.
The dynamic scheme regenerates the full M3 palette from the wallpaper
regardless. So freezing requires the bypass above, not just `smartScheme: false`.

**Warm-metal → M3 roles (gist):** background/surface = base `#322a21`, surface
tiers = mantle/crust/surface0-2, onSurface = text `#f0e6d2`, primary = gold
`#e8c272`, secondary = copper `#d99069`, tertiary = patina `#84baa7`, error =
terracotta `#e5805f` (urgent), errorContainer = rust `#c96b4a` (power gradient
end), success = olive `#b3bf80`. Bonus: `caelestia-cli`'s generator already
emits the catppuccin-style names (`base/mantle/crust/surface0-2/...`) into
`scheme.json` for Hyprland/GTK/terminal templates — the same vocabulary the
existing waybar `style.css` uses — so one vendored `scheme.json` keeps the
desktop-wide warm-metal identity intact. (Shell QML ignores those names; it
reads only `m3*` + `term*` keys.)

**Gradients are NOT in the palette** — `Colours.qml` is flat colors. The active
workspace gold→copper gradient and the power terracotta→rust gradient are
per-widget QML edits (using primary→secondary and error→errorContainer
endpoints) → folded into WF-4.

**Fancy levers confirmed:** `shell-tokens.json` exposes rounding/spacing/padding
(8 tiers each), font sizes (6), animation durations (10, global-only), and
easing curves (12 named bezier lists, global-only) under `appearance.*`, plus
per-component `sizes.*`. Transparency (`enabled/base/layers`) is in `shell.json`
under `appearance.transparency` (global-only). **Blur is not a token** — it's a
Hyprland `layerrule` on `caelestia-drawers` the shell toggles when transparency
is enabled; can also be added directly in the Hyprland config.

**Open risk (→ WF-4):** whether removing `launcher.actions` scheme/wallpaper
entries fully prevents the CLI being invoked from the UI (the bar wallpaper
picker and nexus Settings page may have independent paths) — confirm during
widget porting. Also: exact `overlay1/overlay2/subtext0` hexes should be copied
from one `caelestia wallpaper -p` run rather than hand-computed.