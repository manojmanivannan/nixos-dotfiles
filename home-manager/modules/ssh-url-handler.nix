{ pkgs, lib, ... }:

# x-scheme-handler/ssh — lets clicking an `ssh://user@host` link (e.g. in
# Chrome) open a Ghostty window with an SSH session instead of the
# "No apps installed that can open ssh://..." chooser.
#
# Two pieces are required, and missing either one reproduces the bug:
#
#   1. A .desktop entry with `MimeType=x-scheme-handler/ssh` so the desktop
#      index (mimeinfo.cache) knows an app exists for the scheme. Without
#      it, xdg-open reports "no apps available".
#
#   2. A default mapping in ~/.config/mimeapps.list (xdg.mimeApps below) so
#      xdg-open picks ours instead of popping the interactive "Open with"
#      chooser. `xdg.desktopEntries` alone never writes mimeapps.list.
#
# The Exec line can't be plain `ghostty ssh://...` — the terminal needs the
# URL unpicked into `ssh [options] destination`, so a tiny wrapper script
# does the parsing and execs Ghostty's `-e` mode.
let
  ssh-url-handler = pkgs.writeShellScriptBin "ssh-url-handler" ''
    set -euo pipefail
    url="''${1:-}"
    # Parse an RFC 3986-ish ssh URL: ssh://[user@]host[:port][/path...]
    url="''${url#ssh://}"
    url="''${url%%\?*}"   # drop query string
    url="''${url%%#*}"    # drop fragment
    url="''${url%%/*}"    # drop path; only user@host:port is connectable
    port=""
    case "$url" in
      *:*) port="''${url##*:}"; url="''${url%%:*}" ;;
    esac
    if [ -z "$url" ]; then
      echo "ssh-url-handler: no host in '$1'" >&2
      exit 1
    fi
    # ssh wants options before the destination: [-p PORT] [user@]host
    args=("$url")
    if [ -n "$port" ]; then
      args=(-p "$port" "''${args[@]}")
    fi
    exec ${pkgs.ghostty}/bin/ghostty -e \
      ${pkgs.openssh}/bin/ssh "''${args[@]}"
  '';
in
{
  home.packages = [ ssh-url-handler ];

  xdg.desktopEntries.ssh-url-handler = {
    name = "SSH handler";
    genericName = "SSH";
    comment = "Open ssh:// links in a Ghostty SSH session";
    exec = "ssh-url-handler %u";
    icon = "network-server";
    type = "Application";
    terminal = false;
    categories = [ "Network" ];
    mimeType = [ "x-scheme-handler/ssh" ];
  };

  xdg.mimeApps.defaultApplications."x-scheme-handler/ssh" =
    "ssh-url-handler.desktop";
}
