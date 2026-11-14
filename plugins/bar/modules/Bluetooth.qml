import QtQuick
import QtQml
import Quickshell.Bluetooth

Item {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool radioOn: adapter ? adapter.enabled : false

    readonly property int connectedCount: {
        var tick = devices.revision
        var count = 0
        for (var i = 0; i < devices.count; i++) {
            var device = devices.objectAt(i)
            if (device && device.label !== "") count++
        }
        return count
    }

    readonly property string name: {
        var tick = devices.revision
        if (!adapter) return "No adapter"
        if (!radioOn) return "Off"
        var parts = []
        for (var i = 0; i < devices.count; i++) {
            var device = devices.objectAt(i)
            if (device && device.label !== "") parts.push(device.label)
        }
        return parts.length > 0 ? parts.join(", ") : "On"
    }

    // Reading connected through a plain var does not subscribe to
    // connectedChanged. Each device is a typed object, and label bumps
    // revision so the text above is rebuilt when one connects.
    Instantiator {
        id: devices
        model: Bluetooth.devices
        property int revision: 0

        delegate: QtObject {
            required property BluetoothDevice modelData
            readonly property string label: {
                if (!modelData.connected) return ""
                return String(modelData.deviceName || modelData.name || modelData.address)
            }
            onLabelChanged: devices.revision++
        }
    }

    implicitWidth: row.implicitWidth
    implicitHeight: 32

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
}