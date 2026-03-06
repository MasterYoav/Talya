import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    color: "#f6f5f1"

    Column {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 34
        spacing: 22

        Text {
            text: "Today"
            font.pixelSize: 34
            font.bold: true
            color: "#1e1e1e"
        }

        Rectangle {
            width: 560
            height: 58
            radius: 16
            color: "#ffffff"
            border.color: "#ddd9d0"
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "Your first Talya task list will live here"
                color: "#666666"
                font.pixelSize: 16
            }
        }
    }
}
