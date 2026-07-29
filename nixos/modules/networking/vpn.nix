{ pkgs, config, ... }:

{

  # Enable Tailscale
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "none";
  };

  networking.firewall.allowedUDPPorts = [
    config.services.tailscale.port
  ];

  environment.systemPackages = with pkgs; [
    tailscale
  ];
}
