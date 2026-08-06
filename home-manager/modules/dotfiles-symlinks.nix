{ config, lib, ... }:

let
  dotfiles = "${config.home.homeDirectory}/nixos-dotfiles/config/.config";
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;

  # Standard .config/directory (recursive symlinks). Nested paths are
  # fine — the key is just the xdg.configFile target name.
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
    # Caelestia `scheme/` tree (WF-10) — recursive, like the entries above.
    # Scoped to just the scheme dir (not a whole `caelestia` entry) so it
    # never collides with the HM-generated ~/.config/caelestia/shell.json
    # (the `programs.caelestia` module writes that when `settings` is
    # non-empty — see home-manager/modules/caelestia.nix). WF-12 authors
    # the vendored warm-metal scheme.json here.
    "caelestia/scheme" = "caelestia/scheme";
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
    # Caelestia runtime config (WF-10). The two flat files the shell
    # reads but the HM module does NOT manage. Kept as single-file
    # entries (not a recursive entry) so they do NOT collide with the
    # HM-generated ~/.config/caelestia/shell.json — the `programs.caelestia`
    # module writes shell.json when `settings` is non-empty (see
    # home-manager/modules/caelestia.nix). The `scheme/` tree is a
    # directory, so it lives in the recursive `configs` map above. WF-12
    # fills in the real warm-metal payload; these are placeholders for now.
    "caelestia/shell-tokens.json" = "caelestia/shell-tokens.json";
    "caelestia/hypr-user.conf" = "caelestia/hypr-user.conf";
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
