import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property bool darkMode: false
    property bool collapsed: false

    color: "transparent"
    border.width: 0
    radius: 0

    readonly property int bannerHeight: root.collapsed ? 0 : 110

    Image {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.bannerHeight
        source: darkMode
                ? Qt.resolvedUrl("../../../../../media/dark_2k_banner.png")
                : Qt.resolvedUrl("../../../../../media/2k_banner.png")
        fillMode: Image.PreserveAspectCrop
        visible: !root.collapsed
        z: 3
    }

    Rectangle {
        anchors.fill: parent
        color: darkMode ? "transparent" : "#22ffffff"
        z: 1
    }

    Rectangle {
        id: collapseButton
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.top: parent.top
        anchors.topMargin: 12
        width: 36
        height: 36
        radius: 10
        color: darkMode ? "#33ffffff" : "#ffe4dd"
        border.width: darkMode ? 1 : 0
        border.color: darkMode ? "#55ffffff" : "transparent"
        z: 4

        Text {
            anchors.centerIn: parent
            text: "≡"
            font.pixelSize: 18
            color: darkMode ? "#f2f2f7" : "#6b3a34"
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: appState.toggleSidebarCollapsed()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: root.collapsed ? 60 : (root.bannerHeight + 12)
        anchors.bottomMargin: 12
        spacing: root.collapsed ? 10 : 12
        z: 3

        Item { Layout.preferredHeight: 8 }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            SidebarItem {
                Layout.fillWidth: true
                label: "Inbox"
                iconText: "⌂"
                collapsed: root.collapsed
                darkMode: root.darkMode
                selected: appState.currentSection === "Inbox"
                onClicked: appState.selectSection("Inbox")
            }

            SidebarItem {
                Layout.fillWidth: true
                label: "Today"
                iconText: "•"
                collapsed: root.collapsed
                darkMode: root.darkMode
                selected: appState.currentSection === "Today"
                onClicked: appState.selectSection("Today")
            }

            SidebarItem {
                Layout.fillWidth: true
                label: "Upcoming"
                iconText: "◷"
                collapsed: root.collapsed
                darkMode: root.darkMode
                selected: appState.currentSection === "Upcoming"
                onClicked: appState.selectSection("Upcoming")
            }
        }

        Item {
            Layout.fillHeight: true
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            SidebarItem {
                Layout.fillWidth: true
                label: "Settings"
                iconText: "⚙"
                collapsed: root.collapsed
                darkMode: root.darkMode
                selected: appState.currentSection === "Settings"
                onClicked: appState.selectSection("Settings")
            }

            SidebarItem {
                Layout.fillWidth: true
                label: "Profile"
                iconText: "◉"
                collapsed: root.collapsed
                darkMode: root.darkMode
                selected: appState.currentSection === "Profile"
                onClicked: appState.selectSection("Profile")
            }
        }
    }
}
