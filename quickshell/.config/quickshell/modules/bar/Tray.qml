import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.config
import qs.widgets

// App tray icons. Left click: activate, right click: menu, middle: secondary action.
Island {
    visible: SystemTray.items.values.length > 0

    Repeater {
        model: SystemTray.items

        Item {
            id: entry

            required property SystemTrayItem modelData

            implicitWidth: 28
            implicitHeight: 28
            anchors.horizontalCenter: parent?.horizontalCenter

            IconImage {
                anchors.centerIn: parent
                implicitSize: 18
                source: entry.modelData.icon
            }

            TrayMenu {
                id: menu
                anchorItem: entry
                handle: entry.modelData.menu
            }

            StateLayer {
                radius: Appearance.rounding.small
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: event => {
                    if (event.button === Qt.MiddleButton)
                        entry.modelData.secondaryActivate();
                    else if ((event.button === Qt.RightButton || entry.modelData.onlyMenu) && entry.modelData.hasMenu)
                        menu.open();
                    else
                        entry.modelData.activate();
                }
            }
        }
    }
}
