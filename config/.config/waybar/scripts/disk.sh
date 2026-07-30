#!/bin/sh
# Root filesystem usage for the waybar `custom/disk` module.
#
# Emits waybar JSON so the pill shows a compact percentage (the `format`
# string prefixes the "DISK" label, matching the CPU/MEM/GPU pills) and the
# tooltip shows the full used / total / free breakdown:
#   {"text":"6%","tooltip":"  Root   50G / 906G  (810G free)","class":"disk"}
# `df` resolves the mount holding `/`, so this works on a single partition,
# btrfs, or LVM alike. used/size/avail are 1K blocks; humanized to M/G.

# df --output values are 1K-blocks, so thresholds/divisors are in KiB
# (1 MiB = 1024 KiB, 1 GiB = 1048576 KiB).
human() {
  awk -v b="$1" 'BEGIN{
    if (b >= 1048576) printf "%.0fG", b / 1048576
    else if (b >= 1024) printf "%.0fM", b / 1024
    else printf "%.0fK", b
  }'
}

read -r pcent used size avail <<EOF
$(df --output=pcent,used,size,avail / 2>/dev/null | awk 'NR==2{print $1, $2, $3, $4}')
EOF

# df failed (e.g. weird root mount): show a stable placeholder, keep width.
[ -n "$pcent" ] || { pcent="?"; used=0; size=0; avail=0; }

tooltip=$(printf '  Root   %s / %s  (%s free)' \
  "$(human "$used")" "$(human "$size")" "$(human "$avail")")

jq -cn --arg text "$pcent" --arg tooltip "$tooltip" \
  '{text:$text,tooltip:$tooltip,class:"disk"}'