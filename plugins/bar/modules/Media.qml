import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "../../../Commons"
import "../../../Commons" as Commons
import "../../../Ui"

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
    implicitHeight: Style.bar.height

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

    BarButton {
        id: row
        visible: root.hasMedia
        icon: root.active && root.active.isPlaying ? "󰏤" : "󰐊"
        label: root.title + (root.artist ? "  ·  " + root.artist : "")
        labelSize: Style.font.subtitle
        labelMaxWidth: 180
        onClicked: if (root.active) root.act("toggle")
        onRightClicked: if (root.active) root.opened = !root.opened
        onMiddleClicked: if (root.active) root.act("next")
        onWheeled: function (delta) { root.act(delta > 0 ? "previous" : "next") }
    }

    Loader {
        active: root.opened && root.hasMedia
        sourceComponent: PanelPopup {
            anchorItem: row
            panelNamespace: "media-panel"
            cardWidth: 340
            cardSpacing: 12
            onDismissed: root.opened = false

                        Row {
                            width: parent.width
                            spacing: 12

                            Rectangle {
                                width: 64
                                height: 64
                                color: Commons.Color.surface

                                Image {
                                    anchors.fill: parent
                                    anchors.margins: 2
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    source: root.active && root.active.trackArtUrl ? root.active.trackArtUrl : ""
                                    visible: status === Image.Ready
                                }

                                IconText {
                                    anchors.centerIn: parent
                                    visible: !parent.children[0].visible
                                    text: "󰝚"
                                    size: Style.font.displayLarge
                                }
                            }

                            Column {
                                width: parent.width - 76
                                spacing: 2
                                anchors.verticalCenter: parent.verticalCenter

                                IconText {
                                    width: parent.width
                                    text: root.title || "Nothing playing"
                                    size: Style.font.title
                                    font.bold: true
                                    elide: Text.ElideRight
                                }
                                IconText {
                                    width: parent.width
                                    text: root.artist
                                    color: Commons.Color.subtext
                                    size: Style.font.body
                                    elide: Text.ElideRight
                                    visible: text !== ""
                                }
                                IconText {
                                    width: parent.width
                                    text: root.active && root.active.trackAlbum ? root.active.trackAlbum : ""
                                    color: Commons.Color.muted
                                    size: Style.font.bodySmall
                                    elide: Text.ElideRight
                                    visible: text !== ""
                                }
                            }
                        }

                        Rectangle {
                            visible: root.active && root.active.lengthSupported && root.active.length > 0
                            width: parent.width
                            height: 6
                            color: Commons.Color.surface

                            Rectangle {
                                width: parent.width * root.progress
                                height: parent.height
                                color: Commons.Color.text
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

                            IconText {
                                text: root.active ? root.clock(root.active.position) : ""
                                color: Commons.Color.muted
                                size: Style.font.caption
                            }
                            IconText {
                                anchors.right: parent.right
                                text: root.active ? root.clock(root.active.length) : ""
                                color: Commons.Color.muted
                                size: Style.font.caption
                            }
                        }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 18

                            IconText {
                                text: "󰒮"
                                color: root.active && root.active.canGoPrevious ? Commons.Color.text : Commons.Color.border
                                size: Style.font.displaySmall
                                MouseArea { anchors.fill: parent; onClicked: root.act("previous") }
                            }
                            IconText {
                                text: root.active && root.active.isPlaying ? "󰏤" : "󰐊"
                                size: Style.font.display
                                MouseArea { anchors.fill: parent; onClicked: root.act("toggle") }
                            }
                            IconText {
                                text: "󰒭"
                                color: root.active && root.active.canGoNext ? Commons.Color.text : Commons.Color.border
                                size: Style.font.displaySmall
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
                                    color: root.active && modelData.key === root.active.dbusName ? Commons.Color.surface : "transparent"

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        anchors.leftMargin: 8
                                        anchors.right: parent.right
                                        anchors.rightMargin: 8

                                        IconText {
                                            width: parent.width
                                            text: modelData.title
                                            size: Style.font.body
                                            elide: Text.ElideRight
                                        }
                                        IconText {
                                            width: parent.width
                                            text: modelData.artist
                                            color: Commons.Color.muted
                                            size: Style.font.caption
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