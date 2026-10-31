import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

Tile {
    RowLayout {
        id: now

        width: parent.width
        spacing: Appearance.spacing.large

        MaterialIcon {
            icon: Weather.icon
            size: 52
            fill: 1
            color: Colors.primary
        }

        ColumnLayout {
            spacing: 0

            StyledText {
                text: Weather.ready ? `${Weather.temp}°` : "--°"
                font.pixelSize: 34
                font.weight: Font.Medium
            }

            StyledText {
                text: Weather.ready ? Weather.description : "Loading weather…"
                color: Colors.textOnSurfaceVariant
            }
        }

        Item { Layout.fillWidth: true }

        ColumnLayout {
            visible: Weather.ready
            spacing: 2

            StyledText {
                Layout.alignment: Qt.AlignRight
                text: Weather.location
                font.weight: Font.Medium
            }

            StyledText {
                Layout.alignment: Qt.AlignRight
                text: `Feels ${Weather.feelsLike}° · ${Weather.humidity}%`
                font.pixelSize: Appearance.font.small
                color: Colors.textOnSurfaceVariant
            }
        }
    }

    RowLayout {
        id: forecastRow

        anchors.top: now.bottom
        anchors.topMargin: Appearance.spacing.large
        width: parent.width
        visible: Weather.forecast.length > 0

        Repeater {
            model: Weather.forecast

            ColumnLayout {
                required property var modelData
                required property int index

                Layout.fillWidth: true
                spacing: 2

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: index === 0 ? "Today" : modelData.day
                    font.pixelSize: Appearance.font.small
                    color: Colors.textOnSurfaceVariant
                }

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    icon: modelData.icon
                    size: 22
                    color: Colors.secondary
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: `${modelData.max}° / ${modelData.min}°`
                    font.pixelSize: Appearance.font.small
                }
            }
        }
    }

    // Where: Auto (by network) · College · Home
    RowLayout {
        anchors.top: forecastRow.visible ? forecastRow.bottom : now.bottom
        anchors.topMargin: Appearance.spacing.large
        width: parent.width
        spacing: Appearance.spacing.small

        MaterialIcon {
            icon: Place.place.icon
            size: 16
            color: Colors.primary
        }

        StyledText {
            Layout.fillWidth: true
            text: Place.mode === "auto" ? `Auto · ${Place.place.label}` : Place.place.label
            font.pixelSize: Appearance.font.small
            color: Colors.textOnSurfaceVariant
            elide: Text.ElideRight
        }

        Rectangle {
            implicitWidth: seg.implicitWidth + 4
            implicitHeight: 26
            radius: 13
            color: Colors.surfaceContainerHighest

            Row {
                id: seg
                anchors.centerIn: parent

                Repeater {
                    model: [["auto", "Auto"], ["college", "College"], ["home", "Home"]]

                    Rectangle {
                        required property var modelData
                        readonly property bool active: Place.mode === modelData[0]

                        implicitWidth: label.implicitWidth + 16
                        implicitHeight: 22
                        radius: 11
                        color: active ? Colors.primary : "transparent"

                        Behavior on color { CAnim { duration: Appearance.anim.fast } }

                        StyledText {
                            id: label
                            anchors.centerIn: parent
                            text: parent.modelData[1]
                            font.pixelSize: Appearance.font.small - 1
                            font.weight: parent.active ? Font.DemiBold : Font.Normal
                            color: parent.active ? Colors.textOnPrimary : Colors.textOnSurfaceVariant
                        }

                        StateLayer {
                            onClicked: Place.choose(parent.modelData[0])
                        }
                    }
                }
            }
        }
    }
}
