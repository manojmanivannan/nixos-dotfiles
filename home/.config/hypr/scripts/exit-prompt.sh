#!/bin/sh
# Confirm before ending the Hyprland session.
#
# `uwsm stop` triggers an orderly systemd teardown of the wayland-session
# units (and activation-env cleanup). To avoid yanking the compositor out
# from under clients, we gate it behind a wofi --dmenu prompt: only the
# "Exit" choice runs `uwsm stop`; Cancel or Esc (empty selection) is a no-op.
#
# Invoked from bindings.lua via `hl.dsp.exec_cmd` (SUPER+M). exec_cmd runs
# its argument through /bin/sh, but keeping the shell logic in a script
# avoids quoting/long-bracket fragility in the Lua config.

# wofi flags:
#   --dmenu            read choices from stdin
#   --columns 2        two entries side by side -> the "Exit" / "Cancel" buttons
#   --lines 1          one row, so both buttons fit on a single line
#   --hide-scroll      only two entries, no scrollbar needed
#   --cache-file=/dev/null  don't persist the last selection (deterministic)
#   --location 0       rofi-style location: 0 = center (NOT numpad; 5 = bottom_right)
#   --width 520        compact fixed width so the dialog stays small
#   --style            dedicated exit-style.css: same Gruvbox/orange theme as
#                      the main wofi, but with padded entries (taller buttons)
#                      and margins so they clear the 5px window border. The
#                      main ~/.config/wofi/style.css (used by SUPER+SPACE) is
#                      left untouched. No --height: the entry padding drives
#                      the height, which avoids the buttons overlapping the
#                      border that a fixed --height caused.
# Note: per wofi(7), applying any x/y offset with `center` forces top_left,
# so no --xoffset/--yoffset here.
choice="$(printf 'Exit\nCancel\n' | wofi --dmenu --prompt 'End Hyprland session?' \
    --columns 2 --lines 1 --hide-scroll --cache-file=/dev/null \
    --location 0 --width 520 \
    --style $HOME/.config/wofi/exit-style.css)"

[ "$choice" = "Exit" ] && uwsm stop