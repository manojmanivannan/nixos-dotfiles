#!/usr/bin/env bash
# Tailscale shell module for caelestia (WF-13 — the one ported custom module).
#
# The waybar module lived at config/.config/waybar/scripts/tailscale.sh and
# emitted waybar-Pango JSON with a wofi --dmenu exit-node picker. Caelestia has
# no tailscale built-in, so the script is ported rather than dropped: tailscale
# logic stays here (no JS reimplementation — standing decision #6), only the
# output shape changes. `--status` now emits the structured-JSON schema the QML
# hover popout binds to, and the exit-node picker moved into the shell as a QML
# popout (no wofi, no dmenu binary). The QML invokes the entry points below via
# Quickshell's Process API (see home-manager/modules/caelestia-overrides/
# Tailscale.qml + TailscalePopout.qml).
#
# Subcommands (the QML service dispatches on $1):
#   --status              emit the structured-JSON schema (polled by the service)
#   --toggle              tailscale up / down (left-click on the bar icon)
#   --switch-profile      switch to the other account in PROFILES (right-click)
#   --set-exit-node NAME  `tailscale set --exit-node NAME`; "none"/empty clears
#                         (selecting a row in the QML exit-node picker)
#
# `tailscale status --json` is read-only and works as a non-root user; up/down
# and `tailscale set --exit-node` work without sudo because the user is the
# tailscale operator (set in nixos/modules/networking/vpn.nix).

# The two tailscale accounts right-click toggles between. `tailscale switch`
# flips the daemon to the named account (its login email). With two entries
# here, right-click always swaps to the other one; edit this list to change
# the set.
PROFILES=(
  manoj.manivannan.m@gmail.com
  ragamanoj@gmail.com
)

# Feedback via libnotify. Absent until libnotify is in the system packages —
# guard so the actions still work without it, just silently. (WF-12 risk #6
# tracks whether any remaining surface still calls notify-send; this guard
# means dropping libnotify won't break the module.)
notify() { command -v notify-send >/dev/null && notify-send -a Tailscale "$1"; }

is_up() { tailscale status --json 2>/dev/null | jq -e '.BackendState == "Running"' >/dev/null; }

# Structured-JSON --status — the schema the QML popout binds to:
#   { up, loginName, tailnet, exitNode, exitNodes[], peers[] }
#   exitNodes[]: { name, fqdn } — peers advertising ExitNodeOption (picker rows)
#   peers[]:     { name, fqdn, ip, online } — every peer (the peer list); fqdn
#                is the peer's full MagicDNS name, copied to the clipboard on
#                click in the QML popout (machine name + tailnet)
# Derived from the single `tailscale status --json` parse (same source the
# waybar version used); the warm-metal colouring moved to QML (Colours roles),
# so no Pango/tooltip colours are emitted here.
emit_status() {
  local status_json
  status_json=$(tailscale status --json 2>/dev/null)

  if [ -z "$status_json" ] || ! printf '%s' "$status_json" | jq -e '.BackendState' >/dev/null 2>&1; then
    # Tailscale unavailable (not installed / daemon down / logged out): emit
    # the empty schema so the QML shows a clean "down" state, not an error.
    jq -nc '{up:false,loginName:"",tailnet:"",exitNode:"",exitNodes:[],peers:[]}'
    return
  fi

  printf '%s' "$status_json" | jq -c '
    ( .BackendState == "Running" and ((.Self // {}).Online // false) ) as $up
    | ( .User[ (((.Self // {}).UserID // -1)|tostring) ].LoginName // "" ) as $loginName
    | ( ((.Self // {}).DNSName // "") | sub("\\.$";"") | sub("^[^.]+\\.";"") ) as $tailnet
    | ( [ .Peer[]? | select(.ExitNode == true) | (.DNSName | split(".")[0]) ] | .[0] // "" ) as $exitNode
    | ( [ .Peer[]? | select(.ExitNodeOption == true)
          | { name: (.DNSName | split(".")[0]), fqdn: (.DNSName | sub("\\.$";"")) } ] ) as $exitNodes
    | ( [ .Peer[]?
          | { name: (.DNSName | split(".")[0]),
              fqdn: (.DNSName | sub("\\.$";"")),
              ip: ((.TailscaleIPs // [])[0] // ""),
              online: (.Online // false) } ] ) as $peers
    | { up: $up, loginName: $loginName, tailnet: $tailnet,
        exitNode: $exitNode, exitNodes: $exitNodes, peers: $peers }'
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

# Set (or clear) the exit node. The QML picker passes the fully-qualified
# DNSName `tailscale set --exit-node` expects, or "none"/empty to disable.
set_exit_node() {
  local node="${1:-}"
  if [[ -z "$node" || "$node" == "none" ]]; then
    tailscale set --exit-node= >/dev/null 2>&1
    notify "Exit node disabled"
  else
    tailscale set --exit-node="$node" >/dev/null 2>&1
    notify "Exit node set to: $node"
  fi
}

case "${1:-}" in
  --status)           emit_status ;;
  --toggle)           toggle ;;
  --switch-profile)   switch_profile ;;
  --set-exit-node)    shift; set_exit_node "${1:-}" ;;
  *) echo "usage: tailscale.sh --status|--toggle|--switch-profile|--set-exit-node [node]" >&2; exit 2 ;;
esac