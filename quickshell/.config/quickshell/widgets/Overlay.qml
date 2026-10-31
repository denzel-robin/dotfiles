import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.services

// Base for popup panels: covers the focused screen, dims it, animates `progress`
// 0 -> 1 on open, and closes on Escape or a click outside the content.
PanelWindow {
    id: root

    required property string name
    readonly property bool shown: Panels.current === name
    property real progress: shown ? 1 : 0
    property bool dim: true
    property bool grabKeyboard: true
    default property alias content: area.data

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: `rice-${name}`
    WlrLayershell.keyboardFocus: shown && grabKeyboard ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    visible: progress > 0
    color: dim ? Colors.alpha(Colors.shadow, 0.3 * progress) : "transparent"

    Behavior on progress {
        Anim {
            duration: root.shown ? Appearance.anim.normal : Appearance.anim.fast
            easing.bezierCurve: root.shown ? Appearance.anim.emphasized : Appearance.anim.standard
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Panels.close()
    }

    Item {
        id: area
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: Panels.close()
    }
}
