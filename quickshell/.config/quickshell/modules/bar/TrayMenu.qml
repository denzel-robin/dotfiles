import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.services
import qs.widgets

// Tray app menu drawn in the rice's style (instead of Qt's native menu).
// Submenus open in place with a back row. Clicking outside closes it.
PopupWindow {
    id: root

    required property Item anchorItem
    required property var handle          // the app's QsMenuHandle
    property list<var> stack: []          // open submenus
    readonly property var current: stack.length > 0 ? stack[stack.length - 1] : handle
    readonly property int gap: Appearance.spacing.large

    function open(): void {
        stack = [];
        visible = true;
    }

    function close(): void {
        visible = false;
    }

    // "_Quit" -> "Quit" (GTK/Qt mnemonic markers)
    function label(text: string): string {
        return text.replace(/__/g, "\u0000").replace(/[_&](?=\S)/g, "").replace(/\u0000/g, "_");
    }

    anchor.item: anchorItem
    anchor.edges: Edges.Right
    anchor.gravity: Edges.Right
    grabFocus: true
    color: "transparent"
    implicitWidth: card.width + gap
    implicitHeight: card.height

    QsMenuOpener {
        id: opener
        menu: root.current
    }

    Rectangle {
        id: card

        x: root.gap
        width: 250
        height: column.implicitHeight + Appearance.padding.small * 2
        radius: Appearance.rounding.normal
        color: Colors.surfaceContainer
        border.width: 1
        border.color: Colors.alpha(Colors.outlineVariant, 0.35)

        opacity: root.visible ? 1 : 0
        scale: root.visible ? 1 : 0.92
        transformOrigin: Item.Left
        Behavior on opacity { Anim { duration: Appearance.anim.fast } }
        Behavior on scale { Anim { duration: Appearance.anim.fast; easing.bezierCurve: Appearance.anim.spatial } }
        Behavior on height { Anim { duration: Appearance.anim.fast } }

        ColumnLayout {
            id: column

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Appearance.padding.small
            spacing: 0

            // Back to the parent menu
            Rectangle {
                visible: root.stack.length > 0
                Layout.fillWidth: true
                implicitHeight: 36
                radius: Appearance.rounding.small
                color: "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Appearance.padding.normal
                    spacing: Appearance.spacing.normal

                    MaterialIcon {
                        icon: "arrow_back"
                        size: 18
                        color: Colors.primary
                    }

                    StyledText {
                        text: "Back"
                        color: Colors.primary
                        font.weight: Font.Medium
                    }
                }

                StateLayer {
                    onClicked: root.stack = root.stack.slice(0, -1)
                }
            }

            Repeater {
                model: opener.children

                Loader {
                    id: loader

                    required property var modelData

                    Layout.fillWidth: true
                    sourceComponent: modelData.isSeparator ? separator : item

                    Component {
                        id: separator

                        Item {
                            implicitHeight: 9

                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width - Appearance.padding.normal * 2
                                height: 1
                                color: Colors.outlineVariant
                            }
                        }
                    }

                    Component {
                        id: item

                        Rectangle {
                            readonly property var entry: loader.modelData

                            implicitHeight: 36
                            radius: Appearance.rounding.small
                            color: "transparent"
                            opacity: entry.enabled ? 1 : 0.45

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Appearance.padding.normal
                                anchors.rightMargin: Appearance.padding.normal
                                spacing: Appearance.spacing.normal

                                MaterialIcon {
                                    visible: entry.buttonType !== QsMenuButtonType.None
                                    icon: entry.buttonType === QsMenuButtonType.RadioButton
                                        ? (entry.checkState === Qt.Checked ? "radio_button_checked" : "radio_button_unchecked")
                                        : (entry.checkState === Qt.Checked ? "check_box" : "check_box_outline_blank")
                                    size: 18
                                    fill: entry.checkState === Qt.Checked ? 1 : 0
                                    color: entry.checkState === Qt.Checked ? Colors.primary : Colors.textOnSurfaceVariant
                                }

                                IconImage {
                                    visible: entry.icon !== ""
                                    implicitSize: 18
                                    source: entry.icon
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: root.label(entry.text)
                                    elide: Text.ElideRight
                                }

                                MaterialIcon {
                                    visible: entry.hasChildren
                                    icon: "chevron_right"
                                    size: 18
                                    color: Colors.textOnSurfaceVariant
                                }
                            }

                            StateLayer {
                                enabled: entry.enabled
                                onClicked: {
                                    if (entry.hasChildren) {
                                        root.stack = [...root.stack, entry];
                                    } else {
                                        entry.triggered();
                                        root.close();
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
