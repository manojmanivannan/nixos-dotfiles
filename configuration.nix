{ config, lib, pkgs, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Allow unfree software (needed for vscode, sublime4, etc.).
  # With home-manager.useGlobalPkgs = true this also covers Home Manager packages.
  nixpkgs.config.allowUnfree = true;
  # sublime4 depends on the EOL openssl-1.1.1w; permit it explicitly.
  nixpkgs.config.permittedInsecurePackages = [ "openssl-1.1.1w" ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/London";


  # Enable the X11 windowing system.
  # services.xserver.enable = true;
  services.displayManager.ly.enable = true;
  services.xserver = {
	enable = true;
	autoRepeatDelay = 200;
	autoRepeatInterval = 35;
	windowManager.qtile.enable = true;

  };

  # NVIDIA — GeForce RTX 4090 (Ada Lovelace). Open kernel modules (Turing+),
  # modesetting on for Wayland (Hyprland) and X11 (qtile).
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    open = true; # open-source kernel modules; set false for proprietary
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };


  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.manoj = {
    isNormalUser = true;
    extraGroups = [ "wheel" "sudo" "docker" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      tree
    ];
  };

  programs.firefox.enable = true;
  programs.hyprland = {
	enable = true;
	withUWSM = true;
	xwayland.enable = true;
  };

#  programs.hyprland = {
#	enable = true;
#	package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
#	portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
#  };
  # Docker (daemon must be system-level; there is no Home Manager equivalent).
  virtualisation.docker.enable = true;

  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    git
    alacritty
    nautilus
    waybar
    walker
    hyprpaper
    wofi
    # bar / launcher on-click targets + keybind targets
    pavucontrol
    blueman
    networkmanagerapplet
    pamixer
    btop
    nvitop
    lazydocker
    grimblast
  ];
  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  fonts.packages = with pkgs; [
	nerd-fonts.jetbrains-mono
  ];

  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  nix.settings.experimental-features = ["nix-command" "flakes"];
  system.stateVersion = "26.05"; # Did you read the comment?

}

