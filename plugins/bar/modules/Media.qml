import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Wayland

Item {
    id: root

    property bool opened: false
    property string preferredKey: ""
    property MprisPlayer active: null
    property var sources: []

    readonly property bool hasMedia: active && (active.trackTitle || active.trackArtist)
    readonly property string title: active ? (active.trackTitle || "") : ""
    readonly property string artist: active ? (active.trackArtist || "") : ""
    readonly property real progress: active && active.lengthSupported && active.length > 0
        ? Math.max(0, Math.min(1, active.position / active.length)) : 0

    visible: hasMedia
    implicitWidth: hasMedia ? row.implicitWidth : 0
    implicitHeight: 32

    function list() {
        return Mpris.players ? Mpris.players.values : []
    }

    function proxy(player) {
        return String(player && player.dbusName || "").toLowerCase().indexOf("playerctld") !== -1
    }

    function shown(player) {
        return !!(player && (player.trackTitle || player.trackArtist))
    }

    function choose() {
        var players = list()
        var preferred = null
        var playing = null
        var paused = null
        var rows = []
        for (var i = 0; i < players.length; i++) {
            var player = players[i]
            if (!player || proxy(player)) continue
            if (player.dbusName === preferredKey && shown(player)) preferred = player
            if (player.isPlaying && shown(player) && !playing) playing = player
            else if (!player.isPlaying && shown(player) && !paused) paused = player
            if (shown(player) || player.identity) {
                rows.push({
                    key: String(player.dbusName || ""),
                    title: String(player.trackTitle || player.identity || "Player"),
                    artist: String(player.trackArtist || ""),
                    playing: !!player.isPlaying
                })
            }
        }
        if (preferredKey && !preferred) preferredKey = ""
        active = (preferred && preferred.isPlaying) ? preferred : (playing || preferred || paused)
        sources = rows
    }

    function playerFor(key) {
        var players = list()
        for (var i = 0; i < players.length; i++) {
            if (players[i] && String(players[i].dbusName) === key) return players[i]
        }
        return null
    }

    function act(name, key) {
        var player = key ? playerFor(key) : active
        if (!player) return
        if (name === "next" && player.canGoNext) player.next()
        else if (name === "previous" && player.canGoPrevious) player.previous()
        else if (name === "toggle" && (player.canTogglePlaying || player.canPlay || player.canPause)) player.togglePlaying()
    }

    function clock(seconds) {
        var whole = Math.max(0, Math.floor(seconds))
        var minutes = Math.floor(whole / 60)
        var rest = whole % 60
        return minutes + ":" + (rest < 10 ? "0" : "") + rest
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.choose()
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6
        visible: root.hasMedia

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.active && root.active.isPlaying ? "󰏤" : "󰐊"
            color: "#cdd6f4"
            font.family: "Iosevka Nerd Font"
            font.pixelSize: 16
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 180)
            text: root.title + (root.artist ? "  ·  " + root.artist : "")
            color: "#cdd6f4"
            font.family: "Iosevka Nerd Font"
            font.pixelSize: 14
            elide: Text.ElideRight
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: function (mouse) {
            if (!root.active) return
            if (mouse.button === Qt.RightButton) root.opened = !root.opened
            else if (mouse.button === Qt.MiddleButton) root.act("next")
            else root.act("toggle")
        }
        onWheel: function (wheel) {
            root.act(wheel.angleDelta.y > 0 ? "previous" : "next")
        }
    }

    Loader {
        active: root.opened && root.hasMedia
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
                WlrLayershell.namespace: "media-panel"
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

                anchors { top: true; bottom: true; left: true; right: true }

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

                    width: 340
                    height: column.implicitHeight + 28
                    color: "#1e1e2e"
                    border.color: "#45475a"
                    border.width: 2
                    x: Math.max(8, Math.min(anchor.x + row.width / 2 - width / 2, screenW - width - 8))
                    y: 40

                    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }

                    Column {
                        id: column
                        z: 1
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 14
                        spacing: 12

                        Row {
                            width: parent.width
                            spacing: 12

                            Rectangle {
                                width: 64
                                height: 64
                                color: "#313244"

                                Image {
                                    anchors.fill: parent
                                    anchors.margins: 2
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    source: root.active && root.active.trackArtUrl ? root.active.trackArtUrl : ""
                                    visible: status === Image.Ready
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: !parent.children[0].visible
                                    text: "󰝚"
                                    color: "#cdd6f4"
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: 28
                                }
                            }

                            Column {
                                width: parent.width - 76
                                spacing: 2
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    width: parent.width
                                    text: root.title || "Nothing playing"
                                    color: "#cdd6f4"
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: 15
                                    font.bold: true
                                    elide: Text.ElideRight
                                }
                                Text {
                                    width: parent.width
                                    text: root.artist
                                    color: "#a6adc8"
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
                                    visible: text !== ""
                                }
                                Text {
                                    width: parent.width
                                    text: root.active && root.active.trackAlbum ? root.active.trackAlbum : ""
                                    color: "#7f849c"
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                    visible: text !== ""
                                }
                            }
                        }

                        Rectangle {
                            visible: root.active && root.active.lengthSupported && root.active.length > 0
                            width: parent.width
                            height: 6
                            color: "#313244"

                            Rectangle {
                                width: parent.width * root.progress
                                height: parent.height
                                color: "#cdd6f4"
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: root.active && root.active.canSeek
                                onClicked: function (mouse) {
                                    if (root.active) root.active.position = mouse.x / width * root.active.length
                                }
                            }
                        }

                        Item {
                            visible: parent.children[1].visible
                            width: parent.width
                            height: visible ? 14 : 0

                            Text {
                                text: root.active ? root.clock(root.active.position) : ""
                                color: "#7f849c"
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: 11
                            }
                            Text {
                                anchors.right: parent.right
                                text: root.active ? root.clock(root.active.length) : ""
                                color: "#7f849c"
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: 11
                            }
                        }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 18

                            Text {
                                text: "󰒮"
                                color: root.active && root.active.canGoPrevious ? "#cdd6f4" : "#45475a"
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: 20
                                MouseArea { anchors.fill: parent; onClicked: root.act("previous") }
                            }
                            Text {
                                text: root.active && root.active.isPlaying ? "󰏤" : "󰐊"
                                color: "#cdd6f4"
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: 24
                                MouseArea { anchors.fill: parent; onClicked: root.act("toggle") }
                            }
                            Text {
                                text: "󰒭"
                                color: root.active && root.active.canGoNext ? "#cdd6f4" : "#45475a"
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: 20
                                MouseArea { anchors.fill: parent; onClicked: root.act("next") }
                            }
                        }

                        Column {
                            width: parent.width
                            spacing: 4
                            visible: root.sources.length > 1

                            Repeater {
                                model: root.sources

                                delegate: Rectangle {
                                    required property var modelData
                                    width: parent.width
                                    height: 36
                                    color: root.active && modelData.key === root.active.dbusName ? "#313244" : "transparent"

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        anchors.leftMargin: 8
                                        anchors.right: parent.right
                                        anchors.rightMargin: 8

                                        Text {
                                            width: parent.width
                                            text: modelData.title
                                            color: "#cdd6f4"
                                            font.family: "Iosevka Nerd Font"
                                            font.pixelSize: 13
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            width: parent.width
                                            text: modelData.artist
                                            color: "#7f849c"
                                            font.family: "Iosevka Nerd Font"
                                            font.pixelSize: 11
                                            elide: Text.ElideRight
                                            visible: text !== ""
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            root.preferredKey = modelData.key
                                            root.choose()
                                        }
                                    }
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
                    WlrLayershell.namespace: "media-panel-dismiss"
                    WlrLayershell.layer: WlrLayer.Overlay
                    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                    anchors { top: true; bottom: true; left: true; right: true }
                    MouseArea { anchors.fill: parent; onClicked: root.opened = false }
                }
            }
        }
    }
}