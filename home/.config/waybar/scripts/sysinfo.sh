#!/bin/sh
# Fixed-width system metrics for waybar.
#
# Every value is padded to a constant field width (printf %3d) so the bar
# never shifts as digit counts change (9 -> 10 -> 100). The label, icons and
# unit suffixes live in waybar's `format` strings; this script only emits the
# (padded) number; `cputemp` wraps the value in a red Pango span when hot.
#
#   sysinfo.sh cpu      3-char CPU utilization, 1s average (0..100)
#   sysinfo.sh cputemp  k10temp Tctl, red Pango span at >=80C
#   sysinfo.sh mem      3-char RAM utilization (0..100)
#   sysinfo.sh gpu      3-char NVIDIA GPU utilization (0..100)
#   sysinfo.sh gputemp  3-char NVIDIA GPU temperature in °C

case "$1" in
  cpu)
    read_total() { awk '/^cpu /{s=0; for (i=2;i<=NF;i++) s+=$i; print s}' /proc/stat; }
    read_idle()  { awk '/^cpu /{print $5}' /proc/stat; }
    t0=$(read_total); i0=$(read_idle)
    sleep 1
    t1=$(read_total); i1=$(read_idle)
    dt=$((t1 - t0)); di=$((i1 - i0))
    [ "$dt" -gt 0 ] || dt=1
    u=$((100 * (dt - di) / dt))
    [ "$u" -lt 0 ] && u=0
    [ "$u" -gt 100 ] && u=100
    printf '%3d' "$u"
    ;;
  cputemp)
    # Locate k10temp by name — hwmon indices shift across reboots, so a
    # hardcoded hwmon-path would silently break.
    raw=$(for h in /sys/class/hwmon/hwmon*; do
            [ "$(cat "$h/name" 2>/dev/null)" = k10temp ] && cat "$h/temp1_input" 2>/dev/null
          done | head -n1)
    [ -n "$raw" ] || raw=0
    t=$((raw / 1000))
    # Pango span turns the number red at >=80°C (the °C suffix lives in
    # waybar's format string and keeps the module's CSS color). Below 80°C
    # emit plain text so the usual CSS color applies.
    if [ "$t" -ge 80 ]; then
      printf '<span color="#ed8796">%3d</span>' "$t"
    else
      printf '%3d' "$t"
    fi
    ;;
  mem)
    awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{u=100*(t-a)/t; if(u<0)u=0; printf "%3d",u}' /proc/meminfo
    ;;
  gpu)
    nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null \
      | awk '{printf "%3d", $1}'
    ;;
  gputemp)
    nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null \
      | awk '{printf "%3d", $1}'
    ;;
esac