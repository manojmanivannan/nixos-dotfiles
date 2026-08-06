{
  description = "Manoj's NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    systems.url = "github:nix-systems/x86_64-linux";
    hyprland.url = "github:hyprwm/Hyprland";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
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
