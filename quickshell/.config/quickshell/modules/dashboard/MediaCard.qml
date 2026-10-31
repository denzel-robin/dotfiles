import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.config
import qs.services
import qs.widgets

// Now playing (Spotify, browsers, mpv… anything using MPRIS).
Tile {
    RowLayout {
        id: top

        width: parent.width
        spacing: Appearance.spacing.large

        ClippingRectangle {
            implicitWidth: 72
            implicitHeight: 72
            radius: Appearance.rounding.normal - 6
            color: Colors.secondaryContainer

            Image {
                id: art
                anchors.fill: parent
                source: Media.art
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: status === Image.Ready
            }

            MaterialIcon {
                anchors.centerIn: parent
                visible: !art.visible
                icon: Media.player ? "music_note" : "music_off"
                size: 32
                color: Colors.textOnSecondaryContainer
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            StyledText {
                Layout.fillWidth: true
                text: Media.title
                font.pixelSize: Appearance.font.normal + 1
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                text: Media.artist
                color: Colors.textOnSurfaceVariant
                elide: Text.ElideRight
            }

            // Controls
            RowLayout {
                visible: Media.player !== null
                spacing: Appearance.spacing.small

                Repeater {
                    model: [
                        { icon: "skip_previous", act: () => Media.player.previous(), main: false },
                        { icon: Media.playing ? "pause" : "play_arrow", act: () => Media.player.togglePlaying(), main: true },
                        { icon: "skip_next", act: () => Media.player.next(), main: false }
                    ]

                    Rectangle {
                        required property var modelData

                        implicitWidth: modelData.main ? 44 : 34
                        implicitHeight: 34
                        radius: 17
                        color: modelData.main ? Colors.primary : "transparent"

                        MaterialIcon {
                            anchors.centerIn: parent
                            icon: parent.modelData.icon
                            fill: 1
                            color: parent.modelData.main ? Colors.textOnPrimary : Colors.textOnSurface
                        }

                        StateLayer {
                            onClicked: parent.modelData.act()
                        }
                    }
                }
            }
        }
    }

    // Progress
    ColumnLayout {
        anchors.top: top.bottom
        anchors.topMargin: Appearance.spacing.normal
        width: parent.width
        visible: Media.player !== null && Media.length > 0
        spacing: 2

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 6
            radius: 3
            color: Colors.surfaceContainerHighest

            Rectangle {
                width: parent.width * Math.min(1, Media.position / Math.max(1, Media.length))
                height: parent.height
                radius: 3
                color: Colors.primary

                Behavior on width { Anim { duration: 900; easing.type: Easing.Linear } }
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                enabled: Media.player?.canSeek ?? false
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => Media.player.position = Media.length * mouse.x / width
            }
        }

        RowLayout {
            Layout.fillWidth: true

            StyledText {
                text: Media.formatTime(Media.position)
                font.pixelSize: Appearance.font.small
                color: Colors.textOnSurfaceVariant
            }

            Item { Layout.fillWidth: true }

            StyledText {
                text: Media.formatTime(Media.length)
                font.pixelSize: Appearance.font.small
                color: Colors.textOnSurfaceVariant
            }
        }
    }
}
