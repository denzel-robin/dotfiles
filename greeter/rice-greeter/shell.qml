//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1

// Login screen (greetd greeter), in the rice's colours: drifting wallpaper with soft
// colour glows, a rolling clock, and a glass card with your avatar and password.
// After 25 s without input it fades to just the clock; any key or mouse move wakes it.
//
// Reads (copied there by rice-greeter-sync, since the greeter can't see /home):
//   $RICE_GREETER_DATA (default /var/lib/rice-greeter)/
//     wallpaper.jpg  colors.json  avatar.png  users   (one "name:Full Name" per line)
//
// Run outside greetd (`qs -p .`) it's a preview: any password containing "test" "logs in".
// RICE_GREETER_DEMO=typing|error|caps|busy|idle shows that state (preview only).

import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Greetd
import Quickshell.Widgets

ShellRoot {
    id: root

    readonly property string dataDir: Quickshell.env("RICE_GREETER_DATA") || "/var/lib/rice-greeter"
    readonly property bool preview: !Greetd.available
    // Your desktop: /usr/local/bin/rice-session (installed with the greeter) blanks the
    // text console and starts start-hyprland, logging to $XDG_RUNTIME_DIR/rice-session.log.
    readonly property list<string> session: ["/usr/local/bin/rice-session"]
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
    property real pulse: 0                // 1 on each keystroke, fades to 0

    function keystroke(): void {
        pulseAnim.restart();
    }

    NumberAnimation {
        id: pulseAnim
        target: root
        property: "pulse"
        from: 1
        to: 0
        duration: 450
        easing.type: Easing.OutCubic
    }
    property bool capsLock: false         // guessed from letters typed (Shift inverts them)
    property bool idle: false             // nothing typed or moved for a while: clock only

    function c(key: string, fallback: string): color {
        return colors[key] ?? fallback;
    }

    function wake(): void {
        idle = false;
        idleTimer.restart();
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
        interval: 650
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
        interval: 900
        onTriggered: {
            if (root.password.includes("test")) {
                root.leaving = true;
            } else {
                root.failed("Wrong password (preview: type something containing \"test\")");
            }
        }
    }

    Timer {
        id: idleTimer
        interval: 25000
        running: !root.busy && !root.leaving
        onTriggered: {
            if (root.password === "" && !root.busy)
                root.idle = true;
        }
    }

    // Preview-only states for screenshots
    Component.onCompleted: {
        const demo = root.preview ? (Quickshell.env("RICE_GREETER_DEMO") || "") : "";
        if (demo === "typing") {
            root.password = "hunter2pass";
        } else if (demo === "error") {
            root.failed("Wrong password");
        } else if (demo === "caps") {
            root.password = "PASS";
            root.capsLock = true;
        } else if (demo === "busy") {
            root.password = "hunter2pass";
            root.busy = true;
        } else if (demo === "idle") {
            root.idle = true;
        } else if (demo === "live") {
            demoTyper.running = true;
        }
    }

    Timer {
        id: demoTyper
        property int step: 0
        interval: 170
        repeat: true
        onTriggered: {
            const script = "hunter2xx--pass\n";
            const ch = script.charAt(step++);
            if (ch === "-") {
                root.password = root.password.slice(0, -1);
                root.keystroke();
            } else if (ch === "\n") {
                running = false;
                root.submit();
            } else {
                root.password += ch;
                root.keystroke();
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
        precision: SystemClock.Seconds
    }

    // ── Battery (laptops) ──
    property int battery: -1
    property bool charging: false

    FileView {
        id: batCap
        path: "/sys/class/power_supply/BAT1/capacity"
        printErrors: false
        onLoaded: root.battery = parseInt(text())
        onLoadFailed: if (path.includes("BAT1")) path = "/sys/class/power_supply/BAT0/capacity"
    }

    FileView {
        id: batStatus
        path: batCap.path.replace("capacity", "status")
        printErrors: false
        onLoaded: root.charging = /Charging|Full/.test(text())
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: {
            batCap.reload();
            batStatus.reload();
        }
    }

    // ── Pieces ──

    // A clock digit that rolls up when it changes
    component Digit: Item {
        id: digit

        property string value
        property string shown: ""
        property color color
        property int weight: Font.Normal
        property int size: 160

        implicitWidth: metrics.advanceWidth
        implicitHeight: metrics.height
        clip: true

        onValueChanged: {
            outgoing.text = shown;
            shown = value;
            roll.restart();
        }

        TextMetrics {
            id: metrics
            font: incoming.font
            text: "0"
        }

        Text {
            id: outgoing
            anchors.horizontalCenter: parent.horizontalCenter
            color: digit.color
            font: incoming.font
        }

        Text {
            id: incoming
            anchors.horizontalCenter: parent.horizontalCenter
            text: digit.shown
            color: digit.color
            font.family: "Rubik"
            font.pixelSize: digit.size
            font.weight: digit.weight
            font.features: { "tnum": 1 }
        }

        ParallelAnimation {
            id: roll
            NumberAnimation { target: outgoing; property: "y"; from: 0; to: -digit.height * 0.6; duration: 520; easing.type: Easing.OutCubic }
            NumberAnimation { target: outgoing; property: "opacity"; from: 1; to: 0; duration: 360 }
            NumberAnimation { target: incoming; property: "y"; from: digit.height * 0.6; to: 0; duration: 620; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
            NumberAnimation { target: incoming; property: "opacity"; from: 0; to: 1; duration: 420 }
        }
    }

    // A soft round glow of colour
    component Glow: Shape {
        id: glow

        property color tint
        property real size: 700

        width: size
        height: size
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: -1
            fillGradient: RadialGradient {
                centerX: glow.size / 2
                centerY: glow.size / 2
                centerRadius: glow.size / 2
                focalX: centerX
                focalY: centerY
                GradientStop { position: 0; color: Qt.alpha(glow.tint, 0.42) }
                GradientStop { position: 0.45; color: Qt.alpha(glow.tint, 0.16) }
                GradientStop { position: 1; color: Qt.alpha(glow.tint, 0) }
            }
            PathAngleArc { centerX: glow.size / 2; centerY: glow.size / 2; radiusX: glow.size / 2; radiusY: glow.size / 2; startAngle: 0; sweepAngle: 360 }
        }
    }

    // Glass chip with an icon and text
    component Chip: Rectangle {
        id: chip

        property string icon
        property string label
        property color tint: root.c("on_surface_variant", "#c6c6d0")

        implicitWidth: chipRow.implicitWidth + 28
        implicitHeight: 36
        radius: 18
        color: Qt.alpha(root.c("surface_container", "#1e1f25"), 0.55)
        border.width: 1
        border.color: Qt.alpha(root.c("outline_variant", "#45464f"), 0.6)

        Row {
            id: chipRow
            anchors.centerIn: parent
            spacing: 8

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: chip.icon
                color: chip.tint
                font.family: "Material Symbols Rounded"
                font.pixelSize: 18
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: chip.label
                color: chip.tint
                font.family: "Rubik"
                font.pixelSize: 14
                font.weight: Font.Medium
            }
        }
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

            // The window gets its size a moment after it's created. Start the entrance only
            // then, and let positions animate on their own only after it (otherwise the card
            // animates from the top of a zero-height window to the middle).
            property real enter: 0
            property bool settled: false
            onHeightChanged: if (height > 0 && enter === 0) Qt.callLater(() => enter = 1)
            Component.onCompleted: if (height > 0) Qt.callLater(() => enter = 1)
            onEnterChanged: if (enter === 1) settled = true
            Behavior on enter { NumberAnimation { duration: 1100; easing.type: Easing.OutCubic } }

            readonly property color primary: root.c("primary", "#aec6ff")
            readonly property color tertiary: root.c("tertiary", "#dcbce1")
            readonly property color secondary: root.c("secondary", "#bfc6dc")
            readonly property color fg: root.c("on_surface", "#e2e2e9")
            readonly property color fgDim: root.c("on_surface_variant", "#c6c6d0")
            readonly property color surface: root.c("surface", "#111318")
            readonly property color errorColor: root.c("error", "#ffb4ab")

            // ── Background: slowly drifting wallpaper, colour glows, vignette ──
            Item {
                anchors.fill: parent
                clip: true

                Image {
                    id: wall

                    property real drift: 0

                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                    source: `file://${root.dataDir}/wallpaper.jpg`
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    scale: 1.14 - 0.04 * win.enter
                    x: Math.sin(drift * Math.PI * 2) * 18
                    y: Math.cos(drift * Math.PI * 2) * 12

                    NumberAnimation on drift { from: 0; to: 1; duration: 90000; loops: Animation.Infinite }
                }

                Glow {
                    tint: win.primary
                    size: win.width * 0.55
                    property real t: 0
                    x: win.width * 0.12 + Math.sin(t * Math.PI * 2) * 80 - size / 2
                    y: win.height * 0.25 + Math.cos(t * Math.PI * 2) * 60 - size / 2
                    NumberAnimation on t { from: 0; to: 1; duration: 40000; loops: Animation.Infinite }
                }

                Glow {
                    tint: win.tertiary
                    size: win.width * 0.5
                    property real t: 0
                    x: win.width * 0.88 + Math.cos(t * Math.PI * 2) * 90 - size / 2
                    y: win.height * 0.7 + Math.sin(t * Math.PI * 2) * 70 - size / 2
                    NumberAnimation on t { from: 0; to: 1; duration: 52000; loops: Animation.Infinite }
                }

                Glow {
                    tint: win.secondary
                    size: win.width * 0.4
                    opacity: 0.7
                    property real t: 0
                    x: win.width * 0.5 + Math.sin(t * Math.PI * 2) * 140 - size / 2
                    y: win.height * 1.0 + Math.cos(t * Math.PI * 2) * 40 - size / 2
                    NumberAnimation on t { from: 0; to: 1; duration: 64000; loops: Animation.Infinite }
                }

                // Darker towards the edges so the text always reads
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0; color: Qt.alpha(win.surface, 0.55) }
                        GradientStop { position: 0.35; color: Qt.alpha(win.surface, 0.18) }
                        GradientStop { position: 0.65; color: Qt.alpha(win.surface, 0.28) }
                        GradientStop { position: 1; color: Qt.alpha(win.surface, 0.82) }
                    }
                }
            }

            // Any mouse movement wakes the card (clicks still reach the buttons)
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton

                // The first event is just where the pointer already was: only real movement wakes
                property point last: Qt.point(-1, -1)
                onPositionChanged: mouse => {
                    if (last.x >= 0 && Math.abs(mouse.x - last.x) + Math.abs(mouse.y - last.y) > 4)
                        root.wake();
                    last = Qt.point(mouse.x, mouse.y);
                }
            }

            Item {
                id: ui

                anchors.fill: parent
                opacity: win.enter
                focus: true

                Keys.onPressed: event => {
                    root.wake();
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.submit();
                    } else if (event.key === Qt.Key_Escape) {
                        root.password = "";
                    } else if (event.key === Qt.Key_Backspace) {
                        if (root.password !== "")
                            root.keystroke();
                        root.password = root.password.slice(0, -1);
                    } else if ((event.key === Qt.Key_Left || event.key === Qt.Key_Right) && root.users.length > 1 && root.password === "") {
                        const n = root.users.length;
                        root.userIndex = (root.userIndex + (event.key === Qt.Key_Right ? 1 : n - 1)) % n;
                    } else if (event.text && !root.busy) {
                        root.password += event.text;
                        root.error = "";
                        root.keystroke();
                        // A letter in the "wrong" case for Shift means Caps Lock is on
                        if (/^[a-zA-Z]$/.test(event.text)) {
                            const upper = event.text === event.text.toUpperCase();
                            const shift = (event.modifiers & Qt.ShiftModifier) !== 0;
                            root.capsLock = upper !== shift;
                        }
                    } else {
                        return;
                    }
                    event.accepted = true;
                }

                // ── Date, clock, greeting ──
                Column {
                    id: clockBlock

                    anchors.horizontalCenter: parent.horizontalCenter
                    y: root.idle ? (parent.height - height) / 2 - 20 : parent.height * 0.13 - 30 * (1 - win.enter)
                    spacing: 6
                    scale: root.idle ? 1.12 : 1

                    Behavior on y { enabled: win.settled; NumberAnimation { duration: 900; easing.type: Easing.InOutCubic } }
                    Behavior on scale { NumberAnimation { duration: 900; easing.type: Easing.InOutCubic } }

                    Chip {
                        anchors.horizontalCenter: parent.horizontalCenter
                        icon: "calendar_today"
                        label: Qt.formatDate(clock.date, "dddd, d MMMM")
                    }

                    Row {
                        id: time

                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 4

                        readonly property string hh: Qt.formatTime(clock.date, "hh")
                        readonly property string mm: Qt.formatTime(clock.date, "mm")

                        Digit { value: time.hh.charAt(0); color: win.primary; weight: Font.DemiBold }
                        Digit { value: time.hh.charAt(1); color: win.primary; weight: Font.DemiBold }

                        // Colon: two dots that breathe with the seconds
                        Item {
                            width: 44
                            height: parent.height

                            Column {
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: 6
                                spacing: 30
                                opacity: clock.seconds % 2 === 0 ? 1 : 0.35

                                Behavior on opacity { NumberAnimation { duration: 700; easing.type: Easing.InOutSine } }

                                Repeater {
                                    model: 2

                                    Rectangle {
                                        width: 14
                                        height: 14
                                        radius: 7
                                        gradient: Gradient {
                                            GradientStop { position: 0; color: win.primary }
                                            GradientStop { position: 1; color: win.tertiary }
                                        }
                                    }
                                }
                            }
                        }

                        Digit { value: time.mm.charAt(0); color: win.fg; weight: Font.Light }
                        Digit { value: time.mm.charAt(1); color: win.fg; weight: Font.Light }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: {
                            const h = clock.hours;
                            const part = h < 5 ? "Up late" : h < 12 ? "Good morning" : h < 17 ? "Good afternoon" : h < 22 ? "Good evening" : "Good night";
                            return `${part}, ${root.user.full || root.user.name}`;
                        }
                        color: win.fgDim
                        font.family: "Rubik"
                        font.pixelSize: 22
                        font.weight: Font.Normal
                        font.letterSpacing: 0.5
                    }
                }

                // ── The card: avatar, name, password ──
                Item {
                    id: cardHolder

                    width: 440
                    height: card.height
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height * 0.5 + 40 + (root.idle ? 60 : 0) + 60 * (1 - win.enter)
                    opacity: root.idle ? 0 : 1
                    scale: root.leaving ? 1.06 : 1
                    visible: opacity > 0

                    Behavior on y { enabled: win.settled; NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 500 } }
                    Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }

                    // Soft shadow under the card
                    Rectangle {
                        anchors.fill: card
                        anchors.topMargin: 14
                        radius: card.radius
                        color: Qt.alpha(root.c("shadow", "#000000"), 0.5)
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            blurEnabled: true
                            blur: 1
                            blurMax: 48
                            autoPaddingEnabled: true
                        }
                    }

                    Rectangle {
                        id: card

                        width: parent.width
                        height: cardColumn.y + cardColumn.implicitHeight + 30
                        radius: 36
                        color: Qt.alpha(root.c("surface_container", "#1e1f25"), 0.62)
                        border.width: 1
                        border.color: Qt.alpha(root.c("outline_variant", "#45464f"), 0.55)

                        // A faint light along the top edge
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 1
                            height: parent.height * 0.5
                            radius: parent.radius
                            gradient: Gradient {
                                GradientStop { position: 0; color: Qt.alpha(win.fg, 0.06) }
                                GradientStop { position: 1; color: Qt.alpha(win.fg, 0) }
                            }
                        }

                        Column {
                            id: cardColumn

                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 112 / 2 + 24
                            width: parent.width - 56
                            spacing: 14

                            // Name (and user switcher when there's more than one)
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 14

                                Text {
                                    visible: root.users.length > 1
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "chevron_left"
                                    color: win.fgDim
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 24

                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -8
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.userIndex = (root.userIndex + root.users.length - 1) % root.users.length
                                    }
                                }

                                Column {
                                    spacing: 2

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: root.user.full || root.user.name
                                        color: win.fg
                                        font.family: "Rubik"
                                        font.pixelSize: 24
                                        font.weight: Font.Medium
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        visible: root.user.full !== ""
                                        text: `@${root.user.name}`
                                        color: win.fgDim
                                        font.family: "Rubik"
                                        font.pixelSize: 13
                                    }
                                }

                                Text {
                                    visible: root.users.length > 1
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "chevron_right"
                                    color: win.fgDim
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 24

                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -8
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.userIndex = (root.userIndex + 1) % root.users.length
                                    }
                                }
                            }

                            // ── Password field ──
                            Rectangle {
                                id: field

                                readonly property bool active: root.password !== "" || root.busy
                                readonly property color accent: root.error ? win.errorColor : win.primary

                                width: parent.width
                                height: 60
                                radius: 30
                                color: Qt.alpha(root.c("surface_container_highest", "#33353a"), 0.72)
                                border.width: 2
                                border.color: root.error ? win.errorColor : field.active ? win.primary : Qt.alpha(root.c("outline", "#8f909a"), 0.45)

                                Behavior on border.color { ColorAnimation { duration: 250 } }

                                // Glow behind the field while typing
                                Rectangle {
                                    z: -1
                                    anchors.fill: parent
                                    radius: height / 2
                                    color: "transparent"
                                    border.width: 6 + 4 * root.pulse
                                    anchors.margins: -6 - 4 * root.pulse
                                    border.color: Qt.alpha(field.accent, (field.active || root.error ? 0.18 : 0) + 0.3 * root.pulse)
                                }

                                transform: Translate { id: shake }

                                SequentialAnimation {
                                    id: shakeAnim
                                    NumberAnimation { target: shake; property: "x"; to: -14; duration: 45; easing.type: Easing.OutQuad }
                                    NumberAnimation { target: shake; property: "x"; to: 12; duration: 70; easing.type: Easing.InOutQuad }
                                    NumberAnimation { target: shake; property: "x"; to: -8; duration: 60; easing.type: Easing.InOutQuad }
                                    NumberAnimation { target: shake; property: "x"; to: 5; duration: 55; easing.type: Easing.InOutQuad }
                                    NumberAnimation { target: shake; property: "x"; to: 0; duration: 50; easing.type: Easing.OutQuad }
                                }

                                Connections {
                                    target: root
                                    function onFailsChanged() { shakeAnim.restart(); }
                                }

                                Text {
                                    id: keyIcon
                                    anchors.left: parent.left
                                    anchors.leftMargin: 20
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.error ? "lock_reset" : field.active ? "key" : "lock"
                                    color: field.active || root.error ? field.accent : win.fgDim
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 22
                                    font.variableAxes: { "FILL": field.active ? 1 : 0 }

                                    Behavior on color { ColorAnimation { duration: 250 } }
                                }

                                // Typed characters. They grow from the left, where the caret and the
                                // placeholder are, so nothing jumps when you start typing. Each new dot
                                // drops in with a ripple; while checking they ripple in a wave.
                                Item {
                                    id: dotsArea

                                    anchors.left: keyIcon.right
                                    anchors.right: submit.left
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: 40

                                    readonly property int slot: 19
                                    readonly property int maxDots: Math.max(0, Math.floor((width - 8) / slot))
                                    property real phase: 0

                                    NumberAnimation on phase {
                                        from: 0
                                        to: 1
                                        duration: root.busy ? 900 : 2400
                                        loops: Animation.Infinite
                                        running: root.password !== ""
                                    }

                                    // Each dot has a fixed slot, so positions never depend on a layout pass
                                    Item {
                                        id: dots
                                        anchors.fill: parent

                                        Repeater {
                                            model: dotsArea.maxDots

                                            Item {
                                                id: slotItem

                                                required property int index
                                                readonly property bool filled: index < root.password.length
                                                property real drop: 0      // offset while dropping in / leaving

                                                x: index * dotsArea.slot
                                                width: dotsArea.slot
                                                height: 40

                                                onFilledChanged: {
                                                    if (filled) {
                                                        leave.stop();
                                                        arrive.restart();
                                                        ripple.restart();
                                                    } else {
                                                        arrive.stop();
                                                        leave.restart();
                                                    }
                                                }

                                                ParallelAnimation {
                                                    id: arrive
                                                    NumberAnimation { target: dot; property: "scale"; from: 0; to: 1; duration: 420; easing.type: Easing.OutBack; easing.overshoot: 3 }
                                                    NumberAnimation { target: slotItem; property: "drop"; from: -16; to: 0; duration: 480; easing.type: Easing.OutBounce }
                                                }

                                                ParallelAnimation {
                                                    id: leave
                                                    NumberAnimation { target: dot; property: "scale"; to: 0; duration: 180; easing.type: Easing.InBack }
                                                    NumberAnimation { target: slotItem; property: "drop"; from: 0; to: -10; duration: 180; easing.type: Easing.InQuad }
                                                }

                                                // Ring that spreads out from a new dot
                                                Rectangle {
                                                    id: rippleRing
                                                    anchors.centerIn: parent
                                                    width: 12
                                                    height: 12
                                                    radius: 6
                                                    color: "transparent"
                                                    border.width: 1.5
                                                    border.color: dot.color
                                                    opacity: 0
                                                    scale: 1

                                                    ParallelAnimation {
                                                        id: ripple
                                                        NumberAnimation { target: rippleRing; property: "scale"; from: 0.8; to: 2.8; duration: 520; easing.type: Easing.OutCubic }
                                                        NumberAnimation { target: rippleRing; property: "opacity"; from: 0.8; to: 0; duration: 520; easing.type: Easing.OutQuad }
                                                    }
                                                }

                                                Rectangle {
                                                    id: dot

                                                    // Colour flows from primary to tertiary across what you've typed
                                                    readonly property real t: root.password.length > 1 ? Math.min(1, slotItem.index / (root.password.length - 1)) : 0
                                                    readonly property real wave: Math.sin((dotsArea.phase - slotItem.index * 0.09) * Math.PI * 2)

                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    y: (parent.height - height) / 2 + slotItem.drop + wave * (root.busy ? 5 : 1.2)
                                                    width: 12
                                                    height: 12
                                                    radius: 6
                                                    scale: 0
                                                    color: Qt.tint(win.primary, Qt.alpha(win.tertiary, t))
                                                    opacity: root.busy ? 0.55 + 0.45 * (wave + 1) / 2 : 1

                                                    Behavior on color { ColorAnimation { duration: 260 } }

                                                    // Soft highlight so each dot looks like a little bead
                                                    Rectangle {
                                                        x: 2.5
                                                        y: 2
                                                        width: 4.5
                                                        height: 4.5
                                                        radius: 2.25
                                                        color: Qt.alpha("white", 0.45)
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Typing caret: just after the last dot
                                    Rectangle {
                                        id: caret

                                        anchors.verticalCenter: parent.verticalCenter
                                        x: Math.min(root.password.length, dotsArea.maxDots) * dotsArea.slot + (root.password === "" ? 0 : 3)
                                        visible: !root.busy && root.password.length < dotsArea.maxDots
                                        width: 2
                                        height: 22
                                        radius: 1
                                        color: win.primary

                                        Behavior on x { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }

                                        // Solid while typing, blinks when you stop
                                        SequentialAnimation on opacity {
                                            id: blink
                                            loops: Animation.Infinite
                                            PauseAnimation { duration: 500 }
                                            NumberAnimation { to: 0; duration: 200 }
                                            PauseAnimation { duration: 300 }
                                            NumberAnimation { to: 1; duration: 120 }
                                        }

                                        Connections {
                                            target: root
                                            function onPasswordChanged() {
                                                caret.opacity = 1;
                                                blink.restart();
                                            }
                                        }
                                    }

                                    // Placeholder: slides away to the right as you start typing
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: root.password === "" ? 12 : 40
                                        opacity: root.password === "" ? 1 : 0
                                        text: root.busy ? "Signing in…" : "Password"
                                        color: root.c("outline", "#8f909a")
                                        font.family: "Rubik"
                                        font.pixelSize: 16

                                        Behavior on x { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                                        Behavior on opacity { NumberAnimation { duration: 200 } }
                                    }
                                }

                                Text {
                                    anchors.right: submit.left
                                    anchors.rightMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: root.password.length > dotsArea.maxDots
                                    text: `+${root.password.length - dotsArea.maxDots}`
                                    color: win.fgDim
                                    font.family: "Rubik"
                                    font.pixelSize: 12
                                }

                                // Sign-in button: arrow, or a spinning arc while checking
                                Rectangle {
                                    id: submit

                                    anchors.right: parent.right
                                    anchors.rightMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 44
                                    height: 44
                                    radius: 22
                                    color: field.active ? field.accent : Qt.alpha(win.fg, 0.08)
                                    scale: submitMouse.pressed ? 0.9 : 1

                                    Behavior on color { ColorAnimation { duration: 250 } }
                                    Behavior on scale { NumberAnimation { duration: 120 } }

                                    Text {
                                        anchors.centerIn: parent
                                        visible: !root.busy
                                        text: "arrow_forward"
                                        color: field.active ? root.c("on_primary", "#112f60") : win.fgDim
                                        font.family: "Material Symbols Rounded"
                                        font.pixelSize: 22
                                        x: submitMouse.containsMouse && field.active ? 2 : 0
                                    }

                                    Shape {
                                        id: spinner
                                        anchors.centerIn: parent
                                        width: 24
                                        height: 24
                                        visible: root.busy
                                        preferredRendererType: Shape.CurveRenderer

                                        ShapePath {
                                            strokeColor: root.c("on_primary", "#112f60")
                                            strokeWidth: 3
                                            fillColor: "transparent"
                                            capStyle: ShapePath.RoundCap
                                            PathAngleArc { centerX: 12; centerY: 12; radiusX: 10; radiusY: 10; startAngle: 0; sweepAngle: 260 }
                                        }

                                        RotationAnimation on rotation {
                                            running: root.busy
                                            from: 0
                                            to: 360
                                            duration: 800
                                            loops: Animation.Infinite
                                        }
                                    }

                                    MouseArea {
                                        id: submitMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.submit()
                                    }
                                }
                            }

                            // Error or Caps Lock note (only takes space when shown)
                            Item {
                                width: parent.width
                                height: note.visible ? note.height : 0
                                clip: true

                                Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                                Rectangle {
                                    id: note

                                    readonly property bool isError: root.error !== ""

                                    visible: isError || root.capsLock
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: noteRow.implicitWidth + 28
                                    height: 34
                                    radius: 17
                                    color: isError ? Qt.alpha(root.c("error_container", "#93000a"), 0.85) : Qt.alpha(root.c("tertiary_container", "#5a3f63"), 0.85)

                                    Row {
                                        id: noteRow
                                        anchors.centerIn: parent
                                        spacing: 8

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: note.isError ? "error" : "keyboard_capslock"
                                            color: note.isError ? root.c("on_error_container", "#ffdad6") : root.c("on_tertiary_container", "#f9d8fe")
                                            font.family: "Material Symbols Rounded"
                                            font.pixelSize: 18
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: note.isError ? root.error : "Caps Lock is on"
                                            color: note.isError ? root.c("on_error_container", "#ffdad6") : root.c("on_tertiary_container", "#f9d8fe")
                                            font.family: "Rubik"
                                            font.pixelSize: 13
                                            font.weight: Font.Medium
                                        }
                                    }
                                }
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.busy ? "Checking your password" : root.users.length > 1 && root.password === "" ? "Enter to sign in  ·  ← → switch user" : "Press Enter to sign in"
                                color: Qt.alpha(win.fgDim, 0.7)
                                font.family: "Rubik"
                                font.pixelSize: 12
                                font.letterSpacing: 0.4
                            }
                        }
                    }

                    // Avatar sitting on the card's top edge, with a slowly turning colour ring
                    Item {
                        id: avatarHolder

                        width: 124
                        height: 124
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: -height / 2 + 4

                        Shape {
                            id: ring

                            anchors.fill: parent
                            scale: 1 + 0.05 * root.pulse
                            preferredRendererType: Shape.CurveRenderer

                            ShapePath {
                                strokeWidth: -1
                                fillGradient: ConicalGradient {
                                    centerX: 62
                                    centerY: 62
                                    angle: 90
                                    GradientStop { position: 0; color: root.error ? win.errorColor : win.primary }
                                    GradientStop { position: 0.33; color: root.error ? Qt.darker(win.errorColor, 1.4) : win.tertiary }
                                    GradientStop { position: 0.66; color: root.error ? win.errorColor : win.secondary }
                                    GradientStop { position: 1; color: root.error ? win.errorColor : win.primary }
                                }
                                PathAngleArc { centerX: 62; centerY: 62; radiusX: 62; radiusY: 62; startAngle: 0; sweepAngle: 360 }
                            }

                            RotationAnimation on rotation {
                                id: ringSpin
                                from: 0
                                to: 360
                                duration: root.busy ? 1100 : 14000
                                loops: Animation.Infinite
                                running: true
                            }
                        }

                        ClippingRectangle {
                            anchors.centerIn: parent
                            width: 112
                            height: 112
                            radius: 56
                            color: root.c("primary_container", "#2c4578")
                            border.width: 4
                            border.color: root.c("surface_container", "#1e1f25")

                            Image {
                                id: face
                                anchors.fill: parent
                                source: `file://${root.dataDir}/avatar.png`
                                fillMode: Image.PreserveAspectCrop
                                cache: false
                                sourceSize.width: 224
                            }

                            // No avatar: the name's first letter
                            Text {
                                anchors.centerIn: parent
                                visible: face.status !== Image.Ready
                                text: root.user.name.charAt(0).toUpperCase()
                                color: root.c("on_primary_container", "#d9e2ff")
                                font.family: "Rubik"
                                font.pixelSize: 44
                                font.weight: Font.Medium
                            }

                            // Signed in: a check over the avatar
                            Rectangle {
                                anchors.fill: parent
                                color: Qt.alpha(win.primary, 0.75)
                                opacity: root.leaving ? 1 : 0

                                Behavior on opacity { NumberAnimation { duration: 250 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "check"
                                    color: root.c("on_primary", "#112f60")
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 52
                                    scale: root.leaving ? 1 : 0.4

                                    Behavior on scale { NumberAnimation { duration: 350; easing.type: Easing.OutBack } }
                                }
                            }
                        }
                    }
                }

                // Idle: a hint under the clock
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: clockBlock.bottom
                    anchors.topMargin: 48
                    text: "Press any key to sign in"
                    color: Qt.alpha(win.fgDim, 0.8)
                    font.family: "Rubik"
                    font.pixelSize: 15
                    font.letterSpacing: 0.6
                    opacity: root.idle ? 1 : 0

                    Behavior on opacity { NumberAnimation { duration: 600 } }
                }

                // ── Bottom left: session, battery ──
                Row {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    anchors.margins: 28
                    spacing: 10

                    Chip {
                        icon: "desktop_windows"
                        label: "Hyprland" + (root.preview ? "  ·  preview" : "")
                    }

                    Chip {
                        visible: root.battery >= 0
                        icon: root.charging ? "battery_charging_full"
                            : root.battery > 90 ? "battery_full" : root.battery > 60 ? "battery_5_bar"
                            : root.battery > 30 ? "battery_3_bar" : root.battery > 15 ? "battery_2_bar" : "battery_alert"
                        label: `${root.battery}%`
                        tint: root.battery <= 15 && !root.charging ? win.errorColor : win.fgDim
                    }
                }

                // ── Bottom right: power (click twice to confirm restart / shut down) ──
                Row {
                    id: power

                    property string confirming: ""

                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 24
                    spacing: 10

                    Timer {
                        id: confirmTimeout
                        interval: 3000
                        onTriggered: power.confirming = ""
                    }

                    Repeater {
                        model: [
                            { icon: "bedtime", action: "suspend", label: "Sleep" },
                            { icon: "restart_alt", action: "reboot", label: "Restart" },
                            { icon: "power_settings_new", action: "poweroff", label: "Shut down" }
                        ]

                        Rectangle {
                            id: btn

                            required property var modelData
                            readonly property bool confirming: power.confirming === modelData.action
                            readonly property bool expanded: mouse.containsMouse || confirming

                            width: expanded ? btnRow.implicitWidth + 32 : 48
                            height: 48
                            radius: 24
                            clip: true
                            color: confirming ? root.c("error_container", "#93000a")
                                : mouse.containsMouse ? Qt.alpha(root.c("surface_container_highest", "#33353a"), 0.85)
                                : Qt.alpha(root.c("surface_container", "#1e1f25"), 0.55)
                            border.width: 1
                            border.color: Qt.alpha(root.c("outline_variant", "#45464f"), 0.6)

                            Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 200 } }

                            Row {
                                id: btnRow
                                x: 13
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 8

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: btn.modelData.icon
                                    color: btn.confirming ? root.c("on_error_container", "#ffdad6") : btn.modelData.action === "poweroff" ? win.errorColor : win.fgDim
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 22
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: btn.confirming ? "Click again" : btn.modelData.label
                                    color: btn.confirming ? root.c("on_error_container", "#ffdad6") : win.fg
                                    font.family: "Rubik"
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                    opacity: btn.expanded ? 1 : 0

                                    Behavior on opacity { NumberAnimation { duration: 180 } }
                                }
                            }

                            MouseArea {
                                id: mouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    const action = btn.modelData.action;
                                    if (action !== "suspend" && power.confirming !== action) {
                                        power.confirming = action;
                                        confirmTimeout.restart();
                                        return;
                                    }
                                    power.confirming = "";
                                    if (root.preview)
                                        console.log("preview: would run systemctl", action);
                                    else
                                        Quickshell.execDetached(["systemctl", action]);
                                }
                            }
                        }
                    }
                }
            }

            // Fade to black on successful login (above everything)
            Rectangle {
                anchors.fill: parent
                color: "black"
                opacity: root.leaving ? 1 : 0
                visible: opacity > 0

                Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.InOutQuad } }
            }
        }
    }
}
