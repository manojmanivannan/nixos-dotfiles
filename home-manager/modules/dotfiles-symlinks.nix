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
  };
in

{
  # Wallpaper is set by hyprpaper, launched from Hyprland on startup
  # (see config/hypr/hyprland.lua: "waybar & hyprpaper"). hyprpaper reads
  # config/hypr/hyprpaper.conf (shipped in this symlinked dir) and is
  # installed via nixos/modules/hyprland.nix, so no Home Manager service is
  # needed here.
  xdg.configFile = builtins.mapAttrs (name: subpath: {
    source = create_symlink "${dotfiles}/${subpath}";
    recursive = true;
  }) configs;
}