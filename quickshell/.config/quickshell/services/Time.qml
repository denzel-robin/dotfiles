pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property date date: new Date()
    readonly property string hours: Qt.formatTime(date, "hh")
    readonly property string minutes: Qt.formatTime(date, "mm")

    function format(fmt: string): string {
        return Qt.formatDateTime(date, fmt);
    }

    SystemClock {
        precision: SystemClock.Minutes
        onDateChanged: root.date = date
    }
}
