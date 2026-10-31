pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Trash size and actions (via `rice-trash`). Items older than `days` are removed
// daily by the rice-trash-purge systemd timer.
Singleton {
    id: root

    readonly property int days: 30
    property int items: 0
    property real bytes: 0

    readonly property string size: bytes >= 1e9 ? `${(bytes / 1e9).toFixed(1)} GB` : bytes >= 1e6 ? `${(bytes / 1e6).toFixed(1)} MB` : bytes >= 1e3 ? `${Math.round(bytes / 1e3)} KB` : `${bytes} B`

    function refresh(): void {
        stats.running = true;
    }

    function open(): void {
        Quickshell.execDetached(["kitty", "--class", "yazi", "-e", "yazi", `${Quickshell.env("HOME")}/.local/share/Trash/files`]);
    }

    function empty(): void {
        emptier.running = true;
    }

    Process {
        id: stats
        command: ["rice-trash", "stats"]
        stdout: StdioCollector {
            onStreamFinished: {
                const [n, b] = text.trim().split(" ").map(Number);
                root.items = n || 0;
                root.bytes = b || 0;
            }
        }
    }

    Process {
        id: emptier
        command: ["rice-trash", "empty"]
        onExited: root.refresh()
    }

    // Keep the numbers fresh while the dashboard is open
    Timer {
        interval: 3000
        running: Panels.current === "dashboard"
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
