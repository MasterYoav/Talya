import QtQuick

Rectangle {
    id: root

    property bool darkMode: false

    anchors.fill: parent
    visible: appState.settingsOpen
    color: darkMode ? "#00000066" : "#00000022"

    Rectangle {
        id: panel
        anchors.centerIn: parent
        width: 520
        height: 360
        radius: 24
        color: darkMode ? "#1c1c1e" : "#ffffffee"
        border.color: darkMode ? "#ffffff12" : "#0000000a"
        border.width: 1

        Column {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 18

            Row {
                width: parent.width
                height: 40

                Text {
                    text: "Settings"
                    font.pixelSize: 28
                    font.bold: true
                    color: darkMode ? "#f2f2f7" : "#1c1c1e"
                }

                Item {
                    width: parent.width - 120
                    height: 1
                }

                Rectangle {
                    width: 38
                    height: 38
                    radius: 12
                    color: darkMode ? "#2c2c2e" : "#f2f2f7"

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.pixelSize: 15
                        color: darkMode ? "#f2f2f7" : "#1c1c1e"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: appState.closeSettings()
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: darkMode ? "#ffffff12" : "#0000000a"
            }

            Text {
                text: "Theme"
                font.pixelSize: 20
                font.bold: true
                color: darkMode ? "#f2f2f7" : "#1c1c1e"
            }

            Rectangle {
                width: parent.width
                height: 72
                radius: 18
                color: darkMode ? "#2c2c2e" : "#f7f7f7"
                border.color: darkMode ? "#ffffff0f" : "#00000008"
                border.width: 1

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    spacing: 12

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Dark Mode"
                        font.pixelSize: 17
                        color: darkMode ? "#f2f2f7" : "#1c1c1e"
                    }

                    Item {
                        width: parent.width - 220
                        height: 1
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 58
                        height: 32
                        radius: 16
                        color: appState.darkMode ? "#34c759" : "#d1d1d6"

                        Rectangle {
                            width: 26
                            height: 26
                            radius: 13
                            y: 3
                            x: appState.darkMode ? 29 : 3
                            color: "#ffffff"

                            Behavior on x {
                                NumberAnimation { duration: 140 }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: appState.toggleDarkMode()
                        }
                    }
                }
            }

            Text {
                text: "Connections"
                font.pixelSize: 20
                font.bold: true
                color: darkMode ? "#f2f2f7" : "#1c1c1e"
            }

            Rectangle {
                width: parent.width
                height: 72
                radius: 18
                color: darkMode ? "#2c2c2e" : "#f7f7f7"
                border.color: darkMode ? "#ffffff0f" : "#00000008"
                border.width: 1

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 18
                    text: "Google Calendar, GitHub, Apple Calendar — future feature"
                    font.pixelSize: 15
                    color: darkMode ? "#8e8e93" : "#6e6e73"
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: {
            if (!panel.contains(mapToItem(panel, mouseX, mouseY))) {
                appState.closeSettings()
            }
        }
    }
}
