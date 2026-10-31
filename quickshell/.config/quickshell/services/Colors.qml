pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Material You palette, generated from the wallpaper by matugen (see `rice-wall`).
// Reloads live whenever the file changes; the fallbacks are a dark violet scheme.
Singleton {
    id: root

    property var scheme: ({})

    readonly property bool dark: (scheme.mode ?? "dark") === "dark"

    readonly property color primary: scheme.primary ?? "#cdbdff"
    readonly property color textOnPrimary: scheme.on_primary ?? "#34275e"
    readonly property color primaryContainer: scheme.primary_container ?? "#4b3e76"
    readonly property color textOnPrimaryContainer: scheme.on_primary_container ?? "#e8ddff"

    readonly property color secondary: scheme.secondary ?? "#cac3dc"
    readonly property color secondaryContainer: scheme.secondary_container ?? "#494458"
    readonly property color textOnSecondaryContainer: scheme.on_secondary_container ?? "#e7dff8"

    readonly property color tertiary: scheme.tertiary ?? "#eeb8ca"
    readonly property color tertiaryContainer: scheme.tertiary_container ?? "#643b4a"
    readonly property color textOnTertiaryContainer: scheme.on_tertiary_container ?? "#ffd9e3"

    readonly property color error: scheme.error ?? "#ffb4ab"
    readonly property color textOnError: scheme.on_error ?? "#690005"
    readonly property color errorContainer: scheme.error_container ?? "#93000a"

    readonly property color surface: scheme.surface ?? "#141218"
    readonly property color surfaceContainerLowest: scheme.surface_container_lowest ?? "#0f0d13"
    readonly property color surfaceContainerLow: scheme.surface_container_low ?? "#1d1b20"
    readonly property color surfaceContainer: scheme.surface_container ?? "#211f26"
    readonly property color surfaceContainerHigh: scheme.surface_container_high ?? "#2b2930"
    readonly property color surfaceContainerHighest: scheme.surface_container_highest ?? "#36343b"
    readonly property color textOnSurface: scheme.on_surface ?? "#e6e0e9"
    readonly property color textOnSurfaceVariant: scheme.on_surface_variant ?? "#cac4d0"

    readonly property color outline: scheme.outline ?? "#948f99"
    readonly property color outlineVariant: scheme.outline_variant ?? "#49454f"
    readonly property color shadow: scheme.shadow ?? "#000000"

    // Same colour with a different alpha, e.g. Colors.alpha(Colors.surface, 0.8)
    function alpha(c: color, a: real): color {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    FileView {
        path: `${Quickshell.env("HOME")}/.local/state/rice/colors.json`
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.scheme = JSON.parse(text());
            } catch (e) {
                console.warn("Colors: could not parse colors.json:", e);
            }
        }
    }
}
