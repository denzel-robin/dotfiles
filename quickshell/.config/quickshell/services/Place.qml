pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Where you are, for the weather: College or Home.
// "auto" recognises the network you're on (Wi-Fi name, or the router for wired) —
// unaffected by WARP, unlike IP geolocation. Choosing a place manually also teaches
// it the current network. Saved in ~/.local/state/rice/place.json, which also holds
// the real place names (kept out of the dotfiles repo):
//   "places": { "college": { "name": "Town", "query": "~Town" }, "home": { ... } }
Singleton {
    id: root

    // Names/queries come from place.json; an empty query lets wttr.in guess from your IP
    property var placeNames: ({ college: { name: "College", query: "" }, home: { name: "Home", query: "" } })
    readonly property var places: ({
        college: { label: "College", name: placeNames.college?.name ?? "College", query: placeNames.college?.query ?? "", icon: "school" },
        home: { label: "Home", name: placeNames.home?.name ?? "Home", query: placeNames.home?.query ?? "", icon: "home" }
    })

    property string mode: "auto"          // "auto" | "college" | "home"
    property string last: "college"       // used when the network is unknown
    property var networks: ({ college: [], home: [] })
    property string networkId: ""         // "wifi:<ssid>" or "wired:<router mac>"

    readonly property string autoPlace: {
        for (const key of Object.keys(networks))
            if (networkId && networks[key].includes(networkId))
                return key;
        return last;
    }
    readonly property string current: mode === "auto" ? autoPlace : mode
    readonly property var place: places[current]

    // Pick "auto", "college" or "home". A manual pick remembers the current network.
    function choose(m: string): void {
        if (m !== "auto") {
            const n = Object.assign({}, networks);
            for (const key of Object.keys(n))
                n[key] = n[key].filter(id => id !== networkId);
            if (networkId)
                n[m] = [...n[m], networkId];
            networks = n;
            last = m;
        }
        mode = m;
        save();
    }

    function save(): void {
        file.setText(JSON.stringify({ mode, last, places: placeNames, networks }, null, 2));
    }

    FileView {
        id: file
        path: `${Quickshell.env("HOME")}/.local/state/rice/place.json`
        printErrors: false
        onLoaded: {
            try {
                const d = JSON.parse(text());
                root.mode = d.mode ?? "auto";
                root.last = d.last ?? "college";
                root.networks = Object.assign({ college: [], home: [] }, d.networks ?? {});
                if (d.places)
                    root.placeNames = Object.assign({}, root.placeNames, d.places);
            } catch (e) {}
        }
    }

    // ── Which network are we on? ──
    function refreshNetwork(): void {
        if (Network.wifi) {
            networkId = `wifi:${Network.wifi.name}`;
        } else if (Network.wired) {
            routerProc.running = true;
        } else {
            networkId = "";
        }
    }

    Process {
        id: routerProc
        // MAC of the wired connection's router (WARP's tunnel isn't a wired device, so it's ignored)
        command: ["bash", "-c", "for d in $(nmcli -t -f DEVICE,TYPE,STATE device | awk -F: '$2==\"ethernet\"&&$3==\"connected\"{print $1}'); do gw=$(ip -4 route show default dev $d | awk '{print $3; exit}'); [ -n \"$gw\" ] && ip neigh show $gw dev $d | awk '{print $3; exit}' && break; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const mac = text.trim();
                root.networkId = mac ? `wired:${mac}` : "";
            }
        }
    }

    Connections {
        target: Network
        function onWifiChanged() { root.refreshNetwork(); }
        function onWiredChanged() { root.refreshNetwork(); }
    }

    Timer {
        interval: 5 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshNetwork()
    }
}
