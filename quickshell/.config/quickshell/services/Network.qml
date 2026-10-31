pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking

// Network state from NetworkManager: current connection, Wi-Fi networks, Ethernet adapters.
Singleton {
    id: root

    readonly property var devices: Networking.devices.values
    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool wired: devices.some(d => d.type === DeviceType.Wired && d.connected)

    readonly property var wifiDevice: devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wiredDevices: devices.filter(d => d.type === DeviceType.Wired && d.nmManaged)   // skips VirtualBox etc.

    // The connected Wi-Fi network, or null
    readonly property var wifi: wifiDevice?.networks.values.find(n => n.connected) ?? null
    readonly property real strength: wifi?.signalStrength ?? 0   // 0..1
    readonly property bool online: wired || wifi !== null

    // Visible Wi-Fi networks: connected first, then saved, then by signal. Hidden SSIDs skipped.
    readonly property var networks: {
        if (!wifiDevice)
            return [];
        const seen = new Set();
        return [...wifiDevice.networks.values]
            .filter(n => n.name && !seen.has(n.name) && seen.add(n.name))
            .sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength));
    }

    function signalIcon(s: real): string {
        return s > 0.75 ? "signal_wifi_4_bar" : s > 0.5 ? "network_wifi_3_bar" : s > 0.25 ? "network_wifi_2_bar" : "network_wifi_1_bar";
    }

    function isSecured(n): bool {
        return n.security !== WifiSecurityType.Open && n.security !== WifiSecurityType.Unknown;
    }

    // Scan for networks while something (the network page) needs a fresh list
    function setScanning(on: bool): void {
        if (wifiDevice)
            wifiDevice.scannerEnabled = on;
    }

    readonly property string icon: {
        if (wired)
            return "lan";
        if (wifi)
            return signalIcon(strength);
        return wifiEnabled ? "signal_wifi_0_bar" : "signal_wifi_off";
    }
}
