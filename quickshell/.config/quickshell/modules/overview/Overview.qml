import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import qs.config
import qs.services
import qs.widgets

// Workspace overview (Super+Tab): every workspace with live previews of its windows.
//   click a window      → jump to it          middle-click → close it
//   drag a window       → move it to another workspace (the last card is a fresh one)
//   click a workspace   → go there
//   ←→↑↓ + Enter, 1–9   → keyboard
Overlay {
    id: root

    name: "overview"

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    readonly property int activeId: monitor?.activeWorkspace?.id ?? 1

    // Workspaces that exist + the active one + one empty one after the last
    readonly property list<int> ids: {
        const s = new Set(Hypr.occupiedIds);
        s.add(activeId);
        const ids = [...s].sort((a, b) => a - b);
        const next = (ids[ids.length - 1] ?? 0) + 1;
        if (next <= 10)
            ids.push(next);
        return ids;
    }
    readonly property int columns: Math.min(ids.length, 4)
    readonly property real cardScale: ids.length <= 3 ? 0.26 : 0.19
    readonly property real cardW: screen.width * cardScale
    readonly property real cardH: screen.height * cardScale

    property int selected: 0                 // keyboard selection (index into ids)
    property var dragging: null              // the HyprlandToplevel being dragged
    property int dropTarget: -1              // workspace id under the dragged window

    function goTo(wsId: int): void {
        Panels.close();
        Hypr.focusWorkspace(wsId);
    }

    function addr(t: HyprlandToplevel): string {
        return "address:0x" + t.address.replace(/^0x/, "");
    }

    function focusWindow(t: HyprlandToplevel): void {
        Panels.close();
        Hypr.dispatch(`hl.dsp.focus({ window = "${addr(t)}" })`);
    }

    function closeWindow(t: HyprlandToplevel): void {
        Hypr.dispatch(`hl.dsp.window.close({ window = "${addr(t)}" })`);
        refreshLater.restart();
    }

    function moveWindow(t: HyprlandToplevel, wsId: int): void {
        Hypr.dispatch(`hl.dsp.window.move({ workspace = ${wsId}, window = "${addr(t)}", follow = false })`);
        refreshLater.restart();
    }

    function toplevelsOn(wsId: int): list<var> {
        const ws = Hyprland.workspaces.values.find(w => w.id === wsId);
        if (!ws)
            return [];
        // tiled first, floating on top
        return ws.toplevels.values.filter(t => t.lastIpcObject?.at).sort((a, b) => (a.lastIpcObject.floating ? 1 : 0) - (b.lastIpcObject.floating ? 1 : 0));
    }

    // Workspace id of the card under a point in `root` coordinates, or -1
    function cardAt(x: real, y: real): int {
        for (let i = 0; i < cards.count; i++) {
            const c = cards.itemAt(i);
            const p = c.mapFromItem(root.contentItem, x, y);
            if (p.x >= 0 && p.y >= 0 && p.x <= c.width && p.y <= c.height)
                return c.wsId;
        }
        return -1;
    }

    onShownChanged: {
        if (shown) {
            Hyprland.refreshToplevels();
            Hyprland.refreshWorkspaces();
            selected = Math.max(0, ids.indexOf(activeId));
            keys.forceActiveFocus();
        }
        dragging = null;
        dropTarget = -1;
    }

    Timer {
        id: refreshLater
        interval: 120
        onTriggered: {
            Hyprland.refreshToplevels();
            Hyprland.refreshWorkspaces();
        }
    }

    Card {
        id: card

        anchors.centerIn: parent
        width: grid.implicitWidth + Appearance.padding.large * 2
        height: grid.implicitHeight + hint.implicitHeight + Appearance.padding.large * 2 + Appearance.spacing.normal
        opacity: root.progress
        scale: 0.94 + 0.06 * root.progress

        // swallow clicks so they don't close the overlay
        MouseArea {
            anchors.fill: parent
        }

        Item {
            id: keys
            focus: true
            Keys.onPressed: event => {
                const n = root.ids.length;
                if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab)
                    root.selected = (root.selected + 1) % n;
                else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab)
                    root.selected = (root.selected - 1 + n) % n;
                else if (event.key === Qt.Key_Down)
                    root.selected = Math.min(n - 1, root.selected + root.columns);
                else if (event.key === Qt.Key_Up)
                    root.selected = Math.max(0, root.selected - root.columns);
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space)
                    root.goTo(root.ids[root.selected]);
                else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9)
                    root.goTo(event.key - Qt.Key_0);
                else if (event.key === Qt.Key_0)
                    root.goTo(10);
                else if (event.key === Qt.Key_Escape)
                    Panels.close();
                else
                    return;
                event.accepted = true;
            }
        }

        GridLayout {
            id: grid

            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: Appearance.padding.large
            columns: root.columns
            rowSpacing: Appearance.spacing.large
            columnSpacing: Appearance.spacing.large

            Repeater {
                id: cards

                model: root.ids

                Rectangle {
                    id: ws

                    required property int modelData
                    required property int index
                    readonly property int wsId: modelData
                    readonly property bool active: wsId === root.activeId
                    readonly property bool isSelected: index === root.selected
                    readonly property bool isDrop: root.dragging !== null && root.dropTarget === wsId
                    readonly property var windows: root.toplevelsOn(wsId)

                    implicitWidth: root.cardW
                    implicitHeight: root.cardH
                    radius: Appearance.rounding.normal
                    color: isDrop ? Colors.alpha(Colors.primary, 0.18) : Colors.surfaceContainerHigh
                    border.width: active || isSelected || isDrop ? 2 : 0
                    border.color: isDrop ? Colors.primary : active ? Colors.primary : Colors.alpha(Colors.textOnSurface, 0.35)

                    Behavior on color { CAnim { duration: Appearance.anim.fast } }

                    // empty area: go to the workspace
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: if (!root.dragging) root.selected = ws.index
                        onClicked: root.goTo(ws.wsId)
                    }

                    // Windows, laid out as on screen
                    ClippingRectangle {
                        anchors.fill: parent
                        anchors.margins: ws.border.width
                        radius: ws.radius - ws.border.width
                        color: "transparent"

                        Repeater {
                            model: ws.windows

                            Item {
                                id: win

                                required property var modelData
                                readonly property var ipc: modelData.lastIpcObject
                                readonly property string appId: modelData.wayland?.appId || ipc?.class || ""
                                readonly property bool isDragged: root.dragging === modelData

                                x: (ipc.at[0] - root.screen.x) * root.cardScale
                                y: (ipc.at[1] - root.screen.y) * root.cardScale
                                width: ipc.size[0] * root.cardScale
                                height: ipc.size[1] * root.cardScale
                                opacity: isDragged ? 0.35 : 1

                                ClippingRectangle {
                                    anchors.fill: parent
                                    radius: Appearance.rounding.small - 2
                                    color: Colors.surfaceContainerHighest

                                    ScreencopyView {
                                        id: preview
                                        anchors.fill: parent
                                        captureSource: root.shown ? win.modelData.wayland : null
                                        live: root.shown
                                        constraintSize: Qt.size(width, height)
                                    }

                                    // no preview yet (or capture unavailable): the app's icon
                                    IconImage {
                                        visible: !preview.hasContent
                                        anchors.centerIn: parent
                                        implicitSize: Math.min(parent.width, parent.height) * 0.45
                                        source: Apps.iconForClass(win.appId)
                                    }

                                    // drawn last so it sits on top of the preview
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: Appearance.rounding.small - 2
                                        color: "transparent"
                                        border.width: winArea.containsMouse && !root.dragging ? 2 : 0
                                        border.color: Colors.primary
                                    }
                                }

                                MouseArea {
                                    id: winArea

                                    property point pressAt
                                    property bool moved: false

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                                    cursorShape: root.dragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                                    onEntered: if (!root.dragging) root.selected = ws.index

                                    onPressed: mouse => {
                                        pressAt = Qt.point(mouse.x, mouse.y);
                                        moved = false;
                                    }
                                    onPositionChanged: mouse => {
                                        if (!pressed || mouse.buttons !== Qt.LeftButton)
                                            return;
                                        if (!moved && Math.abs(mouse.x - pressAt.x) + Math.abs(mouse.y - pressAt.y) > 6) {
                                            moved = true;
                                            root.dragging = win.modelData;
                                            ghost.appId = win.appId;
                                        }
                                        if (moved) {
                                            const p = mapToItem(root.contentItem, mouse.x, mouse.y);
                                            ghost.x = p.x - ghost.width / 2;
                                            ghost.y = p.y - ghost.height / 2;
                                            root.dropTarget = root.cardAt(p.x, p.y);
                                        }
                                    }
                                    onReleased: mouse => {
                                        if (moved) {
                                            const t = root.dragging;
                                            const target = root.dropTarget;
                                            root.dragging = null;
                                            root.dropTarget = -1;
                                            if (t && target > 0 && target !== ws.wsId)
                                                root.moveWindow(t, target);
                                        }
                                    }
                                    onClicked: mouse => {
                                        if (moved)
                                            return;
                                        if (mouse.button === Qt.MiddleButton)
                                            root.closeWindow(win.modelData);
                                        else
                                            root.focusWindow(win.modelData);
                                    }
                                }
                            }
                        }
                    }

                    // workspace number
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.margins: 8
                        implicitWidth: Math.max(implicitHeight, num.implicitWidth + 14)
                        implicitHeight: 24
                        radius: height / 2
                        color: ws.active ? Colors.primary : Colors.alpha(Colors.surfaceContainerHighest, 0.85)

                        StyledText {
                            id: num
                            anchors.centerIn: parent
                            text: ws.windows.length === 0 && ws.index === root.ids.length - 1 && !ws.active ? "+" : ws.wsId
                            font.weight: Font.DemiBold
                            font.pixelSize: Appearance.font.small
                            color: ws.active ? Colors.textOnPrimary : Colors.textOnSurface
                        }
                    }

                    StyledText {
                        visible: ws.windows.length === 0
                        anchors.centerIn: parent
                        text: root.dragging ? "Drop here" : ws.index === root.ids.length - 1 && !ws.active ? "New workspace" : "Empty"
                        color: Colors.outline
                    }
                }
            }
        }

        StyledText {
            id: hint
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: Appearance.padding.large
            text: "Click to go · drag a window to move it · middle-click closes · ←→ Enter · Esc"
            font.pixelSize: Appearance.font.small
            color: Colors.textOnSurfaceVariant
        }
    }

    // The window being dragged: its icon follows the pointer
    Rectangle {
        id: ghost

        property string appId: ""

        visible: root.dragging !== null
        width: 64
        height: 64
        radius: Appearance.rounding.normal
        color: Colors.primaryContainer
        border.width: 2
        border.color: Colors.primary

        IconImage {
            anchors.centerIn: parent
            implicitSize: 40
            source: Apps.iconForClass(ghost.appId)
        }
    }
}
