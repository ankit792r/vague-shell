import QtQuick
import Quickshell
import Quickshell.Io
import "../../../Commons"
import "../../../Ui"

Item {
    id: root

    property string outputName: ""
    property var workspaces: []
    property var windows: []

    readonly property var shown: {
        var list = []
        for (var i = 0; i < workspaces.length; i++) {
            if (workspaces[i].output === outputName) list.push(workspaces[i])
        }
        list.sort(function (a, b) { return a.idx - b.idx })
        return list
    }

    readonly property string windowTitle: {
        var activeId = null
        for (var i = 0; i < shown.length; i++) {
            if (shown[i].is_active) activeId = shown[i].active_window_id
        }
        if (activeId == null) return ""
        for (var j = 0; j < windows.length; j++) {
            if (windows[j].id === activeId) return windows[j].title || windows[j].app_id || ""
        }
        return ""
    }

    implicitWidth: row.implicitWidth
    implicitHeight: Style.bar.height

    function take(line) {
        var event
        try { event = JSON.parse(line) } catch (e) { return }
        if (!event) return

        if (event.WorkspacesChanged) {
            workspaces = event.WorkspacesChanged.workspaces || []
        } else if (event.WorkspaceActivated) {
            var activated = event.WorkspaceActivated
            var output = ""
            var i
            for (i = 0; i < workspaces.length; i++) {
                if (workspaces[i].id === activated.id) output = workspaces[i].output
            }
            var next = []
            for (i = 0; i < workspaces.length; i++) {
                var ws = workspaces[i]
                var copy = {
                    id: ws.id, idx: ws.idx, name: ws.name, output: ws.output,
                    is_urgent: ws.is_urgent, is_active: ws.is_active,
                    is_focused: ws.is_focused, active_window_id: ws.active_window_id
                }
                if (copy.id === activated.id) {
                    copy.is_active = true
                    if (activated.focused) copy.is_focused = true
                } else {
                    if (copy.output === output) copy.is_active = false
                    if (activated.focused) copy.is_focused = false
                }
                next.push(copy)
            }
            workspaces = next
        } else if (event.WorkspaceActiveWindowChanged) {
            var change = event.WorkspaceActiveWindowChanged
            var updated = []
            for (var k = 0; k < workspaces.length; k++) {
                var item = workspaces[k]
                updated.push({
                    id: item.id, idx: item.idx, name: item.name, output: item.output,
                    is_urgent: item.is_urgent, is_active: item.is_active,
                    is_focused: item.is_focused,
                    active_window_id: item.id === change.workspace_id ? change.active_window_id : item.active_window_id
                })
            }
            workspaces = updated
        } else if (event.WindowsChanged) {
            windows = event.WindowsChanged.windows || []
        } else if (event.WindowOpenedOrChanged) {
            var win = event.WindowOpenedOrChanged.window
            var found = false
            var wins = []
            for (var n = 0; n < windows.length; n++) {
                if (windows[n].id === win.id) { wins.push(win); found = true }
                else wins.push(windows[n])
            }
            if (!found) wins.push(win)
            windows = wins
        } else if (event.WindowClosed) {
            var rest = []
            for (var c = 0; c < windows.length; c++) {
                if (windows[c].id !== event.WindowClosed.id) rest.push(windows[c])
            }
            windows = rest
        }
    }

    function focusWorkspace(index) {
        Quickshell.execDetached(["sh", "-c",
            "niri msg action focus-monitor '" + outputName + "' && niri msg action focus-workspace " + index])
    }

    Process {
        id: stream
        command: ["niri", "msg", "--json", "event-stream"]
        running: true
        stdout: SplitParser {
            onRead: function (line) { root.take(line) }
        }
        onExited: retry.start()
    }

    Timer {
        id: retry
        interval: 1000
        onTriggered: stream.running = true
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Row {
            spacing: 4

            Repeater {
                model: root.shown

                delegate: Rectangle {
                    required property var modelData
                    width: 22
                    height: 22
                    color: modelData.is_active ? Color.text : "transparent"
                    border.color: modelData.is_active ? Color.text : Color.border
                    border.width: 1

                    IconText {
                        anchors.centerIn: parent
                        text: modelData.name || modelData.idx
                        color: modelData.is_urgent ? Color.urgent : (modelData.is_active ? Color.background : Color.text)
                        size: Style.font.heading
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.focusWorkspace(modelData.idx)
                    }
                }
            }
        }

        IconText {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 280)
            text: root.windowTitle
            color: Color.subtext
            size: Style.font.subtitle
            elide: Text.ElideRight
            visible: text !== ""
        }
    }
}