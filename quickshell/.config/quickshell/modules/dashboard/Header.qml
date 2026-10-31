import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.services
import qs.widgets

Item {
    readonly property int hour: Time.date.getHours()

    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col

        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 2

        StyledText {
            text: `${hour < 5 ? "Good night" : hour < 12 ? "Good morning" : hour < 17 ? "Good afternoon" : "Good evening"}, ${Quickshell.env("USER")}`
            font.pixelSize: Appearance.font.huge
            font.weight: Font.Medium
        }

        RowLayout {
            spacing: Appearance.spacing.normal

            StyledText {
                text: Time.format("dddd, d MMMM")
                color: Colors.textOnSurfaceVariant
            }

            Rectangle {
                implicitWidth: up.implicitWidth + 16
                implicitHeight: 22
                radius: 11
                color: Colors.secondaryContainer
                visible: SysStats.uptime !== ""

                StyledText {
                    id: up
                    anchors.centerIn: parent
                    text: `up ${SysStats.uptime}`
                    font.pixelSize: Appearance.font.small
                    color: Colors.textOnSecondaryContainer
                }
            }
        }
    }
}
