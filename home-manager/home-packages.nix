{ inputs, pkgs, ... }: {
  home.packages = with pkgs; [
    nixfmt
    eza # modern ls replacement; aliased via the oh-my-zsh `eza` plugin (see zsh.nix)
    nautilus # GNOME file manager; launched on Super+E via the `fileManager` bind in hypr/bindings.lua
    localsend # AirDrop-style cross-platform file transfer; ports opened in networking/firewall.nix
    obsidian # local-folder Markdown knowledge base
    # Built from the herdr flake input (flake.nix) rather than nixpkgs, since
    # herdr isn't packaged in nixpkgs. `inputs` reaches here via
    # home-manager.extraSpecialArgs in nixos/modules/nix/home-manager.nix.
    inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}