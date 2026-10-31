import QtQuick
import qs.config

ColorAnimation {
    duration: Appearance.anim.slow
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Appearance.anim.standard
}
