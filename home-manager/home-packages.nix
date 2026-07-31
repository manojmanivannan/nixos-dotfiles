{ pkgs, ... }: {
  home.packages = with pkgs; [
    nixfmt
    wofi
    eza # modern ls replacement; aliased via the oh-my-zsh `eza` plugin (see zsh.nix)
    swaynotificationcenter # ships the `swaync` daemon + `swaync-client`; started from hyprland.start
    nautilus # GNOME file manager; launched on Super+E via the `fileManager` bind in hypr/bindings.lua
    localsend # AirDrop-style cross-platform file transfer; ports opened in networking/firewall.nix
    obsidian # local-folder Markdown knowledge base
  ];
}