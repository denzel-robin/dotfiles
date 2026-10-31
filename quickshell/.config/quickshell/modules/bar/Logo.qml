import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets

// Arch logo. Opens the app launcher.
Island {
    implicitHeight: implicitWidth
    interactive: true
    onClicked: Panels.toggleLauncher("apps")

    StyledText {
        text: ""
        font.family: Appearance.font.mono
        font.pixelSize: 20
        color: Colors.primary
        leftPadding: 2
    }
}
