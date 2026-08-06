# Wayfinder Map — Replace waybar with a quickshell full shell

> Local-markdown tracker (no `docs/agents/issue-tracker.md` in this repo, so
> wayfinder defaults to local markdown). The map is `docs/wayfinder/MAP.md`;
> tickets are `docs/wayfinder/tickets/<slug>.md` with frontmatter for
> `label` (`wayfinder:<type>`), `status`, `assignee`, and `blocked-by`.
> A ticket is **unblocked** when every ticket in its `blocked-by` is closed.
> The **frontier** = open, unblocked, unclaimed tickets. Refer to tickets by
> **title**, never a bare `WF-N`.

## Destination

A warm-metal-themed, fork-based **full quickshell shell** replacing waybar +
swaync + wofi + wlogout — the fork's generic modules plus this repo's custom
monitoring/Tailscale/cava bits ported in — delivered as **a set of cleared
decisions ready to hand off to a spec-first build** (then to `to-spec` /
implement). The map plans; it does not write QML.

## Notes

- **Domain:** NixOS + Home-Manager flake dotfiles; Hyprland compositor. Config
  dirs are symlinked from `config/.config/` via
  `home-manager/modules/dotfiles-symlinks.nix`. Current bar stack lives in
  `config/.config/waybar/` (config + style + scripts) and is launched from the
  Hyprland config; `waybar`, `cava`, `inotify-tools`, `libnotify` ship via
  `nixos/modules/services/services.nix`. Notification/launcher/power surfaces
  are swaync / wofi / wlogout. Lock/idle are hyprlock / hypridle.
- **Skills every session should consult:** `/grilling` + `/domain-modeling` for
  decision tickets; `/prototype` for "how should it look/behave" questions;
  `/research` for AFK fact-finding. Codebase-design vocabulary when designing
  the vendored config's module seams.
- **Standing decisions (settled while naming the destination — orient here
  before choosing a ticket):**
  1. Map plans, doesn't write QML — destination is cleared decisions handed off
     to a spec-first build.
  2. Fork an existing quickshell config + re-theme (do not write from scratch).
     The exact candidate is resolved by [Select the quickshell config to fork](tickets/select-config-to-fork.md).
  3. Full shell scope: quickshell owns bar + notifications + OSD + launcher +
     power menu **and the lock screen**. Retire swaync / wofi / wlogout **and
     hyprlock** (adopt caelestia's `Lock` module). Keep `hypridle` for
     auto-lock-on-idle. Port the custom shell scripts into the new shell. See
     [Lockscreen — caelestia's built-in lock vs keep hyprlock](tickets/lockscreen-caelestia-vs-hyprlock.md).
  4. Keep the warm-metal identity (brushed gold/copper/bronze on warm espresso,
     consistent across ghostty / hyprland / GTK). "Fancy" comes from quickshell's
     motion / blur / curves / popouts — not a new palette.
  5. Module parity: adopt the fork's generic modules; port only the unusual
     custom ones — tailscale (toggle + exit-node picker), cava spectrum,
     GPU/CPU/MEM/disk monitoring, weather.
  6. Keep the existing shell scripts; call them from QML via Quickshell's
     `Process` API. Do not reimplement their logic in JS.
  7. Snapshot-and-diverge: vendor the chosen config once, own it from then on;
     pull upstream fixes manually only when something breaks. No
     subtree/submodule tracking.

## Decisions so far

<!-- one line per closed ticket: gist + link -->

- [Select the quickshell config to fork](tickets/select-config-to-fork.md) — fork `caelestia-dots/shell` @ v2.2.0 (Hyprland-native, full-shell, real Nix HM module); snapshot-and-diverge; warm-metal pinned by forking its M3 scheme layer; C++/CMake vendored via `mkDerivation`.
- [Shell parity — notifications, OSD, launcher, power menu](tickets/shell-parity.md) — accept caelestia defaults on all four surfaces; drop suspend; preserve `uwsm stop` logout teardown; keep SUPER+N/SPACE/ESCAPE keybinds; launcher scheme-switcher → WF-3, power-menu lock target → WF-7, tailscale wofi-dmenu picker → WF-4.
- [Nix / home-manager integration of quickshell + the chosen config](tickets/nix-home-manager-integration.md) — caelestia's flake already wraps the C++/CMake build; add flake input + HM module (`programs.caelestia`) + vendored `config/.config/caelestia/`; launch via systemd `caelestia.service` (not exec-once); keybinds → Hyprland global shortcuts. Build-phase risks flagged (Qt6 version match, uwsm target, global-shortcut IDs).
- [Theming mechanism of the chosen config](tickets/theming-mechanism.md) — pin warm-metal via a vendored static `scheme.json` (path b: bypass `smartScheme` + pre-fill `wallpaper/path.txt` + sever CLI regen path); warm-metal→M3 role mapping table produced; gradients are per-widget QML (→ WF-4); fancy levers = `shell-tokens.json` (rounding/spacing/curves/durations) + `appearance.transparency`; blur is a Hyprland `layerrule`.
- [Lockscreen — caelestia's built-in lock vs keep hyprlock](tickets/lockscreen-caelestia-vs-hyprlock.md) — adopt caelestia's `Lock` module, retire hyprlock (auth freed → password-only PAM patch); keep `hypridle` and add auto-lock-on-idle at ~600s pointed at caelestia's lock; power-menu lock action stays caelestia default (no rerouting). Scope redraw: hyprlock now in-scope to retire.
- [Cutover & fallback strategy](tickets/cutover-fallback-strategy.md) — one-way migration, temporary toggle = git branch (`main`=waybar fallback, `quickshell`=caelestia); cold-turkey on `quickshell` once caelestia boots (swap to systemd `caelestia.service`, drop old exec lines/keybinds); full validation gate (4 surfaces + lock/autolock + custom modules/tray + no Qt glitches) gates an atomic merge `quickshell`→`main` + full removal of old packages/symlinks/config dirs; `cava`+`libnotify` are candidate drops (WF-4 moved both into caelestia built-ins / QML popout), keep/drop confirmed at build time.
- [Custom-module porting plan](tickets/custom-module-porting-plan.md) — port **only tailscale** (new `statusIcons` delegate; structured-JSON `--status`; QML popout exit-node picker replacing wofi; hover popout + left-toggle / right-switch; brand SVG tinted up=`m3success` / down=`m3outline`). Drop `cava.sh` / `sysinfo.sh` / `disk.sh` / `weather.sh` / `mpris` / `netspeed.sh` into caelestia's built-in Cava / Performance / Storage / Weather / Media tabs + network popout. Gradients dropped (flat: active=gold, power=terracotta). Workspaces = caelestia default. Sever CLI regen: remove Nexus "Wallpaper & Style" page + `>scheme` / `>variant` / `>wallpaper` launcher actions (build-time confirm `Colours.setMode()` / `Actions.qml`).

## Hand-off

- [Build spec — caelestia full-shell cutover](tickets/build-spec.md) (WF-8,
  `wayfinder:spec`, `ready-for-agent`) — synthesizes WF-1..WF-7 into a single
  spec for the spec-first build. One automated seam: `nix build .#nixos` on the
  `quickshell` branch; live-session validation is a manual gate. This is the
  map's destination, realized.

### Build hand-off — implementation tickets (WF-9..WF-16)

The spec broken into tracer-bullet vertical slices, each a complete path through
the flake → HM module → vendored config → Hyprland autostart/keybinds → live
session, sized to one fresh context window. `wayfinder:build`,
`ready-for-agent`. Work the **frontier** — open tickets whose blockers are all
closed. WF-9, WF-10, WF-11, and WF-13 are closed; the open frontier is WF-12
and WF-15 (both unblocked — blocked only by the now-closed WF-11), WF-14 gates
on WF-12, and WF-16 is the merge gate after all functional slices + the manual
validation gate.

- [WF-9 — Build-seam baseline test](tickets/build-seam-test.md) — the repo's
  first automated test (`nix build .#nixos`); green on today's stack. Frontier.
- [WF-10 — Wire caelestia flake input + HM module (build-only)](tickets/wire-caelestia-flake-hm.md)
  — prefactor `inputs` into HM; add flake input (no `follows`) + `programs.caelestia`
  HM module + vendored config + systemd service; build-seam stays green; not
  launched yet. Blocked by WF-9.
- [WF-11 — Tracer bullet: caelestia boots as the shell](tickets/tracer-bullet-caelestia-boots.md)
  — swap autostart to `caelestia.service`; repoint SUPER+N/SPACE/ESCAPE to
  global shortcuts + `quickshell:*` layerrules; drop SUPER+R/M; default theme;
  keep hyprlock. Blocked by WF-10.
- [WF-12 — Pin warm-metal theming + sever CLI regen](tickets/pin-warm-metal-theming.md)
  — vendored static warm-metal `scheme.json` (WF-3 role mapping; copy
  overlay/subtext hexes from a real run); `smartScheme:false`; sever Nexus page
  + `>scheme`/`>variant`/`>wallpaper` actions; flat styling; fancy levers +
  blur layerrule. Blocked by WF-11.
- [WF-13 — Tailscale custom module](tickets/tailscale-custom-module.md) — the
  one ported module; structured-JSON `--status`; QML hover popout exit-node
  picker (no wofi); left-toggle / right-switch; brand SVG tinted
  `m3success`/`m3outline`. Blocked by WF-11 (not WF-12 — m3* role names exist in
  any scheme).
- [WF-14 — Lock screen + power menu + auto-lock (retire hyprlock)](tickets/lock-power-autolock.md)
  — adopt caelestia `Lock` + password-only PAM; hypridle `on-timeout`→caelestia
  lock @600s; power-menu logout=`uwsm stop` + lock=caelestia; disable hyprlock.
  Blocked by WF-12 (lock inherits the scheme; validate together).
- [WF-15 — Retire custom scripts into caelestia built-ins](tickets/retire-custom-scripts.md)
  — drop cava/sysinfo/disk/weather/netspeed/waybar-autoreload + waybar mpris;
  rely on built-in Cava/Performance/Storage/Weather/Media + network popout;
  build-time `cava`/`libnotify` keep-or-drop feeds WF-16. Blocked by WF-11.
- [WF-16 — Retirement: atomic merge to main + full removal](tickets/retirement-atomic-merge.md)
  — merge `quickshell`→`main`; remove old launch lines/keybinds, symlink
  entries, config dirs, retired packages (`waybar`/`swaync`/`wofi`/`wlogout`/
  `hyprlock`/`inotify-tools`; `cava`/`libnotify` iff WF-15 confirms unused).
  Blocked by WF-12, WF-13, WF-14, WF-15 + the manual validation gate.

## Not yet specified

<!-- fog toward the destination — in scope, not yet sharp enough to ticket -->

## Out of scope

<!-- work ruled beyond the destination; closed, never graduates -->

- Re-theming ghostty / hyprland / GTK — we are *keeping* warm-metal, so there is
  no desktop-wide re-theme.
- Writing the actual QML / building the shell — that is the hand-off *past* this
  map's destination (the build the cleared decisions enable), not part of the
  map.