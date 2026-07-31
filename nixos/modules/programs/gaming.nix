{ pkgs, ... }:

{
  # Steam. `programs.steam.enable` installs the client and pulls in the
  # steam-runtime container plus the 32-bit graphics stack it needs.
  programs.steam = {
    enable = true;
    # Open the ports Steam uses for In-Home Streaming / Remote Play so a
    # remote client on the LAN can connect without manual firewall tweaks.
    remotePlay.openFirewall = true;
    # Open ports for Steam Dedicated Servers (srcds), in case this machine
    # ever hosts a game server.
    dedicatedServer.openFirewall = true;
    # `steam-session` PAM + a Hyprland/gamescope "Gamescope Session" entry so
    # a game can be launched in a nested gamescope compositor from the login
    # screen, bypassing the main DE entirely.
    gamescopeSession.enable = true;
  };

  # 32-bit graphics/Vulkan drivers. Required by many native games and by
  # Proton's 32-bit prefixes. With the NVIDIA module active, NixOS wires the
  # matching 32-bit NVIDIA userland libs automatically once this is on.
  hardware.graphics.enable32Bit = true;

  # Feral GameMode: on-demand CPU governor / GPU / scheduling tweaks a game
  # requests via `gamemoderun`. `programs.gamemode.enable` installs the
  # daemon + pkexec policy so the user doesn't need to be root.
  programs.gamemode.enable = true;

  environment.systemPackages = with pkgs; [
    gamemode # `gamemoderun %command%` in a Steam game's launch options
    mangohud # Vulkan/OpenGL overlay: FPS, frametimes, CPU/GPU load (press Right Shift+F12 to toggle)
    gamescope # micro-compositor for nested/low-latency rendering; used by gamescopeSession
  ];
}