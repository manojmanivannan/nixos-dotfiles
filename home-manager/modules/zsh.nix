{ config, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;

    shellAliases = {
      btw = "echo i use nixos-btw";
      nrs = "sudo nixos-rebuild switch --flake ~/nixos-dotfiles#nixos";
      # NOTE: `gcommit` is intentionally not an alias here — the JIRA-aware
      # `gcommit` function in zshrc_addon.zsh handles it (an alias would shadow
      # the function, since shellAliases are emitted after initContent).
    };

    # Custom prompt — runs AFTER oh-my-zsh loads the amuse theme (initContent
    # is ordered after the oh-my-zsh source in .zshrc), so it overrides the
    # theme's PROMPT/RPROMPT. git_prompt_info comes from the `git` oh-my-zsh
    # plugin; virtualenv_prompt_info from the `virtualenv` plugin. The
    # ZSH_THEME_*_PROMPT vars mirror the amuse theme so the venv segment
    # matches the original Arch setup.
    initContent = ''
      VIRTUAL_ENV_DISABLE_PROMPT=0
      ZSH_THEME_VIRTUAL_ENV_PROMPT_PREFIX=" %F{cyan}🐍 ("
      ZSH_THEME_VIRTUAL_ENV_PROMPT_SUFFIX=")%f"
      ZSH_THEME_VIRTUALENV_PREFIX=$ZSH_THEME_VIRTUAL_ENV_PROMPT_PREFIX
      ZSH_THEME_VIRTUALENV_SUFFIX=$ZSH_THEME_VIRTUAL_ENV_PROMPT_SUFFIX

      # Left prompt:  <path> <git> <venv> <exit-code on failure> ↪
      PROMPT='%F{blue}%~%f $(git_prompt_info)$(virtualenv_prompt_info)%F{red}%(?.. [%?])%f %F{yellow}$%f '
      # Right prompt: [HH:MM:SS]
      RPROMPT='⌚%F{cyan}[%D{%H:%M:%S}]%f'

      source "${config.home.homeDirectory}/nixos-dotfiles/home/.config/zsh/zshrc_addon.zsh"
    '';

    # oh-my-zsh manages the prompt/theme (matches the old Arch setup: amuse).
    oh-my-zsh = {
      enable = true;
      theme = "amuse";
      plugins = [
        # built-in
        "git"
        "colored-man-pages"
        "colorize"
        "command-not-found"
        "web-search"
        "kubectl"
        "z"
        "virtualenv"
        "gh"
        "zsh-interactive-cd"
        # external, from ZSH_CUSTOM (built in `let`)
      ];
    };

    # zsh-autosuggestions and zsh-syntax-highlighting have no `.plugin.zsh`
    # in their nixpkgs packages, so they can't live in ZSH_CUSTOM. Home Manager
    # sources them directly (and in the correct order) via these options.
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
  };
}