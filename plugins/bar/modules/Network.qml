import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Wayland

Item {
    id: root

    property string kind: "offline"
    property string name: ""
    property bool opened: false
    property string passwordFor: ""
    property string passwordText: ""
    property var networks: []

    readonly property string statusLine: {
        if (!Networking.wifiEnabled && kind !== "ethernet") return "WI-FI OFF"
        if (kind === "ethernet") return "ETHERNET"
        if (kind === "wifi") return "CONNECTED"
        return "NOT CONNECTED"
    }

    implicitWidth: row.implicitWidth
    implicitHeight: 32

    onOpenedChanged: {
        if (!opened) {
            passwordFor = ""
            passwordText = ""
            networks = []
        } else {
            refreshNetworks()
        }
    }

    function bars(signal) {
        if (signal >= 80) return "󰤨"
        if (signal >= 55) return "󰤥"
        if (signal >= 30) return "󰤢"
        return "󰤟"
    }

    function secured(network) {
        return network.security !== WifiSecurityType.Open && network.security !== WifiSecurityType.Owe
    }

    function wifiDevice() {
        var devices = Networking.devices ? Networking.devices.values : []
        var fallback = null
        for (var i = 0; i < devices.length; i++) {
            var device = devices[i]
            if (!device || device.type !== DeviceType.Wifi) continue
            if (device.connected) return device
            if (!fallback) fallback = device
        }
        return fallback
    }

    function refreshNetworks() {
        var device = wifiDevice()
        if (device) device.scannerEnabled = opened
        var values = device && device.networks ? device.networks.values : []
        var rows = []
        for (var i = 0; i < values.length; i++) {
            var network = values[i]
            if (!network || !network.name) continue
            rows.push({
                ssid: String(network.name),
                connected: !!network.connected,
                known: !!network.known,
                secure: secured(network),
                signal: Math.round((network.signalStrength || 0) * 100)
            })
        }
        rows.sort(function (a, b) {
            if (a.connected !== b.connected) return a.connected ? -1 : 1
            return b.signal - a.signal
        })
        networks = rows
    }

    function liveNetwork(ssid) {
        var device = wifiDevice()
        var values = device && device.networks ? device.networks.values : []
        for (var i = 0; i < values.length; i++) {
            if (values[i] && String(values[i].name) === ssid) return values[i]
        }
        return null
    }

    function activate(ssid) {
        var network = liveNetwork(ssid)
        if (!network) return
        if (network.connected) {
            network.disconnect()
            return
        }
        if (network.known || !secured(network)) {
            passwordFor = ""
            network.connect()
            return
        }
        passwordFor = ssid
        passwordText = ""
    }

    function parse(raw) {
        var ethernet = ""
        var wifiName = ""
        var lines = String(raw || "").trim().split("\n")
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i]
            var first = line.indexOf(":")
            var second = line.indexOf(":", first + 1)
            if (first < 0 || second < 0) continue
            var type = line.slice(0, first)
            var state = line.slice(first + 1, second)
            var connection = line.slice(second + 1).replace(/\\:/g, ":")
            if (state !== "connected" || connection === "") continue
            if (type === "ethernet") ethernet = connection
            if (type === "wifi") wifiName = connection
        }
        if (ethernet !== "") {
            kind = "ethernet"
            name = ethernet
        } else if (wifiName !== "") {
            kind = "wifi"
            name = wifiName
        } else {
            kind = "offline"
            name = "offline"
        }
    }

    Process {
        id: poll
        command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "device", "status"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: poll.running = true
    }

    Timer {
        interval: 2000
        running: root.opened
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshNetworks()
    }

    Process {
        id: connectWithPassword
        command: ["nmcli", "device", "wifi", "connect", root.passwordFor, "password", root.passwordText]
        onExited: function (code) {
            if (code === 0) {
                root.passwordFor = ""
                root.passwordText = ""
                root.refreshNetworks()
            }
        }
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.kind === "ethernet" ? "󰈀" : (root.kind === "wifi" ? "󰤨" : "󰤮")
            color: "#cdd6f4"
            font.family: "Iosevka Nerd Font"
            font.pixelSize: 16
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 200)
            elide: Text.ElideRight
            text: root.name
            color: "#cdd6f4"
            font.family: "Iosevka Nerd Font"
            font.pixelSize: 16
        }
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

                screen: row.QsWindow.window ? row.QsWindow.window.screen : null
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                aboveWindows: true
                focusable: true
                WlrLayershell.namespace: "network-panel"
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
                    // radius: 18
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
                                text: root.kind === "ethernet" ? "󰈀" : (Networking.wifiEnabled ? "󰤨" : "󰤮")
                                color: "#cdd6f4"
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: 28
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
                                    text: root.name
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
                                // radius: 10
                                color: Networking.wifiEnabled ? "#a6e3a1" : "#45475a"

                                Rectangle {
                                    width: 16
                                    height: 16
                                    // radius: 8
                                    color: "#1e1e2e"
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: Networking.wifiEnabled ? parent.width - width - 2 : 2
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                                }
                            }
                        }

                        TextField {
                            visible: root.passwordFor !== ""
                            width: parent.width
                            placeholderText: "Password for " + root.passwordFor
                            echoMode: TextInput.Password
                            text: root.passwordText
                            color: "#cdd6f4"
                            font.family: "Iosevka Nerd Font"
                            onTextChanged: root.passwordText = text
                            onAccepted: if (root.passwordText !== "") connectWithPassword.running = true
                        }

                        Text {
                            text: "WI-FI"
                            color: "#7f849c"
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: 11
                            font.bold: true
                            font.letterSpacing: 1.2
                        }

                        ListView {
                            width: parent.width
                            height: Math.min(contentHeight, 280)
                            clip: true
                            spacing: 2
                            boundsBehavior: Flickable.StopAtBounds
                            model: root.networks

                            delegate: Rectangle {
                                required property var modelData
                                width: ListView.view.width
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
                                        text: root.bars(modelData.signal)
                                        color: modelData.connected ? "#cdd6f4" : "#7f849c"
                                        font.family: "Iosevka Nerd Font"
                                        font.pixelSize: 16
                                        horizontalAlignment: Text.AlignHCenter
                                    }

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width - 22 - lockGlyph.width - parent.spacing * 2
                                        spacing: 1

                                        Text {
                                            width: parent.width
                                            text: modelData.ssid
                                            color: "#cdd6f4"
                                            font.family: "Iosevka Nerd Font"
                                            font.pixelSize: 14
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            visible: modelData.connected
                                            width: parent.width
                                            text: "Connected"
                                            color: "#a6adc8"
                                            font.family: "Iosevka Nerd Font"
                                            font.pixelSize: 11
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Text {
                                        id: lockGlyph
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.secure ? "󰌾" : ""
                                        color: "#7f849c"
                                        font.family: "Iosevka Nerd Font"
                                        font.pixelSize: 14
                                    }
                                }

                                MouseArea {
                                    id: rowMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.activate(modelData.ssid)
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
                    WlrLayershell.namespace: "network-panel-dismiss"
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