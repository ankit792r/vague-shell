import QtQuick
import Quickshell
import Quickshell.Wayland
import "../Commons"
import "../Commons" as Commons

// Centered card on a fullscreen layer. Used by overlays that are not
// attached to a bar icon, such as the clipboard.
Item {
    id: root

    property bool shown: false
    property string panelNamespace: "overlay"
    property int cardWidth: 560
    property int cardHeight: 480
    property int cardSpacing: 10

    signal dismissed()

    default property alias content: column.data

    property Item chrome: Item {
        PanelWindow {
            id: overlay

            visible: root.shown
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            aboveWindows: true
            focusable: true
            WlrLayershell.namespace: root.panelNamespace
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            anchors { top: true; bottom: true; left: true; right: true }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                onClicked: root.dismissed()
            }

            Rectangle {
                id: card
                anchors.centerIn: parent
                width: Math.min(root.cardWidth, overlay.width - 48)
                height: Math.min(root.cardHeight, overlay.height - 48)
                color: Commons.Color.background
                border.color: Commons.Color.border
                border.width: 2

                MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }

                Column {
                    id: column
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: root.cardSpacing
                }
            }
        }
    }

    Component.onCompleted: chrome.parent = root
}
