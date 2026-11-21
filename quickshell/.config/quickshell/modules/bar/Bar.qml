import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.modules.jobs // jobs-tracker

// Floating islands down the left edge of the screen.
PanelWindow {
    id: root

    required property ShellScreen modelData

    screen: modelData
    anchors {
        left: true
        top: true
        bottom: true
    }
    implicitWidth: Appearance.bar.margin + Appearance.bar.islandWidth
    exclusiveZone: implicitWidth
    color: "transparent"
    WlrLayershell.namespace: "rice-bar"

    Item {
        anchors.fill: parent
        anchors.leftMargin: Appearance.bar.margin
        anchors.topMargin: Appearance.bar.margin
        anchors.bottomMargin: Appearance.bar.margin

        Column {
            anchors.top: parent.top
            spacing: Appearance.bar.islandSpacing

            Logo {}
            Workspaces {
                screen: root.modelData
            }
        }

        Clock {
            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            anchors.bottom: parent.bottom
            spacing: Appearance.bar.islandSpacing

            JobsIsland {} // jobs-tracker
            Tray {}
            UpdatesIsland {}
            Bell {}
            Status {}
            Power {}
        }
    }
}
