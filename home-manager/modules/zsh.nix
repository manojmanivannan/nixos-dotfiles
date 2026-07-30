{ config, lib, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;

    # initContent holds two ordered pieces, merged with lib.mkMerge:
    #
    #  1. The eza zstyles, wrapped in lib.mkBefore so they land at the top of
    #     .zshrc, BEFORE `source $ZSH/oh-my-zsh.sh`. The oh-my-zsh `eza` plugin
    #     reads these zstyles at load time (in _configure_eza) to decide which
    #     flags to bake into its ls/ll/la/lT aliases, so they must be set before
    #     the plugin is sourced — default ordering runs after oh-my-zsh, which
    #     is too late: the aliases are already built. `icons` enables
    #     --icons=auto so the theme.yml glyphs render; `dirs-first` sorts
    #     directories ahead of files.
    #
    #  2. The custom prompt, at default ordering so it runs AFTER oh-my-zsh
    #     loads the amuse theme and overrides its PROMPT/RPROMPT.
    #     git_prompt_info comes from the `git` oh-my-zsh plugin;
    #     virtualenv_prompt_info from the `virtualenv` plugin. The
    #     ZSH_THEME_*_PROMPT vars mirror the amuse theme so the venv segment
    #     matches the original Arch setup.
    initContent = lib.mkMerge [
      (lib.mkBefore ''
        zstyle ':omz:plugins:eza' 'icons' yes
        zstyle ':omz:plugins:eza' 'dirs-first' yes
      '')
      ''
        VIRTUAL_ENV_DISABLE_PROMPT=0
        ZSH_THEME_VIRTUAL_ENV_PROMPT_PREFIX=" %F{cyan}🐍 ("
        ZSH_THEME_VIRTUAL_ENV_PROMPT_SUFFIX=")%f"
        ZSH_THEME_VIRTUALENV_PREFIX=$ZSH_THEME_VIRTUAL_ENV_PROMPT_PREFIX
        ZSH_THEME_VIRTUALENV_SUFFIX=$ZSH_THEME_VIRTUAL_ENV_PROMPT_SUFFIX

        # Left prompt:  <path> <git> <venv> <exit-code on failure> ↪
        PROMPT='%F{blue}%~%f $(git_prompt_info)$(virtualenv_prompt_info)%F{red}%(?.. [%?])%f %F{yellow}$%f '
        # Right prompt: [HH:MM:SS]
        RPROMPT='⌚%F{cyan}[%D{%H:%M:%S}]%f'

        source "${config.home.homeDirectory}/nixos-dotfiles/config/.config/zsh/zshrc_addon.zsh"
      ''
    ];

    shellAliases = {
      btw = "echo i use nixos-btw";
      nrs = "sudo nixos-rebuild switch --flake ~/nixos-dotfiles#nixos";
      claude = "nix run 'github:ryoppippi/nix-claude-code#stable' -- ";
      # NOTE: `gcommit` is intentionally not an alias here — the JIRA-aware
      # `gcommit` function in zshrc_addon.zsh handles it (an alias would shadow
      # the function, since shellAliases are emitted after initContent).
    };

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
        "z"
        "virtualenv"
        "gh"
        "zsh-interactive-cd"
        "eza" # wraps `ls`/`ll`/`la`/`lT` etc. with eza; package ships in home-packages.nix
        # external, from ZSH_CUSTOM (built in `let`)
      ];
    };

    # Print system info on SSH login only. `$SSH_CONNECTION` is set by sshd
    # (never in local Hyprland terminals or tmux panes), and `loginShellInit`
    # runs only for login shells — sshd starts one by default, while tmux panes
    # spawn non-login interactive shells. Together this fires fastfetch exactly
    # once at the top of an SSH session and nowhere else. fastfetch ships as a
    # system package (nixos/modules/development/info-fetchers.nix).
    # `loginExtra` is written to ~/.zlogin, sourced only for login shells.
    # sshd starts a login shell by default, while local Hyprland terminals and
    # tmux panes spawn non-login shells — so this fires once at the top of an
    # SSH session and nowhere else. The `$SSH_CONNECTION` guard additionally
    # excludes any local login shell (e.g. a VT/console login). fastfetch ships
    # as a system package (nixos/modules/development/info-fetchers.nix).
    loginExtra = ''
      if [[ -n "$SSH_CONNECTION" && -o interactive ]]; then
        fastfetch
      fi
    '';

    # zsh-autosuggestions and zsh-syntax-highlighting have no `.plugin.zsh`
    # in their nixpkgs packages, so they can't live in ZSH_CUSTOM. Home Manager
    # sources them directly (and in the correct order) via these options.
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
  };
}