import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

// Keybind cheat sheet (Super+/). Keep in sync with hypr/hyprland.lua.
Overlay {
    id: root

    name: "keybinds"

    readonly property var groups: [
        { title: "Shell", icon: "dashboard", binds: [
            ["Super+Space", "App launcher"], ["Super+R", "Wallpapers"], ["Super+V", "Clipboard history"],
            ["Super+A", "Dashboard"], ["Super+Tab", "Workspace overview"], ["Super+`", "Notifications"], ["Super+Shift+`", "Do Not Disturb"],
            ["Super+L", "Lock screen"], ["Super+Shift+L", "Session menu"], ["Super+/", "This cheat sheet"]
        ] },
        { title: "Apps", icon: "apps", binds: [
            ["Super+Return", "Terminal (kitty)"], ["Super+E", "Files (Yazi)"], ["Super+Shift+E", "Trash"],
            ["Super+W", "Browser (Zen)"], ["Super+O", "Discord (Vesktop)"], ["Super+\\", "btop"],
            ["Super+[", "KeePassXC"], ["Super+G", "Godot"], ["Super+D", "Draw on screen"]
        ] },
        { title: "Windows", icon: "select_window", binds: [
            ["Super+C", "Close window"], ["Super+F", "Float / tile"], ["Super+Shift+F", "Fullscreen"],
            ["Super+T", "Flip split"], ["Super+Z", "Scratchpad"], ["Super+Arrows", "Focus window"],
            ["Super+Ctrl+Arrows", "Move window"], ["Super+Left drag", "Move with mouse"], ["Super+Right drag", "Resize with mouse"]
        ] },
        { title: "Workspaces", icon: "space_dashboard", binds: [
            ["Super+1…0", "Go to workspace"], ["Super+Shift+1…0", "Send window there"],
            ["Super+Scroll", "Next / previous"], ["3-finger swipe", "Next / previous"], ["Super+M", "Exit Hyprland"]
        ] },
        { title: "Screenshots", icon: "screenshot_region", binds: [
            ["Print", "Flameshot (annotate)"], ["Super+S", "Region → clipboard"], ["Super+Shift+S", "Screenshot → tgbot"]
        ] },
        { title: "Media keys", icon: "volume_up", binds: [
            ["Volume keys", "Volume (slider pops up)"], ["Mute / Mic", "Mute speaker / mic"],
            ["Brightness keys", "Brightness"], ["Play / Next / Prev", "Media control"]
        ] }
    ]

    Card {
        id: card

        anchors.centerIn: parent
        width: grid.implicitWidth + Appearance.padding.large * 2
        height: col.implicitHeight + Appearance.padding.large * 2
        opacity: root.progress
        scale: 0.95 + 0.05 * root.progress

        ColumnLayout {
            id: col

            anchors.fill: parent
            anchors.margins: Appearance.padding.large
            spacing: Appearance.spacing.large

            RowLayout {
                Layout.fillWidth: true

                MaterialIcon {
                    icon: "keyboard"
                    fill: 1
                    color: Colors.primary
                }

                StyledText {
                    Layout.fillWidth: true
                    text: "Keyboard shortcuts"
                    font.pixelSize: Appearance.font.huge
                    font.weight: Font.Medium
                }

                StyledText {
                    text: "Esc to close"
                    font.pixelSize: Appearance.font.small
                    color: Colors.outline
                }
            }

            GridLayout {
                id: grid

                columns: 3
                columnSpacing: Appearance.spacing.large
                rowSpacing: Appearance.spacing.large

                Repeater {
                    model: root.groups

                    Tile {
                        id: group

                        required property var modelData

                        Layout.alignment: Qt.AlignTop
                        Layout.preferredWidth: 330
                        Layout.fillHeight: true

                        ColumnLayout {
                            width: parent.width
                            spacing: 6

                            RowLayout {
                                spacing: Appearance.spacing.small

                                MaterialIcon {
                                    icon: group.modelData.icon
                                    size: 18
                                    color: Colors.primary
                                }

                                StyledText {
                                    text: group.modelData.title
                                    font.weight: Font.DemiBold
                                    color: Colors.primary
                                }
                            }

                            Repeater {
                                model: group.modelData.binds

                                RowLayout {
                                    required property var modelData

                                    Layout.fillWidth: true
                                    spacing: 4

                                    // One chip per key: "Super+Shift+E" -> [Super] [Shift] [E]
                                    Repeater {
                                        model: parent.modelData[0].split("+")

                                        Rectangle {
                                            required property string modelData

                                            implicitWidth: key.implicitWidth + 12
                                            implicitHeight: 22
                                            radius: 6
                                            color: Colors.surfaceContainerHighest
                                            border.width: 1
                                            border.color: Colors.outlineVariant

                                            StyledText {
                                                id: key
                                                anchors.centerIn: parent
                                                text: parent.modelData
                                                font.family: Appearance.font.mono
                                                font.pixelSize: Appearance.font.small
                                            }
                                        }
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        Layout.leftMargin: 4
                                        text: parent.modelData[1]
                                        color: Colors.textOnSurfaceVariant
                                        elide: Text.ElideRight
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
