{ config, pkgs, ... }:

let
  dotfiles = "${config.home.homeDirectory}/nixos-dotfiles/home/.config";
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;

  # Standard .config/directory
  configs = {
    rofi = "rofi";
    hypr = "hypr";
    waybar = "waybar";
    wlogout = "wlogout";
    sway = "sway";
    swaync = "swaync";
    wofi = "wofi";
  };
in

{
  home.username = "manoj";
  home.homeDirectory = "/home/manoj";
  programs.git = {
    enable = true;
    settings = {
      user.email = "manojm18@live.in";
      user.name = "Manoj Manivannan";
      init.defaultBranch = "main";
    };
  };
  # fzf key bindings + fuzzy completion — replaces the old `source <(fzf --zsh)`.
  # Required by the fzf-zsh-plugin oh-my-zsh plugin.
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
  home.stateVersion = "26.05";

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

  # Wallpaper is set by swaybg, launched from Hyprland on startup
  # (see config/hypr/hyprland.lua). swaybg ships in configuration.nix, so no
  # Home Manager service is needed here.
  xdg.configFile = builtins.mapAttrs (name: subpath: {
    source = create_symlink "${dotfiles}/${subpath}";
    recursive = true;
  }) configs;

  home.packages = with pkgs; [
    neovim
    ripgrep
    nil
    nixfmt
    nixpkgs-fmt
    nodejs
    gcc
    rofi
    wofi
    xwallpaper
    sublime4
    swaynotificationcenter # ships the `swaync` daemon + `swaync-client`; started from hyprland.start
    libnotify # provides `notify-send` for testing swaync
    docker-compose
    eza # modern ls replacement; the zsh-eza plugin wraps it
  ];


#   wayland.windowManager.hyprland.systemd.enable = false;
}
