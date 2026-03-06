import QtQuick
import QtQuick.Controls

Rectangle {
    id: root

    property string label: "Item"
    property bool selected: false
    signal clicked

    width: parent ? parent.width : 220
    height: 44
    radius: 10
    color: selected ? "#dcd8cf" : (mouseArea.containsMouse ? "#e3dfd6" : "transparent")

    Behavior on color {
        ColorAnimation {
            duration: 120
        }
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 14
        text: root.label
        font.pixelSize: 22
        font.bold: root.selected
        color: "#222222"
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
