{ pkgs, ... }:

{
  # System-level: make zsh available as a login shell (users.nix sets the user
  # shell to pkgs.zsh). The per-user zsh customization lives in home.nix under
  # home-manager's `programs.zsh`, since options like `initContent`,
  # `oh-my-zsh`, and `config.home` only exist there.
  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [
    kitty
    cool-retro-term
    starship
    ripgrep
    yt-dlp
    jq
    fzf
    bat
    cmatrix
  ];
}
