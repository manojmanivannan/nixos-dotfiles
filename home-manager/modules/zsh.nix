{ config, lib, pkgs, ... }:

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

        # Shell behaviour setopts (the history options are set above via
        # programs.zsh.history; these are the non-history ones from the
        # "Perfect Zsh 2026" setup).
        setopt AUTO_CD           # type a bare dir name to cd into it
        setopt NO_BEEP           # silence the terminal bell
        setopt NUMERIC_GLOB_SORT # 1..10 not 1,10,2 (lexical glob sort)

        # fzf-tab — replaces the tab-completion menu with an fzf-powered one.
        # Must load AFTER compinit (which ran in the addon above and via
        # programs.zsh.enableCompletion). Previews use eza (dirs) and bat
        # (files) — both already installed. Loaded before autosuggestions,
        # which HM sources after initContent.
        source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --tree --color=always --icons $realpath'
        zstyle ':fzf-tab:complete:*:*' fzf-preview 'bat --style=numbers --color=always $realpath 2>/dev/null || eza --tree --color=always --icons $realpath'

        # zsh-abbr — fish-style inline abbreviations that expand on space.
        # Add your own with: abbr -a <name> <expansion>
        source ${pkgs.zsh-abbr}/share/zsh/zsh-abbr/zsh-abbr.plugin.zsh

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

    # History tuning — matches the "Perfect Zsh 2026" setup: large shared
    # history, no duplicates, timestamps, dups expire first. `path` is left
    # to HM's default (~/.zsh_history) to avoid needing an XDG-state dir.
    # HM translates these to the corresponding HIST* / setopt options.
    history = {
      size = 100000;
      save = 100000;
      ignoreDups = true;
      ignoreSpace = true;        # leading-space commands stay out of history
      expireDuplicatesFirst = true;
      share = true;              # SHARE_HISTORY: sync across live shells
      extended = true;           # EXTENDED_HISTORY: record timestamps
    };

    # Up/Down filter history to lines matching the current line prefix.
    # HM binds the keys and sources it in the correct order relative to
    # autosuggestions, so the two cooperate.
    historySubstringSearch.enable = true;

    # oh-my-zsh is kept for its plugins only. The prompt is owned by Starship
    # (init'd above), so theme is left empty — no theme sets a competing
    # PROMPT/RPROMPT. `virtualenv` was dropped: it only provided
    # virtualenv_prompt_info for the old hand-written prompt, and Starship's
    # python segment now shows the active venv. `git` stays — the user's git
    # functions (gcb/gco/gfo in zshrc.d/20-git.zsh) rely on its aliases.
    # `z` removed — replaced by zoxide's `z`/`zi` (home-manager/modules/zoxide.nix);
    # the two `z` commands would otherwise collide. `colored-man-pages`
    # removed — bat is now the manpager (home-manager/modules/bat.nix), which
    # is richer and what `man` actually invokes via $MANPAGER.
    oh-my-zsh = {
      enable = true;
      theme = "";
      plugins = [
        # built-in
        "git"
        "colorize"
        "command-not-found"
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