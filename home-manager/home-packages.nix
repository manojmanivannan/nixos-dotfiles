{ pkgs, ... }: {
  home.packages = with pkgs; [
    nixfmt
    eza # modern ls replacement; aliased via the oh-my-zsh `eza` plugin (see zsh.nix)
    nautilus # GNOME file manager; launched on Super+E via the `fileManager` bind in hypr/bindings.lua
    localsend # AirDrop-style cross-platform file transfer; ports opened in networking/firewall.nix
    obsidian # local-folder Markdown knowledge base
  ];
}