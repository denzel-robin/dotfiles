import QtQuick
import qs.config
import qs.services

Text {
    color: Colors.textOnSurface
    font.family: Appearance.font.sans
    font.pixelSize: Appearance.font.normal
    renderType: Text.NativeRendering
    verticalAlignment: Text.AlignVCenter

    Behavior on color { CAnim {} }
}
