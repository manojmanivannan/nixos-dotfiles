# Aliases.
# Split out of the original zshrc_addon.zsh.
# Note: the `gcommit` function in 20-git.zsh is intentionally NOT aliased here —
# an alias would shadow the function. `btw`, `nrs`, `claude` are defined as
# shellAliases via Home Manager (home-manager/modules/zsh.nix) and emitted after
# initContent, so they are omitted here too.
# Sourced in load-order by ~/.config/zsh/zshrc_addon.zsh.

alias gitzip="git archive HEAD -o ${PWD##*/}.zip"
alias sz='source ~/.zshrc'
alias grecent=gcorecent
alias gclean='git clean -fd && git checkout -- .'
alias glast-tag='git describe --tags --abbrev=0'
alias gtree='git log --graph --online --decorate --all'
alias gst='git status'
alias matrix='uvx git+https://github.com/will8211/unimatrix.git -s 96'