import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.config
import qs.services
import qs.widgets

// App results, plus a calculator row when the query is maths ("2+2", "=10 usd to inr").
ColumnLayout {
    id: root

    required property string query
    readonly property string expr: query.startsWith("=") ? query.slice(1).trim() : /^[\d\s.+\-*\/^%()]+$/.test(query) && /\d/.test(query) && /[+\-*\/^%]/.test(query) ? query.trim() : ""
    property string result: ""

    spacing: Appearance.spacing.small

    function activate(): void {
        if (expr && result) {
            Quickshell.execDetached(["wl-copy", result]);
            Panels.close();
        } else if (list.currentItem) {
            Apps.launch(list.currentItem.modelData);
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
        return false;
    }

    onExprChanged: {
        result = "";
        if (expr)
            calcDelay.restart();
    }

    Timer {
        id: calcDelay
        interval: 120
        onTriggered: {
            calc.command = ["qalc", "-t", root.expr];
            calc.running = true;
        }
    }

    Process {
        id: calc
        stdout: StdioCollector {
            onStreamFinished: root.result = text.trim()
        }
    }

    // Calculator result
    Rectangle {
        visible: root.expr !== ""
        Layout.fillWidth: true
        implicitHeight: 64
        radius: Appearance.rounding.normal
        color: Colors.primaryContainer

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Appearance.padding.large
            anchors.rightMargin: Appearance.padding.large
            spacing: Appearance.spacing.large

            MaterialIcon {
                icon: "calculate"
                fill: 1
                size: 28
                color: Colors.textOnPrimaryContainer
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: root.result || "…"
                    font.pixelSize: Appearance.font.huge
                    font.weight: Font.Medium
                    color: Colors.textOnPrimaryContainer
                    elide: Text.ElideRight
                }

                StyledText {
                    text: "Enter to copy"
                    font.pixelSize: Appearance.font.small
                    color: Colors.alpha(Colors.textOnPrimaryContainer, 0.7)
                }
            }
        }
    }

    ListView {
        id: list

        Layout.fillWidth: true
        implicitHeight: Math.min(count, 7) * 56
        clip: true
        currentIndex: 0
        highlightMoveDuration: Appearance.anim.fast
        boundsBehavior: Flickable.StopAtBounds

        model: ScriptModel {
            values: Apps.search(root.query).slice(0, 50)
        }

        onCountChanged: currentIndex = 0

        highlight: Rectangle {
            radius: Appearance.rounding.normal
            color: Colors.alpha(Colors.textOnSurface, 0.08)
        }

        delegate: Item {
            id: item

            required property var modelData
            required property int index

            width: list.width
            height: 56

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Appearance.padding.normal
                anchors.rightMargin: Appearance.padding.normal
                spacing: Appearance.spacing.large

                Item {
                    readonly property string icon: Apps.iconFor(item.modelData)

                    implicitWidth: 36
                    implicitHeight: 36

                    IconImage {
                        anchors.fill: parent
                        visible: parent.icon !== ""
                        source: parent.icon
                    }

                    // No icon in the theme
                    Rectangle {
                        anchors.fill: parent
                        visible: parent.icon === ""
                        radius: Appearance.rounding.small
                        color: Colors.secondaryContainer

                        MaterialIcon {
                            anchors.centerIn: parent
                            icon: "apps"
                            fill: 1
                            color: Colors.textOnSecondaryContainer
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    StyledText {
                        Layout.fillWidth: true
                        text: item.modelData.name
                        font.pixelSize: Appearance.font.normal + 1
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: item.modelData.comment || item.modelData.genericName || ""
                        font.pixelSize: Appearance.font.small
                        color: Colors.textOnSurfaceVariant
                        elide: Text.ElideRight
                    }
                }
            }

            MouseArea {
                id: hoverArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPositionChanged: mouse => { if (Panels.pointerMoved(hoverArea, mouse.x, mouse.y)) list.currentIndex = item.index; }
                onClicked: {
                    Apps.launch(item.modelData);
                    Panels.close();
                }
            }
        }
    }

    StyledText {
        visible: list.count === 0 && !root.expr
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Appearance.padding.large
        Layout.bottomMargin: Appearance.padding.large
        text: "No apps found"
        color: Colors.outline
    }
}
