import QtQuick
import Quickshell
import Quickshell.Io
import "../../../Commons"
import "../../../Commons" as Commons
import "../../../Ui"

Item {
    id: root

    property bool opened: false
    property int brightness: 0
    property int brightnessMax: 1

    readonly property string backlight: "/sys/class/backlight/intel_backlight"
    readonly property int percent: brightnessMax > 0 ? Math.round(brightness * 100 / brightnessMax) : 0

    implicitWidth: row.implicitWidth
    implicitHeight: Style.bar.height

    function setBrightness(nextPercent) {
        var clamped = Math.max(0, Math.min(100, Math.round(nextPercent)))
        brightness = Math.round(brightnessMax * clamped / 100)
        Quickshell.execDetached(["brightnessctl", "set", clamped + "%"])
    }

    Process {
        id: brightnessRead
        command: ["cat", root.backlight + "/brightness"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.brightness = parseInt(text, 10) || 0
        }
    }

    Process {
        id: brightnessMaxRead
        command: ["cat", root.backlight + "/max_brightness"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.brightnessMax = parseInt(text, 10) || 1
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            brightnessRead.running = true
            brightnessMaxRead.running = true
        }
    }

    BarButton {
        id: row
        icon: "󰃠"
        label: root.percent + "%"
        onClicked: root.opened = !root.opened
        onWheeled: function (delta) { root.setBrightness(root.percent + (delta > 0 ? 5 : -5)) }
    }

    Loader {
        active: root.opened
        sourceComponent: PanelPopup {
            anchorItem: row
            panelNamespace: "brightness-panel"
            cardWidth: 380
            cardSpacing: 14
            onDismissed: root.opened = false

                        PanelHero {
    icon: "󰃠"
    title: "Built-in display"
    subtitle: "INTEL_BACKLIGHT"
}

                        LabeledValue {
    label: "BRIGHTNESS"
    value: root.percent + "%"
}

                        Slider {
    value: root.percent / 100
    fill: Commons.Color.warning
    onMoved: function (next) { root.setBrightness(next * 100) }
}

                        Column {
                            width: parent.width
                            spacing: 8

                            LabeledValue {
    label: "CURRENT"
    value: root.brightness
}

                            LabeledValue {
    label: "MAXIMUM"
    value: root.brightnessMax
}

                            LabeledValue {
    label: "DEVICE"
    value: "intel_backlight"
}
                        }
        }
    }
}
