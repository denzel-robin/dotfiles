import QtQuick
import qs.config
import qs.services
import qs.widgets

// Power button. Opens the session menu.
Island {
    implicitHeight: implicitWidth
    interactive: true
    hoverTint: Colors.error
    onClicked: Panels.toggle("session")

    MaterialIcon {
        icon: "power_settings_new"
        color: Colors.error
        size: 18
    }
}
