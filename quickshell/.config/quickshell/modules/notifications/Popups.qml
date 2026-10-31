import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// New notifications, stacked in the top-right corner.
PanelWindow {
    id: root

    anchors {
        top: true
        right: true
    }
    margins {
        top: Appearance.bar.margin
        right: Appearance.bar.margin
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "rice-notifications"
    implicitWidth: 380
    implicitHeight: Math.max(1, column.implicitHeight)
    visible: Notifs.popups.length > 0 && Panels.current !== "notifications"
    color: "transparent"

    Column {
        id: column

        width: parent.width
        spacing: Appearance.spacing.normal

        Repeater {
            model: ScriptModel {
                values: Notifs.popups.filter(n => n).slice(0, 5)
            }

            NotificationCard {
                id: card

                required property var modelData
                property real enter: 0

                notif: modelData
                popup: true
                width: column.width
                opacity: enter
                transform: Translate { x: (1 - card.enter) * 420 }

                Behavior on enter { Anim { easing.bezierCurve: Appearance.anim.spatial } }
                Component.onCompleted: enter = 1
            }
        }
    }
}
