//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma IconTheme Papirus-Dark

import Quickshell
import Quickshell.Io
import qs.modules.bar
import qs.modules.dashboard
import qs.modules.launcher
import qs.modules.keybinds
import qs.modules.lock
import qs.modules.notifications
import qs.modules.osd
import qs.modules.session
import qs.services

ShellRoot {
    Variants {
        model: Quickshell.screens

        Bar {}
    }

    Launcher {}
    Popups {}
    Center {}
    Osd {}
    Dashboard {}
    Session {}
    Lock {}
    UpdatesMenu {}
    Keybinds {}

    // `qs ipc call rice <function> [args]` — used by Hyprland keybinds.
    IpcHandler {
        target: "rice"

        function workspace(id: string): void {
            Hypr.focusWorkspace(isNaN(Number(id)) ? id : Number(id));
        }

        // mode: apps | wallpapers | clipboard
        function launcher(mode: string): void {
            Panels.toggleLauncher(mode || "apps");
        }

        // name: dashboard | notifications | session
        function toggle(name: string): void {
            Panels.toggle(name);
        }

        // Dashboard opened on the network page
        function network(): void {
            Panels.current = "dashboard";
            Qt.callLater(() => Panels.dashboardPage = "network");
        }

        // action: up | down | mute | mic
        function volume(action: string): void {
            if (action === "up")
                Audio.setVolume(Audio.volume + 0.05);
            else if (action === "down")
                Audio.setVolume(Audio.volume - 0.05);
            else if (action === "mute")
                Audio.toggleMute();
            else if (action === "mic")
                Audio.toggleMicMute();
        }

        // action: up | down
        function brightness(action: string): void {
            Brightness.set(action === "up" ? "5%+" : "5%-");
        }

        function lock(): void {
            LockState.locked = true;
        }

        function dnd(): void {
            Notifs.dnd = !Notifs.dnd;
        }

        // where: auto | college | home (weather location)
        function place(where: string): void {
            Place.choose(where);
        }

        function checkUpdates(): void {
            Updates.check();
        }

        function update(): void {
            Updates.update();
        }

        function trash(): void {
            Trash.open();
        }

        function clearNotifications(): void {
            Notifs.clearAll();
        }
    }
}
