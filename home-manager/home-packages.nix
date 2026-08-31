{ inputs, pkgs, ... }: {
  home.packages = with pkgs; [
    # Patchelf'd browsers for PLAYWRIGHT_BROWSERS_PATH (see home.nix). Playwright
    # only accepts its exact matching revision, so pin any playwright package to
    # `nix eval nixpkgs#playwright-driver.version` (currently 1.59.1) — e.g.
    # `npx -y playwright@1.59.1`; never `npx playwright`, which floats to latest
    # and falls back to unpatched ~/.cache builds (missing libglib-2.0.so.0).
    playwright-driver.browsers
    nixfmt
    eza # modern ls replacement; aliased via the oh-my-zsh `eza` plugin (see zsh.nix)
    nautilus # GNOME file manager; launched on Super+E via the `fileManager` bind in hypr/bindings.lua
    localsend # AirDrop-style cross-platform file transfer; ports opened in networking/firewall.nix
    obsidian # local-folder Markdown knowledge base
    # Built from the herdr flake input (flake.nix) rather than nixpkgs, since
    # herdr isn't packaged in nixpkgs. `inputs` reaches here via
    # home-manager.extraSpecialArgs in nixos/modules/nix/home-manager.nix.
    inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default
    # Google Antigravity suite (Base App, IDE, and CLI `agy`) via jacopone/antigravity-nix
    inputs.antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system}.google-antigravity-ide
    inputs.antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system}.google-antigravity-cli
  ];
}