import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../../Commons"

Item {
    id: root

    property bool opened: false
    property int brightness: 0
    property int brightnessMax: 1

    readonly property string backlight: "/sys/class/backlight/intel_backlight"
    readonly property int percent: brightnessMax > 0 ? Math.round(brightness * 100 / brightnessMax) : 0

    implicitWidth: row.implicitWidth
    implicitHeight: Style.bar.height

    function setBrightness(nextPercent) {
        var clamped = Math.max(0, Math.min(100, Math.round(nextPercent)))
        brightness = Math.round(brightnessMax * clamped / 100)
        Quickshell.execDetached(["brightnessctl", "set", clamped + "%"])
    }

    Process {
        id: brightnessRead
        command: ["cat", root.backlight + "/brightness"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.brightness = parseInt(text, 10) || 0
        }
    }

    Process {
        id: brightnessMaxRead
        command: ["cat", root.backlight + "/max_brightness"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.brightnessMax = parseInt(text, 10) || 1
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            brightnessRead.running = true
            brightnessMaxRead.running = true
        }
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "󰃠"
            color: Color.text
            font.family: Style.font.family
            font.pixelSize: Style.font.heading
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.percent + "%"
            color: Color.text
            font.family: Style.font.family
            font.pixelSize: Style.font.heading
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.opened = !root.opened
        onWheel: function (wheel) {
            root.setBrightness(root.percent + (wheel.angleDelta.y > 0 ? 5 : -5))
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

                screen: row.QsWindow.window ? row.QsWindow.window.screen : null
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                aboveWindows: true
                focusable: true
                WlrLayershell.namespace: "brightness-panel"
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
                }

                Rectangle {
                    id: card

                    readonly property real screenW: overlay.screen ? overlay.screen.width : 1920
                    readonly property point anchor: {
                        var window = row.QsWindow.window
                        if (!window) return Qt.point(8, 40)
                        return row.mapToItem(window.contentItem, 0, 0)
                    }

                    width: 380
                    height: column.implicitHeight + 28
                    color: Color.background
                    border.color: Color.border
                    border.width: 2
                    x: Math.max(8, Math.min(anchor.x + row.width / 2 - width / 2, screenW - width - 8))
                    y: 40

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.AllButtons
                    }

                    Column {
                        id: column
                        z: 1
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 14
                        spacing: 14

                        Item {
                            width: parent.width
                            height: 42

                            Text {
                                id: heroIcon
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: "󰃠"
                                color: Color.text
                                font.family: Style.font.family
                                font.pixelSize: Style.font.displayLarge
                            }

                            Column {
                                anchors.left: heroIcon.right
                                anchors.leftMargin: 14
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Text {
                                    width: parent.width
                                    text: "Built-in display"
                                    color: Color.text
                                    font.family: Style.font.family
                                    font.pixelSize: Style.font.heading
                                    font.bold: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width
                                    text: "INTEL_BACKLIGHT"
                                    color: Color.muted
                                    font.family: Style.font.family
                                    font.pixelSize: Style.font.caption
                                    font.bold: true
                                    font.letterSpacing: 1.2
                                }
                            }
                        }

                        Item {
                            width: parent.width
                            height: 18

                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: "BRIGHTNESS"
                                color: Color.muted
                                font.family: Style.font.family
                                font.pixelSize: Style.font.caption
                                font.bold: true
                                font.letterSpacing: 1.2
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.percent + "%"
                                color: Color.text
                                font.family: Style.font.family
                                font.pixelSize: Style.font.body
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 18
                            color: "transparent"

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                height: 6
                                color: Color.surface

                                Rectangle {
                                    width: parent.width * root.percent / 100
                                    height: parent.height
                                    color: Color.warning
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onPressed: function (mouse) { root.setBrightness(mouse.x / width * 100) }
                                onPositionChanged: function (mouse) { if (pressed) root.setBrightness(mouse.x / width * 100) }
                            }
                        }

                        Column {
                            width: parent.width
                            spacing: 8

                            Item {
                                width: parent.width
                                height: 16

                                Text {
                                    text: "CURRENT"
                                    color: Color.muted
                                    font.family: Style.font.family
                                    font.pixelSize: Style.font.caption
                                    font.bold: true
                                    font.letterSpacing: 1.2
                                }

                                Text {
                                    anchors.right: parent.right
                                    text: root.brightness
                                    color: Color.text
                                    font.family: Style.font.family
                                    font.pixelSize: Style.font.body
                                }
                            }

                            Item {
                                width: parent.width
                                height: 16

                                Text {
                                    text: "MAXIMUM"
                                    color: Color.muted
                                    font.family: Style.font.family
                                    font.pixelSize: Style.font.caption
                                    font.bold: true
                                    font.letterSpacing: 1.2
                                }

                                Text {
                                    anchors.right: parent.right
                                    text: root.brightnessMax
                                    color: Color.text
                                    font.family: Style.font.family
                                    font.pixelSize: Style.font.body
                                }
                            }

                            Item {
                                width: parent.width
                                height: 16

                                Text {
                                    text: "DEVICE"
                                    color: Color.muted
                                    font.family: Style.font.family
                                    font.pixelSize: Style.font.caption
                                    font.bold: true
                                    font.letterSpacing: 1.2
                                }

                                Text {
                                    anchors.right: parent.right
                                    text: "intel_backlight"
                                    color: Color.text
                                    font.family: Style.font.family
                                    font.pixelSize: Style.font.body
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
                    WlrLayershell.namespace: "brightness-panel-dismiss"
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
