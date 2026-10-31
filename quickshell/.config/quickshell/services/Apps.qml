pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Installed applications: search, ranking and launching. Apps you launch more
// often come first, also while searching (counts kept in ~/.local/state/rice/launcher-usage.json).
Singleton {
    id: root

    property var usage: ({})

    readonly property var all: [...DesktopEntries.applications.values]
        .filter(e => !e.noDisplay)
        .sort((a, b) => a.name.localeCompare(b.name))

    function search(query: string): var {
        const q = query.trim().toLowerCase();
        if (!q)
            return all.slice().sort((a, b) => (usage[b.id] ?? 0) - (usage[a.id] ?? 0) || a.name.localeCompare(b.name));

        // Group by what matched (name > description/keywords > comment > letters-in-order),
        // then most-launched first, then match quality, then name
        const tier = sc => sc >= 90 ? 3 : sc >= 50 ? 2 : sc >= 20 ? 1 : 0;
        const hits = [];
        for (const e of all) {
            const sc = score(e, q);
            if (sc > 0)
                hits.push({ entry: e, score: sc, uses: usage[e.id] ?? 0 });
        }
        hits.sort((a, b) => tier(b.score) - tier(a.score) || b.uses - a.uses || b.score - a.score || a.entry.name.localeCompare(b.entry.name));
        return hits.map(h => h.entry);
    }

    function score(e, q: string): int {
        const name = e.name.toLowerCase();
        if (name === q)
            return 200;
        if (name.startsWith(q))
            return 150;
        if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q)))
            return 120;
        if (name.includes(q))
            return 90;
        if ((e.genericName ?? "").toLowerCase().includes(q))
            return 60;
        if ((e.keywords ?? []).some(k => k.toLowerCase().includes(q)))
            return 50;
        if ((e.comment ?? "").toLowerCase().includes(q))
            return 20;
        // letters in order, e.g. "lbo" -> LibreOffice
        let i = 0;
        for (const c of name)
            if (c === q[i])
                i++;
        return i === q.length ? 10 : 0;
    }

    // Icon url for an entry (theme name or absolute path); "" if the theme has none
    function iconFor(e): string {
        const i = e?.icon ?? "";
        // The ?v= tag makes generated icons (e.g. the themed terminal) reload when colours change
        if (i.startsWith("/"))
            return `file://${i}?v=${Colors.primary}`;
        return Quickshell.iconPath(i, true);
    }

    // Icon for a window's app id / class (e.g. "kitty", "zen"); "" if none found
    function iconForClass(cls: string): string {
        void all.length;   // re-run when desktop entries change (e.g. an icon override is added)
        if (!cls)
            return "";
        const entry = DesktopEntries.heuristicLookup(cls);
        return entry ? iconFor(entry) : Quickshell.iconPath(cls.toLowerCase(), true);
    }

    // ── NVIDIA GPU (PRIME render offload) ──
    // Apps render on the AMD iGPU by default; these variables move an app to the RTX 3050.
    readonly property list<string> gpuEnv: [
        "__NV_PRIME_RENDER_OFFLOAD=1",
        "__GLX_VENDOR_LIBRARY_NAME=nvidia",
        "__VK_LAYER_NV_optimus=NVIDIA_only",
        "__EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/10_nvidia.json"
    ]
    property var gpuApps: ({})   // app id -> true: always open on the NVIDIA GPU

    function alwaysGpu(e): bool {
        return gpuApps[e?.id] === true;
    }

    function toggleAlwaysGpu(e): void {
        const g = Object.assign({}, gpuApps);
        if (g[e.id])
            delete g[e.id];
        else
            g[e.id] = true;
        gpuApps = g;
        gpuFile.setText(JSON.stringify(gpuApps));
    }

    // gpu: open on the NVIDIA GPU this time (apps marked "always" use it anyway)
    function launch(e, gpu): void {
        usage[e.id] = (usage[e.id] ?? 0) + 1;
        usageFile.setText(JSON.stringify(usage));
        usageChanged();

        const cmd = e.runInTerminal ? ["kitty", "-e", ...e.command] : [...e.command];
        if (gpu || alwaysGpu(e))
            Quickshell.execDetached(["env", ...gpuEnv, ...cmd]);
        else if (e.runInTerminal)
            Quickshell.execDetached(cmd);
        else
            e.execute();
    }

    FileView {
        id: gpuFile
        path: `${Quickshell.env("HOME")}/.local/state/rice/gpu-apps.json`
        printErrors: false
        onLoaded: {
            try {
                root.gpuApps = JSON.parse(text());
            } catch (e) {}
        }
    }

    FileView {
        id: usageFile
        path: `${Quickshell.env("HOME")}/.local/state/rice/launcher-usage.json`
        printErrors: false
        onLoaded: {
            try {
                root.usage = JSON.parse(text());
            } catch (e) {}
        }
    }
}
