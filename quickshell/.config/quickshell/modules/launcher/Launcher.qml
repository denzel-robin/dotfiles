import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

// App launcher that rises from the bottom of the screen.
// Tab / Shift+Tab switches mode, ↑↓ (and ←→ for wallpapers) move, Enter picks, Esc closes.
Overlay {
    id: root

    name: "launcher"

    readonly property var modes: [
        { id: "apps", icon: "apps", label: "Apps", hint: "Search apps, or = to calculate" },
        { id: "wallpapers", icon: "wallpaper", label: "Wallpapers", hint: "Filter wallpapers" },
        { id: "clipboard", icon: "content_paste", label: "Clipboard", hint: "Search clipboard · Shift+Del removes" }
    ]
    readonly property string mode: Panels.launcherMode
    readonly property Item view: mode === "apps" ? apps : mode === "wallpapers" ? walls : clips

    function cycleMode(step: int): void {
        const i = modes.findIndex(m => m.id === mode);
        Panels.launcherMode = modes[(i + step + modes.length) % modes.length].id;
    }

    onShownChanged: {
        if (!shown)
            return;
        search.text = "";
        search.forceActiveFocus();
        Wallpapers.refresh();
        Clipboard.refresh();
    }
    onModeChanged: search.text = ""

    Card {
        id: card

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Appearance.bar.margin * 2
        width: 640
        height: layout.implicitHeight + Appearance.padding.large * 2
        opacity: root.progress
        transform: Translate { y: (1 - root.progress) * (card.height + 40) }

        Behavior on height { Anim { easing.bezierCurve: Appearance.anim.emphasized } }

        ColumnLayout {
            id: layout

            anchors.fill: parent
            anchors.margins: Appearance.padding.large
            spacing: Appearance.spacing.large

            AppList {
                id: apps
                visible: root.mode === "apps"
                query: search.text
                Layout.fillWidth: true
            }

            WallpaperGrid {
                id: walls
                visible: root.mode === "wallpapers"
                query: search.text
                Layout.fillWidth: true
            }

            ClipboardList {
                id: clips
                visible: root.mode === "clipboard"
                query: search.text
                Layout.fillWidth: true
            }

            // Mode tabs
            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: Appearance.spacing.normal

                Repeater {
                    model: root.modes

                    Rectangle {
                        id: chip

                        required property var modelData
                        readonly property bool active: root.mode === modelData.id

                        implicitWidth: chipRow.implicitWidth + Appearance.padding.large * 2
                        implicitHeight: 32
                        radius: Appearance.rounding.full
                        color: active ? Colors.secondaryContainer : "transparent"
                        border.width: active ? 0 : 1
                        border.color: Colors.outlineVariant

                        Behavior on color { CAnim { duration: Appearance.anim.fast } }

                        Row {
                            id: chipRow
                            anchors.centerIn: parent
                            spacing: Appearance.spacing.small

                            MaterialIcon {
                                icon: chip.modelData.icon
                                size: 18
                                fill: chip.active ? 1 : 0
                                color: chip.active ? Colors.textOnSecondaryContainer : Colors.textOnSurfaceVariant
                            }

                            StyledText {
                                text: chip.modelData.label
                                color: chip.active ? Colors.textOnSecondaryContainer : Colors.textOnSurfaceVariant
                            }
                        }

                        StateLayer {
                            onClicked: {
                                Panels.launcherMode = chip.modelData.id;
                                search.forceActiveFocus();
                            }
                        }
                    }
                }
            }

            // Search field
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 50
                radius: Appearance.rounding.full
                color: Colors.surfaceContainerHigh

                MaterialIcon {
                    id: searchIcon
                    anchors.left: parent.left
                    anchors.leftMargin: Appearance.padding.large
                    anchors.verticalCenter: parent.verticalCenter
                    icon: root.modes.find(m => m.id === root.mode).icon
                    color: Colors.primary
                }

                TextInput {
                    id: search

                    anchors.left: searchIcon.right
                    anchors.right: parent.right
                    anchors.leftMargin: Appearance.spacing.large
                    anchors.rightMargin: Appearance.padding.large
                    anchors.verticalCenter: parent.verticalCenter
                    color: Colors.textOnSurface
                    selectionColor: Colors.primary
                    selectedTextColor: Colors.textOnPrimary
                    font.family: Appearance.font.sans
                    font.pixelSize: Appearance.font.large
                    clip: true

                    StyledText {
                        visible: !search.text
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.modes.find(m => m.id === root.mode).hint
                        color: Colors.outline
                        font.pixelSize: Appearance.font.large
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                            root.cycleMode(event.key === Qt.Key_Backtab ? -1 : 1);
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.view.activate();
                        } else if (event.key === Qt.Key_Escape) {
                            Panels.close();
                        } else if (root.view.handleKey(event)) {
                            // handled by the view (arrows, delete…)
                        } else {
                            return;
                        }
                        event.accepted = true;
                    }
                }
            }
        }
    }
}
