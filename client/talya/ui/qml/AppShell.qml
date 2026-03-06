import QtQuick
import QtQuick.Layouts

import "components"

Rectangle {
    id: root
    color: appState.darkMode ? "#111214" : "#f5f5f7"

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.preferredWidth: appState.sidebarCollapsed ? 84 : 272
            Layout.fillHeight: true
            color: "transparent"

            Behavior on Layout.preferredWidth {
                NumberAnimation { duration: 180 }
            }

            Sidebar {
                anchors.fill: parent
                darkMode: appState.darkMode
                collapsed: appState.sidebarCollapsed
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: appState.darkMode ? "#111214" : "#f5f5f7"

            ContentView {
                anchors.fill: parent
                darkMode: appState.darkMode
            }
        }
    }

    SettingsPanel {
        darkMode: appState.darkMode
    }
}
