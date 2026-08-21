{ ... }:

{
  # Open ports in the firewall.
  networking.firewall.enable = true;
  # networking.firewall.allowedTCPPorts = [ 3000 ];
  # networking.firewall.allowedUDPPorts = [ 3000 ];
  # LocalSend (AirDrop-style file transfer) — discovery + transfer
  networking.firewall.allowedTCPPorts = [ 53317 ];
  networking.firewall.allowedUDPPorts = [ 53317 ];
  # Trust libvirt's default NAT bridge so VMs reach the host/internet without
  # being blocked by the firewall.
  networking.firewall.trustedInterfaces = [ "virbr0" ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;
}
