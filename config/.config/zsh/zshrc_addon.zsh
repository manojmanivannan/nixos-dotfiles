# Master loader for the XDG-organized zsh snippets.
#
# Sourced from home-manager programs.zsh.initContent
# (home-manager/modules/zsh.nix), AFTER oh-my-zsh loads. ~/.config/zsh is
# symlinked from the repo by home-manager/modules/dotfiles-symlinks.nix.
#
# Originally a single ~500-line file (ported from ~/MyArchDotFiles/.zshrc_addon),
# now split into zshrc.d/ snippets for maintainability. Each snippet is sourced
# in filename (glob) order, which preserves the original load sequence:
#
#   10-functions.zsh  — bashcompinit + helper functions + cd/cp overrides
#   20-git.zsh        — git helper functions (rely on oh-my-zsh `git` aliases)
#   30-aliases.zsh    — aliases
#   40-exports.zsh    — exports, PATH, compinit/zstyle, nvm, bun, etc.
#
# The `(N)` glob qualifier enables nullglob for this pattern, so a missing or
# empty directory is a no-op rather than an error.

for __addon_snippet in "$HOME/.config/zsh/zshrc.d"/*.zsh(N); do
  source "$__addon_snippet"
done
unset __addon_snippet