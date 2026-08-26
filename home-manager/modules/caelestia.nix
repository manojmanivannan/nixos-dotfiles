# WF-10 wired caelestia into Home-Manager (build-only); WF-11 made it the
# running shell. WF-12 pins the warm-metal palette and severs the CLI
# regeneration path so colours stay stable. See
# docs/wayfinder/tickets/pin-warm-metal-theming.md and the build spec
# docs/wayfinder/tickets/build-spec.md (Solution: Theming).
#
# The upstream HM module is registered in
# nixos/modules/nix/home-manager.nix via `home-manager.sharedModules` and
# defines the `programs.caelestia` options; this module enables it.

{
  config,
  lib,
  inputs,
  pkgs,
  weatherLocation,
  ...
}:

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
  shellPackage =
    let
      base = inputs.caelestia-shell.packages.${pkgs.stdenv.hostPlatform.system}.with-cli;
      # WF-12: shell.json is a read-only Nix-store symlink (the HM
      # `programs.caelestia` module writes it via `xdg.configFile.*.text`,
      # which HM always symlinks into the store). GlobalConfig (which inherits
      # RootConfig) auto-saves to it on every property change after load
      # (plugin/src/Caelestia/Config/rootconfig.cpp:106-114); the write hits
      # EROFS and emits `saveFailed`, which ConfigToasts.qml renders as the
      # "Failed to save config" Error toast on every launch. The read-only
      # failure is *expected* here — the file is pinned by Nix on purpose
      # (the pin is the WF-12 design; runtime saves are intentionally dropped,
      # the WARN log still records them). Gate only this case so genuine save
      # failures (disk full, permissions, …) still surface as toasts.
      # `file.errorString()` is "Read-only file system" for EROFS; the
      # substituted line is unique in the file (verified).
      #
      # The `emit saveFailed` is compiled by the `plugin` derivation
      # (caelestia-qml-plugin, exposed as `base.plugin`) — a SEPARATE
      # derivation from the shell. The shell's own `src` contains
      # rootconfig.cpp, so a sed in the shell's postPatch rewrites it, but
      # the shell never compiles the C++ plugin (its cmake builds only
      # ENABLE_MODULES=shell), so the edit is discarded — the loaded .so comes
      # from `base.plugin`. The guard must therefore patch the *plugin*
      # derivation, and the patched plugin must be swapped back into the
      # shell's buildInputs (otherwise wrapQtAppsHook still points the QML
      # import path at the unpatched .so). See memory
      # caelestia-shelljson-readonly-save-toast.
      patchedPlugin = base.plugin.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          sed -i 's|emit saveFailed(err, m_screen);|if (!file.errorString().contains("Read-only file system")) emit saveFailed(err, m_screen);|' \
            plugin/src/Caelestia/Config/rootconfig.cpp
        '';
      });
    in
    base.overrideAttrs (old: {
      # Swap the unpatched `base.plugin` for `patchedPlugin` so the shell's
      # Qt wrapper resolves the Caelestia.Config .so from the patched build.
      buildInputs = map (b: if b == base.plugin then patchedPlugin else b) (old.buildInputs or [ ]);
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

        # Drop the rotating GIF (an animated image — the default caelestia
        # "sessionGif", an anime-girl spin) wedged between the Shutdown and
        # Hibernate buttons in modules/session/Content.qml. There's no config
        # flag to hide it (only `general.sessionGifSpeed` to freeze a frame and
        # `paths.sessionGif` to swap the asset), so patch the QML: delete the
        # whole `AnimatedImage { … }` block (4-space-indented, lines 52-62 in
        # the pinned v2.2.0 source). The two flanking SessionButtons collapse
        # together; KeyNavigation.shutdown→hibernate still chains since it
        # references the `hibernate` id, not the removed item.
        sed -i '/^    AnimatedImage {/,/^    }$/d' modules/session/Content.qml

        # Lock-screen resource widgets (modules/lock/Resources.qml). Three
        # `Resource {}` blocks render CPU / Memory / Disk, each with `colour`
        # (the percentage number), `shapeColour` (the shape backdrop the number
        # sits on), and `fillColour` (the wavy fill bar). Upstream paints each
        # in a different token family — CPU gold/amber (m3primary /
        # m3primaryContainer), Memory teal-on-dark (m3tertiary / m3onTertiary),
        # Disk terracotta/amber (m3secondary / m3secondaryContainer) — and the
        # percentage text used the same warm token as its shape (gold-on-amber,
        # terracotta-on-amber), which is low-contrast and hard to read on the
        # espresso lock screen.
        #
        # Two fixes in one pass:
        #  1. Unify all three widgets on the gold/amber scheme — shape backdrop
        #     `m3primaryContainer` (#c08a4f amber), fill bar `m3primary @ 0.3`
        #     (#e8c272 gold) — so the widgets read as one family.
        #  2. Make the text clearer. The percentage number renders on top of the
        #     amber shape, so use `m3onPrimaryContainer` (#f0dca0 pale cream) —
        #     the Material "on primaryContainer" token, the high-contrast text
        #     colour designed for content on the amber container, still in the
        #     gold/cream family. The widget icons are recolored to the same pale
        #     cream (upstream hard-coded them to m3secondary / #d99069 terracotta,
        #     which read pinkish and muddy on the amber shape).
        # The CPU temperature badge originally sat on m3secondaryContainer
        # (#c08a4f amber) — the *same* value as m3primaryContainer here, so the
        # circle was indistinguishable from the pentagon behind it. Its
        # normal-state backdrop is shifted to m3primary (#e8c272 gold) for a
        # subtle in-family differentiation, and its label to m3onPrimary
        # (#322a21 dark brown) for contrast on the brighter gold. The >90C hot
        # state stays m3errorContainer / m3onErrorContainer (already clear).
        # Widget shapes (Pentagon / Slanted / Gem) are left alone.
        #
        # Every target line is globally unique in this file — the per-widget
        # token (m3tertiary / m3primary / m3secondary) and the 0.3 / 0.4 alpha
        # variants disambiguate the fill lines, and the British `colour:` /
        # `shapeColour:` spelling keeps these distinct from the temperature
        # badge's American `color:` ternary lines — so content matches are exact
        # and survive upstream line drift.
        # Memory widget (teal-on-dark -> gold/amber + clear text).
        sed -i 's|colour: Colours.palette.m3tertiary$|colour: Colours.palette.m3onPrimaryContainer|' modules/lock/Resources.qml
        sed -i 's|shapeColour: Colours.palette.m3onTertiary$|shapeColour: Colours.palette.m3primaryContainer|' modules/lock/Resources.qml
        sed -i 's|fillColour: Qt.alpha(Colours.palette.m3tertiary, 0.3)|fillColour: Qt.alpha(Colours.palette.m3primary, 0.3)|' modules/lock/Resources.qml
        # CPU widget (already gold/amber shape; clearer text + gold fill).
        sed -i 's|colour: Colours.palette.m3primary$|colour: Colours.palette.m3onPrimaryContainer|' modules/lock/Resources.qml
        sed -i 's|fillColour: Qt.alpha(Colours.palette.m3secondary, 0.3)|fillColour: Qt.alpha(Colours.palette.m3primary, 0.3)|' modules/lock/Resources.qml
        # Disk widget (terracotta/amber -> gold/amber + clear text).
        sed -i 's|colour: Colours.palette.m3secondary$|colour: Colours.palette.m3onPrimaryContainer|' modules/lock/Resources.qml
        sed -i 's|shapeColour: Colours.palette.m3secondaryContainer$|shapeColour: Colours.palette.m3primaryContainer|' modules/lock/Resources.qml
        sed -i 's|fillColour: Qt.alpha(Colours.palette.m3secondary, 0.4)|fillColour: Qt.alpha(Colours.palette.m3primary, 0.3)|' modules/lock/Resources.qml
        # Widget icons (terracotta -> pale cream). American `color:` + the bare
        # `m3secondary` token + `$` anchor matches only the shared icon line, not
        # the disk widget's British `colour:` number or the temp-label ternary.
        sed -i 's|color: Colours.palette.m3secondary$|color: Colours.palette.m3onPrimaryContainer|' modules/lock/Resources.qml
        # CPU temperature badge backdrop, normal state (amber -> gold to
        # differentiate from the amber widget shape). Hot (>90C) branch stays
        # m3errorContainer.
        sed -i 's|color: Cpu.temperature > 90 ? Colours.palette.m3errorContainer : Colours.palette.m3secondaryContainer$|color: Cpu.temperature > 90 ? Colours.palette.m3errorContainer : Colours.palette.m3primary|' modules/lock/Resources.qml
        # CPU temperature label, normal state (terracotta -> dark brown, for
        # contrast on the new gold badge). Hot (>90C) branch stays m3onErrorContainer.
        sed -i 's|m3onErrorContainer : Colours.palette.m3secondary$|m3onErrorContainer : Colours.palette.m3onPrimary|' modules/lock/Resources.qml

        # Dashboard Performance tab (modules/dashboard/Performance.qml). The two
        # HeroCards (CPU / GPU) take an `accent` colour that drives every accented
        # element in the card — the MaterialIcon, the "CPU"/"GPU" label, the
        # thermometer icon + StyledProgressBar, and the usage % number (which is
        # `color: root.accent` in HeroCard.qml). Upstream keys CPU to m3primary
        # (#e8c272 gold) and GPU to m3secondary (#d99069 terracotta), so the GPU
        # card reads pink next to the gold CPU card — the same terracotta-on-espresso
        # clash fixed above for the lock-screen widgets. Recolour the GPU card to
        # m3primary so both cards read as one gold family. The line is globally
        # unique in this file: only the GPU HeroCard uses `m3secondary`; the CPU
        # card's `accent: Colours.palette.m3primary` is untouched.
        sed -i 's|accent: Colours.palette.m3secondary$|accent: Colours.palette.m3primary|' modules/dashboard/Performance.qml

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
        # 0004 — bar clock: add month + year to the date block. Upstream's
        # BarClock date Loader (modules/bar/components/Clock.qml) renders only
        # the weekday abbreviation ("ddd") and the day-of-month number ("d")
        # when `Config.bar.clock.showDate` is on. Insert two StyledText lines
        # after the day number (before the divider) for the abbreviated month
        # ("MMM", e.g. "Aug") and the four-digit year ("yyyy", e.g. "2026"),
        # styled like the weekday line (small 0.9). `Time.format` wraps
        # Qt.formatDateTime, so these are standard Qt date tokens. Exact
        # against v2.2.0; --fuzz=0 fails the build if upstream drifts.
        patch -p1 --fuzz=0 < ${./caelestia-overrides/0004-clock-show-month-year.patch}

        # WF-14 — password-only lock PAM. Caelestia's lock can authenticate three
        # ways: `passwd` (password), `fprint` (pam_fprintd.so), and `howdy`
        # (pam_howdy.so) — see modules/lock/Pam.qml. The build spec (WF-8 Solution:
        # Lock screen) drops fingerprint/face/Yubikey at the lock screen. Two
        # layers make that hold:
        #   1. `lock.enableFprint`/`enableHowdy` = false in `settings` below stops
        #      the ManualPamContexts from ever starting (their `canAttempt` gate
        #      is `available && enabled && ...`, and `enabled` binds to these).
        #   2. This rewrite drops the `pam_fprintd.so` / `pam_howdy.so` auth lines
        #      from the vendored PAM files themselves — the "build-phase PAM
        #      rewrite of the same shape caelestia's derivation already does" the
        #      spec calls for (upstream's prePatch only rewrites the .so *paths*;
        #      we remove the lines). Defense in depth: even if a future `enable*`
        #      flip re-arms a context, the PAM file has no module to load.
        # The files keep their `%PAM-1.0` header so they remain valid PAM files;
        # they're simply inert (no auth lines) and unreferenced once disabled.
        printf '%s\n' '#%PAM-1.0' > assets/pam.d/fprint
        printf '%s\n' '#%PAM-1.0' > assets/pam.d/howdy
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

      # Qt Quick render-thread + continuous-update so the shell's own UI
      # (drawers, toasts, the bongo-cat, animated widgets) tracks the
      # monitor's refresh rate instead of stalling at ~60Hz / below. On
      # NVIDIA (the RTX 4090 here) the default QSG render loop lets the
      # compositor-bound shell surface cap below the display rate, so the
      # panel feels choppy even though hyprctl reports 3840x2160@60. The
      # upstream fix for this is caelestia-dots/shell#431, which sets these
      # two env vars on the `caelestia shell -d` launch line — here the
      # shell runs as a systemd user service (above), so the vars go into
      # the unit's `Environment=` via the upstream module's
      # `programs.caelestia.systemd.environment` option (appended after the
      # module's own `QT_QPA_PLATFORM=wayland`). `QSG_RENDER_LOOP=threaded`
      # moves scene graph rendering off the GUI thread; `QT_QUICK_CONTINUOUS_UPDATE=1`
      # keeps the render loop pumping vsync-driven frames so animations
      # don't gate on input/paint events. Both are effective only for the
      # shell process, so a unit-scoped env is the right scope (no need to
      # pollute the session env).
      environment = [
        "QSG_RENDER_LOOP=threaded"
        "QT_QUICK_CONTINUOUS_UPDATE=1"
      ];
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

      # Weather temperatures in Celsius. Caelestia's Weather service formats
      # via `GlobalConfig.services.useFahrenheit` (services/Weather.qml:30, and
      # the LanguageAndRegion Nexus page binds the same key). Stated
      # explicitly to pin Celsius rather than rely on the (false) default.
      services.useFahrenheit = false;

      # Weather location is defined centrally in the flake so it is easy to
      # change per machine/user without editing the shell module. The weather
      # service accepts either a city string or coordinates; plain city names
      # are more readable and avoid the wrong-ISP fallback to Southampton.
      services.weatherLocation = weatherLocation;

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

      # Bar clock: show the date + day-of-week under the time. Caelestia's
      # BarClock (plugin/src/Caelestia/Config/barconfig.hpp) defaults
      # `showDate = false`, so the bar renders only the hour/minute by default.
      # Flipping it on adds the weekday abbreviation ("ddd"), the day-of-month
      # number ("d"), and a divider line above the time — see
      # modules/bar/components/Clock.qml's `Config.bar.clock.showDate` Loader.
      # `showIcon` already defaults true (the calendar_month glyph), so it's
      # left untouched.
      bar.clock.showDate = true;

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

      # WF-14 — lock screen: password-only. Caelestia's lock can use password
      # (`passwd`), fingerprint (`fprint`, pam_fprintd.so), and face (`howdy`,
      # pam_howdy.so); the build spec (WF-8 Solution: Lock screen) drops
      # fingerprint/face/Yubikey at the lock screen. These are GLOBAL config
      # properties (CONFIG_GLOBAL_PROPERTY in lockconfig.hpp), so they sit
      # under the top-level `lock` key. Disabling them here stops the
      # ManualPamContexts in modules/lock/Pam.qml from starting (their
      # `canAttempt` gate is `available && enabled && …`); the PAM-file rewrite
      # in the package postPatch above is the defense-in-depth second layer.
      # `triggerHowdyOnWake` is moot once howdy is disabled, but set false too
      # so no `howdy.start()` is ever attempted on resume.
      lock = {
        enableFprint = false;
        enableHowdy = false;
        triggerHowdyOnWake = false;
      };

      # WF-14 — hypridle is the sole idle daemon. The build spec (WF-8
      # Solution: Idle) assumed "Caelestia ships no idle module"; v2.2.0 in
      # fact ships `modules/IdleMonitors.qml` (Quickshell `IdleMonitor`s) with
      # DEFAULT timeouts that lock at 180s, dpms-off at 300s, and
      # suspend-then-hibernate at 600s (generalconfig.hpp `GeneralIdle.timeouts`).
      # Left active, those race the WF-14 hypridle listener — the 180s lock
      # would fire before the 600s auto-lock (user story #13 wants ~10 min, not
      # 3), and the 600s suspend-then-hibernate would suspend the box right when
      # hypridle locks it. Clearing `timeouts` (lists replace, per the WF-12
      # merge note) disables every caelestia IdleMonitor so hypridle alone
      # drives idle→lock at 600s, exactly as WF-14 mandates. `lockBeforeSleep`
      # (default true) is left untouched — it fires on logind `PrepareForSleep`
      # independent of `timeouts`, so a manual suspend still locks first.
      general.idle.timeouts = [ ];

      # WF-14 — power-menu logout tears down the systemd Wayland session
      # cleanly via `uwsm stop` (user story #10), not logind's raw `Terminate`
      # that caelestia's `SessionManager::logout()` would call for the default
      # `["logout"]` command (sessionmanager.cpp). `SessionManager.exec` only
      # maps a fixed set of words (logout/suspend/hibernate/poweroff/reboot) to
      # DBus calls; `uwsm` isn't one, so `exec` returns false and the
      # SessionButton falls back to `Quickshell.execDetached(command)`
      # (modules/session/Content.qml) — i.e. it runs `uwsm stop` directly.
      # `uwsm` ships from `programs.hyprland.withUWSM = true`
      # (nixos/modules/desktop/hyprland.nix). The session menu's action set is
      # otherwise caelestia's default (logout/shutdown/hibernate/reboot —
      # suspend already absent, per the spec), so only `logout` is overridden.
      session.commands.logout = [
        "uwsm"
        "stop"
      ];

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
          command = [
            "autocomplete"
            "calc"
          ];
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
          # WF-14 — `uwsm stop`, matching the power-menu logout above (clean
          # systemd Wayland-session teardown). `SessionManager.exec` returns
          # false for `uwsm` for the same reason as `session.commands.logout`
          # above, so this likewise falls through to `Quickshell.execDetached`.
          command = [
            "uwsm"
            "stop"
          ];
          dangerous = true;
        }
        {
          name = "Lock";
          icon = "lock";
          description = "Lock the current session";
          # WF-14 — targets caelestia's `Lock` module (no rerouting). With
          # hyprlock retired, `loginctl lock-session`'s logind `Lock` signal is
          # bridged exclusively by caelestia's SessionManager ->
          # `WlSessionLock.locked` (plugin/src/Caelestia/Services/
          # sessionmanager.cpp + modules/IdleMonitors.qml `onLockRequested`),
          # so this surfaces the caelestia lock screen, not a hyprlock one.
          command = [
            "loginctl"
            "lock-session"
          ];
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
          command = [
            "caelestia"
            "shell"
            "nexus"
            "open"
          ];
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

  # Profile picture. Caelestia's dashboard (modules/dashboard/dash/User.qml)
  # and lock screen (modules/lock/center/ProfilePic.qml) both source the avatar
  # from `${Paths.home}/.face` — there is no shell.json config key for it, the
  # Nexus "Select a profile picture" picker just `CUtils.copyFile`s the chosen
  # image to `~/.face`. Pin the repo's
  # caelestia-overrides/profile_picture.jpg there via HM so it's managed
  # (symlinked from the store, reproducible) rather than a loose runtime copy.
  home.file.".face".source = ./caelestia-overrides/profile_picture.jpg;
}
