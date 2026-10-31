import QtQuick
import qs.config
import qs.services
import qs.widgets

// Notification bell. Left click: Do-Not-Disturb on/off. Right click: notification menu.
// A dot means there are notifications; crossed out = Do-Not-Disturb.
Island {
    implicitHeight: implicitWidth
    interactive: true
    onClicked: event => {
        if (event.button === Qt.RightButton) {
            updatePosition();
            Panels.toggle("notifications");
        } else if (event.button === Qt.LeftButton) {
            Notifs.dnd = !Notifs.dnd;
        }
    }

    // Tell the notification menu where to line up (also when opened by keybind)
    function updatePosition(): void {
        Panels.bellBottom = mapToItem(null, 0, height).y;
    }

    Component.onCompleted: Qt.callLater(updatePosition)
    onYChanged: Qt.callLater(updatePosition)

    Item {
        implicitWidth: bell.implicitWidth
        implicitHeight: bell.implicitHeight

        MaterialIcon {
            id: bell
            icon: Notifs.dnd ? "notifications_off" : "notifications"
            size: 20
            fill: Notifs.history.length > 0 ? 1 : 0
            color: Notifs.dnd ? Colors.outline : Colors.textOnSurface
        }

        Rectangle {
            visible: Notifs.history.length > 0 && !Notifs.dnd
            anchors.right: bell.right
            anchors.top: bell.top
            width: 8
            height: 8
            radius: 4
            color: Colors.primary
            border.width: 1.5
            border.color: Colors.surfaceContainer
        }
    }
}
