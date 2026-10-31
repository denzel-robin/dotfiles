import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

// Trash at a glance: size, auto-clean note, Open and Empty (press twice to confirm).
Tile {
    id: root

    property bool confirming: false

    Connections {
        target: Panels
        function onCurrentChanged() { root.confirming = false; }
    }

    RowLayout {
        width: parent.width
        spacing: Appearance.spacing.normal

        Rectangle {
            implicitWidth: 40
            implicitHeight: 40
            radius: 20
            color: Trash.items > 0 ? Colors.tertiaryContainer : Colors.surfaceContainerHighest

            MaterialIcon {
                anchors.centerIn: parent
                icon: Trash.items > 0 ? "delete" : "delete_outline"
                fill: Trash.items > 0 ? 1 : 0
                color: Trash.items > 0 ? Colors.textOnTertiaryContainer : Colors.textOnSurfaceVariant
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                text: Trash.items === 0 ? "Trash is empty" : `Trash · ${Trash.items} item${Trash.items === 1 ? "" : "s"} · ${Trash.size}`
                font.weight: Font.Medium
            }

            StyledText {
                Layout.fillWidth: true
                text: root.confirming ? "Click again to delete everything" : `Auto-deletes items after ${Trash.days} days`
                font.pixelSize: Appearance.font.small - 1
                color: root.confirming ? Colors.error : Colors.textOnSurfaceVariant
                elide: Text.ElideRight
            }
        }

        Repeater {
            model: [
                { icon: "folder_open", danger: false, act: () => { Panels.close(); Trash.open(); } },
                { icon: "delete_forever", danger: true, act: () => {
                    if (root.confirming) {
                        root.confirming = false;
                        Trash.empty();
                    } else {
                        root.confirming = true;
                    }
                } }
            ]

            Rectangle {
                required property var modelData

                visible: !modelData.danger || Trash.items > 0
                implicitWidth: 34
                implicitHeight: 34
                radius: 17
                color: modelData.danger && root.confirming ? Colors.error : Colors.surfaceContainerHighest

                Behavior on color { CAnim { duration: Appearance.anim.fast } }

                MaterialIcon {
                    anchors.centerIn: parent
                    icon: parent.modelData.icon
                    size: 18
                    color: parent.modelData.danger ? (root.confirming ? Colors.textOnError : Colors.error) : Colors.textOnSurface
                }

                StateLayer {
                    tint: parent.modelData.danger ? Colors.error : Colors.textOnSurface
                    onClicked: parent.modelData.act()
                }
            }
        }
    }
}
