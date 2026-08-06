---
id: WF-16
title: Retirement — atomic merge to main + full removal
label: wayfinder:build
status: open
assignee:
blocked-by: [WF-12, WF-13, WF-14, WF-15]
triage: ready-for-agent
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

- [ ] The manual validation gate (four surfaces + lock/autolock + tailscale/tray
      + no Qt glitches) has passed on `quickshell` before the merge.
- [ ] `quickshell` is merged to `main` in a single atomic merge.
- [ ] The merge removes the old autostart lines + keybinds, the
      `waybar`/`swaync`/`wofi`/`wlogout` symlink entries, and the old config
      directories.
- [ ] The merge removes the retired packages: `waybar`, `swaync`, `wofi`,
      `wlogout`, `hyprlock`, `inotify-tools`.
- [ ] `cava` and `libnotify` are dropped iff WF-15 confirmed them unused;
      otherwise left installed. `hypridle` and `qt6.qtwayland` are kept.
- [ ] `main` builds caelestia-only with no leftover dead config; the WF-9
      build-seam check is green on `main`.
- [ ] No permanent dual-shell runtime toggle is introduced (git history is the
      recovery net).

## Blocked by

- [WF-12 — Pin warm-metal theming](pin-warm-metal-theming.md)
- [WF-13 — Tailscale custom module](tailscale-custom-module.md)
- [WF-14 — Lock screen + power menu + auto-lock](lock-power-autolock.md)
- [WF-15 — Retire custom scripts into built-ins](retire-custom-scripts.md)
- (plus the manual live-session validation gate from
  [WF-5](cutover-fallback-strategy.md), a user action rather than a ticket)