import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

// Notification history: a menu beside the bell island that grows with its contents.
Overlay {
    id: root

    name: "notifications"
    dim: false

    readonly property real maxListHeight: height * 0.75

    Card {
        id: card

        anchors.left: parent.left
        anchors.leftMargin: Appearance.bar.margin * 2 + Appearance.bar.islandWidth
        y: Math.max(Appearance.bar.margin, (Panels.bellBottom || parent.height - Appearance.bar.margin) - height)
        width: 380
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

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Appearance.padding.small
                spacing: Appearance.spacing.normal

                StyledText {
                    text: "Notifications"
                    font.pixelSize: Appearance.font.large
                    font.weight: Font.Medium
                }

                // Count
                Rectangle {
                    visible: Notifs.history.length > 0
                    implicitWidth: Math.max(22, count.implicitWidth + 12)
                    implicitHeight: 22
                    radius: 11
                    color: Colors.primary

                    StyledText {
                        id: count
                        anchors.centerIn: parent
                        text: Notifs.history.length
                        font.pixelSize: Appearance.font.small
                        font.weight: Font.DemiBold
                        color: Colors.textOnPrimary
                    }
                }

                Item { Layout.fillWidth: true }

                // Clear all
                Rectangle {
                    visible: Notifs.history.length > 0
                    implicitWidth: 32
                    implicitHeight: 32
                    radius: 16
                    color: "transparent"

                    MaterialIcon {
                        anchors.centerIn: parent
                        icon: "clear_all"
                        color: Colors.textOnSurfaceVariant
                    }

                    StateLayer {
                        onClicked: Notifs.clearAll()
                    }
                }
            }

            // Notifications; scrolls once taller than most of the screen
            Flickable {
                id: list

                readonly property int count: Notifs.history.length

                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(stack.implicitHeight, root.maxListHeight)
                clip: true
                contentHeight: stack.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: stack

                    width: list.width
                    spacing: Appearance.spacing.small

                    Repeater {
                        model: Notifs.history

                        NotificationCard {
                            required property var modelData
                            notif: modelData
                            width: stack.width
                        }
                    }
                }
            }

            // Empty state
            RowLayout {
                visible: list.count === 0
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Appearance.spacing.small
                Layout.bottomMargin: Appearance.spacing.normal
                spacing: Appearance.spacing.normal

                MaterialIcon {
                    icon: "notifications_paused"
                    size: 22
                    color: Colors.outline
                }

                StyledText {
                    text: "No notifications"
                    color: Colors.outline
                }
            }
        }
    }
}
