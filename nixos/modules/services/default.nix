{ ... }:

{
  imports = [
    ./services.nix
    ./openssh.nix
    ./power.nix
    ./sound.nix
    ./usb.nix
    ./radicle.nix
    ./virtualisation.nix
  ];
}