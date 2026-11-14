import QtQuick
import Quickshell.Services.UPower

Item {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property bool present: !!(device && device.isPresent)
    readonly property int percent: present ? Math.round(device.percentage * 100) : 0
    readonly property bool pluggedIn: present && !UPower.onBattery

    implicitWidth: label.implicitWidth
    implicitHeight: 32

    Text {
        id: label
        anchors.centerIn: parent
        text: {
            if (!root.present) return "󰂄"
            var source = root.pluggedIn ? "plugged in" : "on battery"
            var icon = root.flow === "charging" ? "󰂄" : (root.flow === "discharging" ? "󰁹" : "󰂅")
            return icon + " " + root.percent + "%"
        }
        color: "#cdd6f4"
        font.family: "Iosevka Nerd Font"
        font.pixelSize: 16
    }
}