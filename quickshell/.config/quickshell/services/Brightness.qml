pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Screen brightness through brightnessctl. Uses the same exponential curve (-e4)
// as the brightness keys, so steps feel even.
Singleton {
    id: root

    property real value: 0   // 0..1, perceptual

    // change: brightnessctl syntax, e.g. "5%+", "5%-", "40%"
    function set(change: string): void {
        proc.command = ["brightnessctl", "-e4", "-n2", "-m", "set", change];
        proc.running = true;
    }

    function setValue(v: real): void {
        set(`${Math.round(Math.max(0.02, Math.min(1, v)) * 100)}%`);
    }

    function parse(out: string): void {
        // device,class,current,percent,max
        const pct = parseInt(out.trim().split(",")[3]);
        if (!isNaN(pct))
            value = pct / 100;
    }

    Process {
        id: proc
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    Component.onCompleted: set("+0%")
}
