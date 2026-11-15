import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../../../Commons"
import "../../../Ui"

Item {
    id: root

    property bool expanded: false
    property bool pinned: false
    property bool opened: false
    property int brightness: 0
    property int brightnessMax: 1
    property var outputs: []

    readonly property string backlight: "/sys/class/backlight/intel_backlight"
    readonly property bool shown: expanded || pinned || opened
    readonly property int volumePercent: Math.round(level * 100)
    readonly property int brightnessPercent: brightnessMax > 0 ? Math.round(brightness * 100 / brightnessMax) : 0

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNodeAudio audio: sink ? sink.audio : null
    readonly property bool muted: audio ? audio.muted : false
    readonly property real level: audio ? audio.volume : 0

    implicitWidth: row.implicitWidth
    implicitHeight: Style.bar.height

    function glyph() {
        if (!audio || muted || level <= 0) return "󰖁"
        if (level < 0.33) return "󰕿"
        if (level < 0.66) return "󰖀"
        return "󰕾"
    }

    function refreshOutputs() {
        var nodes = Pipewire.nodes ? Pipewire.nodes.values : []
        var rows = []
        for (var i = 0; i < nodes.length; i++) {
            var node = nodes[i]
            if (!node || !node.isSink || node.isStream) continue
            rows.push({
                name: String(node.name || ""),
                description: String(node.description || node.nickname || node.name || ""),
                current: sink && node.name === sink.name
            })
        }
        outputs = rows
    }

    function selectOutput(name) {
        var nodes = Pipewire.nodes ? Pipewire.nodes.values : []
        for (var i = 0; i < nodes.length; i++) {
            if (nodes[i] && String(nodes[i].name) === name) {
                Pipewire.preferredDefaultAudioSink = nodes[i]
                return
            }
        }
    }

    function setVolume(value) {
        if (!audio) return
        audio.volume = Math.max(0, Math.min(1, value))
    }

    function setBrightness(percent) {
        var next = Math.max(0, Math.min(100, percent))
        brightness = Math.round(brightnessMax * next / 100)
        Quickshell.execDetached(["sh", "-c", "echo " + brightness + " > '" + backlight + "/brightness'"])
    }

    // HoverHandler {
    //     onHoveredChanged: root.expanded = hovered
    // }

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
            if (root.opened) root.refreshOutputs()
        }
    }

    onOpenedChanged: if (opened) refreshOutputs()

    BarButton {
        id: row
        icon: Quickshell.screens.length > 1 ? "󰍺" : "󰍹"
        onClicked: root.opened = !root.opened
        onWheeled: function (delta) { root.setBrightness(root.brightnessPercent + (delta > 0 ? 5 : -5)) }
    }

    Loader {
        active: root.opened
        sourceComponent: PanelPopup {
            anchorItem: row
            panelNamespace: "monitor-panel"
            cardWidth: 380
            cardSpacing: 14
            onDismissed: root.opened = false

                        PanelHero {
    icon: root.glyph()
    title: "Output"
    subtitle: root.muted ? "MUTED" : "VOLUME"
    iconOpacity: root.muted ? 0.5 : 1
ToggleSwitch {
    id: muteSwitch
    checked: !(root.muted)
    onToggled: if (root.audio) root.audio.muted = !root.audio.muted
}
}

                        LabeledValue {
    label: "VOLUME"
    value: root.volumePercent + "%"
}

                        Slider {
    value: root.level
    fillOpacity: root.muted ? 0.4 : 1
    onMoved: function (next) { root.setVolume(next) }
}

                        ListView {
                            width: parent.width
                            height: Math.min(contentHeight, 140)
                            clip: true
                            spacing: 2
                            model: root.outputs

                            delegate: ListRow {
                                required property var modelData
                                active: modelData.current
                                label: modelData.description
                                onActivated: root.selectOutput(modelData.name)
                            }
                        }

                        LabeledValue {
    label: "BRIGHTNESS"
    value: root.brightnessPercent + "%"
}

                        Slider {
    value: root.brightnessPercent / 100
    onMoved: function (next) { root.setBrightness(next * 100) }
}
        }
    }
}