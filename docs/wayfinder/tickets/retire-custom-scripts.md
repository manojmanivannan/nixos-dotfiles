---
id: WF-15
title: Retire custom scripts into caelestia built-ins
label: wayfinder:build
status: open
assignee:
blocked-by: [WF-11]
triage: ready-for-agent
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

- [ ] `cava.sh`, `sysinfo.sh`, `disk.sh`, `weather.sh`, `netspeed.sh`, and
      `waybar-autoreload.sh` are removed from the repo.
- [ ] The waybar `mpris` module is gone (Media tab covers MPRIS).
- [ ] The old waybar scripts directory is removed once the tailscale script is
      relocated (coordinated with WF-13).
- [ ] Live: cava audio-spectrum, CPU/GPU/mem/temp monitoring, disk usage,
      weather, and media controls all appear in the caelestia dashboard.
- [ ] Build-time confirm recorded: whether caelestia's Cava shells out to the
      `cava` binary, and whether any remaining surface calls `notify-send`.
      (Outputs feed WF-16's `cava`/`libnotify` keep-or-drop.)
- [ ] The WF-9 build-seam check stays green.

## Blocked by

- [WF-11 — Tracer bullet: caelestia boots as the shell](tracer-bullet-caelestia-boots.md)
  (caelestia must be the running shell with its dashboard built-ins before the
  old scripts can be dropped against them).