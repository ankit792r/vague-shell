import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../../../Commons"
import "../../../Ui"

Item {
    id: root

    property bool opened: false
    property var outputs: []

    // Holding the sink binds it. Until then audio.volume stays 0.
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNodeAudio audio: sink ? sink.audio : null
    readonly property bool muted: audio ? audio.muted : false
    readonly property real level: audio ? audio.volume : 0
    readonly property int percent: Math.round(level * 100)
    readonly property string outputName: sink ? String(sink.description || sink.nickname || sink.name || "Output") : "No output"

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
                refreshOutputs()
                return
            }
        }
    }

    function setVolume(value) {
        if (!audio) return
        audio.volume = Math.max(0, Math.min(1, value))
    }

    Timer {
        interval: 2000
        running: root.opened
        repeat: true
        onTriggered: root.refreshOutputs()
    }

    onOpenedChanged: if (opened) refreshOutputs()

    BarButton {
        id: row
        icon: "󰓃"
        label: root.percent + "%"
        dimmed: root.muted
        onClicked: root.opened = !root.opened
        onRightClicked: if (root.audio) root.audio.muted = !root.audio.muted
        onWheeled: function (delta) { root.setVolume(root.level + (delta > 0 ? 0.05 : -0.05)) }
    }

    PopupLoader {
        open: root.opened
        sourceComponent: PanelPopup {
            open: root.opened
            anchorItem: row
            panelNamespace: "volume-panel"
            cardWidth: 380
            cardSpacing: 14
            onDismissed: root.opened = false

                        PanelHero {
    icon: root.glyph()
    title: root.outputName
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
    value: root.percent + "%"
}

                        Slider {
    value: root.level
    fillOpacity: root.muted ? 0.4 : 1
    onMoved: function (next) { root.setVolume(next) }
}

                        SectionLabel {
                            text: "OUTPUT"
                        }

                        ListView {
                            width: parent.width
                            height: Math.min(Math.max(contentHeight, 32), 160)
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
        }
    }
}
