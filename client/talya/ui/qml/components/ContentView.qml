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

                TextField {
                    id: quickAddInput
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 80
                    font.pixelSize: 17
                    color: "#2a2a2a"
                    placeholderText: "Quick add a task..."
                    background: Rectangle {
                        color: "transparent"
                        border.width: 0
                    }

                    onAccepted: {
                        appState.addTask(text)
                        text = ""
                    }
                }
            }
        }

        Rectangle {
            width: Math.min(parent.width, 760)
            height: 420
            radius: 18
            color: "#fbfaf7"
            border.color: "#e4e0d7"
            border.width: 1

            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 14

                Text {
                    text: appState.currentSection + " Tasks"
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
                                required property var modelData

                                width: parent.width
                                height: 54
                                radius: 14
                                color: "#ffffff"
                                border.color: "#e5e0d8"
                                border.width: 1
                                opacity: modelData.isCompleted ? 0.72 : 1.0

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 16
                                    spacing: 14

                                    Rectangle {
                                        id: statusCircle
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 18
                                        height: 18
                                        radius: 9
                                        color: modelData.isCompleted ? "#7d9b76" : "transparent"
                                        border.color: modelData.isCompleted ? "#7d9b76" : "#b8b2a7"
                                        border.width: 1

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: appState.toggleTaskCompleted(modelData.id)
                                        }
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.title
                                        font.pixelSize: 16
                                        color: "#2a2a2a"
                                        font.strikeout: modelData.isCompleted
                                    }
                                }
                            }
                        }

                        Text {
                            visible: appState.tasks.length === 0
                            text: "No tasks in " + appState.currentSection + " yet. Add your first one above."
                            font.pixelSize: 15
                            color: "#7a756c"
                        }
                    }
                }
            }
        }
    }
}
