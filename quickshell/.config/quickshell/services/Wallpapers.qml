pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Wallpapers in ~/Pictures/Wallpapers, plus the current one and light/dark mode.
Singleton {
    id: root

    readonly property string dir: `${Quickshell.env("HOME")}/Pictures/Wallpapers`
    property list<string> files: []
    readonly property string current: currentFile.text().trim()
    readonly property string mode: modeFile.text().trim() || "dark"

    function refresh(): void {
        lister.running = true;
    }

    function set(path: string): void {
        Quickshell.execDetached(["rice-wall", path]);
    }

    function setMode(m: string): void {
        Quickshell.execDetached(["rice-wall", "", m]);
    }

    Process {
        id: lister
        command: ["find", root.dir, "-maxdepth", "1", "-type", "f", "(", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.png", "-o", "-iname", "*.webp", "-o", "-iname", "*.gif", ")"]
        stdout: StdioCollector {
            onStreamFinished: root.files = text.split("\n").filter(Boolean).sort((a, b) => a.localeCompare(b))
        }
    }

    FileView {
        id: currentFile
        path: `${Quickshell.env("HOME")}/.local/state/rice/wallpaper`
        watchChanges: true
        onFileChanged: reload()
    }

    FileView {
        id: modeFile
        path: `${Quickshell.env("HOME")}/.local/state/rice/mode`
        watchChanges: true
        onFileChanged: reload()
    }

    Component.onCompleted: refresh()
}
