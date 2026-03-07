import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property string label: "Item"
    property string iconText: ""
    property string accentColor: ""
    property bool selected: false
    property bool collapsed: false
    property bool darkMode: false
    signal clicked
    readonly property bool iconIsEmoji: iconText.length > 1 || iconText.charCodeAt(0) > 255

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

    Text {
        anchors.centerIn: parent
        visible: root.collapsed
        text: root.iconText
        font.pixelSize: 16
        font.family: root.iconIsEmoji ? "Apple Color Emoji" : ""
        renderType: Text.NativeRendering
        color: root.iconIsEmoji
               ? "#ffffff"
               : (root.accentColor !== ""
                  ? root.accentColor
                  : (root.darkMode ? "#f2f2f7" : "#6b3a34"))
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 10
        visible: !root.collapsed

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.iconText
            font.pixelSize: 16
            font.family: root.iconIsEmoji ? "Apple Color Emoji" : ""
            renderType: Text.NativeRendering
            color: root.iconIsEmoji
                   ? "#ffffff"
                   : (root.accentColor !== ""
                      ? root.accentColor
                      : (root.darkMode ? "#f2f2f7" : "#6b3a34"))
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
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
