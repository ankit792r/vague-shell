import QtQuick
import Quickshell
import "../../../Commons"
import "../../../Ui"

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

    BarButton {
        id: icon
        icon: ""
        onClicked: root.opened = !root.opened
    }

    Loader {
        active: root.opened
        sourceComponent: PanelPopup {
            anchorItem: icon
            panelNamespace: "desktop-panel"
            cardWidth: 440
            cardSpacing: 10
            onDismissed: root.opened = false

                        IconText {
                            text: "Session"
                            size: Style.font.heading
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

                                        IconText {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: modelData.icon
                                            color: modelData.label === "Power off" ? Color.urgent : Color.text
                                            size: Style.font.iconLarge
                                        }

                                        IconText {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: modelData.label
                                            color: modelData.label === "Power off" ? Color.urgent : Color.text
                                            size: Style.font.caption
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

                                    IconText {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "󰂛"
                                        size: Style.font.heading
                                    }

                                    IconText {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "DND"
                                        size: Style.font.body
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

                                    IconText {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "󰖔"
                                        color: root.nightLight ? Color.warning : Color.text
                                        size: Style.font.heading
                                    }

                                    IconText {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "Night light"
                                        color: root.nightLight ? Color.warning : Color.text
                                        size: Style.font.body
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