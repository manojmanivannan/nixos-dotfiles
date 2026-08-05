{ ... }: {
  # lazygit — TUI git client. Covers most of what the `g*` helper functions in
  # zshrc.d/20-git.zsh do, but interactively (staging hunks, rebasing, log
  # navigation). git diffs render via delta (programs.git.delta in git.nix).
  programs.lazygit.enable = true;
}