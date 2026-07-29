{ pkgs, ... }: {
  home.packages = with pkgs; [
    nixfmt
    wofi
    eza # modern ls replacement; aliased via the oh-my-zsh `eza` plugin (see zsh.nix)
    swaynotificationcenter # ships the `swaync` daemon + `swaync-client`; started from hyprland.start
  ];
}