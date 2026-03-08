import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property bool darkMode: false
    property int sidebarWidth: 272
    property string selectedEventId: ""
    property string selectedDay: appState ? appState.calendarDate : "1970-01-01"
    property var eventStartDateTime: new Date((appState ? appState.calendarDate : "1970-01-01") + "T09:00:00")
    property var eventEndDateTime: new Date((appState ? appState.calendarDate : "1970-01-01") + "T10:00:00")
    property var editStartDateTime: new Date((appState ? appState.calendarDate : "1970-01-01") + "T09:00:00")
    property var editEndDateTime: new Date((appState ? appState.calendarDate : "1970-01-01") + "T10:00:00")
    property bool eventAllDay: false
    property bool editAllDay: false
    property int eventCalendarIndex: -1
    property int editCalendarIndex: -1
    property var allDayItems: []
    property string datePickerTarget: ""
    property string timePickerTarget: ""
    property int datePickerYear: new Date(appState ? appState.calendarDate : "1970-01-01").getFullYear()
    property int datePickerMonth: new Date(appState ? appState.calendarDate : "1970-01-01").getMonth()

    color: "transparent"

    Rectangle {
        x: sidebarWidth
        width: parent.width - sidebarWidth
        height: parent.height
        color: darkMode ? "#050505" : "#f6f7fb"
    }

    Column {
        anchors.fill: parent
        anchors.leftMargin: sidebarWidth + 28
        anchors.rightMargin: 28
        anchors.topMargin: 28
        anchors.bottomMargin: 28
        spacing: 20

        Behavior on anchors.leftMargin {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        TextInput {
            width: parent.width
            height: 44
            text: "Calendar"
            font.pixelSize: 34
            font.bold: true
            color: darkMode ? "#f2f2f7" : "#1c1c1e"
            readOnly: true
        }

        Row {
            spacing: 12

            Repeater {
                model: ["Day", "Month", "Year"]
                delegate: Rectangle {
                    width: 96
                    height: 36
                    radius: 12
                    color: appState && appState.calendarView === modelData.toLowerCase()
                           ? (darkMode ? "#1b1f28" : "#ffffff")
                           : "transparent"
                    border.width: appState && appState.calendarView === modelData.toLowerCase() && !darkMode ? 1 : 0
                    border.color: "#00000008"

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        font.pixelSize: 14
                        font.bold: appState && appState.calendarView === modelData.toLowerCase()
                        color: darkMode ? "#f2f2f7" : "#1c1c1e"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (appState) { appState.setCalendarView(modelData.toLowerCase()) }
                    }
                }
            }
        }

        Rectangle {
            width: Math.min(parent.width, 980)
            height: 560
            radius: 22
            color: darkMode ? "#0b0c0f" : "#ffffff"
            border.width: darkMode ? 0 : 1
            border.color: "#00000008"

            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                Row {
                    spacing: 10

                    Rectangle {
                        width: 32
                        height: 32
                        radius: 10
                        color: darkMode ? "#1b1d22" : "#f3f4f8"

                        Text {
                            anchors.centerIn: parent
                            text: "‹"
                            font.pixelSize: 18
                            color: darkMode ? "#f2f2f7" : "#1c1c1e"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: shiftDate(-1)
                        }
                    }

                    Text {
                        text: appState ? appState.calendarDate : "1970-01-01"
                        font.pixelSize: 16
                        font.bold: true
                        color: darkMode ? "#f2f2f7" : "#1c1c1e"
                    }

                    Rectangle {
                        id: datePickerButton
                        width: 160
                        height: 32
                        radius: 10
                        color: darkMode ? "#15161a" : "#f4f6fb"
                        border.width: darkMode ? 0 : 1
                        border.color: "#00000008"

                        Text {
                            anchors.centerIn: parent
                        text: appState ? appState.calendarDate : "1970-01-01"
                            font.pixelSize: 12
                            color: darkMode ? "#f2f2f7" : "#1c1c1e"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: openDatePicker("main")
                        }
                    }

                    Rectangle {
                        width: 32
                        height: 32
                        radius: 10
                        color: darkMode ? "#1b1d22" : "#f3f4f8"

                        Text {
                            anchors.centerIn: parent
                            text: "›"
                            font.pixelSize: 18
                            color: darkMode ? "#f2f2f7" : "#1c1c1e"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: shiftDate(1)
                        }
                    }

                    Item { width: 24 }

                    Rectangle {
                        width: 96
                        height: 32
                        radius: 10
                        color: darkMode ? "#1a1e27" : "#eaf0ff"

                        Text {
                            anchors.centerIn: parent
                            text: "New Event"
                            font.pixelSize: 12
                            font.bold: true
                            color: darkMode ? "#f2f2f7" : "#1c1c1e"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: eventPopup.open()
                        }
                    }
                }

                Row {
                    id: bodyRow
                    width: parent.width
                    spacing: 18

                    Loader {
                        id: leftPanelLoader
                        width: Math.round(bodyRow.width * 0.65)
                        height: 420
                        sourceComponent: appState && appState.calendarView === "day"
                                         ? dayPanelComponent
                                         : (appState && appState.calendarView === "year"
                                            ? yearPanelComponent
                                            : monthPanelComponent)
                    }

                    Rectangle {
                        width: bodyRow.width - leftPanelLoader.width - bodyRow.spacing
                        height: 420
                        radius: 16
                        color: darkMode ? "#15161a" : "#f4f6fb"

                        Column {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 10

                            Text {
                                text: "Events"
                                font.pixelSize: 16
                                font.bold: true
                                color: darkMode ? "#f2f2f7" : "#1c1c1e"
                            }

                            Text {
                                text: root.selectedDay
                                font.pixelSize: 12
                                color: darkMode ? "#8e8e93" : "#6e6e73"
                            }

                            Rectangle {
                                width: parent.width
                                height: 160
                                radius: 12
                                color: darkMode ? "#101216" : "#ffffff"
                                border.width: darkMode ? 0 : 1
                                border.color: "#00000008"

                                ListView {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    clip: true
                                    model: eventsForSelectedDay()

                                    delegate: Rectangle {
                                        width: parent.width
                                        height: 34
                                        radius: 8
                                        color: modelData.id === root.selectedEventId
                                               ? (darkMode ? "#1f232b" : "#f4f6fb")
                                               : "transparent"

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: modelData.title
                                            font.pixelSize: 12
                                            color: darkMode ? "#f2f2f7" : "#1c1c1e"
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.selectedEventId = modelData.id
                                        }
                                    }
                                }
                            }

                            Text {
                                text: "Details"
                                font.pixelSize: 14
                                font.bold: true
                                color: darkMode ? "#c7c7cc" : "#4b5563"
                            }

                            Rectangle {
                                width: parent.width
                                height: 140
                                radius: 12
                                color: darkMode ? "#101216" : "#ffffff"
                                border.width: darkMode ? 0 : 1
                                border.color: "#00000008"

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 6

                                    Text {
                                        text: selectedEventTitle()
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: darkMode ? "#f2f2f7" : "#1c1c1e"
                                    }

                                    Text {
                                        text: selectedEventTime()
                                        font.pixelSize: 11
                                        color: darkMode ? "#8e8e93" : "#6e6e73"
                                    }

                                    Text {
                                        text: selectedEventNotes()
                                        font.pixelSize: 11
                                        color: darkMode ? "#c7c7cc" : "#4b5563"
                                        elide: Text.ElideRight
                                    }

                                    Rectangle {
                                        width: 72
                                        height: 26
                                        radius: 8
                                        visible: root.selectedEventId.length > 0
                                        color: darkMode ? "#1b1d22" : "#f3f4f8"

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Edit"
                                            font.pixelSize: 12
                                            color: darkMode ? "#f2f2f7" : "#1c1c1e"
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: openEditEvent()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: monthPanelComponent

        Rectangle {
            id: monthPanel
            width: leftPanelLoader.width
            height: leftPanelLoader.height
            radius: 16
            color: darkMode ? "#15161a" : "#f4f6fb"

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                Row {
                    width: monthGrid.width
                    spacing: 8

                    Repeater {
                        model: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
                        delegate: Text {
                            width: (monthGrid.width - 6 * 8) / 7
                            text: modelData
                            font.pixelSize: 12
                            color: darkMode ? "#8e8e93" : "#6e6e73"
                        }
                    }
                }

                GridLayout {
                    id: monthGrid
                    width: monthPanel.width - 28
                    columns: 7
                    columnSpacing: 8
                    rowSpacing: 8

                    Repeater {
                        model: monthCells()
                        delegate: Rectangle {
                            width: (monthGrid.width - 6 * 8) / 7
                            height: 54
                            radius: 12
                            color: modelData.inMonth
                                   ? (modelData.date === root.selectedDay
                                      ? (darkMode ? "#1f232b" : "#ffffff")
                                      : (darkMode ? "#101216" : "#ffffff"))
                                   : "transparent"
                            border.width: modelData.date === root.selectedDay ? 1 : 0
                            border.color: darkMode ? "#3a3d46" : "#e1e6f0"

                            Column {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 4

                                Text {
                                    text: modelData.day
                                    font.pixelSize: 13
                                    color: modelData.inMonth
                                           ? (darkMode ? "#f2f2f7" : "#1c1c1e")
                                           : (darkMode ? "#4b4f58" : "#c2c7d0")
                                }

                                Row {
                                    spacing: 4
                                    Repeater {
                                        model: Math.min(modelData.eventCount, 3)
                                        delegate: Rectangle {
                                            width: 6
                                            height: 6
                                            radius: 3
                                                    color: appState ? appState.calendarColor : "#9aa1ad"
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                enabled: modelData.inMonth
                                onClicked: {
                                    root.selectedDay = modelData.date
                                    root.selectedEventId = ""
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: dayPanelComponent

        Rectangle {
            width: leftPanelLoader.width
            height: leftPanelLoader.height
            radius: 16
            color: darkMode ? "#15161a" : "#f4f6fb"

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                Text {
                    text: "Day Schedule"
                    font.pixelSize: 14
                    font.bold: true
                    color: darkMode ? "#f2f2f7" : "#1c1c1e"
                }

                Rectangle {
                    width: parent ? parent.width : 0
                    height: parent.height - 34
                    radius: 12
                    color: darkMode ? "#101216" : "#ffffff"
                    border.width: darkMode ? 0 : 1
                    border.color: "#00000008"

                    Column {
                        id: dayContent
                        x: 10
                        y: 10
                        width: parent.width - 20
                        height: parent.height - 20
                        spacing: 8

                        Rectangle {
                            id: allDayBar
                            width: parent ? parent.width : 0
                            height: allDayItems.length > 0 ? 44 : 0
                            radius: 8
                            visible: allDayItems.length > 0
                            color: darkMode ? "#14161b" : "#f7f8fc"

                            Row {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 6

                                Text {
                                    text: "All-day"
                                    font.pixelSize: 11
                                    color: darkMode ? "#8e8e93" : "#6e6e73"
                                }

                                Repeater {
                                    model: allDayItems
                                    delegate: Rectangle {
                                        height: 24
                                        radius: 8
                                        color: modelData.id === root.selectedEventId
                                               ? (darkMode ? "#1f232b" : "#eef2ff")
                                               : (darkMode ? "#1a1e26" : "#ffffff")

                                        Text {
                                            id: allDayTitle
                                            anchors.centerIn: parent
                                            text: modelData.title
                                            font.pixelSize: 11
                                            color: darkMode ? "#f2f2f7" : "#1c1c1e"
                                            elide: Text.ElideRight
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        width: Math.min(160, allDayTitle.implicitWidth + 16)

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.selectedEventId = modelData.id
                                        }
                                    }
                                }
                            }
                        }

                        ListView {
                            width: parent ? parent.width : 0
                            height: parent ? parent.height - (allDayBar.visible ? (allDayBar.height + 8) : 0) : 0
                            clip: true
                            model: 24

                            delegate: Row {
                                width: ListView.view ? ListView.view.width : 0
                                height: 44
                                spacing: 12

                                Text {
                                    width: 44
                                    text: Qt.formatTime(new Date(2000, 0, 1, index, 0), "hh:mm")
                                    font.pixelSize: 11
                                    color: darkMode ? "#8e8e93" : "#6e6e73"
                                }

                                Column {
                                    width: (ListView.view ? ListView.view.width : 0) - 60
                                    spacing: 4

                                    Repeater {
                                        model: eventsForHour(index)
                                        delegate: Rectangle {
                                            width: ListView.view ? ListView.view.width - 60 : 0
                                            height: 26
                                            radius: 8
                                            color: modelData.id === root.selectedEventId
                                                   ? (darkMode ? "#1f232b" : "#f4f6fb")
                                                   : (darkMode ? "#14161b" : "#f7f8fc")

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.title
                                                font.pixelSize: 11
                                                color: darkMode ? "#f2f2f7" : "#1c1c1e"
                                                elide: Text.ElideRight
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.selectedEventId = modelData.id
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: yearPanelComponent

        Rectangle {
            width: leftPanelLoader.width
            height: leftPanelLoader.height
            radius: 16
            color: darkMode ? "#15161a" : "#f4f6fb"

            GridLayout {
                anchors.fill: parent
                anchors.margins: 12
                columns: 3
                rowSpacing: 12
                columnSpacing: 12

                Repeater {
                    model: yearMonths()
                    delegate: Rectangle {
                        width: (leftPanelLoader.width - 24 - 2 * 12) / 3
                        height: (leftPanelLoader.height - 24 - 3 * 12) / 4
                        radius: 12
                        color: darkMode ? "#101216" : "#ffffff"
                        border.width: darkMode ? 0 : 1
                        border.color: "#00000008"

                        Column {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 6

                            Text {
                                text: modelData.name
                                font.pixelSize: 11
                                font.bold: true
                                color: darkMode ? "#f2f2f7" : "#1c1c1e"
                            }

                            GridLayout {
                                columns: 7
                                columnSpacing: 2
                                rowSpacing: 2

                                Repeater {
                                    model: monthCellsFor(modelData.index)
                                    delegate: Text {
                                        width: 12
                                        height: 12
                                        text: modelData.day
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        font.pixelSize: 9
                                        color: modelData.inMonth
                                               ? (darkMode ? "#c7c7cc" : "#4b5563")
                                               : "transparent"
                                    }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const year = new Date(appState ? appState.calendarDate : root.selectedDay).getFullYear()
                                const dateStr = new Date(year, modelData.index, 1)
                                    .toISOString()
                                    .slice(0, 10)
                                appState.setCalendarView("month")
                                appState.setCalendarDate(dateStr)
                            }
                        }
                    }
                }
            }
        }
    }

    Popup {
        id: datePickerPopup
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        width: 280
        height: 320
        anchors.centerIn: parent

        background: Rectangle {
            radius: 16
            color: darkMode ? "#0b0c0f" : "#ffffff"
            border.width: darkMode ? 0 : 1
            border.color: "#00000008"
        }

        Column {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            Row {
                spacing: 8

                Rectangle {
                    width: 24
                    height: 24
                    radius: 8
                    color: darkMode ? "#1b1d22" : "#f3f4f8"

                    Text {
                        anchors.centerIn: parent
                        text: "‹"
                        font.pixelSize: 14
                        color: darkMode ? "#f2f2f7" : "#1c1c1e"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            datePickerMonth -= 1
                            if (datePickerMonth < 0) {
                                datePickerMonth = 11
                                datePickerYear -= 1
                            }
                        }
                    }
                }

                Text {
                    text: monthName(datePickerMonth) + " " + datePickerYear
                    font.pixelSize: 14
                    font.bold: true
                    color: darkMode ? "#f2f2f7" : "#1c1c1e"
                }

                Rectangle {
                    width: 24
                    height: 24
                    radius: 8
                    color: darkMode ? "#1b1d22" : "#f3f4f8"

                    Text {
                        anchors.centerIn: parent
                        text: "›"
                        font.pixelSize: 14
                        color: darkMode ? "#f2f2f7" : "#1c1c1e"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            datePickerMonth += 1
                            if (datePickerMonth > 11) {
                                datePickerMonth = 0
                                datePickerYear += 1
                            }
                        }
                    }
                }
            }

            Row {
                spacing: 4

                Repeater {
                    model: ["S", "M", "T", "W", "T", "F", "S"]
                    delegate: Text {
                        width: 32
                        text: modelData
                        font.pixelSize: 11
                        color: darkMode ? "#8e8e93" : "#6e6e73"
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            GridLayout {
                columns: 7
                columnSpacing: 4
                rowSpacing: 4

                Repeater {
                    model: monthCellsForYearMonth(datePickerYear, datePickerMonth)
                    delegate: Rectangle {
                        width: 32
                        height: 28
                        radius: 8
                        color: modelData.inMonth && isSelectedDate(modelData.date)
                               ? (darkMode ? "#1f232b" : "#f4f6fb")
                               : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: modelData.day
                            font.pixelSize: 11
                            color: modelData.inMonth
                                   ? (darkMode ? "#f2f2f7" : "#1c1c1e")
                                   : "transparent"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: modelData.inMonth ? Qt.PointingHandCursor : Qt.ArrowCursor
                            enabled: modelData.inMonth
                            onClicked: applyDateSelection(modelData.date)
                        }
                    }
                }
            }
        }
    }

    Popup {
        id: timePickerPopup
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        width: 140
        height: 240
        anchors.centerIn: parent

        background: Rectangle {
            radius: 16
            color: darkMode ? "#0b0c0f" : "#ffffff"
            border.width: darkMode ? 0 : 1
            border.color: "#00000008"
        }

        ListView {
            anchors.fill: parent
            anchors.margins: 8
            clip: true
            model: timeOptions()

            delegate: Rectangle {
                width: ListView.view ? ListView.view.width : 0
                height: 28
                radius: 8
                color: "transparent"

                Text {
                    anchors.centerIn: parent
                    text: modelData
                    font.pixelSize: 12
                    color: darkMode ? "#f2f2f7" : "#1c1c1e"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: applyTimeSelection(modelData)
                }
            }
        }
    }

    Popup {
        id: calendarPickerPopup
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        width: 260
        height: 240
        anchors.centerIn: parent
        z: 2000

        background: Rectangle {
            radius: 16
            color: darkMode ? "#0b0c0f" : "#ffffff"
            border.width: darkMode ? 0 : 1
            border.color: "#00000008"
        }

        ListView {
            anchors.fill: parent
            anchors.margins: 8
            clip: true
            model: appState ? appState.calendarAvailableCalendars : []

            delegate: Rectangle {
                width: ListView.view ? ListView.view.width : 0
                height: 32
                radius: 8
                color: "transparent"

                Text {
                    anchors.centerIn: parent
                    text: modelData.name
                    font.pixelSize: 12
                    color: darkMode ? "#f2f2f7" : "#1c1c1e"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        eventCalendarIndex = index
                        calendarPickerPopup.close()
                    }
                }
            }
        }
    }

    Popup {
        id: editCalendarPickerPopup
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        width: 260
        height: 240
        anchors.centerIn: parent
        z: 2000

        background: Rectangle {
            radius: 16
            color: darkMode ? "#0b0c0f" : "#ffffff"
            border.width: darkMode ? 0 : 1
            border.color: "#00000008"
        }

        ListView {
            anchors.fill: parent
            anchors.margins: 8
            clip: true
            model: appState ? appState.calendarAvailableCalendars : []

            delegate: Rectangle {
                width: ListView.view ? ListView.view.width : 0
                height: 32
                radius: 8
                color: "transparent"

                Text {
                    anchors.centerIn: parent
                    text: modelData.name
                    font.pixelSize: 12
                    color: darkMode ? "#f2f2f7" : "#1c1c1e"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        editCalendarIndex = index
                        editCalendarPickerPopup.close()
                    }
                }
            }
        }
    }

    Popup {
        id: eventPopup
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        width: 380
        height: 360
        anchors.centerIn: parent
        onOpened: {
            const base = new Date(root.selectedDay + "T09:00:00")
            eventStartDateTime = base
            eventEndDateTime = new Date(base.getTime() + 60 * 60 * 1000)
            eventAllDay = false
            eventTitleField.text = ""
            eventNotesField.text = ""
            if (eventCalendarIndex < 0 && appState && appState.calendarAvailableCalendars.length > 0) {
                eventCalendarIndex = 0
            }
        }
        onClosed: {
            if (!appState || eventCalendarIndex < 0) {
                return
            }
            if (!eventTitleField.text.trim()) {
                return
            }
            const normalized = normalizeEventRange(eventStartDateTime, eventEndDateTime, eventAllDay)
            eventStartDateTime = normalized.start
            eventEndDateTime = normalized.end
            const startIso = eventAllDay ? formatDate(eventStartDateTime) : dateTimeToIso(eventStartDateTime)
            const endIso = eventAllDay ? formatDate(eventEndDateTime) : dateTimeToIso(eventEndDateTime)
            const item = appState.calendarAvailableCalendars[eventCalendarIndex]
            appState.createCalendarEvent(
                item.provider,
                item.id,
                eventTitleField.text,
                startIso,
                endIso,
                eventNotesField.text,
                eventAllDay
            )
        }

        background: Rectangle {
            radius: 18
            color: darkMode ? "#0b0c0f" : "#ffffff"
            border.width: darkMode ? 0 : 1
            border.color: "#00000008"
        }

        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Text {
                text: "New Event"
                font.pixelSize: 18
                font.bold: true
                color: darkMode ? "#f2f2f7" : "#1c1c1e"
            }

            TextField {
                id: eventTitleField
                placeholderText: "Title"
            }

            Rectangle {
                width: parent.width
                height: 32
                radius: 10
                color: darkMode ? "#15161a" : "#f4f6fb"
                border.width: darkMode ? 0 : 1
                border.color: "#00000008"

                Text {
                    anchors.centerIn: parent
                    text: eventCalendarIndex >= 0 && appState && appState.calendarAvailableCalendars.length > 0
                          ? appState.calendarAvailableCalendars[eventCalendarIndex].name
                          : "Select calendar"
                    font.pixelSize: 12
                    color: darkMode ? "#f2f2f7" : "#1c1c1e"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: calendarPickerPopup.open()
                }
            }

            Row {
                spacing: 8

                Rectangle {
                    width: 72
                    height: 28
                    radius: 8
                    color: eventAllDay ? (darkMode ? "#1f232b" : "#eef2ff") : "transparent"
                    border.width: eventAllDay ? 0 : 1
                    border.color: "#00000008"

                    Text {
                        anchors.centerIn: parent
                        text: "All-day"
                        font.pixelSize: 11
                        color: darkMode ? "#f2f2f7" : "#1c1c1e"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: eventAllDay = !eventAllDay
                    }
                }
            }

            Row {
                spacing: 10

                Rectangle {
                    width: 160
                    height: 32
                    radius: 10
                    color: darkMode ? "#15161a" : "#f4f6fb"
                    border.width: darkMode ? 0 : 1
                    border.color: "#00000008"

                    Text {
                        anchors.centerIn: parent
                        text: formatDate(eventStartDateTime)
                        font.pixelSize: 12
                        color: darkMode ? "#f2f2f7" : "#1c1c1e"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: openDatePicker("eventStart")
                    }
                }

                Rectangle {
                    width: 110
                    height: 32
                    radius: 10
                    color: darkMode ? "#15161a" : "#f4f6fb"
                    border.width: darkMode ? 0 : 1
                    border.color: "#00000008"
                    visible: !eventAllDay

                    Text {
                        anchors.centerIn: parent
                        text: formatTime(eventStartDateTime)
                        font.pixelSize: 12
                        color: darkMode ? "#f2f2f7" : "#1c1c1e"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: openTimePicker("eventStart")
                    }
                }
            }

            Row {
                spacing: 10

                Rectangle {
                    width: 160
                    height: 32
                    radius: 10
                    color: darkMode ? "#15161a" : "#f4f6fb"
                    border.width: darkMode ? 0 : 1
                    border.color: "#00000008"

                    Text {
                        anchors.centerIn: parent
                        text: formatDate(eventEndDateTime)
                        font.pixelSize: 12
                        color: darkMode ? "#f2f2f7" : "#1c1c1e"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: openDatePicker("eventEnd")
                    }
                }

                Rectangle {
                    width: 110
                    height: 32
                    radius: 10
                    color: darkMode ? "#15161a" : "#f4f6fb"
                    border.width: darkMode ? 0 : 1
                    border.color: "#00000008"
                    visible: !eventAllDay

                    Text {
                        anchors.centerIn: parent
                        text: formatTime(eventEndDateTime)
                        font.pixelSize: 12
                        color: darkMode ? "#f2f2f7" : "#1c1c1e"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: openTimePicker("eventEnd")
                    }
                }
            }

            TextArea {
                id: eventNotesField
                height: 80
                placeholderText: "Notes"
            }

            Item {
                width: 1
                height: 1
            }
        }
    }

    Popup {
        id: editEventPopup
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        width: 380
        height: 360
        anchors.centerIn: parent
        onClosed: {
            const selected = selectedEvent()
            if (!appState || !selected) {
                return
            }
            const normalized = normalizeEventRange(editStartDateTime, editEndDateTime, editAllDay)
            editStartDateTime = normalized.start
            editEndDateTime = normalized.end
            let item = null
            if (editCalendarIndex >= 0) {
                item = appState.calendarAvailableCalendars[editCalendarIndex]
            } else {
                item = { provider: selected.provider, id: selected.calendar_id }
            }
            const startIso = editAllDay ? formatDate(editStartDateTime) : dateTimeToIso(editStartDateTime)
            const endIso = editAllDay ? formatDate(editEndDateTime) : dateTimeToIso(editEndDateTime)
            appState.updateCalendarEvent(
                item.provider,
                root.selectedEventId,
                item.id,
                editTitleField.text,
                startIso,
                endIso,
                editNotesField.text,
                editAllDay
            )
        }

        background: Rectangle {
            radius: 18
            color: darkMode ? "#0b0c0f" : "#ffffff"
            border.width: darkMode ? 0 : 1
            border.color: "#00000008"
        }

        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Text {
                text: "Edit Event"
                font.pixelSize: 18
                font.bold: true
                color: darkMode ? "#f2f2f7" : "#1c1c1e"
            }

            TextField {
                id: editTitleField
                placeholderText: "Title"
            }

            Rectangle {
                width: parent.width
                height: 32
                radius: 10
                color: darkMode ? "#15161a" : "#f4f6fb"
                border.width: darkMode ? 0 : 1
                border.color: "#00000008"

                Text {
                    anchors.centerIn: parent
                    text: editCalendarIndex >= 0 && appState && appState.calendarAvailableCalendars.length > 0
                          ? appState.calendarAvailableCalendars[editCalendarIndex].name
                          : "Select calendar"
                    font.pixelSize: 12
                    color: darkMode ? "#f2f2f7" : "#1c1c1e"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: editCalendarPickerPopup.open()
                }
            }

            Row {
                spacing: 8

                Rectangle {
                    width: 72
                    height: 28
                    radius: 8
                    color: editAllDay ? (darkMode ? "#1f232b" : "#eef2ff") : "transparent"
                    border.width: editAllDay ? 0 : 1
                    border.color: "#00000008"

                    Text {
                        anchors.centerIn: parent
                        text: "All-day"
                        font.pixelSize: 11
                        color: darkMode ? "#f2f2f7" : "#1c1c1e"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: editAllDay = !editAllDay
                    }
                }
            }

            Row {
                spacing: 10

                Rectangle {
                    width: 160
                    height: 32
                    radius: 10
                    color: darkMode ? "#15161a" : "#f4f6fb"
                    border.width: darkMode ? 0 : 1
                    border.color: "#00000008"

                    Text {
                        anchors.centerIn: parent
                        text: formatDate(editStartDateTime)
                        font.pixelSize: 12
                        color: darkMode ? "#f2f2f7" : "#1c1c1e"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: openDatePicker("editStart")
                    }
                }

                Rectangle {
                    width: 110
                    height: 32
                    radius: 10
                    color: darkMode ? "#15161a" : "#f4f6fb"
                    border.width: darkMode ? 0 : 1
                    border.color: "#00000008"

                    Text {
                        anchors.centerIn: parent
                        text: formatTime(editStartDateTime)
                        font.pixelSize: 12
                        color: darkMode ? "#f2f2f7" : "#1c1c1e"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: openTimePicker("editStart")
                    }
                }
            }

            Row {
                spacing: 10

                Rectangle {
                    width: 160
                    height: 32
                    radius: 10
                    color: darkMode ? "#15161a" : "#f4f6fb"
                    border.width: darkMode ? 0 : 1
                    border.color: "#00000008"

                    Text {
                        anchors.centerIn: parent
                        text: formatDate(editEndDateTime)
                        font.pixelSize: 12
                        color: darkMode ? "#f2f2f7" : "#1c1c1e"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: openDatePicker("editEnd")
                    }
                }

                Rectangle {
                    width: 110
                    height: 32
                    radius: 10
                    color: darkMode ? "#15161a" : "#f4f6fb"
                    border.width: darkMode ? 0 : 1
                    border.color: "#00000008"

                    Text {
                        anchors.centerIn: parent
                        text: formatTime(editEndDateTime)
                        font.pixelSize: 12
                        color: darkMode ? "#f2f2f7" : "#1c1c1e"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: openTimePicker("editEnd")
                    }
                }
            }

            TextArea {
                id: editNotesField
                height: 80
                placeholderText: "Notes"
            }

            Item {
                width: 1
                height: 1
            }
        }
    }

    function pad(value) {
        return value < 10 ? "0" + value : "" + value
    }

    function formatDate(dateObj) {
        if (!dateObj || isNaN(dateObj.getTime())) {
            return appState ? appState.calendarDate : "1970-01-01"
        }
        return dateObj.getFullYear()
            + "-" + pad(dateObj.getMonth() + 1)
            + "-" + pad(dateObj.getDate())
    }

    function formatTime(dateObj) {
        if (!dateObj || isNaN(dateObj.getTime())) {
            return "09:00"
        }
        return pad(dateObj.getHours()) + ":" + pad(dateObj.getMinutes())
    }

    function dateTimeToIso(dateObj) {
        return formatDate(dateObj) + "T" + formatTime(dateObj)
    }

    function normalizeEventRange(startDate, endDate, allDay) {
        let start = new Date(startDate)
        let end = new Date(endDate)
        if (allDay) {
            if (end <= start) {
                end = new Date(start.getTime() + 24 * 60 * 60 * 1000)
            }
        } else if (end <= start) {
            end = new Date(start.getTime() + 30 * 60 * 1000)
        }
        return { start: start, end: end }
    }

    function monthName(index) {
        const names = [
            "January", "February", "March", "April", "May", "June",
            "July", "August", "September", "October", "November", "December"
        ]
        return names[index] || ""
    }

    function openDatePicker(target) {
        datePickerTarget = target
        const base = targetDate(target)
        datePickerYear = base.getFullYear()
        datePickerMonth = base.getMonth()
        datePickerPopup.open()
    }

    function openTimePicker(target) {
        timePickerTarget = target
        timePickerPopup.open()
    }

    function targetDate(target) {
        if (target === "eventStart") {
            return eventStartDateTime
        }
        if (target === "eventEnd") {
            return eventEndDateTime
        }
        if (target === "editStart") {
            return editStartDateTime
        }
        if (target === "editEnd") {
            return editEndDateTime
        }
        const base = appState ? appState.calendarDate : root.selectedDay
        return new Date(base + "T00:00:00")
    }

    function applyDateSelection(dateStr) {
        if (!dateStr) {
            return
        }
        const chosen = new Date(dateStr + "T00:00:00")
        if (datePickerTarget === "eventStart") {
            eventStartDateTime = withTime(chosen, eventStartDateTime)
        } else if (datePickerTarget === "eventEnd") {
            eventEndDateTime = withTime(chosen, eventEndDateTime)
        } else if (datePickerTarget === "editStart") {
            editStartDateTime = withTime(chosen, editStartDateTime)
        } else if (datePickerTarget === "editEnd") {
            editEndDateTime = withTime(chosen, editEndDateTime)
        } else {
            appState.setCalendarDate(dateStr)
            root.selectedDay = dateStr
        }
        datePickerPopup.close()
    }

    function applyTimeSelection(timeStr) {
        const parts = timeStr.split(":")
        if (parts.length !== 2) {
            return
        }
        const hour = parseInt(parts[0], 10)
        const minute = parseInt(parts[1], 10)
        if (timePickerTarget === "eventStart") {
            eventStartDateTime = withHourMinute(eventStartDateTime, hour, minute)
        } else if (timePickerTarget === "eventEnd") {
            eventEndDateTime = withHourMinute(eventEndDateTime, hour, minute)
        } else if (timePickerTarget === "editStart") {
            editStartDateTime = withHourMinute(editStartDateTime, hour, minute)
        } else if (timePickerTarget === "editEnd") {
            editEndDateTime = withHourMinute(editEndDateTime, hour, minute)
        }
        timePickerPopup.close()
    }

    function withTime(dateObj, source) {
        return new Date(
            dateObj.getFullYear(),
            dateObj.getMonth(),
            dateObj.getDate(),
            source.getHours(),
            source.getMinutes()
        )
    }

    function withHourMinute(source, hour, minute) {
        return new Date(
            source.getFullYear(),
            source.getMonth(),
            source.getDate(),
            hour,
            minute
        )
    }

    function monthCellsForYearMonth(year, month) {
        const first = new Date(year, month, 1)
        const startDay = first.getDay()
        const daysInMonth = new Date(year, month + 1, 0).getDate()
        const cells = []
        for (let i = 0; i < startDay; i++) {
            cells.push({ day: "", inMonth: false, date: "" })
        }
        for (let d = 1; d <= daysInMonth; d++) {
            const dateStr = new Date(year, month, d).toISOString().slice(0, 10)
            cells.push({ day: d, inMonth: true, date: dateStr })
        }
        while (cells.length % 7 !== 0) {
            cells.push({ day: "", inMonth: false, date: "" })
        }
        return cells
    }

    function timeOptions() {
        const options = []
        for (let h = 0; h < 24; h++) {
            options.push(pad(h) + ":00")
            options.push(pad(h) + ":30")
        }
        return options
    }

    function isSelectedDate(dateStr) {
        const current = formatDate(targetDate(datePickerTarget || "main"))
        return current === dateStr
    }

    function parseEventDate(value) {
        if (!value) {
            return new Date(root.selectedDay + "T09:00:00")
        }
        const parsed = new Date(value)
        if (isNaN(parsed.getTime())) {
            const fallback = value.toString().replace(" ", "T")
            const next = new Date(fallback)
            if (!isNaN(next.getTime())) {
                return next
            }
            return new Date(root.selectedDay + "T09:00:00")
        }
        return parsed
    }

    function eventsForHour(hour) {
        const matches = []
        const list = eventsForDate(root.selectedDay)
        for (let i = 0; i < list.length; i++) {
            const item = list[i]
            if (item.all_day) {
                continue
            }
            if (!item.start) {
                continue
            }
            const parsed = new Date(item.start)
            if (isNaN(parsed.getTime())) {
                continue
            }
            if (parsed.getHours() === hour) {
                matches.push(item)
            }
        }
        return matches
    }

    function yearMonths() {
        const names = [
            "Jan", "Feb", "Mar", "Apr", "May", "Jun",
            "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
        ]
        const result = []
        for (let i = 0; i < names.length; i++) {
            result.push({ index: i, name: names[i] })
        }
        return result
    }

    function monthCellsFor(monthIndex) {
        const base = new Date(appState ? appState.calendarDate : root.selectedDay)
        const year = base.getFullYear()
        const first = new Date(year, monthIndex, 1)
        const startDay = first.getDay()
        const daysInMonth = new Date(year, monthIndex + 1, 0).getDate()
        const cells = []
        for (let i = 0; i < startDay; i++) {
            cells.push({ day: "", inMonth: false })
        }
        for (let d = 1; d <= daysInMonth; d++) {
            cells.push({ day: d, inMonth: true })
        }
        while (cells.length % 7 !== 0) {
            cells.push({ day: "", inMonth: false })
        }
        return cells
    }

    function shiftDate(delta) {
        if (!appState) {
            return
        }
        const current = new Date(appState.calendarDate)
        if (appState.calendarView === "year") {
            current.setFullYear(current.getFullYear() + delta)
        } else if (appState.calendarView === "month") {
            current.setMonth(current.getMonth() + delta)
        } else {
            current.setDate(current.getDate() + delta)
        }
        const iso = current.toISOString().slice(0, 10)
        appState.setCalendarDate(iso)
    }

    function selectedEvent() {
        const events = appState ? appState.calendarEvents : []
        for (let i = 0; i < events.length; i++) {
            const item = events[i]
            if (item.id === root.selectedEventId) {
                return item
            }
        }
        return null
    }

    function selectedEventTitle() {
        const item = selectedEvent()
        return item ? item.title : "Select an event"
    }

    function selectedEventTime() {
        const item = selectedEvent()
        if (!item) {
            return ""
        }
        return (item.start || "") + " → " + (item.end || "")
    }

    function selectedEventNotes() {
        const item = selectedEvent()
        return item ? (item.notes || "") : ""
    }

    function monthCells() {
        const base = new Date(appState ? appState.calendarDate : root.selectedDay)
        const year = base.getFullYear()
        const month = base.getMonth()
        const first = new Date(year, month, 1)
        const startDay = first.getDay()
        const daysInMonth = new Date(year, month + 1, 0).getDate()
        const cells = []
        for (let i = 0; i < startDay; i++) {
            cells.push({ day: "", inMonth: false, date: "", eventCount: 0 })
        }
        for (let d = 1; d <= daysInMonth; d++) {
            const dateObj = new Date(year, month, d)
            const dateStr = dateObj.toISOString().slice(0, 10)
            cells.push({
                day: d,
                inMonth: true,
                date: dateStr,
                eventCount: eventsForDate(dateStr).length
            })
        }
        while (cells.length % 7 !== 0) {
            cells.push({ day: "", inMonth: false, date: "", eventCount: 0 })
        }
        return cells
    }

    function eventsForDate(dateStr) {
        const list = []
        const events = appState ? appState.calendarEvents : []
        for (let i = 0; i < events.length; i++) {
            const item = events[i]
            if (!item.start) {
                continue
            }
            const start = item.start.toString().slice(0, 10)
            if (start === dateStr) {
                list.push(item)
            }
        }
        return list
    }

    function eventsForSelectedDay() {
        return eventsForDate(root.selectedDay)
    }

    function allDayEventsForSelectedDay() {
        const list = eventsForDate(root.selectedDay)
        const results = []
        for (let i = 0; i < list.length; i++) {
            const item = list[i]
            if (item.all_day) {
                results.push(item)
                continue
            }
            if (!item.start) {
                continue
            }
            if (item.start.toString().length <= 10) {
                results.push(item)
            }
        }
        return results
    }

    function openEditEvent() {
        const item = selectedEvent()
        if (!item) {
            return
        }
        editTitleField.text = item.title || ""
        editNotesField.text = item.notes || ""
        editStartDateTime = parseEventDate(item.start)
        editEndDateTime = parseEventDate(item.end)
        editAllDay = !!item.all_day
        editCalendarIndex = -1
        if (!appState) {
            return
        }
        for (let i = 0; i < appState.calendarAvailableCalendars.length; i++) {
            if (appState.calendarAvailableCalendars[i].id === item.calendar_id) {
                editCalendarIndex = i
                break
            }
        }
        editEventPopup.open()
    }

    Component.onCompleted: {
        appState.refreshCalendarEvents()
        root.selectedDay = appState.calendarDate
        allDayItems = allDayEventsForSelectedDay()
    }

    Connections {
        target: appState
        function onCalendarDateChanged() {
            root.selectedDay = appState.calendarDate
            allDayItems = allDayEventsForSelectedDay()
        }
        function onCalendarSourcesChanged() {
            if (eventCalendarIndex < 0 && appState && appState.calendarAvailableCalendars.length > 0) {
                eventCalendarIndex = 0
            }
        }
        function onCalendarEventsChanged() {
            allDayItems = allDayEventsForSelectedDay()
        }
    }
}
