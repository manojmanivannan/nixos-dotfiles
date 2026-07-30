{ config, ... }:

let
  dotfiles = "${config.home.homeDirectory}/nixos-dotfiles/config/.config";
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

  # Single-file config symlinks — manage just the file, not the whole
  # directory, so app-generated siblings (e.g. gtk-4.0/settings.ini,
  # gtk-4.0/assets/) are left untouched. The warm-metal GTK overrides live in
  # config/.config/gtk-{3,4}.0/gtk.css and theme GTK3 via adw-gtk3-dark
  # (see nixos/modules/desktop/theme.nix and home-manager/modules/gtk.nix).
  files = {
    "gtk-4.0/gtk.css" = "gtk-4.0/gtk.css";
    "gtk-3.0/gtk.css" = "gtk-3.0/gtk.css";
  };
in

{
  # Wallpaper is set by swaybg, launched from Hyprland on startup
  # (see config/.config/hypr/hyprland.lua). swaybg ships in nixos/modules/desktop/hyprland.nix,
  # so no Home Manager service is needed here.
  xdg.configFile = builtins.mapAttrs (name: subpath: {
    source = create_symlink "${dotfiles}/${subpath}";
    recursive = true;
  }) configs // builtins.mapAttrs (name: subpath: {
    source = create_symlink "${dotfiles}/${subpath}";
  }) files;
}