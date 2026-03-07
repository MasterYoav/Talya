import QtQuick

import "components"

Rectangle {
    id: root
    color: "transparent"

    readonly property int sidebarWidth: appState.sidebarCollapsed ? 64 : 272

    Rectangle {
        x: root.sidebarWidth
        width: root.width - root.sidebarWidth
        height: root.height
        color: appState.darkMode ? "#050505" : "#f6f7fb"
    }

    Loader {
        id: mainLoader
        anchors.fill: parent
        sourceComponent: appState.currentSection === "Settings"
                         ? settingsViewComponent
                         : appState.currentSection === "Profile"
                           ? profileViewComponent
                           : tasksViewComponent
    }

    Sidebar {
        id: sidebar
        z: 10
        x: 0
        y: 0
        width: root.sidebarWidth
        height: parent.height
        darkMode: appState.darkMode
        collapsed: appState.sidebarCollapsed
    }

    Component {
        id: tasksViewComponent

        ContentView {
            darkMode: appState.darkMode
            sidebarWidth: root.sidebarWidth
        }
    }

    Component {
        id: settingsViewComponent

        SettingsView {
            darkMode: appState.darkMode
            sidebarWidth: root.sidebarWidth
        }
    }

    Component {
        id: profileViewComponent

        ProfileView {
            darkMode: appState.darkMode
            sidebarWidth: root.sidebarWidth
        }
    }
}
