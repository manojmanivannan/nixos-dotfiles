{ ... }:

{
  imports = [
    ./networking.nix
    ./dns.nix
    ./firewall.nix
    ./vpn.nix
    ./avahi.nix
  ];
}