pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Default speaker and microphone from PipeWire.
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    readonly property real volume: sink?.audio?.volume ?? 0     // 0..1
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property bool micMuted: source?.audio?.muted ?? false

    readonly property string icon: muted || volume === 0 ? "volume_off" : volume < 0.34 ? "volume_mute" : volume < 0.67 ? "volume_down" : "volume_up"

    function setVolume(v: real): void {
        if (sink?.ready && sink.audio) {
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0, Math.min(1, v));
        }
    }

    function toggleMute(): void {
        if (sink?.ready && sink.audio)
            sink.audio.muted = !sink.audio.muted;
    }

    function toggleMicMute(): void {
        if (source?.ready && source.audio)
            source.audio.muted = !source.audio.muted;
    }

    PwObjectTracker {
        objects: [root.sink, root.source]
    }
}
