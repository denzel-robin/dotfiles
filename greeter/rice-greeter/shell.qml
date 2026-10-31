//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1

// Login screen (greetd greeter). Same look as the rice's lock screen: blurred
// wallpaper, big clock, password pill, colours from the wallpaper.
//
// Reads (copied there by rice-greeter-sync, since the greeter can't see /home):
//   $RICE_GREETER_DATA (default /var/lib/rice-greeter)/
//     wallpaper.jpg  colors.json  avatar.png  users   (one "name:Full Name" per line)
//
// Run outside greetd (`qs -p .`) it's a preview: any password containing "test" "logs in".

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Greetd
import Quickshell.Widgets

ShellRoot {
    id: root

    readonly property string dataDir: Quickshell.env("RICE_GREETER_DATA") || "/var/lib/rice-greeter"
    readonly property bool preview: !Greetd.available
    // Your desktop. The text console is blanked first and its output goes to
    // $XDG_RUNTIME_DIR/rice-session.log (not the screen), so nothing flashes in between.
    readonly property list<string> session: ["sh", "-c", "clear; setterm --cursor off; exec start-hyprland >\"${XDG_RUNTIME_DIR:-/tmp}/rice-session.log\" 2>&1"]
    property bool leaving: false   // fading out after a successful login

    // ── State ──
    property var colors: ({})
    property list<var> users: []          // [{ name, full }]
    property int userIndex: 0
    readonly property var user: users[userIndex] ?? { name: Quickshell.env("USER") || "user", full: "" }
    property string password: ""
    property bool busy: false
    property string error: ""
    property int fails: 0

    function c(key: string, fallback: string): color {
        return colors[key] ?? fallback;
    }

    // ── Login ──
    function submit(): void {
        if (busy || password === "")
            return;
        busy = true;
        error = "";
        if (preview) {
            previewTimer.restart();
        } else {
            Greetd.createSession(user.name);
        }
    }

    function failed(message: string): void {
        busy = false;
        password = "";
        error = message || "Wrong password";
        fails++;
    }

    Connections {
        target: Greetd
        enabled: !root.preview

        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (responseRequired)
                Greetd.respond(root.password);
            else if (error)
                root.error = message;
        }
        function onAuthFailure(message) {
            root.failed(message);
        }
        function onError(error) {
            Greetd.cancelSession();
            root.failed(error);
        }
        function onReadyToLaunch() {
            root.leaving = true;   // fade to black, then start the desktop (fadeOut timer)
        }
    }

    // After the fade to black, hand over to the desktop
    Timer {
        id: fadeOut
        interval: 450
        running: root.leaving
        onTriggered: {
            if (root.preview) {
                console.log("preview: would launch", root.session.join(" "), "for", root.user.name);
                Qt.quit();
            } else {
                Greetd.launch(root.session, ["XDG_SESSION_TYPE=wayland", "XDG_CURRENT_DESKTOP=Hyprland", "XDG_SESSION_DESKTOP=Hyprland"], true);
            }
        }
    }

    Timer {
        id: previewTimer
        interval: 700
        onTriggered: {
            if (root.password.includes("test")) {
                root.leaving = true;
            } else {
                root.failed("Wrong password (preview: type something containing \"test\")");
            }
        }
    }

    // ── Data from the rice ──
    FileView {
        path: `${root.dataDir}/colors.json`
        printErrors: false
        onLoaded: {
            try {
                root.colors = JSON.parse(text());
            } catch (e) {}
        }
    }

    FileView {
        path: `${root.dataDir}/users`
        printErrors: false
        onLoaded: root.users = text().split("\n").filter(Boolean).map(l => {
            const [name, full] = l.split(":");
            return { name, full: full || "" };
        })
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // ── Screen ──
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property ShellScreen modelData

            screen: modelData
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "rice-greeter"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: root.c("surface", "#111318")

            property real enter: 0
            Component.onCompleted: enter = 1
            Behavior on enter { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }

            // Fade to black on successful login (drawn above everything, see the end)
            // Pre-blurred wallpaper (the same image the lock screen uses)
            Image {
                anchors.fill: parent
                source: `file://${root.dataDir}/wallpaper.jpg`
                fillMode: Image.PreserveAspectCrop
                cache: false
                scale: 1.06 - 0.06 * win.enter
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.alpha(root.c("surface", "#111318"), 0.35)
            }

            Item {
                anchors.fill: parent
                opacity: win.enter
                focus: true

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.submit();
                    } else if (event.key === Qt.Key_Escape) {
                        root.password = "";
                    } else if (event.key === Qt.Key_Backspace) {
                        root.password = root.password.slice(0, -1);
                    } else if ((event.key === Qt.Key_Left || event.key === Qt.Key_Right) && root.users.length > 1 && root.password === "") {
                        const n = root.users.length;
                        root.userIndex = (root.userIndex + (event.key === Qt.Key_Right ? 1 : n - 1)) % n;
                    } else if (event.text && !root.busy) {
                        root.password += event.text;
                        root.error = "";
                    } else {
                        return;
                    }
                    event.accepted = true;
                }

                // Clock + date
                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: avatar.top
                    anchors.bottomMargin: 48

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatTime(clock.date, "hh:mm")
                        color: root.c("on_surface", "#e2e2e9")
                        font.family: "Rubik"
                        font.pixelSize: 120
                        font.weight: Font.Light
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDate(clock.date, "dddd, d MMMM")
                        color: root.c("on_surface_variant", "#c6c6d0")
                        font.family: "Rubik"
                        font.pixelSize: 22
                    }
                }

                // Avatar + name
                ClippingRectangle {
                    id: avatar

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: name.top
                    anchors.bottomMargin: 12
                    width: 96
                    height: 96
                    radius: 48
                    color: root.c("primary_container", "#2c4578")
                    border.width: 3
                    border.color: root.c("primary", "#aec6ff")

                    Image {
                        id: face
                        anchors.fill: parent
                        source: `file://${root.dataDir}/avatar.png`
                        fillMode: Image.PreserveAspectCrop
                        cache: false
                    }

                    // No avatar: the name's first letter
                    Text {
                        anchors.centerIn: parent
                        visible: face.status !== Image.Ready
                        text: root.user.name.charAt(0).toUpperCase()
                        color: root.c("on_primary_container", "#d9e2ff")
                        font.family: "Rubik"
                        font.pixelSize: 40
                        font.weight: Font.Medium
                    }
                }

                Text {
                    id: name

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: pill.top
                    anchors.bottomMargin: 24
                    text: (root.users.length > 1 ? "‹  " : "") + (root.user.full || root.user.name) + (root.users.length > 1 ? "  ›" : "")
                    color: root.c("on_surface", "#e2e2e9")
                    font.family: "Rubik"
                    font.pixelSize: 20
                    font.weight: Font.Medium
                }

                // Password pill
                Rectangle {
                    id: pill

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: 150
                    width: 340
                    height: 58
                    radius: 29
                    color: Qt.alpha(root.c("surface_container", "#1e1f25"), 0.88)
                    border.width: 2
                    border.color: root.error ? root.c("error", "#ffb4ab") : root.c("primary", "#aec6ff")

                    transform: Translate { id: shake }

                    SequentialAnimation {
                        id: shakeAnim
                        loops: 2
                        NumberAnimation { target: shake; property: "x"; to: -12; duration: 50 }
                        NumberAnimation { target: shake; property: "x"; to: 12; duration: 70 }
                        NumberAnimation { target: shake; property: "x"; to: 0; duration: 50 }
                    }

                    Connections {
                        target: root
                        function onFailsChanged() { shakeAnim.restart(); }
                    }

                    Text {
                        id: lockIcon
                        anchors.left: parent.left
                        anchors.leftMargin: 18
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.busy ? "progress_activity" : "lock"
                        color: root.error ? root.c("error", "#ffb4ab") : root.c("primary", "#aec6ff")
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 22

                        RotationAnimation on rotation {
                            running: root.busy
                            from: 0
                            to: 360
                            duration: 900
                            loops: Animation.Infinite
                            onStopped: lockIcon.rotation = 0
                        }
                    }

                    Row {
                        anchors.centerIn: parent

                        Repeater {
                            model: 18

                            Item {
                                required property int index
                                readonly property bool filled: index < root.password.length

                                width: filled ? 18 : 0
                                height: 10

                                Behavior on width { NumberAnimation { duration: 120 } }

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 10
                                    height: 10
                                    radius: 5
                                    color: root.c("on_surface", "#e2e2e9")
                                    scale: parent.filled ? 1 : 0

                                    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }
                                }
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: root.password === ""
                        text: root.busy ? "Signing in…" : "Enter password"
                        color: root.c("outline", "#8f909a")
                        font.family: "Rubik"
                        font.pixelSize: 16
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: pill.bottom
                    anchors.topMargin: 16
                    text: root.error
                    color: root.c("error", "#ffb4ab")
                    font.family: "Rubik"
                    font.pixelSize: 14
                }

                // Session (bottom left)
                Row {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    anchors.margins: 32
                    spacing: 8

                    Text {
                        text: "desktop_windows"
                        color: root.c("on_surface_variant", "#c6c6d0")
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 20
                    }

                    Text {
                        text: "Hyprland" + (root.preview ? "  ·  preview" : "")
                        color: root.c("on_surface_variant", "#c6c6d0")
                        font.family: "Rubik"
                        font.pixelSize: 14
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // Power (bottom right)
                Row {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 24
                    spacing: 8

                    Repeater {
                        model: [["bedtime", "suspend"], ["restart_alt", "reboot"], ["power_settings_new", "poweroff"]]

                        Rectangle {
                            required property var modelData

                            width: 44
                            height: 44
                            radius: 22
                            color: hover.containsMouse ? Qt.alpha(root.c("on_surface", "#e2e2e9"), 0.12) : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: parent.modelData[0]
                                color: parent.modelData[1] === "poweroff" ? root.c("error", "#ffb4ab") : root.c("on_surface_variant", "#c6c6d0")
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 22
                            }

                            MouseArea {
                                id: hover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.preview)
                                        console.log("preview: would run systemctl", parent.modelData[1]);
                                    else
                                        Quickshell.execDetached(["systemctl", parent.modelData[1]]);
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                color: "black"
                opacity: root.leaving ? 1 : 0
                visible: opacity > 0

                Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }
            }
        }
    }
}
