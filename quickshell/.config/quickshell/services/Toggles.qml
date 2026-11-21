pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

// State and actions for the dashboard's quick toggles.
Singleton {
    id: root

    // ── Wi-Fi ──
    readonly property bool wifi: Networking.wifiEnabled
    function toggleWifi(): void {
        Networking.wifiEnabled = !Networking.wifiEnabled;
    }

    // ── Bluetooth ──
    function toggleBluetooth(): void {
        if (Bt.available)
            Bt.adapter.enabled = !Bt.adapter.enabled;
    }

    // ── Cloudflare WARP ──
    property bool warp: false
    property bool warpBusy: false
    function toggleWarp(): void {
        warpBusy = true;
        Quickshell.execDetached(["warp-cli", "--accept-tos", root.warp ? "disconnect" : "connect"]);
        warpRecheck.restart();
    }
    function refreshWarp(): void {
        warpStatus.running = true;
    }
    Process {
        id: warpStatus
        command: ["warp-cli", "--accept-tos", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.warp = /Status update:\s*Connected/.test(text);
                root.warpBusy = /Connecting/.test(text);
            }
        }
    }
    Timer {
        id: warpRecheck
        interval: 1500
        onTriggered: root.refreshWarp()
    }
    Timer {
        interval: 5000
        running: Panels.current === "dashboard"
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshWarp()
    }

    // ── Power profile ──
    // Read with powerprofilesctl in the background rather than Quickshell's PowerProfiles
    // service: that one waits for power-profiles-daemon, which only starts once boot has
    // finished (after the Wi-Fi connects), and held up the whole shell for ~13 s after login.
    property string profile: "balanced"           // "power-saver" | "balanced" | "performance"
    property bool hasPerformance: true
    readonly property string profileName: profile === "power-saver" ? "Saver" : profile === "performance" ? "Performance" : "Balanced"
    readonly property string profileIcon: profile === "power-saver" ? "energy_savings_leaf" : profile === "performance" ? "bolt" : "balance"
    function cycleProfile(): void {
        const next = profile === "power-saver" ? "balanced" : profile === "balanced" && hasPerformance ? "performance" : "power-saver";
        profile = next;   // show it straight away
        profileSet.command = ["powerprofilesctl", "set", next];
        profileSet.running = true;
    }

    Process {
        id: profileSet
        onExited: profileGet.running = true
    }

    Process {
        id: profileGet
        command: ["powerprofilesctl", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const current = (text.match(/^\* (\S+):/m) ?? [])[1];
                if (current)
                    root.profile = current;
                root.hasPerformance = /^\*?\s*performance:/m.test(text);
            }
        }
    }

    // Also catches changes made elsewhere (powerprofilesctl, power button, …)
    Timer {
        interval: 20000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: profileGet.running = true
    }

    // ── Night light (hyprsunset) ──
    property bool nightLight: false
    Process {
        running: root.nightLight
        command: ["hyprsunset", "-t", "4200"]
    }

    // ── Battery charge limit (stop charging at 95 %, kinder to the battery) ──
    // The kernel resets the limit to 100 on boot (and the firmware sometimes on resume),
    // so the saved choice is re-applied at start and checked every minute.
    // Writing it needs the udev rule from ~/dotfiles/system/ (makes it writable by wheel).
    readonly property int chargeLimitValue: 95
    property bool chargeLimit: false
    property int chargeLimitNow: 100     // what the battery is set to right now
    property bool chargeLimitWritable: false
    property bool chargeLimitSupported: false

    function toggleChargeLimit(): void {
        chargeLimit = !chargeLimit;
        chargeLimitFile.setText(chargeLimit ? "on\n" : "off\n");
        applyChargeLimit();
    }
    function applyChargeLimit(): void {
        chargeProc.command = ["sh", "-c", `
            f=$(ls /sys/class/power_supply/BAT*/charge_control_end_threshold 2>/dev/null | head -1)
            [ -n "$f" ] || { echo none; exit; }
            [ -w "$f" ] && [ "$(cat "$f")" != "$1" ] && echo "$1" > "$f"
            [ -w "$f" ] && echo "w $(cat "$f")" || echo "r $(cat "$f")"
        `, "_", String(chargeLimit ? chargeLimitValue : 100)];
        chargeProc.running = true;
    }
    Process {
        id: chargeProc
        stdout: StdioCollector {
            onStreamFinished: {
                const [mode, value] = text.trim().split(" ");
                root.chargeLimitSupported = mode !== "none";
                root.chargeLimitWritable = mode === "w";
                root.chargeLimitNow = parseInt(value) || 100;
            }
        }
    }
    FileView {
        id: chargeLimitFile
        path: `${Quickshell.env("HOME")}/.local/state/rice/charge-limit`
        printErrors: false
        onLoaded: {
            root.chargeLimit = text().trim() === "on";
            root.applyChargeLimit();
        }
        onLoadFailed: root.applyChargeLimit()
    }
    Timer {
        interval: 60 * 1000
        running: true
        repeat: true
        onTriggered: root.applyChargeLimit()
    }
}
