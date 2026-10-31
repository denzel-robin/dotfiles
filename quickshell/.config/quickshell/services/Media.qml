pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// The media player to show: the one playing, otherwise the first one open.
Singleton {
    id: root

    readonly property list<MprisPlayer> players: Mpris.players.values
    readonly property MprisPlayer player: players.find(p => p.isPlaying) ?? players[0] ?? null

    readonly property string title: player?.trackTitle || "Nothing playing"
    readonly property string artist: player?.trackArtist || player?.identity || ""
    readonly property string art: player?.trackArtUrl ?? ""
    readonly property bool playing: player?.isPlaying ?? false
    readonly property real length: player?.length ?? 0
    readonly property real position: player?.position ?? 0

    function formatTime(s: real): string {
        s = Math.max(0, Math.floor(s));
        return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    }

    // MPRIS doesn't push position updates, so ask while something is playing
    Timer {
        interval: 1000
        running: root.playing
        repeat: true
        onTriggered: root.player?.positionChanged()
    }
}
