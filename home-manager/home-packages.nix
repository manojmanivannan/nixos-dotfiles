{ pkgs, ... }: {
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
    btop # TUI resource monitor (CPU/RAM/net) — drop-in htop upgrade
    nvtopPackages.full # TUI GPU monitor; the "full" build supports AMD + NVIDIA + Intel
  ];
}