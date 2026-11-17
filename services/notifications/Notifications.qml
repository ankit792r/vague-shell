import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Wayland
import "../../Commons"
import "../../Commons" as Commons

// Notification daemon. Replaces mako: one server on the session bus, cards
// grouped by app, with the same lifetimes Omarchy uses.
Item {
    id: root

    property bool doNotDisturb: false
    property bool paused: false
    property double pausedAt: 0
    property var order: []
    property var live: ({})
    property var refs: ({})
    property int revision: 0

    readonly property int lowDuration: 5000
    readonly property int normalDuration: 8000
    readonly property int maxDuration: 30000

    readonly property var shown: {
        var bump = revision
        var groups = []
        var at = {}
        for (var i = 0; i < order.length; i++) {
            var row = live[order[i]]
            if (!row || row.silenced) continue
            var key = row.appName || "Notification"
            if (at[key] === undefined) {
                at[key] = groups.length
                groups.push({ key: key, count: 0, row: row })
            }
            groups[at[key]].count += 1
        }
        return groups.slice(0, 4)
    }

    function touch() { revision++ }

    function plain(text) {
        return String(text || "")
            .replace(/<br\s*\/?>/gi, "\n")
            .replace(/<[^>]+>/g, "")
            .replace(/&amp;/g, "&")
            .replace(/&lt;/g, "<")
            .replace(/&gt;/g, ">")
            .replace(/&quot;/g, "\"")
            .replace(/&#39;/g, "'")
            .replace(/[ \t]+\n/g, "\n")
            .trim()
    }

    function iconFor(notification) {
        var image = String(notification.image || "")
        if (image.indexOf("file:") === 0 || image.indexOf("image:") === 0) return image
        if (image.indexOf("/") === 0) return "file://" + image
        var name = notification.appIcon || notification.desktopEntry || image
        if (!name) return ""
        var path = Quickshell.iconPath(name)
        if (!path) return ""
        if (path.indexOf("file:") === 0 || path.indexOf("/") !== 0) return path
        return "file://" + path
    }

    function durationFor(urgency, requested) {
        if (urgency === NotificationUrgency.Critical) return 0
        if (requested === 0) return 0
        var base = urgency === NotificationUrgency.Low ? lowDuration : normalDuration
        var asked = requested > 0 ? requested : base
        return Math.min(maxDuration, Math.max(base, asked))
    }

    function actionsOf(notification) {
        var list = notification.actions || []
        var out = []
        for (var i = 0; i < list.length && out.length < 3; i++) {
            out.push({
                identifier: String(list[i].identifier || ""),
                text: String(list[i].text || "Open")
            })
        }
        return out
    }

    function progressOf(notification) {
        var hints = notification.hints || {}
        if (hints.value === undefined || hints.value === null) return -1
        var value = Number(hints.value)
        if (isNaN(value)) return -1
        return value > 1 ? value / 100 : value
    }

    property bool receiving: false

    function receive(notification) {
        if (!notification || receiving) return
        receiving = true
        var id = notification.id
        if (!notification.tracked) notification.tracked = true
        var duration = durationFor(notification.urgency, notification.expireTimeout)
        var row = {
            id: id,
            appName: plain(notification.appName),
            summary: plain(notification.summary),
            body: plain(notification.body),
            urgency: notification.urgency,
            icon: iconFor(notification),
            actions: actionsOf(notification),
            progress: progressOf(notification),
            duration: duration,
            deadline: duration > 0 ? Date.now() + duration : 0,
            silenced: root.doNotDisturb && notification.urgency !== NotificationUrgency.Critical
        }
        var nextLive = live
        nextLive[id] = row
        live = nextLive
        var next = [id]
        for (var i = 0; i < order.length && next.length < 20; i++) {
            if (order[i] !== id) next.push(order[i])
        }
        order = next
        if (refs[id] !== notification) {
            refs[id] = notification
            notification.closed.connect(function () {
                if (root.refs[id] === notification) root.remove(id)
            })
        }
        touch()
        receiving = false
    }

    function remove(id) {
        if (refs[id]) {
            try { refs[id].tracked = false } catch (e) {}
        }
        delete refs[id]
        delete live[id]
        var next = []
        for (var i = 0; i < order.length; i++) {
            if (order[i] !== id) next.push(order[i])
        }
        order = next
        touch()
    }

    function dismiss(id) {
        var notification = refs[id]
        if (notification) {
            try { notification.dismiss() } catch (e) {}
        }
        remove(id)
    }

    function dismissAll() {
        var ids = order.slice()
        for (var i = 0; i < ids.length; i++) dismiss(ids[i])
    }

    function invoke(id, identifier) {
        var notification = refs[id]
        if (!notification) return
        var list = notification.actions || []
        for (var i = 0; i < list.length; i++) {
            if (String(list[i].identifier) === identifier) {
                list[i].invoke()
                dismiss(id)
                return
            }
        }
    }

    function expireDue() {
        if (paused) return
        var now = Date.now()
        var ids = order.slice()
        for (var i = 0; i < ids.length; i++) {
            var row = live[ids[i]]
            if (!row || row.deadline <= 0 || row.deadline > now) continue
            var notification = refs[ids[i]]
            if (notification) {
                try { notification.expire() } catch (e) {}
            }
            remove(ids[i])
        }
    }

    function setPaused(value) {
        if (value === paused) return
        if (value) {
            pausedAt = Date.now()
        } else if (pausedAt > 0) {
            var delta = Date.now() - pausedAt
            for (var i = 0; i < order.length; i++) {
                var row = live[order[i]]
                if (row && row.deadline > 0) row.deadline += delta
            }
            pausedAt = 0
            touch()
        }
        paused = value
    }

    function setDoNotDisturb(value) {
        doNotDisturb = value
        if (value) {
            for (var i = 0; i < order.length; i++) {
                var row = live[order[i]]
                if (row && row.urgency !== NotificationUrgency.Critical) row.silenced = true
            }
        } else {
            var now = Date.now()
            for (var j = 0; j < order.length; j++) {
                var held = live[order[j]]
                if (!held || !held.silenced) continue
                held.silenced = false
                if (held.duration > 0) held.deadline = now + held.duration
            }
        }
        touch()
    }

    NotificationServer {
        keepOnReload: false
        imageSupported: true
        actionsSupported: true
        bodyMarkupSupported: true
        onNotification: function (notification) { root.receive(notification) }
    }

    Timer {
        interval: 250
        repeat: true
        running: root.order.length > 0 && !root.paused
        onTriggered: root.expireDue()
    }

    Timer {
        id: pauseRelease
        interval: 150
        onTriggered: root.setPaused(false)
    }

    IpcHandler {
        target: "notifications"
        function toggleDnd(): string {
            root.setDoNotDisturb(!root.doNotDisturb)
            return root.doNotDisturb ? "on" : "off"
        }
        function dismissAll(): string {
            root.dismissAll()
            return "ok"
        }
        function count(): string { return String(root.shown.length) }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            focusable: false
            visible: root.shown.length > 0

            WlrLayershell.namespace: "notifications"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            readonly property int deckWidth: 480

            anchors { top: true; right: true }
            margins.top: Style.bar.height + 8
            margins.right: 8
            implicitWidth: deckWidth
            implicitHeight: deck.implicitHeight

            Column {
                id: deck
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 8

                Repeater {
                    model: root.shown

                    delegate: Toast {
                        required property var modelData
                        width: deck.width
                        appName: modelData.row.appName
                        summary: modelData.row.summary
                        body: modelData.row.body
                        urgency: modelData.row.urgency
                        icon: modelData.row.icon
                        progress: modelData.row.progress
                        count: modelData.count
                        actions: modelData.row.actions
                        onDismissed: root.dismiss(modelData.row.id)
                        onInvoked: function (identifier) { root.invoke(modelData.row.id, identifier) }
                        onHovered: function (inside) {
                            if (inside) {
                                pauseRelease.stop()
                                root.setPaused(true)
                            } else {
                                pauseRelease.restart()
                            }
                        }
                    }
                }
            }
        }
    }
}
