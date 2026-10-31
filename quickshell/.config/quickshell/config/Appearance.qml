pragma Singleton

import QtQuick
import Quickshell

// Design tokens: every size, font and animation curve in the shell comes from here.
Singleton {
    readonly property QtObject rounding: QtObject {
        readonly property int small: 10
        readonly property int normal: 20
        readonly property int large: 28
        readonly property int full: 1000
    }

    readonly property QtObject spacing: QtObject {
        readonly property int small: 4
        readonly property int normal: 8
        readonly property int large: 14
    }

    readonly property QtObject padding: QtObject {
        readonly property int small: 6
        readonly property int normal: 10
        readonly property int large: 16
    }

    readonly property QtObject font: QtObject {
        readonly property string sans: "Rubik"
        readonly property string mono: "JetBrainsMono Nerd Font"
        readonly property string icons: "Material Symbols Rounded"

        readonly property int small: 11
        readonly property int normal: 13
        readonly property int large: 16
        readonly property int huge: 22
    }

    readonly property QtObject anim: QtObject {
        readonly property int fast: 200
        readonly property int normal: 400
        readonly property int slow: 600

        // Material 3 expressive curves
        readonly property list<real> standard: [0.2, 0, 0, 1, 1, 1]
        readonly property list<real> emphasized: [0.05, 0, 2 / 15, 0.06, 1 / 6, 0.4, 5 / 24, 0.82, 0.25, 1, 1, 1]
        readonly property list<real> spatial: [0.38, 1.21, 0.22, 1, 1, 1] // slight overshoot
    }

    readonly property QtObject bar: QtObject {
        readonly property int margin: 8        // gap between screen edge and islands
        readonly property int islandWidth: 40
        readonly property int islandSpacing: 8
        readonly property int iconSize: 20
    }
}
