import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Item {
    id: root

    property bool opened: false
    property int cpu: 0
    property int memUsedKb: 0
    property int memTotalKb: 1
    property int swapUsedKb: 0
    property int swapTotalKb: 0
    property int taskCount: 0
    property int threadCount: 0
    property string load: "0.00  0.00  0.00"
    property string uptime: "0m"
    property var cores: []
    property var lastCpu: null

    readonly property int memPercent: memTotalKb > 0 ? Math.round(memUsedKb * 100 / memTotalKb) : 0
    readonly property int swapPercent: swapTotalKb > 0 ? Math.round(swapUsedKb * 100 / swapTotalKb) : 0

    implicitWidth: row.implicitWidth
    implicitHeight: 32

    function formatGb(kb) {
        var gb = kb / 1024 / 1024
        return gb >= 10 ? Math.round(gb) + "G" : gb.toFixed(1) + "G"
    }

    function percent(now, old) {
        if (!now || !old) return 0
        var total = now.total - old.total
        var idle = now.idle - old.idle
        if (total <= 0) return 0
        return Math.max(0, Math.min(100, Math.round((1 - idle / total) * 100)))
    }

    function sample(parts) {
        var idle = (parts[3] || 0) + (parts[4] || 0)
        var total = 0
        for (var i = 0; i < parts.length; i++) total += parts[i]
        return { idle: idle, total: total }
    }

    function parseCpu(raw) {
        var lines = String(raw || "").split("\n")
        var total = null
        var coreSamples = []
        for (var i = 0; i < lines.length; i++) {
            if (lines[i].indexOf("cpu") !== 0) break
            var fields = lines[i].trim().split(/\s+/)
            var nums = []
            for (var n = 1; n < fields.length; n++) nums.push(parseInt(fields[n], 10) || 0)
            var point = sample(nums)
            if (fields[0] === "cpu") total = point
            else coreSamples.push(point)
        }
        var previous = lastCpu
        lastCpu = { total: total, cores: coreSamples }
        if (!previous) return
        cpu = percent(total, previous.total)
        var usage = []
        for (var c = 0; c < coreSamples.length; c++) usage.push(percent(coreSamples[c], previous.cores[c]))
        cores = usage
    }

    function parseMem(raw) {
        var total = 0
        var available = 0
        var swapTotal = 0
        var swapFree = 0
        var lines = String(raw || "").split("\n")
        for (var i = 0; i < lines.length; i++) {
            var value = parseInt(lines[i].replace(/[^0-9]/g, ""), 10) || 0
            if (lines[i].indexOf("MemTotal:") === 0) total = value
            else if (lines[i].indexOf("MemAvailable:") === 0) available = value
            else if (lines[i].indexOf("SwapTotal:") === 0) swapTotal = value
            else if (lines[i].indexOf("SwapFree:") === 0) swapFree = value
        }
        memTotalKb = total
        memUsedKb = Math.max(0, total - available)
        swapTotalKb = swapTotal
        swapUsedKb = Math.max(0, swapTotal - swapFree)
    }

    function parseLoad(raw) {
        var parts = String(raw || "").trim().split(/\s+/)
        load = parts.slice(0, 3).join("  ") || "0.00  0.00  0.00"
    }

    function parseUptime(raw) {
        var seconds = Math.floor(parseFloat(String(raw || "").split(/\s+/)[0]) || 0)
        var days = Math.floor(seconds / 86400)
        seconds %= 86400
        var hours = Math.floor(seconds / 3600)
        seconds %= 3600
        var minutes = Math.floor(seconds / 60)
        uptime = (days > 0 ? days + "d " : "") + hours + "h " + minutes + "m"
    }

    function parseTasks(raw) {
        var lines = String(raw || "").trim().split("\n")
        var tasks = 0
        var threads = 0
        for (var i = 0; i < lines.length; i++) {
            if (!lines[i]) continue
            tasks++
            threads += parseInt(lines[i], 10) || 0
        }
        taskCount = tasks
        threadCount = threads
    }

    Process {
        id: cpuRead
        command: ["cat", "/proc/stat"]
        running: true
        stdout: StdioCollector { onStreamFinished: root.parseCpu(text) }
    }

    Process {
        id: memRead
        command: ["cat", "/proc/meminfo"]
        running: true
        stdout: StdioCollector { onStreamFinished: root.parseMem(text) }
    }

    Process {
        id: loadRead
        command: ["cat", "/proc/loadavg"]
        stdout: StdioCollector { onStreamFinished: root.parseLoad(text) }
    }

    Process {
        id: uptimeRead
        command: ["cat", "/proc/uptime"]
        stdout: StdioCollector { onStreamFinished: root.parseUptime(text) }
    }

    Process {
        id: taskRead
        command: ["ps", "-eo", "nlwp", "--no-headers"]
        stdout: StdioCollector { onStreamFinished: root.parseTasks(text) }
    }

    function refreshPanel() {
        loadRead.running = true
        uptimeRead.running = true
        taskRead.running = true
    }

    Timer {
        interval: 4000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            cpuRead.running = true
            memRead.running = true
            if (root.opened) root.refreshPanel()
        }
    }

    onOpenedChanged: if (opened) refreshPanel()

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 14

        Row {
            spacing: 6
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: ""
                color: "#cdd6f4"
                font.family: "Iosevka Nerd Font"
                font.pixelSize: 16
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.cpu + "%"
                color: "#cdd6f4"
                font.family: "Iosevka Nerd Font"
                font.pixelSize: 16
            }
        }

        Row {
            spacing: 6
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: ""
                color: "#cdd6f4"
                font.family: "Iosevka Nerd Font"
                font.pixelSize: 16
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.formatGb(root.memUsedKb)
                color: "#cdd6f4"
                font.family: "Iosevka Nerd Font"
                font.pixelSize: 16
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.opened = !root.opened
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
                WlrLayershell.namespace: "system-panel"
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

                    width: 460
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
                        spacing: 12

                        Text {
                            text: "System"
                            color: "#cdd6f4"
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: 18
                            font.bold: true
                        }

                        Column {
                            width: parent.width
                            spacing: 8

                            Item {
                                width: parent.width
                                height: 16

                                Text {
                                    text: "CPU"
                                    color: "#7f849c"
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: 14
                                    font.bold: true
                                    font.letterSpacing: 1.2
                                }

                                Text {
                                    anchors.right: parent.right
                                    text: root.cpu + "%"
                                    color: "#cdd6f4"
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: 14
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 8
                                color: "#313244"
                                Rectangle {
                                    width: parent.width * root.cpu / 100
                                    height: parent.height
                                    color: "#cdd6f4"
                                }
                            }
                        }

                        Column {
                            width: parent.width
                            spacing: 8

                            Item {
                                width: parent.width
                                height: 16

                                Text {
                                    text: "MEM"
                                    color: "#7f849c"
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: 14
                                    font.bold: true
                                    font.letterSpacing: 1.2
                                }

                                Text {
                                    anchors.right: parent.right
                                    text: root.formatGb(root.memUsedKb) + " / " + root.formatGb(root.memTotalKb)
                                    color: "#cdd6f4"
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: 14
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 8
                                color: "#313244"
                                Rectangle {
                                    width: parent.width * root.memPercent / 100
                                    height: parent.height
                                    color: "#a6e3a1"
                                }
                            }

                            Item {
                                width: parent.width
                                height: 16

                                Text {
                                    text: "SWAP"
                                    color: "#7f849c"
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: 14
                                    font.bold: true
                                    font.letterSpacing: 1.2
                                }

                                Text {
                                    anchors.right: parent.right
                                    text: root.swapTotalKb > 0
                                        ? root.formatGb(root.swapUsedKb) + " / " + root.formatGb(root.swapTotalKb)
                                        : "none"
                                    color: "#cdd6f4"
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: 14
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 8
                                color: "#313244"
                                Rectangle {
                                    width: parent.width * root.swapPercent / 100
                                    height: parent.height
                                    color: "#f9e2af"
                                }
                            }
                        }

                        GridLayout {
                            width: parent.width
                            columns: 2
                            columnSpacing: 16
                            rowSpacing: 6

                            Text { text: "TASKS"; color: "#7f849c"; font.family: "Iosevka Nerd Font"; font.pixelSize: 14; font.bold: true; font.letterSpacing: 1.2 }
                            Text { text: root.taskCount; color: "#cdd6f4"; font.family: "Iosevka Nerd Font"; font.pixelSize: 14; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight }
                            Text { text: "THREADS"; color: "#7f849c"; font.family: "Iosevka Nerd Font"; font.pixelSize: 14; font.bold: true; font.letterSpacing: 1.2 }
                            Text { text: root.threadCount; color: "#cdd6f4"; font.family: "Iosevka Nerd Font"; font.pixelSize: 14; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight }
                            Text { text: "LOAD"; color: "#7f849c"; font.family: "Iosevka Nerd Font"; font.pixelSize: 14; font.bold: true; font.letterSpacing: 1.2 }
                            Text { text: root.load; color: "#cdd6f4"; font.family: "Iosevka Nerd Font"; font.pixelSize: 14; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight }
                            Text { text: "UPTIME"; color: "#7f849c"; font.family: "Iosevka Nerd Font"; font.pixelSize: 14; font.bold: true; font.letterSpacing: 1.2 }
                            Text { text: root.uptime; color: "#cdd6f4"; font.family: "Iosevka Nerd Font"; font.pixelSize: 14; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight }
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
                    WlrLayershell.namespace: "system-panel-dismiss"
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