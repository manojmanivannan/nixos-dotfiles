{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    fastfetch
    btop
    nvtopPackages.nvidia
    nvtopPackages.intel
  ];
}
