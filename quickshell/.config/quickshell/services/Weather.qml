pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Current weather and 3-day forecast from wttr.in for the current Place
// (College / Home). Refreshes every 30 min and whenever the place changes.
Singleton {
    id: root

    property bool ready: false
    property string location: ""
    property int temp: 0
    property int feelsLike: 0
    property int humidity: 0
    property string description: ""
    property string icon: "cloud"
    property list<var> forecast: []   // [{ day, max, min, icon }]

    // wttr.in weather codes -> Material Symbols
    function iconFor(code: int): string {
        if (code === 113)
            return "clear_day";
        if (code === 116)
            return "partly_cloudy_day";
        if ([119, 122].includes(code))
            return "cloud";
        if ([143, 248, 260].includes(code))
            return "foggy";
        if ([200, 386, 389, 392, 395].includes(code))
            return "thunderstorm";
        if ([179, 227, 230, 323, 326, 329, 332, 335, 338, 368, 371].includes(code))
            return "weather_snowy";
        if ([182, 185, 281, 284, 311, 314, 317, 350, 362, 365, 374, 377].includes(code))
            return "weather_mix";
        return "rainy";
    }

    function refresh(): void {
        fetcher.running = true;
    }

    Process {
        id: fetcher
        command: ["curl", "-sf", "--max-time", "15", `https://wttr.in/${Place.place.query}?format=j1`]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    const c = d.current_condition[0];
                    root.temp = parseInt(c.temp_C);
                    root.feelsLike = parseInt(c.FeelsLikeC);
                    root.humidity = parseInt(c.humidity);
                    root.description = c.weatherDesc[0].value;
                    root.icon = root.iconFor(parseInt(c.weatherCode));
                    root.location = Place.place.name;
                    root.forecast = d.weather.map(w => ({
                        day: Qt.formatDate(new Date(w.date), "ddd"),
                        max: parseInt(w.maxtempC),
                        min: parseInt(w.mintempC),
                        icon: root.iconFor(parseInt(w.hourly[4].weatherCode))
                    }));
                    root.ready = true;
                } catch (e) {
                    console.warn("Weather: bad response", e);
                }
            }
        }
    }

    Connections {
        target: Place
        function onCurrentChanged() { root.refresh(); }
    }

    Timer {
        interval: 30 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
