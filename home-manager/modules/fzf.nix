{ ... }: {
  # fzf key bindings + fuzzy completion — replaces the old `source <(fzf --zsh)`.
  # Required by the fzf-zsh-plugin oh-my-zsh plugin.
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
}