{ ... }:

{
  # Declarative libadwaita/GTK3 dark-mode settings for the warm-metal theme.
  # `color-scheme=prefer-dark` switches libadwaita apps (Nautilus, etc.) to the
  # dark variant that config/.config/gtk-4.0/gtk.css recolors warm-metal.
  # `gtk-theme` selects adw-gtk3-dark for GTK3 apps (also forced via the
  # GTK_THEME env var in nixos/modules/desktop/theme.nix), which
  # config/.config/gtk-3.0/gtk.css recolors to match.
  # Requires programs.dconf.enable = true (see nixos/modules/services/services.nix).
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "adw-gtk3-dark";
    };
  };
}