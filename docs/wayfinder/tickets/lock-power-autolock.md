---
id: WF-14
title: Lock screen + power menu + auto-lock (retire hyprlock)
label: wayfinder:build
status: open
assignee:
blocked-by: [WF-12]
triage: ready-for-agent
---

Parent map: [Replace waybar with a quickshell full shell](../MAP.md)

Spec: [Build spec — caelestia full-shell cutover](build-spec.md) (WF-8,
Solution: Power menu; Lock screen; Idle). Decisions trace to
[WF-6](shell-parity.md) and [WF-7](lockscreen-caelestia-vs-hyprlock.md).

## What to build

Adopt caelestia's `Lock` module as the lock screen, retire hyprlock, point
hypridle's idle timeout at it, and finish the power-menu action deviations — so
locking, auto-lock, and the lock/logout power actions all run through caelestia.
This is security-critical: a broken lock means `git switch main` back to the
waybar fallback.

Adopt caelestia's `Lock` module; patch its lock PAM to authenticate by password
only — drop `pam_fprintd.so` / `pam_howdy.so` (a build-phase PAM rewrite of the
same shape caelestia's derivation already does). No fingerprint, face, or
Yubikey at the lock screen. Repoint hypridle's `on-timeout` from the current
`notify-send "You are idle!"` toast to caelestia's lock at `timeout = 600`
(~10 min); confirm the exact caelestia CLI/IPC lock subcommand at build time and
use it; `on-resume` is optional. Power menu: keep caelestia's default action set
(shutdown / reboot / hibernate / logout / lock — suspend is already excluded by
default, no addition needed) with two deviations — **logout must use
`uwsm stop`** (clean systemd wayland-session teardown, not a raw
`loginctl terminate-user`), and the **lock action targets caelestia's `Lock`
module** (no rerouting). Then retire hyprlock: disable `programs.hyprlock.enable`,
remove the `hyprlock` package, and drop its config/symlink entry.

The lock screen inherits the warm-metal scheme from the same scheme layer as the
rest of the shell (pinned by WF-12), so no separate theming work — which is why
this slice gates on WF-12 and the two are validated together.

## Acceptance criteria

- [ ] Caelestia's `Lock` module is the active lock screen; its PAM authenticates
      by password only (`pam_fprintd.so` / `pam_howdy.so` dropped).
- [ ] hypridle's `on-timeout` triggers caelestia's lock at `timeout = 600`; the
      exact caelestia CLI/IPC lock subcommand is confirmed and used.
- [ ] Power-menu logout uses `uwsm stop`; the lock action targets caelestia's
      `Lock`; suspend is absent.
- [ ] `programs.hyprlock.enable` is false; the `hyprlock` package and its
      config/symlink entry are removed.
- [ ] Live: the caelestia lock renders in warm-metal, a password unlocks it,
      ~10-min idle auto-locks, and the power-menu lock and logout actions work.
- [ ] The WF-9 build-seam check stays green (the PAM patch applies; the
      retired hyprlock package/symlink removal doesn't break evaluation).

## Blocked by

- [WF-12 — Pin warm-metal theming + sever CLI regen](pin-warm-metal-theming.md)
  (the lock inherits the same scheme; validate lock + warm-metal together
  rather than re-validating the lock twice).

## Build-phase risk to confirm here

- hypridle → caelestia lock IPC — confirm the exact caelestia CLI/IPC subcommand
  that triggers the lock screen and use it as hypridle's `on-timeout`.