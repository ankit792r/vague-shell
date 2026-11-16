import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../Commons"
import "../../Commons" as Commons
import "../../Ui"

Item {
    id: root

    property bool opened: false
    property bool ready: false
    property string filterText: ""
    property int selected: 0
    property var history: []

    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/quickshell"
    readonly property string historyPath: stateDir + "/clipboard-history.json"
    readonly property string captureScript: scriptPath()
    readonly property int historyLimit: 100

    readonly property var shown: {
        var query = filterText.toLowerCase()
        var rows = []
        for (var i = 0; i < history.length && rows.length < 50; i++) {
            var entry = history[i]
            if (!entry) continue
            var label = entry.type === "image"
                ? ("Image  " + (entry.capturedAt || ""))
                : String(entry.text || "").replace(/\s+/g, " ")
            if (query && label.toLowerCase().indexOf(query) < 0) continue
            rows.push({
                index: i,
                type: entry.type || "text",
                text: entry.text || "",
                path: entry.path || "",
                mime: entry.mime || "image/png",
                label: label
            })
        }
        return rows
    }

    function scriptPath() {
        var path = Qt.resolvedUrl("./capture.sh").toString()
        if (path.indexOf("file://") === 0) path = decodeURIComponent(path.substring(7))
        return path
    }

    function loadHistory(raw) {
        try {
            var parsed = JSON.parse(String(raw || "[]"))
            history = Array.isArray(parsed) ? parsed : []
        } catch (e) {
            history = []
        }
    }

    function saveHistory() {
        historyFile.setText(JSON.stringify(history.slice(0, historyLimit), null, 2) + "\n")
    }

    function addEntry(entry) {
        if (!entry || (entry.type !== "text" && entry.type !== "image")) return
        if (entry.type === "text" && !String(entry.text || "").trim()) return
        if (entry.type === "image" && !entry.path) return
        var key = entry.type === "image" ? "image:" + entry.path : "text:" + entry.text
        var next = [entry]
        for (var i = 0; i < history.length && next.length < historyLimit; i++) {
            var existing = history[i]
            if (!existing) continue
            var existingKey = existing.type === "image" ? "image:" + existing.path : "text:" + existing.text
            if (existingKey !== key) next.push(existing)
        }
        history = next
        saveHistory()
        if (opened) selected = 0
    }

    function addJson(line) {
        var raw = String(line || "").trim()
        if (!raw) return
        try { addEntry(JSON.parse(raw)) } catch (e) {}
    }

    function copyRow(row) {
        if (!row) return
        opened = false
        if (row.type === "image") {
            Quickshell.execDetached(["python3", "-c",
                "import pathlib,subprocess,sys; subprocess.run(['wl-copy','--type',sys.argv[1]], input=pathlib.Path(sys.argv[2]).read_bytes())",
                row.mime, row.path])
        } else {
            Quickshell.execDetached(["python3", "-c",
                "import subprocess,sys; subprocess.run(['wl-copy'], input=sys.argv[1].encode())",
                row.text])
        }
    }

    function removeRow(row) {
        if (!row) return
        var next = history.slice()
        next.splice(row.index, 1)
        history = next
        saveHistory()
    }

    function toggle() {
        opened = !opened
    }

    onOpenedChanged: if (opened) {
        filterText = ""
        selected = 0
        Qt.callLater(function () { if (filter) filter.forceActiveFocus() })
    }

    onShownChanged: if (selected >= shown.length) selected = Math.max(0, shown.length - 1)

    FileView {
        id: historyFile
        path: root.historyPath
        watchChanges: true
        atomicWrites: true
        printErrors: false
        onLoaded: {
            root.loadHistory(text())
            if (!root.ready) {
                root.ready = true
                currentProc.running = true
                textWatch.running = true
                imageWatch.running = true
            }
        }
        onLoadFailed: {
            root.loadHistory("[]")
            if (!root.ready) {
                root.ready = true
                currentProc.running = true
                textWatch.running = true
                imageWatch.running = true
            }
        }
        onFileChanged: reload()
    }

    Process {
        id: currentProc
        command: [root.captureScript]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.addJson(text)
        }
    }

    Process {
        id: textWatch
        command: ["setpriv", "--pdeathsig", "TERM", "wl-paste", "--type", "text", "--watch", root.captureScript, "text"]
        stdout: SplitParser { onRead: function (line) { root.addJson(line) } }
        onExited: watchRestart.restart()
    }

    Process {
        id: imageWatch
        command: ["setpriv", "--pdeathsig", "TERM", "wl-paste", "--type", "image/png", "--watch", root.captureScript, "image/png"]
        stdout: SplitParser { onRead: function (line) { root.addJson(line) } }
        onExited: watchRestart.restart()
    }

    Timer {
        id: watchRestart
        interval: 1000
        onTriggered: {
            if (!textWatch.running) textWatch.running = true
            if (!imageWatch.running) imageWatch.running = true
        }
    }

    IpcHandler {
        target: "clipboard"
        function toggle(): string {
            root.toggle()
            return root.opened ? "open" : "closed"
        }
        function show(): string { root.opened = true; return "open" }
        function hide(): string { root.opened = false; return "closed" }
    }

    CenterOverlay {
        shown: root.opened
        panelNamespace: "clipboard"
        cardWidth: 560
        cardHeight: 480
        onDismissed: root.opened = false


                Row {
                    width: parent.width
                    spacing: 8

                    Rectangle {
                        width: parent.width - clearButton.width - 8
                        height: 32
                        color: Commons.Color.surface

                        TextInput {
                            id: filter
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            verticalAlignment: TextInput.AlignVCenter
                            color: Commons.Color.text
                            font.family: Style.font.family
                            font.pixelSize: Style.font.subtitle
                            clip: true
                            selectByMouse: true
                            onTextChanged: root.filterText = text
                            Keys.onUpPressed: root.selected = Math.max(0, root.selected - 1)
                            Keys.onDownPressed: root.selected = Math.min(root.shown.length - 1, root.selected + 1)
                            Keys.onEscapePressed: {
                                if (text) text = ""
                                else root.opened = false
                            }
                            Keys.onReturnPressed: if (root.shown.length > 0) root.copyRow(root.shown[root.selected])
                            Keys.onDeletePressed: if (root.shown.length > 0) root.removeRow(root.shown[root.selected])
                        }

                        IconText {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Search clipboard"
                            color: Commons.Color.muted
                            size: Style.font.subtitle
                            visible: filter.text === "" && !filter.activeFocus
                        }
                    }

                    Rectangle {
                        id: clearButton
                        width: 64
                        height: 32
                        color: clearMouse.containsMouse ? Commons.Color.surface : "transparent"
                        border.color: Commons.Color.border
                        border.width: 1

                        IconText {
                            anchors.centerIn: parent
                            text: "Clear"
                            color: Commons.Color.urgent
                            size: Style.font.body
                        }

                        MouseArea {
                            id: clearMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                root.history = []
                                root.saveHistory()
                            }
                        }
                    }
                }

                ListView {
                    id: list
                    width: parent.width
                    height: parent.height - 42
                    clip: true
                    spacing: 2
                    model: root.shown
                    currentIndex: root.selected

                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: list.width
                        height: modelData.type === "image" ? 56 : 36
                        color: index === root.selected || rowMouse.containsMouse ? Commons.Color.surface : "transparent"

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            Image {
                                visible: modelData.type === "image"
                                anchors.verticalCenter: parent.verticalCenter
                                width: 44
                                height: 44
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                source: modelData.path ? ("file://" + modelData.path) : ""
                            }

                            IconText {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - (modelData.type === "image" ? 52 : 0)
                                text: modelData.label
                                size: Style.font.body
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: root.selected = index
                            onClicked: root.copyRow(modelData)
                        }
                    }
                }
    }
}
