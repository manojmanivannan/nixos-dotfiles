{ pkgs, ... }:

{
  # Enable Theme
  # GTK3 theme — adw-gtk3-dark (a GTK3 port of libadwaita), recolored warm-metal
  # by config/.config/gtk-3.0/gtk.css. libadwaita (GTK4) apps like Nautilus are
  # recolored by config/.config/gtk-4.0/gtk.css instead; they ignore GTK_THEME.
  # Dark mode for libadwaita is set via dconf in home-manager/modules/gtk.nix.
  environment.variables.GTK_THEME = "adw-gtk3-dark";
  environment.variables.XCURSOR_THEME = "Catppuccin-Macchiato-Teal";
  environment.variables.XCURSOR_SIZE = "24";
  environment.variables.HYPRCURSOR_THEME = "Catppuccin-Macchiato-Teal";
  environment.variables.HYPRCURSOR_SIZE = "24";
  qt.enable = true;
  qt.platformTheme = "gtk2";
  qt.style = "gtk2";
  console = {
    earlySetup = true;
    # Warm-metal palette for the linux console. Color 0 is the TTY background,
    # set to the warm-metal base (slightly darker, matching ghostty's
    # `background` and the Caelestia shell's M3 `base` role); the rest are
    # warm-metal accents that mirror the ghostty 16-color palette
    # (config/.config/ghostty/config).
    # Cursors/icons below stay Catppuccin-teal until warm variants are adopted.
    colors = [
      "322a21"
      "e5805f"
      "b3bf80"
      "e6c25a"
      "94a6ba"
      "d99a9a"
      "84baa7"
      "f0e6d2"
      "4a3e31"
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
    discord = pkgs.discord.override {
      withOpenASAR = true;
      withTTS = true;
    };
  };

  environment.systemPackages = with pkgs; [
    colloid-icon-theme
    adw-gtk3 # GTK3 port of libadwaita; warm-tinted via ~/.config/gtk-3.0/gtk.css
    catppuccin-cursors.macchiatoTeal

    # gnome.gnome-tweaks
    # gnome.gnome-shell
    # gnome.gnome-shell-extensions
    # xsettingsd
    # themechanger
  ];
}
