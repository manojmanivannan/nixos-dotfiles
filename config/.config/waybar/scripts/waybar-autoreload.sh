#!/bin/sh
# Hot-reload waybar whenever its config or scripts change on disk.
#
# Watches the waybar config directory — resolved through the dotfiles symlink
# (so edits in the repo trigger it) — recursively with inotifywait, and on
# any close_write of config.jsonc or a *.sh script sends waybar SIGUSR2, which
# reloads the full config in place. style.css is intentionally NOT signalled
# here: `reload_style_on_change` in config.jsonc already hot-swaps CSS
# seamlessly (no flicker), so we leave it to that.
#
# SIGUSR2 on a script save matters for the long-running cava exec (it only
# restarts on a full reload); the interval-based scripts would pick up edits
# on their next tick anyway, so the reload there is just harmless insurance.
#
# Cheap to leave running: inotifywait sleeps in the kernel, not a poll loop.
# Started once per Hyprland session from config/.config/hypr/hyprland.lua
# (alongside waybar); inotify-tools ships in nixos/modules/services/services.nix.

DIR=$(readlink -f "${XDG_CONFIG_HOME:-$HOME/.config}/waybar")
[ -d "$DIR" ] || exit 0

# -r recursive (covers scripts/), -m monitor continuously, --format prints the
# changed file path per event. pkill -x matches the exact process name
# "waybar" and is silent if it isn't up yet (this can start before waybar).
inotifywait -q -r -m -e close_write --format '%w%f' "$DIR" 2>/dev/null \
  | while read -r file; do
      case "$file" in
        *.jsonc|*.sh) pkill -USR2 -x waybar 2>/dev/null ;;
      esac
    done