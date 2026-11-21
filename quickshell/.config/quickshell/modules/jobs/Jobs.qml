pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// Off-campus job search tracker. Everything about it lives in this folder.
// Your data stays out of the repo, in ~/.local/state/rice/jobs.json.
//
// Hide it:      "Hide from bar" in its panel, or `qs ipc call jobs hide` (keeps your data)
// Bring it back: `qs ipc call jobs unhide`
// Delete it:    cd ~/.config/quickshell && rm -r modules/jobs && sed -i '/jobs-tracker/d' shell.qml modules/bar/Bar.qml
Singleton {
    id: root

    readonly property var statuses: [
        { id: "todo", label: "To apply" },
        { id: "applied", label: "Applied" },
        { id: "interview", label: "Interview" },
        { id: "offer", label: "Offer" },
        { id: "closed", label: "Closed" }
    ]

    // The weekly routine
    readonly property int dailyGoal: 5        // applications, Mon–Fri
    readonly property int referralGoal: 10    // referral or cold messages a week
    readonly property int sentGoal: 100       // expect 100–200 before offers arrive
    readonly property int followUpDays: 7     // follow up once, after 7–10 days

    // [{ id, company, role, status, contact, contactedOn, link, applied, followedUp, notes }]
    property var items: []
    property var done: ({})        // routine ticks, e.g. { "dsa:2026-11-06": true }
    property bool hidden: false
    property bool ready: false     // false = don't write, the file couldn't be read
    property string problem: ""
    property real islandBottom: 0  // y of the island's bottom edge, to line up the panel

    property string today: dateKey(new Date())

    readonly property bool weekend: {
        const day = parseDate(today).getDay();
        return day === 0 || day === 6;
    }
    readonly property string weekStart: {
        const d = parseDate(today);
        d.setDate(d.getDate() - (d.getDay() + 6) % 7);
        return dateKey(d);
    }
    readonly property int appliedToday: items.filter(e => e.applied === today).length
    readonly property int sent: items.filter(e => e.applied).length
    readonly property int referralsThisWeek: items.filter(e => e.contactedOn && e.contactedOn >= weekStart).length
    readonly property int dueCount: items.filter(e => isDue(e)).length
    readonly property string dsaKey: `dsa:${today}`
    readonly property string weekendKey: `weekend:${weekStart}`

    function dateKey(d: var): string {
        return Qt.formatDate(d, "yyyy-MM-dd");
    }

    function parseDate(key: string): var {
        const [y, m, d] = key.split("-").map(Number);
        return new Date(y, m - 1, d);
    }

    function validDate(key: string): bool {
        return /^\d{4}-\d{2}-\d{2}$/.test(key) && dateKey(parseDate(key)) === key;
    }

    function shortDate(key: string): string {
        return Qt.formatDate(parseDate(key), "d MMM");
    }

    function daysSince(key: string): int {
        return Math.round((parseDate(today) - parseDate(key)) / 86400000);
    }

    function isDue(e: var): bool {
        return e.status === "applied" && !!e.applied && !e.followedUp && daysSince(e.applied) >= followUpDays;
    }

    function statusLabel(id: string): string {
        return statuses.find(s => s.id === id)?.label ?? id;
    }

    function count(filter: string): int {
        return items.filter(e => matches(e, filter)).length;
    }

    function matches(e: var, filter: string): bool {
        return filter === "all" || (filter === "due" ? isDue(e) : e.status === filter);
    }

    // Follow-ups first, then whatever is furthest along, newest first
    function view(filter: string, query: string): var {
        const order = ["interview", "offer", "applied", "todo", "closed"];
        const q = query.trim().toLowerCase();
        return items
            .filter(e => matches(e, filter))
            .filter(e => !q || [e.company, e.role, e.contact, e.notes].some(s => (s ?? "").toLowerCase().includes(q)))
            .sort((a, b) => isDue(b) - isDue(a)
                || order.indexOf(a.status) - order.indexOf(b.status)
                || (b.applied ?? "").localeCompare(a.applied ?? "")
                || a.company.localeCompare(b.company));
    }

    // Fills in the dates a change implies, then returns the entry to store
    function stamped(e: var, previous: var): var {
        const out = Object.assign({}, previous ?? {}, e);
        for (const key of ["company", "role", "contact", "link", "notes", "applied"])
            out[key] = (out[key] ?? "").trim();
        out.status = out.status ?? "todo";
        if (out.status === "todo") {
            out.applied = "";
            out.followedUp = "";
        } else if (!out.applied && ["applied", "interview", "offer"].includes(out.status)) {
            out.applied = today;
        }
        out.contactedOn = out.contact ? (previous?.contactedOn || today) : "";
        return out;
    }

    function add(fields: var): void {
        if (!ready || !(fields.company ?? "").trim())
            return;
        const id = `${Date.now().toString(36)}${Math.floor(Math.random() * 1296).toString(36)}`;
        items = items.concat([stamped(Object.assign({ id }, fields), null)]);
        save();
    }

    function change(id: string, fields: var): void {
        if (!ready)
            return;
        items = items.map(e => e.id === id ? stamped(fields, e) : e);
        save();
    }

    function remove(id: string): void {
        if (!ready)
            return;
        items = items.filter(e => e.id !== id);
        save();
    }

    function tick(key: string): void {
        if (!ready)
            return;
        const next = Object.assign({}, done);
        if (next[key])
            delete next[key];
        else
            next[key] = true;
        done = next;
        save();
    }

    function setHidden(value: bool): void {
        hidden = value;
        save();
        if (value)
            Quickshell.execDetached(["notify-send", "-a", "Job tracker", "Hidden from the bar", "Your data is kept. Bring it back with: qs ipc call jobs unhide"]);
    }

    function openLink(url: string): void {
        Quickshell.execDetached(["xdg-open", /^https?:\/\//i.test(url) ? url : `https://${url}`]);
    }

    function save(): void {
        if (ready)
            file.setText(JSON.stringify({ hidden, done, items }, null, 2) + "\n");
    }

    FileView {
        id: file

        path: `${Quickshell.env("HOME")}/.local/state/rice/jobs.json`
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const d = JSON.parse(text());
                if (!Array.isArray(d.items))
                    throw new Error("no items list");
                root.items = d.items;
                root.done = d.done ?? {};
                root.hidden = d.hidden ?? false;
                root.ready = true;
                root.problem = "";
            } catch (e) {
                // Never overwrite a file we can't read: it may be a hand edit in progress
                root.ready = false;
                root.problem = `Can't read jobs.json (${e.message}). Fix the file; nothing is saved until then.`;
            }
        }
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                root.ready = true;
            } else {
                root.ready = false;
                root.problem = "Can't read jobs.json. Nothing is saved until that's fixed.";
            }
        }
    }

    // Rolls the day over at midnight
    Timer {
        interval: 60 * 1000
        running: true
        repeat: true
        onTriggered: root.today = root.dateKey(new Date())
    }

    // `qs ipc call jobs <function>`
    IpcHandler {
        target: "jobs"

        function toggle(): void {
            Panels.toggle("jobs");
        }

        function unhide(): void {
            root.setHidden(false);
        }

        function hide(): void {
            root.setHidden(true);
        }
    }
}
