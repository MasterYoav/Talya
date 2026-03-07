import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property string label: "Item"
    property string iconText: ""
    property bool selected: false
    property bool collapsed: false
    property bool darkMode: false
    signal clicked

    height: root.collapsed ? 36 : 42
    radius: root.collapsed ? 10 : 12
    width: root.collapsed ? 36 : parent.width

    Layout.preferredWidth: root.collapsed ? 36 : -1
    Layout.fillWidth: !root.collapsed
    Layout.alignment: root.collapsed ? Qt.AlignHCenter : Qt.AlignLeft

    color: selected
           ? (darkMode ? "#2affffff" : "#ffd7cd")
           : (mouseArea.containsMouse
              ? (darkMode ? "#1affffff" : "#ffe6de")
              : (darkMode ? "#12000000" : "#ffecea"))

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
            color: root.darkMode ? "#f2f2f7" : "#6b3a34"
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: !root.collapsed
            text: root.label
            font.pixelSize: 18
            font.bold: root.selected
            color: root.darkMode ? "#f2f2f7" : "#6b3a34"
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
