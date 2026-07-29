{
  description = "Manoj's NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    systems.url = "github:nix-systems/x86_64-linux";
    rust-overlay.url = "github:oxalica/rust-overlay";
    hyprland.url = "github:hyprwm/Hyprland";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, home-manager, ... }@inputs:
  let
    system = "x86_64-linux";
    stateVersion = "26.05";
    user = "manoj";
    # `name` is the stable identity of the host config: it keys the flake
    # output (nixosConfigurations.${name}, i.e. `.#nixos`) and the
    # hosts/${name}/ folder. `hostname` is the machine's network hostname
    # (networking.hostName) — a cloner only needs to change this one field.
    hosts = [
      { name = "nixos"; hostname = "nixos"; inherit stateVersion; }
    ];

    makeSystem = { name, hostname, stateVersion }: nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs stateVersion hostname user;
      };
      modules = [
        ./hosts/${name}/configuration.nix
      ];
    };

  in {
    nixosConfigurations = nixpkgs.lib.foldl' (configs: host:
      configs // {
        "${host.name}" = makeSystem {
          inherit (host) name hostname stateVersion;
        };
      }) {} hosts;
  };
}