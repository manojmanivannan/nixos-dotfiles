{ pkgs, ... }:

{
  # Enable Services
  programs.dconf.enable = true;
  services.dbus = {
    enable = true;
    implementation = "broker";
    packages = with pkgs; [
      gnome2.GConf
    ];
  };
  services.mpd.enable = true;
  programs.xfconf.enable = true;

  # services.gnome.core-shell.enable = true;
  # services.udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];

  environment.systemPackages = with pkgs; [
    qutebrowser
    zathura
    mpv
    mpv-handler
    imv
    at-spi2-atk
    qt6.qtwayland
    playerctl
    psmisc
    grim
    slurp
    imagemagick
    swappy
    ffmpeg_6-full
    wl-screenrec
    wl-clipboard
    wl-clip-persist
    cliphist
    xdg-utils
    # notify-send: caelestia toasts (dashboard/Wrapper.qml profile-picture,
    # areapicker/Picker.qml screenshot) + the ported tailscale.sh picker. WF-16
    # kept libnotify after confirming caelestia shells out to it (WF-15).
    libnotify
    libfido2
  ];
}
