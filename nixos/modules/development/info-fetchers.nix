{ config, lib, pkgs, ... }:

lib.mkIf (config.manoj.profile == "full") {
  environment.systemPackages = with pkgs; [
    fastfetch
    btop
    nvtopPackages.nvidia
    nvtopPackages.intel
  ];
}
