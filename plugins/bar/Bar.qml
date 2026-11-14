import QtQuick
import QtQuick.Layouts
import Quickshell
import "modules"

Item {
    id: root

    property var layout: ({
        left: [],
        center: [],
        right: [
            { id: "volume" },
            { id: "brightness" },
            { id: "network" },
            { id: "bluetooth" },
            { id: "system" },
            { id: "battery" },
            { id: "tray" },
            { id: "desktop" },
        ]
    })

    // Stand-in for BarWidgetRegistry.widgets[id].component.
    function moduleFor(id) {
        if (id === "volume") return volumeComponent
        if (id === "brightness") return brightnessComponent
        if (id === "network") return networkComponent
        if (id === "bluetooth") return bluetoothComponent
        if (id === "battery") return batteryComponent
        if (id === "system") return systemComponent
        if (id === "tray") return trayComponent
        if (id === "desktop") return desktopComponent
        return null
    }

    Component { id: volumeComponent; Volume {} }
    Component { id: brightnessComponent; Brightness {} }
    Component { id: networkComponent; Network {} }
    Component { id: bluetoothComponent; Bluetooth {} }
    Component { id: batteryComponent; Battery {} }
    Component { id: systemComponent; System {} }
    Component { id: trayComponent; Tray {} }
    Component { id: desktopComponent; Desktop {} }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: 32
            color: "#1e1e2e"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8

                Text {
                    text: "workspaces"
                    color: "#cdd6f4"
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 16
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: Qt.formatDateTime(clock.date, "ddd HH:mm")
                    color: "#cdd6f4"
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 16
                }

                Item { Layout.fillWidth: true }

                Row {
                    spacing: 14

                    Repeater {
                        model: root.layout.right

                        delegate: Loader {
                            required property var modelData
                            sourceComponent: root.moduleFor(modelData.id)
                        }
                    }
                }
            }
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}