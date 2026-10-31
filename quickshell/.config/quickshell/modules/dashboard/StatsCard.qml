import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

// Live system usage (updates every 2 s while the dashboard is open).
Tile {
    ColumnLayout {
        width: parent.width
        spacing: Appearance.spacing.normal

        Repeater {
            model: [
                { icon: "memory", label: "CPU", value: SysStats.cpu, text: `${Math.round(SysStats.cpu * 100)}%`, extra: SysStats.cpuTemp ? `${Math.round(SysStats.cpuTemp)}°C` : "" },
                { icon: "memory_alt", label: "RAM", value: SysStats.mem, text: `${SysStats.memUsedGb.toFixed(1)} / ${Math.round(SysStats.memTotalGb)} GB`, extra: "" },
                { icon: "hard_drive", label: "Disk", value: SysStats.disk, text: `${Math.round(SysStats.diskUsedGb)} / ${Math.round(SysStats.diskTotalGb)} GB`, extra: "" },
                { icon: "developer_board", label: "GPU", value: SysStats.gpuAwake ? SysStats.gpu : 0, text: SysStats.gpuAwake ? `${Math.round(SysStats.gpu * 100)}%` : "Sleeping", extra: SysStats.gpuAwake && SysStats.gpuTemp ? `${Math.round(SysStats.gpuTemp)}°C` : "" }
            ]

            RowLayout {
                id: stat

                required property var modelData
                readonly property color barColor: modelData.value > 0.85 ? Colors.error : modelData.value > 0.65 ? Colors.tertiary : Colors.primary

                Layout.fillWidth: true
                spacing: Appearance.spacing.normal

                MaterialIcon {
                    icon: stat.modelData.icon
                    size: 18
                    color: Colors.textOnSurfaceVariant
                }

                StyledText {
                    Layout.preferredWidth: 34
                    text: stat.modelData.label
                    font.weight: Font.Medium
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 8
                    radius: 4
                    color: Colors.surfaceContainerHighest

                    Rectangle {
                        width: parent.width * Math.min(1, stat.modelData.value)
                        height: parent.height
                        radius: 4
                        color: stat.barColor

                        Behavior on width { Anim {} }
                        Behavior on color { CAnim { duration: Appearance.anim.fast } }
                    }
                }

                StyledText {
                    Layout.preferredWidth: 92
                    horizontalAlignment: Text.AlignRight
                    text: stat.modelData.extra ? `${stat.modelData.text} · ${stat.modelData.extra}` : stat.modelData.text
                    font.pixelSize: Appearance.font.small
                    color: Colors.textOnSurfaceVariant
                }
            }
        }
    }
}
