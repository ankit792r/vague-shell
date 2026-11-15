import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../../Commons"

Item {
    id: root

    property bool opened: false
    property int viewYear: clock.date.getFullYear()
    property int viewMonth: clock.date.getMonth()

    readonly property var cells: {
        var first = new Date(viewYear, viewMonth, 1)
        var weekStart = Qt.locale().firstDayOfWeek % 7
        var pad = (first.getDay() - weekStart + 7) % 7
        var count = new Date(viewYear, viewMonth + 1, 0).getDate()
        var list = []
        for (var i = 0; i < pad; i++) list.push(0)
        for (var day = 1; day <= count; day++) list.push(day)
        while (list.length % 7 !== 0) list.push(0)
        return list
    }

    readonly property var weekdayLabels: {
        var locale = Qt.locale()
        var weekStart = locale.firstDayOfWeek % 7
        var names = []
        for (var i = 0; i < 7; i++) {
            var qtDay = (weekStart + i) % 7
            names.push(locale.dayName(qtDay === 0 ? 7 : qtDay, Locale.ShortFormat))
        }
        return names
    }

    implicitWidth: label.implicitWidth
    implicitHeight: Style.bar.height

    function isToday(day) {
        var now = clock.date
        return day === now.getDate() && viewMonth === now.getMonth() && viewYear === now.getFullYear()
    }

    function moveMonth(delta) {
        var next = new Date(viewYear, viewMonth + delta, 1)
        viewYear = next.getFullYear()
        viewMonth = next.getMonth()
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    onOpenedChanged: if (opened) {
        viewYear = clock.date.getFullYear()
        viewMonth = clock.date.getMonth()
    }

    Text {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatDateTime(clock.date, "ddd HH:mm")
        color: Color.text
        font.family: Style.font.family
        font.pixelSize: Style.font.heading
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.opened = !root.opened
        onWheel: function (wheel) {
            if (root.opened) root.moveMonth(wheel.angleDelta.y > 0 ? -1 : 1)
        }
    }

    Loader {
        active: root.opened
        sourceComponent: panelComponent
    }

    Component {
        id: panelComponent

        Item {
            PanelWindow {
                id: overlay

                screen: label.QsWindow.window ? label.QsWindow.window.screen : null
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                aboveWindows: true
                focusable: true
                WlrLayershell.namespace: "clock-panel"
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

                anchors {
                    top: true
                    bottom: true
                    left: true
                    right: true
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.AllButtons
                    onClicked: root.opened = false
                    onWheel: function (wheel) { root.moveMonth(wheel.angleDelta.y > 0 ? -1 : 1) }
                }

                Rectangle {
                    id: card

                    readonly property real screenW: overlay.screen ? overlay.screen.width : 1920
                    readonly property point anchor: {
                        var window = label.QsWindow.window
                        if (!window) return Qt.point(8, 40)
                        return label.mapToItem(window.contentItem, 0, 0)
                    }

                    width: 308
                    height: column.implicitHeight + 28
                    color: Color.background
                    border.color: Color.border
                    border.width: 2
                    x: Math.max(8, Math.min(anchor.x + label.width / 2 - width / 2, screenW - width - 8))
                    y: 40

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.AllButtons
                        onWheel: function (wheel) { root.moveMonth(wheel.angleDelta.y > 0 ? -1 : 1) }
                    }

                    Column {
                        id: column
                        z: 1
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 14
                        spacing: 12

                        Item {
                            width: parent.width
                            height: 24

                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: "‹"
                                color: Color.text
                                font.family: Style.font.family
                                font.pixelSize: Style.font.iconLarge

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: root.moveMonth(-1)
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: new Date(root.viewYear, root.viewMonth, 1).toLocaleString(Qt.locale(), "MMMM yyyy")
                                color: Color.text
                                font.family: Style.font.family
                                font.pixelSize: Style.font.heading
                                font.bold: true
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: "›"
                                color: Color.text
                                font.family: Style.font.family
                                font.pixelSize: Style.font.iconLarge

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: root.moveMonth(1)
                                }
                            }
                        }

                        Grid {
                            columns: 7
                            columnSpacing: 4
                            rowSpacing: 4

                            Repeater {
                                model: root.weekdayLabels

                                delegate: Text {
                                    required property string modelData
                                    width: 36
                                    height: 18
                                    text: modelData
                                    color: Color.muted
                                    font.family: Style.font.family
                                    font.pixelSize: Style.font.caption
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }

                        Grid {
                            columns: 7
                            columnSpacing: 4
                            rowSpacing: 4

                            Repeater {
                                model: root.cells

                                delegate: Rectangle {
                                    required property int modelData
                                    width: 36
                                    height: 28
                                    color: modelData > 0 && root.isToday(modelData) ? Color.text : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        visible: modelData > 0
                                        text: modelData
                                        color: root.isToday(modelData) ? Color.background : Color.text
                                        font.family: Style.font.family
                                        font.pixelSize: Style.font.body
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Variants {
                model: Quickshell.screens

                delegate: PanelWindow {
                    required property var modelData

                    screen: modelData
                    visible: overlay.screen && modelData.name !== overlay.screen.name
                    color: "transparent"
                    exclusionMode: ExclusionMode.Ignore
                    WlrLayershell.namespace: "clock-panel-dismiss"
                    WlrLayershell.layer: WlrLayer.Overlay
                    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

                    anchors {
                        top: true
                        bottom: true
                        left: true
                        right: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.opened = false
                    }
                }
            }
        }
    }
}