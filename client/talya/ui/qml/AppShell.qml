import QtQuick
import QtQuick.Layouts

import "components"

Rectangle {
    id: root
    color: "#f3f2ee"

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Sidebar {
            Layout.preferredWidth: 270
            Layout.fillHeight: true
        }

        ContentView {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
