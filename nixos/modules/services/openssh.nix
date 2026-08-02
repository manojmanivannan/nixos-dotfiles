{ ... }:

{
  # Enable the OpenSSH server so the machine is reachable over the LAN
  # (e.g. `ssh manoj@linux-machine` / `ssh manoj@192.168.1.192`).
  services.openssh = {
    enable = true;

    settings = {
      # Key-only authentication: disable password and all other
      # keyboard-interactive / challenge-response fallbacks, so the only
      # way in is a private key matching an authorized_keys entry.
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # The firewall is enabled in networking/firewall.nix, so port 22 must
  # be explicitly opened for inbound SSH to work.
  networking.firewall.allowedTCPPorts = [ 22 ];
}