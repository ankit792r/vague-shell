import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import "../../../Commons"
import "../../../Commons" as Commons
import "../../../Ui"

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
    implicitHeight: Style.bar.height

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

    BarButton {
        id: row
        icon: root.kind === "ethernet" ? "󰈀" : (root.kind === "wifi" ? "󰤨" : "󰤮")
        label: root.name
        labelMaxWidth: 200
        onClicked: root.opened = !root.opened
    }

    PopupLoader {
        open: root.opened
        sourceComponent: PanelPopup {
            open: root.opened
            anchorItem: row
            panelNamespace: "network-panel"
            cardWidth: 380
            cardSpacing: 12
            onDismissed: root.opened = false

                        PanelHero {
    icon: root.kind === "ethernet" ? "󰈀" : (Networking.wifiEnabled ? "󰤨" : "󰤮")
    title: root.name
    subtitle: root.statusLine
ToggleSwitch {
    id: power
    checked: Networking.wifiEnabled
    onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
}
}

                        TextField {
                            visible: root.passwordFor !== ""
                            width: parent.width
                            placeholderText: "Password for " + root.passwordFor
                            echoMode: TextInput.Password
                            text: root.passwordText
                            color: Commons.Color.text
                            font.family: Style.font.family
                            onTextChanged: root.passwordText = text
                            onAccepted: if (root.passwordText !== "") connectWithPassword.running = true
                        }

                        SectionLabel {
                            text: "WI-FI"
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
                                color: rowMouse.containsMouse ? Commons.Color.surface : "transparent"

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 10

                                    IconText {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 22
                                        text: root.bars(modelData.signal)
                                        color: modelData.connected ? Commons.Color.text : Commons.Color.muted
                                        size: Style.font.heading
                                        horizontalAlignment: Text.AlignHCenter
                                    }

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width - 22 - lockGlyph.width - parent.spacing * 2
                                        spacing: 1

                                        IconText {
                                            width: parent.width
                                            text: modelData.ssid
                                            size: Style.font.subtitle
                                            elide: Text.ElideRight
                                        }

                                        IconText {
                                            visible: modelData.connected
                                            width: parent.width
                                            text: "Connected"
                                            color: Commons.Color.subtext
                                            size: Style.font.caption
                                            elide: Text.ElideRight
                                        }
                                    }

                                    IconText {
                                        id: lockGlyph
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.secure ? "󰌾" : ""
                                        color: Commons.Color.muted
                                        size: Style.font.subtitle
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