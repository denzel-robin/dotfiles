import QtQuick
import qs.config
import qs.services
import qs.widgets

// Click to open the dashboard.
Island {
    spacing: 0
    interactive: true
    onClicked: Panels.toggle("dashboard")
    verticalPadding: Appearance.padding.large

    StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Time.hours
        font.pixelSize: Appearance.font.large
        font.weight: Font.DemiBold
        color: Colors.primary
    }

    StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        text: "••"
        font.pixelSize: 8
        color: Colors.outline
    }

    StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Time.minutes
        font.pixelSize: Appearance.font.large
        font.weight: Font.Medium
    }
}
