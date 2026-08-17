{ pkgs, user, ... }:

{
  # Enable Kasm
  # services.kasmweb = {
  #   enable = true;
  #   listenPort = 9999;
  # };

  # Enable Containerd
  # virtualisation.containerd.enable = true;

  # Enable Docker
  # virtualisation.docker = {
  #   enable = true;
  #   rootless = {
  #     enable = true;
  #     setSocketVariable = true;
  #     daemon.settings.features.cdi = true;
  #   };
  # };
  # users.extraGroups.docker.members = [ "xnm" ];

  virtualisation.docker.enable = true;

  # Virt-manager / libvirtd — graphical VM management (libvirt + QEMU/KVM).
  # See https://wiki.nixos.org/wiki/Virt-manager
  virtualisation.libvirtd = {
    enable = true;
    # virtiofsd lets a VM share a host directory via the virtio-fs device.
    qemu.vhostUserPackages = with pkgs; [ virtiofsd ];
  };
  programs.virt-manager.enable = true;
  # Membership in `libvirtd` lets the user talk to the libvirt socket without a
  # polkit password prompt each time.
  users.extraGroups.libvirtd.members = [ user ];

  # Enable Podman
  virtualisation.podman = {
    enable = false;

    # Create a `docker` alias for podman, to use it as a drop-in replacement
    dockerCompat = false;
    dockerSocket.enable = false;
    # dockerCompat = true;
    # dockerSocket.enable = true;

    # Required for containers under podman-compose to be able to talk to each other.
    defaultNetwork.settings.dns_enabled = true;
  };

  users.extraGroups.docker.members = [ user ];

  environment.systemPackages = with pkgs; [
    nvidia-docker

    # firecracker
    # firectl
    # flintlock

    qemu
    lima
    lima-additional-guestagents

    docker-client
    docker-compose
    lazydocker
    docker-credential-helpers

    # dnsmasq provides DNS/DHCP for libvirt's default (NAT) network.
    dnsmasq
  ];
}
