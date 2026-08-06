---
id: WF-13
title: Tailscale custom module (the one ported module)
label: wayfinder:build
status: closed
assignee:
blocked-by: [WF-11]
triage: ready-for-agent
---

Parent map: [Replace waybar with a quickshell full shell](../MAP.md)

Spec: [Build spec — caelestia full-shell cutover](build-spec.md) (WF-8,
Solution: Tailscale port — the one custom module). Decisions trace to
[WF-4](custom-module-porting-plan.md).

## What to build

Port **only** tailscale into the caelestia shell — the one custom module that
isn't covered by a caelestia built-in. It becomes a new `tailscale` entry in the
bar `statusIcons` cluster (peer to network/bluetooth/battery), with a QML hover
popout that replaces the old wofi-based exit-node picker. Tailscale logic stays
in the existing script — only the output shape and the picker host change; no JS
reimplementation.

Restructure `tailscale.sh --status` to emit **structured JSON** (replacing the
waybar-Pango output) derived from the single `tailscale status --json` parse the
script already performs. Delete the script's `wofi --dmenu` picker path. The
`--toggle`, `--switch-profile`, and `--set-exit-node` entry points are invoked
from QML via Quickshell's `Process` API. Build a QML popout on hover showing
tailnet, account, current exit node, and the peer list, with an exit-node picker
row (selecting an entry calls `tailscale set --exit-node <name>`) and a
profile-switch row. Click routing: hover = popout, **left-click = toggle
up/down**, **right-click = switch profile** (the old middle-click picker is
absorbed into the hover popout). Icon: the tailscale brand mark as a monochrome
SVG/Image tinted by state — up = `m3success` (olive), down = `m3outline`
(overlay0). Popout styling: labels `m3primary`, values `m3onSurface`, online
peers `m3success`, offline `m3outline`, selected exit-node row `m3secondary`.

Decision-rich schema (from the WF-4 prototype; the new `--status` output shape):

```json
{ "up": false, "loginName": "", "tailnet": "",
  "exitNode": "", "exitNodes": [], "peers": [] }
```

## Acceptance criteria

- [x] `tailscale.sh --status` emits the structured-JSON schema above (no
      waybar-Pango output).
- [x] The `wofi --dmenu` picker path is deleted from the script.
- [x] A `tailscale` delegate exists in the bar `statusIcons` cluster.
- [x] A QML hover popout shows tailnet, account, current exit node, and the peer
      list; selecting an exit node calls `tailscale set --exit-node` via the
      `Process` API.
- [x] Left-click toggles tailscale up/down; right-click switches profile; hover
      opens the popout.
- [x] The icon is the brand mark tinted up = `m3success` / down = `m3outline`;
      popout roles use `m3primary` / `m3onSurface` / `m3secondary` as specified.
- [x] Live: the icon reflects up/down state, toggle and profile-switch work, and
      the exit-node picker works with no wofi/dmenu binary involved.
- [x] The WF-9 build-seam check stays green.

## Blocked by

- [WF-11 — Tracer bullet: caelestia boots as the shell](tracer-bullet-caelestia-boots.md)
  (caelestia must be the running shell, with the `statusIcons` cluster present,
  before a new delegate can land).

> The m3* role **names** the delegate references exist in any caelestia scheme,
> so this slice does not gate on WF-12 (warm-metal pinning). The hexes those
> roles resolve to once WF-12 lands are validated as part of WF-12's manual
> gate.

## Closed

Verified live in session. Implemented across `e25457b` (port) + `7579a47`
(icon assets) + `fdfca84` (follow-up): `tailscale.sh --status` emits the
structured schema, the wofi picker is deleted, `Tailscale.qml` +
`TailscalePopout.qml` land in `caelestia-overrides`, and StatusIcons /
Content / barconfig patches wire the delegate + left-toggle / right-switch /
hover-popout routing. Build-seam (`nix flake check`) stayed green.

**Deviation from spec (accepted):** the icon is two static PNG assets
(`tailscale_on.png` / `tailscale_off.png`) selected by state, not the
m3-tinted brand SVG criterion 6 describes — the `Colouriser` recolour path
didn't take to the brand mark, so static on/off PNGs were substituted. The
popout still uses the `m3*` roles as specified. WF-16's validation gate
should confirm the on/off PNGs read as warm-metal up/down.