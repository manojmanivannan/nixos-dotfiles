{ pkgs, ... }:

{
  # Enable fingerprint scanner
  services.fprintd = {
    enable = false;
    tod.enable = true;
    tod.driver = pkgs.libfprint-2-tod1-goodix-550a;
  };
}
