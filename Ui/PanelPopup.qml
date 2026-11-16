import QtQuick
import Quickshell
import Quickshell.Wayland
import "../Commons"
import "../Commons" as Commons

// Fullscreen layer above the bar widget. Clicking outside dismisses it.
// Children are placed in the card.
Item {
    id: root

    property Item anchorItem
    property string panelNamespace: "panel"
    property int cardWidth: 380
    property int cardSpacing: 14

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
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            anchors { top: true; bottom: true; left: true; right: true }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                onClicked: root.dismissed()
                onWheel: function (wheel) { root.wheeled(wheel.angleDelta.y) }
            }

            Rectangle {
                id: card

                readonly property real screenW: overlay.screen ? overlay.screen.width : 1920
                readonly property point anchor: {
                    var item = root.anchorItem
                    var window = item && item.QsWindow ? item.QsWindow.window : null
                    if (!item || !window) return Qt.point(8, 40)
                    return item.mapToItem(window.contentItem, 0, 0)
                }

                width: root.cardWidth
                height: column.implicitHeight + 28
                color: Commons.Color.background
                border.color: Commons.Color.border
                border.width: 2
                x: Math.max(8, Math.min(anchor.x + (root.anchorItem ? root.anchorItem.width : 0) / 2 - width / 2, screenW - width - 8))
                y: 40

                MouseArea {
                    anchors.fill: parent
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

        Variants {
            model: Quickshell.screens

            delegate: PanelWindow {
                required property var modelData

                screen: modelData
                visible: overlay.screen && modelData.name !== overlay.screen.name
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

    Component.onCompleted: chrome.parent = root
}
