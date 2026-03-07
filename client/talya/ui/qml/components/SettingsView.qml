import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property bool darkMode: false
    property int sidebarWidth: 272

    color: "transparent"

    Rectangle {
        x: sidebarWidth
        width: parent.width - sidebarWidth
        height: parent.height
        color: darkMode ? "#050505" : "#f6f7fb"
    }

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
                    height: 280
                    radius: 18
                    color: darkMode ? "#14161a" : "#f4f6fb"
                    border.width: darkMode ? 0 : 1
                    border.color: "#00000006"

                    Column {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 16

                        Row {
                            width: parent.width
                            height: 64
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

                        Column {
                            width: parent.width
                            spacing: 10

                            Text {
                                text: "Sidebar Blur"
                                font.pixelSize: 14
                                font.bold: true
                                color: darkMode ? "#c7c7cc" : "#4b5563"
                            }

                            Switch {
                                checked: appState.sidebarBlurEnabled
                                text: "Enable blur"
                                onToggled: appState.setSidebarBlurEnabled(checked)
                            }

                            Slider {
                                id: blurSlider
                                from: 0.0
                                to: 1.0
                                value: appState.sidebarBlurOpacity
                                enabled: appState.sidebarBlurEnabled
                                opacity: appState.sidebarBlurEnabled ? 1.0 : 0.4
                                onMoved: appState.setSidebarBlurOpacity(value)
                            }

                        }

                        Column {
                            width: parent.width
                            spacing: 10

                            Text {
                                text: "App Icon"
                                font.pixelSize: 14
                                font.bold: true
                                color: darkMode ? "#c7c7cc" : "#4b5563"
                            }

                            Row {
                                spacing: 14

                                Rectangle {
                                    width: 96
                                    height: 96
                                    radius: 20
                                    color: appState.appIconChoice === "dark"
                                           ? (darkMode ? "#1b1f28" : "#ffffff")
                                           : (darkMode ? "#101114" : "#f0f2f7")
                                    border.width: appState.appIconChoice === "dark" ? 2 : 0
                                    border.color: darkMode ? "#5a5f6b" : "#d5d9e5"

                                    Image {
                                        anchors.centerIn: parent
                                        source: Qt.resolvedUrl(
                                            "../../../../../media/dark.xcassets/AppIcon.appiconset/256-mac.png"
                                        )
                                        width: 64
                                        height: 64
                                        fillMode: Image.PreserveAspectFit
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: appState.setAppIconChoice("dark")
                                    }
                                }

                                Rectangle {
                                    width: 96
                                    height: 96
                                    radius: 20
                                    color: appState.appIconChoice === "light"
                                           ? (darkMode ? "#1b1f28" : "#ffffff")
                                           : (darkMode ? "#101114" : "#f0f2f7")
                                    border.width: appState.appIconChoice === "light" ? 2 : 0
                                    border.color: darkMode ? "#5a5f6b" : "#d5d9e5"

                                    Image {
                                        anchors.centerIn: parent
                                        source: Qt.resolvedUrl(
                                            "../../../../../media/light.xcassets/AppIcon.appiconset/256-mac.png"
                                        )
                                        width: 64
                                        height: 64
                                        fillMode: Image.PreserveAspectFit
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: appState.setAppIconChoice("light")
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    text: "Preferences"
                    font.pixelSize: 22
                    font.bold: true
                    color: darkMode ? "#f2f2f7" : "#1c1c1e"
                }

                Rectangle {
                    width: parent.width
                    height: 320
                    radius: 18
                    color: darkMode ? "#14161a" : "#f4f6fb"
                    border.width: darkMode ? 0 : 1
                    border.color: "#00000006"

                    Column {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 16

                        Text {
                            text: "Reminders"
                            font.pixelSize: 14
                            font.bold: true
                            color: darkMode ? "#c7c7cc" : "#4b5563"
                        }

                        Row {
                            spacing: 12

                            Switch {
                                checked: appState.reminderNotifyApp
                                text: "In-app banner"
                                onToggled: appState.setReminderNotifyApp(checked)
                            }

                            Switch {
                                checked: appState.reminderNotifySystem
                                text: "macOS notification"
                                onToggled: appState.setReminderNotifySystem(checked)
                            }
                        }

                        Switch {
                            checked: appState.reminderNotifyBackground
                            text: "Background notifications"
                            onToggled: appState.setReminderNotifyBackground(checked)
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: darkMode ? "#1d2026" : "#e1e6f0"
                        }

                        Row {
                            width: parent.width
                            spacing: 12

                            Text {
                                text: "Sync conflicts"
                                font.pixelSize: 14
                                font.bold: true
                                color: darkMode ? "#c7c7cc" : "#4b5563"
                            }

                            Item { width: parent.width - 140 }

                            Rectangle {
                                width: 80
                                height: 28
                                radius: 8
                                color: darkMode ? "#1b1d22" : "#f3f4f8"

                                Text {
                                    anchors.centerIn: parent
                                    text: "Clear"
                                    font.pixelSize: 12
                                    color: darkMode ? "#f2f2f7" : "#1c1c1e"
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: appState.clearSyncLogs()
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 92
                            radius: 12
                            color: darkMode ? "#101216" : "#ffffff"
                            border.width: darkMode ? 0 : 1
                            border.color: "#00000008"

                            Column {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 6

                                Repeater {
                                    model: appState.syncLogs
                                    delegate: Text {
                                        text: modelData.timestamp + " • " + modelData.message
                                        font.pixelSize: 12
                                        color: darkMode ? "#c7c7cc" : "#4b5563"
                                        elide: Text.ElideRight
                                    }
                                }

                                Text {
                                    visible: appState.syncLogs.length === 0
                                    text: "No conflicts logged."
                                    font.pixelSize: 12
                                    color: darkMode ? "#6e6e73" : "#9aa1ad"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
