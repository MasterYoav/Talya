import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property bool darkMode: false
    property bool collapsed: false

    color: darkMode ? "#660b0c10" : "#99ffffff"
    border.width: darkMode ? 0 : 1
    border.color: "#ffffffaa"
    radius: 0

    Rectangle {
        anchors.fill: parent
        color: darkMode ? "#14000000" : "#22ffffff"
    }

    Rectangle {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: 1
        color: darkMode ? "#1affffff" : "#40ffffff"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            spacing: 12

            Rectangle {
                width: 42
                height: 42
                radius: 12
                color: darkMode ? "#14ffffff" : "#ccffffff"
                border.width: darkMode ? 0 : 1
                border.color: "#ffffffcc"

                Text {
                    anchors.centerIn: parent
                    text: "≡"
                    font.pixelSize: 18
                    color: darkMode ? "#f2f2f7" : "#1c1c1e"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: appState.toggleSidebarCollapsed()
                }
            }

            Text {
                visible: !root.collapsed
                text: "Talya"
                font.pixelSize: 28
                font.bold: true
                color: darkMode ? "#f2f2f7" : "#1c1c1e"
                Layout.alignment: Qt.AlignVCenter
            }

            Item {
                Layout.fillWidth: true
            }
        }

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
