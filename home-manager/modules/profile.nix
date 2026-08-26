{
  lib,
  profile ? "full",
  ...
}:

{
  options.manoj.profile = lib.mkOption {
    type = lib.types.enum [
      "minimal"
      "full"
    ];
    default = "full";
    description = "Home-Manager configuration profile tier ('minimal' or 'full').";
  };

  config.manoj.profile = lib.mkDefault profile;
}
