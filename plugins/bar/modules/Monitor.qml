import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import "../../../Commons"

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

    Text {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        text: Quickshell.screens.length > 1 ? "󰍺" : "󰍹"
        color: Color.text
        font.family: Style.font.family
        font.pixelSize: Style.font.heading
        width: Math.max(implicitWidth, 18)
        height: 32
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.opened = !root.opened
        onWheel: function (wheel) {
            root.setBrightness(root.brightnessPercent + (wheel.angleDelta.y > 0 ? 5 : -5))
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
                WlrLayershell.namespace: "monitor-panel"
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
                    color: Color.background
                    border.color: Color.border
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
                                color: Color.text
                                font.family: Style.font.family
                                font.pixelSize: Style.font.displayLarge
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
                                    text: "Output"
                                    color: Color.text
                                    font.family: Style.font.family
                                    font.pixelSize: Style.font.heading
                                    font.bold: true
                                }

                                Text {
                                    width: parent.width
                                    text: root.muted ? "MUTED" : "VOLUME"
                                    color: Color.muted
                                    font.family: Style.font.family
                                    font.pixelSize: Style.font.caption
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
                                color: root.muted ? Color.border : Color.success

                                Rectangle {
                                    width: 16
                                    height: 16
                                    color: Color.background
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
                                color: Color.muted
                                font.family: Style.font.family
                                font.pixelSize: Style.font.caption
                                font.bold: true
                                font.letterSpacing: 1.2
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.volumePercent + "%"
                                color: Color.text
                                font.family: Style.font.family
                                font.pixelSize: Style.font.body
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
                                color: Color.surface

                                Rectangle {
                                    width: parent.width * root.level
                                    height: parent.height
                                    color: Color.text
                                    opacity: root.muted ? 0.4 : 1
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onPressed: function (mouse) { root.setVolume(mouse.x / width) }
                                onPositionChanged: function (mouse) { if (pressed) root.setVolume(mouse.x / width) }
                            }
                        }

                        ListView {
                            width: parent.width
                            height: Math.min(contentHeight, 140)
                            clip: true
                            spacing: 2
                            model: root.outputs

                            delegate: Rectangle {
                                required property var modelData
                                width: ListView.view.width
                                height: 32
                                color: modelData.current ? Color.surface : (outputMouse.containsMouse ? Color.surface : "transparent")

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 8
                                    anchors.right: parent.right
                                    anchors.rightMargin: 8
                                    text: modelData.description
                                    color: Color.text
                                    font.family: Style.font.family
                                    font.pixelSize: Style.font.body
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

                        Item {
                            width: parent.width
                            height: 18

                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: "BRIGHTNESS"
                                color: Color.muted
                                font.family: Style.font.family
                                font.pixelSize: Style.font.caption
                                font.bold: true
                                font.letterSpacing: 1.2
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.brightnessPercent + "%"
                                color: Color.text
                                font.family: Style.font.family
                                font.pixelSize: Style.font.body
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
                                color: Color.surface

                                Rectangle {
                                    width: parent.width * root.brightnessPercent / 100
                                    height: parent.height
                                    color: Color.text
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onPressed: function (mouse) { root.setBrightness(mouse.x / width * 100) }
                                onPositionChanged: function (mouse) { if (pressed) root.setBrightness(mouse.x / width * 100) }
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
                    WlrLayershell.namespace: "monitor-panel-dismiss"
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