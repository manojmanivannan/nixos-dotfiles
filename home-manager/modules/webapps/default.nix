{ ... }:

# Web apps — standalone browser windows surfaced in the SUPER+SPACE launcher.
#
# The launcher (caelestia:launcher, bound to SUPER+SPACE in
# config/.config/hypr/bindings.lua) keeps no app list of its own: it reads
# `DesktopEntries.applications` — the standard XDG .desktop index that
# rofi/wofi/drun also read. A "web app" is therefore just a .desktop entry
# whose Exec launches google-chrome (declared in nixos/modules/users/users.nix)
# in --app mode. HM's xdg.desktopEntries writes each entry to
# ~/.local/share/applications/, and the launcher picks it up on next open —
# its apps.sqlite only caches launch frequency, not the app list (see
# caelestia's modules/launcher/services/Apps.qml).
#
# --app=URL opens a tabless, omnibox-less window; --class= sets the Wayland
# app-id so Hyprland window rules can target the app (class:^(ugreen)$).
#
# ICONS — each entry needs its icon installed into hicolor (~/.local/share/
# icons/hicolor/<size>/apps/ via xdg.dataFile below), not just named after a
# themed icon. The launcher resolves icons through Quickshell's
# `Quickshell.iconPath(name, "image-missing")` (modules/launcher/items/
# AppItem.qml), which is a pure QIcon::fromTheme lookup: it never loads a bare
# absolute path from Icon=, and it walks the active theme → its parents →
# hicolor. The active theme here is effectively uninstalled (live dconf says
# Papirus-Dark; only colloid-icon-theme is declared — see
# nixos/modules/desktop/theme.nix), so themed names like `network-server` fall
# all the way through to hicolor, which only carries app-brand icons — hence
# the blank tile. Brand icons (obsidian, google-chrome, the Steam entry's
# steam_icon_730.png) render because their packages ship them into hicolor;
# shipping ours the same way rides the one path that provably works.
#
# The icon itself is the UGOS favicon, pulled off the NAS with
# `curl -k https://dxp2800-nas-mm.local:9443/desktop/favicon.ico` and converted
# with `magick favicon.ico -strip PNG32:ugreen.png` (32×32 — all UGOS exposes).
{
  xdg.desktopEntries = {
    ugreen = {
      name = "UGREEN";
      genericName = "NAS";
      comment = "UGREEN DXP2800 NAS (UGOS web UI)";
      exec = "google-chrome --app=https://dxp2800-nas-mm.local:9443 --class=ugreen";
      icon = "ugreen";
      type = "Application";
      terminal = false;
      categories = [ "Network" ];
    };
  };

  # hicolor is the terminal fallback of every freedesktop icon lookup, so a
  # name installed here resolves regardless of which (or whether an) icon
  # theme is active. ~/.local/share/icons/hicolor is a plain user directory
  # (Steam's icon already lives beside this), so xdg.dataFile can grow it.
  xdg.dataFile."icons/hicolor/32x32/apps/ugreen.png".source = ./ugreen.png;
}
