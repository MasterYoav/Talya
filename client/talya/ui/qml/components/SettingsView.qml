import QtQuick
import QtQuick.Layouts

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
        spacing: 22

        Rectangle {
            width: parent.width
            height: 64
            radius: 18
            color: darkMode ? "#101114" : "#ffffff"
            border.width: darkMode ? 0 : 1
            border.color: "#00000008"

            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 22
                text: "Settings"
                font.pixelSize: 34
                font.bold: true
                color: darkMode ? "#f2f2f7" : "#1c1c1e"
            }
        }

        Rectangle {
            width: Math.min(parent.width, 860)
            height: 360
            radius: 22
            color: darkMode ? "#0b0c0f" : "#ffffff"
            border.width: darkMode ? 0 : 1
            border.color: "#00000008"

            Column {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 22

                Text {
                    text: "Theme"
                    font.pixelSize: 22
                    font.bold: true
                    color: darkMode ? "#f2f2f7" : "#1c1c1e"
                }

                Rectangle {
                    width: parent.width
                    height: 82
                    radius: 18
                    color: darkMode ? "#14161a" : "#f4f6fb"
                    border.width: darkMode ? 0 : 1
                    border.color: "#00000006"

                    Row {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 12

                        Rectangle {
                            width: 140
                            height: parent.height
                            radius: 14
                            color: !appState.darkMode
                                   ? (darkMode ? "#1b1f28" : "#ffffff")
                                   : "transparent"
                            border.width: (!appState.darkMode && !darkMode) ? 1 : 0
                            border.color: "#00000008"

                            Row {
                                anchors.centerIn: parent
                                spacing: 8

                                Text {
                                    text: "☀"
                                    font.pixelSize: 18
                                    color: darkMode ? "#f2f2f7" : "#1c1c1e"
                                }

                                Text {
                                    text: "Light"
                                    font.pixelSize: 16
                                    font.bold: !appState.darkMode
                                    color: darkMode ? "#f2f2f7" : "#1c1c1e"
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: appState.setLightMode()
                            }
                        }

                        Rectangle {
                            width: 140
                            height: parent.height
                            radius: 14
                            color: appState.darkMode ? "#1b1f28" : "transparent"
                            border.width: 0

                            Row {
                                anchors.centerIn: parent
                                spacing: 8

                                Text {
                                    text: "☾"
                                    font.pixelSize: 18
                                    color: darkMode ? "#f2f2f7" : "#1c1c1e"
                                }

                                Text {
                                    text: "Dark"
                                    font.pixelSize: 16
                                    font.bold: appState.darkMode
                                    color: darkMode ? "#f2f2f7" : "#1c1c1e"
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: appState.setDarkMode()
                            }
                        }
                    }
                }

                Text {
                    text: "Connections"
                    font.pixelSize: 22
                    font.bold: true
                    color: darkMode ? "#f2f2f7" : "#1c1c1e"
                }

                Rectangle {
                    width: parent.width
                    height: 82
                    radius: 18
                    color: darkMode ? "#14161a" : "#f4f6fb"
                    border.width: darkMode ? 0 : 1
                    border.color: "#00000006"

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 18
                        text: "Google Calendar, GitHub, Apple Calendar — future feature"
                        font.pixelSize: 15
                        color: darkMode ? "#8e8e93" : "#6b7280"
                    }
                }
            }
        }
    }
}
