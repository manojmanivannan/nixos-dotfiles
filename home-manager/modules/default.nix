{
  imports = [
    ./caelestia.nix
    ./claude.nix
    ./dotfiles-symlinks.nix
    ./nas-backup.nix
    ./fzf.nix
    ./git.nix
    ./gtk.nix
    ./py-file-opener.nix
    ./ssh.nix
    ./scripts.nix
    ./vim.nix
    ./zsh.nix
    # CLI/shell tools (one module per tool, mirroring fzf.nix)
    ./zoxide.nix
    ./bat.nix
    ./lazygit.nix
    ./yazi.nix
    ./try.nix
    ./profile.nix
  ];
}
