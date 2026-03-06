import QtQuick
import QtQuick.Controls

Rectangle {
    id: root

    color: "#e9e7e1"

    Column {
        anchors.fill: parent
        anchors.margins: 22
        spacing: 18

        Text {
            text: "Talya"
            font.pixelSize: 30
            font.bold: true
            color: "#1f1f1f"
        }

        Item {
            width: 1
            height: 8
        }

        Column {
            width: parent.width
            spacing: 8

            SidebarItem {
                label: "Inbox"
                selected: appState.currentSection === "Inbox"
                onClicked: appState.selectSection("Inbox")
            }

            SidebarItem {
                label: "Today"
                selected: appState.currentSection === "Today"
                onClicked: appState.selectSection("Today")
            }

            SidebarItem {
                label: "Upcoming"
                selected: appState.currentSection === "Upcoming"
                onClicked: appState.selectSection("Upcoming")
            }
        }
    }
}
