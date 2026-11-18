import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../../Commons"
import "../../../Commons" as Commons
import "../../../Ui"

// Hyprland counterpart of Workspace.qml, read from Quickshell's Hyprland IPC.
Item {
    id: root

    property string outputName: ""

    readonly property var shown: {
        var all = Hyprland.workspaces.values
        var list = []
        for (var i = 0; i < all.length; i++) {
            var ws = all[i]
            if (!ws || ws.id < 0) continue
            if (!ws.monitor || ws.monitor.name !== outputName) continue
            list.push(ws)
        }
        list.sort(function (a, b) { return a.id - b.id })
        return list
    }

    readonly property var activeWorkspace: {
        for (var i = 0; i < shown.length; i++) {
            if (shown[i].active) return shown[i]
        }
        return null
    }

    readonly property string windowTitle: {
        var ws = activeWorkspace
        if (!ws) return ""
        var focused = Hyprland.activeToplevel
        if (focused && focused.workspace === ws) return focused.title || ""
        var windows = ws.toplevels ? ws.toplevels.values : []
        return windows.length > 0 ? (windows[0].title || "") : ""
    }

    implicitWidth: row.implicitWidth
    implicitHeight: Style.bar.height

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
                    color: modelData.active ? Commons.Color.text : "transparent"
                    border.color: modelData.active ? Commons.Color.text : Commons.Color.border
                    border.width: 1

                    IconText {
                        anchors.centerIn: parent
                        text: modelData.name || modelData.id
                        color: modelData.urgent ? Commons.Color.urgent : (modelData.active ? Commons.Color.background : Commons.Color.text)
                        size: Style.font.heading
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: modelData.activate()
                    }
                }
            }
        }

        IconText {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 280)
            text: root.windowTitle
            color: Commons.Color.text
            size: Style.font.heading
            elide: Text.ElideRight
            visible: text !== ""
        }
    }
}
