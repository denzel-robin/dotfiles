import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

// Clipboard history. Enter copies the entry back, Shift+Delete removes it.
ColumnLayout {
    id: root

    required property string query
    readonly property var entries: Clipboard.entries.filter(e => e.text.toLowerCase().includes(query.trim().toLowerCase())).slice(0, 100)

    function activate(gpu): void {
        if (list.currentIndex >= 0 && list.currentIndex < entries.length) {
            Clipboard.copy(entries[list.currentIndex]);
            Panels.close();
        }
    }

    function handleKey(event): bool {
        if (event.key === Qt.Key_Down) {
            list.incrementCurrentIndex();
            return true;
        }
        if (event.key === Qt.Key_Up) {
            list.decrementCurrentIndex();
            return true;
        }
        if (event.key === Qt.Key_Delete && (event.modifiers & Qt.ShiftModifier) && list.currentIndex >= 0) {
            Clipboard.remove(entries[list.currentIndex]);
            return true;
        }
        return false;
    }

    ListView {
        id: list

        Layout.fillWidth: true
        implicitHeight: Math.min(count, 8) * 48
        clip: true
        currentIndex: 0
        highlightMoveDuration: Appearance.anim.fast
        boundsBehavior: Flickable.StopAtBounds
        model: root.entries

        highlight: Rectangle {
            radius: Appearance.rounding.normal
            color: Colors.alpha(Colors.textOnSurface, 0.08)
        }

        delegate: Item {
            id: row

            required property var modelData
            required property int index

            width: list.width
            height: 48

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Appearance.padding.normal
                anchors.rightMargin: Appearance.padding.normal
                spacing: Appearance.spacing.large

                MaterialIcon {
                    icon: row.modelData.isImage ? "image" : "notes"
                    size: 20
                    color: Colors.textOnSurfaceVariant
                }

                StyledText {
                    Layout.fillWidth: true
                    text: row.modelData.text.replace(/\s+/g, " ")
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }

            MouseArea {
                id: hoverArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPositionChanged: mouse => { if (Panels.pointerMoved(hoverArea, mouse.x, mouse.y)) list.currentIndex = row.index; }
                onClicked: {
                    Clipboard.copy(row.modelData);
                    Panels.close();
                }
            }
        }
    }

    StyledText {
        visible: list.count === 0
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Appearance.padding.large
        Layout.bottomMargin: Appearance.padding.large
        text: "Clipboard is empty"
        color: Colors.outline
    }
}
