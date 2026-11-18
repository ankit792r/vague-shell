import QtQuick
import Quickshell
import Quickshell.Wayland
import "../Commons"
import "../Commons" as Commons

// Card on a fullscreen layer for overlays that are not attached to a bar icon.
// anchor "center" shows it immediately. anchor "bottom" rests it at the bottom
// center and slides it up from below the screen on the same curve as the bar panels.
Item {
    id: root

    property bool shown: false
    property string anchor: "center"
    property string panelNamespace: "overlay"
    property int cardWidth: 560
    property int cardHeight: 480
    property int cardSpacing: 10
    property int edgeMargin: 8

    readonly property bool fromBottom: anchor === "bottom"
    property real reveal: shown ? 1 : 0

    Behavior on reveal {
        NumberAnimation {
            duration: root.shown ? Style.motion.enter : Style.motion.exit
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.shown ? Style.motion.enterCurve : Style.motion.exitCurve
        }
    }

    signal dismissed()

    default property alias content: column.data

    property Item chrome: Item {
        PanelWindow {
            id: overlay

            visible: root.fromBottom ? (root.shown || root.reveal > 0) : root.shown
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            aboveWindows: true
            focusable: true
            WlrLayershell.namespace: root.panelNamespace
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: (!root.fromBottom || root.shown) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            anchors { top: true; bottom: true; left: true; right: true }

            // Closing a bottom card: let clicks through while it slides away.
            mask: Region { item: root.fromBottom && !root.shown ? null : backdrop }

            MouseArea {
                id: backdrop
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                onClicked: root.dismissed()
            }

            Item {
                id: cardSlot

                readonly property real cardW: Math.min(root.cardWidth, overlay.width - 48)
                readonly property real cardH: Math.min(root.cardHeight, overlay.height - 48)

                clip: root.fromBottom
                width: cardW
                height: cardH
                x: (overlay.width - width) / 2
                y: root.fromBottom ? overlay.height - height - root.edgeMargin : (overlay.height - height) / 2

                Rectangle {
                    id: card

                    width: cardSlot.width
                    height: cardSlot.height
                    y: root.fromBottom ? (1 - root.reveal) * height : 0
                    color: Commons.Color.background
                    border.color: Commons.Color.border
                    border.width: 2

                    // clip does not limit input, so ignore the part still below the screen.
                    MouseArea {
                        width: parent.width
                        height: root.fromBottom ? Math.max(0, parent.height - card.y) : parent.height
                        acceptedButtons: Qt.AllButtons
                    }

                    Column {
                        id: column
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: root.cardSpacing
                    }
                }
            }
        }
    }

    Component.onCompleted: chrome.parent = root
}
