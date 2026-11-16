import QtQuick
import Quickshell
import Quickshell.Io
import "../../Commons"
import "../../Commons" as Commons
import "../../Ui"

// Application launcher. Opens from the bar, or with
// `qs ipc call launcher toggle`.
Item {
    id: root

    property bool opened: false
    property string filterText: ""
    property int selected: 0

    readonly property var shown: {
        var query = filterText.trim().toLowerCase()
        var values = DesktopEntries.applications.values || []
        var rows = []
        for (var i = 0; i < values.length; i++) {
            var app = values[i]
            if (!app || app.noDisplay || !app.name) continue
            var rank = root.matchRank(app, query)
            if (rank < 0) continue
            rows.push({
                id: app.id,
                name: app.name,
                genericName: app.genericName || "",
                icon: app.icon || "",
                rank: rank
            })
        }
        rows.sort(function (a, b) {
            if (a.rank !== b.rank) return a.rank - b.rank
            return String(a.name).localeCompare(String(b.name))
        })
        return rows
    }

    function fieldHit(value, query) {
        return String(value || "").toLowerCase().indexOf(query) >= 0
    }

    // -1 hides the entry. 0 is a name prefix, 1 a name match, 2 anything else.
    function matchRank(app, query) {
        if (!query) return 0
        var name = String(app.name || "").toLowerCase()
        if (name.indexOf(query) === 0) return 0
        if (name.indexOf(query) >= 0) return 1
        if (fieldHit(app.genericName, query) || fieldHit(app.comment, query) || fieldHit(app.id, query))
            return 2
        var keywords = app.keywords || []
        for (var i = 0; i < keywords.length; i++) {
            if (fieldHit(keywords[i], query)) return 2
        }
        return -1
    }

    function launch(row) {
        if (!row) return
        var entry = DesktopEntries.byId(row.id)
        if (!entry) return
        entry.execute()
        opened = false
    }

    function toggle() {
        opened = !opened
    }

    onFilterTextChanged: selected = 0

    onOpenedChanged: if (opened) {
        filterText = ""
        selected = 0
        if (filter) filter.text = ""
        Qt.callLater(function () { if (filter) filter.forceActiveFocus() })
    }

    onShownChanged: if (selected >= shown.length) selected = Math.max(0, shown.length - 1)

    onSelectedChanged: if (list && shown.length > 0 && selected >= 0)
        list.positionViewAtIndex(selected, ListView.Contain)

    IpcHandler {
        target: "launcher"
        function toggle(): string {
            root.toggle()
            return root.opened ? "open" : "closed"
        }
        function show(): string { root.opened = true; return "open" }
        function hide(): string { root.opened = false; return "closed" }
    }

    CenterOverlay {
        shown: root.opened
        panelNamespace: "launcher"
        cardWidth: 450
        cardHeight: 420
        onDismissed: root.opened = false

        Rectangle {
            id: searchRow
            width: parent.width
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
                onAccepted: if (root.shown.length > 0) root.launch(root.shown[root.selected])
                Keys.onUpPressed: root.selected = Math.max(0, root.selected - 1)
                Keys.onDownPressed: root.selected = Math.min(Math.max(0, root.shown.length - 1), root.selected + 1)
                Keys.onEscapePressed: {
                    if (text) text = ""
                    else root.opened = false
                }
            }

            IconText {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: "Search apps"
                color: Commons.Color.muted
                size: Style.font.subtitle
                visible: filter.text === "" && !filter.activeFocus
            }
        }

        ListView {
            id: list
            width: parent.width
            height: parent.height - searchRow.height - parent.spacing
            clip: true
            spacing: 2
            model: root.shown
            currentIndex: root.selected

            delegate: Rectangle {
                required property var modelData
                required property int index
                width: list.width
                height: 36
                color: index === root.selected || rowMouse.containsMouse ? Commons.Color.surface : "transparent"

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 8

                    Image {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 18
                        height: 18
                        source: Quickshell.iconPath(modelData.icon, "application-x-executable")
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        sourceSize: Qt.size(36, 36)
                    }

                    IconText {
                        id: nameLabel
                        anchors.verticalCenter: parent.verticalCenter
                        width: genericLabel.visible ? Math.round((parent.width - 26) * 0.62) : parent.width - 26
                        text: modelData.name
                        size: Style.font.body
                        elide: Text.ElideRight
                    }

                    IconText {
                        id: genericLabel
                        anchors.verticalCenter: parent.verticalCenter
                        width: visible ? parent.width - 26 - nameLabel.width : 0
                        visible: modelData.genericName !== "" && modelData.genericName !== modelData.name
                        text: modelData.genericName
                        color: Commons.Color.muted
                        size: Style.font.bodySmall
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: root.selected = index
                    onClicked: root.launch(modelData)
                }
            }

            IconText {
                anchors.centerIn: parent
                visible: root.shown.length === 0
                text: root.filterText === "" ? "No applications" : "No matching apps"
                color: Commons.Color.muted
                size: Style.font.subtitle
            }
        }
    }
}
