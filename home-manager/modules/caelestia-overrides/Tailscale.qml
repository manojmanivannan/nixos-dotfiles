pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

// WF-13 — the one ported custom module. Tailscale logic stays in the shell
// script (config/.config/caelestia/scripts/tailscale.sh — no JS
// reimplementation, standing decision #6); this singleton only shells out to
// it via Quickshell's Process API and exposes the structured-JSON --status
// fields to the bar icon (home-manager/modules/caelestia-overrides patches
// StatusIcons.qml) and the hover popout (TailscalePopout.qml).
//
// Schema from `tailscale.sh --status`:
//   { up, loginName, tailnet, exitNode, exitNodes[], peers[] }
//   exitNodes[]: { name, fqdn }   — peers advertising ExitNodeOption
//   peers[]:     { name, ip, online }
// See docs/wayfinder/tickets/tailscale-custom-module.md.

Singleton {
    id: root

    property bool up: false
    property string loginName: ""
    property string tailnet: ""
    property string exitNode: ""
    property var exitNodes: []
    property var peers: []

    // True while an action Process is running — suppresses re-entry and lets
    // the popout show a busy state (the action refreshes status on exit).
    property bool busy: false

    // tailscale.sh ships as a single-file symlink at
    // ~/.config/caelestia/scripts/tailscale.sh (dotfiles-symlinks.nix);
    // Paths.config = ~/.config/caelestia. Invoked via bash so the out-of-store
    // symlink need not carry the executable bit.
    readonly property string script: `${Paths.config}/scripts/tailscale.sh`

    function refresh(): void {
        statusProc.exec(["bash", root.script, "--status"])
    }

    function toggle(): void {
        if (root.busy)
            return
        actionProc.exec(["bash", root.script, "--toggle"])
    }

    function switchProfile(): void {
        if (root.busy)
            return
        actionProc.exec(["bash", root.script, "--switch-profile"])
    }

    // fqdn = the fully-qualified DNSName `tailscale set --exit-node` expects,
    // or "none"/empty to clear (the popout's "None" row).
    function setExitNode(fqdn: string): void {
        if (root.busy)
            return
        actionProc.exec(["bash", root.script, "--set-exit-node", fqdn])
    }

    function applyStatus(text: string): void {
        const trimmed = (text ?? "").trim()

        if (!trimmed) {
            root.reset()
            return
        }

        try {
            const d = JSON.parse(trimmed)
            root.up = d.up ?? false
            root.loginName = d.loginName ?? ""
            root.tailnet = d.tailnet ?? ""
            root.exitNode = d.exitNode ?? ""
            root.exitNodes = d.exitNodes ?? []
            root.peers = d.peers ?? []
        } catch (e) {
            root.reset()
        }
    }

    function reset(): void {
        root.up = false
        root.loginName = ""
        root.tailnet = ""
        root.exitNode = ""
        root.exitNodes = []
        root.peers = []
    }

    Component.onCompleted: root.refresh()

    // One-shot status poll. The script emits one JSON object then exits; the
    // full stdout is parsed on stream finish (matches the VPN service's
    // statusProc pattern in services/VPN.qml).
    Process {
        id: statusProc

        stdout: StdioCollector {
            onStreamFinished: root.applyStatus(text)
        }
        stderr: StdioCollector {}
    }

    // Toggle / switch-profile / set-exit-node. Refresh status on exit so the
    // icon + popout reflect the new state without waiting for the next poll.
    Process {
        id: actionProc

        running: false

        onRunningChanged: root.busy = running
        onExited: exitCode => root.refresh() // qmllint disable signal-handler-parameters
        stdout: StdioCollector {}
        stderr: StdioCollector {}
    }

    // Poll cadence: `tailscale status --json` is cheap, 10s keeps the icon +
    // peer list fresh without thrashing. The initial read is done in
    // Component.onCompleted; the timer starts polling after.
    Timer {
        interval: 10000
        repeat: true
        running: true

        onTriggered: root.refresh()
    }
}