{
  inputs,
  user,
  stateVersion,
  weatherLocation,
  ...
}:
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";

  # Pass the flake `inputs` into Home-Manager modules so a per-user HM
  # module can reference a flake input directly — e.g. the caelestia HM
  # module's `package = inputs.caelestia-shell.packages.${system}.with-cli`
  # (WF-10). A clean prefactor: it keeps `main` green on its own and
  # unblocks the caelestia HM module without coupling the module to a
  # `specialArgs`-only `inputs`.
  home-manager.extraSpecialArgs = {
    inherit
      inputs
      user
      stateVersion
      weatherLocation
      ;
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
