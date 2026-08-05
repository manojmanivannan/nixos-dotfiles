{ config, lib, ... }:

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
    zsh = "zsh"; # ~/.config/zsh holds the sourced zshrc_addon.zsh loader
                 # and its zshrc.d/ snippets (functions, git, aliases, exports).
                 # Sourced from programs.zsh.initContent in home-manager/modules/zsh.nix.
  };

  # Single-file config symlinks — manage just the file, not the whole
  # directory, so app-generated siblings (e.g. gtk-4.0/settings.ini,
  # gtk-4.0/assets/) are left untouched. The warm-metal GTK overrides live in
  # config/.config/gtk-{3,4}.0/gtk.css and theme GTK3 via adw-gtk3-dark
  # (see nixos/modules/desktop/theme.nix and home-manager/modules/gtk.nix).
  #
  # rsync is deliberately here rather than in `configs`: the dir holds
  # `dxp_pass`, a secret that must stay a real local file (see
  # seedRsyncPassword below), so only the non-secret files are symlinked.
  # The nas-backup systemd units are NOT symlinked — they are defined in Nix
  # (home-manager/modules/nas-backup.nix) so HM can enable the timer
  # declaratively. The backup script itself is the symlinked file below.
  files = {
    "gtk-4.0/gtk.css" = "gtk-4.0/gtk.css";
    "gtk-3.0/gtk.css" = "gtk-3.0/gtk.css";
    "rsync/archive_to_nas.sh" = "rsync/archive_to_nas.sh";
    "rsync/ignore" = "rsync/ignore";
    # Starship prompt config (nerd-font glyphs). starship itself ships as a
    # system package (nixos/modules/development/terminal.nix); we call
    # `starship init zsh` from programs.zsh.initContent instead of using HM's
    # programs.starship, so HM never manages this file — the symlink wins.
    "starship.toml" = "starship.toml";
  };
in

{
  # Wallpaper is set by swaybg, launched from Hyprland on startup
  # (see config/.config/hypr/hyprland.lua). swaybg ships in nixos/modules/desktop/hyprland.nix,
  # so no Home Manager service is needed here.
  xdg.configFile =
    builtins.mapAttrs (name: subpath: {
      source = create_symlink "${dotfiles}/${subpath}";
      recursive = true;
    }) configs
    // builtins.mapAttrs (name: subpath: {
      source = create_symlink "${dotfiles}/${subpath}";
    }) files;

  # Seed ~/.config/rsync/dxp_pass on first run only. The password file is a
  # secret, so it is NOT symlinked from the repo (that would make edits land in
  # the working tree and risk committing the password). We just touch an empty
  # file into place; the backup script's own `-s` check then prompts the user
  # to fill it in. Existing files are never overwritten. Mirrors the seed
  # pattern in home-manager/modules/claude.nix.
  home.activation.seedRsyncPassword = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -e "$HOME/.config/rsync/dxp_pass" ]; then
      $DRY_RUN_CMD mkdir -p "$HOME/.config/rsync"
      $DRY_RUN_CMD touch "$HOME/.config/rsync/dxp_pass"
      $DRY_RUN_CMD chmod 600 "$HOME/.config/rsync/dxp_pass"
    fi
  '';
}
