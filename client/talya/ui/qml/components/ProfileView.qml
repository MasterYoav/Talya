import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property bool darkMode: false
    property int sidebarWidth: 272
    property bool registerMode: false

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
                text: "Profile"
                font.pixelSize: 34
                font.bold: true
                color: darkMode ? "#f2f2f7" : "#1c1c1e"
            }
        }

        Rectangle {
            width: Math.min(parent.width, 860)
            height: appState.isAuthenticated ? 360 : 420
            radius: 22
            color: darkMode ? "#0b0c0f" : "#ffffff"
            border.width: darkMode ? 0 : 1
            border.color: "#00000008"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 22
                spacing: 16

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: appState.isAuthenticated ? "Account" : "Sign in"
                        font.pixelSize: 20
                        font.bold: true
                        color: darkMode ? "#f2f2f7" : "#1c1c1e"
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        visible: !appState.isAuthenticated
                        Layout.preferredWidth: 150
                        Layout.preferredHeight: 32
                        radius: 10
                        color: darkMode ? "#1b1d22" : "#f3f4f8"

                        Text {
                            anchors.centerIn: parent
                            text: root.registerMode ? "Switch to sign in" : "Switch to create"
                            font.pixelSize: 13
                            color: darkMode ? "#f2f2f7" : "#1c1c1e"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.registerMode = !root.registerMode
                        }
                    }
                }

                Text {
                    visible: appState.authError.length > 0
                    text: appState.authError
                    font.pixelSize: 13
                    color: darkMode ? "#ffb4a4" : "#c2415c"
                    wrapMode: Text.WordWrap
                }

                Text {
                    visible: appState.authStatus.length > 0
                    text: appState.authStatus
                    font.pixelSize: 13
                    color: darkMode ? "#8e8e93" : "#6e6e73"
                    wrapMode: Text.WordWrap
                }

                Item { Layout.preferredHeight: 6 }

                ColumnLayout {
                    id: authColumn
                    spacing: 12
                    visible: !appState.isAuthenticated
                    Layout.fillWidth: true

                    Text {
                        text: "Email sign-in"
                        font.pixelSize: 14
                        font.bold: true
                        color: darkMode ? "#c7c7cc" : "#4b5563"
                    }

                    Text {
                        visible: root.registerMode
                        text: "Name"
                        font.pixelSize: 14
                        font.bold: true
                        color: darkMode ? "#c7c7cc" : "#4b5563"
                    }

                    TextField {
                        id: nameField
                        visible: root.registerMode
                        Layout.fillWidth: true
                        font.pixelSize: 16
                        color: darkMode ? "#f2f2f7" : "#1c1c1e"
                        placeholderText: "Your name"
                        placeholderTextColor: darkMode ? "#6e6e73" : "#9aa1ad"

                        background: Rectangle {
                            radius: 12
                            color: darkMode ? "#15161a" : "#f4f7ff"
                            border.width: darkMode ? 0 : 1
                            border.color: "#00000008"
                        }
                    }

                    Text {
                        text: "Email"
                        font.pixelSize: 14
                        font.bold: true
                        color: darkMode ? "#c7c7cc" : "#4b5563"
                    }

                    TextField {
                        id: emailField
                        Layout.fillWidth: true
                        font.pixelSize: 16
                        color: darkMode ? "#f2f2f7" : "#1c1c1e"
                        placeholderText: "you@example.com"
                        placeholderTextColor: darkMode ? "#6e6e73" : "#9aa1ad"

                        background: Rectangle {
                            radius: 12
                            color: darkMode ? "#15161a" : "#f4f7ff"
                            border.width: darkMode ? 0 : 1
                            border.color: "#00000008"
                        }
                    }

                    Text {
                        text: "Password"
                        font.pixelSize: 14
                        font.bold: true
                        color: darkMode ? "#c7c7cc" : "#4b5563"
                    }

                    TextField {
                        id: passwordField
                        Layout.fillWidth: true
                        font.pixelSize: 16
                        color: darkMode ? "#f2f2f7" : "#1c1c1e"
                        echoMode: TextInput.Password
                        placeholderText: root.registerMode ? "At least 6 characters" : "Your password"
                        placeholderTextColor: darkMode ? "#6e6e73" : "#9aa1ad"

                        background: Rectangle {
                            radius: 12
                            color: darkMode ? "#15161a" : "#f4f7ff"
                            border.width: darkMode ? 0 : 1
                            border.color: "#00000008"
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        spacing: 12

                        Rectangle {
                            Layout.preferredWidth: 160
                            Layout.preferredHeight: 44
                            radius: 14
                            color: darkMode ? "#1a1e27" : "#eaf0ff"

                            Text {
                                anchors.centerIn: parent
                                text: root.registerMode ? "Create account" : "Email sign in"
                                font.pixelSize: 15
                                font.bold: true
                                color: darkMode ? "#f2f2f7" : "#1c1c1e"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                if (root.registerMode) {
                                    appState.register(nameField.text, emailField.text, passwordField.text)
                                } else {
                                    appState.login(emailField.text, passwordField.text)
                                }
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }
                    }

                    Text {
                        text: "OAuth sign-in"
                        font.pixelSize: 12
                        color: darkMode ? "#8e8e93" : "#6e6e73"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        spacing: 12

                        Rectangle {
                            Layout.preferredWidth: 170
                            Layout.preferredHeight: 44
                            radius: 14
                            color: darkMode ? "#1b1d22" : "#f3f4f8"

                            Text {
                                anchors.centerIn: parent
                                text: "Sign in with Google"
                                font.pixelSize: 13
                                color: darkMode ? "#f2f2f7" : "#1c1c1e"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: appState.loginWithGoogle()
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 170
                            Layout.preferredHeight: 44
                            radius: 14
                            color: darkMode ? "#1b1d22" : "#f3f4f8"

                            Text {
                                anchors.centerIn: parent
                                text: "Sign in with GitHub"
                                font.pixelSize: 13
                                color: darkMode ? "#f2f2f7" : "#1c1c1e"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: appState.loginWithGithub()
                            }
                        }
                    }

                    Text {
                        text: "OAuth will open a browser window to continue."
                        font.pixelSize: 12
                        color: darkMode ? "#8e8e93" : "#6e6e73"
                    }
                }

                ColumnLayout {
                    id: profileColumn
                    spacing: 12
                    visible: appState.isAuthenticated
                    Layout.fillWidth: true

                    Text {
                        text: "Name"
                        font.pixelSize: 14
                        font.bold: true
                        color: darkMode ? "#c7c7cc" : "#4b5563"
                    }

                    TextField {
                        id: profileNameField
                        Layout.fillWidth: true
                        text: appState.userName
                        font.pixelSize: 16
                        color: darkMode ? "#f2f2f7" : "#1c1c1e"

                        background: Rectangle {
                            radius: 12
                            color: darkMode ? "#15161a" : "#f4f7ff"
                            border.width: darkMode ? 0 : 1
                            border.color: "#00000008"
                        }
                    }

                    Text {
                        text: "Email"
                        font.pixelSize: 14
                        font.bold: true
                        color: darkMode ? "#c7c7cc" : "#4b5563"
                    }

                    TextField {
                        id: profileEmailField
                        Layout.fillWidth: true
                        text: appState.userEmail
                        font.pixelSize: 16
                        color: darkMode ? "#f2f2f7" : "#1c1c1e"

                        background: Rectangle {
                            radius: 12
                            color: darkMode ? "#15161a" : "#f4f7ff"
                            border.width: darkMode ? 0 : 1
                            border.color: "#00000008"
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44

                        Rectangle {
                            Layout.preferredWidth: 120
                            Layout.preferredHeight: 44
                            radius: 14
                            color: darkMode ? "#1a1e27" : "#eaf0ff"

                            Text {
                                anchors.centerIn: parent
                                text: "Save"
                                font.pixelSize: 15
                                font.bold: true
                                color: darkMode ? "#f2f2f7" : "#1c1c1e"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: appState.updateProfile(profileNameField.text, profileEmailField.text)
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            Layout.preferredWidth: 120
                            Layout.preferredHeight: 44
                            radius: 14
                            color: darkMode ? "#3a171b" : "#ffe9ec"

                            Text {
                                anchors.centerIn: parent
                                text: "Sign out"
                                font.pixelSize: 15
                                font.bold: true
                                color: darkMode ? "#f2f2f7" : "#1c1c1e"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: appState.logout()
                            }
                        }
                    }
                }
            }

        }
    }
}
