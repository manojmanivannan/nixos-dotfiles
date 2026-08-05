{ ... }: {
  # zoxide — smarter `cd` that frecency-ranks every directory you visit.
  # Provides `z <query>` (jump) and `zi` (interactive fzf picker). Replaces the
  # oh-my-zsh `z` plugin (removed from zsh.nix's oh-my-zsh.plugins) — that one
  # used a separate ~/.z store and would have collided with zoxide's `z`.
  # The hand-rolled `cd()` venv override in zshrc.d/10-functions.zsh is left
  # intact: zoxide's `z` calls `cd`, so jumping into a ./.venv project still
  # auto-activates the venv.
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
}