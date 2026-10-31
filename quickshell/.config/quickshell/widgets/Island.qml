import QtQuick
import qs.config
import qs.services

// A floating pill on the bar. Children stack vertically and centred.
Rectangle {
    id: root

    default property alias content: column.data
    property alias spacing: column.spacing
    property int verticalPadding: Appearance.padding.normal
    property bool interactive: false
    property color hoverTint: Colors.textOnSurface

    signal clicked(var event)

    implicitWidth: Appearance.bar.islandWidth
    implicitHeight: column.implicitHeight + verticalPadding * 2
    radius: Appearance.rounding.normal
    color: Colors.alpha(Colors.surfaceContainer, 0.92)
    border.width: 1
    border.color: Colors.alpha(Colors.outlineVariant, 0.35)

    Behavior on color { CAnim {} }
    Behavior on implicitHeight { Anim { easing.bezierCurve: Appearance.anim.spatial } }

    StateLayer {
        visible: root.interactive
        tint: root.hoverTint
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: event => root.clicked(event)
    }

    Column {
        id: column
        anchors.centerIn: parent
        spacing: Appearance.spacing.normal
    }
}
