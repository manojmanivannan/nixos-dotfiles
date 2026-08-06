---
id: WF-14
title: Lock screen + power menu + auto-lock (retire hyprlock)
label: wayfinder:build
status: implemented (live gate pending)
assignee:
blocked-by: [WF-12]
triage: implemented (live gate pending)
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

- [x] Caelestia's `Lock` module is the active lock screen; its PAM authenticates
      by password only (`pam_fprintd.so` / `pam_howdy.so` dropped).
      — PAM rewrite in caelestia.nix postPatch + `lock.enableFprint/enableHowdy
      = false`; "active lock screen" itself is the live gate below.
- [x] hypridle's `on-timeout` triggers caelestia's lock at `timeout = 600`; the
      exact caelestia CLI/IPC lock subcommand is confirmed and used.
      — Confirmed subcommand `caelestia shell lock lock`; it is non-functional in
      this Nix setup (qs not on PATH; `qs -c caelestia` resolves a config path
      that doesn't exist; IPC socket pathId wouldn't match the running instance
      launched with `-p <store>`). Per the build-phase note below, hypridle uses
      `loginctl lock-session`, which triggers the *same* caelestia `Lock` module
      through caelestia's SessionManager logind bridge. Decision: owner-approved
      (recommended option).
- [x] Power-menu logout uses `uwsm stop`; the lock action targets caelestia's
      `Lock`; suspend is absent.
      — `session.commands.logout = [ "uwsm" "stop" ]` + launcher Logout; launcher
      Lock kept as `loginctl lock-session` (routes to caelestia `Lock` now that
      hyprlock is retired); session menu keeps caelestia's default set (suspend
      already absent). Note: caelestia's session (power) menu has no lock button
      at all — `SessionCommands` (sessionconfig.hpp) defines only
      logout/shutdown/hibernate/reboot — so the spec's "lock action" is the
      launcher's `Lock` action above, which targets caelestia's `Lock`.
- [x] `programs.hyprlock.enable` is false; the `hyprlock` package and its
      config/symlink entry are removed.
      — `programs.hyprlock.enable` and the `hyprlock` package removed from
      nixos/modules/desktop/hyprland.nix; `hyprlock.u2fAuth` removed from
      nixos/modules/security/yubikey.nix. No hyprlock config/symlink entry ever
      existed in the repo (hyprlock used module defaults), so nothing to drop
      there.
- [ ] Live: the caelestia lock renders in warm-metal, a password unlocks it,
      ~10-min idle auto-locks, and the power-menu lock and logout actions work.
- [x] The WF-9 build-seam check stays green (the PAM patch applies; the
      retired hyprlock package/symlink removal doesn't break evaluation).

## Blocked by

- [WF-12 — Pin warm-metal theming + sever CLI regen](pin-warm-metal-theming.md)
  (the lock inherits the same scheme; validate lock + warm-metal together
  rather than re-validating the lock twice).

## Build-phase risk to confirm here

- hypridle → caelestia lock IPC — confirm the exact caelestia CLI/IPC subcommand
  that triggers the lock screen and use it as hypridle's `on-timeout`.

  **Confirmed:** `caelestia shell lock lock` → `qs -c caelestia ipc call lock
  lock` → `Lock.qml` `IpcHandler { target: "lock" }` `lock()` →
  `WlSessionLock.locked = true` (modules/lock/Lock.qml; traced through
  caelestia-cli src/caelestia/subcommands/shell.py).

  **But non-functional in this Nix setup**, so not used as the hypridle trigger:
  1. `qs` is not on the user PATH — quickshell is a `buildInputs` of the
     caelestia-shell package, not a `propagatedBuildInputs`/runtimeDeps entry,
     so the CLI's `subprocess.check_output(["qs", …])` can't find it. (The
     launcher's `caelestia shell …` actions are latent-broken for the same
     reason — out of scope for WF-14 to fix.)
  2. `qs -c caelestia` resolves `~/.config/quickshell/caelestia/shell.qml`
     (quickshell `locateNamedConfig`, src/launch/command.cpp), which doesn't
     exist — the shell's QML ships in the nix store at
     `$out/share/caelestia-shell`, installed via cmake `INSTALL_QSCONFDIR`, not
     into a `quickshell/` XDG config dir. No symlink wires the store config
     under `~/.config/quickshell/caelestia`.
  3. Even with both fixed, the running shell launches with
     `-p <store>/share/caelestia-shell`, so its IPC socket pathId is
     `md5("<store>/share/caelestia-shell/shell.qml")`
     (src/launch/launch.cpp), while `-c caelestia` would hash a different
     config-file path string — the IPC client would open a different socket and
     never reach the running instance. Making them match needs overriding the
     shell's launch flags to `-c caelestia` + symlinking the store config —
     substantial scope beyond WF-14.

  **Used instead:** `loginctl lock-session` (config/.config/hypr/hypridle.conf).
  This emits logind's `Lock` signal on the session, which caelestia's
  `SessionManager` connects to (`sessionmanager.cpp` `handleLockRequested` →
  `lockRequested`) and `IdleMonitors.qml` bridges to
  `lock.lock.locked = true` — the same caelestia `Lock` module, reached through
  the standard, dependency-free session-lock IPC that also keeps logind lock
  state coherent. Retiring hyprlock (this slice) is precisely what makes this
  route exclusively caelestia's. Owner-approved deviation from the literal
  "use the CLI subcommand" wording; see the lock-trigger decision in the
  implementation session.

## Implementation notes

- **Caelestia ships an idle module** (`modules/IdleMonitors.qml`, Quickshell
  `IdleMonitor`s) with default timeouts that lock at 180s, dpms-off at 300s,
  and suspend-then-hibernate at 600s (`generalconfig.hpp` `GeneralIdle.timeouts`).
  The build spec assumed "Caelestia ships no idle module" — that is incorrect
  against v2.2.0. Left active, the 180s lock would pre-empt the 600s auto-lock
  (user story #13 wants ~10 min, not 3) and the 600s suspend-then-hibernate would
  suspend the box as hypridle locks it. `general.idle.timeouts = []` in
  caelestia.nix disables every caelestia IdleMonitor so hypridle is the sole
  idle daemon, exactly as WF-14 mandates. `lockBeforeSleep` (default true) is
  left untouched — it fires on logind `PrepareForSleep` independent of
  `timeouts`, so a manual suspend still locks first. Flag for the live gate:
  confirm no caelestia idle action fires alongside hypridle.