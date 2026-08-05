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
    #  2. The zsh addon loader + Starship init, at default ordering so they run
    #     AFTER `source $ZSH/oh-my-zsh.sh`. The addon (functions/aliases/exports)
    #     lives under ~/.config/zsh, symlinked from the repo by
    #     dotfiles-symlinks.nix. `starship init zsh` must come after oh-my-zsh
    #     so Starship's PROMPT wins over any theme; oh-my-zsh.theme is left
    #     empty below so no theme sets a competing prompt. Starship's config
    #     (~/.config/starship.toml) is also symlinked from the repo; the
    #     binary ships as a system package (nixos/modules/development/terminal.nix).
    initContent = lib.mkMerge [
      (lib.mkBefore ''
        zstyle ':omz:plugins:eza' 'icons' yes
        zstyle ':omz:plugins:eza' 'dirs-first' yes
      '')
      ''
        # Load the XDG-organized zsh snippets (functions, git, aliases, exports).
        # zshrc_addon.zsh is a thin glob-sorted loader over zshrc.d/*.zsh.
        source "$HOME/.config/zsh/zshrc_addon.zsh"

        # Fancy prompt — Starship (nerd-font segments: dir, git, nix_shell,
        # python/venv, cmd_duration, time, ...). See ~/.config/starship.toml.
        eval "$(starship init zsh)"
      ''
    ];

    shellAliases = {
      btw = "echo i use nixos-btw";
      nrs = "sudo nixos-rebuild switch --flake ~/nixos-dotfiles#nixos";
      claude = "nix run 'github:ryoppippi/nix-claude-code#stable' -- ";
      # NOTE: `gcommit` is intentionally not an alias here — the JIRA-aware
      # `gcommit` function in zshrc.d/20-git.zsh handles it (an alias would
      # shadow the function, since shellAliases are emitted after initContent).
    };

    # oh-my-zsh is kept for its plugins only. The prompt is owned by Starship
    # (init'd above), so theme is left empty — no theme sets a competing
    # PROMPT/RPROMPT. `virtualenv` was dropped: it only provided
    # virtualenv_prompt_info for the old hand-written prompt, and Starship's
    # python segment now shows the active venv. `git` stays — the user's git
    # functions (gcb/gco/gfo in zshrc.d/20-git.zsh) rely on its aliases.
    oh-my-zsh = {
      enable = true;
      theme = "";
      plugins = [
        # built-in
        "git"
        "colored-man-pages"
        "colorize"
        "command-not-found"
        "z"
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