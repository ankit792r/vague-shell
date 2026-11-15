import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../../Commons"

Item {
    id: root

    property bool opened: false
    property bool dnd: false
    property bool nightLight: false

    implicitWidth: icon.width
    implicitHeight: Style.bar.height

    function run(command) {
        Quickshell.execDetached(command)
        opened = false
    }

    Text {
        id: icon
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(implicitWidth, 18)
        height: 32
        text: ""
        color: Color.text
        font.family: Style.font.family
        font.pixelSize: Style.font.heading
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.opened = !root.opened
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

                screen: icon.QsWindow.window ? icon.QsWindow.window.screen : null
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                aboveWindows: true
                focusable: true
                WlrLayershell.namespace: "desktop-panel"
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
                        var window = icon.QsWindow.window
                        if (!window) return Qt.point(8, 40)
                        return icon.mapToItem(window.contentItem, 0, 0)
                    }

                    width: 440
                    height: column.implicitHeight + 28
                    color: Color.background
                    border.color: Color.border
                    border.width: 2
                    x: Math.max(8, Math.min(anchor.x + icon.width / 2 - width / 2, screenW - width - 8))
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
                        spacing: 10

                        Text {
                            text: "Session"
                            color: Color.text
                            font.family: Style.font.family
                            font.pixelSize: Style.font.heading
                            font.bold: true
                        }

                        Row {
                            width: parent.width
                            spacing: 8

                            Repeater {
                                model: [
                                    { icon: "󰌾", label: "Lock", command: ["qs", "ipc", "call", "lock", "lock"] },
                                    { icon: "󰍃", label: "Log out", command: ["niri", "msg", "action", "quit"] },
                                    { icon: "󰒲", label: "Suspend", command: ["systemctl", "suspend"] },
                                    { icon: "󰜉", label: "Reboot", command: ["systemctl", "reboot"] },
                                    { icon: "󰐥", label: "Power off", command: ["systemctl", "poweroff"] }
                                ]

                                delegate: Rectangle {
                                    required property var modelData
                                    width: (parent.width - 32) / 5
                                    height: 64
                                    color: actionMouse.containsMouse ? Color.surface : "transparent"
                                    border.color: modelData.label === "Power off" ? Color.urgent : Color.border
                                    border.width: 1

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 4

                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: modelData.icon
                                            color: modelData.label === "Power off" ? Color.urgent : Color.text
                                            font.family: Style.font.family
                                            font.pixelSize: Style.font.iconLarge
                                        }

                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: modelData.label
                                            color: modelData.label === "Power off" ? Color.urgent : Color.text
                                            font.family: Style.font.family
                                            font.pixelSize: Style.font.caption
                                        }
                                    }

                                    MouseArea {
                                        id: actionMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: root.run(modelData.command)
                                    }
                                }
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: 8

                            Rectangle {
                                width: (parent.width - 8) / 2
                                height: 40
                                color: root.dnd ? Color.surface : "transparent"
                                border.color: root.dnd ? Color.text : Color.border
                                border.width: 1

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 8

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "󰂛"
                                        color: Color.text
                                        font.family: Style.font.family
                                        font.pixelSize: Style.font.heading
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "DND"
                                        color: Color.text
                                        font.family: Style.font.family
                                        font.pixelSize: Style.font.body
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: root.dnd = !root.dnd
                                }
                            }

                            Rectangle {
                                width: (parent.width - 8) / 2
                                height: 40
                                color: root.nightLight ? Color.surface : "transparent"
                                border.color: root.nightLight ? Color.warning : Color.border
                                border.width: 1

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 8

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "󰖔"
                                        color: root.nightLight ? Color.warning : Color.text
                                        font.family: Style.font.family
                                        font.pixelSize: Style.font.heading
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "Night light"
                                        color: root.nightLight ? Color.warning : Color.text
                                        font.family: Style.font.family
                                        font.pixelSize: Style.font.body
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        root.nightLight = !root.nightLight
                                        Quickshell.execDetached(root.nightLight
                                            ? ["gammastep", "-m", "wayland", "-O", "4000"]
                                            : ["gammastep", "-x"])
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
                    WlrLayershell.namespace: "desktop-panel-dismiss"
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