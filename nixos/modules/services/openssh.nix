{ ... }:

{
  # Enable the OpenSSH server so the machine is reachable over the LAN
  # (e.g. `ssh manoj@linux-machine` / `ssh manoj@192.168.1.192`).
  services.openssh.enable = true;

  # The firewall is enabled in networking/firewall.nix, so port 22 must
  # be explicitly opened for inbound SSH to work.
  networking.firewall.allowedTCPPorts = [ 22 ];
}