pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// Hyprland helpers. This Hyprland uses the Lua config, so dispatches are Lua
// expressions (`hl.dsp.focus({ workspace = 3 })`), not the old `workspace 3`.
Singleton {
    // Ids of workspaces that currently exist (have windows or are shown), ignoring special ones
    readonly property list<int> occupiedIds: Hyprland.workspaces.values.filter(w => w.id > 0).map(w => w.id)

    // App id of every window on a workspace, in window order (one entry per window)
    function appsOn(wsId: int): list<string> {
        const ws = Hyprland.workspaces.values.find(w => w.id === wsId);
        if (!ws)
            return [];
        return ws.toplevels.values.map(t => t.wayland?.appId || t.lastIpcObject?.class || "").filter(Boolean);
    }

    function dispatch(lua: string): void {
        Hyprland.dispatch(lua);
    }

    // id: a number, or a relative string like "e+1"
    function focusWorkspace(id): void {
        dispatch(`hl.dsp.focus({ workspace = ${typeof id === "string" ? `"${id}"` : id} })`);
    }

    function activeWorkspaceId(screen: ShellScreen): int {
        return Hyprland.monitorFor(screen)?.activeWorkspace?.id ?? 1;
    }
}
