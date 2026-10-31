import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

Tile {
    GridLayout {
        width: parent.width
        columns: 3
        rowSpacing: Appearance.spacing.normal
        columnSpacing: Appearance.spacing.normal

        Repeater {
            model: [
                { label: "Wi-Fi", sub: Network.wifi?.name ?? (Network.wired ? "Ethernet" : Toggles.wifi ? "On" : "Off"), icon: Toggles.wifi ? "wifi" : "wifi_off", on: Toggles.wifi, enabled: true, act: () => Toggles.toggleWifi(), menu: () => Panels.dashboardPage = "network" },
                { label: "Bluetooth", sub: !Bt.available ? "Unavailable" : Bt.enabled ? "On" : "Off", icon: Bt.icon, on: Bt.enabled, enabled: Bt.available, act: () => Toggles.toggleBluetooth() },
                { label: "WARP", sub: Toggles.warpBusy ? "Connecting…" : Toggles.warp ? "Connected" : "Off", icon: Toggles.warp ? "vpn_lock" : "vpn_key_off", on: Toggles.warp, enabled: true, act: () => Toggles.toggleWarp() },
                { label: "Mute", sub: Audio.muted ? "Muted" : `${Math.round(Audio.volume * 100)}%`, icon: Audio.muted ? "volume_off" : "volume_up", on: Audio.muted, enabled: Audio.sink !== null, act: () => Audio.toggleMute() },
                { label: "Power", sub: Toggles.profileName, icon: Toggles.profileIcon, on: Toggles.profileName !== "Balanced", enabled: true, act: () => Toggles.cycleProfile() },
                { label: "Night light", sub: Toggles.nightLight ? "On" : "Off", icon: "nightlight", on: Toggles.nightLight, enabled: true, act: () => Toggles.nightLight = !Toggles.nightLight }
            ]

            Rectangle {
                id: toggle

                required property var modelData

                Layout.fillWidth: true
                implicitHeight: 70
                radius: Appearance.rounding.normal - 4
                color: modelData.on ? Colors.primaryContainer : Colors.surfaceContainerHighest
                opacity: modelData.enabled ? 1 : 0.45

                Behavior on color { CAnim { duration: Appearance.anim.fast } }

                ColumnLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.normal
                    spacing: 1

                    MaterialIcon {
                        icon: toggle.modelData.icon
                        fill: toggle.modelData.on ? 1 : 0
                        color: toggle.modelData.on ? Colors.textOnPrimaryContainer : Colors.textOnSurface
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: toggle.modelData.label
                        font.weight: Font.Medium
                        color: toggle.modelData.on ? Colors.textOnPrimaryContainer : Colors.textOnSurface
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: toggle.modelData.sub
                        font.pixelSize: Appearance.font.small - 1
                        color: toggle.modelData.on ? Colors.alpha(Colors.textOnPrimaryContainer, 0.75) : Colors.textOnSurfaceVariant
                        elide: Text.ElideRight
                    }
                }

                // Has a details page: right-click (or the ▸) opens it
                MaterialIcon {
                    visible: toggle.modelData.menu !== undefined
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 6
                    icon: "chevron_right"
                    size: 16
                    color: toggle.modelData.on ? Colors.textOnPrimaryContainer : Colors.textOnSurfaceVariant
                }

                StateLayer {
                    enabled: toggle.modelData.enabled
                    tint: toggle.modelData.on ? Colors.textOnPrimaryContainer : Colors.textOnSurface
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: event => {
                        if (event.button === Qt.RightButton && toggle.modelData.menu)
                            toggle.modelData.menu();
                        else if (event.button === Qt.LeftButton)
                            toggle.modelData.act();
                    }
                }
            }
        }
    }
}
