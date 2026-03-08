import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property bool darkMode: false
    property int sidebarWidth: 272
    property int currentTab: 0

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
        spacing: 16

        Behavior on anchors.leftMargin {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        Text {
            text: "Settings"
            font.pixelSize: 34
            font.bold: true
            color: darkMode ? "#f2f2f7" : "#1c1c1e"
        }

        Rectangle {
            width: Math.min(parent.width, 860)
            height: 54
            radius: 16
            color: darkMode ? "#0b0c0f" : "#ffffff"
            border.width: darkMode ? 0 : 1
            border.color: "#00000008"

            Row {
                anchors.centerIn: parent
                spacing: 12

                Repeater {
                    model: ["Theme", "Preferences", "Calendars"]
                    delegate: Rectangle {
                        width: 140
                        height: 36
                        radius: 12
                        color: index === root.currentTab
                               ? (darkMode ? "#1b1f28" : "#ffffff")
                               : "transparent"
                        border.width: index === root.currentTab && !darkMode ? 1 : 0
                        border.color: "#00000008"

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            font.pixelSize: 14
                            font.bold: index === root.currentTab
                            color: darkMode ? "#f2f2f7" : "#1c1c1e"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.currentTab = index
                        }
                    }
                }
            }
        }

        Rectangle {
            width: Math.min(parent.width, 860)
            height: parent.height - 64 - 54 - 32
            radius: 22
            color: darkMode ? "#0b0c0f" : "#ffffff"
            border.width: darkMode ? 0 : 1
            border.color: "#00000008"

            StackLayout {
                anchors.fill: parent
                anchors.margins: 20
                currentIndex: root.currentTab

                ScrollView {
                    clip: true

                    Column {
                        width: parent.width
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
                            radius: 0
                            color: "transparent"
                            border.width: 0

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

                                Column {
                                    width: parent.width
                                    spacing: 10

                                    Text {
                                        text: "App Font"
                                        font.pixelSize: 14
                                        font.bold: true
                                        color: darkMode ? "#c7c7cc" : "#4b5563"
                                    }

                                    ComboBox {
                                        id: fontCombo
                                        width: 240
                                        model: appState.availableFonts
                                        currentIndex: appState.availableFonts.indexOf(appState.fontFamily)
                                        onActivated: appState.setFontFamily(currentText)
                                        delegate: ItemDelegate {
                                            width: ListView.view.width
                                            text: modelData
                                            font.family: modelData === "System"
                                                         ? appState.fontFamilyResolved
                                                         : modelData
                                        }
                                        contentItem: Text {
                                            text: fontCombo.currentText
                                            color: fontCombo.enabled
                                                   ? (darkMode ? "#f2f2f7" : "#1c1c1e")
                                                   : (darkMode ? "#6d6d72" : "#a1a1aa")
                                            font.family: fontCombo.currentText === "System"
                                                         ? appState.fontFamilyResolved
                                                         : fontCombo.currentText
                                            verticalAlignment: Text.AlignVCenter
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                ScrollView {
                    clip: true

                    Column {
                        width: parent.width
                        spacing: 22

                        Text {
                            text: "Preferences"
                            font.pixelSize: 22
                            font.bold: true
                            color: darkMode ? "#f2f2f7" : "#1c1c1e"
                        }

                        Rectangle {
                            width: parent.width
                            height: 320
                            radius: 0
                            color: "transparent"
                            border.width: 0

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

                                Text {
                                    text: appState.lastSyncAt.length > 0
                                          ? "Last sync: " + appState.lastSyncAt
                                          : "Last sync: --"
                                    font.pixelSize: 12
                                    color: darkMode ? "#8e8e93" : "#6e6e73"
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

                ScrollView {
                    clip: true

                    Column {
                        width: parent.width
                        spacing: 22

                        Text {
                            text: "Calendars"
                            font.pixelSize: 22
                            font.bold: true
                            color: darkMode ? "#f2f2f7" : "#1c1c1e"
                        }

                        Rectangle {
                            width: parent.width
                            height: 320
                            radius: 0
                            color: "transparent"
                            border.width: 0

                            Column {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 16

                                Text {
                                    text: "Apple Calendar"
                                    font.pixelSize: 14
                                    font.bold: true
                                    color: darkMode ? "#c7c7cc" : "#4b5563"
                                }

                                Rectangle {
                                    width: 90
                                    height: 28
                                    radius: 8
                                    color: darkMode ? "#1b1d22" : "#f3f4f8"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Refresh"
                                        font.pixelSize: 12
                                        color: darkMode ? "#f2f2f7" : "#1c1c1e"
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: appState.refreshCalendars()
                                    }
                                }

                                Repeater {
                                    model: appState.appleCalendars
                                    delegate: Row {
                                        spacing: 10

                                        Switch {
                                            checked: modelData.selected
                                            onToggled: appState.toggleAppleCalendar(modelData.id, checked)
                                        }

                                        Text {
                                            text: modelData.name
                                            font.pixelSize: 14
                                            color: darkMode ? "#f2f2f7" : "#1c1c1e"
                                        }
                                    }
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 1
                                    color: darkMode ? "#1d2026" : "#e1e6f0"
                                }

                                Text {
                                    text: "Google Calendar"
                                    font.pixelSize: 14
                                    font.bold: true
                                    color: darkMode ? "#c7c7cc" : "#4b5563"
                                }

                                Rectangle {
                                    width: 140
                                    height: 28
                                    radius: 8
                                    color: darkMode ? "#1b1d22" : "#f3f4f8"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Connect Google"
                                        font.pixelSize: 12
                                        color: darkMode ? "#f2f2f7" : "#1c1c1e"
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: appState.connectGoogleCalendar()
                                    }
                                }

                                Repeater {
                                    model: appState.googleCalendars
                                    delegate: Row {
                                        spacing: 10

                                        Switch {
                                            checked: modelData.selected
                                            onToggled: appState.toggleGoogleCalendar(modelData.id, checked)
                                        }

                                        Text {
                                            text: modelData.name
                                            font.pixelSize: 14
                                            color: darkMode ? "#f2f2f7" : "#1c1c1e"
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: appState.refreshCalendars()
}
