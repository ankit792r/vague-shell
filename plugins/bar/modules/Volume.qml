import QtQuick
import Quickshell.Services.Pipewire

Item {
    id: root

    // Holding the sink binds it. Until then audio.volume stays 0.
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNodeAudio audio: sink ? sink.audio : null
    readonly property bool muted: audio ? audio.muted : false
    readonly property real level: audio ? audio.volume : 0
    readonly property int percent: Math.round(level * 100)

    implicitWidth: row.implicitWidth
    implicitHeight: 32

    function glyph() {
        if (!audio || muted || level <= 0) return "󰖁"
        if (level < 0.33) return "󰕿"
        if (level < 0.66) return "󰖀"
        return "󰕾"
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.glyph()
            color: "#cdd6f4"
            font.family: "Iosevka Nerd Font"
            font.pixelSize: 16
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.percent + "%"
            color: "#cdd6f4"
            font.family: "Iosevka Nerd Font"
            font.pixelSize: 16
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: if (root.audio) root.audio.muted = !root.audio.muted
        onWheel: function (wheel) {
            if (!root.audio) return
            var step = wheel.angleDelta.y > 0 ? 0.05 : -0.05
            root.audio.volume = Math.max(0, Math.min(1, root.level + step))
        }
    }
}