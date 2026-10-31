import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

// Dashboard sliding out from the bar: greeting, weather, calendar, toggles, media, stats.
Overlay {
    id: root

    name: "dashboard"

    onShownChanged: if (shown) Panels.dashboardPage = ""

    Card {
        id: card

        anchors.left: parent.left
        anchors.leftMargin: Appearance.bar.margin * 2 + Appearance.bar.islandWidth
        anchors.verticalCenter: parent.verticalCenter
        width: grid.implicitWidth + Appearance.padding.large * 2
        height: grid.implicitHeight + Appearance.padding.large * 2
        opacity: root.progress
        transform: Translate { x: (root.progress - 1) * 60 }
        scale: 0.96 + 0.04 * root.progress
        transformOrigin: Item.Left

        RowLayout {
            id: grid

            anchors.centerIn: parent
            spacing: Appearance.spacing.large

            ColumnLayout {
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: 340
                spacing: Appearance.spacing.large

                Header { Layout.fillWidth: true }
                WeatherCard { Layout.fillWidth: true }
                CalendarCard { Layout.fillWidth: true; shown: root.shown }
            }

            // Overview, or a details page (e.g. Network) in the same spot
            ColumnLayout {
                visible: Panels.dashboardPage === ""
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: 340
                spacing: Appearance.spacing.large

                TogglesCard { Layout.fillWidth: true }
                MediaCard { Layout.fillWidth: true }
                StatsCard { Layout.fillWidth: true }
                TrashCard { Layout.fillWidth: true }
            }

            Loader {
                active: Panels.dashboardPage === "network"
                visible: active
                Layout.preferredWidth: 340
                Layout.fillHeight: true
                sourceComponent: NetworkPage {}
            }
        }
    }
}
