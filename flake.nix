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

    makeSystem = { name, hostname, ipv4Address, defaultGateway, stateVersion }: nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs stateVersion hostname user ipv4Address defaultGateway;
      };
      modules = [
        ./hosts/${name}/configuration.nix
      ];
    };

    nixosConfigurations = nixpkgs.lib.foldl' (configs: host:
      configs // {
        "${host.name}" = makeSystem {
          inherit (host) name hostname ipv4Address defaultGateway stateVersion;
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

  in {
    inherit nixosConfigurations;

    packages.${system} = systemToplevels;

    # WF-9 — the repo's first automated test. The single build seam: the
    # configured NixOS system evaluates and builds from the flake. One check
    # per host; it forces the toplevel to build — exercising the whole
    # integration (flake inputs, Home-Manager modules, system config) — and
    # asserts only external behaviour ("the configured system builds"), with
    # no assertions about Nix function internals or file layout. Run it with
    # `nix flake check`; `nix build .#nixos` builds the same toplevel directly.
    checks.${system} = nixpkgs.lib.mapAttrs
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
  };
}
