import QtQuick
import qs.config
import qs.services
import qs.widgets

// Pending updates. Only shown when there are some.
// Left click: update now. Right click: list of updates.
Island {
    id: root

    readonly property color tint: Updates.restart !== "" ? Colors.tertiary : Colors.primary

    visible: Updates.count > 0 || Updates.updating
    interactive: true
    spacing: 2
    verticalPadding: Appearance.padding.small + 2

    onClicked: event => {
        if (event.button === Qt.RightButton) {
            updatePosition();
            Panels.toggle("updates");
        } else if (event.button === Qt.LeftButton) {
            Updates.update();
        }
    }

    function updatePosition(): void {
        Panels.updatesBottom = mapToItem(null, 0, height).y;
    }

    Component.onCompleted: Qt.callLater(updatePosition)
    onYChanged: Qt.callLater(updatePosition)
    onVisibleChanged: Qt.callLater(updatePosition)

    MaterialIcon {
        id: updateIcon

        anchors.horizontalCenter: parent.horizontalCenter
        icon: Updates.updating ? "sync" : "download"
        fill: 1
        color: root.tint

        RotationAnimation on rotation {
            running: Updates.updating
            from: 360
            to: 0
            duration: 1400
            loops: Animation.Infinite
            onStopped: updateIcon.rotation = 0   // spins only while updating; always end upright
        }
    }

    StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: !Updates.updating
        text: Updates.count > 99 ? "99+" : Updates.count
        font.pixelSize: Appearance.font.small
        font.weight: Font.DemiBold
        color: root.tint
    }
}
