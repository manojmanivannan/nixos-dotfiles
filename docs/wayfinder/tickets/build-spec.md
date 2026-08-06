---
id: WF-8
title: Build spec — caelestia full-shell cutover
label: wayfinder:spec
status: open
assignee:
blocked-by: []
triage: ready-for-agent
---

Parent map: [Replace waybar with a quickshell full shell](../MAP.md)

This is the **build hand-off** — the spec-first build the wayfinder map's
destination pointed at. It synthesizes the cleared decisions from WF-1
through WF-7 into a single spec ready for an implementation agent. It does
not re-open any decision; every "why" is in the closed tickets linked below.

## Problem Statement

My desktop shell today is a loose assembly of five separate Wayland tools —
waybar (bar), swaync (notifications), wofi (launcher), wlogout (power menu),
and hyprlock (lock screen) — plus a handful of custom waybar scripts. Each
tool is themed independently, none of them share motion, blur, or popout
behavior, and maintaining the warm-metal look across all of them is fiddly
and inconsistent. I want one coherent, warm-metal shell with modern motion
(blur, curves, popouts) across every surface — bar, notifications, OSD,
launcher, power menu, and lock screen — and I want to stop maintaining five
separate tools to get it.

## Solution

Replace the whole stack with a single **quickshell-based full shell**: a fork
of `caelestia-dots/shell` @ v2.2.0, re-themed to my warm-metal palette, owning
the bar, notifications, OSD, launcher, power menu, **and** the lock screen.
swaync, wofi, wlogout, and hyprlock are retired; hypridle stays as the idle
daemon and gains auto-lock-on-idle pointed at caelestia's lock. Caelestia's
built-in widgets cover cava, system monitoring, disk, weather, and media; the
**only** custom module ported is tailscale. Everything ships through the
existing NixOS + Home-Manager flake. The `quickshell` git branch is the
toggle (main = waybar fallback); once the shell validates, it merges to
`main` and the old packages, symlinks, and config dirs are removed in that
same merge.

## User Stories

1. As the desktop user, I want a single shell owning the bar, notifications,
   OSD, launcher, power menu, and lock screen, so that I no longer maintain
   five separate Wayland tools.
2. As the desktop user, I want every shell surface rendered in my warm-metal
   palette (brushed gold/copper/bronze on warm espresso), so that the desktop
   reads as one coherent theme.
3. As the desktop user, I want the shell's motion — blur, rounded corners,
   easing curves, popouts — to come from quickshell, so that the desktop feels
   modern without me hand-animating widgets.
4. As the desktop user, I want the warm-metal palette pinned and stable, so
   that colors never silently change when the wallpaper or a UI toggle
   regenerates the scheme.
5. As the desktop user, I want the existing shell-key muscle memory preserved
   (SUPER+N notifications, SUPER+SPACE launcher, SUPER+ESCAPE power menu), so
   that I don't relearn keys.
6. As the desktop user, I want a working app launcher with fuzzy search, so
   that I can launch applications as I do today with wofi.
7. As the desktop user, I want a notification center with a Do-Not-Disturb
   toggle and history, so that I can manage notifications as I do today with
   swaync.
8. As the desktop user, I want on-screen-display popups for volume, brightness,
   and media, so that I get visual feedback for those changes (which I lack
   today).
9. As the desktop user, I want a power menu offering shutdown, reboot,
   hibernate, logout, and lock (suspend dropped), so that I can manage session
   power as I do today with wlogout.
10. As the desktop user, I want logout to tear down the systemd wayland session
    cleanly via `uwsm stop`, so that logging out doesn't leave the session in a
    half-state.
11. As the desktop user, I want a lock screen that authenticates by password,
    so that I can unlock without fingerprint/face/Yubikey (I don't use those at
    the lock screen).
12. As the desktop user, I want the lock screen themed in warm-metal from the
    same scheme layer as the rest of the shell, so that locking doesn't break
    the visual identity.
13. As the desktop user, I want the screen to auto-lock after ~10 minutes idle,
    so that an idle machine secures itself (an upgrade over today's idle-notify
    behavior, which only sends a notification).
14. As the desktop user, I want the tailscale status icon in the bar, so that I
    can see at a glance whether my VPN is up.
15. As the desktop user, I want left-click on the tailscale icon to toggle
    tailscale up/down, so that I can quickly connect/disconnect.
16. As the desktop user, I want right-click on the tailscale icon to switch
    between my two tailscale accounts, so that I can flip profiles without a
    terminal.
17. As the desktop user, I want a hover popout on the tailscale icon showing
    tailnet, account, current exit node, and the peer list, so that I get the
    rich status I have today without a tooltip hack.
18. As the desktop user, I want to pick a tailscale exit node (or disable it)
    from that hover popout, so that I don't depend on a wofi dmenu that no
    longer exists.
19. As the desktop user, I want cava audio-spectrum visualization in the shell,
    so that I keep the visualizer I have today.
20. As the desktop user, I want CPU/GPU/memory/temperature monitoring in a
    dashboard, so that I keep the system monitoring I have today.
21. As the desktop user, I want disk usage in a dashboard card, so that I keep
    the disk monitoring I have today.
22. As the desktop user, I want weather in a dashboard tab and a small weather
    widget, so that I keep the weather glance I have today.
23. As the desktop user, I want media (MPRIS) controls in a dashboard tab, so
    that I keep the now-playing controls I have today.
24. As the desktop user, I want the desktop to build from the flake on the
    `quickshell` branch, so that a `nix build` / `nixos-rebuild build` succeeds
    end-to-end before I ever log into the new shell.
25. As the desktop user, I want `main` to remain a working waybar fallback
    during the build, so that a broken caelestia never leaves me without a bar.
26. As the desktop user, I want the old tools removed in a single atomic merge
    to `main`, so that the repo ends caelestia-only with no leftover dead
    config.

## Implementation Decisions

**Base & divergence.** Fork `caelestia-dots/shell` at pinned tag v2.2.0
(Hyprland-native, full-shell, ships its own Nix flake + Home Manager module
`programs.caelestia`). Snapshot-and-diverge: vendor once, own from then on,
pull upstream fixes manually only when something breaks. No subtree/submodule
tracking. (From [WF-1](select-config-to-fork.md).)

**Flake & Home-Manager integration.** Add `caelestia-shell` as a flake input
(pointed at the user's fork once vendoring begins; until then the upstream
URL). Caelestia's flake already wraps its C++/CMake build (`clangStdenv` +
cmake/ninja + Qt6 + quickshell, X11/I3 disabled) — no hand-written
`mkDerivation`. Wire the HM module in so HM modules can reference the flake
input, enable `programs.caelestia` with the `with-cli` package, and add a
dedicated HM module for caelestia to the HM module list. (From
[WF-2](nix-home-manager-integration.md).)

**Launch & environment.** Launch via the HM module's systemd user service
(`caelestia.service`), bound to the graphical-session target — **not** a
Hyprland `exec-once`. `QT_QPA_PLATFORM=wayland` is set by the module. Remove
the waybar/swaync/wofi/wlogout autostart lines. (From [WF-2](nix-home-manager-integration.md).)

**Vendored runtime config.** Caelestia's user-editable config lives under the
vendored caelestia config directory (matching the `~/.config/caelestia/` path
the shell reads). `shell.json` is HM-generated from `programs.caelestia.settings`;
`shell-tokens.json`, `hypr-user.conf`, and the `scheme/` tree are symlinked as
single-file entries (so they don't collide with the HM-generated `shell.json`
and keep the systemd auto-restart-on-edit behavior). (From
[WF-2](nix-home-manager-integration.md).)

**Keybinds.** The launcher / notification-center / power-menu keybinds move
from Hyprland `exec-once`-launched tools to Hyprland DBus **global shortcuts**
(`bindl = , KEY, global, <id>`), with layer rules for the `quickshell:*`
layer namespaces added to the look-and-feel config. Remap caelestia's own
default global keybinds to the existing muscle-memory: SUPER+N → notification
center, SUPER+SPACE → launcher, SUPER+ESCAPE → power menu. Drop SUPER+R (dead
`hyprlauncher` binding, never installed) and SUPER+M (the standalone wofi
exit-prompt folds into the power menu). (From
[WF-6](shell-parity.md) + [WF-2](nix-home-manager-integration.md).)

**Theming — pin warm-metal via a vendored static scheme.** Author a static
warm-metal `scheme.json` and vendor it to the path the shell reads. Set
`services.smartScheme: false` (hygiene). Pre-populate `wallpaper/path.txt` so
the shell's empty-path fallback never force-regenerates. **Sever the CLI
regeneration path** by removing the Nexus "Wallpaper & Style" page from the
page registry **and** dropping the `>scheme` / `>variant` / `>wallpaper`
launcher actions from the vendored `shell.json`. Set `appearance.transparency`
and `background.wallpaperEnabled` directly in the vendored `shell.json`. (From
[WF-3](theming-mechanism.md) + [WF-4](custom-module-porting-plan.md).)

**Warm-metal → M3 role mapping** (the schema the vendored `scheme.json` encodes;
produced by WF-3, the decision-rich part inlined here):

| M3 / scheme role | Warm-metal source | Hex |
|---|---|---|
| background / surface | base | `#322a21` |
| surface tiers | mantle / crust / surface0-2 | (copy from a real scheme run) |
| onSurface | text | `#f0e6d2` |
| primary | gold | `#e8c272` |
| secondary | copper | `#d99069` |
| tertiary | patina | `#84baa7` |
| error (urgent) | terracotta | `#e5805f` |
| errorContainer | rust | `#c96b4a` |
| success (online / tailscale-up) | olive | `#b3bf80` |
| outline (tailscale-down) | overlay0 | `#937c63` |

The exact `overlay1/overlay2/subtext0` hexes should be copied from one real
`caelestia wallpaper -p` run rather than hand-computed. The shell QML reads
only the `m3*` + `term*` keys; the catppuccin-style names the generator emits
keep Hyprland/GTK/terminal templates on the same vocabulary the existing
waybar `style.css` uses. (From [WF-3](theming-mechanism.md).)

**Fancy levers.** Rounding/spacing/padding (8 tiers each), font sizes (6),
animation durations (10, global-only), and easing curves (12 named bezier
lists, global-only) are tuned via `shell-tokens.json` under `appearance.*` plus
per-component `sizes.*`. Transparency (`enabled/base/layers`) is in
`shell.json` under `appearance.transparency` (global-only). **Blur is not a
token** — it's a Hyprland `layerrule` on the `caelestia-drawers` namespace the
shell toggles when transparency is enabled; can also be added directly in the
Hyprland config. (From [WF-3](theming-mechanism.md).)

**Styling is flat, not gradient.** Accept caelestia's flat styling — do **not**
port the current waybar per-widget gradients. Active workspace = solid
`m3primary` (gold); power button = solid `m3error` (terracotta). (From
[WF-4](custom-module-porting-plan.md).)

**Workspaces.** Adopt caelestia's default workspace widget; do not pin
persistent numbered 1-5. (From [WF-4](custom-module-porting-plan.md).)

**Shell surfaces — accept caelestia defaults.** Notifications (center, DND,
grouping, expiry, fullscreen/lock hiding), OSD (brightness/volume/mic), and
launcher (fuzzy search + Qalc) all as-caelestia. The waybar bell widget is
replaced by caelestia's own bar status icon. (From [WF-6](shell-parity.md).)

**Power menu — accept default action set with two deviations.** Actions:
shutdown / reboot / hibernate / logout / lock — **suspend is dropped** (and
caelestia's default set already excludes it, so no addition needed). **Logout
must use `uwsm stop`** (clean systemd wayland-session teardown), not a raw
`loginctl terminate-user`. The lock action targets caelestia's own `Lock`
module (no rerouting). (From [WF-6](shell-parity.md) + [WF-7](lockscreen-caelestia-vs-hyprlock.md).)

**Lock screen — adopt caelestia's `Lock` module; retire hyprlock.** Patch
caelestia's lock PAM to drop `pam_fprintd.so` / `pam_howdy.so` and authenticate
by password only — a build-phase PAM rewrite of the same shape caelestia's
derivation already does. No fingerprint, face, or Yubikey at the lock screen.
(From [WF-7](lockscreen-caelestia-vs-hyprlock.md).)

**Idle — keep hypridle, add auto-lock-on-idle.** Caelestia ships no idle
module, so hypridle stays as the idle daemon. Repoint hypridle's `on-timeout`
from the current `notify-send "You are idle!"` to caelestia's lock (via the
caelestia CLI/IPC — confirm the exact lock subcommand at build time) at
`timeout = 600` (~10 min). `on-resume` is optional. This is a deliberate
upgrade over today's notify-only idle behavior. (From
[WF-7](lockscreen-caelestia-vs-hyprlock.md).)

**Custom modules — port tailscale only; drop the rest into built-ins.**
Caelestia ships built-in Cava (audio viz + beat detection), a dashboard
Performance tab (CPU/GPU/temp/mem/storage/battery), a Weather tab + small
weather widget, and a Media tab (MPRIS). So the porting set collapses to
tailscale:

- `cava.sh` → caelestia built-in Cava service.
- `sysinfo.sh` (CPU/MEM/GPU/temp) → dashboard Performance tab.
- `disk.sh` → dashboard Storage card.
- `weather.sh` → dashboard Weather tab + small-weather widget.
- waybar `mpris` → dashboard Media tab.
- `netspeed.sh` → dropped (caelestia's network status-icon popout shows
  connection state only, no throughput; if throughput is missed, extending the
  network delegate is a build-time tweak).

(From [WF-4](custom-module-porting-plan.md).)

**Tailscale port — the one custom module.**

- **Target widget:** a new `tailscale` entry in the bar `statusIcons` cluster,
  peer to network/bluetooth/battery.
- **Exit-node picker host:** a **QML popout** on the tailscale status-icon —
  no wofi, no dmenu binary. Selecting an entry calls `tailscale set
  --exit-node <name>` via Quickshell's `Process` API. The script's
  `wofi --dmenu` path is deleted.
- **Status wiring:** `tailscale.sh --status` is restructured to emit
  **structured JSON** (replacing the waybar-Pango output) — the schema, from
  the WF-4 prototype:
  ```json
  { "up": false, "loginName": "", "tailnet": "",
    "exitNode": "", "exitNodes": [], "peers": [] }
  ```
  …derived from the single `tailscale status --json` parse the script already
  performs. `--toggle`, `--switch-profile`, and `--set-exit-node` are
  `Process`-invoked. Tailscale logic stays in the script; only the output
  shape changes — the script remains the source of truth (no JS reimplementation).
- **Click routing:** popout on **hover** (status + exit-node list + profile
  switch row); **left-click = toggle up/down**; **right-click = switch
  profile**. The old middle-click picker is absorbed into the hover popout.
- **Icon + styling:** tailscale brand mark as a monochrome SVG/Image tinted by
  state — up = `m3success` (olive), down = `m3outline` (overlay0). Popout:
  labels `m3primary` (gold), values `m3onSurface` (text), online peers
  `m3success`, offline `m3outline`, selected exit-node row `m3secondary`
  (copper). All roles from the vendored `scheme.json`.

(From [WF-4](custom-module-porting-plan.md).)

**Cutover & fallback — git branch as the toggle.** `main` = stable waybar
stack (the fallback); `quickshell` = caelestia work. Flip = `git switch
quickshell` + rebuild; fallback = `git switch main` + rebuild. Cold-turkey on
`quickshell` once caelestia boots reliably: swap the branch autostart to the
systemd `caelestia.service` and remove the old `exec` lines + keybinds. From
here `main` is the only fallback (checkout + rebuild), not a live runtime
toggle. No permanent dual-shell escape hatch in the repo; git history is the
recovery net. (From [WF-5](cutover-fallback-strategy.md).)

**Retirement — atomic merge + full removal.** When the validation gate
passes, merge `quickshell` → `main`. That single merge removes: the old launch
lines + keybinds in the Hyprland config; the waybar/swaync/wofi/wlogout
symlink entries; the old config directories; and the retired packages from the
system packages list — `waybar`, `swaync`, `wofi`, `wlogout`, `hyprlock`, and
`inotify-tools` (the waybar-autoreload watcher's dep). `cava` and `libnotify`
are candidate drops with keep/drop **confirmed at build time** (does caelestia's
built-in Cava still shell out to the `cava` binary? is any remaining script or
caelestia surface still calling `notify-send` once the tailscale picker is a
QML popout?); until those two checks land, leave both installed. Keep
`hypridle` and `qt6.qtwayland`. (From [WF-5](cutover-fallback-strategy.md).)

## Testing Decisions

**One seam: the flake builds.** The single automated test is that the NixOS
system configuration evaluates and builds successfully from the flake on the
`quickshell` branch — `nix build .#nixos` (equivalently `nixos-rebuild build`)
succeeds. This is the highest seam available and covers the entire integration
in one assertion: the `caelestia-shell` flake input resolves, the C++/CMake
package builds, the Home Manager module wires in, the vendored config and
single-file symlinks are produced, the systemd `caelestia.service` unit
evaluates, the PAM patch applies, and the old packages/symlinks are removed
without breaking evaluation. It catches the build-phase risks flagged by WF-2
(Qt6/quickshell version match, graphical-session target under uwsm) at
evaluation/build time.

**What makes a good test here.** Test external behavior, not implementation
details: the assertion is "the configured system builds," not "the HM module
calls `callPackage` with these arguments." No assertions about QML widget
internals, file layout inside the vendored config, or which Nix functions are
used.

**Prior art.** None — this is the first automated test in the repo. There is
no existing `checkPhase`, test harness, or CI. The build-seam test becomes the
repo's first.

**Manual acceptance gate (not automated).** The live-session validation
checklist from [WF-5](cutover-fallback-strategy.md) gates the merge to `main`
and is performed by the user on a real Hyprland session, not by the test seam:
(a) the four shell surfaces render in warm-metal and work — bar; notifications
+ SUPER+N/control center; OSD (volume/brightness/media); launcher + SUPER+SPACE;
power menu + SUPER+ESCAPE; (b) caelestia `Lock` authenticates (password-only
PAM) **and** hypridle auto-lock-on-idle (~600s) triggers it; (c) tailscale
(toggle + exit-node picker) and the system tray behave; (d) no Qt6/Hyprland
glitches — blur layerrule, layer-shell positioning, workspace animations,
Hyprland global shortcuts firing. The tailscale script's structured-JSON
correctness and the warm-metal `scheme.json` contents are verified as part of
this manual gate, not by a separate automated seam.

## Out of Scope

- **Re-theming ghostty / hyprland / GTK.** Warm-metal is being *kept*; there is
  no desktop-wide re-theme. The vendored `scheme.json` reuses the same
  catppuccin-style vocabulary those surfaces already consume.
- **Writing the actual QML / building the shell at the map level.** That is the
  work *this spec enables* — it is in scope for the implementing agent, not for
  the wayfinder map.
- **Porting the dropped custom scripts.** `cava.sh`, `sysinfo.sh`, `disk.sh`,
  `weather.sh`, `mpris`, and `netspeed.sh` are not ported; their functionality
  is covered by caelestia built-ins. Only tailscale is ported.
- **Per-widget gradients.** Dropped in favor of caelestia's flat styling.
- **Suspend in the power menu.** Explicitly dropped.
- **Fingerprint / face / Yubikey unlock.** Password-only at the lock screen.
- **A permanent dual-shell runtime toggle.** The repo ends caelestia-only; git
  history (the `main` branch until merge, `git revert` after) is the recovery
  net.
- **Network throughput in the bar.** Dropped with `netspeed.sh`; caelestia's
  network popout shows connection state only.

## Further Notes

**Build-phase risks carried forward (to confirm during implementation, not
re-decisions):**

1. **Qt6/quickshell version match** — caelestia targets `nixos-unstable`; this
   repo is `nixos-26.05`. A `follows` on nixpkgs may cause a Qt ABI mismatch.
   Mitigation: drop `follows` on `caelestia-shell`.
2. **`graphical-session.target` activation under uwsm** (`withUWSM = true`) —
   confirm the systemd user service activates; else set `systemd.target`
   explicitly or fall back to `systemd.enable = false` + a Hyprland
   `exec-once`.
3. **Hyprland global-shortcut IDs + `quickshell:*` layer namespaces** — read
   the fork's QML `GlobalShortcut` registrations and the caelestia dots keybind
   example to get the exact IDs and the hyprlua `global` bind helper shape.
4. **CLI regen path fully severed** — confirm `Colours.setMode()` and any
   general `Actions.qml` entry don't independently regenerate `scheme.json`
   once the Nexus "Wallpaper & Style" page and the three launcher actions are
   gone (they should have no UI trigger).
5. **hypridle → caelestia lock IPC** — confirm the exact caelestia CLI/IPC
   subcommand that triggers the lock screen, and use it as hypridle's
   `on-timeout` at `timeout = 600`.
6. **`cava` / `libnotify` keep-or-drop** — confirm at build time whether
   caelestia's built-in Cava shells out to the `cava` binary and whether any
   remaining script/surface still calls `notify-send`; drop both in the
   retirement merge only if confirmed unused.

**Decision provenance.** Every decision above traces to a closed wayfinder
ticket: [WF-1](select-config-to-fork.md) (which config to fork),
[WF-2](nix-home-manager-integration.md) (Nix/HM integration),
[WF-3](theming-mechanism.md) (theming mechanism),
[WF-4](custom-module-porting-plan.md) (custom-module porting + bar styling),
[WF-5](cutover-fallback-strategy.md) (cutover & fallback),
[WF-6](shell-parity.md) (shell-surface parity), [WF-7](lockscreen-caelestia-vs-hyprlock.md)
(lock screen). The full research notes live under
`docs/wayfinder/research/`. Implement against this spec; do not re-open the
closed decisions — escalate back to the map if a real build contradicts one.