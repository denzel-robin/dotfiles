pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Pending package updates (repo via checkupdates, AUR via yay). Checks online 10 s
// after start and hourly after that (the AUR rate-limits frequent checks); a cheap
// local watch updates the count within 10 s of any install. No notifications:
// the count just shows on the bar's updates island.
Singleton {
    id: root

    property list<var> packages: []   // [{ name, from, to, aur, restart }]
    property bool checking: false
    property bool updating: false
    property date lastChecked
    property bool everChecked: false

    readonly property int count: packages.length
    readonly property int aurCount: packages.filter(p => p.aur).length
    // "reboot" (kernel/driver) beats "re-login" (compositor/shell) beats ""
    readonly property string restart: packages.some(p => p.restart === "reboot") ? "reboot" : packages.some(p => p.restart === "re-login") ? "re-login" : ""

    function restartFor(name: string): string {
        if (/^(linux(-lts|-zen|-hardened)?|linux-firmware.*|nvidia.*|amd-ucode|intel-ucode|systemd)$/.test(name))
            return "reboot";
        if (/^(hyprland|quickshell|aquamarine|hyprutils|hyprlang|xdg-desktop-portal-hyprland|mesa|wayland)$/.test(name))
            return "re-login";
        return "";
    }

    function check(): void {
        if (checking || updating)
            return;
        checking = true;
        checker.running = true;
    }

    // Floating terminal: pacman -Syu, then (only if that worked) AUR updates; re-checks when it closes
    function update(): void {
        if (updating)
            return;
        updating = true;
        updater.running = true;
    }

    Process {
        id: checker
        // checkupdates exits 0 = updates, 2 = none, anything else = failed (e.g. no network yet)
        command: ["bash", "-c", "checkupdates 2>/dev/null; echo \"--RC $?--\"; echo '--AUR--'; yay -Qua 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const rc = parseInt((text.match(/--RC (\d+)--/) ?? [])[1]);
                if (rc !== 0 && rc !== 2) {
                    // Couldn't reach the mirrors: keep what we had and try again soon
                    root.checking = false;
                    retry.restart();
                    return;
                }
                const list = [];
                let aur = false;
                for (const line of text.split("\n")) {
                    if (line === "--AUR--") {
                        aur = true;
                        continue;
                    }
                    // "name old -> new [age]"
                    const m = line.match(/^(\S+)\s+(\S+)\s+->\s+(\S+)/);
                    if (m)
                        list.push({ name: m[1], from: m[2], to: m[3], aur, restart: root.restartFor(m[1]) });
                }
                root.packages = list.sort((a, b) => (a.restart === "") - (b.restart === "") || a.name.localeCompare(b.name));
                root.lastChecked = new Date();
                root.everChecked = true;
                root.checking = false;
            }
        }
    }

    Process {
        id: updater
        command: ["kitty", "--class", "rice-update", "--title", "System update", "-e", "bash", "-c",
            // Repo first with pacman; AUR only if that succeeded (-Sua = AUR packages only)
            "echo -e '\\e[1m[1/2] Repo packages: sudo pacman -Syu\\e[0m\\n' && sudo pacman -Syu && echo -e '\\n\\e[1m[2/2] AUR packages: yay -Sua\\e[0m\\n' && yay -Sua; echo; read -rsn1 -p 'Done. Press any key to close.'"]
        onExited: {
            root.updating = false;
            root.check();
        }
    }

    // First check 10 s after start (failed checks retry in 5 min), then hourly
    Timer {
        interval: 10 * 1000
        running: true
        onTriggered: {
            root.check();
            hourly.running = true;
        }
    }

    // ── Local watch: every 10 s, has the installed-package database changed? ──
    // (1 ms, no network.) If so — you updated in a terminal, or through the
    // button — drop the packages that are now at their new version (pacman -Q, ~10 ms).
    property string dbStamp: ""

    Timer {
        interval: 10 * 1000
        running: true
        repeat: true
        onTriggered: dbWatch.running = true
    }

    Process {
        id: dbWatch
        command: ["stat", "-c", "%Y", "/var/lib/pacman/local"]
        stdout: StdioCollector {
            onStreamFinished: {
                const stamp = text.trim();
                if (root.dbStamp && stamp !== root.dbStamp && root.count > 0)
                    installed.running = true;
                root.dbStamp = stamp;
            }
        }
    }

    Process {
        id: installed
        command: ["pacman", "-Q"]
        stdout: StdioCollector {
            onStreamFinished: {
                const have = {};
                for (const line of text.split("\n")) {
                    const [name, version] = line.split(" ");
                    if (name)
                        have[name] = version;
                }
                // still pending = installed and not yet at the new version
                root.packages = root.packages.filter(p => have[p.name] && have[p.name] !== p.to);
            }
        }
    }

    Timer {
        id: retry
        interval: 5 * 60 * 1000
        onTriggered: root.check()
    }

    Timer {
        id: hourly
        interval: 60 * 60 * 1000
        repeat: true
        onTriggered: root.check()
    }
}
