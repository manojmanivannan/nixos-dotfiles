{
  config,
  inputs,
  user,
  stateVersion,
  ...
}:
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";

  # Pass the flake `inputs` and configuration profile into Home-Manager modules
  # so a per-user HM module can reference flake inputs directly or gate
  # package installation on the active profile tier.
  home-manager.extraSpecialArgs = {
    inherit inputs user stateVersion;
    profile = config.manoj.profile;
  };

  # Register flake-provided HM modules so they are available to every
  # user's HM config. `programs.caelestia` defaults to disabled, so this
  # is inert until a per-user module enables it (WF-10,
  # home-manager/modules/caelestia.nix). The caelestia module is exported
  # with its flake `self` already applied (`import ./nix/hm-module.nix
  # self`), so it is a ready-to-use HM module — no `self` needed here.
  home-manager.sharedModules = [
    inputs.caelestia-shell.homeManagerModules.default
    # `homeModules.default` is the canonical path; `homeManagerModules.default`
    # is a deprecated alias that prints a build-time warning. The module
    # defaults to disabled, so this is inert until a per-user module enables
    # it (home-manager/modules/try.nix).
    inputs.try.homeModules.default
  ];

  home-manager.users.${user} = import ../../../home-manager/home.nix;
}
