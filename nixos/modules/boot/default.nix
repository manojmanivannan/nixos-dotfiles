{ ... }:

{
  imports = [
    ./bootloader.nix
    ./linux-kernel.nix
    ./swap.nix
  ];
}