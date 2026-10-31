import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.services
import qs.widgets

// Network details (right-click the Wi-Fi tile): Ethernet, Wi-Fi networks, VPN.
Tile {
    id: root

    property string expanded: ""      // name of the secured network whose password field is open
    property string failed: ""        // name of the network that just failed to connect

    Component.onCompleted: Network.setScanning(true)
    Component.onDestruction: Network.setScanning(false)

    ColumnLayout {
        anchors.fill: parent
        spacing: Appearance.spacing.normal

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.small

            IconButton {
                icon: "arrow_back"
                onClicked: Panels.dashboardPage = ""
            }

            StyledText {
                Layout.fillWidth: true
                text: "Network"
                font.pixelSize: Appearance.font.large
                font.weight: Font.Medium
            }

            IconButton {
                id: rescan
                icon: "refresh"
                visible: Network.wifiEnabled
                onClicked: {
                    Network.setScanning(false);
                    Network.setScanning(true);
                    spin.restart();
                }

                RotationAnimation on rotation {
                    id: spin
                    running: false
                    from: 0
                    to: 360
                    duration: 1200
                    loops: 2
                }
            }

            Switch {
                checked: Network.wifiEnabled
                onToggled: Toggles.toggleWifi()
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentHeight: sections.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: sections

                width: parent.width
                spacing: Appearance.spacing.small

                // ── Ethernet ──
                Section {
                    text: "Ethernet"
                    visible: Network.wiredDevices.length > 0
                }

                Repeater {
                    model: Network.wiredDevices

                    Row_ {
                        required property var modelData

                        icon: "lan"
                        active: modelData.connected
                        title: modelData.name
                        subtitle: modelData.connected ? (modelData.linkSpeed > 0 ? `Connected · ${modelData.linkSpeed} Mb/s` : "Connected")
                            : modelData.hasLink ? "Disconnected" : "Cable unplugged"
                        enabled: modelData.hasLink
                        onClicked: modelData.connected ? modelData.disconnect() : modelData.network?.connect()
                    }
                }

                // ── Wi-Fi ──
                Section {
                    text: "Wi-Fi"
                }

                StyledText {
                    visible: !Network.wifiEnabled || Network.networks.length === 0
                    Layout.leftMargin: Appearance.padding.small
                    text: !Network.wifiDevice ? "No Wi-Fi adapter" : !Network.wifiEnabled ? "Wi-Fi is off" : "Searching for networks…"
                    color: Colors.outline
                }

                Repeater {
                    model: Network.wifiEnabled ? Network.networks : []

                    ColumnLayout {
                        id: net

                        required property var modelData
                        readonly property bool secured: Network.isSecured(modelData)
                        readonly property bool open: root.expanded === modelData.name

                        Layout.fillWidth: true
                        spacing: 4

                        Connections {
                            target: net.modelData
                            function onConnectionFailed() {
                                root.failed = net.modelData.name;
                                if (net.secured)
                                    root.expanded = net.modelData.name;
                            }
                        }

                        Row_ {
                            icon: Network.signalIcon(net.modelData.signalStrength)
                            active: net.modelData.connected
                            title: net.modelData.name
                            subtitle: net.modelData.stateChanging ? "Connecting…"
                                : net.modelData.connected ? "Connected"
                                : root.failed === net.modelData.name ? (net.secured ? "Wrong password?" : "Couldn't connect")
                                : net.modelData.known ? "Saved" : net.secured ? "Secured" : "Open"
                            subtitleColor: root.failed === net.modelData.name && !net.modelData.connected ? Colors.error : Colors.textOnSurfaceVariant
                            trailing: net.secured ? "lock" : ""
                            canForget: net.modelData.known
                            onForget: net.modelData.forget()
                            onClicked: {
                                root.failed = "";
                                if (net.modelData.connected)
                                    net.modelData.disconnect();
                                else if (net.modelData.known || !net.secured)
                                    net.modelData.connect();
                                else
                                    root.expanded = net.open ? "" : net.modelData.name;
                            }
                        }

                        // Password for a new secured network
                        Rectangle {
                            visible: net.open
                            Layout.fillWidth: true
                            Layout.leftMargin: 36
                            implicitHeight: 40
                            radius: Appearance.rounding.full
                            color: Colors.surfaceContainerHighest
                            border.width: 1
                            border.color: psk.activeFocus ? Colors.primary : Colors.outlineVariant

                            onVisibleChanged: if (visible) psk.forceActiveFocus()

                            TextInput {
                                id: psk

                                anchors.left: parent.left
                                anchors.right: go.left
                                anchors.leftMargin: Appearance.padding.large
                                anchors.verticalCenter: parent.verticalCenter
                                echoMode: TextInput.Password
                                color: Colors.textOnSurface
                                font.family: Appearance.font.sans
                                font.pixelSize: Appearance.font.normal
                                clip: true
                                onAccepted: go.submit()
                                Keys.onEscapePressed: root.expanded = ""

                                StyledText {
                                    visible: !psk.text
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Password"
                                    color: Colors.outline
                                }
                            }

                            IconButton {
                                id: go

                                function submit(): void {
                                    if (psk.text.length < 8)
                                        return;
                                    root.failed = "";
                                    net.modelData.connectWithPsk(psk.text);
                                    psk.text = "";
                                    root.expanded = "";
                                }

                                anchors.right: parent.right
                                anchors.rightMargin: 4
                                anchors.verticalCenter: parent.verticalCenter
                                icon: "arrow_forward"
                                filled: true
                                onClicked: submit()
                            }
                        }
                    }
                }

                // ── VPN ──
                Section {
                    text: "VPN"
                }

                Row_ {
                    icon: Toggles.warp ? "vpn_lock" : "vpn_key_off"
                    active: Toggles.warp
                    title: "Cloudflare WARP"
                    subtitle: Toggles.warpBusy ? "Connecting…" : Toggles.warp ? "Connected" : "Off"
                    onClicked: Toggles.toggleWarp()
                }
            }
        }

        // Footer
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 36
            radius: Appearance.rounding.full
            color: "transparent"
            border.width: 1
            border.color: Colors.outlineVariant

            Row {
                anchors.centerIn: parent
                spacing: Appearance.spacing.small

                MaterialIcon {
                    icon: "settings"
                    size: 16
                    color: Colors.textOnSurfaceVariant
                }

                StyledText {
                    text: "Advanced settings…"
                    font.pixelSize: Appearance.font.small
                    color: Colors.textOnSurfaceVariant
                }
            }

            StateLayer {
                onClicked: {
                    Panels.close();
                    Quickshell.execDetached(["nm-connection-editor"]);
                }
            }
        }
    }

    // ── Small building blocks for this page ──

    component Section: StyledText {
        Layout.topMargin: Appearance.spacing.normal
        Layout.leftMargin: Appearance.padding.small
        font.pixelSize: Appearance.font.small
        font.weight: Font.DemiBold
        color: Colors.primary
    }

    component IconButton: Rectangle {
        id: btn

        property string icon
        property bool filled: false
        signal clicked

        implicitWidth: 32
        implicitHeight: 32
        radius: 16
        color: filled ? Colors.primary : "transparent"

        MaterialIcon {
            anchors.centerIn: parent
            icon: btn.icon
            size: 20
            color: btn.filled ? Colors.textOnPrimary : Colors.textOnSurface
        }

        StateLayer {
            onClicked: btn.clicked()
        }
    }

    component Switch: Rectangle {
        id: sw

        property bool checked
        signal toggled

        implicitWidth: 44
        implicitHeight: 24
        radius: 12
        color: checked ? Colors.primary : Colors.surfaceContainerHighest
        border.width: checked ? 0 : 1
        border.color: Colors.outline

        Behavior on color { CAnim { duration: Appearance.anim.fast } }

        Rectangle {
            x: sw.checked ? sw.width - width - 4 : 4
            anchors.verticalCenter: parent.verticalCenter
            width: sw.checked ? 16 : 12
            height: width
            radius: width / 2
            color: sw.checked ? Colors.textOnPrimary : Colors.outline

            Behavior on x { Anim { duration: Appearance.anim.fast; easing.bezierCurve: Appearance.anim.spatial } }
            Behavior on width { Anim { duration: Appearance.anim.fast } }
        }

        StateLayer {
            onClicked: sw.toggled()
        }
    }

    component Row_: Rectangle {
        id: row

        property string icon
        property bool active
        property string title
        property string subtitle
        property color subtitleColor: Colors.textOnSurfaceVariant
        property string trailing: ""
        property bool canForget: false
        signal clicked
        signal forget

        Layout.fillWidth: true
        implicitHeight: 48
        radius: Appearance.rounding.small
        color: active ? Colors.primaryContainer : "transparent"
        opacity: enabled ? 1 : 0.5

        Behavior on color { CAnim { duration: Appearance.anim.fast } }

        StateLayer {
            tint: row.active ? Colors.textOnPrimaryContainer : Colors.textOnSurface
            onClicked: row.clicked()
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Appearance.padding.normal
            anchors.rightMargin: Appearance.padding.small
            spacing: Appearance.spacing.normal

            MaterialIcon {
                icon: row.icon
                fill: row.active ? 1 : 0
                color: row.active ? Colors.textOnPrimaryContainer : Colors.textOnSurface
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: row.title
                    font.weight: row.active ? Font.DemiBold : Font.Normal
                    color: row.active ? Colors.textOnPrimaryContainer : Colors.textOnSurface
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: row.subtitle
                    font.pixelSize: Appearance.font.small - 1
                    color: row.active ? Colors.alpha(Colors.textOnPrimaryContainer, 0.75) : row.subtitleColor
                    elide: Text.ElideRight
                }
            }

            MaterialIcon {
                visible: row.trailing !== ""
                icon: row.trailing
                size: 16
                color: row.active ? Colors.textOnPrimaryContainer : Colors.outline
            }

            // Forget a saved network
            Rectangle {
                visible: row.canForget
                implicitWidth: 28
                implicitHeight: 28
                radius: 14
                color: "transparent"

                MaterialIcon {
                    anchors.centerIn: parent
                    icon: "delete"
                    size: 16
                    color: row.active ? Colors.textOnPrimaryContainer : Colors.textOnSurfaceVariant
                }

                StateLayer {
                    tint: Colors.error
                    onClicked: row.forget()
                }
            }
        }
    }
}
