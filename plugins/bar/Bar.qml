import QtQuick
import Quickshell
import "modules"
import "../../Commons"
import "../../Commons" as Commons

Item {
    id: root

    property var layout: ({
        left: [
            { id: "launcher" },
            { id: "workspace" },
        ],
        center: [
            { id: "clock" },
            { id: "media" },
        ],
        right: [
            { id: "volume" },
            { id: "brightness" },
            { id: "network" },
            { id: "bluetooth" },
            { id: "system" },
            { id: "battery" },
            { id: "tray" },
            // { id: "clipboard" },
            { id: "desktop" },
        ]
    })

    // Stand-in for BarWidgetRegistry.widgets[id].component.
    function moduleFor(id) {
        if (id === "launcher") return launcherComponent
        if (id === "workspace") return workspaceComponent
        if (id === "clock") return clockComponent
        if (id === "media") return mediaComponent
        if (id === "volume") return volumeComponent
        if (id === "brightness") return brightnessComponent
        if (id === "network") return networkComponent
        if (id === "bluetooth") return bluetoothComponent
        if (id === "battery") return batteryComponent
        if (id === "system") return systemComponent
        if (id === "tray") return trayComponent
        // if (id === "clipboard") return clipboardComponent
        if (id === "desktop") return desktopComponent
        return null
    }

    Component { id: launcherComponent; Launcher {} }
    Component { id: workspaceComponent; Workspace {} }
    Component { id: clockComponent; Clock {} }

    Component { id: mediaComponent; Media {} }
    Component { id: volumeComponent; Volume {} }
    Component { id: brightnessComponent; Brightness {} }
    Component { id: networkComponent; Network {} }
    Component { id: bluetoothComponent; Bluetooth {} }
    Component { id: batteryComponent; Battery {} }
    Component { id: systemComponent; System {} }
    Component { id: trayComponent; Tray {} }
    // Component { id: clipboardComponent; Clipboard {} }
    Component { id: desktopComponent; Desktop {} }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            readonly property string screenOutput: modelData.name
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: Style.bar.height
            color: Commons.Color.background

            Item {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 14
                    Repeater {
                        model: root.layout.left
                        delegate: Loader {
                            required property var modelData
                            sourceComponent: root.moduleFor(modelData.id)
                            onLoaded: if (item && "outputName" in item) item.outputName = screenOutput
                        }
                    }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 14
                    Repeater {
                        model: root.layout.center
                        delegate: Loader {
                            required property var modelData
                            sourceComponent: root.moduleFor(modelData.id)
                            onLoaded: if (item && "outputName" in item) item.outputName = screenOutput
                        }
                    }
                }


                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
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