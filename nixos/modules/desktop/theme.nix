{ pkgs, ... }:

{
  # Enable Theme
  environment.variables.GTK_THEME = "catppuccin-macchiato-teal-standard";
  environment.variables.XCURSOR_THEME = "Catppuccin-Macchiato-Teal";
  environment.variables.XCURSOR_SIZE = "24";
  environment.variables.HYPRCURSOR_THEME = "Catppuccin-Macchiato-Teal";
  environment.variables.HYPRCURSOR_SIZE = "24";
  qt.enable = true;
  qt.platformTheme = "gtk2";
  qt.style = "gtk2";
  console = {
    earlySetup = true;
    # Warm-metal palette — mirrors the ghostty 16-color palette
    # (config/.config/ghostty/config) so the TTY matches the terminal.
    # GTK/cursor themes below stay Catppuccin-teal until a warm GTK theme is
    # adopted; the terminal/desktop chrome are themed independently.
    colors = [
      "5c4d3d"
      "e5805f"
      "b3bf80"
      "e6c25a"
      "94a6ba"
      "d99a9a"
      "84baa7"
      "f0e6d2"
      "6f5d49"
      "e8906a"
      "c2cc94"
      "eed27a"
      "a4b4c8"
      "e6aaaa"
      "97c8b6"
      "f6eed8"
    ];
  };

  # Override packages
  nixpkgs.config.packageOverrides = pkgs: {
    colloid-icon-theme = pkgs.colloid-icon-theme.override { colorVariants = ["teal"]; };
    catppuccin-gtk = pkgs.catppuccin-gtk.override {
      accents = [ "teal" ]; # You can specify multiple accents here to output multiple themes 
      size = "standard";
      variant = "macchiato";
    };
    discord = pkgs.discord.override {
      withOpenASAR = true;
      withTTS = true;
    };
  };

  environment.systemPackages = with pkgs; [
    colloid-icon-theme
    catppuccin-gtk
    catppuccin-kvantum
    catppuccin-cursors.macchiatoTeal

    # gnome.gnome-tweaks
    # gnome.gnome-shell
    # gnome.gnome-shell-extensions
    # xsettingsd
    # themechanger
  ];
}
