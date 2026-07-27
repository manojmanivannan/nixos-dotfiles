{
  description = "XNM's NixOS Configuration";

  inputs = {
      nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
      systems.url = "github:nix-systems/x86_64-linux";
      rust-overlay.url = "github:oxalica/rust-overlay";
      hyprland.url = "github:hyprwm/Hyprland";
      home-manager.url = "github:nix-community/home-manager/release-26.05";
      home-manager.inputs.nixpkgs.follows = "nixpkgs";

   };

  outputs = { nixpkgs, home-manager, ... } @ inputs:
  {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./configuration.nix
        ./hardware-configuration.nix
        ./modules/nvidia.nix
        ./modules/sound.nix
        ./modules/usb.nix
        ./modules/keyboard.nix
        ./modules/time.nix
        ./modules/swap.nix
        ./modules/bootloader.nix
        ./modules/nix-settings.nix
        ./modules/nixpkgs.nix
        ./modules/gc.nix
        ./modules/linux-kernel.nix
        ./modules/screen.nix
        ./modules/display-manager.nix
        ./modules/theme.nix
        ./modules/internationalisation.nix
        ./modules/fonts.nix
        ./modules/security-services.nix
        ./modules/services.nix
        ./modules/power.nix
        ./modules/hyprland.nix
        ./modules/environment-variables.nix
        ./modules/bluetooth.nix
        ./modules/networking.nix
        ./modules/firewall.nix
        ./modules/dns.nix
        ./modules/vpn.nix
        ./modules/users.nix
        ./modules/virtualisation.nix
        ./modules/programming-languages.nix
        ./modules/lsp.nix
        ./modules/rust.nix
        ./modules/radicle.nix
        ./modules/dev-tools.nix
        ./modules/terminal.nix
        ./modules/work.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.manoj = import ./home.nix;
          home-manager.backupFileExtension = "backup";
        }
      ];
    };
  };
}
