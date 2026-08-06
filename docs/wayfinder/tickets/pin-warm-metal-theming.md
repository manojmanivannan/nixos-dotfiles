---
id: WF-12
title: Pin warm-metal theming + sever CLI regen
label: wayfinder:build
status: open
assignee:
blocked-by: [WF-11]
triage: ready-for-agent
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

- [ ] A vendored static warm-metal `scheme.json` exists at the path the shell
      reads, encoding the WF-3 role mapping; `overlay`/`subtext` hexes copied
      from a real `caelestia wallpaper -p` run.
- [ ] `smartScheme` is false and `wallpaper/path.txt` is pre-populated.
- [ ] `appearance.transparency` and `background.wallpaperEnabled` are set in the
      vendored `shell.json`.
- [ ] The Nexus "Wallpaper & Style" page is removed from the page registry **and**
      the `>scheme` / `>variant` / `>wallpaper` launcher actions are dropped.
- [ ] Styling is flat: active workspace solid `m3primary`, power button solid
      `m3error`; no per-widget gradients ported.
- [ ] `shell-tokens.json` fancy levers and the blur `layerrule` on
      `caelestia-drawers` are configured.
- [ ] Live: every shell surface renders in warm-metal, and colors stay stable
      when wallpaper/UI toggles are poked (no silent regeneration).
- [ ] The WF-9 build-seam check stays green.

## Blocked by

- [WF-11 — Tracer bullet: caelestia boots as the shell](tracer-bullet-caelestia-boots.md)
  (caelestia must be the running shell before it can be re-themed).

## Build-phase risk to confirm here

- CLI regen path fully severed — confirm `Colours.setMode()` and any general
  `Actions.qml` entry don't independently regenerate `scheme.json` once the
  Nexus page and the three launcher actions are gone (they should have no UI
  trigger).