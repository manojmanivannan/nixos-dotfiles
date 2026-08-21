---
id: WF-1
title: Select the quickshell config to fork
label: wayfinder:research
status: closed
assignee: claude
blocked-by: []
resolved: 2026-08-05
---

Parent map: [Replace waybar with a quickshell full shell](../MAP.md)

## Question

Which existing quickshell config do we fork as the base for the warm-metal
full shell?

Survey the popular quickshell configs (e.g. end-4/dots-hyprland, caubut-caca,
m-100/quickshell-config, and any other prominent ones on the quickshell
showcase / GitHub) and evaluate each against these criteria, settled on the map:

1. **Full-shell** — ships bar **and** a notification center, OSD (volume /
   brightness / media popups), app launcher, and a power/logout menu (so it can
   replace swaync + wofi + wlogout, not just the bar).
2. **Themeable / neutral enough** to re-skin in warm-metal (brushed gold /
   copper / bronze on warm espresso). Strong preference for a config that
   centralizes colors (a single color/theme file or Qt properties) rather than
   baking a specific palette deep into every widget. Avoid configs hard-coded
   around a strong brand aesthetic (e.g. catppuccin pastel) that would fight
  warm-metal.
3. **Actively maintained** — recent commits, responsive maintainer, tracks
   current quickshell + Hyprland.
4. **Hyprland-compatible** — designed for Hyprland (workspaces, window rules,
   layer-shell), not Sway-first.
5. **Nix-friendly** — ships a flake / nix module, or at minimum is clean to
   vendor as a directory of QML. Note whether it expects to be installed via
   `quickshell`'s own Nix integration or just run against a config path.

Produce: a shortlist of 2-4 candidates with a one-paragraph verdict each
against the five criteria, then a single **recommendation** with rationale and
the known trade-offs. Capture findings as
`docs/wayfinder/research/select-config-to-fork.md` and link it back here.

This is the **root** ticket: Nix integration, theming mechanism, custom-module
porting, and shell-parity all wait on its resolution.

## Research findings

Resolved by a `/research` subagent on 2026-08-05. Full findings:
[`../research/select-config-to-fork.md`](../research/select-config-to-fork.md)

**Recommendation: fork `caelestia-dots/shell` (soramanew)** —
https://github.com/caelestia-dots/shell, ~10.8k stars, v2.2.0 (2026-07-16),
Hyprland-native, first-class Nix flake + Home Manager module
(`programs.caelestia`), ships every surface needed (bar + notifications + OSD +
launcher + power/logout menu + lock + dashboard).

**Trade-offs to plan around:**
1. ~26% C++/CMake build — vendoring needs a `stdenv.mkDerivation` + cmake/ninja
   derivation, not a pure-QML copy.
2. **Warm-metal theming fights the default scheme system** — colors are
   wallpaper-driven M3 (`services.smartScheme`). Pinning warm-metal requires
   forking the scheme layer (generate from a warm-metal wallpaper + freeze, or
   bypass smartScheme via `shell-tokens.json` + a custom scheme). Contained to
   one seam, but real work.
3. Fast-moving upstream (26 releases, 207 open issues) — pin tag v2.2.0 as fork
   origin; snapshot-and-diverge, no submodule.

Runner-up end-4/dots-hyprland (15k stars, most polished) loses on the two
criteria that hurt this effort most: matugen-M3 theming baked into a singleton
(harder to pin warm-metal) and a Nix path explicitly "not for NixOS".
Lightweight fallback doannc2212/quickshell-config (pure QML, easiest re-theme)
lacks a power menu and any Nix integration.

## Resolution

**Fork `caelestia-dots/shell` @ v2.2.0** (https://github.com/caelestia-dots/shell)
as the base for the warm-metal full shell. Snapshot-and-diverge from pinned tag
v2.2.0; no subtree/submodule.

Accepted trade-offs (to be handled by downstream tickets):
- **C++/CMake build** — vendoring uses a `stdenv.mkDerivation` + cmake/ninja
  derivation around caelestia's flake/HM module, not a pure-QML copy. → WF-2.
- **Warm-metal theming** — caelestia's colors are wallpaper-driven M3
  (`services.smartScheme`). Pin warm-metal by forking the scheme layer:
  generate from a warm-metal wallpaper + freeze, or bypass smartScheme and
  inject a fixed palette via `shell-tokens.json` + a custom scheme. → WF-3.
- **Fast upstream** — pin v2.2.0; pull fixes manually only when something breaks.

Confirmed by the user on 2026-08-05. This unblocks WF-2, WF-3, WF-4, WF-6, and
graduates the lockscreen fog into WF-7 (caelestia ships its own lock screen,
which the "keep hyprlock" standing decision had assumed away).