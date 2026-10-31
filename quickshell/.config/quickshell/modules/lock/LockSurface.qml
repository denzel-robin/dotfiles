import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets

// What the lock screen looks like on each monitor.
Item {
    id: root

    required property var lock
    property real enter: 0

    Component.onCompleted: {
        enter = 1;
        input.forceActiveFocus();
    }

    Behavior on enter { Anim { duration: Appearance.anim.slow; easing.bezierCurve: Appearance.anim.emphasized } }

    // Pre-blurred by rice-wall, so the GPU doesn't redo a full-screen blur every frame.
    // Falls back to the plain wallpaper if the blurred copy doesn't exist yet.
    Image {
        id: blurred
        anchors.fill: parent
        source: `file://${Quickshell.env("HOME")}/.cache/rice/lock.jpg`
        cache: false
        fillMode: Image.PreserveAspectCrop
    }

    Image {
        anchors.fill: parent
        visible: blurred.status === Image.Error
        source: Wallpapers.current ? `file://${Wallpapers.current}` : ""
        sourceSize.width: 1920
        fillMode: Image.PreserveAspectCrop
    }

    Rectangle {
        anchors.fill: parent
        color: Colors.alpha(Colors.surface, 0.35)
    }

    Item {
        anchors.fill: parent
        opacity: root.enter

        // Clock + date
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: pill.top
            anchors.bottomMargin: 56
            spacing: 0

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: `${Time.hours}:${Time.minutes}`
                font.pixelSize: 120
                font.weight: Font.Light
                color: Colors.textOnSurface
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Time.format("dddd, d MMMM")
                font.pixelSize: 22
                color: Colors.textOnSurfaceVariant
            }
        }

        // Password field
        Rectangle {
            id: pill

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 60
            width: 340
            height: 58
            radius: Appearance.rounding.full
            color: Colors.alpha(Colors.surfaceContainer, 0.88)
            border.width: 2
            border.color: root.lock.error ? Colors.error : input.activeFocus ? Colors.primary : Colors.outlineVariant

            Behavior on border.color { CAnim { duration: Appearance.anim.fast } }

            transform: Translate { id: shakeOffset }

            SequentialAnimation {
                id: shake
                loops: 2
                NumberAnimation { target: shakeOffset; property: "x"; to: -12; duration: 50 }
                NumberAnimation { target: shakeOffset; property: "x"; to: 12; duration: 70 }
                NumberAnimation { target: shakeOffset; property: "x"; to: 0; duration: 50 }
            }

            Connections {
                target: root.lock
                function onFailsChanged() { shake.restart(); }
            }

            MaterialIcon {
                id: lockIcon
                anchors.left: parent.left
                anchors.leftMargin: Appearance.padding.large + 2
                anchors.verticalCenter: parent.verticalCenter
                icon: root.lock.busy ? "progress_activity" : "lock"
                fill: 1
                color: root.lock.error ? Colors.error : Colors.primary

                RotationAnimation on rotation {
                    running: root.lock.busy
                    from: 0
                    to: 360
                    duration: 900
                    loops: Animation.Infinite
                    onStopped: lockIcon.rotation = 0
                }
            }

            // One dot per typed character
            Row {
                anchors.centerIn: parent

                // Fixed slots: only the dot being added/removed animates
                Repeater {
                    model: 18

                    Item {
                        required property int index
                        readonly property bool filled: index < root.lock.password.length

                        width: filled ? 18 : 0
                        height: 10

                        Behavior on width { Anim { duration: Appearance.anim.fast } }

                        Rectangle {
                            anchors.centerIn: parent
                            width: 10
                            height: 10
                            radius: 5
                            color: Colors.textOnSurface
                            scale: parent.filled ? 1 : 0

                            Behavior on scale { Anim { duration: Appearance.anim.fast; easing.bezierCurve: Appearance.anim.spatial } }
                        }
                    }
                }
            }

            StyledText {
                anchors.centerIn: parent
                visible: root.lock.password === ""
                text: root.lock.busy ? "Checking…" : "Enter password"
                color: Colors.outline
                font.pixelSize: Appearance.font.large
            }

            TextInput {
                id: input

                anchors.fill: parent
                opacity: 0
                echoMode: TextInput.Password
                enabled: !root.lock.busy
                onTextChanged: {
                    root.lock.password = text;
                    if (text && root.lock.error)
                        root.lock.error = "";
                }
                onAccepted: root.lock.submit()
                Keys.onEscapePressed: text = ""
            }

            // The lock clears the password after each attempt
            Connections {
                target: root.lock
                function onPasswordChanged() {
                    if (root.lock.password === "" && input.text !== "")
                        input.text = "";
                }
            }
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: pill.bottom
            anchors.topMargin: Appearance.spacing.large
            text: root.lock.error
            color: Colors.error
            font.pixelSize: Appearance.font.normal
        }

        // User + battery
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 48
            spacing: Appearance.spacing.large

            Row {
                spacing: Appearance.spacing.small

                MaterialIcon {
                    icon: "account_circle"
                    fill: 1
                    color: Colors.textOnSurfaceVariant
                }

                StyledText {
                    text: Quickshell.env("USER")
                    color: Colors.textOnSurfaceVariant
                }
            }

            Row {
                visible: Battery.present
                spacing: Appearance.spacing.small

                MaterialIcon {
                    icon: Battery.icon
                    fill: 1
                    color: Battery.low ? Colors.error : Colors.textOnSurfaceVariant
                }

                StyledText {
                    text: `${Math.round(Battery.charge * 100)}%`
                    color: Colors.textOnSurfaceVariant
                }
            }
        }
    }
}
