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
        label: root.title
        labelSize: Style.font.title
        labelMaxWidth: 220
        onClicked: if (root.active) root.act("toggle")
        onRightClicked: if (root.active) root.opened = !root.opened
        onMiddleClicked: if (root.active) root.act("next")
        onWheeled: function (delta) { root.act(delta > 0 ? "previous" : "next") }
    }
}
