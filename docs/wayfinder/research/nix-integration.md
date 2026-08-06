# WF-2 Research: Nix / Home-Manager integration of quickshell + caelestia

A concrete, file-by-file integration recipe for folding `caelestia-dots/shell`
@ v2.2.0 into this flake as the quickshell full shell, replacing waybar +
swaync + wofi + wlogout.

All facts are from primary sources retrieved 2026-08-05:
caelestia's `flake.nix`, `nix/default.nix`, `nix/hm-module.nix`, `README.md`
@ tag v2.2.0; home-manager `modules/wayland.nix`; this repo's flake + HM +
Hyprland config. Where a fact could not be confirmed from source it is
marked **(unconfirmed)** or **(needs real nix build to confirm)**.

## TL;DR — the integration shape

1. Add `caelestia-shell` as a flake input (point at the user's fork URL once
   snapshot-and-diverge begins; until then `github:caelestia-dots/shell/v2.2.0`).
2. Import its `homeManagerModules.default` into this repo's HM module list and
   enable `programs.caelestia` with `package = inputs.caelestia-shell.packages.${system}.with-cli`.
3. The flake **already wraps the C++/CMake build** (`clangStdenv` + cmake/ninja
   + Qt6 + quickshell with X11/I3 disabled). No hand-written `mkDerivation`
   is needed — `pkgs.callPackage ./nix` does it. Vendoring means pointing
   `callPackage` at a vendored copy of the repo, not rewriting the derivation.
4. Vendored user-editable config lives at `config/.config/caelestia/` (matches
   the `~/.config/caelestia/` path the shell reads). `shell.json` is generated
   by the HM module from `programs.caelestia.settings`; `shell-tokens.json`,
   `scheme/`, and `hypr-user.conf` are symlinked via `dotfiles-symlinks.nix`.
5. Launch is via the HM module's **systemd user service** (`caelestia.service`),
   bound to `graphical-session.target` by default — NOT a Hyprland
   `exec-once`. Remove the waybar/swaync `exec-once` lines; do not add one
   for caelestia. Qt6-on-Wayland env (`QT_QPA_PLATFORM=wayland`) is set by
   the HM module itself.
6. Hyprland keybinds for launcher/notif/power move to Hyprland **DBus global
   shortcuts** (caelestia registers them; the user binds `bindl = , ... global,
   <id>` in `bindings.lua`). Layer rules for `quickshell:*` namespaces (blur,
   animations) get added to `looknfeel.lua`.

---

## 1. Packaging caelestia — flake input + the provided derivation

### 1a. Add the flake input

In `/home/manoj/nixos-dotfiles/flake.nix`, add to `inputs`:

```nix
caelestia-shell = {
  url = "github:caelestia-dots/shell/v2.2.0";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

`inputs.nixpkgs.follows` is important: caelestia's flake pins `nixos-unstable`,
but this repo is on `nixos-26.05`. Following avoids a second nixpkgs eval and
lets caelestia build against the same Qt6/quickshell the rest of the system
uses. **Risk:** caelestia's C++ plugin may not compile against nixos-26.05's
Qt6 / quickshell if upstream targets unstable — **(needs real nix build to
confirm)**. If it breaks, drop `follows` and let caelestia pull its own
nixpkgs (larger closure, but matches upstream's tested toolchain).

The caelestia flake also has a `quickshell` input (from
`git+https://git.outfoxxed.me/outfoxxed/quickshell`) and a `caelesstia-cli`
input (`github:caelestia-dots/cli`). These are transitive — no action needed
in this repo's flake, but they will be fetched on first eval. The caelestia
flake overrides quickshell with `withX11 = false; withI3 = false;` (correct
for a Hyprland-only setup).

### 1b. The provided derivation already wraps C++/CMake

Source: `nix/default.nix` at v2.2.0 (downloaded verbatim). Key facts:

- **Stdenv:** `pkgs.clangStdenv` (passed in from `flake.nix` as `stdenv`).
  So the C++ is built with clang, not gcc.
- **Build system:** `cmake` + `ninja` (in `nativeBuildInputs`).
- **It is NOT one derivation — it's four**, all from `nix/default.nix`:
  1. `extras` — `stdenv.mkDerivation` building `extras/` (CMakeLists +
     `extras/version.cpp`) → `$out/lib`.
  2. `plugin` — `stdenv.mkDerivation` building `plugin/` (the QML plugin:
     Caelestia Components/Config/Images/Internal/Models/Services). Build
     inputs: `qt6.qtbase qt6.qtdeclarative qt6.qtshadertools libqalculate
     pipewire aubio libcava fftw lm_sensors`.
  3. `m3shapesModule` — `stdenv.mkDerivation` building the m3shapes module
     (source fetched as a flake input `m3shapes`, pinned to commit
     `bdc327b...`, because the build sandbox has no network).
  4. The final `caelestia-shell` derivation — `stdenv.mkDerivation` whose
     `buildInputs = [quickshell extras plugin m3shapesModule xkeyboard-config
     qt6.qtbase]` and `propagatedBuildInputs = runtimeDeps`.
- **Runtime deps** (propagated): `fish ddcutil brightnessctl networkmanager
  lm_sensors swappy wl-clipboard libqalculate bash hyprland` (+ `caelesstia-cli`
  when `withCli = true`). These are wrapped into `PATH` via `makeWrapper` in
  `postInstall`.
- **The wrapped binary:** `postInstall` creates `$out/bin/caelestia-shell`
  by wrapping `${quickshell}/bin/qs` with:
  - `--prefix PATH : <runtimeDeps>`
  - `--set FONTCONFIG_FILE <fontconfig>` (fonts: material-symbols, rubik,
    nerd-fonts caskaydia-cove)
  - `--set CAELESTIA_LIB_DIR ${extras}/lib`
  - `--set CAELESTIA_XKB_RULES_PATH <xkeyboard-config>/.../base.lst`
  - `--add-flags "-p $out/share/caelestia-shell"`

  So `caelestia-shell` = `qs -p <installed shell config dir>`. The QML
  config tree is installed to `$out/share/caelestia-shell` via the cmake
  flag `INSTALL_QSCONFDIR`.
- **PAM patch:** `prePatch` rewrites `pam_fprintd.so` / `pam_howdy.so`
  paths in `assets/pam.d/` to `/run/current-system/sw/lib/security/...`
  (NixOS-correct). So the lock-screen module's PAM integration is
  NixOS-aware out of the box.

**Conclusion:** the flake already wraps the C++/CMake build. You do NOT
write your own `stdenv.mkDerivation`. You consume
`inputs.caelestia-shell.packages.${system}.with-cli` (or `.default`, which
is the non-CLI variant). The `with-cli` variant
(`caelestia-shell.override { withCli = true; }`) bundles `caelesstia-cli`
so `caelestia scheme set`, `caelestia wallpaper`, `caelestia shell ...` IPC
work — README recommends it for "full functionality."

### 1c. Qt6 deps / qtwayland / platform plugin

- The derivation's `buildInputs` include `qt6.qtbase` (and the plugin also
  pulls `qt6.qtdeclarative`, `qt6.qtshadertools`). It does **not** list
  `qt6.qtwayland` — that is expected to come from the system profile (this
  repo already ships `qt6.qtwayland` in
  `/home/manoj/nixos-dotfiles/nixos/modules/services/services.nix` line 26).
  Keep that package.
- The HM module's systemd service hard-codes
  `Environment = ["QT_QPA_PLATFORM=wayland"]` (see §2), so the Wayland
  platform plugin is selected automatically. No `QT_QPA_PLATFORMTHEME`
  is set by default; the module exposes `programs.caelestia.systemd.environment`
  to add more (the option's own example is `QT_QPA_PLATFORMTHEME=gtk3`).
- `wrapQtAppsHook` is in the derivation's `nativeBuildInputs`, so Qt's
  plugin/library paths are wrapped.

---

## 2. HM module usage — `programs.caelestia` options

### 2a. The options (verbatim from `nix/hm-module.nix` @ v2.2.0)

`programs.caelestia`:

| Option | Type | Default | Notes |
|---|---|---|---|
| `enable` | bool (mkEnableOption) | `false` | Master switch. |
| `package` | package | `self.packages.${system}.with-cli` | The shell package. Override only to pick `debug` or a custom build. |
| `systemd.enable` | bool | `true` | Whether to create the `caelestia` systemd user service. |
| `systemd.target` | string | `config.wayland.systemd.target` | The target the service `After`/`PartOf`/`WantedBy`. HM's `wayland.systemd.target` defaults to `"graphical-session.target"` (see below). |
| `systemd.environment` | list of str | `[]` | Extra `Environment=` lines for the service (e.g. `QT_QPA_PLATFORMTHEME=gtk3`). |
| `settings` | attrsOf anything | `{}` | Merged into `~/.config/caelestia/shell.json` (recursive update on top of `{}`). |
| `extraConfig` | str | `""` | Raw JSON string also merged into `shell.json` (used when you want to paste a blob). |
| `cli.enable` | bool | `false` | Adds `caelesstia-cli` to `home.packages`. |
| `cli.package` | package | `self.inputs.caelestia-cli.packages.${system}.default` | |
| `cli.settings` / `cli.extraConfig` | — | `{}` / `""` | Merged into `~/.config/caelestia/cli.json`. |

There is also a renamed-option shim: `programs.caelestia.environment` →
`programs.caelestia.systemd.environment` (so old configs still build with a
warning).

### 2b. What the module does when enabled

- Creates `systemd.user.services.caelestia` with:
  - `Unit.After`/`PartOf` = `[cfg.systemd.target]`
  - `Unit.X-Restart-Triggers` = the `shell.json` source (so editing
    `settings` restarts the shell).
  - `Service.Type = "exec"`, `ExecStart = "${shell}/bin/caelestia-shell"`,
    `Restart = "on-failure"`, `RestartSec = "5s"`, `Slice = "session.slice"`.
  - `Service.Environment = ["QT_QPA_PLATFORM=wayland"] ++ cfg.systemd.environment`.
  - `Install.WantedBy = [cfg.systemd.target]`.
- Generates `xdg.configFile."caelestia/shell.json"` (only if `settings` or
  `extraConfig` is non-empty) by `builtins.toJSON (recursiveUpdate settings
  (fromJSON extraConfig))`.
- Generates `xdg.configFile."caelestia/cli.json"` similarly.
- Adds `shell` to `home.packages`, plus `cli` if `cli.enable`.

Note: the module generates **only** `shell.json` and `cli.json`. It does
NOT generate `shell-tokens.json`, the `scheme/` dir, `monitors/`, or
`hypr-user.conf` — those are user-managed (see §3).

### 2c. The `wayland.systemd.target` default — safe in this repo

`config.wayland.systemd.target` is defined in home-manager's
`modules/wayland.nix`, which is part of HM's default module set (always
imported, not gated by any compositor module). Its default is
`"graphical-session.target"`. So even though this repo does NOT import the
hyprland *HM* module (`wayland.windowManager.hyprland`), the caelestia
module's `systemd.target` default resolves cleanly to
`"graphical-session.target"`.

Source: home-manager `modules/wayland.nix`
(https://github.com/nix-community/home-manager/blob/master/modules/wayland.nix),
PR #6253, and
https://mynixos.com/home-manager/option/wayland.systemd.target.

### 2d. Wiring it into this repo's HM setup

This repo's HM module entry points:
- `/home/manoj/nixos-dotfiles/home-manager/home.nix` imports `./modules`
  (i.e. `/home/manoj/nixos-dotfiles/home-manager/modules/default.nix`) and
  `./home-packages.nix`.
- `/home/manoj/nixos-dotfiles/home-manager/modules/default.nix` is the
  import list.
- HM modules are imported at the NixOS level via `home-manager.nixosModules.home-manager`
  somewhere under `/home/manoj/nixos-dotfiles/nixos/modules/` (the flake
  wires `inputs.home-manager` into `specialArgs`; the actual `homeManager`
  NixOS module import should be verified — **(unconfirmed exact file)**,
  likely in a `users`/`home` module under `nixos/modules/`).

Two changes:

1. **Import the caelestia HM module.** The cleanest place is alongside the
   flake-input HM module imports. Because the caelestia module needs the
   flake `self` reference, it is exported as
   `caelestia-shell.homeManagerModules.default` (a curried
   `self: { ... }` module). Add it to the NixOS `home-manager.sharedModules`
   (or the per-user `home-manager.users.<user>.modules`) list. Concretely,
   wherever this repo registers HM modules (find the file that sets
   `home-manager.users.manoj.modules` or `home-manager.sharedModules` —
   **needs locating**, see §6 open item), append:

   ```nix
   inputs.caelestia-shell.homeManagerModules.default
   ```

2. **Enable `programs.caelestia`** in a new HM module file, e.g.
   `/home/manoj/nixos-dotfiles/home-manager/modules/caelestia.nix`:

   ```nix
   { inputs, pkgs, ... }:
   {
     programs.caelestia = {
       enable = true;
       package = inputs.caelestia-shell.packages.${pkgs.stdenv.hostPlatform.system}.with-cli;
       systemd = {
         enable = true;
         # Default resolves to config.wayland.systemd.target == "graphical-session.target".
         # Set explicitly if you want hyprland-session.target instead:
         # target = "graphical-session.target";
         environment = [
           # Optional: keep GTK theming for Qt dialogs if desired.
           # "QT_QPA_PLATFORMTHEME=gtk3"
         ];
       };
       settings = {
         # Vendored/warm-metal overrides go here. These are merged into
         # ~/.config/caelestia/shell.json. See README for the full schema.
         # Example:
         # bar.status.showBattery = false;
         # paths.wallpaperDir = "~/Pictures/Wallpapers";
         # services.smartScheme = false;  # pin warm-metal instead of wallpaper-driven
       };
       cli = {
         enable = true;
         settings = {
           theme.enableGtk = false;  # this repo manages GTK via gtk.nix
         };
       };
     };
   }
   ```

   Then add `./caelestia.nix` to the import list in
   `/home/manoj/nixos-dotfiles/home-manager/modules/default.nix`.

---

## 3. Vendoring / overriding the config for warm-metal + custom modules

### 3a. Two separate things called "config"

Caelestia has two distinct config surfaces — keep them separate:

1. **The shell source tree** (QML + C++ plugin + CMake). This lives in the
   repo and is *built* into the package at `$out/share/caelestia-shell`.
   Snapshot-and-diverge means forking this repo. The user-editable theming
   seam inside this tree is `services/Colours.qml` (the scheme layer) and
   the token system. This is what you fork to pin warm-metal at the
   palette level.
2. **The user runtime config** (`shell.json`, `shell-tokens.json`,
   `scheme/`, `monitors/<screen>/shell.json`, `hypr-user.conf`). This lives
   in `~/.config/caelestia/` and is read at runtime — NOT built. This is
   what you symlink from this dotfiles repo.

### 3b. Where the vendored runtime config lives in this repo

Recommended: `config/.config/caelestia/` (mirrors the `~/.config/caelestia/`
path the shell reads). Add a `caelestia` entry to the `configs` map in
`/home/manoj/nixos-dotfiles/home-manager/modules/dotfiles-symlinks.nix`:

```nix
configs = {
  hypr = "hypr";
  caelestia = "caelestia";   # NEW — symlinks config/.config/caelestia → ~/.config/caelestia
  ghostty = "ghostty";
  eza = "eza";
  zsh = "zsh";
};
```

and remove `waybar`, `wlogout`, `swaync`, `wofi` from that map (see §5).

**Conflict warning:** the HM module generates `xdg.configFile."caelestia/shell.json"`
when `settings`/`extraConfig` is non-empty, while the symlink map creates
`~/.config/caelestia/` (recursive symlink for the whole dir). These will
collide on `shell.json`. Two ways to resolve:

- **Option A (recommended): let the HM module own `shell.json`.** Keep
  `settings` non-empty in `caelestia.nix` so nix generates `shell.json`
  (and the systemd `X-Restart-Triggers` fire on edit). Symlink only the
  files the HM module does NOT manage: `shell-tokens.json`, `scheme/`,
  `monitors/`, `hypr-user.conf`. To do that, move `caelestia` out of the
  `configs` (recursive) map and into the `files` (single-file) map for
  each non-managed file:
  ```nix
  files = {
    # ... existing ...
    "caelestia/shell-tokens.json" = "caelestia/shell-tokens.json";
    "caelestia/hypr-user.conf"    = "caelestia/hypr-user.conf";
  };
  ```
  and use `xdg.configFile` for `scheme/` if you want it nix-managed, or
  add more `files` entries.

- **Option B: symlink the whole dir, disable HM `shell.json` generation.**
  Set `programs.caelestia.settings = {}; extraConfig = "";` (so the module
  does not emit `shell.json`) and put a hand-written `shell.json` in
  `config/.config/caelestia/shell.json`. You lose the systemd
  `X-Restart-Triggers` restart-on-edit behaviour (the service won't auto
  restart when you change `shell.json`).

Option A fits this repo's pattern (nix-managed where possible) and keeps
the auto-restart. Use Option A.

### 3c. Can you override `shell.json` / `shell-tokens.json` / scheme without forking the derivation?

- **`shell.json`**: YES, without forking. The HM module's `settings`/
  `extraConfig` generate it at `~/.config/caelestia/shell.json`, overriding
  the built-in defaults at runtime. The derivation is untouched.
- **`shell-tokens.json`**: YES, without forking. The shell reads it from
  `~/.config/caelestia/shell-tokens.json` at runtime (README §"Advanced
  configuration"). Drop a file in `config/.config/caelestia/shell-tokens.json`
  and symlink it (Option A `files` entry). No derivation change.
- **`scheme/` (the colour palette)**: PARTIALLY. `caelestia scheme set -n
  dynamic` switches to wallpaper-driven M3; a frozen scheme can be written
  to `~/.config/caelestia/scheme/...` (path **(unconfirmed)** — README
  mentions `caelestia scheme set` but does not document the on-disk scheme
  file layout). However, to *pin* warm-metal against the default
  `services.smartScheme` behaviour, the cleanest path is: (a) set
  `services.smartScheme = false` in `shell.json` (via `settings`) to stop
  wallpaper-driven re-scheming, AND (b) either freeze a generated scheme
  file or fork the scheme layer in the vendored QML
  (`services/Colours.qml`). Forking the QML is the snapshot-and-diverge
  path and is consistent with the WF-1 decision. So: runtime override for
  *disabling* the dynamic scheme; source fork for *injecting* the warm-metal
  palette. This is the main reason snapshot-and-diverge is required rather
  than pure runtime config.

### 3d. Snapshot-and-diverge of the source tree

When forking, the flake input changes from upstream to the fork:

```nix
caelestia-shell = {
  url = "github:manoj-manoj-manivannan/caelestia-shell/v2.2.0-warmmetal";  # your fork
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Alternatively, vendor the source tree under
`/home/manoj/nixos-dotfiles/vendor/caelestia-shell/` and `callPackage` it
directly (bypassing the flake input):

```nix
# in flake.nix outputs, or in an overlay
caelestia-shell = pkgs.callPackage ./vendor/caelestia-shell/nix {
  inherit (inputs) m3shapes;   # still need the m3shapes flake-less input
  rev = "warmmetal-v2.2.0";
  stdenv = pkgs.clangStdenv;
  quickshell = inputs.quickshell.packages.${system}.default.override {
    withX11 = false; withI3 = false;
  };
  caelestia-cli = inputs.caelestia-cli.packages.${system}.default;
};
```

The vendor-the-tree approach is heavier (you now own the quickshell +
caelesstia-cli + m3shapes inputs yourself) but gives full control. The
fork-repo approach is lighter and matches the WF-1 "snapshot-and-diverge,
no submodule" decision. **Recommendation:** start with the fork-repo
approach (flake input pointing at your fork); only vendor the tree if you
need to patch the C++/CMake in ways a fork branch can't express.

---

## 4. Launching from Hyprland

### 4a. Launch method — systemd, not exec-once

The HM module starts caelestia as a systemd user service
(`caelestia.service`) `WantedBy = graphical-session.target`. So:

- **DO NOT** add an `exec-once` for caelestia.
- **DO** remove the existing `exec-once`/`hl.exec_cmd` lines that launch
  waybar and swaync (see §5).
- The service starts automatically when `graphical-session.target` becomes
  active. With this repo's `programs.hyprland.withUWSM = true` (in
  `/home/manoj/nixos-dotfiles/nixos/modules/desktop/hyprland.nix`), uwsm
  starts the Hyprland session and activates `graphical-session.target` in
  the user systemd instance. **(Needs real nix build to confirm)** that
  uwsm actually pulls in `graphical-session.target` on this NixOS setup —
  if not, set `programs.caelestia.systemd.target` to whatever target uwsm
  does activate, or fall back to `systemd.enable = false` and launch via
  `hl.exec_cmd("caelestia-shell")` in `hyprland.lua` (the README's HM
  example explicitly supports `systemd.enable = false; # if you prefer
  starting from your compositor`).

### 4b. Qt6-on-Hyprland env

- `QT_QPA_PLATFORM=wayland` is set by the HM module's service
  `Environment=`. No manual env needed.
- Blur / layer rules: caelestia's surfaces live in `quickshell:*` layer
  namespaces. To get Hyprland blur + animations on them, add layer rules
  in `/home/manoj/nixos-dotfiles/config/.config/hypr/looknfeel.lua` (or a
  new `caelestia.lua` required from `hyprland.lua`). The exact namespaces
  **(unconfirmed)** — the README does not enumerate them; check the fork's
  QML for `namespace: "quickshell:..."` strings, or copy from the full
  caelestia dots' `hypr/hyprland/` config. Pattern:
  ```lua
  hl.layer_rule({
    name  = "caelestia-blur",
    match = { namespace = "^quickshell:.*" },
    blur = true,
    -- animations = true,  -- if supported by hyprlua
  })
  ```
- `XDG_CURRENT_DESKTOP` / `GTK_THEME` etc. are already managed by this
  repo's GTK/Hyprland modules; no caelestia-specific env beyond the above.

### 4c. Keybinds — move to Hyprland DBus global shortcuts

README §"Shortcuts/IPC": "All keybinds are accessible via Hyprland global
shortcuts" (the DBus global-shortcuts-v1 protocol). Caelestia registers
shortcut IDs; the user's Hyprland config binds them with
`bindl = , <key>, global, <id>` (Hyprland `global` keyword). Example
keybinds file:
https://github.com/caelestia-dots/caelestia/blob/main/hypr/hyprland/keybinds.conf
(that's the full caelestia *dots* repo, not the shell repo).

In `/home/manoj/nixos-dotfiles/config/.config/hypr/bindings.lua`, the three
binds to replace (see §5 for the exact lines):
- `SUPER+ESCAPE` → `wlogout` → replace with caelestia's session/power
  global shortcut.
- `SUPER+SPACE` → `wofi --show drun` → replace with caelestia's launcher
  global shortcut.
- `SUPER+N` → `swaync-client -t -sw` → replace with caelestia's
  notification-center global shortcut.

The exact `global, <id>` strings **(unconfirmed)** until you read the
fork's keybinds example or the QML `GlobalShortcut` registrations. This is
a WF-4 (porting) task, but the launch wiring is: replace `hl.dsp.exec_cmd(...)`
with `hl.dsp.global_shortcut("<id>")` (or the hyprlua equivalent —
**(unconfirmed)** whether hyprlua exposes a `global` bind helper; may need
a raw `bindl` line).

### 4d. `hypr-user.conf`

Caelestia reads `~/.config/caelestia/hypr-user.conf` for Hyprland settings
that the shell wants (e.g. VRR disable for flicker). This is sourced by
caelestia's *own* hyprland integration when using the full dots; when
running only the shell on the user's existing Hyprland config, this file
is still read by the shell for shell-specific Hyprland tweaks (README FAQ
points users here for flicker/etc.). Symlink it from
`config/.config/caelestia/hypr-user.conf` (Option A `files` entry). It is
NOT a replacement for the user's `hypr/` config.

---

## 5. Removing the old tools — concrete edit checklist (for WF-5 cutover)

### 5a. `/home/manoj/nixos-dotfiles/nixos/modules/services/services.nix`

Remove from `environment.systemPackages`:
- `waybar` (line 39)
- `inotify-tools` (line 41) — only used by `waybar-autoreload.sh`
- `wlogout` (line 43)

Keep:
- `cava` (line 40) — caelestia bundles `libcava` for its own visualiser,
  but the user's custom cava pill script may still want the `cava` CLI.
  Keep until WF-4 ports/replaces the custom cava module, then re-evaluate.
- `libnotify` (line 42) — provides `notify-send`. Caelestia runs its own
  notification daemon, so swaync-style `notify-send` feedback is no longer
  the path, but shell scripts in `config/.config/hypr/scripts/` may still
  call `notify-send`. Keep until scripts are audited; remove if unused.
- `qt6.qtwayland` (line 26) — needed by Qt6 apps on Wayland (caelestia
  included). Keep.
- `playerctl`, `grim`, `slurp`, `swappy`, `ffmpeg_6-full`, `wl-screenrec`,
  `wl-clipboard`, `wl-clip-persist`, `cliphist`, `xdg-utils`, `mpv`,
  `zathura`, `qutebrowser`, `imv`, `psmisc`, `imagemagick`, `at-spi2-atk`,
  `libfido2` — unrelated to the bar stack; keep.

Note: caelestia's `propagatedBuildInputs` already bring `fish`, `ddcutil`,
`brightnessctl`, `networkmanager`, `lm_sensors`, `swappy`, `wl-clipboard`,
`libqalculate`, `bash`, `hyprland`, `pipewire`, `aubio`, `libcava`,
`fftw`, `xkeyboard-config` into the shell's runtime PATH via the wrapper.
So you do NOT need to add these to `services.nix` for caelestia. But if
other parts of the system use them directly (e.g. `brightnessctl` from
`bindings.lua` media keys — yes, line 132), keep those system-wide. The
propagated deps only land in the `caelestia-shell` wrapper's PATH, not
system-wide.

### 5b. `/home/manoj/nixos-dotfiles/home-manager/modules/dotfiles-symlinks.nix`

Remove from `configs` map (lines 9-19):
- `waybar = "waybar";`
- `wlogout = "wlogout";`
- `swaync = "swaync";`
- `wofi = "wofi";`

Add:
- `caelestia = "caelestia";` (if using Option B whole-dir symlink) OR add
  individual `files` entries for `caelestia/shell-tokens.json`,
  `caelestia/hypr-user.conf` (Option A — recommended, see §3b).

The corresponding source dirs `config/.config/waybar/`,
`config/.config/wlogout/`, `config/.config/swaync/`, `config/.config/wofi/`
can be deleted from the repo at cutover (or kept until the cutover is
verified, then deleted).

### 5c. `/home/manoj/nixos-dotfiles/config/.config/hypr/hyprland.lua`

In the `hl.on("hyprland.start", ...)` block (lines 17-37):
- Remove `hl.exec_cmd("waybar & swaybg -i ...")` — but **keep the swaybg
  half**. Split into `hl.exec_cmd("swaybg -i $HOME/nixos-dotfiles/config/wallpaper/lonely-train.jpg -m fill")`.
- Remove `hl.exec_cmd("$HOME/.config/waybar/scripts/waybar-autoreload.sh &")`.
- Remove `hl.exec_cmd("swaync")`.
- Keep `nm-applet`, `gnome-keyring-daemon`.
- Do NOT add a caelestia launch line (systemd starts it).

### 5d. `/home/manoj/nixos-dotfiles/config/.config/hypr/bindings.lua`

- Line 20: replace `hl.bind(mainMod .. " + ESCAPE", hl.dsp.exec_cmd("wlogout --protocol layer-shell"))`
  with the caelestia session global shortcut (§4c).
- Line 66: replace `hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("wofi --show drun"))`
  with the caelestia launcher global shortcut.
- Line 72: replace `hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("swaync-client -t -sw"))`
  with the caelestia notification-center global shortcut.

### 5e. `/home/manoj/nixos-dotfiles/config/.config/hypr/looknfeel.lua`

- The comment on line 21 referencing "the waybar panel (waybar/style.css)"
  should be updated to reference the caelestia shell instead (cosmetic).
- Add caelestia layer rules for `quickshell:*` namespaces (§4b).

### 5f. Packages that stay / go summary

| Package | File | Disposition |
|---|---|---|
| `waybar` | services.nix:39 | REMOVE |
| `inotify-tools` | services.nix:41 | REMOVE |
| `wlogout` | services.nix:43 | REMOVE |
| `cava` | services.nix:40 | KEEP (until cava module ported) |
| `libnotify` | services.nix:42 | KEEP (until scripts audited) |
| `qt6.qtwayland` | services.nix:26 | KEEP |
| `waybar` symlinks | dotfiles-symlinks.nix | REMOVE |
| `swaync` symlinks | dotfiles-symlinks.nix | REMOVE |
| `wofi` symlinks | dotfiles-symlinks.nix | REMOVE |
| `wlogout` symlinks | dotfiles-symlinks.nix | REMOVE |
| `caelestia` symlinks | dotfiles-symlinks.nix | ADD |

---

## 6. Open items / risks to confirm with a real nix build

1. **(Riskiest) Qt6/quickshell version match.** Caelestia's flake targets
   `nixos-unstable`; this repo is on `nixos-26.05`. With
   `inputs.nixpkgs.follows = "nixpkgs"`, caelestia's C++ plugin builds
   against 26.05's `qt6.qtbase`/`qt6.qtdeclarative`/`qt6.qtshadertools`
   and the `quickshell` input's package. If the quickshell flake's
   nixpkgs is followed too, the build may fail on a Qt ABI mismatch.
   **Confirm by `nix build .#caelestia-shell` (or the HM-enabled system)
   before committing the integration.** Mitigation: drop `follows` on
   `caelestia-shell` (let it pull unstable nixpkgs), accepting a larger
   closure.
2. **`graphical-session.target` activation under uwsm.** The caelestia
   systemd service `WantedBy = graphical-session.target`. Confirm uwsm
   (with `programs.hyprland.withUWSM = true`) activates that target in
   `systemctl --user`. If not, set `programs.caelestia.systemd.target`
   to the actual target, or use `systemd.enable = false` + `exec-once`.
3. **HM module import location.** This research did not locate the exact
   file in `/home/manoj/nixos-dotfiles/nixos/modules/` that imports
   `home-manager.nixosModules.home-manager` and sets
   `home-manager.users.manoj.modules` / `home-manager.sharedModules`.
   Find it before adding `inputs.caelestia-shell.homeManagerModules.default`
   to the module list. (The flake passes `inputs` via `specialArgs`, so the
   module can reference `inputs.caelestia-shell`.)
4. **Hyprland global-shortcut IDs and layer namespaces.** The exact
   `bindl = , ..., global, <id>` strings and the `quickshell:*` layer
   namespaces are not documented in the shell README. Read the fork's QML
   (`GlobalShortcut` registrations) and the full caelestia dots
   `hypr/hyprland/keybinds.conf` example to extract them (WF-4 task).
5. **Scheme file layout.** README documents `caelestia scheme set` but not
   the on-disk `~/.config/caelestia/scheme/` layout for a frozen/pinned
   scheme. Confirm by running `caelestia scheme set -n dynamic` once and
   inspecting `~/.config/caelestia/`, or by reading `services/Colours.qml`
   in the fork.
6. **hyprlua `global` bind helper.** `bindings.lua` uses `hl.bind(...)` /
   `hl.dsp.exec_cmd(...)`. Whether hyprlua exposes a way to emit
   `bindl = , KEY, global, ID` is unconfirmed. If not, the global-shortcut
   binds may need to be raw `hyprland.conf`-style lines (hyprlua may have
   an escape hatch) — verify against the hyprlua docs/source.

---

## Sources

- caelestia `flake.nix` @ v2.2.0: https://raw.githubusercontent.com/caelestia-dots/shell/v2.2.0/flake.nix
- caelestia `nix/default.nix` @ v2.2.0: https://raw.githubusercontent.com/caelestia-dots/shell/v2.2.0/nix/default.nix
- caelestia `nix/hm-module.nix` @ v2.2.0: https://raw.githubusercontent.com/caelestia-dots/shell/v2.2.0/nix/hm-module.nix
- caelestia `README.md` @ v2.2.0: https://raw.githubusercontent.com/caelestia-dots/shell/v2.2.0/README.md
- caelestia repo tree @ v2.2.0: https://api.github.com/repos/caelestia-dots/shell/git/trees/v2.2.0?recursive=1
- home-manager `modules/wayland.nix`: https://github.com/nix-community/home-manager/blob/master/modules/wayland.nix
- home-manager `wayland.systemd.target` option: https://mynixos.com/home-manager/option/wayland.systemd.target
- home-manager PR #6253 (standardize wayland graphical services): https://github.com/nix-community/home-manager/pull/6253
- Hyprland global shortcuts (DBind): https://wiki.hyprland.org/Configuring/Binds/#dbus-global-shortcuts
- Hyprland on HM wiki: https://wiki.hypr.land/Nix/Hyprland-on-Home-Manager/
- Local: `/home/manoj/nixos-dotfiles/flake.nix`, `/home/manoj/nixos-dotfiles/nixos/modules/services/services.nix`, `/home/manoj/nixos-dotfiles/home-manager/modules/dotfiles-symlinks.nix`, `/home/manoj/nixos-dotfiles/nixos/modules/desktop/hyprland.nix`, `/home/manoj/nixos-dotfiles/home-manager/home.nix`, `/home/manoj/nixos-dotfiles/home-manager/modules/default.nix`, `/home/manoj/nixos-dotfiles/config/.config/hypr/hyprland.lua`, `bindings.lua`, `looknfeel.lua`, `autostart.lua`