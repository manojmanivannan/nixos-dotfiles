---
id: WF-11
title: Tracer bullet — caelestia boots as the shell
label: wayfinder:build
status: closed
assignee:
blocked-by: [WF-10]
triage: implemented (live gate completed)
---

Parent map: [Replace waybar with a quickshell full shell](../MAP.md)

Spec: [Build spec — caelestia full-shell cutover](build-spec.md) (WF-8,
Solution: Launch & environment; Keybinds; Shell surfaces). Decisions trace to
[WF-2](nix-home-manager-integration.md) and [WF-6](shell-parity.md).

## What to build

The thin end-to-end path: make caelestia actually **be** the shell on the
`quickshell` branch. Swap the Hyprland autostart off the old tools and onto the
systemd `caelestia.service`, and repoint the three muscle-memory keybinds to
Hyprland DBus global shortcuts so the launcher, notification center, and power
menu open through caelestia. This is the tracer bullet — it proves the whole
stack runs in a live session, even though the theme is still caelestia's
default, the lock screen still uses hyprlock, and tailscale isn't ported yet
(those land in later slices).

Concretely: in the Hyprland autostart handler, drop the lines launching
`waybar` (preserving the `swaybg` wallpaper launch that currently shares its
line), `swaync`, and the waybar-autoreload watcher; **keep** `nm-applet` and
`gnome-keyring-daemon`. Repoint `SUPER+N` → notification center, `SUPER+SPACE`
→ launcher, `SUPER+ESCAPE` → power menu onto Hyprland **global shortcuts**
(`bindl = , KEY, global, <id>`), reading the fork's QML `GlobalShortcut`
registrations for the exact IDs; add the `quickshell:*` / `caelestia-drawers`
layer rules to the look-and-feel config. Drop the dead `SUPER+R` (never-installed
`hyprlauncher`) and `SUPER+M` (the standalone wofi exit-prompt folds into the
power menu). Keep `hyprlock` enabled for now — lock migration is a later slice.

The deliverable is a live session where a caelestia bar renders and the four
surfaces open via the existing keys.

## Acceptance criteria

- [x] The Hyprland autostart no longer launches waybar, swaync, or
      waybar-autoreload; `swaybg`, `nm-applet`, and `gnome-keyring-daemon` still
      launch.
- [x] The systemd `caelestia.service` is what brings the shell up (not a
      Hyprland `exec-once`), bound to the graphical-session target — or, if that
      target won't activate under uwsm, the documented fallback is applied and
      noted.
- [x] `SUPER+N`, `SUPER+SPACE`, `SUPER+ESCAPE` open the caelestia notification
      center, launcher, and power menu via Hyprland global shortcuts.
- [x] `quickshell:*` / `caelestia-drawers` layer rules are in place; the dead
      `SUPER+R` and `SUPER+M` binds are gone.
- [x] Live: a caelestia bar renders, and the launcher / notification center /
      OSD / power menu each open via their key and are usable.
- [x] The WF-9 build-seam check stays green.
- [x] `main` is untouched and still a working waybar fallback (checkout +
      rebuild).

## Blocked by

- [WF-10 — Wire caelestia flake input + HM module](wire-caelestia-flake-hm.md)
  (caelestia must be packaged and wired before it can boot).

## Build-phase risks to confirm here

- Hyprland global-shortcut IDs + `quickshell:*` layer namespaces — read the
  fork's QML `GlobalShortcut` registrations and the caelestia dots keybind
  example for the exact IDs and the hyprlua `global` bind helper shape.
- `graphical-session.target` activation under uwsm — if the service from WF-10
  doesn't activate here, apply the fallback (`systemd.target` explicit, or
  `systemd.enable = false` + a Hyprland `exec-once`).

## Findings (resolved at build time)

The three build-phase risks above are confirmed; no re-decision was needed.

**Global-shortcut IDs + helper shape.** Caelestia registers its surfaces as
Hyprland DBus global shortcuts with a fixed appid of `caelestia`
(`components/misc/CustomShortcut.qml` → `GlobalShortcut { appid: "caelestia" }`),
so a surface's bind id is `caelestia:<name>`. The fork's `modules/Shortcuts.qml`
defines the names; the canonical keybind example is the caelestia dots
`hypr/hyprland/keybinds.lua`, which binds them with the hyprlua helper
`hl.dsp.global("caelestia:<name>")`. Mapped to the existing muscle memory:

| Key | Surface | Shortcut id | Source |
|---|---|---|---|
| SUPER+SPACE | launcher | `caelestia:launcher` | dots `kbLauncher` |
| SUPER+N | notification center | `caelestia:sidebar` | dots `kbShowSidebar = "SUPER + N"` (same key) |
| SUPER+ESCAPE | power / session menu | `caelestia:session` | dots `kbSession` |

The notification center is caelestia's *sidebar* drawer (`modules/sidebar/`
holds `Notif*.qml`; `Content.qml` declares `objectName: "sidebarNotifications"`).
The power menu is the *session* drawer (`modules/session/`). The launcher's
QML toggles on the shortcut's **release** (it peeks on press for caelestia's
hold-SUPER gesture); a plain Hyprland `bind` delivers both press and release
to a global shortcut, so a SUPER+SPACE tap toggles it. All three binds are
plain `hl.bind` (not `bindl`/locked) — matching the dots example — so they
do not fire on the lock screen (caelestia's `Lock` module owns that surface).

**Layer namespaces.** The fork's `components/containers/StyledWindow.qml` sets
`WlrLayershell.namespace = "caelestia-${name}"` on every surface
(`caelestia-bar`, `caelestia-drawers`, `caelestia-osd`, …), so the spec's
anticipated `quickshell:*` namespace is not what the fork uses. The
look-and-feel config targets the real `^caelestia-` pattern with a
`hl.layer_rule` (blur + `ignore_alpha`, mirroring the existing
`popups` / `popups_ignorealpha`). The shell itself toggles blur on
`caelestia-drawers` at runtime from its transparency setting
(`services/Colours.qml` → `reloadHyprRules`), appending a rule that overrides
the static default for the drawers; the static rule covers the persistent
bar/osd surfaces the shell does not self-manage.

**`graphical-session.target` under uwsm.** The caelestia HM module's service
(`nix/hm-module.nix`) is `After`/`PartOf`/`WantedBy` its `systemd.target`,
which defaults to HM's `config.wayland.systemd.target` = `graphical-session.target`
(the module's own default; `caelestia.nix` leaves it at that default).
`programs.hyprland.withUWSM = true` makes uwsm activate `graphical-session.target`
for the session, so `WantedBy` pulls `caelestia.service` up automatically. No
fallback (`systemd.target` explicit, or `systemd.enable = false` + a Hyprland
`exec-once`) is needed — the default path activates under uwsm. If a live
session ever shows the target not activating, repoint `systemd.target` in
`caelestia.nix` (the comment there flags exactly this).

**Slice boundary kept.** WF-11 is config-only — the `config/.config/hypr/*.lua`
files (out-of-store symlinks, not in the Nix evaluation graph). No packages
were removed (waybar/swaync/wofi/wlogout/hyprlock stay installed and are
retired in the WF-16 merge), so the build-seam closure is unchanged from
WF-10 and `main` is untouched. The dead `exit-prompt.sh` script is left in
place; its removal belongs to WF-16. The live-session criterion remains the
manual gate.
