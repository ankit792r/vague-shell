import QtQuick
import Quickshell
import Quickshell.Wayland
import "../Commons"
import "../Commons" as Commons

// Fullscreen layer above the bar widget. Clicking outside dismisses it.
// Children are placed in the card.
//
// The card slides down from behind the bar. Bind `open` and keep the Loader
// active while `reveal > 0` so it can slide back up before it is destroyed.
Item {
    id: root

    property Item anchorItem
    property string panelNamespace: "panel"
    property int cardWidth: 380
    property int cardSpacing: 14
    property bool open: true

    property bool ready: false
    property real reveal: open && ready ? 1 : 0

    Behavior on reveal {
        NumberAnimation {
            duration: root.open ? Style.motion.enter : Style.motion.exit
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.open ? Style.motion.enterCurve : Style.motion.exitCurve
        }
    }

    signal dismissed()
    signal wheeled(int delta)

    default property alias content: column.data

    property Item chrome: Item {
        PanelWindow {
            id: overlay

            screen: root.anchorItem && root.anchorItem.QsWindow.window ? root.anchorItem.QsWindow.window.screen : null
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            aboveWindows: true
            focusable: true
            WlrLayershell.namespace: root.panelNamespace
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            anchors { top: true; bottom: true; left: true; right: true }

            // Closing: let clicks through while the card eases out.
            mask: Region { item: root.open ? catcher : null }

            MouseArea {
                id: catcher
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                onClicked: root.dismissed()
                onWheel: function (wheel) { root.wheeled(wheel.angleDelta.y) }
            }

            // Fixed slot under the bar. The card travels through it, so it
            // looks like it slides out from behind the bar instead of wiping.
            Item {
                id: cardSlot

                readonly property real screenW: overlay.screen ? overlay.screen.width : 1920
                readonly property point anchor: {
                    var item = root.anchorItem
                    var window = item && item.QsWindow ? item.QsWindow.window : null
                    if (!item || !window) return Qt.point(8, 40)
                    return item.mapToItem(window.contentItem, 0, 0)
                }

                clip: true
                width: root.cardWidth
                height: card.height
                x: Math.max(8, Math.min(anchor.x + (root.anchorItem ? root.anchorItem.width : 0) / 2 - width / 2, screenW - width - 8))
                y: 40

                Rectangle {
                    id: card

                    width: cardSlot.width
                    height: column.implicitHeight + 28
                    y: (root.reveal - 1) * height
                    color: Commons.Color.background
                    border.color: Commons.Color.activeBorder
                    border.width: 2

                    // clip does not limit input, so ignore the part still behind the bar.
                    MouseArea {
                        y: Math.max(0, -card.y)
                        width: parent.width
                        height: Math.max(0, parent.height - y)
                        acceptedButtons: Qt.AllButtons
                        onWheel: function (wheel) { root.wheeled(wheel.angleDelta.y) }
                    }

                    Column {
                        id: column
                        z: 1
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 14
                        spacing: root.cardSpacing
                    }
                }
            }
        }

        Variants {
            model: Quickshell.screens

            delegate: PanelWindow {
                required property var modelData

                screen: modelData
                visible: root.open && overlay.screen && modelData.name !== overlay.screen.name
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.namespace: root.panelNamespace + "-dismiss"
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

                anchors { top: true; bottom: true; left: true; right: true }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.dismissed()
                }
            }
        }
    }

    Component.onCompleted: {
        chrome.parent = root
        Qt.callLater(function () { root.ready = true })
    }
}
