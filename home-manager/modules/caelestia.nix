# WF-10 wired caelestia into Home-Manager (build-only); WF-11 made it the
# running shell. WF-12 pins the warm-metal palette and severs the CLI
# regeneration path so colours stay stable. See
# docs/wayfinder/tickets/pin-warm-metal-theming.md and the build spec
# docs/wayfinder/tickets/build-spec.md (Solution: Theming).
#
# The upstream HM module is registered in
# nixos/modules/nix/home-manager.nix via `home-manager.sharedModules` and
# defines the `programs.caelestia` options; this module enables it.

{ config, lib, inputs, pkgs, ... }:

let
  # The repo checkout root (matches the convention in
  # dotfiles-symlinks.nix: `${config.home.homeDirectory}/nixos-dotfiles`).
  repoRoot = "${config.home.homeDirectory}/nixos-dotfiles";

  # The vendored warm-metal scheme source in this repo (the file the shell
  # reads is symlinked from it at activation — see `caelestiaState` below).
  # `services/Colours.qml` reads `${Paths.state}/scheme.json`, i.e.
  # ~/.local/state/caelestia/scheme.json — NOT ~/.config/caelestia/scheme/.
  schemeSource = "${repoRoot}/config/.config/caelestia/scheme/scheme.json";

  # The wallpaper swaybg already launches (config/.config/hypr/hyprland.lua).
  # Reused as caelestia's wallpaper path so the shell's ImageAnalyser (the
  # transparency-luminance tracker) and the bundled background render see
  # the same warm-metal wallpaper.
  wallpaperPath = "${repoRoot}/config/wallpaper/lonely-train.jpg";

  # WF-12: the caelestia package with the Nexus "Wallpaper & style" page
  # removed from the page registries. The page is the shell's only
  # settings UI for changing the wallpaper / scheme / variant / mode, and
  # every control on it regenerates ~/.local/state/caelestia/scheme.json via
  # the CLI (`Colours.setMode`, `Wallpapers.setWallpaper`/`setRandom`,
  # colour/variant selection). Removing it from BOTH the metadata list
  # (modules/nexus/PageRegistry.qml) and the component list
  # (modules/nexus/PageCompRegistry.qml) — kept parallel — leaves no UI
  # trigger that can overwrite the pinned scheme. The launcher's
  # `>scheme`/`>variant`/`>wallpaper`/`Random`/`Light`/`Dark` actions are
  # the other regen triggers and are dropped from `settings.launcher.actions`
  # below; together they fully sever the CLI regen path (the spec's
  # build-phase risk #4). The page's QML files still ship (unreferenced) —
  # only the registry entries are excised, the minimal snapshot-and-diverge
  # edit.
  shellPackage = inputs.caelestia-shell.packages.${pkgs.stdenv.hostPlatform.system}.with-cli.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      # WF-12: drop the Nexus "Wallpaper & style" page from both registries.
      # `sed` deletes from the `// Appearance` comment through the closing
      # `},` at 8-space indent (the first such line after the comment) — the
      # page object / Component block. Verified against the upstream QML;
      # the two lists stay parallel (both now start at Network, index 0).
      sed -i '/\/\/ Appearance/,/^        },$/d' modules/nexus/PageRegistry.qml
      sed -i '/\/\/ Appearance/,/^        },$/d' modules/nexus/PageCompRegistry.qml
      # The now-unused import of the wallandstyle page components.
      sed -i '/^import qs\.modules\.nexus\.pages\.wallandstyle$/d' modules/nexus/PageCompRegistry.qml

      # WF-12: shell.json is a read-only Nix-store symlink (the HM
      # `programs.caelestia` module writes it via `xdg.configFile.*.text`,
      # which HM always symlinks into the store). The shell's RootConfig
      # auto-saves to it on every property change after load
      # (plugin/src/Caelestia/Config/rootconfig.cpp:106-114); the write hits
      # EROFS and emits `saveFailed`, which ConfigToasts.qml renders as the
      # "Failed to save config" Error toast on every launch. The read-only
      # failure is *expected* here — the file is pinned by Nix on purpose
      # (the pin is the WF-12 design; runtime saves are intentionally
      # dropped, the WARN log below still records them). Gate only this
      # case so genuine save failures (disk full, permissions, …) still
      # surface as toasts. `file.errorString()` is "Read-only file system"
      # for EROFS; the substituted line is unique in the file (verified).
      sed -i 's|emit saveFailed(err, m_screen);|if (!file.errorString().contains("Read-only file system")) emit saveFailed(err, m_screen);|' \
        plugin/src/Caelestia/Config/rootconfig.cpp

      # WF-13 — the tailscale custom module (the one ported module). Ships the
      # new QML + brand asset into the source tree and patches the existing
      # StatusIcons / Content / barconfig.hpp to wire them in. The new files
      # live in home-manager/modules/caelestia-overrides/ as real repo files
      # (reviewable, lintable by eye); the path interpolations below copy them
      # into this nix-store build tree (the caelestia-shell flake input's
      # derivation can't see this repo directly — only paths interpolated into
      # the postPatch string). See docs/wayfinder/tickets/
      # tailscale-custom-module.md.
      #
      # services/Tailscale.qml        — Process-wrapped singleton (status poll
      #                                  + toggle/switch/set-exit-node). Auto-
      #                                  registered as a singleton by the
      #                                  quickshell config-loader's qmldir
      #                                  generation (no qmldir in the source).
      # modules/bar/popouts/TailscalePopout.qml — the hover popout. Referenced
      #                                  from Content.qml as `TailscalePopout`
      #                                  (same-dir implicit import, like the
      #                                  Network/Battery popouts).
      # assets/tailscale_{on,off}.png — brand marks; the bar icon (an Image in
      #                                  the StatusIcons patch) swaps between
      #                                  them on Tailscale.up, so the colour
      #                                  (green/grey) is baked into the PNGs
      #                                  rather than applied at runtime.
      cp ${./caelestia-overrides/Tailscale.qml} services/Tailscale.qml
      cp ${./caelestia-overrides/TailscalePopout.qml} modules/bar/popouts/TailscalePopout.qml
      cp ${./caelestia-overrides/tailscale_on.png} assets/tailscale_on.png
      cp ${./caelestia-overrides/tailscale_off.png} assets/tailscale_off.png
      # --fuzz=0: the patches are exact against the pinned v2.2.0 source; fail
      # cleanly (build red) rather than fuzz-applying if upstream drifts.
      patch -p1 --fuzz=0 < ${./caelestia-overrides/0001-statusicons-tailscale.patch}
      patch -p1 --fuzz=0 < ${./caelestia-overrides/0002-content-tailscale.patch}
      patch -p1 --fuzz=0 < ${./caelestia-overrides/0003-barconfig-showTailscale.patch}
    '';
  });
in
{
  programs.caelestia = {
    enable = true;
    # `with-cli` bundles `caelestia-cli` into the shell wrapper so the
    # shell's own IPC works (shell subcommands). The CLI is the sole writer
    # of scheme.json — WF-12 severs every UI path that invokes it, so the
    # binary ships but is never called by the shell (the spec's "with the
    # `with-cli` package" decision, WF-2).
    package = shellPackage;

    systemd = {
      enable = true;
      # `target` is left at its default — `config.wayland.systemd.target`,
      # which HM defines (in its always-imported `wayland.nix`) as
      # "graphical-session.target", the target uwsm activates for this
      # Hyprland session (`programs.hyprland.withUWSM = true`). Confirmed
      # activating under uwsm in WF-11; no fallback needed.
    };

    # WF-12 theming payload. `settings` is merged (lib.recursiveUpdate) over
    # the C++ plugin defaults to generate ~/.config/caelestia/shell.json;
    # attrsets merge recursively, lists REPLACE (so `launcher.actions` is the
    # full curated set, not appended to the default actions). The C++
    # config loader likewise writes the JSON array straight onto the
    # QVariantList (configobject.cpp `loadFromJson` → `prop.write`), so the
    # override is a full replace.
    settings = {
      # Hygiene only, per WF-3: `smartScheme: false` stops the shell passing
      # smart-mode/variant guesses to the CLI — it does NOT by itself freeze
      # the palette (a `caelestia wallpaper -f` still regenerates). The real
      # freeze is the vendored static scheme.json + the severed regen path
      # (path.txt pre-populated, Nexus page removed, regen launcher actions
      # dropped) — see the activation script below + the package postPatch.
      services.smartScheme = false;

      appearance.transparency = {
        # Transparency is the lever that makes the shell glassy and — via
        # `Colours.qml:reloadHyprRules` — toggles Hyprland `layerrule blur`
        # on the `caelestia-drawers` namespace at runtime. Combined with the
        # static `^caelestia-` blur rule in config/.config/hypr/looknfeel.lua
        # (WF-11), every shell surface gets the dual-kawase blur the
        # destination wants. base/layers are the shipped defaults, stated
        # explicitly so the fancy lever is pinned, not left implicit.
        enabled = true;
        base = 0.85;
        layers = 0.4;
      };

      background = {
        # Caelestia's background module renders the wallpaper on the
        # `WlrLayer.Background` layer — the same layer swaybg paints (the
        # wallpaper launcher WF-11 kept in hyprland.lua). Disabling it
        # (a) avoids a competing Background-layer surface double-rendering
        # the wallpaper and (b) severs the module's built-in
        # "Wallpaper missing? Set it now!" picker (modules/background/
        # Wallpaper.qml), which calls `Wallpapers.setWallpaper` — another
        # CLI regen trigger. swaybg remains the wallpaper renderer; the
        # translucent shell surfaces blur swaybg's wallpaper through the
        # WF-11 `^caelestia-` blur layer rule. `wallpaperEnabled` stated
        # false too so the criterion is explicit, not implicit.
        enabled = false;
        wallpaperEnabled = false;
      };

      # WF-12: the launcher actions minus every scheme-regenerating one.
      # Dropped: `>scheme` / `>variant` / `>wallpaper` (autocomplete →
      # Schemes.qml / M3Variants.qml / the wallpaper grid, all of which
      # `caelestia scheme set` / `wallpaper -f` and overwrite scheme.json),
      # `Random` (`caelestia wallpaper -r`), and `Light` / `Dark`
      # (`Colours.setMode` → `caelestia scheme set -m`, regen with a flipped
      # mode). The spec names the first three; the other three are the same
      # regen path and are dropped for the "no UI trigger left" gate
      # (build-phase risk #4). Kept: Calculator, the power actions (Shutdown
      # / Reboot / Logout are `dangerous` and hidden unless
      # `enableDangerousActions` is toggled, which we leave at its default
      # `false` — the SUPER+ESCAPE power menu is the real power surface),
      # Lock, Sleep, and Settings (opens the Nexus, which still has every
      # non-regen settings page).
      launcher.actions = [
        {
          name = "Calculator";
          icon = "calculate";
          description = "Do simple math equations (powered by Qalc)";
          command = [ "autocomplete" "calc" ];
        }
        {
          name = "Shutdown";
          icon = "power_settings_new";
          description = "Shutdown the system";
          command = [ "poweroff" ];
          dangerous = true;
        }
        {
          name = "Reboot";
          icon = "cached";
          description = "Reboot the system";
          command = [ "reboot" ];
          dangerous = true;
        }
        {
          name = "Logout";
          icon = "exit_to_app";
          description = "Log out of the current session";
          command = [ "logout" ];
          dangerous = true;
        }
        {
          name = "Lock";
          icon = "lock";
          description = "Lock the current session";
          command = [ "loginctl" "lock-session" ];
        }
        {
          name = "Sleep";
          icon = "bedtime";
          description = "Suspend then hibernate";
          command = [ "suspendThenHibernate" ];
        }
        {
          name = "Settings";
          icon = "settings";
          description = "Configure the shell";
          command = [ "caelestia" "shell" "nexus" "open" ];
        }
      ];
    };
  };

  # WF-12: deliver the vendored scheme + a pre-populated wallpaper path to
  # the STATE directory the shell reads (~/.local/state/caelestia/). Home
  # Manager's xdg.configFile writes to ~/.config, not ~/.local/state, so
  # this is an activation script mirroring the mkOutOfStoreSymlink pattern
  # in dotfiles-symlinks.nix but targeting state. scheme.json is a symlink
  # to the repo source so edits reload on shell restart (the file is static
  # — pinned — so no live regeneration is wanted). path.txt is a plain file
  # so `Wallpapers.qml`'s FileView never fires its empty/missing fallback
  # (`caelestia wallpaper -f`, which would overwrite scheme.json).
  home.activation.caelestiaState = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "$HOME/.local/state/caelestia/wallpaper"
    # `-sfn`: force (overwrite any prior CLI-generated scheme.json from the
    # WF-11 default-theme live session) and no-dereference (safe if a
    # symlink already exists). This is the pin.
    $DRY_RUN_CMD ln -sfn "${schemeSource}" "$HOME/.local/state/caelestia/scheme.json"
    # Pre-populate the wallpaper path so the empty/missing-path fallback in
    # services/Wallpapers.qml never regenerates. Points at the same
    # wallpaper swaybg launches.
    $DRY_RUN_CMD echo "${wallpaperPath}" > "$HOME/.local/state/caelestia/wallpaper/path.txt"
  '';
}