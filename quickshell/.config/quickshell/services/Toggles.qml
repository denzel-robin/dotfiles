pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.UPower

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
    readonly property int profile: PowerProfiles.profile
    readonly property string profileName: profile === PowerProfile.PowerSaver ? "Saver" : profile === PowerProfile.Performance ? "Performance" : "Balanced"
    readonly property string profileIcon: profile === PowerProfile.PowerSaver ? "energy_savings_leaf" : profile === PowerProfile.Performance ? "bolt" : "balance"
    function cycleProfile(): void {
        const next = profile === PowerProfile.PowerSaver ? "balanced" : profile === PowerProfile.Balanced && PowerProfiles.hasPerformanceProfile ? "performance" : "power-saver";
        Quickshell.execDetached(["powerprofilesctl", "set", next]);
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
