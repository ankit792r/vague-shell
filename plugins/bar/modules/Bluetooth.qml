import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "../../../Commons"
import "../../../Commons" as Commons
import "../../../Ui"

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
    implicitHeight: Style.bar.height

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

    BarButton {
        id: row
        icon: !root.radioOn ? "󰂲" : (root.connectedCount > 0 ? "󰂱" : "󰂯")
        label: root.name
        labelMaxWidth: 160
        onClicked: root.opened = !root.opened
        onRightClicked: root.toggleRadio()
    }

    PopupLoader {
        open: root.opened
        sourceComponent: PanelPopup {
            open: root.opened
            anchorItem: row
            panelNamespace: "bluetooth-panel"
            cardWidth: 380
            cardSpacing: 12
            onDismissed: root.opened = false

                        PanelHero {
    icon: !root.radioOn ? "󰂲" : (root.connectedCount > 0 ? "󰂱" : "󰂯")
    title: "Bluetooth"
    subtitle: root.statusLine
    iconOpacity: root.radioOn ? 1 : 0.5
ToggleSwitch {
    id: power
    checked: root.radioOn
    onToggled: root.toggleRadio()
}
}

                        IconText {
                            visible: root.rows.length === 0
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: !root.adapter ? "No Bluetooth adapter" : (!root.radioOn ? "Turn Bluetooth on to scan" : "Scanning")
                            color: Commons.Color.muted
                            size: Style.font.body
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

                                SectionLabel {
                                    visible: showHeader
                                    text: root.sectionTitle(modelData.section)
                                }

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
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
                                            text: "󰂯"
                                            color: modelData.connected ? Commons.Color.text : Commons.Color.muted
                                            size: Style.font.heading
                                            horizontalAlignment: Text.AlignHCenter
                                        }

                                        Column {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: parent.width - 22 - parent.spacing
                                            spacing: 1

                                            IconText {
                                                width: parent.width
                                                text: modelData.name
                                                size: Style.font.subtitle
                                                elide: Text.ElideRight
                                            }

                                            IconText {
                                                visible: modelData.connected
                                                width: parent.width
                                                text: modelData.battery >= 0 ? ("Connected · " + modelData.battery + "%") : "Connected"
                                                color: Commons.Color.subtext
                                                size: Style.font.caption
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