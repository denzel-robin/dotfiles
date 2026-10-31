import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.config
import qs.services
import qs.widgets

// One notification. As a popup it times out (paused while hovered);
// in the notification center it stays until dismissed.
Rectangle {
    id: root

    required property var notif
    property bool popup: false

    readonly property bool critical: notif?.urgency === NotificationUrgency.Critical
    // Quickshell puts an app icon *name* (e.g. "kitty") in `image` as image://icon/<name>;
    // that's an app icon, not a picture
    readonly property bool imageIsIcon: (notif?.image ?? "").startsWith("image://icon/")
    readonly property string picture: imageIsIcon ? "" : notif?.image ?? ""

    // App icon: the sending app's desktop entry wins, so icon overrides (themed
    // terminal, original Zen…) apply however the app sends its icon
    readonly property string appIcon: {
        if (!notif)
            return "";
        const entry = (notif.desktopEntry && DesktopEntries.byId(notif.desktopEntry)) || (notif.appName && DesktopEntries.heuristicLookup(notif.appName));
        if (entry) {
            const fromEntry = Apps.iconFor(entry);
            if (fromEntry)
                return fromEntry;
        }
        if (imageIsIcon)
            return Apps.iconForClass(notif.image.slice("image://icon/".length));   // "" -> generic bell
        const i = notif.appIcon ?? "";
        if (i.includes("://"))
            return i;
        if (i.startsWith("/"))
            return `file://${i}`;
        return Apps.iconForClass(i);
    }
    readonly property var actions: notif?.actions.filter(a => a.identifier !== "default") ?? []

    implicitWidth: 380
    implicitHeight: layout.implicitHeight + Appearance.padding.large * 2
    radius: Appearance.rounding.normal
    color: popup ? Colors.surfaceContainer : Colors.surfaceContainerHigh
    border.width: critical ? 2 : 1
    border.color: critical ? Colors.error : Colors.alpha(Colors.outlineVariant, 0.35)

    Behavior on color { CAnim {} }

    MouseArea {
        id: hover

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Notifs.defaultAction(root.notif) ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            Notifs.defaultAction(root.notif)?.invoke();
            if (root.popup)
                Notifs.hidePopup(root.notif);
        }
    }

    Timer {
        interval: root.notif ? Notifs.popupDuration(root.notif) : 0
        running: root.popup && interval > 0 && !hover.containsMouse
        onTriggered: Notifs.hidePopup(root.notif)
    }

    RowLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Appearance.padding.large
        spacing: Appearance.spacing.large

        // Picture: notification image > app icon > generic bell
        ClippingRectangle {
            Layout.alignment: Qt.AlignTop
            implicitWidth: 42
            implicitHeight: 42
            radius: Appearance.rounding.full
            color: root.critical ? Colors.errorContainer : Colors.secondaryContainer

            Image {
                id: picture
                anchors.fill: parent
                visible: source != ""
                source: root.picture
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }

            IconImage {
                anchors.centerIn: parent
                visible: !picture.visible && root.appIcon !== ""
                implicitSize: 26
                source: root.appIcon
            }

            MaterialIcon {
                anchors.centerIn: parent
                visible: !picture.visible && root.appIcon === ""
                icon: root.critical ? "priority_high" : "notifications"
                fill: 1
                color: root.critical ? Colors.error : Colors.textOnSecondaryContainer
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.small

                StyledText {
                    text: root.notif?.appName || "Notification"
                    font.pixelSize: Appearance.font.small
                    color: Colors.textOnSurfaceVariant
                }

                StyledText {
                    text: `· ${Notifs.age(root.notif, Time.date)}`
                    font.pixelSize: Appearance.font.small
                    color: Colors.outline
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    implicitWidth: 24
                    implicitHeight: 24
                    radius: 12
                    color: "transparent"

                    MaterialIcon {
                        anchors.centerIn: parent
                        icon: "close"
                        size: 16
                        color: Colors.textOnSurfaceVariant
                    }

                    StateLayer {
                        onClicked: root.notif.dismiss()
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: root.notif?.summary ?? ""
                font.pixelSize: Appearance.font.normal + 1
                font.weight: Font.DemiBold
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.notif?.body ?? ""
                textFormat: Text.StyledText
                color: Colors.textOnSurfaceVariant
                linkColor: Colors.primary
                wrapMode: Text.Wrap
                maximumLineCount: root.popup ? 4 : 8
                elide: Text.ElideRight
                onLinkActivated: link => Qt.openUrlExternally(link)
            }

            Flow {
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.normal
                visible: root.actions.length > 0
                spacing: Appearance.spacing.normal

                Repeater {
                    model: root.actions

                    Rectangle {
                        id: action

                        required property var modelData

                        implicitWidth: label.implicitWidth + Appearance.padding.large * 2
                        implicitHeight: 30
                        radius: Appearance.rounding.full
                        color: Colors.secondaryContainer

                        StyledText {
                            id: label
                            anchors.centerIn: parent
                            text: action.modelData.text
                            font.pixelSize: Appearance.font.small
                            color: Colors.textOnSecondaryContainer
                        }

                        StateLayer {
                            onClicked: {
                                action.modelData.invoke();
                                if (root.popup)
                                    Notifs.hidePopup(root.notif);
                            }
                        }
                    }
                }
            }
        }
    }
}
