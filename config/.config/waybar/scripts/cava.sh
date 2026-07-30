#!/usr/bin/env bash
# Cava audio visualizer for the waybar `custom/cava` module.
#
# Streams a compact spectrum of Nerd Font block characters, one frame per
# stdout line, so waybar (which reads a long-running exec continuously, like
# the swaync bell module) refreshes the pill ~30x/s. Uses cava's `raw` output
# in ascii mode: each bar is an integer 0..100, bars separated by ';', frames
# by newline. Each value maps to one of the eight U+2581..U+2588 blocks.
#
# A per-run temp config (mktemp) is passed via `cava -p` so the user's
# ~/.config/cava/config is never touched. When audio is silent every bar is 0
# and we emit class "silent" with empty text; style.css collapses the pill
# (mirrors mpris.empty) so the bar stays clean when nothing plays.
#
# An outer loop restarts cava if it exits (no audio server yet, transient
# crash) so the visualizer self-heals instead of dying with the module.

blocks=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █)

conf=$(mktemp)
trap 'rm -f "$conf"' EXIT
cat > "$conf" <<EOF
[general]
bars = 10
framerate = 30
[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 100
bar_delimiter = 59
frame_delimiter = 10
EOF

while :; do
  # Each stdout line is one frame: "v0;v1;...;v9;" (trailing ';' -> empty token).
  cava -p "$conf" 2>/dev/null | while IFS= read -r frame; do
      text=""; silent=1
      IFS=';' read -ra vals <<<"$frame"
      for tok in "${vals[@]}"; do
        [[ "$tok" =~ ^[0-9]+$ ]] || continue
        (( tok > 0 )) && silent=0
        i=$(( tok * 8 / 101 ))   # 0..7
        (( i > 7 )) && i=7
        text+="${blocks[i]}"
      done
      if (( silent )); then
        printf '{"text":"","class":"silent"}\n'
      else
        printf '{"text":"%s"}\n' "$text"
      fi
    done
  sleep 1
done