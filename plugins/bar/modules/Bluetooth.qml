import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Wayland

Item {
    id: root

    property bool opened: false
    property var connectedNames: []
    property var rows: []

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool radioOn: adapter ? adapter.enabled : false
    readonly property int connectedCount: connectedNames.length
    readonly property string name: {
        if (!adapter) return "No adapter"
        if (!radioOn) return "Off"
        return connectedNames.length > 0 ? connectedNames.join(", ") : "On"
    }
    readonly property string statusLine: {
        if (!adapter) return "NO ADAPTER"
        return radioOn ? "ON" : "OFF"
    }

    implicitWidth: row.implicitWidth
    implicitHeight: 32

    onOpenedChanged: {
        refresh()
        if (!adapter) return
        adapter.discovering = opened && radioOn
    }

    function human(label) {
        if (!label) return false
        return !/^([0-9a-f]{2}[:-]){5}[0-9a-f]{2}$/i.test(label)
    }

    function refresh() {
        var values = Bluetooth.devices ? Bluetooth.devices.values : []
        var names = []
        var next = []
        for (var i = 0; i < values.length; i++) {
            var device = values[i]
            if (!device) continue
            var label = String(device.deviceName || device.name || "").trim()
            if (!human(label)) continue
            var connected = !!device.connected
            var known = !!(device.paired || device.bonded || device.trusted)
            if (connected) names.push(label)
            next.push({
                address: String(device.address || ""),
                name: label,
                connected: connected,
                section: connected ? "connected" : (known ? "known" : "available"),
                battery: device.batteryAvailable ? Math.round(device.battery * 100) : -1
            })
        }
        var order = { connected: 0, known: 1, available: 2 }
        next.sort(function (a, b) {
            if (order[a.section] !== order[b.section]) return order[a.section] - order[b.section]
            return a.name.localeCompare(b.name)
        })
        connectedNames = names
        rows = opened ? next : []
    }

    function liveDevice(address) {
        var values = Bluetooth.devices ? Bluetooth.devices.values : []
        for (var i = 0; i < values.length; i++) {
            if (values[i] && String(values[i].address) === address) return values[i]
        }
        return null
    }

    function toggleRadio() {
        if (!root.adapter) return
        Quickshell.execDetached(["rfkill", root.adapter.enabled ? "block" : "unblock", "bluetooth"])
    }

    function activate(address) {
        var device = liveDevice(address)
        if (!device) return
        if (device.connected) device.disconnect()
        else if (device.paired || device.bonded || device.trusted) device.connect()
        else device.pair()
    }

    function sectionTitle(section) {
        if (section === "connected") return "CONNECTED"
        if (section === "known") return "PAIRED"
        return "AVAILABLE"
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: !root.radioOn ? "󰂲" : (root.connectedCount > 0 ? "󰂱" : "󰂯")
            color: "#cdd6f4"
            font.family: "Iosevka Nerd Font"
            font.pixelSize: 16
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 160)
            elide: Text.ElideRight
            text: root.name
            color: "#cdd6f4"
            font.family: "Iosevka Nerd Font"
            font.pixelSize: 16
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        // onClicked: root.toggleRadio()
        onClicked: function (mouse) {
            if (mouse.button === Qt.RightButton) root.toggleRadio()
            else root.opened = !root.opened
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
                WlrLayershell.namespace: "bluetooth-panel"
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
                    color: "#1e1e2e"
                    border.color: "#45475a"
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
                        spacing: 12

                        Item {
                            width: parent.width
                            height: 42

                            Text {
                                id: heroIcon
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: !root.radioOn ? "󰂲" : (root.connectedCount > 0 ? "󰂱" : "󰂯")
                                color: "#cdd6f4"
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: 28
                                opacity: root.radioOn ? 1 : 0.5
                            }

                            Column {
                                anchors.left: heroIcon.right
                                anchors.leftMargin: 14
                                anchors.right: power.left
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Text {
                                    width: parent.width
                                    text: "Bluetooth"
                                    color: "#cdd6f4"
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: 16
                                    font.bold: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width
                                    text: root.statusLine
                                    color: "#7f849c"
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: 11
                                    font.bold: true
                                    font.letterSpacing: 1.2
                                    elide: Text.ElideRight
                                }
                            }

                            Rectangle {
                                id: power
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 36
                                height: 20
                                color: root.radioOn ? "#a6e3a1" : "#45475a"
                                visible: root.adapter !== null

                                Rectangle {
                                    width: 16
                                    height: 16
                                    color: "#1e1e2e"
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: root.radioOn ? parent.width - width - 2 : 2
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: root.toggleRadio()
                                }
                            }
                        }

                        Text {
                            visible: root.rows.length === 0
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: !root.adapter ? "No Bluetooth adapter" : (!root.radioOn ? "Turn Bluetooth on to scan" : "Scanning")
                            color: "#7f849c"
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: 13
                        }

                        ListView {
                            visible: root.rows.length > 0
                            width: parent.width
                            height: Math.min(contentHeight, 280)
                            clip: true
                            spacing: 2
                            boundsBehavior: Flickable.StopAtBounds
                            model: root.rows

                            delegate: Item {
                                required property var modelData
                                required property int index

                                readonly property bool showHeader: index === 0 || root.rows[index - 1].section !== modelData.section

                                width: ListView.view.width
                                height: (showHeader ? 22 : 0) + (modelData.connected ? 44 : 36)

                                Text {
                                    visible: showHeader
                                    text: root.sectionTitle(modelData.section)
                                    color: "#7f849c"
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: 11
                                    font.bold: true
                                    font.letterSpacing: 1.2
                                }

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    height: modelData.connected ? 44 : 36
                                    radius: 8
                                    color: rowMouse.containsMouse ? "#313244" : "transparent"

                                    Row {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        spacing: 10

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 22
                                            text: "󰂯"
                                            color: modelData.connected ? "#cdd6f4" : "#7f849c"
                                            font.family: "Iosevka Nerd Font"
                                            font.pixelSize: 16
                                            horizontalAlignment: Text.AlignHCenter
                                        }

                                        Column {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: parent.width - 22 - parent.spacing
                                            spacing: 1

                                            Text {
                                                width: parent.width
                                                text: modelData.name
                                                color: "#cdd6f4"
                                                font.family: "Iosevka Nerd Font"
                                                font.pixelSize: 14
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                visible: modelData.connected
                                                width: parent.width
                                                text: modelData.battery >= 0 ? ("Connected · " + modelData.battery + "%") : "Connected"
                                                color: "#a6adc8"
                                                font.family: "Iosevka Nerd Font"
                                                font.pixelSize: 11
                                                elide: Text.ElideRight
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: rowMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.activate(modelData.address)
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
                    WlrLayershell.namespace: "bluetooth-panel-dismiss"
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