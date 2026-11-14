import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Wayland

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
    implicitHeight: 32

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

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "󰓃"
            color: "#cdd6f4"
            font.family: "Iosevka Nerd Font"
            font.pixelSize: 16
            opacity: root.muted ? 0.5 : 1
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.percent + "%"
            color: "#cdd6f4"
            font.family: "Iosevka Nerd Font"
            font.pixelSize: 16
            opacity: root.muted ? 0.5 : 1
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function (mouse) {
            if (mouse.button === Qt.RightButton) {
                if (root.audio) root.audio.muted = !root.audio.muted
            } else {
                root.opened = !root.opened
            }
        }
        onWheel: function (wheel) {
            root.setVolume(root.level + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))
        }
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
                WlrLayershell.namespace: "volume-panel"
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
                        spacing: 14

                        Item {
                            width: parent.width
                            height: 42

                            Text {
                                id: heroIcon
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.glyph()
                                color: "#cdd6f4"
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: 28
                                opacity: root.muted ? 0.5 : 1
                            }

                            Column {
                                anchors.left: heroIcon.right
                                anchors.leftMargin: 14
                                anchors.right: muteSwitch.left
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Text {
                                    width: parent.width
                                    text: root.outputName
                                    color: "#cdd6f4"
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: 16
                                    font.bold: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width
                                    text: root.muted ? "MUTED" : "VOLUME"
                                    color: "#7f849c"
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: 11
                                    font.bold: true
                                    font.letterSpacing: 1.2
                                }
                            }

                            Rectangle {
                                id: muteSwitch
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 36
                                height: 20
                                color: root.muted ? "#45475a" : "#a6e3a1"

                                Rectangle {
                                    width: 16
                                    height: 16
                                    color: "#1e1e2e"
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: root.muted ? 2 : parent.width - width - 2
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: if (root.audio) root.audio.muted = !root.audio.muted
                                }
                            }
                        }

                        Item {
                            width: parent.width
                            height: 18

                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: "VOLUME"
                                color: "#7f849c"
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: 11
                                font.bold: true
                                font.letterSpacing: 1.2
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.percent + "%"
                                color: "#cdd6f4"
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: 13
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 18
                            color: "transparent"

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                height: 6
                                color: "#313244"

                                Rectangle {
                                    width: parent.width * root.level
                                    height: parent.height
                                    color: "#cdd6f4"
                                    opacity: root.muted ? 0.4 : 1
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onPressed: function (mouse) { root.setVolume(mouse.x / width) }
                                onPositionChanged: function (mouse) { if (pressed) root.setVolume(mouse.x / width) }
                            }
                        }

                        Text {
                            text: "OUTPUT"
                            color: "#7f849c"
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: 11
                            font.bold: true
                            font.letterSpacing: 1.2
                        }

                        ListView {
                            width: parent.width
                            height: Math.min(Math.max(contentHeight, 32), 160)
                            clip: true
                            spacing: 2
                            model: root.outputs

                            delegate: Rectangle {
                                required property var modelData
                                width: ListView.view.width
                                height: 32
                                color: modelData.current || outputMouse.containsMouse ? "#313244" : "transparent"

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 8
                                    anchors.right: parent.right
                                    anchors.rightMargin: 8
                                    text: modelData.description
                                    color: "#cdd6f4"
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
                                }

                                MouseArea {
                                    id: outputMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: root.selectOutput(modelData.name)
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
                    WlrLayershell.namespace: "volume-panel-dismiss"
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
