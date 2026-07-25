{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  # The adi1090x rofi themes (vendored under config/rofi) reference two fonts
  # that aren't packaged in nixpkgs: "feather" (Icomoon-Feather) supplies the
  # prompt / powermenu glyphs, and "Grape Nuts" is used by the type-5 launcher
  # styles. Vendor their TTFs from this repo into a font package so fontconfig
  # — and therefore rofi — can resolve them system-wide.
  custom-rofi-fonts = pkgs.runCommand "custom-rofi-fonts" { } ''
    mkdir -p $out/share/fonts/truetype/custom-rofi
    cp ${./config/rofi/fonts}/Icomoon-Feather.ttf     $out/share/fonts/truetype/custom-rofi/
    cp ${./config/rofi/fonts}/GrapeNuts-Regular.ttf   $out/share/fonts/truetype/custom-rofi/
  '';
in

{
  imports = [
    # Include the results of the hardware scan.
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
  boot.loader.systemd-boot.configurationLimit = 10;

  networking.hostName = "nixos"; # Define your hostname.

  # Static networking is configured declaratively below (eno1). NetworkManager
  # is disabled so it can't conflict with the static interface config.
  # networking.networkmanager.enable = true;

  # Bluetooth — power on the controller automatically at boot.
  # blueman (in environment.systemPackages) provides the GUI applet.
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Set your time zone.
  time.timeZone = "Europe/London";

  # Enable the X11 windowing system.
  # services.xserver.enable = true;
  services.displayManager.ly.enable = true;
  services.xserver = {
    enable = true;
    autoRepeatDelay = 200;
    autoRepeatInterval = 35;

  };

  # NVIDIA — GeForce RTX 4090 (Ada Lovelace). Open kernel modules (Turing+),
  # modesetting on for Wayland (Hyprland).
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    open = true; # open-source kernel modules; set false for proprietary
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Zsh as the system shell. Setting users.users.<name>.shell requires the
  # shell to be enabled in programs.<shell>.enabled.
  programs.zsh.enable = true;
  programs.steam = {
    enable = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.manoj = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "sudo"
      "docker"
    ]; # Enable ‘sudo’ for the user.
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

  programs.nix-ld.enable = true;

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
    swaybg
    hyprlock
    wlogout
    wofi
    # bar / launcher on-click targets + keybind targets
    pavucontrol
    blueman
    pamixer
    btop
    nvitop
    lazydocker
    grimblast
    uv
  ];
  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Auto-start blueman-applet (Bluetooth tray applet) at login.
  services.blueman.enable = true;

  # Secret Service provider (gnome-keyring) so browsers / VS Code / Electron
  # apps can store credentials via libsecret. PAM auto-unlocks it at login.
  services.gnome.gnome-keyring.enable = true;

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.iosevka # "Iosevka Nerd Font" — used by several adi1090x rofi styles
    cascadia-code
    fira-code
    custom-rofi-fonts # "feather" (Icomoon-Feather) + "Grape Nuts" for adi1090x rofi themes
  ];

  networking.useDHCP = false;
  networking.interfaces.eno1 = {
    ipv4.addresses = [
      {
        address = "192.168.1.192";
        prefixLength = 24;
      }
    ];
  };
  networking.defaultGateway = "192.168.1.1";
  networking.nameservers = [
    "1.1.1.1"
    "8.8.8.8"
  ];

  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  system.stateVersion = "26.05"; # Did you read the comment?

}
