import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

// Month view. Arrows (or scrolling) change month; it returns to today on reopen.
Tile {
    id: root

    property bool shown: false
    property int offset: 0
    readonly property date month: new Date(Time.date.getFullYear(), Time.date.getMonth() + offset, 1)
    readonly property int startDay: (month.getDay() + 6) % 7   // Monday first
    readonly property int daysInMonth: new Date(month.getFullYear(), month.getMonth() + 1, 0).getDate()

    onShownChanged: if (shown) offset = 0

    RowLayout {
        id: head

        width: parent.width

        StyledText {
            Layout.fillWidth: true
            text: Qt.formatDate(root.month, "MMMM yyyy")
            font.pixelSize: Appearance.font.large
            font.weight: Font.Medium
        }

        Repeater {
            model: [["chevron_left", -1], ["chevron_right", 1]]

            Rectangle {
                required property var modelData

                implicitWidth: 30
                implicitHeight: 30
                radius: 15
                color: "transparent"

                MaterialIcon {
                    anchors.centerIn: parent
                    icon: modelData[0]
                }

                StateLayer {
                    onClicked: root.offset += modelData[1]
                }
            }
        }
    }

    GridLayout {
        id: days

        anchors.top: head.bottom
        anchors.topMargin: Appearance.spacing.normal
        width: parent.width
        columns: 7
        rowSpacing: 2
        columnSpacing: 0

        Repeater {
            model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

            StyledText {
                required property string modelData
                required property int index

                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                font.pixelSize: Appearance.font.small
                font.weight: Font.Medium
                color: index >= 5 ? Colors.tertiary : Colors.textOnSurfaceVariant
            }
        }

        Repeater {
            model: 42

            Item {
                id: cell

                required property int index
                readonly property date day: new Date(root.month.getFullYear(), root.month.getMonth(), index - root.startDay + 1)
                readonly property bool inMonth: day.getMonth() === root.month.getMonth()
                readonly property bool today: day.toDateString() === Time.date.toDateString()

                Layout.fillWidth: true
                implicitHeight: 34
                visible: index < 35 || root.startDay + root.daysInMonth > 35

                Rectangle {
                    anchors.centerIn: parent
                    width: 32
                    height: 32
                    radius: 16
                    color: cell.today ? Colors.primary : "transparent"
                }

                StyledText {
                    anchors.centerIn: parent
                    text: cell.day.getDate()
                    color: cell.today ? Colors.textOnPrimary : cell.inMonth ? Colors.textOnSurface : Colors.outlineVariant
                    font.weight: cell.today ? Font.DemiBold : Font.Normal
                }
            }
        }
    }

    WheelHandler {
        onWheel: event => root.offset += event.angleDelta.y > 0 ? -1 : 1
    }
}
