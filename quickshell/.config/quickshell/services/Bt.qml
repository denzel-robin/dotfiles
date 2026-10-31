pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth

// Bluetooth state. `available` is false when bluez isn't installed/running.
Singleton {
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property bool connected: Bluetooth.devices.values.some(d => d.connected)

    readonly property string icon: !enabled ? "bluetooth_disabled" : connected ? "bluetooth_connected" : "bluetooth"
}
