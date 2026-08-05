{ ... }: {
  # yazi — Rust terminal file manager. enableZshIntegration provides a `yy`
  # function that opens yazi and cds into the directory yazi was viewing on
  # quit. Integrates with zoxide ( frecency ), fzf, and eza automatically —
  # they're all on $PATH, so no extra wiring needed.
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
  };
}