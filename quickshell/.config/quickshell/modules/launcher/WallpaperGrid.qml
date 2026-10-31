import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.services
import qs.widgets

// Wallpaper thumbnails. Enter applies (colours follow); the chip toggles light/dark.
Column {
    id: root

    required property string query
    readonly property var files: Wallpapers.files.filter(f => f.split("/").pop().toLowerCase().includes(query.trim().toLowerCase()))

    spacing: Appearance.spacing.normal

    function activate(gpu): void {
        if (grid.currentIndex >= 0 && grid.currentIndex < files.length)
            Wallpapers.set(files[grid.currentIndex]);
    }

    function handleKey(event): bool {
        switch (event.key) {
        case Qt.Key_Right: grid.moveCurrentIndexRight(); return true;
        case Qt.Key_Left: grid.moveCurrentIndexLeft(); return true;
        case Qt.Key_Down: grid.moveCurrentIndexDown(); return true;
        case Qt.Key_Up: grid.moveCurrentIndexUp(); return true;
        }
        return false;
    }

    // Light / dark switch
    Rectangle {
        anchors.right: parent.right
        implicitWidth: modeRow.implicitWidth + Appearance.padding.large * 2
        implicitHeight: 30
        radius: Appearance.rounding.full
        color: Colors.surfaceContainerHigh

        Row {
            id: modeRow
            anchors.centerIn: parent
            spacing: Appearance.spacing.small

            MaterialIcon {
                icon: Wallpapers.mode === "dark" ? "dark_mode" : "light_mode"
                size: 16
                fill: 1
                color: Colors.primary
            }

            StyledText {
                text: Wallpapers.mode === "dark" ? "Dark" : "Light"
                font.pixelSize: Appearance.font.small
            }
        }

        StateLayer {
            onClicked: Wallpapers.setMode(Wallpapers.mode === "dark" ? "light" : "dark")
        }
    }

    GridView {
        id: grid

        width: parent.width
        height: Math.min(Math.ceil(count / 4), 3) * cellHeight
        cellWidth: width / 4
        cellHeight: cellWidth * 0.68
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        highlightMoveDuration: Appearance.anim.fast
        currentIndex: Math.max(0, root.files.indexOf(Wallpapers.current))
        model: root.files

        delegate: Item {
            id: thumb

            required property string modelData
            required property int index
            readonly property bool selected: GridView.isCurrentItem
            readonly property bool current: modelData === Wallpapers.current

            width: grid.cellWidth
            height: grid.cellHeight

            ClippingRectangle {
                anchors.fill: parent
                anchors.margins: 4
                radius: Appearance.rounding.normal - 4
                color: Colors.surfaceContainerHigh
                border.width: thumb.selected ? 3 : 0
                border.color: Colors.primary
                scale: thumb.selected ? 1 : 0.94

                Behavior on scale { Anim { duration: Appearance.anim.fast; easing.bezierCurve: Appearance.anim.spatial } }

                MaterialIcon {
                    anchors.centerIn: parent
                    visible: img.status !== Image.Ready
                    icon: "image"
                    size: 28
                    color: Colors.outline
                }

                Image {
                    id: img
                    anchors.fill: parent
                    source: `file://${thumb.modelData}`
                    sourceSize.width: 320
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                }

                Rectangle {
                    visible: thumb.current
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 6
                    width: 22
                    height: 22
                    radius: 11
                    color: Colors.primary

                    MaterialIcon {
                        anchors.centerIn: parent
                        icon: "check"
                        size: 16
                        color: Colors.textOnPrimary
                    }
                }
            }

            MouseArea {
                id: hoverArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPositionChanged: mouse => { if (Panels.pointerMoved(hoverArea, mouse.x, mouse.y)) grid.currentIndex = thumb.index; }
                onClicked: Wallpapers.set(thumb.modelData)
            }
        }
    }

    StyledText {
        visible: root.files.length === 0
        anchors.horizontalCenter: parent.horizontalCenter
        text: `No wallpapers in ${Wallpapers.dir}`
        color: Colors.outline
    }
}
