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
}
