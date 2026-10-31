pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Clipboard history from cliphist. Images get small thumbnails, made in the
// background and cached in ~/.cache/rice/clip/<id>.png (stale ones are pruned).
Singleton {
    id: root

    readonly property string thumbDir: `${Quickshell.env("HOME")}/.cache/rice/clip`

    // [{ line, id, text, isImage, thumb }]
    property list<var> entries: []

    function refresh(): void {
        lister.running = true;
    }

    function copy(entry): void {
        Quickshell.execDetached(["bash", "-c", 'printf "%s" "$1" | cliphist decode | wl-copy', "_", entry.line]);
    }

    function remove(entry): void {
        Quickshell.execDetached(["bash", "-c", 'printf "%s" "$1" | cliphist delete; rm -f "$2"/"$3".png', "_", entry.line, thumbDir, entry.id]);
        entries = entries.filter(e => e.id !== entry.id);
    }

    function withThumbs(ready): void {
        entries = entries.map(e => Object.assign({}, e, { thumb: e.isImage && ready.includes(e.id) ? `file://${thumbDir}/${e.id}.png` : "" }));
    }

    Process {
        id: lister
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.entries = text.split("\n").filter(Boolean).map(line => {
                    const tab = line.indexOf("\t");
                    const body = line.slice(tab + 1);
                    const img = body.match(/^\[\[ binary data (.+?) (\w+) (\d+x\d+) \]\]$/);
                    return {
                        line: line,
                        id: line.slice(0, tab),
                        text: img ? `Image · ${img[3]} · ${img[1]}` : body,
                        isImage: img !== null,
                        thumb: ""
                    };
                });
                thumber.running = true;
            }
        }
    }

    // Thumbnails for the newest 60 images; prints the ids that have one
    Process {
        id: thumber
        command: ["bash", "-c", `
            dir="$1"; mkdir -p "$dir"
            list=$(cliphist list | grep -P '^\\d+\\t\\[\\[ binary data ' | head -60)
            keep=" "
            while IFS= read -r line; do
                [ -n "$line" ] || continue
                id=\${line%%$'\\t'*}; keep="$keep$id "
                f="$dir/$id.png"
                [ -s "$f" ] || printf '%s\\n' "$line" | cliphist decode | magick - -thumbnail '640x320>' "png:$f" 2>/dev/null || rm -f "$f"
                [ -s "$f" ] && echo "$id"
            done <<< "$list"
            for f in "$dir"/*.png; do
                [ -e "$f" ] || continue
                id=$(basename "$f" .png); [[ "$keep" == *" $id "* ]] || rm -f "$f"
            done
        `, "_", root.thumbDir]
        stdout: StdioCollector {
            onStreamFinished: root.withThumbs(text.split("\n").filter(Boolean))
        }
    }
}
