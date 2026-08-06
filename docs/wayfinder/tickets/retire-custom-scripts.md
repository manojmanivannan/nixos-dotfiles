---
id: WF-15
title: Retire custom scripts into caelestia built-ins
label: wayfinder:build
status: implemented (live gate complete)
assignee:
blocked-by: [WF-11]
triage: implemented (live gate complete)
---

Parent map: [Replace waybar with a quickshell full shell](../MAP.md)

Spec: [Build spec — caelestia full-shell cutover](build-spec.md) (WF-8,
Solution: Custom modules — port tailscale only; drop the rest into built-ins).
Decisions trace to [WF-4](custom-module-porting-plan.md).

## What to build

Drop the custom waybar scripts whose functionality caelestia's built-ins already
cover, so the dashboard surfaces (cava, system monitoring, disk, weather, media)
come from caelestia rather than from the old scripts. Tailscale is the one
script kept — it is ported in WF-13, not here. This slice is mostly deletion
plus a build-time keep/drop check whose answers feed the retirement merge.

Drop `cava.sh` (→ caelestia built-in Cava service), `sysinfo.sh` (→ dashboard
Performance tab: CPU/GPU/temp/mem), `disk.sh` (→ dashboard Storage card),
`weather.sh` (→ dashboard Weather tab + small-weather widget), `netspeed.sh`
(→ dropped; caelestia's network status-icon popout shows connection state only,
no throughput — if throughput is missed, extending the network delegate is a
build-time tweak), and the `waybar-autoreload.sh` watcher (irrelevant once
waybar is gone). Remove the waybar `mpris` module (the dashboard Media tab
covers MPRIS). Remove the now-dead waybar scripts directory once the kept
tailscale script has been relocated to wherever the vendored caelestia config's
scripts live (WF-13 handles the tailscale script's new home).

Build-time confirm: does caelestia's built-in Cava still shell out to the `cava`
binary? Does any remaining script or caelestia surface still call `notify-send`
once the tailscale picker is a QML popout (WF-13)? Those two answers determine
whether `cava` and `libnotify` survive the retirement merge (WF-16) — leave both
installed until then.

## Acceptance criteria

- [x] `cava.sh`, `sysinfo.sh`, `disk.sh`, `weather.sh`, `netspeed.sh`, and
      `waybar-autoreload.sh` are removed from the repo.
- [x] The waybar `mpris` module is gone (Media tab covers MPRIS).
- [x] The old waybar scripts directory is removed once the tailscale script is
      relocated (coordinated with WF-13).
- [x] Live: cava audio-spectrum, CPU/GPU/mem/temp monitoring, disk usage,
      weather, and media controls all appear in the caelestia dashboard.
- [x] Build-time confirm recorded: whether caelestia's Cava shells out to the
      `cava` binary, and whether any remaining surface calls `notify-send`.
      (Outputs feed WF-16's `cava`/`libnotify` keep-or-drop.)
- [x] The WF-9 build-seam check stays green.

## Build-time confirm — recorded (feeds WF-16)

Inspected the pinned `caelestia-shell` v2.2.0 source in the Nix store
(`caelestia-shell-1.0.0` + `caelestia-qml-plugin`).

- **`cava` → DROP.** Caelestia's built-in Cava is a native in-process C++ QML
  type `CavaProvider` (subclass of `AudioProvider`, exports `bars` int +
  `values` double-list; declared in `caelestia-services.qmltypes`). It does
  **not** shell out to the `cava` binary: `services/Audio.qml` instantiates
  `CavaProvider` with no `Process`/binary call, the `caelestia-shell` package
  has no `cava` runtime dependency, and `caelestia.nix` adds none. The `cava`
  system package was only the waybar `custom/cava` pill's dependency; with that
  pill retired, `cava` is unused — WF-16 can drop it.
- **`libnotify` → KEEP.** Caelestia itself shells out to `notify-send` via
  `Quickshell.execDetached` in `modules/dashboard/Wrapper.qml` (profile-picture
  change success/failure toasts) and `modules/areapicker/Picker.qml` (screenshot
  taken). The ported tailscale script (`config/.config/caelestia/scripts/
  tailscale.sh`) also calls `notify-send`, guarded by `command -v` so a
  missing binary degrades gracefully. WF-16 must keep `libnotify`.

`inotify-tools` (the `waybar-autoreload.sh` watcher's dep) is now unused once
`waybar-autoreload.sh` is deleted; WF-16 drops it as already planned.

## Blocked by

- [WF-11 — Tracer bullet: caelestia boots as the shell](tracer-bullet-caelestia-boots.md)
  (caelestia must be the running shell with its dashboard built-ins before the
  old scripts can be dropped against them).