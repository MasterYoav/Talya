import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property bool darkMode: false

    color: darkMode ? "#111214" : "#f5f5f7"

    Column {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 20

        Rectangle {
            width: parent.width
            height: 64
            radius: 18
            color: darkMode ? "#1c1c1e" : "#ffffffcc"
            border.color: darkMode ? "#ffffff10" : "#00000008"
            border.width: 1

            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 22
                text: appState.currentSection
                font.pixelSize: 34
                font.bold: true
                color: darkMode ? "#f2f2f7" : "#1c1c1e"
            }
        }

        Row {
            width: Math.min(parent.width, 760)
            height: 56
            spacing: 12

            Rectangle {
                width: parent.width - 116
                height: 56
                radius: 16
                color: darkMode ? "#1c1c1e" : "#ffffffcc"
                border.color: darkMode ? "#ffffff10" : "#00000008"
                border.width: 1

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    spacing: 12

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "+"
                        font.pixelSize: 24
                        color: darkMode ? "#a1a1aa" : "#6b7280"
                    }

                    TextField {
                        id: quickAddInput
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 80
                        font.pixelSize: 17
                        color: darkMode ? "#f2f2f7" : "#1c1c1e"
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
                width: 104
                height: 56
                radius: 16
                color: appState.editMode
                       ? (darkMode ? "#2c2c2e" : "#e9e9ed")
                       : (darkMode ? "#1c1c1e" : "#ffffffcc")
                border.color: darkMode ? "#ffffff10" : "#00000008"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: appState.editMode ? "Done" : "Edit"
                    font.pixelSize: 16
                    font.bold: true
                    color: darkMode ? "#f2f2f7" : "#1c1c1e"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: appState.toggleEditMode()
                }
            }
        }

        Rectangle {
            width: Math.min(parent.width, 920)
            height: 500
            radius: 22
            color: darkMode ? "#18181a" : "#ffffffb8"
            border.color: darkMode ? "#ffffff0f" : "#00000008"
            border.width: 1

            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 14

                Text {
                    text: appState.currentSection + " Tasks"
                    font.pixelSize: 20
                    font.bold: true
                    color: darkMode ? "#f2f2f7" : "#1c1c1e"
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
                                id: taskCard
                                required property var modelData

                                width: parent.width
                                height: 76
                                radius: 16
                                color: darkMode ? "#222225" : "#ffffff"
                                border.color: darkMode ? "#ffffff0f" : "#00000008"
                                border.width: 1
                                opacity: modelData.isCompleted ? 0.68 : 1.0

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
                                        color: modelData.isCompleted ? "#7f9f7c" : "transparent"
                                        border.color: modelData.isCompleted ? "#7f9f7c" : (darkMode ? "#8e8e93" : "#b0b0b7")
                                        border.width: 1

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: appState.toggleTaskCompleted(modelData.id)
                                        }
                                    }

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: appState.editMode ? taskCard.width - 180 : taskCard.width - 90
                                        spacing: 4

                                        Loader {
                                            width: parent.width
                                            sourceComponent: appState.editMode ? editComponent : labelComponent
                                        }

                                        Text {
                                            text: "Created " + modelData.createdLabel
                                            font.pixelSize: 13
                                            color: darkMode ? "#8e8e93" : "#6e6e73"
                                        }
                                    }

                                    Item {
                                        width: 1
                                        height: 1
                                    }

                                    Rectangle {
                                        visible: appState.editMode
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 40
                                        height: 40
                                        radius: 12
                                        color: darkMode ? "#4a1f24" : "#fdecec"

                                        Text {
                                            anchors.centerIn: parent
                                            text: "🗑"
                                            font.pixelSize: 16
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: appState.deleteTask(modelData.id)
                                        }
                                    }
                                }

                                Component {
                                    id: labelComponent

                                    Text {
                                        text: modelData.title
                                        font.pixelSize: 16
                                        color: darkMode ? "#f2f2f7" : "#1c1c1e"
                                        font.strikeout: modelData.isCompleted
                                        wrapMode: Text.WordWrap
                                    }
                                }

                                Component {
                                    id: editComponent

                                    TextField {
                                        width: parent ? parent.width : 300
                                        text: modelData.title
                                        font.pixelSize: 16
                                        color: darkMode ? "#f2f2f7" : "#1c1c1e"
                                        selectByMouse: true
                                        background: Rectangle {
                                            radius: 10
                                            color: darkMode ? "#2a2a2d" : "#f2f2f7"
                                            border.color: darkMode ? "#ffffff10" : "#00000008"
                                            border.width: 1
                                        }

                                        onEditingFinished: {
                                            appState.updateTaskTitle(modelData.id, text)
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            visible: appState.tasks.length === 0
                            text: "No tasks in " + appState.currentSection + " yet. Add your first one above."
                            font.pixelSize: 15
                            color: darkMode ? "#8e8e93" : "#6e6e73"
                        }
                    }
                }
            }
        }
    }
}
