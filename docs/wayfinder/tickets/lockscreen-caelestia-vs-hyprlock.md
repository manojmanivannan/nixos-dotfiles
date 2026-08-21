---
id: WF-7
title: Lockscreen — caelestia's built-in lock vs keep hyprlock
label: wayfinder:grilling
status: resolved
assignee: claude
blocked-by: []
resolved: 2026-08-05
---

Parent map: [Replace waybar with a quickshell full shell](../MAP.md)

## Question

Caelestia ships its **own lock screen** (fprint + Howdy, integrated with its
session/power surfaces). The standing decision to "keep hyprlock/hypridle" was
made when the config base was unknown and assumed quickshell would *not* own the
lockscreen. That assumption no longer holds. Decide:

1. **Use caelestia's lock screen** and retire hyprlock — full design coherence
   (one shell, one look across every surface including lock), and it's already
   wired into caelestia's session/power flow. Trade-off: you lose hyprlock's
   existing config and re-tune auth (fprint/Howdy) inside caelestia; hypridle
   may need re-integration or replacement.
2. **Keep hyprlock/hypridle** and disable caelestia's lock — preserve the
   working lock/idle setup. Trade-off: a caelestia-themed desktop with a
   non-matching lock screen; need to disable caelestia's lock module and route
   the session/power menu's "lock" action to hyprlock instead.

Resolve in dialogue with the human (grilling). Note any hypridle dependency
(hyprlock and hypridle are often paired) and whether caelestia's session flow
expects to own idle/lock together.

Graduated from the map's "Not yet specified" fog once
[Select the quickshell config to fork](select-config-to-fork.md) resolved.

## Answer

Resolved 2026-08-05 in dialogue (grilling). **Adopt caelestia's lock screen;
retire hyprlock.** Auth is no longer a constraint (password-only is fine), so
the fprint/Howdy re-tuning cost that made option 1 expensive is gone; what
remains is the destination's whole point — one warm-metal look across every
surface including the lock — which caelestia's lock delivers for free from the
same scheme layer WF-3 pinned. Keeping hyprlock would have cost *more*
integration work (a separate warm-metal theming pass on `hyprlock.conf`, since
hyprlock is not part of caelestia's scheme layer, plus rerouting the power-menu
lock action and disabling caelestia's lock module) than adopting the lock
already wired into the session/power flow.

**Decision:**

1. **Lock screen = caelestia's `Lock` module; retire hyprlock.** No rerouting
   of the power menu — caelestia's `SessionScreen` already has a "lock" action
   that targets its own `Lock` module (resolves the "power-menu lock target →
   WF-7" deferral from
   [Shell parity](shell-parity.md)).
2. **Auth = password-only.** Patch caelestia's lock PAM to drop
   `pam_fprintd.so` / `pam_howdy.so` and auth by password. This is a
   build-phase PAM rewrite of the same shape its derivation already does
   (folded into the build risks flagged by
   [Nix / home-manager integration](nix-home-manager-integration.md), not a new
   decision ticket). No Yubikey-at-lock, no fingerprint, no face — the user
   confirmed unlock method is not a constraint.
3. **Keep `hypridle`; add auto-lock-on-idle at ~600s (10 min).** Caelestia
   ships no idle module, so `hypridle` stays as the idle daemon. Repoint
   `hypridle`'s `on-timeout` from `notify-send "You are idle!"` to caelestia's
   lock (via the `caelestia shell …` CLI/IPC — confirm the exact lock
   subcommand against caelestia's CLI at build time). `on-resume` notification
   optional. Today there is no auto-lock-on-idle (hypridle only notifies), so
   this is a deliberate upgrade, not a parity carry.
4. **Scope redraw — hyprlock is now in-scope to retire; hypridle stays.** This
   supersedes the map's standing decision #3 ("Keep hyprlock / hypridle") and
   the *Out of scope* line "Replacing hyprlock / hypridle — explicitly staying
   with them." The map is updated accordingly.

**Build directives handed to the implementation (not new decision tickets —
they are the work this decision enables, past the map's destination):**

- Patch caelestia's lock PAM to password-only (drop `pam_fprintd`/`pam_howdy`).
- Edit `config/.config/hypr/hypridle.conf`: `on-timeout = <caelestia lock IPC>`
  at `timeout = 600`; keep or drop the `on-resume` line.
- Remove `programs.hyprlock.enable` / the `hyprlock` package from
  `nixos/modules/desktop/hyprland.nix`; remove `hyprlock.u2fAuth` from
  `nixos/modules/security/yubikey.nix` (leave `greetd` / `sudo-rs` U2F intact).
  **Keep** `services.hypridle.enable` + the `hypridle` package.
- `wlogout`'s `"action": "hyprlock"` reference is moot — wlogout retires per
  [Shell parity](shell-parity.md).

**No new tickets graduate.** The PAM patch and hypridle repoint are build work,
not decisions; the map's destination is cleared decisions handed off to a
spec-first build.