{ config, ... }:

let
  dotfiles = "${config.home.homeDirectory}/nixos-dotfiles/home/.config";
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;

  # Standard .config/directory
  configs = {
    hypr = "hypr";
    waybar = "waybar";
    wlogout = "wlogout";
    swaync = "swaync";
    wofi = "wofi";
    ghostty = "ghostty";
    eza = "eza"; # auto-loads theme.yml for colors/icons
  };
in

{
  # Wallpaper is set by swaybg, launched from Hyprland on startup
  # (see config/hypr/hyprland.lua). swaybg ships in nixos/modules/desktop/hyprland.nix,
  # so no Home Manager service is needed here.
  xdg.configFile = builtins.mapAttrs (name: subpath: {
    source = create_symlink "${dotfiles}/${subpath}";
    recursive = true;
  }) configs;
}