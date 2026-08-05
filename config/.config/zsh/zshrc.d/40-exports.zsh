# Exports, PATH, completion setup, and external tool init.
# Split out of the original zshrc_addon.zsh.
# Runs last (after functions/aliases) so compinit/fpath see everything defined.
# Sourced in load-order by ~/.config/zsh/zshrc_addon.zsh.

# ---------------------------------------------------------------------------
# Exports / environment
# ---------------------------------------------------------------------------
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1
export PATH=${PATH}:~/.local/bin
[ -d ~/.scripts ] && export PATH=$PATH:~/.scripts

autoload -Uz compinit
zstyle ':completion:*' menu select
[[ -d ~/.zfunc ]] && fpath+=(~/.zfunc)

export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

[ -s "$HOME/.api_key/keys.sh" ] && source "$HOME/.api_key/keys.sh"

[ -s "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
[ -d "$BUN_INSTALL/bin" ] && export PATH="$BUN_INSTALL/bin:$PATH"

export LIBVIRT_DEFAULT_URI=qemu:///system