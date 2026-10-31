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

    property int menuFor: -1   // index of the app whose right-click menu is open
    property real menuY: 0

    // Close the right-click menu; true if it was open (so Esc closes the menu first)
    function closeMenu(): bool {
        const wasOpen = menuFor >= 0;
        menuFor = -1;
        return wasOpen;
    }

    // Never carry an open menu over to the next time the launcher opens
    Connections {
        target: Panels
        function onCurrentChanged() { root.menuFor = -1; }
        function onLauncherModeChanged() { root.menuFor = -1; }
    }

    // Open the right-click menu under (or, near the bottom, above) the app's row
    function openMenu(index: int): void {
        const row = list.itemAtIndex(index);
        if (!row)
            return;
        const below = row.mapToItem(menuLayer, 0, row.height).y + 2;
        const listBottom = list.mapToItem(menuLayer, 0, list.height).y;
        const h = 3 * 34 + 8;   // three items (the menu's real height isn't known until it's filled)
        menuY = below + h > listBottom ? row.mapToItem(menuLayer, 0, 0).y - h - 2 : below;
        menuFor = index;
    }

    function activate(gpu): void {
        if (expr && result) {
            Quickshell.execDetached(["wl-copy", result]);
            Panels.close();
        } else if (list.currentItem) {
            Apps.launch(list.currentItem.modelData, gpu);
            Panels.close();
        }
    }

    function handleKey(event): bool {
        menuFor = -1;
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

        onCountChanged: {
            currentIndex = 0;
            root.menuFor = -1;
        }

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

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        StyledText {
                            Layout.fillWidth: true
                            text: item.modelData.name
                            font.pixelSize: Appearance.font.normal + 1
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }

                        // Always opens on the NVIDIA GPU
                        Rectangle {
                            visible: Apps.alwaysGpu(item.modelData)
                            implicitWidth: gpuTag.implicitWidth + 10
                            implicitHeight: 16
                            radius: 8
                            color: Colors.tertiaryContainer

                            StyledText {
                                id: gpuTag
                                anchors.centerIn: parent
                                text: "GPU"
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                                color: Colors.textOnTertiaryContainer
                            }
                        }
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
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onPositionChanged: mouse => { if (Panels.pointerMoved(hoverArea, mouse.x, mouse.y)) list.currentIndex = item.index; }
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton) {
                        list.currentIndex = item.index;
                        if (root.menuFor === item.index)
                            root.menuFor = -1;
                        else
                            root.openMenu(item.index);
                        return;
                    }
                    root.menuFor = -1;
                    Apps.launch(item.modelData);
                    Panels.close();
                }
            }
        }
    }

    // Right-click menu for an app
    Item {
        id: menuLayer

        Layout.preferredHeight: 0
        Layout.fillWidth: true
        z: 10

        // While the menu is open, a click anywhere else in the list closes it
        MouseArea {
            visible: root.menuFor >= 0
            y: -menuLayer.y
            width: root.width
            height: root.height
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: root.menuFor = -1
        }

        Rectangle {
            id: appMenu

            readonly property var entry: root.menuFor >= 0 ? list.itemAtIndex(root.menuFor)?.modelData ?? null : null

            visible: entry !== null
            x: parent.width - width - Appearance.padding.normal
            y: root.menuY
            width: 250
            height: menuCol.implicitHeight + 8
            radius: Appearance.rounding.small + 2
            color: Colors.surfaceContainerHighest
            border.width: 1
            border.color: Colors.outlineVariant

            ColumnLayout {
                id: menuCol

                anchors.fill: parent
                anchors.margins: 4
                spacing: 0

                Repeater {
                    model: appMenu.entry ? [
                        { icon: "open_in_new", text: "Open", act: () => { Apps.launch(appMenu.entry); Panels.close(); } },
                        { icon: "memory", text: "Open on NVIDIA GPU", act: () => { Apps.launch(appMenu.entry, true); Panels.close(); } },
                        { icon: Apps.alwaysGpu(appMenu.entry) ? "check_box" : "check_box_outline_blank", text: "Always use NVIDIA GPU", act: () => Apps.toggleAlwaysGpu(appMenu.entry) }
                    ] : []

                    Rectangle {
                        required property var modelData

                        Layout.fillWidth: true
                        implicitHeight: 34
                        radius: Appearance.rounding.small
                        color: "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Appearance.padding.normal
                            spacing: Appearance.spacing.normal

                            MaterialIcon {
                                icon: parent.parent.modelData.icon
                                size: 18
                                color: Colors.primary
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: parent.parent.modelData.text
                            }
                        }

                        StateLayer {
                            onClicked: parent.modelData.act()
                        }
                    }
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
