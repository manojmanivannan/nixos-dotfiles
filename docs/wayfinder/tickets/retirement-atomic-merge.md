---
id: WF-16
title: Retirement — atomic merge to main + full removal
label: wayfinder:build
status: cleanup done (merge deferred)
assignee:
blocked-by: [WF-12, WF-13, WF-14, WF-15]
triage: merge deferred per user — removals landed on quickshell, merge to main not yet taken
---

Parent map: [Replace waybar with a quickshell full shell](../MAP.md)

Spec: [Build spec — caelestia full-shell cutover](build-spec.md) (WF-8,
Solution: Cutover & fallback; Retirement). Decisions trace to
[WF-5](cutover-fallback-strategy.md).

## What to build

The contract slice. Once the manual live-session validation gate passes on
`quickshell`, merge `quickshell` → `main` in a single atomic merge that removes
every leftover of the old stack, so `main` ends caelestia-only with no dead
config. This is the one-way point — git history (`git revert` after merge,
`main` before) is the recovery net; no permanent dual-shell toggle is kept.

The merge removes: the old autostart lines + keybinds in the Hyprland config;
the `waybar` / `swaync` / `wofi` / `wlogout` symlink entries; the old config
directories (`waybar`, `swaync`, `wofi`, `wlogout`); and the retired packages
from the system / HM package lists — `waybar`, `swaync`, `wofi`, `wlogout`,
`hyprlock`, and `inotify-tools` (the waybar-autoreload watcher's dep). `cava`
and `libnotify` are dropped in this same merge **iff** WF-15 confirmed them
unused; until that confirmation lands, leave both installed. Keep `hypridle` and
`qt6.qtwayland`.

This slice is gated on the **manual** validation gate (performed by the user on a
real Hyprland session, not by the build-seam check): the four shell surfaces
render warm-metal and work; caelestia `Lock` authenticates and hypridle
auto-lock-on-idle triggers it; tailscale (toggle + exit-node picker) and the
system tray behave; no Qt6/Hyprland glitches (blur layerrule, layer-shell
positioning, workspace animations, global shortcuts firing).

## Acceptance criteria

- [x] The manual validation gate (four surfaces + lock/autolock + tailscale/tray
      + no Qt glitches) has passed on `quickshell` before the merge.
      (Confirmed by the user 2026-08-06.)
- [ ] `quickshell` is merged to `main` in a single atomic merge.
      (**Deferred per user request 2026-08-06** — only cleanup was requested.)
- [x] The removal of the old autostart lines + keybinds (WF-11), the
      `waybar`/`swaync`/`wofi`/`wlogout` symlink entries, and the old config
      directories is done on `quickshell` (this slice; the merge itself is the
      deferred step above).
- [x] The retired packages are removed from `quickshell`: `waybar`, `swaync`,
      `wofi`, `wlogout`, `inotify-tools`. `hyprlock` was already retired in
      WF-14.
- [x] `cava` is dropped (WF-15 confirmed caelestia's Cava is a native
      `CavaProvider`, no `cava` binary); `libnotify` is kept (caelestia's
      Wrapper.qml/Picker.qml + tailscale.sh call `notify-send`).
      `hypridle` and `qt6.qtwayland` are kept.
- [ ] `main` builds caelestia-only with no leftover dead config; the WF-9
      build-seam check is green on `main`. (Pending the merge; the WF-9
      build-seam check IS green on `quickshell` after cleanup — `nix build
      .#nixos` exits 0.)
- [x] No permanent dual-shell runtime toggle is introduced (git history is the
      recovery net).

## Status — 2026-08-06

The full removal landed on `quickshell` (commit below); the WF-9 build-seam
stays green on `quickshell` post-removal. The one-way merge to `main` was
**not** taken — the user asked for cleanup only. `main` still carries the
old waybar stack as the fallback branch. Reopen by merging `quickshell` →
`main` in a single atomic merge (fast-forward or `--no-ff` merge commit) and
confirming the WF-9 build-seam is green on `main`.

## Blocked by

- [WF-12 — Pin warm-metal theming](pin-warm-metal-theming.md)
- [WF-13 — Tailscale custom module](tailscale-custom-module.md)
- [WF-14 — Lock screen + power menu + auto-lock](lock-power-autolock.md)
- [WF-15 — Retire custom scripts into built-ins](retire-custom-scripts.md)
- (plus the manual live-session validation gate from
  [WF-5](cutover-fallback-strategy.md), a user action rather than a ticket)