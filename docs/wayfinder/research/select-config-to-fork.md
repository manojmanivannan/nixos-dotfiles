# WF-1 Research: Select the quickshell config to fork

Survey of popular quickshell configs evaluated against the five wayfinder
criteria: (1) full-shell, (2) themeable/neutral enough for warm-metal,
(3) actively maintained, (4) Hyprland-compatible, (5) Nix-friendly.

All facts below are from primary sources (GitHub repo metadata, READMEs,
wikis, quickshell.org showcase) retrieved 2026-08-05. Where a fact could
not be confirmed, it is marked "unconfirmed".

## Note on the ticket's named candidates

- **`caubut-caca`** — no GitHub user/repo of this name could be found. Likely
  misspelled or renamed; possibly conflated with another quickshell config.
- **`m-100/quickshell-config`** — no such repo found. The closest names are
  `mszost/quickshell-config` (0 stars, Matugen, macOS/GNOME-like dock, OSD,
  no notif/launcher/power) and `matthew-hre/quickshell-config` (0 stars,
  waybar-recreation, top bar + notifications only). Neither is full-shell.
- **`end-4/dots-hyprland`** — confirmed, evaluated below (top candidate).

The quickshell.org homepage showcase lists six configs: **end_4**
(end-4/dots-hyprland), **soramanew** (caelestia-dots/shell), **outfoxxed**
(nixnew, the lead dev's private Nix module config), **flicko**
(flickowoa/zephyr), **pfaj & bdebiase**, and **vaxry** (no public repo).
The two with public, full-shell, Hyprland-first repos are end-4 and
caelestia; those dominate the shortlist.

---

## Shortlist

### 1. caelestia-dots/shell (soramanew) — RECOMMENDED

Repo: https://github.com/caelestia-dots/shell — ~10.8k stars, 763 forks,
GPL-3.0, primary language QML (67%) + C++ (26%). Latest release **v2.2.0
(2026-07-16)**, last push 2026-07-20, 26 releases, top contributor
soramanew (2,073 commits). Homepage: https://caelestiashell.com/landing.

- **Full-shell (criterion 1): YES, complete.** Ships bar (workspaces, window
  title, SNI tray, status icons, clock, power), app launcher (fuzzy search,
  calculator via Qalc, wallpaper/scheme/variant switching, power actions),
  notifications (grouping, expiry, fullscreen behavior, lock-screen
  hiding), OSD (brightness/volume/mic), session/power menu (shutdown,
  reboot, hibernate, logout, lock), lock screen (fprint + Howdy), dashboard
  (MPRIS, perf monitoring, weather), sidebars/drawers, background
  wallpaper manager, and toast utilities. Replaces swaync + wofi + wlogout
  entirely.
- **Themeable (criterion 2): Good, with one friction.** User config is
  centralized in `~/.config/caelestia/shell.json` (appearance: fonts,
  rounding, spacing, padding, animation durations, transparency) and
  advanced token overrides in `~/.config/caelestia/shell-tokens.json`
  (rounding, spacing, padding, font size, animation duration/easing,
  component sizes; per-monitor overrides supported). Colors run through a
  **dynamic wallpaper-driven scheme system** (`services.smartScheme`,
  `caelestia scheme set`), so a fixed warm-metal palette requires either
  feeding a warm-metal wallpaper to generate the scheme or forking the
  scheme layer to inject a pinned palette. Tokens are not guaranteed
  stable across versions, but for snapshot-and-diverge that is acceptable.
- **Actively maintained (criterion 3): YES.** v2.2.0 released 2026-07-16
  (26 commits, 102 files changed); last push 2026-07-20; active issue
  tracker (207 open); multiple external contributors in v2.2.0.
- **Hyprland (criterion 4): YES, Hyprland-native.** Topics include
  `hyprland`, `hyprland-rice`; all keybinds use Hyprland's DBus global
  shortcuts; designed for Hyprland layer-shell.
- **Nix (criterion 5): Best-in-class.** First-class Nix flake: `nix run
  github:caelestia-dots/shell`, `caelestia-shell.packages.<system>.default`,
  a `with-cli` variant, and a **Home Manager module** (`programs.caelestia`)
  with systemd integration. This is the only shortlisted config with a
  real HM module — directly fits a NixOS + Home-Manager flake.

**Trade-offs:** (a) ~26% C++ with a CMake/Ninja build — not a pure-QML
  directory, so vendoring carries a native build step. (b) Color scheme is
  wallpaper-driven by default; pinning warm-metal means forking the scheme
  generation, not just editing one color file. (c) Large, opinionated
  project (10.8k stars, 26 releases) — more to carve away than a minimal
  config.

### 2. end-4/dots-hyprland (illogical-impulse) — strong alternative

Repo: https://github.com/end-4/dots-hyprland — ~15.1k stars, 1,239 forks,
GPL-3.0, QML (76.7%) + Shell + Python + Lua. Latest release **2026.05.11**,
last push 2026-06-14, 210 contributors. Previously AGS-based; main branch
now runs on quickshell (`qsConfig=ii`). Wiki:
https://end-4.github.io/dots-hyprland-wiki/en/ii-qs/03config/

- **Full-shell (criterion 1): YES, complete.** The `ii` panel family
  (IllogicalImpulseFamily.qml) loads: Bar/VerticalBar, NotificationPopup,
  OnScreenDisplay, Overview (launcher), SessionScreen (power/logout),
  SidebarLeft/SidebarRight, Dock, Lock, Polkit, Cheatsheet, WallpaperSelector,
  MediaControls, ScreenTranslator, RegionSelector. Plus an AI sidebar and
  "waffle" alternate panel family. Replaces swaync+wofi+wlogout.
- **Themeable (criterion 2): Hardest friction.** Theming is **matugen
  Material-3 wallpaper-driven**: matugen generates `colors.json` consumed
  by a centralized `Looks`/`Appearance` QML singleton (three-tier
  bg0/bg1/bg2, adaptive transparency from wallpaper vibrance). Colors also
  flow to Hyprland, GTK, Fuzzel, Hyprlock. The architecture is centralized
  (good) but explicitly M3-from-wallpaper (bad for a fixed warm-metal
  palette — you would fight matugen, not just swap a color file).
- **Actively maintained (criterion 3): YES.** Last push 2026-06-14, release
  2026.05.11, 210 contributors, very active discussions (#2302, #2958 on
  quickshell packaging). Hyprland 0.55 / Lua-config migration in progress.
- **Hyprland (criterion 4): YES, Hyprland-native.** Layer rules for every
  `quickshell:*` namespace (blur, animations); Hyprland is the only
  target.
- **Nix (criterion 5): Weak for NixOS.** Has a `sdata/dist-nix/` flake, but
  the README explicitly states it is **"not for NixOS"** — it targets
  non-NixOS distros using nix + home-manager for dependency installation
  only. Dotfile deployment via Nix is "paused". PAM-dependent pieces
  (hyprlock, polkit) must come from the system package manager. On NixOS
  you would vendor the QML and write your own HM module.

**Trade-offs:** Most popular and visually polished ("fancy" motion/blur/
  curves are already here), but theming actively fights a fixed palette
  (criterion 2) and the Nix path is experimental and not NixOS-targeted
  (criterion 5). Vendoring is also heavier because it is a full dotfiles
  monorepo (Hyprland config, scripts, AGS legacy) rather than just a shell.

### 3. doannc2212/quickshell-config — lightweight, most themeable fallback

Repo: https://github.com/doannc2212/quickshell-config — 45 stars, 2 forks,
QML (99.2%) + Shell. Created 2026-02-13, last push 2026-06-19, single
contributor. Tagline: "A gentle Quickshell config for Hyprland."

- **Full-shell (criterion 1): Partial.** Ships bar, app launcher
  (rofi-drun-style), notification daemon (urgency styling, DND, action
  buttons, replaces dunst/mako), OSD (vertical pill, auto-hide), wallpaper
  manager, theme switcher, and a monitor manager (WIP per issue #1).
  **No explicit power/logout menu** in the README — would need to be
  added. Closest to full-shell among the small configs, but not complete.
- **Themeable (criterion 2): Best for a fixed palette.** 206 themes across
  6 families (Tokyo Night, Catppuccin, Zen, Arc, Beared, MonkeyType) plus
  wallpaper generation via matugen/wallust. Themes are discrete files, so
  authoring a "warm-metal" theme file is the intended extension model —
  much less fight than matugen-M3 singletons.
- **Actively maintained (criterion 3): Active but small.** Last push
  2026-06-19, but single contributor, 45 stars, 1 open issue. Less
  battle-tested than the top two.
- **Hyprland (criterion 4): YES.** Hyprland-targeted.
- **Nix (criterion 5): None.** No flake, no nix files. Plain `git clone`
  into `~/.config/quickshell`. Pure QML (99.2%) makes it the cleanest to
  vendor as a QML directory, but you write the HM wiring yourself.

**Trade-offs:** Easiest to re-theme (criterion 2) and cleanest to vendor
  (pure QML), but missing a power menu (criterion 1), no Nix integration
  (criterion 5), and a small/single-contributor project (criterion 3).

---

## Considered and rejected

- **bjarneo/quickshell** (~122 stars, MIT, created 2026-05-16) — built for
  Omarchy (DHH's Arch distro); modules read `~/.config/omarchy/current/
  theme/colors.toml` and restyle dynamically. Tightly coupled to Omarchy;
  not portable to NixOS without gutting the theme loader. Interesting
  "fancy" modules (song-drop, theme-wash, data-sphere, expose) but not a
  neutral base. https://github.com/bjarneo/quickshell
- **ulises-jeremias/dotfiles (HorneroConfig)** (~128 stars, MIT) —
  comprehensive, M3-from-wallpaper, but managed with Chezmoi (not
  Nix-first), ships a C++ plugin (Hornero), and last visible commit
  2026-05-13. More of a full dotfiles framework than a forkable shell.
  https://github.com/ulises-jeremias/dotfiles
- **tripathiji1312/quickshell** (~132 stars, MIT, last push 2026-06-05) —
  clean `components/modules/services` architecture, pywal theming, pure
  QML, but no Nix, and issue #2 reports breakage on newer Hyprland
  layer-rule syntax. No power menu listed. Good architecture reference.
  https://github.com/tripathiji1312/quickshell
- **flickowoa/zephyr** — a Hyprland *theme* (hyprtheme.toml) with
  quickshell components, not a standalone full shell repo. The parent
  flickowoa/dotfiles (~1.9k stars) is waybar/wofi-based. Not a full-shell
  quickshell config. https://github.com/flickowoa/zephyr
- **outfoxxed nixnew** (lead dev's config) — referenced on quickshell.org
  but hosted as part of a private Nix module setup; not a community fork
  target. https://git.outfoxxed.me/outfoxxed/nixnew/src/branch/master/
  modules/user/modules/quickshell

---

## RECOMMENDATION

**Fork `caelestia-dots/shell` (soramanew).**

Rationale, mapped to the criteria:

1. **Full-shell (strongest):** It is the only shortlisted config that
   ships *every* surface the user needs — bar, notification center, OSD,
   app launcher, and a real session/power/logout menu — plus lock,
   dashboard, and sidebars. Retires swaync/wofi/wlogout completely.
2. **Hyprland-native:** Designed for Hyprland layer-shell and DBus global
   shortcuts; no Sway-first baggage.
3. **Most Nix-friendly:** First-class flake + Home Manager module
   (`programs.caelestia`), which drops directly into a NixOS + HM flake.
   end-4's Nix path is experimental and explicitly non-NixOS; doannc2212
   has none.
4. **"Fancy" out of the box:** Described as "a fluid, morphing shell";
   shell-tokens.json exposes animation duration/easing curves, rounding,
  and spacing — the motion/blur/curves/popouts the user wants are first-
   class tunables, not afterthoughts.
5. **Actively maintained:** v2.2.0 released 2026-07-16, last push
   2026-07-20, 26 releases, multiple contributors.

### Known trade-offs to plan for

- **C++/CMake build (criterion 5 nuance):** ~26% C++ (performance pieces).
  Vendoring is not a pure-QML copy; the fork must keep a CMake build step
  in its Nix derivation. Plan the HM module around `stdenv.mkDerivation`
  + cmake/ninja, not a plain `writeTextDir`.
- **Warm-metal theming requires forking the scheme layer (criterion 2
  nuance):** Colors are wallpaper-driven M3 by default. To pin warm-metal,
  either (a) generate the scheme from a warm-metal wallpaper once and
  freeze it, or (b) bypass `services.smartScheme` and inject a fixed
  palette at the token/singleton level via `shell-tokens.json` + a custom
  scheme. This is real work but the centralization (shell.json + tokens +
  scheme) makes it *contained* — one seam, not per-widget color bakes.
- **Snapshot-and-diverge discipline:** 26 releases and 207 open issues
  mean upstream moves fast. The user's plan to vendor once and pull
  fixes manually is correct; do not submodule. Pin a tag (v2.2.0) as the
  fork origin.

### Why not end-4 (the runner-up)

end-4 is more popular (15k vs 10.8k) and visually excellent, but loses on
the two criteria that hurt *this* user most: criterion 2 (matugen M3
wallpaper theming baked into a `Looks`/`Appearance` singleton — harder to
pin warm-metal than caelestia's scheme/token split) and criterion 5 (Nix
support is experimental and explicitly "not for NixOS"). end-4 is the
right pick if the user ever wants wallpaper-driven M3 theming; for a
fixed warm-metal identity on NixOS, caelestia fits better.

### Why not doannc2212 (the lightweight fallback)

Easiest to re-theme (discrete theme files, pure QML, no native build), but
it is missing a power/logout menu, has no Nix integration, and is a
45-star single-contributor project. If the user values minimal-vendoring
simplicity over completeness and Nix-fit, it is a viable fallback — but it
does not meet the "replace wlogout" requirement out of the box.

---

## Sources

- https://quickshell.org/ (showcase listing: end_4, soramanew, outfoxxed, flicko, pfaj & bdebiase, vaxry)
- https://github.com/caelestia-dots/shell
- https://github.com/caelestia-dots/shell/releases/tag/v2.2.0
- https://github.com/caelestia-dots/shell/blob/main/README.md
- https://deepwiki.com/caelestia-dots/shell
- https://github.com/end-4/dots-hyprland
- https://end-4.github.io/dots-hyprland-wiki/en/ii-qs/03config/
- https://github.com/end-4/dots-hyprland/blob/c04b0bbc/dots/.config/quickshell/ii/panelFamilies/IllogicalImpulseFamily.qml
- https://deepwiki.com/end-4/dots-hyprland/3.6.1-looks-system-and-theming
- https://deepwiki.com/end-4/dots-hyprland/3.6.2-notification-system
- https://github.com/end-4/dots-hyprland/blob/main/sdata/dist-nix/README.md
- https://github.com/end-4/dots-hyprland/blob/main/sdata/dist-nix/home-manager/flake.nix
- https://deepwiki.com/end-4/dots-hyprland/2.4.2-nix-and-home-manager
- https://github.com/doannc2212/quickshell-config
- https://github.com/bjarneo/quickshell
- https://github.com/ulises-jeremias/dotfiles
- https://github.com/tripathiji1312/quickshell
- https://github.com/flickowoa/zephyr
- https://github.com/InioX/matugen