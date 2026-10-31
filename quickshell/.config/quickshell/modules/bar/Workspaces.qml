import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.services
import qs.widgets

// Workspaces. Ones with windows show an icon per window (max 3, then "+n");
// the active one is tinted with the accent colour; empty ones are dots.
// Click to switch, scroll to cycle.
Island {
    id: root

    required property ShellScreen screen

    readonly property int activeId: Hypr.activeWorkspaceId(screen)
    readonly property var occupied: Hypr.occupiedIds
    readonly property int count: Math.max(5, activeId, ...occupied)
    readonly property int maxIcons: 3

    spacing: Appearance.spacing.small

    Repeater {
        model: root.count

        Item {
            id: ws

            required property int index
            readonly property int wsId: index + 1
            readonly property bool active: wsId === root.activeId
            readonly property var apps: Hypr.appsOn(wsId)
            readonly property bool hasApps: apps.length > 0
            readonly property int extra: Math.max(0, apps.length - root.maxIcons)

            implicitWidth: Appearance.bar.islandWidth
            implicitHeight: pill.height + 4

            Rectangle {
                id: pill

                anchors.centerIn: parent
                width: ws.hasApps ? 28 : ws.active ? 12 : 8
                height: ws.hasApps ? icons.implicitHeight + 12 : ws.active ? 30 : 8
                radius: width / 2
                color: ws.hasApps
                    ? (ws.active ? Colors.alpha(Colors.primary, 0.28) : "transparent")
                    : (ws.active ? Colors.primary : Colors.outlineVariant)
                border.width: ws.hasApps && ws.active ? 1 : 0
                border.color: Colors.alpha(Colors.primary, 0.6)

                Behavior on width { Anim { easing.bezierCurve: Appearance.anim.spatial } }
                Behavior on height { Anim { easing.bezierCurve: Appearance.anim.spatial } }
                Behavior on color { CAnim { duration: Appearance.anim.fast } }

                Column {
                    id: icons

                    anchors.centerIn: parent
                    visible: ws.hasApps
                    spacing: 4
                    opacity: ws.active ? 1 : 0.6

                    Behavior on opacity { Anim { duration: Appearance.anim.fast } }

                    Repeater {
                        model: ws.apps.slice(0, root.maxIcons)

                        Item {
                            id: app

                            required property string modelData
                            readonly property string icon: Apps.iconForClass(modelData)

                            implicitWidth: 16
                            implicitHeight: 16

                            IconImage {
                                anchors.fill: parent
                                visible: app.icon !== ""
                                source: app.icon
                            }

                            // App without an icon: first letter in a little circle
                            Rectangle {
                                anchors.fill: parent
                                visible: app.icon === ""
                                radius: 8
                                color: Colors.secondaryContainer

                                StyledText {
                                    anchors.centerIn: parent
                                    text: app.modelData.charAt(0).toUpperCase()
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                    color: Colors.textOnSecondaryContainer
                                }
                            }
                        }
                    }

                    StyledText {
                        visible: ws.extra > 0
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: `+${ws.extra}`
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        color: ws.active ? Colors.primary : Colors.textOnSurfaceVariant
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Hypr.focusWorkspace(ws.wsId)
            }
        }
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => Hypr.focusWorkspace(event.angleDelta.y > 0 ? "e-1" : "e+1")
    }
}
