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

  # Stable symlink for the RTX 4090's DRM card. /dev/dri/cardN numbering is not
  # boot-stable (on 2026-09-29 the AMD iGPU grabbed card0 while the RTX sat on
  # card1, leaving Hyprland pinned to an iGPU with no monitor -> black console).
  # AQ_DRM_DEVICES splits on ':', so the colon-bearing /dev/dri/by-path entries
  # are unusable there; a udev symlink gives us a fixed, colon-free name.
  services.udev.extraRules = ''
    SUBSYSTEM=="drm", KERNEL=="card[0-9]*", SUBSYSTEMS=="pci", KERNELS=="0000:01:00.0", SYMLINK+="dri/rtx4090"
  '';

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
