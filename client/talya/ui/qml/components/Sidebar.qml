import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property bool darkMode: false
    property bool collapsed: false

    color: darkMode ? "#1c1c1ecc" : "#f7f7f799"
    border.color: darkMode ? "#ffffff12" : "#0000000d"
    border.width: 1
    radius: 0

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
                color: darkMode ? "#ffffff10" : "#00000006"

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

        Item {
            Layout.preferredHeight: 8
        }

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
                selected: false
                onClicked: appState.openSettings()
            }

            SidebarItem {
                Layout.fillWidth: true
                label: "Profile"
                iconText: "◉"
                collapsed: root.collapsed
                darkMode: root.darkMode
                selected: false
                onClicked: console.log("Profile page is a future feature")
            }
        }
    }
}
