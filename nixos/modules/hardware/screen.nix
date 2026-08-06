{ pkgs, ... }:

{
  programs.gpu-screen-recorder.enable = true;

  environment.systemPackages = with pkgs; [
    brightnessctl
    gpu-screen-recorder-gtk
  ];
}
