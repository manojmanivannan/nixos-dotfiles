---
id: WF-2
title: Nix / home-manager integration of quickshell + the chosen config
label: wayfinder:research
status: closed
assignee: claude
blocked-by:
  - WF-1
resolved: 2026-08-05
---

Parent map: [Replace waybar with a quickshell full shell](../MAP.md)

## Question

How do quickshell and the chosen config integrate into this repo's
NixOS + Home-Manager flake?

Investigate and propose:

1. **Packaging quickshell itself** — how is `quickshell` best installed on
   NixOS (nixpkgs package? the quickshell project's own flake / overlay? build
   from source?). Note the Qt6 dependencies and any `qtwayland` / platform
   plugin requirements.
2. **Vendoring the chosen config** — per the snapshot-and-diverge decision,
   the config is copied into the repo. Where should it live
   (`config/.config/quickshell/`?) and how is it symlinked into place — follow
   the existing `home-manager/modules/dotfiles-symlinks.nix` pattern, or does
   quickshell need a different config path / launch invocation?
3. **Launching from Hyprland** — replace the current `exec-once = waybar` (and
   swaync / wofi / wlogout launches) with quickshell. What is the exact
   `exec-once` line, and are there Qt6-on-Hyprland flags needed
   (`QT_QPA_PLATFORM=wayland`, blur env, etc.)?
4. **Removing the old tools** — which packages/services to drop from
   `nixos/modules/services/services.nix` and the Hyprland config once the
   cutover ([Cutover & fallback strategy](cutover-fallback-strategy.md)) is
   done (waybar, cava-as-waybar-dep stays if reused, inotify-tools, swaync,
   wofi, wlogout).

Produce a concrete integration recipe (files to touch, derivations / packages,
env, exec-once) ready for the build. Capture findings as
`docs/wayfinder/research/nix-integration.md` and link it back here.

Blocked by [Select the quickshell config to fork](select-config-to-fork.md) —
the recipe depends on whether the chosen config ships its own flake.

## Resolution

Caelestia ships its own flake + HM module and **already wraps the C++/CMake
build** (`clangStdenv` + cmake/ninja + Qt6 + quickshell, X11/I3 disabled) — no
hand-written `mkDerivation`. Full file-by-file recipe:
[`../research/nix-integration.md`](../research/nix-integration.md).

**Integration shape:**
- **Flake input** (`flake.nix`): `caelestia-shell = { url = "github:caelestia-dots/shell/v2.2.0"; inputs.nixpkgs.follows = "nixpkgs"; };` (point at the user's fork once snapshot-and-diverge begins). Consume `inputs.caelestia-shell.packages.${system}.with-cli`.
- **HM module wiring** (`nixos/modules/nix/home-manager.nix`, verified): add `inputs` to `home-manager.extraSpecialArgs` (currently only `user stateVersion`) so HM modules can reference the flake input; add `home-manager.sharedModules = [ inputs.caelestia-shell.homeManagerModules.default ];`.
- **Enable** in a new `home-manager/modules/caelestia.nix`: `programs.caelestia.enable = true; package = inputs.caelestia-shell.packages.${system}.with-cli;` (add `./caelestia.nix` to `home-manager/modules/default.nix`).
- **Vendored runtime config** at `config/.config/caelestia/`. `shell.json` is HM-generated from `programs.caelestia.settings`; symlink `shell-tokens.json` + `hypr-user.conf` + `scheme/` via single-file `files` entries in `dotfiles-symlinks.nix` (Option A — avoids colliding with the HM-generated `shell.json`, keeps the systemd auto-restart-on-edit).
- **Launch:** HM module's `caelestia.service` systemd user unit, `WantedBy = graphical-session.target` (default resolves via HM's `wayland.systemd.target`). **Not** a Hyprland `exec-once`. `QT_QPA_PLATFORM=wayland` set by the module.
- **Keybinds** (launcher / notif-center / power) move to Hyprland DBus **global shortcuts** (`bindl = , KEY, global, <id>`); layer rules for `quickshell:*` namespaces added to `looknfeel.lua`.
- **Old-tool removal checklist** (for WF-5): `waybar`, `inotify-tools`, `wlogout` out of `services.nix`; `waybar`/`swaync`/`wofi`/`wlogout` out of the symlink map; their `exec-once` lines out of `hyprland.lua` (keep `swaybg`); `bindings.lua` wofi/wlogout/swaync binds → global shortcuts. Keep `cava` (until cava module ported), `libnotify` (until scripts audited), `qt6.qtwayland`.

**Open risks to confirm with a real `nix build` (build-phase, not blocking this
ticket's closure):**
1. Qt6/quickshell version match — caelestia targets `nixos-unstable`, this repo
   is `nixos-26.05`; `follows` may cause a Qt ABI mismatch. Mitigation: drop
   `follows` on `caelestia-shell`.
2. `graphical-session.target` activation under uwsm (`withUWSM = true`) —
   confirm, else set `systemd.target` or fall back to `systemd.enable = false`
   + `exec-once`.
3. Hyprland global-shortcut IDs + `quickshell:*` layer namespaces + hyprlua
   `global` bind helper — not in the shell README; read the fork's QML
   `GlobalShortcut` registrations + the full caelestia dots keybinds example
   (a WF-4 task).
4. Scheme file layout for a pinned warm-metal scheme — confirm by reading
   `services/Colours.qml` or running `caelestia scheme set` once (feeds WF-3).

These risks are flagged for the build hand-off; they do not block the
integration *decision*, which is settled here.