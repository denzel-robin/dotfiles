import QtQuick
import qs.config
import qs.services

// Rounded surface for panel content. Swallows clicks so they don't close the panel.
Rectangle {
    radius: Appearance.rounding.large
    color: Colors.surfaceContainer
    border.width: 1
    border.color: Colors.alpha(Colors.outlineVariant, 0.35)

    Behavior on color { CAnim {} }

    MouseArea {
        anchors.fill: parent
        z: -1
    }
}
