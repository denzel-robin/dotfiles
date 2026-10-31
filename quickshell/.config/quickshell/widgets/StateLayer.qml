import QtQuick
import qs.config
import qs.services

// Hover/press feedback. Drop inside any rounded item and handle onClicked.
MouseArea {
    id: root

    property color tint: Colors.textOnSurface
    property real radius: parent?.radius ?? Appearance.rounding.full

    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.tint
        opacity: root.pressed ? 0.16 : root.containsMouse ? 0.08 : 0

        Behavior on opacity { Anim { duration: Appearance.anim.fast } }
    }
}
