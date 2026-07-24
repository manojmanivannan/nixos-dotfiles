{ config, lib, pkgs, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Londonm";


  # Enable the X11 windowing system.
  # services.xserver.enable = true;
  services.displayManager.ly.enable = true;
  services.xserver = {
	enable = true;
	autoRepeatDelay = 200;
	autoRepeatInterval = 35;
	windowManager.qtile.enable = true;

  };


  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.manoj = {
    isNormalUser = true;
    extraGroups = [ "wheel" "sudo" ]; # Enable ‘sudo’ for the user.
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

