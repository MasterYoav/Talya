import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
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
            spacing: 10

            Label {
                text: "Inbox"
                font.pixelSize: 22
                color: "#2a2a2a"
            }

            Label {
                text: "Today"
                font.pixelSize: 22
                color: "#2a2a2a"
            }

            Label {
                text: "Upcoming"
                font.pixelSize: 22
                color: "#2a2a2a"
            }
        }
    }
}
