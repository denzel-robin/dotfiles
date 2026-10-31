pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Notification daemon. Every notification is kept in history until dismissed;
// new ones also pop up unless Do-Not-Disturb is on (critical ones always pop up).
Singleton {
    id: root

    property bool dnd: false
    readonly property list<var> history: [...server.trackedNotifications.values].reverse()   // newest first
    property list<var> popups: []
    property var receivedAt: ({})   // notification id -> Date.now() when it arrived

    function hidePopup(n): void {
        popups = popups.filter(p => p && p !== n);
    }

    function clearAll(): void {
        for (const n of [...server.trackedNotifications.values])
            n.dismiss();
        popups = [];
    }

    // "now", "5m", "2h", "3d"
    function age(n, now: date): string {
        const mins = Math.floor((now.getTime() - (receivedAt[n?.id] ?? now.getTime())) / 60000);
        return mins < 1 ? "now" : mins < 60 ? `${mins}m` : mins < 1440 ? `${Math.floor(mins / 60)}h` : `${Math.floor(mins / 1440)}d`;
    }

    // Default "click" action of a notification, if it has one
    function defaultAction(n) {
        return n?.actions.find(a => a.identifier === "default") ?? null;
    }

    // How long a popup stays, in ms (expireTimeout is in seconds; <= 0 means "server decides")
    function popupDuration(n): int {
        if (n.urgency === NotificationUrgency.Critical)
            return 0;
        return n.expireTimeout > 0 ? n.expireTimeout * 1000 : 5000;
    }

    NotificationServer {
        id: server

        keepOnReload: true
        actionsSupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: n => {
            n.tracked = true;
            root.receivedAt[n.id] = Date.now();
            n.closed.connect(() => root.hidePopup(n));
            if (!root.dnd || n.urgency === NotificationUrgency.Critical)
                root.popups = [n, ...root.popups];
        }
    }
}
