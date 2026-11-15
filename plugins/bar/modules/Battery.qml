
import QtQuick
import Quickshell.Services.UPower
import "../../../Commons"

Item {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property bool present: !!(device && device.isPresent)
    readonly property int percent: present
        ? Math.round(device.percentage * 100)
        : 0

    readonly property bool pluggedIn: present && !UPower.onBattery

    implicitWidth: label.implicitWidth
    implicitHeight: Style.bar.height

    Text {
        id: label
        anchors.centerIn: parent

        text: {
            if (!root.present)
                return "󰂃"

            var icon

            if (root.device.state === UPowerDeviceState.Charging) {
                icon = "󰂄"
            } else if (root.device.state === UPowerDeviceState.Discharging) {
                icon = "󰁹"
            } else if (root.pluggedIn) {
                icon = "󰂅"
            } else {
                icon = "󰁿"
            }

            return icon + " " + root.percent + "%"
        }

        color: Color.text
        font.family: Style.font.family
        font.pixelSize: Style.font.heading
    }
}
