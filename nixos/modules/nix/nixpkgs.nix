{ ... }:

{
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # nixpkgs.overlays = [
  #   (final: prev: {
  #     nix-ai-tools = inputs.nix-ai-tools.packages.${final.stdenv.hostPlatform.system};
  #   })
  # ];
  # NOTE: the nix-ai-tools overlay above is left disabled because the
  # `nix-ai-tools` flake input is not declared in flake.nix. Re-add the
  # input to flake.nix first, then uncomment here to use it.

  # Override packages
  # nixpkgs.config.packageOverrides = pkgs: {
  #   nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
  #     inherit pkgs;
  #   };
  # };
}
