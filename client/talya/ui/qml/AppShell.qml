import QtQuick

import "components"

Rectangle {
    id: root
    color: "transparent"

    readonly property int sidebarWidth: appState && appState.sidebarCollapsed ? 64 : 272

    Rectangle {
        x: root.sidebarWidth
        width: root.width - root.sidebarWidth
        height: root.height
        color: appState && appState.darkMode ? "#050505" : "#f6f7fb"

        Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    }

    Loader {
        id: mainLoader
        anchors.fill: parent
        sourceComponent: appState && appState.currentListType === "settings"
                         ? settingsViewComponent
                         : appState && appState.currentListType === "profile"
                           ? profileViewComponent
                           : appState && appState.currentListType === "calendar"
                             ? calendarViewComponent
                             : tasksViewComponent
    }

    Sidebar {
        id: sidebar
        z: 10
        x: 0
        y: 0
        width: root.sidebarWidth
        height: parent.height
        darkMode: appState && appState.darkMode
        collapsed: appState && appState.sidebarCollapsed

        Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    }

    Rectangle {
        width: 320
        height: appState && appState.bannerVisible ? 56 : 0
        radius: 16
        color: appState && appState.darkMode ? "#16181d" : "#ffffff"
        border.width: appState && appState.darkMode ? 0 : 1
        border.color: "#00000012"
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 18
        visible: appState && appState.bannerVisible
        z: 20

        Behavior on height {
            NumberAnimation { duration: 160 }
        }

        Text {
            anchors.centerIn: parent
            text: appState ? appState.bannerMessage : ""
            font.pixelSize: 14
            color: appState && appState.darkMode ? "#f2f2f7" : "#1c1c1e"
        }
    }

    Component {
        id: tasksViewComponent

        ContentView {
            darkMode: appState && appState.darkMode
            sidebarWidth: root.sidebarWidth
        }
    }

    Component {
        id: settingsViewComponent

        SettingsView {
            darkMode: appState && appState.darkMode
            sidebarWidth: root.sidebarWidth
        }
    }

    Component {
        id: profileViewComponent

        ProfileView {
            darkMode: appState && appState.darkMode
            sidebarWidth: root.sidebarWidth
        }
    }

    Component {
        id: calendarViewComponent

        CalendarView {
            darkMode: appState && appState.darkMode
            sidebarWidth: root.sidebarWidth
        }
    }
}
