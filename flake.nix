{
  description = "Manoj's NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    systems.url = "github:nix-systems/x86_64-linux";
    hyprland.url = "github:hyprwm/Hyprland";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # WF-10 — the quickshell full shell. Fork `caelestia-dots/shell` @
    # v2.2.0 (Hyprland-native, full-shell, ships its own Nix flake + HM
    # module `programs.caelestia`). Pointed at upstream until the
    # snapshot-and-diverge fork exists (WF-1); the URL is the only thing
    # that changes then.
    #
    # Deliberately NO `inputs.nixpkgs.follows`: caelestia targets
    # `nixos-unstable` and its C++/CMake plugin builds against its own
    # `quickshell` + Qt6. Forcing this repo's `nixos-26.05` nixpkgs via
    # `follows` would make the plugin compile against 26.05's Qt6 while
    # quickshell ships its own — a Qt ABI mismatch risk (the spec's
    # riskiest build-phase item). Dropping `follows` lets caelestia pull
    # its own nixpkgs (larger closure, but the toolchain upstream tests
    # against). Confirm the build stays green — WF-10 build-phase risk #1.
    caelestia-shell.url = "github:caelestia-dots/shell/v2.2.0";

    # try — a single-file Ruby CLI (tobi/try) for spinning up date-prefixed
    # experiment dirs (`2025-08-17-redis-experiment`) with fuzzy navigation.
    # Ships its own Nix flake + HM module `programs.try` that auto-wires
    # `eval "$(try init <path>)"` into zsh's initContent. Enabled per-user in
    # home-manager/modules/try.nix with experiments at ~/Experiments.
    try.url = "github:tobi/try";

    # herdr — a terminal session manager (github.com/herdrdev/herdr). Ships its
    # own Nix flake exposing `packages.${system}.default`; no HM module, so it's
    # consumed directly as a home package in home-manager/home-packages.nix.
    # Pinned to a release tag (the docs' recommendation over tracking master);
    # bump the tag here and `nix flake update herdr` to upgrade.
    herdr.url = "github:herdrdev/herdr/v0.8.2";

    # Google Antigravity - Next-generation agentic IDE suite (Base App, IDE, and CLI `agy`)
    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";
      stateVersion = "26.05";
      user = "manoj";

      pkgs = nixpkgs.legacyPackages.${system};
      # `name` is the stable identity of the host config: it keys the flake
      # output (nixosConfigurations.${name}, i.e. `.#nixos`) and the
      # hosts/${name}/ folder. `hostname` is the machine's network hostname
      # (networking.hostName), and `ipv4Address`/`defaultGateway` are its
      # static network config — a cloner only needs to change these fields.
      hosts = [
        {
          name = "nixos";
          hostname = "linux-machine";
          ipv4Address = "192.168.1.192";
          defaultGateway = "192.168.1.1";
          inherit stateVersion;
        }
      ];

      makeSystem =
        {
          name,
          hostname,
          ipv4Address,
          defaultGateway,
          stateVersion,
          profile ? "full",
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit
              inputs
              stateVersion
              hostname
              user
              ipv4Address
              defaultGateway
              profile
              ;
          };
          modules = [
            ./hosts/${name}/configuration.nix
          ];
        };

      nixosConfigurations = nixpkgs.lib.foldl' (
        configs: host:
        configs
        // {
          "${host.name}" = makeSystem {
            inherit (host)
              name
              hostname
              ipv4Address
              defaultGateway
              stateVersion
              ;
            profile = host.profile or "full";
          };
        }
      ) { } hosts;

      # Each host's system toplevel as a buildable derivation. Exposed as the
      # `packages.${system}` output so the spec's seam — `nix build .#nixos` —
      # resolves: a `nixosConfigurations.<name>` entry is an evaluated module
      # set, not a derivation, so `nix build` needs a derivation attribute to
      # build. This is the same toplevel that `nixos-rebuild build` produces.
      systemToplevels = nixpkgs.lib.genAttrs (map (host: host.name) hosts) (
        name: nixosConfigurations.${name}.config.system.build.toplevel
      );

      # Profile evaluation test configurations: evaluate both 'minimal' and 'full'
      # profiles to assert package membership and module gating.
      evalProfileConfig =
        prof:
        (makeSystem {
          name = "nixos";
          hostname = "linux-machine";
          ipv4Address = "192.168.1.192";
          defaultGateway = "192.168.1.1";
          inherit stateVersion;
          profile = prof;
        }).config;

      profileConfigs = {
        minimal = evalProfileConfig "minimal";
        full = evalProfileConfig "full";
      };

      # Collect all resolved packages across system, per-user, and home-manager scopes
      collectPackages =
        cfg:
        let
          sysPkgs = cfg.environment.systemPackages;
          userPkgs = pkgs.lib.concatLists (pkgs.lib.mapAttrsToList (_: u: u.packages or [ ]) cfg.users.users);
          hmPkgs = pkgs.lib.concatLists (
            pkgs.lib.mapAttrsToList (_: u: u.home.packages or [ ]) (cfg.home-manager.users or { })
          );
        in
        sysPkgs ++ userPkgs ++ hmPkgs;

      hasPackage =
        cfg: name:
        let
          allPkgs = collectPackages cfg;
          pkgName = p: p.pname or (builtins.parseDrvName (p.name or "")).name;
        in
        pkgs.lib.any (
          p:
          let
            pn = pkgName p;
          in
          pn == name || pkgs.lib.hasPrefix (name + "-") (p.name or "") || pkgs.lib.hasPrefix (name + "-") pn
        ) allPkgs;

      hostBuildChecks = nixpkgs.lib.mapAttrs (
        name: toplevel:
        pkgs.runCommand "check-${name}-builds"
          {
            meta.description = "WF-9: the ${name} NixOS configuration evaluates and builds from the flake";
          }
          ''
            # Interpolating the toplevel into the script retains its store
            # context, so Nix must evaluate and build the entire system
            # configuration before this derivation can run. If evaluation or the
            # build fails, this derivation fails.
            test -e "${toplevel}"
            touch "$out"
          ''
      ) systemToplevels;

      profileEvaluationChecks = {
        profile-evaluations =
          let
            minCfg = profileConfigs.minimal;
            fullCfg = profileConfigs.full;

            minGamingOff =
              !minCfg.programs.steam.enable
              && !minCfg.hardware.graphics.enable32Bit
              && !minCfg.programs.gamemode.enable;
            fullGamingOn =
              fullCfg.programs.steam.enable
              && fullCfg.hardware.graphics.enable32Bit
              && fullCfg.programs.gamemode.enable;

            # Programming languages sentinels & options
            minNixLdOff = !minCfg.programs.nix-ld.enable;
            fullNixLdOn = fullCfg.programs.nix-ld.enable;
            minHasNodejs = hasPackage minCfg "nodejs";
            minHasBun = hasPackage minCfg "bun";
            minHasUv = hasPackage minCfg "uv";
            fullHasNodejs = hasPackage fullCfg "nodejs";
            fullHasBun = hasPackage fullCfg "bun";
            fullHasUv = hasPackage fullCfg "uv";

            # LSP sentinels
            minHasNil = hasPackage minCfg "nil";
            minHasNixd = hasPackage minCfg "nixd";
            minHasRuff = hasPackage minCfg "ruff";
            minHasMarksman = hasPackage minCfg "marksman";
            fullHasNil = hasPackage fullCfg "nil";
            fullHasNixd = hasPackage fullCfg "nixd";
            fullHasRuff = hasPackage fullCfg "ruff";
            fullHasMarksman = hasPackage fullCfg "marksman";

            # Info fetchers sentinels
            minHasFastfetch = hasPackage minCfg "fastfetch";
            minHasBtop = hasPackage minCfg "btop";
            minHasNvtop = hasPackage minCfg "nvtop";
            fullHasFastfetch = hasPackage fullCfg "fastfetch";
            fullHasBtop = hasPackage fullCfg "btop";
            fullHasNvtop = hasPackage fullCfg "nvtop";

            # Services split sentinels - Base Wayland desktop utilities (present in both minimal & full)
            minHasGrim = hasPackage minCfg "grim";
            minHasSlurp = hasPackage minCfg "slurp";
            minHasWlClipboard = hasPackage minCfg "wl-clipboard";
            minHasWlScreenrec = hasPackage minCfg "wl-screenrec";
            minHasCliphist = hasPackage minCfg "cliphist";
            minHasLibnotify = hasPackage minCfg "libnotify";
            minHasXdgUtils = hasPackage minCfg "xdg-utils";

            fullHasGrim = hasPackage fullCfg "grim";
            fullHasSlurp = hasPackage fullCfg "slurp";
            fullHasWlClipboard = hasPackage fullCfg "wl-clipboard";
            fullHasWlScreenrec = hasPackage fullCfg "wl-screenrec";
            fullHasCliphist = hasPackage fullCfg "cliphist";
            fullHasLibnotify = hasPackage fullCfg "libnotify";
            fullHasXdgUtils = hasPackage fullCfg "xdg-utils";

            # Services split sentinels - Media applications (absent in minimal, present in full)
            minHasQutebrowser = hasPackage minCfg "qutebrowser";
            minHasZathura = hasPackage minCfg "zathura";
            minHasMpv = hasPackage minCfg "mpv";
            minHasMpvHandler = hasPackage minCfg "mpv-handler";
            minHasImv = hasPackage minCfg "imv";
            minHasImagemagick = hasPackage minCfg "imagemagick";
            minHasSwappy = hasPackage minCfg "swappy";
            minHasFfmpeg = hasPackage minCfg "ffmpeg";

            fullHasQutebrowser = hasPackage fullCfg "qutebrowser";
            fullHasZathura = hasPackage fullCfg "zathura";
            fullHasMpv = hasPackage fullCfg "mpv";
            fullHasMpvHandler = hasPackage fullCfg "mpv-handler";
            fullHasImv = hasPackage fullCfg "imv";
            fullHasImagemagick = hasPackage fullCfg "imagemagick";
            fullHasSwappy = hasPackage fullCfg "swappy";
            fullHasFfmpeg = hasPackage fullCfg "ffmpeg";

            # Base system sentinels
            minHasSteam = hasPackage minCfg "steam";
            minHasZsh = hasPackage minCfg "zsh";
            minHasVim = hasPackage minCfg "vim";

            fullHasSteam = hasPackage fullCfg "steam";
            fullHasZsh = hasPackage fullCfg "zsh";
            fullHasVim = hasPackage fullCfg "vim";

            # Per-user GUI application sentinels (users.users.<user>.packages)
            minHasVscode = hasPackage minCfg "vscode";
            minHasGoogleChrome = hasPackage minCfg "google-chrome";
            fullHasVscode = hasPackage fullCfg "vscode";
            fullHasGoogleChrome = hasPackage fullCfg "google-chrome";

            # Heavy Home-Manager sentinels (gated to full)
            minHasPlaywright = hasPackage minCfg "playwright-browsers";
            minHasObsidian = hasPackage minCfg "obsidian";
            minHasHerdr = hasPackage minCfg "herdr";
            minHasAntigravity = hasPackage minCfg "google-antigravity2";
            minHasAntigravityIde = hasPackage minCfg "google-antigravity-ide";
            minHasAntigravityCli = hasPackage minCfg "google-antigravity-cli";

            fullHasPlaywright = hasPackage fullCfg "playwright-browsers";
            fullHasObsidian = hasPackage fullCfg "obsidian";
            fullHasHerdr = hasPackage fullCfg "herdr";
            fullHasAntigravity = hasPackage fullCfg "google-antigravity2";
            fullHasAntigravityIde = hasPackage fullCfg "google-antigravity-ide";
            fullHasAntigravityCli = hasPackage fullCfg "google-antigravity-cli";

            # Base Home-Manager sentinels (present in both minimal & full)
            minHasNixfmt = hasPackage minCfg "nixfmt";
            minHasEza = hasPackage minCfg "eza";
            minHasNautilus = hasPackage minCfg "nautilus";
            minHasLocalsend = hasPackage minCfg "localsend";

            fullHasNixfmt = hasPackage fullCfg "nixfmt";
            fullHasEza = hasPackage fullCfg "eza";
            fullHasNautilus = hasPackage fullCfg "nautilus";
            fullHasLocalsend = hasPackage fullCfg "localsend";
          in
          pkgs.runCommand "check-profile-evaluations"
            {
              meta.description = "Automated evaluation checks asserting profile options and package membership across minimal and full profiles";
            }
            ''
              echo "Evaluating profile tiers..."

              # Verify profile options
              test "${minCfg.manoj.profile}" = "minimal" || { echo "FAIL: minimal config profile is not minimal" >&2; exit 1; }
              test "${fullCfg.manoj.profile}" = "full" || { echo "FAIL: full config profile is not full" >&2; exit 1; }

              # Verify Home-Manager profile options
              test "${minCfg.home-manager.users.manoj.manoj.profile}" = "minimal" || { echo "FAIL: minimal HM profile is not minimal" >&2; exit 1; }
              test "${fullCfg.home-manager.users.manoj.manoj.profile}" = "full" || { echo "FAIL: full HM profile is not full" >&2; exit 1; }

              # Verify gaming stack options
              ${if !minGamingOff then "echo 'FAIL: minimal profile gaming stack is active' >&2; exit 1;" else ""}
              ${if !fullGamingOn then "echo 'FAIL: full profile gaming stack is not active' >&2; exit 1;" else ""}

              # Verify programming languages stack & options
              ${if !minNixLdOff then "echo 'FAIL: minimal profile nix-ld is active' >&2; exit 1;" else ""}
              ${if !fullNixLdOn then "echo 'FAIL: full profile nix-ld is not active' >&2; exit 1;" else ""}
              ${
                if minHasNodejs then
                  "echo 'FAIL: sentinel package nodejs is present in minimal profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if minHasBun then
                  "echo 'FAIL: sentinel package bun is present in minimal profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if minHasUv then
                  "echo 'FAIL: sentinel package uv is present in minimal profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if !fullHasNodejs then
                  "echo 'FAIL: sentinel package nodejs is missing in full profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if !fullHasBun then
                  "echo 'FAIL: sentinel package bun is missing in full profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if !fullHasUv then
                  "echo 'FAIL: sentinel package uv is missing in full profile' >&2; exit 1;"
                else
                  ""
              }

              # Verify LSP suite sentinels
              ${
                if minHasNil then
                  "echo 'FAIL: sentinel package nil is present in minimal profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if minHasNixd then
                  "echo 'FAIL: sentinel package nixd is present in minimal profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if minHasRuff then
                  "echo 'FAIL: sentinel package ruff is present in minimal profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if minHasMarksman then
                  "echo 'FAIL: sentinel package marksman is present in minimal profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if !fullHasNil then
                  "echo 'FAIL: sentinel package nil is missing in full profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if !fullHasNixd then
                  "echo 'FAIL: sentinel package nixd is missing in full profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if !fullHasRuff then
                  "echo 'FAIL: sentinel package ruff is missing in full profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if !fullHasMarksman then
                  "echo 'FAIL: sentinel package marksman is missing in full profile' >&2; exit 1;"
                else
                  ""
              }

              # Verify info fetchers sentinels
              ${
                if minHasFastfetch then
                  "echo 'FAIL: sentinel package fastfetch is present in minimal profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if minHasBtop then
                  "echo 'FAIL: sentinel package btop is present in minimal profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if minHasNvtop then
                  "echo 'FAIL: sentinel package nvtop is present in minimal profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if !fullHasFastfetch then
                  "echo 'FAIL: sentinel package fastfetch is missing in full profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if !fullHasBtop then
                  "echo 'FAIL: sentinel package btop is missing in full profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if !fullHasNvtop then
                  "echo 'FAIL: sentinel package nvtop is missing in full profile' >&2; exit 1;"
                else
                  ""
              }

              # Verify services module split: core Wayland desktop utilities in both
              ${
                if !minHasGrim then
                  "echo 'FAIL: core utility grim is missing in minimal profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if !minHasSlurp then
                  "echo 'FAIL: core utility slurp is missing in minimal profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if !minHasWlClipboard then
                  "echo 'FAIL: core utility wl-clipboard is missing in minimal profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if !minHasWlScreenrec then
                  "echo 'FAIL: core utility wl-screenrec is missing in minimal profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if !minHasCliphist then
                  "echo 'FAIL: core utility cliphist is missing in minimal profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if !minHasLibnotify then
                  "echo 'FAIL: core utility libnotify is missing in minimal profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if !minHasXdgUtils then
                  "echo 'FAIL: core utility xdg-utils is missing in minimal profile' >&2; exit 1;"
                else
                  ""
              }

              ${
                if !fullHasGrim then
                  "echo 'FAIL: core utility grim is missing in full profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if !fullHasSlurp then
                  "echo 'FAIL: core utility slurp is missing in full profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if !fullHasWlClipboard then
                  "echo 'FAIL: core utility wl-clipboard is missing in full profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if !fullHasWlScreenrec then
                  "echo 'FAIL: core utility wl-screenrec is missing in full profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if !fullHasCliphist then
                  "echo 'FAIL: core utility cliphist is missing in full profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if !fullHasLibnotify then
                  "echo 'FAIL: core utility libnotify is missing in full profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if !fullHasXdgUtils then
                  "echo 'FAIL: core utility xdg-utils is missing in full profile' >&2; exit 1;"
                else
                  ""
              }

              # Verify services module split: media applications gated to full
              ${
                if minHasQutebrowser then
                  "echo 'FAIL: media package qutebrowser is present in minimal profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if minHasZathura then
                  "echo 'FAIL: media package zathura is present in minimal profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if minHasMpv then
                  "echo 'FAIL: media package mpv is present in minimal profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if minHasMpvHandler then
                  "echo 'FAIL: media package mpv-handler is present in minimal profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if minHasImv then
                  "echo 'FAIL: media package imv is present in minimal profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if minHasImagemagick then
                  "echo 'FAIL: media package imagemagick is present in minimal profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if minHasSwappy then
                  "echo 'FAIL: media package swappy is present in minimal profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if minHasFfmpeg then
                  "echo 'FAIL: media package ffmpeg is present in minimal profile' >&2; exit 1;"
                else
                  ""
              }

              ${
                if !fullHasQutebrowser then
                  "echo 'FAIL: media package qutebrowser is missing in full profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if !fullHasZathura then
                  "echo 'FAIL: media package zathura is missing in full profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if !fullHasMpv then "echo 'FAIL: media package mpv is missing in full profile' >&2; exit 1;" else ""
              }
              ${
                if !fullHasMpvHandler then
                  "echo 'FAIL: media package mpv-handler is missing in full profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if !fullHasImv then "echo 'FAIL: media package imv is missing in full profile' >&2; exit 1;" else ""
              }
              ${
                if !fullHasImagemagick then
                  "echo 'FAIL: media package imagemagick is missing in full profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if !fullHasSwappy then
                  "echo 'FAIL: media package swappy is missing in full profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if !fullHasFfmpeg then
                  "echo 'FAIL: media package ffmpeg is missing in full profile' >&2; exit 1;"
                else
                  ""
              }

              # Verify per-user GUI applications: gated to full
              ${
                if minHasVscode then
                  "echo 'FAIL: user package vscode is present in minimal profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if minHasGoogleChrome then
                  "echo 'FAIL: user package google-chrome is present in minimal profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if !fullHasVscode then
                  "echo 'FAIL: user package vscode is missing in full profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if !fullHasGoogleChrome then
                  "echo 'FAIL: user package google-chrome is missing in full profile' >&2; exit 1;"
                else
                  ""
              }

              # Verify heavy Home-Manager packages: gated to full
              ${
                if minHasPlaywright then
                  "echo 'FAIL: home package playwright-browsers is present in minimal profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if minHasObsidian then
                  "echo 'FAIL: home package obsidian is present in minimal profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if minHasHerdr then
                  "echo 'FAIL: home package herdr is present in minimal profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if minHasAntigravity then
                  "echo 'FAIL: home package google-antigravity2 is present in minimal profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if minHasAntigravityIde then
                  "echo 'FAIL: home package google-antigravity-ide is present in minimal profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if minHasAntigravityCli then
                  "echo 'FAIL: home package google-antigravity-cli is present in minimal profile' >&2; exit 1;"
                else
                  ""
              }

              ${
                if !fullHasPlaywright then
                  "echo 'FAIL: home package playwright-browsers is missing in full profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if !fullHasObsidian then
                  "echo 'FAIL: home package obsidian is missing in full profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if !fullHasHerdr then
                  "echo 'FAIL: home package herdr is missing in full profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if !fullHasAntigravity then
                  "echo 'FAIL: home package google-antigravity2 is missing in full profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if !fullHasAntigravityIde then
                  "echo 'FAIL: home package google-antigravity-ide is missing in full profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if !fullHasAntigravityCli then
                  "echo 'FAIL: home package google-antigravity-cli is missing in full profile' >&2; exit 1;"
                else
                  ""
              }

              # Verify base Home-Manager packages: present in both minimal & full
              ${
                if !minHasNixfmt then
                  "echo 'FAIL: base home package nixfmt is missing in minimal profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if !minHasEza then
                  "echo 'FAIL: base home package eza is missing in minimal profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if !minHasNautilus then
                  "echo 'FAIL: base home package nautilus is missing in minimal profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if !minHasLocalsend then
                  "echo 'FAIL: base home package localsend is missing in minimal profile' >&2; exit 1;"
                else
                  ""
              }

              ${
                if !fullHasNixfmt then
                  "echo 'FAIL: base home package nixfmt is missing in full profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if !fullHasEza then
                  "echo 'FAIL: base home package eza is missing in full profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if !fullHasNautilus then
                  "echo 'FAIL: base home package nautilus is missing in full profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if !fullHasLocalsend then
                  "echo 'FAIL: base home package localsend is missing in full profile' >&2; exit 1;"
                else
                  ""
              }

              # Base system sentinels
              ${
                if minHasSteam then
                  "echo 'FAIL: sentinel package steam is present in minimal profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if !minHasZsh then
                  "echo 'FAIL: base utility zsh is missing in minimal profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if !minHasVim then
                  "echo 'FAIL: base utility vim is missing in minimal profile' >&2; exit 1;"
                else
                  ""
              }

              ${
                if !fullHasSteam then
                  "echo 'FAIL: sentinel package steam is missing in full profile' >&2; exit 1;"
                else
                  ""
              }
              ${
                if !fullHasZsh then "echo 'FAIL: base utility zsh is missing in full profile' >&2; exit 1;" else ""
              }
              ${
                if !fullHasVim then "echo 'FAIL: base utility vim is missing in full profile' >&2; exit 1;" else ""
              }

              echo "All profile evaluation checks passed."
              touch "$out"
            '';
      };

    in
    {
      inherit nixosConfigurations;

      packages.${system} = systemToplevels;

      # WF-9 & Profile Evaluation test harness
      checks.${system} = hostBuildChecks // profileEvaluationChecks;
    };
}
