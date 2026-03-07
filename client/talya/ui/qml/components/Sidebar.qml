import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

Rectangle {
    id: root

    property bool darkMode: false
    property bool collapsed: false

    ListModel { id: pinnedListModel }
    ListModel { id: unpinnedListModel }

    function rebuildSidebarLists() {
        pinnedListModel.clear()
        unpinnedListModel.clear()
        for (let i = 0; i < appState.sidebarLists.length; i++) {
            const item = appState.sidebarLists[i]
            if (item.listType === "settings" || item.listType === "profile") {
                continue
            }
            const targetModel = item.isPinned ? pinnedListModel : unpinnedListModel
            targetModel.append({
                listId: item.id,
                name: item.name,
                icon: item.icon,
                color: item.color,
                listType: item.listType,
                isSystem: item.isSystem,
                isPinned: item.isPinned
            })
        }
    }

    color: "transparent"
    border.width: 0
    radius: 0

    readonly property int bannerHeight: root.collapsed ? 0 : 110

    Image {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.bannerHeight
        source: darkMode
                ? Qt.resolvedUrl("../../../../../media/dark_2k_banner.png")
                : Qt.resolvedUrl("../../../../../media/2k_banner.png")
        fillMode: Image.PreserveAspectCrop
        visible: !root.collapsed
        z: 3
    }

    Rectangle {
        anchors.fill: parent
        color: darkMode ? "transparent" : "#22ffffff"
        z: 1
    }

    Rectangle {
        id: collapseButton
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.top: parent.top
        anchors.topMargin: 12
        width: 36
        height: 36
        radius: 10
        color: darkMode ? "#33ffffff" : "#ffe4dd"
        border.width: darkMode ? 1 : 0
        border.color: darkMode ? "#55ffffff" : "transparent"
        z: 4

        Text {
            anchors.centerIn: parent
            text: "≡"
            font.pixelSize: 18
            color: darkMode ? "#f2f2f7" : "#6b3a34"
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: appState.toggleSidebarCollapsed()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: root.collapsed ? 60 : (root.bannerHeight + 12)
        anchors.bottomMargin: 12
        spacing: root.collapsed ? 10 : 12
        z: 3

        Item { Layout.preferredHeight: 8 }

        Connections {
            target: appState
            function onSidebarListsChanged() {
                root.rebuildSidebarLists()
            }
        }

        Component.onCompleted: root.rebuildSidebarLists()

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                visible: pinnedListModel.count > 0 && !root.collapsed
                text: "Pinned"
                font.pixelSize: 12
                color: root.darkMode ? "#c7c7cc" : "#6b7280"
            }

            ListView {
                id: pinnedListView
                visible: pinnedListModel.count > 0
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.preferredHeight: contentHeight
                spacing: 8
                clip: true
                interactive: !root.collapsed
                model: pinnedListModel

                delegate: SidebarItem {
                    width: pinnedListView.width
                    label: name
                    iconText: icon
                    accentColor: color
                    collapsed: root.collapsed
                    darkMode: root.darkMode
                    selected: appState.currentSection === name
                    onClicked: appState.selectList(listId)

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.RightButton
                        onClicked: {
                            listContextMenu.listId = listId
                            listContextMenu.listType = listType
                            listContextMenu.isSystem = isSystem
                            listContextMenu.isPinned = true
                            listContextMenu.popup()
                        }
                    }

                    
                }
            }

            Rectangle {
                visible: pinnedListModel.count > 0
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: root.darkMode ? "#2a2c33" : "#e3e5ec"
            }

            Text {
                visible: !root.collapsed
                text: "Lists"
                font.pixelSize: 12
                color: root.darkMode ? "#c7c7cc" : "#6b7280"
            }

            ListView {
                id: unpinnedListView
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.preferredHeight: contentHeight
                spacing: 8
                clip: true
                interactive: !root.collapsed
                model: unpinnedListModel

                delegate: SidebarItem {
                    width: unpinnedListView.width
                    label: name
                    iconText: icon
                    accentColor: color
                    collapsed: root.collapsed
                    darkMode: root.darkMode
                    selected: appState.currentSection === name
                    onClicked: appState.selectList(listId)

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.RightButton
                        onClicked: {
                            listContextMenu.listId = listId
                            listContextMenu.listType = listType
                            listContextMenu.isSystem = isSystem
                            listContextMenu.isPinned = false
                            listContextMenu.popup()
                        }
                    }

                    
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.preferredWidth: root.collapsed ? 36 : 44
                Layout.preferredHeight: root.collapsed ? 36 : 44
                radius: root.collapsed ? 10 : 12
                color: root.darkMode ? "#1b1d22" : "#f3f4f8"
                visible: true

                Text {
                    anchors.centerIn: parent
                    text: "+"
                    font.pixelSize: 18
                    color: root.darkMode ? "#f2f2f7" : "#1c1c1e"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: newListPopup.open()
                }
            }

            Repeater {
                model: appState.sidebarLists

                delegate: SidebarItem {
                    required property var modelData
                    visible: modelData.listType === "settings" || modelData.listType === "profile"
                    Layout.fillWidth: true
                    label: modelData.name
                    iconText: modelData.icon
                    accentColor: modelData.color
                    collapsed: root.collapsed
                    darkMode: root.darkMode
                    selected: appState.currentSection === modelData.name
                    onClicked: appState.selectList(modelData.id)
                }
            }
        }
    }

    Menu {
        id: listContextMenu
        property string listId: ""
        property string listType: ""
        property bool isSystem: false
        property bool isPinned: false

        MenuItem {
            text: "Edit List"
                    enabled: listContextMenu.listType !== "settings"
                             && listContextMenu.listType !== "profile"
            onTriggered: {
                editListPopup.listId = listContextMenu.listId
                editListPopup.open()
            }
        }

        MenuItem {
            text: listContextMenu.isPinned ? "Unpin" : "Pin"
            enabled: listContextMenu.listType !== "settings" && listContextMenu.listType !== "profile"
            onTriggered: appState.toggleListPinned(listContextMenu.listId)
        }

        MenuItem {
            text: "Remove"
            enabled: listContextMenu.listType !== "settings" && listContextMenu.listType !== "profile"
            onTriggered: appState.deleteSidebarList(listContextMenu.listId)
        }
    }

    Popup {
        id: newListPopup
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        parent: root.parent
        width: 360
        height: 320
        x: parent ? (parent.width - width) / 2 : 0
        y: parent ? (parent.height - height) / 2 : 0

        background: Rectangle {
            radius: 18
            color: root.darkMode ? "#101114" : "#ffffff"
            border.width: root.darkMode ? 0 : 1
            border.color: "#00000010"
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 28

                Text {
                    text: "New List"
                    font.pixelSize: 18
                    font.bold: true
                    color: root.darkMode ? "#f2f2f7" : "#1c1c1e"
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    width: 32
                    height: 32
                    radius: 10
                    color: root.darkMode ? "#1b1d22" : "#f3f4f8"

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.pixelSize: 13
                        color: root.darkMode ? "#f2f2f7" : "#1c1c1e"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: newListPopup.close()
                    }
                }
            }

            TextField {
                id: newListName
                Layout.fillWidth: true
                placeholderText: "List name"
                font.pixelSize: 14
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Icon"
                    font.pixelSize: 13
                    color: root.darkMode ? "#c7c7cc" : "#6b7280"
                }

                TextField {
                    id: newListIconField
                    Layout.preferredWidth: 120
                    placeholderText: "Icon"
                    font.pixelSize: 13
                }

                Rectangle {
                    width: 64
                    height: 28
                    radius: 8
                    color: root.darkMode ? "#1b1d22" : "#f3f4f8"

                    Text {
                        anchors.centerIn: parent
                        text: "Emoji"
                        font.pixelSize: 12
                        color: root.darkMode ? "#f2f2f7" : "#1c1c1e"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: appState.showEmojiPicker()
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Color"
                    font.pixelSize: 13
                    color: root.darkMode ? "#c7c7cc" : "#6b7280"
                }

                Rectangle {
                    width: 32
                    height: 32
                    radius: 10
                    color: newColorPreview
                    border.width: 1
                    border.color: "#00000020"

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: colorDialog.open()
                    }
                }

                Text {
                    text: newColorPreview
                    font.pixelSize: 13
                    color: root.darkMode ? "#c7c7cc" : "#6b7280"
                }
            }

            Rectangle {
                width: 80
                height: 36
                radius: 10
                color: root.darkMode ? "#1a1e27" : "#eaf0ff"

                Text {
                    anchors.centerIn: parent
                    text: "Add"
                    font.pixelSize: 13
                    font.bold: true
                    color: root.darkMode ? "#f2f2f7" : "#1c1c1e"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        const iconValue = newListIconField.text.length > 0 ? newListIconField.text : "•"
                        appState.addSidebarList(newListName.text, iconValue, newColorPreview)
                        newListName.text = ""
                        newListIconField.text = ""
                        newColorPreview = "#9aa1ad"
                        newListPopup.close()
                    }
                }
            }
        }
    }

    Popup {
        id: editListPopup
        property string listId: ""
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        parent: root.parent
        width: 360
        height: 320
        x: parent ? (parent.width - width) / 2 : 0
        y: parent ? (parent.height - height) / 2 : 0

        background: Rectangle {
            radius: 18
            color: root.darkMode ? "#101114" : "#ffffff"
            border.width: root.darkMode ? 0 : 1
            border.color: "#00000010"
        }

        property string editName: ""
        property string editIcon: ""
        property string editColor: "#9aa1ad"

        onOpened: {
            for (let i = 0; i < appState.sidebarLists.length; i++) {
                const item = appState.sidebarLists[i]
                if (item.id === listId) {
                    editListPopup.editName = item.name
                    editListPopup.editIcon = item.icon
                    editListPopup.editColor = item.color
                    break
                }
        }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 28

                Text {
                    text: "Edit List"
                    font.pixelSize: 18
                    font.bold: true
                    color: root.darkMode ? "#f2f2f7" : "#1c1c1e"
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    width: 32
                    height: 32
                    radius: 10
                    color: root.darkMode ? "#1b1d22" : "#f3f4f8"

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.pixelSize: 13
                        color: root.darkMode ? "#f2f2f7" : "#1c1c1e"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: editListPopup.close()
                    }
                }
            }

            TextField {
                id: editNameField
                Layout.fillWidth: true
                text: editListPopup.editName
                font.pixelSize: 14
                onTextChanged: editListPopup.editName = text
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Icon"
                    font.pixelSize: 13
                    color: root.darkMode ? "#c7c7cc" : "#6b7280"
                }

                TextField {
                    id: editIconField
                    Layout.preferredWidth: 120
                    placeholderText: "Icon"
                    text: editListPopup.editIcon
                    font.pixelSize: 13
                    onTextChanged: editListPopup.editIcon = text
                }

                Rectangle {
                    width: 64
                    height: 28
                    radius: 8
                    color: root.darkMode ? "#1b1d22" : "#f3f4f8"

                    Text {
                        anchors.centerIn: parent
                        text: "Emoji"
                        font.pixelSize: 12
                        color: root.darkMode ? "#f2f2f7" : "#1c1c1e"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: appState.showEmojiPicker()
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Color"
                    font.pixelSize: 13
                    color: root.darkMode ? "#c7c7cc" : "#6b7280"
                }

                Rectangle {
                    width: 32
                    height: 32
                    radius: 10
                    color: editListPopup.editColor
                    border.width: 1
                    border.color: "#00000020"

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: editColorDialog.open()
                    }
                }

                Text {
                    text: editListPopup.editColor
                    font.pixelSize: 13
                    color: root.darkMode ? "#c7c7cc" : "#6b7280"
                }
            }

            Rectangle {
                width: 80
                height: 36
                radius: 10
                color: root.darkMode ? "#1a1e27" : "#eaf0ff"

                Text {
                    anchors.centerIn: parent
                    text: "Save"
                    font.pixelSize: 13
                    font.bold: true
                    color: root.darkMode ? "#f2f2f7" : "#1c1c1e"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        const iconValue = editListPopup.editIcon.length > 0 ? editListPopup.editIcon : "•"
                        appState.updateSidebarList(editListPopup.listId, editListPopup.editName, iconValue, editListPopup.editColor)
                        editListPopup.close()
                    }
                }
            }
        }
    }

    ColorDialog {
        id: colorDialog
        onAccepted: newColorPreview = selectedColor.toString()
    }

    ColorDialog {
        id: editColorDialog
        onAccepted: editListPopup.editColor = selectedColor.toString()
    }

    property string newColorPreview: "#9aa1ad"
}
