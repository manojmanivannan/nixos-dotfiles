---
id: WF-5
title: Cutover & fallback strategy
label: wayfinder:task
status: resolved
assignee: claude
blocked-by: []
resolved: 2026-08-05
---

Parent map: [Replace waybar with a quickshell full shell](../MAP.md)

## Question

What is the cutover plan from the old stack to quickshell, and when do the old
tools get removed?

Decide:

1. **Fallback during the build** — keep waybar + swaync + wofi + wlogout
  installed and launchable while the quickshell shell is being built, so a
  broken quickshell doesn't leave the desktop without a bar/notifications?
  (Recommended: yes — keep them until the new shell is validated.)
2. **Switch mechanism** — how is the active shell selected during the
   transition? A Hyprland config toggle / env var / two `exec-once` profiles so
   you can flip between waybar and quickshell without a rebuild cycle?
3. **Validation criteria** — what must be true before the old stack is retired?
   (Bar renders warm-metal correctly; notifications/OSD/launcher/power menu
   all work; custom modules ported; tray behaves; no Qt/Hyprland glitches.)
4. **Retirement step** — the concrete removal (packages out of
   `nixos/modules/services/services.nix`, exec-once lines dropped, symlink
   entries removed) once criteria are met.

This is a decision ticket (a task whose resolution is a plan, not a build).
Record the agreed plan as the resolution; the actual removal happens in the
build hand-off, not here.

## Answer

**Shape — one-way migration with a temporary toggle.** The repo ends
caelestia-only, matching the destination (retire waybar/swaync/wofi/wlogout +
hyprlock). No permanent dual-shell escape hatch is kept in the repo; git
history is the recovery net.

**Switch mechanism — git branch as the toggle.** `main` = stable waybar stack
(the fallback); `quickshell` = caelestia work. The flip is `git switch
quickshell` + rebuild; fallback is `git switch main` + rebuild. The branch
*is* the temporary toggle, removed at retirement by merging `quickshell` →
`main`.

**Build fallback — cold-turkey once caelestia boots.**

1. On `quickshell` (forked from `main`), waybar still launches at first
   (inherited).
2. Build caelestia; test it by launching manually alongside waybar.
3. **Once caelestia boots reliably**, swap the branch autostart to the systemd
   `caelestia.service` (per WF-2) and remove the waybar/swaync/wofi/wlogout
   `exec_cmd` lines + their keybinds (`SUPER+SPACE` wofi, `SUPER+N`
   swaync-client, `SUPER+ESCAPE` wlogout, and the `wofi --dmenu` exit prompt)
   from the branch → cold-turkey on `quickshell`. From here `main` is the only
   fallback (checkout + rebuild), not a live runtime toggle.
4. Iterate on caelestia on `quickshell`; fall back to `main` anytime.

**Validation gate — all four must pass on `quickshell` before merge:**

- **Four shell surfaces** render in warm-metal and work: bar; notifications +
  `SUPER+N`/control center; OSD (volume/brightness/media); launcher +
  `SUPER+SPACE` + scheme-switcher (WF-3); power menu.
- **Lock screen + auto-lock** (added by WF-7, security-critical): caelestia
  `Lock` authenticates (password-only PAM) **and** hypridle auto-lock-on-idle
  (~600s) triggers it. A broken lock means `checkout main`.
- **Custom modules + tray**: tailscale (toggle + exit-node picker), cava
  spectrum, GPU/CPU/MEM/disk monitoring, weather — ported (WF-4) and behaving;
  system tray behaves.
- **No Qt6/Hyprland glitches**: blur `layerrule`, layer-shell positioning,
  workspace animations, Hyprland global shortcuts firing (the WF-2 build-risk
  surface).

**Retirement — atomic merge + full removal.** Gate passes → merge `quickshell`
→ `main`. That single merge removes:

- old launch lines + keybinds in `config/.config/hypr/` (`hyprland.lua`,
  `bindings.lua`, `scripts/exit-prompt.sh`);
- the `waybar`/`wlogout`/`swaync`/`wofi` symlink entries in
  `home-manager/modules/dotfiles-symlinks.nix`;
- the old config dirs `config/.config/{waybar,swaync,wofi,wlogout}/`;
- retired packages from `nixos/modules/services/services.nix`: `waybar`,
  `swaync`, `wofi`, `wlogout`, `hyprlock`, `inotify-tools` (the
  waybar-autoreload watcher's dep).

`cava` + `libnotify` are **candidate drops** at retirement, with final keep/drop
**confirmed at build time**: WF-4 moved `cava.sh` into caelestia's built-in
Cava service (does that service still shell out to the `cava` binary, or is it
pure Qt?) and replaced the `notify-send`-based tailscale picker with a QML
popout (the known `libnotify` consumer is gone — confirm no other script or
caelestia surface calls `notify-send`). Until those two build-time checks land,
leave both packages installed; drop them in the same retirement merge if
confirmed unused. No soak period; `git revert` is the recovery net, matching
cold-turkey.

**Cross-references:** launch path (systemd `caelestia.service`, global
shortcuts) → WF-2; warm-metal validation + scheme-switcher → WF-3; custom
module porting (incl. cava/libnotify retention) → WF-4; lock screen + auto-lock
→ WF-7. The actual removal is executed in the build hand-off, not in this map.