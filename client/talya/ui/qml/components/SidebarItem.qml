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
           ? (darkMode ? "#18ffffff" : "#ccffffff")
           : (mouseArea.containsMouse
              ? (darkMode ? "#0dffffff" : "#88ffffff")
              : "transparent")

    border.width: 0
    border.color: "transparent"

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
