{ inputs, pkgs, ... }:

{
  # Enable Hyprland
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };

  # WF-14 — hyprlock retired. The lock screen is caelestia's `Lock` module
  # (modules/lock/Lock.qml), invoked via `loginctl lock-session` whose logind
  # `Lock` signal caelestia's SessionManager bridges to `WlSessionLock.locked`
  # (plugin/src/Caelestia/Services/sessionmanager.cpp). With hyprlock gone, that
  # route is exclusively caelestia's — see home-manager/modules/caelestia.nix
  # (password-only PAM) and config/.config/hypr/hypridle.conf (auto-lock @600s).
  services.hypridle.enable = true;

  environment.systemPackages = with pkgs; [
    pyprland
    hyprpicker
    hyprcursor
    hypridle
    swaybg
    hyprsunset
    hyprpolkitagent
  ];
}
