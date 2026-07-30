#!/bin/sh
# Hot-reload waybar whenever its config or scripts change on disk.
#
# Watches the waybar config directory — resolved through the dotfiles symlink
# (so edits in the repo trigger it) — recursively with inotifywait, and on
# any save of config.jsonc or a *.sh script sends waybar SIGUSR2, which
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
#
# We watch close_write AND moved_to/create because most editors (vim, VS Code,
# …) save atomically — write to a temp file, then rename over the target —
# which fires moved_to/create on the destination, never close_write. Watching
# only close_write (the old behaviour) silently missed config.jsonc reloads
# while style.css kept working via waybar's own reload_style_on_change.
inotifywait -q -r -m -e close_write,moved_to,create --format '%w%f' "$DIR" 2>/dev/null \
  | while read -r file; do
      case "$file" in
        *.jsonc|*.sh) pkill -USR2 -x waybar 2>/dev/null ;;
      esac
    done