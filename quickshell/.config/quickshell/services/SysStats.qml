pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// CPU, memory, disk, temperatures and the NVIDIA GPU. Only polls while `active`
// (the dashboard is open). The GPU is only queried when it's already awake, so
// opening the dashboard never wakes the RTX 3050 and drains the battery.
Singleton {
    id: root

    readonly property bool active: Panels.current === "dashboard"

    property real cpu: 0          // 0..1
    property real cpuTemp: 0      // °C
    property real mem: 0          // 0..1
    property real memUsedGb: 0
    property real memTotalGb: 0
    property real disk: 0         // 0..1
    property real diskUsedGb: 0
    property real diskTotalGb: 0
    property bool gpuAwake: false
    property real gpu: 0          // 0..1
    property real gpuTemp: 0
    property string uptime: ""

    property var lastCpu: null
    property string cpuTempPath: ""

    function poll(): void {
        stat.reload();
        meminfo.reload();
        uptimeFile.reload();
        gpuState.reload();
        if (cpuTempPath)
            cpuTempFile.reload();
        diskProc.running = true;
    }

    Timer {
        interval: 2000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: root.poll()
    }

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const f = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = f[3] + f[4];
            const total = f.reduce((a, b) => a + b, 0);
            if (root.lastCpu) {
                const dt = total - root.lastCpu.total;
                root.cpu = dt > 0 ? 1 - (idle - root.lastCpu.idle) / dt : 0;
            }
            root.lastCpu = { idle, total };
        }
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: {
            const kb = key => parseInt(text().match(new RegExp(`${key}:\\s+(\\d+)`))[1]);
            const total = kb("MemTotal"), avail = kb("MemAvailable");
            root.memTotalGb = total / 1048576;
            root.memUsedGb = (total - avail) / 1048576;
            root.mem = (total - avail) / total;
        }
    }

    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        onLoaded: {
            const s = Math.floor(parseFloat(text()));
            const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60);
            root.uptime = d > 0 ? `${d}d ${h}h` : h > 0 ? `${h}h ${m}m` : `${m}m`;
        }
    }

    FileView {
        id: cpuTempFile
        path: root.cpuTempPath
        onLoaded: root.cpuTemp = parseInt(text()) / 1000
    }

    // dGPU power state: "active" or "suspended"
    FileView {
        id: gpuState
        path: "/sys/bus/pci/devices/0000:01:00.0/power/runtime_status"
        onLoaded: {
            root.gpuAwake = text().trim() === "active";
            if (root.gpuAwake)
                gpuProc.running = true;
        }
    }

    Process {
        id: gpuProc
        command: ["nvidia-smi", "--query-gpu=utilization.gpu,temperature.gpu", "--format=csv,noheader,nounits"]
        stdout: StdioCollector {
            onStreamFinished: {
                const [util, temp] = text.trim().split(",").map(Number);
                root.gpu = (util || 0) / 100;
                root.gpuTemp = temp || 0;
            }
        }
    }

    Process {
        id: diskProc
        command: ["df", "-B1", "--output=used,size", "/"]
        stdout: StdioCollector {
            onStreamFinished: {
                const [used, size] = text.trim().split("\n").pop().trim().split(/\s+/).map(Number);
                root.diskUsedGb = used / 1e9;
                root.diskTotalGb = size / 1e9;
                root.disk = used / size;
            }
        }
    }

    // hwmon numbers change between boots, so find the AMD CPU sensor by name
    Process {
        running: true
        command: ["bash", "-c", "for h in /sys/class/hwmon/hwmon*; do [ \"$(cat $h/name)\" = k10temp ] && echo $h/temp1_input && break; done"]
        stdout: StdioCollector {
            onStreamFinished: root.cpuTempPath = text.trim()
        }
    }
}
