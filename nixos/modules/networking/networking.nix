{ pkgs, ipv4Address, defaultGateway, ... }:

{
  # Enable networking
  # networking.hostName is set in hosts/<name>/configuration.nix from the
  # `hostname` specialArg, so the machine's name is driven by the flake's
  # `hosts` list rather than hardcoded here.
  # The static IPv4 address and default gateway are likewise driven by the
  # `ipv4Address`/`defaultGateway` specialArgs, sourced from the flake's
  # `hosts` list.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.
  # networking.networkmanager.wifi.backend = "iwd";

 networking.useDHCP = false;
  networking.interfaces.eno1 = {
    ipv4.addresses = [
      {
        address = ipv4Address;
        prefixLength = 24;
      }
    ];
  };
  networking.defaultGateway = defaultGateway;
  networking.nameservers = [
    "1.1.1.1"
    "8.8.8.8"
  ];
  
  # networking.wireless.iwd = {
  #   enable = true;
  #   settings = {
  #     General = {
  #       EnableNetworkConfiguration = true;
  #     };
  #     Network = {
  #       EnableIPv6 = true;
  #     };
  #     Scan = {
  #       DisablePeriodicScan = true;
  #     };
  #   };
  # };

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  environment.systemPackages = with pkgs; [
    iwgtk
    impala
  ];
}
