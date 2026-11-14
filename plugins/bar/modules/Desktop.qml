import QtQuick
import Quickshell
import Quickshell.Wayland

Item {
    id: root

    property bool opened: false
    property bool dnd: false
    property bool nightLight: false

    implicitWidth: icon.width
    implicitHeight: 32

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
        color: "#cdd6f4"
        font.family: "Iosevka Nerd Font"
        font.pixelSize: 16
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

                    width: 360
                    height: column.implicitHeight + 28
                    color: "#1e1e2e"
                    border.color: "#45475a"
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
                            color: "#cdd6f4"
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: 16
                            font.bold: true
                        }

                        Row {
                            width: parent.width
                            spacing: 8

                            Repeater {
                                model: [
                                    { icon: "󰍃", label: "Log out", command: ["niri", "msg", "action", "quit"] },
                                    { icon: "󰒲", label: "Suspend", command: ["systemctl", "suspend"] },
                                    { icon: "󰜉", label: "Reboot", command: ["systemctl", "reboot"] },
                                    { icon: "󰐥", label: "Power off", command: ["systemctl", "poweroff"] }
                                ]

                                delegate: Rectangle {
                                    required property var modelData
                                    width: (parent.width - 24) / 4
                                    height: 64
                                    color: actionMouse.containsMouse ? "#313244" : "transparent"
                                    border.color: modelData.label === "Power off" ? "#f38ba8" : "#45475a"
                                    border.width: 1

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 4

                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: modelData.icon
                                            color: modelData.label === "Power off" ? "#f38ba8" : "#cdd6f4"
                                            font.family: "Iosevka Nerd Font"
                                            font.pixelSize: 18
                                        }

                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: modelData.label
                                            color: modelData.label === "Power off" ? "#f38ba8" : "#cdd6f4"
                                            font.family: "Iosevka Nerd Font"
                                            font.pixelSize: 11
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
                                color: root.dnd ? "#313244" : "transparent"
                                border.color: root.dnd ? "#cdd6f4" : "#45475a"
                                border.width: 1

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 8

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "󰂛"
                                        color: "#cdd6f4"
                                        font.family: "Iosevka Nerd Font"
                                        font.pixelSize: 16
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "DND"
                                        color: "#cdd6f4"
                                        font.family: "Iosevka Nerd Font"
                                        font.pixelSize: 13
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
                                color: root.nightLight ? "#313244" : "transparent"
                                border.color: root.nightLight ? "#f9e2af" : "#45475a"
                                border.width: 1

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 8

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "󰖔"
                                        color: root.nightLight ? "#f9e2af" : "#cdd6f4"
                                        font.family: "Iosevka Nerd Font"
                                        font.pixelSize: 16
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "Night light"
                                        color: root.nightLight ? "#f9e2af" : "#cdd6f4"
                                        font.family: "Iosevka Nerd Font"
                                        font.pixelSize: 13
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