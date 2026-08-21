---
id: WF-6
title: Shell parity — notifications, OSD, launcher, power menu
label: wayfinder:grilling
status: closed
assignee: claude
blocked-by:
  - WF-1
resolved: 2026-08-05
---

Parent map: [Replace waybar with a quickshell full shell](../MAP.md)

## Question

The chosen config replaces swaync (notifications), wofi (launcher), and wlogout
(power menu), and adds OSD. What behavior from the current tools must carry
over, and what can be dropped?

Walk each surface and decide the parity bar with the human:

- **Notifications** — swaync today gives DND toggle, notification history /
  panel, and the waybar bell widget (`swaync-client -swb`). Which of these must
  the quickshell notification center replicate? Any notification styles / Do
  Not Disturb integration (e.g. with hypridle) to preserve?
- **OSD** — volume / brightness / media popups. The current stack has no OSD
  (waybar's pulseaudio pill is the only volume UI); quickshell adds one. Any
  desired behavior, or accept the config's default?
- **Launcher** — wofi today. The quickshell launcher replaces it. Any
  frequently-used wofi behavior (drun mode, command execution, styling) to
  preserve, or accept the config's default?
- **Power menu** — wlogout today (`wlogout --protocol layer-shell`). The
  quickshell power menu replaces it. Confirm the actions (logout / reboot /
  shutdown / suspend / hibernate) and that hyprlock integration is preserved.

This is a grilling ticket — resolve in dialogue with the human; do not answer
unilaterally. Items where "accept the config's default" is the answer are fine.

Blocked by [Select the quickshell config to fork](select-config-to-fork.md) —
parity is judged against what the chosen config actually offers.

## Answer

Resolved 2026-08-05 in dialogue (grilling). Parity bar = accept caelestia's
defaults on every surface, with a small number of deliberate deviations and
keybind remaps. No surface requires building custom behavior; the bar is
"caelestia default, plus these specifics."

**Notifications — accept caelestia default.** Center, DND toggle, grouping,
expiry, fullscreen + lock-screen hiding all as-caelestia. The waybar bell
widget (`swaync-client -swb`) is replaced by caelestia's own bar status icon
(same left-click=open / right-click=toggle-DND semantics come from caelestia).
hypridle's `notify-send "You are idle!"/"Welcome back!"` simply routes through
caelestia's notification daemon — no DND↔idle integration to preserve (none
exists today). MPRIS-in-the-panel moves to caelestia's dashboard (see the
"Bonus surfaces" fog on the map).

**OSD — accept caelestia default.** Brightness/volume/mic popups as-caelestia.
No existing OSD to be parity with; pure upside.

**Launcher — accept caelestia default** (fuzzy search + Qalc calculator). No
wofi `run` mode to preserve (today is `--show drun` only). Scheme/variant
switching in the launcher is **deferred to WF-3** (theming — warm-metal is
pinned). The dead SUPER+R `hyprlauncher` binding (referenced in `bindings.lua`
but never installed) is dropped. **Flagged to WF-4:** wofi `--dmenu` is also
the menu host for the tailscale exit-node picker
(`config/.config/waybar/scripts/tailscale.sh`); retiring wofi means that
picker needs a replacement menu host — a custom-module porting concern.

**Power menu — accept caelestia default action set, with two deviations.**
Actions: shutdown / reboot / hibernate / logout / lock — **suspend is dropped**
(not wanted; caelestia's default set already excludes it, so no addition
needed). **Logout semantics must use `uwsm stop`** (clean systemd
wayland-session teardown, as today's SUPER+M `exit-prompt.sh` does), not a raw
`loginctl terminate-user $USER`. The standalone SUPER+M wofi exit-prompt is
folded into the power menu. The **lock action's target is deferred to WF-7**
(caelestia lock vs hyprlock).

**Keybinds — keep current muscle-memory, mapped onto caelestia's surfaces:**
SUPER+N → notification center, SUPER+SPACE → launcher, SUPER+ESCAPE → power
menu. Drop SUPER+R (dead) and SUPER+M (folded into power menu). Caelestia's
own default DBus-global keybinds are remapped to these.

**Seams handed to other tickets:** WF-3 (launcher scheme/variant switcher),
WF-7 (power-menu lock target), WF-4 (tailscale wofi-dmenu picker replacement).