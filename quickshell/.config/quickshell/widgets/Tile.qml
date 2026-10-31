import QtQuick
import qs.config
import qs.services

// A section inside a panel card.
Rectangle {
    default property alias content: inner.data
    property int padding: Appearance.padding.large

    implicitHeight: inner.childrenRect.height + padding * 2
    radius: Appearance.rounding.normal
    color: Colors.surfaceContainerHigh

    Behavior on color { CAnim {} }

    Item {
        id: inner
        anchors.fill: parent
        anchors.margins: parent.padding
    }
}
