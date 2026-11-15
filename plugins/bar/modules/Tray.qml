import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import "../../../Commons"

Item {
    id: root

    implicitWidth: row.implicitWidth
    implicitHeight: Style.bar.height

    Row {
    id: row
    anchors.verticalCenter: parent.verticalCenter
    spacing: 0

    Repeater {
        model: SystemTray.items

        delegate: Item {
            id: iconRoot

            required property var modelData

            readonly property bool shown: modelData.status !== Status.Passive

            visible: shown
            implicitWidth: shown ? 20 : 0
            implicitHeight: 16

            Image {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 16
                height: 16
                fillMode: Image.PreserveAspectFit
                source: iconRoot.modelData.icon
                sourceSize.width: width * Screen.devicePixelRatio
                sourceSize.height: height * Screen.devicePixelRatio
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: function (mouse) {
                    var item = iconRoot.modelData
                    if (mouse.button === Qt.MiddleButton) item.secondaryActivate()
                    else if (mouse.button === Qt.RightButton || item.onlyMenu) item.display(iconRoot.QsWindow.window, mouse.x, mouse.y)
                    else item.activate()
                }
                onWheel: function (wheel) {
                    iconRoot.modelData.scroll(wheel.angleDelta.y, false)
                }
            }
        }
    }
}
}