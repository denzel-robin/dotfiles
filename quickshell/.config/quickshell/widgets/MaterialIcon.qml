import QtQuick
import qs.config
import qs.services

// A Material Symbols glyph by name, e.g. MaterialIcon { icon: "bluetooth" }
Text {
    property string icon
    property real fill: 0          // 0 = outlined, 1 = filled
    property int size: Appearance.bar.iconSize

    text: icon
    color: Colors.textOnSurface
    font.family: Appearance.font.icons
    font.pixelSize: size
    font.variableAxes: ({ "FILL": fill, "opsz": size, "wght": 450 })
    renderType: Text.NativeRendering
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter

    Behavior on color { CAnim {} }
    Behavior on fill { Anim { duration: Appearance.anim.fast } }
}
