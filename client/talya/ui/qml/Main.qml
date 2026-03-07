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

    color: "transparent"

    AppShell {
        anchors.fill: parent
    }
}
