import QtQuick
import QtQuick.Controls

ApplicationWindow {
    id: window
    width: 1280
    height: 800
    minimumWidth: 1000
    minimumHeight: 650
    visible: true
    title: "Talya"
    font.family: appState ? appState.fontFamilyResolved : ""

    color: "transparent"

    Component {
        id: appShellComponent

        AppShell {
            anchors.fill: parent
        }
    }

    Loader {
        id: appShellLoader
        anchors.fill: parent
        sourceComponent: appShellComponent
    }

    Connections {
        target: appState
        function onFontFamilyChanged() {
            appShellLoader.active = false
            appShellLoader.active = true
        }
    }
}
