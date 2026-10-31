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

    function launch(e): void {
        usage[e.id] = (usage[e.id] ?? 0) + 1;
        usageFile.setText(JSON.stringify(usage));
        usageChanged();

        if (e.runInTerminal)
            Quickshell.execDetached(["kitty", "-e", ...e.command]);
        else
            e.execute();
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
