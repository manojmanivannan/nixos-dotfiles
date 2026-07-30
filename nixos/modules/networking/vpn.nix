{ pkgs, config, user, ... }:

{

  # Enable Tailscale
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "none";
    # Let the desktop user bring Tailscale up/down without sudo, so the waybar
    # `custom/tailscale` pill can toggle connectivity. `tailscale set
    # --operator` (what extraSetFlags runs on activation) can be flaky — see
    # tailscale bug #18294 — so also run `sudo tailscale up --operator=$USER`
    # once to make it stick.
    extraSetFlags = [ "--operator=${user}" ];
  };

  networking.firewall.allowedUDPPorts = [
    config.services.tailscale.port
  ];

  environment.systemPackages = with pkgs; [
    tailscale
  ];
}
