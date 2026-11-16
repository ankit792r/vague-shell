import QtQuick
import Quickshell
import "../../../Commons"
import "../../../Commons" as Commons
import "../../../Ui"

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

    BarButton {
        id: label
        label: Qt.formatDateTime(clock.date, "ddd HH:mm")
        onClicked: root.opened = !root.opened
        onWheeled: function (delta) { if (root.opened) root.moveMonth(delta > 0 ? -1 : 1) }
    }

    Loader {
        active: root.opened
        sourceComponent: PanelPopup {
            anchorItem: label
            panelNamespace: "clock-panel"
            cardWidth: 308
            cardSpacing: 12
            onDismissed: root.opened = false
            onWheeled: function (delta) { root.moveMonth(delta > 0 ? -1 : 1) }

                        Item {
                            width: parent.width
                            height: 24

                            IconText {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: "‹"
                                size: Style.font.iconLarge

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: root.moveMonth(-1)
                                }
                            }

                            IconText {
                                anchors.centerIn: parent
                                text: new Date(root.viewYear, root.viewMonth, 1).toLocaleString(Qt.locale(), "MMMM yyyy")
                                size: Style.font.heading
                                font.bold: true
                            }

                            IconText {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: "›"
                                size: Style.font.iconLarge

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

                                delegate: IconText {
                                    required property string modelData
                                    width: 36
                                    height: 18
                                    text: modelData
                                    color: Commons.Color.muted
                                    size: Style.font.caption
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
                                    color: modelData > 0 && root.isToday(modelData) ? Commons.Color.text : "transparent"

                                    IconText {
                                        anchors.centerIn: parent
                                        visible: modelData > 0
                                        text: modelData
                                        color: root.isToday(modelData) ? Commons.Color.background : Commons.Color.text
                                        size: Style.font.body
                                    }
                                }
                            }
                        }
        }
    }
}