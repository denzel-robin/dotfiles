import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

// List of pending updates, beside the updates island.
Overlay {
    id: root

    name: "updates"
    dim: false

    readonly property real maxListHeight: height * 0.6

    Card {
        id: card

        anchors.left: parent.left
        anchors.leftMargin: Appearance.bar.margin * 2 + Appearance.bar.islandWidth
        y: Math.max(Appearance.bar.margin, (Panels.updatesBottom || parent.height / 2) - height)
        width: 400
        height: layout.implicitHeight + Appearance.padding.normal * 2
        radius: Appearance.rounding.normal
        clip: true
        opacity: root.progress
        scale: 0.94 + 0.06 * root.progress
        transformOrigin: Item.BottomLeft
        transform: Translate { x: (root.progress - 1) * 30 }

        Behavior on height { Anim { duration: Appearance.anim.fast; easing.bezierCurve: Appearance.anim.emphasized } }

        ColumnLayout {
            id: layout

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Appearance.padding.normal
            spacing: Appearance.spacing.normal

            // Header
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Appearance.padding.small
                spacing: Appearance.spacing.normal

                StyledText {
                    text: "Updates"
                    font.pixelSize: Appearance.font.large
                    font.weight: Font.Medium
                }

                Rectangle {
                    visible: Updates.count > 0
                    implicitWidth: Math.max(22, countText.implicitWidth + 12)
                    implicitHeight: 22
                    radius: 11
                    color: Colors.primary

                    StyledText {
                        id: countText
                        anchors.centerIn: parent
                        text: Updates.count
                        font.pixelSize: Appearance.font.small
                        font.weight: Font.DemiBold
                        color: Colors.textOnPrimary
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: Updates.aurCount > 0
                    text: `${Updates.count - Updates.aurCount} repo · ${Updates.aurCount} AUR`
                    font.pixelSize: Appearance.font.small
                    color: Colors.textOnSurfaceVariant
                }

                Item { Layout.fillWidth: !(Updates.aurCount > 0) }

                // Re-check
                Rectangle {
                    implicitWidth: 32
                    implicitHeight: 32
                    radius: 16
                    color: "transparent"

                    MaterialIcon {
                        id: refresh
                        anchors.centerIn: parent
                        icon: "refresh"
                        color: Colors.textOnSurfaceVariant

                        RotationAnimation on rotation {
                            running: Updates.checking
                            from: 0
                            to: 360
                            duration: 900
                            loops: Animation.Infinite
                            onStopped: refresh.rotation = 0
                        }
                    }

                    StateLayer {
                        onClicked: Updates.check()
                    }
                }
            }

            // Restart note
            Rectangle {
                visible: Updates.restart !== ""
                Layout.fillWidth: true
                implicitHeight: note.implicitHeight + Appearance.padding.normal * 2
                radius: Appearance.rounding.small
                color: Colors.tertiaryContainer

                RowLayout {
                    id: note
                    anchors.fill: parent
                    anchors.margins: Appearance.padding.normal
                    spacing: Appearance.spacing.normal

                    MaterialIcon {
                        icon: Updates.restart === "reboot" ? "restart_alt" : "logout"
                        size: 18
                        color: Colors.textOnTertiaryContainer
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: Updates.restart === "reboot" ? "Includes kernel/driver updates — reboot afterwards" : "Includes Hyprland/shell updates — log out and back in afterwards"
                        font.pixelSize: Appearance.font.small
                        color: Colors.textOnTertiaryContainer
                        wrapMode: Text.Wrap
                    }
                }
            }

            // Packages
            Flickable {
                id: list

                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(rows.implicitHeight, root.maxListHeight)
                clip: true
                contentHeight: rows.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: rows

                    width: list.width

                    Repeater {
                        model: Updates.packages

                        Item {
                            id: pkg

                            required property var modelData

                            width: rows.width
                            implicitHeight: 36

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Appearance.padding.small
                                anchors.rightMargin: Appearance.padding.small
                                spacing: Appearance.spacing.normal

                                StyledText {
                                    Layout.fillWidth: true
                                    text: pkg.modelData.name
                                    font.weight: pkg.modelData.restart ? Font.DemiBold : Font.Normal
                                    color: pkg.modelData.restart ? Colors.tertiary : Colors.textOnSurface
                                    elide: Text.ElideRight
                                }

                                Rectangle {
                                    visible: pkg.modelData.aur
                                    implicitWidth: aurLabel.implicitWidth + 10
                                    implicitHeight: 18
                                    radius: 9
                                    color: Colors.secondaryContainer

                                    StyledText {
                                        id: aurLabel
                                        anchors.centerIn: parent
                                        text: "AUR"
                                        font.pixelSize: 9
                                        font.weight: Font.DemiBold
                                        color: Colors.textOnSecondaryContainer
                                    }
                                }

                                StyledText {
                                    Layout.maximumWidth: 190
                                    text: `${pkg.modelData.from} → ${pkg.modelData.to}`
                                    font.family: Appearance.font.mono
                                    font.pixelSize: Appearance.font.small - 1
                                    color: Colors.textOnSurfaceVariant
                                    elide: Text.ElideLeft
                                }
                            }
                        }
                    }
                }
            }

            // Up to date
            RowLayout {
                visible: Updates.count === 0
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Appearance.spacing.small
                Layout.bottomMargin: Appearance.spacing.small
                spacing: Appearance.spacing.normal

                MaterialIcon {
                    icon: "check_circle"
                    size: 22
                    color: Colors.primary
                }

                StyledText {
                    text: Updates.everChecked ? `Up to date · checked ${Qt.formatTime(Updates.lastChecked, "hh:mm")}` : "Not checked yet"
                    color: Colors.textOnSurfaceVariant
                }
            }

            // Update now
            Rectangle {
                visible: Updates.count > 0
                Layout.fillWidth: true
                implicitHeight: 40
                radius: Appearance.rounding.full
                color: Colors.primary

                Row {
                    anchors.centerIn: parent
                    spacing: Appearance.spacing.small

                    MaterialIcon {
                        icon: "download"
                        size: 18
                        fill: 1
                        color: Colors.textOnPrimary
                    }

                    StyledText {
                        text: Updates.updating ? "Updating…" : "Update now"
                        font.weight: Font.Medium
                        color: Colors.textOnPrimary
                    }
                }

                StateLayer {
                    tint: Colors.textOnPrimary
                    onClicked: {
                        Panels.close();
                        Updates.update();
                    }
                }
            }

            StyledText {
                visible: Updates.everChecked && Updates.count > 0
                Layout.alignment: Qt.AlignHCenter
                text: `Checked ${Qt.formatTime(Updates.lastChecked, "hh:mm")} · checks hourly`
                font.pixelSize: Appearance.font.small - 1
                color: Colors.outline
            }
        }
    }
}
