import QtQuick
import QtQuick.Layouts

import "components"

Rectangle {
    id: root

    property string currentSection: "Today"

    color: "#f3f2ee"

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Sidebar {
            Layout.preferredWidth: 270
            Layout.fillHeight: true
            currentSection: root.currentSection

            onSectionSelected: function(section) {
                root.currentSection = section
            }
        }

        ContentView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentSection: root.currentSection
        }
    }
}
