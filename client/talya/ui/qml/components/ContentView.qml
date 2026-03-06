import QtQuick
import QtQuick.Controls

Rectangle {
    id: root

    property bool darkMode: false
    property int sidebarWidth: 272

    color: darkMode ? "#050505" : "#f6f7fb"

    Column {
        anchors.fill: parent
        anchors.leftMargin: sidebarWidth + 28
        anchors.rightMargin: 28
        anchors.topMargin: 28
        anchors.bottomMargin: 28
        spacing: 20

        Rectangle {
            width: Math.min(parent.width, 920)
            height: 64
            radius: 18
            color: darkMode ? "#101114" : "#ffffff"
            border.width: darkMode ? 0 : 1
            border.color: "#00000008"

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
                color: darkMode ? "#101114" : "#ffffff"
                border.width: darkMode ? 0 : 1
                border.color: "#00000008"

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    spacing: 12

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "+"
                        font.pixelSize: 24
                        color: darkMode ? "#8e8e93" : "#6b7280"
                    }

                    TextField {
                        id: quickAddInput
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 80
                        font.pixelSize: 17
                        color: darkMode ? "#f2f2f7" : "#1c1c1e"
                        placeholderText: "Quick add a task..."
                        placeholderTextColor: darkMode ? "#6e6e73" : "#9aa1ad"
                        selectionColor: darkMode ? "#2b2f38" : "#dbe7ff"
                        selectedTextColor: darkMode ? "#ffffff" : "#1c1c1e"
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
                       ? (darkMode ? "#1a1e27" : "#eaf0ff")
                       : (darkMode ? "#101114" : "#ffffff")
                border.width: darkMode ? 0 : 1
                border.color: "#00000008"

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
            height: parent.height - 140
            radius: 22
            color: darkMode ? "#0b0c0f" : "#ffffff"
            border.width: darkMode ? 0 : 1
            border.color: "#00000008"

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

                    ScrollBar.vertical.policy: ScrollBar.AsNeeded
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

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
                                color: appState.selectedTask.id === modelData.id
                                       ? (darkMode ? "#1c1e24" : "#eef4ff")
                                       : (darkMode ? "#15161a" : "#fbfcff")
                                border.width: 0
                                opacity: modelData.isCompleted ? 0.68 : 1.0

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        appState.selectTask(modelData.id)
                                        taskDetailsPopup.open()
                                    }
                                }

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
                                        color: modelData.isCompleted ? "#82a97f" : "transparent"
                                        border.color: modelData.isCompleted ? "#82a97f" : (darkMode ? "#8e8e93" : "#b7bfcc")
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

                                        Text {
                                            text: modelData.title
                                            font.pixelSize: 16
                                            color: darkMode ? "#f2f2f7" : "#1c1c1e"
                                            font.strikeout: modelData.isCompleted
                                            wrapMode: Text.WordWrap
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
                                        color: darkMode ? "#3a171b" : "#ffe9ec"
                                        border.width: 0

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

        Popup {
        id: taskDetailsPopup
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        width: 520
        height: 520
        anchors.centerIn: parent
        padding: 0

        background: Rectangle {
            radius: 22
            color: darkMode ? "#0b0c0f" : "#ffffff"
            border.width: darkMode ? 0 : 1
            border.color: "#00000008"
        }

        onClosed: {
            appState.clearSelectedTask()
        }

        property string draftTitle: ""
        property string draftNotes: ""

        function loadFromSelectedTask() {
            if (appState.hasSelectedTask) {
                draftTitle = appState.selectedTask.title || ""
                draftNotes = appState.selectedTask.notes || ""
            } else {
                draftTitle = ""
                draftNotes = ""
            }
        }

        Connections {
            target: appState
            function onSelectedTaskChanged() {
                if (taskDetailsPopup.visible) {
                    taskDetailsPopup.loadFromSelectedTask()
                }
            }
        }

        onOpened: {
            loadFromSelectedTask()
        }

        Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 16

            Row {
                width: parent.width
                height: 40
                spacing: 12

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Task Details"
                    font.pixelSize: 24
                    font.bold: true
                    color: darkMode ? "#f2f2f7" : "#1c1c1e"
                }

                Item {
                    width: parent.width - 120
                    height: 1
                }

                Rectangle {
                    width: 36
                    height: 36
                    radius: 10
                    color: darkMode ? "#1b1d22" : "#f3f4f8"

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.pixelSize: 14
                        color: darkMode ? "#f2f2f7" : "#1c1c1e"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: taskDetailsPopup.close()
                    }
                }
            }

            Text {
                text: "Title"
                font.pixelSize: 14
                font.bold: true
                color: darkMode ? "#c7c7cc" : "#4b5563"
            }

            TextField {
                id: detailTitleField
                width: parent.width
                text: taskDetailsPopup.draftTitle
                font.pixelSize: 17
                color: darkMode ? "#f2f2f7" : "#1c1c1e"
                onTextChanged: taskDetailsPopup.draftTitle = text

                background: Rectangle {
                    radius: 14
                    color: darkMode ? "#15161a" : "#f4f7ff"
                    border.width: darkMode ? 0 : 1
                    border.color: "#00000008"
                }
            }

            Text {
                text: "Notes"
                font.pixelSize: 14
                font.bold: true
                color: darkMode ? "#c7c7cc" : "#4b5563"
            }

            TextArea {
                id: detailNotesField
                width: parent.width
                height: 220
                text: taskDetailsPopup.draftNotes
                wrapMode: TextEdit.Wrap
                color: darkMode ? "#f2f2f7" : "#1c1c1e"
                placeholderText: "Add notes for this task..."
                placeholderTextColor: darkMode ? "#6e6e73" : "#9aa1ad"
                selectByMouse: true
                onTextChanged: taskDetailsPopup.draftNotes = text

                background: Rectangle {
                    radius: 14
                    color: darkMode ? "#15161a" : "#f4f7ff"
                    border.width: darkMode ? 0 : 1
                    border.color: "#00000008"
                }
            }

            Rectangle {
                width: parent.width
                height: 82
                radius: 14
                color: darkMode ? "#15161a" : "#f6f7fb"

                Column {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 6

                    Text {
                        text: appState.hasSelectedTask
                              ? "Created " + appState.selectedTask.createdLabel
                              : ""
                        font.pixelSize: 14
                        color: darkMode ? "#8e8e93" : "#6e6e73"
                    }

                    Text {
                        text: appState.hasSelectedTask && appState.selectedTask.updatedAt
                              ? "Updated recently"
                              : "No recent updates"
                        font.pixelSize: 14
                        color: darkMode ? "#8e8e93" : "#6e6e73"
                    }
                }
            }

            Item {
                width: 1
                height: 1
            }

            Row {
                width: parent.width
                height: 48

                Item {
                    width: parent.width - 112
                    height: 1
                }

                Rectangle {
                    width: 112
                    height: 48
                    radius: 14
                    color: darkMode ? "#1a1e27" : "#eaf0ff"

                    Text {
                        anchors.centerIn: parent
                        text: "Save"
                        font.pixelSize: 16
                        font.bold: true
                        color: darkMode ? "#f2f2f7" : "#1c1c1e"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (appState.hasSelectedTask) {
                                const taskId = appState.selectedTask.id
                                const newTitle = taskDetailsPopup.draftTitle
                                const newNotes = taskDetailsPopup.draftNotes

                                appState.updateTaskNotes(taskId, newNotes)
                                appState.updateTaskTitle(taskId, newTitle)
                            }
                            taskDetailsPopup.close()
                        }
                    }
                }
            }
        }
    }
}
