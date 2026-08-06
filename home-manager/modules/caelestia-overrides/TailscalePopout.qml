pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services
import qs.utils

// WF-13 — the tailscale hover popout. Opens on hover over the bar's tailscale
// status icon (Config.bar.popouts.statusIcons; the bar's checkPopout sets
// popouts.currentName = "tailscale"). Shows tailnet, account, current exit
// node, the peer list, an exit-node picker (selecting a row calls
// `tailscale set --exit-node`), and a profile-switch / toggle row.
//
// Colour roles (all from the vendored scheme.json — valid in any scheme, so
// this slice does not gate on WF-12): labels m3primary, values m3onSurface,
// online peers m3success, offline m3outline, selected exit-node row
// m3secondary. See docs/wayfinder/tickets/tailscale-custom-module.md.

ColumnLayout {
    id: root

    width: 300
    spacing: Tokens.spacing.small

    // Header: brand mark tinted by state + up/down indicator.
    RowLayout {
        Layout.topMargin: Tokens.padding.medium
        Layout.leftMargin: Tokens.padding.extraSmall
        Layout.rightMargin: Tokens.padding.extraSmall
        spacing: Tokens.spacing.small

        ColouredIcon {
            implicitSize: Math.round(Tokens.font.body.large.pointSize * 1.1)
            source: Quickshell.shellPath("assets/tailscale.svg")
            colour: Tailscale.up ? Colours.palette.m3success : Colours.palette.m3outline
        }

        StyledText {
            Layout.fillWidth: true
            text: qsTr("Tailscale")
            font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
            color: Colours.palette.m3onSurface
        }

        StyledText {
            text: Tailscale.up ? qsTr("Up") : qsTr("Down")
            color: Tailscale.up ? Colours.palette.m3success : Colours.palette.m3outline
            font: Tokens.font.body.small
        }
    }

    // Info rows: Tailnet / Account / Exit node — label m3primary, value
    // m3onSurface (the schema's flat fields; empty shows an em dash).
    Repeater {
        model: [
            { label: qsTr("Tailnet"), value: Tailscale.tailnet },
            { label: qsTr("Account"), value: Tailscale.loginName },
            { label: qsTr("Exit node"), value: Tailscale.exitNode ? Tailscale.exitNode : qsTr("none") }
        ]

        RowLayout {
            required property var modelData

            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.extraSmall
            Layout.rightMargin: Tokens.padding.extraSmall
            spacing: Tokens.spacing.small

            StyledText {
                text: modelData.label
                color: Colours.palette.m3primary
                font: Tokens.font.body.small
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                text: modelData.value ? modelData.value : qsTr("—")
                color: Colours.palette.m3onSurface
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }
        }
    }

    // Exit-node picker.
    StyledText {
        Layout.topMargin: Tokens.spacing.small
        Layout.leftMargin: Tokens.padding.extraSmall
        Layout.rightMargin: Tokens.padding.extraSmall
        text: qsTr("Exit node")
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.small
    }

    // The exit-node picker. "None" (disable) is the first row, followed by the
    // peers advertising ExitNodeOption. ExitNodeRow is the Repeater delegate,
    // so it takes `modelData` (ComponentBehavior: Bound requires the delegate
    // declare it as a required property — see Network.qml's wifi Repeater).
    Repeater {
        model: [ { name: qsTr("None"), fqdn: "none" }, ...Tailscale.exitNodes ]

        ExitNodeRow {
            Layout.fillWidth: true
        }
    }

    // Peers list.
    StyledText {
        Layout.topMargin: Tokens.spacing.small
        Layout.leftMargin: Tokens.padding.extraSmall
        Layout.rightMargin: Tokens.padding.extraSmall
        text: qsTr("Peers")
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.small
    }

    Repeater {
        model: Tailscale.peers

        RowLayout {
            required property var modelData

            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.extraSmall
            Layout.rightMargin: Tokens.padding.extraSmall
            spacing: Tokens.spacing.small

            Rectangle {
                Layout.alignment: Qt.AlignVCenter

                implicitWidth: 8
                implicitHeight: 8
                radius: 4

                color: modelData.online ? Colours.palette.m3success : Colours.palette.m3outline
            }

            StyledText {
                Layout.fillWidth: true
                text: modelData.name
                color: modelData.online ? Colours.palette.m3success : Colours.palette.m3outline
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }

            StyledText {
                text: modelData.ip
                color: modelData.online ? Colours.palette.m3success : Colours.palette.m3outline
                font: Tokens.font.body.small
                horizontalAlignment: Text.AlignRight
            }
        }
    }

    // Actions: toggle up/down (mirrors left-click) + switch profile (mirrors
    // right-click), so the popout is usable without memorised clicks.
    IconTextButton {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.spacing.medium
        text: Tailscale.up ? qsTr("Disconnect") : qsTr("Connect")
        icon: Tailscale.up ? "vpn_key" : "vpn_key_off"

        onClicked: Tailscale.toggle()
    }

    IconTextButton {
        Layout.fillWidth: true
        text: qsTr("Switch profile")
        icon: "swap_horiz"

        onClicked: Tailscale.switchProfile()
    }

    // A full-width clickable row tinted m3secondary when selected (mirrors the
    // rescan/StyledRect + StateLayer pattern in modules/bar/popouts/
    // Network.qml). Selecting calls `tailscale set --exit-node <fqdn>` (or
    // clears it for the "None" row, whose fqdn is "none").
    component ExitNodeRow: StyledRect {
        id: row

        required property var modelData

        readonly property string name: modelData.name
        readonly property string fqdn: modelData.fqdn
        readonly property bool selected: modelData.fqdn === "none" ? Tailscale.exitNode === "" : modelData.name === Tailscale.exitNode

        Layout.fillWidth: true
        implicitHeight: pickerRow.implicitHeight + Tokens.padding.small

        radius: Tokens.rounding.full
        color: Qt.alpha(Colours.palette.m3secondary, row.selected ? 0.2 : 0)

        Behavior on color {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        StateLayer {
            color: Colours.palette.m3onSurface
            onClicked: Tailscale.setExitNode(row.fqdn)
        }

        RowLayout {
            id: pickerRow

            anchors.fill: parent
            anchors.leftMargin: Tokens.padding.small
            anchors.rightMargin: Tokens.padding.small
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: row.selected ? "check_circle" : "radio_button_unchecked"
                color: row.selected ? Colours.palette.m3secondary : Colours.palette.m3onSurfaceVariant
            }

            StyledText {
                Layout.fillWidth: true
                text: row.name
                color: row.selected ? Colours.palette.m3secondary : Colours.palette.m3onSurface
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }
        }
    }
}