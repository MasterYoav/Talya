import QtQuick

import "components"

Rectangle {
    id: root
    color: appState.darkMode ? "#050505" : "#f6f7fb"

    readonly property int sidebarWidth: appState.sidebarCollapsed ? 84 : 272

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

        Behavior on width {
            NumberAnimation { duration: 180 }
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

        Rectangle {
            property int sidebarWidth: root.sidebarWidth
            color: appState.darkMode ? "#050505" : "#f6f7fb"

            Column {
                anchors.fill: parent
                anchors.leftMargin: sidebarWidth + 28
                anchors.rightMargin: 28
                anchors.topMargin: 28
                anchors.bottomMargin: 28
                spacing: 22

                Rectangle {
                    width: parent.width
                    height: 64
                    radius: 18
                    color: appState.darkMode ? "#101114" : "#ffffff"
                    border.width: appState.darkMode ? 0 : 1
                    border.color: "#00000008"

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 22
                        text: "Profile"
                        font.pixelSize: 34
                        font.bold: true
                        color: appState.darkMode ? "#f2f2f7" : "#1c1c1e"
                    }
                }

                Rectangle {
                    width: Math.min(parent.width, 860)
                    height: 180
                    radius: 22
                    color: appState.darkMode ? "#0b0c0f" : "#ffffff"
                    border.width: appState.darkMode ? 0 : 1
                    border.color: "#00000008"

                    Text {
                        anchors.centerIn: parent
                        text: "Profile page — future feature"
                        font.pixelSize: 18
                        color: appState.darkMode ? "#8e8e93" : "#6e6e73"
                    }
                }
            }
        }
    }
}
