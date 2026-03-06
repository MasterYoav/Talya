import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
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
                    text: appState.currentSection
                    font.pixelSize: 34
                    font.bold: true
                    color: "#1e1e1e"
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

                    onAccepted: {
                        appState.addTask(text)
                        text = ""
                    }

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
            width: Math.min(parent.width, 760)
            height: 360
            radius: 18
            color: "#fbfaf7"
            border.color: "#e4e0d7"
            border.width: 1

            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 14

                Text {
                    text: "Tasks"
                    font.pixelSize: 20
                    font.bold: true
                    color: "#232323"
                }

                ScrollView {
                    width: parent.width
                    height: parent.height - 50
                    clip: true

                    Column {
                        width: parent.width
                        spacing: 10

                        Repeater {
                            model: appState.tasks

                            delegate: Rectangle {
                                width: parent.width
                                height: 54
                                radius: 14
                                color: "#ffffff"
                                border.color: "#e5e0d8"
                                border.width: 1

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 16
                                    spacing: 14

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 18
                                        height: 18
                                        radius: 9
                                        color: "transparent"
                                        border.color: "#b8b2a7"
                                        border.width: 1
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.title
                                        font.pixelSize: 16
                                        color: "#2a2a2a"
                                    }
                                }
                            }
                        }

                        Text {
                            visible: appState.tasks.length === 0
                            text: "No tasks yet. Add your first one above."
                            font.pixelSize: 15
                            color: "#7a756c"
                        }
                    }
                }
            }
        }
    }
}
