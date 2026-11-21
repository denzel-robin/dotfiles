import QtQuick
import qs.config
import qs.services
import qs.widgets

// Job search on the bar: applications sent today, and a dot when follow-ups are due.
// Click to open the tracker.
Island {
    id: root

    readonly property bool goalMet: Jobs.appliedToday >= Jobs.dailyGoal

    visible: !Jobs.hidden
    interactive: true
    spacing: 2
    verticalPadding: Appearance.padding.small + 2

    onClicked: event => {
        if (event.button === Qt.LeftButton || event.button === Qt.RightButton) {
            updatePosition();
            Panels.toggle("jobs");
        }
    }

    function updatePosition(): void {
        Jobs.islandBottom = mapToItem(null, 0, height).y;
    }

    Component.onCompleted: Qt.callLater(updatePosition)
    onYChanged: Qt.callLater(updatePosition)
    onVisibleChanged: Qt.callLater(updatePosition)

    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        implicitWidth: icon.implicitWidth
        implicitHeight: icon.implicitHeight

        MaterialIcon {
            id: icon
            icon: "work"
            size: 20
            fill: root.goalMet ? 1 : 0
            color: root.goalMet ? Colors.primary : Colors.textOnSurface
        }

        Rectangle {
            visible: Jobs.dueCount > 0
            anchors.right: icon.right
            anchors.top: icon.top
            width: 8
            height: 8
            radius: 4
            color: Colors.tertiary
            border.width: 1.5
            border.color: Colors.surfaceContainer
        }
    }

    StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: !Jobs.weekend || Jobs.appliedToday > 0
        text: Jobs.weekend ? Jobs.appliedToday : `${Jobs.appliedToday}/${Jobs.dailyGoal}`
        font.pixelSize: Appearance.font.small
        font.weight: Font.DemiBold
        color: root.goalMet ? Colors.primary : Colors.textOnSurfaceVariant
    }
}
