pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Clipboard history from cliphist.
Singleton {
    id: root

    // [{ line, id, text, isImage }]
    property list<var> entries: []

    function refresh(): void {
        lister.running = true;
    }

    function copy(entry): void {
        Quickshell.execDetached(["bash", "-c", 'printf "%s" "$1" | cliphist decode | wl-copy', "_", entry.line]);
    }

    function remove(entry): void {
        Quickshell.execDetached(["bash", "-c", 'printf "%s" "$1" | cliphist delete', "_", entry.line]);
        entries = entries.filter(e => e.id !== entry.id);
    }

    Process {
        id: lister
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: root.entries = text.split("\n").filter(Boolean).map(line => {
                const tab = line.indexOf("\t");
                const body = line.slice(tab + 1);
                const img = body.match(/^\[\[ binary data (.+?) (\w+) (\d+x\d+) \]\]$/);
                return {
                    line: line,
                    id: line.slice(0, tab),
                    text: img ? `Image · ${img[3]} · ${img[1]}` : body,
                    isImage: img !== null
                };
            })
        }
    }
}
