{ ... }:

{
  imports = [
    ./nix-settings.nix
    ./nixpkgs.nix
    ./gc.nix
    ./environment-variables.nix
    ./home-manager.nix
  ];
}