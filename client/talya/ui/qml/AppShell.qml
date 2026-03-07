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
        sourceComponent: appState.currentListType === "settings"
                         ? settingsViewComponent
                         : appState.currentListType === "profile"
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

    Rectangle {
        width: 320
        height: appState.bannerVisible ? 56 : 0
        radius: 16
        color: appState.darkMode ? "#16181d" : "#ffffff"
        border.width: appState.darkMode ? 0 : 1
        border.color: "#00000012"
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 18
        visible: appState.bannerVisible
        z: 20

        Behavior on height {
            NumberAnimation { duration: 160 }
        }

        Text {
            anchors.centerIn: parent
            text: appState.bannerMessage
            font.pixelSize: 14
            color: appState.darkMode ? "#f2f2f7" : "#1c1c1e"
        }
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
