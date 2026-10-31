import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.services
import qs.widgets

// Session menu next to the power island. ↑↓ + Enter or click.
// Log out asks for a second press to confirm.
Overlay {
    id: root

    name: "session"

    property int current: 0
    property string confirming: ""

    readonly property var actions: [
        { id: "lock", icon: "lock", label: "Lock", confirm: false, run: () => LockState.locked = true },
        { id: "suspend", icon: "bedtime", label: "Sleep", confirm: false, run: () => Quickshell.execDetached(["systemctl", "suspend"]) },
        { id: "logout", icon: "logout", label: "Log out", confirm: true, run: () => Hypr.dispatch("hl.dsp.exit()") }
    ]

    function activate(i: int): void {
        const a = actions[i];
        if (a.confirm && confirming !== a.id) {
            confirming = a.id;
            current = i;
            return;
        }
        Panels.close();
        a.run();
    }

    onShownChanged: {
        current = 0;
        confirming = "";
        if (shown)
            keys.forceActiveFocus();
    }

    Card {
        id: card

        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: Appearance.bar.margin * 2 + Appearance.bar.islandWidth
        anchors.bottomMargin: Appearance.bar.margin
        width: 250
        height: list.implicitHeight + Appearance.padding.normal * 2
        opacity: root.progress
        transform: Translate { x: (root.progress - 1) * 40 }

        Item {
            id: keys
            focus: true
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Down)
                    root.current = (root.current + 1) % root.actions.length;
                else if (event.key === Qt.Key_Up)
                    root.current = (root.current - 1 + root.actions.length) % root.actions.length;
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                    root.activate(root.current);
                else if (event.key === Qt.Key_Escape)
                    Panels.close();
                else
                    return;
                event.accepted = true;
            }
        }

        ColumnLayout {
            id: list

            anchors.fill: parent
            anchors.margins: Appearance.padding.normal
            spacing: 2

            Repeater {
                model: root.actions

                Rectangle {
                    id: row

                    required property var modelData
                    required property int index
                    readonly property bool selected: root.current === index
                    readonly property bool asking: root.confirming === modelData.id

                    Layout.fillWidth: true
                    implicitHeight: 48
                    radius: Appearance.rounding.normal - 6
                    color: asking ? Colors.errorContainer : selected ? Colors.alpha(Colors.textOnSurface, 0.08) : "transparent"

                    Behavior on color { CAnim { duration: Appearance.anim.fast } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Appearance.padding.large
                        anchors.rightMargin: Appearance.padding.large
                        spacing: Appearance.spacing.large

                        MaterialIcon {
                            icon: row.modelData.icon
                            fill: row.selected ? 1 : 0
                            color: row.asking ? Colors.error : Colors.textOnSurface
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: row.asking ? `${row.modelData.label}? Press again` : row.modelData.label
                            font.weight: row.selected ? Font.Medium : Font.Normal
                            color: row.asking ? Colors.error : Colors.textOnSurface
                        }
                    }

                    MouseArea {
                        id: hoverArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPositionChanged: mouse => { if (Panels.pointerMoved(hoverArea, mouse.x, mouse.y)) root.current = row.index; }
                        onClicked: root.activate(row.index)
                    }
                }
            }
        }
    }
}
