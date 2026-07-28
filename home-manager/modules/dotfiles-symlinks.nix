{ config, ... }:

let
  dotfiles = "${config.home.homeDirectory}/nixos-dotfiles/home/.config";
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;

  # Standard .config/directory
  configs = {
    rofi = "rofi";
    hypr = "hypr";
    waybar = "waybar";
    wlogout = "wlogout";
    swaync = "swaync";
    wofi = "wofi";
    ghostty = "ghostty";
  };
in

{
  # Wallpaper is set by swaybg, launched from Hyprland on startup
  # (see config/hypr/hyprland.lua). swaybg ships in nixos/modules/hyprland.nix,
  # so no Home Manager service is needed here.
  xdg.configFile = builtins.mapAttrs (name: subpath: {
    source = create_symlink "${dotfiles}/${subpath}";
    recursive = true;
  }) configs;
}