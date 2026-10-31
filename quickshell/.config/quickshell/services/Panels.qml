pragma Singleton

import QtQuick
import Quickshell

// Which popup panel is open. Only one at a time.
Singleton {
    id: root

    // "launcher" | "dashboard" | "session" | "notifications" | "updates" | ""
    property string current: ""
    property string launcherMode: "apps"   // "apps" | "wallpapers" | "clipboard"
    property string dashboardPage: ""      // "" (overview) | "network"
    property real bellBottom: 0
    property real updatesBottom: 0         // same, for the updates island            // y of the bell island's bottom edge, for the notification menu

    // Hover only selects when the mouse really moves, not when a list opens or
    // scrolls underneath a still pointer.
    property var lastPointer: null
    onCurrentChanged: lastPointer = null

    function pointerMoved(item: Item, x: real, y: real): bool {
        const p = item.mapToGlobal(x, y);
        const moved = lastPointer !== null && Math.abs(p.x - lastPointer.x) + Math.abs(p.y - lastPointer.y) > 1;
        lastPointer = p;
        return moved;
    }

    function toggle(name: string): void {
        current = current === name ? "" : name;
    }

    function close(): void {
        current = "";
    }

    // Opens the launcher in `mode`; closes it if it's already open in that mode.
    function toggleLauncher(mode: string): void {
        if (current === "launcher" && launcherMode === mode) {
            close();
        } else {
            launcherMode = mode;
            current = "launcher";
        }
    }
}
