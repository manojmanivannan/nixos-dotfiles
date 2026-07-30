{ config, ... }:

let
  scripts = "${config.home.homeDirectory}/nixos-dotfiles/config/.scripts";
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;
in

{
  # Symlink the whole scripts directory into ~/.scripts. Out-of-store, so
  # adding/editing a script in the repo working tree is immediately live
  # without a rebuild — same pattern as dotfiles-symlinks.nix. The directory
  # itself becomes the symlink, so new scripts dropped into config/.scripts
  # appear in ~/.scripts automatically.
  home.file.".scripts" = {
    source = create_symlink scripts;
    recursive = true;
  };

  # Put every script in ~/.scripts on PATH for interactive shells.
  # ~/.local/bin is already on PATH via the Nix profile; this adds the
  # symlinked scripts dir alongside it.
  home.sessionPath = [ "${config.home.homeDirectory}/.scripts" ];
}