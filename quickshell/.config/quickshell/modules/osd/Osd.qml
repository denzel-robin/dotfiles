import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// Volume / brightness slider that slides in from the right edge when either changes.
// Scroll or drag on it to adjust.
PanelWindow {
    id: root

    property string kind: "volume"   // "volume" | "brightness"
    property bool shown: false
    property bool armed: false       // ignore the initial values at startup
    property real progress: shown ? 1 : 0

    readonly property real value: kind === "volume" ? (Audio.muted ? 0 : Audio.volume) : Brightness.value
    readonly property string icon: kind === "volume" ? Audio.icon : value < 0.34 ? "brightness_low" : value < 0.67 ? "brightness_medium" : "brightness_high"

    function show(k: string): void {
        if (!armed)
            return;
        kind = k;
        shown = true;
        hideTimer.restart();
    }

    function adjust(v: real): void {
        if (kind === "volume")
            Audio.setVolume(v);
        else
            Brightness.setValue(v);
    }

    anchors.right: true
    margins.right: Appearance.bar.margin
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "rice-osd"
    implicitWidth: 52
    implicitHeight: 230
    visible: progress > 0
    color: "transparent"

    Behavior on progress { Anim { easing.bezierCurve: root.shown ? Appearance.anim.spatial : Appearance.anim.standard } }

    Timer {
        interval: 1500
        running: true
        onTriggered: root.armed = true
    }

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: area.containsMouse || area.pressed ? restart() : root.shown = false
    }

    Connections {
        target: Audio
        function onVolumeChanged() { root.show("volume"); }
        function onMutedChanged() { root.show("volume"); }
    }

    Connections {
        target: Brightness
        function onValueChanged() { root.show("brightness"); }
    }

    Rectangle {
        id: pill

        anchors.fill: parent
        radius: Appearance.rounding.full
        color: Colors.surfaceContainer
        border.width: 1
        border.color: Colors.alpha(Colors.outlineVariant, 0.35)
        opacity: root.progress
        transform: Translate { x: (1 - root.progress) * (root.width + Appearance.bar.margin) }

        StyledText {
            id: percent
            anchors.top: parent.top
            anchors.topMargin: Appearance.padding.large
            anchors.horizontalCenter: parent.horizontalCenter
            text: Math.round(root.value * 100)
            font.pixelSize: Appearance.font.small
            font.weight: Font.Medium
        }

        Rectangle {
            id: track

            anchors.top: percent.bottom
            anchors.bottom: icon.top
            anchors.margins: Appearance.spacing.normal
            anchors.horizontalCenter: parent.horizontalCenter
            width: 14
            radius: width / 2
            color: Colors.surfaceContainerHighest

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: Math.max(width, parent.height * root.value)
                radius: width / 2
                color: Colors.primary

                Behavior on height { Anim { duration: Appearance.anim.fast } }
            }
        }

        MaterialIcon {
            id: icon
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Appearance.padding.normal + 2
            anchors.horizontalCenter: parent.horizontalCenter
            icon: root.icon
            fill: 1
            color: Colors.primary
        }

        MouseArea {
            id: area

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: mouse => setFrom(mouse.y)
            onPositionChanged: mouse => { if (pressed) setFrom(mouse.y); }
            onWheel: wheel => root.adjust(root.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))
            onClicked: mouse => { if (mouse.y > icon.y && root.kind === "volume") Audio.toggleMute(); }

            function setFrom(y: real): void {
                if (y < track.y || y > track.y + track.height)
                    return;
                root.adjust(1 - (y - track.y) / track.height);
            }
        }
    }
}
