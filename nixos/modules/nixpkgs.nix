{ inputs, ... }:

{
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # sublime4 depends on the EOL openssl-1.1.1w; permit it explicitly.
  nixpkgs.config.permittedInsecurePackages = [ "openssl-1.1.1w" ];

  nixpkgs.overlays = [
    (final: prev: {
      nix-ai-tools = inputs.nix-ai-tools.packages.${final.stdenv.hostPlatform.system};
    })
  ];
  
  # Override packages
  # nixpkgs.config.packageOverrides = pkgs: {
  #   nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
  #     inherit pkgs;
  #   };
  # };
}
