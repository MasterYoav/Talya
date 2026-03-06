import QtQuick
import QtQuick.Controls

Rectangle {
    id: root

    property string currentSection: "Today"
    signal sectionSelected(string section)

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
                selected: root.currentSection === "Inbox"
                onClicked: root.sectionSelected("Inbox")
            }

            SidebarItem {
                label: "Today"
                selected: root.currentSection === "Today"
                onClicked: root.sectionSelected("Today")
            }

            SidebarItem {
                label: "Upcoming"
                selected: root.currentSection === "Upcoming"
                onClicked: root.sectionSelected("Upcoming")
            }
        }
    }
}
