import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property string currentSection: "Today"

    color: "#f6f5f1"

    Column {
        anchors.fill: parent
        anchors.margins: 30
        spacing: 24

        Rectangle {
            width: parent.width
            height: 64
            radius: 18
            color: "#f0ede7"
            border.color: "#e1ddd4"
            border.width: 1

            Row {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 14

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.currentSection
                    font.pixelSize: 34
                    font.bold: true
                    color: "#1e1e1e"
                }

                Item {
                    width: 1
                    height: 1
                }
            }
        }

        Rectangle {
            width: Math.min(parent.width, 640)
            height: 60
            radius: 16
            color: "#ffffff"
            border.color: "#ddd9d0"
            border.width: 1

            Row {
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 18
                spacing: 12

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "+"
                    font.pixelSize: 26
                    color: "#6a665d"
                }

                TextInput {
                    id: quickAddInput
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 80
                    font.pixelSize: 17
                    color: "#2a2a2a"
                    clip: true
                    verticalAlignment: TextInput.AlignVCenter
                    selectByMouse: true

                    Text {
                        visible: quickAddInput.text.length === 0
                        text: "Quick add a task..."
                        color: "#8a867d"
                        font.pixelSize: 17
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }

        Rectangle {
            width: Math.min(parent.width, 640)
            height: 180
            radius: 18
            color: "#fbfaf7"
            border.color: "#e4e0d7"
            border.width: 1

            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12

                Text {
                    text: "Preview Area"
                    font.pixelSize: 20
                    font.bold: true
                    color: "#232323"
                }

                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: "This is where tasks for the selected section will appear next. For now, we are building the app shell and interaction structure."
                    font.pixelSize: 16
                    color: "#66625a"
                }
            }
        }
    }
}
