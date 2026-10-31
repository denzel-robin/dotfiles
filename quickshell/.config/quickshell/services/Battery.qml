pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower

Singleton {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property bool present: device?.isLaptopBattery ?? false
    readonly property real charge: device?.percentage ?? 0   // 0..1
    readonly property bool charging: [UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged, UPowerDeviceState.PendingCharge].includes(device?.state)
    readonly property bool low: charge < 0.15 && !charging

    readonly property string icon: {
        if (charging)
            return "battery_charging_full";
        const bars = Math.round(charge * 6);
        return bars >= 6 ? "battery_full" : `battery_${bars}_bar`;
    }
}
