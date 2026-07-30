#!/bin/sh
# Network throughput for the waybar `custom/netspeed` module.
#
# Sums RX/TX bytes across all "physical" interfaces (ethernet + wifi; the
# lo/docker/veth/virbr/tun/tap/wg virtuals are filtered out) from /proc/net/dev,
# then divides the delta since the previous run by the elapsed wall time. The
# previous reading is kept in a state file under $XDG_RUNTIME_DIR so each run
# is instant (no in-script sleep) and waybar's `interval` directly sets the
# cadence. First run (no state yet) emits zeros so the pill never flickers.
#
# Emits waybar JSON:
#   {"text":"↓<down> ↑<up>","tooltip":"↓ <down> B/s\n↑ <up> B/s","class":"net"}
# Rates are humanized to B/K/M (bytes per second).

STATE="${XDG_RUNTIME_DIR:-/tmp}/waybar-netspeed.state"

# Sum rx ($2) / tx ($10) bytes over physical interfaces. /proc/net/dev line 1
# is the header; interface name in $1 carries a trailing ':'.
read_bytes() {
  awk '
    NR > 2 {
      iface = $1; sub(/:/, "", iface)
      if (iface ~ /^(lo|docker|virbr|veth|br-|tun|tap|wg|ppp|bond)/) next
      rx += $2; tx += $10
    }
    END { print rx, tx }
  ' /proc/net/dev
}

human() {  # bytes-per-second -> B / K / M string
  b=$1
  if [ "$b" -ge 1048576 ]; then
    awk -v b="$b" 'BEGIN{printf "%.1fM", b/1048576}'
  elif [ "$b" -ge 1024 ]; then
    awk -v b="$b" 'BEGIN{printf "%.0fK", b/1024}'
  else
    printf '%sB' "$b"
  fi
}

set -- $(read_bytes)
cur_rx=$1; cur_tx=$2
now=$(date +%s)

down=0; up=0
if [ -f "$STATE" ]; then
  # State holds "prev_rx prev_tx prev_ts". Corrupt/empty -> treat as first run.
  read -r prev_rx prev_tx prev_ts < "$STATE" 2>/dev/null || true
  [ -n "${prev_ts:-}" ] || { prev_rx=$cur_rx; prev_tx=$cur_tx; prev_ts=$now; }
  dt=$(( now - prev_ts ))
  [ "$dt" -le 0 ] && dt=1
  [ "$cur_rx" -ge "$prev_rx" ] && down=$(( (cur_rx - prev_rx) / dt )) || down=0
  [ "$cur_tx" -ge "$prev_tx" ] && up=$(( (cur_tx - prev_tx) / dt )) || up=0
fi

printf '%s %s %s\n' "$cur_rx" "$cur_tx" "$now" > "$STATE"

text=$(printf '↓%s ↑%s' "$(human "$down")" "$(human "$up")")
tooltip=$(awk -v d="$down" -v u="$up" 'BEGIN{printf "↓ %d B/s\n↑ %d B/s", d, u}')

jq -cn --arg text "$text" --arg tooltip "$tooltip" \
  '{text:$text,tooltip:$tooltip,class:"net"}'