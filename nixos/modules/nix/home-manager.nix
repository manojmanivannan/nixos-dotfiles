{ inputs, user, stateVersion, ... }: {
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";
  home-manager.extraSpecialArgs = { inherit user stateVersion; };

  home-manager.users.${user} = import ../../../home-manager/home.nix;
}