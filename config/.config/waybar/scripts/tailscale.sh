#!/usr/bin/env bash
# Tailscale waybar module — status pill, toggle, and exit-node picker.
#
# Inspired by federicovolponi/waybar-tailscale, adapted to this warm-metal
# bar: the tailscale logo as a CSS background-image (on/off PNG by class), plus
# a rich Pango-markup tooltip (tailnet, exit node, this node, and every peer
# colored online/offline). Left-click toggles up/down; right-click switches
# between the two accounts in PROFILES; middle-click opens a wofi menu to pick
# an exit node (or "None" to disable).
#
# Subcommands (the waybar module dispatches on $1):
#   --status              emit waybar JSON (polled by the module `interval`,
#                         and re-run instantly on clicks via exec-on-event)
#   --toggle              tailscale up / down
#   --switch-profile      switch to the other account in PROFILES (right-click)
#   --select-exit-node    wofi menu of peers advertising as exit nodes
#
# `tailscale status --json` is read-only and works as a non-root user; up/down
# and `tailscale set --exit-node` work without sudo because the user is the
# tailscale operator (set in nixos/modules/networking/vpn.nix).

# Warm-metal tooltip colors — mirror the @define-color values in style.css so
# the tooltip reads as part of the theme rather than generic green/red.
ONLINE="#b3bf80"    # @olive    — online peers
OFFLINE="#937c63"   # @overlay0 — offline / last-seen peers
SELF_C="#f0e6d2"    # @text     — this node
LABEL_C="#e8c272"   # @gold     — "Tailnet:" / "Exit node:" labels

MENU_CMD=(wofi --dmenu --prompt "Tailscale exit node")

# The two tailscale accounts right-click toggles between. `tailscale switch`
# flips the daemon to the named account (its login email). With two entries
# here, right-click always swaps to the other one; edit this list to change
# the set.
PROFILES=(
  manoj.manivannan.m@gmail.com
  ragamanoj@gmail.com
)

# Feedback via swaync (libnotify). Absent until libnotify is in the system
# packages — guard so the picker still works without it, just silently.
notify() { command -v notify-send >/dev/null && notify-send -a Tailscale "$1"; }

is_up() { tailscale status --json 2>/dev/null | jq -e '.BackendState == "Running"' >/dev/null; }

emit_status() {
  local status_json
  status_json=$(tailscale status --json 2>/dev/null)

  if [ -z "$status_json" ] || ! printf '%s' "$status_json" | jq -e '.BackendState' >/dev/null 2>&1; then
    jq -nc --arg icon "" '{text:$icon,class:"disconnected",tooltip:"Tailscale unavailable"}'
    return
  fi

printf '%s' "$status_json" | jq -c \
    --arg on "$ONLINE" --arg off "$OFFLINE" --arg selfc "$SELF_C" --arg lab "$LABEL_C" '
    ( .BackendState == "Running" and ((.Self // {}).Online // false) ) as $up
    | (if $up then
        ( (.Self.DNSName | sub("\\.$";"") | sub("^[^.]+\\.";"")) as $tailnet
        | ( .User[(.Self.UserID | tostring)].LoginName // "Unknown" ) as $loginname
        | ( [ .Peer[]? | select(.ExitNode == true) | (.DNSName | split(".")[0]) ] | .[0] // "" ) as $exit
        | ( .Self.DNSName | split(".")[0] ) as $selfname
        | ( .Self.TailscaleIPs[0] // "?" ) as $selfip
        | ( [ .Peer[]? ]
            | map( "<span color=\"" + (if .Online then $on else $off end) + "\">"
                   + (.DNSName | split(".")[0]) + "  (" + (.TailscaleIPs[0] // "-") + ")</span>" )
            | join("\n") ) as $peers
        | ( "<span color=\"" + $lab + "\"><b>Tailnet:</b></span> " + $tailnet + "\n"
            + "<span color=\"" + $lab + "\"><b>Account:</b></span> " + $loginname + "\n"
            + "<span color=\"" + $lab + "\"><b>Exit node:</b></span> " + (if $exit == "" then "none" else $exit end) + "\n\n"
            + "<span color=\"" + $selfc + "\"><b>" + $selfname + "</b>  (" + $selfip + ")</span>\n"
            + $peers ) )
      else "Disconnected — tailscale is down" end) as $tip
    | { text: (if $up then "" else "" end),
        class: (if $up then "connected" else "disconnected" end),
        tooltip: $tip }'
}

toggle() {
  if is_up; then tailscale down >/dev/null 2>&1
  else            tailscale up   >/dev/null 2>&1; fi
}

switch_profile() {
  # Current account = the login behind this node's owning user. `.User` maps
  # stringified user IDs to profiles; `.Self.UserID` is this node's owner.
  local current target
  current=$(tailscale status --json 2>/dev/null \
    | jq -r '.User[((.Self // {}).UserID // -1)|tostring].LoginName // empty')

  # Pick the first profile that isn't the current account. With two profiles
  # that's the other one; if current is unknown/empty (e.g. logged out), it
  # falls back to the first entry, which is still a valid switch target.
  target=""
  for p in "${PROFILES[@]}"; do
    if [[ "$p" != "$current" ]]; then target="$p"; break; fi
  done
  [ -z "$target" ] && target="${PROFILES[0]}"

  if tailscale switch "$target" >/dev/null 2>&1; then
    notify "Tailscale switched to: $target"
  else
    notify "Tailscale switch to $target failed"
  fi
}

select_exit_node() {
  if ! is_up; then notify "VPN is not running"; return 1; fi

  local nodes selected
  # Peers advertising as exit nodes (ExitNodeOption == true), fully-qualified
  # DNSName as `tailscale set --exit-node` expects, plus a disable option.
  nodes=$(tailscale status --json 2>/dev/null \
    | jq -r '.Peer[]? | select(.ExitNodeOption == true) | (.DNSName | sub("\\.$";""))')
  nodes="None (disable exit node)"$'\n'"$nodes"

  selected=$(printf '%s\n' "$nodes" | "${MENU_CMD[@]}")
  [ -z "$selected" ] && return 0   # user cancelled (Esc)

  if [[ "$selected" == "None"* ]]; then
    tailscale set --exit-node= >/dev/null 2>&1
    notify "Exit node disabled"
  else
    tailscale set --exit-node="$selected" >/dev/null 2>&1
    notify "Exit node set to: $selected"
  fi
}

case "${1:-}" in
  --status)            emit_status ;;
  --toggle)            toggle ;;
  --select-exit-node)  select_exit_node ;;
  --switch-profile)    switch_profile ;;
  *) echo "usage: tailscale.sh --status|--toggle|--switch-profile|--select-exit-node" >&2; exit 2 ;;
esac