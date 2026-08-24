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

  outputs = { nixpkgs, home-manager, ... }@inputs:
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
      { name = "nixos"; hostname = "linux-machine"; ipv4Address = "192.168.1.192"; defaultGateway = "192.168.1.1"; inherit stateVersion; }
    ];

    makeSystem = { name, hostname, ipv4Address, defaultGateway, stateVersion, profile ? "full" }: nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs stateVersion hostname user ipv4Address defaultGateway profile;
      };
      modules = [
        ./hosts/${name}/configuration.nix
      ];
    };

    nixosConfigurations = nixpkgs.lib.foldl' (configs: host:
      configs // {
        "${host.name}" = makeSystem {
          inherit (host) name hostname ipv4Address defaultGateway stateVersion;
          profile = host.profile or "full";
        };
      }) {} hosts;

    # Each host's system toplevel as a buildable derivation. Exposed as the
    # `packages.${system}` output so the spec's seam — `nix build .#nixos` —
    # resolves: a `nixosConfigurations.<name>` entry is an evaluated module
    # set, not a derivation, so `nix build` needs a derivation attribute to
    # build. This is the same toplevel that `nixos-rebuild build` produces.
    systemToplevels = nixpkgs.lib.genAttrs
      (map (host: host.name) hosts)
      (name: nixosConfigurations.${name}.config.system.build.toplevel);

    # Profile evaluation test configurations: evaluate both 'minimal' and 'full'
    # profiles to assert package membership and module gating.
    evalProfileConfig = prof: (makeSystem {
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
    collectPackages = cfg:
      let
        sysPkgs = cfg.environment.systemPackages;
        userPkgs = pkgs.lib.concatLists (pkgs.lib.mapAttrsToList (_: u: u.packages or []) cfg.users.users);
        hmPkgs = pkgs.lib.concatLists (pkgs.lib.mapAttrsToList (_: u: u.home.packages or []) (cfg.home-manager.users or {}));
      in
        sysPkgs ++ userPkgs ++ hmPkgs;

    hasPackage = cfg: name:
      let
        allPkgs = collectPackages cfg;
        pkgName = p: p.pname or (builtins.parseDrvName (p.name or "")).name;
      in
        pkgs.lib.any (p: pkgName p == name) allPkgs;

    hostBuildChecks = nixpkgs.lib.mapAttrs
      (name: toplevel: pkgs.runCommand "check-${name}-builds" {
        meta.description = "WF-9: the ${name} NixOS configuration evaluates and builds from the flake";
      } ''
        # Interpolating the toplevel into the script retains its store
        # context, so Nix must evaluate and build the entire system
        # configuration before this derivation can run. If evaluation or the
        # build fails, this derivation fails.
        test -e "${toplevel}"
        touch "$out"
      '')
      systemToplevels;

    profileEvaluationChecks = {
      profile-evaluations =
        let
          minCfg = profileConfigs.minimal;
          fullCfg = profileConfigs.full;

          minHasSteam = hasPackage minCfg "steam";
          minHasZsh = hasPackage minCfg "zsh";
          minHasVim = hasPackage minCfg "vim";

          fullHasSteam = hasPackage fullCfg "steam";
          fullHasZsh = hasPackage fullCfg "zsh";
          fullHasVim = hasPackage fullCfg "vim";

          minGamingOff = !minCfg.programs.steam.enable && !minCfg.hardware.graphics.enable32Bit && !minCfg.programs.gamemode.enable;
          fullGamingOn = fullCfg.programs.steam.enable && fullCfg.hardware.graphics.enable32Bit && fullCfg.programs.gamemode.enable;
        in
          pkgs.runCommand "check-profile-evaluations" {
            meta.description = "Automated evaluation checks asserting profile options and package membership across minimal and full profiles";
          } ''
            echo "Evaluating profile tiers..."

            # Verify profile options
            test "${minCfg.manoj.profile}" = "minimal" || { echo "FAIL: minimal config profile is not minimal" >&2; exit 1; }
            test "${fullCfg.manoj.profile}" = "full" || { echo "FAIL: full config profile is not full" >&2; exit 1; }

            # Verify gaming stack options
            ${if !minGamingOff then "echo 'FAIL: minimal profile gaming stack is active' >&2; exit 1;" else ""}
            ${if !fullGamingOn then "echo 'FAIL: full profile gaming stack is not active' >&2; exit 1;" else ""}

            # Verify sentinel packages
            ${if minHasSteam then "echo 'FAIL: sentinel package steam is present in minimal profile' >&2; exit 1;" else ""}
            ${if !minHasZsh then "echo 'FAIL: base utility zsh is missing in minimal profile' >&2; exit 1;" else ""}
            ${if !minHasVim then "echo 'FAIL: base utility vim is missing in minimal profile' >&2; exit 1;" else ""}

            ${if !fullHasSteam then "echo 'FAIL: sentinel package steam is missing in full profile' >&2; exit 1;" else ""}
            ${if !fullHasZsh then "echo 'FAIL: base utility zsh is missing in full profile' >&2; exit 1;" else ""}
            ${if !fullHasVim then "echo 'FAIL: base utility vim is missing in full profile' >&2; exit 1;" else ""}

            echo "All profile evaluation checks passed."
            touch "$out"
          '';
    };

  in {
    inherit nixosConfigurations;

    packages.${system} = systemToplevels;

    # WF-9 & Profile Evaluation test harness
    checks.${system} = hostBuildChecks // profileEvaluationChecks;
  };
}
