import QtQuick
import qs.config
import qs.services
import qs.widgets

// Network, Bluetooth and battery at a glance. Click for the dashboard.
Island {
    interactive: true
    onClicked: Panels.toggle("dashboard")

    MaterialIcon {
        anchors.horizontalCenter: parent.horizontalCenter
        icon: Network.icon
        color: Network.online ? Colors.textOnSurface : Colors.outline
    }

    MaterialIcon {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: Bt.available
        icon: Bt.icon
        color: Bt.enabled ? Colors.textOnSurface : Colors.outline
    }

    Column {
        visible: Battery.present
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 0

        MaterialIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            fill: 1
            icon: Battery.icon
            color: Battery.low ? Colors.error : Battery.charging ? Colors.primary : Colors.textOnSurface
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Math.round(Battery.charge * 100)
            font.pixelSize: Appearance.font.small
            color: Colors.textOnSurfaceVariant
        }
    }
}
