---
id: WF-10
title: Wire caelestia flake input + HM module (build-only, not launched)
label: wayfinder:build
status: closed
assignee:
blocked-by: [WF-9]
triage: done
---

Parent map: [Replace waybar with a quickshell full shell](../MAP.md)

Spec: [Build spec — caelestia full-shell cutover](build-spec.md) (WF-8,
Solution: Flake & Home-Manager integration; Vendored runtime config). Decisions
trace to [WF-2](nix-home-manager-integration.md).

## What to build

Stand up the caelestia packaging and Home-Manager integration so the flake
builds with caelestia wired in — **without yet launching it** (waybar still
autostarts; the live shell is unchanged). This is where the build-phase risks
the spec flags surface, at build/evaluation time rather than in a live session.

Prefactor first: Home-Manager modules today cannot see the flake inputs, so pass
`inputs` into `home-manager.extraSpecialArgs` (a clean change that keeps `main`
green and unblocks the caelestia HM module). Then: add the `caelestia-shell`
flake input pointed at the user's fork (upstream URL until vendoring begins);
**drop any nixpkgs `follows`** on it so caelestia's Qt6/quickshell don't hit an
ABI mismatch against this repo's `nixos-26.05` nixpkgs. Add a dedicated HM
module that enables `programs.caelestia` with the `with-cli` package, and
register it in the HM module list. Stand up the vendored caelestia config
directory plus the single-file symlinks (`shell-tokens.json`, `hypr-user.conf`,
the `scheme/` tree) alongside the HM-generated `shell.json`, and let the HM
module's systemd user service (`caelestia.service`, bound to the
graphical-session target) evaluate. Caelestia's flake already wraps its
C++/CMake build — no hand-written `mkDerivation`.

The deliverable is a green build-seam check with caelestia present in the
evaluation graph but not in the autostart. Launching is the next slice.

## Acceptance criteria

- [x] `inputs` is passed to Home-Manager modules via `extraSpecialArgs` (and
      `main` still builds green).
- [x] `caelestia-shell` is a flake input with **no** nixpkgs `follows`.
- [x] A dedicated HM module enables `programs.caelestia` with the `with-cli`
      package and is registered in the HM module list.
- [x] The vendored caelestia config directory and single-file symlinks
      (`shell-tokens.json`, `hypr-user.conf`, `scheme/`) are produced alongside
      the HM-generated `shell.json` without colliding with it.
- [x] The systemd `caelestia.service` user unit evaluates (bound to the
      graphical-session target, `QT_QPA_PLATFORM=wayland` set by the module).
- [x] The WF-9 build-seam check stays green with all of the above wired in.
- [x] No change to the live autostart — waybar/swaync still launch on a real
      session (this slice is build-only).

## Blocked by

- [WF-9 — Build-seam baseline test](build-seam-test.md) (the check must exist
  before it can be kept green).

## Build-phase risks to confirm here (not re-decisions)

- Qt6/quickshell version match — caelestia targets `nixos-unstable`; this repo
  is `nixos-26.05`. Dropping `follows` is the mitigation; confirm the build
  succeeds.
- `graphical-session.target` activation under uwsm (`withUWSM = true`) — confirm
  the user service evaluates and will activate; if it won't, note it for the
  launch slice (WF-11) where the fallback (`systemd.target` explicit, or
  `systemd.enable = false` + Hyprland `exec-once`) is applied.