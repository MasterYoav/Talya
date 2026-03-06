import QtQuick

Rectangle {
    id: root

    property string label: "Item"
    property string iconText: ""
    property bool selected: false
    property bool collapsed: false
    property bool darkMode: false
    signal clicked

    height: 42
    radius: 12
    color: selected
           ? (darkMode ? "#ffffff14" : "#00000008")
           : (mouseArea.containsMouse
              ? (darkMode ? "#ffffff0d" : "#00000005")
              : "transparent")

    Behavior on color {
        ColorAnimation { duration: 120 }
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 10

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.iconText
            font.pixelSize: 16
            color: root.darkMode ? "#f2f2f7" : "#1c1c1e"
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: !root.collapsed
            text: root.label
            font.pixelSize: 18
            font.bold: root.selected
            color: root.darkMode ? "#f2f2f7" : "#1c1c1e"
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
